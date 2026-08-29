# Historial de cambios

Historial del addon Harford, generado desde los commits del repositorio y ordenado del mas
reciente al mas antiguo. Para la arquitectura y los contratos vigentes mira **`AGENTS.md`**;
para el mapa de modulos, **`ESTRUCTURA.md`**.

Convenio de los mensajes: `feat` nuevo, `fix` arreglo, `refactor` reorganizacion sin cambio de
comportamiento, `docs` documentacion y `chore` mantenimiento.

Regeneralo con `python tools/gen_changelog.py`.

- Commits: **594** - del **2026-05-18** al **2026-08-29**

## Agosto de 2026

**Nuevo**

- **picaro** - Conocer la Intencion resuelto — es Impacto certero (True Strike) `0997169`
- **brujo** - Rayo del caos cableado en la lista ampliada de Destruccion `1b1cff2`
- **creacion** - los prerequisitos de LANZADOR de las dotes se validan `402a9c4`
- **creacion** - los prerequisitos de COMPETENCIA de las dotes se validan `6d95f92`
- **creacion** - los prerequisitos de caracteristica de las dotes se validan `04e4757`
- **creacion** - los requisitos raciales de dotes y subclases se APLICAN `6f41721`
- **creacion** - las opciones de conjuro se presentan como en el compendio `42bf05e`
- **compendio** - la magia racial cuenta como siempre preparada en el grimorio `d359b13`
- **razas** - Legado elfico del Semielfo elige su truco de mago y sale en el About `e9b2099`
- **trasfondos** - "un instrumento o juego" es UN grupo combinado a elegir `0a58e42`
- **razas** - las otras subrazas Draenei mecanizadas con sus descripciones `58d6e49`
- **razas** - el incremento del Elfo de la Noche es por subraza — Altonato lo cambia `76f911c`
- **razas** - Elfo de la Noche con DOS subrazas reales, como la web `b4332e1`
- **creacion** - instrumento musical y juego se eligen por miembro concreto `d627ad8`
- **creacion** - ninguna eleccion ofrece lo que ya tienes `e7bf877`
- **creacion** - el dialogo de eleccion lista los nombres de lo marcado `fd583e6`
- **heroe** - el DM concede el punto desde el menu del target (DNDHERO) `5bfaf26`
- **heroe** - puntos de heroe segun el manual Warcraft — uno, especial y del DM `bd478f0`
- **barras** - el tooltip del boton es el MISMO del Libro (y el del grimorio) `0b3aa2d`
- **barras** - conjuros arrastrables a la barra nativa y supervivencia a .poss `b7e7315`
- **admin** - click derecho DM en un aura nativa del target lanza su .unaura `b41fdbf`
- **estados** - click derecho en la tira retira el estado (propio y, con DM, ajeno) `9155df0`
- **estados** - Inconsciente y Muriendo entran al catalogo; aviso a la web `aea94c6`
- **frames** - la tira de estados tambien pinta los PROPIOS sobre el PlayerFrame `3e48942`
- **admin** - el menu de estados del DM se agrupa por categorias del catalogo `4f2c5fc`
- **yunque** - entrenadores, con el id de catalogo que el codigo espera `28c69f4`
- **conjuros** - castigo abrasador y castigo justo tambien estaban en el compendio `70fcab0`
- **conjuros** - penitencia y descarga mental resueltos como equivalencia; peticion a la web `b8e5565`
- **yunque** - armas y armaduras del sistema, con modificadores y color `560b5df`
- **clases** - Furia Elemental funcional y riders del Cazador de Demonios `87fbc9d`
- **yunque** - yunque de secuencias de accion `92d7e46`
- **yunque** - yunque de rutas de patrulla `c37109f`
- **estilos** - los estilos de combate condicionales aplican con su condicion `ea3277d`
- **yunque** - atuendo del NPC, que no estaba bloqueado `6fb2f14`
- **yunque** - yunque de NPC de fase `4dd963e`
- **yunque** - yunque de gossip, que saca un guion y no una tirada `26c18ce`
- **turnos** - el "no" de unirse se contesta con su motivo `21a4d1e`
- **turnos** - Preparar es la unica rendija del turno ajeno `46be976`
- **datos** - razas, trasfondos y dotes sin limbo -- 509 rasgos, todos decididos `61b2ce6`
- **clases** - 100% atendido -- el limbo de "informativo sin mecanica" se vacia `cf3c63a`
- **clases** - los conjuros de camino/dominio son spellGrants reales -- 86% mecanizado `0e2552e`
- **clases** - todo rasgo activable declara ya lo que cuesta `937e8a8`
- **yunque** - yunque de misiones, cotejado contra el addon `32f4cb1`
- **yunque** - editar lo que ya existe, y un yunque de recetas `4d57afc`
- **movimiento** - el DM rueda libre dirigiendo y vuelve de golpe al empezar su turno `9a099cb`
- **musica** - herramienta para bajar una lista y encadenarla con la conversion `7cff45d`
- **turnos** - fuera de tu turno no hay nada, ni reaccion ni movimiento `50b316a`
- **dano** - el ataque de un NPC a un jugador tambien lo publica la victima `0ea9a0c`
- **dano** - la linea la publica la victima, con el numero ya real `209fb29`
- **musica** - herramienta para pasar una carpeta de audio a emisoras `808a935`
- **movimiento** - la barra tambien al poseer, con la velocidad del NPC `7038f17`
- **dm** - devolver accion, adicional, reaccion o movimiento al objetivo `6ff0c6a`
- **turnos** - boton para unirse a un combate en curso, y caducidad a 15 min `28cb7d6`
- **radio** - emisoras extra desde un addon aparte, HarfordMusic `9a2b24e`
- **turnos** - si el DM se cae, releva un companero `c625104`
- **economia** - la economia de turno sobrevive a un /reload `9d1ebce`
- **economia** - si no te queda la accion, no se hace `9d9c454`
- **turnos** - el marcador lleva el movimiento y la economia, y devuelve al inicio `a09bf58`
- **yunque** - iconos a 50 px, con hoja cuadrada `b1dbd7f`
- **yunque** - iconos a 28 px, y el tamano deja de estar fijo `7f5eceb`
- **turnos** - el estado del combate deja de deducirse de la lista `fa8cf13`
- **turnos** - al terminar el combate se recoge todo, y en un sitio `40084aa`
- **yunque** - selector visual de iconos y las 37 opciones del forge `da2687a`
- **turnos** - el estandarte lista lo que te queda por gastar `2bccd5d`
- **yunque** - pagina para definir objetos a mano `f872fa3`
- **turnos** - marcador permanente de turno y asalto `da39560`
- **movimiento** - posicion para el jugador, velocidad para el NPC poseido `06ef029`
- **turnos** - dos estilos de estandarte, y las tarjetas de la lista funcionan `b14efb6`
- **turnos** - estandarte al empezar un turno, con arte nativo `31773e1`
- **turnos** - la lista de un bloque la ve cualquiera, la edita el DM `f25b0cc`
- **turnos** - la lista de un bloque son las tarjetas de siempre, con scroll `641d5e3`
- **economia** - barra de movimiento sobre la barra de accion, estilo BG3 `4ea569d`
- **turnos** - listas de bloque como tarjetas, y el movimiento se cuenta solo `c939214`
- **movimiento** - Correr dobla el tope, y la bateria deja de llorar en falso `11fbf6f`
- **movimiento** - se ancla donde terminas y puedes volver `32641d9`
- **movimiento** - el contador sabe cuanto te queda, se reinicia y se cuenta `de3606a`
- **admin** - el DM ve las tarjetas de cada bloque `4a95b06`
- **turnos** - las tarjetas especiales son BLOQUES y guardan a los suyos `5783d46`
- **turnos** - la lista se abre por bando, y los PJs se anaden en bloque `0337a77`
- **admin** - cadena de mando para los efectos sobre NPC, y la UI de DM fuera del core `59d572b`
- **turnos** - la vida temporal de NPC se comparte, e Iniciar avisa `4d3d699`
- **areas** - la curacion y las auras sueltas tambien se delegan `69ab8ad`
- **npc** - las rutas de ataque entran en la cola delegada `64b8c42`
- **npc** - un jugador sin permiso delega el efecto en el lider `679b15e`
- **turnos** - lista de candidatos para anadir al combate `d1ef0df`
- **estados** - quien entra a mitad de combate pide los estados de los NPC `d6c2abc`
- **turnos** - cada bloque abre y cierra, con hueco para tocar el reparto `72dd062`
- **turnos** - el turno avanza por bandos, no por criatura `89740f5`
- **turnos** - bandos como dato de la entrada, con orden fijo `6700ec1`
- **estados** - cola de auras pendientes sobre NPC `6282145`
- **estados** - se piden al targetear, como los recursos `ab320d2`
- **debug** - la bateria comprueba que la tira este DENTRO de la pantalla `f5ed073`
- **debug** - la bateria se explica sola, con 'verificar ayuda' `e82175d`
- **monje** - Niebla reconfortante se puede gastar, que era el ultimo recurso mudo `df34de0`
- **areas** - distancia por objetivo y los que quedaron fuera, en la ventana `2e0fb32`
- **debug** - la bateria pasa de seis grupos a nueve, y la red deja de ser manual `18c680c`
- **tooling** - mutaciones.py, para saber si las pruebas prueban `5d2e91b`
- **tooling** - detector de referencias a algo que no existe `08c08ec`
- **debug** - bateria de verificacion EN JUEGO `d4e0ccf`
- **estados** - Gracia de Elune abre de verdad sus tres acciones adicionales `51862df`
- **acciones** - Ayudar, Preparar y Lanzar arma dejan de ser narrativas `85598ba`
- **acciones** - tirada enfrentada, y con ella Agarrar y Empujar `e4c47ea`
- **estados** - tira propia de estados Harford sobre el unitframe del target `afa93ff`
- **auras** - contador propio sobre el icono, y acciones basicas con sus iconos `2272e2f`
- **acciones** - Esquivar, Correr, Desengancharse y Esconderse en General `0727ccf`
- **monje** - Punos de Furia hace los dos golpes de verdad `7c00527`
- **brujo** - Caos y Rebotar actuan sobre el conjuro ya lanzado `a4cb400`
- **sacerdote** - Oracion de Curacion repite los dados de verdad `87e01d0`
- **motor** - pruebas de habilidad contra CD, y Corte de Ala con la suya `7728897`
- **brujo** - Ritos de alma lanza el ritual de verdad `f57e453`
- **about** - copia del About de TRP3 antes de que Harford lo reescriba `461460e`
- **migracion** - pregunta antes de convertir los ids de la ficha `a38d48c`
- **migracion** - guarda una copia de la ficha antes de tocarla `59a3547`
- **brujo** - las piedras de alma se forjan y se gastan `b4f749a`
- **estados** - Esquivar como condicion, y dos costes de accion mal declarados `37ba377`
- **tiradas** - motor generico para modificar una tirada ya hecha `f91d286`
- **dotes** - descripcion breve propia en las 77 `4f3c99b`
- **monje** - Palma aturdidora, Efusion y Brebaje del Buey Negro `667ee56`
- **dotes** - descripcion breve propia y el extractor la respeta `d40a1df`
- **paladin** - Canalizar Divinidad deja de ser un anuncio `c053cd5`
- **condiciones** - resistencia por tipo, Piel de Hierro e Imprudencia `c5b1f4a`
- **brebajes** - los que replican un conjuro lo lanzan de verdad `1562419`
- **opciones** - las elecciones dejan de solo anunciarse y resuelven su efecto `89f8304`
- **barra** - habilidades del Libro en los ActionButton nativos `4fa64a6`
- **libro** - las opciones elegidas se vuelven habilidades usables `2a05315`
- **tools** - trazabilidad de ids -- donde vive cada uno y que quedo colgando `3f57ecb`
- **economia** - 49 rasgos declaran ya que accion cuestan, y el Guerrero la concede `f258f6f`
- **recursos** - fichas y espacios sobre la barra nativa, y el pacto con cuenta propia `8b1714a`
- **economia** - fichas de accion estilo BG3 y la reaccion se gasta de verdad `64ef72f`
- **turnos** - inicio/fin de combate con iniciativa, y modularizacion del tracker `24e6982`
- **clases** - mecanizacion 1-6, tarjetas de creacion y carga diferida de datos `71346c7`
- **codice** - hoja de eleccion para los iconos que el cliente no sirve `b33daf1`
- **codice** - generador de fichas de personal desde los perfiles TRP3 `f0ef310`
- **codice** - orden de clase del juego y facciones como nombre propio `7f53fe2`
- **codice** - rasgo propio de variante, parrafo cortado y Ravenholdt `1a5f04b`
- **profesiones** - degradado de dificultad, economia a cero y herramienta de bolsa `4637248`
- **fase** - el aviso va por el canal HarfordNet, no por el grupo `b92028b`
- **fase** - avisar al publicar para que los conectados relean al momento `9ed2382`
- **loot** - historial de saqueo en la fase, para NPCs permanentes `32f4b66`
- **reputacion** - compartir siembra tambien el catalogo en la fase `5fca228`
- **fase** - lo automatico solo actualiza, sembrar es deliberado `3c42532`
- **fase** - loot y facciones se publican solos, no solo desde debug `0ad4a2a`
- **fase** - recargar por eventos, y aislar el loot entre fases `1c7eecf`
- **loot** - leer la tabla de la fase cuando el cliente no la tiene `58f368c`
- **reputacion** - catalogo de facciones guardado en la fase `019c718`
- **loot** - tablas de loot guardadas en la fase `703c6ab`
- **contratos** - cerrar la mision en el tablon al completarla `b043c1f`
- **contratos** - bajar los contratos enteros, no solo el indice `2d44982`
- **itemforge** - extraer los displayid como via alternativa del modelo `6fb29e5`
- **contratos** - tablon guardado en la fase de Epsilon `e6419fc`
- **profesiones** - ventana de entrenador que abre el gossip con solo el ID `c315fb9`
- **itemforge** - dar a cada objeto el modelo 3D del original `b11f4c6`
- **itemforge** - regenerador para cuando cambian las fuentes `56f42c8`
- **itemforge** - sacar la info de los objetos y detectar los ya creados `405aa08`
- **itemforge** - el registro guarda la lista categorizada, y limpieza de bolsas `d441f93`
- **profesiones** - catalogo de 75 entrenadores, uno por profesion y rango `6c033de`
- **profesiones** - entrenadores por RANGO, no por lista de recetas `c1b587e`
- **itemforge** - abrir los objetos para que cualquiera pueda .additem `25fb690`
- **itemforge** - generador y reimportacion de objetos custom en masa `aa3c9fd`
- **profesiones** - base de entrenadores de receta `25fea12`
- **reputacion** - la fila alterna su detalle `839b195`
- **sonido** - abrir y cerrar el detalle de una reputacion `7e4006e`
- **sonido** - pasar pagina en los tres libros y abrir el desplegable de filtros `280d8d1`
- **sonido** - la ficha de tiradas suena como el registro de misiones `d930e12`
- **sonido** - los del libro de profesiones y del libro de habilidades `c2bba02`
- **profesiones** - el sello alterna la ventana de recetas `236e3b9`
- **minimapa** - "Herramientas de Rol" pasa a "Harford DnD 5e" `24763c8`
- **ficha** - fuera los iconos de turnos y de panel de personaje `58a214c`
- **libro** - tooltip en los botones de profesion `a08e80c`
- **libro** - pestana Profesiones sobre el libro de habilidades y espacios de conjuro `535a59d`
- **reglas** - cansancio, concentracion, punto de heroe, maniobras, cobertura y carga `3426efe`
- **profesiones** - recetas dinamicas y crafteo verificado contra el servidor `3f881b2`
- **profesiones** - ventana de recetas reconstruida desde el XML del cliente `1072cf5`
- **debug** - sonda con identidad de objetos y generador de skin desde captura `b94a542`
- **profesiones** - fundicion con animacion, tirada en mesa y botones de hechizo `df1553a`
- **profesiones** - cadenas Classic completas, joyeria TBC e inscripcion Lich `d8f892a`
- **profesiones** - ventana de recetas replica del TradeSkillFrame `7b2831f`
- **profesiones** - cadena de ingenieria, hierbas reales de Epsilon y estaciones `c8d4210`
- **misiones** - XP real en recompensas y sync de objetivos endurecido `57da639`
- **creacion** - nivel 1 + subidas encadenadas, pasos navegables y layout adaptativo `b6bf15e`
- **xp** - sistema de experiencia propio con barras integradas en el gestor nativo `a059050`
- **reputacion** - skin 1:1 de la sonda nativa, pestaña unica y enlaces TRP3 de faccion `8f65a40`
- **about** - frame de Profesiones en el About generado de TRP3 `8d39639`
- **profesiones** - el DM puede enseñar recetas worldLearned (TEACH) `7240769`
- **profesiones** - nodos de recoleccion en el mundo (GatherNode) `20f0b4a`
- **debug** - merchantdump vuelca los items del mercader abierto `0642999`
- **profesiones** - cadenas completas 1-300 para las 14 profesiones de WoW `ad22a7b`
- **creacion** - compra por puntos ademas de la tirada, con +/- `47227ce`
- **creacion** - panel de resumen del personaje `622d960`
- **creacion** - rejilla de iconos para raza y trasfondo `56d977e`
- **creacion** - barra de pasos lateral al estilo BG3 `28895fc`
- **colores** - color propio para las 36 subclases en el About `9c15337`
- **panel** - fila de Competencias y arreglo de las elecciones repetibles `54a8bfb`
- **trasfondos** - descripcion completa en el About de TRP3 `ff91228`

**Arreglos**

- **toc** - Harford a secas y Harford Admin en la lista de addons `1b53a4b`
- **toc** - HarfordDebug se titula Harford Debug con el color de la familia `ab6c008`
- **toc** - los addons de datos se titulan Harford Compendio y Harford Objetos `15f9cd8`
- **heroe** - el uso magico se llama Impacto Certero, no Hechizo Preciso `17230ef`
- **creacion** - el motor lee requiredAbility (barrera de datos muertos) y candado al dia `b5c7c0b`
- **dotes** - descripciones cotejadas contra la web — 11 al dia, 0 sin pareja `6dd3580`
- **clases** - descripciones cotejadas contra la web (188) con marcadores explicitos `f99bf36`
- **razas** - el Man'ari conserva el CON+1 de hoy; notas de recarga segun la web `e370147`
- **razas** - descripciones cotejadas contra la web por id — 38 descs y 82 rasgos `618ce35`
- **trasfondos** - rasgos cotejados contra la web por id — 61 descripciones al dia `3512441`
- **trasfondos** - descripciones sincronizadas desde la web canonica `6eae4f8`
- **creacion** - los huecos de arma del equipo se numeran y BLOQUEAN el confirmar `ef1a5fe`
- **creacion** - la etapa de Equipo colapsa la columna de lista vacia `8b64807`
- **creacion** - Reiniciar de Caracteristicas fijo junto a Confirmar, fuera del scroll `186a0f5`
- **trasfondos** - terminologia y grupos correctos de instrumento y juego `72a689b`
- **iconos** - Competencias de clase usa inv_scroll_11, como la entrada agregada `e6a6d8b`
- **creacion** - el Reiniciar del array 4d6 va al borde izquierdo, visible `6b54c16`
- **razas** - Man'ari segun la web — solo CON +1 y Magia Vil con conjuros `e9421d4`
- **creacion** - el detalle de origen alinea con el titulo, sin canalon izquierdo `4954da0`
- **creacion** - detalle de raza sin hueco muerto, sin solape y con la raza base `f1674db`
- **creacion** - los nombres marcados caben en 3 lineas sin pisar Confirmar `1fcb384`
- **creacion** - el selector de idioma ya no ofrece los que ya hablas `669a05b`
- **iconos** - Esconderse usa eps_bg3_hide, a juego con el resto de acciones basicas BG3 `15cfac7`
- **barras** - las acciones basicas se pueden colocar en la barra nativa `557fba3`
- **barras** - habilidades arrastrables de verdad, con nombre y tooltip en el boton `b316e6a`
- **acciones** - Desengancharse se resuelve anunciandose, con marcador explicito `0b222a5`
- **acciones** - fuera la coletilla gris de Desengancharse `0d3ba40`
- **frames** - la tira propia arranca donde empiezan las barras, no bajo el retrato `baafd24`
- **estados** - el TTL de cache remota ya no se muestra como "Quedan 600 s" `5acd3e9`
- **yunque** - los yunques no se veian entre ellos `bf56b35`
- **musica** - el despliegue no copiaba los .ogg, asi que ninguna emisora sonaba `a4bc96a`
- cuatro globales accidentales, cazados por la auditoria de bytecode `da291f8`
- **acciones** - el menu de coste cobra LO ELEGIDO, no el click que lo abre `cb8a242`
- **movimiento** - el turno ajeno te ancla donde estas, SIEMPRE `946a934`
- **razas** - "Elfo noble" y "Alto elfo" cargaban sin rasgos raciales `d077f45`
- **turnos** - llegar con el turno YA empezado ahora reconcilia, no regala `b927953`
- **turnos** - unirse al combate y devolver la iniciativa no se difundian `1a85064`
- **turnos** - la vida del NPC no llegaba a nadie -- doble fallo que se tapaba solo `97d3afc`
- **turnos** - la foto comprimida de una mesa MEDIANA se descartaba en silencio `33dc5f4`
- **reputacion** - borrar una faccion no le llegaba a nadie `b875967`
- **codice** - limpiar tambien el texto de manual de las dotes `a887b16`
- **itemforge** - las rutas apuntaban a archivos que ya no existen `0825ef9`
- **turnos** - el aviso de combate abandonado, ahora por lista de lo que SI cuenta `dba718b`
- **turnos** - "se retiro un combate abandonado" salia sin haber combate `c959781`
- **dano** - la etiqueta se mandaba siempre pero el atacante solo callaba a veces `d25e8c1`
- **turnos** - el aviso de "ventana creada" no se disparaba nunca `a8fde99`
- **equipo** - la descripcion de Epsilon viene entrecomillada y eso anulaba TODAS sus reglas `b82fc4d`
- **equipo** - un cuero tachonado entraba como cuero (base 11, no 12) `acad828`
- **panel** - un +1 de equipo en la CA se contaba dos veces `fa39f84`
- **equipo** - "Clase de Armadura +1" no daba nada `c13a0b4`
- **turnos** - fuera el avance por bloques; el turno va de criatura en criatura `f9f3e92`
- **turnos** - un fallo pintando callaba el anuncio y la mecanica del turno `2006a9b`
- **turnos** - la fase vuelve a la entrada, y el motor deja de mirarla `2b40648`
- **turnos** - un fallo al pintar dejaba de difundir el estado a la mesa `11b3da9`
- **estados** - sin fase de cierre, las condiciones de FIN de turno no caducaban `4cd5e94`
- **turnos** - Siguiente pasa UN bloque, no medio `ef847c4`
- **turnos** - la marca de ACTIVO sigue al bando, y fuera el aviso de ESTADOS `43fd3bc`
- **turnos** - fuera de tu turno no hay accion, adicional ni movimiento `2091126`
- **turnos** - la marca de "ventana abierta" se borraba al recargar `6ba81ae`
- **turnos** - la ventana vuelve tras un /reload `68b4c36`
- **turnos** - al DM no se le tira su combate, y la lista del grupo no repite `73c24d2`
- **turnos** - recibir la foto cuenta como tocar la lista `3fa2c0d`
- **turnos** - un combate abandonado caduca entero, no solo sus entradas `235e494`
- **chat** - un objetivo unico no se rotula como area, y Imposicion no tira nada `d3ad506`
- **economia** - Imposicion de manos --y toda la familia actionKind-- ya cuesta `d44a427`
- **economia** - una maniobra cuesta la accion, aunque no lo declare `0003849`
- **libro** - los listados no ocupan una fila cada uno, dicen su origen `90cdd2c`
- **libro** - una dote se llama por su nombre, y su etiqueta dice Dote `8c9e00f`
- **bateria** - Correr salia en rojo, y era la lista de la bateria la que estaba vieja `5772d32`
- **equipo** - la CA base solo cuenta desde el pecho, y la cache no se corrompe `227d7f0`
- **acciones** - la accion basica se para si no cabe, y sale en una linea `4746ffb`
- **yunque** - la fuente de iconos es la carpeta, no un CSV filtrado `dbfe6fb`
- **turnos** - el aviso de turno era para toda la raid, y salia por duplicado `14a0e14`
- **yunque** - faltaban los iconos custom, que son los que importan `e112aa1`
- **movimiento** - el muro salta al agotarse el recurso, no al parar `79e974e`
- **turnos** - solo se limita a quien esta DENTRO del combate `a828297`
- **economia** - la barra leia un valor que solo se escribia al parar `e16e2c3`
- **turnos** - el marco de OBJETIVO tambien en las listas de bloque `c722476`
- **movimiento** - el oyente del turno no llegaba a registrarse nunca `d07980f`
- **movimiento** - fuera de combate no se limita nada `e310326`
- **movimiento** - el motor no puede colgar de la ficha `df125e0`
- **economia** - el coste de un ataque se mecaniza, no se asume `389fd33`
- **economia** - atacar y lanzar cuestan la accion, que no costaban nada `0999744`
- **yunque** - la rejilla entera, bien recortada y con la lista de la web `6508bef`
- **economia** - el centro sale de la barra principal, y el movimiento solo en combate `5bed74b`
- **economia** - los iconos van centrados y encima de TODA la pila de barras `525f69e`
- **economia** - la barra de movimiento no salia si no habias abierto la ficha `55b53b6`
- **libro** - el guardia de usos va en el repartidor, no en cada rama `51e3f84`
- **libro** - un rasgo sin usos ya no concede su recurso `529e0c6`
- **turnos** - devuelto el marco de OBJETIVO, y las fichas en colores BG3 `a8d4a3f`
- **turnos** - devueltos los botones de reordenar, que me lleve por delante `e45a65e`
- **movimiento** - al NPC se le cuenta el movimiento, pero no se le pone muro `94029c2`
- **turnos** - un miembro de bloque ES una entrada, no un guid con nombre `ba7eb50`
- **movimiento** - el ancla salia sin mapa, y el tiron fallido no decia nada `4a3f448`
- **estados** - lo mio caduca en mi turno, aunque el turno se llame "PJs" `92c8e68`
- **barra** - las fichas de accion quedaban DETRAS de la barra nativa `88e619e`
- **libro** - iconos heredados de la fila anterior, y la dote se llama "Dote: X" `c23ee31`
- **libro** - una dote es UNA habilidad, no una por cada cosa que hace `a8fccb0`
- una dote elegida no se activaba, solo se apuntaba `62fa1fe`
- **turnos** - modificar vida de NPC delega, y el tope solo si se conoce `fa0a381`
- **combate** - los tres sitios resuelven el empate de CA igual `7b319ce`
- la caida del Brujo y las tres regresiones que meti hoy `d9c9be2`
- los seis ultimos de la sexta revision `7a29f50`
- nueve de la sexta revision, empezando por los arreglos mal hechos `0a87c52`
- la quinta revision. El modo bandos ni siquiera se podia encender `e2bd533`
- la cuarta revision, y detector para la clase que mas se repite `0598977`
- los ocho hallazgos de la tercera revision `d2fb3b9`
- los siete hallazgos de la segunda revision `2f95ad7`
- los seis hallazgos de la revision, todos preexistentes `bf593da`
- **turnos** - asaltos en modo bandos, y ponerse al dia al volver `97a8513`
- cierra tres agujeros de red y turnos `d31d59f`
- **debug** - ficha6 limpia tambien las dotes `d0ee8db`
- **estados** - con varios DMs manda el lider al informar de los NPC `ce33e32`
- **turnos** - al caducar la lista se olvida tambien el bando activo `0b4f653`
- **turnos** - el aviso de bando viaja con su lista de miembros `1dc2c3c`
- **inspect** - sin flechas de equipo, y auditada la seguridad de los datos `394638b`
- **estados** - decir cuando un estado no se publica, y recordar la columna `cd0a0e0`
- **contienda** - FormatCheckRollLabel no se inyectaba, y Empujar reventaba `5e403ab`
- **estados** - la tira en columna con el primer buff `957d740`
- **estados** - la tira se salia de la pantalla, y por eso no se veia `3526606`
- **iconos** - los dos que Epsilon no tiene, confirmados en juego `df429e9`
- **areas** - una esfera o un cubo se centran donde apuntas, no en ti `2cb5f14`
- **estados** - nueve condiciones definidas no se aplicaban nunca `ee35cf0`
- **acciones** - apartar derribaba igual, y disparar lo preparado cobraba dos veces `ee3cad0`
- **auras** - el contador se quedaba viejo si cambiaba sin cambiar el aura `8a43ee7`
- **acciones** - la prueba de habilidad se resolvia contra la forma vieja `4cb0aeb`
- el bono del arma en verde, y la migracion calla al inspeccionar a otro `3562e4b`
- **recetas** - el texto de la barra de fabricacion quedaba pegado abajo `d9e79d8`
- **enlaces** - el enlace de habilidad buscaba su icono solo por NOMBRE `542e937`
- **tiradas** - las lineas defensivas llevan TU nombre, no el de la ficha `bda58e6`
- **areas** - el tamano se comparaba en la unidad equivocada `8464cc0`
- **dano** - el detalle repetia el tipo que ya dice la cabecera `90cfe7d`
- **dano** - "Recibido" solo cuando el resultado no es el anunciado `671d680`
- **dano** - la linea de "Recibido" repetia el numero y pintaba un "(-)" `a9eccd1`
- **libro** - mostraba TODAS las opciones elegibles, no solo la elegida `8e4f25d`
- **profesiones** - el prefijo prof_ es obligatorio, pero el fallo deja de ser mudo `3005112`
- **profesiones** - el prefijo prof_ rompio los gossip ya colocados en el mundo `5b9b083`
- **guerrero** - Reserva de Ira no daba ira, y el detector de datos muertos `211ab05`
- **orden** - cuatro locales llamadas antes de existir, y el detector que faltaba `c9505f4`
- **iconos** - los rasgos de raza y trasfondo no cogian su propio icono `2f54d62`
- **razas** - el id de Humano nunca se prefijo, y sus iconos fueron a la subraza `b891b65`
- **refactor** - cinco roturas mas de la modularizacion, y como detectarlas `712dd13`
- **unitframes** - un `end` de mas rompia el addon entero al cargar `72b5fa7`
- **iconos** - 6 iconos de subclase duplicados en la tabla plana de rasgos `df3a986`
- **datos** - instrumento y juego son CATEGORIAS de herramienta, no herramientas `2a95231`
- **codice** - nameF, variants y la ruta de profesiones tras el refactor a addons LoadOnDemand `8c19c56`
- **tools** - el codice vuelve a encontrar el compendio, y los 5 brebajes que faltaban `6782b57`
- **datos** - el coste de una opcion es un dato, no parte de su nombre `dc94c14`
- **iconos** - los brebajes del Cervecero llevaban el id viejo y salian sin icono `90b91ed`
- **multiclase** - tres recursos que se acumulaban y no debian `58c7b93`
- **iconos** - sustitutos de los que el cliente no sirve, importados de la web `8904279`
- **codice** - tildes de clase en las fichas de personal e icono del Artesano gremial `4eb21dd`
- **codice** - recorrido del volcado TRP3 consciente de las cadenas y desempate por fecha `a699391`
- **codice** - glosario en conjuros importados, ceros de OCR y nombres canonicos `2b16c52`
- **codice** - deduplicar conjuros por id final e iconos de dos trasfondos `ddb5d21`
- **toc** - 45745 era el numero de build, no la version de interfaz `525d49f`
- **fase** - dos fallos encontrados al repasar lo ultimo `cb8c27b`
- **loot** - reparar el historial solo en la direccion segura `09102df`
- **fase** - una lectura fallida no es un almacen vacio `80f030e`
- **contratos** - nada automatico puede vaciar el tablon entero `e1d54c7`
- **reputacion** - una fase vacia no puede borrarte el catalogo local `bd8021b`
- **ficha** - no escribir en disco las tablas vacias de la progresion `8a3363f`
- **reputacion** - sembrar la fase cuelga de compartir ESTRUCTURA `2f51914`
- **debug** - acotar las capturas del probe y barrer los restos de votos `531085a`
- **fase** - ninguna via de publicacion se salta el guard de fase `a2de32c`
- **misiones** - completar por objetivos no repartia XP ni reputacion `28ee813`
- **fase** - acotar la publicacion a la fase de la que vienen los datos `719d47a`
- **comandos** - /harford no anunciaba `reparto` ni `debug` `7f0e1fe`
- **misiones** - QOBJ y QOBJDONE no aplicaban nada `55f7f20`
- **profesiones** - el entrenador daba por sabidas todas las recetas `925282d`
- **itemforge** - proteger el registro en EpsilonLib `770d294`
- **contratos** - borrar deja huerfanos y el error viajaba donde los datos `a35b962`
- **contratos** - el id de fase se colaba en la lista de claves del manifiesto `ddbc6d6`
- **itemforge** - mandar el display como enlace, no como numero suelto `c1b16e3`
- **itemforge** - que el borrado no pueda llevarse nada del jugador `204d98d`
- **itemforge** - fallos encontrados al revisar el borrado, y acotar la salida `a52f89f`
- **itemforge** - tapar los fallos silenciosos de una tanda larga `c73c8c9`
- **condiciones** - el nivel de cansancio no se guardaba `90c8680`
- repaso de bugs por patrones que ya habian mordido `be0dd3d`
- **libro** - recoge tambien el ornamento que sobresale del hueco de profesion `49e8eb2`
- **libro** - el icono de profesion va palido, como el nativo `81b1c60`
- **recetas** - ventana de crafteo cotejada contra el XML y la sonda nativa `77fb134`
- **xp** - recupera la version de las barras que si funcionaba `447ad26`
- cadenas `and` que truncaban retornos multiples `5a91f2e`
- **compendio** - concentracion real, escalado de trucos y subida por espacio `63e0b94`
- **profesiones** - sello del libro segun SpellBookFrame.xml 9.2.7 `44b709b`
- **profesiones** - plantillas de Blizzard donde el arte Classic no carga `bd2765d`
- **profesiones** - usar los fileID reales del frame nativo, no rutas inventadas `4b8e711`
- **profesiones** - sello del libro con la geometria real de la sonda `c743a7a`
- **sonido** - el crafteo no reutiliza los sonidos de mision `3ccfa6f`
- **profesiones** - crafteo uno por uno y reserva de material en vuelo `a7167c8`
- **creacion** - reinicia la compra por puntos al reabrir el asistente `ee6daa3`
- elimina el multi-retorno de gsub en los 8 normalizadores restantes `8cb678e`
- **creacion** - la Pericia ofrecia todas las habilidades en el asistente `b14f5af`
- **colores** - paleta de clase exacta y colores de subclase de los perfiles `41fb05f`
- **contratos** - la lista del tablon acumulaba filas de todos los refrescos `5389abc`
- **trp3** - normalizadores que devolvian dos valores por el gsub final `358bf74`
- **servidor** - filtra saltos de linea al normalizar un comando Epsilon `6d57100`
- **creacion** - las fichas creadas perdian los incrementos de caracteristica `4a68ae7`
- **progresion** - evita huecos en classLevels al fijar una entrada de clase `a78b72a`
- **loot** - valida el remitente de HARFORDLOOT y HARFORDCFG `c044433`
- **turnos** - valida el remitente de los mensajes HARFORDTURN `7da4ee6`
- **competencias** - pericia solo sobre habilidades competentes y quita HasToolProf duplicada `bacbd17`
- **docs** - repara el mojibake de AGENTS.md `1c646d7`
- **admin** - unifica salida de chat y mejora NPC/condiciones/misiones `b05254d`

**Refactor**

- **ficha** - descansos (corto/largo/dados de golpe/menu) a HarfordDnDRest `948b99c`
- **panel** - tooltip de competencias y reacciones preparadas al modulo de acciones `a89d293`
- **panel** - acciones basicas, rituales, reservas y prompts a modulo propio `3f5d2b6`
- **ficha** - panel de acciones externas (ficha NPC) a HarfordDnDActionPanel `5b33c13`
- **ficha** - API externa de tiradas y dos mecanicas mas fuera de HarfordDnD `25b9fc9`
- **ficha** - menus y riders del Libro extraidos a HarfordDnDBookActions `5c73ebc`
- los receptores de loot entran al troceador compartido `ee8081c`
- fase B -- un solo troceador para progresion y equipo `d17e6a6`
- fase A -- fuera el codigo muerto verificado `4b64027`
- **turnos** - una sola tarjeta y un solo sitio donde se pinta `ebc65f8`
- **tiradas** - un solo formato de linea, sin dos puntos y con el desenlace al final `99ba4e3`
- **ids** - prefijo raza_ en 39 entidades e idioma_ en 21 idiomas `4ec0f16`
- **ids** - prefijos her_ y prof_, con sus dos migraciones `138be93`
- **ids** - prefijo feat_ en las 77 dotes `4784a98`
- **ids** - segundo pase, migracion de datos de jugador y verificacion final `af8dedf`
- **ids** - convencion <abrevClase>_<abrevSub>_<cosa> en los 63 sin prefijo de clase `dfbc6e3`
- cinco modulos mas, y el limite de 200 locales bajo control `8af8b06`
- **profesiones** - HarfordCraftSkin pasa a HarfordProfessionsCraftSkin `25c9415`
- **profesiones** - los entrenadores se deducen, no se listan `ee1fe5a`
- **profesiones** - el nombre de catalogo ya dice profesion y rango `74f6304`
- **profesiones** - el entrenador se identifica por su nombre de catalogo `a870c7c`
- organiza el addon en carpetas por dominio `918a636`

**Rendimiento**

- **sync** - la progresion tambien viaja comprimida `cac4e4e`
- **sync** - el equipo viaja comprimido, y la compresion pasa al transporte `d68ee7f`
- **turnos** - la foto viaja comprimida: de doce mensajes a dos `2a7941c`
- **turnos** - la vida de un NPC va sola, no dentro de la lista entera `76c1a97`
- **turnos** - avanzar el turno eran 13 mensajes; ahora es 1 `9d092eb`
- **yunque** - la causa real del bloqueo era var() en CSS `e77bb15`
- **yunque** - de 9,3 MB a 2,5 y se acaba el bloqueo al bajar `af8c99c`
- **movimiento** - el muro salta en el paso, y el tiron ya no se paga a si mismo `03c8b6f`

**Documentacion**

- **epsilon** - la forja no acepta las clases de WoW, y el rechazo corta la cadena `38e91b7`
- **claude** - fase C al dia — sexto corte, leccion del boton de combate y fin de cortes limpios `5ee475a`
- **claude** - fase C documentada — patrones Init/Build y estado de los cortes `3022dc1`
- **conjuros** - CONJUROS_PENDIENTES al dia; estallido estelar resuelto y concedido `feb113d`
- **estado** - Brujo resuelto (pact ya cubre ambas reglas) e iconos verificados `7a14a0f`
- el bloqueo de criatura acompanante estaba RESUELTO y sin tachar `b42ec81`
- el Cazador estaba al 85%, no al 61% -- el criterio contaba mal las trampas `734659c`
- cifras de mecanizacion regeneradas a 2026-08-28, con el cast en el criterio `5960e91`
- por que EpsilonLib es RequiredDeps `5e1467a`
- la regla de fuera de turno, y por que el muro sobrevive al cambio de turno `848406f`
- **turnos** - unirse es automatico, el DM solo se entera `e84c69f`
- al dia lo del turno, y cuatro grupos nuevos de verificacion en juego `8bd6547`
- la comprobacion de usos va antes del efecto, no en el anuncio `62a2aca`
- documenta lo de hoy y amplia la bateria de verificacion `6fcd9c3`
- **agents** - lo confirmado esta semana, con el porque de cada regla `2764607`
- dejar en los contratos lo que faltaba de esta tanda `55182f7`
- **agents** - confirmado que escribir en la fase es de oficial `175d9bc`
- **agents** - almacen de fase completo, y dos conclusiones que eran falsas `9cf7645`
- **itemforge** - dejar escrito que el registro no se toca `7ce38c6`
- regenera el mapa de modulos y el historial `e1550fa`
- ventana de recetas, pestaña Profesiones movida y sonda comparada `fab6f86`
- flujo de creacion encadenado, contratos de XP/reputacion y regeneracion `b957d51`
- **agents** - la pasada de textos del compendio es del chat de la web, no de Codex `fa9b448`
- pasada completa de actualizacion `d3aeef1`
- regenera el historial de cambios `9d7b568`
- organigrama de modulos (ESTRUCTURA.md) e historial (CHANGELOG.md) `e5e4137`
- actualiza el README (HarfordDebug y subcomandos /harford) `108184f`

**Mantenimiento**

- **debug** - decir que tarjeta deberia estar iluminada y por que `95dc034`
- **debug** - ver los espacios de conjuro y los de pacto `0bec1a8`
- **economia** - fuera el constructor de la barra de movimiento, que ya no lo llama nadie `02f5967`
- **debug** - que la limpieza diga POR QUE se llevo el combate `d23395f`
- **debug** - la sonda mira tambien las APIs nativas de aviso `b90e2e1`
- **debug** - pintar las fichas de accion a la fuerza en el centro `c2edd14`
- **debug** - galeria de estilos de aviso de turno `83bfedd`
- **debug** - la sonda mira familias enteras de atlas, no cuatro nombres `c6d5fba`
- **debug** - comprobar los atlas del estandarte antes de montarlo `d66c0d7`
- **iconos** - retirar cuatro entradas huerfanas mas del catalogo `d5fddd1`
- **iconos** - retirar la entrada huerfana vida_falsa `1e55b34`
- **iconos** - retirar de los candidatos los nombres que el cliente no sirve `3450959`
- dejar de versionar los compilados de Python `8813f8d`
- regenerar el mapa de modulos y limpiar el arbol `11535b8`
- **debug** - poder vaciar los volcados que guarda HarfordDebugSettings `9604024`
- **debug** - medir si PLAYER_STARTED_MOVING dispara en Epsilon `4ffa457`
- **debug** - entrenador acepta el nombre de la receta y sugiere al fallar `cf5aedf`
- **debug** - diagnosticos de reglas, compendio y skin de profesiones + contratos `8cd37d1`
- **debug** - herramientas para replicar UI nativa sin adivinar `816208c`
- **debug** - exportador de capturas y claves Frame/etiqueta en el generador `e500661`
- **profesiones** - auditoria de integridad + corrige el contrato de misiones `b0466a7`
- **debug** - nativeprobe unificado, soundlog, profskill y suite de profesiones `98978fe`
- **chat+compendio** - prefijos unicos sin duplicar y parrafos markdown en conjuros `de10b41`
- **tools** - pipeline de extraccion del conocimiento y comando profitems `d228f9a`
- **tools** - generadores de ESTRUCTURA.md y CHANGELOG.md `331fd2e`
- ignora RuleSource/, Codice_Harford.html y AddonsIndependientes/ `1b65b2a`
- añade el addon opcional HarfordDebug e ignora EpsilonIcons/ `582d403`

**Otros**

- test(debug): el ciclo de estados respeta las inmunidades del verificador `104a327`
- test(debug): la bateria sigue al naming actual de dotes y detalla el paso del ciclo `d0a4039`
- test(clases): el stub del compendio entra en el env aislado del Libro `a16ddde`
- test(clases): stub de HarfordCompendioAPI para verificar elecciones de truco `913f0dd`
- test(opciones): el candado de DraftLanguages sigue a su firma nueva `76ec1f6`
- test(heroe): candado del DNDHERO sin salto de linea literal en el find `17f4c7c`
- test(debug): la bateria verifica tambien los iconos por NOMBRE del catalogo `6f01fbc`
- test(verificar): cuatro grupos que EJERCITAN los sistemas sin suite propia `9286f28`
- test(auditoria): las referencias cruzadas de datos quedan como candado permanente `82ff891`
- release: version 2.1.0 -- lista para distribuir `62a7146`
- build: pasar del margen de locales deja de ser un aviso y no despliega `feba5a4`
- test(verificar): la tira sin sitio arriba se solapa a proposito, y la prueba no lo sabia `6e3f278`
- build: EpsilonLib pasa a RequiredDeps, y con ella LibDeflate `6a1b89c`
- test(verificar): la tira no se puede comprobar con otro jugador de objetivo `7f2f498`
- test(verificar): el informe se guarda en disco, y dice antes que te falta montar `71ea7f7`
- test(verificar): el grupo turnos comprobaba las fases, que se retiraron `6822b7c`
- test(verificar): las comprobaciones a mano se agrupan por lo que hay que preparar `74ec0b7`
- test(verificar): bateria en juego para lo que cambio hoy `64bf0ae`
- test(dano): el enlace del arma sobrevive a las dos pasadas, y sin objeto va el nombre `2d631ea`
- debug: de donde sale tu CA, escalon a escalon `f3a8f59`
- docs+fix: bandos en AGENTS.md, e Iniciar/Terminar los reinician `b0f03a5`
- debug: diagnostico de por que no se ven las fichas de accion `e89cd5e`
- debug: ficha6 sortea tambien raza, trasfondo y caracteristicas `ff6934e`
- debug: ficha6 rellena las elecciones al azar `3639a8d`
- debug: ficha6 monta una ficha de nivel 6 de cualquier clase `cfd18aa`
- debug: mide tambien ChatThrottleLib, que no toca el formato `ec29e19`
- debug: mide Chomp frente a SendAddonMessage `6f44526`
- test(tira): la aritmetica del ajuste, y dos correcciones `a69fcea`
- test(progresion) + docs(objetos): de donde salen las lineas condicionales `ef21745`
- test(objetos): el parser de descripciones, y su regla mas delicada `1386147`
- test(armas, xp, recursos): tres modulos de datos que no tenian ninguna prueba `94342c2`
- test(clases): el tercer patron del repaso, conjuros concedidos que no existen `62b485d`
- test(clases): los tres fallos del repaso manual, convertidos en comprobacion `47082b3`
- test(red) + feat(debug): la bateria pasa a 12 grupos y se protege sola `c3b53d6`
- test(concentracion, maniobras) + fix(tooling): una mutacion muerta a medias `ff65f72`
- test(motores): geometria de areas, parser de dano libre y puntos de heroe `e065df0`
- test(rasgos): FeatureEffects, de donde sale cada bonus del personaje `23a3001`
- test(combate) + feat(debug): reglas de impacto cubiertas, y verificacion de ataque `3e8c392`
- test(dano condicional): costes, escalado y el ciclo del boton `95a6d25`
- test(condiciones): el motor de estados y el catalogo contra el manual `01b6af8`
- test(calc): HarfordDnDCalc pasa de 1 mutacion detectada de 12 a 50 de 51 `cf765ef`
- test(contienda): la eleccion del defensor se EJECUTA, no se busca en el texto `1e01b3f`
- style(iconos): los estados usan la sintaxis y el sitio del resto del catalogo `55dd201`
- build: desplegar exige que las pruebas pasen `4967938`
- revert(profesiones): sin aviso de nombre sin prefijo `e910935`
- data(iconos): Parpadeo y Represion infernal `d5a9ba8`
- data(iconos): Mentor prominente del Aprendiz del Kirin Tor `bc09d53`
- test: 12 suites de logica sobre el codigo real, con runner `bf2c23e`
- data(iconos): Artesano gremial es ability_racial_jackofalltrades `42e6004`
- data(iconos): Mala Reputacion y Siervos `4f79982`
- data(iconos): Perspicacia erudita del Eremita `005f29d`
- data(trasfondos): los rasgos de Criminal pasan a bg_crim_* `83c3d70`
- data(iconos): las 27 caracteristicas de trasfondo `b956bd3`
- tools(codice): mas competencias al pergamino, sin pisar el rasgo de clase `c017cab`
- data(iconos): Doble Agente -> factionchange `9a631f9`
- tools(codice): trasfondos y variantes leen el catalogo de iconos `3bcdf3b`
- tools(codice): Beneficios al pergamino, y las variantes entran en la hoja `c2d03d1`
- data(iconos): 93 rasgos mas de dote y las tres subrazas que faltaban `ebd7e7e`
- tools(codice): el resultado de la hoja, solo lo de esa hoja `66c5606`
- data(iconos): llamado marcial y ataques con armas del Chaman Mejora `72ed552`
- tools(codice): seis rasgos marcados como sin icono a proposito `c0706c7`
- tools(codice): singular/plural en la magia, y herencia entre gemelos de nivel `39e170c`
- data(iconos): seis rasgos mas de Chaman, Monje y Paladin `e8adf72`
- tools(codice): el rasgo que concede conjuros hereda el icono de su magia `522920b`
- tools(codice): cosecha de iconos desde los frames del TRP3 `1f9b1af`
- tools(codice): la regla de idiomas, por palabra y no por prefijo `6bf870d`
- tools(codice): las reglas por nombre tambien en las subclases `bfbbe10`
- tools(codice): iconos de dote, filtro multiple y bloque de clases en la hoja `f74c546`
- tools(codice): el buscador de iconos, en columna fija a la derecha `35f2b0e`
- tools(codice): buscador de iconos en la hoja de seleccion `090af09`
- tools(codice): leer las clases del libro partido en modulos `3a3ddf3`
- tools(codice): seguro contra publicar una coleccion vacia `8182501`
- tools(codice): no copiar el texto del manual al primer rasgo de la dote `cab618a`
- tools(codice): descripciones de profesiones y dos huecos del auditor `f4ff031`
- tools(codice): el pipeline del compendio, al dia `72066ea`
- data(profesiones): catalogo reescrito, y las herramientas como objeto `3133ccb`
- Revert "chore(debug): medir si PLAYER_STARTED_MOVING dispara en Epsilon" `8a957d0`
- tools: compilar contra el Lua 5.1 real en vez del 5.4 local `ecbab8d`
- data(compendio): textos completos metricos, limpieza OCR y nombres normalizados `5b7715c`
- revert(colores): deja la paleta de clase como estaba `6cc7032`

## Julio de 2026

**Refactor**

- extrae la pestaña Conjuros a HarfordCharacterSpellbook `2337695`

## Junio de 2026

**Nuevo**

- compendio de conjuros en core + motor de area extendido + condiciones `5ec9ad4`
- panel de personaje + razas/trasfondos/dotes/mana + competencias + animaciones de combate `7ba8492`

**Refactor**

- cache de pieces nativos + unificacion de helpers (acentos/toN/nombres) `1ad801d`

**Otros**

- refactor+feat: maniobras de energia, dano por tipo, auras bajo barras y limpieza `deb8eee`
- Panel de jugador `ac93085`

## Mayo de 2026

**Nuevo**

- tooltip en todos los botones de recurso con la pista de Ctrl+click `6e9d03c`
- Ctrl+click en botones del frame de recursos abre prompt de cantidad `2508ad1`
- "Enviar ficha" como primera opcion del menu admin con target jugador `27ae485`
- color de clase TRP3 en nameplates + nombre sobre barras Kui + glow absorb `dbdc977`
- vida temporal (absorb bar) con Shield-Fill, texto +X y fix resize nameplates `214e88c`

**Arreglos**

- daño jugador->jugador + recuperar CA del focus `0964129`
- enganchar eventos TRP3 para el retrato del player (login lento) `380d07b`
- re-aplicar retrato/icono TRP3 del player tras login (timing TRP3) `190b25e`
- BonusConcat varargs pasaba el siguiente arg como base a tonumber `ec99e82`

**Refactor**

- DRY del glue de tiradas d20 en HarfordDnDCalc `dbf6c55`
- completar y documentar frontera admin/core de HarfordTurns `f9fa5cd`
- HarfordDnDRolls/UI/Profile + fix daño custom `1439b40`
- integrar modulos en core/admin + modelo de autoridad 3 ejes `013b995`
- modulos de datos/calculo/red + DRY color de clase y geometria `9449521`

**Documentacion**

- contratos de modulos nuevos, modelo de autoridad 3 ejes y limites WoW `4a7fe45`

**Otros**

- debug: comando portraitwatch + nota caso retrato player (no resuelto) `58a72f5`
- Mejoras `7e7aae0`
- Reputacion, UI admin y mejoras de sistema `f9722c2`
- Arreglo rep y nameframes `ba9ccc7`
- Reputacion `a8b8892`
- Actualizacion `00b97f5`
- Ajusta nameplates y unitframes Harford `18ea19a`
- Merge pull request #1 from Griker95/dev `34a68d4`
- Ajusta unitframes y overlays Harford `35ad757`
- Initial commit: Harford DnD 5e addon + documentación de agentes `9631f19`
