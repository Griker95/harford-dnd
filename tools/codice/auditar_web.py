# -*- coding: utf-8 -*-
"""Revisa los textos de las paginas escritas a mano de la web.

El compendio se genera y ya tiene su auditoria; estas paginas (historia, organizacion,
inteligencia, expediente...) se escriben a mano y nadie las habia mirado con los mismos
criterios: mojibake, terminologia fuera del glosario, unidades imperiales, comillas o
parentesis sin cerrar, enlaces rotos y anclas que no existen.
"""
import io, os, re, sys, glob, html, collections

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from terminologia import cargar_glosario, normalizar_habilidades

WEB = r"C:/Users/marco/Documents/harfordweb"
PAGINAS = sorted(glob.glob(os.path.join(WEB, "*.html")))

# terminologia: variantes que el glosario manda sustituir en contexto libre
GLOSARIO = cargar_glosario()
VARIANTES = {}
for seccion, entradas in GLOSARIO.items():
    if seccion.startswith("_") or not isinstance(entradas, dict): continue
    for canon, datos in entradas.items():
        if canon.startswith("_") or not isinstance(datos, dict): continue
        if datos.get("contexto") not in ("libre", "habilidad", "accion"): continue
        for v in datos.get("variantes", []):
            if v and v != canon: VARIANTES.setdefault(v, canon)

SIN_TEXTO = re.compile(r"<(script|style)\b.*?</\1>", re.S | re.I)
ETIQUETAS = re.compile(r"<[^>]+>")


def texto_de(ruta):
    """Devuelve el fuente y el texto visible.

    Las etiquetas se sustituyen por un salto de linea, no por un espacio: si se ponen
    espacios, el hueco entre dos elementos parece un doble espacio dentro de una frase y
    la revision se llena de avisos que no existen.
    """
    src = io.open(ruta, encoding="utf-8").read()
    cuerpo = SIN_TEXTO.sub("\n", src)
    return src, html.unescape(ETIQUETAS.sub("\n", cuerpo))


CHECKS = [
    ("mojibake", re.compile(r"Ã[\x80-\xbf]|Â[\x80-\xbf]|â€|\ufffd")),
    ("imperial", re.compile(r"\b\d+\s?(?:pies|pie|libras|millas|pulgadas)\b")),
    ("doble espacio", re.compile(r"[a-zA-Z]  +[a-zA-Z]")),
    ("dado OCR", re.compile(r"\b[lIS]d\d")),
    ("marcador markdown", re.compile(r"(?<!\w)\*\*|\]\([^)]*\)")),
]

def textos_js():
    """Los datos de personajes, organizaciones, lugares e inteligencia se escriben a mano
    igual que el HTML, pero viven en .js. Se sacan las cadenas literales: asi vale tanto
    para los ficheros que son JSON estricto como para los que no.
    """
    out = []
    for f in ("characters.js", "organizations.js", "intelligence.js", "places.js",
              "assets.js", "contacts.js"):
        p = os.path.join(WEB, "js", f)
        if not os.path.exists(p): continue
        src = io.open(p, encoding="utf-8").read()
        cadenas = re.findall(r'"((?:[^"\\]|\\.)*)"', src)
        # solo las que son prosa: las claves y los identificadores no interesan
        prosa = [c.replace('\\"', '"').replace("\\n", "\n") for c in cadenas
                 if len(c) > 40 and " " in c]
        out.append((f, "\n\n".join(prosa)))
    return out


problemas = collections.defaultdict(list)
for ruta, _txt in [(p, None) for p in PAGINAS] + [(None, x) for x in textos_js()]:
    if ruta is None:
        nombre, txt = _txt
        src = ""
    else:
        nombre = os.path.basename(ruta)
        src, txt = texto_de(ruta)
    for etiqueta, pat in CHECKS:
        for m in pat.finditer(txt):
            problemas[etiqueta].append((nombre, txt[max(0, m.start()-45):m.end()+35].strip()))
    # La terminologia se comprueba con el normalizador del pipeline, que entiende el
    # contexto. Buscar la variante a pelo daba falsos positivos serios: "Prestidigitacion"
    # es el CONJURO, no la habilidad "Juego de Manos", y "Arcanos" de "Disparos Arcanos"
    # es el nombre de un rasgo.
    for parrafo in txt.split("\n"):
        if len(parrafo) < 12: continue
        nuevo = normalizar_habilidades(parrafo)
        if nuevo != parrafo:
            for i in range(min(len(parrafo), len(nuevo))):
                if parrafo[i] != nuevo[i]:
                    problemas["terminologia"].append(
                        (nombre, "%s  =>  %s" % (parrafo[max(0, i-30):i+28], nuevo[max(0, i-30):i+30])))
                    break
    # comillas y parentesis descuadrados
    if txt.count("(") != txt.count(")"):
        problemas["parentesis"].append((nombre, "%d abren, %d cierran" % (txt.count("("), txt.count(")"))))
    if txt.count("«") != txt.count("»"):
        problemas["comillas"].append((nombre, "%d vs %d" % (txt.count("«"), txt.count("»"))))

# enlaces internos y anclas
anclas = {}
for ruta in PAGINAS:
    src = io.open(ruta, encoding="utf-8").read()
    anclas[os.path.basename(ruta)] = set(re.findall(r'id="([^"]+)"', src))
for ruta in PAGINAS:
    nombre = os.path.basename(ruta)
    src = io.open(ruta, encoding="utf-8").read()
    # `src` tambien: una imagen o un script con el nombre mal escrito no daba ni un aviso.
    # El <script src="js/resaltar.js"> que se anadio hoy habria pasado en silencio.
    for href in re.findall(r'(?:href|src)="([^"]+)"', src):
        if href.startswith(("http", "mailto:", "#", "javascript:")):
            if href.startswith("#") and href[1:] and href[1:] not in anclas[nombre]:
                problemas["ancla inexistente"].append((nombre, href))
            continue
        destino, _, frag = href.partition("#")
        # los css y js llevan sello de version (?v=hash) para romper la cache: no es parte
        # del nombre del fichero
        destino = destino.split("?")[0]
        destino = destino.lstrip("/")          # las rutas absolutas cuelgan de la raiz del sitio
        if destino and not os.path.exists(os.path.join(WEB, destino)):
            problemas["enlace roto"].append((nombre, href))
        elif frag and destino and frag not in anclas.get(destino, set()):
            problemas["ancla inexistente"].append((nombre, href))

# Los iconos NO se resuelven por nombre: la pagina los sirve como PNG reales desde
# assets/compendium-icons/ y, si falta el fichero, el onerror del <img> cae al icono de
# reserva sin decir nada. Ya paso con nueve armas: el nombre correcto en los datos y un
# puno dibujado en la web.
ICONOS = os.path.join(WEB, "assets", "compendium-icons")
if os.path.isdir(ICONOS):
    hay = {f[:-4].lower() for f in os.listdir(ICONOS) if f.endswith(".png")}
    for f in sorted(os.listdir(os.path.join(WEB, "js"))):
        if not (f.startswith("compendium-") and f.endswith(".js")):
            continue
        src = io.open(os.path.join(WEB, "js", f), encoding="utf-8").read()
        for nombre in sorted({m.group(1) for m in re.finditer(r'"icon[A-Za-z]*"\s*:\s*"([^"]+)"', src)}):
            corto = re.split(r"[\/]", nombre)[-1].lower()
            if corto and corto not in hay:
                problemas["icono sin PNG"].append((f, nombre))

# El arte de los trasfondos se convierte a WebP en el despliegue. Si la conversion falla o
# el original desaparece del export, la ficha se queda con una imagen rota: aqui no hay
# icono de reserva que disimule.
ARTE = os.path.join(WEB, "assets", "compendium-art")
if os.path.isdir(ARTE):
    hay_arte = set(os.listdir(ARTE))
    src = io.open(os.path.join(WEB, "js", "compendium-data.js"), encoding="utf-8").read()
    for nombre in sorted({m.group(1) for m in re.finditer(r'"art"\s*:\s*"([^"]+)"', src)}):
        if nombre not in hay_arte:
            problemas["arte sin fichero"].append(("compendium-data.js", nombre))

print("paginas revisadas: %d" % len(PAGINAS))
print("avisos: %d" % sum(len(v) for v in problemas.values()))
for k in sorted(problemas, key=lambda x: -len(problemas[x])):
    print("\n%s (%d)" % (k.upper(), len(problemas[k])))
    for nombre, det in problemas[k][:10]:
        print("   %-22s %s" % (nombre[:21], re.sub(r"\s+", " ", det)[:96]))
