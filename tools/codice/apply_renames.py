# -*- coding: utf-8 -*-
# Aplica los renombrados aprobados al compendio del addon.
# Los destinos se escriben con la convencion del propio compendio: sin tildes y con
# mayuscula solo inicial (preservando nombres propios).
import io, re, os, sys, glob, unicodedata
sys.stdout.reconfigure(encoding="utf-8")
COMP = glob.glob(r"C:/Users/marco/Documents/New project/**/HarfordCompendio.lua", recursive=True)[0]

# viejo -> nuevo (ya en la convencion del addon)
RENAMES = {
    "Salvar a los moribundos": "Piedad con los moribundos",
    "Spray venenoso": "Rociada venenosa",
    "Amigos": "Amistad",
    "Saeta guiada": "Saeta guia",
    "Maldicion": "Maleficio",
    "Susurros disonantes": "Susurros discordantes",
    "Detectar veneno y enfermedad": "Detectar venenos y enfermedades",
    "Golpe furioso": "Castigo furioso",
    "Rayo de bruja": "Rayo de hechiceria",
    "Cofre secreto de Leomund": "Cofre oculto de Leomund",
    "Esfera resiliente de Otiluke": "Esfera elastica de Otiluke",
    "Invisibilidad mayor": "Invisibilidad mejorada",
    "Piel de piedra": "Piel petrea",
    "Poliformar": "Polimorfar",
    "Proteccion contra la muerte": "Guarda contra la muerte",
    "Sabueso de Mordenkainen": "Mastin fiel de Mordenkainen",
    "Terreno ilusorio": "Terreno alucinatorio",
    "Corona de locura": "Corona de la locura",
    "Golpe cegador": "Castigo cegador",
}

d = io.open(COMP, encoding="utf-8", newline="").read()
starts = list(re.finditer(r"\n {8}id = \"[a-z0-9_]+\",", d))
done, missing = [], dict(RENAMES)
out, cursor = [], 0
for i, m in enumerate(starts):
    end = starts[i+1].start() if i+1 < len(starts) else len(d)
    blk = d[m.start():end]
    nm = re.search(r'(\bname = ")([^"]+)(")', blk)
    if not nm: continue
    old = nm.group(2)
    if old in RENAMES:
        new = RENAMES[old]
        a = m.start() + nm.start(2); b = m.start() + nm.end(2)
        out.append(d[cursor:a]); out.append(new); cursor = b
        done.append((old, new)); missing.pop(old, None)
out.append(d[cursor:])
result = "".join(out)

print("renombrados aplicados:", len(done))
for o, n in done: print("   %-32s -> %s" % (o, n))
if missing: print("\nNO ENCONTRADOS en el compendio:", list(missing))
if "--apply" in sys.argv:
    io.open(COMP, "w", encoding="utf-8", newline="").write(result)
    print("\nESCRITO:", COMP)
