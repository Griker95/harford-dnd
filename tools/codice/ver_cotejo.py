# -*- coding: utf-8 -*-
"""Muestra lado a lado el texto del compendio y el del manual para una entrada.

Sirve para decidir a mano cada aviso de `cotejar_fuentes.py`: si el compendio se aparta
del manual puede ser un error de extraccion, una adaptacion de Warcraft 5a (que manda) o
que la referencia este mal recortada. Solo mirandolos se sabe.

Uso: python ver_cotejo.py "Nombre de la entrada" [...]
"""
import io, os, re, sys

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)

src = io.open(os.path.join(BASE, "cotejar_fuentes.py"), encoding="utf-8").read()
g = {"__file__": os.path.join(BASE, "cotejar_fuentes.py"), "__name__": "x"}
exec(compile(src[:src.find("UMBRAL_PARECIDO")], "c", "exec"), g)

indice = {}
for tipo, nombre, texto, cap in g["entradas"]:
    indice.setdefault(g["clave"](nombre), (tipo, nombre, texto, cap))

for arg in sys.argv[1:]:
    k = g["clave"](arg)
    if k not in indice:
        print("== %s: no esta en el compendio" % arg); continue
    tipo, nombre, texto, cap = indice[k]
    ref = None
    if cap: ref = g["POR_CAPITULO"].get(cap, {}).get(k)
    if ref is None: ref = g["FUENTES"].get(k)
    print("=" * 78)
    print("%s  [%s]" % (nombre, tipo))
    print("-" * 78)
    print("COMPENDIO (%d palabras):" % len(g["palabras"](texto)))
    print(re.sub(r"\n{2,}", "\n", texto)[:1400])
    print("-" * 78)
    if ref:
        print("MANUAL (%d palabras):" % len(g["palabras"](ref)))
        print(re.sub(r"\n{2,}", "\n", ref)[:1400])
    else:
        print("MANUAL: sin referencia localizada")
    print()
