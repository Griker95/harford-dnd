# Guia Para Agentes - Proyecto Harford

Este archivo documenta el contexto tecnico que debe recordar cualquier agente que trabaje en este repo. Es una guia viva: actualizala cuando se confirme nueva informacion del entorno Epsilon/Shadowlands o cambie la arquitectura de los addons.

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
  HarfordDnDResources.lua     -- recursos DnD, cache remota, claves
  HarfordDnDStore.lua         -- persistencia de fichas/perfiles
  HarfordDnDComm.lua          -- recepcion DND5EARC y handlers cliente-cliente
  HarfordLoot.lua             -- UI loot y datos loot; usa wrapper compartido para additem/aura
  HarfordDnD.lua              -- UI ficha, tiradas, recursos
  HarfordTurns.lua            -- tracker turnos, HP/mana, sync de turnos

HarfordAdmin/
  HarfordAdmin.lua            -- bootstrap, slash commands, API admin existente
  HarfordAdminNPC.lua         -- acciones admin basicas sobre target/NPC/enemigo
  HarfordAdminUnitMenu.lua    -- menu contextual DM en PlayerFrame/TargetFrame
  HarfordAdminPanel.lua       -- futuro: panel DM central si hace falta
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
  - `HarfordServerActions.SendRawDebug(command, callback, opts)`: comando raw solo si `HarfordDebug` esta activo.
- `Harford/HarfordLoot.lua` debe usar esta capa para `additem`, `aura 224063 self` y `unaura 224063 self`.
- Nuevas features DM/NPC deberian anadir acciones aqui antes de crear UI.

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
- Los comandos debug no deben ejecutar texto arbitrario recibido de otros clientes ni saltarse las validaciones de `HarfordEpsilonCommands`.

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
  - `HarfordAuthority.CanUseDMTools()`: true si `HarfordAdmin` esta cargado o si `.ph dm` esta activo.
  - `HarfordAuthority.CanUse(requirement)`: comprueba `member`, `officer`, `admin` o `dm`.
  - `HarfordAuthority.Require(requirement, actionName)`: helper para bloquear acciones segun capacidad.
  - `HarfordAuthority.GetStatus()`: snapshot para debug/UI.
  - `HarfordAuthority.RequireDMTools(actionName)`: helper para bloquear acciones futuras.
- Importante: `member`, `officer/owner`, `admin addon` y `.ph dm` son ejes separados. No asumir que estar en DM mode implica rango de phase, ni que ser officer implica estar en DM mode.
- Referencia SpellCreator:
  - `ARC.PHASE.IsMember = C_Epsilon.IsMember`
  - `ARC.PHASE.IsOfficer = C_Epsilon.IsOfficer`
  - `ARC.PHASE.IsOwner = C_Epsilon.IsOwner`
  - `ARC.PHASE.GetPhaseId = C_Epsilon.GetPhaseId`
  - `ARC.PHASE.IsDM = function() return C_Epsilon.IsDM end`
  - `SpellCreator/Permissions.lua` considera DM habilitado solo si `C_Epsilon.IsDM` y (`C_Epsilon.IsOfficer()` o `C_Epsilon.IsOwner()`).
- Comando debug:
  - `/harforddebug run auth`: muestra estado de admin addon, phase rank, `.ph dm` y permisos DM tools.

Contrato `HarfordAdminNPC`:

- Vive en `HarfordAdmin/HarfordAdminNPC.lua`.
- Es el primer modulo admin para acciones sobre target/NPC/enemigo.
- Por ahora no asume comandos Epsilon no confirmados.
- API inicial:
  - `HarfordAdminNPC.GetTargetSnapshot()`: lee datos locales del target actual.
  - `HarfordAdminNPC.PrintTarget()`: imprime nombre, GUID, tipo player/dead/level.
  - `HarfordAdminNPC.ApplyAuraToTarget(spellId)`: usa `HarfordServerActions.ApplyAura(spellId, "target", { addonName = "HarfordAdmin" })`.
  - `HarfordAdminNPC.RemoveAuraFromTarget(spellId)`: usa `HarfordServerActions.RemoveAura(spellId, "target", { addonName = "HarfordAdmin" })`.
  - `HarfordAdminNPC.GetTargetInfo(callback)`: provisional; envia `npc info` via `SendRawDebug`, por tanto requiere debug activo hasta confirmar el comando correcto.
  - `HarfordAdminNPC.HandleSlash(tokens)`: dispatcher para `/harfordadmin npc ...`.
- Slash commands:
  - `/harfordadmin npc target`: muestra snapshot local del target.
  - `/harfordadmin npc aura <spellId>`: aplica aura al target.
  - `/harfordadmin npc unaura <spellId>`: quita aura al target.
  - `/harfordadmin npc info`: prueba provisional `npc info` con callback; requiere debug activo.
- Pendiente: confirmar comandos Epsilon reales para inspeccionar, seleccionar, mover o controlar NPC/enemigos.

Contrato `HarfordAdminUnitMenu`:

- Vive en `HarfordAdmin/HarfordAdminUnitMenu.lua`.
- Es exclusivo de `HarfordAdmin` y no debe cargarse desde el core `Harford`.
- Crea botones pequenos en `PlayerFrame` y `TargetFrame`.
- Los botones solo se muestran si `HarfordAdminAPI.IS_ADMIN == true` y `.ph dm` esta activo via `HarfordAuthority.IsDMMode()`.
- La visibilidad se refresca en eventos de login/world/target y al hacer click; no usar ticker continuo.
- Usa `UIDropDownMenu` propio, no `UnitPopup` nativo.
- API inicial:
  - `HarfordAdminUnitMenu.AttachButtons()`: crea/engancha botones si existen los unitframes.
  - `HarfordAdminUnitMenu.RefreshVisibility()`: muestra/oculta segun permisos y target.
  - `HarfordAdminUnitMenu.Open(unit, anchorButton)`: abre el menu para `player` o `target`.
  - `HarfordAdminUnitMenu.BuildNpcMenu(unit)` / `BuildPlayerMenu(unit)`: capturan snapshot de la unidad.
- Reglas de seguridad:
  - Revalidar permisos antes de ejecutar cualquier accion.
  - Revalidar GUID/unidad antes de ejecutar acciones sobre target.
  - NPC health solo desde `TargetFrame` y solo si el GUID sigue coincidiendo.
  - Player health va por `HarfordDnDAPI.AdjustResourceForName(..., "health", delta)` / `RADJ`, no por comando servidor.
  - Auras sobre `target` pueden usar `HarfordAdminNPC.ApplyAuraToTarget` / `RemoveAuraFromTarget`; auras sobre `player` usan `HarfordServerActions` con target `self`.
  - Inputs numericos usan `StaticPopupDialogs`.
- Opciones v1:
  - NPC: abrir ficha TRP3 por `TRP3_API.companions.register.openPage(profileID)`, mostrar TRP3 IDs, anadir/abrir turnos, vida con presets/personalizado, aura/unaura.
  - Jugador: abrir ficha TRP3 por `TRP3_API.register.openPageByUnitID(unitID)`, mostrar TRP3 unitID, anadir/abrir turnos, pedir recursos, vida por RADJ, aura/unaura.

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
- Los `RegisterChangeListener` deben ser livianos: `HarfordUnitFrames` llama `API.Refresh(false)` al cambiar config; `HarfordDnD` llama `RefreshTargetResourceFrame()` + `HarfordUnitFrames.Refresh(false)`.
- Panel de opciones abre con `/hconfig` o desde Interface Options → Addons → Harford. Usa `UIDropDownMenuTemplate` (no checkboxes). El dropdown muestra la opcion activa al abrir el panel (`UIDropDownMenu_SetText` se llama en `MakeDropDown` al crear y en `OnShow`).
- Panel tiene una seccion `UnitFrames Harford` con tres dropdowns de retrato en horizontal: `Propio`, `Objetivo` y `Objetivo NPC`, mas un dropdown de recursos debajo. Ancho de dropdown: 160px.
- En `HarfordConfig.lua`, por compatibilidad con llamadas antiguas, `MakeLabel`/`MakeDropDown` remapean textos/posiciones historicas (`Retrato - Jugador`, `Target jugador`, `Target NPC`) a la disposicion horizontal nueva. Si se limpia esta deuda, hacerlo en una sola pasada reemplazando las llamadas antiguas del panel, no quitando el remapeo sin ajustar la UI.

Contrato `HarfordUnitFrames`:

- Vive en `Harford/HarfordUnitFrames.lua`.
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
- Solo los recursos extra, a partir del tercero, pueden usar barras propias apiladas bajo el frame. `focus` sigue la misma regla que `target`: barras 1-2 nativas, barras 3+ Harford con `barSlotOverlays`.
- `TargetFrameToT` / unidad `targettarget`: el parpadeo de barras esta resuelto con `totBarsOverlay`. El portrait TRP3 tambien usa overlay (`totBarsOverlay.portraitFrame`) para evitar que `TargetofTarget_Update` restaure el portrait 3D nativo. `AdjustTargetOfTargetFrame` se llama desde `RefreshFrame` junto a `AdjustTargetAuras` cuando `resourceCount > 2`; eleva el frame ToT en strata/level pero NO lo reposiciona fisicamente (intento de reposicion fisica fue descartado — ver enfoques fallidos). `RefreshTargetOfTargetNative` existe pero no se llama directamente — el portrait se actualiza desde `RefreshTargetOfTargetBars` al detectar cambio de GUID.
- ToT barras — arquitectura `totBarsOverlay`: `TargetFrameToTHealthBar` y `TargetFrameToTManaBar` son repintadas constantemente por Blizzard via `OnUpdate` de `TargetFrameToT` y `OnValueChanged` de cada barra (confirmado con `totspy`/`totscripts`). Cualquier escritura en barras nativas causa parpadeo. Solucion: `totBarsOverlay` = tres frames parentes a **`UIParent` con `SetFrameStrata("DIALOG")` y level 500/501/502** (healthFrame, manaFrame, portraitFrame), cada uno con `SetAllPoints` a su pieza nativa (`TargetFrameToTHealthBar`, `TargetFrameToTManaBar`, `TargetFrameToTPortrait`). Parental a `UIParent` con DIALOG strata es CRITICO: los overlays estaban antes como hijos de `TargetFrameToT` pero Epsilon no honra la jerarquia de strata para hijos de `TargetFrame`, por lo que los `barSlotOverlays` (MEDIUM strata, level 58) renderizaban encima aunque el ToT fuese HIGH strata level 120. Con UIParent/DIALOG quedan en un arbol de frames independiente y siempre encima. Cada frame: fondo oscuro (`SetColorTexture 0.04,0.04,0.04,1`) + `StatusBar` con `TEX_STATUS`. Blizzard sigue pintando sus barras debajo — tapadas, invisibles. `ApplyNativeResourceBars` NO toca ninguna barra nativa del ToT. `UpdateToTBarsOverlay(list[1], list[2])` actualiza health+resource; sin datos el health overlay se oculta y el mana overlay muestra fondo oscuro (valor 0). `RefreshTargetOfTargetBars()` es la **fuente de verdad única** para el estado del overlay ToT: (1) si no existe `targettarget`, resetea `targetOfTargetLastGUID` y llama `HideToTBarsOverlay()`; (2) si existe, actualiza portrait (solo si cambia GUID) y barras. Debe llamarse desde `RefreshFrame` en AMBOS branches (supported y !supported) para `unit == "target"`. En el branch `!supported`, llamar siempre `RefreshTargetOfTargetBars()`, **NUNCA** `HideToTBarsOverlay()` directamente: llamarlo directo no resetea `targetOfTargetLastGUID` y puede causar race condition donde el overlay recién mostrado en el branch `supported` queda oculto si `UnitIsSupportedPlayer` devuelve false momentáneamente durante transiciones de target. `HideToTBarsOverlay()` solo se llama desde dentro de `RefreshTargetOfTargetBars` y desde `RestoreNativeFrameContents("targettarget")`. Enfoques FALLIDOS en barras: `SetAlpha(0)` en barras nativas (Blizzard lo restaura via OnUpdate), escribir en barras nativas (idem), hijos de `TargetFrameToT` con frame level alto (Epsilon ignora cross-tree strata).
- ToT en modo recursos `"frame"`: el ToT debe quedarse original. `RefreshTargetOfTargetBars()` debe ocultar solo overlays de recursos/arte (`healthFrame`, `manaFrame`, `artFrame`) mediante `HideToTResourceOverlays()` y refrescar siempre `UpdateToTPortraitOverlay(GetProfile("targettarget"))`. Asi, si la opcion de retrato TRP3 cambia, el icono del ToT se actualiza aunque no cambie el GUID. No llamar `ApplyNativeResourceBars("targettarget")` ni `UpdateToTBarsOverlay` en este modo.
- Ciclo de vida `totBarsOverlay`: como los overlays son hijos de `UIParent`, no se ocultan automaticamente cuando `TargetFrameToT` se oculta. `EnsureToTBarsOverlay()` debe crear los frames ocultos y no llamar `Show()` por defecto. `UpdateToTPortraitOverlay()` y `UpdateToTBarsOverlay()` deben validar `UnitExists("targettarget")` y `TargetFrameToT:IsShown()` antes de mostrar nada. `EnsureTargetOfTargetHooks()` debe enganchar `TargetFrameToT:HookScript("OnHide", ...)` para resetear `targetOfTargetLastGUID` y llamar `HideToTBarsOverlay()`.
- Marco visual ToT: para que el ToT quede nativo aunque las barras extra de Harford esten por debajo, `totBarsOverlay` puede incluir `artFrame`, tambien hijo de `UIParent`/DIALOG. `artFrame` no mueve ni modifica `TargetFrameToT`; clona en runtime solo regiones `Texture` del ToT real cuyo path/atlas pertenezca a `targetingframe`/`targetoftarget`, usando bounds relativos al ToT nativo. Orden actual recomendado: barras/fondo DIALOG 500/501, portrait overlay 502, arte del marco 503. Si el ToT se oculta o no existe `targettarget`, `artFrame` se oculta junto al resto del overlay.
- ToT portrait overlay (`totBarsOverlay.portraitFrame`): frame `UIParent`/DIALOG level 502, `SetAllPoints(TargetFrameToTPortrait)`. Textura `ptex` con `SetTexCoord(0.08,0.92,0.08,0.92)` + mascara circular via `CreateMaskTexture`/`AddMaskTexture` con `TEX_PORTRAIT_MASK`. **CRÍTICO: la máscara debe aplicarse a AMBAS texturas — `pbg:AddMaskTexture(mask)` Y `ptex:AddMaskTexture(mask)` — usando un único mask object con `mask:SetAllPoints(pf)` (frame completo). Si solo se aplica a `ptex`, el `pbg` queda cuadrado y se ve como borde oscuro alrededor del icono circular.** El portrait 3D nativo se suprime con `pNative:SetAlpha(0)` en dos puntos: (1) `UpdateToTPortraitOverlay` cuando hay icono TRP3, inmediato al cambio de GUID; (2) hook post-`TargetofTarget_Update` despues de `RefreshTargetOfTargetBars`, leyendo el estado definitivo del overlay en ese tick. El hook restaura `SetAlpha(1)` si no hay overlay activo. El portrait se actualiza desde `RefreshTargetOfTargetBars` al detectar cambio de GUID via `UpdateToTPortraitOverlay(GetProfile("targettarget"))`.
- Limitacion Epsilon confirmada: frames hijos de `TargetFrame` (incluyendo `TargetFrameToT` y sus hijos) NO respetan la jerarquia de strata de WoW respecto a frames de otros arboles. Un frame MEDIUM strata hijo de `UIParent` puede renderizar encima de un frame HIGH strata hijo de `TargetFrame`. Solucion: cualquier overlay Harford que deba estar encima de los `barSlotOverlays` debe ser hijo de `UIParent` con strata DIALOG. NO reparentar `TargetFrameToT` a `UIParent`: FrameXML espera que siga bajo `TargetFrame`.
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
  - **`totBarsOverlay` como hijos de `TargetFrameToT`**: frame level +10 sobre barras nativas. Epsilon no honra strata cross-tree: `barSlotOverlays` (MEDIUM strata) renderizaban encima del ToT (HIGH strata) aunque el level absoluto fuese mayor. Solucion correcta: UIParent/DIALOG strata.
  - **Reposicion fisica de `TargetFrameToT`** (mover por `extraHeight` sumando al anchor Y): intentado para esquivar el problema de strata. Resultado: el ToT queda en posicion incorrecta segun el usuario ("tendria que esta en su posicion de siempre"). Ademas, `TargetofTarget_Update` puede resetear los anchors entre ticks. No reparentar ni mover el `TargetFrameToT` — solo gestionar strata/level y cubrir con overlays UIParent/DIALOG.
  - **`SetAlpha(0)` en barras nativas del ToT** (`TargetFrameToTHealthBar`/`TargetFrameToTManaBar`): `TargetofTarget_Update` y `OnValueChanged` restauran alpha ~12x/segundo. Causa parpadeo constante.
  - **Hijos de `TargetFrameToT` para portrait overlay**: el portrait 3D nativo (`TargetFrameToTPortrait`, PlayerModel) renderiza en Epsilon encima de cualquier frame 2D hijo del mismo arbol independientemente del frame level. Solucion: overlay UIParent/DIALOG + `SetAlpha(0)` en el portrait nativo desde el hook post-`TargetofTarget_Update`.
- El fondo de barra debe intentar copiar textura/atlas/texcoords desde regiones nativas `BACKGROUND` o desde la textura interna del statusbar medido, pero el color del fondo debe forzarse a oscuro/neutro. No heredar `vertexColor` nativo para el fondo, porque puede aparecer como restos verdes/rojos al final de la barra.
- Recursos extra se apilan debajo de la segunda barra usando el alto real medido y expanden el alto del frame Harford. El primer recurso extra (indice 3) se ancla a `power.y + power.height + BAR_GAP` desde el top del frame visual; los siguientes se anclan al `TOPLEFT` del container anterior con offset `-(barH + BAR_GAP)`.
- Cada barra extra usa una jerarquía de dos frames: `borderFrame` (exterior, sin color propio — el borde visual viene del overlay de textura del `barSlotsFrame`) → `container` (interior, `SetAllPoints(borderFrame)`, sin inset). El `StatusBar` y el `textFrame` viven dentro de `container`. `bar.container = borderFrame` (para posicionamiento y show/hide externo); `bar.innerContainer = container` (para bg, mouse, text). `borderFrame.bg` y `borderFrame.textFrame` son shortcuts para que el código externo acceda via `bar.container.bg` etc. No usar `BackdropTemplate` ni `UI-Tooltip-Border` ni ningún `SetColorTexture`/`borderBg` propio: el marco correcto es la textura del unitframe nativo recortada por UV.
- Al ocultar `bar.container` (borderFrame), los hijos se ocultan automaticamente por propagacion padre-hijo de WoW. No hace falta ocultar `container.borderFrame` por separado — ya no existe esa estructura.
- `frame.maxBarIndex` rastrea el indice mas alto de barra extra creado. La limpieza de barras al cambiar de target itera de `max(#list, 2)+1` hasta `frame.maxBarIndex`, no con `#frame.bars` (que es indefinido en Lua cuando hay huecos en el array porque los indices 1 y 2 nunca se crean).
- Los buffs/debuffs del `TargetFrame` solo deben desplazarse si el target tiene mas de dos barras visibles. El desplazamiento es dinamico segun la altura real de las barras extra. No cambiar el parent de los frames de aura: solo modificar/restaurar sus puntos. Anclar siempre al `BOTTOMLEFT` del frame Harford (no del `TargetFrame` nativo), porque el frame Harford ya incluye la altura extra. Nombres: intentar `_G.TargetFrameBuff1` / `_G.TargetFrameDebuff1` primero; fallback a `_G.TargetFrame.BuffFrame` / `_G.TargetFrame.DebuffFrame`. Offsets desde BOTTOMLEFT del frame Harford: buffs `y = -2`, debuffs `y = -20`.
- No reparentar `TargetFrameToT` a `UIParent`: FrameXML espera que siga bajo `TargetFrame` y puede romper `TargetFrame_UpdateAuras` con `UnitIsUnit(nil, ...)`. La solucion al z-order es hacer los overlays Harford hijos de `UIParent` con DIALOG strata, no mover el frame nativo. Si se ajusta strata/level del ToT, hacerlo sin `C_Timer.After(0)` ni ticker continuo.
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
- La deteccion de party/raid debe soportar tanto globals clasicos (`PartyMemberFrame1..4`) como frames compactos dentro de `CompactPartyFrame`, `CompactRaidFrameContainer`, `CompactRaidGroup*` y tablas internas tipo `memberUnitFrames`/`unitFrames`. En `GROUP_ROSTER_UPDATE` hacer refresco inmediato y diferido corto, porque algunos frames compactos se construyen despues del evento.
- La via principal para party/raid debe ser `hooksecurefunc` sobre `CompactUnitFrame_UpdateAll`, `CompactUnitFrame_UpdateHealth`, `CompactUnitFrame_UpdatePower` y `DefaultCompactUnitFrameSetup`: aplicar Harford justo despues de que Blizzard actualice cada `CompactUnitFrame`. Esto evita depender de nombres concretos y evita escanear `UIParent`, que puede producir taint con objetos protegidos.
- No recorrer `UIParent:GetChildren()` buscando frames compactos: en el cliente Epsilon/SL puede lanzar `Attempt to access forbidden object from code tainted by an AddOn`.
- Los overlays de party/raid deben ser hijos sin mouse del compact frame, anclados a las barras nativas medidas (`healthBar`/`powerBar`). No reparentar, ocultar ni sustituir el compact frame nativo; si un frame no expone barras o no tiene unidad WoW valida, no se modifica.
- Los overlays de party/raid NO deben vivir en un frame level alto global tipo `frameLevel + 25`: eso tapa el nombre y capas internas del compact frame. El overlay host debe quedar cerca del compact frame (`+2`) y cada barra debe posicionarse justo por encima de su barra nativa (`nativeBar:GetFrameLevel() + 1`) para que los textos/iconos nativos sigan ganando la capa cuando corresponda.
- En overlays de party/raid, el texto no puede ser un FontString directo del mismo contenedor que aloja el `StatusBar`: el `StatusBar` es un frame hijo y puede dibujarse encima. Usar `textFrame` con frame level mayor que la barra (`container + 3`) y crear el FontString dentro. Como la barra de salud compacta puede ocupar tambien la zona del nombre, replicar el nombre en `overlay.nameFrame`, copiando bounds/color del nombre nativo si existe.
- Al limpiar party/raid al cambiar a modo `"frame"`, no llamar manualmente a `CompactUnitFrame_UpdateAll/Health/Power` sobre frames recolectados. Eso puede forzar estados visuales incorrectos, por ejemplo party frames apareciendo mientras se esta en raid. Limpiar solo marcas/textos propios y dejar que Blizzard refresque sus frames por su ciclo normal.
- Antes de modificar retratos compactos, guardar snapshot ligero (`textura/texcoords/alpha/shown`) y restaurarlo al cambiar a modo `"frame"`. Para barras compactas, evitar snapshots de `min/max/value/color`: no deben tocarse en flujo normal. `compactBarState` queda como compatibilidad de limpieza para versiones anteriores.
- Al restaurar compact frames, no limitarse a frames encontrados en `CollectAllGroupFrames()`: tambien iterar directamente `compactBarState` y `compactPortraitState`, porque Blizzard puede cambiar la coleccion visible entre el momento de modificacion y el cambio de modo.
- Si existe `compactBarState` de una version anterior, debe guardar el `compactFrame` propietario. Al restaurar una barra compacta legacy, limpiar marcas Harford y pedir `CompactUnitFrame_UpdateAll(compactFrame)` / `CompactUnitFrame_UpdateHealthColor(compactFrame)` si existen. No volver a restaurar valor/color desde snapshots.
- La restauracion final al modo `"frame"` debe dejar que Blizzard repinte sus compact frames: usar una bandera de supresion (`restoringCompactFrames`) para que los hooks Harford sean no-op y llamar `CompactUnitFrame_UpdateAll(frame)` solo sobre frames compactos visibles y con unidad valida. Hacer tambien repintados diferidos cortos para frames que Blizzard reconfigure despues del cambio. No llamar esta funcion sobre `PartyMemberFrame*` ocultos/noexists.
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
- Para mover el texto de salud cuando hay Power Bars, aplicar el ajuste solo a unidades `raidN`, nunca a `partyN`. Inferir Power Bars desde el propio frame (`FindGroupPowerBar(frame):IsShown()`), no solo desde CVar. Si la powerBar compacta de raid esta visible, bajar ligeramente el texto para evitar solape con el nombre del jugador.
- En raid/compact frames, si `resources == "unitframe"` y `statusTextDisplay` esta en `NONE`, el texto Harford no debe mostrarse fijo: debe aparecer solo en hover mediante `OnEnter` y ocultarse/restaurarse en `OnLeave`. Si el CVar esta en `NUMERIC/PERCENT/BOTH`, mostrar el texto corto fijo.
- Grupo/raid usan la misma opcion de retrato que target jugador: si `portrait_target_player == "trp3"`, intentar aplicar `HarfordTRP3.GetProfileIcon(profile)` sobre el portrait/icon nativo del `CompactUnitFrame`; si es `"wow"`, restaurar retrato WoW con `SetPortraitTexture(portrait, unit)`. Buscar portrait en `frame.portrait`, `frame.Portrait`, `frame.icon`, `frame.Icon` o globals derivados del nombre. No crear portrait propio para party/raid.
- En compact frames de party/raid no usar `IsMouseOver()` durante updates de `CompactUnitFrame`: puede fallar con `Action[FrameMeasurement] failed because[Can't measure restricted regions]` en frames protegidos. El hover debe hacerse con `HookScript("OnEnter"/"OnLeave")`, mostrando `_harfordFullText` al entrar y restaurando `_harfordShortText` al salir.
- En compact frames, el hover es un unico estado del frame padre (`_harfordHovering`), aunque el evento llegue desde el `CompactUnitFrame`, `healthBar` o `powerBar`. Todos esos hooks deben llamar al mismo handler (`CompactHoverEnter/CompactHoverLeave`) para evitar dobles hovers donde una barra no muestre salud.
- El `OnLeave` de compact frames debe limpiar con un pequeno delay/token, no inmediatamente. Esto evita parpadeos al mover el cursor entre el frame padre y barras internas sin usar `IsMouseOver()`.
- Si Blizzard reescribe el compact frame durante hover, el overlay debe respetar `_harfordHovering` y volver a poner `_harfordFullText`; si no, el texto aparece un instante, parpadea y desaparece.
- Los eventos de grupo/raid son event-driven: `GROUP_ROSTER_UPDATE`, `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UNIT_NAME_UPDATE`, `UNIT_PORTRAIT_UPDATE`, `CHAT_MSG_ADDON` y cambios de config. No usar ticker continuo para party/raid.
- Al entrar en modo `"frame"`, `HarfordUnitFrames` debe deshacer efectos del modo integrado para player y target: restaurar frame nativo, nivel/textos de barras, class/combo widgets ocultos y esconder todas las piezas Harford (`portraitLayer`, barras extra, nativeTexts, fallback, level/name overlays). Despues de restaurar, puede aplicar solo el retrato nativo/TRP3 con `ApplyNativePortraitOption(unit)` segun las opciones de retrato. `ReapplyNativeBars` y los hooks de power/text deben ser no-op en modo `"frame"`.
- Tras `RestoreNativeFrameContents(unit)` en modo `"frame"`, llamar a funciones FrameXML nativas cuando existan (`PlayerFrame_Update`, `TargetFrame_Update`, `UnitFrameHealthBar_Update`, `UnitFrameManaBar_Update`, `TextStatusBar_UpdateTextString`) y despues reconstruir health/power desde `UnitHealth`, `UnitHealthMax`, `UnitPower`, `UnitPowerMax` y `PowerBarColor`. Restaurar alpha/textos no basta: las barras pueden quedarse con min/max/value/color de Harford hasta que Blizzard repinte.
- En party/raid, no restaurar valor/color desde `compactBarState`: ese snapshot puede estar contaminado por Harford o por el estado pendiente negro. `RestoreGroupNativeBar` solo existe como limpieza legacy; el flujo normal ya no debe poblar `compactBarState`.
- `/harforddebug run groupframes` debe incluir `barColor`, `texColor` y `value/min-max` de la barra de salud para distinguir si el fallo de raid viene de color, textura interna o rango/valor.
- Expone `HarfordUnitFrames.GetFrame(unit)` para que `HarfordAdminUnitMenu` pueda anclarse al frame Harford en lugar del frame nativo oculto.
- Si no hay recursos cacheados para un jugador remoto, no dejar las barras Blizzard con su valor nativo porque al cambiar target pueden verse llenas hasta que llegue `RES`. En modo unitframe integrado, las barras nativas controladas por Harford deben ponerse en estado pendiente: `0/1`, valor `0`, sin texto, salud verde oscura y recurso/fondo oscuro. No pintar `PG --/--   PM --/--`: el fallback textual dentro de barras genera ruido visual.
- La primera barra de recurso del target usa la barra nativa de power/mana (`TargetFrameManaBar`) y Blizzard puede repintarla despues de `PLAYER_TARGET_CHANGED` con power/numeros normales. Harford debe post-hookear los caminos de power/text (`TargetFrame_Update`, `TargetFrame_UpdatePower`, `UnitFrameManaBar_Update`, `TextStatusBar_UpdateTextString*` cuando afecten a `TargetFrameManaBar`) y llamar `ReapplyNativeBars("target")` para reaplicar inmediatamente el estado Harford o pendiente, incluido ocultar `TextString`/`LeftText`/`RightText`. `ApplyNativeStatusBar`/`ApplyPendingNativeStatusBar` marcan `_harfordApplying` mientras escriben `SetValue` para evitar bucles con `OnValueChanged`.
- Para `target` jugador, si no hay recursos en cache, pide recursos con `HarfordDnDAPI.RequestResourcesForName` con throttle interno.
- El texto de cada barra debe ocupar todo el contenedor de barra (`SetAllPoints`, `CENTER`, `MIDDLE`) y vivir en una capa superior al `StatusBar`, para quedar centrado y visible siempre.
- Las barras tienen dos estados de texto segun el CVar `statusTextDisplay` (via `GetStatusTextMode()`):
  - **NUMERIC/PERCENT/BOTH**: texto corto siempre visible (solo valores: `cur/max`, `pct%`, `cur/max (pct%)`). En hover cambia al texto completo con el nombre del recurso DnD (`Salud cur/max`, etc.).
  - **NONE**: sin texto por defecto. En hover muestra el texto completo con nombre y valores numericos.
- Dos funciones de formato: `FormatShortText(cur, max)` (valores sin nombre, para estado normal) y `FormatFullText(label, cur, max)` (nombre + valores, para hover). `FormatBarText` fue eliminada.
- Para barras 1-2: `HookScript("OnEnter"/"OnLeave")` sobre la barra nativa (una vez, `_harfordHooked`). El hook lee `_harfordFullText` en Enter y `_harfordShortText` en Leave. `ReapplyNativeBars` (UNIT_HEALTH/UNIT_POWER_UPDATE) comprueba `IsMouseOver()` para aplicar el texto correcto sin interrumpir el estado de hover activo.
- Para barras 3+: `OnEnter` muestra `_harfordFullText`, `OnLeave` restaura `_harfordShortText` (o oculta si NONE). No existe `ShouldShowBarText()` — fue eliminada.
- Se refresca por eventos (`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_TARGET_CHANGED`, `UNIT_PORTRAIT_UPDATE`, `UNIT_NAME_UPDATE`, `UNIT_AURA`, `UNIT_HEALTH`, `UNIT_POWER_UPDATE`, `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED`, `CHAT_MSG_ADDON`, `CVAR_UPDATE`) y cuando `HarfordDnD` refresca o cambia recursos. `CVAR_UPDATE` solo dispara cuando el cvar es `statusTextDisplay`. `UNIT_HEALTH` y `UNIT_POWER_UPDATE` llaman solo a `ReapplyNativeBars(unit)` (re-aplica fill/color de barra + texto en `nativeBar.TextString` sin reconstruir el frame completo; necesario porque Blizzard resetea estos valores en UNIT_POWER_UPDATE) y retornan inmediatamente. El resto de eventos llaman a `API.Refresh(forceMeasure)`.
- Recalibrar con `force=true` en login/world/target/escala/resolucion para recoger cambios de posicion, escala o layout.
- Debug secundario:
  - `/harforddebug run ufmeasure player|target|focus`: imprime el layout calculado, piezas nativas detectadas y texturas de fondo/relleno usadas.
  - `/harforddebug run ufcompare player|target|focus`: compara bounds Harford contra la medicion y muestra frame levels de fondo, relleno, texto y overlay.
  - `/harforddebug run groupframes`: lista frames de party/raid detectados, unidad, visibilidad y barras nativas (`health`/`power`) para diagnosticar clientes Epsilon/custom.
  - `/harforddebug run barslot player|target|focus`: imprime UV/posicion de los `barSlotOverlays`.
  - `/harforddebug run totlayer`: imprime parent/strata/level de `TargetFrameToT`, frame Harford target, `barSlotsFrame`, anchor points actuales del ToT y estado `totDesired`.
  - `/harforddebug run totpieces`: lista globals/campos/hijos `StatusBar` candidatos dentro de `TargetFrameToT`.
  - `/harforddebug run totwatch [segundos]`: observa eventos/update de `TargetFrameToT` y valores de barras durante unos segundos.
  - `/harforddebug run totportrait`: diagnostica el portrait overlay del ToT — si existe `totBarsOverlay.portraitFrame`, si esta visible, que textura tiene y que devuelve TRP3 para `targettarget`. Util para depurar por que no aparece el icono TRP3.
  - `/harforddebug run totspy [segundos]`: hookea metodos de `TargetFrameToTManaBar` con `hooksecurefunc` para capturar quien los llama. NO removible; solo para diagnostico puntual. Confirmo: `TargetofTarget_Update` y `OnValueChanged` disparan SetStatusBarColor/SetValue ~12x/s.
  - `/harforddebug run totscripts`: lista scripts registrados en barras y frames del ToT (`OnUpdate`, `OnValueChanged`, etc.).
  - `/harforddebug run totrate [segundos]`: mide frecuencia de llamadas a `TargetofTarget_Update`, eventos `UNIT_HEALTH`/`UNIT_POWER_UPDATE`, y contador de `RefreshTargetOfTargetBars`.
  - Estos comandos solo verifican la calibracion; el render normal no depende de ejecutarlos.
- No usar ticker continuo para esta capa visual.
- El frame Harford (`SecureUnitButtonTemplate`) tiene `EnableMouse(false)`: el frame nativo (PlayerFrame/TargetFrame) permanece visible y funcional y maneja click-to-target, menu contextual y tooltips de buffs. Si Harford captura mouse bloquea los buff/debuff icons del target frame. No volver a activar mouse en el frame raiz de Harford sin una razon explicita.

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
