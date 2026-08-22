# -*- coding: utf-8 -*-
"""Repone las tildes que faltan en el texto propio del addon.

El texto que viene de los manuales va acentuado; el que escribio el addon, muchas veces
no ("accion", "dano", "salvacion", "caracteristica"). En el compendio conviven las dos
formas, asi que la palabra correcta se deduce del propio corpus: si la version con tilde
es abrumadoramente mas frecuente, la que no la lleva es la errata.

La trampa son los HOMOGRAFOS: "como" y "cómo", "este" y "esté", "esta" y "está" son
palabras distintas, las dos correctas. Van en una lista blanca y no se tocan nunca.

Sin --apply solo informa.
"""
import io, os, re, sys, json, glob, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
WEB = r"C:/Users/marco/Documents/harfordweb/js"
RAIZ = r"C:/Users/marco/Documents/New project/Harford"
PALABRA = re.compile(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{3,}")

# Pares donde las dos formas existen y significan cosas distintas. Nunca se sustituyen.
HOMOGRAFOS = set("""como cuando donde cual cuales quien quienes que cuanto cuanta cuantos cuantas
este esta estos estas esto ese esa eso aquel aquella el tu mi si mas se de te lo aun solo
sabia sabias habia perdida perdidas cambio continuo publico practica critica limite
termino calculo numero ultimo intimo animo domino secretaria estimulo
valido invalido genero integro transito deposito diagnostico intercambio marco
capitulo articulo
limite limites especifica especifico especificas especificos campana cartel mascara
porque kobolds tratara llevara replica cortes unas mana duro alzo ansia brillo activo""".split())


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def con_tilde(w):
    return any(c in "áéíóúüñÁÉÍÓÚÜÑ" for c in w)


def corpus():
    out = []
    t = io.open(os.path.join(WEB, "compendium-data.js"), encoding="utf-8").read()
    KB = json.loads(t[t.find("{"):t.rfind("}")+1])
    for s in KB["spells"]: out.append(s.get("description") or "")
    for c in KB["classes"]:
        out += [c.get("desc") or "", c.get("extras") or ""]
        out += [f.get("desc") or "" for f in c["features"]]
        out += [f.get("desc") or "" for s in c["subclasses"] for f in s["features"]]
    for r in KB["races"]:
        out += [r.get("desc") or "", r.get("extras") or ""]
        out += [x.get("desc") or "" for x in r["traits"]]
        out += [x.get("desc") or "" for s in r.get("subraces", []) for x in s["traits"]]
    for b in KB["backgrounds"]:
        out.append(b.get("desc") or "")
        out += [x.get("desc") or "" for x in b["traits"]]
    for f, k in (("compendium-equipment.js", "note"), ("compendium-dotes.js", "desc")):
        p = os.path.join(WEB, f)
        if not os.path.exists(p): continue
        d = io.open(p, encoding="utf-8").read()
        for x in json.loads(d[d.find("["):d.rfind("]")+1]):
            if isinstance(x, dict) and isinstance(x.get(k), str): out.append(x[k])
    return out


formas = collections.defaultdict(collections.Counter)
for t in corpus():
    for w in PALABRA.findall(t): formas[sa(w)][w.lower()] += 1

REGLAS = {}
for clave, c in formas.items():
    if clave in HOMOGRAFOS: continue
    tildadas = {w: n for w, n in c.items() if con_tilde(w)}
    planas = {w: n for w, n in c.items() if not con_tilde(w)}
    # NO se usa el vocabulario de los manuales como referencia para las palabras que aqui
    # no tienen forma acentuada: probado, y sale basura. Los manuales arrastran su propio
    # OCR ("bién", "idéas", "maño") y ademas estan llenos de homografos legitimos, asi que
    # proponia "bajo -> bajó", "hacia -> hacía" o "mano -> maño". Las pocas palabras sin
    # referencia aqui se corrigen a mano en RuleSource/arreglar_erratas.py.
    if not tildadas or not planas: continue
    mejor, nt = max(tildadas.items(), key=lambda x: x[1])
    npl = sum(planas.values())
    # la forma con tilde tiene que dominar de largo; si van parejas, es un homografo que
    # se me ha escapado y prefiero no tocarlo
    if nt < 2: continue
    for w in planas: REGLAS[w] = mejor

print("palabras a acentuar: %d formas" % len(REGLAS))
for w, bien in sorted(REGLAS.items(), key=lambda x: -sum(formas[sa(x[0])].values())):
    print("   %-22s -> %-22s (con tilde x%d)" % (w, bien, formas[sa(w)][bien]))

if "--apply" in sys.argv:
    FICHEROS = []
    for nombre in ("HarfordCompendioData", "HarfordDnDBook", "HarfordDnDBackgrounds",
                   "HarfordDnDFeats", "HarfordDnDRaces", "HarfordDnDBookText", "HarfordDnDData"):
        FICHEROS += glob.glob(RAIZ + "/**/%s.lua" % nombre, recursive=True)
    # Solo la PROSA. Ni `name` ni `label`: el addon empareja por ese texto (listas de
    # conjuros, busquedas, ArcSpells), asi que acentuarlo no es corregir una errata sino
    # cambiar una clave. Se probo y hubo que deshacerlo en 85 sitios.
    CAMPO = re.compile(r'\b(description|desc|mechanics|roleNotes) = "((?:[^"\\]|\\.)*)"')
    pares = [(re.compile(r"\b" + re.escape(w) + r"\b", re.I), bien) for w, bien in REGLAS.items()]

    def _acentuar(m):
        cuerpo = m.group(2)
        for pat, bien in pares:
            cuerpo = pat.sub(lambda x: bien.capitalize() if x.group(0)[:1].isupper() else bien, cuerpo)
        return m.group(1) + ' = "' + cuerpo + '"'

    total = 0
    for f in FICHEROS:
        d = io.open(f, encoding="utf-8", newline="").read()
        nuevo = CAMPO.sub(_acentuar, d)
        if nuevo != d:
            io.open(f, "w", encoding="utf-8", newline="").write(nuevo)
            total += 1
    print("\nficheros del addon corregidos: %d" % total)
