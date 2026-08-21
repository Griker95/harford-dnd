# -*- coding: utf-8 -*-
# Enriquece el kb del codice con TODO el texto del libro: intro de clase y de raza, rasgos de
# clase/subclase (chapter-aware), y trasfondos completos del Discord export (matcheo fuzzy).
import re, io, os, json, unicodedata, difflib, sys
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
from metrico import a_metrico  # los manuales de D&D vienen en pies y libras

SP = os.path.dirname(os.path.abspath(__file__))
MD = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
def nk(s): return re.sub(r"[^0-9a-z]+", " ", sa(s or "").lower()).strip()
def nkbase(s): return nk(re.sub(r"\s*\([^)]*\)\s*$", "", s or ""))

kb = json.load(io.open(os.path.join(SP, "kb_icons.json"), encoding="utf-8"))
src = re.sub(r"\r", "", io.open(MD, encoding="utf-8").read())
heads = []
for m in re.finditer(r"\n(#{1,6})\s*([^\n]+)", src):
    txt = m.group(2).strip().strip("*").strip()
    heads.append((len(m.group(1)), txt, nk(txt), m.start(), m.end()))

def clean_body(t):
    # los titulos internos se conservan con un marcador uniforme "### " para que la
    # web los renderice como encabezados con su propia tipografia
    t = re.sub(r"\n#{1,6}\s*", "\n### ", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t.strip()

def section(name, level=2, stop_at_names=None):
    """Texto desde el heading `name` (nivel dado) hasta el siguiente heading <= level;
    si stop_at_names, para al primero de esos (p.ej. 'rasgos de clase')."""
    wn = nk(name)
    for i, (lvl, txt, k, a, b) in enumerate(heads):
        if lvl == level and k == wn:
            start = b
            end = len(src)
            for l2, t2, k2, a2, b2 in heads[i+1:]:
                if l2 <= level: end = a2; break
                if stop_at_names and k2 in stop_at_names: end = a2; break
            return clean_body(src[start:end])
    return None

CLASS_MD = {"guerrero":"Guerrero","paladin":"Paladín","cazador_demonios":"Cazador de Demonios",
  "cazador":"Cazador","picaro":"Pícaro","sacerdote":"Sacerdote","caballero_muerte":"Caballero de la Muerte",
  "chaman":"Chamán","mago":"Mago","brujo":"Brujo","monje":"Monje","druida":"Druida"}
CLASSNAMES = set(nk(v) for v in CLASS_MD.values())
RACE_MD = {"humano":"Humano","enano":"Enano","elfo_noche":"Elfo de la Noche","elfo_sangre":"Elfo de Sangre",
  "semielfo":"Semielfo","gnomo":"Gnomo","draenei":"Draenei","huargen":"Huargen","orco":"Orco",
  "renegado":"Renegados","tauren":"Tauren","trol":"Troll","goblin":"Goblin","pandaren":"Pandaren",
  "nocheterna":"Nocheterna","elfo_vacio":"Elfos del Vacío","vulpera":"Vulpera"}
# (el Semielfo no existe en el libro Warcraft: es raza del PHB y conserva su texto propio)

def chapter(className):
    wc = nk(className); start = end = None
    for lvl, txt, k, a, b in heads:
        if lvl == 2:
            if start is None and k == wc: start = b
            elif start is not None and k != wc and k in CLASSNAMES: end = a; break
    return (start, end if end else len(src)) if start is not None else None

def next_heading(pos, lvl):
    for l, t, k, a, b in heads:
        if a > pos and l <= lvl: return a
    return len(src)

def feature_text(className, featName):
    ch = chapter(className)
    if not ch: return None
    a, b = ch; wt, wb = nk(featName), nkbase(featName)
    for lvl, txt, k, ha, he in heads:
        if a <= ha < b and lvl in (3, 4) and (k == wt or (wb and k == wb)):
            bs = src.find("\n", he); be = min(next_heading(bs, lvl), b)
            return clean_body(src[bs:be]) or None
    return None

# (las clases se procesan mas abajo, cuando ya estan definidos chapter_generic y bold_entries)

RACENAMES = set(nk(v) for v in RACE_MD.values())

def chapter_generic(name, names_set, level=2):
    """Tramo del libro que va del titulo `name` al siguiente titulo hermano de su grupo."""
    wc = nk(name); start = end = None
    for lvl, txt, k, a, b in heads:
        if lvl == level:
            if start is None and k == wc: start = b
            elif start is not None and k != wc and k in names_set: end = a; break
    return (start, end if end else len(src)) if start is not None else None

BOLD_ENTRY = re.compile(r"\*\*\*\s*([^*\n]+?)\.?\s*\*\*\*\s*(.*?)(?=\n\s*\*\*\*|\n#{1,6}\s|\Z)", re.S)
def bold_entries(rango):
    """Rasgos escritos como '***Nombre.*** texto' (asi van los raciales y las dotes),
    que no son titulos y por eso no aparecen en el indice de encabezados."""
    if not rango: return {}
    a, b = rango
    out = {}
    for m in BOLD_ENTRY.finditer(src[a:b]):
        nombre, cuerpo = m.group(1).strip(), clean_body(m.group(2))
        if nombre and cuerpo: out.setdefault(nk(nombre), cuerpo)
    return out

def parecido_en(rango, featName, negritas, minimo=0.86):
    """Emparejar por parecido de nombre dentro del capitulo. NO se usa: probado con
    umbral 0.86 solo recuperaba 2 rasgos de 217 y podia pegarle a un rasgo el texto
    de otro, asi que no compensa. Se deja por si hiciera falta con revision manual."""
    if not rango: return None
    a, b = rango
    cands = dict(negritas)
    for lvl, txt, k, ha, he in heads:                    # titulos del propio capitulo
        if a <= ha < b and lvl in (3, 4, 5):
            bs = src.find("\n", he); be = min(next_heading(bs, lvl), b)
            cuerpo = clean_body(src[bs:be])
            if cuerpo: cands.setdefault(k, cuerpo)
    if not cands: return None
    wt = nk(featName)
    mejor = max(cands, key=lambda k: difflib.SequenceMatcher(None, wt, k).ratio())
    if difflib.SequenceMatcher(None, wt, mejor).ratio() >= minimo: return cands[mejor]
    return None

def feature_in(rango, featName, levels=(3, 4, 5)):
    """Texto de un rasgo buscado SOLO dentro del tramo indicado."""
    if not rango: return None
    a, b = rango; wt, wb = nk(featName), nkbase(featName)
    for lvl, txt, k, ha, he in heads:
        if a <= ha < b and lvl in levels and (k == wt or (wb and k == wb)):
            bs = src.find("\n", he); be = min(next_heading(bs, lvl), b)
            return clean_body(src[bs:be]) or None
    return None

# rasgos de clase del Caldero de Tasha (titulos en imagen): cuerpos curados en Export/
_TASHA_R = {}
import os as _os
_tr = r"C:/Users/marco/Documents/New project/RuleSource/Export/rasgos_tasha.json"
if _os.path.exists(_tr):
    for _k, _v in json.load(io.open(_tr, encoding="utf-8")).items():
        _TASHA_R[nk(_k)] = _v["texto"]

# ----- CLASES: intro del capitulo + rasgos (como titulo o en negrita dentro del capitulo) -----
cf = ct = 0
# ----- recuadros con marco ('>' del markdown = sidebars del PDF): sacarlos TODOS -----
def cajas_de(rango):
    """Bloques '>' del capitulo, fusionando los que solo separa una linea en blanco
    (en el libro son un mismo recuadro, p.ej. titulo + stat block)."""
    if not rango: return []
    if isinstance(rango, tuple): rango = src[rango[0]:rango[1]]
    lineas = rango.split("\n")
    grupos, actual, i = [], [], 0
    while i < len(lineas):
        l = lineas[i]
        if l.lstrip().startswith(">"):
            actual.append(l); i += 1; continue
        if actual and not l.strip():
            j = i
            while j < len(lineas) and not lineas[j].strip(): j += 1
            if j < len(lineas) and lineas[j].lstrip().startswith(">"):
                actual.append(">"); i = j; continue
        if actual: grupos.append("\n".join(actual)); actual = []
        i += 1
    if actual: grupos.append("\n".join(actual))
    return [g for g in grupos if len(re.sub(r"[>\s]", "", g)) > 40]

def anexar_cajas(obj, rango):
    """Recoge los recuadros del capitulo que no esten ya en el desc del objeto ni en el
    de sus rasgos/subclases/subrazas y los guarda en `extras`: la ficha de la web los
    muestra AL FINAL del todo, no pegados a la introduccion."""
    cajas = cajas_de(rango)
    if not cajas: return 0
    textos = [obj.get("desc") or "", obj.get("extras") or ""]
    for f in obj.get("features", []) + obj.get("traits", []): textos.append(f.get("desc") or "")
    for s in obj.get("subclasses", []) + obj.get("subraces", []):
        textos.append(s.get("desc") or "")
        for f in s.get("features", []) + s.get("traits", []): textos.append(f.get("desc") or "")
    todo = nk(" ".join(textos))
    n = 0
    for caja in cajas:
        clave = nk(re.sub(r"[>#*|]", "", caja))[:70]
        if clave and clave not in todo:
            obj["extras"] = ((obj.get("extras") or "").rstrip() + "\n\n" + caja.strip()).strip()
            todo += " " + clave; n += 1
    return n

ncajas = 0
for c in kb["classes"]:
    cn = CLASS_MD.get(c["id"], c["name"])
    intro = section(cn, 2, stop_at_names={"rasgos de clase"})
    if intro and len(intro) > len(c.get("desc", "")): c["desc"] = intro
    negritas_c = bold_entries(chapter(cn))
    for f in c["features"] + [x for s in c["subclasses"] for x in s["features"]]:
        ct += 1
        full = (feature_text(cn, f["name"])
                or negritas_c.get(nk(f["name"])) or negritas_c.get(nkbase(f["name"]))
                or _TASHA_R.get(nk(f["name"])))
        if full and len(full) > len(f.get("desc", "")): f["desc"] = full; cf += 1
    feats_all = c["features"] + [x for s in c["subclasses"] for x in s["features"]]
    nombres_f = {nk(f["name"]) for f in feats_all}
    for f in feats_all:
        d0 = f.get("desc") or ""
        # los recuadros '>' que cayeron dentro de un rasgo no son suyos: se retiran y
        # anexar_cajas los recogera despues en los extras de la clase
        d0 = re.sub(r"(?:^>.*\n?)+\n?", "", d0, flags=re.M)
        # si el texto capturo la seccion del rasgo SIGUIENTE (heading mas profundo), se
        # trunca ahi: el otro rasgo ya tiene su propia tarjeta
        for m2 in re.finditer(r"^#{1,6}\s+(.+)$", d0, re.M):
            if nk(m2.group(1)) in nombres_f and nk(m2.group(1)) != nk(f["name"]):
                d0 = d0[:m2.start()].rstrip(); break
        # rasgos de eleccion: las secciones internas que coinciden con una opcion
        # (Defensa, Duelos...) se reparten a esa opcion, no quedan como titulos sueltos
        opts = f.get("options") or (f.get("choice") or {}).get("options") or []
        if opts:
            por_nombre = {}
            for o in opts:
                et = o.get("label") or o.get("id") or ""
                por_nombre.setdefault(nk(et), o)
                por_nombre.setdefault(nk(re.sub(r"\s*\(.*\)\s*$", "", et)), o)
            secciones = list(re.finditer(r"^#{1,6}\s+(.+)$", d0, re.M))
            recortes = []
            for idx2, m2 in enumerate(secciones):
                o = por_nombre.get(nk(m2.group(1)))
                if not o: continue
                fin2 = secciones[idx2+1].start() if idx2+1 < len(secciones) else len(d0)
                cuerpo2 = d0[m2.end():fin2].strip()
                if cuerpo2 and len(cuerpo2) > len(o.get("desc") or ""):
                    o["desc"] = cuerpo2
                recortes.append((m2.start(), fin2))
            for a2, b2 in reversed(recortes):
                d0 = (d0[:a2] + d0[b2:])
        f["desc"] = re.sub(r"\n{3,}", "\n\n", d0).strip()
    ncajas += anexar_cajas(c, chapter(cn))

# ----- RAZAS: intro + rasgos propios y de subraza, buscados dentro del capitulo de la raza -----
rf = rt = rtok = 0
for r in kb["races"]:
    rn = RACE_MD.get(r["id"])
    if not rn: continue
    intro = section(rn, 2)
    if intro and len(intro) > len(r.get("desc", "")): r["desc"] = intro; rf += 1
    rango = chapter_generic(rn, RACENAMES)
    negritas = bold_entries(rango)
    for f in r["traits"] + [x for s in r.get("subraces", []) for x in s["traits"]]:
        rt += 1
        full = (feature_in(rango, f["name"]) or negritas.get(nk(f["name"]))
                or negritas.get(nkbase(f["name"])))
        if full and len(full) > len(f.get("desc", "")): f["desc"] = full; rtok += 1
    ncajas += anexar_cajas(r, rango)

# ----- TRASFONDOS: Discord export con matcheo fuzzy -----
bgs = json.load(io.open(os.path.join(SP, "bgs_source.json"), encoding="utf-8"))
srckeys = {slug: nk(slug.replace("_", " ")) for slug in bgs}
bf = 0
for b in kb["backgrounds"]:
    bnk = nk(b["name"])
    best, bestr = None, 0.0
    for slug, sk in srckeys.items():
        r = difflib.SequenceMatcher(None, bnk, sk).ratio()
        if r > bestr: best, bestr = slug, r
    if bestr < 0.62: continue
    d = bgs[best]
    if d.get("desc"): b["desc"] = d["desc"]; bf += 1
    rn = nk(d.get("rasgoName", ""))
    for f in b["traits"]:
        fn = nk(re.sub(r"^caracteristica:\s*", "", f["name"], flags=re.I))
        if d.get("rasgoDesc") and (fn == rn or "caracteristica" in nk(f["name"]) or difflib.SequenceMatcher(None, fn, rn).ratio() > 0.7):
            f["desc"] = d["rasgoDesc"]; f["name"] = "Rasgo: " + d["rasgoName"]; break

# ----- TRASFONDOS del Manual del Jugador: presentacion, competencias, equipo y rasgo -----
PHB_BG = r"C:/Users/marco/Documents/New project/RuleSource/Export/trasfondos_phb.json"
PHB_RASGOS = PHB_BG.replace(".json", "_rasgos.json")
CAMPO_A_RASGO = {"competencias en habilidades": "competencias",
                 "competencias con herramientas": "competencia con herramientas",
                 "idiomas": "idiomas", "equipo": "equipo"}
bphb = brasgos = 0
if os.path.exists(PHB_BG):
    phb = {nk(x["nombre"]): x for x in json.load(io.open(PHB_BG, encoding="utf-8"))}
    rasgos_phb = json.load(io.open(PHB_RASGOS, encoding="utf-8")) if os.path.exists(PHB_RASGOS) else {}
    for b in kb["backgrounds"]:
        x = phb.get(nk(b["name"]))
        if not x: continue
        if x.get("desc") and len(x["desc"]) > len(b.get("desc", "")): b["desc"] = x["desc"]; bphb += 1
        for f in b["traits"]:
            fn = nk(f["name"])
            # los campos del manual ("Competencias en habilidades: ...") rellenan sus rasgos
            for campo, destino in CAMPO_A_RASGO.items():
                if fn.startswith(destino) and x.get(campo) and len(x[campo]) > len(f.get("desc", "")):
                    f["desc"] = x[campo]; brasgos += 1; break
            else:
                # el rasgo propio del trasfondo ("Caracteristica: Refugio del fiel")
                clave = nk(re.sub(r"^caracteristica:\s*", "", f["name"], flags=re.I))
                r = rasgos_phb.get(clave)
                if r and len(r["texto"]) > len(f.get("desc", "")):
                    f["desc"] = r["texto"]; brasgos += 1

# ----- VARIANTES de trasfondo del Manual del Jugador (Gladiador, Espia, Pirata...) -----
VAR_PHB = r"C:/Users/marco/Documents/New project/RuleSource/Export/variantes_phb.json"
nvar = 0
if os.path.exists(VAR_PHB):
    for v in json.load(io.open(VAR_PHB, encoding="utf-8")):
        b = next((x for x in kb["backgrounds"] if nk(x["name"]) == nk(v["bg"])), None)
        if not b: continue
        nombre = "Variante: " + v["variante"]
        if any(nk(tr["name"]) == nk(nombre) for tr in b["traits"]): continue
        b["traits"].append({"id": "var_" + nk(v["variante"]).replace(" ", "_"),
                            "level": None, "name": nombre, "type": "informativo",
                            "desc": v["texto"]})
        nvar += 1

# ----- TRASFONDOS sin Discord: usar su rasgo 'Caracteristica' como descripcion -----
cff = 0
for b in kb["backgrounds"]:
    if b.get("desc"): continue
    car = next((t for t in b["traits"] if re.match(r"caracter", t["name"], re.I)), None)
    if car and car.get("desc"): b["desc"] = car["desc"]; cff += 1

# ----- limpieza a prosa de TODOS los desc (quita *, |, \cmd, blockquote) -----
BULLET = "•"
def is_table_line(l): return l.lstrip().startswith("|")
def strip_progression(text):
    """Elimina las tablas de progresion de clase ('| Nivel | ...') que el PDF extrae
    destrozadas (cabecera multilinea, ~20 columnas). Deja el resto (tablas limpias) intacto."""
    lines = text.split("\n"); out = []; i = 0; n = len(lines)
    while i < n:
        if re.match(r"\s*\|\s*Nivel\b", lines[i]) or "Espacios de Conjuros" in lines[i]:
            i += 1
            while i < n:
                if lines[i].strip() == "":
                    k = i + 1
                    while k < n and lines[k].strip() == "": k += 1
                    if k >= n or not lines[k].lstrip().startswith("|"): i = k; break
                i += 1
            # quitar un 'El <Clase>' o titulo corto colgante justo antes
            while out and out[-1].strip() and len(out[-1].strip()) < 24 and "|" not in out[-1]:
                out.pop()
            continue
        out.append(lines[i]); i += 1
    return "\n".join(out)
# --- normalizacion de titulos internos: solo primera mayuscula, conservando nombres
# --- de clase/raza y propios ("Creando un Caballero de la Muerte", "Gracia de Elune")
_PROTEGIDOS = sorted(set(list(CLASS_MD.values()) + list(RACE_MD.values()) +
                         ["Elune", "Azeroth", "Illidari", "Rey Exánime", "Cenarion",
                          "Alexstrasza", "Ysera", "Kalimdor", "Rasganorte"]),
                     key=len, reverse=True)
def norm_titulo(t):
    # a minusculas todo menos la primera letra y la primera tras ":" o "."
    def frase(s):
        s = s.strip()
        if not s: return s
        s = s[0] + s[1:].lower()
        return s
    partes = re.split(r"(\s*[:.]\s*)", t.strip())
    t2 = "".join(frase(p) if i % 2 == 0 else p for i, p in enumerate(partes))
    # restaurar nombres protegidos con su capitalizacion canonica
    for p in _PROTEGIDOS:
        t2 = re.sub(re.escape(p), p, t2, flags=re.I)
    return t2

def prose(t):
    if not t: return t
    t = t.replace("\r", "")
    t = strip_progression(t)
    # titulos internos (### y > #####): normalizar su capitalizacion
    t = re.sub(r"^(\s*(?:>\s*)?#{1,6}\s+)(.+)$",
               lambda m: m.group(1) + norm_titulo(m.group(2)), t, flags=re.M)
    # cabeceras en linea del libro ("***Caracteristica Minima.*** texto"): misma norma
    t = re.sub(r"(?m)^((?:>\s*)?)\*\*\*([^*\n]{2,45}?)(\.?)\*\*\*",
               lambda m: m.group(1) + "***" + norm_titulo(m.group(2)) + m.group(3) + "***", t)
    out = []
    for line in t.split("\n"):
        if is_table_line(line):
            # preservar filas de tabla intactas (el template las renderiza); solo aislar el bloque
            if out and out[-1].strip() and not is_table_line(out[-1]): out.append("")
            out.append(re.sub(r"[ \t]{2,}", " ", line).rstrip())
            continue
        l = re.sub(r"\\[a-zA-Z]+", "", line)
        # las negritas/cursivas del markdown se conservan: la web las renderiza
        l = re.sub(r"(?<![*\w])\*(?![*\w])", "", l)   # solo asteriscos sueltos
        l = re.sub(r"(?<![A-Za-z0-9])_([^_\n]+)_(?![A-Za-z0-9])", r"\1", l)
        # los bloques '>' son los recuadros con marco del PDF (reglas adicionales,
        # formas druidicas, stat blocks): se conservan para que la web los enmarque
        es_caja = bool(re.match(r"^\s*>", l))
        if es_caja: l = re.sub(r"^\s*>\s?", "> ", l)
        l = l.replace("`", "")
        if not es_caja: l = l.replace("|", "")
        l = re.sub(r"^\s*[-" + BULLET + r"]\s+", BULLET + " ", l)
        l = re.sub(r"[ \t]+", " ", l)
        out.append(l)
    t = "\n".join(out)
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t.strip()
def walk(o):
    if isinstance(o, dict):
        if isinstance(o.get("desc"), str): o["desc"] = a_metrico(prose(o["desc"]))
        if isinstance(o.get("extras"), str): o["extras"] = a_metrico(prose(o["extras"]))
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(kb)

json.dump(kb, io.open(os.path.join(SP, "kb_icons.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("Clases: intro + %d/%d rasgos completos" % (cf, ct))
print("Razas: %d intros | rasgos de raza/subraza con texto: %d/%d" % (rf, rtok, rt))
print("Trasfondos: %d Discord + %d por Caracteristica = %d/%d con desc" % (
    bf, cff, sum(1 for b in kb["backgrounds"] if b.get("desc")), len(kb["backgrounds"])))
print("Trasfondos PHB: %d intros + %d rasgos" % (bphb, brasgos))
print("Variantes PHB anadidas: %d" % nvar)
print("Recuadros del libro anexados: %d" % ncajas)
print("Conjuros: %d (pasan sin tocar)" % len(kb.get("spells", [])))
