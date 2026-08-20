# -*- coding: utf-8 -*-
# Extrae el conocimiento canonico del addon a JSON para el codice: clases/subclases/rasgos
# (con OPCIONES de las elecciones), razas/rasgos, trasfondos/rasgos y CONJUROS del compendio
# (con lista por clase). Parseo por llaves equilibradas para captar bloques anidados.
import re, json, os

import glob
BASE = r"C:/Users/marco/Documents/New project/Harford"
def rd(p):
    hits = glob.glob(os.path.join(BASE, "**", p), recursive=True)  # el addon se reorganizo en subcarpetas
    if not hits: hits = [os.path.join(BASE, p)]
    return open(hits[0], encoding="utf-8", errors="replace").read()

def balanced(text, open_pos):
    """Devuelve (end) tras cerrar la llave que abre en open_pos (text[open_pos]=='{')."""
    depth = 0
    for j in range(open_pos, len(text)):
        if text[j] == "{": depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0: return j + 1
    return len(text)

def field(blk, key):
    m = re.search(r'\b' + key + r' = "((?:[^"\\]|\\.)*)"', blk)
    return m.group(1).replace('\\"', '"') if m else None

def strlist(blk, key):
    m = re.search(r'\b' + key + r' = \{([^}]*)\}', blk)
    return [x for x in re.findall(r'"([^"]+)"', m.group(1))] if m else []

def parse_features(region):
    """Cada rasgo real = { id, name, type, description, [level], [choice.options] }.
    Las opciones internas ({id,label}) se filtran como rasgos (no tienen type+description)."""
    out = []
    for m in re.finditer(r'\{\s*id = "([a-z0-9_]+)"', region):
        blk = region[m.start():balanced(region, m.start())]
        nm, ty, de = field(blk, "name"), re.search(r'\btype = "([a-z]+)"', blk), field(blk, "description")
        if not (nm and ty and de is not None): continue
        lv = re.search(r'\blevel = (\d+)', blk)
        feat = {"id": m.group(1), "level": int(lv.group(1)) if lv else None,
                "name": nm, "type": ty.group(1), "desc": de}
        om = re.search(r'options = \{', blk)
        if om:
            oreg = blk[om.end()-1:balanced(blk, om.end()-1)]
            opts = [{"id": o.group(1), "label": o.group(2).replace('\\"', '"')}
                    for o in re.finditer(r'\{\s*id = "([^"]+)",\s*label = "((?:[^"\\]|\\.)*)"', oreg)]
            if opts: feat["options"] = opts
        out.append(feat)
    return out

# ---------- CLASES ----------
book = rd("HarfordDnDBook.lua")
class_hdr = re.compile(r'id = "([a-z_]+)", name = "([^"]+)", desc = "((?:[^"\\]|\\.)*)", hitDie = (\d+)')
classes = []
cstarts = [(m.start(), m.group(1), m.group(2), m.group(3), m.group(4)) for m in class_hdr.finditer(book)]
for i, (pos, cid, cname, cdesc, hd) in enumerate(cstarts):
    end = cstarts[i+1][0] if i+1 < len(cstarts) else len(book)
    block = book[pos:end]
    m = re.search(r'\n {8}features = \{', block)
    class_region = block[m.start():] if m else block
    sub_region = block[:m.start()] if m else ""
    subclasses = []
    sub_hdrs = list(re.finditer(r'\{ id = "([a-z_]+)", name = "([^"]+)", desc = "((?:[^"\\]|\\.)*)", features =', sub_region))
    for j, sm in enumerate(sub_hdrs):
        s_end = sub_hdrs[j+1].start() if j+1 < len(sub_hdrs) else len(sub_region)
        subclasses.append({"id": sm.group(1), "name": sm.group(2), "desc": sm.group(3).replace('\\"', '"'),
                           "features": parse_features(sub_region[sm.end():s_end])})
    classes.append({"id": cid, "name": cname, "desc": cdesc.replace('\\"', '"'), "hitDie": int(hd),
                    "features": parse_features(class_region), "subclasses": subclasses})

# ---------- RAZAS ----------
races_txt = rd("HarfordDnDRaces.lua")
race_hdr = re.compile(r'id = "([a-z_]+)", name = "([^"]+)", desc = "((?:[^"\\]|\\.)*)", faction')
races = []
rstarts = [(m.start(), m.group(1), m.group(2), m.group(3)) for m in race_hdr.finditer(races_txt)]
for i, (pos, rid, rname, rdesc) in enumerate(rstarts):
    end = rstarts[i+1][0] if i+1 < len(rstarts) else len(races_txt)
    block = races_txt[pos:end]
    # las subrazas viven en su propio bloque; sus rasgos no deben mezclarse con los de la raza
    subraces = []
    ms = re.search(r"\n {8}subraces = \{", block)
    if ms:
        s = block.index("{", ms.start())
        sub_region = block[s:balanced(block, s)]
        rest = block[:ms.start()] + block[s + len(sub_region):]
        sub_hdrs = list(re.finditer(r'\{ id = "([a-z_]+)", name = "([^"]+)", desc = "((?:[^"\\]|\\.)*)", traits =', sub_region))
        for j, sm in enumerate(sub_hdrs):
            s_end = sub_hdrs[j+1].start() if j+1 < len(sub_hdrs) else len(sub_region)
            subraces.append({"id": sm.group(1), "name": sm.group(2), "desc": sm.group(3).replace('\\"', '"'),
                             "traits": parse_features(sub_region[sm.end():s_end])})
    else:
        rest = block
    races.append({"id": rid, "name": rname, "desc": rdesc.replace('\\"', '"'),
                  "traits": parse_features(rest), "subraces": subraces})

# ---------- TRASFONDOS ----------
bg_txt = rd("HarfordDnDBackgrounds.lua")
bg_hdr = re.compile(r'id = "([a-z_]+)", name = "([^"]+)", (?:source|aliases)')
bgs = []
bstarts = [(m.start(), m.group(1), m.group(2)) for m in bg_hdr.finditer(bg_txt)]
for i, (pos, bid, bname) in enumerate(bstarts):
    end = bstarts[i+1][0] if i+1 < len(bstarts) else len(bg_txt)
    block = bg_txt[pos:end]
    dm = re.search(r'\bdesc = "((?:[^"\\]|\\.)*)"', block.split("traits =")[0])
    bgs.append({"id": bid, "name": bname, "desc": (dm.group(1).replace('\\"', '"') if dm else ""),
                "traits": parse_features(block)})

# ---------- CONJUROS ----------
comp = rd("HarfordCompendioData.lua")
spells = []
SPELL_KEYS_STR = ["name", "school", "affinity", "castingTime", "range", "components", "duration",
                  "savingThrow", "attack", "damage", "condition", "source", "description", "mechanics", "roleNotes"]
for m in re.finditer(r'\n {8}id = "([a-z0-9_]+)",', comp):
    st = comp.rfind("{", 0, m.start())
    blk = comp[st:balanced(comp, st)]
    if 'level =' not in blk or 'school =' not in blk: continue
    sp = {"id": m.group(1)}
    for k in SPELL_KEYS_STR:
        v = field(blk, k)
        if v: sp[k] = v
    lv = re.search(r'\blevel = (\d+)', blk); sp["level"] = int(lv.group(1)) if lv else 0
    ic = re.search(r'\bicon = (\d+|"(?:[^"\\]|\\.)*")', blk)
    if ic: sp["iconRaw"] = ic.group(1).strip('"').replace('\\\\', '\\')
    sp["classes"] = strlist(blk, "classes")
    sp["categories"] = strlist(blk, "categories")
    for bkey in ("concentration", "ritual"):
        if re.search(r'\b' + bkey + r' = true', blk): sp[bkey] = True
    spells.append(sp)
spells.sort(key=lambda s: (s["level"], s.get("name", "")))

# lista de conjuros por clase (nombre de conjuro-clase -> id de clase del codice)
SPELLCLASS_TO_ID = {"Brujo": "brujo", "Caballero de la Muerte": "caballero_muerte", "Chaman": "chaman",
    "Druida": "druida", "Mago": "mago", "Paladin": "paladin", "Picaro Sutileza": "picaro", "Sacerdote": "sacerdote"}
by_id = {}
for s in spells:
    for cn in s["classes"]:
        cid = SPELLCLASS_TO_ID.get(cn)
        if cid: by_id.setdefault(cid, set()).add(cn)
for c in classes:
    if c["id"] in by_id: c["spellClasses"] = sorted(by_id[c["id"]])

# ---------- PROFESIONES ----------
# Parseo POR LINEA con extraccion de campo individual: los datos van alineados con espacios
# variables y las regex de linea completa se rompian con ellos.
prof_src = rd("HarfordProfessionsData.lua")
items_src = rd("HarfordProfessionsItems.lua")
item_names = dict(re.findall(r'\["([a-z_0-9]+)"\]\s*=\s*\{\s*id\s*=\s*[^,]+,\s*name\s*=\s*"([^"]+)"', items_src))

def fld(line, key):
    m = re.search(key + r'\s*=\s*"([^"]*)"', line)
    return m.group(1) if m else None
def fnum(line, key):
    m = re.search(key + r'\s*=\s*(\d+)', line)
    return int(m.group(1)) if m else None

prof_defs, recipes_by_prof = [], {}
in_recipes = False
for line in prof_src.split(chr(10)):
    if "D.RECIPES" in line: in_recipes = True
    s = line.strip()
    if not s.startswith("{ id ="): continue
    if not in_recipes:
        pid = fld(s, "id")
        if pid and fld(s, "kind"):
            prof_defs.append({"id": pid, "name": fld(s, "name"), "tool": fld(s, "tool"),
                              "kind": fld(s, "kind"), "ability": fld(s, "ability"), "icon": fld(s, "icon")})
    else:
        rid, prof = fld(s, "id"), fld(s, "profession")
        if not (rid and prof): continue
        mats_m = re.search(r"materials\s*=\s*\{(.*)\},\s*output", s)
        mats = [{"name": item_names.get(k, k), "qty": int(q)}
                for k, q in re.findall(r'key\s*=\s*"([a-z_0-9]+)",\s*qty\s*=\s*(\d+)', mats_m.group(1))] if mats_m else []
        out_m = re.search(r'output\s*=\s*\{\s*key\s*=\s*"([a-z_0-9]+)",\s*qty\s*=\s*(\d+)', s)
        recipes_by_prof.setdefault(prof, []).append({
            "id": rid, "skill": fnum(s, "skillReq") or 1, "name": fld(s, "name"), "icon": fld(s, "icon"),
            "dc": fnum(s, "dc") or 10, "mats": mats,
            "out": item_names.get(out_m.group(1), out_m.group(1)) if out_m else "?",
            "qty": int(out_m.group(2)) if out_m else 1,
            "wl": "worldLearned = true" in s})

professions = []
for d in prof_defs:
    recs = sorted(recipes_by_prof.get(d["id"], []), key=lambda x: x["skill"])
    if recs:
        d["recipes"] = recs
        professions.append(d)

data = {"classes": classes, "races": races, "backgrounds": bgs, "spells": spells, "professions": professions}
HERE = os.path.dirname(os.path.abspath(__file__))
json.dump(data, open(os.path.join(HERE, "kb.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
nopt = sum(1 for c in classes for f in c["features"] + [x for s in c["subclasses"] for x in s["features"]] if f.get("options"))
print("Clases: %d (%d subclases, %d rasgos, %d con opciones)" % (
    len(classes), sum(len(c["subclasses"]) for c in classes),
    sum(len(c["features"]) + sum(len(s["features"]) for s in c["subclasses"]) for c in classes), nopt))
print("Razas: %d (%d rasgos) | Trasfondos: %d (%d rasgos)" % (
    len(races), sum(len(r["traits"]) for r in races), len(bgs), sum(len(b["traits"]) for b in bgs)))
print("Conjuros: %d | clases con lista: %s" % (len(spells), [c["id"] for c in classes if c.get("spellClasses")]))
print("Profesiones: %d | recetas: %d" % (len(professions), sum(len(p.get("recipes", [])) for p in professions)))
