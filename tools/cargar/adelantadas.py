# -*- coding: utf-8 -*-
"""Locales que se USAN antes de declararse.

En Lua un `local` solo existe a partir de su linea. Llamarlo antes no da error de compilacion: se
resuelve como un GLOBAL, que vale nil, y revienta al ejecutarse -- "attempt to call global 'X' (a
nil value)". El fichero compila, carga y solo falla cuando el jugador pulsa lo que la usa.

Es lo que le paso a `EquipmentGroups`, definida en la 975 y llamada en la 580 al elegir equipo. El
patron correcto, que este codigo ya usa en otros sitios, es declararla arriba (`local X`) y
asignarla luego (`X = function()`).

    python tools/cargar/adelantadas.py
"""
import io, re, glob, os, sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DECL = re.compile(r'^(\s*)local\s+function\s+([A-Za-z_][A-Za-z0-9_]*)')
# Declaracion adelantada: `local X` (con o sin mas nombres) sin `function` ni `=` con cuerpo.
FWD = re.compile(r'^\s*local\s+([A-Za-z_][A-Za-z0-9_,\s]*?)\s*(?:--.*)?$')


def revisa(ruta):
    lineas = io.open(ruta, encoding='utf-8', errors='replace').read().split('\n')
    # nombres ya declarados adelantados, con su linea
    adelantadas = {}
    for i, l in enumerate(lineas):
        m = FWD.match(l)
        if m and '=' not in l and 'function' not in l:
            for nombre in m.group(1).split(','):
                nombre = nombre.strip()
                if nombre:
                    adelantadas.setdefault(nombre, i)

    fuera = []
    for i, l in enumerate(lineas):
        m = DECL.match(l)
        if not m:
            continue
        nombre = m.group(2)
        if nombre in adelantadas and adelantadas[nombre] < i:
            continue                      # ya esta declarada arriba: correcto
        # Un mismo nombre declarado varias veces son locales de AMBITOS distintos (un `consider`
        # dentro de dos funciones). Sin analisis de ambito no se pueden distinguir, y marcarlos
        # ahogaria los de verdad, asi que solo se miran los nombres unicos del fichero.
        if sum(1 for x in lineas if DECL.match(x) and DECL.match(x).group(2) == nombre) > 1:
            continue
        uso = re.compile(r'(?<![\w.:])%s\s*\(' % re.escape(nombre))
        for j in range(i):
            linea = re.sub(r'--.*', '', lineas[j])
            if uso.search(linea):
                fuera.append((nombre, j + 1, i + 1, lineas[j].strip()[:66]))
                break
    return fuera


def main():
    total = 0
    for f in sorted(glob.glob(os.path.join(RAIZ, 'Harford*', '**', '*.lua'), recursive=True)):
        for nombre, usa, declara, texto in revisa(f):
            rel = os.path.relpath(f, RAIZ).replace(os.sep, '/')
            print('  %s' % rel)
            print('     %s: se usa en la %d y se declara en la %d' % (nombre, usa, declara))
            print('     %s' % texto)
            total += 1
    print()
    print('Locales usadas antes de declararse: %d' % total)
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())
