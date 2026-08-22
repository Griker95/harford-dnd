# -*- coding: utf-8 -*-
"""Alinea los nombres de herramientas del EQUIPO con la terminologia canonica.

La decision de llamarlo todo "Utiles de ..." se aplico a las profesiones pero no a la
lista de equipo, que seguia mezclando "Kit de herborista", "Herramientas de armero" y
"Utensilios de cocina" con los "Utiles de ..." ya migrados. El nombre canonico sale de
`prof_terminologia.json`, que es donde estan escritas esas decisiones.

Ademas fusiona los objetos que resultaron ser el mismo con dos nombres: "Kit de veneno" y
"Kit de envenenador" tenian la misma categoria, el mismo precio y la misma descripcion.

Se aplica en el pipeline (`extract_equipment.py` lo importa), no a mano sobre el .js.
"""
import io, json, os, re, unicodedata

_BASE = os.path.dirname(os.path.abspath(__file__))


def _sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def _canonicos():
    with io.open(os.path.join(_BASE, "prof_terminologia.json"), encoding="utf-8") as f:
        d = json.load(f)
    out = {}
    for grupo in ("tools", "vehicles"):
        for _clave, nombre in (d.get(grupo) or {}).items():
            # "Utiles de herborista" <- se indexa por el oficio para reconocer variantes
            oficio = re.sub(r"^(?:[uú]tiles|herramientas|utensilios|kit|juego)\s+de\s+", "",
                            _sa(nombre)).strip()
            if oficio: out[oficio] = nombre
    return out


CANON = _canonicos()

# variantes que no comparten la palabra del oficio con su nombre canonico
SINONIMOS = {
    "veneno": "envenenador", "venenos": "envenenador",
    "cocina": "cocinero", "herborista": "herboristeria",
    "ladron": "ladron", "sutura": "sanador",
}


def nombre_canonico(nombre):
    """Devuelve el nombre canonico de una herramienta, o el mismo si no lo es."""
    m = re.match(r"(?i)^\s*(?:[uú]tiles|herramientas|utensilios|kit|juego)\s+de\s+(.+?)\s*$", nombre or "")
    if not m: return nombre
    oficio = _sa(m.group(1))
    oficio = SINONIMOS.get(oficio, oficio)
    return CANON.get(oficio, nombre)


def normalizar(items):
    """Renombra las herramientas y funde los duplicados que quedan con el mismo nombre."""
    vistos, salida, fundidos = {}, [], []
    for it in items:
        nuevo = nombre_canonico(it.get("name"))
        if nuevo != it.get("name"):
            it = dict(it)
            it["name"] = nuevo
            it["id"] = re.sub(r"[^a-z0-9]+", "-", _sa(it.get("kind", "obj") + "-" + nuevo)).strip("-")
        clave = (_sa(it["name"]), it.get("kind"))
        if clave in vistos:
            # el mismo objeto con dos nombres: se queda el que tenga descripcion
            previo = vistos[clave]
            if len(it.get("note") or "") > len(previo.get("note") or ""):
                salida[salida.index(previo)] = it
                vistos[clave] = it
            fundidos.append(it["name"])
            continue
        vistos[clave] = it
        salida.append(it)
    return salida, fundidos


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    print("nombres canonicos conocidos: %d" % len(CANON))
    for p in ("Kit de herborista", "Herramientas de armero", "Utensilios de cocina",
              "Kit de veneno", "Kit de envenenador", "Útiles de disfraz", "Antorcha"):
        print("   %-26s -> %s" % (p, nombre_canonico(p)))
