# -*- coding: utf-8 -*-
"""Limpieza de restos de OCR y de unidades imperiales sueltas.

Lo usan los dos lados: `RuleSource/arreglar_ocr_residual.py` para los textos que ya
estan escritos en el Lua del addon, y `add_full_desc.py` para los que se traen del PDF
de un manual, que llegan con las mismas taras.

  OCR       ele por uno y O por cero dentro de los dados ("ldlO", "ldl2") y en los
            bonificadores ("+l a las tiradas").
  imperial  frases que se quedaron en pies o millas. Las proporciones ("2 pies de
            movimiento por cada pie") se pasan metro a metro para que la regla siga
            diciendo exactamente lo mismo.
"""
import io, os, re, json

_DIG = str.maketrans({"l": "1", "I": "1", "O": "0"})


def _dado(m):
    return "1d" + m.group(1).translate(_DIG)


REGLAS = [
    # dados: "ldlO" -> 1d10, "ldl2" -> 1d12, "l d6" -> 1d6
    (re.compile(r"\b[lI1]\s?d\s?([lIO0-9]{1,2})\b"), _dado),
    # bonificador: "+l a las tiradas" -> "+1"
    (re.compile(r"\+\s?l\b"), "+1"),
    # "hasta l pie" -> el uno perdido
    (re.compile(r"\bl (pie|pies|metro|metros)\b"), r"1 \1"),
    # el OCR partio "perfil" en "G, erfi l"
    (re.compile(r"el\s+G,\s*erfi\s*l\s+de"), "el perfil de"),
    # proporciones que se quedaron a medias al pasar a metrico: se expresan metro a metro
    (re.compile(r"emplear 0,6 metros de movimiento por cada pie que quiera mover"),
     "emplear 2 metros de movimiento por cada metro que quiera moverse"),
    (re.compile(r"emplear 1,2 metros de movimiento por cada pie que quiera moverse"),
     "emplear 4 metros de movimiento por cada metro que quiera moverse"),
    (re.compile(r"un cambio de elevaci[oó]n de 10 o m[aá]s pies"),
     "un cambio de elevación de 3 metros o más"),
    (re.compile(r"una cantidad de pies en l[ií]nea recta"),
     "una cantidad de metros en línea recta"),
    (re.compile(r"de hasta 1 pie c[uú]bico"), "de hasta 0,03 metros cúbicos"),
    (re.compile(r"un c[ií]rculo de media milla de radio"),
     "un círculo de 0,8 kilómetros de radio"),
    (re.compile(r"en un radio de varias millas"), "en un radio de varios kilómetros"),
    # el OCR tambien confunde la S con el cinco dentro del dado ("Sd8" -> 5d8)
    (re.compile(r"\bSd(\d+)\b"), r"5d\1"),
    # palabras que el PDF partio con un espacio dentro
    (re.compile(r"\bsup eriores\b"), "superiores"),
    (re.compile(r"\bestudia ndo\b"), "estudiando"),
    (re.compile(r"\ben millas a la redonda\b"), "en kilómetros a la redonda"),
    (re.compile(r"\bunas pocas millas\b"), "unos pocos kilómetros"),
    # el signo del penalizador se separa del numero al maquetar a dos columnas
    (re.compile(r"\bpenalizador de\s*-\s+(\d)"), r"penalizador de -\1"),
    # Tirador de primera: el OCR lee "+10" como "+19". La dote gemela (Maestro en armas
    # pesadas) escribe bien el mismo par -5/+10, asi que el valor correcto no es dudoso.
    (re.compile(r"(a la tirada de ataque\. Si impactas, puedes sumar )\+19\b"), r"\g<1>+10"),
    # la ele del litro leida como uno ("1 pinta (0,45 1)")
    (re.compile(r"(\d,\d+)\s+1\)"), r"\1 l)"),
    # cero leido como O mayuscula ("reduzcas los puntos de golpe de una criatura a O")
    (re.compile(r"(puntos de golpe[^.]{0,40}?\ba)\s+O\b"), r"\1 0"),
    # la ge leida como "¡j" dentro de la palabra ("desinte¡jrar" -> "desintegrar")
    (re.compile(r"(?<=[a-záéíóúñ])¡j(?=[a-záéíóúñ])"), "g"),
    # un signo de apertura en medio de una palabra siempre es basura de OCR
    (re.compile(r"(?<=[a-záéíóúñ])[¡¿](?=[a-záéíóúñ])"), ""),
    # la I mayuscula leida como signo de exclamacion ("Carisma (! nterpretacion)")
    (re.compile(r"(?<=[(\s])!\s?(?=[a-záéíóúñ]{3,})"), "I"),
    # el libro deja sin cerrar la cursiva del ultimo conjuro de la lista ampliada
    (re.compile(r"(\*maldición elemental)(?!\*)"), r"\1*"),
    # espacio colado antes de la puntuacion ("otros artesanos . Tu papel", "una daga ,")
    # ...tambien cuando detras viene la marca de cursiva o negrita ("superiores .***")
    (re.compile(r"(?<=[a-záéíóúñ0-9\)])\s+([,.;:])(?=[\s*_]|$)"), r"\1"),
]


def _asterisco_suelto(t):
    """Quita la marca de cursiva que se quedo sin pareja dentro de su parrafo.

    Las citas de apertura de varias clases abren la cursiva en el primer parrafo y la
    cierran despues de la atribucion, varios parrafos mas abajo. Ni el renderizador de la
    web ni ninguno por lineas puede cerrar eso, asi que se veia un asterisco suelto
    detras del nombre del autor. Solo se toca el parrafo con UNA marca sin pareja: si hay
    mas de una, el caso no es evidente y se deja como esta para poder revisarlo.
    """
    if "*" not in t: return t
    salida = []
    for parrafo in t.split("\n\n"):
        if parrafo.count("*") and len(re.findall(r"\*+", parrafo)) == 1:
            parrafo = parrafo.replace("*", "")
        salida.append(parrafo)
    return "\n\n".join(salida)


_FIN_FRASE = re.compile(r"[.!?:;)\]\"»*]$")


def sin_cola_de_titulo(t, maximo=40, vueltas=2):
    """Quita del final el titulo de la entrada SIGUIENTE, que el PDF deja pegado.

    En las dotes pasaba en 21 de ellas: "...+10 al dano del conjuro.\\n\\nExperto en Armas
    de Fuego". Un titulo se reconoce porque es corto, empieza en mayuscula y no cierra
    frase; el cuerpo de verdad siempre termina en punto.
    """
    if not t: return t
    for _ in range(vueltas):
        lineas = t.rstrip().split("\n")
        while lineas and not lineas[-1].strip(): lineas.pop()
        if not lineas: break
        ult = lineas[-1].strip()
        if not (0 < len(ult) <= maximo) or _FIN_FRASE.search(ult): break
        if not re.match(r"^[A-ZÁÉÍÓÚÑÜ¡¿]", ult): break
        if ult.startswith(("-", "•", "*", "|", ">")): break
        lineas.pop()
        t = "\n".join(lineas).rstrip()
    return t


# El salto de columna del PDF parte una frase en dos parrafos ("puedes sumar +10 al" /
# "dano del ataque"). Se vuelven a unir solo cuando el corte NO cierra frase y lo que
# sigue empieza en minuscula: asi no se pegan parrafos ni vinetas de verdad.
_PARRAFO_PARTIDO = re.compile(r"([a-záéíóúñ0-9,+)\-])\n{2,}(?=[a-záéíóúñ])")


# Cabecera de pagina incrustada EN MEDIO del texto, no al final: el PDF la mete entre dos
# frases y el OCR la deja irreconocible ("C'\\PJTULO 11 : CO:SJUR05", "**C'APITLW** .
# **CONIUROS**", "C,,"). Se reconoce por la forma: mayusculas y signos sin una sola
# palabra en minusculas, con los restos de "CAPITULO" o "CONJUROS" dentro.
_CABECERA_SUELTA = re.compile(r"(?<=[\s.])\*{0,2}[A-Z]['`´]?[,.:;]{2,}\*{0,2}(?=\s)")
# Tramo candidato a cabecera: una tira larga sin minusculas de verdad. Se comprueba
# despues, porque la forma exacta cambia en cada pagina ("C'\\PJTULO 11 : CO:SJUR05",
# "f \\PITULO b . OPCIOXES DE PERSO!--ALIZACION", "**C'APITLW** . **CONIUROS**").
_PALABRA_REAL = re.compile(r"[a-záéíóúñ]{3,}")
_TITULADA = re.compile(r"^\*{0,3}[A-ZÁÉÍÓÚÑ][a-záéíóúñ]")
# caracter que no aparece dentro de una palabra ni de una abreviatura normal: es lo que
# delata a la cabecera rota. El punto NO cuenta, o "S.R.B." caeria con ella.
# Ni "|" ni "--": en estos stat blocks son separadores de columna legitimos ("1 acción ||
# Uno mismo", "**Desafío** -- **Bonificador**") y quitarlos se llevaba datos por delante.
_RARO = re.compile(r"[\\~^\[\]{}]"                   # nunca aparecen dentro de una palabra
                   r"|[A-Za-z][:;'`´][A-Za-z]"       # ...y estos solo si van EN MEDIO:
                   r"|,,")                           # "5d8;" o "ti;" son puntuacion normal


def _semilla(tok):
    if _PALABRA_REAL.search(tok): return False
    if _RARO.search(tok): return True
    # una exclamacion dentro de un tramo en versales tampoco es normal ("PERSO!--ALIZACION")
    return "!" in tok and sum(c.isalpha() for c in tok) >= 4


def _arrastrable(tok):
    """Token que puede formar parte de la cabecera: ni palabra ni nombre propio."""
    if _PALABRA_REAL.search(tok) or _TITULADA.match(tok): return False
    return True


def _cabecera_incrustada(t):
    """Quita la cabecera de pagina que quedo EN MEDIO del texto.

    Se busca un token imposible (con barra invertida, dos puntos o comas dobles y sin
    ninguna palabra en minusculas) y se extiende a los vecinos que tampoco son palabras.
    Se para en cuanto aparece una palabra de verdad o un nombre propio, asi que "DES +3,
    CON +4" o "S.R.B." no se tocan.
    """
    if not t or not _RARO.search(t): return t
    salida = []
    for linea in t.split("\n"):
        toks = linea.split(" ")
        fuera = [False] * len(toks)
        for i, tok in enumerate(toks):
            if not _semilla(tok): continue
            fuera[i] = True
            for j in range(i - 1, -1, -1):
                if not _arrastrable(toks[j]): break
                fuera[j] = True
            for j in range(i + 1, len(toks)):
                if not _arrastrable(toks[j]): break
                fuera[j] = True
        salida.append(" ".join(tok for k, tok in enumerate(toks) if not fuera[k]))
    t = "\n".join(salida)
    t = _CABECERA_SUELTA.sub("", t)
    return re.sub(r"[ \t]{2,}", " ", t)


# Cabecera de tabla que el PDF parte en varias lineas y que al reunirlas queda pegada
# ("Nivel de" + "ConjuroConjuros" + una fila de guiones). Las filas de debajo se leen
# solas ("1.º *vacio oscuro*, ..."), asi que la cabecera rota sobra.
_CABECERA_TABLA = re.compile(
    r"(?m)^(?:[^\n]{0,30}\n)??[^\n]{0,40}?[a-záéíóúñ][A-ZÁÉÍÓÚÑ][^\n]{0,30}\n-{6,}\n")


def _cabecera_de_tabla_rota(t):
    return _CABECERA_TABLA.sub("", t) if "---" in t else t


_LINEA_LISTA = re.compile(r"(?m)^\s*\d+\.?[ºo]\s*(?=\*)")


def _lista_de_conjuros(t):
    """Cierra las cursivas de las listas ampliadas de conjuros del brujo.

    El libro escribe esas filas con el asterisco de cierre perdido mas de una vez:
    "5.º*llamada infernal *atadura planar*", "1.º*manos ardientes*, *rayo del caos".
    La correccion se limita a las lineas que empiezan por el nivel, para no tocar prosa.
    """
    if "*" not in t: return t
    salida = []
    for linea in t.split("\n"):
        if _LINEA_LISTA.match(linea):
            # un nombre que acaba y otro que empieza sin cerrar ni separar
            linea = re.sub(r"([a-záéíóúñ]) \*", lambda m: m.group(1) + "*, *", linea)
            if linea.count("*") % 2: linea += "*"
        salida.append(linea)
    return "\n".join(salida)


def _parrafos_duplicados(t):
    """Quita el parrafo que aparece dos o mas veces dentro de la MISMA entrada.

    Al Troll le salia tres veces el mismo "Entrenamiento con armas Troll". Se exige que
    sean largos e identicos: los titulos cortos de un stat block ("Acciones") si se
    repiten a proposito.
    """
    if not t or "\n\n" not in t: return t
    vistos, salida = set(), []
    for p in t.split("\n\n"):
        clave = re.sub(r"\s+", " ", p.strip())
        if len(clave) > 60:
            if clave in vistos: continue
            vistos.add(clave)
        salida.append(p)
    return "\n\n".join(salida)


def _cola_basura(t):
    """Quita del final los restos de maquetacion del PDF.

    Son el numero de pagina, la cabecera o el pie, y el OCR los deja irreconocibles:
    " .7", "PARTE 2 | HECHIZOS", "( \\Plfl LO J. t.ONJURO'-". Lo que los delata es que no
    contienen ni una palabra de verdad; el texto real siempre trae alguna.
    """
    if not t: return t
    for _ in range(3):
        partes = t.rstrip().split("\n\n")
        ultima = partes[-1].strip()
        if len(partes) > 1 and len(ultima) < 60 and not re.search(r"[a-záéíóúñ]{4,}", ultima):
            t = "\n\n".join(partes[:-1]).rstrip()
            continue
        break
    # numero de pagina pegado detras del punto final (" ... del conjuro. .7")
    return re.sub(r"(?<=\.)\s+[.,]?\s*\d{1,3}\s*$", "", t)


def _cabeza_de_componente(t):
    """Quita del principio la cola del componente material de la ficha del conjuro.

    Al maquetar a dos columnas, "Componentes: V, S, M (una perla de al menos 100 po y una
    pluma de buho)" se parte, y el trozo final se queda pegado delante de la descripcion:
    "100 po y una pluma de buho)  Elige un objeto...". Se reconoce porque hay un parentesis
    que cierra sin haberse abierto.
    """
    if not t: return t
    cierra = t.find(")")
    abre = t.find("(")
    if cierra == -1 or (abre != -1 and abre < cierra): return t
    cabeza = t[:cierra]
    # el trozo arrastrado es la cola de una enumeracion de componentes: nunca cierra una
    # frase. Si hay un punto seguido de espacio es texto de verdad y no se toca (los
    # separadores de millar, "5.000 po", no cuentan porque llevan digito detras).
    if re.search(r"\.\s", cabeza) or len(cabeza) > 400: return t
    return t[cierra+1:].lstrip(" \t.,;:\n")


def _cargar_partidas():
    """Palabras que el OCR partio con un espacio dentro ("med iante" -> "mediante").

    La lista la deduce `palabras_partidas.py` comparando contra el vocabulario del propio
    compendio y se guarda como dato, para que valga tanto para el Lua del addon como para
    el texto que se trae de los manuales.
    """
    import json, os
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "palabras_partidas.json")
    if not os.path.exists(p): return []
    with open(p, encoding="utf-8") as f:
        d = json.load(f)
    return [(re.compile(r"\b" + re.escape(k) + r"\b"), v) for k, v in d.items()]


PARTIDAS = _cargar_partidas()



# ---------------------------------------------------------------- tildes perdidas
# El markdown de los manuales arrastra su propio OCR y se deja tildes por el camino
# ("caracteristica", "vision", "tamano"). El mapa de tildes.json sale del propio corpus:
# palabra cuya forma acentuada ya domina en los textos y que NO es un homografo (esos van
# en su lista y no se tocan nunca: "como"/"como", "esta"/"esta", "perdida"/"perdida").
# Solo se aplica a PROSA. Los `name` no pasan por aqui: el addon los empareja como cadena.
_TILDES = json.load(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                         "tildes.json"), encoding="utf-8"))["palabras"]
_TILDE_PAT = re.compile(r"(?<![A-Za-zÁÉÍÓÚÜÑáéíóúüñ])(" +
                        "|".join(sorted(_TILDES, key=len, reverse=True)) +
                        r")(?![A-Za-zÁÉÍÓÚÜÑáéíóúüñ])", re.I)


# el OCR del manual acentua un nombre propio que no lleva tilde
_OCR_NOMBRES = ((re.compile(r"Mom[eé]ntum"), "Momentum"),)


# separador decimal: el compendio va en espanol y usa coma. Solo delante de una unidad,
# para no tocar numeros de version ni finales de frase.
_DECIMAL = re.compile(r"(\d)\.(\d{1,2})(?!\d)(?=\s*(?:metros?|m|kil[oó]metros?|km|cent[ií]metros?|cm|litros?|l|kilos?|kg|g)\b)")


# la etiqueta de escalado es siempre "A niveles superiores.": el manual la escribe
# tambien con "En"/"Con" y en Mayusculas De Titulo, y el addon la cerraba con dos puntos.
_ESCALADO = re.compile(r"(?:(?<=^)|(?<=[.>*\n]))([ ]*[*]*[ ]*)(?:En|Con|A) [Nn]iveles [Ss]uperiores[.:,]?", re.M)


def _etiqueta_escalado(t):
    t = _ESCALADO.sub(lambda m: m.group(1) + "A niveles superiores.", t)
    # si la etiqueta cerraba con dos puntos, la frase que sigue empieza en minuscula
    return re.sub(r"(A niveles superiores[.]\s*)([a-záéíóúñ])",
                  lambda m: m.group(1) + m.group(2).upper(), t)


# la sigla de la clase de dificultad va en espanol: CD, no la inglesa DC
_SIGLA_CD = re.compile(r"(?<![A-Za-z])DC(?![A-Za-z])")


# enfasis alrededor de UNA letra dentro de la palabra ("Expiaci***o***n"): no es formato,
# es basura del OCR, que marcaba la vocal acentuada
_ENFASIS_INTERIOR = re.compile(r"([A-Za-zÁÉÍÓÚáéíóúñ])\*{1,3}([A-Za-zÁÉÍÓÚáéíóúñ])\*{1,3}([A-Za-zÁÉÍÓÚáéíóúñ])")


# letra suelta que no es palabra: el OCR parte "su", "en" o "al" por la mitad
# ("surge de ti e n una direccion", "dar a l publico"). Solo se unen los casos donde
# la union ES la palabra: un "s o" por "su" no se une, porque haria falta corregir una letra.
# de una letra, y las letras de apendice van en mayuscula, asi que no se tocan.
_LETRA_SUELTA = re.compile(r"(?<=[a-záéíóúñ]) ([eau]) ([nl])(?= [a-záéíóúñ])")


# El manual cita algunos conjuros por un nombre que no es el de su ficha, asi que el
# lector los buscaba y no los encontraba. Solo se reescribe la cita cuando el conjuro
# EXISTE con otro nombre; los que no existen (Dominar persona, Simbolo) se dejan como
# estan, porque inventarlos seria peor que la cita rota.
_CITAS = {
    "restauracion menor": "Restablecimiento menor",
    "restauración menor": "Restablecimiento menor",
    "habilidad mejorada": "Potenciar característica",
    "persona encantada": "Encantar persona",
    "contraconjuro": "Contrahechizo",
    "conceder maldicion": "Imponer maldición",
    "conceder maldición": "Imponer maldición",
    "quitar maldicion": "Levantar maldición",
    "quitar maldición": "Levantar maldición",
    "sentido de la bestia": "Sentido de bestia",
    "esposar a los no-muertos": "Encadenar no muertos",
    "encadenar no-muertos": "Encadenar no muertos",
}
_CITA = re.compile(r"\*(" + "|".join(re.escape(k) for k in sorted(_CITAS, key=len, reverse=True)) + r")\*", re.I)


def _citas_de_conjuro(t):
    return _CITA.sub(lambda m: "*" + _CITAS[m.group(1).lower()] + "*", t)


# Regla horizontal del markdown suelta entre parrafos: el libro la usa para separar
# secciones, pero la ficha ya las separa con su encabezado y salia el "---" en crudo.
# NO se toca la de las tablas, que va dentro de una fila (|:---:|).
_REGLA_HORIZONTAL = re.compile(r"(?m)^[ \t]*-{3,}[ \t]*$\n?")

# Linea de cabecera que el libro pone al empezar un rasgo ("*Caracteristica de mago de 1er
# nivel*"): la ficha ya muestra la clase y el nivel en su etiqueta, asi que repetirlo en el
# cuerpo sobra. Solo se quita cuando ocupa la linea entera; dentro de una frase
# ("caracteristica de tu eleccion aumenta en 2") no se toca.
_CABECERA_DE_NIVEL = re.compile(
    r"(?im)^[ \t>]*\*{0,3}[ \t]*(?:caracter[ií]stica|rasgo|aptitud)\s+del?\s+"
    r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' ]{3,40}?\s+de\s+"
    r"(?:nivel\s+\d{1,2}|\d{1,2}\s*(?:er|do|to|mo|vo|no)?\s*\.?[ºo°]?\s*nivel)"
    r"[ \t]*\*{0,3}[ \t]*$\n?")

# la misma cabecera cuando el texto ya venia con los saltos de linea colapsados y quedo
# pegada al primer parrafo; solo se quita si abre el campo
_CABECERA_PEGADA = re.compile(
    r"^[ \t>]*\*{0,3}[ \t]*(?:Caracter[ií]stica|Rasgo|Aptitud)\s+del?\s+"
    r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' ]{3,40}?\s+de\s+"
    r"(?:nivel\s+\d{1,2}|\d{1,2}\s*(?:er|do|to|mo|vo|no)?\s*\.?[ºo°]?\s*nivel)"
    r"[ \t]*\*{0,3}[ \t]*(?=[A-ZÁÉÍÓÚÑ¡¿])")


def sin_cabecera_de_nivel(t):
    """Quita esa cabecera y el hueco que deja delante del primer parrafo."""
    return _CABECERA_PEGADA.sub("", _CABECERA_DE_NIVEL.sub("", t or "").lstrip("\n"))


def decimales(t):
    """Coma decimal delante de unidad. El punto de los millares (1.000) no se toca."""
    return _DECIMAL.sub(r"\1,\2", t or "")


def tildes(t):
    """Repone tildes sueltas. Para campos cortos que no pasan por limpiar()."""
    return _reponer_tildes(t or "")


def _reponer_tildes(t):
    t = _DECIMAL.sub(r"\1,\2", t)
    t = _etiqueta_escalado(t)
    t = _SIGLA_CD.sub("CD", t)
    t = _ENFASIS_INTERIOR.sub(r"\1\2\3", t)
    t = _LETRA_SUELTA.sub(r" \1\2", t)
    t = _citas_de_conjuro(t)
    t = _REGLA_HORIZONTAL.sub("", t)
    t = re.sub(r"\n{3,}", "\n\n", t)
    for pat, bien in _OCR_NOMBRES:
        t = pat.sub(bien, t)
    def _una(m):
        w = m.group(1)
        bien = _TILDES[w.lower()]
        return bien[0].upper() + bien[1:] if w[:1].isupper() else bien
    return _TILDE_PAT.sub(_una, t)

def limpiar(t):
    if not t: return t
    t = _cabeza_de_componente(t)
    for pat, rep in PARTIDAS:
        t = pat.sub(rep, t)
    for pat, rep in REGLAS:
        t = pat.sub(rep, t)
    t = _PARRAFO_PARTIDO.sub(r"\1 ", t)
    t = _reponer_tildes(t)
    t = sin_cabecera_de_nivel(t)
    return _parrafos_duplicados(_lista_de_conjuros(_cabecera_de_tabla_rota(_cola_basura(_cabecera_incrustada(_asterisco_suelto(t))))))
