# -*- coding: utf-8 -*-
"""Descripciones del capitulo 5 del Manual del Jugador (armaduras, equipo de aventuras,
herramientas, monturas y vehiculos), extraidas del texto por columnas.

Expone cargar() -> dict nk(nombre) -> texto limpio (aun en pies/libras: el consumidor
aplica metrico). Cada entrada del libro es un parrafo "Nombre. Texto..."."""
import io, os, re, collections, unicodedata

PHB = r"C:/Users/marco/Documents/New project/RuleSource/Export/d_d_5_0_edge_manual_del_jugador/texto.md"

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
def nk(s): return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", sa(s or "").lower())).strip()

def _unir_factory(src):
    """Re-une palabras partidas por el corte de columna usando el vocabulario del libro."""
    VOCAB = collections.Counter(re.findall(r"[a-záéíóúüñ]{2,}", src.lower()))
    SINGLE = {"a", "o", "y", "e", "u"}
    def unir(t):
        for _ in range(2):
            toks = re.split(r"(\s+)", t); out = []; i = 0; ch = False
            while i < len(toks):
                w = toks[i]
                if re.fullmatch(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+", w or "") and i + 2 < len(toks):
                    n = toks[i+2]
                    if re.fullmatch(r"[a-záéíóúüñ]+", n or "") and w.lower() not in SINGLE and n.lower() not in SINGLE:
                        a, b = w.lower(), n.lower(); j = a + b
                        fa, fb, fj = VOCAB[a], VOCAB[b], VOCAB[j]
                        if fj >= 5 and (min(fa, fb) < 25 or fj > min(fa, fb) * 3) and fj > min(fa, fb):
                            out.append(w + n); i += 3; ch = True; continue
                out.append(w); i += 1
            t = "".join(out)
            if not ch: break
        return t

    return unir

# cabeceras de pagina del capitulo coladas en el texto
CABS = [
    re.compile(r"\s*[Cc(]?[AÁ]?P[IÍT1'~L.,:JU ]{1,8}[OU0]\s*5?\s*[:.]?\s*E[OQ0]?U?[Il]?P[O0]\s*\d{0,3}"),
    re.compile(r"<!--[^>]*-->"),
]

def _limpiar(t, unir):
    for p in CABS: t = p.sub(" ", t)
    t = re.sub(r"(\w)-\s+(\w)", r"\1\2", t)          # guion de silaba
    t = re.sub(r"\bl(?=d\d)", "1", t)                 # ld8 -> 1d8
    t = re.sub(r"(\dd)[lI](\d)", r"\g<1>1\g<2>", t)   # 2dl0 -> 2d10
    t = unir(t)
    t = re.sub(r"(\w)-[ \t]+(\w)", r"\1\2", t)
    t = re.sub(r"\b[1lI] ?O\b", "10", t)              # OCR: "1 O antorchas" -> "10"
    t = t.replace("bonificaclor", "bonificador")
    return re.sub(r"\s{2,}", " ", t).strip()

def _es_tabla(p):
    """Los bloques de tabla aplanada tienen muchos precios/pesos; no son descripciones."""
    return len(re.findall(r"\b(?:po|pp|pe|pc|lb)\b", p)) >= 5 or p.count("|") >= 3

def cargar():
    src = io.open(PHB, encoding="utf-8").read()
    ini = src.find("### ARMADURAS LIGERAS")
    fin = src.find("MULTICLASE", 600000)
    if ini == -1 or fin == -1: return {}
    seg = src[max(0, ini - 3000):fin]
    unir = _unir_factory(src)
    paras = [p.strip() for p in re.split(r"\n{2,}", seg) if p.strip()]
    out = {}
    ultimo = None
    for p in paras:
        p1 = re.sub(r"^#{1,6}\s*", "", p).replace("\n", " ").strip()
        # el marcador de pagina no interrumpe la entrada: si la corta, la continuacion que
        # viene justo detras (al principio de la pagina siguiente) se pierde
        if p1.startswith("<!--"): continue
        if not p1 or _es_tabla(p1): ultimo = None; continue
        m = re.match(r"^([A-ZÁÉÍÓÚÑ][^.:\n]{2,55}?)\s*[.:]\s+(\S.*)$", p1)
        # el nombre de la entrada tiene pocas palabras y no es una frase
        if m and len(m.group(1).split()) <= 6 and not re.search(r"\b(?:el|la|los|las|un|una|de el)\b [a-z]", m.group(1).lower()):
            nombre, cuerpo = m.group(1), m.group(2)
            k = nk(nombre)
            if k and k not in out:
                out[k] = _limpiar(cuerpo, unir)
                ultimo = k
                continue
        # continuacion corta de la entrada anterior (parrafo partido por columna/pagina)
        # si la entrada anterior se quedo a medias (acaba sin cerrar frase, o partida por
        # un guion: "se uti-"), la continuacion vale aunque sea larga; el tope de 260 solo
        # se aplica cuando la entrada ya estaba completa
        _abierta = ultimo and not re.search(r"[.!?)\"»]$", out.get(ultimo, "").strip())
        # si la palabra quedo partida por el guion, la continuacion sigue aunque empiece
        # por cifra: el OCR lee la ele inicial como un uno ("se uti-" + "1 izan")
        if ultimo and out[ultimo].rstrip().endswith("-"):
            out[ultimo] = re.sub(r"-\s*$", "", out[ultimo].rstrip()) + \
                re.sub(r"^1\s*(?=[a-záéíóúñ])", "l", p1)
            continue
        if ultimo and p1[0].islower() and (len(p1) < 260 or _abierta):
            out[ultimo] = (out[ultimo] + " " + _limpiar(p1, unir)).strip()
        ultimo = None
    # el guion partido puede quedar AL UNIR una entrada con su continuacion
    for k in out: out[k] = re.sub(r"(\w)-[ \t]+(\w)", r"\1\2", out[k])
    for k, resto in CONTINUACIONES.items():
        if k in out and not re.search(r"[.!?)\"»]$", out[k].strip()):
            out[k] = (out[k].rstrip() + " " + resto).strip()
    return out


# El PDF reordena las columnas y hay entradas cuya continuacion no cae en el parrafo
# siguiente, sino paginas mas adelante, asi que el enganche automatico no la ve. El aceite
# se cortaba en "haz un ataque a" y el resto estaba tres paginas despues (pag. 153).
CONTINUACIONES = {
    "aceite": (
        "distancia contra la criatura o el objeto, tratando el aceite como un arma "
        "improvisada: si tienes éxito, quedará cubierto de aceite. Si el objetivo recibe "
        "daño de fuego antes de que el aceite se seque (tras 1 minuto), sufrirá 5 de daño "
        "de fuego adicional debido al aceite ardiendo. También puedes derramar el aceite "
        "sobre el suelo, cubriendo un área de 5 pies cuadrados, siempre y cuando la "
        "superficie esté nivelada. Si se prende, el aceite arderá durante dos asaltos y "
        "causará 5 de daño de fuego a cualquier criatura que entre en la zona o acabe su "
        "turno en ella. Una criatura solo puede recibir daño de esta forma una vez por turno."),
}

if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8")
    d = cargar()
    print("entradas:", len(d))
    for k in list(d)[:12]: print("  %-30s %4d  %r" % (k[:29], len(d[k]), d[k][:70]))
