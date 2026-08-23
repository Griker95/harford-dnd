# -*- coding: utf-8 -*-
# Genera js/compendium-dotes.js: las dotes del addon (HarfordDnDFeats), mismo formato que trasfondos.
import io, re, os, json, sys, glob
sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
from metrico import a_metrico
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terminologia import normalizar_habilidades  # el Manual del Jugador viene en pies y libras
BASE = r"C:/Users/marco/Documents/New project"
WEB = r"C:/Users/marco/Documents/harfordweb"
F = glob.glob(os.path.join(BASE, "Harford", "**", "HarfordDnDFeats.lua"), recursive=True)[0]
t = io.open(F, encoding="utf-8", errors="replace").read()

def balanced(text, i):
    d = 0
    for j in range(i, len(text)):
        if text[j] == "{": d += 1
        elif text[j] == "}":
            d -= 1
            if d == 0: return j + 1
    return len(text)

def parse_traits(region):
    out = []
    for m in re.finditer(r'\{\s*id = "([a-z0-9_]+)"', region):
        blk = region[m.start():balanced(region, m.start())]
        nm = re.search(r'\bname = "((?:[^"\\]|\\.)*)"', blk)
        ty = re.search(r'\btype = "([a-z]+)"', blk)
        de = re.search(r'\bdescription = "((?:[^"\\]|\\.)*)"', blk)
        if not (nm and ty and de): continue
        lv = re.search(r'\blevel = (\d+)', blk)
        feat = {"id": m.group(1), "level": int(lv.group(1)) if lv else None,
                "name": nm.group(1).replace('\\"', '"'), "type": ty.group(1),
                "desc": de.group(1).replace('\\"', '"')}
        om = re.search(r'options = \{', blk)
        if om:
            oreg = blk[om.end()-1:balanced(blk, om.end()-1)]
            opts = [{"id": o.group(1), "label": o.group(2).replace('\\"', '"')}
                    for o in re.finditer(r'\{\s*id = "([^"]+)",\s*label = "((?:[^"\\]|\\.)*)"', oreg)]
            if opts: feat["options"] = opts
        out.append(feat)
    return out

# cada dote: { id, name, requires?, traits = { ... } }
dotes = []
for m in re.finditer(r'\{\s*\n\s*id = "([a-z0-9_]+)", name = "((?:[^"\\]|\\.)*)"(?:, requires = "((?:[^"\\]|\\.)*)")?', t):
    start = m.start()
    blk = t[start:balanced(t, start)]
    tr = re.search(r'\btraits = \{', blk)
    traits = parse_traits(blk[tr.end()-1:balanced(blk, tr.end()-1)]) if tr else []
    requires = (m.group(3) or "").replace('\\"', '"').strip()
    desc = traits[0]["desc"] if traits else ""
    dotes.append({"id": m.group(1), "name": m.group(2).replace('\\"', '"'),
                  "requires": requires, "desc": desc, "traits": traits})

# ---- texto del manual para cada dote (en el libro son titulos de nivel 3) ----
import unicodedata
MDS = [r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md",
       r"C:/Users/marco/Documents/New project/RuleSource/Export/d_d_5_0_edge_manual_del_jugador/texto.md"]
def _nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"[^0-9a-z]+", " ", s.lower()).strip()
# El PDF mete a mitad de texto marcas de pagina y cabeceras muy danadas por el OCR
# ("CAPITULO,; , OPC..ION fS DL PfRSONAllZACION", "<!-- pag 172 -->"): esas lineas se
# BORRAN (cortar ahi perderia el resto de la dote). Solo cierra la entrada el titulo de
# la dote siguiente, que va en MAYUSCULAS en su propia linea.
_MAYUS = re.compile(r"^[A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ 0-9,'´()-]{3,44}$")

from limpieza import decimales, sin_cola_de_titulo, limpiar

def _es_ruido(linea):
    l = linea.strip()
    if not l: return False
    if l.startswith("<!--"): return True
    # sin tildes: la cabecera real dice "CAPÍTULO" y la comparacion con "CAPITUL" fallaba,
    # asi que el pie de pagina se colaba entero al final de la dote ("...habituales. Ibb")
    solo_letras = _nk(l).upper().replace(" ", "")
    return "CAPITUL" in solo_letras or "APITULO" in solo_letras

def _cortar_en_frontera(cuerpo):
    out = []
    for linea in cuerpo.split("\n"):
        if _es_ruido(linea): continue
        if _MAYUS.match(linea.strip()) and out and any(x.strip() for x in out):
            break                      # empieza la siguiente dote
        out.append(linea)
    # el numero de pagina suelto ("Ibb" = 165 mal leido) y el titulo de la dote siguiente
    # se quedan pegados al final del cuerpo
    return sin_cola_de_titulo("\n".join(out))

BOLD = re.compile(r"\*\*\*\s*([^*\n]+?)\.?\s*\*\*\*\s*(.*?)(?=\n\s*\*\*\*|\n#{1,6}\s|\Z)", re.S)
libro_txt = {}
for MD in MDS:
    if not os.path.exists(MD): continue
    _src = io.open(MD, encoding="utf-8").read().replace("\r", "")
    # (nivel, clave, fin del titulo, INICIO del titulo). Hace falta el inicio: cortando el
    # cuerpo por el FINAL del titulo siguiente, ese titulo se quedaba dentro del cuerpo
    # anterior ("...+10 al dano del conjuro.\n\nExperto en Armas de Fuego").
    # un titulo empieza por letra: el OCR marca como encabezado trozos de frase partidos
    # ("### - 5 a la tirada de ataque..."), y tomarlos por titulo cortaba la dote a medias
    _h = [(len(m.group(1)), _nk(m.group(2)), m.end(), m.start())
          for m in re.finditer(r"\n(#{1,6})\s*([^\n]+)", _src)
          if re.match(r"[*_ ]*[A-Za-zÁÉÍÓÚÑÜáéíóúñü]", m.group(2).strip())]
    for idx, (lvl, key, fin, _ini) in enumerate(_h):
        nxt = next((s for l2, k2, p, s in _h[idx+1:] if l2 <= lvl), None)
        cuerpo = _src[fin:(nxt if nxt else len(_src))]
        cuerpo = re.sub(r"\n#{1,6}\s*", "\n", cuerpo)
        cuerpo = _cortar_en_frontera(cuerpo)
        cuerpo = re.sub(r"\n{3,}", "\n\n", cuerpo).strip()
        if cuerpo and key not in libro_txt: libro_txt[key] = cuerpo
    # varias dotes del Manual del Jugador no son titulo, sino '***Nombre.*** texto'
    for m in BOLD.finditer(_src):
        k, c = _nk(m.group(1)), m.group(2).strip()
        # tambien aqui: el nombre de la dote siguiente viene pegado detras del cuerpo
        # este camino tambien recoge pies de pagina, asi que pasa por el mismo filtro
        c = sin_cola_de_titulo(_cortar_en_frontera(c))
        if k and c and k not in libro_txt: libro_txt[k] = c
# Muchos rasgos de clase se llaman igual que una dote ("Acechador" es dote del Manual del
# Jugador y rasgo de Cazador de nivel 14). Como el indice se arma por titulo, esos rasgos
# entraban y podian sobrescribir la dote si su texto era mas largo. Una dote nunca se gana
# a un nivel, asi que ese arranque delata al rasgo.
_ES_RASGO_DE_CLASE = re.compile(
    r"^\s*\*{0,3}\s*(?:A partir del|Al alcanzar el|Al)\s+\d+\.?[ºo]?\s*nivel"
    r"|^\s*\*Caracter[ií]stica de .{0,60}nivel\*", re.I)
for _k in [k for k, v in libro_txt.items() if _ES_RASGO_DE_CLASE.match(v)]:
    del libro_txt[_k]

# el OCR confunde l y 1 en los dados ("ld20" -> "1d20", "2dl0" -> "2d10")
def _fix_dados(s):
    s = re.sub(r"\bl\s?d(\d)", r"1d\1", s)
    return re.sub(r"\b(\d)\s?dl(\d)?\b", lambda m: m.group(1) + "d1" + (m.group(2) or ""), s)
for _k in list(libro_txt): libro_txt[_k] = _fix_dados(libro_txt[_k])

# dotes del Caldero de Tasha: titulos en imagen, cuerpos curados a mano en Export/
TASHA = r"C:/Users/marco/Documents/New project/RuleSource/Export/dotes_tasha.json"
if os.path.exists(TASHA):
    for k, v in json.load(io.open(TASHA, encoding="utf-8")).items():
        libro_txt.setdefault(_nk(k), v["texto"])
# el OCR del Manual del Jugador lee OBSERVADOR como UBSERVADOR
if "ubservador" in libro_txt: libro_txt.setdefault("observador", libro_txt["ubservador"])
enr = 0
for d in dotes:
    t = libro_txt.get(_nk(d["name"]))
    if t and len(t) > len(d.get("desc", "")):
        d["desc"] = t; enr += 1
        # El texto del manual se queda en la DOTE y no se copia a su primer rasgo. Copiarlo
        # hacia que 68 de las 77 tuvieran un primer rasgo que decia llamarse "Trucos de Mago"
        # y contenia la dote entera -- requisito y todas las vinetas -- mientras el segundo y
        # el tercero si traian su texto propio del addon, que es correcto y especifico.
        # No se pierde nada: comprobado que en las 77 ese texto no aporta ni una palabra que
        # no este ya en `desc` o en los demas rasgos.
print("dotes con texto del manual:", enr, "de", len(dotes))
# El rasgo "Incremento de caracteristica" sale 35 veces y es siempre lo mismo, asi que no
# es una eleccion de icono: se le pone el mismo signo verde que llevan los incrementos de
# raza. A diferencia de las razas, aqui casi todos ofrecen ELEGIR entre dos ("Destreza o
# Inteligencia +1"), asi que no hay un color de caracteristica que lo represente -- solo 9
# de los 35 nombran una sola -- y va el generico, que es lo que ya se hace en ese caso.
SIGNO_MEJORA = "hd_plussign_hunter"
_ninc = 0
for _d in dotes:
    for _t in _d.get("traits") or []:
        if not _t.get("icon") and "incremento de caracteristica" in _nk(_t.get("name", "")):
            _t["icon"] = SIGNO_MEJORA
            _ninc += 1
print("incrementos de caracteristica con signo: %d" % _ninc)

# ---- iconos elegidos a mano, del catalogo del addon ----
# Las dotes no tienen icono propio en HarfordDnDFeats.lua y hasta ahora tampoco miraban el
# catalogo, asi que la pestana entera salia sin un solo dibujo. Se lee de la misma tabla
# que usan clases, razas y trasfondos: un unico sitio donde poner los iconos.
# El valor admite MAYUSCULAS y espacios: 1.991 ficheros del volcado llevan mayusculas
# ("WH_DeadlyDetermination") y 165 llevan espacios en el nombre.
_CAT = glob.glob(os.path.join(BASE, "Harford", "**", "HarfordIconCatalog.lua"), recursive=True)
_iconos_cat = {}
if _CAT:
    _txt = io.open(_CAT[0], encoding="utf-8", errors="replace").read()
    _m = re.search(r"Catalog\.features\s*=\s*\{(.*?)" + chr(10) + r"\}", _txt, re.S)
    if _m:
        for _e in re.finditer(
                r'(?:\["([A-Za-z0-9_]+)"\]|([A-Za-z0-9_]+))\s*=\s*"([A-Za-z0-9_ ]+)"',
                _m.group(1)):
            _iconos_cat[(_e.group(1) or _e.group(2))] = _e.group(3)
_ncat = 0
for _d in dotes:
    if not _d.get("icon") and _iconos_cat.get(_d["id"]):
        _d["icon"] = _iconos_cat[_d["id"]]
        _ncat += 1
    for _t in _d.get("traits") or []:
        if not _t.get("icon") and _iconos_cat.get(_t["id"]):
            _t["icon"] = _iconos_cat[_t["id"]]
            _ncat += 1
print("iconos de dote leidos del catalogo: %d" % _ncat)

# El mismo pergamino que en el kb para las etiquetas genericas de competencia: es un rotulo
# repetido, no un rasgo distinto cada vez. Las que nombran algo concreto ya traen su icono
# del catalogo y no se tocan.
ICONO_COMPETENCIA = "inv_scroll_11"
# Por PREFIJO y pisando lo que hubiera: tambien las que nombran algo concreto
# ("Competencia con armas de fuego") llevan el pergamino.
_ncomp = 0
for _d in dotes:
    for _t in _d.get("traits") or []:
        if _nk(_t.get("name", "")).startswith("competencia"):
            _t["icon"] = ICONO_COMPETENCIA
            _ncomp += 1
print("etiquetas de competencia con pergamino: %d" % _ncomp)


dotes = json.loads(normalizar_habilidades(a_metrico(json.dumps(dotes, ensure_ascii=False))))
dotes = json.loads(decimales(json.dumps(dotes, ensure_ascii=False)))
# los nombres visibles llevan tilde aunque el addon los guarde sin ella (los empareja
# como cadena al elegir dote), igual que clases, conjuros y recetas
from nombres_display import titulo as _titulo
for _d in dotes:
    if isinstance(_d.get("name"), str): _d["name"] = _titulo(_d["name"])
    for _f in (_d.get("features") or _d.get("traits") or []):
        if isinstance(_f, dict) and isinstance(_f.get("name"), str):
            _f["name"] = _titulo(_f["name"])
# la limpieza de OCR se aplica campo a campo, no sobre el JSON entero: trabaja por
# parrafos y en el JSON los saltos van escapados
# La ficha ya muestra el requisito en su propia linea, asi que repetirlo al principio del
# texto ("*Requisito: Goblin*") solo lo dice dos veces seguidas.
_REQ_REPETIDO = re.compile(r"^\s*[*_]{0,2}\s*Requisitos?\s*:.*?[*_]{0,2}\s*(?:\n+|$)", re.I)
_nreq = 0
for _d in dotes:
    if _d.get("requires") and _d.get("desc"):
        _sin, _k = _REQ_REPETIDO.subn("", _d["desc"], count=1)
        if _k:
            _d["desc"] = _sin.lstrip()
            _nreq += 1
print("dotes que repetian el requisito en el texto: %d" % _nreq)

for _d in dotes:
    if _d.get("desc"): _d["desc"] = limpiar(_d["desc"])
    for _tr in _d.get("traits", []):
        if _tr.get("desc"): _tr["desc"] = limpiar(_tr["desc"])

payload = "window.HARFORD_COMPENDIUM = window.HARFORD_COMPENDIUM || {};\nwindow.HARFORD_COMPENDIUM.dotes = " + \
          json.dumps(dotes, ensure_ascii=False, indent=1) + ";\n"
io.open(os.path.join(WEB, "js", "compendium-dotes.js"), "w", encoding="utf-8").write(payload)
print("Dotes: %d (%d con requisito, %d rasgos totales)" % (
    len(dotes), sum(1 for d in dotes if d["requires"]), sum(len(d["traits"]) for d in dotes)))
print("ejemplo:", dotes[0]["name"], "| req:", dotes[0]["requires"][:40], "| rasgos:", len(dotes[0]["traits"]))
