# -*- coding: utf-8 -*-
"""Espacios de conjuro por nivel (1-20) de cada clase, leidos del Libro 1.

La tabla de cada clase trae las columnas de espacios, pero cada una las coloca de una
manera: el Mago y el Sacerdote meten una columna suelta antes de los rasgos, el Druida y
el Chaman la ponen despues, el Paladin solo tiene cinco columnas y el Brujo tiene un
formato propio (un solo grupo de espacios, todos del mismo nivel).

Para no depender de contar columnas a ojo, las celdas se leen DESPUES de la de rasgos (la
unica con texto) y el resultado se contrasta con la progresion canonica de 5e al nivel 20.
Si no coincide, la clase se descarta con un aviso en vez de publicar una tabla inventada.
"""
import os
import re
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
import tabla_clases_libro1 as T                                   # noqa: E402

# a lo que tiene que llegar el nivel 20 segun las reglas
COMPLETO = [4, 3, 3, 3, 3, 2, 2, 1, 1]
MEDIO = [4, 3, 3, 3, 2]

_NUM = re.compile(r"^\d+$")


def _valor(c):
    """Numero de una celda de espacios; el guion del libro es un cero."""
    c = (c or "").strip()
    if c in ("—", "-", "–", ""):
        return 0
    return int(c) if _NUM.match(c) else None


def _tiene_texto(c):
    return bool(re.search(r"[A-Za-zÁÉÍÓÚÑáéíóúñ]{3,}", c or ""))


def _fila(celdas):
    """La fila entera como numeros, con None donde la celda no es una cifra."""
    return [_valor(c) for c in celdas]


def _encaja(vals, patron):
    """Primer indice donde `patron` aparece dentro de `vals`, o None."""
    n = len(patron)
    for ini in range(0, max(0, len(vals) - n) + 1):
        if vals[ini:ini + n] == patron:
            return ini
    return None


def _brujo(filas):
    """El Brujo no tiene una columna por nivel de conjuro: tiene un numero de espacios y
    el nivel al que valen todos, y los recupera con un descanso corto. Se traduce a la
    misma forma que las demas clases poniendo esos espacios en su nivel."""
    prog = {}
    for lv, fila in filas.items():
        c = fila["celdas"]
        if len(c) < 7:
            continue
        cuantos = _valor(c[5])
        nivel = _valor(re.sub(r"[^0-9]", "", c[6] or ""))
        if not cuantos or not nivel or nivel > 9:
            continue
        fila_out = [0] * 9
        fila_out[nivel - 1] = cuantos
        fila = {"slots": fila_out}
        if isinstance(_valor(c[3]), int):
            fila["cantrips"] = _valor(c[3])
        if (c[4] or "").strip() not in ("—", "-", ""):
            fila["known"] = (c[4] or "").strip()
        prog[lv] = fila
    return prog


def leer(src=None):
    """{clase: {nivel: [espacios de nivel 1..N]}} solo de las clases verificadas."""
    tablas = T.leer() if src is None else T.leer(src)
    salida, avisos = {}, []
    for clase, filas in tablas.items():
        if 20 not in filas:
            continue
        # la columna donde empiezan los espacios es fija en toda la tabla: se localiza en
        # la fila del nivel 20, donde se sabe con que tiene que coincidir
        v20 = _fila(filas[20]["celdas"])
        ini = _encaja(v20, COMPLETO)
        largo = len(COMPLETO)
        if ini is None:
            ini = _encaja(v20, MEDIO)
            largo = len(MEDIO)
        if ini is None:
            if T.nk(clase) == "brujo":
                p = _brujo(filas)
                if p:
                    salida[clase] = p
                    continue
            avisos.append((clase, [c for c in filas[20]["celdas"]]))
            continue
        # trucos y conjuros conocidos van justo antes de los espacios, pero no siempre en
        # la misma columna: los trucos nunca pasan de 6 y el numero de conjuros conocidos
        # de una clase que los aprende es mucho mayor, asi que se distinguen por su valor
        i_trucos = i_conocidos = None
        for j in range(ini - 1, max(1, ini - 4), -1):
            v = v20[j] if j < len(v20) else None
            if not isinstance(v, int):
                continue
            if v <= 6 and i_trucos is None:
                i_trucos = j
            elif v > 6 and i_conocidos is None:
                i_conocidos = j
        prog = {}
        for lv in sorted(filas):
            celdas = filas[lv]["celdas"]
            vals = _fila(celdas)
            trozo = [(v if isinstance(v, int) else 0) for v in vals[ini:ini + largo]]
            if len(trozo) < largo:
                trozo += [0] * (largo - len(trozo))
            fila = {"slots": trozo}
            if i_trucos is not None and isinstance(vals[i_trucos] if i_trucos < len(vals) else None, int):
                fila["cantrips"] = vals[i_trucos]
            if i_conocidos is not None and i_conocidos < len(celdas):
                bruto = (celdas[i_conocidos] or "").strip()
                if bruto not in ("—", "-", ""):
                    fila["known"] = bruto
            prog[lv] = fila
        salida[clase] = prog
    return salida, avisos


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    prog, avisos = leer()
    print("clases con espacios de conjuro verificados: %d" % len(prog))
    for clase, p in sorted(prog.items()):
        print("  %-24s nv1 %s | nv20 %s" % (clase, p[1], p[20]))
    print("\nsin verificar (su nivel 20 no encaja con la progresion de 5e): %d" % len(avisos))
    for clase, v in avisos:
        print("  %-24s %s" % (clase, v))
