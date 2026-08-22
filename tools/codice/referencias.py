# -*- coding: utf-8 -*-
"""Referencias cruzadas a capitulos de otros manuales.

Los libros se remiten entre si ("Consulta el capitulo 10 del Manual del Jugador...").
En el compendio eso no sirve: o el destino existe aqui y entonces se enlaza, o no
existe y la frase se va.

  destino que SI existe -> reglas.html#conjuros (reglas generales de lanzamiento)
                        -> la lista de conjuros de la clase, al final de su propia ficha
  destino que NO existe -> Guia del Dungeon Master: se borra la subordinada

`web=True` emite el enlace en markdown `[texto](url)`; `web=False` deja prosa plana,
porque el addon renderiza el texto en el chat/compendio del juego y no sabe de enlaces.
"""
import re

_CLASE = r"(?:de|del)\s+(?:los\s+)?[A-Za-zÁÉÍÓÚÑáéíóúñ][\wÁÉÍÓÚÑáéíóúñ ]{2,32}?"

# "Consulta el capitulo 10 del Manual del Jugador para las reglas generales de
#  lanzamiento de conjuros y el capitulo 6 de este libro para la lista de conjuros del mago."
_CONJUROS = re.compile(
    r"Consulta\s+el\s+cap[ií]tulo\s*10\s+del?\s*\*?Manual del Jugador\*?\s+para\s+"
    r"(?:conocer\s+)?las\s+reglas\s+generales\s+(?:de|del|sobre)\s+(?:el\s+)?"
    r"(?:lanzamiento\s+de\s+conjuros|la\s+magia)\s+y\s+el\s+cap[ií]tulo\s*6"
    r"(?:\s+de\s+este\s+libro)?\s+para\s+(?:ver\s+)?la\s+lista\s+de\s+(?:conjuros|hechizos)\s+"
    r"(" + _CLASE + r")\s*\.",
    re.I)

# Remision entre parentesis. No basta con mirar el verbo del principio: tambien aparece
# como aclaracion suelta ("(o puedes tirar en la tabla bagatelas del capitulo 5)"). Basta
# con que el parentesis entero remita a un capitulo o pagina que aqui no existe.
_PARENTESIS = re.compile(r"\s*\([^)]{0,140}?(?:cap[ií]tulo|p[áa]gina)\s*\d[^)]{0,140}\)")

# remision a una pagina de un manual que el compendio no tiene
_PAGINA = re.compile(r"[^.\n]*\bp[áa]gina\s+\d+\s+de\s+\*?[^.\n]*\.")

# subordinada que remite a un manual que el compendio no tiene
_SIN_DESTINO = re.compile(
    r"\s*,?\s*(?:tal\s+y?\s*como\s+se\s+describe|como\s+se\s+(?:describe|explica|detalla)|"
    r"seg[uú]n\s+se\s+(?:describe|explica)|descrito|ver|v[ée]ase)\s+en\s+el\s+cap[ií]tulo\s*\d+\s+"
    r"(?:de\s+la|del|de)\s*\*?(?:Gu[ií]a del Dungeon Master|Manual del Jugador|"
    r"Gu[ií]a del Dungeon M[áa]ster)\*?\s*", re.I)

_ENLACE = "[las reglas generales de lanzamiento de conjuros](reglas.html#conjuros)"
_PLANO = "las reglas generales de lanzamiento de conjuros"


def referencias(texto, web=True):
    if not texto or not re.search(r"cap[ií]tulo|p[áa]gina", texto, re.I):
        return texto
    reglas = _ENLACE if web else _PLANO
    texto = _CONJUROS.sub(
        lambda m: "Consulta %s; la lista de conjuros %s está al final de esta ficha."
                  % (reglas, m.group(1).strip()),
        texto)
    texto = _SIN_DESTINO.sub("", texto)
    texto = _PARENTESIS.sub("", texto)
    texto = _PAGINA.sub("", texto)
    # una remision suelta que quede sin reescribir tampoco tiene destino: fuera la frase
    texto = re.sub(r"(?:^|(?<=[.\n]))\s*[^.\n]{0,40}cap[ií]tulo\s*\d+\s+"
                   r"(?:de|del)[^.\n]{0,70}\.\s*", " ", texto)
    texto = _cajas_vacias(texto)
    return re.sub(r"[ \t]{2,}", " ", texto).strip()


def _cajas_vacias(texto):
    """Un recuadro del libro que se queda solo con su titulo deja de tener sentido.

    Pasa cuando el recuadro entero era una remision ("Reglas adicionales de Metamagia
    pueden verse en la pagina 65 de Tasha's"): al quitar la frase queda una caja vacia.
    """
    if ">" not in texto:
        return texto
    salida, bloque = [], []

    def cerrar():
        if not bloque:
            return
        cuerpo = [re.sub(r"^\s*>\s?", "", x) for x in bloque]
        util = [x for x in cuerpo if x.strip() and not x.lstrip().startswith("#")]
        if util:
            salida.extend(bloque)
        bloque.clear()

    for linea in texto.split("\n"):
        if linea.lstrip().startswith(">"):
            bloque.append(linea)
        else:
            cerrar()
            salida.append(linea)
    cerrar()
    return re.sub(r"\n{3,}", "\n\n", "\n".join(salida))


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    for p in [
        "Consulta el capítulo 10 del *Manual del Jugador* para conocer las reglas generales "
        "del lanzamiento de conjuros y el capítulo 6 de este libro para la lista de conjuros del mago.",
        "Consulta el capítulo 10 del Manual del Jugador para las reglas generales sobre "
        "lanzamiento de conjuros y el capítulo 6 para la lista de conjuros de brujo.",
        "Estás naturalmente adaptado a climas cálidos, tal como se describe en el capítulo 5 "
        "de la *Guía del Dungeon Master*.",
    ]:
        print(repr(referencias(p)))
        print(repr(referencias(p, web=False)))
