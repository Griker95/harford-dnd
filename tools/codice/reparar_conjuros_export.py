# -*- coding: utf-8 -*-
"""Recompone los campos de un conjuro exportado de un manual en PDF.

El PDF va a dos columnas y el OCR corta el componente material a mitad de linea: el
principio se queda en "componentes" con el parentesis sin cerrar y la cola aparece pegada
detras de la duracion.

    componentes: "V, S, M (un diamante con un valor de,"
    duracion:    "Instantáneo al menos, 500 po, que es consumido como parte del conjuro)"

Aqui se separa la duracion de verdad, que siempre es una de las pocas formas que usa el
manual, y el resto se devuelve al material. Si no se reconoce la duracion no se toca nada:
mejor un campo raro que uno inventado.
"""
import re

# el \b final es imprescindible: sin el, "8 horas" casaba como "8 hora" y la ese
# suelta se iba a parar al componente material
UNIDAD = r"(?:asaltos?|rondas?|turnos?|minutos?|horas?|d[ií]as?|a[ñn]os?)\b"
_DURACION = re.compile(
    r"^\s*(?:"
    r"[1lJI|]\s*nstant[áa]ne[oa]"              # el OCR confunde la I de Instantaneo
    r"|Instant[áa]ne[oa]"
    r"|Especial|Permanente"
    r"|Hasta\s+que\s+sea\s+disipad[oa](?:\s+o\s+activad[oa])?"
    r"|Hasta\s+el\s+final\s+de\s+tu\s+(?:pr[óo]ximo\s+)?turno"
    r"|Concentraci[óo]n,?\s*hasta\s+\d+\s*" + UNIDAD +
    r"|Concentraci[óo]n"
    r"|\d+\s*" + UNIDAD +
    r")\s*[.,]?", re.I)


def _normaliza(d):
    return re.sub(r"(?i)^[1lJI|]\s*nstant", "Instant", (d or "").strip())


def reparar(entrada):
    """Devuelve (componentes, duracion) recompuestos. No modifica la entrada."""
    comp = (entrada.get("componentes") or "").strip()
    dur = _normaliza(entrada.get("duracion"))
    if comp.count("(") <= comp.count(")"):
        return comp, dur
    m = _DURACION.match(dur)
    if not m:
        return comp, dur
    cola = dur[m.end():].strip()
    if not cola:
        return comp, dur
    comp = (comp + " " + cola).strip()
    if comp.count("(") > comp.count(")"):     # el manual cierra el parentesis del material
        comp += ")"
    return comp, _normaliza(m.group(0).strip().rstrip(".,"))


if __name__ == "__main__":
    import io
    import json
    import os
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    D = r"C:/Users/marco/Documents/New project/RuleSource/Export"
    tot = arreglados = quedan = 0
    for f in ("conjuros_d_d_5_0_edge_manual_del_jugador", "conjuros_tasha",
              "conjuros_warcraft_5_edici_n_compressed", "conjuros_xanathar"):
        ruta = os.path.join(D, f + ".json")
        if not os.path.exists(ruta):
            continue
        for e in json.load(io.open(ruta, encoding="utf-8")):
            tot += 1
            roto = (e.get("componentes") or "").count("(") > (e.get("componentes") or "").count(")")
            c, d = reparar(e)
            if roto and c.count("(") == c.count(")"):
                arreglados += 1
                if arreglados <= 6:
                    print("  %-26s comp=%r\n%30sdur=%r" % (e["nombre"][:25], c[:78], "", d))
            elif roto:
                quedan += 1
                if quedan <= 6:
                    print("  SIN ARREGLAR %-18s dur=%r" % (e["nombre"][:17], (e.get("duracion") or "")[:60]))
    print("\nentradas: %d | recompuestas: %d | sin reconocer la duracion: %d" % (tot, arreglados, quedan))
