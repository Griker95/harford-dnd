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
# el valor admite espacios: 165 iconos del volcado los llevan en el nombre del fichero
# ("trade_archaeology_carved wildhammer gryphon figurine") y sin esto eran inalcanzables
for m in re.finditer(r'(?:\["([a-z0-9_]+)"\]|([a-z0-9_]+))\s*=\s*"([A-Za-z0-9_ ]+)"', mfe.group(1)):
    FEATS[m.group(1) or m.group(2)] = m.group(3)
# rasgos sin entrada en el catalogo del addon: iconos elegidos a mano (iconos_rasgos.json)
_ir = os.path.join(SP, "iconos_rasgos.json")
if os.path.exists(_ir):
    for k, v in json.load(io.open(_ir, encoding="utf-8")).items():
        if not k.startswith("_"): FEATS.setdefault(k, v)

# Catalog.subclasses[classid][subid] -> icono
SUBS = {}
# Hasta el primer cierre de linea, no hasta el final del fichero: el catalogo dejo de
# terminar en esta tabla y desde entonces SUBS salia vacio sin que nada fallara, asi que
# las 37 subclases se publicaban sin icono.
# El icono de los conjuros de cada especializacion, del frame "Magia <X>" del TRP3.
SUBSPELL = {}
_mss = re.search(r"Catalog\.subclassSpells\s*=\s*\{(.*?)" + chr(10) + r"\}", cat, re.S)
if _mss:
    # la clave es clase/subclase: los ids de subclase se repiten entre clases y sin la
    # clase delante el Mago se llevaba el icono de escarcha del Caballero de la Muerte
    for _m in re.finditer(r'\["([a-z0-9_]+/[a-z0-9_]+)"\]\s*=\s*"([A-Za-z0-9_ ]+)"', _mss.group(1)):
        SUBSPELL[_m.group(1)] = _m.group(2)

msc = re.search(r"Catalog\.subclasses\s*=\s*\{(.*?)\n\}", cat, re.S)
if msc:
    # las claves van sin corchetes (`caballero_muerte = { sangre = "..." }`), asi que los
    # corchetes son opcionales: exigirlos dejaba SUBS vacio
    for cm in re.finditer(r'(?:\["?([a-z_]+)"?\]|([a-z_]+))\s*=\s*\{([^}]*)\}', msc.group(1)):
        cid = cm.group(1) or cm.group(2); SUBS[cid] = {}
        for sm in re.finditer(r'(?:\["?([a-z_]+)"?\]|([a-z_]+))\s*=\s*"([a-z0-9_]+)"', cm.group(3)):
            SUBS[cid][sm.group(1) or sm.group(2)] = sm.group(3)

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
# Iconos de trasfondo: son los que el jugador eligio en su propia ficha de TRP3, sacados
# de las SavedVariables. Los trasfondos no tenian ninguno y salian todos sin dibujo.
BG_ICON = {
  "acolito": "spell_holy_impholyconcentration",
  "anima_errante": "ability_warlock_soulswap",
  "animador": "achievement_halloween_smiley_01",
  "artesano_gremial": "eps_arc_sign_oribos_trade",
  "boticario_oscuro": "ui_darkshore_warfront_horde_alchemist",
  "buscador_sombrio": "dos2_shadow12",
  "capitan_veterano_harford": "inv_tabard_duelersguild",
  "cazarrecompensas_urbano": "inv_bountyhunting",
  "coneja_elemental": "inv_eng_gizmo3",
  "desertor_errante": "achievement_general_classicbattles",
  "devoto_elune": "eps_wow_eluneschosen",
  "eco_resurreccion": "d3_astralpresence",
  "el_loco": "spell_magic_polymorphrabbit",
  "erudito": "wh_focusedmind",
  "gladiador_goriano": "achievement_dungeon_ogreslagmines",
  "guardia_ciudad": "ability_warrior_vigilance",
  "guardian_salvaje": "ability_hunter_huntervswild",
  "huerfano": "eps_lol_profileicon_ezbereal",
  "mercenario_veterano_harford": "w3reforgedbandit",
  "noble": "w3reforgedgoldring",
  "rostro_olvidado": "ability_rogue_disguise",
  "senda_sangre_barro": "wh_burnawaylies",
  "veterano_campo_batalla": "inv_banner_03",
}
# Cada raza tiene dos iconos y dos nombres, uno por genero, para el interruptor
# Hombre/Mujer de la pestana Razas. El femenino se deja vacio hasta que se elija a mano:
# poner el masculino en los dos lados haria creer que el interruptor no funciona.
RACE_GENERO = {
  "humano":      ("achievement_character_human_male", "achievement_character_human_female", "Humana"),
  "enano":       ("achievement_character_dwarf_male", "achievement_character_dwarf_female", "Enana"),
  "elfo_noche":  ("achievement_character_nightelf_male", "achievement_character_nightelf_female", "Elfa de la Noche"),
  "semielfo":    ("eps_wc3h_highelfrangermale", "eps_wc3h_highelfbaddiegirl", "Semielfa"),
  "gnomo":       ("gnome_m", "gnome_f", "Gnoma"),
  "draenei":     ("achievement_character_draenei_male", "achievement_character_draenei_female", "Draenei"),
  "huargen":     ("achievement_worganhead", "ability_worgen_darkflight", "Huargen"),
  "orco":        ("achievement_character_orc_male", "achievement_character_orc_female", "Orca"),
  "renegado":    ("forsaken_m", "forsaken_f", "Renegada"),
  "tauren":      ("tauren_m", "tauren_f", "Tauren"),
  "trol":        ("troll_m", "troll_f", "Troll"),
  "elfo_sangre": ("achievement_character_bloodelf_male", "achievement_character_bloodelf_female", "Elfa de Sangre"),
  "goblin":      ("achievement_goblinhead", "achievement_femalegoblinhead", "Goblin"),
  "pandaren":    ("w3reforgedpandarenbrewmaster", "achievement_character_pandaren_female", "Pandaren"),
  # Esta entrada esta nombrada en femenino, al reves que las demas, asi que necesita
  # tambien el masculino: sin el, el interruptor ensenaba "Nocheterno" al pedir Mujer.
  "nocheterna":  ("nightborne_m", "nightborne_f", "Elfa Nocheterna", "Elfo Nocheterna"),
  "elfo_vacio":  ("voidelf_m", "voidelf_f", "Elfa del Vacio"),
  "vulpera":     ("vulpera_m", "vulpera_f", "Vulpera"),
}

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

# Los rasgos de incremento salian todos con el mismo dibujo. El texto dice que
# caracteristica sube ("Constitucion +2", "Destreza +2 y Sabiduria +1"), asi que cada uno
# puede llevar el signo del color de SU caracteristica. El color se elige por la clase que
# encarna esa caracteristica en WoW: el guerrero la Fuerza, el picaro la Destreza, el mago
# la Inteligencia. Cuando el incremento es a eleccion (Humano) no hay caracteristica que
# colorear y se queda con el signo neutro.
SIGNO_CARACTERISTICA = {
    "fuerza": "hd_plussign_warrior",
    "destreza": "hd_plussign_rogue",
    "constitucion": "hd_plussign_deathknight",
    "inteligencia": "hd_plussign_mage",
    "sabiduria": "hd_plussign_monk",
    "carisma": "hd_plussign_paladin",
}
# gris: no hay caracteristica que colorear porque todavia no se ha elegido
SIGNO_NEUTRO = "hd_plussign_priest"
# verde: la mejora de caracteristica que da la clase al subir de nivel (4, 8, 12...),
# que no es lo mismo que el incremento fijo que trae la raza
SIGNO_MEJORA = "hd_plussign_hunter"


# El rasgo de idiomas lleva siempre la misma nota, este en una raza, una subraza o un
# trasfondo. Se decide por nombre y no por id porque son 40 rasgos repartidos por todo.
ICONO_IDIOMAS = "inv_misc_note_05"
# Cabeceras de seccion que repiten decenas de trasfondos. No son rasgos propios: llevan un
# icono por TIPO, no uno cada uno, para que se reconozcan de un vistazo entre los que si lo
# son. Van por nombre porque estan repartidas por los 52 trasfondos.
# Las etiquetas genericas de competencia llevan todas el mismo pergamino: son un rotulo
# repetido decenas de veces, no un rasgo distinto cada vez. Las que SI nombran algo
# concreto ("Competencia con venenos", "Competencia adicional (cervecero)") conservan su
# icono propio, que dice mas que un pergamino.
ICONO_COMPETENCIA = "inv_scroll_11"
ICONO_POR_NOMBRE = {
    "competencias": ICONO_COMPETENCIA,
    "competencia con herramientas": ICONO_COMPETENCIA,
    "competencia en habilidad": ICONO_COMPETENCIA,
    "competencia con armas": ICONO_COMPETENCIA,
    "competencia en habilidades": ICONO_COMPETENCIA,
    # es una competencia aunque no se llame asi
    "herramientas de artesano": ICONO_COMPETENCIA,
    "equipo": "inv_misc_bag_20",
    "juego o instrumento": "inv_misc_dice_01",
    "juego": "inv_misc_dice_02",
}


def signo_incremento(f):
    """Signo del color de la caracteristica que sube este rasgo, si la nombra."""
    nombre = nk(f.get("name", ""))
    # cualquier rasgo que conceda idioma, aunque no empiece por la palabra
    # ("Herramienta e idioma"). Solo se aplica a RASGOS: las listas de conjuros no pasan
    # por aqui, asi que el conjuro "Comprender idiomas" no se ve afectado.
    if re.search(r"\bidiomas?\b", nombre):
        return ICONO_IDIOMAS
    # TODA etiqueta de competencia lleva el pergamino, tambien las que nombran algo
    # concreto ("Competencia con venenos", "Competencia adicional (cervecero)"). Va por
    # PREFIJO y por delante del catalogo, asi que pisa el icono especifico que tuvieran.
    if nombre.startswith("competencia"):
        return ICONO_COMPETENCIA
    if nombre in ICONO_POR_NOMBRE:
        return ICONO_POR_NOMBRE[nombre]
    if "mejora de caracteristica" in nombre:
        return SIGNO_MEJORA
    if "incremento de caracteristica" not in nombre:
        return None
    texto = nk(f.get("description") or f.get("desc") or "")
    citadas = sorted(((texto.find(c), ic) for c, ic in SIGNO_CARACTERISTICA.items()
                      if texto.find(c) >= 0))
    # "Destreza +2 y Sabiduria +1" sube dos cosas: no hay un color que lo represente,
    # asi que va el verde de mejora, el mismo que el ASI de clase
    if len(citadas) > 1:
        return SIGNO_MEJORA
    return citadas[0][1] if citadas else SIGNO_NEUTRO


for c in kb["classes"]:
    c["icon"] = use("classicon_" + CLASS_TOKEN.get(c["id"], "warrior"))
    for f in c["features"]: f["icon"] = use(signo_incremento(f) or feat_icon(f))
    for s in c["subclasses"]:
        s["icon"] = use((SUBS.get(c["id"], {}) or {}).get(s["id"]))
        # los conjuros de la especializacion llevan su propio icono
        _k = "%s/%s" % (c["id"], s["id"])
        if SUBSPELL.get(_k): s["spellIcon"] = use(SUBSPELL[_k])
        # las reglas por NOMBRE (incremento de caracteristica, idiomas, competencias)
        # se aplicaban a clases, razas, subrazas y trasfondos pero NO a subclases,
        # asi que sus rasgos se quedaban fuera de todas ellas sin motivo
        for f in s["features"]: f["icon"] = use(signo_incremento(f) or feat_icon(f))
        # ...y DESPUES del bucle de arriba, que asigna icono a cada rasgo sin condiciones
        # y pisaba esto cuando iba delante
        # Los rasgos que CONCEDEN esos conjuros ("Conjuros de presencia (Sangre)",
        # "Conjuros del llamado (Sombra)", "Lista ampliada de conjuros") llevan el mismo
        # icono que la magia de su especializacion: es exactamente de lo que hablan.
        if s.get("spellIcon"):
            for _f in s["features"]:
                if not _f.get("icon") and re.match(
                        r"(?i)^((conjuros?|hechizos?) (de|del)|lista ampliada de conjuros)\b",
                        _f["name"]):
                    _f["icon"] = s["spellIcon"]
# El MISMO rasgo a otro nivel: "Conjuros del camino" existe a nivel 3 y a nivel 5, y solo
# uno de los dos tenia icono. Si dos rasgos de la misma clase o subclase se llaman igual y
# uno lleva dibujo, lo llevan los dos.
_ngem = 0
for c in kb["classes"]:
    for grupo in [c] + list(c.get("subclasses") or []):
        _con = {}
        for f in grupo.get("features") or []:
            if f.get("icon"): _con.setdefault(nk(f["name"]), f["icon"])
        for f in grupo.get("features") or []:
            if not f.get("icon") and _con.get(nk(f["name"])):
                f["icon"] = _con[nk(f["name"])]; _ngem += 1
print("rasgos que heredan el icono de su gemelo de otro nivel: %d" % _ngem)

# Lo mismo por subraza. La clave es "raza/subraza" porque los ids se repiten entre razas
# (Renegado y Humano tienen los dos una subraza "humano").
SUBRACE_GENERO = {
  "enano/forjaz": ("dwarf_m", "dwarf_f", "Enana de Forjaz"),
  "enano/martillo_salvaje": ("eps_wc3h_wildhammermale", "eps_hots_dwarfshaman", "Enana Martillo Salvaje"),
  "enano/hierro_negro": ("darkiron_m", "darkiron_f", "Enana Hierro Negro"),
  "elfo_noche/altonato": ("eps_wc3h_nightelfmalewarrior", "eps_wc3h_nightelfcharm", "Altonata"),
  "gnomo/gnomeregan": ("achievement_character_gnome_male", "achievement_character_gnome_female", "Gnoma de Gnomeregan"),
  "gnomo/mecagnomo": ("mechagnome_m", "mechagnome_f", "Mecagnoma"),
  "draenei/exodar": ("draenei_m", "draenei_f", "Draenei del Exodar"),
  "draenei/forjado_luz": ("lightforged_m", "lightforged_f", "Draenei Forjada por la Luz"),
  "draenei/tabido": ("broken", "eps_wc3_brokendraeneimage", "Draenei Tábida"),
  "draenei/man_ari": ("eps_wc3h_eredardiabolist", "achievement_boss_argus_femaleeredar", "Man'ari"),
  "orco/cazadores": ("eps_wc3_orcwarlock", "eps_wc3h_orchuntress", "Clanes Cazadores"),
  "orco/misticos": ("eps_wc3_orcwarlockred", "eps_wc3h_orcwarden", "Clanes Místicos"),
  "orco/guerreros": ("eps_wc3h_orcwarlord", "eps_wc3h_orcfemalewarrior", "Clanes Guerreros"),
  "renegado/humano": ("achievement_character_undead_male", "achievement_character_undead_female", "Renegada Humana"),
  "renegado/elfo": ("eps_wc3h_forsakenhunter", "eps_wc3h_undeadsanlaynbaddiegirl", "Renegada Elfa"),
  "tauren/mulgore": ("achievement_character_tauren_male", "achievement_character_tauren_female", "Tauren de Mulgore"),
  "tauren/monte_alto": ("highmountain_m", "highmountain_f", "Tauren de Monte Alto"),
  "tauren/taunka": ("eps_wc3h_taunkachieftain", "inv_misc_head_tauren_02", "Taunka"),
  "trol/jungla": ("achievement_character_troll_male", "achievement_character_troll_female", "Troll de la Jungla"),
  "trol/zandalari": ("inv_zandalarimalehead", "inv_zandalarifemalehead", "Troll Zandalari"),
  "trol/bosque": ("eps_wc3_foresttrollpriest", "eps_wc3h_trolltrollpriestessfemale", "Troll de Bosque"),
  "trol/hielo": ("eps_wc3_icetrollshadowpriest", "eps_wc3h_trollpeasant", "Troll de Hielo"),
}

for r in kb["races"]:
    _g = RACE_GENERO.get(r["id"], ("", "", ""))
    _m, _f, _nf = _g[0], _g[1], _g[2]
    r["icon"] = use(_m) if _m else None
    r["iconF"] = use(_f) if _f else None
    r["nameF"] = _nf or None
    r["nameM"] = _g[3] if len(_g) > 3 else None
    for f in r["traits"]: f["icon"] = use(signo_incremento(f) or feat_icon(f))
    for sr in r.get("subraces", []):
        _sg = SUBRACE_GENERO.get(r["id"] + "/" + sr["id"])
        if _sg:
            sr["icon"] = use(_sg[0])
            sr["iconF"] = use(_sg[1]) if _sg[1] else None
            sr["nameF"] = _sg[2] or None
        else:
            sr["icon"] = use(icon_by_name(sr["name"]))
        for f in sr["traits"]: f["icon"] = use(signo_incremento(f) or feat_icon(f))
for b in kb["backgrounds"]:
    # BG_ICON son los que se sacaron de los perfiles TRP3; el catalogo del addon manda
    # igual que para el resto, para no tener dos sitios donde poner un icono
    _bi = FEATS.get(b["id"]) or BG_ICON.get(b["id"])
    b["icon"] = use(_bi) if _bi else None
    for f in b["traits"]: f["icon"] = use(signo_incremento(f) or feat_icon(f))
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
