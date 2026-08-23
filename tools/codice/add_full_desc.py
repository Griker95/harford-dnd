# -*- coding: utf-8 -*-
# Enriquece el kb del codice con TODO el texto del libro: intro de clase y de raza, rasgos de
# clase/subclase (chapter-aware), y trasfondos completos del Discord export (matcheo fuzzy).
import collections
import re, io, os, json, unicodedata, difflib, sys
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
from metrico import a_metrico  # los manuales de D&D vienen en pies y libras

SP = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SP)
from terminologia import normalizar_habilidades
from referencias import referencias
from limpieza import limpiar
MD = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/warcraft_5e_libro1.md"

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
def nk(s): return re.sub(r"[^0-9a-z]+", " ", sa(s or "").lower()).strip()
def nkbase(s): return nk(re.sub(r"\s*\([^)]*\)\s*$", "", s or ""))

kb = json.load(io.open(os.path.join(SP, "kb_icons.json"), encoding="utf-8"))

# Este script LEE y ESCRIBE el mismo fichero, asi que ejecutarlo dos veces seguidas duplica
# los conjuros importados y deja el compendio inservible. La marca lo impide: hay que
# rehacer el kb desde extract_kb.py, que es lo que borra el sello.
if kb.get("_completado"):
    raise SystemExit("add_full_desc ya se aplico a este kb. Vuelve a generarlo primero: "
                     "python extract_kb.py && python add_icons_kb.py")
kb["_completado"] = True
src = re.sub(r"\r", "", io.open(MD, encoding="utf-8").read())
heads = []
for m in re.finditer(r"\n(#{1,6})\s*([^\n]+)", src):
    txt = m.group(2).strip().strip("*").strip()
    heads.append((len(m.group(1)), txt, nk(txt), m.start(), m.end()))

def _sin_cola_de_titulo(t):
    """Quita del final lo que en realidad encabeza el bloque siguiente: un titulo sin
    cuerpo debajo, o un divisor de seccion del libro ("Razas de la Horda")."""
    for _ in range(3):
        t2 = re.sub(r"\n### [^\n]{0,60}$", "", t).strip()
        lineas = t2.split("\n")
        if lineas:
            ult = lineas[-1].strip()
            if (ult and len(ult) <= 34 and " " in ult
                    and re.match(r"^[A-Z\u00c1\u00c9\u00cd\u00d3\u00da\u00d1]", ult)
                    and not re.search(r"[.:;!?)\]]$", ult)):
                lineas.pop()
                while lineas and not lineas[-1].strip(): lineas.pop()
                t2 = "\n".join(lineas).strip()
        if t2 == t: break
        t = t2
    return t

def _cuerpo_rasgo(t):
    """Cuerpo de un rasgo, sin la tabla que a veces se le cuela detras.

    Una tabla suelta dentro del texto de un rasgo es la tabla de la clase, que viene a
    continuacion y se cuela cuando su encabezado no queda bien marcado en el OCR. Las
    tablas legitimas de un rasgo van dentro de un recuadro citado.
    """
    m = re.search(r"(?m)^[ \t]*\|", t or "")
    return t[:m.start()] if m else t


# Lo que NUNCA se pega a la linea anterior: titulos, vinetas, listas numeradas, filas de
# tabla, citas y las etiquetas en negrita del bloque de datos (`***Altura:***`).
_LINEA_PROPIA = re.compile(r"^\s*(?:#{1,6}\s|[-*+]\s|\d+[.)]\s|\||>|\*\*\*)")


def unir_lineas(t):
    """Deshace los saltos de MAQUETA del manual.

    El libro corta las lineas a mano para esquivar las ilustraciones, y esos cortes caian
    en la web como versos sueltos en medio de un parrafo. El salto de parrafo de verdad es
    la linea en blanco; un salto suelto dentro de un bloque es maqueta y se convierte en
    espacio, salvo en lo que tiene que ir en su propia linea."""
    bloques = []
    for bloque in t.split("\n\n"):
        lineas = bloque.split("\n")
        acc = [lineas[0]]
        for ln in lineas[1:]:
            if _LINEA_PROPIA.match(ln) or _LINEA_PROPIA.match(acc[-1]) or not acc[-1].strip():
                acc.append(ln)
            else:
                acc[-1] = acc[-1].rstrip() + " " + ln.strip()
        bloques.append("\n".join(acc))
    return "\n\n".join(bloques)


def clean_body(t):
    # un marcador de titulo sin texto detras no titula nada: el renderizador solo trata
    # como encabezado la linea que lleva texto, asi que el marcador se quedaba a la vista
    # ("###" suelto dentro del stat block del elemental de agua)
    t = re.sub(r"(?m)^\s*(>\s*)?#{1,6}\s*$", lambda m: (m.group(1) or "").rstrip(), t)
    # los titulos internos se conservan con un marcador uniforme "### " para que la
    # web los renderice como encabezados con su propia tipografia
    t = re.sub(r"\n#{1,6}\s*", "\n### ", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    return referencias(limpiar(normalizar_habilidades(unir_lineas(_sin_cola_de_titulo(t.strip())))), web=True)

def section(name, level=2, stop_at_names=None):
    """Texto desde el heading `name` (nivel dado) hasta el siguiente heading <= level;
    si stop_at_names, para al primero de esos (p.ej. 'rasgos de clase')."""
    wn = nk(name)
    for i, (lvl, txt, k, a, b) in enumerate(heads):
        if lvl == level and k == wn:
            start = b
            end = len(src)
            for l2, t2, k2, a2, b2 in heads[i+1:]:
                if l2 <= level: end = a2; break
                if stop_at_names and k2 in stop_at_names: end = a2; break
            return clean_body(src[start:end])
    return None

CLASS_MD = {"guerrero":"Guerrero","paladin":"Paladín","cazador_demonios":"Cazador de Demonios",
  "cazador":"Cazador","picaro":"Pícaro","sacerdote":"Sacerdote","caballero_muerte":"Caballero de la Muerte",
  "chaman":"Chamán","mago":"Mago","brujo":"Brujo","monje":"Monje","druida":"Druida"}
CLASSNAMES = set(nk(v) for v in CLASS_MD.values())
RACE_MD = {"humano":"Humano","enano":"Enano","elfo_noche":"Elfo de la Noche","elfo_sangre":"Elfo de Sangre",
  "semielfo":"Semielfo","gnomo":"Gnomo","draenei":"Draenei","huargen":"Huargen","orco":"Orco",
  "renegado":"Renegados","tauren":"Tauren","trol":"Troll","goblin":"Goblin","pandaren":"Pandaren",
  "nocheterna":"Nocheterna","elfo_vacio":"Elfos del Vacío","vulpera":"Vulpera"}
# (el Semielfo no existe en el libro Warcraft: es raza del PHB y conserva su texto propio)

# Un titulo de nivel 1 no siempre abre otra seccion: el "Anexo A: Cambio de forma"
# viene justo detras del druida y es suyo. Solo cortan los cambios de capitulo o
# de parte; asi la ultima clase/raza deja de tragarse los capitulos siguientes.
CORTE_MAYOR = re.compile(r"^(?:cap[ií]tulo|parte|ap[eé]ndice|[ií]ndice)\b", re.I)

# El "Anexo A: Cambio de forma" va justo detras del druida y entra en su tramo solo.
# El de companeros demoniacos, en cambio, esta detras del capitulo de conjuros, asi que
# se le asigna al brujo de forma explicita.
APENDICE_DE_CLASE = {"brujo": "Apéndice C: Compañeros Demoníacos"}

def chapter(className):
    wc = nk(className); start = end = None
    for lvl, txt, k, a, b in heads:
        if lvl == 2 and start is None and k == wc:
            start = b
            continue
        if start is None: continue
        # igual que en `chapter_generic`: la ultima clase del libro se quedaba con todo
        # lo que venia detras: los capitulos de personalizacion y de conjuros enteros
        if (lvl == 2 and k != wc and k in CLASSNAMES) or (lvl == 1 and CORTE_MAYOR.match(txt)):
            end = a; break
    return (start, end if end else len(src)) if start is not None else None

def next_heading(pos, lvl):
    for l, t, k, a, b in heads:
        if a > pos and l <= lvl: return a
    return len(src)

def feature_text(className, featName):
    ch = chapter(className)
    if not ch: return None
    a, b = ch; wt, wb = nk(featName), nkbase(featName)
    for lvl, txt, k, ha, he in heads:
        if a <= ha < b and lvl in (3, 4) and (k == wt or (wb and k == wb)):
            bs = src.find("\n", he); be = min(next_heading(bs, lvl), b)
            return clean_body(_cuerpo_rasgo(src[bs:be])) or None
    return None

# (las clases se procesan mas abajo, cuando ya estan definidos chapter_generic y bold_entries)

RACENAMES = set(nk(v) for v in RACE_MD.values())

def chapter_generic(name, names_set, level=2):
    """Tramo del libro que va del titulo `name` al siguiente titulo hermano de su grupo."""
    wc = nk(name); start = end = None
    for lvl, txt, k, a, b in heads:
        if lvl == level and start is None and k == wc:
            start = b
            continue
        if start is None: continue
        # se corta en el siguiente hermano del grupo o, si esta es la ultima entrada, en
        # el siguiente capitulo. Sin esto la ultima raza se quedaba
        # con TODO lo que venia detras en el libro (las formas del druida, el elemental
        # del mago, los diablillos del brujo...).
        if (lvl == level and k != wc and k in names_set) or (lvl == 1 and CORTE_MAYOR.match(txt)):
            end = a; break
    return (start, end if end else len(src)) if start is not None else None

BOLD_ENTRY = re.compile(r"\*\*\*\s*([^*\n]+?)\.?\s*\*\*\*\s*(.*?)(?=\n\s*\*\*\*|\n#{1,6}\s|\Z)", re.S)
def bold_entries(rango):
    """Rasgos escritos como '***Nombre.*** texto' (asi van los raciales y las dotes),
    que no son titulos y por eso no aparecen en el indice de encabezados."""
    if not rango: return {}
    a, b = rango
    out = {}
    for m in BOLD_ENTRY.finditer(src[a:b]):
        nombre, cuerpo = m.group(1).strip(), clean_body(m.group(2))
        if nombre and cuerpo: out.setdefault(nk(nombre), cuerpo)
    return out

def parecido_en(rango, featName, negritas, minimo=0.86):
    """Emparejar por parecido de nombre dentro del capitulo. NO se usa: probado con
    umbral 0.86 solo recuperaba 2 rasgos de 217 y podia pegarle a un rasgo el texto
    de otro, asi que no compensa. Se deja por si hiciera falta con revision manual."""
    if not rango: return None
    a, b = rango
    cands = dict(negritas)
    for lvl, txt, k, ha, he in heads:                    # titulos del propio capitulo
        if a <= ha < b and lvl in (3, 4, 5):
            bs = src.find("\n", he); be = min(next_heading(bs, lvl), b)
            cuerpo = clean_body(_cuerpo_rasgo(src[bs:be]))
            if cuerpo: cands.setdefault(k, cuerpo)
    if not cands: return None
    wt = nk(featName)
    mejor = max(cands, key=lambda k: difflib.SequenceMatcher(None, wt, k).ratio())
    if difflib.SequenceMatcher(None, wt, mejor).ratio() >= minimo: return cands[mejor]
    return None

def feature_in(rango, featName, levels=(3, 4, 5)):
    """Texto de un rasgo buscado SOLO dentro del tramo indicado."""
    if not rango: return None
    a, b = rango; wt, wb = nk(featName), nkbase(featName)
    for lvl, txt, k, ha, he in heads:
        if a <= ha < b and lvl in levels and (k == wt or (wb and k == wb)):
            bs = src.find("\n", he); be = min(next_heading(bs, lvl), b)
            return clean_body(_cuerpo_rasgo(src[bs:be])) or None
    return None

def _raiz(w):
    """Raiz basta de una palabra: quita el sufijo para que 'profano' y 'profana' o
    'asesinato' y 'asesino' se reconozcan como el mismo termino."""
    return re.sub(r"(?:os|as|es|o|a|e)$", "", w)[:6]


# El addon renombra dos subclases respecto al libro y lleva sus propios alias
# (HarfordDnDBook: retribucion -> represion). Aqui hace falta el camino inverso.
SUBCLASE_ALIAS = {
    "represion": "retribucion",
    "viajero del viento": "caminavientos",
    # el recurso y la subclase del guerrero se llaman Ira en la mesa y Furia en el Libro 1.
    # Va con la clase delante porque el Cazador de Demonios tiene su propia Marca de Ira,
    # que el libro SI titula asi y no debe irse a buscar "furia".
    "guerrero/ira": "furia",
}


def subcapitulo(rango_clase, subname, class_id=None):
    """Tramo del libro correspondiente a UNA subclase, dentro del capitulo de su clase.

    Los rasgos de subclase deben buscarse aqui y no en todo el capitulo: si no, las tres
    subclases del Brujo se llevaban la MISMA "Lista Ampliada de Conjuros" (la primera)."""
    if not rango_clase: return None
    a, b = rango_clase
    wn = SUBCLASE_ALIAS.get("%s/%s" % (class_id, nk(subname)),
                            SUBCLASE_ALIAS.get(nk(subname), nk(subname)))
    raices = {_raiz(w) for w in wn.split() if len(w) > 4}
    marcas = [(lvl, k, ha) for lvl, txt, k, ha, he in heads if a <= ha < b and lvl == 3]
    candidatos = []
    for i, (lvl, k, ha) in enumerate(marcas):
        # el libro titula la subclase con su nombre largo ("Estudio de la Afliccion")
        # tambien por raiz: el addon dice "Profano" y el libro "Presencia Profana", y
        # "Asesinato" frente a "Asesino". Cambia el genero o el sufijo, no el termino.
        if (k == wn or wn in k.split() or (len(wn) > 5 and wn in k)
                or (raices and raices & {_raiz(w) for w in k.split() if len(w) > 4})):
            fin = marcas[i+1][2] if i + 1 < len(marcas) else b
            candidatos.append((fin - ha, ha, fin, k == wn))
    if not candidatos: return None
    # El nombre de la subclase aparece dos veces: en el rasgo que dice "elige un camino"
    # y en la seccion de la subclase de verdad. La primera es un parrafo suelto y la
    # segunda trae todos sus rasgos, asi que se queda el tramo mas largo. Sin esto, los
    # tres caminos del paladin cogian el texto generico de Canalizar Divinidad en vez de
    # sus propias opciones (Luz del Amanecer, Consagracion...).
    # ...pero un titulo que sea EXACTAMENTE el nombre gana al que solo lo contiene: el
    # capitulo del guerrero tiene "Furia Interna" (el rasgo de recurso, nivel 2) antes que
    # "Furia" (la especializacion), y por longitud se llevaba el primero, dejando a la
    # subclase con una sola frase de presentacion.
    exactos = [c for c in candidatos if c[3]]
    _largo, ini, fin, _ex = max(exactos or candidatos)
    return (ini, fin)

def intro_de_subclase(rango):
    """Parrafos de presentacion de una subclase: lo que va entre su titulo y su primer rasgo.

    El libro los tiene para las 37, pero el bucle de subclases solo importaba los RASGOS y
    nunca tocaba `desc`, asi que las 37 se quedaban con la frase corta del addon (38-112
    caracteres) mientras las subrazas si traian su parrafo (150-470)."""
    if not rango:
        return None
    ini, fin = rango
    cuerpo = None
    for i, (lvl, txt, k, a, b) in enumerate(heads):
        if a != ini:
            continue
        cuerpo = b
        for l2, t2, k2, a2, b2 in heads[i+1:]:
            if a2 >= fin:
                break
            fin = a2
            break
        break
    if cuerpo is None:
        return None
    return clean_body(src[cuerpo:fin]) or None

# rasgos de clase del Caldero de Tasha (titulos en imagen): cuerpos curados en Export/
_TASHA_R = {}
import os as _os
_tr = r"C:/Users/marco/Documents/New project/RuleSource/Export/rasgos_tasha.json"
if _os.path.exists(_tr):
    for _k, _v in json.load(io.open(_tr, encoding="utf-8")).items():
        _TASHA_R[nk(_k)] = _v["texto"]

# ----- CLASES: intro del capitulo + rasgos (como titulo o en negrita dentro del capitulo) -----
cf = ct = 0
# ----- recuadros con marco ('>' del markdown = sidebars del PDF): sacarlos TODOS -----
def cajas_de(rango):
    """Bloques '>' del capitulo, fusionando los que solo separa una linea en blanco
    (en el libro son un mismo recuadro, p.ej. titulo + stat block)."""
    if not rango: return []
    if isinstance(rango, tuple): rango = src[rango[0]:rango[1]]
    lineas = rango.split("\n")
    grupos, actual, i = [], [], 0
    while i < len(lineas):
        l = lineas[i]
        if l.lstrip().startswith(">"):
            actual.append(l); i += 1; continue
        if actual and not l.strip():
            j = i
            while j < len(lineas) and not lineas[j].strip(): j += 1
            if j < len(lineas) and lineas[j].lstrip().startswith(">"):
                actual.append(">"); i = j; continue
        # Dentro de un stat block hay lineas a las que el libro no les puso el '>':
        # "***Garra.*** *Ataque de arma...*" lleva marca pero la linea siguiente,
        # " *Impacto:* (1d12 + modificador) de dano cortante.", no. Cerrar el recuadro ahi
        # perdia el dano de todas las formas y criaturas invocadas, asi que se absorbe.
        if actual and re.match(r"\s*[*\-•]|\s+[a-záéíóúñ]", l) and not re.match(r"\s*_{3,}", l):
            actual.append("> " + l.strip()); i += 1; continue
        if actual: grupos.append("\n".join(actual)); actual = []
        i += 1
    if actual: grupos.append("\n".join(actual))
    return [g for g in grupos if len(re.sub(r"[>\s]", "", g)) > 40]

def anexar_cajas(obj, rango):
    """Recoge los recuadros del capitulo que no esten ya en el desc del objeto ni en el
    de sus rasgos/subclases/subrazas y los guarda en `extras`: la ficha de la web los
    muestra AL FINAL del todo, no pegados a la introduccion."""
    cajas = cajas_de(rango)
    if not cajas: return 0
    textos = [obj.get("desc") or "", obj.get("extras") or ""]
    for f in obj.get("features", []) + obj.get("traits", []): textos.append(f.get("desc") or "")
    for s in obj.get("subclasses", []) + obj.get("subraces", []):
        textos.append(s.get("desc") or "")
        for f in s.get("features", []) + s.get("traits", []): textos.append(f.get("desc") or "")
    todo = nk(" ".join(textos))
    n = 0
    for caja in cajas:
        clave = nk(re.sub(r"[>#*|]", "", caja))[:70]
        if clave and clave not in todo:
            obj["extras"] = ((obj.get("extras") or "").rstrip() + "\n\n" + caja.strip()).strip()
            todo += " " + clave; n += 1
    return n

ncajas = 0
_BLOQUE_CLASE = re.compile(r"(?ms)^##\s+Rasgos de Clase\s*$(.*?)(?=^#{1,3}\s)")
_BLOQUE_SUELTO = re.compile(r"(?ms)(^#{4}\s+Puntos de [Gg]olpe\s*$.*?)(?=^#{1,3}\s)")


def bloque_de_clase(rango):
    """Puntos de golpe, competencias y equipo inicial: el bloque que abre cada clase.

    Es lo primero que mira quien se hace un personaje (dado de golpe, con que armaduras y
    armas es competente, sus dos salvaciones, que habilidades puede elegir y con que
    equipo empieza) y no estaba en el compendio.
    """
    if not rango:
        return ""
    # chapter() devuelve el TRAMO (inicio, fin) del libro, no el texto
    a, b = rango
    trozo = src[a:b]
    m = _BLOQUE_CLASE.search(trozo)
    if not m:
        # el Brujo no lleva la cabecera "Rasgos de Clase", pero si los tres epigrafes
        m = _BLOQUE_SUELTO.search(trozo)
    if not m:
        return ""
    txt = m.group(1).strip()
    # los "___" son la regla horizontal con la que el libro subraya cada epigrafe
    txt = re.sub(r"(?m)^_{3,}\s*$", "", txt)
    return re.sub(r"\n{3,}", "\n\n", txt).strip()


ORDINAL_NIVEL = {"1er": 1, "2do": 2, "3er": 3, "4to": 4, "5to": 5, "6to": 6, "7mo": 7,
                 "8vo": 8, "9no": 9, "10mo": 10}
_NIVEL_PARRAFO = re.compile(
    r"(?:En el|A partir del|Al alcanzar el)\s+(1er|2do|3er|4to|5to|6to|7mo|8vo|9no|10mo|[0-9]{1,2})"
    r"[º°o]?\s+nivel", re.I)


def _nombre_base(n):
    return re.sub(r"\s*\([^)]*\)\s*$", "", n or "").strip().lower()


def _base_repetida(clase, rasgo):
    base = _nombre_base(rasgo.get("name"))
    iguales = [x for x in clase.get("features", []) if _nombre_base(x.get("name")) == base]
    return len(iguales) > 1 and len({x.get("level") for x in iguales}) > 1

def parrafo_de_su_nivel(texto, nivel):
    """El parrafo que habla del nivel del rasgo, no el de toda la seccion.

    El libro mete la mejora dentro de la seccion del rasgo base ("Pericia" explica el
    nivel 1 y, dos parrafos mas abajo, el 6). Sin esto, "Pericia (mejora)" se quedaba con
    el texto del nivel 1, "En el 1er nivel" incluido.
    """
    if not texto or not nivel:
        return texto
    partes = [p for p in texto.split("\n\n") if p.strip()]
    if len(partes) < 2:
        return texto
    propio = []
    for p in partes:
        m = _NIVEL_PARRAFO.search(p)
        if not m:
            continue
        n = ORDINAL_NIVEL.get(m.group(1).lower()) or (int(m.group(1)) if m.group(1).isdigit() else None)
        if n == nivel:
            propio.append(p)
    return "\n\n".join(propio) if propio else texto


# El recurso del guerrero se llama Ira en la mesa; el Libro 1 lo llama Furia. No entra en
# TERMINOS_DE_LA_CASA porque "furia" es legitimo en otras siete clases -- Punos de Furia
# del monje, Furia de Elune, Furia Elemental, Furia Demoniaca -- asi que se aplica solo al
# texto que se importa del capitulo del guerrero.
def ira_del_guerrero(texto, class_id):
    if class_id != "guerrero" or not texto:
        return texto
    return re.sub(r"\bfuria\b", "ira", re.sub(r"\bFuria\b", "Ira", texto))


ci = 0
for c in kb["classes"]:
    cn = CLASS_MD.get(c["id"], c["name"])
    intro = section(cn, 2, stop_at_names={"rasgos de clase"})
    if intro and len(intro) > len(c.get("desc", "")): c["desc"] = intro
    negritas_c = bold_entries(chapter(cn))
    bloque = bloque_de_clase(chapter(cn))
    if bloque: c["classBlock"] = bloque

    rango_cl = chapter(cn)
    # cada subclase tiene su propio tramo: sus rasgos se buscan SOLO ahi
    sub_rango = {s["id"]: subcapitulo(rango_cl, s["name"], c["id"]) for s in c["subclasses"]}
    for f in c["features"]:
        ct += 1
        full = (feature_text(cn, f["name"])
                or negritas_c.get(nk(f["name"])) or negritas_c.get(nkbase(f["name"]))
                or _TASHA_R.get(nk(f["name"])))
        # solo cuando DOS rasgos comparten nombre base y se diferencian por el nivel
        # ("Pericia" y "Pericia (mejora)"): ahi el libro mete los dos en una seccion. En
        # el resto, los parrafos de otros niveles son el escalado del propio rasgo y
        # recortarlos le quitaba la mitad del texto (Ataque furtivo, Cambio de forma...).
        if full and _base_repetida(c, f): full = parrafo_de_su_nivel(full, f.get("level"))
        if full and len(full) > len(f.get("desc", "")): f["desc"] = full; cf += 1
    for s in c["subclasses"]:
        rs = sub_rango.get(s["id"])
        ins = ira_del_guerrero(intro_de_subclase(rs), c["id"])
        if ins and len(ins) > len(s.get("desc", "")):
            s["desc"] = ins
            ci += 1
        neg_s = bold_entries(rs) if rs else {}
        for f in s["features"]:
            ct += 1
            full = ((feature_in(rs, f["name"], levels=(4, 5, 6)) if rs else None)
                    or (feature_in(rs, f["name"]) if rs else None)
                    or neg_s.get(nk(f["name"])) or neg_s.get(nkbase(f["name"]))
                    or feature_text(cn, f["name"])
                    or negritas_c.get(nk(f["name"])) or negritas_c.get(nkbase(f["name"]))
                    or _TASHA_R.get(nk(f["name"])))
            if full and len(full) > len(f.get("desc", "")): f["desc"] = full; cf += 1
    feats_all = c["features"] + [x for s in c["subclasses"] for x in s["features"]]
    nombres_f = {nk(f["name"]) for f in feats_all}
    for f in feats_all:
        d0 = f.get("desc") or ""
        # los recuadros '>' que cayeron dentro de un rasgo no son suyos: se retiran y
        # anexar_cajas los recogera despues en los extras de la clase
        d0 = re.sub(r"(?:^>.*\n?)+\n?", "", d0, flags=re.M)
        # Si el texto capturo la seccion de otro rasgo, se QUITA esa seccion, no se corta
        # el texto ahi: truncar tiraba tambien lo que viniera despues. Al brujo le costaba
        # el "Grimorio de Servidumbre" entero, que va detras del "Grimorio de Sacrificio"
        # y no tiene tarjeta propia.
        cabeceras = [(len(m2.group(1)), nk(m2.group(2)), m2.start(), m2.end())
                     for m2 in re.finditer(r"^(#{1,6})\s+(.+)$", d0, re.M)]
        for i2, (lvl2, k2, ini2, _fin) in enumerate(cabeceras):
            if k2 not in nombres_f or k2 == nk(f["name"]): continue
            fin2 = next((c2[2] for c2 in cabeceras[i2+1:] if c2[0] <= lvl2), len(d0))
            d0 = d0[:ini2] + "" * (fin2 - ini2) + d0[fin2:]   # marcar sin mover indices
        d0 = re.sub(r"+", "\n\n", d0).strip()
        # rasgos de eleccion: las secciones internas que coinciden con una opcion
        # (Defensa, Duelos...) se reparten a esa opcion, no quedan como titulos sueltos
        opts = f.get("options") or (f.get("choice") or {}).get("options") or []
        if opts:
            por_nombre = {}
            for o in opts:
                et = o.get("label") or o.get("id") or ""
                por_nombre.setdefault(nk(et), o)
                por_nombre.setdefault(nk(re.sub(r"\s*\(.*\)\s*$", "", et)), o)
            secciones = list(re.finditer(r"^#{1,6}\s+(.+)$", d0, re.M))
            recortes = []
            for idx2, m2 in enumerate(secciones):
                o = por_nombre.get(nk(m2.group(1)))
                if not o: continue
                fin2 = secciones[idx2+1].start() if idx2+1 < len(secciones) else len(d0)
                cuerpo2 = d0[m2.end():fin2].strip()
                if cuerpo2 and len(cuerpo2) > len(o.get("desc") or ""):
                    o["desc"] = cuerpo2
                recortes.append((m2.start(), fin2))
            for a2, b2 in reversed(recortes):
                d0 = (d0[:a2] + d0[b2:])
        f["desc"] = re.sub(r"\n{3,}", "\n\n", d0).strip()
    ncajas += anexar_cajas(c, chapter(cn))
    # los apendices no van pegados a su clase en el libro (el de companeros demoniacos
    # esta detras del capitulo de conjuros), asi que se asignan a mano en vez de por
    # posicion, que es lo que hacia que se los quedara la clase equivocada
    if c["id"] in APENDICE_DE_CLASE:
        ncajas += anexar_cajas(c, chapter_generic(APENDICE_DE_CLASE[c["id"]], set(), level=1))

# ----- RAZAS: intro + rasgos propios y de subraza, buscados dentro del capitulo de la raza -----
rf = rt = rtok = 0
# El Semielfo no tiene capitulo en ninguno de los dos libros Warcraft, y el del Manual del
# Jugador es un OCR malo y de otra ambientacion (Tanis, Krynn), asi que no se puede
# importar. Este es texto de la casa, con la misma estructura que los capitulos del libro.
# La cita SI es real: es de Arator, de la historia corta "El hijo de dos mundos".
CAPITULO_DE_LA_CASA = {"semielfo": "*Toda mi vida he estado dividido. Elfo, humano, madre, padre, oscuridad, Luz. Pero ahora sé que no tengo por qué elegir entre ellos. Soy más que la suma de mis partes. No soy la mitad de nada. Estoy completo.*\n\n*— Arator el Redentor*\n\nLos semielfos nacieron de la alianza más improbable de la Segunda Guerra, cuando los quel'dorei de Quel'Thalas marcharon junto a los reinos humanos contra la Horda y descubrieron que sus vecinos de vida breve valían algo más que un tratado. De aquellos años quedaron unas pocas uniones y, de ellas, unos pocos hijos. Nunca han sido muchos: un elfo puede pasar un siglo entero sin cruzarse con otro semielfo.\n\nHeredan de sus padres elfos el oído fino, la afinidad natural por lo arácano y una vida larga; de sus padres humanos, la ambición, la curiosidad y esa prisa por dejar huella que los elfos nunca han terminado de entender. La mezcla suele dar gente capaz y difícil de encasillar, y casi siempre gente que ha aprendido pronto a caer bien a todo el mundo porque no tenía otro sitio al que ir.\n\n### Dos siluetas en una\nPara un humano, un semielfo parece un elfo; para un elfo, parece un humano. Son más altos que la mayoría de los humanos y menos esbeltos que los quel'dorei, con orejas más cortas que las de un elfo pero inconfundibles bajo el pelo. Los ojos casi siempre delatan el lado élfico, y a los varones les crece barba, cosa que ningún elfo hace: muchos se la dejan precisamente por eso, y otros se afeitan por el motivo contrario.\n\n### Vidas desacompasadas\nEl problema del semielfo no es su cara, sino su reloj. Crece al ritmo de un humano y es adulto a los veinte, pero sigue en pie ciento sesenta años después, cuando ya ha enterrado a sus amigos de infancia y a los hijos de estos. Entre elfos le pasa lo contrario: llega a la madurez cuando sus compañeros de juegos todavía son considerados niños, y le toca esperar un siglo a que le hablen de igual a igual. De ahí que tantos acaben en el camino, en una compañía de aventureros o en una torre de Dalaran, sitios donde a nadie le importa demasiado cuánto piensas durar.\n\n### Afiliación\nCasi todos los semielfos están del lado de la Alianza, y no por elección propia sino por herencia: sus padres elfos eran altos elfos de Quel'Thalas, aliados de los reinos humanos desde la Segunda Guerra. Cuando Quel'Thalas cayó y la mayoría de los quel'dorei se convirtieron en elfos de sangre y buscaron a la Horda, los pocos que permanecieron leales lo hicieron con Ventormenta y con Dalaran, y sus hijos mestizos con ellos. Nada se lo impone: hay semielfos en el Kirin Tor, en las compañías libres de Aguas Termales y alguno, muy pocos, del otro lado de la línea.\n\n### Nombres semielfos\nNo tienen nombres propios. Los criados entre humanos suelen recibir nombre élfico, y los criados entre elfos, nombre humano; en ambos casos, para dejar constancia de la mitad que no está delante. El apellido casi siempre es el del padre humano, porque las casas élficas rara vez inscriben a un mestizo en su linaje.\n\n**Nombres masculinos:** Arator, Giramar, Galadin, Aedan, Kelmar,\n Theron, Halduin, Loryan, Sarien, Belen\n\n**Nombres femeninos:** Aelin, Verissa, Elandra, Nariel, Mirelle,\n Kaelyn, Ithara, Serana, Alys, Ysolde\n\n**Apellidos:** Dawnstrider, Sunwhisper, Halfmoon, Silverbrand,\n Ashfield, Thornwood, Redbrook\n\n***Edad.*** Maduran al mismo ritmo que los humanos y se les considera adultos en torno a los veinte años, pero viven mucho más que ellos y no es raro que superen los ciento ochenta.\n\n***Alineamiento.*** Comparten la vena caótica de su parte élfica. Valoran la libertad y no les gusta ni mandar ni que les manden; la costumbre de no pertenecer a ningún sitio los vuelve poco dóciles y, a ojos de otros, imprevisibles.\n\n***Tamaño.*** Los semielfos miden entre 1,70 y 1,95 metros y pesan entre 60 y 90 kilogramos. Tu tamaño es Mediano. Para determinar tu altura y peso de forma aleatoria, usa el modificador de tamaño:\n\n***Modificador de Tamaño:*** 2d8\n\n***Altura:*** 1,20 metros + 25 cm + Mod. tamaño (cm)\n\n***Peso en Kilogramos:*** 50 + (2d4 x Mod. tamaño)\n\n***Velocidad.*** 9 metros."}

for r in kb["races"]:
    rn = RACE_MD.get(r["id"])
    if not rn: continue
    intro = CAPITULO_DE_LA_CASA.get(r["id"]) or section(rn, 2)
    if intro and len(intro) > len(r.get("desc", "")): r["desc"] = intro; rf += 1
    rango = chapter_generic(rn, RACENAMES)
    negritas = bold_entries(rango)
    # Cuando dos rasgos hermanos comparten el nombre base ("Incremento de caracteristica
    # (+2)" y "(+1)"), el libro los cuenta en una sola frase y esa frase pisaria los dos
    # con lo mismo, borrando la reparticion que el addon si distingue. En ese caso se
    # conserva lo que trae el addon.
    _bases = collections.Counter(
        nkbase(x["name"]) for x in r["traits"] + [y for s in r.get("subraces", []) for y in s["traits"]])
    for f in r["traits"] + [x for s in r.get("subraces", []) for x in s["traits"]]:
        rt += 1
        # Solo se protege el reparto de puntuaciones: ahi el addon dice "Fuerza +1" por
        # subraza y el libro lo cuenta todo en una frase, que pisaria a los hermanos con lo
        # mismo. Un rasgo repetido que no reparte puntos (la vision en la oscuridad del
        # draenei, el entrenamiento con armas del troll) si se enriquece.
        if _bases[nkbase(f["name"])] > 1 and re.search(r"\+\s*\d|aumenta en \d",
                                                      f.get("desc") or ""):
            continue
        full = (feature_in(rango, f["name"]) or negritas.get(nk(f["name"]))
                or negritas.get(nkbase(f["name"])))
        if full and len(full) > len(f.get("desc", "")): f["desc"] = full; rtok += 1
    # igual que en las clases: un recuadro que cayo dentro de un rasgo no es del rasgo.
    # El de "Crear un elfo noble" colgaba de los Idiomas del elfo de sangre.
    for f in r["traits"] + [x for s in r.get("subraces", []) for x in s["traits"]]:
        if f.get("desc"):
            f["desc"] = re.sub(r"\n{3,}", "\n\n",
                               re.sub(r"(?:^>.*\n?)+\n?", "", f["desc"], flags=re.M)).strip()
    ncajas += anexar_cajas(r, rango)

# ----- TRASFONDOS: Discord export con matcheo fuzzy -----
bgs = json.load(io.open(os.path.join(SP, "bgs_source.json"), encoding="utf-8"))
srckeys = {slug: nk(slug.replace("_", " ")) for slug in bgs}
bf = 0
# Un slug del export pertenece al trasfondo que se llama igual, y a ningun otro. Sin esta
# reserva, "Ermitano" se llevaba el texto de "eremita" con un parecido de 0,80: son dos
# trasfondos distintos (el Hermit del Manual del Jugador y la orden de eruditos de
# Warcraft) y el Ermitano acababa contando la historia del otro.
_reservados = {slug for slug, sk in srckeys.items()
               if any(nk(b["name"]) == sk for b in kb["backgrounds"])}
for b in kb["backgrounds"]:
    bnk = nk(b["name"])
    # el nombre puede venir con las palabras al reves ("Doble Agente" / "agente_doble"),
    # y con el ratio a secas se quedaba en 0,50 y no llegaba al umbral: se compara tambien
    # con las palabras ordenadas
    _orden = " ".join(sorted(bnk.split()))
    best, bestr = None, 0.0
    for slug, sk in srckeys.items():
        if slug in _reservados and sk != bnk:
            continue
        r = max(difflib.SequenceMatcher(None, bnk, sk).ratio(),
                difflib.SequenceMatcher(None, _orden, " ".join(sorted(sk.split()))).ratio())
        if r > bestr: best, bestr = slug, r
    if best is None: continue
    if bestr < 0.62: continue
    d = bgs[best]
    if d.get("desc"): b["desc"] = d["desc"]; bf += 1
    # La ilustracion viaja como ruta DENTRO del export; `deploy_compendium` la convierte y
    # deja aqui el nombre del fichero ya servible. La variante lleva la suya, que es otra.
    if d.get("image"):
        b["art"] = "%s/media/attachments/%s" % (best, d["image"])
    if d.get("variants"):
        b["variants"] = [{
            "id": "%s_%s" % (b["id"], re.sub(r"[^a-z0-9]+", "_", nk(v["name"])).strip("_")),
            "name": v["name"],
            "desc": v.get("desc") or "",
            "art": ("%s/media/attachments/%s" % (best, v["image"])) if v.get("image") else None,
        } for v in d["variants"]]
    rn = nk(d.get("rasgoName", ""))
    for f in b["traits"]:
        fn = nk(re.sub(r"^caracteristica:\s*", "", f["name"], flags=re.I))
        if d.get("rasgoDesc") and (fn == rn or "caracteristica" in nk(f["name"]) or difflib.SequenceMatcher(None, fn, rn).ratio() > 0.7):
            # la etiqueta del rasgo propio del trasfondo es "Característica:" en todo el compendio
            f["desc"] = d["rasgoDesc"]; f["name"] = d["rasgoName"]; break

# ----- TRASFONDOS del Manual del Jugador: presentacion, competencias, equipo y rasgo -----
PHB_BG = r"C:/Users/marco/Documents/New project/RuleSource/Export/trasfondos_phb.json"
PHB_RASGOS = PHB_BG.replace(".json", "_rasgos.json")
CAMPO_A_RASGO = {"competencias en habilidades": "competencias",
                 "competencias con herramientas": "competencia con herramientas",
                 "idiomas": "idiomas", "equipo": "equipo"}
bphb = brasgos = 0
if os.path.exists(PHB_BG):
    phb = {nk(x["nombre"]): x for x in json.load(io.open(PHB_BG, encoding="utf-8"))}
    rasgos_phb = json.load(io.open(PHB_RASGOS, encoding="utf-8")) if os.path.exists(PHB_RASGOS) else {}
    for b in kb["backgrounds"]:
        x = phb.get(nk(b["name"]))
        if not x: continue
        if x.get("desc") and len(x["desc"]) > len(b.get("desc", "")): b["desc"] = x["desc"]; bphb += 1
        for f in b["traits"]:
            fn = nk(f["name"])
            # los campos del manual ("Competencias en habilidades: ...") rellenan sus rasgos
            for campo, destino in CAMPO_A_RASGO.items():
                if fn.startswith(destino) and x.get(campo) and len(x[campo]) > len(f.get("desc", "")):
                    f["desc"] = x[campo]; brasgos += 1; break
            else:
                # el rasgo propio del trasfondo ("Caracteristica: Refugio del fiel")
                clave = nk(re.sub(r"^caracteristica:\s*", "", f["name"], flags=re.I))
                r = rasgos_phb.get(clave)
                if r and len(r["texto"]) > len(f.get("desc", "")):
                    f["desc"] = r["texto"]; brasgos += 1

# ----- VARIANTES de trasfondo del Manual del Jugador (Gladiador, Espia, Pirata...) -----
VAR_PHB = r"C:/Users/marco/Documents/New project/RuleSource/Export/variantes_phb.json"
nvar = 0
if os.path.exists(VAR_PHB):
    for v in json.load(io.open(VAR_PHB, encoding="utf-8")):
        b = next((x for x in kb["backgrounds"] if nk(x["name"]) == nk(v["bg"])), None)
        if not b: continue
        nombre = "Variante: " + v["variante"]
        if any(nk(tr["name"]) == nk(nombre) for tr in b["traits"]): continue
        b["traits"].append({"id": "var_" + nk(v["variante"]).replace(" ", "_"),
                            "level": None, "name": nombre, "type": "informativo",
                            "desc": v["texto"]})
        nvar += 1

# ----- TRASFONDOS propios del Libro 1 que el addon no tiene -----
import trasfondos_libro1
_nuevos_bg = 0
_bg_exist = {nk(b["name"]) for b in kb["backgrounds"]}
for _b in trasfondos_libro1.trasfondos():
    if nk(_b["name"]) in _bg_exist: continue
    kb["backgrounds"].append(_b); _nuevos_bg += 1
print("Trasfondos del Libro 1 anadidos: %d" % _nuevos_bg)



# ----- TRASFONDOS sin Discord: usar su rasgo 'Caracteristica' como descripcion -----
cff = 0
for b in kb["backgrounds"]:
    if b.get("desc"): continue
    car = next((t for t in b["traits"] if re.match(r"caracter", t["name"], re.I)), None)
    if car and car.get("desc"): b["desc"] = car["desc"]; cff += 1

# ----- limpieza a prosa de TODOS los desc (quita *, |, \cmd, blockquote) -----
BULLET = "•"
def is_table_line(l): return l.lstrip().startswith("|")
def strip_progression(text):
    """Elimina las tablas de progresion de clase ('| Nivel | ...') que el PDF extrae
    destrozadas (cabecera multilinea, ~20 columnas). Deja el resto (tablas limpias) intacto."""
    lines = text.split("\n"); out = []; i = 0; n = len(lines)
    while i < n:
        # La tabla del brujo sale del PDF sin el pipe inicial ("Nivel |Bonif."), asi que
        # no la reconocia ni esta funcion ni `is_table_line`: sus lineas se trataban como
        # prosa y acababan pegadas ("ConocidosConjuros", "EspacioDemonios").
        if (re.match(r"\s*\|?\s*Nivel\b.*\|", lines[i]) or "Espacios de Conjuros" in lines[i]):
            i += 1
            while i < n:
                if lines[i].strip() == "":
                    k = i + 1
                    while k < n and lines[k].strip() == "": k += 1
                    if k >= n or "|" not in lines[k]: i = k; break
                i += 1
            # quitar un 'El <Clase>' o titulo corto colgante justo antes; hay que saltarse
            # las lineas en blanco o el titulo se salva y se queda sin tabla debajo
            while out and not out[-1].strip(): out.pop()
            while out and out[-1].strip() and len(out[-1].strip()) < 24 and "|" not in out[-1]:
                out.pop()
                while out and not out[-1].strip(): out.pop()
            continue
        # La tabla del brujo salio del PDF SIN pipes: cabecera partida en varias lineas,
        # una fila de guiones y veinte filas "N.º +B ...". La web ya pinta la progresion
        # con los datos del addon, asi que este bloque solo duplicaba, y encima con las
        # cabeceras pegadas ("ConocidosConjuros", "EspacioDemonios").
        if re.fullmatch(r"[-:]{20,}", lines[i].strip()):
            # hacia atras: la cabecera, hasta el titulo corto o la linea en blanco
            while out and out[-1].strip() and not re.match(r"\s*#{1,6}\s", out[-1]):
                out.pop()
            if out and re.match(r"\s*#{1,6}\s", out[-1]) and len(out[-1].strip()) < 30: out.pop()
            i += 1
            while i < n and (not lines[i].strip() or re.match(r"\s*\d+\.?[ºo]?\s", lines[i])):
                i += 1
            continue
        out.append(lines[i]); i += 1
    return "\n".join(out)
# --- normalizacion de titulos internos: solo primera mayuscula, conservando nombres
# --- de clase/raza y propios ("Creando un Caballero de la Muerte", "Gracia de Elune")
_PROTEGIDOS = sorted(set(list(CLASS_MD.values()) + list(RACE_MD.values()) +
                         ["Elune", "Azeroth", "Illidari", "Rey Exánime", "Cenarion",
                          "Alexstrasza", "Ysera", "Kalimdor", "Rasganorte",
                          "Harford", "Ventormenta", "Lordaeron", "Quel'Thalas",
                          "Dalaran", "Orgrimmar", "Tol Barad", "Pandaria",
                          "Draenor", "Rasganorte", "Feralas", "Silithus",
                          # los de las subrazas, que salian en minuscula en su titulo
                          "Forjaz", "Exodar", "Mulgore", "Monte Alto", "Gnomeregan",
                          "Gilneas", "Alterac", "Ravenholdt", "Kirin Tor", "Tirisfal"]),
                     key=len, reverse=True)
def norm_titulo(t):
    # a minusculas todo menos la primera letra y la primera tras ":" o "."
    def frase(s):
        s = s.strip()
        if not s: return s
        s = s[0] + s[1:].lower()
        return s
    partes = re.split(r"(\s*[:.]\s*)", t.strip())
    t2 = "".join(frase(p) if i % 2 == 0 else p for i, p in enumerate(partes))
    # restaurar nombres protegidos con su capitalizacion canonica
    for p in _PROTEGIDOS:
        t2 = re.sub(re.escape(p), p, t2, flags=re.I)
    return t2

def prose(t):
    if not t: return t
    t = t.replace("\r", "")
    # los recuadros llegan aqui tal cual salen del libro, sin pasar por `clean_body`: un
    # marcador de titulo sin texto detras se veia como "###" suelto dentro del stat block
    t = re.sub(r"(?m)^(\s*>\s*)#{1,6}\s*$", r"\1", t)
    t = strip_progression(t)
    # titulos internos (### y > #####): normalizar su capitalizacion
    t = re.sub(r"^(\s*(?:>\s*)?#{1,6}\s+)(.+)$",
               lambda m: m.group(1) + norm_titulo(m.group(2)), t, flags=re.M)
    # cabeceras en linea del libro ("***Caracteristica Minima.*** texto"): misma norma
    t = re.sub(r"(?m)^((?:>\s*)?)\*\*\*([^*\n]{2,45}?)(\.?)\*\*\*",
               lambda m: m.group(1) + "***" + norm_titulo(m.group(2)) + m.group(3) + "***", t)
    out = []
    for line in t.split("\n"):
        if is_table_line(line):
            # preservar filas de tabla intactas (el template las renderiza); solo aislar el bloque
            if out and out[-1].strip() and not is_table_line(out[-1]): out.append("")
            out.append(re.sub(r"[ \t]{2,}", " ", line).rstrip())
            continue
        l = re.sub(r"\\[a-zA-Z]+", "", line)
        # las negritas/cursivas del markdown se conservan: la web las renderiza
        # asterisco realmente aislado (espacio a los dos lados). No vale mirar solo si le
        # sigue un espacio: el cierre de cursiva detras de dos puntos cumple eso y se
        # borraba ("*Ataque de arma cuerpo a cuerpo:*" perdia el cierre y el resto del
        # stat block se quedaba sin formato).
        l = re.sub(r"(?:(?<=\s)|^)\*(?=\s|$)", "", l)
        l = re.sub(r"(?<![A-Za-z0-9])_([^_\n]+)_(?![A-Za-z0-9])", r"\1", l)
        # los bloques '>' son los recuadros con marco del PDF (reglas adicionales,
        # formas druidicas, stat blocks): se conservan para que la web los enmarque
        es_caja = bool(re.match(r"^\s*>", l))
        if es_caja: l = re.sub(r"^\s*>\s?", "> ", l)
        l = l.replace("`", "")
        if not es_caja: l = l.replace("|", "")
        l = re.sub(r"^\s*[-" + BULLET + r"]\s+", BULLET + " ", l)
        l = re.sub(r"[ \t]+", " ", l)
        out.append(l)
    t = "\n".join(out)
    t = re.sub(r"\n{3,}", "\n\n", t)
    t = re.sub(r"\n\s*-{3,}\s*$", "", t)          # regla horizontal del markdown
    return referencias(limpiar(normalizar_habilidades(unir_lineas(_sin_cola_de_titulo(t.strip())))), web=True)
def walk(o):
    if isinstance(o, dict):
        if isinstance(o.get("desc"), str): o["desc"] = a_metrico(prose(o["desc"]))
        if isinstance(o.get("extras"), str): o["extras"] = a_metrico(prose(o["extras"]))
        if isinstance(o.get("classBlock"), str): o["classBlock"] = a_metrico(prose(o["classBlock"]))
        # los conjuros usan `description` y su texto ya viene en metrico desde el addon:
        # se les pasa la terminologia y la limpieza de OCR, pero NO `a_metrico`, que
        # confundiria el verbo ("Purificas y libras de todo veneno") con las libras.
        if isinstance(o.get("description"), str):
            o["description"] = limpiar(normalizar_habilidades(o["description"]))
        # `mechanics` y `roleNotes` son texto del addon, igual que `description`: pasan por
        # la misma limpieza (tildes y OCR) y tampoco por `a_metrico`, que ya viene aplicado
        for campo in ("mechanics", "roleNotes"):
            if isinstance(o.get(campo), str):
                o[campo] = limpiar(normalizar_habilidades(o[campo]))
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(kb)

# ----- competencias, herramientas, idiomas y equipo del export de Discord -----
# Va DESPUES de walk() por dos razones: los trasfondos del Libro 1 se anaden mas abajo, y
# sus rasgos llegan con un resto de marcado que la limpieza deja en vacio, asi que antes
# de ella parecian llenos y la pasada los saltaba.
_CAMPO_RASGO = (("skills", ("competencias", "competencia en habilidad", "habilidades",
                            "competencias en habilidades")),
                ("tools", ("competencia con herramientas", "herramientas", "herramienta",
                           "competencias con herramientas")),
                ("langs", ("idioma", "idiomas")),
                ("equip", ("equipo",)))
_rellenos = 0
for b in kb["backgrounds"]:
    bnk = nk(b["name"])
    # el nombre puede venir con las palabras al reves ("Doble Agente" / "agente_doble"),
    # asi que se compara tambien con las palabras ordenadas
    orden = " ".join(sorted(bnk.split()))
    mejor, mejorr = None, 0.0
    for slug, sk in srckeys.items():
        # misma reserva que arriba: un slug es del trasfondo que se llama igual
        if slug in _reservados and sk != bnk:
            continue
        r = max(difflib.SequenceMatcher(None, bnk, sk).ratio(),
                difflib.SequenceMatcher(None, orden, " ".join(sorted(sk.split()))).ratio())
        if r > mejorr: mejor, mejorr = slug, r
    if mejor is None or mejorr < 0.62: continue
    d = bgs[mejor]
    for campo, etiquetas in _CAMPO_RASGO:
        valor = (d.get(campo) or "").strip()
        if not valor: continue
        for f in b["traits"]:
            if nk(f["name"]) in [nk(x) for x in etiquetas] and not (f.get("desc") or "").strip():
                f["desc"] = valor[0].upper() + valor[1:]
                if not f["desc"].endswith("."): f["desc"] += "."
                _rellenos += 1
                break
print("Rasgos de trasfondo rellenados desde el export: %d" % _rellenos)

# ----- caracteristicas sugeridas (personalidad, ideal, vinculo, defecto) -----
# El compendio no tenia ninguna de las cuatro tablas. El Libro 1 las trae como tablas
# markdown limpias; se atribuye cada juego al trasfondo cuyo titulo lo precede.
import tablas_personalidad as _tp
import tablas_discord as _td
_TABLAS = {}
# el export de Discord es la mejor fuente: trae las cuatro tablas completas y su carpeta
# ya lleva el nombre del trasfondo, asi que no hay que adivinar a quien pertenecen
for _slug, _juego in _td.todas().items():
    _TABLAS[_slug.replace("_", " ")] = _juego
# el Manual del Jugador las trae como listas y su OCR esta bastante peor: solo sobreviven
# las tablas COMPLETAS cuyo titulo es de verdad un trasfondo, porque una tabla mal
# atribuida es peor que no tenerla. El Libro 1 va despues y manda sobre ellas.
_PHB_MD = r"C:/Users/marco/Documents/New project/RuleSource/Rulebooks_MD/manual_del_jugador.md"
if os.path.exists(_PHB_MD):
    _TABLAS.update(_tp.de_listas(io.open(_PHB_MD, encoding="utf-8", errors="ignore").read()))
_TABLAS.update(_tp.de_tablas(src))
_sug = 0
for b in kb["backgrounds"]:
    bn = _tp.nk(b["name"])
    # el slug del export sustituye por "_" las letras acentuadas ("agente_de_pr_ncipe"),
    # asi que la comparacion exacta no vale para esos
    _mejor, _mr = None, 0.0
    for titulo in _TABLAS:
        tk = _tp.nk(titulo)
        r = max(difflib.SequenceMatcher(None, tk, bn).ratio(),
                difflib.SequenceMatcher(None, " ".join(sorted(tk.split())),
                                        " ".join(sorted(bn.split()))).ratio())
        if r > _mr: _mejor, _mr = titulo, r
    for titulo, juego in ([(_mejor, _TABLAS[_mejor])] if _mejor and _mr >= 0.82 else []):
        if True:
            # esta pasada va despues de walk(), asi que el texto no ha pasado por la
            # limpieza: se le aplica aqui (viene del mismo OCR que el resto del libro)
            texto = limpiar(normalizar_habilidades(_tp.como_texto(juego)))
            if texto:
                # El export trae el preambulo de las caracteristicas sugeridas DELANTE de
                # la presentacion del trasfondo, asi que la ficha abria hablando de la
                # personalidad del arquetipo. La presentacion empieza siempre en segunda
                # persona ("Eres un informante", "Fuiste abandonado", "Has formado parte"),
                # y eso marca el corte: lo de antes es preambulo y se va con sus tablas.
                parrafos = [x for x in (b.get("desc") or "").split("\n") if x.strip()]
                corte = next((j for j, x in enumerate(parrafos) if j and re.match(
                    r"(?i)^(eres|has|fuiste|naciste|creciste|serviste|viviste|perteneces|trabajaste)\b", x.strip())), 0)
                if corte:
                    texto = "\n\n".join(parrafos[:corte]) + "\n\n" + texto
                    b["desc"] = "\n\n".join(parrafos[corte:])
                b["suggested"] = texto; _sug += 1
            break
print("Trasfondos con caracteristicas sugeridas: %d" % _sug)


# Correcciones puntuales frente al export. NO se sobrescribe en bloque a proposito: el
# emparejado difuso confunde "Ermitano" con "Eremita" (que son los dos trasfondos
# duplicados) y le cambiaria sus competencias por las del otro. Aqui solo van los dos
# casos verificados: un idioma que era el generico de otro trasfondo, y unas competencias
# que se habian quedado en un texto de relleno.
_CORRIGE = {
    ("Doble Agente", "Idioma"): "Uno de tu elección perteneciente a la facción opuesta.",
    ("Veterano del campo de batalla", "Competencias"): "Atletismo, Percepción.",
}
# El equipo y las competencias son la enumeracion que sigue a los dos puntos del manual
# ("Equipo: un simbolo sagrado, ..."), asi que el texto empieza en minuscula y en la ficha,
# donde el titulo va aparte, queda como una frase cortada.
_nmayus = 0
for b in kb["backgrounds"]:
    for f in b["traits"]:
        d = (f.get("desc") or "").strip()
        if d and d[0].islower():
            f["desc"] = d[0].upper() + d[1:]
            _nmayus += 1
print("Rasgos de trasfondo que empezaban en minuscula: %d" % _nmayus)

for b in kb["backgrounds"]:
    for f in b["traits"]:
        v = _CORRIGE.get((b["name"], f["name"]))
        if v: f["desc"] = v

# ----- habilidades que concede cada trasfondo (respaldo por texto) -----
# El extractor las saca de los efectos declarados del addon, pero siete trasfondos propios
# no tienen rasgo de "Competencias" (nombran el rasgo con la habilidad misma), asi que
# para esos se leen del texto contra la lista cerrada de habilidades.
_HABILIDADES = ["Acrobacias", "Atletismo", "Conocimiento Arcano", "Engaño", "Historia",
                "Interpretación", "Intimidación", "Investigación", "Juego de Manos",
                "Medicina", "Naturaleza", "Percepción", "Perspicacia", "Persuasión",
                "Religión", "Sigilo", "Supervivencia", "Trato con Animales"]
_sk = 0
for b in kb["backgrounds"]:
    if b.get("skills"):
        continue
    encontradas = []
    for f in b["traits"]:
        texto = (f.get("name") or "") + " " + (f.get("desc") or "")
        if not re.search(r"(?i)competenc|habilidad", texto):
            continue
        for h in _HABILIDADES:
            if re.search(r"(?i)\b" + re.escape(h) + r"\b", texto) and h not in encontradas:
                encontradas.append(h)
    if encontradas:
        b["skills"] = encontradas; _sk += 1
print("Trasfondos con habilidades leidas del texto: %d" % _sk)

# ----- tabla de progresion completa (niveles 1 a 20) -----
# La ficha de clase solo llegaba al nivel 6, que es hasta donde tiene rasgos el addon. El
# libro trae la tabla entera, con el bono de competencia y los rasgos de cada nivel, asi
# que se adjunta tal cual: es informacion del manual, no una regla inventada aqui.
import tabla_clases_libro1 as _tc
# en esta fase los nombres del addon van sin tilde (Picaro, Chaman, Paladin) y el libro
# los escribe con ella: se empareja sin tildes
_TABLAS_CLASE = {_tc.nk(k): v for k, v in _tc.leer().items()}
_ntab = 0
for c in kb["classes"]:
    filas = _TABLAS_CLASE.get(_tc.nk(c["name"]))
    if not filas:
        continue
    c["levelTable"] = [{"level": lv,
                        "prof": filas[lv].get("comp") or "",
                        "features": filas[lv].get("rasgos") or []}
                       for lv in sorted(filas)]
    _ntab += 1
print("Subclases con presentacion del libro: %d de %d"
      % (ci, sum(len(c["subclasses"]) for c in kb["classes"])))
print("Clases con tabla de progresion completa: %d" % _ntab)

# ----- lista de conjuros por clase (niveles 0 a 9) -----
# La ficha construia esa lista con los conjuros que EXISTEN, y el compendio no pasa del
# nivel 4, asi que la clase parecia no tener conjuros altos. El libro trae la lista entera
# en sus dos capitulos 6, con la marca de donde esta descrito cada uno.
import listas_conjuros_libro1 as _lc
_LISTAS = {_tc.nk(k): v for k, v in _lc.leer().items()}
_nlist = 0
for c in kb["classes"]:
    lst = _LISTAS.get(_tc.nk(c["name"]))
    if lst is None and _tc.nk(c["name"]) == "picaro":
        lst = _LISTAS.get("picaro sutileza")
    if not lst:
        continue
    c["spellList"] = [{"level": lv,
                       "spells": [{"name": n, "src": f} for n, f in lst[lv]]}
                      for lv in sorted(lst)]
    _nlist += 1
print("Clases con lista de conjuros del libro: %d" % _nlist)

# ----- espacios de conjuro por nivel (1-20) -----
# La progresion que trae el addon llega al nivel 6 porque es lo que el addon juega; la
# tabla del libro tiene las columnas completas y se verifican contra las reglas de 5e.
import progresion_conjuros_libro1 as _pc
_PROG, _pc_avisos = _pc.leer()
_PROG = {_tc.nk(k): v for k, v in _PROG.items()}
_nprog = 0
for c in kb["classes"]:
    p = _PROG.get(_tc.nk(c["name"]))
    if not p:
        continue
    c["slotTable"] = [dict(nivel=lv, **p[lv]) for lv in sorted(p)]
    _nprog += 1
print("Clases con espacios de conjuro 1-20: %d" % _nprog)

# ----- listas de conjuros ampliadas de subclase -----
# El libro las llama con el nombre largo ("Presencia de Sangre") y el addon con el corto
# ("Sangre"), asi que se emparejan por contencion dentro de la MISMA clase.
import difflib as _dl
import listas_conjuros_subclase as _lcs
_SUB = {}
for (_c, _s), _filas in _lcs.leer().items():
    _SUB.setdefault(_tc.nk(_c), {})[_tc.nk(_s)] = _filas
# el addon y el libro no siempre coinciden en el nombre de la subclase y el parecido no
# basta: "Profano" no se parece a "Presencia Profana" y "Represion" no se parece a
# "Camino de la Retribucion"
_SUB_ALIAS = {
    ("caballero de la muerte", "profano"): "presencia profana",
    ("paladin", "represion"): "camino de la retribucion",
}
_nsub = 0
for c in kb["classes"]:
    porclase = _SUB.get(_tc.nk(c["name"]))
    if not porclase:
        continue
    for s in c["subclasses"]:
        k = _tc.nk(s["name"])
        clave = _SUB_ALIAS.get((_tc.nk(c["name"]), k))
        clave = clave if clave in porclase else k if k in porclase else next(
            (x for x in porclase if k in x or x in k),
            (_dl.get_close_matches(k, list(porclase), 1, 0.62) or [None])[0])
        if not clave:
            continue
        # el modulo devuelve (nombre, fuente); la ficha espera el mismo objeto que en la
        # lista de clase
        s["spellList"] = [{"level": f["level"],
                           "spells": [{"name": n, "src": fu} for n, fu in f["spells"]]}
                          for f in porclase[clave]]
        _nsub += 1
print("Subclases con lista ampliada: %d" % _nsub)

# ----- ficha para los conjuros que solo eran un nombre en las listas -----
import completar_conjuros_listas as _ccl
# los conjuros creados desde el export tambien son texto de manual: les toca el
# glosario ademas de la limpieza, o entran con "ranura de conjuro" y "puntos de vida"
_nuevas, _nalias, _ = _ccl.aplicar(kb, limpiar=lambda s: limpiar(normalizar_habilidades(s)),
                                   metrico=a_metrico)
print("Conjuros nuevos desde export: %d | alias de traduccion: %d" % (_nuevas, _nalias))

# ----- restos del OCR en el texto importado -----
import arreglar_ocr_kb as _ali
_uni, _formas, _cortes, _mil, _colas, _ctx = _ali.aplicar(kb)
print("Restos de OCR: %d letras iniciales en %d formas, %d guiones de corte, %d millares"
      % (_uni, _formas, _cortes, _mil))
if _colas:
    for _w, _c in _colas.most_common():
        print("   unida por el final: %-14s x%-2d ...%s"
              % (_w, _c, _ctx.get(_w, "").replace("\n", " ")))

# ----- ataque, salvacion y dano leidos de la descripcion -----
# Los conjuros importados de los manuales no traen estos campos, y hay fichas antiguas que
# tampoco. Se leen del texto y SOLO se rellena lo que esta vacio: donde el addon ya dice
# algo, su valor manda, porque suele ser mas preciso ("Constitucion, luego Destreza al
# terminar" frente al primero que aparece en el texto).
import mecanica_desde_texto as _mec
_mk = {"attack": 0, "savingThrow": 0, "damage": 0}
_mdudas = []
for _s in kb["spells"]:
    _a, _sv, _d, _du = _mec.extraer(_s.get("description"))
    for _campo, _valor in (("attack", _a), ("savingThrow", _sv), ("damage", _d)):
        if _valor and not (_s.get(_campo) or "").strip():
            _s[_campo] = _valor
            _mk[_campo] += 1
    for _tipo, _pal in _du:
        _mdudas.append((_s["name"], _tipo, _pal))
print("Mecanica leida del texto: %d ataque, %d salvacion, %d dano"
      % (_mk["attack"], _mk["savingThrow"], _mk["damage"]))

# ----- afinidad, icono y categorias seguras de los conjuros importados -----
import metrica_de_juego as _met
_nmet = _met.aplicar(kb)
print("Medidas unificadas con el redondeo de juego: %d" % _nmet)

import clasificar_conjuros as _cls
_iconos_ok = set(json.load(io.open(os.path.join(SP, "icons_data.json"), encoding="utf-8")))
_ccat, _caf, _cic = _cls.aplicar(kb, _iconos_ok)
print("Conjuros clasificados: %d con categoria, %d con afinidad, %d con icono prestado"
      % (_ccat, _caf, _cic))
if _mdudas:
    print("   palabras que no estan en el catalogo y se dejan sin poner: %d" % len(_mdudas))
    for _n, _tp, _pl in _mdudas[:8]:
        print("      %-28s %-10s %r" % (_n[:27], _tp, _pl))

# ----- edad y alineamiento en cifras, y el matiz de lore de algunas subrazas -----
import edad_alineamiento as _ea
_eap, _easin, _ealore = _ea.aplicar(kb)
print("Subrazas matizadas con lore (no con los libros): %s" % ", ".join(_ealore))
print("Razas con edad y alineamiento en cifras: %d%s"
      % (_eap, (" | sin datos: " + ", ".join(_easin)) if _easin else ""))

# ----- la presentacion de cada raza deja de repetir sus propios rasgos -----
import rasgos_sin_repetir as _rsr
_rq, _rc, _rm, _ravisos = _rsr.aplicar(kb)
print("Rasgos repetidos retirados de la presentacion: %d | conservados: %d | presentaciones de subraza salvadas: %d"
      % (_rq, _rc, _rm))
for _rz, _rt, _na, _nb in _ravisos:
    print("   conservado por si acaso: %s / %s (%d car. frente a %d del rasgo)"
          % (_rz, _rt, _na, _nb))

# ----- los reinos y etnias de una raza salen del texto y pasan a ser tarjetas -----
# El capitulo del Humano cierra con siete reinos (Alterac, Dalaran, Gilneas, Kul Tiras,
# Lordaeron, Ventormenta, Stromgarde), cada uno con su descripcion fisica y su lista de
# nombres. En prosa seguida no se distinguen; como tarjetas se consultan de un vistazo.
# El tramo es el que va del titulo de etnias al bloque de datos, asi que no hay que
# mantener a mano una lista de reinos: si el libro anade uno, entra solo.
# Va DETRAS de rasgos_sin_repetir: por delante se colaba tambien "Rasgos Humanos", que es
# la seccion de rasgos repetidos y no una etnia.
# Ventormenta es `hurlevent`, su nombre en frances, asi que no aparece buscando "stormwind".
ICONO_ETNIA = {
    "alterac": "achievement_zone_alteracmountains_01",
    "dalaran": "inv_legion_faction_kirintor",
    "gilneas": "hd_book2motif_gilneasold",
    "kul tiras": "inv__faction_proudmooreadmiralty",
    "lordaeron": "hd_book2motif_lordaeronlight",
    "ventormenta": "hd_book2motif_hurlevent",
    "stromgarde": "hd_book2motif_stromgarde",
}
_ANCLA_ETNIAS = re.compile(r"(?m)^### .*\betnias\b.*$")
_FIN_ETNIAS = re.compile(r"(?m)^\*\*\*Edad[.:]\*\*\*")
_NOMBRES_DE = re.compile(r"(?m)^\*{0,3}Nombres\b[^:]*:\*{0,3}\s*(.+)$")

_net = 0
for r in kb["races"]:
    texto = r.get("desc") or ""
    anc = _ANCLA_ETNIAS.search(texto)
    if not anc:
        continue
    fin = _FIN_ETNIAS.search(texto)
    corte = fin.start() if fin else len(texto)
    tramo = texto[anc.end():corte]
    primera = tramo.find("\n### ")
    if primera < 0:
        continue
    etnias = []
    for trozo in tramo[primera:].split("\n### "):
        if not trozo.strip():
            continue
        lineas = trozo.split("\n", 1)
        nombre = lineas[0].strip()
        cuerpo = (lineas[1] if len(lineas) > 1 else "").strip()
        nom = _NOMBRES_DE.search(cuerpo)
        etnias.append({
            "id": nk(nombre).replace(" ", "_"),
            "name": nombre,
            "desc": (cuerpo[:nom.start()].strip() if nom else cuerpo),
            "names": nom.group(1).strip() if nom else "",
            "icon": ICONO_ETNIA.get(nk(nombre)),
        })
    if not etnias:
        continue
    r["ethnicities"] = etnias
    # el titulo del libro ("Nombres y etnias humanas") anunciaba las etnias que ya no van
    # debajo, porque ahora son tarjetas: lo que queda en la prosa son los nombres
    r["desc"] = texto[:anc.start()] + "### Nombres" + tramo[:primera].rstrip() + "\n\n" + texto[corte:]
    _net += len(etnias)
    print("Etnias de %s: %s" % (r["name"], ", ".join(e["name"] for e in etnias)))
print("Reinos y etnias convertidos en tarjetas: %d" % _net)

# ----- una variante no se cuenta dos veces -----
# Cinco de las siete ya venian como rasgo ("Variante: Gladiador"). Ahora son tarjeta con su
# propia ilustracion, asi que el rasgo sobra. Va DESPUES del bloque del Manual del Jugador:
# hecho antes, ese bloque volvia a anadir el rasgo y el duplicado reaparecia.
_vdup = 0
for b in kb["backgrounds"]:
    if not b.get("variants"):
        continue
    quedan = []
    for f in b["traits"]:
        if not nk(f["name"]).startswith("variante"):
            quedan.append(f)
            continue
        corto = nk(re.sub(r"^variante\s*:?\s*", "", f["name"], flags=re.I))
        hermana = next((v for v in b["variants"]
                        if nk(v["name"]).startswith(corto) or corto.startswith(nk(v["name"]))), None)
        if hermana is None:
            quedan.append(f)
            continue
        # se conserva el texto mas completo de los dos
        if len(f.get("desc") or "") > len(hermana.get("desc") or ""):
            hermana["desc"] = f["desc"]
        _vdup += 1
    b["traits"] = quedan
print("Variantes que dejan de estar tambien como rasgo: %d" % _vdup)

# ----- texto de variante que el export no trae -----
# El mensaje de "Veterano Harford" en el export es solo el titulo: la imagen va detras y el
# cuerpo no esta, asi que la tarjeta salia con nombre y dibujo y sin una sola linea. Su
# rasgo y sus cuatro tablas SI venian, en el trasfondo padre, y no se repiten aqui.
VARIANTE_DE_LA_CASA = {"mercenario_veterano_harford_veterano_harford": 'Has combatido bajo una bandera que pocos recordarían con honor, pero que tú llevas con orgullo. Fuiste parte de la Compañía Harford, un grupo caótico, desigual y extremadamente ruidoso de mercenarios cuya fama procede más de su terquedad y supervivencia que de su disciplina o precisión militar. Leal no al mando, sino al emblema de la compañía y a sus camaradas, tu vida ha sido un desfile de asedios imposibles, retiradas gloriosas, saqueos improvisados y victorias ganadas por pura testarudez.\n\nQuizá empuñaste una espada junto a desertores, navegaste en una bañera flotante apodada "barco", o luchaste codo con codo con magos descalzos, guerreros sin armadura y gentes extrañas. En Harford no importaba tu raza, pasado o linaje, sino si sabías mantenerte en pie tras una emboscada. Allí aprendiste a sobrevivir más que a guerrear, y a confiar en la fuerza de la costumbre, el ingenio callejero y la suerte de los insensatos.\n\n***Competencias en habilidades.*** Escoge una entre Atletismo, Persuasión, Engaño, Supervivencia y Perspicacia.\n\n***Competencias con armas.*** Armas marciales.\n\n***Competencias con herramientas.*** Un juego y otra herramienta entre herramientas de ladrón, vehículos terrestres o acuáticos o un instrumento musical (cualquier tipo de tambor o flauta popular).\n\n***Equipo.*** Un recuerdo cochambroso de tu tiempo en Harford (un clavo bendito, una petaca vacía, una insignia oxidada...), un juego al que jugabas con tus compañeros de barco o campamento, un tabardo Harford remendado varias veces, y una bolsa con 8 po (2 po se los quedó el capitán al pagaros).',
                       "marinero_pirata": 'Has pasado tu juventud bajo la influencia de un temible pirata; un asesino despiadado que te enseñó a sobrevivir en un mundo de tiburones y salvajes. Te has dado el gusto de hurtar a otros barcos y has enviado a más de un alma a una tumba salada. El miedo y el derramamiento de sangre no te son extraños, pues te has forjado una despreciable reputación en multitud de puertos.\n\nSi decides que tu carrera como marinero ha incluido la piratería, puedes elegir el rasgo Mala Reputación en lugar de Pasaje en un Barco.\n\n***Rasgo: Mala Reputación.*** Allá donde vayas, tu reputación te precede y la gente te teme. Cuando te encuentres en un asentamiento civilizado poco después de cometer delitos menores, como negarte a pagar la comida en una taberna o romper la puerta de una tienda, la mayoría de la gente no se atreverá a informar sobre ti ni sobre tus aliados.'}

_vcasa = 0
for b in kb["backgrounds"]:
    for v in b.get("variants") or []:
        texto = VARIANTE_DE_LA_CASA.get(v.get("id"))
        # manda siempre, no "el mas largo": estas entradas existen porque lo del export
        # falta o esta MAL. La del Pirata continua sin corte con el trasfondo siguiente y
        # acababa hablando de titulos nobiliarios, y ese texto sucio era mas largo que el
        # bueno, asi que con la regla de longitud no entraba nunca.
        if texto and texto != v.get("desc"):
            v["desc"] = texto
            _vcasa += 1
print("Variantes con texto propio de la casa: %d" % _vcasa)

# ---- icono de cada variante, del catalogo del addon ----
# Una variante es un trasfondo contado en corto y tiene su propio dibujo. El catalogo es el
# mismo sitio donde estan los demas iconos: no se le monta una tabla aparte.
ICONO_VARIANTE = {}
import glob as _glob  # no estaba importado en este modulo
_cat_v = _glob.glob(os.path.join(r"C:/Users/marco/Documents/New project/Harford", "**",
                                 "HarfordIconCatalog.lua"), recursive=True)
if _cat_v:
    _tv = io.open(_cat_v[0], encoding="utf-8", errors="replace").read()
    _mv = re.search(r"Catalog\.features\s*=\s*\{(.*?)" + chr(10) + r"\}", _tv, re.S)
    if _mv:
        for _e in re.finditer(r'([a-z0-9_]+)\s*=\s*"([A-Za-z0-9_ ]+)"', _mv.group(1)):
            ICONO_VARIANTE[_e.group(1)] = _e.group(2)
_nvi = 0
for b in kb["backgrounds"]:
    for v in b.get("variants") or []:
        if not v.get("icon") and ICONO_VARIANTE.get(v.get("id")):
            v["icon"] = ICONO_VARIANTE[v["id"]]
            _nvi += 1
print("Variantes con icono: %d" % _nvi)

# ----- el rasgo propio del trasfondo va con su nombre a secas -----
# El manual lo encabeza "Caracteristica: Identidad falsa"; en la ficha esa etiqueta no
# aporta nada. Se quita al final, para que la cojan tambien los trasfondos del Libro 1 y
# los propios, que la traen de su propia fuente.
_ncar = 0
for _b in kb["backgrounds"]:
    for _f in _b.get("traits") or []:
        _n = re.sub(r"^\s*[Cc]aracter[ií]stica:\s*", "", _f.get("name") or "")
        if _n != _f.get("name"):
            _f["name"] = _n
            _ncar += 1
print("Rasgos de trasfondo sin la etiqueta Caracteristica: %d" % _ncar)

json.dump(kb, io.open(os.path.join(SP, "kb_icons.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("Clases: intro + %d/%d rasgos completos" % (cf, ct))

print("Razas: %d intros | rasgos de raza/subraza con texto: %d/%d" % (rf, rtok, rt))
print("Trasfondos: %d Discord + %d por Caracteristica = %d/%d con desc" % (
    bf, cff, sum(1 for b in kb["backgrounds"] if b.get("desc")), len(kb["backgrounds"])))
print("Trasfondos PHB: %d intros + %d rasgos" % (bphb, brasgos))
print("Variantes PHB anadidas: %d" % nvar)
print("Recuadros del libro anexados: %d" % ncajas)
print("Conjuros: %d (pasan sin tocar)" % len(kb.get("spells", [])))
