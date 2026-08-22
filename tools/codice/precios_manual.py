# -*- coding: utf-8 -*-
"""Precio y peso de las armas y armaduras, leidos de las tablas del Manual del Jugador.

El compendio saca las armas y las armaduras del addon, que no guarda ni lo que cuestan ni
lo que pesan, asi que sus fichas eran las unicas del equipo sin esos dos datos. El manual
si los da, en las tablas del capitulo de equipo.

El OCR de esas tablas es malo de una forma constante y por eso se puede corregir: la ele
minuscula ocupa el lugar del uno ("l po", "ld6", "llb") y la unidad de peso aparece como
"lb", "1b" o "21b" pegada a la cifra. Lo que no encaje con la forma esperada se descarta:
un precio raro es peor que un hueco.
"""
import io
import re
import unicodedata

MD = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/manual_del_jugador.md"

# el OCR confunde estos caracteres dentro de las cifras
_CIFRA = str.maketrans({"l": "1", "I": "1", "O": "0", "o": "0"})
_PRECIO = re.compile(r"^([\dlIoO]+(?:[.,][\dlIoO]+)?)\s*(pc|pp|pe|po|pl)$", re.I)
_PESO = re.compile(r"^([\dlIoO]+(?:\s*/\s*[\dlIoO]+)?)\s*(?:1|l)?b$", re.I)
_FILA = re.compile(r"^\s*\|([^|]{3,40})\|([^|]{0,14})\|([^|]{0,40})\|([^|]{0,14})\|")

LIBRA_EN_GRAMOS = 454


def _nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", s.lower())).strip()


def _precio(txt):
    t = re.sub(r"\s+", " ", (txt or "").strip())
    t = re.sub(r"(?<=\d)\s+(?=p[cpeol])", " ", t)
    m = _PRECIO.match(t.replace(" ", " ").strip())
    if not m:
        m = _PRECIO.match(re.sub(r"(\d)([a-z]{2})$", r"\1 \2", t, flags=re.I))
    if not m:
        return None
    cifra = m.group(1).translate(_CIFRA)
    if not re.match(r"^\d+(?:[.,]\d+)?$", cifra):
        return None
    return "%s %s" % (cifra, m.group(2).lower())


def _peso(txt):
    """Peso en gramos o kilos a partir de la columna del manual.

    La unidad se quita por el final y no con una expresion, porque el OCR la escribe como
    "lb", "1b" o "b" y pegada a la cifra: en "6 1b" el uno es en realidad la ele de libra, y
    leerlo como parte del numero convertia 6 libras en 61.
    """
    t = re.sub(r"\s+", "", (txt or "").strip())
    if not t or not t.lower().endswith("b"):
        return None
    t = t[:-1]                                  # la b de lb
    if len(t) > 1 and t[-1] in "1lI":
        t = t[:-1]                              # la l de lb, que el OCR pasa a 1
    bruto = t.translate(_CIFRA)
    if "/" in bruto:                            # "1/4 lb"
        a, _, b = bruto.partition("/")
        if not (a.isdigit() and b.isdigit()) or int(b) == 0:
            return None
        gramos = round(int(a) / int(b) * LIBRA_EN_GRAMOS)
    elif bruto.isdigit():
        gramos = int(bruto) * LIBRA_EN_GRAMOS
    else:
        return None
    if gramos >= 1000:
        return ("%.1f" % (gramos / 1000.0)).replace(".0", "").replace(".", ",") + " kg"
    return "%d g" % gramos


LIBRO1 = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"

# La tabla del Libro 1 tiene otro formato: columnas vacias de separacion y el peso ya en
# kilos, sin pasar por libras.
_FILA_WC = re.compile(r"^\s*\|([^|]{3,40})\|\s*([\d.,]+\s*p[cpeol])\s*\|\|"
                      r"[^|]*\|\s*([\d.,]+)\s*kg\s*\|", re.I)


def leer_libro1(md=None):
    """{nombre normalizado: (precio, peso)} de las tablas de armas del Libro 1."""
    s = io.open(md or LIBRO1, encoding="utf-8", errors="ignore").read()
    salida = {}
    for linea in s.splitlines():
        m = _FILA_WC.match(linea)
        if not m:
            continue
        nombre = re.sub(r"[*_]", "", m.group(1)).strip()
        if len(_nk(nombre)) < 3:
            continue
        kg = m.group(3).replace(",", ".")
        peso = ("%s kg" % kg.rstrip("0").rstrip(".")).replace(".", ",")
        salida.setdefault(_nk(nombre), (re.sub(r"\s+", " ", m.group(2)).lower(), peso))
    return salida


def leer(md=None):
    """{nombre normalizado: (precio, peso)} de las tablas de equipo del manual."""
    s = io.open(md or MD, encoding="utf-8", errors="ignore").read()
    salida = {}
    for linea in s.splitlines():
        m = _FILA.match(linea)
        if not m:
            continue
        nombre = re.sub(r"[*_]", "", m.group(1)).strip()
        if not nombre or nombre.startswith("-") or len(_nk(nombre)) < 3:
            continue
        precio, peso = _precio(m.group(2)), _peso(m.group(4))
        if precio or peso:
            salida.setdefault(_nk(nombre), (precio, peso))
    return salida


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    d = leer()
    print("entradas con precio o peso en el manual: %d" % len(d))
    for k in sorted(d)[:25]:
        print("   %-30s %-10s %s" % (k, d[k][0] or "-", d[k][1] or "-"))
