# -*- coding: utf-8 -*-
"""Importa los nombres en FEMENINO de razas y subrazas desde la web al addon.

Sentido web -> addon; no toca la web. La web publica `nameM`/`nameF` en cada raza y subraza; el
addon solo tenia `name` (masculino) y escribia eso en el About aunque el PJ fuera mujer, pese a
que su propio lector (`Masculinize`) da por hecho que el About viene en femenino.

    python tools/codice/importar_femenino.py            # informe
    python tools/codice/importar_femenino.py --escribir

Solo anade `nameF` donde el femenino DIFIERE del masculino: Draenei, Tauren, Troll, Goblin,
Pandaren y Vulpera son invariables y no ganan nada con el campo.

Clases y subclases NO se tocan: la web no publica su femenino (0 de 12), y los perfiles reales
usan "Sacerdotisa", "Picara", "Maga", "Guerrera"... que ninguna regla deriva de "Sacerdote".
Ese dato hay que crearlo en la web antes de poder importarlo.
"""
import io, os, re, sys, json

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, '..', '..')) + '/'
WEB = 'C:/Users/marco/Documents/harfordweb/js/compendium-data.js'
DESTINO = RAIZ + 'Harford/DnD/Data/HarfordDnDRaces.lua'
ESCRIBIR = '--escribir' in sys.argv


def lua_cadena(t):
    return '"' + str(t or '').replace('\\', '\\\\').replace('"', '\\"') + '"'


s = io.open(WEB, encoding='utf-8').read()
i, j = s.find('{'), s.rfind('}')
d = json.loads(s[i:j + 1])

# CUIDADO: los ids de subraza COLISIONAN con los de raza. Renegado tiene una subraza `humano`
# ("Renegado Humano") y otra `elfo`, asi que un diccionario plano por id hacia que el femenino de
# la RAZA Humano acabara siendo "Renegada Humana". Se separan por ambito.
fem_raza, fem_sub = {}, {}
for r in d.get('races', []):
    m, f = (r.get('nameM') or r.get('name')), r.get('nameF')
    if f and f != m:
        fem_raza[r['id']] = f
    for sr in r.get('subraces', []):
        m2, f2 = (sr.get('nameM') or sr.get('name')), sr.get('nameF')
        if f2 and f2 != m2:
            fem_sub[(r['id'], sr['id'])] = f2

print('femeninos que DIFIEREN en la web: %d razas, %d subrazas'
      % (len(fem_raza), len(fem_sub)))

lua = io.open(DESTINO, encoding='utf-8').read()
if 'nameF' in lua:
    print('El fichero ya tiene nameF; abortando para no duplicar.')
    sys.exit(1)

hechos, ausentes = [], []
posiciones = []

def bloque_raza(rid):
    """Rango [ini, fin) del registro de una raza, para buscar sus subrazas SOLO ahi dentro."""
    m = re.search(r'\{\s*id = "%s", name = "' % re.escape(rid), lua)
    if not m:
        return None
    ini = lua.rfind('{', 0, m.start() + 1)
    prof, k = 0, ini
    while k < len(lua):
        if lua[k] == '{': prof += 1
        elif lua[k] == '}':
            prof -= 1
            if prof == 0: break
        k += 1
    return (ini, k)

# Razas: primera aparicion en file-scope.
for rid, f in fem_raza.items():
    m = re.search(r'\{\s*id = "%s", name = "([^"]+)"' % re.escape(rid), lua)
    if not m:
        ausentes.append(rid); continue
    posiciones.append((m.end(), rid, m.group(1), f))

# Subrazas: dentro del bloque de SU raza, nunca fuera.
for (rid, sid), f in fem_sub.items():
    rango = bloque_raza(rid)
    if not rango:
        ausentes.append('%s/%s' % (rid, sid)); continue
    a_, b_ = rango
    m = re.search(r'\{\s*id = "%s", name = "([^"]+)"' % re.escape(sid), lua[a_:b_])
    if not m:
        ausentes.append('%s/%s' % (rid, sid)); continue
    posiciones.append((a_ + m.end(), '%s/%s' % (rid, sid), m.group(1), f))

# De atras hacia delante para no mover los offsets de los anteriores.
for fin, rid, nombre, f in sorted(posiciones, reverse=True):
    lua = lua[:fin] + ', nameF = ' + lua_cadena(f) + lua[fin:]
    hechos.append((rid, nombre, f))

for rid, nombre, f in reversed(hechos):
    print('  %-20s %-24s -> %s' % (rid, nombre, f))
if ausentes:
    print('  no encontrados en el addon: %s' % ', '.join(sorted(ausentes)))

if not ESCRIBIR:
    print()
    print('  (informe; nada escrito. Repite con --escribir)')
    sys.exit(0)

io.open(DESTINO, 'w', encoding='utf-8', newline='\n').write(lua)
print()
print('  escrito %s  (%d con femenino)' % (DESTINO, len(hechos)))
