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

# 1ter) el ARTE de los trasfondos y de sus variantes. Los originales del export son PNG de
# 1536x1024 y de 1,5 a 3,8 MB -- 120 MB en total -- que no se pueden servir tal cual. Se
# convierten a WebP del ancho al que se ven de verdad en la ficha. Va ANTES de escribir el
# JS porque reescribe el campo `art` del kb con el nombre ya servible.
ART_SRC = r"C:/Users/marco/Documents/New project/RuleSource/Discord_Export"
ART_DST = os.path.join(WEB, "assets", "compendium-art")
ART_ANCHO, ART_CALIDAD = 1024, 80


def _con_arte(obj, salida=None):
    """Cada objeto del kb que declare `art`, para poder reescribirle la ruta."""
    salida = [] if salida is None else salida
    if isinstance(obj, dict):
        if obj.get("art"):
            salida.append(obj)
        for v in obj.values():
            if not isinstance(v, str):
                _con_arte(v, salida)
    elif isinstance(obj, list):
        for v in obj:
            _con_arte(v, salida)
    return salida


_art = _con_arte(kb)
if _art:
    from PIL import Image
    os.makedirs(ART_DST, exist_ok=True)
    _hechos, _fallos = 0, []
    for _o in _art:
        _src = os.path.join(ART_SRC, _o["art"])
        _nombre = (_o.get("id") or os.path.basename(_o["art"])) + ".webp"
        if not os.path.exists(_src):
            _fallos.append(_o["art"]); _o.pop("art", None); continue
        _dst = os.path.join(ART_DST, _nombre)
        # solo se reconvierte si falta o si el original es mas nuevo: son 49 imagenes
        # grandes y rehacerlas en cada despliegue son varios segundos de nada
        if not os.path.exists(_dst) or os.path.getmtime(_src) > os.path.getmtime(_dst):
            _im = Image.open(_src).convert("RGB")
            if _im.width > ART_ANCHO:
                _im = _im.resize((ART_ANCHO, round(_im.height * ART_ANCHO / _im.width)),
                                 Image.LANCZOS)
            _im.save(_dst, "WEBP", quality=ART_CALIDAD, method=6)
        _o["art"] = _nombre
        _hechos += 1
    _peso = sum(os.path.getsize(os.path.join(ART_DST, f)) for f in os.listdir(ART_DST))
    print("arte de trasfondos: %d imagenes | %.1f MB en total%s"
          % (_hechos, _peso / 1e6, (" | sin origen: %d" % len(_fallos)) if _fallos else ""))

io.open(os.path.join(WEB, "js", "compendium-data.js"), "w", encoding="utf-8").write(
    "window.HARFORD_COMPENDIUM = " + json.dumps(kb, ensure_ascii=False, indent=1) + ";\n")

# 1bis) los idiomas: no salen del addon, su fuente es idiomas.json, la lista canonica que
# tambien publica reglas.html en su seccion 12.
_idi = json.load(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                      "idiomas.json"), encoding="utf-8"))["catalogo"]
_lista = []
for _cat, _etiqueta in (("basicos", "Básico"), ("exoticos", "Exótico")):
    for _x in _idi.get(_cat, []):
        _lista.append({
            "id": _x["id"], "name": _x["nombre"], "category": _etiqueta,
            "speakers": _x.get("hablantes") or "", "script": _x.get("escritura") or "",
            # el mismo dibujo que el rasgo de idiomas de razas y trasfondos
            "icon": "inv_misc_note_05",
        })
io.open(os.path.join(WEB, "js", "compendium-languages.js"), "w", encoding="utf-8", newline="").write(
    "window.HARFORD_COMPENDIUM = window.HARFORD_COMPENDIUM || {};\n"
    "window.HARFORD_COMPENDIUM.idiomas = "
    + json.dumps(_lista, ensure_ascii=False, indent=1) + ";\n")
print("Idiomas: %d (%d basicos, %d exoticos)" % (
    len(_lista), len(_idi.get("basicos", [])), len(_idi.get("exoticos", []))))

# 2) recopilar iconos de todos los data files del web
names = set()
for fn in ("compendium-data.js", "compendium-equipment.js", "compendium-dotes.js",
           "compendium-languages.js"):
    p = os.path.join(WEB, "js", fn)
    if not os.path.exists(p): continue
    t = io.open(p, encoding="utf-8").read()
    for m in re.finditer(r'"icon[A-Za-z]*":\s*"([^"]+)"', t):
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
