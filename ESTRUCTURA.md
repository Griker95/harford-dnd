# Estructura del addon Harford

Organigrama de los modulos: que hay en cada carpeta, que hace cada archivo y como fluyen los
datos entre capas. **Documento generado desde el codigo** con `python tools/gen_estructura.py`;
regeneralo cuando muevas o añadas un modulo.

- Contratos de modulo, limitaciones de Epsilon y enfoques fallidos: **`AGENTS.md`**
- Instrucciones para agentes: **`CLAUDE.md`** - **`.github/copilot-instructions.md`**
- Historial de cambios: **`CHANGELOG.md`**

## Resumen

| | |
|---|---|
| Modulos (`Harford/`) | **117** en **17** carpetas |
| Lineas de codigo | ~150 521 |
| Addons hermanos | `HarfordAdmin/` (herramientas DM) - `HarfordDebug/` (diagnostico, opcional) |

## Capas y orden de carga

WoW carga los archivos **en el orden del `.toc`**, y todos comparten el namespace global: no hay
`require` ni rutas entre archivos. Por eso el orden es lo unico que importa, y va de la
infraestructura hacia la interfaz. Mover un archivo de carpeta es seguro; cambiarlo de sitio en
el `.toc` solo lo es si su dependencia sigue cargando antes.

```
Core --> Server --> TRP3 --> Compendium
  |
  +--> DnD/Data --> DnD/State --> DnD/Engine --> DnD/UI
                                      |
                                      +--> Character - Frames - Reputation - Quests
                                           Contracts - Professions - Communicator - Loot
```

## `Core/` - Infraestructura

Transporte, chat, configuracion, autoridad y utilidades puras. No depende de nadie.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordSync.lua` | 2320 | Transporte de addon messages: serializacion, troceo en chunks, canales y reensamblado con TTL. |
| `HarfordPhaseStore.lua` | 276 | Transporte comun del almacen de fase de Epsilon: escribir con pcall, leer con plazo y vaciar segmentos. Comparte el como, no la politica. |
| `HarfordChat.lua` | 32 | Salida comun para mensajes visibles de Harford. |
| `HarfordUISounds.lua` | 119 | Sonidos de interfaz centralizados. |
| `HarfordConfig.lua` | 277 | Ajustes del addon con listeners de cambio (gates tipo `actionbar`, modo de coste de conjuros). |
| `HarfordAuthority.lua` | 270 | Fuente unica de autoridad: rango de phase, modo DM y permisos (`IsOfficerPlus`, `CanUseDMTools`). |
| `HarfordClassColors.lua` | 169 | Fuente unica de verdad para el color de clase WoW. |
| `HarfordUIGeom.lua` | 114 | Helpers puros de geometria y busqueda de StatusBars usados por los overlays de HarfordUnitFrames. |
| `HarfordDamageTypes.lua` | 122 | Tabla de datos de tipos de dano D&D 5e. |

## `Server/` - Servidor Epsilon

Comandos validados hacia el servidor. Solo se entra por aqui.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordEpsilonCommands.lua` | 197 | Wrapper de bajo nivel sobre EpsilonLib/ARC para enviar comandos al servidor. |
| `HarfordCommandTemplates.lua` | 61 | Plantillas de comandos Epsilon con placeholders {clave}. |
| `HarfordEmotes.lua` | 208 | Tabla de datos de emotes/animaciones servidor que el addon usa. |
| `HarfordServerActions.lua` | 315 | Acciones de servidor validadas (dar item, auras, vida y emotes de NPC). Unica puerta desde gameplay. |
| `HarfordActionSequence.lua` | 238 | Motor propio de "secuencias de acciones con delay", equivalente ligero a una ArcSpell de SpellCreator (lista de pasos temporizados). |
| `HarfordActionSequencePresets.lua` | 695 | Catalogo hardcodeado de secuencias de ataque decodificadas desde SpellCreator/ArcSpell. |
| `HarfordAuras.lua` | 97 | Tabla de datos de auras "conocidas" por el addon. |

## `TRP3/` - Integracion TRP3

Lectura/escritura de perfiles de TotalRP3.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordTRP3.lua` | 2729 | Lectura segura de perfiles TRP3: ficha de jugador, stat block de NPC, enlaces y escritura del About. |

## `Compendium/` - Compendio de conjuros

Catalogo y resolucion de lanzamiento.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordIconCatalog.lua` | 1076 | Registro comun de iconos de contenido. |
| `HarfordCompendioCore.lua` | 1277 | API del compendio: coste y resolucion de lanzamiento (`ResolveCast`), progresion de conjuros y filtros. |
| `HarfordCompendioData.lua` | 9336 | Catalogo de conjuros (nivel, escuela, componentes, dano, mecanica). Solo datos. |
| `HarfordCompendioIconMap.lua` | 72 | Resuelve el icono de un conjuro (fileID, `spell:`, ruta o LibRPMedia). |
| `HarfordCompendioUI.lua` | 1546 | Ventana del compendio: listado, filtros y detalle de conjuro. |

## `DnD/Data/` - D&D - Datos

Libros hardcodeados: clases, razas, trasfondos, dotes, armas, mitigacion.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordDamageMitigation.lua` | 281 | Resuelve si una unit es inmune/resistente/vulnerable a un tipo de dano leyendo el stat block TRP3 ya parseado por HarfordTRP3.GetNPCStatBlock. |
| `HarfordDnDData.lua` | 391 | Tablas de datos estaticos de la ficha D&D 5e. |
| `HarfordDnDBook.lua` | 519 | Libro hardcodeado de clases/subclases/rasgos. |
| `HarfordDnDBookDerived.lua` | 44 | Rasgos derivados COMUNES a todas las clases. |
| `HarfordDnDBookText.lua` | 12823 | Fuente local del Libro en Markdown y lectura segura de secciones. |
| `HarfordDnDRaces.lua` | 659 | Libro hardcodeado de razas (World of Warcraft D&D 5ª Ed. |
| `HarfordDnDBackgrounds.lua` | 796 | Libro hardcodeado de trasfondos (World of Warcraft D&D 5ª Ed. |
| `HarfordDnDFeats.lua` | 629 | Libro hardcodeado de dotes (World of Warcraft D&D 5ª Ed. |
| `HarfordDnDWeapons.lua` | 225 | Tabla WEAPONS + helpers de arma sin estado de UI. |
| `HarfordDnDFormsData.lua` | 89 | Las 7 formas canonicas de Cambio de Forma (Anexo A del manual). |
| `HarfordDnDCompanionsData.lua` | 271 | Bloques de estadisticas de las criaturas acompanantes. |

## `DnD/Data/Classes/` - D&D - Clases

Una clase por archivo: sus datos y el generador de rasgos derivados que solo le afecta. Se apilan en `API.CLASSES` en el orden del `.toc`; el nucleo (`HarfordDnDBook.lua`) carga antes y `HarfordDnDBookDerived.lua` el ultimo.

| Archivo | Lineas | Rol |
|---|--:|---|
| `CaballerodelaMuerte.lua` | 129 | Caballero de la Muerte: datos de clase para HarfordDnDBook. |
| `CazadordeDemonios.lua` | 110 | Cazador de Demonios: datos de clase para HarfordDnDBook. |
| `Druida.lua` | 133 | Datos de clase para HarfordDnDBook. |
| `Cazador.lua` | 153 | Datos de clase para HarfordDnDBook. |
| `Mago.lua` | 91 | Datos de clase para HarfordDnDBook. |
| `Monje.lua` | 135 | Datos de clase para HarfordDnDBook. |
| `Paladin.lua` | 91 | Datos de clase para HarfordDnDBook. |
| `Sacerdote.lua` | 148 | Datos de clase para HarfordDnDBook. |
| `Picaro.lua` | 96 | Datos de clase para HarfordDnDBook. |
| `Chaman.lua` | 138 | Datos de clase para HarfordDnDBook. |
| `Brujo.lua` | 152 | Datos de clase para HarfordDnDBook. |
| `Guerrero.lua` | 163 | Datos de clase para HarfordDnDBook. |

## `DnD/State/` - D&D - Estado

Persistencia y estado por perfil: ficha, progresion, equipo, formas.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordDnDResources.lua` | 224 | Definicion y orden de los recursos, cache de recursos remotos y flags de animacion. |
| `HarfordDnDStore.lua` | 564 | Persistencia compacta de la ficha (SavedVariables) y helpers numericos compartidos. |
| `HarfordDnDEconomy.lua` | 813 | Saldo de oro por personaje para la economia D&D. |
| `HarfordDnDContext.lua` | 56 | Estado de contexto de ficha + accesores de valores ARC. |
| `HarfordDnDProfile.lua` | 50 | Aplicacion de tablas de perfil/recursos sobre HarfordDnDStore. |
| `HarfordDnDMana.lua` | 337 | Regla adicional de Maná (World of Warcraft D&D 5ª Ed. |
| `HarfordDnDProgression.lua` | 1744 | Estado de clase/subclase/rasgos por perfil. |
| `HarfordDnDItems.lua` | 1367 | Equipo virtual de ficha usando objetos reales del cliente. |
| `HarfordDnDBurden.lua` | 204 | Sintonizacion de objetos magicos y capacidad de carga. |
| `HarfordDnDForms.lua` | 667 | Lectura y estado de las formas druídicas declaradas en TRP3. |
| `HarfordDnDCompanions.lua` | 516 | Estado de la criatura acompanante del jugador. |
| `HarfordDnDBeast.lua` | 214 | La bestia companera del Cazador (Domar Bestia / Vinculo del Compañero). |

## `DnD/Engine/` - D&D - Motor

Calculo y reglas: tiradas, combate, condiciones, area y red.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordDnDCustomDamage.lua` | 256 | Parser, tirada y ventana de daño personalizado. |
| `HarfordDnDRolls.lua` | 308 | Serializacion, render y emision de tiradas Harford DnD. |
| `HarfordDnDConditionalDamage.lua` | 359 | Costes, niveles y escalado de daños condicionales. |
| `HarfordDnDFeatureEffects.lua` | 858 | Interpreta efectos declarativos de rasgos activos. |
| `HarfordDnDConditions.lua` | 1263 | Catalogo y motor de condiciones de combate. |
| `HarfordDnDConcentration.lua` | 164 | Concentracion en conjuros (Manual del Jugador, "Duracion"). |
| `HarfordDnDHeroPoints.lua` | 159 | Puntos de heroe (regla opcional de la Guia del Dungeon Master). |
| `HarfordDnDManeuvers.lua` | 237 | Maniobras de combate del Manual del Jugador que no son un ataque: agarrar, empujar, escapar de un agarre, estabilizar a un aliado y cobertura. |
| `HarfordDnDCalc.lua` | 313 | Calculo puro de la ficha D&D 5e (modificadores, dados, bonos). |
| `HarfordDnDNet.lua` | 146 | Capa de recursos/red de la ficha (export, request, adjust). |
| `HarfordDnDCombat.lua` | 638 | Reglas de combate compartidas que no pertenecen a UI. |
| `HarfordDnDArea.lua` | 1520 | Motor comun de ataques de area. |
| `HarfordDnDComm.lua` | 314 | Despachador de `DND5EARC`: valida el remitente y enruta cada opcode a su handler. |

## `DnD/UI/` - D&D - Interfaz

Ficha de personaje y controles de tirada.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordDnDUI.lua` | 110 | Constantes y fabricas UI pequenas usadas por la ficha Harford DnD. |
| `HarfordDnDAttackUI.lua` | 544 | Construccion y estado visual de la seccion Ataque. |
| `HarfordDnDMinimap.lua` | 165 | Boton de minimapa de la ficha Harford. |
| `HarfordDnD.lua` | 6811 | DND 5e (persistencia local + sync) + UI completa (/harford ficha) |
| `HarfordActionBars.lua` | 166 | Barra de accion de madera para colocar habilidades del Libro. |

## `Character/` - Panel de personaje

Creacion, subida de nivel, libro, conjuros e inspeccion.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordCharacterInspect.lua` | 335 | Inspeccion ligera del panel de personaje de otro jugador. |
| `HarfordCharacterBook.lua` | 321 | Clasificacion y datos de PRESENTACION del Libro (pestaña tipo spellbook de HarfordCharacterPanel). |
| `HarfordCharacterSpellbook.lua` | 446 | Pestaña Conjuros (replica del libro de hechizos poblada por el compendio). |
| `HarfordCharacterCreation.lua` | 1511 | Valida y aplica el borrador del creador, incluido el About de TRP3. |
| `HarfordCharacterAdvancement.lua` | 2606 | Prototipo visual de creacion y progresion. |
| `HarfordCharacterXP.lua` | 544 | Sistema de experiencia propio de Harford (D&D 5e). |
| `HarfordCharacterPanel.lua` | 6518 | Panel de personaje unificado. No sustituye el panel de reputaciones; lo usa como modulo externo desde una pestana. La primera vista siempre es la ficha/resumen del PJ. |

## `Frames/` - Frames del juego

Overlays sobre unitframes, nameplates y tracker de turnos.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordUnitFrames.lua` | 4733 | Overlays de Harford sobre los unitframes nativos (target, focus, ToT, party/raid). |
| `HarfordNamePlates.lua` | 1045 | Overlays sobre nameplates nativos y KuiNameplates. |
| `HarfordTurns.lua` | 2587 | Visual initiative tracker for Harford. |

## `Reputation/` - Reputacion

Facciones y rangos por personaje.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordReputation.lua` | 852 | Nucleo de reputaciones: facciones, puntos por PJ y rangos. |
| `HarfordReputationPhase.lua` | 359 | Facciones guardadas en la fase, con espejo local de ids para no pisar el trabajo de otro DM. |
| `HarfordReputationSync.lua` | 687 | Sync de reputacion (`HARFORDREP`) con snapshots troceados y TTL. |
| `HarfordReputationUI.lua` | 1628 | Panel de reputaciones, standalone o embebido en el panel de personaje. |

## `Quests/` - Misiones

Catalogo, estado por PJ, registro, tracker y quests de mundo.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordQuestCatalog.lua` | 65 | Catalogo de misiones canonicas reutilizables (patron "indice + libro"). |
| `HarfordQuests.lua` | 1136 | Estado per-PJ de misiones (quest log Harford) Capa de SISTEMA (addon), cross-fase, per-personaje. |
| `HarfordQuestLog.lua` | 1257 | Registro de misiones Harford. Replica la composicion de ClassicQuestLog 2.1.0 para Shadowlands: ButtonFrameTemplate, HybridScrollFrameTemplate y QuestScrollFrameTemplate. El estado de las... |
| `HarfordQuestTracker.lua` | 222 | Misiones Harford como modulo real del ObjectiveTracker de Shadowlands. |
| `HarfordWorldQuests.lua` | 1020 | Capa de quests de MUNDO (NPC de fase) sobre el nucleo HarfordQuests. |

## `Contracts/` - Contratos

Tablon de contratos con autoridad DM.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordContractsCore.lua` | 253 | Nucleo del tablon: estado, SavedVariable y gate de modo DM. |
| `HarfordContractsData.lua` | 451 | Modelo de contratos: alta, edicion, borrado, dificultad y orden. |
| `HarfordContractsRewards.lua` | 116 | Capa de recompensas compartidas (XP/rep) sobre los contratos. |
| `HarfordContractsUtil.lua` | 174 | Helpers de presentacion del tablon (iconos, color por dificultad, metadatos). |
| `HarfordContractsUI.lua` | 1799 | Tablon de contratos: lista, detalle y reclamacion de recompensas. |
| `HarfordContractsDM.lua` | 1724 | Editor DM de contratos (crear, publicar, resetear). |
| `HarfordContractsComm.lua` | 972 | Sync del tablon: snapshots fragmentados y autoridad de sesion del DM. |
| `HarfordContractsPhase.lua` | 1086 | Tablon guardado EN LA FASE: indice mas un bloque por contrato. No exige que el DM este conectado. |
| `HarfordContractsMinimap.lua` | 185 | Boton/hub de minimapa del tablon. |

## `Professions/` - Profesiones

Profesiones D&D/WoW y sus recetas.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordObjectCatalog.lua` | 41539 | GENERADO por tools/codice/generar_catalogo_objetos.py. |
| `HarfordProfessionsItems.lua` | 2193 | Registro CENTRAL de items de profesiones (materiales y resultados). |
| `HarfordProfessionFX.lua` | 158 | Presentacion de una fabricacion: animacion, sonido y lo que cada profesion quiera hacer. |
| `HarfordProfessionsCraftSkin.lua` | 205 | GENERADO por tools/codice/gen_frame_from_probe.py a partir de una captura de HarfordFrameProbe. |
| `HarfordProfessionsCraftUI.lua` | 1544 | Ventana de recetas de una profesion Harford, replica del TradeSkillFrame moderno. |
| `HarfordProfessionsData.lua` | 3604 | Catalogo hardcodeado de profesiones + recetas (como HarfordDnDBook). |
| `HarfordProfessions.lua` | 1191 | Core del sistema de profesiones D&D (unifica profesiones WoW + herramientas D&D). |
| `HarfordProfessionTrainers.lua` | 561 | Entrenadores de profesion: quien ensena que receta y donde. |
| `HarfordProfessionTrainerUI.lua` | 687 | Ventana de entrenador de recetas. |

## `Communicator/` - Comunicador

Mensajeria RP fiable y bandeja de herramientas.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordCourier.lua` | 371 | Capa de mensajeria FIABLE (store-and-forward) sobre un CANAL de addon propio. |
| `HarfordToolTray.lua` | 299 | "Herramientas de Rol": bandeja propia de Harford, replica FIEL del Epsilon AddOn Tray (Epsilon_Launcher): mismo panel, misma flecha, misma animacion (scale+alpha con easeOutCubic), mismo... |
| `HarfordCommunicator.lua` | 1210 | Comunicador Harford: version segura inspirada en Noumenon Index. |

## `Loot/` - Loot

Loot resuelto y configuracion compartida.

| Archivo | Lineas | Rol |
|---|--:|---|
| `HarfordLoot.lua` | 863 | Loot resuelto por GUID, configuracion global y su sync (`HARFORDLOOT`/`HARFORDCFG`). |
| `HarfordLootPhase.lua` | 565 | Loot guardado en la fase, con manifiesto local de las claves escritas para poder limpiarlas. |

## Flujo de datos

```
Libros (DnD/Data)        catalogos hardcodeados: clases, razas, trasfondos, dotes, armas
        |
        v
Estado (DnD/State)       progresion, ficha, equipo y formas por perfil -> SavedVariables
        |
        v
Motor (DnD/Engine)       resuelve efectos, calcula y tira; unico que aplica reglas
        |
        v
Interfaz (DnD/UI,        pinta y dispara acciones; no decide reglas
  Character, Frames)
```

Regla practica: **los datos no llaman al motor** (el Libro es capa de datos y lo consume la
importacion de TRP3), y **la interfaz no calcula reglas**: pide el valor ya resuelto.

## Red

Todo mensaje entre clientes pasa por `HarfordSync`. Los receptores que aplican algo **validan
siempre el remitente** (propio, unidad visible o miembro de grupo/raid).

| Prefijo | Modulo | Transporta |
|---|---|---|
| `DND5EARC` | `DnD/Engine/HarfordDnDComm.lua` | Ficha, tiradas, recursos, condiciones, area y auras |
| `HARFORDTURN` | `Frames/HarfordTurns.lua` | Estado del tracker de turnos |
| `HARFORDLOOT` / `HARFORDCFG` | `Loot/HarfordLoot.lua` | Loot resuelto y configuracion global |
| `HARFORDREP` | `Reputation/HarfordReputationSync.lua` | Reputaciones y snapshots |
| `HARFORDQUEST` | `Quests/HarfordQuests.lua` | Estado de misiones y cierre por el DM |
| `HARFCOM` | `Communicator/HarfordCommunicator.lua` | Mensajeria RP (solo texto) |
| `HARFORDPROF` | `Professions/HarfordProfessions.lua` | Enseñar recetas worldLearned (DM -> jugador) |
| Tablon | `Contracts/HarfordContractsComm.lua` | Snapshots de contratos con autoridad de sesion |

## Donde toco cada cosa

| Quiero cambiar... | Archivo |
|---|---|
| Una clase, subclase o rasgo | `DnD/Data/Classes/<Clase>.lua` |
| La API del Libro o un helper compartido | `DnD/Data/HarfordDnDBook.lua` |
| Una raza o un trasfondo | `DnD/Data/HarfordDnDRaces.lua` - `HarfordDnDBackgrounds.lua` |
| Un conjuro | `Compendium/HarfordCompendioData.lua` |
| Como se calcula una tirada o un bonus | `DnD/Engine/HarfordDnDCalc.lua` - `HarfordDnDFeatureEffects.lua` |
| La CA, el impacto o la mitigacion | `DnD/Engine/HarfordDnDCombat.lua` - `DnD/Data/HarfordDamageMitigation.lua` |
| La ventana de la ficha | `DnD/UI/HarfordDnD.lua` |
| La creacion o la subida de nivel | `Character/HarfordCharacterCreation.lua` - `HarfordCharacterAdvancement.lua` |
| Los overlays sobre unitframes | `Frames/HarfordUnitFrames.lua` |
| Un comando al servidor Epsilon | `Server/HarfordServerActions.lua` |
| Un diagnostico temporal | `HarfordDebug/HarfordDebug.lua` (nunca en modulos de gameplay) |
| Algo exclusivo de modo DM | `HarfordAdmin/` (nunca en el core) |
