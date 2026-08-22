-- HarfordDnDBook: libro hardcodeado de clases/subclases/rasgos.
-- Solo datos + helpers puros. Los efectos son declarativos, nunca codigo Lua.
--
-- Sistema: World of Warcraft D&D 5ª Edicion (homebrew). Las clases, subclases
-- (especializaciones) y rasgos salen del manual en español. Contenido en curso:
-- rasgos hasta NIVEL 6. Lo no automatizable va como `informativo` con su texto.

HarfordDnDBook = HarfordDnDBook or {}

local API = HarfordDnDBook

-- Rasgo ASI estandar (niveles 4/8/12/16/19; hasta nivel 6 solo aplica el de 4).
local function ASI(classId, level)
    return {
        id = classId .. "_asi_" .. tostring(level), level = level,
        name = "Mejora de Caracteristica", type = "choice",
        description = "Aumenta una característica en 2 o dos caracteristicas en 1 (maximo 20).",
        effects = {},
        choice = { slots = 2, optionsFrom = "ability+1" },
    }
end

local function WeaponProfEffects(...)
    local out = {}
    for i = 1, select("#", ...) do
        out[#out + 1] = { kind = "weaponProf", weapon = select(i, ...) }
    end
    return out
end

-- Motivo por el que un rasgo NO esta mecanizado, o nil si SI lo esta. Sirve para clases,
-- razas, dotes y trasfondos (mismo formato de feature). Se considera mecanizado si tiene
-- efectos, un contador de usos (`uses`) o una eleccion (`choice`). Para el resto (solo
-- `type=="informativo"`) deduce el motivo de la descripcion (heuristica; solo informativo
-- para la UI, no afecta a calculos). Asi "se indica" en los datos que sigue sin mecanizar.
function API.GetUnmechanizedReason(feature)
    if type(feature) ~= "table" then return nil end
    local hasEffects = type(feature.effects) == "table" and #feature.effects > 0
    if hasEffects or type(feature.uses) == "table" or type(feature.choice) == "table" then
        return nil  -- mecanizado: efecto, contador de usos o eleccion
    end
    if feature.type ~= "informativo" then return nil end
    local d = HarfordClassColors.StripAccents(feature.description):lower()
    local function has(...)
        for i = 1, select("#", ...) do if d:find((select(i, ...)), 1, true) then return true end end
        return false
    end
    if has("vision en la oscuridad", "vision en oscuridad", "penumbra a ", "luz tenue a ", "oscuridad como", "ves en luz tenue") then
        return "Vision en la oscuridad: el addon no modela sentidos."
    elseif has("hablas, lees y escribes", "idioma adicional", "idioma extra") then
        return "Idiomas: no se modelan mecanicamente."
    elseif has("arma natural", "golpe desarmado que inflige") then
        return "Arma natural: requiere una capa de arma natural (no existe)."
    elseif has("pg maximos", "puntos de golpe maximos", "puntos de golpe maximos") then
        return "Bono de PG por nivel total: resourceMax solo escala por clase."
    elseif has("conjuro", "truco", "ranura", "hechizo", "lanzas ", "lanzar el conjuro", "augurio", "heroismo") then
        return "Depende del sistema de conjuros (no modelado)."
    elseif has("reaccion") then
        return "Reaccion sobre daño entrante: limitacion del modelo de red."
    elseif has("ventaja en", "con ventaja", "desventaja en") then
        return "Ventaja/desventaja situacional: no hay efecto de ventaja pasiva."
    elseif has("doble de tu bono de competencia", "doble bono de competencia", "competente y sumas el doble", "la mitad de tu bono de competencia") then
        return "Pericia situacional (solo en cierto tipo de pruebas)."
    elseif has("terreno dificil", "velocidad", "salto", "categoria de tamano", "tamano mayor", "altitudes", "altura", "volar", "vuelo") then
        return "Movimiento/tamaño/terreno: no modelado."
    elseif has("herramientas") then
        return "Competencia de herramienta (situacional/no aplicada)."
    elseif has("1 vez por turno", "una vez por turno", "1 vez al turno") then
        return "Limite por turno: el tracker de usos es por descanso, no por turno."
    end
    return "Rasgo narrativo o situacional sin mecanica aplicable."
end

API.CLASSES = {
    {
        id = "caballero_muerte", name = "Caballero de la Muerte", desc = "Antiguo campeon caido y resucitado que empuna poder runico y magia profana, de escarcha y de sangre para dominar el campo de batalla.", hitDie = 10, casterType = "half", startingGold = { dice = 4, sides = 4, multiplier = 10 },
        saves = { "Constitucion", "Carisma" },
        armorProfs = { "ligera", "media", "pesada" },
        weaponProfs = { "sencillas", "marciales" },
        subclasses = {
            { id = "sangre", name = "Sangre", desc = "Tanque no-muerto que se sostiene drenando la vida de sus enemigos.", features = {
                { id = "cdm_comando_oscuro", level = 3, name = "Comando oscuro", type = "informativo", description = "Al dañar con Poder Runico, la criatura tiene desventaja en ataques contra otros que no seas tu hasta el final de tu próximo turno.", effects = {} },
                { id = "cdm_escudo_sangre", level = 3, name = "Escudo de Sangre", type = "informativo", description = "Al lanzar un conjuro de 1er nivel o superior creas un escudo de sangre (PG = 2x nivel CdM + Mod. Carisma) que absorbe daño. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                            { id = "sangre_tormenta_de_huesos", level = 7, name = "Tormenta de Huesos", type = "informativo", description = "A partir del nivel 7, puedes usar tu acción para invocar un torbellino de huesos afilados a tu alrededor. La tormenta tiene un radio de 6,1 metros y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Destreza. Si falla, la criatura recibe daño perforante mágico igual a 1d6 + tu nivel de caballero de la muerte y cae derribada. Si tiene éxito, recibe la mitad del daño y no sufre otros efectos. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso corto o largo.", effects = {} },
                { id = "sangre_golpe_al_corazon", level = 11, name = "Golpe al Corazón", type = "informativo", description = "En el nivel 11, tu poder oscuro refuerza tus ataques. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 de arma. Además, el daño infligido por tus armas rúnicas ignora resistencias.", effects = {} },
                { id = "sangre_purgatorio", level = 15, name = "Purgatorio", type = "informativo", description = "A partir del nivel 15, cuando seas reducido a 0 puntos de golpe y no mueras instantáneamente, puedes optar por quedar con 1 punto de golpe en su lugar y reponer los puntos de golpe de tu escudo de sangre al doble de tu nivel de caballero de la muerte. Una vez que uses esta habilidad, no podrás volver a usarla hasta que termines un descanso largo.", effects = {} },
                { id = "sangre_arma_runica_danza", level = 20, name = "Arma Rúnica Danza", type = "informativo", description = "En el nivel 20, puedes invocar una copia espectral de tu arma rúnica, que danza de manera amenazante en tu espacio. El arma rúnica danzante dura 1 minuto y es idéntica a tu arma rúnica. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo. Al comienzo de cada uno de tus turnos, puedes comandar a tu arma rúnica danzante para que actúe de una de las siguientes maneras hasta el inicio de tu próximo turno (no se requiere acción). ***Defensivamente.*** Obtienes los beneficios de la acción de Esquivar. Además, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en tu turno. Puedes usar esta reacción especial cuando una criatura que puedas ver realiza un ataque contra un objetivo que no seas tú y que esté a 3 metros de ti, imponiendo desventaja en la tirada de ataque.", effects = {} },
            } },
            { id = "escarcha", name = "Escarcha", desc = "Doble empunadura y magia de hielo para ralentizar y despedazar.", features = {
                { id = "cdm_golpe_escarcha", level = 3, name = "Golpe de escarcha", type = "pasivo", description = "Los dados de Poder Runico gastados en un golpe runico pasan a d8 e infligen daño por frío en vez de necrótico.", effects = {
                    { kind = "flag", flag = "frostRunicStrike" },
                } },
                { id = "cdm_maquina_matar", level = 3, name = "Maquina de matar", type = "pasivo", description = "Crítico con armas cuerpo a cuerpo con 19-20. Puedes combatir con dos armas aunque no sean ligeras (si no son pesadas ni a dos manos).", effects = {
                    { kind = "critRange", value = 19, melee = true },
                } },
                            { id = "escarcha_invierno_implacable", level = 7, name = "Invierno Implacable", type = "informativo", description = "A partir del nivel 7, puedes usar tu acción para invocar una tormenta de viento cortante y aguanieve a tu alrededor. La tormenta tiene un radio de 6,1 metros y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Constitución, recibiendo daño por frío igual a 1d6 + tu nivel de caballero de la muerte si falla, o la mitad si tiene éxito. Si falla, la velocidad de la criatura se reduce a la mitad hasta el inicio de su próximo turno. Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso corto o largo.", effects = {} },
                { id = "escarcha_corazon_congelado", level = 11, name = "Corazón Congelado", type = "informativo", description = "En el nivel 11, tus ataques con armas llevan consigo el frío de Rasganorte. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 por frío. Además, tus rasgos y conjuros de caballero de la muerte ignoran la resistencia al frío y tratan la inmunidad al daño por frío como resistencia.", effects = {} },
                { id = "escarcha_garras_de_hielo", level = 15, name = "Garras de Hielo", type = "informativo", description = "A partir del nivel 15, una vez en cada uno de tus turnos, cuando gastes dos o más dados rúnicos a la vez en un golpe rúnico, puedes realizar un ataque adicional con un arma cuerpo a cuerpo como parte de la misma acción de Ataque.", effects = {} },
                { id = "escarcha_pilar_de_escarcha", level = 20, name = "Pilar de Escarcha", type = "informativo", description = "En el nivel 20, eres capaz de canalizar el poder helado del mismísimo Trono Helado. Como acción, puedes convertirte mágicamente en un avatar del invierno todo consumidor, obteniendo los siguientes beneficios durante 1 minuto: - Tienes resistencia al daño contundente, perforante y cortante, e inmunidad al daño por frío. - Añades tu modificador de Carisma al daño de tus ataques con armas cuerpo a cuerpo (mínimo de 1). - Cuando normalmente lanzarías uno o más dados para infligir daño por frío con un conjuro de caballero de la muerte, en su lugar, usas el número más alto posible para cada dado. Por ejemplo, en lugar de infligir 2d8 de daño por frío a una criatura, infliges 16. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo.", effects = {} },
            } },
            { id = "profana", name = "Profano", desc = "Enfermedades y magia profana que corroen y debilitan al enemigo.", features = {
                { id = "cdm_portador_plagas", level = 3, name = "Portador de plagas", type = "informativo", description = "Eliges Brotes (infligir enfermedades profanas con Poder Runico) o Levantar a los Muertos (esbirro no-muerto). Detalle en el manual.", effects = {} },
            } },
        },
        features = {
            { id = "cdm_renacer_oscuro", level = 1, name = "Renacer oscuro", type = "informativo", description = "Eres humanoide y no-muerto a la vez. No duermes (4h de trance = 8h de sueño). Ventaja en salvaciones contra efectos exclusivos de no-muertos.", effects = {} },
            { id = "cdm_armas_runicas", level = 1, name = "Armas runicas", type = "informativo", description = "Vinculas armas runicas (un arma a dos manos o dos de una mano). No te pueden desarmar salvo incapacitado; las invocas como acción adicional.", effects = {} },
            { id = "cdm_poder_runico", level = 1, name = "Poder runico", type = "pasivo", description = "Reserva de dados d6 (1 + nivel CdM) que recarga en descanso largo; no gastas mas dados que tu Mod. Carisma. Alimenta Espiral de la Muerte y Golpe Runico.", effects = {
                { kind = "resourceMax", resource = "runic_power", base = 1, perClassLevel = "caballero_muerte", perLevel = 1 },
            } },
            { id = "cdm_golpe_runico", level = 1, name = "Golpe runico", type = "recurso", description = "Al impactar con un ataque con arma, gastas dados de Poder Runico para infligir daño necrótico adicional. No puedes gastar mas dados que tu Mod. Carisma.", effects = {
                { kind = "conditionalWeaponDamage", id = "runic_strike", label = "Golpe Runico", count = 1, die = 6, damageType = "necrotico", resourceCost = "runic_power", costPerLevel = 1, minLevel = 1, maxLevelAbility = "Carisma", countPerLevel = 1 },
            } },
            { id = "cdm_espiral_muerte", level = 1, name = "Espiral de la Muerte", type = "maniobra", description = "Acción: gastas dados de Poder Runico para lanzar energía necrótica contra una criatura. La criatura realiza una salvación de Constitución contra tu CD de conjuro; si falla, sufre daño necrótico por los dados gastados.", effects = {
                { kind = "energyManeuver", resource = "runic_power", cost = 1, save = "Constitucion", outcome = "sufre energia necrotica", dcAbility = "Carisma", levelCost = true, minLevel = 1, maxLevelAbility = "Carisma", damageDie = 6, damageType = "necrotico" },
            } },
            { id = "cdm_estilo_combate", level = 2, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "defensa",         label = "Defensa (+1 CA con armadura)",       effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                    { id = "duelos",          label = "Duelos (+2 daño un arma a una mano)", effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                    { id = "gran_arma",       label = "Gran Lucha con Armas (repetir 1-2 a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                    { id = "guerrero_profano", label = "Guerrero Profano (2 trucos de brujo, Carisma)", effects = {} },
                    { id = "dos_armas",       label = "Combate con Dos Armas (+mod al 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                },
            } },
            { id = "cdm_lanzamiento_conjuros", level = 2, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de caballero de la muerte usando Carisma. CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma. Foco: tu arma runica.", effects = {} },
            { id = "cdm_constitucion_nomuerta", level = 3, name = "Constitucion no-muerta", type = "pasivo", description = "Inmune a enfermedades y a la condicion envenenado; resistente al daño por veneno.", effects = {
                { kind = "resist", damage = "veneno" },
                { kind = "conditionImmunity", condition = "poisoned" },
            } },
            { id = "cdm_presencia_maligna", level = 3, name = "Presencia maligna", type = "informativo", description = "Eliges tu presencia (Sangre, Escarcha o Profana). Concede rasgos en niveles 3, 7, 11, 15 y 20.", effects = {} },
            ASI("cdm", 4),
            { id = "cdm_ataque_extra", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "cdm_forja_runas", level = 6, name = "Forja de runas", type = "informativo", description = "Tras un descanso largo inscribes una runa en tus armas runicas (una activa a la vez) mientras las empuñas.", effects = {} },
                    { id = "caballero_mu_voluntad_de_la_tumba", level = 10, name = "Voluntad de la Tumba", type = "informativo", description = "A partir del nivel 10, no puedes ser encantado ni asustado mientras estés consciente.", effects = {} },
            { id = "caballero_mu_sin_muerte", level = 14, name = "Sin Muerte", type = "informativo", description = "A partir del nivel 14, no necesitas comer, beber ni respirar. Además, envejeces a un ritmo más lento. Por cada 10 años que pasan, tu cuerpo solo envejece 1 año, y eres inmune al envejecimiento mágico.", effects = {} },
            { id = "caballero_mu_forja_de_runas_superior", level = 18, name = "Forja de Runas Superior", type = "informativo", description = "Al alcanzar el nivel 18, puedes inscribir dos runas diferentes en tus armas rúnicas al mismo tiempo (según lo descrito en tu rasgo de Forja de Runas), y ambas pueden ser cambiadas cuando completes un descanso largo.", effects = {} },
        },
    },
    {
        id = "cazador_demonios", name = "Cazador de Demonios", desc = "Illidari que sacrifico su humanidad absorbiendo esencia demoniaca; agil cazador de gran movilidad y metamorfosis demoniaca.", hitDie = 8, startingGold = { dice = 2, sides = 4, multiplier = 10 },
        saves = { "Destreza", "Carisma" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas", "marciales", "gujas", "hojas gemelas" },
        subclasses = {
            { id = "devastacion", name = "Devastacion", desc = "Agresion implacable de gran movilidad y daño demoniaco.", features = {
                { id = "dh_dev_competencia", level = 3, name = "Competencia adicional (acrobacias)", type = "pasivo", description = "Pericia en Acrobacias (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Acrobacias" },
                    { kind = "flag", flag = "initiativeProfBonus" },
                } },
                { id = "dh_dev_embestida", level = 3, name = "Embestida vil", type = "informativo", description = "Cuando usas Momentum para Correr o Desengancharte, puedes moverte exactamente la mitad de tu velocidad en línea recta. Las criaturas que atraviesan tu recorrido reciben daño de fuego vil igual a tu dado de Caos.", effects = {} },
                { id = "dh_dev_momentum_vengativo", level = 6, name = "Golpe caotico", type = "informativo", description = "Cuando las dos tiradas de ataque de Mordida de Demonio impactan, recuperas 1 punto de Vil. La comprobacion de ambas tiradas sigue siendo manual.", effects = {} },
            } },
            { id = "venganza", name = "Venganza", desc = "Defensa demoniaca que absorbe el castigo y lo devuelve.", features = {
                { id = "dh_ven_competencia", level = 3, name = "Competencia adicional (intimidacion)", type = "pasivo", description = "Pericia en Intimidación (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Intimidacion" },
                } },
                { id = "dh_ven_tormento", level = 3, name = "Tormento", type = "informativo", description = "Acción: una criatura a 30 pies con salvación de Sabiduría o desventaja en ataques contra otros que no seas tu durante 1 minuto.", effects = {} },
                { id = "dh_ven_puas", level = 6, name = "Puas demoniacas", type = "pasivo", description = "En metamorfosis: resistencia a contundente/perforante/cortante y ventaja en pruebas y salvaciones de Fuerza y Destreza.", effects = {
                    { kind = "resist", damage = "contundente", requiresState = "metamorphosis" },
                    { kind = "resist", damage = "perforante", requiresState = "metamorphosis" },
                    { kind = "resist", damage = "cortante", requiresState = "metamorphosis" },
                } },
                { id = "venganza_aura_de_inmolacion", level = 10, name = "Aura de Inmolación", type = "informativo", description = "Al alcanzar el nivel 10, puedes gastar 2 puntos de vil como acción adicional para envolver tu cuerpo en llamas viles. Cuando activas esta aura y al comienzo de cada uno de tus turnos mientras dura, recibes 1d6 puntos de daño por fuego. La aura de inmolación dura 1 minuto, hasta que la termines como acción adicional, o hasta que quedes inconsciente. Siempre que una criatura te golpee con un ataque cuerpo a cuerpo mientras la aura de inmolación está activa, infliges a esa criatura un daño por fuego igual a 1d6 + la mitad de tu nivel de cazador de demonios.", effects = {} },
                { id = "venganza_ultimo_recurso", level = 17, name = "Último Recurso", type = "informativo", description = "A nivel 17, puedes extraer vida de tu marca demoníaca para escapar de la muerte. Cuando te reduzcan a 0 puntos de golpe, puedes gastar 1 punto de vil (no se requiere ninguna acción) para quedarte con 1 punto de golpe en su lugar y entrar en tu metamorfosis hasta el final de tu próximo turno.", effects = {} },
            } },
            { id = "ira", name = "Ira", desc = "Furia desatada que crece con el frenesi del combate.", features = {
                { id = "dh_ira_competencia", level = 3, name = "Competencia adicional (arcano)", type = "pasivo", description = "Pericia en Conocimiento Arcano (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Arcano" },
                } },
                { id = "dh_ira_llamas", level = 3, name = "Llamas del caos", type = "informativo", description = "Ataque a distancia (30 pies) con tu Mod. Destreza; 1d6 de fuego al impactar (1d10 a nivel 11).", effects = {} },
                { id = "dh_ira_marca_ignea", level = 6, name = "Marca ignea", type = "informativo", description = "En metamorfosis, las Llamas del Caos de tu Mordida de Demonio imponen salvación de Constitución (desventaja en ataques) e ignoran resistencia al fuego.", effects = {} },
            } },
        },
        features = {
            { id = "dh_defensa_sin_armadura", level = 1, name = "Guardas demoniacas", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Inteligencia.", effects = {
                { kind = "unarmoredDefenseAbility", ability = "Inteligencia" },
            } },
            { id = "dh_iniciacion_illidari", level = 1, name = "Iniciacion Illidari", type = "pasivo", description = "Tus armas cuerpo a cuerpo que no sean Pesadas ni de Dos manos se consideran Ligeras y Sutiles: usas el mejor modificador entre Fuerza y Destreza. También tienes ventaja en el primer turno contra criaturas que no han actuado, al rastrear con Supervivencia y contra demonios; hablas Eredun.", effects = {
                { kind = "weaponFinesse", meleeOnly = true, excludeHeavy = true, excludeTwoHanded = true },
            } },
            { id = "dh_vision_espectral", level = 1, name = "Vision espectral", type = "pasivo", description = "Visión en oscuridad normal y mágica a 60 pies (con color); eres inmune a cegado. A nivel 7 puedes usar detectar magia.", effects = {
                { kind = "conditionImmunity", condition = "blinded" },
            } },
            { id = "dh_vil", level = 2, name = "Vil", type = "pasivo", description = "Puntos de Vil para alimentar rasgos demoníacos. El maximo es igual a tu nivel de Cazador de Demonios. Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "fel_point", perClassLevel = "cazador_demonios", perLevel = 1 },
            } },
            { id = "dh_mordida_demonio", level = 2, name = "Mordida de Demonio", type = "accion", description = "Después de realizar la acción de Atacar con un arma, puedes gastar 1 punto de Vil para realizar dos ataques con arma como acción adicional. No agregas tu modificador de característica al daño de esos ataques.", actionKind = "demonBite", effects = {} },
            { id = "dh_momentum", level = 2, name = "Momentum", type = "accion", resourceKey = "fel_point", resourceCost = 1, description = "Como acción adicional, gastas 1 punto de Vil para Correr o Desengancharte. Tu distancia de salto se duplica durante ese turno; el movimiento se resuelve en juego.", effects = {} },
            { id = "dh_metamorfosis", level = 2, name = "Metamorfosis", type = "accion", uses = { max = 1, recharge = "long" }, description = "Acción adicional: gastas un uso para transformarte durante 1 minuto. Ganas PG temporales iguales a tu nivel de Cazador de Demonios + Mod. Inteligencia; el estado activa sus efectos de combate.", actionKind = "metamorphosis", effects = {
                { kind = "toggleState", state = "metamorphosis", label = "Metamorfosis", description = "Activa rasgos que solo funcionan mientras estas en metamorfosis." },
                { kind = "weaponExtraDamage", id = "dh_metamorphosis_fire", label = "Metamorfosis", count = 1, perClassLevel = "cazador_demonios", values = { 0, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4 }, damageType = "fuego", requiresState = "metamorphosis" },
            } },
            { id = "dh_marca_demoniaca", level = 3, name = "Marca demoniaca", type = "informativo", description = "Eliges tu marca (Devastacion, Venganza o Ira). Concede rasgos en niveles 3, 6, 10 y 17.", effects = {} },
            ASI("dh", 4),
            { id = "dh_ataque_adicional", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "dh_hambre_instintiva", level = 5, name = "Hambre instintiva", type = "informativo", description = "Reacción al terminar una criatura su turno a 15 pies: te mueves media velocidad hacia ella sin provocar ataques de oportunidad y obtienes ventaja en tu primer ataque contra ella.", effects = {} },
            { id = "cazador_demo_evasion", level = 7, name = "Evasión", type = "informativo", description = "A nivel 7, tus agudos reflejos te permiten esquivar ciertos efectos de área, como el aliento ardiente de un dragón rojo o el conjuro de *tormenta de hielo*. Cuando estés sujeto a un efecto que te permita hacer una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y solo recibes la mitad del daño si fallas.", effects = {} },
            { id = "cazador_demo_un_cazador_por_encima_de_todo", level = 9, name = "Un Cazador por Encima de Todo", type = "informativo", description = "Al alcanzar el nivel 9, has perfeccionado tus instintos para cazar presas. Si pasas al menos 1 minuto observando a una criatura, obtienes ventaja en las pruebas de Sabiduría (Supervivencia) realizadas para rastrear a esa criatura hasta que la hayas matado, elijas una nueva presa o transcurran un número de días igual a tu nivel de cazador de demonios. Si pierdes el rastro de tu presa, puedes pasar 1 hora para percibir su dirección general en relación contigo, siempre y cuando ambos estén en el mismo plano de existencia. Además, en tu primer turno durante el combate, tienes ventaja en las tiradas de ataque realizadas contra la criatura.", effects = {} },
            { id = "cazador_demo_alas_demoniacas", level = 11, name = "Alas Demoníacas", type = "informativo", description = "A partir del nivel 11, puedes usar tu reacción cuando caigas para manifestar alas demoníacas, reduciendo cualquier daño por caída que recibas en una cantidad igual a cinco veces tu nivel de cazador de demonios. Además, durante la duración de tu Metamorfosis, obtienes una velocidad de vuelo igual a tu velocidad de movimiento.", effects = {} },
            { id = "cazador_demo_destreza_illidari", level = 11, name = "Destreza Illidari", type = "informativo", description = "A partir del nivel 11, cuando empuñas un arma cuerpo a cuerpo con la propiedad versátil, puedes usar el valor de daño aumentado incluso cuando la empuñas con una mano. Si decides empuñar el arma con dos manos, no recibes ningún beneficio adicional.", effects = {} },
            { id = "cazador_demo_purificado_por_las_llamas", level = 13, name = "Purificado por las Llamas", type = "informativo", description = "En el nivel 13, puedes usar tu acción y gastar 2 puntos de vil para envolver tu cuerpo en llamas de dolor y finalizar un efecto en ti que te cause estar encantado, asustado o envenenado. Cada criatura en un radio de 1,5 metros de ti cuando uses esta característica debe realizar una tirada de salvación de Destreza, recibiendo 1d10 + la mitad de tu nivel de cazador de demonios en daño por fuego si falla, o la mitad del daño si tiene éxito.", effects = {} },
            { id = "cazador_demo_mirada_reveladora", level = 14, name = "Mirada Reveladora", type = "informativo", description = "A partir del nivel 14, puedes concentrar el vil en tus ojos quemados para revelar la verdad del mundo que te rodea. Como acción, puedes gastar 3 puntos de vil para obtener los beneficios del conjuro *visión verdadera* durante 1 minuto.", effects = {} },
            { id = "cazador_demo_resiliencia_abisal", level = 15, name = "Resiliencia Abisal", type = "informativo", description = "En el nivel 15, has adquirido una fortaleza superior. Ganas competencia en tiradas de salvación de Constitución.", effects = {} },
            { id = "cazador_demo_cuerpo_atemporal", level = 18, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del nivel 18, el vil primordial que fluye por tu cuerpo te ha concedido una longevidad inimaginable. Por cada 10 años que pasen, tu cuerpo envejece solo 1 año y no puedes ser envejecido mágicamente.", effects = {} },
            { id = "cazador_demo_preparado", level = 20, name = "Preparado", type = "informativo", description = "A nivel 20, tus sentidos sobrenaturales te permiten actuar al instante. Puedes tomar dos turnos durante la primera ronda de cualquier combate. Tomas tu primer turno en el conteo de iniciativa 30 y tu segundo turno en tu tirada de iniciativa. Además, cuando tires iniciativa y no tengas puntos de vil restantes, recuperas 2 puntos de vil.", effects = {} },
        },
    },
    {
        id = "druida", name = "Druida", desc = "Guardian de la naturaleza capaz de adoptar formas animales y lanzar magia primigenia de equilibrio, fiereza o restauración.", hitDie = 8, casterType = "full", startingGold = { dice = 2, sides = 4, multiplier = 10 },
        saves = { "Inteligencia", "Sabiduria" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "equilibrio", name = "Equilibrio", desc = "Magia lunar y solar que castiga al enemigo a distancia.", features = {
                { id = "dru_eq_conjuros_camino", level = 2, name = "Conjuros del camino", type = "informativo", description = "Obtienes conjuros del camino (Elune) a niveles 3/5/7/9; siempre preparados y no cuentan en tu limite.", effects = {} },
                { id = "dru_eq_invocar", level = 2, name = "Invocar", type = "informativo", description = "En un descanso corto recuperas espacios de conjuro (nivel combinado <= mitad de tu nivel de druida, ninguno de 6+). 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "dru_eq_fuerza_naturaleza", level = 6, name = "Fuerza de la naturaleza", type = "informativo", description = "Al lanzar un conjuro de un solo objetivo, infliges daño extra o curas igual a tu nivel de druida. 2 usos por descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
                            { id = "equilibrio_influencia_astral", level = 10, name = "Influencia Astral", type = "informativo", description = "Al alcanzar el 10º nivel, encuentras consuelo y poder en la diosa Elune, obteniendo las siguientes características. - Ganas resistencia al daño radiante. - Puedes elegir infligir daño radiante con tu característica Fuerza de la Naturaleza, en lugar del tipo de daño del conjuro. - Tienes ventaja en las pruebas y tiradas de salvación para evitar ser encantado o asustado por efectos de conjuros.", effects = {} },
                { id = "equilibrio_bendicion_de_los_ancestros", level = 14, name = "Bendición de los Ancestros", type = "informativo", description = "A partir del 14º nivel, equilibras las dos fuerzas del mundo. Siempre que terminas un descanso corto o largo, puedes elegir *an'she* o *elune* y obtener los beneficios del equilibrio elegido hasta que termines tu próximo descanso. ***An'she.*** Siempre estás bajo los efectos de un conjuro de *ver lo invisible*. Además, eres inmune a la ceguera y cuando se hace un ataque cuerpo a cuerpo contra ti, puedes usar tu reacción para imponer desventaja en la tirada de ataque. ***Elune.*** Obtienes visión en la oscuridad con un alcance de 18,3 metros. Si ya tienes visión en la oscuridad debido a tu raza, su alcance aumenta en 9,1 metros. Además, mientras estés en penumbra u oscuridad, puedes usar tu reacción para obtener ventaja en tus ataques de hechizo hasta el final de tu turno.", effects = {} },
                { id = "equilibrio_encarnacion_elegido_de_elune", level = 20, name = "Encarnación: Elegido de Elune", type = "informativo", description = "En el nivel 20, has sido elegido por Elune y puedes dejar que sus poderes fluyan a través de ti, tomando una apariencia según tu elección. Por ejemplo, los colores y las estrellas de Elune podrían moverse por tu piel, tu forma de luniscente podría brillar con una luz tenue azulada, o podrías tener una luna creciente flotando sobre tu cabeza. Puedes usar tu acción para asumir tu forma de luniscente y permitir que los poderes de la diosa fluyan a través de ti. Durante 1 minuto, obtienes los siguientes beneficios: - Puedes usar un espacio de conjuro para lanzar el hechizo *rayo de luna*, incluso si no lo tienes preparado, y puedes mover el rayo como una acción adicional. - El alcance de cualquier hechizo de druida que lances se duplica, y cualquier hechizo de druida con un alcance de toque tiene un alcance de 9,1 metros.", effects = {} },
            } },
            { id = "feral", name = "Feral", desc = "Forma de fiera con garras y sigilo depredador.", features = {
                { id = "dru_fer_adaptacion", level = 2, name = "Adaptacion salvaje", type = "choice", description = "Ganas competencia en salvaciones de Destreza o Constitución (además de las del druida). Cuentas como medio lanzador (tabla Feral).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "destreza",     label = "Salvacion de Destreza",     effects = { { kind = "saveProf", ability = "Destreza" } } },
                        { id = "constitucion", label = "Salvacion de Constitucion", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                    },
                } },
                { id = "dru_fer_marca_ursol", level = 2, name = "Marca de ursol", type = "informativo", description = "Puedes lanzar conjuros mientras estas transformado (ignoras componentes V/S y materiales sin coste). 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
                { id = "dru_fer_afinidad", level = 2, name = "Afinidad feral o guardiana", type = "choice", description = "Elige Ravager (daño extra gastando espacio de conjuro) o Frenesi (resistencia fisica transformado).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "ravager", label = "Ravager (daño extra con espacio de conjuro)", effects = {} },
                        { id = "frenesi", label = "Frenesi (resistencia fisica transformado)",   effects = {
                            { kind = "resist", damage = "contundente", requiresState = "wild_shape" },
                            { kind = "resist", damage = "perforante", requiresState = "wild_shape" },
                            { kind = "resist", damage = "cortante", requiresState = "wild_shape" },
                        } },
                    },
                } },
                { id = "dru_fer_instintos", level = 6, name = "Instintos primales", type = "pasivo", description = "Sumas tu Mod. Sabiduría a la iniciativa y no puedes ser sorprendido mientras estas despierto.", effects = {
                    { kind = "initiativeAbility", ability = "Sabiduria" },
                } },
                { id = "dru_fer_ataque_adicional", level = 6, name = "Ataque adicional (transformado)", type = "pasivo", description = "Atacas dos veces al realizar la acción de Atacar mientras estas transformado; esos ataques cuentan como magicos.", effects = {
                    { kind = "flag", flag = "extraAttack", requiresState = "wild_shape" },
                } },
                { id = "dru_fer_tacticas", level = 6, name = "Tacticas ferales", type = "choice", description = "Transformado, elige Defensor de la Manada (intercambiar lugar para recibir un ataque) o Demoledor Pulverizante (derribar con salvación de Fuerza).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "defensor",  label = "Defensor de la Manada", effects = {} },
                        { id = "demoledor", label = "Demoledor Pulverizante", effects = {} },
                    },
                } },
                { id = "feral_mutilacion_brutal", level = 10, name = "Mutilación Brutal", type = "informativo", description = "En el nivel 10, cuando golpeas a una criatura con un ataque de arma mientras estás transformado, la criatura golpeada tiene desventaja en la próxima tirada de salvación que haga contra un hechizo de druida que lances antes del final de tu siguiente turno.", effects = {} },
                { id = "feral_afinidad_superior_feral_o_guar", level = 14, name = "Afinidad Superior Feral o Guardiana", type = "informativo", description = "A partir del nivel 14, obtienes una de las siguientes características, según tu elección en el nivel 2. ***Ravager.*** Cuando una criatura hostil que puedes ver a tu alcance sea golpeada por un ataque realizado por otra criatura, puedes usar tu reacción para hacer un ataque de oportunidad contra esa criatura hostil. ***Frenesí.*** Mientras estás en frenesí, cualquier criatura a 1,5 metros de ti que sea hostil hacia ti tiene desventaja en las tiradas de ataque contra objetivos que no seas tú u otro personaje con esta característica. Un enemigo es inmune a este efecto si no puede verte u oírte o si no puede ser asustado.", effects = {} },
                { id = "feral_encarnacion_guardian_de_las_ti", level = 20, name = "Encarnación: Guardián de las Tierras Salvajes", type = "informativo", description = "En el nivel 20, puedes asumir la forma de un guardián de las tierras salvajes, mejorando la apariencia de tu transformación y empoderándote a través de las fuerzas de la naturaleza. La corteza se manifiesta como una armadura alrededor de ti y tu apariencia se vuelve feroz y aterradora a medida que las tierras salvajes te otorgan su poder. Mientras estás transformado, puedes usar tu acción para encarnar las tierras salvajes. Durante 1 minuto, obtienes los siguientes beneficios: - Cuando realizas la acción de Ataque en tu turno, puedes hacer un ataque adicional como parte de esa acción. - Todas las tiradas de ataque tienen desventaja contra ti, ya que la armadura de corteza toma el frente de los golpes. - Tu velocidad base aumenta en 3 metros y puedes ignorar el terreno difícil. La encarnación persiste más allá de tus transformaciones, pero no tiene efecto fuera de ellas.", effects = {} },
            } },
            { id = "restauracion", name = "Restauracion", desc = "Sanacion sostenida con magia de la naturaleza.", features = {
                { id = "dru_res_conjuros_camino", level = 2, name = "Hechizos del camino", type = "informativo", description = "Obtienes hechizos del camino a niveles 3/5/7/9; siempre preparados y no cuentan en tu limite.", effects = {} },
                { id = "dru_res_rejuvenecimiento", level = 2, name = "Alivio presto", type = "recurso", description = "Reserva de d6 igual a tu nivel de druida. Cuando un conjuro tuyo restaura puntos de golpe, puedes gastar hasta la mitad de tu nivel en dados para sumar su resultado a la curación. También puedes hacerlo como reacción cuando una criatura recupera PG durante su turno con un conjuro tuyo. Recarga en descanso largo.", effects = {
                    { kind = "resourceMax", resource = "living_seeds", perClassLevel = "druida", perLevel = 1 },
                } },
                { id = "dru_res_marca_salvaje", level = 6, name = "Marca de lo salvaje", type = "accion", description = "Acción: tu y hasta un numero de aliados igual a tu Mod. Sabiduría a 30 m ganáis +1 a la CA, tiradas de salvación y tiradas de daño durante 1 minuto.", uses = { proficiencyBonus = true, recharge = "long" }, effects = {} },
                            { id = "restauracion_rejuvenecimiento", level = 2, name = "Rejuvenecimiento", type = "informativo", description = "Cuando eliges este camino en el nivel 2, recibes las bendiciones de Elune, convirtiéndote en una fuente de energía que ofrece alivio de las heridas. Tienes una reserva de energía representada por un número de d6 igual a tu nivel de druida. Como acción adicional, puedes elegir una criatura que puedas ver a 36,6 metros de ti y gastar un número de esos dados igual a la mitad de tu nivel de druida o menos. Lanza los dados gastados y súmalos. El objetivo recupera una cantidad de puntos de golpe igual al total. El objetivo también gana 1 punto de golpe temporal por dado. Recuperas todos los dados gastados cuando terminas un descanso largo.", effects = {} },
                { id = "restauracion_corteza_de_hierro", level = 6, name = "Corteza de Hierro", type = "informativo", description = "A partir del nivel 6, cuando tú o una criatura dentro de 9,1 metros de ti reciban daño por ácido, frío, fuego, relámpago o trueno, puedes usar tu reacción para otorgar resistencia a la criatura contra esa instancia del daño.", effects = {} },
                { id = "restauracion_tranquilidad", level = 10, name = "Tranquilidad", type = "informativo", description = "A partir del nivel 10, puedes recurrir a la naturaleza tranquila que te rodea para calmar a tus aliados. Como acción, invocas la tranquilidad y obtienes una reserva de energía de curación que puede restaurar puntos de golpe igual a cinco veces tu nivel de druida. Mantener la tranquilidad requiere tu concentración, dura hasta 1 minuto, y mientras estás concentrado en ella, tu velocidad de movimiento se reduce a la mitad. Mientras esté activa, puedes usar una acción adicional para elegir cualquier número de criaturas dentro de 9,1 metros de ti y dividir un número de puntos de golpe de tu reserva entre ellas, hasta un máximo de puntos de golpe igual a tu nivel de druida. Una vez que usas esta característica, no puedes usarla nuevamente hasta que termines un descanso largo.", effects = {} },
                { id = "restauracion_guardia_cenarion", level = 14, name = "Guardia Cenarion", type = "informativo", description = "Cuando alcanzas el nivel 14, las criaturas del mundo natural sienten tu conexión con la naturaleza y se vuelven reticentes a atacarte. Cuando una bestia o planta te ataque, la criatura debe hacer una tirada de salvación de Sabiduría contra la CD de salvación de tus hechizos de druida. Si falla, la criatura debe elegir un objetivo diferente o el ataque falla automáticamente. Si tiene éxito, la criatura es inmune a este efecto durante 24 horas. La criatura es consciente de este efecto antes de realizar su ataque contra ti.", effects = {} },
                { id = "restauracion_encarnacion_arbol_de_vida", level = 20, name = "Encarnación: Arbol de Vida", type = "informativo", description = "Al llegar al nivel 20, puedes obtener fuerza de los árboles del mundo de Azeroth, aumentando tu forma de árbol a igualar a un anciano mientras asumes la forma serena de un Árbol de la Vida. Puedes usar tu acción para asumir tu forma de árbol y encarnar el Árbol de la Vida. Durante 1 minuto, obtienes los siguientes beneficios: - Al comienzo de cada uno de tus turnos, ganas 10 puntos de golpe temporales. Cuando la encarnación termina, pierdes cualquier punto de golpe temporal que te quede. - Tu tamaño se convierte en Grande, a menos que ya fueras más grande. - Cuando lanzas un hechizo que restaura puntos de golpe a un objetivo, otra criatura a tu elección dentro de 9,1 metros de ese objetivo recupera puntos de golpe igual a la mitad de la cantidad restaurada. La encarnación persiste más allá de la transformación, pero no tiene efecto fuera de tu forma de árbol.", effects = {} },
            } },
        },
        features = {
            { id = "dru_druidico", level = 1, name = "Druidico", type = "informativo", description = "Conoces el druidico, el lenguaje secreto de los druidas (hablar, leer y escribir).", effects = {} },
            { id = "dru_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de druida usando Sabiduría (preparas Mod. Sabiduría + nivel). CD = 8 + comp + Mod. Sabiduría; ataque = comp + Mod. Sabiduría. Foco druidico.", effects = {} },
            { id = "dru_cambio_forma", level = 2, name = "Cambio de forma", type = "pasivo", description = "Acción: asumes una forma druidica conocida (gato, oso, lechucico lunar, árbol...). Mas formas a niveles 4 y 8.", effects = {
                { kind = "toggleState", state = "wild_shape", label = "Transformado", description = "Activa rasgos que solo funcionan mientras estas en forma druidica." },
            } },
            { id = "dru_senda", level = 2, name = "Senda del Druida", type = "informativo", description = "Eliges tu senda (Equilibrio, Feral o Restauración). Concede rasgos en niveles 2, 6, 10, 14 y 20.", effects = {} },
            { id = "dru_afinidades", level = 3, name = "Afinidades salvajes", type = "informativo", description = "Obtienes 2 afinidades salvajes de tu elección (mas a niveles superiores). Opciones detalladas al final de la clase.", effects = {} },
            ASI("druida", 4),
            { id = "dru_mejora_cambio_forma", level = 4, name = "Mejora de cambio de forma", type = "informativo", description = "Mejora tus formas druídicas (nuevas formas/beneficios según la tabla de formas).", effects = {} },
            { id = "druida_cuerpo_atemporal", level = 18, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del nivel 18, la magia primigenia que manejas ha hecho que envejezcas más lentamente. Por cada 10 años que pasan, tu cuerpo envejece solo 1 año.", effects = {} },
            { id = "druida_alma_del_bosque", level = 18, name = "Alma del Bosque", type = "informativo", description = "A partir del nivel 18, tu conexión con la naturaleza crece a nuevas profundidades, fortaleciendo tu vínculo con ella y permitiéndote conjurar un portal al Sueño Esmeralda. Si pasas 10 minutos en un área de naturaleza intacta, puedes conjurar un portal al Sueño Esmeralda. La entrada brilla tenuemente y mide 1,5 metros de ancho y 3 metros de alto. Tú y cualquier criatura que designes al conjurar el portal pueden entrar al Sueño Esmeralda mientras el portal permanezca abierto. Puedes abrir y cerrar el portal si estás a menos de 9,1 metros de él. Cuando está cerrado, el portal en Azeroth se desmorona y es efectivamente invisible. El portal permanece conjurado durante 24 horas, después de lo cual se desmorona por completo y no puede ser conjurado nuevamente durante 7 días.", effects = {} },
        },
    },
    {
        id = "cazador", name = "Cazador", desc = "Experto rastreador y tirador que combate junto a una bestia companera y domina las armas a distancia.", hitDie = 10, startingGold = { dice = 5, sides = 4, multiplier = 10 },
        saves = { "Fuerza", "Destreza" },
        armorProfs = { "ligera", "media" },
        weaponProfs = { "sencillas", "marciales", "armas de fuego" },
        subclasses = {
            { id = "bestias", name = "Bestias", desc = "Vínculo profundo con una poderosa bestia companera.", features = {
                { id = "caz_bes_domador", level = 3, name = "Domador de bestias", type = "informativo", description = "Puedes domar bestias Grandes o menores con valor de desafío 1 o menor.", effects = {} },
                { id = "caz_bes_aspecto", level = 3, name = "Aspecto de la bestia", type = "informativo", description = "Lanzas sentido de la bestia como ritual, solo en tu mascota.", effects = {} },
                { id = "caz_bes_comando", level = 5, name = "Comando de matar", type = "informativo", description = "Acción adicional + dado de enfoque: tu mascota Ataca con ventaja; añades el dado al daño del primer impacto.", effects = {} },
                            { id = "bestias_vinculo_del_companero", level = 3, name = "Vínculo del Compañero", type = "informativo", description = "Tu leal compañero gana una variedad de beneficios. - La bestia pierde su acción de Multiataque, si tiene una. - Tu compañero obedece tus órdenes lo mejor que puede. Comparte tu conteo de iniciativa, pero actúa inmediatamente después de ti. Puede moverse y usar su reacción por sí solo, pero la única acción que realiza es la acción de Esquivar, a menos que uses tu acción adicional para ordenarle que realice la acción de Atacar, Correr, Desengancharse o Ayudar. Si estás incapacitado o ausente, tu bestia actúa por su cuenta. - Tu compañero bestial tiene habilidades y estadísticas determinadas en parte por tu nivel, usando tu bonificador de competencia en lugar del suyo. Además de las áreas donde normalmente usa su bonificador de competencia, tu compañero también agrega su bonificador de competencia a su CA y a sus tiradas de daño.", effects = {} },
            } },
            { id = "punteria", name = "Punteria", desc = "Tiros precisos y devastadores a larga distancia.", features = {
                { id = "caz_pun_disparo_arcano", level = 3, name = "Disparo arcano", type = "informativo", description = "Tus ataques a distancia contra tu marcado ignoran cobertura e infligen +(2 + mitad de nivel) de fuerza. Usos = Mod. Sabiduría.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
                { id = "caz_pun_lobo_apuntado", level = 3, name = "Lobo solitario: Ataque apuntado", type = "pasivo", description = "Sin compañero bestial, acción adicional para dar ventaja a tu próximo ataque con arma.", effects = {
                    { kind = "toggleState", state = "lone_wolf", label = "Lobo Solitario", description = "Activa rasgos que requieren combatir sin companero bestial." },
                } },
                { id = "caz_pun_disparo_conmocionante", level = 5, name = "Disparo conmocionante", type = "accion", resourceKey = "focus", resourceCost = 1, description = "Gasta un dado de enfoque para sumarlo a la CD de concentración que provoque tu ataque.", effects = {} },
                { id = "caz_pun_lobo_ataque", level = 5, name = "Lobo solitario: Ataque adicional", type = "pasivo", description = "Sin compañero bestial, atacas dos veces al realizar la acción de Atacar.", effects = {
                    { kind = "flag", flag = "extraAttack", requiresState = "lone_wolf" },
                } },
                            { id = "punteria_aspecto_del_aguila", level = 7, name = "Aspecto del Aguila", type = "informativo", description = "A partir del nivel 7, puedes ver hasta 1,6 km de distancia sin dificultad, pudiendo discernir incluso los detalles más finos como si estuvieras observando algo a no más de 30 metros de distancia. Además, atacar a larga distancia no impone desventaja en tus tiradas de ataque con armas a distancia.", effects = {} },
                { id = "punteria_ataque_multiple", level = 11, name = "Ataque Múltiple", type = "informativo", description = "Al alcanzar el nivel 11, obtienes una de las siguientes características de tu elección. ***Disparo de Quimera.*** Una vez en cada uno de tus turnos, cuando hagas un ataque con arma a distancia, puedes realizar otro ataque con la misma arma contra una criatura diferente que esté a 1,5 metros del objetivo original y dentro del alcance de tu arma. Si se usa con tu característica Lobo Solitario, ambos ataques tienen ventaja. ***Disparo Penetrante.*** Una vez en cada uno de tus turnos, cuando realices un ataque con arma a distancia contra una criatura, puedes hacer que el ataque atraviese múltiples criaturas. Realiza una tirada de ataque con desventaja contra cada criatura en una línea directamente detrás del objetivo original, hasta que falles, golpees un objeto o alcances el rango normal de tu arma, lo que ocurra primero.", effects = {} },
                { id = "punteria_enfoque_del_tirador", level = 15, name = "Enfoque del Tirador", type = "informativo", description = "En el nivel 15, cuando lances iniciativa y no tengas usos restantes de Disparo Arcano, recuperas un uso.", effects = {} },
            } },
            { id = "supervivencia", name = "Supervivencia", desc = "Trampas, cuerpo a cuerpo y dominio del terreno.", features = {
                { id = "caz_sup_trampero", level = 3, name = "Trampero experto", type = "informativo", description = "Aprendes y colocas trampas (2 conocidas; mas a niveles superiores). CD de Trampa = 8 + comp + Mod. Sabiduría.", effects = {} },
                { id = "caz_sup_estudiante", level = 3, name = "Estudiante de lo salvaje", type = "pasivo", description = "Pericia en Supervivencia (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Supervivencia" },
                } },
                { id = "caz_sup_lobo_salvaje", level = 3, name = "Lobo solitario: Nacido para ser salvaje", type = "pasivo", description = "Sin compañero bestial, tus ataques con arma son criticos con 19-20 y Desengancharte es acción adicional.", effects = {
                    { kind = "toggleState", state = "lone_wolf", label = "Lobo Solitario", description = "Activa rasgos que requieren combatir sin companero bestial." },
                    { kind = "critRange", value = 19, requiresState = "lone_wolf" },
                } },
                { id = "caz_sup_corte_ala", level = 5, name = "Corte de ala", type = "accion", resourceKey = "focus", resourceCost = 1, description = "Al golpear, gasta un dado de enfoque: el objetivo con Fuerza (Atletismo) o su velocidad baja a 0 hasta tu próximo turno.", effects = {} },
                { id = "caz_sup_lobo_ataque", level = 5, name = "Lobo solitario: Ataque adicional", type = "pasivo", description = "Sin compañero bestial, atacas dos veces al realizar la acción de Atacar.", effects = {
                    { kind = "flag", flag = "extraAttack", requiresState = "lone_wolf" },
                } },
                            { id = "supervivencia_camuflaje_natural", level = 7, name = "Camuflaje Natural", type = "informativo", description = "A partir del nivel 7, obtienes la capacidad de lanzar el conjuro *pasar sin dejar rastro* sin proporcionar componentes materiales, pero solo como un ritual. Debes tener acceso a barro fresco, tierra, plantas, hollín u otros materiales naturales para poder hacerlo.", effects = {} },
                { id = "supervivencia_contraataque_marcado", level = 11, name = "Contraataque Marcado", type = "informativo", description = "Al alcanzar el nivel 11, si tu objetivo marcado te obliga a realizar una tirada de salvación, puedes usar tu reacción para realizar un ataque con arma contra el objetivo. Realizas este ataque antes de hacer la tirada de salvación. Si tu ataque impacta, obtienes ventaja en tu tirada de salvación, además de los efectos normales del ataque.", effects = {} },
                { id = "supervivencia_terminos_de_compromiso", level = 15, name = "Términos de Compromiso", type = "informativo", description = "En el nivel 15, demuestras un control incomparable sobre tus trampas y utilizas las oportunidades que crean. Obtienes los siguientes beneficios: - Tienes ventaja en ataques con armas contra cualquier criatura que haya sido golpeada por una de tus trampas desde el final de tu último turno. - Tus trampas ya no se activan cuando una criatura entra en su alcance; en su lugar, puedes elegir como acción gratuita activar una trampa, incluso si no hay una criatura cerca.", effects = {} },
                            { id = "supervivencia_trampas", level = 3, name = "Trampas", type = "informativo", description = "Las trampas se presentan en orden alfabético. ***Trampa de Oso.*** Cuando se activa la trampa, cada criatura en su alcance debe tener éxito en una tirada de salvación de Destreza o ser derribada y quedar boca abajo en su espacio. Cualquier criatura derribada por esta trampa tiene su velocidad reducida a 0 hasta el inicio de su siguiente turno. ***Trampa Cegadora.*** Cuando se activa la trampa, cada criatura en su alcance debe realizar una tirada de salvación de Constitución. En una tirada fallida, el objetivo queda cegado hasta el inicio de su siguiente turno. Cualquier criatura invisible que falle esta tirada brilla con luz tenue, haciéndola visible por la duración. ***Trampa Enredadora.*** Cuando se activa la trampa, cada criatura en su alcance debe tener éxito en una tirada de salvación de Fuerza o quedar restringida durante 1 minuto.", effects = {} },
            } },
        },
        features = {
            { id = "caz_marca_cazador", level = 1, name = "Marca del Cazador", type = "accion", actionKind = "huntersMark", markAuraId = 259556, description = "Acción adicional: marcas una criatura a 120 pies. Hasta que termine la marca, una vez por turno infliges +1d4 de daño al golpearla con un arma (sube a 1d6/1d8/1d10 con el nivel). Ventaja en Percepción y Supervivencia para encontrarla.", effects = {
                { kind = "conditionalWeaponDamage", id = "hunters_mark", label = "Marca del Cazador", count = 1, die = 4, scaleClassId = "cazador", dieScale = { { 6, 6 }, { 11, 8 }, { 16, 10 } }, requiresMarkedTarget = true },
            } },
            { id = "caz_explorador_natural", level = 1, name = "Explorador natural", type = "pasivo", description = "Sumas tu Mod. Sabiduría a la iniciativa; ventaja en el primer turno contra criaturas que no han actuado; ventajas viajando por la naturaleza.", effects = {
                { kind = "initiativeAbility", ability = "Sabiduria" },
            } },
            { id = "caz_estilo_combate", level = 2, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "tiro_arco",   label = "Tiro con Arco (+2 ataque a distancia)", effects = { { kind = "bonus", target = "weaponAttack", value = 2 } } },
                    { id = "tirador",     label = "Tirador en Combate Cercano (+1 ataque a distancia, ignora cobertura)", effects = { { kind = "bonus", target = "weaponAttack", value = 1 } } },
                    { id = "dos_armas",   label = "Combate con Dos Armas (+mod al 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                    { id = "gran_arma",   label = "Combate con Arma Grande (repetir 1-2 a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                },
            } },
            { id = "caz_enfoque", level = 2, name = "Enfoque", type = "pasivo", description = "Dados de enfoque (d8, según la tabla) para Llamada de lo Salvaje, Ataque Preciso y Tacticas de Supervivencia. Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "focus", perClassLevel = "cazador", values = { 0, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10 } },
            } },
            { id = "caz_empatia_animal", level = 2, name = "Empatia animal", type = "informativo", description = "Te comunicas con bestias y lees su estado de animo e intencion básica.", effects = {} },
            { id = "caz_arquetipo", level = 3, name = "Arquetipo de Cazador", type = "informativo", description = "Eliges tu arquetipo (Maestro de Bestias, Punteria o Supervivencia). Concede rasgos en niveles 3, 5, 7, 11 y 15.", effects = {} },
            { id = "caz_domar_bestia", level = 3, name = "Domar bestia", type = "informativo", description = "Vinculas una bestia (Mediana o menor, desafío 1/2 o menor) como compañero (Vínculo del Compañero).", effects = {} },
            ASI("cazador", 4),
                    { id = "cazador_conocimiento_del_depredador", level = 10, name = "Conocimiento del Depredador", type = "informativo", description = "En el 10º nivel, puedes obtener un conocimiento íntimo de las capacidades de tu objetivo marcado. Puedes usar tu acción para aprender dos de las siguientes características de tu elección sobre el objetivo de tu marca de cazador si está dentro de 36,6 metros. - Tipo de Criatura - Clase de Armadura - Velocidad - Vulnerabilidades al Daño - Resistencias al Daño - Inmunidades al Daño - Sentidos Una vez que hayas obtenido las capacidades de una criatura, no puedes usar *Conocimiento del Depredador* para aprender más sobre la criatura, o sobre otra criatura similar, durante las siguientes 24 horas.", effects = {} },
            { id = "cazador_acechador", level = 14, name = "Acechador", type = "informativo", description = "A partir del 14º nivel, puedes usar la acción de Esconderse como una acción adicional en tu turno. Además, no puedes ser rastreado por medios no mágicos, a menos que elijas dejar un rastro.", effects = {} },
            { id = "cazador_sentidos_agudizados", level = 18, name = "Sentidos Agudizados", type = "informativo", description = "A partir del 18º nivel, obtienes sentidos sobrenaturales que te ayudan a luchar contra criaturas que no puedes ver. Cuando atacas a una criatura que no puedes ver, tu incapacidad para verla no impone desventaja en tus tiradas de ataque contra ella. También eres consciente de la ubicación de cualquier criatura invisible dentro de 9,1 metros de ti, siempre que la criatura no esté escondida de ti y no estés cegado o ensordecido.", effects = {} },
            { id = "cazador_aspecto_de_lo_salvaje", level = 20, name = "Aspecto de lo Salvaje", type = "informativo", description = "En el 20º nivel, te conviertes en un cazador incomparable. Una vez en cada uno de tus turnos, puedes añadir tu modificador de Sabiduría a la tirada de ataque o a la tirada de daño de un ataque que realices. Puedes elegir usar esta característica antes o después de la tirada, pero antes de que se apliquen los efectos de la tirada.", effects = {} },
        },
    },
    {
        id = "mago", name = "Mago", desc = "Estudioso de las artes arcanas que moldea fuego, escarcha y energía pura mediante conjuros aprendidos.", hitDie = 6, casterType = "full", startingGold = { dice = 4, sides = 4, multiplier = 10 },
        saves = { "Inteligencia", "Sabiduria" },
        armorProfs = {},
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "arcano", name = "Arcano", desc = "Manipulacion de energía arcana pura y gran eficiencia mágica.", features = {
                { id = "mago_arc_truco", level = 2, name = "Truco adicional (prestidigitacion)", type = "informativo", description = "Aprendes prestidigitacion (u otro truco de mago); no cuenta en tu limite.", effects = {} },
                { id = "mago_arc_cargas", level = 2, name = "Cargas arcanas", type = "informativo", description = "Al lanzar un conjuro de 1er nivel o superior ganas una carga arcana (= nivel, max 5) que gastas para sumar bonus a ataque/daño o salvaciones.", effects = {} },
                { id = "mago_arc_desplazamiento", level = 2, name = "Desplazamiento temporal", type = "informativo", description = "Tras tirar iniciativa, intercambias tu resultado con el de otra criatura visible. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "mago_arc_brillantez", level = 6, name = "Brillantez arcana", type = "pasivo", description = "Pericia en Conocimiento Arcano (competencia y bonus duplicado). Siempre bajo entender idiomas.", effects = {
                    { kind = "skillExpertise", skill = "Arcano" },
                } },
            } },
            { id = "fuego", name = "Fuego", desc = "Conjuros incendiarios de alto daño y combustion.", features = {
                { id = "mago_fue_truco", level = 2, name = "Truco adicional (controlar llamas)", type = "informativo", description = "Aprendes controlar llamas (u otro truco de mago); no cuenta en tu limite.", effects = {} },
                { id = "mago_fue_racha", level = 2, name = "Racha de calor", type = "informativo", description = "Al sacar el maximo en un dado de daño de conjuro, relanza ese dado y suma el resultado. 1 vez por turno.", effects = {} },
                { id = "mago_fue_cauterizar", level = 6, name = "Cauterizar", type = "informativo", description = "Reacción al caer a 0 PG: quedas a 1 PG y las criaturas a 10 pies reciben fuego = mitad de nivel + Mod. Inteligencia. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "fuego_prender", level = 10, name = "Prender", type = "informativo", description = "*Característica de Estudio del Fuego de 10.º nivel* Cuando infliges daño de fuego con un conjuro usando un espacio de conjuro de hasta 5.º nivel, puedes gastar hasta 3 puntos de hechicería para potenciarlo. Por cada punto de hechicería gastado, añade un dado extra al daño infligido por el conjuro. Por ejemplo, cuando lanzas *manos ardientes* y gastas 2 puntos, agregas 2d6 adicionales al daño del conjuro. Cuando lanzas un conjuro que hace múltiples tiradas de ataque, como *rayo abrasador*, debes gastar los puntos en cada ataque individualmente.", effects = {} },
                { id = "fuego_combustion", level = 14, name = "Combustión", type = "informativo", description = "*Característica de Estudio del Fuego de 14.º nivel* Puedes desatar las llamas que arden dentro de ti. Como acción, te envuelves en un torbellino de fuego. Por 1 minuto, obtienes los siguientes beneficios: - Irradias luz brillante en un radio de 9,1 metros y luz tenue en 9,1 metros adicionales. - Cualquier criatura recibe daño de fuego igual a la mitad de tu nivel de mago si te golpea con un ataque cuerpo a cuerpo. - Cualquier conjuro o efecto que crees ignora la resistencia al daño de fuego y trata la inmunidad al daño de fuego como resistencia al mismo. - Eres inmune al daño de fuego y tienes resistencia al daño por frío. - Tus ataques de conjuro obtienen un golpe crítico con una tirada de 19 o 20 en el d20. Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo, a menos que gastes 5 puntos de hechicería para usarla nuevamente.", effects = {} },
            } },
            { id = "escarcha", name = "Escarcha", desc = "Control, ralentizacion y daño de hielo.", features = {
                { id = "mago_esc_truco", level = 2, name = "Truco adicional (moldear agua)", type = "informativo", description = "Aprendes moldear agua (u otro truco de mago); no cuenta en tu limite.", effects = {} },
                { id = "mago_esc_dedos", level = 2, name = "Dedos de escarcha", type = "choice", description = "Elige Barrera de Hielo (escudo de PG temporal con conjuros de frío) o Elemental de Agua (compañero).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "barrera",   label = "Barrera de Hielo", effects = {} },
                        { id = "elemental", label = "Elemental de Agua", effects = {} },
                    },
                } },
                { id = "mago_esc_congelacion", level = 6, name = "Congelacion cerebral", type = "accion", resourceKey = "mage_point", resourceCost = 1, description = "El daño por frío de tus conjuros reduce 10 pies la velocidad; puedes gastar un punto de hechicería para restringir (salvación de Fuerza).", effects = {} },
                { id = "escarcha_manos_de_escarcha", level = 10, name = "Manos de Escarcha", type = "informativo", description = "*Característica de Estudio de la Escarcha de 10.º nivel* Obtienes una de las siguientes características, dependiendo de tu elección a nivel 2. ***Barrera de Hielo.*** Cuando una criatura que puedes ver dentro de 9,1 metros de ti recibe daño, puedes usar tu reacción para hacer que tu Barrera de Hielo se manifieste alrededor de ella y absorba el daño. Si este daño reduce la barrera a 0 puntos de golpe, la criatura barricada recibe cualquier daño restante. Además, ahora puedes gastar puntos de hechicería para causar el efecto de Congelación Cerebral. ***Elemental de Agua.*** Tu elemental de agua se convierte en un elemental de hielo y obtiene los siguientes beneficios adicionales: - Gana inmunidad al daño por frío. - Congelación Cerebral ahora se aplica al daño por frío causado por el elemental.", effects = {} },
                { id = "escarcha_anillo_de_escarcha", level = 14, name = "Anillo de Escarcha", type = "informativo", description = "*Característica de Estudio de la Escarcha de 14.º nivel* Puedes usar tu acción para conjurar un anillo de runas mágicas que invoca el frío más profundo alrededor de un punto que elijas dentro de 18,3 metros. El anillo tiene un radio de 9,1 metros y llena un cilindro de 3 metros de altura con frío gélido. Las criaturas dentro del área deben tener éxito en una tirada de salvación de Fuerza contra la CD de salvación de tus conjuros o quedar paralizadas hasta 1 minuto o hasta que reciban daño. Si el cuerpo de una criatura está completamente dentro del área, la tirada de salvación se realiza con desventaja. En una tirada de salvación exitosa, la criatura no queda restringida. Además, las criaturas que pasan por el área por medios no mágicos tienen su velocidad de movimiento reducida a la mitad hasta el final de su próximo turno después de salir del área.", effects = {} },
            } },
        },
        features = {
            { id = "mago_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Libro de conjuros; preparas Mod. Inteligencia + nivel. CD = 8 + comp + Mod. Inteligencia; ataque = comp + Mod. Inteligencia. Foco arcano.", effects = {} },
            { id = "mago_sentido_magico", level = 1, name = "Sentido magico", type = "informativo", description = "Percibes magia residual reciente y lees escritura mágica oculta. Además puedes crear escritura mágica oculta en idiomas que conozcas.", effects = {} },
            { id = "mago_fuente_magia", level = 2, name = "Fuente de magia", type = "pasivo", description = "Puntos de hechicería (= nivel) para Lanzamiento Flexible (convertir puntos en espacios de conjuro y viceversa). Recargan en descanso largo.", effects = {
                { kind = "resourceMax", resource = "mage_point", perClassLevel = "mago", perLevel = 1 },
            } },
            { id = "mago_estudio_magico", level = 2, name = "Estudio magico", type = "informativo", description = "Eliges tu estudio (Arcano, Fuego o Escarcha). Concede rasgos en niveles 2, 6, 10 y 14.", effects = {} },
            { id = "mago_metamagia", level = 3, name = "Metamagia", type = "choice", description = "Aprendes dos opciones de metamagia para alterar tus conjuros gastando puntos de hechicería (aprendes mas a niveles 10 y 17).", effects = {}, choice = {
                slots = 2,
                options = {
                    { id = "cuidadoso",  label = "Conjuro Cuidadoso",  effects = {} },
                    { id = "distante",   label = "Conjuro Distante",   effects = {} },
                    { id = "potenciado", label = "Conjuro Potenciado", effects = {} },
                    { id = "prolongado", label = "Conjuro Prolongado", effects = {} },
                    { id = "rapido",     label = "Conjuro Rapido",     effects = {} },
                    { id = "sutil",      label = "Conjuro Sutil",      effects = {} },
                    { id = "gemelo",     label = "Conjuro Gemelo",     effects = {} },
                },
            } },
            { id = "mago_formulas_cantrips", level = 3, name = "Formulas de trucos", type = "informativo", description = "Aprendes a modificar tus trucos con formulas arcanas.", effects = {} },
            ASI("mago", 4),
        },
    },
    {
        id = "monje", name = "Monje", desc = "Artista marcial que canaliza el chi para golpear con rapidez, sanar con nieblas o resistir como un muro.", hitDie = 8, startingGold = { dice = 5, sides = 4, multiplier = 1 },
        saves = { "Fuerza", "Destreza" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas", "espadas cortas" },
        subclasses = {
            { id = "cervecero", name = "Maestro cervecero", desc = "Muro resistente que aguanta y dispersa el daño.", features = {
                { id = "monje_cer_competencia", level = 3, name = "Competencia adicional (cervecero)", type = "pasivo", description = "Competencia con herramientas de cervecero (bonus de competencia duplicado en sus pruebas).", effects = {
                    { kind = "toolProf", tool = "Herramientas de cervecero" },
                } },
                { id = "monje_cer_brebajes", level = 3, name = "Cervecero elusivo", type = "informativo", description = "Conoces brebajes (Buey Negro + uno a elegir; mas a niveles superiores) que gastan chi para diversos efectos.", effects = {} },
                { id = "monje_cer_tambaleo", level = 6, name = "Tambaleo", type = "informativo", description = "Reacción al recibir daño: resistencia a todo el daño del ataque salvo psíquico. 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
                { id = "cervecero_elaboracion_ligera", level = 11, name = "Elaboración Ligera", type = "informativo", description = "A partir del 11º nivel, cuando usas tu acción para beber un brebaje, puedes realizar un golpe desarmado como acción adicional. En el 17º nivel, esto aumenta a dos golpes desarmados.", effects = {} },
                { id = "cervecero_brebajes_elusivos", level = 11, name = "Brebajes Elusivos", type = "informativo", description = "Los brebajes elusivos se presentan en orden alfabético. Si un brebaje requiere un nivel, debes tener ese nivel en esta clase para aprender el brebaje. ***Brebaje del Buey Negro.*** Puedes gastar 1 punto de chi para darte ventaja en el próximo ataque cuerpo a cuerpo que realices dentro de 1 minuto. Puedes realizar un ataque cuerpo a cuerpo como parte de la misma acción. ***Brebaje del Desmayo (Requiere 11º nivel).*** Puedes gastar 3 puntos de chi para obtener los efectos del hechizo *desenfoque* durante 1 minuto. ***Aliento de Fuego (Requiere 6º nivel).*** Puedes gastar 2 puntos de chi para exhalar fuego en un cono de 4,6 metros. Cada criatura en el área debe realizar una tirada de salvación de Destreza, recibiendo daño por fuego igual a tu nivel de Monje + tu modificador de Sabiduría si falla la tirada, o la mitad de daño si tiene éxito.", effects = {} },
                { id = "cervecero_brebaje_fortificante", level = 3, name = "Brebaje Fortificante", type = "informativo", description = "Puedes gastar 1 punto de chi para ganar puntos de golpe temporales iguales a la mitad de tu nivel de Monje + tu modificador de Sabiduría.", effects = {} },
                { id = "cervecero_brebaje_vigorizante", level = 11, name = "Brebaje Vigorizante", type = "informativo", description = "Puedes gastar 4 puntos de chi para obtener los efectos del conjuro *prisa* durante 1 minuto.", effects = {} },
                { id = "cervecero_brebaje_de_piel_de_hierro", level = 6, name = "Brebaje de Piel de Hierro", type = "informativo", description = "Puedes gastar 2 puntos de chi para ganar resistencia al daño contundente, perforante y cortante infligido por ataques no mágicos durante 1 minuto.", effects = {} },
                { id = "cervecero_brebaje_agil", level = 11, name = "Brebaje Agil", type = "informativo", description = "Puedes gastar 3 puntos de chi para obtener los efectos del conjuro *libertad de movimiento* durante 1 minuto.", effects = {} },
                { id = "cervecero_brebaje_purificador", level = 17, name = "Brebaje Purificador", type = "informativo", description = "Puedes gastar 5 puntos de chi para lanzar *restauración mayor* sobre ti mismo.", effects = {} },
                { id = "cervecero_te_de_trueno", level = 3, name = "Té de Trueno", type = "informativo", description = "Puedes gastar 1 punto de chi para ganar la fuerza de Xuen. Hasta el final de tu próximo turno, tus ataques cuerpo a cuerpo infligen daño adicional por trueno igual a tu modificador de Sabiduría.", effects = {} },
            } },
            { id = "tejedor", name = "Tejedor de niebla", desc = "Sanacion y apoyo mediante nieblas restauradoras.", features = {
                { id = "monje_tej_niebla_calmante", level = 3, name = "Niebla calmante", type = "recurso", description = "Reserva de chi sanador (= nivel x 10 PG). Acción: rayo a 30 pies que cura; o gasta 5 para curar enfermedad/veneno. Recarga en descanso largo.", effects = {
                    { kind = "resourceMax", resource = "healing_mist", perClassLevel = "monje", base = 0, perLevel = 10 },
                } },
                { id = "monje_tej_palma_chiji", level = 3, name = "Palma de chi-ji", type = "informativo", description = "Al usar Niebla Calmante, golpe desarmado como acción adicional usando tu Mod. Sabiduría al ataque y daño.", effects = {} },
                { id = "monje_tej_caminante", level = 6, name = "Caminante de la niebla", type = "informativo", description = "Acción + 1 punto de chi: te teletransportas 60 pies y puedes usar Niebla Calmante desde la nueva posición.", effects = {} },
                            { id = "tejedor_anillo_de_paz", level = 11, name = "Anillo de Paz", type = "informativo", description = "Al alcanzar el nivel 11, puedes usar tu acción y elegir un número de criaturas dentro de 4,6 metros de ti igual a tu modificador de Sabiduría. Un objetivo debe tener éxito en una tirada de salvación de Sabiduría o quedar incapacitado hasta el final de tu próximo turno o hasta que reciba daño. Puedes usar esta característica un número de veces igual a tu modificador de Sabiduría. Recuperas los usos gastados cuando terminas un descanso prolongado.", effects = {} },
                { id = "tejedor_estatua_del_dragon_de_jade", level = 17, name = "Estatua del Dragón de Jade", type = "informativo", description = "A nivel 17, puedes dar forma física a tu chi, moldeándolo en una estatua de Yu'lon, el Dragón de Jade. Puedes gastar 3 puntos de chi como acción y elegir un espacio vacío a 9,1 metros de ti para manifestar una estatua de jade. La estatua tiene puntos de golpe igual al doble de tu nivel de monje, resistencia a todo el daño e inmunidad al daño psíquico y por veneno. Siempre que uses tu característica de Niebla Calmante, puedes elegir un segundo objetivo dentro de 18,3 metros de la estatua para ser sanado por la mitad de los puntos de golpe que restores. La estatua permanece durante 1 minuto o hasta que sea destruida.", effects = {} },
            } },
            { id = "caminavientos", name = "Viajero del viento", desc = "Daño agil y veloz con golpes encadenados.", features = {
                { id = "monje_cam_golpes_lanza", level = 3, name = "Golpes de mano de lanza", type = "informativo", description = "Al golpear con Puños de Furia, impones un efecto (derribar, empujar 15 pies o impedir reacciones).", effects = {} },
                { id = "monje_cam_reflejos", level = 3, name = "Reflejos del tigre", type = "pasivo", description = "Sumas tu Mod. Sabiduría a la iniciativa.", effects = {
                    { kind = "initiativeAbility", ability = "Sabiduria" },
                } },
                { id = "monje_cam_caminavientos", level = 6, name = "Caminavientos", type = "informativo", description = "Al usar Paso del Viento ganas velocidad de vuelo (mitad de tu velocidad) hasta el final del turno; reduces daño por caida.", effects = {} },
            } },
        },
        features = {
            { id = "monje_defensa_sin_armadura", level = 1, name = "Defensa sin armadura", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Sabiduría.", effects = {
                { kind = "unarmoredDefenseAbility", ability = "Sabiduria" },
            } },
            { id = "monje_artes_marciales", level = 1, name = "Artes marciales", type = "pasivo", description = "Con golpes desarmados y armas de monje: usas Destreza al ataque/daño y el dado marcial mejora el daño cuando supera al dado normal. Requiere no llevar armadura ni escudo.", effects = {
                { kind = "martialArts", classId = "monje", values = { 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8, 10, 10, 10, 10 } },
            } },
            { id = "monje_chi", level = 2, name = "Chi", type = "pasivo", description = "Puntos de chi (= nivel) para Puños de Furia, Danza Elusiva, Paso del Viento y Efusion. CD de Chi = 8 + comp + Mod. Sabiduría. Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "chi", perClassLevel = "monje", perLevel = 1 },
            } },
            { id = "monje_rodar", level = 2, name = "Rodar", type = "informativo", description = "Sin escudo, una vez por turno ruedas en línea recta gastando movimiento; los ataques de oportunidad contra ti se hacen con desventaja.", effects = {} },
            { id = "monje_tradicion", level = 3, name = "Tradicion monastica", type = "informativo", description = "Eliges tu tradicion (Maestro Cervecero, Tejedor de Niebla o Caminavientos). Concede rasgos en niveles 3, 6, 11 y 17.", effects = {} },
            { id = "monje_serenidad", level = 3, name = "Serenidad", type = "informativo", description = "Al usar chi entras en postura serena 1 minuto: usas tu Mod. Sabiduría al ataque/daño con armas de monje o golpes desarmados.", effects = {} },
            ASI("monje", 4),
            { id = "monje_ataque_adicional", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "monje_palma_aturdidora", level = 5, name = "Palma aturdidora", type = "accion", resourceKey = "chi", resourceCost = 1, description = "Una vez por turno, al golpear cuerpo a cuerpo, gasta 1 punto de chi: el objetivo con salvación de Constitución o aturdido hasta tu próximo turno.", effects = {} },
            { id = "monje_golpes_empoderados_chi", level = 6, name = "Golpes empoderados por el chi", type = "informativo", description = "Tus golpes desarmados cuentan como magicos para superar resistencias e inmunidades no mágicas.", effects = {} },
                    { id = "monje_evasion", level = 7, name = "Evasión", type = "informativo", description = "En el 7º nivel, tu agilidad instintiva te permite esquivar ciertos efectos de área, como el aliento de escarcha de un dragón azul o el hechizo *bola de fuego*. Cuando te someten a un efecto que te permite realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y recibes la mitad de daño si fallas.", effects = {} },
            { id = "monje_desintoxicacion", level = 7, name = "Desintoxicación", type = "informativo", description = "A partir del 7º nivel, puedes usar tu acción para eliminar una enfermedad o condición de envenenado que te esté afectando.", effects = {} },
            { id = "monje_trascendencia", level = 9, name = "Trascendencia", type = "informativo", description = "Al alcanzar el 9º nivel, puedes concentrar tu chi en una imagen incorpórea de ti mismo a la que podrás trasladarte en el futuro. Puedes usar tu acción y gastar 1 punto de chi para invocar la imagen en tu espacio; la imagen es incorpórea y no se puede interactuar con ella. La imagen permanece durante 1 minuto antes de desaparecer. Mientras estés a 18,3 metros de ella, puedes usar tu acción adicional para trascender el mundo material y teletransportarte al espacio de la imagen. La imagen incorpórea desaparece entonces. En el 18º nivel, tu imagen de jade incorpórea permanece durante 1 hora, y el rango al que puedes trascender a ella se incrementa a 1,6 km.", effects = {} },
            { id = "monje_paz_interior", level = 10, name = "Paz Interior", type = "informativo", description = "A partir del 10º nivel, puedes usar tu acción adicional y gastar 1 punto de chi para finalizar un efecto que te esté causando estar hechizado o asustado.", effects = {} },
            { id = "monje_cuerpo_atemporal", level = 15, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del 15º nivel, tu chi te sostiene de manera que no sufres los efectos de la vejez, y no puedes ser envejecido mágicamente. Aun puedes morir de vejez, sin embargo. Además, ya no necesitas comida ni agua.", effects = {} },
            { id = "monje_zen_perfecto", level = 20, name = "Zen Perfecto", type = "informativo", description = "En el 20º nivel, cuando tires para iniciativa y no tengas puntos de chi restantes, recuperas 4 puntos de chi.", effects = {} },
        },
    },
    {
        id = "paladin", name = "Paladin", desc = "Cruzado sagrado que une fuerza marcial y Luz Sagrada para proteger, castigar y sanar.", hitDie = 10, casterType = "half", startingGold = { dice = 5, sides = 4, multiplier = 10 },
        saves = { "Sabiduria", "Carisma" },
        armorProfs = { "ligera", "media", "pesada", "escudo" },
        weaponProfs = { "sencillas", "marciales" },
        subclasses = {
            { id = "sagrado", name = "Sagrado", desc = "Luz sanadora y apoyo para los aliados.", features = {
                { id = "pal_sag_canalizar", level = 3, name = "Canalizar divinidad (sagrado)", type = "informativo", description = "Opciones: Luz del Amanecer (disipa oscuridad y cura) y Martillo de Luz (estallido de luz, salvación de Constitución).", effects = {} },
                { id = "pal_sag_destello", level = 3, name = "Destello de Luz", type = "informativo", description = "Acción adicional + ranura de conjuro: curas a un objetivo a 20 pies (2d6 por ranura de 1er nivel, +1d6 por nivel superior, max 6d6).", effects = {} },
            } },
            { id = "proteccion", name = "Proteccion", desc = "Guardian acorazado que protege a los suyos.", features = {
                { id = "pal_pro_canalizar", level = 3, name = "Canalizar divinidad (proteccion)", type = "informativo", description = "Opciones: Consagracion (radio 30 pies, daño radiante + PG temporal a aliados) y Escudo Sagrado (desventaja a atacantes; daño al fallar contra ti).", effects = {} },
                { id = "pal_pro_bastion", level = 3, name = "Bastion divino", type = "recurso", description = "Al golpear cuerpo a cuerpo, gasta ranura de conjuro: +2d6 radiante (1er nivel; +1d6 por nivel superior, max 6d6) y el objetivo tiene desventaja en ataques contra otros. No se combina con Golpe del Cruzado (elige solo uno por ataque). Toggle por nivel en 'Daño extra'.", effects = {
                    { kind = "conditionalWeaponDamage", id = "divine_bastion", label = "Bastion Divino", count = 2, die = 6, damageType = "radiante", spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, extraCountOffset = 1, maxCount = 6 },
                } },
            } },
            { id = "represion", name = "Represion", desc = "Castigo sagrado que aniquila al impio.", features = {
                { id = "pal_ret_canalizar", level = 3, name = "Canalizar divinidad (represion)", type = "informativo", description = "Opciones: Veredicto del Templario (ventaja en ataques contra una criatura 1 minuto) y Rechazar lo Profano (apartar demonios/no-muertos).", effects = {} },
                { id = "pal_ret_tormenta", level = 3, name = "Tormenta divina", type = "informativo", description = "Al golpear, gasta ranura de conjuro: daño radiante a la criatura y a todo a 5 pies (salvación de Destreza por mitad). No se combina con Golpe del Cruzado.", effects = {} },
            } },
        },
        features = {
            { id = "pal_sentido_divino", level = 1, name = "Sentido divino", type = "informativo", description = "Acción: detectas celestiales, infernales y no-muertos a 60 pies, y lugares/objetos consagrados o profanados. Usos = 1 + Mod. Carisma.", uses = { base = 1, ability = "Carisma", min = 1, recharge = "long" }, effects = {} },
            { id = "pal_imposicion_manos", level = 1, name = "Imposicion de manos", type = "accion", actionKind = "layOnHands", description = "Reserva de curación igual a tu nivel de paladín x5 PG. Como acción, tocas a una criatura y restauras la cantidad de PG que elijas de la reserva. Recarga en descanso largo.", uses = { base = 0, perClassLevel = "paladin", perLevel = 5, recharge = "long" }, effects = {} },
            { id = "pal_estilo_combate", level = 2, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "guerrero_bendito", label = "Guerrero Bendito (2 trucos de sacerdote, Carisma)", effects = {} },
                    { id = "defensa",          label = "Defensa (+1 CA con armadura)",            effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                    { id = "doble_empuñadura", label = "Doble Empuñadura (+2 daño un arma a una mano)", effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                    { id = "gran_arma",        label = "Gran Arma (repetir 1-2 a dos manos)",     effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                    { id = "proteccion",       label = "Proteccion (desventaja a atacantes, con escudo)", effects = {} },
                },
            } },
            { id = "pal_lanzamiento_conjuros", level = 2, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de paladín usando Carisma (preparas Mod. Carisma + mitad de nivel). CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma.", effects = {} },
            { id = "pal_golpe_cruzado", level = 2, name = "Golpe del cruzado", type = "pasivo", description = "Al golpear cuerpo a cuerpo, gasta ranura de conjuro: +2d8 radiante (1er nivel; +1d8 por nivel superior, max 6d8; +1d8 contra no-muertos/infernales). El toggle suma el daño base de 1er nivel (2d8); los dados extra por ranura superior se añaden manualmente.", effects = {
                { kind = "conditionalWeaponDamage", id = "smite", label = "Golpe del Cruzado", count = 2, die = 8, damageType = "radiante", spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, extraCountOffset = 1, maxCount = 6 },
            } },
            { id = "pal_camino_sagrado", level = 3, name = "Camino sagrado", type = "recurso", description = "Eliges tu camino (de lo Sagrado, de la Protección o de la Represion). Concede rasgos y Canalizar Divinidad (1 uso, recarga en descanso corto o largo) en niveles 3, 7, 15 y 20.", effects = {
                { kind = "resourceMax", resource = "channel_divinity", value = 1 },
            } },
            ASI("paladin", 4),
            { id = "pal_ataque_extra", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "pal_aura_proteccion", level = 6, name = "Aura de proteccion", type = "pasivo", description = "Tu y aliados a 10 pies suman tu Mod. Carisma (mínimo +1) a sus tiradas de salvación mientras estés consciente.", effects = {
                { kind = "allSavesAbility", ability = "Carisma", min = 1 },
            } },
                    { id = "paladin_aura_de_coraje", level = 10, name = "Aura de Coraje", type = "informativo", description = "A partir de nivel 10. ni tú ni las criaturas amistosas a 3 metros o menos de ti podréis ser asustadas mientras permanezcas consciente. A nivel 18 el alcance de esta aura aumenta a 9,1 metros.", effects = {} },
            { id = "paladin_toque_purificador", level = 14, name = "Toque Purificador", type = "informativo", description = "A partir de nivel 14, puedes utilizar tu acción para finalizar un conjuro que te esté afectando a ti o a una criatura voluntaria a la que toques. Puedes emplear este rasgo tantas veces como tu modificador por Carisma (mínimo una vez). Recuperas todos los usos tras finalizar un descanso largo.", effects = {} },
        },
    },
    {
        id = "sacerdote", name = "Sacerdote", desc = "Servidor devoto que canaliza la fe para sanar, proteger o castigar con poder sagrado y sombrio.", hitDie = 6, casterType = "full", startingGold = { dice = 4, sides = 4, multiplier = 10 },
        saves = { "Sabiduria", "Carisma" },
        armorProfs = {},
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "disciplina", name = "Disciplina", desc = "Escudos y prevencion que sanan mitigando el daño.", features = {
                { id = "sac_dis_truco", level = 1, name = "Truco de bonificacion", type = "informativo", description = "Aprendes un truco adicional de sacerdote; no cuenta en tu limite.", effects = {} },
                { id = "sac_dis_supresion", level = 6, name = "Supresion del dolor", type = "informativo", description = "Acción adicional: barrera invisible a un aliado a 60 pies que reduce daño fisico en 2 + tu bonus de competencia durante 1 minuto.", effects = {} },
                            { id = "disciplina_absolucion_penitencia", level = 2, name = "Absolución: Penitencia", type = "informativo", description = "A partir del 2º nivel, puedes usar tu Absolución para liberar una expansión de radiancia o fuerza necrótica. Puedes gastar hasta cinco puntos de fe como acción y lanzar una ráfaga de penitencia hacia un objetivo que puedas ver en un radio de 18,3 metros. Al hacerlo, eliges si deseas encomendar o condenar a ese objetivo. ***Encomendar.*** El objetivo recupera puntos de golpe iguales a 2 + 1d6 por cada punto de fe gastado. Si esto restaura a la criatura a su máximo de puntos de golpe, gana puntos de golpe temporales iguales al número de puntos de golpe que queden en la reserva. ***Condenar.*** El objetivo recibe daño radiante o necrótico (a tu elección) igual a 1d10 por cada punto de fe gastado, y debe superar una tirada de salvación de Sabiduría o quedar asustado de ti hasta el final de tu siguiente turno.", effects = {} },
                { id = "disciplina_castigo", level = 14, name = "Castigo", type = "informativo", description = "A partir del 14º nivel, cuando lanzas un conjuro que causa daño, elige una criatura dañada por ese conjuro en el turno en que lo lanzaste. Esa criatura recibe daño radiante o necrótico adicional (a tu elección) igual a la mitad de tu nivel de sacerdote. Esta característica solo puede usarse una vez por lanzamiento de un conjuro.", effects = {} },
                { id = "disciplina_claridad_de_voluntad", level = 20, name = "Claridad de Voluntad", type = "informativo", description = "En el nivel 20, eres capaz de aprovechar tu voluntad enfocada, mejorando tu Supresión del Dolor. Tu barrera de supresión ahora reduce todo el daño recibido. Mientras una criatura esté bajo el efecto de tu barrera de supresión, también tiene ventaja en las tiradas de salvación para evitar ser encantada o asustada.", effects = {} },
            } },
            { id = "sagrado", name = "Sagrado", desc = "Sanacion pura y restauradora con la Luz.", features = {
                { id = "sac_sag_competencia", level = 1, name = "Competencia adicional (religion)", type = "pasivo", description = "Pericia en Religión (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Religion" },
                } },
                { id = "sac_sag_himno", level = 1, name = "Himno divino", type = "informativo", description = "Acción: curación (= nivel x5 PG) repartida entre criaturas a 30 pies (no por encima de la mitad de su maximo). 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "sac_sag_oracion", level = 6, name = "Oracion de curacion", type = "accion", resourceKey = "light_point", resourceCost = 1, description = "Gasta 1 punto de fe para volver a tirar dados de curación (tuya o de un aliado a 5 pies). 1 vez por turno.", effects = {} },
            } },
            { id = "sombra", name = "Sombra", desc = "Magia de la mente y energía sombria para destruir.", features = {
                { id = "sac_som_voz", level = 1, name = "Voz psiquica", type = "informativo", description = "Telepatia con cualquier criatura visible a 30 pies (no necesitais compartir idioma, pero debe entender alguno).", effects = {} },
                { id = "sac_som_legado", level = 1, name = "Legado del Vacio", type = "informativo", description = "Al dañar con un truco, daño psíquico extra = Mod. Carisma (con salvación de Sabiduría para seguir usandolo).", effects = {} },
                { id = "sac_som_forma", level = 6, name = "Forma de Sombra", type = "informativo", description = "Acción adicional 1 minuto: si vas sin armadura sumas Mod. Carisma a la CA; daño necrótico a quien te golpee; tus conjuros ignoran resistencia necrótica/psiquica. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                            { id = "sombra_mente_dominante", level = 14, name = "Mente Dominante", type = "informativo", description = "Al alcanzar el nivel 14, puedes usar tu voz telepática para dominar las mentes de otros. Como acción, puedes gastar 6 puntos de fe para lanzar *dominar bestia* o *dominar persona* sobre una criatura a 9,1 metros de ti. Además, tienes ventaja en las tiradas de salvación contra ser encantado.", effects = {} },
                { id = "sombra_rendicion_a_la_locura", level = 20, name = "Rendición a la Locura", type = "informativo", description = "En el nivel 20, puedes abrazar los susurros locos del vacío y dejar que sus poderes fluyan a través de ti. Cuando usas tu acción adicional para cubrirte con tu forma de sombra, o como acción adicional mientras está activa, puedes someterte al vacío durante la duración de la forma de sombra y obtener los siguientes beneficios: - Cuando normalmente lanzarías uno o más dados de daño por un conjuro de sacerdote de nivel 5 o inferior, en su lugar usas el número más alto posible para cada dado. - Puedes usar tu reacción cuando una criatura que puedes ver te ataca o lanza un conjuro contra ti, perforando su mente con los murmullos de los Dioses Antiguos. La criatura debe superar una tirada de salvación de Sabiduría contra tu CD de conjuros o quedar incapacitada hasta el comienzo de tu próximo turno.", effects = {} },
            } },
            { id = "elune", name = "Sacerdocio de Elune", desc = "Especializacion exclusiva de elfos de la noche: devoción a la Madre Luna y disciplina marcial de las centinelas.", requiredRace = "elfo_noche", features = {
                { id = "sac_elu_canalizar_divinidad", level = 1, name = "Canalizar divinidad", type = "pasivo", icon = "Interface\\Icons\\Spell_Holy_LightsGrace", requiredRace = "elfo_noche", description = "Tu devoción a Elune te permite canalizar energía divina para alimentar sus dones. Dispones de 1 uso de Canalizar Divinidad y recuperas todos los usos al terminar un descanso corto o largo.", effects = {
                    { kind = "resourceMax", resource = "channel_divinity", value = 1 },
                } },
                { id = "sac_elu_gracia", level = 1, name = "Gracia de Elune", type = "accion", icon = "Interface\\Icons\\Spell_Holy_ElunesGrace", requiredRace = "elfo_noche", actionKind = "elunesGrace", description = "Como acción adicional, gastas Canalizar Divinidad para envolver a una criatura que veas a 30 pies en el abrazo protector de Elune. Durante 1 minuto, o hasta que quedes incapacitado o mueras, puede realizar Destrabarse, Esquivar u Ocultarse como acción adicional. Si te eliges a ti, puedes realizar una de esas acciones al activar la gracia.", effects = {} },
                { id = "sac_elu_conjuros", level = 1, name = "Conjuros del sacerdocio de Elune", type = "pasivo", requiredRace = "elfo_noche", description = "Hasta nivel 6, estos conjuros están siempre preparados y no cuentan contra tu limite: nivel 1 Encontrar familiar y Marca del cazador; nivel 2 Rayo de luna y Oleada estelar; nivel 3 Señal de esperanza y Explosión lunar; nivel 4 Destierro e Invisibilidad mayor.", spellGrants = {
                    { level = 1, ids = { "encontrar_familiar", "marca_del_cazador" } },
                    { level = 2, ids = { "rayo_de_luna", "oleada_estelar" } },
                    { level = 3, ids = { "senal_de_esperanza", "explosion_lunar" } },
                    { level = 4, ids = { "destierro", "invisibilidad_mayor" } },
                }, effects = {} },
                { id = "sac_elu_entrenamiento_centinela", level = 3, name = "Entrenamiento de centinela", type = "pasivo", icon = "Interface\\Icons\\eps_wc3h_ceremoniallocketelune", requiredRace = "elfo_noche", description = "Tu instruccion con las centinelas te concede competencia con armadura ligera y media. También aprendes Golpe Lunar: cuenta como truco de sacerdote, pero no contra tu limite de trucos conocidos.", cantripSpellIds = { "golpe_lunar" }, effects = {
                    { kind = "armorProf", armor = "ligera" },
                    { kind = "armorProf", armor = "media" },
                } },
                { id = "sac_elu_furia", level = 3, name = "Furia de Elune", type = "accion", icon = "Interface\\Icons\\eps_wc3_darkelune", requiredRace = "elfo_noche", actionKind = "furyOfElune", description = "Cuando usas tu acción para lanzar un truco de sacerdote, puedes realizar un ataque con arma como acción adicional. Puedes usar esta característica un numero de veces igual a tu modificador de Carisma, mínimo una, y recuperas todos los usos con un descanso corto o largo.", uses = { base = 0, ability = "Carisma", min = 1, recharge = "short" }, effects = {} },
                { id = "sac_elu_asalto_luz_lunar", level = 6, name = "Asalto de Luz lunar", type = "pasivo", icon = "Interface\\Icons\\Spell_Holy_ChampionsBond", requiredRace = "elfo_noche", description = "Cuando realizas la acción de Atacar en tu turno, puedes realizar un ataque adicional como parte de esa acción.", effects = {
                    { kind = "flag", flag = "extraAttack" },
                } },
            } },
        },
        features = {
            { id = "sac_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de sacerdote usando Carisma (preparas Mod. Carisma + nivel). CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma. Foco: símbolo sagrado.", effects = {} },
            { id = "sac_llamado_divino", level = 1, name = "Llamado divino", type = "informativo", description = "Eliges tu llamado (Disciplina, Sagrado o Sombra) a nivel 1. Concede rasgos en niveles 1, 6, 14 y 20.", effects = {} },
            { id = "sac_ecos_fe", level = 2, name = "Ecos de fe", type = "recurso", description = "Puntos de fe (= nivel) para Devoción (convertir puntos en ranuras de conjuro y viceversa). Recargan en descanso largo.", effects = {
                { kind = "resourceMax", resource = "light_point", perClassLevel = "sacerdote", perLevel = 1 },
            } },
            -- Absolucion es una categoria de reglas: sus opciones se muestran como
            -- habilidades independientes, no como una tarjeta clicable del Libro.
            { id = "sac_absolucion", level = 3, name = "Absolucion", type = "informativo", bookHidden = true, description = "Canalizas tu fe en absoluciones (empiezas con Encadenar No-muertos + una de tu llamado). CD = tu CD de conjuros.", effects = {} },
            { id = "sac_encadenar_no_muertos", level = 3, name = "Encadenar no muertos", type = "accion", actionKind = "absolution", spellId = "encadenar_no_muertos", description = "Elige un no muerto a 18 metros. Debe superar una salvación de Sabiduría o queda aturdido hasta 1 minuto o hasta recibir daño; repite la salvación al final de cada turno.", effects = {} },
            { id = "sac_palabra_poder", level = 3, name = "Palabra de poder", type = "choice", actionKind = "powerWord", description = "Elige una Palabra de Poder. A nivel 10 y 17 obtendras elecciones adicionales.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "barrera", label = "Barrera", icon = "spell_holy_powerwordshield", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, desc = "Reacción: cuando una criatura a 30 pies recibe el impacto de una tirada de ataque, gastas 1 punto de fe para forzar al atacante a repetir esa tirada. Harford anuncia y descuenta el uso; la repeticion se resuelve manualmente en mesa." },
                    { id = "llamada", label = "Llamada", icon = "inv_shoulder_robe_raidpriest_k_01", cast = "reaccion", resourceKey = "light_point", resourceCost = 2, desc = "Puedes usar tu reacción y gastar 2 puntos de fe cuando una criatura aliada dentro de 60 pies de ti se ve obligada a hacer una tirada de salvación para evitar un efecto de área o cae. La criatura es arrastrada a un espacio vacío a 5 pies de ti y no sufre efectos del área si Llamada la saco de la zona ni recibe daño por caer." },
                    { id = "castigo", label = "Castigo", icon = "spell_shadow_mindshear", cast = "accion", resourceKey = "light_point", resourceCost = 2, saveAbility = "Sabiduria", conditionId = "incapacitated", conditionDuration = "target_turn_end", desc = "Acción: una criatura a 30 pies hace una salvación de Sabiduría contra tu CD de conjuro. Si falla, queda incapacitada hasta el final de su siguiente turno." },
                    { id = "muerte", label = "Muerte", icon = "spell_shadow_demonicfortitude", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, desc = "Cuando infliges daño con un conjuro de sacerdote, puedes volver a tirar tantos dados de daño como tu modificador de Carisma (mínimo uno), usando los nuevos resultados." },
                    { id = "fortaleza", label = "Fortaleza", icon = "spell_priest_angelicbulwark", cast = "reaccion", resourceKey = "light_point", resourceCost = 2, conditionId = "palabra_fortaleza", conditionDuration = "target_turn_end", desc = "Reacción: cuando se realiza una salvación, eliges hasta tu modificador de Carisma (mínimo una) criaturas a 30 pies. Tienen ventaja en esa salvación. Marca manualmente a cada criatura elegida antes de resolverla." },
                    { id = "resplandor", label = "Resplandor", icon = "spell_holy_searinglight", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, saveAbility = "Sabiduria", conditionId = "frightened", conditionDuration = "target_turn_end", desc = "Reacción: cuando una criatura te golpea con un ataque cuerpo a cuerpo, debe superar una salvación de Sabiduría contra tu CD de conjuro o quedar asustada hasta el final de su siguiente turno." },
                    { id = "dolor", label = "Dolor", icon = "spell_shadow_shadowwordpain", cast = "accion", resourceKey = "light_point", resourceCost = 1, saveAbility = "Constitucion", conditionId = "palabra_dolor", conditionDuration = "target_turn_end", desc = "Acción: una criatura a 60 pies hace una salvación de Constitución contra tu CD de conjuro. Si falla, tiene desventaja en todas sus tiradas de ataque hasta el final de su siguiente turno." },
                    { id = "escudo", label = "Escudo", icon = "spell_holy_powerwordshield", cast = "accion_adicional", resourceKey = "light_point", resourceCost = 2, desc = "Acción adicional: una criatura gana PG temporales iguales a la mitad de tu nivel de sacerdote + tu modificador de Carisma." },
                    { id = "consuelo", label = "Consuelo", icon = "spell_holy_prayerofmendingtga", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, desc = "Cuando restauras PG con un conjuro de nivel 1 o superior, puedes restaurar PG adicionales iguales a tu modificador de Carisma a una criatura afectada." },
                },
            } },
            ASI("sacerdote", 4),
            { id = "sac_restauracion_fieles", level = 5, name = "Restauracion de los fieles", type = "informativo", description = "Recuperas 2 puntos de fe al terminar un descanso corto (3 a nivel 10, 4 a nivel 17).", effects = {} },
        },
    },
    {
        id = "picaro", name = "Picaro", desc = "Maestro del sigilo, las trampas y el ataque furtivo que prospera con astucia y precision.", hitDie = 8, startingGold = { dice = 4, sides = 4, multiplier = 10 },
        saves = { "Destreza", "Inteligencia" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas", "ballestas de mano", "espadas largas", "floretes", "espadas cortas" },
        subclasses = {
            { id = "asesino", name = "Asesinato", desc = "Golpes letales, venenos y muerte desde las sombras.", features = {
                { id = "pic_ase_competencia", level = 3, name = "Competencia adicional (envenenador)", type = "pasivo", description = "Competencia con el equipo de envenenador.", effects = {
                    { kind = "toolProf", tool = "Equipo de envenenador" },
                } },
                { id = "pic_ase_intuicion", level = 3, name = "Intuicion del asesino", type = "pasivo", description = "Ventaja en ataques contra criaturas que aun no han actuado; tu primer impacto del combate inflige daño extra = tu nivel de picaro.", effects = {
                    { kind = "conditionalWeaponDamage", id = "assassin_intuition", label = "Intuicion del Asesino", flatBonus = "level", flatClassId = "picaro" },
                } },
            } },
            { id = "forajido", name = "Forajido", desc = "Combate audaz con armas de fuego y trucos sucios.", features = {
                { id = "pic_for_competencia", level = 3, name = "Competencia con armas de fuego", icon = "ability_rogue_pistolshot", type = "pasivo", description = "Obtienes competencia con pistolas y rifles.", effects = WeaponProfEffects("pistolas", "rifles") },
                { id = "pic_for_alacridad", level = 3, name = "Alacridad", type = "pasivo", description = "Sumas tu Mod. Carisma a la iniciativa; al atacar cuerpo a cuerpo, ese objetivo no puede hacerte ataques de oportunidad el resto del turno.", effects = {
                    { kind = "initiativeAbility", ability = "Carisma" },
                } },
            } },
            { id = "sutileza", name = "Sutileza", desc = "Sigilo extremo y ataques furtivos precisos.", features = {
                { id = "pic_sut_conjuracion", level = 3, name = "Conjuracion", type = "informativo", description = "Aprendes magia de sombras (trucos + hechizos). Inteligencia es tu habilidad de conjuro: CD = 8 + comp + Mod. Inteligencia.", effects = {} },
                { id = "pic_sut_vista", level = 3, name = "Vista de penumbra", type = "informativo", description = "Visión en la oscuridad 60 pies (o +30 si ya la tienes por raza).", effects = {} },
            } },
        },
        features = {
            { id = "pic_pericia", level = 1, name = "Pericia", type = "choice", description = "Elige 2 competencias para duplicar su bonus de competencia.", effects = {}, choice = {
                slots = 2, optionsFrom = "skillExpertise",
            } },
            { id = "pic_ataque_furtivo", level = 1, name = "Ataque furtivo", type = "pasivo", description = "Una vez por turno, +1d6 de daño (sube con nivel) a una criatura si tienes ventaja o un aliado adyacente, con arma ligera/precision/distancia.", effects = {
                { kind = "conditionalWeaponDamage", id = "sneak", label = "Ataque Furtivo", die = 6, perTwoClassLevels = "picaro" },
            } },
            { id = "pic_misivas", level = 1, name = "Misivas secretas", type = "informativo", description = "Ocultas mensajes e ideas en conversaciones y cartas mediante jerga y códigos.", effects = {} },
            { id = "pic_energia", level = 2, name = "Energia", type = "pasivo", description = "Puntos de energía (según la tabla) para maniobras (Mutilar, Exponer Armadura, Garrote). CD de Energía = 8 + comp + Mod. Destreza. Recargan en descanso.", effects = {
                { kind = "resourceMax", resource = "energy", perClassLevel = "picaro",
                  values = { 0, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
            } },
            { id = "pic_mutilar", level = 2, name = "Mutilar", type = "maniobra", description = "Tras impactar a una criatura con la acción de Ataque, gastas 1 punto de energía: el objetivo supera una salvación de Fuerza (CD de Energía) o queda derribado.", effects = {
                { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Fuerza", outcome = "Derribado", dcAbility = "Destreza", onFailAura = 267937, conditionId = "prone" },
            } },
            { id = "pic_exponer_armadura", level = 2, name = "Exponer armadura", type = "maniobra", description = "Acción: gastas 1 punto de energía y haces un ataque especial con arma. Si aciertas, infliges daño normal y expones fallos en su defensa: cada otra criatura tiene ventaja en su primera tirada de ataque con arma contra el objetivo antes del final de tu siguiente turno.", effects = {
                { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, onHitAura = 11971, conditionId = "exposed_armor", conditionDuration = "source_turn_end", conditionTurns = 2 },
            } },
            { id = "pic_garrote", level = 2, name = "Garrote", type = "maniobra", description = "Tras impactar a una criatura con un ataque cuerpo a cuerpo, gastas 1 punto de energía: el objetivo supera una salvación de Constitución (CD de Energía) o no puede hablar hasta el final de tu siguiente turno.", effects = {
                { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Constitucion", outcome = "Silenciado", dcAbility = "Destreza", onFailAura = 30900, conditionId = "silenced", conditionDuration = "source_turn_end", conditionTurns = 2 },
            } },
            { id = "pic_accion_astuta", level = 2, name = "Accion astuta", type = "informativo", description = "Acción adicional cada turno solo para Correr, Desengancharse o Esconderse.", effects = {} },
            { id = "pic_arquetipo", level = 3, name = "Arquetipo de Picaro", type = "informativo", description = "Eliges tu arquetipo (Asesino, Forajido o Sutileza). Concede rasgos en niveles 3, 9, 13 y 17.", effects = {} },
            ASI("picaro", 4),
            { id = "pic_esquiva_sobrenatural", level = 5, name = "Esquiva sobrenatural", type = "informativo", cast = "reaccion", reactionTrigger = "damage_taken", reactionEffect = "half_damage", description = "Reacción al recibir un ataque de un atacante visible: reduces el daño a la mitad.", effects = {} },
            { id = "pic_pericia_2", level = 6, name = "Pericia (mejora)", type = "choice", description = "Elige 2 competencias mas para duplicar su bonus de competencia.", effects = {}, choice = {
                slots = 2, optionsFrom = "skillExpertise",
            } },
                    { id = "picaro_evasion", level = 7, name = "Evasión", type = "informativo", description = "A nivel 7 tu agilidad instintiva te da opción de evitar ciertos efectos de área, como el aliento de relámpago de un dragón o un conjuro de _bolá de fuego._ Cua ndo seas víctima de un efecto que te permita hacer una tirada de salvación de Destreza para recibir solo la mitad del daño, no recibirás daño alguno si tienes éxito en la tirada de salvación y solo la mitad si la fallas.", effects = {} },
            { id = "picaro_anticipacion", level = 15, name = "Anticipación", type = "informativo", description = "A nivel 15 has adquirido una fortaleza mental considerable. Ganas competencia en las tiradas de salvación de Sabiduría.", effects = {} },
            { id = "picaro_esquivo", level = 18, name = "Esquivo", type = "informativo", description = "A partir de nivel 18, eres tan escurrid izo que será raro que un atacante pueda tomar el control de la situación. Ninguna tirada de ataque hecha contra ti tendrá ventaja mientras no estés incapacitado.", effects = {} },
            { id = "picaro_golpe_de_suerte", level = 20, name = "Golpe de Suerte", type = "informativo", description = "A nivel 20 h as desarrollado una capacidad asombrosa para tener éxito justo c uando lo necesitas. Si fallas al atacar a un objetivo dentro del alcance, puedes transformar el fa llo en un impacto. También puedes emplear este rasgo para, si fallas al hacer una prueba de caracte rística, considerar el resultado de la tirada del d20 como un 20. Una vez utilizado este rasgo, deberás terminar un descanso corto o largo para poder volver a usarlo otra vez.", effects = {} },
        },
    },
    {
        id = "chaman", name = "Chaman", desc = "Mediador de los elementos y los espíritus ancestrales; desata furia elemental, potencia armas o restaura con totems.", hitDie = 8, casterType = "full", startingGold = { dice = 5, sides = 4, multiplier = 10 },
        saves = { "Fuerza", "Sabiduria" },
        armorProfs = { "ligera", "media", "escudo" },
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "elemental", name = "Elemental", desc = "Desata rayos, fuego y tierra contra el enemigo a distancia.", features = {
                { id = "cha_ele_poder", level = 3, name = "Poder totemico: Mente tranquila", type = "informativo", description = "Tu tótem da ventaja en salvaciones de Constitución para concentración a criaturas a 15 pies.", effects = {} },
                { id = "cha_ele_furia", level = 3, name = "Furia elemental", type = "informativo", description = "Al lanzar un conjuro de daño elemental (acido/frío/fuego/rayo/trueno) puedes cambiar su tipo por otro de la lista.", effects = {} },
                { id = "cha_ele_eco", level = 6, name = "Eco de los elementos", type = "informativo", description = "Al lanzar un conjuro de daño, repite hasta Mod. Sabiduría dados y usa el resultado que quieras. Usos = Mod. Sabiduría por descanso largo.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
            } },
            { id = "mejora", name = "Mejora", desc = "Imbuye sus armas con los elementos para el cuerpo a cuerpo.", features = {
                { id = "cha_mej_poder", level = 3, name = "Poder totemico: Furia del viento", type = "informativo", description = "Tu tótem permite repetir un ataque cuerpo a cuerpo fallado a una criatura a 15 pies.", effects = {} },
                { id = "cha_mej_competencia", level = 3, name = "Competencia adicional (armas marciales)", type = "pasivo", description = "Competencia con armas marciales; puedes usar un arma como foco de conjuro. Cuentas como medio lanzador.", effects = WeaponProfEffects("marciales") },
                { id = "cha_mej_torbellino", level = 3, name = "Torbellino", type = "pasivo", description = "Puntos de torbellino (mitad de tu nivel, redondeado hacia arriba) para ataques con armas elementales (Golpe de Roca, Látigo Elemental, etc.). Recargan en descanso corto o largo.", effects = {
                    { kind = "resourceMax", resource = "maelstrom", perClassLevel = "chaman", values = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
                } },
                { id = "cha_mej_ataque_adicional", level = 6, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                    { kind = "flag", flag = "extraAttack" },
                } },
            } },
            { id = "restauracion", name = "Restauracion", desc = "Sanacion y apoyo mediante totems y aguas curativas.", features = {
                { id = "cha_res_poder", level = 3, name = "Poder totemico: Marea viva", type = "informativo", description = "Cuando una criatura a 15 pies del tótem cura, el tótem cura a otra criatura a 15 pies (= Mod. Sabiduría).", effects = {} },
                { id = "cha_res_guia", level = 3, name = "Guia ancestral", type = "informativo", description = "Al curar con un conjuro de 1er nivel o superior y sacar 1 o 2 en un dado, repites el dado (usas el nuevo resultado).", effects = {} },
                { id = "cha_res_fuerzas", level = 6, name = "Fuerzas anuladoras", type = "informativo", description = "Al lanzar un conjuro sobre un aliado, intentas terminar un efecto de conjuro que lo afecte (según nivel de ranura). 2 usos por descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
            } },
        },
        features = {
            { id = "cha_kalimag", level = 1, name = "Kalimag", type = "informativo", description = "Conoces Kalimag, el idioma de los elementales; dejas mensajes en rocas y agua como el conjuro mensaje.", effects = {} },
            { id = "cha_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de chaman usando Sabiduría. CD = 8 + comp + Mod. Sabiduría; ataque = comp + Mod. Sabiduría. Foco druidico.", effects = {} },
            { id = "cha_totemista", level = 2, name = "Totemista", type = "recurso", description = "Acción adicional: invocas un tótem (CA 15, PG = 2x nivel) con poderes (Resistencia Elemental + el de tu afinidad). 2 usos por descanso corto o largo (3 a nivel 10, 4 a nivel 18).", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "cha_afinidad_elemental", level = 2, name = "Afinidad elemental", type = "choice", description = "Te sintonizas con un elemento.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "aire",  label = "Aire (+5 velocidad, +comp a iniciativa)", effects = { { kind = "flag", flag = "initiativeProfBonus" } } },
                    { id = "tierra", label = "Tierra (competencia en salvacion de Constitucion)", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                    { id = "fuego", label = "Fuego (+comp de daño por fuego, 1/turno)", effects = { { kind = "conditionalWeaponDamage", id = "shaman_fire_affinity", label = "Afinidad Fuego", flatBonus = "pb", damageType = "fuego" } } },
                    { id = "agua",  label = "Agua (conjuros conocidos extra)",          effects = {} },
                },
            } },
            { id = "cha_vinculo", level = 3, name = "Vinculo chamanico", type = "informativo", description = "Eliges tu vínculo (Elemental, Mejora o Restauración). Concede rasgos en niveles 3, 6, 14 y 20.", effects = {} },
            ASI("chaman", 4),
            { id = "cha_bestia_espiritual", level = 5, name = "Bestia espiritual", type = "informativo", description = "Acción: asumes la apariencia ilusoria de tu bestia espiritual (velocidad 50 pies). Termina al lanzar conjuro, atacar o como acción adicional.", effects = {} },
        },
    },
    {
        id = "brujo", name = "Brujo", desc = "Invocador que pacta con entidades oscuras para lanzar maldiciones, dominar demonios y desatar fuego vil.", hitDie = 8, casterType = "full", startingGold = { dice = 4, sides = 4, multiplier = 10 },
        saves = { "Constitucion", "Inteligencia" },
        armorProfs = {},
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "afliccion", name = "Afliccion", desc = "Maldiciones y enfermedades que consumen poco a poco.", features = {
                { id = "bru_afl_lista", level = 2, name = "Lista ampliada de conjuros (afliccion)", type = "informativo", description = "Añade conjuros de sombra/tormento a tu lista de brujo.", effects = {} },
                { id = "bru_afl_corrupcion", level = 2, name = "Corrupcion", type = "informativo", description = "Lanzas Maldiciones (aprendes una; mas a niveles superiores) que puedes amplificar gastando un fragmento de alma. CD = tu CD de conjuros.", effects = {} },
                { id = "bru_afl_acechar", level = 2, name = "Acechar", type = "informativo", description = "Reacción: una criatura a 60 pies con salvación de Sabiduría o falla su prueba de habilidad (mente nublada).", effects = {} },
                { id = "bru_afl_maestro_maldiciones", level = 6, name = "Maestro de maldiciones", type = "informativo", description = "Aprendes conceder maldicion y quitar maldicion (no cuentan); puedes apuntar a dos criaturas en lugar de una.", effects = {} },
                { id = "afliccion_drenar_alma", level = 10, name = "Drenar Alma", type = "informativo", description = "*Característica de Estudio de la Aflicción de nivel 10* Cuando inflijas daño psíquico o necrótico a una criatura, puedes generar un fragmento de alma. Puedes usar esta habilidad tres veces y recuperas todos los usos gastados cuando terminas un descanso prolongado.", effects = {} },
                { id = "afliccion_aflicciones_inestables", level = 14, name = "Aflicciones Inestables", type = "informativo", description = "*Característica de Estudio de la Aflicción de nivel 14* Cuando una criatura tenga éxito en una tirada de salvación contra uno de tus conjuros o habilidades de brujo, recibe daño psíquico igual a la mitad de tu nivel de brujo.", effects = {} },
                { id = "afliccion_aflicciones_potentes", level = 18, name = "Aflicciones Potentes", type = "informativo", description = "*Característica de Estudio de la Aflicción de nivel 18* Elige una de las siguientes opciones. Una vez que uses cualquiera de estas habilidades, no podrás volver a hacerlo hasta que completes un descanso largo. ***Maldición del Destino.*** Aprendes una maldición de destino inminente. Como una acción adicional, colocas la maldición sobre una criatura que puedas ver a 18,3 metros. Al final de cada turno de la criatura, el objetivo recibe 1d4 puntos de daño psíquico. Este daño aumenta en 1 por cada turno después del primero. Después de que el objetivo reciba daño de esta maldición seis veces, o cuando la criatura muera, aparece un guardia apocalíptico a 1,5 metros del objetivo maldito, o en el espacio disponible más cercano.", effects = {} },
                { id = "afliccion_maldiciones", level = 5, name = "Maldiciones", type = "informativo", description = "Las maldiciones se presentan en orden alfabético. Maldición de la Agonía Como acción adicional, maldices a una criatura que puedes ver a 9,1 metros, infligiendo 1d4 puntos de daño psíquico. Durante cada uno de tus turnos durante el próximo minuto, puedes usar tu acción adicional para infligir 1d4 de daño psíquico a la criatura. Este daño aumenta con el nivel: 2d4 a nivel 5, 3d4 a nivel 11 y 4d4 a nivel 17. La criatura puede intentar una salvación de Sabiduría al inicio de su turno, terminando el efecto en caso de éxito. ***Ampliar.*** Cuando el objetivo reciba daño por la Maldición, tiene desventaja en la próxima tirada de ataque que haga antes del final de su próximo turno. Maldición de los Elementos Cuando una criatura que puedes ver a 9,1 metros sea golpeada por un ataque o conjuro, puedes usar tu reacción para debilitar temporalmente su resistencia al mismo.", effects = {} },
            } },
            { id = "demonologia", name = "Demonologia", desc = "Dominio e invocacion de demonios al servicio del brujo.", features = {
                { id = "bru_dem_lista", level = 2, name = "Lista ampliada de conjuros (demonologia)", type = "informativo", description = "Añade conjuros de invocacion/protección demoniaca a tu lista de brujo.", effects = {} },
                { id = "bru_dem_conducto", level = 2, name = "Conducto de almas", type = "informativo", description = "Telepatia con tu esbirro demoniaco; puedes ver/oir por sus sentidos y entregar conjuros de toque a través de el.", effects = {} },
                { id = "bru_dem_sentir", level = 2, name = "Sentir Demonios", type = "informativo", description = "Acción: detectas demonios a 60 pies. Usos = Mod. Inteligencia por descanso largo.", uses = { ability = "Inteligencia", min = 1, recharge = "long" }, effects = {} },
                { id = "bru_dem_vinculo_almas", level = 6, name = "Vinculo de almas", type = "informativo", description = "Con tu demonio a 60 pies, la mitad del daño que recibes se transfiere a el; tu demonio puede generar fragmentos de alma con su reacción.", effects = {} },
                { id = "demonologia_furia_demoniaca", level = 10, name = "Furia Demoníaca", type = "informativo", description = "*Característica de Estudio de Demonología de nivel 10* Obtienes un conjunto de energía que puedes usar para potenciar a tu demonio. Tienes seis puntos que puedes usar para obtener uno de los siguientes efectos, y recuperas los puntos gastados cuando terminas un descanso prolongado: - Cuando ordenes a tu demonio que realice la acción de ataque, puedes gastar un punto para darle ventaja en la tirada de ataque. - Cuando tu demonio sea forzado a realizar una tirada de salvación, puedes gastar un punto como reacción para darle ventaja en la tirada.", effects = {} },
                { id = "demonologia_grimorio_de_supremacia", level = 14, name = "Grimorio de Supremacía", type = "informativo", description = "*Característica de Estudio de Demonología de nivel 14* Puedes recurrir al conocimiento del Grimorio de Supremacía para evolucionar permanentemente a tu minion demoníaco en una forma más poderosa. Gana una serie de beneficios mencionados en su entrada en la Parte I del Apéndice C.", effects = {} },
                { id = "demonologia_somos_legion", level = 18, name = "Somos Legión", type = "informativo", description = "*Característica de Estudio de Demonología de nivel 18* Aplicas las enseñanzas del Grimorio de Supremacía a ti mismo, transformándote permanentemente en un demonio. Puedes ganar dos o más peculiaridades de la tabla de Peculiaridades de la Metamorfosis (o inventar peculiaridades similares) y las siguientes habilidades: - Te brotan alas que te otorgan velocidad de vuelo igual a tu velocidad de movimiento. Puedes ocultar o mostrar estas alas como acción adicional. - Ganas resistencia al daño de fuego y necrótico. - No envejeces, ni necesitas comer, beber o dormir. - Los demonios con una inteligencia de 3 o menos no te atacarán a menos que tú los ataques. Peculiaridades de la Metamorfosis d8|Peculiaridad --|-- 1|Tus ojos se vuelven verdes y brillan en la oscuridad. 2|Tu piel se torna verde o roja. 3|Tus dientes se convierten en colmillos o colmillos y tus uñas se parecen a garras negras.", effects = {} },
            } },
            { id = "destruccion", name = "Destruccion", desc = "Fuego vil explosivo y daño directo abrasador.", features = {
                { id = "bru_des_lista", level = 2, name = "Lista ampliada de conjuros (destruccion)", type = "informativo", description = "Añade conjuros de fuego/destruccion a tu lista de brujo.", effects = {} },
                { id = "bru_des_piromaniaco", level = 2, name = "Piromaniaco", type = "informativo", description = "Aprendes producir llama (no cuenta) y puedes encender objetos inflamables al tocarlos.", effects = {} },
                { id = "bru_des_canalizar", level = 2, name = "Canalizar fuego demoniaco", type = "informativo", description = "Al dañar con un conjuro, puedes recibir hasta tu nivel en fuego para que el objetivo reciba el doble de ese daño por fuego.", effects = {} },
                { id = "bru_des_caos", level = 6, name = "Caos", type = "informativo", description = "Con una ranura de Hechicería Vil de un solo objetivo (no personal), gasta un fragmento de alma para apuntar a una segunda criatura.", effects = {} },
                { id = "destruccion_resolucion_inquebrantable", level = 10, name = "Resolución Inquebrantable", type = "informativo", description = "*Característica de Estudio de la Destrucción de nivel 10* Cuando reduces a una criatura hostil a 0 puntos de golpe, obtienes puntos de golpe temporales igual a tu modificador de Inteligencia + tu nivel de brujo (mínimo de 1).", effects = {} },
                { id = "destruccion_llamas_de_xerrath", level = 14, name = "Llamas de Xerrath", type = "informativo", description = "*Característica de Estudio de la Destrucción de nivel 14* Puedes sobrecargar el poder de tus conjuros con las llamas viles. Cuando inflijas daño con un conjuro de brujo lanzado con una ranura de Hechicería Vil, puedes hacer que el conjuro inflija su daño máximo. La primera vez que lo hagas, no sufres ningún efecto adverso. Si usas esta característica de nuevo antes de completar un descanso prolongado, recibes 5d12 puntos de daño por fuego al final de tu turno actual. Cada vez que uses esta característica de nuevo antes de completar un descanso prolongado, el daño por fuego aumenta en 1d12. Este daño ignora la resistencia e inmunidad.", effects = {} },
                { id = "destruccion_infierno", level = 18, name = "Infierno", type = "informativo", description = "*Característica de Estudio de la Destrucción de nivel 18* Puedes conjurar un meteorito del Vacío Abisal como una acción, haciendo que aparezca en el aire y se estrelle en un punto que designes dentro de 18,3 metros. Las criaturas en un radio de 9,1 metros de ese punto reciben 2d8 puntos de daño contundente y 2d6 puntos de daño por fuego, y el suelo se convierte en terreno difícil. Luego, puedes elegir detonar la piedra, infligiendo 13d10 puntos de daño por fuego a todas las criaturas dentro de 9,1 metros del punto (salvación de Destreza para mitigar a la mitad), o puedes animarla como un infernal. Los infernales se describen en la Parte II del Apéndice C. El infernal se levanta del cráter al final de tu turno, siguiendo tus órdenes (sin requerir acción). Permanece animado durante 1 minuto, o hasta que sea destruido o desechado como una acción adicional.", effects = {} },
            } },
        },
        features = {
            { id = "bru_secretos_profanos", level = 1, name = "Secretos profanos", type = "pasivo", icon = "spell_warlock_demonbolt", description = "Puedes hablar, leer y escribir en Eredun. Tienes ventaja en los chequeos de Inteligencia para recordar información sobre aberraciones, demonios y no muertos. Al interactuar con demonios, aplicas tu bonificador de competencia a los chequeos de Carisma, o el doble si ya eres competente.", effects = {} },
            { id = "bru_hechiceria_vil", level = 1, name = "Hechiceria vil", type = "informativo", description = "Lanzas conjuros de brujo usando Inteligencia; ranuras de un mismo nivel que recargan en descanso corto. CD = 8 + comp + Mod. Inteligencia.", effects = {} },
            { id = "bru_toque_vida", level = 1, name = "Toque de vida", type = "pasivo", icon = "ability_warlock_mortalcoil", description = "Cuando no tienes mana, puedes lanzar un conjuro como si lo tuvieras. Pierdes puntos de golpe iguales a tu nivel total mas el nivel de lanzamiento. Este daño no puede resistirse y no puedes usar este rasgo si te redujera a 0 PG.", effects = {} },
            { id = "bru_estudio_vil", level = 2, name = "Estudio vil", type = "informativo", description = "Eliges tu estudio (Afliccion, Demonologia o Destruccion) a nivel 2. Concede rasgos en niveles 2, 6, 10, 14 y 18.", effects = {} },
            { id = "bru_conocimiento_demoniaco", level = 2, name = "Conocimiento demoniaco", type = "pasivo", icon = "warlock_sacrificial_pact", description = "Puedes invocar un demonio al final de un descanso largo. Solo puedes mantener un demonio invocado o un núcleo demoniaco a la vez.", effects = {} },
            { id = "bru_grimorio_sacrificio", level = 2, name = "Grimorio de sacrificio", type = "pasivo", icon = "warlock_grimoireofsacrifice", description = "Puedes destruir al demonio al invocarlo para obtener su núcleo demoniaco. El núcleo determina sus ventajas en habilidades y el conjuro o truco que puedes lanzar mientras lo sostienes.", effects = {} },
            { id = "bru_nucleo_abisario", level = 2, name = "Nucleo demoniaco: Abisario", type = "pasivo", icon = "spell_shadow_summonvoidwalker", description = "Mientras lleves un núcleo de abisario, tienes ventaja en Perspicacia e Intimidación. Mientras lo sostengas, puedes lanzar Armadura de Agathys. La elección y posesión del núcleo se resuelven en mesa.", effects = {} },
            { id = "bru_fragmentos_alma", level = 3, name = "Fragmentos de alma", type = "pasivo", description = "Cristales de alma (hasta 3; 5 a nivel 9) que gastas para potenciar conjuros (Círculo de Conjuros, Quemar Alma, Ritos de Alma). Los creas en descanso o de criaturas moribundas.", effects = {
                { kind = "resourceMax", resource = "soul_shard", perClassLevel = "brujo", values = { 0, 0, 3, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 } },
            } },
            { id = "bru_capturar_fragmento", level = 3, name = "Capturar fragmento de alma", type = "reaccion", icon = "inv_misc_gem_amethyst_02", description = "Cuando una criatura apropiada muere a 60 pies, puedes usar tu reacción para crear un fragmento de alma. Los humanoides son objetivos validos; la mayoría de no muertos y constructos no lo son.", resourceGain = { key = "soul_shard", amount = 1 }, effects = {} },
            { id = "bru_circulo_demoniaco", level = 3, name = "Circulo demoniaco", type = "accion", icon = "spell_shadow_demoniccircleteleport", description = "Gastas 1 fragmento de alma como acción adicional para crear un círculo de runas de 5 pies durante 1 minuto. Mientras permanezcas en el, tienes ventaja en chequeos de concentración.", resourceKey = "soul_shard", resourceCost = 1, effects = {} },
            { id = "bru_quemar_alma_extender", level = 3, name = "Quemar alma: Extender", type = "accion", icon = "ability_warlock_coil2", description = "Al lanzar un conjuro con duración de 1 hora o mas, gastas 1 fragmento de alma para extender su duración un numero de horas igual a tu nivel de brujo.", resourceKey = "soul_shard", resourceCost = 1, effects = {} },
            { id = "bru_quemar_alma_acelerar", level = 3, name = "Quemar alma: Acelerar", type = "accion", icon = "warlock_spelldrain", description = "Al lanzar un conjuro con tiempo de lanzamiento de 10 minutos o menos, gastas 1 fragmento de alma para lanzarlo como una acción.", resourceKey = "soul_shard", resourceCost = 1, effects = {} },
            { id = "bru_quemar_alma_rebotar", level = 3, name = "Quemar alma: Rebotar", type = "reaccion", icon = "spell_priest_shadoworbs", description = "Cuando un conjuro de objetivo único falla o su objetivo supera la salvación, gastas 1 fragmento de alma para redirigirlo a otro objetivo dentro de su alcance.", resourceKey = "soul_shard", resourceCost = 1, spendResourceOnAnnounce = true, effects = {} },
            { id = "bru_ritos_alma", level = 3, name = "Ritos de alma", type = "accion", icon = "spell_warlock_soulburn", description = "Gastas 1 fragmento de alma para lanzar como ritual un conjuro de brujo con etiqueta de ritual, siempre que dispongas del nivel de lanzamiento necesario. La seleccion del conjuro se confirma en el Compendio.", resourceKey = "soul_shard", resourceCost = 1, effects = {} },
            ASI("brujo", 4),
            { id = "bru_forjado_almas", level = 5, name = "Forjado de almas", type = "informativo", description = "Gastas un fragmento de alma para forjar piedras (Fuego, Salud, Alma, Conjuro). Una de cada tipo a la vez.", effects = {} },
            { id = "brujo_nigromancia_del_vacio_nivel_6", level = 11, name = "Nigromancia del Vacío (Nivel 6)", type = "informativo", description = "*Característica de brujo de nivel 11* Puedes forzarte a lanzar conjuros más poderosos un cierto número de veces por día. Obtienes una ranura de conjuro de nivel 6. Esta ranura puede gastarse para lanzar cualquier conjuro de brujo que conozcas. Recuperas cualquier ranura de conjuros de Nigromancia del Vacío gastada al finalizar un descanso prolongado. Cada vez que obtengas una ranura de conjuro mediante Nigromancia del Vacío, también aprendes un solo conjuro de brujo de un nivel que puedas lanzar. Estos se cuentan por separado de tus conjuros normales, como se muestra en la columna de Conjuros Conocidos de la tabla del Brujo. A niveles superiores. Obtienes más ranuras de conjuro: una ranura de conjuro de nivel 7 a nivel 13, una de nivel 8 a nivel 15 y una de nivel 9 a nivel 17.", effects = {} },
            { id = "brujo_nigromancia_del_vacio_nivel_7", level = 13, name = "Nigromancia del Vacío (Nivel 7)", type = "informativo", description = "Puedes forzarte a lanzar conjuros más poderosos un cierto número de veces por día. Obtienes una ranura de conjuro de nivel 6. Esta ranura puede gastarse para lanzar cualquier conjuro de brujo que conozcas. Recuperas cualquier ranura de conjuros de Nigromancia del Vacío gastada al finalizar un descanso prolongado. Cada vez que obtengas una ranura de conjuro mediante Nigromancia del Vacío, también aprendes un solo conjuro de brujo de un nivel que puedas lanzar. Estos se cuentan por separado de tus conjuros normales, como se muestra en la columna de Conjuros Conocidos de la tabla del Brujo. A niveles superiores. Obtienes más ranuras de conjuro: una ranura de conjuro de nivel 7 a nivel 13, una de nivel 8 a nivel 15 y una de nivel 9 a nivel 17.", effects = {} },
        },
    },
    {
        id = "guerrero", name = "Guerrero", desc = "Maestro de las armas y la armadura, versatil en el combate cuerpo a cuerpo y a distancia, puro musculo y tecnica.", hitDie = 10, startingGold = { dice = 5, sides = 4, multiplier = 10 },
        saves = { "Fuerza", "Constitucion" },
        armorProfs = { "ligera", "media", "pesada", "escudo" },
        weaponProfs = { "sencillas", "marciales", "armas de fuego" },
        subclasses = {
            { id = "armas", name = "Armas", desc = "Maestria tecnica con armas pesadas y golpes precisos.", features = {
                { id = "gue_arm_arrollar", level = 3, name = "Arrollar", type = "informativo", description = "Reacción al recibir un ataque cuerpo a cuerpo: tira 1d10 y sumalo a tu CA; si el ataque falla, puedes atacar al objetivo. 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
                { id = "gue_arm_intrepido", level = 3, name = "Intrepido", type = "informativo", description = "Recuperas 1 punto de Furia al final de tu turno si golpeaste a una criatura con un movimiento de furia ese turno.", effects = {} },
                            { id = "armas_grito_de_mando", level = 7, name = "Grito de Mando", type = "informativo", description = "A partir del nivel 7, puedes comandar a un aliado para que ataque a tu objetivo. Como acción adicional, elige a una criatura aliada a 18,3 metros de ti que pueda verte o escucharte. Esa criatura puede usar su reacción para realizar un ataque cuerpo a cuerpo.", effects = {} },
                { id = "armas_golpe_colosal", level = 11, name = "Golpe Colosal", type = "informativo", description = "Al alcanzar el nivel 11, cuando impactes a una criatura con un ataque cuerpo a cuerpo en tu turno, puedes destruir sus defensas y otorgar ventaja al próximo ataque de arma contra ese objetivo antes del final de tu próximo turno. Solo puedes usar Golpe Colosal una vez en cada turno.", effects = {} },
                { id = "armas_calma_mortal", level = 15, name = "Calma Mortal", type = "informativo", description = "A partir del nivel 15, instintivamente adoptas una postura defensiva en situaciones críticas. Mientras estés por debajo de la mitad de tus puntos de golpe máximos, tienes ventaja en las tiradas de salvación de Fuerza, Destreza o Constitución.", effects = {} },
                { id = "armas_golpes_de_oportunidad", level = 18, name = "Golpes de Oportunidad", type = "informativo", description = "En el nivel 18, respondes con ferocidad a las aperturas en las defensas del enemigo. En combate, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en el tuyo. Solo puedes usar esta reacción para realizar un ataque de oportunidad, y no puedes usarla en el mismo turno en el que uses tu reacción normal.", effects = {} },
            } },
            { id = "furia", name = "Furia", desc = "Berserker de doble empunadura que ataca con ira incontenible.", features = {
                { id = "gue_fur_desatada", level = 3, name = "Furia desatada", type = "informativo", description = "En tu primer ataque del turno puedes desatar tu furia: ventaja en ataques cuerpo a cuerpo con Fuerza ese turno, pero los ataques contra ti tienen ventaja hasta tu próximo turno.", effects = {} },
                { id = "gue_fur_temible", level = 3, name = "Temible", type = "pasivo", description = "Competencia en Intimidación (si no la tienes); puedes usar tu Mod. Fuerza en lugar de Carisma en sus pruebas.", effects = { { kind = "skillProf", skill = "Intimidacion" } } },
                            { id = "furia_furia_focalizada", level = 7, name = "Furia Focalizada", type = "informativo", description = "A partir del nivel 7, tu fuerza bruta te permite manejar armas con una potencia incomparable. Cuando uses un arma que inflige un único dado de daño, el dado de daño se incrementa en 1. Por ejemplo, una espada corta que normalmente inflige 1d6 de daño, en su lugar inflige 1d8 de daño. El dado de daño de un arma no puede incrementarse más allá de 1d12.", effects = {} },
                { id = "furia_sed_de_sangre", level = 11, name = "Sed de Sangre", type = "informativo", description = "Al nivel 11, cuando una criatura hostil a 6,1 metros de ti reciba daño, puedes usar tu reacción para moverte hasta la mitad de tu velocidad hacia ella sin provocar ataques de oportunidad. Si este movimiento te pone al alcance de la criatura, puedes realizar un ataque de arma contra ella como parte de la reacción.", effects = {} },
                { id = "furia_critico_devastador", level = 15, name = "Crítico Devastador", type = "informativo", description = "A partir del nivel 15, cuando consigas un golpe crítico con un ataque de arma, sumas un bono al daño igual a tu nivel en esta clase.", effects = {} },
                { id = "furia_berserker_enloquecido", level = 18, name = "Berserker Enloquecido", type = "informativo", description = "En el nivel 18, si recibes daño que te reduce a 0 puntos de golpe y no te mata de inmediato, puedes usar tu reacción para retrasar la pérdida de consciencia y tomar un turno adicional de inmediato. Mientras tengas 0 puntos de golpe durante ese turno adicional, recibir daño provoca fallos en las tiradas de salvación de muerte como es habitual, y tres fallos pueden matarte. Al terminar el turno adicional, caes inconsciente si aún tienes 0 puntos de golpe. Una vez que uses esta característica, no puedes volver a usarla hasta que completes un descanso largo.", effects = {} },
            } },
            { id = "proteccion", name = "Proteccion", desc = "Tanque con escudo que protege a sus aliados.", features = {
                { id = "gue_pro_provocacion", level = 3, name = "Provocacion", type = "informativo", description = "Acción: las criaturas a 9 m que elijas hacen salvación de Sabiduría (CD de Furia) o tienen desventaja en ataques contra otros durante 1 minuto. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "gue_pro_control", level = 3, name = "Control de ira", type = "informativo", description = "Cuando una criatura hostil te golpea con un ataque, ganas 1 punto de Furia (una vez por turno).", effects = {} },
                            { id = "proteccion_interceptar", level = 7, name = "Interceptar", type = "informativo", description = "A partir del nivel 7, cuando una criatura que puedes ver ataque a un objetivo que no seas tú y que esté a 1,5 metros de ti, puedes usar tu reacción para interceptar el ataque, forzando al atacante a dirigirse a ti en su lugar. Puedes usar esta característica un número de veces igual a tu modificador de Constitución (mínimo de 1). Recuperas todos los usos gastados al completar un descanso largo.", effects = {} },
                { id = "proteccion_golpes_atenuados", level = 11, name = "Golpes Atenuados", type = "informativo", description = "A partir del nivel 11, incluso los golpes más fuertes no quebrarán tu defensa. Todo golpe crítico contra ti se convierte en un golpe normal y tienes ventaja en cualquier prueba o tirada de salvación para evitar ser derribado.", effects = {} },
                { id = "proteccion_presencia_inspiradora", level = 15, name = "Presencia Inspiradora", type = "informativo", description = "A partir del nivel 15, puedes extender el beneficio de tu rasgo Indomable a un aliado. Cuando uses Indomable para repetir una tirada de salvación de Inteligencia, Sabiduría o Carisma y no estés incapacitado, puedes elegir a un aliado a 18,3 metros de ti que también haya fallado la tirada contra el mismo efecto. Si puede verte u oírte, puede repetir su tirada de salvación y debe usar el nuevo resultado.", effects = {} },
                { id = "proteccion_nunca_te_rindas", level = 18, name = "Nunca Te Rindas", type = "informativo", description = "Al nivel 18, siempre que comiences tu turno con menos de la mitad de tus puntos de golpe máximos, ganas 1d10 + tu modificador de Constitución en puntos de golpe temporales. No obtienes este beneficio si tienes 0 puntos de golpe.", effects = {} },
            } },
        },
        features = {
            { id = "guerrero_estilo_combate", level = 1, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad. Elige una opcion.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "defensa",    label = "Defensa (+1 CA con armadura)",          effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                    { id = "duelo",      label = "Duelo (+2 daño un arma a una mano)",    effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                    { id = "gran_arma",  label = "Gran Arma (repetir 1-2 en daño a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                    { id = "proteccion", label = "Proteccion (desventaja a atacantes, con escudo)", effects = {} },
                    { id = "dos_armas",  label = "Combate con Dos Armas (+mod al daño del 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                },
            } },
            { id = "guerrero_segundo_aliento", level = 1, name = "Segundo aliento", type = "accion", description = "Acción adicional: gasta un dado de golpe d10 para recuperar PG (tirada + Mod. Constitución).", actionKind = "secondWind", effects = {} },
            { id = "guerrero_furia_interna", level = 2, name = "Furia interna", type = "pasivo", description = "Ganas puntos de Furia al dañar con armas; los gastas en maniobras (Desarme, Golpe Heroico, Carga). Maximo de Furia = tu nivel de Guerrero. CD Furia = 8 + comp + Mod. Fuerza.", effects = {
                { kind = "resourceMax", resource = "rage", perClassLevel = "guerrero", base = 0, perLevel = 1 },
            } },
            { id = "guerrero_man_golpe_heroico", level = 2, name = "Golpe heroico", type = "recurso", description = "Gasta 1 punto de Furia en una tirada de ataque para infligir daño adicional igual a tu Mod. Fuerza. Activalo en 'Daño extra'.", effects = {
                { kind = "conditionalWeaponDamage", id = "war_golpe_heroico", label = "Golpe Heroico", flatAbility = "Fuerza", resourceCost = "rage", costPerLevel = 1, minLevel = 1, maxLevel = 1 },
            } },
            { id = "guerrero_man_desarme", level = 2, name = "Desarme", type = "recurso", description = "Gasta 2 puntos de Furia en una tirada de ataque; si impacta, daño normal y el objetivo suelta un objeto a tu elección. Activalo en 'Daño extra'.", effects = {
                { kind = "conditionalWeaponDamage", id = "war_desarme", label = "Desarme (suelta objeto)", resourceCost = "rage", costPerLevel = 2, minLevel = 1, maxLevel = 1, onHitAura = 177714, conditionId = "disarmed" },
            } },
            { id = "guerrero_man_carga", level = 2, name = "Carga", type = "maniobra", description = "Gasta 1 punto de Furia para realizar una carga contra el objetivo y resolver un ataque especial con arma.", effects = {
                { kind = "energyManeuver", resource = "rage", cost = 1, spendOnHit = true, attack = true },
            } },
            { id = "guerrero_arquetipo_marcial", level = 3, name = "Arquetipo marcial", type = "informativo", description = "Eliges tu arquetipo (Armas, Furia o Protección). Concede rasgos en niveles 3, 7, 11, 15 y 18.", effects = {} },
            ASI("guerrero", 4),
            { id = "guerrero_ataque_extra", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "guerrero_accion_adicional", level = 6, name = "Accion adicional", type = "accion", description = "Una acción adicional extra en tu turno; recarga con descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "guerrero_ataque_extra_2", level = 20, name = "Ataque adicional (2)", type = "informativo", description = "El número de ataques de tu rasgo de Ataque Extra aumenta a tres cuando alcanzas el nivel 20 en esta clase.", effects = {} },
        },
    },
}

local classById, classOrder

local SUBCLASS_ID_ALIASES = {
    paladin = {
        retribucion = "represion",
        reprension = "represion",
    },
}

local SUBCLASS_TEXT_ALIASES = {
    paladin = {
        retribucion = "represion",
        reprension = "represion",
    },
}

local function Normalize(value)
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))  -- parentesis: gsub devuelve 2 valores
end

local function NormalizeSubclassId(classId, subclassId)
    classId = tostring(classId or "")
    subclassId = tostring(subclassId or "")
    local aliases = SUBCLASS_ID_ALIASES[classId]
    return (aliases and aliases[subclassId]) or subclassId
end

-- Variante en MASCULINO de un texto ya normalizado (sin acentos, minusculas). Sirve para
-- que los nombres en FEMENINO del About TRP3 (Maga, Bruja, Picara, Guerrera, Sacerdotisa,
-- Cazadora, Forajida...) resuelvan a su clase/subclase canonica (masculina). Se usa SOLO
-- como fallback: el texto original se prueba primero, asi no rompe nombres canonicos que
-- acaban en 'a' (Escarcha, Ira, Sutileza, Restauracion...).
local GENDER_ALIAS = {
    sacerdotisa = "sacerdote", cazadora = "cazador", luchadora = "luchador",
    hechicera = "hechicero", guerrera = "guerrero", druidesa = "druida",
}
-- Palabras funcionales que NO se masculinizan (si no, "la"->"lo" rompe "Elfa de la Noche").
local GENDER_STOP = { la = true, las = true, una = true, unas = true, de = true,
    del = true, el = true, los = true, ["a"] = true, ["y"] = true, en = true }
local function Masculinize(normalized)
    return (tostring(normalized or ""):gsub("%a+", function(w)
        if GENDER_ALIAS[w] then return GENDER_ALIAS[w] end
        if GENDER_STOP[w] then return w end
        return (w:gsub("a$", "o"))  -- 'a' final de palabra -> 'o'
    end))
end

local function EnsureIndex()
    if classById then return end
    classById, classOrder = {}, {}
    for _, classDef in ipairs(API.CLASSES) do
        classById[classDef.id] = classDef
        classOrder[#classOrder + 1] = classDef.id
    end
end

function API.GetClasses()
    EnsureIndex()
    return API.CLASSES
end

function API.GetClass(classId)
    EnsureIndex()
    return classById[tostring(classId or "")]
end

function API.GetClassOrder()
    EnsureIndex()
    return classOrder
end

function API.GetSubclass(classId, subclassId)
    local classDef = API.GetClass(classId)
    if not classDef then return nil end
    subclassId = NormalizeSubclassId(classId, subclassId)
    for _, subclass in ipairs(classDef.subclasses or {}) do
        if subclass.id == subclassId then return subclass end
    end
    return nil
end

function API.NormalizeSubclassId(classId, subclassId)
    return NormalizeSubclassId(classId, subclassId)
end

function API.GetDefaultSubclassId(classId)
    local classDef = API.GetClass(classId)
    local first = classDef and classDef.subclasses and classDef.subclasses[1]
    return first and first.id or ""
end

function API.GetSubclassUnlockLevel(classId)
    local classDef = API.GetClass(classId)
    local best
    for _, subclass in ipairs((classDef and classDef.subclasses) or {}) do
        for _, feature in ipairs(subclass.features or {}) do
            local level = tonumber(feature.level)
            if level and (not best or level < best) then
                best = level
            end
        end
    end
    return best
end

function API.FindClassIdByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil end
    EnsureIndex()
    local masc = Masculinize(clean)
    for _, classDef in ipairs(API.CLASSES) do
        local n, i = Normalize(classDef.name), Normalize(classDef.id)
        if clean:find(n, 1, true) or clean:find(i, 1, true)
            or (masc ~= clean and (masc:find(n, 1, true) or masc:find(i, 1, true)))
        then
            return classDef.id
        end
    end
    return nil
end

function API.FindSubclassIdByText(classId, text)
    local classDef = API.GetClass(classId)
    local clean = Normalize(text)
    if not classDef or clean == "" then return nil end
    local masc = Masculinize(clean)
    local bestId, bestLen
    for _, subclass in ipairs(classDef.subclasses or {}) do
        local candidates = { subclass.id, subclass.name }
        local aliases = SUBCLASS_TEXT_ALIASES[classDef.id]
        if aliases then
            for alias, targetId in pairs(aliases) do
                if targetId == subclass.id then
                    candidates[#candidates + 1] = alias
                end
            end
        end
        local normalizedName = Normalize(subclass.name)
        -- Muchas especializaciones del libro usan prefijos ("Camino de",
        -- "Marca de", "Presencia de"). El About TRP3 suele escribir solo el
        -- nombre jugable, asi que probamos tambien la ultima palabra relevante.
        local tail = normalizedName:match("([^%s]+)$")
        if tail and tail ~= normalizedName then
            candidates[#candidates + 1] = tail
        end
        for _, candidate in ipairs(candidates) do
            local normalized = Normalize(candidate)
            -- original primero; fallback en masculino para subclases escritas en femenino
            -- (Forajida->forajido, etc.). Las subclases canonicas acabadas en 'a' (Escarcha,
            -- Sutileza, Ira...) casan con el texto original, no con la variante.
            if normalized ~= "" and (clean:find(normalized, 1, true)
                or (masc ~= clean and masc:find(normalized, 1, true))) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = subclass.id, len
                end
            end
        end
    end
    return bestId
end

function API.GetClassName(classId)
    local classDef = API.GetClass(classId)
    return classDef and classDef.name or tostring(classId or "")
end

function API.GetSubclassName(classId, subclassId)
    local subclass = API.GetSubclass(classId, subclassId)
    return subclass and subclass.name or ""
end

-- Resuelve la lista de opciones de un rasgo con `choice`. Devuelve { {id,label,effects}, ... }.
-- `choice.options` se usa tal cual; `choice.optionsFrom` genera la lista desde datos:
--   "ability+1"      -> cada caracteristica como +1 (ASI).
--   "skillProf"      -> cada habilidad como competencia.
--   "skillExpertise" -> cada habilidad como pericia (x2).
function API.GetChoiceOptions(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return nil end
    if type(choice.options) == "table" then return choice.options end

    local from = tostring(choice.optionsFrom or "")
    local out = {}
    -- "ability+N": cada caracteristica como +N (ASI usa +1; razas usan +2 o +1).
    local abilInc = from:match("^ability%+(%d+)$")
    if abilInc and HarfordDnDData and HarfordDnDData.ABIL then
        local value = tonumber(abilInc) or 1
        for _, abil in ipairs(HarfordDnDData.ABIL) do
            out[#out + 1] = {
                id = abil.key, label = abil.key .. " +" .. value,
                effects = { { kind = "bonus", target = "ability", ability = abil.key, value = value } },
            }
        end
    elseif (from == "skillProf" or from == "skillExpertise") and HarfordDnDData and HarfordDnDData.SKILLS then
        local kind = (from == "skillExpertise") and "skillExpertise" or "skillProf"
        for _, skill in ipairs(HarfordDnDData.SKILLS) do
            out[#out + 1] = {
                id = skill.id, label = skill.name or skill.id,
                effects = { { kind = kind, skill = skill.id } },
            }
        end
    elseif from == "toolProf" and HarfordDnDData and HarfordDnDData.TOOLS then
        -- Competencia con una herramienta a elegir del catalogo estandar (Prodigio, Artifice, etc.).
        for _, tool in ipairs(HarfordDnDData.TOOLS) do
            out[#out + 1] = {
                id = tool.id, label = tool.name or tool.id,
                effects = { { kind = "toolProf", tool = tool.name or tool.id } },
            }
        end
    else
        return nil
    end
    return out
end

-- Busca una opcion de choice por id dentro de un rasgo.
function API.GetChoiceOption(feature, optionId)
    optionId = tostring(optionId or "")
    if optionId == "" then return nil end
    for _, opt in ipairs(API.GetChoiceOptions(feature) or {}) do
        if opt.id == optionId then return opt end
    end
    return nil
end

-- Texto completo de cada estilo de combate (las opciones solo llevan label corto; el detalle
-- vive aqui, compartido por todas las clases que ofrecen Estilo de Combate).
local COMBAT_STYLE_DESC = {
    defensa             = "Mientras lleves armadura, ganas +1 a la Clase de Armadura.",
    duelo               = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    duelos              = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    ["doble_empuñadura"] = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    gran_arma           = "Con un arma a dos manos (o versatil usada a dos manos), repites los dados de daño que saquen 1 o 2 y usas el nuevo resultado.",
    proteccion          = "Con un escudo, usas tu reaccion para imponer desventaja a un atacante (a 5 pies) que ataque a otro objetivo distinto de ti.",
    dos_armas           = "Cuando portas dos armas, puedes agregar tu modificador de habilidad al daño del segundo ataque.",
    tiro_arco           = "Ganas +2 a las tiradas de ataque con armas a distancia.",
    tirador             = "Atacar a distancia estando en cuerpo a cuerpo no te impone desventaja, e ignoras media cobertura y tres cuartos; +1 al ataque a distancia.",
    guerrero_profano    = "Aprendes dos trucos de brujo (lanzados con Carisma); no cuentan en tu limite de trucos.",
    guerrero_bendito    = "Aprendes dos trucos de sacerdote (lanzados con Carisma); no cuentan en tu limite de trucos.",
}

-- Descripcion de la OPCION elegida de un choice (para el tooltip del Libro): usa opt.desc si
-- existe; para Estilo de Combate cae al texto compartido por id. nil si no hay descripcion propia.
function API.GetChoiceOptionDesc(feature, optionId)
    local opt = API.GetChoiceOption(feature, optionId)
    if opt and type(opt.desc) == "string" and opt.desc ~= "" then return opt.desc end
    if feature and tostring(feature.name or ""):find("Estilo de Combate") then
        return COMBAT_STYLE_DESC[tostring(optionId)]
    end
    return nil
end

-- Numero de slots a elegir de un rasgo con choice (default 1).
function API.GetChoiceSlots(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return 0 end
    return math.max(1, math.floor(tonumber(choice.slots) or 1))
end

function API.GetFeature(featureId)
    featureId = tostring(featureId or "")
    for _, classDef in ipairs(API.CLASSES) do
        for _, feature in ipairs(classDef.features or {}) do
            if feature.id == featureId then
                return feature, classDef
            end
        end
    end
    return nil
end

function API.GetUnlockedFeatures(classLevels)
    local out = {}
    for _, entry in ipairs(classLevels or {}) do
        local classDef = API.GetClass(entry.classId)
        local level = tonumber(entry.level) or 0
        if classDef and level > 0 then
            for _, feature in ipairs(classDef.features or {}) do
                if (tonumber(feature.level) or 0) <= level then
                    out[#out + 1] = {
                        classId = classDef.id,
                        className = classDef.name,
                        subclassId = entry.subclassId,
                        level = feature.level,
                        feature = feature,
                    }
                end
            end
            -- Rasgos de la subclase (especializacion) SELECCIONADA, por nivel.
            local subclass = API.GetSubclass(classDef.id, entry.subclassId)
            if subclass then
                for _, feature in ipairs(subclass.features or {}) do
                    if (tonumber(feature.level) or 0) <= level then
                        out[#out + 1] = {
                            classId = classDef.id,
                            className = (classDef.name or "") .. " / " .. (subclass.name or ""),
                            subclassId = entry.subclassId,
                            level = feature.level,
                            feature = feature,
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.className or "") ~= (b.className or "") then return (a.className or "") < (b.className or "") end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return tostring(a.feature and a.feature.name or "") < tostring(b.feature and b.feature.name or "")
    end)
    return out
end
