# -*- coding: utf-8 -*-
"""Lo que es la profesion en si, no sus recetas: rangos, especializaciones y habilidades.

Faltaba justo lo que explica el arbol. Inscripcion no tiene ninguna receta por debajo de 15
y aun asi se sube de 1 a 15: se hace con **Moler**, que no es una receta sino una habilidad
del oficio. Lo mismo pasa con **Prospectar** en Joyeria, **Desencantar** en Encantamiento y
**Buscar minerales** en Mineria.

Todo esto ya venia en las paginas de profesion que se bajaron para las recetas, en el bloque
`WH.Gatherer.addData(6, ...)`, y simplemente no se estaba mirando. No hace falta red.

De cada profesion salen tres cosas:
  - los RANGOS (Aprendiz, Oficial, Experto, Artesano...) con su tope de habilidad;
  - las ESPECIALIZACIONES, que son rangos sin numero (Forjador de armas, Peleteria tribal);
  - las HABILIDADES que no fabrican nada pero suben o sirven al oficio.
"""
import io
import json
import os
import re
import ssl
import sys
import time
import urllib.request

BASE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(BASE, "cotejo", "wowhead_cache")
RECETAS = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")
SALIDA = os.path.join(BASE, "cotejo", "profesion_info.json")

# skill de Wowhead -> (id de profesion en el addon, version de la que se bajo)
PAGINAS = {
    "encantamiento": ("classic", 333), "ingenieria": ("classic", 202),
    "sastreria": ("classic", 197), "alquimia": ("classic", 171),
    "herreria": ("classic", 164), "peleteria": ("classic", 165),
    "primeros_auxilios": ("classic", 129), "mineria": ("classic", 186),
    "cocina": ("classic", 185), "joyeria": ("tbc", 755), "inscripcion": ("wotlk", 773),
}

TOPE = 300              # el sistema no pasa de 300: los rangos de expansion no interesan


def _cerrar(t, i, abre, cierra):
    prof, k = 0, i
    while k < len(t):
        if t[k] == abre:
            prof += 1
        elif t[k] == cierra:
            prof -= 1
            if prof == 0:
                return t[i:k + 1]
        k += 1
    raise ValueError("bloque sin cerrar")


def hechizos(html):
    """El diccionario de hechizos que la pagina declara, recetas incluidas."""
    d = {}
    for m in re.finditer(r"WH\.Gatherer\.addData\(6,\s*\d+,\s*", html):
        try:
            d.update(json.loads(_cerrar(html, m.end(), "{", "}")))
        except ValueError:
            continue
    return d


_MAX = re.compile(r"(?:habilidad|habilidad potencial)[^.]*?de (\d{2,3})", re.I)
_MAX2 = re.compile(r"m[aá]ximo de (\d{2,3})", re.I)


def tope_de(desc):
    m = _MAX.search(desc or "") or _MAX2.search(desc or "")
    return int(m.group(1)) if m else None


# Lo que distingue una especializacion: permite fabricar cosas vetadas al resto. Se mira en
# la descripcion, no en el nombre, porque los nombres no siguen ningun patron ("Peleteria
# dragontina", "Ingeniero goblin", "Maestro forjador de hachas").
_ESPECIALIZACION = re.compile(r"(?i)especial|no est[aá]n al alcance|dispositivos (de los goblins|gn[oó]micos)")
_NOMBRE_ESP = re.compile(r"(?i)^(ingeniero|forjador|maestro forjador|maestro invocador|peleter[ií]a) ")


_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE
_ACTUAL = {}


def _palabras(t):
    return {w for w in re.findall(r"[a-záéíóúñ]{4,}", (t or "").lower())}


def nombre_actual(sid, porDefecto, desc=""):
    """El nombre del hechizo en el juego de hoy, con el de su version como respaldo.

    Classic traduce mal alguna: el hechizo 17039 es "Master Swordsmith" y alli se llama
    "Maestro invocador", que no dice nada y desentona con sus dos hermanas. El juego actual
    lo llama "Maestro forjador de espadas".

    Pero el nombre actual solo vale si es EL MISMO hechizo. Blizzard reutiliza ids: el 2656
    era "Fundiendo" y en el retail de hoy es "Diario de mineria", que no tiene nada que ver.
    Se compara la descripcion y, si no se parecen, se prueba en Pandaria, que es la ultima
    version donde estos hechizos conservan su sentido: alli el 2656 es "Fundicion".
    """
    if sid in _ACTUAL:
        return _ACTUAL[sid] or porDefecto
    _ACTUAL[sid] = None
    # se prueba primero el juego actual y luego Pandaria, que es la ultima version donde
    # estos hechizos de profesion siguen significando lo mismo. La de Classic ya la tenemos.
    for etiqueta, ruta in (("ret", ""), ("mop", "mop-classic/")):
        try:
            cache = os.path.join(CACHE, "spell%s_%s.json" % (etiqueta, sid))
            if os.path.exists(cache):
                d = json.load(io.open(cache, encoding="utf-8"))
            else:
                u = "https://nether.wowhead.com/%stooltip/spell/%s?locale=6" % (ruta, sid)
                req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"})
                t = urllib.request.urlopen(req, timeout=40,
                                           context=_CTX).read().decode("utf-8")
                io.open(cache, "w", encoding="utf-8").write(t)
                time.sleep(0.15)
                d = json.loads(t)
        except Exception:                                         # noqa: BLE001
            continue
        n = (d.get("name") or "").strip()
        if not n or "[" in n:
            continue                    # marcador de posicion, no una traduccion
        act = re.sub(r"<[^>]+>", " ", re.sub(r"<!--.*?-->", "", d.get("tooltip") or "",
                                             flags=re.S))
        a, b = _palabras(desc), _palabras(act)
        # el nombre solo vale si sigue siendo EL MISMO hechizo: Blizzard reutiliza ids y el
        # 2656 paso de "Fundiendo" a "Diario de mineria", que no tiene nada que ver
        if a and len(a & b) / max(len(a), 1) < 0.4:
            continue
        _ACTUAL[sid] = n
        break
    return _ACTUAL[sid] or porDefecto


def limpiar(t):
    return re.sub(r"\s{2,}", " ", (t or "").replace("\r", " ").replace("\n", " ")).strip()


def main():
    recetas = json.load(io.open(RECETAS, encoding="utf-8"))
    fuera = {}
    for pid, (ver, skill) in PAGINAS.items():
        p = os.path.join(CACHE, "skill_%s_%d.html" % (ver, skill))
        if not os.path.exists(p):
            print("  sin pagina cacheada:", pid)
            continue
        html = io.open(p, encoding="utf-8").read()
        spells = hechizos(html)
        ids_receta = {str(x["spell"]) for x in recetas.get(pid, [])}

        rangos, especial, habil = [], [], []
        for sid, v in spells.items():
            if sid in ids_receta:
                continue                       # es una receta, ya esta en su tabla
            nombre = limpiar(v.get("name_eses"))
            desc = limpiar(v.get("description_eses"))
            if not nombre or not desc:
                continue
            rango = limpiar(v.get("rank_eses"))
            mx = tope_de(desc)
            if _ESPECIALIZACION.search(desc) or _NOMBRE_ESP.match(nombre):
                # Una especializacion deja fabricar lo que el resto no puede. Algunas llevan
                # `rank_eses` (Forjador de armas viene como "Artesano", que es el rango que
                # exige) y sin este filtro se colaban como si fueran un rango mas, dos veces
                # "Artesano" y sin tope.
                especial.append({"id": int(sid), "name": nombre_actual(sid, nombre, desc),
                                 "desc": desc, "icon": v.get("icon")})
            elif rango and mx:
                if mx > TOPE:
                    continue                   # rango de expansion, fuera del sistema
                rangos.append({"rank": rango, "max": mx, "desc": desc,
                               "icon": v.get("icon")})
            elif not rango:
                habil.append({"id": int(sid), "name": nombre_actual(sid, nombre, desc),
                              "desc": desc, "icon": v.get("icon")})

        # los rangos vienen desordenados; se ordenan por su tope
        vistos = set()
        rangos = [r for r in sorted(rangos, key=lambda r: r["max"] or 0)
                  if not (r["rank"] in vistos or vistos.add(r["rank"]))]
        # la descripcion de la profesion es la del primer rango, sin la coletilla del tope
        desc = ""
        if rangos:
            # La coletilla del tope pertenece al rango, no a la profesion, y aparece con
            # dos redacciones: "hasta un maximo de habilidad potencial de 75 p." dentro de
            # la frase, y "Da una habilidad potencial de 75." como frase suelta. Al quitarla
            # hay que devolver el punto, o la frase siguiente se pega a la anterior.
            desc = rangos[0]["desc"]
            desc = re.sub(r"(?i),?\s*hasta un[^,.]*?\d{2,3} ?p?\.?", ".", desc)
            desc = re.sub(r"(?i)\s*Da una habilidad[^.]*\.", "", desc)
            desc = re.sub(r"\s*\.\s*\.", ".", desc)
            desc = re.sub(r"\s{2,}", " ", desc).strip()
            if desc and not desc.endswith("."):
                desc += "."
        fuera[pid] = {"desc": desc, "ranks": rangos, "specializations": especial,
                      "abilities": habil}
        print("%-20s rangos %d   especializaciones %d   habilidades %d"
              % (pid, len(rangos), len(especial), len(habil)))
        for h in habil:
            print("      %s" % h["name"])

    io.open(SALIDA, "w", encoding="utf-8").write(json.dumps(fuera, ensure_ascii=False, indent=1))
    print("\nguardado en", SALIDA)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
