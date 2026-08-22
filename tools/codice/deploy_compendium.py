# -*- coding: utf-8 -*-
# Regenera compendium-data.js desde kb_icons.json y copia a assets/compendium-icons/ todos los
# PNG referenciados por los data files del web (data + equipment + dotes).
import io, os, re, json, shutil, sys
from facetas import normalizar_conjuro
sys.stdout.reconfigure(encoding="utf-8")
KB = r"C:/Users/marco/Documents/New project/tools/codice/kb_icons.json"
WEB = r"C:/Users/marco/Documents/harfordweb"
EIPNG = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"

# 1) compendium-data.js desde kb_icons.json. Las profesiones NO van aqui: su generador
# canonico es extract_professions.py (terminologia de prof_terminologia.json), que las
# escribe en compendium-professions.js; la copia que traiga el kb se descarta.
kb = json.load(io.open(KB, encoding="utf-8"))
# las facetas cortas alimentan los filtros: se unifican tildes/genero antes de escribir
for _sp in kb.get("spells", []): normalizar_conjuro(_sp)
# los nombres visibles llevan tilde aunque el addon los guarde sin ella
from nombres_display import aplicar as _acentuar_nombres
_acentuar_nombres(kb)
kb.pop("professions", None)
io.open(os.path.join(WEB, "js", "compendium-data.js"), "w", encoding="utf-8").write(
    "window.HARFORD_COMPENDIUM = " + json.dumps(kb, ensure_ascii=False, indent=1) + ";\n")

# 2) recopilar iconos de todos los data files del web
names = set()
for fn in ("compendium-data.js", "compendium-equipment.js", "compendium-dotes.js"):
    p = os.path.join(WEB, "js", fn)
    if not os.path.exists(p): continue
    t = io.open(p, encoding="utf-8").read()
    for m in re.finditer(r'"icon":\s*"([^"]+)"', t):
        names.add(m.group(1).replace("\\", "/").split("/")[-1].lower())

# 3) copiar; el archivo real puede llevar prefijo de fuente o apostrofo, se copia al nombre-alias
_PNG = {f[:-4].lower(): f for f in os.listdir(EIPNG) if f.lower().endswith(".png")}
def resolve_file(n):
    n = n.lower()
    for cand in (n, "eps_" + n, "hots_" + n, n + "'", "eps_" + n + "'"):
        if cand in _PNG: return _PNG[cand]
    suf = "_" + n
    for base, f in _PNG.items():
        if base.endswith(suf): return f
    return None
dst = os.path.join(WEB, "assets", "compendium-icons"); os.makedirs(dst, exist_ok=True)
copied = miss = 0; missing = []
for n in sorted(names):
    src_file = resolve_file(n)
    if src_file:
        shutil.copyfile(os.path.join(EIPNG, src_file), os.path.join(dst, n + ".png")); copied += 1
    else:
        miss += 1; missing.append(n)
print("iconos referenciados:", len(names), "| copiados:", copied, "| sin PNG:", miss)
if missing: print("faltan:", ", ".join(missing[:12]))
