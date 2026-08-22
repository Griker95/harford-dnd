# -*- coding: utf-8 -*-
"""Repaso de las profesiones ya publicadas: cadenas, duplicados y huecos.

Mira el fichero que ve el lector, no los intermedios, porque lo que importa es si el arbol
se sostiene: de donde sale cada material, que profesion depende de cual y si hay recetas
que sobran o se pisan.
"""
import io
import json
import os
import re
import sys
from collections import defaultdict

WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-professions.js"


def cargar():
    t = io.open(WEB, encoding="utf-8").read()
    i = t.find("professions = ")
    prof = json.loads(t[t.find("[", i):t.find("];", i) + 1])
    j = t.find("professionItems = ")
    fichas = json.loads(t[t.find("{", j):t.rfind(";")])
    return prof, fichas


def main():
    prof, fichas = cargar()
    con = [p for p in prof if p.get("recipes")]
    vacias = [p for p in prof if p.get("wow") and not p.get("recipes")]

    produce = defaultdict(set)
    for p in con:
        for r in p["recipes"]:
            if r.get("output"):
                produce[r["output"]["name"]].add(p["name"])

    print("profesiones con recetas: %d   sin recetas: %d (%s)"
          % (len(con), len(vacias), ", ".join(p["name"] for p in vacias)))
    print("recetas: %d" % sum(len(p["recipes"]) for p in con))

    # --- de donde sale cada material ---
    usa = defaultdict(set)
    for p in con:
        for r in p["recipes"]:
            for m in (r.get("materials") or []):
                usa[m["name"]].add(p["name"])
    delmundo = sorted(m for m in usa if m not in produce)
    print("\nmateriales distintos: %d   los da otra receta: %d   salen del mundo: %d"
          % (len(usa), len(usa) - len(delmundo), len(delmundo)))

    # --- quien depende de quien ---
    print("\ncadena entre profesiones")
    for p in con:
        dep = defaultdict(int)
        for r in p["recipes"]:
            for m in (r.get("materials") or []):
                for o in produce.get(m["name"], ()):
                    if o != p["name"]:
                        dep[o] += 1
        if dep:
            print("  %-20s <- %s" % (p["name"], ", ".join(
                "%s (%d)" % (k, v) for k, v in sorted(dep.items(), key=lambda kv: -kv[1]))))

    # --- recetas que se pisan: mismo nombre y mismo resultado ---
    print("\nrecetas repetidas (mismo nombre y mismo resultado)")
    n = 0
    for p in con:
        vistas = defaultdict(list)
        for r in p["recipes"]:
            if r.get("output"):
                vistas[(r["name"], r["output"]["name"])].append(r)
        for (nom, _), v in vistas.items():
            if len(v) > 1:
                n += 1
                det = " | ".join("hab %s, %s" % (x.get("skillReq"), x.get("source")) for x in v)
                print("  %-16s %-38s %s" % (p["name"], nom[:38], det))
    if not n:
        print("  ninguna")

    # --- lo que un jugador no podria fabricar nunca: material sin origen conocido ---
    huerfanos = [m for m in delmundo if m.startswith("Pergamino: ")]
    if huerfanos:
        print("\npergaminos de encantamiento que nadie fabrica: %d (correcto: son el"
              " resultado, no un material)" % len(huerfanos))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
