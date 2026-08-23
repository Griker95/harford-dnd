# -*- coding: utf-8 -*-
"""Importa los iconos de la web (harfordweb) al catalogo del addon.

Sentido web -> addon. NO toca la web. La web MANDA: si un id tiene icono alli, ese gana sobre el
que tuviera el addon. Lo que la web no cubre se conserva tal cual, para no perder nada.

    python tools/codice/importar_iconos_web.py            # informe, no escribe
    python tools/codice/importar_iconos_web.py --escribir # aplica sobre HarfordIconCatalog.lua
    python tools/codice/importar_iconos_web.py --lista    # ademas vuelca el inventario completo

Que se reescribe de `HarfordIconCatalog.lua`:
  - `Catalog.features`   : id de rasgo -> icono.
  - `Catalog.spells`     : id de conjuro -> LISTA de candidatos; el de la web va el PRIMERO y se
                           conservan los que ya hubiera detras (los resuelve HarfordCompendioIconMap
                           con LibRPMedia, asi que un candidato de mas no estorba).
  - `Catalog.subclasses` : clase -> subclase -> icono.
Que NO se toca:
  - `Catalog.names`, que es el fallback POR NOMBRE y no tiene equivalente en la web.
  - Las funciones del final del fichero.
  - Los `icon = "..."` en linea de los ficheros de datos: el catalogo ya tiene prioridad sobre
    ellos en `HarfordDnDData.GetFeatureIcon`, asi que importar aqui basta para que mande la web.

OJO: que un icono este en la web no garantiza que exista en el cliente de Epsilon (AGENTS.md:
las texturas retail que faltan salen en verde). Validar en juego con `GetFileIDFromPath`.
"""
import io, os, re, sys, json, glob

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, '..', '..')) + '/'
WEB = 'C:/Users/marco/Documents/harfordweb/js/'
CATALOGO = RAIZ + 'Harford/Compendium/HarfordIconCatalog.lua'

ESCRIBIR = '--escribir' in sys.argv
LISTA = '--lista' in sys.argv


# ---------------------------------------------------------------- lectura de la web
def carga_web(nombre):
    ruta = WEB + nombre
    if not os.path.exists(ruta):
        print('  (falta %s)' % nombre)
        return None
    s = io.open(ruta, encoding='utf-8').read()
    # Los auxiliares abren con "window.X = window.X || {};" y DESPUES publican el literal.
    # El primer '{' del fichero es ese '{}' vacio, no el dato.
    for apertura, cierre in (('= [', ']'), ('= {', '}')):
        i = s.find(apertura)
        while i >= 0:
            try:
                return json.loads(s[i + 2:s.rfind(cierre) + 1])
            except Exception:
                i = s.find(apertura, i + 1)
    print('  (%s: no parsea)' % nombre)
    return None


def iconos_de_la_web():
    iconos = {}
    for fichero in ['compendium-data.js', 'compendium-dotes.js', 'compendium-equipment.js',
                    'compendium-languages.js', 'compendium-professions.js']:
        d = carga_web(fichero)
        if d is None:
            continue
        def anda(n):
            if isinstance(n, dict):
                i, ic = n.get('id'), n.get('icon')
                if isinstance(i, str) and isinstance(ic, str) and ic:
                    iconos.setdefault(i, ic)
                for v in n.values():
                    anda(v)
            elif isinstance(n, list):
                for v in n:
                    anda(v)
        anda(d)
    return iconos


# ---------------------------------------------------------------- lectura del addon
def bloque(texto, nombre):
    """Devuelve (inicio, fin, contenido) del cuerpo de `Catalog.<nombre> = { ... }`."""
    m = re.search(r'Catalog\.%s\s*=\s*\{' % nombre, texto)
    if not m:
        return None
    i = m.end()
    prof, j = 1, i
    while prof > 0 and j < len(texto):
        if texto[j] == '{':
            prof += 1
        elif texto[j] == '}':
            prof -= 1
        j += 1
    return (i, j - 1, texto[i:j - 1])


def ids_del_libro():
    """id -> nombre, de todo lo que el addon puede pedirle un icono al catalogo."""
    RE = re.compile(r'\{\s*id\s*=\s*"([a-z_0-9]+)"\s*,\s*(?:level\s*=\s*(\d+)\s*,\s*)?name\s*=\s*"([^"]+)"')
    rasgos = {}
    ficheros = sorted(glob.glob(RAIZ + 'Harford/DnD/Data/Classes/*.lua'))
    ficheros += [RAIZ + 'Harford/DnD/Data/HarfordDnDRaces.lua',
                 RAIZ + 'Harford/DnD/Data/HarfordDnDBackgrounds.lua',
                 RAIZ + 'Harford/DnD/Data/HarfordDnDFeats.lua']
    for f in ficheros:
        if not os.path.exists(f):
            continue
        s = io.open(f, encoding='utf-8').read()
        for m in RE.finditer(s):
            rasgos.setdefault(m.group(1), m.group(3))
    comp = RAIZ + 'Harford/Compendium/HarfordCompendioData.lua'
    conjuros = {}
    if os.path.exists(comp):
        s = io.open(comp, encoding='utf-8').read()
        for m in re.finditer(r'id = "([a-z_0-9]+)",(.{0,200}?)name = "([^"]+)"', s, re.S):
            conjuros.setdefault(m.group(1), m.group(3))
    return rasgos, conjuros


def subclases_del_libro():
    """classId -> [subclassId]. La primera subclase de cada fichero es la propia clase."""
    fuera = {}
    for f in sorted(glob.glob(RAIZ + 'Harford/DnD/Data/Classes/*.lua')):
        s = io.open(f, encoding='utf-8').read()
        mc = re.search(r'id = "([a-z_]+)", name = "[^"]+"', s)
        if not mc:
            continue
        classId = mc.group(1)
        m = re.search(r'subclasses\s*=\s*\{', s)
        if not m:
            continue
        i = m.end()
        prof, j = 1, i
        while prof > 0 and j < len(s):
            if s[j] == '{':
                prof += 1
            elif s[j] == '}':
                prof -= 1
            j += 1
        fuera[classId] = re.findall(r'id = "([a-z_]+)", name = "[A-Z]', s[i:j])
    return fuera


# ---------------------------------------------------------------- generacion
def escribe_features(mapa):
    lineas = []
    for k in sorted(mapa):
        lineas.append('    %s = "%s",' % (k, mapa[k]))
    return '\n' + '\n'.join(lineas) + '\n'


def escribe_spells(mapa):
    lineas = []
    for k in sorted(mapa):
        cands = ', '.join('"%s"' % c for c in mapa[k])
        lineas.append('    %s = { %s },' % (k, cands))
    return '\n' + '\n'.join(lineas) + '\n'


def escribe_subclases(mapa):
    lineas = []
    for clase in sorted(mapa):
        pares = ', '.join('%s = "%s"' % (s, mapa[clase][s]) for s in sorted(mapa[clase]))
        lineas.append('    %s = { %s },' % (clase, pares))
    return '\n' + '\n'.join(lineas) + '\n'


def main():
    web = iconos_de_la_web()
    rasgos, conjuros = ids_del_libro()
    subclases = subclases_del_libro()

    cat = io.open(CATALOGO, encoding='utf-8').read()
    b_feat = bloque(cat, 'features')
    b_spell = bloque(cat, 'spells')
    b_sub = bloque(cat, 'subclasses')
    if not (b_feat and b_spell and b_sub):
        print('No se reconocieron las tablas del catalogo; aborto.')
        return 1

    viejo_feat = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', b_feat[2]))
    viejo_spell = {}
    for m in re.finditer(r'(\w+)\s*=\s*\{([^}]*)\}', b_spell[2]):
        viejo_spell[m.group(1)] = re.findall(r'"([^"]+)"', m.group(2))
    viejo_sub = {}
    for m in re.finditer(r'(\w+)\s*=\s*\{([^}]*)\}', b_sub[2]):
        viejo_sub[m.group(1)] = dict(re.findall(r'(\w+)\s*=\s*"([^"]+)"', m.group(2)))

    # --- features: la web manda; lo que no cubre, se conserva.
    nuevo_feat = dict(viejo_feat)
    cambiados, anadidos = [], []
    for fid in rasgos:
        ic = web.get(fid)
        if not ic:
            continue
        if fid not in nuevo_feat:
            anadidos.append((fid, ic))
            nuevo_feat[fid] = ic
        elif nuevo_feat[fid] != ic:
            cambiados.append((fid, nuevo_feat[fid], ic))
            nuevo_feat[fid] = ic

    # --- spells: el de la web va el PRIMERO, los candidatos previos detras.
    nuevo_spell = {k: list(v) for k, v in viejo_spell.items()}
    s_cambiados, s_anadidos = [], []
    for sid in conjuros:
        ic = web.get(sid)
        if not ic:
            continue
        previos = [c for c in nuevo_spell.get(sid, []) if c != ic]
        if sid not in nuevo_spell:
            s_anadidos.append((sid, ic))
        elif nuevo_spell[sid][:1] != [ic]:
            s_cambiados.append((sid, nuevo_spell[sid][0] if nuevo_spell[sid] else '-', ic))
        nuevo_spell[sid] = [ic] + previos

    # --- subclases: la web publica el icono con el id de la subclase suelto.
    nuevo_sub = {c: dict(v) for c, v in viejo_sub.items()}
    sub_cambios = []
    for clase, subs in subclases.items():
        for sub in subs:
            ic = web.get(sub)
            if not ic:
                continue
            antes = nuevo_sub.get(clase, {}).get(sub)
            if antes != ic:
                sub_cambios.append((clase, sub, antes or '-', ic))
                nuevo_sub.setdefault(clase, {})[sub] = ic

    print('IMPORTACION DE ICONOS  (web -> addon)')
    print('  web: %d ids con icono' % len(web))
    print()
    print('  features : %d anadidos, %d cambiados  (total %d)'
          % (len(anadidos), len(cambiados), len(nuevo_feat)))
    print('  spells   : %d anadidos, %d cambiados  (total %d)'
          % (len(s_anadidos), len(s_cambiados), len(nuevo_spell)))
    print('  subclases: %d cambios' % len(sub_cambios))
    print()
    if cambiados:
        print('  Ejemplos de icono SUSTITUIDO por el de la web:')
        for fid, a, b in cambiados[:10]:
            print('     %-34s %-32s -> %s' % (fid, a, b))
        print()

    sin_icono = [(k, v) for k, v in sorted(rasgos.items())
                 if k not in nuevo_feat and k not in web]
    sin_conj = [(k, v) for k, v in sorted(conjuros.items()) if k not in nuevo_spell]
    print('  QUEDAN SIN ICONO: %d rasgos, %d conjuros' % (len(sin_icono), len(sin_conj)))

    if LISTA:
        destino = os.path.join(AQUI, '_iconos_inventario.csv')
        with io.open(destino, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write('tipo;id;nombre;icono_addon;icono_web;resultado;estado\n')
            for k, v in sorted(rasgos.items()):
                a, w = viejo_feat.get(k), web.get(k)
                r = nuevo_feat.get(k)
                estado = 'sin icono' if not r else ('nuevo de la web' if not a and w else
                         ('sustituido por la web' if w and a != w else 'del addon'))
                fh.write('rasgo;%s;%s;%s;%s;%s;%s\n' % (k, v, a or '', w or '', r or '', estado))
            for k, v in sorted(conjuros.items()):
                a = (viejo_spell.get(k) or [''])[0]
                w = web.get(k)
                r = (nuevo_spell.get(k) or [''])[0]
                estado = 'sin icono' if not r else ('nuevo de la web' if not a and w else
                         ('sustituido por la web' if w and a != w else 'del addon'))
                fh.write('conjuro;%s;%s;%s;%s;%s;%s\n' % (k, v, a, w or '', r, estado))
        print('  lista completa -> %s' % destino)

    if not ESCRIBIR:
        print()
        print('  (informe; nada escrito. Repite con --escribir para aplicar)')
        return 0

    salida = (cat[:b_feat[0]] + escribe_features(nuevo_feat) + cat[b_feat[1]:b_spell[0]]
              + escribe_spells(nuevo_spell) + cat[b_spell[1]:b_sub[0]]
              + escribe_subclases(nuevo_sub) + cat[b_sub[1]:])
    io.open(CATALOGO, 'w', encoding='utf-8', newline='\n').write(salida)
    print()
    print('  escrito %s' % CATALOGO)
    return 0


if __name__ == '__main__':
    sys.exit(main())
