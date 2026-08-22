# -*- coding: utf-8 -*-
# Genera el informe navegable de la auditoria de conjuros.
import io, os, json, sys
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
rows = json.load(io.open(os.path.join(HERE, "spell_audit_final.json"), encoding="utf-8"))

SRC = {"manual_del_jugador": "Manual del Jugador", "warcraft_5e_libro1": "Warcraft 5ª · Libro 1",
       "caldero_de_thasa": "Caldero de Tasha", "guia_de_xanathar": "Guía de Xanathar",
       "guia_costa_de_la_espada": "Costa de la Espada", "guia_del_dungeon_master": "Guía del DM",
       "manual_de_monstruos": "Manual de Monstruos", "warcraft_5e_libro2_alt": "Warcraft 5ª · Libro 2"}
slim = [{"n": r["name"], "l": r["level"], "s": r["school"], "g": r["group"],
         "w": 1 if r["group"] == "Warcraft Custom" else 0, "k": r["kind"],
         "b": r["book"], "f": SRC.get(r["src"], r["src"]), "bl": r["bookLvl"], "bs": r["bookSch"],
         "t": (r["text"] or "")[:2600], "m": r["meta"]} for r in rows]
data = json.dumps(slim, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")

html = """<title>Cotejo de Conjuros</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zilla+Slab:wght@500;600;700&family=Source+Sans+3:wght@400;600&family=JetBrains+Mono:wght@400;500&display=swap">
<style>
:root{
  --paper:#f2efe8; --paper-2:#e9e5db; --ink:#1e2733; --ink-2:#4a5665; --ink-3:#7b8593;
  --rule:#d3cec2; --ink-blue:#2d4a6b; --oxide:#a4472f; --amber:#9a7215; --moss:#3f6b4a; --slate:#6b7280;
  --shadow:0 1px 2px rgba(30,39,51,.06),0 8px 24px rgba(30,39,51,.07);
}
:root:not([data-theme="light"]){@media (prefers-color-scheme:dark){
  --paper:#161a20; --paper-2:#1e242c; --ink:#e6e3db; --ink-2:#a8b0ba; --ink-3:#79828d;
  --rule:#2c333c; --ink-blue:#7aa5cf; --oxide:#e08b6e; --amber:#d8b martin; --moss:#7bb98c; --slate:#98a1ad;
  --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px rgba(0,0,0,.35);
}}
:root[data-theme="dark"]{
  --paper:#161a20; --paper-2:#1e242c; --ink:#e6e3db; --ink-2:#a8b0ba; --ink-3:#79828d;
  --rule:#2c333c; --ink-blue:#7aa5cf; --oxide:#e08b6e; --amber:#d8b45c; --moss:#7bb98c; --slate:#98a1ad;
  --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px rgba(0,0,0,.35);
}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font-family:"Source Sans 3",ui-sans-serif,system-ui,sans-serif;line-height:1.6;
  -webkit-font-smoothing:antialiased}
.wrap{width:min(1080px,calc(100% - 40px));margin-inline:auto}
header.top{padding:44px 0 26px;border-bottom:1px solid var(--rule)}
.eyebrow{font-family:"JetBrains Mono",monospace;font-size:11px;letter-spacing:.18em;text-transform:uppercase;color:var(--oxide)}
h1{font-family:"Zilla Slab",Georgia,serif;font-weight:700;font-size:clamp(30px,4.4vw,44px);line-height:1.1;margin:8px 0 10px;text-wrap:balance}
.sub{color:var(--ink-2);max-width:64ch;margin:0}
.filterlabel{font-family:"JetBrains Mono",monospace;font-size:10.5px;letter-spacing:.16em;text-transform:uppercase;color:var(--ink-3);margin:24px 0 7px}
.counts{display:flex;flex-wrap:wrap;gap:8px;margin:0}
.cbtn{cursor:pointer;font:inherit;text-align:left;background:var(--paper-2);border:1px solid var(--rule);border-radius:3px;
  padding:9px 13px;display:flex;flex-direction:column;gap:1px;min-width:112px;transition:border-color .15s,transform .12s}
.cbtn:hover{transform:translateY(-1px)}
.cbtn[aria-pressed="true"]{border-color:currentColor;box-shadow:inset 0 0 0 1px currentColor;
  background:color-mix(in srgb,currentColor 12%,var(--paper-2))}
.cbtn[aria-pressed="true"] .lbl{color:currentColor}
.showing{display:flex;align-items:baseline;gap:10px;margin:0 0 12px;padding-bottom:10px;border-bottom:1px solid var(--rule)}
.showing h2{font-family:"Zilla Slab",Georgia,serif;font-size:20px;font-weight:600;margin:0}
.showing .cnt{font-family:"JetBrains Mono",monospace;font-size:12.5px;color:var(--ink-3);font-variant-numeric:tabular-nums}
.cbtn .num{font-family:"JetBrains Mono",monospace;font-size:19px;font-weight:500;font-variant-numeric:tabular-nums}
.cbtn .lbl{font-size:11.5px;letter-spacing:.05em;text-transform:uppercase;color:var(--ink-3)}
.k-exacto{color:var(--moss)} .k-ocr{color:var(--amber)} .k-traduccion{color:var(--oxide)}
.k-dudoso{color:var(--ink-blue)} .k-sin{color:var(--slate)}
.tools{display:flex;gap:12px;align-items:center;margin:18px 0 0;padding-bottom:20px}
.search{flex:1;display:flex;align-items:center;gap:8px;background:var(--paper-2);border:1px solid var(--rule);border-radius:3px;padding:8px 12px}
.search input{flex:1;border:0;background:none;color:var(--ink);font:inherit;outline:none}
.search input::placeholder{color:var(--ink-3)}
main{padding:22px 0 60px}
.note{background:var(--paper-2);border-left:3px solid var(--oxide);border-radius:0 3px 3px 0;padding:12px 16px;margin:0 0 22px;font-size:14.5px;color:var(--ink-2)}
.note b{color:var(--ink)}
.rows{display:flex;flex-direction:column;gap:6px}
.row{background:var(--paper-2);border:1px solid var(--rule);border-radius:3px;overflow:hidden}
.rhead{width:100%;text-align:left;font:inherit;color:inherit;background:none;border:0;cursor:pointer;
  display:grid;grid-template-columns:minmax(0,1fr) 18px minmax(0,1fr) auto;gap:12px;align-items:center;padding:11px 14px}
.rhead:hover{background:color-mix(in srgb,var(--ink) 4%,transparent)}
.rhead:focus-visible{outline:2px solid var(--ink-blue);outline-offset:-2px}
.nm{font-family:"JetBrains Mono",monospace;font-size:13.5px;font-weight:500;overflow-wrap:anywhere}
.nm.book{color:var(--ink-2)}
.star{color:var(--amber);margin-right:5px}
.origin{display:flex;gap:4px;flex-shrink:0}
.obtn{font:inherit;font-size:12px;cursor:pointer;background:var(--paper-2);border:1px solid var(--rule);
  color:var(--ink-2);border-radius:2px;padding:7px 11px}
.obtn[aria-pressed="true"]{border-color:var(--ink-blue);color:var(--ink);background:color-mix(in srgb,var(--ink-blue) 14%,var(--paper-2))}
.arrow{color:var(--ink-3);text-align:center}
.meta{display:flex;align-items:center;gap:8px;flex-shrink:0}
.chip{font-family:"JetBrains Mono",monospace;font-size:10.5px;letter-spacing:.04em;text-transform:uppercase;
  border:1px solid currentColor;border-radius:2px;padding:2px 7px;white-space:nowrap}
.lvl{font-family:"JetBrains Mono",monospace;font-size:11.5px;color:var(--ink-3);font-variant-numeric:tabular-nums;white-space:nowrap}
.body{display:none;padding:2px 14px 16px;border-top:1px solid var(--rule)}
.row.open .body{display:block}
.body h4{font-family:"JetBrains Mono",monospace;font-size:10.5px;letter-spacing:.14em;text-transform:uppercase;
  color:var(--ink-3);margin:14px 0 6px;font-weight:400}
.body .m{font-size:13px;color:var(--ink-2);font-family:"JetBrains Mono",monospace;white-space:pre-wrap}
.body .t{font-size:14.5px;max-width:70ch;white-space:pre-wrap}
.empty{color:var(--ink-3);font-style:italic;padding:40px 0;text-align:center}
/* decisiones */
.dec{display:flex;gap:5px;flex-shrink:0}
.dbtn{font:inherit;font-size:11.5px;cursor:pointer;background:var(--paper);border:1px solid var(--rule);
  color:var(--ink-2);border-radius:2px;padding:4px 9px;transition:background .12s,border-color .12s}
.dbtn:hover{border-color:var(--ink-3)}
.dbtn[aria-pressed="true"]{font-weight:600}
.dbtn.keep[aria-pressed="true"]{background:color-mix(in srgb,var(--moss) 18%,var(--paper));border-color:var(--moss);color:var(--moss)}
.dbtn.ren[aria-pressed="true"]{background:color-mix(in srgb,var(--oxide) 18%,var(--paper));border-color:var(--oxide);color:var(--oxide)}
.row.decided{opacity:.62}
.bar{position:sticky;bottom:0;z-index:5;margin-top:18px;background:var(--paper-2);border:1px solid var(--rule);
  border-radius:3px;padding:11px 14px;display:flex;align-items:center;gap:14px;flex-wrap:wrap;box-shadow:var(--shadow)}
.bar .tally{font-family:"JetBrains Mono",monospace;font-size:12.5px;color:var(--ink-2);font-variant-numeric:tabular-nums}
.bar button{font:inherit;font-size:13px;cursor:pointer;border:1px solid var(--rule);background:var(--paper);
  color:var(--ink);border-radius:2px;padding:6px 13px}
.bar button.primary{background:var(--ink-blue);border-color:var(--ink-blue);color:var(--paper)}
:root[data-theme="dark"] .bar button.primary,:root:not([data-theme="light"]) .bar button.primary{color:#0f1318}
.bar .spacer{flex:1}
#out{width:100%;margin-top:10px;min-height:150px;font-family:"JetBrains Mono",monospace;font-size:12.5px;
  background:var(--paper);color:var(--ink);border:1px solid var(--rule);border-radius:3px;padding:10px;resize:vertical}
#out[hidden]{display:none}
footer{border-top:1px solid var(--rule);padding:18px 0 40px;color:var(--ink-3);font-size:13px}
@media (max-width:700px){.rhead{grid-template-columns:1fr;gap:4px}.arrow{display:none}.meta{margin-top:4px}}
</style>
<header class="top"><div class="wrap">
<div class="eyebrow">Compendio Harford · control de calidad</div>
<h1>Cotejo de Conjuros</h1>
<p class="sub">Los 384 conjuros del compendio, cotejados uno a uno contra los conjuros recuperados de los manuales. Sirve para localizar nombres mal traducidos y decidir cuáles corregir.</p>
<p class="filterlabel">Elige qué grupo revisar</p>
<div class="counts" id="counts"></div>
<div class="tools"><label class="search">
<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
<input id="q" type="search" placeholder="Buscar conjuro…" autocomplete="off" aria-label="Buscar conjuro"></label>
<div class="origin" id="origin" role="group" aria-label="Origen del conjuro">
<button class="obtn" data-o="all" aria-pressed="true">Todos</button>
<button class="obtn" data-o="wc" aria-pressed="false">★ Warcraft</button>
<button class="obtn" data-o="dnd" aria-pressed="false">D&amp;D</button></div></div>
</div></header>
<main class="wrap">
<p class="note"><b>Cómo usarlo.</b> «Nombre distinto» agrupa conjuros cuyo nivel y escuela coinciden con los del manual pero cuyo nombre no: ahí están los fallos de traducción reales, mezclados con parejas que solo comparten nivel y escuela y en realidad son conjuros diferentes. Los marcados con <b>★</b> son propios de Warcraft y solo se cotejan contra los libros de Warcraft; el resto, contra los manuales de D&amp;D. Abre la fila para leer el texto del manual y marca <b>Está bien</b> o <b>Renombrar</b> en cada una. Las decisiones se guardan solas; cuando termines, pulsa <b>Ver decisiones para copiar</b> abajo y pégame el resultado.</p>
<div class="showing"><h2 id="showTitle"></h2><span class="cnt" id="showCount"></span></div>
<div class="rows" id="rows"></div>
<p class="empty" id="empty" hidden>Ningún conjuro coincide con la búsqueda.</p>
<div class="bar">
<span class="tally" id="tally"></span><span class="spacer"></span>
<button id="reset">Borrar decisiones</button>
<button class="primary" id="export">Ver decisiones para copiar</button>
<textarea id="out" hidden readonly aria-label="Decisiones para copiar"></textarea>
</div>
</main>
<footer class="wrap">Fuentes: Manual del Jugador y Warcraft 5ª (Libros 1 y 2), texto recuperado de los PDF. El nombre del manual puede aparecer roto por el reconocimiento de texto.</footer>
<script id="data" type="application/json">__DATA__</script>
<script>
const D=JSON.parse(document.getElementById('data').textContent);
const KIND={exacto:['Ya resuelto','k-exacto'],ocr:['Pendiente de volcar','k-ocr'],traduccion:['Nombre distinto','k-traduccion'],
  dudoso:['Dudoso','k-dudoso'],sin:['Sin fuente','k-sin']};
const esc=s=>(s||'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const norm=s=>(s||'').normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase();
let filter='traduccion',query='',origin='all';
const KEY='harford-cotejo-conjuros';
let DEC={}; try{DEC=JSON.parse(localStorage.getItem(KEY)||'{}');}catch(e){DEC={};}
const rowsEl=document.getElementById('rows'),emptyEl=document.getElementById('empty');
document.getElementById('counts').innerHTML=Object.entries(KIND).map(([k,[lbl,cls]])=>
  `<button class="cbtn ${cls}" data-k="${k}" aria-pressed="${k===filter}"><span class="num">${D.filter(d=>d.k===k).length}</span><span class="lbl">${lbl}</span></button>`).join('');
const lvl=n=>n===0?'Truco':(n==null?'—':'Nv '+n);
function render(){
  const list=D.filter(d=>(d.k===filter)
    &&(origin==='all'||(origin==='wc')===!!d.w)
    &&(!query||norm(d.n+' '+d.b).includes(query)));
  const TITLES={exacto:'Ya tienen el texto del manual',ocr:'Coinciden pero sin volcar',
    traduccion:'Nombre distinto al del manual',dudoso:'Parecido sin confirmar',sin:'Sin equivalente en los manuales que tienes'};
  document.getElementById('showTitle').textContent=TITLES[filter];
  document.getElementById('showCount').textContent=list.length+(list.length===1?' conjuro':' conjuros');
  emptyEl.hidden=list.length>0;
  rowsEl.innerHTML=list.map((d,i)=>{
    const [lbl,cls]=KIND[d.k];
    const right=d.b?`<span class="nm book">${esc(d.b)}</span>`:'<span class="nm book" style="opacity:.5">— sin equivalente —</span>';
    const dv=DEC[d.n]||'';
    const dec=d.b?`<span class="dec">
      <button class="dbtn keep" data-dec="ok" data-n="${esc(d.n)}" aria-pressed="${dv==='ok'}" title="El nombre del addon es correcto">Está bien</button>
      <button class="dbtn ren" data-dec="ren" data-n="${esc(d.n)}" aria-pressed="${dv==='ren'}" title="Renombrar al nombre del manual">Renombrar</button>
    </span>`:'';
    return `<div class="row${dv?' decided':''}" data-i="${i}"><button class="rhead" aria-expanded="false">
      <span class="nm">${d.w?'<span class="star" title="Conjuro propio de Warcraft">★</span>':''}${esc(d.n)}</span><span class="arrow">→</span>${right}
      <span class="meta"><span class="lvl">${lvl(d.l)} · ${esc(d.s||'')}</span><span class="chip ${cls}">${lbl}</span>${dec}</span>
    </button><div class="body">
      ${d.m?`<h4>Ficha en el manual</h4><div class="m">${esc(d.m)}</div>`:''}
      ${d.t?`<h4>Texto del manual${d.f?' · '+esc(d.f):''}</h4><div class="t">${esc(d.t)}</div>`:'<h4>Sin texto recuperado</h4>'}
    </div></div>`;}).join('');
  rowsEl.querySelectorAll('.rhead').forEach(b=>b.onclick=()=>{
    const r=b.closest('.row'),on=r.classList.toggle('open');b.setAttribute('aria-expanded',on);});
  rowsEl.querySelectorAll('.dbtn').forEach(b=>b.onclick=ev=>{
    ev.stopPropagation();                       // no desplegar la fila al decidir
    const n=b.dataset.n,v=b.dataset.dec;
    if(DEC[n]===v) delete DEC[n]; else DEC[n]=v;  // volver a pulsar deshace
    localStorage.setItem(KEY,JSON.stringify(DEC));
    render();
  });
  tally();
}
function tally(){
  const ok=Object.values(DEC).filter(v=>v==='ok').length, rn=Object.values(DEC).filter(v=>v==='ren').length;
  const pend=D.filter(d=>d.b&&!DEC[d.n]).length;
  document.getElementById('tally').textContent=`${rn} para renombrar · ${ok} correctos · ${pend} sin decidir`;
}
document.getElementById('export').onclick=()=>{
  const out=document.getElementById('out');
  const ren=D.filter(d=>DEC[d.n]==='ren').map(d=>`${d.n} -> ${d.b}`);
  const ok=D.filter(d=>DEC[d.n]==='ok').map(d=>d.n);
  out.value=(ren.length?'RENOMBRAR:\\n'+ren.join('\\n'):'RENOMBRAR: (ninguno)')
    +'\\n\\n'+(ok.length?'CORRECTOS (dejar como estan):\\n'+ok.join('\\n'):'CORRECTOS: (ninguno)');
  out.hidden=false; out.focus(); out.select();
};
document.getElementById('reset').onclick=()=>{
  if(!confirm('¿Borrar todas las decisiones?'))return;
  DEC={};localStorage.removeItem(KEY);document.getElementById('out').hidden=true;render();
};
document.getElementById('counts').addEventListener('click',e=>{
  const b=e.target.closest('.cbtn');if(!b)return;filter=b.dataset.k;
  document.querySelectorAll('.cbtn').forEach(x=>x.setAttribute('aria-pressed',x===b));render();});
document.getElementById('q').addEventListener('input',e=>{query=norm(e.target.value.trim());render();});
document.getElementById('origin').addEventListener('click',e=>{
  const b=e.target.closest('.obtn');if(!b)return;origin=b.dataset.o;
  document.querySelectorAll('.obtn').forEach(x=>x.setAttribute('aria-pressed',x===b));render();});
render();
</script>"""

html = html.replace("__DATA__", data).replace("--amber:#d8b martin;", "--amber:#d8b45c;")
io.open(os.path.join(HERE, "cotejo_conjuros.html"), "w", encoding="utf-8").write(html)
print("escrito:", len(html) // 1024, "KB")
from collections import Counter
print(dict(Counter(r["kind"] for r in rows)))
