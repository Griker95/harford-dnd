# Harford — Instrucciones para Claude Code

Addon de WoW (Lua, Interface 45745, servidor Epsilon RP) que implementa D&D 5e como sistema de roleplay.
**Lee `AGENTS.md` antes de tocar cualquier módulo** — contiene contratos, limitaciones Epsilon y enfoques fallidos.

## Reglas de trabajo

- Responde al usuario en **español**.
- Código y comentarios en español.
- No crear archivos nuevos salvo petición explícita. Preferir editar los existentes.
- No agregar comentarios genéricos — solo el WHY no obvio.
- Al confirmar una limitación, patrón o bug nuevo, actualizar `AGENTS.md` en la sección correspondiente.
- Los diagnósticos temporales van en `HarfordDebug.lua` con `RegisterCommand`, nunca en módulos de gameplay.
- **Todo comportamiento exclusivo de modo DM va en `HarfordAdmin/`**, nunca en el core `Harford/`. El core puede exponer callbacks sobrescribibles (patron `HarfordTRP3.InsertGlanceLink(glance)`); HarfordAdmin los reemplaza en su `PLAYER_LOGIN`. No poner `if HarfordAuthority.IsDMMode()` en modulos core para cambiar comportamiento de UI o acciones: eso es responsabilidad de HarfordAdmin.
- **`ClearTarget()` es protegida**: no llamarla desde addon (core ni Admin) — dispara "blocked from an action only available to the Blizzard UI". No hay equivalente inseguro (`RunMacroText("/cleartarget")`/`TargetUnit` tambien protegidas). El "Modo combate" no deselecciona el target.
- **Modelo de autoridad de 3 ejes**: (1) **Oficial** `HarfordAuthority.IsOfficerPlus()` → el core puede emitir comandos de servidor ligeros sin datos de Admin (daño en bruto a NPC al tirar via `SetNpcHealthDelta`, sin resistencias); la modificacion de vida al tirar daño vive en el core (NPC oficial + jugador `RADJ`). (2) **DM+Admin** `HarfordAuthority.CanUseDMTools()` → exclusivo de `HarfordAdmin/`. (3) **Recepcion/render** → siempre en el core. Usar solo `HarfordAuthority.*` para la señal; no leer `HarfordAdminAPI.IS_ADMIN` ni `C_Epsilon`/`ARC` directo desde core.
- La ficha core solo acepta contextos neutrales con `HarfordDnDAPI.ApplySheetContext(context)`. Construir/cargar un contexto NPC desde TRP3, incluidos sus estados de ataque convertidos a `context.actions` y `context.kind = "npc"` + `context.spellProficiencyBonus` exclusivo para informacion/tiradas de `Ataque Conjuro`/`CD Conjuro`, activar el boton de modo NPC y editar recursos remotos son herramientas exclusivas de `HarfordAdmin`; `HarfordDnD.lua` solo renderiza/tira el contexto recibido y debe ignorar ese bonus en cualquier contexto no NPC.
- **Flujo NPC atacante/victima**: modo normal sigue al NPC target (otro NPC reemplaza la ficha, `Atacar` activo y `Daño` inactivo); al targetear un jugador conserva la ficha anterior y habilita solo `Daño`; sin target deshabilita ambos. `Shift+click` marca/fija `npcSourceGuid` y `titleText = "[Nombre]"` solo localmente: el mismo GUID habilita solo `Atacar`, cualquier unidad distinta habilita solo `Daño`, incluidos otros NPC. `rollName` siempre queda sin corchetes. `onAttackAnimation` usa `SetNpcEmote(id)` sobre el NPC ficha. Los ataques pueden tener `action.damageComponents` multiples (`2d8 + 4 perforante + 1d4 necrotico`): el core tira cada componente, aplica `HarfordDamageMitigation.ForTarget("target", tipo, total)` y muestra el daño ya mitigado con marcador `R`/`V`/`I` en la tirada publica. `HarfordAdminNPC.ApplyNpcSheetDamage` recibe ese total ya mitigado y solo llama `SetNpcHealthDelta(-danoAplicado)`; no re-mitiga ni imprime lineas locales de defensa. Si `Atacar` es `CRÍTICO`, `HarfordDnD` guarda una carga para esa accion y el siguiente `Daño` usa el maximo de todos sus dados, conserva bonus fijos y despues aplica las defensas por tipo; se consume al usarla y otra tirada de ataque no critica la limpia. `SetNpcHealthDelta` centraliza ademas `npc emote 33` (`ONESHOT_WOUND`) o `npc emote 34` (`ONESHOT_WOUND_CRIT`, con `opts.isCritical`) sobre la victima cuando cualquier ruta le resta mas de 1 de vida; no se ejecuta al restar solo 1. Las defensas no se aplican a victimas jugador.
- En ficha NPC, `Atacar` intenta resolver CA contra `focus` si existe; sin `focus` mantiene el comportamiento anterior. El editbox `CA` usa esa misma unidad activa (`focus` si existe, si no `target/ficha`) y se refresca en `PLAYER_FOCUS_CHANGED`. Esto no cambia el objetivo de la animacion ni el flujo del boton `Daño`, que siguen usando/validando `target`.
- **Daño NPC contra jugador**: si el target jugador es el propio cliente, `HarfordDnD` aplica el daño localmente con `AdjustResourceCurrent`, consumiendo primero `temp_health` y luego `health`; no depende de `RemoteCache`. Si el target es otro jugador, usa la cache remota para calcular temp/health y envía `RADJ` al cliente objetivo.
- **Control rapido de posesion NPC**: `Ctrl+click` en el boton `Modo NPC` de la ficha con NPC target llama exclusivamente a `HarfordServerActions.RepossessCurrentNpc({ addonName = "HarfordAdmin" })`, que envia la cadena fija `unposs`/`poss` mediante `HarfordEpsilonCommands.SendChain`; con target jugador o sin target llama `UnpossessCurrentNpc` y envia solo `unposs`. El gesto requiere Admin + `.ph dm`, revalida NPC actual cuando procede, no cambia el contexto de ficha y nunca acepta comandos libres.
- **Limite de 200 locales en `HarfordDnD.lua`** (~139 tras modularizar): el contexto temporal vive en `HarfordDnDContext.State` (alias local `SheetContext`); no desglosarlo en nuevos locales de file-scope. Datos/calculo/red/tiradas/layout/perfil/progresion estan en modulos `HarfordDnD*` (Context/UI/Data/Book/Progression/FeatureEffects/Weapons/Calc/Net/Minimap/Rolls/Profile) — añadir alli antes que en el chunk principal. El runtime profile se lee en vivo de `HarfordDnDStore.state.runtime` (no recrear el alias `RuntimeProfile` ni el sync-hook de Context). Encapsular ampliaciones grandes en `do...end` o tablas de estado.
- **Links de estados TRP3 en DM**: `HarfordTRP3.CreateGlanceLink(glance)` es la puerta de creacion solo para estados ajenos y cachea por `TI`/`TX`/`IC`. Sin DM, se inserta `[TRP3:id]`. En DM con NPC target, `HarfordAdminNPC` envia `npc te <hyperlink totalrp3>` mediante `HarfordServerActions.SendNpcTRP3Hyperlink`; si no puede emitirlo, imprime el hyperlink local como fallback.
- **Links nativos TRP3**: no enganchar `ChatFrame_OnHyperlinkShow`, no sobrescribir `OpenMakeImportablePrompt` ni `AtFirstGlanceChatLinksModule.InsertLink`. Los links ya visibles y los estados propios los procesa TRP3 sin intervención Harford.
- **Envio NPC de links TRP3 confirmado**: se valido en Epsilon que el hyperlink completo via `EpsilonLib.AddonCommands` genera un mensaje NPC clicable y resuelve tooltip en dos clientes; el marcador `[TRP3:id]` no sirve. Solo aceptar hyperlinks reconocidos por `HarfordTRP3.IsKnownGlanceHyperlink`; mantener `/harforddebug run trp3npctest hyperlink` como prueba de regresion.
- **No enviar `npc info`**: la carga de fichas NPC usa TRP3 local. `HarfordAdminNPC.GetTargetInfo` y `/harfordadmin npc info` estan neutralizados y no deben volver a ejecutar ese comando servidor sin una feature explicitamente aprobada.
- **Salv Muerte**: en la ficha core reutiliza los bonus/modo de `Salv CON`, presenta contador coloreado compacto `fallos|exitos` sin signos ni corchetes desde `0|0`, centra el unico boton visible en cada refresh y no debe bloquear el acceso al frame de `Recursos`. Al recuperar vida desde estado moribundo con animaciones activadas debe retirar la aura 29266 incluso si `deathAuraActive` local se perdio.
- `AdjustResourceCurrent` refresca `ResourceFrame` si esta visible; no retirar ese refresh porque la recuperacion de `Salv Muerte` debe reflejar el punto de salud al instante.
- **Titulo de ficha**: en modo jugador permanece `Harford DnD 5ª - Ficha`; no usar nombre/color TRP3 del jugador en esa cabecera. Solo el contexto NPC aplicado desde Admin puede sustituirlo.
- **Sonido y serializacion de tiradas**: TRP3 usa el sound kit `36629`. `HarfordDnDRolls.Broadcast` lo reproduce solo en tiradas locales reales; usa `TRP3_API.ui.misc.playSoundKit` si existe y no debe reproducirse desde el render/receptor del chat. El payload de tiradas sigue siendo de 10 campos por `^`, pero los campos de texto se escapan (`%`, `^`, saltos de linea) para no romper nombres/links/etiquetas; no volver a parsear por strings crudos sin escape.
- **HarfordActionSequence y sonido TRP3e**: los comandos de secuencia usan `EpsilonLib.AddonCommands`; solo el paso `TRP3e_Sound_playLocalSoundID` usa TRP3e. No añadir resets automaticos (`stopLocalSoundID`/`stopSoundID`) antes del play: SpellCreator no los usa y esos intentos no arreglaron las segundas ejecuciones.
- **CA / Armor Class**: jugador persiste `ArmorClass`, viaja en `ProfileKeys.DnDBase/DnD` y se incluye en recursos, pero el editbox `CA` de Ataque muestra/edita la CA del **target actual**. Sin target cae a ficha activa/propia. `Ataque Arma` delega en `HarfordDnDCombat.ResolveArmorClassOutcome`: NPC = Turnos, override local, TRP3; jugador = TRP3 About/Currently (`CA: 14`, `Armadura <texto> 14`), cache actual de recursos, override local, ficha/perfil local. Muestra `vs CA N Superada/No superada` y, si impacta, tira automaticamente el daño de arma.
- **Critico de arma del jugador**: `Ataque Arma` con `CRÍTICO` guarda `HarfordDnDStore.pendingWeaponCriticalKey`; el siguiente `Daño Arma` maximiza todos los dados solo si sigue seleccionada esa arma y consume la marca siempre. No anadir locales de file-scope para este estado. `Ataque Conjuro` no tiene actualmente tirada de daño automatizada asociada.

- **Panel de personaje/progresion**: el icono de tabardo de la ficha abre `HarfordCharacterPanel` (primera pestaña `Ficha`). `Creacion` prepara caracteristicas base; `Subida` usa `HarfordDnDBook`, `HarfordDnDProgression` y `HarfordDnDFeatureEffects`; `Reputacion` embebe el panel real `HarfordReputationUI` mediante `EmbedInto`/`DetachEmbedded`, sin duplicar su lista ni abrir otra ventana. El estilo objetivo replica CharacterFrame/SL: retrato circular en cabecera y tabs inferiores. Para replicar la pestaña `Ficha`, las fuentes son `FrameDump.lua` y `Harford.lua`/`HarfordFrameProbe` (`/harforddebug probeframe CharacterFrame`); usar esas capturas como geometria/arte controlados, no clonar scripts/eventos del `CharacterFrame` vivo. La pestaña `Ficha` usa canvas de frame completo para coordenadas nativas (`CharacterFrameInset 4,-60`, modelo `52,-66`, inset derecho desde `CharacterFrameInset`) y texturas del probe: `UI-Background-Rock/Marble`, `UI-Character-Info-Title`, `UI-Character-Info-<Class>-BG`, `PaperDollSidebarTabs` y `Char-Paperdoll-*`. El fondo derecho se elige por clase Harford de mayor nivel y cae a `UnitClass`; el fondo del modelo se elige por `progression.race` usando `Interface\\DressUpFrame\\DressUpBackground-<Race>1..4` y cae a negro si no hay token conocido, nunca copiando el `CharacterModelFrameBackground*` vivo del personaje real. Los slots nunca usan rutas inventadas `UI-PaperDoll-Slot-*` ni copian `Character*SlotIconTexture`: muestran el icono vacio nativo del hueco con `GetInventorySlotInfo`, mas fondo oscuro, `UI-Quickslot2`, `WhiteIconFrame` y `Char-Paperdoll-Parts`. Las tres tabs superiores del panel derecho usan `PaperDollSidebarTabs`: primera con retrato 3D nativo del jugador, y vistas `summary`/`skills`/`details` inspiradas en BG3 con filas compactas. La cabecera de clase usa formato multiclase `Picaro Forajido (3)  Paladin (1)`, sin `|`, coloreando cada entrada por su propia clase via `HarfordClassColors`; en detalles, cada clase va en una linea dentro de la fila `Clase`; nunca `Nivel X - Clase X`. La ficha compacta queda para tiradas: Caract./Ataque/Habilidades. La antigua pestaña `Clases` de `HarfordDnD.lua` fue retirada; no recrear `SEC_CLS` ni `HarfordDnDStore.RefreshClassPanel`.
- **Semilla TRP3 del build**: `HarfordDnDProgression.SeedFromTRP3` rellena clases, raza/subraza y trasfondo desde campos estructurados TRP3 (`RA`/`Raza`/`race`, `BG`/`Trasfondo`/`background`) o etiquetas claras del About (`Clase (nivel)`, `Raza:`, `Subraza:`, `Trasfondo:`/`Origen:`), pero solo cuando el campo correspondiente esta vacio. Si raza/trasfondo no existen en el libro, se guarda el texto raw como valor visual sin rasgos automaticos. `HarfordCharacterPanel.RefreshPanel` llama esta semilla antes de pintar para que abrir `/hchar` no dependa de pasar antes por la ficha compacta. No debe sobrescribir selecciones hechas en `Subida`.
- **Rasgos visibles del panel**: el bloque `Rasgos destacables` de `HarfordCharacterPanel` prioriza rasgos de clase/subclase desbloqueados desde `HarfordDnDProgression`/`HarfordDnDBook` y filtra entradas de magia/conjuros. `HarfordTRP3.GetProfileFeatureLines(profile, limit)` queda como fallback visual y solo debe extraer secciones de clase; no convertir esos textos en efectos automaticos sin contrato nuevo.

## Módulos principales

| Archivo | Rol | Tamaño aprox |
|---|---|---|
| `Harford/HarfordUnitFrames.lua` | Overlays TRP3/DnD sobre frames nativos WoW | ~4400 líneas (~169 locales) |
| `Harford/HarfordClassColors.lua` | Fuente única de color de clase WoW (alias es/en, normalización, RGB/hex). Consumido por UnitFrames/NamePlates/Turns | pequeño |
| `Harford/HarfordUIGeom.lua` | Helpers puros de geometría/búsqueda de StatusBars para overlays | pequeño |
| `Harford/HarfordDnD.lua` | Ficha D&D 5e — UI principal `/FichaHarford`. 3 tabs compactos de tirada (Caract./Ataque/Habilidades); icono tabardo abre `HarfordCharacterPanel` | grande (~139 locales) |
| `Harford/HarfordCharacterPanel.lua` | Panel de personaje de usuario final: Ficha, Creacion, Subida y acceso a Reputacion; usa los modulos DnD* y no sustituye HarfordReputationUI | mediano |
| `Harford/HarfordDnDContext.lua` | Estado de contexto de ficha (`SheetContext`) + accesores `Get`/`Set` (ARCGET/ARCSET). Bisagra que desacopla los helpers del chunk de DnD | pequeño |
| `Harford/HarfordDnDProfile.lua` | Aplica tablas de perfil/recursos sobre `HarfordDnDStore` (hooks EnsureDefaults/RefreshMainUI inyectados) | pequeño |
| `Harford/HarfordDnDUI.lua` | Constantes visuales/layout y fábricas UI pequeñas de la ficha (`SetFrameBackground`, `CreateSection`, `MakeButton`) | pequeño |
| `Harford/HarfordDnDRolls.lua` | Serialización, render en chat, broadcast y sonido de tiradas D&D por `DND5EARC` | pequeño |
| `Harford/HarfordDnDData.lua` | Datos: tablas `ABIL` (características) y `SKILLS` (habilidades) | pequeño |
| `Harford/HarfordDnDBook.lua` | Libro hardcodeado de clases/subclases/rasgos; efectos declarativos, sin Lua arbitrario | pequeño |
| `Harford/HarfordDnDProgression.lua` | Estado por perfil de niveles, featureStates internos y choices; se guarda en `HarfordDnDPersistStore.classProgression` | pequeño |
| `Harford/HarfordDnDFeatureEffects.lua` | Resuelve efectos activos y bonos derivados para Calc/Combat/UI | pequeño |
| `Harford/HarfordDnDWeapons.lua` | Datos: tabla `WEAPONS` + helpers de arma (dados, props, menú) | pequeño |
| `Harford/HarfordDnDCalc.lua` | Cálculo puro: modificadores, dados, bonos. Lee vía `HarfordDnDContext` | pequeño |
| `Harford/HarfordDnDNet.lua` | Recursos/red: export/request/adjust vía HarfordSync. `HarfordDnDAPI` delega aquí | pequeño |
| `Harford/HarfordDnDCombat.lua` | Reglas de combate con contexto de unidad: CA, impacto y aplicación segura de daño de arma a NPC | pequeño |
| `Harford/HarfordDnDMinimap.lua` | Botón de minimapa de la ficha (toggle + reset de posiciones inyectado) | pequeño |
| `Harford/HarfordTurns.lua` | Tracker visual de turnos de combate | grande |
| `Harford/HarfordReputation.lua` | Core de reputaciones: facciones, jugadores, gremios, NPCs, rangos. Sin DEFAULT_FACTIONS; todo en SavedVariables | mediano |
| `Harford/HarfordReputationUI.lua` | Panel flotante `/harfordrep`. Filas custom: hlFrame para highlights (sin clipping), caps OVERLAY -1, Exaltado siempre lleno, `adjustPrompt` para ajuste libre | mediano |
| `Harford/HarfordReputationSync.lua` | Sync de red, prefix `HARFORDREP` | pequeño |
| `Harford/HarfordReputationTooltip.lua` | Hook GameTooltip para NPCs con facción vinculada | pequeño |
| `Harford/HarfordTRP3.lua` | Lectura segura de perfiles TRP3 | mediano |
| `Harford/HarfordDebug.lua` | Sistema de debug — todos los diagnósticos van aquí | mediano |
| `Harford/HarfordSync.lua` | Transporte addon messages (serialización, canales) | mediano |
| `Harford/HarfordNamePlates.lua` | Overlays DnD sobre nameplates nativos/KuiNameplates | mediano |
| `Harford/HarfordCommandTemplates.lua` | Plantillas de comandos Epsilon con placeholders | pequeño |
| `Harford/HarfordEmotes.lua` | Datos de emotes, heridas y posturas de combate | pequeño |
| `Harford/HarfordAuras.lua` | Datos/helpers para auras conocidas por scope | pequeño |
| `Harford/HarfordDamageTypes.lua` | Tipos de daño D&D 5e y normalización de palabras | pequeño |
| `Harford/HarfordDamageMitigation.lua` | Resistencias, inmunidades y vulnerabilidades por stat block TRP3 | pequeño |
| `Harford/HarfordActionSequence.lua` | Motor ligero de secuencias con delay; comandos por EpsilonLib y sonido nearby por TRP3e | pequeño |
| `Harford/HarfordActionSequencePresets.lua` | Catalogo hardcodeado de secuencias decodificadas de SpellCreator; solo datos registrados en el motor | pequeño |
| `Harford/HarfordServerActions.lua` | Comandos Epsilon validados (additem, auras, npc health/emotes, npc te) | pequeño |
| `Harford/HarfordEpsilonCommands.lua` | Wrapper bajo nivel para EpsilonLib/ARC | pequeño |
| `HarfordAdmin/HarfordAdminUnitMenu.lua` | Menú contextual DM en unitframes | mediano |

## Limitaciones Epsilon críticas (no reintentar lo fallado)

- **Strata cross-tree**: hijos de `TargetFrame` NO respetan jerarquía de strata vs frames UIParent. Overlays ToT → **UIParent/MEDIUM** (niveles 82-85, `TOT_OVERLAY_STRATA`). Paneles/ventanas → DIALOG (level 500+). No usar DIALOG para overlays de unitframe: tapa otros addons.
- **TargetofTarget_Update**: corre via `OnUpdate` a ~60fps, restaura barras y portrait nativo del ToT. No escribir en barras nativas del ToT; usar `totBarsOverlay` (UIParent/MEDIUM). Portrait nativo (Texture, no Frame): `SetAlpha(0)` + `_SyncToTNativePortraitAlpha` en cada tick del hook.
- **SetAlpha en barras ToT**: `TargetofTarget_Update` y `OnValueChanged` lo restauran. No usar.
- **PlayerFrameTexture SetAlpha(0)**: no funciona en Epsilon para el player frame.
- **Reposicionar TargetFrameToT físicamente**: `TargetofTarget_Update` resetea anchors entre ticks. No mover el frame nativo — solo gestionar strata/level y cubrir con overlays.
- **Límite de 200 locales Lua 5.1**: `HarfordUnitFrames.lua` roza el límite. Nuevos bloques de funciones deben ir dentro de `do...end` para no añadir locales al scope global. Exponer funciones públicas vía tabla (ver patrón `focusTot`).
- **No ticks continuos**: no usar `C_Timer.NewTicker`, `OnUpdate` permanente ni polling para UI/permisos/nameplates/turnos. Preferir eventos WoW/addon. `OnUpdate` solo mientras dura una interacción real (drag/hover) y se limpia al terminar. **Excepción**: el tracker de movimiento usa `OnUpdate` permanente en `movBtn` con `if not _tracking then return end` como guardia — coste prácticamente cero cuando inactivo.
- **`PLAYER_STARTED_MOVING`/`PLAYER_STOPPED_MOVING`**: pueden no disparar en Epsilon. No usarlos para activar/desactivar lógica de seguimiento de posición.
- **`UnitPosition("player")` en Epsilon**: puede devolver solo `x, y` sin `z` (z = nil). Siempre usar `nz = nz or 0` y guard `if not nx or not ny then return end` antes de cualquier aritmética sobre las coordenadas. Devuelve yards; multiplicar por `0.9144` para metros.
- **Caches de auras de target/focus**: target y focus tienen caches de anclas separados. Limpiar un cache de buff frames sin restaurar antes las posiciones nativas causa drift infinito con cada `UNIT_AURA`. Siempre restaurar antes de limpiar (`RestoreTargetAuras()`/`RestoreFocusAuras()`/`RestoreUnitAuras(unit)`); no compartir anclas entre target y focus.
- **`CHAT_MSG_SYSTEM` para detectar modo DM**: dispara en cualquier mensaje de sistema (kills, quests, etc.). Usar `HarfordAuthority.RegisterChangeListener` para reaccionar a cambios de DM mode.

## Patrones de código recurrentes

```lua
-- Dependencias opcionales: siempre comprobar en runtime
if TRP3_API and TRP3_API.register then ... end
if ARC and ARC.CMD then ... end

-- Overlay UIParent/MEDIUM para ToT/unitframe (no tapa otros addons)
local f = CreateFrame("Frame", nil, UIParent)
f:SetFrameStrata("MEDIUM")
f:SetFrameLevel(82)  -- art=82, barFrame=83, bar=84, portrait=85
f:SetAllPoints(nativeBar)  -- anclaje cross-tree OK para posicionamiento
-- Para paneles/ventanas flotantes: DIALOG level 500+

-- Máscara circular en portrait: aplicar a AMBAS texturas
local mask = pf:CreateMaskTexture(nil, "ARTWORK")
mask:SetTexture(TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mask:SetAllPoints(pf)  -- sobre el frame, no sobre la textura
pbg:AddMaskTexture(mask)   -- fondo Y
ptex:AddMaskTexture(mask)  -- icono — ambos necesarios

-- Registro de diagnóstico temporal en debug
HarfordDebug.RegisterCommand("micomando", function(args)
    -- diagnóstico aquí
end, "Descripción breve del comando")

-- RefreshTargetOfTargetBars / focusTot.refresh() son las fuentes de verdad
-- Llamar desde AMBOS branches de RefreshFrame para unit=="target"/"focus"
-- NUNCA llamar HideToTBarsOverlay() / focusTot.hide() directamente desde RefreshFrame

-- Highlights en panel de reputación: usar hlFrame (Frame hijo del row, SetAllPoints)
-- para evitar clipping de texturas al ancho del StatusBar (101px) en Epsilon.
-- Highlight1 (cuerpo) y Highlight2 (cap) son objetos SEPARADOS — nunca misma ref.
-- OnEnter/OnLeave muestran/ocultan ambos; InitializeRow de header oculta ambos explícitamente.

-- Nameplates: event-driven. No ticker.
-- Kui normal: overlay sobre kui.HealthBar. Kui name-only: overlay bajo kui.NameText.
-- Nativo: overlay simple sobre UnitFrame.healthBar.

-- Buff drift fix: SIEMPRE usar RestoreTargetAuras() en lugar de ClearTargetAuraAnchorCache().
-- RestoreTargetAuras restaura frames a posición nativa ANTES de limpiar el cache.
-- Aplica en: handler UNIT_AURA target + branch de cambio de GUID en AdjustTargetAuras.
-- (Con focus activo, UNIT_AURA "focus" también dispara RefreshFrame("Target") → duplica la deriva)
RestoreTargetAuras()  -- correcto
-- ClearTargetAuraAnchorCache()  -- NUNCA llamar directamente; deja cache vacío sin restaurar

-- HandleAddonMessage (HarfordDnDComm) retorna boolean:
-- true  → cache de recursos remota actualizada (RES / RESCFG / RADJ) → llamar HarfordUnitFrames.Refresh()
-- false → REQ, perfiles, prof flags, tiradas → NO hacer Refresh completo
local resourcesChanged = AddonHandlers.HandleAddonMessage(prefix, message, sender)
if resourcesChanged and HarfordUnitFrames and HarfordUnitFrames.Refresh then
    HarfordUnitFrames.Refresh()
end

-- RequestResourcesFromPlayer: throttle 12s por jugador
-- (tabla _resourceRequestTimes en scope de módulo, no en el handler de evento)

-- Nombres en turnos/sync: siempre cortos (sin realm), igual que claves banco de fichas
local shortName = Ambiguate and Ambiguate(name, "short") or name:match("^[^%-]+") or name

-- Debounce de RefreshReputationViews (HarfordReputationSync):
-- _refreshViewsPending + C_Timer.After(0.1) colapsa rafagas REP/RDELTA en un único refresh.
-- No aplicar a ApplySnapshot (ya es una sola llamada al final del reensamblado).

-- Patrón do...end para añadir funciones sin consumir locales de file-scope
-- (HarfordUnitFrames.lua está al límite de 200 locales Lua 5.1)
do
    local function miFuncionInterna() end
    local function otraFuncion() end
    miTabla.publica = miFuncionInterna
    miTabla.otra    = otraFuncion
end

-- Forward declaration para cerrar sobre una función definida más abajo:
local RefreshTopInfo  -- se declara aquí, se asigna ~N líneas más abajo
local function ConsumeMode()
    if RefreshTopInfo then RefreshTopInfo() end  -- OK aunque aún sea nil al definir
end
-- ... más adelante en el mismo scope:
RefreshTopInfo = function() ... end  -- la asignación "rellena" la upvalue

-- Tracker de movimiento con OnUpdate throttleado (patrón en do...end):
do
    local POLL_INTERVAL = 0.1  -- 10fps
    local _tracking, _elapsed, _totalMeters = false, 0, 0
    local _lastX, _lastY, _lastZ
    local function GetPos()
        if UnitPosition then
            local x, y, z = UnitPosition("player")
            if x and y then return x, y, z or 0 end
        end
        -- fallback C_Map si UnitPosition no está disponible
        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local p = C_Map.GetPlayerMapPosition(mapID, "player")
                if p then return p.x, p.y, 0 end
            end
        end
        return nil
    end
    movBtn:SetScript("OnUpdate", function(_, dt)
        if not _tracking then return end  -- guardia barata: coste ~0 cuando inactivo
        _elapsed = _elapsed + dt
        if _elapsed < POLL_INTERVAL then return end
        _elapsed = 0
        local nx, ny, nz = GetPos()
        if not nx or not ny then return end  -- CRÍTICO: z puede ser nil en Epsilon
        nz = nz or 0
        if _lastX then
            local dist = math.sqrt((nx-_lastX)^2 + (ny-_lastY)^2 + (nz-_lastZ)^2) * 0.9144
            if dist > 0.05 then _totalMeters = _totalMeters + dist end
        end
        _lastX, _lastY, _lastZ = nx, ny, nz
    end)
end
```

## Prefixes de addon messages

| Prefix | Uso |
|---|---|
| `DND5EARC` | Ficha, tiradas, recursos, RADJ |
| `HARFORDLOOT` | Loot resuelto y limpieza remota |
| `HARFORDCFG` | Configuración global de loot |
| `HARFORDTURN` | Estado tracker de turnos |

## Skills disponibles (`/` commands)

- `/harford-debug` — añade un nuevo comando de debug siguiendo el patrón del proyecto
- `/harford-module` — scaffolding para un módulo nuevo
- `/harford-review` — repaso de un módulo contra AGENTS.md

## Patrones de datos D&D

```lua
-- Vida temporal: no está en HarfordDnDResources.ORDER; no aparece como barra propia.
-- Se inyecta en list[1].tempCur antes del render (en nameplates y group overlays).
-- El render usa ApplyAbsorbTexture(tempBar, hpBar, cur, max, tempCur, 0.85):
--   - Kui nameplates: textura Kui_Media\\t\\stippled-bar + spark (ov.tempBar._harfordUseKui=true)
--   - Nativo / party/raid: TEX_ABSORB_FILL (Shield-Overlay) + TEX_ABSORB_EDGE (Shield-Overshield)
--   - Main unitframes: Texture OVERLAY en nativeBar via EnsureNativeAbsorbTexture
-- NO usar TEX_STATUS ni StatusBar plano para temp HP: parece recurso normal, no absorción.

-- Hover compact frames: comportamiento diferente por tipo
-- Party/group: hover es no-op si statusTextDisplay != NONE (texto ya visible)
-- Raid: hover siempre activo; con texto activo muestra fullText en lugar de shortText
-- Distinción vía IsRaidCompactFrame(frame, nil) en SetCompactFrameHoverState y
-- SetGroupOverlayText
```

## Verificación rápida antes de editar

1. ¿El enfoque que voy a usar está en la lista de "enfoques fallidos" de AGENTS.md? → No reintentar.
2. ¿El módulo tiene contrato documentado en AGENTS.md? → Respetar el contrato.
3. ¿Estoy añadiendo diagnóstico temporal? → Va en `HarfordDebug.RegisterCommand`.
4. ¿Estoy creando un overlay de ToT/unitframe? → UIParent/MEDIUM (niveles 82-85). ¿Es un panel/ventana? → UIParent/DIALOG (500+).
