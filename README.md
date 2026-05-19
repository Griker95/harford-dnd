# Harford DnD 5e

Addon de World of Warcraft para el servidor Epsilon RP de la **Compañía Harford**. Implementa un sistema completo de **D&D 5e** dentro del juego: ficha de personaje, recursos, combate por turnos, loot y sincronización entre jugadores.

> Addon privado. Requiere acceso al servidor Epsilon de la Compañía Harford.

---

## Dependencias externas

Deben estar instaladas en el cliente Epsilon antes de cargar Harford:

| Addon | Rol |
|---|---|
| **EpsilonLib** | Capa de comunicación con el servidor Epsilon |
| **TotalRP3** | Perfiles de roleplay (iconos, colores, estados) |
| **ARC** (SpellCreator) | Comandos de servidor fire-and-forget |

---

## Instalación

1. Clonar o descargar este repositorio.
2. Copiar las carpetas **`Harford/`** y **`HarfordAdmin/`** a:
   ```
   [Cliente Epsilon]\_retail_\Interface\AddOns\
   ```
3. Iniciar el cliente Epsilon y activar ambos addons en el selector de addons.
4. `HarfordAdmin` solo debe activarse en cuentas con permisos de DM/Admin.

---

## Slash commands

| Comando | Descripción |
|---|---|
| `/FichaHarford` | Abre la ficha de personaje D&D 5e |
| `/harfordrep` | Abre/cierra el panel de reputaciones (también accesible desde el icono de tabardo en la ficha) |
| `/harforddebug` | Sistema de debug (on/off/toggle/status/list) |
| `/hdebug` | Alias de `/harforddebug` |
| `/harfordadmin` | Herramientas de DM/Admin (loot, fichas, NPCs) |
| `/hconfig` | Panel de configuración del addon |

---

## Estructura del proyecto

```
Harford/            ← Addon principal (carga para todos los jugadores)
HarfordAdmin/       ← Addon admin (solo DMs/Officers)
AGENTS.md           ← Arquitectura, contratos de módulos y enfoques fallidos
CLAUDE.md           ← Instrucciones para Claude Code
.github/
  copilot-instructions.md  ← Instrucciones para GitHub Copilot
.cursorrules        ← Instrucciones para Cursor AI
```

---

## Para colaboradores

**Antes de modificar cualquier módulo**, leer [`AGENTS.md`](AGENTS.md). Contiene:
- Contratos de cada módulo (qué hace, qué expone, qué no debe tocar)
- Limitaciones conocidas del cliente Epsilon (strata, hooks, frames)
- Enfoques que ya se probaron y fallaron (no reintentar)
- Patrones de código establecidos

### Flujo de trabajo

- **Rama de trabajo**: `dev` — nunca hacer commits directos a `main`
- **`main`** = versión estable, probada en el servidor
- **`dev`** = desarrollo activo
- Para una feature nueva: branch `feature/nombre` desde `dev`, PR a `dev`
- Para pasar a producción: PR de `dev` → `main` (requiere review)

### Diagnósticos temporales

No añadir código de debug en módulos de gameplay. Usar siempre:

```lua
HarfordDebug.RegisterCommand("micomando", function(args)
    -- diagnóstico aquí
end, "Descripción breve")
```

Y ejecutar en juego con `/hdebug run micomando`.
