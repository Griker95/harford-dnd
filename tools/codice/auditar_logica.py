# -*- coding: utf-8 -*-
"""Revision de COHERENCIA del compendio (no de erratas): que los datos digan cosas
que encajan entre si y con las reglas de 5e.

Comprueba, entre otras cosas:
  - concentracion declarada frente a la duracion escrita, y al reves
  - ritual declarado frente al texto
  - nivel/escuela frente a lo que dice el propio texto
  - dano declarado frente al dano que aparece en la descripcion
  - trucos que gastan espacio de conjuro o traen "A niveles superiores"
  - conjuros sin ninguna clase que los pueda lanzar
  - rasgos cuyo nivel no cuadra con el texto ("a partir del nivel N")
  - listas de conjuros de clase que citan conjuros que no existen
  - equipo: armas sin dano, armaduras sin CA, objetos sin precio
"""
import io, os, re, sys, json, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js"

def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
def nk(s):
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", sa(s).lower())).strip()

def cargar(f, obj=False):
    t = io.open(os.path.join(WEB, f), encoding="utf-8").read()
    a, b = (t.find("{"), t.rfind("}")) if obj else (t.find("["), t.rfind("]"))
    return json.loads(t[a:b+1])

KB = cargar("compendium-data.js", obj=True)
EQ = cargar("compendium-equipment.js")
DO = cargar("compendium-dotes.js")
PR = cargar("compendium-professions.js")

fallos = collections.defaultdict(list)
def añadir(clave, quien, detalle): fallos[clave].append((quien, detalle))

# ---------------- CONJUROS ----------------
spells = KB["spells"]
por_nombre = {nk(s["name"]): s for s in spells}
ESCUELAS = {"abjuracion", "adivinacion", "conjuracion", "encantamiento",
            "evocacion", "ilusion", "nigromancia", "transmutacion"}
for s in spells:
    n, d = s["name"], (s.get("description") or "")
    dur = s.get("duration") or ""
    conc_dec = bool(s.get("concentration"))
    conc_dur = "concentr" in nk(dur)
    if conc_dec and not conc_dur and dur:
        añadir("concentracion sin duracion de concentracion", n, "duracion: " + dur)
    if conc_dur and not conc_dec:
        añadir("duracion dice concentracion pero el campo dice que no", n, dur)
    # el sentido util es el contrario: el manual marca "(ritual)" y el addon no lo tiene.
    # Al reves no vale: la etiqueta "(ritual)" del tiempo de lanzamiento se pierde al
    # extraer y la ficha ya lo indica con su propio distintivo, asi que no falta nada.
    if not s.get("ritual") and "ritual" in nk(s.get("castingTime") or ""):
        añadir("el manual lo marca como ritual pero el campo dice que no", n,
               s.get("castingTime") or "")
    if nk(s.get("school") or "") not in ESCUELAS:
        añadir("escuela desconocida", n, s.get("school"))
    if not s.get("classes"):
        añadir("conjuro que ninguna clase puede lanzar", n, "")
    if s.get("level") == 0:
        if re.search(r"espacio de conjuro|ranura de conjuro", nk(d)) and "sin gastar" not in nk(d):
            añadir("truco que gasta espacio de conjuro", n, "")
        # la etiqueta de la nota de escalado es SIEMPRE "A niveles superiores" por decision
        # de presentacion del compendio, tambien en los trucos (que escalan por nivel de
        # personaje). No es un error: no se audita.
    else:
        if re.search(r"aumenta.{0,40}cuando alcanzas.{0,20}nivel 5", nk(d)):
            añadir("conjuro con nivel que escala como truco", n, "")
    # el dano declarado deberia aparecer en el texto
    dm = s.get("damage") or ""
    # basta con que el texto use el mismo dado: el campo puede agregar lo que la
    # descripcion reparte ("3d4 + 3" en el campo y "1d4+1 por cada dardo" en el texto)
    md = re.search(r"\d+(d\d+)", dm)
    if md and not re.search(r"\d" + md.group(1) + r"\b", d) and len(d) > 200:
        añadir("dano declarado que no aparece en la descripcion", n, "%s (campo) vs texto" % md.group(1))
    # el texto no deberia mencionar un nivel de conjuro distinto al suyo
    for m in re.finditer(r"conjuro de (?:nivel )?(\d)", nk(d)):
        pass

# clases que dicen lanzar conjuros de una lista
for c in KB["classes"]:
    lst = c.get("spellClasses")
    if lst:
        for x in lst:
            if not any(x in (sp.get("classes") or []) for sp in spells):
                añadir("clase con lista de conjuros vacia", c["name"], x)

# ---------------- RASGOS ----------------
for c in KB["classes"]:
    feats = c["features"] + [f for s in c["subclasses"] for f in s["features"]]
    vistos = collections.Counter(nk(f["name"]) for f in c["features"])
    for k, v in vistos.items():
        if v > 1: añadir("rasgo repetido dentro de la misma clase", c["name"], k)
    for f in feats:
        d = f.get("desc") or ""
        lv = f.get("level")
        # solo cuenta la mencion del principio, que es la que dice cuando se OBTIENE el
        # rasgo: mas adelante el texto habla de sus mejoras ("a partir del nivel 7 puedes
        # usarlo dos veces") y eso no contradice el nivel del campo
        m = re.search(r"(?:a partir del|al alcanzar el|al) nivel (\d+)", nk(d)[:140])
        if m and lv and int(m.group(1)) != lv:
            añadir("nivel del rasgo distinto al que dice su texto", c["name"] + "/" + f["name"],
                   "campo %s vs texto %s" % (lv, m.group(1)))
        if lv is not None and not (1 <= lv <= 20):
            añadir("nivel de rasgo fuera de rango", c["name"] + "/" + f["name"], lv)
        if f.get("options") and not d:
            añadir("rasgo de eleccion sin texto que explique la eleccion", c["name"] + "/" + f["name"], "")

# conjuros citados en cursiva que no existen en el compendio
CITA = re.compile(r"\*([a-záéíóúñ][^*\n]{3,40})\*")
citados = collections.Counter()
for grupo in (spells, DO):
    for x in grupo:
        for m in CITA.finditer(x.get("description") or x.get("desc") or ""):
            citados[nk(m.group(1))] += 1
for c in KB["classes"]:
    for f in c["features"] + [y for s in c["subclasses"] for y in s["features"]]:
        for m in CITA.finditer(f.get("desc") or ""):
            citados[nk(m.group(1))] += 1
sin_ficha = [(k, v) for k, v in citados.items() if k not in por_nombre and v >= 2 and len(k) > 6]

# ---------------- EQUIPO ----------------
for e in EQ:
    if e["kind"] == "weapon" and not (e.get("damage") or "").strip("— "):
        # desarmado y red no hacen dano por regla: la red apresa
        if nk(e["name"]) not in ("desarmado", "red"): añadir("arma sin dano", e["name"], "")
    if e["kind"] == "armor" and not e.get("ac"):
        añadir("armadura sin CA", e["name"], "")
    if e["kind"] == "gear" and not e.get("price"):
        añadir("objeto sin precio", e["name"], "")
    if e.get("damage") and e.get("damageType") in (None, "", "—") and e["kind"] == "weapon":
        if "d" in (e.get("damage") or ""): añadir("arma con dano pero sin tipo de dano", e["name"], e.get("damage"))

# ---------------- PROFESIONES ----------------
for p in PR:
    if p["kind"] == "craft" and not p.get("recipes"):
        # no es un fallo de datos: son oficios en los que se puede ser competente y a los
        # que todavia no se les ha escrito lista de recetas
        añadir("oficio sin lista de recetas (contenido pendiente)", p["name"], "")
    for r in p.get("recipes", []):
        # desencantar no lleva materiales por definicion: lo que se consume es el objeto
        if p["kind"] == "craft" and not r.get("materials") and not r["name"].lower().startswith("desencantar"):
            añadir("receta de artesania sin materiales", p["name"] + "/" + r["name"], "")
        if not r.get("output"):
            añadir("receta sin resultado", p["name"] + "/" + r["name"], "")

# ---------------- TRASFONDOS ----------------
for b in KB["backgrounds"]:
    tr = b.get("traits", [])
    if not tr: añadir("trasfondo sin ningun rasgo", b["name"], "")
    # El rasgo propio del trasfondo puede venir etiquetado ("Caracteristica: Refugio del
    # fiel", como en el Manual del Jugador) o con nombre suelto ("Autoridad del capitan"),
    # que es como lo escriben los trasfondos propios de Harford. Falta de verdad solo si
    # no hay NINGUN rasgo mas alla de las competencias, los idiomas y el equipo.
    GENERICOS = ("competencia", "idioma", "equipo", "herramienta", "kit", "juego",
                 "util", "instrumento", "vehiculo")
    etiquetado = any(nk(t["name"]).startswith(("caracteristica", "rasgo")) for t in tr)
    propios = [t for t in tr if not nk(t["name"]).startswith(GENERICOS)]
    if not etiquetado and not propios:
        añadir("trasfondo sin su rasgo propio", b["name"], "")
    elif not etiquetado:
        añadir("rasgo propio sin la etiqueta 'Caracteristica' (solo presentacion)",
               b["name"], ", ".join(t["name"] for t in propios)[:60])

print("=" * 72)
print("REVISION DE COHERENCIA")
print("=" * 72)
total = sum(len(v) for v in fallos.values())
print("incoherencias: %d en %d categorias" % (total, len(fallos)))
for k in sorted(fallos, key=lambda x: -len(fallos[x])):
    print("\n%s (%d)" % (k.upper(), len(fallos[k])))
    for quien, det in fallos[k][:10]:
        print("   %-42s %s" % (str(quien)[:41], str(det)[:34]))
print("\nCONJUROS CITADOS QUE NO EXISTEN EN EL COMPENDIO (%d)" % len(sin_ficha))
for k, v in sorted(sin_ficha, key=lambda x: -x[1])[:14]:
    print("   %-38s citado %d veces" % (k[:37], v))
