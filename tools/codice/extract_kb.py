# -*- coding: utf-8 -*-
# Extrae el conocimiento canonico del addon a JSON para el codice: clases/subclases/rasgos
# (con OPCIONES de las elecciones), razas/rasgos, trasfondos/rasgos y CONJUROS del compendio
# (con lista por clase). Parseo por llaves equilibradas para captar bloques anidados.
import re, json, os

import glob
BASE = r"C:/Users/marco/Documents/New project"  # la raiz, no Harford/: el compendio y los
# datos de profesiones salieron a addons LoadOnDemand hermanos de esa carpeta.
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

def sin_subtablas(blk):
    """Bloque sin las tablas anidadas: `condition = { duration = "manual" }` tiene su
    propio `duration`, que NO es la duracion del conjuro. Los campos escalares se leen
    solo del nivel superior."""
    ini = blk.find("{")
    if ini < 0: return blk
    out, prof, j = [], 0, ini + 1
    out.append(blk[:ini + 1])
    while j < len(blk):
        c = blk[j]
        if c == "{": prof += 1
        elif c == "}":
            if prof == 0: out.append(blk[j:]); break
            prof -= 1
        elif prof == 0: out.append(c)
        j += 1
    return "".join(out)

def field(blk, key):
    m = re.search(r'\b' + key + r' = "((?:[^"\\]|\\.)*)"', blk)
    if not m: return None
    # des-escapado Lua completo: \n -> salto real, \" -> comilla, \\ -> barra
    return re.sub(r'\\(.)', lambda e: "\n" if e.group(1) == "n" else e.group(1), m.group(1))

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
# El libro se partio en un modulo por clase (Harford/DnD/Data/Classes/*.lua): el nucleo
# HarfordDnDBook.lua se quedo con los helpers y `API.CLASSES` vacio, y leyendo solo ese
# fichero el extractor pasaba de 12 clases a 0 sin quejarse. Se leen los dos y se pegan:
# asi funciona con el libro partido, con el entero, y durante el reparto, que es cuando
# una parte esta en cada sitio.
def _texto_de_clases():
    partes = []
    for ruta in sorted(glob.glob(os.path.join(BASE, "**", "Classes", "*.lua"), recursive=True)):
        partes.append(open(ruta, encoding="utf-8", errors="replace").read())
    partes.append(rd("HarfordDnDBook.lua"))
    # separador entre modulos: sin el, el ultimo bloque de un fichero y el primero del
    # siguiente quedan pegados y el parseo por llaves los mezcla
    return ("\n\n-- FIN DE MODULO --\n\n").join(partes)

book = _texto_de_clases()
class_hdr = re.compile(r'id = "([a-z_]+)", name = "([^"]+)", desc = "((?:[^"\\]|\\.)*)", hitDie = (\d+)')
classes = []
cstarts = [(m.start(), m.group(1), m.group(2), m.group(3), m.group(4)) for m in class_hdr.finditer(book)]
for i, (pos, cid, cname, cdesc, hd) in enumerate(cstarts):
    end = cstarts[i+1][0] if i+1 < len(cstarts) else len(book)
    block = book[pos:end]
    # La sangria dejo de ser fija al partir el libro: dentro de HarfordDnDBook.lua la tabla
    # de clase colgaba de API.CLASSES y sus campos iban a 8 espacios; en los modulos por
    # clase cuelga del nivel superior y van a 4. Exigir 8 dejaba las 37 subclases fuera.
    m = re.search(r'\n {2,12}features = \{', block)
    class_region = block[m.start():] if m else block
    sub_region = block[:m.start()] if m else ""
    subclasses = []
    # Entre `desc` y `features` puede haber campos propios de la subclase, como el
    # `requiredRace` del Sacerdocio de Elune. Sin admitirlos, su cabecera no se reconocia
    # y sus seis rasgos se quedaban dentro de la subclase anterior (Sombra).
    sub_hdrs = list(re.finditer(
        r'\{ id = "([a-z_]+)", name = "([^"]+)", desc = "((?:[^"\\]|\\.)*)"'
        r'(?:,\s*\w+ = (?:"(?:[^"\\]|\\.)*"|\d+|true|false|\{[^{}]*\}))*,\s*features =', sub_region))
    for j, sm in enumerate(sub_hdrs):
        s_end = sub_hdrs[j+1].start() if j+1 < len(sub_hdrs) else len(sub_region)
        sub = {"id": sm.group(1), "name": sm.group(2), "desc": sm.group(3).replace('\\"', '"'),
               "features": parse_features(sub_region[sm.end():s_end])}
        # el Sacerdocio de Elune solo esta abierto a elfos de la noche: sin este dato el
        # lector no tiene forma de saber que la subclase esta restringida
        rr = re.search(r'\brequiredRace = "([a-z_]+)"', sm.group(0))
        if rr: sub["requiredRace"] = rr.group(1)
        subclasses.append(sub)
    classes.append({"id": cid, "name": cname, "desc": cdesc.replace('\\"', '"'), "hitDie": int(hd),
                    "features": parse_features(class_region), "subclasses": subclasses})

# ---------- RAZAS ----------
# `nameF` (nombre en femenino) es un campo opcional que va entre `name` y `desc`.
# Sin contemplarlo, las razas que lo declaran no se reconocian.
OPC_NAMEF = r'(?:\s*nameF = "[^"]*",)?'
races_txt = rd("HarfordDnDRaces.lua")
race_hdr = re.compile(r'id = "([a-z_]+)", name = "([^"]+)",' + OPC_NAMEF + r' desc = "((?:[^"\\]|\\.)*)", faction')
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
        sub_hdrs = list(re.finditer(r'\{ id = "([a-z_]+)", name = "([^"]+)",' + OPC_NAMEF + r' desc = "((?:[^"\\]|\\.)*)", traits =', sub_region))
        for j, sm in enumerate(sub_hdrs):
            s_end = sub_hdrs[j+1].start() if j+1 < len(sub_hdrs) else len(sub_region)
            subraces.append({"id": sm.group(1), "name": sm.group(2), "desc": sm.group(3).replace('\\"', '"'),
                             "traits": parse_features(sub_region[sm.end():s_end])})
    else:
        rest = block
    # tamano, velocidad y faccion los declara el addon en la cabecera de la raza y no se
    # estaban recogiendo: sin ellos la ficha no dice ni lo que mide ni lo que se mueve
    _size = re.search(r'size = "([^"]+)"', block[:400])
    _speed = re.search(r'speed = ([\d.]+)', block[:400])
    _fac = re.search(r'faction = "([^"]+)"', block[:400])
    _raza = {"id": rid, "name": rname, "desc": rdesc.replace('\\"', '"'),
             "traits": parse_features(rest), "subraces": subraces}
    if _size: _raza["size"] = _size.group(1)
    if _speed: _raza["speed"] = float(_speed.group(1))
    if _fac: _raza["faction"] = _fac.group(1)
    races.append(_raza)

# ---------- TRASFONDOS ----------
bg_txt = rd("HarfordDnDBackgrounds.lua")
# El salto de linea cuenta, y no todos declaran lo mismo detras del nombre: cuatro
# trasfondos ponen sus alias en la linea siguiente y dos van directos a sus rasgos. Se
# quedaban fuera del compendio, que luego los recreaba desde el libro con peores datos.
bg_hdr = re.compile(r'id = "([a-z_0-9]+)", name = "([^"]+)",\s*(?:source|aliases|traits)')

# El addon declara que concede cada trasfondo con `Skill("Sigilo")`, `Tool("...")` o su
# forma larga `{ kind = "skillProf", skill = "..." }`. Se recogen para poder filtrar por
# habilidad, que es lo que mira quien esta eligiendo trasfondo.
_SKILL_CANON = {"animales": "Trato con Animales", "arcano": "Conocimiento Arcano",
                "engano": "Engaño", "interpretacion": "Interpretación",
                "intimidacion": "Intimidación", "investigacion": "Investigación",
                "juegomanos": "Juego de Manos", "percepcion": "Percepción",
                "persuasion": "Persuasión", "religion": "Religión",
                "atletismo": "Atletismo", "historia": "Historia", "medicina": "Medicina",
                "naturaleza": "Naturaleza", "perspicacia": "Perspicacia",
                "sigilo": "Sigilo", "supervivencia": "Supervivencia",
                "acrobacias": "Acrobacias"}


def _nk_sk(s):
    """Clave sin tildes para reconocer la habilidad tal como la escribe el addon."""
    import unicodedata
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower().strip()


def _competencias(block):
    hab, her = [], []
    for m in re.finditer(r'Skill\("([^"]+)"\)', block):
        hab.append(_SKILL_CANON.get(_nk_sk(m.group(1)), m.group(1)))
    for m in re.finditer(r'kind = "skillProf",\s*skill = "([^"]+)"', block):
        hab.append(_SKILL_CANON.get(_nk_sk(m.group(1)), m.group(1)))
    for m in re.finditer(r'Tool\("([^"]+)"\)', block):
        her.append(m.group(1))
    for m in re.finditer(r'kind = "toolProf",\s*tool = "([^"]+)"', block):
        her.append(m.group(1))
    # sin repetir y conservando el orden en que las declara el addon
    return list(dict.fromkeys(hab)), list(dict.fromkeys(her))


bgs = []
bstarts = [(m.start(), m.group(1), m.group(2)) for m in bg_hdr.finditer(bg_txt)]
for i, (pos, bid, bname) in enumerate(bstarts):
    end = bstarts[i+1][0] if i+1 < len(bstarts) else len(bg_txt)
    block = bg_txt[pos:end]
    dm = re.search(r'\bdesc = "((?:[^"\\]|\\.)*)"', block.split("traits =")[0])
    # de donde sale el trasfondo (PHB, SCAG, Warcraft o propio de Harford): el addon lo
    # marca y el compendio lo tiraba, asi que el lector no sabia cual era cual
    sm = re.search(r'\bsource = "([^"]+)"', block.split("traits =")[0])
    bgs.append({"id": bid, "name": bname, "desc": (dm.group(1).replace('\\"', '"') if dm else ""),
                "source": sm.group(1) if sm else None,
                "skills": _competencias(block)[0], "tools": _competencias(block)[1],
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
    plano = sin_subtablas(blk)
    for k in SPELL_KEYS_STR:
        # `condition` puede ser tabla: ahi si hace falta mirar dentro
        v = field(blk if k == "condition" else plano, k)
        if v: sp[k] = v
    lv = re.search(r'\blevel = (\d+)', blk); sp["level"] = int(lv.group(1)) if lv else 0
    ic = re.search(r'\bicon = (\d+|"(?:[^"\\]|\\.)*")', blk)
    if ic: sp["iconRaw"] = ic.group(1).strip('"').replace('\\\\', '\\')
    sp["classes"] = strlist(blk, "classes")
    sp["categories"] = strlist(blk, "categories")
    for bkey in ("concentration", "ritual"):
        if re.search(r'\b' + bkey + r' = true', blk): sp[bkey] = True
    spells.append(sp)
# ---- progresion de conjuros: se lee del addon para que la web no la duplique a mano ----
def _spell_progression():
    """SPELL_PROGRESSION de HarfordCompendioCore.lua, que es la fuente de verdad en juego.
    Cada clase ocupa una linea con llaves anidadas, asi que se recorre linea a linea."""
    ruta = glob.glob(os.path.join(BASE, "**", "HarfordCompendioCore.lua"), recursive=True)
    if not ruta: return {}
    src = open(ruta[0], encoding="utf-8", errors="replace").read()
    m = re.search(r"local SPELL_PROGRESSION = \{(.*?)\n\}", src, re.S)
    if not m: return {}
    out = {}
    for linea in m.group(1).split("\n"):
        mc = re.match(r'\s*\["([^"]+)"\]\s*=\s*\{(.*)$', linea)
        if not mc: continue
        clase, cuerpo = mc.group(1), mc.group(2)
        d = {}
        for campo in ("cantrips", "spells"):
            mm = re.search(campo + r"\s*=\s*\{([^}]*)\}", cuerpo)
            if mm: d[campo] = [int(x) for x in re.findall(r"\d+", mm.group(1))]
        mp = re.search(r'prepared\s*=\s*"([a-z]+)"', cuerpo)
        if mp: d["prepared"] = mp.group(1)
        if d: out[clase] = d
    return out

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

data = {
    "spellProgression": _spell_progression(),"classes": classes, "races": races, "backgrounds": bgs, "spells": spells, "professions": professions}
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
