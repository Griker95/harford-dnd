# -*- coding: utf-8 -*-
"""Fase 2 de la revision: coherencia INTERNA del compendio.

La fase 1 (`cotejar_fuentes.py`) comparaba cada texto con su manual. Esta no mira fuera:
comprueba que el compendio no se contradiga a si mismo.

Un primer intento tenia reglas mal calibradas y daba 524 avisos falsos, asi que conviene
apuntar que NO se comprueba y por que:

  "el texto no menciona el nombre de la entrada"  ->  un conjuro se llama "Amistad" o
      "Guia" y su texto no tiene por que repetirlo. 232 avisos, ninguno real.
  "declara ataque y el texto no lo menciona"      ->  el campo `attack` no dice si hay
      tirada de ataque: es un resumen de como se resuelve ("Contra salvacion 1d8
      radiante"). La regla partia de una lectura equivocada del campo.
  "el alcance no aparece en el texto"             ->  el campo lleva el ALCANCE del
      conjuro y el cuerpo habla del AREA. Son dos cosas distintas.
"""
import io, os, re, sys, json, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js"


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def nk(s):
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", sa(s))).strip()


def carga(f, obj=False):
    t = io.open(os.path.join(WEB, f), encoding="utf-8").read()
    a, b = (t.find("{"), t.rfind("}")) if obj else (t.find("["), t.rfind("]"))
    return json.loads(t[a:b+1])


KB = carga("compendium-data.js", obj=True)
EQ = carga("compendium-equipment.js")
DO = carga("compendium-dotes.js")
avisos = collections.defaultdict(list)

# ---------------- duplicados ----------------
todos = []
for s in KB["spells"]: todos.append(("conjuro", s["name"], s.get("description") or ""))
for c in KB["classes"]:
    for f in c["features"]: todos.append(("rasgo " + c["name"], f["name"], f.get("desc") or ""))
    for sub in c["subclasses"]:
        for f in sub["features"]:
            todos.append(("rasgo " + c["name"] + "/" + sub["name"], f["name"], f.get("desc") or ""))
for r in KB["races"]:
    for x in r["traits"] + [y for s in r.get("subraces", []) for y in s["traits"]]:
        todos.append(("racial " + r["name"], x["name"], x.get("desc") or ""))
for b in KB["backgrounds"]:
    for x in b["traits"]: todos.append(("trasfondo " + b["name"], x["name"], x.get("desc") or ""))
for d in DO: todos.append(("dote", d["name"], d.get("desc") or ""))

por_texto = collections.defaultdict(list)
for tipo, nombre, txt in todos:
    if len(txt) < 200: continue
    por_texto[nk(txt)[:220]].append((tipo, nombre))
for v in por_texto.values():
    if len(v) < 2: continue
    # el mismo rasgo repetido en varias clases o subclases comparte texto a proposito
    if len({nk(n) for _t, n in v}) == 1: continue
    avisos["texto identico en entradas de distinto nombre"].append(
        (v[0][0], v[0][1], " = ".join("%s/%s" % (t, n) for t, n in v[1:])[:64]))

# ---------------- salvacion declarada frente al texto ----------------
# se usa el mismo criterio que el pipeline, para que auditoria y datos no discrepen
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from facetas import pide_salvacion
for s in KB["spells"]:
    d = s.get("description") or ""
    if len(d) < 120: continue
    salv = (s.get("savingThrow") or "").strip("— ")
    atq = (s.get("attack") or "").strip("— ")
    if salv and not pide_salvacion(d):
        avisos["declara salvacion y el texto no la pide"].append(("conjuro", s["name"], salv))
    if not salv and not atq and pide_salvacion(d):
        avisos["el texto pide salvacion y la ficha no la declara"].append(("conjuro", s["name"], ""))

# ---------------- unidades: ficha redondeada frente a cuerpo exacto ----------------
# el cuerpo aplica la conversion real a un decimal (60 pies = 18,3 m) y el campo del
# addon usa metros redondos (18 m). No es un error, pero el lector ve dos cifras para la
# misma distancia, asi que conviene tenerlo contado.
EQUIV = {"1,5": "1,5", "3": "3", "4,5": "4,6", "6": "6,1", "9": "9,1", "12": "12,2",
         "18": "18,3", "27": "27,4", "30": "30,5", "36": "36,6", "45": "45,7",
         "90": "91,4", "150": "152,4", "300": "304,8"}
descuadre = collections.Counter()
for s in KB["spells"]:
    for m in re.finditer(r"(\d+(?:,\d+)?)\s*metros", s.get("range") or ""):
        v = m.group(1)
        # el valor tiene que aparecer como numero suelto: buscarlo como subcadena hacia
        # que "16,1 km por hora" contara como un "6,1 metros" que no existe
        _suelto = re.compile(r"(?<![0-9,.])" + re.escape(EQUIV.get(v, v)) + r"\s*(?:metros|m)\b")
        if v in EQUIV and EQUIV[v] != v and _suelto.search(s.get("description") or ""):
            descuadre[(v, EQUIV[v])] += 1

# ---------------- equipo ----------------
# "la nota no menciona el objeto" no servia: la descripcion de una armadura empieza por
# "Esta armadura..." sin repetir "Coraza". Lo que si dice algo es la nota REPETIDA: dos
# objetos distintos con el mismo texto suelen ser el mismo objeto con dos nombres.
_notas = collections.defaultdict(list)
for e in EQ:
    nota = (e.get("note") or "").strip()
    if len(nota) > 80: _notas[nk(nota)[:200]].append(e["name"])
for _k, _v in _notas.items():
    if len(_v) > 1:
        avisos["objetos distintos con la misma nota"].append(("equipo", _v[0], ", ".join(_v[1:])[:56]))

print("=" * 74)
print("COHERENCIA INTERNA")
print("=" * 74)
print("entradas revisadas: %d" % len(todos))
print("avisos: %d\n" % sum(len(v) for v in avisos.values()))
for k in sorted(avisos, key=lambda x: -len(avisos[x])):
    print("%s (%d)" % (k.upper(), len(avisos[k])))
    for tipo, nombre, det in avisos[k][:14]:
        print("   %-24s %-30s %s" % (tipo[:23], nombre[:29], str(det)[:56]))
    print()
if descuadre:
    print("FICHA REDONDEADA FRENTE A CUERPO EXACTO (%d conjuros)" % sum(descuadre.values()))
    for (a, b), n in descuadre.most_common():
        print("   ficha %-6s vs cuerpo %-6s  %d conjuros" % (a + " m", b + " m", n))
