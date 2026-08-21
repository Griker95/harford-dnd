# -*- coding: utf-8 -*-
"""Saca la informacion de los objetos de la captura de Wowhead que ya esta en disco.

`cotejo/objetos_wowhead.json` se bajo en una tanda anterior del pipeline del codice y trae
2087 fichas con calidad, tamano de pila y lineas de tooltip. Aqui se cruzan con la lista de
HarfordItemForge por NOMBRE y se escribe lo aprovechable en la capa de anulaciones.

Que se toma y que no:

  display   el id del objeto original de WoW. `.forge item set display` copia de ahi
            modelo y textura, que es lo que hace que un arma forjada se VEA como un arma.
  calidad   la de Wowhead, que es la real del objeto original.
  apilable  el `Carga max` de la ficha; si no lo dice, no se toca lo deducido.
  desc      SOLO el efecto de uso. El resto de lineas del tooltip son ruido que el propio
            servidor ya calcula (nivel de objeto, precio de venta, requisito de nivel) y
            meterlas como descripcion daria objetos con texto falso.

Sin --aplicar solo informa. Nunca pisa un campo ya afinado a mano: eso lo decide
importar_itemforge.py, que es quien escribe.

Uso:
    python tools/codice/itemforge_desde_wowhead.py
    python tools/codice/itemforge_desde_wowhead.py --aplicar
"""
import io
import json
import os
import re
import subprocess
import sys
import unicodedata

sys.stdout.reconfigure(encoding='utf-8')

BASE = os.path.dirname(os.path.abspath(__file__))
WOWHEAD = os.path.join(BASE, 'cotejo', 'objetos_wowhead.json')
DATOS = 'AddonsIndependientes/HarfordItemForge/Data.lua'
PUENTE = os.path.join(BASE, '_itemforge_desde_wowhead.json')

# Lineas que el servidor ya calcula o que no describen nada.
RUIDO = re.compile(
    r'^(nivel de objeto|carga max|precio de venta|se vende por|necesitas ser de nivel|'
    r'requiere nivel|dura(cion)?:|unico|ligado|nivel \d)', re.I)

# El limite del comando de descripcion deja unos 180 caracteres utiles.
MAX_DESC = 180


def sinTildes(t):
    t = unicodedata.normalize('NFD', t or '')
    return ''.join(c for c in t if unicodedata.category(c) != 'Mn').lower().strip()


def descripcionDe(ficha):
    """El efecto de uso, limpio. Si no hay, no se inventa nada."""
    for texto in (ficha.get('effects') or []):
        limpio = ' '.join((texto or '').split())
        if not limpio or RUIDO.match(sinTildes(limpio)):
            continue
        if len(limpio) > MAX_DESC:
            # Se corta por frase, no a mitad de palabra.
            corte = limpio.rfind('.', 0, MAX_DESC)
            limpio = limpio[:corte + 1] if corte > 60 else limpio[:MAX_DESC].rsplit(' ', 1)[0]
        return limpio
    return None


def main():
    aplicar = '--aplicar' in sys.argv

    if not os.path.exists(WOWHEAD):
        print("No existe %s" % WOWHEAD)
        return 1
    wh = json.load(io.open(WOWHEAD, encoding='utf-8'))
    porNombre = {}
    for idOriginal, ficha in wh.items():
        # El id de WoW es la CLAVE del json, y sirve para copiarle el modelo al forjado.
        ficha = dict(ficha, _id=int(idOriginal))
        for campo in ('name', 'classicName'):
            if ficha.get(campo):
                porNombre.setdefault(sinTildes(ficha[campo]), ficha)

    texto = io.open(DATOS, encoding='utf-8').read()
    items = re.findall(r'clave = "([^"]+)", nombre = "([^"]+)"', texto)

    salida = {}
    sinFicha, conDesc, conCalidad, conPila, conDisplay = [], 0, 0, 0, 0
    for clave, nombre in items:
        ficha = porNombre.get(sinTildes(nombre))
        if not ficha:
            sinFicha.append(nombre)
            continue
        campos = {}
        if ficha.get('_id'):
            # `.forge item set display <enlace> <id>` copia modelo y textura del original.
            campos['display'] = ficha['_id']
            conDisplay += 1
        if ficha.get('quality') is not None:
            campos['calidad'] = int(ficha['quality'])
            conCalidad += 1
        if ficha.get('pila'):
            campos['apilable'] = int(ficha['pila'])
            conPila += 1
        desc = descripcionDe(ficha)
        if desc:
            campos['desc'] = desc
            conDesc += 1
        if campos:
            salida[clave] = campos

    print("Objetos en la lista:        %d" % len(items))
    print("Con ficha de Wowhead:       %d  (%.0f%%)"
          % (len(items) - len(sinFicha), 100.0 * (len(items) - len(sinFicha)) / len(items)))
    print()
    print("Se puede rellenar:")
    print("   calidad:      %d" % conCalidad)
    print("   apilable:     %d" % conPila)
    print("   display:      %d   (modelo 3D del objeto original)" % conDisplay)
    print("   descripcion:  %d   (solo los que tienen efecto de uso)" % conDesc)
    print()
    print("Sin ficha, quedan a mano:   %d" % len(sinFicha))
    for n in sinFicha[:8]:
        print("   %s" % n)
    if len(sinFicha) > 8:
        print("   ... y %d mas" % (len(sinFicha) - 8))

    if not aplicar:
        print()
        print("Nada escrito. Vuelve a lanzarlo con --aplicar.")
        return 0

    io.open(PUENTE, 'w', encoding='utf-8', newline='').write(
        json.dumps(salida, ensure_ascii=False, indent=1) + "\n")
    print()
    print("Escrito el puente %s" % PUENTE)
    # Se delega en el importador, que es quien sabe respetar lo ya afinado.
    subprocess.run([sys.executable, os.path.join(BASE, 'importar_itemforge.py'), PUENTE],
                   check=False)
    return 0


if __name__ == '__main__':
    sys.exit(main())
