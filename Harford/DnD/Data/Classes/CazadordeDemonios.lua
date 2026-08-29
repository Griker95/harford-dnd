-- Cazador de Demonios: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "cazador_demonios", name = "Cazador de Demonios", desc = "Illidari que sacrifico su humanidad absorbiendo esencia demoniaca; agil cazador de gran movilidad y metamorfosis demoniaca.", hitDie = 8, startingGold = { dice = 2, sides = 4, multiplier = 1 },
    -- Idioma que concede la clase (rasgo de nivel 1 del manual).
    languages = { "Eredun" },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Dos gujas de guerra", items = { "Guja de guerra", "Guja de guerra" } },
            { label = "Dos armas marciales", items = { { pick = "Marcial" }, { pick = "Marcial" } } },
        } },
        { label = "Arma secundaria",
            options = {
            { label = "Dos dagas", items = { "Daga", "Daga" } },
            { label = "10 dardos", items = { "10 dardos" } },
        } },
        { label = "Paquete",
            fixed = { "Cuero", "Amuleto de tu vida pasada" },
            options = {
            { label = "Paquete de aventurero de mazmorras", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Acrobacias", "Arcano", "Perspicacia", "Intimidacion", "Investigacion",
        "Percepcion", "Sigilo", "Supervivencia" },
    saves = { "Destreza", "Carisma" },
    armorProfs = { "ligera" },
    weaponProfs = { "sencillas", "marciales", "Guja de guerra" },
    subclasses = {
        { id = "devastacion", name = "Devastacion", desc = "Agresion implacable de gran movilidad y daño demoniaco.", features = {
            { id = "dh_dev_competencia", level = 3, name = "Competencia adicional (acrobacias)", type = "pasivo", description = "Al elegir esta marca en el nivel 3, obtienes competencia en la habilidad de Acrobacias si no la tienes. Bonus Competencia se duplica en cualquier prueba de habilidad que uses con esta competencia.", effects = {
                { kind = "skillExpertise", skill = "Acrobacias" },
                { kind = "flag", flag = "initiativeProfBonus" },
            } },
            { id = "dh_dev_embestida", level = 3, name = "Embestida vil", type = "pasivo", description = "A nivel 3, obtienes la capacidad de moverte a través del campo de batalla con tu momento. Siempre que gastes un punto de vil en la característica Momentum, obtienes los beneficios de una acción de Esquivar y Destrabarse hasta el final de tu turno.", effects = { { kind = "flag", flag = "felRush" } } },
            { id = "dh_dev_momentum_vengativo", level = 6, name = "Momentum vengativo", type = "pasivo", description = "A partir del nivel 6, siempre que uses la característica Momentum de vil, obtienes ventaja en el siguiente ataque con arma que realices antes del final de tu próximo turno.", effects = { { kind = "flag", flag = "vengefulMomentum" } } },
        } },
        { id = "venganza", name = "Venganza", desc = "Defensa demoniaca que absorbe el castigo y lo devuelve.", features = {
            { id = "dh_ven_competencia", level = 3, name = "Competencia adicional (intimidacion)", type = "pasivo", description = "Al elegir esta marca en el nivel 3, obtienes competencia en la habilidad de Intimidación si no la tienes. Bonus Competencia se duplica para cualquier prueba de habilidad que realices con esta competencia.", effects = {
                { kind = "skillExpertise", skill = "Intimidacion" },
            } },
            { id = "dh_ven_tormento", level = 3, name = "Tormento", cast = "accion", type = "maniobra", description = "A nivel 3, obtienes la habilidad de atormentar a una criatura. Puedes usar tu acción para elegir una criatura que puedas ver dentro de 9 metros de ti. El objetivo debe tener éxito en una tirada de salvación de Sabiduría contra tu CD de salvación de vil o tener desventaja en las tiradas de ataque contra criaturas que no seas tú durante 1 minuto. Al final de cada uno de sus turnos, el objetivo puede realizar otra tirada de salvación, terminando el efecto en un éxito.\n\nEl tormento termina antes en el objetivo si usas esta habilidad en una criatura diferente.", effects = {
                { kind = "energyManeuver", resource = "fel_point", cost = 0, save = "Sabiduria", dcAbility = "Inteligencia", outcome = "desventaja en sus ataques" },
            } },
            { id = "dh_ven_puas", level = 6, name = "Puas demoniacas", type = "pasivo", description = "A partir del nivel 6, tu forma demoníaca se ve potenciada por tu marca demoníaca, otorgándote resistencia al daño contundente, perforante y cortante mientras estás en metamorfosis. Además, mientras estés en metamorfosis, tienes ventaja en las pruebas y tiradas de salvación de Fuerza y Destreza.", effects = {
                { kind = "resist", damage = "contundente", requiresState = "metamorphosis" },
                { kind = "resist", damage = "perforante", requiresState = "metamorphosis" },
                { kind = "resist", damage = "cortante", requiresState = "metamorphosis" },
            } },
            { id = "dh_ven_aura_de_inmolacion", level = 10, name = "Aura de Inmolación", type = "informativo", description = "Al alcanzar el nivel 10, puedes gastar 2 puntos de vil como acción adicional para envolver tu cuerpo en llamas viles. Cuando activas esta aura y al comienzo de cada uno de tus turnos mientras dura, recibes 1d6 puntos de daño por fuego. La aura de inmolación dura 1 minuto, hasta que la termines como acción adicional, o hasta que quedes inconsciente. Siempre que una criatura te golpee con un ataque cuerpo a cuerpo mientras la aura de inmolación está activa, infliges a esa criatura un daño por fuego igual a 1d6 + la mitad de tu nivel de cazador de demonios.", effects = {} },
            { id = "dh_ven_ultimo_recurso", level = 17, name = "Último Recurso", type = "informativo", description = "A nivel 17, puedes extraer vida de tu marca demoníaca para escapar de la muerte. Cuando te reduzcan a 0 puntos de golpe, puedes gastar 1 punto de vil (no se requiere ninguna acción) para quedarte con 1 punto de golpe en su lugar y entrar en tu metamorfosis hasta el final de tu próximo turno.", effects = {} },
        } },
        { id = "ira", name = "Ira", desc = "Furia desatada que crece con el frenesi del combate.", features = {
            { id = "dh_ira_competencia", level = 3, name = "Competencia adicional (arcano)", type = "pasivo", description = "Al elegir esta marca en el nivel 3, obtienes competencia en la habilidad de Conocimiento Arcano si no la tienes. Bonus Competencia se duplica para cualquier prueba de habilidad que uses con esta competencia.", effects = {
                { kind = "skillExpertise", skill = "Arcano" },
            } },
            { id = "dh_ira_llamas", level = 3, name = "Llamas del caos", cast = "accion", type = "maniobra", description = "A nivel 3, aprendes a manifestar llamas viles puras. Obtienes una nueva opción de ataque que puedes usar con la acción de Ataque. Este ataque especial es un ataque a distancia con un arma con un alcance de 9 metros. Tienes competencia con él y añades Mod. Destreza a sus tiradas de ataque y daño. En un golpe exitoso, este ataque especial inflige 1d6 de daño por fuego.\n\nCuando obtienes la característica de Ataque Adicional, este ataque especial puede usarse para cualquiera de los ataques que realices como parte de la acción de Ataque.\n\nA nivel 11, el daño de tus Llamas del Caos aumenta a 1d10 de daño por fuego.", effects = {
                { kind = "energyManeuver", resource = "fel_point", cost = 0, attack = true, spendOnHit = true, damageDie = 6, damageType = "fuego" },
            } },
            { id = "dh_ira_marca_ignea", level = 6, name = "Marca ignea", cast = "ninguna", type = "accion", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Constitucion", success = "none", conditionId = "marca_ignea", conditionDuration = "manual", note = "Solo en metamorfosis y al impactar con Llamas del caos de tu Mordida de Demonio." }, description = "En metamorfosis, las Llamas del Caos de tu Mordida de Demonio imponen salvación de Constitución (desventaja en ataques) e ignoran resistencia al fuego.", effects = {} },
        } },
    },
    features = {
        { id = "dh_defensa_sin_armadura", level = 1, name = "Guardas demoniacas", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Inteligencia.", effects = {
            { kind = "unarmoredDefenseAbility", ability = "Inteligencia" },
        } },
        { id = "dh_iniciacion_illidari", level = 1, name = "Iniciacion Illidari", type = "pasivo", description = "Eres un iniciado Illidari, habiendo sobrevivido a las pruebas despiadadas de los Illidari y recibido un entrenamiento inaudito en otros lugares. Esto te otorga los siguientes beneficios:\n\n• En tu primer turno del combate, tienes ventaja en las tiradas de ataque contra criaturas que aún no hayan actuado. • Puedes tratar las armas cuerpo a cuerpo que no tengan la propiedad de pesada o de dos manos como si tuvieran las propiedades de ligereza y precisión, además de sus otras propiedades. • Cuando haces una prueba de Sabiduría (Supervivencia) relacionada con rastrear una criatura, se considera que tienes competencia en la habilidad de Supervivencia.\n\nAdemás, tienes un odio profundo hacia los seres demoníacos y has sido entrenado para derrotarlos. Esto te otorga los siguientes beneficios adicionales:\n\n• Tienes ventaja en las pruebas de Sabiduría (Supervivencia) para rastrear a los demonios, así como en las pruebas de Inteligencia para recordar información sobre ellos. • Puedes hablar, leer y escribir Eredun.", effects = {
            { kind = "weaponFinesse", meleeOnly = true, excludeHeavy = true, excludeTwoHanded = true },
        } },
        { id = "dh_vision_espectral", level = 1, name = "Vision espectral", type = "pasivo", description = "Te has cegado ritualmente, y tus cuencas oculares están imbuidas de magia, otorgándote una nueva forma de visión. Puedes ver normalmente en oscuridad, tanto normal como mágica, hasta 18 metros de distancia, y puedes discernir colores en la oscuridad. Además, eres inmune a cegado.\n\nA nivel 7, puedes afinar tu visión espectral al flujo de la magia a tu alrededor. Puedes usar tu acción para obtener los beneficios del conjuro *detectar magia* durante 10 minutos. Puedes usar esta característica dos veces. Recuperas todos los usos gastados cuando terminas un descanso corto o largo.", effects = {
            { kind = "conditionImmunity", condition = "blinded" },
        } },
        { id = "dh_vil", level = 2, name = "Vil", type = "pasivo", description = "A partir del nivel 2, puedes extraer energía vil caótica que duerme en tu interior. Tu acceso a esta fuerza caótica está representado por una cantidad de puntos de vil. Tu nivel de cazador de demonios determina la cantidad de puntos que tienes, como se muestra en la columna de Puntos de Vil de la tabla del Cazador de Demonios.\n\nPuedes gastar estos puntos para alimentar varias características. Comienzas sabiendo tres de estas características: Mordida de Demonio, Potenciar Protecciones y Momentum. Aprenderás más características de vil a medida que subas de nivel en esta clase.\n\nCuando gastas un punto de vil, no estará disponible hasta que termines un descanso corto o largo, al final del cual recuperarás toda tu energía vil gastada.\n\nAlgunas características de vil requieren que tu objetivo haga una tirada de salvación para resistir los efectos. La CD de salvación se calcula de la siguiente manera:\n\n**CD de salvación de Vil** = 8 + Bonus Competencia + Mod. Inteligencia", effects = {
            { kind = "resourceMax", resource = "fel_point", perClassLevel = "cazador_demonios", perLevel = 1 },
        } },
        { id = "dh_mordida_demonio", level = 2, name = "Mordida de Demonio", cast = "accion_adicional", type = "accion", description = "Después de realizar la acción de Atacar con un arma, puedes gastar 1 punto de Vil para realizar dos ataques con arma como acción adicional. No agregas tu modificador de característica al daño de esos ataques.", actionKind = "demonBite", effects = {} },
        { id = "dh_potenciar_protecciones", level = 2, name = "Potenciar protecciones", type = "informativo", cast = "reaccion", resourceKey = "fel_point", resourceCost = 2, spendResourceOnAnnounce = true, description = "Cuando haces una tirada de salvación de Inteligencia, Sabiduría o Carisma, puedes gastar 2 puntos de vil como reacción para obtener ventaja en la tirada de salvación.", effects = {} },
        { id = "dh_momentum", level = 2, name = "Momentum", cast = "accion_adicional", type = "accion", grantsAsBonus = { "correr", "desengancharse" }, resourceKey = "fel_point", resourceCost = 1, description = "Como acción adicional, gastas 1 punto de Vil para Correr o Desengancharte. Tu distancia de salto se duplica durante ese turno; el movimiento se resuelve en juego.", effects = {} },
        { id = "dh_metamorfosis", level = 2, name = "Metamorfosis", cast = "accion_adicional", type = "accion", uses = { max = 1, recharge = "long" }, description = "Acción adicional: gastas un uso para transformarte durante 1 minuto. Ganas PG temporales iguales a tu nivel de Cazador de Demonios + Mod. Inteligencia; el estado activa sus efectos de combate.", actionKind = "metamorphosis", effects = {
            { kind = "toggleState", state = "metamorphosis", label = "Metamorfosis", description = "Activa rasgos que solo funcionan mientras estas en metamorfosis." },
            { kind = "weaponExtraDamage", id = "dh_metamorphosis_fire", label = "Metamorfosis", count = 1, perClassLevel = "cazador_demonios", values = { 0, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4 }, damageType = "fuego", requiresState = "metamorphosis" },
            { kind = "bonus", target = "speed", value = 3, requiresState = "metamorphosis" },
        } },
        { id = "dh_marca_demoniaca", subclassMarker = true, level = 3, name = "Marca demoniaca", type = "informativo", description = "A nivel 3, eliges una marca que moldea la naturaleza de tu cuerpo infundido demoníacamente. Elige la Marca de Devastación, la Marca de Venganza o la Marca de Ira, todas detalladas al final de la descripción de la clase.\n\nTu elección te otorga rasgos en el nivel 3 y nuevamente en los niveles 6, 10 y 17.", effects = {} },
        ASI("dh", 4),
        { id = "dh_ataque_adicional", level = 5, name = "Ataque adicional", type = "pasivo", description = "A partir del nivel 5, puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "dh_hambre_instintiva", level = 5, name = "Hambre instintiva", type = "informativo", cast = "reaccion", description = "A partir del nivel 5, cuando una criatura termina su turno a 4,5 metros de ti, puedes usar tu reacción para moverte hasta la mitad de tu velocidad hacia un espacio más cercano a la criatura. Moverte de esta manera no provoca ataques de oportunidad.\n\nAdemás, tienes ventaja en el primer ataque que realices contra la criatura antes del final de tu próximo turno.", effects = {} },
        { id = "dh_evasion", level = 7, name = "Evasión", type = "informativo", description = "A nivel 7, tus agudos reflejos te permiten esquivar ciertos efectos de área, como el aliento ardiente de un dragón rojo o el conjuro de *tormenta de hielo*. Cuando estés sujeto a un efecto que te permita hacer una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y solo recibes la mitad del daño si fallas.", effects = {} },
        { id = "dh_un_cazador_por_encima_de_todo", level = 9, name = "Un Cazador por Encima de Todo", type = "informativo", description = "Al alcanzar el nivel 9, has perfeccionado tus instintos para cazar presas. Si pasas al menos 1 minuto observando a una criatura, obtienes ventaja en las pruebas de Sabiduría (Supervivencia) realizadas para rastrear a esa criatura hasta que la hayas matado, elijas una nueva presa o transcurran un número de días igual a tu nivel de cazador de demonios. Si pierdes el rastro de tu presa, puedes pasar 1 hora para percibir su dirección general en relación contigo, siempre y cuando ambos estén en el mismo plano de existencia. Además, en tu primer turno durante el combate, tienes ventaja en las tiradas de ataque realizadas contra la criatura.", effects = {} },
        { id = "dh_alas_demoniacas", level = 11, name = "Alas Demoníacas", type = "informativo", description = "A partir del nivel 11, puedes usar tu reacción cuando caigas para manifestar alas demoníacas, reduciendo cualquier daño por caída que recibas en una cantidad igual a cinco veces tu nivel de cazador de demonios. Además, durante la duración de tu Metamorfosis, obtienes una velocidad de vuelo igual a tu velocidad de movimiento.", effects = {} },
        { id = "dh_destreza_illidari", level = 11, name = "Destreza Illidari", type = "informativo", description = "A partir del nivel 11, cuando empuñas un arma cuerpo a cuerpo con la propiedad versátil, puedes usar el valor de daño aumentado incluso cuando la empuñas con una mano. Si decides empuñar el arma con dos manos, no recibes ningún beneficio adicional.", effects = {} },
        { id = "dh_purificado_por_las_llamas", level = 13, name = "Purificado por las Llamas", type = "informativo", description = "En el nivel 13, puedes usar tu acción y gastar 2 puntos de vil para envolver tu cuerpo en llamas de dolor y finalizar un efecto en ti que te cause estar encantado, asustado o envenenado. Cada criatura en un radio de 1,5 metros de ti cuando uses esta característica debe realizar una tirada de salvación de Destreza, recibiendo 1d10 + la mitad de tu nivel de cazador de demonios en daño por fuego si falla, o la mitad del daño si tiene éxito.", effects = {} },
        { id = "dh_mirada_reveladora", level = 14, name = "Mirada Reveladora", type = "informativo", description = "A partir del nivel 14, puedes concentrar el vil en tus ojos quemados para revelar la verdad del mundo que te rodea. Como acción, puedes gastar 3 puntos de vil para obtener los beneficios del conjuro *visión verdadera* durante 1 minuto.", effects = {} },
        { id = "dh_resiliencia_abisal", level = 15, name = "Resiliencia Abisal", type = "informativo", description = "En el nivel 15, has adquirido una fortaleza superior. Ganas competencia en tiradas de salvación de Constitución.", effects = {} },
        { id = "dh_cuerpo_atemporal", level = 18, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del nivel 18, el vil primordial que fluye por tu cuerpo te ha concedido una longevidad inimaginable. Por cada 10 años que pasen, tu cuerpo envejece solo 1 año y no puedes ser envejecido mágicamente.", effects = {} },
        { id = "dh_preparado", level = 20, name = "Preparado", type = "informativo", description = "A nivel 20, tus sentidos sobrenaturales te permiten actuar al instante. Puedes tomar dos turnos durante la primera ronda de cualquier combate. Tomas tu primer turno en el conteo de iniciativa 30 y tu segundo turno en tu tirada de iniciativa. Además, cuando tires iniciativa y no tengas puntos de vil restantes, recuperas 2 puntos de vil.", effects = {} },
    },
}
