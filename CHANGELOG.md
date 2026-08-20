# Historial de cambios

Historial del addon Harford, generado desde los commits del repositorio y ordenado del mas
reciente al mas antiguo. Para la arquitectura y los contratos vigentes mira **`AGENTS.md`**;
para el mapa de modulos, **`ESTRUCTURA.md`**.

Convenio de los mensajes: `feat` nuevo, `fix` arreglo, `refactor` reorganizacion sin cambio de
comportamiento, `docs` documentacion y `chore` mantenimiento.

Regeneralo con `python tools/gen_changelog.py`.

- Commits: **66** - del **2026-05-18** al **2026-08-20**

## Agosto de 2026

**Nuevo**

- **about** - frame de Profesiones en el About generado de TRP3 `8d39639`
- **profesiones** - el DM puede enseñar recetas worldLearned (TEACH) `7240769`
- **profesiones** - nodos de recoleccion en el mundo (GatherNode) `20f0b4a`
- **debug** - merchantdump vuelca los items del mercader abierto `0642999`
- **profesiones** - cadenas completas 1-300 para las 14 profesiones de WoW `ad22a7b`
- **creacion** - compra por puntos ademas de la tirada, con +/- `47227ce`
- **creacion** - panel de resumen del personaje `622d960`
- **creacion** - rejilla de iconos para raza y trasfondo `56d977e`
- **creacion** - barra de pasos lateral al estilo BG3 `28895fc`
- **colores** - color propio para las 36 subclases en el About `9c15337`
- **panel** - fila de Competencias y arreglo de las elecciones repetibles `54a8bfb`
- **trasfondos** - descripcion completa en el About de TRP3 `ff91228`

**Arreglos**

- **creacion** - reinicia la compra por puntos al reabrir el asistente `ee6daa3`
- elimina el multi-retorno de gsub en los 8 normalizadores restantes `8cb678e`
- **creacion** - la Pericia ofrecia todas las habilidades en el asistente `b14f5af`
- **colores** - paleta de clase exacta y colores de subclase de los perfiles `41fb05f`
- **contratos** - la lista del tablon acumulaba filas de todos los refrescos `5389abc`
- **trp3** - normalizadores que devolvian dos valores por el gsub final `358bf74`
- **servidor** - filtra saltos de linea al normalizar un comando Epsilon `6d57100`
- **creacion** - las fichas creadas perdian los incrementos de caracteristica `4a68ae7`
- **progresion** - evita huecos en classLevels al fijar una entrada de clase `a78b72a`
- **loot** - valida el remitente de HARFORDLOOT y HARFORDCFG `c044433`
- **turnos** - valida el remitente de los mensajes HARFORDTURN `7da4ee6`
- **competencias** - pericia solo sobre habilidades competentes y quita HasToolProf duplicada `bacbd17`
- **docs** - repara el mojibake de AGENTS.md `1c646d7`
- **admin** - unifica salida de chat y mejora NPC/condiciones/misiones `b05254d`

**Refactor**

- organiza el addon en carpetas por dominio `918a636`

**Documentacion**

- regenera el historial de cambios `9d7b568`
- organigrama de modulos (ESTRUCTURA.md) e historial (CHANGELOG.md) `e5e4137`
- actualiza el README (HarfordDebug y subcomandos /harford) `108184f`

**Mantenimiento**

- **tools** - pipeline de extraccion del conocimiento y comando profitems `d228f9a`
- **tools** - generadores de ESTRUCTURA.md y CHANGELOG.md `331fd2e`
- ignora RuleSource/, Codice_Harford.html y AddonsIndependientes/ `1b65b2a`
- añade el addon opcional HarfordDebug e ignora EpsilonIcons/ `582d403`

**Otros**

- revert(colores): deja la paleta de clase como estaba `6cc7032`

## Julio de 2026

**Refactor**

- extrae la pestaña Conjuros a HarfordCharacterSpellbook `2337695`

## Junio de 2026

**Nuevo**

- compendio de conjuros en core + motor de area extendido + condiciones `5ec9ad4`
- panel de personaje + razas/trasfondos/dotes/mana + competencias + animaciones de combate `7ba8492`

**Refactor**

- cache de pieces nativos + unificacion de helpers (acentos/toN/nombres) `1ad801d`

**Otros**

- refactor+feat: maniobras de energia, dano por tipo, auras bajo barras y limpieza `deb8eee`
- Panel de jugador `ac93085`

## Mayo de 2026

**Nuevo**

- tooltip en todos los botones de recurso con la pista de Ctrl+click `6e9d03c`
- Ctrl+click en botones del frame de recursos abre prompt de cantidad `2508ad1`
- "Enviar ficha" como primera opcion del menu admin con target jugador `27ae485`
- color de clase TRP3 en nameplates + nombre sobre barras Kui + glow absorb `dbdc977`
- vida temporal (absorb bar) con Shield-Fill, texto +X y fix resize nameplates `214e88c`

**Arreglos**

- daño jugador->jugador + recuperar CA del focus `0964129`
- enganchar eventos TRP3 para el retrato del player (login lento) `380d07b`
- re-aplicar retrato/icono TRP3 del player tras login (timing TRP3) `190b25e`
- BonusConcat varargs pasaba el siguiente arg como base a tonumber `ec99e82`

**Refactor**

- DRY del glue de tiradas d20 en HarfordDnDCalc `dbf6c55`
- completar y documentar frontera admin/core de HarfordTurns `f9fa5cd`
- HarfordDnDRolls/UI/Profile + fix daño custom `1439b40`
- integrar modulos en core/admin + modelo de autoridad 3 ejes `013b995`
- modulos de datos/calculo/red + DRY color de clase y geometria `9449521`

**Documentacion**

- contratos de modulos nuevos, modelo de autoridad 3 ejes y limites WoW `4a7fe45`

**Otros**

- debug: comando portraitwatch + nota caso retrato player (no resuelto) `58a72f5`
- Mejoras `7e7aae0`
- Reputacion, UI admin y mejoras de sistema `f9722c2`
- Arreglo rep y nameframes `ba9ccc7`
- Reputacion `a8b8892`
- Actualizacion `00b97f5`
- Ajusta nameplates y unitframes Harford `18ea19a`
- Merge pull request #1 from Griker95/dev `34a68d4`
- Ajusta unitframes y overlays Harford `35ad757`
- Initial commit: Harford DnD 5e addon + documentación de agentes `9631f19`
