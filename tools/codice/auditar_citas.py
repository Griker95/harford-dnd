# -*- coding: utf-8 -*-
"""Comprueba que los conjuros citados dentro de un texto existan como ficha.

El libro cita los conjuros en cursiva ("puedes lanzar el conjuro *restauracion menor*").
Si ese nombre no coincide con el de ninguna ficha, el lector lo busca y no lo encuentra.
Hay dos causas distintas y se tratan distinto:

  - la ficha existe con OTRO nombre -> la cita se reescribe en limpieza._CITAS
  - el conjuro no existe en el compendio -> se deja la cita y se avisa aqui, porque
    inventar la ficha seria peor que la cita rota
"""
import io, json, os, re, sys, collections, unicodedata

sys.stdout.reconfigure(encoding="utf-8")
WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-data.js"


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn").lower().strip(" .,;:)")


t = io.open(WEB, encoding="utf-8").read()
KB = json.loads(t[t.find("{"):t.rfind("}") + 1])
# tambien valen los alias: la ficha se titula "Contorno borroso" y el libro la cita como
# "desenfoque", y el lector la encuentra igual porque ese nombre enlaza a ella
existe = {sa(s["name"]) for s in KB["spells"]}
existe |= {sa(a) for s in KB["spells"] for a in (s.get("aliases") or [])}

CAMPOS = ("description", "mechanics", "desc", "extras")
CITA = re.compile(r"(?:hechizo|conjuro)s?\s+\*([^*\n]{4,36})\*")
falta, resueltas, donde = collections.Counter(), 0, {}


def recorrer(o, nombre=None):
    global resueltas
    if isinstance(o, dict):
        n = o.get("name") or nombre
        for k, v in o.items():
            if isinstance(v, str) and k in CAMPOS:
                for m in CITA.finditer(v):
                    if sa(m.group(1)) in existe:
                        resueltas += 1
                    else:
                        falta[m.group(1).strip()] += 1
                        donde.setdefault(m.group(1).strip(), n)
            else:
                recorrer(v, n)
    elif isinstance(o, list):
        for v in o:
            recorrer(v, nombre)


recorrer(KB)
print("citas que resuelven a una ficha: %d" % resueltas)
print("citas que no resuelven: %d\n" % sum(falta.values()))
for k, v in falta.most_common():
    print("   %-34s x%-3d citado en %s" % (k, v, donde[k]))
