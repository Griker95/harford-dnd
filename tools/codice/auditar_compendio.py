# -*- coding: utf-8 -*-
"""Auditoria del compendio de conjuros: que falta por rellenar y que esta incoherente.

No compara contra los manuales (eso lo hace el chat de la web con el codice); mira la
INTEGRIDAD INTERNA de HarfordCompendioData: campos vacios, valores fuera de catalogo,
duplicados, y sobre todo lo que impide que un conjuro se pueda LANZAR desde la ficha.
"""
import io
import re
import sys
import collections

sys.stdout.reconfigure(encoding='utf-8')

# El compendio salio de Harford/ al pasar a addon LoadOnDemand.
SRC = 'HarfordCompendioData/HarfordCompendioData.lua'
text = io.open(SRC, encoding='utf-8').read()

# Cada conjuro es un bloque que empieza en `id = "..."`.
blocks = []
for m in re.finditer(r'\{\s*\n\s*id\s*=\s*"([^"]+)"', text):
    start = m.start()
    nxt = text.find('\n        id = "', m.end())
    blocks.append((m.group(1), text[start:nxt if nxt > 0 else len(text)]))

def field(block, name):
    m = re.search(r'\b%s\s*=\s*"((?:[^"\\]|\\.)*)"' % name, block)
    if m:
        return m.group(1)
    m = re.search(r'\b%s\s*=\s*(true|false|\d+)' % name, block)
    return m.group(1) if m else None

def list_field(block, name):
    m = re.search(r'\b%s\s*=\s*\{([^}]*)\}' % name, block)
    if not m:
        return []
    return re.findall(r'"([^"]+)"', m.group(1))

spells = []
for sid, block in blocks:
    spells.append({
        'id': sid,
        'name': field(block, 'name'),
        'level': field(block, 'level'),
        'school': field(block, 'school'),
        'classes': list_field(block, 'classes'),
        'categories': list_field(block, 'categories'),
        'castingTime': field(block, 'castingTime'),
        'range': field(block, 'range'),
        'components': field(block, 'components'),
        'duration': field(block, 'duration'),
        'concentration': field(block, 'concentration'),
        'savingThrow': field(block, 'savingThrow'),
        'attack': field(block, 'attack'),
        'damage': field(block, 'damage'),
        'description': field(block, 'description'),
        'mechanics': field(block, 'mechanics'),
        'roleNotes': field(block, 'roleNotes'),
        'icon': field(block, 'icon'),
        'source': field(block, 'source'),
    })

print('CONJUROS: %d' % len(spells))

# --- 1) Campos vacios o ausentes
print('\n[1] CAMPOS SIN RELLENAR')
required = ['name', 'school', 'castingTime', 'range', 'components', 'duration',
            'description', 'mechanics', 'icon']
faltan = collections.Counter()
sin_campo = collections.defaultdict(list)
for s in spells:
    for f in required:
        if not s.get(f):
            faltan[f] += 1
            sin_campo[f].append(s['id'])
    if not s['classes']:
        faltan['classes'] += 1
        sin_campo['classes'].append(s['id'])
for f, n in faltan.most_common():
    ejemplos = ', '.join(sin_campo[f][:4])
    print('    %-14s %4d sin rellenar   %s' % (f, n, ejemplos))
if not faltan:
    print('    ninguno')

# --- 2) Lanzables: que tiene datos para resolverse solo
print('\n[2] RESOLUCION AUTOMATICA')
con_ataque = [s for s in spells if s['attack']]
con_salvacion = [s for s in spells if s['savingThrow']]
con_dano = [s for s in spells if s['damage']]
solo_texto = [s for s in spells if not s['attack'] and not s['savingThrow'] and not s['damage']]
print('    con tirada de ataque      %4d' % len(con_ataque))
print('    con tirada de salvacion   %4d' % len(con_salvacion))
print('    con dano declarado        %4d' % len(con_dano))
print('    SOLO informativos         %4d  (se anuncian, no se resuelven)' % len(solo_texto))

# Dano declarado pero sin ataque ni salvacion: no se sabe como aplicarlo.
huerfanos = [s for s in spells if s['damage'] and not s['attack'] and not s['savingThrow']]
print('\n[3] DANO SIN FORMA DE APLICARLO (ni ataque ni salvacion): %d' % len(huerfanos))
for s in huerfanos[:12]:
    print('    %-28s %s' % (s['id'], s['damage']))

# --- 4) Concentracion declarada contra duracion
print('\n[4] COHERENCIA DE CONCENTRACION')
inconsistentes = []
for s in spells:
    dur = (s['duration'] or '').lower()
    dice_conc = 'concentracion' in dur or 'concentración' in dur
    marcado = s['concentration'] == 'true'
    if dice_conc != marcado:
        inconsistentes.append((s['id'], s['duration'], marcado))
print('    marcados con concentracion: %d' % sum(1 for s in spells if s['concentration'] == 'true'))
print('    incoherentes duracion/marca: %d' % len(inconsistentes))
for sid, dur, marcado in inconsistentes[:10]:
    print('       %-26s duracion=%-32s marca=%s' % (sid, (dur or '')[:32], marcado))

# --- 5) Duplicados
print('\n[5] IDS Y NOMBRES DUPLICADOS')
ids = collections.Counter(s['id'] for s in spells)
nombres = collections.Counter((s['name'] or '').lower() for s in spells)
dup_id = [k for k, v in ids.items() if v > 1]
dup_nom = [k for k, v in nombres.items() if v > 1 and k]
print('    ids duplicados:     %d %s' % (len(dup_id), dup_id[:5]))
print('    nombres duplicados: %d %s' % (len(dup_nom), dup_nom[:5]))

# --- 6) Reparto por nivel y clase
print('\n[6] REPARTO')
por_nivel = collections.Counter(s['level'] for s in spells)
print('    por nivel: ' + '  '.join('%s:%d' % (k, por_nivel[k]) for k in sorted(por_nivel, key=lambda x: int(x or 0))))
por_clase = collections.Counter()
for s in spells:
    for c in s['classes']:
        por_clase[c] += 1
print('    por clase:')
for c, n in por_clase.most_common():
    print('        %-22s %4d' % (c, n))
sin_clase = [s['id'] for s in spells if not s['classes']]
if sin_clase:
    print('    SIN CLASE (%d): %s' % (len(sin_clase), ', '.join(sin_clase[:8])))
