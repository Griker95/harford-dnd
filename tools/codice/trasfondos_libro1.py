# -*- coding: utf-8 -*-
"""Trasfondos propios del Libro 1 (Warcraft 5ª) que no existen en el addon.

El capitulo "Nuevos Trasfondos" los define con sus campos en negrita
(**Competencias en habilidades:**, **Equipo:**...) y su rasgo como
"#### Caracteristica: <nombre>". Se exponen con la misma forma que los del kb.
"""
import io, os, re, sys, unicodedata

SP = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SP)
import libro1

CAMPOS = [("Competencias en habilidades", "Competencias"),
          ("Competencia con herramientas", "Competencia con herramientas"),
          ("Competencias con herramientas", "Competencia con herramientas"),
          ("Idiomas", "Idioma"), ("Idioma", "Idioma"), ("Equipo", "Equipo")]

def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", s.lower())).strip()

def slug(s):
    return re.sub(r"[^a-z0-9]+", "_", nk(s)).strip("_")

def _capitulo():
    s = libro1.src()
    m = re.search(r"^#\s*Cap[ií]tulo\s*\d+\s*:\s*Nuevos Trasfondos\s*$", s, re.M | re.I)
    if not m: return s, 0, 0
    fin = len(s)
    m2 = re.search(r"^#\s+\S", s[m.end():], re.M)
    if m2: fin = m.end() + m2.start()
    return s, m.end(), fin

def trasfondos():
    s, a, b = _capitulo()
    if not b: return []
    tramo = s[a:b]
    marcas = list(re.finditer(r"^###\s+(.+)$", tramo, re.M))
    out = []
    for i, m in enumerate(marcas):
        fin = marcas[i+1].start() if i + 1 < len(marcas) else len(tramo)
        cuerpo = tramo[m.end():fin]
        nombre = m.group(1).strip()
        # intro: hasta el primer campo en negrita
        mc = re.search(r"^\s*\*\*", cuerpo, re.M)
        intro = (cuerpo[:mc.start()] if mc else cuerpo).strip()
        intro = re.sub(r"\n#{1,6}\s*", "\n### ", intro)
        traits = []
        for etiqueta, visible in CAMPOS:
            mm = re.search(r"\*\*" + re.escape(etiqueta) + r":?\*\*\s*(.+)", cuerpo)
            if mm and not any(t["name"] == visible for t in traits):
                traits.append({"id": slug(nombre) + "_" + slug(visible), "level": None,
                               "name": visible, "type": "informativo",
                               "desc": mm.group(1).strip()})
        # rasgo propio: "#### Caracteristica: <nombre>"
        mr = re.search(r"^####\s*Caracter[ií]stica:\s*(.+)$", cuerpo, re.M)
        if mr:
            ini = mr.end()
            mf = re.search(r"^#{1,6}\s+\S", cuerpo[ini:], re.M)
            texto = cuerpo[ini: ini + (mf.start() if mf else len(cuerpo))].strip()
            if texto:
                traits.append({"id": slug(nombre) + "_caracteristica", "level": None,
                               "name": "Caracteristica: " + mr.group(1).strip(),
                               "type": "informativo", "desc": texto})
        if traits:
            out.append({"id": slug(nombre), "name": nombre, "desc": intro,
                        "traits": traits, "source": "Warcraft 5ª"})
    return out

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    d = trasfondos()
    print("trasfondos del Libro 1: %d" % len(d))
    for b in d:
        print("   %-26s intro=%4d  campos=%s" % (b["name"][:25], len(b["desc"]),
                                                 [t["name"] for t in b["traits"]]))
