# -*- coding: utf-8 -*-
"""Ejecuta las pruebas de logica del addon.

Uso:  python tools/pruebas.py [nombre-parcial]

Cada suite de `tools/pruebas/` es un fichero Lua que EXTRAE funciones del codigo real y las ejecuta
con stubs de WoW. No prueba frames, anclajes ni red de verdad: prueba las REGLAS -- protocolo de
turnos, iniciativa, mitigacion de dano, competencias, creacion de personaje.

Por que existe: esa logica vivia dentro de ficheros de 3000-7000 lineas mezclada con construccion
de UI, y no habia forma de tocarla. Al extraerla a modulos quedo alcanzable, y estas suites son lo
que hace que esa extraccion valga para algo mas que reducir el numero de lineas.

Lo que NO cubre: nada visual, nada de red real, nada de dos clientes. Para eso esta la sesion de
pruebas en juego.
"""
import io, os, re, subprocess, sys, glob

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUITES = os.path.join(RAIZ, "tools", "pruebas")

# El interprete: cualquiera vale para logica pura. La COMPILACION contra Lua 5.1 real la hace
# `desplegar.py`; aqui solo se ejecutan reglas, que no dependen de la version.
CANDIDATOS = [
    r"C:\Users\marco\AppData\Local\Programs\Lua\bin\lua.exe",
    "lua5.1", "lua51", "luajit", "lua",
]


def buscar_lua():
    for c in CANDIDATOS:
        try:
            subprocess.run([c, "-v"], capture_output=True, timeout=5)
            return c
        except (OSError, subprocess.SubprocessError):
            continue
    return None


def main():
    filtro = sys.argv[1].lower() if len(sys.argv) > 1 else ""
    lua = buscar_lua()
    if not lua:
        print("No encuentro un interprete de Lua. Probados: %s" % ", ".join(CANDIDATOS))
        return 2

    ficheros = sorted(glob.glob(os.path.join(SUITES, "*.lua")))
    if filtro:
        ficheros = [f for f in ficheros if filtro in os.path.basename(f).lower()]
    if not ficheros:
        print("Ninguna suite coincide con %r" % filtro)
        return 2

    print("PRUEBAS DE LOGICA")
    print("=" * 70)
    fallan, casos_ok, casos_mal = [], 0, 0
    for f in ficheros:
        nombre = os.path.basename(f)[:-4]
        # Se ejecutan desde la RAIZ: las suites abren el codigo real con rutas relativas.
        r = subprocess.run([lua, f], cwd=RAIZ, capture_output=True, text=True,
                           encoding="utf-8", errors="replace")
        salida = (r.stdout or "") + (r.stderr or "")
        ok = r.returncode == 0 and "TODO CORRECTO" in salida
        casos_ok += len(re.findall(r"\bok\s*$", salida, re.M))
        casos_mal += len(re.findall(r"\bFALLA", salida))
        print("  %-28s %s" % (nombre, "ok" if ok else "FALLA"))
        if not ok:
            fallan.append((nombre, salida))

    print()
    print("%d suites, %d casos correctos, %d fallidos" % (len(ficheros), casos_ok, casos_mal))

    for nombre, salida in fallan:
        print()
        print("-" * 70)
        print("FALLA: %s" % nombre)
        print("-" * 70)
        for linea in salida.rstrip().split("\n"):
            print("   " + linea)

    return 1 if fallan else 0


if __name__ == "__main__":
    sys.exit(main())
