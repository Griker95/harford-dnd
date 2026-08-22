# -*- coding: utf-8 -*-
"""Estacion que exige cada receta: yunque, forja, fuego de cocina...

No es una herramienta que se lleve encima sino algo que hay que tener DELANTE, asi que en
mesa un NPC o un spark puede hacer de sustituto. Por eso se guarda aparte de `tools`.

El dato solo esta en la ficha de cada receta —ni en el listado de la profesion ni en el
tooltip— y Wowhead corta el raspado enseguida: hay que ir en tandas cortas desde el
navegador, y de ahi que esto sea un acumulador y no un extractor de una pasada.

    python estaciones.py            informe: cuanto llevamos y por profesion
    python estaciones.py siguiente  imprime los ids de la proxima tanda, listos para el JS
    python estaciones.py guardar "id=Y,id=-,..."   apunta lo que devolvio la tanda

Codigos: Y yunque · F forja · N forja negra · C fuego de cocina · A alambique · - ninguna
"""
import io
import json
import os
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
RECETAS = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")
OBJETOS = os.path.join(BASE, "cotejo", "objetos_wowhead.json")
SALIDA = os.path.join(BASE, "cotejo", "estaciones.json")
TANDA = 20                       # lo que cabe en una llamada del navegador sin agotar los 30 s

NOMBRE = {"Y": "Yunque", "F": "Forja", "N": "Forja Negra", "C": "Fuego de cocina",
          "A": "Alambique", "-": None}


def pendientes():
    """[(profesion, version, spell)] de lo que entra en el compendio y aun no se ha mirado."""
    r = json.load(io.open(RECETAS, encoding="utf-8"))
    o = json.load(io.open(OBJETOS, encoding="utf-8"))
    hecho = cargar()
    fuera = {11447}
    out = []
    for p, v in r.items():
        for x in v:
            s = x.get("skill") or ((x.get("colors") or [0])[0]) or 0
            if s > 300 or x["spell"] in fuera:
                continue
            c = x.get("creates") or {}
            if (o.get(str(c.get("id"))) or {}).get("sod"):
                continue
            if str(x["spell"]) in hecho:
                continue
            out.append((p, x.get("version") or "classic", x["spell"]))
    return out


def cargar():
    if os.path.exists(SALIDA):
        return json.load(io.open(SALIDA, encoding="utf-8"))
    return {}


def guardar(d):
    io.open(SALIDA, "w", encoding="utf-8").write(json.dumps(d, ensure_ascii=False, indent=1))


def informe():
    r = json.load(io.open(RECETAS, encoding="utf-8"))
    hecho = cargar()
    pend = pendientes()
    total = len(hecho) + len(pend)
    print("comprobadas %d de %d   (faltan %d, %d tandas)"
          % (len(hecho), total, len(pend), (len(pend) + TANDA - 1) // TANDA))
    # reparto por profesion
    dep = {}
    for p, v in r.items():
        for x in v:
            dep[str(x["spell"])] = p
    por = {}
    for sid, cod in hecho.items():
        p = dep.get(sid, "?")
        por.setdefault(p, {}).setdefault(cod, 0)
        por[p][cod] += 1
    faltan = {}
    for p, _, _ in pend:
        faltan[p] = faltan.get(p, 0) + 1
    print()
    for p in sorted(set(list(por) + list(faltan))):
        vis = ", ".join("%s %d" % (NOMBRE.get(k) or "ninguna", n)
                        for k, n in sorted(por.get(p, {}).items()))
        print("  %-20s %-46s pendientes %d" % (p, vis or "-", faltan.get(p, 0)))


def siguiente():
    pend = pendientes()
    if not pend:
        print("no queda nada por comprobar")
        return
    ver = pend[0][1]
    lote = [s for p, v, s in pend if v == ver][:TANDA]
    print("version:", ver, " profesion:", pend[0][0])
    print(json.dumps(lote))


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "siguiente":
        siguiente()
    elif len(sys.argv) > 2 and sys.argv[1] == "guardar":
        d = cargar()
        n = 0
        for par in sys.argv[2].split(","):
            par = par.strip()
            if not par or "=" not in par:
                continue
            sid, cod = par.split("=", 1)
            d[sid.strip()] = cod.strip() or "-"
            n += 1
        guardar(d)
        print("apuntadas %d   total %d" % (n, len(d)))
    else:
        informe()


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
