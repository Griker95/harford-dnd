# -*- coding: utf-8 -*-
"""Nombre de presentacion de clases, razas y subclases.

El addon guarda estos nombres SIN tilde porque los compara como cadena (listas de
conjuros por clase, busquedas, ArcSpells), y por eso no se tocan en el Lua. Pero el
lector del compendio ve "Paladin", "Picaro" o "Afliccion", que son erratas para el.

Aqui se acentuan solo al publicar la web. Hay que hacerlo en los dos sitios a la vez: el
nombre de la clase y las listas por las que se filtra (`spellClasses` y el `classes` de
cada conjuro), o la ficha de clase se quedaria sin sus conjuros.
"""
import io, os, re, json

ACENTOS = {
    "Paladin": "Paladín",
    "Picaro": "Pícaro",
    "Picaro Sutileza": "Pícaro Sutileza",
    "Chaman": "Chamán",
    "Elfo del Vacio": "Elfo del Vacío",
    # el Libro 1 titula la raza "Troll" y la escribe asi 23 veces frente a 9; el addon la
    # guarda como "Trol" porque es su clave de emparejado
    "Trol": "Troll",
    "Trol de Bosque": "Troll de Bosque",
    "Afliccion": "Aflicción",
    "Demonologia": "Demonología",
    "Destruccion": "Destrucción",
    "Devastacion": "Devastación",
    "Proteccion": "Protección",
    "Punteria": "Puntería",
    "Represion": "Represión",
    "Restauracion": "Restauración",
}


def bonito(nombre):
    return ACENTOS.get(nombre, nombre)


def aplicar(kb):
    """Acentua los nombres visibles y, a la vez, las listas por las que se emparejan."""
    for c in kb.get("classes", []):
        c["name"] = bonito(c["name"])
        if c.get("spellClasses"):
            c["spellClasses"] = [bonito(x) for x in c["spellClasses"]]
        for f in c.get("features", []):
            f["name"] = titulo(f["name"])
        for s in c.get("subclasses", []):
            s["name"] = titulo(bonito(s["name"]))
            for f in s.get("features", []):
                f["name"] = titulo(f["name"])
    # razas y trasfondos guardan sus rasgos en `traits`, no en `features`
    for r in kb.get("races", []):
        r["name"] = bonito(r["name"])
        for f in (r.get("traits") or []) + (r.get("features") or []):
            f["name"] = titulo(f["name"])
        for s in r.get("subraces", []) or []:
            s["name"] = titulo(bonito(s["name"]))
            for f in (s.get("traits") or []) + (s.get("features") or []):
                f["name"] = titulo(f["name"])
    for b in kb.get("backgrounds", []):
        b["name"] = titulo(b["name"])
        if b.get("source") in FUENTES_TRASFONDO:
            b["source"] = FUENTES_TRASFONDO[b["source"]]
        for f in (b.get("traits") or []) + (b.get("features") or []):
            f["name"] = titulo(f["name"])
    for sp in kb.get("spells", []):
        sp["name"] = titulo(sp["name"])
        # las categorias son chips de filtro que el lector lee ("Dano", "Engano"); el addon
        # las compara sin tildes, asi que acentuarlas aqui no rompe su filtro
        if sp.get("categories"):
            sp["categories"] = [titulo(x) for x in sp["categories"]]
        if sp.get("source") in FUENTES:
            sp["source"] = FUENTES[sp["source"]]
        if sp.get("classes"):
            sp["classes"] = [bonito(x) for x in sp["classes"]]
    return kb


# Las mismas tildes, palabra a palabra, para los NOMBRES de conjuros, rasgos y trasfondos.
# El addon los guarda sin ella por el mismo motivo (los empareja como cadena), pero en el
# compendio son titulos que el lector lee: "Latigo mental de Tasha", "Espiritus guardianes".
# El mapa es el MISMO que usa la prosa (tildes.json), para que un termino no salga acentuado
# en el cuerpo del texto y sin tilde en su propio titulo. Se aplica solo al publicar.
_CFG = json.load(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                      "tildes.json"), encoding="utf-8"))
PALABRAS = _CFG["palabras"]
_HOMOGRAFOS = set(_CFG["homografos"])


def _palabra(w):
    if w.lower() in _HOMOGRAFOS:
        return w
    b = PALABRAS.get(w.lower())
    if not b:
        return w
    return b[0].upper() + b[1:] if w[:1].isupper() else b


# nombres propios: el texto del addon los escribe a veces en minuscula
PROPIOS = ("Harford", "Azeroth", "Elune", "Ventormenta", "Lordaeron", "Dalaran",
           "Orgrimmar", "Kalimdor", "Rasganorte", "Illidari", "Pandaria")


# Expresiones fijas: la palabra suelta es homografa y no se puede acentuar por su cuenta
# ("mas" existe como conjuncion), pero dentro de la locucion si lleva tilde.
LOCUCIONES = ((re.compile(r"\bmas all[aá]", re.I), "más allá"),)


def titulo(nombre):
    """Acentua un nombre de entrada respetando mayusculas y el resto del texto."""
    if not nombre:
        return nombre
    # la clase TIENE que incluir las vocales acentuadas: si no, una palabra que ya lleva
    # tilde se parte por ella ("Caracteristica" acentuada daba "Caracter" + "istica" y
    # el mapa acentuaba el primer trozo otra vez)
    nombre = re.sub(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{4,}", lambda m: _palabra(m.group(0)), nombre)
    for pat, bien in LOCUCIONES:
        nombre = pat.sub(lambda m: bien.capitalize() if m.group(0)[:1].isupper() else bien, nombre)
    for p in PROPIOS:
        nombre = re.sub(r"(?<![A-Za-z])" + p + r"(?![A-Za-z])", p, nombre, flags=re.I)
    return nombre

# Etiquetas de fuente: son una faceta de filtrado, asi que dos nombres para la misma
# fuente parten el filtro en dos. Se unifican al publicar.
FUENTES = {
    "Reglas basicas": "Reglas básicas",
    "Warcraft Custom": "Warcraft 5E Custom",
    "DnD": "D&D 5e",
}

# La misma idea para los trasfondos: el addon marca de donde sale cada uno con una sigla
# y el lector necesita saber cual es del manual, cual del libro de Warcraft y cual propio.
FUENTES_TRASFONDO = {
    "PHB": "Manual del Jugador",
    "SCAG": "Guía de la Costa de la Espada",
    "Warcraft": "Warcraft 5ª",
    "Harford": "Propio de Harford",
}


# Terminología de la casa: donde el juego actual dice "Barra de X", aquí se dice "Lingote
# de X". No es una errata de Blizzard: es la forma que usa la mesa, y ya la usaban tres
# objetos del propio catálogo ("Lingote de sulfuron", "Lingote de elementium"). Se aplica a
# los dos lados —el registro del addon y la ficha del compendio— para que un material no se
# llame de dos maneras según dónde se mire.
_CASA = ((re.compile(r"(?i)^barra\b"), "Lingote"),)


def casa(nombre):
    if not nombre:
        return nombre
    for pat, bien in _CASA:
        nombre = pat.sub(lambda m: bien if m.group(0)[:1].isupper() else bien.lower(), nombre)
    return nombre
