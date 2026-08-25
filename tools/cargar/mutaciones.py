# -*- coding: utf-8 -*-
"""Mide si las pruebas prueban: rompe el codigo a proposito y mira si alguna suite se entera.

Una prueba que pasa no dice nada por si sola. Hoy dos no probaban lo que decian: una miraba que el
fichero contuviera cierta linea (y la linea estaba mal), y otra usaba datos con los que un fallo real
daba la misma respuesta. Las dos estaban en verde.

Esto invierte la pregunta: si cambio `>` por `>=` en el motor, ¿se entera alguien? Si nadie se
entera, esa linea NO esta probada -- da igual cuantas aserciones la rodeen.

Uso:
    python tools/cargar/mutaciones.py                       -- los motores por defecto
    python tools/cargar/mutaciones.py Harford/.../X.lua     -- un fichero
    python tools/cargar/mutaciones.py X.lua 40              -- con tope de mutaciones

NO es un paso de despliegue: cada mutacion cuesta una pasada entera de suites. Se ejecuta a mano
cuando se quiere saber si una zona esta cubierta de verdad.
"""

import io
import os
import re
import sys
import random
import signal
import subprocess

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Por defecto, los motores: donde una comparacion mal puesta cambia una regla de juego.
POR_DEFECTO = [
    'Harford/DnD/Engine/HarfordDnDCalc.lua',
    'Harford/DnD/Engine/HarfordDnDConditions.lua',
    'Harford/DnD/Engine/HarfordDnDWeaponRolls.lua',
    'Harford/DnD/Data/HarfordDnDActions.lua',
]

# Cambios pequenos que casi siempre alteran el comportamiento. Nada de tocar nombres ni estructura:
# una mutacion que solo rompe la sintaxis no mide nada, porque la atrapa el compilador.
OPERADORES = [
    (r'(?<![<>=~])>=', '>'), (r'(?<![<>=~])<=', '<'),
    (r'(?<![<>=~])>(?!=)', '>='), (r'(?<![<>=~])<(?!=)', '<='),
    (r'==', '~='),
    (r'\bmath\.floor\b', 'math.ceil'), (r'\bmath\.ceil\b', 'math.floor'),
    (r'\bmath\.max\b', 'math.min'), (r'\bmath\.min\b', 'math.max'),
    (r'\btrue\b', 'false'), (r'\bfalse\b', 'true'),
]


def zonas_de_codigo(texto):
    """Rangos que son codigo: fuera quedan comentarios y cadenas.

    Mutar dentro de una cadena cambia un texto visible, no una regla, y saldria como superviviente
    sin serlo: la etiqueta cambia y ninguna prueba de logica tiene por que mirarla.
    """
    fuera = []
    i, n = 0, len(texto)
    while i < n:
        if texto.startswith('--[[', i):
            j = texto.find(']]', i)
            i = n if j < 0 else j + 2
            continue
        if texto.startswith('--', i):
            j = texto.find('\n', i)
            i = n if j < 0 else j
            continue
        if texto[i] in '"\'':
            comilla, j = texto[i], i + 1
            while j < n and texto[j] != comilla:
                j += 2 if texto[j] == '\\' else 1
            i = j + 1
            continue
        if texto.startswith('[[', i):
            j = texto.find(']]', i)
            i = n if j < 0 else j + 2
            continue
        inicio = i
        while i < n and texto[i] not in '-"\'[':
            i += 1
        if i > inicio:
            fuera.append((inicio, i))
        if i < n and not (texto.startswith('--', i) or texto[i] in '"\'' or texto.startswith('[[', i)):
            fuera.append((i, i + 1))
            i += 1
    return fuera


def candidatas(ruta):
    texto = io.open(os.path.join(RAIZ, ruta), encoding='utf-8', newline='').read()
    zonas = zonas_de_codigo(texto)

    def es_codigo(pos):
        return any(a <= pos < b for a, b in zonas)

    fuera = []
    for patron, reemplazo in OPERADORES:
        for m in re.finditer(patron, texto):
            if es_codigo(m.start()):
                fuera.append((m.start(), m.end(), m.group(0), reemplazo,
                              texto[:m.start()].count('\n') + 1))
    return texto, fuera


# El fichero se restaura en un `finally`, pero eso NO cubre que maten el proceso desde fuera: un
# `timeout` o un Ctrl-C dejaban el modulo MUTADO en disco, y el siguiente despliegue se lo llevaba
# al cliente. Paso de verdad. Asi que ademas:
#   - se atienden las senales para restaurar antes de morir,
#   - y se deja una marca en disco con lo que se esta tocando, para poder deshacerlo en el arranque
#     siguiente aunque no diera tiempo a nada (SIGKILL no se puede atender).
MARCA = os.path.join(RAIZ, 'tools', 'cargar', '.mutacion_en_curso')
_restaurar = None


def _guardar_respaldo(ruta_rel, texto):
    global _restaurar
    _restaurar = (ruta_rel, texto)
    with io.open(MARCA, 'w', encoding='utf-8', newline='') as fh:
        fh.write(ruta_rel + chr(10))
        fh.write(texto)


def _deshacer():
    global _restaurar
    if _restaurar:
        rel, texto = _restaurar
        io.open(os.path.join(RAIZ, rel), 'w', encoding='utf-8', newline='').write(texto)
        _restaurar = None
    if os.path.exists(MARCA):
        os.remove(MARCA)


def _al_morir(signum, frame):
    _deshacer()
    sys.exit(130)


def recuperar_de_una_muerte_anterior():
    """Si la ejecucion anterior no llego a restaurar, se deshace ahora."""
    if not os.path.exists(MARCA):
        return
    with io.open(MARCA, encoding='utf-8', newline='') as fh:
        contenido = fh.read()
    corte = contenido.find(chr(10))
    if corte > 0:
        rel, texto = contenido[:corte], contenido[corte + 1:]
        destino = os.path.join(RAIZ, rel)
        if os.path.exists(destino):
            io.open(destino, 'w', encoding='utf-8', newline='').write(texto)
            print('Se restauro %s, que una ejecucion anterior dejo mutado.' % rel)
    os.remove(MARCA)


def suites_pasan():
    r = subprocess.run([sys.executable, os.path.join(RAIZ, 'tools', 'pruebas.py')],
                       capture_output=True, text=True, encoding='utf-8', errors='replace')
    return r.returncode == 0


def main():
    args = [a for a in sys.argv[1:]]
    tope = 60
    ficheros = []
    for a in args:
        if a.isdigit():
            tope = int(a)
        else:
            ficheros.append(a.replace(os.sep, '/'))
    ficheros = ficheros or POR_DEFECTO

    recuperar_de_una_muerte_anterior()
    for s in (signal.SIGINT, signal.SIGTERM):
        try:
            signal.signal(s, _al_morir)
        except (ValueError, AttributeError):
            pass   # En algunos entornos no se pueden atender; queda la marca en disco.

    if not suites_pasan():
        print('Las suites ya fallan sin mutar nada. Arregla eso primero.')
        return 2

    todas = []
    for ruta in ficheros:
        texto, cands = candidatas(ruta)
        for c in cands:
            todas.append((ruta, texto, c))

    # Muestreo estable: la misma semilla da el mismo informe, para poder comparar entre ejecuciones.
    random.seed(20260825)
    random.shuffle(todas)
    elegidas = todas[:tope]
    print('%d mutaciones posibles; se prueban %d.' % (len(todas), len(elegidas)))

    sobreviven = []
    for i, (ruta, texto, (a, b, viejo, nuevo, linea)) in enumerate(elegidas, 1):
        completa = os.path.join(RAIZ, ruta)
        try:
            _guardar_respaldo(ruta, texto)
            io.open(completa, 'w', encoding='utf-8', newline='').write(texto[:a] + nuevo + texto[b:])
            if suites_pasan():
                sobreviven.append((ruta, linea, viejo, nuevo))
        finally:
            # Pase lo que pase, el fichero vuelve. Un fallo aqui dejaria el addon roto en disco.
            _deshacer()
        sys.stdout.write('\r  %d/%d probadas, %d sin detectar   ' % (i, len(elegidas), len(sobreviven)))
        sys.stdout.flush()
    print()

    print('\nMUTACIONES QUE NADIE DETECTA: %d de %d' % (len(sobreviven), len(elegidas)))
    for ruta, linea, viejo, nuevo in sobreviven:
        print('  %s:%d   %s -> %s' % (ruta, linea, viejo, nuevo))
    if sobreviven:
        print('\nCada linea de arriba es codigo que se puede cambiar sin que ninguna prueba se queje.')
        print('No todas merecen prueba: mucho es UI o red, que no corre fuera de WoW.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
