# -*- coding: utf-8 -*-
"""Pasa las fichas de personaje de la web por la misma vara que el compendio.

`js/characters.js` se escribe a mano y nunca habia pasado por la revision: seguia en
pies mientras el resto del sitio va en metrico, usaba "ranura de conjuro" y
"Desengancharse" en vez de la terminologia del glosario, y traia un `**negrita**` de
markdown que el marcado de estas fichas (TRP3: {col}, {h3}, {icon}) no entiende y que
salia con los asteriscos a la vista.

Se trabaja cadena a cadena, no sobre el fichero entero, para no tocar claves ni codigo.
Sin --apply solo informa.
"""
import io, os, re, sys

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
from terminologia import normalizar_habilidades
from metrico import a_metrico

FICHERO = r"C:/Users/marco/Documents/harfordweb/js/characters.js"
CADENA = re.compile(r'"((?:[^"\\]|\\.)*)"')


def arregla(txt):
    # el marcado de estas fichas no tiene negrita: los asteriscos se veian tal cual
    txt = re.sub(r"\*\*([^*\n]{2,60})\*\*", r"\1", txt)
    return normalizar_habilidades(a_metrico(txt))


d = io.open(FICHERO, encoding="utf-8", newline="").read()
piezas, cursor, cambios = [], 0, []
for m in CADENA.finditer(d):
    crudo = m.group(1)
    if len(crudo) < 12 or " " not in crudo:
        continue
    real = crudo.replace('\\"', '"').replace("\\n", "\n")
    nuevo = arregla(real)
    if nuevo == real:
        continue
    esc = nuevo.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    piezas.append(d[cursor:m.start(1)]); piezas.append(esc); cursor = m.end(1)
    for i in range(min(len(real), len(nuevo))):
        if real[i] != nuevo[i]:
            cambios.append((real[max(0, i-34):i+26].replace("\n", " "),
                            nuevo[max(0, i-34):i+30].replace("\n", " ")))
            break
piezas.append(d[cursor:])

print("cadenas corregidas: %d" % len(cambios))
for a, b in cambios[:18]:
    print("   antes : %s\n   ahora : %s" % (a[:66], b[:66]))
if "--apply" in sys.argv:
    io.open(FICHERO, "w", encoding="utf-8", newline="").write("".join(piezas))
    print("\nESCRITO:", FICHERO)
