# -*- coding: utf-8 -*-
# Cotejo v2: cruza el compendio del addon con los conjuros extraidos de los PDF
# (Export/conjuros_*.json), que ya salen limpios y con nivel y escuela fiables.
import io, os, re, sys, json, glob, difflib, unicodedata
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
from metrico import a_metrico
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
RS = r"C:/Users/marco/Documents/New project/RuleSource"
COMP = glob.glob(r"C:/Users/marco/Documents/New project/Harford/**/HarfordCompendioData.lua", recursive=True)[0]

LIBRO = {"conjuros_d_d_5_0_edge_manual_del_jugador": "Manual del Jugador",
         "conjuros_warcraft_5_edici_n_compressed": "Warcraft 5ª",
         "conjuros_xanathar": "Guía de Xanathar",
         "conjuros_guia_de_xanathar_para_todo_carta_1_202_o": "Guía de Xanathar",
         "conjuros_tasha": "Caldero de Tasha",
         "conjuros_el_caldero_para_todo_de_thasa_tcoe": "Caldero de Tasha",
         "conjuros_phb": "Manual del Jugador"}
WARCRAFT = {"Warcraft 5ª"}

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
def nk(s):
    s = sa(s).lower(); s = re.sub(r"[^a-z0-9 ]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()

# --- conjuros de los manuales ---
libro = {}
for f in glob.glob(os.path.join(RS, "Export", "conjuros_*.json")):
    base = os.path.splitext(os.path.basename(f))[0]
    nombre_libro = LIBRO.get(base, base)
    for c in json.load(io.open(f, encoding="utf-8")):
        k = nk(c["nombre"])
        if not k or k in libro: continue
        libro[k] = {**c, "libro": nombre_libro}

# --- conjuros del addon ---
d = io.open(COMP, encoding="utf-8").read()
starts = list(re.finditer(r"\n {8}id = \"([a-z0-9_]+)\",", d))
filas = []
for i, m in enumerate(starts):
    e = starts[i+1].start() if i+1 < len(starts) else len(d)
    blk = d[m.start():e]
    g = lambda k: (re.search(r'\b' + k + r' = "((?:[^"\\]|\\.)*)"', blk).group(1)
                   if re.search(r'\b' + k + r' = "((?:[^"\\]|\\.)*)"', blk) else "")
    lv = re.search(r"\blevel = (\d+)", blk)
    filas.append({"id": m.group(1), "n": g("name"), "l": int(lv.group(1)) if lv else 0,
                  "s": g("school"), "grupo": g("sourceGroup"), "fuente": g("source"),
                  "desc": g("description")})

def squash(s): return re.sub(r"[^a-z0-9]", "", nk(s))
def ya_volcado(f, hit):
    """Ya tiene el texto del manual si su descripcion coincide con la del libro."""
    return bool(hit) and squash(f["desc"])[:120] == squash(a_metrico(hit["texto"]))[:120]

def compatible(c, f):
    """Un conjuro de Warcraft solo se cruza con libros de Warcraft, y al reves."""
    wc = c["libro"] in WARCRAFT
    return wc if f["grupo"] == "Warcraft Custom" else (not wc)

keys = list(libro)
res = []
for f in filas:
    k = nk(f["n"])
    hit = libro.get(k)
    kind = "exacto" if hit and compatible(hit, f) else None
    if not kind:
        hit = None
        # el mismo nombre roto por el OCR del manual ("SHI LLELAGH") es el mismo conjuro
        sq = squash(f["n"])
        cand_sq = [x for x in keys if squash(x) == sq and compatible(libro[x], f)]
        if cand_sq: hit, kind = libro[cand_sq[0]], "exacto"
    if not kind:
        # mismo nivel y escuela, nombre parecido -> posible traduccion distinta
        cand = [x for x in keys
                if libro[x]["nivel"] == f["l"] and nk(libro[x]["escuela"]) == nk(f["s"])
                and compatible(libro[x], f)]
        if cand:
            best = max(cand, key=lambda x: difflib.SequenceMatcher(None, k, x).ratio())
            r = difflib.SequenceMatcher(None, k, best).ratio()
            if r >= 0.45: hit, kind = libro[best], "traduccion"
    if not kind: kind = "sin"
    hecho = ya_volcado(f, hit)
    res.append({"n": f["n"], "l": f["l"], "s": f["s"], "w": 1 if f["grupo"] == "Warcraft Custom" else 0,
                "fuente": f["fuente"], "ya": 1 if hecho else 0,
                "k": "hecho" if hecho else kind,
                "b": hit["nombre"] if hit else "", "f": hit["libro"] if hit else "",
                "t": (hit["texto"][:2400] if hit else ""),
                "m": (" · ".join(x for x in [hit.get("tiempo"), hit.get("alcance"),
                                             hit.get("componentes"), hit.get("duracion")] if x) if hit else "")})

json.dump(res, io.open(os.path.join(HERE, "cotejo2.json"), "w", encoding="utf-8"), ensure_ascii=False)
import collections
print("conjuros del addon:", len(res), "| conjuros en los manuales:", len(libro))
print(dict(collections.Counter(r["k"] for r in res)))
print("ya con texto del manual:", sum(r["ya"] for r in res))
print("\nPENDIENTES de decidir (traduccion):")
for r in [x for x in res if x["k"] == "traduccion"][:22]:
    print("  %-30s -> %-30s [%s]" % (r["n"][:29], r["b"][:29], r["f"][:18]))
