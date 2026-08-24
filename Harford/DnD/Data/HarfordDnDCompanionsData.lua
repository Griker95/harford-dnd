-- HarfordDnDCompanionsData: bloques de estadisticas de las criaturas acompanantes.
-- Solo datos. El estado (cual esta invocada, sus PG) vive en HarfordDnDCompanions (State).
--
-- El manual les da la MISMA forma en las cuatro clases que las declaran: bloque propio,
-- comparten tu iniciativa pero actuan justo despues de ti, y en su turno solo toman la accion de
-- Esquivar salvo que gastes tu accion en ordenarles otra.
--
-- Por eso NO tienen entrada propia en el tracker de turnos: actuan DENTRO del tuyo. `commandAction`
-- dice que te cuesta ordenarles un ataque, que no es igual en todas ("accion" o "adicional").
--
-- Varios valores se DERIVAN de su invocador y no son fijos:
--   `hp`      = base + Mod. de una caracteristica PROPIA + Mod. de una TUYA + porNivel x tu nivel
--   `acPlusProficiency` suma tu bonus de competencia a la CA (el elemental: "CA 13 + PB")
--   una accion con `attackFrom = "spellAttack"` usa TU modificador de ataque de conjuros
--   `damagePlusProficiency` suma tu PB al dano (el elemental: "1d8 + 2 + PB")
--
-- Pendientes de tener su pagina: los demonios del Brujo (Anexo C) y la bestia del Cazador
-- (que no es un bloque fijo, sino cualquier bestia de desafio 1/2 o menor).

HarfordDnDCompanionsData = HarfordDnDCompanionsData or {}

local function Ataque(nombre, dmgN, dmgS, tipo, opts)
    opts = opts or {}
    return {
        key = nombre, cat = "Acompanante", mode = opts.mode or "Melee",
        icon = opts.icon,
        rangeFeet = opts.rangeFeet or 5, targetText = "un objetivo",
        dmgN = dmgN, dmgS = dmgS, dmgType = tipo,
        addAbi = false,                       -- el bloque declara su dano, no suma tu caracteristica
        weaponDamageBonus = opts.damageBonus or 0,
        damagePlusProficiency = opts.damagePlusProficiency or false,
        attackBonus = opts.attackBonus,       -- fijo del bloque
        attackFrom = opts.attackFrom,         -- "spellAttack": usa el del invocador
        ignoreGlobalWeaponBonuses = true,
        source = "companion",
        props = { "Natural" },
        note = opts.note,
    }
end

-- Los cinco demonios del brujo comparten formula de PG: "tu Mod. Inteligencia + el Mod. de
-- Constitucion de la criatura + 5 veces tu nivel de brujo". Es Inteligencia, NO Carisma: este
-- brujo lanza con Inteligencia (lo confirma "Sentir Demonios", cuyos usos salen de ahi).
local HP_BRUJO = { base = 0, ownAbility = "Constitucion", ownerAbility = "Inteligencia", perOwnerLevel = 5 }

HarfordDnDCompanionsData.COMPANIONS = {
    {
        id = "esbirro_no_muerto", name = "Esbirro No-Muerto",
        icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
        classId = "caballero_muerte", minLevel = 3, requiresOption = "levantar",
        commandAction = "accion",
        creatureType = "No-muerto Mediano, maligno neutral",
        armorClassBase = 12, armorClassNote = "armadura natural",
        -- "Mod. Constitucion del esbirro + tu Mod. Carisma + 5 x nivel en esta clase"
        hp = { base = 0, ownAbility = "Constitucion", ownerAbility = "Carisma", perOwnerLevel = 5 },
        speed = 30,
        abilities = { Fuerza = 16, Destreza = 11, Constitucion = 14, Inteligencia = 6, Sabiduria = 8, Carisma = 5 },
        saves = { Fuerza = 5, Constitucion = 4, Sabiduria = 1 },
        masterPower = { attack = true, damage = true },
        damageImmunities = { "veneno" },
        conditionImmunities = { "agotamiento", "petrificado", "asustado", "envenenado" },
        senses = "Vision en la oscuridad 18 m, Percepcion pasiva 9",
        languages = "Entiende los idiomas que conocia en vida pero no puede hablar",
        traits = {
            "Obligado a Servir: sus salvaciones y el ataque y dano de su Garra Putrefacta suben 1 cuando sube tu bonus de competencia. Ademas puede usar TU modificador de ataque con conjuros en lugar del suyo; el dano no cambia.",
            "Fortaleza No-Muerta: si el dano lo reduce a 0 puntos de golpe, hace una salvacion de Constitucion con CD 5 + el dano recibido, salvo que el dano sea radiante o de un critico. Con exito queda a 1 punto de golpe.",
            "Carga Tambaleante (1/descanso corto o largo): al inicio de su turno puede duplicar su velocidad hasta el final del turno. Si golpea a una criatura ese mismo turno, esta hace una salvacion de Fuerza contra la CD de tus conjuros o cae derribada.",
        },
        actions = {
            Ataque("Garra Putrefacta", 1, 6, "necrotico", {
                attackBonus = 5, attackFrom = "spellAttack", damageBonus = 2,
                note = "Si el objetivo no es un no-muerto, hace una salvacion contra la CD de tus conjuros o sufre la enfermedad profana que porta. Repite la salvacion al final de cada uno de sus turnos.",
            }),
        },
    },
    {
        id = "elemental_agua", name = "Elemental de Agua",
        icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
        classId = "mago", minLevel = 2, requiresOption = "elemental",
        commandAction = "adicional",
        creatureType = "Elemental mediano, neutral",
        armorClassBase = 13, acPlusProficiency = true, armorClassNote = "armadura natural",
        -- "2 + Mod. Inteligencia + 5 x nivel de mago"
        hp = { base = 2, ownerAbility = "Inteligencia", perOwnerLevel = 5 },
        speed = 30, swimSpeed = 40,
        abilities = { Fuerza = 14, Destreza = 12, Constitucion = 14, Inteligencia = 4, Sabiduria = 10, Carisma = 6 },
        skills = { Percepcion = 2 },
        skillsScaleWithProficiency = true,
        damageImmunities = { "veneno" },
        conditionImmunities = { "agotamiento", "petrificado", "envenenado" },
        senses = "Vision en la oscuridad 18 m, Percepcion pasiva 9",
        languages = "Entiende los idiomas de su creador, pero no puede hablar",
        traits = {
            "Si le lanzas un conjuro que inflija dano por frio, es inmune y recupera puntos de golpe iguales al dano infligido.",
            "No necesitas tirar para golpear al elemental y falla automaticamente cualquier tirada de salvacion si lo eliges.",
        },
        actions = {
            Ataque("Golpe", 1, 8, "contundente", {
                attackFrom = "spellAttack", damageBonus = 2, damagePlusProficiency = true }),
            Ataque("Rayo de Escarcha", 1, 6, "frio", {
                mode = "Ranged", rangeFeet = 30, attackFrom = "spellAttack",
                damageBonus = 2, damagePlusProficiency = true }),
        },
        specialActions = {
            { key = "Restaurar", uses = 3, recharge = "long",
              note = "Las magias dentro del elemental le restauran 2d8 + tu bonus de competencia puntos de golpe a si mismo." },
        },
        reactions = {
            { key = "Congelar",
              note = "Cuando una criatura a su alcance lo golpea con un ataque cuerpo a cuerpo, el elemental puede intentar agarrarla." },
        },
    },
    -- ---------------------------------------------------------------------------------------
    -- Demonios del Brujo (rasgo "Conocimiento demoniaco", nivel 2). Los cinco comparten forma:
    -- misma formula de PG, "Poder del Maestro" que sube CA/ataque/dano con tu competencia, y un
    -- Nucleo Demoniaco que se obtiene destruyendolos al invocarlos, que es rasgo de clase y no
    -- del bloque. Solo se mantiene uno a la vez, que es lo que ya impone el estado.
    -- ---------------------------------------------------------------------------------------
    {
        id = "guardia_vil", name = "Guardia Vil",
        icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
        classId = "brujo", minLevel = 2, commandAction = "accion",
        -- Grimorio de sacrificio: destruirlo al invocarlo te deja su nucleo.
        coreFeatureId = "bru_nucleo_guardia_vil",
        creatureType = "Diablillo mediano (demonio), maligno legal",
        armorClassBase = 14, armorClassNote = "armadura natural",
        masterPower = { ac = true, attack = true, damage = true },
        hp = HP_BRUJO,
        speed = 30,
        abilities = { Fuerza = 16, Destreza = 12, Constitucion = 14, Inteligencia = 10, Sabiduria = 12, Carisma = 12 },
        saves = { Fuerza = 5, Constitucion = 4 },
        skills = { Atletismo = 5, Intimidacion = 3, Percepcion = 3 },
        damageResistances = { "contundente", "perforante", "cortante" },
        senses = "Vision en la oscuridad 18 m, Percepcion pasiva 11",
        languages = "Eredun, comprende los idiomas de su invocador",
        traits = {
            "Poder del Maestro: su CA, sus bonificaciones de habilidades y el bono a sus tiradas de ataque y dano suben 1 cada vez que sube tu bonificacion de competencia.",
            "Golpe de Legion: una vez por turno, al atacar con Hacha de Legion puede hacer otro ataque contra una criatura distinta que este a 1,5 m del primer objetivo y del guardia vil.",
            "Resistencia al Dano: contundente, perforante y cortante de armas no magicas.",
        },
        reactions = {
            { key = "Persecucion",
              note = "Cuando una criatura deja de moverse tras salir de su alcance, puede usar su reaccion para moverse hasta su velocidad hacia ella. Ese movimiento no provoca ataques de oportunidad, y despues puede atacar con Hacha de Legion si la criatura esta a su alcance." },
        },
        actions = {
            Ataque("Hacha de Legion", 1, 10, "cortante", { attackBonus = 5, damageBonus = 3 }),
        },
    },
    {
        id = "manafago", name = "Manafago",
        icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
        classId = "brujo", minLevel = 2, commandAction = "accion",
        -- Grimorio de sacrificio: destruirlo al invocarlo te deja su nucleo.
        coreFeatureId = "bru_nucleo_manafago",
        creatureType = "Diablillo mediano (demonio), maligno neutral",
        armorClassBase = 13, armorClassNote = "armadura natural",
        masterPower = { ac = true, attack = true, damage = true },
        hp = HP_BRUJO,
        speed = 40,
        abilities = { Fuerza = 17, Destreza = 12, Constitucion = 14, Inteligencia = 6, Sabiduria = 13, Carisma = 14 },
        saves = { Destreza = 3, Constitucion = 4 },
        skills = { Percepcion = 3, Sigilo = 3, Supervivencia = 3 },
        senses = "Vision ciega 18 m, Percepcion pasiva 13",
        languages = "Entiende Eredun y los idiomas de su invocador, pero no puede hablar",
        traits = {
            "Poder del Maestro: su CA, sus bonificaciones de habilidades y el bono a sus tiradas de ataque y dano suben 1 cada vez que sube tu bonificacion de competencia.",
            "Disrupcion Magica: si inflige dano a una criatura que luego deba salvar Constitucion para mantener la concentracion en un conjuro, esa salvacion se hace con desventaja.",
            "Resistencia Magica: ventaja en las salvaciones contra conjuros y otros efectos magicos.",
            "Deteccion Magica: percibe la magia a 18 m a voluntad, como el conjuro detectar magia, pero el rasgo no es magico.",
        },
        actions = {
            Ataque("Mordisco Sombrio", 1, 6, "necrotico", { attackBonus = 5, damageBonus = 3 }),
            Ataque("Desgarrar", 1, 8, "perforante", { attackBonus = 5, damageBonus = 3 }),
        },
    },
    {
        id = "diablillo", name = "Diablillo",
        icon = "Interface\\Icons\\Spell_Shadow_SummonImp",
        classId = "brujo", minLevel = 2, commandAction = "accion",
        -- Grimorio de sacrificio: destruirlo al invocarlo te deja su nucleo.
        coreFeatureId = "bru_nucleo_diablillo",
        creatureType = "Pequeno ser infernal (demonio), caotico maligno",
        armorClassBase = 13,
        masterPower = { ac = true, attack = true, damage = true },
        hp = HP_BRUJO,
        speed = 25,
        abilities = { Fuerza = 6, Destreza = 16, Constitucion = 13, Inteligencia = 16, Sabiduria = 8, Carisma = 14 },
        saves = { Destreza = 5, Sabiduria = 1 },
        skills = { Engano = 4, ["Juego de Manos"] = 5, Sigilo = 5 },
        senses = "Vision en la oscuridad 18 m, Percepcion pasiva 11",
        languages = "Eredun, comprende los idiomas de su invocador",
        traits = {
            "Poder del Maestro: su CA, sus bonificaciones de habilidades y el bono a sus tiradas de ataque y dano suben 1 cada vez que sube tu bonificacion de competencia.",
        },
        reactions = {
            { key = "Cambio de Fase",
              note = "Cuando sea objeto de un efecto que le permita salvar para recibir la mitad del dano, puede usar su reaccion para cambiar de fase con el mundo y tener exito automaticamente." },
        },
        actions = {
            Ataque("Garra", 1, 4, "cortante", { attackBonus = 5, damageBonus = 3 }),
            Ataque("Rayo de Fuego", 1, 8, "fuego", {
                mode = "Ranged", rangeFeet = 60, attackBonus = 4, damageBonus = 3,
                note = "Ataque de Conjuro a Distancia." }),
        },
    },
    {
        id = "sucubo", name = "Sucubo",
        icon = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
        classId = "brujo", minLevel = 2, commandAction = "accion",
        -- Grimorio de sacrificio: destruirlo al invocarlo te deja su nucleo.
        coreFeatureId = "bru_nucleo_sucubo",
        creatureType = "Ser infernal mediano (demonio), caotico maligno",
        armorClassBase = 13,
        masterPower = { ac = true, attack = true, damage = true },
        hp = HP_BRUJO,
        speed = 30, flySpeed = 15,
        abilities = { Fuerza = 8, Destreza = 16, Constitucion = 13, Inteligencia = 10, Sabiduria = 12, Carisma = 16 },
        saves = { Carisma = 5, Sabiduria = 3 },
        skills = { Engano = 5, Persuasion = 5, Sigilo = 5 },
        senses = "Vision en la oscuridad 18 m, Percepcion pasiva 11",
        languages = "Eredun, Comun, entiende los idiomas de su invocador",
        traits = {
            "Poder del Maestro: su CA, sus bonificaciones de habilidades y el bono a sus tiradas de ataque y dano suben 1 cada vez que sube tu bonificacion de competencia.",
            "Cambiaformas: con su accion se transforma en un humanoide Pequeno o Mediano, o vuelve a su forma verdadera. Salvo tamano y velocidad, sus estadisticas no cambian. El equipo que lleve no se transforma.",
            "Maestra del Latigo: cuando golpea con el Latigo del Dolor, el objetivo puede ser movido hasta 3 m hacia el sucubo o alejandose de el.",
        },
        specialActions = {
            { key = "Invisibilidad",
              note = "Se vuelve invisible magicamente hasta atacar o hasta que termine su concentracion. El equipo que lleve tambien se vuelve invisible." },
        },
        actions = {
            Ataque("Latigo del Dolor", 1, 6, "necrotico", {
                attackBonus = 5, damageBonus = 3, rangeFeet = 10,
                note = "Ademas, el objetivo debe superar una salvacion de Constitucion contra la CD de conjuro de su maestro o su velocidad se reduce en 3 m hasta el inicio del siguiente turno del sucubo." }),
        },
    },
    {
        id = "abisario", name = "Abisario",
        icon = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
        classId = "brujo", minLevel = 2, commandAction = "accion",
        -- Grimorio de sacrificio: destruirlo al invocarlo te deja su nucleo.
        coreFeatureId = "bru_nucleo_abisario",
        creatureType = "Ser infernal mediano (demonio), neutral maligno",
        armorClassBase = 16, armorClassNote = "armadura natural",
        masterPower = { ac = true, attack = true, damage = true },
        hp = HP_BRUJO,
        speed = 30,
        abilities = { Fuerza = 16, Destreza = 8, Constitucion = 18, Inteligencia = 8, Sabiduria = 14, Carisma = 10 },
        saves = { Destreza = 1, Sabiduria = 4 },
        skills = { Atletismo = 5, Intimidacion = 2, Percepcion = 4 },
        damageVulnerabilities = { "radiante" },
        damageResistances = { "contundente", "perforante", "cortante" },
        conditionImmunities = { "asustado", "apresado" },
        senses = "Vision en la oscuridad 18 m, Percepcion pasiva 14",
        languages = "Eredun, comprende los idiomas de su invocador",
        traits = {
            "Poder del Maestro: su CA, sus bonificaciones de habilidades y el bono a sus tiradas de ataque y dano suben 1 cada vez que sube tu bonificacion de competencia.",
            "Presencia Amenazante: cualquier criatura danada por el abisario tiene desventaja en las tiradas de ataque contra un objetivo que no sea el abisario, hasta el final de su siguiente turno.",
            "Resistencias: contundente, perforante y cortante de armas no magicas. Vulnerable al dano radiante. Inmune a asustado y apresado.",
        },
        specialActions = {
            { key = "Muralla de Sombras", uses = 1, recharge = "long",
              note = "Gana puntos de golpe temporales iguales al doble de tu bonus de competencia." },
        },
        actions = {
            Ataque("Golpe", 1, 6, "contundente", { attackBonus = 5, damageBonus = 3, rangeFeet = 10 }),
            Ataque("Sufrimiento", 1, 6, "necrotico", { attackBonus = 5, damageBonus = 3, rangeFeet = 10 }),
        },
    },
}
