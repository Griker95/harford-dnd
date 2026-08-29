# -*- coding: utf-8 -*-
"""Guardian de pre-commit: sobre los .lua EN STAGE comprueba lo que ya nos costo caro.
1. Compila con luac -p (si luac esta en el PATH; si no, avisa y no bloquea por eso).
2. UTF-8 valido y SIN BOM.
3. Mojibake compuesto (doble codificacion): busca los patrones de CLAUDE.md
   ("Ãƒ", "Ã‚", "Ã¢", "â€", "�"),
   nunca "Ã"/"Â" sueltos, que aparecen legitimos en tablas de acentos.
Sale con 1 si algo bloquea el commit.
"""
import io, subprocess, sys

MOJIBAKE = ["Ãƒ", "Ã‚", "Ã¢", "â€", "�"]


def staged_lua():
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
        capture_output=True, text=True, check=True).stdout
    return [line for line in out.splitlines() if line.endswith(".lua")]


def tiene_luac():
    try:
        subprocess.run(["luac", "-v"], capture_output=True)
        return True
    except OSError:
        return False


def main():
    ficheros = staged_lua()
    if not ficheros:
        return 0
    errores = []
    con_luac = tiene_luac()
    for ruta in ficheros:
        try:
            raw = open(ruta, "rb").read()
        except OSError as exc:
            errores.append("%s: no se pudo leer (%s)" % (ruta, exc))
            continue
        if raw.startswith(b"\xef\xbb\xbf"):
            errores.append("%s: tiene BOM y los .lua van UTF-8 SIN BOM" % ruta)
        try:
            texto = raw.decode("utf-8")
        except UnicodeDecodeError as exc:
            errores.append("%s: no es UTF-8 valido (%s)" % (ruta, exc))
            continue
        for patron in MOJIBAKE:
            if patron in texto:
                linea = texto[:texto.index(patron)].count("\n") + 1
                errores.append("%s:%d: mojibake compuesto %r (doble codificacion)"
                               % (ruta, linea, patron))
                break
        if con_luac:
            comp = subprocess.run(["luac", "-p", ruta], capture_output=True, text=True)
            if comp.returncode != 0:
                errores.append("%s: no compila -> %s" % (ruta, comp.stderr.strip()))
    if not con_luac:
        print("[hook] aviso: luac no esta en el PATH, se salta la compilacion")
    if errores:
        print("[hook] COMMIT BLOQUEADO:")
        for e in errores:
            print("  - " + e)
        return 1
    print("[hook] %d .lua en stage: compilan, UTF-8 sin BOM, sin mojibake" % len(ficheros))
    return 0


if __name__ == "__main__":
    sys.exit(main())
