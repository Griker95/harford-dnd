# -*- coding: utf-8 -*-
"""Pone afinidad, icono y las categorias seguras a los conjuros importados de los manuales.

Las fichas que vienen del addon traen tres cosas que las importadas no: categorias
funcionales, afinidad elemental e icono. Las importadas se crean despues de que corra el
asignador de iconos, asi que llegan sin nada de eso.

Lo que se puede reponer y lo que no:

  - **Categorias**: solo dos, y salen de un campo, no de interpretar el texto. `Dano` si el
    conjuro declara dano y `Ritual` si es ritual. Las demas (`Control`, `Utilidad`,
    `Mejora`, `Social`...) estan curadas a mano en el addon y no se dejan deducir: al
    contrastar un juego de reglas de texto contra las 384 fichas que ya las tienen,
    `Control` acertaba 12 de 113 y `Mejora` metia 101 de mas. Publicar eso ensuciaria los
    filtros, asi que esas categorias se quedan sin poner.
  - **Afinidad**: el tipo de dano que ya se leyo del texto, que es dato, no criterio.
  - **Icono**: no se inventa ni se embebe uno nuevo; se reutiliza el de un conjuro hermano
    que ya esta en el compendio. Primero se busca uno de la misma familia por el nombre
    ("Bola de fuego retardada" toma el de "Bola de fuego"), luego uno del mismo tipo de
    dano y, en ultimo termino, uno de su escuela.
"""
import collections
import difflib
import re
import unicodedata

FUENTES = {"Manual del Jugador", "Xanathar", "Tasha", "Warcraft 5ª",
           "Costa de la Espada", "Wildemount"}


def _nk(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def afinidad(spell):
    """La afinidad es el tipo de dano, cuando el conjuro declara uno."""
    partes = (spell.get("damage") or "").split()
    if len(partes) >= 2 and not partes[-1][0].isdigit():
        return partes[-1].capitalize()
    return None


def iconos_hermanos(spells):
    """Indices para prestar el icono de un conjuro que ya lo tiene."""
    por_dano = collections.defaultdict(collections.Counter)
    por_escuela = collections.defaultdict(collections.Counter)
    for s in spells:
        ic = s.get("icon")
        if not ic:
            continue
        af = afinidad(s) or (s.get("affinity") or "").split(",")[0].strip()
        if af:
            por_dano[_nk(af)][ic] += 1
        if s.get("school"):
            por_escuela[_nk(s["school"])][ic] += 1
    return por_dano, por_escuela


PALABRAS_VACIAS = {"de", "del", "la", "el", "los", "las", "y", "o", "un", "una", "en",
                   "a", "por", "con", "al", "mayor", "menor", "masa"}


def _familia(nombre, conicono):
    """Ficha existente de la misma familia, por el nombre.

    Se exige que compartan una palabra con peso ("fuego", "muerte") ademas del parecido,
    para no prestarle el icono a un conjuro que solo se parece en las particulas.
    """
    base = _nk(nombre)
    palabras = {w for w in re.findall(r"[a-z]{4,}", base) if w not in PALABRAS_VACIAS}
    if not palabras:
        return None
    mejor, mejorr = None, 0.0
    for s in conicono:
        otras = {w for w in re.findall(r"[a-z]{4,}", _nk(s["name"])) if w not in PALABRAS_VACIAS}
        if not palabras & otras:
            continue
        r = difflib.SequenceMatcher(None, base, _nk(s["name"])).ratio()
        if r > mejorr:
            mejor, mejorr = s, r
    return mejor if mejorr >= 0.62 else None


def aplicar(kb, iconos_validos=None):
    """Rellena lo que falte sin tocar lo que ya hay. Devuelve (categorias, afinidad, icono).

    `iconos_validos` son los iconos que tienen PNG embebido: solo esos se pueden prestar,
    porque prestar uno sin imagen deja el hueco igual de vacio que antes.
    """
    conicono = [s for s in kb["spells"]
                if s.get("icon") and (iconos_validos is None or s["icon"] in iconos_validos)]
    por_dano, por_escuela = iconos_hermanos(conicono)
    n_cat = n_af = n_ic = 0
    for s in kb["spells"]:
        actuales = list(s.get("categories") or [])
        if set(actuales) <= FUENTES:          # solo trae la fuente: no esta clasificado
            seguras = []
            if s.get("damage"):
                seguras.append("Dano")
            if s.get("ritual"):
                seguras.append("Ritual")
            if seguras:
                s["categories"] = seguras + actuales
                n_cat += 1
        if not s.get("affinity"):
            af = afinidad(s)
            if af:
                s["affinity"] = af
                n_af += 1
        if not s.get("icon"):
            pariente = _familia(s["name"], conicono)
            if pariente:
                s["icon"] = pariente["icon"]
                n_ic += 1
                continue
            cand = (por_dano.get(_nk(s.get("affinity") or ""))
                    or por_escuela.get(_nk(s.get("school") or "")))
            if cand:
                s["icon"] = cand.most_common(1)[0][0]
                n_ic += 1
    return n_cat, n_af, n_ic
