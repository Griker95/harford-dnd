# -*- coding: utf-8 -*-
"""Hoja para elegir el icono de los rasgos de raza, subraza y trasfondo que no tienen.

Los nombres de los rasgos estan en espanol y los iconos del volcado en ingles, asi que no
sirve buscar por la palabra tal cual: "Sangre de fuego" no casa con nada, "fireblood" si.
Aqui hay un lexico corto que traduce las palabras que de verdad aparecen en estos 104
nombres, y con eso se busca en el volcado.

Reglas que no cambian:
  - un icono ya usado no se propone otra vez;
  - si no hay nada con sentido, la fila sale sin candidatos y se dice, en vez de rellenarla
    con un dibujo que no signifique nada.
"""
import base64
import collections
import io
import json
import os
import re
import sys
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
DUMP = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-data.js"
DOTES = r"C:/Users/marco/Documents/harfordweb/js/compendium-dotes.js"
CAT = r"C:/Users/marco/Documents/New project/Harford/Compendium/HarfordIconCatalog.lua"
SALIDA = os.path.join(BASE, "hoja_rasgos.html")
POR_FILA = 5

# Solo las palabras que aparecen de verdad en los 104 nombres. Ampliar segun haga falta.
LEXICO = {
    "mentor": ("teaching", "apprentice", "mentor"),
    # palabras corrientes, para que el buscador manual responda en espanol
    "hierro": "iron", "acero": "steel", "oro": "gold", "plata": "silver", "bronce": "bronze",
    "agua": "water", "aire": "air", "viento": "wind", "rayo": ("lightning", "shock"),
    "hielo": ("frost", "ice"), "veneno": "poison", "acido": "acid", "trueno": "thunder",
    "espada": "sword", "hacha": "axe", "maza": "mace", "arco": "bow", "daga": "dagger",
    "lanza": "spear", "martillo": "hammer", "escudo": "shield", "armadura": "armor",
    "casco": "helm", "capa": "cloak", "anillo": "ring", "libro": "book", "llave": "key",
    "corazon": "heart", "craneo": "skull", "hueso": "bone", "ojo": "eye", "mano": "hand",
    "ala": "wing", "lobo": "wolf", "oso": "bear", "cuervo": "raven", "serpiente": "snake",
    "dragon": "dragon", "demonio": "demon", "angel": "angel", "arbol": "tree", "flor": "flower",
    "estrella": "star", "sol": "sun", "luna": "moon", "corona": "crown", "moneda": "coin",
    # vocabulario de las DOTES y sus rasgos
    "beneficios": ("scroll", "book", "note"), "acorazado": ("plate", "armor", "defend"),
    "maestro": ("master", "expertise"), "experto": ("expertise", "master"),
    "adepto": ("adept", "expertise"), "iniciado": ("initiate", "apprentice"),
    "lanzador": ("spellpower", "arcane"), "trucos": ("cantrip", "arcane"),
    "recarga": ("reload", "shoot"), "tirador": ("marksmanship", "shoot", "aimedshot"),
    "atacante": ("attack", "warrior"), "combatiente": ("warrior", "combat"),
    "escudo": ("shield", "defend"), "armaduras": ("armor", "plate"),
    "pesadas": ("plate", "armor"), "garras": ("claw", "rake"),
    "pocion": ("potion", "alchemy"), "sanador": ("healing", "heal"),
    "espiritual": ("spirit", "spiritheal"), "vacio": ("void", "shadow"),
    "precision": ("precision", "aimedshot"), "versado": ("expertise", "study"),
    "tocado": ("touch", "blessing"), "durabilidad": ("toughness", "stamina"),
    "afortunado": ("luck", "fortune"), "observador": ("perception", "eye"),
    "centinela": ("sentinel", "guard"), "duelista": ("duel", "parry"),
    "apresador": ("grapple", "grip"), "acechador": ("stealth", "prowl"),
    "actor": ("disguise", "trickster"), "alerta": ("alertness", "perception"),
    # vocabulario de los TRASFONDOS: muchos tienen icono literal en el volcado
    "argenta": ("argentcrusade", "argent"), "cenarion": "cenarion", "ravenholdt": "ravenholdt",
    "kirin": "kirintor", "tor": "kirintor", "torio": "thorium", "alterac": "alterac",
    "luna": "darkmoon", "negra": "darkmoon", "feriante": "darkmoon",
    "doble": ("spy", "espionage"), "agente": ("spy", "agent"), "operativo": ("spy", "rogue"),
    "charlatan": ("trickster", "disguise", "charlatan"), "criminal": ("thief", "pickpocket"),
    "ermitano": "hermit", "eremita": "hermit", "forastero": ("outlander", "explorer"),
    "marinero": ("sailor", "anchor", "ship"), "bucanero": ("pirate", "buccaneer"),
    "soldado": ("soldier", "warcry"), "salvaje": ("outlander", "wild"),
    "heroe": "hero", "pueblo": "hero", "heredero": ("heirloom", "noble"),
    "cosecha": ("blackharvest", "fel"), "adepto": ("warlock", "fel"),
    "abisal": ("netherlight", "shadow"), "acolito": ("priest", "acolyte"),
    "expedicionarios": ("explorer", "explorersleague"), "liga": "explorersleague",
    "anillo": ("earthenring", "shaman"), "tierra": "earthenring",
    "tribal": ("totem", "tribal"), "catastrofe": ("cataclysm", "survival"),
    "superviviente": ("survival", "cataclysm"), "principe": ("goblin", "trade"),
    "mercante": ("trade", "coin"), "organizacion": ("tabard", "guild"),
    "faccion": ("tabard", "alliance"), "crianza": ("tabard", "alliance"),
    "caballero": ("knight", "paladin"), "orden": ("knight", "order"),
    "exiliado": ("exile", "alterac"), "forjador": ("blacksmith", "thorium"),
    "hermandad": ("thorium", "brotherhood"), "novato": ("explorer", "apprentice"),
    "tenacidad": "tenacity", "rugosa": "rugged", "pisoton": "warstomp",
    "voodoo": "voodoo", "shuffle": "shuffle", "loa": "loa", "amani": "amani",
    "zandalari": "zandalari", "emboscador": ("ambush", "stealth"), "berserker": "berserk",
    "grieta": ("rift", "voidrift"), "palma": "palm", "temblorosa": "quivering",

    "residencia": ("mountaineer", "highmountain"),
    "abrazo": ("embrace", "blessing"),
    "sangre": "blood", "fuego": "fire", "llamas": "flame", "forjado": "forge", "forja": "forge",
    "piedra": "stone", "roca": "rock", "hielo": "frost", "frio": "frost", "nieve": "snow",
    "luz": "holy", "sagrada": "holy", "sagrado": "holy", "juicio": "judgement",
    "sombras": "shadow", "sombra": "shadow", "oscuridad": "darkness",
    "arcano": "arcane", "arcana": "arcane", "magia": "magic", "elemental": "elemental",
    "naturaleza": "nature", "tundra": "tundra", "montanes": ("mountaineer", "mountain"), "montana": "mountain",
    "altura": "mountain", "regeneracion": "regeneration", "resistencia": "resistance",
    "dureza": "toughness", "tenacidad": ("tenacity", "hardiness", "endurance"), "constitucion": ("fortitude", "endurance", "stamina"),
    "berserker": "berserk", "furia": "rage", "agresivo": ("enrage", "berserk", "battleshout"), "salvajes": "savage",
    "emboscador": "ambush", "sorpresa": "ambush", "sigilo": "stealth", "esquivar": ("evasion", "nimble", "dodge"),
    "cuernos": "gore", "pisoton": "warstomp", "palma": "palm", "temblorosa": "quivering",
    "ingenieria": "engineering", "mecanica": "mechanical", "tratos": "trade",
    "disfraces": "disguise", "disfraz": "disguise", "herborista": "herb",
    "veterano": "veteran", "militar": "military", "rango": "rank", "soldado": "soldier",
    "espia": "spy", "pirata": "pirate", "caballero": "knight", "gladiador": "gladiator",
    "criminal": "criminal", "identidad": "identity", "falsa": "false",
    "barco": "boat", "marinero": "sailor", "refugio": "sanctuary", "red": "network",
    "herencia": "heirloom", "perspicacia": "insight", "supervivencia": "survival",
    "guardian": "guardian", "vagabundo": "wander", "descubrimiento": "discovery",
    "conocimiento": "lore", "conocimientos": "lore", "misticos": "mystic",
    "ancestral": "ancestral", "llamado": "call", "loa": "loa", "voodoo": "voodoo",
    "vinculo": "bond", "paria": ("exile", "banish", "outcast"), "gemas": "gem", "tallado": "gem",
    "amenazante": ("intimidat", "menacing", "demoraliz"), "implacable": "relentless", "poderosa": ("might", "powerful", "strength"),
    "versatilidad": ("versatility", "adaptation"), "habilidades": "skill", "habilidad": "skill",
    "armas": "weapon", "entrenamiento": "training", "combate": "combat",
    "atleta": "athletic", "caminante": "walk", "domador": "tame", "valentia": ("courage", "valor", "fearless"),
    "grieta": "rift", "espacial": "void", "solar": "sun", "sensibilidad": "sensitivity",
    "determinacion": "determination", "equilibrio": "balance", "codigo": "code",
    "hipnotica": "hypnotic", "actuacion": "perform", "pionero": "explorer",
    "cartel": "cartel", "conexiones": "contact", "prestigio": "prestige",
    "hermandad": "brotherhood", "torio": "thorium", "canalla": "rogue",
    "instintos": "instinct", "amani": "amani", "zandalari": "zandalari",
    "kaldorei": "nightelf", "orcas": "orc", "tauren": "tauren", "troll": "troll",
    "enano": "dwarf", "goblin": "goblin", "nocheterna": "nightborne",
}
FAMILIAS = ("spell_", "ability_", "eps_", "hots_", "d3_", "dos2_", "wh_", "inv_", "achievement_")
BASURA = {"mount", "tarot", "food", "drink", "pet", "toy", "quest", "dmc", "garrison",
          "banner", "tabard", "shirt", "fishing", "cooking", "battlepet", "profileicon",
          "coinpack", "ticket"}
PESO = {"spell_": 12, "ability_": 12, "eps_": 8, "hots_": 6, "d3_": 5, "dos2_": 5,
        "wh_": 5, "achievement_": -6, "inv_": -8}


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]+", " ", s.lower())


def claves(nombre):
    """Palabras inglesas por las que buscar el icono de este rasgo."""
    limpio = re.sub(r"(?i)^(caracter[ií]stica|variante)\s*:\s*", "", nombre or "")
    out = []
    for w in nk(limpio).split():
        if len(w) < 4:
            continue
        t = LEXICO.get(w)
        if isinstance(t, tuple):
            out.extend(t)
        elif t:
            out.append(t)
        elif len(w) > 5:
            out.append(w)              # nombres propios: amani, zandalari, kaldorei
    return list(dict.fromkeys(out))


def _peso(ic):
    for pref, v in PESO.items():
        if ic.startswith(pref):
            return v
    return 0


def candidatos(nombre, iconos, vetados):
    cl = claves(nombre)
    if not cl:
        return []
    # Los iconos de WoW pegan las palabras: "Sangre de fuego" no es "blood" a secas, es
    # "fireblood". Las combinaciones van delante para que ganen a la palabra suelta, que
    # se deja la mitad del nombre por el camino.
    if len(cl) > 1:
        cl = [cl[1] + cl[0], cl[0] + cl[1]] + cl
    marcados = {}
    for ic in iconos:
        if ic in vetados or not ic.startswith(FAMILIAS):
            continue
        segs = set(re.split(r"[_0-9]+", ic))
        # por segmento y no por subcadena: "mount" tapaba "mountaineer" y "living_mountain"
        if segs & BASURA:
            continue
        for i, k in enumerate(cl):
            # el segmento tiene que EMPEZAR por la clave: "wind" dentro de "second·wind"
            # no habla de viento
            if k in segs or any(s.startswith(k) for s in segs):
                p = (30 - i * 6) + _peso(ic) + (8 if k in segs else 0)
                if p > marcados.get(ic, (0,))[0]:
                    marcados[ic] = (p, k)
    return [ic for ic, _ in sorted(marcados.items(), key=lambda x: -x[1][0])][:POR_FILA]


# En modo LOCAL la hoja no incrusta nada: apunta a los PNG del volcado con una ruta
# relativa. Asi caben los 36.604 en el buscador, cosa imposible en base64.
RUTA_DUMP_REL = "../../EpsilonIcons/png"
LOCAL = False


def png(nombre):
    ruta = os.path.join(DUMP, nombre + ".png")
    if not os.path.exists(ruta):
        return None
    if LOCAL:
        return RUTA_DUMP_REL + "/" + nombre + ".png"
    return "data:image/png;base64," + base64.b64encode(io.open(ruta, "rb").read()).decode()


CABECERA = io.open(os.path.join(BASE, "_hoja_estilo.html"), encoding="utf-8").read() \
    if os.path.exists(os.path.join(BASE, "_hoja_estilo.html")) else ""


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    d = json.loads(re.search(r"=\s*(\{[\s\S]*\})", io.open(WEB, encoding="utf-8").read()).group(1))
    iconos = [f[:-4].lower() for f in os.listdir(DUMP) if f.lower().endswith(".png")]
    vetados = {x.lower() for x in re.findall(r'"([A-Za-z0-9_]+)"', io.open(CAT, encoding="utf-8").read())}

    def rec(o):
        if isinstance(o, dict):
            if isinstance(o.get("icon"), str):
                vetados.add(o["icon"].lower())
            for v in o.values():
                if not isinstance(v, str):
                    rec(v)
        elif isinstance(o, list):
            for v in o:
                rec(v)
    rec(d)

    # con argumento se genera solo un bloque: `python hoja_rasgos.py raza`
    # `plana` saca TODO en una sola lista, sin separar por bloques
    plana = "plana" in [x.lower() for x in sys.argv[1:]]
    global LOCAL
    LOCAL = "--local" in sys.argv[1:]
    _args = [x for x in sys.argv[1:] if not x.startswith("--")]
    # varios terminos separados por coma: "raza,clase" saca los cuatro bloques de golpe
    solo = [nk(x) for x in _args[0].split(",")] if _args and not plana else []
    filas = []
    for r in d["races"]:
        for f in r.get("traits") or []:
            if not f.get("icon"):
                filas.append(("Razas", r["name"], f))
        for s in r.get("subraces") or []:
            for f in s.get("traits") or []:
                if not f.get("icon"):
                    filas.append(("Subrazas", s["name"], f))
    # Clases y subclases HASTA NIVEL 6, que es el alcance acordado: un rasgo de nivel 12 no
    # se juega todavia y meterlo aqui seria pedir decisiones que no hacen falta.
    for c in d.get("classes") or []:
        for f in c.get("features") or []:
            if not f.get("icon") and (f.get("level") or 0) <= 6:
                filas.append(("Clases", c["name"], f))
        for s in c.get("subclasses") or []:
            for f in s.get("features") or []:
                if not f.get("icon") and (f.get("level") or 0) <= 6:
                    filas.append(("Subclases", c["name"] + " / " + s["name"], f))

    # Las dotes van en su propio fichero y no en el kb, asi que hay que cargarlas aparte.
    # Son las 77 dotes y sus 139 rasgos: ninguna tiene icono, ni en el addon ni en el
    # catalogo, asi que es el bloque mas grande que queda.
    try:
        _dot = json.loads(re.search(r"=\s*(\[[\s\S]*\])\s*;",
                                    io.open(DOTES, encoding="utf-8").read()).group(1))
    except Exception:
        _dot = []
    for x in _dot:
        if not x.get("icon"):
            filas.append(("Iconos de dote", x.get("requires") or "sin requisito", x))
        for f in x.get("traits") or []:
            if not f.get("icon"):
                filas.append(("Rasgos de dote", x["name"], f))

    for b in d["backgrounds"]:
        # el icono del trasfondo en si, no el de sus rasgos: es el que se ve en la lista
        if not b.get("icon"):
            filas.append(("Iconos de trasfondo", b.get("source") or "", b))
        for f in b.get("traits") or []:
            if not f.get("icon"):
                filas.append(("Trasfondos", b["name"], f))

    if solo:
        filas = [x for x in filas if any(s in nk(x[0]) for s in solo)]
    # el mismo rasgo repetido en varias razas es un unico rasgo: una fila, y al aplicarlo
    # va a todos sus ids ("Entrenamiento con armas Troll" esta en las tres subrazas de trol)
    unicas, vistos = [], {}
    for grupo, quien, f in filas:
        clave = nk(f["name"])
        if clave in vistos:
            vistos[clave][1].append(quien)
            continue
        vistos[clave] = (f, [quien])
        unicas.append((grupo, clave, f))
    filas = [(g, " + ".join(vistos[c][1]), f) for g, c, f in unicas]
    reservados = set()
    partes = [PLANTILLA_CABECERA % len(filas)]
    sin_nada = []
    grupo_actual = None
    for grupo, quien, f in filas:
        if grupo != grupo_actual and not plana:
            partes.append("<h2>%s</h2>" % grupo)
            grupo_actual = grupo
        cands = candidatos(f["name"], iconos, vetados | reservados)
        if cands:
            reservados.add(cands[0])
        else:
            sin_nada.append(f["name"])
        partes.append('<div class="fila" data-k="%s">' % f["id"])
        partes.append('<div class="cab"><b>%s</b><span class="meta">%s · %s · %s</span></div>'
                      % (f["name"], grupo, quien, f["id"]))
        partes.append('<div class="ops">')
        for c in cands:
            dato = png(c)
            if dato:
                partes.append('<button class="op" data-i="%s"><img src="%s" alt=""><small>%s</small></button>'
                              % (c, dato, c))
        partes.append('<button class="op nada" data-i="">Ninguno</button></div></div>')
    if LOCAL:
        # la lista de nombres son ~700 KB de texto: aceptable en local, y es lo que permite
        # buscar entre TODOS y no solo entre los candidatos propuestos
        # nombre REAL del fichero: 1.991 del volcado llevan mayusculas y la busqueda se
        # hace aparte en minusculas, para no depender de que el disco las ignore
        todos = sorted(f[:-4] for f in os.listdir(DUMP) if f.lower().endswith(".png"))
        # el volcado esta en INGLES: sin traducir la consulta, "fuego" da CERO
        # resultados. Se envia el mismo lexico que usan los candidatos.
        _lex = {k: ([v] if isinstance(v, str) else list(v)) for k, v in LEXICO.items()}
        partes.append(BUSCADOR % (len(todos), json.dumps(RUTA_DUMP_REL),
                                  json.dumps(todos), json.dumps(_lex, ensure_ascii=False)))
    if not LOCAL:
        # sin buscador no hay panel, pero las columnas hay que cerrarlas igual
        partes.append('</div>\n<aside class="panel"><p class="vacio">El buscador de iconos '
                      'solo esta en la hoja local (--local), que lee la carpeta del volcado.</p>')
    partes.append(PLANTILLA_PIE)
    salida = SALIDA.replace(".html", "_plana.html") if plana else (
        SALIDA if not solo else SALIDA.replace(".html", "_%s.html" % "-".join(solo)))
    io.open(salida, "w", encoding="utf-8").write("\n".join(partes))
    print("hoja escrita: %s" % salida)
    print("   rasgos: %d | sin ningun candidato: %d | tamano: %.1f MB"
          % (len(filas), len(sin_nada), os.path.getsize(salida) / 1e6))
    for n in sin_nada[:15]:
        print("      sin candidatos: %s" % n)


PLANTILLA_CABECERA = """<title>Iconos de rasgos</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bitter:wght@700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
 :root{--tinta:#12212f;--tinta-2:#3b4c5d;--tenue:#6f7d8b;--papel:#f4f1e8;--papel-2:#eae5d7;
   --caja:#fff;--linea:#d9d2c2;--azul:#2b5f88;--verde:#3f6b4a}
 @media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
   --tinta:#e8e3d6;--tinta-2:#b6b0a1;--tenue:#8a8577;--papel:#131820;--papel-2:#1b222b;
   --caja:#19202a;--linea:#2f3a46;--azul:#78aed6;--verde:#79b98a}}
 :root[data-theme="dark"]{--tinta:#e8e3d6;--tinta-2:#b6b0a1;--tenue:#8a8577;--papel:#131820;
   --papel-2:#1b222b;--caja:#19202a;--linea:#2f3a46;--azul:#78aed6;--verde:#79b98a}
 *{box-sizing:border-box}
 body{margin:0;background:var(--papel);color:var(--tinta);
   font:400 16px/1.6 "IBM Plex Sans",system-ui,sans-serif}
 .hoja{max-width:86rem;margin:0 auto;padding:2.5rem 1.2rem 7rem}
 h1{font:700 2.2rem/1.1 "Bitter",Georgia,serif;margin:0 0 .5rem}
 h2{font:700 1.3rem/1.2 "Bitter",Georgia,serif;margin:2.4rem 0 .6rem;
   padding-bottom:.4rem;border-bottom:2px solid var(--azul)}
 .sub{margin:0 0 1.4rem;color:var(--tinta-2);max-width:44rem}
 .barra{position:sticky;top:0;z-index:5;background:var(--papel);border-bottom:1px solid var(--linea);
   padding:.7rem 0;margin-bottom:1rem;display:flex;gap:1rem;align-items:center;flex-wrap:wrap}
 .cuenta{font:500 .85rem/1 "IBM Plex Mono",monospace;color:var(--tinta-2)}
 button.acc{font:500 .82rem/1 inherit;padding:.5rem .8rem;cursor:pointer;border:1px solid var(--linea);
   border-radius:3px;background:var(--caja);color:var(--tinta)}
 .fila{border:1px solid var(--linea);border-left:3px solid var(--azul);border-radius:4px;
   background:var(--caja);padding:.8rem 1rem;margin:0 0 .5rem}
 .fila.hecha{border-left-color:var(--verde)}
 .cab{display:flex;align-items:baseline;gap:.6rem;flex-wrap:wrap;margin-bottom:.5rem}
 .cab b{font:600 1rem/1.2 inherit}
 .meta{font:400 .74rem/1 "IBM Plex Mono",monospace;color:var(--tenue)}
 .ops{display:flex;gap:.45rem;flex-wrap:wrap}
 .op{border:2px solid transparent;border-radius:4px;background:var(--papel-2);padding:.35rem;
   cursor:pointer;width:6rem;text-align:center;font:inherit;color:inherit}
 .op:hover{border-color:var(--azul)}
 .op.sel{border-color:var(--verde);background:color-mix(in srgb,var(--verde) 16%%,var(--caja))}
 .op img{width:40px;height:40px;display:block;margin:0 auto .25rem;border-radius:3px}
 .op small{display:block;font:400 .58rem/1.15 "IBM Plex Mono",monospace;color:var(--tinta-2);
   word-break:break-all}
 .op.nada{width:auto;padding:.5rem .7rem;font-size:.76rem;color:var(--tinta-2)}
 #salida{width:100%%;min-height:11rem;margin-top:.7rem;font:400 .76rem/1.45 "IBM Plex Mono",monospace;
   background:var(--caja);color:var(--tinta);border:1px solid var(--linea);border-radius:3px;padding:.7rem}
 /* Dos columnas: las filas a la izquierda y el buscador pegado a la derecha. Al final del
    documento no servia: para asignar un icono hay que ver la fila y el buscador a la vez. */
 .cols{display:grid;grid-template-columns:minmax(0,1fr) 23rem;gap:1.4rem;align-items:start}
 .panel{position:sticky;top:4.2rem;max-height:calc(100vh - 5.5rem);display:flex;
   flex-direction:column;border:1px solid var(--linea);border-radius:5px;
   background:var(--caja);padding:.8rem .8rem .5rem}
 .panel h2{margin:0 0 .3rem;font-size:1rem}
 .panel .sub{margin:0 0 .6rem;font-size:.78rem}
 .panel #res{overflow:auto;flex:1;align-content:flex-start;padding-right:.2rem}
 .panel #res .op{width:64px}
 .panel .vacio{color:var(--tenue);font-size:.8rem;margin:.4rem 0}
 @media(max-width:980px){.cols{grid-template-columns:1fr}
   .panel{position:static;max-height:none}}
 .fila.activa{outline:2px solid var(--azul);outline-offset:3px}
 .fila.activa .cab b{color:var(--azul)}
 .cab{cursor:pointer}
 .busca{display:flex;gap:10px;align-items:center;margin:6px 0 10px}
 .busca input{flex:1;padding:8px 10px;font:inherit;border:1px solid var(--linea);
   border-radius:5px;background:var(--caja);color:var(--tinta)}
</style>
<div class="hoja">
<h1>Iconos de rasgos</h1>
<p class="sub">Los %d rasgos de raza, subraza y trasfondo que no tienen dibujo. Un clic por
fila; se guarda en este navegador y sale abajo listo para pasármelo. Ningún candidato está
ya en uso.</p>
<div class="barra"><span class="cuenta" id="cuenta">0</span>
<button class="acc" id="ver">Ver el resultado</button>
<button class="acc" id="limpiar">Empezar de cero</button></div>
<div class="cols">
<div class="lista">
"""

BUSCADOR = """</div>
<aside class="panel">
<h2>Buscar icono</h2>
<p class="sub">Los %s del volcado. Pulsa el <b>nombre de una fila</b> para activarla y
luego el icono: se le asigna. Dos letras minimo; busca en espanol.</p>
<div class="busca">
  <input id="q" type="search" placeholder="fuego, espada, wildhammer, ability_warrior..." autocomplete="off">
  <span id="qn" class="meta"></span>
</div>
<div id="res" class="ops"></div>
<script>
(function(){
  var BASE=%s, TODOS=%s, LEX=%s;
  window.HARFORD_RUTA_ICONOS=BASE;
  var q=document.getElementById('q'), res=document.getElementById('res'), qn=document.getElementById('qn');
  var t=null;
  function pinta(){
    var v=q.value.trim().toLowerCase();
    res.innerHTML='';
    if(v.length<2){ qn.textContent=''; return; }
    var pal=v.split(/\\s+/);
    // cada palabra vale por si misma o por su traduccion: "fuego" busca tambien "fire"
    var alt=pal.map(function(p){ return [p].concat(LEX[p]||[]); });
    var hit=[];
    for(var i=0;i<TODOS.length && hit.length<400;i++){
      var n=TODOS[i], nl=n.toLowerCase(), ok=true;
      for(var j=0;j<alt.length;j++){
        var hay=false;
        for(var k=0;k<alt[j].length;k++) if(nl.indexOf(alt[j][k])>=0){ hay=true; break; }
        if(!hay){ ok=false; break; }
      }
      if(ok) hit.push(n);
    }
    qn.textContent=hit.length+(hit.length===400?'+':'')+' resultados';
    var frag=document.createDocumentFragment();
    hit.forEach(function(n){
      var b=document.createElement('button');
      b.className='op'; b.dataset.i=n;
      b.innerHTML='<img loading="lazy" src="'+BASE+'/'+n+'.png" alt=""><small>'+n+'</small>';
      frag.appendChild(b);
    });
    res.appendChild(frag);
  }
  q.addEventListener('input', function(){ clearTimeout(t); t=setTimeout(pinta,180); });
})();
</script>
"""

PLANTILLA_PIE = """</aside>
</div>
<h2>El resultado</h2>
<textarea id="salida" readonly></textarea>
</div>
<script>
(function(){
  var CLAVE='harford:rasgos';
  var RUTA_ICONOS=window.HARFORD_RUTA_ICONOS||'';
  var elegido=JSON.parse(localStorage.getItem(CLAVE)||'{}');
  var filas=[].slice.call(document.querySelectorAll('.fila'));
  function pinta(){
    document.getElementById('cuenta').textContent=Object.keys(elegido).length+' de '+filas.length;
    document.getElementById('salida').value=JSON.stringify(elegido,null,1);
  }
  filas.forEach(function(f){
    var k=f.getAttribute('data-k');
    f.addEventListener('click',function(ev){
      var b=ev.target.closest('.op'); if(!b) return;
      f.querySelectorAll('.op').forEach(function(x){x.classList.remove('sel')});
      b.classList.add('sel'); f.classList.add('hecha');
      elegido[k]=b.getAttribute('data-i');
      localStorage.setItem(CLAVE,JSON.stringify(elegido)); pinta();
    });
    if(elegido[k]!==undefined){
      var sel=f.querySelector('.op[data-i="'+(elegido[k]||'')+'"]');
      if(sel){sel.classList.add('sel'); f.classList.add('hecha');}
    }
  });
  // ---- fila activa y buscador ----
  // El buscador esta fuera de las filas, asi que necesita saber a cual asignar. Se marca
  // una pulsando su cabecera; sin fila activa, un icono del buscador no hace nada y se
  // avisa, que es mejor que asignarlo a la primera y que el usuario no se entere.
  var activa=null;
  function marca(f){
    if(activa) activa.classList.remove('activa');
    activa=f; if(f) f.classList.add('activa');
  }
  filas.forEach(function(f){
    var cab=f.querySelector('.cab');
    if(cab) cab.addEventListener('click',function(){ marca(activa===f?null:f); });
  });
  function asigna(nombre){
    if(!activa){ alert('Selecciona antes una fila: pulsa su nombre.'); return; }
    var k=activa.getAttribute('data-k');
    elegido[k]=nombre;
    activa.classList.add('hecha');
    activa.querySelectorAll('.op').forEach(function(x){
      x.classList.toggle('sel', x.getAttribute('data-i')===nombre);
    });
    // si el icono no estaba entre los candidatos, se anade a esa fila para que se vea
    if(!activa.querySelector('.op[data-i="'+nombre+'"]')){
      var ops=activa.querySelector('.ops');
      var b=document.createElement('button');
      b.className='op sel'; b.setAttribute('data-i',nombre);
      b.innerHTML='<img loading="lazy" src="'+RUTA_ICONOS+'/'+nombre+'.png" alt=""><small>'+nombre+'</small>';
      ops.insertBefore(b, ops.firstChild);
    }
    localStorage.setItem(CLAVE,JSON.stringify(elegido)); pinta();
  }
  var res=document.getElementById('res');
  if(res) res.addEventListener('click',function(ev){
    var b=ev.target.closest('.op'); if(b) asigna(b.getAttribute('data-i'));
  });

  document.getElementById('ver').addEventListener('click',function(){
    var s=document.getElementById('salida'); s.scrollIntoView({behavior:'smooth'}); s.select();
  });
  document.getElementById('limpiar').addEventListener('click',function(){
    if(!confirm('¿Borrar todas las elecciones?')) return;
    elegido={}; localStorage.removeItem(CLAVE);
    filas.forEach(function(f){f.classList.remove('hecha');
      f.querySelectorAll('.op').forEach(function(x){x.classList.remove('sel')})});
    pinta();
  });
  pinta();
})();
</script>"""


if __name__ == "__main__":
    main()
