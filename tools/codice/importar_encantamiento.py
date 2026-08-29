# -*- coding: utf-8 -*-
"""Sustituye las recetas de Encantamiento del addon por las 200 de Wowhead Classic.

Las recetas del proyecto referencian sus materiales por CLAVE del registro de items, no por
nombre, asi que hay que hacer dos cosas a la vez: dar de alta los materiales y resultados
nuevos en HarfordProfessionsItems y reescribir el bloque de recetas de la profesion.

Se reutiliza la clave que ya exista para un material (comparando el nombre sin tildes): asi
"Polvo extraño" sigue siendo `polvo_extrano` y no se duplica con las recetas de Ingenieria,
que tambien lo gastan.

Dos decisiones de reglas, porque Wowhead no las trae:
  - la CD sale del nivel de habilidad, `10 + skill//37` acotado a 20. Coincide con las CD
    que ya tenian las recetas de encantamiento del proyecto (300 -> 18, 275 -> 17, 250 -> 16).
  - un encantamiento no produce objeto en WoW: se aplica a una pieza. El proyecto ya
    resolvia eso entregando un pergamino, y se mantiene ese criterio.

Sin --apply solo informa.
"""
import io
import json
import os
import re
import sys
import unicodedata

BASE = os.path.dirname(os.path.abspath(__file__))
JSON_WH = os.path.join(BASE, "cotejo", "encantamiento_wowhead.json")
ADDON = r"C:/Users/marco/Documents/New project/HarfordProfesiones"
F_DATA = os.path.join(ADDON, "HarfordProfesiones.lua")
F_ITEMS = os.path.join(ADDON, "HarfordProfesionesItems.lua")


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn")


def slug(s, tope=40):
    s = re.sub(r"[^a-z0-9]+", "_", sa(s).lower()).strip("_")
    return s[:tope].strip("_")


def cd(skill):
    return max(8, min(20, 10 + int(skill or 0) // 37))


def pergamino(nombre):
    """Nombre del pergamino que entrega un encantamiento."""
    n = re.sub(r"(?i)^encantar\s+", "", nombre)
    n = n.replace(":", ",")
    return "Pergamino: " + n[0].lower() + n[1:]


def bloque_registry(items_lua):
    i = items_lua.find("API.REGISTRY = {")
    if i < 0:
        raise SystemExit("no encuentro API.REGISTRY")
    ini = i + len("API.REGISTRY = {")
    prof, k = 1, ini
    while k < len(items_lua) and prof:
        if items_lua[k] == "{":
            prof += 1
        elif items_lua[k] == "}":
            prof -= 1
        k += 1
    return ini, k - 1


def main():
    recetas = json.load(io.open(JSON_WH, encoding="utf-8"))
    data = io.open(F_DATA, encoding="utf-8", newline="").read()
    items = io.open(F_ITEMS, encoding="utf-8", newline="").read()

    # --- claves ya registradas, por nombre normalizado ---
    ri, rf = bloque_registry(items)
    reg = items[ri:rf]
    por_nombre, claves = {}, set()
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*\{([^}]*)\}', reg):
        claves.add(m.group(1))
        mn = re.search(r'name\s*=\s*"([^"]*)"', m.group(2))
        if mn:
            por_nombre.setdefault(sa(mn.group(1)).lower(), m.group(1))

    nuevos = {}          # clave -> (nombre, icono, idWowhead)

    def clave(nombre, icono=None, wid=None):
        n = sa(nombre).lower()
        if n in por_nombre:
            return por_nombre[n]
        k = slug(nombre)
        base, i = k, 2
        while k in claves and k not in nuevos:
            k = "%s_%d" % (base, i)
            i += 1
        por_nombre[n] = k
        claves.add(k)
        nuevos.setdefault(k, (nombre, icono, wid))
        return k

    # --- recetas nuevas ---
    lineas, usados_id = [], set()
    for r in sorted(recetas, key=lambda x: ((x.get("skill") or 0), sa(x["name"]).lower())):
        rid, i = "enc_" + slug(r["name"], 34), 2
        while rid in usados_id:
            rid = "enc_%s_%d" % (slug(r["name"], 30), i)
            i += 1
        usados_id.add(rid)
        mats = ", ".join(
            '{ key = "%s", qty = %d }' % (clave(m["name"], m.get("icon"), m["id"]), m["qty"])
            for m in r["reagents"])
        c = r.get("creates")
        if c:
            ok, oq = clave(c["name"], c.get("icon"), c["id"]), c.get("qty") or 1
        else:
            ok, oq = clave(pergamino(r["name"]), "inv_scroll_03"), 1
        desc = (r.get("efecto") or "").replace("\\", "").replace('"', "'")
        lineas.append(
            '    { id = "%s", profession = "encantamiento", skillReq = %d, name = "%s", '
            'icon = "%s", dc = %d, materials = { %s }, output = { key = "%s", qty = %d }%s },'
            % (rid, r.get("skill") or 1, r["name"].replace('"', "'"),
               r.get("icon") or "INV_Scroll_03", cd(r.get("skill")), mats, ok, oq,
               (', desc = "%s"' % desc) if desc else ""))

    # --- quitar las recetas de encantamiento que hubiera ---
    def equilibrado(t, i):
        d = 0
        for j in range(i, len(t)):
            if t[j] == "{":
                d += 1
            elif t[j] == "}":
                d -= 1
                if d == 0:
                    return j + 1
        return len(t)

    rm = re.search(r"D\.RECIPES\s*=\s*\{", data)
    pos, fuera, primera, viejas = rm.end(), [], None, 0
    while True:
        m = re.search(r'\{\s*id\s*=\s*"', data[pos:])
        if not m:
            break
        ini = pos + m.start()
        fin = equilibrado(data, ini)
        blk = data[ini:fin]
        if re.search(r'profession\s*=\s*"encantamiento"', blk):
            viejas += 1
            # la linea entera, con su sangria y su coma final
            a = data.rfind("\n", 0, ini) + 1
            b = fin
            if data[b:b + 1] == ",":
                b += 1
            fuera.append((a, b))
            if primera is None:
                primera = a
        pos = fin

    print("recetas nuevas: %d   recetas de encantamiento que se retiran: %d" % (len(lineas), viejas))
    print("materiales/resultados nuevos en el registro: %d" % len(nuevos))
    print("CD: %d..%d" % (min(cd(r.get("skill")) for r in recetas),
                          max(cd(r.get("skill")) for r in recetas)))
    if "--apply" not in sys.argv:
        for l in lineas[:4]:
            print("  " + l.strip()[:180])
        return

    for a, b in reversed(fuera):
        data = data[:a] + data[b:]
        if primera is not None and a < primera:
            primera -= (b - a)
    cuerpo = ("    -- ===== Encantamiento (200 recetas, Wowhead Classic es) =====\n"
              + "\n".join(lineas) + "\n")
    if primera is None:
        primera = re.search(r"D\.RECIPES\s*=\s*\{", data).end() + 1
    data = data[:primera] + cuerpo + data[primera:]
    io.open(F_DATA, "w", encoding="utf-8", newline="").write(data)

    bloque = ["\n    -- ===== Encantamiento (materiales y resultados de Wowhead Classic).",
              "    -- `wow` es el itemId de WoW Classic: sirve para mapear al item de Epsilon"
              " cuando se indique. =====",
              ]
    for k in sorted(nuevos):
        nombre, icono, wid = nuevos[k]
        bloque.append('    ["%s"] = { id = nil, name = "%s"%s%s },'
                      % (k, nombre.replace('"', "'"),
                         ', icon = "%s"' % icono if icono else "",
                         ", wow = %d" % wid if wid else ""))
    ri, rf = bloque_registry(items)
    items = items[:rf] + "\n".join(bloque) + "\n" + items[rf:]
    io.open(F_ITEMS, "w", encoding="utf-8", newline="").write(items)
    print("\nescrito")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
