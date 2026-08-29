# -*- coding: utf-8 -*-
# Adapta cotejo2.json al formato del informe. Un 'sin'/'exacto' cuya descripcion en el
# addon ya es larga (Libro 2 traducido, volcados previos) cuenta como resuelto.
import io, json, re, sys, glob, collections
sys.stdout.reconfigure(encoding="utf-8")
rows = json.load(io.open("cotejo2.json", encoding="utf-8"))
COMP = glob.glob(r"C:/Users/marco/Documents/New project/**/HarfordCompendio.lua", recursive=True)[0]
d = io.open(COMP, encoding="utf-8").read()
st = list(re.finditer(r'\n {8}id = "[a-z0-9_]+",', d))
dlen = {}
for i, m in enumerate(st):
    blk = d[m.start():st[i+1].start() if i+1 < len(st) else len(d)]
    nm = re.search(r'name = "([^"]+)"', blk)
    de = re.search(r'description = "((?:[^"\\]|\\.)*)"', blk)
    if nm: dlen[nm.group(1)] = len(de.group(1)) if de else 0
for r in rows:
    if r["k"] in ("sin", "exacto") and dlen.get(r["n"], 0) > 400:
        r["k"] = "hecho"; r["ya"] = 1
KIND = {"hecho": "exacto", "exacto": "ocr", "traduccion": "traduccion", "sin": "sin"}
out = [{"name": r["n"], "level": r["l"], "school": r["s"],
        "group": "Warcraft Custom" if r["w"] else "DnD",
        "kind": KIND.get(r["k"], r["k"]), "book": r["b"], "src": r["f"],
        "bookLvl": r["l"], "bookSch": r["s"], "text": r["t"], "meta": r["m"]} for r in rows]
json.dump(out, io.open("spell_audit_final.json", "w", encoding="utf-8"), ensure_ascii=False)
print(dict(collections.Counter(x["kind"] for x in out)))
