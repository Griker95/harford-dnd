# -*- coding: utf-8 -*-
"""Detecta palabras que el OCR partio con un espacio dentro ("med iante", "profu ndo").

No hay diccionario a mano, asi que el corpus hace de diccionario: si "mediante" aparece
escrito junto en otros textos del compendio y "iante" no existe como palabra por su
cuenta, entonces "med iante" es la misma palabra partida.

Para no juntar dos palabras de verdad se exige, ademas:
  - que la union exista y sea razonablemente frecuente,
  - que el segundo trozo NO sea una palabra que aparezca sola en el corpus,
  - que ninguno de los dos trozos sea una palabra corta de uso comun (de, la, un...).

Sin --apply solo informa.
"""
import io, os, re, sys, json, glob, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js"
RAIZ = r"C:/Users/marco/Documents/New project/Harford"

# palabras cortas que existen solas y jamas son el trozo de otra
COMUNES = set("""a al algo alli ante antes aqui asi aun cada como con contra cual cuando de del
donde dos el ella ellas ello ellos en entre era eran eres es esa esas ese eso esos esta estan
estas este esto estos fue ha han hasta hay la las le les lo los mas me mi mis mucho muy nada ni
no nos o os otra otras otro otros para pero poco por porque que quien se sea sean segun ser si
sin so sobre solo son su sus tan te ti todo todos tras tu tus un una uno unos vez y ya
uso paso peso caso base fase mano modo pie pies tipo dado dano hora dia luz mar sol dos tres
arma area cofre suelo cuerpo turno nivel dado dados metro metros pieza piezas""".split())


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower()


def textos_web():
    out = []
    t = io.open(os.path.join(WEB, "compendium-data.js"), encoding="utf-8").read()
    KB = json.loads(t[t.find("{"):t.rfind("}")+1])
    for s in KB["spells"]: out.append(s.get("description") or "")
    for c in KB["classes"]:
        out += [c.get("desc") or "", c.get("extras") or ""]
        out += [f.get("desc") or "" for f in c["features"]]
        out += [f.get("desc") or "" for s in c["subclasses"] for f in s["features"]]
    for r in KB["races"]:
        out += [r.get("desc") or "", r.get("extras") or ""]
        out += [x.get("desc") or "" for x in r["traits"]]
        out += [x.get("desc") or "" for s in r.get("subraces", []) for x in s["traits"]]
    for b in KB["backgrounds"]:
        out.append(b.get("desc") or "")
        out += [x.get("desc") or "" for x in b["traits"]]
    for fich, clave in (("compendium-equipment.js", "note"), ("compendium-dotes.js", "desc"),
                        ("compendium-professions.js", "desc")):
        p = os.path.join(WEB, fich)
        if not os.path.exists(p): continue
        d = io.open(p, encoding="utf-8").read()
        for x in json.loads(d[d.find("["):d.rfind("]")+1]):
            if isinstance(x, dict) and isinstance(x.get(clave), str): out.append(x[clave])
    return out


PALABRA = re.compile(r"[A-Za-zÁÉÍÓÚÑÜáéíóúñü]{2,}")
# tambien vale un trozo de una sola letra: el OCR separa la inicial ("S i el conjuro") o
# deja colgada la ultima ("una accio n"). Las letras que SI son palabra quedan fuera abajo.
# El segundo trozo va en un lookahead para que la busqueda NO lo consuma: si no, en
# "y a lojamiento" se emparejaba "y a" y ya no llegaba a probar "a lojamiento".
CANDIDATO = re.compile(r"\b([A-Za-zÁÉÍÓÚÑáéíóúñ]+)[ \t](?=([a-záéíóúñ]+)\b)")
LETRA_PALABRA = set("aoyeu")

RULES = r"C:/Users/marco/Documents/New project/RuleSource"


def vocabulario_manuales():
    """Las palabras de los manuales en crudo hacen de diccionario de castellano.

    Con solo el vocabulario del compendio se escapaban las palabras poco frecuentes:
    "funera l", "pagaria n" o "a lojamiento" no se detectaban porque "funeral" y
    "alojamiento" aparecen una sola vez aqui. En los manuales aparecen muchas.
    """
    voc = collections.Counter()
    fuentes = glob.glob(os.path.join(RULES, "Rulebooks_MD", "*.md"))
    fuentes += glob.glob(os.path.join(RULES, "Export", "*", "texto.md"))
    for f in fuentes:
        try: txt = io.open(f, encoding="utf-8", errors="replace").read()
        except OSError: continue
        for w in PALABRA.findall(txt): voc[sa(w)] += 1
    return voc


VOC_MANUAL = vocabulario_manuales()

textos = textos_web()
vocab = collections.Counter()
for t in textos:
    for w in PALABRA.findall(t): vocab[sa(w)] += 1
for k, v in VOC_MANUAL.items(): vocab[k] += v

cand = collections.Counter()
for t in textos:
    for m in CANDIDATO.finditer(t):
        a, b = m.group(1), m.group(2)
        ja, jb, jun = sa(a), sa(b), sa(a + b)
        # Una letra que SI es palabra ("a", "o", "y") solo se une si lo que sale es una
        # palabra muy usada en los manuales: asi se recupera "a lojamiento" sin tocar
        # "a lomos".
        # Lo que decide es el SEGUNDO trozo: si es una palabra de verdad, los dos lo son y
        # es una frase normal ("a un", "volver a"). Si no lo es, la palabra viene partida
        # ("a lojamiento", "funera l"). Por eso al primero se le permite ser "a" u "o".
        if len(jun) < 4: continue                   # "ya", "en", "os": no vale la pena
        if len(jb) == 1 and jb in LETRA_PALABRA: continue   # "y a las criaturas" es correcto
        # "Es una palabra" se decide con el vocabulario de los MANUALES, no con el del
        # compendio: aqui el trozo puede aparecer varias veces sencillamente porque la
        # misma errata se repite ("a lojamiento" salia tres veces y parecia palabra).
        # El umbral es alto a proposito: los manuales arrastran las MISMAS roturas, asi
        # que "lojamiento" o "lgunas" aparecen alli dos o tres veces. Una palabra de
        # verdad sale cientos. Por debajo de ocho no cuenta como palabra.
        if len(jb) > 1 and (jb in COMUNES or VOC_MANUAL.get(jb, 0) >= 8): continue
        # una consonante suelta nunca es palabra en castellano: si la union existe, la
        # palabra venia partida por ahi ("proporcionara n", "marge n")
        consonante = len(jb) == 1 and jb not in LETRA_PALABRA
        # ...pero una palabra comun nunca encabeza una rotura: en "equipada con s illa" el
        # par bueno es "s illa", no "con s"
        if len(ja) > 1 and ja in COMUNES: continue
        if not consonante and len(ja) > 1 and VOC_MANUAL.get(ja, 0) >= 8: continue
        if vocab.get(jun, 0) < (1 if consonante else 3): continue
        cand[(a, b, a + b)] += 1

print("palabras partidas detectadas: %d formas" % len(cand))
for (a, b, j), n in cand.most_common(40):
    print("   %-28s -> %-22s x%d" % (a + " " + b, j, n))

SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "palabras_partidas.json")

if "--apply" in sys.argv:
    # el diccionario se guarda como dato: limpieza.py lo aplica tambien al texto que se
    # trae de los manuales, que no pasa por el Lua del addon
    previo = {}
    if os.path.exists(SALIDA):
        previo = json.load(io.open(SALIDA, encoding="utf-8"))
    for (a, b, j), n in cand.items():
        previo[a + " " + b] = j
    json.dump(dict(sorted(previo.items())), io.open(SALIDA, "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
    print("diccionario guardado: %d formas en %s" % (len(previo), os.path.basename(SALIDA)))

    # se corrige en el Lua del addon, que es la fuente; la web se regenera despues
    FICHEROS = []
    for nombre in ("HarfordCompendioData", "HarfordDnDBook", "HarfordDnDBackgrounds",
                   "HarfordDnDFeats", "HarfordDnDRaces", "HarfordDnDBookText", "HarfordDnDData"):
        FICHEROS += glob.glob(RAIZ + "/**/%s.lua" % nombre, recursive=True)
    reglas = [(re.compile(r"\b" + re.escape(a) + r"\s" + re.escape(b) + r"\b"), a + b)
              for (a, b, j), n in cand.items()]
    total = 0
    for f in FICHEROS:
        d = io.open(f, encoding="utf-8", newline="").read()
        orig = d
        for pat, rep in reglas: d = pat.sub(rep, d)
        if d != orig:
            io.open(f, "w", encoding="utf-8", newline="").write(d)
            total += 1
    print("\nficheros del addon corregidos: %d" % total)
