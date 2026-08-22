# -*- coding: utf-8 -*-
"""Busca en todos los textos publicados las variantes de traduccion de las 18 habilidades
y de las 6 caracteristicas. Cada libro las llama distinto ("Manejo de Animales" /
"Trato con Animales", "Arcano" / "Conocimiento Arcano"), y el compendio debe usar SIEMPRE
el nombre canonico del addon (HarfordDnDData.SKILLS).
"""
import io, os, re, sys, json, collections

sys.stdout.reconfigure(encoding="utf-8")
W = r"C:/Users/marco/Documents/harfordweb/js"

# canonico del addon -> variantes que aparecen en los manuales
VARIANTES = {
    "Trato con Animales": ["Manejo de Animales", "Manejo de animales", "Trato con animales",
                           "Domar Animales", "Adiestrar Animales"],
    "Conocimiento Arcano": ["Arcano", "Arcanos", "Conocimiento arcano", "Saber Arcano"],
    "Juego de Manos": ["Juego de manos", "Prestidigitación", "Prestidigitacion", "Manos Ágiles"],
    "Perspicacia": ["Introspección", "Introspeccion", "Averiguar Intenciones", "Intuición", "Intuicion"],
    "Engaño": ["Decepción", "Decepcion", "Engatusar"],
    "Interpretación": ["Actuación", "Actuacion", "Actuar"],
    "Atletismo": ["Atletismo"],
    "Percepción": ["Percepción"],
    "Sigilo": ["Ocultarse", "Esconderse"],
    "Investigación": ["Buscar"],
    "Supervivencia": ["Supervivencia"],
}

def cargar(f, obj=False):
    t = io.open(os.path.join(W, f), encoding="utf-8").read()
    a, b = (t.find("{"), t.rfind("}")) if obj else (t.find("["), t.rfind("]"))
    return json.loads(t[a:b+1])

KB = cargar("compendium-data.js", True)
textos = []
def add(g, n, t):
    if t: textos.append((g, n, t))
for c in KB["classes"]:
    add("clase", c["name"], c.get("desc")); add("clase", c["name"] + " (extras)", c.get("extras"))
    for f in c["features"]: add("rasgo", c["name"] + "/" + f["name"], f.get("desc"))
    for s in c["subclasses"]:
        for f in s["features"]: add("rasgo", s["name"] + "/" + f["name"], f.get("desc"))
        for o in [op for f in s["features"] for op in (f.get("options") or [])]: add("opcion", o.get("label", ""), o.get("desc"))
for r in KB["races"]:
    add("raza", r["name"], r.get("desc"))
    for x in r["traits"]: add("racial", r["name"] + "/" + x["name"], x.get("desc"))
    for s in r.get("subraces", []):
        for x in s["traits"]: add("racial", s["name"] + "/" + x["name"], x.get("desc"))
for b in KB["backgrounds"]:
    add("trasfondo", b["name"], b.get("desc"))
    for x in b.get("traits", []): add("bg", b["name"] + "/" + x["name"], x.get("desc"))
for s in KB["spells"]: add("conjuro", s["name"], s.get("description"))
for d in cargar("compendium-dotes.js"): add("dote", d["name"], d.get("desc"))
for e in cargar("compendium-equipment.js"): add("equipo", e["name"], e.get("note"))

print("textos revisados: %d" % len(textos))
hallazgos = collections.defaultdict(list)
for canon, vs in VARIANTES.items():
    for v in vs:
        if v == canon: continue
        pat = re.compile(r"\b" + re.escape(v) + r"\b")
        for g, n, t in textos:
            for m in pat.finditer(t):
                ctx = t[max(0, m.start()-32):m.end()+22].replace("\n", " ")
                hallazgos[(canon, v)].append((g, n, ctx))

if not hallazgos:
    print("\nno hay variantes: todas las habilidades usan el nombre canonico")
for (canon, v), casos in sorted(hallazgos.items(), key=lambda x: -len(x[1])):
    print("\n'%s' deberia ser '%s'  (%d casos)" % (v, canon, len(casos)))
    for g, n, ctx in casos[:6]:
        print("   %-9s %-32s %s" % (g, n[:31], ctx[:68]))
