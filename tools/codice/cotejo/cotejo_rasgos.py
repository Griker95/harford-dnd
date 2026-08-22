# -*- coding: utf-8 -*-
# Cotejo de RASGOS y DOTES: para cada rasgo/dote del addon sin texto del manual, busca el
# titulo mas parecido en los libros y lo presenta para validacion humana.
import io, os, re, sys, json, glob, difflib, unicodedata
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
SP1 = r"C:/Users/marco/Documents/New project/tools/codice"
LIBROS = [(r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md", "Warcraft 5ª"),
          (r"C:/Users/marco/Documents/New project/RuleSource/Export/d_d_5_0_edge_manual_del_jugador/texto.md", "Manual del Jugador")]

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
def nk(s): return re.sub(r"[^0-9a-z ]+", " ", sa(s).lower()).strip()

# candidatos: titulos h3-h5 y entradas en negrita de ambos libros, con su cuerpo
BOLD = re.compile(r"\*\*\*\s*([^*\n]+?)\.?\s*\*\*\*\s*(.*?)(?=\n\s*\*\*\*|\n#{1,6}\s|\Z)", re.S)
cands = {}
for path, fuente in LIBROS:
    src = io.open(path, encoding="utf-8").read().replace("\r", "")
    heads = [(len(m.group(1)), m.group(2).strip().strip("*").strip(), m.start(), m.end())
             for m in re.finditer(r"\n(#{1,6})\s*([^\n]+)", src)]
    for i, (lvl, titulo, a, b) in enumerate(heads):
        if lvl < 3 or not (3 <= len(titulo) <= 46): continue
        fin = next((a2 for l2, t2, a2, b2 in heads[i+1:] if l2 <= lvl), len(src))
        cuerpo = re.sub(r"\n#{1,6}\s*", "\n", src[b:fin]).strip()
        if len(cuerpo) >= 80: cands.setdefault(nk(titulo), (titulo, fuente, cuerpo))
    for m in BOLD.finditer(src):
        titulo, cuerpo = m.group(1).strip(), m.group(2).strip()
        if 3 <= len(titulo) <= 46 and len(cuerpo) >= 80:
            cands.setdefault(nk(titulo), (titulo, fuente, cuerpo))
print("candidatos en los libros:", len(cands))

# items del addon sin texto amplio
kb = json.load(io.open(os.path.join(SP1, "kb_icons.json"), encoding="utf-8"))
items = []
for c in kb["classes"]:
    for f in c["features"]: items.append(("Rasgo de clase", c["name"], f["name"], f.get("desc", "")))
    for s in c["subclasses"]:
        for f in s["features"]: items.append(("Rasgo de subclase", c["name"] + " · " + s["name"], f["name"], f.get("desc", "")))
for r in kb["races"]:
    for f in r["traits"]: items.append(("Rasgo racial", r["name"], f["name"], f.get("desc", "")))
    for s in r.get("subraces", []):
        for f in s["traits"]: items.append(("Rasgo de subraza", r["name"] + " · " + s["name"], f["name"], f.get("desc", "")))
for d in kb.get("dotes", []):
    items.append(("Dote", d.get("requires") or "—", d["name"], d.get("desc", "")))

keys = list(cands)
rows = []
for kind, owner, name, desc in items:
    if len(desc or "") >= 250: continue                    # ya tiene texto amplio
    k = nk(name)
    if not k: continue
    best = max(keys, key=lambda x: difflib.SequenceMatcher(None, k, x).ratio())
    ratio = difflib.SequenceMatcher(None, k, best).ratio()
    if ratio >= 0.60 and best != k:
        t, fuente, cuerpo = cands[best]
        rows.append({"kind": kind, "owner": owner, "n": name, "cur": (desc or "")[:400],
                     "b": t, "f": fuente, "r": round(ratio, 2), "t": cuerpo[:2200]})
rows.sort(key=lambda x: -x["r"])
json.dump(rows, io.open(os.path.join(HERE, "rasgos_audit.json"), "w", encoding="utf-8"), ensure_ascii=False)
import collections
print("emparejamientos propuestos:", len(rows), dict(collections.Counter(x["kind"] for x in rows)))
for x in rows[:20]: print("  %.2f %-16s %-30s ~ %-30s [%s]" % (x["r"], x["kind"][:15], x["n"][:29], x["b"][:29], x["f"][:12]))
