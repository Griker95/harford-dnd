# -*- coding: utf-8 -*-
"""Que le falta al alcance acordado para estar completo.

Alcance: razas y subrazas, trasfondos, clases y subclases hasta nivel 6, y conjuros hasta
nivel 4 con los trucos. Lo de fuera se cuenta aparte y no se toca.

No arregla nada: mide y enumera, para que el plan salga de datos y no de impresiones.

Una auditoria que da falsos positivos es peor que no tenerla, porque se deja de mirar. Los
tres que daba esta y por que estaban mal:

  - "rasgo sin texto" por longitud: un rasgo de incremento dice "Fuerza +1." y eso son diez
    caracteres CORRECTOS. Ahora se mira si el texto esta VACIO o si parece CORTADO (corto y
    sin cerrar con puntuacion), que es lo que de verdad indica un problema.
  - "subclase sin rasgo de nivel 3": el 3 estaba puesto a mano y no es universal. El Druida,
    el Mago y el Brujo eligen a nivel 2, y el Sacerdote a nivel 1. Ahora el nivel de cada
    clase se DEDUCE de sus propias subclases y se senala la que se sale de su grupo.
  - los campos de conjuro se comprobaban con una condicion que nunca era cierta, asi que ese
    bloque no miraba nada.
"""
import collections
import io
import json
import os
import re
import sys

WEB = r"C:/Users/marco/Documents/harfordweb/js"

# Cierres validos de una frase completa. Un texto que cierra bien esta acabado por corto que
# sea ("Fuerza +1."); uno que NO cierra suele estar cortado, y eso no depende de la longitud:
# de los 620 rasgos del compendio solo 3 no cierran, y los tres acaban en una FORMULA
# ("= 8 + Bonus Competencia + Mod. Sabiduria"), que tampoco lleva punto y esta completa.
_CERRADO = re.compile(r"[.!?:)\]\"»…]$")
# el punto de "Mod." va DENTRO de la formula, asi que la cola no puede excluir puntos
_FORMULA = re.compile(r"[=+][^\n]{0,60}$")


def kb():
    t = io.open(os.path.join(WEB, "compendium-data.js"), encoding="utf-8").read()
    return json.loads(re.search(r"=\s*(\{[\s\S]*\})", t).group(1))


def vacio(txt):
    return not (txt or "").strip()


def cortado(txt):
    """Texto que parece haberse quedado a medias, no simplemente breve."""
    t = (txt or "").strip()
    if not t:
        return True
    return not _CERRADO.search(t) and not _FORMULA.search(t)


def flojo(txt, minimo):
    """Para presentaciones: ahi la longitud SI dice algo, porque son parrafos."""
    return len((txt or "").strip()) < minimo


def bloque(titulo):
    print()
    print("=" * 72)
    print(titulo)
    print("=" * 72)


def resumen(faltas):
    if not faltas:
        print("  nada que corregir")
        return
    c = collections.Counter(x[0] for x in faltas)
    for k, n in c.most_common():
        print("  %-42s %d" % (k, n))
        for tipo, quien, extra in [x for x in faltas if x[0] == k][:6]:
            print("        %s %s" % (quien[:58], extra))
        if n > 6:
            print("        ... y %d mas" % (n - 6))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    d = kb()

    # ---------- RAZAS Y SUBRAZAS ----------
    bloque("RAZAS Y SUBRAZAS")
    faltas = []
    for r in d["races"]:
        if flojo(r.get("desc"), 400):
            faltas.append(("raza sin presentacion", r["name"], "%d caracteres" % len(r.get("desc") or "")))
        for campo, etiqueta in (("size", "tamano"), ("speed", "velocidad"), ("faction", "faccion"),
                                ("icon", "icono"), ("iconF", "icono femenino"),
                                ("ageMature", "edad"), ("alignment", "alineamiento")):
            if not r.get(campo):
                faltas.append(("raza sin " + etiqueta, r["name"], ""))
        for f in r.get("traits") or []:
            if cortado(f.get("desc")):
                faltas.append(("rasgo de raza sin texto", r["name"] + " / " + f["name"], ""))
            if not f.get("icon"):
                faltas.append(("rasgo de raza sin icono", r["name"] + " / " + f["name"], ""))
        for s in r.get("subraces") or []:
            if flojo(s.get("desc"), 40):
                faltas.append(("subraza sin presentacion", r["name"] + " / " + s["name"], ""))
            for campo, etiqueta in (("icon", "icono"), ("iconF", "icono femenino")):
                if not s.get(campo):
                    faltas.append(("subraza sin " + etiqueta, r["name"] + " / " + s["name"], ""))
            for f in s.get("traits") or []:
                if cortado(f.get("desc")):
                    faltas.append(("rasgo de subraza sin texto", s["name"] + " / " + f["name"], ""))
                if not f.get("icon"):
                    faltas.append(("rasgo de subraza sin icono", s["name"] + " / " + f["name"], ""))
        for e in r.get("ethnicities") or []:
            if not e.get("icon"):
                faltas.append(("reino sin icono", r["name"] + " / " + e["name"], ""))
            if vacio(e.get("desc")):
                faltas.append(("reino sin texto", r["name"] + " / " + e["name"], ""))
    resumen(faltas)

    # ---------- TRASFONDOS ----------
    bloque("TRASFONDOS")
    faltas = []
    for b in d["backgrounds"]:
        propio = (b.get("source") or "").lower() in ("personalizado", "harford")
        if flojo(b.get("desc"), 150):
            faltas.append(("trasfondo sin presentacion", b["name"], "%d car." % len(b.get("desc") or "")))
        if not b.get("icon"):
            faltas.append(("trasfondo sin icono", b["name"], ""))
        if not (b.get("skills") or []):
            faltas.append(("trasfondo sin competencias", b["name"], ""))
        if not b.get("suggested"):
            # los propios de la casa no salen de ningun manual ni del export: si les falta,
            # es que nadie las ha escrito todavia, no que la importacion haya fallado
            faltas.append(("trasfondo sin caracteristicas sugeridas" + (" (propio)" if propio else ""),
                           b["name"], ""))
        if not (b.get("traits") or []):
            faltas.append(("trasfondo sin rasgos", b["name"], ""))
        if not b.get("art") and not propio:
            faltas.append(("trasfondo sin ilustracion", b["name"], ""))
        for f in b.get("traits") or []:
            if cortado(f.get("desc")):
                faltas.append(("rasgo de trasfondo sin texto", b["name"] + " / " + f["name"], ""))
            if not f.get("icon"):
                faltas.append(("rasgo de trasfondo sin icono", b["name"] + " / " + f["name"], ""))
        for v in b.get("variants") or []:
            if vacio(v.get("desc")):
                faltas.append(("variante sin texto", b["name"] + " / " + v["name"], ""))
            if not v.get("art"):
                faltas.append(("variante sin ilustracion", b["name"] + " / " + v["name"], ""))
    resumen(faltas)

    # ---------- CLASES Y SUBCLASES HASTA NIVEL 6 ----------
    bloque("CLASES Y SUBCLASES HASTA NIVEL 6")
    faltas = []
    for c in d["classes"]:
        if flojo(c.get("desc"), 200):
            faltas.append(("clase sin presentacion", c["name"], ""))
        if not c.get("classBlock"):
            faltas.append(("clase sin bloque de competencias y equipo", c["name"], ""))
        if not c.get("icon"):
            faltas.append(("clase sin icono", c["name"], ""))
        for f in c.get("features") or []:
            if (f.get("level") or 0) > 6:
                continue
            if cortado(f.get("desc")):
                faltas.append(("rasgo de clase sin texto", c["name"] + " / " + f["name"], "nv%s" % f.get("level")))
            if not f.get("icon"):
                faltas.append(("rasgo de clase sin icono", c["name"] + " / " + f["name"], ""))

        # A que nivel elige subclase ESTA clase: se deduce de sus propias subclases, porque
        # no es 3 para todas (Druida, Mago y Brujo a 2; Sacerdote a 1).
        primeros = [min((x.get("level") or 99) for x in (s.get("features") or [{}]))
                    for s in c.get("subclasses") or [] if s.get("features")]
        nivel_clase = collections.Counter(primeros).most_common(1)[0][0] if primeros else None
        for s in c.get("subclasses") or []:
            if flojo(s.get("desc"), 40):
                faltas.append(("subclase sin presentacion", c["name"] + " / " + s["name"], ""))
            if not s.get("icon"):
                faltas.append(("subclase sin icono", c["name"] + " / " + s["name"], ""))
            if not (s.get("features") or []):
                faltas.append(("subclase sin rasgos", c["name"] + " / " + s["name"], ""))
            elif nivel_clase is not None:
                suyo = min(x.get("level") or 99 for x in s["features"])
                if suyo != nivel_clase:
                    faltas.append(("subclase que empieza a otro nivel que sus hermanas",
                                   c["name"] + " / " + s["name"], "nv%d frente a nv%d" % (suyo, nivel_clase)))
            for f in s.get("features") or []:
                if (f.get("level") or 0) > 6:
                    continue
                if cortado(f.get("desc")):
                    faltas.append(("rasgo de subclase sin texto", s["name"] + " / " + f["name"], "nv%s" % f.get("level")))
                if not f.get("icon"):
                    faltas.append(("rasgo de subclase sin icono", s["name"] + " / " + f["name"], ""))
    if any(c.get("subclasses") for c in d["classes"]):
        niveles = {}
        for c in d["classes"]:
            p = [min((x.get("level") or 99) for x in (s.get("features") or [{}]))
                 for s in c.get("subclasses") or [] if s.get("features")]
            if p:
                niveles[c["name"]] = collections.Counter(p).most_common(1)[0][0]
        print("  nivel al que cada clase elige subclase: %s"
              % ", ".join("%s %d" % (k, v) for k, v in sorted(niveles.items(), key=lambda x: x[1])))
    resumen(faltas)

    # ---------- CONJUROS HASTA NIVEL 4 ----------
    bloque("CONJUROS HASTA NIVEL 4, TRUCOS INCLUIDOS")
    faltas = []
    conj = [s for s in d["spells"] if (s.get("level") or 0) <= 4]
    for s in conj:
        for campo, etiqueta in (("school", "escuela"), ("castingTime", "tiempo de lanzamiento"),
                                ("range", "alcance"), ("components", "componentes"),
                                ("duration", "duracion"), ("icon", "icono")):
            if vacio(s.get(campo)):
                faltas.append(("conjuro sin " + etiqueta, s["name"], "nv%s" % s.get("level")))
        if flojo(s.get("description"), 60):
            faltas.append(("conjuro sin descripcion", s["name"], "nv%s" % s.get("level")))
        if not (s.get("classes") or []):
            faltas.append(("conjuro sin clases que lo lancen", s["name"], "nv%s" % s.get("level")))
    print("  conjuros en el alcance: %d" % len(conj))
    resumen(faltas)


if __name__ == "__main__":
    main()
