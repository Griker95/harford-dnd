# -*- coding: utf-8 -*-
"""Recupera de los perfiles TRP3 lo que conceden los trasfondos personalizados.

Los trasfondos de la casa no estan en ningun manual, asi que no hay de donde importarlos.
Si estan JUGADOS: la ficha de cada perfil marca con `{col:cccccc}Trasfondo{/col}` cada
habilidad, idioma o herramienta que viene del trasfondo, y el propio frame del trasfondo
trae su presentacion y sus rasgos. Esto lee eso y lo deja en JSON para revisarlo antes de
tocar el addon; NO escribe nada por su cuenta.

La ficha es siempre el frame 1 del perfil y el trasfondo va detras, asi que la ficha del
mismo personaje es la ocurrencia de "{h3}Habilidades{/h3}" mas cercana HACIA ATRAS.
"""
import io
import json
import os
import re
import sys

CUENTAS = r"G:/Epsilon/_retail_/WTF/Account"
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_trasfondos_trp3.json")

# Marca de TRP3 para "esto te lo da el trasfondo". No hay una sola forma: cada jugador la
# escribio a su manera y conviven `{col:cccccc}Trasfondo{/col}`, la misma entre parentesis
# y la de otro gris (`a7a7a7`). Buscar la cadena literal se dejaba fuera a la mitad.
MARCA = re.compile(r"\{col:[0-9a-fA-F]{6}\}\(?Trasfondo\)?\{/col\}")


def sin_markup(t):
    t = re.sub(r"\{icon:[^}]*\}", "", t)
    t = re.sub(r"\{/?(?:h1|h2|h3|p|col)(?::[^}]*)?\}", "", t)
    return t.replace("||", "|").strip()


def sec(texto, titulo):
    """Los guiones de una seccion `{h3}<titulo>{/h3}` hasta el siguiente {h3} o el final."""
    m = re.search(r"\{h3\}%s\{/h3\}\\n(.*?)(?=\{h3\}|$)" % re.escape(titulo), texto, re.S)
    if not m:
        return []
    filas = []
    for linea in m.group(1).split("\\n"):
        linea = linea.strip()
        if linea.startswith("- "):
            filas.append(linea[2:])
    return filas


def del_trasfondo(texto, titulo):
    """Solo las filas marcadas como aportadas por el trasfondo."""
    return [sin_markup(MARCA.sub("", x)) for x in sec(texto, titulo) if MARCA.search(x)]


def rasgos(frame):
    """Cada `{h2}...{/h2}` del frame del trasfondo, con su texto debajo."""
    out = []
    for m in re.finditer(r"\{h2\}(.*?)\{/h2\}\\n(.*?)(?=\{h2\}|\{h3\}|$)", frame, re.S):
        nombre = sin_markup(m.group(1))
        cuerpo = sin_markup(m.group(2).replace("\\n", "\n")).strip()
        icono = re.search(r"\{icon:([^:}]+)", m.group(1))
        if nombre:
            out.append({"name": nombre, "desc": cuerpo, "icon": icono.group(1) if icono else None})
    return out


def presentacion(frame):
    """Lo que va entre el titulo del trasfondo y su primer rasgo."""
    m = re.search(r"\{h1:c\}.*?\{/h1\}\\n(.*?)(?=\{h2\}|$)", frame, re.S)
    return sin_markup((m.group(1) if m else "").replace("\\n", "\n")).strip()


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    encontrados = {}
    for cuenta in sorted(os.listdir(CUENTAS)):
        p = os.path.join(CUENTAS, cuenta, "SavedVariables", "totalRP3.lua")
        if not os.path.exists(p):
            continue
        t = io.open(p, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r'\["TX"\] = "(\{h1:c\}Trasfondo [^"]*?)"', t):
            frame = m.group(1)
            nombre = sin_markup(re.search(r"\{h1:c\}Trasfondo (.*?)\{/h1\}", frame).group(1))
            # la ficha del MISMO personaje: la mas cercana hacia atras
            corte = t.rfind("{h3}Habilidades{/h3}", 0, m.start())
            ficha = ""
            if corte > 0:
                # la ficha hay que cortarla donde acaba SU cadena Lua: Idiomas suele ser la
                # ultima seccion y, sin este corte, se tragaba el `["BK"]` y el frame siguiente
                fin = re.search(r'",\r?\n', t[corte:m.start()])
                ficha = t[corte:corte + (fin.start() if fin else 3000)]
            datos = {
                "cuenta": cuenta,
                "desc": presentacion(frame),
                "skills": del_trasfondo(ficha, "Habilidades"),
                "languages": del_trasfondo(ficha, "Idiomas"),
                "tools": del_trasfondo(ficha, "Herramientas"),
                "traits": rasgos(frame),
            }
            # si el mismo trasfondo sale en dos perfiles, se queda el mas completo
            previo = encontrados.get(nombre)
            peso = lambda d: len(d["skills"]) + len(d["languages"]) + len(d["tools"]) + len(d["traits"])
            if not previo or peso(datos) > peso(previo):
                encontrados[nombre] = datos

    io.open(SALIDA, "w", encoding="utf-8", newline="").write(
        json.dumps(encontrados, ensure_ascii=False, indent=2))
    print("trasfondos encontrados en perfiles TRP3: %d" % len(encontrados))
    for n in sorted(encontrados):
        d = encontrados[n]
        print("  %-32s hab=%-28s idi=%-16s her=%-14s rasgos=%d  desc=%d car."
              % (n, ", ".join(d["skills"]) or "-", ", ".join(d["languages"]) or "-",
                 ", ".join(d["tools"]) or "-", len(d["traits"]), len(d["desc"])))
    print("\nescrito: %s" % SALIDA)


if __name__ == "__main__":
    main()
