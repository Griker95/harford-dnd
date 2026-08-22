# -*- coding: utf-8 -*-
"""Propone iconos con logica para los conjuros que no tienen uno elegido a mano.

Como busca, de mejor a peor:

  1. el nombre ingles del conjuro entero dentro del nombre del icono
     ("coneofcold" -> eps_bg3_coneofcold);
  2. una palabra larga de ese nombre ("insectplague" -> "insect", "plague");
  3. los sinonimos de su tipo de dano y de su concepto, de `sinonimos_iconos.json`
     ("timestop" no existe en WoW, pero "chrono" y "hourglass" si).

Dos reglas que no se saltan:

  - **Sentido.** El nombre del icono tiene que contener algo que hable del conjuro. Si no
    hay nada, se queda sin propuesta antes que ponerle un dibujo que engane.
  - **Sin repetir.** Un icono que ya use otra entrada -- incluidas las 794 elecciones
    manuales del catalogo -- no se propone otra vez.

El ingles sale de `glosario_ingles.json` y se usa SOLO aqui, para buscar. No sustituye a
ningun nombre del compendio.

Solo propone: escribe `propuestas_iconos.json` y no toca el catalogo.
"""
import collections
import io
import json
import os
import re
import sys
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
DUMP = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
KB = os.path.join(BASE, "kb_icons.json")
CAT = r"C:/Users/marco/Documents/New project/Harford/Compendium/HarfordIconCatalog.lua"

# familias que son iconos de habilidad o hechizo; las demas suelen ser objetos y quedan mal
FAMILIAS = ("spell_", "ability_", "eps_", "hots_", "d3_", "dos2_", "smite_", "hd_", "wh_",
            "achievement_", "inv_")


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def _segmentos(nombre):
    return set(re.split(r"[_0-9]+", nombre))


def cargar_iconos():
    return [f[:-4] for f in os.listdir(DUMP) if f.endswith(".png")]


def usados_ya():
    """Todo icono que ya esta puesto: catalogo manual y compendio."""
    fuera = set()
    txt = io.open(CAT, encoding="utf-8").read()
    fuera |= set(re.findall(r'"([a-z0-9_]+)"', txt))
    kb = json.load(io.open(KB, encoding="utf-8"))

    def rec(o):
        if isinstance(o, dict):
            if isinstance(o.get("icon"), str):
                fuera.add(o["icon"])
            for v in o.values():
                if not isinstance(v, str):
                    rec(v)
        elif isinstance(o, list):
            for v in o:
                rec(v)
    rec(kb)
    return fuera


# Un icono de hechizo o de habilidad de clase casi siempre sirve; uno de montura, de
# objeto de mision o de carta de tarot casi nunca, aunque su nombre contenga la palabra.
PESO_FAMILIA = {"eps_bg3_": 14, "spell_": 12, "ability_": 10, "hots_": 6, "d3_": 6,
                "dos2_": 6, "smite_": 5, "eps_": 4, "hd_": 3, "achievement_": -10,
                "inv_": -14}
# palabras que delatan que el icono no es de un hechizo aunque encaje por texto
BASURA = ("mount", "ticket", "tarot", "ball", "food", "drink", "pet_", "toy", "quest",
          "item", "dmc", "armor", "camp", "portrait", "profileicon", "emblem",
          "boss", "misc_", "garrison", "profession", "trade", "banner", "tabard",
          "shirt", "helm", "boots", "glove", "chest_", "shoulder", "bracer", "cape",
          "fishing", "pickaxe", "ore", "herb", "cooking", "archaeology", "battlepet")


def _peso_familia(ic):
    for pref, v in PESO_FAMILIA.items():
        if ic.startswith(pref):
            return v
    return 0


def _penaliza(ic):
    return -25 * sum(1 for b in BASURA if b in ic)


def candidatos(spell, ingles, iconos, sinonimos, vetados):
    """Lista de (icono, motivo) de mejor a peor, sin ninguno ya usado."""
    marcados, vistos = {}, set()

    def anota(ic, motivo, base):
        if ic in vetados:
            return
        p = base + _peso_familia(ic) + _penaliza(ic)
        if p <= 0:
            return
        if ic not in marcados or marcados[ic][0] < p:
            marcados[ic] = (p, motivo)

    def por(clave, motivo, base, modo="empieza"):
        """modo: 'exacto' el segmento entero, 'empieza' un segmento que empiece asi.

        No vale buscar la palabra suelta dentro del nombre: "ship" aparece dentro de
        "markman·ship" y "wind" dentro de "second·wind", y ninguno de los dos tiene que
        ver con un barco ni con el viento.
        """
        if not clave or len(clave) < 4:
            return
        for ic in iconos:
            if not ic.startswith(FAMILIAS):
                continue
            segs = _segmentos(ic)
            if clave in segs or (modo == "empieza" and any(s.startswith(clave) for s in segs)):
                anota(ic, motivo, base)

    # 1) el nombre ingles entero
    por(ingles, "nombre exacto", 100, "exacto")
    por(ingles, "nombre dentro del icono", 70, "empieza")
    # 2) palabras largas del nombre ingles
    for palabra in sorted(re.findall(r"[a-z]{5,}", ingles or ""), key=len, reverse=True):
        if palabra in ("scale", "great", "lesser", "greater"):
            continue
        por(palabra, "palabra '%s'" % palabra, 30 + len(palabra))
    # 3) sinonimos del tipo de dano y de los conceptos del conjuro
    conceptos = []
    dano = (spell.get("damage") or "").split()
    if len(dano) >= 2:
        conceptos.append({"fuego": "fire", "frio": "cold", "rayo": "lightning",
                          "trueno": "thunder", "acido": "acid", "veneno": "poison",
                          "necrotico": "necrotic", "radiante": "radiant",
                          "psiquico": "psychic", "fuerza": "force"}.get(nk(dano[-1])))
    for clave, palabras in sinonimos.items():
        if clave.startswith("_"):
            continue
        if clave in conceptos or any(p in (ingles or "") for p in palabras[:2]):
            for i, p in enumerate(palabras):
                # el primer sinonimo de la lista es el mas literal, los siguientes valen menos
                por(p, "sinonimo de %s" % clave, max(6, 26 - 3 * i))
    return [(ic, m) for ic, (p, m) in sorted(marcados.items(), key=lambda x: -x[1][0])]


def main():
    iconos = cargar_iconos()
    sinonimos = json.load(io.open(os.path.join(BASE, "sinonimos_iconos.json"), encoding="utf-8"))
    glosario = {k: v for k, v in json.load(
        io.open(os.path.join(BASE, "glosario_ingles.json"), encoding="utf-8")).items()
        if not k.startswith("_")}
    kb = json.load(io.open(KB, encoding="utf-8"))
    txt = io.open(CAT, encoding="utf-8").read()
    m = re.search(r"Catalog\.spells\s*=\s*\{(.*?)\n\}", txt, re.S)
    ids = set(re.findall(r"(\w+)\s*=\s*\{", m.group(1)))
    m2 = re.search(r"Catalog\.names\s*=\s*\{(.*?)\n\}", txt, re.S)
    noms = {x.lower() for x in re.findall(r'\["([^"]+)"\]', m2.group(1))}

    faltan = [s for s in kb["spells"] if s["id"] not in ids and s["name"].lower() not in noms]
    vetados = usados_ya()
    print("conjuros sin icono elegido: %d" % len(faltan))
    print("iconos ya en uso que no se pueden repetir: %d" % len(vetados))

    propuestas, sin_ingles, sin_nada = {}, [], []
    # Se reparte por calidad y no por orden alfabetico: el que tiene una coincidencia
    # fuerte se queda con su icono antes de que otro se lo lleve por un sinonimo flojo.
    # Sin esto, "Controlar vientos" se quedaba con el "windwalk" de "Andar en el viento".
    conNombre, resto = [], []
    for s in faltan:
        ing = glosario.get(s["name"])
        if not ing:
            sin_ingles.append(s["name"])
            continue
        primero = candidatos(s, ing, iconos, sinonimos, vetados)
        exacto = primero and primero[0][1] == "nombre exacto"
        (conNombre if exacto else resto).append((s, ing))
    reservados = set()
    for s, ing in conNombre + sorted(resto, key=lambda x: (x[0].get("level", 0), x[0]["name"])):
        cand = candidatos(s, ing, iconos, sinonimos, vetados | reservados)
        if not cand:
            sin_nada.append(s["name"])
            continue
        propuestas[s["name"]] = {"nivel": s.get("level"), "ingles": ing,
                                 "escuela": s.get("school"),
                                 "candidatos": [{"icono": i, "motivo": m} for i, m in cand[:8]]}
        reservados.add(cand[0][0])          # el primero queda reservado para el

    json.dump(propuestas, io.open(os.path.join(BASE, "propuestas_iconos.json"), "w",
                                  encoding="utf-8"), ensure_ascii=False, indent=1)
    print()
    print("con propuesta: %d" % len(propuestas))
    print("sin nombre ingles en el glosario: %d %s" % (len(sin_ingles), sin_ingles[:6]))
    print("sin ningun icono con sentido: %d %s" % (len(sin_nada), sin_nada[:8]))
    print()
    motivos = collections.Counter(v["candidatos"][0]["motivo"].split(" '")[0]
                                  for v in propuestas.values())
    print("por que se propone el primero:")
    for a, b in motivos.most_common():
        print("   %-26s %d" % (a, b))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
