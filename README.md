# Harford DnD 5e

Addon de World of Warcraft para el servidor Epsilon RP de la Compania Harford. Implementa un sistema de D&D 5e dentro del juego: ficha de personaje, recursos, reputaciones, combate por turnos, loot, sincronizacion entre jugadores y herramientas DM opcionales.

> Addon privado. Requiere acceso al servidor Epsilon de la Compania Harford.

---

## Dependencias externas

Deben estar instaladas en el cliente Epsilon antes de cargar Harford:

| Addon | Rol |
|---|---|
| **EpsilonLib** | Capa de comunicacion con el servidor Epsilon |
| **TotalRP3** | Perfiles de roleplay (iconos, colores, estados) |
| **ARC** (SpellCreator) | Comandos de servidor fire-and-forget |

---

## Instalacion

1. Clonar o descargar este repositorio.
2. Copiar las carpetas **`Harford/`** y **`HarfordAdmin/`** a:
   ```
   [Cliente Epsilon]\_retail_\Interface\AddOns\
   ```
3. Iniciar el cliente Epsilon y activar **`Harford`** en el selector de addons.
4. Activar **`HarfordAdmin`** solo en cuentas con permisos de DM/Admin. Las herramientas DM requieren `HarfordAdmin` cargado y `.ph dm` activo.

---

## Slash Commands

| Comando | Descripcion |
|---|---|
| `/FichaHarford` | Abre la ficha de personaje D&D 5e |
| `/harfordchar` / `/hchar` | Abre el panel de personaje: Ficha, Creacion, Subida y acceso a Reputacion |
| `/harfordrep` | Abre/cierra el panel de reputaciones |
| `/harforddebug` | Sistema de debug: on/off/toggle/status/list |
| `/hdebug` | Alias de `/harforddebug` |
| `/harfordadmin` | Herramientas de DM/Admin: loot, reputaciones, fichas NPC y acciones sobre NPCs |
| `/hconfig` | Panel de configuracion del addon |

---

## Estructura Del Proyecto

```text
Harford/            <- Addon principal: jugadores y DM
HarfordAdmin/       <- Addon admin: herramientas DM, editores y comandos protegidos
AGENTS.md           <- Arquitectura, contratos de modulos y enfoques fallidos
CLAUDE.md           <- Instrucciones para Claude Code
.github/
  copilot-instructions.md  <- Instrucciones para GitHub Copilot
.cursorrules        <- Instrucciones para Cursor AI
```

---

## Arquitectura Resumida

- **Harford** contiene el core compartido: ficha D&D, recursos, turnos, reputaciones, loot visible/usable, unitframes, nameplates, sync addon y acciones servidor validadas que tambien pueden necesitar jugadores.
- **HarfordAdmin** contiene la capa DM: menu contextual, ficha Modo NPC, editores de loot/reputacion, compartir datos, ajustar recursos/reputacion y comandos protegidos.
- El icono de tabardo de la ficha abre el **Panel de Personaje**. La ficha compacta queda para tiradas; el panel unificado contiene Ficha, Creacion, Subida y acceso al panel de Reputacion.
- La progresion usa datos hardcodeados por clase/subclase, raza, trasfondo y dotes, con efectos declarativos que se suman sobre valores manuales. Los rasgos se aplican internamente; el usuario solo elige cuando existe una eleccion real (`choice`). Se sincroniza con `DNDCLASS` dentro de `DND5EARC`.
- Los comandos Epsilon se construyen desde plantillas y acciones validadas (`HarfordCommandTemplates` + `HarfordServerActions`), nunca desde texto arbitrario recibido de otros clientes.
- La mitigacion de dano (`resistente`, `inmune`, `vulnerable`) se calcula en core con el stat block TRP3 del target y se muestra en la tirada con marcadores `R`/`I`/`V`. Admin solo aplica el total ya calculado.
- La herida visual de NPC al perder vida se centraliza en `HarfordServerActions.SetNpcHealthDelta`: emote `33` para dano normal y `34` para dano critico.

---

## Para Colaboradores

**Antes de modificar cualquier modulo**, leer [`AGENTS.md`](AGENTS.md). Contiene:

- Contratos de cada modulo: que hace, que expone y que no debe tocar.
- Limitaciones conocidas del cliente Epsilon: strata, hooks, frames.
- Enfoques que ya se probaron y fallaron.
- Patrones de codigo establecidos.

Documentacion auxiliar:

- [`CLAUDE.md`](CLAUDE.md): resumen compacto para Claude Code.
- [`.github/copilot-instructions.md`](.github/copilot-instructions.md): resumen compacto para GitHub Copilot.

### Flujo De Trabajo

- **Rama de trabajo**: `dev`; nunca hacer commits directos a `main`.
- **`main`**: version estable, probada en el servidor.
- **`dev`**: desarrollo activo.
- Para una feature nueva: branch `feature/nombre` desde `dev`, PR a `dev`.
- Para pasar a produccion: PR de `dev` a `main` con review.

### Diagnosticos Temporales

No anadir codigo de debug en modulos de gameplay. Usar siempre:

```lua
HarfordDebug.RegisterCommand("micomando", function(args)
    -- diagnostico aqui
end, "Descripcion breve")
```

Y ejecutar en juego con `/hdebug run micomando`.
