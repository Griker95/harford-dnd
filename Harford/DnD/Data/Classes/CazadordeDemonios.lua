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
            { id = "dh_dev_competencia", level = 3, name = "Competencia adicional (acrobacias)", type = "pasivo", description = "Pericia en Acrobacias (competencia y bonus de competencia duplicado).", effects = {
                { kind = "skillExpertise", skill = "Acrobacias" },
                { kind = "flag", flag = "initiativeProfBonus" },
            } },
            { id = "dh_dev_embestida", level = 3, name = "Embestida vil", type = "informativo", description = "Cuando usas Momentum para Correr o Desengancharte, puedes moverte exactamente la mitad de tu velocidad en línea recta. Las criaturas que atraviesan tu recorrido reciben daño de fuego vil igual a tu dado de Caos.", effects = {} },
            { id = "dh_dev_momentum_vengativo", level = 6, name = "Momentum vengativo", type = "accion", resourceGain = { key = "fel_point", amount = 1 }, description = "Cuando las dos tiradas de ataque de Mordida de Demonio impactan, recuperas 1 punto de Vil. La comprobacion de ambas tiradas sigue siendo manual.", effects = {} },
        } },
        { id = "venganza", name = "Venganza", desc = "Defensa demoniaca que absorbe el castigo y lo devuelve.", features = {
            { id = "dh_ven_competencia", level = 3, name = "Competencia adicional (intimidacion)", type = "pasivo", description = "Pericia en Intimidación (competencia y bonus de competencia duplicado).", effects = {
                { kind = "skillExpertise", skill = "Intimidacion" },
            } },
            { id = "dh_ven_tormento", level = 3, name = "Tormento", cast = "accion", type = "maniobra", description = "Acción: una criatura a 30 pies con salvación de Sabiduría o desventaja en ataques contra otros que no seas tu durante 1 minuto.", effects = {
                { kind = "energyManeuver", resource = "fel_point", cost = 0, save = "Sabiduria", dcAbility = "Inteligencia", outcome = "desventaja en sus ataques" },
            } },
            { id = "dh_ven_puas", level = 6, name = "Puas demoniacas", type = "pasivo", description = "En metamorfosis: resistencia a contundente/perforante/cortante y ventaja en pruebas y salvaciones de Fuerza y Destreza.", effects = {
                { kind = "resist", damage = "contundente", requiresState = "metamorphosis" },
                { kind = "resist", damage = "perforante", requiresState = "metamorphosis" },
                { kind = "resist", damage = "cortante", requiresState = "metamorphosis" },
            } },
            { id = "dh_ven_aura_de_inmolacion", level = 10, name = "Aura de Inmolación", type = "informativo", description = "Al alcanzar el nivel 10, puedes gastar 2 puntos de vil como acción adicional para envolver tu cuerpo en llamas viles. Cuando activas esta aura y al comienzo de cada uno de tus turnos mientras dura, recibes 1d6 puntos de daño por fuego. La aura de inmolación dura 1 minuto, hasta que la termines como acción adicional, o hasta que quedes inconsciente. Siempre que una criatura te golpee con un ataque cuerpo a cuerpo mientras la aura de inmolación está activa, infliges a esa criatura un daño por fuego igual a 1d6 + la mitad de tu nivel de cazador de demonios.", effects = {} },
            { id = "dh_ven_ultimo_recurso", level = 17, name = "Último Recurso", type = "informativo", description = "A nivel 17, puedes extraer vida de tu marca demoníaca para escapar de la muerte. Cuando te reduzcan a 0 puntos de golpe, puedes gastar 1 punto de vil (no se requiere ninguna acción) para quedarte con 1 punto de golpe en su lugar y entrar en tu metamorfosis hasta el final de tu próximo turno.", effects = {} },
        } },
        { id = "ira", name = "Ira", desc = "Furia desatada que crece con el frenesi del combate.", features = {
            { id = "dh_ira_competencia", level = 3, name = "Competencia adicional (arcano)", type = "pasivo", description = "Pericia en Conocimiento Arcano (competencia y bonus de competencia duplicado).", effects = {
                { kind = "skillExpertise", skill = "Arcano" },
            } },
            { id = "dh_ira_llamas", level = 3, name = "Llamas del caos", cast = "accion", type = "maniobra", description = "Accion de Ataque: manifiestas llamas viles como un ataque a distancia de 9 metros. Tienes competencia y sumas tu Mod. Destreza al ataque y al dano. Al impactar inflige 1d6 de dano por fuego (1d10 a nivel 11). Con Ataque Adicional puedes usarlo en cualquiera de tus ataques.", effects = {
                { kind = "energyManeuver", resource = "fel_point", cost = 0, attack = true, spendOnHit = true, damageDie = 6, damageType = "fuego" },
            } },
            { id = "dh_ira_marca_ignea", level = 6, name = "Marca ignea", type = "accion", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Constitucion", success = "none", conditionId = "marca_ignea", conditionDuration = "manual", note = "Solo en metamorfosis y al impactar con Llamas del caos de tu Mordida de Demonio." }, description = "En metamorfosis, las Llamas del Caos de tu Mordida de Demonio imponen salvación de Constitución (desventaja en ataques) e ignoran resistencia al fuego.", effects = {} },
        } },
    },
    features = {
        { id = "dh_defensa_sin_armadura", level = 1, name = "Guardas demoniacas", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Inteligencia.", effects = {
            { kind = "unarmoredDefenseAbility", ability = "Inteligencia" },
        } },
        { id = "dh_iniciacion_illidari", level = 1, name = "Iniciacion Illidari", type = "pasivo", description = "Tus armas cuerpo a cuerpo que no sean Pesadas ni de Dos manos se consideran Ligeras y Sutiles: usas el mejor modificador entre Fuerza y Destreza. También tienes ventaja en el primer turno contra criaturas que no han actuado, al rastrear con Supervivencia y contra demonios; hablas Eredun.", effects = {
            { kind = "weaponFinesse", meleeOnly = true, excludeHeavy = true, excludeTwoHanded = true },
        } },
        { id = "dh_vision_espectral", level = 1, name = "Vision espectral", type = "pasivo", description = "Visión en oscuridad normal y mágica a 60 pies (con color); eres inmune a cegado. A nivel 4 puedes usar tu accion para obtener los beneficios de detectar magia durante 10 minutos, dos veces entre descansos.", effects = {
            { kind = "conditionImmunity", condition = "blinded" },
        } },
        { id = "dh_vil", level = 2, name = "Vil", type = "pasivo", description = "Puntos de Vil para alimentar rasgos demoníacos. El maximo es igual a tu nivel de Cazador de Demonios. Recargan en descanso corto o largo.", effects = {
            { kind = "resourceMax", resource = "fel_point", perClassLevel = "cazador_demonios", perLevel = 1 },
        } },
        { id = "dh_mordida_demonio", level = 2, name = "Mordida de Demonio", type = "accion", description = "Después de realizar la acción de Atacar con un arma, puedes gastar 1 punto de Vil para realizar dos ataques con arma como acción adicional. No agregas tu modificador de característica al daño de esos ataques.", actionKind = "demonBite", effects = {} },
        { id = "dh_potenciar_protecciones", level = 2, name = "Potenciar protecciones", type = "informativo", cast = "reaccion", resourceKey = "fel_point", resourceCost = 2, spendResourceOnAnnounce = true, description = "Reaccion: cuando haces una tirada de salvacion de Inteligencia, Sabiduria o Carisma, gastas 2 puntos de Vil para obtener ventaja en esa salvacion.", effects = {} },
        { id = "dh_momentum", level = 2, name = "Momentum", cast = "accion_adicional", type = "accion", grantsAsBonus = { "correr", "desengancharse" }, resourceKey = "fel_point", resourceCost = 1, description = "Como acción adicional, gastas 1 punto de Vil para Correr o Desengancharte. Tu distancia de salto se duplica durante ese turno; el movimiento se resuelve en juego.", effects = {} },
        { id = "dh_metamorfosis", level = 2, name = "Metamorfosis", cast = "accion_adicional", type = "accion", uses = { max = 1, recharge = "long" }, description = "Acción adicional: gastas un uso para transformarte durante 1 minuto. Ganas PG temporales iguales a tu nivel de Cazador de Demonios + Mod. Inteligencia; el estado activa sus efectos de combate.", actionKind = "metamorphosis", effects = {
            { kind = "toggleState", state = "metamorphosis", label = "Metamorfosis", description = "Activa rasgos que solo funcionan mientras estas en metamorfosis." },
            { kind = "weaponExtraDamage", id = "dh_metamorphosis_fire", label = "Metamorfosis", count = 1, perClassLevel = "cazador_demonios", values = { 0, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4 }, damageType = "fuego", requiresState = "metamorphosis" },
            { kind = "bonus", target = "speed", value = 3, requiresState = "metamorphosis" },
        } },
        { id = "dh_marca_demoniaca", level = 3, name = "Marca demoniaca", type = "informativo", description = "Eliges tu marca (Devastacion, Venganza o Ira). Concede rasgos en niveles 3, 6, 10 y 17.", effects = {} },
        ASI("dh", 4),
        { id = "dh_ataque_adicional", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "dh_hambre_instintiva", level = 5, name = "Hambre instintiva", type = "informativo", cast = "reaccion", description = "Reacción al terminar una criatura su turno a 15 pies: te mueves media velocidad hacia ella sin provocar ataques de oportunidad y obtienes ventaja en tu primer ataque contra ella.", effects = {} },
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
