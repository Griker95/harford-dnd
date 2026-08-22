# -*- coding: utf-8 -*-
"""Acceso al Libro 1 (Warcraft 5ª), que es EL sistema que usa Harford.

Jerarquia de fuentes (ver CLAUDE.md / AGENTS.md):
  1. Warcraft 5ª  -> el sistema entero: clases, razas, trasfondos, dotes, equipo,
                     objetos, conjuros y reglas adicionales. PREVALECE siempre.
  2. Libro 2 (Heroes of Warcraft, ingles) -> amplia el Libro 1.
  3. PHB / Xanathar / Tasha / Costa de la Espada -> SOLO para lo que el Libro 1 no
                     cubre (sobre todo conjuros y reglas generales de 5e).

Este modulo expone las entradas del Libro 1 por seccion para que los extractores
consulten aqui ANTES de recurrir a los manuales generales.
"""
import io, os, re, unicodedata

MD = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"

def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")

def nk(s):
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", sa(s).lower())).strip()

_src = None
def src():
    global _src
    if _src is None:
        _src = io.open(MD, encoding="utf-8").read().replace("\r", "")
    return _src

def seccion(titulo, niveles=(1, 2, 3)):
    """Texto de la seccion cuyo encabezado coincide con `titulo`, hasta el siguiente
    encabezado de nivel igual o superior."""
    t = src()
    for m in re.finditer(r"^(#{1,6})\s*(.+)$", t, re.M):
        h = nk(m.group(2))
        # los capitulos van titulados "Capitulo 5: Personalizacion"
        h = re.sub(r"^(capitulo|parte|apendice)\s*[a-z0-9]*\s*", "", h).strip()
        if h != nk(titulo): continue
        lvl = len(m.group(1))
        fin = len(t)
        for m2 in re.finditer(r"^(#{1,6})\s*.+$", t[m.end():], re.M):
            if len(m2.group(1)) <= lvl:
                fin = m.end() + m2.start(); break
        return t[m.end():fin].strip()
    return None

BOLD = re.compile(r"\*\*\*\s*([^*\n]+?)\.?\s*\*\*\*\s*(.*?)(?=\n\s*\*\*\*|\n#{1,6}\s|\Z)", re.S)

def entradas(titulo_seccion):
    """Entradas '***Nombre.*** texto' de una seccion -> {nombre_normalizado: texto}."""
    s = seccion(titulo_seccion)
    if not s: return {}
    out = {}
    for m in BOLD.finditer(s):
        nombre, cuerpo = m.group(1).strip(), m.group(2).strip()
        cuerpo = re.sub(r"\n#{1,6}\s*", "\n", cuerpo)
        cuerpo = re.sub(r"\n{3,}", "\n\n", cuerpo).strip()
        if nombre and cuerpo: out.setdefault(nk(nombre), cuerpo)
    return out

def entradas_titulo(titulo_seccion, nivel=3):
    """Entradas escritas como encabezado ('### Mago de Batalla') dentro de una seccion."""
    s = seccion(titulo_seccion)
    if not s: return {}
    out, marcas = {}, list(re.finditer(r"^(#{2,6})\s*(.+)$", s, re.M))
    for i, m in enumerate(marcas):
        if len(m.group(1)) != nivel: continue
        fin = len(s)
        for m2 in marcas[i+1:]:
            if len(m2.group(1)) <= nivel: fin = m2.start(); break
        cuerpo = s[m.end():fin].strip()
        if cuerpo: out.setdefault(nk(m.group(2)), cuerpo)
    return out

def equipo():
    """Objetos del Libro 1: 'Equipo de Aventurero' + 'Armas Exoticas'."""
    d = {}
    for sec in ("Equipo de Aventurero", "Armas Exóticas", "Equipo Inicial"):
        d.update({k: v for k, v in entradas(sec).items() if k not in d})
    return d

def dotes():
    """Dotes del Libro 1: capitulo de Personalizacion y Dotes Raciales."""
    d = {}
    for sec in ("Personalización", "Dotes Raciales", "Dotes"):
        d.update({k: v for k, v in entradas_titulo(sec).items() if k not in d})
        d.update({k: v for k, v in entradas(sec).items() if k not in d})
    return d

if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    eq, do = equipo(), dotes()
    print("Libro 1 -> equipo: %d entradas | dotes: %d entradas" % (len(eq), len(do)))
    for k in list(eq)[:12]: print("   EQ %-26s %s" % (k[:25], eq[k][:60].replace("\n", " ")))
    for k in list(do)[:8]: print("   DO %-26s %s" % (k[:25], do[k][:60].replace("\n", " ")))
