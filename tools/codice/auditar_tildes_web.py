# -*- coding: utf-8 -*-
"""Busca tildes que faltan en la prosa escrita a mano de la web.

No hay diccionario de espanol disponible, asi que la referencia es el propio compendio:
si una palabra aparece alli SIEMPRE con tilde y aqui alguna vez sin ella, esa forma sin
tilde es casi con seguridad una errata ("Investigacion" por "Investigacion" acentuada).

Se exige que la forma acentuada sea la dominante en el compendio para no proponer pares
legitimos que existen en las dos formas ("de" / "de" acentuado, "mas" / "mas" acentuado).
"""
import io, os, re, sys, json, glob, html, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb"
TILDE = "aeiouAEIOU"


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn")


PALABRA = re.compile(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{4,}")

# ---- vocabulario de referencia: los textos ya revisados del compendio ----
ref = collections.defaultdict(collections.Counter)
for f in glob.glob(os.path.join(WEB, "js", "compendium-*.js")):
    src = io.open(f, encoding="utf-8").read()
    for w in PALABRA.findall(src):
        ref[sa(w).lower()][w.lower()] += 1

# ---- textos escritos a mano ----
# un nombre de fichero no es prosa: "compania-harford.png" no lleva tilde ni debe llevarla
SLUG = re.compile(r"\{icon:[^}]*\}|\{col:[0-9a-fA-F]{6}\}|https?://\S+|[a-z]+_[a-z_]+"
                  r"|[\w./-]+\.(?:png|jpe?g|webp|svg|gif|ico)")
textos = []
for p in sorted(glob.glob(os.path.join(WEB, "*.html"))):
    s = io.open(p, encoding="utf-8").read()
    s = re.sub(r"<(script|style)\b.*?</\1>", "\n", s, flags=re.S | re.I)
    textos.append((os.path.basename(p), html.unescape(re.sub(r"<[^>]+>", "\n", s))))
for f in ("characters.js", "organizations.js", "intelligence.js", "places.js"):
    p = os.path.join(WEB, "js", f)
    if os.path.exists(p):
        src = io.open(p, encoding="utf-8").read()
        # las CLAVES del json no son prosa ("region": ...) y contarian como erratas
        src = re.sub(r'"[A-Za-z_]+"\s*:', ' ', src)
        textos.append((f, "\n".join(re.findall(r'"((?:[^"\\]|\\.)*)"', src))))

# formas que existen SIN tilde con otro significado y que el compendio no distingue
# ("de forma continua" es adjetivo, no el verbo acentuado; "para que dejara de constar" es
# subjuntivo, no el futuro). La lista larga es la misma que protege al acentuador.
EXCEPCIONES = {"continua"} | set(json.load(io.open(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "tildes.json"),
    encoding="utf-8"))["homografos"])

avisos = collections.defaultdict(collections.Counter)
for nombre, txt in textos:
    txt = SLUG.sub(" ", txt)
    for w in PALABRA.findall(txt):
        if w.lower() in EXCEPCIONES or sa(w) != w:
            continue                                   # ya lleva tilde
        formas = ref.get(w.lower())
        if not formas:
            continue
        con = sum(n for f, n in formas.items() if sa(f) != f)
        sin = sum(n for f, n in formas.items() if sa(f) == f)
        if con >= 3 and sin == 0:                      # en el compendio SIEMPRE acentuada
            buena = formas.most_common(1)[0][0]
            avisos[(w, buena)][nombre] += 1

print("palabras sin tilde que el compendio siempre acentua: %d\n" % len(avisos))
for (w, buena), donde in sorted(avisos.items(), key=lambda kv: -sum(kv[1].values())):
    print("   %-18s -> %-18s %s" % (w, buena, ", ".join("%s x%d" % (a, b) for a, b in donde.most_common(3))))
