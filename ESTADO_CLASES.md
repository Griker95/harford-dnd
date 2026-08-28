# Estado de mecanización por clase (niveles 1-6)

Las **12 clases repasadas** contra su capítulo del manual (`Rulebooks/`).

Un rasgo cuenta como **mecanizado** si tiene efectos declarativos, elección,
usos, coste de recurso que se cobra, conjuros concedidos, `actionKind` propio o
es una reacción. Los `informativo` sin mecánica **no son deuda**: la norma del
proyecto es no convertir ventajas situacionales sin una capa mecánica explícita.

Regenerar las cifras: cargar `HarfordDnDBook.lua`, los doce `Classes/*.lua` y
`HarfordDnDBookDerived.lua` en el orden del `.toc`, y recorrer `GetClasses()`.

| Clase | Rasgos 1-6 | Mecanizados | % |
|---|---|---|---|
| Guerrero | 30 | 29 | 96 |
| Monje | 30 | 28 | 93 |
| Cazador de Demonios | 22 | 19 | 86 |
| Cazador | 34 | 29 | 85 |
| Brujo | 47 | 36 | 76 |
| Pícaro | 19 | 14 | 73 |
| Sacerdote | 45 | 32 | 71 |
| Chamán | 40 | 28 | 70 |
| Druida | 22 | 15 | 68 |
| Mago | 20 | 13 | 65 |
| Paladín | 28 | 18 | 64 |
| Caballero de la Muerte | 24 | 15 | 62 |
| **Total** | **361** | **276 (76%)** | |

Cifras regeneradas el **2026-08-28**. El criterio suma desde esa fecha: un `cast` con coste real
(se cobra), y los ejecutables cuya mecánica no vive en `effects` — `trap` (se coloca y se dispara
por el motor de áreas), `usesFrom` (gasta los usos de otro rasgo) y `area` (salvación/daño/condición).
Sin eso, las ocho trampas del Cazador contaban como no mecanizadas **siendo ejecutables**, y la
clase salía 61% cuando está al 85%.

**Cazador, repasado el 2026-08-28**: sus 5 sin mecanizar están todos justificados — *Empatía
animal* es narrativa por norma; el marcador de arquetipo se filtra del Libro; y los tres de bestia
(*Domador*, *Aspecto*, *Vínculo*) son texto de presentación de una mecánica que **sí existe** en
`HarfordDnDBeast` (bloque TRP3 del compañero + reglas del Vínculo: tu competencia sustituye la
suya, se suma a CA y daño, pierde Multiataque). El umbral de doma (desafío/tamaño) no se valida a
propósito: el bloque lo escribe el jugador y lo adjudica la mesa.

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

### Criatura acompañante — 4 clases

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

### Conversión puntos ↔ ranuras — 2 clases

Mago (Lanzamiento Flexible) y Sacerdote (Devoción) tienen la **misma tabla de
costes** (2/3/5/6/7 para 1.º-5.º). Los rasgos existen y anuncian, pero no mueven
las ranuras: hay que tocar `HarfordDnDMana`.

### Otros

| Bloqueo | Clase |
|---|---|
| Condición en los efectos `bonus` | Guerrero (4 estilos de combate aplican su bono sin condición) |
| *Riders* sobre otro rasgo | Cazador de Demonios (Embestida Vil, Moméntum Vengativo) |
| Sustituir el tipo de daño de un conjuro | Chamán (Furia Elemental) |

## Decisión de mesa pendiente

**El `casterType` del Brujo.** Está como lanzador completo. La tabla de clase del
manual da **magia de pacto** (2 ranuras a nivel 6, recarga en descanso corto),
pero `HarfordDnDMana` cita la regla variante de maná que sí lo clasifica como
completo. Dos fuentes para dos reglas distintas y **un solo campo que gobierna
ambas**. No se toca sin decidir cuál manda.

## Sin verificar

Los **iconos** de las maniobras del Guerrero (8) y de las Maldiciones del Brujo
siguen sin comprobar contra el cliente. Los del Guerrero los invente yo.
