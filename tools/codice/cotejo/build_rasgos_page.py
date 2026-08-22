# -*- coding: utf-8 -*-
# Genera el informe navegable del cotejo de rasgos y dotes (mismo diseno que el de conjuros).
import io, os, json, sys
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
rows = json.load(io.open(os.path.join(HERE, "rasgos_audit.json"), encoding="utf-8"))
data = json.dumps(rows, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")

html = """<title>Cotejo de Rasgos y Dotes</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Zilla+Slab:wght@500;600;700&family=Source+Sans+3:wght@400;600&family=JetBrains+Mono:wght@400;500&display=swap">
<style>
:root{
  --paper:#f2efe8; --paper-2:#e9e5db; --ink:#1e2733; --ink-2:#4a5665; --ink-3:#7b8593;
  --rule:#d3cec2; --ink-blue:#2d4a6b; --oxide:#a4472f; --amber:#9a7215; --moss:#3f6b4a;
  --shadow:0 1px 2px rgba(30,39,51,.06),0 8px 24px rgba(30,39,51,.07);
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --paper:#161a20; --paper-2:#1e242c; --ink:#e6e3db; --ink-2:#a8b0ba; --ink-3:#79828d;
  --rule:#2c333c; --ink-blue:#7aa5cf; --oxide:#e08b6e; --amber:#d8b45c; --moss:#7bb98c;
  --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px rgba(0,0,0,.35);
}}
:root[data-theme="dark"]{
  --paper:#161a20; --paper-2:#1e242c; --ink:#e6e3db; --ink-2:#a8b0ba; --ink-3:#79828d;
  --rule:#2c333c; --ink-blue:#7aa5cf; --oxide:#e08b6e; --amber:#d8b45c; --moss:#7bb98c;
  --shadow:0 1px 2px rgba(0,0,0,.3),0 8px 24px rgba(0,0,0,.35);
}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font-family:"Source Sans 3",ui-sans-serif,system-ui,sans-serif;line-height:1.6;-webkit-font-smoothing:antialiased}
.wrap{width:min(1080px,calc(100% - 40px));margin-inline:auto}
header.top{padding:44px 0 26px;border-bottom:1px solid var(--rule)}
.eyebrow{font-family:"JetBrains Mono",monospace;font-size:11px;letter-spacing:.18em;text-transform:uppercase;color:var(--oxide)}
h1{font-family:"Zilla Slab",Georgia,serif;font-weight:700;font-size:clamp(30px,4.4vw,44px);line-height:1.1;margin:8px 0 10px;text-wrap:balance}
.sub{color:var(--ink-2);max-width:64ch;margin:0}
.tools{display:flex;gap:10px;align-items:center;margin:20px 0 0;flex-wrap:wrap}
.search{flex:1;min-width:220px;display:flex;align-items:center;gap:8px;background:var(--paper-2);border:1px solid var(--rule);border-radius:3px;padding:8px 12px}
.search input{flex:1;border:0;background:none;color:var(--ink);font:inherit;outline:none}
.kbtn{font:inherit;font-size:12px;cursor:pointer;background:var(--paper-2);border:1px solid var(--rule);color:var(--ink-2);border-radius:2px;padding:7px 11px}
.kbtn[aria-pressed="true"]{border-color:var(--ink-blue);color:var(--ink);background:color-mix(in srgb,var(--ink-blue) 14%,var(--paper-2))}
main{padding:22px 0 60px}
.note{background:var(--paper-2);border-left:3px solid var(--oxide);border-radius:0 3px 3px 0;padding:12px 16px;margin:0 0 22px;font-size:14.5px;color:var(--ink-2)}
.note b{color:var(--ink)}
.rows{display:flex;flex-direction:column;gap:6px}
.row{background:var(--paper-2);border:1px solid var(--rule);border-radius:3px;overflow:hidden}
.rhead{width:100%;text-align:left;font:inherit;color:inherit;background:none;border:0;cursor:pointer;
  display:grid;grid-template-columns:minmax(0,1fr) 18px minmax(0,1fr) auto;gap:12px;align-items:center;padding:11px 14px}
.rhead:hover{background:color-mix(in srgb,var(--ink) 4%,transparent)}
.rhead:focus-visible{outline:2px solid var(--ink-blue);outline-offset:-2px}
.nm{font-family:"JetBrains Mono",monospace;font-size:13px;font-weight:500;overflow-wrap:anywhere}
.nm small{display:block;font-size:10.5px;color:var(--ink-3);font-weight:400}
.nm.book{color:var(--ink-2)}
.arrow{color:var(--ink-3);text-align:center}
.meta{display:flex;align-items:center;gap:8px;flex-shrink:0}
.chip{font-family:"JetBrains Mono",monospace;font-size:10px;letter-spacing:.04em;text-transform:uppercase;
  border:1px solid var(--rule);color:var(--ink-3);border-radius:2px;padding:2px 7px;white-space:nowrap}
.chip.r{color:var(--amber);border-color:currentColor}
.body{display:none;padding:2px 14px 16px;border-top:1px solid var(--rule)}
.row.open .body{display:block}
.body h4{font-family:"JetBrains Mono",monospace;font-size:10.5px;letter-spacing:.14em;text-transform:uppercase;color:var(--ink-3);margin:14px 0 6px;font-weight:400}
.body .t{font-size:14.5px;max-width:70ch;white-space:pre-wrap}
.body .cur{color:var(--ink-2)}
.empty{color:var(--ink-3);font-style:italic;padding:40px 0;text-align:center}
.dec{display:flex;gap:5px;flex-shrink:0}
.dbtn{font:inherit;font-size:11.5px;cursor:pointer;background:var(--paper);border:1px solid var(--rule);color:var(--ink-2);border-radius:2px;padding:4px 9px}
.dbtn.keep[aria-pressed="true"]{background:color-mix(in srgb,var(--moss) 18%,var(--paper));border-color:var(--moss);color:var(--moss);font-weight:600}
.dbtn.ren[aria-pressed="true"]{background:color-mix(in srgb,var(--oxide) 18%,var(--paper));border-color:var(--oxide);color:var(--oxide);font-weight:600}
.row.decided{opacity:.62}
.bar{position:sticky;bottom:0;z-index:5;margin-top:18px;background:var(--paper-2);border:1px solid var(--rule);border-radius:3px;padding:11px 14px;display:flex;align-items:center;gap:14px;flex-wrap:wrap;box-shadow:var(--shadow)}
.bar .tally{font-family:"JetBrains Mono",monospace;font-size:12.5px;color:var(--ink-2);font-variant-numeric:tabular-nums}
.bar button{font:inherit;font-size:13px;cursor:pointer;border:1px solid var(--rule);background:var(--paper);color:var(--ink);border-radius:2px;padding:6px 13px}
.bar button.primary{background:var(--ink-blue);border-color:var(--ink-blue);color:var(--paper)}
.bar .spacer{flex:1}
#out{width:100%;margin-top:10px;min-height:150px;font-family:"JetBrains Mono",monospace;font-size:12.5px;background:var(--paper);color:var(--ink);border:1px solid var(--rule);border-radius:3px;padding:10px;resize:vertical}
#out[hidden]{display:none}
@media (max-width:700px){.rhead{grid-template-columns:1fr;gap:4px}.arrow{display:none}.meta{margin-top:4px}}
</style>
<header class="top"><div class="wrap">
<div class="eyebrow">Compendio Harford · control de calidad</div>
<h1>Cotejo de Rasgos y Dotes</h1>
<p class="sub">Rasgos de clase, raza, subraza y dotes del addon cuyo nombre no coincide exactamente con el de los manuales. Cada fila propone el título más parecido del libro: confirma si es el mismo rasgo o si el del addon ya está bien.</p>
<div class="tools"><label class="search">
<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>
<input id="q" type="search" placeholder="Buscar rasgo…" autocomplete="off" aria-label="Buscar"></label>
<span id="kinds"></span></div>
</div></header>
<main class="wrap">
<p class="note"><b>Cómo usarlo.</b> Abre cada fila para comparar el texto <b>actual del addon</b> con el <b>del manual</b>. Marca <b>Está bien</b> si el del addon es correcto tal cual, o <b>Usar el del libro</b> si es el mismo rasgo y quieres su texto completo. Las decisiones se guardan solas; al final pulsa <b>Ver decisiones para copiar</b> y pégame el resultado.</p>
<div class="rows" id="rows"></div>
<p class="empty" id="empty" hidden>Nada que coincida con la búsqueda.</p>
<div class="bar">
<span class="tally" id="tally"></span><span class="spacer"></span>
<button id="reset">Borrar decisiones</button>
<button class="primary" id="export">Ver decisiones para copiar</button>
<textarea id="out" hidden readonly aria-label="Decisiones para copiar"></textarea>
</div>
</main>
<script id="data" type="application/json">__DATA__</script>
<script>
const D=JSON.parse(document.getElementById('data').textContent);
const esc=s=>(s||'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const norm=s=>(s||'').normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase();
const KEY='harford-cotejo-rasgos';
let DEC={}; try{DEC=JSON.parse(localStorage.getItem(KEY)||'{}');}catch(e){DEC={};}
let query='', kind='Todos';
const kinds=['Todos',...new Set(D.map(d=>d.kind))];
document.getElementById('kinds').innerHTML=kinds.map(k=>`<button class="kbtn" data-k="${esc(k)}" aria-pressed="${k===kind}">${esc(k)}</button>`).join(' ');
const rowsEl=document.getElementById('rows'),emptyEl=document.getElementById('empty');
const idOf=d=>d.kind+'|'+d.owner+'|'+d.n;
function render(){
  const list=D.filter(d=>(kind==='Todos'||d.kind===kind)&&(!query||norm(d.n+' '+d.b+' '+d.owner).includes(query)));
  emptyEl.hidden=list.length>0;
  rowsEl.innerHTML=list.map(d=>{
    const dv=DEC[idOf(d)]||'';
    return `<div class="row${dv?' decided':''}"><button class="rhead" aria-expanded="false">
      <span class="nm">${esc(d.n)}<small>${esc(d.kind)} · ${esc(d.owner)}</small></span><span class="arrow">→</span>
      <span class="nm book">${esc(d.b)}<small>${esc(d.f)}</small></span>
      <span class="meta"><span class="chip r">${(d.r*100).toFixed(0)}%</span>
      <span class="dec">
        <button class="dbtn keep" data-id="${esc(idOf(d))}" data-dec="ok" aria-pressed="${dv==='ok'}">Está bien</button>
        <button class="dbtn ren" data-id="${esc(idOf(d))}" data-dec="ren" aria-pressed="${dv==='ren'}">Usar el del libro</button>
      </span></span>
    </button><div class="body">
      <h4>Texto actual del addon</h4><div class="t cur">${esc(d.cur)||'<i>(vacío)</i>'}</div>
      <h4>Texto del manual · ${esc(d.f)}</h4><div class="t">${esc(d.t)}</div>
    </div></div>`;}).join('');
  rowsEl.querySelectorAll('.rhead').forEach(b=>b.onclick=()=>{const r=b.closest('.row'),on=r.classList.toggle('open');b.setAttribute('aria-expanded',on);});
  rowsEl.querySelectorAll('.dbtn').forEach(b=>b.onclick=ev=>{
    ev.stopPropagation();
    const id=b.dataset.id,v=b.dataset.dec;
    if(DEC[id]===v) delete DEC[id]; else DEC[id]=v;
    localStorage.setItem(KEY,JSON.stringify(DEC)); render();
  });
  tally();
}
function tally(){
  const ok=Object.values(DEC).filter(v=>v==='ok').length, rn=Object.values(DEC).filter(v=>v==='ren').length;
  document.getElementById('tally').textContent=`${rn} usar libro · ${ok} correctos · ${D.length-ok-rn} sin decidir`;
}
document.getElementById('kinds').addEventListener('click',e=>{
  const b=e.target.closest('.kbtn'); if(!b)return; kind=b.dataset.k;
  document.querySelectorAll('.kbtn').forEach(x=>x.setAttribute('aria-pressed',x===b)); render();
});
document.getElementById('q').addEventListener('input',e=>{query=norm(e.target.value.trim());render();});
document.getElementById('export').onclick=()=>{
  const out=document.getElementById('out');
  const ren=D.filter(d=>DEC[idOf(d)]==='ren').map(d=>`${d.kind} | ${d.owner} | ${d.n} -> ${d.b}`);
  const ok=D.filter(d=>DEC[idOf(d)]==='ok').map(d=>`${d.kind} | ${d.owner} | ${d.n}`);
  out.value=(ren.length?'USAR EL DEL LIBRO:\\n'+ren.join('\\n'):'USAR EL DEL LIBRO: (ninguno)')
    +'\\n\\n'+(ok.length?'CORRECTOS:\\n'+ok.join('\\n'):'CORRECTOS: (ninguno)');
  out.hidden=false; out.focus(); out.select();
};
document.getElementById('reset').onclick=()=>{ if(!confirm('¿Borrar todas las decisiones?'))return;
  DEC={};localStorage.removeItem(KEY);document.getElementById('out').hidden=true;render(); };
render();
</script>"""
html = html.replace("__DATA__", data)
io.open(os.path.join(HERE, "cotejo_rasgos.html"), "w", encoding="utf-8").write(html)
print("escrito:", len(html)//1024, "KB |", len(rows), "filas")
