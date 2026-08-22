# -*- coding: utf-8 -*-
"""Saca las cuatro tablas de cada trasfondo de los exports de Discord.

En RuleSource/Discord_Export hay una carpeta por trasfondo con la pagina guardada, y ahi
SI estan las "Caracteristicas sugeridas" completas: rasgos de personalidad, ideales,
vinculos y defectos. Es la misma fuente de la que salio bgs_source.json, que se quedo
solo con la descripcion, las competencias y el rasgo.

El texto viene como lineas sueltas: un encabezado, y debajo el numero y el texto en
lineas distintas ("1." y luego la frase). Los mensajes no vienen en orden, asi que cada
tabla se identifica por su encabezado, no por su posicion.
"""
import io, os, re, glob, html, unicodedata

EXPORT = r"C:/Users/marco/Documents/New project/RuleSource/Discord_Export"
ENCABEZADOS = (("Rasgos de personalidad", r"rasgos? de personalidad"),
               ("Ideales", r"ideales?"),
               ("Vínculos", r"v[ií]nculos?"),
               ("Defectos", r"defectos?"))


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]", " ", s.lower()).strip()


def _lineas(carpeta):
    txt = ""
    for f in sorted(glob.glob(os.path.join(carpeta, "*.html"))):
        s = io.open(f, encoding="utf-8", errors="ignore").read()
        s = re.sub(r"<(script|style)\b.*?</\1>", "", s, flags=re.S | re.I)
        txt += html.unescape(re.sub(r"<[^>]+>", "\n", s))
    return [l.strip() for l in txt.split("\n") if l.strip()]


def _tabla(lineas, i):
    """Filas a partir del encabezado: el numero y su texto vienen en lineas distintas.

    Una fila puede ocupar varias lineas: los ideales traen el nombre, el texto y el
    alineamiento por separado ("1." / "Altruismo." / "Uso mi posicion..." / "(Bueno)"),
    asi que se acumula todo hasta el numero siguiente.
    """
    filas, n, buf = [], None, []

    def cerrar():
        if n is not None and buf:
            txt = re.sub(r"\s*\((?:edited|editado)\)\s*$", "", " ".join(buf).strip(), flags=re.I)
            filas.append((n, re.sub(r"\s+", " ", txt).strip()))

    for l in lineas[i + 1:]:
        if re.fullmatch(r"\d{1,2}\.?", l):
            cerrar()
            n, buf = int(l.rstrip(".")), []
            continue
        if n is None:
            break
        # otro encabezado o una marca de mensaje cierran la tabla
        if re.match(r"(?i)^(rasgos? de personalidad|ideales?|v[ií]nculos?|defectos?)$", l):
            break
        if re.match(r"^\d{1,2}/\d{1,2}/\d{4}", l) or l.lower() == "griker":
            break
        # marcas del propio Discord que no son texto de la tabla
        if l.lower() in ("(edited)", "(editado)"):
            continue
        buf.append(l)
    cerrar()
    return filas


def de_carpeta(carpeta):
    lineas = _lineas(carpeta)
    salida = {}
    for etiqueta, patron in ENCABEZADOS:
        for i, l in enumerate(lineas):
            if re.fullmatch(patron, l, re.I):
                filas = _tabla(lineas, i)
                # solo la tabla completa: numeracion seguida desde 1, sin huecos
                if filas and sorted(a for a, _ in filas) == list(range(1, len(filas) + 1)) and len(filas) >= 4:
                    salida[etiqueta] = filas
                break
    return salida


def todas():
    """{slug: {tipo: [(n, texto)]}} para cada carpeta del export."""
    out = {}
    for c in sorted(glob.glob(os.path.join(EXPORT, "*"))):
        if not os.path.isdir(c):
            continue
        t = de_carpeta(c)
        if t:
            out[os.path.basename(c)] = t
    return out


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    r = todas()
    print("carpetas con tablas: %d" % len(r))
    for k, v in r.items():
        print("   %-40s %s" % (k[:39], {a: len(b) for a, b in v.items()}))
