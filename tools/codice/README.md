# tools/codice — pipeline y cotejo del Compendio

La web publica (`harfordweb`) es la fuente canonica de contenido curado para clases,
subclases, razas, trasfondos y conjuros. `Rulebooks/` es la fuente de validacion de reglas,
traducciones y texto antes de incorporar esos datos al addon. El alcance vigente es nivel de
personaje 1-6 y conjuros 0-4; la creacion automatica que los consume sigue **en curso**.

Los scripts documentados abajo describen el flujo historico addon -> web. No ejecutarlos para
sobrescribir la web ni editar `js/compendium-*.js` desde este repositorio sin coordinacion. La
importacion web -> addon debe ser revisable, cotejada y validada en Epsilon antes de considerarse
parte del creador de fichas.

## Flujo historico de publicacion (no ejecutar por defecto)

```
python extract_kb.py            # addon Lua -> kb.json
python add_icons_kb.py          # resuelve iconos -> kb_icons.json
python add_full_desc.py         # textos de manuales/Discord SOBRE kb_icons.json (in place;
                                #   sus contadores son solo lo mejorado en esa pasada)
python deploy_compendium.py     # kb_icons.json -> web js/compendium-data.js + copia iconos
python extract_dotes.py         # HarfordDnDFeats -> js/compendium-dotes.js
python extract_equipment.py     # HarfordDnDWeapons/Items -> js/compendium-equipment.js
python extract_professions.py   # HarfordProfessionsData/Items -> js/compendium-professions.js
python stamp_versions.py        # sella ?v=<commit> en los <script> (cache-busting)
```

Después: `git add/commit/push` en el repo de la web. `build_codice.py` encadena los tres
primeros pasos (era del Códice HTML retirado).

## Fuentes canónicas de terminología (decisiones del usuario)

- `prof_terminologia.json` — herramientas ("Útiles de ..." para todo), juegos, instrumentos
  y vehículos DIFERENCIADOS, iconos por variante. El addon aún usa los nombres antiguos:
  migrarlo requiere tabla vieja→nueva y compatibilidad con competencias guardadas.
- `idiomas_terminologia.json` — idiomas estándar y exóticos (publicados en reglas.html §12).
- `bgs_source.json` — extracción de Discord de trasfondos (FUENTE, no regenerable).

## Cotejo y aplicación de decisiones (`cotejo/`)

- `cotejo2.py` → `cotejo2.json`: cruza el compendio del addon con `RuleSource/Export/conjuros_*.json`.
- `adapt_cotejo.py` → `spell_audit_final.json`; `build_audit_page.py` → página de decisión de conjuros.
- `cotejo_rasgos.py` + `build_rasgos_page.py` → página de decisión de rasgos/dotes.
- `apply_renames.py` / `apply_descriptions.py` (en la raíz): aplican al addon los renombres y
  volcados una vez decididos (comprueban colisiones de nombre; UTF-8 sin BOM, CRLF, `luac -p`).

Dependencias en disco (fuera de git): `EpsilonIcons/png` (dump de iconos) y `RuleSource/`
(manuales extraídos por columnas + OCR). La conversión métrica vive en `RuleSource/metrico.py`
(equivalencia real, 1 decimal).

## Orden de la cadena (importante)

`add_full_desc.py` **lee y escribe el mismo `kb_icons.json`**, asi que no es idempotente:
ejecutarlo dos veces seguidas deja los recuadros del libro ya anexados y el contador cae
de 26 a 1. Siempre se regenera desde el principio:

    extract_kb.py -> add_icons_kb.py -> add_full_desc.py
                  -> extract_dotes.py / extract_equipment.py / extract_professions.py
                  -> deploy_compendium.py -> stamp_versions.py

## Nombres: el addon empareja, la web presenta

El addon guarda nombres y campos cortos SIN tilde porque los compara como cadena (listas
de conjuros por clase, `attack`/`savingThrow` que lee `ResolveCast`, materiales que la
ventana de crafteo cruza con el inventario). Acentuarlos en el Lua no es corregir una
errata: es cambiar una clave. Ya se probo una vez y hubo que deshacerlo en 85 sitios.

Por eso el acentuado de NOMBRES vive solo en la publicacion (`nombres_display.py`, que
usa el mismo `tildes.json` que la prosa) y se aplica **a los dos lados de cada
emparejado a la vez**: el `name` de la clase y su `spellClasses`, y el `classes` de cada
conjuro. Si se acentua uno solo, la ficha de clase se queda sin sus conjuros.

La PROSA es otra cosa: ahi la tilde si es una errata y se corrige en el origen
(`arreglar_tildes.py --apply` sobre el Lua, y `limpieza.py` para lo que viene del
markdown de los manuales, que arrastra su propio OCR).

## Comprobaciones

    auditar_textos.py auditar_tipografia.py auditar_erratas.py auditar_web.py
    auditar_nombres.py auditar_tildes_web.py palabras_partidas.py cotejar_fuentes.py
    cotejar_numeros.py auditar_partidas_clave.py   (este ultimo desde la raiz)

`revisar_render.js` NO se ejecuta con node: es para la consola del navegador, porque
comprueba la pagina ya renderizada (fue el unico que caza fallos como el marco de las
citas). Conviene lanzarlo por tramos: con el panel oculto el navegador estrangula los
temporizadores y una pasada entera no cabe en una sola llamada.

## Recetas de profesion (Wowhead)

Las recetas del addon salen de Wowhead Classic, que es la version con el arbol completo de
estas nueve profesiones, pero los NOMBRES se toman del WoW actual, que es el que usa el
servidor: Classic dice "Vara de cobre con runas", "Orbe de rectitud" o "Vial vacio" donde
el juego de hoy dice "Vara runica de cobre", "Orbe recto" y "Vial de cristal".

    wowhead_profesiones.py     baja lista + tooltip de cada receta + nombre moderno de cada
                               objeto; todo cacheado en cotejo/wowhead_cache
    iconos_wowhead.py --apply  baja de Wowhead los iconos que EpsilonIcons no tiene
    importar_profesiones.py --apply   reescribe las recetas y da de alta lo que falte en
                               HarfordProfessionsItems

Dos criterios que Wowhead no da y decide el importador:

  - la **CD** sale del COLOR que la receta tiene para tu habilidad, que es su dificultad real
    en el juego: rojo 20, naranja 16, amarillo 12, verde 10 y gris 8, mas la calidad de lo que
    fabricas (gris -1, blanco 0, verde +1, azul +3, morado +5, legendario +7).
  - un **encantamiento no produce objeto** en WoW: se aplica sobre una pieza. El proyecto ya
    resolvia eso entregando un pergamino y se mantiene ese criterio, porque el motor de
    crafteo desreferencia `r.output.key` sin comprobarlo.

Las recetas de RECOLECCION del proyecto ("Extraer cobre", "Desollar") tampoco se conservan:
la tabla es lo extraido de Wowhead y nada mas, asi que Herboristeria, Pesca, Desollar y
Fabricar venenos se quedan sin recetas mientras no haya datos suyos.


Al importar tambien se PODA: se retira toda receta escrita a mano y todo objeto que ya no use
ninguna, salvo las entradas que ya tengan su itemId real de Epsilon puestas a mano, que no se
puede volver a deducir. El emparejado con el registro se hace por `wow = <itemId>`, nunca por
nombre: renombrar por nombre creaba una clave nueva y dejaba huerfana la vieja, que es justo
la que lleva ese itemId.

    wowhead_objetos.py --apply   ficha completa de cada objeto (nivel, ranura, armadura o
                                 dano, caracteristicas, efectos, precio); estadisticas de la
                                 version del arbol, nombre del WoW actual
    wowhead_fuentes.py --apply   de donde se aprende cada receta. PENDIENTE: la ficha completa
                                 de Wowhead da 403 y bloquea la IP a las ~90 peticiones

La terminologia de la casa vive en `nombres_display.casa` y se aplica a los dos lados —el
registro del addon y la ficha del compendio— para que un material no se llame de dos maneras
segun donde se mire.
