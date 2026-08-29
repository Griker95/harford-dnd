# Guia Para Agentes - Proyecto Harford

Este archivo documenta el contexto tecnico que debe recordar cualquier agente que trabaje en este repo. Es una guia viva: actualizala cuando se confirme nueva informacion del entorno Epsilon/Shadowlands o cambie la arquitectura de los addons.

Documentos hermanos: **`ESTRUCTURA.md`** es el organigrama de modulos (que hace cada archivo, orden de carga, flujo de datos y prefijos de red) y **`CHANGELOG.md`** el historial de cambios. Este archivo (`AGENTS.md`) manda en los **contratos**: reglas de modulo, limitaciones de Epsilon y enfoques ya descartados.

## Repositorio Y Colaboracion

- **Fuente de contenido y pipeline**: la web publica `harfordweb` es la fuente canonica de contenido curado para clases, subclases, razas, trasfondos y conjuros. El addon consume una copia validada de ese contenido; los manuales de `RuleSource/Rulebooks/` siguen siendo la autoridad para comprobar reglas, traducciones y artefactos OCR antes de importar. El alcance vigente de la sincronizacion web -> addon es clases/subclases de nivel 1-6 y conjuros de nivel 0-4. La creacion automatica basada en esos datos esta **en curso**, no se declara terminada ni se debe dar por funcional hasta su revision en juego. `tools/codice/` conserva utilidades de extraccion, cotejo y publicacion historicas: no ejecutar una direccion addon -> web ni web -> addon sin confirmar el flujo actual y revisar el diff de datos. El HTML local `Codice_Harford.html` queda como fallback offline y no se mantiene por duplicado. Las copias del scratchpad de sesion quedan OBSOLETAS: editar solo las de `tools/codice/`. `bgs_source.json` es FUENTE (extraccion de Discord, no regenerable); `kb*.json`/`icons_data.json` son intermedios gitignored. Requiere en disco `EpsilonIcons/png` y `RuleSource/` (ambos fuera de git).

- **RENOMBRADO de los addons de datos (2026-08-29)**: `HarfordCompendioData/` es ahora
  **`HarfordCompendio/`** (fichero `HarfordCompendio.lua`) y `HarfordProfessionsData/` es
  **`HarfordProfesiones/`** (`HarfordProfesiones.lua` + `HarfordProfesionesItems.lua`). Cambia
  SOLO el nombre de addon/carpeta/fichero: los **globals Lua conservan su nombre**
  (`HarfordCompendioSpells`, `HarfordProfessionsData`, `HarfordProfessionsItems`) y las
  SavedVariables viven en `Harford.toc`, asi que nada persiste distinto. Implicaciones para
  CUALQUIER agente (chat del codice y Codex incluidos): (1) el pipeline que regenera el compendio
  debe escribir en `HarfordCompendio/HarfordCompendio.lua` — escribir en la ruta vieja RECREARIA
  la carpeta retirada; los scripts de `tools/codice/` de este repo ya estan actualizados; (2) los
  `LoadAddOn` del core piden los nombres nuevos; (3) al actualizar un cliente hay que BORRAR las
  carpetas viejas de `Interface/AddOns` (el README lo avisa). Titulos de la familia en la lista
  de addons: `Harford`, `Harford Admin`, `Harford Compendio`, `Harford Profesiones` (antes `Harford Objetos`), `Harford Debug`, `Harford Musica`, todos con la marca `|cff3536CC`.

- Repo privado: `harford-dnd`.
- Ramas:
  - `main`: version estable. No hacer push directo; solo via PR desde `dev`.
  - `dev`: rama de trabajo diaria.
- Flujo esperado cuando se trabaje con Git:
  - `git checkout dev`
  - `git pull` antes de empezar.
  - Cambios locales pequenos y enfocados.
  - `git add <archivos>` + `git commit -m "descripcion"` + `git push` solo si el usuario lo pide explicitamente.
- Para pasar a estable, crear PR desde `dev` a `main` despues de probar en Epsilon.
- Fuentes compartidas:
  - `AGENTS.md`: arquitectura, contratos, limitaciones Epsilon, decisiones confirmadas y enfoques fallidos.
  - `CLAUDE.md`: instrucciones especificas para Claude Code.
  - `.cursorrules`: instrucciones especificas para Cursor si existe en el repo.
- Fuentes de reglas:
  - Todo manual, PDF y texto de referencia vive en `RuleSource/Rulebooks/`; no dejar copias sueltas en la raiz del workspace.
  - **Libro 1:** `RuleSource/Rulebooks/Warcraft 5º Edición.txt` es el Markdown completo en espanol y la fuente prioritaria para descripciones, razas, clases, rasgos y trasfondos de Harford.
  - **Libro 2:** `RuleSource/Rulebooks/Heroes of Warcraft 5º (Alt).txt` es una fuente adicional en ingles: usarla solo para ampliar contenido que no cubra el Libro 1 y traducir cualquier dato incorporado.
  - Los manuales normales de D&D 5e en `RuleSource/Rulebooks/` (Manual del Jugador, Guía del Dungeon Master, Manual de Monstruos, Xanathar, Tasha, Costa de la Espada y Volo) son referencias válidas para reglas generales y contenido no cubierto por Warcraft.
  - Jerarquía de fuentes: D&D 5e base para reglas generales; Libro 1 Warcraft para cualquier adaptación o regla homebrew de Azeroth; Libro 2 solo para ampliaciones no presentes en el Libro 1. Si hay conflicto, prevalece la fuente más específica.
- Convenciones:
  - Codigo, comentarios y documentacion operativa en espanol.
  - No crear archivos nuevos sin peticion explicita.
  - Diagnosticos temporales siempre en `HarfordDebug.RegisterCommand`, nunca en modulos de gameplay.
  - Si una solucion se descarta por pruebas en juego, documentarla aqui como enfoque fallido.
  - No tocar ZIP/RAR/backups del workspace salvo peticion explicita.

## Proyecto Y Entorno

El workspace contiene tres addons:

- `Harford`: addon principal de ficha DnD, recursos, loot y turnos.
- `HarfordAdmin`: addon opcional/admin, dependiente de `Harford`.
- `HarfordDebug`: addon opcional de diagnostico, dependiente de `Harford`. No es requisito de juego ni de administracion.

Intencion del producto:

- Harford es un addon de control para GM/Dungeon Master en Epsilon.
- Debe ayudar a dirigir partidas basadas en DnD 5e dentro de WoW.
- El addon cubre dados, estados, fichas, atributos/caracteristicas, recursos, loot y orden de turnos.
- Tambien debe ayudar al DM a manejar enemigos/NPCs y ejecutar comandos basicos de servidor cuando sea necesario.
- La experiencia debe favorecer control rapido durante la partida, claridad para jugadores y herramientas admin seguras para el DM.

Entorno objetivo:

- WoW Shadowlands/custom, servidor Epsilon.
- Interface actual del addon Harford: `45745`.
- `EpsilonLib` inspeccionado en `G:\Epsilon\_retail_\Interface\AddOns\EpsilonLib`.
- `GobClone` inspeccionado en `G:\Epsilon\_retail_\Interface\AddOns\GobClone`.

## Arquitectura Objetivo

### Salida De Chat

- Todo mensaje visible para usuario emitido por `Harford` o `HarfordAdmin`, incluidas tiradas, misiones, reputacion, loot y avisos de herramientas, debe pasar por `HarfordChat.Print` o `HarfordChat.Format`.
- El prefijo unico es `|cff00ccff[Harford]|r`. Los colores de error, exito o resultado se aplican despues del prefijo, nunca creando etiquetas alternativas como `[D&D]`, `[HarfordAdmin]` o `[Mision compartida]`.
- `HarfordDebug` es la unica excepcion: conserva `[HarfordDebug]` porque solo existe bajo diagnostico explicito.

### Sonidos De Interfaz

  - `HarfordUISounds.lua` es la fuente unica de sonidos de interfaz propios de Harford. Los consumidores llaman `HarfordUISounds.Play(evento)`; cada entrada de `HarfordUISounds.SOUNDS` declara `{ id = <numero>, kind = "file"|"soundkit" }`. `file` usa `PlaySoundFile` (FileDataID) y `soundkit` usa `PlaySound` (SoundKitID). No repartir IDs literales ni decidir la API en paneles o sistemas. Para clasificar un ID nuevo, usar solo diagnostico explicito: `/harford debug run soundprobe <ID> [file|soundkit|both] [SFX|Master]`; `soundevent <evento>` prueba una entrada ya registrada. El cambio de faccion seguida usa `reputation_tracking_changed` (SoundKit 856).
- Eventos de mision actuales: `quest_accepted` (567400), `quest_gossip_shown` (567503), `quest_log_opened` y `quest_tracking_changed` (567504), `quest_log_closed` (567508), `quest_completed` (567439), `quest_abandoned`/`quest_failed` (567459) y `quest_objective_completed` (1045704). `communicator_message_received` (567402) acompana cada recepcion verde/amarilla incluso con el Comunicador abierto; el modo rojo y el modo silencioso no suenan. `character_panel_opened` (567507) se reproduce solo al mostrar el panel de personaje; `character_panel_tab_changed` (567422) al pulsar `Personaje`, `Reputacion` o `Profesiones`; `character_sidebar_tab_changed` (567407) al cambiar entre las tres vistas del lateral derecho; `skills_panel_opened` y `skills_panel_tab_changed` (567440) al abrir o cambiar entre `Habilidades` y `Conjuros`.

Contrato `HarfordCommunicator`:

- Modulo core de mensajeria para jugadores que tengan Harford cargado, inspirado funcionalmente en Noumenon Index.
- Usa el prefix `HARFCOM` exclusivamente por `WHISPER`: los grupos se distribuyen como susurros dirigidos a sus miembros, no abren canales globales, no ejecutan comandos Epsilon y no requieren `HarfordAdmin`.
- `HarfordCommunicatorStore` conserva contactos, grupos, opciones e historial, limitado a 100 mensajes por conversacion. Fragmentos, ACK y deduplicacion son runtime con TTL y no se persisten.
- Un grupo solo acepta mensajes de remitentes presentes en su definicion recibida del propietario. Los mensajes recibidos son solo texto: no ampliar este protocolo para ejecutar acciones, comandos ni modificar datos de juego.
- Radio es una pestana propia y reproduce emisoras mediante `TRP3_API.utils.music.playLocalMusic(id, 25)`; el boton "Apagar radio" usa `stopLocalMusic()`. No duplicar la logica de sonido en Harford.
- Contratos monta el tablon dentro del mismo frame del Comunicador mediante `HarfordContracts.UI.OpenEmbedded(parent, onClose)`. No deben coexistir dos ventanas ni reparentar regiones sueltas: el tablon embebido conserva su propia jerarquia visual. `HarfordContracts.UI.OpenStandalone()` queda para futuros tablones fisicos y para `/harford contratos`.
- Aperturas: `/harford comunicador` y la bandeja abren el Comunicador normal. La bandeja se deshabilita si el inventario no contiene el item `14085291`, aunque el slash directo sigue permitido. `/harford radio` es solo una entrada silenciosa al Comunicador, en Contactos, y NO aplica el aura `309862`; no tiene relacion con la pestana Radio. Las navegaciones internas deben conservar el modo de apertura y no renovar esa aura. La pestana Radio no debe aplicar ni retirar auras.
- Abrir con `/harford comunicador`, `/harford radio` o desde la bandeja de Herramientas. `/harford mensajes` esta retirado.

Transformacion incremental:

- `Harford` es el core compartido para jugadores y DM.
- `HarfordAdmin` es la capa de autoridad DM/Admin, herramientas avanzadas y futuras acciones de NPC/enemigos.
- Los comandos de servidor no son exclusivos de `HarfordAdmin`: algunas funciones del core, como loot o auras de UI, tambien deben poder enviar comandos seguros.
- Las dependencias externas (`EpsilonLib`, `ARC`, TRP3) son opcionales y deben comprobarse en runtime.

Arbol logico:

```text
Harford/
  HarfordSync.lua             -- transporte addon, serializacion, canales, prefixes
  HarfordDebug.lua            -- logging/debug
  HarfordConfig.lua           -- configuracion del addon: HarfordConfig.Get/Set, panel Interface Options, /harford config
  HarfordAuthority.lua        -- permisos: Admin addon, rango phase y modo DM
  HarfordEpsilonCommands.lua  -- wrapper compartido para comandos Epsilon/ARC
  HarfordCommandTemplates.lua -- plantillas con placeholders {id}/{sign}/{amount} para comandos Epsilon
  HarfordEmotes.lua           -- datos: ORDER + DEFS de emotes de combate + NPC_WOUND/NPC_WOUND_CRIT
  HarfordServerActions.lua    -- acciones servidor validadas; usa HarfordCommandTemplates + HarfordEmotes
  HarfordActionSequence.lua   -- motor de secuencias de acciones con delay (estilo ArcSpell ligero)
  HarfordActionSequencePresets.lua -- catalogo hardcodeado de secuencias decodificadas de SpellCreator
  HarfordAuras.lua            -- datos: ORDER + DEFS de auras conocidas + helpers Apply/Remove por scope
  HarfordClassColors.lua      -- fuente unica de color de clase WoW (alias es/en, normalizacion, RGB/hex)
  HarfordIconCatalog.lua      -- fuente unica de iconos y registro por identificador estable
  HarfordTRP3.lua             -- lectura segura de perfiles TRP3 jugador/companion/NPC Epsilon
  HarfordUIGeom.lua           -- helpers puros de geometria/busqueda de StatusBars para overlays
  HarfordDamageTypes.lua      -- datos: ORDER + DEFS de tipos de dano D&D 5e (fisico/magico)
  HarfordDamageMitigation.lua -- resuelve immune/resistant/vulnerable/normal leyendo stat block TRP3
  HarfordUnitFrames.lua       -- overlays TRP3/recursos Harford sobre PlayerFrame/TargetFrame
  HarfordNamePlates.lua       -- overlays DnD sobre nameplates nativos/KuiNameplates
  HarfordDnDResources.lua     -- recursos DnD, cache remota, claves; AnimFlagCache por jugador
  HarfordDnDStore.lua         -- persistencia de fichas/perfiles
  HarfordDnDEconomy.lua       -- saldo temporal de oro D&D; se activa solo tras crear ficha valida
  HarfordDnDContext.lua       -- estado de contexto de ficha (SheetContext) + accesores Get/Set (ARCGET/ARCSET)
  HarfordDnDProfile.lua       -- aplica tablas de perfil/recursos sobre HarfordDnDStore (hooks inyectados)
  HarfordDnDUI.lua            -- constantes visuales/layout y fabricas UI pequenas de la ficha
  HarfordDnDAttackUI.lua      -- construccion/estado visual de Ataque y tracker de movimiento bajo demanda
  HarfordDnDCustomDamage.lua  -- parser, tirada, mitigacion y ventana de dano personalizado
  HarfordDnDConditionalDamage.lua -- niveles, costes, validacion y escalado de dano condicional
  HarfordDnDRolls.lua         -- serializacion/render/broadcast de tiradas D&D via DND5EARC
  HarfordDnDData.lua          -- datos: tablas ABIL (caracteristicas) y SKILLS (habilidades)
  HarfordDnDBook.lua          -- libro hardcodeado: clases, subclases, rasgos y efectos declarativos
  HarfordDnDProgression.lua   -- estado por perfil: niveles de clase, featureStates internos, choices
  HarfordDnDItems.lua         -- equipo virtual: item links reales, iconos, stats, arma/CA derivadas
  HarfordCharacterInspect.lua -- inspeccion ligera de panel remoto por snapshot read-only
  HarfordDnDFeatureEffects.lua-- resuelve efectos activos sin ejecutar Lua arbitrario
  HarfordDnDConditions.lua    -- catalogo/estado de condiciones: aura, aura+metadata o estado Harford
  HarfordDnDWeapons.lua       -- datos: tabla WEAPONS + helpers de arma (ParseDice, dados, props, menu)
  HarfordDnDCalc.lua          -- calculo puro: modificadores, dados, bonos (lee via HarfordDnDContext)
  HarfordDnDNet.lua           -- recursos/red: export/request/adjust de recursos via HarfordSync
  HarfordDnDCombat.lua        -- reglas de combate con contexto de unit: CA, impacto, daño servidor NPC
  HarfordDnDArea.lua          -- ataques de area: marcado manual, receptor jugador y cola NPC por GUID
  HarfordDnDMinimap.lua       -- boton de minimapa de la ficha (toggle + reset de posiciones inyectado)
  HarfordCommunicator.lua     -- mensajeria Harford: contactos, grupos, historial y protocolo HARFCOM
  HarfordDnDComm.lua          -- recepcion DND5EARC y handlers cliente-cliente
  HarfordLoot.lua             -- UI loot y datos loot; usa wrapper compartido para additem/aura
  HarfordDnD.lua              -- UI ficha y recursos (consume los modulos DnD* anteriores)
  HarfordCharacterBook.lua    -- clasificacion/datos de PRESENTACION del Libro (logica pura, sin estado del panel)
  HarfordCharacterCreation.lua -- valida/aplica el borrador del creador y genera el About local de TRP3
  HarfordCharacterAdvancement.lua -- asistente moderno de creacion y subida: aplica elecciones de nivel sin reescribir el origen
  HarfordCharacterPanel.lua   -- panel de personaje + ventana independiente de Habilidades/Conjuros; flecha de nivel y /harford char subir abren el asistente moderno
  HarfordActionBars.lua       -- barra de accion (config-gated "actionbar") para habilidades del Libro
  HarfordCompendioCore.lua    -- API del compendio de conjuros y persistencia por personaje
  HarfordCompendio.lua    -- datos de conjuros (`HarfordCompendioSpells`)
  HarfordCompendioIconMap.lua -- resolucion de iconos del compendio
  HarfordCompendioUI.lua      -- interfaz de busqueda, detalle, lanzamiento y grimorio
  HarfordReputation.lua       -- core: facciones, reputacion por PJ y rangos
  HarfordReputationSync.lua   -- sync de red via prefix HARFORDREP
  HarfordReputationUI.lua     -- panel de reputaciones (/harford rep o embebido en CharacterPanel)
  HarfordTurns.lua            -- tracker turnos, HP/mana, sync de turnos

HarfordAdmin/
  HarfordAdmin.lua            -- bootstrap, slash commands, API admin existente
  HarfordAdminNPC.lua           -- acciones admin basicas sobre target/NPC/enemigo
  HarfordAdminConditions.lua    -- ejecutor DM de condiciones sobre jugadores/NPC por GUID
  HarfordAdminUnitMenu.lua      -- menu contextual DM en PlayerFrame/TargetFrame
  HarfordReputationAdmin.lua    -- panel GM de gestion de reputaciones: crear/editar/ordenar/renombrar grupos

```

Contrato `HarfordCompendio`:

- Vive como modulo del core en `Harford/HarfordCompendio*.lua`, cargado desde `Harford.toc`.
- API publica: `_G.HarfordCompendioAPI` (nombre unico). La integracion en core ya termino: se retiraron los alias del nombre invertido antiguo `_G.CompendioHarfordAPI`/`_G.CompendioHarfordSpells`; no reintroducirlos.
- Datos globales: `_G.HarfordCompendioSpells`.
- SavedVariables declaradas en `Harford.toc`: `HarfordCompendioDB` y `HarfordCompendioCharacterDB`.
- La normalizacion de texto debe delegar en `HarfordClassColors.StripAccents` cuando exista; no duplicar nuevos mapas de acentos aqui.
- Slash: usar solo `/harford compendio` o `/harford magia`. No registrar comandos globales sueltos para el compendio.
- Comandos Harford: toda UI nueva debe colgar de `/harford <subcomando>`. No registrar slash sueltos salvo el dispatcher principal `/harford` y el namespace admin explicito `/harfordadmin`. El editor de loot admin se abre con `/harford loot` o `/harford cargarloot` cuando `HarfordAdmin` esta cargado; no reintroducir `/harfordloot` ni `/hloot`.
- Lanzamiento de conjuros: `HarfordCompendioCore` es la puerta unica (`CanCast`, `AnnounceCastAttempt`, `ResolveCast`, `ConfirmCast`, `SpendSpellMana`). Coste via `HarfordDnDMana.GetSpellCost` (FUENTE UNICA; no duplicar tabla de coste de mana); rituales 0. `ResolveCast` enruta con `BuildAreaDefinition`: (1) salvacion (area/directa/condicion) -> `HarfordDnDArea.Open` `resolution="save"`; (2) ataque de conjuro CON daño y/o condicion -> mismo motor `resolution="attack"`. **Objetivo unico** se marca `shape="other"`/`sizeText="Objetivo"` y se **auto-resuelve sin ventana** (`context.autoResolve`); el **area real** abre ventana para marcar varias victimas. El motor aplica daño mitigado por tipo + condicion a **Player** (`DNDAREAREQ`, el receptor tira su salvacion/CA) y **NPC** (cola por GUID). (3) ataque de conjuro SIN daño -> `RollSpellAttack` (solo impacto vs CA, sin daño automatico). (4) resto -> `ConfirmCast` informativo. El mana se gasta en `onCommit`/`ConfirmCast`, nunca al anunciar; `{ silent = true }` para rutas que ya emiten tirada propia. **Gate de UI**: el boton "Lanzar Hechizo" se deshabilita sin mana (`CanCast`) y, para ataques directos (`API.SpellNeedsTarget`), sin objetivo; se re-evalua con la ventana abierta enganchando `HarfordUnitFrames.Refresh` (endpoint universal de cambios de recurso) y `PLAYER_TARGET_CHANGED`. **Anuncio** (`AnnounceCastAttempt`/`ConfirmCast`): formato LIMPIO `<lanzador> <link conjuro> <target>` (link TRP3 clicable via `API.GetSpellChatLink`, espejo de `GetAbilityChatLink`; target coloreado por clase/RP via la logica de `ColoredUnitName`); `ConfirmCast` añade `|cff00ff00EXITO|r`. Sin verbos ("intenta/lanza") ni mana en el texto. No crear gasto de mana ni tiradas paralelas en la UI ni en `HarfordDnD.lua`.
- Multiimpactos y curacion: `BuildAreaDefinition` detecta por texto los impactos homogeneos de rayos/proyectiles/fragmentos (incluida `Descarga sobrenatural` escalada por nivel total). Se resuelven en `HarfordDnDArea` como aplicaciones independientes: cada una tira su propio d20 y dano, y puede repartirse o concentrarse en un objetivo. Las curaciones se detectan por categoria + texto (`recupera`, dados y hasta N criaturas), usan `resolution="heal"`, no pasan por mitigacion y respetan el maximo visible de salud local/NPC. `DNDAREAREQ` usa el codigo `H` para curacion. Multiimpactos heterogeneos, con salvacion compartida o fases posteriores permanecen guiados hasta tener un resolvedor especifico; no falsear sus reglas desde la UI.
- Construccion/interpretacion de conjuros: la mecanica se DERIVA DEL TEXTO (`attack`/`savingThrow`/`damage`/`range`/`mechanics`/`description`), NO de campos estructurados (salvo `condition`). Parsers puros en `HarfordCompendioCore` (`SpellText` concatena el corpus): `ParseDamageComponents` (`XdY[±Z] <tipo>`, tipo canonizado), `ParseSaveAbility` (`savingThrow` o "TS de X"/"salvacion de X"), `ParseAreaMeta` (forma desde `range` Personal+radio/cono/linea/esfera o marcador `Area:`), `ParseSaveSuccess` (mitad->`half`/niega->`none`), `IsSpellAttack`/`IsDirectSaveSpell` (ataque vs CA vs salvacion), `SpellAttackRange` (cuerpo a cuerpo->melee), `SpellDC`/`SpellAttackBonus` (caracteristica `AtributoConjuro`, default Inteligencia: CD=8+mod+PB+bonus). Para mejorar la deteccion, AMPLIAR los parsers de texto; no añadir campos estructurados de daño/salvacion por conjuro.
- `ParseAreaMeta` del compendio debe leer `range`, `mechanics` y `description`: muchos conjuros de jugador describen el area en prosa (`cono de 15 pies`, `cubo de 20 pies`, `cuadrado de 10 pies`, `linea de 30 metros por 1,5 metros`, `esfera de 1,5 metros de radio`) y no en un campo estructurado. Acepta unidades `metro(s)`, `m`, `pie(s)` y `ft`; la cadena original de tamaño se conserva como `sizeText`. La pestaña Conjuros del panel de personaje NO lanza por ruta propia: abre el detalle del compendio, y el boton de lanzamiento llama siempre a `HarfordCompendioAPI.ResolveCast`, que a su vez abre `HarfordDnDArea` cuando `BuildAreaDefinition` detecta area/ataque/salvacion.
- Campo `autohit = true` de conjuro (estructurado): marca auto-impacto (daño sin tirada ni salvacion, ej. Proyectil Magico) -> `BuildAreaDefinition` usa `resolution="auto"`; el motor de area aplica el daño mitigado a Player/NPC sin tirar (rama `mode="auto"` en `ResolvePlayerRequest`/`ResolveNpcEntry`, codigo de red "U"). NO es auto-detectable por texto (chocaria con daño rider/curacion), por eso es flag explicito; para multi-dardo (Proyectil Magico) el `damage` representa el total base a un objetivo y el escalado por nivel es manual.
- Campo `zone = true` de conjuro (estructurado): zona de daño persistente por turno (ej. Nube de Dagas). En este RP SIN posicionamiento real, se modela como area re-resoluble: `BuildAreaDefinition` marca `area.zone` y nunca la trata como objetivo unico (no auto-resuelve, siempre ventana). El motor (`HarfordDnDArea`) habilita el boton **"Repetir turno"** (`API.RepeatTurn`): avanza `session.turn` (ids frescos para que el receptor NO deduplique), reabre el marcado y re-aplica daño **sin volver a pagar el coste** (gate `session.committed`; `onCommit` solo en la 1a resolucion). Combinar con `autohit=true` si el daño no lleva tirada (Nube de Dagas) o con salvacion segun el conjuro. La duracion/fin la gestiona el usuario (Cancelar cierra la zona).
- Campo `condition` de conjuro (estructurado, opcional; con `autohit` son los DOS campos mecanicos no-texto): `spell.condition = "restrained"` o `{ id, duration, persist, turns }`. `id` DEBE existir en `HarfordDnDConditions.DEFS` (lo valida `SpellCondition`; ids invalidos se ignoran). `BuildAreaDefinition` lo anexa al `area`: por defecto una condicion de salvacion repite salvacion al final del turno del objetivo (`save_at_turn_end`), o `manual` (la retira el DM / al romperse / al recibir daño). Habilita **control puro sin daño**: el motor de area acepta `damageComponents` vacio si hay `conditionId` (`NormalizeDefinition`/`ValidateIncomingRequest`) y la red lo transmite vacio (`HarfordSync`: componentes "" -> {}). Solo mapear conjuros cuyo efecto coincida EXACTAMENTE con una condicion del catalogo y verificar UNO A UNO (falsos positivos tipicos: conjuros que RETIRAN estados, efectos sobre el lanzador, ralentizaciones de zona sin salvacion). Auditar con el clasificador de `/harforddebug` o replicando los parsers.
- El panel `Master` de `HarfordCompendioUI` es solo informativo mientras viva en core, pero aun asi se abre exclusivamente con `HarfordAuthority.CanUseDMTools()` (HarfordAdmin cargado + `.ph dm`). No usar `C_Epsilon.IsDM`/`ARC.PHASE.IsDM` directamente aqui. Si en el futuro obtiene botones que ejecuten cambios reales de DM (descansos forzados, preparacion ajena, auditoria aplicada, etc.), esas acciones deben moverse a `HarfordAdmin` o pasar por APIs core validadas con la misma puerta.
- **Estado de datos del Compendio (2026-08-20)**: `HarfordCompendio.lua` conserva texto completo en unidades metricas y requiere una auditoria OCR controlada por entradas. Ya se han corregido errores que afectan a dados de dano (`ldlO` -> `1d10`, `ldl2` -> `1d12`) en los conjuros detectados, pero siguen existiendo cabeceras de pagina y fragmentos OCR en otras descripciones; no declarar la pasada cerrada hasta completar el barrido comparado con la fuente canonica. `respirar_bajo_el_agua` traia incrustado el conjuro completo `Restablecimiento mayor` y se recorto; **`Restablecimiento mayor` NO existe aun como entrada propia** (solo `restablecimiento_menor`) y queda pendiente de alta con datos canonicos. Antes de editar descripciones, comprobar `ldl`, `PITULO`, `JUROS`, `PARTE N | HECHIZOS` y cabeceras corruptas; preservar los cambios validos de formato y no hacer sustituciones globales ciegas.
- **Auditoria de mecanizacion del Compendio (2026-08-21)**: 384 conjuros, niveles 0-4 (nv0 55, nv1 91, nv2 97, nv3 80, nv4 61); **no hay ningun conjuro de nivel 5-9** aunque `HarfordDnDMana` reparte espacios hasta nivel 9 (lanzador 9 ya crea espacios de nivel 5), asi que un lanzador de nivel de personaje 9+ se queda sin nada que lanzar en sus espacios altos. Estado de resolucion: 179 con campo `attack`, 95 con `savingThrow`, 157 con `damage`, y **181 puramente informativos** (se anuncian, no los resuelve ningun motor). Cosas confirmadas que faltan y por que:
  - **Concentracion declarada vs escrita**: 62 conjuros llevan la concentracion en el texto de `duration` ("Concentracion, hasta 1 minuto") con `concentration = false`, y otros 7 al reves (`concentration = true` con `duration = "manual"`). Se resuelve en el CORE con `HarfordCompendioAPI.RequiresConcentration(spell)` (campo booleano O texto de duracion), que es lo que usan `ConfirmCast` y la UI de detalle/tooltip. **No arreglar esto en `HarfordCompendio.lua`**: ese fichero lo regenera el pipeline del codice desde otro chat y el arreglo se perderia.
  - **`duration = "manual"` en 19 entradas** (`encantar_animal`, `grasa`, `hechizar_persona`, `encantar_persona`, `golpe_trueno`, `rayo_de_enfermedad`, `temblor_de_tierra`, `fuerza_brillante`, `patron_hipnotico`, `tormenta_de_aguanieve`, `pua_terrestre`, `dominar_bestia`, `encantar_monstruo`, `lanza_psiquica_de_raulothim`, `pirotecnia`, `amigos_rapidos`, `golpe_cegador`, `ola_de_marea`, `sueno_profundo`) es un marcador de relleno, no una duracion. Es dato, lo decide el chat del codice.
  - **Campo `attack` sobrecargado**: mezcla cuatro cosas distintas — tipo de ataque real (`Ataque de conjuro a distancia`), copia de la salvacion (`Salvacion de Destreza`, `Contra salvacion`), etiqueta de categoria (`Area`, `Aura`, `Invocacion`, `Proteccion`, `Mejora de ataque`) y ataque+dano fundidos (`A distancia 1d8 fuego`). El core lo tolera por `find` de subcadenas, pero las cinco etiquetas de categoria no resuelven a nada y caen en informativo.
  - **24 conjuros con `damage` y sin ataque ni salvacion**, que el motor no puede aplicar. No son un solo problema: (a) **riders de dano de arma** (`favor_divino`, `marca_del_cazador`, `favor_aterrador`, `maldicion`, `manto_del_cruzado_caido`) cuyo sitio correcto es `conditionalWeaponDamage` de `HarfordDnDConditionalDamage`, no el motor de area; (b) **dano reactivo / PG temporales** (`armadura_de_agathys`, `escudo_de_fuego`, `escudo_de_relampagos`, `bloque_de_hielo`, `absorber_elementos`, `discurso_motivador`, `barrera_luminosa`), que necesitan una capa de reaccion que aun no existe; (c) **dos errores de dato reales**: `bendicion` (`damage = "1d4 y"`) y `perdicion` (`damage = "1d4 y"`) NO hacen dano — son bonus/penalizador de 1d4 a tiradas —, y `rociada_de_color` (`damage = "2d10 por"`) tampoco: ciega por total de PG. Si alguna vez se les diera via de aplicacion, harian dano inventado.
  - **Escalado de trucos (RESUELTO en codigo)**: el dano de un truco sube un dado a nivel de PERSONAJE 5, 11 y 17. Es regla general del manual, no dato por conjuro, asi que la aplica `ApplyCantripScaling` en `HarfordCompendioCore` sobre los componentes ya parseados, usando `HarfordDnDProgression.GetTotalLevel()`. Cubre los 31 trucos con dano, incluidos los 7 que no lo declaran en su texto (`mordedura_helada`, `retumbo`, `llamada_de_relampago`, `palabra_de_radiancia`, `salvajismo_primitivo`, `hoja_retumbante`, `hoja_verdeante`). **Excepcion**: los trucos que escalan sumando PROYECTILES en vez de dados (Descarga Sobrenatural: de un rayo a cuatro, cada uno 1d10) se detectan por texto (`CantripScalesByProjectiles`) y se dejan intactos, porque multiplicarles el dado los doblaria. El numero de rayos en si sigue sin automatizarse. `ApplyUpcastDamage` (espacios superiores) solo escala lo que el texto declara: 72 de los 126 conjuros de nivel 1-4 con dano no traen la formula.
  - **Modificador de lanzamiento en curaciones**: el texto lo escribe de cinco formas distintas (`modificador de conjuro` 16 usos, `por aptitud magica` 4, `de lanzamiento de conjuros` 3, `de aptitud magica` 1) y `HealingDefinition` solo reconocia una, asi que curaciones como `cadena_de_curacion` sanaban los dados SIN modificador. Ahora se reconocen todas via `MentionsCastingModifier`. La puerta de texto `recuper` NO se relaja a `cura`: `restablecimiento_menor` (cura enfermedades) se convertiria en curacion falsa.
  - **`"Picaro Sutileza"` aparece como valor de `classes`** en 20 conjuros; es una subclase, no una clase, y los filtros de la pestana Conjuros derivan sus opciones directamente de esos valores, asi que sale como una clase mas en el desplegable.
  - **Nombres duplicados por diseno**: `explosion_arcana`/`explosion_arcana_nivel_3` y `toque_helado`/`toque_helado_nivel_1` comparten nombre visible; en la lista no hay forma de distinguirlos salvo por el nivel.
  - Diagnostico en juego: `/harford debug run compendio` (resumen) y `compendio pendientes` (listado de los que declaran dano sin via de aplicacion).
- **Web publica canonica** (<https://harfordweb.marcos-pazos-95.workers.dev/>, mantenida por el usuario en otro arbol): sus datos viven en `js/compendium-data.js` (classes/races/backgrounds/spells), `compendium-dotes.js`, `compendium-equipment.js` y `compendium-professions.js` (`window.HARFORD_COMPENDIUM`). Para la tanda actual, la web es la fuente de contenido de clases, subclases, razas, trasfondos y conjuros; el addon no debe sobrescribirla mediante publicaciones automaticas. Antes de incorporar datos, cotejar texto, niveles, efectos e iconos con `RuleSource/Rulebooks/` y corregir OCR/artefactos en la fuente adecuada. Alcance confirmado: nivel de personaje 1-6 y conjuros 0-4. Las dotes, profesiones y equipo conservan sus propios flujos de cotejo hasta que se acuerde su migracion. La importacion para la creacion automatica de fichas es trabajo en curso: no afirmar paridad web/addon ni activar una sincronizacion automatica hasta validarla en juego.

Coste y cobertura de conjuros:

- `HarfordConfig.spell_cost_mode` es global: `mana` (predeterminado) o `slots`. En `slots`, `HarfordDnDMana` es la unica fuente de maximos y gasto, y `HarfordDnDProgression.spellSlots` solo persiste los espacios gastados por nivel; el descanso largo los reinicia. No reintroducir el antiguo flag por perfil `useMana` ni tablas de coste paralelas.
- Ataques de conjuro simples y salvaciones con daño pasan por `HarfordDnDArea`, con CA/salvación/mitigación calculada por el defensor. Si un ataque requiere además una salvación contra una condición (ej. Rayo de Enfermedad), conserva el ataque inicial y el receptor resuelve `conditionApplySaveAbility/DC` antes de aplicar la condición. No auto-resolver múltiples proyectiles, explosiones por fases, daño recurrente ni riders de ataque de arma: necesitan resolvedor propio para no falsear objetivos, impactos o costes.

Contrato `HarfordEpsilonCommands`:

- `HarfordEpsilonCommands.Send(command, opts)`: puerta compartida para comandos servidor.
- Si `opts.callback` existe, usa `EpsilonLib.AddonCommands` para recibir `success/messages`.
- Si no hay callback, usa `ARC.CMD` / `ARC.COMM` para comandos fire-and-forget cuando este disponible.
- Puede usar `EpsilonLib.AddonCommands` como fallback si `ARC` no esta disponible.
- `HarfordEpsilonCommands.SendChain(commands, callback, opts)` usa `EpsilonLib.AddonCommands.SendChain`.
- `HarfordEpsilonCommands.GetStatus(addonName)` devuelve disponibilidad de `EpsilonLib`, registro AddonCommands y `ARC`.
- Usar `opts.addonName = "HarfordAdmin"` para comandos iniciados por la capa admin.
- Nunca ejecutar texto arbitrario recibido de otros clientes como comando servidor.

Contrato `HarfordCommandTemplates`:

- Vive en `Harford/Server/HarfordCommandTemplates.lua`. Solo datos: plantillas literales sin punto inicial.
- Exporta plantillas como campos de tabla: `AURA_SELF`, `AURA_TARGET`, `UNAURA_SELF`, `UNAURA_TARGET`, `NPC_SET_AURA`, `NPC_SET_UNAURA`, `NPC_EMOTE`, `NPC_EMOTE_REPEAT`, `NPC_SET_HEALTH`, `MOD_ANIM`, `ADD_ITEM`, `PH_F_N_FAC`, `PHASE_INFO`, `UNPOSS`, `POSS`.
- Convencion de placeholders: `{id}`, `{sign}`, `{amount}`, `{qty}`, `{factionId}`. El sufijo `_SELF` indica `self`, `_TARGET` indica sin sufijo (unit seleccionado).
- `HarfordCommandTemplates.Build(template, args) -> string | nil, err`: interpola `{clave}` con `args[clave]`; si falta un placeholder devuelve `nil` + mensaje. No envia el comando, solo construye el string.
- Toda nueva accion servidor debe pasar por este modulo en lugar de concatenar strings con `..` dispersos por el codigo.

Modularizacion de `HarfordDnD.lua` (refactor de descarga de chunk):

- `HarfordDnD.lua` rozaba el limite de 200 locales de Lua 5.1. Se extrajeron datos, calculo puro, red, tiradas y fabricas UI a modulos `HarfordDnD*` para bajar de 194 a ~139 locales de file-scope. Verificar con `grep -c "^local " Harford/DnD/UI/HarfordDnD.lua`.
- Deuda tecnica vigente: `HarfordDnD.lua`, `HarfordCharacterPanel.lua` y `HarfordUnitFrames.lua` siguen altos de locals/lineas. Funcionalidad nueva grande debe ir a modulos auxiliares antes que crecer esos chunks.
- **Barra de experiencia (arte y geometria)**: el envoltorio de la barra de XP es **UN solo atlas OVERLAY** del tamano exacto de la barra, que se estira al ancho que tenga — `hud-MainMenuBar-experiencebar-large-single` (804) / `-small-single` (550), altura nativa 14, y vive en las regiones del PROPIO gestor, no en la barra. La barra nativa son CUATRO capas y no una, con estos tintes exactos (sonda leida cargando el SavedVariable con `dofile`, no con regex): carril `Interface\TargetingFrame\UI-StatusBar` en `BACKGROUND:1` tintado `0.50,0.44,0.28`; relleno **la misma** `UI-StatusBar` en `BORDER:0` tintado `0.58,0.00,0.55`; La sonda muestra ademas una capa `XPBarAnim-OrangeGain` en `ARTWORK:-1` a alpha 1 tintada `0.90,0.80,0.60`, pero **NO reproducirla**: los `XPBarAnim-*` son las texturas de la ANIMACION de ganancia de XP (las demas aparecen en la captura a alpha 0, en reposo) y copiarla cubre la barra de AMARILLO, tanto en BLEND como en ADD. Comprobado en juego apagandola con `xpcapas tono off`. Leccion: una sonda captura un ESTADO, no solo arte fijo; una capa de animacion a alpha 1 en la captura no es parte del skin. **El relleno NO es la textura `1098846`**: ese id salio de una extraccion con regex mal acotada sobre la sonda y pintaba la barra de ROJO. Para leer una sonda, cargarla con `dofile` y recorrer el arbol; no rascarla con expresiones regulares. **NO son piezas por secciones ni caps encadenados**: montarlo con los caps de `UI-Character-ReputationBar` (62x21 + 42x21 de las filas de reputacion) los renderiza ROTOS a tamano pequeno, como dos trozos rojos en los extremos. Confirmado con `/harford debug run probeframe StatusTrackingBarManager`. `HarfordCharacterXP.SkinBar(bar, framed)` es la fuente UNICA del arte y la usan las dos barras: la del gestor nativo y la fina del panel de personaje; `framed` anade el envoltorio (con guarda `C_Texture.GetAtlasInfo`, sin ruta inventada) y usa el relleno nativo. El atlas ya dibuja el carril vacio, asi que **no hace falta pintar un fondo propio para que la barra se vea a 0 XP**; sin el, un fondo negro al 55% sobre el panel negro la deja invisible. La barra de abajo NO la dibuja Harford: `CreateManagedBar` se cuelga de `StatusTrackingBarManager` con `StatusTrackingBarTemplate` y el envoltorio lo pone la plantilla nativa. `HarfordCharacterXP.Refresh()` repinta tambien la barra del panel, pero **solo si `HarfordCharacterPanelFrame` esta visible** (`Panel.Refresh()` es un repintado completo). Diagnostico: `xp <cantidad>` / `xp = <total>`, `xpbar` (barras del gestor) y `xpbarpanel <y> [ancho] [alto] [x]` (la del panel; no confundir los dos ultimos: `RegisterCommand` indexa por clave y un nombre repetido PISA al anterior).
- **XP y nivel son independientes, y la XP manda hacia arriba**: el nivel de personaje SOLO cambia por el asistente de subida, nunca solo. La XP puede ir POR DELANTE del nivel y ese desfase es justo lo que enciende `PendingLevelUp` (aviso de subida disponible); mientras tanto el personaje sigue siendo del nivel anterior **para todo menos para la XP**, cuya barra ya cuenta en el tramo del nivel siguiente porque `Progress()` deriva de `LevelForXP(xp)`, no del nivel de clases. En sentido contrario hay TRES operaciones distintas y no se deben confundir: (1) `SyncToCharacterLevel(reason)` es SOLO SUELO — `xp = max(xp, XP_TABLE[nivelTotal])`, asi que tras subir de nivel la XP sobrante se conserva y puede seguir por delante; la usa el asistente de subida. (2) `ClampToCharacterLevel(reason)` ACOTA AL TRAMO — suelo y ademas techo en `XP_TABLE[nivel+1] - 1` (en nivel maximo no hay techo); la usa `/harford cargarficha`, donde la ficha cargada manda sobre el nivel: si traias XP de mas te deja en ese nivel con la barra llena menos 1, nunca con una subida pendiente que la ficha no contempla. (3) `ResetXP(reason)` pone la XP a 0 y la llama `HarfordCharacterCreation.Apply` junto al resto de reinicios explicitos (profesiones), para que la XP del personaje anterior no se cuele en el nuevo; las subidas encadenadas a nivel 2 y 3 la vuelven a poner en su umbral. El suelo se aplica al terminar cada subida en `HarfordCharacterAdvancement` (incluidas las encadenadas por la creacion via `S.autoLevelTarget`), y en `/harford cargarficha` (`LoadPlayerSheetFromTRP3`, paso 5b antes de `EnsureDefaults`). La creacion en si no necesita gancho porque termina en nivel 1 y `XP_TABLE[1] = 0`. Sin esto, un PJ creado o cargado a nivel 3 se quedaba con 0 XP y la barra decia "Nivel 1 - 0/300".
- **Geometria de la vista `Ficha` del panel**: la barra de XP cae POR DEBAJO de la banda del numero de nivel (que acaba en -71), asi que la seccion de `Caracteristicas` ya no puede estar en el -70 historico. `S.ABIL_BAR_Y` (-80) es el valor unico del que se derivan las filas de caracteristica (`abilY - 37`, la regla del panel: barra - 40 de alto + 3), la barra de `Rasgos` (`-206 + delta`) y el `featScroll` (`-243 + delta`), de modo que mover la seccion mueve el bloque entero. Vive en la tabla de estado `S` y NO como local de fichero: `HarfordCharacterPanel.lua` va por ~190 de los 200 locals de Lua 5.1. Ajuste en vivo con `/harford debug run seccioncaract <y>`.
- Contrato `HarfordCharacterBook` (`Harford/Character/HarfordCharacterBook.lua`): logica PURA de clasificacion/presentacion del Libro extraida de `HarfordCharacterPanel`, sin estado del panel (`S`). Carga en `Harford.toc` ANTES que `HarfordCharacterPanel`, que la consume via alias locales (`BookCategory`, `BookCategoryLabel`, `IsMagicLikeFeature`, `IsVisibleBookFeature`, etc.). API: `ICON`, `CondDamageId`, `IsEnergyManeuver`, `Category` (pasivo/activo/reaccion/al_accion/maniobra), `CAT_LABEL`/`CAT_COLOR`/`CategoryLabel`, `REACTION_TRIGGER_TEXT`/`ReactionTrigger`/`ReactionEffect`, `IsMagicLike`, `IsVisible` (filtra marcadores de subclase) y `BuildSections(progression)` (General + por clase/subclase; el panel le pasa `GetProgression()`). La UI del Libro (`RefreshBook`/`CreateBookPage`/botones/reacciones) sigue en el panel por su acoplamiento a `S`. No reintroducir estos clasificadores como locales del panel.
- **Un rasgo agotado no hace nada, y eso se comprueba UNA VEZ en el repartidor.** El guardia de
  usos vivia dentro de `AnnounceAbility`, que se llama al FINAL: `ApplyPowerWordGrant` concedia el
  recurso y despues avisaba de que no quedaban usos, asi que la Reserva de ira daba sus puntos con
  el contador a cero -- y con ella cualquier rasgo con `grant` (Brebaje Fortificante, Efusion,
  Capturar Fragmento de Alma). Ahora `BookButtonOnClick` lo comprueba **antes de repartir a sus
  veinticinco ramas**: un guardia por rama es un guardia que alguien olvidara en la siguiente.
  **Dos excepciones, las dos a proposito**: `pasivo` (es un tooltip, no gasta nada) y `trap`
  (colocar la trampa y que se dispare son momentos distintos; si colocaste la ultima y luego salta,
  hay que poder resolverla con el contador ya a 0).
- Las pruebas no comprueban solo que el guardia EXISTA, sino que aparezca ANTES del efecto y antes
  de la primera rama: que estuviera puesto, pero tarde, es justo lo que hacia que esto pareciera
  correcto de un vistazo.
- **Norma de activacion del Libro (2026-08):** todo rasgo con `uses` propios se clasifica como `activo` salvo que sea una maniobra, dano condicional, forma, area, Palabra de Poder o reaccion con ruta mecanica propia. Al activarlo debe anunciarse por `HarfordDnDRolls.BroadcastAbility`, que genera el ChatLink TRP3 clicable, y gastar exactamente su uso. Las acciones especiales que reutilizan combate o curacion (p.ej. Mordida de Demonio y Segundo Aliento) tambien deben emitir ese anuncio antes de su resultado. Una reaccion solo queda preparada si Harford puede resolver de verdad su disparador y efecto localmente; si no, anuncia y gasta ahora para resolverla en mesa. Nunca restaurar una reaccion remota ficticia para repetir ataques: Barrera es manual.
- **Compatibilidad de reacciones antiguas:** `PREPATTACK` se conserva solo para que clientes previos no rompan el parser, pero `HarfordDnDCombat` lo ignora y no realiza consultas de red. La unica reaccion automatica vigente es una que pueda resolverse localmente despues de conocer el dano; el resto no altera una tirada que ya ocurrio.
- Contrato `HarfordCharacterSpellbook` (`Harford/Character/HarfordCharacterSpellbook.lua`): la **pestaña Conjuros** (UI tipo libro de hechizos poblada por `HarfordCompendioAPI`), extraida de `HarfordCharacterPanel`. A diferencia de `HarfordCharacterBook` (pura), esta es UI acoplada a `S`, asi que recibe sus dependencias por inyeccion: `HarfordCharacterPanel` llama `HarfordCharacterSpellbook.Init({ S, CreatePage, BookSideTabOnEnter, BOOK_PER_PAGE/ROWS/BTN/COL_X/ROW_Y0/ROW_PITCH/GENERAL_ICON })` antes de `CreateSpellsPage()`, y usa `HarfordCharacterSpellbook.RefreshSpells` como refresher. Lee `HarfordCharacterPanel._bookFrame`/`._tabSkin` (tabla global) directo. Expone `Init`, `CreateSpellsPage`, `RefreshSpells`. Su config de texturas es `SPELLS_SKIN` (independiente del Libro de Habilidades). Carga en `Harford.toc` antes que el panel. No devolver la UI de Conjuros al chunk del panel.
- Contrato `HarfordDnDContext` (`Harford/DnD/State/HarfordDnDContext.lua`): es la "bisagra" que desacopla los demas modulos del chunk principal.
  - `HarfordDnDContext.State`: tabla unica y estable = el antiguo `SheetContext` (contexto temporal de ficha NPC: active, overrides, rollName, rollColor, actions, kind, spellProficiencyBonus, armorClass, onAttackAnimation, onDamageRolled, ...). HarfordDnD.lua hace `local SheetContext = HarfordDnDContext.State` (misma referencia).
  - `HarfordDnDContext.Get(k, default)` / `Set(k, v)`: accesores ARC (los antiguos `ARCGET`/`ARCSET`). `Get` prioriza `State.overrides` y cae a `HarfordDnDStore.GetValue` (siempre en vivo). `Set` en contexto activo actualiza `State.overrides[k]` si esa clave existe (edicion efimera de ficha NPC, sin contaminar el perfil del jugador); fuera de contexto escribe en runtime durante hidratacion (`_G.HarfordDnDHydratingFromPersist`) o via `HarfordDnDStore.SetValue`. HarfordDnD.lua hace `local ARCGET = HarfordDnDContext.Get` / `local ARCSET = HarfordDnDContext.Set` (sin tocar sus call-sites).
  - **Aislamiento NPC**: `HarfordDnDCalc` NO consulta `HarfordDnDFeatureEffects` cuando `State.kind == "npc"`; las fichas NPC usan solo `overrides` + stat block TRP3 (habilidades/salvaciones explicitas, CA, PB de conjuro aproximado). Esto evita que pericias, clase, raza, equipo o recursos del jugador se filtren a un NPC (ej. Acrobacias de NPC no puede heredar Destreza/pericia del PJ que lo esta manejando).
  - **Sin sync-hook**: se eliminó el antiguo `SetSyncHook`/`SyncRuntimeProfileRef` (existía solo para refrescar un alias local `RuntimeProfile` en DnD). La única lectura del runtime usa `HarfordDnDStore.state.runtime` en vivo; no recrear ese alias ni el hook.
- Contrato `HarfordDnDStore` (`Harford/DnD/State/HarfordDnDStore.lua`): mantiene runtime completo pero compacta la persistencia. `SetValue` conserva siempre el valor en `state.runtime`, pero si el valor es default (`0`, `10`, `normal`, `Desarmado`, etc.) elimina esa clave del perfil persistido en vez de guardarla. `PrunePersistedProfiles()` limpia perfiles antiguos cargados desde SavedVariables y borra perfiles fantasma que queden vacios si no son el perfil activo. Esto evita que `EnsureDefaults` y los recursos derivados llenen `HarfordDnDPersistStore.profiles` con decenas de ceros. No guardar un default no cambia comportamiento: los `Get(..., default)` de la ficha siguen devolviendo el mismo valor. **Claves SOLO de runtime** (`RUNTIME_ONLY_KEYS` en HarfordDnDStore): `Versatil`, `Offhand`, `ModoTirada` (ventaja/desventaja de la tirada actual) y `ModArma` (legacy retirado). Son estado momentaneo, NO datos de ficha: `SetValue` los mantiene en `state.runtime` (funcionan en sesion) pero **nunca** los escribe en `profiles` (`IsDefaultProfileValue` devuelve `true` para ellas en cualquier valor) y `PruneProfileTable` limpia los que guardaron versiones previas. Tras `/reload` vuelven a su default. **`activeProfile` eliminado**: el perfil es SIEMPRE el personaje actual (`UnitName("player")`); ya no se persiste y los lectores/exportadores/importadores locales ya no lo consultan como fallback (solo quedan asignaciones a `nil` para limpiar SavedVariables antiguas). `PruneAuxStores` borra el valor heredado. **Poda de contadores y tablas auxiliares** (`PruneAuxStores`, dentro de `PrunePersistedProfiles`, ejecutada en login y en `svclean dnd/safe/all`): elimina entradas a 0 de `hitDice[perfil].spent` y `featureUses[perfil]`, sus tablas de perfil si quedan vacias, y las sub-tablas vacias de `equipment`/`classProgression`. Se ejecuta ANTES del barrido de `profiles` para que `HasRelatedProfileData` (que mantiene vivo un perfil con datos en hitDice/featureUses/equipment/classProgression) refleje el estado limpio y un perfil cuyo unico "dato" era cruft a 0 pase a ser borrable. **Origen del cruft cerrado**: `HarfordDnDHitDice`/`HarfordDnDFeatureUses` ahora separan lectura (`hitEntryRead`/`usesEntryRead`, NO crean tablas) de escritura, y `SetSpent`/`RegainOnLongRest` borran las entradas que vuelven a 0 (no persistir el default "sin gastar"). Antes, una simple LECTURA (`GetSpent`/`GetTracked`/render del panel) creaba `hitDice[perfil]={spent={}}` y `featureUses[perfil]={}` vacios persistidos para cada perfil consultado.
- `HarfordDnDStore.ToNumber(value, default)`: conversion numerica compartida; devuelve `tonumber(value)` o `default or 0`. `HarfordDnD`, `HarfordDnDCalc`, `HarfordDnDNet` y `HarfordDnDRolls` mantienen un alias local a esta funcion; no duplicar nuevos helpers `toN`.
- Contrato `HarfordDnDProfile` (`Harford/DnD/State/HarfordDnDProfile.lua`): aplica tablas de perfil/recursos sobre `HarfordDnDStore`. `SetHooks(ensureDefaults, refresh)` lo registra HarfordDnD.lua tras definir `EnsureDefaults`/`RefreshMainUI`. API: `Apply(tbl, name)` (perfil completo), `ApplyResourceConfig(tbl, name)`, `MergeProfFlags(tbl, name)`; empaquetan `HarfordDnDResources.ALL_KEYS/CurKey/MaxKey` + los hooks. Los wrappers triviales `EnsurePersist`/`LoadPersistToRuntime`/`SaveCurrentProfileToBank` ya NO existen: se llaman directos sobre `HarfordDnDStore`.
- Contrato `HarfordDnDUI` (`Harford/DnD/UI/HarfordDnDUI.lua`): constantes visuales y fabricas simples de la ficha. Exporta `TEX`, `SECTION_TEX`, `LAYOUT`, `SetFrameBackground`, `CreateSection`, `MakeButton`. No contiene estado de ficha ni accesores ARC. `MakeSignedEditBox` se queda en `HarfordDnD.lua` porque depende directamente de `ARCGET/ARCSET`.
- Contrato `HarfordDnDAttackUI` (`Harford/DnD/UI/HarfordDnDAttackUI.lua`): fabrica y conserva los controles visuales de la seccion Ataque en `HarfordDnDAttackUI.Controls` (arma, dano, versatil, offhand, dano condicional, animaciones, modo combate, ataques, iniciativa y movimiento). Recibe callbacks explicitos desde `HarfordDnD.lua`; no calcula tiradas, no consume recursos y no aplica dano. `ConfigureWeaponInfo`/`RefreshWeaponInfo` centralizan el render del arma equipada y sus controles; `RefreshActionButtons(enabled)` centraliza el estado de los tres botones que requieren objetivo. El tracker de movimiento instala `OnUpdate` solo mientras esta midiendo y lo elimina al detenerse; no dejar un script por-frame ocioso.
- Contrato `HarfordDnDCustomDamage` (`Harford/DnD/Engine/HarfordDnDCustomDamage.lua`): subsistema autocontenido de dano personalizado. API: `Parse(text)`, `Roll(expr, abilityKey, damageKey, maximizeDice, mitigationUnit)`, `Apply()`, `Open(applyUnit, ownerFrame)` y `Configure(ownerFrame)`. Acepta `XdY`, `dY`, bonus fijo y numero plano; usa `HarfordDamageMitigation`, emite con `HarfordDnDRolls` y aplica por `HarfordDnDCombat` a `target` o `focus`. `Configure` mantiene el puente historico `HarfordDnDStore.OpenCustomDamageFrame` y `HarfordDnDStore.customDamageFrame`; no duplicar otra ventana/parser en `HarfordDnD.lua`.
- Contrato `HarfordDnDConditionalDamage` (`Harford/DnD/Engine/HarfordDnDConditionalDamage.lua`): fuente unica para nivel seleccionado, nivel maximo, costes, validacion, consumo y escalado de `conditionalWeaponDamage`. API de reglas: `Configure`, `GetSelectedLevel`, `GetMaxLevel`, `GetCosts`, `GetCostText`, `CanPay`, `HasPayable`, `Spend`, `GetLeveled`; recibe por `Configure` solo los accesos a recurso actual/ajuste y no ejecuta ataques. `InstallUI(parent)` crea los menus de Ataque y Libro y publica los puentes historicos en `HarfordDnDStore` (`GetConditionalDamageList`, `ToggleConditionalDamage`, `OpenConditionalDamageMenu`, etc.); `ToggleAttackMenu(anchor)` abre el selector de la ficha. Ataque, Libro y render deben consultar esta API y no recrear calculos o dropdowns locales.
- Contrato `HarfordDnDRolls` (`Harford/DnD/Engine/HarfordDnDRolls.lua`): serializacion, recepcion visual y emision de tiradas. API publica: `GetDisplayName`, `Serialize`, `Deserialize`, `DisplayInChat`, `Broadcast`. Mantiene el formato historico de 10 campos separados por `^` en prefix `DND5EARC`, incluyendo `nameColor` en el campo 10. Los campos de texto se escapan de forma compatible (`%`, `^`, saltos de linea) para que nombres compuestos, links TRP3 o etiquetas raras no rompan el parser; `Deserialize` sigue aceptando mensajes antiguos sin escapes. `Broadcast` acepta overrides opcionales `player`/`nameColor` para tiradas que el motor resuelve en nombre de un NPC, usa `HarfordSync.BestChannel()`/`HarfordSync.Send(...)`, loguea por `HarfordDebug` si el envio falla o el payload se acerca al limite seguro, pinta la tirada local y reproduce el sound kit TRP3 `36629` solo en emision local real; `DisplayInChat` no reproduce sonido porque tambien se usa para tiradas recibidas.
- Contrato `HarfordIconCatalog` (`Harford/Compendium/HarfordIconCatalog.lua`): **fuente unica de todos los iconos de contenido**. Contiene los nombres de rasgo, `features[feature.id]`, `spells[spell.id]`, `subclasses[classId][subclassId]` y los iconos de presentacion que proceden de perfiles de referencia. No crear ni mantener tablas de iconos en otros modulos. No usar etiquetas, coincidencias por categoria, iconos inferidos ni campos `verified`: si un rasgo no tiene una asignacion exacta de fuente, su UI muestra el fallback neutro `INV_Misc_QuestionMark` hasta que se añada al catalogo. Nunca consultar SavedVariables de TRP3 en caliente para rellenarlo.
- Contrato `HarfordDnDData` (`Harford/DnD/Data/HarfordDnDData.lua`): solo datos. `HarfordDnDData.ABIL` (6 caracteristicas, `{key, short, desc, saveDesc}`) y `HarfordDnDData.SKILLS` (18 habilidades, `{name, ability, id, desc}`). Se referencian como `HarfordDnDData.ABIL`/`.SKILLS` (no aliases locales). **`desc`/`saveDesc`/`desc` son la fuente UNICA de descripciones de caracteristica/salvacion/habilidad** para los tooltips del panel (`HarfordCharacterPanel` deriva `ABILITY_TOOLTIP_TEXT` de `ABIL[].desc`; las vistas Habilidades/Salvaciones leen `skill.desc`/`abil.saveDesc`). No duplicar estos textos en otros modulos. `ICONS`, `PRESENTATION` y `SUBCLASS_ICONS` son datos estaticos de presentacion y fallback: se preparan desde perfiles TRP3 de referencia durante desarrollo, pero nunca se consulta `totalRP3_Data.lua` ni otro SavedVariable en caliente. El Libro usa `PRESENTATION` primero, despues `ICONS` y, finalmente, su icono generico; las pestañas de subclase usan `GetSubclassIcon`.
- Contrato `HarfordDnDBook` (`Harford/DnD/Data/HarfordDnDBook.lua`): libro hardcodeado de clases/subclases/rasgos. Solo datos y helpers puros (`GetClasses`, `GetClass`, `GetSubclass`, `GetUnlockedFeatures`, `FindClassIdByText`). Los rasgos exponen `effects` declarativos; nunca contienen Lua ejecutable. **Sistema: World of Warcraft D&D 5ª Edicion (homebrew español)** — fuente prioritaria: `RuleSource/Rulebooks/Warcraft 5º Edición.txt`; el PDF `RuleSource/Rulebooks/Warcraft 5º Edición_compressed.pdf` queda como referencia visual. Las 12 clases son las de WoW: Caballero de la Muerte, Cazador de Demonios, Druida, Cazador, Mago, Monje, Paladin, Sacerdote, Picaro, Chaman, Brujo, Guerrero (cada una con 3 especializaciones como subclases). **No quedan vestigios de las clases D&D de relleno.** El libro contiene los rasgos de nivel 1–6, pero su estado de mecanizacion se audita por lotes: no tratar una entrada del libro como mecanica solo por existir. Automatizado donde aplica: estilos de combate (`armorClass`/`weaponAttack`/`weaponDamage`), ASI L4, pericias de clase/subclase (`skillExpertise`), competencias claras de arma (`weaponProf`, p.ej. Forajido pistolas/rifles y Chaman Mejora), y salvaciones por choice (`saveProf`: Druida Feral, Chaman Tierra). El resto (conjuros, recursos de clase, mecanicas complejas) va como `informativo`/`recurso` con su texto del manual hasta tener un disparador verificable. Las descripciones completas que consume la UI se extraen de esta fuente mediante `HarfordDnDBookText`; no sustituirlas por sinopsis locales. Helper local `ASI(classId, level)` para el rasgo de Mejora de Caracteristica (choice `ability+1` x2). Helper local `WeaponProfEffects(...)` para convertir competencias de armas claras a efectos declarativos sin repetir tablas largas.
  - **Choices (elecciones)**: un rasgo puede tener `type = "choice"` + `choice = { slots = N, options = {...} | optionsFrom = "ability+1"|"skillProf"|"skillExpertise" }`. Cada opcion es `{ id, label, effects = {...} }` (mismos efectos declarativos). `optionsFrom` genera las opciones desde datos: `ability+1` (cada caracteristica +1, para ASI), `skillProf`/`skillExpertise` (cada habilidad). Helpers: `GetChoiceOptions(feature)`, `GetChoiceOption(feature, optionId)`, `GetChoiceSlots(feature)`. Ejemplos en el libro: `fighter_fighting_style` (1 slot, opciones explicitas), `fighter_asi_4` (2 slots, `ability+1`; mismo slot repetido = +2 a una), `rogue_expertise` (2 slots, `skillExpertise`). Los rasgos `choice` estan activos por defecto (como `pasivo`/`recurso`).
  - **Regla: una eleccion se ELIGE, no se hereda.** Todo rasgo `choice` -- de clase, de raza o de
    trasfondo -- debe ofrecerse como seleccion tanto en la CREACION de personaje como en la SUBIDA
    de nivel, y una ficha no deberia darse por valida con elecciones pendientes.
    **Estado verificado 2026-08-23:** `HarfordCharacterAdvancement` SI las ofrece (resuelve por
    `HarfordDnDBook.GetChoiceOptions`). `HarfordCharacterCreation` NO: no referencia
    `GetChoiceOptions` ni escribe en `draft.choices`, solo MUESTRA las ya hechas (`ChoiceText`), y
    su validador `Apply` comprueba caracteristicas, subclase y nivel 1 pero no que falte elegir.
    Lo unico que se elige por opciones en la creacion es el equipo inicial. Quedan sin ofrecer las
    53 elecciones de raza y trasfondo (18 + 35) mas las de nivel 1 de clase.
    Falta el CONECTOR, no el resolvedor: `GetChoiceOptions` ya cubre los siete `optionsFrom` en
    uso (`ability+N`, `skillProf`, `skillExpertise`, `language`, `toolProf`, `artisanTool` y las
    `options` explicitas).
- Contrato `HarfordDnDRaces` (`Harford/DnD/Data/HarfordDnDRaces.lua`): libro hardcodeado de **razas** WoW (alianza/horda/aliada). Solo datos + helpers (`GetRaces`, `GetRace`, `GetRaceName`, `GetSubrace`, `GetDefaultSubraceId`, `GetRaceTraits`, `GetTrait`). Cada raza: `id`, `name`, `faction`, `size`, `speed`, `traits` (+ `subraces` opcional con sus `traits`). Los `traits` tienen el MISMO formato que los rasgos de clase (`id/name/type/description/effects/choice`) para reusar el motor: incrementos de caracteristica fijos → `effects {bonus ability}`; a eleccion → `choice` con `optionsFrom="ability+2"`/`"ability+1"`; competencias de habilidad → `skillProf`; competencias claras de arma → `weaponProf` con helper local `WeaponProfEffects(...)` (Enano, Kaldorei, Orco, Tauren, Trolls, opcion de armas de Elfo de Sangre y Goblin). `GetRaceTraits(raceId, subraceId)` devuelve los rasgos en el formato de `GetUnlockedFeatures` (`{className, level=0, feature}`). Integracion: `HarfordDnDProgression.GetUnlockedFeatures` **fusiona** rasgos raciales + de clase, asi que `HarfordDnDFeatureEffects` y la UI los tratan igual. La raza se guarda en `progression.race = {id, subraceId}` (`GetRace`/`SetRace`), viaja en `DNDCLASS` (seccion `r=raceId~subraceId`), y se elige en `HarfordCharacterPanel` > `Subida` con dropdowns Raza/Subraza. Contenido en curso (igual que clases): **Alianza completa** (Humano, Enano [3 subrazas], Elfo de la Noche, Gnomo [2 subrazas], Draenei [4 subrazas: Exodar/Forjado por la Luz/Tabido/Man'ari], Huargen) y **Horda completa** (Orco [3 clanes: Cazadores/Misticos/Guerreros], Renegado [2 subrazas: Humano/Elfo], Tauren [3 subrazas: Mulgore/Monte Alto/Taunka], Trol [4 subrazas: Jungla/Zandalari/Bosque/Hielo], Elfo de Sangre, Goblin [Pequeño, 7.5m]); **Aliadas completas** (todas del GMBinder): **Pandaren** (ASI Con+1/Sab+2, Gourmet=`toolProf` x2, Palma Temblorosa=`uses` 1/short; resto `informativo`), **Nocheterna** (ASI Des+1/Int+2, `skillProf` Arcano+Percepcion; Vision/Sensibilidad Solar/Proteccion Mental/Magia como `informativo`), **Elfo del Vacio** (`elfo_vacio`; ASI Des+2 + choice Int/Car+1, `skillProf` Percepcion, `resist` necrotico [Frio de la Noche], Grieta Espacial=`uses` 1/short, Legado Thalassiano=choice truco/`weaponProf`), **Vulpera** (Pequeño; ASI Des+2/Int+1, Conocimiento Nomada=choice `skillProf` Animales/Naturaleza/Sigilo/Supervivencia, Furia del Pequeño=`uses` 1/short; resto `informativo`). **16/16 razas del GMBinder implementadas.** Ademas **Semielfo** (faction `aliada`; rasgos Espiritu Mestizo/Vision/Conocimiento Arcano [`skillProf` Arcano + `uses` 1/long para Detectar magia]/Legado Elfico) y la subraza **Altonato** del Elfo de la Noche (Shen'dralar de Eldre'Thalas: "Conocimiento antiguo" = `skillProf` Arcano+Historia; Erudito arcano/Proteccion mental como `informativo`; su Vision Superior la cubre ya el rasgo base del Elfo de la Noche, no se duplica) y la subraza **Man'ari** del Draenei (Sab+2/Con+1; Resiliencia Vil = `resist` fuego; Presencia Retorcida = `skillProf` Intimidacion; Vision/Magia Vil como `informativo`; su Resistencia a las Sombras la cubre ya el Draenei base, no se duplica). `RACE_TEXT_ALIAS` mapea "elfo noble"/"alto elfo" -> `elfo_sangre` (Semielfo ya NO es alias, es raza propia). `optionsFrom` admite `ability+N` (generico). Choices raciales notables: Huargen "Conocimiento del Cazador" (skillProf de 5 a elegir), Gnomo Mecagnomo "Mejoras Mecanicas", Orco Misticos (incremento Int/Sab + "Conocimientos Misticos" skillProf de 4), Renegado Humano ("Versatilidad" skillProf + incremento `ability+1`), Trol de Bosque "Instintos Amani" (skillProf de 3), Elfo de Sangre "Legado Thalassiano" (truco/weaponProf si elige armas). Competencias de herramienta → `toolProf` (Ingenieria Gnomica/Goblin=artesano, Tallado de Gemas=joyero, Familiaridad Mecanica=armero). **Resistencias de daño PERMANENTES → `resist`** (Forjado en Llamas=fuego, Resistencia Sagrada=radiante, Resistencia a las Sombras=necrotico, Resistencia al Frio/Piel de Nacido del Hielo=frio, Naturaleza No-Muerta=veneno). **Daño condicional racial** → `conditionalWeaponDamage` (Orco Cazador "Ataque Sorpresa" = `{ id="surprise_attack", count=1, die=6 }`, toggle del dropdown de daño). **Critico salvaje** → `flag savageCritDie` (Orco Guerrero "Ataques Salvajes": en critico `RollWeaponDamage` tira un dado de arma extra). **Habilidades de uso limitado "X/descanso"** → campo `uses = { max=1, recharge="short"/"long" }` (contador en el tracker del panel, reset por descanso; el EFECTO sigue narrativo): Determinacion (humano/renegado), Forma de Piedra, Sangre de Fuego, Don de los Naaru, Presencia Heroica, Llamado Ancestral, Resistencia Implacable, Pisoton de Guerra, Tenacidad Rugosa, Berserker, Abrazo de los Loa, Reversion de Conjuros, Esquivar. **No convertir** (sin mecanica posible): ventajas situacionales en salvacion/prueba (no hay efecto "ventaja" pasiva), idiomas, vision en la oscuridad, armas naturales (Mordida/Cuernos — sin capa de arma natural), CA condicional, resistencias por reaccion, bonos de PG por nivel TOTAL (Dureza Enana/Resistencia — `resourceMax` solo escala por clase, no por nivel total; ademas la vida es sensible), competencia/pericia parcial situacional (Conocimiento de la Piedra/Artifice/Mejores Tratos), movimiento/tamaño/terreno y Regeneracion Troll (modifica la curacion por dado de golpe; candidata futura via flag). **Descripciones**: cada raza y cada subraza tiene un campo `desc` (1-2 frases, lore condensado del manual) que `HarfordCharacterPanel` muestra como tooltip nativo en los dropdowns de Raza/Subraza de `Subida` y en las filas Raza/Trasfondo de la vista `details` de la ficha (subraza tiene prioridad sobre raza). Fuente unica de la descripcion de raza; no reescribir en la UI.
- Contrato `HarfordDnDBackgrounds` (`Harford/DnD/Data/HarfordDnDBackgrounds.lua`): libro hardcodeado de **trasfondos** WoW. Solo datos + helpers (`GetBackgrounds`, `GetBackground`, `GetBackgroundOrder`, `GetBackgroundName`, `GetBackgroundTraits`, `GetTrait`). Cada trasfondo: `id`, `name`, `traits` (sin subrazas, mismo formato de feature que clases/razas: `id/name/type/description/effects`). Competencias en habilidades → `effects {skillProf}`; herramientas/idiomas/Caracteristica/Equipo → `informativo` con su texto; elecciones reales usan `choice` (p.ej. Cazarrecompensas urbano, Heredero, Miembro de organizacion). `GetBackgroundTraits(id)` devuelve `{ {className, level=0, feature }, ... }`. Integracion: `HarfordDnDProgression.GetUnlockedFeatures` **fusiona** rasgos raciales + de trasfondo + de clase. Se guarda en `progression.background = ""` (`GetBackground`/`SetBackground`), viaja en `DNDCLASS` (seccion `b=backgroundId`), y se elige en `HarfordCharacterPanel` > `Subida` con un dropdown Trasfondo (con opcion "Ninguno"). **Contenido actual: 50 trasfondos.** 4 Warcraft base (`boticario_oscuro`, `doble_agente`, `crianza_faccion`, `aprendiz_kirin_tor`), 13 PHB (`source="PHB"`), 1 SCAG (`cazarrecompensas_urbano`) y 32 de mesa/Discord Discrub (`source="Harford"`), incluidos `acolito_luz_abisal`, `adepto_cosecha_oscura`, `agente_principe_mercante`, `anima_errante`, `bucanero_retirado`, `buscador_sombrio`, `caballero_orden`, `cruzado_argenta`, `desertor_errante`, `eremita`, `feriante_luna_negra`, `forastero`, `forjador_torio`, `guardian_salvaje`, `guardia_ciudad`, `heredero`, `miembro_organizacion`, `miembro_anillo_tierra`, `miembro_tribal`, `novato_liga_expedicionarios`, `operativo_ravenholdt`, `protector_cenarion`, `superviviente_catastrofe`, `eco_resurreccion`, `senda_sangre_barro`, ademas de los propios previos (Capitan Veterano Harford, El Loco, Mercenario veterano, Exiliado de Alterac, Rostro olvidado, Coneja elemental, Veterano del campo de batalla). Texto en ASCII salvo datos historicos ya existentes; mantener estilo compacto.
- Regla de fuente para trasfondos: la ficha TRP3 actua como **indice** (`Trasfondo X`); `HarfordDnDBackgrounds` es el **guardian del saber** (descripcion, rasgos y efectos). `HarfordTRP3.ParsePlayerSheet` captura tambien el primer parrafo del bloque de trasfondo, pero `HarfordDnDProgression` solo lo persiste en `backgroundDesc` si `X` NO existe en el libro. Si existe, se limpia la desc TRP3 y el panel usa `bgDef.desc`/rasgos del addon. `FindBackgroundIdByText` soporta `aliases`; tras importar exports de Discord/Discrub se añadieron aliases defensivos para titulos sin tildes o mutilados (`ac_lito`, `charlat_n`, `agente_de_pr_ncipe_mercante`, etc.). **Contenido de `desc`**: 22 trasfondos llevan ya la prosa completa del export de Discord (la escribe tal cual el frame "Trasfondo" del About en `HarfordCharacterCreation`). Se excluyen a proposito los **catalogos de opciones** que traia el export (parrafos `- <Nombre>. ...` que enumeran companias mercenarias, regiones de origen, organizaciones): son tablas de eleccion de creacion, no la descripcion de UN personaje, y volcarlas al About meteria un catalogo entero en el perfil. Por el mismo motivo se descartan los parrafos que solo remiten a esas listas ("...a continuacion", "tabla siguiente") y se acota cada desc a ~1800 caracteres. Los trasfondos PHB estandar siguen SIN `desc` a proposito: su contenido vive en `traits` y duplicarlo como desc lo repetiria en el About.
- `Devoto de Elune` es un trasfondo Harford: mecaniza Medicina, Religion y Kit de herborista. El idioma elegido, equipo y `Luz Sanadora` permanecen informativos/narrativos; no otorgar ventaja ni curacion automatica fuera de una regla con disparador verificable.
- Contrato `HarfordDnDFeats` (`Harford/DnD/Data/HarfordDnDFeats.lua`): libro hardcodeado de **dotes** (Cap. 5 Personalizacion). Solo datos + helpers (`GetFeats`, `GetFeat`, `GetFeatOrder`, `GetFeatName`, `GetFeatTraits`, `GetTrait`). Cada dote: `id`, `name`, `requires` (texto descriptivo, NO se valida — el DM decide), `traits` (mismo formato de feature; los `choice` de incremento usan opciones explicitas de las caracteristicas permitidas via helper local `AbilOpt`, no `optionsFrom`). Automatizado: incrementos fijos → `bonus ability`; "X o Y +1" → `choice` con opciones; competencias → `skillProf`; Prodigio competencia/pericia a elegir → `choice` con `optionsFrom="skillProf"`/`"skillExpertise"`; Agilidad Robusta Acrobacias/Atletismo → `choice`. Lo no automatizable (velocidad +1.5m, CA especial de Resistencia Tauren, PG max, conjuros, rerolls) → `informativo`. `GetFeatTraits(featIds)` recibe una LISTA de ids (un PJ puede tener varias dotes) y devuelve `{ {className="Dote: Nombre", level=0, feature}, ... }`. Las dotes se guardan en `progression.feats = {}` (lista) via `GetFeats`/`HasFeat`/`SetFeatEnabled`, viajan en `DNDCLASS` (seccion `d=`, ids por `~`) y se eligen en `HarfordCharacterPanel` > `Subida` con un dropdown **multi-seleccion** (checkboxes, `keepShownOnClick`); el texto muestra el conteo ("Dotes (N)"). **Contenido: 75 dotes.** 18 del manual Warcraft (4 especiales + 14 raciales). 42 del **Manual del Jugador (PHB 5e ES)** con `source="PHB"` (Acechador, Actor, Afortunado, Alerta [iniciativa +5 automatizada], Atleta, Resiliente [choice con bonus+saveProf por caracteristica], Habilidoso [choice skillProf x3], etc.). 15 de **El Caldero para Todo de Tasha (TCoE 5e ES)** con `source="TCoE"` (Iniciado Artificiero, Cocinero, Triturador, Adepto Sobrenatural, Tocado por las Hadas, Iniciado en el Combate, Tirador/Armas de Fuego, Adepto de la Metamagia, Perforador, Envenenador, Tocado por las Sombras, Experto en Habilidades [choice ability+1 + skillProf + skillExpertise], Cortador, Telequinetico, Telepata). Los incrementos "X o Y +1" usan `choice` con opciones explicitas; el resto de beneficios va en una trait `informativo` "Beneficios". Xanathar no aporta dotes; SCAG esta escaneado. **Las dotes con `choice` (incrementos a elegir, pericias) renderizan sus selectores en la lista de rasgos automaticamente, igual que clases/razas.**
- Contrato `HarfordDnDMana` (`Harford/DnD/State/HarfordDnDMana.lua`): regla adicional de **Maná** (Parte 3 Reglas Variantes). Solo datos + calculo puro; NO crea recurso ni toca UI. `API.COST` (coste por nivel de espacio 1..9: 2/3/5/6/7/9/10/11/13), `API.BY_LEVEL` (Maná por Nivel de lanzador 1..20: `{mana, maxSpell}`). Helpers: `GetSpellCost(n)`, `GetCasterLevel(profile)`, `GetManaPool(profile)`, `GetMaxSpellLevel(profile)`, `IsEnabled(profile)`. **Tipo de lanzador** (`classDef.casterType` en `HarfordDnDBook`): completos (nivel completo) = druida/mago/sacerdote/chaman/brujo; mitad (`math.ceil(nivel/2)`, **redondeado ARRIBA** por decision de mesa: nivel 1 ya aporta lanzador 1 = 3 mana, nivel 2 = 1, nivel 3 = 2 = 6 mana) = caballero_muerte/paladin y **druida con subclase `feral`** (override en el modulo); no-lanzadores = sin mana (`casterType` ausente). En multiclase suma las aportaciones por clase (cada medio lanzador redondea su mitad por separado antes de sumar; acotado 0..20). **Activacion global**: `HarfordConfig.spell_cost_mode` selecciona `mana` (predeterminado) o `slots`; no existe toggle por perfil ni campo `useMana`/`m=` en `DNDCLASS`. La fila "Mana" y el recurso `mana` solo aparecen para lanzadores cuando el modo global es `mana`; con `slots`, `HarfordDnDMana` conserva el calculo de maximos y gasto de espacios en `HarfordDnDProgression.spellSlots`. Cuando esta activo, `HarfordDnDFeatureEffects.Resolve` suma `GetManaPool` como `resourceMax.mana`, asi el pool se refleja en el **recurso "mana" existente** (`GetResourceMax` = base manual + pool) sin crear recurso nuevo.
- Costes de habilidades que gastan espacio/mana o recursos: los efectos `conditionalWeaponDamage` pueden declarar `spellLevelCost = "level"` para elegir nivel de espacio (coste via `HarfordDnDMana.GetSpellCost(level)`) o `resourceCost` + `costPerLevel` para recursos como `runic_power`. La seccion Ataque muestra una opcion por nivel disponible, deshabilita lo impagable y guarda el nivel elegido en `HarfordDnDStore.condDamageLevel`. **Los recursos se descuentan SOLO al consumir el dano en `RollWeaponDamage`, que se invoca desde el impacto confirmado; si el ataque falla no se gasta mana/poder runico.** **El coste de RANURA (`spellLevelCost`) solo se cobra como `mana` cuando el modo global `spell_cost_mode` es `mana` (`HarfordDnDMana.IsEnabled`)**: con `slots`, el espacio se gasta mediante `HarfordDnDMana.SpendSpellSlot`, no hay recurso de mana que descontar y el nivel queda limitado por los espacios disponibles. Sin este gate, un paladin sin mana no tenia recurso y TODOS los niveles del selector salian deshabilitados. Ejemplos actuales: Paladin `Golpe del Cruzado` (`smite`) elige nivel de espacio/mana y escala dados; Caballero de la Muerte `Golpe Runico` (`runic_strike`) cuesta Poder runico por nivel, escala dados por nivel elegido, se limita por Mod. Carisma y en Escarcha cambia de d6 necrotico a d8 frio. No hardcodear costes por nombre de rasgo.
- Caballero de la Muerte: `Poder Runico` es solo el rasgo/recurso informativo que crea el maximo de `runic_power`; NO debe abrir dropdown ni declarar dano. `Golpe Runico` es el rasgo activable separado con `conditionalWeaponDamage id="runic_strike"` y el selector por dados/coste. `Espiral de la Muerte` es una `maniobra` con `energyManeuver`: gasta Poder Runico, tira salvacion de Constitucion contra CD de conjuro y aplica dano necrotico solo si falla.
- **Layout de SavedVariables por perfil (anidado)**: todo lo de una ficha vive bajo `HarfordDnDPersistStore.profiles[name]`: las claves PLANAS de recursos/caracteristicas/flags (`Res_*`, `Fuerza`, etc.) y CUATRO sub-tablas estructuradas reservadas: `_progression` (clases/raza/trasfondo/choices/dotes), `_equipment` (equipo virtual por slot), `_hitDice` (`{spent={[caras]=n}}`) y `_featureUses` (`{[featureId]=gastados}`). Las antiguas tablas top-level keyed-por-nombre (`HarfordDnDPersistStore.classProgression/equipment/hitDice/featureUses`) **fueron retiradas**; `HarfordDnDStore.MigrateNestedIntoProfiles(persist)` las migra a `profiles[name]._x` (idempotente, corre al cargar via `PrunePersistedProfiles`) y deja las top-level a `nil`. **CRITICO — `ApplyProfileTable` (recepcion de ficha/import) RECONSTRUYE el perfil plano desde los recursos entrantes**: PRESERVA explicitamente las cuatro sub-tablas del perfil anterior y las re-anexa solo a PERSIST; `state.runtime` queda PLANO (sin sub-tablas, copiado ANTES de re-anexar). No volcar sub-tablas como texto (el rebuild filtra `type(v) ~= "table"`). `PruneProfileTable` retira sub-tablas vacias y nunca trata una sub-tabla como valor plano; `HasRelatedProfileData` mira `profiles[name]._x` para no borrar perfiles con progresion/equipo. Las claves reservadas se centralizan en `HarfordDnDStore.NESTED_PROFILE_KEYS`.
- Contrato `HarfordDnDProgression` (`Harford/DnD/State/HarfordDnDProgression.lua`): estado por perfil en `HarfordDnDPersistStore.profiles[name]._progression` (antes top-level `classProgression`; migrado automaticamente), sin SavedVariable nueva. Schema: `classLevels`, `featureStates`, `choices`, `race`, `background`, `feats`, `schema`. API: `Get`, `SetClassEntry`, `RemoveClassEntry`, `SetFeatureEnabled`, `IsFeatureEnabled`, `GetRace`/`SetRace`, `GetBackground`/`SetBackground`, `GetFeats`/`HasFeat`/`SetFeatEnabled`, `GetUnlockedFeatures`, `GetTotalLevel`, `GetProficiencyBonus`, `SeedFromTRP3`, `Export`, `Import`. `SeedFromTRP3` no debe inflar una unica clase con el nivel total: primero usa `HarfordTRP3.GetProfileClassEntries(profile)` y carga cada linea del About con formato `Clase Subclase (nivel)` como entrada independiente de multiclase (ej. `Picaro Forajido (3)` + `Paladin (6)` -> dos `classLevels`). Si una linea no declara subclase y el nivel aun no llega al nivel de eleccion de esa clase, `subclassId` queda vacio; si ya llega o supera el nivel de subclase, usa la subclase por defecto como placeholder editable en `Subida`. `SetClassEntry(..., subclassId=nil, ...)` sigue significando "elige default"; `subclassId=""` significa "sin subclase todavia". `GetUnlockedFeatures` fusiona en orden: rasgos raciales → de trasfondo → de dotes → de clase/subclase. `featureStates` es estado interno para resolver que aplicar; **no se expone como checkbox general de usuario**. La UI solo debe pedir decision cuando el rasgo declare `choice`. Los pasivos/recursos/choices desbloqueados por nivel se consideran activos por defecto salvo override interno en `featureStates`; condicionales/acciones pueden seguir controlados por codigo interno si alguna feature futura lo necesita.
- Import TRP3 de choices: `LoadFromTRP3Replace` resuelve elecciones declaradas en la misma linea del rasgo o en la linea inmediatamente siguiente (ej. `Pericia` -> `Acrobacias | Sigilo`, `Adaptacion Salvaje` -> `Destreza`). Si una linea contiene varias opciones y el rasgo tiene varios slots, debe llenar todos los slots detectados. No inferir elecciones de caracteristica/ASI desde puntuaciones finales: los atributos ya vienen horneados en el About y aplicarlos duplicaria bonus. Tampoco forzar subraza por defecto al importar TRP3: si el texto dice solo `Elfo de la Noche`, `subraceId` queda vacio; solo se fija `altonato`/otra subraza si el About la nombra explicitamente.
- Semilla TRP3 y recursos derivados: el calculo de maximos de recurso de clase (por ejemplo `Ira` de Guerrero) usa `HarfordDnDBook` -> `HarfordDnDFeatureEffects.resourceMax`. `/harford cargarficha` sigue siendo el unico flujo destructivo que importa TRP3 y **inicializa** currents al maximo/valor inicial; durante esa carga `HarfordDnDStore.suspendDerivedResourceReconcile` evita refrescos intermedios. Fuera de esa carga, los setters de `HarfordDnDProgression` llaman `HarfordDnDStore.ReconcileDerivedResources(profileName, reason)` para el **perfil local actual**: recalcula `Res_*_Max`, crea el current inicial solo si el maximo anterior era 0, clampa currents que superen el nuevo maximo y conserva currents reales a 0. Si el perfil no es el jugador local, la reconciliacion no toca recursos propios. `Harford.toc` declara `OptionalDeps: totalRP3, totalRP3_Extended`. El antiguo hook `TRP3_API.events.WORKFLOW_ON_FINISH` que sembraba/emitia recursos al terminar el workflow **fue retirado** (causaba aparicion automatica de barras al abrir ficha/cambiar target): la ficha ya no se auto-rellena desde TRP3. No reintroducir auto-siembra ni timers/reintentos para esto.
- Persistencia de recursos derivados: no guardar `Res_*_Max` cuando el maximo viene de rasgos/clase/equipo; ese maximo se recalcula. `HarfordDnD.lua` ya NO materializa `Res_*_Cur` ausentes al maximo durante refresh/sync/login: un current ausente se interpreta como 0 y un current guardado a 0 con maximo > 0 se conserva porque es estado real de combate (especialmente vida a 0). `EnsureDerivedResourceCurrentsPersisted` solo clampa currents existentes que superen el maximo. `ReconcileDerivedResources` solo inicializa recursos nuevos al activar progresion local (maximo anterior 0 -> nuevo maximo > 0); no rellena recursos existentes cada refresh.
- Estados activables de rasgos: `HarfordDnDProgression` tambien guarda `activeStates` por perfil. API: `IsToggleStateActive(stateId)`, `SetToggleState(stateId, enabled)` y `GetActiveStates()`. Estos estados solo existen si un rasgo declara un efecto `toggleState`; NO son checkboxes genericos de todos los rasgos. Viajan en `DNDCLASS` seccion `s=` como ids activos (`~`-separados). La UI de `Subida` muestra un bloque "Estados activables" solo cuando hay estados declarados, para casos como transformado/postura/metamorfosis/lobo solitario.
- Contrato `HarfordDnDItems` (`Harford/DnD/State/HarfordDnDItems.lua`): equipo virtual de ficha, no equipo real del personaje WoW. Guarda por slot `itemLink/itemId` y seleccion basica opcional (`basicWeaponKey`/`basicArmorKey`) en `HarfordDnDPersistStore.profiles[name]._equipment` (antes top-level `equipment[profileName]`; migrado automaticamente — ver "Layout de SavedVariables por perfil"). API principal: `GetSlot`, `GetEquipment`, `SetEquipment`, `EquipSlot`, `UnequipSlot`, `SetBasicWeapon`, `GetBasicWeapon`, `SetBasicArmor`, `GetBasicArmor`, `GetBasicWeapons`, `GetBasicArmors`, `ResolveItem`, `ResolveSlot`, `GetEquippedBonuses`, `GetEquippedWeapon`, `GetEquippedArmorClass`, `GetDescriptionLines`, `GetParsedRules`. Resuelve con `GetItemInfo`, `GetItemStats`, `GetItemIcon`, `GetDetailedItemLevelInfo`; si falta cache, guarda link/id y reintenta en `GET_ITEM_INFO_RECEIVED`. Los objetos custom de Epsilon se tratan como objetos normales del juego: Harford conserva link/icono/tooltip nativo, incluida descripcion custom. **Prioridad fija**: objeto equipado reconocido > seleccion basica > fallback de ficha; si el objeto equipado existe pero aun no esta cacheado o no se reconoce como arma/armadura, se mantiene el fallback de ficha para no romper la tirada. **Parser de descripcion**: se escanea un `GameTooltip` oculto con `SetHyperlink`; las lineas narrativas quedan en `descriptionLines` y solo se aplican mecanicas si la linea completa coincide con una etiqueta conocida + numero/dados, por ejemplo `Naturaleza +1`, `Fuerza +2`, `Salvacion Destreza +1`, `CA +1`, `Armadura 14`, `Ataque +1`, `Dano +1`, `Ataque conjuro +1`, `CD conjuro +1`, `Dano extra 1d6 fuego` o `Dano adicional 1d4 necrotico`. No interpretar texto libre fuera de este formato. **Tipo de arma, dados base, tipo de dano y propiedades NO salen de la descripcion**: se derivan de la **subclase WoW** (`itemSubClass` de `GetItemInfo`) mapeada a un arma base D&D via `WEAPON_SUBCLASS_TO_KEY` -> `HarfordDnDWeapons.WEAPONS` (el dano real del item WoW se ignora; se usan los dados D&D). Como WoW no distingue tanto como D&D (todas las espadas de una mano = "Espada larga"), el tipo se puede indicar de **multiples formas** y se detecta robustamente: (1) **declaracion explicita** con prefijo `Arma: <nombre>` / `Tipo de arma: <nombre>` (en `ParseTooltipRules`, consume y oculta esa linea); (2) **`DetectWeaponKey`** (en `ResolveFromClient`, si no hubo prefijo) busca el nombre de arma como **FRASE COMPLETA con limite de palabra** (via `NormalizePhrase`, que conserva espacios) en el **nombre del item + lineas de descripcion**, eligiendo la coincidencia **mas larga/especifica**. Asi detecta `Espada corta +1`, una linea suelta `Espada corta`, o el tipo **embebido** en texto mas largo (`Gran espada corta rota`, `Una hacha de batalla maldita`), **sin** falsos positivos por limite de palabra (`Espada cortante` NO casa `Espada corta`; `Mazazo` NO casa `Maza`). Ignora `Desarmado`. Un nombre propio sin tipo (`Mordefilo`) no casa -> cae a la subclase WoW. `FindWeaponKeyByName` (match exacto normalizado sin espacios) se usa solo para el prefijo explicito. Si coincide por cualquier via, `rules.weaponOverride` **manda sobre la subclase** (incluso permite que un item que WoW no clasifica como arma se trate como tal). El patron `Arma:` no colisiona con `Armadura:`. Solo de la descripcion salen los **modificadores adicionales** (ataque/dano/dados extra/caracteristica/etc.), nunca el arma base. **Bonus automatico por calidad/rareza** (`QUALITY_BONUS`, sin necesidad de texto en la descripcion): Verde/Infrecuente (quality 2) = +1, Azul/Raro (3) = +2, Morado/Epico (4) = +3, Naranja/Legendario (5) = +4 (comun/pobre = sin bonus). La calidad se toma del **color del itemLink** (`QualityFromLink`/`LINK_COLOR_QUALITY`) con fallback a `GetItemInfo`, porque los items custom de Epsilon a veces devuelven en `GetItemInfo` una rareza distinta a la que muestra el color del enlace. En **armas** se suma a `rules.weaponAttack` y `rules.weaponDamage`; en **armadura/escudo** a `rules.armorClass` (un +1 escudo da +1 CA, no golpe). Se evalua escudo/armadura antes que arma. `resolved.qualityBonus` guarda el valor. Como el resto de bonos de equipo, fluye por `GetEquippedBonuses` -> bucket live de `HarfordDnDFeatureEffects` (es decir, el bonus de ataque/dano de arma es global a las tiradas de arma mientras este equipado, no estrictamente por-arma). `HarfordCharacterPanel` permite arrastrar item a cualquier slot PaperDoll, click derecho o Alt+click para quitar solo el objeto equipado, tooltip real con `GameTooltip:SetHyperlink`, y flecha en `MainHand`/`SecondaryHand`/`Chest` para elegir arma/armadura basica. Los bonuses de caracteristica detectados por `GetItemStats` o descripcion entran al bucket live de `HarfordDnDFeatureEffects.GetBonus("ability")`; los de habilidad/salvacion/ataque/dano/CA/conjuro entran a sus buckets equivalentes. Los dados extra del objeto se agregan a la tirada de daño del arma y se maximizan en critico. Armadura/escudo son CA base alternativa en `HarfordDnDCombat` (`max(CA manual, CA equipo) + bonuses`), nunca suma directa. **Armadura basica = set completo D&D 5e** (`BASIC_ARMOR`, nombres nivel20): ligeras (Acolchada 11, Cuero 11, Cuero tachonado 12), medias (Pieles 12, Camisa de malla 13, Coraza 14, Cota de escamas 14, Media armadura 15), pesadas (Cota guarnecida 14, Cota de malla 16, Armadura de bandas 17, Armadura de placas 18), mas "Sin armadura" (10) y escudo (+2). Cada entrada lleva `cat` (`ligera`/`media`/`pesada`/`ninguna`) y `caText`. `GetEquippedArmorClass` suma **Destreza por categoria** (`ArmorDexBonus`: ligera/ninguna = Des completa; media = min(Des,2); pesada = 0) usando `HarfordDnDCalc.GetAbilityMod("Destreza")` del contexto activo (en inspeccion es aproximado: la CA manual del snapshot suele ganar). La CA explicita de un item (`rules.armorBase`, ej. "Armadura 14") se toma como final, sin sumar Destreza. Los items WoW se mapean a categoria via `ARMOR_KIND_CAT` (cloth/leather=ligera, mail=media, plate=pesada). Nota: las claves viejas (`cloth/leather/mail/plate`) cambiaron a las nuevas; selecciones de armadura basica guardadas con el set viejo deben re-elegirse. `MainHand` reconocido o basico alimenta el arma activa de ficha jugador; si `Offhand` esta activo intenta usar `SecondaryHand`; modo NPC ignora equipo del jugador. Las tiradas de ataque/daño de un arma de objeto usan el `itemLink` como nombre de arma para que el chat muestre el link clicable; armas basicas/manuales siguen usando `key`. `DNDEQUIP` sincroniza itemLink y selecciones basicas con formato por campos (`i:`, `w:`, `a:`) manteniendo compatibilidad con payloads viejos de solo itemLink (los `:`/`|` del link se escapan con `EscapeProgressionText`, parseo seguro). Diagnostico: `/harford debug run itemrules MainHand` imprime reglas parseadas y lineas descriptivas. **Rendimiento**: `ResolveItem(itemLink, forceResolve)` cachea tambien los items `pending`; las lecturas normales devuelven el cacheado SIN re-escanear el tooltip (antes era O(lecturas)). Solo `RefreshPending` (evento `GET_ITEM_INFO_RECEIVED`) fuerza re-resolucion con `forceResolve=true`. **Inspeccion**: `SetInspectData`/`ClearInspectData` + helper interno `ReadProfile` (prefiere el override efimero de inspeccion sobre la persistencia en las funciones de LECTURA; las de escritura siguen en `EnsureProfile`). **Menu de armas basicas**: la mano secundaria (`SecondaryHand`) filtra las armas con propiedad "Dos manos". `EQUIP_LOC_TO_SLOT` queda reservado (andamiaje de auto-slot al soltar, no eliminar).
- **Menu de armadura basica**: `HarfordDnDItems.GetArmorMenuGroups()` es la fuente del selector de `Chest`; mantiene `Sin armadura` en la raiz y agrupa el resto en `Armaduras ligeras`, `Armaduras medias` y `Armaduras pesadas`, con las opciones concretas en submenus. No volver a construir una lista plana en `HarfordCharacterPanel`.
- **Lecturas de equipo sin cruft**: `HarfordDnDItems.ReadProfile` NO debe crear `profiles[name]` ni `_equipment`; devuelve la cache efimera de inspeccion, el `_equipment` existente o una tabla vacia compartida de solo lectura. Solo `EnsureProfile`/`ProfileSlot` pueden crear persistencia y solo desde escrituras (`EquipSlot`, `SetBasicWeapon`, `SetBasicArmor`, `SetEquipment`, `UnequipSlot`). Esto evita que abrir paneles, calcular CA o sincronizar equipo cree perfiles vacios en SavedVariables.
- Contrato `HarfordCharacterInspect` (`Harford/Character/HarfordCharacterInspect.lua`): inspeccion ligera y **read-only de verdad** del panel de otro jugador. **No escribe en persistencia** (`HarfordDnDPersistStore`). `Request(unitOrName)` envia `DNDINSREQ` por whisper; el receptor responde con `DNDINSBASE` (solo `ProfileKeys.DnDBase`), `DNDRES`, y los **opcodes especificos de inspeccion `DNDINSCLASS`/`DNDINSEQUIP`** (con chunks `DNDINSCLASSC`/`DNDINSEQUIPC`). Estos opcodes son **distintos** de los de sync normal (`DNDCLASS`/`DNDEQUIP`) justo para poder distinguir inspeccion de "Enviar ficha": el receptor los consume en `HarfordCharacterInspect.HandleAddonMessage` (que corre ANTES que el import en `HarfordDnDComm`) y solo llama `NoteProgression`/`NoteEquipment`. Esos `Note*` guardan la progresion/equipo en una **caché EFIMERA** dentro de los propios modulos: `HarfordDnDProgression.SetInspectData(name, data)` y `HarfordDnDItems.SetInspectData(name, data)` (keyed por nombre **corto**), que `HarfordDnDProgression.Get`/`HarfordDnDItems.ReadProfile` prefieren sobre la persistencia. Asi el panel pinta progresion/equipo del inspeccionado **sin contaminar** `classProgression`/`equipment` locales. `HarfordSync.Deserialize*` devuelve un 3er valor `isInspect`; `HarfordDnDComm` lo respeta como defensa (si el modulo de inspeccion no estuviera cargado, nunca importa datos de inspeccion). **Defensa de cache**: `DNDINSBASE`/`DNDRES` usado por inspect/`DNDINSCLASS*`/`DNDINSEQUIP*` solo se aceptan en `HarfordCharacterInspect` si hay una peticion reciente que encaje con el `sender` o el `profileName`; snapshots no solicitados se ignoran para evitar caches fantasma. El `DNDRES` normal sigue alimentando `HarfordDnDResources.RemoteCache`, pero no crea snapshot de inspect por si solo. El panel abre con `OpenInspect(unitOrName)` o `/harford inspect`; en ese modo `GetProfileName()` apunta al perfil remoto, lee base/recursos de `HarfordCharacterInspect.Cache`/`HarfordDnDResources.RemoteCache`, desactiva pestanas editables y bloquea drag/drop/unequip. Al salir de inspeccion (`API.Open`) o cambiar de objetivo (`OpenInspect`) se llama `HarfordCharacterInspect.ClearInspectStores()` → `ClearInspectData()` en ambos modulos (descarta el snapshot efimero). **Consentimiento + throttle**: `API.AllowRequests` (default `true`) gobierna si se responde a `DNDINSREQ`, con throttle de 5 s por solicitante (`CanServe`). **Limitacion**: items custom de Epsilon viajan como `itemLink`; si el cliente que inspecciona no los tiene cacheados, `GetItemInfo` no resuelve y el slot/tooltip queda vacio (igual que los links TRP3). **Nota de diseño**: el sync NORMAL de ficha (`DNDCLASS`/`DNDEQUIP`) sigue importando a persistencia keyed por nombre, lo que acumula progresion/equipo de otros jugadores; migrar ese render a cache efimera tambien queda como mejora futura.
- Ataque de jugador y equipo: la seccion `Ataque` de `HarfordDnD.lua` **no usa** la seleccion legacy `ArmaSeleccionada` ni los modificadores ocultos `ModArma`/`ModIniciativa`. El arma activa sale de `HarfordDnDItems.GetEquippedWeapon("MainHand")` o, si `Offhand` esta activo, de `SecondaryHand`; si no hay item/arma basica, cae a `Desarmado`. Un escudo item equipado en `SecondaryHand` se convierte a la definicion basica `Escudo` para que `Offhand` pueda mostrarlo/atacar con el. Los bonos de arma/iniciativa vienen de `HarfordDnDFeatureEffects` (items/rasgos), no de campos manuales ocultos.
- Semilla TRP3 de progresion: `HarfordTRP3.GetProfileClassEntries(profile)` lee multiclase desde el About; `GetProfileRaceEntry(profile)` lee campos estructurados TRP3 (`RA`/`Raza`/`race`) y lineas claras `Raza:`/`Subraza:`; `GetProfileBackgroundId(profile)` lee campos estructurados (`BG`/`Trasfondo`/`background`) y lineas claras `Trasfondo:`/`Origen:`. Los buscadores viven en `HarfordDnDRaces.FindRaceIdByText`/`FindSubraceIdByText` y `HarfordDnDBackgrounds.FindBackgroundIdByText`. Si una raza/trasfondo no existe en el libro, se guarda el texto raw como valor visual (sin rasgos automaticos). `HarfordDnDProgression.SeedFromTRP3(profileName)` rellena **por campo** y no pisa datos ya configurados: importa clases solo si no hay `classLevels`, raza solo si `race.id` esta vacio y trasfondo solo si `background` esta vacio. **Ya NO se llama automaticamente** (ni desde `HarfordCharacterPanel.RefreshPanel`, ni desde `Refresh`, ni desde un hook de workflow): la carga TRP3 es exclusiva de `/harford cargarficha` (ver abajo). `SeedFromTRP3` solo se usa hoy desde el diagnostico `trp3build`. No hacer deteccion vaga sobre descripciones largas: solo etiquetas claras del About/campos TRP3. Diagnostico en juego: `/harford debug on` + `/harford debug run trp3build`.
- **Carga destructiva de ficha desde TRP3 (`/harford cargarficha`)**: a diferencia de la semilla NO destructiva de arriba, este comando **reemplaza la ficha completa** del jugador con los datos de su perfil TRP3 (seccion About SIEMPRE). Cadena: `HarfordTRP3.ParsePlayerSheet(profile)` -> `HarfordDnDProgression.LoadFromTRP3Replace(sheet, profileName)` -> hornear caracteristicas y recursos en SavedVariables. `ParsePlayerSheet` devuelve `{ classes (via ClassEntriesFromAbout, desambiguado por `classicon_<key>` -> CLASS_ICON_TO_HARFORD, genero-proof), abilities (claves Fuerza/Destreza/Constitucion/Inteligencia/Sabiduria/Carisma), weapons (lista de texto de lineas `Arma(s)`/`- arma` con dados), armorDesc (solo la PRIMERA linea `Armadura`), hasShield, raceId, subraceId, raceRaw, background, backgroundRaw }`. Usa `NormAccents` correcto en UTF-8 (secuencias de 2 bytes `\195[...]` -> letra; NO gsub de clase de bytes, que duplica acentos). Validado contra los 14 perfiles reales. **Genero**: `HarfordDnDBook.FindClassIdByText`/`FindSubclassIdByText` y `HarfordDnDRaces.FindRaceIdByText`/`FindSubraceIdByText` prueban una variante **masculinizada** (`Masculinize` + GENDER_ALIAS para irregulares: sacerdotisa->sacerdote, semielfa->semielfo; 'a' final->'o' por palabra excluyendo GENDER_STOP la/las/de/del/el/los/a/y/en) **solo como fallback** tras fallar el match original (preserva nombres canonicos en -a como Escarcha/Ira/Sutileza). Asi "Maga"/"Bruja"/"Elfa de la Noche" resuelven clase/raza y cargan sus rasgos. **Elecciones (choice) desde el About**: `LoadFromTRP3Replace` llama a `ResolveChoicesFromAbout(profileName, sheet.aboutLines)` tras fijar clases/raza/trasfondo. Para cada rasgo `choice` desbloqueado, busca la LINEA del About que contiene el NOMBRE del rasgo (ej. "Estilo de Combate") y tambien la linea inmediatamente siguiente. Para choices con `options` explicitas matchea una o varias opciones (segun slots), probando tanto el `id` normalizado (`gran_arma`->"gran arma") como el nombre del `label` (porque el About puede escribirlo distinto al libro: "Gran Arma" vs label "Gran Lucha con Armas"), ordenadas por aparicion. Para `optionsFrom="skillProf"`/`"skillExpertise"` usa los pools de habilidades/pericias detectados en la ficha. NO inferir ASI/incrementos de caracteristica desde puntuaciones finales: ya vienen horneadas del About. Asi el estilo de combate (Defensa/Duelo/Gran Arma/Dos Armas...) se aplica al cargar (antes quedaba sin elegir -> su efecto no se aplicaba). El scope por-linea evita falsos positivos (p.ej. un conjuro "Proteccion" en otra linea). `sheet.aboutLines` (lineas sin markup) lo expone `ParsePlayerSheet`. **Dotes desde el About**: `ResolveFeatsFromAbout` resuelve las dotes: el perfil las marca "Dote <Nombre>" (cabecera con `{col}Dote{/col} <Nombre>`, normalmente en la seccion de raza); por cada linea con "dote" busca el nombre de dote del libro mas largo presente y la activa via `SetFeatEnabled` (`HarfordDnDFeats` carga antes que Progression en el .toc). `LoadFromTRP3Replace` resetea `data.feats={}` antes. Tener una dote a nivel 4 implica que NO se uso la Mejora de Caracteristica: esa choice ASI (`optionsFrom`) queda sin resolver a proposito (las puntuaciones ya vienen horneadas del About, no se re-aplican). Validado: Kijava (Humano) -> dote `centinela`. **Cabeceras sueltas**: ademas del marcador (`Estilo de combate X`/`Dote X`), tanto choices como dotes se detectan si una linea ES EXACTAMENTE el nombre de la opcion/dote (h2 sin prefijo: "Gran Arma" -> estilo gran_arma; "Gran Maestro de Armas" -> dote, esta solo si el nombre es multipalabra para evitar falsos positivos). Igualdad exacta = sin falsos positivos (validado en los 14 perfiles). **Alias de raza** (`RACE_TEXT_ALIAS` en `HarfordDnDRaces`): razas sin entrada propia en el libro que comparten rasgos con una existente se mapean por texto: `semielfo`/`semielfa`/`semi elfo`, `elfo noble`, `alto elfo` -> `elfo_sangre` (sin'dorei). Compiten en el mismo "match mas largo" de `FindRaceIdByText`, asi que no pisan a "Elfo de la Noche" ni a nombres mas especificos. **Bug corregido (normalizacion de acentos)**: las funciones `Normalize` de `HarfordDnDBook`/`HarfordDnDRaces`/`HarfordDnDBackgrounds` y `NormalizeBuildText` de `HarfordTRP3` usaban clases de bytes `gsub("[áàäâ]","a")` que en UTF-8 **corrompen** los caracteres multibyte (la "o" de "Restauracion" se partia en "ao"; "Chaman"->"chamaan"). Eso hacia que subclases/razas/trasfondos ACENTUADOS no casaran y la subclase cayera al default (p.ej. Chaman "Restauracion" se cargaba como "Elemental", arrastrando recursos de subclase erroneos como `maelstrom`). Arreglado con normalizacion UTF-8 byte-segura: `HarfordDnDBook.Normalize` usa `UTF8_ACCENT_MAP` + `gsub("\\195.", map)` para que `Represion` con/sin acento case como id canonico `represion`; `Reprension` y `Retribucion` quedan como alias legacy; `HarfordTRP3.NormAccents` mantiene el mismo objetivo para el parser. NO reintroducir clases de bytes para acentos en ningun normalizador. **Unificado**: todos los normalizadores (`HarfordClassColors.NormalizeKey`, `HarfordDnDFeatureEffects.NormDamageKey`, `HarfordCharacterPanel`, `HarfordDnDBook`, `HarfordDamageMitigation`, `HarfordDnDBackgrounds`, `HarfordDnDRaces`, `HarfordTRP3`, etc.) delegan ya en `HarfordClassColors.StripAccents(value)` (byte-segura, mapa `\195.` envuelto en parentesis para evitar el multi-retorno de `gsub`; carga en `.toc` antes que todos los consumidores). Cada uno conserva su `:lower()`/trim propio. **Pitfall multi-retorno de `gsub`**: un normalizador que termina en `return value:gsub(...):gsub(...)` devuelve DOS valores (string + nº de sustituciones). Si ese retorno se usa como ULTIMO elemento de un constructor de tabla o lista de argumentos, el contador numerico se cuela como elemento extra (paso: `{ Norm(a), Norm(b) }` -> `{strA, strB, count}`, y un `ipairs` posterior tropezaba con `#numero`). Caso real: crash al cargar Ellie en `ResolveChoicesFromAbout`. `HarfordDnDProgression.NormalizeText` ahora asigna y devuelve UN solo valor; al envolver cualquier `Norm()` como ultimo elemento, parentizarlo o asignarlo antes.
- **Calculo de vida y recursos al cargar (hornear en SV)**: `HarfordDnDProgression.ComputeMaxHP(conMod, profileName)` aplica la formula del manual: PG nivel 1 = dado de golpe maximo de la PRIMERA clase + Mod.CON; cada nivel restante (incl. L1 de otras clases en multiclase) = floor(dado/2)+1 + Mod.CON; minimo 1. Verificado vs perfiles (Axus Guerrero(4) CON+3 = 40, Cody CdM(3) CON+4 = 34, Chloe Sacerdote(2) CON+2 = 14). `HarfordDnD.LoadPlayerSheetFromTRP3` (almacenado en `HarfordDnDStore.LoadPlayerSheetFromTRP3`) orquesta: parse -> LoadFromTRP3Replace -> ARCSET de las 6 caracteristicas -> `HarfordDnDItems.LoadBasicEquipmentFromSheet(sheet)` (mapea `armorDesc` a clave de `BASIC_ARMOR` por frase mas larga y cada arma a clave via `DetectWeaponKey`; armas custom sin match -> Desarmado; escudo si `hasShield`) -> `FeatureEffects.Invalidate` -> bucle `RESOURCE_ORDER` horneando `ComputeDerivedResourceMax(key)` (health=ComputeMaxHP, resto=GetResourceMaxBonus+mana) en `SetResourceMax` y currents al maximo -> EnsureDefaults/RefreshMainUI/ScheduleMyResourceBroadcast -> confirmacion en chat. **CA NO se lee del About**: solo se usa `armorDesc` para equipar armadura basica; el numero de CA sale de Other Information/equipo via `HarfordDnDCombat.ComputeSelfArmorClass` (sin cambios).
- **Profesiones en el About TRP3**: van como una linea mas de la seccion `Competencia`, detras del bloque de herramientas y separadas por una linea en blanco, con el rango como etiqueta gris (`- Herreria {col:cccccc}Aprendiz{/col}`). Solo el rango, sin el numero de skill. **No hay frame "Profesiones" propio**: lo hubo y se retiro (`BuildProfessionsFrame`), no recrearlo. Escribe `HarfordCharacterCreation.ProfessionProficiencyLines`; lee `MatchProfessionLine` en `HarfordDnDProgression`, que exige que el nombre case ENTERO (asi `Herramientas de herrero` sigue siendo herramienta y no la profesion `Herreria`) y convierte el rango a skill con `HarfordProfessions.GetTierMin` (sin rango = Aprendiz). **El About decide QUE profesiones tienes, el skill local decide CUANTO**: `ApplyImportedProfessions` recorre TODAS las profesiones; una nombrada se queda con `max(skill local, minimo del rango declarado)` (el rango es grueso — Aprendiz cubre 1..74 — asi que un "Aprendiz" no tira un 25 a 1, solo sube si vienes por debajo del escalon), y una ausente del About se BORRA (`SetSkill(id, 0)`, que guarda `nil`). Barrer todas es seguro porque el unico llamador aborta antes si no pudo leer el About, asi que una tabla vacia significa "no declara ninguna", no un fallo de parseo. **Se aplica EXCLUSIVAMENTE en `LoadFromTRP3Replace` (`/harford cargarficha`)**: no llamarlo desde `SetInspectDataFromTRP3Sheet` ni desde ninguna ruta de inspeccion, porque ese About es de OTRO jugador y sobrescribiria las profesiones propias con las suyas.
- **Etiqueta de fuente en `Competencia`**: `ImportGeneralProficiency` recorta la etiqueta final (`Trasfondo`, `Racial`, `Clase`, `Raza`, `Eleccion`) con `StripSourceTag`, reutilizando `LANGUAGE_SOURCE_TAGS`. Antes solo se recortaba en Idiomas, asi que se guardaba la competencia de arma como `de fuego trasfondo` y la herramienta como `Herramientas de cartografo Racial`, con la etiqueta pegada al nombre y visible en el tooltip de Competencias.
- **Arquitectura de recursos "solo SV" (cambio)**: tras este comando, `HarfordDnD.GetResourceMax(key)` lee el `Res_*_Max` PURO de SavedVariables (ya no suma el bonus derivado en vivo); `ComputeDerivedResourceMax(key)`/`SetResourceMax(key,value)` son los que calculan y hornean. `HarfordDnDNet.WrapDerivedMax` quedo como **passthrough** (devuelve `baseReader` sin sumar; el SV ya trae el valor horneado, sumar lo duplicaria). `HarfordDnDFeatureEffects.GetResourceMaxBonus` y `HarfordDnDMana` siguen existiendo pero **solo los usa el comando** al hornear. **Transicion**: un PJ que nunca ejecute el comando vera `Res_*_Max` = valor que ya tuviera en SV (las barras de recurso de clase no aparecen hasta ejecutar el comando); subir de nivel = re-ejecutar `/harford cargarficha`. Admin sigue ajustando current/max remotamente por `RADJ` (el MAX horneado es la fuente unica, intacto).
- **Dispatcher `/harford` (UNICA via)**: `SlashCmdList["HARFORDMAIN"]` enruta subcomandos: `cargarficha` (carga destructiva), `ficha`/`char`/`rep`/`turnos`/`config`/`inspect`/`debug`. Los comandos sueltos antiguos (`/FichaHarford`, `/hchar`, `/harfordrep`, `/turnos`/`/th`, `/hconfig`, `/hinspect`, `/harforddebug`/`/hdebug`) **fueron RETIRADOS**: se eliminaron sus globals `SLASH_*N` pero se **conserva la funcion en `SlashCmdList[clave]`** para que `route()` del dispatcher la invoque. No volver a registrar globals `SLASH_*` sueltos en los modulos; toda entrada de usuario pasa por `/harford`. `/harford` a secas (o subcomando desconocido / `help`) **solo imprime la lista** de subcomandos, NO abre la ficha (para abrirla: `/harford ficha`).
- **Carga TRP3 SOLO bajo demanda (no automatica)**: la siembra `HarfordDnDProgression.SeedFromTRP3` ya **no se llama** desde `_G.DND5E_ARC_API.Refresh`, ni desde un hook `TRP3_API.events.WORKFLOW_ON_FINISH` (ambos retirados), ni desde `HarfordCharacterPanel.RefreshPanel`. Abrir la ficha/panel o cambiar de target **no auto-rellena** clase/raza/trasfondo ni deriva recursos. La unica forma de traer datos del TRP3 a la ficha es `/harford cargarficha` (carga destructiva que hornea todo en SV). `SeedFromTRP3` sigue existiendo solo para el diagnostico `/harford debug trp3build`. Combinado con `GetResourceMax` = SV puro, un PJ sin ejecutar el comando no muestra barras de recurso de clase.
- **Modelo de 3 vias de carga de ficha (prioridad)**: los datos de la ficha pueden venir de 3 origenes, y el orden de prioridad determina cual gana cuando hay varios disponibles:
  1. **Envio directo ("Enviar ficha")**: datos enviados/cargados explicitamente por sync (`DND5EARC` resources/profile/`DNDCLASS` progresion). Es la fuente mas autoritativa.
  2. **TRP3** (fallback): si no hay envio directo, se siembra desde el perfil TRP3 (`SeedFromTRP3`, que rellena **solo campos vacios** y no pisa datos ya configurados).
  3. **Sistema de creacion/subida en el addon** (futuro): cuando exista, construira la ficha desde cero dentro del addon.
  - **Prioridad ACTUAL (de momento)**: 1 (Envio directo) > 2 (TRP3) > 3 (Creacion). El dia de mañana la prioridad se **invertira**: 3 (Creacion) > 2 (TRP3) > 1 (Envio directo).
  - **Implicacion para modificadores de caracteristica**: en las vias 1 (Envio) y 2 (TRP3) los incrementos de raza/trasfondo **ya vienen horneados** en la puntuacion → no se re-aplican en vivo (ver contrato `HarfordDnDFeatureEffects`, bucket `creationBonus.ability`). Solo la via 3 (Creacion) aplicara esos modificadores sobre la puntuacion base via `GetCreationAbilityBonus`.
- Rasgos visibles del panel: `HarfordCharacterPanel` muestra en `Rasgos destacables` primero rasgos de **clase/subclase** desbloqueados desde `HarfordDnDProgression`/`HarfordDnDBook`, filtrando entradas de magia/conjuros. `HarfordTRP3.GetProfileFeatureLines(profile, limit)` queda como fallback visual, acotado a secciones de clase del About y cortando al llegar a magia, ataque, habilidades, idiomas, equipo, etc. Estos textos son **solo visuales**, no efectos automaticos.
- `toggleState` / `requiresState` (primera prioridad de mecanizacion de clases): `HarfordDnDFeatureEffects` soporta rasgos que declaran un estado activable con `{ kind="toggleState", state="id", label="..." }` y efectos condicionados con `requiresState="id"`. Si el estado no esta activo en `HarfordDnDProgression.activeStates`, ese efecto condicionado no se aplica. Estados cableados ahora: `metamorphosis` (Cazador de Demonios: Puas Demoniacas concede resistencia fisica solo en Metamorfosis), `wild_shape` (Druida: Frenesi concede resistencia fisica y Ataque Adicional solo transformado) y `lone_wolf` (Cazador: Lobo Solitario activa ataque extra / critico 19 segun subclase). No usar `featureStates` como UI general: solo `toggleState` crea controles de usuario.
- **Iniciacion Illidari (Cazador de Demonios)**: usa el efecto declarativo `weaponFinesse` para tratar como Sutil cualquier arma cuerpo a cuerpo que no tenga `Pesada` ni `Dos manos`. El calculo comun de arma elige Fuerza o Destreza como con una arma Sutil, cubriendo gujas de guerra basicas, equipadas y resueltas desde objetos. Las ventajas por primer turno, rastreo o tipo de criatura permanecen situacionales: no se conceden de forma global sin un contexto verificable.
- **Lanzamiento Flexible (Mago) / Devocion (Sacerdote) -- puntos <-> espacios**: misma mecanica con distinto recurso (`mage_point` / `light_point`), asi que vive UNA sola vez en `HarfordDnDMana` (`SLOT_POINT_COST = {2,3,5,6,7}` para espacios de nivel 1-5, `GetCreatableSlots`, `GetConvertibleSlots`, `CreateSlotFromPoints`, `ConvertSlotToPoints`) y cada rasgo declara el suyo con `actionKind = "slotConversion"` + `slotConversion = { mode = "create"|"convert", resource = "..." }`. **Los espacios creados se CUENTAN**: van en `progression.spellSlotsBonus` (tabla aparte de `spellSlots`, que sigue siendo "gastados" y no negativo) y `GetSpellSlotMax` los suma, asi que aparecen en el libro de conjuros, en el compendio y en el coste al lanzar sin tocar ningun consumidor. `ResetSpellSlots` (descanso largo) limpia las DOS tablas, que es lo que dice el manual: los espacios creados desaparecen en el descanso largo. **Solo funciona en modo espacios**: si `HarfordDnDMana.IsEnabled()` (la mesa juega con mana) las dos rutas se rechazan con un motivo visible, nunca en silencio. Validaciones: no se crea por encima del nivel 5 ni por encima de tu nivel maximo de conjuro, no se crea sin puntos suficientes, y convertir un espacio no da puntos por encima del maximo del recurso (se rechaza en vez de tirarlos). El nivel se elige en un desplegable (`HarfordDnDStore.OpenSlotConversionMenu`), porque el coste y la ganancia dependen de el; va dentro de un `do...end` por el limite de 200 locales de `HarfordDnD.lua`.
- **Lanzador de TERCIO**: `HarfordDnDMana.CasterContribution` acepta `casterType = "third"` (`ceil(nivel/3)`), ademas de `full` y `half`. Lo declara la SUBCLASE `picaro/sutileza`, no la clase. Sin esto, un Picaro Sutileza conocia sus 9 conjuros y tenia CERO ranuras: el compendio ya lo trataba como tercio (`THIRD_CASTERS` en `HarfordCompendioCore.GetMaxSpellLevel`, mismo `ceil(nivel/3)`) pero el motor de ranuras no. No hace falta puerta de nivel 3: antes de elegir subclase no hay `subclassId`, asi que el `casterType` ni se lee. Reproduce la tabla del Truhan Arcano: nivel 3 = 2 ranuras de N1, niveles 4-6 = 3 de N1, y N2 llega a nivel 7 (fuera de alcance). **`casterType` ausente es correcto** en Guerrero, Monje, Cazador de Demonios y Cazador: en esta adaptacion el Cazador NO lanza conjuros (su tabla de clase no tiene columnas de espacios, solo Marca del Cazador y Dados de Enfoque).
- **Riqueza inicial por clase**: diverge del manual A PROPOSITO (`multiplier = 1`, la decima parte). Ver "Decisiones de mesa que DIVERGEN del manual" al final de este fichero. Nota suelta: el Monje esta declarado `4d1` (4 monedas fijas, sin tirada) en vez de conservar la forma `NdM` del resto; su fila del manual es la unica sin `x10`. Pendiente de confirmar si esa forma es intencionada.
- **Sacerdote: Disciplina, Sagrado y Sombra cotejados contra fichas TRP3 reales** (`{PJ} Chloe` = Sagrado, `{PJ} Clementine` = Sombra, y el texto de Disciplina que aporto el usuario). Lo corregido: **Expiacion NO EXISTIA** -- el manual tiene ahi un marcador literal `#### CARACTERISTICA DE 1ER NIVEL / Caracteristica aqui`, sin escribir; el Libro 2 trae otra version distinta (nivel 6, `1d6 x nivel`), y la buena es la de la web/TRP3: simetrica, `2 x nivel del conjuro`, cura al danar y dana al curar, uno de los dos por lanzamiento. **Penitencia** cobraba 1 punto fijo cuando gasta HASTA CINCO y todo escala por punto; ahora el desplegable pide modalidad, puntos y tipo de dano. Regla que importa: en Condenar el **dano es automatico** y la salvacion de Sabiduria es SOLO contra el miedo, asi que va `resolution = "auto"` + `conditionApplySaveAbility`, NO `resolution = "save"`, que dejaria que la salvacion redujera el dano a la mitad. **Saber divino** es el nombre canonico del rasgo que estaba como "Competencia adicional (religion)". **Encadenar no muertos** tenia el coste bien pero `effects = {}`: ahora resuelve salvacion y `stunned` por el motor de area. **Legado del Vacio** estaba informativo; ahora aplica el dano psiquico (Mod. Carisma) y tira su salvacion con **CD 10 + 1 por cada uso adicional desde el ultimo descanso largo**, bloqueandose al fallar.
- **Contadores por descanso largo** (`progression.restCounters` + `GetRestCounter`/`SetRestCounter`/`ResetRestCounters`, limpiados en `ApplyLongRest`): para rasgos con la forma "N desde el ultimo descanso largo" que **no tienen tope de usos** y por eso no encajan en `_featureUses`, que necesita un maximo y solo resetea lo que aparece en `GetTracked`. Genericos a proposito: el primero es Legado del Vacio (sentinela `-1` = bloqueado), pero cualquier rasgo con esa forma los reusa sin inventarse su almacen.
- **Disparadores que el cliente NO observa**: Expiacion y Legado del Vacio son riders de "acabas de lanzar un conjuro/truco". Ninguno se autodetecta: se activan a mano y se pregunta lo que haga falta (el nivel del conjuro). Lo que SI es rastreable va automatico (la CD escalonada, el bloqueo, el dano). No convertirlos en pasivos ni fingir que detectan el lanzamiento.
- **Como contar rasgos "sin mecanizar" sin enganarse**: un rasgo esta mecanizado si tiene `effects` no vacios (propios o en las opciones de su `choice`), `choice`, `uses`/`usesFrom`, `area`, `actionKind`, `resourceKey`, `spellGrants`/`grantedSpells`/`cantripSpellIds`/`expandedSpells`, `companions`/`companionId`, **`cast = "reaccion"`** (BookCategory lo hace reaccion activable), **`requiresOption`** (solo existe si elegiste esa opcion) o **`showsExpandedSpells`**. Ademas hay que descontar dos familias que NO son huecos: los **marcadores de eleccion de subclase** (el Libro ya los oculta via `IsSubclassMarkerFeature`) y los **enganches de lanzamiento** ("Lanzamiento de conjuros", "Hechiceria Vil"...), cuya mecanica vive en `HarfordDnDMana`. Un contador que solo mire `effects` da cifras alarmantes y falsas: la primera pasada dio 175 "sin mecanizar" y la buena son 62 sobre 364 (302 mecanizados, 83%). No repetir ese error al auditar.
- **Rasgos DEFENSIVOS que llegan de otro cliente se comprueban en el DEFENSOR**: el aura de una maniobra viaja por `AURASIG` y es el cliente del objetivo quien se la aplica a si mismo (`HandleApplyAuraSelf`), asi que ahi puede rechazarla sin sincronizar nada. Implementado: **Armas runicas** del Caballero de la Muerte declara `flag cannotBeDisarmed` y su cliente rechaza el aura de Desarme (177714) salvo que este `incapacitated`. NO confundirlo con las resistencias al dano, que si necesitan sincronizacion porque las aplica el ATACANTE.
- **Efecto `restRestore`** (`{ kind = "restRestore", resource, rest = "short"|"long", value` o `perClassLevel + values }`): recuperacion PARCIAL de un recurso al descansar, que **no es lo mismo que su `recharge`**. Un recurso puede recargar en descanso largo y aun asi un rasgo devolver N en el corto: es el caso del Sacerdote "Restauracion de los fieles" (2 puntos de fe en corto desde nivel 5, 3 desde el 10, 4 desde el 17). Lo expone `HarfordDnDFeatureEffects.GetRestRestores(restType)` y lo aplican `ApplyShortRest` y `ApplyLongRest` DESPUES de las recargas normales, acotado al maximo del recurso.
- **Trucos concedidos**: un rasgo que dice "aprendes un truco adicional" tiene que concederlo o el truco no es tuyo para `IsMySpell` ni sale como conocido. Dos formas segun el texto: si el manual nombra el truco concreto, `cantripSpellIds = { "<id>" }` (los tres "Truco adicional" del Mago); si dice "de tu eleccion", `choice = { slots = 1, options = {}, extraFrom = "cantrip:<Clase>" }`, que rellena la lista desde el compendio filtrando por clase (Sacerdote Disciplina "Truco de bonificacion").
- **Efecto `weaponAbilityOverride`** (`{ ability, martialArtsOnly, requiresState }`): sustituye la caracteristica de ataque Y dano de un arma. Manda sobre artes marciales y sobre Sutil en `GetWeaponAttackAbility`, y el dano la sigue sola porque `RollWeaponDamage` recibe esa misma clave. Implementado: Monje **Serenidad** = `toggleState serene_stance` + el override a Sabiduria gateado por `requiresState`, asi que fuera de la postura el efecto ni existe. La postura sale como casilla en "Estados activables".
- **`HarfordDnDStore.AttackWithBlock(def, options)`**: atacar con un bloque arbitrario en lugar del arma equipada, por la ruta normal (CA, criticos, mitigacion, animacion, red). Nacio para las criaturas acompanantes y ahora lo comparten los rasgos que conceden un ataque propio (Monje "Palma de chi-ji", que ataca y dana con Sabiduria). `AttackWithCompanion` es un envoltorio suyo. Usar esto antes que escribir otra ruta de ataque.
- **Rasgos que gastan una RANURA DE CONJURO por un efecto escalado** (Paladin "Destello de Luz" y "Tormenta divina"): no escribir otra ruta de coste. `HarfordDnDConditionalDamage` ya resuelve coste, permitirse y cobro con `spellLevelCost`, y funciona igual en modo mana y en modo espacios; basta pasarle un condicional con la MISMA forma que Golpe del Cruzado. **Cuidado**: sin `maxSpellLevel`/`countPerLevel`/`maxCount` el `GetMaxLevel` de un condicional pelado se queda en **1** y el selector solo ofreceria nivel 1. La forma correcta es `{ spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, maxCount = 6, extraCountOffset = 1 }`, que da la escala del Paladin: 2d6 a nivel 1 subiendo hasta 6d6 a nivel 5. **Tormenta divina** se modela como UNA esfera de 1,5 m centrada en el paladin con salvacion de Destreza y `success = "half"`: el objetivo de un ataque cuerpo a cuerpo ya cae dentro, asi que no hacen falta dos resoluciones. Lo que el motor no sabe queda como `note`: que no afecta a no-muertos ni constructos (Destello) y que es excluyente con Golpe del Cruzado (Tormenta).
- **Efecto `resourceGain`** (`{ resource, amount, trigger, note }`): GANAR recurso por un disparador observable. Hasta el Guerrero de Armas y el de Proteccion los recursos solo se gastaban. Disparadores implementados: **`damage_taken`**, que salta en `ApplyResourceDeltaFromRemote` cuando llega un `RADJ` negativo a vida o vida temporal -- es NUESTRO cliente aplicandose el dano, asi que no hace falta sincronizar nada con el atacante, igual que "Armas runicas" --, y **`rage_maneuver_hit`**, que salta en `onImpactOnce` reusando el `spendsRage` que ya se calculaba para Furia Interna. Lo concede `TriggerResourceGain`, que acota al maximo y publica la ganancia. Guerrero: "Control de ira" (`damage_taken`) e "Intrepido" (`rage_maneuver_hit`). **Simplificacion declarada**: el manual pone Intrepido "al final de tu turno" y el 1/turno de Control de ira; el cliente no observa el fin de turno, asi que se concede al confirmar el impacto y el limite por turno va en el texto de la linea publicada.
- **Condicion `unleashed_rage`** (Guerrero "Ira desatada"): no es una condicion del manual sino el estado que deja el rasgo. Se modela como condicion porque el motor ya hace las DOS mitades a la vez (`rollMode adv` en tus ataques + `incomingRollMode adv` en los que te hacen). Es un toggle: `HarfordDnDStore.ToggleUnleashedRage` la aplica y la retira. Patron reutilizable para cualquier rasgo que cambie defensa por ofensiva.
- **Brujo "Vinculo de almas"** (`flag soulLink`): la mitad del dano que recibes, redondeada hacia ARRIBA, se TRANSFIERE al demonio invocado. Se resuelve en `ApplyResourceDeltaFromRemote` ANTES de restarte la vida, porque el manual dice transferir y no duplicar: tu recibes la otra mitad. Solo actua si hay un acompanante activo de `classId = "brujo"`, y le baja los PG con `HarfordDnDCompanions.AdjustHP`, asi que si el demonio cae a 0 se retira solo por la ruta de siempre. Es el primer rasgo que conecta el sistema de acompanantes con el dano recibido.
- **Dos formas de conceder recurso, NO duplicarlas**: `resourceGain` de RASGO (`{ key, amount }`, campo del rasgo) lo concede el panel al activarlo, y sirve para disparadores que el cliente no observa y pide el jugador a mano (Brujo "Capturar fragmento de alma", que es una reaccion a que muera una criatura cerca). El EFECTO `resourceGain` (`{ kind, resource, amount, trigger }`) es para disparadores que el cliente SI observa (Guerrero). Antes de escribir una ruta nueva, comprobar cual de las dos encaja: se escribio un activable duplicado antes de ver que el primero ya existia.
- **Mago "Racha de calor"** (`flag heatStreak`): si un dado de dano de conjuro saca el MAXIMO, se tira uno mas y se SUMA -- al reves que la repeticion de Palabra de Poder: Muerte, que SUSTITUYE el mas bajo. Vive en `RollComponents` de `HarfordDnDArea` y usa el mismo criterio que Guia Ancestral para saber que es un conjuro: **`definition.castLevel >= 1`**, asi que los trucos y las areas de un rasgo del Libro (Penitencia, Tormenta divina...) quedan fuera. Una sola vez por lanzamiento (`rachaUsada`), no por componente; el manual dice por turno y el cliente no observa el fin de turno. Se muestra como `(Racha de calor +N)` en el detalle.
- **Mago "Cargas arcanas"** (`flag arcaneCharges`): UNA carga a la vez, con NIVEL. Se gana al lanzar un conjuro de Mago de nivel 1+ y una carga nueva **solo sustituye a la anterior si es de nivel mayor** (tope 5). Se engancha en `API.SpendSpellMana` del compendio como ENVOLTORIO -- el punto unico donde se paga un conjuro, con multiples returns, por eso se envuelve en vez de editarlo. Gastarla deja un bono PENDIENTE de un solo uso: `+X al ataque y dano del proximo conjuro` o `+X a salvaciones contra magia`. El primero lo consume `BuildAreaDefinition` una sola vez por lanzamiento (`TakeArcaneSpellBonus`) y lo reparte al `attackBonus` y al `damageBonus` de cada componente. Estado en `progression.restCounters` (`arcane_charge`, `arcane_spell_bonus`, `arcane_save_bonus`). **El "1 minuto" de duracion NO se modela**: no hay temporizadores en el proyecto, asi que la carga vive hasta que se usa, la sustituye otra mayor o llega un descanso largo.
- **Cazador de Demonios**: "Momentum vengativo" usa `resourceGain` de RASGO (+1 Vil reclamado a mano) porque que impacten las DOS tiradas de Mordida de Demonio no lo observa el cliente. "Marca ignea" declara un `area` en el propio rasgo y reusa la ruta `cat == "area"` del Libro -- igual que Encadenar no muertos --: salvacion de Constitucion y condicion `marca_ignea`. **Se creo una condicion propia en vez de reusar `palabra_dolor`**, que tiene el mismo efecto (desventaja en ataques) pero le pondria a la victima la etiqueta "Dolor", que es de otro rasgo; el nombre importa en mesa.
- **Pendiente con concepto que NO existe: REDUCCION PLANA de dano** (Sacerdote Disciplina "Supresion del dolor": barrera a un ALIADO que le reduce el dano fisico en 2 + tu competencia). `HarfordDamageMitigation` trabaja por TIPO (resistente/inmune/vulnerable), no con una resta, y las condiciones **no admiten un valor numerico**. Ademas la barrera va sobre otro jugador, asi que hace falta que su cliente la conozca. Modelarlo pide dos cosas nuevas: condiciones con valor y su sincronizacion. No inventar un apano con vida temporal: la vida temporal se CONSUME y una reduccion no.
- **FORMATO DE LAS LINEAS DE HABILIDAD -- regla, no preferencia**: una habilidad se publica como `[D&D] <Actor> [LINK de la habilidad] <Objetivo>`, y punto. **NO se narra en prosa** ("proyecta una barrera sobre...", "gana 1 de Ira", "crea un espacio de nivel 2"). Se consigue SIEMPRE con `HarfordDnDRolls.BroadcastAbility(feature, { targetUnit = ... })`, que resuelve el link TRP3 y deja que el render anteponga el actor y anexe el objetivo. Los NUMEROS no van en esa linea: van en su tirada tipada (`attack`, `damage`, `save`, `heal`) o se ven en la barra del recurso. Un area con `abilityFeature` en su contexto ya la firma sola. Cuando la mecanica se dispara automatica y no tiene a mano la tabla del rasgo, se usa `HarfordDnDStore.AnnounceFeatureById(featureId, targetUnit)`; por eso el efecto `resourceGain` lleva `featureId`. **Unica excepcion**: los DESENLACES cortos que no son una habilidad (`recupera 1 PG`, `queda incapacitado`, la criatura acompanante que cae a 0 PG) siguen siendo un `info` breve. Y una tirada de salvacion propia de la habilidad NO repite su nombre: la linea de la habilidad ya la firmo.
- **CONDICIONES CON VALOR** (`record.vars = { nombre = numero }`): convierten una condicion de etiqueta si/no en algo que lleva una cantidad ("reduce 5") o un contador ("3 acumulaciones"). Diseno tomado de **TRP3 Extended 2.3.5** (modulo `Aura`), que ya resolvio esto -- pero NO se puede usar el suyo: el Extended instalado en Epsilon es **1.5.2 y no tiene modulo de auras**, y la version que si lo tiene va contra interfaz 120100 frente a nuestra 90207. Lo que se copio es el MODELO, no el codigo. `API.GetVar(ref, id, nombre, default)` y `API.SetVar(ref, id, opType, nombre, valor)` con las operaciones de TRP3: **`[=]`** fija solo si no existe, **`=`** fija siempre, **`+`/`-`/`*`** operan sobre lo que hubiera. **Solo NUMEROS a proposito**: el QUE hace la condicion vive en su definicion (`API.DEFS`), la instancia solo lleva el CUANTO -- por eso `supresion_dolor` declara `damageReduction = { tipos }` en la definicion y solo `vars.reduccion` viaja. Viajan en `DNDCOND` como un campo mas, codificadas `nombre=numero,nombre=numero` (sin `|`, que es el separador). **La expiracion NO se copio de TRP3**: la suya es por reloj con `C_Timer`; la nuestra ya era por RONDAS con el `turnSerial` del tracker, que es lo correcto para una mesa por turnos.
- **`API.GetDamageReduction(ref, tipo)`**: reduccion PLANA que aplican las condiciones activas a un tipo de dano. **No es resistir** (mitad) **ni vida temporal** (se consume): resta una cantidad fija a CADA golpe mientras dure. Se aplica en `ApplyResourceDeltaFromRemote`, o sea en el cliente del DEFENSOR, que es quien se resta la vida -- por eso no hace falta que el atacante conozca la barrera. **Limitacion conocida**: `RADJ` no lleva el tipo de dano, asi que ahi se asume contundente (el caso que cubre el rasgo del Sacerdote); cuando el opcode lleve tipo, se pasa y deja de asumirse.
- **Fallo corregido de paso**: `CopyRecord` de `HarfordDnDConditions` no copiaba `level`, asi que una condicion con niveles (cansancio) volvia a 1 al persistir y recargar. Es el mismo fallo que ya se corrigio en la ruta de APLICAR y seguia vivo en la de guardar.
- **Mapa de rutas de dano (quien mitiga)** -- util antes de tocar nada de dano: **Jugador -> NPC** usa un comando de servidor (`SetNpcHealthDelta`) y mitiga el ATACANTE, y esta bien asi porque el NPC no tiene cliente. **NPC -> tu mismo** se aplica en local (`ApplyLocalResourceDamage`) y ya lo resuelve tu cliente. **Motor de AREA**: cada victima resuelve en SU cliente (tirada, salvacion, mitigacion) y aplica el dano localmente -- **es el modelo correcto y ya esta en produccion**. **`RADJ` es la ruta LEGADA**: la unica que sigue mitigando en el emisor con una copia cacheada de las defensas ajenas, y por eso el DM no puede aplicar bien tus resistencias. Migrarla significa llevarla al modelo del area, no inventar uno. Son **7 llamadas** que acaban en `RADJ` y **5 puntos de mitigacion** distintos: dentro de `RollWeaponDamage`, dentro de `RollActionDamage`, la maniobra de energia, Canalizar fuego demoniaco y el dano personalizado.
- **Corregido**: `HarfordDnDStore.ApplyFailedSpecialDamage` (dano de un especial de forma druidica tras fallar la salvacion) recibia `damageType` y **NO lo usaba**: ignoraba por completo resistencias e inmunidades del objetivo. Ahora mitiga como cualquier otro dano y publica el tipo con su marcador R/V/I. Un objetivo inmune recibe 0 y la linea lo dice.
- **`RADJ` MIGRADO al modelo del area: nuevo opcode `DNDDMG`**. El dano a otro jugador ya NO se manda pre-mitigado y pre-partido entre vida temporal y salud: se manda **EN BRUTO, desglosado por tipo** (`DNDDMG|14:cortante,9:frio|C`) y lo resuelve el cliente de la VICTIMA, que es el unico que conoce de verdad sus resistencias, sus reducciones planas y su vida temporal. `RADJ` sigue existiendo para lo que siempre fue ademas de dano: CONCEDER recursos. **Por que multi-componente**: un golpe puede llevar varios tipos (arma cortante + Golpe Runico de frio) y la victima puede ser resistente a uno y vulnerable a otro; mandar un tipo unico daria un resultado erroneo. **La pieza que evita tocar los sitios que calculan dano** es `HarfordDamageMitigation.TargetResolvesOwnDamage(unit)`: `ForTarget` devuelve el bruto sin tocar cuando el objetivo es OTRO jugador, asi que los 5 puntos de mitigacion siguen llamando igual y se auto-desactivan solo en ese caso. Contra NPC y contra uno mismo se sigue mitigando en el atacante, que es lo correcto: no hay otro cliente que lo haga. `ApplyWeaponDamageToTarget` y `ApplyActionDamageToFocus` aceptan **un numero ya mitigado (compatible) o una lista de componentes en bruto**; `RollWeaponDamage` y `RollActionDamage` devuelven esa lista como segundo valor. Orden de resolucion en la victima: resistencias por tipo -> reduccion plana de condiciones -> vida temporal -> salud, y publica lo que realmente recibio. **MIGRACION COMPLETA: las 7 llamadas pasadas.** El helper `HarfordDnDCombat.PayloadFor(unit, total, damageType)` decide por ellas: componentes en BRUTO si el objetivo resuelve lo suyo (otro jugador), el total tal cual si no (NPC o uno mismo, donde el llamador ya mitigo). Sin tipo o con dano 0 devuelve el total, asi que nunca rompe. Usarlo SIEMPRE al anadir un sitio nuevo que dane; no repetir el condicional. **Compatibilidad**: un cliente antiguo no entiende `DNDDMG` y no aplicara el dano; el nuevo entiende los dos.
- **`progression.choices[featureId]` esta indexado por SLOT y puede tener HUECOS**: el desplegable por slot del panel de personaje escribe un `slotNo` arbitrario, asi que se puede dejar el 1 vacio y el 2 puesto. Los ~10 consumidores recorren la lista con `ipairs`, que se detiene en el primer hueco, y la eleccion entera se comportaba como si no existiera: sin efecto, sin salir en el About y marcada como pendiente en el Libro. **`API.GetChoice` ahora devuelve la lista COMPACTADA**, lo que lo arregla para todos a la vez. Al leer elecciones, usar SIEMPRE `GetChoice` y no `data.choices[id]` directo.
- Contrato `HarfordDnDForms` (`Harford/DnD/State/HarfordDnDForms.lua`): interpreta la seccion TRP3 **Cambio de forma** del jugador propio. Solo acepta formas con encabezado `h2`, CA explicita y acciones `h3` con dado/tipo de daño; no inventa formas ni reemplazos si la ficha no las declara. Conserva alcance, objetivo, bonificador fijo y tipo de daño de la ficha, convirtiendo este ultimo a la clave interna solo para calculos y devolviendo siempre la etiqueta española en UI. Los `h3` especiales declarativos de una forma (actualmente `Carga`/`Embestida`) se parsean separadamente: requieren movimiento medido, se arman antes del ataque normal, y se resuelven solo si impacta mediante la salvacion/condicion existente. `Carga` suma su daño extra al impacto; tras fallar una salvacion de `Embestida` contra NPC queda preparado su dado extra para el siguiente impacto. La seleccion guarda `activeForm`/`activeFormAction` dentro de la progresion y activa `wild_shape`. Mientras existe una forma, su CA tiene prioridad sobre TRP3/equipo, sus ataques naturales sustituyen por completo arma principal/offhand y se ignoran bonos globales de armas/objetos; al revertir solo se limpian esos dos estados, por lo que el equipo y valores normales reaparecen intactos. Los PG se conservan porque la ficha de Baird asi lo establece; la forma se revierte automaticamente a 0 PG. Las formas declaradas se reflejan en el personaje con auras reales: Lechucico lunar=`24858`, Oso=`5487`, Gato=`768`, Antárbol=`33891`; al pasar entre dos formas conocidas se retira solo la aura anterior y se aplica la nueva mediante el wrapper rapido. Forma normal/0 PG, o un estado previo desconocido, retira las cuatro auras para limpiar residuos. No se reenvia la secuencia al cambiar solo el ataque de una misma forma. **La unica activacion manual es el rasgo `Cambio de Forma` en el Libro de Habilidades:** su flecha abre a la derecha una replica no segura del `SpellFlyout` de **Shadowlands 9.2.7**, usando literalmente `ActionBarFlyoutButton`, `ActionBarFlyoutButton-FlyoutMidLeft`, botones `28x28`, espaciados `7/4/4` y la tapa final rotada del original. El flyout se eleva sobre el Libro con el strata/nivel del ancla para no quedar oculto bajo sus paginas. El Libro muestra `Forma activa: <nombre>` e icono TRP3 de la forma. Si la forma tiene varios ataques o especiales, la seccion Ataque muestra otra flecha y usa la misma replica. No usar el `SpellFlyout` real: es protegido y solo admite hechizos Blizzard registrados. `Subida` no muestra ni puede cambiar `wild_shape`; solo configura elecciones de progresion. No usar el recurso `rage`: es exclusivo del Guerrero.
- Contrato `HarfordDnDCompanions` (`Harford/DnD/State/HarfordDnDCompanions.lua`) + datos `HarfordDnDCompanionsData`: criaturas acompanantes del JUGADOR (esbirro no-muerto del Caballero de la Muerte, elemental de agua del Mago). Modeladas sobre `HarfordDnDForms`, **NUNCA sobre el contexto NPC**: `ApplySheetContext` es la ficha NPC del DM y no debe usarse para criaturas de un jugador. **No tienen entrada en el tracker de turnos**: actuan DENTRO del turno de su invocador, y `HarfordTurns.AddEntry` exige `IsTurnAdmin()`, asi que un jugador no podria anadirlas aunque se quisiera. `commandAction` (`accion`/`adicional`) declara que cuesta ordenarles un ataque y sale en el tooltip. Lo persistido es MINIMO: `activeCompanion` y `activeCompanionHP` en la progresion, espejo de `activeForm`. Todo lo demas se DERIVA en cada consulta para que subir de nivel se refleje sin migrar nada: `hp = base + Mod. de una caracteristica del bloque + Mod. de una TUYA + perOwnerLevel x tu nivel de esa clase`, `acPlusProficiency` suma tu PB a la CA, una accion con `attackFrom = "spellAttack"` usa TU ataque de conjuros y `damagePlusProficiency` suma tu PB al dano. **Los ataques NO tienen ruta propia**: `GetWeaponDef` devuelve la accion con forma de arma y `HarfordDnDStore.AttackWithCompanion(actionKey)` la pasa por el `DoWeaponAttack` normal via `options.weaponDef`, asi que hereda CA del objetivo, criticos, mitigacion por tipo, reaccion de Barrera, animacion y red. Lo que NO debe heredar son los rasgos del invocador: el flag `externalActor` (helper `ActorIsPlayer(def)` en `HarfordDnD.lua`) corta Gran Arma, Ataques Salvajes, Artes Marciales, critico ampliado, dano extra de rasgos, danos condicionales activos, la penalizacion por condicion propia y la competencia con armas del jugador. La UI es una categoria declarativa del Libro: un rasgo con `companionId` se clasifica como `acompanante` y su flyout invoca / despide / ordena / ajusta PG. El flyout es el MISMO de las formas druidicas, expuesto como `HarfordDnDForms.OpenEntryFlyout(clave, ancla, entradas, activa, alElegir)`; no duplicar el arte nativo. A 0 PG la criatura cae y se retira sola; la Fortaleza No-Muerta del esbirro es tirada de mesa, no automatica. La disponibilidad se filtra por clase, nivel y `requiresOption` contra `progression.choices` (indexado por SLOT: leer con `pairs`, no `ipairs`). `masterPower = { ac, attack, damage }` es "Poder del Maestro": esos numeros suben 1 por cada +1 de TU bonus de competencia, y el bloque esta escrito con el bonus base 2, asi que el incremento es `PB - 2` y nunca resta. Lo llevan los 5 demonios del Brujo (`guardia_vil`, `manafago`, `diablillo`, `sucubo`, `abisario`, todos desde nivel 2 por `bru_conocimiento_demoniaco`) y, solo en ataque y dano, el esbirro del CdM. Los demonios derivan sus PG de **Inteligencia**, no de Carisma: este brujo lanza con Inteligencia, y lo confirma `bru_dem_sentir`, cuyos usos salen de la misma caracteristica. Un rasgo que concede VARIAS criaturas usa `companions = true` (se elige cual al invocar) en vez de `companionId`; quien filtra sigue siendo `GetAvailable` por clase, nivel y `requiresOption`. **Fuera del sistema a proposito**: `Guardian de la Perdicion` e `Infernal` NO son acompanantes -- son monstruos de Desafio 7 con PG fijos (85 y 73), sin Poder del Maestro ni Nucleo Demoniaco--; no meterlos aqui. **Bestia del Cazador** (`Harford/DnD/State/HarfordDnDBeast.lua`): NO es un bloque escrito a mano. El manual dice "cualquier bestia" (Mediana o menor de desafio 1/2; Grande o menor de desafio 1 con `caz_bes_domador`) y **no trae bestiario**, asi que el bloque lo escribe el jugador en su TRP3 bajo el frame `{h1}Compañero bestial{/h1}`, con un `{h2}` por bestia (`CA 13   PG 11 (2d8 + 2)   Velocidad 40 pies`) y sus ataques en `{h3}`. Se parsea igual que `Cambio de forma` y se registra via `HarfordDnDCompanions.RegisterProvider`, asi que entra por la MISMA puerta que el resto: mismo estado, PG, flyout y ruta de ataque. El bloque se copia TAL CUAL del bestiario, con su competencia +2; el Vinculo del Compañero se aplica encima con campos ya existentes: `acPlusProficiency` (+PB a la CA), `damagePlusProficiency` (+PB al dano) y `masterPower = { attack = true }` (su competencia se SUSTITUYE por la tuya, de ahi `PB - 2`). Los PG usan el modo `hp = { base, hitDie, hitDieConMod, extraDiceAfterLevel = 3 }`: un dado de golpe por **nivel de PERSONAJE** (no de clase) despues del 3, con el valor PROMEDIO `dado/2 + 1 + Mod. Con` -- no una tirada, que cambiaria en cada consulta. El Mod. Con se deduce del `(2d8 + 2)` del propio bloque. **Sus dos elecciones estan en la subida** con `optionsFrom = "beastSkill"` (L3, dos habilidades) y `"beastAbility"` (L4, la Mejora de Caracteristica de la bestia: +2 a una o +1 a dos, por eso admite repetir opcion). Ambas listas se generan **SIN `effects`** a proposito: son de la BESTIA, y usar `skillProf`/`ability+N` se las aplicaria al cazador. Por el mismo motivo NO se recalculan los numeros del bloque: lo mantiene el jugador en TRP3 y aplicarlas aqui las contaria dos veces. **NO anadir "Companero bestial" a `EXTRAS_DE_CLASE`** de `HarfordCharacterCreation`: comprobado con `TituloRango` que hoy NO se reconoce como cabecera canonica (rango nil), y eso es justo lo que lo protege -- el frame se trata como propio del jugador y sobrevive intacto a la regeneracion del About y a cada subida de nivel. Reconocerlo haria que Harford creyera que ese frame es suyo y lo reescribiese, borrando el bloque de la bestia. Es lo contrario que `Cambio de forma`, que SI esta en `EXTRAS_DE_CLASE` (rango 15) porque el druida no escribe datos que Harford deba conservar. Invocar la bestia **apaga el estado `lone_wolf`**: los rasgos "Lobo Solitario" exigen no tener companero. **Nucleos Demoniacos del Brujo**: un nucleo NO es una criatura (no tiene PG ni acciones), pero vive en este mismo sistema porque el manual los hace EXCLUYENTES: "solo puedes mantener un demonio invocado o un nucleo a la vez", y `Grimorio de sacrificio` dice que el nucleo se obtiene destruyendo al demonio al invocarlo. Estado: `activeCore` en la progresion; `Summon` lo limpia y `TakeCore` limpia `activeCompanion`/`activeCompanionHP`, asi que la exclusion la impone el estado y no hace falta validarla en la UI. En el flyout hay tres situaciones: con nucleo, solo "Soltar el nucleo"; con demonio invocado, aparece "Destruir a X y quedarte su nucleo"; sin nada, la lista de invocables. Los datos del nucleo (`core = { source, advantage, atWill, tiers }`) viven **junto a su prosa en el rasgo de clase** `bru_nucleo_*`, no en el bloque del demonio, que solo apunta con `coreFeatureId`: un unico sitio donde corregirlos. `GetCoreGrants` separa lo que concede AHORA de lo que llega en niveles superiores segun tu nivel de brujo. **Los conjuros SI llegan al libro**: cada rasgo `bru_nucleo_*` declara `requiredCore = "<id del demonio>"` y `spellGrants = { { level, ids } }`. La puerta nueva esta en `HarfordDnDProgression.IsFeatureEnabled`, con el mismo patron que `requiredRace`: un rasgo de nucleo solo cuenta si `data.activeCore` coincide. Con eso, `HarfordCompendioCore.IsFeatureGrantedSpell` -> `IsMySpell` ya funcionaba sin fontaneria nueva; los cinco rasgos existen desde nivel 2, pero solo cuenta el del nucleo sostenido, y sin nucleo no concede ninguno. `IsFeatureGrantedSpell` NO consulta `spell.classes`, asi que un conjuro concedido cuenta como tuyo aunque su lista de clases no incluya al Brujo -- que es el caso de `armadura_de_agathys`, `armadura_de_mago`, `arma_magica`, `burla_danina` y `parpadeo`, todos marcados solo como Mago en el compendio. El flyout llama a `HarfordCharacterSpellbook.RefreshSpells` al tomar o soltar un nucleo. El at-will del Sucubo apunta a `hechizar_persona` de las DOS entradas duplicadas de *charm person*, porque la otra (`encantar_persona`) lleva el `mechanics` de otro conjuro. **Nombres de conjuro cotejados contra el compendio**: `contraconjuro` es **Contrahechizo**, `mofa vil` es **Burla danina** y `sugerencia` es **Sugestion**; faltan `furia de sangre y heroismo`, `lluvia de fuego`, `dominar persona` y `desgaste` (todos de nivel 9 del brujo o de nivel de conjuro > 4). **Fallo de datos conocido en `HarfordCompendio.lua` (co-propiedad, sin tocar)**: `hechizar_persona` y `encantar_persona` son la misma *charm person* duplicada, las dos con `classes = { "Sacerdote" }` cuando es conjuro de Brujo, y `encantar_persona` lleva el `mechanics` de *conjurar seres del bosque*. Detalle en `CONJUROS_PENDIENTES.md`. **Pendiente**: el `Guardian de la Perdicion` de los cuatro demonios que aun no tienen su rasgo (solo existe `bru_nucleo_abisario`).
- **Metamorfosis del Cazador de Demonios:** desde 2026-08 no es una barra ni un recurso sincronizado. `dh_metamorfosis` es una accion con `uses={max=1,recharge="long"}`; al activarla el Libro gasta su uso estandar, activa el estado temporal y concede sus PG temporales. Las claves heredadas `Res_metamorphosis_Cur/Max` se podan al cargar el perfil. `Momentum` consume 1 punto de Vil al activarlo.
- **Restauracion del Druida:** `dru_res_rejuvenecimiento` conserva su id por compatibilidad, pero se presenta como **Alivio presto**: reserva de d6 igual al nivel de druida que mejora una curacion ya lanzada. `Marca de lo Salvaje` (L6) usa el contador estandar con `uses={ proficiencyBonus=true, recharge="long" }`; no es un recurso nuevo ni usa `living_seeds`.
- `conditionalWeaponDamage.flatBonus` (segunda prioridad de mecanizacion de clases): el mismo control de "Daño extra" puede sumar dados (`count`/`die`/`perTwoClassLevels`/`dieScale`) y/o un valor plano (`flatBonus`). Valores aceptados: numero fijo, `"pb"`/`"competencia"` para bonus de competencia, `"level"`/`"nivel"` para nivel total o nivel de `flatClassId`, o nombre de caracteristica para usar su modificador. El daño plano se consume junto al condicional, no se duplica en critico, y se mitiga con el mismo `damageType` del condicional. Cableado actual: Chaman Afinidad Fuego (`flatBonus="pb"`, fuego) y Picaro Asesino Intuicion del Asesino (`flatBonus="level"`, `flatClassId="picaro"`).
- Contrato `HarfordDnDFeatureEffects` (`Harford/DnD/Engine/HarfordDnDFeatureEffects.lua`): interpreta los efectos activos de progresion y devuelve una capa derivada para calculos. Efectos soportados: `bonus` a `ability/save/skill/initiative/weaponAttack/weaponDamage/armorClass/spellAttack/spellDC`, `saveProf`, `skillProf`, `skillExpertise`, `resourceMax`, `armorProf` (`effect.armor`), `weaponProf` (`effect.weapon`), `critRange` (critico ampliado: `effect.value` = tirada minima de critico, p.ej. 19; `effect.melee = true` lo restringe a armas cuerpo a cuerpo), `flag` (`effect.flag` booleano por rasgo; `HasFlag(name)`), `resist`/`immune`/`vuln` (`effect.damage` = palabra del tipo, ej. "veneno"; `GetDamageStatus(tipo)` -> "resistant"/"immune"/"vulnerable"/nil; `GetDamageStatusMap()`). **Estilos de combate cableados via flag**: `offhandDamageMod` (Combate con Dos Armas: el ataque offhand suma Mod. al daño) y `greatWeaponFighting` (Gran Lucha con Armas: repite 1-2 en dados de daño con arma a dos manos/versatil) — afectan a `RollWeaponDamage`/`UpdateWeaponInfoUI`. **`savageCritDie`** (Orco "Ataques Salvajes"): en `RollWeaponDamage`, si la tirada es critica (`maximizeDice`), tira UN dado de daño de arma adicional (se tira, no se maximiza). **`trollRegenHitDie`** (Troll "Regeneracion"): en `RollHitDieHeal`, el dado de golpe cura `tirada + 2x Mod. CON` (en vez de 1x). **Resistencias del jugador**: `HarfordDamageMitigation.ForTarget` aplica el `GetDamageStatus` del jugador LOCAL; para que el DM (otro cliente) aplique TU resistencia hace falta sincronizar el mapa (pendiente, estilo CA). Implementado: DK Constitucion No-Muerta = `resist veneno`. **`resourceMax` dinamico**: ademas de `effect.value` fijo, acepta `effect.base + effect.perLevel * (nivel de effect.perClassLevel)` para pools de clase escalados (ej. DK Poder Runico = `resourceMax` sobre el recurso existente `runic_power` con `base=1, perClassLevel="caballero_muerte"` = 1 + nivel CdM; el recurso aparece solo al tener max>0). **Ataque Extra** = `flag extraAttack` (recordatorio "x2" en la seccion Ataque del jugador; sin economia de acciones no auto-dobla la tirada). **Daño condicional conmutable** `conditionalWeaponDamage` (`effect.id/label/die`; nº de dados = `effect.count` fijo o `ceil(nivel/2)` de `effect.perTwoClassLevels`; `effect.damageType` opcional, por defecto el tipo del arma; **dado escalado por nivel** con `effect.dieScale = {{minNivel,caras},...}` ascendente + `effect.scaleClassId` — ej. Marca del Cazador 1d4→1d6/1d8/1d10, con `count` por defecto 1 si solo escala el dado). `GetConditionalDamage()` lista los disponibles; la seccion Ataque usa UN SOLO control dinamico: el boton `condDamageButton` que despliega (`condDamageMenu`, dropdown) **solo** los daños condicionales que tenga el personaje, permite activar **varios** a la vez (set `HarfordDnDStore.activeCondDamage` por id) y se **OCULTA** si no hay ninguno (sin botones en gris). `RollWeaponDamage` suma los dados de cada activo (mitigados, maximizados en critico) y los **consume** todos tras la tirada. El boton muestra el nombre si hay 1 activo, "Extra (N)" si varios, o "Daño extra" si ninguno. **Guerrero** (hasta L6): Estilos de Combate (Defensa/Duelo/Gran Arma/Dos Armas) ya cableados; **Ataque Extra** (`flag extraAttack`); **Furia Interna** = recurso `rage` (relabel a "Ira") con `resourceMax perClassLevel="guerrero" perLevel=1` = max nivel de Guerrero (manual: "no mas puntos de furia que tu nivel de Guerrero"). Informativo: Segundo Aliento (gasta un dado de golpe — ahora posible desde el menu de descanso, ver contrato de Dados de Golpe; no hay boton dedicado en combate), Accion Adicional (1 uso/descanso), Arquetipo Marcial y las maniobras de Furia (Carga/Desarme/Golpe Furioso, situacionales). **Subclases del Guerrero pobladas a L3** (antes estaban vacias): Armas (Arrollar `uses` 2/short + Intrepido), Furia (Furia Desatada + Temible = `skillProf` Intimidacion), Proteccion (Provocacion `uses` 1/short + Control de Ira); el resto de rasgos de arquetipo (L7/11/15/18) queda fuera del alcance L6, y casi todo es reaccion/generacion de furia situacional -> `informativo`. Implementado: **Picaro Ataque Furtivo** = `{ conditionalWeaponDamage id="sneak", die=6, perTwoClassLevels="picaro" }` (1d6/2/3d6 a L1-2/3-4/5-6). Reutilizable para Golpe Runico (DK)/Castigo Divino, etc. **`attackPenalty`** (campo de `conditionalWeaponDamage`): resta a la tirada de ataque mientras el toggle este activo (lo aplica `DoWeaponAttack` via `GetActiveConditionalAttackPenalty`); el dano lo aporta `flatBonus`. Asi la dote **Gran Maestro de Armas** "Golpe Potente" = `{ conditionalWeaponDamage id="gwm_potente", flatBonus=10, attackPenalty=5 }` es un toggle -5/+10 desde "Daño extra" (su ataque adicional al critico/matar sigue informativo). **Maniobras de Furia del Guerrero (L2)** como `conditionalWeaponDamage` con `resourceCost="rage"`: Golpe Heroico (+Mod Fuerza, 1 Ira) y Desarme (solo-coste, 2 Ira, "suelta objeto"; aplica aura **177714 al IMPACTAR** via campo `onHitAura`). **Todo solo al impactar**: el consumo de coste y `onHitAura` viven en `RollWeaponDamage`, que solo corre desde `onImpactOnce` (hit confirmado); en fallo no se gasta ni aplica nada. `onHitAura` enruta: NPC -> `HarfordServerActions.SetNpcAura(id)` (`.npc set aura`); jugador ajeno -> `HarfordDnDNet.SendAuraToPlayer` (opcode `AURASIG`) y el receptor ejecuta `.au <id> self` via `deps.ApplyAuraSelf` -> `HarfordServerActions.ApplyAura`. Para esto el sistema acepta entradas **solo-coste** (sin daño) y un campo **`flatAbility`** (ej. "Fuerza") que se resuelve **EN LA TIRADA**, NO en `Resolve`: usar `flatBonus=<caracteristica>` dentro de `conditionalWeaponDamage` causa **recursion infinita** (GetAbilityMod -> GetBonus -> Resolve -> ApplyEffect -> ResolveFlatBonus -> GetAbilityMod...). `flatBonus` solo para "pb"/"level"/numero; para Mod de caracteristica usar `flatAbility`. **Picaro**: Pericia (L1) y Pericia mejora (L6) ya eran `choice optionsFrom=skillExpertise`; Forajido competencia pistolas/rifles ya era `weaponProf`. **Picaro Energia** = `resourceMax` sobre el recurso `energy` con `perClassLevel="picaro"` + `values={...}` (tabla exacta del manual por nivel: L1=0, L2=1, L3-4=2, ... L19-20=10; `resourceMax` admite `values` indexado por nivel ademas de `base`/`perLevel`). **Picaro Alacridad** (Forajido) = `initiativeAbility ability="Carisma"` -> `GetInitiativeAbilities()`; `HarfordDnDCalc.GetInitiativeBonus` suma el Mod. de esas caracteristicas a la iniciativa (la parte de "sin ataques de oportunidad" queda informativa). **Picaro completo hasta L6.** **Paladin** (hasta L6): Estilo de Combate Defensa/Doble Empuñadura/Gran Arma ya cableados; **Ataque Extra** (`flag extraAttack`); **Golpe del Cruzado** = `conditionalWeaponDamage id="smite" count=2 die=8 damageType="radiante" spellLevelCost="level"` (selector por nivel de espacio/mana; escala +1d8 por nivel superior y se cobra solo al impactar); **Aura de Proteccion** = nuevo efecto `allSavesAbility ability="Carisma" min=1` -> `GetAllSavesAbilities()`, `HarfordDnDCalc.GetSaveRollBonuses` suma `max(min, Mod)` a TODAS las salvaciones (parte de aliados informativa); **Defensa sin Armadura** = nuevo efecto `unarmoredDefenseAbility ability="<car>"` -> `GetUnarmoredDefenseAbilities()`, sumado a la CA en `HarfordDnDCombat.GetSelfArmorClass` SOLO en la rama sin armadura ni escudo (con armadura/escudo equipados no aplica, regla 5e); se propaga a otros via `ComputeSelfArmorClass`; **Imposicion de Manos** = reserva propia del rasgo `pal_imposicion_manos`, no una barra de recursos: `uses={perClassLevel="paladin",perLevel=5,recharge="long"}`. El Libro muestra los PG disponibles como `actual/max`; al activarla abre un prompt para elegir la cantidad y la curacion se resuelve por `HarfordDnDArea` sobre el objetivo. Las claves heredadas `Res_lay_on_hands_Cur/Max` se podan al cargar. **Canalizar Divinidad** = recurso nuevo `channel_divinity` ("Canalizar Divinidad", max 1, via `resourceMax value=1` en `pal_camino_sagrado` que se desbloquea a L3 -> aparece desde nivel 3; manual: 1 uso, recarga en descanso corto/largo). Solo el CONTADOR de usos es mecanico; las OPCIONES (Luz del Amanecer, Consagracion, Veredicto del Templario, etc.) quedan informativas. Informativo: Sentido Divino, Lanzamiento de Conjuros, y los efectos de las opciones de subclase. **Druida** (full caster + wild shape): casi todo es spell/forma-gated -> informativo. Mecanizado: **Rejuvenecimiento** (Restauracion L2) = recurso `living_seeds` (reetiquetado a "Rejuvenecimiento", recarga "long") con `resourceMax perClassLevel="druida" perLevel=1` = nivel (nº de d6); **Instintos Primales** (Feral L6) = `initiativeAbility ability="Sabiduria"`; **Adaptacion Salvaje** (Feral L2, choice) ya daba `saveProf Destreza/Constitucion`. Informativo a proposito: Cambio de Forma y todas las afinidades/tacticas/marca de forma (wild shape no modelado), Ataque Adicional **transformado** (condicional a estado no rastreado, como Lobo Solitario del Cazador), Conjuros/Invocar/Fuerza de la Naturaleza/Corteza de Hierro (spell-gated). El recurso `astral_power` queda reservado sin usar (el Equilibrio homebrew usa ranuras, no un pool astral). **Cazador de Demonios** (hasta L6): **Defensa sin Armadura** (L1) = `unarmoredDefenseAbility ability="Inteligencia"` (+Mod. INT a la CA sin armadura ni escudo); **Vil** (L2) = recurso `fel_point` ("Vil", recarga "short") con `resourceMax perClassLevel="cazador_demonios" perLevel=1` = nivel; **Metamorfosis** (L2) = recurso nuevo `metamorphosis` ("Metamorfosis", recarga "long") con `resourceMax perClassLevel="cazador_demonios" values={0,1,1,1,1,1,2,2,2,2,2,3,3,3,3,4,4,4,4,5}` (usos 1/2/3/4/5 por la tabla); **Ataque Adicional** (L5) = `flag extraAttack`; las competencias de marca (L3, `skillExpertise` Acrobacias/Intimidacion/Arcano) ya estaban. Informativo a proposito: Iniciacion Illidari (competencia Supervivencia SOLO al rastrear / armas como precisas — condicional), Vision Espectral, Hambre Instintiva, Llamas del Caos (ataque especial no-arma), y los efectos en metamorfosis de cada marca. **Monje** (hasta L6): **Defensa sin Armadura** (L1) = `unarmoredDefenseAbility ability="Sabiduria"` (+Mod. SAB a la CA sin armadura ni escudo); **Chi** (L2) = recurso `chi` con `resourceMax perClassLevel="monje" perLevel=1` = nivel (recarga "short"); **Ataque Adicional** (L5) = `flag extraAttack`; **Reflejos del Tigre** (Caminavientos L3) = `initiativeAbility ability="Sabiduria"`; **Niebla Calmante** (Tejedor L3) = recurso nuevo `healing_mist` (label "Chi sanador", recarga "long") con `resourceMax perClassLevel="monje" base=0 perLevel=10` = nivel x10 PG (el rasgo se sigue llamando "Niebla Calmante"; solo cambia el nombre visible del recurso). Informativo a proposito: Artes Marciales (dado marcial/uso de Destreza y golpe desarmado como arma — el sistema de armas no modela el dado escalado del monje), Serenidad/Palma de Chi-Ji (SAB a ataque/daño solo en postura temporal), Palma Aturdidora, Golpes Empoderados por el Chi (golpes magicos), Rodar, brebajes/nieblas/efectos de tradicion (chi-gated). **Chaman** (hasta L6): **Totemista** (L2, base) = recurso nuevo `totem` ("Tótem", recarga "short") con `resourceMax perClassLevel="chaman" values={0,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4}` (2 usos, 3 a L10, 4 a L18); **Torbellino** (Mejora L3) = recurso nuevo `maelstrom` ("Torbellino", recarga "short") con `resourceMax perClassLevel="chaman" values={1,1,2,2,...,10,10}` = `ceil(nivel/2)`; **Ataque Adicional** (Mejora L6) = `flag extraAttack`; **Afinidad Tierra** ya era `saveProf Constitucion` y **Competencia Adicional (marciales)** (Mejora L3) ya era `weaponProf marciales`. Informativo a proposito: Afinidad Aire = `flag initiativeProfBonus` (suma el bonus de COMPETENCIA a la iniciativa: `HarfordDnDCalc.GetInitiativeBonus` y el panel añaden `+PB` si el flag esta activo; reutiliza el mecanismo `flag`/`HasFlag`), Agua (conjuros extra), poderes totemicos, resistencias elementales de L9, y todo lo de Elemental/Restauracion (spell-gated). Afinidad Fuego ya esta mecanizada como `conditionalWeaponDamage.flatBonus="pb"` con tipo fuego. **Sacerdote** (lanzador puro): casi todo spell-gated -> informativo. Mecanizado: **Ecos de Fe** (L2) = recurso `light_point` ("Puntos de Fe", recarga "long") con `resourceMax perClassLevel="sacerdote" perLevel=1` = nivel (2 a L2, igual progresion que el Mago; el rasgo se desbloquea en L2 asi que `perLevel=1` reproduce la tabla). **Competencia Adicional (Religion)** (Sagrado L1) ya era `skillExpertise Religion`. Informativo a proposito: Lanzamiento de Conjuros, Absolucion (gasta puntos de fe, spell-gated), Restauracion de los Fieles (recupera 2/3/4 puntos en descanso corto desde L5 — ver nota de `light_point` en recarga), Himno Divino, Forma de Sombra (Carisma a CA SOLO durante la forma temporal, no permanente), Legado del Vacio (daño psiquico en truco), y todo Disciplina/Sagrado/Sombra spell-gated. **Brujo** (lanzador de pacto): casi todo spell-gated -> informativo. Mecanizado: **Fragmentos de Alma** (L3) = recurso `soul_shard` ("Fragmentos de alma", recarga "long") con `resourceMax perClassLevel="brujo" values={0,0,3,3,3,3,3,3,5,5,...}` (max 3, sube a 5 a L9; el +1 en descanso corto y la creacion por reaccion al morir una criatura son gestion manual). Informativo a proposito: Hechiceria Vil (ranuras de pacto), Toque de Vida (X/dia, spell-gated, pierde PG), Secretos Profanos (competencia Carisma SOLO con demonios = condicional), Conocimiento Demoniaco/minion, Forjado de Almas, y todo Afliccion/Demonologia/Destruccion (maldiciones/demonios/fuego spell-gated). **Mago** (lanzador puro): casi todo es spell-gated -> informativo. Mecanizado: **Fuente de Magia** (L2) = recurso `mage_point` ("Puntos de Hechicería", recarga "long") con `resourceMax perClassLevel="mago" perLevel=1` = nivel de Mago (la tabla del manual es puntos=nivel para L2-20; el rasgo se desbloquea en L2 asi que `perLevel=1` reproduce la tabla exacta). **Brillantez Arcana** (Arcano L6) ya era `skillExpertise Arcano`. Informativo a proposito (dependen del sistema de conjuros no modelado): Cargas Arcanas, Racha de Calor, Cauterizar, Congelacion Cerebral, Metamagia y sus opciones, Formulas de Trucos, Desplazamiento Temporal, Dedos de Escarcha. **Cazador** (hasta L6): Estilo de Combate (Tiro con Arco +2 / Tirador +1 / Dos Armas / Gran Arma) ya cableado; **Marca del Cazador** (L1) = `conditionalWeaponDamage id="hunters_mark" count=1 die=4 scaleClassId="cazador" dieScale={{6,6},{11,8},{16,10}}` (toggle de daño condicional; el "1/turno" lo gestiona el jugador como en Furtivo); **Explorador Natural** (L1) = `initiativeAbility ability="Sabiduria"` (las ventajas situacionales y de viaje quedan informativas); **Enfoque** (L2) = recurso `focus` ("Enfoque", recarga "short") con `resourceMax perClassLevel="cazador" values={0,2,3,3,4,4,5,5,6,6,7,7,8,8,8,9,9,9,10,10}` (tabla exacta del manual). `caz_sup_estudiante` ya era `skillExpertise Supervivencia`. **Informativo a propósito** (condicional a estado no modelado): los rasgos "Lobo Solitario" (crítico 19-20 / ataque extra **sin compañero bestial**) y toda la mecánica de mascota (Maestro de Bestias, Domar Bestia, Comando de Matar) — no se mecanizan porque el addon no rastrea si el cazador tiene companion, y aplicarlos daría ventajas falsas a un Maestro de Bestias. **Critico ampliado**: `GetWeaponCritThreshold(isMelee)` devuelve la tirada minima de critico (20 por defecto; `min(any, melee)` si `isMelee`). `DoWeaponAttack` recalcula el `critTag` con ese umbral via `HarfordDnDCalc.GetCritTag(mode, a, b, threshold)` solo para armas `mode=="Melee"` (respeta ventaja/desventaja y la pifia). Implementado: Caballero de la Muerte "Maquina de Matar" (subclase Escarcha, `id=escarcha`, L3) = `{ kind="critRange", value=19, melee=true }`, `type="pasivo"` (activo por defecto al tener esa subclase a nivel 3+). El critico ampliado tambien marca `pendingWeaponCriticalKey` -> el siguiente `Daño Arma` maximiza dados. **Competencias (5 categorias)**: salvacion (`saveProf`), habilidad (`skillProf`/`skillExpertise`), **armadura** (`armorProf`; claves `ligera`/`media`/`pesada`/`escudo`), **arma** (`weaponProf`; claves `sencillas`/`marciales`/`armas de fuego` o arma concreta) y **herramienta** (`toolProf`; clave libre, ej. "Herramientas de cervecero"/"Equipo de envenenador"/"Herramientas de artesano/joyero/armero"). Base de clase tambien via `classDef.toolProfs` (mismo patron que armorProfs/weaponProfs). Base de la CLASE via `classDef.armorProfs`/`classDef.weaponProfs` (union de todas las clases en multiclase; las salvaciones solo de la primera). Raza/trasfondo/dote añaden via efectos `armorProf`/`weaponProf`. Consulta: `HasArmorProf`, `HasWeaponProf`, `HasToolProf`, `GetArmorProfs`, `GetWeaponProfs`, `GetToolProfs`, `GetProficiencies` (instantanea `{armor, weapon, tool, saves, skills}`). El panel `Ficha` (detalles) muestra una fila "Herramientas" con `GetToolProfs(name)` si hay alguna. Cableadas: Envenenador (Pícaro Asesino), Cervecero (Monje), Ingenieria Gnomica/Goblin (artesano), Tallado de Gemas (joyero), Familiaridad Mecanica (armero). **Las 12 clases ya tienen `armorProfs`/`weaponProfs` pobladas desde el manual** (claves de armadura `ligera/media/pesada/escudo`; armas `sencillas/marciales/armas de fuego` + armas concretas tipo `gujas`, `espadas cortas`, `ballestas de mano`, etc.). Los "Entrenamiento con armas" de razas YA son `weaponProf` (via helper `WeaponProfEffects`), y las resistencias raciales permanentes YA son `resist` (Enano Hierro Negro, Draenei, Tauren Taunka, Troll de Hielo, Renegado). **Competencias en el panel**: la vista `details` pinta UNA fila "Competencias" con armadura y armas en el valor y el desglose completo (Armadura/Armas/Herramientas) en el tooltip. Es una sola fila a proposito: las filas de detalle comparten el espacio con la barra de "Salvaciones" (fija en `-206`), asi que una fila por categoria desbordaria sobre ella. **Modificadores de caracteristica (ability) = de CREACION, no live**: los efectos `bonus ability` (incrementos de raza/trasfondo/dote) se enrutan a un bucket aparte `creationBonus.ability` y **NO se suman a la puntuacion en vivo** (`GetBonus("ability")` devuelve solo el bucket live `bonus.ability`, reservado para bonos/penalizaciones de **estado/objeto**, vacio por ahora). Motivo: al cargar una ficha (TRP3) los incrementos de raza ya vienen horneados en la puntuacion nativa; volver a sumarlos los duplicaria y los mostraria erroneamente en el tooltip de caracteristica. `GetCreationAbilityBonus(key)` expone el bucket de creacion y **lo consume `HarfordCharacterCreation.Apply`**: al crear una ficha, las caracteristicas se guardan HORNEADAS (base asignada + incrementos de raza/subraza/trasfondo/dote + Mejoras de Caracteristica elegidas), igual que las que llegan del About en `/harford cargarficha`. Se aplica DESPUES de `ReplaceCreation` (raza/trasfondo/dotes/choices ya fijados) y el valor horneado se escribe tambien en `draft.abilities` para que el About TRP3 muestre la misma puntuacion que la ficha. **No sumar el bono en `BuildCreationDraft`**: el asistente ya lo muestra sumado via `RaceAbilityBonus` y hacerlo alli lo contaria dos veces (ahi SI se aplicaran sobre la puntuacion base). En el tooltip de caracteristica del panel (`AbilityTooltipTitle`) el `(base+bonus)` solo refleja el bono live (estado/objeto), coloreado verde/rojo; los modificadores de raza no aparecen. Esta capa **suma sobre valores manuales** y no escribe permanentemente en `ARCGET/ARCSET`; los recursos maximos derivados solo afectan al calculo visual/runtime. **Memoizacion**: `Resolve(profileName)` se cachea por perfil con un contador de `generation`; se reconstruia entero en cada `GetBonus`/`HasSaveProf`/`GetSkillRank`/`GetAbilityScore` (decenas de veces por refresh, cada uno recorriendo features + equipo). `API.Invalidate()` sube la generacion y lo llaman los setters de `HarfordDnDProgression` (via `Touch()`), los de `HarfordDnDItems` (equip/unequip/basic/setEquipment/`RefreshPending`) y `SetInspectData`/`ClearInspectData` de ambos. No leer la tabla resuelta y mutarla (es compartida). **Salvaciones base de clase**: `Resolve` aplica ademas las `classDef.saves` de la **primera** clase de `classLevels` como `saveProf` (regla 5e: en multiclase solo la primera clase otorga sus salvaciones). Se suma al flag manual de salvacion en `HarfordDnDCalc` (no marca el checkbox; suma PB al calculo). **Choices**: por cada rasgo activo con `choice`, `Resolve` aplica los efectos de la(s) opcion(es) elegida(s) (`HarfordDnDProgression.GetChoice(featureId)` → optionId por slot; `HarfordDnDBook.GetChoiceOption`). La progresion guarda `choices[featureId] = { optSlot1, ... }` (`SetChoiceSlot`/`GetChoice`), viaja en el sync `DNDCLASS` (seccion `h=`, slots por `~`) y se elige en `HarfordCharacterPanel` > `Subida` con un dropdown por slot bajo cada rasgo. **Repeticion de opciones**: solo las elecciones `optionsFrom = "ability+N"` (Mejora de Caracteristica, incrementos de dote) admiten la MISMA opcion en dos slots — es el "+2 a una caracteristica" del manual, y tanto `Resolve` como la previsualizacion de creacion iteran la lista con `ipairs`, asi que el efecto se aplica dos veces. El resto (metamagia, estilos de combate, habilidades, herramientas) NO se puede duplicar: el dropdown del panel oculta las opciones ya elegidas en otro slot y el dialogo de creacion funciona como toggle. En el dialogo de creacion, las repetibles muestran el contador (`[X2]`) y, sin slots libres, un click sobre una opcion ya elegida la libera entera. **Pericia** (`optionsFrom = "skillExpertise"`): el dropdown del panel solo ofrece habilidades en las que YA se es competente (regla 5e), consultando `HarfordDnDFeatureEffects.GetSkillRank`; si aun no hay ninguna competente muestra todas antes que un menu vacio. El filtro vive en la UI y NO en `GetChoiceOptions`: el Libro es capa de datos y `HarfordDnDProgression` lo llama durante la importacion TRP3, asi que no debe depender del motor de efectos.
- Nota posterior: las resistencias/inmunidades/vulnerabilidades de jugador ya no se tratan como busqueda de rasgos en caliente. `HarfordDnDFeatureEffects.Resolve` crea una lista derivada por perfil (`damageStatusCache`); `HarfordDamageMitigation.ForTarget` solo consulta esa lista, con `Prime` de emergencia si el perfil aun no habia sido resuelto en la sesion. Para jugadores remotos sin snapshot Harford, `HarfordDnDProgression.SetInspectDataFromTRP3Sheet` puede materializar una progresion efimera desde el About TRP3 (sin persistir) y poblar esa misma lista; ejemplo: Caballero de la Muerte L3+ => `veneno = resistant`.
- **Dados de Golpe** (`HarfordDnDHitDice`, definido al final de `Harford/DnD/State/HarfordDnDProgression.lua`): pool DERIVADO del nivel/tipo de dado de cada clase (`classDef.hitDie`), sin estado propio salvo lo gastado. `GetPoolByDie(profile)` = `{[sides]=suma de niveles de clases con ese hitDie}` (multiclase = varios tipos); `GetSpent`/`GetAvailable`/`GetTotalMax`/`GetTotalAvailable`/`GetSummaryList` (lista ordenada dado mayor primero `{sides,max,available}`)/`GetSummaryText` ("3d8 + 1d10 (N disp.)"). `SpendDie(sides, profile)` gasta uno si hay disponible. `RegainOnLongRest(profile)` recupera `floor(total/2)` (min 1) dados, de mayor a menor tipo (regla 5e). Persistencia: `HarfordDnDPersistStore.hitDice[profileName].spent = {[sides]=n}`. **`ApplyShortRest` (HarfordDnD.lua) ya NO auto-cura** (antes curaba la mitad de la vida): solo recupera recursos de descanso; la curacion va por gasto de dados de golpe. **`ApplyLongRest`** sigue curando vida full + rellena recursos + llama `RegainOnLongRest`. El menu de descanso (`RestMenu`) muestra "Descanso corto" (no cierra, recupera recursos) / "Descanso largo" (cierra) y, debajo, hasta 4 botones por tipo de dado (d12/d10/d8/d6) que `RefreshRestMenu` posiciona/etiqueta `dX (avail/max)` y deshabilita sin disponibles. `RollHitDieHeal(sides)` (HarfordDnD.lua, forward-declared) gasta el dado, cura `dX + Mod. Constitucion` (min 1) via `AdjustResourceCurrent("health", ...)` y difunde una tirada `type="heal"` ("Dado de Golpe dX (cura)"); solo en ficha de jugador propio (no `SheetContext.active`). Estos botones tambien cubren el "Segundo Aliento" del Guerrero (gasta un dado de golpe). El panel `Ficha` (detalles) muestra una fila "Dados de Golpe" con `GetSummaryText` si el pool > 0. No persiste por red (es derivado del nivel; lo gastado es local).
- **Usos de rasgos** (`HarfordDnDFeatureUses`, al final de `Harford/DnD/State/HarfordDnDProgression.lua`): contador ligero para rasgos "X/descanso" cuyo EFECTO no se modela pero el numero de usos si (Sentido Divino, Sentir Demonios, Marca de Ursol, Tambaleo, Cauterizar, Eco de los Elementos, etc.). Un rasgo se rastrea declarando en `HarfordDnDBook`/`Races`/`Feats` un campo `uses = { max=<N|spec>, recharge="short"/"long" }` (INDEPENDIENTE de `type`/`effects`; el rasgo sigue siendo `informativo`). `max` numerico = fijo; si no, se calcula `base + Mod(ability) + perClassLevel*perLevel` acotado a `>= min`; `proficiencyBonus=true` suma el bonificador de competencia (ej. Marca de lo Salvaje). API: `GetMax(uses, profile)`, `GetTracked(profile)` (lista `{featureId,name,max,spent,available,recharge}` de rasgos desbloqueados con `uses`), `GetSpent`/`SetSpent`, `Spend`/`Restore`, `ResetOnRest(restType, profile)` ("short" recupera los `recharge="short"`, "long" recupera todos). Persistencia: `HarfordDnDPersistStore.featureUses[perfil][featureId] = gastados`. **Solo para el perfil ACTIVO** (el max dinamico usa `HarfordDnDCalc.GetAbilityMod` del jugador). UI: el resumen `Rasgos` de `HarfordCharacterPanel` NO muestra contadores `[X/Y]`; los usos se muestran y se gastan desde la pestaña **Libro** en el subtexto/tooltip del boton (`Usos disponibles/max · Descanso corto|Descanso largo`). Los botones del Libro bloquean el uso/preparacion si no quedan usos; se ocultan en inspeccion. Reset cableado en `ApplyShortRest`/`ApplyLongRest` (HarfordDnD.lua). No promover estos contadores a barras de recurso del unitframe (saturarian); el recurso solo es para pools de clase centrales (chi, furia, etc.).
- **Indicador de rasgos sin mecanizar** (`HarfordDnDBook.GetUnmechanizedReason(feature)`): para clases, razas, dotes y trasfondos (mismo formato de feature). Devuelve `nil` si el rasgo ESTA mecanizado (tiene `effects`, `uses` o `choice`); si no, deduce de la descripcion el MOTIVO por el que sigue en `informativo` (heuristica con normalizacion de acentos/ñ; **solo informativa para la UI, no afecta a calculos**). Categorias: vision en la oscuridad, idiomas, arma natural, bono de PG por nivel total, sistema de conjuros, reaccion sobre daño entrante, ventaja/desventaja situacional, pericia situacional, movimiento/tamaño/terreno, limite por turno, o "narrativo/situacional" por defecto. La lista de rasgos de `HarfordCharacterPanel` > `Subida` marca esos rasgos con `(sin mecanizar)` y muestra el motivo completo en el tooltip al pasar el raton. Estado actual: ~176/331 rasgos mecanizados. Al añadir mecanica a un rasgo (efecto/uses/choice) el indicador desaparece solo. Si un motivo nuevo merece su categoria, añadir la rama de keywords en `GetUnmechanizedReason` (keywords ya normalizados: sin acentos y con ñ→n).
- Sync de progresion/equipo: `HarfordSync` usa opcodes separados dentro del prefix `DND5EARC`. `DNDCLASS` sincroniza progresion y soporta chunks `DNDCLASSC`; sus secciones incluyen clases (`c=`), elecciones (`h=`), raza (`r=`), trasfondo (`b=`/`bd=`), dotes (`d=`), mana (`m=`) y estados activables activos (`s=`). `DNDEQUIP` sincroniza equipo virtual como `slotKey=i:<itemLink>,w:<basicWeaponKey>,a:<basicArmorKey>` y soporta chunks `DNDEQUIPC`. Ambos se envian junto a la ficha en `BroadcastConfig`, `BroadcastConfigForPlayer` y `BroadcastAll`. Receptores antiguos ignoran opcodes desconocidos. **Inspeccion**: las funciones `SerializeDnD*`/`SendDnD*`/`Deserialize*`/`Receive*Chunk` estan **parametrizadas por opcode**; la inspeccion reusa el mismo cuerpo con los opcodes `DNDINSCLASS`/`DNDINSEQUIP` (chunks `DNDINSCLASSC`/`DNDINSEQUIPC`). Los receptores de chunk parsean el primer campo `opcode` y aceptan solo los pares exactos (`DNDCLASSC`/`DNDINSCLASSC`, `DNDEQUIPC`/`DNDINSEQUIPC`); no usar patrones abreviados tipo `DND[A-Z]-...` porque no casan con estos opcodes. `Deserialize*` devuelve un 3er valor `isInspect` (`true` para los opcodes INS) para que el receptor cachee en vez de importar. `EscapeProgressionText` ahora tambien escapa `~` (delimitador de tokens) para texto libre como la desc de trasfondo personalizado.
- Contrato `HarfordDnDWeapons` (`Harford/DnD/Data/HarfordDnDWeapons.lua`): `HarfordDnDWeapons.WEAPONS` (tabla de armas) + helpers `ParseDice`, `GetVersatileDice`, `WeaponBaseDice`, `WeaponPropsLabel`, `GetWeaponMenuGroups`. Los que dependen del flag "Versatil" lo leen via `HarfordDnDContext.Get`. `GetWeaponAttackAbility` se queda en HarfordDnD.lua porque necesita modificadores de caracteristica.
- Contrato `HarfordDnDCalc` (`Harford/DnD/Engine/HarfordDnDCalc.lua`): calculo puro, sin UI, leyendo via `HarfordDnDContext`. Funciones: `AbilityMod`, `RollDie`, `RollD20`, `GetPB`, `GetSpellPB` (PB de conjuro NPC), `GetMode`, `GetMiscBonus`, `GetAbilityScore`, `GetAbilityMod`, `GetSaveProf`, `GetWeaponMod`, `GetWeaponAttackBonus`, `GetWeaponDamageBonus`, `GetVersatileActive`, `GetSkillProfBonus`, `GetSkillRollBonuses`, `GetSaveRollBonuses`, `RollTextWithMode`, `GetCritTag`, `BonusConcat`. HarfordDnD.lua las llama como `HarfordDnDCalc.X(...)`. `GetPB` usa la progresion total si existe y cae a `BonusCompetencia` manual si no hay progresion. `toN`/`fmtSigned`/`ColorSigned` siguen viviendo como locales en HarfordDnD.lua (muy usadas); Calc tiene copias privadas triviales de `toN`/`fmtSigned`.
- Contrato `HarfordDnDNet` (`Harford/DnD/Engine/HarfordDnDNet.lua`): capa de recursos/red. `BuildActiveResourcePayload`, `ExportCurrentResources`, `ExportProfileResourcesFromBank`, `GetRemoteResourceValue`, `RemoteResourceExists`, `SendResourceResponseTo`, `SendResourceResponseForProfileTo`, `RequestResourcesFromPlayer` (throttle interno 12s), `SendResourceAdjustToPlayer`. `HarfordDnDAPI.GetCurrentResources/GetResourcesForName/RequestResourcesForName/AdjustResourceForName` delegan aqui; las firmas publicas NO cambian. `BuildActiveResourcePayload` añade tambien `ArmorClass` al payload runtime para que otros clientes puedan resolver la CA de jugadores desde cache remota cuando exista. La APLICACION local de deltas (`AdjustResourceCurrent`, `ApplyResourceDeltaFromRemote`, aura de muerte, refresh de frames) se queda en HarfordDnD.lua.
- Contrato `HarfordDnDCombat` (`Harford/DnD/Engine/HarfordDnDCombat.lua`): reglas de combate que necesitan contexto de unidad, por tanto NO pertenecen a `HarfordDnDCalc` (calculo puro) ni a `HarfordDnDRolls` (solo serializacion/render). API inicial: `GetArmorClassForUnit(unit)`, `GetRemoteArmorClassForUnit(unit)`, `GetProfileArmorClassForUnit(unit)`, `SetArmorClassForUnit(unit, value)`, `IsCriticalRollTag(critTag)`, `ResolveArmorClassOutcome(total, critTag, unit)`, `ApplyWeaponDamageToNpc(total, isCritical)` y `ApplyWeaponDamageToTarget(total, isCritical)`. Defensa al fallar: `SetNpcCombatMode(guid, modeKey)`, `GetCombatModeForGuid(guid)`, `PlayLocalDefense()`, `TriggerDefenseOnMiss(defenderUnit)`. Ataque/herida: `RunAttackSequence(opts)`, `TriggerWoundOnHit(defenderUnit, isCritical)`, `PlayLocalWound(isCritical)`. Puede consultar `HarfordDnDContext`, `HarfordDnDResources.RemoteCache`, `HarfordTurnOrderAPI`, `HarfordTRP3`, `HarfordAuthority`, `HarfordSync`, `HarfordServerActions`, `HarfordEmotes` y `HarfordActionSequence`.
- Contrato `HarfordDnDArea` (`Harford/DnD/Engine/HarfordDnDArea.lua`): motor core efimero de areas, sin SavedVariables ni deteccion automatica de distancias. `Open` captura definicion/actor; `AddCurrentTarget` marca por GUID hasta 40; `Resolve` tira una vez el daño base y resuelve defensa por victima. Jugadores reciben `DNDAREAREQ` individual y aplican localmente salvacion/CA -> mitigacion -> reaccion -> vida temporal -> salud; responden `DNDAREARES` con deduplicacion TTL. NPC quedan en cola y solo se aplican al targetear el GUID exacto mediante `HarfordDnDCombat`/`HarfordServerActions`. No usar ticker/OnUpdate: solo `PLAYER_TARGET_CHANGED` y timers one-shot de timeout. Las formas (`cone/sphere/line/other`) son informativas. **`context.autoResolve`**: para objetivo unico (`sizeText="Objetivo"`) `Open` NO muestra la ventana — marca el target actual y resuelve al instante (fallback a ventana si no hay objetivo valido); el area real sigue abriendo ventana. El descriptor puede declarar `conditionId`, `conditionDuration`, `conditionTurns`, `conditionSaveAbility`, `conditionSaveDC` y `conditionPersist`; estos datos viajan anexados de forma compacta y compatible con los `DNDAREAREQ` antiguos. Cuando una peticion de area aplica condicion, viajan tambien `sourceGuid` y `sourceName` para que un NPC atacante no quede registrado como si la fuente fuera el DM que transporta el whisper. **Condicion pura sin daño**: `NormalizeDefinition`/`ValidateIncomingRequest` aceptan `damageComponents` vacio SI hay `conditionId` (la red transmite componentes "" -> {}); `Resolve` omite la tirada de daño compartida si no hay componentes. `ValidateIncomingRequest` convierte y acota defensivamente CD, ataque total, daño y maximos antes de resolver; no asumir que el deserializador ya dejo tipos seguros. Asi un conjuro de control aplica solo el estado en fallo de salvacion (Player y NPC). El Libro declara `feature.area`; Admin convierte lineas TRP3 estrictas (`Area`, `Salvacion`, `Exito`, `Impacto`, `Estado`) a `action.area`; `Impacto` es opcional si el area tiene `Estado`, permitiendo areas de control puro. Metadatos opcionales de estado: `Duracion: 2 rondas`, `Duracion: fin del siguiente turno de la fuente`, `Duracion: inicio del turno del objetivo`, `Salvacion final: Constitucion CD 14` y `Persistencia: si`. Una salvacion de area necesita `Exito: mitad` o `Exito: niega`; una duracion desconocida invalida el area y nunca se infiere desde prosa narrativa. Las caracteristicas aceptan nombre o abreviatura y se canonizan en el motor. Prueba manual: `/harford debug run areatest save|attack [state]`.
- Nota actual de `HarfordDnDArea`: el motor puede auto-marcar **jugadores** con `C_Epsilon.GetPosition()` via `DNDAREAPOSREQ`/`DNDAREAPOSRES`. Estas peticiones de posicion solo se envian y responden por `PARTY`/`RAID`; nunca se usa `GUILD` como fallback para coordenadas. Si el origen es NPC, `HarfordAdmin` aporta la posicion del NPC origen con `.npc info` mediante `SetNpcPositionProvider`; el core no ejecuta comandos servidor. Geometria soportada: `sphere/circle`, `cone`, `line`, `square/cube`, `rectangle`; X/Y son la base y Z solo filtra por altura maxima. Para cono/linea/rectangulo, el target/focus jugador actual se usa como direccion antes de pulsar `Auto jugadores`; circulo/cuadrado usan la posicion del lanzador o del NPC origen. Los NPC victima siguen entrando por marcado manual/GUID salvo que se implemente un escaneo dedicado de NPCs visibles.
- Seguridad de mensajes sensibles: `RADJ`, `DNDAREAREQ`, `DNDCOND`, `DNDCONDSTATE`, `DOAPPLYAURA`, `DODEFENSE`, `DOWOUND`, `DOSAVE` y `AURASIG` (senal de aura de maniobra, ej. Desarme, que ejecuta `.au <id> self`) solo se aceptan si el `sender` se puede resolver como el propio jugador, una unidad visible (`target/focus/mouseover/...`) o miembro del grupo/raid mediante `HarfordClassColors.FindUnitByName`. No es una firma criptografica de DM, pero evita aplicar daño/condiciones desde whispers anonimos o nombres que el cliente no reconoce. No usar `GUILD` como fallback para mensajes que apliquen efectos mecanicos directos.
- Contrato `HarfordDnDConditions` (`Harford/DnD/Engine/HarfordDnDConditions.lua`): fuente unica de condiciones mecanicas. Cada definicion usa `tracking="aura"` (consulta `UnitAura` y normalmente no guarda nada), `tracking="aura_state"` (aura autoritativa + metadatos) o `tracking="state"` (estado Harford para condiciones sin aura). Una condicion `aura` se promociona dinamicamente a registro de metadatos solo si la instancia trae duracion, turnos, salvacion final o persistencia; una aplicacion manual sin esos datos sigue siendo aura pura. API principal: `GetActive`, `Has`, `ApplyOwned`, `RemoveOwned`, `ApplyToUnit`, `RemoveFromUnit`, `CanPerform`, `ResolveRollMode`, `IsSaveAutoFailed`, `IsSpeedZero`, `GetDamageStatus`, `OnDamageTaken`, `OnTurnChanged`. Solo persiste dentro de `HarfordDnDPersistStore.conditionStates` cuando la definicion/instancia lo exige; caches remotas y NPC son runtime, limitadas y con TTL. Red compacta: `DNDCOND`, `DNDCONDRES`, `DNDCONDSTATE`; `DOSAVE` conserva sus campos historicos y puede anexar condicion/duracion/fuente (`sourceGuid` + `sourceName`) para maniobras nuevas. Solo viajan IDs conocidos y metadatos acotados, nunca efectos ni comandos. Las condiciones intervienen en `HarfordDnDCalc`, `HarfordDnDCombat`, areas, maniobras, reacciones, movimiento y turnos. `Garrote`, `Mutilar`, `Exponer Armadura` y `Desarme` usan `conditionId` manteniendo su `auraId` como compatibilidad visual/cliente antiguo. No usar ticker/OnUpdate. Debug: `/harford debug run conditiontest list|apply ID|remove ID`.
- Contrato `HarfordAdminConditions` (`HarfordAdmin/HarfordAdminConditions.lua`): unico adaptador DM para aplicar/quitar condiciones. Jugadores reciben señal core y se actualizan en su propio cliente; el core delega aqui `applyAura/removeAura` de NPC para que Harford sin Admin no ejecute herramientas DM. Los NPC se validan por GUID, usan `HarfordAuras`/`HarfordServerActions` y guardan solo metadatos necesarios. Las retiradas NPC pendientes de una expiracion se ejecutan al volver a targetear el GUID, mediante `PLAYER_TARGET_CHANGED`, sin ticker, y caducan a los 60s para no acumular GUIDs si el NPC no vuelve a seleccionarse. Si una salvacion al final del turno no pudo resolverse porque el NPC no estaba visible, core la marca pendiente y Admin pide resolverla al seleccionar exactamente ese GUID; solo entonces puede retirar la aura. `HarfordAdminUnitMenu` genera Estados desde el catalogo core; no recrear otra tabla `ESTADOS`.
- **Aplicacion de daño del jugador (`ApplyWeaponDamageToTarget`)**: punto unico que usan `DoWeaponAttack` (auto-daño al impactar), el boton `Daño Arma` y `Daño Custom`. Contra un NPC delega en `ApplyWeaponDamageToNpc` (ruta oficial `IsOfficerPlus` + `SetNpcHealthDelta`, daño en bruto). **Contra otro jugador** envia `RADJ` por `HarfordSync.SendResourceAdjust` (`DND5EARC`): consume primero `temp_health` segun la cache remota y el resto a `health`; si no hay cache, manda todo a `health` y solicita recursos para futuras tiradas. Nunca aplica daño a uno mismo. El receptor aplica el delta y su propia aura de muerte. No re-mitiga (la mitigacion R/V/I solo aplica a victimas NPC y ya se hizo en `RollWeaponDamage`/`RollCustomDamage`). **Deuda tecnica/futuro**: esta division `temp_health`/`health` en el EMISOR se mantiene por compatibilidad con clientes antiguos, pero no es el modelo correcto para reacciones. No hay rasgos actuales que deban saltarse vida temporal. La evolucion correcta es un opcode nuevo de daño bruto a jugador (p.ej. `DMG|amount|...`) para que el RECEPTOR aplique: reaccion preparada/mitigacion local -> `temp_health` -> `health`. No sustituir `RADJ` hasta poder convivir con versiones antiguas.
- **Botones de daño = Daño Custom** (frame parametrizado por unidad): el frame de daño custom (`HarfordDnDStore.OpenCustomDamageFrame(applyUnit)`) acepta `applyUnit` (`"target"` o `"focus"`). `ApplyCustomDamage` valida esa unidad, mitiga contra ella (`RollCustomDamage(..., mitigationUnit)`) y aplica: `"focus"` → `HarfordDnDCombat.ApplyActionDamageToFocus` (**en nombre del NPC** porque la tirada usa el contexto NPC activo): focus = mi propio PJ → daño local (`HarfordDnDStore.ApplyLocalResourceDamage`); focus = otro jugador → RADJ; focus NPC → no aplica. `"target"` → `ApplyWeaponDamageToTarget`.
  - **Jugador**: el boton de daño es **siempre "Daño Custom"** (sin el toggle Shift): el daño de arma al impactar ya esta automatizado en `DoWeaponAttack`, asi que el boton solo abre el frame custom sobre `target`.
  - **Ficha NPC**: el boton `Atacar` se habilita **con un focus victima valido** (existe y no es el propio NPC = target); **SI se permite que el focus sea mi propio PJ** (el NPC puede atacar a mi personaje → daño/herida/defensa en local). El boton de daño pasa a ser **"Daño Custom"** sobre `focus`. El panel se refresca en `PLAYER_FOCUS_CHANGED`/`PLAYER_TARGET_CHANGED` (`RefreshSheetActionPanel`). El antiguo flujo de daño de accion al `target` (`onDamageRolled`/`SetNpcHealthDelta` desde el boton) se retira; el daño de ataque al focus jugador sigue siendo automatico al impactar.
- **Etiqueta del ataque NPC**: `RollActionAttack` emite `"Ataque <NOMBREFOCUS> <link de la accion>"`. El `NOMBREFOCUS` se resuelve con la logica habitual de nombre/color (`GetFocusColoredName`): nombre RP TRP3 (`HarfordTRP3.GetUnitRPName`, fallback nombre WoW) coloreado por el color de nombre TRP3 (`GetUnitNameColor`: companion `NH` / player `CH`) y, si no hay, por color de clase (`HarfordUnitFrames.GetClassColor`).
- **Auto-daño del ataque NPC al focus jugador**: en la ficha NPC, `RollActionAttack` con un `focus` jugador (incluye mi propio PJ) y CA resuelta enruta por `RunAttackSequence(family=nil, defenderUnit="focus", npcAttacker=true)`. En el impacto (delay fijo ~0.4s; el swing del NPC lo da `onAttackAnimation` del boton Atacar): si impacta, `onImpactOnce` tira el daño de la accion (`RollActionDamage(action, isCritical, "focus")` → sin mitigacion, el focus es jugador) y lo aplica con `HarfordDnDCombat.ApplyActionDamageToFocus` (RADJ temp/health al nombre del focus); ademas se despacha herida (`DOWOUND`) o, en fallo, defensa (`DODEFENSE`) al focus. **Ya no hace falta tirar el daño a mano** contra un jugador en focus. El focus NPC NO se daña por esta via (los `.npc` actuan sobre el target); mantiene el boton `Daño` manual sobre el target. `RollActionDamage` acepta `mitigationUnit` (por defecto `"target"`) para mitigar contra la unidad correcta. La CA del ataque NPC ya se resuelve y muestra contra el focus (`GetActiveArmorClassUnit` → `focus` si existe; refresco en `PLAYER_FOCUS_CHANGED`).
- **Combate NPC vs NPC (asincrono, dos fases)**: como los `.npc` (daño/herida/esquiva via `SetNpcHealthDelta`/`SetNpcEmote`) solo actuan sobre el **target**, y en el ataque NPC la victima es el **focus**, el flujo se parte en dos. **Fase 1 (atacar)**: target = NPC atacante (su ficha), focus = NPC victima. `RollActionAttack` tira vs CA del focus; si el focus es NPC (no jugador) guarda `HarfordDnDStore.pendingNpcAttack = { guid=GUID(focus), action, isCritical, hit }` y avisa por chat; el swing del atacante lo da `onAttackAnimation` del boton Atacar. Un nuevo ataque descarta el pendiente anterior. **Fase 2 (al targetear a la victima)**: el handler de `PLAYER_TARGET_CHANGED` llama `HarfordDnDStore.ResolvePendingNpcAttack()`; si el target actual (NPC, no jugador) coincide con `pendingNpcAttack.guid`: acierto → `RollActionDamage(action, isCritical, "target")` (mitigado contra la victima) + `HarfordDnDCombat.ApplyWeaponDamageToNpc(total, isCritical)` (→ `SetNpcHealthDelta` con su herida 33/34); fallo → `HarfordDnDCombat.TriggerDefenseOnMiss("target")` (esquiva/parry del NPC victima, que ahora SI es el target). El pendiente se consume siempre. La aplicacion a NPC va gateada por el eje Oficial (`IsOfficerPlus` dentro de `ApplyWeaponDamageToNpc`/`TriggerDefenseOnMiss`); el core NO comprueba modo DM. **Coexiste** con el flujo Shift+click (`npcSourceGuid` + `Daño` manual sobre el target), que no se toca. `pendingNpcAttack` es solo runtime (no persiste ni viaja por red).
- **Reaccion defensiva al fallar el ataque (parry/dodge/block, aleatoria)**: cuando un ataque que resuelve CA NO supera la CA (`hit == false`), el **defensor** ejecuta parry/dodge/block **elegido al azar** entre las opciones de su postura (`HarfordEmotes.PickDefenseSeq`). Lo orquesta `HarfordDnDCombat.TriggerDefenseOnMiss(defenderUnit)`, llamado desde `DoWeaponAttack` (defensor `"target"`) y `RollActionAttack` de la ficha NPC (defensor `"focus"`). `DoSpellAttack` NO resuelve CA y no dispara defensa. El defensa se elige **al azar** entre las opciones de la postura (`HarfordEmotes.PickDefenseSeq(modeKey, hasShield)`): `one_hand`/`two_hand`/`polearm` → {parry, dodge}; `unarmed` → {block(fist), dodge}; arco/rifle/hechizo/arrojadiza → {dodge}; **sin modo conocido → se asume arma a una mano → {parry, dodge}** (default). Con escudo (solo defensor jugador) → {block, dodge}. Solo runtime, no se persiste.
  - **La misma secuencia (`def.seq`) maneja ambos casos** (jugador y NPC); difiere solo el transporte del anim. Principio: ejecutar en el cliente destino siempre que se pueda.
- **Ataque con preset sincronizado al impacto (`RunAttackSequence`)**: `DoWeaponAttack` (atacante jugador) llama a `HarfordDnDCombat.RunAttackSequence{ family, critical, offhand, hit, defenderUnit, npcAttacker, onImpactOnce }`. Corre el preset de ataque de la familia (`HarfordEmotes.GetAttackSequence`) con `interceptImpact`; en el instante de impacto del preset ejecuta UNA vez `onImpactOnce` (el daño: `RollWeaponDamage` + `ApplyWeaponDamageToTarget`) y despacha la reaccion del objetivo: `hit==true` → `TriggerWoundOnHit`; `hit==false` → `TriggerDefenseOnMiss`. El **daño es mecanico y se aplica siempre**; el swing y la reaccion son **animaciones gateadas por el flag**. Si el atacante tiene animaciones off (o no hay familia/preset), `impact()` se ejecuta de inmediato (daño ya; reaccion segun gates de cada lado). Armas sin preset melee (arco/rifle/conjuro, `family==nil`): el swing lo mantiene el emote actual de `DoWeaponAttack` y `RunAttackSequence` solo sincroniza la reaccion con un delay fijo (~0.4s). La reaccion solo se dispara con CA resuelta (`hit` conocido); sin CA (`hit==nil`) solo se reproduce el swing del preset. `RollActionAttack` (ficha NPC) sigue disparando `TriggerDefenseOnMiss("focus")` directo (su swing lo da `onAttackAnimation` del contexto; no usa `RunAttackSequence`).
  - **Herida al impactar (`TriggerWoundOnHit`)**: uno mismo/jugador ajeno → su cliente anima `mod anim 33/34` (`PlayLocalWound`, gateada por flag; jugador ajeno via `DOWOUND`). NPC → la herida la emite `SetNpcHealthDelta` al aplicar el daño (`npc emote 33/34`), no se duplica aqui.
  - El branch NPC de `TriggerDefenseOnMiss` requiere ademas el **flag de animaciones del atacante** activo (el origen emite el `npc emote` en su propio cliente).
  - **Defensor jugador ajeno** (tiene cliente → lo hace SU cliente): se le envia `HarfordSync.SendDefense(prefix, name)` (opcode `DODEFENSE`, WHISPER, sin payload); su cliente recibe (`HarfordDnDComm` → `deps.HandleDefense`) y ejecuta `PlayLocalDefense()`, que corre la secuencia (`HarfordActionSequence.RunByName(seq)` → `mod anim` + vuelta a postura + sonido, todo en su cliente; no requiere oficial; respeta el flag de animaciones). `combatModeKey` lo fija/limpia el boton "Modo combate" del jugador.
  - **Escudo (block)**: `PlayLocalDefense` detecta en el cliente del propio defensor si lleva escudo en la mano secundaria (`GetInventoryItemID("player", INVSLOT_OFFHAND)` → `GetItemInfoInstant` clase 4 / subclase 6). Con escudo usa `HarfordEmotes.SHIELD_DEFENSE_DEFS` ({`ShieldBlock`, `OnehandDodge`} al azar), con prioridad sobre la postura; funciona aunque no haya `combatModeKey` activo. Sin escudo → `PickDefenseSeq(combatModeKey)`. La deteccion de escudo es solo para defensores jugador (no se puede leer el equipo de un NPC; el NPC usa su modo recordado por GUID).
  - **Defensor NPC** (no tiene cliente → lo emite el atacante): solo si el atacante es `IsOfficerPlus()` (los no-oficiales no emiten comandos a NPC) **y** el defensor es el `target` seleccionado del servidor (`.npc emote` actua sobre el target; si el defensor es `focus` y el target es otro NPC, animaria al equivocado → se omite). Corre la **misma secuencia** con `HarfordActionSequence.RunByName(def.seq, { npcAnim = true })`: en modo `npcAnim` los pasos `anim` salen como `.npc emote <id>` one-shot sobre el NPC objetivo (no poseido) y el sonido se reproduce local en el atacante. La postura del NPC se recuerda por GUID: el dropdown de modo de combate de la ficha NPC llama `HarfordDnDCombat.SetNpcCombatMode(guidTarget, opt.key)` (fallback `npcSourceGuid`); `TriggerDefenseOnMiss` consulta `GetCombatModeForGuid(guid)` (dodge por defecto si no se conoce).
  - `HarfordActionSequence.ACTIONS.anim` acepta `opts.npcAnim`: redirige a `HarfordServerActions.SetNpcEmote(id, opts)` en vez de `mod anim`. Es la unica via para animar a un NPC NO poseido (mod anim solo afecta a uno mismo/poseido).
  - Secuencias de defensa (`OnehandParry`/`OnehandDodge`/`TwohandParry`/`TwohandDodge`/`PolearmParry`/`PolearmDodge`/`FistBlock`/`FistDodge`/`ShieldBlock`) en `HarfordActionSequencePresets`. Pendiente de validar en Epsilon: que los anim IDs de esas secuencias funcionen igual con `.npc emote` que con `.mod anim`.
- Contrato `HarfordDnDMinimap` (`Harford/DnD/UI/HarfordDnDMinimap.lua`): boton de minimapa. `HarfordDnDMinimap.Create()` (idempotente) + `HarfordDnDMinimap.UpdatePosition(btn)`. El click izquierdo usa `_G.DND5E_ARC_API.Toggle`; el click derecho llama al handler inyectado con `HarfordDnDMinimap.SetResetHandler(fn)` (HarfordDnD.lua registra su `ResetAllFramePositions`). La clave `CreateDnDMinimapButton` del deps de `HarfordDnDComm` ahora apunta a `HarfordDnDMinimap.Create`.
- Contrato `HarfordCharacterPanel` (`Harford/Character/HarfordCharacterPanel.lua`): panel de personaje para usuario final, abierto desde el icono de tabardo de la ficha o `/harford char`. Sus tabs inferiores son exclusivamente `Personaje` y `Reputacion`; Habilidades/Conjuros/Profesiones se abren en su ventana propia (`HarfordSkillsPanelFrame`, `SKILLS_TAB_ORDER = book/spells/professions`). La pestaña `Profesiones` NO reimplementa el skin: parte del libro de habilidades y solo sustituye el marcapaginas por la franja verde de `383588` y añade los sellos de profesion (recorte de marco de `383588` a escala 1:1 + aro `383591` 72x72 con icono 70x70 enmascarado + barra 95x16 de `ProfessionsBook`); el click de un sello abre `HarfordProfessionsCraftUI`, no una vista de recetas embebida. `Creacion` se abre con `/harford char crear`; `Subida` se abre con `/harford char subir` o la flecha de reputacion junto al nivel. Ambas rutas usan `HarfordCharacterAdvancement`: el modo `levelup` parte de la ficha actual, avanza exactamente un nivel total y solo escribe la clase/subclase/elections elegidas antes de regenerar el About de TRP3; nunca reescribe raza, trasfondo, caracteristicas o equipo. **No mostrar checkboxes por rasgo**: los booleanos de rasgos son internos; solo se muestran dropdowns/controles cuando existe una eleccion real (`choice`). `Reputacion` NO duplica ni reimplementa la lista: usa el propio `HarfordReputationUI` en modo embebido (`EmbedInto`/`DetachEmbedded`) dentro del panel de personaje. La ficha compacta conserva solo tabs de tirada (`Caracteristicas`, `Ataque`, `Habilidades`); la antigua pestaña `Clases` y su bloque `RefreshClassPanel` fueron retirados de `HarfordDnD.lua`.
  - **Pestaña `Libro`**: replica 1:1 del `SpellBookFrame` nativo (probe `/harford debug run probeframe SpellBookFrame`/`SpellBookSkillLineTab1`). Texturas: cuerpo `374155` (texCoord `0,0.533203125,0,0.4902344`), pliego `Spellbook-Page-1` (375503) + cierre `Spellbook-Page-2` (375504); botones desde `Spellbook-Parts` (375505): `Background` marron = pasivo, `SlotFrame` = activo/al_accion, `UnlearnedSlotFrame` = reaccion, `TextBackground` ×2 = sombra del nombre; highlight de reaccion activa = `TrainSlotFrame` + `TrainTextBackground`. Tab = `SpellBook-SkillLineTab` (136831) 64x64@(-3,+11) + `GuildSpellbooktabIconFrame` (marco del icono). Iconos de tab: General = `INV_Misc_Book_09`, clase/subclase = `Interface\Icons\classicon_<token>` (mapa `CLASS_ICON_TOKEN`).
  - **Categorias del boton del Libro** (`BookCategory`): `pasivo` (tooltip); `al_accion` = la habilidad declara `conditionalWeaponDamage` → el click **togglea `HarfordDnDStore.ToggleConditionalDamage(cdId)`** (MISMO estado `activeCondDamage` que el menu "Daño extra" de la seccion Ataque; pueden activarse varios y el ataque los consume). **Objetivo: el Libro sera el unico control y se retirara el boton "Daño extra".** `reaccion` = `feature.cast="reaccion"` → toggle + highlight "preparado" (estado `S.activeReactions` por id), se apaga al volver a clicar o **al empezar tu turno** (`HarfordTurnOrderAPI.RegisterMyTurnListener`). Las reacciones pueden declarar `reactionTrigger`/`reactionEffect`; el disparador inicial `damage_taken` se llama desde el daño local y desde `RADJ health` remoto negativo. Implementadas ahora: Esquiva Sobrenatural (mitad de daño) y Tenacidad Rugosa (1d12 + mitad de nivel). `directo`/`activo` = anuncia el uso con enlace.
  - `maniobra` = la habilidad declara `energyManeuver` y el click pasa por `HarfordDnDStore.OpenEnergyManeuverMenu(feature, anchor)`: las maniobras simples ejecutan `UseEnergyManeuver(feature)` directo; las que declaran `levelCost` abren dropdown para elegir cuantos dados/niveles gastar. Gasta el recurso y resuelve ataque/salvacion/dano segun el efecto. Si declara `attack=true`, primero hace un ataque de arma normal y solo al impactar ejecuta el efecto posterior. Si ademas declara `spendOnHit=true`, el recurso se comprueba al pulsar pero se gasta solo si el ataque impacta. La linea de ataque usa el link TRP3 de la habilidad (`HarfordTRP3.GetAbilityChatLink`) cuando exista. Ejemplos: Picaro `Mutilar`/`Exponer Armadura`/`Garrote`, Guerrero `Carga`, Caballero de la Muerte `Espiral de la Muerte`. `Mutilar` usa `onFailAura=267937` (`Derribado`) y `Garrote` `onFailAura=30900` (`Silenciado`) si el objetivo falla la salvacion posterior al impacto. `Exponer Armadura` NO lleva salvacion: aplica `onHitAura=11971` (`Exponer armadura`) directamente al impactar (campo `onHitAura` en maniobras de ataque sin save, ruteado por `ApplyConditionalHitAura`). `Carga` quedo como ataque a secas con `spendOnHit` (sin estado). El estado 11971 esta tambien en el menu `ESTADOS` de `HarfordAdminUnitMenu`. **Formato compacto** del desenlace (compartido por todas via `FormatSaveRollLabel`/`FormatSaveOutcome`): `Salv CON 10 vs CD 13: FALLO <estado-o-daño>` (sin total duplicado ni flavor redundante; con bonus muestra `8+2=10`).
  - Marcadores de eleccion de subclase/arquetipo (`Arquetipo de Picaro`, `Estudio Magico`, `Camino Sagrado`, etc.) no son habilidades: no deben aparecer como botones del Libro ni como rasgos-habilidad. El resumen de Rasgos muestra una fila informativa `Subclase <Clase>: <Subclase>`, con `<Clase>` coloreada con su color de clase; los rasgos reales de la subclase aparecen en su tab propia.
  - Los rasgos `choice` (p.ej. `Estilo de Combate`, `Pericia`, afinidades) deben mostrar la opcion elegida tanto en el resumen `Rasgos` como en el boton del `Libro`. Si no hay opcion resuelta/importada, mostrar `Eleccion: pendiente` en vez de ocultar el dato; el tooltip lista opciones posibles cuando el choice esta pendiente.
  - El resumen `Rasgos` NO muestra contadores `[X/Y]` de usos por descanso. Esos usos pertenecen al Libro/accion del rasgo; el boton del Libro muestra `Usos X/Y · Descanso corto|Descanso largo`, bloquea la preparacion/uso si no quedan usos y refresca el contador al gastar. Meterlos en el resumen duplica filas como `Conocimiento Arcano`.
  - **Enlace de habilidad clicable**: los enlaces de tipo propio (`harford:abil:`) NO son clicables en este cliente (no disparan `SetItemRef`) y `ChatFrame_OnHyperlinkShow` esta vetado; por eso se usa **TRP3 ChatLinks** via `HarfordTRP3.GetAbilityChatLink(feature)` (modulo `harford_ability`, hyperlink `totalrp3`). Fallback a texto de color si TRP3 no esta.
- Contrato `HarfordProfessions` (`Harford/Professions/`): profesiones D&D+WoW en tres capas de solo-datos + core. `HarfordProfessionsData` define profesiones (herramienta, caracteristica, `kind` craft/gather/utility) y las RECETAS; `HarfordProfessionsItems.REGISTRY` mapea cada CLAVE estable (`mena_cobre`) a su itemId real de Epsilon — una clave con `id = nil` es valida: su receta sale "pendiente" (visible, no crafteable) y nada se rompe. `HarfordObjectCatalog.lua` se GENERA con `tools/codice/generar_catalogo_objetos.py` desde `cotejo/objetos_wowhead.json` y contiene solo los metadatos Wowhead de las claves declaradas (nombre, icono, calidad, stats y lineas). **`wow` es una referencia de metadatos, nunca un itemId de Epsilon**: inventario, Merchant y comandos de servidor usan exclusivamente `entry.id`. Consultar `HarfordProfessionsItems.GetMetadata(key)`, `GetByItemId` o `GetByWowId`; `ShowTooltip(owner, key)` muestra el tooltip real si existe el item de Epsilon y, si no, el respaldo descriptivo del catálogo. No duplicar catálogos ni intentar convertir un ID Wowhead en un ID de phase. **Conocer una profesion = tener la competencia de su herramienta** (`HarfordDnDFeatureEffects.HasToolProf`). Craftear = d20 + PB (si herramienta) + Mod vs CD, critico 20 = salida x2, consume materiales REALES (`RemoveItem`) y entrega items REALES (`GiveItem`); skill 1-300 con subida estilo WoW (umbral gris = skillReq+100) y tiers Aprendiz/Oficial/Experto/Artesano/Maestro (1/75/150/225/300). **Las recetas salen de Wowhead, no se escriben a mano** (2026-08-22): 2.275 recetas de ONCE profesiones extraidas con `tools/codice/wowhead_profesiones.py` -> `importar_profesiones.py`, que RETIRA cualquier receta escrita a mano; las cadenas 1-300 inventadas anteriores ya no existen. Cada profesion se lee de la version donde su arbol esta completo (Classic, salvo Joyeria en TBC e Inscripcion en Wrath) y los NOMBRES se toman del WoW actual, con dos excepciones deliberadas: los 26 objetos que el retail ya no traduce conservan el nombre espanol de Classic, y la terminologia de la casa dice "Lingote de X" donde el juego dice "Barra de X" (`nombres_display.casa`). Herboristeria, Pesca, Desollar y Fabricar venenos se quedan SIN recetas: son recoleccion y Wowhead no las publica como arbol. **La CD ya no es un numero fijo**: sale del color que la receta tiene para tu habilidad (`colors = { naranja, amarillo, verde, gris }`, umbrales del propio juego) -> rojo 20, naranja 16, amarillo 12, verde 10, gris 8, mas `qmod` por la calidad de lo que se fabrica (gris -1, blanco 0, verde +1, azul +3, morado +5, legendario +7). El campo `dc` se conserva como respaldo (naranja + qmod) para la receta sin umbrales y para el codigo que solo lea un numero; **`HarfordProfessions` todavia usa `dc` y no lee `colors`/`qmod`** — pendiente. **El emparejado del registro es por `wow = <itemId>`, NO por nombre**: cada entrada guarda el itemId de Blizzard, y renombrar por nombre creaba una clave nueva dejando una clave vieja huerfana, que es justo la que lleva el `id` real de Epsilon puesto a mano. Se poda lo que no usa ninguna receta salvo las entradas que ya tengan ese `id`, que no se puede volver a deducir. **No renombrar ids de receta ni claves de item**: la SV per-character `HarfordProfessionsStore` (`skills`/`learned`/`nodeCooldowns`) los referencia. **Nodos de mundo**: `HarfordProfessions.GatherNode(recipeId, cooldownSeconds)` es la puerta para vetas/plantas/bancos de peces colocados por el DM — el gossip del NPC/objeto ejecuta un ArcSpell que la llama (mismo patron que `HarfordQuestAPI` en WorldQuests). Solo acepta recetas de profesiones `gather`; la identidad del nodo es el GUID de la unidad del gossip (`npc`/`target`); el cooldown (300s por defecto, minimo 30) es por nodo y por personaje, persiste en `nodeCooldowns` con poda de expirados, y se aplica AL INTENTO (exito o fallo) — pero SOLO si `CanCraft` pasa: quien no conoce la profesion o tiene la receta pendiente de ID no consume el nodo. ArcSpell de ejemplo (accion Script del gossip): `HarfordProfessions.GatherNode("min_cobre", 300)`. **Enseñar recetas**: `HarfordProfessions.TeachRecipe(nombreJugador, recipeId)` (menu DM de unidad > Profesiones) envia `TEACH|recipeId` por el prefix propio `HARFORDPROF` (WHISPER); solo acepta recetas `worldLearned`. El receptor concede solo un beneficio (marcar aprendida), asi que aplica el filtro estandar de remitente reconocido y el gate de DM vive en el EMISOR (mismo modelo que `QDONE`); ignora recetas no-worldLearned y avisa si ya se conocia. Para cosechar itemIds: `/harford debug run merchantdump [match|apply]` con un mercader abierto vuelca id+nombre, casa por nombre normalizado contra las claves pendientes y acumula todo en `HarfordDebugSettings.merchantDump` (leible del fichero SV tras /reload); `apply` rellena en caliente con `HarfordProfessionsItems.Set` (solo sesion: la persistencia real se hornea en el .lua). Un item del dump sin nombre (`item NNNN`) es cache fria de `GetItemInfo`: reabrir el mercader mas tarde y re-dumpear lo resuelve. **Cosecha 2026-08-20**: horneados los reales de Epsilon (menas/barras cobre-plata, pellejos/cueros ligero-grueso, restos de cuero, y las hierbas reales Hojaplata/Marregal/Brezospina/Cardopresto/Alga estranguladora/Hierba cardenal/Musgo de tumba/Acérita salvaje) con recetas gather nuevas en herboristeria/mineria y fundiciones de estano/plata; los nombres del registro usan el nombre EXACTO en juego aunque la clave conserve el alias antiguo (`aceroflor` -> "Acérita salvaje", `zarzaespina` -> "Brezospina"). **Ingenieria ya tiene su cadena 1-300** (11 recetas `ing_*`, remate `ing_detonador_goblin` worldLearned) con outputs `id = nil` pendientes de crear en el phase vault. Quedan ~40 ids del dump sin nombre resuelto.
- **IDs operativos de Profesiones (2026-08-22):** hasta que se migre a un vault propio, `HarfordProfessionsItems.GetId(key)` devuelve `entry.wow` primero y solo cae a `entry.id` para entradas custom/dinamicas sin equivalencia Wowhead. Por tanto, bolsas, `additem`/`removeitem`, Merchant, crafteo y tooltips usan los IDs originales de Wowhead. `GetEpsilonId(key)` existe solo para la futura migracion; no usarlo en gameplay actual.
- Contrato `HarfordActionBars` (`Harford/DnD/UI/HarfordActionBars.lua`): barra de accion propia (frame movible, NO secuestra los ActionButton de Blizzard) para colocar habilidades del Libro. Gate por `HarfordConfig` (`actionbar` on/off; opcion en el panel de config). Expone API publica (`Toggle`/`SetShown`/`SetTestTexture`/`SetGeometry`/`Layout`); los diagnosticos viven en `HarfordDebug` (`actionbar`/`actionbarsize`/`actionbarset`/`actionbarscan`). **Limitacion Epsilon confirmada**: las texturas de madera retail `Interface\PlayerActionBarAlt\spellbar-wood*` (y `wood`) **NO existen en el cliente Epsilon** (salen verde); usar solo texturas que el cliente tiene (Spellbook/Buttons/Icons/Achievement…). `GetFileIDFromPath(ruta)` permite comprobar si una textura existe antes de usarla (`/harford debug run actionbarscan [ruta]`). FASE 2 pendiente: arrastrar habilidades del Libro a los slots (patron Arcanum: SecureActionButton con `type` custom + `_<type>` handler) y persistencia.
  - Fuentes confirmadas para replicar el `CharacterFrame` nativo sin ajustes a ojo:
    - `G:\Epsilon\_retail_\WTF\Account\MORTYN\SavedVariables\FrameDump.lua`: arbol completo del frame vivo (`CharacterFrame`, `PaperDollFrame`, `CharacterFrameInset`, `CharacterFrameInsetRight`, `CharacterStatsPane`, slots y modelo).
    - `G:\Epsilon\_retail_\WTF\Account\MORTYN\SavedVariables\HarfordDebug.lua`, tabla `HarfordFrameProbe`: captura generada por `/harford debug run probeframe CharacterFrame`; conserva atlas/texturas (`_UI-Frame-TitleTileBg`, `UI-Frame-InnerTopLeft`, `UI-Character-Info-Title`, etc.), puntos, tamaños, capas, fuentes y colores. Las capturas historicas que sigan en `Harford.lua` quedan como archivo de referencia y no las carga el core.
  - Enfoque correcto: usar esas capturas como referencia de geometria/arte para una reconstruccion controlada en `HarfordCharacterPanel`. No clonar recursivamente el `CharacterFrame` vivo con scripts/eventos/secure templates, porque arrastra pestañas nativas, `ReputationFrame`, `TokenFrame`, popups, eventos y riesgo de taint. Si se necesita actualizar la referencia, ejecutar `/harford debug run probeframe CharacterFrame`, hacer `/reload`, y leer de nuevo `SavedVariables\HarfordDebug.lua`.
  - La pestaña `Ficha` usa un canvas hijo del frame completo, no `S.content`, para poder aplicar coordenadas nativas directamente. Medidas base confirmadas: `CharacterFrameInset` = `TOPLEFT CharacterFrame 4,-60` + `BOTTOMRIGHT CharacterFrame BOTTOMLEFT 332,4`; `CharacterModelFrame` = `231x320`, `TOPLEFT PaperDollFrame 52,-66`; `CharacterFrameInsetRight` = `TOPLEFT CharacterFrameInset TOPRIGHT 1,0` + `BOTTOMRIGHT CharacterFrame -4,4`; `CharacterStatsPane` = `TOPLEFT insetRight 3,-3` + `BOTTOMRIGHT insetRight -3,2`.
  - Texturas ya replicadas desde `HarfordFrameProbe`: fondo principal `Interface\FrameGeneral\UI-Background-Rock`, insets `Interface\FrameGeneral\UI-Background-Marble`, cabeceras `UI-Character-Info-Title`, fondo de clase del panel derecho `UI-Character-Info-<Class>-BG`, tabs superiores `Interface\PaperDollInfoFrame\PaperDollSidebarTabs` y borde interior del modelo con `Interface\CharacterFrame\Char-Paperdoll-Parts`, `Char-Paperdoll-Vertical` y `Char-Paperdoll-Horizontal`.
  - Tabs inferiores: replicar `CharacterFrameTab1/2/3` desde `G:\Epsilon\_retail_\WTF\Account\MORTYN\SavedVariables\Harford.lua` (`HarfordFrameProbe`). Primera tab `TOPLEFT CharacterFrame BOTTOMLEFT 11,2`; siguientes `LEFT` de la anterior con `x=-15`. Estado seleccionado usa piezas `*Disabled` con `UI-Character-ActiveTab`, texcoord vertical `0..0.546875`, altura 35, ancladas a `TOPLEFT`; su texto nativo va blanco y centrado en `y=-3`. Estado normal usa `UI-Character-InActiveTab`, altura 32, anclaje `TOPLEFT y=-1`; su texto va dorado Blizzard (`1,0.82,0`) y centrado en `y=2`. Highlight `UI-Character-Tab-RealHighlight` con `TOPLEFT 3,5` y `BOTTOMRIGHT -3,0`.
  - Fondo derecho de la ficha: `UI-Character-Info-<Class>-BG` se resuelve por la clase Harford de mayor nivel; si el perfil no tiene clase Harford, cae a `UnitClass("player")` y su atlas nativo (`ROGUE` -> `UI-Character-Info-Rogue-BG`, etc.). El valor grande bajo la primera cabecera (`Nivel`/equivalente al `Item Level` nativo) no va directo sobre el fondo de clase: vive en un frame `187x29` anclado al `BOTTOM` de la cabecera, con atlas `UI-Character-Info-ItemLevel-Bounce`, textura `162x29`, capa `BORDER`, alpha ~0.298 y texto centrado en `y=-1`.
  - Fondo del modelo: no copiar las cuatro texturas del `CharacterModelFrame` nativo vivo, porque eso fija el visor a la raza real del personaje conectado. `HarfordCharacterPanel` elige el fondo desde `progression.race` usando `Interface\DressUpFrame\DressUpBackground-<Race>1..4` con los mismos texcoords del probe. Mapeos confirmados/previstos: `huargen -> Worgen`, `orco -> Orc`, `elfo_sangre -> BloodElf`, `humano -> Human`, `enano -> Dwarf` (`hierro_negro -> DarkIronDwarf`), `gnomo -> Gnome` (`mecagnomo -> Mechagnome`), `draenei -> Draenei` (`forjado_luz -> LightforgedDraenei`), `elfo_noche -> NightElf`, `renegado -> Scourge`, `tauren -> Tauren` (`monte_alto -> HighmountainTauren`), `trol -> Troll` (`zandalari -> ZandalariTroll`) y `goblin -> Goblin`. Si la raza no existe o no tiene token conocido, el visor usa fondo negro plano.
  - Slots y tabs superiores: no usar rutas inventadas como `Interface\PaperDoll\UI-PaperDoll-Slot-*` ni `RTPortrait1` directo porque producen cuadrados verdes si la textura no existe como ruta cargable. Los slots son decorativos por diseño y muestran el icono vacio nativo del hueco via `GetInventorySlotInfo("HeadSlot"/"NeckSlot"/...)`; nunca copian `Character*SlotIconTexture` ni objetos equipados reales del jugador. La composicion del slot usa fondo oscuro, `UI-Quickslot2`, `WhiteIconFrame` y marco `Char-Paperdoll-Parts`. Las tabs superiores usan texcoords confirmadas de `PaperDollSidebarTabs`: la primera muestra el retrato 3D nativo del jugador y las tres cambian el panel derecho (`summary`, `skills`, `details`) con composicion inspirada en BG3. Segun `FrameDump.lua`, las tabs 2/3 mantienen visible su region grande `GLOW` como marco/base del icono; no es hover. El estado activo/inactivo se expresa con alpha del boton (`1` activo, `0.498` inactivo). La tab de retrato usa su propio `PORTRAIT_BG`; el hover (`HILITE`) solo aparece en tabs inactivas.
  - Cabecera de clase del paperdoll: no usar `Nivel X - Clase X`. Debe mostrar entradas de multiclase estilo TRP3, sin separador `|`, con cada entrada coloreada por su propia clase WoW usando `HarfordClassColors`. En la cabecera compacta pueden ir en una linea (`Picaro Forajido (3)  Paladin (1)`); en la vista de detalles, cada clase va en su propia linea dentro de la fila `Clase`.
  - Panel derecho: las filas de datos deben tener banda alterna tenue y etiquetas doradas/valores blancos, siguiendo el `CharacterStatsPane` nativo; no dejar texto plano flotando sobre el fondo de clase.
- CA / Armor Class:
  - Ficha jugador: el campo `CA` vive en la pestaña `Ataque` y persiste en la clave `ArmorClass` de la ficha.
  - Ficha NPC: el campo `CA` vive dentro del panel de ataque NPC. Al cargar un NPC, la precedencia es `HarfordTurnOrderStore.entries[].armorClass` si ese NPC ya esta en turnos; si no existe, se usa `HarfordTRP3.GetNPCStatBlock(unit).ac` parseado desde la ficha TRP3.
  - Turnos: las entradas NPC tienen campo `armorClass`, se serializa por `HARFORDTURN` y se muestra como boton `CA N` en la tarjeta. El admin puede editarlo desde Turnos; si la ficha NPC de ese GUID esta abierta, `HarfordDnDAPI.UpdateSheetArmorClassForGuid` actualiza el campo de la ficha al instante.
  - El editbox `CA` de la pestaña Ataque muestra la CA del **target actual**, no la CA propia estatica. Al cambiar de target se refresca el numero dentro del box. Si no hay target, cae a la ficha activa (NPC cargado o jugador propio).
  - Ataque de arma: `DoWeaponAttack` llama a `HarfordDnDCombat.ResolveArmorClassOutcome`. Para NPC prioriza CA de Turnos por GUID, luego override local editado desde el box, luego TRP3; para jugadores la **CA de "Currently" (TRP3) tiene PRIORIDAD SIEMPRE, incluso para uno mismo**, por encima de la CA local de la ficha Harford: `GetArmorClassForUnit` intenta primero `HarfordTRP3.GetPlayerArmorClass` (que a su vez parsea el texto `character.CU` "Currently" ANTES que los campos estructurados de la ficha TRP3); solo si no hay CA en TRP3 cae a `ArmorClass` propio (self), o a cache remota / override / ficha-perfil-banco (otros jugadores). Reconoce `CA: 14`, `CA 14`, `Clase de Armadura 14`, `Armor Class 14`. La tirada muestra `vs CA N Superada/No superada`. Si supera CA (o critico natural), se lanza automaticamente `RollWeaponDamage`; si falla o pifia, no consume dano. Sin CA resoluble se conserva el flujo manual anterior.
  - Regla de mesa: un ataque normal solo supera CA si `total > CA`; si `total == CA`, gana la defensa y debe salir `No superada`. Critico natural impacta y pifia natural falla antes de esta comparacion.
  - **Ataque Arma y Ataque Conjuro requieren target valido** (existe y no es uno mismo): los botones se deshabilitan (via `HarfordDnDStore.RefreshWeaponDamageButton`, que ahora gatea los tres botones) y `DoWeaponAttack`/`DoSpellAttack` ademas hacen guard al inicio.
  - **Ataque Conjuro tambien se resuelve contra la CA del target** (`ResolveArmorClassOutcome(total, critTag, "target")`, muestra `vs CA N Superada/No superada`). No tiene daño automatizado ni dispara reaccion melee de herida/parry (parar un conjuro no aplica); solo informa el resultado.
  - `ArmorClass` esta en `HarfordSync.ProfileKeys.DnDBase` y `DnD`, por lo que viaja con la ficha cuando se comparte/guarda en banco. Al editar la CA propia se agenda `ScheduleMyResourceBroadcast()` para actualizar la cache de grupo. `PLAYER_TARGET_CHANGED` y la llegada de recursos remotos refrescan los controles de CA para evitar valores visuales obsoletos.
  - Plan de migracion a `HarfordDnDCombat`: primero mantener `DoWeaponAttack`/`RollWeaponDamage` en `HarfordDnD.lua` y delegar solo resolucion/aplicacion contextual. Segundo, mover helpers puros de ataque/dano de arma que no creen widgets. Tercero, mover resolucion de impacto de acciones NPC y dano custom cuando compartan contrato con arma. No mover UI, dropdowns, botones ni consumo de modo de tirada a Combat.

Contrato `HarfordEmotes`:

- Vive en `Harford/Server/HarfordEmotes.lua`. Solo datos: ORDER + DEFS + helpers, sin envio de comandos.
- `HarfordEmotes.NPC_WOUND = { id = 33, label = ... }`: emote ONESHOT_WOUND usado por `SetNpcHealthDelta` al recibir dano real normal.
- `HarfordEmotes.NPC_WOUND_CRIT = { id = 34, label = ... }`: variante ONESHOT_WOUND_CRIT usada por `SetNpcHealthDelta` cuando recibe `opts.isCritical = true`.
- `HarfordEmotes.ORDER` lista las keys canonicas en el orden visual del dropdown del panel NPC: `none, unarmed, one_hand, two_hand, polearm, bow, rifle, offhand, thrust, thrust_2hl, thrust_offhand, throw, unarmed_offhand`.
- `HarfordEmotes.DEFS[key] = { id, label, weaponClass }`: `id` puede ser `nil` para `none`. `weaponClass` mapea a familia de arma para futuras heuristicas (1h, 2h, bow, rifle, polearm, throw, offhand, unarmed).
- Helpers: `Get(key)`, `GetById(id) -> def, key`, `GetOrderedList() -> { { key, id, label } }`, `Default() -> none`.
- El IIFE del panel NPC en `HarfordDnD.lua` consume `GetOrderedList()`; ya no contiene IDs literales.
- **Modo combate** (posturas persistentes, distintas del swing de ataque): `HarfordEmotes.COMBAT_ORDER` (`stand, unarmed, one_hand, two_hand, polearm, bow, rifle, spell_direct, spell_area, thrown`) + `COMBAT_DEFS[key] = { id, [npcId], label }` con IDs `stand` (jugador `id=26`, NPC `npcId=0`), resto `4254..4337`. `stand` sale del modo combate; en el jugador es `mod anim 26`, en el NPC es `npc emote 0 repeat`. Helpers: `GetCombatList() -> { { key, id, npcId, label } }` (`npcId` por defecto = `id`), `GetCombat(key) -> def`.
- Ficha jugador: botón **"Modo combate"** en `SEC_ATK` (150,-6, a la izquierda del checkbox de animaciones, que se mantiene en 266,-6). Solo visible si `HarfordDnDStore.animsEnabled` y fuera de la ficha NPC (lo gestiona el `OnClick` del checkbox de animaciones y `RefreshSheetActionPanel`). Mapea el arma equipada (`GetCombatEmoteKeyForWeapon`, versátil activo → `two_hand`) y envía `mod anim` sobre el propio personaje. Pulsar de nuevo SIN cambiar de arma (`HarfordDnDStore.combatModeWeaponKey`) ejecuta `stand` (26) y limpia la marca. Ref del botón en `HarfordDnDStore.combatModeButton`.
  - Ficha NPC: dropdown adicional de modo combate (bajo el dropdown de emote de swing, derecha del panel) alimentado por `GetCombatList()`, empieza en "Stand"; **al seleccionar** ejecuta `HarfordServerActions.SetNpcEmoteRepeat(opt.npcId)` (postura en bucle `npc emote ID repeat`) para **todas** las opciones, incluida "Stand" (`npc emote 0 repeat`). Sin botón extra. El `repeat` es exclusivo de este dropdown: el resto de emotes (swing de ataque, herida, `mod anim` del jugador) nunca lo usan.
- **Ataque por familia de animacion** (`HarfordEmotes.ATTACK_SEQ_DEFS[family] = { normal, critical, offhand }`): mapea la familia melee a su preset de ataque. `family` lo da `HarfordDnDWeapons.GetAnimFamily(def, versatileActive)` → `unarmed`/`one_hand`/`two_hand`/`polearm`/`shield`, o `nil` para arco/rifle/conjuro (sin preset; mantienen el emote actual). `HarfordEmotes.GetAttackSequence(family, { critical, offhand })` devuelve el nombre del preset: `offhand` tiene prioridad (define que arma golpea), luego `critical` (golpe pesado: `*Obliterate`/`*Chop`/`*Special`/`ShieldBashSlash`), si no el normal. Solo datos/funcion pura; el orquestador de combate (Fase 3) lo consume.
- **Defensa por postura (aleatoria)** (`HarfordEmotes.DEFENSE_DEFS[modeKey] = { seq1, seq2, ... }`): lista de secuencias posibles; `HarfordEmotes.PickDefenseSeq(modeKey, hasShield)` elige una **al azar** (`math.random`). `one_hand`/`two_hand`/`polearm` → {parry, dodge}; `unarmed` → {FistBlock, FistDodge}; arco/rifle/hechizo/arrojadiza → {FistDodge}; **desconocido → `DEFAULT_DEFENSE_DEFS` = one_hand {OnehandParry, OnehandDodge}** (asume arma a una mano). `hasShield` → `SHIELD_DEFENSE_DEFS` ({ShieldBlock, OnehandDodge}). Cada secuencia sirve a la vez para jugador (mod anim) y NPC (npc emote via `npcAnim`). Solo datos; el envio lo hace `HarfordDnDCombat`. **`math.randomseed` se siembra una vez al cargar `HarfordEmotes`** (con `GetServerTime`/`time`): sin sembrar, WoW usa una semilla fija y la defensa del NPC (que consume el RNG en posiciones fijas: 2 d20 + 1 pick por fallo en el cliente del atacante) tendia a elegir SIEMPRE lo mismo (solo dodge); en PvP no pasaba porque el pick corre en el cliente del defensor. Debug: `/harford debug run defrand` muestra la distribucion; `/harford debug run npcemote <id>` prueba un `.npc emote` suelto.
- Ficha NPC: el boton `Atacar` usa `focus` como objetivo defensivo si existe. Esto solo afecta a la resolucion de CA (`vs CA N Superada/No superada`) de la tirada; la animacion sigue validando el NPC fuente actual y el boton `Dano` conserva el flujo normal sobre `target`. Si no hay `focus`, `Atacar` se comporta como antes. El editbox `CA` del panel NPC usa la misma regla: si hay `focus`, muestra/edita la CA del focus (player o NPC segun `HarfordDnDCombat.GetArmorClassForUnit`); si no, vuelve al target/ficha.
- **CA del focus jugador — request de recursos**: para resolver la CA de un focus jugador via cache remota (`GetRemoteArmorClassForUnit`), el campo `ArmorClass` viaja en el payload de recursos (`HarfordDnDNet.BuildActiveResourcePayload` lo anexa; no esta en `ALL_KEYS`, si en `RUNTIME_KEYS`). En `PLAYER_FOCUS_CHANGED`, si el focus es un jugador ajeno, se pide `HarfordDnDAPI.RequestResourcesForName(focus)` para cachear su `ArmorClass`; al llegar el `RES`, la rama `resourcesChanged` vuelve a llamar `RefreshArmorClassBoxes()`. Sin esto, la CA del focus solo se resolvia por TRP3 (CA visible en About/Currently) y quedaba en 0 si el jugador la tenia en Harford pero no en su perfil TRP3.
- **El botón "Daño" de la ficha NPC NO reproduce ningún emote de tipo de ataque**: la animación del swing pertenece solo a la tirada de "Atacar". "Daño" solo aplica el daño (la reacción de herida sobre la víctima la gestiona `SetNpcHealthDelta` → `npc emote 33` normal o `34` crítico).
- `HarfordServerActions.SetNpcEmoteRepeat(id, opts)` + plantilla `NPC_EMOTE_REPEAT = "npc emote {id} repeat"`: variante persistente de `SetNpcEmote`. Valida con `ToNonNegativeInteger` (admite `0` para el Stand).
- **Emotes NPC van por el canal silencioso de EpsilonLib**: `SetNpcEmote`/`SetNpcEmoteRepeat` fuerzan `forceEpsilon = true` + `showMessages = false`. Si se enviaran por `ARC.CMD` (rama por defecto cuando no hay `forceEpsilon`), el servidor imprimiría su confirmación (`... is now repeating emote N`) en el chat; `ARC.CMD` además ignora `showMessages`. La supresión solo funciona por la ruta `EpsilonLib.AddonCommands`.
- Panel NPC: el dropdown "Accion:" lista **solo** las habilidades detectadas como ataque utilizable (`IsAttackAction`: `attackBonus ~= nil` o `damageDice ~= nil`); el selector por defecto es el último ataque utilizable. El panel muestra **solo** el resumen de bonus de ataque + daño (`parsedText`); ya no se renderiza la descripción completa del estado TRP3.

Contrato `HarfordClassColors` (color de clase, fuente unica):

- Vive en `Harford/Core/HarfordClassColors.lua`. Centraliza lo que antes estaba triplicado en `HarfordUnitFrames`, `HarfordNamePlates` y `HarfordTurns`.
- Carga antes de `HarfordTRP3.lua` y de todos los libros/parsers que consumen normalizacion. Sus referencias a TRP3 se resuelven dentro de funciones en runtime, no durante la carga del archivo.
- `StripAccents(value) -> string`: utilidad UTF-8 central y pura. Sustituye secuencias UTF-8 completas, cubre vocales con tilde/dieresis/circunflejo y `ñ`, preserva mayusculas/minusculas y no aplica `lower`, trim, markup ni cambios de separadores. No crear mapas `UTF8_ACCENT_MAP` ni `gsub` de clases de bytes en otros modulos.
- Este contrato sustituye las notas historicas que mencionaban mapas locales o migraciones pendientes: libros, TRP3, panel, efectos, items, progresion, iconos, mitigacion y parsers NPC Admin ya consumen esta API.
- `ALIASES`: lista `{ token (es/en sin tildes), classFile }`. `NormalizeKey(text)`: convierte a texto, llama `StripAccents`, pasa a minusculas y normaliza separadores.
- `ClassFileFromText(text) -> classFile|nil`; `ColorRGBForClassFile(classFile) -> r,g,b`; `RGBToHex(r,g,b) -> "rrggbb"`.
- `ProfileColorRGB(profile) -> r,g,b,classFile` (clase principal TRP3 via `HarfordTRP3.GetProfilePrimaryClass`); `ProfileColorHex(profile)`.
- `UnitColorRGB(unit) -> r,g,b,classFile` (clase nativa via `UnitClass`); `UnitColorHex(unit)`.
- Solo datos/helpers puros; el cache por nombre de `HarfordUnitFrames` (`API.S.classColorCache`) se queda en ese modulo. Cualquier cambio de alias/color se hace **solo aqui**.

Contrato `HarfordUIGeom` (geometria pura de overlays):

- Vive en `Harford/Core/HarfordUIGeom.lua`. Helpers puros usados por `HarfordUnitFrames` para medir frames nativos: `Clamp`, `FieldPath`, `FirstExisting`, `FindStatusBars`, `StatusBarScore`, `PickStatusBar`, `ScaleBox`, `IsSaneBox`. Sin estado mutable ni dependencias del addon.
- `Bounds`/`RelativeBounds` se quedan en `HarfordUnitFrames.lua` (colisionarian como substring entre si al reescribir call-sites en masa).

Contrato `HarfordAuras`:

- Vive en `Harford/Server/HarfordAuras.lua`. Patron canonico de datos + helpers que envuelven `HarfordServerActions`.
- `HarfordAuras.ORDER`: lista de keys conocidas (`death`, `loot`).
- `HarfordAuras.DEFS[key] = { id, label, scope, note }`. `scope` en (`"self"`, `"current_target"`, `"npc"`) determina que funcion de `HarfordServerActions` se invoca.
- Auras actuales:
  - `death = { id = 29266, scope = "self" }`: gestionada por el propio cliente al cruzar 0 HP (ver "Sistema de animaciones y auras").
  - `loot = { id = 224063, scope = "self" }`: aplicada/quitada por el frame de loot.
- Helpers: `Apply(key, scopeOverride?, opts?)`, `Remove(key, scopeOverride?, opts?)`, `ApplyById(spellId, scope, opts?)`, `RemoveById(spellId, scope, opts?)`, `Get(key)`, `GetId(key)`.
- `ApplyById/RemoveById` despachan a `ApplyAura/RemoveAuraSelf` (self), `ApplyAuraToCurrentTarget/RemoveAura` (current_target) o `SetNpcAura/RemoveNpcAura` (npc). **Esta es la unica via correcta** para que el codigo externo lance auras: no llamar a `HarfordServerActions.Apply*/Remove*` directamente salvo desde dentro de este modulo o de `HarfordServerActions` mismo.
- `HarfordDnD.lua` (handler `HandleApplyAuraSelf`, `AdjustResourceCurrent`) y `HarfordLoot.lua` (OnShow/OnHide del frame) ya estan migrados a `HarfordAuras.Apply/Remove`.

Contrato `HarfordDamageTypes`:

- Vive en `Harford/Core/HarfordDamageTypes.lua`. Solo datos: identidad y presentacion, sin logica de aplicacion.
- `HarfordDamageTypes.ORDER`: 3 fisicos (`slashing, piercing, bludgeoning`) + 10 magicos (`fire, cold, lightning, thunder, acid, poison, necrotic, radiant, psychic, force`).
- `HarfordDamageTypes.DEFS[key] = { label, color, category }`. `category` en `"fisico" | "magico"`.
- Helpers puros: `Exists(key)`, `Get(key)`, `GetLabel(key)`, `GetColor(key)`, `GetCategory(key)`, `IsPhysical(key)`, `IsMagical(key)`, `GetOrderedList()`.
- `HarfordDamageTypes.FromWord(word)`: convierte la palabra del texto libre (espanol o ingles, con o sin tildes) a la key canonica. Util para parsear `action.damageComponents` recibido de TRP3.
- **No** parsea TRP3 ni consulta resistencias; esa responsabilidad es de `HarfordDamageMitigation`.

Contrato `HarfordDamageMitigation`:

- Vive en `Harford/DnD/Data/HarfordDamageMitigation.lua`. Resuelve el estado de mitigacion de una unit frente a un tipo de dano.
- `HarfordDamageMitigation.STATUS = { NORMAL = "normal", RESISTANT = "resistant", IMMUNE = "immune", VULNERABLE = "vulnerable" }`.
- `MITIGATION_MAP[damageKey] = { words = { ... } }`: palabras (sin tildes, minusculas) que indican el tipo en el texto libre del stat block TRP3. Si la entrada del bloc contiene varias palabras separadas por coma, basta con que alguna coincida.
- `HarfordDamageMitigation.Resolve(unit, damageKey) -> status`: llama `HarfordTRP3.GetNPCStatBlock(unit)` (cae a perfil de jugador para `unit = "player"`). Prioridad: inmunidad > (resistencia y vulnerabilidad se cancelan) > resistente / vulnerable / normal.
- `HarfordDamageMitigation.ApplyMultiplier(amount, status) -> newAmount`: aplica multiplicador 5e (immune=0, resistant=floor(amount/2), vulnerable=amount*2, normal=amount). Acepta solo `amount > 0`; devuelve 0 si no.
- `HarfordDamageMitigation.MARKERS` + `Marker(status) -> string`: marcador coloreado de una letra para incrustar en la tirada — `R` azul (resistente), `V` rojo (vulnerable), `I` amarillo (inmune), `""` si normal.
- `HarfordDamageMitigation.KeyFromTypeText(typeText) -> damageKey|nil`: mapea texto libre del tipo (p.ej. "cortante") a la `damageKey` canonica via `MITIGATION_MAP`.
- `HarfordDamageMitigation.ResolveByTypeText(unit, typeText) -> status`: atajo `KeyFromTypeText` + `Resolve`.
- `HarfordDamageMitigation.ForTarget(unit, typeText, amount) -> amountAplicado, status, marcador`: punto de entrada para tiradas de daño. NPCs leen stat block TRP3. Jugadores leen la lista derivada de defensas del perfil (`damageStatusCache`, creada por `HarfordDnDFeatureEffects` al resolver progresion/inspeccion; ej. Caballero de la Muerte `Constitucion No-Muerta` => `veneno = resistant`). Si el jugador remoto no tiene snapshot Harford, intenta una importacion efimera desde su About TRP3 con `SetInspectDataFromTRP3Sheet` y vuelve a consultar la lista. Solo cae al stat block TRP3 si no hay defensa derivada. Si no se puede resolver defensa devuelve `amount, "normal", ""`.
- **Resolucion de defensas en la tirada (core, info publica)**: el calculo de resistencias/inmunidades/vulnerabilidades vive DENTRO de la tirada de daño del core, no en HarfordAdmin. Tanto `RollWeaponDamage` (jugador) como `RollActionDamage` (panel NPC) llaman `ForTarget("target", tipo, total)` por componente, muestran el total ya mitigado y anexan el marcador coloreado junto al tipo de daño en la tirada difundida. Lo aplican TODOS (DM y jugador raso) porque ambos leen el stat block TRP3 del NPC target localmente. `HarfordAdminNPC.ApplyNpcSheetDamage` recibe el total YA mitigado: solo lo aplica con `SetNpcHealthDelta`; no re-mitiga ni imprime lineas de resistencia.
- Consumidor canonico futuro: `HarfordDamage.lua` (pendiente, Fase 2 del plan). Las llamadas directas desde UI se hacen via `ForTarget` para tiradas de daño.

Contrato `HarfordServerActions`:

- Vive en `Harford/Server/HarfordServerActions.lua`.
- Es la capa preferida para gameplay y UI cuando necesiten comandos servidor.
- Construye comandos Epsilon desde funciones validadas, no desde strings sueltos repartidos por otros modulos.
- Construye los strings via `HarfordCommandTemplates.Build(template, args)`. No concatena con `..` literales. Las constantes de herida NPC viven en `HarfordEmotes.NPC_WOUND.id` y `HarfordEmotes.NPC_WOUND_CRIT.id`.
- Funciones actuales:
  - `HarfordServerActions.GiveItem(itemId, quantity, opts)`: envia `additem <itemId> <quantity>`.
  - `HarfordServerActions.GetPhaseInfo(callback, opts)`: envia `phase info addon` con callback via EpsilonLib.
  - `HarfordServerActions.SetNpcHealthDelta(delta, opts)`: envia `npc set health +N/-N`, validando delta numerico y limite absoluto. Al aceptar una perdida mayor que `1` (`delta < -1`) envia tambien una reaccion de herida sobre el mismo NPC target: `npc emote 33` (`HarfordEmotes.NPC_WOUND`, `ONESHOT_WOUND`) por defecto o `npc emote 34` (`HarfordEmotes.NPC_WOUND_CRIT`, `ONESHOT_WOUND_CRIT`) si `opts.isCritical = true`; no lo hace para `-1`, curacion ni inmunidad que deje el daño en `0`. La reaccion vive aqui para cubrir turnos, menu admin y ataques sin duplicar logica.
  - `HarfordServerActions.RepossessCurrentNpc(opts)`: envia la cadena fija `unposs` → `poss` mediante `HarfordEpsilonCommands.SendChain`/EpsilonLib, sin puntos iniciales. Es una accion validada para refrescar la posesion del NPC target desde herramientas DM; no acepta texto libre.
  - `HarfordServerActions.UnpossessCurrentNpc(opts)`: envia `unposs` mediante el wrapper seguro, forzando EpsilonLib. Se usa para soltar la posesion cuando el DM activa el gesto sin tener un NPC target.
  - `HarfordServerActions.SendNpcTRP3Hyperlink(hyperlink, opts)`: envia `npc te <hyperlink totalrp3>` solo para enlaces creados y registrados por `HarfordTRP3`, limita el payload a `<250` bytes y fuerza `EpsilonLib.AddonCommands`. `opts.textPrefix` antepone texto al hyperlink; `opts.textSuffix` lo anexa DESPUES (lo usa `HarfordAdminNPC` para el nombre plano del `focus`: `npc te [estado] <Focus>`).
  - `HarfordServerActions.SetPhaseNpcFaction(factionId, opts)`: envia `ph f n fac <FactionID>` para asignar al NPC target la faccion Epsilon configurada en una reputacion Harford. El comando se envia sin punto inicial por el wrapper.
  - `HarfordServerActions.ModAnim(animId, opts)`: envia `mod anim <animId>`. Usado por el DM para reproducir animaciones sobre su personaje al golpear a un target (animId 33 = golpe de combate genérico).
  - `HarfordServerActions.ApplyAura(spellId, opts)`: envia `aura <spellId> self`. Solo para el propio personaje (jugador).
  - `HarfordServerActions.ApplyAuraToCurrentTarget(spellId, opts)`: envia `aura <spellId>` (sin sufijo). Para otro jugador seleccionado en el cliente.
  - `HarfordServerActions.RemoveAuraSelf(spellId, opts)`: envia `unaura <spellId> self`. Solo para el propio personaje (jugador).
  - `HarfordServerActions.RemoveAura(spellId, opts)`: envia `unaura <spellId>` (sin sufijo). Para otro jugador seleccionado en el cliente.
  - `HarfordServerActions.SetNpcAura(spellId, opts)`: envia `npc set aura <spellId>`. Para NPCs (el DM lo aplica al NPC actualmente seleccionado/controlado).
  - `HarfordServerActions.RemoveNpcAura(spellId, opts)`: envia `npc set unaura <spellId>`. Para NPCs.
  - **Resumen de comandos Epsilon por contexto**: jugador propio → `aura/unaura ID self`; jugador ajeno seleccionado → `aura/unaura ID`; NPC → `npc set aura/unaura ID`. Nombres literales de jugador como sufijo **no funcionan**.
  - `HarfordServerActions.SendRawDebug(command, callback, opts)`: comando raw solo si `HarfordDebug` esta activo.
- `Harford/Loot/HarfordLoot.lua` debe usar `HarfordServerActions.GiveItem` para `additem` y `HarfordAuras.Apply("loot")` / `HarfordAuras.Remove("loot")` para la aura visual (ya no maneja el id 224063 literal). Al lotear, no marcar la entrada como consumida ni sincronizarla hasta que el callback de `GiveItem` confirme exito; mientras espera confirmacion, el boton queda bloqueado solo en runtime para evitar doble click. Si el comando falla, el bloqueo se limpia y el boton permanece disponible.
- Nuevas features DM/NPC deberian anadir acciones aqui antes de crear UI.

Contrato `HarfordActionSequence`:

- Vive en `Harford/Server/HarfordActionSequence.lua`. Motor ligero de "secuencias de acciones con delay", equivalente reducido a una ArcSpell de SpellCreator (lista de pasos temporizados). Diseñado tras estudiar `SpellCreator/Actions/Execute.lua` + `Data.lua`.
- Las secuencias hardcodeadas viven en `Harford/Server/HarfordActionSequencePresets.lua`, no en `HarfordDnD.lua` ni en la UI. Ese archivo es solo datos decodificados desde seriales de SpellCreator y registra cada preset con `HarfordActionSequence.Register(name, actions)`.
- Una secuencia es un array de pasos `{ delay, kind, input, self }`: `delay` en segundos (varios pasos con el mismo delay se disparan juntos), `kind` el tipo de accion, `input` string de argumento(s), `self` opcional (sufijo `self` para comandos servidor que lo aceptan). Tambien acepta aliases estilo SpellCreator: `actionType`, `vars`, `selfOnly`.
- **`.ph dm` y `.mod anim`**: en modo DM, `.mod anim <id>` se aplica al TARGET seleccionado, no a uno mismo (por eso la animacion de defensa/herida/swing del propio personaje aparece sobre el target/ToT cuando el ejecutor es un DM con target). NO existe `mod anim <id> self` (comando invalido en Epsilon), asi que no se puede forzar self por sufijo. Es comportamiento propio de `.ph dm`; en juego normal (defensor/atacante sin `.ph dm`) `.mod anim` anima a uno mismo correctamente.
- `API.ACTIONS` (tipos): `anim` / `Anim` (`mod anim <id>` via `HarfordServerActions.ModAnim`), `cast` (`cast <id>`), `npccast` (`npc cast <id>`), `command` / `Command` (comando servidor crudo con/sin punto), `sound` / `TRP3e_Sound_playLocalSoundID` (`TRP3_API.utils.music.playLocalSoundID(soundID, channel, distance)`, requiere TRP3 Extended; input `"id, canal, distancia"`). `sound` replica la accion "Play Sound Nearby" de SpellCreator: usa el broadcast posicional de TRP3e, no `PlaySound` local inmediato; por eso puede depender del roundtrip/procesado de TRP3e. `anim`/`cast`/`npccast` aceptan solo IDs numericos positivos; texto libre debe pasar por `command` de forma explicita. Con `opts.npcAnim`, `anim` no usa `mod anim` sino `HarfordServerActions.SetNpcEmote(id, opts)` (`.npc emote <id>` one-shot) para animar a un NPC NO poseido (mod anim solo afecta a uno mismo/poseido); el sonido no cambia. Ademas, con `npcAnim` solo se ejecuta el PRIMER paso `anim` de la secuencia: los siguientes (la "vuelta a postura") se OMITEN, porque en un NPC pisarian su `npc emote ... repeat` y se quedaria atascado en esa pose; al no emitirlos, su postura en bucle prevalece tras el one-shot. Lo usa la defensa parry/dodge/block del NPC defensor.
- API: `Run(sequence, opts)` programa los pasos con `C_Timer.NewTimer` (delay 0 = inmediato; opts se pasa a los comandos servidor, p.ej. `{ addonName="HarfordAdmin" }`); `Register(name, seq)` / `RunByName(name, opts)` para reutilizar; `Stop()` cancela los timers en vuelo.
- **Impacto (`opts.interceptImpact` + `opts.onImpact`)**: un paso es "de impacto" si lanza `npc cast` (kind `npccast`, o `command`/`Command` cuyo texto contiene `npc cast`); en SpellCreator ese paso aplica el golpe/herida al objetivo. Con `interceptImpact = true`, esos pasos **no se envian**: en su `delay` se llama a `onImpact(action, opts)` en vez de castear. Lo usa el orquestador de ataque (Fase 3) para despachar la reaccion del objetivo (herida si impacta, esquiva/parry si falla) sincronizada con el preset. Sin `interceptImpact`, comportamiento idéntico al anterior; las secuencias sin `npc cast` (parry/dodge/herida) no se ven afectadas.
- Transporte: los comandos servidor salen por `HarfordEpsilonCommands.Send` forzando `EpsilonLib.AddonCommands` (`forceEpsilon=true`, `showMessages=false`) para mantener el canal seguro. El sonido es la unica accion que usa la ruta TRP3e (`playLocalSoundID`) porque asi funciona el "Play Sound Nearby" de SpellCreator.
- No introducir resets automaticos de sonido: SpellCreator no limpia antes de `TRP3e_Sound_playLocalSoundID`; solo parsea `vars` y llama `TRP3_API.utils.music.playLocalSoundID(soundID, channel, distance)`. Los intentos de `stopLocalSoundID`/`stopSoundID` automaticos antes del play no resolvieron las segundas ejecuciones y pueden descompensar el broadcast.
- El motor **no** valida permisos: el llamador gatea (p.ej. accion de ataque NPC bajo Admin/oficial) y el servidor aplica sus propios permisos. El `kind = "command"` solo debe recibir texto de confianza definido por el DM, nunca recibido de la red.
- Diagnostico: `/harford debug run seqtest` ejecuta una secuencia de ejemplo (Anim + sonido nearby + `npc cast`) con comandos por EpsilonLib y sonido por TRP3e.

Sistema de animaciones y auras (cliente a cliente):

- **Opcodes en prefix `DND5EARC`** (via `HarfordSync`):
  - `ANIMFLG|0` / `ANIMFLG|1`: flag de preferencia de animaciones. Cada cliente lo envía junto a su respuesta `RES` cuando le solicitan recursos. Se cachea en `HarfordDnDResources.AnimFlagCache[nombre]` (tanto nombre corto como completo).
  - `DOAPPLYAURA|spellId`: opcode genérico — el DM puede pedir al target que aplique una aura sobre sí mismo. **No se usa para la aura de muerte 29266**: esa la gestiona el propio cliente del jugador de forma autónoma (ver abajo).
  - `DODEFENSE` (sin payload): el atacante fallo contra un jugador → su cliente ejecuta parry/dodge/block segun su propia postura/escudo (`HarfordDnDComm` → `deps.HandleDefense` → `HarfordDnDCombat.PlayLocalDefense`). Gateado por el flag de animaciones del receptor.
  - `DOWOUND|crit`: el atacante golpeo a un jugador → su cliente reproduce herida `mod anim 33` (`crit=0`) / `34` (`crit=1`) (`HarfordDnDComm` → `deps.HandleWound` → `HarfordDnDCombat.PlayLocalWound`). Se envia en el instante de impacto del preset (`TriggerWoundOnHit`). Gateado por el flag del receptor. El daño numerico viaja aparte por `RADJ`.
  - **Tirada de ataque a otro jugador (whisper extra)**: `HarfordDnDRolls.Broadcast` envia la tirada por `BestChannel()` (RAID/PARTY) y, si `rollData.targetUnit` es un jugador distinto de uno mismo que NO esta en tu grupo, ADEMAS por `WHISPER` a ese objetivo (en grupo ya la recibe por el canal; solo, igual le llega). Lo marcan `Ataque Arma`/`Ataque Conjuro`/maniobras (`targetUnit="target"`) y el ataque NPC→jugador (`targetUnit="focus"`, ignorado si el focus es NPC por el guard `UnitIsPlayer`). El handler `DND5EARC` no filtra por canal, asi que la tirada por WHISPER se renderiza igual que por RAID.
- **Flujo de daño con animación** (botón Daño en ficha NPC/DM):
  - **Victima NPC** (target no jugador con ficha NPC cargada):
    1. `RollActionDamage` en el core tira cada componente, llama `HarfordDamageMitigation.ForTarget("target", tipo, total)` por componente y muestra el daño ya mitigado con marcador coloreado R/V/I en la tirada publica.
    2. `ApplyNpcSheetDamage` recibe el total mitigado y llama `SetNpcHealthDelta(-total)`.
    3. `SetNpcHealthDelta` ejecuta `npc emote 33` (ONESHOT_WOUND) sobre la victima si la perdida es > 1, o `npc emote 34` (ONESHOT_WOUND_CRIT) si el daño aplicado viene marcado como crítico.
    4. `ApplyNpcSheetDamage` ejecuta adicionalmente `ModAnim(33)` sobre el personaje del DM (impacto visual del atacante).
    5. **El boton Daño NO reproduce ningun emote de tipo de ataque** (swing, postura): esa animacion es exclusiva del boton Atacar.
  - **Victima jugador** (target jugador con animaciones activas):
    1. Consultar `HarfordDnDResources.AnimFlagCache[shortName]` del target (nil = tratar como `true`).
    2. Si el flag esta activo: `HarfordServerActions.ModAnim(33)` (el DM se anima a si mismo).
    3. Aplicar daño: si el target es el propio jugador, consumir `temp_health` y luego `health` con `AdjustResourceCurrent` local (no hay cache remota propia). Si es otro jugador, consumir primero `temp_health` via `RADJ`; el resto descontar de `health` via `RADJ`.
    4. Las defensas de jugador se aplican si `ForTarget` encuentra una entrada en la lista derivada de resistencias/inmunidades/vulnerabilidades del perfil o en su stat block TRP3; si no hay dato, el daño queda normal.
  - ~~El DM no envía `DOAPPLYAURA|29266`~~ — el cliente receptor detecta hp=0 de forma autónoma.
- **Aura de muerte (29266) — gestionada por el propio jugador**:
  - **El DM NO envía `DOAPPLYAURA` para la aura de muerte.** Es el cliente del jugador quien la gestiona en `AdjustResourceCurrent("health", delta)`.
  - Cuando `health` baja a ≤ 0: si `HarfordDnDStore.animsEnabled ~= false`, el cliente llama `HarfordServerActions.ApplyAura(29266)` y activa `HarfordDnDStore.deathAuraActive = true`.
  - Cuando `health` sube a > 0 y `deathAuraActive == true`, o cuando sale de `deathSaveActive` con animaciones activadas aunque la marca local de aura se haya perdido: el cliente llama `HarfordServerActions.RemoveAuraSelf(29266)` y baja la flag. La recuperacion de `Salv Muerte` debe ser autoritativa para no dejar la animacion de moribundo pegada tras sync/reload.
  - Cubre todos los caminos de cambio de vida: botones UI, `RADJ` remoto, descanso, `AdjustResourceCurrent` directo.
- **Checkbox de animaciones** (SEC_ATK de la ficha jugador):
  - `HarfordDnDStore.animsEnabled` (boolean, default `true`): preferencia local del jugador. Controla si el **propio jugador** recibe la aura de muerte al llegar a 0.
  - `HarfordDnDStore.animsCheckbox` / `HarfordDnDStore.animsCheckboxLabel`: referencias al widget.
  - Al hacer click envía `ANIMFLG` al canal activo (broadcast al grupo/raid).
  - **Oculto en modo NPC**: `RefreshSheetActionPanel` llama `chk:SetShown(not inNpcMode)` y `label:SetShown(not inNpcMode)`.
  - Al enviar respuesta `RES` a un target que nos solicita recursos, siempre se incluye también el envío del `ANIMFLG` actual al remitente.
- **`HarfordDnDStore.deathAuraActive`**: campo booleano de `HarfordDnDStore`. Registra si el cliente tiene activa la aura de muerte 29266. No persistir entre sesiones; se inicializa `false` o `nil` en cada login.
- **Semántica confirmada de `.aura`/`.unaura` en Epsilon**:
  - Propio personaje → `aura ID self` / `unaura ID self` (sufijo "self" obligatorio).
  - Target actual (otro jugador o NPC seleccionado) → `aura ID` / `unaura ID` (sin sufijo; Epsilon lo aplica al unit seleccionado en juego). El nombre de jugador como sufijo **no funciona**.
- **`HarfordServerActions.ApplyAura(spellId)`**: envía `aura ID self`. Para el propio personaje.
- **`HarfordServerActions.ApplyAuraToCurrentTarget(spellId)`**: envía `aura ID` (sin sufijo). Para el unit actualmente seleccionado.
- **`HarfordServerActions.RemoveAuraSelf(spellId)`**: envía `unaura ID self`. Para el propio personaje.
- **`HarfordServerActions.RemoveAura(spellId)`**: envía `unaura ID` (sin sufijo). Para el unit actualmente seleccionado.

Sistema moribundo (`HarfordDnD.lua` — bloque `do...end` tras la IIFE de botones):

- **Decision de arquitectura**: no extraer este sistema a otro modulo. Ya vive en un `do...end` y solo consume la forward decl `RefreshDyingState`; sacarlo obligaria a exponer/injectar `SEC_SAV`, `AbilityButtons`, `SaveButtons`, `Layout3Col`, `ShowDnDTab`, `FormatSaveButtonText`, `_dsLabel` y `AdjustResourceCurrent`, aumentando riesgo en una zona delicada para liberar ~1 local.

- **Activación**: cuando `GetResourceCurrent("health") <= 0` y no hay contexto NPC activo (`SheetContext.active = false`). `RefreshDyingState()` es el punto de entrada único; lo llama `AdjustResourceCurrent` al final cuando `key == "health"`, `DND5E_ARC_API.Refresh` (tras `RefreshButtons`/`ShowDnDTab`), y también `ApplySheetContext` y `ClearSheetContext` al final para coordinar transiciones con el modo NPC.
- **Separacion estado persistido vs estado visual**: `HarfordDnDStore.deathSaveActive` + contadores viven independientemente de los widgets. Esto permite que al activar modo NPC con jugador moribundo, la UI se vea normal sin perder el progreso de las Salv Muerte; al desactivarlo, la UI moribundo se re-aplica si HP sigue ≤ 0.
- **`ApplyDyingVisualState()`**: solo widgets. Fuerza pestaña BASE, deshabilita ATK/SKL tabs, deshabilita `AbilityButtons`, oculta salvaciones no-CON, centra CON como "Salv Muerte" y muestra `_dsLabel`. Idempotente, no toca contadores.
- **`ClearDyingVisualState()`**: solo widgets. Habilita características, salvaciones y tabs ATK/SKL, restaura texto CON con `FormatSaveButtonText`, llama `Layout3Col` para recolocar, `ShowDnDTab(ActiveTab)` y oculta `_dsLabel`. Idempotente, no toca contadores.
- **`EnterDyingState()`**: pone `deathSaveActive=true`, resetea contadores a 0 y llama `ApplyDyingVisualState`.
- **`ExitDyingState()`**: pone `deathSaveActive=false`, resetea contadores a 0 y llama `ClearDyingVisualState`.
- **`RefreshDyingState()`**: en `SheetContext.active` llama `ClearDyingVisualState` si `deathSaveActive` (visualmente normal aunque siga moribundo) y retorna. En modo jugador: `hp<=0 && !dying` → `EnterDyingState`; `hp<=0 && dying` → `ApplyDyingVisualState` (cubre tanto refresh post-tirada como retorno desde modo NPC); `hp>0 && dying` → `ExitDyingState`.
- El boton superior `Recursos` permanece usable para consultar o modificar los recursos propios mientras se esta moribundo.
- **Contador** (`_dsLabel` en SEC_SAV): FontString anclado `BOTTOM, SEC_SAV, BOTTOM, 0, 10`. Formato compacto visual: `fallos|exitos`, con fallos rojos, separador neutro y exitos verdes; sin signos ni espacios porque el color ya indica el significado. Al entrar empieza en `0|0`. `UpdateDyingUI()` vuelve a centrar `Salv Muerte` en cada refresh porque `Layout3Col` puede restaurar la celda original del boton CON.
- **`HarfordDnDStore.deathSaveActive`** (bool), **`deathSaveSuccesses`** (int), **`deathSaveFailures`** (int): estado en HarfordDnDStore para no consumir locales de file-scope.
- **Refresco de `Recursos` durante moribundo**: `AdjustResourceCurrent` debe llamar `RefreshResourceFrame()` si el frame local esta abierto despues de aplicar cualquier delta. Es imprescindible cuando `Salv Muerte` llega a tres exitos y recupera 1 de salud, para que la barra pase de `0/max` a `1/max` sin cerrar/reabrir la ventana.
- **Botones `+`/`-` del frame de recursos del player** (`ResourceFrame`): click normal suma/resta 1; `Shift+click` en Salud actua sobre `temp_health`; `Ctrl+click` abre un prompt numerico (`StaticPopupDialogs["HARFORD_RESOURCE_ADJUST"]`, helper `PromptResourceAdjust(key, sign)`) para sumar (boton `+`) o restar (boton `-`) una cantidad concreta a ese recurso (aplica `AdjustResourceCurrent` + `RefreshResourceFrame`).
- **Tirada Salv Muerte** (`DoDeathSave()`): reutiliza el cálculo normal de `Salv CON` (`GetSaveRollBonuses("Constitucion")`, modo de tirada y modificador global) y resuelve éxito con el total. Un 20 natural suma dos éxitos y un 1 natural suma dos fallos; en el resto, total `>= 10` suma un éxito y total `< 10` un fallo. El broadcast lleva label especial `Salv Muerte fallos|éxitos`, con números coloreados y sin signos/corchetes, para mostrar el acumulado en chat. Al llegar a tres éxitos llama `AdjustResourceCurrent("health", 1)`, sale del estado y, si las animaciones estan activadas, fuerza retirar la aura de moribundo; a tres fallos pasa a `Incapacitado`.
- **Botón CON override**: `SetScript("OnClick", ...)` aplicado sobre `SaveButtons["Constitucion"]` tras el IIFE. Si `deathSaveActive` → `DoDeathSave()`, si no → `DoRoll("Salv CON", ...)` normal.
- **`RefreshDyingState`**: local forward-declared al inicio del chunk (1 local de file-scope). Asignada en el bloque `do...end` de moribundo.

Contrato `HarfordReputation` (core):

- `HarfordReputation.GetFaction(id)` → tabla de faccion o nil.
- `HarfordReputation.GetFactions(includeHidden)` → lista ordenada. Orden: `sortOrder` ASC, luego nombre alfabetico.
- `HarfordReputation.GetRank(points)` → `name, colorARGB, rankTable`. Rangos: Odiado→Hostil→Adverso→Neutral→Amistoso→Honorable→Reverenciado→Exaltado. Tabla confirmada:
  | Rango        | min    | max    | Tamaño |
  |---|---|---|---|
  | Odiado       | -42000 | -6001  | 36000  |
  | Hostil       |  -6000 | -3001  |  3000  |
  | Adverso      |  -3000 |    -1  |  3000  |
  | Neutral      |      0 |  2999  |  3000  |
  | Amistoso     |   3000 |  8999  |  6000  |
  | Honorable    |   9000 | 20999  | 12000  |
  | Reverenciado |  21000 | 41999  | 21000  |
  | Exaltado     |  42000 | 42999  |  1000  |
  Neutral empieza en 0. `API.MIN_POINTS = -42000`, `API.MAX_POINTS = 42999`.
- `HarfordReputation.GetPlayerPoints(playerKey, factionId)` -> `points, repEntry`. La reputacion es estrictamente por personaje; si ese PJ no tiene valor propio, devuelve 0. No hay herencia por gremio.
- `HarfordReputation.SetPlayerPoints(playerKey, factionId, points, opts)` → solo si `CanEdit()` o `opts.fromSync=true`.
- `HarfordReputation.IsAtWarPoints(points)` -> `true` desde `Hostil` hacia abajo (`points <= -3001`: Hostil/Odiado). Al subir por encima de Hostil (`Adverso`, `Neutral` o mejor) debe quitarse. `SetPlayerPoints` actualiza automaticamente `repEntry.atWar` en reputacion de jugador; sync tambien lo reconstruye al recibir puntos.
- Contrato `HarfordCharacterXP` (`Harford/Character/HarfordCharacterXP.lua`, 2026-08-20): sistema de experiencia PROPIO (Epsilon no tiene comando de XP real; el antiguo "reward.xp informativa" de HarfordQuests quedo retirado). La XP vive en `progression.xp` del perfil activo (`HarfordDnDProgression.Get()`, persiste con la ficha); tabla oficial 5e niveles 1-20 en `API.XP_TABLE`. API: `GetXP`/`SetXP`/`AddXP(amount, reason)`/`LevelForXP`/`Progress`/`PendingLevelUp`/`Refresh`. `SetXP` delega en `HarfordDnDProgression.SetXP`, que normaliza el valor e invalida los derivados del perfil. El campo se serializa como `x=<xp>` dentro de `DNDCLASS`/`DNDINSCLASS`; clientes antiguos lo ignoran y los nuevos conservan la XP al compartir o inspeccionar una ficha. `AddXP` imprime la ganancia y anuncia "Nivel N disponible" al cruzar umbral, pero NUNCA aplica niveles: la subida sigue siendo manual con `/harford char subir` (no hay pestaña inferior de Subida). El nivel total esta limitado a 20, incluida multiclase, importacion y avance manual. Barras visuales propias (XP morado + reputacion seguida opcional) ancladas en `UIParent/MEDIUM` nivel 85: no registrar ni modificar `StatusTrackingBarManager`, cuyos contratos privados fallan en Epsilon antes de que un addon pueda completar la barra. Gate `HarfordConfig` clave `xpbar` (default on); texto fijo con `statusTextDisplay`, si no al hover. `HarfordQuests.ClaimRewards` concede `reward.xp` via `AddXP`. **Barra de reputacion seguida** (mismo modulo, misma opcion `xpbar`): solo visible si hay faccion seguida (`Ctrl+click` en una fila de faccion del panel togglea `HarfordReputationStore.ui.watchedByChar[nombreCorto]`; API `Get/Set/ToggleWatchedFaction`); color nativo por rango (`FACTION_BAR_COLORS`), texto `Faccion: cur / max (Rango)`, rango tope lleno. `HarfordReputation.FireChanged` refresca tambien esta barra.
- **Barras de XP/reputacion: por que no subian la barra de accion ni tenian marco (2026-08-21)**.
  El commit que introdujo el sistema (`a059050`) tiene un mensaje que describe barras REGISTRADAS
  en `StatusTrackingBarManager` ("el gestor recoloca la UI solo"), pero el codigo que entro en ese
  mismo commit ya era la version suelta con `barHolder` en `UIParent BOTTOM 0,0`. El mensaje nunca
  se actualizo, asi que parecia que debia funcionar. **Nunca funciono en `dev`.**
  Lo que el gestor daba gratis al estar registradas eran dos cosas:
  1. **Subir la barra de accion.** Cadena nativa: `StatusTrackingBarManager:LayoutBars()` ->
     `MainMenuBar:OnStatusBarsUpdated()` -> `MainMenuBar:SetPositionForStatusBars()` ->
     `SetYOffset(0|14|19)` + `UIParent_ManageFramePositions()` -> `UIParent.lua` ancla
     `MainMenuBar:SetPoint("BOTTOM", UIParent, 0, GetYOffset())`. El offset sale de
     `GetNumberVisibleBars()`, que recorre `mgr.bars`; sin registrar, devuelve 0.
  2. **El marco.** NO esta en `StatusTrackingBarTemplate` (solo StatusBar + fondo negro 0.9 +
     texto): son cuatro texturas de atlas del MANAGER, `hidden="true"`, mostradas por `LayoutBar`.
  **Solucion adoptada**: replicarlo a mano SIN registrar (los contratos privados del gestor
  siguen fallando en Epsilon). Geometria nativa exacta, verificada con el interprete Lua:
  - una barra: `BOTTOM MainMenuBar 0,-14`; marco a `CENTER` de la barra `0,0`, alto natural.
  - dos barras: superior `0,-10`, inferior `0,-19`; marco `Upper` a `CENTER+4` y base a
    `CENTER-9` **sobre la barra SUPERIOR** (ambas piezas se anclan a la misma), alto natural - 4.
  - StatusBar mide `ancho - endCapWidth*2` (`endCapWidth = 4`), no el ancho completo.
  - atlas `hud-MainMenuBar-experiencebar-large-single` o `-small-single` segun
    `MultiBarBottomRight:IsShown()` (`MainMenuBar.lua`: `isLargeSize = rightMultiBarShowing`).
  - `MainMenuBar:SetYOffset(14|19|0)` + end caps a `-98,-offset` + `UIParent_ManageFramePositions()`.
  **Cuidado**: `UIParent_ManageFramePositions` recoloca frames protegidos -> guardar con
  `InCombatLockdown()` y reintentar en `PLAYER_REGEN_ENABLED`; y respetar `IsUserPlaced()`, que el
  propio nativo comprueba antes de mover nada. El nativo reescribe `yOffset` cada vez que recalcula
  sus barras, asi que hay `hooksecurefunc` sobre `SetPositionForStatusBars` para reaplicarlo.
  `ClearAllPoints` en AMBAS ramas del marco: `SetPoint` acumula y al pasar de una barra a dos
  arrastraria los anclajes anteriores. Diagnostico: `/harford debug run xpbar`.
- **Ventana standalone de reputacion RETIRADA (2026-08-20)**: `HarfordReputationUI.Toggle`/`Open` delegan en `HarfordCharacterPanel.Toggle/Open("reputation")`; `/harford rep`, la bandeja de herramientas y el boton de la ficha abren esa pestaña. El flujo de ventana flotante (CreatePanel standalone + DetachEmbedded) se conserva SOLO como fallback si el panel de personaje no esta cargado y como soporte del embebido; no re-exponer la ventana suelta como via principal.
- Sonidos del panel de reputacion (confirmado con `nativeprobe` + observacion en juego 2026-08-20): el frame nativo suena `856 igMainMenuOptionCheckBoxOn` al seleccionar una faccion; **expandir/colapsar CABECERAS de grupo es silencioso** (no reproducir 856/857 ahi). Ampliado 2026-08-21 con una captura nueva sobre `ReputationBar`: abrir el DETALLE de una faccion suena **839** y cerrarlo **840** (`reputation_detail_opened`/`_closed`). O sea, seleccionar una faccion que abre su detalle reproduce 856 y 839; el 840 va en el boton de cerrar del detalle. Cabeceras y detalle son cosas distintas: solo las primeras son mudas. `HarfordReputationUI` reproduce 856 en el click de fila de faccion. La apertura/cierre del panel ya la cubren los kits propios del CharacterPanel (567422/567440). Version previa al ajuste guardada en `HarfordReputationUI.lua.pre-sonda.bak` (no carga en toc; borrar cuando el cambio quede validado).
- Visual `At War` en `HarfordReputationUI`: no basta con guardar `repEntry.atWar`. La fila debe mostrar dos texturas nativas `AtWarHighlight1/2` con `Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar`, alpha ~0.20, replicando `ReputationBarXReputationBarAtWarHighlight1/2` del `FrameDump`. Deben ir embebidas en el marco de la fila: `AtWarHighlight1` empieza en `indent+3` (donde empieza el marco de esa fila) y se une a `AtWarHighlight2`, que cierra en `TOPRIGHT row -1,-2`. Usar capa `OVERLAY -2`: `ARTWORK -1` queda tapado por el marco/fondo, mientras `OVERLAY -2` sigue por debajo del texto (`Name`/`FactionStanding`) y no flota por encima de la seleccion. Se muestran solo en filas de faccion con `atWar=true`; headers las ocultan.
- `HarfordReputation.AdjustTarget(factionId, delta)` -> ajusta al target jugador actual por su `playerKey`.
- `HarfordReputation.CanEdit()` → delega en `HarfordAuthority.CanUseDMTools()`: requiere simultaneamente `HarfordAdmin` cargado/activo y `.ph dm` confirmado. Tener solo `.ph dm` no carga ni habilita herramientas admin.
- `HarfordReputation.GetCurrentPlayerPoints(factionId)` → atajo al jugador local. En el panel principal, un jugador normal ve siempre su reputacion local. Si `HarfordAdmin` esta cargado, el modo DM esta activo y el target es un jugador, el panel puede mostrar las reputaciones de ese target para trabajo admin.
- En modo DM con target jugador, el panel principal **no debe leer los puntos del target desde el store local del DM**. Debe pedir una vista remota al cliente objetivo mediante `HarfordReputationSync.RequestPlayerSnapshot(playerKey)` y mostrar esa cache de solo lectura. Si aun no ha llegado la respuesta, mostrar estructura local/0 temporalmente antes que mezclar valores propios del DM.
- No hay vinculos locales de NPC a reputacion (`npcLinks` eliminado). La relacion/faccion real del NPC vive en Epsilon. El boton `Asignar Faccion` solo ejecuta `.ph f n fac X` mediante `HarfordServerActions.SetPhaseNpcFaction`; no guarda tooltip, GUID ni estado local.
- `HarfordReputation.EnsureStore()` → inicializa `HarfordReputationStore` (crea claves vacias si faltan). **No inyecta facciones por defecto**: las facciones viven 100% en SavedVariables y se gestionan desde `/harfordadmin rep`.
- `HarfordReputation.CreateFaction(nameOrData, ...)` → acepta tabla `{name,description,icon,color,epsilonFactionId,group,subgroup,hidden,sortOrder}` o args posicionales. Devuelve `true, id`.
- `HarfordReputation.UpdateFaction(factionId, data)` → edita todos los campos incluyendo `sortOrder` (si `data.sortOrder ~= nil`).
- `HarfordReputation.GetGroups()` → `[{name, subgroups=[...]}]` — lista de grupos únicos con sus subgrupos.
- `HarfordReputation.CreateGroup(name)` → crea un encabezado de grupo persistente aunque aun no tenga facciones.
- `HarfordReputation.CreateSubgroup(groupName, subgroupName)` → crea una seccion persistente dentro de un grupo aunque aun no tenga facciones.
- `HarfordReputation.SetFactionGroup(factionId, groupName, subgroupName)` → mueve una faccion a un grupo/seccion.
- `HarfordReputation.RenameGroup(oldName, newName)` → actualiza `faction.group` en todas las facciones del grupo.
- `HarfordReputation.RenameSubgroup(groupName, oldSub, newSub)` → renombra subgrupo dentro de un grupo.
- `HarfordReputation.DeleteGroup(groupName)` → borra solo grupos vacios, incluido `Reputaciones Harford` si esta vacio. No debe mover facciones automaticamente al grupo base ni recrear `Reputaciones Harford`, porque eso genera encabezados fantasma al limpiar estructura. Si el grupo tiene facciones, bloquear y pedir mover/borrar primero.
- `HarfordReputation.DeleteSubgroup(groupName, subgroupName)` → elimina la seccion y deja sus facciones en la raiz del mismo grupo.
- `HarfordReputation.DeleteGroup(groupName)` → borra el encabezado persistente; si contiene facciones, no las borra, las mueve al grupo base `Reputaciones Harford` sin subgrupo. No permite borrar el grupo base.
- `HarfordReputation.DeleteSubgroup(groupName, subgroupName)` → borra la seccion persistente; si contiene facciones, no las borra, les limpia `subgroup` para dejarlas en la raiz del grupo.
- `HarfordReputation.SwapFactionOrder(factionIdA, factionIdB)` → intercambia `sortOrder` entre dos facciones (uso: botones ↑/↓ en panel admin).
- `HarfordReputation.SetFactionSortOrder(factionId, order)` → asigna sortOrder directamente.
- `HarfordReputation.MoveFactionOrder(factionId, direction)` → normaliza sortOrder y mueve una faccion una posicion en el orden global.
- `HarfordReputation.MoveGroupOrder(groupName, direction)` → normaliza `sortOrder` y mueve un grupo una posicion arriba/abajo en el panel admin.
- `HarfordReputation.MoveSubgroupOrder(groupName, subgroupName, direction)` → normaliza `subgroupOrder` y mueve una seccion una posicion dentro de su grupo.
- `HarfordReputation.GetGroups()` debe respetar `group.sortOrder` y `group.subgroupOrder`; no debe devolver el subgrupo vacio como una seccion real.
- `HarfordReputation.ResolveIconTexture(value)` -> los iconos de reputacion se guardan siempre como nombre corto (`INV_...`, `Ability_...`, `ability_xxx`), sin ruta. Para renderizar, Harford hardcodea `Interface\\Icons\\` + nombre. Si recibe datos antiguos con `Interface\\Icons\\...`, `NormalizeIconName` los limpia antes de guardar/mostrar.
- No hay facciones por defecto hardcodeadas en el core actual: se crean y gestionan desde `/harfordadmin rep`.
- `HarfordReputationStore` guardado en SavedVariables; estructura viva: `{factions={}, players={}, groups={}, ui={}}`. **No persistir logs**: `logs` se considera ruido y `EnsureStore` lo borra; `AddLog` solo imprime/refresca. **No persistir `guilds`**: la reputacion es por PJ, no por gremio; `EnsureStore` borra restos antiguos. **No persistir `npcLinks`**: fue eliminado por duplicar la faccion real de Epsilon y quedar obsoleto; `EnsureStore` borra restos antiguos. Cada faccion puede tener `sortOrder` (number, default 0). `groups` guarda encabezados/secciones persistentes aunque esten vacios; cada grupo puede tener `sortOrder` y `subgroupOrder={ [subgroupName]=number }`.

Contrato `HarfordReputationAdmin` (solo HarfordAdmin):

Actualizacion NPC/Faction ID Epsilon:

- Cada faccion puede guardar `epsilonFactionId` opcional, normalizado con `HarfordReputation.NormalizeEpsilonFactionId(value)`. Vacio significa que no hay faccion Epsilon asignable; valores no numericos, negativos o `0` se limpian.
- El campo admin `Faction ID` vive en el formulario de faccion y se comparte en snapshots `FAC` de `HarfordReputationSync` junto a la estructura.
- Si el detalle de reputacion esta abierto en modo DM y el target actual es un NPC/no jugador, el boton de accion cambia a `Asignar Faccion`. No abre el prompt de ajuste: valida que la reputacion seleccionada tenga `epsilonFactionId` y llama a `HarfordServerActions.SetPhaseNpcFaction(epsilonFactionId, { addonName = "HarfordAdmin", forceEpsilon = true })`.
- Si falta `epsilonFactionId`, no se envia ningun comando y se informa al usuario. El comando Epsilon real es `.ph f n fac X`, pero Harford lo envia al wrapper sin punto inicial: `ph f n fac X`.

- Panel GM flotante para gestionar facciones: crear, editar, reordenar, renombrar grupos.
- `HarfordReputationAdmin.Toggle()` → abre/cierra; comprueba `CanEdit()` antes de mostrar.
- `HarfordReputationAdmin.Open()` / `Close()` → acceso programatico.
- `HarfordReputationAdmin.Refresh()` → recarga lista + refresca HarfordReputationUI si esta abierto.
- Acceso: `/harfordadmin rep` | `/harfordadmin reputacion` | boton `Admin` en panel principal (visible solo en modo DM + HarfordAdmin cargado).
- Lista izquierda (322px): groups → subgroups → facciones. Headers tienen botones subir/bajar, Renombrar (inline popup) y borrar con Shift+click; click en un grupo/subgrupo selecciona el destino para guardar o mover facciones. Filas de faccion tienen botones ASCII/textura para subir/bajar (swapOrder), visibilidad, editar y borrar con Shift+click obligatorio para evitar borrados accidentales.
- Form derecha (326px): campos Nombre, Icono (con preview en vivo), Color AARRGGBB (con swatch en vivo), Descripcion multilinea alta y Faction ID opcional de Epsilon. `Descripcion` debe ser un textarea compuesto con marco interior propio, `ScrollFrame` interno y altura reservada, no un `InputBoxTemplate` alto directo, para que el texto quede recortado dentro del marco y no desborde sobre el Faction ID/Botones. No usar `EditBox:GetStringHeight()` en este cliente: no existe en Epsilon/SL y rompe el admin. Botones: Guardar, Mover aqui y Cancelar. No poner boton `Nueva` dentro del form; para nueva faccion se usa el boton superior `Nueva faccion`.
- No editar `group` ni `subgroup` como texto libre en el formulario de faccion. La asignacion a grupo/subgrupo debe resolverse mas adelante con estructura/orden del panel admin, no escribiendo nombres a mano.
- Botones `Grupo` y `Seccion` crean encabezados/secciones desde prompt. `Seccion` se crea dentro del grupo seleccionado. El formulario muestra `Destino: grupo / seccion`; guardar una faccion nueva o editada la asigna a ese destino.
- Si se borra el grupo seleccionado, el admin debe limpiar el destino (`Sin destino seleccionado`) para no recrear por accidente el encabezado borrado al guardar/crear.
- La lista admin se desplaza con rueda de raton sobre el area de facciones; no usar botones visibles `^/v` para scroll porque ensucian el encabezado.
- Los botones de subir/bajar de grupos y secciones normalizan su orden persistente (`sortOrder` / `subgroupOrder`) antes de intercambiar con el elemento adyacente. Las secciones solo se mueven dentro de su grupo.
- Los botones de subir/bajar de facciones en el admin primero normalizan el `sortOrder` segun el orden visible y luego intercambian con la faccion adyacente visible. Esto evita el bug de "no se mueve" cuando varias facciones tienen `sortOrder = 0`.
- Subir/bajar solo debe moverse dentro del mismo grupo/subgrupo visible. Para mover entre secciones, editar una faccion, seleccionar un grupo/subgrupo destino y pulsar `Mover aqui` o guardar con ese destino.
- En `HarfordReputationAdmin.BuildFlatList()`, las facciones con `subgroup == ""` son raiz directa del grupo y se emiten justo debajo del header de grupo, antes de las secciones. No volver a meter el subgrupo vacio dentro de `subOrder`: visualmente hace que parezcan colgar de la ultima seccion.
- No mostrar `Orden` como campo editable: el orden se controla con subir/bajar. No mostrar checkbox `Oculta` en el form: la visibilidad se controla desde el boton de fila `Oc/Ver` y solo afecta a clientes que no estan en modo DM.
- Icono y color en el form admin tienen selector auxiliar:
  - Icono: boton `...` abre `HarfordRepIconPicker`, un buscador flotante estilo TRP3 con parrilla 8x6, scroll por rueda/slider, filtro de texto, contador y tooltip por icono. Si TRP3/`LibRPMedia-1.0` esta cargado, se puebla con `LibRPMedia:FindIcons(..., { method = "substring" })` / `TRP3_API.utils.resources.getIconList`; si no, cae a iconos curados + iconos ya usados por facciones. El campo de texto debe contener solo el nombre del icono, no `Interface\\Icons\\`.
  - El selector de iconos debe ser un popup completo centrado (`FULLSCREEN_DIALOG`) y no anclarse al formulario: evita que clipee con el panel admin. Su fondo debe quedar dentro del borde visual, no `SetAllPoints` hasta el borde exterior.
  - Rendimiento del selector de iconos: filtrar/consultar `LibRPMedia` solo cuando cambia el texto del filtro o se abre el selector. El scroll debe usar la lista cacheada y repintar solo los botones visibles; no recalcular ni ordenar miles de iconos en cada `OnMouseWheel`/slider.
  - En el selector de iconos, guardar iconos TRP3 como nombre bare (`ability_xxx`) y resolverlos visualmente siempre con `Interface\\Icons\\<nombre>`. Las rutas completas (`Interface\\Icons\\...`) solo se aceptan como input legado y se normalizan al nombre corto.
  - Color: boton `...` abre `ColorPickerFrame` nativo y escribe color AARRGGBB en el campo. El swatch se actualiza en vivo.
- Una faccion nueva o movida recibe `sortOrder` al final del destino seleccionado (`max sortOrder del destino + 10`). El panel principal no debe ordenar facciones alfabeticamente dentro de una seccion; respeta el orden de `HarfordReputation.GetFactions`.
- `FormLoad(factionId)` no debe cambiar el destino seleccionado. El destino es una seleccion independiente del usuario: se cambia haciendo click en un grupo/subgrupo, no al pulsar `Edit` en una faccion. Esto permite seleccionar destino → editar faccion → `Mover aqui`.
- `renamePopup`: frame flotante DIALOG-level para renombrar un grupo/subgrupo desde la lista.
- Boton `X`: requiere `IsShiftKeyDown()` para confirmar; sin shift solo muestra aviso en chat.
- Evitar glifos Unicode en botones del panel admin: en Epsilon pueden no cargar segun fuente/locale. Usar textos ASCII cortos como `Ver`, `Oc`, `Edit`, `X`, `^`, `v`, o iconos de textura Blizzard si se sustituyen mas adelante.

Contrato `HarfordReputationUI`:

- La via principal es la pestaña `Reputacion` de `HarfordCharacterPanel`; `/harford rep`, `Toggle()` y `Open()` delegan en ella. `EmbedInto`/`DetachEmbedded` siguen siendo el mecanismo interno y el frame flotante solo es un fallback cuando el panel de personaje no esta disponible. No duplicar la lista ni reintroducir una ventana standalone como flujo normal.
- `HarfordReputationUI.Toggle()` / `Open()` → abren o cierran la pestaña integrada; `Close()` conserva el cierre programatico.
- `HarfordReputationUI.Refresh()` → recarga la lista (llamado por HarfordReputation al cambiar datos).
- El icono de acceso en la ficha (`HarfordDnD.lua`) es un Button 20x20 hijo de `F`, del mismo tamano que el boton de turnos, anclado junto al boton cerrar con `TOPRIGHT, close, TOPLEFT, -2, -11` para quedar en la misma fila superior. Textura `INV_Shirt_GuildTabard_01`, highlight `ButtonHilight-Square` en blend ADD. Abre `HarfordCharacterPanel.Toggle("sheet")` y solo cae a `HarfordReputationUI.Toggle()` si el panel de personaje no esta cargado. NO hay un tab "Reputacion" en la barra compacta de la ficha; esos botones son exclusivos para tiradas (Caracteristicas, Ataque, Habilidades).
- Arquitectura de tabs en HarfordDnD: 3 tabs compactos (`Caract.`, `Ataque`, `Habilidades`) con `TAB_W=118`, `TAB_GAP=6`, `TOTAL_TABS_W=366`, centrados en `SEC_W=392`. La progresion hardcodeada Harford ya no vive en esta barra: se edita en `HarfordCharacterPanel` (`Subida`). No recrear `SEC_CLS` ni `HarfordDnDStore.RefreshClassPanel`.
- Referencia visual correcta: `Interface/FrameXML/ReputationFrame.xml` y `Interface/FrameXML/ReputationFrame.lua` de Shadowlands. No usar el `ReputationFrame` moderno de Retail actual.
- Layout del panel: frame principal custom compacto (`PANEL_W=390`, `PANEL_H=460`) con cabeceras `Faccion` y `Prestigio`, lista SL con `ScrollBox` + `WowTrimScrollBar` cuando el cliente lo expone, y fallback manual de filas/scroll si Epsilon no tiene `ScrollUtil`/`CreateScrollBoxListLinearView`. `LIST_H=360` para mostrar una fila mas y reducir espacio inferior; mantener `LIST_W=336` para que la barra de prestigio siga alineada.
- La lista se construye desde `BuildFlatList()`: facciones de `HarfordReputation.GetFactions(includeHidden)`, agrupadas por `faction.group` y `faction.subgroup`. El estado colapsado vive en `HarfordReputationStore.ui.collapsedHeaders`.
- En modo DM con target jugador, `BuildFlatList()` puede alimentarse de `HarfordReputationSync.GetRemoteView(playerKey)`: usa `remoteView.groups`, `remoteView.factions` y `remoteView.points`. Esta vista remota es solo para mostrar/editar al target actual y no sustituye las SavedVariables del DM.
- El panel principal debe respetar el orden de `HarfordReputation.GetGroups()` para grupos/secciones y el `sortOrder` de facciones. Las facciones con `subgroup == ""` se muestran como raiz directa del grupo, antes de las secciones, igual que en el panel admin.
- Cada `elementData` debe tener `name`, `isHeader`, `isChild`, `isCollapsed`, `hasRep`, `value`, `min`, `max`, `standingID`, `standingText`; en filas de reputacion tambien `factionId`, `faction`, `rankColor`.
- **Fila custom tipo `HarfordReputationBarTemplate`**: creada por Lua con `CreateRow(parent)`. Estructura:
  ```
  Button (row, LIST_W × ROW_H)
  ├── BACKGROUND  solidBg              (tinte custom para headers)
  ├── ARTWORK     rowBg                (área nombre, LEFT→row LEFT indent | RIGHT→bar LEFT)
  ├── OVERLAY     Name (FontString)
  ├── Button      ExpandOrCollapseButton
  ├── StatusBar   bar                  (RIGHT→row RIGHT 0,0; BAR_W×BAR_H)
  │   ├── BACKGROUND  fill (Skills-Bar via SetStatusBarTexture)
  │   ├── OVERLAY -1  leftTex          (LEFT→bar LEFT; 62×21)
  │   ├── OVERLAY -1  rightTex         (RIGHT→bar RIGHT 0,0; 42×21) ← ancla al RIGHT del bar
  │   ├── ARTWORK     FactionStanding  (LEFT bar LEFT 2 | RIGHT bar RIGHT -2; ancho completo)
  │   └── Frame       ReputationStar   (siempre oculto — no flecha/estrella en ningún rango)
  └── Frame       hlFrame              (SetAllPoints(row); level=bar+1; EnableMouse=false)
      ├── OVERLAY 0   Highlight1       (cuerpo; texCoord 0→0.9609375, 0→0.4375; blend ADD)
      └── OVERLAY 0   Highlight2       (cap derecho; texCoord 0.9609375→1, 0→0.4375; 24×(ROW_H+8); TOPRIGHT→hlFrame TOPRIGHT 0,4; blend ADD)
  ```
- **Por qué hlFrame**: texturas en StatusBar (101px) quedan clipeadas a 101px aunque se anclen al row. Epsilon no extiende texturas mas alla del frame padre. `hlFrame` cubre el row entero y evita ese clipping.
- **Highlight1/Highlight2 son objetos SEPARADOS** — no asignar la misma referencia. `OnEnter` y `OnLeave` deben llamar `Show`/`SetShown` en AMBOS explicitamente. `InitializeRow` para headers debe ocultar AMBOS explicitamente (ya no los silencia `bar:Hide()` porque estan en hlFrame, no en bar).
- **Headers sin highlight**: `OnEnter`/`OnLeave` comprueban `not data.isHeader` antes de tocar el highlight. `InitializeRow` header: `row.Highlight1:Hide()` + `row.Highlight2:Hide()`.
- **leftTex/rightTex en OVERLAY -1**: el fill del StatusBar renderiza en Epsilon encima de ARTWORK, cubriendo los caps decorativos. Moviendolos a `OVERLAY -1` quedan por encima del fill y por debajo de los highlights (OVERLAY 0).
- **rightTex ancla a `RIGHT→bar RIGHT 0,0`** — no `LEFT→leftTex RIGHT`. En nuestra barra de 101px, leftTex cubre 62px (61%); anclando rightTex a leftTex.RIGHT quedaría casi fuera del área visible. La ancla al RIGHT del bar garantiza que el cap cierra el borde derecho de la barra.
- Texturas usadas: `UI-Character-ReputationBar` (caps/rowBg), `UI-Character-Skills-Bar` (fill), `UI-Character-ReputationBar-Highlight` (highlights), `UI-PlusButton-Up/MinusButton-UP/PlusButton-Hilight` (expand).
- `InitializeRow(row, elementData)`:
  - **Headers**: `ExpandOrCollapseButton` visible con `+`/`-`, `Name` dorado 12px, `ReputationBar:Hide()`, `rowBg:Hide()`, `FactionStanding:Hide()`, `ReputationStar:Hide()`, `Highlight1:Hide()`, `Highlight2:Hide()`.
  - **Facciones**: `Name` coloreado con `faction.color` (fallback blanco) en `FRIZQT__` 11; `FactionStanding` muestra `standingText`; hover lo sobreescribe con `cur / rng` formateado con separador de miles. `ReputationStar` siempre oculto.
  - **Barra Exaltado** (`standingID >= 8`): `SetMinMaxValues(0, 1000)` + `SetValue(1000)` — siempre llena. En hover muestra `"1.000 / 1.000"`. No usar el valor real de puntos para la barra en Exaltado.
  - **Resto de rangos**: `SetMinMaxValues(0, max-min)`, `SetValue(value-min)`. Hover: `FormatNum(value-min) .. " / " .. FormatNum(max-min+1)`.
  - `SetStatusBarColor(FACTION_BAR_COLORS[standingID])` con fallback a `ColorToRGB(rankColor)`.
  - Highlight: `Highlight1` TOPLEFT(row TOPLEFT indent-2, 4) → BOTTOMRIGHT(row BOTTOMRIGHT -24, -4). `Highlight2` posicion fija (set en CreateRow). Ambos `SetShown(isSelected)`.
- **`FormatNum(n)`**: separa miles con punto (`1.000`, `21.000`). Usado en hover text y cualquier numero de rep en la UI.
- Sangria confirmada: header raiz `x=2`, subheader `x=21`, reputacion hija `x=44`, reputacion raiz `x=25`.
- Click en header alterna `collapsedHeaders[key]` y regenera DataProvider/lista plana. Click en reputacion asigna `selectedFactionId` y refresca detalle. El boton `ExpandOrCollapseButton` (hijo del row Button) tiene su propio `OnClick` delegado al mismo handler — sin esto Epsilon no propaga el click al row padre.
- **Panel de detalle lateral** (derecha del panel principal): replica compacta de `ReputationDetailFrame` de Shadowlands segun `FrameDump.lua`: tamano aproximado `212x203`, anclado fuera del panel principal con `TOPLEFT` al `TOPRIGHT` del panel de reputacion (`x=1`, `y=-18`) para quedar pegado al borde derecho y algo mas alto sin solaparse con el marco, marco `DialogBorderTemplate`, boton cerrar `UIPanelCloseButton`, icono de faccion arriba a la izquierda, nombre con fuente nativa (`FRIZQT__` 12) coloreado con `faction.color` y descripcion debajo con fuente `FRIZQT__` 11. La descripcion usa altura `132` cuando no hay acciones DM visibles para aprovechar el cuerpo hasta abajo; si el boton DM `Ajustar...` esta visible baja a `108` para no solaparse. Composicion de fondos: base negra habitual ocupando todo el interior del frame, cabecera oscura hasta `y=-52` y textura `Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal` (la misma que usan secciones internas como Ataque) desde `y=-52` hasta abajo, siempre en capa `BACKGROUND` para no tapar el marco; encima del pergamino hay un oscurecedor negro `alpha=0.22` para conservar la textura pero bajar su brillo. Entre cabecera y descripcion hay un separador fino propio de dos lineas (`BLACK` + dorado tenue), no la textura nativa `131074`: esa textura corresponde al divisor inferior del `ReputationDetailFrame` antes de los checkboxes nativos y no debe reutilizarse en cabecera. No usar el fileID nativo `136565` como fondo expandido: en Epsilon deja zonas transparentes al escalarlo. No mostrar bloque inferior de booleanos (`Relacion`, `Progreso`, `Visible`) ni su separador. Accion DM compacta: un unico boton `Ajustar...`.
- **`adjustPrompt` / boton de accion del detalle**: frame 200×85, hijo de `panel`, aparece encima del detalle (`BOTTOM→detail TOP 0,6`). Contiene label, EditBox (`InputBoxTemplate`), botones OK y Cancelar. Acepta numero positivo o negativo. Si el target actual es otro jugador, ajusta la reputacion del target; si no hay target jugador o `target == player`, ajusta la reputacion propia y el boton debe decir `Ajustar propio` (sin parentesis). Si el target actual es NPC/no jugador, el boton cambia a `Asignar Faccion` y no abre prompt: valida que la reputacion seleccionada tenga `epsilonFactionId` y ejecuta `HarfordServerActions.SetPhaseNpcFaction(epsilonFactionId, { addonName = "HarfordAdmin", forceEpsilon = true })`; si falta ID no ejecuta comando y avisa al usuario. Si se mantiene `SHIFT` al pulsar `Ajustar`, el boton debe mostrar `Ajustar raid` y el prompt envia el valor como delta a toda la party/raid (`RDELTA`) para la faccion seleccionada. No usar ticks para esto: en `MODIFIER_STATE_CHANGED`, normalizar `key:upper()`, aceptar cualquier key que contenga `SHIFT` (incluido `SHIFT` a secas) y recalcular con `IsShiftKeyDown()`, `IsLeftShiftKeyDown()` y `IsRightShiftKeyDown()` si existen. `OnEnter`/`OnMouseDown` quedan solo como respaldo. Escape/Cancelar cierra sin accion. Click en `Ajustar` mientras esta visible lo cierra (toggle).
- **Frame level**: `DIALOG` strata, level **100** — igual que `DND5E_PlayerFrame` en `HarfordDnD`. Sin llamadas a `Raise()`. Asi ninguno de los dos paneles pisa al otro permanentemente.
- **Shift bug en `adjustBtn` (Epsilon, shift izquierdo)**: `MODIFIER_STATE_CHANGED` NO dispara para shift izquierdo en Epsilon — ningún handler de evento puede capturarlo. Fix: `OnUpdate` en el propio `panel` que compara `IsAnyShiftDown()` contra `_lastShift` cada frame; solo llama `RefreshAdjustButtonText()` cuando cambia. Coste mínimo (una comparación booleana por frame) y activo solo mientras el panel está abierto. No usar `MODIFIER_STATE_CHANGED` ni `OnUpdate` en el botón para este propósito — el panel ya lo cubre globalmente.
- **Self-target optimization en `GetPlayerKeyForDisplay`**: si el DM se selecciona a sí mismo como target, `GetPlayerKeyForDisplay` devuelve `(playerKey, false)` en lugar de `(targetKey, true)`. Así `RefreshRows` nunca llama `RequestPlayerSnapshot` sobre uno mismo (los datos locales ya están disponibles sin request de red).
- Solo el DM (`HarfordReputation.CanEdit()` / `.ph dm`) deberia poder editar reputaciones; si se reintroduce editor avanzado, conservar esta regla.
- Columnas de rango coloreadas: Exaltado=dorado, Reverenciado=violeta, Honorable=azul, Amistoso=verde, Neutral=gris, Adverso=naranja, Hostil=naranja oscuro, Odiado=rojo.
- Texturas de barra CONFIRMADAS en Harford (inspeccionado en cliente con frame debugger):
  - Fill: `UI-Character-Skills-Bar` via `SetStatusBarTexture`. Confirmado correcto.
  - `UI-Character-Skills-BarBorder` — **no usar**: no existe como fichero standalone en Epsilon.
  - Color del fill: `FACTION_BAR_COLORS[standingID]` (tabla WoW global indexada 1-8). Fallback a `ColorToRGB(rankColor)`.
  - **leftTex/rightTex en capa OVERLAY -1 del StatusBar**: en Epsilon el fill del StatusBar renderiza en ARTWORK o superior, cubriendo los caps si estan en ARTWORK. Moverlos a `OVERLAY -1` los pone por encima del fill y por debajo de los highlights (`OVERLAY 0`). **No volver a ARTWORK para los caps**.
  - LeftTexture: `SetTexCoord(0.7578125, 1, 0, 0.328125)`, size `62 × (BAR_H+8)`, ancla `LEFT→bar LEFT 0,0`
  - RightTexture: `SetTexCoord(0, 0.1640625, 0.34375, 0.671875)`, size `42 × (BAR_H+8)`, ancla **`RIGHT→bar RIGHT 0,0`** — NO a leftTex.RIGHT (en bar de 101px, leftTex cubre 62px; anclando rightTex a leftTex.RIGHT quedaría casi fuera del area visible)
  - BAR_W confirmado: **101px**, BAR_H confirmado: **13px** (caps: BAR_H+8 = 21px alto)
  - `ReputationBarBackground` (rowBg): ARTWORK en el Button. `LEFT→row LEFT indent` + `RIGHT→bar LEFT 0,0`. Textura `UI-Character-ReputationBar` texCoord `(0, 0.7578125, 0, 0.328125)`, altura 21px.
  - `FactionStanding`: ARTWORK en StatusBar. Ancla `LEFT bar LEFT 2,0` + `RIGHT bar RIGHT -2,0` (ancho completo del bar). Font FRIZQT__ 10px. Texto normal = `standingText`; hover = `FormatNum(cur) / FormatNum(rng)` o `"1.000 / 1.000"` para Exaltado.
  - `ReputationStar`: siempre `Hide()` — eliminado el `SetShown(standingID >= 8)`. No mostrar flecha ni estrella en ningun rango; Exaltado se comunica visualmente con la barra llena.
  - **Highlights — arquitectura hlFrame** (solucion definitiva al clipping en Epsilon):
    - Texturas en StatusBar (101px) quedan clipeadas a 101px aunque se anclen cross-tree al Button. Epsilon no extiende texturas mas alla del frame padre.
    - Solucion: `hlFrame = CreateFrame("Frame", nil, row)` con `SetAllPoints(row)` y `SetFrameLevel(bar:GetFrameLevel() + 1)` y `EnableMouse(false)`. Las texturas en `hlFrame` cubren el row entero sin clipping.
    - `Highlight1` (cuerpo): texCoord `(0, 0.9609375, 0, 0.4375)`, blend ADD, ARTWORK en hlFrame. Anclas en `InitializeRow`: `TOPLEFT(row TOPLEFT indent-2, 4)` + `BOTTOMRIGHT(row BOTTOMRIGHT -24, -4)`.
    - `Highlight2` (cap derecho): texCoord `(0.9609375, 1, 0, 0.4375)`, blend ADD, SetSize `(24, ROW_H+8)`, `TOPRIGHT→hlFrame TOPRIGHT 0,4`. Ancla fija en `CreateRow` — no cambia con el indent.
    - Highlight1 y Highlight2 son **objetos separados**. `OnEnter` y `OnLeave` deben llamar `Show`/`SetShown` en ambos explicitamente.
    - Headers: `InitializeRow` oculta ambos con `Highlight1:Hide()` + `Highlight2:Hide()` (ya no basta con `bar:Hide()` porque hlFrame es independiente del bar).
    - `OnEnter`/`OnLeave` comprueban `not data.isHeader` antes de tocar los highlights.
  - **NO usar frame `container` intermediario**: OVERLAY en un container queda detras del StatusBar hijo. No reintentar.
  - **NO usar HIGHLIGHT del Button**: capa HIGHLIGHT queda detras de frames hijos (StatusBar incluido).
  - **NO poner highlights como OVERLAY en el StatusBar**: se clipean al ancho del bar (101px) aunque se anclen al Button. Usar hlFrame.
- Firma real de `SetElementInitializer` en este cliente Epsilon: **3 argumentos** — `view:SetElementInitializer(frameType, nil, function(row, elementData) ... end)`. La forma de 2 argumentos deja `initializer` como nil y produce `attempt to call upvalue 'initializer' (a nil value)` en `ScrollBoxListView.lua:290`. No intentar la forma de 2 args aunque la documentación Blizzard la mencione.
- Enfoques FALLADOS en HarfordReputationUI (no reintentar):
  - **Barra manual con `BackdropTemplate` + `SetBackdrop`**: el trough (`BackdropColor`) no renderiza correctamente en Epsilon; el StatusBar con valor 0 tampoco pinta nada, barra completamente invisible.
  - **`StatusBar` hijo de `BackdropTemplate` sin trough propio**: igual que el anterior. `SetStatusBarColor` funciona pero si el valor es 0 no hay fill visible ni borde visible.
  - **Depender de `ReputationBarTemplate` nativo**: descartado para este panel. En Epsilon/SL el template nativo arrastra posiciones/elementos del `ReputationFrame` original y obliga a perseguir caps/texturas por globals; el panel custom debe tener su propia fila.
  - **Usar el `ReputationFrame` moderno de Retail como referencia**: no corresponde al cliente objetivo. La referencia es Shadowlands.
  - **`view:SetElementInitializer("Button", function...)` con 2 args**: produce `initializer = nil`. Siempre pasar 3 args con `nil` como segundo arg.
  - **Highlights como OVERLAY en StatusBar (cross-anchored al row)**: Epsilon clipea texturas al frame padre aunque el ancla sea cross-tree. El highlight quedaba cortado a 101px (ancho del bar). Solucion: hlFrame hijo del row con `SetAllPoints(row)`.
  - **Highlight1 = Highlight2 (misma referencia)**: si ambos apuntan al mismo objeto, `Show`/`Hide` funcionan pero se pierde el cap independiente. Deben ser texturas separadas para que el cuerpo y el cap se anclen de forma distinta.
  - **Anchor cuerpo→cap entre texturas** (`hl1:SetPoint("BOTTOMRIGHT", hlCap, "BOTTOMLEFT")`): WoW puede no resolver anchors cross-texture en algunos contextos de Epsilon. Usar offset directo sobre el row (`BOTTOMRIGHT row BOTTOMRIGHT -24,-4`) en su lugar.
  - **caps leftTex/rightTex en ARTWORK**: el fill del StatusBar en Epsilon renderiza por encima de ARTWORK, cubriendo los caps. Usar `OVERLAY -1`.
  - **rightTex anclado a leftTex.RIGHT**: en bar de 101px, leftTex cubre 62px (61%); rightTex quedaría fuera del area visible. Anclar siempre `RIGHT→bar RIGHT 0,0`.
  - **`ReputationStar:SetShown(standingID >= 8)`**: aparecia una textura tipo flecha en Exaltado. Siempre `Hide()`; la barra llena comunica visualmente el Exaltado.

Contrato `HarfordReputationSync`:

- Prefix `HARFORDREP`, registrado en PLAYER_LOGIN via `HarfordSync.RegisterPrefix`.
- Filtro de remitente: antes de procesar cualquier `HARFORDREP`, el receptor debe poder resolver el `sender` como propio, unidad visible o miembro de grupo/raid mediante `HarfordClassColors.FindUnitByName`; si no, se ignora. Esto evita snapshots/deltas anonimos, pero no es una firma DM fuerte.
- Opcodes legacy: `FAC` (datos de faccion), `REP` (puntos jugador), `NPC` (link NPC→faccion), `LOG` (entrada de log), `DEL` (borrar faccion). Quedan como referencia historica/API interna, pero el receptor actual no debe aplicar mensajes legacy entrantes.
- Snapshots completos/troceados:
  - `HarfordReputationSync.BroadcastSnapshotStructure()` serializa solo estructura: facciones, grupos/secciones y sin puntos. Es el boton `Compartir estructura`.
  - `HarfordReputationSync.BroadcastSnapshotAll()` serializa estructura completa + puntos de jugadores + `SELFREP` para todas las facciones. Es el boton `Compartir todo`.
  - `HarfordReputationSync.BroadcastSnapshotFaction(factionId)` serializa solo la faccion seleccionada, su grupo/seccion, puntos de esa faccion. Es el boton `Compartir seleccion`.
  - `HarfordReputationSync.BroadcastRepDelta(factionId, delta)` envia `RDELTA` a grupo/raid para que cada cliente aplique un delta a su propia reputacion local actual. El emisor aplica su delta localmente antes de emitir y el receptor ignora `RDELTA` si viene de si mismo para evitar doble ajuste si el cliente se eco-recibe.
  - Cada snapshot incluye tambien `SELFREP|factionId|points`: son los puntos actuales del jugador que comparte para esa faccion. Al recibirlo, cada cliente lo aplica a su propio `playerKey`, para que todos vean el mismo numero en su barra local despues de compartir.
  - Transporte: `SNAPC|transferId|scope|index|total|chunk`, con `chunk` escapado y limite pequeno (`SNAPSHOT_CHUNK_BYTES`) para evitar desbordamiento de addon messages.
  - El receptor reensambla por `sender:transferId`; los buffers tienen TTL y limite de `total` (`SNAPSHOT_MAX_CHUNKS`) para cortar mensajes malformados. Al completar, deserializa y aplica con `suppress` restaurado aunque falle el snapshot.
- Vista remota DM→target:
  - `HarfordReputationSync.RequestPlayerSnapshot(playerKey)` envia `RVIEWREQ` por `WHISPER` al target (tambien prueba nombre corto si el key incluye reino).
  - El cliente objetivo responde con `RVIEWC|transferId|index|total|chunk`, usando el mismo snapshot `ALL` escapado/troceado, pero el receptor DM lo guarda en `remoteViews` y **no lo aplica al store local**.
  - `HarfordReputationSync.GetRemoteView(playerKey)` devuelve `{ groups, factions, points }`; `points` viene de `SELFREP` del jugador objetivo. Las vistas remotas caducan por TTL para que inspeccionar muchos jugadores no crezca indefinidamente.
  - `HarfordReputationSync.SetRemoteViewPoints(playerKey, factionId, points)` actualiza de forma optimista la vista remota tras `SetTargetPoints`, para que el panel no parezca usar valores locales del DM mientras llega/si no llega eco de red.
  - Scope `ALL`: sustituye `store.factions`, `store.groups`, `store.players` completos; elimina `store.guilds` si existia como resto antiguo.
  - Scope `STRUCTURE`: sustituye estructura (`store.factions`, `store.groups`) y respeta puntos locales de facciones que siguen existiendo. Debe inicializar a 0 las facciones nuevas para el jugador local y borrar puntos locales de facciones que ya no existan en la estructura recibida.
  - Los snapshots deben preservar orden visual: `GRP` envia `sortOrder` de grupo y `SUB` envia `subgroupOrder` de seccion. Las facciones ya viajan con `sortOrder` dentro de `FAC`. Al recibir, no reconstruir cabeceras sin estos campos o el cliente ordenara distinto.
  - Scope `FACTION`: sustituye solo esa faccion y limpia/reaplica sus puntos, preservando el resto del store local.
- Solo el DM emite snapshots desde botones admin explicitos. Los cambios locales (`CreateFaction`, `UpdateFaction`, ajustes de puntos, etc.) no se emiten automaticamente; primero modifican SavedVariables locales y refrescan UI. Para compartirlos con la raid/grupo hay que pulsar `Compartir todo` o `Compartir seleccion`.
- Todos los clientes reciben y aplican snapshots con supresion interna de rebroadcast (`suppress`) para no reenviar el snapshot al grupo.
- `RefreshReputationViews()` usa debounce interno (`_refreshViewsPending` + `C_Timer.After(0.1)`): colapsa rafagas de mensajes `REP`/`RDELTA` consecutivos en un unico refresh de UI. Llamar `RefreshReputationViews()` multiples veces en el mismo frame solo dispara un refresh real. El debounce NO aplica a `ApplySnapshot`: ese camino ya ejecuta `RefreshReputationViews()` una sola vez al final del reensamblado completo.

Modulo `HarfordDebug`:

- Es un **addon opcional separado** en `HarfordDebug/`, con `## RequiredDeps: Harford`. Harford core no carga comandos, capturas ni SavedVariables de diagnostico.
- El nombre historico `HarfordDnDDebug` queda como alias temporal de `HarfordDebug` para compatibilidad.
- Es el unico propietario de `HarfordDebugSettings` y `HarfordFrameProbe` en su propio `.toc`. No re-declarar esas SavedVariables en `Harford/Harford.toc`.
- Sin el addon instalado, `/harford debug ...` muestra un aviso claro y el core sigue sin rutas de debug residentes. Los metodos `Debug...` que queden en modulos core son puentes inertes, invocados solo por el addon opcional; no registran eventos, timers ni SavedVariables.
- Slash commands:
  - `/harford debug on`: activa logs y comandos debug.
  - `/harford debug off`: desactiva debug.
  - `/harford debug toggle`: alterna estado.
  - `/harford debug status`: muestra estado.
  - `/harford debug list`: lista comandos debug registrados.
- `/harford debug run <comando>`: ejecuta un comando debug registrado solo si debug esta activo.
- No hay alias corto activo: usar `/harford debug ...`.
- Para nuevos diagnosticos temporales, registrar comandos con `HarfordDebug.RegisterCommand(name, handler, helpText)`.
- Cualquier operacion de debug, dump, listado de candidatos o inspeccion temporal debe vivir aqui, no en modulos de gameplay/admin normal. No crear un comando para un control visual concreto: usar el probe generico, capturar `normal`/`hover`/`activo`/`pulsado` y comparar los estados antes de trasladar los datos confirmados a la UI de produccion.
- Comandos debug actuales:
  - `/harford debug run svclean status|safe|dnd|logs|npclinks|guilds|targetpos [force]|all`: limpieza parcial de SavedVariables obsoletas/controladas.
  - `/harford debug run svclean purge confirm`: purga TODAS las SavedVariables de Harford declaradas en `Harford.toc`, incluida `HarfordCompendioCharacterDB` per-character, y requiere `/reload` despues. Usarlo solo para reiniciar el addon desde cero.
  - **Loot - no duplicar en disco**: `HarfordLootLootRegistry` (loot por tipo de criatura, keyed por creatureId) y `HarfordLootGlobalLootRegistry` (loot global, lista) son la forma PERSISTIDA real. `HarfordLootConfigStore` es solo un cache de serializacion (`registry`/`global` strings) de esas dos tablas y **ya NO esta en SavedVariables** (era una copia redundante en disco); queda como global runtime que `SaveConfig` rellena para el sync `LOOTCFG`. En carga, `LoadLootConfigTables` lo ve vacio y cae a las tablas vivas. No re-declararlo como SavedVariable. `HarfordLootTaggedCreatureRegistry` es loot por instancia (keyed por GUID). La lista `SAVED_VARIABLES` de `HarfordDebug` (para `svclean purge`) debe coincidir con la del `.toc`; la per-character `HarfordCompendioCharacterDB` vive en una lista separada del mismo comando.
  - **Filtro de remitente en loot**: `HARFORDLOOT`/`HARFORDCFG` mutan estado compartido y PERSISTIDO (tabla de loot por GUID, borrado masivo `LOOTCLEAR` y la configuracion global que va a SavedVariables). El loot usa WHISPER de forma legitima, asi que el filtro NO puede ser por canal: el receptor descarta los mensajes cuyo `sender` no reconozca (propio, unidad visible o grupo/raid via `HarfordClassColors.FindUnitByName`). El auto-descarte compara nombre corto Y completo (`Nombre-Reino`). No retirar ese guard.
  - **Loot config sync**: `HARFORDCFG` mantiene compatibilidad con mensaje directo `LOOTCFG|registry|global` si cabe bajo el limite seguro. Si no cabe, `HarfordSync.SendLootConfig` lo fragmenta como `LOOTCFGC|transferId|idx|total|chunk` (payload escapado, chunks TTL 60s, max 80 chunks) y `HarfordLoot` lo reensambla antes de `ApplyConfig`. No volver a enviar tablas grandes de loot como un unico addon message.
  - `/harford debug run deps`: estado de `EpsilonLib.AddonCommands` y `ARC`.
  - `/harford debug run sync`: estado basico de transporte addon.
  - `/harford debug run phase`: prueba `phase info addon` con callback.
  - `/harford debug run raw <comando>`: envia comando raw solo con debug activo.
  - `/harford debug run trp3icons`: lista candidatos de icono TRP3 del target.
  - `/harford debug run trp3link`: inspecciona el ultimo link de estado ajeno creado por Harford, mostrando `identifier`, emisor, marcador `[TRP3:id]`, hyperlink clicable y longitud del comando `npc te`.
  - `/harford debug run trp3npctest marker|hyperlink|chat`: con NPC target, compara `npc te [TRP3:id]` y `npc te <hyperlink>` via `HarfordServerActions.SendRawDebug`/EpsilonLib, o `SendChatMessage(".npc te <hyperlink>", "GUILD")` como ruta comparable al comando manual. Se conserva como diagnostico/regresion: la ruta `hyperlink` via EpsilonLib ya fue validada en dos clientes.
  - `/harford debug run totlayer`: strata/level/anchors de `TargetFrameToT` y estado `totDesired`.
  - `/harford debug run totportrait`: diagnostica portrait overlay ToT y TRP3 para `targettarget`.
  - `/harford debug run totspy [s]`: hookea `TargetFrameToTManaBar` para capturar callers (no removible).
  - `/harford debug run totscripts`: lista scripts en barras/frames del ToT.
  - `/harford debug run totrate [s]`: mide frecuencia de llamadas al ciclo ToT.
  - `/harford debug run totpieces`: lista globals/hijos StatusBar dentro de `TargetFrameToT`.
  - `/harford debug run totframe [tot|focustot]`: vuelca jerarquía completa de `TargetFrameToT` o `FocusFrameToT` (hijos, regiones, tipo, strata, level, alpha, tamaño, textura/atlas). También reporta tipo de `TargetofTarget_Update`/`FocusofTarget_Update`, estado de overlays creados y alpha del portrait nativo. Primer paso obligatorio antes de tocar código del ToT.
  - `/harford debug run npinspect [all]`: inspecciona el nameplate del target o todos los nameplates visibles; lista campos raiz, `UnitFrame`, barras y estructura Kui si existe.
  - `/harford debug run npkui`: dump detallado de `nameplate.kui` del target para investigar KuiNameplates, especialmente modo name-only.
  - `/harford debug run testpos`: imprime los valores que devuelven `UnitPosition("player")` y `C_Map.GetPlayerMapPosition` en el momento de la llamada. Primer paso para diagnosticar si las APIs de posición están disponibles en Epsilon.
  - `/harford debug run poswatch [segundos]`: muestra muestras de posición cada 0.1s durante N segundos (por defecto 8s). Imprime distancia acumulada y al final clasifica en: `OK` (API actualiza correctamente), `PROBLEMA: ninguna API retornó coordenadas` o `PROBLEMA: posición no cambió` (API existe pero valores estáticos).
  - `/harford debug run portraitwatch [segundos]` (o `off`): diagnostico del retrato del `PlayerFrame`. Registra `UNIT_PORTRAIT_UPDATE`/`UNIT_AURA`/`UNIT_MODEL_CHANGED`/`UNIT_DISPLAYPOWER`/`PLAYER_TARGET_CHANGED` y hookea (guarded) `SetPortraitTexture`, `UnitFramePortrait_Update(PlayerFrame)` y `PlayerPortrait:SetTexture`, mostrando el estado del retrato (`icono:` vs `fileID:`/`modelo3D`) en cada evento. Sirvio para confirmar el repintado de Blizzard que motiva el hook defensivo del retrato del player.
- Los comandos debug no deben ejecutar texto arbitrario recibido de otros clientes ni saltarse las validaciones de `HarfordEpsilonCommands`.

Regla de timers/refresco:

- No usar ticks continuos para UI o permisos (`C_Timer.NewTicker`, `OnUpdate` permanente, polling cada X segundos) salvo interacciones que realmente lo necesitan mientras duran, por ejemplo arrastrar el minimap button.
- Preferir eventos WoW/addon (`PLAYER_TARGET_CHANGED`, `UNIT_HEALTH`, `CHAT_MSG_ADDON`, cambios de config) y refrescos puntuales.
- `CHAT_MSG_SYSTEM` no es una buena fuente para detectar cambios de estado DM: dispara en cualquier mensaje de sistema (kills, quests, invitaciones) sin relation con el addon. Usar `HarfordAuthority.RegisterChangeListener` para reaccionar al toggle de modo DM.
- `C_Timer.After` solo es aceptable como one-shot acotado para debounce/transicion concreta; no debe encadenarse para simular un ticker.
- `HarfordTurns` no debe refrescar cada 0.5s con `OnUpdate`; se refresca por cambios de target, salud, mensajes de sync y acciones locales.
- **`UNIT_HEALTH` en el tracker de turnos**: el handler solo debe actuar cuando `unit == "target"` y la unidad es un NPC trackeado (`RefreshTargetNpcHealthFromUnit`). Eliminar cualquier `elseif RefreshFrame()` que dispare la UI en cambios de salud de otras unidades no relacionadas — eso causaba un refresh de overlay por cualquier cambio de HP del grupo/raid mientras el tracker estaba visible.
- **Doble `AlertMyTurn` al avanzar turno (bug de lag confirmado y corregido)**: `NextTurn`/`PrevTurn` envía primero `TURN|serial:N|...` (inmediato) y luego `STATE|...` 150ms después (`ScheduleBroadcast`). `ApplyTurnNotice` graba `lastTurnAlertKey = "serial:N:id:name"`. Cuando llega el STATE, el event handler llamaba `AlertMyTurn(entry, index)` SIN pasar `turnSerial` → `serial=0` → `key = "0:id:name"` → clave diferente → sonido RAID_WARNING + animación se reproducían por segunda vez. Fix: pasar siempre el `turnSerial` runtime al `AlertMyTurn` en el event handler para STATE/SCHUNK: `AlertMyTurn(entry, index, turnSerial)`. `turnSerial` no se persiste y se acota a 999999; es solo un nonce de sesion para deduplicar TURN/STATE.
- **`RefreshPlayerEntryTRP3Meta` en cada `RefreshFrame` (rendimiento)**: iteraba sobre `player`, `target`, `mouseover`, `focus`, `party1-4`, `raid1-40` (47 unidades) por cada entrada de tipo `player` en cada refresh. Con 3 jugadores y 2 RefreshFrame por turno avanzado = ~282 llamadas WoW API por tecla. Fix: flag `entry._trpMetaCached` + TTL de 30s. El cache se invalida solo cuando `ApplySerializedState` reconstruye `store.entries = {}` (las entradas nuevas no tienen la flag). No cachear en datos estáticos globales: la TTL permite recoger cambios de perfil TRP3 en sesión.
- **`HandleAddonMessage` en `HarfordDnDComm` retorna boolean**: `true` solo cuando se actualiza la cache de recursos remotos (`RES`, `RESCFG`, `RADJ`); `false` para `REQ`, sincronias de perfil, prof flags, tiradas, `ANIMFLG` y `DOAPPLYAURA`. El caller en `HarfordDnD` debe usar ese return para condicionar `HarfordUnitFrames.Refresh()`: no hacer Refresh completo en cada mensaje de turnos, loot, reputaciones o tiradas.
- **`HarfordDnDResources.AnimFlagCache`**: tabla `{[nombre]=boolean}`, indexada tanto por nombre corto como nombre completo. `true` = el jugador quiere recibir animaciones; `nil` = desconocido (tratar como `true`); `false` = animaciones desactivadas. Se llena al recibir `ANIMFLG` en `HarfordDnDComm`. Siempre usar `Ambiguate(name, "short")` para el lookup y para poblar la cache.
- **`RequestResourcesFromPlayer` en `HarfordDnD`**: throttle de 12s por jugador (`_resourceRequestTimes` tabla local + `RESOURCE_REQUEST_COOLDOWN = 12`). Sin el throttle, `PLAYER_TARGET_CHANGED` podía enviar WHISPER en cada cambio de objetivo al mismo jugador. La tabla debe vivir en scope de modulo, no dentro del handler de evento.
- **Nombre y color TRP3 en tiradas (`HarfordDnDRolls`)**: las tiradas emitidas por el jugador local deben mostrar el nombre y color TRP3, no el nombre WoW ni el dorado fijo.
  - `HarfordDnDRolls.GetDisplayName()`: si `HarfordDnDContext.State.rollName` está activo (contexto NPC), lo usa; si no, intenta `HarfordTRP3.GetUnitRPName("player")`; cae a `UnitName("player")`.
  - `HarfordDnDRolls.Serialize` incluye un **10.º campo** `nameColor` (hex 6 dígitos o string vacío).
  - `HarfordDnDRolls.Broadcast` establece `rollData.nameColor` antes de serializar: en contexto NPC usa `HarfordDnDContext.State.rollColor`; en modo normal usa `HarfordTRP3.GetUnitNameColor("player")`.
  - `HarfordDnDRolls.Deserialize` extrae `nameColor` de `parts[10]` y lo pasa en la tabla devuelta.
  - Los receptores que renderizan en chat aplican `nameColor` al nombre del emisor si está presente.
- **Sonido de tiradas TRP3 (`HarfordDnDRolls`)**: en la copia local inspeccionada, `totalRP3/core/impl/slash.lua` llama a `TRP3_API.ui.misc.playSoundKit(36629, "SFX")` al terminar `TRP3_API.slash.rollDices(...)`; `totalRP3_Extended` reutiliza esa ruta. `HarfordDnDRolls.Broadcast` reproduce el mismo sound kit solo para tiradas locales reales (`type ~= "info"` ni `"static"`, y dados validos), usando la API TRP3 cuando existe para respetar su opcion de sonidos y `PlaySound(36629, "SFX")` como fallback. **Tipos de tirada en `DisplayInChat`**: `"info"` = mensaje de estado, renderiza `[D&D] Nombre <label>` SIN `: total` ni sonido (Salv Muerte); `"static"` = valor CALCULADO sin tirada de dado (ej. **CD Conjuro**), se renderiza CON `: total (desglose)` como cualquier tirada pero NO suena (no es un dado); cualquier otro tipo (`"spell"`, `"damage"`, ...) muestra total + desglose y suena. NO usar `"info"` para valores que deban mostrar su numero (era el bug de CD Conjuro: el total se perdia). No moverlo a `DisplayInChat`: ese punto tambien renderiza resultados recibidos y haria sonar o duplicaria tiradas remotas.
- **Titulo de `HarfordDnD`**: en modo normal debe permanecer fijo como `Harford DnD 5ª - Ficha`, sin sustituirse por el nombre/color TRP3 del jugador. Solo un contexto externo marcado `SheetContext.kind == "npc"` puede sustituir el titulo por el nombre/color del NPC; ese contexto lo activa `HarfordAdmin`.
- **Emotes NPC confirmados** (tabla `HarfordEmotes.ORDER` / `HarfordEmotes.DEFS`): IDs validados en Epsilon — `Desarmado=2016`, `Una mano=2017`, `A dos manos=2018`, `Arma Asta=2018`, `Arco=2046`, `Rifle=2049`, `Offhand=2087`, `Estocada=2085`, `Estocada 2HL=2086`, `Estocada Offhand=2088`, `Lanzar=2107`, `Desarmado Offhand=2117`. `Ninguno` tiene `id=nil` y no envía comando. Para la victima, `npc emote 33` corresponde a `ONESHOT_WOUND` y `npc emote 34` a `ONESHOT_WOUND_CRIT`; ambos se disparan desde `SetNpcHealthDelta` solo cuando pierde mas de 1 punto de vida, segun `opts.isCritical`.
- **`ApplyResourceDeltaFromRemote` en `HarfordDnD`**: acepta tanto claves cortas legacy (`"health"`, `"temp_health"`) como claves completas de recurso (`"Res_X_Cur"` para el current, `"Res_X_Max"` para el máximo de cualquier recurso de `HarfordDnDResources.DEFS`). El receptor/aplicacion vive en core. El editor de recursos admin envia `RADJ` desde `HarfordAdminUnitMenu` mediante su helper privado y `HarfordSync.SendResourceAdjust`; ya no usa una UI inline en core. `HarfordDnDAPI.AdjustResourceForName` se conserva como puente estable: `HarfordTurns` lo usa para los controles de vida de turnos (jugador via `RADJ`). No se planea separar turnos a Admin (ver "Frontera admin/core de turnos"): la frontera es el API `HarfordTurnOrderAPI` + el gating `CanUseDMTools`, no un split fisico.
- **Editor de recursos admin (`HarfordAdminUnitMenu`)**: frame `CreateResourceEditorFrame()` en `DIALOG` strata level 500, 320px de ancho. Muestra las 15 recursos (health + 14 de `HarfordDnDResources.ORDER` + temp_health) con label coloreado, `EditBox` de cur y `EditBox` de max. Botón `Aplicar` calcula deltas `nuevo - actual` y envía cada delta no-cero por su helper privado `AdjustResourceForName(...)`, que usa `HarfordSync.SendResourceAdjust("DND5EARC", ...)`. Botón `Refrescar` repopula los campos desde el cache de recursos. Toggle via `OpenResourceEditor(snapshot)`: si el frame ya está visible para el mismo target lo oculta, si no pide recursos con `RequestResources` y repopula tras 1.5s one-shot timer. `GetResOrderFull()` construye la lista insertando `temp_health` justo después de `health`. Es la unica UI para modificar recursos remotos.
- **`TargetResourceFrame` es solo lectura en core**: se retiro la edicion inline (`CreateTargetEditRow`, `ToggleTargetResourceEditMode`, `GetTargetResourceEditMode`) de `HarfordDnD`. Aunque el usuario use presentacion `frame`, cualquier modificacion de recursos debe abrir el editor de `HarfordAdminUnitMenu`; asi `Harford` no carga controles DM sin el addon Admin.
- **Tracker de movimiento en SEC_ATK (`HarfordDnD`)**: botón `Movimiento` + label de resultado en la sección de ataque. Implementado en `do...end` para no consumir locals de file-scope. `OnUpdate` permanente sobre `movBtn` con `if not _tracking then return end` como guardia barata (coste cero cuando inactivo). Throttle de 0.1s (10fps). `GetPos()` intenta primero `UnitPosition("player")` y cae a `C_Map.GetPlayerMapPosition` si no retorna x,y. Distancia: euclídea en yards × `0.9144` (conversión a metros). Umbral mínimo 0.05 yards (~4.5cm) para ignorar jitter de posición en reposo. Al iniciar, verifica que `GetPos()` retorna coordenadas; si no, muestra `"Sin posición"` y aborta. Al parar, muestra el total acumulado. **`UnitPosition` en Epsilon puede devolver solo x,y sin z**: guard `if not nx or not ny then return end` + `nz = nz or 0` necesario para evitar crash aritmético. No usar `PLAYER_STARTED_MOVING`/`PLAYER_STOPPED_MOVING` para activar el OnUpdate: esos eventos pueden no disparar en Epsilon.
- **Ventaja/Desventaja de un solo uso en `HarfordDnD`**: los botones "Ventaja" y "Desv." comprueban si shift está pulsado al momento del click (`IsShiftKeyDown`, `IsLeftShiftKeyDown`, `IsRightShiftKeyDown`). Sin shift → activan el modo y ponen `_modoTiradaSingleUse = true`; con shift → activación permanente hasta cambio manual. `ConsumeMode()` se llama al final de `DoRoll`, `DoWeaponAttack` y `DoSpellAttack`: si `_modoTiradaSingleUse`, resetea `ModoTirada` a `"normal"`, baja la flag y llama `RefreshTopInfo()`. Labels en "Modo activo": **un solo uso** → `"Ventaja"` / `"Desventaja"`; **permanente** → `"Ventaja Perm."` / `"Desventaja Perm."`. El botón "Normal" también baja `_modoTiradaSingleUse`. `local RefreshTopInfo` se declara antes de `ConsumeMode` (forward declaration) porque `ConsumeMode` cierra sobre ella pero `RefreshTopInfo` se asigna ~1400 líneas más abajo; sin la declaración previa, la referencia dentro de `ConsumeMode` sería el global `nil`.
- **Critico de arma del jugador (`HarfordDnD`)**: si `Ataque Arma` obtiene `CRÍTICO`, guarda `HarfordDnDStore.pendingWeaponCriticalKey = def.key` sin añadir locales de file-scope. El siguiente click en `Daño Arma` consume la marca; solo maximiza los dados si el arma seleccionada sigue siendo la que obtuvo el crítico, suma modificadores fijos con normalidad y etiqueta la tirada de daño como `CRÍTICO`. Cualquier click en `Daño Arma` consume la marca aunque se haya cambiado de arma. `Ataque Conjuro` no se incluye todavía porque la ficha actual no dispone de un botón/formula de `Daño Conjuro` asociado.
- **Labels dinámicos de botones Ventaja/Desventaja**: cuando el usuario mantiene shift, los botones cambian a `"Modo V"` / `"Modo D"` para indicar que el siguiente click activará modo permanente. Cuando no hay shift vuelven a `"Ventaja"` / `"Desventaja"`. Se implementa con `OnUpdate` en `SEC_TOP` (mismo patrón que el fix de shift global): compara `_lastShift` con `IsAnyShiftDown()` cada frame y llama `RefreshModeButtonLabels()` solo cuando cambia.
- **Debounce de `RefreshReputationViews` en `HarfordReputationSync`**: `BroadcastRepPoints()` y `BroadcastAll()` envian un mensaje por jugador/faccion; sin debounce cada `REP` o `RDELTA` dispara `HarfordReputationUI.Refresh()` + `HarfordReputationAdmin.Refresh()` de forma individual. Patron: `_refreshViewsPending` flag + `C_Timer.After(0.1, ...)` colapsa la rafaga en un unico refresh. No aplicar este debounce a `ApplySnapshot` (el snapshot ya es una operacion unica al final del reensamblado).
- Orden manual de turnos: en modo `Editar`, `reorderSelectedIndex` debe seguir a la entrada seleccionada por referencia, no quedarse como indice fijo. `MoveEntryToIndex` debe guardar `selectedEntry = store.entries[reorderSelectedIndex]` antes de `table.remove/table.insert` y recalcular el nuevo indice despues. El click-to-place mantiene la entrada seleccionada en su nueva posicion para poder seguir moviendola sin seleccionar otro turno por accidente.
- `HarfordLoot` no debe usar `OnUpdate` permanente para cerrar al moverse; se cierra con `PLAYER_STARTED_MOVING`. El tooltip de loot puede usar `OnUpdate` solo mientras el raton esta encima de un boton y debe limpiarlo en `OnLeave`.

Contrato `HarfordAuthority`:

- Vive en `Harford/Core/HarfordAuthority.lua`.
- Centraliza las senales de permisos sin mezclarlas:
  - `HarfordAuthority.HasAdminAddon()`: `HarfordAdmin` esta instalado/cargado y marca `HarfordAdminAPI.IS_ADMIN`.
  - `HarfordAuthority.IsPhaseMember()`: miembro de la phase actual.
  - `HarfordAuthority.IsPhaseOfficer()`: oficial de la phase actual.
  - `HarfordAuthority.IsPhaseOwner()`: owner de la phase actual.
  - `HarfordAuthority.IsMemberPlus()`: member, officer u owner.
  - `HarfordAuthority.IsOfficerPlus()`: officer u owner.
  - `HarfordAuthority.IsDMMode()`: flag DM activo por Epsilon, equivalente a `.ph dm on/off`.
  - `HarfordAuthority.IsDMEnabled()`: criterio estilo SpellCreator: DM mode activo y ademas officer u owner.
  - `HarfordAuthority.CanUseMemberCommands()`: true si `HarfordAdmin` esta cargado o si es member/officer/owner.
  - `HarfordAuthority.CanUseOfficerCommands()`: true si `HarfordAdmin` esta cargado o si es officer/owner.
  - `HarfordAuthority.CanUseAdminCommands()`: true solo si `HarfordAdmin` esta cargado.
  - `HarfordAuthority.CanUseDMTools()`: true solo si `HarfordAdmin` esta cargado/activo **y** `.ph dm` esta activo.
  - `HarfordAuthority.CanUse(requirement)`: comprueba `member`, `officer`, `admin` o `dm`.
  - `HarfordAuthority.Require(requirement, actionName)`: helper para bloquear acciones segun capacidad.
  - `HarfordAuthority.GetStatus()`: snapshot para debug/UI.
  - `HarfordAuthority.RequireDMTools(actionName)`: helper para bloquear acciones futuras.
- Importante: `member`, `officer/owner`, `admin addon` y `.ph dm` son ejes separados. No asumir que estar en DM mode implica rango de phase, ni que ser officer implica estar en DM mode. Las opciones/herramientas DM de Harford exigen siempre que el addon `HarfordAdmin` este cargado; `.ph dm` por si solo no debe hacerlas aparecer ni activarlas.
- **Modelo de autoridad de 3 ejes (regla de separacion Core/Admin):**
  - **Oficial** (`IsOfficerPlus()`): el core `Harford/` puede **emitir** comandos de servidor "ligeros" que NO requieran datos de Admin (sin mitigacion de resistencias, sin contexto NPC). Ejemplo vigente: `HarfordDnD.lua` aplica daño en bruto a un NPC target via `SetNpcHealthDelta(-total, { addonName = "Harford" })` cuando el jugador es `IsOfficerPlus()` (botones `Daño Arma`/`Daño Custom`). Es la "3ª opcion oficial". La modificacion de vida al tirar daño vive en el core: NPC oficial via `SetNpcHealthDelta`, jugador via `RADJ`.
  - **DM + Admin** (`CanUseDMTools()` = `HarfordAdmin` cargado **y** `.ph dm`): todo lo exclusivo de DM vive en `HarfordAdmin/` (fichas NPC, mitigacion R/V/I coloreada, edicion de turnos/reputacion). El core nunca consulta `IsDMMode()` para cambiar UI/acciones; expone callbacks sobrescribibles (patron `HarfordTRP3.InsertGlanceLink`) que Admin rellena en su `PLAYER_LOGIN`.
  - **Funcion protegida `ClearTarget()`**: NO llamarla desde ningun addon (core ni Admin). Es protegida (solo Blizzard UI / codigo seguro); llamarla dispara `blocked from an action only available to the Blizzard UI`. Tampoco sirve `RunMacroText("/cleartarget")` ni `TargetUnit` (igual de protegidas). El boton "Modo combate" ya NO limpia el target en modo DM: la animacion se aplica al propio personaje sin deseleccionar.
  - **Recepcion/render** (sin gate): escuchar y aplicar `DND5EARC`/`HARFORDTURN`/`HARFORDREP` y dibujar la UI vive siempre en el core.
  - Señal unica: usar `HarfordAuthority.HasAdminAddon()` / `CanUseDMTools()` / `IsOfficerPlus()`. No leer `HarfordAdminAPI.IS_ADMIN` ni `C_Epsilon`/`ARC` directamente desde modulos core (centralizado en `HarfordAuthority`). `HarfordTurns.IsTurnAdmin()` delega en `CanUseDMTools()`.
- Referencia SpellCreator:
  - `ARC.PHASE.IsMember = C_Epsilon.IsMember`
  - `ARC.PHASE.IsOfficer = C_Epsilon.IsOfficer`
  - `ARC.PHASE.IsOwner = C_Epsilon.IsOwner`
  - `ARC.PHASE.GetPhaseId = C_Epsilon.GetPhaseId`
  - `ARC.PHASE.IsDM = function() return C_Epsilon.IsDM end`
  - `SpellCreator/Permissions.lua` considera DM habilitado solo si `C_Epsilon.IsDM` y (`C_Epsilon.IsOfficer()` o `C_Epsilon.IsOwner()`).
- Comando debug:
  - `/harford debug run auth`: muestra estado de admin addon, phase rank, `.ph dm` y permisos DM tools.

Contrato `HarfordAdminNPC`:

- Vive en `HarfordAdmin/HarfordAdminNPC.lua`.
- Es el primer modulo admin para acciones sobre target/NPC/enemigo.
- Por ahora no asume comandos Epsilon no confirmados.
- API inicial:
- `HarfordAdminNPC.GetTargetSnapshot()`: lee datos locales del target actual.
  - `HarfordAdminNPC.PrintTarget()`: imprime nombre, GUID, tipo player/dead/level.
  - `HarfordAdminNPC.ApplyAuraToTarget(spellId)`: usa `HarfordServerActions.ApplyAura(spellId, "target", { addonName = "HarfordAdmin" })`.
  - `HarfordAdminNPC.RemoveAuraFromTarget(spellId)`: usa `HarfordServerActions.RemoveAura(spellId, "target", { addonName = "HarfordAdmin" })`.
  - `HarfordAdminNPC.GetTargetInfo(callback)`: diagnostico explicito de Admin para `npc info`; no usarlo para cargar fichas. La lectura de fichas NPC se hace desde TRP3 local (`GetEpsilonNpcProfile`/`GetNPCStatBlock`). La excepcion aprobada es la posicion de areas: Admin parsea X/Y/Z de `npc info` y se la entrega al core mediante `HarfordDnDArea.SetNpcPositionProvider`.
  - `HarfordAdminNPC.BuildDnDSheetContext(unit, opts)`: con `HarfordAdmin + .ph dm`, lee el stat block TRP3 del NPC y construye un contexto neutral para la ficha con nombre/color, overrides de atributos/habilidades/salvaciones y acciones desde estados activos TRP3. Antes de aplicar el parseo inicializa una base NPC limpia: atributos, `BonusCompetencia`, `BonoSituacional`, `ModIniciativa`, flags `Salv_*` y `Hab_*_Prof/Exp` a `0`; asi una habilidad/salvacion no declarada se calcula desde el NPC y nunca hereda proficiencias de la ficha normal. Toda ficha NPC guarda `npcSourceGuid = UnitGUID(unit)` para identificar su atacante; `opts.locked = true` solo marca `titleText` entre corchetes (`[Nombre]`) en la vista DM. `rollName` permanece normal para no enviar corchetes en tiradas.
  - `HarfordAdminNPC.ApplyDnDSheetContext(unit, opts)` / `ClearDnDSheetContext()`: activan/limpian ese contexto mediante `HarfordDnDAPI.ApplySheetContext` / `ClearSheetContext`. `HasDnDSheetContext()` informa si existe atacante NPC cargado e `IsDnDSheetContextLocked()` solo informa de la marca visual de corchetes.
  - `HarfordAdminNPC.CanNpcSheetAttack()` / `CanNpcSheetDamage()`: gobiernan los botones segun variante. En modo NPC normal, al seleccionar un NPC se recarga su ficha y queda activo `Atacar`/inactivo `Daño`; al seleccionar un jugador se conserva la ultima ficha y queda activo solo `Daño`; sin target ambos quedan inactivos. En modo marcado (`Shift+click`), compara `UnitGUID("target")` con el GUID fijado: el atacante exacto habilita `Atacar` y cualquier otra unidad habilita `Daño`, incluidos otros NPC con el mismo nombre.
  - `HarfordAdminNPC.ApplyNpcSheetAttackAnimation(animId)`: callback de cualquier contexto NPC. Al pulsar `Atacar` con el NPC ficha exacto seleccionado, aplica el emote elegido con `HarfordServerActions.SetNpcEmote(animId, { addonName = "HarfordAdmin" })`; asi la animacion ocurre en el atacante antes de seleccionar la victima.
  - `HarfordAdminNPC.ApplyNpcSheetDamage(total, action, rolledComponents, isCritical)`: callback de cualquier contexto NPC. Recibe el `total` **ya mitigado** por defensas (la mitigacion se resolvio en la tirada del core via `HarfordDamageMitigation.ForTarget`). Revalida Admin + `.ph dm`, exige que el target sea un NPC distinto del NPC de la ficha, y aplica directamente `HarfordServerActions.SetNpcHealthDelta(-total, { addonName="HarfordAdmin", isCritical=isCritical })`. No re-mitiga ni imprime lineas de resistencia; esa informacion ya aparece como marcador coloreado (R/V/I) dentro de la tirada de daño publica. Si el envio se acepta y `HarfordServerActions.ModAnim` esta disponible, el cliente DM ejecuta `ModAnim(33)` sobre su propio personaje (reaccion de impacto del atacante). Para victimas jugador el core gestiona el flujo de recursos por `RADJ` sin llamar a este callback.
  - `HarfordAdminNPC.HandleSlash(tokens)`: dispatcher para `/harfordadmin npc ...`.
- Slash commands:
  - `/harfordadmin npc target`: muestra snapshot local del target.
  - `/harfordadmin npc aura <spellId>`: aplica aura al target.
  - `/harfordadmin npc unaura <spellId>`: quita aura al target.
  - `/harfordadmin npc info`: comando de diagnostico Admin para ver la salida del servidor y validar el parseo de posicion. No usarlo como fuente de ficha.
- Pendiente: confirmar comandos Epsilon reales para inspeccionar, seleccionar, mover o controlar NPC/enemigos.

Contrato `HarfordAdminUnitMenu`:

- Vive en `HarfordAdmin/HarfordAdminUnitMenu.lua`.
- Es exclusivo de `HarfordAdmin` y no debe cargarse desde el core `Harford`.
- Crea botones pequenos en `PlayerFrame` y `TargetFrame`.
- Los botones solo se muestran si `HarfordAdminAPI.IS_ADMIN == true` y `.ph dm` esta activo via `HarfordAuthority.IsDMMode()`.
- La visibilidad se refresca en eventos de carga/login/world/target, mensajes de sistema y al hacer click; no usar ticker continuo ni refrescos diferidos repetidos. Para `.ph dm on/off`, reconsultar `HarfordAuthority.IsDMMode()` en cada evento relevante en vez de cachear el valor.
- El boton visual debe ser circular y pequeno, tipo control nativo de WoW: usar una textura circular de Blizzard (`UI-Panel-MinimizeButton-*`) como base y centrar el icono admin dentro. Evitar bordes como `MiniMap-TrackingBorder` o texturas cuadradas de inventario ocupando todo el boton, porque generan artefactos y no encajan en el hueco entre nombre y retrato.
- Usa `UIDropDownMenu` propio, no `UnitPopup` nativo.
- API:
  - `HarfordAdminUnitMenu.AttachButtons()`: crea/engancha botones si existen los unitframes.
  - `HarfordAdminUnitMenu.RefreshVisibility()`: muestra/oculta segun permisos y target.
  - `HarfordAdminUnitMenu.Open(unit, anchorButton)`: abre el menu para `player` o `target`.
  - `HarfordAdminUnitMenu.BuildNpcMenu(unit)` / `BuildPlayerMenu(unit)`: capturan snapshot de la unidad.
  - `GetMeasuredButtonPoint(unit, parent)` (privada): posiciona el boton alineado con el box name/health del overlay Harford usando `HarfordUnitFrames.GetMeasuredLayout(unit, false)`. `target` → borde derecho del box; `player` → borde izquierdo. Si `GetMeasuredLayout` no esta disponible o el parent no es un frame Harford, devuelve `nil` y `AnchorUnitButton` usa la posicion estatica de respaldo.
- **Comportamiento de la ficha en modo NPC** (`OnTargetChanged` en `HarfordAdminUnitMenu`):
  - El boton `Modo NPC` de la ficha ofrece control de posesion con `Ctrl+click`: con NPC target revalida permiso/unidad y ejecuta `HarfordServerActions.RepossessCurrentNpc({ addonName = "HarfordAdmin" })` (`unposs` → `poss`); con target jugador o sin target ejecuta solo `HarfordServerActions.UnpossessCurrentNpc({ addonName = "HarfordAdmin" })`. En ninguno de los casos activa/desactiva/cambia el contexto de ficha.
  - La ficha NPC **persiste** en la última ficha cargada mientras el modo NPC esté activo. Cambiar a un target jugador, quitar el target o seleccionar ninguno NO limpia la ficha.
  - Solo se recarga en la ficha NPC cuando se selecciona un **nuevo NPC** distinto como target.
  - Para volver a la ficha normal del propio jugador, el DM debe desactivar el modo NPC explícitamente (no basta con deseleccionar o seleccionar un jugador).
  - Implementado: `OnTargetChanged` llama `HarfordAdminNPC.ApplyDnDSheetContext(unit)` solo si `UnitExists("target") and not UnitIsPlayer("target")`.
- Inicializacion event-driven: registra `ADDON_LOADED` (filtrando Harford/HarfordAdmin/SpellCreator/EpsilonLib), `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_TARGET_CHANGED` y `PLAYER_FLAGS_CHANGED`. `CHAT_MSG_SYSTEM` fue eliminado porque disparaba `AttachButtons()`+`RefreshVisibility()` en cada mensaje de sistema sin filtrar (kills, quests, etc.); `HarfordAuthority.RegisterChangeListener` cubre los cambios de modo DM correctamente. No se usa `C_Timer.After` para diferir el attach.
- Reglas de seguridad:
  - Revalidar permisos antes de ejecutar cualquier accion.
  - Revalidar GUID/unidad antes de ejecutar acciones sobre target.
  - NPC health solo desde `TargetFrame` y solo si el GUID sigue coincidiendo.
  - Player health desde el menu admin va por su helper `AdjustResourceForName(...)` / `RADJ`, no por comando servidor. `HarfordDnDAPI.AdjustResourceForName` es el puente estable de vida de jugador (lo usa tambien `HarfordTurns`); no es deuda pendiente de migracion.
  - Auras sobre el propio personaje: `ApplyAura` / `RemoveAuraSelf` (`self`). Auras sobre otro jugador seleccionado: `ApplyAuraToCurrentTarget` / `RemoveAura` (sin sufijo). Auras sobre NPC: `SetNpcAura` / `RemoveNpcAura` (`npc set aura/unaura`).
  - Inputs numericos usan `StaticPopupDialogs`.
- Opciones v1:
  - NPC: abrir ficha TRP3 por `TRP3_API.companions.register.openPage(profileID)`, mostrar TRP3 IDs, anadir/abrir turnos, vida con presets/personalizado, aura/unaura.
  - Jugador: abrir ficha TRP3 por `TRP3_API.register.openPageByUnitID(unitID)`, mostrar TRP3 unitID, anadir/abrir turnos, pedir recursos, vida por RADJ, aura/unaura.

Contrato `HarfordTRP3`:

- Vive en `Harford/TRP3/HarfordTRP3.lua`.
- Encapsula lectura TRP3 sin depender de API base de WoW para fichas.
- TRP3 se trata como dependencia opcional: comprobar runtime antes de usar.
- API inicial:
  - `HarfordTRP3.IsAvailable()`
  - `HarfordTRP3.BuildUnitID(unit)`: construye `Nombre-Reino`.
  - `HarfordTRP3.GetPlayerProfile(unit)`: perfil TRP3 de jugador via `TRP3_API.register`; para `player` debe usar primero `TRP3_API.profile.getPlayerCurrentProfile()`.
  - `HarfordTRP3.GetPlayerProfileByUnitID(unitID)`: perfil TRP3 de jugador por `Nombre-Reino`; si es el propio jugador debe usar `TRP3_API.profile.getPlayerCurrentProfile()`.
  - `HarfordTRP3.GetPlayerAboutText(profile)`: extrae About soportando perfiles remotos (`profile.about`) y perfil propio (`profile.player.about`), con plantillas TRP3 `T1`, `T2` y `T3`.
  - `HarfordTRP3.GetUnitRPName(unit)`: nombre RP si TRP3 lo conoce.
  - `HarfordTRP3.GetAbilityChatLink(feature)`: enlace de chat **clicable** de una habilidad del Libro via el sistema TRP3 ChatLinks (`TRP3_API.ChatLinks` → modulo `harford_ability`, hyperlink `totalrp3`). Los enlaces de tipo propio `harford:` no son clicables en este cliente; TRP3 sí (engancha `ChatFrame_OnHyperlinkShow` internamente). Fallback a texto de color si TRP3 no esta. El tooltip lleva icono inline (`|T...|t`) + nombre coloreado embebidos en el titulo (TRP3 fuerza el titulo a blanco).
  - `HarfordTRP3.GetNpcIdFromGUID(guid)` / `GetUnitNpcId(unit)`.
  - `HarfordTRP3.GetPhaseId()`: lee phase actual desde `C_Epsilon`/`ARC`.
  - `HarfordTRP3.BuildEpsilonNpcFullID(unit)`: construye `phaseID .. "_" .. npcID`.
  - `HarfordTRP3.GetEpsilonNpcProfile(unit)`: perfil companion/NPC via `TRP3_API.companions.register.getCompanionProfile(fullID)`.
  - `HarfordTRP3.GetEpsilonNpcProfileByProfileID(profileID)`: fallback para perfiles companion/NPC ya presentes en `TRP3_API.companions.register.getProfiles()`.
  - `HarfordTRP3.GetEpsilonNpcProfileID(unit)`: profileID asociado via `getCompanionProfileID(fullID)`.
  - `HarfordTRP3.GetEpsilonNpcMainText(unit)`: devuelve `profile.data.TX`.
  - `HarfordTRP3.GetPhaseAddonProfileKey(unit)`: construye `TOTALRP_PROFILE_<npcID>`.
  - `HarfordTRP3.GetProfileIcon(profile)`: devuelve icono principal de ficha, priorizando `profile.data.IC` antes de busqueda recursiva.
  - `HarfordTRP3.GetProfileLevel(profile)`: intenta leer nivel desde campos TRP3 conocidos (`LV`, `LVL`, `level`, `Nivel`). Si no hay campo estructurado, interpreta el About para multiclase sumando lineas con formato `Clase (nivel)`, por ejemplo `Picaro (3)` + `Paladin (1)` = `4`; luego cae a `Nivel X`/`Level X`. Si no hay dato, el consumidor debe caer a `UnitLevel`.
  - `HarfordTRP3.GetProfilePrimaryClass(profile)`: interpreta primero el About crudo con lineas `Clase (nivel)` y devuelve la clase con mayor nivel. Si hay icono `{icon:classicon_<clase>:...}`, usar ese token como pista principal. Solo si no hay clase en About cae a campos estructurados (`CL`, `class`, `Clase`). Ejemplo: `Picaro (3)` + `Paladin (6)` => `Paladin`.
  - `HarfordTRP3.GetProfileIconCandidates(profile)`: helper de diagnostico; usarlo desde `HarfordDebug`, no desde flujo normal.
  - `HarfordTRP3.GetProfileStates(profile)`: devuelve estados/glances activos con `IC`, `TI` y `TX`. En NPC companion lee `profile.PE`; en jugadores remotos lee `profile.misc.PE`; en el propio jugador lee `profile.player.misc.PE`.
  - `HarfordTRP3.BuildStatesDisplayText(profile)`: compone una lista vertical dinamica de estados activos con icono grande + titulo + texto.
  - `HarfordTRP3.ConvertTRP3Markup(text)`: convierte markup TRP3 basico a texto WoW renderizable (`|c`, `|T`, saltos, titulos).
  - `HarfordTRP3.BuildDisplayText(profile)`: compone `profile.data.TX` + estados activos para visor de ficha.
  - `HarfordTRP3.CreateGlanceLink(glance)`: crea y registra localmente una copia no importable `AT_FIRST_GLANCE` mediante `TRP3_API.ChatLink`, devolviendo el objeto registrado. Centraliza un cache en memoria por contenido `TI`/`TX`/`IC`: repetir el mismo estado en modo normal o DM reutiliza el mismo `ChatLink` y no vuelve a crecer `sentChatLinks` de TRP3. No alterar el identificador entregado a TRP3 con sufijos o escapes decorativos: forma parte del protocolo del enlace.
  - `HarfordTRP3.GetLastGlanceLinkInfo()`: devuelve la ultima copia creada/reutilizada como `{link, sender, identifier, marker, hyperlink}` para diagnostico y acciones DM validadas.
  - `HarfordTRP3.IsKnownGlanceHyperlink(hyperlink)`: solo devuelve `true` para hyperlinks generados por `CreateGlanceLink` en la sesion; es el guard que evita enviar texto libre como `npc te`.
  - `HarfordTRP3.InsertGlanceLink(glance)`: callback sobrescribible para la extension de **estados ajenos**. Por defecto crea una copia local registrada con `CreateGlanceLink` e inserta su marcador plano `[TRP3:identificador]`. `HarfordAdmin` lo sustituye para la emision NPC segura en modo DM.
- Shift-click en estados ajenos del viewer TRP3: `HarfordTRP3` hookea en PLAYER_LOGIN los botones de glance de TRP3 (jugadores, companions/NPC y barra del target frame). Sin modo DM crea una copia local no importable del estado e inserta el marcador TRP3 enviable.
- En modo `HarfordAdmin + .ph dm`, `HarfordAdminNPC` cambia el comportamiento de los estados ajenos capturados por `HarfordTRP3.InsertGlanceLink`: con un NPC target registra/reutiliza el link y envia `npc te <hyperlink totalrp3>` mediante `HarfordServerActions.SendNpcTRP3Hyperlink`. Si hay `focus`, anexa su nombre plano (RP TRP3 o WoW) DESPUES del hyperlink (`opts.textSuffix`) => `npc te [estado] <Focus>`; sin focus no anexa nada. El prefijo del Ctrl+prompt (`opts.textPrefix`) sigue yendo ANTES. Sin NPC target, con target jugador o si falla el envio, imprime el hyperlink local como fallback.
- Envio directo por NPC validado en juego: `npc te [TRP3:id]` via EpsilonLib queda como marcador plano; `npc te <hyperlink totalrp3>` via `EpsilonLib.AddonCommands` produce un mensaje NPC clicable cuyo tooltip resuelve correctamente tanto en el cliente DM como en un segundo cliente.
- Protocolo nativo TRP3 confirmado en la copia Epsilon: `ChatLinkModule:InsertLink(...)` crea un `TRP3_API.ChatLink`, lo registra en `ChatLinksManager:StoreSentLink` y solo inserta texto plano `[TRP3:identificador]`. Al llegar por un canal de chat, `ChatLinks.lua` transforma ese marcador en hyperlink visible `totalrp3:emisor:identificador`. Al clicar, el receptor envia `CTLK_R` al **emisor del mensaje**, y este responde con `CTLK_D` buscando el identificador en su tabla de links enviados.
- Consecuencia: un enlace TRP3 no transporta su ficha dentro del texto visible; apunta al emisor que tiene el `ChatLink` registrado. Para compartir un estado ajeno desde Harford, el cliente que lo origina debe crear/registrar su propia copia con datos del estado y `canBeImported=false`.
- Ciclo de vida/memoria de links: `TRP3_API.ChatLinksManager` mantiene `sentChatLinks` en una tabla privada y no expone API de borrado. No intentar purgar enlaces enviados: rompería links antiguos aún clicables en chat. La mitigacion obligatoria es reutilizar `CreateGlanceLink` por contenido y no instanciar `TRP3_API.ChatLink` directamente desde Admin u otros módulos. La memoria solo crece cuando se comparte un contenido de estado realmente distinto durante la sesión.
- Links ya visibles en chat: no enganchar ni reemplazar `ChatFrame_OnHyperlinkShow` desde Harford o HarfordAdmin. TRP3 ya procesa los clicks en su cliente, y los intentos de reescribir el editbox rompieron enlaces existentes, `.npc te` y links de terceros.
- No sobrescribir `TRP3_API.ChatLinks.OpenMakeImportablePrompt` ni `TRP3_API.AtFirstGlanceChatLinksModule.InsertLink`: los estados propios deben mantener el flujo nativo de TRP3. Harford solo complementa estados ajenos, que TRP3 no enlaza por si solo.
- El render de ficha en turnos debe simular los bloques/frames de TRP3 cuando el texto venga en secciones: cabecera con icono/titulo, separador fino e indentacion del cuerpo. Evitar una columna plana de texto corrido.
- `HarfordAdminNPC` usa este modulo con `/harfordadmin npc trp3` para mostrar fullID/profileID y preview de `data.TX`.
- `Harford/Frames/HarfordTurns.lua` usa `HarfordTRP3.GetEpsilonNpcProfile(unit)` al anadir un target no jugador al tracker de turnos, y luego `HarfordTRP3.GetProfileIcon(profile)` para tomar el icono principal de ficha TRP3.
- No usar busqueda recursiva sin prioridad para iconos TRP3: puede coger `IC` de estados/PE u otros bloques antes que el icono real de la ficha.
- En turnos, si una entrada tiene `entry.icon`, ese icono persistido tiene prioridad sobre `SetPortraitTexture`. Motivo: el retrato vivo de `target`/`mouseover` puede perderse al cambiar de objetivo/personaje y degradar a una textura incorrecta. Solo usar `SetPortraitTexture` si no hay icono persistido.
- `HarfordTurns` ya serializa `displayId`. Si no hay icono TRP3 persistido, debe intentar `SetPortraitTextureFromCreatureDisplayID(texture, entry.displayId)` antes de usar retratos vivos de `target`/`mouseover`. Esto permite reconstruir un portrait estable por modelo de criatura aunque el GUID concreto ya no este targeteado.
- No guardar `texture:GetTexture()` despues de `SetPortraitTexture`: puede devolver valores internos/genericos como retratos temporales, no una ruta de textura estable.
- En tarjetas de turnos, si una entrada de jugador tiene `Res_temp_health_Cur > 0`, la barra pequena de vida debe mostrar una capa azul de vida temporal y texto `vida+temp/max`. Al restar vida desde turnos, primero se envia `RADJ temp_health -N` hasta agotar la vida temporal; solo el resto se envia como `RADJ health -N`. Para que esto funcione, el receptor de recursos permite ajustes remotos controlados de `health` y `temp_health`.
- Modelo de datos recomendado para turnos/NPC:
  - `entry.id`: GUID unico de la instancia concreta.
  - `entry.npcId`: id base extraido del GUID, para agrupar criaturas iguales o buscar `TOTALRP_PROFILE_<npcID>` si se anade en el futuro.
  - `entry.displayId`: modelo/apariencia de criatura para portrait estable.
  - `entry.icon`: icono TRP3 o icono persistido manual, prioridad maxima.
- Las entradas de turnos guardan metadatos TRP3 opcionales:
  - `entry.trpFullID`: `phaseID .. "_" .. npcID`, para volver a cargar ficha TRP3 aunque ya no este targeteado.
  - `entry.trpUnitID`: `Nombre-Reino` para volver a cargar ficha TRP3 de jugadores, incluido el propio `player`.
  - `entry.trpProfileID`: profileID TRP3 companion/NPC como fallback si existe en `TRP3_API.companions.register.getProfiles()`.
  - `entry.nameColor`: color hexadecimal usado por nombres de jugador en turnos. Prioridad: color manual de nombre TRP3 (`characteristics.CH`); si no existe, color de la clase principal calculada desde la ficha TRP3 (`GetProfilePrimaryClass`, soporta multiclase y acentos); si tampoco existe, fallback a `UnitClass`/`RAID_CLASS_COLORS` cuando la unidad este visible.
  - `entry.npcId`
  - `entry.phaseId`
- **Nombres en el tracker de turnos — sin realm**: `entry.unitName` y `entry.trpUnitID` se serializan siempre con nombre corto (`Ambiguate(name, "short")`, o `name:match("^[^%-]+")`), igual que las claves del banco de fichas. El receptor normaliza con `NormalizePlayerUnitID` si necesita el realm. `adminName` fue retirado de SavedVariables; el campo legacy viaja vacio para compatibilidad de protocolo. Todos en el mismo servidor Epsilon: realm no aporta identificacion extra en el payload de sync.
- Sincronizacion `HARFORDTURN`:
  - Los estados pequenos siguen viajando como `STATE|activeIndex||entries`.
  - Si el estado supera el limite seguro, `HarfordTurns` lo parte en mensajes `SCHUNK|transferId|index|total|chunk`.
  - El receptor agrupa trozos por `sender + transferId`, los reensambla en orden y solo entonces aplica el `STATE`.
  - Los chunks escapan `%` y `|` para no romper el parser del protocolo.
  - No enviar el texto completo de fichas TRP3 por sync de turnos. El estado debe enviar solo identificadores y metadatos estables.
  - **Filtro de remitente**: el emisor difunde por `BestChannel()` (RAID/PARTY), pero `CHAT_MSG_ADDON` entrega tambien WHISPER de cualquiera y estos mensajes REESCRIBEN el estado compartido (entradas, turno activo, vida de NPC). El receptor descarta los que no vengan de un remitente reconocido (propio, unidad visible o grupo/raid via `HarfordClassColors.FindUnitByName`), igual que el resto de opcodes con efecto. No retirar ese guard.
  - Para NPC Epsilon, enviar/normalizar `entry.trpFullID`, `entry.phaseId`, `entry.npcId` y, si se conoce, `entry.trpProfileID`; el cliente receptor debe asumir que ya tiene esa ficha en su TRP3 local y cargarla con `getCompanionProfile(entry.trpFullID)`, usando `getProfiles()[entry.trpProfileID]` solo como fallback.
  - Para jugadores, enviar/normalizar `entry.trpUnitID`; el cliente receptor debe cargar el About desde `TRP3_API.register` o desde el perfil propio si corresponde.
- Click izquierdo sobre una tarjeta de turnos abre una ventana de ficha. Para NPC Epsilon intenta cargar `profile.data.TX` desde `TRP3_API.companions.register.getCompanionProfile(entry.trpFullID)`. Para jugadores carga `profile.about` desde `TRP3_API.register` resolviendo primero `entry.trpUnitID`/nombre, y si hace falta busca la unidad viva por GUID (`player`, `target`, `mouseover`, grupo/raid). No abrir jugadores directamente por un `entry.trpProfileID` persistido: es un ID opaco que puede quedar obsoleto/cruzado y mostrar una ficha incorrecta.
- El titulo de la ficha de turnos debe mostrar icono persistido + nombre. En jugadores, el nombre usa `entry.nameColor` de TRP3; en NPC, usa el color de reaccion/reputacion guardado.
- Orden manual de turnos: el boton `Editar` activa modo ordenacion. En ese modo, click izquierdo sobre una carta la selecciona para mover y click izquierdo sobre otra posicion la coloca ahi; el overlay morado indica la seleccion. Las flechas `<`/`>` siguen moviendo de uno en uno. Tambien existe `/harford turnos mover <origen> <destino>` para ordenar por indice exacto.
- Para jugadores en turnos, refrescar `entry.nameColor` desde TRP3 cuando se renderiza la carta si el perfil esta disponible. Al anadir un jugador, guardar `entry.trpUnitID` y `entry.trpProfileID` cuando TRP3 los exponga, pero considerar `trpUnitID` la identidad estable para lectura. Al abrir ficha de jugador, resolver por `entry.trpUnitID` con `getUnitIDProfileID`/`hasProfile` + `getProfile`; despues probar variantes (`entry.unitName`, `entry.name`, con/sin reino); y solo como fallback buscar unidades vivas por GUID/nombre (`player`, `target`, `mouseover`, `focus`, party/raid). `NormalizeEntryLinks` limpia `npcId`, `phaseId` y `trpFullID` en toda entrada `player`. Los jugadores no se cargan como companions/NPC ni disparan `.npc info`.
- Seguridad sobre `.npc info`: no forma parte del flujo de turnos ni de carga de fichas. Solo se emite desde `HarfordAdmin` para diagnostico explicito o para obtener la posicion del NPC origen en areas; requiere que Admin este cargado y la accion venga de la ruta DM.
- La ventana de ficha abierta desde turnos debe intentar parecerse visualmente al panel About/TRP3: textura/fondo negro en el cuerpo, marco interior claro que no sobresalga, titulo arriba separado del contenido, texto grande y zona de lectura con margen amplio. Mantener icono + nombre en el titulo. La ficha de jugador usa la misma estructura visual, pero debe encapsular sus secciones de About TRP3 como bloques.
- El visor de ficha de turnos debe usar `HarfordTRP3.BuildDisplayText(profile)`, no texto plano, para parecerse lo maximo posible al formato TRP3 dentro de las limitaciones de FontString WoW.
- Estados: si `profile.PE[i].AC` o `profile.misc.PE[i].AC` esta activo, mostrar `IC`, `TI` y `TX` despues del texto principal como lista vertical dinamica, sin encabezado generico tipo "Estados activos". Los estados inactivos no deben aparecer.
- Iconos TRP3: `IC` puede ser ruta, nombre de icono o fileID numerico. No convertir fileIDs numericos a `Interface\Icons\<id>`; WoW puede renderizarlos directamente en `|T...|t`.
- Reaccion/color de NPC en turnos:
  - Al anadir una unidad no jugador, capturar `UnitReaction(unit, "player")` en `entry.reaction`.
  - Colores esperados: `1-2` hostil rojo, `3` unfriendly naranja, `4` neutral amarillo, `5-8` aliado/friendly verde.
  - Usar el color guardado para el nombre del NPC en el tracker, porque la unidad puede dejar de estar targeteada o visible.
- Color de jugadores en turnos:
  - Al anadir un jugador, capturar el color TRP3 desde `profile.characteristics.CH` o, para el propio player, `profile.player.characteristics.CH`.
  - Usar ese color en el nombre de la tarjeta y en el titulo de la ficha.
- Botones `+` / `-` en turnos:
  - Para NPC/enemigos, antes de tocar vida se debe comprobar que `UnitGUID("target") == entry.id`. Si no coincide, no ejecutar comando servidor ni modificar vida local.
  - Para NPC/enemigos, si coincide el GUID, enviar comando servidor seguro `npc set health -1` o `npc set health +1` mediante `HarfordServerActions.SetNpcHealthDelta`.
  - Para jugadores, no modificar la vida localmente desde el tracker. Enviar una senal `RADJ|health|delta` por `WHISPER` al jugador usando el prefix `DND5EARC`; el cliente receptor aplica `AdjustResourceCurrent("health", delta)` y responde con sus recursos actualizados.
  - Shift+click en `+` o `-` abre una entrada numerica para sumar/restar una cantidad concreta. La cantidad debe pasar por el mismo flujo seguro que el click normal: jugador via `RADJ`, NPC via validacion de GUID + comando servidor.
  - La barra de vida de jugadores en turnos debe leer `HarfordDnDAPI.GetResourcesForName(...)`; no usar vida base de WoW ni una copia local del tracker como autoridad final. Si no hay recursos cacheados todavia, mostrar `--/--`.
  - El tracker de turnos solo muestra una barra de vida. La antigua barra secundaria/mana no se usa.
  - Cuando `UnitGUID("target") == entry.id`, la tarjeta debe marcarse como objetivo exacto con borde cian y etiqueta compacta `OBJETIVO`. Esto aplica a jugadores y NPCs y debe refrescar en `PLAYER_TARGET_CHANGED`.
  - Si `PLAYER_TARGET_CHANGED` selecciona un NPC ya cargado en turnos por GUID, actualizar `entry.hp` y `entry.maxHp` desde `UnitHealth("target")` / `UnitHealthMax("target")`. Para NPC visible, la vida real del target tiene prioridad sobre la vida guardada.
  - Al recibir recursos `RES` o configuracion de recursos remota, refrescar el tracker de turnos si `HarfordTurnOrderAPI.Refresh` existe.
  - **Frontera admin/core de turnos (NO hacer split fisico):** el tracker, el store, la serializacion/sync (`HARFORDTURN`) y las mutaciones viven todos en el core `HarfordTurns.lua`. Las mutaciones (`AddEntry`/`AddUnit`/`RemoveEntry`/`AdjustHp`/`NextTurn`/`PrevTurn`/`MoveEntry`/`ToggleEditMode`) estan **gateadas por `IsTurnAdmin()` = `HarfordAuthority.CanUseDMTools()`** (inertes sin HarfordAdmin + `.ph dm`). La superficie de control publica es `HarfordTurnOrderAPI` (`Toggle/Refresh/SendState/AddEntry/AddUnit/NextTurn/PrevTurn/RemoveEntry/AdjustHp/MoveEntry/ToggleEditMode/IsAdmin`); **`HarfordAdmin` las invoca por ese API** (p.ej. `HarfordAdminUnitMenu` usa `AddUnit`/`Toggle`) y NO debe tocar internals (store/broadcast). No mover las mutaciones a `HarfordAdmin`: romperia los botones del propio tracker (UI core) sin ganancia (ya estan gateadas). No extraer la capa de serializacion/sync sin validacion en juego: es el camino multi-cliente y el riesgo es desproporcionado.
  - El tracker no debe mostrar controles manuales de `Nombre/NPC`, `Ini`, `Vida`, `Max` ni boton generico `NPC`: el flujo correcto es anadir desde `Objetivo` o `Jugador` para conservar GUID, TRP3, reaccion y recursos.
  - Si el turno activo recibido o avanzado pertenece al jugador local, mostrar una alerta local estilo banda (`RaidWarningFrame`) y reproducir sonido de raid warning si esta disponible. Evitar repetirla en cada refresh guardando una clave del turno ya alertado.
  - Si hay mas de `MAX_CARDS` entradas, la ventana debe permitir desplazar la vista con botones `<` y `>` sin cambiar el turno activo. Al avanzar/retroceder turno, autoajustar la vista para que el activo quede visible.
- Si no encuentra icono TRP3, cae al fallback por tipo/clasificacion de criatura.

Contrato `HarfordConfig`:

- Vive en `Harford/Core/HarfordConfig.lua`. SavedVariable: `HarfordConfigStore` (tabla plana de clave→valor).
- API: `HarfordConfig.Get(key)`, `HarfordConfig.Set(key, value)`, `HarfordConfig.Reset()`, `HarfordConfig.RegisterChangeListener(fn)`.
- Claves actuales y defaults:
  - `portrait_player = "trp3"`: retrato del jugador. `"trp3"` usa icono TRP3 si disponible, `"wow"` usa retrato 3D WoW.
  - `portrait_target_player = "trp3"`: retrato del target cuando es jugador.
  - `portrait_target_npc = "trp3"`: retrato del target cuando es NPC. Default `"trp3"` porque en Epsilon los NPCs pueden tener ficha companion TRP3; cae a WoW 3D si no hay perfil.
  - `resources = "unitframe"`: modo de recursos del target. `"unitframe"` activa el overlay Harford con barras DnD en player y target jugador. `"frame"` restaura los unitframes nativos de WoW para ambas unidades y muestra `HarfordDnDTargetResourceFrame` (frame separado flotante) para el target. En modo `"frame"`, los cambios de barras/textos/niveles/recursos de `HarfordUnitFrames` deben quedar desactivados; solo se permite seguir aplicando retratos segun `portrait_player`, `portrait_target_player` y `portrait_target_npc`.
  - `nameplates = "on"`: activa overlays DnD de `HarfordNamePlates` sobre placas de nombre. `"off"` oculta y limpia sus overlays.
- Los `RegisterChangeListener` deben ser livianos: `HarfordUnitFrames` llama `API.Refresh(false)` al cambiar config y fuerza `RefreshTargetOfTargetBars(true)` + `focusTot.refresh(true)` para que ToT/FocusToT actualicen icono/modo sin tener que quitar y volver a seleccionar target; `HarfordDnD` llama `RefreshTargetResourceFrame()` + `HarfordUnitFrames.Refresh(false)`.
- Panel de opciones abre con `/harford config` o desde Interface Options → Addons → Harford. Usa `UIDropDownMenuTemplate` (no checkboxes). El dropdown muestra la opcion activa al abrir el panel (`UIDropDownMenu_SetText` se llama en `MakeDropDown` al crear y en `OnShow`).
- Panel tiene una seccion `UnitFrames Harford` con tres dropdowns de retrato en horizontal: `Propio`, `Objetivo` y `Objetivo NPC`, mas un dropdown de recursos debajo. Ancho de dropdown: 160px.
- Panel tiene una seccion `Nameplates Harford` con dropdown `nameplates` (`Activado`/`Desactivado`). Al resetear defaults, refrescar tambien este dropdown.
- En `HarfordConfig.lua`, por compatibilidad con llamadas antiguas, `MakeLabel`/`MakeDropDown` remapean textos/posiciones historicas (`Retrato - Jugador`, `Target jugador`, `Target NPC`) a la disposicion horizontal nueva. Si se limpia esta deuda, hacerlo en una sola pasada reemplazando las llamadas antiguas del panel, no quitando el remapeo sin ajustar la UI.

Contrato `HarfordUnitFrames`:

- Vive en `Harford/Frames/HarfordUnitFrames.lua`.
- Lua 5.1 tiene limite duro de 200 locals por scope. Este archivo ya es grande, asi que no anadir nuevos `local` de file-scope salvo necesidad clara.
- Constantes compartidas de UnitFrames viven en `HarfordUnitFrames.C`; estado mutable/cache/flags viven en `HarfordUnitFrames.S`. Usar ese patron antes que declarar mas locals sueltos arriba.
- Si se anaden helpers grandes, preferir bloque `do ... end` con funciones internas y exponer solo lo necesario por una tabla existente (`API`, `API.S.focusTot`, etc.). Esto evita consumir slots de local del scope global del archivo.
- La misma regla aplica al resto de modulos grandes: evitar acumular locals de file-scope; agrupar estado interno en una tabla de modulo cuando el archivo crezca.
- Es un reemplazo visual propio para unidades jugador, anclado a `UIParent` y posicionado sobre `PlayerFrame`/`TargetFrame`/`FocusFrame`.
- Crea `HarfordPlayerUnitFrame`, `HarfordTargetUnitFrame` y `HarfordFocusUnitFrame` solo para unidades jugador. Si `focus` no existe o no hay `FocusFrame` nativo, el frame Harford de focus queda oculto.
- Muestra:
  - icono principal TRP3 desde `HarfordTRP3.GetProfileIcon(profile)`;
  - nivel TRP3 desde `HarfordTRP3.GetProfileLevel(profile)`, con fallback a `UnitLevel(unit)`;
  - recursos Harford desde `HarfordDnDAPI.GetResourcesForName`.
- Los recursos se muestran como barras apiladas hacia abajo usando el orden de `HarfordDnDResources.ORDER`.
- Cada recurso activo (`HarfordDnDResources.Exists`) genera una barra con textura `UI-StatusBar`, color del recurso, etiqueta y `cur/max`.
- **Recursos derivados de clase en unitframes**: un recurso nuevo de clase (Imposición de Manos, Furia, Energía, etc.) se renderiza en los unitframes (propio y del target) **solo si su `_Max` viaja con el maximo EFECTIVO**. La ruta canonica es `HarfordDnDNet.ExportCurrentResources()` / `HarfordDnDNet.BuildActiveResourcePayload` via `WrapDerivedMax`: reescribe toda clave `Res_<key>_Max` como `base ARC + HarfordDnDFeatureEffects.GetResourceMaxBonus(key, profile)`, igual que el frame de recursos local (`GetResourceMax`). Esto aplica en el broadcast programado de `ScheduleMyResourceBroadcast`, en `SendResourceResponseTo` y en `SendResourceResponseForProfileTo` (perfil del banco). No crear builders paralelos desde `HarfordDnD.lua`: siempre delegar en `HarfordDnDNet`. En contexto NPC aplicado (`HarfordDnDContext.State.active`) el bonus de rasgos del jugador NO se inyecta (`allowDerived=false`). Al añadir un recurso de clase nuevo: (1) registrarlo en `ORDER/ALL_KEYS/DEFS/PROFILE_KEYS/RUNTIME_KEYS` de `HarfordDnDResources`; (2) **AÑADIR sus claves `Res_<key>_Cur/_Max` (Cur+Max) a `HarfordSync.ResourceKeys.Runtime` y la `_Max` a `.Config`, APENDADAS AL FINAL**; (3) darle su `resourceMax` en `HarfordDnDBook`. **El paso (2) es OBLIGATORIO y fácil de olvidar**: `HarfordSync.lua` carga ANTES que `HarfordDnDResources.lua` (orden del `.toc`), por eso mantiene listas hardcodeadas DUPLICADAS que generan el mapa de códigos base36 de la serialización de red (`BuildResourceCodeMaps`). Un recurso ausente de esas listas se ve en TU propia ficha (via `ExportCurrentResources`+`ALL_KEYS`) pero **NO se serializa al cliente del target** (se descarta silenciosamente al no tener código). Apendar al final preserva los códigos de clientes en versión anterior; nunca reordenar.
- **Recarga por descanso** (`HarfordDnDResources.DEFS[key].recharge`, getter `GetRecharge`): `"short"` = se recupera al maximo en descanso corto y largo; `"long"` = al maximo solo en largo; `"reset"` = pool de combate que se acumula desde 0 y el descanso VACIA a 0 (Furia); `"none"` = nunca con descansos. `ApplyShortRest` (HarfordDnD.lua) rellena al maximo solo los `"short"` (y ya NO auto-cura vida: eso son dados de golpe); `ApplyLongRest` cura vida full y rellena `"short"`+`"long"` (los `"none"` como `temp_health` no se tocan). Reglas del manual: **short** = `chi`, `energy`, `fel_point`, `focus`, `channel_divinity`, `totem` (Totemista), `maelstrom` (Torbellino); **reset** (pool de combate que se acumula desde 0; el descanso lo VACIA a 0 en vez de rellenarlo) = `rage` (label "Ira"; Furia Interna del Guerrero: **+1 AUTOMATICO al infligir daño con un ataque de arma** —enganchado en `onImpactOnce` de `DoWeaponAttack`, solo ficha propia y si `GetResourceMax("rage")>0`, cap = nivel via `AdjustResourceCurrent`—, se disipa a 0 en el descanso; el gasto en maniobras y la condicion "que no hayas gastado puntos en ese ataque" se gestionan a mano con los botones +/-); **long** = `mana`, `runic_power`, `mage_point`, `light_point` (Puntos de Fe; el +2/+3/+4 parcial en descanso corto desde L5 queda informativo), `soul_shard` (el manual permite crear +1 en descanso corto; modelado solo como full en largo), `astral_power`, `living_seeds`, `holy_power`, `healing_mist` (label "Chi sanador"). **Metamorfosis no es un recurso**: es el rasgo `dh_metamorfosis`, con `uses={max=1,recharge="long"}`, mostrado y restablecido por el sistema general de usos del Libro. Imposicion de Manos se recarga con el sistema de usos de rasgo, no con barras. Un recurso nuevo de clase debe declarar su `recharge`; sin campo se asume `"long"`.
- La fuente principal de geometria es automatica, no coordenadas fijas:
  - `MeasureNativeLayout(unit)` mide en runtime el unitframe Blizzard real antes de ocultarlo.
  - `ApplyMeasuredLayout(frame, layout)` aplica esos bounds al frame Harford.
  - `HarfordUnitFrames.GetMeasuredLayout(unit, force)` expone/cachea la medicion para debug.
- Convenio de coordenadas en layouts: `x` es offset positivo desde el left del root; `y` es offset positivo hacia abajo desde el top del root (igual que pixeles desde arriba). En `SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)` el `-y` convierte al sistema WoW donde negativo = abajo. `cx`/`cy` siguen el mismo convenio. La funcion interna `RelativeBounds` calcula `y = rootBounds.top - bounds.top` (positivo cuando el elemento esta debajo del top del root). No invertir el signo al usar `box.y` en SetPoint: siempre negar (`-box.y`) para obtener la direccion correcta hacia abajo.
- Medir desde las piezas nativas cuando existan:
  - root: `PlayerFrame` / `TargetFrame` / `FocusFrame`;
  - portrait: `PlayerPortrait` / `TargetFramePortrait` / `FocusFramePortrait`;
  - health: `PlayerFrameHealthBar` / `TargetFrameHealthBar` / `FocusFrameHealthBar`;
  - power: `PlayerFrameManaBar` / `TargetFrameManaBar` / `FocusFrameManaBar`;
  - level: `PlayerFrameTextureFrameLevelText` / `TargetFrameTextureFrameLevelText` / `FocusFrameTextureFrameLevelText`;
  - name: `PlayerName` / `TargetFrameTextureFrameName` / `FocusFrameTextureFrameName`;
  - textura principal: `PlayerFrameTexture` / `TargetFrameTextureFrameTexture` / `FocusFrameTextureFrameTexture`, o la region mas grande con textura `TargetingFrame`.
- Convertir bounds absolutos (`GetLeft/GetTop/GetRight/GetBottom`) a offsets locales relativos al root nativo y usar esos offsets para portrait, barras, nombre, nivel y carcasa.
- Para unidades jugador, usar el unitframe Blizzard real como superficie visual siempre que sea posible. No ocultarlo ni recrear sus barras si se puede inyectar el valor/color en las barras nativas.
- Estrategia actual de portrait: atacar directamente `PlayerPortrait` / `TargetFramePortrait` / `FocusFramePortrait`. No usar `portraitLayer` ni portrait Harford propio mientras la mascara nativa funcione.
- Al escribir iconos TRP3 en el portrait nativo, aplicar `Texture:AddMaskTexture` con `Interface\\CharacterFrame\\TempPortraitAlphaMask` si existe. Mantener el level nativo y actualizar solo su texto.
- Aunque el unitframe Blizzard quede visible, Harford debe ocultar widgets nativos de clase/combo (`Combo`, `ClassPower`, `ClassResource`, runas, holy power, etc.) en cada refresh. La carcasa y barras nativas se conservan; los recursos de clase nativos no.
- La carcasa Harford debe copiar solo la textura principal medida (`texture`, `texcoord`, `vertexColor`, tamano y posicion relativos). No clonar hijos/regiones indiscriminadamente.
- Si la textura principal no se puede medir, usar fallback con `Interface\\TargetingFrame\\UI-TargetingFrame` y texcoords conocidos de player/target.
- Las barras usan bounds reales de `HealthBar` y `ManaBar`, con inset interno pequeno, y quedan en un frame level inferior al overlay para que el marco haga de borde/mascara visual.
- Para las dos primeras barras, Harford escribe en `nativeBar.TextString` el label formateado y lo mantiene oculto. WoW puede resetear ese TextString en UNIT_HEALTH/UNIT_POWER_UPDATE, pero `ReapplyNativeBars` lo re-aplica inmediatamente (mismo frame, sin parpadeo). No existe overlay adicional de strata HIGH: fue eliminado porque causaba doble texto en hover. Una sola capa en el TextString nativo mas el hook de hover es suficiente.
- Para las dos primeras barras, no crear ni mostrar barras Harford propias. Solo actualizar la barra nativa con valor/color/texto. El texto aparece unicamente en hover via `HookScript`.
- No forzar `SetStatusBarTexture` sobre barras nativas salvo que sea imprescindible: puede cambiar el material bajo la mascara Blizzard y dejar tonos grises o artefactos.
- En unitframes, la barra `health` debe usar verde estilo Blizzard por legibilidad/parecido visual al unitframe original, aunque el recurso Harford tenga otro color en otras UI.
- Vida temporal en unitframes principales (`player`/`target`/`focus`): `BuildResourceList` adjunta `tempCur` al recurso `health` desde `resources["Res_temp_health_Cur"]`. El enfoque DiceMaster literal (`Interface\\AddOns\\DiceMaster\\Texture\\health-bar`, texcoord `0.75..1`, valor `health + temp`) fue probado y rechazado: en barras pequeñas de Harford/nameplates genera franjas rojo/amarillo/negras y parece overheal/vida rota. En Harford core usar solo texturas Blizzard: base azul opaca con `WHITE8x8`, patron rallado dominante recortado con `Interface\\RaidFrame\\Shield-Overlay` y borde/glow nativo `Interface\\RaidFrame\\Shield-Overshield`, con valor `temp/max` por encima de la vida normal. No usar base demasiado transparente: deja ver la salud normal debajo y el usuario lo percibe como barra translucida. No usar `Absorb-Edge`: en este cliente/SL no es el borde correcto y no se ve. No usar `Shield-Overlay` como unico material del `StatusBar`: el cliente puede recortarlo como una barra plana y perder el rallado; debe ser una capa decorativa independiente limitada al ancho real del escudo. No usar `Raid-Bar-Hp-Fill` para vida temporal: se ve como barra azul plana y pierde el patron de escudo. En barras nativas (`PlayerFrameHealthBar`, `TargetFrameHealthBar`, `FocusFrameHealthBar`) NO usar un `StatusBar` hijo para el absorb: con `FrameLevel +1` tapa texto/marco, y con el mismo level queda debajo del fill nativo. La solucion es crear `Texture` regions directamente en la barra nativa en draw layer `OVERLAY` con subniveles negativos: base `WHITE8x8` en `OVERLAY,-3`, patron `Shield-Overlay` en `OVERLAY,-2`, borde `Shield-Overshield` en `OVERLAY,-1`; el texto Harford/nativo debe forzarse a `OVERLAY,7`. Ese orden da `vida normal -> vida temporal -> texto`, sin subir a un frame level que tape el marco. El borde `Shield-Overshield` debe ser contenido (`~0.9x` alto de barra) y centrado dentro de la barra, no sobresalir arriba/abajo. No usar assets de Kui fuera de KuiNameplates. No modificar el valor de salud ni sumar visualmente `health + temp`.
- Solo los recursos extra, a partir del tercero, pueden usar barras propias apiladas bajo el frame. `focus` sigue la misma regla que `target`: barras 1-2 nativas, barras 3+ Harford con `barSlotOverlays`.
- **Retrato del `PlayerFrame` (icono TRP3) revierte a 3D con ciertas auras — CASO LIMITE NO RESUELTO**: en modo `frame`, el icono TRP3 del player se pinta sobre la textura nativa `PlayerPortrait`. Al aplicar ciertas auras (p.ej. "llamas"+"asustado") a un NPC target, Blizzard repinta el retrato del player via `UnitFramePortrait_Update(PlayerFrame)` **y** `SetPortraitTexture(...,"player")` (confirmado con `/harford debug run portraitwatch`: el retrato acaba en el render-texture del modelo 3D), dejando el 3D hasta el siguiente refresh (cambio de target). **Enfoque FALLIDO (no reintentar):** `hooksecurefunc` defensivo sobre `UnitFramePortrait_Update` (filtrando `PlayerFrame`) **y** `SetPortraitTexture` (filtrando `unit=="player"`) re-aplicando `ApplyNativePortraitOption("player")` — probado en juego y el repintado persiste igual; además añade coste de hook global. Revertido. Solo ocurre con esas auras concretas (no con "derribado"); es un caso límite de baja prioridad, dejado pendiente. Diagnóstico disponible: `/harford debug run portraitwatch`.
- `TargetFrameToT` / unidad `targettarget`: el parpadeo de barras esta resuelto con `totBarsOverlay`. El portrait TRP3 tambien usa overlay (`totBarsOverlay.portraitFrame`) para evitar que `TargetofTarget_Update` restaure el portrait 3D nativo, pero ese portrait overlay es hijo del propio `TargetFrameToT`: solo sustituye el icono, no intenta quedar por encima de barras adicionales ni de otros overlays. `AdjustTargetOfTargetFrame` se llama desde `RefreshFrame` junto a `AdjustTargetAuras` cuando `resourceCount > 2`; eleva el frame ToT en strata/level pero NO lo reposiciona fisicamente (intento de reposicion fisica fue descartado — ver enfoques fallidos). `RefreshTargetOfTargetNative` existe pero no se llama directamente — el portrait se actualiza desde `RefreshTargetOfTargetBars` al detectar cambio de GUID.
- ToT barras — arquitectura `totBarsOverlay`: `TargetFrameToTHealthBar` y `TargetFrameToTManaBar` son repintadas constantemente por Blizzard via `OnUpdate` de `TargetFrameToT` y `OnValueChanged` de cada barra (confirmado con `totspy`/`totscripts`). Cualquier escritura en barras nativas causa parpadeo. Solucion para barras/arte: frames parentes a **`UIParent` con `SetFrameStrata("MEDIUM")`** y niveles internos `82-84` (`artFrame`, health/mana frames, barras), cada uno con `SetAllPoints` a su pieza nativa (`TargetFrameToTHealthBar`, `TargetFrameToTManaBar`). Parental a `UIParent` es CRITICO para barras/arte: los overlays estaban antes como hijos de `TargetFrameToT` pero Epsilon no honra la jerarquia de strata para hijos de `TargetFrame`, por lo que los `barSlotOverlays` (MEDIUM strata, level 58) renderizaban encima aunque el ToT fuese HIGH strata level 120. Usar `MEDIUM`, no `HIGH` ni `DIALOG`: `HIGH/DIALOG` tapaban ventanas de otros addons y no es comportamiento nativo. Con UIParent/MEDIUM level 82+ queda por encima de barras extra Harford (`barSlotsFrame` aprox. level 58) pero por debajo de paneles addon normales con strata superior o niveles altos. El portrait es la excepcion: no necesita quedar por encima de barras extra y va hijo del ToT nativo. Cada frame de barra: fondo oscuro (`SetColorTexture 0.04,0.04,0.04,1`) + `StatusBar` con `TEX_STATUS`. Blizzard sigue pintando sus barras debajo — tapadas, invisibles. `ApplyNativeResourceBars` NO toca ninguna barra nativa del ToT. `UpdateToTBarsOverlay(list[1], list[2])` actualiza health+resource; `list[1].tempCur` (vida temporal) se aplica via `ApplyAbsorbTexture(EnsureNativeAbsorbTexture(ov.healthFrame.bar), ov.healthFrame.bar, cur, max, tempCur, 0.85)` sobre la barra de salud overlay — mismo patron que player/target/focus. Sin datos el health overlay se oculta y el mana overlay muestra fondo oscuro (valor 0). `UpdateFocusTotBarsOverlay` sigue el mismo patron para `focustarget`. `RefreshTargetOfTargetBars()` es la **fuente de verdad unica** para el estado del overlay ToT: (1) si no existe `targettarget`, resetea `targetOfTargetLastGUID` y llama `HideToTBarsOverlay()`; (2) si existe, actualiza portrait (solo si cambia GUID) y barras. Debe llamarse desde `RefreshFrame` en AMBOS branches (supported y !supported) para `unit == "target"`. En el branch `!supported`, llamar siempre `RefreshTargetOfTargetBars()`, **NUNCA** `HideToTBarsOverlay()` directamente: llamarlo directo no resetea `targetOfTargetLastGUID` y puede causar race condition donde el overlay recien mostrado en el branch `supported` queda oculto si `UnitIsSupportedPlayer` devuelve false momentaneamente durante transiciones de target. `HideToTBarsOverlay()` solo se llama desde dentro de `RefreshTargetOfTargetBars` y desde `RestoreNativeFrameContents("targettarget")`. Enfoques FALLIDOS en barras: `SetAlpha(0)` en barras nativas (Blizzard lo restaura via OnUpdate), escribir en barras nativas (idem), hijos de `TargetFrameToT` con frame level alto (Epsilon ignora cross-tree strata).
- ToT en modo recursos `"frame"`: el ToT debe quedarse original. `RefreshTargetOfTargetBars(forceVisual)` debe ocultar solo overlays de recursos/arte (`healthFrame`, `manaFrame`, `artFrame`) mediante `HideToTResourceOverlays()` y refrescar siempre `UpdateToTPortraitOverlay(GetProfile("targettarget"))`. Asi, si la opcion de retrato TRP3 cambia, el icono del ToT se actualiza aunque no cambie el GUID. No llamar `ApplyNativeResourceBars("targettarget")` ni `UpdateToTBarsOverlay` en este modo. En modo `"unitframe"`, pasar `forceVisual=true` fuerza tambien la reevaluacion del portrait aunque `targettarget` sea la misma unidad.
- **FocusFrameToT / `focustarget`**: sistema paralelo completo implementado. Estado en tabla `focusTot = {overlay, lastGUID, hooksInstalled}` (1 local de file-scope). Funciones encapsuladas en `do...end` para no consumir slots de local del scope global (el archivo roza el límite de 200 locales de Lua 5.1). Funciones públicas expuestas como `focusTot.hide()`, `focusTot.refresh(forceVisual)`, `focusTot.ensureHooks()`. El hook se instala para `FocusofTarget_Update` si existe (análogo a `TargetofTarget_Update`). `NativePiecesForUnit("focustarget")` usa root=`FocusFrameToT`, prefix=`"FocusFrameToT"`. `ApplyNativeResourceBars` excluye `focustarget` de escrituras en barras nativas igual que `targettarget`. Eventos cubiertos: `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UNIT_PORTRAIT_UPDATE`, `UNIT_NAME_UPDATE` con `unit=="focustarget"`; `UNIT_TARGET` con `unit=="focus"`. El portrait `FocusFrameToTPortrait` sigue el mismo patrón que el ToT: respeta `portrait_target_player`/`portrait_target_npc`, `SetAlpha(0)` inicial + `API._SyncToTNativePortraitAlpha(portraitNative, portraitOverlay)` llamado en cada hook de `FocusofTarget_Update` para reajustar el alpha según si el overlay de icono está visible. **CRÍTICO: `HideFocusTotBarsOverlay` debe resetear `focusTot.lastGUID = nil`** antes de ocultar, para que la próxima llamada a `UpdateFocusTotBarsOverlay` re-evalúe el portrait aunque el GUID no haya cambiado. Sin este reset, si Hide se llama cuando `tot:IsShown()` es transitoriamente false, el portrait nunca vuelve a mostrarse.
- Ciclo de vida `totBarsOverlay`: como los overlays son hijos de `UIParent`, no se ocultan automaticamente cuando `TargetFrameToT` se oculta. `EnsureToTBarsOverlay()` debe crear los frames ocultos y no llamar `Show()` por defecto. `UpdateToTPortraitOverlay()` y `UpdateToTBarsOverlay()` deben validar `UnitExists("targettarget")` y `TargetFrameToT:IsShown()` antes de mostrar nada. `EnsureTargetOfTargetHooks()` debe enganchar `TargetFrameToT:HookScript("OnHide", ...)` para resetear `targetOfTargetLastGUID` y llamar `HideToTBarsOverlay()`.
- Marco visual ToT (`artFrame`): `totBarsOverlay.artFrame` es también hijo de `UIParent`/MEDIUM (level **82**), por debajo de las barras overlay (83/84). **CRÍTICO: si `artFrame` tiene un level superior al de las barras, las tapa completamente (bug confirmado: artFrame a 503 tapaba todo).** El portrait overlay ya no comparte este árbol de niveles: va hijo del ToT nativo. `artFrame` clona en runtime solo la textura real `UI-TargetofTargetFrame` del hijo `TargetFrameToTTextureFrame` / `FocusFrameToTTextureFrame` usando bounds relativos. `CollectToTArtRegions` aplica tres filtros para evitar cuadrados falsos: (1) solo escanea `*TextureFrame`, no el root ni otros hijos; (2) `hasTex` check — `GetTexture() or GetAtlas()` debe ser no-nil; (3) path filter — solo texturas cuyo path/atlas contiene `ui-targetoftargetframe` o `targetoftargetframe`. Sin estos filtros se copian texturas vacías de los slots Debuff/Buff que producen cuadrados blancos. `UpdateToTArtOverlay(root, ov)` es genérico y acepta cualquier frame ToT como primer parámetro. Si el ToT se oculta o no existe `targettarget`, `artFrame` se oculta junto al resto.
- Cuadrados buff/debuff del ToT (`HideToTNativeExtras`): `TargetFrameToTBuff1..N` y `TargetFrameToTDebuff1..N` son hijos Frame del ToT. En Epsilon, `TargetofTarget_Update` puede hacerlos visibles según auras activas. Se ocultan con `HookScript("OnShow", function(self) self:Hide() end)` + `Hide()` — el HookScript garantiza que ninguna llamada futura de Blizzard los vuelva a mostrar. Esto es posible porque son objetos Frame (no Texture). Se llama una única vez en `EnsureToTBarsOverlay` / `EnsureFocusTotBarsOverlay`. Confirmado como solución a los cuatro cuadrados que aparecían junto al ToT.
- ToT portrait overlay (`totBarsOverlay.portraitFrame`): frame hijo de `TargetFrameToT` / `FocusFrameToT`, level local `tot:GetFrameLevel()+3`, `SetAllPoints(TargetFrameToTPortrait)` / `SetAllPoints(FocusFrameToTPortrait)`. No parentarlo a `UIParent` ni usar `TOT_PORTRAIT_LEVEL`: el icono solo debe sustituir el portrait nativo, no quedar por encima de barras adicionales o ventanas. En Epsilon `TargetFrameToTPortrait`/`FocusFrameToTPortrait` son `Texture`, no `Frame`; no se puede usar `HookScript("OnShow")` sobre ellos (solo funciona en objetos Frame, no en Texture). Textura `ptex` con **`SetTexCoord(0, 1, 0, 1)`** + mascara circular via `CreateMaskTexture`/`AddMaskTexture` con `TEX_PORTRAIT_MASK`. **CONFIRMADO: usar `SetTexCoord(0, 1, 0, 1)` para iconos de interfaz TRP3, NO `(0.08, 0.92, 0.08, 0.92)`**. El recorte 8% era convencion para retratos 3D de modelo WoW (que tienen borde transparente); los iconos de interfaz TRP3 (`Interface\\Icons\\...`) usan la textura completa y el recorte produce un zoom excesivo. Al aplicar un icono TRP3 sobre el portrait (en `UpdateToTPortraitOverlay`, `UpdateFocusTotPortraitOverlay`, overlays de unitframes), llamar siempre `ptex:SetTexCoord(0, 1, 0, 1)` después de `SetTexture`. **CRÍTICO: la máscara debe aplicarse a AMBAS texturas — `pbg:AddMaskTexture(mask)` Y `ptex:AddMaskTexture(mask)` — usando un único mask object con `mask:SetAllPoints(pf)` (frame completo). Si solo se aplica a `ptex`, el `pbg` queda cuadrado y se ve como borde negro/verde alrededor del icono circular.** El portrait nativo se sincroniza por alpha tras cada update: `API._SyncToTNativePortraitAlpha(portraitNative, portraitOverlay)` aplica alpha `0` si el overlay de icono está visible, alpha `1` si no. Esta función se llama desde el hook de `TargetofTarget_Update`/`FocusofTarget_Update` para contrarrestar la restauración constante de alpha que hace Blizzard a ~60fps. No intentar ocultarlo permanentemente con hooks de frame — `HookScript` no funciona en objetos Texture. `HideToTNativeExtras` (para buff/debuff slots, que SÍ son Frame) sí puede usar `HookScript("OnShow", hide)` porque esos hijos son objetos Frame, no Texture.
- Limitacion Epsilon confirmada: frames hijos de `TargetFrame` (incluyendo `TargetFrameToT` y sus hijos) NO respetan la jerarquia de strata de WoW respecto a frames de otros arboles. Un frame MEDIUM strata hijo de `UIParent` puede renderizar encima de un frame HIGH strata hijo de `TargetFrame`. Solucion: cualquier overlay Harford que deba estar encima de los `barSlotOverlays` debe ser hijo de `UIParent`, pero mantenerlo en `MEDIUM` con level controlado si es HUD/unitframe. `HIGH`/`DIALOG` quedan reservados para paneles/ventanas; no usarlos para ToT porque tapa addons. NO reparentar `TargetFrameToT` a `UIParent`: FrameXML espera que siga bajo `TargetFrame`.
- Diagnostico ToT: `NativePiecesForUnit("targettarget")` puede probar `TargetFrameToTHealthBar`/`TargetFrameToTManaBar`, campos internos `healthbar`/`manabar` y, si fallan, escanear hijos `StatusBar` del `TargetFrameToT`. Usar `/harford debug run totpieces` y `/harford debug run totwatch` antes de reactivar icono/nombre/nivel.
- Las barras extra (3+) usan el sistema `barSlotOverlays` para replicar el marco visual nativo de WoW. Cada barra extra recibe una textura independiente (`frame.barSlotOverlays[slot]`) anclada al `barSlotsFrame`, que recorta exactamente la zona UV del power bar slot en la textura del unitframe nativo. Esto hace que cada barra extra tenga el mismo borde dorado transparente que la barra de vida y maná, porque la textura tiene agujeros transparentes donde asoman las barras y borde dorado opaco alrededor. `ApplyBarSlotOverlays(frame, layout, list)` calcula los UV en runtime a partir de `layout.texture` y `layout.power`/`layout.health`; se llama al final de `RefreshResourceBars`. Si no hay barras extra, se ocultan todos los overlays via `HideAllBarSlotOverlays(frame)`.
- `frame.barSlotsFrame`: Frame hijo de `frame.visual` (NO de `overlayFrame`), siempre visible (no se oculta en el reset flow). Frame level `frame:GetFrameLevel() + 18`, por encima del `borderFrame` (level +4) y de las barras. Es el host de todas las texturas `barSlotOverlays`. Se crea en `CreateUnitFrame` y sus puntos se resincronizan en `ApplyMeasuredLayout`. Separarlo de `overlayFrame` es crítico: `overlayFrame:Hide()` se llama en el reset flow de `RefreshFrame` y nunca se re-muestra, por lo que cualquier textura hija de `overlayFrame` quedaría siempre oculta.
- UV de `ApplyBarSlotOverlays`: solo se usa el área horizontal de la barra (`power.x` a `power.x + power.width`), no el ancho completo del frame (`rel.width`). El área de portrait contiene pixels dorados opacos en la textura; incluir demasiados pinta artefactos del aro del retrato. El cálculo soporta `hRange` negativo (frame de jugador: `tcL=1.0 > tcR=0.09375`, textura reflejada). UV vertical: solo el slot del power bar (`power.y` a `power.y + power.height`) con pequeña expansión vertical.
- Expansión horizontal de `barSlotOverlays`: usar dos márgenes distintos. Lado del portrait = `BPH_PORTRAIT = 3`, suficiente para conservar el pequeño remate/rombo entre barras sin arrastrar el aro del icono; lado exterior = `BPH_OUTER = 5`, para conservar el borde decorativo derecho/izquierdo opuesto. Para `player`: `BPH_L=3`, `BPH_R=5`; para `target`: `BPH_L=5`, `BPH_R=3`.
- `GetOrCreateBarSlotOverlay(frame, slotIndex)`: crea la textura en `frame.barSlotsFrame or frame.overlayFrame`, strata OVERLAY sublevel 7. La textura se oculta hasta que `ApplyBarSlotOverlays` la posicione y muestre.
- `EnsureBar` (barras extra, índice ≥ 3): no crea ningún borde de color sólido. `container:SetAllPoints(borderFrame)` — ocupa todo el borderFrame. El overlay de textura del barSlotsFrame provee el borde visual. El `bg` de barras extra debe ser un fondo neutro/translúcido muy suave (`TEX_WHITE` negro, alpha aprox. `0.42`) para imitar el hueco sombreado del PlayerFrame/TargetFrame sin arrastrar texturas del portrait ni restos verdes/rojos del statusbar. `ApplyBarTextureInfo` debe aplicar este fondo para índices > 2. Jerarquía: `borderFrame` (Frame, level +4, hijo de `visual`) → `container` (Frame, `SetAllPoints`, level +5) → `bg` translúcido, `bar` (StatusBar, level +6), `textFrame` (Frame, level +22), `text` (FontString). Atajos: `bar.container = borderFrame`, `bar.innerContainer = container`, `borderFrame.bg = bg`, `borderFrame.textFrame = container.textFrame`.
- Enfoques que FALLARON y no deben reintentarse:
  - **Borde de color sólido** (1px oscuro, 2px dorado, 4 líneas doradas): rechazado por el usuario. "El borde no debería ser dorado, debería replicar el unitframe para obtener esos bordes de barras, es una textura no un borde simple." El `bg` semitransparente (alpha 0.82) hace que el color del borde sangre visualmente hacia el interior de la barra.
  - **`overlayFrame:Show()` para barSlotOverlays**: `frame.overlay` (artwork del frame WoW) es hijo de `overlayFrame`; mostrarlo duplica visualmente la carcasa nativa sobre la propia.
  - **`nativeTex:SetAlpha(0)`**: funciona para `TargetFrameTextureFrameTexture` pero NO para `PlayerFrameTexture` en Epsilon. Causa inconsistencia visual entre player y target. Revertido completamente.
  - **UV de ancho completo** (`rel.x=0`, tamaño `rel.width`): incluye el área del portrait (pixels dorados opacos en la textura), pintando fondo amarillo sobre las barras extra.
  - **`totBarsOverlay` como hijos de `TargetFrameToT`**: frame level +10 sobre barras nativas. Epsilon no honra strata cross-tree: `barSlotOverlays` (MEDIUM strata) renderizaban encima del ToT (HIGH strata) aunque el level absoluto fuese mayor. Solución correcta: UIParent/MEDIUM strata (ver `TOT_OVERLAY_STRATA`, niveles 82-85). HIGH y DIALOG también funcionan z-order pero tapan ventanas de otros addons; MEDIUM con niveles controlados es el equilibrio correcto.
  - **`totBarsOverlay` con UIParent/HIGH o UIParent/DIALOG**: tapan paneles/ventanas de otros addons. Desechado a favor de UIParent/MEDIUM.
  - **Reposicion fisica de `TargetFrameToT`** (mover por `extraHeight` sumando al anchor Y): intentado para esquivar el problema de strata. Resultado: el ToT queda en posicion incorrecta segun el usuario ("tendria que esta en su posicion de siempre"). Ademas, `TargetofTarget_Update` puede resetear los anchors entre ticks. No reparentar ni mover el `TargetFrameToT` — solo gestionar strata/level y cubrir con overlays UIParent/MEDIUM.
  - **`SetAlpha(0)` en barras nativas del ToT** (`TargetFrameToTHealthBar`/`TargetFrameToTManaBar`): `TargetofTarget_Update`/OnUpdate lo restaura continuamente (observado a ritmo de frame, ~60fps). Causa parpadeo constante.
  - **Hijos de `TargetFrameToT` para portrait overlay**: el portrait nativo renderiza en Epsilon encima de overlays del mismo arbol independientemente del frame level. Solucion: overlay UIParent/MEDIUM + sincronizar alpha de la `Texture` nativa tras `TargetofTarget_Update`/`FocusofTarget_Update` con `_SyncToTNativePortraitAlpha`.
  - **`HookScript("OnShow", hide)` sobre objetos `Texture`**: los objetos `Texture` en WoW/Epsilon no son `Frame` y no soportan `HookScript`. Solo funciona en objetos `Frame`. Para buff/debuff slots (`TargetFrameToTBuff1..4`, `Debuff1..4`) que SÍ son Frame, `HookScript("OnShow", function(self) self:Hide() end)` funciona correctamente. Para el portrait nativo (Texture), usar `SetAlpha(0)` + sync periódico.
  - **Clonar todas las regiones del ToT en `artFrame`**: fallido. Copia regiones de debuffs ocultos y/o root regions ambiguas (`TargetPortrait1`), creando cuadrados falsos y errores visuales de icono. Solo copiar `*ToTTextureFrame` con `hasTex` check y filtro de path.
  - **`artFrame` de ToT con level superior al de barras/portrait**: artFrame a level 503 (o cualquier valor > 82 en MEDIUM) tapa las barras overlay (83/84) y el portrait overlay (85). Confirmado bug: level 503 ocultaba todo el contenido del ToT. Mantener artFrame en level 82.
  - **Copiar textura nativa de barra compacta (`GetStatusBarTexture():GetTexture()`) en overlays de raid**: en Epsilon/SL las barras compactas pueden usar atlas; `GetTexture()` devuelve nil para atlas, dejando la barra invisible o negra. Alternativamente, la textura ya lleva color multiplicado y `SetStatusBarColor` sobre ella produce negro/rojo. Solución: `TEX_STATUS` + `SetStatusBarColor`.
  - **`TEX_WHITE + SetStatusBarColor` para barra de absorcion**: produce color solido plano sin textura visible (confirmado en Epsilon). Causa adicional: si `ownerWidth=0` en el momento de llamar a `UpdateDecor`, el pattern overlay calculado queda con `w=1px` e invisible. Solucion: usar `Interface\\RaidFrame\\Shield-Fill` directamente como `SetStatusBarTexture`; la textura se clipea internamente por valor sin necesitar `GetWidth()`.
  - **`fillTex:RIGHT` para posicionar el spark de absorcion**: `GetStatusBarTexture():GetRight()` en Epsilon devuelve siempre el borde derecho del frame completo porque la textura interna del StatusBar es de anchura 100% (el clip se hace por texcoords). No refleja el valor actual. Usar `frame:GetWidth() * pct` para centrar el spark justo sobre el final del fill. El offset fijo `+2` fue retirado como prueba porque desplaza el centro del borde a la derecha.
  - **`Shield-Overlay` tileada como textura de absorcion**: la textura tilea y produce huecos/costuras visibles en barras cortas. Textura correcta: `Interface\\RaidFrame\\Shield-Fill` (disenada para estirarse, no tilear).
  - **Anchor `LEFT` en lugar de `CENTER` para el spark de absorcion**: al cambiar de anchor `CENTER` al borde de relleno a anchor `LEFT`, el spark se desplaza media anchura del spark hacia la derecha. Siempre usar `CENTER` para que el pivot sea el punto medio del spark.
  - **`OnSizeChanged` no hookeado en nameplates**: los nameplates Kui y nativos WoW se redimensionan al seleccionar/deseleccionar; sin hook `OnSizeChanged` en `healthBar`, la posicion del spark queda obsoleta. Hookear con guard `npState[unit]` para evitar re-aplicar sobre nameplates reciclados con unidad antigua.
  - **`nameFrame` anclado a `kui.NameText` con `SetAllPoints`**: los bounds de un FontString en Kui pueden ser el ancho completo del nameplate (no el area visible del texto). Crear un Frame con `SetAllPoints(nt)` produce un overlay enorme que tapa todo el nameplate. Enfoque tambien rechazado: ocultar `kui.NameText` y depender de un FontString propio; en Kui puede quedar invisible. Solucion actual: escribir el nombre TRP3 en `kui.NameText` real y mantenerlo visible.
  - **Pasar token `nameplateN` directamente a `register.getUnitRPName`**: TRP3 puede no soportar tokens de nameplate en versiones antiguas. Usar siempre `HarfordTRP3.BuildUnitID(unit)` como intermediario, o `HarfordTRP3.GetPlayerProfile(unit)` que ya llama a `BuildUnitID`. Leer nombre del perfil desde `characteristics.FN`+`LN`.
  - **FontString sin `SetFont` en tiempo de creacion**: un FontString creado con `CreateFontString` sin llamar a `SetFont` o `SetFontObject` no renderiza texto aunque se llame `SetText` y `Show`. Establecer siempre una fuente por defecto en el momento de creacion; sobreescribir con la fuente del elemento nativo (p.ej. `nt:GetFont()`) en runtime si se desea coincidencia visual.
  - **Plugin Kui registrado en tiempo de carga del TOC**: si Kui se inicializa despues de HarfordNamePlates (posible segun orden de carga), `KuiNameplates.NewPlugin` puede no existir todavia. Diferir `TryRegisterKuiPlugin()` a `PLAYER_LOGIN` cuando todos los addons estan cargados.
  - **`WHITE8X8` como textura de barra de raid**: produce barras planas sin textura, aspecto demasiado "moderno" y vacío. Rechazado por el usuario. Usar `TEX_STATUS`.
  - **`nativeTex:SetAlpha(0)` en barras compactas de raid**: no probado pero análogo al caso ToT — `OnValueChanged` puede restaurarlo. No usar; usar overlays propios que tapan la barra nativa.
- El fondo de barra debe intentar copiar textura/atlas/texcoords desde regiones nativas `BACKGROUND` o desde la textura interna del statusbar medido, pero el color del fondo debe forzarse a oscuro/neutro. No heredar `vertexColor` nativo para el fondo, porque puede aparecer como restos verdes/rojos al final de la barra.
- Recursos extra se apilan debajo de la segunda barra usando el alto real medido y expanden el alto del frame Harford. El primer recurso extra (indice 3) se ancla a `power.y + power.height + BAR_GAP` desde el top del frame visual; los siguientes se anclan al `TOPLEFT` del container anterior con offset `-(barH + BAR_GAP)`.
- Cada barra extra usa una jerarquía de dos frames: `borderFrame` (exterior, sin color propio — el borde visual viene del overlay de textura del `barSlotsFrame`) → `container` (interior, `SetAllPoints(borderFrame)`, sin inset). El `StatusBar` y el `textFrame` viven dentro de `container`. `bar.container = borderFrame` (para posicionamiento y show/hide externo); `bar.innerContainer = container` (para bg, mouse, text). `borderFrame.bg` y `borderFrame.textFrame` son shortcuts para que el código externo acceda via `bar.container.bg` etc. No usar `BackdropTemplate` ni `UI-Tooltip-Border` ni ningún `SetColorTexture`/`borderBg` propio: el marco correcto es la textura del unitframe nativo recortada por UV.
- Al ocultar `bar.container` (borderFrame), los hijos se ocultan automaticamente por propagacion padre-hijo de WoW. No hace falta ocultar `container.borderFrame` por separado — ya no existe esa estructura.
- `frame.maxBarIndex` rastrea el indice mas alto de barra extra creado. La limpieza de barras al cambiar de target itera de `max(#list, 2)+1` hasta `frame.maxBarIndex`, no con `#frame.bars` (que es indefinido en Lua cuando hay huecos en el array porque los indices 1 y 2 nunca se crean).
- **Auras del `TargetFrame`/`FocusFrame` con barras extra — RE-ANCLAJE (no shift)**: cuando la unidad tiene mas de dos barras de recurso (`frame.resourceCount > 2`), `ReanchorAurasBelowBars(frame, unit)` recoloca las auras en orden **buffs → debuffs** bajo la ultima barra: `*FrameBuff1` ancla `TOPLEFT` a la **ultima barra de recurso** (`frame.bars[resourceCount].container`) `BOTTOMLEFT`, y `*FrameDebuff1` ancla bajo el **contenedor de buffs** (`*FrameBuffs` `BOTTOMLEFT`); los demas iconos y los contenedores heredan la cadena nativa. En este cliente el orden NATIVO es el inverso (`Debuff1 → TargetFrame`, `Buff1 → TargetFrameDebuffs`), por eso hay que invertirlo explicitamente. El re-anclaje es **idempotente** (ancla a referencias absolutas: la barra y el contenedor de buffs), asi que reaplicarlo NO acumula desplazamiento → **sin drift** (ya no se usa el shift por `extraResourceHeight` ni `ShiftAuraFrame`/`NormalizeDebuffGap`, eliminados). Se reaplica DESPUES de que Blizzard recoloque, via `hooksecurefunc("TargetFrame_UpdateAuras")` (generico: distingue target/focus por `self == _G.TargetFrame`/`_G.FocusFrame`) ademas del flujo `RefreshFrame`/`UNIT_AURA`. Sin el hook, cada actualizacion nativa de auras devolvia los iconos a su sitio ("se actualiza al refrescar"). Con `resourceCount <= 2` o al cambiar `UnitGUID(unit)`, `RestoreUnitAuras(unit)` devuelve las auras a la posicion nativa (cache de puntos guardado con `SaveAuraPoints`, separado por unidad `target`/`focus`). Nombres: `_G.TargetFrameBuff1`/`_G.TargetFrameDebuff1`/`_G.TargetFrameBuffs` (y `FocusFrame*`).
- **Bug de drift de buff frames (historico)**: el enfoque viejo (shift incremental sobre el cache) acumulaba offset en cada `UNIT_AURA` hasta "congelar" los iconos si se limpiaba el cache sin restaurar primero. El re-anclaje idempotente actual lo evita por diseño. Se conserva la regla para el path de restauracion (`resourceCount<=2`/cambio de GUID): restaurar SIEMPRE a nativo ANTES de limpiar el cache (`RestoreUnitAuras(unit)`), nunca limpiar sin restaurar.
- No reparentar `TargetFrameToT` a `UIParent`: FrameXML espera que siga bajo `TargetFrame` y puede romper `TargetFrame_UpdateAuras` con `UnitIsUnit(nil, ...)`. La solucion al z-order es hacer los overlays Harford hijos de `UIParent` con `MEDIUM` strata y niveles controlados, no mover el frame nativo. Si se ajusta strata/level del ToT, hacerlo sin `C_Timer.After(0)` ni ticker continuo.
- El nombre usa bounds reales del texto nativo si existen; si no, se deriva de la barra de vida. Debe tener fondo negro semitransparente para recuperar el fondo detras del nombre.
- El portrait TRP3 debe usar mascara circular si el cliente soporta `Texture:AddMaskTexture`, con `Interface\\CharacterFrame\\TempPortraitAlphaMask`; si no, usar portrait ligeramente reducido y centrado bajo el aro.
- Cualquier fondo protector de portrait debe estar tambien enmascarado o venir de una textura nativa; no usar fondos cuadrados opacos detras de `player` ni `target`.
- No clonar regiones del frame nativo ni anclar barras/portrait a hijos dinamicos: se cuelan overlays como raid markers, threat, class power o efectos.
- La prioridad es estabilidad visual y ausencia de piezas nativas filtradas (combo/class power), usando el asset SL/Epsilon real del cliente.
- Referencias de recreacion visual:
  - `SecureUnitButtonTemplate` es la base adecuada para unitframes clicables.
  - Los frames Blizzard pueden reaparecer por eventos si solo se usa `:Hide()`; si se ocultan, revalidar/rehacer en eventos relevantes y restaurar para NPC.
  - Para estilo Shadowlands/clasico, usar `Interface\\TargetingFrame\\UI-TargetingFrame` y `Interface\\TargetingFrame\\UI-StatusBar`.
- No intentar usar una textura completa `UI-TargetingFrame` con coordenadas inventadas como fuente primaria; medir el frame Blizzard real y usar fallbacks solo si falta una pieza nativa.
- Si el target no es jugador (`UnitIsSupportedPlayer` devuelve false), `HarfordUnitFrames` restaura el `TargetFrame` original de WoW y llama a `RefreshNpcTargetPortrait()`. Esta funcion lee `HarfordConfig.Get("portrait_target_npc")`: si es `"trp3"`, obtiene el perfil via `HarfordTRP3.GetEpsilonNpcProfile("target")` (companions register) y aplica el icono sobre `TargetFramePortrait`; si es `"wow"` o no hay perfil, llama a `SetPortraitTexture`. El frame overlay de Harford NO se activa para NPCs: solo se toca el retrato nativo.
- La seleccion de clave de config de retrato usa `GetPortraitCfgKey(unit)`: `"player"` → `portrait_player`; `"target"` + `UnitIsPlayer` → `portrait_target_player`; `"target"` + NPC → `portrait_target_npc`.
- Cuando `HarfordConfig.Get("resources") == "frame"`, el frame overlay de Harford se desactiva para AMBAS unidades (player y target): se restauran los unitframes nativos de WoW. El target resource frame flotante (`HarfordDnDTargetResourceFrame`) es gestionado por `HarfordDnD` segun la misma clave.
- La integracion de grupo/raid tambien depende de `HarfordConfig.Get("resources") == "unitframe"`. Si el modo es `"frame"`, no se toca party/raid: se ocultan los overlays Harford y los frames Blizzard/compactos quedan intactos.
- Party/raid no deben escribir valores/colores Harford directamente en `healthBar`/`powerBar` nativos. El enfoque confirmado es overlay: crear barras Harford sin mouse encima de las barras compactas nativas y ocultarlas en modo `"frame"`. Motivo: escribir en barras compactas nativas deja estados contaminados (rojo/negro) al alternar entre integrado y frame separado.
- En overlays de party/raid no copiar `nativeBar:GetStatusBarTexture()` al `StatusBar` Harford. En Epsilon/SL puede devolver atlas/texturas ya coloreadas o con material no neutro; al multiplicarlo con `SetStatusBarColor` produce barras negras/rojas o nil en textura atlas. **Solución confirmada**: usar `TEX_STATUS` ("Interface\\TargetingFrame\\UI-StatusBar") directamente en `CreateOverlayBar` y en `ApplyGroupOverlayBar`, y pintar encima con `SetStatusBarColor(r, g, b, 0.95)`. Esta textura es neutra y produce el color plano correcto al multiplicarse con `SetStatusBarColor`. Alpha 0.95 es el valor probado. No usar `WHITE8X8` (aspecto demasiado plano/sin textura, rechazado); no copiar textura nativa (atlas devuelve nil); no usar alpha < 0.9 (se transparenta y se mezcla con el fondo compacto).
- En overlays de party/raid usar `SetIgnoreParentAlpha(true)` en overlay/containers/bar/textFrame cuando exista. Motivo: Blizzard puede poner alpha bajo al compact frame si el jugador esta lejos/fuera de phase; si el overlay hereda alpha se ven las barras nativas debajo. Mantener `bg` opaco para tapar la barra nativa y aplicar el alpha del compact frame solo al fill/texto/absorcion para conservar el feedback visual.
- Vida temporal en party/raid: `container.tempBar` es un `StatusBar` con textura `TEX_ABSORB_FILL` (`Interface\\RaidFrame\\Shield-Fill`), color `(0.35, 0.82, 1.00, 1.0)` y `SetAllPoints(bar)`, creado en `CreateOverlayBar` sin offset fijo. En `ApplyGroupOverlayBar` cuando `isHealth` y `data.tempCur > 0`, se marca `container.tempBar._harfordGroupAbsorb = true` solo si `IsRaidCompactFrame(frame, unit)` devuelve true; party queda sin flag. Luego se llama `ApplyAbsorbTexture(container.tempBar, container.bar, cur, max, tempCur, 0.85 * stateAlpha)`, que aplica `Shield-Fill` como textura de StatusBar + spark de borde sobre el `tempBar`. El `data.tempCur` se inyecta en `list[1]` leyendo `resources["Res_temp_health_Cur"]` antes de llamar a `ApplyGroupOverlayBar`. No usar en power bar. El mismo mecanismo `ApplyAbsorbTexture` se usa en unitframes principales (sobre nativeBar), party/raid (sobre `container.tempBar`) y nameplates (sobre `ov.tempBar`), pero el offset del spark NO es global: unitframes/nameplates/party usan `realW*pct`/`absorbWidth`; raid conserva `realW*pct + 2` porque fue el unico caso que quedaba descentrado tras quitar el `+2` global. **Textura correcta confirmada: `Interface\\RaidFrame\\Shield-Fill`** (textura Blizzard de relleno de absorción, se estira; NO usar `Shield-Overlay` que tilea y produce huecos visibles). Para StatusBar de absorción: usar la textura directamente como `SetStatusBarTexture` con `SetHorizTile(false)` + `SetVertTile(false)`. Para Kui nameplates, usar `Kui_Media\\t\\stippled-bar` con `SetHorizTile(true)` (sí tilea). No usar `TEX_WHITE + SetStatusBarColor` para absorción: produce color sólido plano sin textura.
- Jugadores desconectados en compact frames: si `UnitIsConnected(unit) == false`, ocultar overlay Harford y restaurar portrait compacto nativo para que Blizzard muestre el icono de estado/desconexion sin solaparse con nivel, retrato o barras Harford.
- La deteccion de party/raid debe soportar tanto globals clasicos (`PartyMemberFrame1..4`) como frames compactos dentro de `CompactPartyFrame`, `CompactRaidFrameContainer`, `CompactRaidGroup*` y tablas internas tipo `memberUnitFrames`/`unitFrames`. En `GROUP_ROSTER_UPDATE` hacer refresco inmediato y diferido corto, porque algunos frames compactos se construyen despues del evento.
- La via principal para party/raid debe ser `hooksecurefunc` sobre `CompactUnitFrame_UpdateAll`, `CompactUnitFrame_UpdateHealth`, `CompactUnitFrame_UpdatePower` y `DefaultCompactUnitFrameSetup`: aplicar Harford justo despues de que Blizzard actualice cada `CompactUnitFrame`. Esto evita depender de nombres concretos y evita escanear `UIParent`, que puede producir taint con objetos protegidos.
- No recorrer `UIParent:GetChildren()` buscando frames compactos: en el cliente Epsilon/SL puede lanzar `Attempt to access forbidden object from code tainted by an AddOn`.
- Los overlays de party/raid deben ser hijos sin mouse del compact frame, anclados a las barras nativas medidas (`healthBar`/`powerBar`). No reparentar, ocultar ni sustituir el compact frame nativo; si un frame no expone barras o no tiene unidad WoW valida, no se modifica.
- `GetOrCreateGroupOverlay(frame)` no debe crear frames nuevos en combate (`InCombatLockdown`); si el overlay aun no existe, devolver `nil` y esperar al siguiente refresh fuera de combate.
- Los overlays de party/raid NO deben vivir en un frame level alto global tipo `frameLevel + 25`: eso tapa el nombre y capas internas del compact frame. El overlay host debe quedar cerca del compact frame (`+2`) y cada barra debe posicionarse justo por encima de su barra nativa (`nativeBar:GetFrameLevel() + 1`) para que los textos/iconos nativos sigan ganando la capa cuando corresponda.
- En overlays de party/raid, el texto no puede ser un FontString directo del mismo contenedor que aloja el `StatusBar`: el `StatusBar` es un frame hijo y puede dibujarse encima. Usar `textFrame` con frame level mayor que la barra (`container + 3`) y crear el FontString dentro. Como la barra de salud compacta puede ocupar tambien la zona del nombre, replicar el nombre en `overlay.nameFrame`, copiando bounds/color del nombre nativo si existe.
- `ApplyCompactHealthClassColor(frame)` no toca la barra nativa: solo refresca el overlay de salud si existe `overlay.healthData`. El color de clase de raid/grupo es color del overlay, no del `healthBar` Blizzard.
- Al limpiar party/raid al cambiar a modo `"frame"`, ocultar `groupOverlays`, limpiar `healthData`/`powerData`, ocultar `overlay.nameFrame`, restaurar textos nativos y retratos compactos, y usar `restoringCompactFrames` para que los hooks Harford sean no-op mientras Blizzard repinta. Evitar tocar valor/color de barras nativas.
- Antes de modificar retratos compactos, guardar snapshot ligero (`textura/texcoords/alpha/shown`) y restaurarlo al cambiar a modo `"frame"`. Para barras compactas, evitar snapshots de `min/max/value/color`: no deben tocarse en flujo normal. `compactBarState` queda como compatibilidad de limpieza para versiones anteriores.
- Al restaurar compact frames, no limitarse a frames encontrados en `CollectAllGroupFrames()`: tambien iterar directamente `compactBarState` y `compactPortraitState`, porque Blizzard puede cambiar la coleccion visible entre el momento de modificacion y el cambio de modo.
- Si existe `compactBarState` de una version anterior, debe guardar el `compactFrame` propietario. Al restaurar una barra compacta legacy, limpiar marcas Harford y pedir `CompactUnitFrame_UpdateAll(compactFrame)` / `CompactUnitFrame_UpdateHealthColor(compactFrame)` si existen. No volver a restaurar valor/color desde snapshots.
- La restauracion final al modo `"frame"` debe dejar que Blizzard repinte sus compact frames: usar una bandera de supresion (`restoringCompactFrames`) para que los hooks Harford sean no-op y llamar `CompactUnitFrame_UpdateAll(frame)` solo sobre frames compactos visibles y con unidad valida. Hacer tambien repintados diferidos cortos para frames que Blizzard reconfigure despues del cambio. No usar esto para escribir colores/valores Harford.
- Los hooks de `CompactUnitFrame` tambien pueden dispararse desde sistemas que no son party/raid, por ejemplo nameplates (`Blizzard_NamePlates`). `ShouldHandleCompactUnitFrame` debe limitarse estrictamente a `player`, `partyN` y `raidN`; no tocar `nameplateN`, `focus`, `mouseover` ni otros tokens aunque `UnitIsPlayer` sea true.
- En modo `"frame"`, si el cliente deja `PartyMemberFrame1..4` clasicos visibles estando en raid o sin `UnitExists("partyN")`, ocultarlos con cuidado fuera de combate. En raid, la interfaz original no debe mostrar party frames clasicos.
- Los hooks de hover de barras nativas deben no-op si `_harfordShortText` y `_harfordFullText` ya estan limpios. Si no, un `OnLeave` posterior puede ocultar texto nativo despues de volver a modo `"frame"`.
- Grupo/raid muestran recursos Harford cacheados por nombre de unidad y solicitan recursos remotos con throttle si faltan. Actualmente dibujan como maximo dos overlays: salud y primer recurso adicional disponible. Las barras nativas quedan debajo e intactas.
- En Epsilon/SL, el color de clase de raid/compact frames solo debe aplicarse si la opcion Blizzard `Display Class Colors` esta activa. No confiar solo en el CVar `raidFramesDisplayClassColor`: en este cliente puede no reflejar el perfil visual activo. La fuente primaria debe ser `frame.optionTable.useClassColors`; despues `frame.optionTable.displayClassColor` si existe; despues `GetRaidProfileOption(GetActiveRaidProfile(), "useClassColors")`; despues `"displayClassColor"`; y solo como ultimo fallback el CVar.
- Cuando `Display Class Colors` esta activa, Harford toma la clase desde la ficha TRP3 (`HarfordTRP3.GetProfilePrimaryClass`) y cae a cache/`UnitClass` si falta perfil. Cuando esta desactivada, la barra de salud debe conservar el color normal del recurso/vida, no forzar clase.
- `HarfordTRP3.GetProfilePrimaryClass` debe parsear el About crudo antes de `ConvertTRP3Markup`; si se parsea el texto ya convertido a WoW markup, los tags de color/icono pueden impedir detectar correctamente `Clase (nivel)`.
- Si la linea de clase del About incluye `{icon:classicon_<clase>:...}`, usar ese token como pista primaria de clase y elegir siempre la linea con mayor nivel. Esto evita fallos por acentos, traducciones o subclases como `Picaro Forajido (3)`.
- Para color/clase Harford, las lineas de clase DnD del About tienen prioridad sobre campos TRP3 estructurados como `characteristics.CL`. Motivo: `characteristics.CL` puede contener la clase WoW/base del personaje (`Picaro`) mientras la ficha Harford multiclase debe elegir la clase con mayor nivel (`Paladin (6)` sobre `Picaro (3)`).
- `HarfordUnitFrames` mantiene cache de color de clase por nombre de unidad. Si TRP3 no devuelve perfil para `raidN` pero ya se aprendio la clase al targetear/ver al jugador, raid puede reutilizar ese color cacheado. Si tampoco hay cache, caer a `UnitClass(unit)` para no dejar la barra verde generica; TRP3/cache siguen teniendo prioridad sobre la clase WoW normal.
- En compact/raid frames, Blizzard repinta el color de vida desde `CompactUnitFrame_UpdateHealthColor`; Harford puede post-hookear esa funcion solo para refrescar el overlay Harford, no para tocar la barra nativa. Para diagnostico, `/harford debug run groupframes` debe mostrar clase resuelta, color esperado y color real de la barra nativa.
- Para mover el texto de salud cuando hay Power Bars, aplicar offset vertical solo a unidades `raidN`, nunca a `partyN`. Inferir Power Bars desde el propio frame (`FindGroupPowerBar(frame):IsShown()`), no solo desde CVar. Si la powerBar compacta de raid esta visible, bajar ligeramente el texto para evitar solape con el nombre del jugador. En party/grupo el texto debe quedarse centrado sin offset.
- En raid/compact frames, si `resources == "unitframe"` y `statusTextDisplay` esta en `NONE`, el texto Harford no debe mostrarse fijo: debe aparecer solo en hover mediante `OnEnter` y ocultarse/restaurarse en `OnLeave`. Si el CVar esta en `NUMERIC/PERCENT/BOTH`, mostrar el texto corto fijo.
- Comportamiento de hover segun tipo de frame (implementado en `SetCompactFrameHoverState` + `SetGroupOverlayText`):
  - **Party/group**: si el modo texto es `NUMERIC/PERCENT/BOTH`, el hover es no-op completo (no llama a `SetCompactBarHoverText` ni `RefreshGroupOverlayTexts`). Motivo: ya hay texto visible y activar hover causaria parpadeo. Solo actua cuando el modo es `NONE`. El texto de hover muestra valor corto sin nombre de recurso (`cur/max`).
  - **Raid**: el hover siempre actua independientemente del modo texto activo. `IsRaidCompactFrame(frame, nil)` determina el tipo. Con texto activo y hover, `SetGroupOverlayText` muestra `fullText` (etiqueta + valores) en lugar del `shortText` fijo; sin hover muestra `shortText`.
- Grupo/raid usan la misma opcion de retrato que target jugador: si `portrait_target_player == "trp3"`, intentar aplicar `HarfordTRP3.GetProfileIcon(profile)` sobre el portrait/icon nativo del `CompactUnitFrame`; si es `"wow"`, restaurar retrato WoW con `SetPortraitTexture(portrait, unit)`. Buscar portrait en `frame.portrait`, `frame.Portrait`, `frame.icon`, `frame.Icon` o globals derivados del nombre. No crear portrait propio para party/raid.
- En compact frames de party/raid no usar `IsMouseOver()` durante updates de `CompactUnitFrame`: puede fallar con `Action[FrameMeasurement] failed because[Can't measure restricted regions]` en frames protegidos. El hover debe hacerse con `HookScript("OnEnter"/"OnLeave")`, mostrando `_harfordFullText` al entrar y restaurando `_harfordShortText` al salir.
- En compact frames, el hover es un unico estado del frame padre (`_harfordHovering`), aunque el evento llegue desde el `CompactUnitFrame`, `healthBar` o `powerBar`. Todos esos hooks deben llamar al mismo handler (`CompactHoverEnter/CompactHoverLeave`) para evitar dobles hovers donde una barra no muestre salud.
- El `OnLeave` de compact frames debe limpiar con un pequeno delay/token, no inmediatamente. Esto evita parpadeos al mover el cursor entre el frame padre y barras internas sin usar `IsMouseOver()`.
- Si Blizzard reescribe el compact frame durante hover, el overlay debe respetar `_harfordHovering` y volver a poner `_harfordFullText`; si no, el texto aparece un instante, parpadea y desaparece.
- `CompactUnitFrame_OnEnter/OnLeave` y `TextStatusBar_UpdateTextString*` pueden re-mostrar textos nativos de barras compactas mientras el raton esta encima. Marcar barras gestionadas con `_harfordCompactManaged` y post-hookear `TextStatusBar_UpdateTextString` / `TextStatusBar_UpdateTextStringWithValues` solo para suprimir esas barras marcadas. No tocar barras no gestionadas.
- `CompactUnitFrame_UpdateInRange` se puede hookear para sincronizar alpha de overlays con el alpha que Blizzard aplica por rango/phase. No usarlo para reconstruir todo el frame.
- Los eventos de grupo/raid son event-driven: `GROUP_ROSTER_UPDATE`, `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UNIT_NAME_UPDATE`, `UNIT_PORTRAIT_UPDATE`, `CHAT_MSG_ADDON` y cambios de config. No usar ticker continuo para party/raid.
- Al entrar en modo `"frame"`, `HarfordUnitFrames` debe deshacer efectos del modo integrado para player y target: restaurar frame nativo, nivel/textos de barras, class/combo widgets ocultos y esconder todas las piezas Harford (`portraitLayer`, barras extra, nativeTexts, fallback, level/name overlays). Despues de restaurar, puede aplicar solo el retrato nativo/TRP3 con `ApplyNativePortraitOption(unit)` segun las opciones de retrato. `ReapplyNativeBars` y los hooks de power/text deben ser no-op en modo `"frame"`.
- Tras `RestoreNativeFrameContents(unit)` en modo `"frame"`, llamar a funciones FrameXML nativas cuando existan (`PlayerFrame_Update`, `TargetFrame_Update`, `UnitFrameHealthBar_Update`, `UnitFrameManaBar_Update`, `TextStatusBar_UpdateTextString`) y despues reconstruir health/power desde `UnitHealth`, `UnitHealthMax`, `UnitPower`, `UnitPowerMax` y `PowerBarColor`. Restaurar alpha/textos no basta: las barras pueden quedarse con min/max/value/color de Harford hasta que Blizzard repinte.
- En party/raid, no restaurar valor/color desde `compactBarState`: ese snapshot puede estar contaminado por Harford o por el estado pendiente negro. `RestoreGroupNativeBar` solo existe como limpieza legacy; el flujo normal ya no debe poblar `compactBarState`.
- `/harford debug run groupframes` debe incluir `barColor`, `texColor` y `value/min-max` de la barra de salud para distinguir si el fallo de raid viene de color, textura interna o rango/valor.
- Expone `HarfordUnitFrames.GetFrame(unit)` para que `HarfordAdminUnitMenu` pueda anclarse al frame Harford en lugar del frame nativo oculto.
- Si no hay recursos cacheados para un jugador remoto en `player`/`target`/`focus`, no dejar las barras Blizzard con su valor nativo porque al cambiar target pueden verse llenas hasta que llegue `RES`. En modo unitframe integrado, las barras nativas controladas por Harford deben ponerse en estado pendiente: `0/1`, valor `0`, sin texto, salud verde oscura y recurso/fondo oscuro. No pintar `PG --/--   PM --/--`: el fallback textual dentro de barras genera ruido visual. Para party/raid, no tocar la barra nativa: ocultar/no crear overlay si falta informacion suficiente.
- La primera barra de recurso del target usa la barra nativa de power/mana (`TargetFrameManaBar`) y Blizzard puede repintarla despues de `PLAYER_TARGET_CHANGED` con power/numeros normales. Harford debe post-hookear los caminos de power/text (`TargetFrame_Update`, `TargetFrame_UpdatePower`, `UnitFrameManaBar_Update`, `TextStatusBar_UpdateTextString*` cuando afecten a `TargetFrameManaBar`) y llamar `ReapplyNativeBars("target")` para reaplicar inmediatamente el estado Harford o pendiente, incluido ocultar `TextString`/`LeftText`/`RightText`. `ApplyNativeStatusBar`/`ApplyPendingNativeStatusBar` marcan `_harfordApplying` mientras escriben `SetValue` para evitar bucles con `OnValueChanged`. **Hot-path (rendimiento)**: los hooks de `TextStatusBar_UpdateTextString*` corren para CADA barra de estado de toda la UI (player/target/focus/party/raid/nameplates) en cada repintado — extremadamente frecuente. Su filtro debe ser una comparacion de referencias BARATA (`statusFrame == targetPower` con el `targetPower` cacheado en `InstallNativePowerHooks` + `_G.TargetFrameManaBar`), NUNCA `NativePiecesForUnit("target").power`, que aloca una tabla y escanea `FieldPath` en cada llamada. El supresor de texto compacto (`SuppressCompactBarText`) ya es barato: solo actua si `statusFrame._harfordCompactManaged`. **Cache de pieces nativos**: `NativePiecesForUnit(unit)` cachea el resultado para `player`/`target`/`focus` (sus frames y barras nativas son ESTABLES en la sesion; cambiar de target reusa `TargetFrame`), evitando alocar tabla + escanear `FieldPath` en cada una de sus ~11 llamadas (`ReapplyNativeBars` corre por cada `UNIT_HEALTH/POWER`). `BuildNativePieces` es el builder SIN cache — no llamarlo directo. `targettarget`/`focustarget` NO se cachean (barras mas dinamicas). Se invalida con `InvalidateNativePiecesCache()` en `PLAYER_ENTERING_WORLD`/`PLAYER_LOGIN` (recreacion de frames/reload). Los callers solo LEEN la tabla (no mutar).
- Para `target` jugador, si no hay recursos en cache, pide recursos con `HarfordDnDAPI.RequestResourcesForName` con throttle interno.
- El texto de cada barra debe ocupar todo el contenedor de barra (`SetAllPoints`, `CENTER`, `MIDDLE`) y vivir en una capa superior al `StatusBar`, para quedar centrado y visible siempre.
- Las barras tienen dos estados de texto segun el CVar `statusTextDisplay` (via `GetStatusTextMode()`):
  - **NUMERIC/PERCENT/BOTH**: texto corto siempre visible (solo valores: `cur/max`, `pct%`, `cur/max (pct%)`). En hover cambia al texto completo con el nombre del recurso DnD (`Salud cur/max`, etc.).
  - **NONE**: sin texto por defecto. En hover muestra el texto completo con nombre y valores numericos.
- Dos funciones de formato: `FormatShortText(cur, max, tempCur)` (valores sin nombre, para estado normal) y `FormatFullText(label, cur, max, tempCur)` (nombre + valores, para hover). Ambas aceptan `tempCur` opcional: si `tempCur > 0`, insertan `+tempCur` pegado al valor actual sin espacio (`cur+tempCur/max`, e.g. `45+10/100`). Si `tempCur` es `nil` o `0`, no añaden el `+`. Hay **4 call sites** que deben pasar `tempCur`: `SetGroupOverlayText`, `ApplyNativeResourceText`, el loop en `RefreshResourceBars` y la función de re-apply de texto de barras 1-2. `FormatBarText` fue eliminada.
- Para barras 1-2: `HookScript("OnEnter"/"OnLeave")` sobre la barra nativa (una vez, `_harfordHooked`). El hook lee `_harfordFullText` en Enter y `_harfordShortText` en Leave. `ReapplyNativeBars` (UNIT_HEALTH/UNIT_POWER_UPDATE) comprueba `IsMouseOver()` para aplicar el texto correcto sin interrumpir el estado de hover activo.
- Para barras 3+: `OnEnter` muestra `_harfordFullText`, `OnLeave` restaura `_harfordShortText` (o oculta si NONE). No existe `ShouldShowBarText()` — fue eliminada.
- Se refresca por eventos (`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_TARGET_CHANGED`, `UNIT_PORTRAIT_UPDATE`, `UNIT_NAME_UPDATE`, `UNIT_AURA`, `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED`, `CHAT_MSG_ADDON`, `CVAR_UPDATE`) y cuando `HarfordDnD` refresca o cambia recursos. `CVAR_UPDATE` solo dispara cuando el cvar es `statusTextDisplay`. `UNIT_HEALTH` y `UNIT_POWER_UPDATE` llaman solo a `ReapplyNativeBars(unit)` (re-aplica fill/color de barra + texto en `nativeBar.TextString` sin reconstruir el frame completo; necesario porque Blizzard resetea estos valores en UNIT_POWER_UPDATE) y retornan inmediatamente. El resto de eventos llaman a `API.Refresh(forceMeasure)`.
- Recalibrar con `force=true` en login/world/target/escala/resolucion para recoger cambios de posicion, escala o layout.
- Vida temporal en group overlays: ver descripcion en el punto de "Vida temporal en party/raid" del bloque de contratos. `ApplyCompactStateAlpha` sincroniza `tempBar:SetAlpha(0.85 * stateAlpha)` cuando esta visible. `temp_health` no esta en `HarfordDnDResources.ORDER`; su unico canal visual son los overlays de absorcion. El `tempBar` actua solo sobre la health bar, nunca sobre la power bar.
- Debug secundario:
  - `/harford debug run ufmeasure player|target|focus`: imprime el layout calculado, piezas nativas detectadas y texturas de fondo/relleno usadas.
  - `/harford debug run ufcompare player|target|focus`: compara bounds Harford contra la medicion y muestra frame levels de fondo, relleno, texto y overlay.
  - `/harford debug run groupframes`: lista frames de party/raid detectados, unidad, visibilidad y barras nativas (`health`/`power`) para diagnosticar clientes Epsilon/custom.
  - `/harford debug run barslot player|target|focus`: imprime UV/posicion de los `barSlotOverlays`.
  - `/harford debug run totlayer`: imprime parent/strata/level de `TargetFrameToT`, frame Harford target, `barSlotsFrame`, anchor points actuales del ToT y estado `totDesired`.
  - `/harford debug run totpieces`: lista globals/campos/hijos `StatusBar` candidatos dentro de `TargetFrameToT`.
  - `/harford debug run totwatch [segundos]`: observa eventos/update de `TargetFrameToT` y valores de barras durante unos segundos.
  - `/harford debug run totportrait`: diagnostica el portrait overlay del ToT — si existe `totBarsOverlay.portraitFrame`, si esta visible, que textura tiene y que devuelve TRP3 para `targettarget`. Util para depurar por que no aparece el icono TRP3.
  - `/harford debug run totspy [segundos]`: hookea metodos de `TargetFrameToTManaBar` con `hooksecurefunc` para capturar quien los llama. NO removible; solo para diagnostico puntual. Confirmo: `TargetofTarget_Update` y `OnValueChanged` disparan SetStatusBarColor/SetValue a ritmo de frame (~60fps).
  - `/harford debug run totscripts`: lista scripts registrados en barras y frames del ToT (`OnUpdate`, `OnValueChanged`, etc.).
  - `/harford debug run totrate [segundos]`: mide frecuencia de llamadas a `TargetofTarget_Update`, eventos `UNIT_HEALTH`/`UNIT_POWER_UPDATE`, y contador de `RefreshTargetOfTargetBars`.
  - Estos comandos solo verifican la calibracion; el render normal no depende de ejecutarlos.
- No usar ticker continuo para esta capa visual.
- El frame Harford (`SecureUnitButtonTemplate`) tiene `EnableMouse(false)`: el frame nativo (PlayerFrame/TargetFrame) permanece visible y funcional y maneja click-to-target, menu contextual y tooltips de buffs. Si Harford captura mouse bloquea los buff/debuff icons del target frame. No volver a activar mouse en el frame raiz de Harford sin una razon explicita.

Contrato `HarfordNamePlates`:

- Vive en `Harford/Frames/HarfordNamePlates.lua` y se carga despues de `HarfordUnitFrames.lua` en `Harford.toc`, porque reutiliza `HarfordUnitFrames.BuildResourceList`, `HarfordUnitFrames.ResourceColor`, `HarfordUnitFrames.C.TEX_STATUS` y `HarfordUnitFrames.GetClassColor`.
- Control de config: `HarfordConfig.Get("nameplates")`. `"on"` activa overlays; `"off"` oculta y limpia `npState`.
- Objetivo: pintar recursos Harford en nameplates coloreados por clase TRP3, con nombre RP visible encima de las barras.
- **Deteccion dinamica de modo**: `IsKuiActive() and rawget(nameplate, "kui")` se evalua en cada `ApplyUnit`. Si Kui se inicializa despues de nuestro addon (race condition en NAME_PLATE_UNIT_ADDED), el overlay puede haberse creado en modo nativo. `st.isKui` marca el modo del overlay actual; si cambia, el overlay se destruye y se recrea en el modo correcto. Nunca reutilizar un overlay nativo como Kui ni viceversa: sus estructuras internas son incompatibles.
- Soporta dos caminos:
  - **KuiNameplates activo**: usa `nameplate.kui`, `kui.HealthBar`, `kui.NameText`, `kui.IN_NAMEONLY` y `kui.unit`. El overlay (`ov`) se parenta al `kuiFrame`. `st.isKui = true`.
  - **Nativo WoW**: usa `nameplate.UnitFrame.healthBar` / `HealthBar` o campos equivalentes. Overlay hijo de `healthBar`. `st.isKui = false`.
- **Plugin Kui**: `TryRegisterKuiPlugin()` se llama en `PLAYER_LOGIN` (no en tiempo de carga del TOC) para garantizar que Kui esta inicializado. Si Kui no existe, la funcion es no-op. Si Harford registra el plugin despues de que Kui haya inicializado su lista en `PLAYER_LOGIN`, hay que llamar manualmente a `mod:Initialise()` y `mod:Enable()`; si no, el plugin queda creado pero no escucha mensajes. El plugin escucha `Show`, `Hide`, `HealthUpdate`, `HealthColourChange`, `GainedTarget` y `LostTarget` para repintar sin ticker.
- **Modo Kui normal**: overlay anclado a `kui.HealthBar`, frame level `kuiFrame+5`. Al aplicar el modo, recalcular tambien los niveles de `ov.hpBar`, `ov.resBar` y `ov.tempBar` (`base+1`, `base+1`, `base+2`); no asumir que el cambio de level del parent reajusta hijos ya creados. Fondo opaco tapa la barra nativa. Para el nombre, usar el `kui.NameText` real como fuente visual principal: `SetText(nombre TRP3)`, `SetTextColor(color clase)`, `SetAlpha(1)` y `Show()`. Como el `NameText` real puede quedar por debajo de nuestras barras si vive en el plano de Kui/HealthBar, parentarlo temporalmente a `ov.nameHost` (`base+5`) y luego llamar a `kuiFrame:UpdateNameTextPosition()` para conservar anchors/posicion de Kui. No ocultar `kui.NameText` ni depender de un FontString propio para el camino normal: en Kui puede quedar en un plano no visible. Si Harford deja de pintar esa placa por falta de datos, cambio de modo o reciclaje, llamar a `RestoreKuiNameText(st)` antes de ocultar `ov`; si no, el nombre puede quedarse dentro de un parent oculto y parecer que el nameplate desaparece. `RestoreKuiNameText` debe activar temporalmente `API._applying` y **no debe llamar a `kuiFrame:UpdateNameText()`**, porque ese metodo esta hookeado por Harford y provoca recursion/C stack overflow. `ov.nameLabel` queda solo como fallback si `NameText` no existe.
- Color del nombre en Kui: prioridad `HarfordTRP3.GetProfileNameColor(profile)` (color manual del nombre TRP3). Si no existe, usar color de clase principal calculado desde la ficha TRP3. Como ultimo fallback, usar `UnitClass`/`RAID_CLASS_COLORS`. La barra de salud puede seguir usando color de clase TRP3, pero el texto del nombre no debe ignorar un color manual configurado en TRP3.
- **Fallback sin recursos**: si una placa de jugador aun no tiene recursos Harford cacheados, usar `UnitHealth/UnitHealthMax` como `hpData` temporal en cualquier modo (normal o name-only) mientras se solicita `HarfordDnDAPI.RequestResourcesForName(...)`. Esto evita ocultar el overlay/nameplate durante la ventana entre `NAME_PLATE_UNIT_ADDED` y la llegada del cache remoto.
- **Modo Kui name-only**: no dibujar `ov.hpBar` ni barras semitransparentes detras del nombre. El porcentaje de vida se representa coloreando el propio texto de `kui.NameText` por caracteres con codigos `|cff...|r` (parte rellena en color clase/TRP3, resto gris). Antes de aplicar este modo, devolver `kui.NameText` al `kuiFrame` y ejecutar `UpdateNameTextPosition`; `kui.NameText` permanece visible y tambien recibe el nombre TRP3; `ov.nameLabel` oculto. `HideUnit` tambien restaura el parent del `NameText` al `kuiFrame` para no contaminar frames reciclados.
- **ClassPowers de Kui**: mientras `HarfordConfig.Get("nameplates") ~= "off"` y Kui este activo, desactivar/ocultar temporalmente el plugin/frame global `ClassPowers` de Kui para que los recursos propios del jugador (por ejemplo fragmentos de alma de brujo) no aparezcan sobre placas gestionadas por Harford ni parpadeen al seleccionar. No restaurarlo por `HideUnit`, `LostTarget`, cambios de placa ni por que la placa actual no sea `target`: Kui usa un unico frame global y restaurarlo por unidad reintroduce flicker. `ApplyNormalMode` y `ApplyNameOnlyMode` deben llamar `SetKuiClassPowersSuppressed(true)`, no condicionar por `kuiFrame.unit == "target"`. `SetKuiClassPowersSuppressed(false)` restaura con `plugin:Enable()` solo al desactivar nuestros nameplates/config `"off"`.
- Kui repinta `NameText` en `UpdateNameText`/`UpdateNameTextPosition` al ganar/perder target. Harford debe hookear esos metodos por `kuiFrame` y **programar** `ScheduleApplyUnit(unit)` (deduplicado por unit token, `C_Timer.After(0)`) en vez de llamar `API.ApplyUnit` directamente dentro del stack de Kui. El guard `API._applying` sigue siendo obligatorio para cuando Harford llama `UpdateNameTextPosition`, pero no basta por si solo: aplicar inline desde el hook puede reentrar en Kui y provocar `C stack overflow`. Esto NO es un ticker continuo; es un re-apply de un frame tras eventos/hooks concretos.
- **Color TRP3 en nameplateN**: no depender del cache de `HarfordUnitFrames.GetClassColor`, porque se llena al seleccionar/interactuar con unitframes. `HarfordNamePlates.GetNpClassColor` debe intentar primero `HarfordTRP3.GetPlayerProfile(unit)` + `HarfordTRP3.GetProfilePrimaryClass(profile)` con aliases de clases WoW (`Paladin`, `Pícaro/Picaro`, `Brujo`, etc.) y solo despues caer al cache/unitclass.
- **Color de clase**: `GetNpClassColor(unit)` — intenta clase principal de la ficha TRP3, despues cache/`HarfordUnitFrames.GetClassColor(unit)`, despues `RAID_CLASS_COLORS[classFile]` y verde solo para NPCs/unidades sin clase. Se usa para la barra de salud. Para texto de nombre usar `GetNpNameColor(unit)`, que antepone color manual TRP3 a la clase. **NUNCA verde fijo para jugadores**: indica ausencia de clase detectada, no salud.
- Si `nameplate.kui` cambia de frame fisico para el mismo token reciclado, destruir y recrear el overlay (`st.kuiFrame ~= kui`) antes de aplicar. Reutilizar un overlay parentado al `kuiFrame` anterior provoca colores/nombres inconsistentes "de vez en cuando" al seleccionar/deseleccionar o reciclar placas.
- **Nombre TRP3**: `GetTRP3Name(unit)` usa `HarfordTRP3.GetPlayerProfile(unit)` (que llama `BuildUnitID` — soporta tokens nameplate correctamente) y lee `profile.data.characteristics.FN`+`LN`. Fallback a `HarfordTRP3.GetUnitRPName(unit)` y finalmente a `UnitName(unit)`. **NO pasar el token nameplate directamente a `register.getUnitRPName`**: TRP3 puede no soportar tokens `nameplateN` en versiones antiguas; usar siempre `BuildUnitID` como intermediario. **FontString sin `SetFont` no renderiza nada**: siempre establecer fuente por defecto en la creacion del FontString antes de mostrarlo.
- En nativo WoW sin Kui, crear overlay simple hijo de la `healthBar` nativa y pintar salud + primer recurso con color de clase. Sin `nameLabel` (WoW nativo ya muestra el nombre correctamente).
- Vida temporal: si `resources["Res_temp_health_Cur"] > 0`, se inyecta `hpData.tempCur` antes del render. El overlay `ov.tempBar` es un `StatusBar` como contenedor de absorcion. En modo Kui, `ov.tempBar._harfordUseKui = true` y la textura es `Kui_Media\\t\\stippled-bar` (con `SetHorizTile(true)`). En modo nativo WoW, usa `Interface\\RaidFrame\\Shield-Fill` (con `SetHorizTile(false)`). Efecto visual: Shield-Fill (fill solido azul) + `_harfordAbsorbGlow` (Shield-Overlay tileado con ADD blend, alpha 0.45) encima. En name-only se oculta. **Patrones criticos de `ApplyAbsorbTexture` en nameplates**: (1) Pattern/glow se muestran pero solo si `realW > 0`: el glow se ancla TOPLEFT..BOTTOMLEFT con `SetWidth(realW*pct)` y `SetHorizTile(true)`; (2) Spark: `CENTER, frame, LEFT, realW*pct` — **NO `fillTex:RIGHT`** (texcoords-based en Epsilon, siempre apunta al extremo) y no sumar `+2` global; (3) **`OnSizeChanged` en `healthBar`** con guard `npState[unit]` para nameplates nativos reciclados.
- Recursos remotos: si la unidad es jugador y no hay recursos cacheados, llamar `HarfordDnDAPI.RequestResourcesForName(unitName)` con throttle de 5s por nombre.
- Eventos: `NAME_PLATE_UNIT_ADDED` aplica overlay; `NAME_PLATE_UNIT_REMOVED` oculta y limpia la entrada (incluyendo restaurar `kui.NameText:SetAlpha(1)` y su parent original). `PLAYER_LOGIN` registra plugin Kui, suprime ClassPowers si procede y llama `RefreshAll()` para placas ya visibles. El listener de config tambien intenta registrar Kui antes de refrescar; esto cubre cambios de opcion hechos despues de login. `HarfordUnitFrames` refresca nameplates por nombre (`RefreshName`) cuando llegan recursos por `CHAT_MSG_ADDON`; `RefreshAll()` queda solo como fallback si esa API no existe.
- Debug relacionado:
  - `/harford debug run npinspect`: inspecciona target.
  - `/harford debug run npinspect all`: lista nameplates visibles.
  - `/harford debug run npkui`: vuelca campos/regiones de `nameplate.kui`.
- No usar `OnUpdate` ni ticker para nameplates. La integracion debe ser event-driven por eventos de nameplate, mensajes Kui, config listener y `RefreshAll()` tras sync de recursos.
- UnitFrames no debe usar timers de arranque tipo `C_Timer.After(3/6, ...)` para "por si TRP3 esta listo": `totalRP3` es `OptionalDeps`, y `EnsureTRP3Hooks`/`InstallCompactUnitFrameHooks` se invocan desde `ADDON_LOADED`, `PLAYER_LOGIN` y `PLAYER_ENTERING_WORLD`. Los `C_Timer.After(0)` o delays cortos que quedan son diferidos puntuales de layout/restauracion despues de eventos concretos, no reintentos de inicializacion.

## TRP3 / Fichas De Jugador, Companion Y NPC Epsilon

TRP3 no usa la API base de WoW para leer fichas completas. `UnitName`, `UnitClass`, etc. solo sirven como apoyo para construir identificadores o conocer el target. La informacion real vive en APIs internas:

- `TRP3_API.register`: perfiles de jugadores.
- `TRP3_API.companions.register`: perfiles de companions, monturas y NPCs con ficha companion.
- `TRP3_API.companions.player`: utilidades relacionadas con companions del jugador.

Jugador normal:

```lua
local name, realm = UnitName("target")
realm = realm ~= "" and realm or GetRealmName()
realm = realm:gsub("%s+", "")
local unitID = name .. "-" .. realm

if TRP3_API.register.isUnitIDKnown(unitID) then
    local profile = TRP3_API.register.getUnitIDCurrentProfile(unitID)
end
```

Funciones relevantes:

- `TRP3_API.register.isUnitIDKnown(unitID)`
- `TRP3_API.register.getUnitIDCurrentProfile(unitID)`
- `TRP3_API.register.getUnitIDProfile(unitID)`
- `TRP3_API.register.getUnitIDProfileID(unitID)`
- `TRP3_API.register.getProfile(profileID)`
- `TRP3_API.register.getCharacterList()`
- `TRP3_API.register.getUnitRPName("target")`

Bloques posibles del perfil de jugador:

- `profile.characteristics`
- `profile.about`
- `profile.misc`
- `profile.character`

Companion/montura de jugador:

- Usa `TRP3_API.companions.register`.
- `getCompanionProfile(companionFullID)` espera `companionFullID`, no un `profileID` simple.
- Para monturas/companions vinculados a jugador, TRP3 puede construir IDs como `ownerID .. "_" .. spellBuffID`.
- Funcion relevante: `TRP3_API.companions.register.getUnitMount(ownerID, "target")`.

NPC de Epsilon con ficha companion:

- Es el caso principal actual para Harford.
- No se resuelve por owner/mount.
- Epsilon construye:

```lua
local guid = UnitGUID("target")
local npcID = select(6, strsplit("-", guid))
local fullID = C_Epsilon.GetPhaseId() .. "_" .. npcID
local profile = TRP3_API.companions.register.getCompanionProfile(fullID)
```

- `profile.data.TX` contiene el texto principal de la ficha del NPC.
- Ejemplos de contenido en `data.TX`: tipo de criatura, CA, atributos, vulnerabilidades, resistencias, sentidos, velocidad y bloques `{h3}...{/h3}`.
- Modo NPC de la ficha DnD: `HarfordTRP3.GetNPCStatBlock(unit)` sigue siendo lectura core de TRP3, pero la decision DM de cargar un NPC vive en `HarfordAdminNPC.BuildDnDSheetContext(unit)`. Admin crea primero una ficha NPC limpia con atributos, competencia, bonus situacional/iniciativa y todos los flags de habilidad/salvacion a `0`, despues aplica los datos parseados y convierte lineas explicitas (`Sigilo +5`, `Destreza +5`, etc.) a overrides neutrales `Context_Hab_<id>_Bonus` y `Context_Salv_<atributo>_Bonus`. Los entrega a `HarfordDnDAPI.ApplySheetContext(context)`, que solo representa/tira el contexto: no hay fallback accidental a la ficha del jugador.
- Stat block NPC por defecto: si TRP3 no tiene ficha, no hay texto o el parser no encuentra datos, `HarfordTRP3.GetNPCStatBlock` devuelve una ficha estandar segura (`CA 10`, las seis caracteristicas a `10`/`+0`, sin salvaciones/habilidades/defensas explicitas) en vez de `nil`. El parser normaliza etiquetas para TODAS las caracteristicas, no solo Fuerza/Constitucion: `FUE/Fuerza/STR`, `DES/Destreza/DEX`, `CON/Cons/Constitucion/Constitution`, `INT/Inteligencia`, `SAB/Sabiduria/WIS`, `CAR/Carisma/CHA`; acepta mayusculas/minusculas, tildes, guion o asterisco inicial, `:`/`=`, y modificador opcional (si falta, se calcula desde la puntuacion). No crear parsers paralelos de stats NPC en Admin.
- Ataques del modo NPC: al aplicar el contexto, `HarfordAdminNPC` recoge los estados activos con `HarfordTRP3.GetProfileStates(profile)` y los entrega como `context.actions`; `HarfordDnD` sustituye visualmente la seccion Ataque por un selector de esos estados, icono, texto y botones de tirada. El parser reconoce expresiones TRP3 equivalentes a `+5 al ataque`, `Impacto: 1d6 + 3 de dano perforante` y daños compuestos como `Impacto: 2d8 + 4 perforante + 1d4 necrotico`; cada tramo se guarda en `action.damageComponents = { damageDice, damageBonus, damageType }`. `HarfordDnD` tira todos los componentes, aplica en core `HarfordDamageMitigation.ForTarget("target", tipo, total)` por componente y muestra en la tirada publica el daño ya mitigado junto al marcador `R`/`V`/`I` si corresponde. `HarfordAdminNPC.ApplyNpcSheetDamage` recibe el total ya mitigado y solo lo aplica con `SetNpcHealthDelta`; no re-mitiga ni imprime lineas locales de defensa. Si la tirada `Atacar` obtiene `CRÍTICO`, el panel guarda una carga consumible vinculada a esa misma accion: su siguiente click en `Daño` fuerza cada dado de todos sus componentes al maximo posible y suma los bonus fijos normalmente; luego la carga desaparece. Una nueva tirada de ataque no critica la limpia, y no puede consumirse sobre otra accion seleccionada. El daño maximo sigue pasando por inmunidades, resistencias y vulnerabilidades por componente. Cada accion reutiliza `HarfordTRP3.CreateGlanceLink` para incluir el hyperlink clicable del estado solo en el mensaje `Ataque` enviado por `DND5EARC`; el mensaje `Dano` usa el titulo plano y representa la tirada base por componentes. La cache por contenido evita registrar enlaces nuevos en cada tirada. Efectos condicionales posteriores (por ejemplo dano adicional con ventaja) se muestran en el texto, pero no se automatizan hasta definir su contrato.
- Flujo atacante/victima en modo NPC: click normal carga el NPC seleccionado y sigue cambiando de ficha cuando se selecciona otro NPC; con un NPC target queda activo solo `Atacar`. Si despues se selecciona un jugador, conserva la ultima ficha NPC para permitir solo `Daño` sobre sus recursos; sin target ambos botones quedan apagados. `Shift+click` carga la variante marcada, muestra corchetes solo en el titulo local y fija `npcSourceGuid`: con el NPC exacto queda activo `Atacar`, y con cualquier unidad diferente queda activo `Daño`, incluidos otros NPC, a los que descuenta mediante `npc set health -N`. Las tiradas conservan el nombre normal del NPC. Tras aceptar daño NPC, el DM ejecuta localmente `mod anim 33` para mostrar el impacto. El core solo almacena/ejecuta callbacks opcionales recibidos y refresca disponibilidad al cambiar target; la identificacion y los comandos servidor siguen viviendo en `HarfordAdmin`.
- Competencia informativa/conjuro NPC: `HarfordAdminNPC` entrega `context.kind = "npc"` y `context.spellProficiencyBonus`, calculado segun nivel/CR aproximado: 1-4 `+2`, 5-8 `+3`, 9-12 `+4`, 13-16 `+5`, 17-20 `+6`, 21-24 `+7`, 25-28 `+8`, 29-30 `+9`. El core solo acepta este override si el contexto esta marcado explicitamente como NPC. En modo NPC se muestra en la cabecera como `Bonus competencia` y solo alimenta la informacion/tirada de `Ataque Conjuro` y el envio de `CD Conjuro`; no se usa en ninguna otra tirada. Mientras no exista un CR parseado en el stat block, usa `UnitLevel(unit)` como fuente disponible. No escribir este valor en `BonusCompetencia`: no puede pisar stats, salvaciones, skills ni ataques explicitamente cargados desde TRP3.
- `profile.PE` parece contener cinco posibles estados:
  - `AC`: activo
  - `TI`: titulo
  - `TX`: texto
  - `IC`: icono
- Estado actual de investigacion: aunque `PE` aparece con estructura compatible, los valores directos pueden salir vacios en Epsilon. Es posible que la UI lea estados desde otra capa o desde datos de fase.

PhaseAddonData de Epsilon:

- Epsilon guarda perfiles NPC TRP3 en claves de fase:

```lua
local key = "TOTALRP_PROFILE_" .. npcID
EpsilonLib.PhaseAddonData.Set(key, str)
```

- La estructura probable deserializada:

```lua
local phaseData = {
    id = profileID,
    profile = profile,
    notes = ...
}
```

- Siguiente investigacion para estados:
  - leer `EpsilonLib.PhaseAddonData.Get("TOTALRP_PROFILE_" .. npcID)`;
  - si viene comprimido, probar `AddOn_TotalRP3.Compression.decompress(...)`;
  - deserializar con `TRP3_API.utils.serial.deserialize(...)`;
  - comprobar si ahi viven los estados reales.

Comandos `/run` validados/utiles:

```lua
-- Texto principal del NPC target
/run local g=UnitGUID("target"); if not g then print("sin target") return end local npcID=select(6,strsplit("-",g)); local fullID=C_Epsilon.GetPhaseId().."_"..npcID; local p=TRP3_API.companions.register.getCompanionProfile(fullID); print(p and p.data and p.data.TX or "Sin texto")

-- ProfileID asociado al NPC
/run local g=UnitGUID("target"); if not g then print("sin target") return end local npcID=select(6,strsplit("-",g)); local fullID=C_Epsilon.GetPhaseId().."_"..npcID; local r=TRP3_API.companions.register; print("fullID",fullID,"profileID",r.getCompanionProfileID(fullID) or "nil")

-- Dumpear perfil completo del NPC
/run local g=UnitGUID("target"); if not g then print("sin target") return end local npcID=select(6,strsplit("-",g)); local fullID=C_Epsilon.GetPhaseId().."_"..npcID; DevTools_Dump(TRP3_API.companions.register.getCompanionProfile(fullID))

-- Dumpear PE del NPC
/run local g=UnitGUID("target"); if not g then print("sin target") return end local npcID=select(6,strsplit("-",g)); local fullID=C_Epsilon.GetPhaseId().."_"..npcID; local p=TRP3_API.companions.register.getCompanionProfile(fullID); DevTools_Dump(p and p.PE)
```

## Comunicacion Interna Entre Clientes

Harford usa `C_ChatInfo.SendAddonMessage` / `SendAddonMessage` para comunicacion entre clientes. La recepcion entra por el evento `CHAT_MSG_ADDON`.

Prefixes actuales (los NUEVE que existen; no anadir mas sin motivo real):

| Prefijo | Lleva |
|---|---|
| `DND5EARC` | Ficha, tiradas, recursos y configuracion DnD |
| `TCBOARD` | Tablon de contratos |
| `HARFORDLOOT` | Loot resuelto por cadaver (`LOOT`, o `LOOTC` fragmentado si una tabla por GUID crece) |
| `HARFORDCFG` | Configuracion global de loot (`LOOTCFG`, o `LOOTCFGC` fragmentado) |
| `HARFORDREP` | Reputaciones (facciones y jugadores) |
| `HARFORDQUEST` | Misiones: progreso y cierre para el grupo |
| `HARFORDPROF` | Profesiones |
| `HARFORDTURN` | Estado del tracker de turnos |
| `HARFCOM` | Comunicador (solo texto, por WHISPER) |

Tipos de mensaje dentro de `TCBOARD`: `SNAPBEGIN`, `SNAPEND`, `STATUS`, `CLAIM`, `CLAIMMONEY`,
`EMPTY`, `TCDONE` (aviso de mision completada por quien no puede escribir en la fase).
`VOTE`/`VOTES`/`VOTECLEAR`/`VOTERESET` estan RETIRADOS: se ignoran al recibirlos, por
compatibilidad con clientes viejos.

### Claves de fase (PhaseAddonData)

Esto NO viaja por chat: vive en el servidor, ligado a la fase. No hacen falta prefijos de red
nuevos para nada que se guarde asi. Convencion:

```
HARFORD_<SISTEMA>_KEYS     manifiesto: TODAS las claves que Harford escribe en esa fase
HARFORD_<SISTEMA>_INDEX    indice, SOLO si hay que enumerar
HARFORD_<SISTEMA>_<id>     bloque, SOLO si el grano de escritura lo pide
```

| Clave | Contenido |
|---|---|
| `HARFORD_TC_KEYS` | Manifiesto del tablon de contratos |
| `HARFORD_TC_INDEX` | Indice rico (8 campos de la fila) + sello `meta = { by, at }` |
| `HARFORD_TC_<id>` | Un contrato publico completo |
| `HARFORD_LOOT_KEYS` | Manifiesto de loot *(previsto)* |
| `HARFORD_LOOT_GLOBAL` | Tabla de loot global *(previsto)* |
| `HARFORD_LOOT_C_<creatureId>` | Tabla de loot por criatura *(previsto)* |
| `HARFORD_REP_KEYS` | Manifiesto de reputacion *(previsto)* |
| `HARFORD_REP_ALL` | TODAS las definiciones de faccion en una sola clave *(previsto)* |

**El manifiesto es obligatorio en cada sistema.** El servidor no deja listar claves ni borrar
por prefijo (la API entera son `GetPhaseAddonData`/`SetPhaseAddonData` sobre una clave exacta),
asi que sin manifiesto una clave huerfana es irrecuperable: nadie puede saber que existe.

**Indice solo si hay que enumerar.** El tablon lo necesita porque muestra una lista. El loot no:
cuando vas a saquear ya sabes el template id de la criatura y pides su clave directamente
(patron de `Epsilon_Merchant`/TRP3, direccionado por identidad).

**Regla que decide si un sistema puede usar bloques por id: el id tiene que estar ACOTADO.**
Los ids numericos (criaturas, NPCs) lo estan. Los derivados de texto escrito por una persona,
NO: `HarfordReputation.NormalizeId` construye el id de faccion desde el NOMBRE sin truncar,
asi que con `HARFORD_REP_F_` gastando 14 de los 96 caracteres utiles, una faccion con nombre
de mas de ~82 caracteres romperia la clave y el servidor lanza error duro. Por eso las
facciones van TODAS en `HARFORD_REP_ALL` y no una por clave. Si algun sistema necesita bloques
con id de texto, hay que acotar o hashear el id ANTES, no confiar en que nadie escriba largo.

Canales actuales:

- `RAID` o `PARTY`, elegidos via `HarfordSync.BestChannel()`.
- `WHISPER`, para mensajes dirigidos a un jugador concreto.

Archivos clave:

- `Harford/Core/HarfordSync.lua`: wrappers comunes de registro/envio.
- `Harford/DnD/Engine/HarfordDnDComm.lua`: receptor principal de mensajes DnD.
- `Harford/Loot/HarfordLoot.lua`: receptor loot/config.
- `Harford/Frames/HarfordTurns.lua`: receptor turnos.
- `HarfordAdmin/HarfordAdmin.lua`: comandos admin locales.

## Canal De Comandos Al Servidor Epsilon

Para comandos al servidor Epsilon, no usar `SendChatMessage(".comando", "GUILD")` como via principal.

La via preferida es `EpsilonLib.AddonCommands`:

```lua
local sendCommand, sendCommandChain = EpsilonLib.AddonCommands.Register("HarfordAdmin", false)
```

Los comandos se envian sin punto inicial:

```lua
sendCommand("gob select 12345", callback)
sendCommand("phase info 123 addon", callback)
sendCommandChain({ "gob spa 123", "gobject scale 1" }, callback)
```

Internamente, `EpsilonLib` usa el prefix addon `"Command"` y envia por:

```lua
ChatThrottleLib:SendAddonMessage(..., "Command", payload, "GUILD")
```

Ese `"GUILD"` es transporte addon oculto, no chat visible de hermandad.

Las respuestas llegan por `CHAT_MSG_ADDON`, con prefix `"Command"`, normalmente por canal `"WHISPER"`. `EpsilonLib` asocia las respuestas al command id y llama al callback con:

```lua
function(success, messages)
end
```

`messages` contiene las lineas devueltas por el servidor y deben parsearse segun el comando.

### La forja de objetos NO acepta las clases de WoW (2026-08-29, confirmado en juego)

`forge item set class` admite **cinco valores y ya**: `-1` ninguna, `2` Arma, `4` Armadura,
`13` Llave y `15` Miscelaneo. Cualquier otra la rechaza en seco:

```
EpsiLib -> Failed Command by HarfordItemForge: forge item set class [Item ID #14088100] 0
The specified class 0 is not currently supported
```

**El rechazo CORTA la cadena**, asi que el objeto no queda sin clase: queda **a medias**. El
orden de `Comandos()` es nombre, descripcion, icono, calidad, clase, subclase, hueco, modelo,
apilable, vinculacion, additem — o sea que lo anterior a `class` SI se aplico y todo lo
posterior no, incluido el `additem anyone` que abre el objeto a los demas. Se confirmo con
`aceite_de_bocanegra` (id 14088100).

No hay categoria de consumible: **pociones, comida, vendajes y materiales van todos como `15`**,
con subclase `1` Reactivo (bienes comerciales, que literalmente lo son) o `4` Otro. Las
subclases de Miscelaneo llegan solo hasta `6`: 0 Basura, 1 Reactivo, 2 Mascota, 3 Festividad,
4 Otro, 5 Montura, 6 Equipo de montura.

`set stackable` tiene la misma trampa: *"Cannot be done on weapons or armour"*, y su rechazo
corta la cadena igual. No mandarlo en clases 2 ni 4.

**El catalogo de EpsilonLib NO sirve para averiguar esto**: su descripcion de `set class` se
corta en `"2 is for weapons"` y se traga el resto de la frase, que es justo la lista. Es el
mismo truncado por coma que ya afecta a `description`, `creaturetype`, `rank`, `sheath`,
`movetype` y los huecos de `outfit equip`. La fuente buena es **`PhaseToolkit.itemClass`**, la
tabla que llena el desplegable del creador oficial: da clases, subclases y sus nombres.

`gen_itemforge_data.py` sigue clasificando con las clases de WoW —saber que algo es un
consumible decide su subclase y su apilamiento— y traduce al emitir (`para_la_forja`), despues
de aplicar las anulaciones para que una correccion a mano tampoco pueda colar una clase
rechazada. `HarfordItemForge/Core.lua` lo vuelve a comprobar al enviar (`CLASES_FORJA`), porque
`Data.lua` se puede editar a mano.

## Almacen De Fase Epsilon (PhaseAddonData) (2026-08-21)

Almacen clave -> valor **guardado en el servidor y ligado a la fase**. Es la unica via conocida
para que un dato escrito por el DM lo lea otro jugador **sin que el DM este conectado**. Harford
todavia no lo usa: hoy todo se reparte por addon messages y exige un emisor vivo.

### API

```lua
EpsilonLib.PhaseAddonData.SaveTable(clave, tabla)           -- escribir (serializa+comprime+trocea)
EpsilonLib.PhaseAddonData.LoadTable(clave, function(t) end) -- leer (ASINCRONO, reensambla)
EpsilonLib.PhaseAddonData.Set/Get                           -- las mismas con cadenas crudas
```

Por debajo: `C_Epsilon.SetPhaseAddonData(clave, str)` y `C_Epsilon.GetPhaseAddonData(clave, faseId?)`.
`Get` **devuelve un ticket, no el dato**: la respuesta llega por `CHAT_MSG_ADDON` usando ese ticket
como prefijo. Por eso todo es asincrono. El `faseId` opcional permite leer de OTRA fase.

**Usar siempre EpsilonLib, nunca `C_Epsilon` directo.** Epsilon_Merchant se guiso el mismo protocolo
a mano y su reensamblado multi-parte esta ROTO (`Epsilon_Merchant.lua:830` hace aritmetica sobre el
ticket para construir la clave siguiente, y registra `type = prefix` en vez de `prefixType`): un
vendedor de mas de 3000 caracteres no carga bien.

### Limites CONFIRMADOS en vivo (`/harford debug run phasedata`)

- **Clave <= 100 caracteres.** Lo valida el SERVIDOR y **lanza error Lua duro**
  (`key should have length <= 100`), no falla en silencio. Envolver toda escritura en `pcall`.
  El troceado ANADE `_2`, `_3`... a la clave, asi que el presupuesto real es ~96.
- **3000 caracteres por segmento**, troceado y reensamblado automaticos con caracteres de control
  (`\001` primero, `\002` medio, `\003` ultimo).
- **Throttle 45 llamadas / 1,5 s** con cola propia. Pasarse desconecta del servidor.
- **`EncodeForPrint` expande +33 %** (3 bytes -> 4 caracteres): el dato viaja por chat y no admite
  bytes crudos.
- **Escribir exige ser OFICIAL de la fase, y lo aplica el SERVIDOR.** Medido en vivo el
  2026-08-21 con el mismo personaje en dos fases: en la que era oficial el viaje redondo
  cuajo; en la que no, la escritura no tuvo efecto. Los filtros `IsOfficer`/`IsMember` que
  aplican SpellCreator y TRP3 no son solo politica de addon: el servidor tambien filtra.
- **El rechazo por permiso es SILENCIOSO.** No lanza error Lua -- a diferencia del limite de
  clave, que si lo lanza --: la escritura simplemente no ocurre y al releer no hay nada. Por
  eso `pcall` NO detecta un fallo de permiso; la unica forma de saber si cuajo es releer y
  comparar (por eso `phasedata escribir` escribe una marca de tiempo y la verifica).
- **Consecuencia de diseno**: un jugador normal NO puede persistir nada por su cuenta. Todo lo
  que deba quedar escrito lo tiene que escribir un oficial, sea directamente o porque alguien
  se lo pide por addon message (patron `TCDONE` de los contratos).

### Trampas

- **No hay ruta de error en la lectura.** Si el servidor calla, el callback **no se llama jamas** y
  la entrada se queda en `_queue` para siempre. Toda lectura necesita su propio plazo.
- **Borrar es escribir cadena vacia.** No hay borrado real; leer una clave inexistente devuelve `""`.
- **Sobrescribir no limpia.** Pasar de 5 segmentos a 2 deja `_3.._5` colgando. Leer no se rompe
  (para en el `\003`) pero se acumula basura.
- **No se pueden listar las claves.** El servidor solo responde "dame X". Hay que mantener un
  **indice propio** si se necesita enumerar.
- **Cambiar de fase con lecturas en vuelo**: comparar `C_Epsilon.GetPhaseId()` dentro del callback
  contra el que habia al pedir, y descartar si no coincide (lo hace SpellCreator).
- **Cuota total por fase: DESCONOCIDA.** No aparece ningun tope agregado en el codigo del addon.

### Los tres patrones existentes

1. **Indice + bloques** (SpellCreator): `SCFORGE_KEYS` lista los ids, `SCFORGE_S_<id>` cada hechizo.
   Obligado cuando hay que enumerar. **Orden de escritura: primero el bloque, DESPUES el indice** —
   asi un corte a medias deja un huerfano invisible, nunca un indice apuntando a la nada. Borrar es
   quitar del indice, reguardar el indice y escribir `""` en el bloque.
2. **Direccionado por identidad, sin indice** (Epsilon_Merchant, TRP3): `VENDOR_DATA_<merchantID>`,
   `TOTALRP_PROFILE_<npcID>`. Sirve cuando ya sabes que clave quieres. El merchant ademas **parte
   por campo**: siete claves por vendedor (`VENDOR_TEXT_`, `GREET_SOUND_`...), de forma que cambiar
   un sonido no reescribe la lista de objetos.
3. **Cerrojo cooperativo para el indice** (SpellCreator): el indice es un lee-modifica-escribe
   ASINCRONO, asi que dos DMs escribiendo a la vez pierden datos. Se difunde `_PLOCK`/`_PUNLOCK`
   con el phaseID por canal de addon; los demas clientes se marcan ocupados y recargan al soltarse.
   **Caduca solo a los 5 s** para que un DM que se cae no bloquee la fase. No es un cerrojo del
   servidor: quien no lleve el addon no lo respeta.

### Medidas reales del tablon de contratos (17 contratos, 2026-08-21)

| Que | Crudo | Deflate | Encode | Segmentos |
|---|---|---|---|---|
| Tablon entero | 43389 | 16610 | 22147 | 8 |
| Tablon sin `prep`/`privateNotes` | 42479 | 16254 | 21672 | 8 |
| Solo el indice de ids | 366 | 120 | 160 | 1 |
| **Indice RICO** (8 campos de la fila) | 1460 | 739 | **986** | **1** |
| Contrato mas gordo | 4637 | 2230 | 2974 | 1 |

Conclusiones que NO se adivinan:

- **Quitar `prep`/`privateNotes` no ahorra espacio** (2 %). Hay que excluirlos igualmente por
  privacidad — lo que no se escribe no se puede filtrar — pero no como argumento de tamano.
- **Los contratos sueltos comprimen peor que el tablon junto** (48 % contra 38 %): deflate aprovecha
  la repeticion entre contratos. Guardar por separado gasta ~25 % mas bytes totales.
- **El contrato mas gordo esta al 99 % de un segmento** con `prep` vacio. Un contrato por clave es
  el grano correcto; en un blob unico ese crecimiento arrastra a los ocho segmentos.
- **El indice rico cabe de sobra en UN segmento**: 986 de 3000 para 17 contratos, con margen para
  ~34 mas (unos 51 en total) antes de trocearse. Los 8 campos son exactamente los que pinta la fila
  (`HarfordContractsUI.lua:1216-1246` + `FormatContractMeta`): `id`, `title`, `difficulty`,
  `status`, `duration`, `rewardText`, `category`, `icon`.

### Forma decidida para el tablon de contratos

```
HARFORD_TC_INDEX   -> indice rico: una fila por contrato (8 campos)   1 segmento hasta ~51
HARFORD_TC_<id>    -> el contrato publico completo                     ~1 segmento cada uno
```

Coste de lectura medido, contra el throttle de 45/1,5 s:

| Estrategia | Llamadas para ver la lista |
|---|---|
| Blob unico del tablon | 8 |
| **Indice rico** (pintar la lista) | **1** |
| + un bloque por contrato (completar) | +1 cada uno |

**CORRECCION (2026-08-21): la carga perezosa NO basta.** El primer diseno bajaba el bloque solo
al abrir un contrato. No vale, porque una **mision de mundo la dispara el gossip de un NPC**, no
abrir el tablon: cuando el jugador habla con el NPC ya tienen que estar objetivos, recompensas y
los tres textos. `TC.BuildWorldQuestDef` los lee del contrato COMPLETO y el indice ni siquiera
lleva `worldNpc`, asi que con esbozos la mision no se registraba en absoluto. Ahora el indice
pinta la lista en una llamada y detras `Phase.LoadAllBlocks()` baja todos los bloques y llama a
`RegisterAllWorldQuests`. Un bloque que no conteste deja ese contrato como esbozo sin bloquear
a los demas.

`prep` y `privateNotes` **no se suben nunca** (lista BLANCA, no negra: con lista negra un campo
privado nuevo se filtraria por olvido). Los borradores (`draft`) y el archivo (`archived`)
tampoco. **Trampa**: por eso la carga que reemplaza retira solo los contratos PUBLICOS ausentes
del indice; borrar "lo que no este en la fase" a secas se llevaria por delante todo el trabajo
sin publicar del DM.

**CORRECCION (2026-08-21): no hace falta cerrojo cooperativo.** El plan inicial preveia
`_PLOCK`/`_PUNLOCK` para el indice. No se necesita: `PublishTracked` lee el indice y fusiona a
tres bandas antes de escribir (ver mas abajo).

## Patrones Comunes Del Almacen De Fase (2026-08-21)

Tres sistemas lo usan ya -- contratos, loot y facciones -- y comparten estas piezas. Cualquier
sistema nuevo deberia reutilizarlas en vez de reinventarlas.

### `HarfordPhaseStore` (`Harford/Core/HarfordPhaseStore.lua`)

Transporte comun: `Write` (con `pcall`, porque el servidor lanza error Lua duro), `Read`
(con plazo y guardia de cambio de fase), `WipeKey` (vacia la clave Y sus segmentos),
`MergeKeys`, `CanWrite`, `KeyFits`. **Comparte el transporte, NO la politica**: indice,
manifiesto y fusion los necesita distintos cada sistema. Carga en `.toc` antes que cualquier
consumidor.

### Manifiesto + espejo local

**Obligatorio en cada sistema.** El servidor no deja listar claves ni borrar por prefijo, asi
que sin manifiesto una clave huerfana es irrecuperable. Se espeja ademas en SavedVariables
**por fase**; la fase sigue siendo la autoridad y el espejo solo SUMA. El fallo es asimetrico a
favor: claves de mas se vacian sin dano (escribir vacio sobre lo que no existe es inocuo),
claves de menos dejan las cosas como sin espejo. El espejo salva la limpieza si la fase pierde
su manifiesto.

Precedente de por que hace falta: TRP3 **no** lleva manifiesto y su `unboundNPC` vacia solo el
primer segmento con `C_Epsilon.SetPhaseAddonData` directo, aunque `boundNPC` escribio con
`EpsilonLib` (que trocea). Los segmentos `_2`, `_3` de un perfil grande quedan colgados para
siempre y nadie puede volver a encontrarlos.

### Sello y fusion a tres bandas

El indice/payload lleva `meta = { by, at }` **como campo con NOMBRE dentro de la lista**, asi que
`ipairs` lo ignora: sin clave aparte y sin cambiar el formato.

Al ABRIR se compara el sello con el ultimo aplicado; si es el mismo no se toca nada, ni un
refresco. Al DM no se le carga encima por si tiene ediciones sin publicar: se le avisa.

Al PUBLICAR se lee primero y se fusiona:

| Situacion | Que pasa |
|---|---|
| En la fase **y** en tu copia | Mandas tu |
| En la fase, no en la tuya, y **lo viste** la ultima vez | Lo borraste tu -> se retira |
| En la fase, no en la tuya, y **nunca lo viste** | Lo anadio otro DM -> se **adopta** |
| Solo en tu copia | Se sube |

Para distinguir las dos de en medio hay que guardar **los ids que se vieron**, no solo la hora.
Sin esta fusion, un DM con una copia vieja borraba el trabajo de los demas de forma permanente.
Adoptar es barato: la fila ya la tienes de la lectura y el bloque ajeno ni se toca. Tras
publicar, la copia local se actualiza con el resultado de la fusion.

### Contrato de los callbacks

Dos formas, y **el error NUNCA ocupa el hueco de los datos**:

- Lecturas puras (`Load*`): `callback(datos, error)`. No hay `ok` aparte porque `datos` nil ya
  significa que fallo.
- Lo que ademas escribe (`Publish*`, `Purge*`, `Prune*`): `callback(ok, datos, extra)`, donde
  `extra` es el error si fallo.

Caso real: `PurgeAll` devolvia la cadena `sin modo DM` en el hueco de la lista, su longitud daba
11, el comando anuncio "Purgadas 11 claves" y luego reviento en `ipairs`. Los consumidores
comprueban ademas `type(x) == "table"` antes de contar o iterar.

### Trampa de retornos multiples, variante EXPANSION

Distinta de la ya documentada (cadenas `and` que TRUNCAN a uno). Aqui es lo contrario: una
llamada multivalor como **ultimo elemento de un constructor de tabla o de una lista de
argumentos se EXPANDE**. Caso real: `EspejoLocal()` devuelve tres valores (lista, tabla, fase) y
estaba dentro de `ipairs({ lista, EspejoLocal() })`; la tabla acababa con el id de fase (cadena)
dentro y el bucle reventaba. Se arregla parentizando: `(EspejoLocal())`.

**Solo aparecia despues de publicar al menos una vez**: con el espejo de esa fase vacio el
segundo elemento era nil, `ipairs` paraba ahi y nunca alcanzaba la cadena. Por eso ningun test
lo cazo. El grep documentado para la variante `and` NO detecta esta.

## Loot En La Fase (2026-08-21)

`Harford/Loot/HarfordLootPhase.lua`. Dos diferencias DELIBERADAS con el tablon:

**Sin indice.** Al saquear ya sabes el template id, asi que se pide `HARFORD_LOOT_C_<id>`
directamente (patron de `Epsilon_Merchant` y de los perfiles de NPC de TRP3). El manifiesto
existe solo para limpiar y para que el editor del DM liste.

**Escritura incremental.** Una fase puede tener cientos de criaturas; reescribirlas todas al
tocar una seria absurdo. Editar una son DOS escrituras: su clave y el manifiesto. El precio es
que el manifiesto SI es lee-modifica-escribe y dos DM pueden pisarse; lo cubren la union al
escribir, el espejo local y `RebuildManifest`, que lo rehace desde el registro local **sin
borrar claves ajenas** y saltando las criaturas con tabla vacia (`PublishAll` tampoco las
escribe, asi que declararlas pondria en el manifiesto claves que no existen).

**Lectura con cache, y los FALLOS tambien se cachean** (60 s frente a 300 s de los aciertos).
La mayoria de criaturas no tienen tabla propia; sin esto cada cadaver vacio volveria a preguntar
y se comeria el cupo de lecturas.

Al resolver el loot, si el registro local no conoce la criatura se pide a la fase y se repite la
resolucion. **La tabla se guarda con la MISMA clave que usa la busqueda**: `id` es CADENA, sale
de `strsplit` del GUID, no numero. Con clave numerica no habria casado nunca y habria pedido en
bucle. Se reintenta solo si sigues mirando al mismo GUID.

`HarfordLootTaggedCreatureRegistry` **NO va a la fase**: es el loot YA TIRADO de un cadaver
concreto, se consume mientras la gente saquea, y sigue por `HARFORDLOOT`.

## Facciones En La Fase (2026-08-21)

`Harford/Reputation/HarfordReputationPhase.lua`. Sube SOLO el catalogo: `factions` y `groups`.
La reputacion acumulada de cada personaje (`players`) es personal y NO sale de su cliente;
`guilds`, `npcLinks` y `logs` son restos obsoletos y tampoco viajan.

**UNA sola clave (`HARFORD_REP_ALL`), no una por faccion.** El motivo no es el tamano sino la
longitud de clave: `HarfordReputation.NormalizeId` construye el id desde el NOMBRE sin truncar,
asi que con un prefijo por faccion un nombre de mas de ~82 caracteres pasaria del tope de 100 y
el servidor lanzaria error duro. Son pocas y cambian poco, asi que caben juntas.

Regla general derivada: **bloques por id SOLO si el id esta acotado**. Numerico (criaturas,
NPCs) lo esta; derivado de texto escrito por una persona, no.

## Cierre De Mision Desde El Tablon (2026-08-21)

Quien termina una mision de mundo la cierra en el tablon. `TurnInCurrent` avisa con `def.id`,
que ES el id del contrato (`TC.BuildWorldQuestDef` lo copia tal cual).

- **Oficial de fase** -> `Phase.CompleteContract` escribe directamente.
- **No oficial** -> `Comm.ReportCompletion` manda `TCDONE` por susurro al lider del grupo, o al
  canal si no hay lider identificable, y quien pueda la cierra. Es idempotente.

**Para esto la escritura es de OFICIAL, no de DM**: quien remata una mision suele ser un jugador
normal. `CompleteContract` toca SOLO ese contrato -- su bloque y su fila del indice, dos
escrituras -- en vez de republicar, para que un oficial sin el tablon local al dia no pise nada.
El bloque se LEE, se le cambia el estado y se devuelve: reescribirlo desde el contrato local
perderia cambios de otro DM que este cliente no tenga.

El tablon tiene seccion "Completadas" y las terminadas salen de las categorias normales.

## Mapa Vivo De Permisos Y Comandos Epsilon

Este mapa queda preparado para rellenarlo cuando confirmemos comandos reales del servidor Epsilon. No inventar comandos ni permisos: documentar aqui cada comando cuando se pruebe o se confirme.

Capacidades:

- `member`: personaje con rango member/officer/owner en la phase actual.
- `officer`: personaje con rango officer/owner en la phase actual.
- `admin`: addon `HarfordAdmin` instalado y cargado.
- `dm`: modo DM activo via `.ph dm on/off`, independiente del rango de phase.

Plantilla por comando:

```text
capacidad:
  - accion: Nombre funcional en Harford
    comando: comando epsilon sin punto inicial
    modulo: archivo Lua que lo usa
    callback: si/no
    respuesta: formato esperado de messages, si aplica
    estado: pendiente/probado/confirmado
    notas: validaciones necesarias o riesgos
```

Mapa inicial:

```text
member:
  - pendiente: recopilar comandos permitidos a miembros.

officer:
  - pendiente: recopilar comandos permitidos a oficiales/owner.

admin:
  - pendiente: recopilar comandos exclusivos de HarfordAdmin.

dm:
  - pendiente: recopilar acciones/comandos que dependan de .ph dm on.
```

Regla operativa:

- Antes de implementar una accion nueva que envie comandos Epsilon, anadir o actualizar su entrada en este mapa.
- Si todavia no se sabe la capacidad exacta, dejarla como `pendiente` y no bloquear gameplay existente hasta probarlo en juego.
- Cuando una accion pase a implementacion estable, preferir exponerla como funcion validada en `HarfordServerActions` o en un modulo admin especifico.

## SpellCreator / Arcanum API

`SpellCreator` esta instalado en `G:\Epsilon\_retail_\Interface\AddOns\SpellCreator`.

`ArcanumVaultView` es un addon auxiliar separado para leer datos de Arcanum desde `EpsilonLib.PhaseAddonData` y publicar flags de integracion con SpellCreator. Los parches directos sobre SpellCreator no se documentan aqui: usar `SPELLCREATOR_PATCHES.md` para reaplicarlos tras actualizaciones.

La API publica principal es el global `ARC`. Se inicializa en `SpellCreator/Constants.lua` y se amplia en `SpellCreator/API.lua`.

API Harford para ArcSpell/Arcanum:

- La API oficial de tiradas es `_G.DND5E_ARC_API` (alias publico `HarfordDnDAPI.Rolls`). No crear puentes paralelos.
- Compatibilidad antigua: `RollAbility`, `RollSave`, `RollSkill`, `RollInitiative` devuelven `total, crit`; `RollExpression` devuelve `total` o `false`.
- API estructurada: `RollAbilityEx`, `RollSaveEx`, `RollSkillEx`, `RollInitiativeEx`, `RollExpressionEx` devuelven tabla runtime `{ ok, kind, label, total, die, base, prof, misc, dice, modifiers, crit, mode, timestamp }` cuando aplica.
- Ultimo resultado local: `GetLastRoll`, `ClearLastRoll`, `LastTotal`, `LastCrit`, `LastIsCritical`, `LastIsFumble`, `LastMeets(dc)`, `LastFails(dc)`, `CheckLastRoll(op, value)`, `LastIsKind(kind)`.
- En SpellCreator, una accion Lua puede tirar (`DND5E_ARC_API.RollSkill("Sigilo")`) y una condicion posterior debe consultar (`return DND5E_ARC_API.LastMeets(15)`). **Las condiciones no deben llamar a `Roll...`**, porque se evaluan mas de una vez y duplicarian tiradas/chat.
- Las tiradas recibidas de otros clientes no pisan `_lastRoll`; solo tiradas locales generadas por Harford/esta API.
- Profesiones para ArcSpell: `HarfordProfessions.OpenStation(professionId)` abre la estacion filtrada por el **id de profesion** (`"herreria"`, `"alquimia"`, etc.), incluso si el PJ aun no la conoce; no otorga competencia ni evita `CanCraft`. `GetStationInfo(professionId)` devuelve una instantanea segura `{ id, name, kind, known, skill, tier }`. `GatherNode(recipeId, cooldownSeconds)` mantiene la puerta validada de los nodos de mundo.
- No se registran acciones ni categorias automaticamente en SpellCreator: los Sparks/ArcSpells llaman de forma explicita a las APIs publicas de Harford. Los datos entre clientes siguen viajando exclusivamente por protocolos Harford especificos y validados; no exponer envio arbitrario de mensajes.
- **EL XML DE BLIZZARD ES RECUPERABLE Y ES LA PRIMERA FUENTE, ANTES QUE LA SONDA.** El cliente de Epsilon es **Shadowlands 9.2.7 build 45745** (el `Interface: 45745` del toc es literalmente esa build), y el FrameXML de CADA build esta publicado en Townlong Yak:

      https://www.townlong-yak.com/framexml/45745/<Addon>/<Fichero>.xml
      https://www.townlong-yak.com/framexml/45745/<Fichero>.xml        (FrameXML raiz)

  Se sirve como HTML coloreado; se limpia con `re.findall(r'<li id="\d+">(.*?)</li>')` + quitar etiquetas + `html.unescape`. La lista de ficheros de un addon sale de su `.toc` (misma ruta). Copias limpias en el scratchpad de sesion `framexml/`.

  **Por que importa**: la sonda ve el RESULTADO ya calculado, no la DECLARACION. Confundir las dos cosas costo una tarde entera de la ventana de recetas:
  - Un `texCoord` mayor que 1 en la sonda **no es un dato de entrada**: es lo que el cliente calcula al pintar en mosaico. El XML lo declara como `horizTile="true" vertTile="true"` SIN texCoord. Copiar ese numero sin activar el mosaico estira el pixel del borde -> **bandas palidas**.
  - `SetTexCoord` sobre una textura de ATLAS **anula la region del atlas**. La sonda reporta ese texCoord porque `GetTexCoord()` lo devuelve resuelto; re-aplicarlo rompe la textura.
  - Los insets se declaran `useParentLevel="true"`: comparten nivel con el padre. Con nivel propio se dibujan por encima de los hermanos y **tapan el contenido**.
  - Muchas piezas son PLANTILLAS, no arte suelto: pestañas `TabButtonTemplate`, scroll `HybridScrollBarTemplate`, buscador `SearchBoxTemplate`, insets `InsetFrameTemplate`, marco `PortraitFrameTemplate`. Reproducirlas a mano con sus texturas nunca queda igual y ademas se rompe si el cliente no resuelve ese fileID.
  - Los **fileID numericos de la sonda no se resuelven para un addon** en Epsilon (salen verdes o en blanco) aunque el frame nativo los use: el nativo los carga por RUTA desde su XML. Traducirlos con `/harford debug run texpath`, que compara la ruta contra el fileID que la sonda leyo. Cuidado: los ficheros de pestaña estan INVERTIDOS respecto a su nombre (`HelpFrameTab-Active` = 132085, y el nativo usa 132086 para la activa) y `UI-Background-Marble`/`-Rock` tambien.

  - **Una Texture declarada SIN anclajes ni tamano dentro de un StatusBar SI se pinta**: el cliente la estira a la barra entera. Asi es el fondo translucido de las barras de habilidad — `<Texture parentKey="Background"><Color r="0" g="0" b="0.75" a="0.1"/></Texture>` en `Blizzard_TradeSkillUI.xml`, que la sonda del nativo mide a 447x14 en capa BACKGROUND. **No deducir que "no se pinta" porque la sonda lo de en 1x1: eso pasa cuando el frame capturado estaba OCULTO** y sus tamanos no estan resueltos (ocurrio con `ClassTrainerStatusBar` y me llevo a quitar un fondo que si existe). Sin ese fondo la barra se ve vacia a la derecha del relleno, sin carril. Ojo al alpha: el `ClassTrainerFrame` declara `a=0.5` para su fondo, pero su relleno es `0,0,1 a 0.5` — casi el mismo color, y la barra parece llena con valor 0. En Harford ambas barras usan el `a=0.1` del TradeSkillFrame, que es el que deja distinguir carril y relleno; es una desviacion deliberada del XML del entrenador.
  - **La maquetacion del detalle es CONDICIONAL, no estatica.** `Blizzard_TradeSkillDetails.lua` ancla `RequirementLabel` a `Description.BOTTOMLEFT (0,0)` por defecto y **solo** lo baja a `(0,-18)` cuando la receta trae descripcion de verdad. La sonda solo puede ver UNA de las dos ramas -la de la receta que estuviera seleccionada- y copiarla como valor fijo deja un hueco muerto en las recetas sin texto. Regla: si el XML declara un anclaje y la sonda mide otro, buscar el `SetPoint` en el Lua antes de dar por bueno el numero de la sonda. Constante relacionada: `SPACING_BETWEEN_LINES = 11`, que es de donde sale el hueco de 12 (11 + el pixel de alto de la fila vacia de enfriamiento) entre el requisito y `Materiales:`.
  - **UN ANCHO QUE MIDE LA SONDA NO ES UN ANCHO DECLARADO.** Es lo que ocupa un texto EN INGLES ya pintado. Copiarlo como `SetWidth` rompe en cuanto el texto cambia: el contador de material se partia en dos lineas con `12 /1` porque le puse los 26 que media `"0 /5"`, cuando `$parentCount` del XML se declara SIN `Size` y crece solo hacia la izquierda desde su `BOTTOMRIGHT`. Lo mismo con `RequirementLabel`, que tampoco declara `Size` -los 48 eran el ancho de `"Requires:"`, y `"Requiere:"` no mide igual-. Regla: antes de fijar un ancho, buscar `<Size x=...>` en el XML; si no esta, NO ponerlo. Y si el XML dice `<!-- width set in OnLoad -->`, el ancho se calcula en Lua y hay que copiar la FORMULA, no el resultado: `RequirementText:SetWidth(236 - RequirementLabel:GetWidth())`. Anchos SI declarados del detalle: `RecipeName` 230, `Description` 290, `SourceText` (instructor+coste) 290 con `GameFontHighlight`; `ReagentLabel` y `RequirementLabel` sin ancho.

  **Orden de trabajo correcto**: (1) XML de la build para saber COMO se declara y que plantillas hereda; (2) sonda `nativeprobe` para las MEDIDAS de la version concreta de Epsilon, que puede diferir del XML publico; (3) `texpath` si hace falta traducir un fileID; (4) `gen_frame_from_probe.py` para generar el armazon.

- Contrato `HarfordProfessionTrainerUI` (`Harford/Professions/HarfordProfessionTrainerUI.lua`): **replica del `ClassTrainerFrame` nativo**, reconstruida desde el XML REAL de la build 45745, no desde pantallazos. Fuentes guardadas en `RuleSource/framexml/`: `Blizzard_TrainerUI.xml` (el frame), `Blizzard_TrainerUI.lua` (constantes y pintado de fila) y `UIPanelTemplates.xml` (`UIServiceButtonTemplate`, que es la fila). **El entrenador nativo NO tiene panel de detalle a la derecha**: es UNA sola columna y cada fila lleva icono, nombre, un subtexto de requisito debajo y el precio a la derecha; el panel de detalle que tuvo Harford era invento propio y se retiro. Constantes: 7 filas visibles, fila 47 de alto, **318 de ancho sin barra de scroll y 298 con ella** (el nativo las estrecha al aparecer la barra, ver `ClassTrainerScrollFrameScrollBar.Show/Hide`). **Medidas CONFIRMADAS contra el cliente** con `/harford debug run nativeprobe trainer` (captura `ClassTrainerFrame/nativo`, 81 nodos): ventana **338x424**; Inset `TOPLEFT root +4,-60` / `BOTTOMRIGHT root -6,+26`; **scroll 320x330 anclado a `TOPLEFT` del Inset `+5,-5`** -el XML lo declara por `TOPRIGHT -5,+5`, pero lo que vale es lo que resuelve esta build-; barra de habilidad 136x18 en `TOPLEFT +64,-36`; boton de entrenar 80x22 en `BOTTOMRIGHT -6,+4`; desplegable de filtro 150x32 en `TOPRIGHT +6,-30`; borde de moneda 148x34 en `BOTTOMLEFT +5,-9` con el marco de dinero a `RIGHT +8,+6` de el (a `+8`, no a `-8`). **Las rutas de textura del XML SI resuelven en Epsilon**: `TrainerTextures` -> fileID 404984, borde de moneda -> 237619, mas `GuildFrame` y `UI-Character-Skills-Bar`. **Al aparecer la barra de scroll hay que estrechar DOS cosas, no una**: las filas (318 -> 298) *y* el propio scroll (320 -> 300, `ancho de fila + 2`), como hace `ClassTrainerScrollFrameScrollBar.Show/Hide`. Estrechando solo las filas, la barra queda colgando 14px fuera del borde derecho de la ventana. **Los textos NO usan las cadenas globales del cliente** (`REQUIRES_LABEL`, `FILTER`, `AVAILABLE`, `USED`, `ITEM_SPELL_KNOWN`): el cliente de Epsilon es enUS y saldrian en ingles dentro de un addon en castellano. El **filtro** replica los tres conmutadores nativos con sus valores por defecto (`TRAINER_FILTER_AVAILABLE = 1`, `UNAVAILABLE = 1`, `USED = 0`): **las recetas ya conocidas empiezan ocultas**. Fila (de `UIServiceButtonTemplate`): icono 36x36 en `LEFT +6`, nombre `GameFontNormal` con `TOPLEFT -> icono.TOPRIGHT +6,-1` y `RIGHT -> precio.LEFT -2`, subtexto `SystemFont_Shadow_Small` 240x30 en `LEFT -> nombre.LEFT +0,-19`, precio en `TOPRIGHT +5,-7`. Arte: atlas `Interface/ClassTrainerFrame/TrainerTextures` (fondo, fila, hover y seleccion son cuatro recortes del mismo fichero 512x512, coordenadas en el modulo), candado y trozos de la barra de habilidad desde `Interface/GuildFrame/GuildFrame`, barra 136x18 en `TOPLEFT +64,-36` con relleno `UI-Character-Skills-Bar` y `BarColor 0,0,1,0.5`. El fondo se ancla al scroll con el desborde exacto del nativo (`-3,+4` / `+3,-4`), no a un tamano fijo. Estados de fila copiados de `ClassTrainerFrame_SetServiceButton`: no disponible = icono desaturado + nombre gris + velo gris `MOD` al 0.55; ya conocida = subtexto `ITEM_SPELL_KNOWN` y SIN precio; disponible = nombre normal y precio, en rojo si no llega el dinero. **Desviacion consciente**: el precio usa `GetCoinTextureString` en una FontString en vez de `SmallMoneyFrameTemplate`; son los mismos iconos de moneda y evita depender de `MoneyFrame_Update`. Toda ruta pasa por `GetFileIDFromPath` antes de usarse y cae a un color plano si no existe; comprobar con `/harford debug run nativeprobe trainer`, que ademas carga `Blizzard_TrainerUI` (es de carga bajo demanda: se puede cargar SIN entrenador delante) y captura el frame con la sonda.
- **Competencias e Idiomas son rasgos AGREGADOS**: no se reparte una entrada por fuente. Raza, clase y trasfondo aportan a la misma bolsa, que `HarfordDnDFeatureEffects.GetProficiencies(profile)` ya devuelve sumada (`armor`, `weapon`, `tool`, `saves`, `skills` con rango); los idiomas salen de `HarfordDnDProgression.GetImportedProficiencies(profile).languages`. Cada rasgo de origen sigue mostrando SU texto y nada mas; el listado completo vive en el tooltip de `Competencias` y de `Idiomas`. **Una seccion sin contenido no se pinta** (nada de "Herramientas: -"), y la pericia (rango 2) va aparte de la competencia (rango 1). Se reconocen por NOMBRE, no por id, porque cada raza declara el suyo (`hum_idiomas`, `ena_idiomas`...). El bloque vive dentro de un `do...end` y expone UNA sola funcion, `HarfordCharacterPanel.AddAggregatedFeatureTooltip`: `HarfordCharacterPanel.lua` esta EN el limite de 200 locales de Lua 5.1 y anadir seis lo rompio (`too many local variables`).
- **Los rasgos con `choice` muestran SOLO la eleccion**: el titulo pierde el sufijo entre parentesis (`Incremento de caracteristica (+2)` -> `Incremento de caracteristica`) y el subtexto es la eleccion a secas (`Sabiduria +2`), sin el `Pasiva - Eleccion:` delante. Los dos incrementos del humano quedan con el mismo titulo y se distinguen por su eleccion, que es lo util. El recorte solo afecta a un parentesis FINAL: `Ataque (a distancia) mejorado` se queda intacto. La categoria sigue en el tooltip y en el marco del icono. Separadores del subtexto -tanto el de varias elecciones como el previo al contador de usos- en gris y con la barra ESCAPADA (`|cff888888|||r`): una `|` suelta es prefijo de secuencia de escape y no se pinta.
- **Selector de basica en el paperdoll (flecha + rejilla): medidas del nativo.** La flecha NO es la del template tal cual — `EquipmentFlyoutPopoutButtonTemplate` nace 16x32 anclado `LEFT->RIGHT`, pero `PaperDollItemSlotButton_OnLoad` la reconfigura **por hueco**, y hay DOS orientaciones (`VERTICAL_FLYOUTS`):
  - **Vertical (manos)**: flecha **38 de ancho x 16 de alto** en `TOP -> hueco.BOTTOM (0, +4)`, apuntando ABAJO, y la rejilla se abre DEBAJO (`TOPLEFT -> flecha.BOTTOMLEFT`, `verticalAnchor 0,0`). TexCoords de CUATRO numeros: cerrada `(0.15625, 0.84375, 0.5, 0)`, abierta `(0.15625, 0.84375, 0, 0.5)` — el arriba/abajo invertido es lo que hace que apunte hacia abajo.
  - **Horizontal (pecho)**: **16 de ancho x 38 de alto** en `LEFT -> hueco.RIGHT (-8, 0)` -metida 8px SOBRE el hueco- y la rejilla a su derecha. TexCoords de OCHO numeros, que ademas giran el recorte 90 grados: cerrada `(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0)`.
  Textura `UI-GearManager-FlyoutButton` en ambas; al abrirse se invierten (`EquipmentFlyoutPopoutButton_SetReversed`). **Los texCoords se aplican a la textura que creamos, NO via `GetNormalTexture()`**: ese camino llevaba un guard `if not (n and h) then return end` que se lo tragaba en silencio, y sin recorte la textura sale entera y estirada — una banda amarilla en vez de una pestana. El **resaltado del hueco mientras el menu esta abierto** es `UI-GearManager-ItemButton-Highlight` a 50x50 (`EquipmentFlyoutFrame.Highlight`). Rejilla: `ITEMS_PER_ROW=5`, item 37x37, `XOFFSET=4`, `YOFFSET=-5` (paso vertical 42), `BORDERWIDTH=3`, y se ancla a la DERECHA de la flecha (`TOPLEFT -> popoutButton.TOPRIGHT`), no debajo. Tamano: ancho `(n*37)+((n-1)*4)+3`, alto `43 + (filas-1)*42`; cada icono en `(3 + col*41, -(3 + fila*42))`. **El fondo NO es un marco generico**: se monta por piezas de `UI-GearManager-Flyout` con recortes distintos segun haya UN hueco (izq 25 + der 24, alto 54), UNA fila (izq 43 + centros 41 + der 47, alto 54) o VARIAS (arriba 49 / medios 42 / abajo 49, ancho 214), todas arrancando en `TOPLEFT (-5, +4)` de la rejilla. **El flyout nativo no lleva titulo**: cada icono se identifica por su tooltip. **El resaltado del hueco va DETRAS, no encima**: el nativo lo pinta en el frame del flyout, que monta a `itemButton:GetFrameLevel() - 1`, asi que asoma como un halo alrededor y el icono y el borde quedan por delante; en `OVERLAY` tapaba las dos cosas y parecia descuadrado aunque estuviera centrado al pixel (medido con `/harford debug run selectorhl`: desvio 0.0/0.0). Hueco 37x37 y borde `UI-Quickslot2` 64x64 en `CENTER (0,-1)`, igual que `ItemButtonTemplate`. **La rejilla cuelga de `UIParent` con strata `FULLSCREEN_DIALOG`**: dentro del arbol del panel quedaba por debajo del marco exterior, porque el `NineSlice` del panel es un frame hijo con nivel superior; como ya no se oculta con el panel, el hueco engancha su `OnHide`. Fuentes en `RuleSource/framexml/`: `EquipmentFlyout.xml`, `EquipmentFlyout.lua`, `PaperDollFrame.lua`. Contenido decidido: dos pasos (categorias -> piezas), solo basicas del catalogo, y el pecho igual que las manos.
- **El scroll NO recalcula datos: separar MODELO de PINTADO.** La lista de recetas reutiliza 25 botones para cientos de recetas (lista virtual), asi que al hacer scroll SI hay que repintar esos 25 botones — pero nada mas. `ConstruirModelo(def)` (filtrar, ordenar, cabeceras de rango) corre UNA vez y queda en `state.model`; `InvalidarLista()` lo tira, y lo llaman solo las cosas que cambian el contenido: `RefreshUI` (pestana, busqueda, filtro, fabricar, bolsas) y plegar un rango. El scroll llama a `RefreshList` a secas y reaprovecha el modelo. Ademas, la cantidad fabricable `[N]` se cachea por receta en `state.craftableCache`, asi que `CanCraft` corre como mucho una vez por receta y no 25 por muesca. **Medido con el catalogo real (254 recetas, ninguna aprendida, que es el caso lento):** antes cada muesca costaba ~8 ms (20 `CanCraft`, cada uno resolviendo el entrenador a 0.28 ms); ahora 10 muescas hacen 10 `CanCraft` -uno por fila nueva- y CERO reconstrucciones, y volver atras hace 0.
- **`HarfordProfessionTrainers` memoiza `Get(trainerId)` y `GetForRecipe(recipeId)`.** Que entrenador ensena cada receta sale de datos estaticos (catalogo + `PLACED`), pero resolverlo obliga a construir el entrenador, y comprobar que ese par profesion/rango tiene recetas **recorre las 1614 del catalogo**. Sin memoizar, cada fila que entraba en pantalla al hacer scroll disparaba ese escaneo completo. `API.OlvidarCache()` limpia ambas y lo llama `HarfordProfessions.DefineRecipe`, que es lo unico que puede cambiar el reparto en caliente.
- **Las flechas de `HybridScrollBarTemplate` NO valen sobre nuestras listas.** Su `OnClick` sube dos padres buscando un `HybridScrollFrame` de verdad y llama a `HybridScrollFrame_OnMouseWheel`, que necesita `stepSize`/`buttonHeight`/`range`. Nuestras listas se desplazan por INDICE de fila con `state.offset`, no son frames hibridos, y al pulsar la flecha saltaba `HybridScrollFrame.lua:67: attempt to perform arithmetic on local 'stepSize' (a nil value)`. Solucion: sustituir el `OnClick` de `slider.ScrollUpButton`/`ScrollDownButton` por uno propio que SOLO mueve el valor del slider — el clamp lo hace el Slider y el refresco lo dispara su `OnValueChanged`. En `HarfordProfessionsCraftUI` esta el helper `WireScrollArrows(slider, paso)`; paso 1 para la lista (filas) y 20 para el detalle (pixeles, el mismo que ya usaba la rueda). `HarfordProfessionTrainerUI` lo hace en linea. **Cualquier barra nueva creada desde plantilla necesita esto**, aunque la rueda del raton funcione: la rueda va por nuestro `OnMouseWheel`, las flechas no.
- **El bonus de competencia se pide con `HarfordDnDCalc.GetPB()`, NO con `GetProficiencyBonus`** (esa no existe en `HarfordDnDCalc`; vive en `HarfordDnDFeatureEffects` y en `HarfordDnDProgression`, con otra firma). `ProfBonus` de `HarfordProfessions` la llamaba mal y el guard `if HarfordDnDCalc and HarfordDnDCalc.GetProficiencyBonus then` caia al `return 0` **en silencio**: ni la tirada de profesion ni la de FABRICAR sumaban competencia. `GetPB()` ya resuelve contexto NPC, efectos de rasgos y el valor de la ficha. Respaldo si no hay ficha: `HarfordDnDProgression.GetProficiencyBonus(nombre)`. Este es el patron de fallo a vigilar: un `and`-guard sobre una funcion que no existe no da error, simplemente devuelve el neutro.
- **Requisito en la ventana de entrenador: formato del nativo.** `TRAINER_REQ_SKILL_RANK` es `"%s (%d)"`, asi que con el prefijo de la fila queda `Requiere: Alquimia (50)`. La etiqueta que devuelve `GetRecipeState` NO debe repetir la palabra "Requiere" ni describir la carencia en prosa; antes salia `Requiere: Requiere 50 de habilidad`.
- **Cada profesion tiene UN solo boton en la pagina de profesiones** (`spellOpen`, abre la ventana de recetas) y va en el hueco de ABAJO del slot grande (`TOPRIGHT -109,-43`; en el slot pequeno no cabe esa segunda fila y se queda en `-3`). El segundo boton (`spellTool`, tirada de herramienta) fue retirado al mover la tirada al boton de dado.
- **Enlaces de objeto: nombre del CATALOGO, no el del cliente.** `HarfordProfessionsItems.GetChatLink(key)` NO devuelve el link de `GetItemInfo`: ese trae el nombre del cliente, que en Epsilon esta en ingles. Construye el hyperlink a mano -`<color>|Hitem:<id>|h[<nombre castellano>]|h|r`- porque WoW pinta el texto entre corchetes tal cual y resuelve el objeto por su ID: sigue siendo clicable y con tooltip. De `GetItemInfo` solo se aprovecha el color de calidad (`ITEM_QUALITY_COLORS`). La tirada de fabricar usa ese enlace en su etiqueta.
- **Barra de fabricacion: medidas de la sonda `CastingBarFrame/nativo`.** Barra **195x13**, `BOTTOM -> UIParent.BOTTOM (0, +160)`, strata **HIGH** (si el jugador movio la nativa se copia su punto con `GetPoint(1)`). Relleno **`Interface/TargetingFrame/UI-StatusBar`** — el nativo NO usa `UI-CastingBar-Fill`, que ademas ni siquiera resuelve en este cliente. Chispa `UI-CastingBar-Spark` 32x32 en `CENTER (0,+2)`. **El marco es una textura de TAMANO FIJO 256x64 anclada por su `TOP` al `TOP` de la barra con `+28`**: NO se estira con `TOPLEFT`/`BOTTOMRIGHT`. Estirarla la deformaba a 241x53 y por eso el relleno parecia salirse del marco — el arte ya trae su propio margen alrededor de los 195x13 utiles. El marco vive en un frame aparte por encima para que el avance del relleno no lo corte.
- **El tooltip de la tirada nombra la CARACTERISTICA real** (`def.ability` del catalogo): "d20 + Bonus Competencia + Mod. Inteligencia". Las 30 profesiones la tienen declarada.
- **Tirada de profesion: UNA sola entrada, el boton de dado de la ventana de recetas.** Ocupa el sitio, el tamano y el resaltado del `LinkToButton` nativo (30x30 en `BOTTOMRIGHT` del boton de filtro `+3,+1`, resaltado `UI-Common-MouseHilight` en ADD) pero con `INV_Misc_Dice_01`: ahi no se enlaza la profesion al chat, se tira. La regla NO vive en la UI: llama a `HarfordProfessions.RollTool(profId)`, que es d20 + bonus de competencia + modificador de caracteristica, el MISMO modificador que usa fabricar. La tirada se emite en mesa con `HarfordDnDRolls.Broadcast` y su etiqueta es el nombre de la PROFESION (`Alquimia`, `Herreria`), no el de la herramienta. **El segundo boton de "Suministros de ..." de la pagina de profesiones fue RETIRADO**: tener dos entradas dejaba dos formas distintas de tirar lo mismo. La textura pasa por `SafeTexture`, que oculta y anota si la ruta no existe en el cliente en vez de pintar el cuadrado verde.
- **Iconos de arma: la WEB manda, y el flujo es web -> addon** (`tools/codice/importar_iconos_armas.py`). Lee `C:/Users/marco/Documents/harfordweb/js/compendium-equipment.js` -ojo, la web canonica esta en `Documents/harfordweb`, NO en `D:/Azerothcore/harfordweb`, que es el sitio de rol- y escribe `icon="..."` en cada entrada de `HarfordDnDWeapons.WEAPONS`. Empareja por nombre normalizado (sin tildes ni apostrofes) y NO inventa nada: lo que no cuadra lo lista. Acepta tambien `kind="armor"` porque el `Escudo` esta en la tabla de armas del addon pero en la web es armadura. Corre en simulacion por defecto; `--escribir` aplica. Cubre las 52 armas. El acceso desde codigo es `HarfordDnDWeapons.GetIconPath(def)`, **que esta enganchado al resolutor del compendio** (`HarfordCompendioAPI.ResolveRP3IconName`, que busca el nombre en LibRPMedia, lo mapea a fileID y cachea). Orden: fileID o ruta ya completa -> resolutor -> ruta `Interface/Icons/<nombre>` comprobada con `GetFileIDFromPath` -> `INV_Misc_QuestionMark`. Puede devolver un NUMERO (fileID) o una cadena; `SetTexture` acepta ambos. **Nunca devuelve una ruta sin comprobar**, que es lo que pinta el cuadrado verde. Los genericos por tipo de arma (`INV_Sword_04` para todo cuerpo a cuerpo) que habia en `GetWeaponIcon` de `HarfordDnDItems` quedan solo como red de seguridad para entradas sin campo `icon`; antes hacian que los huecos del paperdoll se vieran todos iguales. Comprobar en cliente con `/harford debug run armasiconos`, que pregunta al MISMO resolutor. **No confundir con `extract_equipment.py`, que va al reves (addon -> web) y no debe ejecutarse sin coordinacion.**
- **Auditoria XML vs implementacion** (`tools/codice/auditar_xml.py`): parsea un FrameXML y saca el inventario COMPLETO de cada elemento declarado (tipo, herencia, `Size` o "SIN DECLARAR", todos los anclajes, `Color`, `TexCoords`, `alphaMode`, `hidden`, `justifyH/V`, capa, `useParentLevel`) incluidas `NormalTexture`/`HighlightTexture`/`BarTexture`. Es la forma de repasar una replica entera sin ir a ojo. Repaso hecho (2026-08) sobre `Blizzard_TrainerUI.xml`, `UIPanelTemplates.xml` (`UIServiceButtonTemplate`), `Blizzard_TradeSkillUI.xml`, `Blizzard_TradeSkillDetails.xml` y `Blizzard_TradeSkillRecipeButton.xml`: todo cuadra salvo lo anotado arriba. Piezas nativas declaradas que Harford NO reproduce a proposito, por no aplicar: `ClassTrainerFrameSkillStepButton` (316x40, recetas multi-rango), `ClassTrainerFrameBottomInset`, las estrellas de rango (`TradeSkillRowStarTemplate`, `TradeSkillDetailsStarTemplate`), `SkillUps`/`LockedIcon`/`SubSkillRankBar` de la fila de receta, el tabardo de hermandad del `TradeSkillFrame` y `RetrievingFrame`/`Spinner`. Desviaciones deliberadas y ya documentadas: buscador en x=230 (el XML dice 220), precio del entrenador con `GetCoinTextureString` en vez de `SmallMoneyFrameTemplate`, y fondo de barra a alpha 0.1 en el entrenador (su XML dice 0.5). **Ojo**: el XML del entrenador declara `ClassTrainerTrainButton` en `BOTTOMRIGHT (0,0)` pero en vivo resuelve a `-6,+4`; manda la sonda.
- **Investigacion de UI nativa (reps y profesiones):** herramienta UNICA `/harford debug run nativeprobe` (el antiguo `nativeprof` quedo absorbido como subopciones; no recrear comandos sueltos). Subcomandos: `status` (que frames existen: ReputationFrame, TradeSkillFrame/ProfessionsFrame/CraftFrame, APIs, estado del soundlog); `rep [etiqueta]` (captura probeframe de ReputationFrame y, si esta visible, ReputationDetailFrame); `prof [etiqueta]` (captura de datos `nativeProfessionProbes` + probeframe del frame de profesion visible); `sound on|off|show|clear` (hookea PlaySound/PlaySoundFile y anota los soundkits que dispara la UI, persistidos en `HarfordDebugSettings.soundLog`, max 400 — el hook es permanente en la sesion, el flag decide si anota); `events on|off` (eventos de profesion nativa). Flujo: con el frame nativo abierto, `sound on`, interactuar, capturar estados con `rep`/`prof` y `/reload` para persistir. Sin abrir, seleccionar ni ejecutar una receta desde el diagnostico. Comparar varias etiquetas antes de decidir si se integra el frame nativo o se reproduce su geometria. `harford [etiqueta]` captura NUESTRAS ventanas (`HarfordProfessionsCraftFrame`, `HarfordSkillsPanelFrame`) con la MISMA sonda; si la ventana de recetas no existe la abre con la primera profesion conocida. Ese es el flujo de trabajo correcto para ajustar fidelidad: capturar nativo + capturar el nuestro y DIFFEAR los arboles dato a dato (posicion/tamaño/textura/coord/fuente/vertexColor), en vez de iterar a ojo sobre pantallazos. Ojo: la geometria puede coincidir y aun verse mal — comprobar tambien `vertexColor`, `alpha`, `drawLayer` y `visible` de cada region, que es donde han estado los fallos reales (borde blanco de reactivo que el nativo tiene OCULTO, relleno de barra a alpha 0.5, fondos estirados).

- **Crafteo UNO POR UNO y reserva de material en vuelo** (anti-duplicacion): `RemoveItem` es un comando de servidor ASINCRONO, asi que entre craftear y que el servidor descuente, `GetItemCount` sigue devolviendo el valor viejo. Encadenar crafteos a ciegas permitiria fabricar con material ya gastado. Dos defensas, y las dos deben mantenerse: (1) en el CORE, `HarfordProfessions` apunta lo consumido en una tabla `reserved` e `InspectMaterials` lo RESTA del `have`, de modo que `CanCraft` es honesto aunque las bolsas no se hayan actualizado; la reserva se libera cuando `BAG_UPDATE`/`BAG_UPDATE_DELAYED` confirma el recuento esperado o al expirar `RESERVE_TTL` (15s) si el comando se perdio. Va en el core y no en la UI porque `Craft` tambien lo llaman ArcSpells y gossips. (2) en la UI, pedir varias unidades ENCOLA: nunca hay dos crafteos en vuelo, cada pieza espera la confirmacion de bolsas de la anterior (tope `MAX_QUEUE` 20, timeout 6s que corta la cola avisando). **Los materiales solo se gastan por crafteo COMPLETADO**: una tirada fallida no consume nada, no reserva nada y corta la cola. No sustituir la cola por un bucle sincrono ni quitar la reserva: ambos reabren la duplicacion. Diagnostico: `HarfordProfessions.GetReservedMaterials()`.

- **Crafteo verificado contra el servidor (no dar por hechos los comandos)**: `RemoveItem`/`GiveItem` devuelven `(ok, err)` y `HarfordProfessions.Craft` los COMPRUEBA. Antes los llamaba a ciegas, y eso daba objeto gratis si fallaba el descuento, o materiales perdidos en silencio si fallaba la entrega. Orden obligatorio: (1) comprobar que existe canal de servidor ANTES de tirar, para no gastar la tirada; (2) descontar material a material mirando el resultado; (3) si uno falla, DEVOLVER lo ya descontado, liberar la reserva y cancelar sin dar el objeto ni subir skill; (4) entregar el resultado y, si falla con los materiales ya gastados, decirlo claramente en vez de fingir exito. No simplificar esto a un `for` sin retorno.

- Contrato de **RECETAS DINAMICAS** (`DefineRecipe` / `TeachCustomRecipe` / `ForgetCustomRecipe` / `GetCustomRecipes` / `PruneCustomRecipes`): recetas que NO estan en `HarfordProfessionsData`, para contenido puntual (plano de un jefe, receta de evento, recompensa de mision). Un ArcSpell/gossip llama a `TeachCustomRecipe(def)` y la receta queda definida Y aprendida en ese personaje, persistida en `HarfordProfessionsStore.custom`. A partir de ahi se comporta como cualquier otra: sale en la ventana, comprueba materiales, tira en mesa, sube skill. **No hay una ruta de crafteo paralela.** Materiales y resultado se pueden dar por **itemId directo** (lo normal en contenido suelto); se registran al vuelo con clave sintetica `din_<id>` para que el resto del sistema no sepa que son dinamicas. Reglas que aplica `DefineRecipe` y que NO se deben quitar: no puede pisar un id del catalogo (romperia las recetas horneadas de todos); una receta que devuelve mas unidades del MISMO objeto que consume se rechaza (dinero infinito); una receta que no es de recoleccion necesita materiales; siempre `worldLearned` (hay que aprenderla, no se desbloquea por skill). Se podan a 100 por personaje sacrificando primero las que ni se aprendieron, de la mas antigua a la mas nueva. **Viajan por red con su DEFINICION COMPLETA** (`TEACHDEF|id|prof|skillReq|dc|icono|outId:qty|matId:qty,...|nombre`, nombre al final porque puede contener cualquier cosa menos `|`): `TEACH|id` no sirve para ellas porque el receptor no las tiene en su catalogo. Si no cabe en el limite de `SendAddonMessage` se avisa en vez de mandar un mensaje truncado. El receptor NO confia en el mensaje: lo pasa por `DefineRecipe`, asi que todas las validaciones se aplican igual. Diagnostico: `/harford debug run customrecipe list|demo|forget <id>`.

- **Crafteo UNO POR UNO, reserva y cola**: ver el contrato de material en vuelo mas abajo. Ademas, la cola de la ventana se ata a la receta con la que EMPEZO (`queue.recipeId`): leer `state.selected` en cada pieza hacia que cambiar de receta a mitad fabricase otra cosa gastando materiales ajenos. El cooldown de nodo se indexa por `NPCID:spawnUID` extraidos del GUID, no por el GUID entero, que lleva servidor/instancia y cambia al reiniciar (regalaba la veta). `GetRecipe` usa un indice por id: la ventana lo llama una vez por fila visible y el buscador refresca en cada tecla.

- Contrato `HarfordProfessionsCraftUI` (`Harford/Professions/HarfordProfessionsCraftUI.lua`): ventana propia de recetas (`HarfordProfessionsCraftFrame`), replica del TradeSkillFrame moderno segun la sonda `nativeprobe prof`. Solo UI: TODOS los datos y acciones pasan por `HarfordProfessions` (`GetRecipes`/`CanCraft`/`Craft`/`IsRecipeLearned`/`EffectiveSkill`/`GetOutputItemId`); no lee SavedVariables ni ejecuta comandos de servidor por su cuenta. Se abre desde el sello de profesion del libro (`HarfordProfessionsCraftUI.Open(profId)`). Geometria hardcodeada del nativo, con los valores que costaron varias pasadas: ButtonFrameTemplate 670x496 con su Inset propio OCULTO y **dos insets** en su lugar (izquierdo 325x410 en `+4,-80`, derecho 335x390 en `TOPRIGHT -6,-80`); barra de skill 447x14 **centrada** (`TOP +0,-33`) con borde en TRES piezas de `136571` (caps 9x20 a -3/+3 + centro estirado) y relleno `136570` azul a **alpha 0.5 sin fondo negro**; lista `+7,-83` de filas 300x16 (FRIZQT 12 a LEFT +6) con cabeceras de grupo por tier en ORO y contador a la derecha; scrollbar con riel `136569` en 3 piezas + thumb `130849`; reactivos en botones 147x41 encadenados (icono 39 SIN recorte, `UI-QuestItemNameFrame` 128x64 a `icono.RIGHT -10`, nombre FRIZQT 12 a `NameFrame.LEFT +15`, contador ARIALN 14 OUTLINE con formato `0 /15`) — el borde `auctionhouse-itemicon-border-white` esta OCULTO en el nativo, **no mostrarlo**; icono de receta 47x47 en `+10,-20` con `tradeskills-iconborder` 51x51 CENTRADO (no del mismo tamaño); fondo del detalle `tradeskill-background-recipe` a tamaño FIJO 310x383 en `-5,0` (estirarlo deforma el pergamino). El numero entre corchetes de cada fila es la CANTIDAD FABRICABLE con los materiales actuales, nunca el requisito de skill. Pestañas Aprendidas/No aprendidas (arte HelpFrameTab `132086`/`132085`) filtran por `IsRecipeLearned`; la caja de busqueda filtra por nombre con `HarfordClassColors.StripAccents`. Los iconos del catalogo que no existen en Epsilon se validan con `GetFileIDFromPath` y caen al icono del item resultante (evita el cuadrado verde).

- Contrato `HarfordProfessionFX` (`Harford/Professions/HarfordProfessionFX.lua`): TODA la presentacion de una fabricacion -animacion, sonido, auras, emotes- vive aqui, no en `HarfordProfessionsCraftUI`, que es solo UI y no debe saber que suena cada profesion. Cuatro fases: `Begin(profId, estado)` al empezar la barra, `Tick(estado, dt, total)` desde el OnUpdate que YA mueve la barra, `Finish(estado, exito)` al resolver la pieza y `Stop(estado)` al cerrar la tanda, que devuelve `nil`. El `estado` es de la TANDA y no de la pieza: `Begin` recibe el anterior y NO relanza la animacion entre unidades encadenadas, porque devolverla y volver a pedirla daba el parpadeo 69-13-69 en cada pieza; solo `Stop` devuelve la 13. Sonidos en `PERFILES`: alquimia 1105, mineria 1166, desollar 3781, peleteria 6426, herboristeria 1104, sastreria 6425, ingenieria 7141, inscripcion 6426, joyeria 10589, encantamiento 27 con remate 3084. Cada profesion puede declarar ademas `alInicio`/`alMedio`/`alFinal`/`alSoltar` para hacer lo suyo (aura, emote, lo que sea) sin tocar la ventana; `alMedio` se dispara UNA vez al pasar la mitad de la barra. El casteo dura 5 s.
- **Bucle de sonido de fabricacion: por EVENTO, nunca por temporizador.** El juego base no resuelve esto en Lua -el sonido es parte de los datos del hechizo, de ahi que los ids sean los `precast` de cada oficio, y el motor lo mantiene sonando mientras dura el lanzamiento-. Desde Lua no hay modo bucle, pero `PlaySound(id, canal, sinDuplicados, avisarAlTerminar)` con el CUARTO argumento a `true` hace que el cliente dispare `SOUNDKIT_FINISHED` con el manejador al acabar ese sonido; encadenando ahi se repite exacto, sin solape ni silencio y sin saber cuanto dura. Confirmado en este cliente: lo usan `SpellCreator/Actions/Data_Scripts.lua` y `Epsilon_Merchant/SoundPicker.lua`. **No reintroducir un `cada`/`C_Timer`/ticker para repetir el sonido** (se probo y se retiro: era una estimacion a ojo de la duracion). **El corte es `StopSound(manejador)` sobre el que devolvio `PlaySound`** -mismo patron que SpellCreator- y vive en `API.CutSound`, que llama `CancelCast` de la ventana: por ahi pasan TODAS las salidas del casteo (completarse, moverse, cerrar la ventana), asi que el sonido muere con la barra y NO sigue sonando mientras se tira el dado ni mientras se descuentan materiales. `Finish` vuelve a cortar por si acaso (es idempotente) y solo entonces lanza el remate. El unico sonido que puede seguir despues es `sonidoExito`, y solo si acerto. **`fx` se declara ANTES de `CancelCast`**: un cierre solo captura las locales que ya existen al crearse, y declarada despues seria una global `nil` ahi dentro. Un aviso que llegue tarde, despues de `Stop`, no revive el bucle.
- **Al partir un refresco en dos, revisar las locales que cruzan.** `RefreshDetail` se quedo usando `recipes`, que era local de `RefreshList`: con ella `nil`, `ipairs` reventaba y el panel de detalle no se repintaba nunca. La receta seleccionada se pide por id con `HarfordProfessions.GetRecipe(state.selected)`, no recorriendo una lista de la otra mitad.
- **Refresco de la ventana de recetas, partido en dos (rendimiento):** `RefreshList` rehace cabecera, filtro, orden y filas; `RefreshDetail` rehace el panel de la derecha; `RefreshUI` es las dos. **El scroll -rueda y slider- llama SOLO a `RefreshList`**. Antes era una unica funcion y cada muesca de rueda reconstruia tambien el detalle entero: icono de la receta, todos los iconos de material, tooltips y linea de instructor, aunque la seleccion no hubiera cambiado. Eso hundia los fps. Medido con los datos reales del catalogo (1614 recetas, 254 en la profesion mas grande), la parte de DATOS de un refresco cuesta 0,42 ms: `GetRecipes` 0,03, filtro 0,09, `table.sort` 0,17, cabeceras 0,05 y `CanCraft` de las 20 filas visibles 0,07. **El coste no estaba en los datos sino en las texturas**: el retrato solo se recarga al cambiar de profesion (`frame._retratoDe`), y el boton de plegar de cada fila monta su resaltado y su `OnClick` UNA vez al crear la fila -el rango viaja en `row.tier`- y solo cambia la textura normal cuando de verdad cambia de estado (`row._plegado`). No volver a poner `SetNormalTexture`/`SetHighlightTexture` por ruta ni crear cierres por fila dentro del refresco.
- La linea `Requiere:` del detalle lleva SOLO sitio y herramienta, como el `Requires: Anvil, Blacksmith Hammer` nativo. No añadir ahi los motivos de `CanCraft`: los materiales que faltan ya los pintan los huecos en rojo, y la habilidad y donde se aprende los dice la linea de instructor. La etiqueta `Materiales:` NO usa el ancho nativo de 54 (le vale a `Reagents:`, no al castellano): va sin ancho fijo, anclada solo por la izquierda.
- **Panel de detalle de receta, medido de la sonda (no volver a estimarlo):** el panel es `root.f6.f9` de la captura `TradeSkillFrame/nativo`, 300x232. Todas las cadenas son Friz Quadrata sin contorno; los FontObject con nombre NO valen porque los tamanos no coinciden con ninguna escala unica, asi que se fijan con `SetFont` a mano. Nombre 230x14 blanco LEFT/MIDDLE en `TOPLEFT +65,-20`; icono 47x47 en `TOPLEFT +10,-20`; descripcion 290 de ancho, Friz 11, blanco, LEFT/MIDDLE, en `TOPLEFT +8,-85` **fija** (con texto vacio mide 0 de alto y lo de abajo sube solo: NO ocultarla ni re-anclarla); `Requiere:` 48x10 Friz 10 **CENTER**/MIDDLE en oro `1/0.82/0` a `desc.BOTTOMLEFT +0,-18`; su VALOR 188x10 Friz 10 LEFT/**TOP** blanco a `etiqueta.TOPRIGHT +4,+0`, con el rojo del requisito no cumplido **en linea** dentro del texto (`|cffff2020`), nunca por `SetTextColor`; `Materiales:` 54x10 Friz 10 CENTER/MIDDLE oro con **DOS** anclajes, `TOP -> valor.BOTTOM +0,-12` y `LEFT -> etiqueta.LEFT` (el -12 es el hueco que deja la fila de experiencia del nativo, oculta pero con sitio reservado); huecos de material 147x41 con el primero en `Materiales.BOTTOMLEFT -5,-6`, paso 147 en x y 43 en y, contador 26x14 ARIALN 14 OUTLINE RIGHT/MIDDLE a `icono.BOTTOMRIGHT -1,+1`. **Instructor y coste son UNA SOLA FontString** de 290 de ancho, Friz 12, blanco, LEFT/MIDDLE, con las dos lineas unidas por `|n` y las etiquetas en oro dentro del texto (`|cFFFFD200`); el coste usa `GetCoinTextureString`. Lleva tambien **DOS** anclajes: `TOP -> ultimoHueco.BOTTOM +0,-15` y `LEFT -> Materiales.LEFT`. Ese segundo punto es obligatorio: con solo el `TOP` la linea queda centrada sobre el ultimo hueco y se desplaza a la derecha cuando la ultima fila tiene una sola columna. La cadena completa esta verificada contra la captura posicion a posicion.

Comandos:

- `ARC:CMD(command)` / `ARC.CMD(command)`: ejecuta comandos simples de servidor.
- `ARC:COMM(command)` / `ARC.COMM(command)`: alias legacy de `CMD`.
- Uso esperado: comandos fire-and-forget, sin callback ni parseo de respuesta.
- Nota: internamente acaba usando `SendChatMessage`, no devuelve `success/messages`.

Variables runtime:

- `ARC:SET(key, value)`: guarda un valor en `ARC.VAR`.
- `ARC:GET(key)`: lee un valor de `ARC.VAR`.
- `ARC:TOG(key)`: alterna un valor boolean-like en `ARC.VAR`.
- `ARC:IF(key, cmdTrue, cmdFalse, var1, var2)`: ejecuta comandos segun si `ARC.VAR[key]` existe/es true.
- `ARC:IFS(key, value, cmdTrue, cmdFalse, var1, var2)`: ejecuta comandos segun igualdad de `ARC.VAR[key]`.

Variables por fase:

- `ARC.PHASE:SET(key, value)`: guarda valor para la fase actual.
- `ARC.PHASE:GET(key)`: lee valor de la fase actual.
- `ARC.PHASE:TOG(key)`: alterna valor para la fase actual.
- `ARC.PHASE:IF(...)`: condicional por existencia/truthy en phase var.
- `ARC.PHASE:IFS(...)`: condicional por igualdad en phase var.
- Estas variables se persisten por personaje/fase en `SpellCreatorCharacterTable.phaseArcVars`.

Permisos/fase:

- `ARC.PHASE.IsMember`
- `ARC.PHASE.IsOfficer`
- `ARC.PHASE.IsOwner`
- `ARC.PHASE.GetPhaseId`
- `ARC.PHASE.IsDM`
- `ARC.XAPI.Phase.*`

Utilidades utiles:

- `ARC:TOGAURA(id)`: alterna aura por spell id.
- `ARC.XAPI.ToggleAura(spellID)`: alterna aura por spell id.
- `ARC.XAPI.HasAuraID(id, unit)` / `ARC.XAPI.HasAura(id, unit)`: comprueba aura.
- `ARC.XAPI.HasItem(itemID)`: comprueba item en bolsas.
- `ARC.XAPI.GetPosition()`: devuelve posicion actual via Epsilon.
- `ARC.LOCATIONS:SAVE(key)`: guarda posicion actual.
- `ARC.LOCATIONS:LOAD(key)`: devuelve posicion guardada.
- `ARC.LOCATIONS:GOTO(key)`: hace `worldport` a posicion guardada.
- `ARC.XAPI.UI.errorMessage(...)`: muestra error UI.
- `ARC.XAPI.UI.showConfirmationDialog(...)`: muestra dialogo de confirmacion.
- `ARC.XAPI.Time.GetPhaseTime(format)`, `GetServerTime(format)`, `GetLocalTime(format)`: utilidades de tiempo.

Notas de integracion:

- `EpsilonLib.AddonCommands` es la via preferida cuando Harford necesite callback, parsear respuesta del servidor o suprimir mensajes de confirmacion.
- Harford debe usar `HarfordServerActions` para acciones de gameplay/UI que impliquen comandos servidor siempre que exista una accion validada.
- `HarfordEpsilonCommands.Send(...)` queda como transporte compartido de bajo nivel para comandos fijos/validados que aun no tengan accion propia.
- `ARC.CMD` directo no debe usarse desde modulos de gameplay/Admin. Solo puede vivir dentro de `HarfordEpsilonCommands` como fallback interno del wrapper, o en comandos explicitamente debug documentados.
- Los modulos Admin deben pasar comandos sin punto inicial (`npc set aura 123`, no `.npc set aura 123`) y con `addonName = "HarfordAdmin"` cuando usen el wrapper.
- `Harford/Loot/HarfordLoot.lua` usa `HarfordServerActions` para `additem`, `aura 224063 self` y `unaura 224063 self`.
- Antes de enviar un comando sin accion propia, comprobar runtime del wrapper:

```lua
if HarfordEpsilonCommands and HarfordEpsilonCommands.Send then
    HarfordEpsilonCommands.Send("npc set aura 123", {
        addonName = "HarfordAdmin",
        forceEpsilon = true,
        showMessages = false,
    })
end
```

## Regla: Todo lo DM va en HarfordAdmin

- Cualquier comportamiento exclusivo de modo DM (`.ph dm`) debe vivir en `HarfordAdmin/`, nunca en el core `Harford/`.
- Regla de carga: sin el modulo `HarfordAdmin` activo no se cargan ni se exponen opciones DM/Admin, aunque el personaje tenga `.ph dm` activo. Para herramientas admin el permiso es la conjuncion `HarfordAdmin activo + .ph dm activo`, no cualquiera de las dos condiciones por separado.
- El core puede exponer **callbacks/funciones sobrescribibles** que HarfordAdmin reemplaza (patron `InsertGlanceLink`).
- Para la ficha, el core expone `HarfordDnDAPI.ApplySheetContext(context)`, `HasSheetContext()` y `ClearSheetContext()`. Son APIs neutrales de render/tirada; la construccion del contexto NPC desde target/TRP3 y su boton viven solo en `HarfordAdminNPC`/`HarfordAdminUnitMenu`.
- **Limite de locales en `HarfordDnD.lua`**: el cliente Lua falla si la funcion principal supera 200 `local` (actual ~139). El estado temporal de contexto se agrupa en una sola tabla local `SheetContext` (`active`, `overrides`, `rollName`, `rollColor`, `actions`, `showActionPanel`, `spellProficiencyBonus`, `kind`). No volver a separar esos campos en locales de file-scope; nuevas piezas grandes deben ir a modulos `HarfordDnD*`, bloques `do ... end` o tablas de estado.
- Si un módulo core necesita comportamiento condicional según modo DM, la condición debe vivir en HarfordAdmin mediante override del callback, no como `if HarfordAuthority.IsDMMode()` dentro del core.
- Ejemplos del patrón:
  - `HarfordTRP3.InsertGlanceLink(glance)`: extension exclusiva de estados ajenos. Por defecto crea una copia no importable registrada e inserta su marcador plano TRP3 enviable; `HarfordAdminNPC` lo sobrescribe en modo DM para enviar al NPC target un hyperlink validado y caer a impresion local si no puede emitirlo. Los links nativos de TRP3 no se interceptan.
  - `HarfordReputation.CanEdit()` comprueba addon `HarfordAdmin` cargado e `IsDMMode()` porque la edicion de reputaciones es un contrato protegido del core.
- Excepción aceptada: comprobaciones de permisos DM que bloquean acciones destructivas en el core (`CanEdit`, `Require`, etc.) pueden vivir en `HarfordAuthority` referenciados desde el core. Lo que no puede estar en el core es **comportamiento de UI o acción específica del DM**.

- **Espacios de conjuro visibles (2026-08-21)**: el sistema de espacios ya existia y se APLICA
  (`HarfordDnDMana.SLOT_COUNT` con la tabla 5e 1-20, `CanSpendSpellSlot` bloquea el lanzamiento y
  `SpendSpellSlot` lo consume en `ConfirmCast`; los gastados viven en `_progression.spellSlots` y
  se restauran en descanso largo), pero solo estaba activo si `HarfordConfig.spell_cost_mode` vale
  `"slots"` (por defecto es `"mana"`) y **solo se veia de uno en uno** dentro del detalle de un
  conjuro. `HarfordCharacterSpellbook.CastingResourceText` anade una linea en la esquina inferior
  IZQUIERDA de la pestana Conjuros que enumera todos los niveles (`I 4/4  II 3/3  III 2/2`) en
  modo espacios, o `Mana 19/27` en modo mana, y queda VACIA para un no lanzador en vez de mentir
  con ceros. Color por estado: dorado intacto, blanco a medias, rojo agotado. Va anclada por
  BOTTOMLEFT y con `SetMaxLines(2)` porque un lanzador de nivel 20 tiene nueve niveles y la
  segunda linea debe crecer hacia arriba sin invadir el pasapaginas. Se recalcula en cada
  `RefreshSpells`. El mana actual se lee de `HarfordDnDStore.GetResourceCurrent("mana")`, que es la
  via canonica (`HarfordDnDAPI` NO expone `GetResourceCurrent`).

- **Sintonizacion y carga en la UI (2026-08-21)**: `HarfordDnDBurden` tenia motor pero ninguna
  via de uso. Ahora: (1) dos filas en la vista **Detalles** de la ficha de personaje —
  `Sintonizacion 2/3` con la lista de objetos en el tooltip, y `Carga 45/210` con la capacidad
  (Fuerza x 15) explicada; (2) gesto **Ctrl+click** en un hueco del paperdoll para sintonizar o
  romper la sintonizacion (los demas gestos ya estaban cogidos: shift linkea, click derecho/alt
  desequipa, click izquierdo equipa); (3) el tooltip del hueco solo menciona la sintonizacion si
  el objeto la pide o ya la tiene, para no ensuciar el de cada pieza corriente.
  Reglas verificadas con el interprete Lua real: maximo 3 objetos, no dos copias del mismo (ni
  por itemId ni por nombre), capacidad = Fuerza x 15, y sobrecarga.
  **Las dos filas se ocultan en INSPECCION**: `HarfordDnDBurden.GetCapacity` resuelve la Fuerza
  con `HarfordDnDCalc`, que es el del jugador LOCAL, asi que en inspeccion daria los numeros de
  uno bajo el nombre de otro (mismo contrato que habilidades/salvaciones remotas).
  **El peso no viene del juego**: el cliente de WoW no expone el peso de un objeto, asi que
  `API.WEIGHTS` solo tiene lo DECLARADO y `GetCarried` devuelve tambien cuantos objetos no lo
  traen. La UI lo muestra como `45/210 (+3?)` en vez de dar una cifra que mentiria por defecto.
  Diagnostico: `/harford debug run carga`, `carga peso <itemId> <libras>`, `carga romper <id>`.

## Wowhead Como Fuente: Que Aguanta Y Que No (2026-08-22)

Las recetas y los objetos de profesion se bajan de Wowhead. Hay DOS puertas y se portan de
forma muy distinta:

- **`nether.wowhead.com/.../tooltip/...`** (tooltip de hechizo o de item): respuestas de 1 KB,
  aguanto **mas de 6.000 peticiones seguidas** a 0,1 s sin una sola queja. Es la puerta buena y
  de ahi salen nombre, icono, efecto, calidad y todas las caracteristicas del objeto.
- **`es.wowhead.com/...` (la ficha completa)**: paginas de 60 a 180 KB. A las ~90 peticiones
  devuelve **403 Forbidden y bloquea la IP para TODO el dominio**, incluido `&xml`. Cambiar el
  User-Agent no lo levanta. No reintentar en bucle: hay que espaciar mucho o no usarla.

Consecuencia practica: **de donde se aprende cada receta** (entrenador / vendedor / botin /
mision) solo esta en la ficha completa, en un listview `taught-by-item`, y por eso ese dato
esta PENDIENTE. Lo que si funciona de ahi, cuando se pueda: la receta sin ese listview es de
entrenador, y con el trae el item (`Formula: ...`), su `source` y el NPC y la zona.

Detalles de la extraccion que costaron una pasada cada uno:

- La lista de la profesion vive en un `<script>` inline del HTML, en un `Listview` con
  `id: "recipes"`; los nombres de objeto estan en `WH.Gatherer.addData(3, ...)` bajo
  `name_eses`. Nada de eso lo ve `WebFetch`, que devuelve solo el armazon de la pagina.
- El certificado de wowhead no valida contra el almacen local de este equipo: hay que
  desactivar la verificacion en el contexto SSL.
- El nombre MODERNO se pide al dominio sin version. Si vuelve entre corchetes
  (`[Dream Dust]`, `[PH] ... [DEP]`) es que el retail ya no lo traduce: ahi manda Classic.
- Las CARACTERISTICAS, en cambio, se piden a la version del arbol. El retail reescala cada
  objeto y hasta le cambia las estadisticas (la Hombrera de arana venenosa pasa de 41 de
  armadura y espiritu a 10 de armadura y versatilidad).
- Un objeto puede no existir en la version del arbol donde aparece: hay que probar en cascada
  classic -> tbc -> wotlk -> retail.

## Pestana Profesiones: Como Lo Hace El Libro Nativo (2026-08-21)

El libro de hechizos nativo **no recorta ornamentos por hueco de profesion**. Al entrar en la
pestana Profesiones sustituye las DOS paginas enteras (`SpellBookFrame.lua`, `SpellBookInfo`):

```lua
SpellBookInfo[BOOKTYPE_PROFESSION] = {
    bgFileL = "Interface\\Spellbook\\Professions-Book-Left",
    bgFileR = "Interface\\Spellbook\\Professions-Book-Right",
}
```

El marco ornamentado de cada profesion, el marcapaginas verde y el resto del adorno vienen
HORNEADOS en esas dos texturas. `PrimaryProfessionTemplate` no tiene fondo propio: su unica
textura de fondo esta comentada en el XML.

De ahi salio el fallo que se arrastraba: se conservaban las paginas de conjuros
(`Spellbook-Page-1/-2`), se recortaba un trozo de `383588` por boton como sello y se estiraba
449x101 texeles dentro de un frame de 437x81 (deformacion no uniforme, 0,973x horizontal y
0,802x vertical), mas un parche `ribbonCover` para tapar la cinta AZUL de la pagina de conjuros
que asomaba por debajo. Con las paginas correctas no hay cinta azul que tapar y el parche sobra.

**Nuestro libro mide 550x525, exactamente igual que `SpellBookFrame`**, asi que las coordenadas
nativas valen 1:1 y no hay que escalar nada:

| Elemento | Anclaje nativo | Tamano |
|---|---|---|
| `SpellBookPage1` | TOPLEFT +7,-25, **tamano natural** (sin Size ni 2o anclaje) | natural |
| `SpellBookPage2` | `SpellBookPage1`.TOPRIGHT, tamano natural | natural |
| `PrimaryProfession1` | TOPLEFT +80,-67 | 437x81 |
| `PrimaryProfession2` | P1.BOTTOMLEFT +0,-12 (y = -160) | 437x81 |
| `SecondaryProfession1` | P2.BOTTOMLEFT +0,-40 (y = -281) | 437x46 |
| `SecondaryProfession2` | S1.BOTTOMLEFT +0,-30 (y = -357) | 437x46 |
| `SecondaryProfession3` | S2.BOTTOMLEFT +0,-30 (y = -433) | 437x46 |

Son CINCO huecos fijos de DOS tipos distintos, no cinco iguales apilados con un paso fijo:

- **Primary** (437x81): aro de icono 72x72 en TOPLEFT **+7,-7**; `professionName`
  `QuestTitleFontBlackShadow` en +100,-2; `rank` `GameFontHighlightSmall` a
  `professionName`.BOTTOMLEFT +0,-33; `statusBar` a `rank`.BOTTOMLEFT +14,-5.
- **Secondary** (437x46): **sin aro de icono**; se monta de abajo arriba — `statusBar` en
  BOTTOMLEFT +16,-1, `rank` sobre ella (+(-14),+4 / +25,+4) y `professionName`
  `QuestFont_Shadow_Small` sobre el rank (+0,+2). El segundo boton de hechizo va a la IZQUIERDA
  del primero (`TOPRIGHT` > `TOPLEFT` -109,0), no debajo: solo hay 46 de alto.

**Estado "sin profesion"**: el XML declara DOS FontStrings PROPIAS, no reutiliza las de la
profesion aprendida, y ese era el otro fallo visible (texto en oro y descolocado):

- Primary: `missingHeader` `QuestTitleFontBlackShadow` en TOPLEFT **+120,-13**, color
  `0.85/0.7/0.6`; `missingText` `SubSpellFont` ancho **305** a su BOTTOMLEFT +0,-1, color
  `0.1/0.05/0.05`. `OnLoad` deja el icono con `SetAlpha(0.6)` + `SetDesaturation(true)`.
- Secondary: `missingHeader` `QuestFont_Large` en TOPLEFT +4,-15, color `0.15/0.1/0.1`;
  `missingText` `SubSpellFont` ancho 250 anclado a RIGHT del hueco -5,0.

**El manifiesto de atlas comentado al principio de `SpellBookFrame.xml` da los tamanos REALES de
cada pieza**, y dividiendo tamano entre delta de texcoord se saca la dimension de la textura:
`Professions-MajorRing-Normal` 74x74 con Δx=0.2890625 y Δy=0.578125 => `ProfessionsBook` es de
**256x128**. Cuadra con `Professions-Item-Border` (108x41), `Progress-BgLeft` (16x16) y los
remates de 12x12. Ojo: el aro mide **74x74 reales** pero el XML lo mete en `<Size x="72" y="72"/>`
— ese encogimiento de 2 px es intencionado y hay que conservarlo.

`ProfessionStatusBarTemplate` esta replicado 1:1 y verificado contra el XML. El remate DERECHO
(`$parentRight`) va `hidden="true"` **en el propio XML**: ocultarlo no es un apano nuestro.

**`S.pages` mezcla paginas de DOS ventanas.** `CreatePage` cuelga `book`/`spells`/`professions`
de `S.skillsContent` (la ventana de Habilidades) y el resto del panel de personaje, pero todas
acaban en la misma tabla `S.pages`. El bucle de `RefreshPanel` que oculta paginas excluia solo
`book` y `spells`: cuando Profesiones se mudo a esa ventana nadie actualizo la exclusion, asi que
**abrir el panel de personaje ocultaba la pagina de Profesiones** (se perdian los marcos; el
marcapaginas dejo de perderse al pasarlo a textura de `host`). Ahora hay una fuente unica,
`SKILLS_WINDOW_PAGES`, que usan tanto `CreatePage` como ese bucle, y **debe declararse antes de
`RefreshPanel`**: si queda por debajo, en el bucle es un global `nil` y se ocultan todas.

**TRAMPA DE ORIGEN: `skillsContent` empieza 21 px mas abajo que el libro.** Las coordenadas
nativas (huecos en `(80,-67)`, pagina en `(7,-25)`) son respecto al FRAME de 550x525. Pero
`CreatePage` cuelga la pagina de `S.skillsContent`, que esta anclado a `TOPLEFT sf, 0, -21`.
Anclar los huecos a `page` los bajaba 21 px (el aro del icono salia visiblemente bajo) mientras
la textura de pagina, colgada de `host` directamente, quedaba en su sitio. `profList`, los marcos
recortados y `recipePanel` se anclan al LIBRO (`host`), no a `page`; siguen siendo hijos de `page`
para mostrarse/ocultarse con la pestana, que el anclaje cruzado no lo impide.

**Reparto Harford: CINCO huecos iguales, no 2+3.** El nativo tiene dos huecos grandes (437x81)
y tres pequenos (437x46) con el arte de cocina/pesca/arqueologia HORNEADO en la pagina. En
Harford todas las profesiones son equivalentes, asi que se usan cinco huecos GRANDES con el paso
nativo de 93: `67 + 5*93 = 520` sobre 525 de alto, caben justos (un sexto se saldria).

Los huecos 3, 4 y 5 caen sobre el arte de secundarias y hay que taparlo. **Se tapa con el marco
del hueco 1 recortado de la PROPIA pagina**, sin texCoords calculadas ni arte inventado: un frame
con `SetClipsChildren(true)` que contiene otra copia de `Professions-Book-Left`/`-Right`
desplazada `(-73, +42)`. Ese desplazamiento sale de la geometria nativa: la pagina izquierda se
ancla en `(7,-25)` y el hueco 1 en `(80,-67)`, luego `7-80 = -73` y `-25+67 = +42`. El frame de
recorte va a `nivel del hueco - 1` para que el marco quede DETRAS del icono, el texto y la barra.

La rama `secondary` de `ProfButton` queda sin usar con este reparto; se conserva por ser la
transcripcion fiel de `SecondaryProfessionTemplate` y por si se adopta el reparto nativo 2+3.

**Sonda `profbook` (capturada 2026-08-21, cuenta GRIKER)**: valida TODO lo deducido del XML. Se
midio contra el frame nativo vivo y coincide punto por punto — tamanos 437x81 / 437x46, aro
72x72 en TOPLEFT +7,-7, icono 70x70 con +1,-1 / -1,+1, `professionName` +100,-2, `rank` a
`professionName`.BOTTOMLEFT +0,-33, `missing` +120,-13, barra 95x16 con remates 12x12 y fondos
16x16 en RIGHT>LEFT +0,+2, `BGMiddle` entre los dos fondos, texto de barra en CENTER +0,+2,
botones 40x40, NameFrame 108x41 en LEFT>icono.RIGHT +1,0, nombre de 100 de ancho en
LEFT>boton.RIGHT +5,+7, subtitulo 95x28 debajo; y en el hueco pequeno `rank` de 134 de ancho en
BOTTOMLEFT>barra.TOPLEFT -14,+4 / BOTTOMRIGHT>barra.TOPRIGHT +25,+4, nombre sobre el rank +0,+2
y `missing` en +4,-15. **Una sola discrepancia**: `PrimaryProfession1IconBorder` va en capa
**OVERLAY/0**, no en ARTWORK; corregido.

Dato util de la sonda: `Interface\\Spellbook\\ProfessionsBook` **es el fileID 383591**. Las
texturas puestas por XML (`file=`) vuelven de la sonda como fileID numerico, y las puestas por
Lua con cadena vuelven como cadena; ambas formas funcionan. **383588 NO es ProfessionsBook**, es
otra textura (probablemente `Professions-Book-Left`, de donde salia la cinta verde del apano
anterior).

Lo unico SIN confirmar es que `Professions-Book-Left/Right` existan en el build de Epsilon: la
sonda de `SpellBookProfessionFrame` no las incluye porque cuelgan de `SpellBookFrame`
(`SpellBookPage1/2`), no del frame de profesiones. `/harford debug run proftex` lo dice, o
`probeframecapture SpellBookFrame profpagina`. No hace falta esperar a eso para trabajar:
`ProfTexture` usa la ruta, cae al fileID si `GetFileIDFromPath` devuelve nil y **avisa por chat
una sola vez** cuando eso pasa, de modo que un id equivocado no se queda en una pagina verde
silenciosa.

## Trampa De Lua: Cadenas `and` Que Truncan Retornos Multiples

**NUNCA** asignar varios valores desde una cadena `and` con la guarda dentro de la expresion:

```lua
-- MAL: `a and b and f(x)` se queda SOLO con el primer valor devuelto por f.
local count, sides = HarfordDnDWeapons and HarfordDnDWeapons.ParseDice
    and HarfordDnDWeapons.ParseDice(dice)     -- sides == nil SIEMPRE

-- BIEN: la guarda va en un `if`, la asignacion multiple aparte.
local count, sides
if HarfordDnDWeapons and HarfordDnDWeapons.ParseDice then
    count, sides = HarfordDnDWeapons.ParseDice(dice)
end
```

Lo mismo con `local ok, err = cond and F() or G()`: ambas ramas se truncan y `err` queda nil.

No es teorico: en 2026-08-21 se encontro el patron en **diez sitios** y tres eran fallos de juego
silenciosos, sin error ni mensaje, que llevaban vivos desde que se escribio el codigo:

- `HarfordDnDArea.NormalizeDefinition` rechazaba **TODA curacion** con "Componente de curacion
  invalido", porque `sides` era nil y la validacion siempre fallaba. Ninguna curacion del compendio
  llegaba a resolverse.
- `HarfordCompendioCore.ApplyUpcastDamage` **nunca escalaba ningun conjuro** al lanzarlo con un
  espacio superior: `componentSides` era nil, asi que `componentSides == sides` nunca se cumplia.
  Afectaba a los 54 conjuros que declaran la formula en su texto (Bola de Fuego a espacio 5 seguia
  haciendo 8d6).
- `HarfordDnD.lua` (maniobra Carga) comprobaba `if motion and tx and ty and ...` con `ty` siempre
  nil, asi que la validacion de "acercarte directamente al objetivo" no se ejecutaba nunca.

Los otros siete perdian solo el texto de error o falseaban un volcado de diagnostico
(`HarfordUnitFrames.DebugGroupFrames` informaba nil en casi todo lo que decia inspeccionar).
Al tocar cualquier modulo, barrer con:

```bash
grep -rnE "local +[A-Za-z_][A-Za-z0-9_]*(, *[A-Za-z_][A-Za-z0-9_]*)+ *=.* and +[A-Za-z_][A-Za-z0-9_.:]*\(" Harford/ HarfordAdmin/ HarfordDebug/ --include=*.lua
```

Ese patron tenia DOS agujeros, y por ellos se colaron `QOBJ`/`QOBJDONE` de `HarfordQuests`
durante meses (el DM cerraba un objetivo y ningun cliente hacia nada):

1. **Exigia dos nombres exactos.** `local a, b, c = x and f()` no casaba. Ahora acepta 2 o mas.
2. **No admitia `:` en la llamada.** El caso mas comun de todos es `rest and rest:match(...)`,
   y el patron solo aceptaba `.` en el nombre. Ahora acepta `:` tambien.

Le queda un tercer agujero que grep no puede cubrir: **la asignacion partida en dos lineas**.

```lua
local ok, err = _G.HarfordTrainerAPI and _G.HarfordTrainerAPI.OpenTrainer
    and _G.HarfordTrainerAPI.OpenTrainer(a)   -- `err` SIEMPRE nil, y grep no lo ve
```

Para esas, el olor es cualquier `local` con varios nombres cuya parte derecha acabe en `and`.

### La otra cara: `cond and X or Y` cuando X vale `false` (2026-08-25)

El mismo idioma tiene un segundo fallo, y este NO va de retornos multiples:

```lua
-- MAL: si `opts.conditionId` es false, devuelve `contest.onWin`, no false.
local estado = (opts and opts.conditionId ~= nil) and opts.conditionId or contest.onWin

-- BIEN: con `if` no hay trampa.
local estado = contest.onWin
if opts and opts.conditionId ~= nil then estado = opts.conditionId or nil end
```

`and/or` no puede distinguir "el valor es false" de "no hay valor", porque los dos son falsos para
Lua. En cuanto `false` sea un valor CON SIGNIFICADO -- y lo es en cuanto se usa para decir "ninguno"
en vez de "por defecto" -- el idioma deja de servir.

Paso en `Empujar`: la opcion "Apartar 1,5 m" llevaba `conditionId = false` para decir expresamente
que no aplicara ningun estado, y apartar derribaba igual. Compilaba, pasaba las suites (que miraban
el texto del fichero, no el resultado) y habria salido mal en mesa.

**Regla:** si `false` es un valor legitimo del campo, no se lee con `and/or`. Y la prueba de un
campo asi tiene que EJECUTAR la logica, no comprobar que el codigo diga lo que se espera.

Hay un intérprete Lua real en `C:/Users/marco/AppData/Local/Programs/Lua/bin/lua.exe`: para logica
pura (parsers, escalados, formulas) se puede extraer el trozo del modulo con `load()` y stubs de
los globales y probarlo de verdad, en vez de deducir el comportamiento leyendo. Asi se encontro
esto. `luac -p` solo valida sintaxis y no habria detectado ninguno de los tres fallos.

## Una lista de PRESENTACION nunca puede ser la lista de EXISTENCIA (2026-08-25)

`HarfordDnDConditions.API.ORDER` es el orden en que se pintan las condiciones: la tira del
unitframe, el menu del DM, la ficha. Pero `GetActive` la usaba tambien para RECORRERLAS, y con eso
una lista de presentacion se convirtio en una lista de existencia:

> una condicion definida en `DEFS` y no listada en `ORDER` no aparecia como activa NUNCA, y como
> `EffectsFor` va por `GetActive`, sus efectos no se aplicaban jamas.

No fallaba, no avisaba y compilaba igual. **Nueve estaban fuera**, y seis llevaban tiempo apagadas
sin que nadie lo notara: Ira desatada, Fortaleza, Marca ignea, Dolor y Orden oscura perdian sus
efectos enteros. Supresion del dolor se salvo por casualidad, porque su `damageReduction` se lee
recorriendo el bucket directamente y no por `GetActive`.

**Arreglo estructural, no once lineas mas en la lista.** `ORDER` se completa sola al cargar: lo
declarado ordena lo que le importa y el resto se anade en orden estable (`table.sort`) detras.
Olvidarse ya no puede apagar una condicion, solo ponerla al final de la tira.

**Regla general:** si una lista ordena, que solo ordene. Cuando ademas decide que existe, cualquier
olvido apaga funcionalidad en silencio. Antes de usar una lista declarada a mano para iterar,
completarla desde la tabla de datos.

El detector permanente vive en `tools/cargar/referencias.py` (paso 6 del despliegue) y la bateria en
juego lo comprueba tambien en el grupo `estados`, porque la version cargada puede diferir del texto.

## Referencias a ids que no existen: `tools/cargar/referencias.py` (2026-08-25)

Un rasgo puede nombrar la condicion `ayudado_pruebaa` y Lua no se queja: la busca, no la encuentra,
y no hace nada. Misma familia que lo anterior -- algo apunta a un sitio vacio y el fallo aparece
como SILENCIO. Es paso de despliegue y bloquea la copia.

Cuatro espacios de nombres, y **NO se mezclan**:

| Campo | Se comprueba contra |
|---|---|
| `conditionId`, `selfCondition.id`, `onWin` | `HarfordDnDConditions.DEFS` |
| `resourceKey` | `HarfordDnDResources.DEFS` |
| `grantsAsBonus` | `HarfordDnDActions.DEFS` |
| `requiresState` | los `kind = "toggleState"` declarados |

**`requiresState` NO son condiciones** aunque los dos se llamen "estados": son estados activables de
`HarfordDnDProgression` (`lone_wolf`, `wild_shape`, `metamorphosis`, `spirit_beast`,
`serene_stance`). Confundirlos da cinco falsos positivos. Un `requiresState` sin su `toggleState`
si es un fallo real: el efecto que lo pide no se activaria jamas.

Si una tabla no se puede leer, el detector lo DICE en vez de callarse: sin ella todas sus
referencias pareceria rotas y el aviso se volveria ruido que se aprende a ignorar.

## Tira de estados propia sobre el unitframe (2026-08-25)

Solo 15 de las 48 condiciones tienen aura detras. Las otras **no existen para el cliente** y no
apareceran en el unitframe por mucho aura que se les enganche, asi que Harford pinta los suyos
APARTE en `HarfordEstados<unit>`, no mezclados con los buffs nativos: son de otra naturaleza (los
lleva Harford, no el servidor) y confundirlos haria creer que se pueden disipar.

- `HarfordUnitFrames.RefreshConditionStrip(unit)` para `target` y `focus`. UIParent/MEDIUM nivel 85,
  como cualquier overlay de unitframe (nunca DIALOG).
- **El ancla se recalcula cada vez**: sobre la aura nativa mas alta si siguen encima del frame (el
  caso normal, sin barras extra), o sobre el frame si Harford las movio bajo las barras. Se ancla al
  OBJETO, no a una coordenada, que se quedaria vieja al reposicionar.
- Pool de iconos, sin ticker. Se repinta al cambiar target/focus, al reanclar auras y cuando el
  motor de condiciones avisa (`Notify` llama a `RefreshAuraCounters`).
- **El contador puede cambiar sin que cambie el aura**, y ahi `UNIT_AURA` no dispara: por eso
  `Notify` avisa a los unitframes ademas de al panel. Sin eso el numero se queda viejo hasta que
  entre o salga un aura cualquiera.
- Arte: la condicion CON aura usa el icono del aura (el que el jugador ya ve); las demas, el
  catalogo, con clave `harford_estado_<id>` en `Catalog.features` -- misma nomenclatura y misma
  sintaxis de clave desnuda que `harford_accion_<id>`.

## Tiradas enfrentadas (Agarrar, Empujar) (2026-08-25)

La dificultad NO es fija: la pone el atacante con su propia tirada, y su total es la CD del
defensor. `HarfordDnDWeaponRolls.RollContest(contest, opts)`.

**No hay opcode nuevo ni resolucion nueva.** `DOSAVE` ya llevaba un campo `skill` que convierte la
peticion en prueba de habilidad, y `ResolveWeaponManeuverAfterHitSave` ya sabe distinguir jugador de
NPC, pedirle la tirada al cliente defensor y aplicar el estado al que pierde. Lo unico propio de una
contienda es de donde sale la dificultad.

- **Elige el DEFENSOR**: las habilidades viajan juntas separadas por `/` (`"Atletismo/Acrobacias"`) y
  su cliente se queda con la mejor. Quien decide que le conviene es quien lo recibe.
- **El empate lo gana el defensor**, y eso ya salia de la comparacion inclusiva (`total >= dc`).
- La opcion elegida manda sobre `onWin` y puede ser `false` para no aplicar ninguno (ver la trampa
  de `and/or` mas arriba).

## Reglas De Seguridad

- No ejecutar texto arbitrario recibido de otros clientes como comando Epsilon.
- Los comandos Epsilon deben salir solo desde logica admin explicita.
- Preferir plantillas cerradas y parametros validados antes que concatenar texto libre.
- Mantener separadas estas capas:
  - Comunicacion Harford entre clientes.
  - Comandos Epsilon al servidor.
  - Respuestas Epsilon parseadas desde callbacks.
- Si se anade integracion Epsilon, `HarfordAdmin` deberia declarar dependencia opcional o hacer comprobacion runtime de `EpsilonLib`.

## Competencias Importadas Desde TRP3

- `/harford cargarficha` importa competencias literales del About TRP3 en `HarfordDnDProgression.importedProficiencies`.
- Formato confirmado con perfiles reales: la cabecera `Competencia` lista armaduras/armas/herramientas; `Tiradas de salvacion` lista salvaciones; `Habilidades` lista habilidades competentes; el bloque `Pericia` tiene la cabecera y en la linea inmediatamente posterior las habilidades separadas por `|` (ej. `Acrobacias | Sigilo`).
- `HarfordDnDFeatureEffects.Resolve` mezcla esa capa importada con los rasgos/libros: `Habilidades` -> `skillRank=1`, `Pericia` -> `skillRank=2`, salvaciones -> `saveProf`, y competencias generales -> `armorProf`/`weaponProf`/`toolProf`.
- Esta capa viaja en `DNDCLASS` como campo compacto `p=` para sync/inspeccion. No sustituye el libro: lo complementa para elecciones libres que el libro sabe que existen pero no puede adivinar.

## Salvaciones Post-Impacto

- `DOSAVE|stat|dc|outcome|auraId`: cuando una maniobra post-impacto pide salvacion contra un jugador, el atacante solo envia esta solicitud por WHISPER. El cliente defensor calcula con su propia ficha (`HarfordDnDCalc.GetSaveRollBonuses`), tira y publica el resultado desde su nombre/color. Solo los defensores NPC se resuelven localmente desde el atacante/DM porque no tienen cliente receptor.

## Rendimiento, Caches Y Debug Pesado

- `GET_ITEM_INFO_RECEIVED` puede dispararse en masa con MogIt. `HarfordDnDItems.RefreshPending()` solo debe procesar items de equipo/inspect que estuvieran realmente pendientes; si un item ya estaba resuelto, el evento se ignora y no refresca panel, ficha, unitframes ni nameplates. `HarfordLoot` y `HarfordAdminLoot` tambien filtran ese evento por `itemID`: si el item recibido no esta en la tabla visible/editada, no repintan la ventana. Diagnostico: `/harforddebug run perfitems` (`reset` reinicia contadores).
- `HarfordUnitFrames` no debe reaccionar a cualquier mensaje `DND5EARC`: solo recursos (`DNDRES`, `DNDRESCFG`, `RADJ`) pueden refrescar nameplates. Tiradas, clases, equipo, inspect y otros opcodes no deben provocar `HarfordNamePlates.RefreshAll()`. Para recursos usar `HarfordNamePlates.RefreshName(profileName)`; `RefreshAll()` queda para login, cambios de config o fallback si esa API no existe.
- Los overlays de party/raid usan firma por compact frame (unidad, icono, recursos, temp HP y color de clase). Si la firma no cambia, la ruta caliente solo actualiza alpha/rango y evita repintar barras/textos.
- Las filas dinamicas del panel de personaje deben usar pool/reutilizacion. No crear frames/fontstrings/dropdowns nuevos en cada refresh y luego perder la referencia; en WoW los frames no se destruyen realmente.
- `HarfordCharacterPanel` solo debe registrar eventos de target/retrato (`PLAYER_TARGET_CHANGED`, `UNIT_PORTRAIT_UPDATE`) mientras el panel esta visible. Al ocultarse se desregistran para evitar lecturas TRP3/modelo/retrato en juego normal.
- `HarfordTurns` mantiene vivo el estado/sync de turnos, pero la ventana visual se crea bajo demanda al abrirla y `RefreshFrame()` no repinta tarjetas si el frame esta oculto. Los cambios de HP del NPC target pueden seguir actualizando/sincronizando el store aunque la ventana este cerrada.
- Los buffers chunked de `HarfordSync` para progresion/equipo (`DNDCLASSC`, `DNDINSCLASSC`, `DNDEQUIPC`, `DNDINSEQUIPC`) caducan tras 60s si faltan chunks. No dejar buffers incompletos vivos toda la sesion.
- `HarfordCharacterInspect` usa cache efimera y limitada: maximo 8 snapshots unicos y TTL de 5 minutos. Al expulsar/caducar un snapshot, tambien limpia los datos efimeros asociados en `HarfordDnDProgression` y `HarfordDnDItems` por cada alias del perfil; la inspeccion no debe crecer indefinidamente al mirar muchos jugadores.
- Timers diferidos en rutas calientes deben estar coalescidos con flag/token. Confirmado: `HarfordUnitFrames` deduplica el refresco diferido de group overlays y la secuencia de restauracion compact; `HarfordAdminUnitMenu` deduplica el repoblado diferido del editor de recursos por token/nombre esperado.
- Caches por identidad tambien deben quedar acotadas: `HarfordUnitFrames.classColorCache` conserva como maximo 100 nombres completos (mas alias cortos); `HarfordNamePlates` limita a 100 solicitudes recientes y limpia estado al retirar la placa; el throttle de respuestas de inspeccion elimina entradas con mas de 60s.
- `HarfordUnitFrames` mantiene un indice runtime `unit -> compact frames`. `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UNIT_AURA`, `UNIT_NAME_UPDATE`, `UNIT_PORTRAIT_UPDATE` y `UNIT_CONNECTION` de party/raid refrescan solo los frames de esa unidad; el escaneo completo queda como fallback si el indice aun no conoce el frame. Los mensajes `DNDRES`/`DNDRESCFG`/`RADJ` refrescan por nombre y retornan sin caer en `API.Refresh()` global.
- Caches runtime deben tener limite o limpieza: `HarfordTRP3` limita enlaces glance, `HarfordDnDItems` limita cache de items resueltos, `HarfordDnDResources.RemoteCache` se poda al cambiar grupo/mundo y los buffers chunked de reputacion caducan.
- `HarfordFrameProbe` es debug pesado. Puede superar 1 MB en SavedVariables tras `/harford debug run probeframe`. Comandos: `probeframe NombreFrame` (snapshot actual), `probeframeexport NombreFrame` (conserva varias capturas en `HarfordFrameProbe.exports`), `probeframecapture <Frame> <etiqueta>` (guarda varios ESTADOS del mismo frame) y `probeframediff <Frame> <antes> <despues>` (lista cambios de alpha, visibilidad, capas, textura, atlas, texcoords y color); `probeframeclear` borra la SV en memoria. Para reproducir un control nativo con estados, capturar cada estado visible, ejecutar el diff y solo entonces cambiar el addon. Tras usarlo, limpiar con `/harford debug run probeframeclear` o `/harford debug run svclean frameprobe`; no dejarlo cargado durante juego normal. Captura strata/level/alpha/scale/bounds/anclajes/regiones/texturas/fontstrings/statusbars/botones/scrollframes para replicar UI nativa sin clonar scripts/eventos.

## Contratos Y Misiones Harford

- `HarfordQuests` es estado per-PJ: acepta/abandona misiones y reclama recompensas compartidas. `ClaimRewards` guarda un recibo por componente (`reps` por indice/faccion/cantidad y `xp`) y solo marca la recompensa completa cuando todos resolvieron: una faccion pendiente no bloquea las demas ni permite duplicarlas al reintentar. La XP se aplica con `HarfordCharacterXP.AddXP`; una recompensa solo-XP se reclama y marca correctamente cuando esa entrega local tiene exito.
  - La entrega compartida de una mision de mundo usa `FinalizeSharedTurnIn(id, reward?)`: concede exclusivamente reputacion/XP locales, marca la entrega y retira la mision sin reproducir abandono. `HarfordWorldQuests` difunde `QTURNIN^<id>` por grupo; cada receptor usa su propia copia persistida de recompensas. Oro e items siguen siendo exclusivos de quien usa el gossip.
- **Frontera contrato/mision**: el contrato es la publicacion global del DM (`HarfordContractsDB`); la mision es una entrada aceptada/rastreada por personaje en `HarfordQuestsStore`, autocontenida y por `id` generico. Origenes de mision: (1) contrato (`HarfordContractsUI` -> `HarfordQuests.Accept(contract.id, ...)`), (2) catalogo `HarfordQuestCatalog` (misiones canonicas reutilizables "de la naturaleza"; el ArcSpell/gossip pasa solo el `id` y `Accept` rellena la definicion), (3) info libre desde ArcSpell/gossip (todos los campos al aceptar). En `Accept`, si el `id` existe en el catalogo se usa de BASE y el `info` recibido la sobrescribe. Cada entrada guarda `source` (`contract`/`world`/`npc`). El quest log conserva `EnrichQuestFromContract` SOLO como fallback legacy; una mision de catalogo/libre ya trae toda su info.
- **Objetivos estructurados + completado (`HarfordQuests`)**: cada mision guarda `objectives = { {text, required, current, done}, ... }`. `Accept` normaliza desde `info.objectives` (array de strings o de `{text, required}`) o, como fallback, parte `info.objective` multilinea (una linea = un objetivo de required 1); re-aceptar preserva el progreso por texto. El string `objective` que renderiza el quest log/tracker se COMPONE con `ComposeObjectiveText` (progreso `(n/N)` y check verde en los hechos) — por eso la UI muestra progreso sin tocar su jerarquia fragil. API: `GetObjectives(id)`, `IsComplete(id)`, `SetObjectiveProgress(id, i, n)`, `AdvanceObjective(id, i, delta=1)`, `CompleteObjective(id, i)`, `MarkComplete(id, by)` (cierre local). **Los avances solo por eventos CONFIRMABLES**: contador sincronizado que llama el ArcSpell/gossip/entrega, o accion DM. NUNCA progreso local automatico (nada de credito de kill nativo, poco fiable en Epsilon). Al completarse todos los objetivos, `RecomputeCompletion` marca `completed` (timestamp + `completedBy`).
- **Recompensas estructuradas de mision (`HarfordQuests`)**: `rewards = { rep = {faction, amount}, xp = n, money = {gold, silver, copper}, items = { {link|id, count}, ... } }`. **Reparto**: `rep`/`xp` son COMPARTIDAS (cada cliente cobra su parte una vez, modelo pull via `ClaimRewards` y `HarfordCharacterXP.AddXP`). `money`/`items` son INDIVIDUALES (turn-in unico en el NPC). El **dinero usa campos SEPARADOS oro/plata/cobre**; `HarfordQuests.RewardMoneyCopper(rewards)` da el total en cobre (1 oro=100 plata=10000 cobre) solo para componer el comando de entrega. El display del dinero usa los **iconos de moneda del Comunicador** (`Interface\MoneyFrame\UI-MoneyIcons`, texcoords oro `{0,.25}`/plata `{.25,.5}`/cobre `{.5,.75}`) como textura inline `|T...|t` (NO hyperlink), replicados en `HarfordQuests` para no depender de que el Comunicador cargue. `Accept` normaliza `info.rewards`; si no se pasa `info.reward` (string display), se DERIVA de `rewards` (`ComposeRewardText`). Lecturas exponen `rewards` (copia) + `reward` (string). Accesor `GetRewards(id)`. **Entrega de oro por comando de servidor**: `HarfordServerActions.GiveMoney(copper)` -> plantilla `MOD_MONEY = "modify money {copper}"` (delta en cobre). Items por `GiveItem` (ya existente). No repartir money/items a toda la raid (duplicaria dinero/objetos); solo rep/xp son de raid.
- **PRINCIPIO RECTOR: la Quest es el NUCLEO de todo**. `HarfordQuests` (el modelo Quest) es la base unica; contratos, registro (quest log), tracker y quests de mundo son **fuentes** o **vistas** de Quests, no modelos paralelos. Una Quest tiene: `id`, `title`, `description`, `objectives` (estructurados), `rewards` (rep/xp/money/items), `source` (`contract`/`world`/`npc`) y estado (`available`/`active`/`completed`). Un **contrato** es una Quest con `source="contract"`; una quest de **mundo** es una Quest con `source="world"` cuyo estado vive en el aura del NPC; el registro y el tracker son VISTAS. Un solo motor de objetivos/completado/recompensas. Converger todo aqui; no crear modelos de quest paralelos.
- **API para cargar quests de mundo desde el Arcanum (`DefineWorldQuest`)**: el ArcSpell "crea" la quest en el mundo cargando su info BASICA; el ESTADO (disponible/incompleta/completada) lo pone el aura del NPC (las 3 constantes), no el ArcSpell. Forma prevista:
  ```
  HarfordQuestAPI.DefineWorldQuest({
    id="world:i_spy", npc=<creatureTemplateId>, title="I Spy...",
    rewards={ items={ {id=14026825, count=5} } },
    available ={ text="...oferta...", objectives={ {text="Use the Detection spell...", required=1} } },
    incomplete={ text="Find anything worth looking yet?" },
    completed ={ text="There's lots to explore..." },
  })
  ```
  Al interactuar con el NPC, Harford lee su aura -> estado -> muestra el texto/objetivos de ese estado; al coger, `Accept` + comparte al grupo + (si oficial) swap de aura. Info reutilizable, sin `DummyQuestFrame`. **Identidad de la quest = el ID del NPC TEMPLATE (creature-entry, 6º token del GUID `Creature-0-...-<templateId>-<spawnUID>`), NO el spawn unico**: varios spawns del mismo template comparten la quest. `HarfordQuestCatalog`/registro runtime mapea `templateId -> definicion`.
- **Flag "Recompensa" (ledger) + recuperacion de ausentes**: al cobrar la parte compartida, la quest pasa a **completada** para ese jugador y sale de su log activo (`ClaimRewards` ya lo hace). El **flag "Recompensa"** es el ledger `claimed` per-PJ (`IsClaimed`): marca que ese PJ YA recibio la rep/xp (anti-doble cobro); la UI lo muestra como "Recompensa recibida". **Comando DM para ausentes**: un comando gateado por `CanUseDMTools()` envia la EXP/Rep compartida a quienes NO estaban al completar. Reutiliza el modelo pull: el DM difunde por `HARFORDQUEST` un "reclama tu parte de la mision X"; cada receptor sin el flag la aplica UNA vez (`ClaimRewards`) y se marca. Un jugador realmente offline no recibe el broadcast; lo cobra cuando este conectado y el DM re-emita (o via `Reconcile`). El `claimed`/flag garantiza que nadie cobra dos veces. Dinero+items NUNCA entran aqui (son turn-in individual); solo rep/xp.
- **El gossip depende del ESTADO (aura del NPC)**: Harford POSEE el render del gossip (engancha `GossipFrame`, lee `UnitGUID("npc")` -> templateId + aura -> estado) y muestra distinto contenido/accion por estado: `155096` disponible -> oferta (`available.text` + objetivos + recompensa) + boton **Aceptar**; `245633` incompleta -> progreso (`incomplete.text` + objetivos con contador), solo info; `252527` completada -> entrega (`completed.text` + recompensa) + boton **Completar**. **Reparto en el turn-in**: quien entrega se lleva **dinero + items** (INDIVIDUAL, su copia via `GiveMoney`/`GiveItem`) y la quest sale de SU registro/tracker; **rep + XP van a TODOS** (compartido, modelo pull, una vez por persona). La mision se auto-completa al cumplir objetivos (estado compartido por `QSTATE`); el aura del NPC pasa a "completada" de forma oportunista (oficial en el gossip) o por el DM. Cada jugador puede entregar y recibir su dinero+items; rep/xp sigue siendo una sola vez por persona. **Al entregar, si el que entrega es OFICIAL (`IsOfficerPlus()`) ademas quita el aura `252527` del NPC (`RemoveNpcAura`), CERRANDO la quest en el NPC para todos**; un no-oficial entrega pero no toca el aura. Ciclo de aura del NPC: `155096` (disponible) -> oficial coge: quita `155096`+pone `245633` (incompleta) -> auto-completada por objetivos (aura -> `252527` cuando un oficial abre el gossip, o DM a mano) -> oficial entrega: quita `252527` (cerrada). **El panel usa el estado real del jugador, no solo el aura.** El ArcSpell SOLO define la quest y spawnea el NPC con su aura; no necesita `DummyQuestFrame` ni hooks propios. **Vigilar en integracion**: que el render de Harford coexista con los hooks de gossip de la fase (EpsilonLib) sin pisarse.
- **IMPLEMENTADO `HarfordWorldQuests.lua`** (capa de quests de mundo sobre el nucleo `HarfordQuests`). API para el ArcSpell en `_G.HarfordQuestAPI`:
  - `DefineWorldQuest(def)`: registra por template id (`def={id,npc,title,description?,rewards?,available?,incomplete?,completed?}`; cada bloque de estado `{text, objectives={ {text,required,item?}, ... }}`). Si el gossip esta abierto, refresca el panel.
  - `GetNpcQuestState(unit)`/`GetNpcTemplateId(unit)`: estado via aura del NPC / template id (6º token del GUID, `UnitAura` HELPFUL).
  - `AcceptWorldQuest(unit)`: `HarfordQuests.Accept` + comparte al grupo por `QSHARE` (display) + si oficial swap `155096`->`245633`.
  - `TurnInWorldQuest(unit)`: dinero+items al que entrega (`GiveMoney`/`GiveItem`), rep+xp por `ClaimRewards`, si oficial quita `252527`.
  - `DmSendReward(questId)`: gate `CanUseDMTools()`; difunde `QREWARD` para que ausentes cobren rep/xp una vez por componente mediante el recibo `sharedClaimed` (no usa el turn-in individual `IsClaimed`).
  - `ShowQuestPanel`/`HideQuestPanel`: control manual del panel de gossip.
  - **Render de gossip propio** (Stage 2): panel superpuesto en `GossipFrame` (parchment `QuestBG` + fuentes de quest oscuras), pintado por estado en `GOSSIP_SHOW`/al definir; muestra oferta/progreso/entrega + boton Aceptar/Completar; NO toca las opciones nativas. **PRIMERA PASADA**: la disposicion final depende del gossip real de la fase y la coexistencia con hooks EpsilonLib; ajustar en juego con capturas.
  - **Progreso por inventario** (Stage 3): un objetivo con `item=<itemId>` avanza en `BAG_UPDATE_DELAYED` (`GetItemCount` -> `SetObjectiveProgress`), sin ticker. El indice del objetivo en la def coincide con el de HarfordQuests.
  - **Auto-completado compartido** (Stage): `HarfordQuests.RegisterCompletionListener` avisa cuando una mision se completa (todos los objetivos); para quests de mundo, `HarfordWorldQuests` difunde `QSTATE^id` al grupo y todos marcan completada (guard `sharedComplete` anti-bucle). El panel de gossip deriva el estado del progreso REAL del jugador (`IsAccepted`/`IsComplete`), no solo del aura; el swap de aura a `252527` es oportunista (oficial en el gossip).
  - **Como se engancha al NPC (Epsilon gossip tags)**: el ArcSpell (guardado en el PHASE vault con un `commID`) contiene una accion Script/Lua que llama `HarfordQuestAPI.DefineWorldQuest({...})`. Se adjunta al NPC poniendo el tag `<arcanum_cast:commID>` en el **texto de saludo del gossip** (auto-ejecuta al abrir, oculto para jugadores; en una opcion = al clicar). El sistema de tags esta en `SpellCreator/Gossip.lua` (`click_cast`/`auto_cast` -> `executePhaseSpell(commID)`). Como el tag re-ejecuta el ArcSpell en CADA apertura del gossip, `DefineWorldQuest` se re-registra solo tras reconexion; el ArcSpell no necesita registrar hooks `GOSSIP_SHOW` propios.
  - **Persistencia (clave)**: la *definicion* de la quest (`byNpc`/`byId`, textos por estado) vive SOLO en memoria y se re-registra al reabrir el gossip (el ArcSpell re-llama `DefineWorldQuest`, idempotente). Pero la mision ACEPTADA (titulo, objetivos con su `item`, `rewards`) se guarda en `HarfordQuests` (SavedVariables) al aceptar, asi que **sobrevive a la desconexion y aparece en el registro/tracker** (`AcceptCurrent` ademas la auto-rastrea). Por eso: el **progreso por inventario** itera las misiones ACEPTADAS (persistidas), no `byId` -> avanza tras `/reload` sin revisitar el NPC; y el **turn-in** lee `rewards` de `HarfordQuests.GetRewards` (persistido), fallback a la def. El `item` del objetivo se persiste en `HarfordQuests` (NormalizeObjectives/CopyObjectives lo conservan). **Anti DOBLE entrega**: `TurnInCurrent` aborta si `IsClaimed(id)` (flag "Recompensa" persistido) y SIEMPRE marca `MarkClaimed` al entregar (tambien money-only), asi que aunque reconectes y el aura del NPC siga en `252527`, no se reparte dinero+items dos veces; `RenderGossip` no re-ofrece turn-in a un PJ que ya cobro (claimed y no aceptada -> panel oculto).
  - Solo oficiales tocan el aura (`IsOfficerPlus`). `QSHARE`/`QSTATE`/`QREWARD` van por prefix `HARFORDQUEST`, sender validado grupo/raid. Debug: `/harford debug run worldquest define|state|accept|turnin|reward` sobre el NPC target.
- **DIRECCION ACORDADA: quests de fase por NPC como base**. Para las quests que dan NPCs del mundo, la BASE es el patron de fase Epsilon (gossip + auras + comandos de servidor), y Harford es la capa de PRESENTACION + RED encima. Reparto de responsabilidades:
  - **Fase = definicion + estado canonico**. La quest se define en el gossip del NPC. Estado MIXTO: (a) **marcador de estado = un aura SOBRE EL NPC** (decision del usuario: NO usar auras invisibles "quest invisibility" sobre el jugador). IDs confirmados: `155096` = disponible, `245633` = incompleta, `252527` = completada. El hook de gossip y Harford leen ese aura con `UnitAura("npc")`/`UnitAura("target")` en vez de hardcodear la creature-entry. (b) **variables de fase (`ARC.PHASE.GET/SET`) + inventario (`ARC.XAPI.HasItem`)** para el progreso de objetivos; (c) la creature-entry (`1988059`/`2024880`/`2024881`) queda como reflejo/alternativa visual. Recompensas = comandos de servidor (`.additem`, `.modify money`, `.aura`).
  - **MODELO RESUELTO: COMPARTIDO (estado de grupo)**. El aura del NPC es estado compartido: coger la mision cambia el NPC para todos. **Flujo al coger una mision (miembro de grupo/raid)**: (a) SIEMPRE la mision se comparte al grupo automaticamente (broadcast de la red de Harford; no requiere autoridad, cualquier cliente emite); (b) si el que la coge es **oficial** (`HarfordAuthority.IsOfficerPlus()`) ADEMAS hace el swap de aura en el NPC: quita `155096` (disponible) y pone `245633` (incompleta) via `HarfordServerActions.RemoveNpcAura`/`SetNpcAura` (comandos de servidor, ya existen); (c) si NO es oficial, no toca el aura (sin permiso de servidor) y la mision igual se coge y se comparte. Encaja con el eje "Oficial" del modelo de autoridad (comandos de servidor ligeros desde el core). **Completado AUTOMATICO + estado compartido** (decision del usuario): cuando se cumplen TODOS los objetivos, `HarfordQuests` marca la mision completada y `HarfordWorldQuests` lo **difunde al grupo** por `QSTATE` (con guard anti-bucle `sharedComplete`), de modo que a todos se les marca completada. El **panel de gossip usa el estado REAL del jugador** (aceptada+completada -> entrega, aunque el aura del NPC aun no cambie). El **swap de aura del NPC a `252527`** es OPORTUNISTA: lo hace un oficial cuando abre el gossip del NPC estando completada (no se puede hacer en remoto sin estar junto al NPC); el DM tambien puede hacerlo a mano. `MarkComplete` sigue disponible como override del DM. Ciclo de estado CERRADO.
  - **Harford = UI + red + reparto**. El ArcSpell del gossip llama a la API (`HarfordQuests.Accept`/`SetObjectiveProgress`/`MarkComplete`) para reflejar la quest en el quest log + tracker (mejor que `DummyQuestFrame`/`DummyObjectiveTracker`). El mapa aura-de-NPC->estado iria en `HarfordQuestCatalog` (campos tipo `availableAura=155096`/`activeAura=245633`/`doneAura=252527`). El progreso por inventario se engancharia con `BAG_UPDATE_DELAYED` -> `SetObjectiveProgress`, NO con `C_Timer.NewTicker` de 3s como hace la fase (regla de no tickers permanentes).
  - **Compartir NO lo resuelven las auras**: las auras son per-personaje server-side, no comparten entre jugadores. Compartir una quest al grupo y repartir rep/xp de raid sigue siendo la capa de RED de Harford (addon messages: `Accept` broadcast + modelo pull de recompensa + `CompleteForGroup` DM). O sea: fase = base de mundo/estado; Harford = base de compartir/UI. Son complementarios.
  - **Modelo de estado CERRADO** (compartido; oficial hace swap disponible->incompleta al coger; DM manual ->completada). Verificaciones tecnicas:
    - (2) **CONFIRMADO en juego**: un oficial SIN `.ph dm` puede aplicar/quitar el aura del NPC con `npc set aura`/`npc set unaura` -> el branch "oficial hace el swap" es valido sin modo DM.
    - (3) **CONFIRMADO: el progreso es AMBOS** -> objetivos por inventario (enganchar `BAG_UPDATE_DELAYED` -> `HarfordQuests.SetObjectiveProgress`, NO ticker) Y por variable de fase (el ArcSpell llama `SetObjectiveProgress` cuando pone su `ARC.PHASE.SET`).
    - (1) **CONFIRMADO en juego**: el aura de estado es legible en el NPC por ID. `/harford debug run scanauras` sobre el NPC mostro `[HELPFUL] id=155096 "Yellow Exclamation"`. El cliente Epsilon NO expone `C_UnitAuras`; el lector debe usar `UnitAura(unit, i, "HELPFUL")` (fallback `AuraUtil`), leyendo indice a indice y comparando `spellId`.
  - **Auras = 3 CONSTANTES GLOBALES** (mismas para TODAS las quests, decision del usuario): `155096` disponible, `245633` incompleta, `252527` completada. NO van por-entrada en el catalogo: son constantes de modulo. El aura solo codifica el **ESTADO**, no la identidad de la quest.
  - **Identidad de la quest = el ID del NPC TEMPLATE** (creature-entry, 6º token del GUID), CONFIRMADO por el usuario: NO el spawn unico. Varios spawns del mismo template = misma quest. El aura solo da el ESTADO.
  - **DISENO CERRADO Y VERIFICADO; listo para construir**. Nada implementado aun del puente.
- **Progreso de objetivo del DM al grupo**: `HarfordQuests.SetObjectiveProgressForGroup(id, index, current)` (gateado por `CanUseDMTools()`) aplica local + difunde `QOBJ|<index>|<current>|<id>` por prefix `HARFORDQUEST` (id ULTIMO, puede contener `|`; el receptor aplica `SetObjectiveProgress` si tiene la mision aceptada, y auto-completa si procede). UI: submenu "Objetivos (DM)" en el boton Opciones del registro (+1 / Completar / Reiniciar por objetivo). Complementa a `CompleteForGroup` (cierre total): esto es progreso granular. El handler de `HarfordQuests` (`|`) y el de `HarfordWorldQuests` (`^`) coexisten sin choque porque los formatos difieren. Recordatorio del modelo de recompensa: **item/oro son INDIVIDUALES del que ENTREGA** (turn-in del NPC), rep/xp compartidos (pull idempotente por `claimed`).
- **Override del DM para el grupo**: `HarfordQuests.CompleteForGroup(id)` (gateado por `HarfordAuthority.CanUseDMTools()`) marca local y difunde `QDONE|id` por prefix `HARFORDQUEST` (`HarfordSync.Send`/`BestChannel`). El receptor solo marca completa la mision si YA la tiene aceptada (`IsAccepted`), nunca crea misiones ajenas ni ejecuta comandos; sender validado como propio/grupo/raid via `HarfordClassColors.FindUnitByName` (nunca GUILD). Es el equivalente para misiones ad-hoc del `status=completed` del contrato.
- **API externa `_G.HarfordQuestAPI`**: alias estable y SEGURO para ArcSpells/macros (`Accept`, `Abandon`, `IsAccepted`, `IsComplete`, `GetObjectives`, `SetObjectiveProgress`, `AdvanceObjective`, `CompleteObjective`, `SetTracked`, `CompleteForGroup` [auto-gateado]). Solo estado de misiones del propio jugador; jamas transporta comandos de servidor. El camino "contador confirmable" es `SetObjectiveProgress`/`AdvanceObjective` desde el ArcSpell cuando el mundo dispara un evento real.
- **`HarfordQuestCatalog` (`Harford/Quests/HarfordQuestCatalog.lua`)**: catalogo hardcodeado de misiones canonicas (patron "indice + libro"), carga ANTES de `HarfordQuests`. Solo datos (misma forma que el `info` de `Accept`) + `Get(id)`/`GetIds()`; nada de logica de estado. Ampliar aqui las misiones reutilizables; las puntuales de una fase van por info libre.
- **Regla visual del quest log**: `HarfordQuestLog.lua` es una jerarquia Lua fragil ya validada en juego. Las interacciones de filas se limitan a su `OnClick`; no modificar `BuildFrame`, scrolls, fondos, capas ni anclajes de los controles superiores para cambios de comportamiento. La pestana "Todas" usa `UI-QuestLogSortTab` creado en Lua: marco, icono y texto se ajustan como una sola pieza.
- **Persistencia de misiones**: las lecturas no crean perfiles vacios en `HarfordQuestsStore`; solo una mutacion crea la entrada del PJ. `ClaimRewards` elimina tambien el rastreo de una mision cerrada. `HarfordQuests.Prune()` es limpieza manual de rastreos huerfanos/perfiles vacios; se expone en `/harford debug run contractclean quests` y nunca se ejecuta automaticamente.
- **Rastreo de misiones (`HarfordQuests` + `HarfordQuestTracker`)**: hay un subconjunto de "rastreadas" dentro de las aceptadas. Estado per-PJ en `HarfordQuestsStore.characters[pj].tracked = { [id]=true }`. API: `IsTracked(id)`, `SetTracked(id, on)` (solo rastrea si la mision esta aceptada), `ToggleTracked(id)`, `GetTracked()` (misma forma que `GetAccepted`, ordenada por antiguedad). `Abandon(id)` limpia tambien el rastreo. `GetAccepted()` expone ademas `tracked` por entrada para que el quest log pinte el estado del boton. Todas las mutaciones disparan `FireChanged()`, que repinta quest log + tracker (sin tickers).
- **`HarfordQuestTracker` (`Harford/Quests/HarfordQuestTracker.lua`)**: las misiones rastreadas Harford se insertan como modulo real de `ObjectiveTrackerFrame` Shadowlands; no existe un marco Harford independiente. En el arranque crea `HARFORD_QUEST_TRACKER_MODULE` mediante `ObjectiveTracker_GetModuleInfoTable` y usa las plantillas nativas `ObjectiveTrackerHeaderTemplate`, `ObjectiveTrackerBlockTemplate` y `ObjectiveTrackerLineTemplate`. Mientras `questtracker` esta activo, conserva una copia de las listas de modulos Blizzard, libera sus bloques y sustituye temporalmente `ObjectiveTrackerFrame.MODULES`/`MODULES_UI_ORDER` por la lista exclusiva `{ HARFORD_QUEST_TRACKER_MODULE }`: se mantiene el root, arte, layout, pool y colapsado nativos, pero no aparecen misiones automaticas, campañas, logros ni otros objetivos Blizzard bajo las misiones Harford. Si se desactiva la opcion, limpia Harford, restaura las listas nativas y las repinta. Un reason privado `0x40000000` actualiza solo Harford al cambiar `HarfordQuests.GetTracked()`; no hay `OnUpdate`, ticker ni anclajes manuales. Click izq abre `HarfordQuestLog.OpenTo(id)`; click der deja de rastrear.
- **Quest log (`HarfordQuestLog`)**: replica Lua de la variante **Shadowlands** `ClassicQuestLog 2.1.0`. El XML se conserva solo como referencia y **no se carga** desde `Harford.toc`: en Epsilon los scrolls hermanos declarados por XML acababan tapando el contenido Lua. `HarfordQuestLog.lua` es la unica fuente de la jerarquia: crea una raiz `ButtonFrameTemplate`, listado `HybridScrollFrameTemplate` con `QuestMapLogAtlas` recortado y detalle `QuestScrollFrameTemplate` con `QuestBG`; no debe coexistir con una carcasa XML. `API.OpenTo(id)` abre una mision concreta; ruta `/harford misiones`.
- **Recompensa estructurada del quest log = fuente unica del panel del ArcSpell**: el detalle del registro pinta la recompensa IGUAL que el gossip de world quest, reutilizando `HarfordQuestAPI.ResolveRewardItem(it)` (id->nombre/icono via `GetItemInfo`, re-pinta en `GET_ITEM_INFO_RECEIVED`) y `HarfordQuestAPI.GetRewardValueLines(rewards)` (expuestos desde `HarfordWorldQuests`; **no duplicar** la logica). Dinero/xp/rep en filas etiqueta FRIZQT + valor ARIALN blanco (valor anclado a `label.RIGHT(4,0)`, pegado al `:`); items en botones `QuestItemTemplate`. Reputacion: numero SIN `+`, verde `|cff33ff33` si suma / rojo `|cffff3333` si resta, faccion en blanco. Fallback a texto plano (`quest.reward`) solo si no hay `rewards` estructurados. `LayoutPanel` (gossip) y `LayoutDetail` (registro) son layouts SEPARADOS: cambios de offset/estilo van en AMBOS.
- **Boton "Compartir" del registro**: cablea `HarfordQuestAPI.ShareQuest(id)` (= `HarfordWorldQuests.ShareAcceptedQuest`, reusa el formato `QSHARE` con el display persistido). Solo habilitado con grupo/raid (`IsInGroup`/`IsInRaid`); se re-evalua con `GROUP_ROSTER_UPDATE` mientras el registro esta abierto.
- **Enlace de mision en chat = TRP3 ChatLink** (`HarfordTRP3.InsertQuestChatLink(quest)`, modulo `harford_quest`): **LIMITACION CONFIRMADA**: un enlace 100% nativo (`|Hquest:id|h`) es IMPOSIBLE para misiones que solo existen en el addon (el cliente resuelve el `questID` contra su DB de quests reales; las Harford no existen alli -> tooltip vacio). Los hyperlinks de tipo propio no son clicables y `ChatFrame_OnHyperlinkShow` esta vetado. Por eso el enlace usa TRP3 (decision del usuario: mantener TRP3 clicable). Queda **casi nativo**: TRP3 envuelve el link reconstruido en `LINK_COLOR = ColorManager.YELLOW`, o sea sale AMARILLO `[Titulo]` como un enlace de quest nativo (no un color TRP3 distinto); el **texto** del enlace NO es controlable (TRP3 lo fuerza a amarillo; igual que un enlace de quest nativo en chat, que SIEMPRE es amarillo — la dificultad solo colorea la lista del cuaderno, no el hyperlink). El **tooltip SI es controlable** (`GetTooltipLines`): el titulo va coloreado por DIFICULTAD via `HarfordTRP3.InsertQuestChatLink(quest, titleColorHex)` (hex `ffRRGGBB` que el registro calcula con `DifficultyColorHex` = misma fuente `HarfordContracts.Data.GetDifficulty().color` que la lista); default amarillo. El titulo se embebe con `|c<hex>` porque TRP3 fuerza el titulo del tooltip a blanco (mismo truco que los enlaces de habilidad). **CLAVE**: para insertar en el editbox hay que usar el `ChatLinkModule:InsertLink` de TRP3, que inserta el marcador PLANO `[TRP3:id]` (`LINK_PATTERN`), NO el hyperlink `|Htotalrp3:...|h` crudo. WoW ELIMINA los hyperlinks `totalrp3` de los mensajes que ENVIA un jugador (el mensaje sale vacio); el filtro `AddMessageEventFilter` de TRP3 reconstruye `[TRP3:id]` como link clicable al RECIBIRLO. El hyperlink completo solo vale para render LOCAL via `AddMessage` (asi funcionan los enlaces de habilidad, que NO se tocaron). Gesto: shift-click en una fila del registro con un editbox de chat abierto inserta el enlace; sin chat abierto togglea rastreo (imita al nativo).
- **Boton "Opciones" del registro = solo DM**: visible solo con `HarfordAuthority.CanUseDMTools()` (admin + `.ph dm`) y mision seleccionada; se re-evalua con `HarfordAuthority.RegisterChangeListener("HarfordQuestLog", ...)`. Abre `EasyMenu` con acciones de estado reales: Marcar completada (grupo) `CompleteForGroup`, Reiniciar entrega `ResetClaim`, Repartir recompensa a ausentes `HarfordQuestAPI.DmSendReward`. Editar la DEFINICION de la mision en el phase (objetivos/recompensas) queda pendiente: las defs viven en los ArcSpell del phase, no en el addon.
- **Submenu "Misiones" del menu DM de unidad** (`HarfordAdminUnitMenu`, solo NPC): fija el estado de mision del NPC eligiendo una de las 3 auras (`HarfordWorldQuests.AURA_AVAILABLE/INCOMPLETE/COMPLETE`, fuente unica). Hace swap LIMPIO: quita las otras dos auras de estado (`HarfordAdminNPC.RemoveAuraFromTarget`) antes de fijar la elegida, para que el NPC nunca tenga dos estados a la vez.
- **Compartir ESTRUCTURADO (`QSHAREF`)**: al aceptar/compartir una world quest, `HarfordWorldQuests.ShareAcceptedQuest` envia `QSHAREF` con objetivos (texto+required+item) y recompensas (rep/xp/money/items) serializados, para que el receptor vea la MISMA ficha y su auto-completado/inventario funcione (antes `QSHARE` solo mandaba texto y los miembros compartidos no podian completar). Formato: 14 campos `^`, con `Esc`/`Unesc` que ademas reservan `;` (items de lista) y `=` (sub-campos) via `SerializeObjectives`/`DeserializeObjectives`. Guard de tamaño `MAX_SHARE_BYTES=240`: si se pasa, cae a `QSHARE` texto-only. `AcceptCurrent` usa la ruta unica `ShareAcceptedQuest` (se retiro `BroadcastShare`). El receptor entiende `QSHAREF^` y `QSHARE^` (legacy).
- **XP propia de Harford**: Epsilon no tiene un comando fiable de XP real (`.mod xp`/`.modify xp` no disponible), por eso `HarfordCharacterXP` guarda la experiencia D&D 5e en la progresion del perfil. `ClaimRewards` concede `reward.xp` mediante `HarfordCharacterXP.AddXP`; al cruzar un umbral avisa de nivel disponible, pero nunca sube el nivel automaticamente. Las recompensas compartidas de grupo deben propagar tanto reputacion como XP a cada miembro; dinero e items siguen siendo del personaje que entrega/reclama.
- **Reconciliacion de world quest al reconectar**: si el grupo completo la mision estando yo desconectado (perdi el `QSTATE` en vivo), al reabrir el gossip del NPC `RenderGossip` cierra la mision localmente si `ScanAuraState("npc")=="completed"` y la tengo aceptada+incompleta (el aura del NPC es el estado CANONICO). Marca `sharedComplete` para no re-difundir.
- **Baseline de objetivo por inventario (`itemBase`)**: `NormalizeObjectives` guarda `itemBase = GetItemCount(item)` al aceptar; `RefreshItemObjectives` cuenta `GetItemCount - itemBase` (solo lo recogido DESPUES, no lo que ya llevabas). Se preserva al re-aceptar y viaja en `CopyObjectives`.
- **Feedback de completado**: `HarfordQuestLog` registra un `RegisterCompletionListener` que suena `SOUNDKIT.UI_QUEST_ROLLING_FORWARD_01` + avisa en chat con el titulo cuando una mision se cierra (objetivos/DM/compartido). El core NO reproduce sonidos; el feedback vive en la capa UI.
- **Generador de ArcSpell DM**: `/harford debug run questarc <catalogId>` (con el NPC en target) emite en ventana copiable el Lua del ArcSpell (`HarfordQuestAPI.DefineWorldQuest{...}`) desde una entrada de `HarfordQuestCatalog` + el template id del target. Camino intermedio de autoria DM: evita escribir la def a mano y reduce el drift (el editor DM completo de la def en el phase sigue pendiente).
- **UNIFICACION Contrato = Mision de mundo** (editor DM del tablon como fuente unica): un contrato puede declarar `worldNpc` (template id) y entonces es TAMBIEN mision de mundo. `TC.RegisterWorldQuestFromContract(contract)` (en `HarfordContractsCore`) construye la def estructurada (objetivos texto->{text,required=1} + recompensas rep/xp/money/items) y la entrega a `HarfordQuestAPI.DefineWorldQuest`; `TC.RegisterAllWorldQuests()` se llama dentro de `TC.Refresh()` (chokepoint: login, entrada al mundo, sync Comm, guardar/publicar DM), idempotente. **Asi el gossip del NPC muestra la mision SIN ArcSpell** (el ArcSpell deja de ser necesario para la def; el estado sigue en el aura del NPC, oficiales).
  - **Recompensa estructurada de contrato**: el contrato ya tenia `rewardXP`/`rewardRep{faction,amount}`/`rewardItems`; se añadio `rewardMoney{gold,silver,copper}` y `rewardRep.factionId` (id estable). La Comm serializa los campos nuevos AL FINAL del `PUB` (18=factionId, 19-21=money, 22=worldNpc; compat con clientes viejos). El puente `HarfordContractsUI` (Seguir mision) pasa `rewards` ESTRUCTURADO a `HarfordQuests.Accept` (antes componia texto y perdia la estructura) -> el registro muestra la ficha nativa y la rep se concede al reclamar.
  - **Reputacion de mision con id estable**: `HarfordQuests` rep = `{faction=nombre, factionId=id, amount}`; `ClaimRewards` concede con `GrantSelfReputation(rep.factionId or rep.faction)` (id robusto ante typos/tildes; el display usa el nombre). El editor DM guarda el id.
  - **Anti DOBLE reputacion**: `TC.Rewards.Reconcile` (rep/xp de contrato completado, clave de claim `"contract:<id>"`) SALTA los contratos con `worldNpc`: esos reparten por la ruta del world quest (turn-in del NPC + `DmSendReward`, clave `<id>` pelado). Sin ese guard, un contrato-mision-de-mundo concederia la rep DOS veces. NO reintroducir la reconciliacion de contrato para world quests.
  - **Objetivos de contrato = booleanos**: los objetivos del contrato son strings -> `{text, required=1}`; NO tienen contador `required>1`. El DM los cierra con el submenu "Objetivos (DM)" del registro (`SetObjectiveProgressForGroup`). Para contadores reales (0/50) haria falta objetivos estructurados en el contrato (pendiente). Un `worldNpc` compartido por dos contratos hace que el ultimo registrado gane `byNpc[tid]` (usar NPCs distintos).
  - **VARIAS reputaciones por mision** (`rewardReps` = lista de `{factionId, faction, amount}`): el editor acumula con "Añadir rep" (dropdown + cantidad, cantidad SIN `SetNumeric` para permitir **negativas**). Se serializa en la Comm como campo 23 `factionId:amount,...` (el nombre lo resuelve el receptor por `HarfordReputation.GetFaction`). `HarfordQuests` rewards lleva `reps` (lista) ademas de `rep` (una, `reps[1]`, legacy); `ClaimRewards` concede cada una (si NINGUNA resuelve su faccion, no marca reclamada -> reintento). `RewardLines` pinta una fila por rep. Fuente unica: bridge/Core/board display iteran `rewardReps` con fallback a `rewardRep`.
  - **DINERO como BOTE UNICO** (lo cobra UNA persona, como los items): `TC.Data.ClaimMoney` marca `rewardMoney.claimed`; boton "Cobrar dinero" en el detalle (visible solo si Completado + hay dinero + no cobrado). Sync `CLAIMMONEY|id` -> el DM (autoridad) `ClaimMoney` + `SyncPublicContracts`. El jugador se auto-entrega con `HarfordServerActions.GiveMoney` (`modify money`). **NO se muestra el boton en contratos con `worldNpc`**: ahi el dinero lo entrega el turn-in del NPC (evita doble cobro). Serializado como campo 24 (`claimed` 0/1).
  - **Panel de detalle del tablon = orden Localizacion(negro) -> Descripcion -> Objetivos -> Recompensa**; el subtitulo (meta) NO lleva dificultad (redundante con el color del titulo) y usa separadores grises `|cff808080 || |r` (`FormatContractMeta` + inline). La recompensa se pinta con el MISMO sistema que el registro (cabecera + filas etiqueta FRIZQT negra / valor ARIALN blanco outline via `GetRewardValueLines`). CUIDADO con ciclos de anclaje: `rewardItemsPanel` depende de `detailReward->detailDescription->detailLocation->detailIcon`; las ramas "vacias" (tipo/all/select) DEBEN anclar `detailDescription` a `detailIcon` (nunca a `rewardItemsPanel`).
  - **Editbox multilinea del editor DM** (`CreateLargeEditBox`): usar **`InputScrollFrameTemplate`** con `EditBox:SetWidth(ancho-34)` (patron de EpsilonLib/SpellCreator en este cliente). NO usar `UIPanelScrollFrameTemplate` + helpers `ScrollingEdit_*` (petan `scrollFrame boolean` y rompen el cursor), NI meter el editbox como scroll-child de un ScrollFrame manual (rompe el click-to-cursor), NI medir con `EditBox:GetStringHeight` (no existe, es de FontString).
  - **Selector de reputacion JERARQUICO** (editor DM): `RepFactionDropDownInit` (UIDropDownMenu) organiza por **grupo -> subgrupo -> faccion** desde `HarfordReputation.GetGroups()`/`GetFactions()` (no lista plana); guarda `factionId`+nombre. Sin grupos, cae a lista plana. El editor tambien tiene campos de dinero (oro/plata/cobre) y `NPC mundo` con boton "Usar target" (autorrellena el template id); el frame del editor se amplio a 884px y esos campos van al FONDO (debajo de Notas DM) para no colisionar con Descripcion.
- **Regresion de quest log (junio 2026)**: no volver a cargar `HarfordQuestLog.xml` junto con la construccion Lua. La variante actual oculta los iconos de fila y añade `Shift+click` exclusivamente dentro del `OnClick` de una mision para llamar a `HarfordQuests.ToggleTracked(id)`; el click normal solo selecciona. Las mejoras de interaccion no deben modificar `BuildFrame`, scrolls, fondos ni capas. Antes de tocar el aspecto, guardar el archivo Lua en un commit o snapshot recuperable.
- **Debug**: `/harford debug run questtest` acepta 2 misiones del catalogo (objetivos con contador) y rastrea una. Sub-usos: `clear` (abandona todas), `obj <id> <i> <n>` (`SetObjectiveProgress`), `adv <id> <i>` (`AdvanceObjective` +1), `done <id>` (`CompleteForGroup`, requiere DM). Sirve para probar quest log + tracker + progreso/completado sin un contrato real.
- `HarfordContracts` conserva UI/core en Harford, pero las herramientas globales de publicacion/edicion requieren `HarfordAuthority.CanUseDMTools()` (`HarfordAdmin activo + .ph dm activo`). No usar solo `.ph dm`. `HarfordContractsData` tambien bloquea crear/borrar/ordenar contratos si no hay permisos DM, aunque la UI ya lo valide.
- El tablón no se registra en `HarfordToolTray`: se abre desde la entrada Contratos del Comunicador o mediante `/harford contratos`. La ruta embebida usa `HarfordContractsUI.OpenEmbedded(parent, onClose)`/`CloseEmbedded()` y restaura el Comunicador al cerrar o cambiar de pestaña; `OpenStandalone()` queda reservada a un tablón físico futuro.
- Recompensas por item: el cliente marca localmente la recompensa como extraida solo de forma provisional; si `HarfordServerActions.GiveItem` no confirma, `UnclaimRewardItem` revierte el contador. El mensaje remoto `CLAIM` solo se publica despues de confirmar la entrega.
- `HarfordContractsComm` mantiene una memoria efimera `sender:contractId:rewardIndex` para ignorar duplicados exactos de `CLAIM` durante la sesion. No se persiste; solo evita doble consumo por mensajes repetidos.
- Limitacion de confianza de red vigente: los addon messages no firman autoridad remota. Mensajes de grupo como `RDELTA`, turnos o contratos confian en el canal/addon y en gates locales al emitir. No ejecutar comandos servidor recibidos por red. Si se necesita endurecer esto, el siguiente paso sera un protocolo de autoridad DM explicito, no aceptar comandos arbitrarios.
- Visibilidad del tablon: jugadores pueden ver/abrir contratos no `draft` ni `archived` (available/accepted/preparing/active/completed) para seguir progreso y reclamar recompensas completadas. El DM conserva filtros por estado y puede ver borradores/archivados.
- **Sistema de votos RETIRADO**: se elimino por completo (datos `db.votes`/`contract.votes`, API `Vote`/`RecountVotes`/`GetVotersForContract`/`ResetVotesForContract`, UI del boton de voto y columnas de votantes del resumen DM, sync `VOTE`/`VOTECLEAR`/`VOTERESET` y el bloque `VOTES` del snapshot, y las lineas `V` del backup). Por compatibilidad, los receptores IGNORAN en silencio mensajes de voto de clientes sin actualizar y saltan un bloque `VOTES` heredado dentro de un snapshot (sin inyectarlo como contrato). No reintroducir votos.
- **Orden UNICO de misiones (sin reordenacion manual)**: `TC.Data.CompareByDifficulty` ordena por dificultad de menor a mayor (`GetDifficultyRank`) y, dentro de cada dificultad, alfabetico por titulo (sin acentos via `StripAccents`, minusculas). `GetContractsByCategory` y el resumen DM usan este comparador. Se retiraron `MoveContractInCategory`/`SortCategoryByDifficulty`/`NormalizeCategoryOrder` y todos los controles manuales (botones Subir/Bajar/Ordenar del detalle, flechas ^/v de la lista, boton "Ord" del pager). El campo `sortOrder` sigue en creacion/backup por compatibilidad pero YA NO se usa para ordenar. No reintroducir orden manual.
- `TCBOARD` publica exclusivamente desde el DM local (`HarfordAdmin` + `.ph dm`). La sincronizacion actual es un **snapshot**: `SNAPBEGIN|id|cantidad`, contratos `PUB` fragmentados y `SNAPEND|id` (ya sin bloque `VOTES`). El cliente conserva el tablon anterior hasta recibir el cierre con todos los contratos esperados (`received == expected`); entonces reemplaza su copia publica completa, retira contratos ausentes y conserva solo sus borradores locales. Notas privadas y `prep` nunca se serializan. Las reclamaciones de recompensa son solicitudes: solo el DM consume la cantidad y vuelve a publicar el snapshot; los clientes no alteran su copia al recibir la solicitud. Los ids de transferencia y de contrato usan contadores monotonicos de sesion, no aleatorios cortos. Se limita la memoria runtime a 64 transferencias y los buffers/snapshots caducan a los 60 s. `PUB` aislados heredados solo actualizan si el sender ya es la autoridad; `EMPTY` heredado no puede aduenarse del tablon. `STATUS` solo se acepta desde la autoridad de sesion. No hay firma remota fuerte: el primer snapshot completo valido fija la autoridad hasta que termina la sesion.
- **Llevar el tablon de una fase a otra**: `Phase.CopyBoardHere()` (`/harford contratos copiar`, con confirmacion y los numeros delante) es la UNICA via legitima. **Es ADITIVA**: escribe los bloques que faltan y anade al indice del destino sin retirar nada de lo que ya haya. No confundir con `Publish`/`PublishTracked`, que FUSIONAN y por eso se niegan a cruzar fases (`phaseOrigin`): publicar en B un tablon bajado de A retiraria de B todo lo que A no tuviera. En choque de ids gana el **destino** — copiar no pisa lo que otro DM tenga montado aqui — y los omitidos se listan por titulo. Requiere modo DM **y** `CanWrite()` (oficial). Al terminar reasigna `phaseOrigin` a la fase actual, para que la siguiente publicacion normal no se bloquee. Igual que en `Publish`, una lectura FALLIDA del indice del destino aborta la copia: no es una fase vacia, y confundirlas perderia lo que hubiera. Limitacion de Epsilon detras de todo esto: `C_Epsilon` solo lee la fase en la que ESTAS, asi que la secuencia obligada es cargar en A, viajar a B y copiar; abrir el tablon en B antes de copiar dispara `ApplyIndexReplacing` y retira de la lista local los contratos de A (se avisa por chat antes de hacerlo, recordando el comando). Los borradores no viajan a la fase ni los toca la fusion, asi que pasar un contrato a borrador es la via manual para cruzarlo sin comando.
- **Recompensa compartida de contratos, boton por mision**: `TC.Rewards` expone `SharedKey(contract)` = **el id PELADO del contrato**, deliberadamente la MISMA clave que usan el listener de completado de `HarfordQuests` y la ruta de mision de mundo. **Bug corregido (doble concesion de reputacion)**: esta ruta uso durante un tiempo el prefijo `contract:` mientras el listener usaba el id pelado; como el recibo va POR CLAVE, ninguna bloqueaba a la otra y un contrato completado que ademas tuvieras aceptado en el registro concedia rep/XP **dos veces** (verificado en el ledger de un PJ real, con los dos recibos del mismo contrato). `LegacySharedKey(contract)` devuelve la clave antigua y **nunca se escribe**: solo se consulta, en `IsSharedClaimed` y como cortafuegos al principio de `ClaimShared`, para reconocer lo ya cobrado entonces y no volver a concederlo. No volver a introducir una clave distinta por ruta, `HasShared` (XP o reputacion; oro y objetos NO, que son individuales de quien entrega), `IsSharedClaimed` (recibo per-PJ via `HarfordQuests.IsSharedRewardsClaimed`), `IsSharedClaimable` y `ClaimShared(contract)`. `Reconcile()` y el boton de la UI llaman a la MISMA `ClaimShared`, asi que no pueden divergir ni conceder dos veces (el recibo por componente de `HarfordQuests.ClaimRewards` es idempotente). El boton `sharedClaimButton` del panel de detalle se muestra si el contrato esta `completed`, reparte rep/XP y no es `worldNpc`, y **se queda visible pero DESACTIVADO cuando ya se cobro** (a diferencia del de dinero, que se oculta): es la unica forma de que el jugador vea que esa mision ya le pago. Los `worldNpc` se excluyen SIEMPRE de esta ruta porque su rep/XP la reparte el turn-in del NPC y cobrarla aqui la daria dos veces.
- **Cierre de mision del tablon al entregar**: `HarfordWorldQuests.TurnInCurrent` llama a `HarfordContracts.Comm.ReportCompletion(def.id)`. Si quien entrega es **oficial** (`TC.Phase.CanWrite()` -> `HarfordAuthority.IsOfficerPlus`), cierra el mismo la mision en la fase con `TC.Phase.CompleteContract`, que reescribe SOLO el bloque de ese contrato y su fila del indice (no republica el tablon, ni exige ser DM, ni tener el tablon local al dia; lee el bloque y toca solo `status` para no pisar cambios de otro DM). Si NO es oficial, emite `TCDONE` por susurro al lider del grupo, y si no hay lider identificable al canal; cualquier oficial que lo reciba lo cierra. Cerrar es idempotente, asi que dos avisos no hacen dano. No anadir una ruta cliente->DM aparte: esta ya cubre los dos casos.
- **Dificultad de contratos**: la escala publica es exactamente `gray` (Muy facil), `green` (Facil), `yellow` (Media), `orange` (Dificil) y `red` (Muy dificil), de menor a mayor. `HarfordContractsData.NormalizeDifficultyKey` traduce las claves heredadas sin perder contratos: `easy -> green`, `normal -> yellow`, `hard -> orange`, `veryHard/boss -> red`. Todo contrato nuevo usa `yellow`.
- Los contratos de ejemplo/desarrollo no se siembran nunca durante el arranque. `TC.Data.EnsureSampleContracts()` se conserva solo como helper de desarrollo y no debe llamarse desde el core. Los contratos existentes en SavedVariables no se borran automaticamente.
- El tablón no implementa solicitudes manuales de sincronización: no existe botón ni mensaje `REQUEST`. La sincronización se inicia desde las herramientas DM mediante publicación explícita. Borradores y archivados son datos privados del DM y no forman parte del snapshot publico.
- Objetos/recompensas de contratos usan `HarfordServerActions.GiveItem`; no enviar `.add` por `SendChatMessage`. La extraccion reserva el contador local, espera callback de `EpsilonLib.AddonCommands` y revierte con `TC.Data.UnclaimRewardItem` si el servidor no confirma la entrega o si el comando ni siquiera se pudo enviar; solo despues de exito se publica `CLAIM`.
- La UI de contratos mantiene un bloqueo runtime `pendingRewardClaims[contractId#index]` mientras espera la confirmacion del servidor para impedir doble click/doble entrega local. No persistir este bloqueo: si hay `/reload`, el contador real `claimed` vuelve a ser la fuente.

## Cobertura De Clases 1–6

- La web publica es el indice canonico del contenido curado de esta tanda; `RuleSource/Rulebooks/` valida cada regla, traduccion, icono y texto antes de que llegue al addon. TRP3 solo identifica clase, nivel, subclase y elecciones. Un rasgo del Libro no se considera mecanizado hasta que tenga un disparador y una ruta verificable.
- Lote marcial inicial revisado: `Guerrero`, `Monje` y `Cazador de Demonios`. `Segundo Aliento` usa el dado de golpe d10; `Ataque Extra` reutiliza la tirada normal una sola vez contra el mismo GUID; `Artes Marciales` usa siempre Destreza y mejora solo el dado cuando corresponde; `Mordida de Demonio` exige un ataque normal reciente al mismo objetivo, consume 1 Vil y hace dos ataques sin modificador al daño.
- Las reglas que Harford no puede observar (aliado adyacente, primer turno real, posicionamiento, mascota o efectos narrativos) siguen como accion/reaccion guiada. No convertirlas en bonos pasivos ficticios.
- Fuente adicional ocasional: `RuleSource/Rulebooks/Heroes of Warcraft 5º (Alt).txt`. Su contenido puede estar en ingles; todo rasgo que se incorpore al Libro se traduce al espanol y se modela con los mismos efectos declarativos, nunca copiando texto o Lua ejecutable. Primera incorporacion: `Sacerdocio de Elune`, subclase de Sacerdote exclusiva de `elfo_noche`. A nivel 1 concede Canalizar Divinidad y `Gracia de Elune` (estado de diez rondas); a nivel 3 concede competencia con armadura ligera/media, `Golpe Lunar` y `Furia de Elune` (un ataque de arma tras un truco de sacerdote, usos por Mod. Carisma y descanso corto); a nivel 6 concede Ataque Extra. Los conjuros concedidos se resuelven desde el Compendio en vivo. `Explosión lunar` se incorporó traducida como conjuro de nivel 3 y concentración con sus tres fases; el motor automatiza la primera salvación/daño y el jugador gestiona las dos fases posteriores hasta que exista un motor explícito de repetición de concentración. `Curar heridas en masa` y `Carcaj veloz` son nivel 5 y quedan fuera de la cobertura actual 1-6.
- Proximos lotes: hibridos y transformaciones, luego lanzadores. Dotes y trasfondos permanecen fuera de esta auditoria.

## Creacion de fichas y About TRP3

- **Estado de la creacion automatica**: esta tanda esta en curso. La web amplia los datos que usara el creador, pero no sustituye todavia el flujo local ni garantiza que todo el contenido web este importado o mecanizado. Antes de declararla funcional se debe revisar la importacion web -> addon, validar un personaje nuevo de cada clase/subclase hasta nivel 6, comprobar elecciones y conjuros 0-4 y ejecutar pruebas en Epsilon.

- **Flujo de creacion (2026-08-21)**: el asistente de creacion confirma SOLO el nivel 1 — el validador `HarfordCharacterCreation.Apply` exige total 1 — y al aplicar encadena AUTOMATICAMENTE las subidas a nivel 2 y 3 (`S.autoLevelTarget = 3`; `FinishLevelUp` reabre `OpenLevelUp` hasta alcanzarlo; `OpenPrototype` lo resetea). La barra de pasos es NAVEGABLE (`GoToStep`: saltar de seccion no pierde elecciones; entrar en Clase solo inicializa el plan la primera vez) y la estrella de completado exige confirmacion EXPLICITA del boton principal ademas de datos completos (`S.confirmedSteps` + `StepDone`; el valor dorado es solo del paso seleccionado, confirmado en claro, resto apagado). El ancho del frame se adapta a la seccion con `ApplyModeLayout` ("grid" 1200 razas/trasfondos, "list" 996 clase/subida con botones de 210px con icono+color de clase, "none" 776 caracteristicas/elecciones sin columna de seleccion), conservando la esquina superior izquierda al cambiar de ancho para que el cursor no se desplace. Tarjetas de origen SIN plantilla azul: atlas `raceicon-<token>-<genero>` segun `UnitSex(player)` (fallback `Achievement_Character_<token>_<genero>` via `GetFileIDFromPath`, ultimo recurso el icono del libro); **SIN marco circular ni mascara** (decision 2026-08-20: `AddMaskTexture` no recorto de forma fiable en estas tarjetas; hover = aclarado de tarjeta, seleccion = tinte dorado de fondo). La descripcion de raza/trasfondo vive DENTRO del scroll y los rasgos arrancan bajo su altura medida (no se solapan con descripciones largas); `CreateNode` calcula el ancho de fila desde su sangria para cerrar todas en el mismo borde derecho. Caracteristicas: compra por puntos y 4d6 comparten layout (nombre x6 / botones / racial blanco + total oro + modificador `ModifierText` verde-rojo-gris); en 4d6 el racial se anuncia en verde ANTES de asignar el dado y ambos sistemas tienen Reiniciar.
- **Subida moderna de nivel**: `HarfordCharacterAdvancement.OpenLevelUp()` parte de la progresion actual, fija el objetivo en exactamente `nivel total + 1` y solo permite cambiar clase, subclase y elecciones de ese nivel. El limite absoluto de personaje es `HarfordDnDProgression.MAX_TOTAL_LEVEL = 20`: `SetClassEntry` lo valida tambien en ediciones, importaciones y debug, y la flecha/asistente se ocultan o rechazan la apertura al alcanzarlo. `FinishLevelUp()` persiste esos cambios y regenera el About local TRP3; no reabre ni reescribe origen, caracteristicas, equipo ni otros datos de la ficha. Se abre con `/harford char subir` o desde la flecha junto al nivel del panel de personaje.
- **Flecha junto al nivel**: se tomo del `ReputationBar` nativo mediante `FrameDump.lua`, no de una ruta supuesta. El boton usa `FileDataID 130821` (normal/pulsado), `130837` (highlight), mide `13x13` y se ancla a la derecha del texto. El numero de nivel conserva su centro exacto en el `ValueBounceFrame`; nunca desplazarlo para dejar hueco a la flecha. Si se altera, volver a capturar el control nativo antes de editar.
- **Pruebas de progresion**: solo en `HarfordDebug`: `/harford debug run xp <cantidad>`, `/harford debug run rep <faccionId> <cantidad>` y `/harford debug run nivel <1-20> [indiceClase]`. Son atajos locales de diagnostico; no son una via de juego, no deben migrar al core ni sustituir XP, recompensas o el asistente de subida.

- **`HarfordTRP3.WritePlayerAbout(content)`**: escribe el About del perfil LOCAL. Harford fuerza
  siempre la **plantilla 2** (`TE=2`, `T2`): acepta una lista de frames `{ IC=icono, TX=texto }` y,
  por compatibilidad, convierte una cadena en un unico frame T2. Escribe IN-PLACE sobre
  `getPlayerCurrentProfile().player.about` (wipe+copia sin cambiar la
  referencia), sube `v` para propagar por intercambio y dispara `REGISTER_DATA_UPDATED`. BUG historico
  corregido: el antiguo `register.saveInformation(playerID, "character", copiaDelPlayer)` anidaba TODO
  el player bajo la clave "character" y escribia en el nivel equivocado (top-level `.about` en vez de
  `.player.about`). **Esquema obligatorio:** aunque el About activo sea T1 o T2, se deben persistir
  siempre `T1`, `T2` y `T3 = { PH = {}, PS = {}, HI = {} }`. El editor nativo de TRP3 indexa las tres
  plantillas antes de decidir la activa y falla con `Nil template1 data or not a table` si falta una.
  Harford solo garantiza este esquema cuando crea o regenera una ficha propia; no repara ni altera
  automaticamente perfiles existentes. **No enganchar, envolver ni sustituir el `OnClick` del boton
  Editar nativo de TRP3**. Los
  frames T2 solo tienen `IC`/`TX`/`BK` (sin titulo); todo el contenido va en
  `TX` y solo se muestran frames con `TX` no vacio.
  **Despliegue:** el `.toc` carga `TRP3\\HarfordTRP3.lua`; al probar en Epsilon hay que copiar el
  fuente a esa subcarpeta, nunca a `AddOns\\Harford\\HarfordTRP3.lua` en la raiz.
- **`HarfordCharacterCreation.BuildAbout(draft, profileName)`** devuelve la lista de frames del About,
  calcada 1:1 de los perfiles reales del proyecto (Hizdahr/TH/Reena): frame "Ficha" (identidad +
  caracteristicas con iconos y colores + PG/PM/Armadura + Competencia/salvaciones/habilidades), frames
  de raza/trasfondo/clase (titulo centrado + cada rasgo `{h2}{icon} Nombre` + descripcion), y frames de
  MAGIA (ver abajo). Colores: puntuacion `a7a7a7`, mod `+ 00ff00`/`- ff0000`, competencia `14b200`,
  derivados `ff9900`, dados/cian `00ffff`, gris mecanico `cccccc`. Iconos de caracteristica y de frame
  de raza (por genero via `UnitSex`) extraidos de los perfiles reales; sin dato -> generico, nunca
  inventar. Colores de spec por subclase en `SUBCLASS_SPEC_COLORS` (extraidos de los perfiles).
- El texto de rasgo se pasa por `ColorizeDescription` (dados/ventaja en cian, acciones/descanso en
  gris) SOLO al generar el About; el dato del libro queda en texto plano (el panel pinta la descripcion
  cruda con `SetText`, sin convertir markup TRP3). `IsMarkerFeature` filtra marcadores (Incremento,
  Idiomas, Versatilidad, Competencias, Equipo) que los perfiles no muestran como rasgo, y ADEMAS
  delega en `HarfordCharacterBook.IsSubclassMarker` para los marcadores de eleccion de subclase
  ("Arquetipo marcial", "Estudio Magico", "Camino Sagrado"...). Ese predicado era local del Libro y
  se expuso para que About y Libro compartan criterio: duplicar la lista de nombres (arquetipo,
  senda, camino, estudio, tradicion, llamado, vinculo, presencia, marca) la dejaria desincronizada
  a la primera clase nueva.
- `HarfordCharacterCreation.Apply` crea la ficha Harford PRIMERO (no depende de TRP3) y el About es
  best-effort. **`HarfordCharacterCreation.RewriteAbout(profileName)`** regenera el About desde el
  estado actual (progresion + conjuros del compendio) reconstruyendo un draft; es la via para que
  aparezcan las secciones de magia tras elegir conjuros. Las razas con PJ de ejemplo en los perfiles
  tienen descripciones completas de rasgos porteadas a `HarfordDnDRaces.lua` (markup `{col:}` quitado,
  numeros baked genericizados a formulas).
- **Secciones de magia**: `BuildMagicFrames` genera HASTA DOS frames por clase lanzadora
  (`Magia <Clase>` y `Magia <Sub>`), con cabecera "Ataque Conjuro +N || DC Conjuro N" y conjuros por
  nivel (Trucos, Nivel N (mana)). Une SIEMPRE los trucos de `knownSpells` con el pool del modo
  (`wizardBook`/`preparedSpells`/`knownSpells`). Reparto y precedencias: ver "Frames del About:
  corte por clase/subclase" mas abajo.
- **Progresion magica** (`HarfordCompendioCore`): `SPELL_PROGRESSION` da por clase y nivel 1-6 los
  `cantrips` (tabla), `spells` (pool fijo: known o libro del mago; ausente en prepared), y la formula
  `prepared` ("full"=Mod+nivel, "half"=Mod+1/2 nivel). Accesores `GetSpellPickCounts(clase, nivel)`
  (delta a elegir) y `GetPreparedCount(clase, modCaract, nivel)` (calculo). Numeros de Libro 1.
- **Picker de conjuros embebido** (`HarfordCharacterAdvancement`): en el paso de nivel de una clase
  lanzadora, botones "Trucos/Libro/Conjuros/Preparar (X/Y)" que abren un modal (patron del selector de
  elecciones). Al crear la ficha, `PersistSpellPicks` escribe al compendio (cantrips->knownSpells,
  pool->knownSpells/wizardBook, preparados->preparedSpells) ANTES de generar el About.
- **Menu de descanso largo**: `_G.HarfordOpenPrepareSpellsMenu(silent)` reelige preparados del PJ
  actual (standalone, sobre `preparedSpells` vivo, Mod real de `HarfordDnDCalc`). Enganchado a
  `ApplyLongRest` (auto, silencioso si no prepara). Los known casters no re-preparan en descanso.
- **Descripciones completas del manual**: `HarfordDnDBookText.GetClassChapterFeature(className, title,
  level)` busca el rasgo como heading nv3/4 en TODO el CAPITULO de la clase (de "## <Clase>" hasta la
  siguiente clase conocida), no solo bajo "## <Clase>". Motivo: los rasgos mecanicos del manual viven
  bajo "## Rasgos de Clase" (nivel 2 separado), asi que la busqueda por seccion simple (`GetNestedSection`)
  no los alcanzaba y CASI TODAS las descripciones de clase caian a la version corta del libro. El match
  es normalizado (tolera tildes: `Paladin`/`Chaman`/`Picaro` vs `## Paladín`/`## Chamán`/`## Pícaro`) y
  prueba tambien el titulo sin el "(...)" final. `GetFeatureDescription` usa esta funcion para rasgos de
  clase/subclase; ~187/216 resuelven al texto completo, el resto son homebrew/Libro 2 sin heading.
- **Round-trip cargarficha**: `HarfordTRP3.WritePlayerRaceClass(raceName, className)` rellena
  `player.characteristics.RA`/`.CL` SOLO si estan vacias (no pisa identidad RP del jugador), para que
  `cargarficha` y los lectores TRP3 (color de clase) detecten raza/clase de una ficha creada (el About
  ya no lleva linea "Raza:"). La creacion lo llama tras escribir el About.
- **Progresion magica** (`HarfordCompendioCore`): `GetMaxSpellLevel(clase, nivel)` da el nivel de
  conjuro maximo lanzable segun tipo (completo/medio Paladin-CdM/tercio Picaro Sutileza), para filtrar el
  picker a conjuros castables. Magia racial: features de raza con `spellGrants`/`cantripSpellIds` (p.ej.
  `sme_arcano`/`esa_arcano`/`ren_elf_arcano` conceden `detectar_magia`) generan un frame "Magia <Raza>".
- **Debug**: `wipesheet [confirm]` (deja el PJ sin ficha), `abouttrp3` (regenera About), `preparar`
  (abre el menu de preparados).

### Frames del About: corte por clase/subclase (2026-08-24)

- **Cuatro frames por clase, no uno.** El generador escribia los rasgos de clase y subclase
  mezclados en un frame y un unico `Magia <Clase>`. El orden canonico que `TituloRango` ya esperaba
  —y que tienen los 45 perfiles reales— es por BLOQUES:
  `[Clase (10i+1), Especializacion <Sub> (10i+2), Magia <Clase> (10i+3), Magia <Sub> (10i+4)]`.
  `GetClassEntryTraits(entry, elegidas)` devuelve rasgos de clase y de subclase POR SEPARADO
  (`base, class, sub, subclass`) y `BuildMagicFrames` devuelve los frames AGRUPADOS POR POSICION de
  clase, para intercalarlos en su bloque. Con una sola clase daba igual; en multiclase la magia de
  la primera clase aterrizaba detras de la segunda.
- **`Magia <Sub>` = conjuros CONCEDIDOS por la subclase**, no "los de nivel" ni "los que no son
  trucos". Se comprobo contra los perfiles reales: `{PJ} Cody` (CdM Sangre) tiene "Nivel 1" en LOS
  DOS frames, asi que el corte por nivel es falso. Son los `grantedSpells` de sus rasgos
  ("Conjuros del llamado / de presencia / del camino"), filtrados por nivel alcanzado.
- **Clase que solo lanza por su subclase** (`Picaro Sutileza`, `Chaman Mejora`): el frame se titula
  con la SUBCLASE y es uno solo. Evidencia: en los perfiles reales hay `Magia Sutileza` x3 y ni un
  solo `Magia Picaro`. Se detecta porque `GetClassCasting(clase)` falla y solo acierta la clave
  compuesta `"<Clase> <Sub>"`. Ojo: el Chaman Mejora NO entra aqui (existe `CLASS_CASTING["Chaman"]`,
  que resuelve antes), y por eso su frame es `Magia Chaman` — que es lo que tienen los perfiles.
- **Atribucion de conjuros por clase.** `GetKnownSpells()` devuelve el pool ENTERO sin decir de que
  clase es cada conjuro, asi que con dos lanzadores cada frame se llevaba TODO (la Sacerdotisa
  listaba Mano de mago). Se filtra por la etiqueta `classes` del compendio, que usa exactamente las
  claves de `CLASS_CASTING`. Tres cautelas, todas necesarias:
  1. **Con UN solo lanzador no se filtra**: un conjuro sin etiquetar (fuente propia, custom de
     Epsilon) se perderia y no hay ambiguedad que resolver.
  2. **Nada se tira**: si ninguna clase lanzadora lo reclama, va a la primera.
  3. **Exclusividad**: un conjuro sale UNA vez. Hay conjuros etiquetados para dos clases lanzadoras
     a la vez (Mano de mago y Prestidigitacion son de "Mago" Y de "Picaro Sutileza") y salian
     duplicados. Se lo queda la PRIMERA clase de la progresion que lo reclame (`duenoDe`).
- **Una concesion manda sobre el etiquetado.** "Conjuros del llamado" existe justamente para dar
  conjuros que NO estan en la lista de tu clase, asi que el filtro por etiqueta los expulsaba en
  multiclase. Un pre-pase calcula `concedidoPor[spellId]` para TODAS las clases antes de repartir, y
  un conjuro concedido va siempre al frame de quien lo concede, sin pasar por el filtro. Auditados,
  hay 7 concesiones cruzadas reales: CdM concede `armadura_de_agathys` (etiquetada Mago) y
  `viento_guardian` (Chaman/Druida); Chaman concede `meteoros_menores_de_melf` (Brujo), `luz_del_dia`
  y `auxilio`; Sacerdote concede `oscuridad` (Brujo/Mago/Picaro Sutileza) y `fuerza_fantasmal`
  (Brujo/Mago). Sin esta precedencia, un Sacerdote Sombras + Brujo perdia Oscuridad de su frame.
- **`requiresOption` tambien en el About.** Habia dos caminos para calcular "rasgos desbloqueados" y
  solo `HarfordDnDProgression.GetUnlockedTraits` aplicaba la compuerta. Un Chaman Elemental de
  afinidad Aire se escribia los CUATRO Poderes totemicos y los OCHO Conjuros de vinculo, mientras su
  Libro solo le mostraba los de Aire. `GetClassEntryTraits` y el recolector de `grantedSpells` usan
  ahora el mismo set plano de opciones elegidas. Chaman es el mas afectado (13 rasgos condicionados);
  Brujo, Cazador, Guerrero, Monje y Sacerdote tienen uno cada uno.
- **La magia racial no se duplica.** Un conjuro concedido por la raza ya tiene su frame
  `Magia <Raza>` (rango 9000) y salia ademas en el de la clase, porque viene del mismo pool de
  conocidos: un Paladin elfo de sangre listaba Detectar magia dos veces. `BuildAbout` calcula
  `idsRaciales` y `BuildMagicFrames` los excluye de los frames de clase, SALVO que una clase tambien
  los conceda (ahi manda la concesion de clase).
- **`Eleccion: pendiente`.** `ChoiceText` salia sin escribir nada cuando no habia seleccion, asi que
  el volcado de opciones (Defensa, Duelo, Gran Arma...) se leia como si las tuviera todas. Si el
  rasgo declara `choice` (tabla con `slots`/`options`, el mismo campo que lee
  `HarfordDnDBook.GetChoiceOptions`) y no hay nada elegido, escribe `Eleccion: pendiente.`.

**LIMITACION conocida, no la "arregles" a ciegas**: `GetKnownSpells()` no guarda que clase aprendio
cada conjuro. Con dos lanzadores que comparten lista (Mago + Picaro Sutileza) es IMPOSIBLE saberlo,
y la colocacion unica por orden de progresion es una decision, no una deduccion: la segunda clase
puede quedarse sin frame de magia si todo lo suyo ya lo reclamo la primera. La alternativa evaluada
—dar prioridad a la clave compuesta de subclase— es igual de arbitraria. Los conjuros del libro del
Mago (`GetWizardBook`) no sufren esto: son pool propio.

**Lagunas de DATOS detectadas (no son del generador; viven en ficheros del pipeline web/Codex):**
- `Mago.lua` no declara ni un `grantedSpells`, asi que un Mago no genera `Magia <Sub>`. En los
  perfiles reales hay un `Magia Escarcha` CON la cabecera derivada (huella del generador web), que
  con nuestros datos no se puede reproducir. Los `Magia Fuego` y `Magia Represion` reales, en cambio,
  NO llevan cabecera: estan escritos a mano.
- El compendio no tiene la etiqueta `classes = "Chaman Mejora"`, aunque si es clave de
  `CLASS_CASTING`. Un Chaman Mejora multiclase con otro lanzador cae al reparto por defecto.
- Paladin: la subclase es `id = "represion"`, `name = "Represion"`, pero sus rasgos se titulan
  `Conjuros de camino (Retribucion)`.

**Verificacion**: se genero el About de 31 PJ de prueba en un arnes headless (`lua.exe` cargando los
modulos de DATOS reales —Book + las 12 clases + Races + Backgrounds + ClassColors— y stubbeando lo
que depende de WoW), comprobando que el rango de cada cabecera segun `TituloRango` es estrictamente
creciente. `TituloRango` es local: se rescata por `debug.getupvalue` sobre `API.SyncAboutAdditive`,
sin tocar produccion. Cubiertas las 12 clases, monoclase y multiclase, y las cabeceras en plural y
femenino de los perfiles ya escritos ("Sacerdotisa", "Especializacion Sombras", "Magia Sombras"),
que deben seguir clasificando. Esto NO sustituye probarlo en Epsilon.

## Iconos: de donde sale cada uno y quien manda (2026-08-24)

- **Cinco fuentes, no una.** `HarfordDnDData.GetFeatureIcon(feature)` resuelve en este orden:
  1. `AbilitySignIcon(feature)` — signos por NOMBRE, hardcodeados: los rasgos de idiomas van
     siempre a `inv_misc_note_05` y los de Incremento/Mejora de Caracteristica a un signo por
     color. Gana sobre todo lo demas.
  2. `HarfordIconCatalog.features[id]` — por id. Es la fuente principal.
  3. `HarfordIconCatalog.names[nombre normalizado]` — respaldo por nombre.
  Fuera de esa funcion hay dos mas: el `icon = "..."` EN LINEA de los ficheros de datos, y los
  conjuros, que van por `HarfordIconCatalog.spells[id]` (una LISTA de candidatos que resuelve
  `HarfordCompendioIconMap` con LibRPMedia, y que acepta `spell:<id>` numerico).
  `HarfordDnDData.PRESENTATION`/`TRP3_PRESENTATION` tienen una rama de icono en el Libro, pero hoy
  ninguna de sus 148 entradas declara `icon`: esa rama no dispara.

- **TRAMPA: la precedencia del `icon` en linea estaba INVERTIDA entre las dos vistas.** En el
  About (`FeatureIconName`) el catalogo gana y el inline es el ultimo recurso; en el Libro
  (`HarfordCharacterPanel`, ~5823) el inline era AUTORITATIVO y ganaba al catalogo. El motivo
  documentado alli era real: el respaldo POR NOMBRE colisiona entre homonimos (la Palabra de Poder
  "Escudo" tomaba el icono del conjuro "Escudo"). Como el catalogo ya resuelve por ID, que no
  colisiona, se retiraron los 23 inline cuyo id SI estaba en el catalogo y las dos vistas
  coinciden. **Los otros 86 se conservan a proposito**: maniobras del Guerrero, Palabras de Poder
  del Sacerdote y opciones de eleccion no tienen entrada por id, asi que su inline es lo unico que
  tienen. No quitarlos sin darles antes entrada en el catalogo.

- **La web MANDA sobre el addon.** `tools/codice/importar_iconos_web.py` va web -> addon y no toca
  la web. Reescribe `Catalog.features`, `Catalog.spells` (el icono de la web va el PRIMERO y se
  conservan los candidatos previos detras) y `Catalog.subclasses`; NO toca `Catalog.names`, que no
  tiene equivalente en la web. Lo que la web no cubre se conserva. Corre en seco por defecto:
  `--escribir` aplica, `--lista` vuelca el inventario a `_iconos_inventario.csv`.
  Resultado de la primera pasada: 533 iconos nuevos, 18 sustituidos, cobertura 1089 -> 1335 de
  1430. Los conjuros salieron con 0 cambios: ya estaban sincronizados.

- **Que un icono este en la web NO significa que exista en Epsilon.** Es la trampa central.
  `assets/compendium-icons/` tiene 2388 PNG y la web los sirve ella misma, asi que alli se ven
  todos; el cliente solo tiene los suyos bajo `Interface\Icons\`. Comprobado en juego con
  `/harford debug run iconoscheck`: 15 de 1430 no existen (~1%), y 14 vienen de la web. Ni siquiera
  va por familias: `eps_bg3_shockingrasp` existe y `eps_bg3_levitate` no. La lista para arreglar en
  la web esta en `tools/codice/_iconos_faltan_en_epsilon.md`.

- **`/harford debug run iconoscheck [todo|texto]`** recorre las cuatro tablas del catalogo mas el
  arte de origen (`HarfordCharacterCreation.GetAllOriginIcons`, que vive aparte) y pregunta al
  cliente con `GetFileIDFromPath`. Agrupa por TEXTURA, no por rasgo: un nombre roto suele estar en
  varios sitios. Trata `spell:<id>` con `GetSpellTexture` — sin ese caso daba tres falsos
  positivos.

- **Quedan 95 rasgos sin icono**, de los cuales 89 son de nivel 7+ (fuera del alcance 1-6 de la
  web). Los 6 alcanzables hoy son de subclase y la web tampoco los tiene: `bru_afl_maldiciones`,
  `bru_afl_maldiciones_6`, `mago_convertir_espacio`, `mago_crear_espacio`, `sac_convertir_ranura`,
  `sac_crear_ranura`.

## Tarjetas de seleccion en creacion y subida (2026-08-24)

- **Todo son tarjetas**: raza, trasfondo, clase, subraza, subclase y variante de trasfondo. Antes
  la subraza y la subclase eran un desplegable compartido (`S.subclassDrop`) y las clases una lista
  vertical de botones de 210x28. El desplegable ya no se usa para nada.

- **Dos rejillas con medidas distintas, a proposito.** Raza y trasfondo van en el scroll de la
  columna izquierda con `GRID_*` (4 por fila, 94x82). Todas resuelven su icono con
  `GridIconFor(isRace, id)`, que NORMALIZA la ruta: `GetRaceIcon`/`GetGenericIcon` devuelven el
  nombre pelado pero `HarfordIconCatalog.GetFeatureIcon` ya devuelve la ruta completa, y anteponer
  `Interface\Icons\` a ciegas la duplicaba y dejaba el icono roto. Las clases van en la columna estrecha
  (layout `list`, 996 de ancho) con `CLASS_*` (2 por fila, 110x72): son 12 y en 2 columnas salen 6
  filas, que a la altura de las de raza no cabrian en los 620 del frame; y 110 de ancho porque
  "Caballero de la Muerte" no cabe en 94. Se probo la etapa de clase en layout `grid` (1200) con 4
  columnas y las tarjetas se metian bajo el panel de detalle.

- **`RefreshOptionCards(opciones, seleccionadoId, iconoDe, alElegir)`** sirve a subraza, subclase y
  variante de trasfondo: mismo pool y misma posicion, porque nunca coinciden (una es de la etapa de
  raza y las otras de clase o trasfondo). `RefreshOptionCards(nil)` las oculta, y hay que llamarla
  en TODOS los sitios que ocultan el selector o quedan pintadas sobre caracteristicas y equipo.

- **Seleccion por defecto**: la primera subraza y la primera subclase vienen elegidas. **Excepcion
  documentada**: las razas cuyo libro admite la raza base (`BASE_RACE_IDS`, hoy solo Elfo de la
  Noche) arrancan en la BASE, que se muestra como primera tarjeta. Ahi "Elfo de la Noche sin
  subraza" es un personaje legitimo y preseleccionar Altonato reclasificaria a quien no se fije.
  Las variantes de trasfondo son OPCIONALES por el mismo motivo: el trasfondo a secas va primero y
  es el elegido.

- **Pool obligatorio.** Las tarjetas de raza, trasfondo y clase hacian `CreateFrame` en CADA
  refresco y solo ocultaban las viejas. Ahora se crean una vez, se guardan indexadas en
  `S.originButtons`/`S.classButtons` y en los refrescos se reposicionan y repintan. Lo que depende
  del estado se reaplica SIEMPRE: posicion, textura, texto, color, tinte del marco, `SetShown` de
  la seleccion, `SetEnabled`, el `OnClick` y el tooltip (que capturan el `choice` de esa pasada).

- **Tooltips**: `AttachTooltip(frame, obtenerTitulo, obtenerCuerpo, colorTitulo)`. Los textos se
  piden con CALLBACKS, no se guardan en el frame: con pool, un texto pegado al frame seguiria
  mostrando la eleccion anterior.

- **Marco**: `Interface\Common\WhiteIconFrame`, que es blanco puro y por tanto se tine con
  `SetVertexColor` (asi funcionan los bordes de calidad de objeto). Color de clase en las clases
  (100% si esta elegida, 55% si no), dorado/gris apagado en el resto. Existe en Epsilon: ya lo usa
  el PaperDoll del panel de personaje.

- **Variantes de trasfondo**: 7, importadas de la web con
  `tools/codice/importar_variantes_trasfondo.py` (aborta si el fichero ya las tiene). Se guardan en el campo `variants` de cada trasfondo de `HarfordDnDBackgrounds.lua` y solo traen
  `id`, `name`, `desc` e `icon`: son NARRATIVAS, no conceden rasgos ni efectos. El `art` .webp de
  la web se ignora, WoW no lo carga. `HarfordDnDProgression.SetBackgroundVariant` guarda la clave
  SOLO si hay variante elegida y la BORRA al deseleccionar, en vez de dejar `""`; no entra en el
  esquema por defecto ni viaja en sync. `SetBackground` la limpia al cambiar de trasfondo.

## Compendio: Convenciones De Datos Y Pipeline RuleSource (2026-08)

- **Nombres normalizados**: conjuros, rasgos (clase/subclase/raza/subraza), dotes y trasfondos usan
  mayuscula SOLO inicial ("Descarga de relampago", "Artesano gremial"). Se preservan nombres propios
  (Tasha, Mordenkainen, Leomund, Elune...), siglas (S.R.B.) y la mayuscula tras dos puntos
  ("Caracteristica: Refugio del fiel"). NO tocar clases, subclases ni razas ("Caballero de la Muerte",
  "Elfo de la Noche"): los libros las escriben asi y ademas `SPELL_PROGRESSION`/`classes = {...}`
  cruzan conjuros POR NOMBRE de clase; renombrarlas rompe el sistema de conjuros.
- **Sistema metrico**: todas las medidas van en metros/kg/g con la equivalencia REAL a 1 decimal
  (1 pie = 0,3048 m; 1 libra = 0,4536 kg; 1 milla = 1,609 km). 60 pies -> 18,3 m. Conviven "18 metros"
  (texto nativo del libro Warcraft) y "18,3 metros" (convertido del PHB): ambos correctos. La
  conversion vive en `RuleSource/metrico.py` y es idempotente.
- **Descripciones de conjuro**: 276/384 llevan el texto del manual, volcado con
  `RuleSource/volcar_conjuros.py`, que SOLO escribe si coinciden nombre (o su forma sin espacios,
  por titulos partidos por OCR) + nivel + escuela. Los manuales se extraen con
  `RuleSource/extraer_conjuros.py` POR COLUMNAS (aplanar la pagina mezcla columnas y parte palabras:
  "su rge", texto de otro conjuro). El extractor repara guiones de silaba ("des- bloquea") y digitos
  OCR ("ld8" -> "1d8", "2dl0" -> "2d10"). Tasha trae los titulos DENTRO de la imagen de fondo: se
  recuperan del OCR (`RuleSource/ocr_libro.ps1`, motor Windows es-ES) y se emparejan por escuela+nivel.
  La Costa de la Espada es un escaneo sin capa de texto: solo OCR.
- **`Catalog.spells` de HarfordIconCatalog es una LISTA de candidatos por conjuro**: el addon usa el
  primero que resuelve y el ultimo suele ser un `Interface\Icons\...` base garantizado. Al leerla
  desde fuera hay que recorrer la lista, no quedarse con el primero. Los iconos `wh_*` (Warhammer) ya
  no existen en el cliente: esos conjuros llevan un segundo candidato anadido (eps_bg3/spell_holy...).
  Erratas conocidas del catalogo: `eps_bg3_fiends` -> el PNG real es `eps_bg3_friends`;
  `fotunesfavor` -> `fortunesfavor`; `wc3_blink` -> `w3reforgedblink`.
- **Web publica (harfordweb)**: es la fuente canonica de contenido de la tanda de creacion (clases,
  subclases, razas, trasfondos y conjuros). El pipeline historico de `tools/codice/` describe una
  publicacion addon -> web, pero ya no debe tratarse como direccion autoritativa para esos dominios.
  La importacion web -> addon se hara por una ruta revisable, con cotejo previo contra `RuleSource/Rulebooks/`;
  no editar `js/compendium-*.js` desde este repositorio ni ejecutar publicaciones que los pisen sin
  coordinacion. Las decisiones de terminologia del usuario viven en `tools/codice/prof_terminologia.json`
  (herramientas "Utiles de ...", instrumentos/juegos/vehiculos diferenciados) e
  `idiomas_terminologia.json`; el addon aun usa los nombres antiguos y su migracion esta pendiente de
  decision.
- **Fuentes curadas en `RuleSource/Export/*.json`**: cuando un libro trae los TITULOS dentro de la
  imagen (Tasha) o el OCR los rompe, el cuerpo se cura una vez a mano y se guarda como JSON durable
  que el pipeline consume: `dotes_tasha.json` (12 dotes del Caldero, clave = nombre normalizado),
  `rasgos_tasha.json` (rasgos de clase, p.ej. Formulas de trucos del Mago), `variantes_phb.json`
  (5 variantes de trasfondo: Gladiador, Espia, Pirata, Caballero, Comerciante Gremial) y
  `trasfondos_phb.json`(+`_rasgos`). Erratas OCR de titulos: el PHB lee "OBSERVADOR" como
  "UBSERVADOR" (alias en el extractor de dotes). Los rasgos cortos restantes ("Ataque extra",
  "Incremento de caracteristica", "Guardas demoniacas" = Defensa sin Armadura renombrada) son reglas
  de una linea tambien en el libro: no forzar textos mas largos.

## HarfordItemForge: Creacion En Masa De Objetos Custom (2026-08-21)

Addon **independiente**, en `AddonsIndependientes/HarfordItemForge/`. No es parte de Harford
ni de HarfordAdmin y no se despliega con ellos.

**Limite del trabajo: crear y categorizar, nada mas.** `HarfordProfesionesItems.lua`,
`HarfordProfesiones.lua` y `Harford/Compendium/`+`Harford/DnD/Data/` los mantiene otro
agente. El utillaje de ItemForge los LEE como fuente y no escribe en ellos nunca: la etapa de
vuelta deja las lineas preparadas en `tools/codice/_itemforge_forjados.txt` para que las
pegue quien corresponda. No anadir una opcion que parchee el registro: con dos agentes sobre
el mismo archivo, el que no lo posee no escribe.

- **El servidor no devuelve el id del objeto creado.** `.forge item create` lo deja en la
  bolsa y ya. El id se DEDUCE fotografiando el inventario antes y despues; de ahi sale el
  item link con el que se encadenan los `.forge item set ...`. Es el flujo que PhaseToolkit
  tiene probado en produccion, incluido enviar el enlace rodeado de espacios.
- **Se forja de uno en uno, y no es negociable**: dos creaciones solapadas hacen imposible
  saber que id es de cual. El limite real de una tanda son los huecos de bolsa, asi que el
  addon se para solo al llenarse y reanuda con `/hforge crear`.
- Si el objeto se crea pero fallan sus campos, la clave **queda apuntada igual**: el objeto
  ya existe en el servidor y reintentar crearia un duplicado.
- El registro vive en `HarfordItemForgeDB` (SavedVariables), nunca en `Data.lua`. **Guarda
  la ficha completa** (`id`, `nombre`, `prof`, `papel`, `cuando`), no un id suelto: ESA es la
  lista, y `/hforge exportar` la saca agrupada por profesion y papel en el formato de
  `HarfordProfessionsItems.REGISTRY`. Se admite el formato viejo (numero suelto) al leer.
  Tambien persiste `estado.ultimo` y `estado.tanda` para saber por donde se iba.
- **Los cinco cerrojos del borrado.** En orden, y ninguno es prescindible: (1) el id tiene
  que constar en el registro; (2) tiene que estar en el rango custom `>= 14000000` -- los
  objetos de Blizzard andan por debajo de 250.000, asi que aunque un id equivocado se colara
  en el registro no se borraria nada del jugador; (3) se comprueba el hueco EXACTO antes de
  tirar; (4) no se toca nada con el cursor ocupado; (5) `limpiar` ensena que borraria y solo
  actua con `limpiar si`. Ese mismo rango custom se exige ANTES de aceptar un id como
  forjado: si en la ventana de creacion entra un botin o un correo, se para en seco en vez
  de reescribirlo y borrarlo. **Solo bolsas 0..4**: el banco (5..11) no se toca nunca.
- **El borrado de bolsa es del cliente y es destructivo**: Epsilon no tiene comando de
  servidor para quitar objetos, asi que `BorrarDeBolsa` usa `PickupContainerItem` +
  `DeleteCursorItem`. Solo borra ids que constan en el registro (`EsNuestro`), comprueba el
  hueco antes y confirma despues. No relajar esos cerrojos. Va apagado por defecto
  (`/hforge autolimpiar`); encendido es lo unico que permite pasar de la capacidad de bolsa.
- **Un objeto forjado nace cerrado**: solo su creador puede `.additem`. Como son objetos de
  profesion, el addon envia `forge item set property additem anyone <link> on` para todos.
  Se cierra por objeto con `"additem": false` en las anulaciones.
- **EpsilonLib lanza `error()` a partir de 250 caracteres por comando**, no falla en
  silencio: un comando largo aborta la tanda entera. `Comandos()` recorta y avisa. El peor
  caso actual son 150, pero las descripciones aun estan vacias.
- **EpsilonLib NO tiene tiempo limite**: `sendAddonCommandChain` avanza solo cuando el
  servidor responde a cada comando y, si una respuesta se pierde, espera para siempre y en
  silencio. Con miles de idas y vueltas pasa antes o despues, asi que `Rellenar()` monta su
  propio vigilante. No asumir que un callback de EpsilonLib siempre llega.
- **Registrar en `AddonCommands` SIN el segundo argumento.** Con `showMessages = false`
  EpsilonLib silencia TODO, incluidos los mensajes de fallo del servidor, que son lo unico
  que permite diagnosticar. Sin argumento imprime solo los fallos.
- **El id se deduce del inventario, y solo vale si aparecio UN objeto.** Si aparecen dos
  (correo, botin, intercambio en la ventana justa) no hay forma de saber cual es el forjado
  y elegir a ciegas es destructivo: los `set` reescriben nombre y datos del que no toca.
  `IdNuevo` devuelve tambien cuantos apareceron y la maquina se para.
- **El borrado NO se verifica en el momento.** El contenedor no se actualiza al instante:
  la noticia llega por `BAG_UPDATE`. Comprobar el hueco justo despues de `DeleteCursorItem`
  daria siempre "no se pudo" aunque el borrado fuera bien. Por lo mismo, con `autolimpiar`
  el hueco liberado tarda en constar y `Siguiente` concede UNA segunda oportunidad de 1,5s
  antes de dar la tanda por terminada, o pararia justo despues de haber hecho sitio.
- **Nada se toca con el cursor ocupado**: `PickupContainerItem` con el cursor lleno intenta
  COLOCAR lo que lleva, y el objeto del usuario acabaria movido. Se comprueba `GetCursorInfo`.
- **Lo que va al chat esta acotado**: `exportar` corta en 60 lineas (el bufer no aguanta
  miles y no se pueden copiar) y remite a las SavedVariables; `revisar` corta en 12
  problemas. El vertido completo se saca con `actualizar_itemforge.py`.
- **Las SavedVariables solo se escriben al salir o al recargar.** Un cuelgue a mitad pierde
  el registro mientras los objetos ya existen en el servidor, y NO hay comando de busqueda
  por nombre para recuperarlos (`.forge item info` pide el id que has perdido). Lotes por
  profesion y `/reload` entre ellos.

**`Data.lua` se genera, no se escribe a mano** (`tools/codice/gen_itemforge_data.py`).
Clasifica por PROFESION de la receta, luego por PAPEL (resultado o materia prima) y solo al
final por nombre. Cotejar contra `kb.json` es parte del generador: avisa de cualquier objeto
publicado en la web que no tenga clave en el registro.

**El icono no es el modelo.** El `icono` es lo que se ve en la bolsa; el `display` es el
modelo 3D sobre el personaje, y sin el un arma forjada no se parece a un arma.
`.forge item set display $item-link $item-link2` le copia modelo y textura a OTRO objeto, y
`cotejo/objetos_wowhead.json` esta indexado justamente por el id real de WoW: de ahi salen
2415 displays sin necesidad de conocer ningun displayid. **Se manda un ENLACE, nunca el
numero pelado**: la descripcion del catalogo dice "If the $item-link2 is instead a number" y
se corta ahi, en EpsilonLib mismo, sin aclarar si ese numero seria un id de objeto o un
displayid. Con el enlace no hay dos lecturas posibles. El comando lleva entonces dos enlaces
y sigue holgado: el peor caso son 169 caracteres de 249. Lo que sigue SIN enviarse es `sheath` (100 armas): el enum
0..7 no esta verificado y equivocarlo solo afecta a donde se envaina, asi que se deja hasta
poder comprobarlo en juego.

**Yunque** (`tools/codice/yunque.html`): pagina suelta con VARIOS yunques en pestanas.
La montan tres generadores y hay que lanzarlos en este orden: `gen_yunque.py` (nombres de
icono), `gen_yunque_datos.py` (registro, profesiones, ids de receta y los objetos pendientes,
para poder EDITARLOS y no solo crear nuevos) y `gen_yunque_iconos.py` (la hoja de sprites).

- **Objetos**: crea uno nuevo o carga uno de los 1.944 pendientes para completarlo -- ahi
  esta el trabajo que queda, 1.198 sin descripcion. Avisa si la clave ya existe.
- **Objetos, armas y armaduras del sistema**: la mecanica de un objeto Harford vive en su
  DESCRIPCION. `HarfordDnDItems` la lee linea a linea y solo aplica las que casan con una
  etiqueta que conoce; una etiqueta inventada da un objeto bonito que no hace nada, y desde
  el juego no hay forma de notarlo. Por eso el Yunque saca etiquetas, caracteristicas,
  habilidades, tipos de dano y las 52 armas **del propio addon** via `gen_yunque_datos.py`.
  Cada modificador es una LINEA COMPLETA, porque los patrones estan anclados asi. Ojo con
  dos formas distintas: `CA +1` es un bonus y `Armadura 14` es un valor ABSOLUTO. El color
  es seguro: `CleanTooltipLine` quita `|c…|r` y `$RRGGBB$` ANTES de interpretar la regla, asi
  que pintar una linea no le quita la mecanica. La descripcion puede tener varias lineas
  porque viaja por mensaje de addon, no por chat; el limite de longitud lo marca el texto
  ENTERO, modificadores incluidos.
- **Recetas**: saca la linea de `HarfordProfessionsData.RECIPES`. Materiales y resultado se
  referencian por CLAVE y se **autocompletan y validan contra el registro real**: una clave
  inventada deja la receta como pendiente para siempre sin decir nada, que es el mismo
  problema que el icono inexistente.
- **NPC**: saca la cadena de `.phase forge npc ...` (36 comandos). **Los enumerados no salen
  de la memoria**: el catalogo del cliente los trae TRUNCADOS -- corta en la primera coma,
  la misma corrupcion que la descripcion de `forge item` --, asi que los 11 tipos de criatura
  y los 5 rangos (0 Normal, 1 Elite, 2 Raro elite, 3 Jefe, 4 Raro) se sacaron del editor de
  NPC de PhaseToolkit, que es quien los manda de verdad. Lo del envainado sigue truncado y
  por eso se ofrece por numero, sin etiquetas inventadas. Solo se emite lo que se toca.
  Incluye el **atuendo**: `outfit equip` toma el **ID DEL OBJETO**, no un displayid (un
  numero NEGATIVO si de verdad es un displayid), asi que se puede vestir buscando por nombre
  contra los 2.525 objetos de `objetos_wowhead.json`. Ese detalle es lo que lo desbloqueo:
  parecia que hacia falta un catalogo de displayids de equipo y no. Las 37 razas SI vienen
  enteras en el catalogo del cliente; la lista de huecos de `equip` esta truncada, asi que se
  ofrece el segundo argumento sin etiquetarlo, y los nombres de hueco para vaciar salen de
  los subcomandos reales de `outfit unequip`. Se vacia antes de vestir.
- **Secuencias**: saca el bloque `Register` de `HarfordActionSequencePresets`. **El retardo
  de cada paso es ABSOLUTO desde que arranca**, no un hueco respecto al anterior: el motor
  programa un temporizador por paso en el mismo instante y los que comparten retardo salen
  juntos. Por eso el orden del codigo NO es el orden de los hechos -- en `FistAttack` los
  retardos van `0, 0.95, 0.25, 0.25` y suceden 0, 0.25, 0.25, 0.95, que leido asi tiene
  sentido: golpe, impacto y sonido, y vuelta a postura. 65 de los 68 presets se leen
  desordenados por eso y NO estan mal. El yunque ordena la previa y la salida por momento,
  para que el archivo se lea como ocurre. Los tipos son los cinco que registra el motor
  (`anim`, `cast`, `npccast`, `command`, `sound`) y se emiten con los alias de SpellCreator.
- **Rutas**: guion, no tirada, por el mismo motivo que el gossip: `waypoints add` pone el
  nodo DONDE ESTAS TU y los `modify` van al nodo seleccionado, asi que la ruta hay que
  andarla. Se asume que el nodo recien anadido queda seleccionado, que es como se encadena
  al crear una ruta del tiron; para retocar una ya hecha hay que seleccionar a mano y el
  guion lo dice. Cubre espera, probabilidad, decir/gritar/emotear, lanzar, emote, sonido,
  activar un GUID, quitar aura y movetype, mas el modo aleatorio (`waypoints random`). El
  enumerado de `movetype` esta truncado en el catalogo ("walk"), asi que va como texto libre
  y se avisa. Solo hay `unaura`: no existe comando para PONER un aura en un nodo.
- **Gossip**: NO saca una tirada de comandos, saca un **guion**. `text add` y `option add`
  actuan sobre **la pagina abierta en la ventana de gossip**, asi que un arbol de dialogo no
  se puede montar de una tacada: hay que navegar por el juego. El guion intercala los pasos
  ("desde la pagina 0, pulsa X") donde tocan, crea TODAS las paginas primero (una opcion no
  puede enlazar a lo que no existe) y avisa de las paginas a las que no llega ninguna
  opcion, que no se podrian escribir. Al borrar una pagina renumera enlaces igual que hace
  `page remove` en el servidor. La pagina 0 es la que sale al hablar y no se crea.
- **Misiones**: saca la entrada de `HarfordQuestCatalog`. **No inventar campos**: los que
  existen son `title`, `description`, `category`, `difficulty`, `icon`, `source`,
  `objectives[{text, required}]` y `rewards{rep|reps, xp, money{gold,silver,copper}, items}`.
  Tres cosas que costaron cotejarlas y no deben perderse:
  - **`source` vale SIEMPRE `"world"`** en todo el addon. No hay otros valores.
  - **`category` NO es texto libre**: `HarfordQuestLog` lo resuelve con
    `TC.Data.GetTypeByKey`, asi que son las 12 claves de tipo de contrato (`mercenary`,
    `hunt`, `investigation`...).
  - **El icono va con RUTA COMPLETA** (`Interface\Icons\nombre`), al reves que en objetos,
    donde es el nombre pelado. Y en `rewards.items` conviene emitir el `id`: con el,
    `FormatRewardItemForText` resuelve nombre, enlace e icono solo.

**Los yunques comparten lo que estas creando.** Una clave vale si esta en el registro del
proyecto O si la acabas de crear en el yunque de objetos. Sin eso, el orden natural de
trabajo -- crear el objeto y despues su receta o la mision que lo da -- marcaba en rojo la
clave que acababas de inventar. La marca distingue las dos procedencias ("lo estas creando
ahora"), porque una todavia hay que pegarla en el registro y la otra no.

Dos ideas ordenan los formularios:

1. **Los campos se separan por naturaleza.** Los que se convierten en un `.forge item set …`
   van juntos y marcados en verdin; los que solo ordenan la lista de Harford (profesion,
   papel, clave) van aparte en cobre. No anadir un campo que no caiga claramente en uno de
   los dos lados.
2. **El icono se valida contra el catalogo real** (19.347 nombres de `epsilon_icons.json`,
   que trae fichas `{fdid,name,path}`, no cadenas). Un icono inexistente NO borra la textura
   anterior: el objeto hereda la del hueco que ocupaba antes y no se nota hasta verlo en
   juego. La pagina avisa antes. Ademas normaliza lo que se pegue -- ruta, extension,
   mayusculas -- a la forma que acepta el comando.
3. **El selector visual va sobre una HOJA DE SPRITES** en WebP a 24 px, no imagenes
   sueltas: la pagina no puede pedirle nada a ningun servidor, y sueltas serian 164 MB.
   - **La data-URI se convierte a un `blob:` y se inyecta como UNA regla CSS.** Es lo unico
     que hace la pagina usable, y costo dos intentos fallidos: metida en el `style` de cada
     boton se copiaban megas de texto por elemento; metida en una variable CSS tampoco vale,
     porque `var()` se sustituye TEXTUALMENTE y cada elemento que la usa vuelve a arrastrar
     la cadena entera. Medido: 60 desplazamientos pasaban de **11.312 ms a 39 ms**. Nunca
     poner una data-URI grande en una variable CSS ni en un style por elemento.
   - **La rejilla es VIRTUAL**: en el DOM viven solo los ~90 botones visibles y se reciclan.
     Antes se anadian de 400 en 400 al bajar, pero el evento de scroll se dispara decenas de
     veces por gesto y la condicion seguia siendo cierta: miles de elementos de golpe.
   - Con eso, el catalogo COMPLETO (18.830) sale gratis en ejecucion y solo cuesta peso de
     archivo. `--cupo N` lo recorta si alguna vez se prefiere que abra antes. Convertir
     4,5 MB de base64 a blob son 28 ms, asi que el tamano de la hoja no penaliza en runtime.
   - **El tamano del icono es `--lado` y la pagina se ajusta sola**: celdas, huecos y los
     tres previsualizadores salen de `HOJA.lado`, no van fijos en el CSS.
   - **Los CUSTOM entran todos, con el nombre que tengan.** Filtrarlos por prefijo
     `inv_/trade_/item_` dejaba fuera 3.793 -- `inv-sword_53` con GUION, `custom_*`,
     `smite_*`, `ivn_*` (un `inv` mal escrito), `racial_*`. Son arte propio del servidor y no
     hay donde buscarlos si faltan, asi que van sin filtro y con prioridad en el cupo: si
     hay que recortar, se recorta de lo de Blizzard. El prefijo se sigue aplicando SOLO a
     los `base`, donde `spell_`/`ability_` es arte de hechizo y estorba. Por lo mismo,
     `aIcono()` conserva el guion.
   - **Nombres y miniaturas se separan**: los 36.605 nombres van SIEMPRE enteros (escribir
     no cuesta peso), y el cupo decide solo cuales llevan miniatura. Asi nunca hay un icono
     inalcanzable.
   - **El lado y el cupo se compran el uno al otro**, porque la hoja crece con el CUADRADO.
     El ajuste actual, **36 px / 22.200**, es el mayor tamano al que caben TODOS los propios
     (20.780, BG3 incluido): 14,4 MB de pagina. A 40 px esos mismos se pasarian de 16 MB, y
     a 50 px solo entrarian ~12.600, dejando fuera BG3 y medio `eps_`. Lo que se queda sin
     miniatura son 14.405 de arte base de Blizzard, que se consulta en cualquier base de
     datos de WoW.
   - Queda a 1,6 MB del limite: **si la carpeta de iconos crece, hay que bajar el lado**.
   - **La hoja se monta CUADRADA**: WebP no admite mas de 16.383 px por lado, y una tira
     estrecha y muy alta se pasa en cuanto crece el icono -- a 50 px con ancho fijo salian
     31.400 px de alto y el codificador fallaba. `columnas = ceil(sqrt(n))`.
   - El resto del cupo se reparte tomando **uno de cada N por todo el catalogo**. Por orden
     alfabetico solo entraba el principio: `inv_axe`, `inv_belt`, y no se llegaba a
     `inv_sword`.
   - **La fuente es la CARPETA `EpsilonIcons/png` (36.605 PNG), no un CSV ni un filtro de
     prefijos.** Si el PNG esta en disco, el icono existe. Filtrar por `icons_master.csv` y
     por `inv_/trade_/item_` dejaba fuera **9.582**, entre ellos los 6.204 del espacio `eps_`
     -- el propio de Epsilon -- con **los 461 de BG3**, y los paquetes `hots_`, `hd_`, `d3_`,
     `dos2_`. Costo tres intentos verlo: no volver a filtrar iconos por prefijo.
   - Los nombres van SIEMPRE en minusculas: `Data.lua` los guarda con mayusculas
     (`INV_Misc_Fish_01`) y la pagina normaliza, asi que sin eso el sprite fallaba justo en
     los que ya se usan.
   - **El recorte es por caja de contenido**: `padding` para centrar mas
     `background-origin/clip: content-box`, de modo que el fondo solo se pinta en una caja
     que mide exactamente una celda. Sin eso se colaba el icono contiguo.
   - **El buscador y el valor son campos DISTINTOS.** Cuando eran el mismo, elegir un icono
     dejaba la rejilla con un unico resultado. Y el filtro traduce del castellano
     (`espada` -> `sword`): los nombres son ingleses y sin eso parece que no busca.
   - La rejilla los pinta de 400 en 400 al bajar; 18.882 botones de golpe atascan la pagina.

Estan **las 37 opciones** de `.forge item set` que admite el cliente, no solo las que usa
Core.lua: bonding, sheath, material, la familia `property` (adder, additem anyone/character/
member/officer, copy, creator, info, lookup) y las tres listas blancas. Las propiedades son
de TRES estados -- sin tocar / si / no -- y solo emiten comando si se tocan, para no anadir
nueve comandos por objeto sin motivo.

**Merchant**: los catalogos de vendedor NO son comandos de servidor. `Epsilon_Merchant`
guarda cada uno en el vault de la fase con la clave `VENDOR_DATA_<merchantID>`, troceado por
`SetPhaseData`, y cada articulo es un array posicional `{ itemID, precio, tamanoPila,
moneda }` (moneda -1 = cobre). Para cargar un catalogo se rellena
`EPSILON_VENDOR_DATA[merchantID]` y se llama a `Epsilon_Merchant_SaveVendor()`. Harford ya
engancha `BuyEpsilon_MerchantItem`/`SellEpsilon_MerchantItem` desde `HarfordDnDEconomy`.

**Regenerar cuando cambian las fuentes**: `tools/codice/actualizar_itemforge.py [--aplicar]`
encadena las cinco etapas en el orden correcto: (1) VUELTA, lee los ids forjados de las
SavedVariables del juego y prepara las lineas para el registro; (2) WOWHEAD, vuelca calidad,
pila y efectos de `cotejo/objetos_wowhead.json`, que ya esta en disco (84% de cobertura);
(3) GENERAR; (4) DUPLICADOS; (5) COMPROBAR con el Lua 5.1 real. Es lo que hay que lanzar
cuando el otro chat toca el registro o las recetas -- en una sola sesion paso de 2099 a 2866
claves. Como descripcion se toma SOLO el efecto de uso de Wowhead: el resto del tooltip
(nivel de objeto, precio, requisitos) lo calcula el servidor y meterlo daria texto falso.

**Comprobar que no existan ya**: `tools/codice/itemforge_ya_creados.py`. Un duplicado en
Epsilon no se deshace y el servidor no busca por nombre, pero cada objeto custom que paso por
el chat dejo su enlace en las SavedVariables de Elephant. Rastreando el WTF salen 298 objetos
custom y 13 de los pendientes que YA existen. Solo ve lo que paso por el chat: no es prueba
concluyente, asi que la primera tanda corta y `/hforge revisar`.

**Reimportacion desde la web**: lo que el generador no puede deducir vive en
`tools/codice/itemforge_anulaciones.json`, que se aplica ENCIMA de lo deducido y es lo unico
que sobrevive a una regeneracion. Se rellena con `tools/codice/importar_itemforge.py`, que
acepta claves o nombres visibles y NO pisa lo ya afinado salvo con `--pisar`. No hardcodear
descripciones dentro de `Data.lua`: se pierden en la siguiente regeneracion.

**Aviso pendiente**: el registro trae 55 nombres repetidos con sufijo `_2`
(`botas_zarzal` / `botas_zarzal_2`). Parecen duplicados del pipeline, no variantes. Forjarlos
crearia 55 objetos redundantes; conviene resolverlos antes de una tanda larga.

## Convencion de ids de rasgo de clase (2026-08-24)

`<abrevClase>_<abrevSub>_<cosa>`. Las abreviaturas se **DECLARAN**, no se deducen: el Paladin usa
`ret` para *represion* (retribution) y el Caballero de la Muerte usaba el nombre entero. Deducirlas
da resultados equivocados.

Aplicado a los 63 rasgos que se nombraban SOLO por su subclase (`afliccion_drenar_alma` ->
`bru_afl_drenar_alma`). Sin prefijo de clase, dos clases con la misma subclase -- **Druida y Chaman
comparten "restauracion"** -- solo se distinguian por suerte.

**Comprobado antes de aplicar, y es lo que lo hizo seguro:**
- **0 de los 63 aparecen en SavedVariables reales.** Solo hay 4 ids de rasgo guardados en toda la
  cuenta (`bg_des_herr`, `guerrero_estilo_combate`, `hum_versatilidad`, `pic_pericia`), todos en
  `choices`. No hizo falta migracion de datos de jugador.
- **0 estan cableados en codigo.**
- **6 estaban en el catalogo de iconos**, renombrados en el mismo commit.
- Los ids construidos en RUNTIME (`monje_cer_breb_`, `caz_sup_trampa_`, `bru_afl_mald_`,
  `cha_mej_atq_`, `sac_pp_`) ya seguian la convencion y no se tocan. `guerrero_man_` no, pero queda
  fuera del alcance.
- 0 colisiones con ids existentes y 0 entre los nuevos.

**La WEB conserva los ids viejos y NO se toca desde aqui.** `importar_iconos_web.py` lleva una tabla
`ALIAS_WEB` que traduce al leer, asi que el cruce de iconos sigue funcionando. Sin ella, si la web
cambiase el icono de uno de esos 6, el addon dejaria de enterarse EN SILENCIO. Cuando la web adopte
los ids nuevos la tabla se vuelve inerte sola y se puede borrar.

**Fuera del alcance:** 33 ids con el nombre de clase entero (`guerrero_segundo_aliento`). Uno de
ellos, `guerrero_estilo_combate`, SI esta en datos de jugador, asi que ese pase necesitaria
migracion de verdad.

Suite `ids_convencion`: falla si un rasgo vuelve a nombrarse solo por su subclase o si sobrevive un
id viejo en cualquier parte del addon.

## Pruebas de logica: `python tools/pruebas.py` (2026-08-24)

12 suites, 133 casos. Cada una EXTRAE funciones del codigo real con `string.find` sobre el fichero
y las ejecuta con stubs de WoW: no hay copias del codigo que puedan quedarse viejas.

```
python tools/pruebas.py            # todas
python tools/pruebas.py turnos     # solo las que casen con el nombre
```

**Que cubren:** protocolo de red de turnos (escapado, troceado, ida y vuelta), iniciativa y su
autoridad, economia de turno, caducidad de la lista, tipos de entrada, mitigacion de dano magico,
payload `DNDDMG`, cabecera de dano por tipo, borrador de creacion de personaje y calculo de
habilidades.

**Que NO cubren, y es importante saberlo:** nada visual, nada de red real, nada de dos clientes.
Cuatro de los cinco bugs de la sesion de modularizacion solo se habrian visto ejecutando en WoW.

**Regresiones que fijan** (bugs que ya ocurrieron una vez):
- El borrador guarda la caracteristica BASE, sin el bono racial: sumarlo ahi lo contaba dos veces.
- Nadie puede fijar la iniciativa de otro jugador mandando un `INITRES` falso.
- Una resistencia calificada "de ataques no magicos" no frena un golpe magico, pero una sin
  calificar SI lo frena -- es la regla correcta y es facil pasarse de listo.
- El marcador de asalto no cuenta como "hay combate".

Al anadir una suite, ponerle cabecera explicando QUE prueba y por que: el runner las lista por
nombre y la cabecera es lo unico que dice si sigue teniendo sentido.

## Modularizacion: patron `Init(deps)` y sus trampas (2026-08-24)

Ocho modulos salieron de los cuatro ficheros grandes. Todos siguen el mismo patron, y hay dos
trampas que costaron cinco bugs reales en una sola sesion. **Ninguna la ve el compilador**: en Lua
una funcion que no existe es una variable global valida hasta que la llamas.

**El patron.** El modulo declara sus dependencias como locales sin valor y las recibe con
`Init(deps)`; el fichero de origen guarda UN alias (`local Codec = HarfordTurnsCodec`) en vez de los
doce locales que ocupaban las funciones. Los cuerpos se mueven **verbatim**: no se reescriben.

**Trampa 1: el `Init` va al FINAL del fichero.** Muchas dependencias son de asignacion adelantada
(`local X` arriba, `X = function` mil lineas abajo). Si el `Init` se coloca antes de esa asignacion,
inyecta `nil` y el modulo se queda con una funcion muerta que compila igual. Paso dos veces
(`NormalizeIconPath`, `SafeNumber`). Si no se puede mover el `Init`, inyectar un cierre:
`NormalizeIconPath = function(i) return NormalizeIconPath(i) end`, que resuelve al llamarse.

**Trampa 2: las referencias sin parentesis.** Reescribir `Nombre(` no encuentra las funciones
pasadas POR REFERENCIA (`MakeButton(..., StartCombat)`, `S.refreshers.sheet = RefreshSheet`). Los
botones Iniciar/Terminar del tracker se rompieron asi.

**Verificacion obligatoria tras cada extraccion**, en este orden:
1. Referencias sueltas en el fichero de origen: buscar cada nombre movido SIN el prefijo del alias,
   por palabra completa (no solo seguido de `(`).
2. Llamadas sin resolver en el modulo nuevo: comparar lo que llama contra lo que declara, contra los
   globales de WoW y contra las palabras clave de Lua. Aparecen dependencias que el analisis inicial
   no vio, sobre todo si se movieron ayudantes en un segundo paso.
3. Referencias desde OTROS addons (`HarfordAdmin`, `HarfordDebug`), no solo el fichero de origen.
4. Que la tabla global en la que escribe el modulo exista ya en su posicion del `.toc`.
5. Que cada dependencia del `Init` este asignada en esa linea.

**No basta con que compile.** Los cinco bugs de la sesion compilaban.

## Limite de 200 locales: como medirlo y como bajarlo (2026-08-24)

Lua 5.1 permite 200 locales por chunk. Al pasarlos el fichero no compila y el addon NO CARGA. No es
estilo, es el techo real. `HarfordUnitFrames` llego a 180 (AGENTS.md lo documentaba en ~169) sin que
nadie lo vigilara.

Estado tras la sesion: UnitFrames 163, HarfordDnD 138, CharacterPanel 112, Turns 118.

**Tecnica barata: bloques `do...end`.** Encierra locales de un solo uso sin mover codigo. El criterio
correcto es que **NINGUN local de file-scope dentro del rango se use fuera de el** -- no solo el
candidato. Comprobar solo el candidato dejo encerrado `RefreshSheetTitle`, cuyas dos llamadas van
guardadas con `if X then`: no habria dado error, el titulo de la ficha simplemente habria dejado de
refrescarse para siempre. Con el criterio correcto se rechazan 3 de cada 4 candidatos (52 liberados
frente a 151 descartados); ese ratio es el resultado, no un fracaso.

**La medida que decide que extraer no es el tamano, es el ACOPLAMIENTO.** `CreateSheetPage` tenia 946
lineas y UNA llamada externa; se extrajo sin drama. Contar tambien cuales de sus dependencias se usan
solo dentro del grupo: esas se mueven con el, no se inyectan (en la pestana Ficha eran 13 ayudantes,
237 lineas extra).

## Target y Focus NO se unifican (2026-08-24)

Parece duplicacion -- `EnsureToTBarsOverlay` / `EnsureFocusTotBarsOverlay`, `RestoreTargetAuras` /
`RestoreFocusAuras`, y dos pares mas -- pero **ya han divergido**: 61 %, 74 % y 88 % de similitud, y
las versiones de focus son sistematicamente MAS CORTAS porque focus ya hace menos que target.

Unificar exigiria condicionales desde el primer dia y uno mas por cada divergencia futura, hasta que
la funcion compartida fuese peor que dos copias claras. Ademas las caches de anclas de ambos deben
permanecer separadas (deriva infinita de buffs, ya documentado). **Evaluado y descartado; no
reintentarlo.**

## Turno compartido "PJs": iniciativa por bandos (2026-08-24)

Entrada de tipo `players` en el tracker: un unico hueco para TODOS los personajes jugadores, que
actuan entre ellos en el orden que quieran. Es la variante de iniciativa por bandos, no una
invencion: en RP, tirar iniciativa por cada jugador y sostener el orden es mas friccion que juego.

- `EntryBelongsToMe(entry)` devuelve **true para cualquiera** si `entry.kind == "players"`. Eso hace
  que cada cliente reciba su aviso de turno y **renueve su propia economia de accion**.
- `IsSystemEntry(entry)` agrupa las tres entradas que no son criatura (`round`, `generic`,
  `players`): sin vida, sin CA, sin ficha y sin ajustes. Sustituye a las comprobaciones sueltas
  `kind == "round" or kind == "generic"` que estaban repetidas en cinco sitios.
- Solo tiene sentido UNA entrada `players`; el boton avisa en vez de apilar varias.
- **Consecuencia conocida**: el aviso "ES TU TURNO" del hueco PJs llega a todo cliente que tenga el
  tracker sincronizado, tenga o no entrada propia en la lista. Con turnos individuales solo lo
  recibia el jugador nombrado. Si eso molesta, la solucion es una lista de participantes en la
  propia entrada, no cambiar `EntryBelongsToMe`.
- El icono `INV_Misc_GroupLooking` NO se ha verificado en el cliente de Epsilon: comprobar con
  `/harford debug run iconoscheck` antes de darlo por bueno.

**Reglas de reaccion (5e, confirmado):** la reaccion se recupera **al comienzo de tu siguiente
turno**, no al final del asalto. Una reaccion gastada en el turno de un enemigo sigue gastada el
resto del asalto. `API.Turn` ya lo hace asi. Con el hueco PJs, todos los jugadores la recuperan a la
vez, que es el comportamiento correcto bajo iniciativa por bandos.

## Bloques de turno: las tarjetas especiales guardan a los suyos (2026-08-26)

- **La lista de un bloque vive en el CORE** (`HarfordTurnOrderAPI.OpenBlockPanel`) y la abre
  CUALQUIERA con el click izquierdo: mirar quien esta dentro es informacion, no una herramienta de
  DM, y HarfordAdmin no esta instalado en el cliente de un jugador. Lo que SI es del DM es
  EDITARLA, y se cuelga con `RegisterBlockPanelDecorator`: sin Admin la lista sigue abriendose, de
  lectura. El decorador corre en CADA refresco, asi que tiene que reutilizar sus botones.
- **Son las MISMAS tarjetas de la ventana de turnos**, no una imitacion: las monta
  `CreateCardVisuals` y las pinta `PaintEntryCard`, y la ventana usa esas dos. **No rehacer la
  tarjeta**: la primera version lo hizo y quedaban parecidas pero se actualizaban de otra forma.
- **Un miembro ES una entrada**: `AddBlockMember` lo captura con `CapturarUnidadDeTurno`, el mismo
  codigo que una tarjeta normal (icono, displayId, vida, CA, unitName, kind), y se le pasa TAL CUAL
  al pintor. Guardar solo guid/nombre obligaba a rellenar el resto de la unidad que tuvieras
  delante: al cambiar de objetivo se perdia el icono, la CA salia 0 y la vida de un PJ era la
  NATIVA en vez de la del sistema Harford. Un jugador conserva `kind = "player"`, que es lo que
  hace que el pintor le busque la vida por nombre. Y el miembro viaja ENTERO por la red: en el otro
  cliente la unidad puede no estar ni a la vista.
- **`.ph dm on` no dispara ningun evento de WoW**: la ventana se queda en modo jugador hasta que la
  cierras y la abres. Por eso `HarfordTurns` registra `HarfordAuthority.RegisterChangeListener` y
  refresca -- los controles de DM se deciden en cada refresco, asi que con eso basta.
- **El click derecho de un bloque abre su lista y no un submenu de anadir** -- eso era la misma cosa
  en dos sitios, y la del menu ni siquiera enseniaba vida ni CA. Sin ser admin no abre nada y
  CALLA: el click derecho se da constantemente y avisar cada vez llenaba el chat.
- En el bloque de PJs hay DOS botones: anadir el objetivo y desplegar el grupo. Cada uno valida el
  tipo -- un NPC no entra en el bloque de PJs ni un PJ en uno de NPCs -- porque colar a uno donde no
  va rompe su bando sin que nadie lo note.
- Vida y CA se leen de la unidad VIVA en cada refresco (`UnitHealth`, y la CA por
  `HarfordDnDCombat.GetArmorClassForUnit`, la misma resolucion que usa el ataque). Sin vista se
  dice `sin vista`: un numero viejo que nadie puede comprobar es peor que no tener numero.
- **Tres por fila, con scroll.** Las tarjetas cuelgan de `panel.contenido` (el hijo del
  `ScrollFrame`); el boton de anadir cuelga del PANEL, fuera del area que se desplaza, para que no
  lo recorte el scroll ni se pierda de vista cuando la lista crece.

Una tarjeta `players` o `generic` -- PJs, Aliados, Neutrales, Enemigos -- **no es un combatiente:
es un BLOQUE**, y guarda en `entry.miembros` quien va dentro.

- Un miembro **no tiene tarjeta**. Se guardan solo `guid`, `name` y `jugador`: lo justo para
  reconocerlo cuando le toque el turno. Su vida y su CA se miran en el **unitframe al
  seleccionarlo**, que es donde ya se ven; el bloque no las guarda y por eso no pueden quedarse
  viejas.
- `GetBandoMembers` cuenta el bloque **y a los de dentro**, o un bloque lleno pareceria vacio.
- `miembros` viaja en la entrada serializada, detras de `tempHp`. Si no viajara, solo los veria el
  DM que los puso.
- **Se retiro el panel de candidatos** que hubo antes: anadia a cada uno como tarjeta suelta, que es
  justo lo contrario de este modelo, y la lista se llenaba.

**Gestion (solo DM, en `HarfordAdminTurns`)**: click DERECHO sobre el bloque abre el menu -- anadir
el objetivo, anadir a todos los jugadores conectados, y sacar a los que ya estan. Click IZQUIERDO
abre la lista de tarjetas con retrato, nombre y vida leida de la unidad viva (`sin vista` cuando no
esta a la mano). Solo a los PJs se les puede anadir en bloque: a los NPC no, porque **el cliente no
permite enumerarlos** mas alla de los que tengan placa visible (confirmado tambien en Atlas, que
resuelve unidades con las mismas dos fuentes: grupo y `C_NamePlate.GetNamePlates`).

## Efectos sobre NPC delegados al lider (2026-08-26)

Un jugador que no es **oficial de fase** no puede bajarle la vida a un NPC ni ponerle un aura: son
comandos de servidor y el servidor se los rechaza. Pero SI puede tirar, calcular su dano y
mitigarlo, que es todo del cliente.

Asi que resuelve el efecto entero y manda **solo el resultado ya calculado** a quien pueda
emitirlo. **No se delega la decision, se delega la ejecucion**: el receptor no vuelve a tirar ni a
mitigar.

- Punto unico: `HarfordDnDConditions.AplicarEfectoNpc(guid, tipo, valor, unidad)`. Devuelve
  `"aplicado"`, `"encolado"`, `"delegado"` o nil.
- Reutiliza la **cola por GUID** de las auras pendientes: en Epsilon solo se puede actuar sobre el
  NPC seleccionado, asi que lo apuntado se ejecuta cuando el receptor lo seleccione -- cosa que
  hara igualmente, porque le toca jugarlo.
- La cola guarda un **DELTA con el signo del comando** (`op = "health"`), no "dano": asi un golpe y
  una curacion pendientes sobre el mismo NPC **se cancelan** en vez de emitir dos comandos que se
  pisan.
- **Cadena de mando**: lider primero, DMs secundarios detras (`GetSecondaryDMs`). Quien no puede
  emitirlo lo pasa al siguiente; si no queda nadie, se avisa a quien lo lanzo.
- **En cadena y no a todos**: si le llegara a varios y dos tuvieran el NPC seleccionado se
  aplicaria dos veces -- un golpe de 7 quitaria 14, y eso no se ve venir en mesa.
- El lider va **primero** porque quien aplica tiene que tener el NPC seleccionado o se le queda en
  la cola; el lider suele estar en todo, un secundario puede no mirar nunca a ese NPC.
- Dos guardias al recibir: solo se acepta si **yo puedo emitirlo**, y solo sobre **NPCs que ya
  estan en el orden de turnos** (`EsNpcDeLosTurnos`), que es lo que impide pedir dano sobre
  cualquier cosa.

Rutas enganchadas: dano de arma (`ApplyWeaponDamageToNpc`), dano y curacion de area, condiciones
(`ApplyToUnit` delega el aura y **guarda el estado igual** -- el estado de Harford no necesita
permiso ninguno) y los botones `+`/`-` de la tarjeta de turno.

## Un icono que no existe deja el de la fila anterior (2026-08-26)

`SetTexture` con una ruta invalida **no borra la textura: la deja como estaba**. Y como las filas
del Libro vienen de un pool, la habilidad hereda el icono de la que ocupaba ese hueco antes. Media
pagina salia con el mismo dibujo.

**Estar en el catalogo no valida un icono.** Varios rasgos de trasfondo declaran arte que no esta
en este build (`w3reforgedmercenarycamp` y similares). Antes de poner una textura hay que
comprobarla con `GetFileIDFromPath` y caer a un respaldo -- es lo que ya hacian
`HarfordCharacterProfessions` y `HarfordCharacterSheet`.

## Una dote es UNA habilidad, y hay que ACTIVARLA (2026-08-26)

Dos cosas distintas que fallaban a la vez:

1. **`GetFeatTraits` devuelve los rasgos sueltos** y el Libro los pintaba como habilidades
   independientes: "Mago de batalla" salia como tres entradas y la dote no aparecia por su nombre.
   `GetFeatAbilities` devuelve **una entrada por dote**, titulada con el NOMBRE de la dote a
   secas --el prefijo `Dote:` sobraba: lo que es se dice en la etiqueta de categoria, como en el
   resto (ninguna se llama `Pasiva: Vision oscura`)--, marcada con `esDote = true` para que su
   etiqueta diga **Dote** y lleve el verde azulado de los perfiles TRP3 (`{col:008c7f}`) en vez del
   color de la mecanica que tenga por debajo. Con la
   descripcion y debajo cada rasgo. Agrupar solo vale porque **ningun rasgo de dote es accionable**
   -- no hay uno con `cast`, `uses` ni `actionKind` -- y la suite lo comprueba: el dia que lo haya,
   cae. `GetFeatTraits` se queda para el motor de efectos y el About, que los necesitan uno a uno.

2. **Elegir una dote no la aplica.** Su opcion no lleva `effects`: lo que aplica son sus rasgos, que
   llegan por `progression.feats`. Hay que llamar a `SetFeatEnabled`. Lo hacia solo el asistente de
   subida; `ReplaceCreation` (que ademas vacia `feats`) y `ficha6` lo omitian.

## Lo mio caduca en MI turno, se llame como se llame (2026-08-26)

Esquivar y Preparar guardan tu nombre como ORIGEN y caducan con `source_turn_start`, que casa el
registro contra la entrada de turno. Si tu turno es el **hueco colectivo**, esa entrada se llama
"PJs" -- y en bandos, "Personajes" --, los nombres no casaban y el estado no se retiraba nunca.

`IdentityMatches` comprueba **primero** si el registro es mio y el turno es mio, reconociendo las
tres formas que puede tener mi turno: entrada individual, hueco `players` y bloque `pjs`. Va
delante porque el hueco colectivo no tiene ni mi guid ni mi nombre.

Afecta a **todo lo que uno se aplica a si mismo con duracion de turno**, no solo a esas dos.

## ChatThrottleLib en `HarfordSync.Send` (2026-08-26)

`Send` usa **CTL** cuando esta (lo trae EpsilonLib y otros siete addons del cliente). Aporta tres
cosas y **no cambia el formato del cable** -- envia el texto tal cual por
`C_ChatInfo.SendAddonMessage`, verificado en vivo: 16 bytes enviados, 16 recibidos:

1. **Callback de entrega con CAUSA**. `NotInGroup = 5` es el fallo silencioso de siempre.
2. Cola con prioridad (`PRIORIDAD_POR_PREFIJO`: tiradas y turnos `ALERT`, fotos grandes `BULK`).
3. Reintento automatico ante saturacion.

Si CTL revienta se cae al envio directo, para no perder el mensaje.

**Chomp queda DESCARTADO**: antepone 12 hex de cabecera y **descarta en silencio** lo que no la
traiga (`if not hasVersion16 then return end`), asi que activarlo dejaria sordo a todo cliente sin
actualizar. Ademas delega en CTL cuando lo encuentra, que es el caso en Epsilon. Solo aportaria
`BNSendGameData` a 4078 bytes, y el CTL propio lo limita a 255 aposta.

## Detector de locales huerfanas en `referencias.py` (2026-08-26)

Cuatro fallos del mismo dia fueron **una local que se queda atras al extraer un modulo**:
`IconPath` (la barra de accion no pintaba), `SheetContext` (un DM con ficha de NPC gastaba sus
propios recursos), `damageType` (el dano viajaba sin tipo y saltaba todas las resistencias) y
`Codec` (reventaba al abrir la ficha de una entrada). No fallan al cargar -- resuelven a nil -- y
casi siempre estan detras de un `and` que las da por ausentes, asi que el guardia entero se vuelve
mudo.

`referencias.py` los caza comparando CONJUNTOS (una regex por nombre tardaba minutos) y acotado a
nombres **distintivos**: mayuscula inicial, cinco letras o mas, y local en UN SOLO fichero. Sin
acotar salian **211 hallazgos, todos ruido**, y un detector asi entrena a ignorarlo. Se quitan
tambien las cadenas antes de buscar: una descripcion que dice "...o Ayudar." ponia `Ayudar.` en el
texto y contaba como acceso a tabla.

## El defensor gana los empates de CA (2026-08-26)

**Divergencia deliberada del manual.** En 5e, una tirada que IGUALA la CA impacta ("equals or
exceeds"). En esta mesa NO: el empate falla y el defensor lo gana.

La comparacion es `>` en los tres sitios que la resuelven:

- `HarfordDnDCombat.ResolveArmorClassOutcome` (`total > armorClass`)
- `HarfordDnDArea` (`request.attackTotal > armorClass`)
- `HarfordDnDRolls`, al recalcular tras gastar un dado o un modificador

Los dos primeros ya lo hacian; el tercero usaba `>=` y **se contradecia con ellos**: la misma
tirada contra la misma CA salia "No superada" al atacar y "Superada" al gastar el dado sobre ella.

Esta escrito aqui porque una decision de mesa sin documentar se "corrige" sola en la siguiente
revision: paso el 26 de agosto, cuando una revision la marco como bug citando el manual. El
comentario en el codigo -- "empate = fallo para el atacante (el defensor gana los empates)" -- es
lo unico que lo delataba.

## La descripcion de un objeto de Epsilon viene ENTRECOMILLADA (2026-08-27)

El editor de objetos de Epsilon guarda la descripcion entre comillas, y el tooltip las muestra: una
descripcion de una linea sale como `"CA +1"`, y una de varias abre comilla en la primera linea y la
cierra en la ultima.

Los patrones de regla de `ParseTooltipRules` estan anclados a la linea COMPLETA (`^...$`), a
proposito, para que una frase de sabor que mencione un numero no se convierta en mecanica. Con la
comilla pegada, **ninguno casaba**: la linea pasaba a texto narrativo y la regla se perdia sin dar
error. Afectaba a TODAS las lineas mecanicas de TODOS los objetos custom -- `CA +1`, `Fuerza +2`,
`Dano extra 1d6 fuego` --, no solo a la CA.

`StripWrappingQuotes` quita la comilla inicial y la final por separado (recta, simple y
tipografica), y **solo para intentar leer la regla**: el texto narrativo conserva las suyas.

Sintoma con el que se encontro: unas botas verdes con `"CA +1"` no movian la CA ni un punto. El
diagnostico `/harford debug run ca` las listaba como `Feet  Botas de Conrad  CA +0` -- resueltas,
con nombre, pero sin reglas.

**La rareza de una pieza de armadura tampoco daba CA** si el objeto custom no venia con clase
"Armadura" de WoW. `ResolveCategory` mira la clase declarada, y un item de Epsilon puede no
traerla. Ahora el bonus por calidad acepta tambien el HUECO (`ARMOR_EQUIPLOC`: cabeza, hombros,
pecho, tunica, cintura, piernas, pies, muneca, manos, capa). Anillos, abalorios y cuello quedan
FUERA a proposito: su rareza no es una pieza de armadura y no debe dar CA.

## La linea de dano la publica LA VICTIMA (2026-08-28)

Solo el defensor conoce sus resistencias, asi que solo el puede decir el numero definitivo. Antes
el atacante publicaba su numero en bruto y la victima anadia DETRAS una linea de correccion cuando
no coincidia: dos lineas por golpe mitigado. Ahora hay UNA, y la dice la victima.

En la mesa se lee **igual que antes** -- `Gmaster [Espada larga] 5 Cortante R` -- porque la
etiqueta del atacante viaja con el dano (`DNDDMG|<componentes>|C|M|<etiqueta>`) y la victima
publica con `player = sender` y esa etiqueta. Lo unico que cambia es que el numero ya es el real.

Detalles que costaron y no deben perderse:

- **La etiqueta va la ULTIMA y NO se saca con `strsplit("|")`.** Un enlace de objeto lleva pipes
  dentro (`|cff…|Hitem:…|h[Espada larga]|h|r`), asi que el split la cortaba en el primero y llegaba
  como `"Dano "`. Se coge el resto de la cadena de una pieza con un `match`. Lo cazo la prueba de
  `dano_payload`, no el juego.
- Se compacta con `HarfordDnDRolls.NetworkLabel` (expuesto para esto): conserva color y
  clicabilidad y suelta la cadena larga de estadisticas. Si aun asi no cabe en 240 bytes se recorta
  **la etiqueta**, nunca los componentes -- el dano es el dato.
- **El atacante solo calla si sabe que la victima corre Harford**, y eso se sabe porque ha
  difundido sus recursos alguna vez (`HarfordDnDCombat.VictimaPublicaSuDano` mira
  `HarfordDnDResources.RemoteCache`). Si no lo sabe, publica el bruto como siempre: no hay acuse en
  ningun sitio de este sistema, asi que callarse a ciegas seria perder la linea entera.
- Un mensaje **sin** etiqueta (cliente anterior, o no cabia) mantiene el comportamiento viejo: el
  atacante publico, y la victima solo corrige si el resultado real no es ese.

## La foto de turnos: comprimida, y solo cuando cambia la LISTA (2026-08-28)

El reensamblado de un mensaje troceado es **todo o nada** y **no hay acuse ni reintento**: si falta
un trozo, `buffer.received < total` devuelve false, el TTL de 15 s borra el buffer en silencio y no
se aplica nada. Ni el emisor sabe que falto, ni el receptor sabe que le faltaba. En el cliente eso
no se ve como un error: se ve como que el DM ha dejado de hablar.

Con la mesa llena la foto son ~2400 bytes = **12 mensajes**. Basta perder uno.

Tres cambios, por orden de importancia:

1. **Avanzar el turno ya no manda la foto.** El aviso `TURN` lleva serial, indice, la entrada y
   ahora tambien el **asalto** -- que era lo unico que viajaba solo en la foto. Va en el quinto
   hueco, vacio desde que se retiro el avance por bloques, asi que no cambia el numero de campos.
   Un aviso de un cliente viejo trae ahi texto: `SafeNumber` lo deja en 0 y no pisa el asalto de
   nadie. De 13 mensajes por pulsacion a 1. `MarcarLocal` apunta y repinta sin difundir.
2. **La vida de un NPC va sola** (`THP|guid|hp|maxHp`). `UNIT_HEALTH` dispara en rafaga y cada
   disparo difundia la lista entera para cambiar un numero. Se aplica ademas a los MIEMBROS de un
   bloque, que guardan vida y no tienen tarjeta propia.
3. **La foto va comprimida** con LibDeflate (viene en EpsilonLib, en TRP3 y en Epsilon_Book; se
   registra en LibStub y como global). Es texto muy repetitivo y pasa de ~2400 a ~275 bytes:
   **12 trozos a 2**. Marca `Z|` al principio del payload; el transporte no cambia.

La compresion vive en **`HarfordSync.Comprimir` / `.Descomprimir`**, no en cada sistema: es el
transporte y la usan varios. Duplicarla seria tener dos formatos de cable que divergen sin avisar.
Aplicada en la foto de turnos (2398 B / 12 trozos -> 295 / 2), en `DNDEQUIP` (equipo completo:
1210 / 7 -> 360 / 2) y en `DNDCLASS` (progresion multiclase nivel 6: 662 / 4 -> 246 / 2).

**Al anadir un sistema hay que tocar DOS sitios**: comprimir en el envio y deshacer en su
deserializador. Olvidar el segundo no da error -- los mensajes llegan y se descartan en silencio,
que es justo el fallo que se persigue. La suite `progresion` cuenta las dos apariciones para que no
se quede a medias.

**Loot resuelto y snapshots de reputacion quedan FUERA por ahora**: escapan el payload
(`EscapeProgressionText`) ANTES de trocear, asi que el orden con la compresion hay que pensarlo
aparte. No es que no compensen; es que no es el mismo cambio.

**Por que comprimir y no arreglar el troceado.** El fallo es MULTIPLICATIVO: tienen que llegar
TODOS los trozos, asi que con 12 trozos y un 1% de perdida por mensaje falla el 11,4% de los
envios; con 2, el 2%. Al 5% de perdida, 12 trozos fallan el 46% de las veces. Ademas menos
mensajes bajan la propia tasa de perdida, porque satura menos el throttle. Un acuse con reintento
seria un protocolo nuevo -- quien acusa, cada cuanto, que pasa si el que pide ya no esta --;
comprimir QUITA el problema en vez de gestionarlo, en veinte lineas y con una libreria que ya esta.

**`EpsilonLib` es `RequiredDeps`, y en parte POR ESTO.** De ella sale LibDeflate. Sin esa
declaracion el fallo era asimetrico y mudo: si un cliente la tiene y otro no, el que no la tiene
DESCARTA EN SILENCIO todo lo comprimido --y antes le llegaba troceado y le funcionaba--, con un
sintoma ("no me llega el equipo al inspeccionar") que se parece a otras diez cosas. Ya era una
dependencia de hecho --`AddonCommands`, `PhaseAddonData`, `EventManager` en 13 ficheros, todos
guardados con `if EpsilonLib and ...`-- asi que solo se hizo explicita: mejor no cargar que cargar
a medias y callado. Anunciar la capacidad en un saludo NO habria bastado: la foto de turnos va por
RAID, a todos a la vez, y no se puede comprimir para unos y no para otros en el mismo mensaje.
La garantia depende de que EpsilonLib SIGA incluyendo LibDeflate; si algun dia la quita, toca
empaquetarla dentro de Harford, y el grupo `comprimir` de la bateria lo dice.

**`EpsilonLib` es `RequiredDeps`, y en parte POR ESTO.** De ella sale LibDeflate. Sin esa
declaracion el fallo era asimetrico y mudo: si un cliente la tiene y otro no, el que no la tiene
DESCARTA EN SILENCIO todo lo comprimido --y antes le llegaba troceado y le funcionaba--, con un
sintoma ("no me llega el equipo al inspeccionar") que se parece a otras diez cosas. Ya era una
dependencia de hecho --`AddonCommands`, `PhaseAddonData`, `EventManager` en 13 ficheros, todos
guardados con `if EpsilonLib and ...`-- asi que solo se hizo explicita: mejor no cargar que cargar
a medias y callado. Anunciar la capacidad en un saludo NO habria bastado, porque la foto de turnos
va por RAID, a todos a la vez, y no se puede comprimir para unos y no para otros en el mismo
mensaje. La garantia depende de que EpsilonLib SIGA incluyendo LibDeflate (hoy la carga en
`Lib/Lib.xml`); si algun dia la quita, toca empaquetarla dentro de Harford, y el grupo `comprimir`
de la bateria lo dice con esas palabras.

**NUNCA en el vault de fase.** Es otro transporte y otra cosa: alli trocea EpsilonLib en segmentos
de 3000 caracteres, el SERVIDOR lo persiste (no hay perdida silenciosa que arreglar) y sobrescribir
con menos datos **NO limpia los segmentos sobrantes** -- via real de corrupcion, la misma que sufre
TRP3 al desvincular un perfil de NPC. Comprimir alli ahorraria segmentos y dejaria cola colgada.

Reglas que NO deben perderse:

- **Se comprime SOLO lo que no cabe en un mensaje.** Por debajo de `TURN_SINGLE_MESSAGE_LIMIT` se
  manda en claro y lo entiende cualquier cliente, incluido uno sin actualizar. Y si comprimir no
  encoge, se manda en claro igual.
- Un cliente sin actualizar que reciba un payload `Z|` lo descarta (su parser exige `STATE`): se
  queda sin actualizar la lista, que es lo mismo que le pasa HOY al perder un trozo, solo que hoy
  pasa a menudo. No se corrompe nada.
- **El ICONO se queda en el cable.** Se penso quitarlo por tamanio y es un error: sale del perfil
  TRP3 de la unidad (`GetProfileIcon`), no de `displayId` ni de nada derivable, y el receptor puede
  no tener a esa criatura ni a la vista -- lo que no se manda no se puede recuperar alli. Ademas,
  comprimido cuesta 37 bytes (275 con icono, 238 sin) y no ahorra ni un mensaje.
- `Chomp` NO es el camino, aunque sea lo que usa TRP3: antepone 12 hex de cabecera y descarta lo
  que no la traiga, asi que dejaria sordo a todo cliente sin actualizar. De TRP3 se toma la otra
  mitad de su receta, que es comprimir.

## El avance por BLOQUES se retiro; los bloques se quedan (2026-08-27)

Hubo un segundo modo de avanzar el turno: en vez de ir de criatura en criatura, iba de **bloque en
bloque** — le tocaba a Enemigos y actuaban los cinco a la vez. Se encendia con un boton `Bandos` en
la ventana y viajaba en la foto para que la mesa entera estuviera en el mismo modo.

**Se ha quitado.** No funcionaba bien y nadie sabia para que estaba, que es la peor combinacion
posible en algo que se cruza con la red, la economia de turno y el motor de condiciones. Queda
**una** forma de avanzar: de criatura en criatura, `activeIndex`.

Lo que **no** se ha quitado, y no debe volver a mezclarse con lo anterior:

- **Los cuatro bloques siguen existiendo como TARJETAS**: `BANDOS`, `BANDO_ETIQUETA`, `GetBando`,
  `SetBando`, `GetBandoMembers`, el panel de miembros y el reparto desde el menu de DM. Un bloque es
  una entrada mas de la lista, con los suyos dentro. Eso se pidio y funciona.
- **El turno de un bloque caduca los estados de TODOS los suyos.** Antes colgaba de una entrada
  sintetica `kind = "bando"` que fabricaba el avance por bloques; al retirarlo, la tarjeta paso a
  ser una entrada normal — y sin tocar nada, un turno de `Enemigos` no habria caducado nada a nadie,
  porque la tarjeta no tiene ni guid ni nombre contra los que casar. `IdentityMatches` recorre ahora
  `entry.miembros` cuando la entrada es `players`/`generic`.
- **El asalto sube al pasar por el MARCADOR.** Se contaba solo al dar la vuelta a los bloques, que
  era el unico sitio; sin trasladarlo, las duraciones medidas en asaltos habrian dejado de bajar.
- **El estandarte lo levanta TU turno** (`AlertMyTurn`), no el comienzo de un bloque.

Compatibilidad, que es donde esto se puede volver a romper en silencio:

- **El hueco del modo sigue en la foto, vacio.** El tercer campo es `modo~dms~estado`; quitar el
  hueco descuadraria los otros dos en un cliente sin actualizar, y eso no da error: da un combate
  que no comparte estado.
- **`TURNB` se recibe y se DESCARTA.** Un cliente viejo puede seguir emitiendolo; aplicarlo
  reintroduciria el modo por la puerta de atras.
- Los `store.activeBando = nil` / `faseBando = nil` que quedan son la limpieza del dato viejo en
  disco. No son restos: son la migracion.

## La economia de turno BLOQUEA, no avisa (2026-08-27)

- **Sobrevive a un `/reload`.** Era una tabla de runtime: recargabas y recuperabas accion, adicional
  y reaccion. Con la economia bloqueando, eso deja de ser un detalle y pasa a ser **la forma de
  saltarsela**. Se guarda en `HarfordTurnOrderStore.economia` sellada con el ASALTO y tu guid --el
  mismo trato que el contador de movimiento-- y se retoma en `PLAYER_ENTERING_WORLD`. El sello
  impide que lo de un combate se aplique a otro.
- **`GuardarEconomia` va declarada ANTES que `Turn.Spend`**, que es quien la usa: un
  `local function` declarado despues no es una upvalue, se resuelve como global y vale nil. Y
  `Turn.RestoreFromStore` va DESPUES, donde `Turn` ya existe.

- `Turn.Spend` apuntaba el gasto **aunque no cupiera**, asi que el contador se iba a negativo y el
  "ya lo habias gastado" era un aviso y nada mas: seguias atacando y lanzando. Ahora un gasto que
  no cabe **devuelve false y no deja rastro**, y los tres llamadores lo respetan:
  `DoWeaponAttack` no ataca, `BroadcastAbility` no anuncia ni ejecuta, y `ConfirmCast` no lanza.
- **El coste del conjuro se cobra ANTES que el mana**: si no te queda esa accion el conjuro no
  sale, y asi no hay que devolver nada. Cobrar por un conjuro que no sale es peor que no llevar la
  cuenta.
- **Un ataque que no ocurre tampoco se apunta** (`ECONOMIA.ataques` se decrementa): si no, el
  siguiente intento se tomaria por el segundo de la tanda y saldria gratis.
- **Las fichas y la barra de movimiento viven en el MARCADOR DE TURNO**, no encima de la barra de
  accion. Es lo que te queda ESTE turno y su sitio es junto al turno y el asalto; tenerlas en los
  dos lados era la misma informacion en dos sitios. Sobre la barra de accion se quedan solo los
  ORBES de espacios de conjuro, que **no son del turno** --no se renuevan con el-- y por eso se ven
  tambien fuera de combate.

## La economia de turno se GASTA de verdad (2026-08-27)

- Solo cobraba a los rasgos del Libro que declaran `cast` (via `BroadcastAbility` →
  `SpendForFeature`). **Atacar con el arma y lanzar un conjuro no cobraban nada**, que es
  justamente lo que la gente hace en su turno: las fichas no bajaban nunca y el contador quedaba de
  adorno.
- **Lo que cuesta un ataque lo decide `Turn.SpendWeaponAttack(esOffhand)`**, no la ficha. Tres
  casos y confundirlos hacia el contador inutil:
  - **Mano SECUNDARIA** → cuesta **accion ADICIONAL** (Combate con Dos Armas), no la accion, y no
    cuenta contra los ataques de la accion.
  - **Los N de tu accion de Atacar** → solo el primero cobra; los demas van dentro de esa misma
    accion. **N sale del RASGO** (`flag extraAttack` → 2, si no 1): Ataque Extra hay que TENERLO,
    y a nivel 4 el segundo ataque es una segunda accion de Atacar.
  - **N+1 en adelante** → otra accion de Atacar, y se cobra como tal.
- **Ataque Extra y "accion adicional por rasgo" son cosas DISTINTAS** y el Guerrero de nivel 6
  tiene las dos: una da mas ataques dentro de la accion (`flag extraAttack`), la otra da un hueco
  mas en el turno (`grantsTurnAction`). No mezclarlas.
- `ECONOMIA.ataques` se reinicia en `Turn.Reset()`: sin eso, el primer ataque del turno siguiente
  se tomaria por el segundo y saldria gratis. `options.skipTurnCost` lo ponen las rutas que ya
  cobraron (maniobras), y la criatura acompanante no gasta la economia de su duenio.
- **`ConfirmCast` cobra lo que diga el TIEMPO DE LANZAMIENTO** del conjuro, no siempre accion:
  "adicional"/"bonus" → adicional, "reacc" → reaccion, y los de minutos u horas **no cobran nada**
  porque no se juegan por turnos. Un ritual sale por su rama antes de llegar ahi.
- Diagnostico de por que no arranca solo el contador de movimiento:
  `/harford debug run movimiento` (y `movimiento simular` dispara el aviso de turno a mano, que es
  el eslabon que no se puede provocar sin montar un combate entero).

## El DM puede DEVOLVER lo gastado (2026-08-27)

- Menu de unitframe → `Turnos` → `Devolver`: **Accion, Accion adicional, Reaccion y Movimiento**.
  Sirve para cuando algo no llego a pasar --se cancelo, el objetivo ya no estaba-- y cobrarlo seria
  quitarle el turno a alguien por un error de mesa.
- **No es lo mismo que `GrantExtra`**: aquello SUBE el presupuesto (te da una accion de mas), esto
  DESHACE un gasto. `Turn.Refund(kind)` no baja de cero, asi que devolver dos veces no regala nada.
- **Lo aplica el RECEPTOR** (`TGIVE` por whisper): es quien lleva su propia economia, y escribirsela
  desde fuera daria dos verdades distintas sobre lo mismo. Con el mismo filtro de remitente que el
  resto de mensajes con efecto, y **lista cerrada de tipos**: lo que llega por el cable no elige a
  que parte del motor se llama.
- El movimiento se devuelve con `RefundTurnMovement`, que pone el contador a cero y levanta el muro
  **sin tocar el ancla de inicio**: sigues donde estas y en el mismo turno. No te MUEVE.
- **`Profesiones` sale del menu de un jugador**: es su ficha, no una herramienta de mesa.

## `Siguiente` pasa UN bloque (2026-08-27)

- El avance por bandos tenia **dos fases por bloque** --empezarlo y cerrarlo-- asi que pasar de
  Enemigos a Neutrales costaba DOS pulsaciones, y en medio la mesa se quedaba mirando un "cerrando
  Enemigos" que no le dice nada a nadie. **Retirada**: un bloque por pulsacion, adelante y atras.
- Lo que caducaba al CERRAR un bloque caduca ahora al EMPEZAR el siguiente: es el mismo instante.
- La fase sigue viajando en el mensaje **por compatibilidad** con clientes anteriores, pero vale
  siempre `inicio`. No reintroducir la fase de cierre.

## Unirse a un combate en curso (2026-08-27)

- **Se sale FUERA de combate por defecto**: nadie entra solo porque haya una pelea en su raid. Al
  entrar se pide la foto (`TREQ`) y, **si el DM ya te tenia en el bloque de PJs**, vuelves dentro
  solo -- la foto trae el estado y los miembros.
- Si NO estabas, hay un boton **`Unirse`** en la ventana de turnos, en el sitio de `Limpiar` (que
  es de DM, asi que nunca se ven los dos). Solo aparece con combate empezado y estando fuera.
- **Es AUTOMATICO**: mandas `TJOIN` y el cliente del DM te mete solo, sin confirmar nada -- al DM
  se le avisa y ya. Pasa por el porque **la lista es suya** (una entrada anadida en local
  desapareceria con la siguiente foto), no porque haya que pedirle permiso.
- Lo unico que lo para es que el DM **no te vea** (`FindUnitByName`): un nombre suelto no basta
  para saber a quien estas anadiendo, y ahi si te mete a mano.

## Un combate abandonado caduca ENTERO (2026-08-27)

- `PurgeStaleEntries` (15 min sin tocar la lista, al entrar) limpiaba las ENTRADAS pero **no el
  estado**: quien se desconectaba a media pelea y volvia al dia siguiente --sin nadie que le
  mandara una foto nueva-- se encontraba la lista vacia y `estado = "activo"`. O sea, **"en
  combate" el solo**, con el asalto de ayer.
- Ahora se van tambien `estado`, `asalto` y lo gastado (`movimiento`, `economia`), **que iba
  sellado con el asalto**: si el asalto se va y el sello se queda, podria aplicarse a la pelea
  siguiente. Y se llama a `CleanUpAfterCombat`, igual que al Terminar.
- **No se sale por lista vacia**: lo que caduca es el COMBATE, y su estado puede haber quedado
  puesto sin entradas.
- **La caducidad solo se comprueba AL ENTRAR** (`PLAYER_LOGIN`), no mientras juegas: estar
  conectado cuatro horas no mata un combate. Lo que se mide es cuanto lleva la lista sin TOCARSE.
- **Recibir la foto cuenta como tocarla.** Es la unica senal de vida de un jugador que no manda
  nada: sin eso su sello se quedaba a `nil` --que se lee como "de una version anterior", o sea
  vieja-- y un `/reload` justo despues de entrar en combate le borraba la pelea en curso.

## Si el DM se cae, releva un companero (2026-08-27)

- `TREQ` lo contestaba **solo el DM**. Si se caia a mitad de combate, quien entraba o reconectaba se
  quedaba sin nada. Copiado del `COMBAT_QUERY` de Atlas, cuyo comentario dice que sirve "para que
  los lideres que han crasheado tambien puedan recuperar de sus pares".
- **La foto del DM sigue mandando**: contesta al instante. Un companero espera **5 s** y solo
  responde si en ese rato **no ha pasado ninguna foto** por el canal (`ULTIMA_FOTO_VISTA`) -- si
  paso, alguien con mas derecho ya contesto, y dos fotos distintas serian peor que ninguna.
- Tampoco contesta si el no tiene combate que servir. `SendStateTo(target, comoPar)`: el segundo
  argumento es el UNICO camino por el que un no-DM puede servir la foto.

## El estado del combate es EXPLICITO (2026-08-27)

- Tres estados, como en Atlas: sin combate, `preparando` (mesa montada, sin empezar) y `activo`.
  `HarfordTurnOrderAPI.GetCombatState()` / `SetCombatState()`, guardados en `store.estado`.
- **`HasActiveCombat()` dice si el combate se ha INICIADO**, no si hay gente en la lista. Lo
  segundo lo contesta ahora **`HasCombatants()`**, que es lo que mira `StartCombat` -- preguntar
  por `HasActiveCombat` alli era circular y solo funcionaba porque eran lo mismo.
- **Terminar el combate YA NO vacia la lista.** Eran dos cosas distintas juntadas, y obligaba a
  volver a montar la mesa entera entre escena y escena. Vaciar es el boton `Limpiar`, y ese SI
  termina ademas: un combate "activo" sin nadie dentro no tiene sentido.
- **El estado viaja al FINAL del tercer hueco**, detras de los DMs: un cliente anterior lee modo y
  DMs como siempre y no llega a mirarlo, en vez de descuadrarse los campos. Y si el mensaje **no lo
  trae, no se toca el nuestro** -- poner nil ahi mataria un combate en curso cada vez que hablara
  alguien sin actualizar.
- Compatibilidad: una lista guardada por una version anterior no trae estado, asi que un combate
  con `asalto > 0` y combatientes se sigue considerando activo. Sin eso, actualizar el addon a
  media sesion mataba el combate en curso.

## Al terminar el combate se recoge TODO, y en un sitio (2026-08-27)

- `RecogerTodo()` en `HarfordTurnsCombat` es el UNICO punto de limpieza de fin de combate: economia
  de turno, contador de movimiento, estandarte y marcador. Antes cada cosa que caducaba se
  enganchaba donde buenamente podia --el contador de movimiento acabo escuchando al motor de
  condiciones para enterarse-- y de lo que se anadia despues no se acordaba nadie. Copiado del
  `EndCombatState` de Atlas, que recoge todo de golpe.
- **Un modulo nuevo trae su limpieza consigo**: `HarfordTurnsCombat.RegisterCombatCleanup(nombre,
  fn)`. No ampliar la lista fija de dentro.
- **Cada apartado con `pcall`**: que falte un modulo o falle uno no puede dejar los demas sin
  recoger, porque entonces el combate siguiente arranca con restos del anterior.
- **Tambien al RECIBIRLO de otro cliente.** Quien pulsa Terminar limpia su ficha, no la de los
  demas: `ApplySerializedState` compara si habia combate y ya no, y recoge. Sin eso solo quedaba
  limpio el que dio al boton -- al resto se le quedaba el contador corriendo y el estandarte del
  ultimo turno puesto.
- `HideTurnBanner` retira el estandarte YA, sin desvanecerse: al terminar no hay nada que rematar y
  dejarlo salir solo mantiene en pantalla el aviso de un combate que ya no existe.

## El marcador de turno (2026-08-27)

- Ventanita PERMANENTE con de quien es el turno y por que asalto vamos
  (`HarfordTurnOrderAPI.RefreshTurnMarker`). El estandarte pasa en cuatro segundos; esa pregunta se
  hace cinco minutos despues, y hasta ahora la respuesta vivia solo en la ventana de turnos, que
  nadie tiene abierta todo el rato. Copiado del `TurnTracker` de DiceMaster.
- Arte NATIVO y por faccion: `AllianceScenario-TrackerHeader` / `HordeScenario-TrackerHeader`
  (243x77), comprobado con `C_Texture.GetAtlasInfo` antes de pintar.
- **En bandos dice tambien la FASE**: "cerrando el bloque" o "jugando". `cierra Enemigos` y
  `empiezan Enemigos` son dos momentos distintos del mismo bloque y desde fuera se confunden.
- **Se repinta en TRES sitios y hacen falta los tres**: `AlertTurnChanged` (cambio de turno),
  `MarkChanged` (iniciar y terminar el combate NO son cambios de turno, asi que sin este se quedaba
  puesto despues de terminar) y al recibir estado de otro cliente, que no pasa por `MarkChanged`
  porque seria reenviarlo.
- **Lleva DENTRO la barra de movimiento y las fichas de economia.** Vivian sueltas encima de la
  barra de accion: es todo lo mismo --lo que te queda este turno-- y en dos sitios obliga a mirar a
  dos sitios. **Click en la barra: vuelves a donde EMPEZASTE el turno** y el contador a cero
  (`HarfordDnDAttackUI.ReturnToTurnStart`), que es lo que quieres cuando te has colocado mal y no
  tenia gesto. Se repinta tambien al moverse y al gastar, no solo al cambiar de turno.
- **El marco de OBJETIVO lo crea `CreateCardVisuals`, no `CreateCard`.** Vivia en el segundo, asi
  que las tarjetas de la lista de un bloque no lo tenian -- y `SetCardTargetState` comprueba
  `if card.targetTop then`, asi que no fallaba: no hacia nada, en silencio.
- `MEDIUM` nivel 60, no DIALOG: se queda en pantalla y no puede ponerse por delante de una ventana.
  Movible con `SetUserPlaced`. Ajuste `turnmarker` (`on` por defecto). **Sin ticker**: solo se
  repinta cuando cambia lo que dice.

## El estandarte de turno (2026-08-27)

- Aviso grande al empezar un turno, al estilo del de DiceMaster. **Todo el arte es NATIVO**
  (`BossBanner-BgBanner-Mid` de fondo, `BossBanner-RedLightning` espejado a los dos lados). De los
  11 atlas que usa DiceMaster, **10 existen en este build**; el que falta, `BossBanner-Title`, es
  prescindible porque el titulo es texto. Comprobar con `/harford debug run atlas`.
- **Si el atlas no existe no se pinta nada.** Un atlas ausente no borra la textura anterior, la
  deja como estaba: mas vale no pintar que pintar un rectangulo con la textura de otra cosa.
- **Solo al EMPEZAR.** En bandos, `AnunciarBando` lo levanta con `fase == "inicio"` -- al cerrar el
  bloque no empieza nada. En individual lo levanta `AlertMyTurn`, o sea SOLO cuando te toca a ti:
  un estandarte por cada combatiente seria insoportable.
- El titulo va **dorado si empieza el bando de los PJs**, que es siempre el tuyo (`AddEntry` manda
  a un jugador a `pjs` se ponga donde se ponga, asi que no hay que buscarse entre los miembros).
- `frameStrata` **HIGH y no DIALOG**: tiene que verse sobre el juego pero no tapar una ventana
  abierta, porque dura cuatro segundos y no se puede apartar.
- **Sin ticker**: entra con un `AnimationGroup` y se retira con un `C_Timer.NewTimer` de una sola
  vez, que se cancela si vuelve a salir antes. Ajuste `turnbanner` (`on` por defecto).
- **Debajo lleva TARJETAS con lo que te queda por gastar** (accion, adicional, reaccion y
  movimiento), con fondo `LootBanner-ItemBg` y aro `LootBanner-IconGlow`, los dos nativos. Es la
  idea que mejor funciona de DiceMaster --el aviso no solo dice que te toca, ENSENA lo que puedes
  hacer--, pero lo suyo es una lista fija escrita a mano y esto sale de la economia REAL: un Impetu
  de Accion se ve como dos acciones y no como una.
- **Solo en TU turno y solo lo que QUEDA.** En el turno de otro serian cuatro tarjetas de relleno
  tapando la pantalla, y pintar lo gastado contradice para lo que esta la tarjeta.
- El texto de cada tipo vive en `HarfordTurnOrderAPI.TEXTO_ECONOMIA`, no dentro del estandarte: el
  marcador y los tooltips dicen lo mismo y dos copias se acaban contradiciendo.
- Vista previa a mano: `/harford debug run estandarte <titulo> ; <subtitulo>`, y
  `/harford debug run banners` para verlos todos seguidos.

## Movimiento del turno: se cuenta solo y el limite es un muro (2026-08-27)

- **La economia se pinta sobre la barra de accion nativa, estilo BG3** (`HarfordActionBars`): fila
  de FICHAS (Accion / Adicional / Reaccion, una por punto de presupuesto -- Impetu de Accion da
  dos), y encima la BARRA de movimiento, que es un recurso continuo y no cabe como ficha. Verde,
  ambar en el ultimo tercio, roja al agotarse.
- **Los orbes de espacios de conjuro solo salen en modo `slots`.** En modo mana no hay piramide que
  pintar y no aparece nada. Ojo: `HarfordDnDMana.IsEnabled()` devuelve true con el MANA activo, asi
  que la piramide es el caso CONTRARIO.
- Fichas y barra solo con turnos activos: fuera de combate no se lleva la cuenta y pintarlas llenas
  seria informacion falsa. Los orbes SI se ven siempre, porque no se renuevan por turno.
- **Sin ticker.** Las fichas las refresca el listener de `HarfordDnDConditions`; la barra, el
  `RegisterMovementListener` del seguimiento de la ficha, que ya corre mientras andas.

- **ESTAR EN LA RAID NO ES ESTAR EN LA PELEA.** `HarfordTurnOrderAPI.AmIInCombat()` decide si TU
  estas dentro: entrada propia, miembro de algun bloque, o llevando un NPC poseido siendo DM --ahi
  juegas SU turno--. `Turn.IsActive()` exige las dos cosas (hay combate Y estoy dentro), y como
  todo lo del turno cuelga de ahi, basta con decirlo una vez: a quien solo mira no se le pintan
  fichas de accion, ni barra de movimiento, ni se le limita nada.
- **FUERA DE COMBATE NO SE LIMITA NADA.** Todo lo del turno --contador de movimiento, muro,
  economia de accion/adicional/reaccion-- es del MODO COMBATE. Fuera, la gente tira y se mueve
  como siempre: el contador puede medir si lo arrancas a mano, pero **no marca ancla ni tira de
  nadie**, y `Turn.Spend` devuelve exito sin apuntar nada. No anadir avisos ni bloqueos que se
  disparen sin combate activo.
- **Estar en combate es una CONDICION del contador, no un detalle.** Fuera de un combate por turnos
  no hay turno que gastar y un contador corriendo miente, asi que NO arranca solo -- pero a mano
  si, porque el boton tambien sirve para medir una distancia sin mas. Y **se para al ACABAR el
  combate**, que es el caso que se olvida: el turno no "termina", desaparece el combate entero, y
  sin eso el contador seguia con un tope que ya no valia y el muro te devolvia a un sitio de otro
  combate. Lo avisa el listener de `HarfordDnDConditions`.
- **El motor del contador NO puede colgar de la ficha.** WoW **no ejecuta `OnUpdate` en un frame
  oculto**, y el boton de movimiento vive dentro de la seccion Ataque: con la ficha cerrada el
  contador no contaba nada y no lo decia nadie. "Funcionaba" al pulsar el boton solo porque para
  pulsarlo tenias la ficha abierta. El `OnUpdate` va en `HarfordMovementDriver`, un frame de 1x1
  colgado de UIParent y siempre mostrado; el boton es solo el mando.
- **Se cuenta SOLO, no hay que pulsar nada.** `HarfordDnDAttackUI` arranca el seguimiento desde el
  listener `RegisterMyTurnListener`, igual que Atlas. El boton queda para pararlo antes de tiempo
  (izquierdo) y para volver al ancla (derecho). Tener que acordarse de pulsarlo cada turno era la
  friccion que hacia que la cuenta no se llevara nunca.
- **Se mide distinto segun quien se mueva.** Un JUGADOR tiene posicion: se resta donde estaba de
  donde esta, que es el dato REAL. De una criatura POSEIDA no hay posicion que leer -- un NPC
  poseido es el `pet` del cliente y `UnitPosition` solo habla del jugador --, asi que se INTEGRA su
  velocidad (`GetUnitSpeed("pet") * 0.9144 * dt`). Es una estimacion, pero con la velocidad REAL:
  Atlas da por buena la carrera base (7 yd/s) y con eso un ralentizado gasta su turno igual de
  rapido que uno suelto.
- **Un salto de mas de 5 m en una muestra no cuenta como paso.** Es un desplazamiento (el teleporte
  de vuelta, un empujon) y sumarlo hacia que el tiron se pagase a si mismo y encadenara teleportes.
- **DOS anclas, y hacen cosas distintas** (como en Atlas): la del INICIO del turno
  (`API.TurnStartAnchor`), a la que se vuelve A MANO con click derecho en el boton -- deshace el
  turno entero y pone el contador a cero --, y la del AGOTAMIENTO (`API.RecordedMovementAnchor`),
  que es a donde te devuelve el muro. Las dos se olvidan al empezar el turno siguiente.
- **Al NPC NO se le pone muro, solo se le cuenta.** `worldport` mueve TU cuerpo, no a la criatura
  poseida, y `npc info` actua sobre el objetivo, que mientras posees no es ella: no hay comando con
  el que devolverla. Se avisa al agotarlo y corregir es cosa del DM -- que es exactamente lo que
  hace Atlas, cuyo `TryOutOfTurnMovementSnapback` empieza con `if isPossessing then return end`.
- **El muro salta EN EL INSTANTE en que se agota el recurso**, dentro del `OnUpdate`, no al soltar
  la tecla: el movimiento se acaba cuando se acaba, y esperar a que pares regala los metros de en
  medio. Si sigues andando te devuelve otra vez -- no es un aviso de una sola vez --, con
  enfriamiento de 0.6 s porque el servidor tarda en responder al `worldport` y sin el se mandaria
  uno por muestra (veinte por segundo) mientras el primero esta de camino.
- Los enganches de soltar tecla (`MoveForwardStop` y companeros) se quedan como **RESPALDO**, por
  si la ultima muestra no llego a ver el agotamiento. **`TurnOrActionStop` queda FUERA a
  proposito** -- es el giro de camara con el raton, y girar la vista no es moverse.
- `WorldportSelf` es el UNICO comando de Harford que mueve a alguien. No emite nada sin coordenadas
  validas Y mapa (`GetInstanceInfo`, no `C_Map`, que devuelve el id de la interfaz).

## Economia de turno: accion, adicional y reaccion (2026-08-24)

`HarfordDnDConditions.Turn` lleva el presupuesto por turno. Vive **dentro del motor de condiciones**,
no en un modulo propio, porque ese modulo ya posee la frontera de turno (`OnTurnChanged`, duraciones
`*_turn_start`): un modulo aparte significaria un segundo listener y dos verdades sobre cuando
empieza un turno.

- **Estado efimero.** No se persiste ni viaja por red. Cada cliente cuenta lo suyo.
- **Se reinicia al EMPEZAR tu turno**, colgado de `HarfordTurnOrderAPI.RegisterMyTurnListener`, que
  ya trae su propio antirrepeticion (`lastTurnAlertKey`). En 5e la reaccion tambien vuelve al
  empezar tu turno, no al terminarlo, asi que un solo reinicio cubre los tres.
- **Sin orden de turnos queda INACTIVO**, no a cero. Fuera de combate no hay frontera que detectar y
  un contador congelado a `1/1` seria informacion falsa. `IsActive()` mira si
  `HarfordTurnOrderStore.entries` tiene alguna entrada.
- **INFORMA, NO BLOQUEA.** `Spend` gasta SIEMPRE y devuelve si habia presupuesto. Si el tracker va
  desincronizado o alguien juega sin el, impedir usar un rasgo dejaria al jugador sin su propio
  recurso en mitad de la escena. Misma linea que Barrera (manual) y que las reacciones que el
  cliente no puede resolver.
- **El coste se cobra en `HarfordDnDRolls.BroadcastAbility`**, que es el punto unico de activacion
  real; `opts.skipTurnCost = true` lo evita para rutas que no consumen accion.
- **Solo se cobra a los rasgos que DECLARAN `cast`.** No deducir el coste de `type = "accion"`: en
  5e "accion" es la categoria generica e incluye las adicionales, asi que adivinarlo daria un
  contador equivocado, que es peor que no tener contador. `cast` acepta `accion`,
  `accion_adicional` y `reaccion`.
- **Estado del dato (2026-08-24): 13 de 292 rasgos de nivel 1-6 declaran su coste, y los 13 son
  reacciones.** El contador funciona, pero hasta que se rellene `cast` solo se movera la reaccion.
  Ese dato debe nacer en la web `harfordweb`, que es la fuente canonica, no parchearse en el addon.
- El presupuesto base es 1 de cada. El flag `extraTurnAction` suma una accion (Impetu de Accion).
- Indicador en la banda inferior de la seccion Ataque (`HarfordDnDAttackUI.CreateTurnEconomyLabel`),
  anclado a `BOTTOMRIGHT`: las dos filas de botones llegan a -166 sobre 183 de panel, asi que la
  unica franja libre es la de abajo. Se refresca por el listener de condiciones, sin ticker.
- Diagnostico: `/harford debug run turnecon [reset|rasgos]`.

**Lo que esto NO cierra.** `Accion astuta` del Picaro no queda mecanizada por tener contador: bajo
el modelo de "1 accion adicional por turno para todos", ese rasgo no anade presupuesto, solo
restringe para que se puede usar, asi que sigue siendo informativo. `Embestida vil` del Cazador de
Demonios sigue bloqueada por el dado de Caos, que en el Libro 2 solo esta en una imagen.

## Golpes empoderados por el chi: el bit "magico" viaja (2026-08-24)

Una defensa calificada `"de ataques no magicos"` no debe frenar un golpe magico. La mitigacion la
resuelve el DEFENSOR, asi que el dato tiene que viajar con el dano.

- `HarfordDamageMitigation.ForTarget(unit, typeText, amount, opts)` acepta `opts.magical`.
  `ListMatchesType` ignora las entradas que casan el tipo **y** llevan calificador no magico
  (`"no magic"`, `"nonmagical"`, `"non magical"`, `"non-magical"`).
- Una resistencia SIN calificar sigue aplicandose a un golpe magico: es la regla correcta.
- El payload `DNDDMG` gana un CUARTO campo `M`. Es del GOLPE, no de un componente suelto, y es
  compatible en los dos sentidos: un cliente viejo manda 3 campos y aqui sale nil, y uno viejo que
  reciba 4 ignora el que no conoce.
- El rasgo declara `{ kind = "flag", flag = "magicalUnarmed" }`; `OpcionesGolpeMagico(def)` en
  `HarfordDnD.lua` solo lo aplica al arma `Desarmado`.

## Despliegue: `tools/desplegar.py`, no `cp` a mano (2026-08-24)

**El despliegue a Epsilon pasa SIEMPRE por `python tools/desplegar.py`.** Copiar con `cp` se
salta las comprobaciones y ya ha colado a Epsilon un fichero roto mas de una vez en una sola
sesion (una vez porque el script que lo generaba fallo y el `cp` posterior se ejecuto igual).

```
python tools/desplegar.py            # comprueba y despliega los 5 addons
python tools/desplegar.py --revisar  # solo comprueba
python tools/desplegar.py --forzar   # despliega con avisos (los ERRORES nunca se saltan)
```

Comprueba, y no copia NADA si algo falla:

1. **Compilacion con el 5.1 real** de cada `.lua` de los cinco addons.
2. **Margen de locales**: avisa por debajo de 25 libres de 200. Es lo unico que detecta que un
   fichero esta a punto de dejar de compilar; el `luac` 5.4 local NO lo ve.
3. **Codificacion**: UTF-8 sin BOM, LF, y mojibake por pares compuestos.
4. **Que cada `.lua` listado en un `.toc` exista.**

Tras copiar verifica por hash que origen y destino son identicos. Sale con codigo 1 si algo
falla, asi que sirve tal cual para un hook. Probado rompiendo un fichero a proposito: se niega
a desplegar y dice cual y por que.

Los addons desplegados son cinco: `Harford`, `HarfordAdmin`, `HarfordDebug` y los dos
LoadOnDemand `HarfordProfesiones` y `HarfordCompendio`.

## Comprobar Lua contra el 5.1 REAL, no contra el interprete local (2026-08-21)

El interprete instalado en la maquina es **Lua 5.4**, asi que `luac -p` sirve como detector
de sintaxis pero NO dice nada sobre los limites de 5.1, que es el que corre WoW.

`tools/codice/lua51.py` carga `lua51.dll` por ctypes y expone `compila(ruta)` y
`ejecuta(ruta)` con el compilador de 5.1 de verdad. Esta calibrado: reproduce los mensajes
exactos de "more than 200 local variables" y "more than 60 upvalues".

```
python -c "import sys; sys.path.insert(0,'tools/codice'); import lua51; print(lua51.compila('Harford/DnD/UI/HarfordDnD.lua'))"
```

**Limite medido para tablas de datos grandes** (probado, no deducido): una tabla con la forma
de `Data.lua` (registros anidados con campos con nombre) aguanta hasta **~65.000 entradas**;
a partir de ahi el compilador corta con `main function has more than 65536 constants`. Un
array plano de cadenas no tiene ese techo (300.000 pasan). NO fiarse del calculo teorico
sobre `MAXARG_Bx` (2^18): la barrera real que salta primero esta en 2^16 y va por entradas
del constructor, no por cadenas distintas.

## Verificacion

**La cadena de despliegue son seis barreras, y cada una nacio de un fallo que llego al cliente:**

| Paso | Que atrapa | Fallo que lo motivo |
|---|---|---|
| 1. Compilar con Lua 5.1 real | sintaxis, limite de 200 locales | `luac` local es 5.4 y no ve el limite |
| 2. Arnes de carga | errores de ejecucion al cargar, chunk truncado, rutas `/harford` sin registrar | un `end` de mas dejo 2600 lineas fuera del chunk |
| 3. `adelantadas.py` | locales usadas antes de declararse | `EquipmentGroups` reventaba al elegir equipo |
| 4. `datos_muertos.py` | campos que ningun motor lee | `rageReserveByLevel` no daba ni un punto de ira |
| 5. `referencias.py` | ids que apuntan a algo inexistente | ver su seccion |
| 6. `pruebas.py` | reglas ya probadas que se rompen | se desplego dos veces con una suite en rojo |

**Y lo que las suites NO pueden ver, porque corren fuera de WoW:** `/harford debug run verificar`
(`HarfordDebug/HarfordDebugVerify.lua`), seis grupos -- `iconos`, `estados`, `acciones`, `tira`,
`red`, `libro`.

- Los iconos se validan con `GetFileIDFromPath` y **se nombra cual falla**. Uno inventado sale VERDE
  en Epsilon y desde fuera no hay forma de saberlo: los ~1000 del catalogo se eligen a ciegas.
- **Lo que el cliente no puede comprobar solo se marca MANUAL y nunca cuenta como aprobado.** Una
  verificacion que se da por buena sin mirarla da una seguridad que no existe.
- No deja rastro en quien la ejecuta: el ciclo aplicar/ver/retirar solo prueba estados SIN aura
  (probar los otros lanzaria comandos de servidor), no toca los que ya estuvieran puestos, y la tira
  restaura lo que encontro. Cada grupo va en su `pcall`.
- Apoyo para montar la escena: `accion <id>` (por la MISMA ruta que el boton del Libro),
  `estadoen <cond> [quitar]` (ruta de red, al objetivo) y `tira [target|focus]`.

Para esta documentacion:

- Confirmar que `AGENTS.md` existe en la raiz del workspace.
- Confirmar que no se modifica codigo de los addons.
- Confirmar que las rutas y nombres de prefixes coinciden con los archivos actuales.

Para una futura implementacion en juego:

- Validar que `EpsilonLib.AddonCommands.Register` existe.
- Validar que un comando simple devuelve callback `success/messages`.
- Validar que Harford sigue sincronizando por sus prefixes propios sin mezclarse con `"Command"`.

## Entrenadores De Receta: La Identidad Es El Nombre De Catalogo (2026-08-21)

`HarfordProfessionTrainers` no concede profesiones: es una **tienda de recetas**. Cada entrenador
cubre un **rango** de una profesion (`Aprendiz`/`Oficial`/`Experto`/`Artesano`/`Maestro`) y ensena
todas las recetas cuyo `skillReq` cae en ese tramo; la lista se deriva sola, asi que anadir
recetas al catalogo no obliga a tocar entrenadores. `recipes` queda para casos sueltos y se suma.
El nivel de habilidad del jugador sigue subiendo libre hasta 300: el rango solo decide de quien
se aprende, no hasta donde se puede subir.

**NO HAY LISTA DE ENTRENADORES.** Existe uno por cada par (profesion, rango) que tenga recetas, y
`API.Get`/`API.GetAll` los construyen al vuelo. Del nombre `herreria_experto` salen la profesion,
el rango, las recetas que cubre y el nombre por defecto (`Instructor de <profesion>`), asi que
escribir el catalogo era escribir 75 veces lo que ya estaba en el nombre. `API.SplitId` parte por
el ULTIMO guion bajo, porque hay profesiones con guion dentro (`primeros_auxilios`), y solo acepta
la deduccion si el sufijo es un rango real: un entrenador con nombre propio
(`thorgas_yunquegris`) no se malinterpreta y solo existe si esta declarado con sus campos.

Lo unico hardcodeado es **`API.PLACED`**, que empieza vacio: los que YA existen en el mundo, con
su `name` y `zone` reales. Una entrada ahi cierra su rango. Se le deducen `profession`/`tier` en
`Declarados()` —una entrada escrita a mano es solo `{ id, name, zone }` y sin esos campos no
cubriria ninguna receta—. No reintroducir una lista de los 75: se derivan.

**La identidad es el nombre de catalogo (`id`), no el NPC.** Un entrenador NO apunta a un template
id: es el NPC quien declara en su gossip que nombre encarna, con
`HarfordTrainerAPI.BindTrainer("herreria_experto", { name?, zone? })`. Asi puede haber varios NPCs
para el mismo entrenador —uno por ciudad— o moverlo de sitio sin tocar el catalogo. `Bind` copia la
entrada antes de refinarla: **no muta `API.TRAINERS`**. `Teach(nombreDeCatalogo, receta)` y
`Get(nombreDeCatalogo)` van por lo mismo. No reintroducir `npc`, `GetByNpc` ni
`GetTrainerForNpc`: se retiraron justamente por esto.

**Aprendizaje explicito.** Al obtener una profesion solo se conocen las recetas iniciales
(`skillReq <= 1`, salvo `worldLearned`, o `starter = true`/`false` cuando se declare). TODA receta
restante se compra o aprende explicitamente y persiste como `HarfordProfessionsStore.learned[id]`.
Los 75 entrenadores deducidos existen aunque aun no haya NPC colocado: el gossip puede abrirlos por
ID. `API.PLACED` y los registros vivos solo aportan nombre/zona reales para mostrar al jugador; no
cambian que una receta requiera aprendizaje. Las recetas importadas sin `trainCost` reciben tarifa
base por rango: Aprendiz 50c, Oficial 500c, Experto 2500c, Artesano 7500c y Maestro 15000c.

**`skillReq = 0` es Aprendiz.** 37 recetas reales lo traen, y `tonumber(0) or 1` sigue siendo 0:
quedaban por debajo del minimo del primer rango y no caian en NINGUNO, asi que se quedaban sin
entrenador. El helper `SkillReq` lo acota a 1. Verificado contra los datos reales: 2309 de 2309
recetas tienen entrenador que las cubra.

`API.Define` sigue existiendo para un entrenador que NO este en el catalogo, y rechaza rango
desconocido, profesion ajena y cobertura vacia (un NPC mudo no se registra).

**Nada de esto toca SavedVariables**: los entrenadores se deducen, `API.PLACED` vive en el Lua y
el registro en vivo (`vivos`) muere con el `/reload`. Lo unico que persiste al aprender es `HarfordProfessionsStore.learned[id]
= true`, un booleano por receta realmente aprendida.

Pruebas: `/harford debug run entrenador` resume por profesion, `entrenador <profesion>` desglosa
sus cinco rangos, y `colocar`/`quitar`/`ensenar` recorren el flujo entero sin NPCs puestos.

## Ventana De Entrenador: La Abre El Gossip Con Solo El ID (2026-08-21)

`HarfordProfessionTrainerUI` es lo que abre el gossip del NPC. Una opcion "lua" del gossip llama a
`HarfordTrainerAPI.OpenTrainer("herreria_experto")` y esa API monta la ventana entera desde ese
id: titulo, retrato de la profesion, barra de habilidad, lista de recetas del rango y detalle. El
NPC NO pasa recetas, precios ni rango: solo dice quien es. Todo lo demas se deduce.

Reutiliza `HarfordProfessionsCraftSkin.Build` (replica del TradeSkillFrame nativo, generada desde la sonda)
en vez de inventar arte para un `ClassTrainerFrame` que no esta capturado. Si algun dia se captura
el nativo, se regenera un skin propio; no meter rutas de textura a ojo mientras tanto.

**Las condiciones las decide `Teach`, no la ventana.** La UI las repite solo para pintar el boton.
`API.Teach` comprueba cobertura del rango, profesion conocida, **requisito de habilidad** y si ya
la sabes. Ese requisito faltaba y se podia aprender una receta de 300 con habilidad 1.

**Comprar no es aprender optimistamente.** `recipe.trainCost` se expresa en cobre y la ventana
lo muestra tanto en la fila como en el detalle. `API.Purchase` comprueba el dinero local con
`GetMoney()`, revalida con `Teach`, descuenta mediante `HarfordServerActions.TakeMoney` y solo
marca la receta como aprendida cuando el callback de Epsilon confirma el comando. Si el cobro
falla o no hay dinero, la receta sigue sin aprender. No llamar `LearnRecipe` directamente desde
la UI ni volver a construir `modify money` fuera del wrapper compartido.

**`Teach` NO exige que el entrenador este colocado.** Son cosas distintas: `colocado` decide si ese
rango deja de venir con el nivel de habilidad para TODO el mundo (viene de `API.PLACED`, va en el
addon, igual para todos, sin red ni SavedVariables); poder aprender depende de estar delante del
NPC, que es lo que significa que su gossip te haya abierto la ventana. Atarlas hacia que el gossip
abriese la ventana y `Aprender` fallase con "ese entrenador aun no existe en el mundo" delante del
NPC.

**`IsRecipeLearned` es la unica pregunta de disponibilidad.** Devuelve `true` para una receta
inicial o para una entrada guardada en `learned`; `HasLearnedRecipe` significa exclusivamente que
fue aprendida y persistida de forma explicita. La ventana de recetas y la de entrenador deben usar
`IsRecipeLearned` para no vender ni clasificar las iniciales como desconocidas.

Prueba sin NPC: `/harford debug run entrenador abrir herreria_experto`.

## Economia Temporal De Oro WoW (2026-08-22)

`HarfordDnDEconomy` conserva un saldo propio en cobre dentro de
`HarfordDnDPersistStore.profiles[name]._economy`, pero el dinero visible sigue siendo el oro
nativo de WoW. Es una capa temporal hasta migrar a items fisicos de moneda.

- **Activacion estricta:** no crea saldo, no observa `PLAYER_MONEY` y no ejecuta `modify money` para
  personajes sin una ficha terminada por `HarfordCharacterCreation.Apply`. Importar/leer TRP3 o
  abrir una ficha antigua no activa la economia por si mismo. **Excepcion guiada para fichas
  heredadas:** al entrar al mundo, si hay progresion Harford valida pero no `_economy.initialized`,
  aparece una oferta unica por runtime. `Ahora no` no persiste saldo ni vuelve a insistir hasta
  reload/login; `Configurar saldo` abre oro/plata/cobre con iconos. La suma de primera clase +
  trasfondo se rellena solo como sugerencia editable y, al aceptar, se aplica UNA vez mediante
  `InitializeExistingSheet`; `0` sigue siendo un saldo inicial valido y distinto de no inicializado.
- **Creacion:** la primera creacion valida tira la riqueza inicial de la primera clase segun la
  tabla de `Warcraft 5º Edicion` y suma la bolsa declarada del trasfondo. El resultado queda
  guardado y ajusta el oro nativo al importe resultante; repetir la creacion despues no reinicia
  ni vuelve a otorgar dinero.
- **Carga:** al entrar al mundo, si el perfil ya tiene `_economy.initialized`, se ignoran los
  cambios iniciales de Epsilon y se reconcilia el oro nativo con el saldo persistido. Asi los
  millones iniciales no contaminan una ficha ya creada.
- **Saldo autoritativo y cambios posteriores:** fuera de esa ventana, `HarfordDnDEconomy` conserva
  el saldo persistido como autoridad y `GetBalance` nunca adopta `GetMoney()` por su cuenta.
  `PLAYER_MONEY` solo confirma un destino pendiente que haya iniciado `Spend`/`Grant` o una
  transaccion nativa previamente autorizada; cualquier otro cambio, incluido `.mod`/`.modify money`
  manual, se reconcilia de vuelta al saldo Harford y no contamina SavedVariables.
- **Merchant Epsilon:** `Epsilon_Merchant` sigue enviando sus propios comandos de dinero. Harford
  engancha sus acciones de compra y venta y autoriza una unica variacion exacta antes de aceptar
  `PLAYER_MONEY`; esa variacion actualiza a la vez el oro nativo y el saldo Harford. No usar el
  mero estado del frame abierto como permiso: un `.mod money` manual con el merchant visible debe
  seguir revirtiendose.
- **Comercio entre jugadores:** al aceptar ambos lados, Harford calcula el delta neto exacto
  (`oro recibido - oro ofrecido`) usando `GetTargetTradeMoney` y `GetPlayerTradeMoney`. Solo ese
  saldo se acepta durante la transaccion; cancelar o abrir Comercio no autoriza cambios de dinero.
- **Correo:** `SendMail` arma una transaccion de salida temporal que se confirma solo al observar el
  saldo final alrededor de `MAIL_SEND_SUCCESS` (el orden frente a `PLAYER_MONEY` no es estable en
  Epsilon). Si el exito llega primero, conserva la autorizacion durante toda la ventana de 5 s y
  nunca reconcilia al saldo previo entre ambos eventos; incluye el porte real que aplique el
  cliente. `TakeInboxMoney` acepta exactamente el dinero adjunto y retirar un adjunto contra
  reembolso acepta exactamente su COD. Abrir el buzon, un correo fallido o un comando manual no
  modifica el saldo Harford.
- **Puerta unica:** usar `HarfordDnDEconomy.CanAfford`, `Spend` y `Grant`. Trainers, recompensas
  de misiones y bote de contratos pasan por ella. El trainer solo aprende tras confirmar el cobro;
  el bote de contrato se revierte si la entrega de dinero falla.

Puntos de datos o presentacion que NO cobran ni entregan por si mismos:

- `HarfordProfesiones.lua`: `trainCost` es el precio declarativo de una receta.
- `HarfordQuests` y `HarfordWorldQuests`: `rewards.money = { gold, silver, copper }`,
  `RewardMoneyCopper` y los helpers de iconos/formato solo serializan o pintan el importe.
- `HarfordProfessionTrainerUI.FormatMoney` solo pinta el precio.

Plan al introducir moneda fisica: conservar esta API y sustituir solo su adaptador nativo. La
reserva/confirmacion debe seguir siendo asincrona: no marcar una receta aprendida ni una
recompensa entregada hasta que el inventario confirme la operacion. Los IDs de los items de
moneda aun no estan decididos.

**Limite de inspeccion:** `GetMoney()` solo conoce el dinero del cliente local. No existe una API
de cliente que lea de forma autoritativa el oro de otro jugador. Un futuro informe voluntario por
red podria servir al DM como diagnostico, pero nunca como saldo fiable ni como base para un cobro.


## Poda De Tablas Vacias En La Ficha (2026-08-22)

`_progression` escribia siete tablas vacias por perfil (`classLevels`, `featureStates`, `choices`,
`feats`, `activeStates`, `spellSlots`, `importedProficiencies` con sus seis hijas). Con 16
perfiles reales eran 196 tablas y el 5,5% del fichero de SavedVariables.

`HarfordDnDStore.PruneEmptyProgressionTables` las quita, y es **LISTA BLANCA a proposito**: cada
clave de la lista la recrea `HarfordDnDProgression.Migrate` al leer, asi que quitarla no pierde
nada. Con lista negra —"cualquier tabla vacia"— una clave futura en la que vacio SIGNIFIQUE algo
distinto de ausente se podaria sola y en silencio. No ampliar la lista sin comprobar la ruta de
recreacion de la clave nueva.

**Se poda en `PLAYER_LOGOUT`, no solo al cargar.** Podar al arrancar no sirve de nada: `Get` pasa
por `Migrate`, que vuelve a escribir las tablas vacias EN la tabla persistida, de modo que
reaparecen en cuanto alguien abre la ficha y eso es lo que WoW acaba serializando. La poda de
carga se mantiene porque limpia perfiles fantasma; la de salida es la que llega al disco.

No se podan las tablas vacias de contratos ni de otros modulos: alli no hay una ruta de
recreacion equivalente que garantice que no se pierde informacion.


## Recompensas Compartidas De Mision: Se Cobran Al Completar (2026-08-22)

La parte COMPARTIDA (reputacion y XP) se reclama en `FireCompleted`, que es el punto por el que
pasan las DOS transiciones a completada —`RecomputeCompletion` (ultimo objetivo hecho) y
`MarkComplete` (cierre del DM)— y dispara una sola vez. El listener vive al final de
`HarfordQuests.lua`.

Antes solo la reclamaba el receptor de `QDONE`, asi que una mision cerrada POR OBJETIVOS —el caso
normal— dejaba al grupo entero sin nada: el receptor de `QOBJ` auto-completa pero no reclamaba, y
en el DM la unica ruta que concedia exigia ademas tener la mision aceptada en su propio personaje,
que es justo lo que el comentario de al lado advierte que puede no pasar.

Estaba tapado porque `QOBJ` no aplicaba nada (ver la trampa del `and` mas arriba). Al arreglarlo,
el auto-completado empezo a ocurrir de verdad y esto quedo al descubierto: **arreglar un bug puede
destapar el siguiente, y conviene volver a mirar lo que dependia de la ruta muerta.**

`ClaimRewards` ignora oro y objetos —son individuales, los cobra quien entrega en el NPC— y lleva
recibo por componente, asi que reclamar de mas no concede de mas. No anadir reclamaciones sueltas
en otras rutas: si aparece una nueva forma de completar, que pase por `FireCompleted`.


## Fabricar: Color, Subida, Pifia Y Rojo (2026-08-22)

**Una sola funcion decide color Y subida.** `HarfordProfessions.DifficultyColor` devuelve r,g,b
mas la clave del escalon, y `SkillGainFor` traduce esa clave a puntos: rojo 5, naranja 3,
amarillo 2, verde 1, gris 0. Antes el gris de la subida era `skillReq + 100` y el del color
margen 70, asi que habia recetas que se veian grises y seguian subiendo. No volver a separar los
dos umbrales.

**Solo sube al COMPLETAR con exito.** `SkillUp` va despues de todos los `return` de fallo.

**La pifia (d20 == 1) gasta los materiales**; un fallo normal no. Es el unico desenlace en el que
se pierde algo sin obtener nada, y se anuncia aparte diciendo que se perdio.

**El rojo es jugable.** Estar por debajo del requisito ya NO impide fabricar: se tira contra
`API.CraftDC`, que devuelve 20 cuando el escalon es `imposible` y la CD propia de la receta en el
resto. Eso es lo que hace alcanzable el +5.

**Aprender lo decide el RANGO, no el `skillReq` exacto.** Siendo Aprendiz se pueden aprender
TODAS las de Aprendiz aunque alguna salga en rojo. Comparar contra el requisito de cada receta
dejaba media lista del entrenador fuera de alcance justo despues de pagarle por llegar a su rango.

**La animacion de artesano hay que devolverla.** `.mod anim 69` al empezar a fundir NO se corta
sola: sin `.mod anim 13` al terminar, el personaje se queda martilleando para siempre. Va en
`StopQueue` y no en `CancelCast`, porque StopQueue cubre el final de la cola, la interrupcion y el
cierre de la ventana; en CancelCast parpadearia 69-13-69 entre piezas encadenadas.

**Pendiente**: un cooldown de fabricacion POR PROFESION, para que no se repita el intento de la
misma pocion. Todavia no implementado; `HarfordProfessionsStore.nodeCooldowns` es el patron
hermano que ya existe para nodos de recoleccion.

## Mecanizacion de rasgos de clase: campos declarativos

Estado por clase y decisiones pendientes en `ESTADO_CLASES.md`. Conjuros que el
manual cita y no estan en el compendio, mas equivalencias de nombre resueltas,
en `CONJUROS_PENDIENTES.md`.

Antes de anadir un `actionKind` nuevo, comprobar si basta uno de estos:

- **`spendResourceOnAnnounce`**: sin esta bandera, `resourceKey`/`resourceCost`
  se MUESTRAN pero no se cobran. Faltaba en 10 rasgos de 6 clases distintas
  (Momentum, Disparo conmocionante, Corte de ala, Congelacion cerebral, Palma
  aturdidora, Oracion de curacion y cuatro del Brujo): el boton anunciaba la
  habilidad y no descontaba nada. Las OPCIONES de Palabra de Poder no la llevan;
  esas se cobran por `SpendPowerWord`.
- **`uses.values`**: maximo de usos por nivel de clase, como `resourceMax`.
- **`usesFrom`**: el rasgo consume la reserva de OTRO rasgo (las Maldiciones
  gastan usos de Corrupcion). Tocar los SEIS puntos del panel que miran
  `feature.uses`; si se olvida uno, la habilidad se anuncia y no descuenta.
- **`usesArePool`**: marca un rasgo como reserva y no como accion. Sin el, el
  clasificador lo hace activable (`todo rasgo con usos es activable`) y pulsarlo
  quema un uso sin invocar nada.
- **`expandedSpells`** (en la SUBCLASE): Listas Ampliadas de Conjuros. Hay que
  pasarlos a CUATRO sitios: siembra, dialogo, y **el podado** de
  `PersistSpellPicks`; sin lo ultimo, deseleccionar deja el conjuro pegado.
- **`grantedSpells`**: conjuros concedidos que NO cuentan contra los conocidos.
  Se aplican al FINAL de `PersistSpellPicks`: suelen ser conjuros de la propia
  clase y el podado los borraria.

**Nombres de conjuros**: el manual y el compendio divergen (*producir llama* ->
`Crear llama`, *romper* -> `Hacer anicos`, *mandato* -> `Orden imperiosa`).
Buscar por NIVEL y EFECTO, nunca por parecido de nombre: `Rayo de hechiceria`
parece *rayo del caos* y es *witch bolt*.

## Libro de clases separado por fichero

Las 12 clases viven en `Harford/DnD/Data/Classes/<Clase>.lua`. El nucleo
`HarfordDnDBook.lua` aporta la API y los helpers, y arranca con `API.CLASSES = {}`;
cada fichero de clase se APILA con `API.CLASSES[#API.CLASSES + 1] = { ... }`.

- **El orden lo fija el `.toc`**: nucleo -> las 12 clases -> `HarfordDnDBookDerived.lua`.
- Los helpers que usan los datos (`ASI`, `WeaponProfEffects`, `ManeuverEffects`) estan
  en la API, no como locales: un fichero de clase no ve los locales del nucleo. Cada
  fichero los aliasa en su cabecera.
- **Un generador de rasgos derivados de UNA clase va en SU fichero**, tras la tabla.
  Los que recorren TODAS las clases (Competencias de clase) van en `HarfordDnDBookDerived.lua`,
  que carga el ultimo porque necesita las 12 apiladas.

**El indice de `GetClass` se invalida por numero de clases.** Antes se cacheaba a la
primera consulta y no volvia a construirse. Con un solo fichero daba igual; separado,
el generador de la 8.ª clase (Sacerdote) llamaba a `GetClass` y CONGELABA el indice con
8 clases: Chaman, Brujo y Guerrero se apilaban despues y sus generadores recibian `nil`,
recorrian una lista vacia y no creaban NINGUN rasgo. **Sin error**: se perdieron 25 rasgos
generados en silencio. Si se toca `EnsureIndex`, mantener la invalidacion.

Al mover clases, verificar con una HUELLA: volcar `GetClasses()` con clases, subclases,
ids de rasgo y nivel antes y despues, y comparar. La compilacion no detecta esto.

## Repaso de las 12 clases contra el manual

Estado por clase, errores de regla corregidos y bloqueos: `ESTADO_CLASES.md`.
Equivalencias de nombre de conjuro y los que faltan: `CONJUROS_PENDIENTES.md`.

Tres fallos aparecieron en casi todas las clases; conviene buscarlos al tocar una:

1. **Sub-rasgos nombrados que no existen.** La clase declara un recurso (chi,
   enfoque, fragmentos, puntos de fe) y NINGUNA forma de gastarlo, aunque su
   descripcion los nombre. Comprobar que cada caracteristica citada existe como rasgo.
2. **Catalogos como muro de texto, y TRUNCADOS.** Las Maldiciones del Brujo tenian
   2 de 8 y las Trampas del Cazador 3 de 8, cortadas a media frase. Si un rasgo
   `informativo` enumera opciones en su descripcion, contarlas contra el manual.
3. **Nombres de conjuro divergentes.** El manual y el compendio traducen distinto.
   Buscar por NIVEL y EFECTO, nunca por parecido: `Rayo de hechiceria` parece
   *rayo del caos* y es *witch bolt*; `Causar miedo` es nivel 1 y *miedo* es nivel 3.

**Verificar cargando el libro, no leyendo el fichero.** Un grep sobre una linea larga
miente: mostro 2 opciones de metamagia donde habia 7, y me hizo duplicar 4 estilos de
combate del Caballero de la Muerte que ya existian. Los `uses` van entre la descripcion
y `effects`, asi que un patron que espere `description..., effects = {}` no los ve y
parece que faltan.

**El bloqueo mas rentable son las criaturas acompanantes**: cuatro clases (Brujo,
Cazador, Caballero de la Muerte y Mago) declaran una con la MISMA forma -bloque de
estadisticas propio, iniciativa compartida con turno posterior al tuyo, y solo accion
de Esquivar salvo que gastes tu accion en ordenarle otra-. Ninguna existe.

## Los tres fallos del repaso de clases, ya automatizados (2026-08-25)

El repaso a mano no se repite solo, asi que los tres patrones estan en
`tools/pruebas/clases_manual.lua`, que **carga el libro de verdad** en el orden del `.toc` -- nunca
con grep, por el motivo que ya avisa este fichero.

| Patron | Como se comprueba |
|---|---|
| Recurso declarado sin forma de gastarlo | cinco vias de gasto: `resourceKey`, `conditionalWeaponDamage`, `energyManeuver`, `poolHeal` y `AdjustResourceCurrent(clave, -n)` desde el motor |
| Catalogo cortado a media frase | descripciones largas que acaban en coma, punto y coma, " y" o " o" |
| Conjuro concedido que no existe | ids (`grantedSpells`, `spellGrants.ids`, `cantripSpellIds`) contra los del compendio, y `expandedSpells` por NOMBRE visible |

Mas los datos duros: dado de golpe de cada clase y que todas den exactamente dos salvaciones.

**Cuidado con las estructuras, que no estan donde parece.** `API.CLASSES` es una LISTA, no un mapa
por id: cada clase trae su `id` dentro. Y `expandedSpells` cuelga de la SUBCLASE, no de un rasgo --
buscarla en los rasgos no da error, da "0 sin casar" mirando una lista vacia, que es peor que no
comprobar. Las dos cosas me costaron una pasada.

**Los dados de golpe son los de WARCRAFT, no los de D&D vanilla.** Sacerdote es **d6** y Cazador de
Demonios **d8** (no d8 y d10). Escribi los vanilla y marque como fallo dos datos que estaban BIEN.
La prueba los lee del manual cuando puede abrirlo; en Windows el nombre lleva acentos y el
`io.open` de Lua no lo abre, asi que usa una copia contrastada y **dice** que la esta usando.

## Decisiones de mesa que DIVERGEN del manual (leer antes de cualquier auditoria de reglas)

Estaban repartidas entre este fichero, `CLAUDE.md` y comentarios de codigo. Se juntan aqui porque
un cotejo mecanico contra el manual las marca como "errores" y **no lo son**: cambiarlas rompe
equilibrio ya acordado. Si una auditoria futura las senala, la respuesta es esta seccion.

| Tema | Manual | Harford | Por que |
|---|---|---|---|
| Riqueza inicial | `4d4 x 10 po`, `5d4 x 10`... | `multiplier = 1` (la decima parte) | En 5e el oro es la ALTERNATIVA al equipo inicial. Harford concede las dos cosas, asi que el oro va reducido para compensar. |
| Medio lanzador | Multiclase usa `floor(nivel/2)` | `ceil(nivel/2)`, **sin lanzar hasta nivel 2** | El redondeo hacia arriba es decision de mesa; la puerta de nivel 2 la manda el compendio. |
| Brujo (magia de pacto) | Tabla de pacto en la clase; la regla de Mana **no lo menciona** | `casterType = "pact"`: **pacto en modo espacios, completo en modo mana** | Su tabla de clase es inequivoca (1/2/2/2/2/2 ranuras, todas de 1.o/1.o/2.o/2.o/3.o/3.o), pero la regla variante de Mana no lista al brujo en ninguna de sus dos listas, asi que ahi se le da el pool de un completo. |
| Lanzador de tercio | Tabla propia del Truhan Arcano | `ceil(nivel/3)`, **sin lanzar hasta nivel 3** | Reproduce la tabla dentro del alcance 1-6 y es el mismo criterio que ya usaba `HarfordCompendioCore`. |
| Coste de conjuros | Ranuras | `HarfordConfig.spell_cost_mode`, **mana por defecto** | Regla variante de la Parte 3. `slots` es la alternativa, elegida por el usuario y global. |
| Nombres de conjuro | Los del manual | **Los del compendio** | El compendio es la fuente canonica. Ver `CONJUROS_PENDIENTES.md` para las equivalencias resueltas. |
| Alcance | Niveles 1-20 | **Validado 1-6, conjuros 0-4** | No hay tope tecnico: el Libro lleva 96 rasgos de nivel 7-20 y las tablas llegan a 20, pero solo 1-6 esta auditado. |
| Fuente de datos | La ficha TRP3 | TRP3 es INDICE, el Libro es la FUENTE | TRP3 solo identifica clase/nivel/subclase/elecciones; descripciones y efectos salen del Libro. |

**Quien manda cuando dos motores discrepan: el COMPENDIO.** Es quien decide que conjuros puede elegir el personaje, asi que `HarfordDnDMana` se alinea con el, no al reves. Ya se resolvieron dos desajustes de este tipo, y los dos apuntaban al mismo sitio: el Picaro Sutileza tenia 0 ranuras mientras el picker le dejaba elegir conjuros (le faltaba `casterType = "third"`), y el medio lanzador de nivel 1 tenia una ranura para la que el picker no ofrecia ningun conjuro (le faltaba la puerta de nivel 2). Las puertas viven ahora en `CasterContribution` y son explicitas: medio no aporta antes de nivel 2, tercio antes de nivel 3. Al anadir un tipo de lanzador nuevo, comprobar los dos motores con la misma tabla. Comprobado para el pacto: el nivel de ranura del brujo (1,1,2,2,3,3) coincide con el `ceil(nivel/2)` que le aplica el compendio en TODO el rango 1-6 -- y hasta el 10 --, asi que no hay desajuste. Divergen a partir del nivel 11, fuera de alcance: la tabla de pacto se queda en ranuras de 5.o y el compendio subiria a 6.o. No "simplificar" una en la otra por eso.

**Divergencias que NO son decisiones y si hay que corregir** cuando aparezcan: efectos declarativos
que apuntan a ids inexistentes, conjuros prometidos que no estan en el compendio, rasgos con coste
de recurso que no lo cobran, y escalones de nivel que faltan (el Druida solo concedia el par de
nivel 3 de sus conjuros de camino, faltando el de nivel 5). Esas si son fallos.
