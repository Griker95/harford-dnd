# -*- coding: utf-8 -*-
"""Barrido de calidad sobre TODOS los textos publicados en la web.

Busca texto raro y perdida de informacion:
  - mojibake y caracteres de control
  - restos de OCR (dados ld8, ordinales "20 nivel", virgulillas, cabeceras)
  - restos de markdown crudo o marcas de estilo sin cerrar
  - unidades imperiales sin convertir
  - frases cortadas: empieza en minuscula, acaba sin cierre, palabras partidas
  - referencias vacias ("ver "), parentesis o comillas sin cerrar
"""
import io, os, re, sys, json, collections

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js"

def cargar(fichero, clave=None):
    t = io.open(os.path.join(WEB, fichero), encoding="utf-8").read()
    a = t.find("{" if clave else "[")
    b = t.rfind("}" if clave else "]")
    d = json.loads(t[a:b+1])
    return d[clave] if clave else d

CHECKS = [
    # restos del propio Discord, que es de donde salen las tablas de personalidad:
    # la marca de mensaje editado, la hora del mensaje o una mencion
    ("resto de Discord", re.compile(r"\((?:edited|editado)\)|\d{1,2}:\d{2}\s*(?:AM|PM)|(?<![A-Za-z0-9])@\w+", re.I)),
    ("mojibake",        re.compile(r"Ã[\u0080-\u00bf]|â€|\ufffd")),
    ("control",         re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")),
    ("dado OCR",        re.compile(r"\bld\d|\d\s?dl\d")),
    # "de 20 nivel" es OCR de "de 2o nivel"; "nivel 10" y "nivel 20" son legitimos
    ("ordinal OCR",     re.compile(r"\bde\s+\d0\s+nivel\b")),
    ("virgulilla",      re.compile(r"~")),
    ("cabecera",        re.compile(r"CAP[IÍ]TUL|APITULO|MISCEL[AÁ]NEA")),
    # `[texto](pagina.html#ancla)` es intencionado: lo escribe referencias.py y la web lo
    # convierte en enlace. Solo se avisa de separadores de tabla y anclas sueltas.
    # El separador DENTRO de un recuadro (">") tampoco es un resto: la web desanida la caja
    # y monta una <table> de verdad (comprobado en pantalla con el stat block del CdM).
    ("markdown crudo",  re.compile(r"(?m)^(?!\s*>)[^\n]*\|\s*[-:]{3,}|\{#")),
    ("estilo sin cerrar", None),
    ("imperial",        re.compile(r"\d+\s?(?:pies|pie\b|libras?|pulgadas?|millas?)")),
    ("palabra partida", re.compile(r"[a-záéíóúñ]-\s+[a-záéíóúñ]")),
    ("doble espacio",   re.compile(r"[a-zA-Z]  +[a-zA-Z]")),
    ("parentesis",      None),
    ("empieza minus",   re.compile(r"^\s*[a-záéíóúñ,;)]")),
    ("acaba cortado",   None),
]

def revisar(nombre, texto):
    fallos = []
    for etiqueta, pat in CHECKS:
        if etiqueta == "estilo sin cerrar":
            # se quitan primero los pares completos; si queda algun asterisco suelto es
            # que la cursiva o la negrita se abrio y no se cerro
            # la cursiva puede abarcar varias lineas (citas de apertura), igual que en la web
            resto = re.sub(r"\*{1,3}[^*]{1,900}\*{1,3}", "", texto)
            if "*" in resto: fallos.append(("estilo sin cerrar", ""))
            continue
        if etiqueta == "parentesis":
            if texto.count("(") != texto.count(")"): fallos.append(("parentesis", ""))
            continue
        if etiqueta == "acaba cortado":
            t = texto.rstrip()
            # una formula ("= 8 + Bonus...") o una lista de conjuros en cursiva acaban sin punto
            if (len(t) > 220 and not re.search(r"[.!?:)\"»*\]]$", t)
                    and not re.search(r"(?:Mod\.|competencia|nivel)\s*[A-Za-zÁÉÍÓÚÑáéíóúñ.]*$", t)):
                fallos.append(("acaba cortado", t[-45:]))
            continue
        if etiqueta == "empieza minus" and (len(texto) < 120 or "/Equipo" in nombre
                                            or "/Competencia" in nombre or "/Idioma" in nombre): continue
        m = pat.search(texto)
        if m:
            i = max(0, m.start() - 30)
            fallos.append((etiqueta, texto[i:m.end() + 25].replace("\n", " ")))
    return fallos

entradas = []
kb = cargar("compendium-data.js", clave=None) if False else None
t = io.open(os.path.join(WEB, "compendium-data.js"), encoding="utf-8").read()
KB = json.loads(t[t.find("{"): t.rfind("}") + 1])
for c in KB["classes"]:
    entradas.append(("clase", c["name"], c.get("desc")))
    entradas.append(("clase-extras", c["name"], c.get("extras")))
    for f in c["features"]: entradas.append(("rasgo", c["name"] + "/" + f["name"], f.get("desc")))
    for s in c["subclasses"]:
        entradas.append(("subclase", s["name"], s.get("desc")))
        for f in s["features"]: entradas.append(("rasgo", s["name"] + "/" + f["name"], f.get("desc")))
for r in KB["races"]:
    entradas.append(("raza", r["name"], r.get("desc")))
    entradas.append(("raza-extras", r["name"], r.get("extras")))
    for x in r["traits"]: entradas.append(("racial", r["name"] + "/" + x["name"], x.get("desc")))
    for s in r.get("subraces", []):
        for x in s["traits"]: entradas.append(("racial", s["name"] + "/" + x["name"], x.get("desc")))
for b in KB["backgrounds"]:
    entradas.append(("trasfondo", b["name"], b.get("desc")))
    for x in b.get("traits", []): entradas.append(("bg", b["name"] + "/" + x["name"], x.get("desc")))
for s in KB["spells"]:
    entradas.append(("conjuro", s["name"], s.get("description")))
for d in cargar("compendium-dotes.js"):
    entradas.append(("dote", d["name"], d.get("desc")))
for e in cargar("compendium-equipment.js"):
    entradas.append(("equipo", e["name"], e.get("note")))
for p in cargar("compendium-professions.js"):
    for r2 in p.get("recipes", []):
        entradas.append(("receta", p["name"] + "/" + r2["name"], ""))

cuenta = collections.Counter()
casos = collections.defaultdict(list)
n = 0
for grupo, nombre, txt in entradas:
    if not txt: continue
    n += 1
    for etiqueta, ctx in revisar(nombre, txt):
        cuenta[etiqueta] += 1
        casos[etiqueta].append((grupo, nombre, ctx))
print("textos revisados: %d" % n)
print("hallazgos:", dict(cuenta) or "ninguno")
for etiqueta in sorted(casos, key=lambda k: -cuenta[k]):
    print("\n%s (%d)" % (etiqueta.upper(), cuenta[etiqueta]))
    for g, nm, ctx in casos[etiqueta][:8]:
        print("   %-9s %-34s %s" % (g, nm[:33], str(ctx)[:70]))
