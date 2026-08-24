# -*- coding: utf-8 -*-
"""Campos declarados en los datos que NINGUN motor lee.

Un rasgo puede declarar lo que quiera: Lua no se queja. Si el campo no lo lee nadie, el rasgo se
anuncia, gasta su uso o su recurso, y no hace nada -- sin error y sin pista de por que. Le pasaba a
la Reserva de Ira del Guerrero, que declaraba `rageReserveByLevel` y no daba ni un punto.

Se comparan los nombres de campo de los ficheros de DATOS contra el resto del addon.

Antes de comparar se quitan comentarios, literales de texto y parametros de funcion: sin eso, una
palabra dentro de una descripcion ("4h de trance = 8h") o el parametro de `GetTrait(traitId)` se
cuentan como campos, y nueve falsos positivos tapan el unico real. Una herramienta que grita en
falso es peor que ninguna -- ya nos ha costado un fallo real dado por ruido.

    python tools/cargar/datos_muertos.py
"""
import io
import os
import re
import sys
import glob

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATOS = [
    'Harford/DnD/Data/Classes/*.lua',
    'Harford/DnD/Data/HarfordDnDRaces.lua',
    'Harford/DnD/Data/HarfordDnDBackgrounds.lua',
    'Harford/DnD/Data/HarfordDnDFeats.lua',
]

# Estructurales: los lee todo el mundo y no dicen nada.
IGNORAR = {
    'id', 'name', 'nameF', 'level', 'desc', 'description', 'icon', 'type', 'label', 'source',
    'aliases', 'note', 'text', 'values', 'value', 'kind', 'effects', 'traits', 'options',
    'faction', 'size', 'speed', 'min', 'max', 'count', 'die', 'cost', 'resource', 'mode',
    # Clave de una tabla de alias de genero, no un campo de rasgo.
    'semielfa',
}

CAMPO = re.compile(r'(?<![\w.:"])([a-z][A-Za-z0-9]{3,})\s*=\s*')
# `local a, b, c`: hay que coger los TRES, no solo el primero.
LOCAL = re.compile(r'(?<![\w.:])local[ \t]+([a-zA-Z_][A-Za-z0-9_, \t]*)')
PARAMS = re.compile(r'function[^\r\n(]*\(([^)]*)\)')


def limpia(texto):
    """Deja solo codigo: sin comentarios, sin literales y sin listas de parametros."""
    texto = re.sub(r'--\[\[.*?\]\]', ' ', texto, flags=re.S)
    texto = re.sub(r'--[^\r\n]*', ' ', texto)
    texto = re.sub(r'"(?:[^"\\]|\\.)*"', '""', texto)
    texto = re.sub(r"'(?:[^'\\]|\\.)*'", "''", texto)
    # La lista de parametros NO se borra: sus nombres hacen falta como locales, porque una funcion
    # suele reasignar su propio parametro (`traitId = tostring(traitId or "")`) y eso se contaria
    # como un campo declarado.
    return texto


def rutas(patrones):
    fuera = []
    for patron in patrones:
        fuera += glob.glob(os.path.join(RAIZ, *patron.split('/')))
    return fuera


def main():
    ficheros_datos = rutas(DATOS)
    declarados = {}
    for f in ficheros_datos:
        s = limpia(io.open(f, encoding='utf-8', errors='replace').read())
        locales = set()
        for grupo in LOCAL.findall(s):
            for nombre in grupo.split(','):
                nombre = nombre.strip()
                if nombre:
                    locales.add(nombre)
        for grupo in PARAMS.findall(s):
            for nombre in grupo.split(','):
                nombre = nombre.strip()
                if nombre:
                    locales.add(nombre)
        for m in CAMPO.finditer(s):
            if m.group(1) not in locales:
                declarados.setdefault(m.group(1), os.path.relpath(f, RAIZ).replace(os.sep, '/'))

    conjunto_datos = {os.path.abspath(f) for f in ficheros_datos}
    motor = []
    for f in glob.glob(os.path.join(RAIZ, 'Harford*', '**', '*.lua'), recursive=True):
        if os.path.abspath(f) not in conjunto_datos:
            motor.append(io.open(f, encoding='utf-8', errors='replace').read())
    motor = '\n'.join(motor)

    muertos = []
    for campo, donde in sorted(declarados.items()):
        if campo in IGNORAR:
            continue
        # Lo lee alguien si aparece como `.campo`, `["campo"]` o `campo =` fuera de los datos.
        if re.search(r'[.\[]\s*"?%s"?' % re.escape(campo), motor):
            continue
        if re.search(r'(?<![\w.:])%s\s*=' % re.escape(campo), motor):
            continue
        muertos.append((campo, donde))

    for campo, donde in muertos:
        print('  %-28s declarado en %s y no lo lee nadie' % (campo, donde))
    print()
    print('Campos de datos que ningun motor lee: %d' % len(muertos))
    return 1 if muertos else 0


if __name__ == '__main__':
    sys.exit(main())
