-- Chaman: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects
local ManeuverEffects = API.ManeuverEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "chaman", name = "Chaman", desc = "Mediador de los elementos y los espíritus ancestrales; desata furia elemental, potencia armas o restaura con totems.", hitDie = 8, casterType = "full", startingGold = { dice = 5, sides = 4, multiplier = 1 },
    -- Idioma que concede la clase (rasgo de nivel 1 del manual).
    languages = { "Kalimag" },
    -- Herramientas de clase segun el manual.
    toolProfs = { "Kit de herborista" },
    startingEquipment = {
        { label = "Armadura",
            options = {
            { label = "Armadura de pieles", items = { "Pieles" } },
            { label = "Armadura de cuero", items = { "Cuero" } },
        } },
        { label = "Arma principal",
            options = {
            { label = "Una maza y un escudo", items = { "Maza", "Escudo" } },
            { label = "Dos armas simples", items = { { pick = "Simple" }, { pick = "Simple" } } },
        } },
        { label = "Paquete",
            fixed = { "Foco druidico" },
            options = {
            { label = "Paquete de aventurero", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Animales", "Arcano", "Historia", "Perspicacia", "Medicina", "Naturaleza",
        "Percepcion", "Supervivencia" },
    saves = { "Fuerza", "Sabiduria" },
    armorProfs = { "ligera", "media", "escudo" },
    weaponProfs = { "sencillas" },
    subclasses = {
        { id = "elemental", name = "Elemental", desc = "Desata rayos, fuego y tierra contra el enemigo a distancia.", features = {
            { id = "cha_ele_poder", level = 3, name = "Poder totemico: Mente tranquila", type = "informativo", cast = "reaccion", description = "Tu tótem da ventaja en salvaciones de Constitución para concentración a criaturas a 15 pies.", effects = {} },
            { id = "cha_ele_furia", level = 3, name = "Furia elemental", type = "informativo", description = "Al lanzar un conjuro de daño elemental (acido/frío/fuego/rayo/trueno) puedes cambiar su tipo por otro de la lista.", effects = {} },
            { id = "cha_ele_vinculo_aire_3", level = 3, name = "Conjuros de vinculo (Aire)", type = "informativo", description = "Por tu Afinidad Elemental de Aire aprendes Diablo de polvo y Viento guardian. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "aire", grantedSpells = { "diablo_de_polvo", "viento_guardian" }, effects = {} },
            { id = "cha_ele_vinculo_aire_5", level = 5, name = "Conjuros de vinculo (Aire)", type = "informativo", description = "Por tu Afinidad Elemental de Aire aprendes Llamar al relampago y Muro de viento. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "aire", grantedSpells = { "llamar_al_relampago", "muro_de_viento" }, effects = {} },
            { id = "cha_ele_vinculo_tierra_3", level = 3, name = "Conjuros de vinculo (Tierra)", type = "informativo", description = "Por tu Afinidad Elemental de Tierra aprendes Puno terrestre de Maximiliano y Hacer anicos. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "tierra", grantedSpells = { "puno_terrestre_de_maximiliano", "hacer_anicos" }, effects = {} },
            { id = "cha_ele_vinculo_tierra_5", level = 5, name = "Conjuros de vinculo (Tierra)", type = "informativo", description = "Por tu Afinidad Elemental de Tierra aprendes Pua terrestre y Tierra en erupcion. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "tierra", grantedSpells = { "pua_terrestre", "tierra_en_erupcion" }, effects = {} },
            { id = "cha_ele_vinculo_fuego_3", level = 3, name = "Conjuros de vinculo (Fuego)", type = "informativo", description = "Por tu Afinidad Elemental de Fuego aprendes Calentar metal y Rafaga de lava. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "fuego", grantedSpells = { "calentar_metal", "erupcion_de_lava" }, effects = {} },
            { id = "cha_ele_vinculo_fuego_5", level = 5, name = "Conjuros de vinculo (Fuego)", type = "informativo", description = "Por tu Afinidad Elemental de Fuego aprendes Luz del dia y Meteoros menores de Melf. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "fuego", grantedSpells = { "luz_del_dia", "meteoros_menores_de_melf" }, effects = {} },
            { id = "cha_ele_vinculo_agua_3", level = 3, name = "Conjuros de vinculo (Agua)", type = "informativo", description = "Por tu Afinidad Elemental de Agua aprendes Auxilio y Restablecimiento menor. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "agua", grantedSpells = { "auxilio", "restablecimiento_menor" }, effects = {} },
            { id = "cha_ele_vinculo_agua_5", level = 5, name = "Conjuros de vinculo (Agua)", type = "informativo", description = "Por tu Afinidad Elemental de Agua aprendes Cadena de curacion y Muro de agua. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "agua", grantedSpells = { "cadena_de_curacion", "muro_de_agua" }, effects = {} },
            { id = "cha_ele_eco", level = 6, name = "Eco de los elementos", type = "informativo", description = "Al lanzar un conjuro de daño, repite hasta Mod. Sabiduría dados y usa el resultado que quieras. Usos = Mod. Sabiduría por descanso largo.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
        } },
        { id = "mejora", name = "Mejora", desc = "Imbuye sus armas con los elementos para el cuerpo a cuerpo.", casterType = "half", features = {
            { id = "cha_mej_poder", level = 3, name = "Poder totemico: Furia del viento", type = "informativo", cast = "reaccion", description = "Tu tótem permite repetir un ataque cuerpo a cuerpo fallado a una criatura a 15 pies.", effects = {} },
            { id = "cha_mej_competencia", level = 3, name = "Competencia adicional (armas marciales)", type = "pasivo", description = "Competencia con armas marciales; puedes usar un arma simple o marcial como foco de conjuro.", effects = WeaponProfEffects("marciales") },
            { id = "cha_mej_llamado_marcial", level = 3, name = "Llamado marcial", type = "informativo", description = "Desde el nivel 3 usas la tabla de Lanzamiento de Conjuros de Mejora en vez de la del Chaman: 2 trucos, y 5 conjuros conocidos (6 al nivel 6). Cuentas como MEDIO lanzador, tambien al multiclasear: 3 ranuras de 1.º a niveles 3-4, y 4 de 1.º mas 2 de 2.º a los niveles 5-6.", effects = {} },
            { id = "cha_mej_torbellino", level = 3, name = "Torbellino", type = "pasivo", description = "Puntos de torbellino (mitad de tu nivel, redondeado hacia arriba) para ataques con armas elementales (Golpe de Roca, Látigo Elemental, etc.). Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "maelstrom", perClassLevel = "chaman", values = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
            } },
            { id = "cha_mej_ataques_3", level = 3, name = "Ataques con armas conocidos", type = "choice", description = "Conoces dos ataques con armas a tu eleccion; aprendes mas a los niveles 7, 11 y 15. La CD de sus salvaciones es la de tus conjuros.", effects = {}, choice = {
            slots = 2,
            options = {
                { id = "golpe_roca", label = "Golpe de Roca", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para obligarla a una salvacion de Fuerza. Si falla, es empujada 4,6 metros directamente lejos de ti.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Fuerza", outcome = "empujado 4,6 metros" } },
                { id = "mordida_roca", label = "Mordida de Roca", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para intentar un golpe que derriba. Salvacion de Fuerza o cae derribado.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Fuerza", outcome = "Derribado", onFailAura = 267937, conditionId = "prone" } },
                { id = "golpe_tormenta", label = "Golpe de Tormenta", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para descargar un rayo. Salvacion de Constitucion o no podra tomar reacciones hasta el inicio de tu proximo turno.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Constitucion", outcome = "sin reacciones" } },
                { id = "marca_hielo", label = "Marca de Hielo", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para intentar una marca helada. Salvacion de Constitucion o tendra desventaja en ataques hasta el final de su proximo turno.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Constitucion", outcome = "desventaja en ataques", onFailAura = 287295, conditionId = "chilled" } },
                { id = "latigo_elemental", label = "Latigo Elemental", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para azotar a otra criatura a 4,6 metros de ella. Salvacion de Destreza o recibe 1d10 del tipo de dano de tu Afinidad Elemental.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Destreza", outcome = "azotado por los elementos", damageDie = 10 } },
                { id = "golpe_torbellino", label = "Golpe de Torbellino", resourceKey = "maelstrom", resourceCost = 1, desc = "Al realizar la accion de ataque, gastas 1 punto de torbellino para que todos tus ataques con arma cuenten como magicos hasta el final de tu turno. Combinable con otro ataque con armas.", maneuver = { cost = 1, attack = true, spendOnHit = true } },
                { id = "golpe_impactante", label = "Golpe Impactante", resourceKey = "maelstrom", resourceCost = 3, requiresLevel = 7, desc = "Cuando golpeas con un ataque con arma, gastas 3 puntos de torbellino para intentar un golpe impactante. Salvacion de Constitucion o queda incapacitada hasta el inicio de tu proximo turno.", maneuver = { cost = 3, attack = true, spendOnHit = true, save = "Constitucion", outcome = "Incapacitado", conditionId = "incapacitated" } },
            } } },
            { id = "cha_mej_golpe_elemental", level = 3, name = "Golpe elemental", type = "maniobra", description = "Al realizar la accion de ataque, gastas 1 punto de torbellino para envolver tus ataques en tu Afinidad Elemental hasta el final del turno: cada ataque inflige 1d4 adicional de ese tipo.", effects = {
            { kind = "conditionalWeaponDamage", id = "shaman_elemental_strike", label = "Golpe elemental", count = 1, die = 4, resourceCost = "maelstrom", costPerLevel = 1, minLevel = 1, maxLevel = 1 },
            } },
            { id = "cha_mej_ataque_adicional", level = 6, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
        } },
        { id = "restauracion", name = "Restauracion", desc = "Sanacion y apoyo mediante totems y aguas curativas.", features = {
            { id = "cha_res_poder", level = 3, name = "Poder totemico: Marea viva", type = "informativo", cast = "reaccion", description = "Cuando una criatura a 15 pies del tótem cura, el tótem cura a otra criatura a 15 pies (= Mod. Sabiduría).", effects = {} },
            { id = "cha_res_guia", level = 3, name = "Guia ancestral", type = "informativo", description = "Al curar con un conjuro de 1er nivel o superior y sacar 1 o 2 en un dado, repites el dado (usas el nuevo resultado).", effects = { { kind = "flag", flag = "ancestralGuidance" } } },
            { id = "cha_res_fuerzas", level = 6, name = "Fuerzas anuladoras", type = "informativo", description = "Al lanzar un conjuro sobre un aliado, intentas terminar un efecto de conjuro que lo afecte (según nivel de ranura). 2 usos por descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
        } },
    },
    features = {
        { id = "cha_kalimag", level = 1, name = "Kalimag", type = "informativo", description = "Conoces Kalimag, el idioma de los elementales; dejas mensajes en rocas y agua como el conjuro mensaje.", effects = { { kind = "language", language = "Kalimag" } } },
        { id = "cha_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de chaman usando Sabiduría. CD = 8 + comp + Mod. Sabiduría; ataque = comp + Mod. Sabiduría. Foco druidico.", effects = {} },
        { id = "cha_totemista", level = 2, name = "Totemista", cast = "accion_adicional", type = "recurso", description = "Acción adicional: invocas un tótem (CA 15, PG = 2x nivel) con poderes (Resistencia Elemental + el de tu afinidad). 2 usos por descanso corto o largo (3 a nivel 10, 4 a nivel 18).", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "cha_totem_resistencia", level = 2, name = "Poder totemico: Resistencia Elemental", type = "informativo", cast = "reaccion", description = "Activas el totem cuando una criatura a 4,6 metros de el reciba dano de acido, frio, fuego, rayo o trueno, otorgandole resistencia a ese tipo de dano hasta el final de su siguiente turno. Este poder lo tiene el totem siempre.", effects = {} },
            { id = "cha_totem_aire", level = 2, name = "Poder totemico: Gracia del Aire", type = "informativo", cast = "reaccion", requiresOption = "aire", description = "Por tu Afinidad Elemental de Aire: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Destreza, otorgandole ventaja en su tirada.", effects = {} },
            { id = "cha_totem_tierra", level = 2, name = "Poder totemico: Fuerza de la Tierra", type = "informativo", cast = "reaccion", requiresOption = "tierra", description = "Por tu Afinidad Elemental de Tierra: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Fuerza, otorgandole ventaja en su tirada.", effects = {} },
            { id = "cha_totem_fuego", level = 2, name = "Poder totemico: Lengua de Fuego", type = "informativo", cast = "reaccion", requiresOption = "fuego", description = "Por tu Afinidad Elemental de Fuego: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Carisma, otorgandole ventaja en su tirada.", effects = {} },
            { id = "cha_totem_agua", level = 2, name = "Poder totemico: Corriente Purificadora", type = "informativo", cast = "reaccion", requiresOption = "agua", description = "Por tu Afinidad Elemental de Agua: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Sabiduria, otorgandole ventaja en su tirada.", effects = {} },
        { id = "cha_afinidad_elemental", level = 2, name = "Afinidad elemental", type = "choice", description = "Te sintonizas con un elemento.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "aire",  label = "Aire (+1,5 m de velocidad, +comp a iniciativa)", effects = { { kind = "flag", flag = "initiativeProfBonus" }, { kind = "bonus", target = "speed", value = 1.5 } } },
                { id = "tierra", label = "Tierra (competencia en salvacion de Constitucion)", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                { id = "fuego", label = "Fuego (+comp de daño por fuego, 1/turno)", effects = { { kind = "conditionalWeaponDamage", id = "shaman_fire_affinity", label = "Afinidad Fuego", flatBonus = "pb", damageType = "fuego" } } },
                { id = "agua",  label = "Agua (conjuros conocidos extra)",          effects = {} },
            },
        } },
        { id = "cha_vinculo", level = 3, name = "Vinculo chamanico", type = "informativo", description = "Eliges tu vínculo (Elemental, Mejora o Restauración). Concede rasgos en niveles 3, 6, 14 y 20.", effects = {} },
        ASI("chaman", 4),
        { id = "cha_bestia_espiritual", level = 5, name = "Bestia espiritual", cast = "accion", type = "accion", description = "Accion: asumes la apariencia ilusoria de tu bestia espiritual. No cambia tus estadisticas salvo que tu velocidad pasa a 15 metros. Termina al lanzar un conjuro, atacar, o al usar tu accion adicional para volver a tu forma.", effects = {
            { kind = "toggleState", state = "spirit_beast", label = "Bestia espiritual", description = "Apariencia espectral activa: tu velocidad es 15 m." },
            { kind = "speedOverride", value = 15, requiresState = "spirit_beast" },
        } },
    },
}

-- Rasgos generados a partir de los Ataques con Armas elegidos (Chaman, Mejora). Mismo patron que
-- las maniobras del Guerrero: la opcion elegida se convierte en un rasgo real y ejecutable.
do
    local clase = API.GetClass and API.GetClass("chaman")
    local sub
    for _, sc in ipairs((clase and clase.subclasses) or {}) do
        if sc.id == "mejora" then sub = sc break end
    end
    local eleccion
    for _, f in ipairs((sub and sub.features) or {}) do
        if f.id == "cha_mej_ataques_3" then eleccion = f break end
    end
    for _, opcion in ipairs((eleccion and eleccion.choice and eleccion.choice.options) or {}) do
        sub.features[#sub.features + 1] = {
            id = "cha_mej_atq_" .. tostring(opcion.id),
            icon = opcion.icon,
            level = tonumber(opcion.requiresLevel) or 3,
            name = opcion.label,
            type = "maniobra",
            description = opcion.desc,
            requiresOption = opcion.id,
            effects = ManeuverEffects(opcion, "maelstrom"),
        }
    end
end
