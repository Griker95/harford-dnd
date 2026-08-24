# -*- coding: utf-8 -*-
"""Trazabilidad de ids: donde vive cada uno y si algo quedo colgando.

Uso:  python tools/trazar_ids.py            resumen
      python tools/trazar_ids.py <id>       la ficha completa de un id
      python tools/trazar_ids.py --rotos    solo lo que esta mal

Sigue cada id por las SEIS superficies donde puede aparecer, y el valor esta en cruzarlas: un id
declarado que nadie referencia es inofensivo, pero una REFERENCIA a un id que ya no existe es un
rasgo que desaparece en juego sin dar error.

  1. declaracion   el fichero de datos donde nace
  2. iconos        HarfordIconCatalog
  3. web           harfordweb (fuente canonica de contenido)
  4. equivalencia  ALIAS_WEB del importador, para los renombrados
  5. migracion     IDS_RENOMBRADOS de la progresion, para datos de jugador
  6. jugador       SavedVariables reales
"""
import io, os, re, sys, glob, collections

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_DIR = 'C:/Users/marco/Documents/harfordweb/js'
SV_GLOB = r"G:/Epsilon/_retail_/WTF/Account/**/SavedVariables/Harford*.lua"


def lee(p):
    try:
        return io.open(p, encoding='utf-8', errors='replace').read()
    except Exception:
        return ''


def ruta(*partes):
    return os.path.join(RAIZ, *partes)


# ------------------------------------------------------------------ superficies
def declaraciones():
    """{id: (fichero, espacio)} -- de donde nace cada id."""
    fuera = {}
    FUENTES = [
        ('Harford/DnD/Data/Classes/*.lua', 'rasgo de clase'),
        ('Harford/DnD/Data/HarfordDnDFeats.lua', 'dote'),
        ('Harford/DnD/Data/HarfordDnDRaces.lua', 'raza'),
        ('Harford/DnD/Data/HarfordDnDBackgrounds.lua', 'trasfondo'),
        ('Harford/DnD/Data/HarfordDnDData.lua', 'herramienta/dato'),
        ('HarfordProfessionsData/HarfordProfessionsData.lua', 'profesion'),
        ('HarfordCompendioData/HarfordCompendioData.lua', 'conjuro'),
    ]
    for patron, espacio in FUENTES:
        for f in sorted(glob.glob(ruta(*patron.split('/')))):
            rel = os.path.relpath(f, RAIZ).replace(os.sep, '/')
            for m in re.finditer(r'id\s*=\s*"([a-z_0-9]+)"', lee(f)):
                fuera.setdefault(m.group(1), (rel, espacio))
    return fuera


def en_catalogo():
    t = lee(ruta('Harford', 'Compendium', 'HarfordIconCatalog.lua'))
    fuera = {}
    for m in re.finditer(r'^\s*([a-z_0-9]+)\s*=\s*"([^"]+)"', t, re.M):
        fuera.setdefault(m.group(1), m.group(2))
    for m in re.finditer(r'^\s*\["([^"]+)"\]\s*=\s*"([^"]+)"', t, re.M):
        fuera.setdefault(m.group(1), m.group(2))
    return fuera


def en_web():
    ids = set()
    for f in glob.glob(os.path.join(WEB_DIR, '*.js')):
        for m in re.finditer(r'"id"\s*:\s*"([a-z_0-9]+)"', lee(f)):
            ids.add(m.group(1))
    return ids


def alias_web():
    t = lee(ruta('tools', 'codice', 'importar_iconos_web.py'))
    return dict(re.findall(r"^    '([a-z_0-9]+)': '([a-z_0-9]+)',", t, re.M))


def migracion():
    t = lee(ruta('Harford', 'DnD', 'State', 'HarfordDnDProgression.lua'))
    i = t.find('local IDS_RENOMBRADOS = {')
    if i < 0:
        return {}
    j = t.find('\n}', i)
    return dict(re.findall(r'\["([a-z_0-9]+)"\] = "([a-z_0-9]+)"', t[i:j]))


# Solo los bloques que guardan ids de RASGO. El resto de SavedVariables de Harford (loot, fases,
# facciones, ajustes) usa claves snake_case que no son ids de rasgo, y meterlas aqui ahogaba el
# informe en 31000 falsos positivos.
BLOQUES_DE_RASGO = ('choices', 'featureStates', 'featureUses', 'activeStates', 'feats')


def en_jugador():
    """Ids de rasgo que aparecen en SavedVariables reales, con el fichero donde salen."""
    fuera = collections.defaultdict(set)
    for f in glob.glob(SV_GLOB, recursive=True):
        nombre = os.path.basename(f)
        t = lee(f)
        for bloque in BLOQUES_DE_RASGO:
            for m in re.finditer(r'\["%s"\] = \{' % bloque, t):
                j = t.find('{', m.start())
                prof, k = 0, j
                while k < len(t):
                    if t[k] == '{':
                        prof += 1
                    elif t[k] == '}':
                        prof -= 1
                        if prof == 0:
                            break
                    k += 1
                trozo = t[j:k]
                for mm in re.finditer(r'\["([a-zA-Z_0-9]+)"\]', trozo):
                    fuera[mm.group(1)].add(nombre)
                for mm in re.finditer(r'^\s*"([a-z_0-9]+)",', trozo, re.M):
                    fuera[mm.group(1)].add(nombre)
    return fuera


def referencias(ids):
    """{id: [ficheros]} contando SOLO posiciones de id, no texto libre."""
    fuera = collections.defaultdict(set)
    for f in glob.glob(ruta('Harford*', '**', '*.lua'), recursive=True):
        rel = os.path.relpath(f, RAIZ).replace(os.sep, '/')
        t = lee(f)
        for m in re.finditer(r'(?:id\s*=\s*|\[)"([a-z_0-9]+)"', t):
            if m.group(1) in ids:
                fuera[m.group(1)].add(rel)
        for m in re.finditer(r'^\s*([a-z_0-9]+)\s*=\s*"', t, re.M):
            if m.group(1) in ids:
                fuera[m.group(1)].add(rel)
    return fuera


# ------------------------------------------------------------------ informe
def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ''
    decl = declaraciones()
    cat = en_catalogo()
    web = en_web()
    alias = alias_web()
    mig = migracion()
    jug = en_jugador()
    refs = referencias(set(decl) | set(mig) | set(mig.values()))

    if arg and not arg.startswith('--'):
        fid = arg
        print('TRAZA DE  %s' % fid)
        print('=' * 74)
        d = decl.get(fid)
        print('  1. declaracion   %s' % ('%s  (%s)' % (d[0], d[1]) if d else 'NO SE DECLARA'))
        print('  2. iconos        %s' % (cat.get(fid) or '-'))
        print('  3. web           %s' % ('si' if fid in web else 'no'))
        print('  4. equivalencia  %s' % (('%s -> %s' % (alias[fid], fid)) if fid in alias else '-'))
        vieja = [v for v, n in mig.items() if n == fid]
        print('  5. migracion     %s' % (('desde ' + ', '.join(vieja)) if vieja else
                                         ('renombrado a ' + mig[fid] if fid in mig else '-')))
        print('  6. jugador       %s' % (', '.join(sorted(jug.get(fid, []))) or 'no aparece'))
        print('  referencias      %s' % (', '.join(sorted(refs.get(fid, []))) or 'ninguna'))
        return 0

    print('TRAZABILIDAD DE IDS')
    print('=' * 74)
    print('  declarados en datos ............ %d' % len(decl))
    print('  con icono en el catalogo ....... %d' % len(cat))
    print('  presentes en la web ............ %d' % len(web))
    print('  con equivalencia web ........... %d' % len(alias))
    print('  en la tabla de migracion ....... %d' % len(mig))
    print('  vistos en datos de jugador ..... %d' % len(jug))
    print()

    # --- lo que puede estar roto
    roto = collections.OrderedDict()

    roto['migracion apunta a un id inexistente'] = \
        ['%s -> %s' % (v, n) for v, n in mig.items() if n not in decl]

    roto['id viejo todavia DECLARADO'] = [v for v in mig if v in decl]

    # una referencia a un id que ni se declara ni se migra: eso si desaparece en juego
    conocidos = set(decl) | set(mig)
    roto['referencia a un id que no existe'] = \
        ['%s (en %s)' % (k, ', '.join(sorted(v)[:2])) for k, v in refs.items()
         if k not in conocidos]

    roto['guardado por el jugador y sin destino'] = \
        [k for k in jug if k not in conocidos and re.match(r'^[a-z]+_[a-z_0-9]+$', k)
         and not k.startswith(('res_', 'hab_', 'salv_'))]

    roto['renombrado, sigue en la web y sin equivalencia'] = \
        ['%s' % v for v, n in mig.items() if v in web and n not in alias]

    hay = False
    for titulo, lista in roto.items():
        estado = 'ok' if not lista else 'FALLA (%d)' % len(lista)
        print('  %-52s %s' % (titulo, estado))
        for x in list(lista)[:6]:
            print('        %s' % x)
        if len(lista) > 6:
            print('        ... y %d mas' % (len(lista) - 6))
        if lista:
            hay = True

    print()
    if hay:
        print('HAY IDS ROTOS. Traza uno con:  python tools/trazar_ids.py <id>')
        return 1
    print('TRAZA LIMPIA: ningun id roto ni colgando')
    return 0


if __name__ == '__main__':
    sys.exit(main())
