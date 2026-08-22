# -*- coding: utf-8 -*-
"""Comprueba que razas y clases se escriban igual en toda la web que en el compendio.

El compendio se genera del addon y usa un nombre canonico para cada raza y cada clase.
Las paginas escritas a mano (historia, reglas, reclutamiento...) y las fichas de personaje
pueden usar otra forma ("trols" frente a "Troll", "paladin" sin tilde). Es la clase de
descuadre que nadie ve hasta que busca un termino y no lo encuentra.
"""
import io, os, re, sys, json, glob, html, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb"


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


t = io.open(os.path.join(WEB, "js", "compendium-data.js"), encoding="utf-8").read()
KB = json.loads(t[t.find("{"):t.rfind("}")+1])

# nombre canonico -> formas que deben considerarse la misma palabra
CANON = {}
for r in KB["races"]: CANON[r["name"]] = set()
for c in KB["classes"]: CANON[c["name"]] = set()

# variantes plausibles de cada nombre: singular/plural y sin tildes
def variantes(nombre):
    base = sa(nombre)
    yield base
    yield base + "s"
    yield base + "es"
    if base.endswith("l"): yield base + "es"
    if base.endswith("ll"): yield base[:-1]          # troll -> trol
    if base.endswith("l"): yield base + "l"          # trol -> troll


VAR = {}
for nombre in CANON:
    for v in variantes(nombre): VAR.setdefault(v, nombre)

textos = []
for p in sorted(glob.glob(os.path.join(WEB, "*.html"))):
    s = io.open(p, encoding="utf-8").read()
    s = re.sub(r"<(script|style)\b.*?</\1>", "\n", s, flags=re.S | re.I)
    textos.append((os.path.basename(p), html.unescape(re.sub(r"<[^>]+>", "\n", s))))
for f in ("characters.js", "organizations.js", "intelligence.js", "places.js"):
    p = os.path.join(WEB, "js", f)
    if not os.path.exists(p): continue
    src = io.open(p, encoding="utf-8").read()
    textos.append((f, "\n".join(c for c in re.findall(r'"((?:[^"\\]|\\.)*)"', src) if " " in c)))

PALABRA = re.compile(r"\b[A-Za-zÁÉÍÓÚÑáéíóúñ]{4,}\b")
usos = collections.defaultdict(collections.Counter)
for nombre, txt in textos:
    for m in PALABRA.finditer(txt):
        w = m.group(0)
        canon = VAR.get(sa(w))
        if canon: usos[canon][w] += 1

print("razas y clases mencionadas en la web: %d\n" % len(usos))
print("%-24s %s" % ("canonico del compendio", "formas usadas en la web"))
print("-" * 78)
descuadre = 0
for canon in sorted(usos):
    formas = usos[canon]
    # "un cazador" en minuscula es prosa normal, y el plural tambien: lo que interesa es
    # la diferencia de ACENTO o de grafia ("Chaman" por "Chamán", "troll" por "trol")
    # se compara en minuscula y sin plural, pero CON tildes: asi "un cazador" o "los trols"
    # no son avisos y si lo son "Picaro" por "Pícaro" o "troll" por "trol"
    base = canon.lower().rstrip("s")
    # el plural pierde la tilde por regla de acentuacion ("chaman" -> "chamanes"), asi que
    # en las formas en plural se compara sin tildes
    def encaja(w):
        if w.lower().rstrip("s") == base: return True
        return w.lower().endswith("s") and sa(w).rstrip("es") == sa(base)
    otras = {w: n for w, n in formas.items() if not encaja(w)}
    marca = ""
    if otras:
        descuadre += 1
        marca = "  <-- revisar: " + ", ".join(sorted(otras))
    print("%-24s %s%s" % (canon, ", ".join("%s x%d" % (w, n) for w, n in formas.most_common(5)), marca))
print("\nnombres con alguna forma distinta a la canonica: %d" % descuadre)
