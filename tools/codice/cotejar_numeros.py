# -*- coding: utf-8 -*-
"""Coteja las CIFRAS de cada texto contra las del manual del que salio.

Las erratas de numero son las que mas duelen: un "Sd8" que se lee 5d8, un "+19" donde el
manual dice +10, un nivel cambiado. El texto puede estar perfecto de forma y decir algo
que no es. Los barridos anteriores no miraban esto.

Se comparan solo las cifras que NO cambian entre el libro y el compendio:

  dados        1d8, 2d6, 8d6
  bonos        +2, -5
  niveles      "nivel 5", "5.º nivel"
  cantidades   "hasta 3 criaturas", "2 usos"

Las distancias quedan FUERA a proposito: el manual va en pies y el compendio en metros,
asi que ahi la diferencia es la conversion, no una errata.
"""
import io, os, re, sys, collections

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)

# se reutiliza el indice de fuentes de la fase 1
_src = io.open(os.path.join(BASE, "cotejar_fuentes.py"), encoding="utf-8").read()
_g = {"__file__": os.path.join(BASE, "cotejar_fuentes.py"), "__name__": "x"}
exec(compile(_src[:_src.find("# nombres de rasgo que ya tienen")], "cf", "exec"), _g)

clave, palabras = _g["clave"], _g["palabras"]
FUENTES_CONJUROS, FUENTES, FUENTES_DOTES = _g["FUENTES_CONJUROS"], _g["FUENTES"], _g["FUENTES_DOTES"]
POR_CAPITULO, entradas = _g["POR_CAPITULO"], _g["entradas"]

DADO = re.compile(r"\b(\d*)d(\d+)\b")
BONO = re.compile(r"(?<![\d,.])([+\-]\d+)(?![\d,.])")
NIVEL = re.compile(r"nivel\s+(\d+)|(\d+)\.?[ºo]\s+nivel", re.I)
UNIDAD_DISTANCIA = re.compile(r"\d+[,.]?\d*\s*(?:pies|pie|metros|metro|millas|km)", re.I)


def cifras(t):
    """Multiconjunto de cifras comparables. Las distancias se retiran antes."""
    t = UNIDAD_DISTANCIA.sub(" ", t or "")
    c = collections.Counter()
    for m in DADO.finditer(t):
        c["d" + m.group(2) + "x" + (m.group(1) or "1")] += 1
    for m in BONO.finditer(t):
        c["b" + m.group(1)] += 1
    for m in NIVEL.finditer(t):
        c["n" + (m.group(1) or m.group(2))] += 1
    return c


KB = _g["KB"]
# rasgos que ya tienen ficha propia: el manual los mete dentro de la seccion del padre y
# sus cifras contarian dos veces ("A nivel 13" es del Grimorio de Sacrificio, no de
# Conocimiento Demoniaco)
HERMANOS = collections.defaultdict(set)
for _c in KB["classes"]:
    _k = clave(_c["name"])
    for _f in _c["features"]: HERMANOS[_k].add(clave(_f["name"]))
    for _s in _c["subclasses"]:
        for _f in _s["features"]: HERMANOS[_k].add(clave(_f["name"]))


def _sin_hermanos(ref, nombre, cap):
    if not cap or cap not in HERMANOS: return ref
    trozos, salida = re.split(r"(?m)^\s*#{2,6}\s*", ref), []
    for i, tr in enumerate(trozos):
        titulo = clave(tr.split("\n", 1)[0]) if i else None
        if titulo and titulo in HERMANOS[cap] and titulo != clave(nombre): continue
        salida.append(tr)
    return "\n".join(salida)


def referencia(tipo, nombre, cap):
    if tipo == "conjuro": return FUENTES_CONJUROS.get(clave(nombre))
    if tipo == "dote": return FUENTES_DOTES.get(clave(nombre))
    if cap: return _sin_hermanos(POR_CAPITULO.get(cap, {}).get(clave(nombre)) or "", nombre, cap)
    return FUENTES.get(clave(nombre))


avisos, cotejados = [], 0
for tipo, nombre, texto, cap in entradas:
    if len(texto) < 150: continue
    ref = referencia(tipo, nombre, cap)
    if not ref or len(ref) < 150: continue
    # si el texto se aparta mucho del manual, la comparacion de cifras no dice nada
    if abs(len(palabras(texto)) - len(palabras(ref))) > max(60, len(palabras(ref)) * 0.5): continue
    cotejados += 1
    a, b = cifras(texto), cifras(ref)
    faltan = b - a
    sobran = a - b
    if not faltan and not sobran: continue
    def fmt(c):
        return ", ".join(("%s x%d" % (k, v)) if v > 1 else k for k, v in sorted(c.items()))
    avisos.append((tipo, nombre, fmt(faltan), fmt(sobran)))

# Las dos direcciones a la vez es lo que delata una cifra CAMBIADA. Que el manual tenga
# un numero de mas suele ser que su OCR quedo mejor; que lo tenga el compendio, que aqui
# ya se corrigio ("Sd8" del manual frente a nuestro 5d8, "+19" frente a +10).
sustituciones = [a for a in avisos if a[2] and a[3]]
solo_manual = [a for a in avisos if a[2] and not a[3]]
solo_aqui = [a for a in avisos if a[3] and not a[2]]

print("entradas con cifras cotejadas: %d" % cotejados)
print("cifras CAMBIADAS (el manual dice una cosa y el compendio otra): %d" % len(sustituciones))
for tipo, nombre, faltan, sobran in sustituciones:
    print("   %-20s %-28s manual: %-22s aqui: %s" % (tipo[:19], nombre[:27], faltan[:21], sobran[:26]))
print("\nsolo en el manual (posible perdida): %d" % len(solo_manual))
for tipo, nombre, faltan, _ in solo_manual[:12]:
    print("   %-20s %-28s %s" % (tipo[:19], nombre[:27], faltan[:40]))
print("\nsolo en el compendio (normalmente ya corregido aqui): %d" % len(solo_aqui))
for tipo, nombre, _, sobran in solo_aqui[:12]:
    print("   %-20s %-28s %s" % (tipo[:19], nombre[:27], sobran[:40]))
