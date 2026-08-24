# Conjuros pendientes de comprobar en el compendio

Seguimiento de conjuros que el manual (`Rulebooks/Warcraft 5º Edición.txt`) cita
pero que no se encuentran en `Harford/Compendium/HarfordCompendioData.lua`.

**Los nombres del compendio son los canónicos.** El manual usa traducciones
distintas para el mismo conjuro, así que antes de dar uno por ausente hay que
buscar por NIVEL y EFECTO, no por nombre.

**Cotejadas las 12 clases** (todas sus listas de conjuros de subclase, niveles de
clase 1-6). Guerrero, Monje y Cazador de Demonios no tienen listas propias.

## Faltan de verdad (dentro del alcance 0-4)

Verificados por mecánica, no solo por nombre.

| Conjuro (manual) | Nivel | Lo pide | Por qué no vale ningún candidato |
|---|---|---|---|
| rayo del caos | 1 | Brujo / Destrucción | Daño de tipo ALEATORIO que salta a otra criatura. `Rayo de hechicería` es *witch bolt* (1d12 relámpago, arco continuo). `Orbe cromático` deja ELEGIR el tipo. Búsqueda por mecánica de nivel 1 con daño aleatorio: sin resultados. |
| descarga mental | 2 | Brujo / Aflicción **y** Sacerdote / Sombra | 3d8 psíquico, salvación de Sabiduría, sigues conociendo su posición. `Tortura mental` es 2d6 y de Sacerdote. `Látigo mental de Tasha` usa salvación de Inteligencia y otro efecto. |
| castigo abrasador | 1 | Paladín / Retribución | *searing smite* estándar. El compendio solo tiene tres castigos: `Castigo furioso` (wrathful, 1d6 psíquico), `Castigo marcador` (branding, 2d6) y `Castigo cegador` (blinding, 3d8 radiante). Ninguno es el de fuego. |
| ✦ castigo justo | 3 | Paladín / Retribución | Marcado como conjuro NUEVO en el manual (capítulo 6). Sin candidato: el único castigo de nivel 3 es `Castigo cegador`, ya asignado a *castigo deslumbrante*. |
| ✦ penitencia | 1 | Paladín / Sagrado | Marcado como NUEVO. No confundir con la Absolución: Penitencia del Sacerdote, que es una habilidad, no un conjuro. |
| Conocer la Intención | 0 | Pícaro / Sutileza | El manual solo lo LISTA, sin descripción. No hay ningún truco con "intención" en el compendio. Sutileza queda con 9 de 10 trucos. |

## Incoherencias del compendio detectadas

No las corrijo: `HarfordCompendioData.lua` es compartido con otro chat y con Codex.

| Qué | Detalle |
|---|---|
| `guardia_con_hoja` | El id sugiere *blade ward*, pero el conjuro se llama "Rompante de espadas" y su efecto es *sword burst*. El blade ward real está en `resguardo_de_hoja`. Emparejar por id cruzaría los dos. |
| Longstrider duplicado | `zancada_prodigiosa` (etiquetado Pícaro Sutileza) y `pies_ligeros` (Druida/Mago, con el componente de tierra) son el mismo conjuro: +3 m de velocidad y mejorable. El manual de Sutileza dice "Pies Ligeros"; el compendio le da "Zancada prodigiosa". |

| estallido estelar | 3 | Druida / Equilibrio | Marcado con ✦ en el manual: conjuro nuevo del capítulo 6. Buscado por nivel 3 y por efecto (estrellas/luz): `Estrella divina`, `Explosión lunar` y `Faro de luz` no encajan lo bastante como para darlo por bueno. |

| penitencia | 1 | Paladín / Sagrado | Marcado con ✦: conjuro nuevo del capítulo 6. Sin candidatos en el compendio. |
| castigo deslumbrante | 2 | Paladín / Protección | La familia "Castigo" del compendio tiene `Castigo furioso` (nivel 1, *searing smite*), `Castigo marcador` (nivel 2, *branding smite*) y `Castigo cegador` (nivel 3). Ninguno encaja con seguridad en una ranura de 2.º nivel. |
| castigo justo | 2 | Paladín / Retribución | Mismo problema: no se distingue de `Castigo marcador` sin más datos. |

| protección con cuchilla | 0 | Pícaro / Sutileza | *Blade ward*. No está por nombre. Ojo: el id `guardia_con_hoja` (que traduce blade ward) lo lleva **Rompante de espadas** (*sword burst*), así que puede haberse reutilizado la entrada. |
| amigos | 0 | Pícaro / Sutileza | *Friends*. Sin candidatos en el compendio. |
| conocer la intención | 0 | Pícaro / Sutileza | Sin candidatos. `Codificar pensamientos` es otro conjuro. |

| miedo | 3 | Sacerdote / Sombra | *Fear*, nivel 3. `Causar miedo` del compendio es **nivel 1** (*cause fear*), otro conjuro. |

## Fuera del alcance actual (nivel 5)

El proyecto llega a conjuros de nivel 4, y un brujo de nivel 6 solo tiene
ranuras de 3.º. No bloquean nada; se listan por si el alcance sube.

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

**Fallo de datos del compendio, sin tocar** (`HarfordCompendioData.lua` es co-propiedad de otro chat):

- `hechizar_persona` y `encantar_persona` son DOS entradas del mismo conjuro (*charm person*): ambas nivel 1, Encantamiento, `condition = charmed`.
- Las dos declaran `classes = { "Sacerdote" }`. *Charm person* es conjuro de Brujo, y el nucleo de Sucubo lo necesita: hoy un brujo no puede acceder a el.
- `encantar_persona` lleva un `mechanics` que no es suyo: "Convocas espiritus feericos en forma de bestia con un valor de desafio total de 2 o menos" (es *conjurar seres del bosque*). El `roleNotes` de `hechizar_persona` tampoco corresponde.

## Conjuros de camino (repaso de clases)

Cotejadas las 111 promesas de conjuro del Libro (listas ampliadas, `grantedSpells`, `spellGrants`, trucos) contra los 384 del compendio: **ninguna rota**.

**Hueco corregido**: el Druida solo concedia el par de nivel 3 de su camino; el manual da conjuros en 3, 5, 7 y 9. Anadido el escalon de nivel 5 con rasgo propio (patron `_3`/`_5` del Chaman):

| Camino | Nivel 5 segun el manual | Estado |
|---|---|---|
| Equilibrio | luz del dia, estallido estelar | `luz_del_dia` OK; **estallido estelar falta** |
| Restauracion | palabra curativa en masa, revivificar | `palabra_de_curacion_en_masa` y `revivir` OK |

Divergencias de nombre resueltas: *palabra curativa en masa* -> **Palabra de curacion en masa**; *revivificar* -> **Revivir**.

**Paladin**: sus tres caminos conceden 3 de los 4 conjuros de nivel 3-5. Falta uno por camino, y los tres son contenido propio de Warcraft que no esta en el compendio: `penitencia` (Sagrado, nivel 3), `castigo deslumbrante` (Proteccion, nivel 5) y `castigo justo` (Retribucion, nivel 5).
