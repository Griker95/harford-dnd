# -*- coding: utf-8 -*-
"""Referencias que apuntan a algo que no existe.

Un rasgo puede nombrar la condicion `ayudado_pruebaa` y Lua no se queja: la busca, no la encuentra,
y no hace nada. Ni el compilador ni el arnes de carga lo ven, porque el fichero es valido y carga
bien; el fallo aparece cuando alguien pulsa el boton, y aparece como silencio.

Es la misma familia de fallo que dejo nueve condiciones sin aplicarse nunca por no estar en
`API.ORDER`: algo apunta a un sitio vacio y el sistema se lo traga.

Cada espacio de nombres es SUYO y no se mezclan:
  - conditionId / selfCondition.id / onWin / helpOther -> HarfordDnDConditions.DEFS
  - resourceKey                                        -> HarfordDnDResources.DEFS
  - grantsAsBonus                                      -> HarfordDnDActions.DEFS
  - requiresState                                      -> los `toggleState` declarados, que NO son
                                                          condiciones aunque se llamen "estados"

Salida: codigo 0 si no hay ninguna rota.
"""

import io
import os
import re
import sys
import glob

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _texto(rel):
    ruta = os.path.join(RAIZ, rel)
    if not os.path.exists(ruta):
        return ''
    return io.open(ruta, encoding='utf-8').read()


def _claves(rel, patron):
    """Los ids de primer nivel de una tabla de datos."""
    t = _texto(rel)
    m = re.search(patron, t)
    if not m:
        return set()
    resto = t[m.end():]
    fin = resto.find('\n}')
    return set(re.findall(r'\n    ([a-zA-Z_0-9]+)\s*=\s*\{', resto[:fin if fin > 0 else len(resto)]))


def main():
    condiciones = _claves('Harford/DnD/Engine/HarfordDnDConditions.lua', r'API\.DEFS\s*=\s*\{')
    recursos = _claves('Harford/DnD/State/HarfordDnDResources.lua', r'\.DEFS\s*=\s*\{')
    acciones = _claves('Harford/DnD/Data/HarfordDnDActions.lua', r'API\.DEFS\s*=\s*\{')

    # Si una tabla no se pudo leer, callarse es peor que avisar: sin ella, todas sus referencias
    # parecerian rotas y el aviso se volveria ruido que se aprende a ignorar.
    for nombre, conjunto in (('condiciones', condiciones), ('recursos', recursos), ('acciones', acciones)):
        if not conjunto:
            print('No se pudo leer la tabla de %s; no se comprueban sus referencias.' % nombre)

    fuentes = sorted(glob.glob(os.path.join(RAIZ, 'Harford', '**', '*.lua'), recursive=True)
                     + glob.glob(os.path.join(RAIZ, 'HarfordAdmin', '*.lua')))

    rotas = []
    declarados, requeridos = {}, {}

    for ruta in fuentes:
        rel = os.path.relpath(ruta, RAIZ).replace(os.sep, '/')
        crudo = io.open(ruta, encoding='utf-8').read()
        # Sin comentarios: documentar un id retirado no es referenciarlo.
        t = re.sub(r'--[^\n]*', '', crudo)

        if condiciones:
            for m in re.finditer(r'\b(conditionId|onWin)\s*=\s*"([a-z_0-9]+)"', t):
                if m.group(2) not in condiciones:
                    rotas.append((rel, m.group(1), m.group(2), 'condicion'))
            for m in re.finditer(r'\bselfCondition\s*=\s*\{\s*id\s*=\s*"([a-z_0-9]+)"', t):
                if m.group(1) not in condiciones:
                    rotas.append((rel, 'selfCondition', m.group(1), 'condicion'))
        if recursos:
            for m in re.finditer(r'\bresourceKey\s*=\s*"([a-z_0-9]+)"', t):
                if m.group(1) not in recursos:
                    rotas.append((rel, 'resourceKey', m.group(1), 'recurso'))
        if acciones:
            for m in re.finditer(r'grantsAsBonus\s*=\s*\{([^}]*)\}', t):
                for ident in re.findall(r'"([a-z_0-9]+)"', m.group(1)):
                    if ident not in acciones:
                        rotas.append((rel, 'grantsAsBonus', ident, 'accion'))

        for m in re.finditer(r'kind = "toggleState", state = "([a-z_0-9]+)"', t):
            declarados.setdefault(m.group(1), set()).add(rel)
        for m in re.finditer(r'requiresState = "([a-z_0-9]+)"', t):
            requeridos.setdefault(m.group(1), set()).add(rel)

    # Un `requiresState` que nadie declara con `toggleState` no se activa jamas, asi que el efecto
    # que lo pide no se aplica nunca. Es exactamente el fallo de las nueve condiciones.
    for estado in sorted(set(requeridos) - set(declarados)):
        for rel in sorted(requeridos[estado]):
            rotas.append((rel, 'requiresState', estado, 'estado activable'))

    # ── Funciones de modulo que no existen ──────────────────────────────────
    # `HarfordAlgo.Funcion(...)` donde `Funcion` no esta declarada en ninguna parte. No falla al
    # cargar: la llamada esta casi siempre tras un `and` que la da por ausente, asi que el codigo
    # sigue como si el modulo no estuviera y el efecto simplemente no ocurre.
    #
    # Dos casos reales el mismo dia: `HarfordDnDNet.ScheduleMyResourceBroadcast` (no existia; el
    # nombre era un local de otro fichero) y `HarfordClassColors.GetUnitColor` (se llama
    # `UnitColorRGB`, y ademas devuelve tres valores, no una tabla).
    declaradas = {}
    llamadas = {}
    for ruta in fuentes:
        rel = os.path.relpath(ruta, RAIZ).replace(os.sep, '/')
        t = io.open(ruta, encoding='utf-8').read()
        t = re.sub(r'--[^\n]*', '', t)
        # Los modulos declaran casi siempre con un ALIAS local (`local API = HarfordAlgo`), asi
        # que buscar solo `function HarfordAlgo.Foo` no encuentra nada y TODO parece roto. Es el
        # mismo error que ya se cometio en `dependencias.py` adivinando el alias por el fichero.
        alias = {}
        for m in re.finditer(r'local\s+(\w+)\s*=\s*(Harford\w+)\b', t):
            alias[m.group(1)] = m.group(2)
        for m in re.finditer(r'(\w+)\s*=\s*(Harford\w+)\s+or\s+\{\}', t):
            alias[m.group(1)] = m.group(2)

        # Todo lo que un modulo expone, por su nombre o por su alias.
        for m in re.finditer(r'\bfunction\s+(\w+)[.:](\w+)', t):
            modulo = alias.get(m.group(1), m.group(1))
            if modulo.startswith('Harford'):
                declaradas.setdefault(modulo, set()).add(m.group(2))
        for m in re.finditer(r'\b(\w+)\.(\w+)\s*=[^=]', t):
            modulo = alias.get(m.group(1), m.group(1))
            if modulo.startswith('Harford'):
                declaradas.setdefault(modulo, set()).add(m.group(2))
        # Y las llamadas.
        for m in re.finditer(r'\b(Harford\w+)\.(\w+)\s*\(', t):
            llamadas.setdefault((m.group(1), m.group(2)), set()).add(rel)

    # Un modulo del que no se ha visto NINGUNA declaracion no se puede juzgar: puede venir de otro
    # addon (HarfordAdmin, HarfordDebug) o construirse en runtime.
    for (modulo, nombre), donde in sorted(llamadas.items()):
        conocidas = declaradas.get(modulo)
        if not conocidas:
            continue
        if nombre in conocidas:
            continue
        for rel in sorted(donde):
            rotas.append((rel, 'llamada', modulo + '.' + nombre, 'funcion de modulo'))

    vistas, unicas = set(), []
    for rel, campo, ident, clase in rotas:
        clave = (campo, ident, clase)
        if clave in vistas:
            continue
        vistas.add(clave)
        unicas.append((rel, campo, ident, clase))

    print('Referencias a algo que no existe: %d' % len(unicas))
    for rel, campo, ident, clase in unicas:
        print('  %s: %s = "%s" (no hay ninguna %s con ese id)' % (rel, campo, ident, clase))
    return 1 if unicas else 0


if __name__ == '__main__':
    sys.exit(main())
