# -*- coding: utf-8 -*-
"""Pipeline de extraccion del conocimiento del addon. Su producto principal es
`kb_icons.json`: clases, razas, trasfondos, conjuros y profesiones con textos completos e
iconos, listo para alimentar LA WEB (el consultor canonico). Tambien puede montar el HTML
local Codice_Harford.html, que quedo como fallback offline: la web manda.

Uso:  python tools/codice/build_codice.py

Cadena: extract_kb.py (addon -> kb.json) -> add_icons_kb.py (+iconos de EpsilonIcons ->
kb_icons.json + icons_data.json) -> add_full_desc.py (+texto completo de RuleSource y Discord)
-> inyeccion en codice_template.html. Los .json intermedios se regeneran siempre (gitignored);
bgs_source.json lo REGENERA `trasfondos_desde_export.py` desde RuleSource/Discord_Export
(42 trasfondos). Antes se extrajo a mano de un export parcial de 25 y estaba marcado como
fuente no regenerable; ya no lo es. Se versiona igual, porque el pipeline lo lee.

Requiere en disco: EpsilonIcons/png (dump de iconos) y RuleSource/ (manuales MD + exports).
"""
import io, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

for step in ("extract_kb.py", "add_icons_kb.py", "add_full_desc.py"):
    print("==", step)
    r = subprocess.run([sys.executable, os.path.join(HERE, step)])
    if r.returncode != 0:
        sys.exit("fallo en " + step)

tpl = io.open(os.path.join(HERE, "codice_template.html"), encoding="utf-8").read()
kb = io.open(os.path.join(HERE, "kb_icons.json"), encoding="utf-8").read().replace("</", "<\/")
ic = io.open(os.path.join(HERE, "icons_data.json"), encoding="utf-8").read().replace("</", "<\/")
out = os.path.join(ROOT, "Codice_Harford.html")
io.open(out, "w", encoding="utf-8").write(tpl.replace("/*KBDATA*/", kb).replace("/*ICONDATA*/", ic))
print("Codice_Harford.html regenerado: %d KB" % (os.path.getsize(out) // 1024))
