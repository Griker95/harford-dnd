# -*- coding: utf-8 -*-
"""Edad y alineamiento de cada raza como datos, no solo como parrafo.

Los libros lo cuentan en prosa ("maduran al mismo ritmo que los humanos, pero no se les
considera adultos hasta los 60") y asi no se puede comparar una raza con otra de un
vistazo. Aqui van los numeros, sacados de ese mismo texto.

Que hay detras de cada cifra:
  - "maduran al mismo ritmo que los humanos" -> 18, que es la referencia del manual;
  - "menos de un siglo" -> 80, la vida media humana, no el tope;
  - "miles de anos" -> 1000, porque ningun libro da una cifra para elfos de la noche,
    draenei ni nocheterna.

El alineamiento es una TENDENCIA cultural, no un requisito: los libros siempre dicen "la
mayoria" o "tienden a". Se marca como tal para que la tabla no le de mas autoridad de la
que tiene.
"""

# raza -> (madurez fisica, adultez para su gente, esperanza de vida, tendencia)
# Los textos van tal cual se leen en la ficha; None cuando la raza no admite una cifra.
RAZAS = {
    "humano":      ("18 años", "18 años", "~80 años", "Cualquiera"),
    "enano":       ("18 años", "40 años", "~320 años", "Legal bueno"),
    "elfo_noche":  ("18 años", "100 años", "Milenios", "Caótico bueno"),
    "semielfo":    ("18 años", "20 años", "~180 años", "Caótico bueno"),
    "gnomo":       ("18 años", "40 años", "350–500 años", "Bueno"),
    "draenei":     ("20 años", "20 años", "Milenios", "Bueno"),
    "huargen":     ("18 años", "18 años", "~80 años", "Caótico"),
    "orco":        ("14 años", "14 años", "~75 años", "Caótico"),
    # la no-muerte detiene el proceso: su edad es la que tenia al morir
    "renegado":    ("La que tuviera al morir", None, "Indefinida", "El de su vida, tiende al caos"),
    "tauren":      ("15 años", "15 años", "~95 años", "Legal"),
    "trol":        ("16 años", "16 años", "Más de un siglo", "Legal neutral"),
    "elfo_sangre": ("18 años", "60 años", "Siglos; milenios con la Fuente del Sol", "Legal"),
    "goblin":      ("20 años", "20 años", "~150 años", "Caótico neutral"),
    "pandaren":    ("18 años", "18 años", "~100 años", "Neutral o bueno"),
    "nocheterna":  ("18 años", "100 años", "Milenios", "Legal"),
    "elfo_vacio":  ("18 años", "60 años", "Siglos; milenios para muchos", "Legal"),
    # madura a los 5, pero la adultez la decide el clan
    "vulpera":     ("5 años", "Cuando su clan lo decide", "~75 años", "Neutral"),
}


# Las subrazas HEREDAN de su raza: ni el Manual ni el Libro 1 les dan edad o alineamiento
# propios. Las cinco menciones que parecen suyas son el parrafo de la raza repetido dentro
# del capitulo, palabra por palabra.
#
# Estas siete se matizan con el lore de Warcraft, NO con los libros de reglas. Van marcadas
# para que en la ficha se vea de donde sale el matiz y nadie lo confunda con una regla.
SUBRAZAS_LORE = {
    "draenei/man_ari":      {"lifespan": "Milenios; no envejecen desde su corrupción",
                             "alignment": "Malvado",
                             "porque": "Son eredar corrompidos por la Legión"},
    "draenei/tabido":       {"lifespan": "Siglos, menos que un draenei íntegro",
                             "porque": "La degeneración les acorta la vida"},
    "elfo_noche/altonato":  {"lifespan": "Milenios; conservaron la inmortalidad más tiempo",
                             "porque": "Los shen'dralar de Dire Maul"},
    "trol/zandalari":       {"lifespan": "Siglos, muy por encima del resto de trolls",
                             "porque": "Lore de Zandalar"},
    "gnomo/mecagnomo":      {"lifespan": "~500 años, alargada por las prótesis",
                             "porque": "Mecagon"},
    "renegado/elfo":        {"ageMature": "La que tuviera al morir", "ageAdult": None,
                             "lifespan": "Indefinida",
                             "porque": "Ya es un no-muerto"},
    "enano/hierro_negro":   {"alignment": "Legal neutral",
                             "porque": "Siglos de servidumbre a Ragnaros"},
}


def aplicar(kb):
    puestas, sin_datos, con_lore = 0, [], []
    for r in kb.get("races", []):
        datos = RAZAS.get(r["id"])
        if not datos:
            sin_datos.append(r["name"])
            continue
        madurez, adultez, vida, tendencia = datos
        r["ageMature"] = madurez
        r["ageAdult"] = adultez
        r["lifespan"] = vida
        r["alignment"] = tendencia
        puestas += 1

        for s in r.get("subraces", []):
            for campo in ("ageMature", "ageAdult", "lifespan", "alignment"):
                s[campo] = r.get(campo)
            lore = SUBRAZAS_LORE.get(r["id"] + "/" + s["id"])
            if lore:
                for campo, valor in lore.items():
                    if campo != "porque":
                        s[campo] = valor
                s["loreNote"] = lore["porque"]
                con_lore.append(s["name"])
    return puestas, sin_datos, con_lore
