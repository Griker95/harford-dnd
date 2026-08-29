# -*- coding: utf-8 -*-
# Vuelca al compendio del addon las descripciones limpias y validadas de los manuales.
# Sin --apply solo compara y muestra; con --apply escribe el archivo.
import io, re, os, sys, json, glob
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
COMP = glob.glob(r"C:/Users/marco/Documents/New project/**/HarfordCompendio.lua"  # desde la RAIZ: el compendio salio de Harford/ al pasar a addon LoadOnDemand, recursive=True)[0]

KEEP = json.load(io.open(os.path.join(HERE, "spelltext_clean.json"), encoding="utf-8"))
DESC_RE = re.compile(r'(\bdescription = ")((?:[^"\\]|\\.)*)(")')

def lua_escape(t):
    """Texto -> literal Lua de una linea (el compendio guarda cada campo en una linea)."""
    t = t.replace("\\", "\\\\").replace('"', '\\"')
    return t.replace("\r", "").replace("\n", "\\n")

d = io.open(COMP, encoding="utf-8", newline="").read()
starts = list(re.finditer(r"\n {8}id = \"([a-z0-9_]+)\",", d))
out, cursor = [], 0
changed, shorter, same = [], [], 0
for i, m in enumerate(starts):
    end = starts[i+1].start() if i+1 < len(starts) else len(d)
    blk = d[m.start():end]
    nm = re.search(r'\bname = "([^"]+)"', blk)
    dm = DESC_RE.search(blk)
    if not (nm and dm): continue
    name = nm.group(1)
    if name not in KEEP: continue
    old = dm.group(2)
    new = lua_escape(KEEP[name]["text"])
    if new == old: same += 1; continue
    # no reemplazar por algo notablemente mas pobre que lo que ya hay
    if len(new) < len(old) * 0.6:
        shorter.append((name, len(old), len(new))); continue
    a = m.start() + dm.start(2); b = m.start() + dm.end(2)
    out.append(d[cursor:a]); out.append(new); cursor = b
    changed.append((name, KEEP[name]["src"], len(old), len(new)))
out.append(d[cursor:])
result = "".join(out)

print("descripciones a sustituir:", len(changed))
print("  ya identicas:", same, "| descartadas por ser mas pobres:", len(shorter))
if shorter:
    print("  (descartadas):", ", ".join("%s %d->%d" % s for s in shorter[:8]))
print("\nmuestra:")
for n, s, lo, ln in changed[:8]:
    print("  %-30s [%s] %d -> %d chars" % (n[:29], s[:14], lo, ln))

if "--apply" in sys.argv:
    io.open(COMP, "w", encoding="utf-8", newline="").write(result)
    print("\nESCRITO:", COMP)
