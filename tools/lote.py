# -*- coding: utf-8 -*-
"""Cierre de lote en un solo comando y un solo exit code:
  1. luac -p sobre todos los .lua del arbol de addons (compilacion).
  2. Bateria completa de tools/pruebas/ (cada suite debe acabar en TODO CORRECTO u ok).
  3. Despliegue con tools/desplegar.py (opcional: --sin-desplegar).
Cualquier fallo para el lote y sale con 1; el commit viene DESPUES de esto, nunca antes.

Uso:  python tools/lote.py [--sin-desplegar]
"""
import os, subprocess, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS = ["Harford", "HarfordAdmin", "HarfordDebug", "HarfordCompendio",
          "HarfordProfesiones", "HarfordMusic"]
PRUEBAS = os.path.join(RAIZ, "tools", "pruebas")


def paso(titulo):
    print("\n=== %s ===" % titulo)


def compilacion():
    paso("1/3 Compilacion (luac -p)")
    try:
        subprocess.run(["luac", "-v"], capture_output=True)
    except OSError:
        print("luac no esta en el PATH: paso saltado (el hook de pre-commit tampoco compilara)")
        return []
    fallos = []
    total = 0
    for addon in ADDONS:
        base = os.path.join(RAIZ, addon)
        if not os.path.isdir(base):
            continue
        for carpeta, _dirs, ficheros in os.walk(base):
            for nombre in ficheros:
                if not nombre.endswith(".lua"):
                    continue
                total += 1
                ruta = os.path.join(carpeta, nombre)
                r = subprocess.run(["luac", "-p", ruta], capture_output=True, text=True, encoding="utf-8", errors="replace")
                if r.returncode != 0:
                    fallos.append(r.stderr.strip())
    if fallos:
        for f in fallos:
            print("  FALLA " + f)
    else:
        print("  %d .lua compilan" % total)
    return fallos


def bateria():
    paso("2/3 Bateria de pruebas")
    fallos = []
    suites = sorted(n for n in os.listdir(PRUEBAS) if n.endswith(".lua"))
    for nombre in suites:
        r = subprocess.run(["lua", os.path.join(PRUEBAS, nombre)],
                           capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=RAIZ)
        ultima = (r.stdout.strip().splitlines() or [""])[-1]
        # Las suites cierran con "TODO CORRECTO"; acciones_basicas acaba en una linea "... ok".
        ok = r.returncode == 0 and ("TODO CORRECTO" in ultima or ultima.endswith("ok"))
        if not ok:
            fallos.append(nombre)
            print("  FALLA %-32s %s" % (nombre, (r.stderr.strip() or ultima)[:120]))
    print("  %d suites, %d fallos" % (len(suites), len(fallos)))
    return fallos


def despliegue():
    paso("3/3 Despliegue")
    r = subprocess.run([sys.executable, os.path.join(RAIZ, "tools", "desplegar.py")],
                       capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=RAIZ)
    colas = r.stdout.strip().splitlines()[-2:]
    for linea in colas:
        print("  " + linea)
    # El exit code se comprueba DIRECTO: encadenarlo a un pipe ya enmascaro despliegues rojos.
    if r.returncode != 0:
        print("  DESPLIEGUE ROJO (exit %d); log completo arriba en stdout/stderr" % r.returncode)
        if r.stderr.strip():
            print(r.stderr.strip()[-800:])
        return ["desplegar.py exit %d" % r.returncode]
    return []


def main():
    sin_desplegar = "--sin-desplegar" in sys.argv[1:]
    fallos = compilacion()
    fallos += bateria()
    if fallos:
        # Sin compilar o con la bateria rota no se despliega: desplegado a medias es peor.
        print("\nLOTE ROTO (%d fallos); despliegue omitido" % len(fallos))
        return 1
    if sin_desplegar:
        print("\nLOTE VERDE (sin desplegar)")
        return 0
    fallos = despliegue()
    print("\n" + ("LOTE ROTO" if fallos else "LOTE VERDE: listo para commit"))
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main())
