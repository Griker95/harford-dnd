# -*- coding: utf-8 -*-
"""Repone el grupo \\1 que la shell se comio al insertar la regla de la cursiva."""
import io, sys

sys.stdout.reconfigure(encoding="utf-8")
P = "limpieza.py"
t = io.open(P, encoding="utf-8").read()
malo = '(re.compile(r"(\\*maldición elemental)(?!\\*)"), r"' + chr(1) + '*"),'
bueno = '(re.compile(r"(\\*maldición elemental)(?!\\*)"), r"\\1*"),'
print("encontrada:", malo in t)
if malo in t:
    io.open(P, "w", encoding="utf-8").write(t.replace(malo, bueno))
    print("corregida")
