# Harford DnD 5e — Instrucciones para GitHub Copilot

Este proyecto es un addon de **World of Warcraft** escrito en **Lua** (Interface 45745) para el servidor privado de roleplay **Epsilon**. Implementa un sistema de **D&D 5e** dentro del juego.

## Reglas fundamentales

- **Idioma**: Responde siempre al usuario en **español**. El código y los comentarios van en español.
- **Fuente de verdad**: Lee `AGENTS.md` antes de modificar cualquier módulo. Contiene arquitectura, contratos y enfoques fallidos documentados.
- **No crear archivos nuevos** salvo petición explícita. Preferir editar los existentes.
- **No agregar comentarios genéricos** — solo el WHY no obvio.
- **No reintentar** enfoques marcados como FALLIDOS en `AGENTS.md`.

## Entorno técnico

- Lua para WoW (no Lua estándar): usa la WoW API (`CreateFrame`, `UnitExists`, `hooksecurefunc`, etc.)
- Servidor Epsilon (cliente WoW privado RP): APIs adicionales `EpsilonLib`, `ARC`, `C_Epsilon`, `ARC.PHASE`
- TotalRP3: addon de perfiles de roleplay. Siempre comprobar disponibilidad en runtime.
- Addon messages comprimidos/chunked vía prefixes: `DND5EARC`, `HARFORDLOOT`, `HARFORDCFG`, `HARFORDTURN`

## Limitaciones Epsilon críticas

Estas limitaciones están confirmadas. **No intentar alternativas** — ya se probaron y fallaron:

- **Strata cross-tree**: Frames hijos de `TargetFrame` NO respetan la jerarquía de strata frente a frames de `UIParent`. Cualquier overlay que deba estar encima de `barSlotOverlays` (MEDIUM/UIParent) **debe ser hijo de `UIParent` con `SetFrameStrata("DIALOG")` y level 500+**.
- **TargetofTarget_Update**: Se ejecuta ~12x/segundo y restaura barras nativas del ToT. No escribir en barras nativas del `TargetFrameToT`. Usar el overlay `totBarsOverlay` (UIParent/DIALOG).
- **SetAlpha en barras ToT**: `TargetofTarget_Update` y `OnValueChanged` restauran el alpha. No usar `SetAlpha` para ocultar barras nativas del ToT.
- **PlayerFrameTexture**: `SetAlpha(0)` no funciona en Epsilon para el player frame.
- **Reposicionar TargetFrameToT**: `TargetofTarget_Update` resetea los anchors entre ticks. No mover el frame nativo.

## Patrones de código establecidos

```lua
-- Dependencias opcionales: SIEMPRE comprobar en runtime
if TRP3_API and TRP3_API.register then ... end
if ARC and ARC.CMD then ... end

-- Overlay UIParent/DIALOG para escapar la limitación Epsilon
local f = CreateFrame("Frame", nil, UIParent)
f:SetFrameStrata("DIALOG")
f:SetFrameLevel(500)
f:SetAllPoints(nativeBar)  -- anclaje cross-tree OK para posicionamiento

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
| `Harford/HarfordUnitFrames.lua` | Overlays TRP3/recursos sobre frames nativos (~3800 líneas) |
| `Harford/HarfordDnD.lua` | Ficha D&D 5e, UI principal `/FichaHarford` |
| `Harford/HarfordTurns.lua` | Tracker visual de turnos de combate |
| `Harford/HarfordDebug.lua` | Sistema de debug — diagnósticos temporales aquí |
| `Harford/HarfordSync.lua` | Transporte addon messages |
| `Harford/HarfordTRP3.lua` | Lectura segura de perfiles TRP3 |
| `Harford/HarfordServerActions.lua` | Comandos Epsilon validados (additem, aura, etc.) |
| `HarfordAdmin/HarfordAdminUnitMenu.lua` | Menú contextual DM en unitframes |

## Seguridad

- No ejecutar texto arbitrario recibido de otros clientes como comando Epsilon.
- Comandos Epsilon solo desde lógica admin explícita con parámetros validados.
- Mantener separados: comunicación Harford entre clientes / comandos Epsilon / respuestas Epsilon.
