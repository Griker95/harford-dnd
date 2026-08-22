# -*- coding: utf-8 -*-
"""Descarga el FrameXML de Blizzard de la build del cliente y lo deja legible.

POR QUE: la sonda `nativeprobe` ve el RESULTADO ya calculado de un frame; el XML ve la
DECLARACION. Sin el XML se acaba deduciendo mal cosas que no se pueden ver: que un texCoord
mayor que 1 significa mosaico y no un recorte, que un SetTexCoord sobre un atlas lo anula, que
un inset usa `useParentLevel`, o que media UI son PLANTILLAS heredadas y no arte suelto.

El cliente de Epsilon es Shadowlands 9.2.7 build 45745 (el `Interface: 45745` del toc es
literalmente esa build), y ese codigo esta publicado con esa etiqueta exacta.

Uso:
    python tools/codice/fetch_framexml.py                 # los frames que ya replicamos
    python tools/codice/fetch_framexml.py SpellBookFrame CharacterFrame
    python tools/codice/fetch_framexml.py --list          # que hay descargado

Los ficheros van a RuleSource/framexml/ (fuera de git, como el resto de material externo).
Este script SI esta en git: cualquiera puede regenerarlos.
"""
import argparse
import io
import os
import sys
import subprocess

sys.stdout.reconfigure(encoding='utf-8')

BUILD = '45745'          # Shadowlands 9.2.7, la build del cliente de Epsilon
TAG = '9.2.7'
OUT_DIR = os.path.join('RuleSource', 'framexml')

GITHUB = 'https://raw.githubusercontent.com/Gethe/wow-ui-source/%s/Interface/%s'
TOWNLONG = 'https://www.townlong-yak.com/framexml/%s/%s'

# Frames que replicamos hoy -> ruta dentro de Interface/ en el repo de Blizzard.
# Al añadir un sistema nuevo, se añade aqui su frame y se vuelve a lanzar el script.
KNOWN = {
    # --- Profesiones y crafteo (ventana de recetas + huecos del libro) ---
    'Blizzard_TradeSkillUI': 'AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillUI.xml',
    'Blizzard_TradeSkillRecipeList': 'AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillRecipeList.xml',
    'Blizzard_TradeSkillDetails': 'AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillDetails.xml',
    'Blizzard_TradeSkillRecipeButton': 'AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillRecipeButton.xml',
    'Blizzard_TradeSkillTemplates': 'AddOns/Blizzard_TradeSkillUI/Blizzard_TradeSkillTemplates.xml',
    'SpellBookFrame': 'FrameXML/SpellBookFrame.xml',
    # --- Panel de personaje y ficha ---
    'CharacterFrame': 'FrameXML/CharacterFrame.xml',
    'CharacterFrameTemplates': 'FrameXML/CharacterFrameTemplates.xml',
    'PaperDollFrame': 'FrameXML/PaperDollFrame.xml',
    # --- Reputacion ---
    'ReputationFrame': 'FrameXML/ReputationFrame.xml',
    # --- Misiones ---
    'Blizzard_ObjectiveTracker': 'AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.xml',
    'Blizzard_ObjectiveTrackerShared': 'AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerShared.xml',
    'Blizzard_QuestObjectiveTracker': 'AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.xml',
    'QuestFrame': 'FrameXML/QuestFrame.xml',
    # --- Barra de experiencia / reputacion seguida ---
    'StatusTrackingBar': 'FrameXML/StatusTrackingBar.xml',
    'StatusTrackingBarTemplate': 'FrameXML/StatusTrackingBarTemplate.xml',
    # --- Plantillas compartidas: insets, spinners, buscadores, botones ---
    'SharedUIPanelTemplates': 'SharedXML/SharedUIPanelTemplates.xml',
    'UIPanelTemplates': 'FrameXML/UIPanelTemplates.xml',
    'ItemButtonTemplate': 'FrameXML/ItemButtonTemplate.xml',
}


def fetch(url, timeout=45):
    """Se descarga con curl: urllib no tiene salida a internet en este entorno."""
    try:
        out = subprocess.run(['curl', '-s', '-L', '--max-time', str(timeout), url],
                             capture_output=True, timeout=timeout + 10)
        if out.returncode != 0:
            return None
        return out.stdout.decode('utf-8', errors='replace')
    except Exception:
        return None


def clean_townlong(raw):
    """Townlong Yak sirve el XML como HTML coloreado: se extrae el texto de cada linea."""
    import html
    import re
    lines = re.findall(r'<li id="\d+">(.*?)</li>', raw, re.S)
    if not lines:
        return None
    out = [html.unescape(re.sub(r'<[^>]+>', '', ln)).replace('\xa0', ' ').rstrip() for ln in lines]
    return '\n'.join(out) + '\n'


def download(name, path):
    """Primero el repo de Blizzard con la etiqueta exacta; si falla, el archivo de la build."""
    try:
        text = fetch(GITHUB % (TAG, path))
        if text and '<Ui' in text:
            return text, 'github %s' % TAG
    except Exception:
        pass
    try:
        raw = fetch(TOWNLONG % (BUILD, path.split('/')[-1]))
        text = clean_townlong(raw)
        if text and '<Ui' in text:
            return text, 'townlong %s' % BUILD
    except Exception:
        pass
    return None, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('names', nargs='*', help='frames a descargar (por defecto, los conocidos)')
    ap.add_argument('--list', action='store_true', help='muestra lo ya descargado')
    args = ap.parse_args()

    if args.list:
        if not os.path.isdir(OUT_DIR):
            print('No hay nada descargado. Lanza el script sin argumentos.')
            return
        files = sorted(os.listdir(OUT_DIR))
        print('%s: %d ficheros' % (OUT_DIR, len(files)))
        for f in files:
            size = os.path.getsize(os.path.join(OUT_DIR, f))
            print('  %-46s %6d bytes' % (f, size))
        return

    os.makedirs(OUT_DIR, exist_ok=True)
    targets = args.names or sorted(KNOWN)
    ok = failed = 0
    for name in targets:
        path = KNOWN.get(name)
        if not path:
            # Nombre suelto: se intenta como fichero de FrameXML.
            path = 'FrameXML/%s.xml' % name
        text, source = download(name, path)
        if not text:
            print('  FALLO   %-40s (%s)' % (name, path))
            failed += 1
            continue
        dest = os.path.join(OUT_DIR, name + '.xml')
        io.open(dest, 'w', encoding='utf-8', newline='\n').write(text)
        print('  %-40s %6d bytes   [%s]' % (name, len(text), source))
        ok += 1
    print('\n%d descargados, %d fallidos -> %s' % (ok, failed, OUT_DIR))


if __name__ == '__main__':
    main()
