# -*- coding: utf-8 -*-
"""Audita el kb entero buscando texto que NO corresponde a su entrada.

Señales que revisa:
  - el texto de un rasgo/dote/trasfondo empieza hablando de OTRA entrada del kb
  - el texto esta duplicado entre dos entradas distintas
  - el texto arranca a media frase (minuscula o coma) o se corta sin cerrar
  - restos de tabla/markdown crudo
Solo informa.
"""
import io, os, re, sys, json, unicodedata, collections
sys.stdout.reconfigure(encoding="utf-8")
SP = os.path.dirname(os.path.abspath(__file__))
kb = json.load(io.open(os.path.join(SP, "kb_icons.json"), encoding="utf-8"))

def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
def nk(s):
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", sa(s).lower())).strip()
def sq(s):
    return re.sub(r"[^a-z0-9]", "", nk(s))

# --- inventario de entradas con texto: (grupo, ruta, nombre, texto) ---
ent = []
for c in kb["classes"]:
    ent.append(("clase", c["name"], c["name"], c.get("desc")))
    for f in c["features"]: ent.append(("rasgo", c["name"], f["name"], f.get("desc")))
    for s in c["subclasses"]:
        ent.append(("subclase", c["name"], s["name"], s.get("desc")))
        for f in s["features"]: ent.append(("rasgo", c["name"] + "/" + s["name"], f["name"], f.get("desc")))
for r in kb["races"]:
    ent.append(("raza", r["name"], r["name"], r.get("desc")))
    for t in r["traits"]: ent.append(("racial", r["name"], t["name"], t.get("desc")))
    for s in r.get("subraces", []):
        ent.append(("subraza", r["name"], s["name"], s.get("desc")))
        for t in s["traits"]: ent.append(("racial", r["name"] + "/" + s["name"], t["name"], t.get("desc")))
for b in kb["backgrounds"]:
    ent.append(("trasfondo", b["name"], b["name"], b.get("desc")))
    for t in b.get("traits", []): ent.append(("bg-rasgo", b["name"], t["name"], t.get("desc")))
for d in kb.get("dotes", []):
    ent.append(("dote", d["name"], d["name"], d.get("desc")))

nombres = {nk(n) for _, _, n, _ in ent if len(nk(n)) > 6}

prob = collections.defaultdict(list)
por_texto = collections.defaultdict(list)
for grupo, ruta, nombre, txt in ent:
    if not txt: continue
    t = txt.strip()
    if len(t) >= 80:
        por_texto[sq(t)[:160]].append((grupo, ruta, nombre))
    # arranca a media frase
    if re.match(r"^[a-záéíóúñ,;)]", t):
        prob["empieza a media frase"].append((grupo, ruta, nombre, t[:70]))
    # empieza nombrando OTRA entrada ("Golpe runico. Cuando impactas...")
    m = re.match(r"^([A-ZÁÉÍÓÚÑ][^.\n]{4,40})\.\s+[A-ZÁÉÍÓÚÑ]", t)
    if m and nk(m.group(1)) in nombres and nk(m.group(1)) != nk(nombre):
        prob["empieza con otra entrada"].append((grupo, ruta, nombre, m.group(1)))
    # restos de markdown/tabla
    if re.search(r"\|\s*[-:]{3,}|\{#|\]\(", t):
        prob["resto de markdown"].append((grupo, ruta, nombre, t[:70]))
    # se corta sin cerrar
    if len(t) > 200 and not re.search(r"[.:!?)\"»]\s*$", t):
        prob["acaba sin cerrar"].append((grupo, ruta, nombre, t[-60:]))

dups = {k: v for k, v in por_texto.items() if len(v) > 1}
print("entradas con texto: %d" % sum(1 for e in ent if e[3]))
print("TEXTOS DUPLICADOS entre entradas distintas: %d" % len(dups))
for k, v in list(dups.items())[:12]:
    nombres_v = {nk(x[2]) for x in v}
    marca = "  <-- nombres distintos" if len(nombres_v) > 1 else ""
    print("   %s%s" % (" | ".join("%s:%s" % (x[0], x[2][:26]) for x in v), marca))
for k in sorted(prob):
    print("\n%s: %d" % (k.upper(), len(prob[k])))
    for x in prob[k][:10]:
        print("   %-9s %-24s %-28s %s" % (x[0], x[1][:23], x[2][:27], str(x[3])[:60].replace("\n", " ")))
