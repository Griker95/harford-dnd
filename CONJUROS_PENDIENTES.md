# Conjuros pendientes de comprobar en el compendio

Seguimiento de conjuros que el manual (`Rulebooks/Warcraft 5º Edición.txt`) cita
pero que no se encuentran en `HarfordCompendio.lua`.

**Los nombres del compendio son los canónicos.** El manual usa traducciones
distintas para el mismo conjuro, así que antes de dar uno por ausente hay que
buscar por NIVEL y EFECTO, no por nombre. Los ✦ del manual son conjuros nuevos
descritos en su capítulo 6 — y varios YA estaban en el compendio con el texto
idéntico bajo otro título (ver la tabla de resueltos).

**Cotejadas las 12 clases** (todas sus listas de conjuros de subclase, niveles de
clase 1-6). Guerrero, Monje y Cazador de Demonios no tienen listas propias.

## PETICIÓN A LA WEB — VACÍA (cerrada el 2026-08-29)

**Los 6 conjuros pendientes originales están todos resueltos**: cinco eran
equivalencias que ya existían en el compendio con otro título (tabla de abajo) y
el sexto (rayo del caos) lo incorporó la web tras la petición. Solo siguen vivas
las incoherencias de datos anotadas más abajo, que son de la web.

1. ~~Rayo del caos~~ — **RESUELTO (2026-08-29)**: la web lo incorporó (`rayo_del_caos`,
   nivel 1) y ya está en la lista ampliada de Brujo/Destrucción del addon.
2. ~~Conocer la Intención~~ — **RESUELTO (2026-08-29)**: es *True Strike* = `impacto_certero`,
   que ya estaba en el compendio. Añadido a la lista de trucos de Sutileza (10/10).

## Resueltos como equivalencia (2026-08-29)

Estaban en el compendio con otro título; todos concedidos ya en sus rasgos.

| Manual | Compendio | Comprobado por |
|---|---|---|
| ✦ penitencia | `arrepentimiento` | TEXTO IDÉNTICO del capítulo 6 (Encantamiento 1, reacción, salvación de Sabiduría que desvía el ataque); la lista de Paladín nivel 1 del cap. 6 trae `✦ Arrepentimiento` donde la tabla de clase decía `✦ penitencia`. Concedido en `pal_sag_conjuros_3`. |
| descarga mental | `aguijon_mental` | *Mind Spike* (Xanathar): 3d8 psíquico, salvación de Sabiduría, conoces la ubicación. Clases: Brujo y Sacerdote. Concedido en `sac_som_conjuros_3`. |
| castigo abrasador | `golpe_llameante` | *Searing smite* (Reglas básicas): acción adicional, +1d6 fuego y el objetivo arde con salvación de Constitución. En la lista de Paladín nivel 1 del cap. 6 junto a Golpe Trueno (*thunderous*) y Golpe Furioso (*wrathful*). Concedido en `pal_ret_conjuros_3` (antes lo suplantaba `golpe_furioso`, que es *wrathful*: otro conjuro). |
| ✦ castigo justo | `golpe_justo` ("Golpe de cruzado") | TEXTO IDÉNTICO del "Golpe Justiciero" del cap. 6 (listado como `✦ Golpe Justo` en nivel 2): Evocación 2, +2d6 radiante y ventaja al siguiente ataque. Concedido en `pal_ret_conjuros_5`. |
| ✦ estallido estelar | `oleada_estelar` ("Oleada de estrellas") | TEXTO IDÉNTICO de la "Oleada de Estrellas" del cap. 6 (*starsurge*): línea de 30 m, salvación de Destreza, 6d6 radiante, +2d6 bajo luna clara. Concedido en `dru_eq_conjuros_camino_5`. Ojo: el compendio lo declara nivel 2 y su propio texto dice "Evocación de nivel 3" (ver incoherencias). |

## Sin resolver con seguridad

*(vacío — el último, castigo deslumbrante, se resolvió el 2026-09-05, tabla de abajo)*

| Manual | Compendio | Comprobado por |
|---|---|---|
| castigo deslumbrante | `castigo_marcador` ("Castigo marcador", *Branding Smite*, nivel 2) | La fila 5º del Camino de la Protección es de ranura de NIVEL 2: su compañero ✦ `guardian_del_rey` es nivel 2 y toda la tabla es consistente por ranura (3º→1, 9º→3 —confirmado porque su ✦ Luz Cegadora se define "Evocación de nivel 3"—, 13º→4, 17º→5). El único castigo radiante de nivel 2 es *Branding Smite*, y su efecto ES la luz deslumbrante ("tu arma brilla con un resplandor astral… el objetivo emite luz… no puede volverse invisible"). `golpe_cegador` (*Blinding Smite*, "Castigo cegador") queda descartado: nivel 3, y el manual usa "cegador/a" para la ✦ Luz Cegadora del escalón 9º, distinguiéndolo de "deslumbrante". Cableado en `pal_pro_conjuros_5` (2026-09-05). |

## Limpieza addon-side (2026-09-05): claves `concentration` duplicadas

64 conjuros del compendio del addon tenían `concentration = false` seguido más abajo de
`concentration = true` — un parche por lotes añadió el `true` sin quitar el default. En Lua
gana la última clave (el juego siempre vio `true`, que era el valor correcto en los 64), pero
cualquier extractor que lea la PRIMERA aparición se llevaba `false`. **Aviso al chat del
códice**: si algún extractor de la web leyó ese campo, conviene re-comprobar el flag de
concentración de esos conjuros en la web. Candado en `tools/pruebas/compendio_ocr.lua`.

## Barrido OCR comparado (2026-09-05) — CERRADO

Auditoría completa del compendio del addon (384 conjuros) contra los 558 de la web,
por id, sobre descripción + mecánica + daño: **1 artefacto OCR** (`rociada_venenosa`
"(2dl 2)" → "(2d12)", corregido), **0 dados desviados** de la web, **0 cabeceras de
página**, **0 mojibake**, **0 conjuros con contenido de otro incrustado**. El candado
vive en `tools/pruebas/compendio_ocr.lua`.

Hallazgos de cobertura:

1. **`sp_resplandor_enfermizo`** (Sickening Radiance, Xanathar, nivel 4, Brujo): era el
   único conjuro de nivel 0–4 de la web que faltaba en el addon. **Alta hecha** con el id
   de la web (para que el cotejo por id siga casando), texto web (ya en métrico), icono
   reutilizado de `rayo_de_enfermedad` (137020). Sin condición automática: la recurrencia
   del área y el agotamiento son de mesa.
2. **AVISO A LA WEB — `sp_castigo_abrasador` es un DUPLICADO**: es el mismo *Searing
   Smite* que la web ya tiene como `golpe_llameante` (mismo nivel 1, Paladín, 1 acción
   adicional, V, concentración 1 minuto, +1d6 fuego y arde con salvación CON). El addon
   resolvió esa equivalencia en 2026-08-29 (`pal_ret_conjuros_3` concede
   `golpe_llameante`); NO se importa el duplicado. Decidir en el chat del códice cuál de
   las dos entradas se queda.
3. Los **otros 172 `sp_*` solo-web son de nivel 5–9** (57/49/23/22/21 por nivel): fuera
   del alcance actual (conjuros 0–4). Son el material ya preparado para cuando se amplíe.
4. **`Restablecimiento mayor` tampoco está en la web** (solo `restablecimiento_menor`):
   ya no es "alta pendiente" del addon — es nivel 5 (fuera de alcance) y cuando la web lo
   incorpore entrará con la ampliación.

## Avisos a la web (no conjuros)

- **"Apresado" vs "Restringido"** (2026-08-29): la seccion Estados de la web llama
  "Apresado (Restrained)" al estado que el addon llama **"Restringido"** (mismo id
  `restrained`, misma mecanica). Conviene alinear una de las dos fuentes para que el
  jugador lea lo mismo en ambos sitios; los buscadores de texto del addon toleran
  variantes, asi que no rompe nada mientras tanto — es solo consistencia.
- Los 16 estados de esa seccion ya estan todos en el addon: "Inconsciente" y
  "Muriendo" se añadieron el 2026-08-29 (Muriendo se rastrea por el aura de muerte
  29266 que pone el sistema de Salv Muerte a 0 PG).

## Incoherencias del compendio detectadas

No las corrijo: `HarfordCompendio.lua` es compartido con otro chat y con Codex.

| Qué | Detalle |
|---|---|
| `oleada_estelar` | Declara `level = 2` pero su propio texto dice "Evocación de nivel 3" y escala "por cada nivel por encima del 3". El manual también lo da como nivel 3. Debería ser nivel 3. |
| `guardia_con_hoja` | El id sugiere *blade ward*, pero el conjuro se llama "Rompante de espadas" y su efecto es *sword burst*. El blade ward real está en `resguardo_de_hoja`. Emparejar por id cruzaría los dos. |
| Longstrider duplicado | `zancada_prodigiosa` (etiquetado Pícaro Sutileza) y `pies_ligeros` (Druida/Mago, con el componente de tierra) son el mismo conjuro: +3 m de velocidad y mejorable. El manual de Sutileza dice "Pies Ligeros"; el compendio le da "Zancada prodigiosa". |
| *Charm person* duplicado | `hechizar_persona` y `encantar_persona` son DOS entradas del mismo conjuro (ambas nivel 1, Encantamiento, `condition = charmed`); las dos declaran `classes = { "Sacerdote" }` cuando es conjuro de Brujo (el núcleo de Súcubo lo necesita); y `encantar_persona` lleva un `mechanics` de *conjurar seres del bosque* que no es suyo. |
| `bendicion` | `damage = "1d4 y"` es un fragmento truncado del texto del buff ("puede tirar 1d4 y añadir el resultado"): Bendición no hace daño y ese campo debería ir vacío. Inofensivo en el addon (no parsea a componente de daño), pero un extractor que lea `damage` se lleva basura. (2026-09-05: el addon le añadió `condition = { id = "blessed" }`, adaptación mecánica propia — conservarla al regenerar.) |

## Fuera del alcance actual (nivel 5)

El proyecto llega a conjuros de nivel 4, y un brujo de nivel 6 solo alcanza
nivel 3 de conjuro (con pacto Y con maná). No bloquean nada; se listan por si
el alcance sube.

| Conjuro | Lo pide |
|---|---|
| nube aniquiladora | Brujo / Aflicción |
| contagio | Brujo / Aflicción |
| llamada infernal | Brujo / Demonología |
| atadura planar | Brujo / Demonología |
| onda destructiva | Brujo / Destrucción |
| golpe de llama | Brujo / Destrucción |

## Equivalencias ya resueltas

Mismo conjuro con otro nombre. Útil como referencia: el manual y el compendio
divergen a menudo.

| Manual | Compendio | Comprobado por |
|---|---|---|
| producir llama | Crear llama | nivel 0, clases incluyen Brujo |
| susurros disonantes | Susurros discordantes | nombre |
| guardianes espirituales | Espíritus guardianes | nombre |
| esfera de fuego | Esfera de llamas | nombre |
| tierra eruptiva | Tierra en erupción | nombre |
| mandato | Orden imperiosa | "orden de una palabra" |
| romper | Hacer añicos | "súbito y fuerte tañido" |
| maldición elemental | Perdición elemental | nivel 4, elige tipo de daño |
| Protección con Cuchilla | Resguardo contra las hojas | *blade ward*, nivel 0 |
| Amigos | Amistad | id `amigos`, nivel 0 |
| Mano Mágica | Mano de mago | nivel 0 |
| Explosión de Espadas | Rompante de espadas | *sword burst*: círculo de espadas espectrales |
| Maldición | Maleficio | id `maldicion`, nivel 1 |
| Orden | Orden imperiosa | nivel 1 |
| Nube de Niebla | Nube de oscurecimiento | nivel 1 |
| Pies Ligeros | Zancada prodigiosa | ver duplicado mas arriba |
| hervir sangre | Hervor de sangre | CdM, nivel 2 |
| toque gélido | Toque helado | CdM, *chill touch* |
| rayo de debilitamiento | Rayo debilitador | CdM, nivel 2 |
| escudo de la fe | Escudo de fe | Paladín, nivel 1 |
| duelo forzado | Duelo obligado | Paladín, nivel 1 |
| castigo deslumbrante | Castigo cegador | Paladín, *blinding smite* 3d8 radiante |
| bendecir | Bendición | Sacerdote, *bless* nivel 1 |
| fuerza brillante | Fuerza radiante | Sacerdote, nivel 2 |
| faro de esperanza | Señal de esperanza | Sacerdote, *beacon of hope* nivel 3 |
| miedo | Terror | Sacerdote, *fear* nivel 3 |

## Nucleos Demoniacos del Brujo (Apendice C)

Cotejados los 15 conjuros de los cinco nucleos contra el compendio.

**Resueltos con OTRO nombre** (el compendio manda; ya corregidos en `Classes/Brujo.lua`):

| Manual | Compendio |
|---|---|
| contraconjuro | **Contrahechizo** (`contrahechizo`) |
| mofa vil | **Burla danina** (`burla_danina`, truco) |
| sugerencia | **Sugestion** |

**Faltan en el compendio** (todos de nivel 9 del brujo o de nivel de conjuro > 4, fuera del alcance actual 0-4):

- `furia de sangre y heroismo` (marcado con el simbolo de contenido propio de Warcraft)
- `lluvia de fuego` (idem)
- `dominar persona` (nivel 5 de conjuro)
- `desgaste` (XGE; nivel 5 de conjuro)

**Fallo de datos del compendio, sin tocar** (`HarfordCompendio.lua` es co-propiedad de otro chat):

- `hechizar_persona` y `encantar_persona` son DOS entradas del mismo conjuro (*charm person*): ambas nivel 1, Encantamiento, `condition = charmed`.
- Las dos declaran `classes = { "Sacerdote" }`. *Charm person* es conjuro de Brujo, y el nucleo de Sucubo lo necesita: hoy un brujo no puede acceder a el.
- `encantar_persona` lleva un `mechanics` que no es suyo: "Convocas espiritus feericos en forma de bestia con un valor de desafio total de 2 o menos" (es *conjurar seres del bosque*). El `roleNotes` de `hechizar_persona` tampoco corresponde.

## Conjuros de camino (repaso de clases)

Cotejadas las 111 promesas de conjuro del Libro (listas ampliadas, `grantedSpells`,
`spellGrants`, trucos) contra los 384 del compendio: **ninguna rota**.

**Hueco corregido**: el Druida solo concedia el par de nivel 3 de su camino; el
manual da conjuros en 3, 5, 7 y 9. Anadido el escalon de nivel 5 con rasgo propio
(patron `_3`/`_5` del Chaman). Equilibrio concede `luz_del_dia` + `oleada_estelar`
y Restauracion `palabra_de_curacion_en_masa` + `revivir` (divergencias de nombre:
*palabra curativa en masa* -> Palabra de curacion en masa; *revivificar* -> Revivir).

**Paladin**: los tres caminos conceden ya sus conjuros de nivel 3-5 salvo UNO:
`castigo deslumbrante` (Proteccion, nivel de clase 5), pendiente por el conflicto
de nivel descrito en "Sin resolver con seguridad".
