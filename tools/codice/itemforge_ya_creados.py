# -*- coding: utf-8 -*-
"""Busca objetos custom que YA existan, para no forjarlos dos veces.

Crear un objeto duplicado en Epsilon no se deshace, y el servidor no tiene comando para
buscar por nombre. Pero cada vez que un objeto custom aparece en el chat deja su enlace, y
los addons de registro (Elephant) guardan ese chat en las SavedVariables. Ahi queda el
rastro: `|Hitem:14074575:...|h[Barra de cobre]|h`.

Se rastrea todo el WTF, se cruza por NOMBRE con la lista de HarfordItemForge y se avisa de
lo que ya parece existir. No es una verdad absoluta -- solo ve lo que paso por el chat --
pero es el unico rastro disponible y evita los duplicados mas probables.

Uso:
    python tools/codice/itemforge_ya_creados.py
    python tools/codice/itemforge_ya_creados.py --saltar   escribe los hallados como saltados
"""
import io
import json
import os
import re
import sys
import unicodedata

sys.stdout.reconfigure(encoding='utf-8')

WTF = 'G:/Epsilon/_retail_/WTF'
DATOS = 'AddonsIndependientes/HarfordItemForge/Data.lua'
# El otro chat saco los datos de profesiones a su propio addon (commit 3133ccb). Si
# vuelven a moverse, es esta linea la que hay que tocar.
REGISTRO = 'HarfordProfesiones/HarfordProfesionesItems.lua'
SALIDA = 'tools/codice/_itemforge_ya_creados.json'

# Los objetos custom de Epsilon viven en el rango de 8 cifras que empieza por 14.
ENLACE = re.compile(r'Hitem:(14\d{6})[:0-9]*\|h\[([^\]]{1,80})\]')
MIN_CUSTOM = 14000000


def sinTildes(t):
    t = unicodedata.normalize('NFD', t or '')
    return ''.join(c for c in t if unicodedata.category(c) != 'Mn').lower().strip()


def rastrea():
    """id -> nombre, de todo lo custom que alguna vez paso por el chat."""
    vistos, archivos = {}, 0
    for raiz, _, ficheros in os.walk(WTF):
        for f in ficheros:
            if not f.endswith('.lua'):
                continue
            ruta = os.path.join(raiz, f)
            try:
                texto = io.open(ruta, encoding='utf-8', errors='replace').read()
            except (OSError, MemoryError):
                continue
            archivos += 1
            for id_, nombre in ENLACE.findall(texto):
                n = int(id_)
                if n >= MIN_CUSTOM:
                    vistos.setdefault(n, nombre)
    return vistos, archivos


def main():
    saltar = '--saltar' in sys.argv

    vistos, archivos = rastrea()
    print("Rastreados %d archivos del WTF." % archivos)
    print("Objetos custom vistos alguna vez en el chat: %d" % len(vistos))
    if vistos:
        ids = sorted(vistos)
        print("   rango de ids: %d .. %d" % (ids[0], ids[-1]))
    print()

    # Los que el registro ya da por creados
    yaEnRegistro = set()
    if os.path.exists(REGISTRO):
        for m in re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{[^}]*\bid\s*=\s*(\d+)',
                             io.open(REGISTRO, encoding='utf-8').read()):
            yaEnRegistro.add(int(m.group(2)))
    print("Ids ya apuntados en HarfordProfessionsItems: %d" % len(yaEnRegistro))

    porNombre = {}
    for id_, nombre in vistos.items():
        porNombre.setdefault(sinTildes(nombre), []).append(id_)

    texto = io.open(DATOS, encoding='utf-8').read()
    items = re.findall(r'clave = "([^"]+)", nombre = "([^"]+)"', texto)

    sospechosos = {}
    for clave, nombre in items:
        encontrados = porNombre.get(sinTildes(nombre))
        if encontrados:
            nuevos = [i for i in encontrados if i not in yaEnRegistro]
            if nuevos:
                sospechosos[clave] = {'nombre': nombre, 'ids': sorted(nuevos)}

    print()
    if not sospechosos:
        print("Ninguno de los %d pendientes aparece ya creado. Via libre." % len(items))
    else:
        print("|  %d de los %d pendientes YA parecen existir:" % (len(sospechosos), len(items)))
        for clave, d in sorted(sospechosos.items())[:20]:
            print("|     %-34s %s" % (d['nombre'][:34], ', '.join(str(i) for i in d['ids'])))
        if len(sospechosos) > 20:
            print("|     ... y %d mas" % (len(sospechosos) - 20))
        io.open(SALIDA, 'w', encoding='utf-8', newline='').write(
            json.dumps(sospechosos, ensure_ascii=False, indent=1) + "\n")
        print()
        print("Escrito %s" % SALIDA)
        if saltar:
            print("Pasale ese archivo a /hforge saltar, o revisalos uno a uno antes.")

    print()
    print("AVISO: esto solo ve lo que paso por el chat. Un objeto creado sin que su enlace")
    print("se llegara a mostrar no deja rastro, asi que la primera tanda conviene hacerla")
    print("corta y comprobar con /hforge revisar.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
