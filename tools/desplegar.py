# -*- coding: utf-8 -*-
"""Despliegue de Harford a Epsilon con verificacion previa.

    python tools/desplegar.py            # comprueba y despliega
    python tools/desplegar.py --revisar  # solo comprueba, no copia
    python tools/desplegar.py --forzar   # copia aunque haya avisos (NO salta los errores)

Comprueba, en este orden, y NO copia nada si algo falla:

  1. Compilacion con el Lua 5.1 REAL (tools/codice/lua51.py, que carga lua51.dll). El `luac` de
     la maquina es 5.4 y NO detecta el limite de 200 locales ni el de 65.536 constantes, que son
     justo los que rompen en juego.
  2. Margen de locales: avisa por debajo de 25 libres. Un fichero sin margen deja de compilar en
     cuanto alguien le anade una funcion, y el error aparece al arrancar WoW, no al editar.
  3. Codificacion: UTF-8 sin BOM, saltos LF y sin mojibake. Se buscan pares compuestos
     (C3 82, C3 8F, E2 80, FFFD), NO `A`/`A` sueltos, que aparecen legitimamente en las tablas
     de normalizacion de acentos.
  4. Que cada .lua listado en un .toc exista de verdad.

Tras copiar, verifica por hash que el destino es identico al origen.
"""
import io, os, re, sys, shutil, hashlib

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, '..')) + '/'
DESTINO = 'G:/Epsilon/_retail_/Interface/AddOns/'
sys.path.insert(0, os.path.join(AQUI, 'codice'))
import lua51

ADDONS = ['Harford', 'HarfordAdmin', 'HarfordDebug',
          'HarfordProfessionsData', 'HarfordCompendioData']

SOLO_REVISAR = '--revisar' in sys.argv
FORZAR = '--forzar' in sys.argv
MARGEN_MINIMO = 25

MOJIBAKE = ['\u00c3\u0192', '\u00c3\u201a', '\u00c3\u00a2', '\u00e2\u20ac', '\ufffd']

errores, avisos = [], []


def ficheros_lua(addon):
    fuera = []
    for base, _, nombres in os.walk(RAIZ + addon):
        for n in nombres:
            if n.lower().endswith('.lua'):
                fuera.append(os.path.join(base, n).replace('\\', '/'))
    return sorted(fuera)


def margen(ruta):
    """Locales libres en el chunk principal, preguntandoselo al compilador 5.1."""
    import tempfile
    s = io.open(ruta, encoding='utf-8', errors='replace').read()

    def cabe(n):
        extra = ''.join('local __d%d = %d\n' % (i, i) for i in range(n))
        tmp = tempfile.mktemp(suffix='.lua')
        io.open(tmp, 'w', encoding='utf-8', newline='\n').write(s + '\n' + extra)
        ok, _ = lua51.compila(tmp)
        os.remove(tmp)
        return ok

    if cabe(MARGEN_MINIMO):
        return None          # sobra margen, no hace falta afinar
    lo, hi = 0, MARGEN_MINIMO
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if cabe(mid):
            lo = mid
        else:
            hi = mid - 1
    return lo


print('VERIFICACION PREVIA')
print('=' * 66)
total = 0
for addon in ADDONS:
    if not os.path.isdir(RAIZ + addon):
        avisos.append('%s: la carpeta no existe en el repositorio' % addon)
        continue
    for f in ficheros_lua(addon):
        total += 1
        rel = f.replace(RAIZ, '')
        ok, msg = lua51.compila(f)
        if not ok:
            errores.append('%s: NO COMPILA en 5.1 -> %s' % (rel, msg))
            continue
        libre = margen(f)
        if libre is not None:
            avisos.append('%s: solo %d locales libres de 200' % (rel, libre))
        s = io.open(f, encoding='utf-8', errors='replace').read()
        crudo = io.open(f, 'rb').read()
        if crudo.startswith(b'\xef\xbb\xbf'):
            errores.append('%s: tiene BOM (debe ser UTF-8 SIN BOM)' % rel)
        if b'\r\n' in crudo:
            errores.append('%s: tiene saltos CRLF (deben ser LF)' % rel)
        malos = [p for p in MOJIBAKE if p in s]
        if malos:
            errores.append('%s: mojibake (%d patron(es))' % (rel, len(malos)))

# --- el .toc apunta a ficheros que existen ---
for addon in ADDONS:
    toc = RAIZ + addon + '/' + addon + '.toc'
    if not os.path.exists(toc):
        continue
    for linea in io.open(toc, encoding='utf-8', errors='replace').read().split('\n'):
        linea = linea.strip()
        if not linea or linea.startswith('#') or not linea.lower().endswith('.lua'):
            continue
        p = RAIZ + addon + '/' + linea.replace('\\', '/')
        if not os.path.exists(p):
            errores.append('%s.toc: lista %s y no existe' % (addon, linea))

# --- 3. Carga real de los ficheros -------------------------------------------------------------
# Compilar NO basta. Un `end` de mas cierra una funcion antes de tiempo, el fichero sigue
# compilando, y su cuerpo pasa a ejecutarse en el chunk principal donde las locales de esa funcion
# no existen. Asi rompio HarfordUnitFrames el addon entero sin un solo error de sintaxis: el
# cliente aborta ese fichero y todo lo que va detras muere en silencio.
#
# Esto los carga con stubs de WoW, que es donde ese fallo si sale.
# Lo que NO cubre: nada posterior a la carga (PLAYER_LOGIN, eventos, abrir una ventana).
import subprocess as _sp
_lua = None
for _c in [os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Programs', 'Lua', 'bin', 'lua.exe'),
           'lua5.1', 'lua51', 'luajit', 'lua']:
    try:
        _sp.run([_c, '-v'], capture_output=True, timeout=5)
        _lua = _c
        break
    except (OSError, _sp.SubprocessError):
        continue
if _lua:
    _arranque = os.path.join(RAIZ, 'tools', 'cargar', 'arranque.lua')
    _r = _sp.run([_lua, _arranque, RAIZ.replace(chr(92), '/').rstrip('/')],
                 capture_output=True, text=True, encoding='utf-8', errors='replace')
    if _r.returncode != 0:
        for _l in ((_r.stdout or '') + (_r.stderr or '')).strip().split(chr(10)):
            if _l.strip() and not _l.startswith('Ficheros cargados'):
                errores.append('al cargar: ' + _l.strip())
else:
    avisos.append('sin interprete Lua: no se ha comprobado la carga de los ficheros')

# --- 4. Locales usadas antes de declararse -----------------------------------------------------
# En Lua un `local` solo existe a partir de su linea: llamarlo antes se resuelve como GLOBAL, vale
# nil y revienta al EJECUTARSE. Compila, carga, y solo falla cuando el jugador pulsa lo que la usa,
# asi que ni el compilador ni el arnes de carga lo ven. Le paso a `EquipmentGroups` al elegir
# equipo, definida 400 lineas por debajo de donde se llama.
_r2 = _sp.run([sys.executable, os.path.join(RAIZ, 'tools', 'cargar', 'adelantadas.py')],
              capture_output=True, text=True, encoding='utf-8', errors='replace')
if _r2.returncode != 0:
    for _l in (_r2.stdout or '').strip().split(chr(10)):
        if _l.strip() and not _l.startswith('Locales usadas'):
            errores.append('orden: ' + _l.strip())

# --- 5. Campos de datos que ningun motor lee ---------------------------------------------------
# Un rasgo puede declarar el campo que quiera y Lua no se queja. Si nadie lo lee, el rasgo se
# anuncia, gasta su uso y no hace NADA. Le pasaba a la Reserva de Ira, que declaraba
# `rageReserveByLevel` y no daba ni un punto de ira.
_r3 = _sp.run([sys.executable, os.path.join(RAIZ, 'tools', 'cargar', 'datos_muertos.py')],
              capture_output=True, text=True, encoding='utf-8', errors='replace')
if _r3.returncode != 0:
    for _l in (_r3.stdout or '').strip().split(chr(10)):
        if _l.strip() and not _l.startswith('Campos de datos'):
            errores.append('datos: ' + _l.strip())

# --- 5b. Una mutacion a medio deshacer ---------------------------------------------------------
# `mutaciones.py` rompe el codigo a proposito y lo restaura despues, pero si lo matan desde fuera
# (un `timeout`, un Ctrl-C) el fichero se queda MUTADO en disco. Paso de verdad. La herramienta lo
# deshace en su siguiente arranque, pero entre medias un despliegue se llevaria el fichero roto al
# cliente, y encima con una rotura sutil y a proposito.
_marca = os.path.join(RAIZ, 'tools', 'cargar', '.mutacion_en_curso')
if os.path.exists(_marca):
    errores.append('mutacion: hay una mutacion a medio deshacer; ejecuta '
                   '"python tools/cargar/mutaciones.py X.lua 1" para que la restaure')

# --- 6. Referencias a algo que no existe -------------------------------------------------------
# Un rasgo puede nombrar la condicion `ayudado_pruebaa` y Lua no se queja: la busca, no la
# encuentra, y no hace nada. Es la misma familia que dejo nueve condiciones sin aplicarse jamas por
# no estar en `API.ORDER`: algo apunta a un sitio vacio y el fallo aparece como SILENCIO, que es lo
# que mas ha costado esta semana.
_r5 = _sp.run([sys.executable, os.path.join(RAIZ, 'tools', 'cargar', 'referencias.py')],
              capture_output=True, text=True, encoding='utf-8', errors='replace')
if _r5.returncode != 0:
    for _l in (_r5.stdout or '').strip().split(chr(10)):
        if _l.strip() and not _l.startswith('Referencias a'):
            errores.append('refs: ' + _l.strip())

# --- 7. Pruebas de logica ----------------------------------------------------------------------
# Dos veces en una sesion se desplego con una suite en rojo: una comprobacion se quedaba vieja al
# cambiar la firma de una funcion, y nadie la ejecutaba antes de copiar. Un fichero que compila,
# carga y ademas rompe una regla que ya estaba probada no tiene por que llegar al cliente.
_r4 = _sp.run([sys.executable, os.path.join(RAIZ, 'tools', 'pruebas.py')],
              capture_output=True, text=True, encoding='utf-8', errors='replace')
if _r4.returncode != 0:
    _resumen = [l for l in (_r4.stdout or '').split(chr(10)) if 'FALLA' in l or 'fallidos' in l]
    for _l in _resumen[:12]:
        if _l.strip():
            errores.append('pruebas: ' + _l.strip())
    if not _resumen:
        errores.append('pruebas: fallan y no se pudo leer el resumen')

print('  %d ficheros .lua revisados' % total)
for a in avisos:
    print("  AVISO   %s" % a)
for e in errores:
    print('  ERROR   %s' % e)
if not errores and not avisos:
    print('  todo correcto')
print()

if errores:
    print('NO se despliega: hay %d error(es).' % len(errores))
    sys.exit(1)
if avisos and not FORZAR and not SOLO_REVISAR:
    print('Hay avisos. Repite con --forzar si quieres desplegar igualmente.')
    sys.exit(1)
if SOLO_REVISAR:
    print('(solo revision; nada copiado)')
    sys.exit(0)

# --- copia ---
print('DESPLIEGUE')
print('=' * 66)
copiados, fallos = 0, 0
for addon in ADDONS:
    org = RAIZ + addon
    dst = DESTINO + addon
    if not os.path.isdir(org):
        continue
    os.makedirs(dst, exist_ok=True)
    for base, _, nombres in os.walk(org):
        rel_dir = base.replace(org, '').lstrip('\\/')
        for n in nombres:
            if not (n.lower().endswith('.lua') or n.lower().endswith('.toc')
                    or n.lower().endswith('.xml')):
                continue
            o = os.path.join(base, n)
            d = os.path.join(dst, rel_dir, n)
            os.makedirs(os.path.dirname(d), exist_ok=True)
            shutil.copyfile(o, d)
            ho = hashlib.md5(io.open(o, 'rb').read()).hexdigest()
            hd = hashlib.md5(io.open(d, 'rb').read()).hexdigest()
            if ho == hd:
                copiados += 1
            else:
                fallos += 1
                print('  FALLO de copia: %s' % d)
    print('  %-26s desplegado' % addon)

print()
print('%d ficheros copiados y verificados por hash%s'
      % (copiados, (', %d FALLOS' % fallos) if fallos else ''))
sys.exit(1 if fallos else 0)
