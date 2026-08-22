# -*- coding: utf-8 -*-
"""Baja de Wowhead las recetas de las profesiones de WoW, una a una.

La lista de cada profesion (skill=NNN) trae el esqueleto de cada receta: nombre, nivel al
que se aprende, umbrales de color, componentes y el objeto que crea. El EFECTO solo esta en
la ficha del hechizo, asi que despues se pide el tooltip de cada receta.

Cada profesion se lee de la version donde su arbol esta completo: Classic para las nueve
originales, Burning Crusade para Joyeria y Wrath para Inscripcion, que no existen antes.
Los NOMBRES, en cambio, se toman siempre de la version moderna, que es la que usa el
servidor: Classic dice "Vara de cobre con runas", "Orbe de rectitud" o "Vial vacio" donde
el juego actual dice "Vara runica de cobre", "Orbe recto" y "Vial de cristal".

Todo lo descargado se cachea en disco, asi que repetir la ejecucion no vuelve a pedir nada.
"""
import io
import json
import os
import re
import ssl
import sys
import time
import urllib.request

BASE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(BASE, "cotejo", "wowhead_cache")
SALIDA = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")

# skill de Wowhead -> id de profesion en el addon, y de que version sale su arbol.
# Casi todas se leen de Classic, que es donde estan completas, pero Joyeria nacio en Burning
# Crusade e Inscripcion en Wrath: en Classic no existen y hay que pedirlas a su version.
SKILLS = [
    (333, "enchanting",   "encantamiento",     "classic"),
    (202, "engineering",  "ingenieria",        "classic"),
    (197, "tailoring",    "sastreria",         "classic"),
    (171, "alchemy",      "alquimia",          "classic"),
    (164, "blacksmithing", "herreria",         "classic"),
    (165, "leatherworking", "peleteria",       "classic"),
    (129, "first-aid",    "primeros_auxilios", "classic"),
    (186, "mining",       "mineria",           "classic"),
    (185, "cooking",      "cocina",            "classic"),
    (755, "jewelcrafting", "joyeria",          "tbc"),
    (773, "inscription",  "inscripcion",       "wotlk"),
]

LISTA = "https://es.wowhead.com/%s/skill=%d/%s"
TT_SPELL = "https://nether.wowhead.com/%s/tooltip/spell/%d?locale=6"
TT_ITEM = "https://nether.wowhead.com/tooltip/item/%d?locale=6"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

# el certificado de wowhead no valida contra el almacen local de este equipo
_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE


def bajar(url, nombre):
    os.makedirs(CACHE, exist_ok=True)
    p = os.path.join(CACHE, nombre)
    if os.path.exists(p):
        return io.open(p, encoding="utf-8").read()
    req = urllib.request.Request(url, headers=UA)
    t = urllib.request.urlopen(req, timeout=60, context=_CTX).read().decode("utf-8", "ignore")
    io.open(p, "w", encoding="utf-8").write(t)
    time.sleep(0.12)
    return t


def _cerrar(txt, desde, abre, cierra):
    prof, k = 0, desde
    while k < len(txt):
        if txt[k] == abre:
            prof += 1
        elif txt[k] == cierra:
            prof -= 1
            if prof == 0:
                return txt[desde:k + 1]
        k += 1
    raise ValueError("bloque sin cerrar")


def catalogo(html):
    """{id: {'name','icon'}} de los objetos que la pagina declara, en espanol."""
    items = {}
    for m in re.finditer(r"WH\.Gatherer\.addData\(3,\s*\d+,\s*", html):
        try:
            datos = json.loads(_cerrar(html, m.end(), "{", "}"))
        except ValueError:
            continue
        for iid, v in datos.items():
            nombre = v.get("name_eses") or v.get("name_enus")
            if not nombre:
                continue
            iid = int(iid)
            if iid in items and items[iid]["es"] and not v.get("name_eses"):
                continue
            items[iid] = {"name": nombre, "icon": v.get("icon"), "es": bool(v.get("name_eses"))}
    return items


def recetas(html):
    i = html.find('id: "recipes"')
    if i < 0:
        return []
    return json.loads(_cerrar(html, html.find("data:", i) + 5, "[", "]"))


_COMENT = re.compile(r"<!--.*?-->", re.S)
_TAG = re.compile(r"<[^>]+>")


def _texto(s):
    s = _COMENT.sub("", s).replace("&nbsp;", " ").replace("<br />", " ").replace("<br>", " ")
    s = _TAG.sub("", s).replace("&amp;", "&").replace("&quot;", '"').replace("&#39;", "'")
    return re.sub(r"\s{2,}", " ", s).strip()


def detalle(spell_id, ver="classic"):
    d = json.loads(bajar(TT_SPELL % (ver, spell_id),
                         "spell_%s_%d.json" % (ver, spell_id)))
    tt = d.get("tooltip") or ""
    efecto = None
    qs = re.findall(r'<div class="q">(.*?)</div>', tt, re.S)
    if qs:
        efecto = _texto(qs[-1])
    if not efecto:
        m = re.search(r'<span id="useText1".*?>(.*?)</span>', tt, re.S)
        if m:
            efecto = _texto(m.group(1))
    herr = None
    m = re.search(r"Herramientas:(.*?)(?:Componentes:|$)", tt, re.S)
    if m:
        herr = _texto(m.group(1)) or None
    return {"icon": d.get("icon"), "efecto": efecto, "herramienta": herr}


_MODERNO = {}


def moderno(iid):
    """Nombre del objeto en el WoW actual; None si ya no existe alli."""
    if iid in _MODERNO:
        return _MODERNO[iid]
    try:
        d = json.loads(bajar(TT_ITEM % iid, "item_%d.json" % iid))
        n = d.get("name") or None
        # un objeto que el juego actual ya no tiene traducido vuelve con el nombre en
        # ingles entre corchetes ("[Dream Dust]"): ahi manda el nombre de Classic
        # ...o con marcas internas de Blizzard ("[PH] ... [DEP]"), que tampoco son un nombre
        if n and ("[" in n or "]" in n):
            n = None
    except Exception:                                             # noqa: BLE001
        n = None
    _MODERNO[iid] = n
    return n


def main():
    todo, cambios = {}, []
    for skill, slug, pid, ver in SKILLS:
        html = bajar(LISTA % (ver, skill, slug), "skill_%s_%d.html" % (ver, skill))
        items = catalogo(html)
        filas = recetas(html)
        print("%-18s %3d recetas   %3d objetos" % (pid, len(filas), len(items)))

        def obj(iid, qty=1):
            iid = int(iid)
            it = items.get(iid) or {}
            clasico = it.get("name") or ("item:%d" % iid)
            act = moderno(iid)
            if act and act != clasico:
                cambios.append((clasico, act))
            return {"id": iid, "name": act or clasico, "classic": clasico,
                    "icon": it.get("icon"), "qty": qty}

        salida = []
        # de que version sale este arbol: las fichas de objeto se piden a la misma
        for n, r in enumerate(filas, 1):
            e = {"spell": r["id"], "name": r["name"], "skill": r.get("learnedat"),
                 "colors": r.get("colors"), "version": ver,
                 "reagents": [obj(i, q) for i, q in (r.get("reagents") or [])]}
            c = r.get("creates")
            if c:
                e["creates"] = obj(c[0], c[1] or 1)
            try:
                e.update(detalle(r["id"], ver))
            except Exception as ex:                               # noqa: BLE001
                e["error"] = str(ex)
            salida.append(e)
            if n % 50 == 0:
                print("     %3d/%d" % (n, len(filas)))
        todo[pid] = salida

    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    io.open(SALIDA, "w", encoding="utf-8").write(json.dumps(todo, ensure_ascii=False, indent=1))
    tot = sum(len(v) for v in todo.values())
    print("\nguardadas %d recetas de %d profesiones en %s" % (tot, len(todo), SALIDA))
    print("objetos renombrados en el WoW actual: %d" % len(set(cambios)))
    for a, b in sorted(set(cambios))[:20]:
        print("   %-38s -> %s" % (a, b))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
