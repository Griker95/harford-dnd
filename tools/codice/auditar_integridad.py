# -*- coding: utf-8 -*-
"""Integridad estructural del compendio publicado: ids duplicados, iconos que no
existen como fichero, categorias sospechosas y campos obligatorios vacios."""
import io, os, re, sys, json, collections

sys.stdout.reconfigure(encoding="utf-8")
W = r"C:/Users/marco/Documents/harfordweb"
SEP = re.compile(r"[\\/]")

def car(f, obj=False):
    t = io.open(os.path.join(W, "js", f), encoding="utf-8").read()
    a, b = (t.find("{"), t.rfind("}")) if obj else (t.find("["), t.rfind("]"))
    return json.loads(t[a:b+1])

kb = car("compendium-data.js", True)
eq = car("compendium-equipment.js")
do = car("compendium-dotes.js")
pr = car("compendium-professions.js")

print("=== IDS DUPLICADOS ===")
hay = False
for nom, lst in (("conjuros", kb["spells"]), ("equipo", eq), ("dotes", do), ("profesiones", pr),
                 ("clases", kb["classes"]), ("razas", kb["races"]), ("trasfondos", kb["backgrounds"])):
    c = collections.Counter(x["id"] for x in lst)
    d = [k for k, v in c.items() if v > 1]
    if d: print("   %-12s %s" % (nom, d)); hay = True
if not hay: print("   ninguno")

print("\n=== ICONOS QUE NO EXISTEN COMO FICHERO ===")
base = os.path.join(W, "assets", "compendium-icons")
faltan = set()
def rec(o):
    if isinstance(o, dict):
        ic = o.get("icon")
        if isinstance(ic, str) and ic:
            f = SEP.split(ic)[-1].lower() + ".png"
            if not os.path.exists(os.path.join(base, f)): faltan.add(ic)
        for v in o.values(): rec(v)
    elif isinstance(o, list):
        for v in o: rec(v)
for x in (kb, eq, do, pr): rec(x)
print("   ", sorted(faltan) or "ninguno")

print("\n=== ICONOS HUERFANOS (fichero que nadie usa) ===")
usados = set()
def rec2(o):
    if isinstance(o, dict):
        ic = o.get("icon")
        if isinstance(ic, str) and ic: usados.add(SEP.split(ic)[-1].lower() + ".png")
        for v in o.values(): rec2(v)
    elif isinstance(o, list):
        for v in o: rec2(v)
for x in (kb, eq, do, pr): rec2(x)
en_disco = {f.lower() for f in os.listdir(base) if f.lower().endswith(".png")}
huer = sorted(en_disco - usados - {"_fallback.png"})
print("   %d ficheros sin usar%s" % (len(huer), (": " + ", ".join(huer[:6])) if huer else ""))

print("\n=== CAMPOS VACIOS EN CONJUROS ===")
faltantes = collections.Counter()
for s in kb["spells"]:
    for k in ("castingTime", "range", "components", "duration", "school"):
        if not (s.get(k) or "").strip(): faltantes[k] += 1
print("   ", dict(faltantes) or "ninguno")

print("\n=== CATEGORIAS DE EQUIPO CON MUY POCAS ENTRADAS ===")
cc = collections.Counter(x.get("category") for x in eq)
print("   ", {k: v for k, v in cc.items() if v <= 2} or "ninguna")

print("\n=== VALORES DE FACETA QUE APARECEN UNA SOLA VEZ (posible errata) ===")
for campo in ("range", "damageType"):
    c = collections.Counter(x.get(campo) for x in eq if x.get(campo))
    unicos = [k for k, v in c.items() if v == 1]
    if unicos: print("   equipo.%-11s %s" % (campo, unicos[:8]))
c = collections.Counter(s.get("school") for s in kb["spells"])
print("   conjuros.school", {k: v for k, v in c.items() if v <= 2} or "todas con >2")
