# -*- coding: utf-8 -*-
"""Saca de los manuales las tablas de personalidad, ideal, vinculo y defecto.

Son las "Caracteristicas sugeridas" de cada trasfondo, y el compendio no tenia ninguna.
El Libro 1 las trae como tablas markdown limpias; el Manual del Jugador, como listas que
el OCR dejo bastante peor. Cada tabla se atribuye al trasfondo cuyo titulo la precede.
"""
import io, re, unicodedata

TIPOS = (("Rasgos de personalidad", r"rasgos? de personalidad"),
         ("Ideales", r"ideal(?:es)?"),
         ("Vínculos", r"v[ií]nculos?"),
         ("Defectos", r"defectos?"))


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]", " ", s.lower()).strip()


def _filas(bloque):
    """Filas de una tabla markdown: se queda con el numero y el texto."""
    out = []
    for linea in bloque.split("\n"):
        if not linea.strip().startswith("|"):
            break
        celdas = [c.strip() for c in linea.strip().strip("|").split("|")]
        celdas = [c for c in celdas if c and not re.fullmatch(r":?-{2,}:?", c)]
        if len(celdas) < 2:
            continue
        num, txt = celdas[0], celdas[-1]
        if not re.fullmatch(r"\d{1,2}", num):
            continue
        out.append((int(num), re.sub(r"\s+", " ", txt).strip()))
    return out


def de_tablas(texto):
    """Devuelve {titulo_de_seccion: {tipo: [(n, texto)]}} para el formato de tabla."""
    # el titulo del trasfondo es el h3; el h4 que hay justo encima de la tabla es siempre
    # el generico "Caracteristicas Sugeridas" y no sirve para atribuirla
    encabezados = [(m.start(), len(m.group(1)), m.group(2))
                   for m in re.finditer(r"(?m)^(#{1,6})\s+(.+?)\s*$", texto)]
    salida = {}
    for etiqueta, patron in TIPOS:
        for m in re.finditer(r"\|\s*d\d+\s*\|[^\n]*?\|\s*" + patron + r"\s*\|[^\n]*\n", texto, re.I):
            filas = _filas(texto[m.end():m.end() + 4000])
            if len(filas) < 3:
                continue
            titulo = ""
            for pos, lvl, t in encabezados:
                if pos >= m.start():
                    break
                if lvl <= 3:
                    titulo = t
            salida.setdefault(titulo, {})[etiqueta] = filas
    return salida


def como_texto(tablas):
    """Las cuatro tablas de un trasfondo, listas para publicar."""
    partes = []
    for etiqueta, _ in TIPOS:
        filas = tablas.get(etiqueta)
        if not filas:
            continue
        partes.append("#### " + etiqueta + "\n\n" +
                      "\n".join("%d. %s" % (n, t) for n, t in sorted(filas)))
    return "\n\n".join(partes)



_ENC_LISTA = None


def de_listas(texto):
    """Formato del Manual del Jugador: encabezado + lista, con el OCR bastante peor.

    Los elementos vienen como "- 2 texto", a veces con el numero en negrita y a veces sin
    numero (el primero, y las continuaciones de una linea partida, que se pegan al
    anterior). La tabla acaba en el siguiente encabezado o en "**Idiomas:**"/"**Equipo:**".
    """
    encabezados = [(m.start(), len(m.group(1)), m.group(2))
                   for m in re.finditer(r"(?m)^(#{1,6})\s+(.+?)\s*$", texto)]
    salida = {}
    for etiqueta, patron in TIPOS:
        cab = re.compile(r"(?im)^#{0,6}\s*\**\s*d(\d+)\s*\**\s*" + patron + r"\s*\**\s*$")
        for m in cab.finditer(texto):
            caras = int(m.group(1))
            filas, n = [], 0
            for linea in texto[m.end():m.end() + 3500].split("\n"):
                s = linea.strip()
                if not s:
                    continue
                if s.startswith("#") or re.match(r"^\*\*(Idiomas|Equipo|Competencias)", s):
                    break
                if not s.startswith("-"):
                    break
                s = s.lstrip("-").strip()
                mm = re.match(r"^\**(\d{1,2})\**\s+(.+)$", s)
                if mm:
                    n = int(mm.group(1)); filas.append((n, mm.group(2).strip()))
                elif filas:
                    # continuacion de la linea anterior, partida por el OCR
                    filas[-1] = (filas[-1][0], filas[-1][1].rstrip() + " " + s)
                else:
                    n = 1; filas.append((1, s))
                if n >= caras:
                    continue
            filas = [(a, re.sub(r"\s+", " ", b).strip()) for a, b in filas]
            # con este OCR la unica garantia es que la tabla este COMPLETA: si el dado es
            # d8 tienen que salir exactamente 8 filas numeradas del 1 al 8. Cuando no
            # cuadra es que se ha comido filas o se ha tragado las de la tabla siguiente,
            # y una tabla mal atribuida es peor que no tenerla.
            if sorted(a for a, _ in filas) != list(range(1, caras + 1)):
                continue
            titulo = ""
            for pos, lvl, tt in encabezados:
                if pos >= m.start():
                    break
                if lvl <= 3 or re.match(r"(?i)^[A-ZÁÉÍÓÚ][^:]{2,34}$", tt):
                    titulo = tt
            salida.setdefault(titulo, {})[etiqueta] = filas
    return salida


if __name__ == "__main__":
    import sys, json
    sys.stdout.reconfigure(encoding="utf-8")
    d = io.open(r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md",
                encoding="utf-8", errors="ignore").read()
    r = de_tablas(d)
    for titulo, t in r.items():
        print("%-34s %s" % (titulo[:33], {k: len(v) for k, v in t.items()}))
