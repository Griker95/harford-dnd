# -*- coding: utf-8 -*-
"""Terminologia canonica compartida por todo el pipeline.

Las equivalencias viven en glosario.json (el diccionario privado del proyecto): ahi se
anade un termino nuevo y todo el compendio se normaliza solo. Cada manual traduce a su
manera ("Manejo de Animales" / "Trato con Animales", "Desengancharse" / "Destrabarse")
y el compendio debe usar SIEMPRE un unico nombre.

La sustitucion es CONSCIENTE DEL CONTEXTO segun el campo `contexto` del glosario:
  habilidad -> solo si se habla de la habilidad (competencia en X, prueba de INT (X))
  accion    -> solo si se habla de la accion (accion de X, realizar X)
  libre     -> sustitucion directa, el termino no es ambiguo
  informativo -> NO se sustituye; esta en el glosario solo para poder comparar
"""
import io, json, os, re

_GLOSARIO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "glosario.json")

def cargar_glosario():
    with io.open(_GLOSARIO, encoding="utf-8") as f:
        return json.load(f)

def _por_contexto(ctx):
    """{canon: [variantes]} de todas las secciones del glosario con ese contexto."""
    out = {}
    for seccion, entradas in cargar_glosario().items():
        if seccion.startswith("_") or not isinstance(entradas, dict): continue
        for canon, datos in entradas.items():
            if canon.startswith("_") or not isinstance(datos, dict): continue
            if datos.get("contexto") != ctx: continue
            vs = [v for v in datos.get("variantes", []) if v and v != canon]
            if vs: out[canon] = vs
    return out

SKILL_VARIANTS = _por_contexto("habilidad")

CARACS = r"(?:Fuerza|Destreza|Constituci[oó]n|Inteligencia|Sabidur[ií]a|Carisma)"

def _contextos(variante):
    """Formas en las que un nombre suelto SI es una referencia a la habilidad."""
    v = re.escape(variante)
    return [
        # "prueba de Inteligencia (Arcanos)"
        (re.compile(r"(\(\s*)" + v + r"(\s*\))"), r"\1{C}\2"),
        # "competencia en (la habilidad de) Arcano" / "competencia con Arcano"
        (re.compile(r"((?:competencia|competente)\s+(?:en|con)\s+(?:la\s+habilidad\s+de\s+)?(?:de\s+)?)" + v + r"\b", re.I), r"\1{C}"),
        # "habilidad de Arcanos"
        (re.compile(r"(habilidad(?:es)?\s+de\s+)" + v + r"\b", re.I), r"\1{C}"),
        # dentro de una lista de habilidades: "a tu eleccion: Manejo de Animales, Naturaleza"
        (re.compile(r"(habilidades[^.:\n]{0,40}:\s*(?:[A-ZÁÉÍÓÚÑ][^,\n]{2,24},\s*){0,5})" + v + r"\b"), r"\1{C}"),
        # "prueba de Sabiduria (Manejo de Animales)" ya cubierto; y "Sabiduria (X)"
        (re.compile(r"(" + CARACS + r"\s*\(\s*)" + v + r"(\s*\))"), r"\1{C}\2"),
        # primera de una lista de eleccion: "Elige dos entre Trato con animales, Arcanos".
        # La regla de lista de abajo pide coma delante, asi que se saltaba justo esta.
        (re.compile(r"((?:[Ee]lige|[Ee]scoge|[Ee]legir|[Ee]scoger)\s+\w+\s+(?:entre|de)\s+)"
                    + v + r"\b"), r"\1{C}"),
        # lista separada por comas justo detras de otra habilidad canonica conocida
        (re.compile(r"(,\s*)" + v + r"(\s*(?:,|\sy\s|\.))"), r"\1{C}\2"),
        # encadenada con coma/o/y tras otra habilidad:
        #   "competentes en Naturaleza o Arcano", "competencia en Sigilo, Naturaleza y Manejo de Animales"
        (re.compile(r"((?:competen\w*|habilidad\w*)\s+(?:en|con)\s+"
                    r"(?:[A-Z\u00c1\u00c9\u00cd\u00d3\u00da\u00d1][\w\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1]{2,}"
                    r"(?:\s+de\s+[A-Za-z\u00e1\u00e9\u00ed\u00f3\u00fa\u00f1]+)?(?:\s*,\s*|\s+o\s+|\s+y\s+)){1,4})" + v + r"\b", re.I),
         r"\1{C}"),
    ]

def normalizar_habilidades(texto):
    """Reescribe habilidades y terminos de regla al nombre canonico, solo en contexto."""
    if not texto: return texto
    texto = normalizar_reglas(texto)
    for canon, variantes in SKILL_VARIANTS.items():
        # de mas larga a mas corta, para que "Conocimiento arcano" gane a "Arcano"
        for v in sorted(variantes, key=len, reverse=True):
            if v == canon: continue
            for pat, rep in _contextos(v):
                texto = pat.sub(rep.replace("{C}", canon.replace("\\", "\\\\")), texto)
    return texto


# ---------------------------------------------------------------------------
# TERMINOS DE REGLA
# ---------------------------------------------------------------------------
# Para las reglas generales de 5e la referencia es el Manual del Jugador (CLAUDE.md).
# Las acciones solo se sustituyen en contexto de accion, para no tocar el verbo comun
# ("retirarse del combate" narrativo o "carrera" como profesion).
ACCION_CTX = (r"(acci[oó]n(?:es)?\s+(?:de\s+|adicional\s+de\s+)?|realizar\s+(?:la\s+acci[oó]n\s+de\s+)?"
              r"|tomar\s+la\s+acci[oó]n\s+de\s+|usa(?:r|s)?\s+la\s+acci[oó]n\s+de\s+|,\s*|\so\s|\su\s|\sy\s)")
ACCIONES = _por_contexto('accion')
# terminos que no son acciones: sustitucion directa, sin ambiguedad posible
DIRECTOS = []
for _canon, _vs in _por_contexto("libre").items():
    if "espacio de conjuro" in _canon: continue      # lo trata _RANURA, que concuerda genero
    for _v in sorted(_vs, key=len, reverse=True):
        _pat = r"\b" + re.escape(_v) + r"\b"
        # una sigla en versales ("PV") se desarrolla en prosa, pero NO cuando es notacion
        # de ficha: "PV: 48/48" es una cabecera compacta y "PV: puntos de golpe: 48/48"
        # seria absurdo
        if _v.isupper() and len(_v) <= 4:
            _pat += r"(?!\s*[:/]|\s*\d)"
        DIRECTOS.append((_pat, _canon))

# "ranura de conjuro" es femenino y "espacio de conjuro" masculino: al sustituir hay que
# conservar el numero y concordar lo que la rodea.
_FEM_ANTES = {"una": "un", "la": "el", "las": "los", "unas": "unos", "esa": "ese", "esas": "esos",
              "esta": "este", "estas": "estos", "todas": "todos", "cuantas": "cuantos",
              "cuántas": "cuántos", "otras": "otros", "otra": "otro", "algunas": "algunos",
              "alguna": "alguno", "dichas": "dichos", "dicha": "dicho", "ningunas": "ningunos",
              "ninguna": "ningun", "mismas": "mismos", "misma": "mismo", "varias": "varios"}
_FEM_DESPUES = {"gastadas": "gastados", "gastada": "gastado", "usadas": "usados", "usada": "usado",
                "disponibles": "disponibles", "adicionales": "adicionales", "restantes": "restantes",
                "recuperadas": "recuperados", "no gastadas": "no gastados", "vacias": "vacios",
                "altas": "altos", "alta": "alto", "bajas": "bajos", "baja": "bajo"}
_RANURA = re.compile(r"(?:\b((?:[A-Za-zÁÉÍÓÚÑáéíóúñ]+\s+){1,2}))?\b(ranuras?)\s+del?\s+"
                     r"([Cc]onjuros?|[Hh]echizos?)"
                     r"(?:\s+([a-záéíóúñ]+))?", re.I)
# "ranura" a secas tambien es el espacio de conjuro: el Libro 1 la usa sin nombrarlo
# ("nivel de ranura", "ranuras de Hechiceria Vil"). En todo el compendio no hay ni una
# sola ranura en el sentido de hendidura, asi que la sustitucion es segura.
_RANURA_SOLA = re.compile(r"(?:\b((?:[A-Za-zÁÉÍÓÚÑáéíóúñ]+\s+){1,2}))?\b([Rr]anuras?)\b")
# tras el cambio, el adjetivo que va detras puede quedar en femenino
_CONCORDAR_TRAS = re.compile(r"\b(espacios) de ([A-Za-zÁÉÍÓÚÑáéíóúñ]+(?: [A-Za-zÁÉÍÓÚÑáéíóúñ]+)?) "
                             r"(gastadas|usadas|restantes|disponibles|recuperadas)\b")
# "una ranura de 1er nivel" no nombra el conjuro: se le pone para que la regla de arriba
# lo trate igual que al resto y concuerde el determinante.
_RANURA_NIVEL = re.compile(r"\b(ranuras?)\s+de\s+(?=\d)", re.I)
def _sustituir_ranura(m):
    det, ranura, _, adj = m.group(1), m.group(2), m.group(3), m.group(4)
    plural = ranura.lower().endswith("s")
    nucleo = ("espacios" if plural else "espacio")
    if ranura[0].isupper(): nucleo = nucleo.capitalize()
    partes = []
    if det is not None:
        palabras = []
        for w in det.split():
            nw = _FEM_ANTES.get(w.lower(), w)
            if w[0].isupper(): nw = nw.capitalize()
            palabras.append(nw)
        partes.append(" ".join(palabras))
    partes.append(nucleo + " de conjuro")
    if adj is not None:
        partes.append(_FEM_DESPUES.get(adj.lower(), adj))
    return " ".join(partes)

def _sustituir_ranura_sola(m):
    """Como `_sustituir_ranura` pero sin el "de conjuro": aqui el texto ya nombra a que
    pertenece el espacio ("de Hechiceria Vil") o no lo nombra en absoluto."""
    det, ranura = m.group(1), m.group(2)
    nucleo = "espacios" if ranura.lower().endswith("s") else "espacio"
    if ranura[0].isupper(): nucleo = nucleo.capitalize()
    if det is None: return nucleo
    palabras = []
    for w in det.split():
        nw = _FEM_ANTES.get(w.lower(), w)
        if w[0].isupper(): nw = nw.capitalize()
        palabras.append(nw)
    return " ".join(palabras) + " " + nucleo



# ---------------------------------------------------------------------------
# BONO DE COMPETENCIA Y MODIFICADOR DE CARACTERISTICA
# ---------------------------------------------------------------------------
# La ficha del juego los escribe cortos ("8 + Bonus Competencia + Mod. Sabiduria") y el
# texto los traia de catorce formas distintas ("tu bonificador de competencia", "tu
# bonificador por competencia", "Bonificador de competencia", "Mod Constitucion"...).
# Se unifican a la forma de la ficha, articulo incluido: el nombre funciona como etiqueta.
_CARACS = "Fuerza|Destreza|Constituci[oó]n|Inteligencia|Sabidur[ií]a|Carisma"
_CAP = {"constitucion": "Constitución", "inteligencia": "Inteligencia",
        "sabiduria": "Sabiduría", "fuerza": "Fuerza", "destreza": "Destreza",
        "carisma": "Carisma"}
_BONO_COMP = re.compile(
    r"(?:(?:tu|su|el|la|un|una)\s+)?(?:bonificador|bono|bonus|modificador)\s+(?:de|por)\s+competencia", re.I)
_MOD_CARAC = re.compile(
    r"(?:(?:tu|su|el|la|un|una)\s+)?(?:modificador|mod\.?)\s+(?:de|por)\s+(" + _CARACS + r")", re.I)
# la forma corta ya escrita, pero sin punto o sin mayuscula
_MOD_CORTO = re.compile(r"(?:(?:tu|su|el|la)\s+)?\bMod\.?\s+(" + _CARACS + r")", re.I)
_BONO_CORTO = re.compile(r"\bBonus\s+competencia\b")


def _cap_carac(w):
    import unicodedata
    k = "".join(c for c in unicodedata.normalize("NFD", w) if unicodedata.category(c) != "Mn").lower()
    return _CAP.get(k, w)



# El descanso tiene un nombre y solo uno: la ficha del juego dice "Descanso corto" y
# "Descanso largo", y el texto traia ademas "prolongado" y "breve" para lo mismo.
_DESCANSO = ((re.compile(r"(descansos?)\s+prolongados?", re.I), "largo"),
             (re.compile(r"(descansos?)\s+breves?", re.I), "corto"))
# la forma coordinada ("un descanso breve o prolongado"): sin esto la regla de arriba
# arregla solo la primera mitad y deja "corto o prolongado"
_DESCANSO_PAR = re.compile(r"(descansos?)\s+(?:breves?|cortos?)\s+o\s+(?:prolongados?|largos?)", re.I)


def normalizar_descanso(texto):
    if not texto:
        return texto
    texto = _DESCANSO_PAR.sub(lambda m: m.group(1) + " corto o largo", texto)
    for pat, bien in _DESCANSO:
        texto = pat.sub(lambda m: m.group(1) + " " + (bien + "s" if m.group(1).lower().endswith("s") else bien), texto)
    return texto

def normalizar_bonos(texto):
    if not texto:
        return texto
    texto = _BONO_COMP.sub("Bonus Competencia", texto)
    texto = _MOD_CARAC.sub(lambda m: "Mod. " + _cap_carac(m.group(1)), texto)
    texto = _MOD_CORTO.sub(lambda m: "Mod. " + _cap_carac(m.group(1)), texto)
    texto = _BONO_CORTO.sub("Bonus Competencia", texto)
    return texto

def normalizar_reglas(texto):
    """Unifica el nombre de las acciones y de los terminos de regla."""
    if not texto: return texto
    texto = normalizar_bonos(texto)
    texto = normalizar_descanso(texto)
    for canon, variantes in ACCIONES.items():
        for v in variantes:
            texto = re.sub("(" + ACCION_CTX + ")" + v + r"\b",
                           lambda m: m.group(1) + canon, texto, flags=re.I)
    texto = _RANURA_NIVEL.sub(lambda m: m.group(1) + " de conjuro de ", texto)
    texto = _RANURA.sub(_sustituir_ranura, texto)
    texto = _RANURA_SOLA.sub(_sustituir_ranura_sola, texto)
    texto = _CONCORDAR_TRAS.sub(
        lambda m: "%s de %s %s" % (m.group(1), m.group(2),
                                   _FEM_DESPUES.get(m.group(3), m.group(3))), texto)
    # el idioma del manual es "nivel de espacio de conjuro por encima de N"
    texto = re.sub(r"\bnivel de (espacios?)\b(?! de conjuro)", r"nivel de \1 de conjuro", texto)
    for pat, rep in DIRECTOS:
        # conserva la mayuscula inicial de la palabra sustituida
        texto = re.sub(pat, lambda m, r=rep: (r[0].upper() + r[1:]) if m.group(0)[:1].isupper() else r,
                       texto, flags=re.I)
    # "espacio de conjuro de 2 nivel o superior" en plural cuando toca
    texto = re.sub(r"\b(\d+|varios|dos|tres)\s+espacio de conjuro\b", r"\1 espacios de conjuro", texto)
    # al traducir el termino ingles entre parentesis queda repetido:
    # "Mejora de Caracteristica (*Mejora de Caracteristica*)" -> se quita la glosa
    texto = re.sub(r"([A-Za-zÁÉÍÓÚÑáéíóúñ][\w áÁéÉíÍóÓúÚñÑ]{3,40}?)\s*\(\*?\1\*?\)",
                   r"\1", texto, flags=re.I)
    return _concordar(texto)

# La sustitucion puede dejar el articulo o la conjuncion en femenino de la palabra vieja
# ("una ranura" -> "una espacio") o una "u" ante palabra que ya no empieza por o-
# ("u Ocultarse" -> "u Esconderse").
_ART = {"una": "un", "la": "el", "esa": "ese", "esta": "este", "dicha": "dicho",
        "alguna": "algun", "otra": "otro", "ninguna": "ningun", "cada": "cada",
        "unas": "unos", "las": "los", "esas": "esos", "estas": "estos", "otras": "otros"}
def _concordar(texto):
    def art(m):
        a = m.group(1)
        rep = _ART.get(a.lower(), a)
        if a[0].isupper(): rep = rep.capitalize()
        return rep + m.group(2)
    # "una de esas ranuras" -> el determinante suelto queda descolgado del cambio de genero
    texto = re.sub(r"\b([Uu])na (de (?:esos|los|estos|dichos|aquellos|sus|tus|mis)\b)",
                   lambda m: m.group(1) + "no " + m.group(2), texto)
    # conjuncion o/u segun la palabra que la sigue
    texto = re.sub(r"\bu\s+(?![OoHh][^\W\d_])", "o ", texto)
    texto = re.sub(r"\bo\s+(?=[Oo][^\W\d_]|[Hh]o)", "u ", texto)
    return texto

if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    pruebas = [
        "Obtienes competencia en Arcano si no la tienes.",
        "haz una prueba de Inteligencia (Arcanos) contra tu CD",
        "competencia en la habilidad de Arcanos si no la tienes",
        "dos de las siguientes habilidades a tu elección: Manejo de Animales, Naturaleza, Sigilo",
        "- Competencia en de Manejo de Animales. Si ya eres competente",
        "***Conocimiento arcano.*** Competencia en Conocimiento arcano.",
        "realizar Destrabarse, Esquivar u Ocultarse como accion adicional",   # NO se toca
        "a través de una de las tres áreas: Arcano, Fuego o Escarcha",        # NO se toca
        "*Rasgo de Estudio del Arcano de nivel 2*",                            # NO se toca
    ]
    for p in pruebas:
        r = normalizar_habilidades(p)
        print(("   OK " if r == p else " CAMB ") + repr(r[:95]))
