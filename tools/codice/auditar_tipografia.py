# -*- coding: utf-8 -*-
"""Barrido de TIPOGRAFIA y puntuacion, por categorias.

Los barridos anteriores miraban las palabras (erratas, partidas, tildes) y la estructura
(cotejo, coherencia). Este mira lo de en medio: como esta escrito el texto.

  palabra repetida     "de de", "el el": el clasico salto de linea del PDF
  espacio mal puesto   antes de una coma, detras de un parentesis que abre
  frase sin abrir      "?" o "!" de cierre sin su signo de apertura en castellano
  mayuscula intrusa    "campoDe" pegado por el OCR
  dado imposible       1d7, 1d9: no existen en 5e
  parrafo repetido     el mismo parrafo dos veces dentro de la misma entrada
  puntuacion rara      dos puntos seguidos, coma antes de punto, puntos suspensivos mal

Uso: python auditar_tipografia.py [categoria ...]
"""
import io, os, re, sys, json, collections

sys.stdout.reconfigure(encoding="utf-8")
BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
from auditar_erratas import CAT          # mismas categorias que el barrido de erratas

DADOS_VALIDOS = {2, 3, 4, 6, 8, 10, 12, 20, 100}

REGLAS = [
    # Ninguna palabra castellana lleva dos tildes. Es la marca de un acentuado automatico
    # que ha partido una palabra ya acentuada: paso de verdad con "Caracteristica" acentuada,
    # que se partia por su propia tilde y salia como "Caracter" acentuado mas "istica".
    ("dos tildes en una palabra", re.compile(r"\b[a-zñ]*[áéíóú][a-zñ]*[áéíóú][a-zñ]*\b", re.I)),
    ("palabra repetida", re.compile(r"\b([a-záéíóúñ]{2,})\s+\1\b", re.I)),
    ("espacio antes de puntuacion", re.compile(r"\s+[,;:.](?:\s|$)")),
    ("espacio tras parentesis que abre", re.compile(r"\(\s")),
    ("espacio antes de parentesis que cierra", re.compile(r"\s\)")),
    ("doble espacio", re.compile(r"\S  +\S")),
    # La interrogacion se comprueba CONTANDO signos (mas abajo), no mirando los 80
    # caracteres previos: una pregunta puede ser larga y esa regla daba 94 avisos falsos.
    ("mayuscula dentro de palabra", re.compile(r"\b[a-záéíóúñ]{2,}[A-ZÁÉÍÓÚÑ][a-záéíóúñ]{2,}\b")),
    # los puntos suspensivos son tres: el patron excluye ese caso a los dos lados
    ("puntuacion repetida", re.compile(r"[,;:]{2,}|(?<!\.)\.{2}(?!\.)|\.{4,}|,\s*\.")),
    # "en el nivel 5 (2d8), nivel 11 (3d8), y el nivel 17" es una enumeracion normal: la
    # coma antes de la conjuncion final no es una errata. Eran 16 avisos que no existian.
]


def interrogacion_descuadrada(t):
    """Los signos de apertura y de cierre tienen que salir en el mismo numero."""
    return t.count("¿") != t.count("?") or t.count("¡") != t.count("!")


def parrafos_repetidos(t):
    ps = [p.strip() for p in t.split("\n\n") if len(p.strip()) > 60]
    vistos, repes = set(), []
    for p in ps:
        k = re.sub(r"\s+", " ", p)[:120]
        if k in vistos: repes.append(k[:60])
        vistos.add(k)
    return repes


def dados_raros(t):
    return [m.group(0) for m in re.finditer(r"\b\d*d(\d+)\b", t)
            if int(m.group(1)) not in DADOS_VALIDOS]


pedidas = [x for x in sys.argv[1:] if x in CAT] or list(CAT)
total = 0
for cat in pedidas:
    hallazgos = collections.defaultdict(list)
    for nombre, texto in CAT[cat]:
        if not texto: continue
        for etiqueta, pat in REGLAS:
            for m in pat.finditer(texto):
                ctx = re.sub(r"\s+", " ", texto[max(0, m.start()-32):m.end()+24])
                hallazgos[etiqueta].append((nombre, repr(m.group(0))[:26], ctx[:58]))
        if interrogacion_descuadrada(texto):
            hallazgos["signos de interrogacion descuadrados"].append(
                (nombre, "%d abren / %d cierran" % (texto.count("¿"), texto.count("?")), ""))
        for p in parrafos_repetidos(texto):
            hallazgos["parrafo repetido"].append((nombre, "", p))
        for d in dados_raros(texto):
            hallazgos["dado que no existe"].append((nombre, d, ""))
    n = sum(len(v) for v in hallazgos.values())
    total += n
    print("\n%s (%d entradas) -> %d avisos" % (cat.upper(), len(CAT[cat]), n))
    for etiqueta in sorted(hallazgos, key=lambda x: -len(hallazgos[x])):
        print("   %s (%d)" % (etiqueta, len(hallazgos[etiqueta])))
        for nombre, tok, ctx in hallazgos[etiqueta][:6]:
            print("      %-28s %-26s %s" % (nombre[:27], tok, ctx))
print("\ntotal de avisos: %d" % total)
