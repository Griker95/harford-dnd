# -*- coding: utf-8 -*-
"""Ficha completa de cada objeto que aparece en las recetas de profesion.

`wowhead_profesiones.py` solo se queda con el nombre, el icono y la cantidad de cada
material y de cada resultado. Eso basta para leer la receta, pero no para saber que es lo
que sales fabricando: de las 315 piezas de Herreria o las 315 de Peleteria lo unico que se
veia era el nombre.

Las caracteristicas se toman de CLASSIC, no del juego actual: el retail reescala cada
objeto y hasta le cambia las estadisticas (la Hombrera de arana venenosa pasa de 41 de
armadura y espiritu a 10 de armadura y versatilidad). El NOMBRE si sigue siendo el moderno,
que es el criterio del resto del compendio.

Sin --apply solo informa.
"""
import io
import json
import os
import re
import ssl
import sys
import time
import unicodedata
import urllib.request


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn")

BASE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(BASE, "cotejo", "wowhead_cache")
RECETAS = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")
SALIDA = os.path.join(BASE, "cotejo", "objetos_wowhead.json")
TT = "https://nether.wowhead.com/%s/tooltip/item/%d?locale=6"
# de mas antigua a mas nueva: un objeto se pide a la version mas vieja en la que aparece,
# porque de Classic a Wrath las estadisticas no cambian y asi se reaprovecha la cache
ORDEN = {"classic": 0, "tbc": 1, "wotlk": 2}
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE

CALIDAD = {0: "Pobre", 1: "Comun", 2: "Poco comun", 3: "Raro", 4: "Epico", 5: "Legendario"}


def bajar(iid, ver="classic"):
    os.makedirs(CACHE, exist_ok=True)
    p = os.path.join(CACHE, "citem_%d.json" % iid if ver == "classic"
                     else "citem_%s_%d.json" % (ver or "retail", iid))
    if os.path.exists(p):
        return json.load(io.open(p, encoding="utf-8"))
    req = urllib.request.Request(
        ("https://nether.wowhead.com/tooltip/item/%d?locale=6" % iid) if not ver
        else (TT % (ver, iid)), headers=UA)
    t = urllib.request.urlopen(req, timeout=60, context=_CTX).read().decode("utf-8", "ignore")
    io.open(p, "w", encoding="utf-8").write(t)
    time.sleep(0.1)
    return json.loads(t)


_COMENT = re.compile(r"<!--.*?-->", re.S)
_ORO = re.compile(r'<span class="money(gold|silver|copper)">(\d+)</span>')


def pedir(iid, ver):
    """El objeto en su version, y si alli no existe se prueba en las siguientes.

    Un reactivo puede haberse anadido despues de la version del arbol donde aparece, y
    entonces esa version devuelve un 404. La ultima parada es el juego actual.
    """
    orden = [ver] + [v for v in ("classic", "tbc", "wotlk", "") if v != ver]
    ultimo = None
    for v in orden:
        try:
            return bajar(iid, v)
        except Exception as ex:                                   # noqa: BLE001
            ultimo = ex
    raise ultimo


def _lineas(tt):
    """El tooltip partido en lineas legibles, en el orden en que las muestra el juego."""
    t = _COMENT.sub("", tt or "")
    t = _ORO.sub(lambda m: m.group(2) + {"gold": "o", "silver": "p", "copper": "c"}[m.group(1)], t)
    t = re.sub(r"<br\s*/?>", "\n", t)
    # hay que cortar tambien al ABRIR celda o tabla: la ligadura va suelta antes de un
    # <table><tr><td>Pecho</td>, y sin ese corte salia "Se liga al equiparloPecho"
    t = re.sub(r"</?(table|td|th|tr|div|span)\b[^>]*>", "\n", t)
    t = re.sub(r"<[^>]+>", "", t)
    for e, c in (("&nbsp;", " "), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", '"'),
                 ("&#39;", "'"), ("&amp;", "&")):
        t = t.replace(e, c)
    out = []
    for l in t.split("\n"):
        l = re.sub(r"\s{2,}", " ", l).strip()
        if l and l not in out[-1:]:
            out.append(l)
    return out


_RE = {
    "ilvl": re.compile(r"^Nivel de objeto (\d+)$"),
    "req": re.compile(r"^Necesitas ser de nivel (\d+)$"),
    "armor": re.compile(r"^([\d.,]+) armadura$", re.I),
    "dur": re.compile(r"^Durabilidad (\d+) / (\d+)$"),
    "dmg": re.compile(r"^([\d.,]+) *[-a] *([\d.,]+) (?:p\. de )?[Dd]a(?:ñ|n)o$"),
    "vel": re.compile(r"^Velocidad ([\d.,]+)$"),
    "dps": re.compile(r"^\(([\d.,]+) (?:p\. de )?da(?:ñ|n)o por segundo\)$"),
    "pila": re.compile(r"^Carga m[aá]x: (\d+)$"),
    "venta": re.compile(r"^Precio de venta: ?(.*)$"),
    "prof": re.compile(r"^Requiere (.+?) \((\d+)\)$"),
    "stat": re.compile(r"^([+-]\d+) (.+)$"),
    "efecto": re.compile(r"^(Uso|Equipar|Equipo|Probabilidad al acertar|Al golpear|"
                         r"Al equipar|Al recibir dano|Al ser golpeado): ?(.*)$"),
}
_ATADURA = ("Se liga al recogerlo", "Se liga al equiparlo", "Se liga al usarlo", "Enlace de cuenta")

# La ranura y el material no se pueden tomar por posicion: delante de ellos puede ir la
# etiqueta de un conjunto ("Uniforme Escarlata") o de una fase ("[TdD Phase 2]"), y entonces
# la ranura salia siendo el nombre del conjunto. Se reconocen por su vocabulario, que es
# cerrado en las dos.
_RANURAS = {"cabeza", "cuello", "hombro", "espalda", "pecho", "camisa", "tabardo", "muneca",
            "manos", "cintura", "piernas", "pies", "dedo", "mano principal",
            "mano secundaria", "una mano", "dos manos", "a distancia", "reliquia",
            "municion", "sostenido en mano izquierda"}
_MATERIALES = {"tela", "cuero", "malla", "placas", "escudo", "espada", "hacha", "maza",
               "daga", "baston", "arco", "ballesta", "arma de fuego", "varita", "arma de asta",
               "arma de mano", "lanza", "alhaja", "camisola", "misceláneo", "miscelaneo",
               "libro", "idolo", "totem", "estandarte"}
_BANDERAS = {"unico", "unico-equipado"}
# marca interna de Wowhead para las fases de la temporada, no forma parte del objeto
_FASE = re.compile(r"^\[[A-Za-z]{2,4} Phase \d+\]$")


def ficha(iid, d):
    """Lo que el juego enseña del objeto, en campos y tambien tal cual, linea a linea."""
    ls = _lineas(d.get("tooltip"))
    f = {"quality": d.get("quality"), "icon": d.get("icon"), "lines": ls[1:]}   # ls[0] es el nombre
    stats, efectos, resto = [], [], []
    i = 0
    for l in ls[1:]:
        i += 1
        if l in _ATADURA:
            f["bind"] = l
            continue
        hecho = False
        for k, rx in _RE.items():
            m = rx.match(l)
            if not m:
                continue
            if k == "stat":
                stats.append(l)
            elif k == "efecto":
                efectos.append(l)
            elif k == "dmg":
                f["damage"] = "%s - %s" % (m.group(1), m.group(2))
            elif k == "dur":
                f["durability"] = int(m.group(2))
            elif k == "prof":
                f["reqProf"], f["reqSkill"] = m.group(1), int(m.group(2))
            elif k == "venta":
                f["sell"] = m.group(1).strip() or None
            else:
                v = m.group(1)
                f[k] = int(v) if v.isdigit() else v
            hecho = True
            break
        if not hecho:
            resto.append(l)
    if stats:
        f["stats"] = stats
    if efectos:
        f["effects"] = efectos
    sobra = []
    for l in resto:
        k = sa(l).lower()
        if k in _RANURAS and "slot" not in f:
            f["slot"] = l
        elif k in _MATERIALES and "type" not in f:
            f["type"] = l
        elif k in _BANDERAS:
            f.setdefault("flags", []).append(l)
        elif _FASE.match(l):
            # el jugador no ve esta etiqueta, pero delata que el objeto es de la Temporada
            # de Descubrimiento y no del Classic original: hay que poder descartarlo
            f["sod"] = True
        elif "set" not in f and "slot" in f:
            f["set"] = l                # el nombre del conjunto va junto a la ranura
        else:
            sobra.append(l)
    if sobra:
        f["other"] = sobra
    return {k: v for k, v in f.items() if v not in (None, [], "")}


def main():
    datos = json.load(io.open(RECETAS, encoding="utf-8"))
    ids, vers = {}, {}
    for v in datos.values():
        for x in v:
            ver = x.get("version") or "classic"
            for o in list(x.get("reagents") or []) + ([x["creates"]] if x.get("creates") else []):
                ids[o["id"]] = o["name"]
                if ORDEN[ver] < ORDEN.get(vers.get(o["id"]), 9):
                    vers[o["id"]] = ver
    print("objetos distintos en las recetas: %d" % len(ids))
    if "--apply" not in sys.argv:
        cach = sum(1 for i in ids if os.path.exists(os.path.join(CACHE,
                   "citem_%d.json" % i if vers.get(i, "classic") == "classic"
                   else "citem_%s_%d.json" % (vers[i], i))))
        print("ya en cache: %d   por bajar: %d" % (cach, len(ids) - cach))
        return

    fuera, err = {}, 0
    for n, (iid, nombre) in enumerate(sorted(ids.items()), 1):
        try:
            d = pedir(iid, vers.get(iid, "classic"))
            f = ficha(iid, d)
            f["name"] = nombre                    # el nombre moderno manda sobre el de Classic
            f["classicName"] = d.get("name")
            fuera[str(iid)] = f
        except Exception as ex:                                   # noqa: BLE001
            err += 1
            print("   %s: %s" % (iid, ex))
        if n % 200 == 0:
            print("   %4d/%d" % (n, len(ids)))
    # El nombre moderno no siempre sirve: Blizzard desmantelo los glifos y 324 objetos que
    # en Wrath tenian nombre propio ("Glifo de Disparo de punteria") hoy se llaman todos
    # "Glifo carbonizado". Cuando un nombre actual lo comparten varios objetos distintos, el
    # que distingue es el de su version, asi que ahi manda ese.
    import collections
    por = collections.defaultdict(list)
    for iid, f in fuera.items():
        por[f["name"]].append(iid)
    revertidos = 0
    for nombre, ids in por.items():
        if len(ids) < 2:
            continue
        for iid in ids:
            f = fuera[iid]
            if f.get("classicName") and f["classicName"] != f["name"]:
                f["name"] = f.pop("classicName")
                revertidos += 1
    print("objetos que recuperan su nombre de version por colision: %d" % revertidos)

    io.open(SALIDA, "w", encoding="utf-8").write(json.dumps(fuera, ensure_ascii=False, indent=1))
    con = lambda k: sum(1 for f in fuera.values() if f.get(k))    # noqa: E731
    print("\nguardados %d objetos en %s   (fallos %d)" % (len(fuera), SALIDA, err))
    print("con estadisticas %d | con efecto %d | con armadura %d | con dano %d | con nivel %d"
          % (con("stats"), con("effects"), con("armor"), con("damage"), con("req")))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
