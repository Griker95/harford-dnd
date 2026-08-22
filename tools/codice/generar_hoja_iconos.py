# -*- coding: utf-8 -*-
"""Monta la pagina para elegir icono conjuro a conjuro, con los dibujos a la vista.

Lee `propuestas_iconos.json` y escribe un HTML autocontenido: los PNG van embebidos, asi
que la pagina funciona sola y se puede publicar. Al elegir, la eleccion se guarda en el
navegador y abajo aparece el texto listo para pegar en `elecciones_iconos.json`.

No decide nada: solo ensena lo que hay para que se elija con un clic.
"""
import base64
import io
import json
import os
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
DUMP = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
SALIDA = os.path.join(BASE, "hoja_iconos.html")
POR_CONJURO = 6


def png(nombre):
    ruta = os.path.join(DUMP, nombre + ".png")
    if not os.path.exists(ruta):
        return None
    return "data:image/png;base64," + base64.b64encode(io.open(ruta, "rb").read()).decode()


CABECERA = """<title>Elegir iconos</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bitter:wght@500;700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
 :root{--tinta:#16212e;--tinta-2:#3d4c5c;--tenue:#6d7a88;--papel:#f5f2ea;--papel-2:#eae5d8;
   --linea:#d5cdba;--oro:#a9752c;--azul:#2f5677;--verde:#3f6b4a;--caja:#fff}
 @media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
   --tinta:#e7e2d5;--tinta-2:#b9b3a4;--tenue:#8b8578;--papel:#161a1f;--papel-2:#1e242b;
   --linea:#333c46;--oro:#d6a44f;--azul:#7fb0d8;--verde:#7fbb8c;--caja:#1b2128}}
 :root[data-theme="dark"]{--tinta:#e7e2d5;--tinta-2:#b9b3a4;--tenue:#8b8578;--papel:#161a1f;
   --papel-2:#1e242b;--linea:#333c46;--oro:#d6a44f;--azul:#7fb0d8;--verde:#7fbb8c;--caja:#1b2128}
 *{box-sizing:border-box}
 body{margin:0;background:var(--papel);color:var(--tinta);
   font:400 16px/1.6 "IBM Plex Sans",system-ui,sans-serif;-webkit-font-smoothing:antialiased}
 .hoja{max-width:64rem;margin:0 auto;padding:2.5rem 1.2rem 8rem}
 header{border-bottom:3px solid var(--oro);padding-bottom:1.2rem;margin-bottom:1.6rem}
 .eyebrow{font:500 .72rem/1 "IBM Plex Mono",monospace;letter-spacing:.16em;
   text-transform:uppercase;color:var(--oro);margin:0 0 .7rem}
 h1{font:700 2.3rem/1.1 "Bitter",Georgia,serif;margin:0 0 .5rem;letter-spacing:-.01em}
 .sub{margin:0;color:var(--tinta-2);max-width:46rem}
 .fila{border:1px solid var(--linea);border-radius:4px;background:var(--caja);
   padding:.85rem 1rem;margin:.7rem 0}
 .fila.hecha{border-color:var(--verde);border-left:4px solid var(--verde)}
 .cab{display:flex;align-items:baseline;gap:.6rem;flex-wrap:wrap;margin-bottom:.6rem}
 .cab b{font:600 1.05rem/1.2 "IBM Plex Sans",sans-serif}
 .meta{font:400 .78rem/1 "IBM Plex Mono",monospace;color:var(--tenue)}
 .ops{display:flex;gap:.5rem;flex-wrap:wrap;align-items:flex-start}
 .op{border:2px solid transparent;border-radius:4px;background:var(--papel-2);padding:.4rem;
   cursor:pointer;width:5.6rem;text-align:center;font:inherit;color:inherit}
 .op:hover{border-color:var(--oro)}
 .op.sel{border-color:var(--verde);background:color-mix(in srgb,var(--verde) 16%,var(--caja))}
 .op img{width:42px;height:42px;display:block;margin:0 auto .3rem;border-radius:3px}
 .op small{display:block;font:400 .62rem/1.15 "IBM Plex Mono",monospace;color:var(--tinta-2);
   word-break:break-all}
 .op .por{display:block;font-size:.6rem;color:var(--tenue);margin-top:.2rem}
 .op.nada{width:auto;padding:.55rem .7rem;font-size:.78rem;color:var(--tinta-2)}
 .barra-sup{position:sticky;top:0;z-index:5;background:var(--papel);
   border-bottom:1px solid var(--linea);padding:.7rem 0;margin-bottom:1rem;
   display:flex;gap:1rem;align-items:center;flex-wrap:wrap}
 .prog{flex:1;min-width:12rem;height:8px;border-radius:4px;background:var(--papel-2);overflow:hidden}
 .prog i{display:block;height:100%;background:var(--verde);width:0}
 .cuenta{font:500 .85rem/1 "IBM Plex Mono",monospace;color:var(--tinta-2)}
 button.acc{font:500 .82rem/1 "IBM Plex Sans",sans-serif;padding:.5rem .8rem;cursor:pointer;
   border:1px solid var(--linea);border-radius:3px;background:var(--caja);color:var(--tinta)}
 button.acc:hover{border-color:var(--oro)}
 #salida{width:100%;min-height:11rem;margin-top:.7rem;font:400 .78rem/1.45 "IBM Plex Mono",monospace;
   background:var(--caja);color:var(--tinta);border:1px solid var(--linea);border-radius:3px;padding:.7rem}
 h2{font:700 1.3rem/1.25 "Bitter",Georgia,serif;margin:2.4rem 0 .3rem}
 p{max-width:46rem}
 .nota{border-left:3px solid var(--azul);background:var(--caja);padding:.85rem 1rem;
   margin:1.1rem 0;max-width:46rem;font-size:.94rem}
</style>
"""


def main():
    props = json.load(io.open(os.path.join(BASE, "propuestas_iconos.json"), encoding="utf-8"))
    partes = [CABECERA, '<div class="hoja"><header>',
              '<p class="eyebrow">Compendio Harford · elección de iconos</p>',
              "<h1>Elegir iconos</h1>",
              '<p class="sub">Un clic en el icono que mejor le pegue a cada conjuro. '
              "Ninguno se repite: los candidatos ya excluyen todo lo que está en uso. "
              "Lo que elijas se guarda en este navegador y sale abajo listo para pegar.</p>",
              "</header>",
              '<div class="barra-sup"><span class="cuenta" id="cuenta">0 de %d</span>'
              '<span class="prog"><i id="prog"></i></span>'
              '<button class="acc" id="ver">Ver el resultado</button>'
              '<button class="acc" id="limpiar">Empezar de cero</button></div>' % len(props)]

    orden = sorted(props.items(), key=lambda kv: (kv[1]["nivel"] or 0, kv[0]))
    faltan_png = 0
    for nombre, v in orden:
        partes.append('<div class="fila" data-c="%s">' % nombre.replace('"', "&quot;"))
        partes.append('<div class="cab"><b>%s</b><span class="meta">nivel %s · %s · busca «%s»</span></div>'
                      % (nombre, v["nivel"], v.get("escuela") or "—", v["ingles"]))
        partes.append('<div class="ops">')
        for c in v["candidatos"][:POR_CONJURO]:
            d = png(c["icono"])
            if not d:
                faltan_png += 1
                continue
            partes.append(
                '<button class="op" data-i="%s"><img src="%s" alt=""><small>%s</small>'
                '<span class="por">%s</span></button>'
                % (c["icono"], d, c["icono"], c["motivo"]))
        partes.append('<button class="op nada" data-i="">Ninguno me convence</button>')
        partes.append("</div></div>")

    partes.append("""
<h2>El resultado</h2>
<p>Cuando termines (o cuando quieras dejarlo a medias), copia esto y pásamelo.</p>
<textarea id="salida" readonly></textarea>
<div class="nota">Se guarda solo en tu navegador según vas eligiendo, así que puedes cerrar
y seguir después. «Ninguno me convence» deja el conjuro sin icono, que es mejor que ponerle
uno que no diga nada.</div>
</div>
<script>
(function(){
  var CLAVE='harford:iconos';
  var elegido=JSON.parse(localStorage.getItem(CLAVE)||'{}');
  var filas=[].slice.call(document.querySelectorAll('.fila'));
  function pinta(){
    var n=Object.keys(elegido).length, tot=filas.length;
    document.getElementById('cuenta').textContent=n+' de '+tot;
    document.getElementById('prog').style.width=(tot?100*n/tot:0)+'%';
    document.getElementById('salida').value=JSON.stringify(elegido,null,1);
  }
  filas.forEach(function(f){
    var nom=f.getAttribute('data-c');
    f.addEventListener('click',function(ev){
      var b=ev.target.closest('.op'); if(!b) return;
      f.querySelectorAll('.op').forEach(function(x){x.classList.remove('sel')});
      b.classList.add('sel'); f.classList.add('hecha');
      elegido[nom]=b.getAttribute('data-i');
      localStorage.setItem(CLAVE,JSON.stringify(elegido)); pinta();
    });
    if(elegido[nom]!==undefined){
      var sel=f.querySelector('.op[data-i="'+(elegido[nom]||'')+'"]');
      if(sel){sel.classList.add('sel'); f.classList.add('hecha');}
    }
  });
  document.getElementById('ver').addEventListener('click',function(){
    var s=document.getElementById('salida'); s.scrollIntoView({behavior:'smooth'}); s.select();
  });
  document.getElementById('limpiar').addEventListener('click',function(){
    if(!confirm('¿Borrar todas las elecciones?')) return;
    elegido={}; localStorage.removeItem(CLAVE);
    filas.forEach(function(f){f.classList.remove('hecha');
      f.querySelectorAll('.op').forEach(function(x){x.classList.remove('sel')})});
    pinta();
  });
  pinta();
})();
</script>""")

    io.open(SALIDA, "w", encoding="utf-8").write("\n".join(partes))
    tam = os.path.getsize(SALIDA) / 1e6
    print("hoja escrita: %s" % SALIDA)
    print("   conjuros: %d | iconos sin PNG omitidos: %d | tamano: %.1f MB"
          % (len(props), faltan_png, tam))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
