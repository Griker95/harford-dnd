# -*- coding: utf-8 -*-
"""Rehace la lista de HarfordItemForge cuando cambia cualquiera de sus fuentes.

La lista no es un archivo que se edite: es el resultado de cruzar varias cosas que se mueven
por su cuenta -- el registro de objetos y las recetas (que mantiene el otro chat), la KB que
consume la web, la captura de Wowhead y lo forjado en el juego. Este script las recorre en el
orden correcto y deja `Data.lua` al dia.

Las seis etapas:

  1. VUELTA     lee los ids ya forjados de las SavedVariables del juego. Es el camino de
                regreso: lo que se creo anoche tiene que salir de la lista de pendientes.
  2. WOWHEAD    vuelca calidad, pila y efectos de la captura que ya esta en disco.
  3. DISPLAYID  extrae los displayid de la cache de HTML, como via alternativa del modelo.
  4. GENERAR    rehace Data.lua desde el registro + recetas + KB, con las anulaciones encima.
  5. DUPLICADOS rastrea el WTF por objetos que ya existan, para no crearlos dos veces.
  6. COMPROBAR  compila el resultado con el Lua 5.1 REAL, no con el interprete local.

Sin --aplicar solo informa de lo que haria.

Uso:
    python tools/codice/actualizar_itemforge.py
    python tools/codice/actualizar_itemforge.py --aplicar
"""
import io
import os
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
WTF = 'G:/Epsilon/_retail_/WTF'
DATOS = 'AddonsIndependientes/HarfordItemForge/Data.lua'
# El otro chat saco los datos de profesiones a su propio addon (commit 3133ccb). Si
# vuelven a moverse, es esta linea la que hay que tocar.
REGISTRO = 'HarfordProfesiones/HarfordProfesionesItems.lua'
SALIDA_VUELTA = os.path.join(BASE, '_itemforge_forjados.txt')


def titulo(n, texto):
    sys.stdout.flush()
    print()
    print("── %d. %s %s" % (n, texto, "─" * max(0, 58 - len(texto))))
    sys.stdout.flush()


def corre(script, *args):
    # Sin esto, lo que imprime el subproceso se adelanta a las cabeceras de etapa: mis
    # print van a bufer y el suyo va directo al terminal.
    sys.stdout.flush()
    return subprocess.run([sys.executable, os.path.join(BASE, script)] + list(args),
                          check=False).returncode


# ── 1. La vuelta: del juego al registro ─────────────────────────────────────
def buscaSavedVariables():
    encontrados = []
    for raiz, _, ficheros in os.walk(WTF):
        for f in ficheros:
            if f == 'HarfordItemForge.lua':
                encontrados.append(os.path.join(raiz, f))
    return encontrados


def leeForjados(ruta):
    """clave -> (id, nombre, prof). El formato de las SavedVariables es predecible."""
    texto = io.open(ruta, encoding='utf-8', errors='replace').read()
    trozo = re.search(r'\["hechos"\]\s*=\s*\{(.*?)\n\t\},', texto, re.S)
    if not trozo:
        return {}
    salida = {}
    patron = re.compile(
        r'\["([a-z0-9_]+)"\]\s*=\s*\{(.*?)\}', re.S)
    for m in patron.finditer(trozo.group(1)):
        clave, cuerpo = m.group(1), m.group(2)
        mid = re.search(r'\["id"\]\s*=\s*(\d+)', cuerpo)
        if not mid:
            continue
        nom = re.search(r'\["nombre"\]\s*=\s*"([^"]*)"', cuerpo)
        prof = re.search(r'\["prof"\]\s*=\s*"([^"]*)"', cuerpo)
        salida[clave] = (int(mid.group(1)),
                         nom.group(1) if nom else clave,
                         prof.group(1) if prof else '')
    return salida


def idsDelRegistro():
    if not os.path.exists(REGISTRO):
        return {}
    texto = io.open(REGISTRO, encoding='utf-8').read()
    return {m.group(1): int(m.group(2)) for m in
            re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{[^}]*\bid\s*=\s*(\d+)', texto)}


def etapaVuelta(aplicar):
    archivos = buscaSavedVariables()
    if not archivos:
        print("   Sin SavedVariables del addon todavia: nada que devolver.")
        print("   (apareceran en %s tras forjar y hacer /reload)" % WTF)
        return 0

    todos = {}
    for ruta in archivos:
        forjados = leeForjados(ruta)
        print("   %s  ->  %d forjados" % (os.path.basename(os.path.dirname(
            os.path.dirname(ruta))), len(forjados)))
        todos.update(forjados)

    yaEstan = idsDelRegistro()
    faltan = {c: v for c, v in todos.items() if c not in yaEstan}
    print()
    print("   Forjados en total:            %d" % len(todos))
    print("   Ya apuntados en el registro:  %d" % (len(todos) - len(faltan)))
    print("   |  PENDIENTES de apuntar:     %d" % len(faltan))

    if not faltan:
        return 0

    lineas = ["-- Pegar en HarfordProfessionsItems.REGISTRY.",
              "-- Generado por tools/codice/actualizar_itemforge.py desde las SavedVariables.",
              ""]
    profPrevia = None
    for clave, (id_, nombre, prof) in sorted(faltan.items(), key=lambda kv: (kv[1][2], kv[0])):
        if prof != profPrevia:
            lineas.append("")
            lineas.append("    -- ===== %s =====" % (prof or 'sin receta').upper())
            profPrevia = prof
        lineas.append('    %-32s = { id = %d, name = "%s" },'
                      % ('["%s"]' % clave, id_, nombre))
    io.open(SALIDA_VUELTA, 'w', encoding='utf-8', newline='').write("\n".join(lineas) + "\n")
    print("   Escrito %s" % SALIDA_VUELTA)
    print("   HarfordProfessionsItems.lua lo mantiene el otro chat: se deja preparado,")
    print("   no se toca.")
    return len(faltan)


def main():
    aplicar = '--aplicar' in sys.argv
    print("Actualizar la lista de HarfordItemForge" + ("" if aplicar else "   (en seco)"))

    titulo(1, "Vuelta: ids forjados en el juego")
    etapaVuelta(aplicar)

    titulo(2, "Wowhead: calidad, pila y efectos")
    corre('itemforge_desde_wowhead.py', *(['--aplicar'] if aplicar else []))

    titulo(3, "Displayid: la via alternativa del modelo")
    corre('itemforge_displayids.py', *(['--aplicar'] if aplicar else []))

    titulo(4, "Generar Data.lua")
    if aplicar:
        corre('gen_itemforge_data.py')
    else:
        print("   (se saltaria; con --aplicar rehace Data.lua)")

    titulo(5, "Duplicados: objetos que ya existan")
    corre('itemforge_ya_creados.py')

    titulo(6, "Comprobar con el Lua 5.1 real")
    sys.path.insert(0, BASE)
    import lua51
    ok, msg = lua51.ejecuta(DATOS)
    print("   %s  %s" % ("OK  " if ok else "PETA", msg))
    if not ok:
        return 1

    print()
    if not aplicar:
        print("Nada escrito. Vuelve a lanzarlo con --aplicar.")
    else:
        print("Listo. Copia Data.lua al AddOns si lo tienes desplegado.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
