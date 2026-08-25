# -*- coding: utf-8 -*-
"""Dependencias que un modulo declara y nadie le pasa.

Varios modulos reciben sus dependencias por inyeccion:

    -- en el modulo
    function API.Init(deps)
        FormatCheckRollLabel = deps.FormatCheckRollLabel or FormatCheckRollLabel
    end

    -- en quien lo carga
    WeaponRolls.Init({ FormatSaveOutcome = ..., FormatSaveRollLabel = ... })

Si el llamador se deja una, la variable se queda en `nil`. No falla al cargar: falla el dia que
alguien pulsa lo que la usa, y con un error que apunta al modulo y no a quien se la olvido.

Paso de verdad: `FormatCheckRollLabel` estaba declarada en `HarfordDnDWeaponRolls` y no se pasaba,
mientras sus dos vecinas si. Reventaba solo al usar Empujar contra un NPC, semanas despues de
escribirse.

Salida: codigo 0 si a nadie le falta ninguna.
"""

import io
import os
import re
import sys
import glob

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def sin_comentarios(texto):
    return re.sub(r'--[^\n]*', '', texto)


def declaradas(texto):
    """Nombres que el modulo espera recibir: `X = deps.X or X`."""
    return set(re.findall(r'(\w+)\s*=\s*deps\.\1\b', texto))


def bloques_init(texto):
    """Las claves de cada llamada `algo.Init({ ... })` del fichero.

    NO se adivina el alias del modulo. La primera version lo derivaba del nombre del fichero
    (`HarfordDnDWeaponRolls` -> `DnDWeaponRolls`) y el alias real era `WeaponRolls`, asi que no
    encontraba la llamada y daba por buenas todas sus dependencias: el detector callaba justo el
    fallo que lo motivo. Se recogen TODOS los bloques y luego se elige el que mas encaja.
    """
    fuera = []
    for m in re.finditer(r'\.Init\s*\(\s*\{', texto):
        i = texto.index('{', m.end() - 1)
        nivel, j = 0, i
        while j < len(texto):
            if texto[j] == '{':
                nivel += 1
            elif texto[j] == '}':
                nivel -= 1
                if nivel == 0:
                    break
            j += 1
        fuera.append(set(re.findall(r'(\w+)\s*=', texto[i:j])))
    return fuera


def main():
    modulos = {}
    for ruta in sorted(glob.glob(os.path.join(RAIZ, 'Harford', '**', '*.lua'), recursive=True)):
        texto = sin_comentarios(io.open(ruta, encoding='utf-8').read())
        esperadas = declaradas(texto)
        if esperadas:
            nombre = os.path.basename(ruta)[:-4]
            modulos[nombre] = (os.path.relpath(ruta, RAIZ).replace(os.sep, '/'), esperadas)

    if not modulos:
        print('Ningun modulo usa inyeccion de dependencias; no hay nada que comprobar.')
        return 0

    # Todo lo que se entrega, venga de donde venga: un modulo puede inicializarse desde varios
    # sitios, y basta con que UNO le pase la dependencia.
    todos = sorted(glob.glob(os.path.join(RAIZ, 'Harford', '**', '*.lua'), recursive=True))
    fuentes = {r: sin_comentarios(io.open(r, encoding='utf-8').read()) for r in todos}

    # Todos los bloques `Init({...})` del proyecto, de una vez.
    bloques = []
    for ruta, texto in fuentes.items():
        for claves in bloques_init(texto):
            bloques.append((os.path.relpath(ruta, RAIZ).replace(os.sep, '/'), claves))

    faltan = []
    for nombre, (rel, esperadas) in sorted(modulos.items()):
        # El inyector de un modulo es el bloque que MAS dependencias suyas comparte. Emparejar por
        # nombre no vale: el alias local no tiene por que parecerse al del fichero.
        mejor, mejorN = None, 0
        for origen, claves in bloques:
            comunes = len(esperadas & claves)
            if comunes > mejorN:
                mejor, mejorN = claves, comunes
        # Sin ningun bloque que encaje no se puede afirmar nada: puede que el modulo se use sin
        # inyectar y sus dependencias caigan a su valor por defecto.
        if not mejor:
            continue
        for dep in sorted(esperadas - mejor):
            faltan.append((rel, nombre, dep))

    print('Dependencias declaradas que nadie entrega: %d' % len(faltan))
    for rel, nombre, dep in faltan:
        print('  %s: %s espera "%s" y su Init no la pasa' % (rel, nombre, dep))
    return 1 if faltan else 0


if __name__ == '__main__':
    sys.exit(main())
