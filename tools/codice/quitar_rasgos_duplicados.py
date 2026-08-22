# -*- coding: utf-8 -*-
"""Quita del libro los rasgos repetidos que dejaron los scripts de completado.

Al traer del manual los rasgos que faltaban, algunos entraron aunque el addon ya los
tenia: el libro los titula de otra manera ("Truco Adicional" frente a "Truco adicional
(controlar llamas)", "Druidismo" frente a "Druidico") y el emparejado por nombre no los
reconocio. En la ficha salen dos veces, con el mismo contenido.

Se borran solo entradas ANADIDAS (las que no estan en la version de HEAD del fichero) y
solo cuando hay un rasgo que las cubre:

  - un rasgo YA EXISTENTE del mismo nivel, cerca en el fichero (es decir, de la misma
    clase o subclase), cuyo nombre es el mismo o el mismo con una precision entre
    parentesis;
  - o una entrada anadida anterior con el MISMO texto, que es lo que pasa con los rasgos
    que el libro repite a varios niveles ("Toque de Vida (1/dia)", "(2/dia)", "(3/dia)"):
    se conserva la del nivel mas bajo y la tabla de progresion sigue diciendo a que nivel
    mejora.

Sin --apply solo informa.
"""
import collections
import difflib
import io
import json
import os
import re
import subprocess
import sys
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
RAIZ = r"C:/Users/marco/Documents/New project"
REL = "Harford/DnD/Data/HarfordDnDBook.lua"
LUA = os.path.join(RAIZ, REL)

# Cabecera de una clase del libro. Dos rasgos son del mismo bloque cuando caen entre las
# mismas dos cabeceras: medir la distancia en caracteres se quedaba corto en las clases
# largas y dejaba pasar duplicados.
CLASE = re.compile(r'\{\s*id = "[a-z_]+", name = "[^"]+", desc = "[^"]*", hitDie')

# La descripcion se acota con [^"]* y SIN re.S a proposito: el libro escapa las comillas
# de dentro del texto, y con un .*? multilinea el motor se tragaba entradas enteras hasta
# el siguiente `effects = {}` y dejaba rasgos sin ver.
# para comparar valen todos los rasgos, declaren efectos o no. Entre `type` y
# `description` puede haber campos sueltos (`icon`), y sin admitirlos el rasgo no se ve.
CUALQUIERA = re.compile(
    r'\{ id = "([a-z0-9_]+)", level = (\d+), name = "([^"]*)", '
    r'type = "[^"]*", (?:[a-zA-Z]+ = "[^"]*", )*description = "([^"]*)"')
# para borrar, solo los que ocupan una linea entera y no declaran efectos: son los que
# escribieron los scripts de completado, y quitarlos no parte ninguna tabla
BORRABLE = re.compile(
    r'[ \t]*\{ id = "([a-z0-9_]+)", level = (\d+), name = "([^"]*)", '
    r'type = "[^"]*", description = "([^"]*)", effects = \{\} \},\n')


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", s.lower())).strip()


# Rasgos que el libro titula de una manera y el addon de otra: van en un fichero aparte
# porque los completadores usan la misma tabla para no volver a anadirlos.
_EQUIV = {}
_eq = os.path.join(BASE, "equivalencias_rasgos.json")
if os.path.exists(_eq):
    _EQUIV = {nk(k): nk(v) for k, v in json.load(io.open(_eq, encoding="utf-8")).items()
              if not k.startswith("_")}


def _cubre(nombre_viejo, nombre_nuevo):
    """Los dos titulan el mismo rasgo, lleve la precision entre parentesis uno u otro.

    Vale en los dos sentidos: el addon dice "Truco adicional (controlar llamas)" donde el
    libro dice "Truco Adicional", pero tambien "Toque de vida" donde el libro dice "Toque
    de Vida (1/dia)". La igualdad de nivel es la que evita que esto se lleve por delante
    una mejora posterior del mismo rasgo.
    """
    a, b = nk(nombre_viejo), nk(nombre_nuevo)
    if _EQUIV.get(b) == a or _EQUIV.get(a) == b:
        return True
    return a == b or a.startswith(b + " ") or b.startswith(a + " ")


def _mismo_id(id_viejo, id_nuevo):
    """Los dos ids acaban en el mismo slug, que sale del titulo del rasgo en su fuente."""
    sufijo = id_viejo.split("_", 1)[1] if "_" in id_viejo else id_viejo
    return len(sufijo) > 10 and id_nuevo.endswith(sufijo)


def _mismo_texto(a, b):
    """Dos redacciones del mismo rasgo.

    Se comparan las primeras palabras y no el texto entero: la version del libro suele ser
    mucho mas larga que la del addon y comparar de punta a punta hunde el parecido aunque
    empiecen diciendo exactamente lo mismo.
    """
    x, y = nk(a), nk(b)
    if not x or not y:
        return False
    if difflib.SequenceMatcher(None, x[:90], y[:90]).ratio() >= 0.8:
        return True
    # o el rasgo del addon, que es un resumen, aparece casi entero dentro del texto largo
    # del libro: entonces los dos cuentan la misma regla
    comun = difflib.SequenceMatcher(None, x, y).find_longest_match(0, len(x), 0, len(y)).size
    return comun >= 55 and comun >= 0.7 * len(x)


def main():
    cur = io.open(LUA, encoding="utf-8", newline="").read()
    viejo = subprocess.run(["git", "-C", RAIZ, "show", "HEAD:" + REL],
                           capture_output=True).stdout.decode("utf-8", "ignore")
    ids_viejos = {m.group(1) for m in re.finditer(r'id = "([a-z0-9_]+)"', viejo)}

    entradas = [(m.group(1), int(m.group(2)), m.group(3), m.group(4), m.start(), m.end())
                for m in CUALQUIERA.finditer(cur)]
    borrables = {m.group(1): (m.start(), m.end()) for m in BORRABLE.finditer(cur)}
    fronteras = [m.start() for m in CLASE.finditer(cur)]

    def bloque(pos):
        """Indice de la clase en la que cae esa posicion."""
        n = 0
        for f in fronteras:
            if f <= pos:
                n += 1
            else:
                break
        return n

    # Un id repetido DENTRO de la misma clase es siempre un error: el addon indexa por id
    # y la segunda entrada pisa a la primera. Pasa cuando el completador vuelve a generar
    # un rasgo que ya existia y le sale el mismo id.
    _porid = collections.defaultdict(list)
    for e in entradas:
        _porid[(e[0], bloque(e[4]))].append(e)
    repetidos = {e[0] for k, v in _porid.items() if len(v) > 1 for e in v if e[0] in borrables}

    if repetidos:
        print("AVISO: ids repetidos dentro de una misma clase; el addon indexa por id "
              "y la segunda entrada pisa a la primera: %s" % ", ".join(sorted(repetidos)))

    fuera = []
    for i, (rid, lv, nombre, desc, ini, fin) in enumerate(entradas):
        if rid in ids_viejos or rid not in borrables:
            continue
        # 1) lo cubre un rasgo que ya existia, del mismo nivel y del mismo bloque
        cubierto = next((e for e in entradas
                         if e[0] in ids_viejos and e[1] == lv
                         and bloque(e[4]) == bloque(ini) and _cubre(e[2], nombre)), None)
        if cubierto:
            fuera.append((rid, lv, nombre, "ya estaba como '%s'" % cubierto[2]))
            continue
        # 1b) el mismo rasgo con otro titulo ("Druidismo" por "Druidico"): se reconoce
        # porque el texto dice lo mismo, al mismo nivel y en el mismo bloque
        parecido = next((e for e in entradas
                         if e[0] in ids_viejos and e[1] == lv
                         and bloque(e[4]) == bloque(ini)
                         and _mismo_texto(e[3], desc)), None)
        if parecido:
            fuera.append((rid, lv, nombre, "dice lo mismo que '%s'" % parecido[2]))
            continue
        # 1c) el addon lo titulo de otra manera y lo reescribio entero ("Guardas
        # demoniacas" por "Defensa sin Armadura", "Forjado de almas" por "Forja de
        # Almas"): ahi el texto ya no sirve, pero si el nombre o el propio id, que en
        # ambos ficheros se deriva del titulo del rasgo en su fuente
        otro = next((e for e in entradas
                     if e[0] in ids_viejos and e[1] == lv and bloque(e[4]) == bloque(ini)
                     and (_mismo_id(e[0], rid)
                          or difflib.SequenceMatcher(None, nk(e[2]), nk(nombre)).ratio() >= 0.9)),
                    None)
        if otro:
            fuera.append((rid, lv, nombre, "es '%s' con otro titulo" % otro[2]))
            continue
        # 2) es la repeticion a otro nivel de un rasgo anadido antes, con el mismo texto
        gemelo = next((e for e in entradas[:i]
                       if e[0] not in ids_viejos and e[3] == desc
                       and bloque(e[4]) == bloque(ini)), None)
        if gemelo:
            fuera.append((rid, lv, nombre, "mismo texto que '%s' (nv%d)" % (gemelo[2], gemelo[1])))

    print("rasgos anadidos: %d | a quitar: %d"
          % (sum(1 for e in entradas if e[0] not in ids_viejos), len(fuera)))
    for rid, lv, nombre, por in fuera:
        print("   nv%-2d %-34s %s" % (lv, nombre[:33], por))

    if "--apply" not in sys.argv or not fuera:
        return
    quitar = {r[0] for r in fuera}
    salida, ultimo = [], 0
    for rid in sorted(quitar, key=lambda r: borrables[r][0]):
        ini, fin = borrables[rid]
        salida.append(cur[ultimo:ini])
        ultimo = fin
    salida.append(cur[ultimo:])
    io.open(LUA, "w", encoding="utf-8", newline="").write("".join(salida))
    print("\nquitados del libro: %d" % len(quitar))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
