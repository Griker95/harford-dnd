# -*- coding: utf-8 -*-
"""Lee las listas de conjuros por clase del Libro 1.

Las listas estan en sus dos capitulos 6 y cada nombre lleva la marca de donde esta
descrito. La leyenda la da el propio libro:

    (sin marca)   Manual del Jugador
    ✦             Descripciones de Conjuros (de este mismo libro)
    ^XGE^ / ^X^   Guia de Xanathar
    ^TCE^ / ^T^   Caldero de Todo de Tasha
    ^EGW^ / ^W^   Guia de Exploradores de Wildemount

Tres cosas que da el OCR y hay que tener en cuenta:
  - los niveles salen desordenados (Nivel 4, 8, 1, 5...), asi que se lee por encabezado;
  - parte de cada lista vive dentro de un recuadro citado, con "> " delante, incluido el
    apartado "Conjuros Nuevos", que tambien es de la clase;
  - los nombres van unas veces con guion de lista y otras sin el.
"""
import io, re, sys, unicodedata

LIBRO = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"
CLASES = {"caballero de la muerte": "Caballero de la Muerte", "druida": "Druida",
          "mago": "Mago", "paladin": "Paladín", "sacerdote": "Sacerdote",
          "chaman": "Chamán", "brujo": "Brujo", "sutileza": "Pícaro Sutileza",
          "picaro": "Pícaro Sutileza"}
FUENTE_POR_MARCA = {"X": "Xanathar", "T": "Tasha", "E": "Wildemount", "W": "Wildemount",
                    "S": "Costa de la Espada"}
_MARCA = re.compile(r"[\^]([A-Z]{1,5})[\^]")
_NIVEL = re.compile(r"^#{3,6}\s*[*]*\s*(?:Trucos\s*[(]\s*Nivel\s*0\s*[)]"
                    r"|(\d+)\s*[.ºo°]*\s*(?:er|do|to|mo|vo|no)?\s+Nivel"
                    r"|Nivel\s*(\d+))", re.I)
_TITULO = re.compile(r"^#{1,6}\s*(.+?)\s*$")
# encabezados que NO cortan la lista: son parte de ella
_NO_CORTA = re.compile(r"^(conjuros nuevos|conjuros de la clase)$", re.I)


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", s.lower())).strip()


def _limpiar(l):
    """Quita el sangrado de recuadro y el guion de lista, que no son del nombre."""
    s = l.strip()
    while s.startswith(">"):
        s = s[1:].strip()
    return re.sub(r"^[-*•]\s+", "", s).strip()


def leer():
    """{clase: {nivel: [(nombre, fuente)]}}"""
    fuera, clase, nivel = {}, None, None
    for linea in io.open(LIBRO, encoding="utf-8", errors="ignore").read().split("\n"):
        s = _limpiar(linea)
        if not s:
            continue
        m = _NIVEL.match(s)
        if m:
            nivel = int(m.group(1) or m.group(2)) if (m.group(1) or m.group(2)) else 0
            continue
        if s.startswith("#"):
            titulo = _TITULO.match(s).group(1).strip(" *")
            titulo = re.sub(r"^conjuros de\s+", "", titulo, flags=re.I)
            elegida = CLASES.get(nk(titulo))
            if elegida:
                clase, nivel = elegida, None
            elif not _NO_CORTA.match(titulo):
                clase, nivel = None, None
            continue
        if clase is None or nivel is None:
            continue
        fuente = "Manual del Jugador"
        mm = _MARCA.search(s)
        if mm:
            fuente = FUENTE_POR_MARCA.get(mm.group(1)[0], "Manual del Jugador")
            s = _MARCA.sub("", s)
        if "✦" in s:
            fuente = "Warcraft 5ª"
            s = s.replace("✦", "")
        s = re.sub(r"\s+", " ", s.strip(" *·-")).strip()
        # una linea con puntuacion de frase no es un nombre de conjuro
        if not s or len(s) > 46 or re.search(r"[.;:]", s) or not re.search(r"[A-Za-zÁÉÍÓÚáéíóú]", s):
            continue
        fuera.setdefault(clase, {}).setdefault(nivel, []).append((s, fuente))
    return fuera


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    d = leer()
    tot = 0
    for c in sorted(d):
        porn = {k: len(v) for k, v in sorted(d[c].items())}
        n = sum(porn.values()); tot += n
        print("%-24s %3d  %s" % (c, n, porn))
    print("\nentradas totales: %d" % tot)
