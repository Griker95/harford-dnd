# -*- coding: utf-8 -*-
"""Completa HarfordDnDBook.lua con los rasgos de clase que el libro nombra y el addon no.

El addon llegaba al nivel 6; el libro trae la tabla entera hasta el 20. De cada rasgo que
falta se toma su texto de la seccion del libro que lo describe, DENTRO del capitulo de su
clase: hay nombres que se repiten entre clases y buscarlos por todo el libro traeria el
texto equivocado.

Solo ANADE. No toca ni un rasgo existente, y deja fuera:
  - los genericos de la tabla ("Mejora de Caracteristica", "Rasgo de ...");
  - los que no tienen seccion propia, que van a un informe aparte para revisarlos a mano.

Sin --apply solo informa.
"""
import io
import json
import os
import re
import sys
import difflib
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")   # aqui vive metrico.py
import tabla_clases_libro1 as T                                   # noqa: E402
from limpieza import limpiar                                      # noqa: E402
from metrico import a_metrico                                     # noqa: E402

LIBRO = T.LIBRO
LUA = r"C:/Users/marco/Documents/New project/Harford/DnD/Data/HarfordDnDBook.lua"
GENERICO = re.compile(r"(?i)^(mejora de (puntuacion de )?caracteristica|rasgo de |caracteristica de |caracteristica del |—|conjuros? |lanzamiento de )")

src = io.open(LIBRO, encoding="utf-8", errors="ignore").read()
lua = io.open(LUA, encoding="utf-8", newline="").read()


def slug(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"_+", "_", re.sub(r"[^a-z0-9]+", "_", s.lower())).strip("_")[:34]


def capitulo(clase):
    """(inicio, fin) del capitulo de la clase.

    El capitulo es "## <Clase>" y DENTRO tiene mas encabezados de segundo nivel ("## Rasgos
    de Clase", "## Presencia Maligna"...), asi que no vale cortar en el siguiente "##": se
    corta en el siguiente que sea OTRA clase, o en el siguiente capitulo.
    """
    m = re.search(r"(?m)^##\s+" + re.escape(clase) + r"\s*$", src, re.I)
    if not m:
        return None
    for s in re.finditer(r"(?m)^(#{1,2})\s+(.+?)\s*$", src[m.end():]):
        titulo = T.nk(s.group(2))
        if len(s.group(1)) == 1 or (titulo in T.CLASES and titulo != T.nk(clase)):
            return (m.end(), m.end() + s.start())
    return (m.end(), len(src))


def seccion(rango, nombre):
    """Texto de la seccion `nombre` dentro del tramo dado."""
    if not rango:
        return None
    a, b = rango
    trozo = src[a:b]
    pat = re.compile(r"(?m)^(#{3,6})\s+\**\s*" + re.escape(nombre) + r"\s*\**\s*$", re.I)
    m = pat.search(trozo)
    if not m:
        # el titulo puede llevar un sufijo entre parentesis o un adorno
        pat = re.compile(r"(?m)^(#{3,6})\s+\**\s*" + re.escape(nombre) + r"[^\n]{0,24}$", re.I)
        m = pat.search(trozo)
    if not m:
        # el libro escribe el mismo rasgo con otro nombre ("Sentidos Agudizados" frente a
        # "Sentidos Aguzados", "Formulas de Cantrips" frente a "Formulas de Trucos"), asi
        # que como ultimo recurso se busca el titulo mas parecido DENTRO del capitulo
        titulos = [(mm, T.nk(mm.group(2))) for mm in
                   re.finditer(r"(?m)^(#{3,6})\s+(.+?)\s*$", trozo)]
        cerca = difflib.get_close_matches(T.nk(nombre), [x[1] for x in titulos], 1, 0.8)
        if not cerca:
            return None
        m = next(mm for mm, k in titulos if k == cerca[0])
    if not m:
        return None
    nivel = len(m.group(1))
    sig = re.compile(r"(?m)^#{1," + str(nivel) + r"}\s+\S").search(trozo, m.end())
    return trozo[m.end():sig.start() if sig else len(trozo)].strip()


def limpio(t):
    # una tabla dentro del texto del rasgo no es su descripcion: es la tabla de la clase,
    # que empieza justo despues. Se corta ahi antes de nada.
    t = re.split(r"(?m)^[ 	]*\|", t or "")[0]
    t = re.sub(r"(?m)^_{3,}\s*$", "", t)
    t = re.sub(r"(?m)^[>\s]*#{1,6}\s*", "", t)
    t = re.sub(r"\s*\n\s*", " ", t)
    t = re.sub(r"\s{2,}", " ", t).strip()
    return a_metrico(limpiar(t))


def recortar(t, tope=900):
    """Corta por final de frase: cortar a mitad deja el rasgo diciendo algo incompleto."""
    if len(t) <= tope:
        return t
    corte = t.rfind(". ", 0, tope)
    return (t[:corte + 1] if corte > tope // 2 else t[:tope]).strip()


def bloque_features(clase_id):
    """(inicio, fin) del `features = {` de la CLASE (no de sus subclases)."""
    i = lua.find('id = "%s"' % clase_id)
    if i < 0:
        return None
    j = lua.find("\n        features = {", i)
    if j < 0:
        return None
    ini = j + len("\n        features = {")
    prof, k = 1, ini
    while k < len(lua) and prof:
        if lua[k] == "{":
            prof += 1
        elif lua[k] == "}":
            prof -= 1
        k += 1
    return (ini, k - 1)


def main():
    kbp = os.path.join(BASE, "kb.json")
    kb = json.load(io.open(kbp, encoding="utf-8"))
    tablas = {T.nk(k): v for k, v in T.leer().items()}
    nuevos, sin_texto = {}, []
    for c in kb["classes"]:
        filas = tablas.get(T.nk(c["name"]))
        if not filas:
            continue
        rango = capitulo(c["name"])
        tiene = {T.nk(f["name"]) for f in c["features"]}
        tiene |= {T.nk(f["name"]) for s in c["subclasses"] for f in s["features"]}
        for lv in sorted(filas):
            for nombre in filas[lv]["rasgos"]:
                k = T.nk(nombre)
                if k in tiene or GENERICO.match(k):
                    continue
                tiene.add(k)
                txt = seccion(rango, nombre)
                if not txt or len(txt) < 40:
                    sin_texto.append((c["name"], lv, nombre))
                    continue
                nuevos.setdefault(c["id"], []).append(
                    {"id": "%s_%s" % (c["id"][:12], slug(nombre)), "level": lv,
                     "name": nombre, "desc": recortar(limpio(txt))})
    tot = sum(len(v) for v in nuevos.values())
    print("rasgos nuevos con texto del libro: %d" % tot)
    for cid, v in nuevos.items():
        print("   %-22s %d" % (cid, len(v)))
    print("\nsin seccion propia (a revisar a mano): %d" % len(sin_texto))
    for a, b, c2 in sin_texto[:15]:
        print("   %-22s nv%-2d %s" % (a[:21], b, c2))

    if "--apply" not in sys.argv:
        return
    global lua
    escrito = 0
    for cid, items in sorted(nuevos.items(), key=lambda kv: -(bloque_features(kv[0]) or (0, 0))[1]):
        r = bloque_features(cid)
        if not r:
            print("  sin bloque de features:", cid)
            continue
        ini, fin = r
        lineas = []
        for it in items:
            lineas.append('            { id = "%s", level = %d, name = "%s", type = "informativo", '
                          'description = "%s", effects = {} },'
                          % (it["id"], it["level"], it["name"].replace('"', "'"),
                             it["desc"].replace("\\", "").replace('"', "'")))
            escrito += 1
        lua = lua[:fin] + "\n".join(lineas) + "\n        " + lua[fin:]
    io.open(LUA, "w", encoding="utf-8", newline="").write(lua)
    print("\nrasgos escritos en el addon: %d" % escrito)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
