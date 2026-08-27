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
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
ICONOS = 'EpsilonIcons/epsilon_icons.json'
PAGINA = os.path.join(BASE, 'yunque.html')

# Solo lo que puede ser icono de OBJETO. Los de habilidad o logro solo estorbarian al buscar.
PREFIJOS = ('inv_', 'trade_', 'item_', 'spell_holy_', 'ability_')


def main():
    if not os.path.exists(ICONOS):
        print("No existe %s" % ICONOS)
        return 1
    crudo = json.load(io.open(ICONOS, encoding='utf-8'))
    # El catalogo trae fichas {fdid, name, path}, no cadenas sueltas.
    if isinstance(crudo, dict):
        todos = list(crudo)
    else:
        todos = [x if isinstance(x, str) else (x.get('name') or '') for x in crudo]

    nombres = sorted({n.lower() for n in todos
                      if n and n.lower().startswith(PREFIJOS)})
    print("Iconos en el catalogo: %d" % len(todos))
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
