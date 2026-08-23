# -*- coding: utf-8 -*-
"""Da ficha a los conjuros que solo aparecen como nombre en las listas de clase.

Las listas del Libro 1 nombran 1140 conjuros y el compendio tenia ficha de una parte. El
resto son dos casos distintos:

  - el conjuro YA esta en el compendio con otro titulo (otra traduccion: "Aceleracion" es
    "Acelerar", "Ayuda" es "Auxilio"). No se duplica: se le pone un alias y el nombre de
    la lista enlaza a la ficha que ya existe.
  - el conjuro no esta, pero si en uno de los exports de manual. Entonces se crea la ficha
    con el titulo que usa el Libro 1 y el texto del export.

Las equivalencias estan revisadas a mano en `equivalencias_listas.json`, porque el nombre
castellano de dos traducciones no se parece lo suficiente para deducirlo. Aqui se verifica
cada par por NIVEL: si el nivel del export no coincide con el nivel al que la lista pide el
conjuro, el par se rechaza y se informa.

Se importa desde add_full_desc.py; ejecutado suelto, solo informa.
"""
import difflib as _dl
import io
import json
import os
import re
import sys
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
import reparar_conjuros_export as _rep
EXPORTS = [("Manual del Jugador", "conjuros_d_d_5_0_edge_manual_del_jugador"),
           ("Tasha", "conjuros_tasha"),
           ("Warcraft 5ª", "conjuros_warcraft_5_edici_n_compressed"),
           ("Xanathar", "conjuros_xanathar")]
DIR_EXP = r"C:/Users/marco/Documents/New project/RuleSource/Export"


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", s.lower())).strip()


def _clave_y_nivel(clave):
    """Una clave del mapa puede llevar el nivel detras de una barra.

    Hace falta porque el libro reutiliza el mismo titulo para dos conjuros distintos y los
    separa por el nivel: "Sueno" es Sleep en el nivel 1 y Dream en el 5, y "Adivinacion"
    aparece en el 4 y en el 5. Sin el nivel no se puede decir a cual va cada uno.
    """
    if "|" in clave:
        nombre, _, lv = clave.rpartition("|")
        if lv.strip().isdigit():
            return nombre.strip(), int(lv)
    return clave, None


def _sin_marcadores(s):
    """La lista arrastra la marca de fuente del libro y a veces una precision entre
    parentesis: "Controlar vientos ^XGE^", "Conjurar elemental (aire)"."""
    s = re.sub(r"\s*\^[^^]*\^\s*", " ", s or "")
    s = re.sub(r"\s*\([^)]*\)\s*$", "", s)
    return nk(s)


def _slug(s):
    return re.sub(r"_+", "_", re.sub(r"[^a-z0-9]+", "_", nk(s))).strip("_")[:40]


def _nivel(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


def cargar_exports():
    """{clave normalizada: (fuente, entrada)} de todos los manuales exportados."""
    d = {}
    for fuente, fichero in EXPORTS:
        ruta = os.path.join(DIR_EXP, fichero + ".json")
        if not os.path.exists(ruta):
            continue
        for e in json.load(io.open(ruta, encoding="utf-8")):
            d.setdefault(nk(e["nombre"]), (fuente, e))
    return d


def _junta_cifras(s):
    """Arregla los numeros que el OCR del export estropea, antes de pasar a metros.

    Son dos cosas: un numero partido ("12 0 pies" por "120 pies"), que sin juntar deja la
    medida en pies porque el conversor no la reconoce; y el cero leido como la letra O
    ("O pies de altura").
    """
    s = s or ""
    s = re.sub(r"(\d)\s+(\d{1,2})(?=\s*(?:pies|libras)\b)", r"\1\2", s)
    return re.sub(r"(?<![A-Za-zÁÉÍÓÚÑ])O(?=\s*(?:pies|libras)\b)", "0", s)


def _millares(s):
    """Punto de millar en las medidas largas: el resto del compendio escribe 1.500 m."""
    return re.sub(r"(?<![\d.,])(\d)(\d{3})(?=\s*(?:metros|m)\b)", r"\1.\2", s or "")


# apellidos de los conjuros con autor: son lo unico que conserva la mayuscula dentro del
# titulo, igual que en las fichas que ya tenia el compendio ("Flecha acida de Melf")
_AUTORES = ("Melf", "Otto", "Otiluke", "Mordenkainen", "Leomund", "Bigby", "Tasha",
            "Rary", "Drawmij", "Tenser", "Snilloc", "Aganazzar", "Abi-Dalzim", "Nystul",
            "Maximiliano", "Evard", "Galder", "Jaina", "Alexstrasza", "Elune", "Hadar",
            "Agathys", "Raulothim", "Ursol", "Moil", "Shillelagh")


def _titulo(s):
    """Titulo de ficha: mayuscula solo al principio, como el resto del compendio.

    El export los trae en mayusculas de OCR y las listas del libro en mayuscula por
    palabra; ni uno ni otro encajan con las fichas que ya existian.
    """
    s = re.sub(r"\s{2,}", " ", (s or "").strip())
    if not s:
        return s
    s = s[:1].upper() + s[1:].lower()
    for autor in _AUTORES:
        s = re.sub(r"(?i)\b" + re.escape(autor) + r"\b", autor, s)
    return s


def aplicar(kb, limpiar=None, metrico=None, avisar=True):
    """Anade fichas y alias. Devuelve (nuevas, alias, rechazos)."""
    eq = json.load(io.open(os.path.join(BASE, "equivalencias_listas.json"), encoding="utf-8"))
    exp = cargar_exports()
    porficha = {nk(s["name"]): s for s in kb["spells"]}

    # Nivel de CONJURO al que cada lista pide cada nombre, para verificar el par. Solo
    # sirve la lista de la clase: en la ampliada de subclase el numero es el nivel de
    # CLASE al que se obtiene, no el nivel del conjuro.
    pedido, _original, _sinnivel = {}, {}, {}
    for c in kb["classes"]:
        for b in c.get("spellList") or []:
            for x in b["spells"]:
                pedido.setdefault(nk(x["name"]), b["level"])
                _original.setdefault(nk(x["name"]), x["name"])
        for s in c["subclasses"]:
            for b in s.get("spellList") or []:
                for x in b["spells"]:
                    _sinnivel.setdefault(nk(x["name"]), x["name"])
                    _original.setdefault(nk(x["name"]), x["name"])

    alias, rechazos, nuevas = {}, [], 0

    # 2) el conjuro hay que crearlo desde el export
    creadas = {}
    # cada par lleva su propio nivel: hay nombres que aparecen en dos niveles distintos y
    # un indice por nombre solo podria quedarse con uno
    pares = [(_clave_y_nivel(c)[0], v, _clave_y_nivel(c)[1]) for c, v in eq["export"].items()]

    # 2b) ademas, todo nombre que el export trae escrito casi igual y al MISMO nivel: son
    # la misma traduccion con las mayusculas o un acento del OCR de por medio, y no hace
    # falta escribirlos a mano uno por uno
    _revisado = {nk(k) for k in eq["export"]} | {nk(k) for k in eq["ficha"]}
    _todas = [(k, v) for k, v in sorted(pedido.items())]
    _todas += [(k, None) for k in sorted(_sinnivel) if k not in pedido]
    for clave, nivel_lista in _todas:
        limpia = _sin_marcadores(_original.get(clave, clave))
        if clave in porficha or limpia in porficha or clave in _revisado:
            continue
        par = exp.get(clave) or exp.get(limpia)
        if not par:
            # sin nivel que comprobar solo vale un nombre practicamente identico
            umbral = 0.9 if nivel_lista is not None else 0.94
            cerca = _dl.get_close_matches(limpia, list(exp), 1, umbral)
            par = exp.get(cerca[0]) if cerca else None
        if not par:
            continue
        if nivel_lista is not None and _nivel(par[1].get("nivel")) != nivel_lista:
            continue
        pares.append((_original.get(clave, clave), par[1]["nombre"], None))

    por_id = {s["id"]: s for s in kb["spells"]}
    for libro, nombre_exp, nivel_fijo in pares:
        par = exp.get(nk(nombre_exp))
        if not par:
            rechazos.append((libro, nombre_exp, "no esta en ningun export"))
            continue
        fuente, e = par
        nv = _nivel(e.get("nivel"))
        quiere = nivel_fijo if nivel_fijo is not None else pedido.get(nk(libro))
        if nv is not None and quiere is not None and nv != quiere:
            rechazos.append((libro, nombre_exp,
                             "nivel %s en el export y %s en la lista" % (nv, quiere)))
            continue
        clave = (nk(nombre_exp), nivel_fijo)
        if clave in creadas:                        # varios nombres, un solo conjuro
            alias[nk(libro)] = creadas[clave]["id"]
            if libro not in creadas[clave]["aliases"]:
                creadas[clave]["aliases"].append(libro)
            continue
        titulo = _titulo(eq.get("titulos", {}).get(nombre_exp) or libro)
        # Dos nombres de lista distintos pueden acabar en el MISMO titulo por la tabla de
        # equivalencias ("Resucitar" y "Resurreccion" son "Alzar a los muertos"), y la clave
        # de arriba, que es el nombre de origen, no los ve iguales: salian dos fichas con el
        # mismo id. Manda el id final.
        _id = "sp_" + _slug(titulo)
        _ya = por_id.get(_id)
        if _ya is not None:
            alias[nk(libro)] = _id
            if libro not in _ya["aliases"]:
                _ya["aliases"].append(libro)
            creadas[clave] = _ya
            continue
        comp, dur = _rep.reparar(e)
        # los nombres de campo son los que ya usa la ficha de conjuro del compendio; el
        # export los trae con otros y la web no leeria ni la descripcion ni el tiempo
        obj = {
            "id": _id,
            "name": titulo,
            "level": nv if nv is not None else (quiere or 0),
            "school": (e.get("escuela") or "").strip(),
            "castingTime": (e.get("tiempo") or "").strip(),
            "range": (e.get("alcance") or "").strip(),
            "components": comp,
            "duration": dur,
            "concentration": "concentraci" in nk(dur),
            "ritual": bool(e.get("ritual")),
            "description": (e.get("texto") or "").strip(),
            "source": fuente,
            "categories": [fuente],
            "classes": [],
            "aliases": [libro],
        }
        # el export deja algun campo vacio; se completa con el dato del manual
        for _campo, _valor in (eq.get("campos", {}).get(nombre_exp) or {}).items():
            if not (obj.get(_campo) or "").strip():
                obj[_campo] = _valor
        for campo in ("description", "castingTime", "range", "components", "duration"):
            v = _junta_cifras(obj[campo])
            if metrico:
                v = metrico(v)
            if limpiar:
                v = limpiar(v)
            obj[campo] = _millares(v)
        kb["spells"].append(obj)
        porficha[nk(obj["name"])] = obj
        creadas[clave] = obj
        por_id[_id] = obj
        alias[nk(libro)] = obj["id"]
        alias.setdefault(_sin_marcadores(libro), obj["id"])
        nuevas += 1

    # 1) el conjuro ya tiene ficha con otro titulo
    for _clave, ficha in eq["ficha"].items():
        libro, _lv = _clave_y_nivel(_clave)
        obj = porficha.get(nk(ficha))
        if not obj:
            rechazos.append((libro, ficha, "no existe esa ficha"))
            continue
        alias[nk(libro)] = obj["id"]
        obj.setdefault("aliases", [])
        if libro not in obj["aliases"]:
            obj["aliases"].append(libro)

    # ultimo repaso: un nombre que solo se diferencia por la marca de fuente que arrastra
    # de la tabla ("Controlar vientos ^XGE^") apunta a la ficha que ya existe
    for clave in list(pedido) + list(_sinnivel):
        if clave in porficha or clave in alias:
            continue
        obj = porficha.get(_sin_marcadores(_original.get(clave, clave)))
        if obj:
            alias[clave] = obj["id"]
            obj.setdefault("aliases", [])
            nombre = _original.get(clave, clave)
            if nombre not in obj["aliases"]:
                obj["aliases"].append(nombre)

    # las clases de cada ficha salen de las propias listas: si la lista del Sacerdote lo
    # nombra, el conjuro es de Sacerdote, se llame como se llame en su ficha
    porid = {s["id"]: s for s in kb["spells"]}
    def _marca(nombre_clase, entradas):
        for x in entradas:
            k = nk(x["name"])
            obj = porficha.get(k) or porid.get(alias.get(k) or "")
            if not obj:
                continue
            cl = obj.setdefault("classes", [])
            if nombre_clase not in cl:
                cl.append(nombre_clase)
    for c in kb["classes"]:
        for b in c.get("spellList") or []:
            _marca(c["name"], b["spells"])
        for s in c["subclasses"]:
            for b in s.get("spellList") or []:
                _marca(c["name"], b["spells"])

    kb.setdefault("spellAliases", {}).update(alias)
    if avisar and rechazos:
        for a, b, por in rechazos:
            print("   equivalencia rechazada: %-34s -> %-34s (%s)" % (a[:33], b[:33], por))
    return nuevas, len(alias), rechazos


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    kb = json.load(io.open(os.path.join(BASE, "kb_icons.json"), encoding="utf-8"))
    n, a, r = aplicar(kb)
    print("fichas nuevas: %d | alias: %d | rechazos: %d" % (n, a, len(r)))
