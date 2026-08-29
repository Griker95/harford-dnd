# Estado de mecanización por clase (niveles 1-6)

Las **12 clases repasadas** contra su capítulo del manual (`Rulebooks/`).

Un rasgo cuenta como **mecanizado** si tiene efectos declarativos, elección,
usos, coste de recurso que se cobra, conjuros concedidos, `actionKind` propio o
es una reacción. Los `informativo` sin mecánica **no son deuda**: la norma del
proyecto es no convertir ventajas situacionales sin una capa mecánica explícita.

Regenerar las cifras: cargar `HarfordDnDBook.lua`, los doce `Classes/*.lua` y
`HarfordDnDBookDerived.lua` en el orden del `.toc`, y recorrer `GetClasses()`.

**2026-08-28, tarde: 100% ATENDIDO.** La metrica cambio de "mecanizado/total" a la pregunta que
de verdad importa: ¿queda algun rasgo SIN DECIDIR? Cada rasgo 1-6 es ahora una de tres cosas:

1. **Mecanizado** — efectos, usos, grants, area, `cast` con coste, `grantsAsBonus`/`grantsTurnAction`
   (Accion Astuta ya lo estaba y no se contaba), trampas, danos condicionales.
2. **Pasivo deliberado** (`type = "pasivo"`) — no hace nada activo y esta bien que no lo haga:
   narrativas (Empatia animal, Misivas), cabeceras de lanzamiento (la mecanica vive en el
   Compendio), indices de opciones ya ejecutables (los tres `Canalizar` del Paladin resumen
   rasgos que existen completos), y presentacion de maquinaria externa (los tres de bestia,
   cuya mecanica vive en HarfordDnDBeast).
3. **Marcador de subclase** — el Libro lo filtra; no cuenta en el total.

El limbo — `informativo` sin mecanica, indistinguible de "sin revisar" — se vacio: 32 rasgos
reclasificados a pasivo tras leerlos uno a uno, y tres correcciones que salieron del repaso:
*Momentum vengativo* estaba tipado como accion siendo un disparador pasivo; los *brebajes del
Monje* no cobraban la accion que su propio texto declara ("usarlos cuesta una accion", Buey Negro
incluido); y *colocar una trampa* no cobraba la accion que el texto de Trampero declara.

| Clase | Rasgos 1-6 (sin marcadores) | Atendidos | % |
|---|---|---|---|
| Las 12 | 349 | 349 | **100** |

La suite `coste_de_accion` carga los ficheros REALES y exige los dos invariantes: todo activable
declara su coste, y nadie vuelve al limbo. Un rasgo nuevo tiene que decidir que es.

**El mismo trato se aplico despues a RAZAS (177 rasgos), TRASFONDOS (193) y DOTES (139)**: sus 227
del limbo eran, sin excepcion, lo que la norma ya dice que se queda guiado -- vision en la
oscuridad, ventajas situacionales, resistencias, idiomas, herramientas, armas naturales, equipo --
y pasaron a `pasivo` deliberado (cero activables sin coste entre ellos, verificado antes del
volcado). El candado de la suite cubre las tres familias: **509 rasgos de datos, 0 en el limbo**.

El Mago sale bajo porque casi todo su peso está en Metamagia y en los tres
Estudios, que son texto de referencia; su mecánica real (puntos, metamagia,
estudios) está completa.

---

## Los tres fallos que se repitieron en casi todas

**1. Sub-rasgos nombrados que no existían.** La clase declaraba un recurso y
**ninguna forma de gastarlo**: las 4 características de Chi del Monje, las 3 de
Enfoque del Cazador, los gastos de fragmento del Brujo, Devoción del Sacerdote,
Lanzamiento Flexible del Mago, Potenciar Protecciones del Cazador de Demonios.

**2. Catálogos como muro de texto, y truncados.** Las Maldiciones del Brujo
tenían **2 de 8** (la segunda cortada a media frase) y las Trampas del Cazador
**3 de 8**. Ahora son elecciones con rasgos generados.

**3. Nombres de conjuro divergentes.** Unas 40 equivalencias resueltas **por
nivel y efecto, nunca por parecido**: `Rayo de hechicería` parece *rayo del caos*
y es *witch bolt*. Ver [`CONJUROS_PENDIENTES.md`](CONJUROS_PENDIENTES.md).

## Errores de regla corregidos

| Clase | Qué estaba mal |
|---|---|
| Caballero de la Muerte | **Espiral de la Muerte** se resolvía con salvación y el manual dice ataque de conjuro; faltaba además que cure a no-muertos |
| Cazador de Demonios | Equipo y competencia apuntaban a la **Guja** marcial (pesada, a dos manos) en vez de a la **Guja de guerra**, lo que dejaba al Illidari sin Destreza con su arma característica |
| Cazador de Demonios | **Visión Espectral** decía nivel 7 donde el manual dice 4; **Metamorfosis** no aplicaba su +10 pies de velocidad |
| Chamán | **Mejora** se trataba como lanzador completo siendo **medio lanzador** |
| Sacerdote | **Encadenar no muertos** era un enlace al conjuro homónimo, siendo una habilidad de 3 puntos de fe en área |
| Monje | Los brebajes se concedían **todos**; el manual da Buey Negro + uno a elegir |
| Guerrero | Sus 10 maniobras elegibles salían como **pasivas**, no ejecutables |
| Pícaro | El Sutileza tenía **0 trucos** disponibles pese a conocer 3 |
| Guerrero | *Heridas profundas* y *Golpe mortal* costaban 3 puntos de ira; el manual dice 2 |

---

## Bloqueos transversales

Ordenados por cuántas clases desbloquean.

### Criatura acompañante — 4 clases — **RESUELTO (verificado 2026-08-28)**

Las siete páginas existen en `HarfordDnDCompanionsData` y el Libro las abre con su flyout
(invocar/despedir/ordenar): esbirro no-muerto (CdM), elemental de agua (Mago) y los cinco
demonios del Brujo del Anexo C (guardia vil, manáfago, diablillo, súcubo, abisario), con la
fórmula de PG por invocador y el coste de ordenar declarados. La bestia del Cazador va aparte
por diseño: bloque libre en TRP3 transformado por `HarfordDnDBeast`. La nota de "pendiente"
llevaba tiempo desfasada.

#### El detalle histórico

Todas comparten la misma forma en el manual: bloque de estadísticas propio,
iniciativa compartida contigo pero turno inmediatamente después, y **solo toma
la acción de Esquivar salvo que gastes tu acción en ordenarle otra**.

| Clase | Criatura |
|---|---|
| Brujo | Esbirro demoníaco (Grimorio de Servidumbre) |
| Cazador | Bestia compañera (Vínculo del Compañero) |
| Caballero de la Muerte | Esbirro no-muerto (Levantar a Los Muertos) |
| Mago | Elemental de agua (Dedos de Escarcha) |

Es el bloqueo más rentable del proyecto.

### Conversión puntos ↔ ranuras — RESUELTO

Mago (Lanzamiento Flexible) y Sacerdote (Devoción) convierten de verdad:
`HarfordDnDMana` crea/consume ranuras (`SpellSlotsBonus`), el menú del Libro
elige el nivel y el descanso largo hace desaparecer las creadas. Candado en
`tools/pruebas/furia_y_riders.lua`.

### Otros — RESUELTOS

| Bloqueo | Resolución |
|---|---|
| Estilos de combate sin condición | Flags `styleDefense/styleDueling/styleArchery/styleSharpshooter`; el motor los evalúa con el arma/armadura delante (suite `estilos_condicionales`) |
| Riders del CdD | Embestida Vil tira y publica el dado de Caos al usar Momentum; Momentum Vengativo devuelve el punto de Vil si AMBAS mordidas impactan (CA resuelta) |
| Furia Elemental (Chamán) | Botón en el Libro elige el tipo; el Compendio convierte los componentes elementales de cada conjuro (suite `furia_y_riders`) |

## Decisión de mesa pendiente — RESUELTA (2026-08-29)

**El `casterType` del Brujo**: la mesa decidió AMBAS. `casterType = "pact"` ya
implementa exactamente eso en `CasterContribution` (`HarfordDnDMana`): con la
variante de maná cuenta su nivel entero (funciona como siempre) y en modo
ranuras usa su tabla de magia de pacto (`PACT_SLOTS`, recarga en descanso
corto, se gasta antes que las ranuras normales). Verificado por el grupo
`espacios` de la batería in-game.

## Sin verificar — VERIFICADO (2026-08-29)

Los iconos de las maniobras del Guerrero y de las Maldiciones del Brujo se
comprobaron contra el cliente con la batería (`grupo iconos`, incluye la tabla
por nombre completa con `GetFileIDFromPath`): **todos existen en el build**.
Batería completa: 178 ok / 0 fallos en GRIKER, 183 ok / 0 fallos en MORTYN.

## Cierre 2026-08-29 (tarde)

- **Conjuros pendientes: 6/6 resueltos.** Cinco equivalencias (penitencia =
  `arrepentimiento`, descarga mental = `aguijon_mental`, castigo abrasador =
  `golpe_llameante`, castigo justo = `golpe_justo`, estallido estelar =
  `oleada_estelar`, Conocer la Intención = `impacto_certero`) y rayo del caos
  incorporado por la web y cableado en Destrucción. La petición a la web queda vacía.
- **Prerrequisitos de dote APLICADOS los cuatro tipos**: raza (13 dotes,
  `requiredRaces` con subrazas), característica (5, `requiredAbility`, "una de la
  lista llega al mínimo"), competencia (5, `requiredProficiency` por token) y
  lanzador (6, `requiredCaster` any/class con puertas de nivel de medio y tercio).
  Validados en creación (borrador) y subida (ficha viva). El requisito racial de
  subclase (Sacerdocio de Elune) se filtra también en las tarjetas del asistente.
- **Contenido cotejado contra la web** por id en las cuatro familias: trasfondos
  (41 descs + 61 rasgos), razas (38 + 82), clases (188 seguras, 106 con mecánica
  adaptada respetadas) y dotes (11). Los 10 marcadores de subclase llevan ahora
  `subclassMarker = true` (la detección por frase se rompió con el texto web).
- **Magia racial en el grimorio**: los `spellGrants` de raza/subraza cuentan como
  siempre preparados (puerta `minCharacterLevel`), trucos elegidos incluidos.
- **Verificado in-game**: batería 0 fallos en GRIKER (182 ok, con la nota de
  inmunidad al sueño del Renegado, que es la mecanización funcionando) y MORTYN.

