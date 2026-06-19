# Harford — Instrucciones para Claude Code

Addon de WoW (Lua, Interface 45745, servidor Epsilon RP) que implementa D&D 5e como sistema de roleplay.
**Lee `AGENTS.md` antes de tocar cualquier módulo** — contiene contratos, limitaciones Epsilon y enfoques fallidos.

## Reglas de trabajo

- Responde al usuario en **español**.
- Código y comentarios en español.
- No crear archivos nuevos salvo petición explícita. Preferir editar los existentes.
- No agregar comentarios genéricos — solo el WHY no obvio.
- Al confirmar una limitación, patrón o bug nuevo, actualizar `AGENTS.md` en la sección correspondiente.
- **ENCODING: todos los `.lua` son UTF-8 SIN BOM.** WoW/Epsilon renderiza UTF-8; si un `.lua` se guarda como Windows-1252/Latin-1 y se re-guarda como UTF-8 se produce mojibake que sale roto en juego. Ya pasó una vez (HarfordDnD/Progression/UnitFrames/Sync quedaron doble/triple-codificados y se repararon con un colapso de pares mojibake `[0xC2|0xC3]+[0x80-0xBF]` + mapa CP1252, preservando los `─` de 3 bytes). Editar SIEMPRE con herramientas que conserven UTF-8; tras editar, buscar patrones compuestos como `\u00C3\u0192`, `\u00C3\u201A`, `\u00C3\u00A2`, `\u00E2\u20AC` y `\uFFFD`. No buscar `Ã`/`Â` sueltos: pueden aparecer legítimamente en tablas de normalización de acentos.
- Los diagnósticos temporales van en `HarfordDebug.lua` con `RegisterCommand`, nunca en módulos de gameplay.
- **Todo comportamiento exclusivo de modo DM va en `HarfordAdmin/`**, nunca en el core `Harford/`. El core puede exponer callbacks sobrescribibles (patron `HarfordTRP3.InsertGlanceLink(glance)`); HarfordAdmin los reemplaza en su `PLAYER_LOGIN`. No poner `if HarfordAuthority.IsDMMode()` en modulos core para cambiar comportamiento de UI o acciones: eso es responsabilidad de HarfordAdmin.
- **`ClearTarget()` es protegida**: no llamarla desde addon (core ni Admin) — dispara "blocked from an action only available to the Blizzard UI". No hay equivalente inseguro (`RunMacroText("/cleartarget")`/`TargetUnit` tambien protegidas). El "Modo combate" no deselecciona el target.
- **Modelo de autoridad de 3 ejes**: (1) **Oficial** `HarfordAuthority.IsOfficerPlus()` → el core puede emitir comandos de servidor ligeros sin datos de Admin (daño en bruto a NPC al tirar via `SetNpcHealthDelta`, sin resistencias); la modificacion de vida al tirar daño vive en el core (NPC oficial + jugador `RADJ`). (2) **DM+Admin** `HarfordAuthority.CanUseDMTools()` → exclusivo de `HarfordAdmin/`. (3) **Recepcion/render** → siempre en el core. Usar solo `HarfordAuthority.*` para la señal; no leer `HarfordAdminAPI.IS_ADMIN` ni `C_Epsilon`/`ARC` directo desde core.
- La ficha core solo acepta contextos neutrales con `HarfordDnDAPI.ApplySheetContext(context)`. Construir/cargar un contexto NPC desde TRP3, incluidos sus estados de ataque convertidos a `context.actions` y `context.kind = "npc"` + `context.spellProficiencyBonus` exclusivo para informacion/tiradas de `Ataque Conjuro`/`CD Conjuro`, activar el boton de modo NPC y editar recursos remotos son herramientas exclusivas de `HarfordAdmin`; `HarfordDnD.lua` solo renderiza/tira el contexto recibido y debe ignorar ese bonus en cualquier contexto no NPC.
- **Aislamiento de ficha NPC/inspect**: en contexto NPC, `HarfordDnDCalc` no debe consultar `HarfordDnDFeatureEffects` del jugador; solo usa `SheetContext.overrides` + stat block TRP3. `HarfordDnDContext.Set` actualiza overrides existentes si el contexto esta activo, para que editar la ficha NPC no escriba en el perfil local. En inspeccion, el panel debe calcular habilidades/salvaciones con `GetProfileName()`/snapshot remoto, nunca con `HarfordDnDCalc` global del jugador local.
- **Parser NPC TRP3**: si falta ficha/texto, `HarfordTRP3.GetNPCStatBlock` devuelve defaults seguros (`CA 10`, todas las caracteristicas `10/+0`, listas vacias). Las seis caracteristicas aceptan variantes normalizadas (`FUE/Fuerza/STR`, `DES/Destreza/DEX`, `CON/Cons/Constitucion`, `INT/Inteligencia`, `SAB/Sabiduria/WIS`, `CAR/Carisma/CHA`), con tildes/mayusculas/guion inicial y modificador opcional. No duplicar este parser en Admin.
- **Flujo NPC atacante/victima**: modo normal sigue al NPC target (otro NPC reemplaza la ficha, `Atacar` activo y `Daño` inactivo); al targetear un jugador conserva la ficha anterior y habilita solo `Daño`; sin target deshabilita ambos. `Shift+click` marca/fija `npcSourceGuid` y `titleText = "[Nombre]"` solo localmente: el mismo GUID habilita solo `Atacar`, cualquier unidad distinta habilita solo `Daño`, incluidos otros NPC. `rollName` siempre queda sin corchetes. `onAttackAnimation` usa `SetNpcEmote(id)` sobre el NPC ficha. Los ataques pueden tener `action.damageComponents` multiples (`2d8 + 4 perforante + 1d4 necrotico`): el core tira cada componente, aplica `HarfordDamageMitigation.ForTarget("target", tipo, total)` y muestra el daño ya mitigado con marcador `R`/`V`/`I` en la tirada publica. `HarfordAdminNPC.ApplyNpcSheetDamage` recibe ese total ya mitigado y solo llama `SetNpcHealthDelta(-danoAplicado)`; no re-mitiga ni imprime lineas locales de defensa. Si `Atacar` es `CRÍTICO`, `HarfordDnD` guarda una carga para esa accion y el siguiente `Daño` usa el maximo de todos sus dados, conserva bonus fijos y despues aplica las defensas por tipo; se consume al usarla y otra tirada de ataque no critica la limpia. `SetNpcHealthDelta` centraliza ademas `npc emote 33` (`ONESHOT_WOUND`) o `npc emote 34` (`ONESHOT_WOUND_CRIT`, con `opts.isCritical`) sobre la victima cuando cualquier ruta le resta mas de 1 de vida; no se ejecuta al restar solo 1. Las defensas de jugador se aplican si `HarfordDamageMitigation.ForTarget` encuentra una entrada en la lista derivada de defensas del perfil (`damageStatusCache`, ej. CdM `Constitucion No-Muerta` => veneno resistente); si falta snapshot Harford de un jugador remoto, puede poblarla de forma efimera desde su About TRP3; como ultimo fallback lee stat block TRP3. Si no hay dato, el daño queda normal.
- En ficha NPC, `Atacar` intenta resolver CA contra `focus` si existe; sin `focus` mantiene el comportamiento anterior. El editbox `CA` usa esa misma unidad activa (`focus` si existe, si no `target/ficha`) y se refresca en `PLAYER_FOCUS_CHANGED`. Esto no cambia el objetivo de la animacion ni el flujo del boton `Daño`, que siguen usando/validando `target`.
- **Daño NPC contra jugador**: si el target jugador es el propio cliente, `HarfordDnD` aplica el daño localmente con `AdjustResourceCurrent`, consumiendo primero `temp_health` y luego `health`; no depende de `RemoteCache`. Si el target es otro jugador, usa la cache remota para calcular temp/health y envía `RADJ` al cliente objetivo. Esto se conserva por compatibilidad con versiones antiguas, pero la evolución correcta será enviar daño bruto y que el receptor lo resuelva (reacciones/mitigación -> vida temporal -> salud).
- **Control rapido de posesion NPC**: `Ctrl+click` en el boton `Modo NPC` de la ficha con NPC target llama exclusivamente a `HarfordServerActions.RepossessCurrentNpc({ addonName = "HarfordAdmin" })`, que envia la cadena fija `unposs`/`poss` mediante `HarfordEpsilonCommands.SendChain`; con target jugador o sin target llama `UnpossessCurrentNpc` y envia solo `unposs`. El gesto requiere Admin + `.ph dm`, revalida NPC actual cuando procede, no cambia el contexto de ficha y nunca acepta comandos libres.
- **Limite de 200 locales en `HarfordDnD.lua`** (~139 tras modularizar): el contexto temporal vive en `HarfordDnDContext.State` (alias local `SheetContext`); no desglosarlo en nuevos locales de file-scope. Datos/calculo/red/tiradas/layout/perfil/progresion estan en modulos `HarfordDnD*` (Context/UI/Data/Book/Progression/FeatureEffects/Weapons/Calc/Net/Minimap/Rolls/Profile) — añadir alli antes que en el chunk principal. El runtime profile se lee en vivo de `HarfordDnDStore.state.runtime` (no recrear el alias `RuntimeProfile` ni el sync-hook de Context). Encapsular ampliaciones grandes en `do...end` o tablas de estado.
- **Links de estados TRP3 en DM**: `HarfordTRP3.CreateGlanceLink(glance)` es la puerta de creacion solo para estados ajenos y cachea por `TI`/`TX`/`IC`. Sin DM, se inserta `[TRP3:id]`. En DM con NPC target, `HarfordAdminNPC` envia `npc te <hyperlink totalrp3>` mediante `HarfordServerActions.SendNpcTRP3Hyperlink`; si no puede emitirlo, imprime el hyperlink local como fallback. Si hay `focus`, se anexa su nombre plano (RP TRP3 o WoW) DESPUES del hyperlink via `opts.textSuffix` => `npc te [estado] <Focus>`; `opts.textPrefix` (Ctrl+prompt) sigue yendo ANTES. Sin focus no se anexa nada.
- **Links nativos TRP3**: no enganchar `ChatFrame_OnHyperlinkShow`, no sobrescribir `OpenMakeImportablePrompt` ni `AtFirstGlanceChatLinksModule.InsertLink`. Los links ya visibles y los estados propios los procesa TRP3 sin intervención Harford.
- **Envio NPC de links TRP3 confirmado**: se valido en Epsilon que el hyperlink completo via `EpsilonLib.AddonCommands` genera un mensaje NPC clicable y resuelve tooltip en dos clientes; el marcador `[TRP3:id]` no sirve. Solo aceptar hyperlinks reconocidos por `HarfordTRP3.IsKnownGlanceHyperlink`; mantener `/harford debug run trp3npctest hyperlink` como prueba de regresion.
- **No enviar `npc info`**: la carga de fichas NPC usa TRP3 local. `HarfordAdminNPC.GetTargetInfo` y `/harfordadmin npc info` estan neutralizados y no deben volver a ejecutar ese comando servidor sin una feature explicitamente aprobada.
- **Salv Muerte**: en la ficha core reutiliza los bonus/modo de `Salv CON`, presenta contador coloreado compacto `fallos|exitos` sin signos ni corchetes desde `0|0`, centra el unico boton visible en cada refresh y no debe bloquear el acceso al frame de `Recursos`. Al recuperar vida desde estado moribundo con animaciones activadas debe retirar la aura 29266 incluso si `deathAuraActive` local se perdio. Los desenlaces (`recupera 1 PG` al llegar a 3 exitos, `queda incapacitado` a 3 fallos) se **comparten al resto de clientes** via `HarfordDnDRolls.Broadcast({ type = "info", label = ... })`; `DisplayInChat` renderiza el tipo `info` como `[D&D] Nombre <texto>` (sin `: total` ni sonido). No usar `DEFAULT_CHAT_FRAME:AddMessage` local para mensajes que deban verse en mesa.
- `AdjustResourceCurrent` refresca `ResourceFrame` si esta visible; no retirar ese refresh porque la recuperacion de `Salv Muerte` debe reflejar el punto de salud al instante.
- **Titulo de ficha**: en modo jugador permanece `Harford DnD 5ª - Ficha`; no usar nombre/color TRP3 del jugador en esa cabecera. Solo el contexto NPC aplicado desde Admin puede sustituirlo.
- **Sonido y serializacion de tiradas**: TRP3 usa el sound kit `36629`. `HarfordDnDRolls.Broadcast` lo reproduce solo en tiradas locales reales; usa `TRP3_API.ui.misc.playSoundKit` si existe y no debe reproducirse desde el render/receptor del chat. El payload de tiradas sigue siendo de 10 campos por `^`, pero los campos de texto se escapan (`%`, `^`, saltos de linea) para no romper nombres/links/etiquetas; no volver a parsear por strings crudos sin escape. **Label de RED con item link COMPACTADO (sigue clicable)**: `Serialize` pasa la `label` por `NetworkLabel` → `CompactItemLinks`, que reduce el item link a su forma mínima `|Hitem:<id>|h[<nombre>]|h|r` (regex `(|Hitem:%d+)[^|]-|h` → `%1|h`, quita la larga cadena de stats) y acota a 200 chars. El link compacto **sigue siendo clicable en el cliente ajeno** (WoW reconstruye el tooltip desde el ID) y ocupa pocos bytes. **CONSERVA color (`|c..|r`), nombre visible y pipes escapados** para que la tirada salga IGUAL en origen y destino (p.ej. el contador coloreado `fallos|exitos` de Salv Muerte vía `FormatDeathCounter`). **NO** strippear `|c`/`|r` ni el hyperlink completo aquí: lo primero rompía el color en el cliente ajeno, lo segundo quitaba la clicabilidad. Motivo del compactado: `WeaponRollName` mete el `itemLink` completo en la etiqueta y `HarfordSync.Send` NO trocea las tiradas; el link completo desbordaría el límite de ~255 bytes. El chat LOCAL conserva el link completo original (DisplayInChat usa `rollData.label`); la red manda el link compacto clicable. **Guard de tamaño del payload (entrega garantizada)**: ademas del cap de 200 chars de `NetworkLabel`, `Serialize` mide el payload COMPLETO (10 campos) y recorta SOLO la label hasta que cabe en `MAX_SAFE_PAYLOAD_BYTES` (240, margen bajo el limite ~255 de `SendAddonMessage`), cerrando con `SanitizeLabelTail` cualquier `|c..` partido. Sin esto, una label larga (p.ej. `Exponer Armadura: Ataque [arma] +1 <Target> (nota larga)` daba ~280 bytes) hacia que `SendAddonMessage` descartara el mensaje y la tirada NO llegara al receptor (sintoma: log `roll send ... bytes=280 OK` pero el target no la ve). El recorte solo afecta a la RED (DisplayInChat local usa la label completa). **Tiradas de ataque a otro jugador (whisper extra)**: si `rollData.targetUnit` apunta a un jugador distinto de uno mismo, `Broadcast` envia la tirada por `BestChannel()` (RAID/PARTY) Y ADEMAS por `WHISPER` al objetivo cuando NO esta en tu grupo (en grupo ya la recibe por el canal y no se duplica; solo, igual le llega por whisper). Lo marcan `Ataque Arma`/`Ataque Conjuro`/maniobras (`targetUnit="target"`) y el ataque NPC→jugador (`targetUnit="focus"`; si el focus es NPC, el guard `UnitIsPlayer` lo ignora). El receptor procesa la tirada por WHISPER igual que por RAID (el handler `DND5EARC` no filtra por canal).
- **HarfordActionSequence y sonido TRP3e**: los comandos de secuencia usan `EpsilonLib.AddonCommands`; solo el paso `TRP3e_Sound_playLocalSoundID` usa TRP3e. No añadir resets automaticos (`stopLocalSoundID`/`stopSoundID`) antes del play: SpellCreator no los usa y esos intentos no arreglaron las segundas ejecuciones.
- **CA / Armor Class**: jugador persiste `ArmorClass`, viaja en `ProfileKeys.DnDBase/DnD` y se incluye en recursos, pero el editbox `CA` de Ataque muestra/edita la CA del **target actual**. Sin target cae a ficha activa/propia. `Ataque Arma` delega en `HarfordDnDCombat.ResolveArmorClassOutcome`: NPC = Turnos, override local, TRP3; jugador = **TRP3 "Other Information" (CO) / "Currently" (CU)** (`CA: 14`, `Armadura <texto> 14`) con prioridad, luego **CA de la armadura EQUIPADA** (`GetEquippedArmorClass`, con Destreza por categoria + escudo + bonus). **La CA manual de la ficha quedo OBSOLETA** y ya no se usa en `GetSelfArmorClass` (sin armadura equipada cae a desarmado 10 + Mod. Destreza). **CA efectiva enviada a otros**: `HarfordDnDCombat.ComputeSelfArmorClass()` = TRP3 CO/CU si hay valor, si no la armadura equipada; `RefreshArmorClassBoxes` la persiste en `ArmorClass` y re-broadcast (`ScheduleMyResourceBroadcast`) solo si cambia y fuera de modo NPC, de modo que otros clientes ven tu CA de equipo (un valor en TRP3 "Other Information"/CO manda por encima). Muestra `vs CA N Superada/No superada` y, si impacta, tira automaticamente el daño de arma.
- **Critico de arma del jugador**: `Ataque Arma` con `CRÍTICO` guarda `HarfordDnDStore.pendingWeaponCriticalKey`; el siguiente `Daño Arma` maximiza todos los dados solo si sigue seleccionada esa arma y consume la marca siempre. No anadir locales de file-scope para este estado. `Ataque Conjuro` no tiene actualmente tirada de daño automatizada asociada.
- **Cabecera de daño POR TIPO**: tanto `RollWeaponDamage` (daño de arma del jugador, base + extra + condicionales tipo Golpe Runico) como `RollActionDamage` (daño NPC multi-componente) agregan el daño YA MITIGADO por tipo y muestran la cabecera como "N Tipo [R/V/I]" por cada tipo (p.ej. `9 Cortante 7 Frio`), no un total unico mal etiquetado. Para encajar en el render `<total> <modifiers>`, el `total` del broadcast es el del PRIMER tipo y `modifiers` lleva el resto de tipos; los numeros de los tipos extra se colorean con `|cff66ccff` (igual que el total de cabecera) y los nombres de tipo se capitalizan. El valor devuelto por la funcion sigue siendo el GRAN total (para aplicar el daño); solo cambia la presentacion. No asumir que el campo `total` de un broadcast de daño es la suma de todos los tipos.

- **Panel de personaje/progresion**: el icono de tabardo de la ficha abre `HarfordCharacterPanel` (primera pestaña `Ficha`). `Creacion` prepara caracteristicas base; `Subida` usa `HarfordDnDBook`, `HarfordDnDProgression` y `HarfordDnDFeatureEffects`; `Reputacion` embebe el panel real `HarfordReputationUI` mediante `EmbedInto`/`DetachEmbedded`, sin duplicar su lista ni abrir otra ventana. El estilo objetivo replica CharacterFrame/SL: retrato circular en cabecera y tabs inferiores. Para replicar la pestaña `Ficha`, las fuentes son `FrameDump.lua` y `Harford.lua`/`HarfordFrameProbe` (`/harford debug run probeframe CharacterFrame`); usar esas capturas como geometria/arte controlados, no clonar scripts/eventos del `CharacterFrame` vivo. La pestaña `Ficha` usa canvas de frame completo para coordenadas nativas (`CharacterFrameInset 4,-60`, modelo `52,-66`, inset derecho desde `CharacterFrameInset`) y texturas del probe: `UI-Background-Rock/Marble`, `UI-Character-Info-Title`, `UI-Character-Info-<Class>-BG`, `PaperDollSidebarTabs` y `Char-Paperdoll-*`. El fondo derecho se elige por clase Harford de mayor nivel y cae a `UnitClass`; el fondo del modelo se elige por `progression.race` usando `Interface\\DressUpFrame\\DressUpBackground-<Race>1..4` y cae a negro si no hay token conocido, nunca copiando el `CharacterModelFrameBackground*` vivo del personaje real. Los slots nunca usan rutas inventadas `UI-PaperDoll-Slot-*` ni copian `Character*SlotIconTexture`: muestran el icono vacio nativo del hueco con `GetInventorySlotInfo`, mas fondo oscuro, `UI-Quickslot2`, `WhiteIconFrame` y `Char-Paperdoll-Parts`. Las tres tabs superiores del panel derecho usan `PaperDollSidebarTabs`: primera con retrato 3D nativo del jugador, y vistas `summary`/`skills`/`details` inspiradas en BG3 con filas compactas. La cabecera de clase usa formato multiclase `Picaro Forajido (3)  Paladin (1)`, sin `|`, coloreando cada entrada por su propia clase via `HarfordClassColors`; en detalles, cada clase va en una linea dentro de la fila `Clase`; nunca `Nivel X - Clase X`. La ficha compacta queda para tiradas: Caract./Ataque/Habilidades. La antigua pestaña `Clases` de `HarfordDnD.lua` fue retirada; no recrear `SEC_CLS` ni `HarfordDnDStore.RefreshClassPanel`.
- **Pestaña Libro**: réplica 1:1 del `SpellBookFrame` nativo (texturas `374155`/`Spellbook-Page-1`/`-2`/`Spellbook-Parts`/`SpellBook-SkillLineTab`+`GuildSpellbooktabIconFrame`; iconos de tab General=`INV_Misc_Book_09`, clase=`classicon_<token>`). `BookCategory` clasifica cada habilidad: **pasivo** (tooltip); **al_accion** (tiene `conditionalWeaponDamage` → el click togglea `HarfordDnDStore.ToggleConditionalDamage(cdId)`, **mismo estado que el menú "Daño extra"** de la ficha; varios a la vez, el ataque los consume; **se retirará el botón "Daño extra"** cuando el Libro lo cubra todo); **reaccion** (`feature.cast="reaccion"`; toggle + highlight, se apaga al volver a clicar o **al empezar tu turno** vía `HarfordTurnOrderAPI.RegisterMyTurnListener`; si declara `reactionTrigger`/`reactionEffect`, `HarfordCharacterPanel.TriggerPreparedReaction` la consume en el disparador, hoy `damage_taken`: Esquiva Sobrenatural y Tenacidad Rugosa); **directo/activo** (anuncia con enlace). Enlace clicable de habilidad = `HarfordTRP3.GetAbilityChatLink` (TRP3 ChatLinks `totalrp3`; los enlaces de tipo propio `harford:` NO son clicables en el cliente y `ChatFrame_OnHyperlinkShow` está vetado).
- **Maniobras del Libro**: `BookCategory` tambien reconoce `energyManeuver` como **maniobra** y el click pasa por `HarfordDnDStore.OpenEnergyManeuverMenu(feature, anchor)`: las simples ejecutan directo, las de `levelCost` abren dropdown para elegir cuantos dados/niveles gastar. Las que tienen `attack=true` hacen primero ataque de arma; `spendOnHit=true` retrasa el gasto del recurso hasta confirmar impacto. La linea de ataque usa el link TRP3 de la habilidad cuando exista. Esto cubre Picaro (`Mutilar`, `Exponer Armadura`, `Garrote`; Mutilar aplica `Derribado` aura 267937 y Garrote aplica `Silenciado` aura 30900 si fallan la salvacion tras impactar via `onFailAura`. `Exponer Armadura` NO lleva salvacion: es ataque normal + link y aplica el estado `Exponer armadura` aura 11971 al impactar via `onHitAura` (sin nota larga: el link lleva la descripcion). El estado 11971 esta tambien en el menu `ESTADOS` de `HarfordAdminUnitMenu`), Guerrero (`Carga`) y Caballero de la Muerte (`Espiral de la Muerte`). Si la salvacion post-impacto la hace un jugador, se envia `DOSAVE` y la tira/publica el cliente defensor con su ficha; solo los NPCs se resuelven localmente desde el atacante/DM. `Poder Runico` queda como recurso/informativo; el dropdown activable es `Golpe Runico` (`conditionalWeaponDamage id="runic_strike"`), no el rasgo de recurso.
- **Gran Arma / Great Weapon Fighting**: el flag `greatWeaponFighting` solo se aplica a dano de arma cuerpo a cuerpo con propiedad `Dos manos`, o arma `Versatil` cuando el toggle `Versatil` esta activo. No se aplica a arcos/rifles aunque tengan `Dos manos`. Cada dado de dano base del arma que saque 1 o 2 se repite una sola vez y se muestra ENTRE PARENTESIS como `(1→N)`/`(2→N)` en el detalle de la tirada, para no confundir la repeticion con los `+` de la suma y el modificador (antes `6+1->4+5` se leia como "4+5").
- Los marcadores de eleccion de subclase/arquetipo (`Arquetipo de Picaro`, `Estudio Magico`, `Camino Sagrado`, etc.) no son habilidades: el Libro los filtra y la lista de Rasgos los resume como `Subclase <Clase>: <Subclase>`, con la clase coloreada. Los rasgos reales de la subclase siguen apareciendo en su tab.
- Los rasgos `choice` (por ejemplo `Estilo de Combate` o `Pericia`) deben mostrar la opcion elegida en Rasgos y en el Libro. Si no hay opcion resuelta/importada, mostrar `Eleccion: pendiente` y no ocultar el rasgo.
- El resumen `Rasgos` no debe mostrar contadores `[X/Y]`; los usos por descanso se gestionan desde el Libro para no duplicar rasgos. El boton del Libro muestra `Usos X/Y` y `Descanso corto`/`Descanso largo`, bloquea uso/preparacion si esta a 0 y refresca el contador al gastar.
- **Barra de acción (`HarfordActionBars`)**: barra propia (NO secuestra los ActionButton de Blizzard), gate por `HarfordConfig` (`actionbar`), para colocar habilidades del Libro. **Las texturas de madera retail `Interface\PlayerActionBarAlt\spellbar-wood*` NO existen en el cliente Epsilon** (salen verde); usar solo texturas que el cliente tiene y verificar con `GetFileIDFromPath`. Diagnósticos en `HarfordDebug` (`actionbar*`). Fase 2 (arrastrar del Libro + click) pendiente; patrón Arcanum = SecureActionButton con `type` custom + `_<type>` handler.
- **Equipo virtual**: `HarfordDnDItems` guarda item links por slot en `HarfordDnDPersistStore.profiles[name]._equipment` (anidado por perfil; migrado desde el antiguo top-level `equipment`). Arrastrar un objeto del juego a un slot PaperDoll del panel lo equipa virtualmente; click derecho/Alt+click lo quita. No equipa el objeto real de WoW. Los slots `MainHand`/`SecondaryHand`/`Chest` tienen flecha de seleccion basica; el objeto equipado reconocido tiene prioridad y la seleccion basica queda como fallback. Los items custom de Epsilon se tratan como items normales: link/icono/tooltip nativo se conservan. Parser de descripcion: solo lineas completas con etiqueta conocida + numero se aplican como mecanica (`Naturaleza +1`, `Fuerza +2`, `Salvacion Destreza +1`, `CA +1`, `Armadura 14`, `Ataque +1`, `Dano +1`, `Ataque conjuro +1`, `CD conjuro +1`, `Dano extra 1d6 fuego`); el resto queda como descripcion narrativa. `GetItemStats` y esas lineas entran como bonus live de caracteristica/habilidad/salvacion/ataque/dano/CA/conjuro; los dados extra se suman a la tirada de daño del arma y se maximizan en critico. Las tiradas de ataque/daño de arma equipada como objeto usan el `itemLink` como nombre de arma para que salga clicable en chat. Armadura/escudo se resuelven como CA base alternativa (`max(CA manual, CA equipo) + bonus`); MainHand reconocido alimenta el arma activa y, si `Offhand` esta activo, se intenta `SecondaryHand`; un escudo item en secundaria se trata como `Escudo` para offhand. La seccion Ataque no usa `ArmaSeleccionada`, `ModArma` ni `ModIniciativa`; si no hay item/arma basica cae a `Desarmado`. El texto del arma muestra `<arma>: <propiedades>` (link clicable con color de calidad si es objeto via `weaponLinkFrame` con `SetHyperlinksEnabled`; nombre en negro si es basica) y el `Offhand` solo aparece si hay arma/escudo en la mano secundaria (`HasOffhandCombatItem`). **Tipo de arma D&D**: se detecta robustamente (`DetectWeaponKey`, frase completa con limite de palabra) desde el nombre del item o su descripcion (o `Arma: <tipo>` explicito), sobre el mapeo por subclase WoW. **Bonus por calidad**: la rareza (color del enlace, `QualityFromLink`) da +1/+2/+3/+4 (verde/azul/morado/naranja) a ataque y daño (armas) o CA (armadura/escudo). Nunca en modo NPC. Sync via `DNDEQUIP`/`DNDEQUIPC`. Debug: `/harford debug run itemrules MainHand`.
- **Inspeccion ligera**: `HarfordCharacterInspect` permite `/harford inspect` o `HarfordCharacterPanel.OpenInspect("target")` para ver el panel de otro jugador sin cambiar `activeProfile`. Usa `DNDINSREQ`/`DNDINSBASE`, `DNDRES`, y opcodes especificos de inspeccion `DNDINSCLASS`/`DNDINSEQUIP` (con chunks `DNDINSCLASSC`/`DNDINSEQUIPC`). Esos paquetes se guardan solo en cache efimera (`SetInspectData`/`Note*`) y no importan progresion/equipo a persistencia. El panel queda read-only y desactiva pestanas editables.
- **Carga de ficha desde TRP3 SOLO con comando**: `/harford cargarficha` es la UNICA via que trae datos del TRP3 a la ficha (carga destructiva: lee clase(s)/raza/trasfondo/caracteristicas/equipo del About, calcula vida y maximos de recurso y los hornea en SV). La antigua siembra automatica `HarfordDnDProgression.SeedFromTRP3` ya **no se llama** desde `RefreshPanel`/`Refresh` ni desde el hook `WORKFLOW_ON_FINISH` (retirado): abrir la ficha/panel o cambiar de target ya **no auto-rellena** ni hace aparecer barras de recurso. `SeedFromTRP3` queda solo para el diagnostico `trp3build`. `Harford.toc` mantiene `OptionalDeps: totalRP3, totalRP3_Extended`. No reintroducir auto-siembra ni resolverla con `C_Timer`/reintentos. **Comando unico**: todo se invoca via `/harford <sub>` (`cargarficha`/`ficha`/`char`/`rep`/`turnos`/`config`/`inspect`/`debug`); los slash sueltos antiguos fueron retirados (sus funciones siguen en `SlashCmdList[clave]` solo para el ruteo del dispatcher). `/harford` a secas solo lista los subcomandos.
- **TRP3 como indice, libro como fuente**: para trasfondos y rasgos, la ficha TRP3 solo debe identificar que elemento existe (`Trasfondo X`, `Dote Y`, `Estilo de combate Z`, pericias elegidas). Las descripciones, efectos y reglas salen de `HarfordDnDBackgrounds`/`HarfordDnDBook`/`HarfordDnDFeats`. `backgroundDesc` solo se guarda para trasfondos personalizados que no existan en el libro; si el trasfondo resuelve a entrada conocida, se ignora el parrafo TRP3. `HarfordDnDBackgrounds` contiene 50 trasfondos (Warcraft, PHB, SCAG Cazarrecompensas urbano y los exportados/propios como `eco_resurreccion`/`buscador_sombrio`/`anima_errante`/`senda_sangre_barro`); `FindBackgroundIdByText` usa aliases defensivos para titulos sin tildes o mutilados.
- **Persistencia de recursos derivados**: `/harford cargarficha` es el unico flujo que importa TRP3 y rellena currents al maximo/valor inicial. Fuera de esa carga, los setters de `HarfordDnDProgression` llaman `HarfordDnDStore.ReconcileDerivedResources(profileName, reason)` para el perfil local: recalcula maximos derivados, crea current inicial solo cuando el maximo anterior era 0, clampa valores que superen el maximo y conserva currents reales a 0. No usar timers/reintentos ni auto-siembra TRP3 para que aparezcan recursos; la progresion local ya dispara la reconciliacion.
- **Persistencia compacta de ficha**: `HarfordDnDStore.SetValue` mantiene defaults en runtime pero no los guarda en `HarfordDnDPersistStore.profiles` (`0`, `10`, `normal`, `Desarmado`, etc.). `PrunePersistedProfiles()` limpia defaults antiguos y borra perfiles fantasma vacios no activos. **Todo lo de una ficha se anida en `profiles[name]`**: claves planas + sub-tablas `_progression`/`_equipment`/`_hitDice`/`_featureUses` (las antiguas top-level `classProgression`/`equipment`/`hitDice`/`featureUses` se migran con `MigrateNestedIntoProfiles` al cargar). `ApplyProfileTable` (recepcion de ficha) reconstruye el perfil plano pero PRESERVA esas sub-tablas y mantiene `runtime` plano; no reintroducir tablas top-level keyed-por-nombre. No reintroducir escrituras directas de defaults al perfil persistido; usa siempre el store salvo casos muy justificados.
- **Limpieza de SavedVariables**: `HarfordDebug` expone `/harford debug run svclean status|safe|dnd|logs|npclinks|guilds|targetpos [force]|all|purge confirm`. `safe` limpia defaults DnD, logs de reputacion y `HarfordDnDTargetResourceSettings` si no hay posicion manual. `guilds`/`npclinks` solo purgan restos obsoletos: la reputacion actual es por PJ y la faccion NPC vive en Epsilon. `purge confirm` borra todas las SavedVariables declaradas en `Harford.toc` y requiere `/reload`. Los logs de reputacion no se persisten: `HarfordReputation.AddLog` solo imprime.
- **Rasgos visibles del panel**: el bloque `Rasgos destacables` de `HarfordCharacterPanel` prioriza rasgos de clase/subclase desbloqueados desde `HarfordDnDProgression`/`HarfordDnDBook` y filtra entradas de magia/conjuros. `HarfordTRP3.GetProfileFeatureLines(profile, limit)` queda como fallback visual y solo debe extraer secciones de clase; no convertir esos textos en efectos automaticos sin contrato nuevo.

- **Automatizacion de rasgos**: implementar primero lo que encaje en efectos declarativos existentes (`skillProf`, `skillExpertise`, `saveProf`, `armorProf`, `weaponProf`, `bonus` a CA/ataque/dano/iniciativa/conjuro, `resourceMax`). Ya estan convertidas competencias de arma claras de razas (Enano/Kaldorei/Orco/Tauren/Trolls/Elfo de Sangre/Goblin) y de clase/subclase (Forajido pistolas/rifles, Chaman Mejora marciales). No convertir ventajas situacionales, resistencias, idiomas, herramientas, armas naturales o CA condicional sin anadir primero una capa mecanica explicita.

## Módulos principales

| Archivo | Rol | Tamaño aprox |
|---|---|---|
| `Harford/HarfordUnitFrames.lua` | Overlays TRP3/DnD sobre frames nativos WoW | ~4400 líneas (~169 locales) |
| `Harford/HarfordClassColors.lua` | Fuente única de color de clase WoW (alias es/en, normalización, RGB/hex). Consumido por UnitFrames/NamePlates/Turns | pequeño |
| `Harford/HarfordUIGeom.lua` | Helpers puros de geometría/búsqueda de StatusBars para overlays | pequeño |
| `Harford/HarfordDnD.lua` | Ficha D&D 5e — UI principal `/harford ficha`. 3 tabs compactos de tirada (Caract./Ataque/Habilidades); icono tabardo abre `HarfordCharacterPanel` | grande (~139 locales) |
| `Harford/HarfordCharacterPanel.lua` | Panel de personaje de usuario final: Ficha, **Libro** (replica 1:1 del spellbook nativo), Creacion, Subida y acceso a Reputacion; usa los modulos DnD* y no sustituye HarfordReputationUI | mediano |
| `Harford/HarfordActionBars.lua` | Barra de accion propia (config-gated `actionbar`) para colocar habilidades del Libro; no secuestra los ActionButton de Blizzard | pequeño |
| `Harford/HarfordDnDContext.lua` | Estado de contexto de ficha (`SheetContext`) + accesores `Get`/`Set` (ARCGET/ARCSET). Bisagra que desacopla los helpers del chunk de DnD | pequeño |
| `Harford/HarfordDnDProfile.lua` | Aplica tablas de perfil/recursos sobre `HarfordDnDStore` (hooks EnsureDefaults/RefreshMainUI inyectados) | pequeño |
| `Harford/HarfordDnDUI.lua` | Constantes visuales/layout y fábricas UI pequeñas de la ficha (`SetFrameBackground`, `CreateSection`, `MakeButton`) | pequeño |
| `Harford/HarfordDnDAttackUI.lua` | Controles visuales de Ataque y tracker de movimiento activado solo durante la medición; reglas/tiradas permanecen fuera | pequeño |
| `Harford/HarfordDnDCustomDamage.lua` | Parser, ventana, mitigación y aplicación del daño personalizado a target/focus | pequeño |
| `Harford/HarfordDnDConditionalDamage.lua` | Fuente única de niveles/costes/escalado y menús de daños condicionales para Ataque y Libro | pequeño |
| `Harford/HarfordDnDRolls.lua` | Serialización, render en chat, broadcast y sonido de tiradas D&D por `DND5EARC` | pequeño |
| `Harford/HarfordDnDData.lua` | Datos: tablas `ABIL` (características) y `SKILLS` (habilidades) | pequeño |
| `Harford/HarfordDnDBook.lua` | Libro hardcodeado de clases/subclases/rasgos; efectos declarativos, sin Lua arbitrario | pequeño |
| `Harford/HarfordDnDProgression.lua` | Estado por perfil de niveles, featureStates internos, choices y estados activables (`activeStates`); se guarda en `HarfordDnDPersistStore.profiles[name]._progression` | pequeño |
| `Harford/HarfordDnDItems.lua` | Equipo virtual por item links reales: slots, iconos, stats, arma y CA derivadas | pequeño |
| `Harford/HarfordCharacterInspect.lua` | Snapshot ligero/read-only para inspeccionar el panel de otro jugador | pequeño |
| `Harford/HarfordDnDFeatureEffects.lua` | Resuelve efectos activos y bonos derivados para Calc/Combat/UI; soporta `toggleState`/`requiresState` para rasgos activables | pequeño |
| `Harford/HarfordDnDWeapons.lua` | Datos: tabla `WEAPONS` + helpers de arma (dados, props, menú) | pequeño |
| `Harford/HarfordDnDCalc.lua` | Cálculo puro: modificadores, dados, bonos. Lee vía `HarfordDnDContext` | pequeño |
| `Harford/HarfordDnDNet.lua` | Recursos/red: export/request/adjust vía HarfordSync. `HarfordDnDAPI` delega aquí | pequeño |
| `Harford/HarfordDnDCombat.lua` | Reglas de combate con contexto de unidad: CA, impacto y aplicación segura de daño de arma a NPC | pequeño |
| `Harford/HarfordDnDMinimap.lua` | Botón de minimapa de la ficha (toggle + reset de posiciones inyectado) | pequeño |
| `Harford/HarfordTurns.lua` | Tracker visual de turnos de combate | grande |
| `Harford/HarfordReputation.lua` | Core de reputaciones: facciones, reputacion por PJ y rangos. Sin DEFAULT_FACTIONS; todo en SavedVariables | mediano |
| `Harford/HarfordReputationUI.lua` | Panel de reputaciones, standalone con `/harford rep` y embebible en `HarfordCharacterPanel`. Filas custom: hlFrame para highlights (sin clipping), caps OVERLAY -1, Exaltado siempre lleno, `adjustPrompt` para ajuste libre | mediano |
| `Harford/HarfordReputationSync.lua` | Sync de red, prefix `HARFORDREP` | pequeño |
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
- **Sin reintentos de startup**: no meter `C_Timer.After(3/6, ...)` para esperar TRP3/unitframes. `HarfordUnitFrames` inicializa hooks desde `ADDON_LOADED`, `PLAYER_LOGIN` y `PLAYER_ENTERING_WORLD`; los `After(0)` o delays cortos restantes son diferidos puntuales de layout/restauracion tras eventos concretos.
- **`PLAYER_STARTED_MOVING`/`PLAYER_STOPPED_MOVING`**: pueden no disparar en Epsilon. No usarlos para activar/desactivar lógica de seguimiento de posición.
- **`UnitPosition("player")` en Epsilon**: puede devolver solo `x, y` sin `z` (z = nil). Siempre usar `nz = nz or 0` y guard `if not nx or not ny then return end` antes de cualquier aritmética sobre las coordenadas. Devuelve yards; multiplicar por `0.9144` para metros.
- **Caches de auras de target/focus**: target y focus tienen caches de anclas separados. Limpiar un cache de buff frames sin restaurar antes las posiciones nativas causa drift infinito con cada `UNIT_AURA`. Siempre restaurar antes de limpiar (`RestoreTargetAuras()`/`RestoreFocusAuras()`/`RestoreUnitAuras(unit)`); no compartir anclas entre target y focus. **Con barras extra (`resourceCount > 2`) el posicionamiento ya NO es shift por altura, sino re-anclaje idempotente** (`ReanchorAurasBelowBars`: buffs bajo la ultima barra, debuffs bajo el contenedor de buffs), reaplicado tras Blizzard via `hooksecurefunc("TargetFrame_UpdateAuras")`. Ver AGENTS.md para el contrato completo.
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

-- Buff drift fix: SIEMPRE restaurar a nativo ANTES de limpiar el cache de anclas.
-- Usar RestoreTargetAuras()/RestoreFocusAuras()/RestoreUnitAuras(unit) (restauran Y limpian);
-- nunca vaciar el cache sin restaurar primero (dejaria los frames desplazados como "base").
-- Aplica en: handler UNIT_AURA target + branch de cambio de GUID en AdjustUnitAuras.
-- (Con focus activo, UNIT_AURA "focus" también dispara RefreshFrame("Target") → duplica la deriva)
RestoreTargetAuras()  -- correcto

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

## Rendimiento

- MogIt dispara muchos `GET_ITEM_INFO_RECEIVED`: `HarfordDnDItems.RefreshPending()` solo procesa items Harford realmente pendientes y `HarfordLoot`/`HarfordAdminLoot` solo repintan si el `itemID` recibido esta en el loot visible/editado. Usar `/harforddebug run perfitems` para medir eventos procesados/ignorados.
- No usar `HarfordNamePlates.RefreshAll()` ante cualquier `DND5EARC`; solo recursos (`DNDRES`, `DNDRESCFG`, `RADJ`) justifican refresco de overlays, y preferir `HarfordNamePlates.RefreshName(profileName)`.
- Las listas dinamicas del panel de personaje deben reutilizar filas/controles con pool. No crear frames nuevos por refresh.
- `HarfordCharacterPanel` registra eventos de target/retrato solo mientras esta visible; no dejarlos activos con el panel cerrado.
- `HarfordTurns` crea la ventana de turnos bajo demanda y `RefreshFrame()` debe salir rapido si esta oculta; no repintar tarjetas invisibles.
- Los chunks incompletos de progresion/equipo en `HarfordSync` tienen TTL; la cache de inspeccion es efimera y limitada.
- Los `C_Timer.After` en rutas calientes deben estar coalescidos: UnitFrames usa flags para group overlays/restauracion compact y AdminUnitMenu usa token en el editor de recursos.
- Caches por nombre deben tener limite/poda: color de clase UnitFrames y solicitudes NamePlates maximo 100; throttle de inspeccion TTL 60s.
- Eventos frecuentes de compact frames deben usar `RefreshGroupOverlayForUnit`; `DNDRES`/`DNDRESCFG`/`RADJ` refrescan overlays por nombre y no deben caer en `API.Refresh()` global.
- `HarfordFrameProbe` es debug pesado; limpiar con `/harford debug run svclean frameprobe` tras usar `probeframe`.

## Verificación rápida antes de editar

1. ¿El enfoque que voy a usar está en la lista de "enfoques fallidos" de AGENTS.md? → No reintentar.
2. ¿El módulo tiene contrato documentado en AGENTS.md? → Respetar el contrato.
3. ¿Estoy añadiendo diagnóstico temporal? → Va en `HarfordDebug.RegisterCommand`.
4. ¿Estoy creando un overlay de ToT/unitframe? → UIParent/MEDIUM (niveles 82-85). ¿Es un panel/ventana? → UIParent/DIALOG (500+).
