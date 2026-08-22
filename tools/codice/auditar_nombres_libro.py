# -*- coding: utf-8 -*-
"""Compara los nombres del compendio con como los escribe el Libro 1.

auditar_nombres.py comprueba que la web sea coherente CONSIGO MISMA. Esto comprueba algo
distinto y mas importante: que lo que llamamos las cosas coincida con el manual, que es
el sistema. Asi salio que la raza se publicaba como "Trol" cuando el libro la titula
"Troll" y la escribe asi 23 veces frente a 9.

Compara solo la grafia (con tildes), no mayusculas ni plurales.
"""
import io, json, os, re, sys, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-data.js"
LIBRO = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


t = io.open(WEB, encoding="utf-8").read()
KB = json.loads(t[t.find("{"):t.rfind("}") + 1])
libro = io.open(LIBRO, encoding="utf-8").read()
palabras = collections.Counter(w for w in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ']{4,}", libro))

# cada nombre canonico frente a como lo escribe el libro
nombres = [c["name"] for c in KB["classes"]]
nombres += [s["name"] for c in KB["classes"] for s in c["subclasses"]]
nombres += [r["name"] for r in KB["races"]]
nombres += [s["name"] for r in KB["races"] for s in (r.get("subraces") or [])]

avisos = 0
print("%-26s %s" % ("compendio", "como lo escribe el Libro 1"))
print("-" * 78)
for n in sorted(set(nombres)):
    # la ultima palabra significativa es la que distingue ("Elfo del Vacio" -> Vacio)
    clave = [w for w in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ']{4,}", n)]
    if not clave:
        continue
    w = clave[-1]
    variantes = {k: v for k, v in palabras.items() if sa(k).rstrip("es") == sa(w).rstrip("es")}
    if not variantes:
        continue
    mejor = max(variantes.items(), key=lambda x: x[1])[0]
    if sa(mejor) == sa(w) and mejor.lower() != w.lower() and sa(mejor) != sa(w):
        continue
    # el plural castellano anade -s o -es: se compara la raiz para no avisar de
    # "Cazadores" frente a "cazador"
    def raiz(x): return sa(x).rstrip("s").rstrip("e")
    if raiz(mejor) != raiz(w):
        avisos += 1
        print("%-26s %-22s (x%d en el libro)  <-- revisar" % (n, mejor, palabras[mejor]))
print("\nnombres que el libro escribe distinto: %d" % avisos)
