# -*- coding: utf-8 -*-
"""Genera el catalogo Lua compacto de objetos usados por Profesiones.

Parte de la exportacion de Wowhead, pero incluye solo los IDs ``wow`` declarados
en HarfordProfessionsItems. Los itemId reales de Epsilon siguen siendo un dato
independiente del registro de profesiones.
"""

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tools" / "codice" / "cotejo" / "objetos_wowhead.json"
REGISTRY = ROOT / "Harford" / "Professions" / "HarfordProfessionsItems.lua"
OUTPUT = ROOT / "Harford" / "Professions" / "HarfordObjectCatalog.lua"

FIELDS = (
    "name", "classicName", "icon", "quality", "ilvl", "pila", "sell", "bind",
    "slot", "type", "armor", "damage", "vel", "dps", "durability", "req",
    "reqProf", "reqSkill", "stats", "effects", "lines",
)


def lua(value, depth=0):
    indent = "    " * depth
    nested = "    " * (depth + 1)
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        if not value:
            return "{}"
        return "{\n" + ",\n".join(
            nested + lua(item, depth + 1) for item in value
        ) + "\n" + indent + "}"
    if isinstance(value, dict):
        if not value:
            return "{}"
        rows = []
        for key, item in value.items():
            if isinstance(key, str) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", key):
                label = key
            else:
                label = "[" + lua(key, depth + 1) + "]"
            rows.append(nested + label + " = " + lua(item, depth + 1))
        return "{\n" + ",\n".join(rows) + "\n" + indent + "}"
    raise TypeError(type(value))


def main():
    exported = json.loads(SOURCE.read_text(encoding="utf-8"))
    registry = REGISTRY.read_text(encoding="utf-8")
    ids = sorted({int(value) for value in re.findall(r"\bwow\s*=\s*(\d+)", registry)})
    data = {}
    for wow_id in ids:
        source = exported.get(str(wow_id))
        if not source:
            raise RuntimeError("Falta el objeto Wowhead %s" % wow_id)
        data[wow_id] = {field: source[field] for field in FIELDS if field in source}

    content = """-- GENERADO por tools/codice/generar_catalogo_objetos.py.\n-- Fuente: tools/codice/cotejo/objetos_wowhead.json.\n-- Solo incluye los objetos Wowhead que referencia HarfordProfessionsItems.\n\nHarfordObjectCatalog = HarfordObjectCatalog or {}\nlocal API = HarfordObjectCatalog\n\nAPI.WOW = """ + lua(data) + """\n\nfunction API.GetWow(wowId)\n    return API.WOW[tonumber(wowId)]\nend\n\nfunction API.GetForEntry(entry)\n    return type(entry) == \"table\" and API.GetWow(entry.wow) or nil\nend\n\nfunction API.GetName(info)\n    return type(info) == \"table\" and (info.name or info.classicName) or nil\nend\n\nfunction API.GetIcon(info)\n    return type(info) == \"table\" and info.icon or nil\nend\n"""
    OUTPUT.write_text(content, encoding="utf-8", newline="\n")
    print("Generado %s objetos en %s" % (len(data), OUTPUT))


if __name__ == "__main__":
    main()
