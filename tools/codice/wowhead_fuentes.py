# -*- coding: utf-8 -*-
"""De donde se aprende cada receta: entrenador, vendedor, botin o mision.

Es el ultimo dato que faltaba de lo importado. En la lista de la profesion no viene, y en el
tooltip tampoco: solo esta en la ficha completa del hechizo, en un listado `taught-by-item`
que nombra la receta fisica (el patron, el plano, la formula) y de donde sale.

Una receta SIN ese listado es de entrenador: se aprende hablando con el, sin objeto de por
medio. Es la unica lectura posible y encaja con el juego.

Se cachea solo lo extraido, no la pagina: son 2.275 fichas de 60 a 180 KB y guardarlas
enteras ocupaba un cuarto de giga para releer cuatro campos.
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
CACHE = os.path.join(BASE, "cotejo", "wowhead_cache", "fuentes")
RECETAS = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")
SALIDA = os.path.join(BASE, "cotejo", "fuentes_wowhead.json")
PAG = "https://es.wowhead.com/%s/spell=%d"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE


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


def extraer(html):
    """La receta fisica que ensena el hechizo, o None si la ensena un entrenador."""
    m = re.search(r"id:\s*'taught-by-item'", html)
    if not m:
        return None
    j = html.find("data:", m.end())
    if j < 0:
        return None
    try:
        datos = json.loads(_cerrar(html, html.find("[", j), "[", "]"))
    except ValueError:
        return None
    if not datos:
        return None
    d = datos[0]
    return {"item": d.get("id"), "name": d.get("name"), "quality": d.get("quality"),
            "skill": d.get("skill"), "source": d.get("source") or [],
            "sourcemore": d.get("sourcemore") or []}


def ficha(spell, ver):
    os.makedirs(CACHE, exist_ok=True)
    p = os.path.join(CACHE, "%s_%d.json" % (ver, spell))
    if os.path.exists(p):
        return json.load(io.open(p, encoding="utf-8"))
    req = urllib.request.Request(PAG % (ver, spell), headers=UA)
    h = urllib.request.urlopen(req, timeout=60, context=_CTX).read().decode("utf-8", "ignore")
    r = extraer(h)
    io.open(p, "w", encoding="utf-8").write(json.dumps(r, ensure_ascii=False))
    time.sleep(0.1)
    return r


def main():
    datos = json.load(io.open(RECETAS, encoding="utf-8"))
    tareas = [(x["spell"], x.get("version") or "classic", pid, x["name"])
              for pid, v in datos.items() for x in v]
    print("recetas: %d" % len(tareas))
    hechas = sum(1 for s, ver, _, _ in tareas
                 if os.path.exists(os.path.join(CACHE, "%s_%d.json" % (ver, s))))
    print("ya en cache: %d   por bajar: %d" % (hechas, len(tareas) - hechas))
    if "--apply" not in sys.argv:
        return

    fuera, err, entrenador = {}, 0, 0
    for n, (s, ver, pid, nombre) in enumerate(tareas, 1):
        try:
            r = ficha(s, ver)
            if r is None:
                entrenador += 1
            fuera[str(s)] = r
        except Exception as ex:                                   # noqa: BLE001
            err += 1
            if err < 8:
                print("   %s (%s): %s" % (nombre, s, ex))
        if n % 200 == 0:
            print("   %4d/%d" % (n, len(tareas)))
    io.open(SALIDA, "w", encoding="utf-8").write(json.dumps(fuera, ensure_ascii=False, indent=1))

    import collections
    c = collections.Counter()
    for r in fuera.values():
        if r is None:
            c["entrenador"] += 1
        else:
            for x in (r["source"] or [0]):
                c["origen %s" % x] += 1
    print("\nguardadas %d   (fallos %d)" % (len(fuera), err))
    for k, v in c.most_common():
        print("   %-14s %4d" % (k, v))
    # una muestra de cada origen, para poder poner nombre a los codigos
    vistos = set()
    for r in fuera.values():
        if not r:
            continue
        for x in r["source"]:
            if x in vistos:
                continue
            vistos.add(x)
            sm = (r["sourcemore"] or [{}])[0]
            print("   codigo %-3s ej: %-42s -> %s" % (x, r["name"][:42], sm.get("n") or sm))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
