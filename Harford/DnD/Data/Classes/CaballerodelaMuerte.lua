-- Caballero de la Muerte: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "caballero_muerte", name = "Caballero de la Muerte", desc = "Guerrero resucitado por las val'kyr: parece muerto, pero está vivo. Runas en el filo, escarcha y tierra marchita, y un rechazo que lo empuja a los márgenes.", hitDie = 10, casterType = "half", startingGold = { dice = 4, sides = 4, multiplier = 1 },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Un arma marcial", items = { { pick = "Marcial" } } },
            { label = "Dos espadas cortas", items = { "Espada corta", "Espada corta" } },
        } },
        { label = "Arma secundaria",
            options = {
            { label = "Cinco jabalinas", items = { "Jabalina", "Jabalina", "Jabalina", "Jabalina", "Jabalina" } },
            { label = "Cualquier arma simple", items = { { pick = "Simple" } } },
        } },
        { label = "Armadura",
            options = {
            { label = "Cota de escamas", items = { "Cota de escamas" } },
            { label = "Cota de malla", items = { "Cota de malla" } },
        } },
        { label = "Paquete",
            fixed = { "Amuleto de tu vida pasada" },
            options = {
            { label = "Paquete de aventurero de mazmorras", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Atletismo", "Engano", "Intimidacion", "Investigacion", "Percepcion",
        "Sigilo" },
    saves = { "Constitucion", "Carisma" },
    armorProfs = { "ligera", "media", "pesada" },
    weaponProfs = { "sencillas", "marciales" },
    subclasses = {
        { id = "sangre", name = "Sangre", desc = "Tanque no-muerto que se sostiene drenando la vida de sus enemigos.", features = {
                { id = "cdm_san_conjuros_3", level = 3, name = "Conjuros de presencia (Sangre)", type = "informativo", grantedSpells = { "orden_imperiosa", "agarre_de_la_muerte" }, description = "Nivel 3: Orden imperiosa (mandato) y Agarre de la muerte. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", spellGrants = { { level = 1, ids = { "orden_imperiosa", "agarre_de_la_muerte" } } }, effects = {} },
                { id = "cdm_san_conjuros_5", level = 5, name = "Conjuros de presencia (Sangre)", type = "informativo", grantedSpells = { "hervor_de_sangre", "inmovilizar_persona" }, description = "Nivel 5: Hervor de sangre y Inmovilizar persona. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", spellGrants = { { level = 2, ids = { "inmovilizar_persona", "hervor_de_sangre" } } }, effects = {} },
            { id = "cdm_san_comando_oscuro", level = 3, name = "Orden oscura", type = "informativo", description = "Al dañar con Poder Runico, la criatura tiene desventaja en ataques contra otros que no seas tu hasta el final de tu próximo turno.", effects = {
                    -- El dano condicional `runic_strike` es de CLASE (Golpe runico, N1) y este
                    -- rasgo es de subclase N3: la condicion no puede colgar del dano, o la
                    -- tendrian todos los caballeros desde nivel 1. Cuelga del rasgo como rider.
                    { kind = "conditionalDamageRider", conditionalId = "runic_strike",
                      conditionId = "orden_oscura", duration = "fin de tu proximo turno" },
                } },
            { id = "cdm_san_escudo_sangre", level = 3, name = "Escudo de Sangre", type = "informativo", description = "A partir del nivel 3, aprendes a tejer tu magia vil en una barrera protectora. Cuando lanzas un conjuro de caballero de la muerte de 1er nivel o superior, puedes usar la esencia oscura del conjuro para crear un escudo de sangre sobre ti que dura hasta que termines un descanso largo. El escudo tiene puntos de golpe iguales al doble de tu nivel de caballero de la muerte + Mod. Carisma. Siempre que recibas daño, el escudo lo absorbe primero. Si el daño reduce el escudo a 0 puntos de golpe, recibes cualquier daño restante.\n\nMientras el escudo de sangre tenga 0 puntos de golpe, no puede absorber daño, pero su magia permanece. Siempre que lances un conjuro de caballero de la muerte de 1er nivel o superior, el escudo recupera puntos de golpe iguales al doble del nivel del conjuro.\n\nUna vez que crees un escudo de sangre, no puedes volver a crearlo hasta que termines un descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                        { id = "cdm_san_tormenta_de_huesos", icon = "inv_misc_bone_humanskull_01", level = 7, name = "Tormenta de Huesos", type = "informativo", description = "A partir del nivel 7, puedes usar tu acción para invocar un torbellino de huesos afilados a tu alrededor. La tormenta tiene un radio de 6 metros y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Destreza. Si falla, la criatura recibe daño perforante mágico igual a 1d6 + tu nivel de caballero de la muerte y cae derribada. Si tiene éxito, recibe la mitad del daño y no sufre otros efectos. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso corto o largo.", effects = {} },
            { id = "cdm_san_golpe_al_corazon", icon = "spell_deathknight_bloodpresence", level = 11, name = "Golpe al Corazón", type = "informativo", description = "En el nivel 11, tu poder oscuro refuerza tus ataques. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 de arma. Además, el daño infligido por tus armas rúnicas ignora resistencias.", effects = {} },
            { id = "cdm_san_purgatorio", icon = "spell_shadow_lifedrain", level = 15, name = "Purgatorio", type = "informativo", description = "A partir del nivel 15, cuando seas reducido a 0 puntos de golpe y no mueras instantáneamente, puedes optar por quedar con 1 punto de golpe en su lugar y reponer los puntos de golpe de tu escudo de sangre al doble de tu nivel de caballero de la muerte. Una vez que uses esta habilidad, no podrás volver a usarla hasta que termines un descanso largo.", effects = {} },
            { id = "cdm_san_arma_runica_danza", icon = "inv_sword_62", level = 20, name = "Arma Rúnica Danza", type = "informativo", description = "En el nivel 20, puedes invocar una copia espectral de tu arma rúnica, que danza de manera amenazante en tu espacio. El arma rúnica danzante dura 1 minuto y es idéntica a tu arma rúnica. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo.\n\nAl comienzo de cada uno de tus turnos, puedes comandar a tu arma rúnica danzante para que actúe de una de las siguientes maneras hasta el inicio de tu próximo turno (no se requiere acción).\n\n***Defensivamente.*** Obtienes los beneficios de la acción de Esquivar. Además, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en tu turno. Puedes usar esta reacción especial cuando una criatura que puedas ver realiza un ataque contra un objetivo que no seas tú y que esté a 3 metros de ti, imponiendo desventaja en la tirada de ataque.\n\n ***Ofensivamente.*** Cuando realices la acción de Ataque en tu turno, puedes hacer un ataque adicional con el arma rúnica danzante como parte de la misma acción. Además, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en tu turno. Solo puedes usar esta reacción especial para realizar un ataque de oportunidad con tu arma rúnica danzante y no puedes usarla en el mismo turno que tomas tu reacción normal.", effects = {} },
        } },
        { id = "escarcha", name = "Escarcha", desc = "Doble empunadura y magia de hielo para ralentizar y despedazar.", features = {
                { id = "cdm_esc_conjuros_3", level = 3, name = "Conjuros de presencia (Escarcha)", type = "informativo", grantedSpells = { "armadura_de_agathys", "toque_helado_nivel_1" }, description = "Nivel 3: Armadura de Agathys y Toque helado. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", spellGrants = { { level = 1, ids = { "armadura_de_agathys", "toque_helado_nivel_1" } } }, effects = {} },
                { id = "cdm_esc_conjuros_5", level = 5, name = "Conjuros de presencia (Escarcha)", type = "informativo", grantedSpells = { "explosion_aullante", "viento_guardian" }, description = "Nivel 5: Explosion aullante y Viento guardian (viento protector). Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", spellGrants = { { level = 2, ids = { "explosion_aullante", "viento_guardian" } } }, effects = {} },
            { id = "cdm_esc_golpe_escarcha", level = 3, name = "Golpe de escarcha", type = "pasivo", description = "Cuando eliges esta presencia en el nivel 3, aprendes a potenciar tus ataques con furia invernal. Cuando gastas dados de Poder Rúnico en un golpe rúnico, los dados se convierten en d8 y el golpe rúnico inflige daño por frío en lugar de daño necrótico.", effects = {
                { kind = "flag", flag = "frostRunicStrike" },
            } },
            { id = "cdm_esc_maquina_matar", level = 3, name = "Maquina de matar", type = "pasivo", description = "También a partir del nivel 3, tus ataques con armas cuerpo a cuerpo obtienen un golpe crítico con una tirada de 19 o 20. Además, puedes usar combate con dos armas incluso si las armas cuerpo a cuerpo que empuñas no son ligeras, siempre que no tengan las propiedades de pesada o dos manos.", effects = {
                { kind = "critRange", value = 19, melee = true },
            } },
                        { id = "cdm_esc_invierno_implacable", icon = "spell_frost_arcticwinds", level = 7, name = "Invierno Implacable", type = "informativo", description = "A partir del nivel 7, puedes usar tu acción para invocar una tormenta de viento cortante y aguanieve a tu alrededor. La tormenta tiene un radio de 6 metros y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Constitución, recibiendo daño por frío igual a 1d6 + tu nivel de caballero de la muerte si falla, o la mitad si tiene éxito. Si falla, la velocidad de la criatura se reduce a la mitad hasta el inicio de su próximo turno. Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso corto o largo.", effects = {} },
            { id = "cdm_esc_corazon_congelado", icon = "spell_frost_frozencore", level = 11, name = "Corazón Congelado", type = "informativo", description = "En el nivel 11, tus ataques con armas llevan consigo el frío de Rasganorte. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 por frío. Además, tus rasgos y conjuros de caballero de la muerte ignoran la resistencia al frío y tratan la inmunidad al daño por frío como resistencia.", effects = {} },
            { id = "cdm_esc_garras_de_hielo", icon = "inv_misc_monsterclaw_03", level = 15, name = "Garras de Hielo", type = "informativo", description = "A partir del nivel 15, una vez en cada uno de tus turnos, cuando gastes dos o más dados rúnicos a la vez en un golpe rúnico, puedes realizar un ataque adicional con un arma cuerpo a cuerpo como parte de la misma acción de Ataque.", effects = {} },
            { id = "cdm_esc_pilar_de_escarcha", icon = "spell_deathknight_frostpresence", level = 20, name = "Pilar de Escarcha", type = "informativo", description = "En el nivel 20, eres capaz de canalizar el poder helado del mismísimo Trono Helado. Como acción, puedes convertirte mágicamente en un avatar del invierno todo consumidor, obteniendo los siguientes beneficios durante 1 minuto: - Tienes resistencia al daño contundente, perforante y cortante, e inmunidad al daño por frío. - Añades Mod. Carisma al daño de tus ataques con armas cuerpo a cuerpo (mínimo de 1). - Cuando normalmente lanzarías uno o más dados para infligir daño por frío con un conjuro de caballero de la muerte, en su lugar, usas el número más alto posible para cada dado. Por ejemplo, en lugar de infligir 2d8 de daño por frío a una criatura, infliges 16. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo.", effects = {} },
        } },
        { id = "profana", name = "Profano", desc = "Enfermedades y magia profana que corroen y debilitan al enemigo.", features = {
                { id = "cdm_pro_conjuros_3", level = 3, name = "Conjuros de presencia (Profana)", type = "informativo", grantedSpells = { "explosion_de_cadaveres", "rayo_de_enfermedad" }, description = "Nivel 3: Explosion de cadaveres y Rayo de enfermedad. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", spellGrants = { { level = 1, ids = { "explosion_de_cadaveres", "rayo_de_enfermedad" } } }, effects = {} },
                { id = "cdm_pro_conjuros_5", level = 5, name = "Conjuros de presencia (Profana)", type = "informativo", grantedSpells = { "cascara_antimagica", "rayo_debilitador" }, description = "Nivel 5: Caparazon antimagia y Rayo debilitador. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", spellGrants = { { level = 2, ids = { "cascara_antimagica", "rayo_debilitador" } } }, effects = {} },
            { id = "cdm_pro_portador_plagas", level = 3, name = "Portador de plagas", type = "choice", companionId = "esbirro_no_muerto", description = "Eliges Brotes o Levantar a los Muertos.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "brotes", icon = "spell_shadow_creepingplague", label = "Brotes", desc = "Gastas Poder Runico para infligir enfermedades profanas a las criaturas que golpeas.", effects = {} },
                    { id = "levantar", icon = "spell_shadow_animatedead", label = "Levantar a los Muertos", desc = "Levantas un esbirro no-muerto que te sirve. Comparte tu cuenta de iniciativa pero toma su turno justo despues del tuyo; en su turno solo toma la accion de Esquivar salvo que uses tu accion para ordenarle otra.", effects = {} },
                },
            } },
        } },
    },
    features = {
        { id = "cdm_renacer_oscuro", level = 1, name = "Renacer oscuro", type = "pasivo", description = "Como caballero de la muerte, caminas entre el mundo de los vivos y los muertos, existiendo en ambos y en ninguno.\n- Eres considerado tanto un humanoide como un no-muerto, lo cual te permite ser afectado por cualquier cosa que afecte a esos tipos de criatura. Por ejemplo, como no-muerto, puedes ser detectado por el Sentido Divino de un paladín, pero como humanoide, puedes ser sanado por su Imposición de Manos.\n- No necesitas dormir. En su lugar, entras en un estado semi-consciente, alimentando tu hambre eterna recordando el sufrimiento causado. Después de 4 horas en este estado, obtienes los mismos beneficios que un humano tras 8 horas de sueño.\n- Ventaja en las tiradas de salvación contra cualquier efecto que afecte exclusivamente a los no-muertos, como el conjuro *Encadenar no muertos* de un sacerdote.", effects = {} },
        { id = "cdm_armas_runicas", level = 1, name = "Armas runicas", type = "informativo", description = "Sabes inscribir runas en armas, dotándolas de poder y uniéndolas a ti. Realizas un ritual de 1 hora para inscribir las runas, que puede completarse durante un descanso corto. Las armas deben estar a tu alcance durante todo el ritual. Solo puedes tener un arma de dos manos unida o dos armas de una mano. Vincular nuevas armas rompe inmediatamente el vínculo con las anteriores.\n\nNo puedes ser desarmado de tus armas rúnicas a menos que estés incapacitado. Si están en el mismo plano de existencia que tú, puedes invocarlas como acción adicional, teletransportándolas a tus manos. Si tienes dos armas rúnicas de una mano, al usar un rasgo de caballero de la muerte que se refiera a tu arma rúnica, puedes elegir cuál usar (pero no ambas).", effects = {
            -- "No puedes ser desarmado de tus armas runicas a menos que estes incapacitado."
            -- Lo comprueba el cliente del PROPIO caballero al recibir el aura de Desarme.
            { kind = "flag", flag = "cannotBeDisarmed" },
        } },
        { id = "cdm_poder_runico", level = 1, name = "Poder runico", type = "pasivo", description = "Energías necróticas recorren tu cuerpo que se representa con una reserva de d6 que se recarga tras un descanso largo. El número de dados en esta reserva es igual a 1 + nivel de caballero de la muerte. Nunca puedes gastar más dados rúnicos que Mod. Carisma (mínimo 1).", effects = {
            { kind = "resourceMax", resource = "runic_power", base = 1, perClassLevel = "caballero_muerte", perLevel = 1 },
        } },
        { id = "cdm_golpe_runico", level = 1, name = "Golpe runico", type = "recurso", description = "Cuando impactas a una criatura con un ataque cuerpo a cuerpo, puedes gastar dados de tu reserva de Poder Rúnico para infligir daño necrótico adicional al objetivo igual al resultado de los dados gastados, además del daño del arma.", effects = {
            { kind = "conditionalWeaponDamage", id = "runic_strike", label = "Golpe Runico", count = 1, die = 6, damageType = "necrotico", resourceCost = "runic_power", costPerLevel = 1, minLevel = 1, maxLevelAbility = "Carisma", countPerLevel = 1 },
        } },
        { id = "cdm_espiral_muerte", level = 1, name = "Espiral de la Muerte", cast = "accion", type = "maniobra", description = "Acción: gastas dados de Poder Rúnico y eliges una criatura visible a 36 metros. Si es NO-MUERTA, recupera puntos de golpe iguales al resultado de los dados. Si no lo es, haces un ataque de conjuro a distancia con Mod. Carisma; al impactar infliges daño necrotico igual al resultado. No puedes gastar mas dados que Mod. Carisma.", effects = {
            { kind = "energyManeuver", resource = "runic_power", cost = 1, attack = true, spendOnHit = true, dcAbility = "Carisma", levelCost = true, minLevel = 1, maxLevelAbility = "Carisma", damageDie = 6, damageType = "necrotico", outcome = "dano necrotico igual a los dados gastados" },
        } },
        { id = "cdm_estilo_combate", level = 2, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "defensa", icon = "ability_warrior_defensivestance",         label = "Defensa (+1 CA con armadura)",       effects = { { kind = "flag", flag = "styleDefense" } } },
                { id = "duelos", icon = "ability_warrior_challange",          label = "Duelos (+2 daño un arma a una mano)", effects = { { kind = "flag", flag = "styleDueling" } } },
                { id = "gran_arma", icon = "ability_warrior_cleave",       label = "Gran Lucha con Armas (repetir 1-2 a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                { id = "guerrero_profano", icon = "spell_shadow_deathanddecay", label = "Guerrero Profano (2 trucos de brujo, Carisma)", effects = {} },
                { id = "dos_armas", icon = "ability_dualwield",       label = "Combate con Dos Armas (+mod al 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
            },
        } },
        { id = "cdm_lanzamiento_conjuros", level = 2, name = "Lanzamiento de conjuros", type = "pasivo", description = "A partir del nivel 2, el poder otorgado por las fuerzas de la muerte te da habilidad con hechizos. Consulta [las reglas generales de lanzamiento de conjuros](reglas.html#conjuros); la lista de conjuros de caballero de la muerte está al final de esta ficha.\n\n### Espacios de conjuro\nLa tabla de caballero de la muerte muestra cuántos espacios de conjuro tienes para lanzar tus conjuros de caballero de la muerte de 1er a 5º nivel. Para lanzar uno de estos conjuros, debes gastar un espacio del nivel del conjuro o superior. Recuperas todos los espacios de conjuro gastados cuando terminas un descanso largo. Muchos caballeros de la muerte manifiestan sus espacios de conjuro visiblemente como runas de poder en sus armas rúnicas.\n\nPor ejemplo, si conoces el conjuro de 1er nivel *cuchillo de hielo* y tienes un espacio de conjuro de 1er nivel y uno de 2º nivel disponible, puedes lanzar *cuchillo de hielo* usando cualquiera de esos espacios.\n\n### Conjuros conocidos de 1er nivel y superiores\nConoces dos conjuros de 1er nivel de tu elección de la lista de conjuros de caballero de la muerte.\n\nLa columna de Conjuros Conocidos de la tabla de caballero de la muerte muestra cuándo aprendes más conjuros de caballero de la muerte de tu elección. Cada uno de estos conjuros debe ser de un nivel para el que tengas espacios de conjuro. Por ejemplo, cuando llegas al nivel 5 en esta clase, puedes aprender un nuevo conjuro de 1er o 2º nivel.\n\nAdemás, cuando subes de nivel en esta clase, puedes elegir uno de los conjuros de caballero de la muerte que conoces y reemplazarlo por otro de la lista de conjuros de caballero de la muerte, que también debe ser de un nivel para el que tengas espacios de conjuro.", effects = {} },
        { id = "cdm_constitucion_nomuerta", level = 3, name = "Constitucion no-muerta", type = "pasivo", description = "A partir del nivel 3, tu naturaleza no-muerta te hace inmune a las enfermedades y a la condición de envenenado, además de ser resistente al daño por veneno.", effects = {
            { kind = "resist", damage = "veneno" },
            { kind = "conditionImmunity", condition = "poisoned" },
        } },
        { id = "cdm_presencia_maligna", subclassMarker = true, level = 3, name = "Presencia maligna", type = "informativo", description = "Al alcanzar el nivel 3, te comprometes por completo con un aspecto de la muerte: Sangre, Escarcha o Profano. Tu elección te otorga rasgos en el nivel 3 y nuevamente en los niveles 7, 11, 15 y 20.\n\n### Conjuros de presencia\nCada presencia tiene una lista de conjuros asociados. Aprendes estos conjuros a los niveles especificados en la descripción de la presencia. Los conjuros de presencia no cuentan contra el número de conjuros de caballero de la muerte que puedes conocer.\n\nSi obtienes un conjuro de presencia que no aparece en la lista de conjuros de caballero de la muerte, sigue siendo un conjuro de caballero de la muerte para ti.", effects = {} },
        ASI("cdm", 4),
        { id = "cdm_ataque_extra", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "cdm_forja_runas", level = 6, name = "Forja de runas", type = "choice", description = "Al terminar un descanso largo inscribes una de estas runas en tus armas runicas. Obtienes su beneficio mientras las empunes. Solo puedes tener UNA runa activa a la vez.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "glaciar_ceniza", icon = "spell_frost_glacier", label = "Runa de Glaciar de Ceniza", desc = "Cuando golpeas a una criatura con un ataque de arma, tiene desventaja en cualquier tirada de salvacion que haga contra tus rasgos y conjuros de caballero de la muerte hasta tu proximo turno.", effects = {  } },
                { id = "cruzado_caido", icon = "spell_holy_retributionaura", label = "Runa del Cruzado Caido", desc = "Cuando logras un golpe critico o reduces a una criatura a 0 puntos de golpe con un ataque de arma, puedes curarte de inmediato con espiral de la muerte como parte de la misma accion, recuperando puntos de golpe iguales al DOBLE del resultado de los dados de poder runico gastados.", effects = {  } },
                { id = "juramento_liche", icon = "spell_shadow_raisedead", label = "Runa del Juramento del Liche", desc = "Obtienes un bono de +2 a tu modificador de ataque con conjuros.", effects = { { kind = "bonus", target = "spellAttack", value = 2 } } },
                { id = "rompeconjuros", icon = "spell_shadow_antimagicshell", label = "Runa de Rompeconjuros", desc = "Obtienes resistencia al dano infligido por conjuros.", effects = {  } },
                { id = "rompespadas", icon = "ability_warrior_disarm", label = "Runa de Rompespadas", desc = "Obtienes un bono de +2 a tu Clase de Armadura.", effects = { { kind = "bonus", target = "armorClass", value = 2 } } },
                { id = "caminante_espectral", icon = "spell_deathknight_frozenruneweapon", label = "Runa de Caminante Espectral", desc = "Tu velocidad de movimiento aumenta en 3 metros y obtienes un bono a tu iniciativa igual a tu modificador de Carisma (minimo +1).", effects = { { kind = "bonus", target = "speed", value = 3 } } },
        } } },
                { id = "cdm_voluntad_de_la_tumba", icon = "spell_holy_senseundead", level = 10, name = "Voluntad de la Tumba", type = "informativo", description = "A partir del nivel 10, no puedes ser encantado ni asustado mientras estés consciente.", effects = {} },
        { id = "cdm_sin_muerte", icon = "ability_creature_cursed_02", level = 14, name = "Sin Muerte", type = "informativo", description = "A partir del nivel 14, no necesitas comer, beber ni respirar. Además, envejeces a un ritmo más lento. Por cada 10 años que pasan, tu cuerpo solo envejece 1 año, y eres inmune al envejecimiento mágico.", effects = {} },
        { id = "cdm_forja_de_runas_superior", icon = "inv_misc_rune_10", level = 18, name = "Forja de Runas Superior", type = "informativo", description = "Al alcanzar el nivel 18, puedes inscribir dos runas diferentes en tus armas rúnicas al mismo tiempo (según lo descrito en tu rasgo de Forja de Runas), y ambas pueden ser cambiadas cuando completes un descanso largo.", effects = {} },
    },
}
