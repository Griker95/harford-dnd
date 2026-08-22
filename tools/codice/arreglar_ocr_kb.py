# -*- coding: utf-8 -*-
"""Repara en el kb ya montado los restos que deja el OCR de los manuales en PDF.

Son tres: la letra inicial desprendida de su palabra ("s uelo"), el guion de corte de
linea ("murcie- lago") y las medidas largas sin punto de millar ("1500 metros").

Lo primero es lo delicado y va con el criterio de `auditar_letra_inicial.py`:

  - la letra suelta es una consonante, y en castellano ninguna consonante es una palabra
    de una sola letra (por eso no se tocan "a", "e", "o", "u", "y", que si lo son);
  - la palabra que resulta de unirlas YA existe en el compendio unas cuantas veces;
  - y aparece mas veces que el resto suelto, para no unir cuando el corte era correcto.

Se aplica sobre el kb ya montado, asi que vale igual para el texto que venia del addon y
para el que se importa de los manuales.
"""
import collections
import re

# la letra suelta solo se toca en prosa; el guion de corte, en cualquier campo de texto,
# porque donde mas aparece es en el componente material
CAMPOS = ("desc", "description", "extras", "mechanics", "roleNotes", "suggested", "intro")
CAMPOS_CORTE = CAMPOS + ("components", "range", "castingTime", "duration")
SUELTA = re.compile(r"(?<![A-Za-zÁÉÍÓÚáéíóúñ])([b-df-hj-np-tv-zB-DF-HJ-NP-TV-Z]) ([a-záéíóúñ]{2,})")
MINIMO = 3


def _textos(o, campos=CAMPOS):
    if isinstance(o, dict):
        for k, v in o.items():
            if isinstance(v, str) and k in campos:
                yield o, k, v
            else:
                for x in _textos(v, campos):
                    yield x
    elif isinstance(o, list):
        for v in o:
            for x in _textos(v, campos):
                yield x


# Guion de corte de linea del PDF: "murcie- lago", "consu- mido". Un guion legitimo del
# castellano no lleva espacio detras ("teorico-practico"), asi que la union es segura.
CORTE = re.compile(r"([a-záéíóúñ])-\s+([a-záéíóúñ])")

# Punto de millar en las medidas: el resto del compendio ya escribe "1.000 po" y una
# distancia de cuatro cifras sin separador desentona y cuesta de leer.
MILLAR = re.compile(r"(?<![\d.,])(\d)(\d{3})(?=\s*(?:metros|m)\b)")

# La misma palabra rota, pero por el final: "Caris ma", "conjur os". El trozo que queda
# suelto es corto, asi que aqui la salvaguarda es que ese trozo NO sea de por si una
# palabra corriente: "vio la" no se puede unir en "viola", y "la" aparece por todas partes.
# Cifra pegada a su unidad ("1minuto", "5pies"): el OCR se come el espacio. Solo se
# separan unidades conocidas, para no tocar los dados ("1d6") ni los codigos.
PEGADA = re.compile(r"(\d)(minutos?|horas?|d[ií]as?|pies?|metros?|rondas?|asaltos?|niveles?|nivel)\b", re.I)

COLA = re.compile(r"\b([A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{4,}) ([a-záéíóúñ]{2,3})\b")
COLA_MAX = 4      # veces que puede aparecer el trozo suelto para seguir considerandolo roto
# palabras castellanas cortas que existen por si solas: si el trozo suelto es una de
# ellas, el espacio es bueno. Sin esto "puntos de golpe a 0" se unia en "golpea".
COLA_VETO = {"de", "del", "la", "el", "lo", "los", "las", "un", "una", "al", "en", "es",
             "se", "si", "no", "ni", "su", "sus", "te", "le", "les", "me", "mi", "tu",
             "tus", "ya", "ha", "he", "han", "por", "con", "sin", "que", "mas", "más",
             "muy", "son", "ser", "fue", "dos", "tre", "pie", "pies", "vez", "mal",
             "bien", "aun", "aún", "asi", "así", "sus", "ese", "eso", "esa", "las"}


def aplicar(kb):
    """Devuelve (uniones, formas distintas, guiones, millares)."""
    voc = collections.Counter()
    for _, _, v in _textos(kb):
        voc.update(w.lower() for w in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{2,}", v))

    hechas = collections.Counter()
    colas = collections.Counter()
    contexto = {}

    def une(m):
        unido = (m.group(1) + m.group(2)).lower()
        if voc[unido] >= MINIMO and voc[m.group(2).lower()] < voc[unido]:
            hechas[unido] += 1
            return m.group(1) + m.group(2)
        return m.group(0)

    def une_cola(m):
        unido = (m.group(1) + m.group(2)).lower()
        cola = m.group(2).lower()
        if cola in COLA_VETO:
            return m.group(0)
        if voc[unido] >= MINIMO and voc[cola] <= COLA_MAX:
            hechas[unido] += 1
            colas[unido] += 1
            # se guarda como quedaba antes para poder revisar la union a mano: es la regla
            # con mas riesgo de las tres y conviene poder verla
            contexto.setdefault(unido, m.string[max(0, m.start() - 45):m.end() + 25])
            return m.group(1) + m.group(2)
        return m.group(0)

    cortes = millares = 0
    for obj, campo, valor in _textos(kb, CAMPOS_CORTE):
        nuevo, k = CORTE.subn(r"\1\2", valor)
        nuevo, k2 = MILLAR.subn(r"\1.\2", nuevo)
        nuevo, k3 = PEGADA.subn(r"\1 \2", nuevo)
        if k or k2 or k3:
            cortes += k
            millares += k2 + k3
            obj[campo] = nuevo
    for obj, campo, valor in _textos(kb):
        nuevo = COLA.sub(une_cola, SUELTA.sub(une, valor))
        if nuevo != valor:
            obj[campo] = nuevo
    return sum(hechas.values()), len(hechas), cortes, millares, colas, contexto


if __name__ == "__main__":
    import io
    import json
    import os
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    BASE = os.path.dirname(os.path.abspath(__file__))
    kb = json.load(io.open(os.path.join(BASE, "kb_icons.json"), encoding="utf-8"))
    n, formas, cortes, mil, colas, ctx = aplicar(kb)
    print("uniones: %d en %d formas | guiones: %d | millares: %d" % (n, formas, cortes, mil))
    print("unidas por el final:")
    for w, c in colas.most_common():
        print("   %-16s x%-2d ...%s" % (w, c, ctx.get(w, "").replace("\n", " ")))
