# -*- coding: utf-8 -*-
"""Construye la hoja de sprites de iconos que lleva el Yunque dentro.

Un selector visual necesita las imagenes, y no se pueden pedir a ningun servidor: la pagina
va sola. Meter los 19.347 iconos como imagenes sueltas serian 164 MB, muy por encima del
limite. Una hoja unica a 32 px los deja en un par de megas, y cada icono se recorta con
`background-position`.

Se priorizan los iconos que los objetos de la lista USAN de verdad; el resto rellena hasta
el cupo. Los que se queden fuera siguen buscandose por nombre, solo que sin miniatura.

Uso:
    python tools/codice/gen_yunque_iconos.py [--cupo 3000]
"""
import base64
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
CATALOGO = 'EpsilonIcons/epsilon_icons.json'
PAGINA = os.path.join(BASE, 'yunque.html')

LADO = 32          # tamano en la hoja
COLUMNAS = 48
CUPO = 3000
PREFIJOS = ('inv_', 'trade_', 'item_')


def nombresDelCatalogo():
    crudo = json.load(io.open(CATALOGO, encoding='utf-8'))
    if isinstance(crudo, dict):
        nombres = list(crudo)
    else:
        nombres = [x if isinstance(x, str) else (x.get('name') or '') for x in crudo]
    return sorted({n.lower() for n in nombres if n and n.lower().startswith(PREFIJOS)})


def usadosPorLaLista():
    if not os.path.exists(DATOS):
        return []
    t = io.open(DATOS, encoding='utf-8').read()
    return sorted(set(re.findall(r'icono = "([^"]+)"', t)))


def main():
    cupo = CUPO
    if '--cupo' in sys.argv:
        cupo = int(sys.argv[sys.argv.index('--cupo') + 1])

    catalogo = nombresDelCatalogo()
    usados = usadosPorLaLista()
    print("Catalogo util:            %d" % len(catalogo))
    print("Usados por los objetos:   %d" % len(usados))

    # Primero los que ya se usan, luego el resto del catalogo hasta llenar el cupo.
    orden, vistos = [], set()
    for n in usados + catalogo:
        if n in vistos:
            continue
        if os.path.exists(os.path.join(PNG, n + '.png')):
            vistos.add(n)
            orden.append(n)
        if len(orden) >= cupo:
            break
    print("En la hoja:               %d" % len(orden))

    filas = (len(orden) + COLUMNAS - 1) // COLUMNAS
    hoja = Image.new('RGBA', (COLUMNAS * LADO, filas * LADO), (0, 0, 0, 0))
    for i, n in enumerate(orden):
        try:
            im = Image.open(os.path.join(PNG, n + '.png')).convert('RGBA')
        except Exception:
            continue
        if im.size != (LADO, LADO):
            im = im.resize((LADO, LADO), Image.LANCZOS)
        hoja.paste(im, ((i % COLUMNAS) * LADO, (i // COLUMNAS) * LADO))

    buf = _io.BytesIO()
    # La paleta baja mucho el peso y para iconos de 32 px no se nota.
    hoja.convert('RGBA').quantize(colors=255, method=Image.FASTOCTREE).save(
        buf, format='PNG', optimize=True)
    datos = buf.getvalue()
    print("Hoja: %dx%d  ->  %.2f MB" % (hoja.size[0], hoja.size[1], len(datos) / 1024 / 1024))

    b64 = base64.b64encode(datos).decode('ascii')
    bloque = ('/*HOJA_INICIO*/const HOJA={lado:%d,columnas:%d,'
              'orden:%s,img:"data:image/png;base64,%s"};/*HOJA_FIN*/'
              % (LADO, COLUMNAS, json.dumps(orden, separators=(',', ':')), b64))

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
