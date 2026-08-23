# -*- coding: utf-8 -*-
"""Saca de los perfiles TRP3 el icono DEL FRAME, no solo los de dentro del texto.

Cada frame del About lleva su propio `IC`: el de "Magia Sangre" es el icono de los conjuros
de esa especializacion, el de "Especializacion Sutileza" el de esa subclase, y asi con la
raza, el trasfondo y las clases. Eso no lo recogia nada: la pasada anterior solo miraba los
`{icon:...}` incrustados en el texto de cada rasgo.

Solo lee y propone; no escribe en el addon.
"""
import collections
import io
import json
import os
import re
import sys
import unicodedata

CUENTAS = r"G:/Epsilon/_retail_/WTF/Account"
DUMP = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_iconos_frames_trp3.json")

# cadena Lua completa, con sus escapes
_TX = re.compile(r'\["TX"\] = "((?:[^"\\]|\\.)*)"')
_IC = re.compile(r'\["IC"\] = "([^"]+)"')
# los titulos de clase, en femenino y masculino, tal y como los escriben los perfiles
CLASES = {"guerrero", "guerrera", "paladin", "paladina", "cazador", "cazadora",
          "picaro", "picara", "sacerdote", "sacerdotisa", "caballero de la muerte",
          "chaman", "chamana", "mago", "maga", "brujo", "bruja", "monje", "monja",
          "druida", "cazador de demonios", "cazadora de demonios"}
_H1 = re.compile(r"\{h1:c\}(.{0,160}?)\{/h1\}", re.S)


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", s.lower())).strip()


def limpio(x):
    x = re.sub(r"\{icon:[^}]*\}", "", x or "")
    x = re.sub(r"\{/?(?:h1|h2|h3|p|col)(?::[^}]*)?\}", "", x)
    return re.sub(r"\s+", " ", x).strip()


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    pares = collections.Counter()
    for cuenta in sorted(os.listdir(CUENTAS)):
        p = os.path.join(CUENTAS, cuenta, "SavedVariables", "totalRP3.lua")
        if not os.path.exists(p):
            continue
        t = io.open(p, encoding="utf-8", errors="replace").read()
        # Los ids de subclase SE REPITEN entre clases (escarcha es del Caballero de la
        # Muerte y del Mago; proteccion, de Guerrero y Paladin), asi que "Magia Escarcha"
        # a secas no dice de quien es. El About lleva un orden fijo -- clase, su
        # especializacion, su magia --, de modo que la clase es la ultima vista antes.
        clase_actual = ""
        for m in _TX.finditer(t):
            mt = _H1.match(m.group(1))
            if not mt:
                continue
            ic = _IC.search(t[m.end():m.end() + 300])
            titulo = limpio(mt.group(1))
            if not titulo:
                continue
            if nk(titulo) in CLASES:
                clase_actual = nk(titulo)
            if ic:
                etiqueta = titulo
                if nk(titulo).startswith(("magia ", "especializacion ")) and clase_actual:
                    etiqueta = clase_actual + " / " + titulo
                pares[(etiqueta, ic.group(1))] += 1

    existe = {f[:-4].lower() for f in os.listdir(DUMP) if f.lower().endswith(".png")}
    # un titulo puede salir con iconos distintos en perfiles distintos: gana el mas repetido
    mejor = {}
    for (titulo, ic), n in pares.most_common():
        if ic.lower() in existe:
            mejor.setdefault(nk(titulo), (titulo, ic, n))

    io.open(SALIDA, "w", encoding="utf-8", newline="").write(
        json.dumps({k: v[1] for k, v in mejor.items()}, ensure_ascii=False, indent=1))
    print("frames con titulo e icono: %d | titulos distintos: %d | con PNG real: %d"
          % (sum(pares.values()), len({t for t, _ in pares}), len(mejor)))
    for etiqueta, prefijo in (("MAGIA", "magia"), ("ESPECIALIZACION", "especializacion"),
                              ("TRASFONDO", "trasfondo")):
        filas = [(t, i, n) for k, (t, i, n) in sorted(mejor.items()) if prefijo in k]
        print("\n%s (%d):" % (etiqueta, len(filas)))
        for t, i, n in filas:
            print("   %-32s %-40s x%d" % (t[:32], i, n))
    print("\nescrito: %s" % SALIDA)


if __name__ == "__main__":
    main()
