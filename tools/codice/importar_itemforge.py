# -*- coding: utf-8 -*-
"""Vuelca informacion de la web a la capa de anulaciones de HarfordItemForge.

La lista de objetos NO se escribe a mano: se genera. Este script es la puerta por la que
entra lo que la web sabe y el generador no puede deducir -- descripciones, sobre todo --
sin pisar nada de lo que ya se hubiera afinado.

Uso:
    python tools/codice/importar_itemforge.py <archivo.json> [--pisar]

El archivo de entrada admite dos formas:

    {"clave": "texto de la descripcion", ...}
    {"clave": {"desc": "...", "calidad": 3}, ...}

Tambien acepta una lista de objetos con `key`/`clave`/`id` y `desc`/`description`, que es
la forma en que suele exportarse el codice.

Por defecto NO sobreescribe un campo que ya existiera en las anulaciones: lo afinado a mano
manda sobre una reimportacion. Con --pisar se invierte esa regla.
"""
import io
import json
import os
import sys
import unicodedata

sys.stdout.reconfigure(encoding='utf-8')

ANULACIONES = 'tools/codice/itemforge_anulaciones.json'
DATOS = 'AddonsIndependientes/HarfordItemForge/Data.lua'
CAMPOS = {'nombre', 'icono', 'calidad', 'clase', 'subclase', 'hueco', 'apilable',
          'vinculacion', 'desc', 'additem'}


def sinTildes(t):
    t = unicodedata.normalize('NFD', t or '')
    return ''.join(c for c in t if unicodedata.category(c) != 'Mn').lower().strip()


def clavesConocidas():
    """Las claves que existen de verdad, para no importar sobre nombres inventados."""
    import re
    if not os.path.exists(DATOS):
        return None, None
    texto = io.open(DATOS, encoding='utf-8').read()
    porClave, porNombre = set(), {}
    for c, n in re.findall(r'clave = "([^"]+)", nombre = "([^"]+)"', texto):
        porClave.add(c)
        porNombre.setdefault(sinTildes(n), c)
    return porClave, porNombre


def normaliza(entrada):
    """Reduce cualquiera de las formas admitidas a {clave: {campo: valor}}."""
    salida = {}
    if isinstance(entrada, list):
        for fila in entrada:
            if not isinstance(fila, dict):
                continue
            clave = fila.get('clave') or fila.get('key') or fila.get('id')
            if not clave:
                continue
            campos = {k: v for k, v in fila.items() if k in CAMPOS}
            desc = fila.get('desc') or fila.get('description')
            if desc:
                campos['desc'] = desc
            if campos:
                salida[clave] = campos
        return salida

    for clave, valor in (entrada or {}).items():
        if clave.startswith('_'):
            continue
        if isinstance(valor, str):
            salida[clave] = {'desc': valor}
        elif isinstance(valor, dict):
            campos = {k: v for k, v in valor.items() if k in CAMPOS}
            desc = valor.get('desc') or valor.get('description')
            if desc:
                campos['desc'] = desc
            if campos:
                salida[clave] = campos
    return salida


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    pisar = '--pisar' in sys.argv
    if not args:
        print(__doc__)
        return 1

    origen = args[0]
    if not os.path.exists(origen):
        print("No existe %s" % origen)
        return 1

    entrantes = normaliza(json.load(io.open(origen, encoding='utf-8')))
    print("Leidas %d entradas de %s" % (len(entrantes), origen))

    porClave, porNombre = clavesConocidas()
    if porClave:
        # Una entrada puede venir con el nombre visible en vez de la clave.
        arregladas, desconocidas = {}, []
        for clave, campos in entrantes.items():
            if clave in porClave:
                arregladas[clave] = campos
            elif sinTildes(clave) in porNombre:
                arregladas[porNombre[sinTildes(clave)]] = campos
            else:
                desconocidas.append(clave)
        entrantes = arregladas
        if desconocidas:
            print("|  %d sin clave conocida, se ignoran:" % len(desconocidas))
            for d in desconocidas[:10]:
                print("|     %s" % d)

    actuales = {}
    if os.path.exists(ANULACIONES):
        actuales = json.load(io.open(ANULACIONES, encoding='utf-8'))
    nota = actuales.pop('_nota', None)

    nuevas, actualizadas, respetadas = 0, 0, 0
    for clave, campos in entrantes.items():
        destino = actuales.setdefault(clave, {})
        if not destino:
            nuevas += 1
        for campo, valor in campos.items():
            if campo in destino and not pisar:
                if destino[campo] != valor:
                    respetadas += 1
                continue
            if destino.get(campo) != valor:
                actualizadas += 1
            destino[campo] = valor

    salida = {}
    if nota:
        salida['_nota'] = nota
    for clave in sorted(actuales):
        salida[clave] = actuales[clave]

    io.open(ANULACIONES, 'w', encoding='utf-8', newline='').write(
        json.dumps(salida, ensure_ascii=False, indent=2) + "\n")

    print("Claves nuevas: %d   campos escritos: %d" % (nuevas, actualizadas))
    if respetadas:
        print("Campos ya afinados que se han respetado: %d  (--pisar para forzarlos)"
              % respetadas)
    print("Escrito %s" % ANULACIONES)
    print("Ahora: python tools/codice/gen_itemforge_data.py")
    return 0


if __name__ == '__main__':
    sys.exit(main())
