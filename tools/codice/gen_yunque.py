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
# La carpeta de PNG, que es lo que la web sirve y la unica fuente completa.
PNG = 'EpsilonIcons/png'
PAGINA = os.path.join(BASE, 'yunque.html')

# Solo lo que puede ser icono de OBJETO. Los de habilidad o logro solo estorbarian al buscar.
PREFIJOS = ('inv_', 'trade_', 'item_', 'spell_holy_', 'ability_')


def main():
    if not os.path.isdir(PNG):
        print("No existe %s" % PNG)
        return 1
    # LA CARPETA es la fuente: si el PNG esta ahi, el icono existe. Filtrar por el CSV y por
    # prefijo dejaba fuera 9.582, entre ellos los 6.192 del espacio `eps_` con los 461 de
    # BG3. Aqui entran todos, porque escribir un nombre no cuesta peso: lo que cuesta es la
    # miniatura, y de eso se ocupa el cupo de la hoja.
    nombres = sorted({f[:-4].lower() for f in os.listdir(PNG) if f.endswith('.png')})
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
