-- Caballero de la Muerte: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "caballero_muerte", name = "Caballero de la Muerte", desc = "Antiguo campeon caido y resucitado que empuna poder runico y magia profana, de escarcha y de sangre para dominar el campo de batalla.", hitDie = 10, casterType = "half", startingGold = { dice = 4, sides = 4, multiplier = 1 },
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
                { id = "cdm_sangre_conjuros_3", level = 3, name = "Conjuros de presencia (Sangre)", type = "informativo", grantedSpells = { "orden_imperiosa", "agarre_de_la_muerte" }, description = "Nivel 3: Orden imperiosa (mandato) y Agarre de la muerte. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", effects = {} },
                { id = "cdm_sangre_conjuros_5", level = 5, name = "Conjuros de presencia (Sangre)", type = "informativo", grantedSpells = { "hervor_de_sangre", "inmovilizar_persona" }, description = "Nivel 5: Hervor de sangre y Inmovilizar persona. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", effects = {} },
            { id = "cdm_comando_oscuro", level = 3, name = "Orden oscura", type = "informativo", description = "Al dañar con Poder Runico, la criatura tiene desventaja en ataques contra otros que no seas tu hasta el final de tu próximo turno.", effects = {
                    -- El dano condicional `runic_strike` es de CLASE (Golpe runico, N1) y este
                    -- rasgo es de subclase N3: la condicion no puede colgar del dano, o la
                    -- tendrian todos los caballeros desde nivel 1. Cuelga del rasgo como rider.
                    { kind = "conditionalDamageRider", conditionalId = "runic_strike",
                      conditionId = "orden_oscura", duration = "fin de tu proximo turno" },
                } },
            { id = "cdm_escudo_sangre", level = 3, name = "Escudo de Sangre", type = "informativo", description = "Al lanzar un conjuro de 1er nivel o superior creas un escudo de sangre (PG = 2x nivel CdM + Mod. Carisma) que absorbe daño. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                        { id = "sangre_tormenta_de_huesos", level = 7, name = "Tormenta de Huesos", type = "informativo", description = "A partir del nivel 7, puedes usar tu acción para invocar un torbellino de huesos afilados a tu alrededor. La tormenta tiene un radio de 6,1 metros y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Destreza. Si falla, la criatura recibe daño perforante mágico igual a 1d6 + tu nivel de caballero de la muerte y cae derribada. Si tiene éxito, recibe la mitad del daño y no sufre otros efectos. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso corto o largo.", effects = {} },
            { id = "sangre_golpe_al_corazon", level = 11, name = "Golpe al Corazón", type = "informativo", description = "En el nivel 11, tu poder oscuro refuerza tus ataques. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 de arma. Además, el daño infligido por tus armas rúnicas ignora resistencias.", effects = {} },
            { id = "sangre_purgatorio", level = 15, name = "Purgatorio", type = "informativo", description = "A partir del nivel 15, cuando seas reducido a 0 puntos de golpe y no mueras instantáneamente, puedes optar por quedar con 1 punto de golpe en su lugar y reponer los puntos de golpe de tu escudo de sangre al doble de tu nivel de caballero de la muerte. Una vez que uses esta habilidad, no podrás volver a usarla hasta que termines un descanso largo.", effects = {} },
            { id = "sangre_arma_runica_danza", level = 20, name = "Arma Rúnica Danza", type = "informativo", description = "En el nivel 20, puedes invocar una copia espectral de tu arma rúnica, que danza de manera amenazante en tu espacio. El arma rúnica danzante dura 1 minuto y es idéntica a tu arma rúnica. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo. Al comienzo de cada uno de tus turnos, puedes comandar a tu arma rúnica danzante para que actúe de una de las siguientes maneras hasta el inicio de tu próximo turno (no se requiere acción). ***Defensivamente.*** Obtienes los beneficios de la acción de Esquivar. Además, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en tu turno. Puedes usar esta reacción especial cuando una criatura que puedas ver realiza un ataque contra un objetivo que no seas tú y que esté a 3 metros de ti, imponiendo desventaja en la tirada de ataque.", effects = {} },
        } },
        { id = "escarcha", name = "Escarcha", desc = "Doble empunadura y magia de hielo para ralentizar y despedazar.", features = {
                { id = "cdm_escarcha_conjuros_3", level = 3, name = "Conjuros de presencia (Escarcha)", type = "informativo", grantedSpells = { "armadura_de_agathys", "toque_helado_nivel_1" }, description = "Nivel 3: Armadura de Agathys y Toque helado. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", effects = {} },
                { id = "cdm_escarcha_conjuros_5", level = 5, name = "Conjuros de presencia (Escarcha)", type = "informativo", grantedSpells = { "explosion_aullante", "viento_guardian" }, description = "Nivel 5: Explosion aullante y Viento guardian (viento protector). Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", effects = {} },
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
                { id = "cdm_profana_conjuros_3", level = 3, name = "Conjuros de presencia (Profana)", type = "informativo", grantedSpells = { "explosion_de_cadaveres", "rayo_de_enfermedad" }, description = "Nivel 3: Explosion de cadaveres y Rayo de enfermedad. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", effects = {} },
                { id = "cdm_profana_conjuros_5", level = 5, name = "Conjuros de presencia (Profana)", type = "informativo", grantedSpells = { "cascara_antimagica", "rayo_debilitador" }, description = "Nivel 5: Caparazon antimagia y Rayo debilitador. Los conjuros de presencia NO cuentan contra los conjuros de caballero de la muerte que puedes conocer.", effects = {} },
            { id = "cdm_portador_plagas", level = 3, name = "Portador de plagas", type = "choice", companionId = "esbirro_no_muerto", description = "Eliges Brotes o Levantar a los Muertos.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "brotes", label = "Brotes", desc = "Gastas Poder Runico para infligir enfermedades profanas a las criaturas que golpeas.", effects = {} },
                    { id = "levantar", label = "Levantar a los Muertos", desc = "Levantas un esbirro no-muerto que te sirve. Comparte tu cuenta de iniciativa pero toma su turno justo despues del tuyo; en su turno solo toma la accion de Esquivar salvo que uses tu accion para ordenarle otra.", effects = {} },
                },
            } },
        } },
    },
    features = {
        { id = "cdm_renacer_oscuro", level = 1, name = "Renacer oscuro", type = "informativo", description = "Eres humanoide y no-muerto a la vez. No duermes (4h de trance = 8h de sueño). Ventaja en salvaciones contra efectos exclusivos de no-muertos.", effects = {} },
        { id = "cdm_armas_runicas", level = 1, name = "Armas runicas", type = "informativo", description = "Vinculas armas runicas (un arma a dos manos o dos de una mano). No te pueden desarmar salvo incapacitado; las invocas como acción adicional.", effects = {
            -- "No puedes ser desarmado de tus armas runicas a menos que estes incapacitado."
            -- Lo comprueba el cliente del PROPIO caballero al recibir el aura de Desarme.
            { kind = "flag", flag = "cannotBeDisarmed" },
        } },
        { id = "cdm_poder_runico", level = 1, name = "Poder runico", type = "pasivo", description = "Reserva de dados d6 (1 + nivel CdM) que recarga en descanso largo; no gastas mas dados que tu Mod. Carisma. Alimenta Espiral de la Muerte y Golpe Runico.", effects = {
            { kind = "resourceMax", resource = "runic_power", base = 1, perClassLevel = "caballero_muerte", perLevel = 1 },
        } },
        { id = "cdm_golpe_runico", level = 1, name = "Golpe runico", type = "recurso", description = "Al impactar con un ataque con arma, gastas dados de Poder Runico para infligir daño necrótico adicional. No puedes gastar mas dados que tu Mod. Carisma.", effects = {
            { kind = "conditionalWeaponDamage", id = "runic_strike", label = "Golpe Runico", count = 1, die = 6, damageType = "necrotico", resourceCost = "runic_power", costPerLevel = 1, minLevel = 1, maxLevelAbility = "Carisma", countPerLevel = 1 },
        } },
        { id = "cdm_espiral_muerte", level = 1, name = "Espiral de la Muerte", type = "maniobra", description = "Accion: gastas dados de Poder Runico y eliges una criatura visible a 36 metros. Si es NO-MUERTA, recupera puntos de golpe iguales al resultado de los dados. Si no lo es, haces un ataque de conjuro a distancia con Mod. Carisma; al impactar infliges dano necrotico igual al resultado. No puedes gastar mas dados que tu Mod. Carisma.", effects = {
            { kind = "energyManeuver", resource = "runic_power", cost = 1, attack = true, spendOnHit = true, dcAbility = "Carisma", levelCost = true, minLevel = 1, maxLevelAbility = "Carisma", damageDie = 6, damageType = "necrotico", outcome = "dano necrotico igual a los dados gastados" },
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
        { id = "cdm_forja_runas", level = 6, name = "Forja de runas", type = "choice", description = "Al terminar un descanso largo inscribes una de estas runas en tus armas runicas. Obtienes su beneficio mientras las empunes. Solo puedes tener UNA runa activa a la vez.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "glaciar_ceniza", label = "Runa de Glaciar de Ceniza", desc = "Cuando golpeas a una criatura con un ataque de arma, tiene desventaja en cualquier tirada de salvacion que haga contra tus rasgos y conjuros de caballero de la muerte hasta tu proximo turno.", effects = {  } },
                { id = "cruzado_caido", label = "Runa del Cruzado Caido", desc = "Cuando logras un golpe critico o reduces a una criatura a 0 puntos de golpe con un ataque de arma, puedes curarte de inmediato con espiral de la muerte como parte de la misma accion, recuperando puntos de golpe iguales al DOBLE del resultado de los dados de poder runico gastados.", effects = {  } },
                { id = "juramento_liche", label = "Runa del Juramento del Liche", desc = "Obtienes un bono de +2 a tu modificador de ataque con conjuros.", effects = { { kind = "bonus", target = "spellAttack", value = 2 } } },
                { id = "rompeconjuros", label = "Runa de Rompeconjuros", desc = "Obtienes resistencia al dano infligido por conjuros.", effects = {  } },
                { id = "rompespadas", label = "Runa de Rompespadas", desc = "Obtienes un bono de +2 a tu Clase de Armadura.", effects = { { kind = "bonus", target = "armorClass", value = 2 } } },
                { id = "caminante_espectral", label = "Runa de Caminante Espectral", desc = "Tu velocidad de movimiento aumenta en 3 metros y obtienes un bono a tu iniciativa igual a tu modificador de Carisma (minimo +1).", effects = { { kind = "bonus", target = "speed", value = 3 } } },
        } } },
                { id = "caballero_mu_voluntad_de_la_tumba", level = 10, name = "Voluntad de la Tumba", type = "informativo", description = "A partir del nivel 10, no puedes ser encantado ni asustado mientras estés consciente.", effects = {} },
        { id = "caballero_mu_sin_muerte", level = 14, name = "Sin Muerte", type = "informativo", description = "A partir del nivel 14, no necesitas comer, beber ni respirar. Además, envejeces a un ritmo más lento. Por cada 10 años que pasan, tu cuerpo solo envejece 1 año, y eres inmune al envejecimiento mágico.", effects = {} },
        { id = "caballero_mu_forja_de_runas_superior", level = 18, name = "Forja de Runas Superior", type = "informativo", description = "Al alcanzar el nivel 18, puedes inscribir dos runas diferentes en tus armas rúnicas al mismo tiempo (según lo descrito en tu rasgo de Forja de Runas), y ambas pueden ser cambiadas cuando completes un descanso largo.", effects = {} },
    },
}
