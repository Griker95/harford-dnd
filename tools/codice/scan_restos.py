# -*- coding: utf-8 -*-
# Escanea las descripciones del compendio buscando restos de cabecera de pagina del OCR.
import io, re, glob, sys
sys.stdout.reconfigure(encoding="utf-8")
d = io.open(glob.glob(r"C:/Users/marco/Documents/New project/**/HarfordCompendio.lua", recursive=True)[0], encoding="utf-8").read()
pares = re.findall(r'\bname = "((?:[^"\\]|\\.)*)".*?description = "((?:[^"\\]|\\.)*)"', d, re.S)

def lua_unescape(text):
    """Convierte escapes del literal Lua para inspeccionar el texto por párrafos."""
    return text.replace(r"\n", "\n").replace(r'\"', '"').replace(r"\\", "\\")

descs = [lua_unescape(x) for x in re.findall(r'description = "((?:[^"\\]|\\.)*)"', d)]

# restos reales: fragmentos de cabecera "CAPITULO 11: CONJUROS 213" con OCR roto
PAT = re.compile(
    r"\s*[\(\[]?[CcltfEr(']{1,3}[A4]P[IÍT1'~L.,:JU\u00b0O ]{1,12}[OU0]\s*(?:\d{1,2})?\s*[:.,]?\s*"
    r"C?[O0Q]?[~N]{0,2}[-~]?[JIl]?U?R?[O0]?S?\s*[\d'`\u00b4]{0,4}\s*"
)
CANDS = []
for x in descs:
    hits = []
    # 1) virgulilla (no existe en castellano normal)
    for m in re.finditer(r".{30}~.{15}", x): hits.append(m.group(0))
    # 2) CAPIT-variantes en cualquier punto
    for m in re.finditer(r".{0,25}[CcltfEr(']{1,3}[A4]P[IÍT1'~L.,:JU\u00b0 ]{2,12}[OU0].{0,40}", x): hits.append(m.group(0))
    # 3) numero de pagina pegado al final tras mayusculas
    m = re.search(r".{0,40}[A-ZÁÉÍÓÚÑ~'`]{4,}.{0,10}\d{2,3}['`\u00b4]?\s*$", x)
    if m: hits.append("FINAL: " + m.group(0))
    if hits: CANDS.append((x[:40], hits))
for n, hs in CANDS:
    print("==", n)
    for h in hs: print("   ", repr(h))
print("total sospechosas:", len(CANDS), "de", len(descs))
