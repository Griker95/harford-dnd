# -*- coding: utf-8 -*-
# Resuelve el icono de cada clase/subclase/raza/rasgo del kb (logica GetFeatureIcon del addon),
# embebe los PNG usados de EpsilonIcons como data-URI, y produce kb con iconos + mapa de iconos.
import re, io, os, json, base64, unicodedata

H = r"C:/Users/marco/Documents/New project/Harford"
EI = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
SP = os.path.dirname(os.path.abspath(__file__))

def rd(p): return io.open(p, encoding="utf-8", errors="replace").read()
def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
def nk(s): return re.sub(r"\s+", " ", sa(s).lower().replace("_", " ").replace("-", " ")).strip()

import glob
def find(name):
    hits = glob.glob(os.path.join(H, "**", name), recursive=True)  # addon reorganizado en subcarpetas
    return hits[0] if hits else os.path.join(H, name)
cat = rd(find("HarfordIconCatalog.lua"))
data = rd(find("HarfordDnDData.lua"))

# Catalog.spells: id-de-conjuro -> LISTA ordenada de candidatos de icono (fuente unica).
# El addon usa el primero que resuelve; el ultimo suele ser un Interface\Icons\... base garantizado.
SPELLICON = {}
_msp = re.search(r"Catalog\.spells\s*=\s*\{(.*?)\n\}", cat, re.S)
if _msp:
    for _mm in re.finditer(r"(\w+)\s*=\s*\{([^}]*)\}", _msp.group(1)):
        SPELLICON[_mm.group(1)] = [c.split("\\")[-1] for c in re.findall(r'"([^"]+)"', _mm.group(2))]

# Catalog.names (por nombre normalizado) y PRESENTATION/TRP3 (por nombre) -> icono
NAMES = {}
mnames = re.search(r"Catalog\.names\s*=\s*\{(.*?)\n\}", cat, re.S)
for m in re.finditer(r'\["([^"]+)"\]\s*=\s*"([^"]+)"', mnames.group(1)):
    NAMES[nk(m.group(1))] = m.group(2)
for block in re.findall(r"HarfordDnDData\.(?:PRESENTATION|TRP3_PRESENTATION)\s*=\s*\{(.*?)\n\}", data, re.S):
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*\{[^}]*?icon\s*=\s*"([^"]+)"', block):
        NAMES.setdefault(nk(m.group(1)), m.group(2).split("\\")[-1])

# Catalog.features (por id) -> icono
FEATS = {}
mfe = re.search(r"Catalog\.features\s*=\s*\{(.*?)\n\}", cat, re.S)
for m in re.finditer(r'(?:\["([a-z0-9_]+)"\]|([a-z0-9_]+))\s*=\s*"([a-z0-9_]+)"', mfe.group(1)):
    FEATS[m.group(1) or m.group(2)] = m.group(3)

# Catalog.subclasses[classid][subid] -> icono
SUBS = {}
msc = re.search(r"Catalog\.subclasses\s*=\s*\{(.*)\n\}\s*$", cat, re.S)
if msc:
    for cm in re.finditer(r'(?:\["?([a-z_]+)"?\])\s*=\s*\{([^}]*)\}', msc.group(1)):
        cid = cm.group(1); SUBS[cid] = {}
        for sm in re.finditer(r'\["?([a-z_]+)"?\]\s*=\s*"([a-z0-9_]+)"', cm.group(2)):
            SUBS[cid][sm.group(1)] = sm.group(2)

def icon_by_name(name):
    k = nk(name)
    if k in NAMES: return NAMES[k]
    base = re.sub(r"\s*\([^)]*\)\s*$", "", k)
    if base in NAMES: return NAMES[base]
    for mk in NAMES:
        if mk.startswith(k) and k: return NAMES[mk]
    return None

def feat_icon(f):
    return FEATS.get(f["id"]) or icon_by_name(f["name"])

CLASS_TOKEN = {"guerrero":"warrior","paladin":"paladin","cazador_demonios":"demonhunter","cazador":"hunter",
  "picaro":"rogue","sacerdote":"priest","caballero_muerte":"deathknight","chaman":"shaman","mago":"mage",
  "brujo":"warlock","monje":"monk","druida":"druid"}
RACE_ICON = {"humano":"achievement_character_human_male","elfo_noche":"achievement_character_nightelf_male",
  "elfo_sangre":"achievement_character_bloodelf_male","semielfo":"eps_wc3h_highelfrangermale",
  "huargen":"achievement_worganhead","pandaren":"w3reforgedpandarenbrewmaster","vulpera":"vulpera_m"}

# mapa fileID -> nombre de icono (para los conjuros, que traen icon numerico)
FDID = {}
try:
    for line in io.open(os.path.join(EI, "..", "icons_master.csv"), encoding="utf-8", errors="replace"):
        p = line.rstrip("\n").split(";")
        if len(p) >= 2 and p[0].isdigit(): FDID[p[0]] = p[1]
except Exception:
    pass
def spell_icon(ic):
    if ic is None: return None
    s = str(ic)
    if s.isdigit(): return FDID.get(s)
    return s.split("\\")[-1]  # ruta "Interface\\Icons\\nombre"

# iconos que el catalogo del addon nombra pero no existen en el dump de EpsilonIcons:
# se sustituyen por el mas cercano que si esta
SUSTITUTOS = {
    "ability_demonhunter_immolationaura": "eps_rumble_immolationaura",
    "ability_demonhunter_infernalimpact": "ability_demonhunter_infernalstrike1",
    "ability_demonhunter_markedfordeath": "ability_hunter_markedfordeath",
    "ability_monk_brewmaster": "achievement_faction_brewmaster",
    "ability_monk_stagger": "ability_monk_ascension",
    "ability_monk_wayofthecrane": "ability_monk_blackoutkick",
    "ability_monk_windwalker_spec": "ability_monk_blackoutstrike",
    "inv_axe_1h_steelwarrior": "inv_axe_01",
    "spell_holy_painsuppression": "spell_holy_powerinfusion",
}

kb = json.load(io.open(os.path.join(SP, "kb.json"), encoding="utf-8"))
used = set()
def use(ic):
    if not ic: return ic
    ic = SUSTITUTOS.get(str(ic).split("\\")[-1].lower(), ic)   # icono inexistente -> el mas cercano
    used.add(ic.split("\\")[-1].lower())
    return ic

for c in kb["classes"]:
    c["icon"] = use("classicon_" + CLASS_TOKEN.get(c["id"], "warrior"))
    for f in c["features"]: f["icon"] = use(feat_icon(f))
    for s in c["subclasses"]:
        s["icon"] = use((SUBS.get(c["id"], {}) or {}).get(s["id"]))
        for f in s["features"]: f["icon"] = use(feat_icon(f))
for r in kb["races"]:
    r["icon"] = use(RACE_ICON.get(r["id"]))
    for f in r["traits"]: f["icon"] = use(feat_icon(f))
    for sr in r.get("subraces", []):
        sr["icon"] = use(icon_by_name(sr["name"]))
        for f in sr["traits"]: f["icon"] = use(feat_icon(f))
for b in kb["backgrounds"]:
    for f in b["traits"]: f["icon"] = use(feat_icon(f))
SCHOOL_ICON = {
    "abjuracion": "spell_holy_powerwordbarrier", "adivinacion": "spell_holy_mindvision",
    "conjuracion": "spell_arcane_portalstormwind", "encantamiento": "spell_shadow_charm",
    "evocacion": "spell_fire_fireball02", "ilusion": "spell_arcane_arcane04",
    "nigromancia": "spell_shadow_deathcoil", "transmutacion": "spell_nature_polymorph"}
# los nombres del catalogo son alias; el archivo real puede llevar prefijo de fuente
# (eps_/hots_/eps_wc3_...) o un apostrofo final. Resolvemos al basename real del PNG.
_PNG = {f[:-4].lower(): f[:-4] for f in os.listdir(EI) if f.lower().endswith(".png")}
def resolve_png(name):
    if not name: return None
    name = SUSTITUTOS.get(str(name).lower(), name)
    n = name.replace("\\", "/").split("/")[-1].lower()
    for cand in (n, "eps_" + n, "hots_" + n, n + "'", "eps_" + n + "'"):
        if cand in _PNG: return _PNG[cand]
    suf = "_" + n
    for base in _PNG:                       # archivo con prefijo de fuente distinto
        if base.endswith(suf): return _PNG[base]
    return None
def has_png(name): return resolve_png(name) is not None
def school_icon_for(school):
    k = nk(school or "").replace(" ", "")
    if k in SCHOOL_ICON: return SCHOOL_ICON[k]
    for name, ic in SCHOOL_ICON.items():             # escuela malformada ("encantamientode2nivel")
        if name in k: return ic
    return None
# iconos por afinidad (mas especifico que la escuela) y por categoria funcional
AFFINITY_ICON = {
    "fuego":"spell_fire_fireball02", "escarcha":"spell_frost_frostbolt02", "relampago":"spell_nature_lightning",
    "arcano":"spell_arcane_blast", "sombra":"spell_shadow_shadowbolt", "vil":"spell_shadow_seedofdestruction",
    "psiquico":"spell_shadow_mindtwisting", "naturaleza":"spell_nature_naturetouchgrow", "sagrado":"spell_holy_holybolt",
    "veneno":"ability_creature_poison_06", "acido":"spell_nature_acid_01", "aire":"spell_nature_cyclone",
    "agua":"spell_frost_summonwaterelemental", "sangre":"spell_deathknight_bloodplague", "tierra":"spell_nature_earthquake",
    "elemental":"spell_nature_elementalshields", "bestia":"ability_hunter_beasttaming", "oscuridad":"spell_shadow_twilight",
    "demonio":"spell_shadow_summoninfernal", "no muerto":"spell_shadow_raisedead"}
CATEGORY_ICON = [  # orden = prioridad; solo categorias funcionales (no dano/combate/control)
    ("curacion","spell_holy_heal"), ("proteccion","spell_holy_powerwordshield"),
    ("invocacion","spell_shadow_summonvoidwalker"), ("teletransporte","spell_arcane_blink"),
    ("movimiento","ability_rogue_sprint"), ("deteccion","spell_holy_mindvision"),
    ("cambiaformas","ability_druid_catform")]
def better_spell_icon(s):
    cats = [nk(c) for c in s.get("categories", [])]
    for key, ic in CATEGORY_ICON:
        if key in cats: return ic
    aff = nk((s.get("affinity") or "").split(",")[0])
    if aff in AFFINITY_ICON: return AFFINITY_ICON[aff]
    return school_icon_for(s.get("school"))
# Hibrido: se usa el icono real del addon cuando es de fiar (resuelve a un icono de
# conjuro/habilidad real, no un placeholder compartido ni una eleccion absurda: caramelos,
# pesca, talentframe). Si no, se asigna por categoria funcional -> afinidad -> escuela.
import re as _re
from collections import Counter as _Counter
_raw_freq = _Counter(str(s.get("iconRaw")) for s in kb.get("spells", []) if s.get("iconRaw"))
def _good_exact(nm, raw):
    if not nm or not has_png(nm): return False
    if raw is not None and _raw_freq[str(raw)] > 3: return False   # fileID placeholder compartido
    if "unused" in nm: return False
    return bool(_re.match(r"(spell_|ability_)", nm))               # solo iconos de conjuro/habilidad reales
def _name_icon_strict(name):  # Catalog.names: nombre de conjuro -> icono (eps_bg3, etc.), exacto
    k = nk(name)
    if k in NAMES: return NAMES[k]
    base = re.sub(r"\s*\([^)]*\)\s*$", "", k)
    return NAMES.get(base)
for s in kb.get("spells", []):
    raw = s.pop("iconRaw", None)
    nm = next((c for c in SPELLICON.get(s["id"], []) if has_png(c)), None)  # 1) primer candidato que exista
    if not nm:
        nm = _name_icon_strict(s["name"])      # 2) catalogo por nombre
        if not (nm and has_png(nm)):
            ex = spell_icon(raw)
            nm = ex if _good_exact(ex, raw) else better_spell_icon(s)  # 3) fileID real / 4) afinidad
    if nm: s["icon"] = use(nm)

# profesiones: icono de la profesion y de cada receta (nombres WoW tipo Trade_BlackSmithing);
# si el PNG no existe en el dump, la receta cae al icono de su profesion y esta a uno generico.
for prof in kb.get("professions", []):
    picon = prof.get("icon")
    if not has_png(picon): picon = "trade_engineering"
    prof["icon"] = use(resolve_png(picon) or picon)
    for rec in prof.get("recipes", []):
        ricon = rec.get("icon")
        if not has_png(ricon): ricon = picon
        rec["icon"] = use(resolve_png(ricon) or ricon)

# embeber PNGs usados
icons = {}
miss = []
for name in sorted(used):
    p = os.path.join(EI, name + ".png")
    if os.path.exists(p):
        icons[name] = "data:image/png;base64," + base64.b64encode(io.open(p, "rb").read()).decode()
    else:
        miss.append(name)

json.dump(kb, io.open(os.path.join(SP, "kb_icons.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump(icons, io.open(os.path.join(SP, "icons_data.json"), "w", encoding="utf-8"), ensure_ascii=False)
print("iconos usados: %d | con PNG: %d | sin PNG: %d" % (len(used), len(icons), len(miss)))
print("tamano icons_data.json: %d KB" % (os.path.getsize(os.path.join(SP, "icons_data.json"))//1024))
if miss: print("faltan (muestra):", ", ".join(miss[:15]))
