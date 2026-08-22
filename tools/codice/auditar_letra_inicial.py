# -*- coding: utf-8 -*-
"""Busca la letra inicial desprendida de su palabra ("s uelo", "s iguiente").

Es el reverso de palabras_partidas.py, que mira el corte por el final. Aqui el OCR deja
la primera letra suelta, y como en castellano ninguna consonante es palabra de una letra,
el aviso es fiable. Aun asi se exige que la union produzca una palabra que YA existe en
el compendio y que sea mas frecuente que el resto suelto, para no inventar uniones.
"""
import io, json, os, re, sys, collections

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js"

t = io.open(os.path.join(WEB, "compendium-data.js"), encoding="utf-8").read()
KB = json.loads(t[t.find("{"):t.rfind("}") + 1])
voc = collections.Counter(w.lower() for w in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{3,}", t))

CAMPOS = ("desc", "description", "extras", "mechanics", "roleNotes")
SUELTA = re.compile(r"(?<![A-Za-zÁÉÍÓÚáéíóúñ])([b-df-hj-np-tv-zB-DF-HJ-NP-TV-Z]) ([a-záéíóúñ]{2,})")
avisos = collections.Counter()
ejemplo = {}


def recorrer(o, nombre=None):
    if isinstance(o, dict):
        n = o.get("name") or nombre
        for k, v in o.items():
            if isinstance(v, str) and k in CAMPOS:
                for m in SUELTA.finditer(v):
                    unido = (m.group(1) + m.group(2)).lower()
                    if voc[unido] >= 3 and voc[m.group(2).lower()] < voc[unido]:
                        avisos[unido] += 1
                        ejemplo.setdefault(unido, (n, v[max(0, m.start() - 35):m.end() + 20]))
            else:
                recorrer(v, n)
    elif isinstance(o, list):
        for v in o:
            recorrer(v, nombre)


recorrer(KB)
print("inicios de palabra separados: %d en %d formas" % (sum(avisos.values()), len(avisos)))
for w, n in avisos.most_common():
    quien, ctx = ejemplo[w]
    print("   %-16s x%-3d %-24s ...%s" % (w, n, str(quien)[:23], ctx.replace("\n", " ")[:60]))
