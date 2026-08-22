# -*- coding: utf-8 -*-
"""Deshace el acentuado en los campos `name` y `label`, y solo en ellos.

Reponer tildes en la prosa es una correccion de erratas; hacerlo en un `name` es otra
cosa, porque el addon empareja por ese texto (listas de conjuros, busquedas, ArcSpells).
Como el resto de cambios de la sesion todavia no esta en un commit, no vale con volver a
HEAD: se emparejan los campos uno a uno con la version de HEAD, por orden de aparicion,
y se restaura el valor anterior solo cuando la unica diferencia son las tildes.
"""
import io, re, subprocess, sys, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
RAIZ = r"C:/Users/marco/Documents/New project"
FICHEROS = [
    "Harford/Compendium/HarfordCompendioData.lua",
    "Harford/DnD/Data/HarfordDnDBook.lua",
    "Harford/DnD/Data/HarfordDnDBackgrounds.lua",
    "Harford/DnD/Data/HarfordDnDFeats.lua",
    "Harford/DnD/Data/HarfordDnDData.lua",
]
CAMPO = re.compile(r'\b(name|label) = "((?:[^"\\]|\\.)*)"')


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


for rel in FICHEROS:
    ruta = RAIZ + "/" + rel
    actual = io.open(ruta, encoding="utf-8", newline="").read()
    head = subprocess.run(["git", "show", "HEAD:" + rel], cwd=RAIZ,
                          capture_output=True, text=True, encoding="utf-8").stdout
    if not head:
        print("%s: sin version en HEAD" % rel.split("/")[-1]); continue
    viejos = [m.group(2) for m in CAMPO.finditer(head)]
    if len(viejos) != len(CAMPO.findall(actual)):
        print("%s: el numero de campos cambio, no se toca" % rel.split("/")[-1]); continue
    i, repuestos = 0, 0

    def _rep(m):
        global i, repuestos
        viejo = viejos[i]; i += 1
        nuevo = m.group(2)
        # solo si la diferencia son las tildes: si el texto cambio de verdad, se respeta
        if nuevo != viejo and sa(nuevo) == sa(viejo):
            repuestos += 1
            return m.group(1) + ' = "' + viejo + '"'
        return m.group(0)

    salida = CAMPO.sub(_rep, actual)
    if repuestos:
        io.open(ruta, "w", encoding="utf-8", newline="").write(salida)
    print("%-34s nombres repuestos: %d" % (rel.split("/")[-1], repuestos))
