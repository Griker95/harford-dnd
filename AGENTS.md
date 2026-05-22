# Guia Para Agentes - Proyecto Harford

Este archivo documenta el contexto tecnico que debe recordar cualquier agente que trabaje en este repo. Es una guia viva: actualizala cuando se confirme nueva informacion del entorno Epsilon/Shadowlands o cambie la arquitectura de los addons.

## Repositorio Y Colaboracion

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
- Convenciones:
  - Codigo, comentarios y documentacion operativa en espanol.
  - No crear archivos nuevos sin peticion explicita.
  - Diagnosticos temporales siempre en `HarfordDebug.RegisterCommand`, nunca en modulos de gameplay.
  - Si una solucion se descarta por pruebas en juego, documentarla aqui como enfoque fallido.
  - No tocar ZIP/RAR/backups del workspace salvo peticion explicita.

## Proyecto Y Entorno

El workspace contiene dos addons:

- `Harford`: addon principal de ficha DnD, recursos, loot y turnos.
- `HarfordAdmin`: addon opcional/admin, dependiente de `Harford`.

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

Transformacion incremental:

- `Harford` es el core compartido para jugadores y DM.
- `HarfordAdmin` es la capa de autoridad DM/Admin, herramientas avanzadas y futuras acciones de NPC/enemigos.
- Prioridad arquitectonica para el futuro: `HarfordAdmin` ejecuta herramientas DM y `Harford` actua como receptor/aplicador/renderizador. Si una feature crea, edita, comparte, ajusta a otros, ejecuta comandos DM o abre prompts de maestro, debe vivir en `HarfordAdmin`. `Harford` debe quedarse con datos, APIs pasivas, recepcion de senales, aplicacion de snapshots y UI normal de jugador.
- Los comandos de servidor no son exclusivos de `HarfordAdmin`: algunas funciones del core, como loot o auras de UI, tambien deben poder enviar comandos seguros.
- Las dependencias externas (`EpsilonLib`, `ARC`, TRP3) son opcionales y deben comprobarse en runtime.

Arbol logico:

```text
Harford/
  HarfordSync.lua             -- transporte addon, serializacion, canales, prefixes
  HarfordDebug.lua            -- logging/debug
  HarfordConfig.lua           -- configuracion del addon: HarfordConfig.Get/Set, panel Interface Options, /hconfig
  HarfordAuthority.lua        -- permisos: Admin addon, rango phase y modo DM
  HarfordEpsilonCommands.lua  -- wrapper compartido para comandos Epsilon/ARC
  HarfordServerActions.lua    -- acciones servidor validadas sobre Epsilon/ARC
  HarfordTRP3.lua             -- lectura segura de perfiles TRP3 jugador/companion/NPC Epsilon
  HarfordUnitFrames.lua       -- overlays TRP3/recursos Harford sobre PlayerFrame/TargetFrame
  HarfordNamePlates.lua       -- overlays DnD sobre nameplates nativos/KuiNameplates
  HarfordDnDResources.lua     -- recursos DnD, cache remota, claves
  HarfordDnDStore.lua         -- persistencia de fichas/perfiles
  HarfordDnDComm.lua          -- recepcion DND5EARC y handlers cliente-cliente
  HarfordLoot.lua             -- loot frame, datos/sync de loot y uso normal de loot
  HarfordDnD.lua              -- UI ficha, tiradas, recursos
  HarfordTurns.lua            -- tracker turnos, HP/mana, sync de turnos

HarfordAdmin/
  HarfordAdmin.lua            -- bootstrap, slash commands, API admin existente
  HarfordAdminNPC.lua           -- acciones admin basicas sobre target/NPC/enemigo
  HarfordAdminLoot.lua          -- editor DM para cargar/editar/compartir tablas de loot
  HarfordAdminUnitMenu.lua      -- menu contextual DM en PlayerFrame/TargetFrame
  HarfordReputationAdmin.lua    -- panel GM de gestion de reputaciones: crear/editar/ordenar/renombrar grupos
  HarfordAdminPanel.lua         -- futuro: panel DM central si hace falta
```

Contrato `HarfordEpsilonCommands`:

- `HarfordEpsilonCommands.Send(command, opts)`: puerta compartida para comandos servidor.
- Si `opts.callback` existe, usa `EpsilonLib.AddonCommands` para recibir `success/messages`.
- Si no hay callback, usa `ARC.CMD` / `ARC.COMM` para comandos fire-and-forget cuando este disponible.
- Puede usar `EpsilonLib.AddonCommands` como fallback si `ARC` no esta disponible.
- `HarfordEpsilonCommands.SendChain(commands, callback, opts)` usa `EpsilonLib.AddonCommands.SendChain`.
- `HarfordEpsilonCommands.GetStatus(addonName)` devuelve disponibilidad de `EpsilonLib`, registro AddonCommands y `ARC`.
- Usar `opts.addonName = "HarfordAdmin"` para comandos iniciados por la capa admin.
- Nunca ejecutar texto arbitrario recibido de otros clientes como comando servidor.

Contrato `HarfordServerActions`:

- Vive en `Harford/HarfordServerActions.lua`.
- Es la capa preferida para gameplay y UI cuando necesiten comandos servidor.
- Construye comandos Epsilon desde funciones validadas, no desde strings sueltos repartidos por otros modulos.
- Funciones actuales:
  - `HarfordServerActions.GiveItem(itemId, quantity, opts)`: envia `additem <itemId> <quantity>`.
  - `HarfordServerActions.ApplyAura(spellId, target, opts)`: envia `aura <spellId> <target>`.
  - `HarfordServerActions.RemoveAura(spellId, target, opts)`: envia `unaura <spellId> <target>`.
  - `HarfordServerActions.GetPhaseInfo(callback, opts)`: envia `phase info addon` con callback via EpsilonLib.
  - `HarfordServerActions.SetNpcHealthDelta(delta, opts)`: envia `npc set health +N/-N`, validando delta numerico y limite absoluto.
  - `HarfordServerActions.SetNpcAura(spellId, opts)`: envia `npc set aura <spellId>`, validando `spellId`. Uso preferente para auras sobre NPC target desde herramientas DM.
  - `HarfordServerActions.SetPhaseNpcFaction(factionId, opts)`: envia `ph f n fac <FactionID>` para asignar al NPC target la faccion Epsilon configurada en una reputacion Harford. El comando se envia sin punto inicial por el wrapper.
  - `HarfordServerActions.SendRawDebug(command, callback, opts)`: comando raw solo si `HarfordDebug` esta activo.
- `Harford/HarfordLoot.lua` debe usar esta capa para `additem`, `aura 224063 self` y `unaura 224063 self`.
- Nuevas features DM/NPC deberian anadir acciones aqui antes de crear UI.

Contrato `HarfordLoot`:

- Vive en `Harford/HarfordLoot.lua`.
- Datos persistentes:
  - `HarfordLootLootRegistry[npcId] = { {itemId, chance, min, max}, ... }` para loot especifico por criatura base. `npcId` se extrae de `UnitGUID("target")` con `select(6, strsplit("-", guid))`.
  - `HarfordLootGlobalLootRegistry = { {itemId, chance, min, max}, ... }` para loot global que se tira en todas las criaturas validas.
  - `HarfordLootTaggedCreatureRegistry[guid]` guarda loot ya resuelto para una instancia concreta y se sincroniza por `HARFORDLOOT`.
  - `HarfordLootConfigStore` guarda la configuracion serializada por `HARFORDCFG`.
- `HarfordLootAPI.GetLootEntries(creatureId, createIfMissing)` no debe crear tablas vacias salvo que `createIfMissing == true`. Motivo: una tabla vacia para un NPC cuenta como "tiene registro" y permite que el loot global se tire para ese NPC; solo debe crearse al guardar una entrada real.
- El core `HarfordLoot.lua` no registra slash ni crea editor de carga/edicion. `Cargar loot Harford` es herramienta DM y vive en `HarfordAdminLoot`.
- Generacion de loot:
  - Al cambiar target, si el target existe, esta muerto, esta en rango de `IsItemInRange(37727)` y tiene aura `"Loot Room Completion Area"`, Harford resuelve loot desde la tabla del `npcId` + loot global.
  - Cada entrada tira `random(100) <= chance`; la cantidad se calcula con `random(minAmount, maxAmount)`.
  - El resultado se guarda por GUID en `HarfordLootTaggedCreatureRegistry` y se sincroniza por `HARFORDLOOT` para que no se rerollee al volver a targetear.
  - Al lotear un item, `HarfordServerActions.GiveItem(itemId, quantity)` envia `additem` y marca esa entrada como consumida.
- No usar `OnUpdate` permanente para cerrar/mantener la ventana. El cierre al moverse usa `PLAYER_STARTED_MOVING`; el tooltip de items puede usar `OnUpdate` solo mientras el raton esta sobre el boton y debe limpiarse en `OnLeave`.

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
- `HarfordReputation.GetPlayerPoints(playerKey, factionId)` → `points, repEntry`. Si no tiene rep propia, hereda del gremio.
- `HarfordReputation.SetPlayerPoints(playerKey, factionId, points, opts)` → solo si `CanEdit()` o `opts.fromSync=true`.
- `HarfordReputation.IsAtWarPoints(points)` → `true` desde `Hostil` hacia abajo (`points <= -3001`: Hostil/Odiado). Al subir por encima de Hostil (`Adverso`, `Neutral` o mejor) debe quitarse. `SetPlayerPoints` actualiza automaticamente `repEntry.atWar` en reputacion de jugador/gremio; sync tambien lo reconstruye al recibir puntos.
- Visual `At War` en `HarfordReputationUI`: no basta con guardar `repEntry.atWar`. La fila debe mostrar dos texturas nativas `AtWarHighlight1/2` con `Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar`, alpha ~0.20, replicando `ReputationBarXReputationBarAtWarHighlight1/2` del `FrameDump`. Deben ir embebidas en el marco de la fila: `AtWarHighlight1` empieza en `indent+3` (donde empieza el marco de esa fila) y se une a `AtWarHighlight2`, que cierra en `TOPRIGHT row -1,-2`. Usar capa `OVERLAY -2`: `ARTWORK -1` queda tapado por el marco/fondo, mientras `OVERLAY -2` sigue por debajo del texto (`Name`/`FactionStanding`) y no flota por encima de la seleccion. Se muestran solo en filas de faccion con `atWar=true`; headers las ocultan.
- `HarfordReputation.AdjustTarget(factionId, delta)` → ajusta al target actual + hereda gremio.
- `HarfordReputation.CanEdit()` -> requiere `HarfordAdmin` cargado (`HarfordAuthority.HasAdminAddon() == true`) y `.ph dm` activo (`HarfordAuthority.IsDMMode() == true`). El core Harford recibe/aplica sync, pero no debe editar estructura/puntos sin la capa admin.
- `HarfordReputation.GetCurrentPlayerPoints(factionId)` → atajo al jugador local. En el panel principal, un jugador normal ve siempre su reputacion local. Si `HarfordAdmin` esta cargado, el modo DM esta activo y el target es un jugador, el panel puede mostrar las reputaciones de ese target para trabajo admin.
- En modo DM con target jugador, el panel principal **no debe leer los puntos del target desde el store local del DM**. Debe pedir una vista remota al cliente objetivo mediante `HarfordReputationSync.RequestPlayerSnapshot(playerKey)` y mostrar esa cache de solo lectura. Si aun no ha llegado la respuesta, mostrar estructura local/0 temporalmente antes que mezclar valores propios del DM.
- `HarfordReputation.GetUnitFactionRelationship(unit)` → `factionId, points, rank, rankColor` si la unidad tiene NPC link.
- `HarfordReputation.EnsureStore()` → inicializa `HarfordReputationStore` (crea claves vacias si faltan). **No inyecta facciones por defecto**: las facciones viven 100% en SavedVariables y se gestionan desde `/harfordadmin rep`.
- `HarfordReputation.CreateFaction(nameOrData, ...)` → acepta tabla `{name,description,icon,color,epsilonFactionId,group,subgroup,hidden,sortOrder}` o args posicionales. Devuelve `true, id`.
- `HarfordReputation.UpdateFaction(factionId, data)` → edita todos los campos incluyendo `sortOrder` (si `data.sortOrder ~= nil`).
- `HarfordReputation.GetGroups()` → `[{name, subgroups=[...]}]` — lista de grupos únicos con sus subgrupos.
- `HarfordReputation.CreateGroup(name)` → crea un encabezado de grupo persistente aunque aun no tenga facciones.
- `HarfordReputation.CreateSubgroup(groupName, subgroupName)` → crea una seccion persistente dentro de un grupo aunque aun no tenga facciones.
- `HarfordReputation.SetFactionGroup(factionId, groupName, subgroupName)` → mueve una faccion a un grupo/seccion.
- `HarfordReputation.RenameGroup(oldName, newName)` → actualiza `faction.group` en todas las facciones del grupo.
- `HarfordReputation.RenameSubgroup(groupName, oldSub, newSub)` → renombra subgrupo dentro de un grupo.
- `HarfordReputation.DeleteGroup(groupName)` -> borra solo grupos vacios, incluido `Reputaciones Harford` si esta vacio. No debe mover facciones automaticamente al grupo base ni recrear `Reputaciones Harford`, porque eso genera encabezados fantasma al limpiar estructura. Si el grupo tiene facciones, bloquear y pedir mover/borrar primero.
- `HarfordReputation.DeleteSubgroup(groupName, subgroupName)` -> borra la seccion persistente; si contiene facciones, no las borra, les limpia `subgroup` para dejarlas en la raiz del grupo.
- `HarfordReputation.SwapFactionOrder(factionIdA, factionIdB)` → intercambia `sortOrder` entre dos facciones (uso: botones ↑/↓ en panel admin).
- `HarfordReputation.SetFactionSortOrder(factionId, order)` → asigna sortOrder directamente.
- `HarfordReputation.MoveFactionOrder(factionId, direction)` → normaliza sortOrder y mueve una faccion una posicion en el orden global.
- `HarfordReputation.MoveGroupOrder(groupName, direction)` → normaliza `sortOrder` y mueve un grupo una posicion arriba/abajo en el panel admin.
- `HarfordReputation.MoveSubgroupOrder(groupName, subgroupName, direction)` → normaliza `subgroupOrder` y mueve una seccion una posicion dentro de su grupo.
- `HarfordReputation.GetGroups()` debe respetar `group.sortOrder` y `group.subgroupOrder`; no debe devolver el subgrupo vacio como una seccion real.
- `HarfordReputation.ResolveIconTexture(value)` -> los iconos de reputacion se guardan siempre como nombre corto (`INV_...`, `Ability_...`, `ability_xxx`), sin ruta. Para renderizar, Harford hardcodea `Interface\\Icons\\` + nombre. Si recibe datos antiguos con `Interface\\Icons\\...`, `NormalizeIconName` los limpia antes de guardar/mostrar.
- No hay facciones por defecto hardcodeadas en el core actual: se crean y gestionan desde `/harfordadmin rep`.
- `HarfordReputationStore` guardado en SavedVariables; estructura: `{factions={}, players={}, guilds={}, npcLinks={}, logs={}, groups={}, ui={}}`. Cada faccion puede tener `sortOrder` (number, default 0). `groups` guarda encabezados/secciones persistentes aunque esten vacios; cada grupo puede tener `sortOrder` y `subgroupOrder={ [subgroupName]=number }`.

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

- Panel flotante standalone (no embebido en TabPanel de la ficha: 183px de alto no son suficientes para la lista).
- `HarfordReputationUI.Toggle()` → abre/cierra el panel. Llamado desde el icono de tabardo junto al boton cerrar de la ficha y desde `/harfordrep`.
- `HarfordReputationUI.Open()` / `HarfordReputationUI.Close()` → acceso programatico.
- `HarfordReputationUI.Refresh()` → recarga la lista (llamado por HarfordReputation al cambiar datos).
- El icono de acceso en la ficha (`HarfordDnD.lua`) es un Button 20x20 hijo de `F`, del mismo tamano que el boton de turnos, anclado junto al boton cerrar con `TOPRIGHT, close, TOPLEFT, -2, -11` para quedar en la misma fila superior. Textura `INV_Shirt_GuildTabard_01`, highlight `ButtonHilight-Square` en blend ADD. Usa guard `HarfordReputationUI and HarfordReputationUI.Toggle`. NO hay un tab "Reputacion" en la barra de tabs; esos botones son exclusivos para tiradas (Caracteristicas, Ataque, Habilidades).
- El panel principal conserva el portrait y el attic/composicion superior gris de `ButtonFrameTemplate` como el frame de loot. No llamar a `ButtonFrameTemplate_HidePortrait` ni `ButtonFrameTemplate_HideAttic` en este panel. El fondo marmol/negro propio y cualquier banda negra interna deben empezar en el separador/lista (`LIST_TOP_Y + 2`), no detras del campo Buscar, para no tapar el gris nativo de la cabecera. El portrait usa mascara circular (`TempPortraitAlphaMask`) y se refresca con el contexto visible: sin target jugador, con target propio, o sin modo Admin DM muestra el portrait del `player`; con `HarfordAdmin + .ph dm` activo y target jugador distinto muestra el portrait del target. Para `player` respeta `portrait_player`; para target jugador respeta `portrait_target_player`; si TRP3 no da icono o el modo es `wow`, usa `SetPortraitTexture`.
- Arquitectura de tabs en HarfordDnD: 3 tabs de 124px de ancho (`TAB_W=124`, `TAB_GAP=6`, `TOTAL_TABS_W=384`) centrados en `SEC_W=392`, dejando 4px de margen a cada lado. Antes eran 4 tabs de 88px; no volver a esa configuracion.
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
- Solo HarfordAdmin con `.ph dm` activo (`HarfordReputation.CanEdit()`) deberia poder editar reputaciones; si se reintroduce editor avanzado, conservar esta regla.
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
- Opcodes legacy: `FAC` (datos de faccion), `REP` (puntos jugador), `NPC` (link NPC→faccion), `LOG` (entrada de log), `DEL` (borrar faccion). Quedan como referencia historica/API interna, pero el receptor actual no debe aplicar mensajes legacy entrantes.
- Snapshots completos/troceados:
  - `HarfordReputationSync.BroadcastSnapshotStructure()` serializa solo estructura: facciones, grupos/secciones y links NPC, sin puntos. Es el boton `Compartir estructura`.
  - `HarfordReputationSync.BroadcastSnapshotAll()` serializa estructura completa + puntos de jugadores/gremios + `SELFREP` para todas las facciones. Es el boton `Compartir todo`.
  - `HarfordReputationSync.BroadcastSnapshotFaction(factionId)` serializa solo la faccion seleccionada, su grupo/seccion, puntos de esa faccion y links NPC relacionados. Es el boton `Compartir seleccion`.
  - `HarfordReputationSync.BroadcastRepDelta(factionId, delta)` envia `RDELTA` a grupo/raid para que cada cliente aplique un delta a su propia reputacion local actual. El emisor aplica su delta localmente antes de emitir y el receptor ignora `RDELTA` si viene de si mismo para evitar doble ajuste si el cliente se eco-recibe.
  - Cada snapshot incluye tambien `SELFREP|factionId|points`: son los puntos actuales del jugador que comparte para esa faccion. Al recibirlo, cada cliente lo aplica a su propio `playerKey`, para que todos vean el mismo numero en su barra local despues de compartir.
  - Transporte: `SNAPC|transferId|scope|index|total|chunk`, con `chunk` escapado y limite pequeno (`SNAPSHOT_CHUNK_BYTES`) para evitar desbordamiento de addon messages.
  - El receptor reensambla por `sender:transferId`; al completar, deserializa y aplica.
- Vista remota DM→target:
  - `HarfordReputationSync.RequestPlayerSnapshot(playerKey)` envia `RVIEWREQ` por `WHISPER` al target (tambien prueba nombre corto si el key incluye reino).
  - El cliente objetivo responde con `RVIEWC|transferId|index|total|chunk`, usando el mismo snapshot `ALL` escapado/troceado, pero el receptor DM lo guarda en `remoteViews` y **no lo aplica al store local**.
  - `HarfordReputationSync.GetRemoteView(playerKey)` devuelve `{ groups, factions, points, npcLinks, guilds }`; `points` viene de `SELFREP` del jugador objetivo.
  - `HarfordReputationSync.SetRemoteViewPoints(playerKey, factionId, points)` actualiza de forma optimista la vista remota tras `SetTargetPoints`, para que el panel no parezca usar valores locales del DM mientras llega/si no llega eco de red.
  - Scope `ALL`: sustituye `store.factions`, `store.groups`, `store.players`, `store.guilds` y `store.npcLinks` completos.
  - Scope `STRUCTURE`: sustituye estructura (`store.factions`, `store.groups`, `store.npcLinks`) y respeta puntos locales de facciones que siguen existiendo. Debe inicializar a 0 las facciones nuevas para el jugador local y borrar puntos locales/gremio de facciones que ya no existan en la estructura recibida.
  - Los snapshots deben preservar orden visual: `GRP` envia `sortOrder` de grupo y `SUB` envia `subgroupOrder` de seccion. Las facciones ya viajan con `sortOrder` dentro de `FAC`. Al recibir, no reconstruir cabeceras sin estos campos o el cliente ordenara distinto.
  - Scope `FACTION`: sustituye solo esa faccion y limpia/reaplica sus puntos y links relacionados, preservando el resto del store local.
- Solo el DM emite snapshots desde botones admin explicitos. Los cambios locales (`CreateFaction`, `UpdateFaction`, ajustes de puntos, links NPC, etc.) no se emiten automaticamente; primero modifican SavedVariables locales y refrescan UI. Para compartirlos con la raid/grupo hay que pulsar `Compartir todo` o `Compartir seleccion`.
- Todos los clientes reciben y aplican snapshots con supresion interna de rebroadcast (`suppress`) para no reenviar el snapshot al grupo.
Modulo `HarfordDebug`:

- Vive en `Harford/HarfordDebug.lua`.
- El nombre historico `HarfordDnDDebug` queda como alias temporal de `HarfordDebug` para compatibilidad.
- Usa `HarfordDebugSettings` como SavedVariable para recordar si debug esta activo.
- Slash commands:
  - `/harforddebug on`: activa logs y comandos debug.
  - `/harforddebug off`: desactiva debug.
  - `/harforddebug toggle`: alterna estado.
  - `/harforddebug status`: muestra estado.
  - `/harforddebug list`: lista comandos debug registrados.
- `/harforddebug run <comando>`: ejecuta un comando debug registrado solo si debug esta activo.
- Alias corto: `/hdebug`.
- Para nuevos diagnosticos temporales, registrar comandos con `HarfordDebug.RegisterCommand(name, handler, helpText)`.
- Cualquier operacion de debug, dump, listado de candidatos o inspeccion temporal debe vivir aqui, no en modulos de gameplay/admin normal.
- Comandos debug actuales:
  - `/harforddebug run deps`: estado de `EpsilonLib.AddonCommands` y `ARC`.
  - `/harforddebug run sync`: estado basico de transporte addon.
  - `/harforddebug run phase`: prueba `phase info addon` con callback.
  - `/harforddebug run raw <comando>`: envia comando raw solo con debug activo.
  - `/harforddebug run trp3icons`: lista candidatos de icono TRP3 del target.
  - `/harforddebug run totlayer`: strata/level/anchors de `TargetFrameToT` y estado `totDesired`.
  - `/harforddebug run totportrait`: diagnostica portrait overlay ToT y TRP3 para `targettarget`.
  - `/harforddebug run totspy [s]`: hookea `TargetFrameToTManaBar` para capturar callers (no removible).
  - `/harforddebug run totscripts`: lista scripts en barras/frames del ToT.
  - `/harforddebug run totrate [s]`: mide frecuencia de llamadas al ciclo ToT.
  - `/harforddebug run totpieces`: lista globals/hijos StatusBar dentro de `TargetFrameToT`.
  - `/harforddebug run totframe [tot|focustot]`: vuelca jerarquía completa de `TargetFrameToT` o `FocusFrameToT` (hijos, regiones, tipo, strata, level, alpha, tamaño, textura/atlas). También reporta tipo de `TargetofTarget_Update`/`FocusofTarget_Update`, estado de overlays creados y alpha del portrait nativo. Primer paso obligatorio antes de tocar código del ToT.
  - `/harforddebug run npinspect [all]`: inspecciona el nameplate del target o todos los nameplates visibles; lista campos raiz, `UnitFrame`, barras y estructura Kui si existe.
  - `/harforddebug run npkui`: dump detallado de `nameplate.kui` del target para investigar KuiNameplates, especialmente modo name-only.
- Los comandos debug no deben ejecutar texto arbitrario recibido de otros clientes ni saltarse las validaciones de `HarfordEpsilonCommands`.

Regla de timers/refresco:

- No usar ticks continuos para UI o permisos (`C_Timer.NewTicker`, `OnUpdate` permanente, polling cada X segundos) salvo interacciones que realmente lo necesitan mientras duran, por ejemplo arrastrar el minimap button.
- Preferir eventos WoW/addon (`PLAYER_TARGET_CHANGED`, `UNIT_HEALTH`, `CHAT_MSG_ADDON`, `CHAT_MSG_SYSTEM`, cambios de config) y refrescos puntuales.
- `C_Timer.After` solo es aceptable como one-shot acotado para debounce/transicion concreta; no debe encadenarse para simular un ticker.
- `HarfordTurns` no debe refrescar cada 0.5s con `OnUpdate`; se refresca por cambios de target, salud, mensajes de sync y acciones locales.
- `HarfordLoot` no debe usar `OnUpdate` permanente para cerrar al moverse; se cierra con `PLAYER_STARTED_MOVING`. El tooltip de loot puede usar `OnUpdate` solo mientras el raton esta encima de un boton y debe limpiarlo en `OnLeave`.

Contrato `HarfordAuthority`:

- Vive en `Harford/HarfordAuthority.lua`.
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
  - `HarfordAuthority.CanUseDMTools()`: true solo si `HarfordAdmin` esta cargado y `.ph dm` esta activo. Tener el addon admin instalado no implica permiso DM; estar en `.ph dm` sin HarfordAdmin tampoco habilita herramientas admin.
  - `HarfordAuthority.CanUse(requirement)`: comprueba `member`, `officer`, `admin` o `dm`.
  - `HarfordAuthority.Require(requirement, actionName)`: helper para bloquear acciones segun capacidad.
  - `HarfordAuthority.GetStatus()`: snapshot para debug/UI.
  - `HarfordAuthority.RequireDMTools(actionName)`: helper para bloquear acciones futuras.
  - `HarfordAuthority.RegisterChangeListener(owner, callback)`: bus comun para UIs admin; el callback recibe `status, reason` cuando cambian admin addon, phase, rango o `.ph dm`.
  - `HarfordAuthority.ScheduleRefresh(reason)` / `NotifyChanged(reason, force)`: refresco centralizado de autoridad.
- Importante: `member`, `officer/owner`, `admin addon` y `.ph dm` son ejes separados. No asumir que estar en DM mode implica rango de phase, ni que ser officer implica estar en DM mode.
- `RegisterChangeListener` debe invocar callbacks con `pcall` tanto al registrar como en cambios posteriores. Si un listener falla, reportar via `HarfordDebug.Print` o `DEFAULT_CHAT_FRAME`, pero no romper la carga del addon.
- Lectura robusta de flags Epsilon: tratar `true`, `1`, `"1"` y `"true"` como valores activos. Algunos estados restaurados por Epsilon tras relog/cambio de mapa pueden no llegar como booleano Lua puro.
- Eventos de autoridad: `HarfordAuthority` escucha `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_FLAGS_CHANGED`, `CHAT_MSG_SYSTEM` y `UI_ERROR_MESSAGE`. No registrar `EPSILON_PHASE_CHANGE` directamente en un frame WoW: en este cliente produce `Attempt to register unknown event`; si `EpsilonLib.EventManager` esta disponible, registrarse ahi con `EpsilonLib.EventManager:Register("EPSILON_PHASE_CHANGE", ...)` protegido por `pcall`.
- SpellCreator confirma que `.ph dm` se actualiza desde `UI_ERROR_MESSAGE`: en `SpellCreator.lua`, si el mensaje es `"DM mode is ON"` pone `C_Epsilon.IsDM = true`; si es `"DM mode is OFF"` lo pone en `false`. Tambien resetea `C_Epsilon.IsDM = false` en `PLAYER_ENTERING_WORLD`/cambio de phase. Por tanto, si tras relog/mapa el servidor no vuelve a emitir `DM mode is ON`, `ARC.PHASE.IsDM()` seguira devolviendo falso aunque el jugador tenga `HarfordAdmin`.
- No usar ticker ni reintentos temporizados esperando `.ph dm`: tener `HarfordAdmin` instalado no implica que el jugador vaya a activar `.ph dm`. Si Epsilon restaura/cambia el estado, debe llegar por evento (`UI_ERROR_MESSAGE`, `PLAYER_FLAGS_CHANGED`, `EpsilonLib.EventManager` o mensaje de sistema) y entonces se refrescan las UIs admin.
- UIs admin deben registrarse en `RegisterChangeListener` en vez de depender solo de sus propios eventos. Confirmado: `HarfordAdminUnitMenu`, `HarfordAdminLoot` y `HarfordReputationUI` se refrescan desde este bus.
- Referencia SpellCreator:
  - `ARC.PHASE.IsMember = C_Epsilon.IsMember`
  - `ARC.PHASE.IsOfficer = C_Epsilon.IsOfficer`
  - `ARC.PHASE.IsOwner = C_Epsilon.IsOwner`
  - `ARC.PHASE.GetPhaseId = C_Epsilon.GetPhaseId`
  - `ARC.PHASE.IsDM = function() return C_Epsilon.IsDM end`
  - `ARC.XAPI.Phase.IsDM = ARC.PHASE.IsDM`
  - `SpellCreator/Permissions.lua` considera DM habilitado solo si `C_Epsilon.IsDM` y (`C_Epsilon.IsOfficer()` o `C_Epsilon.IsOwner()`).
  - `Permissions.isDMEnabled()` es interno del namespace de SpellCreator (`ns.Permissions`), no API global publica. Para Harford usar `ARC.PHASE.IsDM` / `ARC.XAPI.Phase.IsDM` como fuente publica y mantener `HarfordAuthority.IsDMEnabled()` como equivalente local cuando se necesite el criterio DM+officer/owner.
- Comando debug:
  - `/harforddebug run auth`: muestra estado de admin addon, phase rank, `.ph dm` y permisos DM tools.
  - `/harforddebug run authraw`: imprime valores raw de `C_Epsilon.IsDM`, `ARC.PHASE.IsDM()`, `ARC.XAPI.Phase.IsDM()`, `HarfordAuthority.IsDMMode()`, `C_Epsilon.IsOfficer()` y `C_Epsilon.IsOwner()`.

Contrato `HarfordAdminNPC`:

- Vive en `HarfordAdmin/HarfordAdminNPC.lua`.
- Es el primer modulo admin para acciones sobre target/NPC/enemigo.
- Por ahora no asume comandos Epsilon no confirmados.
- API inicial:
  - `HarfordAdminNPC.GetTargetSnapshot()`: lee datos locales del target actual.
  - `HarfordAdminNPC.PrintTarget()`: imprime nombre, GUID, tipo player/dead/level.
  - `HarfordAdminNPC.ApplyAuraToTarget(spellId)`: usa `HarfordServerActions.ApplyAura(spellId, "target", { addonName = "HarfordAdmin" })`.
  - `HarfordAdminNPC.RemoveAuraFromTarget(spellId)`: usa `HarfordServerActions.RemoveAura(spellId, "target", { addonName = "HarfordAdmin" })`.
  - `HarfordAdminNPC.SetAuraOnTarget(spellId)`: usa `HarfordServerActions.SetNpcAura(spellId, { addonName = "HarfordAdmin" })` para enviar `npc set aura <spellId>` al NPC target.
  - `HarfordAdminNPC.SetLootAuraOnTarget()`: envia `npc set aura 140172`.
  - `HarfordAdminNPC.GetTargetInfo(callback)`: provisional; envia `npc info` via `SendRawDebug`, por tanto requiere debug activo hasta confirmar el comando correcto.
  - `HarfordAdminNPC.HandleSlash(tokens)`: dispatcher para `/harfordadmin npc ...`.
- Slash commands:
  - `/harfordadmin npc target`: muestra snapshot local del target.
  - `/harfordadmin npc aura <spellId>`: aplica aura al target.
  - `/harfordadmin npc setaura <spellId>` o `/harfordadmin npc npcaura <spellId>`: aplica aura al NPC target por `npc set aura`.
  - `/harfordadmin npc lootaura`: aplica Loot Aura (`npc set aura 140172`) al NPC target.
  - `/harfordadmin npc unaura <spellId>`: quita aura al target.
  - `/harfordadmin npc info`: prueba provisional `npc info` con callback; requiere debug activo.
- Pendiente: confirmar comandos Epsilon reales para inspeccionar, seleccionar, mover o controlar NPC/enemigos.

Contrato `HarfordAdminLoot`:

- Vive en `HarfordAdmin/HarfordAdminLoot.lua` y se carga desde `HarfordAdmin.toc` antes de `HarfordAdminUnitMenu.lua`.
- Es la unica UI para `Cargar loot Harford`: slash `/harfordloot` y `/hloot`, editor de tablas por NPC, `Loot global`, guardar/borrar entradas y compartir configuracion por `HARFORDCFG`.
- Requiere `HarfordAdminAPI.IS_ADMIN == true` y `.ph dm` activo via `HarfordAuthority.IsDMMode()` para abrir o modificar datos. Con solo `Harford`, no debe existir editor ni slash de carga.
- Usa las tablas/SavedVariables del core (`HarfordLootLootRegistry`, `HarfordLootGlobalLootRegistry`) y `HarfordLootAPI.SaveConfig/BroadcastConfig/GetLootEntries/GetTargetCreatureId`; no cambia el formato `{itemId, chance, min, max}`.
- El editor sigue automaticamente el target NPC en `PLAYER_TARGET_CHANGED`: al seleccionar un NPC rellena `NPC ID`, desactiva `Loot global`, limpia seleccion si cambia la criatura y refresca la lista sin boton `Usar target`.
- El campo `ItemID` acepta numeros o enlaces de item tipo chat (`|Hitem:12345:...|h[...]|h`). Si el campo tiene foco, `Shift+click` sobre un item rellena el ID mediante hook seguro de `ChatEdit_InsertLink`; tambien acepta drag de item con `OnReceiveDrag`.
- El portrait del editor usa mascara circular (`TempPortraitAlphaMask`) y respeta `HarfordConfig.Get("portrait_target_npc")`: icono TRP3 via `HarfordTRP3.GetEpsilonNpcProfile("target")` + `HarfordTRP3.GetProfileIcon(profile)`, fallback WoW 3D via `SetPortraitTexture`, y fallback de bolsa (`Interface\\Icons\\INV_Misc_Bag_10`) si no hay NPC target.
- El editor tiene acciones para limpiar solo el historico de loot resuelto (`HarfordLootTaggedCreatureRegistry`), sin tocar tablas/configuracion:
  - `Limpiar local`: llama `HarfordLootAPI.ClearAllResolvedLoot()`.
  - `Limpiar grupo`: envia `LOOTCLEAR|ALL` por `HARFORDLOOT` al `RAID`/`PARTY` resuelto por `HarfordSync.BestChannel()` y solo despues de envio correcto limpia el historico local, porque el emisor ignora sus propios mensajes addon. Debe llamar `HarfordLootAPI.ClearRemoteLoot(channel, nil, false)`; el tercer parametro debe ser `false` para no enviar `HARFORDCFG` vacio ni borrar configuracion. Si no hay grupo/raid, no debe limpiar localmente desde este boton.
- `/harfordadmin lootclear ...` sigue la misma regla: limpia historico resuelto remoto, no tablas/configuracion. Para borrar configuracion de loot habria que crear una accion explicita distinta; no reutilizar `lootclear` enviando `HARFORDCFG` vacio.
- `HarfordLootAPI.ClearRemoteLoot(channel, target, clearConfigToo)` debe devolver `false, err` si no hay canal, si `WHISPER` no tiene target o si `SendAddonMessage` falla. No devolver `true` a ciegas: el boton `Limpiar grupo` depende de ese resultado para decidir si limpia el historico local del emisor.

Contrato `HarfordAdminUnitMenu`:

- Vive en `HarfordAdmin/HarfordAdminUnitMenu.lua`.
- Es exclusivo de `HarfordAdmin` y no debe cargarse desde el core `Harford`.
- Crea botones pequenos en `PlayerFrame` y `TargetFrame`.
- Los botones solo se muestran si `HarfordAdminAPI.IS_ADMIN == true` y `.ph dm` esta activo via `HarfordAuthority.IsDMMode()`.
- La visibilidad se refresca en eventos de carga/login/world/target, mensajes de sistema y al hacer click; no usar ticker continuo ni refrescos diferidos repetidos. Para `.ph dm on/off`, reconsultar `HarfordAuthority.IsDMMode()` en cada evento relevante en vez de cachear el valor.
- El boton visual debe ser circular y pequeno, incrustado en el unitframe como acceso admin, similar a un boton de minimapa. Usar fondo `Interface\\Minimap\\UI-Minimap-Background`, borde `Interface\\Minimap\\MiniMap-TrackingBorder`, highlight `UI-Minimap-ZoomButton-Highlight` e icono admin centrado con mascara circular. Importante: `MiniMap-TrackingBorder` no se centra; replica el patron del boton de minimapa de `HarfordDnD` a escala pequena: borde grande anclado `TOPLEFT` al boton, fondo/icono centrados. Debe existir tanto en el unitframe propio (`player`) como en el de objetivo (`target`).
- Usa `UIDropDownMenu` propio, no `UnitPopup` nativo.
- API:
  - `HarfordAdminUnitMenu.AttachButtons()`: crea/engancha botones si existen los unitframes.
  - `HarfordAdminUnitMenu.RefreshVisibility()`: muestra/oculta segun permisos y target.
  - `HarfordAdminUnitMenu.Open(unit, anchorButton)`: abre el menu para `player` o `target`.
  - `HarfordAdminUnitMenu.BuildNpcMenu(unit)` / `BuildPlayerMenu(unit)`: capturan snapshot de la unidad.
  - `GetMeasuredButtonPoint(unit, parent)` (privada): posiciona el boton en el hueco entre portrait y barras usando `HarfordUnitFrames.GetMeasuredLayout(unit, false)`. Debe aplicarse tanto si el parent es `HarfordPlayer/TargetUnitFrame` como si es el `PlayerFrame/TargetFrame` nativo, porque en modo frame separado los botones siguen teniendo que caer entre retrato y barras. `player` → borde derecho interior del portrait; `target` → borde izquierdo interior del portrait. Si `GetMeasuredLayout` no esta disponible, `AnchorUnitButton` usa la posicion estatica de respaldo.
  - `SyncButtonFrameLevel(button, parent, parentName)` (privada): al reanclar, iguala el strata del parent y pone el boton por encima del parent y del `PlayerFrameTextureFrame`/`TargetFrameTextureFrame` nativo (`max(levels)+10`). No subirlo a `DIALOG/HIGH` global: debe quedar por encima de su unitframe, no de ventanas de otros addons.
- Inicializacion event-driven: registra `ADDON_LOADED` (filtrando Harford/HarfordAdmin/SpellCreator/EpsilonLib), `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_TARGET_CHANGED`, `PLAYER_FLAGS_CHANGED` y `CHAT_MSG_SYSTEM`. Ademas se registra en `HarfordAuthority.RegisterChangeListener("HarfordAdminUnitMenu", ...)`, que es la fuente comun para relog/cambio de mapa/restauracion `.ph dm`. No usar ticker continuo.
- Reglas de seguridad:
  - Revalidar permisos antes de ejecutar cualquier accion.
  - Revalidar GUID/unidad antes de ejecutar acciones sobre target.
  - NPC health solo desde `TargetFrame` y solo si el GUID sigue coincidiendo.
  - Player health va por `HarfordDnDAPI.AdjustResourceForName(..., "health", delta)` / `RADJ`, no por comando servidor.
  - Auras sobre NPC target usan `HarfordAdminNPC.SetAuraOnTarget` / `HarfordServerActions.SetNpcAura`, es decir `npc set aura <spellId>`. El shortcut `Loot Aura` envia `npc set aura 140172`.
  - Quitar aura sobre NPC target conserva por ahora `HarfordAdminNPC.RemoveAuraFromTarget` (`unaura <spellId> target`) hasta confirmar un comando Epsilon especifico de retirada para NPC.
  - Auras sobre jugadores: `target` puede usar `HarfordAdminNPC.ApplyAuraToTarget` / `RemoveAuraFromTarget`; `player` usa `HarfordServerActions` con target `self`.
  - Inputs numericos usan `StaticPopupDialogs`.
- Opciones v1:
  - NPC: abrir ficha TRP3 por `TRP3_API.companions.register.openPage(profileID)`, mostrar TRP3 IDs, anadir/abrir turnos, vida con presets/personalizado, `Aplicar aura NPC...` (`npc set aura <spellId>`), `Loot Aura` (`npc set aura 140172`) y `Quitar aura...`.
  - NPC: incluye submenu `Loot` → `Cargar loot...`, que abre `HarfordAdminLoot.OpenEditor()`. Con target NPC actual, el editor rellena su `NPC ID`.
  - Jugador: abrir ficha TRP3 por `TRP3_API.register.openPageByUnitID(unitID)`, mostrar TRP3 unitID, anadir/abrir turnos, pedir recursos, vida por RADJ, aura/unaura.
  - Target jugador: en submenu `Ficha`, accion `Enviar ficha al target`. Usa `HarfordDnDAPI.BroadcastConfigForPlayer(nombreTarget, "WHISPER", whisperTarget)` para enviar ficha + configuracion de recursos al jugador seleccionado. Probar primero nombre corto `UnitName("target")` y luego nombre completo `GetUnitName("target", true)` si el perfil no existe con el corto. No aparece desde el boton propio de `player`, solo desde el boton del target.
  - Jugador: incluye submenu `Loot` → `Cargar loot...` tambien desde el boton propio de player, como acceso rapido al editor aunque no sea una accion sobre el jugador.

Contrato `HarfordTRP3`:

- Vive en `Harford/HarfordTRP3.lua`.
- Encapsula lectura TRP3 sin depender de API base de WoW para fichas.
- TRP3 se trata como dependencia opcional: comprobar runtime antes de usar.
- API inicial:
  - `HarfordTRP3.IsAvailable()`
  - `HarfordTRP3.BuildUnitID(unit)`: construye `Nombre-Reino`.
  - `HarfordTRP3.GetPlayerProfile(unit)`: perfil TRP3 de jugador via `TRP3_API.register`; para `player` debe usar primero `TRP3_API.profile.getPlayerCurrentProfile()`.
  - `HarfordTRP3.GetPlayerProfileByUnitID(unitID)`: perfil TRP3 de jugador por `Nombre-Reino`; si es el propio jugador debe usar `TRP3_API.profile.getPlayerCurrentProfile()`.
  - `HarfordTRP3.GetPlayerAboutText(profile)`: extrae About soportando perfiles remotos (`profile.about`) y perfil propio (`profile.player.about`), con plantillas TRP3 `T1`, `T2` y `T3`.
  - `HarfordTRP3.GetUnitRPName(unit)`: nombre RP si TRP3 lo conoce.
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
- El render de ficha en turnos debe simular los bloques/frames de TRP3 cuando el texto venga en secciones: cabecera con icono/titulo, separador fino e indentacion del cuerpo. Evitar una columna plana de texto corrido.
- `HarfordAdminNPC` usa este modulo con `/harfordadmin npc trp3` para mostrar fullID/profileID y preview de `data.TX`.
- `Harford/HarfordTurns.lua` usa `HarfordTRP3.GetEpsilonNpcProfile(unit)` al anadir un target no jugador al tracker de turnos, y luego `HarfordTRP3.GetProfileIcon(profile)` para tomar el icono principal de ficha TRP3.
- No usar busqueda recursiva sin prioridad para iconos TRP3: puede coger `IC` de estados/PE u otros bloques antes que el icono real de la ficha.
- En turnos, si una entrada tiene `entry.icon`, ese icono persistido tiene prioridad sobre `SetPortraitTexture`. Motivo: el retrato vivo de `target`/`mouseover` puede perderse al cambiar de objetivo/personaje y degradar a una textura incorrecta. Solo usar `SetPortraitTexture` si no hay icono persistido.
- `HarfordTurns` ya serializa `displayId`. Si no hay icono TRP3 persistido, debe intentar `SetPortraitTextureFromCreatureDisplayID(texture, entry.displayId)` antes de usar retratos vivos de `target`/`mouseover`. Esto permite reconstruir un portrait estable por modelo de criatura aunque el GUID concreto ya no este targeteado.
- No guardar `texture:GetTexture()` despues de `SetPortraitTexture`: puede devolver valores internos/genericos como retratos temporales, no una ruta de textura estable.
- Modelo de datos recomendado para turnos/NPC:
  - `entry.id`: GUID unico de la instancia concreta.
  - `entry.npcId`: id base extraido del GUID, para agrupar criaturas iguales o buscar `TOTALRP_PROFILE_<npcID>` si se anade en el futuro.
  - `entry.displayId`: modelo/apariencia de criatura para portrait estable.
  - `entry.icon`: icono TRP3 o icono persistido manual, prioridad maxima.
- Las entradas de turnos guardan metadatos TRP3 opcionales:
  - `entry.trpFullID`: `phaseID .. "_" .. npcID`, para volver a cargar ficha TRP3 aunque ya no este targeteado.
  - `entry.trpUnitID`: `Nombre-Reino` para volver a cargar ficha TRP3 de jugadores, incluido el propio `player`.
  - `entry.trpProfileID`: profileID TRP3 companion/NPC como fallback si existe en `TRP3_API.companions.register.getProfiles()`.
  - `entry.nameColor`: color hexadecimal de nombre TRP3 (`characteristics.CH`) para jugadores.
  - `entry.npcId`
  - `entry.phaseId`
- Sincronizacion `HARFORDTURN`:
  - Los estados pequenos siguen viajando como `STATE|activeIndex|adminName|entries`.
  - Si el estado supera el limite seguro, `HarfordTurns` lo parte en mensajes `SCHUNK|transferId|index|total|chunk`.
  - El receptor agrupa trozos por `sender + transferId`, los reensambla en orden y solo entonces aplica el `STATE`.
  - Los chunks escapan `%` y `|` para no romper el parser del protocolo.
  - No enviar el texto completo de fichas TRP3 por sync de turnos. El estado debe enviar solo identificadores y metadatos estables.
  - Para NPC Epsilon, enviar/normalizar `entry.trpFullID`, `entry.phaseId`, `entry.npcId` y, si se conoce, `entry.trpProfileID`; el cliente receptor debe asumir que ya tiene esa ficha en su TRP3 local y cargarla con `getCompanionProfile(entry.trpFullID)`, usando `getProfiles()[entry.trpProfileID]` solo como fallback.
  - Para jugadores, enviar/normalizar `entry.trpUnitID`; el cliente receptor debe cargar el About desde `TRP3_API.register` o desde el perfil propio si corresponde.
- Click izquierdo sobre una tarjeta de turnos abre una ventana de ficha. Para NPC Epsilon intenta cargar `profile.data.TX` desde `TRP3_API.companions.register.getCompanionProfile(entry.trpFullID)`. Para jugadores intenta cargar `profile.about` desde `TRP3_API.register` usando `entry.trpUnitID`, y si hace falta busca la unidad viva por GUID (`player`, `target`, `mouseover`, grupo/raid).
- El titulo de la ficha de turnos debe mostrar icono persistido + nombre. En jugadores, el nombre usa `entry.nameColor` de TRP3; en NPC, usa el color de reaccion/reputacion guardado.
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
  - El tracker no debe mostrar controles manuales de `Nombre/NPC`, `Ini`, `Vida`, `Max` ni boton generico `NPC`: el flujo correcto es anadir desde `Objetivo` o `Jugador` para conservar GUID, TRP3, reaccion y recursos.
  - Si el turno activo recibido o avanzado pertenece al jugador local, mostrar una alerta local estilo banda (`RaidWarningFrame`) y reproducir sonido de raid warning si esta disponible. Evitar repetirla en cada refresh guardando una clave del turno ya alertado.
  - Si hay mas de `MAX_CARDS` entradas, la ventana debe permitir desplazar la vista con botones `<` y `>` sin cambiar el turno activo. Al avanzar/retroceder turno, autoajustar la vista para que el activo quede visible.
- Si no encuentra icono TRP3, cae al fallback por tipo/clasificacion de criatura.

Contrato `HarfordConfig`:

- Vive en `Harford/HarfordConfig.lua`. SavedVariable: `HarfordConfigStore` (tabla plana de clave→valor).
- API: `HarfordConfig.Get(key)`, `HarfordConfig.Set(key, value)`, `HarfordConfig.Reset()`, `HarfordConfig.RegisterChangeListener(fn)`.
- Claves actuales y defaults:
  - `portrait_player = "trp3"`: retrato del jugador. `"trp3"` usa icono TRP3 si disponible, `"wow"` usa retrato 3D WoW.
  - `portrait_target_player = "trp3"`: retrato del target cuando es jugador.
  - `portrait_target_npc = "trp3"`: retrato del target cuando es NPC. Default `"trp3"` porque en Epsilon los NPCs pueden tener ficha companion TRP3; cae a WoW 3D si no hay perfil.
  - `resources = "unitframe"`: modo de recursos del target. `"unitframe"` activa el overlay Harford con barras DnD en player y target jugador. `"frame"` restaura los unitframes nativos de WoW para ambas unidades y muestra `HarfordDnDTargetResourceFrame` (frame separado flotante) para el target. En modo `"frame"`, los cambios de barras/textos/niveles/recursos de `HarfordUnitFrames` deben quedar desactivados; solo se permite seguir aplicando retratos segun `portrait_player`, `portrait_target_player` y `portrait_target_npc`.
  - `nameplates = "on"`: activa overlays DnD de `HarfordNamePlates` sobre placas de nombre. `"off"` oculta y limpia sus overlays.
- Los `RegisterChangeListener` deben ser livianos: `HarfordUnitFrames` llama `API.Refresh(false)` al cambiar config y fuerza `RefreshTargetOfTargetBars(true)` + `focusTot.refresh(true)` para que ToT/FocusToT actualicen icono/modo sin tener que quitar y volver a seleccionar target; `HarfordDnD` llama `RefreshTargetResourceFrame()` + `HarfordUnitFrames.Refresh(false)`.
- Panel de opciones abre con `/hconfig` o desde Interface Options → Addons → Harford. Usa `UIDropDownMenuTemplate` (no checkboxes). El dropdown muestra la opcion activa al abrir el panel (`UIDropDownMenu_SetText` se llama en `MakeDropDown` al crear y en `OnShow`).
- Panel tiene una seccion `UnitFrames Harford` con tres dropdowns de retrato en horizontal: `Propio`, `Objetivo` y `Objetivo NPC`, mas un dropdown de recursos debajo. Ancho de dropdown: 160px.
- Panel tiene una seccion `Nameplates Harford` con dropdown `nameplates` (`Activado`/`Desactivado`). Al resetear defaults, refrescar tambien este dropdown.
- En `HarfordConfig.lua`, por compatibilidad con llamadas antiguas, `MakeLabel`/`MakeDropDown` remapean textos/posiciones historicas (`Retrato - Jugador`, `Target jugador`, `Target NPC`) a la disposicion horizontal nueva. Si se limpia esta deuda, hacerlo en una sola pasada reemplazando las llamadas antiguas del panel, no quitando el remapeo sin ajustar la UI.

Contrato `HarfordUnitFrames`:

- Vive en `Harford/HarfordUnitFrames.lua`.
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
- `TargetFrameToT` / unidad `targettarget`: el parpadeo de barras esta resuelto con `totBarsOverlay`. El portrait TRP3 tambien usa overlay (`totBarsOverlay.portraitFrame`) para evitar que `TargetofTarget_Update` restaure el portrait 3D nativo, pero ese portrait overlay es hijo del propio `TargetFrameToT`: solo sustituye el icono, no intenta quedar por encima de barras adicionales ni de otros overlays. `AdjustTargetOfTargetFrame` se llama desde `RefreshFrame` junto a `AdjustTargetAuras` cuando `resourceCount > 2`; eleva el frame ToT en strata/level pero NO lo reposiciona fisicamente (intento de reposicion fisica fue descartado — ver enfoques fallidos). `RefreshTargetOfTargetNative` existe pero no se llama directamente — el portrait se actualiza desde `RefreshTargetOfTargetBars` al detectar cambio de GUID.
- ToT barras — arquitectura `totBarsOverlay`: `TargetFrameToTHealthBar` y `TargetFrameToTManaBar` son repintadas constantemente por Blizzard via `OnUpdate` de `TargetFrameToT` y `OnValueChanged` de cada barra (confirmado con `totspy`/`totscripts`). Cualquier escritura en barras nativas causa parpadeo. Solucion para barras/arte: frames parentes a **`UIParent` con `SetFrameStrata("MEDIUM")`** y niveles internos `82-84` (`artFrame`, health/mana frames, barras), cada uno con `SetAllPoints` a su pieza nativa (`TargetFrameToTHealthBar`, `TargetFrameToTManaBar`). Parental a `UIParent` es CRITICO para barras/arte: los overlays estaban antes como hijos de `TargetFrameToT` pero Epsilon no honra la jerarquia de strata para hijos de `TargetFrame`, por lo que los `barSlotOverlays` (MEDIUM strata, level 58) renderizaban encima aunque el ToT fuese HIGH strata level 120. Usar `MEDIUM`, no `HIGH` ni `DIALOG`: `HIGH/DIALOG` tapaban ventanas de otros addons y no es comportamiento nativo. Con UIParent/MEDIUM level 82+ queda por encima de barras extra Harford (`barSlotsFrame` aprox. level 58) pero por debajo de paneles addon normales con strata superior o niveles altos. El portrait es la excepcion: no necesita quedar por encima de barras extra y va hijo del ToT nativo. Cada frame de barra: fondo oscuro (`SetColorTexture 0.04,0.04,0.04,1`) + `StatusBar` con `TEX_STATUS`. Blizzard sigue pintando sus barras debajo — tapadas, invisibles. `ApplyNativeResourceBars` NO toca ninguna barra nativa del ToT. `UpdateToTBarsOverlay(list[1], list[2])` actualiza health+resource; `list[1].tempCur` (vida temporal) se aplica via `ApplyAbsorbTexture(EnsureNativeAbsorbTexture(ov.healthFrame.bar), ov.healthFrame.bar, cur, max, tempCur, 0.85)` sobre la barra de salud overlay — mismo patron que player/target/focus. Sin datos el health overlay se oculta y el mana overlay muestra fondo oscuro (valor 0). `UpdateFocusTotBarsOverlay` sigue el mismo patron para `focustarget`. `RefreshTargetOfTargetBars()` es la **fuente de verdad unica** para el estado del overlay ToT: (1) si no existe `targettarget`, resetea `targetOfTargetLastGUID` y llama `HideToTBarsOverlay()`; (2) si existe, actualiza portrait (solo si cambia GUID) y barras. Debe llamarse desde `RefreshFrame` en AMBOS branches (supported y !supported) para `unit == "target"`. En el branch `!supported`, llamar siempre `RefreshTargetOfTargetBars()`, **NUNCA** `HideToTBarsOverlay()` directamente: llamarlo directo no resetea `targetOfTargetLastGUID` y puede causar race condition donde el overlay recien mostrado en el branch `supported` queda oculto si `UnitIsSupportedPlayer` devuelve false momentaneamente durante transiciones de target. `HideToTBarsOverlay()` solo se llama desde dentro de `RefreshTargetOfTargetBars` y desde `RestoreNativeFrameContents("targettarget")`. Enfoques FALLIDOS en barras: `SetAlpha(0)` en barras nativas (Blizzard lo restaura via OnUpdate), escribir en barras nativas (idem), hijos de `TargetFrameToT` con frame level alto (Epsilon ignora cross-tree strata).
- ToT en modo recursos `"frame"`: el ToT debe quedarse original. `RefreshTargetOfTargetBars(forceVisual)` debe ocultar solo overlays de recursos/arte (`healthFrame`, `manaFrame`, `artFrame`) mediante `HideToTResourceOverlays()` y refrescar siempre `UpdateToTPortraitOverlay(GetProfile("targettarget"))`. Asi, si la opcion de retrato TRP3 cambia, el icono del ToT se actualiza aunque no cambie el GUID. No llamar `ApplyNativeResourceBars("targettarget")` ni `UpdateToTBarsOverlay` en este modo. En modo `"unitframe"`, pasar `forceVisual=true` fuerza tambien la reevaluacion del portrait aunque `targettarget` sea la misma unidad.
- **FocusFrameToT / `focustarget`**: sistema paralelo completo implementado. Estado en tabla `focusTot = {overlay, lastGUID, hooksInstalled}` (1 local de file-scope). Funciones encapsuladas en `do...end` para no consumir slots de local del scope global (el archivo roza el límite de 200 locales de Lua 5.1). Funciones públicas expuestas como `focusTot.hide()`, `focusTot.refresh(forceVisual)`, `focusTot.ensureHooks()`. El hook se instala para `FocusofTarget_Update` si existe (análogo a `TargetofTarget_Update`). `NativePiecesForUnit("focustarget")` usa root=`FocusFrameToT`, prefix=`"FocusFrameToT"`. `ApplyNativeResourceBars` excluye `focustarget` de escrituras en barras nativas igual que `targettarget`. Eventos cubiertos: `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UNIT_PORTRAIT_UPDATE`, `UNIT_NAME_UPDATE` con `unit=="focustarget"`; `UNIT_TARGET` con `unit=="focus"`. El portrait `FocusFrameToTPortrait` sigue el mismo patrón que el ToT: respeta `portrait_target_player`/`portrait_target_npc`, `SetAlpha(0)` inicial + `API._SyncToTNativePortraitAlpha(portraitNative, portraitOverlay)` llamado en cada hook de `FocusofTarget_Update` para reajustar el alpha según si el overlay de icono está visible. **CRÍTICO: `HideFocusTotBarsOverlay` debe resetear `focusTot.lastGUID = nil`** antes de ocultar, para que la próxima llamada a `UpdateFocusTotBarsOverlay` re-evalúe el portrait aunque el GUID no haya cambiado. Sin este reset, si Hide se llama cuando `tot:IsShown()` es transitoriamente false, el portrait nunca vuelve a mostrarse.
- Ciclo de vida `totBarsOverlay`: como los overlays son hijos de `UIParent`, no se ocultan automaticamente cuando `TargetFrameToT` se oculta. `EnsureToTBarsOverlay()` debe crear los frames ocultos y no llamar `Show()` por defecto. `UpdateToTPortraitOverlay()` y `UpdateToTBarsOverlay()` deben validar `UnitExists("targettarget")` y `TargetFrameToT:IsShown()` antes de mostrar nada. `EnsureTargetOfTargetHooks()` debe enganchar `TargetFrameToT:HookScript("OnHide", ...)` para resetear `targetOfTargetLastGUID` y llamar `HideToTBarsOverlay()`.
- Marco visual ToT (`artFrame`): `totBarsOverlay.artFrame` es también hijo de `UIParent`/MEDIUM (level **82**), por debajo de las barras overlay (83/84). **CRÍTICO: si `artFrame` tiene un level superior al de las barras, las tapa completamente (bug confirmado: artFrame a 503 tapaba todo).** El portrait overlay ya no comparte este árbol de niveles: va hijo del ToT nativo. `artFrame` clona en runtime solo la textura real `UI-TargetofTargetFrame` del hijo `TargetFrameToTTextureFrame` / `FocusFrameToTTextureFrame` usando bounds relativos. `CollectToTArtRegions` aplica tres filtros para evitar cuadrados falsos: (1) solo escanea `*TextureFrame`, no el root ni otros hijos; (2) `hasTex` check — `GetTexture() or GetAtlas()` debe ser no-nil; (3) path filter — solo texturas cuyo path/atlas contiene `ui-targetoftargetframe` o `targetoftargetframe`. Sin estos filtros se copian texturas vacías de los slots Debuff/Buff que producen cuadrados blancos. `UpdateToTArtOverlay(root, ov)` es genérico y acepta cualquier frame ToT como primer parámetro. Si el ToT se oculta o no existe `targettarget`, `artFrame` se oculta junto al resto.
- Cuadrados buff/debuff del ToT (`HideToTNativeExtras`): `TargetFrameToTBuff1..N` y `TargetFrameToTDebuff1..N` son hijos Frame del ToT. En Epsilon, `TargetofTarget_Update` puede hacerlos visibles según auras activas. Se ocultan con `HookScript("OnShow", function(self) self:Hide() end)` + `Hide()` — el HookScript garantiza que ninguna llamada futura de Blizzard los vuelva a mostrar. Esto es posible porque son objetos Frame (no Texture). Se llama una única vez en `EnsureToTBarsOverlay` / `EnsureFocusTotBarsOverlay`. Confirmado como solución a los cuatro cuadrados que aparecían junto al ToT.
- ToT portrait overlay (`totBarsOverlay.portraitFrame`): frame hijo de `TargetFrameToT` / `FocusFrameToT`, level local `tot:GetFrameLevel()+3`, `SetAllPoints(TargetFrameToTPortrait)` / `SetAllPoints(FocusFrameToTPortrait)`. No parentarlo a `UIParent` ni usar `TOT_PORTRAIT_LEVEL`: el icono solo debe sustituir el portrait nativo, no quedar por encima de barras adicionales o ventanas. En Epsilon `TargetFrameToTPortrait`/`FocusFrameToTPortrait` son `Texture`, no `Frame`; no se puede usar `HookScript("OnShow")` sobre ellos (solo funciona en objetos Frame, no en Texture). Textura `ptex` con `SetTexCoord(0.08,0.92,0.08,0.92)` + mascara circular via `CreateMaskTexture`/`AddMaskTexture` con `TEX_PORTRAIT_MASK`. **CRÍTICO: la máscara debe aplicarse a AMBAS texturas — `pbg:AddMaskTexture(mask)` Y `ptex:AddMaskTexture(mask)` — usando un único mask object con `mask:SetAllPoints(pf)` (frame completo). Si solo se aplica a `ptex`, el `pbg` queda cuadrado y se ve como borde negro/verde alrededor del icono circular.** El portrait nativo se sincroniza por alpha tras cada update: `API._SyncToTNativePortraitAlpha(portraitNative, portraitOverlay)` aplica alpha `0` si el overlay de icono está visible, alpha `1` si no. Esta función se llama desde el hook de `TargetofTarget_Update`/`FocusofTarget_Update` para contrarrestar la restauración constante de alpha que hace Blizzard a ~60fps. No intentar ocultarlo permanentemente con hooks de frame — `HookScript` no funciona en objetos Texture. `HideToTNativeExtras` (para buff/debuff slots, que SÍ son Frame) sí puede usar `HookScript("OnShow", hide)` porque esos hijos son objetos Frame, no Texture.
- Limitacion Epsilon confirmada: frames hijos de `TargetFrame` (incluyendo `TargetFrameToT` y sus hijos) NO respetan la jerarquia de strata de WoW respecto a frames de otros arboles. Un frame MEDIUM strata hijo de `UIParent` puede renderizar encima de un frame HIGH strata hijo de `TargetFrame`. Solucion: cualquier overlay Harford que deba estar encima de los `barSlotOverlays` debe ser hijo de `UIParent`, pero mantenerlo en `MEDIUM` con level controlado si es HUD/unitframe. `HIGH`/`DIALOG` quedan reservados para paneles/ventanas; no usarlos para ToT porque tapa addons. NO reparentar `TargetFrameToT` a `UIParent`: FrameXML espera que siga bajo `TargetFrame`.
- Diagnostico ToT: `NativePiecesForUnit("targettarget")` puede probar `TargetFrameToTHealthBar`/`TargetFrameToTManaBar`, campos internos `healthbar`/`manabar` y, si fallan, escanear hijos `StatusBar` del `TargetFrameToT`. Usar `/harforddebug run totpieces` y `/harforddebug run totwatch` antes de reactivar icono/nombre/nivel.
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
- Los buffs/debuffs del `TargetFrame` solo deben desplazarse si el target tiene mas de dos barras visibles. El desplazamiento es dinamico segun la altura real de las barras extra (`frame.extraResourceHeight`), no con una formula paralela. No cambiar el parent de los frames de aura: guardar sus puntos originales con `SaveAuraPoints`, restaurar `point`, `relativeTo`, `relativePoint` y `x`, y modificar solo `y` con `-extraResourceHeight`. No reanclar al `TOPLEFT`/`BOTTOMLEFT` del frame Harford, porque eso pierde la posicion nativa y desplaza los iconos a izquierda/arriba. Invalidar el cache de anclas al cambiar `UnitGUID("target")` o en `UNIT_AURA target`, porque Blizzard recoloca `TargetFrameBuff1`/`TargetFrameDebuff1`. Importante: si el primer debuff esta anclado a `TargetFrameBuff*` en el layout nativo, no aplicar el offset tambien al debuff; debe heredar el movimiento desde el buff para no solapar/desdoblar filas. Despues del desplazamiento, medir y normalizar la separacion entre `TargetFrameBuff1` y `TargetFrameDebuff1` para conservar el gap nativo; asi se corrigen tanto solapes como doble-offset. Nombres: intentar `_G.TargetFrameBuff1` / `_G.TargetFrameDebuff1` primero; fallback a `_G.TargetFrame.BuffFrame` / `_G.TargetFrame.DebuffFrame`.
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
- En compact/raid frames, Blizzard repinta el color de vida desde `CompactUnitFrame_UpdateHealthColor`; Harford puede post-hookear esa funcion solo para refrescar el overlay Harford, no para tocar la barra nativa. Para diagnostico, `/harforddebug run groupframes` debe mostrar clase resuelta, color esperado y color real de la barra nativa.
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
- `/harforddebug run groupframes` debe incluir `barColor`, `texColor` y `value/min-max` de la barra de salud para distinguir si el fallo de raid viene de color, textura interna o rango/valor.
- Expone `HarfordUnitFrames.GetFrame(unit)` para que `HarfordAdminUnitMenu` pueda anclarse al frame Harford en lugar del frame nativo oculto.
- Si no hay recursos cacheados para un jugador remoto en `player`/`target`/`focus`, no dejar las barras Blizzard con su valor nativo porque al cambiar target pueden verse llenas hasta que llegue `RES`. En modo unitframe integrado, las barras nativas controladas por Harford deben ponerse en estado pendiente: `0/1`, valor `0`, sin texto, salud verde oscura y recurso/fondo oscuro. No pintar `PG --/--   PM --/--`: el fallback textual dentro de barras genera ruido visual. Para party/raid, no tocar la barra nativa: ocultar/no crear overlay si falta informacion suficiente.
- La primera barra de recurso del target usa la barra nativa de power/mana (`TargetFrameManaBar`) y Blizzard puede repintarla despues de `PLAYER_TARGET_CHANGED` con power/numeros normales. Harford debe post-hookear los caminos de power/text (`TargetFrame_Update`, `TargetFrame_UpdatePower`, `UnitFrameManaBar_Update`, `TextStatusBar_UpdateTextString*` cuando afecten a `TargetFrameManaBar`) y llamar `ReapplyNativeBars("target")` para reaplicar inmediatamente el estado Harford o pendiente, incluido ocultar `TextString`/`LeftText`/`RightText`. `ApplyNativeStatusBar`/`ApplyPendingNativeStatusBar` marcan `_harfordApplying` mientras escriben `SetValue` para evitar bucles con `OnValueChanged`.
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
  - `/harforddebug run ufmeasure player|target|focus`: imprime el layout calculado, piezas nativas detectadas y texturas de fondo/relleno usadas.
  - `/harforddebug run ufcompare player|target|focus`: compara bounds Harford contra la medicion y muestra frame levels de fondo, relleno, texto y overlay.
  - `/harforddebug run groupframes`: lista frames de party/raid detectados, unidad, visibilidad y barras nativas (`health`/`power`) para diagnosticar clientes Epsilon/custom.
  - `/harforddebug run barslot player|target|focus`: imprime UV/posicion de los `barSlotOverlays`.
  - `/harforddebug run totlayer`: imprime parent/strata/level de `TargetFrameToT`, frame Harford target, `barSlotsFrame`, anchor points actuales del ToT y estado `totDesired`.
  - `/harforddebug run totpieces`: lista globals/campos/hijos `StatusBar` candidatos dentro de `TargetFrameToT`.
  - `/harforddebug run totwatch [segundos]`: observa eventos/update de `TargetFrameToT` y valores de barras durante unos segundos.
  - `/harforddebug run totportrait`: diagnostica el portrait overlay del ToT — si existe `totBarsOverlay.portraitFrame`, si esta visible, que textura tiene y que devuelve TRP3 para `targettarget`. Util para depurar por que no aparece el icono TRP3.
  - `/harforddebug run totspy [segundos]`: hookea metodos de `TargetFrameToTManaBar` con `hooksecurefunc` para capturar quien los llama. NO removible; solo para diagnostico puntual. Confirmo: `TargetofTarget_Update` y `OnValueChanged` disparan SetStatusBarColor/SetValue a ritmo de frame (~60fps).
  - `/harforddebug run totscripts`: lista scripts registrados en barras y frames del ToT (`OnUpdate`, `OnValueChanged`, etc.).
  - `/harforddebug run totrate [segundos]`: mide frecuencia de llamadas a `TargetofTarget_Update`, eventos `UNIT_HEALTH`/`UNIT_POWER_UPDATE`, y contador de `RefreshTargetOfTargetBars`.
  - Estos comandos solo verifican la calibracion; el render normal no depende de ejecutarlos.
- No usar ticker continuo para esta capa visual.
- El frame Harford (`SecureUnitButtonTemplate`) tiene `EnableMouse(false)`: el frame nativo (PlayerFrame/TargetFrame) permanece visible y funcional y maneja click-to-target, menu contextual y tooltips de buffs. Si Harford captura mouse bloquea los buff/debuff icons del target frame. No volver a activar mouse en el frame raiz de Harford sin una razon explicita.

Contrato `HarfordNamePlates`:

- Vive en `Harford/HarfordNamePlates.lua` y se carga despues de `HarfordUnitFrames.lua` en `Harford.toc`, porque reutiliza `HarfordUnitFrames.BuildResourceList`, `HarfordUnitFrames.ResourceColor`, `HarfordUnitFrames.C.TEX_STATUS` y `HarfordUnitFrames.GetClassColor`.
- Control de config: `HarfordConfig.Get("nameplates")`. `"on"` activa overlays; `"off"` oculta y limpia `npState`.
- Objetivo: pintar recursos Harford en nameplates coloreados por clase TRP3, con nombre RP visible encima de las barras.
- **Deteccion dinamica de modo**: `IsKuiActive() and rawget(nameplate, "kui")` se evalua en cada `ApplyUnit`. Si Kui se inicializa despues de nuestro addon (race condition en NAME_PLATE_UNIT_ADDED), el overlay puede haberse creado en modo nativo. `st.isKui` marca el modo del overlay actual; si cambia, el overlay se destruye y se recrea en el modo correcto. Nunca reutilizar un overlay nativo como Kui ni viceversa: sus estructuras internas son incompatibles.
- Soporta dos caminos:
  - **KuiNameplates activo**: usa `nameplate.kui`, `kui.HealthBar`, `kui.NameText`, `kui.IN_NAMEONLY` y `kui.unit`. El overlay (`ov`) se parenta al `kuiFrame`. `st.isKui = true`.
  - **Nativo WoW**: usa `nameplate.UnitFrame.healthBar` / `HealthBar` o campos equivalentes. Overlay hijo de `healthBar`. `st.isKui = false`.
- **Plugin Kui**: `TryRegisterKuiPlugin()` se llama en `PLAYER_LOGIN` (no en tiempo de carga del TOC) para garantizar que Kui esta inicializado. Si Kui no existe, la funcion es no-op. Si Harford registra el plugin despues de que Kui haya inicializado su lista en `PLAYER_LOGIN`, hay que llamar manualmente a `mod:Initialise()` y `mod:Enable()`; si no, el plugin queda creado pero no escucha mensajes. El plugin escucha `Show`, `Hide`, `HealthUpdate`, `HealthColourChange`, `GainedTarget` y `LostTarget` para repintar sin ticker.
- **Modo Kui normal**: overlay anclado a `kui.HealthBar`, frame level `kuiFrame+5`. Al aplicar el modo, recalcular tambien los niveles de `ov.hpBar`, `ov.resBar` y `ov.tempBar` (`base+1`, `base+1`, `base+2`); no asumir que el cambio de level del parent reajusta hijos ya creados. Fondo opaco tapa la barra nativa. Para el nombre, usar el `kui.NameText` real como fuente visual principal: `SetText(nombre TRP3)`, `SetTextColor(color clase)`, `SetAlpha(1)` y `Show()`. Como el `NameText` real puede quedar por debajo de nuestras barras si vive en el plano de Kui/HealthBar, parentarlo temporalmente a `ov.nameHost` (`base+5`) y luego llamar a `kuiFrame:UpdateNameTextPosition()` para conservar anchors/posicion de Kui. No ocultar `kui.NameText` ni depender de un FontString propio para el camino normal: en Kui puede quedar en un plano no visible. `ov.nameLabel` queda solo como fallback si `NameText` no existe.
- **Modo Kui name-only**: no dibujar `ov.hpBar` ni barras semitransparentes detras del nombre. El porcentaje de vida se representa coloreando el propio texto de `kui.NameText` por caracteres con codigos `|cff...|r` (parte rellena en color clase/TRP3, resto gris). Si aun no hay recursos Harford cacheados para `nameplateN`, usar `UnitHealth/UnitHealthMax` como fallback temporal solo para pintar el progreso del nombre; seguir pidiendo recursos remotos con throttle. Antes de aplicar este modo, devolver `kui.NameText` al `kuiFrame` y ejecutar `UpdateNameTextPosition`; `kui.NameText` permanece visible y tambien recibe el nombre TRP3; `ov.nameLabel` oculto. `HideUnit` tambien restaura el parent del `NameText` al `kuiFrame` para no contaminar frames reciclados.
- **ClassPowers de Kui**: mientras `HarfordConfig.Get("nameplates") ~= "off"` y Kui este activo, desactivar/ocultar temporalmente el plugin/frame global `ClassPowers` de Kui para que los recursos propios del jugador (por ejemplo fragmentos de alma de brujo) no aparezcan sobre placas gestionadas por Harford ni parpadeen al seleccionar. No restaurarlo por `HideUnit`, `LostTarget` ni por cambios de placa: Kui usa un unico frame global y restaurarlo por unidad reintroduce flicker. `SetKuiClassPowersSuppressed(true)` guarda si el plugin estaba activo y llama `plugin:Disable()` si existe; `SetKuiClassPowersSuppressed(false)` restaura con `plugin:Enable()` solo al desactivar nuestros nameplates/config `"off"`.
- Kui repinta `NameText` en `UpdateNameText`/`UpdateNameTextPosition` al ganar/perder target. Harford debe hookear esos metodos por `kuiFrame` y re-aplicar `API.ApplyUnit(unit)` despues de Kui, con guard `API._applying` para evitar recursion cuando Harford mismo llama `UpdateNameTextPosition`.
- **Color TRP3 en nameplateN**: no depender del cache de `HarfordUnitFrames.GetClassColor`, porque se llena al seleccionar/interactuar con unitframes. `HarfordNamePlates.GetNpClassColor` debe intentar primero `HarfordTRP3.GetPlayerProfile(unit)` + `HarfordTRP3.GetProfilePrimaryClass(profile)` con aliases de clases WoW (`Paladin`, `Pícaro/Picaro`, `Brujo`, etc.) y solo despues caer al cache/unitclass.
- **Color de clase**: `GetNpClassColor(unit)` — delega en `HarfordUnitFrames.GetClassColor(unit)` (cache TRP3 → perfil TRP3 directo → clase WoW) con fallback a `RAID_CLASS_COLORS[classFile]` y verde para NPCs sin clase. Se usa en `ov.hpBar:SetStatusBarColor` y en `ov.nameLabel:SetTextColor`. **NUNCA verde fijo para jugadores**: indica ausencia de clase detectada, no salud.
- **Nombre TRP3**: `GetTRP3Name(unit)` usa `HarfordTRP3.GetPlayerProfile(unit)` (que llama `BuildUnitID` — soporta tokens nameplate correctamente) y lee `profile.data.characteristics.FN`+`LN`. Fallback a `HarfordTRP3.GetUnitRPName(unit)` y finalmente a `UnitName(unit)`. **NO pasar el token nameplate directamente a `register.getUnitRPName`**: TRP3 puede no soportar tokens `nameplateN` en versiones antiguas; usar siempre `BuildUnitID` como intermediario. **FontString sin `SetFont` no renderiza nada**: siempre establecer fuente por defecto en la creacion del FontString antes de mostrarlo.
- En nativo WoW sin Kui, crear overlay simple hijo de la `healthBar` nativa y pintar salud + primer recurso con color de clase. Sin `nameLabel` (WoW nativo ya muestra el nombre correctamente).
- Vida temporal: si `resources["Res_temp_health_Cur"] > 0`, se inyecta `hpData.tempCur` antes del render. El overlay `ov.tempBar` es un `StatusBar` como contenedor de absorcion. En modo Kui, `ov.tempBar._harfordUseKui = true` y la textura es `Kui_Media\\t\\stippled-bar` (con `SetHorizTile(true)`). En modo nativo WoW, usa `Interface\\RaidFrame\\Shield-Fill` (con `SetHorizTile(false)`). Efecto visual: Shield-Fill (fill solido azul) + `_harfordAbsorbGlow` (Shield-Overlay tileado con ADD blend, alpha 0.45) encima. En name-only se oculta. **Patrones criticos de `ApplyAbsorbTexture` en nameplates**: (1) Pattern/glow se muestran pero solo si `realW > 0`: el glow se ancla TOPLEFT..BOTTOMLEFT con `SetWidth(realW*pct)` y `SetHorizTile(true)`; (2) Spark: `CENTER, frame, LEFT, realW*pct` — **NO `fillTex:RIGHT`** (texcoords-based en Epsilon, siempre apunta al extremo) y no sumar `+2` global; (3) **`OnSizeChanged` en `healthBar`** con guard `npState[unit]` para nameplates nativos reciclados.
- Recursos remotos: si la unidad es jugador y no hay recursos cacheados, llamar `HarfordDnDAPI.RequestResourcesForName(unitName)` con throttle de 5s por nombre.
- Eventos: `NAME_PLATE_UNIT_ADDED` aplica overlay; `NAME_PLATE_UNIT_REMOVED` oculta y limpia la entrada (incluyendo restaurar `kui.NameText:SetAlpha(1)`). `PLAYER_LOGIN` registra plugin Kui. `HarfordUnitFrames` llama `HarfordNamePlates.RefreshAll()` cuando llegan recursos por `CHAT_MSG_ADDON`.
- Debug relacionado:
  - `/harforddebug run npinspect`: inspecciona target.
  - `/harforddebug run npinspect all`: lista nameplates visibles.
  - `/harforddebug run npkui`: vuelca campos/regiones de `nameplate.kui`.
- No usar `OnUpdate` ni ticker para nameplates. La integracion debe ser event-driven por eventos de nameplate, mensajes Kui, config listener y `RefreshAll()` tras sync de recursos.

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

Prefixes actuales:

- `DND5EARC`: ficha, tiradas, recursos y configuracion DnD.
- `HARFORDLOOT`: loot resuelto y limpieza remota.
- `HARFORDCFG`: configuracion global de loot.
- `HARFORDTURN`: estado del tracker de turnos.

Canales actuales:

- `RAID` o `PARTY`, elegidos via `HarfordSync.BestChannel()`.
- `WHISPER`, para mensajes dirigidos a un jugador concreto.

Archivos clave:

- `Harford/HarfordSync.lua`: wrappers comunes de registro/envio.
- `Harford/HarfordDnDComm.lua`: receptor principal de mensajes DnD.
- `Harford/HarfordLoot.lua`: receptor loot/config.
- `Harford/HarfordTurns.lua`: receptor turnos.
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

La API publica principal es el global `ARC`. Se inicializa en `SpellCreator/Constants.lua` y se amplia en `SpellCreator/API.lua`.

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

- `EpsilonLib.AddonCommands` es la via preferida cuando Harford necesite callback o parsear respuesta del servidor.
- `ARC.CMD` queda como fallback/compatibilidad para comandos simples fire-and-forget como `additem`, `aura` o `unaura`.
- Harford debe usar `HarfordServerActions` para acciones de gameplay/UI que impliquen comandos servidor.
- `HarfordEpsilonCommands.Send(...)` queda como transporte compartido de bajo nivel.
- `ARC.CMD` directo solo debe vivir como fallback local dentro del wrapper o compatibilidad temporal.
- `Harford/HarfordLoot.lua` usa `HarfordServerActions` para `additem`, `aura 224063 self` y `unaura 224063 self`.
- Antes de usar `ARC`, comprobar runtime:

```lua
if ARC and ARC.CMD then
end
```

## Reglas De Seguridad

- No ejecutar texto arbitrario recibido de otros clientes como comando Epsilon.
- Los comandos Epsilon deben salir solo desde logica admin explicita.
- Preferir plantillas cerradas y parametros validados antes que concatenar texto libre.
- Mantener separadas estas capas:
  - Comunicacion Harford entre clientes.
  - Comandos Epsilon al servidor.
  - Respuestas Epsilon parseadas desde callbacks.
- Si se anade integracion Epsilon, `HarfordAdmin` deberia declarar dependencia opcional o hacer comprobacion runtime de `EpsilonLib`.

## Verificacion

Para esta documentacion:

- Confirmar que `AGENTS.md` existe en la raiz del workspace.
- Confirmar que no se modifica codigo de los addons.
- Confirmar que las rutas y nombres de prefixes coinciden con los archivos actuales.

Para una futura implementacion en juego:

- Validar que `EpsilonLib.AddonCommands.Register` existe.
- Validar que un comando simple devuelve callback `success/messages`.
- Validar que Harford sigue sincronizando por sus prefixes propios sin mezclarse con `"Command"`.
