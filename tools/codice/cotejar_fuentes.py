# -*- coding: utf-8 -*-
"""Coteja cada texto del compendio contra el del manual del que salio.

Las revisiones anteriores buscaban defectos DENTRO del texto (OCR, unidades, cortes).
Esta busca otra cosa: que el texto sea el que le toca. Tres sintomas, y cada uno delata
un fallo distinto de la extraccion:

  parecido bajo    a la entrada le pusieron el texto de OTRA (paso con las razas y las
                   clases del final del libro, que se llevaban los recuadros del vecino)
  mucho mas corto  se perdieron parrafos por el camino
  mucho mas largo  se le pego texto de la entrada siguiente

No se corrige nada aqui: es una lista para revisar, porque la decision de cada caso
depende de la jerarquia de fuentes (Warcraft 5a manda; los otros manuales completan).
"""
# EXCEPCION CONOCIDA: "Espiritu curativo" y "Respirar bajo el agua" salen aqui como si
# les faltara texto frente al manual. Es al reves: el manual arrastra pegado al final de
# esas dos entradas OTRO conjuro entero (Estatica sinaptica y Restablecimiento mayor), y
# en el compendio ya se separaron. Los dos conjuros rescatados siguen sin ficha propia
# porque su lista de clases no se puede leer con fiabilidad del OCR de Xanathar.

import io, os, re, sys, json, glob, difflib, unicodedata, collections

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
WEB = r"C:/Users/marco/Documents/harfordweb/js"
EXPORT = r"C:/Users/marco/Documents/New project/RuleSource/Export"

PAL = re.compile(r"[a-z0-9]+")


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def clave(s):
    # el OCR lee la O inicial de las versales como U con dieresis ("ULA ATRONADORA")
    s = " ".join({"ü": "o", "ö": "o"}.get(p[:1], p[:1]) + p[1:] for p in sa(s).split() if p)
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def palabras(t):
    return PAL.findall(sa(t))


def parecido(a, b):
    """Cuanto del texto del manual aparece en el del compendio, palabra a palabra."""
    pa, pb = palabras(a), palabras(b)
    if not pa or not pb: return 0.0
    return difflib.SequenceMatcher(None, pa, pb, autojunk=False).ratio()


def carga(fichero, obj=False):
    t = io.open(os.path.join(WEB, fichero), encoding="utf-8").read()
    a, b = (t.find("{"), t.rfind("}")) if obj else (t.find("["), t.rfind("]"))
    return json.loads(t[a:b+1])


# ---------- fuentes ----------
def fuente_conjuros():
    """{clave: texto} de los conjuros de los cuatro manuales exportados."""
    out = {}
    for f in glob.glob(os.path.join(EXPORT, "conjuros_*.json")):
        d = json.load(io.open(f, encoding="utf-8"))
        for e in (d if isinstance(d, list) else list(d.values())):
            nm = e.get("nombre") or e.get("name") or ""
            tx = e.get("descripcion") or e.get("texto") or e.get("description") or ""
            if nm and len(tx) > 60: out.setdefault(clave(nm), tx)
    return out


def fuente_paginas_phb():
    """Entradas de conjuro sacadas de las paginas en crudo del Manual del Jugador."""
    ruta = r"C:/Users/marco/Documents/New project/RuleSource/rescatar_conjuros_perdidos.py"
    if not os.path.exists(ruta): return {}
    src = io.open(ruta, encoding="utf-8").read()
    g = {"__file__": ruta, "__name__": "x"}
    exec(compile(src[:src.find("libro = entradas()")], "r", "exec"), g)
    return {k: g["limpia_cuerpo"](v) for k, v in g["entradas"]().items()}


def fuente_libro1():
    """Secciones del libro de Warcraft, por titulo."""
    src = io.open(r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/"
                  r"warcraft_5e_libro1.md", encoding="utf-8").read().replace("\r", "")
    heads = [(len(m.group(1)), m.group(2).strip().strip("*").strip(), m.start(), m.end())
             for m in re.finditer(r"\n(#{1,6})\s*([^\n]+)", src)]
    out = {}
    for i, (lvl, txt, a, b) in enumerate(heads):
        fin = next((x[2] for x in heads[i+1:] if x[0] <= lvl), len(src))
        cuerpo = src[b:fin].strip()
        if len(cuerpo) > 80: out.setdefault(clave(txt), cuerpo)
    # entradas en negrita ("***Nombre.*** texto"), que es como van los rasgos raciales
    for m in re.finditer(r"\*\*\*\s*([^*\n]+?)\.?\s*\*\*\*\s*(.*?)(?=\n\s*\*\*\*|\n#{1,6}\s|\Z)",
                         src, re.S):
        k, c = clave(m.group(1)), m.group(2).strip()
        if k and len(c) > 80: out.setdefault(k, c)
    return out


def fuentes_por_capitulo():
    """Igual que la de arriba, pero separando por capitulo de clase y de raza.

    Hace falta porque hay titulos que se repiten en todos los capitulos ("Lanzamiento de
    conjuros", "Estilo de combate"): comparar contra el primero que aparece da avisos que
    no existen. Se reutiliza el mismo recorte de capitulos que usa el pipeline.
    """
    ruta = os.path.join(BASE, "add_full_desc.py")
    src = io.open(ruta, encoding="utf-8").read()
    corte = src.find("# (las clases se procesan mas abajo")
    resto = src[src.find("RACENAMES = set("):src.find("def parecido_en")]
    g = {"__file__": ruta, "__name__": "x"}
    exec(compile(src[:corte] + "\n" + resto, "afd", "exec"), g)
    out = {}
    for clave_md, nombre in list(g["CLASS_MD"].items()):
        rango = g["chapter"](nombre)
        if not rango: continue
        idx = dict(g["bold_entries"](rango))
        a, b = rango
        for lvl, txt, k, ha, he in g["heads"]:
            if a <= ha < b and lvl in (3, 4, 5):
                bs = g["src"].find("\n", he)
                be = min(g["next_heading"](bs, lvl), b)
                cuerpo = g["clean_body"](g["src"][bs:be])
                if len(cuerpo) > 80: idx.setdefault(k, cuerpo)
        out[clave(nombre)] = idx
    for clave_md, nombre in list(g["RACE_MD"].items()):
        rango = g["chapter_generic"](nombre, g["RACENAMES"])
        if not rango: continue
        out[clave(nombre)] = dict(g["bold_entries"](rango))
    return out


KB = carga("compendium-data.js", obj=True)
DO = carga("compendium-dotes.js")
POR_CAPITULO = fuentes_por_capitulo()
print("capitulos con indice propio: %d" % len(POR_CAPITULO))

# Los indices van SEPARADOS por tipo. Mezclarlos comparaba el conjuro "Escudo" contra el
# rasgo de sacerdote del mismo nombre, y el conjuro "Vision en la oscuridad" contra el
# rasgo racial: dos avisos que no existian.
FUENTES_CONJUROS = fuente_conjuros()
for k, v in fuente_paginas_phb().items(): FUENTES_CONJUROS.setdefault(k, v)
def fuente_dotes():
    """Indice propio de dotes: se reutiliza el que arma `extract_dotes.py`.

    Sin el, la dote "Acechador" se comparaba contra el rasgo de Cazador del mismo nombre.
    """
    ruta = os.path.join(BASE, "extract_dotes.py")
    src = io.open(ruta, encoding="utf-8").read()
    corte = src.find("# dotes del Caldero de Tasha")
    g = {"__file__": ruta, "__name__": "x"}
    exec(compile(src[:corte], "ed", "exec"), g)
    return {clave(k): v for k, v in g["libro_txt"].items()}


FUENTES = fuente_libro1()
FUENTES_DOTES = fuente_dotes()
print("referencias: %d conjuros | %d secciones de libro" % (len(FUENTES_CONJUROS), len(FUENTES)))

# ---------- entradas del compendio ----------
# cada entrada lleva el capitulo al que pertenece, para buscar la referencia ahi primero
entradas = []
for s in KB["spells"]:
    entradas.append(("conjuro", s["name"], s.get("description") or "", None))
def texto_con_opciones(f):
    """Texto del rasgo mas el de sus opciones.

    Un rasgo de eleccion ("Estilo de combate", "Metamagia") es solo el enunciado; lo que
    en el libro va seguido son las opciones, que aqui viven aparte con su propio texto.
    Comparar solo el enunciado hacia parecer que faltaban 200 palabras.
    """
    partes = [f.get("desc") or ""]
    for o in f.get("options") or []:
        partes.append(o.get("label") or o.get("name") or "")
        partes.append(o.get("desc") or o.get("description") or "")
    return "\n".join(x for x in partes if x)


for c in KB["classes"]:
    cap = clave(c["name"])
    for f in c["features"]:
        entradas.append(("rasgo " + c["name"], f["name"], texto_con_opciones(f), cap))
    for sub in c["subclasses"]:
        for f in sub["features"]:
            entradas.append(("rasgo " + c["name"] + "/" + sub["name"], f["name"],
                             texto_con_opciones(f), cap))
for r in KB["races"]:
    cap = clave(r["name"])
    for x in r["traits"]:
        entradas.append(("racial " + r["name"], x["name"], x.get("desc") or "", cap))
    for sub in r.get("subraces", []):
        for x in sub["traits"]:
            entradas.append(("racial " + r["name"], x["name"], x.get("desc") or "", cap))
for b in KB["backgrounds"]:
    entradas.append(("trasfondo", b["name"], b.get("desc") or "", None))
for d in DO:
    entradas.append(("dote", d["name"], d.get("desc") or "", None))

# nombres de rasgo que ya tienen entrada propia, por capitulo
HERMANOS = collections.defaultdict(set)
for c in KB["classes"]:
    k = clave(c["name"])
    for f in c["features"]: HERMANOS[k].add(clave(f["name"]))
    for sub in c["subclasses"]:
        for f in sub["features"]: HERMANOS[k].add(clave(f["name"]))
for r in KB["races"]:
    k = clave(r["name"])
    for x in r["traits"]: HERMANOS[k].add(clave(x["name"]))
    for sub in r.get("subraces", []):
        for x in sub["traits"]: HERMANOS[k].add(clave(x["name"]))

UMBRAL_PARECIDO = 0.40
avisos = collections.defaultdict(list)
cotejados = 0
for tipo, nombre, texto, cap in entradas:
    if len(texto) < 120: continue
    # primero la referencia del propio capitulo; el indice general solo como respaldo, y
    # nunca para los rasgos, donde un titulo repetido apuntaria a la clase equivocada
    ref = None
    if tipo == "conjuro":
        ref = FUENTES_CONJUROS.get(clave(nombre))
    elif tipo == "dote":
        ref = FUENTES_DOTES.get(clave(nombre))
    elif cap:
        ref = POR_CAPITULO.get(cap, {}).get(clave(nombre))
    else:
        ref = FUENTES.get(clave(nombre))
    if not ref: continue
    if cap and cap in HERMANOS:
        # El libro deja los sub-rasgos dentro de la seccion del padre ("Poder Runico"
        # incluye "Golpe Runico" y "Espiral de la Muerte"), mientras que el compendio les
        # da entrada propia. Se descuentan de la referencia los que ya existen aparte, o
        # pareceria que al padre le faltan 200 palabras.
        trozos, sobra = re.split(r"(?m)^\s*#{2,6}\s*", ref), []
        for i, tr in enumerate(trozos):
            titulo = clave(tr.split("\n", 1)[0]) if i else None
            if titulo and titulo in HERMANOS[cap] and titulo != clave(nombre): continue
            sobra.append(tr)
        ref = "\n".join(sobra)
        # los recuadros del libro no cuelgan del rasgo: el compendio los muestra a nivel
        # de clase, en sus `extras`, asi que aqui no cuentan como texto que falte
        ref = re.sub(r"(?m)^\s*>.*$", "", ref)
        if len(palabras(ref)) < 25: continue
    if tipo == "trasfondo":
        # la ficha del compendio separa intro, competencias y equipo en rasgos aparte;
        # la seccion del libro los lleva todos juntos. Se compara solo contra la intro.
        corte = re.search(r"(?im)^\s*(?:#{1,6}\s*)?(?:\*\*\*?)?\s*"
                          r"(competencias?|habilidades|equipo|idiomas?)\b", ref)
        if corte: ref = ref[:corte.start()].strip()
        if len(palabras(ref)) < 40: continue
    cotejados += 1
    r = parecido(ref, texto)
    lr = len(palabras(texto)) / max(1, len(palabras(ref)))
    if r < UMBRAL_PARECIDO:
        avisos["texto que no se parece al del manual"].append(
            (tipo, nombre, "parecido %.0f%% | %d vs %d palabras" %
             (r * 100, len(palabras(texto)), len(palabras(ref)))))
    elif lr < 0.55:
        avisos["falta texto frente al manual"].append(
            (tipo, nombre, "%d de %d palabras (%.0f%%)" %
             (len(palabras(texto)), len(palabras(ref)), lr * 100)))
    elif lr > 1.9:
        avisos["sobra texto frente al manual"].append(
            (tipo, nombre, "%d frente a %d palabras (x%.1f)" %
             (len(palabras(texto)), len(palabras(ref)), lr)))

print("entradas cotejadas contra su fuente: %d de %d" % (cotejados, len(entradas)))
print("avisos: %d\n" % sum(len(v) for v in avisos.values()))
for k in sorted(avisos, key=lambda x: -len(avisos[x])):
    print("%s (%d)" % (k.upper(), len(avisos[k])))
    for tipo, nombre, det in avisos[k][:20]:
        print("   %-26s %-30s %s" % (tipo[:25], nombre[:29], det))
    print()
