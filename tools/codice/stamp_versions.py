# -*- coding: utf-8 -*-
"""Sella los js y los css de la web con el commit corto actual.

Ejecutar en el repo de la web DESPUES de commitear datos nuevos y ANTES del commit final,
o simplemente tras regenerar datos: los navegadores cachean estos ficheros y sin esto los
jugadores ven datos viejos tras cada despliegue. Los CSS se quedaron fuera mucho tiempo y
eso es peor todavia: un cambio de estilo no llegaba nunca sin recarga forzada.
"""
import io, re, subprocess, sys

WEB = r"C:/Users/marco/Documents/harfordweb"
sys.stdout.reconfigure(encoding="utf-8")
v = subprocess.check_output(["git", "-C", WEB, "rev-parse", "--short", "HEAD"]).decode().strip()
PAT_CSS = re.compile(r'href="css/([a-z-]+\.css)(\?v=[a-z0-9]+)?"')
PAT = re.compile(r'src="js/(compendium[a-z-]*\.js|search\.js|characters\.js|organizations\.js|contacts\.js|places\.js|assets\.js|intelligence\.js|app\.js)(\?v=[a-z0-9]+)?"')
for f in ("compendio.html", "buscar.html", "index.html", "historia.html", "personajes.html",
          "intelligence.html", "organizacion.html", "expediente.html", "activos.html",
          "reclutamiento.html", "reglas.html"):
    p = WEB + "/" + f
    try:
        t = io.open(p, encoding="utf-8").read()
    except FileNotFoundError:
        continue
    t2 = PAT.sub(lambda m: 'src="js/%s?v=%s"' % (m.group(1), v), t)
    t2 = PAT_CSS.sub(lambda m: 'href="css/%s?v=%s"' % (m.group(1), v), t2)
    if t2 != t:
        io.open(p, "w", encoding="utf-8", newline="").write(t2)
        print(f, "->", v)
print("hecho")
