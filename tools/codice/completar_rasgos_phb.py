# -*- coding: utf-8 -*-
"""Trae del Manual del Jugador los rasgos de clase que el Libro 1 nombra pero no describe.

La tabla de progresion del Libro 1 lista rasgos a los que no dedica ninguna seccion, asi
que no habia texto que copiar y la ficha de esas clases se cortaba: el Picaro se quedaba en
el nivel 6. Son rasgos estandar de 5e y el Manual si los describe, unas veces con el mismo
titulo y otras con la traduccion de esa edicion ("Anticipacion" es "Mente escurridiza",
"Esquivo" es "Elusivo").

La lista va a mano, con el nombre del manual al lado, porque emparejar por parecido traia
cosas de otra clase: "Pie Ligero" del picaro caia en el rasgo racial del mediano
piesligeros. El nombre que se guarda es el del Libro 1, que es el que usa la tabla de
progresion de la clase.

Solo ANADE, y nunca sobre un rasgo que ya exista. Sin --apply solo informa.
"""
import io
import os
import re
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
import tabla_clases_libro1 as T                                   # noqa: E402
from limpieza import limpiar                                      # noqa: E402
from metrico import a_metrico                                     # noqa: E402

MD = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/manual_del_jugador.md"
LUA = r"C:/Users/marco/Documents/New project/Harford/DnD/Data/HarfordDnDBook.lua"

# (clase, nivel, nombre en el Libro 1, encabezado en el Manual del Jugador)
RASGOS = [
    ("picaro",   7,  "Evasión",          "EVASIÓN"),
    ("picaro",  15,  "Anticipación",     "MENTE ESCURRIDIZA"),
    ("picaro",  18,  "Esquivo",          "ELUSIVO"),
    ("picaro",  20,  "Golpe de Suerte",  "GOLPE DE SUERTE"),
    ("paladin", 10,  "Aura de Coraje",   "AURA DE CORAJE"),
    ("paladin", 14,  "Toque Purificador", "TOQUE PURIFICADOR"),
]


def seccion(src, titulo):
    """Texto que cuelga de ese encabezado en el manual."""
    m = re.search(r"(?im)^(#{1,6})\s+\**\s*" + re.escape(titulo) + r"\s*\**\s*$", src)
    if not m:
        return None
    fin = re.compile(r"(?m)^#{1,%d}\s+\S" % len(m.group(1))).search(src, m.end())
    return src[m.end():fin.start() if fin else len(src)].strip()


def limpio(t):
    t = re.split(r"(?m)^[ \t]*\|", t or "")[0]
    # el manual abre el parrafo con la inicial en negrita: "**A** nivel 15 has adquirido..."
    t = re.sub(r"^\s*\*{1,3}([A-ZÁÉÍÓÚÑ])\*{1,3}\s*", r"\1 ", t.strip())
    t = re.sub(r"(?m)^[>\s]*#{1,6}\s*", "", t)
    t = re.sub(r"\s*\n\s*", " ", t)
    return a_metrico(limpiar(re.sub(r"\s{2,}", " ", t).strip()))


def recortar(t, tope=900):
    if len(t) <= tope:
        return t
    corte = t.rfind(". ", 0, tope)
    return (t[:corte + 1] if corte > tope // 2 else t[:tope]).strip()


def bloque_features(lua, clase_id):
    i = lua.find('id = "%s"' % clase_id)
    if i < 0:
        return None
    j = lua.find("\n        features = {", i)
    if j < 0:
        return None
    ini = j + len("\n        features = {")
    prof, k = 1, ini
    while k < len(lua) and prof:
        if lua[k] == "{":
            prof += 1
        elif lua[k] == "}":
            prof -= 1
        k += 1
    return (ini, k - 1)


def main():
    src = io.open(MD, encoding="utf-8", errors="ignore").read()
    lua = io.open(LUA, encoding="utf-8", newline="").read()
    nuevos, sin_texto = {}, []
    for clase, lv, nombre, titulo in RASGOS:
        # el nombre se busca DENTRO de su clase: "Evasion" existe tambien en el monje y
        # comprobarlo en todo el fichero hacia que el picaro se quedara sin el suyo
        _r = bloque_features(lua, clase)
        if _r and re.search(r'name = "%s"' % re.escape(nombre), lua[_r[0]:_r[1]]):
            continue
        txt = seccion(src, titulo)
        if not txt or len(txt) < 40:
            sin_texto.append((clase, nombre, titulo))
            continue
        nuevos.setdefault(clase, []).append(
            {"id": "%s_%s" % (clase[:10], T.nk(nombre).replace(" ", "_")),
             "level": lv, "name": nombre, "desc": recortar(limpio(txt))})
    print("rasgos a traer del manual: %d" % sum(len(v) for v in nuevos.values()))
    for clase, items in nuevos.items():
        for it in items:
            print("   %-10s nv%-2d %-22s %s" % (clase, it["level"], it["name"], it["desc"][:60]))
    if sin_texto:
        print("\nsin texto en el manual: %s" % ", ".join(n for _, n, _ in sin_texto))

    if "--apply" not in sys.argv or not nuevos:
        return
    for clase, items in sorted(nuevos.items(),
                               key=lambda kv: -(bloque_features(lua, kv[0]) or (0, 0))[1]):
        r = bloque_features(lua, clase)
        if not r:
            print("  sin bloque de features:", clase)
            continue
        ini, fin = r
        lineas = ['            { id = "%s", level = %d, name = "%s", type = "informativo", '
                  'description = "%s", effects = {} },'
                  % (it["id"], it["level"], it["name"].replace('"', "'"),
                     it["desc"].replace("\\", "").replace('"', "'")) for it in items]
        lua = lua[:fin] + "\n".join(lineas) + "\n        " + lua[fin:]
    io.open(LUA, "w", encoding="utf-8", newline="").write(lua)
    print("\nescritos en el addon: %d" % sum(len(v) for v in nuevos.values()))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
