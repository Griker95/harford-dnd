# -*- coding: utf-8 -*-
"""Reescribe la funcion de las listas de conjuros, que la shell dejo rota.

Al insertarla desde la consola se convirtieron los "\\n" en saltos reales y el fichero
dejo de compilar. Aqui se escribe el bloque tal cual debe quedar.
"""
import io, re, sys

sys.stdout.reconfigure(encoding="utf-8")
P = "limpieza.py"
t = io.open(P, encoding="utf-8").read()

ini = t.find("_LINEA_LISTA = re.compile")
fin = t.find("def _parrafos_duplicados(t):")
assert ini > 0 and fin > ini, "no se localiza el bloque"

BLOQUE = '''_LINEA_LISTA = re.compile(r"(?m)^\\s*\\d+\\.?[ºo]\\s*(?=\\*)")


def _lista_de_conjuros(t):
    """Cierra las cursivas de las listas ampliadas de conjuros del brujo.

    El libro escribe esas filas con el asterisco de cierre perdido mas de una vez:
    "5.º*llamada infernal *atadura planar*", "1.º*manos ardientes*, *rayo del caos".
    La correccion se limita a las lineas que empiezan por el nivel, para no tocar prosa.
    """
    if "*" not in t: return t
    salida = []
    for linea in t.split("\\n"):
        if _LINEA_LISTA.match(linea):
            # un nombre que acaba y otro que empieza sin cerrar ni separar
            linea = re.sub(r"([a-záéíóúñ]) \\*", lambda m: m.group(1) + "*, *", linea)
            if linea.count("*") % 2: linea += "*"
        salida.append(linea)
    return "\\n".join(salida)


'''
io.open(P, "w", encoding="utf-8").write(t[:ini] + BLOQUE + t[fin:])
print("bloque reescrito")
