# -*- coding: utf-8 -*-
"""Barrido de ERRATAS por categoria, sin diccionario.

No hay diccionario de castellano a mano, asi que se usan dos referencias que si tenemos:

  el propio corpus   una palabra que aparece UNA vez y se parece mucho a otra que aparece
                     muchas es casi siempre la misma palabra mal escrita ("conjruo" junto
                     a 380 "conjuro"). Es el metodo que mas erratas reales encuentra.
  los manuales       el vocabulario de los PDF y del libro de Warcraft. Una palabra que
                     no aparece en ningun manual y tampoco es frecuente aqui suele venir
                     de un fallo de proceso, no del autor.

Se recorre categoria a categoria para poder revisarlas por tandas.
Uso: python auditar_erratas.py [categoria ...]
"""
import io, os, re, sys, json, glob, difflib, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
WEB = r"C:/Users/marco/Documents/harfordweb/js"
RULES = r"C:/Users/marco/Documents/New project/RuleSource"

PALABRA = re.compile(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{4,}")


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def carga(f, obj=False):
    """Primera estructura del fichero, balanceando llaves.

    No vale coger del primer corchete al ultimo: compendium-professions.js declara dos
    cosas (las profesiones y sus objetos) y eso juntaba las dos en un texto que no es JSON.
    """
    t = io.open(os.path.join(WEB, f), encoding="utf-8").read()
    abre, cierra = ("{", "}") if obj else ("[", "]")
    a = t.find(abre)
    prof, i = 0, a
    while i < len(t):
        if t[i] == abre:
            prof += 1
        elif t[i] == cierra:
            prof -= 1
            if prof == 0:
                break
        i += 1
    return json.loads(t[a:i + 1])


KB = carga("compendium-data.js", obj=True)
EQ = carga("compendium-equipment.js")
DO = carga("compendium-dotes.js")
PR = carga("compendium-professions.js")


def categorias():
    c = collections.OrderedDict()
    c["conjuros"] = [(s["name"], s.get("description") or "") for s in KB["spells"]]
    c["clases"] = [(x["name"], (x.get("desc") or "") + "\n" + (x.get("extras") or ""))
                   for x in KB["classes"]]
    c["rasgos"] = [(x["name"] + "/" + f["name"], f.get("desc") or "")
                   for x in KB["classes"]
                   for f in x["features"] + [g for s in x["subclasses"] for g in s["features"]]]
    c["razas"] = [(x["name"], (x.get("desc") or "") + "\n" + (x.get("extras") or ""))
                  for x in KB["races"]]
    c["raciales"] = [(r["name"] + "/" + x["name"], x.get("desc") or "")
                     for r in KB["races"]
                     for x in r["traits"] + [y for s in r.get("subraces", []) for y in s["traits"]]]
    c["trasfondos"] = [(b["name"], b.get("desc") or "") for b in KB["backgrounds"]] + \
                      [(b["name"] + "/" + x["name"], x.get("desc") or "")
                       for b in KB["backgrounds"] for x in b["traits"]]
    c["dotes"] = [(d["name"], d.get("desc") or "") for d in DO] + \
                 [(d["name"] + "/" + x["name"], x.get("desc") or "")
                  for d in DO for x in d.get("traits", [])]
    c["equipo"] = [(e["name"], e.get("note") or "") for e in EQ]
    c["profesiones"] = [(p["name"], p.get("tool") or "") for p in PR] + \
                       [(p["name"] + "/" + r["name"], r["name"]) for p in PR for r in p.get("recipes", [])]
    return c


CAT = categorias()


def vocabulario_manuales():
    """Todas las palabras de los manuales en crudo: la referencia de que existe."""
    voc = collections.Counter()
    fuentes = glob.glob(os.path.join(RULES, "Rulebooks_MD", "*.md"))
    fuentes += glob.glob(os.path.join(RULES, "Export", "*", "texto.md"))
    for f in fuentes:
        try: txt = io.open(f, encoding="utf-8", errors="replace").read()
        except OSError: continue
        for w in PALABRA.findall(txt): voc[sa(w)] += 1
    return voc


VOC_MANUAL = vocabulario_manuales()

# vocabulario del compendio entero: lo frecuente es la forma correcta
VOC = collections.Counter()
for entradas in CAT.values():
    for _n, t in entradas:
        for w in PALABRA.findall(t): VOC[sa(w)] += 1
FRECUENTES = {w for w, n in VOC.items() if n >= 12}

# nombres propios y terminos del mundo: no son erratas aunque salgan una vez
PROPIOS = set()
for grupo in (KB["classes"], KB["races"], KB["backgrounds"], EQ, DO, PR, KB["spells"]):
    for x in grupo:
        for w in PALABRA.findall(x.get("name") or ""): PROPIOS.add(sa(w))


def _pegada(k):
    """¿Son dos palabras del propio compendio escritas sin el espacio?

    "objetivogana", "deadivinacion", "siguientesformas". Es el detector que encuentra las
    erratas de verdad. El de "no aparece en ningun manual" se quito: en los trasfondos
    propios daba 224 avisos y ninguno era una errata, porque ese texto no sale de ningun
    manual y usa palabras normales que alli no estan.
    """
    for i in range(3, len(k) - 2):
        a, b = k[:i], k[i:]
        if VOC.get(a, 0) >= 6 and VOC.get(b, 0) >= 6: return a + " " + b
    return None


def sospechosas(entradas):
    """Palabras raras que se parecen a una frecuente, o que son dos pegadas."""
    out = []
    for nombre, texto in entradas:
        for m in PALABRA.finditer(texto):
            w = m.group(0)
            k = sa(w)
            if VOC[k] >= 3 or k in PROPIOS or len(k) < 5: continue
            if VOC_MANUAL.get(k, 0) >= 2: continue          # el manual la escribe asi
            motivo = None
            cerca = difflib.get_close_matches(k, FRECUENTES, n=1, cutoff=0.88)
            if cerca and abs(len(cerca[0]) - len(k)) <= 2: motivo = "se parece a '%s'" % cerca[0]
            if not motivo and len(k) >= 9:
                p = _pegada(k)
                if p: motivo = "son dos palabras: '%s'" % p
            if not motivo: continue
            ctx = re.sub(r"\s+", " ", texto[max(0, m.start()-38):m.end()+28])
            out.append((nombre, w, motivo, ctx))
    return out


pedidas = [x for x in sys.argv[1:] if x in CAT] or list(CAT)
print("vocabulario de los manuales: %d palabras | del compendio: %d" % (len(VOC_MANUAL), len(VOC)))
total = 0
for cat in pedidas:
    hallazgos = sospechosas(CAT[cat])
    total += len(hallazgos)
    print("\n%s (%d entradas) -> %d sospechas" % (cat.upper(), len(CAT[cat]), len(hallazgos)))
    for nombre, w, motivo, ctx in hallazgos[:24]:
        print("   %-28s %-18s %-26s %s" % (nombre[:27], w[:17], motivo[:25], ctx[:56]))
print("\ntotal de sospechas: %d" % total)
