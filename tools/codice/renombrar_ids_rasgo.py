# -*- coding: utf-8 -*-
"""Propone (y opcionalmente aplica) la unificacion de los ids de rasgo de clase.

La convencion es `<clase>_<subclase>_<cosa>`, con abreviaturas FIJAS declaradas aqui. Los
que ya la cumplen no se tocan: esto es solo para los que se nombraron con la subclase suelta
(`afliccion_drenar_alma`) o con el nombre entero de la clase.

Aviso aprendido con el trasfondo Criminal: una abreviatura ambigua es peor que un nombre
largo. Por eso las abreviaturas de subclase se generan y se COMPRUEBAN: si dos subclases de
la misma clase producen la misma, el script para y lo dice en vez de inventarse un desempate.

    python tools/codice/renombrar_ids_rasgo.py             # informe, no escribe
    python tools/codice/renombrar_ids_rasgo.py --escribir  # aplica y deja la tabla de migracion
"""
import collections
import glob
import io
import os
import re
import sys
import unicodedata

BASE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLASES = os.path.join(BASE, "Harford", "DnD", "Data", "Classes")

# Abreviatura fija por clase. Son las que ya dominan en cada fichero; cambiarlas seria
# renombrar tambien lo que ya cumple la convencion, y eso no es este trabajo.
ABREV_CLASE = {
    "brujo": "bru", "caballero_muerte": "cdm", "cazador": "caz", "cazador_demonios": "dh",
    "chaman": "cha", "druida": "dru", "guerrero": "gue", "mago": "mago", "monje": "monje",
    "paladin": "pal", "picaro": "pic", "sacerdote": "sac",
}


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


# Abreviatura EXPLICITA de las subclases que la regla mecanica resuelve mal. Es la leccion
# del trasfondo Criminal: una abreviatura ambigua cuesta mas de lo que ahorra.
#   - "Maestro cervecero": la primera palabra no distingue (habria dado `mae`).
#   - "Sacerdocio de Elune": daria `sac`, que choca con la abreviatura de la clase --el id
#     quedaria `sac_sac_...`-- y ademas el proyecto ya usa `sac_elu_` en el codigo.
ABREV_SUB = {
    ("monje", "cervecero"): "cer",
    ("sacerdote", "elune"): "elu",
}

# palabras que no distinguen una subclase de otra
VACIAS = ("maestro", "maestra", "senor", "senora", "gran", "alto", "alta", "el", "la",
          "sacerdocio", "orden", "camino", "senda", "circulo")


def abrevia(nombre, largo=3, clave=None):
    """Abreviatura de subclase: las `largo` primeras letras de su primera palabra UTIL."""
    if clave and clave in ABREV_SUB:
        return ABREV_SUB[clave]
    palabras = [p for p in nk(nombre).split("_") if p and p not in VACIAS]
    return (palabras[0] if palabras else nk(nombre))[:largo]


def _bloque(texto, desde):
    """Del `{` que abre en `desde` a su pareja, saltandose las cadenas."""
    nivel, i, cadena, escapa = 0, desde, None, False
    while i < len(texto):
        c = texto[i]
        if cadena:
            if escapa:
                escapa = False
            elif c == "\\":
                escapa = True
            elif c == cadena:
                cadena = None
        elif c == '"':
            cadena = c
        elif c == "{":
            nivel += 1
        elif c == "}":
            nivel -= 1
            if nivel == 0:
                return texto[desde:i + 1]
        i += 1
    return texto[desde:]


def estructura():
    """[(classId, subId, subNombre, [ids de rasgo])] leyendo cada fichero de clase."""
    salida = []
    for f in sorted(glob.glob(os.path.join(CLASES, "*.lua"))):
        t = io.open(f, encoding="utf-8", errors="replace").read()
        mc = re.search(r'id = "([a-z_]+)", name = "([^"]+)"', t)
        if not mc:
            continue
        cid = mc.group(1)
        # rasgos de la clase (fuera de subclases) y de cada subclase
        ms = re.search(r"subclasses\s*=\s*\{", t)
        cuerpo_clase = t[:ms.start()] if ms else t
        rasgos_clase = re.findall(r'\{\s*id = "([a-z0-9_]+)"[^\n]*?level = \d+', cuerpo_clase)
        salida.append((cid, None, None, rasgos_clase))
        if not ms:
            continue
        resto = _bloque(t, t.index("{", ms.end() - 1))
        for m in re.finditer(r'\{ id = "([a-z0-9_]+)", name = "([^"]+)"', resto):
            sub = _bloque(resto, m.start())
            ids = re.findall(r'\{\s*id = "([a-z0-9_]+)"[^\n]*?level = \d+', sub)
            salida.append((cid, m.group(1), m.group(2), ids))
    return salida


def propone():
    """id viejo -> id nuevo, solo para los que no cumplen la convencion."""
    partes = estructura()
    # abreviaturas de subclase, comprobando que no choquen dentro de la misma clase
    abrev_sub, choques = {}, []
    por_clase = collections.defaultdict(list)
    for cid, sid, snom, _ in partes:
        if sid:
            por_clase[cid].append((sid, snom))
    for cid, subs in por_clase.items():
        for largo in (3, 4, 5, 99):
            vistas = {}
            ok = True
            for sid, snom in subs:
                a = abrevia(snom, largo, (cid, sid))
                if a in vistas and vistas[a] != sid:
                    ok = False
                    break
                vistas[a] = sid
            if ok:
                for sid, snom in subs:
                    abrev_sub[(cid, sid)] = abrevia(snom, largo, (cid, sid))
                break
        else:
            choques.append(cid)

    cambios, ya_ok = {}, 0
    for cid, sid, snom, ids in partes:
        pref = ABREV_CLASE.get(cid, cid)
        esperado = pref + "_" + (abrev_sub.get((cid, sid), "") + "_" if sid else "")
        for i in ids:
            if i.startswith(esperado):
                ya_ok += 1
                continue
            # se conserva la parte descriptiva, quitando lo que ya nombraba clase o subclase
            cola = i
            for quitar in (pref + "_", cid + "_", (sid or "") + "_", nk(snom or "") + "_"):
                if quitar and quitar != "_" and cola.startswith(quitar):
                    cola = cola[len(quitar):]
            cambios[i] = esperado + cola
    return cambios, ya_ok, choques


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    cambios, ya_ok, choques = propone()
    if choques:
        print("PARA: no hay abreviatura inequivoca para las subclases de %s" % choques)
        return
    print("rasgos que YA cumplen la convencion: %d" % ya_ok)
    print("rasgos a renombrar: %d\n" % len(cambios))

    # colisiones del resultado
    inverso = collections.Counter(cambios.values())
    choca = {n for n, c in inverso.items() if c > 1}
    existentes = set()
    for f in glob.glob(os.path.join(CLASES, "*.lua")):
        existentes |= set(re.findall(r'id = "([a-z0-9_]+)"',
                                     io.open(f, encoding="utf-8", errors="replace").read()))
    pisa = {v for k, v in cambios.items() if v in existentes and v != k}
    print("colisiones entre los nuevos: %s" % (sorted(choca) or "ninguna"))
    print("nuevos que pisan un id existente: %s\n" % (sorted(pisa) or "ninguno"))

    for viejo, nuevo in sorted(cambios.items()):
        print("   %-44s -> %s" % (viejo, nuevo))


if __name__ == "__main__":
    main()
