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

# ---- SEGURO DE VUELCO ----
# Si una coleccion se desploma respecto a lo ya publicado, casi seguro que el extractor ha
# dejado de entender su fuente, no que el contenido haya desaparecido de verdad. Sin este
# seguro se publica el hueco en silencio: hoy el libro de clases se partio en modulos por
# clase y el extractor paso de 12 clases a 0 sin una sola queja.
# Se salta con --forzar cuando el recorte es de verdad intencionado.
def _cuenta(d):
    return {k: len(v) for k, v in (d or {}).items() if isinstance(v, list)}

_ANTES = os.path.join(WEB, "js", "compendium-data.js")
if os.path.exists(_ANTES) and "--forzar" not in sys.argv:
    _t = io.open(_ANTES, encoding="utf-8").read()
    _m = re.search(r"=\s*(\{[\s\S]*\})", _t)
    if _m:
        _viejo, _nuevo = _cuenta(json.loads(_m.group(1))), _cuenta(kb)
        _caidas = [(k, _viejo[k], _nuevo.get(k, 0)) for k in _viejo
                   if _viejo[k] >= 5 and _nuevo.get(k, 0) < _viejo[k] * 0.8]
        if _caidas:
            print("ABORTADO: hay colecciones que se desploman frente a lo publicado.")
            for _k, _a, _b in _caidas:
                print("   %-14s publicado %5d -> ahora %5d" % (_k, _a, _b))
            print("Si el recorte es intencionado, repite con --forzar.")
            sys.exit(1)
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

# Resumen de tarjeta. La descripcion del manual abre con una cita de ambientacion y la
# tarjeta la cortaba a media palabra, asi que no presentaba nada. Los textos estan en
# resumenes.json, escritos a mano; la ficha completa sigue mostrando el manual entero.
_res = json.load(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                      "resumenes.json"), encoding="utf-8"))
# Subclases: van por CLASE y por NOMBRE, no por id. Los ids de subclase se repiten entre
# clases (`sagrado` en Sacerdote y Paladin, `escarcha` en Mago y Caballero de la Muerte) y
# una tabla plana los cruzaria; el nombre si es unico dentro de su clase.
_sc = _res.get("subclases") or {}
_psc = 0
for _c in kb.get("classes", []):
    _porclase = _sc.get(_c["id"]) or {}
    for _s in _c.get("subclasses", []) or []:
        _t = _porclase.get(_s["name"])
        if _t:
            _s["summary"] = _t
            _psc += 1
if _sc:
    _faltan = [c["id"] + " > " + s["name"] for c in kb.get("classes", [])
               for s in c.get("subclasses", []) or [] if not s.get("summary")]
    print("Resumenes de subclases: %d puestos%s" % (
        _psc, (" | sin resumen: %s" % ", ".join(_faltan)) if _faltan else ""))

# las subrazas se ven plegadas, solo con su nombre: el resumen es la unica pista de que
# hay dentro sin abrirlas una por una
_subs = _res.get("subrazas") or {}
_ps = 0
for _r in kb.get("races", []):
    for _s in _r.get("subraces", []) or []:
        _t = _subs.get(_s["id"]) or _subs.get("raza_" + _s["id"])
        # `=raza`: la subraza BASE -la que no cambia nada respecto a su pueblo- muestra el
        # resumen de la raza. Se guarda el marcador y no una copia para que no se separen.
        if _t == "=raza":
            _t = _r.get("summary") or (_res.get("razas") or {}).get(_r["id"])
        if _t:
            _s["summary"] = _t
            _ps += 1
if _subs:
    print("Resumenes de subrazas: %d puestos de %d escritos" % (_ps, len(_subs)))

for _grupo, _clave in (("clases", "classes"), ("razas", "races")):
    _textos = _res.get(_grupo) or {}
    _puestos = 0
    for _o in kb.get(_clave, []):
        # se acepta el id con prefijo y sin el: los de raza lo llevan (raza_humano) y los
        # de clase no, y asi un renombrado futuro no se lleva por delante los resumenes
        _r = (_textos.get(_o["id"])
              or _textos.get("raza_" + _o["id"])
              or _textos.get(_o["id"].replace("raza_", "", 1)))
        if _r:
            _o["summary"] = _r
            _puestos += 1
    if _textos:
        _faltan = [o["id"] for o in kb.get(_clave, [])
                   if not (o.get("summary") or "").strip()]
        print("Resumenes de %s: %d puestos%s" % (
            _grupo, _puestos, (" | sin resumen: %s" % ", ".join(_faltan)) if _faltan else ""))

# ---- CORRECCIONES SOBRE EL DATO DEL ADDON ----
# Parches para lo que el addon todavia no puede expresar. Cada uno se anuncia al aplicarlo:
# si el addon se arregla y el parche sigue aqui, estaria pisando el dato bueno.
_corr = json.load(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                       "correcciones_web.json"), encoding="utf-8"))
for _bid, _c in (_corr.get("trasfondos") or {}).items():
    _b = next((x for x in kb.get("backgrounds", []) if x["id"] == _bid), None)
    if not _b:
        print("CORRECCION SIN APLICAR: no existe el trasfondo %s" % _bid)
        continue
    _porid = {t["id"]: t for t in _b.get("traits", [])}
    # los rasgos que en realidad son de la variante se MUEVEN, no se duplican
    for _vid, _v in (_c.get("variantes") or {}).items():
        _var = next((x for x in _b.get("variants", []) if x["id"] == _vid), None)
        if not _var:
            print("CORRECCION SIN APLICAR: no existe la variante %s" % _vid)
            continue
        _var["traits"] = [_porid[i] for i in _v.get("mover_rasgos", []) if i in _porid]
    _quedan = {i: _porid[i] for i in _c.get("conservar_rasgos", []) if i in _porid}
    for _n in _c.get("rasgos_nuevos", []):
        _quedan[_n["id"]] = _n
    _b["traits"] = [_quedan[i] for i in _c.get("orden", []) if i in _quedan]
    if _c.get("skills"):
        _b["skills"] = _c["skills"]
    if _c.get("tools"):
        _b["tools"] = _c["tools"]
    print("CORRECCION APLICADA a %s: %d rasgos en el base, %d movidos a la variante. "
          "RETIRAR de correcciones_web.json cuando el addon lo arregle."
          % (_bid, len(_b["traits"]),
             sum(len(v.get("mover_rasgos", [])) for v in (_c.get("variantes") or {}).values())))

# ---- SEGURO DE VUELCO, NIVELES ANIDADOS ----
# El seguro de arriba solo mira las colecciones de primer nivel, y ahi no se ve el fallo
# tipico: 17 razas siguen siendo 17 aunque se hayan quedado sin una sola subraza. Los tres
# desplomes de hoy -subrazas, dotes, iconos- eran todos de nivel anidado.
def _anidados(kbx):
    c = {"subclasses": 0, "subraces": 0, "variants": 0, "features": 0, "traits": 0}
    for _n in ("classes", "races", "backgrounds"):
        for _o in kbx.get(_n, []):
            for _k in c:
                c[_k] += len(_o.get(_k) or [])
                for _h in ("subclasses", "subraces", "variants"):
                    for _s in _o.get(_h) or []:
                        c[_k] += len(_s.get(_k) or []) if _k in ("features", "traits") else 0
    return c

try:
    _pub = io.open(os.path.join(WEB, "js", "compendium-data.js"), encoding="utf-8").read()
    _antes = _anidados(json.loads(_pub[_pub.index("{"):_pub.rindex("}") + 1]))
    _ahora = _anidados(kb)
    _caidas = ["%s %d -> %d" % (k, _antes[k], _ahora[k])
               for k in _antes if _antes[k] and _ahora[k] < _antes[k] * 0.8]
    if _caidas:
        raise SystemExit("ABORTADO: se desploma un nivel anidado (%s). Suele ser que el "
                         "extractor dejo de reconocer la cabecera por un campo nuevo en "
                         "medio; revisa antes de publicar." % "; ".join(_caidas))
except SystemExit:
    raise
except Exception:
    pass

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
