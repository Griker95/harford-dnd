# -*- coding: utf-8 -*-
"""Genera js/compendium-professions.js para la web desde el addon HarfordProfesiones (globals HarfordProfessionsData/Items).

Cada profesion sale con sus recetas resueltas (materiales/salida por nombre visible del
registro de items) y copia a assets/compendium-icons/ los PNG de EpsilonIcons que use.
"""
import io, os, re, sys, glob, json, shutil

sys.stdout.reconfigure(encoding="utf-8")
BASE = r"C:/Users/marco/Documents/New project"
WEB = r"C:/Users/marco/Documents/harfordweb"
PNG = os.path.join(BASE, "EpsilonIcons", "png")

# Desde la RAIZ, no desde Harford/: los datos de profesiones salieron a un addon
# LoadOnDemand hermano de esa carpeta, igual que el compendio.
def _lee(nombre):
    hits = glob.glob(os.path.join(BASE, "**", nombre), recursive=True)
    # fuera las copias empaquetadas: los zips dejan el addon entero duplicado bajo dist/ y
    # el glob puede devolver ese snapshot antes que la fuente viva
    hits = [h for h in hits if "dist" not in h.replace("\\", "/").split("/")] or hits
    if not hits:
        raise SystemExit("no encuentro %s bajo %s" % (nombre, BASE))
    return io.open(hits[0], encoding="utf-8").read()


DATA = _lee("HarfordProfesiones.lua")
ITEMS = _lee("HarfordProfesionesItems.lua")

g = lambda blk, k: (re.search(r'\b%s\s*=\s*"((?:[^"\\]|\\.)*)"' % k, blk).group(1) if re.search(r'\b%s\s*=\s*"' % k, blk) else "")
gn = lambda blk, k: (int(re.search(r"\b%s\s*=\s*(\d+)" % k, blk).group(1)) if re.search(r"\b%s\s*=\s*\d+" % k, blk) else None)

# ---- registro de items: clave -> nombre visible ----
items, wow = {}, {}
for m in re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{(.*?)\}', ITEMS, re.S):
    items[m.group(1)] = g(m.group(2), "name") or m.group(1)
    # el itemId de WoW es la llave para colgar de cada material y cada resultado su ficha
    w = gn(m.group(2), "wow")
    if w: wow[m.group(1)] = w

# ---- profesiones ----
profs, orden = {}, []
pm = re.search(r"D\.PROFESSIONS\s*=\s*\{(.*?)\n\}", DATA, re.S)
for m in re.finditer(r"\{([^{}]*)\}", pm.group(1)):
    blk = m.group(1)
    pid = g(blk, "id")
    if not pid: continue
    profs[pid] = {"id": pid, "name": g(blk, "name"), "tool": g(blk, "tool") or None,
                  "kind": g(blk, "kind"), "ability": g(blk, "ability"), "icon": g(blk, "icon"),
                  "recipes": []}
    orden.append(pid)

# ---- recetas (bloques anidados: materials/output dentro) ----
rm = re.search(r"D\.RECIPES\s*=\s*\{(.*)\n\}", DATA, re.S)
def balanced(text, i):
    d = 0
    for j in range(i, len(text)):
        if text[j] == "{": d += 1
        elif text[j] == "}":
            d -= 1
            if d == 0: return j + 1
    return len(text)

src = rm.group(1)
pos = 0
nrec = 0
while True:
    m = re.search(r'\{\s*id\s*=\s*"', src[pos:])
    if not m: break
    ini = pos + m.start()
    fin = balanced(src, ini)
    blk = src[ini:fin]; pos = fin
    prof = g(blk, "profession")
    if prof not in profs: continue
    mats = []
    mm = re.search(r"materials\s*=\s*\{(.*?)\}\s*,\s*output", blk, re.S)
    if mm:
        for x in re.finditer(r'\{\s*key\s*=\s*"([^"]+)",\s*qty\s*=\s*(\d+)\s*\}', mm.group(1)):
            mats.append({"name": items.get(x.group(1), x.group(1)), "qty": int(x.group(2)),
                         "wow": wow.get(x.group(1))})
    # la clave puede llevar tilde ("ungüento_curativo"): sin esto la receta salia sin resultado
    om = re.search(r'output\s*=\s*\{\s*key\s*=\s*"([^"]+)",\s*qty\s*=\s*(\d+)', blk)
    profs[prof]["recipes"].append({
        "id": g(blk, "id"), "name": g(blk, "name"), "icon": g(blk, "icon"),
        "skillReq": gn(blk, "skillReq"), "dc": gn(blk, "dc"),
        # lo que la calidad del objeto fabricado suma o resta a la CD de la banda
        "qmod": (int(re.search(r"qmod\s*=\s*(-?\d+)", blk).group(1))
                 if re.search(r"qmod\s*=", blk) else 0),
        # los cuatro umbrales de color: de ellos sale la CD real, que baja segun tu habilidad
        "colors": [int(x) for x in (re.search(r"colors\s*=\s*\{\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\}", blk).groups()
                                    if re.search(r"colors\s*=\s*\{", blk) else [])] or None,
        "desc": g(blk, "desc") or None,
        # de donde se aprende: entrenador (con su precio) o un objeto de receta
        "source": g(blk, "source") or None,
        # las herramientas que exige la receta (yunque, martillo, vara runica...)
        "tools": g(blk, "tools") or None,
        "trainCost": gn(blk, "trainCost"),
        "ability": g(blk, "ability") or None,
        "materials": mats,
        "output": {"name": items.get(om.group(1), om.group(1)), "qty": int(om.group(2)),
                   "wow": wow.get(om.group(1))} if om else None})
    nrec += 1

data = [profs[p] for p in orden]
for p in data:
    # skillReq 0 = Wowhead no declara requisito; esas van al final, no encabezando la lista
    p["recipes"].sort(key=lambda r: (1 if not r["skillReq"] else 0, r["skillReq"] or 0, r["name"]))

# ---- terminologia canonica (prof_terminologia.json): herramienta oficial + variantes ----
TERM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "prof_terminologia.json")
if os.path.exists(TERM):
    term = json.load(io.open(TERM, encoding="utf-8"))
    canon = term.get("tools", {})
    pkey = term.get("profession_tool_key", {})
    # regla general: toda herramienta es "Útiles de ..."
    for p in data:
        k = pkey.get(p["id"])
        if k and canon.get(k):
            p["tool"] = canon[k]; p["toolKey"] = k
    # instrumentos y juegos DIFERENCIADOS: cada uno es una competencia y una entrada propia
    import unicodedata
    def slug(s):
        s = "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
        return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")
    nuevos = []
    icon_i = term.get("instrument_icons", {})
    icon_g = term.get("game_icons", {})
    icon_v = term.get("vehicle_icons", {})
    # el id puede venir con prefijo (`prof_instrumento`) o sin el: compararlo pelado evita
    # que un renombrado deje de expandirlos y los publique como dos entradas genericas
    def _pelado(pid):
        return pid[5:] if pid.startswith("prof_") else pid
    for p in data:
        if _pelado(p["id"]) == "instrumento":
            for n in term.get("instruments", {}).values():
                nuevos.append({"id": "instrumento_" + slug(n), "name": n, "kind": "utility",
                               "ability": p["ability"], "tool": n, "family": "Instrumento musical",
                               "icon": icon_i.get(n, p["icon"]), "recipes": []})
        elif _pelado(p["id"]) == "juego":
            for n in term.get("games", {}).values():
                nuevos.append({"id": "juego_" + slug(n), "name": n, "kind": "utility",
                               "ability": p["ability"], "tool": n, "family": "Juego de azar",
                               "icon": icon_g.get(n, p["icon"]), "recipes": []})
        else:
            nuevos.append(p)
    # Vehículos: competencia y también profesión (terrestres/acuáticos)
    for n in term.get("vehicles", {}).values():
        nuevos.append({"id": "vehiculo_" + slug(n), "name": n, "kind": "utility",
                       "ability": None, "tool": n, "family": "Vehículos",
                       "icon": icon_v.get(n, ""), "recipes": []})
    data = nuevos

# Las profesiones que existen en WoW. Las artesanias de D&D (carpinteria, alfareria...) son
# competencias de herramienta, no oficios del juego, y por ahora no entran en Profesiones.
WOW = {"herreria", "alquimia", "herboristeria", "mineria", "peleteria", "desollar",
       "sastreria", "encantamiento", "ingenieria", "joyeria", "inscripcion", "cocina",
       "pesca", "primeros_auxilios"}
for p in data:
    p["wow"] = p["id"] in WOW

# nombres de profesion con su tilde (el addon los guarda en ASCII plano)
ACENTOS = {"Herreria": "Herrería", "Herboristeria": "Herboristería", "Mineria": "Minería",
           "Peleteria": "Peletería", "Sastreria": "Sastrería", "Ingenieria": "Ingeniería",
           "Joyeria": "Joyería", "Inscripcion": "Inscripción", "Carpinteria": "Carpintería",
           "Cartografia": "Cartografía", "Zapateria": "Zapatería", "Albanileria": "Albañilería",
           "Alfareria": "Alfarería", "Cerveceria": "Cervecería", "Falsificacion": "Falsificación",
           "Navegacion": "Navegación", "Herramientas de ladron": "Útiles de ladrón",
           "Kit de disfraz": "Útiles de disfraz"}
for p in data:
    p["name"] = ACENTOS.get(p["name"], p["name"])

# iconos del addon sin PNG en el dump de EpsilonIcons: sustituto visual equivalente (solo web)
SUSTITUTOS = {
    "inv_ingot_copper": "inv_ingot_02",
    "inv_ore_iron": "inv_ore_iron_01",
    "inv_misc_food_101": "inv_misc_food_101_sourcheese",
    "inv_inscription_pigment_01": "inv_inscription_pigment_azure",
    "inv_inscription_pigment_04": "inv_inscription_80_crimsonpigment",
    "inv_inscription_pigment_07": "inv_inscription_80_viridescentpigment",
    "inv_misc_dye_01": "inv_inscription_warpaint_blue",
    "inv_misc_pot_01": "inv_scarab_clay",
    "inv_misc_wood_01": "dos2_lumber",
}

def resolver(ic):
    fn = ic.split("\\")[-1].split("/")[-1].lower()
    return SUSTITUTOS.get(fn, fn)

for p in data:
    p["icon"] = resolver(p["icon"]) if p.get("icon") else p.get("icon")
    for r in p["recipes"]:
        if r.get("icon"): r["icon"] = resolver(r["icon"])

# ---- iconos: copiar los PNG usados a assets/compendium-icons/ ----
dest = os.path.join(WEB, "assets", "compendium-icons")
copiados = faltan = 0
usados = {p["icon"] for p in data} | {r["icon"] for p in data for r in p["recipes"]}
for ic in sorted(x for x in usados if x):
    fn = ic + ".png"
    srcp = os.path.join(PNG, fn)
    if os.path.exists(srcp):
        shutil.copyfile(srcp, os.path.join(dest, fn)); copiados += 1
    else:
        faltan += 1; print("  sin PNG:", ic)

# Lo que el lector ve: el addon guarda la caracteristica sin tilde y una profesion en
# Mayusculas De Titulo. Se corrige solo al publicar, como con los nombres de clase.
_DISPLAY = {"Sabiduria": "Sabiduría", "Primeros Auxilios": "Primeros auxilios"}
from nombres_display import titulo as _titulo, casa as _casa
for _p in data:
    for _k in ("ability", "name", "tool"):
        if isinstance(_p.get(_k), str): _p[_k] = _DISPLAY.get(_p[_k], _p[_k])
    # recetas, materiales y resultados: mismo acentuado que el resto de nombres. En la web
    # son solo texto; el emparejado con el inventario ocurre en el addon, que no se toca.
    for _r in (_p.get("recipes") or []):
        _r["name"] = _titulo(_r["name"])
        if isinstance(_r.get("output"), dict) and _r["output"].get("name"):
            _r["output"]["name"] = _titulo(_r["output"]["name"])
        for _m in (_r.get("materials") or []):
            if isinstance(_m, dict) and _m.get("name"): _m["name"] = _titulo(_m["name"])

# ---- lo que es la profesion en si (wowhead_profesion_info.py) ----
# Rangos, especializaciones y habilidades que no son recetas. Sin esto no se entiende el
# arbol: Inscripcion no tiene ninguna receta por debajo de 15 y se sube con Moler.
INFO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cotejo", "profesion_info.json")
if os.path.exists(INFO):
    _info = json.load(io.open(INFO, encoding="utf-8"))
    for _p in data:
        _i = _info.get(_p["id"])
        if not _i:
            continue
        _p["desc"] = _i.get("desc") or None
        _p["ranks"] = _i.get("ranks") or []
        _p["specializations"] = _i.get("specializations") or []
        _p["abilities"] = _i.get("abilities") or []
        # A que rango pertenece cada receta: se cruza su habilidad con los topes del oficio
        # (Aprendiz 75, Oficial 150, Experto 225, Artesano 300). No hay que pedirlo a nadie,
        # sale de dos datos que ya estan.
        _topes = [(r.get("max") or 0, r.get("rank")) for r in _p["ranks"] if r.get("max")]
        for _r in (_p.get("recipes") or []):
            _s = _r.get("skillReq") or 0
            # sin requisito declarado no hay rango que asignar: darle "Aprendiz" ponia la
            # espada de torio junto a los brazales de cobre
            _r["rank"] = (next((n for mx, n in _topes if _s <= mx),
                               _topes[-1][1] if _topes else None) if _s else None)
        for _l in (_p["specializations"] + _p["abilities"]):
            if _l.get("icon"): _l["icon"] = resolver(_l["icon"])
    for _ic in sorted({_l["icon"] for _p in data
                       for _l in (_p.get("specializations") or []) + (_p.get("abilities") or [])
                       if _l.get("icon")}):
        _fn = _ic + ".png"
        if os.path.exists(os.path.join(dest, _fn)):
            continue
        if os.path.exists(os.path.join(PNG, _fn)):
            shutil.copyfile(os.path.join(PNG, _fn), os.path.join(dest, _fn)); copiados += 1
        else:
            faltan += 1; print("  habilidad sin PNG:", _ic)

# ---- descripcion de lo que no esta en Wowhead ----
# Las once profesiones de WoW traen la suya del volcado; el resto -- oficios de artesano,
# instrumentos, juegos y vehiculos -- no la tiene nadie: ni el Libro 1, ni el 2, ni el
# Manual del Jugador los describen en espanol. Son texto de la casa y viven en
# prof_terminologia.json, que NO se regenera, y no en cotejo/, que si.
_DESCS = term.get("descs") or {}
_ndesc = 0
for _p in data:
    if not _p.get("desc") and _DESCS.get(_p["id"]):
        _p["desc"] = _DESCS[_p["id"]]
        _ndesc += 1
print("Descripciones propias puestas: %d" % _ndesc)


# ---- ficha de cada objeto (wowhead_objetos.py): un solo diccionario compartido ----
# Colgar la ficha de cada receta duplicaria el mismo objeto decenas de veces (la Barra de
# cobre aparece en medio Herreria). Se emite una sola vez y las recetas la referencian por
# su itemId, que es lo que ya llevan materiales y resultado.
OBJ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cotejo", "objetos_wowhead.json")
fichas, usados_obj = {}, set()
for _p in data:
    for _r in (_p.get("recipes") or []):
        for _o in (_r.get("materials") or []) + ([_r["output"]] if _r.get("output") else []):
            if _o.get("wow"): usados_obj.add(str(_o["wow"]))
if os.path.exists(OBJ):
    crudo = json.load(io.open(OBJ, encoding="utf-8"))
    for _k in usados_obj:
        f = crudo.get(_k)
        if not f: continue
        # `lines` es el tooltip entero sin trocear: la ficha ya trae esos datos en campos
        f = {k: v for k, v in f.items() if k != "lines"}
        # el nombre de Classic solo interesa cuando difiere del actual; repetirlo en
        # 1.100 objetos engordaba el fichero sin decir nada
        if f.get("classicName") == f.get("name"): f.pop("classicName", None)
        for _k2 in ("name", "type", "slot", "set"):
            if isinstance(f.get(_k2), str): f[_k2] = _titulo(f[_k2])
        # la misma terminologia que el registro del addon, o el material se llamaria de dos
        # maneras segun se mire la lista o su ficha
        for _k2 in ("name", "classicName"):
            if isinstance(f.get(_k2), str): f[_k2] = _casa(f[_k2])
        if f.get("classicName") == f.get("name"): f.pop("classicName", None)
        if f.get("icon"): f["icon"] = resolver(f["icon"])
        fichas[_k] = f

# los PNG de los objetos van aparte: sus fichas se arman despues del copiado de arriba
for _ic in sorted({f["icon"] for f in fichas.values() if f.get("icon")}):
    _fn = _ic + ".png"
    if os.path.exists(os.path.join(dest, _fn)):
        continue
    if os.path.exists(os.path.join(PNG, _fn)):
        shutil.copyfile(os.path.join(PNG, _fn), os.path.join(dest, _fn)); copiados += 1
    else:
        faltan += 1; print("  objeto sin PNG:", _ic)

payload = ("window.HARFORD_COMPENDIUM = window.HARFORD_COMPENDIUM || {};\n"
           "window.HARFORD_COMPENDIUM.professions = " + json.dumps(data, ensure_ascii=False, indent=1) + ";\n"
           "window.HARFORD_COMPENDIUM.professionItems = " + json.dumps(fichas, ensure_ascii=False, indent=1) + ";\n")
io.open(os.path.join(WEB, "js", "compendium-professions.js"), "w", encoding="utf-8").write(payload)
print("Profesiones: %d | recetas: %d | fichas de objeto: %d | iconos copiados: %d | sin PNG: %d"
      % (len(data), nrec, len(fichas), copiados, faltan))
