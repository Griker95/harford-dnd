# -*- coding: utf-8 -*-
"""Saca del texto de un conjuro los tres datos que la ficha usa para tirar.

Los conjuros que se importaron de los manuales traen la descripcion entera pero ninguno
de los campos que lee el addon: `attack`, `savingThrow` y `damage`. Aqui se leen del
propio texto, con dos reglas:

  - todo sale de una frase literal de la descripcion, nunca de suponer lo que "deberia"
    hacer un conjuro por su nombre o su escuela;
  - lo que se encuentra se coteja contra los catalogos del addon (las seis
    caracteristicas de `HarfordDnDData.ABIL` y los trece tipos de dano de
    `HarfordDamageTypes`), que ya recogen las variantes de traduccion: el manual escribe
    "relampago" donde el addon dice "rayo", o "psiquico" con tilde y sin ella. Si una
    palabra no esta en el catalogo NO se inventa un valor: se deja el campo vacio y se
    informa aparte para mirarlo a mano.

El formato de los campos es el que ya usan las fichas del compendio, sin tildes, porque el
addon compara esas cadenas tal cual.
"""
import re
import unicodedata

# Las seis de HarfordDnDData.ABIL, en la forma en que el compendio las escribe.
CARACTERISTICAS = {
    "fuerza": "Fuerza",
    "destreza": "Destreza",
    "constitucion": "Constitucion",
    "inteligencia": "Inteligencia",
    "sabiduria": "Sabiduria",
    "carisma": "Carisma",
}

# Los trece de HarfordDamageTypes, con los alias en castellano que ya reconoce el addon.
# El valor es la etiqueta del catalogo en minusculas y sin tilde.
TIPOS_DANO = {
    "cortante": "cortante",
    "perforante": "perforante",
    "contundente": "contundente",
    "fuego": "fuego",
    "frio": "frio",
    "rayo": "rayo",
    "relampago": "rayo",          # el manual lo traduce asi; el addon lo llama rayo
    "electricidad": "rayo",
    "trueno": "trueno",
    "acido": "acido",
    "veneno": "veneno",
    "necrotico": "necrotico",
    "radiante": "radiante",
    "psiquico": "psiquico",
    "fuerza": "fuerza",
}


def _nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return s.lower()


# "tirada de salvacion de Destreza", "una salvacion de Constitucion"
_SALVACION = re.compile(
    r"(?:tirada de )?salvaci[óo]n(?:es)? de ([A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)", re.I)
# ...pero no cuando el conjuro lo que hace es MEJORAR esa salvacion en vez de exigirla:
# "tiene ventaja en sus tiradas de salvacion de Sabiduria" no es una salvacion contra el
# conjuro, es lo que el conjuro concede.
_NO_ES_SALVACION = re.compile(
    r"ventaja|desventaja|competencia|bonificador|inmune|[ée]xito autom[áa]tico|"
    r"supera autom[áa]ticamente", re.I)
# "un ataque de conjuro a distancia", "... cuerpo a cuerpo"
_ATAQUE = re.compile(
    r"ataque de conjuro (a distancia|cuerpo a cuerpo)", re.I)
# "8d6 de dano de fuego", "4d8 de dano necrotico", "1d10 de dano por fuego"
_DANO = re.compile(
    r"(\d+d\d+)(?:\s*\+\s*\d+)?\s+de\s+da[ñn]o\s*(?:de|por|del tipo)?\s*"
    r"([A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)?", re.I)


def extraer(texto):
    """Devuelve (attack, savingThrow, damage, dudas).

    `dudas` son las palabras que aparecian donde se esperaba una caracteristica o un tipo
    de dano y no estan en el catalogo; sirven para revisarlas, no se publican.
    """
    t = texto or ""
    dudas = []

    salvacion = None
    for m in _SALVACION.finditer(t):
        # se mira solo lo que va desde el principio de la frase, para no arrastrar el
        # contexto de la anterior
        frase = re.split(r"[.;]\s", t[:m.start()])[-1]
        if _NO_ES_SALVACION.search(frase):
            continue
        k = _nk(m.group(1))
        if k in CARACTERISTICAS:
            salvacion = CARACTERISTICAS[k]
            break
        dudas.append(("salvacion", m.group(1)))

    ataque = None
    m = _ATAQUE.search(t)
    if m:
        ataque = "Ataque de conjuro " + _nk(m.group(1))

    dano = None
    for m in _DANO.finditer(t):
        palabra = m.group(2)
        if not palabra:
            continue
        k = _nk(palabra)
        if k in TIPOS_DANO:
            dano = "%s %s" % (m.group(1), TIPOS_DANO[k])
            break
        # "de dano" seguido de otra cosa ("de dano adicional") no nombra un tipo
        if k in ("adicional", "extra", "necesario", "total", "maximo"):
            continue
        dudas.append(("dano", palabra))

    # el campo `attack` del compendio dice como se resuelve: por ataque o por salvacion
    if not ataque and salvacion:
        ataque = "Salvacion de " + salvacion
    return ataque, salvacion, dano, dudas
