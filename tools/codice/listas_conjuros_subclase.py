# -*- coding: utf-8 -*-
"""Listas de conjuros AMPLIADAS de subclase del Libro 1.

Varias subclases anaden conjuros propios a niveles concretos ("Conjuros de Presencia de
Sangre", "Conjuros de Camino", "Conjuros de Disciplina"). Es una tabla pequena dentro de
la seccion de la subclase: nivel de clase -> conjuros que se obtienen.

Devuelve {(clase, subclase): [{"level": n, "spells": [(nombre, fuente), ...]}, ...]}.
La subclase se identifica por el titulo del libro; el emparejado con el addon lo hace
quien consume esto, que ya lo sabe hacer.
"""
import io
import os
import re
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
import tabla_clases_libro1 as T                                   # noqa: E402

# el marcador de fuente que el libro pone delante del nombre del conjuro
FUENTES = [("✦", "Warcraft 5ª"), ("^XGE^", "Xanathar"), ("^X^", "Xanathar"),
           ("^TCE^", "Tasha"), ("^T^", "Tasha"), ("^EGW^", "Wildemount"),
           ("^W^", "Wildemount")]
_FILA = re.compile(r"^\s*\|\s*(\d{1,2})\s*[.º°o]*\s*\|\s*(.+?)\s*\|\s*$")


def _celdas(linea):
    """Linea de tabla sin las celdas vacias que a veces mete el OCR (| a | | b |)."""
    if "|" not in linea:
        return linea
    partes = [c for c in linea.strip().strip("|").split("|") if c.strip()]
    return "| " + " | ".join(p.strip() for p in partes) + " |" if partes else linea


def _conjuro(txt):
    """(nombre, fuente) de una entrada, quitando cursivas y el marcador de fuente."""
    t = txt.strip().strip("*_ ").strip()
    fuente = "Manual del Jugador"
    for marca, nombre in FUENTES:
        if t.startswith(marca):
            t, fuente = t[len(marca):].strip(), nombre
            break
    t = t.strip("*_ ").strip()
    if not t:
        return None
    return (t[0].upper() + t[1:], fuente)


# la cabecera de una lista ampliada: dos columnas y la segunda son los conjuros. Sin esto
# se cuela la tabla de progresion de la clase, que tambien empieza por el nivel.
_CABECERA = re.compile(r"^\s*\|[^|]*nivel[^|]*\|[^|]*(?:conjuros?|hechizos?)[^|]*\|\s*$", re.I)


def _tabla(cuerpo):
    """Filas nivel -> conjuros de la primera lista ampliada del tramo."""
    if not any(_CABECERA.match(_celdas(l)) for l in cuerpo.splitlines()):
        return []
    salida, visto = [], False
    for linea in cuerpo.splitlines():
        linea = _celdas(linea)
        m = _FILA.match(linea)
        if not m:
            if visto and linea.strip().startswith("|"):
                continue
            if visto and linea.strip() and not linea.strip().startswith("|"):
                break
            continue
        visto = True
        hechizos = [c for c in (_conjuro(x) for x in re.split(r"[,;]", m.group(2))) if c]
        if hechizos:
            salida.append({"level": int(m.group(1)), "spells": hechizos})
    return salida


def leer(src=None):
    src = src or io.open(T.LIBRO, encoding="utf-8", errors="ignore").read()
    salida = {}
    # los capitulos de clase se localizan por su encabezado: T.CLASES solo trae la clave
    # normalizada y aqui hace falta el nombre tal cual lo escribe el libro
    for m in re.finditer(r"(?m)^##\s+(.+?)\s*$", src):
        clase = m.group(1).strip()
        if T.nk(clase) not in T.CLASES:
            continue
        fin = len(src)
        for s in re.finditer(r"(?m)^(#{1,2})\s+(.+?)\s*$", src[m.end():]):
            k = T.nk(s.group(2))
            if len(s.group(1)) == 1 or (k in T.CLASES and k != T.nk(clase)):
                fin = m.end() + s.start()
                break
        trozo = src[m.end():fin]
        # secciones de tercer nivel: cada subclase
        marcas = [(mm.start(), mm.end(), mm.group(1).strip(" *"))
                  for mm in re.finditer(r"(?m)^###\s+(.+?)\s*$", trozo)]
        for i, (a, b, titulo) in enumerate(marcas):
            hasta = marcas[i + 1][0] if i + 1 < len(marcas) else len(trozo)
            filas = _tabla(trozo[b:hasta])
            if filas:
                salida[(clase, titulo)] = filas
    return salida


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    d = leer()
    print("subclases con lista ampliada: %d" % len(d))
    for (c, s), filas in sorted(d.items()):
        print("  %-24s %-28s %s" % (c[:23], s[:27],
                                    " ".join("nv%d:%d" % (f["level"], len(f["spells"]))
                                             for f in filas)))
