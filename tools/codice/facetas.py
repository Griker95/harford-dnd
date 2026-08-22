# -*- coding: utf-8 -*-
"""Normaliza las facetas cortas del conjuro (duracion, tiempo, escuela, salvacion).

Son vocabularios cerrados y alimentan los filtros del compendio, asi que una misma cosa
escrita de dos maneras sale dos veces en el filtro. Aqui se juntan tres arreglos:

  acentos   los datos del addon van sin tildes ("Concentracion", "accion", "dano") y los
            de los manuales con ellas: el filtro mostraba "Instantanea" y "Instantáneo"
            como dos duraciones distintas.
  genero    la duracion es femenina: "Instantánea" (no "Instantáneo").
  arrastre  al extraer del PDF, el componente material se colaba dentro de la duracion
            ("Hasta que sea disipado de jade con un valor de, al menos, 1.000 po").

Es normalizacion de PRESENTACION para la web: no toca el Lua del addon, donde estos
mismos textos podrian estar comparados como cadena.
"""
import re

# palabras de vocabulario cerrado que el addon guarda sin tilde
_TILDES = {
    "Concentracion": "Concentración", "concentracion": "concentración",
    "accion": "acción", "Accion": "Acción",
    "reaccion": "reacción", "Reaccion": "Reacción",
    "dano": "daño", "Dano": "Daño",
    "Instantaneo": "Instantánea", "Instantanea": "Instantánea",
    "Instantáneo": "Instantánea",
    "Evocacion": "Evocación", "Transmutacion": "Transmutación",
    "Conjuracion": "Conjuración", "Abjuracion": "Abjuración",
    "Adivinacion": "Adivinación", "Ilusion": "Ilusión",
    "Constitucion": "Constitución", "Sabiduria": "Sabiduría",
    "Percepcion": "Percepción", "magico": "mágico", "magica": "mágica",
    "elemental": "elemental", "asalto": "asalto",
    # tipos de dano: el addon los guarda sin tilde porque los compara como cadena, pero
    # en la ficha se leen ("1d6 frio"). La web reconoce las dos formas para el color, asi
    # que acentuarlos al mostrar no cambia nada del resaltado.
    "frio": "frío", "Frio": "Frío", "acido": "ácido", "Acido": "Ácido",
    "necrotico": "necrótico", "Necrotico": "Necrótico",
    "psiquico": "psíquico", "Psiquico": "Psíquico",
    "relampago": "relámpago", "Relampago": "Relámpago",
    "vision": "visión", "Vision": "Visión",
    "proteccion": "protección", "Proteccion": "Protección",
    "curacion": "curación", "Curacion": "Curación",
}
_RE_TILDES = re.compile(r"\b(" + "|".join(sorted(_TILDES, key=len, reverse=True)) + r")\b")

# duraciones validas; lo que sobre detras es arrastre del componente material
# el plural va primero: la alternancia regex para en la primera que encaja
_UNIDAD = r"(?:asaltos|asalto|rondas|ronda|minutos|minuto|horas|hora|d[ií]as|d[ií]a|a[nñ]os|a[nñ]o)"
_DURACION_OK = re.compile(
    r"^(?:Instant[áa]nea(?:\s+o\s+\d+\s+" + _UNIDAD + r")?"
    r"|Permanente|Especial"
    r"|Hasta que sea disipad[ao](?:\s+o\s+activad[ao])?"
    r"|(?:Concentraci[óo]n,\s+)?[Hh]asta\s+\d+\s+" + _UNIDAD +
    r"|\d+\s+" + _UNIDAD + r")", re.I)


def _tildar(t):
    return _RE_TILDES.sub(lambda m: _TILDES[m.group(1)], t)


def duracion(v):
    if not v:
        return v
    v = v.strip().rstrip(".")
    v = v.replace("Concentración.", "Concentración,").replace("Concentracion.", "Concentracion,")
    v = re.sub(r"\bHasta l\b", "Hasta 1", v)          # OCR: ele por uno
    v = re.sub(r"^\d+\s+[Nn]stant", "Instant", v)     # OCR: "1 nstantáneo"
    v = _tildar(v)
    m = _DURACION_OK.match(v)
    if m:
        # el resto es el componente material que se colo al extraer la ficha del PDF
        return m.group(0)[0].upper() + m.group(0)[1:]
    return v


def texto_corto(v):
    # ademas del mapa propio, el mapa compartido: los campos cortos no pasan por limpiar()
    # y arrastraban cosas como "caeis" en el tiempo de lanzamiento
    from limpieza import tildes as _tildes_comunes
    return _tildes_comunes(_tildar(v.strip())) if v else v


CAMPOS_CORTOS = ("castingTime", "school", "range", "components", "savingThrow", "attack",
                 "affinity", "damage")


_ABILIDAD = re.compile(r"salvaci[oó]n\s+de\s+([A-Za-zÁÉÍÓÚáéíóú]+)", re.I)
# alguien tiene que HACER la salvacion: distingue "debe superar una tirada de salvacion"
# de "obtienes un bonificador a las tiradas de salvacion", que no es una salvacion contra
# el conjuro sino un efecto sobre ellas
_PIDE_SALVACION = re.compile(
    r"(?:debe|deben|deber[áa]|deber[áa]n|hace|hacen|haga|hagan|realiza|realizan|realice|"
    r"supera|supere|superan|superar|falla|falle|fallan|tener [ée]xito|"
    r"tenga [ée]xito|tengan [ée]xito)[^.]{0,45}(?:tirada de )?salvaci[oó]n", re.I)
# ...pero no cuando el conjuro solo SUMA a las salvaciones ajenas (Bendicion, Resistencia)
_SALVACION_BONUS = re.compile(
    r"(?:a[ñn]adir|sumar|a[ñn]ade|suma|bonificador|penalizador|ventaja|desventaja)"
    r"[^.]{0,60}tirada de salvaci[oó]n"
    r"|tirada de ataque o una tirada de salvaci[oó]n", re.I)


def pide_salvacion(texto):
    """El conjuro obliga a alguien a hacer una salvacion CONTRA el.

    La exclusion se mira coincidencia a coincidencia, no en todo el texto: un conjuro
    puede pedir una salvacion en un parrafo y hablar de bonificadores a las salvaciones en
    otro. Descartarlo entero por eso dejaba sin fila de Salvacion a conjuros que si la
    tienen, como Hacer anicos o Dominar bestia.
    """
    if not texto: return False
    for m in _PIDE_SALVACION.finditer(texto):
        ventana = texto[max(0, m.start() - 70):m.end() + 10]
        if not _SALVACION_BONUS.search(ventana): return True
    return False
_CANON_ABIL = {"fuerza": "Fuerza", "destreza": "Destreza", "constitucion": "Constitución",
               "inteligencia": "Inteligencia", "sabiduria": "Sabiduría", "carisma": "Carisma"}


def _sin_tilde(s):
    import unicodedata
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def sincronizar_salvacion(sp):
    """`attack` y `savingThrow` dicen lo mismo y estaban descoordinados.

    La ficha muestra las dos filas: 21 conjuros nombraban la salvacion solo en `attack`
    ("Contra salvacion 1d8 radiante", "Salvacion de Destreza") y dejaban vacia la fila
    de Salvacion, y otros 22 al reves. Se rellena la que falte a partir de la otra; nunca
    se sobrescribe un valor ya puesto.
    """
    atq = (sp.get("attack") or "").strip("— ")
    salv = (sp.get("savingThrow") or "").strip("— ")
    if not salv and atq:
        m = _ABILIDAD.search(atq)
        # "Contra salvacion 1d8 radiante" no dice de que: la caracteristica esta en el
        # cuerpo del conjuro ("una tirada de salvacion de Destreza")
        if not m and "salvaci" in _sin_tilde(atq):
            m = _ABILIDAD.search(sp.get("description") or "")
        if m:
            sp["savingThrow"] = _CANON_ABIL.get(_sin_tilde(m.group(1)), m.group(1).capitalize())
    elif not salv and not atq:
        # ni un campo ni el otro, pero el cuerpo si la pide: 42 conjuros mostraban la
        # ficha sin fila de Salvacion aunque el texto dijera que hay que superarla
        d = sp.get("description") or ""
        if pide_salvacion(d):
            m = _ABILIDAD.search(d)
            if m:
                sp["savingThrow"] = _CANON_ABIL.get(_sin_tilde(m.group(1)), m.group(1).capitalize())
    elif salv and atq and "salvaci" not in _sin_tilde(atq):
        sp["attack"] = ("%s | Salvación de %s" % (atq, salv)).strip(" |")
    return sp


# "Personal" y "Uno mismo" son la misma etiqueta de alcance (Self) y partian el filtro en
# dos. Se unifica en "Personal", que es la forma del manual en castellano.
_FORMAS = ("cono", "cubo", "esfera", "cilindro", "l[ií]nea", "radio", "cuadrado")
_RE_FORMA = re.compile(r"\((" + "|".join(_FORMAS) + r")\b", re.I)


def alcance(v):
    if not v:
        return v
    v = re.sub(r"^\s*Uno mismo\b", "Personal", v.strip(), flags=re.I)
    # la forma del area va en minuscula dentro del parentesis: "Personal (cono de 9 metros)"
    v = _RE_FORMA.sub(lambda m: "(" + _tildar(m.group(1)).lower(), v)
    return v.replace("(linea", "(línea").replace("(Linea", "(línea")


def normalizar_conjuro(sp):
    sincronizar_salvacion(sp)
    # el separador decimal en castellano es la coma, y el cuerpo del conjuro ya la usa
    for _k in ("range", "damage", "duration"):
        if sp.get(_k):
            sp[_k] = re.sub(r"(?<=\d)\.(?=\d)", ",", sp[_k])
    if sp.get("duration"):
        sp["duration"] = duracion(sp["duration"])
    if sp.get("range"):
        sp["range"] = alcance(sp["range"])
    for k in CAMPOS_CORTOS:
        if sp.get(k):
            sp[k] = texto_corto(sp[k])
    return sp


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    for p in ["Instantanea", "Instantáneo", "Concentracion, hasta 1 minuto",
              "Concentración. hasta 1 minuto", "Hasta l hora",
              "1 nstantáneo carne y una pizca de polvo de hueso)",
              "Hasta que sea disipado de jade con un valor de, al menos, 1.000 po",
              "Hasta que sea disipado que es consumido como parte del lanzamiento",
              "Instantanea o 1 hora", "8 horas", "10 días"]:
        print("%-52s -> %s" % (p[:51], duracion(p)))
