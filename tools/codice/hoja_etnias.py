# -*- coding: utf-8 -*-
"""Hoja para elegir el icono de cada reino/etnia de una raza (los siete humanos).

No busca candidatos por lexico como la hoja de rasgos: un reino no se parece a ninguna
palabra del volcado, asi que los candidatos van escogidos a mano de las familias que de
verdad existen. La familia `hd_book2motif_*` cubre cuatro de los siete; los otros tres se
completan con lo que hay.

Reutiliza la plantilla de `hoja_rasgos.py` para que las dos hojas se usen igual.
"""
import io
import json
import os
import re
import sys

from hoja_rasgos import PLANTILLA_CABECERA, PLANTILLA_PIE, png

BASE = os.path.dirname(os.path.abspath(__file__))
WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-data.js"
SALIDA = os.path.join(BASE, "hoja_etnias.html")

# Ventormenta sale como `hurlevent`, que es su nombre en frances: buscando "stormwind" no
# aparece. Stromgarde solo tiene el motivo; de Arathor en el volcado solo hay armas.
CANDIDATOS = {
    "alterac": ["achievement_zone_alteracmountains_01", "eps_lol_tft_syndicateemblem",
                "eps_wc3h_beveperenolde", "portal_alteracvalleyalliance",
                "creatureportrait_portal_alteracvalleyhorde"],
    "dalaran": ["achievement_reputation_kirintor", "hots_bannerdalaran",
                "eps_wc3h_eyeofdalaran", "inv_legion_faction_kirintor",
                "achievement_kirintor_offensive", "eps_arc_sign_dalaran"],
    "gilneas": ["hd_book2motif_gilneas", "inv_misc_tabard_gilneas", "hd_book2motif_gilneasold",
                "achievement_zone_gilneas_01", "achievement_zone_gilneas_02"],
    "kul_tiras": ["inv__faction_proudmooreadmiralty", "eps_arc_vault_kultiras",
                  "book_kultiras1", "eps_arc_book_kultiras1", "eps_arc_poster_kultiras_prison"],
    "lordaeron": ["hd_book2motif_lordaeron", "eps_wc3h_lordaeronsymbol",
                  "hd_book2motif_lordaeronlight", "hd_book2motif_lordaeronscarlet",
                  "hd_book2motif_lordaeroncorrupted"],
    "ventormenta": ["hd_book2motif_hurlevent", "hots_bannerstormwind",
                    "spell_arcane_portalstormwind", "eps_arc_vault_stormwind"],
    "stromgarde": ["hd_book2motif_stromgarde", "hd_book2motif_tyr", "hd_book2motif_silverhand"],
}


def etnias():
    """Los reinos tal y como han quedado en el kb, para no repetir nombres ni ids a mano."""
    txt = io.open(WEB, encoding="utf-8").read()
    d = json.loads(re.search(r"=\s*(\{[\s\S]*\})", txt).group(1))
    for r in d["races"]:
        for e in r.get("ethnicities") or []:
            yield r["name"], e


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    filas = list(etnias())
    # la cabecera es la misma plantilla que la hoja de rasgos, asi que hay que corregirle
    # el texto: si no, esta hoja se anuncia como "rasgos de raza, subraza y trasfondo"
    cabecera = ((PLANTILLA_CABECERA % len(filas))
                .replace("Iconos de rasgos", "Iconos de reinos y etnias")
                .replace("rasgos de raza, subraza y trasfondo que no tienen dibujo",
                         "reinos humanos del compendio, para ponerles icono"))
    partes = [cabecera]
    partes.append("<h2>Reinos y etnias</h2>")
    faltan = []
    for raza, e in filas:
        partes.append('<div class="fila" data-k="%s">' % e["id"])
        partes.append('<div class="cab"><b>%s</b><span class="meta">%s · %s</span></div>'
                      % (e["name"], raza, e["id"]))
        partes.append('<div class="ops">')
        puestos = 0
        for c in CANDIDATOS.get(e["id"], []):
            dato = png(c)
            if not dato:
                faltan.append((e["name"], c))
                continue
            partes.append('<button class="op" data-i="%s"><img src="%s" alt=""><small>%s</small></button>'
                          % (c, dato, c))
            puestos += 1
        if not puestos:
            faltan.append((e["name"], "SIN NINGUN CANDIDATO"))
        partes.append('<button class="op nada" data-i="">Ninguno</button></div></div>')
    partes.append(PLANTILLA_PIE)
    io.open(SALIDA, "w", encoding="utf-8").write("\n".join(partes))
    print("hoja escrita: %s" % SALIDA)
    print("   reinos: %d | tamano: %.2f MB" % (len(filas), os.path.getsize(SALIDA) / 1e6))
    for quien, cual in faltan:
        print("   sin PNG: %-14s %s" % (quien, cual))


if __name__ == "__main__":
    main()
