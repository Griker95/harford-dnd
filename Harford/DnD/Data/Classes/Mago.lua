-- Mago: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "mago", name = "Mago", desc = "Estudioso de las artes arcanas que moldea fuego, escarcha y energía pura mediante conjuros aprendidos.", hitDie = 6, casterType = "full", startingGold = { dice = 4, sides = 4, multiplier = 1 },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Un baston", items = { "Bastón" } },
            { label = "Una daga", items = { "Daga" } },
        } },
        { label = "Foco",
            options = {
            { label = "Una bolsa de componentes", items = { "Bolsa de componentes" } },
            { label = "Un foco arcano", items = { "Foco arcano" } },
        } },
        { label = "Paquete",
            fixed = { "Libro de conjuros" },
            options = {
            { label = "Paquete de erudito", items = { "Paquete de erudito" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Arcano", "Historia", "Perspicacia", "Investigacion", "Medicina", "Religion" },
    saves = { "Inteligencia", "Sabiduria" },
    armorProfs = {},
    weaponProfs = { "sencillas" },
    subclasses = {
        { id = "arcano", name = "Arcano", desc = "Manipulacion de energía arcana pura y gran eficiencia mágica.", features = {
            { id = "mago_arc_truco", level = 2, name = "Truco adicional (prestidigitacion)", type = "informativo", description = "Aprendes prestidigitacion (u otro truco de mago); no cuenta en tu limite.", cantripSpellIds = { "prestidigitacion" }, effects = {} },
            { id = "mago_arc_cargas", level = 2, name = "Cargas arcanas", type = "accion", actionKind = "arcaneCharge", description = "Al lanzar un conjuro de 1er nivel o superior ganas una carga arcana (= nivel, max 5) que gastas para sumar bonus a ataque/daño o salvaciones.", effects = { { kind = "flag", flag = "arcaneCharges" } } },
            { id = "mago_arc_desplazamiento", level = 2, name = "Desplazamiento temporal", type = "informativo", description = "Tras tirar iniciativa, intercambias tu resultado con el de otra criatura visible. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            { id = "mago_arc_brillantez", level = 6, name = "Brillantez arcana", type = "pasivo", description = "Pericia en Conocimiento Arcano (competencia y bonus duplicado). Siempre bajo entender idiomas.", effects = {
                { kind = "skillExpertise", skill = "Arcano" },
            } },
        } },
        { id = "fuego", name = "Fuego", desc = "Conjuros incendiarios de alto daño y combustion.", features = {
            { id = "mago_fue_truco", level = 2, name = "Truco adicional (controlar llamas)", type = "informativo", description = "Aprendes controlar llamas (u otro truco de mago); no cuenta en tu limite.", cantripSpellIds = { "controlar_llamas" }, effects = {} },
            { id = "mago_fue_racha", level = 2, name = "Racha de calor", type = "informativo", description = "Al sacar el maximo en un dado de daño de conjuro, relanza ese dado y suma el resultado. 1 vez por turno.", effects = { { kind = "flag", flag = "heatStreak" } } },
            { id = "mago_fue_cauterizar", level = 6, name = "Cauterizar", cast = "reaccion", type = "informativo", description = "Reacción al caer a 0 PG: quedas a 1 PG y las criaturas a 10 pies reciben fuego = mitad de nivel + Mod. Inteligencia. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            { id = "mago_fue_prender", level = 10, name = "Prender", type = "informativo", description = "*Característica de Estudio del Fuego de 10.º nivel* Cuando infliges daño de fuego con un conjuro usando un espacio de conjuro de hasta 5.º nivel, puedes gastar hasta 3 puntos de hechicería para potenciarlo. Por cada punto de hechicería gastado, añade un dado extra al daño infligido por el conjuro. Por ejemplo, cuando lanzas *manos ardientes* y gastas 2 puntos, agregas 2d6 adicionales al daño del conjuro. Cuando lanzas un conjuro que hace múltiples tiradas de ataque, como *rayo abrasador*, debes gastar los puntos en cada ataque individualmente.", effects = {} },
            { id = "mago_fue_combustion", level = 14, name = "Combustión", type = "informativo", description = "*Característica de Estudio del Fuego de 14.º nivel* Puedes desatar las llamas que arden dentro de ti. Como acción, te envuelves en un torbellino de fuego. Por 1 minuto, obtienes los siguientes beneficios: - Irradias luz brillante en un radio de 9,1 metros y luz tenue en 9,1 metros adicionales. - Cualquier criatura recibe daño de fuego igual a la mitad de tu nivel de mago si te golpea con un ataque cuerpo a cuerpo. - Cualquier conjuro o efecto que crees ignora la resistencia al daño de fuego y trata la inmunidad al daño de fuego como resistencia al mismo. - Eres inmune al daño de fuego y tienes resistencia al daño por frío. - Tus ataques de conjuro obtienen un golpe crítico con una tirada de 19 o 20 en el d20. Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo, a menos que gastes 5 puntos de hechicería para usarla nuevamente.", effects = {} },
        } },
        { id = "escarcha", name = "Escarcha", desc = "Control, ralentizacion y daño de hielo.", features = {
            { id = "mago_esc_truco", level = 2, name = "Truco adicional (moldear agua)", type = "informativo", description = "Aprendes moldear agua (u otro truco de mago); no cuenta en tu limite.", cantripSpellIds = { "moldear_agua" }, effects = {} },
            { id = "mago_esc_dedos", level = 2, name = "Dedos de escarcha", type = "choice", companionId = "elemental_agua", description = "Elige Barrera de Hielo (escudo de PG temporal con conjuros de frío) o Elemental de Agua (compañero).", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "barrera", label = "Barrera de Hielo", desc = "Al lanzar un conjuro de nivel 1 o superior que inflija dano por frio, deformas parte de su magia para crear una barrera de hielo que dura hasta que termines un descanso largo. Tiene puntos de golpe iguales al DOBLE de tu nivel de mago mas tu Mod. Inteligencia y absorbe el dano en tu lugar. Cada vez que lances un conjuro de nivel 1 o superior que cause dano por frio, la barrera recupera puntos de golpe iguales al doble del nivel del conjuro. Al reducirse a 0, cada criatura a 3 metros ve reducida su velocidad en 3 metros hasta el inicio de tu proximo turno al estallar.", effects = {} },
                    { id = "elemental", label = "Elemental de Agua", icon = "spell_frost_summonwaterelemental_2", desc = "Aprendes a conjurar un elemental de agua. Es amistoso contigo y tus companeros y obedece tus ordenes. Comparte tu cuenta de iniciativa pero toma su turno inmediatamente despues del tuyo. Puede moverse y usar su reaccion por si solo, pero la unica accion que toma en su turno es la de Esquivar, a menos que uses tu accion adicional para ordenarle otra. Si le lanzas un conjuro de frio, es inmune y recupera puntos de golpe iguales al dano infligido.", effects = {} },
                },
            } },
            { id = "mago_esc_congelacion", level = 6, name = "Congelacion cerebral", type = "accion", resourceKey = "mage_point", resourceCost = 1, spendResourceOnAnnounce = true, description = "El daño por frío de tus conjuros reduce 10 pies la velocidad; puedes gastar un punto de hechicería para restringir (salvación de Fuerza).", effects = {} },
            { id = "mago_esc_manos_de_escarcha", level = 10, name = "Manos de Escarcha", type = "informativo", description = "*Característica de Estudio de la Escarcha de 10.º nivel* Obtienes una de las siguientes características, dependiendo de tu elección a nivel 2. ***Barrera de Hielo.*** Cuando una criatura que puedes ver dentro de 9,1 metros de ti recibe daño, puedes usar tu reacción para hacer que tu Barrera de Hielo se manifieste alrededor de ella y absorba el daño. Si este daño reduce la barrera a 0 puntos de golpe, la criatura barricada recibe cualquier daño restante. Además, ahora puedes gastar puntos de hechicería para causar el efecto de Congelación Cerebral. ***Elemental de Agua.*** Tu elemental de agua se convierte en un elemental de hielo y obtiene los siguientes beneficios adicionales: - Gana inmunidad al daño por frío. - Congelación Cerebral ahora se aplica al daño por frío causado por el elemental.", effects = {} },
            { id = "mago_esc_anillo_de_escarcha", level = 14, name = "Anillo de Escarcha", type = "informativo", description = "*Característica de Estudio de la Escarcha de 14.º nivel* Puedes usar tu acción para conjurar un anillo de runas mágicas que invoca el frío más profundo alrededor de un punto que elijas dentro de 18,3 metros. El anillo tiene un radio de 9,1 metros y llena un cilindro de 3 metros de altura con frío gélido. Las criaturas dentro del área deben tener éxito en una tirada de salvación de Fuerza contra la CD de salvación de tus conjuros o quedar paralizadas hasta 1 minuto o hasta que reciban daño. Si el cuerpo de una criatura está completamente dentro del área, la tirada de salvación se realiza con desventaja. En una tirada de salvación exitosa, la criatura no queda restringida. Además, las criaturas que pasan por el área por medios no mágicos tienen su velocidad de movimiento reducida a la mitad hasta el final de su próximo turno después de salir del área.", effects = {} },
        } },
    },
    features = {
        { id = "mago_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Libro de conjuros; preparas Mod. Inteligencia + nivel. CD = 8 + comp + Mod. Inteligencia; ataque = comp + Mod. Inteligencia. Foco arcano.", effects = {} },
        { id = "mago_sentido_magico", level = 1, name = "Sentido magico", type = "informativo", description = "Percibes magia residual reciente y lees escritura mágica oculta. Además puedes crear escritura mágica oculta en idiomas que conozcas.", effects = {} },
        { id = "mago_fuente_magia", level = 2, name = "Fuente de magia", type = "pasivo", description = "Puntos de hechicería (= nivel) para Lanzamiento Flexible (convertir puntos en espacios de conjuro y viceversa). Recargan en descanso largo.", effects = {
            { kind = "resourceMax", resource = "mage_point", perClassLevel = "mago", perLevel = 1 },
        } },
        { id = "mago_crear_espacio", level = 2, name = "Crear espacio de conjuro", cast = "accion_adicional", type = "accion", description = "Accion adicional: transformas puntos de hechiceria en un espacio de conjuro. Coste: 2 puntos para uno de 1.o, 3 para 2.o, 5 para 3.o, 6 para 4.o y 7 para 5.o. Los espacios creados desaparecen al terminar un descanso largo. No puedes crear espacios por encima del 5.o nivel.", actionKind = "slotConversion", slotConversion = { mode = "create", resource = "mage_point" }, effects = {} },
        { id = "mago_convertir_espacio", level = 2, name = "Convertir espacio en puntos", cast = "accion_adicional", type = "accion", description = "Accion adicional: gastas un espacio de conjuro y ganas puntos de hechiceria iguales al nivel del espacio.", actionKind = "slotConversion", slotConversion = { mode = "convert", resource = "mage_point" }, effects = {} },
        { id = "mago_estudio_magico", level = 2, name = "Estudio magico", type = "informativo", description = "Eliges tu estudio (Arcano, Fuego o Escarcha). Concede rasgos en niveles 2, 6, 10 y 14.", effects = {} },
        { id = "mago_metamagia", level = 3, name = "Metamagia", type = "choice", description = "Aprendes dos opciones de metamagia para alterar tus conjuros gastando puntos de hechicería (aprendes mas a niveles 10 y 17).", effects = {}, choice = {
            slots = 2,
            options = {
                { id = "cuidadoso", label = "Conjuro Cuidadoso", resourceKey = "mage_point", resourceCost = 1, desc = "Al lanzar un conjuro que obliga a otras criaturas a una salvacion, gastas 1 punto de hechiceria y eliges un numero de esas criaturas igual a tu Mod. Inteligencia (minimo una): tienen exito automaticamente en su salvacion.", effects = {} },
                { id = "distante", label = "Conjuro Distante", resourceKey = "mage_point", resourceCost = 1, desc = "Al lanzar un conjuro con un alcance de 1,5 metros o mas, gastas 1 punto para duplicar su alcance. Si el alcance es de toque, pasa a 9 metros.", effects = {} },
                { id = "potenciado", label = "Conjuro Potenciado", resourceKey = "mage_point", resourceCost = 1, desc = "Al tirar el dano de un conjuro, gastas 1 punto para repetir un numero de dados de dano igual a tu Mod. Inteligencia (minimo 1). Debes usar los nuevos resultados. Puedes usarlo aunque ya hayas usado otra metamagia en ese conjuro.", effects = {} },
                { id = "prolongado", label = "Conjuro Prolongado", resourceKey = "mage_point", resourceCost = 1, desc = "Al lanzar un conjuro con duracion de 1 minuto o mas, gastas 1 punto para duplicar su duracion, hasta un maximo de 24 horas.", effects = {} },
                { id = "intensificado", label = "Conjuro Intensificado", resourceKey = "mage_point", resourceCost = 3, desc = "Al lanzar un conjuro que obliga a una criatura a una salvacion para resistir sus efectos, gastas 3 puntos para dar a un objetivo desventaja en su PRIMERA salvacion contra el conjuro. En el manual aparece con el mismo nombre que Conjuro Potenciado.", effects = {} },
                { id = "rapido", label = "Conjuro Rapido", resourceKey = "mage_point", resourceCost = 2, desc = "Al lanzar un conjuro con tiempo de lanzamiento de 1 accion, gastas 2 puntos para cambiarlo a accion adicional en ese lanzamiento.", effects = {} },
                { id = "sutil", label = "Conjuro Sutil", resourceKey = "mage_point", resourceCost = 1, desc = "Al lanzar un conjuro, gastas 1 punto para lanzarlo sin componentes somaticos ni verbales.", effects = {} },
                { id = "gemelo", label = "Conjuro Gemelo (puntos = nivel del conjuro)", desc = "Al lanzar un conjuro de un solo objetivo y sin alcance personal, gastas puntos iguales al nivel del conjuro (1 si es un truco) para apuntar a una segunda criatura en el rango. El conjuro no debe ser capaz de apuntar a mas de una criatura a su nivel actual.", effects = {} },
            },
        } },
        { id = "mago_formulas_cantrips", level = 3, name = "Formulas de trucos", type = "informativo", description = "Aprendes a modificar tus trucos con formulas arcanas.", effects = {} },
        ASI("mago", 4),
    },
}
