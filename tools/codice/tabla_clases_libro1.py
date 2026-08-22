# -*- coding: utf-8 -*-
"""Lee las tablas de progresion de clase del Libro 1 (niveles 1 a 20).

Cada clase presenta su tabla a su manera, asi que no se puede leer por posicion:

  - el nivel se escribe "1", "1°", "1º" o "1.º";
  - la columna de rasgos esta la tercera en unas y la ultima en otras;
  - hay filas partidas en dos lineas (el Chaman parte "Totemista (2/descanso)," de
    "Afinidad Elemental"), asi que primero hay que volver a juntarlas.

Se identifica cada columna por lo que contiene: el nivel es la primera celda numerica, el
bono de competencia la que tiene "+N" y los rasgos la celda de texto mas larga.
"""
import io
import re
import sys
import unicodedata

LIBRO = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"

# el Brujo titula su tabla sin el articulo, asi que se acepta con y sin el y se valida
# el nombre contra las clases conocidas
_CAB = re.compile(r"^#{4,6}\s+(?:El\s+)?(.+?)\s*$", re.I)
CLASES = {"caballero de la muerte", "cazador de demonios", "druida", "cazador",
          "mago", "monje", "paladin", "sacerdote", "picaro", "chaman",
          "brujo", "guerrero"}
_SEP = re.compile(r"^\|[\s:|-]+\|?$")
# el nivel se numera de todas las maneras: 1, 1°, 1º, 1.º, 1ro, 2do, 4to...
_NIVEL = re.compile(r"^(\d{1,2})\s*[.]?\s*(?:[°º]|ro|do|to|mo|vo|no|er|o)?$", re.I)
_COMP = re.compile(r"^\+\d$")
_LETRAS = re.compile(r"[A-Za-zÁÉÍÓÚáéíóúñ]{3,}")


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", s.lower())).strip()


def _juntar_filas(lineas):
    """Une las filas que el OCR partio en varias lineas."""
    salida, buf = [], None
    for l in lineas:
        s = l.strip()
        if s.startswith("|"):
            if buf is not None:
                salida.append(buf)
            buf = l
        elif buf is not None and s and not s.startswith("#") and "|" in s:
            buf = buf.rstrip() + " " + s
        else:
            if buf is not None:
                salida.append(buf)
                buf = None
            salida.append(l)
    if buf is not None:
        salida.append(buf)
    return salida


def _celdas(linea):
    return [c.strip() for c in linea.strip().strip("|").split("|")]


def leer():
    """{clase: {nivel: {'comp', 'rasgos', 'celdas'}}}

    Se guardan tambien las celdas crudas: los numeros de trucos, conjuros conocidos y
    ranuras van detras de la columna de rasgos y su significado depende de la clase.
    """
    lineas = io.open(LIBRO, encoding="utf-8", errors="ignore").read().split("\n")
    fuera, clase, en_tabla = {}, None, False
    for l in _juntar_filas(lineas):
        m = _CAB.match(l.strip())
        if m and nk(m.group(1)) in CLASES:
            clase = re.sub(r"\s+", " ", m.group(1)).strip()
            en_tabla = False
            continue
        s = l.strip()
        if clase is None:
            continue
        # el Brujo no empieza sus filas con barra, asi que una fila es cualquier linea con
        # barras cuya primera celda sea un nivel
        cel = [c for c in _celdas(l) if c] if "|" in s else []
        es_fila = bool(cel) and bool(_NIVEL.match(cel[0]))
        if not es_fila:
            # la tabla de la clase es la PRIMERA tras su encabezado: al acabarse, se cierra.
            # Sin esto, cualquier tabla posterior del capitulo pisaba sus filas.
            if en_tabla and s and not _SEP.match(s) and "|" not in s:
                clase, en_tabla = None, False
            continue
        en_tabla = True
        nivel = int(_NIVEL.match(cel[0]).group(1))
        comp = next((c for c in cel[1:] if _COMP.match(c)), None)
        # los rasgos son la celda con mas letras: los numeros de espacios y los "—" no cuentan
        texto = [c for c in cel[1:] if _LETRAS.search(c)]
        rasgos = []
        if texto:
            for r in re.split(r"\s*,\s*", max(texto, key=len)):
                r = r.strip(" *")
                if r and r != "—":
                    rasgos.append(r)
        fuera.setdefault(clase, {})[nivel] = {"comp": comp, "rasgos": rasgos, "celdas": cel}
    return fuera


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    d = leer()
    for c in sorted(d):
        niv = sorted(d[c])
        nr = sum(len(v["rasgos"]) for v in d[c].values())
        print("%-24s niveles %2d-%-2d (%2d filas)  %3d rasgos"
              % (c, min(niv), max(niv), len(niv), nr))
