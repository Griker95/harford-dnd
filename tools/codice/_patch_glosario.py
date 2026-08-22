# -*- coding: utf-8 -*-
"""terminologia.py pasa a leer glosario.json en vez de llevar las listas escritas dentro.
Asi hay un solo sitio donde anadir un termino nuevo."""
import io, os, ast

p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "terminologia.py")
t = io.open(p, encoding="utf-8").read()

nuevo_inicio = '''# -*- coding: utf-8 -*-
"""Terminologia canonica compartida por todo el pipeline.

Las equivalencias viven en glosario.json (el diccionario privado del proyecto): ahi se
anade un termino nuevo y todo el compendio se normaliza solo. Cada manual traduce a su
manera ("Manejo de Animales" / "Trato con Animales", "Desengancharse" / "Destrabarse")
y el compendio debe usar SIEMPRE un unico nombre.

La sustitucion es CONSCIENTE DEL CONTEXTO segun el campo `contexto` del glosario:
  habilidad -> solo si se habla de la habilidad (competencia en X, prueba de INT (X))
  accion    -> solo si se habla de la accion (accion de X, realizar X)
  libre     -> sustitucion directa, el termino no es ambiguo
  informativo -> NO se sustituye; esta en el glosario solo para poder comparar
"""
import io, json, os, re

_GLOSARIO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "glosario.json")

def cargar_glosario():
    with io.open(_GLOSARIO, encoding="utf-8") as f:
        return json.load(f)

def _por_contexto(ctx):
    """{canon: [variantes]} de todas las secciones del glosario con ese contexto."""
    out = {}
    for seccion, entradas in cargar_glosario().items():
        if seccion.startswith("_") or not isinstance(entradas, dict): continue
        for canon, datos in entradas.items():
            if canon.startswith("_") or not isinstance(datos, dict): continue
            if datos.get("contexto") != ctx: continue
            vs = [v for v in datos.get("variantes", []) if v and v != canon]
            if vs: out[canon] = vs
    return out

SKILL_VARIANTS = _por_contexto("habilidad")
'''

# recortar la cabecera vieja hasta la definicion de SKILL_VARIANTS y sustituir el dict
ini = t.find("CARACS = ")
assert ini != -1, "no se encontro CARACS"
t = nuevo_inicio + "\n" + t[ini:]

# ACCIONES y DIRECTOS tambien salen del glosario
viejo_acc = t[t.find("ACCIONES = {"): t.find("}", t.find("ACCIONES = {")) + 1]
t = t.replace(viejo_acc, "ACCIONES = _por_contexto('accion')", 1)

ini_d = t.find("DIRECTOS = [")
fin_d = t.find("]", ini_d) + 1
directos_nuevo = '''DIRECTOS = []
for _canon, _vs in _por_contexto("libre").items():
    if "espacio de conjuro" in _canon: continue      # lo trata _RANURA, que concuerda genero
    for _v in sorted(_vs, key=len, reverse=True):
        DIRECTOS.append((r"\\b" + re.escape(_v) + r"\\b", _canon))'''
t = t[:ini_d] + directos_nuevo + t[fin_d:]

io.open(p, "w", encoding="utf-8").write(t)
ast.parse(io.open(p, encoding="utf-8").read())
print("terminologia.py lee del glosario")
