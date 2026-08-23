# -*- coding: utf-8 -*-
"""Saca los idiomas de razas y trasfondos del texto de la WEB (fuente canonica).

No existe un campo estructurado de idiomas ni en el addon ni en la web: viven dentro de la prosa
del rasgo "Idiomas". Este script la interpreta y saca, por rasgo:
    fijos    -> idiomas que se conocen si o si
    elige    -> cuantos idiomas se eligen libremente
    entre    -> lista cerrada de opciones, cuando el texto la acota

Imprime TODO lo que encuentra y, por separado, lo que NO ha sabido interpretar. Lo segundo es lo
importante: se revisa a mano antes de hornear nada, en vez de inventarse un idioma por inferencia.
"""
import io
import json
import re
import sys
import unicodedata

sys.stdout.reconfigure(encoding="utf-8")

WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-data.js"

# Numeros escritos que aparecen en el texto.
CANTIDAD = {"un": 1, "una": 1, "uno": 1, "dos": 2, "tres": 3}


def sin_tildes(s):
    return "".join(c for c in unicodedata.normalize("NFD", s)
                   if unicodedata.category(c) != "Mn")


def bloques(texto, clave):
    """Devuelve los objetos JSON de primer nivel de una lista con esa clave."""
    i = texto.find('"%s"' % clave)
    if i < 0:
        return []
    i = texto.find("[", i)
    fuera, nivel, ini = [], 0, None
    for k in range(i, len(texto)):
        c = texto[k]
        if c == "{":
            if nivel == 0:
                ini = k
            nivel += 1
        elif c == "}":
            nivel -= 1
            if nivel == 0:
                fuera.append(texto[ini:k + 1])
        elif c == "]" and nivel == 0:
            break
    return fuera


def campo(bloque, nombre):
    m = re.search(r'"%s"\s*:\s*"((?:[^"\\]|\\.)*)"' % nombre, bloque)
    if not m:
        return None
    return json.loads('"%s"' % m.group(1))


def rasgos_de_idioma(bloque):
    """Cada rasgo cuyo nombre empieza por 'Idioma'."""
    fuera = []
    for sub in bloques(bloque, "traits"):
        nombre = campo(sub, "name") or ""
        if sin_tildes(nombre).lower().startswith("idioma"):
            fuera.append((campo(sub, "id") or "?", nombre, campo(sub, "desc") or ""))
    return fuera


def interpretar(texto):
    """Prosa -> { fijos, elige, entre }. Devuelve None si no lo entiende.

    Los nombres de idioma van en MAYUSCULA en el texto (Comun, Enano, Taur-ahe, Visceralico) y la
    prosa que los acompana no. Esa es la senal que separa un idioma de una explicacion: sin ella,
    "Visceralico, una forma baja de Comun usada en mercados clandestinos" entraba entera como si
    fuesen tres idiomas.
    """
    t = texto.split(".")[0].strip()
    plano = sin_tildes(t).lower()

    # "Puedes hablar A, B, C o D" -> eleccion entre una lista cerrada.
    m = re.search(r"puedes hablar ((?:[^,]+, )+[^,]+ o [^,]+)$", t, re.I)
    if m:
        opciones = [p.strip() for p in re.split(r",| o ", m.group(1)) if p.strip()]
        if len(opciones) >= 2 and all(o[:1].isupper() for o in opciones):
            return {"fijos": [], "elige": 1, "entre": opciones}

    elige = 0
    # "N idioma(s) [adicional(es)] [cualquiera] de/a tu eleccion"
    m = re.search(r"(\w+) idiomas?[^.]{0,30}?(?:de|a) tu eleccion", plano)
    if m:
        elige = CANTIDAD.get(m.group(1), 0)
    if elige == 0 and re.search(r"^\s*(un|uno|una) idioma", plano):
        elige = 1
    if elige == 0 and "de tu eleccion" in plano:
        elige = 1

    # Idiomas NOMBRADOS: palabras en mayuscula, descartando el arranque de la frase.
    fijos = []
    for palabra in re.findall(r"\b[A-ZÁÉÍÓÚÑ][\wáéíóúñ'-]+", t):
        if sin_tildes(palabra).lower() in ("puedes", "hablas", "hablar", "leer", "escribir",
                                           "escribes", "lees", "uno", "una", "un", "dos", "tres",
                                           "conoces", "tambien", "ademas", "los", "el", "la"):
            continue
        if palabra not in fijos:
            fijos.append(palabra)

    # Si la frase acota una eleccion, esas mayusculas son OPCIONES, no idiomas fijos.
    if elige and re.search(r"como |normalmente |perteneciente ", plano):
        return {"fijos": [], "elige": elige, "entre": [], "nota": t}

    if not fijos and elige == 0:
        return None
    return {"fijos": fijos, "elige": elige, "entre": []}


def main():
    texto = io.open(WEB, encoding="utf-8").read()
    entendidos, dudosos = [], []
    for clave in ("races", "backgrounds"):
        for bloque in bloques(texto, clave):
            nombre = campo(bloque, "name") or "?"
            for rid, rnombre, desc in rasgos_de_idioma(bloque):
                info = interpretar(desc)
                fila = (clave, nombre, rid, desc.split(".")[0].strip())
                if info:
                    entendidos.append((fila, info))
                else:
                    dudosos.append(fila)

    print("=" * 100)
    print("INTERPRETADOS: %d" % len(entendidos))
    print("=" * 100)
    for (clave, nombre, rid, frase), info in entendidos:
        partes = []
        if info["fijos"]:
            partes.append("fijos: " + ", ".join(info["fijos"]))
        if info["elige"]:
            partes.append("elige %d" % info["elige"])
        if info.get("entre"):
            partes.append("entre: " + ", ".join(info["entre"]))
        if info.get("nota"):
            partes.append("nota: " + info["nota"])
        print("  [%s] %-26s %-18s %s" % (clave[:3], nombre[:26], rid[:18], "  |  ".join(partes)))

    print()
    print("=" * 100)
    print("NO INTERPRETADOS (revisar a mano): %d" % len(dudosos))
    print("=" * 100)
    for clave, nombre, rid, frase in dudosos:
        print("  [%s] %-26s %-18s %s" % (clave[:3], nombre[:26], rid[:18], frase[:80]))


if __name__ == "__main__":
    main()
