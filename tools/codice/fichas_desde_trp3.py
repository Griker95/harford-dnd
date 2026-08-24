# -*- coding: utf-8 -*-
"""Lee los perfiles TRP3 del disco y saca los frames del About de cada personaje.

Fuente: `totalRP3.lua` de las cuentas de Epsilon. Interesan los perfiles `{PJ} <Nombre>`,
que son los canonicos (ver AGENTS.md); del About se toma la plantilla 2, que es la que
Harford escribe: cada frame lleva su texto (`TX`), su icono (`IC`) y abre con un `{h1}` que
es su titulo.

Este modulo SOLO LEE y expone los datos; quien escribe la web es `fichas_web_desde_trp3.py`.

El `.lua` no se parsea entero: se recorren las llaves contando profundidad, que es barato y
no depende de que el volcado tenga un orden concreto.
"""
import io
import os
import re
import sys
import unicodedata

CUENTAS = r"G:/Epsilon/_retail_/WTF/Account"

_PROFILE_NAME = re.compile(r'\["profileName"\]\s*=\s*"((?:[^"\\]|\\.)*)"')
_TX = re.compile(r'\["TX"\]\s*=\s*"((?:[^"\\]|\\.)*)"')
_IC = re.compile(r'\["IC"\]\s*=\s*"([^"]*)"')
_H1 = re.compile(r"\{h1(?::[^}]*)?\}(.*?)\{/h1\}", re.S)


def desescapa(s):
    """Deshace los escapes de una cadena Lua tal como la escribe WoW."""
    return (s.replace("\\n", "\n").replace('\\"', '"')
             .replace("\\\\", "\\").replace("\\t", "\t"))


def limpio(x):
    """Texto de un titulo sin markup, para poder compararlo."""
    x = re.sub(r"\{icon:[^}]*\}", "", x or "")
    x = re.sub(r"\{/?(?:h[123]|p|col)(?::[^}]*)?\}", "", x)
    return re.sub(r"\s+", " ", x).strip()


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", s.lower())).strip()


def _bloques_de_perfil(texto):
    """Trocea el volcado en un bloque por perfil, cortando por `["profileName"]`.

    OJO con el sentido: WoW escribe `profileName` como ULTIMA clave del perfil, asi que a
    cada nombre le corresponde el texto que lo PRECEDE, no el que lo sigue. Tomando el
    texto siguiente, los frames se le colgaban al perfil anterior: Cody salia con 23 y
    Baird con 2.
    """
    marcas = [m for m in _PROFILE_NAME.finditer(texto)]
    inicio = 0
    for m in marcas:
        yield desescapa(m.group(1)), texto[inicio:m.start()]
        inicio = m.end()


def _recorre_llaves(texto, desde):
    """Recorre desde una llave de apertura devolviendo (posicion, caracter, nivel).

    Salta el contenido de las cadenas: el markup del About lleva llaves dentro ({h1:c},
    {icon:...}), y contarlas descuadra el recorrido entero.
    """
    nivel, k, cadena, escapa = 0, desde, None, False
    while k < len(texto):
        c = texto[k]
        if cadena:
            if escapa:
                escapa = False
            elif c == "\\":
                escapa = True
            elif c == cadena:
                cadena = None
        elif c in "\"'":
            cadena = c
        elif c == "{":
            nivel += 1
            yield k, c, nivel
        elif c == "}":
            yield k, c, nivel
            nivel -= 1
            if nivel == 0:
                return
        elif nivel >= 1:
            yield k, c, nivel
        k += 1


def _tramo_t2(bloque):
    """El sub-bloque `["T2"]` del About.

    Hace falta acotar: los VISTAZOS del perfil (`AT FIRST GLANCE`) tambien guardan su texto
    en `["TX"]`, asi que scaneando el perfil entero se colaban como si fueran frames --a
    Ziegler le salian cinco sin titulo por delante--.
    """
    i = bloque.find('["T2"]')
    if i < 0:
        return ""
    j = bloque.find("{", i)
    if j < 0:
        return ""
    for k, c, nivel in _recorre_llaves(bloque, j):
        if c == "}" and nivel == 1:
            return bloque[j:k + 1]
    return bloque[j:]

def frames_de(bloque):
    """Frames del About en orden: titulo, icono y markup."""
    salida = []
    bloque = _tramo_t2(bloque)
    for m in _TX.finditer(bloque):
        markup = desescapa(m.group(1))
        if not markup.strip():
            continue
        ic = _IC.search(bloque[m.end():m.end() + 400])
        t = _H1.search(markup)
        salida.append({
            "title": limpio(t.group(1)) if t else "",
            "icon": (ic.group(1) if ic else ""),
            "markup": markup,
        })
    return salida


_FN = re.compile(r'\["FN"\]\s*=\s*"((?:[^"\\]|\\.)*)"')


def _hijos_de_tabla(texto, inicio):
    """Trozos `["clave"] = { ... }` que cuelgan directamente de la tabla que abre en `inicio`."""
    j = texto.find("{", inicio)
    if j < 0:
        return
    arranque = None
    for k, c, nivel in _recorre_llaves(texto, j):
        if c == "[" and nivel == 1 and arranque is None:
            arranque = k
        elif c == "}" and nivel == 2 and arranque is not None:
            yield texto[arranque:k + 1]
            arranque = None

def _perfiles_vistos(cuenta):
    """Perfiles de OTROS jugadores, del registro (`totalRP3_Data.lua`).

    Se recorre la tabla `["profiles"]` por bloques: de cada perfil se lee su nombre en
    `["FN"]` y su About del mismo bloque. Cortar por la marca de nombre, como se hacia
    antes, desplazaba la correspondencia en cuanto un perfil no tenia About.
    """
    ruta = os.path.join(CUENTAS, cuenta, "SavedVariables", "totalRP3_Data.lua")
    if not os.path.exists(ruta):
        return []
    texto = io.open(ruta, encoding="utf-8", errors="replace").read()
    i = texto.find('["profiles"]')
    if i < 0:
        return []
    salida = []
    for bloque in _hijos_de_tabla(texto, i):
        fn = _FN.search(bloque)
        if not fn:
            continue
        visto = re.search(r'\["time"\]\s*=\s*(\d+)', bloque)
        salida.append((desescapa(fn.group(1)), bloque, int(visto.group(1)) if visto else 0))
    return salida


def perfiles(solo_pj=True):
    """{nombre sin marca} -> {"etiqueta", "cuenta", "frames"} del perfil mas completo."""
    encontrados = {}
    for cuenta in sorted(os.listdir(CUENTAS)):
        ruta = os.path.join(CUENTAS, cuenta, "SavedVariables", "totalRP3.lua")
        if not os.path.exists(ruta):
            continue
        texto = io.open(ruta, encoding="utf-8", errors="replace").read()
        # los propios y, detras, los vistos de otros jugadores
        fuentes = [(e, b, 0) for e, b in _bloques_de_perfil(texto)] + _perfiles_vistos(cuenta)
        for etiqueta, bloque, visto in fuentes:
            if solo_pj and not etiqueta.startswith("{PJ}"):
                continue
            nombre = re.sub(r"^\{[^}]*\}\s*", "", etiqueta).strip()
            fr = frames_de(bloque)
            if not fr:
                continue
            # Dos perfiles pueden normalizar al mismo nombre ("{PJ} Cody" y "Côdy"), y el
            # que manda es el marcado {PJ}, que es el canonico; entre iguales, el que mas
            # frames trae. Ordenar solo por numero de frames hacia que la ficha cambiara de
            # perfil segun cual estuviera mas relleno ese dia.
            # propio {PJ} > visto mas reciente > mas frames
            rango = (1 if etiqueta.startswith("{PJ}") else 0, visto, len(fr))
            registro = {"etiqueta": etiqueta, "nombre": nombre,
                        "cuenta": cuenta, "frames": fr, "rango": rango}
            # La clave por ETIQUETA se guarda SIEMPRE: es la que permite pedir un perfil
            # concreto. Antes se saltaba junto con la del nombre cuando otro perfil ganaba
            # el desempate, y entonces no habia forma de apuntar al de Dornalei que esta en
            # el registro de vistos, porque el propio {PJ} le ganaba.
            clave = unicodedata.normalize("NFC", etiqueta)
            anterior = encontrados.get(clave)
            if not anterior or anterior["rango"] < rango:
                encontrados[clave] = registro
            previo = encontrados.get(nk(nombre))
            if previo and previo["rango"] >= rango:
                continue
            encontrados[nk(nombre)] = registro
    return encontrados


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    p = perfiles()
    print("perfiles {PJ} con About: %d" % len(p))
    for k in sorted(p):
        d = p[k]
        print("   %-26s %-10s %d frames: %s" % (
            d["nombre"], d["cuenta"], len(d["frames"]),
            ", ".join(f["title"][:18] or "(sin titulo)" for f in d["frames"][:6])))


if __name__ == "__main__":
    main()
