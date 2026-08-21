# -*- coding: utf-8 -*-
"""Auditoria de integridad del sistema de profesiones.

Comprueba, contra los .lua de datos:
  1. claves de material/resultado que no existen en el REGISTRY
  2. claves declaradas sin itemId real (recetas "pendientes", no crafteables)
  3. materiales que ninguna receta produce (deben venir de mercader/loot/DM)
  4. profesiones craft sin recetas
  5. BLOQUEOS DE PROGRESION: con la regla de subida (gris = skillReq+100), para
     avanzar de skill X hace falta una receta con X-100 < skillReq <= X. Un hueco
     mayor de 100 entre recetas consecutivas deja la profesion atascada.
  6. remates worldLearned por profesion
  7. claves del registro que ninguna receta usa (huerfanas)
"""
import io
import re
import sys
import collections

sys.stdout.reconfigure(encoding='utf-8')

BASE = 'Harford/Professions/'
data = io.open(BASE + 'HarfordProfessionsData.lua', encoding='utf-8').read()
items = io.open(BASE + 'HarfordProfessionsItems.lua', encoding='utf-8').read()

# --- registro de items: ["clave"] = { id = N | nil, name = "..." }
registry, pending = {}, set()
for m in re.finditer(r'\["(\w+)"\]\s*=\s*\{([^}]*)\}', items):
    key, body = m.group(1), m.group(2)
    idm = re.search(r'\bid\s*=\s*(nil|\d+)', body)
    if not idm:
        continue
    registry[key] = None if idm.group(1) == 'nil' else int(idm.group(1))
    if idm.group(1) == 'nil':
        pending.add(key)

# --- profesiones
profs = {}
for m in re.finditer(
        r'\{\s*id\s*=\s*"(\w+)"\s*,\s*name\s*=\s*"([^"]+)"\s*,\s*tool\s*=\s*(nil|"[^"]*")\s*,\s*kind\s*=\s*"(\w+)"',
        data):
    profs[m.group(1)] = {'name': m.group(2), 'tool': m.group(3), 'kind': m.group(4)}

# --- recetas
recipes = []
for line in data.splitlines():
    if 'profession =' not in line or 'skillReq' not in line:
        continue
    rid = re.search(r'id\s*=\s*"([\w_]+)"', line)
    prof = re.search(r'profession\s*=\s*"(\w+)"', line)
    skill = re.search(r'skillReq\s*=\s*(\d+)', line)
    if not (rid and prof and skill):
        continue
    head, _, tail = line.partition('output =')
    mats = re.findall(r'\{\s*key\s*=\s*"(\w+)"\s*,\s*qty\s*=\s*(\d+)\s*\}', head)
    out = re.search(r'\{\s*key\s*=\s*"(\w+)"', tail)
    nm = re.search(r'name\s*=\s*"([^"]+)"', line)
    recipes.append({
        'id': rid.group(1),
        'prof': prof.group(1),
        'skill': int(skill.group(1)),
        'name': nm.group(1) if nm else '?',
        'materials': [(k, int(q)) for k, q in mats],
        'output': out.group(1) if out else None,
        'world': 'worldLearned = true' in line,
    })

print('PROFESIONES: %d   RECETAS: %d   CLAVES EN REGISTRO: %d (sin itemId: %d)'
      % (len(profs), len(recipes), len(registry), len(pending)))

# 1. claves inexistentes
missing = collections.defaultdict(list)
for r in recipes:
    for k, _ in r['materials']:
        if k not in registry:
            missing[k].append(r['id'])
    if r['output'] and r['output'] not in registry:
        missing[r['output']].append(r['id'] + ' (output)')
print('\n[1] CLAVES USADAS QUE NO EXISTEN EN EL REGISTRO: %d' % len(missing))
for k, v in sorted(missing.items()):
    print('    %-28s <- %s' % (k, ', '.join(v[:4])))

# 2. recetas bloqueadas por id pendiente
blocked = [r for r in recipes
           if (r['output'] in pending) or any(k in pending for k, _ in r['materials'])]
print('\n[2] RECETAS NO CRAFTEABLES (alguna clave sin itemId real): %d de %d'
      % (len(blocked), len(recipes)))
byprof = collections.Counter(r['prof'] for r in blocked)
for p, n in byprof.most_common():
    total = sum(1 for r in recipes if r['prof'] == p)
    print('    %-22s %d/%d' % (profs.get(p, {}).get('name', p), n, total))

# 3. materiales que nadie produce
produced = {r['output'] for r in recipes if r['output']}
consumed = {k for r in recipes for k, _ in r['materials']}
external = sorted(consumed - produced)
print('\n[3] MATERIALES QUE NINGUNA RECETA PRODUCE (mercader/loot/DM): %d' % len(external))
for k in external:
    tag = 'SIN ID' if k in pending else ('id %s' % registry.get(k, 'NO REGISTRADO'))
    print('    %-28s %s' % (k, tag))

# 4. profesiones sin recetas
withr = {r['prof'] for r in recipes}
print('\n[4] PROFESIONES SIN NINGUNA RECETA:')
for pid, p in profs.items():
    if pid not in withr:
        print('    %-22s (%s)' % (p['name'], p['kind']))

# 5. bloqueos de progresion
print('\n[5] PROGRESION DE SKILL (hueco > 100 = atasco; tope < 300 = no llega al maximo):')
for pid in sorted(withr):
    lv = sorted(r['skill'] for r in recipes if r['prof'] == pid)
    problems = []
    if lv[0] > 1:
        problems.append('empieza en %d' % lv[0])
    for a, b in zip(lv, lv[1:]):
        if b - a > 100:
            problems.append('hueco %d->%d' % (a, b))
    if lv[-1] + 100 < 300:
        problems.append('tope real %d/300' % (lv[-1] + 100))
    name = profs.get(pid, {}).get('name', pid)
    print('    %-22s %2d recetas  %3d..%3d   %s'
          % (name, len(lv), lv[0], lv[-1],
             'OK' if not problems else 'PROBLEMA: ' + '; '.join(problems)))

# 6. worldLearned
print('\n[6] REMATES worldLearned (se espera 1 por profesion):')
wl = collections.Counter(r['prof'] for r in recipes if r['world'])
for pid in sorted(withr):
    n = wl.get(pid, 0)
    print('    %-22s %d%s' % (profs.get(pid, {}).get('name', pid), n,
                              '' if n == 1 else '   <-- revisar'))

# 7. claves huerfanas del registro
used = consumed | produced
orphan = sorted(k for k in registry if k not in used)
print('\n[7] CLAVES DEL REGISTRO QUE NINGUNA RECETA USA: %d' % len(orphan))
for k in orphan:
    print('    %-28s id %s' % (k, registry[k]))
