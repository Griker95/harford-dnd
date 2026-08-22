# -*- coding: utf-8 -*-
"""Objetos, armas y armaduras extraidos de los LIBROS, con la jerarquia del proyecto.

Warcraft 5ª es el sistema: sus tablas anaden objetos propios (Cajabuzz, Dinamita,
Paracaidas...) y ademas REPRECIAN objetos del PHB ("~~25 po~~ 10 po"). El precio y el
peso del Libro 1 mandan sobre los del Manual del Jugador.

Expone:
    armas()      -> {clave: {name, cost, damage, weight, props, source}}
    objetos()    -> {clave: {name, cost, weight, category, source}}
    descripciones() -> {clave: texto}     (Libro 1 y, de relleno, el PHB)
"""
import io, os, re, sys, unicodedata

SP = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SP)
import libro1

def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", s.lower())).strip()

def _limpia_celda(c):
    """'*~~25 po~~* 10 po' -> '10 po' (el Libro 1 reprecia objetos del PHB)."""
    c = c.strip()
    c = re.sub(r"\*?~~[^~]*~~\*?", "", c).strip()   # quita el precio tachado
    c = re.sub(r"^\*+|\*+$", "", c).strip()
    return re.sub(r"\s{2,}", " ", c)

def _cap_equipo():
    """Tramo del capitulo 'Nuevo Equipamiento': hay varias tablas con el mismo titulo
    repartidas por el libro (p.ej. 'Armas Exoticas' tambien en clases), asi que las
    tablas de equipo se buscan SOLO aqui."""
    s = libro1.src()
    m = re.search(r"^#\s*Cap[ií]tulo\s*\d+\s*:\s*Nuevo Equipamiento\s*$", s, re.M | re.I)
    if not m: return s, 0, len(s)
    fin = len(s)
    m2 = re.search(r"^#\s+\S", s[m.end():], re.M)
    if m2: fin = m.end() + m2.start()
    return s, m.end(), fin

def _filas(tabla_titulo):
    """Filas de una tabla del capitulo de equipo del Libro 1."""
    s, a, b = _cap_equipo()
    m = re.search(r"^#{1,6}\s*" + re.escape(tabla_titulo) + r"\s*$", s[a:b], re.M | re.I)
    if not m: return []
    s = s[a:b]
    out = []
    for linea in s[m.end():].split("\n"):
        l = linea.strip()
        if not l:
            if out: break
            continue
        if not l.startswith("|"):
            if out: break
            continue
        if re.match(r"^\|[\s:|-]+\|?$", l): continue          # separador
        celdas = [_limpia_celda(c) for c in l.strip("|").split("|")]
        celdas = [c for c in celdas if c != ""]
        if not celdas: continue
        out.append(celdas)
    return out

def _es_subtitulo(celdas, cruda):
    return len(celdas) <= 1 or re.match(r"^\*", cruda)

def armas():
    """Armas exoticas del Libro 1: nombre, coste, dano, peso, propiedades."""
    out = {}
    cat = "Exótica"
    for c in _filas("Armas Exóticas"):
        if len(c) < 4:
            if c and re.search(r"distancia", c[0], re.I): cat = "Exótica a distancia"
            elif c and re.search(r"cuerpo a cuerpo", c[0], re.I): cat = "Exótica"
            continue
        nombre = c[0].strip("* ")
        if nk(nombre) in ("nombre", ""): continue
        out[nk(nombre)] = {"name": nombre, "cost": c[1], "damage": c[2],
                           "weight": c[3], "props": c[4] if len(c) > 4 else "",
                           "category": cat, "source": "Warcraft 5ª"}
    return out

def objetos():
    """Equipo y herramientas del Libro 1 (incluye reprecios de objetos del PHB)."""
    out = {}
    for titulo, categoria in (("Nuevo Equipo de Aventurero", "Equipo de aventuras"),
                              ("Nuevas Herramientas", "Herramientas")):
        grupo = categoria
        for c in _filas(titulo):
            if len(c) < 2:
                if c: grupo = c[0].strip("* ")
                continue
            nombre = c[0].strip("* ")
            if nk(nombre) in ("nombre", ""): continue
            n = nk(nombre)
            if re.search(r"balas|flechas|virotes|dardos|municion", n): cat = "Munición"
            elif re.search(r"libram|simbolo|totem|idolo|reliquia", n): cat = "Canalizadores"
            elif re.search(r"herramient|utiles|kit|set de|juego de|instrumento", n): cat = "Herramientas"
            elif re.search(r"bomba|dinamita|granada|pocion|vial|frasco", n): cat = "Consumibles"
            else: cat = categoria
            out[nk(nombre)] = {"name": nombre, "cost": c[1],
                               "weight": c[2] if len(c) > 2 else "—",
                               "category": cat, "source": "Warcraft 5ª"}
    return out

def descripciones():
    return libro1.equipo()

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    a, o, d = armas(), objetos(), descripciones()
    print("Libro 1 -> armas: %d | objetos: %d | descripciones: %d" % (len(a), len(o), len(d)))
    for k, v in list(a.items())[:8]:
        print("   ARMA %-18s %-8s %-16s %-7s %s" % (v["name"][:17], v["cost"], v["damage"], v["weight"], v["props"][:34]))
    for k, v in list(o.items())[:10]:
        print("   OBJ  %-22s %-10s %-8s %s" % (v["name"][:21], v["cost"], v["weight"], v["category"]))
