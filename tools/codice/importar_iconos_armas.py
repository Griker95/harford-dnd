# -*- coding: utf-8 -*-
"""Trae los iconos de arma de la WEB al catalogo del addon.

Sentido del flujo: web -> addon. La web es la fuente canonica del contenido, y es donde estan
los iconos revisados; `HarfordDnDWeapons.lua` no tenia ninguno. El flujo contrario
(`extract_equipment.py`, addon -> web) NO se toca aqui.

Empareja por el nombre del arma. Escribe `icon="..."` en cada entrada de WEAPONS que encuentre
pareja y deja el resto intacto, informando de lo que no cuadra en vez de inventarse nada.
"""
import io, os, re, sys, unicodedata

sys.stdout.reconfigure(encoding="utf-8")

WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-equipment.js"
LUA = r"C:/Users/marco/Documents/New project/Harford/DnD/Data/HarfordDnDWeapons.lua"


def sin_tildes(s):
    return "".join(c for c in unicodedata.normalize("NFD", s)
                   if unicodedata.category(c) != "Mn")


def clave(s):
    """Nombre normalizado para emparejar: sin tildes, sin apostrofes, minusculas."""
    s = sin_tildes(s).lower()
    return re.sub(r"[^a-z0-9]+", "", s)


def iconos_de_la_web():
    texto = io.open(WEB, encoding="utf-8").read()
    # Cada objeto del compendio trae name, kind e icon. Solo interesan las armas.
    fuera = {}
    for bloque in re.finditer(r"\{[^{}]*\}", texto):
        b = bloque.group(0)
        n = re.search(r'"name"\s*:\s*"([^"]+)"', b)
        i = re.search(r'"icon"\s*:\s*"([^"]*)"', b)
        k = re.search(r'"kind"\s*:\s*"([^"]+)"', b)
        if not (n and i and i.group(1)):
            continue
        # El Escudo esta en la tabla de armas del addon pero en la web es armadura: se acepta
        # tambien, porque el catalogo del addon lo trata como equipo de mano secundaria.
        if k and k.group(1) not in ("weapon", "armor"):
            continue
        fuera[clave(n.group(1))] = (n.group(1), i.group(1))
    return fuera


def main():
    escribir = "--escribir" in sys.argv
    web = iconos_de_la_web()
    print("armas con icono en la web: %d" % len(web))

    lua = io.open(LUA, encoding="utf-8", newline="").read()
    lineas = lua.split("\n")
    puestos, ya_tenian, sin_pareja = 0, 0, []

    for idx, linea in enumerate(lineas):
        m = re.match(r'(\s*\{ key="([^"]+)",)(.*)$', linea)
        if not m:
            continue
        cabeza, nombre, resto = m.group(1), m.group(2), m.group(3)
        if 'icon=' in resto:
            ya_tenian += 1
            continue
        par = web.get(clave(nombre))
        if not par:
            sin_pareja.append(nombre)
            continue
        # El icono va justo detras de la clave, antes de cat=, para que se lea de un vistazo.
        lineas[idx] = cabeza + ' icon="%s",' % par[1] + resto
        puestos += 1

    print("  iconos puestos:      %d" % puestos)
    print("  ya tenian icono:     %d" % ya_tenian)
    print("  sin pareja en la web: %d" % len(sin_pareja))
    for n in sin_pareja:
        print("      %s" % n)

    if escribir and puestos:
        io.open(LUA, "w", encoding="utf-8", newline="").write("\n".join(lineas))
        print("\nESCRITO en %s" % os.path.basename(LUA))
    elif not escribir:
        print("\n(simulacion: pasa --escribir para aplicarlo)")


if __name__ == "__main__":
    main()
