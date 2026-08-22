# -*- coding: utf-8 -*-
# Actualiza Inteligencia de la web: copia los iconos de faccion (de la reputacion de GRIKER)
# sobre el arte actual y fija relacion/clase de cada entrada segun las reps de Gmaster.
import json, io, re, os, sys, shutil, unicodedata
sys.stdout.reconfigure(encoding="utf-8")

SP = os.path.dirname(os.path.abspath(__file__))
WEB = r"C:/Users/marco/Documents/harfordweb"
EIPNG = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c)!="Mn")
def nk(s): return re.sub(r"[^a-z0-9]+"," ", sa(s or "").lower()).strip()

RANK2CLASS = {"Odiado":"hated","Hostil":"hostile","Adverso":"adverse","Neutral":"neutral",
  "Amistoso":"friendly","Honorable":"honored","Reverenciado":"revered","Exaltado":"exalted","Sin registrar":"unknown"}

reps = json.load(io.open(os.path.join(SP,"reps_gmaster.json"),encoding="utf-8"))
byid = {f["id"]:f for f in reps}
ALIAS = {"velasangre":"piratas de los mares","industrias_petronegro":"loto dorado",
  "industrias_petronegro_2":"industrias petronegro","ventura_y_c_a":"cartel ventura",
  "cartel_tuercarrota":"banda de tuercarrota"}

files = {"org":"organizations.js","contact":"contacts.js","place":"places.js"}
# indice nk(name) -> (kind, slug)
entries = {}
for kind,fn in files.items():
    t = io.open(os.path.join(WEB,"js",fn),encoding="utf-8").read()
    for oid,oname in re.findall(r'"id":\s*"([^"]+)",\s*"name":\s*"([^"]+)"', t):
        entries[nk(oname)] = (kind, oid)

# faccion -> (kind, slug)
fmap = {}
for f in reps:
    hit = entries.get(nk(ALIAS.get(f["id"], f["name"]))) or entries.get(nk(f["name"]))
    if hit: fmap[f["id"]] = hit

# 1) copiar iconos
icon_ok = icon_miss = 0
missing_icons = []
for fid,(kind,slug) in fmap.items():
    ic = (byid[fid]["icon"] or "").split("\\")[-1].lower()
    src = os.path.join(EIPNG, ic + ".png")
    dst = os.path.join(WEB, "assets", "icons", slug + ".png")
    if ic and os.path.exists(src):
        shutil.copyfile(src, dst); icon_ok += 1
    else:
        icon_miss += 1; missing_icons.append((slug, ic))

# 2) actualizar relacion/clase en cada archivo (por bloque de entrada)
def update_file(fn, relkey):
    path = os.path.join(WEB, "js", fn)
    t = io.open(path, encoding="utf-8").read()
    # localizar bloques por id
    ids = [(m.start(), m.group(1)) for m in re.finditer(r'"id":\s*"([^"]+)"', t)]
    # construir slug->faccion para este archivo
    slug2f = {slug:fid for fid,(kind,slug) in fmap.items()}
    changed = 0
    # procesar de atras hacia delante para no descuadrar indices
    for i in range(len(ids)-1, -1, -1):
        pos, slug = ids[i]
        end = ids[i+1][0] if i+1 < len(ids) else len(t)
        fid = slug2f.get(slug)
        if not fid: continue
        f = byid[fid]
        rname = f["rankName"]; rcls = RANK2CLASS.get(rname, "unknown")
        block = t[pos:end]
        nb = re.sub(r'("'+relkey+r'":\s*")[^"]*(")', lambda m: m.group(1)+rname+m.group(2), block, count=1)
        nb = re.sub(r'("relationClass":\s*")[^"]*(")', lambda m: m.group(1)+rcls+m.group(2), nb, count=1)
        if nb != block: t = t[:pos] + nb + t[end:]; changed += 1
    io.open(path, "w", encoding="utf-8").write(t)
    return changed

c_org = update_file("organizations.js", "relation")
c_con = update_file("contacts.js", "relation")
c_pla = update_file("places.js", "reputation")

print("Iconos copiados:", icon_ok, "| sin PNG:", icon_miss, missing_icons)
print("Actualizados -> org:", c_org, "contactos:", c_con, "lugares:", c_pla)
print("Facciones mapeadas:", len(fmap), "de", len(reps))
