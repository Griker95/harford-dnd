# -*- coding: utf-8 -*-
"""Completa los iconos que las recetas de Wowhead necesitan y el dump de Epsilon no tiene.

En el juego basta el NOMBRE del icono: el cliente resuelve `Interface\\Icons\\<nombre>`. La
web no: sirve un PNG suelto desde assets/compendium-icons y, si falta, la receta sale con
el hueco vacio. Aqui se comprueba cada icono contra el dump de EpsilonIcons y lo que falte
se baja de Wowhead y se guarda como PNG con el mismo nombre, para que el resto del pipeline
no tenga que distinguir de donde salio.

Sin --apply solo informa.
"""
import io
import json
import os
import ssl
import sys
import urllib.request

BASE = os.path.dirname(os.path.abspath(__file__))
ENTRADA = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")
PNG = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
ZAM = "https://wow.zamimg.com/images/wow/icons/large/%s.jpg"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE


def usados():
    """Todos los iconos que citan las recetas: el de la receta y el de cada objeto."""
    datos = json.load(io.open(ENTRADA, encoding="utf-8"))
    ic = set()
    for recetas in datos.values():
        for r in recetas:
            if r.get("icon"):
                ic.add(r["icon"].split("\\")[-1].lower())
            for o in list(r.get("reagents") or []) + ([r["creates"]] if r.get("creates") else []):
                if o.get("icon"):
                    ic.add(o["icon"].split("\\")[-1].lower())
    return ic


def main():
    ic = usados()
    faltan = sorted(i for i in ic if not os.path.exists(os.path.join(PNG, i + ".png")))
    print("iconos citados por las recetas: %d" % len(ic))
    print("ya presentes en EpsilonIcons:   %d" % (len(ic) - len(faltan)))
    print("por bajar de Wowhead:           %d" % len(faltan))
    for f in faltan[:15]:
        print("   ", f)
    if "--apply" not in sys.argv or not faltan:
        return

    from PIL import Image
    ok = err = 0
    for n, nombre in enumerate(faltan, 1):
        try:
            req = urllib.request.Request(ZAM % nombre, headers=UA)
            jpg = urllib.request.urlopen(req, timeout=60, context=_CTX).read()
            tmp = os.path.join(BASE, "cotejo", "_icono.jpg")
            io.open(tmp, "wb").write(jpg)
            Image.open(tmp).convert("RGBA").save(os.path.join(PNG, nombre + ".png"))
            ok += 1
        except Exception as ex:                                   # noqa: BLE001
            err += 1
            print("   no se pudo bajar %s (%s)" % (nombre, ex))
        if n % 25 == 0:
            print("   %d/%d" % (n, len(faltan)))
    print("\nbajados %d   fallidos %d" % (ok, err))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
