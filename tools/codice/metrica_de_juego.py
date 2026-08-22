# -*- coding: utf-8 -*-
"""Unifica las distancias del compendio con el redondeo que se usa en la mesa.

Conviven dos conversiones de la misma medida: la ficha dice "9 metros" donde el cuerpo del
conjuro dice "9,1 metros", porque una viene del redondeo que usa el addon (y el manual en
castellano) y la otra de convertir 30 pies al milimetro. Son 33 conjuros que se contradicen
consigo mismos.

Manda el redondeo de juego, que es el que se usa al medir en la mesa y el que ya traen los
campos de la ficha. La tabla es la equivalencia estandar de 5e, no un redondeo inventado:
cada valor exacto solo se sustituye si corresponde a una medida en pies de las que el
manual utiliza.
"""
import re

# pies -> (conversion exacta que aparece en el texto, medida de juego)
EQUIVALENCIAS = {
    "0,3": "0,3",       # 1 pie, se deja
    "0,6": "0,6",
    "0,9": "0,9",
    "1,5": "1,5",       # 5 pies
    "3": "3",           # 10
    "4,6": "4,5",       # 15
    "6,1": "6",         # 20
    "7,6": "7,5",       # 25
    "9,1": "9",         # 30
    "12,2": "12",       # 40
    "13,7": "13,5",     # 45
    "15,2": "15",       # 50
    "18,3": "18",       # 60
    "21,3": "21",       # 70
    "22,9": "22,5",     # 75
    "24,4": "24",       # 80
    "27,4": "27",       # 90
    "30,5": "30",       # 100
    "36,6": "36",       # 120
    "45,7": "45",       # 150
    "61": "60",         # 200
    "91,4": "90",       # 300
    "121,9": "120",     # 400
    "152,4": "150",     # 500
    "304,8": "300",     # 1.000
    "1.524": "1.500",   # 5.000
}
_CAMBIA = {k: v for k, v in EQUIVALENCIAS.items() if k != v}
_PAT = re.compile(r"(?<![\d,.])(" + "|".join(sorted((re.escape(k) for k in _CAMBIA),
                                                    key=len, reverse=True)) +
                  r")(?=\s*(?:metros|m)\b)")

CAMPOS = ("description", "mechanics", "range", "roleNotes", "desc", "extras", "suggested")


def _textos(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if isinstance(v, str) and k in CAMPOS:
                yield o, k, v
            else:
                for x in _textos(v):
                    yield x
    elif isinstance(o, list):
        for v in o:
            for x in _textos(v):
                yield x


def aplicar(kb):
    """Devuelve cuantas medidas se han unificado."""
    n = 0
    for obj, campo, valor in _textos(kb):
        nuevo, k = _PAT.subn(lambda m: _CAMBIA[m.group(1)], valor)
        if k:
            n += k
            obj[campo] = nuevo
    return n


if __name__ == "__main__":
    import io
    import json
    import os
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    BASE = os.path.dirname(os.path.abspath(__file__))
    kb = json.load(io.open(os.path.join(BASE, "kb_icons.json"), encoding="utf-8"))
    print("medidas unificadas: %d" % aplicar(kb))
