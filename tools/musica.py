# -*- coding: utf-8 -*-
"""Convierte una carpeta de audio a OGG y genera la lista de emisoras de HarfordMusic.

    python tools/musica.py <carpeta_con_audio>

Coge cualquier .mp3/.wav/.flac/.m4a/.ogg de esa carpeta, los pasa a OGG con los ajustes que
funcionan en WoW, los deja en `HarfordMusic/Media/` y reescribe `HarfordMusic/Emisoras.lua` con la
tabla. El nombre de la emisora sale del nombre del fichero, asi que llamalos como quieras que se
lean en la radio: `Taberna de Refugio.mp3` -> emisora "Taberna de Refugio".

NO descarga nada de internet: trabaja con ficheros que ya tengas. Lo que metas aqui lo vas a
repartir a tu mesa, asi que que sea tuyo o de uso libre.
"""
import os
import re
import subprocess
import sys
import unicodedata

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DESTINO = os.path.join(RAIZ, 'HarfordMusic', 'Media')
LISTA = os.path.join(RAIZ, 'HarfordMusic', 'Emisoras.lua')
EXTENSIONES = ('.mp3', '.wav', '.flac', '.m4a', '.ogg', '.opus', '.aac')

# `-q:a 4` deja unos 128 kbps: para musica de fondo en un juego suena bien y un tema de tres
# minutos se queda sobre los 3 MB. El paquete lo descarga cada uno a mano, asi que el peso importa
# tanto como la calidad.
CALIDAD = '4'


def NombreDeFichero(titulo):
    """Un nombre de fichero sin acentos ni espacios: las rutas de WoW se escriben a mano en Lua y
    un acento ahi es una fuente de mojibake que no compensa."""
    plano = unicodedata.normalize('NFD', titulo)
    plano = ''.join(c for c in plano if unicodedata.category(c) != 'Mn')
    plano = re.sub(r'[^A-Za-z0-9]+', '_', plano).strip('_').lower()
    return plano or 'pista'


def HayFfmpeg():
    try:
        subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def Convertir(origen, destino):
    orden = ['ffmpeg', '-y', '-i', origen,
             '-c:a', 'libvorbis', '-q:a', CALIDAD,
             '-ar', '44100', '-ac', '2',
             destino]
    r = subprocess.run(orden, capture_output=True)
    return r.returncode == 0, (r.stderr or b'').decode('utf-8', 'ignore')


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    origen = sys.argv[1]
    if not os.path.isdir(origen):
        print('No existe la carpeta: %s' % origen)
        return 1
    if not HayFfmpeg():
        print('Falta ffmpeg. Instalalo y vuelve a ejecutar:')
        print('    winget install Gyan.FFmpeg')
        print('(o descarga el .exe portable y ponlo en el PATH)')
        return 1

    os.makedirs(DESTINO, exist_ok=True)
    entradas = sorted(f for f in os.listdir(origen)
                      if f.lower().endswith(EXTENSIONES))
    if not entradas:
        print('No hay audio en %s (busco %s)' % (origen, ', '.join(EXTENSIONES)))
        return 1

    emisoras, total = [], 0
    for nombre in entradas:
        titulo = os.path.splitext(nombre)[0]
        base = NombreDeFichero(titulo)
        salida = os.path.join(DESTINO, base + '.ogg')
        ok, err = Convertir(os.path.join(origen, nombre), salida)
        if not ok:
            print('  FALLA  %s' % nombre)
            print('         %s' % err.strip().splitlines()[-1] if err.strip() else '')
            continue
        tam = os.path.getsize(salida)
        total += tam
        emisoras.append((titulo, base))
        print('  ok     %-40s %6.1f MB' % (titulo, tam / 1048576.0))

    if not emisoras:
        print('No se convirtio nada.')
        return 1

    with open(LISTA, 'w', encoding='utf-8', newline='') as f:
        f.write('-- GENERADO por `tools/musica.py`. No editar a mano: se regenera.\n')
        f.write('--\n')
        f.write('-- El nombre de cada emisora sale del nombre del fichero de origen. Para cambiarlo,\n')
        f.write('-- renombra el fichero y vuelve a ejecutar el script.\n')
        f.write('\n')
        f.write('HarfordMusic = HarfordMusic or {}\n')
        f.write('HarfordMusic.EMISORAS_FICHERO = {\n')
        for titulo, base in emisoras:
            f.write('    { name = %s, file = "Interface\\\\AddOns\\\\HarfordMusic\\\\Media\\\\%s.ogg" },\n'
                    % (LuaCadena(titulo), base))
        f.write('}\n')

    print('')
    print('%d emisora(s), %.1f MB en total.' % (len(emisoras), total / 1048576.0))
    print('Escrita %s' % os.path.relpath(LISTA, RAIZ))
    print('')
    print('Ahora: python tools/desplegar.py   y REINICIA el WoW entero.')
    print('(un /reload no vale: el cliente indexa el audio de los addons al arrancar)')
    return 0


def LuaCadena(texto):
    return '"' + str(texto).replace('\\', '\\\\').replace('"', '\\"') + '"'


if __name__ == '__main__':
    sys.exit(main())
