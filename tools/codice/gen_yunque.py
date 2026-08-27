# -*- coding: utf-8 -*-
"""Mete el catalogo de iconos dentro de yunque.html.

El Yunque valida el icono contra la lista real de Epsilon, y eso importa: un icono que no
existe NO borra la textura anterior, asi que el objeto hereda la del hueco que ocupaba antes
y el fallo no se ve hasta tenerlo delante en el juego.

La lista se inyecta entre las marcas /*ICONOS_INICIO*/ y /*ICONOS_FIN*/, asi que el html se
edita a mano con normalidad y esto solo refresca ese trozo.

Uso:
    python tools/codice/gen_yunque.py
"""
import csv
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
# La misma lista canonica que sirve la web: solo los que se pudieron extraer.
ICONOS = 'EpsilonIcons/icons_master.csv'
PAGINA = os.path.join(BASE, 'yunque.html')

# Solo lo que puede ser icono de OBJETO. Los de habilidad o logro solo estorbarian al buscar.
PREFIJOS = ('inv_', 'trade_', 'item_', 'spell_holy_', 'ability_')


def main():
    if not os.path.exists(ICONOS):
        print("No existe %s" % ICONOS)
        return 1
    # Los CUSTOM entran todos, con el nombre que tengan: son arte propio del servidor y no
    # hay donde buscarlos. A los de Blizzard si se les pide el prefijo, porque `spell_` y
    # `ability_` son arte de hechizo y solo estorban.
    nombres = set()
    for f in csv.DictReader(io.open(ICONOS, encoding='utf-8'), delimiter=';'):
        if f.get('estado') != 'extraido':
            continue
        n = f['nombre'].lower()
        if f.get('tipo') in ('custom', 'addon') or n.startswith(PREFIJOS):
            nombres.add(n)
    nombres = sorted(nombres)
    print("Iconos del catalogo (custom incluidos): %d" % len(nombres))
    print("   utiles para objetos: %d" % len(nombres))

    pagina = io.open(PAGINA, encoding='utf-8').read()
    bloque = ('/*ICONOS_INICIO*/const ICONOS=%s;/*ICONOS_FIN*/'
              % json.dumps(nombres, separators=(',', ':')))
    nueva, n = re.subn(r'/\*ICONOS_INICIO\*/.*?/\*ICONOS_FIN\*/', lambda _: bloque,
                       pagina, count=1, flags=re.S)
    if not n:
        print("No se encontraron las marcas ICONOS_INICIO / ICONOS_FIN en yunque.html")
        return 1

    io.open(PAGINA, 'w', encoding='utf-8', newline='').write(nueva)
    print()
    print("Escrito %s  (%.0f KB)" % (PAGINA, len(nueva) / 1024))
    return 0


if __name__ == '__main__':
    sys.exit(main())
