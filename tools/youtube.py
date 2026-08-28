# -*- coding: utf-8 -*-
"""Baja el audio de una lista de YouTube y lo deja listo para `tools/musica.py`.

    python tools/youtube.py <url_de_la_lista>
    python tools/youtube.py <url> --carpeta D:\\musica_harford
    python tools/youtube.py lista.txt          (un enlace por linea)

Descarga a una carpeta de trabajo y despues llama a `tools/musica.py`, que es quien convierte a
OGG, renombra y escribe la tabla de emisoras. Asi hay UNA sola ruta de conversion: lo que bajes de
aqui y lo que metas a mano acaban tratados igual.

Necesita `yt-dlp` y `ffmpeg`:
    winget install yt-dlp.yt-dlp
    winget install Gyan.FFmpeg

El titulo del video se convierte en el nombre de la emisora, asi que si un video se llama
"Tavern Music (1 HOUR) [HD]" te va a salir eso en la radio: renombra los ficheros de la carpeta
de trabajo antes de dejar que `musica.py` los procese, o usa `--solo-bajar`.

Lo que bajes lo vas a repartir a tu mesa. Eso es distribuirlo, asi que elige material que puedas
repartir: tuyo, de dominio publico o con licencia que lo permita (Creative Commons, bibliotecas
libres). El script no comprueba nada de eso; es cosa tuya.
"""
import os
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRABAJO = os.path.join(RAIZ, 'tools', '_musica_descargada')


def Hay(programa):
    try:
        subprocess.run([programa, '--version'], capture_output=True, check=True)
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


def Enlaces(argumento):
    """Un fichero con un enlace por linea, o el enlace suelto."""
    if os.path.isfile(argumento):
        with open(argumento, encoding='utf-8') as f:
            return [l.strip() for l in f if l.strip() and not l.strip().startswith('#')]
    return [argumento]


def Bajar(url, destino):
    orden = [
        'yt-dlp',
        '-x',                          # solo el audio
        '--audio-format', 'vorbis',    # OGG ya de entrada
        '--audio-quality', '4',        # ~128 kbps, lo mismo que usa musica.py
        '--no-playlist-reverse',
        '--ignore-errors',             # un video caido no tumba la lista entera
        '-o', os.path.join(destino, '%(playlist_index)s - %(title)s.%(ext)s'),
        url,
    ]
    return subprocess.run(orden).returncode == 0


def main():
    args = [a for a in sys.argv[1:]]
    if not args:
        print(__doc__)
        return 1

    solo_bajar = '--solo-bajar' in args
    args = [a for a in args if a != '--solo-bajar']

    destino = TRABAJO
    if '--carpeta' in args:
        i = args.index('--carpeta')
        if i + 1 >= len(args):
            print('--carpeta necesita una ruta')
            return 1
        destino = args[i + 1]
        args = args[:i] + args[i + 2:]

    if not args:
        print('Falta la url o el fichero de enlaces.')
        return 1

    faltan = [p for p in ('yt-dlp', 'ffmpeg') if not Hay(p)]
    if faltan:
        print('Falta: %s' % ', '.join(faltan))
        print('    winget install yt-dlp.yt-dlp')
        print('    winget install Gyan.FFmpeg')
        return 1

    os.makedirs(destino, exist_ok=True)
    enlaces = Enlaces(args[0])
    print('Bajando %d enlace(s) a %s' % (len(enlaces), destino))
    fallos = 0
    for url in enlaces:
        if not Bajar(url, destino):
            fallos += 1
            print('  FALLA  %s' % url)

    bajados = sorted(f for f in os.listdir(destino) if f.lower().endswith('.ogg'))
    print('')
    print('%d fichero(s) en la carpeta de trabajo.' % len(bajados))
    if fallos:
        print('%d enlace(s) fallaron.' % fallos)
    if not bajados:
        return 1

    # El nombre del fichero acaba siendo el nombre de la emisora, y los titulos de YouTube traen
    # basura ("(1 HOUR)", "[HD]", el indice de la lista). Se avisa en vez de intentar limpiarlos a
    # ciegas: adivinar que parte del titulo sobra sale mal mas veces de las que acierta.
    print('')
    print('Revisa los NOMBRES antes de seguir: son los que saldran en la radio.')
    for f in bajados[:8]:
        print('    %s' % f)
    if len(bajados) > 8:
        print('    ... y %d mas' % (len(bajados) - 8))

    if solo_bajar:
        print('')
        print('Cuando esten como quieras:  python tools/musica.py "%s"' % destino)
        return 0

    print('')
    print('Convirtiendo y generando la lista de emisoras...')
    return subprocess.run([sys.executable, os.path.join(RAIZ, 'tools', 'musica.py'),
                           destino]).returncode


if __name__ == '__main__':
    sys.exit(main())
