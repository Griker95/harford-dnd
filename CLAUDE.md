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

## Módulos principales

| Archivo | Rol | Tamaño aprox |
|---|---|---|
| `Harford/HarfordUnitFrames.lua` | Overlays TRP3/DnD sobre frames nativos WoW | ~3800 líneas |
| `Harford/HarfordDnD.lua` | Ficha D&D 5e — UI principal `/FichaHarford` | grande |
| `Harford/HarfordTurns.lua` | Tracker visual de turnos de combate | grande |
| `Harford/HarfordTRP3.lua` | Lectura segura de perfiles TRP3 | mediano |
| `Harford/HarfordDebug.lua` | Sistema de debug — todos los diagnósticos van aquí | mediano |
| `Harford/HarfordSync.lua` | Transporte addon messages (serialización, canales) | mediano |
| `Harford/HarfordServerActions.lua` | Comandos Epsilon validados (additem, aura, etc.) | pequeño |
| `Harford/HarfordEpsilonCommands.lua` | Wrapper bajo nivel para EpsilonLib/ARC | pequeño |
| `HarfordAdmin/HarfordAdminUnitMenu.lua` | Menú contextual DM en unitframes | mediano |

## Limitaciones Epsilon críticas (no reintentar lo fallado)

- **Strata cross-tree**: hijos de `TargetFrame` NO respetan jerarquía de strata vs frames UIParent. Overlays que deban estar encima de `barSlotOverlays` (MEDIUM/UIParent) → **UIParent con DIALOG strata** (level 500+).
- **TargetofTarget_Update**: ~12x/segundo, restaura barras y portrait nativo del ToT. No escribir en barras nativas del ToT; usar `totBarsOverlay` (UIParent/DIALOG).
- **SetAlpha en barras ToT**: `TargetofTarget_Update` y `OnValueChanged` lo restauran. No usar.
- **PlayerFrameTexture SetAlpha(0)**: no funciona en Epsilon para el player frame.
- **Reposicionar TargetFrameToT físicamente**: `TargetofTarget_Update` resetea anchors entre ticks. No mover el frame nativo — solo gestionar strata/level y cubrir con overlays.
- **Límite de 200 locales Lua 5.1**: `HarfordUnitFrames.lua` roza el límite. Nuevos bloques de funciones deben ir dentro de `do...end` para no añadir locales al scope global. Exponer funciones públicas vía tabla (ver patrón `focusTot`).

## Patrones de código recurrentes

```lua
-- Dependencias opcionales: siempre comprobar en runtime
if TRP3_API and TRP3_API.register then ... end
if ARC and ARC.CMD then ... end

-- Overlay UIParent/DIALOG (escape para limitación Epsilon)
local f = CreateFrame("Frame", nil, UIParent)
f:SetFrameStrata("DIALOG")
f:SetFrameLevel(500)
f:SetAllPoints(nativeBar)  -- anclaje cross-tree OK para posicionamiento

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

-- Patrón do...end para añadir funciones sin consumir locales de file-scope
-- (HarfordUnitFrames.lua está al límite de 200 locales Lua 5.1)
do
    local function miFuncionInterna() end
    local function otraFuncion() end
    miTabla.publica = miFuncionInterna
    miTabla.otra    = otraFuncion
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

## Verificación rápida antes de editar

1. ¿El enfoque que voy a usar está en la lista de "enfoques fallidos" de AGENTS.md? → No reintentar.
2. ¿El módulo tiene contrato documentado en AGENTS.md? → Respetar el contrato.
3. ¿Estoy añadiendo diagnóstico temporal? → Va en `HarfordDebug.RegisterCommand`.
4. ¿Estoy creando un overlay sobre TargetFrame? → UIParent/DIALOG strata obligatorio.
