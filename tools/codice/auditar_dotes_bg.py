# -*- coding: utf-8 -*-
"""Revision UNO A UNO de dotes y trasfondos: informacion recortada o mal colocada.

Para cada entrada compara el texto que tiene con el que hay en los libros y avisa de:
  - texto mas corto que el del libro (informacion recortada)
  - texto que no menciona el nombre ni comparte vocabulario (mal colocado)
  - campos de trasfondo vacios (competencias, equipo, rasgo)
"""
import io, os, re, sys, json, glob, unicodedata
sys.stdout.reconfigure(encoding="utf-8")
SP = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SP)
import libro1

WEB = r"C:/Users/marco/Documents/harfordweb"

def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
def nk(s):
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]+", " ", sa(s).lower())).strip()
def toks(s):
    return {w for w in re.findall(r"[a-z]{5,}", sa(s).lower())}

def cargar_js(fichero, abre="["):
    t = io.open(os.path.join(WEB, "js", fichero), encoding="utf-8").read()
    cierra = "]" if abre == "[" else "}"
    return json.loads(t[t.find(abre): t.rfind(cierra) + 1])

# --- fuentes: Libro 1 (manda) y Manual del Jugador ---
PHB = r"C:/Users/marco/Documents/New project/RuleSource/Export/d_d_5_0_edge_manual_del_jugador/texto.md"
phb = io.open(PHB, encoding="utf-8").read().replace("\r", "") if os.path.exists(PHB) else ""

def texto_libro(nombre):
    """Texto del Libro 1 (por titulo o negrita) o, de relleno, del Manual del Jugador."""
    n = nk(nombre)
    for d in (libro1.dotes(), libro1.entradas("Dotes"), libro1.equipo()):
        if n in d: return ("Warcraft 5ª", d[n])
    s = libro1.seccion(nombre)
    if s: return ("Warcraft 5ª", s)
    if phb:
        m = re.search(r"^#{1,6}\s*" + re.escape(nombre.upper()) + r"\s*$", phb, re.M)
        if m:
            fin = len(phb)
            m2 = re.search(r"^#{1,6}\s+\S", phb[m.end():], re.M)
            if m2: fin = m.end() + m2.start()
            return ("Manual del Jugador", phb[m.end():fin].strip())
    return (None, None)

print("=" * 70)
print("DOTES")
print("=" * 70)
dotes = cargar_js("compendium-dotes.js")
cortas, malas, sinf = [], [], []
for d in dotes:
    txt = d.get("desc") or ""
    fuente, libro = texto_libro(d["name"])
    if not libro:
        if len(txt) < 150: sinf.append(d["name"])
        continue
    if len(libro) > len(txt) * 1.5 and len(libro) - len(txt) > 120:
        cortas.append((d["name"], len(txt), len(libro), fuente))
    elif txt and len(toks(txt) & toks(libro)) < max(2, len(toks(libro)) * 0.15):
        malas.append((d["name"], fuente, txt[:60], libro[:60]))
print("dotes: %d | RECORTADAS: %d | posible texto ajeno: %d | sin fuente y cortas: %d"
      % (len(dotes), len(cortas), len(malas), len(sinf)))
for x in cortas[:20]: print("   RECORTADA  %-32s %4d -> %4d chars  [%s]" % (x[0][:31], x[1], x[2], x[3]))
for x in malas[:10]: print("   AJENO      %-32s [%s]\n              tiene: %s\n              libro: %s" % (x[0][:31], x[1], x[2], x[3]))
if sinf: print("   sin fuente:", ", ".join(sinf[:14]))

print()
print("=" * 70)
print("TRASFONDOS")
print("=" * 70)
kb = json.load(io.open(os.path.join(SP, "kb_icons.json"), encoding="utf-8"))
bgs = kb["backgrounds"]
sin_campo, cortos2 = [], []
CLAVES = ("competencia", "equipo", "idioma", "caracteristica", "rasgo")
for b in bgs:
    tr = b.get("traits", [])
    vacios = [t["name"] for t in tr if len(t.get("desc") or "") < 12]
    tiene = {c for c in CLAVES for t in tr if nk(t["name"]).startswith(c)}
    falta = [c for c in ("competencia", "equipo") if c not in tiene]
    if vacios or falta:
        sin_campo.append((b["name"], vacios[:3], falta))
    if len(b.get("desc") or "") < 200:
        cortos2.append((b["name"], len(b.get("desc") or "")))
print("trasfondos: %d | con campo vacio o ausente: %d | intro corta: %d"
      % (len(bgs), len(sin_campo), len(cortos2)))
for x in sin_campo[:22]:
    print("   %-30s vacios=%-34s falta=%s" % (x[0][:29], str(x[1])[:33], x[2]))
