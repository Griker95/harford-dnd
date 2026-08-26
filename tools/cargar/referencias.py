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

    # ── Locales huerfanas al extraer un modulo ──────────────────────────────
    # Un nombre que en OTRO fichero del proyecto es `local`, usado aqui sin declararlo: es lo que
    # queda cuando se saca una funcion a su propio modulo y su dependencia se deja atras. No falla
    # al cargar -- resuelve a nil -- y casi siempre esta detras de un `and` que la da por ausente,
    # asi que el guardia entero se vuelve mudo.
    #
    # Cuatro veces el mismo dia: `IconPath` (la barra de accion no pintaba nada), `SheetContext`
    # (un DM con ficha de NPC gastaba sus propios recursos), `damageType` (el dano viajaba sin tipo
    # y saltaba todas las resistencias) y `GetUnitColor` (que ni existia).
    #
    # Se comparan CONJUNTOS, no una regex por nombre: con 134 ficheros y miles de identificadores,
    # buscar uno a uno tardaba minutos.
    RE_DECL = re.compile(r'\blocal\s+(?:function\s+)?([A-Za-z_][\w,\s]*?)\s*[=({\n]')
    RE_PARAM = re.compile(r'function[^(\n]*\(([^)]*)\)')
    RE_FOR = re.compile(r'\bfor\s+([A-Za-z_][\w,\s]*?)\s*(?:=|\bin\b)')
    RE_GLOBAL = re.compile(r'^\s*([A-Za-z_]\w*)\s*=[^=]', re.M)
    # Usado como funcion, tabla o indice -- `x(`, `x.`, `x[` -- y NO precedido de punto o dos
    # puntos, que serian un campo de otra tabla.
    RE_USO = re.compile(r'(?<![\w.:])([A-Za-z_]\w*)\s*[.(\[]')

    def nombres(cadena):
        return {x.strip() for x in cadena.split(',') if x.strip()}

    info = {}
    for ruta in fuentes:
        rel = os.path.relpath(ruta, RAIZ).replace(os.sep, '/')
        t2 = re.sub(r'--[^\n]*', '', io.open(ruta, encoding='utf-8').read())
        # Sin CADENAS: una descripcion que dice "...Correr, Desengancharse o Ayudar." deja
        # `Ayudar.` en el texto y la regex de uso lo tomaba por un acceso a tabla. Tres de los
        # cuatro hallazgos iniciales eran exactamente eso.
        t2 = re.sub(r'"(?:\\.|[^"\\])*"', '""', t2)
        t2 = re.sub(r"'(?:\\.|[^'\\])*'", "''", t2)
        # Cadenas largas con cualquier numero de `=`: `HarfordDnDBookText` usa `[====[`.
        t2 = re.sub(r'\[(=*)\[.*?\]\1\]', '[[]]', t2, flags=re.S)
        declara = set()
        for m in RE_DECL.finditer(t2):
            declara |= nombres(m.group(1))
        propios = set(declara)
        for m in RE_PARAM.finditer(t2):
            propios |= nombres(m.group(1))
        for m in RE_FOR.finditer(t2):
            propios |= nombres(m.group(1))
        propios |= set(RE_GLOBAL.findall(t2))
        info[rel] = (declara, propios, set(RE_USO.findall(t2)))

    # De quien es local cada nombre.
    duenos = {}
    for rel, (declara, _, _) in info.items():
        for n in declara:
            duenos.setdefault(n, set()).add(rel)

    # Se acota a nombres DISTINTIVOS. Sin acotar salian 211 hallazgos y todos eran ruido: `aura`,
    # `target`, `activo`... son locales en algun fichero y locales tambien aqui, y cualquier forma
    # de declaracion que la regex no cubra se convierte en un falso positivo. Un detector con 211
    # falsos positivos entrena a ignorarlo, que es peor que no tenerlo.
    #
    # El filtro: empieza en MAYUSCULA (convencion del proyecto para funciones y modulos), al menos
    # cinco letras, y es local en UN SOLO fichero. Eso deja fuera `damageType` -- que empieza en
    # minuscula -- pero caza el patron que se ha repetido: una funcion o una tabla que se quedo
    # atras al extraer un modulo.
    for rel, (_, propios, usados) in info.items():
        for n in sorted(usados & set(duenos)):
            if n in propios or rel in duenos[n]:
                continue
            if len(n) < 5 or not n[0].isupper() or len(duenos[n]) != 1:
                continue
            rotas.append((rel, 'global', n, 'local de ' + sorted(duenos[n])[0]))

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
