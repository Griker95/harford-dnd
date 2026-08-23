# -*- coding: utf-8 -*-
"""Hoja para elegir los iconos que faltan dentro del alcance acordado.

Dos bloques:
  - los rasgos de clase y subclase hasta nivel 6 que no tienen icono;
  - los conjuros hasta nivel 4 que comparten dibujo con otro, con los dos implicados a la
    vista para decidir cual se cambia.

Como `generar_hoja_iconos.py`: los PNG van embebidos, la eleccion se guarda en el
navegador y abajo sale el texto para pegar. No decide nada.
"""
import base64
import io
import json
import os
import re
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
DUMP = r"C:/Users/marco/Documents/New project/EpsilonIcons/png"
WEB = r"C:/Users/marco/Documents/harfordweb/js/compendium-data.js"
CAT = r"C:/Users/marco/Documents/New project/Harford/Compendium/HarfordIconCatalog.lua"
SALIDA = os.path.join(BASE, "hoja_pendientes.html")

# Alternativas curadas para cada rasgo: el icono real de WoW primero y dos que digan lo
# mismo por si el primero ya esta cogido o no convence.
RASGOS = {
    "restauracion_corteza_de_hierro": ["spell_druid_ironbark", "spell_nature_stoneclawtotem",
                                       "inv_misc_herb_felblossom", "spell_nature_natureguardian"],
    "bestias_vinculo_del_companero": ["ability_hunter_animalhandler", "ability_hunter_beastsoothe",
                                      "ability_hunter_pet_assist", "spell_nature_protectionformnature"],
    "cervecero_brebaje_fortificante": ["ability_monk_fortifyingale_new", "ability_monk_fortifyingale",
                                       "inv_misc_beer_06", "ability_monk_domeofmist"],
    "cervecero_brebaje_de_piel_de_hierro": ["ability_monk_ironskinbrew", "inv_misc_beer_08",
                                            "ability_monk_elusivebrawler", "inv_drink_05"],
    "cervecero_te_de_trueno": ["ability_monk_thunderfocustea", "ability_monk_forcesphere",
                               "inv_misc_beer_02", "spell_nature_lightning"],
    "afliccion_maldiciones": ["spell_shadow_curseofsargeras", "spell_shadow_antishadow",
                              "spell_shadow_curseofachimonde", "spell_shadow_blackplague"],
    "guerrero_maniobras_3": ["ability_warrior_weaponmastery", "ability_warrior_battleshout",
                             "ability_warrior_bladestorm", "inv_sword_48"],
    "guerrero_maniobras_6": ["ability_warrior_trauma", "ability_warrior_commandingshout",
                             "ability_warrior_decisivestrike", "ability_warrior_shieldmastery"],
}

# Nombre ingles de los conjuros que comparten dibujo, solo para buscarles alternativa.
INGLES_PAREJAS = {
    "Favor aterrador": "dreadfulfear", "Nova sagrada": "holynova",
    "Ira solar": "sunfire", "Resplandor enfermizo": "blight",
    "Llamada de relámpago": "calllightning", "Llamar al relámpago": "calllightning",
    "Vínculo de bestia": "beastbond", "Dominar bestia": "dominatebeast",
    "Amistad": "friends", "Amigos rápidos": "charmperson",
    "Toque helado": "chilltouch", "Explosión arcana": "arcaneblast",
    "Don de la alacridad": "haste", "Libertad de movimiento": "freedom",
    "Castigo marcador": "brandingsmite", "Castigo abrasador": "searingsmite",
}

CABECERA = """<title>Iconos pendientes</title>
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
 .hoja{max-width:62rem;margin:0 auto;padding:2.5rem 1.2rem 7rem}
 header{border-bottom:3px solid var(--oro);padding-bottom:1.1rem;margin-bottom:1.5rem}
 .eyebrow{font:500 .72rem/1 "IBM Plex Mono",monospace;letter-spacing:.16em;
   text-transform:uppercase;color:var(--oro);margin:0 0 .7rem}
 h1{font:700 2.2rem/1.1 "Bitter",Georgia,serif;margin:0 0 .5rem;letter-spacing:-.01em}
 h2{font:700 1.25rem/1.25 "Bitter",Georgia,serif;margin:2.2rem 0 .2rem}
 .sub{margin:0;color:var(--tinta-2);max-width:46rem}
 .fila{border:1px solid var(--linea);border-left:3px solid var(--azul);border-radius:4px;
   background:var(--caja);padding:.85rem 1rem;margin:.7rem 0}
 .fila.hecha{border-left-color:var(--verde)}
 .cab{display:flex;align-items:baseline;gap:.6rem;flex-wrap:wrap;margin-bottom:.55rem}
 .cab b{font:600 1.02rem/1.2 "IBM Plex Sans",sans-serif}
 .meta{font:400 .76rem/1 "IBM Plex Mono",monospace;color:var(--tenue)}
 .ahora{display:flex;align-items:center;gap:.5rem;font-size:.82rem;color:var(--tinta-2);
   margin:0 0 .55rem}
 .ahora img{width:26px;height:26px;border-radius:3px}
 .ops{display:flex;gap:.5rem;flex-wrap:wrap;align-items:flex-start}
 .op{border:2px solid transparent;border-radius:4px;background:var(--papel-2);padding:.4rem;
   cursor:pointer;width:6.2rem;text-align:center;font:inherit;color:inherit}
 .op:hover{border-color:var(--oro)}
 .op.sel{border-color:var(--verde);background:color-mix(in srgb,var(--verde) 16%,var(--caja))}
 .op img{width:42px;height:42px;display:block;margin:0 auto .3rem;border-radius:3px}
 .op small{display:block;font:400 .6rem/1.15 "IBM Plex Mono",monospace;color:var(--tinta-2);
   word-break:break-all}
 .op.nada{width:auto;padding:.55rem .7rem;font-size:.78rem;color:var(--tinta-2)}
 .barra{position:sticky;top:0;z-index:5;background:var(--papel);border-bottom:1px solid var(--linea);
   padding:.7rem 0;margin-bottom:1rem;display:flex;gap:1rem;align-items:center;flex-wrap:wrap}
 .cuenta{font:500 .85rem/1 "IBM Plex Mono",monospace;color:var(--tinta-2)}
 button.acc{font:500 .82rem/1 "IBM Plex Sans",sans-serif;padding:.5rem .8rem;cursor:pointer;
   border:1px solid var(--linea);border-radius:3px;background:var(--caja);color:var(--tinta)}
 button.acc:hover{border-color:var(--oro)}
 #salida{width:100%;min-height:10rem;margin-top:.7rem;font:400 .78rem/1.45 "IBM Plex Mono",monospace;
   background:var(--caja);color:var(--tinta);border:1px solid var(--linea);border-radius:3px;padding:.7rem}
 .nota{border-left:3px solid var(--azul);background:var(--caja);padding:.8rem 1rem;
   margin:1rem 0;max-width:46rem;font-size:.92rem}
 p{max-width:46rem}
</style>
"""


def png(nombre):
    ruta = os.path.join(DUMP, nombre + ".png")
    if not os.path.exists(ruta):
        for f in os.listdir(DUMP):
            if f[:-4].lower() == nombre.lower():
                ruta = os.path.join(DUMP, f)
                break
        else:
            return None
    return "data:image/png;base64," + base64.b64encode(io.open(ruta, "rb").read()).decode()


# Cuatro se resisten al buscador: su concepto no aparece en ningun nombre de icono libre.
# Se les da la lista a mano, igual que a los rasgos.
A_MANO = {
    "Vínculo de bestia": ["ability_hunter_beasttaming", "ability_hunter_pet_assist",
                          "spell_nature_protectionformnature", "ability_hunter_animalhandler"],
    "Amistad": ["eps_wc3h_nightelfcharm", "eps_bg3_countercharm",
                "spell_holy_prayerofspirit", "spell_shadow_sacrificialshield"],
    "Libertad de movimiento": ["spell_holy_blessingofagility", "spell_magic_lesserinvisibilty",
                               "ability_rogue_sprint", "spell_nature_earthbind"],
    "Castigo marcador": ["ability_paladin_empoweredseals", "ability_demonhunter_fierybrand",
                         "spell_holy_sealofwrath", "spell_holy_righteousfury"],
}


def alternativas_conjuro(spell, usados, _cache={}):
    """Iconos libres que digan algo del conjuro.

    Se apoya en `buscar_iconos`, que ya tiene el glosario ingles, los sinonimos y el
    reparto por familias. Una busqueda por palabras del nombre en espanol dejaba sin
    candidatos a la mitad: "Ira solar" o "Amigos rapidos" no casan con nada en ingles.
    """
    if not _cache:
        import buscar_iconos as B
        _cache["B"] = B
        _cache["iconos"] = B.cargar_iconos()
        _cache["sin"] = json.load(io.open(os.path.join(BASE, "sinonimos_iconos.json"), encoding="utf-8"))
        _cache["glo"] = {k: v for k, v in json.load(
            io.open(os.path.join(BASE, "glosario_ingles.json"), encoding="utf-8")).items()
            if not k.startswith("_")}
    B = _cache["B"]
    # el glosario solo cubre los conjuros que NO tenian eleccion; estos si la tienen, asi
    # que su nombre ingles hay que darlo aqui o el buscador se queda sin nada por donde tirar
    ingles = INGLES_PAREJAS.get(spell["name"]) or _cache["glo"].get(spell["name"], "")
    if spell["name"] in A_MANO:
        return A_MANO[spell["name"]]
    cands = B.candidatos(spell, ingles, _cache["iconos"], _cache["sin"], usados)
    return [ic for ic, _ in cands[:5]]


def bloque(id_, titulo, meta, actual, candidatos):
    p = ['<div class="fila" data-k="%s">' % id_,
         '<div class="cab"><b>%s</b><span class="meta">%s</span></div>' % (titulo, meta)]
    if actual:
        d = png(actual)
        p.append('<p class="ahora">%sahora: <code>%s</code></p>'
                 % ('<img src="%s" alt="">' % d if d else "", actual))
    p.append('<div class="ops">')
    for c in candidatos:
        d = png(c)
        if not d:
            continue
        p.append('<button class="op" data-i="%s"><img src="%s" alt=""><small>%s</small></button>'
                 % (c, d, c))
    p.append('<button class="op nada" data-i="">Dejarlo como está</button>')
    p.append("</div></div>")
    return "".join(p)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    d = json.loads(re.search(r"=\s*(\{[\s\S]*\})",
                             io.open(WEB, encoding="utf-8").read()).group(1))
    usados = {x.lower() for x in re.findall(r'"([a-z0-9_]+)"',
                                            io.open(CAT, encoding="utf-8").read())}

    partes = [CABECERA, '<div class="hoja"><header>',
              '<p class="eyebrow">Compendio Harford · lo que falta</p>',
              "<h1>Iconos pendientes</h1>",
              '<p class="sub">Los rasgos hasta nivel 6 sin dibujo y los conjuros hasta nivel 4 '
              "que comparten uno. Un clic por fila; se guarda en este navegador y sale abajo "
              "listo para pasármelo.</p></header>",
              '<div class="barra"><span class="cuenta" id="cuenta">0</span>'
              '<button class="acc" id="ver">Ver el resultado</button>'
              '<button class="acc" id="limpiar">Empezar de cero</button></div>']

    # --- rasgos ---
    sin = []
    for c in d["classes"]:
        for f in c.get("features") or []:
            if (f.get("level") or 0) <= 6 and not f.get("icon") and f["id"] in RASGOS:
                sin.append((c["name"], f, RASGOS[f["id"]]))
        for s in c.get("subclasses") or []:
            for f in s.get("features") or []:
                if (f.get("level") or 0) <= 6 and not f.get("icon") and f["id"] in RASGOS:
                    sin.append(c["name"] + " / " + s["name"], )
                    sin[-1] = (c["name"] + " / " + s["name"], f, RASGOS[f["id"]])
    partes.append("<h2>Rasgos sin icono</h2>")
    for donde, f, cands in sin:
        partes.append(bloque(f["id"], f["name"],
                             "%s · nivel %s · %s" % (donde, f.get("level"), f["id"]),
                             None, cands))

    # --- conjuros que comparten dibujo ---
    conj = [s for s in d["spells"] if (s.get("level") or 0) <= 4]
    porico = {}
    for s in conj:
        porico.setdefault((s.get("icon") or "").lower(), []).append(s)
    partes.append("<h2>Conjuros que comparten dibujo</h2>")
    partes.append('<div class="nota">Cada pareja lleva el mismo icono. Elige uno nuevo para el '
                  "que prefieras cambiar; el otro se queda con el que ya tiene.</div>")
    n_conj = 0
    for ico, lista in sorted(porico.items()):
        if not ico or len(lista) < 2:
            continue
        for s in lista:
            n_conj += 1
            otros = ", ".join(x["name"] for x in lista if x is not s)
            partes.append(bloque("conjuro:" + s["id"], s["name"],
                                 "nivel %s · comparte con %s · %s" % (s.get("level"), otros, s["id"]),
                                 s.get("icon"), alternativas_conjuro(s, usados)))

    partes.append("<h2>El resultado</h2><p>Copia esto y pásamelo.</p>"
                  '<textarea id="salida" readonly></textarea></div>')
    partes.append("""
<script>
(function(){
  var CLAVE='harford:pendientes';
  var elegido=JSON.parse(localStorage.getItem(CLAVE)||'{}');
  var filas=[].slice.call(document.querySelectorAll('.fila'));
  function pinta(){
    document.getElementById('cuenta').textContent=Object.keys(elegido).length+' de '+filas.length;
    document.getElementById('salida').value=JSON.stringify(elegido,null,1);
  }
  filas.forEach(function(f){
    var k=f.getAttribute('data-k');
    f.addEventListener('click',function(ev){
      var b=ev.target.closest('.op'); if(!b) return;
      f.querySelectorAll('.op').forEach(function(x){x.classList.remove('sel')});
      b.classList.add('sel'); f.classList.add('hecha');
      elegido[k]=b.getAttribute('data-i');
      localStorage.setItem(CLAVE,JSON.stringify(elegido)); pinta();
    });
    if(elegido[k]!==undefined){
      var sel=f.querySelector('.op[data-i="'+(elegido[k]||'')+'"]');
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
    print("hoja escrita: %s" % SALIDA)
    print("   rasgos: %d | conjuros que comparten: %d | tamano: %.1f MB"
          % (len(sin), n_conj, os.path.getsize(SALIDA) / 1e6))


if __name__ == "__main__":
    main()
