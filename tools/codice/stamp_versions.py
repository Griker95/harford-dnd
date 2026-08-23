# -*- coding: utf-8 -*-
"""Sella los js y los css de la web con un hash de SU PROPIO CONTENIDO.

Los navegadores cachean estos ficheros y sin sello los jugadores ven datos viejos tras cada
despliegue. Los CSS se quedaron fuera mucho tiempo y eso es peor todavia: un cambio de
estilo no llegaba nunca sin recarga forzada.

Antes se sellaba con el commit corto de HEAD, y eso fallaba de una forma silenciosa: si se
ejecuta ANTES de commitear -- que es lo natural, porque el sello cambia el HTML y tiene que
entrar en ese mismo commit -- el sello queda con el commit ANTERIOR. El fichero servido en
esa URL ya es el nuevo, asi que quien entra de cero lo ve bien; pero quien visito la web
durante el commit anterior tiene esa MISMA URL cacheada con el contenido viejo y no recibe
la actualizacion. El sello llegaba un despliegue tarde justo para quien ya estaba mirando.

Con el hash del contenido la URL cambia exactamente cuando cambia el fichero, sin depender
del orden de los commits, y un fichero que no ha cambiado conserva su cache.
"""
import hashlib
import io
import os
import re
import sys

WEB = r"C:/Users/marco/Documents/harfordweb"

PAT_CSS = re.compile(r'href="css/([a-z-]+\.css)(\?v=[a-z0-9]+)?"')
PAT_JS = re.compile(
    r'src="js/(compendium[a-z-]*\.js|search\.js|characters\.js|organizations\.js'
    r'|contacts\.js|places\.js|assets\.js|intelligence\.js|app\.js)(\?v=[a-z0-9]+)?"')

PAGINAS = ("compendio.html", "buscar.html", "index.html", "historia.html", "personajes.html",
           "intelligence.html", "organizacion.html", "expediente.html", "activos.html",
           "reclutamiento.html", "reglas.html")

_cache = {}


def sello(rel):
    """Hash corto del contenido del asset. Si no existe, no se sella: vale mas dejar la URL
    limpia que inventar una version para un fichero que no esta."""
    if rel not in _cache:
        ruta = os.path.join(WEB, rel)
        try:
            with io.open(ruta, "rb") as fh:
                _cache[rel] = hashlib.md5(fh.read()).hexdigest()[:10]
        except FileNotFoundError:
            _cache[rel] = None
    return _cache[rel]


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    tocados = 0
    for f in PAGINAS:
        p = os.path.join(WEB, f)
        try:
            t = io.open(p, encoding="utf-8").read()
        except FileNotFoundError:
            continue

        def sub(m, carpeta, attr):
            v = sello("%s/%s" % (carpeta, m.group(1)))
            if not v:
                return '%s="%s/%s"' % (attr, carpeta, m.group(1))
            return '%s="%s/%s?v=%s"' % (attr, carpeta, m.group(1), v)

        t2 = PAT_JS.sub(lambda m: sub(m, "js", "src"), t)
        t2 = PAT_CSS.sub(lambda m: sub(m, "css", "href"), t2)
        if t2 != t:
            io.open(p, "w", encoding="utf-8", newline="").write(t2)
            tocados += 1
            print("%s sellado" % f)
    faltan = [k for k, v in _cache.items() if not v]
    for k in faltan:
        print("  sin fichero, sin sello: %s" % k)
    print("hecho (%d paginas actualizadas, %d assets)" % (tocados, len(_cache) - len(faltan)))


if __name__ == "__main__":
    main()
