# -*- coding: utf-8 -*-
"""Genera el borrador de definiciones para HarfordItemForge.

Clasifica en tres pasadas, de mas fiable a menos:

  1. PROFESION  de la receta donde aparece la clave. Es el dato mas solido: lo que sale de
     alquimia es consumible y lo que sale de sastreria es tela, se llame como se llame.
  2. PAPEL      resultado o materia prima. Un resultado de herreria es un arma o una armadura;
     una materia prima de herreria es metal.
  3. NOMBRE     solo para afinar DENTRO de lo anterior: que tipo de arma, que hueco de armadura,
     o si un "resultado" es en realidad un intermedio (una barra, un fardo de tela).

Lo que el generador no puede saber es la DESCRIPCION: ese campo queda vacio a proposito.
"""
import io
import json
import os
import re
import sys
import collections
import unicodedata

sys.stdout.reconfigure(encoding='utf-8')

REGISTRO = 'Harford/Professions/HarfordProfessionsItems.lua'
RECETAS = 'Harford/Professions/HarfordProfessionsData.lua'
SALIDA = 'AddonsIndependientes/HarfordItemForge/Data.lua'

# La KB es lo que consume la web: se usa para COTEJAR, de modo que nada publicado en el
# codice se quede fuera de la lista sin avisar, y para completar iconos que falten.
KB = 'tools/codice/kb.json'

# Capa de anulaciones. Es el canal por el que entra la informacion que el generador no
# puede deducir (descripciones, correcciones puntuales) y lo unico que sobrevive intacto a
# cada regeneracion. Se puede editar a mano o rellenar desde la web.
ANULACIONES = 'tools/codice/itemforge_anulaciones.json'

# ── Clases de objeto (wow.gamepedia.com/ItemType) ───────────────────────────
CONSUM, TRADE, WEAPON, ARMOR, MISC = 0, 7, 2, 4, 15

# Subclases de consumible
C_POCION, C_ELIXIR, C_COMIDA, C_VENDAJE, C_OTRO = 1, 2, 5, 7, 8
# Subclases de bien comercial
T_GEN, T_PIEZAS, T_JOYERIA, T_TELA, T_CUERO, T_METAL, T_CARNE, T_HIERBA, T_ENCANT, T_OTRO = \
    0, 1, 4, 5, 6, 7, 8, 9, 12, 11
# Subclases de armadura
A_MISC, A_TELA, A_CUERO, A_MALLA, A_PLACAS, A_ESCUDO = 0, 1, 2, 3, 4, 6
# Subclases de arma
W_HACHA1, W_HACHA2, W_ARCO, W_ARMAFUEGO, W_MAZA1, W_MAZA2, W_ASTA, W_ESPADA1, W_ESPADA2 = \
    0, 1, 2, 3, 4, 5, 6, 7, 8
W_BACULO, W_PUNOS, W_DAGA, W_BALLESTA, W_VARITA = 10, 13, 15, 18, 19

# Enum.InventoryType: hueco donde se equipa
INV = {'cabeza': 1, 'cuello': 2, 'hombros': 3, 'pecho': 5, 'cintura': 6, 'piernas': 7,
       'pies': 8, 'muneca': 9, 'manos': 10, 'dedo': 11, 'abalorio': 12, 'unamano': 13,
       'escudo': 14, 'distancia': 15, 'espalda': 16, 'dosmanos': 17, 'principal': 21,
       'secundaria': 22}

# ── Nombre -> tipo de arma ──────────────────────────────────────────────────
ARMAS = [
    (r'\bdaga|punal|estilete\b', W_DAGA, 'unamano'),
    (r'\bespada de dos manos|mandoble|espada bastarda|espadon\b', W_ESPADA2, 'dosmanos'),
    (r'\bespada|sable|cimitarra\b', W_ESPADA1, 'unamano'),
    (r'\bhacha de dos manos|hachon\b', W_HACHA2, 'dosmanos'),
    (r'\bhacha\b', W_HACHA1, 'unamano'),
    (r'\bmartillo de guerra|maza de dos manos\b', W_MAZA2, 'dosmanos'),
    (r'\bmaza|martillo|clava|garrote\b', W_MAZA1, 'unamano'),
    (r'\blanza|alabarda|guja|pica\b', W_ASTA, 'dosmanos'),
    (r'\bbaculo|baston|vara\b', W_BACULO, 'dosmanos'),
    (r'\barco\b', W_ARCO, 'distancia'),
    (r'\bballesta\b', W_BALLESTA, 'distancia'),
    (r'\brifle|mosquete|pistola|trabuco\b', W_ARMAFUEGO, 'distancia'),
    (r'\bvarita\b', W_VARITA, 'distancia'),
    (r'\bpuno|garra|nudillo\b', W_PUNOS, 'unamano'),
]

# ── Nombre -> hueco de armadura ─────────────────────────────────────────────
HUECOS = [
    (r'\byelmo|casco|capucha|corona|diadema|capirote|sombrero\b', 'cabeza'),
    (r'\bhombreras|espaldares|charnelas\b', 'hombros'),
    (r'\bcoraza|cota|tunica|peto|jubon|camisa|pechera|armadura de\b', 'pecho'),
    (r'\bcinturon|faja|cincha\b', 'cintura'),
    (r'\bgrebas|quijotes|pantalones|calzas|musleras\b', 'piernas'),
    (r'\bbotas|zapatos|sandalias|escarpes\b', 'pies'),
    (r'\bbrazales|munequeras|manoplas de antebrazo\b', 'muneca'),
    (r'\bguanteletes|guantes|manoplas\b', 'manos'),
    (r'\bcapa|manto|capote\b', 'espalda'),
    (r'\bescudo|broquel|rodela\b', 'escudo'),
    (r'\banillo|sortija\b', 'dedo'),
    (r'\bamuleto|collar|colgante|gargantilla\b', 'cuello'),
    (r'\babalorio|talisman|idolo|totem\b', 'abalorio'),
]

# Materiales de armadura que trabaja cada profesion.
ARMADURA_DE = {'sastreria': A_TELA, 'peleteria': A_CUERO, 'herreria': A_PLACAS,
               'joyeria': A_MISC, 'ingenieria': A_MALLA}

# Un "resultado" que en realidad es un INTERMEDIO: la profesion lo fabrica, pero es material
# para la siguiente receta. Se detecta por nombre y manda sobre el papel.
INTERMEDIOS = [
    (r'\bbarra|lingote\b', T_METAL),
    (r'\bfardo|bala de|hilo|madeja\b', T_TELA),
    (r'\bcuero curtido|cuero grueso|cuero rigido|pergamino de cuero\b', T_CUERO),
    (r'\bpolvo|esencia|fragmento|cristal|astilla\b', T_ENCANT),
    (r'\btinta|pigmento\b', T_OTRO),
]

# Materia prima segun la profesion que la usa o recolecta.
MATERIA_DE = {'mineria': T_METAL, 'herboristeria': T_HIERBA, 'desollar': T_CUERO,
              'pesca': T_CARNE, 'cocina': T_CARNE, 'sastreria': T_TELA,
              'peleteria': T_CUERO, 'herreria': T_METAL, 'joyeria': T_JOYERIA,
              'encantamiento': T_ENCANT, 'ingenieria': T_PIEZAS,
              'alquimia': T_HIERBA, 'inscripcion': T_HIERBA}

# Consumible segun la profesion que lo produce.
CONSUMIBLE_DE = {'alquimia': C_POCION, 'cocina': C_COMIDA, 'primeros_auxilios': C_VENDAJE,
                 'envenenador': C_OTRO, 'inscripcion': C_OTRO}


def sin_tildes(t):
    for a, b in zip('áéíóúüñÁÉÍÓÚÑ', 'aeiouunAEIOUN'):
        t = t.replace(a, b)
    return t


def clasifica(nombre, profesion, papel):
    """Devuelve (clase, subclase, hueco, apilable, calidad)."""
    n = sin_tildes(nombre.lower())

    # 1) Herramientas y kits, se produzcan donde se produzcan.
    if re.search(r'\bherramientas|kit de|suministros|utiles|juego de\b', n):
        return MISC, 0, 0, 1, 1

    # 2) Un intermedio manda sobre el papel: lo fabrica la profesion pero es material.
    for patron, sub in INTERMEDIOS:
        if re.search(patron, n):
            return TRADE, sub, 0, 20, 1

    if papel == 'material':
        return TRADE, MATERIA_DE.get(profesion, T_GEN), 0, 20, 1

    # 3) Resultado: primero si es equipable, por nombre.
    for patron, sub, hueco in ARMAS:
        if re.search(patron, n):
            return WEAPON, sub, INV[hueco], 1, 1
    for patron, hueco in HUECOS:
        if re.search(patron, n):
            sub = A_ESCUDO if hueco == 'escudo' else ARMADURA_DE.get(profesion, A_MISC)
            if hueco in ('dedo', 'cuello', 'abalorio'):
                sub = A_MISC
            return ARMOR, sub, INV[hueco], 1, 1

    # 4) No es equipable: consumible si la profesion los hace, si no bien comercial.
    if profesion in CONSUMIBLE_DE:
        sub = CONSUMIBLE_DE[profesion]
        if re.search(r'\belixir\b', n):
            sub = C_ELIXIR
        elif re.search(r'\bracion|pan|estofado|guiso|asado|filete|sopa\b', n):
            sub = C_COMIDA
        return CONSUM, sub, 0, 20, 1
    return TRADE, MATERIA_DE.get(profesion, T_GEN), 0, 20, 1


# ── Leer el registro ─────────────────────────────────────────────────────────
texto = io.open(REGISTRO, encoding='utf-8').read()
entradas = []
for m in re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{([^}]*)\}', texto):
    clave, cuerpo = m.group(1), m.group(2)
    idm = re.search(r'\bid\s*=\s*(\d+)', cuerpo)
    nom = re.search(r'\bname\s*=\s*"([^"]*)"', cuerpo)
    ico = re.search(r'\bicon\s*=\s*"([^"]*)"', cuerpo)
    entradas.append({'clave': clave, 'id': int(idm.group(1)) if idm else None,
                     'nombre': nom.group(1) if nom else clave,
                     'icono': ico.group(1) if ico else None})

# ── Cruzar con las recetas ───────────────────────────────────────────────────
recetas = io.open(RECETAS, encoding='utf-8').read()
comoResultado, profesionDe, comoMaterial = set(), {}, set()
for m in re.finditer(r'\{\s*id\s*=\s*"[^"]+",\s*profession\s*=\s*"([a-z_]+)"(.*?)\n', recetas):
    prof, resto = m.group(1), m.group(2)
    for bloque in re.findall(r'materials\s*=\s*\{(.*?)\}\s*\}', resto):
        for key in re.findall(r'key\s*=\s*"([a-z0-9_]+)"', bloque):
            comoMaterial.add(key)
            profesionDe.setdefault(key, prof)
    salida = re.search(r'output\s*=\s*\{\s*key\s*=\s*"([a-z0-9_]+)"', resto)
    if salida:
        comoResultado.add(salida.group(1))
        profesionDe[salida.group(1)] = prof

pendientes = [e for e in entradas if e['id'] is None]
print("Claves: %d   con id: %d   PENDIENTES: %d"
      % (len(entradas), len(entradas) - len(pendientes), len(pendientes)))

# ── Anulaciones ──────────────────────────────────────────────────────────────
anulaciones = {}
if os.path.exists(ANULACIONES):
    anulaciones = json.load(io.open(ANULACIONES, encoding='utf-8'))
    anulaciones.pop('_nota', None)
print("Anulaciones cargadas: %d" % len(anulaciones))

# ── Cotejo con la KB de la web ───────────────────────────────────────────────
def sinTildes(t):
    t = unicodedata.normalize('NFD', t or '')
    return ''.join(c for c in t if unicodedata.category(c) != 'Mn').lower().strip()

porNombre = {}
for e in entradas:
    porNombre.setdefault(sinTildes(e['nombre']), e)

if os.path.exists(KB):
    kb = json.load(io.open(KB, encoding='utf-8'))
    enLaWeb, iconosWeb = {}, {}
    for prof in kb.get('professions', []):
        for r in prof.get('recipes', []):
            if r.get('out'):
                enLaWeb[sinTildes(r['out'])] = r['out']
                if r.get('icon'):
                    iconosWeb[sinTildes(r['out'])] = r['icon']
            for mat in r.get('mats', []):
                if mat.get('name'):
                    enLaWeb[sinTildes(mat['name'])] = mat['name']
    huerfanos = sorted(v for k, v in enLaWeb.items() if k not in porNombre)
    print("Cotejo con la KB: %d objetos publicados, %d sin clave en el registro"
          % (len(enLaWeb), len(huerfanos)))
    for n in huerfanos[:10]:
        print("   sin clave: %s" % n)
    if len(huerfanos) > 10:
        print("   ... y %d mas" % (len(huerfanos) - 10))
    # El icono de la web manda cuando el registro no trae ninguno.
    prestados = 0
    for e in pendientes:
        if not e['icono']:
            ico = iconosWeb.get(sinTildes(e['nombre']))
            if ico:
                e['icono'] = ico
                prestados += 1
    if prestados:
        print("Iconos tomados de la web: %d" % prestados)
else:
    print("Sin %s: se genera solo desde el registro." % KB)

# ── Emitir ───────────────────────────────────────────────────────────────────
NOMCLASE = {CONSUM: 'consumible', TRADE: 'material', WEAPON: 'arma', ARMOR: 'armadura',
            MISC: 'utiles'}
out = ["-- GENERADO por tools/codice/gen_itemforge_data.py. Regenerable: no editar a mano lo que",
       "-- el generador deduce: se regenera y se pierde. Lo que se escribe a mano o llega de la",
       "-- web va en tools/codice/itemforge_anulaciones.json, que se aplica encima al generar.",
       "--",
       "-- Clasificado por PROFESION de la receta, luego por PAPEL (resultado o materia prima) y",
       "-- solo despues por nombre, para afinar tipo de arma y hueco de armadura.",
       "--",
       "-- clase/subclase/hueco son los enums de WoW; hueco 0 = no equipable.",
       "-- Todos se abren para que cualquiera pueda .additem salvo los marcados additem = false.",
       "",
       "HarfordItemForgeData = HarfordItemForgeData or {}",
       "HarfordItemForgeData.ITEMS = {"]

def papelDe(clave):
    if clave in comoResultado:
        return 'resultado'
    return 'material' if clave in comoMaterial else 'suelto'

# El orden del archivo ES el orden de forjado, y la profesion es la unidad de lote: primero
# los productos finales de cada profesion, despues sus materias primas.
ORDEN_PAPEL = {'resultado': 0, 'material': 1, 'suelto': 2}
def orden(e):
    prof = profesionDe.get(e['clave'], '')
    return (prof == '', prof, ORDEN_PAPEL[papelDe(e['clave'])], e['nombre'].lower())

def escapa(t):
    # La descripcion puede venir de la web: se escapa para no romper el Lua.
    return '"%s"' % (t or '').replace('\\', '\\\\').replace('"', '\\"').replace('\\n', ' ')

reparto = collections.Counter()
porProf = collections.Counter()
anuladas = collections.Counter()
cerrados = []
profPrevia = None
for e in sorted(pendientes, key=orden):
    prof = profesionDe.get(e['clave'], '')
    papel = papelDe(e['clave'])
    clase, subclase, hueco, apilable, calidad = clasifica(e['nombre'], prof, papel)
    reparto[NOMCLASE[clase]] += 1
    porProf[prof or '(sin receta)'] += 1
    if prof != profPrevia:
        out.append('')
        out.append('    -- %s' % (prof.upper() if prof else 'SIN RECETA (sueltos)'))
        profPrevia = prof
    campos = {'nombre': e['nombre'], 'icono': e['icono'], 'calidad': calidad,
              'clase': clase, 'subclase': subclase, 'hueco': hueco,
              'apilable': apilable, 'vinculacion': 0, 'desc': '', 'additem': True,
              'display': None}
    # Lo escrito a mano o traido de la web pisa lo deducido, nunca al reves.
    for campo, valor in (anulaciones.get(e['clave']) or {}).items():
        if campo in campos:
            campos[campo] = valor
            anuladas[campo] += 1

    icono = ('"%s"' % campos['icono']) if campos['icono'] else 'nil'
    out.append('    { clave = "%s", nombre = %s,' % (e['clave'], escapa(campos['nombre'])))
    out.append('      prof = %s, papel = "%s",'
               % (('"%s"' % prof) if prof else 'nil', papel))
    out.append('      icono = %s, calidad = %d, clase = %d, subclase = %d, hueco = %d,'
               % (icono, campos['calidad'], campos['clase'], campos['subclase'],
                  campos['hueco']))
    out.append('      apilable = %d, vinculacion = %d, desc = %s,'
               % (campos['apilable'], campos['vinculacion'], escapa(campos['desc'])))
    if campos['display']:
        out.append('      display = %d,   -- modelo del objeto original de WoW'
                   % int(campos['display']))
    if campos['additem'] is False:
        out.append('      additem = false,   -- cerrado: solo su creador puede .additem')
        cerrados.append(e['clave'])
    out.append('    },')
out.append("}")
out.append("")
io.open(SALIDA, 'w', encoding='utf-8', newline='').write("\n".join(out))

print("Escrito %s" % SALIDA)
print()
print("Reparto por clase:")
for k, v in reparto.most_common():
    print("   %-12s %5d  (%.0f%%)" % (k, v, 100 * v / len(pendientes)))
print()
print("Reparto por PROFESION (cada una es un lote de forjado):")
for k, v in porProf.most_common():
    print("   %-16s %5d" % (k, v))
if anuladas:
    print()
    print("Campos tomados de las anulaciones:")
    for k, v in anuladas.most_common():
        print("   %-12s %5d" % (k, v))
sinDesc = sum(1 for e in pendientes
              if not (anulaciones.get(e['clave']) or {}).get('desc'))
print()
if cerrados:
    print()
    print("Cerrados a .additem (%d): %s" % (len(cerrados), ", ".join(cerrados[:8])))
print("Sin descripcion: %d de %d. Se rellenan en %s." % (sinDesc, len(pendientes), ANULACIONES))
