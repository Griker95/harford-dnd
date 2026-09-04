# -*- coding: utf-8 -*-
"""Hoja de eleccion para los iconos que el cliente de Epsilon no sirve.

La comprobacion en juego (`/harford debug run iconoscheck`) dio 15 iconos que la web declara
y el cliente no tiene. Aqui se eligen los sustitutos.

Lo que distingue esta hoja de las demas: el dump de PNG NO vale como criterio. Cuatro de los
que fallan (Ivern_FriendOfTheForest, Malzahar_VoidShift, poster_darkmoon1, ArcaneIntensity)
ESTAN en el dump y aun asi el cliente no los sirve. Por eso el buscador marca en verde los
que constan como validados --los que la web ya usa y la comprobacion dio por buenos-- y
arranca filtrando por ellos: elegir fuera de ahi es volver a arriesgarse.

    python tools/codice/hoja_iconos_rotos.py

Escribe `hoja_iconos_rotos.html` al lado. Se abre en el navegador, se eligen y el boton de
arriba copia el JSON con las decisiones.
"""
import io
import json
import os
import re
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
DUMP = os.path.join(BASE, "..", "..", "EpsilonIcons", "png")
WEBJS = "C:/Users/marco/Documents/harfordweb/js/"
SALIDA = os.path.join(BASE, "hoja_iconos_rotos.html")
RUTA_DUMP_REL = "../../EpsilonIcons/png"

FALLAN = {
    "arcaneintensity", "hots_resilientshield", "inv_cape_armor_explorer_d_01_backpack",
    "inv_helm_armor_explorer_d_01", "ivern_friendoftheforest", "liming_talrashaselements",
    "malzahar_voidshift", "medivh_ravenform", "tyrande_huntersmark",
    "xinzhao_determination", "eps_bg3_levitate", "eps_lol_zyra_graspingroot",
    "poster_darkmoon1", "eps_bg3_aid",
}

# id, nombre, donde vive, icono que falla, propuesta, alternativas
ENTRADAS = [
    ("feat_mb_potente", "Conjuro potente", "dote", "ArcaneIntensity",
     "spell_arcane_arcane01", ["ability_racial_arcaneaffinity", "ability_socererking_arcaneacceleration"]),
    ("resiliente", "Resiliente", "dote", "HotS_ResilientShield",
     "spell_holy_wordfortitude", ["spell_deathknight_iceboundfortitude", "ability_paladin_shieldofthetemplar"]),
    ("novato_liga_expedicionarios", "Novato de la Liga de Expedicionarios", "trasfondo",
     "INV_Cape_Armor_Explorer_D_01_backpack",
     "inv_misc_bag_01", ["achievement_explore_argus", "inv_misc_map_01"]),
    ("bg_liga_pionero", "Pionero audaz", "rasgo de trasfondo", "INV_Helm_Armor_Explorer_D_01",
     "inv_misc_map02", ["inv_misc_map_01", "achievement_explore_argus"]),
    ("amigo_criaturas", "Amigo de las criaturas", "dote", "Ivern_FriendOfTheForest",
     "ability_hunter_beasttaming", ["ability_hunter_beastsoothe", "ability_hunter_beastwithin"]),
    ("versado_elemento", "Versado en un elemento", "dote", "LiMing_TalRashasElements",
     "ability_shaman_echooftheelements", ["inv_elemental_mote_air01", "ability_shawaterelemental_reform"]),
    ("abrazo_vacio", "Abrazo del Vacío", "dote", "Malzahar_VoidShift",
     "spell_priest_voidshift", ["inv_enchant_voidsphere", "hots_malzahar_voidshift"]),
    ("operativo_ravenholdt", "Operativo de Ravenholdt", "trasfondo", "Medivh_RavenForm",
     "ability_stealth", ["ability_rogue_ambush", "ability_revendreth_rogue"]),
    ("feat_pe_reroll", "Precisión", "dote", "Tyrande_HuntersMark",
     "ability_hunter_focusedaim", ["ability_marksmanship", "ability_hunter_aimedshot"]),
    ("feat_fe_esquivar", "Esquivar y curar", "dote", "XinZhao_Determination",
     "ability_druid_healinginstincts", ["spell_holy_flashheal", "eps_bg3_healingword"]),
    ("levitar", "Levitar", "conjuro", "eps_bg3_levitate",
     "ability_priest_angelicfeather", ["inv_feather_02", "inv_feather_03"]),
    ("enmaranar", "Enmarañar", "conjuro", "eps_lol_zyra_graspingroot",
     "eps_wc3_entanglingroots", ["inv_misc_root_01", "w3reforgedentanglingroots"]),
    ("feriante_luna_negra", "Feriante de la Luna Negra", "trasfondo", "poster_darkmoon1",
     "inv_misc_ticket_tarot_madness", ["inv_darkmoon_vengeance", "inv_misc_ticket_tarot_furies"]),
]

ESTILO = """
:root{--fondo:#0b1622;--caja:#132132;--linea:#24384f;--texto:#dbe6f2;--suave:#8ea6bf;
      --oro:#d4aa4c;--verde:#4cd48a;--rojo:#e06a6a}
*{box-sizing:border-box}
body{margin:0;background:var(--fondo);color:var(--texto);
     font:15px/1.5 system-ui,"Segoe UI",sans-serif}
header{padding:18px 22px;border-bottom:1px solid var(--linea);position:sticky;top:0;
       background:var(--fondo);z-index:5;display:flex;gap:16px;align-items:center}
h1{font-size:1.15rem;margin:0}
.sub{color:var(--suave);font-size:.85rem}
button{background:var(--caja);color:var(--texto);border:1px solid var(--linea);
       border-radius:6px;padding:8px 14px;cursor:pointer;font:inherit}
button:hover{border-color:var(--oro)}
.cols{display:grid;grid-template-columns:1fr 340px;gap:18px;padding:18px 22px;align-items:start}
.fila{background:var(--caja);border:1px solid var(--linea);border-radius:8px;
      padding:12px 14px;margin-bottom:12px}
.cab{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap}
.cab b{font-size:1rem}
.cab code{color:var(--suave);font-size:.78rem}
.donde{margin-left:auto;color:var(--suave);font-size:.78rem;text-transform:uppercase;
       letter-spacing:.06em}
.ops{display:flex;gap:10px;margin-top:10px;flex-wrap:wrap;align-items:flex-start}
.op{width:78px;text-align:center;cursor:pointer;border:2px solid transparent;
    border-radius:8px;padding:5px 3px}
.op:hover{border-color:var(--linea)}
.op.sel{border-color:var(--oro);background:rgba(212,170,76,.10)}
.op img{width:44px;height:44px;border-radius:6px;display:block;margin:0 auto 4px}
.op span{font-size:.62rem;color:var(--suave);word-break:break-all;line-height:1.25;
         display:block}
.rota{opacity:.55}
.rota img{outline:2px solid var(--rojo);outline-offset:-2px}
.sinpng{width:44px;height:44px;border-radius:6px;margin:0 auto 4px;display:grid;place-items:center;color:var(--rojo);border:2px solid var(--rojo);font-weight:700}
.etq{font-size:.6rem;letter-spacing:.05em;text-transform:uppercase;color:var(--suave)}
.panel{position:sticky;top:74px;background:var(--caja);border:1px solid var(--linea);
       border-radius:8px;padding:12px}
.panel input[type=search]{width:100%;padding:8px 10px;border-radius:6px;
       border:1px solid var(--linea);background:var(--fondo);color:var(--texto);font:inherit}
.panel label{display:flex;gap:8px;align-items:center;margin:10px 0;color:var(--suave);
       font-size:.82rem}
.rej{display:grid;grid-template-columns:repeat(5,1fr);gap:6px;margin-top:10px;
     max-height:62vh;overflow:auto}
.rej figure{margin:0;text-align:center;cursor:pointer;border:2px solid transparent;
     border-radius:6px;padding:3px}
.rej figure:hover{border-color:var(--oro)}
.rej img{width:40px;height:40px;border-radius:5px;display:block;margin:0 auto}
.rej figcaption{font-size:.55rem;color:var(--suave);word-break:break-all;line-height:1.2}
.rej .val{outline:2px solid var(--verde);outline-offset:-2px}
.aviso{color:var(--suave);font-size:.8rem;margin:8px 0 0}
"""

GUION = """
// Un icono que ni esta en el dump (eps_bg3_levitate) salia como imagen partida y parecia
// un fallo de la hoja. Se cambia por un cuadro con interrogante.
const sinPng = img => {
  const d = document.createElement('div');
  d.className = 'sinpng';
  d.textContent = '?';
  img.replaceWith(d);
};
document.querySelectorAll('.op img').forEach(img => {
  if (img.complete && img.naturalWidth === 0) sinPng(img);
  else img.addEventListener('error', () => sinPng(img));
});
let destino = null;
const marcar = (fila, icono) => {
  fila.querySelectorAll('.op').forEach(o => o.classList.toggle('sel', o.dataset.icono === icono));
  fila.dataset.elegido = icono;
};
document.querySelectorAll('.fila').forEach(fila => {
  fila.addEventListener('click', e => {
    const op = e.target.closest('.op');
    destino = fila;
    document.querySelectorAll('.fila').forEach(f => f.style.outline = '');
    fila.style.outline = '1px solid var(--oro)';
    if (op && !op.classList.contains('rota')) marcar(fila, op.dataset.icono);
  });
});
const rej = document.getElementById('rej');
const q = document.getElementById('q');
const soloVal = document.getElementById('solo');
function pinta() {
  const t = q.value.trim().toLowerCase();
  const lista = [];
  for (const n of ICONOS) {
    if (soloVal.checked && !VALIDADOS.has(n)) continue;
    if (t && !n.includes(t)) continue;
    lista.push(n);
    if (lista.length >= 120) break;
  }
  rej.innerHTML = lista.map(n =>
    `<figure data-icono="${n}"><img class="${VALIDADOS.has(n) ? 'val' : ''}" loading="lazy"
      src="${RUTA}/${n}.png"><figcaption>${n}</figcaption></figure>`).join('');
}
q.addEventListener('input', pinta);
soloVal.addEventListener('change', pinta);
rej.addEventListener('click', e => {
  const f = e.target.closest('figure');
  if (!f || !destino) return;
  const icono = f.dataset.icono;
  const ops = destino.querySelector('.ops');
  if (!destino.querySelector(`.op[data-icono="${icono}"]`)) {
    const d = document.createElement('div');
    d.className = 'op';
    d.dataset.icono = icono;
    d.innerHTML = `<img src="${RUTA}/${icono}.png"><span>${icono}</span>
                   <span class="etq">a mano</span>`;
    ops.appendChild(d);
  }
  marcar(destino, icono);
});
document.getElementById('copiar').addEventListener('click', () => {
  const out = {};
  document.querySelectorAll('.fila').forEach(f => out[f.dataset.id] = f.dataset.elegido);
  navigator.clipboard.writeText(JSON.stringify(out, null, 1));
  document.getElementById('copiar').textContent = 'copiado';
  setTimeout(() => document.getElementById('copiar').textContent = 'Copiar decisiones', 1200);
});
pinta();
"""


def _validados():
    """Iconos que la web ya usa y la comprobacion en juego dio por buenos."""
    vistos = set()
    for f in ("compendium-data.js", "compendium-dotes.js", "compendium-equipment.js",
              "compendium-languages.js", "compendium-professions.js"):
        ruta = WEBJS + f
        if not os.path.exists(ruta):
            continue
        t = io.open(ruta, encoding="utf-8").read()
        vistos |= {m.group(1).lower() for m in re.finditer(r'"(?:icon|spellIcon)":\s*"([^"]+)"', t)}
    return vistos - FALLAN


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    disponibles = {f[:-4].lower() for f in os.listdir(DUMP) if f.lower().endswith(".png")}
    validados = _validados() & disponibles
    # los validados primero, que son los que conviene elegir
    orden = sorted(disponibles, key=lambda n: (n not in validados, n))

    filas = []
    for _id, nombre, donde, rota, propuesta, alternativas in ENTRADAS:
        ops = ['<div class="op rota"><img src="%s/%s.png"><span>%s</span>'
               '<span class="etq">no la sirve</span></div>' % (RUTA_DUMP_REL, rota, rota)]
        for i, ic in enumerate([propuesta] + alternativas):
            ops.append('<div class="op%s" data-icono="%s"><img src="%s/%s.png"><span>%s</span>'
                       '<span class="etq">%s</span></div>'
                       % (" sel" if i == 0 else "", ic, RUTA_DUMP_REL, ic, ic,
                          "propuesta" if i == 0 else "alternativa"))
        filas.append(
            '<div class="fila" data-id="%s" data-elegido="%s">'
            '<div class="cab"><b>%s</b><code>%s</code><span class="donde">%s</span></div>'
            '<div class="ops">%s</div></div>'
            % (_id, propuesta, nombre, _id, donde, "".join(ops)))

    html = (
        "<!doctype html><meta charset='utf-8'><title>Iconos que Epsilon no sirve</title>"
        "<style>%s</style><header><div><h1>Iconos que el cliente no sirve</h1>"
        "<div class='sub'>%d entradas · el buscador marca en verde los %d validados en juego</div>"
        "</div><button id='copiar'>Copiar decisiones</button></header>"
        "<div class='cols'><div>%s</div>"
        "<aside class='panel'><input id='q' type='search' placeholder='buscar icono…'>"
        "<label><input id='solo' type='checkbox' checked> solo los validados en el cliente</label>"
        "<div id='rej' class='rej'></div>"
        "<p class='aviso'>Pulsa una fila y luego un icono del buscador para asignarlo. "
        "El dump tiene iconos que el cliente NO sirve, por eso conviene el filtro.</p>"
        "</aside></div>"
        "<script>const RUTA=%s;const ICONOS=%s;const VALIDADOS=new Set(%s);%s</script>"
        % (ESTILO, len(ENTRADAS), len(validados), "".join(filas),
           json.dumps(RUTA_DUMP_REL), json.dumps(orden),
           json.dumps(sorted(validados)), GUION))

    io.open(SALIDA, "w", encoding="utf-8", newline="").write(html)
    print("hoja escrita: %s" % SALIDA)
    print("  entradas: %d | iconos del dump: %d | validados en el cliente: %d"
          % (len(ENTRADAS), len(disponibles), len(validados)))


if __name__ == "__main__":
    main()
