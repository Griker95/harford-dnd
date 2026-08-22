# -*- coding: utf-8 -*-
"""Inventario de TODO el texto del proyecto, para saber que falta por revisar.

Cuenta por corpus: cuantas entradas, cuantas palabras, cuantas tienen texto de manual
detras (cotejable) y cuantas solo tienen texto propio del addon (no hay contra que
compararlas). Es la base del plan de revision.
"""
import io, os, re, sys, json, glob

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js"
PAL = re.compile(r"[A-Za-zÁÉÍÓÚÑÜáéíóúñü]{3,}")


def carga(fichero, obj=False):
    t = io.open(os.path.join(WEB, fichero), encoding="utf-8").read()
    a, b = (t.find("{"), t.rfind("}")) if obj else (t.find("["), t.rfind("]"))
    return json.loads(t[a:b+1])


KB = carga("compendium-data.js", obj=True)
EQ = carga("compendium-equipment.js")
DO = carga("compendium-dotes.js")
PR = carga("compendium-professions.js")

corpus = []


def anota(nombre, textos):
    textos = [t for t in textos if isinstance(t, str)]
    con = [t for t in textos if t.strip()]
    corpus.append((nombre, len(textos), len(con),
                   sum(len(PAL.findall(t)) for t in con)))


anota("conjuros", [s.get("description") for s in KB["spells"]])
anota("clases (intro)", [c.get("desc") for c in KB["classes"]])
anota("clases (recuadros)", [c.get("extras") for c in KB["classes"]])
anota("rasgos de clase", [f.get("desc") for c in KB["classes"] for f in c["features"]])
anota("rasgos de subclase", [f.get("desc") for c in KB["classes"]
                             for s in c["subclasses"] for f in s["features"]])
anota("razas (intro)", [r.get("desc") for r in KB["races"]])
anota("rasgos raciales", [x.get("desc") for r in KB["races"] for x in r["traits"]]
      + [x.get("desc") for r in KB["races"] for s in r.get("subraces", []) for x in s["traits"]])
anota("trasfondos (intro)", [b.get("desc") for b in KB["backgrounds"]])
anota("rasgos de trasfondo", [x.get("desc") for b in KB["backgrounds"] for x in b["traits"]])
anota("equipo", [e.get("note") for e in EQ])
anota("dotes", [d.get("desc") for d in DO])
anota("rasgos de dote", [x.get("desc") for d in DO for x in d.get("traits", [])])
anota("profesiones", [p.get("desc") for p in PR] + [p.get("note") for p in PR])
anota("recetas", [r.get("desc") for p in PR for r in p.get("recipes", [])])

# paginas y datos escritos a mano
paginas = sorted(glob.glob(r"C:/Users/marco/Documents/harfordweb/*.html"))
html_txt = []
for p in paginas:
    s = io.open(p, encoding="utf-8").read()
    s = re.sub(r"<(script|style)\b.*?</\1>", "\n", s, flags=re.S | re.I)
    html_txt.append(re.sub(r"<[^>]+>", "\n", s))
anota("paginas html", html_txt)
for f in ("characters.js", "organizations.js", "intelligence.js", "places.js",
          "assets.js", "contacts.js"):
    p = os.path.join(WEB, f)
    if not os.path.exists(p): continue
    src = io.open(p, encoding="utf-8").read()
    anota("datos: " + f, [c for c in re.findall(r'"((?:[^"\\]|\\.)*)"', src)
                          if len(c) > 40 and " " in c])

print("%-26s %8s %8s %10s" % ("corpus", "entradas", "con texto", "palabras"))
print("-" * 56)
for nombre, n, con, pal in corpus:
    print("%-26s %8d %8d %10d" % (nombre, n, con, pal))
print("-" * 56)
print("%-26s %8d %8d %10d" % ("TOTAL", sum(c[1] for c in corpus),
                              sum(c[2] for c in corpus), sum(c[3] for c in corpus)))
