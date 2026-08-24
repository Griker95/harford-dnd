# -*- coding: utf-8 -*-
"""Importa las VARIANTES de trasfondo de la web al addon.

Sentido web -> addon; no toca la web. Una variante es narrativa: trae `id`, `name`, `desc` e
`icon`, sin rasgos ni efectos, asi que no hay mecanica que trasladar. El campo `art` de la web
(un .webp) se ignora: WoW no carga webp.

    python tools/codice/importar_variantes_trasfondo.py            # informe
    python tools/codice/importar_variantes_trasfondo.py --escribir
"""
import io, os, re, sys, json

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, '..', '..')) + '/'
WEB = 'C:/Users/marco/Documents/harfordweb/js/compendium-data.js'
DESTINO = RAIZ + 'Harford/DnD/Data/HarfordDnDBackgrounds.lua'
ESCRIBIR = '--escribir' in sys.argv


def carga_web():
    s = io.open(WEB, encoding='utf-8').read()
    i, j = s.find('{'), s.rfind('}')
    return json.loads(s[i:j + 1])


def lua_cadena(txt):
    """Cadena Lua entre comillas dobles, escapando lo que lo requiere."""
    t = str(txt or '')
    t = t.replace('\\', '\\\\').replace('"', '\\"')
    t = t.replace('\r', '').replace('\n', ' ')
    return '"' + t + '"'


def main():
    d = carga_web()
    variantes = {}
    for bg in d.get('backgrounds', []):
        v = bg.get('variants')
        if v:
            variantes[bg.get('id')] = v
    print('trasfondos con variantes en la web: %d' % len(variantes))

    s = io.open(DESTINO, encoding='utf-8').read()
    if 'variants = {' in s:
        print('El fichero YA tiene variantes; abortando para no duplicarlas.')
        return 1

    hechos, ausentes = [], []
    # De atras hacia delante para que los offsets de los anteriores sigan siendo validos.
    posiciones = []
    for bgid, lista in variantes.items():
        # El registro abre con "{\n        id = ...", no con "{ id = ...".
        m = re.search(r'\{\s*id = "%s", name = "([^"]+)"' % re.escape(bgid), s)
        if not m:
            ausentes.append(bgid)
            continue
        posiciones.append((m.end(), bgid, lista, m.group(1)))
    posiciones.sort(reverse=True)

    for fin, bgid, lista, nombre in posiciones:
        trozos = []
        for v in lista:
            campos = [
                'id = ' + lua_cadena(v.get('id')),
                'name = ' + lua_cadena(v.get('name')),
                'desc = ' + lua_cadena(v.get('desc')),
            ]
            if v.get('icon'):
                campos.append('icon = ' + lua_cadena(v.get('icon')))
            trozos.append('{ ' + ', '.join(campos) + ' }')
        bloque = ', variants = { ' + ', '.join(trozos) + ' }'
        s = s[:fin] + bloque + s[fin:]
        hechos.append((bgid, nombre, [v.get('name') for v in lista]))

    for bgid, nombre, nombres in reversed(hechos):
        print('  %-30s %-24s -> %s' % (bgid, nombre, ', '.join(nombres)))
    if ausentes:
        print('  NO encontrados en el addon: %s' % ', '.join(ausentes))

    if not ESCRIBIR:
        print()
        print('  (informe; nada escrito. Repite con --escribir)')
        return 0

    io.open(DESTINO, 'w', encoding='utf-8', newline='\n').write(s)
    print()
    print('  escrito %s  (%d trasfondos con variante)' % (DESTINO, len(hechos)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
