# Harford DnD 5e

Addon de World of Warcraft para el servidor Epsilon RP de la Compania Harford. Implementa un sistema de D&D 5e dentro del juego: ficha de personaje, recursos, reputaciones, combate por turnos, loot, sincronizacion entre jugadores y herramientas DM opcionales.

> Addon privado. Requiere acceso al servidor Epsilon de la Compania Harford.

**Consultor web (canonico)**: <https://harfordweb.marcos-pazos-95.workers.dev/> - reglas del
sistema (clases, razas, trasfondos, conjuros y profesiones) navegables fuera del juego. Los
datos se extraen del addon con `tools/codice/build_codice.py` (`kb_icons.json`).

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
2. Copiar las carpetas **`Harford/`**, **`HarfordAdmin/`** y (opcional) **`HarfordDebug/`** a:
   ```
   [Cliente Epsilon]\_retail_\Interface\AddOns\
   ```
3. Iniciar el cliente Epsilon y activar **`Harford`** en el selector de addons.
4. Activar **`HarfordAdmin`** solo en cuentas con permisos de DM/Admin. Las herramientas DM requieren `HarfordAdmin` cargado y `.ph dm` activo.
5. Activar **`HarfordDebug`** solo durante una investigacion tecnica. Es opcional, depende de `Harford` y guarda sus capturas/debug en SavedVariables propias.

---

## Slash Commands

| Comando | Descripcion |
|---|---|
| `/harford ficha` | Abre la ficha compacta de personaje D&D 5e |
| `/harford cargarficha` | Carga DESTRUCTIVA de la ficha desde el perfil TRP3 activo (unica via de importar TRP3) |
| `/harford char` (`personaje`) | Abre el panel de personaje: Personaje y Reputacion. Habilidades, Conjuros y Profesiones se abren en una ventana independiente. |
| `/harford char crear` | Abre el creador de personaje. |
| `/harford char subir` | Abre el asistente moderno de subida de nivel. Tambien se accede desde la flecha junto al nivel en el panel de personaje. |
| `/harford inspect` | Inspecciona en modo ligero/read-only el panel de personaje del target jugador o del nombre indicado |
| `/harford rep` (`reputacion`) | Abre/cierra el panel de personaje en la pestaña Reputacion |
| `/harford turnos` | Abre/cierra el tracker de turnos |
| `/harford comunicador` | Abre el comunicador normal |
| `/harford radio` | Abre el comunicador sin aplicar su aura visual |
| `/harford contratos` (`tablon`) | Abre el tablon de contratos como ventana independiente |
| `/harford misiones` (`quests`) | Abre el registro de misiones Harford |
| `/harford herramientas` (`tools`) | Abre/cierra la bandeja de herramientas |
| `/harford reparto [id]` (`questreward`) | DM: reparte rep/xp de una mision de mundo al grupo (requiere modo DM) |
| `/harford config` | Panel de configuracion del addon |
| `/harford debug` | Sistema de debug opcional: on/off/toggle/status/list/run; requiere `HarfordDebug` |
| `/FichaHarford`, `/hchar`, `/harfordrep`, `/hconfig`, `/hdebug` | Retirados; usar `/harford <subcomando>` |
| `/harfordadmin` | Herramientas de DM/Admin: loot, reputaciones, fichas NPC y acciones sobre NPCs |
| `/harford loot` / `/harford cargarloot` | Editor admin de loot; requiere `HarfordAdmin` |
| `/harford compendio` / `/harford magia` | Abre el compendio de conjuros Harford |

---

## Estructura Del Proyecto

```text
Harford/            <- Addon principal: jugadores y DM (85 modulos en 16 carpetas)
  Core/               Transporte, chat, configuracion, autoridad y utilidades puras
  Server/             Comandos validados hacia el servidor Epsilon
  TRP3/               Lectura y escritura de perfiles de TotalRP3
  Compendium/         Compendio de conjuros (catalogo + lanzamiento)
  DnD/
    Data/             Libros: clases, razas, trasfondos, dotes, armas
    State/            Ficha, progresion, equipo y formas (SavedVariables)
    Engine/           Reglas: calculo, tiradas, combate, condiciones, area y red
    UI/               Ficha de personaje y controles de tirada
  Character/          Creacion, subida de nivel, libro, conjuros e inspeccion
  Frames/             Overlays de unitframes y nameplates + tracker de turnos
  Reputation/         Facciones y rangos por personaje
  Quests/             Misiones: catalogo, estado, registro y tracker
  Contracts/          Tablon de contratos con autoridad DM
  Professions/        Profesiones y recetas
  Communicator/       Mensajeria RP y bandeja de herramientas
  Loot/               Loot resuelto y configuracion compartida
HarfordAdmin/       <- Addon admin: herramientas DM, editores y comandos protegidos
HarfordDebug/       <- Addon opcional: diagnostico, probes y limpieza de SavedVariables

tools/              <- Generadores: ESTRUCTURA.md, CHANGELOG.md y la extraccion de datos para la web (tools/codice/)
ESTRUCTURA.md       <- Organigrama de modulos: que hace cada archivo y como fluyen los datos
CHANGELOG.md        <- Historial de cambios del proyecto
AGENTS.md           <- Arquitectura, contratos de modulos y enfoques fallidos
CLAUDE.md           <- Instrucciones para Claude Code
.github/
  copilot-instructions.md  <- Instrucciones para GitHub Copilot
.cursorrules        <- Instrucciones para Cursor AI
```

> Los archivos se cargan **en el orden del `.toc`** y comparten el namespace global: no hay
> `require` ni rutas entre archivos. Mover un modulo de carpeta es seguro siempre que su
> dependencia siga cargando antes. Detalle completo en [`ESTRUCTURA.md`](ESTRUCTURA.md).

---

## Arquitectura Resumida

- **Harford** contiene el core compartido: ficha D&D, recursos, turnos, reputaciones, loot visible/usable, unitframes, nameplates, sync addon y acciones servidor validadas que tambien pueden necesitar jugadores.
- **HarfordAdmin** contiene la capa DM: menu contextual, ficha Modo NPC, editores de loot/reputacion, compartir datos, ajustar recursos/reputacion y comandos protegidos.
- **HarfordCompendio** vive como modulo dentro de `Harford`: compendio de conjuros con SavedVariables propias y API `_G.HarfordCompendioAPI`.
- El icono de tabardo de la ficha abre el **Panel de Personaje**. La ficha compacta queda para tiradas; el panel unificado contiene Personaje y Reputacion. **Habilidades**, **Conjuros** y **Profesiones** se muestran en una ventana independiente, que puede permanecer abierta junto al panel de personaje. Desde **Profesiones**, el sello de una profesion abre su ventana de recetas (replica del frame nativo de crafteo).
- El panel de **Habilidades** replica el libro nativo y lista las habilidades por categoria (pasiva / activable al atacar / reaccion / directa). Las activables al atacar comparten estado con el control `Daño extra` de la ficha. Hay una **barra de accion** opcional (activable en config) para colocar habilidades del Libro.
- La progresion usa datos hardcodeados por clase/subclase, raza, trasfondo y dotes, con efectos declarativos que se suman sobre valores manuales. Los rasgos se aplican internamente; el usuario solo elige cuando existe una eleccion real (`choice`) o cuando un rasgo declara un estado activable (`toggleState`, por ejemplo Metamorfosis/Transformado/Lobo Solitario). Se sincroniza con `DNDCLASS` dentro de `DND5EARC`.
- El equipo del panel es virtual: se arrastran objetos reales del juego a los slots de Harford, se guardan como item links, se muestran con su icono/tooltip y se sincronizan con `DNDEQUIP`; no se equipa ni se desequipa el personaje real de WoW.
- Los objetos custom de Epsilon pueden llevar descripcion narrativa normal y, aparte, lineas mecanicas claras que Harford parsea, por ejemplo `Naturaleza +1`, `Fuerza +2`, `Salvacion Destreza +1`, `CA +1`, `Armadura 14`, `Ataque +1`, `Dano +1`, `Ataque conjuro +1`, `CD conjuro +1` o `Dano extra 1d6 fuego`. Lo que no siga ese formato queda solo como descripcion.
- Los slots de arma y pecho tienen selector basico por flecha. Si hay objeto equipado, el objeto tiene prioridad y la seleccion basica queda guardada como fallback.
- Si el arma activa viene de un objeto equipado, las tiradas de ataque y dano muestran el link del arma en el chat.
- Los daños condicionales de clase usan el mismo control `Daño extra` (y ahora tambien el boton de la habilidad en el **Libro**): pueden sumar dados o valores planos (`PB`, nivel de clase o modificador) y se consumen al tirar daño.
- Los comandos Epsilon se construyen desde plantillas y acciones validadas (`HarfordCommandTemplates` + `HarfordServerActions`), nunca desde texto arbitrario recibido de otros clientes.
- La mitigacion de dano (`resistente`, `inmune`, `vulnerable`) se calcula en core con el stat block TRP3 del target y se muestra en la tirada con marcadores `R`/`I`/`V`. Admin solo aplica el total ya calculado.
- La herida visual de NPC al perder vida se centraliza en `HarfordServerActions.SetNpcHealthDelta`: emote `33` para dano normal y `34` para dano critico.
- El compendio de conjuros se abre con `/harford compendio`; al confirmar un lanzamiento con exito consume mana o un espacio de conjuro segun el modo global configurado. Si el conjuro declara ataque de conjuro, salvacion directa o area reconocible, usa las mismas rutas de tirada/area de Harford; si no, se anuncia como lanzamiento informativo. Los rituales no consumen coste.
- **Sistema de experiencia propio** (Epsilon no tiene XP real): la XP vive en la ficha, usa la tabla oficial 5e y se muestra en una barra propia y estable en el borde inferior. Las misiones conceden su XP real; al alcanzar el umbral se anuncia que hay nivel disponible y la flecha junto al nivel, o `/harford char subir`, abre el asistente moderno para aplicarlo. El nivel total esta limitado a 20, incluida la multiclase y las rutas de importacion. Con `Ctrl+click` en una faccion del panel de Reputacion se la sigue en una segunda barra; `Shift+click` inserta un enlace TRP3 clicable de la faccion en el chat. Todo se activa/desactiva con la opcion "Barra de experiencia" del panel de configuracion.

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

Y ejecutar en juego con `/harford debug run micomando`.
