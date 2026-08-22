# -*- coding: utf-8 -*-
"""Quita los caracteres de control 0x08/0x01 que se colaron en el fuente.

Vienen de haber generado el parche desde la shell: ahi "\\b" y "\\1" se convierten en el
caracter real en vez de quedarse como escape de regex, y el patron deja de encajar sin
que se note al leerlo.
"""
import io, glob, os, sys

sys.stdout.reconfigure(encoding="utf-8")
tocados = []
for p in glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "*.py")):
    t = io.open(p, encoding="utf-8").read()
    if "\x08" in t or "\x01" in t:
        io.open(p, "w", encoding="utf-8").write(t.replace("\x08", "").replace("\x01", ""))
        tocados.append(os.path.basename(p))
print("ficheros limpiados:", tocados or "ninguno")
