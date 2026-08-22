# -*- coding: utf-8 -*-
"""Completa los rasgos de SUBCLASE que el libro describe y el addon no tiene.

Las subclases del addon llegan al nivel 6; el libro las lleva hasta el 20. Cada una tiene
su seccion dentro del capitulo de su clase ("### Presencia de Sangre") y sus rasgos
cuelgan de ella ("#### Golpe al Corazon").

Dos cosas que hay que resolver:
  - el addon llama a la subclase con el nombre corto ("Sangre") y el libro con el largo
    ("Presencia de Sangre"), asi que se emparejan por parecido;
  - el nivel del rasgo no esta en un campo, sino dentro de su propio texto ("A partir del
    nivel 11..."), asi que se lee de ahi y, si no lo dice, el rasgo se deja fuera.

Solo ANADE. Sin --apply solo informa.
"""
import difflib
import io
import json
import os
import re
import sys
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
import tabla_clases_libro1 as T                                   # noqa: E402
from limpieza import limpiar                                      # noqa: E402
from metrico import a_metrico                                     # noqa: E402

LUA = r"C:/Users/marco/Documents/New project/Harford/DnD/Data/HarfordDnDBook.lua"
src = io.open(T.LIBRO, encoding="utf-8", errors="ignore").read()
lua = io.open(LUA, encoding="utf-8", newline="").read()

ORDINAL = {"primer": 1, "segundo": 2, "tercer": 3, "cuarto": 4, "quinto": 5, "sexto": 6,
           "septimo": 7, "octavo": 8, "noveno": 9, "decimo": 10}
# el libro lo escribe de las dos maneras y con varios verbos: "a partir del nivel 7",
# "en el 11º nivel", "cuando eliges esta presencia en el nivel 3"
_NIVEL_TXT = re.compile(
    r"(?i)nivel\s+(\d{1,2})"
    r"|(\d{1,2}|" + "|".join(ORDINAL) + r")\s*[.ºo°]*\s*(?:er|do|to|mo|vo|no)?\s+nivel")
# encabezados que no son un rasgo
NO_RASGO = re.compile(r"(?i)^(conjuros de|lista de|tabla|conjuros ampliados)")


def slug(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"_+", "_", re.sub(r"[^a-z0-9]+", "_", s.lower())).strip("_")[:30]


def capitulo(clase):
    m = re.search(r"(?m)^##\s+" + re.escape(clase) + r"\s*$", src, re.I)
    if not m:
        return None
    for s in re.finditer(r"(?m)^(#{1,2})\s+(.+?)\s*$", src[m.end():]):
        titulo = T.nk(s.group(2))
        if len(s.group(1)) == 1 or (titulo in T.CLASES and titulo != T.nk(clase)):
            return (m.end(), m.end() + s.start())
    return (m.end(), len(src))


def secciones(trozo, nivel_h):
    """[(titulo, texto)] de los encabezados de ese nivel dentro del tramo."""
    marcas = [(m.start(), m.end(), m.group(1).strip(" *"))
              for m in re.finditer(r"(?m)^#{%d}\s+(.+?)\s*$" % nivel_h, trozo)]
    salida = []
    for i, (a, b, titulo) in enumerate(marcas):
        fin = marcas[i + 1][0] if i + 1 < len(marcas) else len(trozo)
        # un encabezado de rango superior tambien cierra la seccion
        corte = re.search(r"(?m)^#{1,%d}\s+\S" % (nivel_h - 1), trozo[b:fin])
        salida.append((titulo, trozo[b:b + corte.start()] if corte else trozo[b:fin]))
    return salida


def limpio(t):
    # una tabla dentro del texto del rasgo no es su descripcion: es la tabla de la clase,
    # que empieza justo despues. Se corta ahi antes de nada.
    t = re.split(r"(?m)^[ 	]*\|", t or "")[0]
    t = re.sub(r"(?m)^_{3,}\s*$", "", t)
    t = re.sub(r"(?m)^[>\s]*#{1,6}\s*", "", t)
    t = re.sub(r"\s*\n\s*", " ", t)
    return a_metrico(limpiar(re.sub(r"\s{2,}", " ", t).strip()))


def recortar(t, tope=900):
    if len(t) <= tope:
        return t
    corte = t.rfind(". ", 0, tope)
    return (t[:corte + 1] if corte > tope // 2 else t[:tope]).strip()


def nivel_de(texto):
    m = _NIVEL_TXT.search(texto)
    if not m:
        return None
    v = (m.group(1) or m.group(2) or "").lower()
    return int(v) if v.isdigit() else ORDINAL.get(v)


def bloque_features_subclase(clase_id, sub_id):
    """El id de subclase NO es unico: "escarcha" es del Caballero de la Muerte y tambien
    del Mago. Hay que buscarlo DENTRO de su clase o se escriben los rasgos en la otra."""
    ci = lua.find('id = "%s"' % clase_id)
    if ci < 0:
        return None
    i = lua.find('id = "%s"' % sub_id, ci)
    if i < 0:
        return None
    j = lua.find("features = {", i)
    if j < 0:
        return None
    ini = j + len("features = {")
    prof, k = 1, ini
    while k < len(lua) and prof:
        if lua[k] == "{":
            prof += 1
        elif lua[k] == "}":
            prof -= 1
        k += 1
    return (ini, k - 1)


def main():
    kb = json.load(io.open(os.path.join(BASE, "kb.json"), encoding="utf-8"))
    nuevos, sin_nivel = {}, []
    for c in kb["classes"]:
        rango = capitulo(c["name"])
        if not rango:
            continue
        trozo = src[rango[0]:rango[1]]
        titulos = secciones(trozo, 3)
        for s in c["subclasses"]:
            claves = [T.nk(t) for t, _ in titulos]
            cerca = difflib.get_close_matches(T.nk(s["name"]), claves, 1, 0.62)
            if not cerca:
                # el libro suele anteponer un grupo ("Presencia de Sangre" por "Sangre")
                cerca = [k for k in claves if T.nk(s["name"]) in k]
                if not cerca:
                    continue
            texto = next(tx for t2, tx in titulos if T.nk(t2) == cerca[0])
            tiene = {T.nk(f["name"]) for f in s["features"]}
            for titulo, cuerpo in secciones(texto, 4):
                k = T.nk(titulo)
                if k in tiene or NO_RASGO.match(k) or len(cuerpo.strip()) < 40:
                    continue
                lv = nivel_de(cuerpo)
                if not lv:
                    sin_nivel.append((c["name"], s["name"], titulo))
                    continue
                tiene.add(k)
                nuevos.setdefault((c["id"], s["id"]), []).append(
                    {"id": "%s_%s" % (s["id"][:14], slug(titulo)), "level": lv,
                     "name": titulo, "desc": recortar(limpio(cuerpo))})
    tot = sum(len(v) for v in nuevos.values())
    print("rasgos de subclase nuevos: %d en %d subclases" % (tot, len(nuevos)))
    for (cid, sid), v in sorted(nuevos.items()):
        print("   %-16s %-16s %2d  %s" % (cid[:15], sid[:15], len(v),
                                          ", ".join("nv%d" % x["level"] for x in v)))
    print("\nsin nivel en su texto (se dejan fuera): %d" % len(sin_nivel))
    for a, b, c2 in sin_nivel[:10]:
        print("   %-20s %-18s %s" % (a[:19], b[:17], c2))

    if "--apply" not in sys.argv:
        return
    global lua
    escrito = 0
    orden = sorted(nuevos.items(),
                   key=lambda kv: -(bloque_features_subclase(*kv[0]) or (0, 0))[1])
    for (cid, sid), items in orden:
        r = bloque_features_subclase(cid, sid)
        if not r:
            print("  sin bloque:", cid, sid)
            continue
        ini, fin = r
        lineas = ['                { id = "%s", level = %d, name = "%s", type = "informativo", '
                  'description = "%s", effects = {} },'
                  % (it["id"], it["level"], it["name"].replace('"', "'"),
                     it["desc"].replace("\\", "").replace('"', "'")) for it in items]
        lua = lua[:fin] + "\n".join(lineas) + "\n            " + lua[fin:]
        escrito += len(items)
    io.open(LUA, "w", encoding="utf-8", newline="").write(lua)
    print("\nescritos en el addon: %d" % escrito)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
