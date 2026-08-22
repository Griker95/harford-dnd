# -*- coding: utf-8 -*-
"""Errata en la ficha de Cody: "Sabiduria: 10 (0" se quedo sin cerrar el parentesis.

El resto de caracteristicas de esa misma lista si lo llevan ("Destreza: 10 (0)"), asi que
no hay duda de cual es la forma correcta.
"""
import io, re, sys

sys.stdout.reconfigure(encoding="utf-8")
P = r"C:/Users/marco/Documents/harfordweb/js/characters.js"
d = io.open(P, encoding="utf-8", newline="").read()
patron = re.compile(r"(Sabidur\u00eda: 10 \(0)(?=\\n)")
n = len(patron.findall(d))
print("ocurrencias:", n)
if n:
    io.open(P, "w", encoding="utf-8", newline="").write(patron.sub(r"\1)", d))
    print("corregido")
