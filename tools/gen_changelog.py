# -*- coding: utf-8 -*-
"""Regenera CHANGELOG.md desde el historial de git.

Uso:  python tools/gen_changelog.py

Agrupa los commits por mes y por tipo (`feat`, `fix`, `refactor`, `docs`, `chore`). Los mensajes
que no siguen el convenio caen en "Otros", asi que ninguno se pierde.
"""
import re, io, os, sys, subprocess
from collections import OrderedDict

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEP = "\x1f"

MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
         "septiembre", "octubre", "noviembre", "diciembre"]
TIPO = OrderedDict([
    ("feat", "Nuevo"), ("fix", "Arreglos"), ("refactor", "Refactor"),
    ("perf", "Rendimiento"), ("docs", "Documentacion"), ("chore", "Mantenimiento"),
    ("otros", "Otros"),
])

def commits():
    log = subprocess.run(
        ["git", "log", "--reverse", "--date=short", "--format=%h" + SEP + "%ad" + SEP + "%s"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8").stdout
    out = []
    for line in log.split("\n"):
        if not line.strip():
            continue
        sha, date, subject = line.split(SEP)
        match = re.match(r"^([a-z]+)(?:\(([^)]+)\))?:\s*(.+)$", subject)
        if match and match.group(1) in TIPO:
            kind, scope, text = match.group(1), match.group(2), match.group(3)
        else:
            kind, scope, text = "otros", None, subject
        out.append({"sha": sha, "date": date, "kind": kind, "scope": scope, "text": text})
    return out

def build(items):
    by_month = OrderedDict()
    for c in items:
        by_month.setdefault((c["date"][:4], int(c["date"][5:7])), []).append(c)

    out = []
    add = out.append
    add("# Historial de cambios")
    add("")
    add("Historial del addon Harford, generado desde los commits del repositorio y ordenado del mas")
    add("reciente al mas antiguo. Para la arquitectura y los contratos vigentes mira **`AGENTS.md`**;")
    add("para el mapa de modulos, **`ESTRUCTURA.md`**.")
    add("")
    add("Convenio de los mensajes: `feat` nuevo, `fix` arreglo, `refactor` reorganizacion sin cambio de")
    add("comportamiento, `docs` documentacion y `chore` mantenimiento.")
    add("")
    add("Regeneralo con `python tools/gen_changelog.py`.")
    add("")
    add("- Commits: **%d** - del **%s** al **%s**" % (len(items), items[0]["date"], items[-1]["date"]))
    add("")
    for year, month in sorted(by_month, reverse=True):
        group = list(reversed(by_month[(year, month)]))
        add("## %s de %s" % (MESES[month - 1].capitalize(), year))
        add("")
        for kind, label in TIPO.items():
            rows = [c for c in group if c["kind"] == kind]
            if not rows:
                continue
            add("**%s**" % label)
            add("")
            for c in rows:
                scope = ("**%s** - " % c["scope"]) if c["scope"] else ""
                add("- %s%s `%s`" % (scope, c["text"], c["sha"]))
            add("")
    return "\n".join(out)

def main():
    items = commits()
    if not items:
        print("Sin commits: ¿se ejecuta dentro del repositorio?")
        return 1
    io.open(os.path.join(ROOT, "CHANGELOG.md"), "w", encoding="utf-8", newline="\n").write(build(items))
    print("CHANGELOG.md regenerado: %d commits" % len(items))
    return 0

if __name__ == "__main__":
    sys.exit(main())
