# -*- coding: utf-8 -*-
"""Saca los displayid de los objetos de la cache de HTML de Wowhead.

Hace falta porque la descripcion de `.forge item set display` se corta en el propio
EpsilonLib justo donde importaba -- "If the $item-link2 is instead a number" -- sin decir si
ese numero seria un id de objeto o un displayid.

Por defecto el addon manda un ENLACE, que vale bajo cualquiera de las dos lecturas y cubre
2498 objetos. Esto es la segunda via: si la prueba en juego demuestra que el servidor quiere
un displayid suelto, ya estan extraidos y se cambia con `/hforge modelo displayid`.

La cobertura es menor (solo lo que hay en la cache de paginas de profesion), asi que el
enlace sigue siendo el camino principal.

En el HTML, cada objeto va como  "<id>":{"name_enus":...,"jsonequip":{...,"displayid":N,...}}
y el displayid solo aparece en los equipables, que es justo donde importa.

Uso:
    python tools/codice/itemforge_displayids.py
    python tools/codice/itemforge_displayids.py --aplicar
"""
import io
import json
import os
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(BASE, 'cotejo', 'wowhead_cache')
DATOS = 'AddonsIndependientes/HarfordItemForge/Data.lua'
PUENTE = os.path.join(BASE, '_itemforge_displayids.json')

INICIO = re.compile(r'"(\d+)":\{"name_')
DISP = re.compile(r'"displayid":(\d+)')


def extrae():
    """id de objeto -> displayid, de todo el HTML cacheado."""
    porItem, ficheros = {}, 0
    if not os.path.isdir(CACHE):
        return porItem, 0
    for f in sorted(os.listdir(CACHE)):
        if not f.endswith('.html'):
            continue
        ficheros += 1
        t = io.open(os.path.join(CACHE, f), encoding='utf-8', errors='replace').read()
        # Se trocea por objeto: entre una cabecera y la siguiente. Sin acotar, el displayid
        # de un objeto se le pegaria al anterior.
        marcas = [(m.start(), int(m.group(1))) for m in INICIO.finditer(t)]
        for i, (pos, idItem) in enumerate(marcas):
            fin = marcas[i + 1][0] if i + 1 < len(marcas) else min(len(t), pos + 4000)
            d = DISP.search(t, pos, fin)
            if d:
                porItem.setdefault(idItem, int(d.group(1)))
    return porItem, ficheros


def main():
    aplicar = '--aplicar' in sys.argv

    porItem, ficheros = extrae()
    print("Cache leida: %d archivos" % ficheros)
    print("displayid extraidos: %d objetos" % len(porItem))
    if not porItem:
        print("Nada que hacer.")
        return 0

    texto = io.open(DATOS, encoding='utf-8').read()
    # clave + el id original que ya le asignamos
    entradas = re.findall(
        r'clave = "([^"]+)", nombre = "([^"]+)",(?:.|\n){0,400}?display = (\d+),', texto)

    salida, cubiertos = {}, 0
    for clave, nombre, idOriginal in entradas:
        disp = porItem.get(int(idOriginal))
        if disp:
            salida[clave] = {'displayid': disp}
            cubiertos += 1

    conOriginal = len(re.findall(r'display = (\d+),', texto))
    print()
    print("Objetos con id original:     %d" % conOriginal)
    print("   de esos, con displayid:   %d  (%.0f%%)"
          % (cubiertos, 100.0 * cubiertos / max(1, conOriginal)))
    print()
    print("El enlace sigue siendo la via principal: cubre los %d." % conOriginal)
    print("Esto es el plan B por si el servidor resulta querer un displayid suelto.")

    if not aplicar:
        print()
        print("Nada escrito. Vuelve a lanzarlo con --aplicar.")
        return 0

    io.open(PUENTE, 'w', encoding='utf-8', newline='').write(
        json.dumps(salida, ensure_ascii=False, indent=1) + "\n")
    print()
    print("Escrito el puente %s" % PUENTE)
    subprocess.run([sys.executable, os.path.join(BASE, 'importar_itemforge.py'), PUENTE],
                   check=False)
    return 0


if __name__ == '__main__':
    sys.exit(main())
