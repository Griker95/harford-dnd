# Harford DnD 5e — Instrucciones para GitHub Copilot

Este proyecto es un addon de **World of Warcraft** escrito en **Lua** (Interface 45745) para el servidor privado de roleplay **Epsilon**. Implementa un sistema de **D&D 5e** dentro del juego.

## Reglas fundamentales

- **Idioma**: Responde siempre al usuario en **español**. El código y los comentarios van en español.
- **Fuente de verdad**: Lee `AGENTS.md` antes de modificar cualquier módulo. Contiene arquitectura, contratos y enfoques fallidos documentados.
- **No crear archivos nuevos** salvo petición explícita. Preferir editar los existentes.
- **No agregar comentarios genéricos** — solo el WHY no obvio.
- **No reintentar** enfoques marcados como FALLIDOS en `AGENTS.md`.
- **Todo comportamiento exclusivo de modo DM en `HarfordAdmin/`**. El core `Harford/` puede exponer callbacks sobrescribibles (patron `HarfordTRP3.InsertGlanceLink(glance)`); HarfordAdmin los reemplaza. Nunca poner `if IsDMMode()` para logica de UI/accion en modulos core.
- `HarfordDnD.lua` solo representa contextos externos mediante `ApplySheetContext`; el armado de ficha NPC desde target/TRP3 y la edicion de recursos remotos viven en `HarfordAdmin`, no en core.
- `HarfordDnD.lua` tambien esta sujeto al limite de 200 locales del chunk Lua: el contexto externo vive agrupado en `SheetContext`. No volver a crear locales de file-scope separados para sus campos.
- **Links TRP3 en DM**: crear links mediante `HarfordTRP3.CreateGlanceLink(glance)` solo para estados ajenos. Sin DM, insertar `[TRP3:id]`; en DM con NPC target, enviar `npc te <hyperlink totalrp3>` por `HarfordServerActions.SendNpcTRP3Hyperlink`, cayendo a impresion local si no puede emitirse.
- **Links nativos TRP3**: no enganchar `ChatFrame_OnHyperlinkShow`, no sobrescribir `OpenMakeImportablePrompt` ni `AtFirstGlanceChatLinksModule.InsertLink`. Los links visibles y estados propios quedan en manos de TRP3.
- **Envio NPC de links TRP3**: la via directa con hyperlink completo por EpsilonLib esta validada en dos clientes. Solo aceptar hyperlinks creados/reconocidos por `HarfordTRP3.IsKnownGlanceHyperlink`; el marcador `[TRP3:id]` no funciona por NPC. Conservar `/harforddebug run trp3npctest hyperlink` solo para regresion.
- **Daño y mitigación**: el core `HarfordDnD.lua` calcula resistencias/inmunidades/vulnerabilidades con `HarfordDamageMitigation.ForTarget(...)` y muestra marcadores `R`/`V`/`I` en la tirada. `HarfordAdmin` solo aplica el total ya mitigado con acciones servidor validadas.
- **Herida NPC**: `HarfordServerActions.SetNpcHealthDelta` dispara `npc emote 33` para daño real normal y `npc emote 34` para daño crítico (`opts.isCritical`). No duplicar esta lógica en UI.

## Entorno técnico

- Lua para WoW (no Lua estándar): usa la WoW API (`CreateFrame`, `UnitExists`, `hooksecurefunc`, etc.)
- Servidor Epsilon (cliente WoW privado RP): APIs adicionales `EpsilonLib`, `ARC`, `C_Epsilon`, `ARC.PHASE`
- TotalRP3: addon de perfiles de roleplay. Siempre comprobar disponibilidad en runtime.
- Addon messages comprimidos/chunked vía prefixes: `DND5EARC`, `HARFORDLOOT`, `HARFORDCFG`, `HARFORDTURN`

## Limitaciones Epsilon críticas

Estas limitaciones están confirmadas. **No intentar alternativas** — ya se probaron y fallaron:

- **Strata cross-tree**: Frames hijos de `TargetFrame` NO respetan la jerarquía de strata frente a frames de `UIParent`. Overlays ToT/unitframe → **`UIParent` con `SetFrameStrata("MEDIUM")`** y niveles 82-85. Paneles/ventanas → `DIALOG` level 500+. No usar `DIALOG` para overlays de HUD: tapa ventanas de otros addons.
- **TargetofTarget_Update**: Se ejecuta ~60fps y restaura barras nativas del ToT. No escribir en barras nativas del `TargetFrameToT`. Usar el overlay `totBarsOverlay` (UIParent/MEDIUM, niveles 82-85).
- **SetAlpha en barras ToT**: `TargetofTarget_Update` y `OnValueChanged` restauran el alpha. No usar `SetAlpha` para ocultar barras nativas del ToT.
- **PlayerFrameTexture**: `SetAlpha(0)` no funciona en Epsilon para el player frame.
- **Reposicionar TargetFrameToT**: `TargetofTarget_Update` resetea los anchors entre ticks. No mover el frame nativo.
- **`ClearTargetAuraAnchorCache()` directamente**: provoca drift infinito de buff frames. Siempre usar `RestoreTargetAuras()` (restaura Y limpia). Con focus activo, `UNIT_AURA focus` también dispara `RefreshFrame("Target")`, duplicando la deriva.
- **`CHAT_MSG_SYSTEM` para estado DM**: dispara en cualquier mensaje de sistema. Usar `HarfordAuthority.RegisterChangeListener` para cambios de modo DM.

## Patrones de código establecidos

```lua
-- Dependencias opcionales: SIEMPRE comprobar en runtime
if TRP3_API and TRP3_API.register then ... end
if ARC and ARC.CMD then ... end

-- Overlay UIParent/MEDIUM para ToT/unitframe (no tapa otros addons)
local f = CreateFrame("Frame", nil, UIParent)
f:SetFrameStrata("MEDIUM")
f:SetFrameLevel(82)  -- art=82, barFrame=83, bar=84, portrait=85
f:SetAllPoints(nativeBar)  -- anclaje cross-tree OK para posicionamiento
-- Para paneles/ventanas flotantes: DIALOG level 500+

-- Buff frames: SIEMPRE restaurar antes de limpiar el cache de anclas
RestoreTargetAuras()  -- OK: restaura posición nativa Y limpia cache
-- ClearTargetAuraAnchorCache()  -- MAL: limpia sin restaurar → drift infinito

-- HandleAddonMessage retorna boolean; usar para condicionar refreshes costosos
local changed = AddonHandlers.HandleAddonMessage(prefix, message, sender)
if changed and HarfordUnitFrames then HarfordUnitFrames.Refresh() end

-- Throttle de requests por jugador (evitar spam de WHISPER en PLAYER_TARGET_CHANGED)
local _reqTimes = {}  -- tabla en scope de módulo
if (GetTime() - (_reqTimes[name] or 0)) < 12 then return false end
_reqTimes[name] = GetTime()

-- Nombres en sync (turnos, fichas): siempre cortos, sin realm
local short = Ambiguate and Ambiguate(name, "short") or name:match("^[^%-]+") or name

-- Debounce para rafagas de mensajes (HarfordReputationSync, etc.)
local _pending = false
local function RefreshViews()
    if _pending then return end
    _pending = true
    C_Timer.After(0.1, function() _pending = false; DoActualRefresh() end)
end

-- Máscara circular: aplicar a AMBAS texturas (fondo e icono)
local mask = pf:CreateMaskTexture(nil, "ARTWORK")
mask:SetTexture(TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mask:SetAllPoints(pf)
pbg:AddMaskTexture(mask)
ptex:AddMaskTexture(mask)

-- Diagnóstico temporal: SIEMPRE en HarfordDebug, nunca en módulos de gameplay
HarfordDebug.RegisterCommand("micomando", function(args)
    -- diagnóstico aquí
end, "Descripción breve")
```

## Módulos principales

| Archivo | Rol |
|---|---|
| `Harford/HarfordUnitFrames.lua` | Overlays TRP3/recursos sobre frames nativos (~4300 líneas) |
| `Harford/HarfordNamePlates.lua` | Overlays DnD sobre nameplates (KuiNameplates o nativo WoW) |
| `Harford/HarfordDnD.lua` | Ficha D&D 5e, UI principal `/FichaHarford`. 3 tabs (Características/Ataque/Habilidades, 124px c/u). Icono tabardo en la esquina superior derecha abre el panel de reputación |
| `Harford/HarfordTurns.lua` | Tracker visual de turnos de combate |
| `Harford/HarfordReputation.lua` | Core de reputaciones: facciones, rangos, jugadores, NPCs |
| `Harford/HarfordReputationUI.lua` | Panel flotante `/harfordrep`. Filas con `ReputationBarTemplate`; caps (`_barLeftTex`/`_barRightTex`) gestionados explícitamente |
| `Harford/HarfordReputationSync.lua` | Sync de red, prefix `HARFORDREP` |
| `Harford/HarfordReputationTooltip.lua` | Hook GameTooltip NPCs con facción vinculada |
| `Harford/HarfordDebug.lua` | Sistema de debug — diagnósticos temporales aquí |
| `Harford/HarfordSync.lua` | Transporte addon messages |
| `Harford/HarfordTRP3.lua` | Lectura segura de perfiles TRP3 |
| `Harford/HarfordCommandTemplates.lua` | Plantillas de comandos Epsilon con placeholders |
| `Harford/HarfordEmotes.lua` | Datos de emotes, heridas y posturas de combate |
| `Harford/HarfordAuras.lua` | Datos/helpers para auras conocidas por scope |
| `Harford/HarfordDamageTypes.lua` | Tipos de daño D&D 5e y normalización de palabras |
| `Harford/HarfordDamageMitigation.lua` | Resistencias, inmunidades y vulnerabilidades por stat block TRP3 |
| `Harford/HarfordServerActions.lua` | Comandos Epsilon validados (additem, auras, npc health/emotes, npc te) |
| `HarfordAdmin/HarfordAdminUnitMenu.lua` | Menú contextual DM en unitframes |

## Seguridad

- No ejecutar texto arbitrario recibido de otros clientes como comando Epsilon.
- Comandos Epsilon solo desde lógica admin explícita con parámetros validados.
- Mantener separados: comunicación Harford entre clientes / comandos Epsilon / respuestas Epsilon.
