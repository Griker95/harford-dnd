# -*- coding: utf-8 -*-
"""Construye la hoja de sprites de iconos que lleva el Yunque dentro.

Un selector visual necesita las imagenes, y no se pueden pedir a ningun servidor: la pagina
va sola. Sueltas serian 164 MB. Una hoja unica en WebP a 24 px las deja en poco mas de un
mega, y cada icono se recorta con `background-position`.

Van TODOS: 18.830 en una hoja de 3,8 MB. Lo que hacia lenta la pagina no era el numero de
iconos sino como se les daba la imagen -- ver el comentario de `montaHoja` en yunque.html --
y con eso resuelto el unico coste del catalogo completo es el peso del archivo. El cupo sigue
ahi por si algun dia se prefiere que abra antes.

Se meten primero los que los objetos USAN de verdad, y el resto se reparte por todo el
catalogo tomando uno de cada N -- por orden alfabetico solo entraba la A y la B. Los que se
queden fuera siguen buscandose por nombre, solo que sin miniatura.

Uso:
    python tools/codice/gen_yunque_iconos.py [--cupo 3000] [--lado 32]
"""
import base64
import csv
import math
import io as _io
import io
import json
import os
import re
import sys

from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
PNG = 'EpsilonIcons/png'
DATOS = 'AddonsIndependientes/HarfordItemForge/Data.lua'
# La lista canonica es la que alimenta la web: cada fila dice si el icono se pudo extraer, y
# solo esos tienen un PNG que servir. Incluye ademas los custom de Epsilon, que el volcado de
# nombres se dejaba fuera.
CATALOGO = 'EpsilonIcons/icons_master.csv'
PAGINA = os.path.join(BASE, 'yunque.html')

# 24 px es lo que permite meter el catalogo ENTERO por debajo del limite del artefacto.
# A 32 px habria que recortar, y recortar significaba quedarse con el principio del
# alfabeto: entraban inv_axe y inv_belt y no llegaba ni a inv_sword.
# El tamano de la hoja manda: la pagina calcula sola las celdas y los huecos a partir de
# `HOJA.lado`, asi que cambiarlo aqui es todo lo que hace falta.
#
# Cuesta peso, y crece con el CUADRADO del lado. Medido con el catalogo entero (18.830):
# 24 px = 6,0 MB de pagina | 28 px = 7,6 | 32 px = 9,7 | 50 px = 20,6, que NO CABE en el
# limite de 16 MB del artefacto. A 50 px hay que quedarse en unos 9.000 iconos.
LADO = 50
CUPO = 14400   # entran los 13.086 custom enteros
PREFIJOS = ('inv_', 'trade_', 'item_')


def nombresDelCatalogo():
    """Devuelve (custom, base). Van separados porque no se filtran igual.

    Los CUSTOM entran todos, se llamen como se llamen: son arte hecho a medida para este
    servidor y no hay donde buscarlos si faltan. Filtrarlos por prefijo dejaba fuera 3.793
    -- `inv-sword_53` con guion, `custom_*`, `smite_*`, `ivn_*` (un `inv` mal escrito)...

    A los BASE si se les aplica el prefijo: son los de Blizzard y ahi `spell_`/`ability_` es
    arte de hechizo, no de objeto, y solo estorba al buscar.
    """
    custom, base = set(), set()
    for f in csv.DictReader(io.open(CATALOGO, encoding='utf-8'), delimiter=';'):
        if f.get('estado') != 'extraido':
            continue
        n = f['nombre'].lower()
        if f.get('tipo') in ('custom', 'addon'):
            custom.add(n)
        elif n.startswith(PREFIJOS):
            base.add(n)
    return sorted(custom), sorted(base)


def usadosPorLaLista():
    if not os.path.exists(DATOS):
        return []
    t = io.open(DATOS, encoding='utf-8').read()
    # En minusculas SIEMPRE: la pagina normaliza asi lo que se escribe, y si la hoja guarda
    # `INV_Misc_Fish_01` la busqueda de `inv_misc_fish_01` no lo encontraria. En disco da
    # igual porque Windows no distingue mayusculas.
    return sorted({n.lower() for n in re.findall(r'icono = "([^"]+)"', t)})


def main():
    cupo, lado = CUPO, LADO
    if '--cupo' in sys.argv:
        cupo = int(sys.argv[sys.argv.index('--cupo') + 1])
    if '--lado' in sys.argv:
        lado = int(sys.argv[sys.argv.index('--lado') + 1])

    custom, base = nombresDelCatalogo()
    usados = usadosPorLaLista()
    print("Custom y de addon:        %d  (entran todos)" % len(custom))
    print("De Blizzard utiles:       %d" % len(base))
    print("Usados por los objetos:   %d" % len(usados))

    # Primero los que ya se usan. El resto NO por orden alfabetico: asi solo entraba el
    # principio del abecedario (inv_axe, inv_belt) y no se llegaba ni a inv_sword. Se toma
    # uno de cada N para que el cupo quede repartido por todo el catalogo.
    orden, vistos = [], set()
    def mete(n):
        if n in vistos or not os.path.exists(os.path.join(PNG, n + '.png')):
            return False
        vistos.add(n)
        orden.append(n)
        return True

    for n in usados:
        mete(n)
    # Los custom van DESPUES de los usados y ANTES que los de Blizzard: si hay que recortar,
    # que se recorte de lo que se puede mirar en cualquier base de datos de WoW.
    for n in custom:
        mete(n)
        if cupo and len(orden) >= cupo:
            break
    resto = [n for n in base if n not in vistos]
    if cupo and len(resto) > cupo - len(orden) > 0:
        paso = len(resto) / float(cupo - len(orden))
        resto = [resto[int(i * paso)] for i in range(cupo - len(orden))]
    for n in resto:
        mete(n)
        if cupo and len(orden) >= cupo:
            break
    print("En la hoja:               %d" % len(orden))

    # Cuadrada a proposito: WebP no admite mas de 16.383 px por lado, y una hoja estrecha y
    # muy alta se pasa en cuanto crece el icono. Cuadrada aprovecha el margen por los dos.
    columnas = int(math.ceil(math.sqrt(len(orden)))) if orden else 1
    filas = (len(orden) + columnas - 1) // columnas
    if max(columnas, filas) * lado > 16383:
        print("AVISO: la hoja se pasa del limite de WebP (16.383 px). Baja el cupo o el lado.")
        return 1
    hoja = Image.new('RGBA', (columnas * lado, filas * lado), (0, 0, 0, 0))
    for i, n in enumerate(orden):
        try:
            im = Image.open(os.path.join(PNG, n + '.png')).convert('RGBA')
        except Exception:
            continue
        if im.size != (lado, lado):
            im = im.resize((lado, lado), Image.LANCZOS)
        hoja.paste(im, ((i % columnas) * lado, (i // columnas) * lado))

    buf = _io.BytesIO()
    # WebP con transparencia: a 24 px no se distingue del PNG y pesa bastante menos, que
    # aqui es lo unico que decide si la pagina abre rapido.
    hoja.save(buf, format='WEBP', quality=60, method=5)
    datos = buf.getvalue()
    print("Hoja: %dx%d  ->  %.2f MB (webp)"
          % (hoja.size[0], hoja.size[1], len(datos) / 1024 / 1024))

    b64 = base64.b64encode(datos).decode('ascii')
    bloque = ('/*HOJA_INICIO*/const HOJA={lado:%d,columnas:%d,'
              'orden:%s,img:"data:image/webp;base64,%s"};/*HOJA_FIN*/'
              % (lado, columnas, json.dumps(orden, separators=(',', ':')), b64))

    pagina = io.open(PAGINA, encoding='utf-8').read()
    nueva, n = re.subn(r'/\*HOJA_INICIO\*/.*?/\*HOJA_FIN\*/', lambda _: bloque,
                       pagina, count=1, flags=re.S)
    if not n:
        print("Faltan las marcas HOJA_INICIO / HOJA_FIN en yunque.html")
        return 1
    io.open(PAGINA, 'w', encoding='utf-8', newline='').write(nueva)
    print()
    print("Escrito %s  (%.1f MB)" % (PAGINA, len(nueva) / 1024 / 1024))
    if len(nueva) > 15 * 1024 * 1024:
        print("AVISO: cerca del limite de 16 MB del artefacto. Baja el cupo.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
