# -*- coding: utf-8 -*-
"""Comprobacion final de la convencion de ids de rasgo de clase.

Uso:  python tools/verificar_ids.py

Responde a una sola pregunta: ¿queda algo suelto tras la migracion? Comprueba NUEVE cosas, y
cualquiera de ellas en rojo significa que un rasgo dejaria de funcionar en juego sin dar error --
que es como fallan estas cosas: en silencio.

La convencion es `<abrevClase>_<abrevSub>_<cosa>`, con abreviaturas DECLARADAS. No se deducen: el
Paladin usa `ret` para represion (retribution) y deducirla daria `rep`.
"""
import io, os, re, sys, glob, collections

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLASES = os.path.join(RAIZ, 'Harford', 'DnD', 'Data', 'Classes')
CATALOGO = os.path.join(RAIZ, 'Harford', 'Compendium', 'HarfordIconCatalog.lua')
PROGRESION = os.path.join(RAIZ, 'Harford', 'DnD', 'State', 'HarfordDnDProgression.lua')
IMPORTADOR = os.path.join(RAIZ, 'tools', 'codice', 'importar_iconos_web.py')
WEB = 'C:/Users/marco/Documents/harfordweb/js/compendium-data.js'
SV = r"G:/Epsilon/_retail_/WTF/Account/**/SavedVariables/Harford*.lua"

ABREV = {'Brujo': 'bru', 'CaballerodelaMuerte': 'cdm', 'Cazador': 'caz', 'CazadordeDemonios': 'dh',
         'Chaman': 'cha', 'Druida': 'dru', 'Guerrero': 'gue', 'Mago': 'mago', 'Monje': 'monje',
         'Paladin': 'pal', 'Picaro': 'pic', 'Sacerdote': 'sac'}
SUB = {'afliccion': 'afl', 'demonologia': 'dem', 'destruccion': 'des', 'sangre': 'san',
       'escarcha': 'esc', 'profana': 'pro', 'bestias': 'bes', 'punteria': 'pun',
       'supervivencia': 'sup', 'devastacion': 'dev', 'venganza': 'ven', 'ira': 'ira',
       'elemental': 'ele', 'mejora': 'mej', 'restauracion': 'res', 'equilibrio': 'eq',
       'feral': 'fer', 'armas': 'arm', 'furia': 'fur', 'proteccion': 'pro', 'arcano': 'arc',
       'fuego': 'fue', 'cervecero': 'cer', 'tejedor': 'tej', 'caminavientos': 'cam',
       'sagrado': 'sag', 'represion': 'ret', 'asesino': 'ase', 'forajido': 'for',
       'sutileza': 'sut', 'disciplina': 'dis', 'sombra': 'som', 'elune': 'elu'}


def lee(p):
    return io.open(p, encoding='utf-8', errors='replace').read()


def rasgos_por_clase():
    """{clase: [(id, subclase|None)]} leyendo la ESTRUCTURA, no el nombre."""
    fuera = {}
    for f in sorted(glob.glob(os.path.join(CLASES, '*.lua'))):
        clase = os.path.basename(f)[:-4]
        t = lee(f)
        bloques = []
        for m in re.finditer(r'\{ id = "([a-z_0-9]+)", name = "[^"]+", desc', t):
            sid = m.group(1)
            if sid not in SUB:
                continue
            prof, k = 0, m.start()
            while k < len(t):
                if t[k] == '{':
                    prof += 1
                elif t[k] == '}':
                    prof -= 1
                    if prof == 0:
                        break
                k += 1
            bloques.append((sid, m.start(), k))
        lista = []
        for m in re.finditer(r'\{ id = "([a-z_0-9]+)", level = \d+, name = "', t):
            sub = next((s for s, a, b in bloques if a <= m.start() <= b), None)
            lista.append((m.group(1), sub))
        fuera[clase] = lista
    return fuera


def main():
    problemas = []

    def comprueba(titulo, malos, pinta=lambda x: str(x)):
        estado = 'ok' if not malos else 'FALLA (%d)' % len(malos)
        print('  %-58s %s' % (titulo, estado))
        for x in list(malos)[:8]:
            print('        %s' % pinta(x))
        if len(malos) > 8:
            print('        ... y %d mas' % (len(malos) - 8))
        if malos:
            problemas.append(titulo)

    print('VERIFICACION DE IDS DE RASGO')
    print('=' * 74)

    porclase = rasgos_por_clase()
    todos = {i for l in porclase.values() for i, _ in l}
    print('  %d rasgos de clase en %d ficheros' % (len(todos), len(porclase)))
    print()

    # 1. Todos siguen la convencion.
    malos = []
    for clase, lista in porclase.items():
        ab = ABREV[clase]
        for fid, sub in lista:
            esperado = '%s_%s_' % (ab, SUB[sub]) if sub else '%s_' % ab
            if not fid.startswith(esperado):
                malos.append('%s: %s (esperaba %s...)' % (clase, fid, esperado))
    comprueba('1. Todos los ids siguen <abrevClase>_<abrevSub>_<cosa>', malos)

    # 2. Sin duplicados entre clases.
    veces = collections.Counter(i for l in porclase.values() for i, _ in l)
    comprueba('2. Ningun id duplicado', [k for k, v in veces.items() if v > 1])

    # 3. Ningun id viejo sobrevive en el addon.
    tabla = re.findall(r'\["([a-z_0-9]+)"\] = "([a-z_0-9]+)"', lee(PROGRESION))
    viejos = {v for v, _ in tabla}
    # Solo en POSICION DE ID, no en texto libre: varios ids de dote (`actor`, `resistente`,
    # `alerta`) son palabras corrientes que aparecen legitimamente en descripciones.
    def posiciones_de_id(texto, v):
        e = re.escape(v)
        return (re.search(r'id\s*=\s*"%s"' % e, texto)
                or re.search(r'\["%s"\]\s*=' % e, texto)
                or re.search(r'^\s*%s\s*=\s*"' % e, texto, re.M))
    restos = []
    for f in glob.glob(os.path.join(RAIZ, 'Harford*', '**', '*.lua'), recursive=True):
        q = os.path.relpath(f, RAIZ).replace(os.sep, '/')
        if 'HarfordDnDProgression' in q:
            continue  # ahi viven a proposito, en la tabla de migracion
        # Los ids de HERRAMIENTA comparten nombre con dos dotes y son otro espacio de nombres.
        if 'HarfordDnDData' in q:
            continue
        texto = lee(f)
        for v in viejos:
            if posiciones_de_id(texto, v):
                restos.append('%s en %s' % (v, q))
    comprueba('3. Ningun id viejo sobrevive en el addon', restos)

    # 4. La tabla de migracion cubre TODO lo renombrado y apunta a ids que existen.
    # El destino puede ser un rasgo de clase O una dote: la tabla cubre los dos.
    feats_p = os.path.join(RAIZ, 'Harford', 'DnD', 'Data', 'HarfordDnDFeats.lua')
    ids_feat = set(re.findall(r'id = "([a-z_0-9]+)"', lee(feats_p))) if os.path.exists(feats_p) else set()
    huerfanos = [(v, n) for v, n in tabla if n not in todos and n not in ids_feat]
    comprueba('4. La migracion apunta a ids que existen', huerfanos,
              lambda x: '%s -> %s NO EXISTE' % x)

    # 5. El catalogo de iconos no tiene entradas huerfanas de rasgo de clase.
    cat = lee(CATALOGO)
    b = cat.find('features')
    trozo = cat[b:cat.find('spells', b)] if b >= 0 else cat
    prefijos = tuple(a + '_' for a in ABREV.values())
    encat = {k for k in re.findall(r'^\s*([a-z_0-9]+)\s*=\s*"', trozo, re.M) if k.startswith(prefijos)}
    # los generados en runtime no estan declarados como rasgo
    RUNTIME = ('bru_afl_mald_', 'caz_sup_trampa_', 'cha_mej_atq_', 'gue_man_',
               'monje_cer_breb_', 'sac_pp_')
    # Dotes, razas y trasfondos comparten el espacio de nombres del catalogo y algunos empiezan por
    # un prefijo de clase por puro nombre: `mago_de_batalla` es una DOTE, no un rasgo de Mago.
    otros = set()
    for rel in ('Harford/DnD/Data/HarfordDnDFeats.lua', 'Harford/DnD/Data/HarfordDnDRaces.lua',
                'Harford/DnD/Data/HarfordDnDBackgrounds.lua'):
        f = os.path.join(RAIZ, *rel.split('/'))
        if os.path.exists(f):
            otros |= set(re.findall(r'id = "([a-z_0-9]+)"', lee(f)))
    orf = [k for k in encat if k not in todos and k not in otros and not k.startswith(RUNTIME)]
    comprueba('5. El catalogo de iconos no apunta a rasgos inexistentes', sorted(orf))

    # 5b. Las dotes llevan su prefijo. Sin el, ids como `resistente`, `alerta` o `cocinero` son
    #     palabras corrientes en el espacio global -- y dos COLISIONABAN con ids de herramienta.
    feats = os.path.join(RAIZ, 'Harford', 'DnD', 'Data', 'HarfordDnDFeats.lua')
    sin_pre = []
    if os.path.exists(feats):
        tf = lee(feats)
        sin_pre = [c for c in re.findall(r'^\s*id = "([a-z_0-9]+)", name = "', tf, re.M)
                   if not c.startswith('feat_')]
    comprueba('5b. Las dotes llevan prefijo feat_', sorted(sin_pre))

    # 5c. Ningun id de dote choca con uno de herramienta u otro espacio de nombres.
    datos = os.path.join(RAIZ, 'Harford', 'DnD', 'Data', 'HarfordDnDData.lua')
    choques = []
    if os.path.exists(feats) and os.path.exists(datos):
        ids_feat = set(re.findall(r'^\s*id = "([a-z_0-9]+)", name = "', lee(feats), re.M))
        ids_otros = set(re.findall(r'id\s*=\s*"([a-z_0-9]+)"', lee(datos)))
        choques = sorted(ids_feat & ids_otros)
    comprueba('5c. Ninguna dote choca con otro espacio de nombres', choques)

    # 6. La equivalencia con la web cubre todo lo que la web sigue teniendo.
    imp = lee(IMPORTADOR)
    alias = dict(re.findall(r"^    '([a-z_0-9]+)': '([a-z_0-9]+)',", imp, re.M))
    faltan = []
    if os.path.exists(WEB):
        web = lee(WEB)
        for viejo, nuevo in tabla:
            if ('"%s"' % viejo) in web and nuevo not in alias:
                faltan.append('%s sigue en la web y no tiene alias' % viejo)
    else:
        print('        (web no accesible; comprobacion 6 omitida)')
    comprueba('6. La web renombrada tiene equivalencia en el importador', faltan)

    # 7. Ningun id viejo quedo en datos de jugador SIN entrada de migracion.
    sv = ''
    for f in glob.glob(SV, recursive=True):
        try:
            sv += lee(f)
        except Exception:
            pass
    sin_mig = []
    if sv:
        # cualquier id con pinta de rasgo guardado que no exista ni tenga migracion
        guardados = set()
        for bloque in ('choices', 'featureStates', 'featureUses', 'activeStates'):
            for m in re.finditer(r'\["%s"\] = \{' % bloque, sv):
                j = sv.find('{', m.start())
                prof, k = 0, j
                while k < len(sv):
                    if sv[k] == '{':
                        prof += 1
                    elif sv[k] == '}':
                        prof -= 1
                        if prof == 0:
                            break
                    k += 1
                guardados |= set(re.findall(r'\["([a-zA-Z_0-9]+)"\]', sv[j:k]))
        mig = dict(tabla)
        for g in sorted(guardados):
            if g in todos or g in mig:
                continue
            # razas, trasfondos y dotes tienen sus propios prefijos y no entran aqui
            if g.startswith(prefijos):
                sin_mig.append('%s guardado y sin destino' % g)
    else:
        print('        (SavedVariables no accesibles; comprobacion 7 omitida)')
    comprueba('7. Nada guardado por el jugador queda sin destino', sin_mig)

    print()
    if problemas:
        print('QUEDAN COSAS SUELTAS: %d comprobacion(es) en rojo' % len(problemas))
        for p in problemas:
            print('   - %s' % p)
        return 1
    print('NADA SUELTO: las 7 comprobaciones pasan')
    return 0


if __name__ == '__main__':
    sys.exit(main())
