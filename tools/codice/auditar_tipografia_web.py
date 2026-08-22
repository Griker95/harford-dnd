# -*- coding: utf-8 -*-
"""Tipografia de la prosa escrita a mano (paginas y expedientes).

auditar_tipografia.py mira los datos del compendio; esto mira lo que se escribio a mano,
que hasta ahora no pasaba por ninguna revision automatica: palabras repetidas, espacios
sobrantes, comillas rectas, puntuacion suelta.
"""
import io, os, re, sys, glob, html

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb"

REGLAS = [
    # sin cruzar el salto de linea: dos campos contiguos del json se pegaban y parecian
    # repeticion ("Cartel Ventura" seguido de "Ventura y Cia.")
    # ni cuando la segunda empieza en mayuscula: ahi no hay repeticion sino un titulo
    # seguido de su valor ("Estilo de combate" + "Combate con Dos Armas")
    ("palabra repetida", re.compile(r"\b([a-záéíóúñ]{3,})[ \t]+\1\b")),
    ("dos tildes en una palabra", re.compile(r"\b[a-zñ]*[áéíóú][a-zñ]*[áéíóú][a-zñ]*\b", re.I)),
    ("espacio antes de puntuacion", re.compile(r"\s+[,;:](?:\s|$)")),
    # el doble espacio pegado al marcado de color ({col:...}  17{/col}) es alineacion
    # deliberada de la ficha en juego, no una errata
    ("doble espacio", re.compile(r"[^}\s]  +[^{\s]")),
    ("comilla recta", re.compile(r"\"[a-zA-ZáéíóúñÁÉÍÓÚÑ]")),
    ("espacio antes de cierre", re.compile(r"\s[\)\]]")),
]

textos = []
for p in sorted(glob.glob(os.path.join(WEB, "*.html"))):
    s = io.open(p, encoding="utf-8").read()
    s = re.sub(r"<(script|style)\b.*?</\1>", "\n", s, flags=re.S | re.I)
    # las etiquetas EN LINEA se quitan sin dejar hueco: si no, "de <strong>ataque</strong>,"
    # se leia como "de  ataque ," y salia un aviso de espacio antes de la coma
    s = re.sub(r"</?(?:strong|em|b|i|a|code|abbr|sup|sub)[^>]*>", "", s)
    textos.append((os.path.basename(p), html.unescape(re.sub(r"<[^>]+>", "\n", s))))
for f in ("characters.js", "organizations.js", "intelligence.js", "places.js"):
    p = os.path.join(WEB, "js", f)
    if not os.path.exists(p):
        continue
    src = io.open(p, encoding="utf-8").read()
    src = re.sub(r'"[A-Za-z_]+"\s*:', " ", src)          # las claves no son prosa
    frases = [c for c in re.findall(r'"((?:[^"\\]|\\.)*)"', src) if " " in c]
    textos.append((f, "\n".join(frases)))

avisos = 0
for nombre, txt in textos:
    for etiqueta, pat in REGLAS:
        for m in pat.finditer(txt):
            trozo = txt[max(0, m.start() - 30):m.end() + 20].replace("\n", " ")
            print("   %-18s %-22s ... %s" % (nombre[:17], etiqueta[:21], trozo.strip()[:80]))
            avisos += 1
print("\navisos: %d" % avisos)
