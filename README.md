# Harford DnD 5e

Addon de World of Warcraft para el servidor Epsilon RP de la **Compañía Harford**. Implementa un sistema de **D&D 5e** dentro del juego: ficha de personaje, recursos, reputaciones, combate por turnos, loot, sincronización entre jugadores y herramientas DM opcionales.

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
3. Iniciar el cliente Epsilon y activar **`Harford`** en el selector de addons.
4. Activar **`HarfordAdmin`** solo en cuentas con permisos de DM/Admin. Las herramientas DM requieren `HarfordAdmin` cargado y `.ph dm` activo.

---

## Slash commands

| Comando | Descripción |
|---|---|
| `/FichaHarford` | Abre la ficha de personaje D&D 5e |
| `/harfordrep` | Abre/cierra el panel de reputaciones (también accesible desde el icono de tabardo en la ficha) |
| `/harforddebug` | Sistema de debug (on/off/toggle/status/list) |
| `/hdebug` | Alias de `/harforddebug` |
| `/harfordadmin` | Herramientas de DM/Admin (loot, reputaciones, fichas NPC, acciones sobre NPCs) |
| `/hconfig` | Panel de configuración del addon |

---

## Estructura del proyecto

```
Harford/            ← Addon principal: jugadores y DM
HarfordAdmin/       ← Addon admin: herramientas DM, editores y comandos protegidos
AGENTS.md           ← Arquitectura, contratos de módulos y enfoques fallidos
CLAUDE.md           ← Instrucciones para Claude Code
.github/
  copilot-instructions.md  ← Instrucciones para GitHub Copilot
.cursorrules        ← Instrucciones para Cursor AI
```

---

## Arquitectura resumida

- **Harford** contiene el core compartido: ficha D&D, recursos, turnos, reputaciones, loot visible/usable, unitframes, nameplates, sync addon y acciones servidor validadas que también pueden necesitar jugadores.
- **HarfordAdmin** contiene la capa DM: menú contextual, ficha Modo NPC, editores de loot/reputación, compartir datos, ajustar recursos/reputación y comandos protegidos.
- Los comandos Epsilon se construyen desde plantillas y acciones validadas (`HarfordCommandTemplates` + `HarfordServerActions`), nunca desde texto arbitrario recibido de otros clientes.
- La mitigación de daño (`resistente`, `inmune`, `vulnerable`) se calcula en core con el stat block TRP3 del target y se muestra en la tirada con marcadores `R`/`I`/`V`. Admin solo aplica el total ya calculado.
- La herida visual de NPC al perder vida se centraliza en `HarfordServerActions.SetNpcHealthDelta`: emote `33` para daño normal y `34` para daño crítico.

---

## Para colaboradores

**Antes de modificar cualquier módulo**, leer [`AGENTS.md`](AGENTS.md). Contiene:
- Contratos de cada módulo (qué hace, qué expone, qué no debe tocar)
- Limitaciones conocidas del cliente Epsilon (strata, hooks, frames)
- Enfoques que ya se probaron y fallaron (no reintentar)
- Patrones de código establecidos

Documentación auxiliar:

- [`CLAUDE.md`](CLAUDE.md): resumen compacto para Claude Code.
- [`.github/copilot-instructions.md`](.github/copilot-instructions.md): resumen compacto para GitHub Copilot.

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
