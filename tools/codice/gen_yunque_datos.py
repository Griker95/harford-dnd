# -*- coding: utf-8 -*-
"""Mete en el Yunque los datos del proyecto que necesita para validar y para editar.

Sin esto la pagina solo sabe crear cosas nuevas a ciegas. Con esto puede:

  * EDITAR los objetos que ya estan en la lista, que es donde esta el trabajo que queda
    (1.198 sin descripcion) en vez de empezar siempre en blanco.
  * AUTOCOMPLETAR claves de objeto al escribir una receta. Los materiales y el resultado se
    referencian por CLAVE, y una clave que no existe deja la receta como "pendiente" para
    siempre sin decir nada. Es el mismo problema que el icono inexistente.
  * AVISAR de identificadores repetidos, tanto de objeto como de receta.

Se inyecta entre /*DATOS_INICIO*/ y /*DATOS_FIN*/.

Uso:
    python tools/codice/gen_yunque_datos.py
"""
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
REGISTRO = 'HarfordProfesiones/HarfordProfesionesItems.lua'
RECETAS = 'HarfordProfesiones/HarfordProfesiones.lua'
PENDIENTES = 'AddonsIndependientes/HarfordItemForge/Data.lua'
PAGINA = os.path.join(BASE, 'yunque.html')


def registro():
    """clave -> (nombre, id). El id importa: en las recompensas de mision, el addon
    resuelve nombre, enlace e icono a partir de el (`FormatRewardItemForText`)."""
    if not os.path.exists(REGISTRO):
        return {}
    t = io.open(REGISTRO, encoding='utf-8').read()
    salida = {}
    for m in re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{([^}]*)\}', t):
        nom = re.search(r'name\s*=\s*"([^"]*)"', m.group(2))
        idm = re.search(r'\bid\s*=\s*(\d+)', m.group(2))
        salida[m.group(1)] = (nom.group(1) if nom else m.group(1),
                              int(idm.group(1)) if idm else 0)
    return salida


CATEGORIAS = 'Harford/Contracts/HarfordContractsData.lua'


def categorias():
    """`category` NO es texto libre: se resuelve con `GetTypeByKey` contra estas."""
    if not os.path.exists(CATEGORIAS):
        return []
    t = io.open(CATEGORIAS, encoding='utf-8').read()
    return re.findall(r'key = "(\w+)",\s*label = "([^"]+)"', t)


def profesiones():
    if not os.path.exists(RECETAS):
        return []
    t = io.open(RECETAS, encoding='utf-8').read()
    out = []
    for m in re.finditer(
            r'\{\s*id\s*=\s*"(prof_[a-z_]+)",\s*name\s*=\s*"([^"]*)".*?'
            r'kind\s*=\s*"([a-z]+)".*?icon\s*=\s*"([^"]*)"', t):
        out.append([m.group(1), m.group(2), m.group(3), m.group(4).lower()])
    return out


def idsDeReceta():
    return [r[0] for r in recetasConNivel()]


def recetasConNivel():
    """[id, profesion, skillReq, nombre]. El nivel es lo que decide QUE ENTRENADOR la ensena:
    los entrenadores no son una lista, se deducen del par (profesion, rango) y cada receta
    cae en un rango por su `skillReq`."""
    if not os.path.exists(RECETAS):
        return []
    t = io.open(RECETAS, encoding='utf-8').read()
    out = []
    for m in re.finditer(
            r'\{\s*id\s*=\s*"([a-z0-9_]+)",\s*profession\s*=\s*"([a-z_]+)",'
            r'\s*skillReq\s*=\s*(\d+),\s*name\s*=\s*"([^"]*)"', t):
        out.append([m.group(1), m.group(2), int(m.group(3)), m.group(4)])
    return sorted(out)


def rangos():
    """Los cinco rangos con su minimo, de HarfordProfessions."""
    p = 'HarfordProfesiones/HarfordProfesiones.lua'
    if not os.path.exists(p):
        return []
    t = io.open(p, encoding='utf-8').read()
    m = re.search(r'API\.TIERS = \{(.*?)\n\}', t, re.S)
    if not m:
        return []
    return [[n, int(v)] for n, v in
            re.findall(r'name = "(\w+)",\s*min = (\d+)', m.group(1))]


WOWHEAD = os.path.join(BASE, 'cotejo', 'objetos_wowhead.json')


def objetosDeWow():
    """id de WoW -> nombre. `outfit equip` toma el ID DEL OBJETO (negativo = displayid),
    asi que con esto se puede vestir a un NPC buscando por nombre en vez de a ciegas."""
    if not os.path.exists(WOWHEAD):
        return []
    wh = json.load(io.open(WOWHEAD, encoding='utf-8'))
    out = []
    for idOriginal, ficha in wh.items():
        nombre = ficha.get('name') or ficha.get('classicName')
        if nombre:
            out.append([int(idOriginal), nombre])
    return sorted(out)


ITEMS_LUA = 'Harford/DnD/State/HarfordDnDItems.lua'
ARMAS_LUA = 'Harford/DnD/Data/HarfordDnDWeapons.lua'


def reglasDeObjeto():
    """Las etiquetas que el parser de descripcion reconoce DE VERDAD.

    `HarfordDnDItems` lee la descripcion del objeto linea a linea y solo aplica como
    mecanica las que casan con una etiqueta conocida. Si el Yunque ofreciera etiquetas
    inventadas, el objeto saldria bonito y sin dar nada, y no habria forma de notarlo desde
    el juego. Por eso salen de ahi y no de una lista escrita a mano.
    """
    if not os.path.exists(ITEMS_LUA):
        return {}
    t = io.open(ITEMS_LUA, encoding='utf-8').read()

    def valores(nombre):
        m = re.search(r'local %s = \{(.*?)\n\}' % nombre, t, re.S)
        if not m:
            return []
        return sorted(set(re.findall(r'= "([^"]+)"', m.group(1))))

    # De RULE_LABELS interesa la etiqueta que se escribe, no la clave interna: se toman las
    # formas mas legibles de cada regla.
    reglas = [
        ["CA", "armorClass", "bonus"],
        ["Armadura", "armorClass", "absoluto"],
        ["Iniciativa", "initiative", "bonus"],
        ["Ataque", "weaponAttack", "bonus"],
        ["Daño", "weaponDamage", "bonus"],
        ["Ataque conjuro", "spellAttack", "bonus"],
        ["CD conjuro", "spellDC", "bonus"],
    ]
    return {
        'reglas': reglas,
        'caracteristicas': valores('ABILITY_ALIASES'),
        'habilidades': valores('SKILL_ALIASES'),
        'tiposDano': valores('DAMAGE_TYPE_ALIASES'),
    }


def armasDnD():
    if not os.path.exists(ARMAS_LUA):
        return []
    t = io.open(ARMAS_LUA, encoding='utf-8').read()
    return re.findall(r'key="([^"]+)"', t)


def pendientes():
    """Los objetos de la lista, en forma compacta para poder editarlos."""
    if not os.path.exists(PENDIENTES):
        return []
    t = io.open(PENDIENTES, encoding='utf-8').read()
    # Los campos opcionales (display, displayid, additem) van en lineas sueltas detras.
    trozos = re.findall(r'\{ clave = "(.*?)\n    \},', t, re.S)
    salida = []
    for tr in trozos:
        cuerpo = '{ clave = "' + tr
        def campo(n, por_defecto=None):
            m = re.search(r'\b%s = (-?\d+)' % n, cuerpo)
            return int(m.group(1)) if m else por_defecto
        def texto(n):
            m = re.search(r'\b%s = "((?:[^"\\]|\\.)*)"' % n, cuerpo)
            return m.group(1) if m else ""
        salida.append([
            texto('clave'), texto('nombre'), texto('prof'), texto('papel'), texto('icono'),
            campo('calidad', 1), campo('clase', 15), campo('subclase', 0), campo('hueco', 0),
            campo('apilable', 1), campo('vinculacion', 0), texto('desc'),
            campo('display', 0), campo('displayid', 0),
        ])
    return salida


def main():
    reg = registro()
    profs = profesiones()
    recetas = idsDeReceta()
    pend = pendientes()

    print("Registro de objetos:  %d claves" % len(reg))
    print("Profesiones:          %d" % len(profs))
    print("Recetas existentes:   %d ids" % len(recetas))
    print("Categorias de contrato:%d" % len(categorias()))
    print("Objetos de WoW:       %d  (para vestir NPCs)" % len(objetosDeWow()))
    r = reglasDeObjeto()
    print("Reglas de objeto:     %d etiquetas, %d habilidades, %d tipos de dano"
          % (len(r.get("reglas", [])), len(r.get("habilidades", [])),
             len(r.get("tiposDano", []))))
    print("Armas D&D:            %d" % len(armasDnD()))
    print("Rangos de profesion:  %d" % len(rangos()))
    print("Objetos pendientes:   %d  (editables desde la pagina)" % len(pend))
    sinDesc = sum(1 for p in pend if not p[11])
    print("   de esos sin descripcion: %d" % sinDesc)

    datos = {
        'registro': [[k, v[0], v[1]] for k, v in sorted(reg.items())],
        'profs': profs,
        'recetaIds': recetas,
        'pendientes': pend,
        'categorias': categorias(),
        'wow': objetosDeWow(),
        'reglas': reglasDeObjeto(),
        'armasDnD': armasDnD(),
        'recetas': recetasConNivel(),
        'rangos': rangos(),
    }
    bloque = ('/*DATOS_INICIO*/const DATOS=%s;/*DATOS_FIN*/'
              % json.dumps(datos, separators=(',', ':'), ensure_ascii=False))

    pagina = io.open(PAGINA, encoding='utf-8').read()
    nueva, n = re.subn(r'/\*DATOS_INICIO\*/.*?/\*DATOS_FIN\*/', lambda _: bloque,
                       pagina, count=1, flags=re.S)
    if not n:
        print("Faltan las marcas DATOS_INICIO / DATOS_FIN en yunque.html")
        return 1
    io.open(PAGINA, 'w', encoding='utf-8', newline='').write(nueva)
    print()
    print("Datos embebidos: %.0f KB" % (len(bloque.encode('utf-8')) / 1024))
    print("Escrito %s  (%.1f MB)" % (PAGINA, len(nueva) / 1024 / 1024))
    return 0


if __name__ == '__main__':
    sys.exit(main())
