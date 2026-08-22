# -*- coding: utf-8 -*-
"""Baja las recetas de Encantamiento de Wowhead Classic, una a una.

La lista de la profesion (skill=333) trae el esqueleto: nombre, nivel al que se aprende,
umbrales de color, componentes y el objeto que se crea. Pero el EFECTO del encantamiento
solo esta en la ficha de cada hechizo, asi que despues se pide el tooltip de cada receta.

Se usa el dominio en espanol: los nombres de receta ya vienen traducidos en la lista y los
de los objetos en el bloque `WH.Gatherer.addData(3, 4, ...)` bajo la clave `name_eses`.
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
SALIDA = os.path.join(BASE, "cotejo", "encantamiento_wowhead.json")
LISTA = "https://es.wowhead.com/classic/skill=333/enchanting"
TOOLTIP = "https://nether.wowhead.com/classic/tooltip/spell/%d?locale=6"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

# el certificado de wowhead no valida con el almacen local de este equipo
_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE


def bajar(url):
    req = urllib.request.Request(url, headers=UA)
    return urllib.request.urlopen(req, timeout=60, context=_CTX).read().decode("utf-8", "ignore")


def _array(txt, desde):
    """Recorta el array JSON que empieza en `desde` equilibrando corchetes."""
    prof, k = 0, desde
    while k < len(txt):
        if txt[k] == "[":
            prof += 1
        elif txt[k] == "]":
            prof -= 1
            if prof == 0:
                return txt[desde:k + 1]
        k += 1
    raise ValueError("array sin cerrar")


def _objeto(txt, desde):
    prof, k = 0, desde
    while k < len(txt):
        if txt[k] == "{":
            prof += 1
        elif txt[k] == "}":
            prof -= 1
            if prof == 0:
                return txt[desde:k + 1]
        k += 1
    raise ValueError("objeto sin cerrar")


def catalogo_objetos(html):
    """{id: {'name', 'icon'}} con el nombre en espanol cuando lo hay."""
    items = {}
    for m in re.finditer(r"WH\.Gatherer\.addData\(3,\s*\d+,\s*", html):
        try:
            datos = json.loads(_objeto(html, m.end()))
        except ValueError:
            continue
        for iid, v in datos.items():
            nombre = v.get("name_eses") or v.get("name_enus")
            if not nombre:
                continue
            prev = items.get(int(iid))
            # el mismo objeto aparece en varios bloques; manda el que trae el nombre traducido
            if prev and prev.get("es") and not v.get("name_eses"):
                continue
            items[int(iid)] = {"name": nombre, "icon": v.get("icon"),
                               "es": bool(v.get("name_eses"))}
    return items


def recetas(html):
    i = html.find('id: "recipes"')
    if i < 0:
        raise SystemExit("la pagina no trae el listado de recetas")
    return json.loads(_array(html, html.find("data:", i) + 5))


_TAG = re.compile(r"<[^>]+>")
_COMENT = re.compile(r"<!--.*?-->", re.S)


def _texto(s):
    s = _COMENT.sub("", s)
    s = s.replace("&nbsp;", " ").replace("<br />", " ").replace("<br>", " ")
    s = _TAG.sub("", s)
    s = s.replace("&amp;", "&").replace("&quot;", '"').replace("&#39;", "'")
    return re.sub(r"\s{2,}", " ", s).strip()


def detalle(spell_id):
    """Efecto, herramienta e icono de una receta concreta."""
    d = json.loads(bajar(TOOLTIP % spell_id))
    tt = d.get("tooltip") or ""
    efecto = None
    # los encantamientos describen su efecto en el ultimo <div class="q"> del tooltip
    qs = re.findall(r'<div class="q">(.*?)</div>', tt, re.S)
    if qs:
        efecto = _texto(qs[-1])
    if not efecto:
        # los consumibles (aceites, varas) lo llevan como "Uso:"
        m = re.search(r'<span id="useText1".*?>(.*?)</span>', tt, re.S)
        if m:
            efecto = _texto(m.group(1))
    herr = None
    m = re.search(r"Herramientas:(.*?)(?:Componentes:|$)", tt, re.S)
    if m:
        herr = _texto(m.group(1)) or None
    return {"icon": d.get("icon"), "efecto": efecto, "herramienta": herr,
            "nombre_tooltip": d.get("name")}


def main():
    html = bajar(LISTA)
    items = catalogo_objetos(html)
    filas = recetas(html)
    print("recetas en la lista: %d   objetos con nombre: %d" % (len(filas), len(items)))

    def obj(iid):
        it = items.get(int(iid))
        return {"id": int(iid), "name": it["name"] if it else "item:%s" % iid,
                "icon": it.get("icon") if it else None}

    fuera, faltan = [], 0
    for n, r in enumerate(filas, 1):
        e = {"spell": r["id"], "name": r["name"],
             "skill": r.get("learnedat"), "colors": r.get("colors"),
             "reagents": [dict(obj(i), qty=q) for i, q in (r.get("reagents") or [])]}
        c = r.get("creates")
        if c:
            e["creates"] = dict(obj(c[0]), qty=(c[1] or 1))
        try:
            e.update(detalle(r["id"]))
        except Exception as ex:                                   # noqa: BLE001
            faltan += 1
            e["error"] = str(ex)
        fuera.append(e)
        if n % 20 == 0 or n == len(filas):
            print("  %3d/%d" % (n, len(filas)))
        time.sleep(0.15)

    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    io.open(SALIDA, "w", encoding="utf-8").write(
        json.dumps(fuera, ensure_ascii=False, indent=1))
    sin = [x["name"] for x in fuera if not x.get("efecto")]
    print("\nguardadas %d en %s" % (len(fuera), SALIDA))
    print("sin efecto: %d   con error: %d" % (len(sin), faltan))
    for s in sin[:12]:
        print("   ", s)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
