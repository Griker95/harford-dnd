# -*- coding: utf-8 -*-
"""Guarda y vigila los iconos elegidos a mano, para que ningun cambio se los lleve.

Los iconos del catalogo (`HarfordIconCatalog.lua`) estan puestos uno a uno y son la parte
que no se puede rehacer: si un script los pisa o el fichero pierde una entrada, no hay
manera de recuperarlos salvo volviendo a elegirlos.

  - `--guardar` toma la foto de referencia (`iconos_manuales.json`).
  - sin argumentos, compara el catalogo de ahora con esa foto y avisa de lo que falte o
    haya cambiado. Sale con codigo 1 si algo se ha perdido, para poder encadenarlo.

Tambien informa de los iconos que se repiten, que es lo que hay que evitar al completar.
"""
import collections
import io
import json
import os
import re
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
CAT = r"C:/Users/marco/Documents/New project/Harford/Compendium/HarfordIconCatalog.lua"
FOTO = os.path.join(BASE, "iconos_manuales.json")


def _bloque(txt, nombre):
    m = re.search(r"Catalog\.%s\s*=\s*\{" % nombre, txt)
    if not m:
        return ""
    ini = m.end()
    prof, i = 1, ini
    while i < len(txt) and prof:
        if txt[i] == "{":
            prof += 1
        elif txt[i] == "}":
            prof -= 1
        i += 1
    return txt[ini:i - 1]


def leer(ruta=None):
    """{seccion: {clave: [iconos]}} tal y como estan escritos en el catalogo."""
    txt = io.open(ruta or CAT, encoding="utf-8").read()
    fuera = {}
    # conjuros: id = { "candidato", "candidato", ... }
    conj = {}
    for m in re.finditer(r"(\w+)\s*=\s*\{([^}]*)\}", _bloque(txt, "spells")):
        conj[m.group(1)] = re.findall(r'"([^"]+)"', m.group(2))
    fuera["spells"] = conj
    # las demas secciones son clave -> icono
    for sec in ("names", "presentationNames", "features", "subclasses"):
        b = _bloque(txt, sec)
        d = {}
        for m in re.finditer(r'\["([^"]+)"\]\s*=\s*"([^"]+)"', b):
            d[m.group(1)] = [m.group(2)]
        for m in re.finditer(r'(?m)^\s*(\w+)\s*=\s*"([^"]+)"', b):
            d.setdefault(m.group(1), [m.group(2)])
        # subclases: clase = { sub = "icono", ... }
        for m in re.finditer(r"(\w+)\s*=\s*\{([^}]*)\}", b):
            for mm in re.finditer(r'(\w+)\s*=\s*"([^"]+)"', m.group(2)):
                d.setdefault("%s.%s" % (m.group(1), mm.group(1)), [mm.group(2)])
        fuera[sec] = d
    return fuera


def _total(d):
    return sum(len(v) for sec in d.values() for v in sec.values())


def _entidad(clave):
    """Clave normalizada para saber si dos entradas hablan de lo mismo.

    El mismo conjuro aparece en `spells` por su id y en `names` por su nombre
    ("vision_en_la_oscuridad" y "vision en la oscuridad"), y eso no es un icono repetido.
    """
    import unicodedata
    s = "".join(c for c in unicodedata.normalize("NFD", clave)
                if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def repetidos(d):
    """Iconos puestos en entidades DISTINTAS, que es lo que hay que evitar."""
    uso = collections.defaultdict(dict)
    for sec, entradas in d.items():
        for clave, iconos in entradas.items():
            for ic in iconos:
                uso[ic].setdefault(_entidad(clave), "%s/%s" % (sec, clave))
    return {ic: list(donde.values()) for ic, donde in uso.items() if len(donde) > 1}


def main():
    ahora = leer()
    if "--guardar" in sys.argv:
        json.dump(ahora, io.open(FOTO, "w", encoding="utf-8"), ensure_ascii=False, indent=1,
                  sort_keys=True)
        print("foto guardada: %d entradas, %d iconos" %
              (sum(len(v) for v in ahora.values()), _total(ahora)))
        return 0

    if not os.path.exists(FOTO):
        print("no hay foto de referencia; ejecuta primero:  python iconos_manuales.py --guardar")
        return 1
    antes = json.load(io.open(FOTO, encoding="utf-8"))

    perdidas, cambios = [], []
    for sec, entradas in antes.items():
        hoy = ahora.get(sec, {})
        for clave, iconos in entradas.items():
            if clave not in hoy:
                perdidas.append("%s/%s (%s)" % (sec, clave, ", ".join(iconos)))
            elif hoy[clave] != iconos:
                cambios.append("%s/%s: %s -> %s" % (sec, clave, iconos, hoy[clave]))
    nuevas = sum(1 for sec, e in ahora.items() for c in e if c not in antes.get(sec, {}))

    print("catalogo: %d entradas, %d iconos" %
          (sum(len(v) for v in ahora.values()), _total(ahora)))
    print("   entradas perdidas: %d" % len(perdidas))
    for x in perdidas[:12]:
        print("      %s" % x)
    print("   entradas cambiadas: %d" % len(cambios))
    for x in cambios[:12]:
        print("      %s" % x)
    print("   entradas nuevas: %d" % nuevas)

    rep = repetidos(ahora)
    print("   iconos usados en mas de una entrada: %d" % len(rep))
    for ic, donde in sorted(rep.items(), key=lambda x: -len(x[1]))[:8]:
        print("      %-44s %s" % (ic, ", ".join(donde[:3])))
    return 1 if perdidas or cambios else 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
