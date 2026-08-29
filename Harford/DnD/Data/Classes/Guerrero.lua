-- Guerrero: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects
local ManeuverEffects = API.ManeuverEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "guerrero", name = "Guerrero", desc = "Maestro de las armas y la armadura, versatil en el combate cuerpo a cuerpo y a distancia, puro musculo y tecnica.", hitDie = 10, startingGold = { dice = 5, sides = 4, multiplier = 1 },
    saves = { "Fuerza", "Constitucion" },
    armorProfs = { "ligera", "media", "pesada", "escudo" },
    weaponProfs = { "sencillas", "marciales", "armas de fuego" },
    -- Equipo inicial: cada grupo es una eleccion; cada opcion, los objetos que aporta.
    startingEquipment = {
        { label = "Armadura", options = {
            { label = "Cota de escamas", items = { "Cota de escamas" } },
            { label = "Cota de malla", items = { "Cota de malla" } },
        } },
        { label = "Arma principal", options = {
            { label = "Un arma marcial y un escudo", items = { { pick = "Marcial" }, "Escudo" } },
            { label = "Dos armas marciales", items = { { pick = "Marcial" }, { pick = "Marcial" } } },
        } },
        { label = "Arma secundaria", options = {
            { label = "Una ballesta ligera y 20 virotes", items = { "Ballesta ligera", "20 virotes" } },
            { label = "Dos hachas de mano", items = { "Hacha de mano", "Hacha de mano" } },
        } },
        { label = "Paquete", options = {
            { label = "Paquete de aventurero", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase: cuantas se eligen y de que lista (manual del Guerrero).
    skillChoices = 2,
    skillOptions = { "Acrobacias", "Animales", "Atletismo", "Historia", "Perspicacia",
        "Intimidacion", "Percepcion", "Supervivencia" },
    subclasses = {
        { id = "armas", name = "Armas", desc = "Maestria tecnica con armas pesadas y golpes precisos.", features = {
            { id = "gue_arm_arrollar", level = 3, name = "Arrollar", cast = "reaccion", type = "informativo", description = "A partir de que elijas este arquetipo al nivel 3, aprendes a usar tu arma como barrera. Cuando recibas un ataque cuerpo a cuerpo, puedes usar tu reacción para tirar 1d10 y sumar el resultado a tu CA. Si tu arrollamiento hace que el ataque falle, puedes realizar un ataque de arma contra el objetivo como parte de la misma reacción.\n\nPuedes usar esta característica dos veces. Recuperas los usos gastados al completar un descanso corto o largo.", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "gue_arm_intrepido", level = 3, name = "Intrepido", type = "informativo", description = "Al nivel 3, tu furia se regenera a medida que la viertes en tus ataques. Recuperas 1 punto de furia al final de tu turno si golpeas a una criatura con un movimiento de furia durante el mismo.", effects = {
            { kind = "resourceGain", resource = "rage", amount = 1, trigger = "rage_maneuver_hit", featureId = "gue_arm_intrepido",
              note = "Intrepido" },
        } },
                        { id = "gue_arm_grito_de_mando", icon = "ability_warrior_rallyingcry", level = 7, name = "Grito de Mando", type = "informativo", description = "A partir del nivel 7, puedes comandar a un aliado para que ataque a tu objetivo. Como acción adicional, elige a una criatura aliada a 18 metros de ti que pueda verte o escucharte. Esa criatura puede usar su reacción para realizar un ataque cuerpo a cuerpo.", effects = {} },
            { id = "gue_arm_golpe_colosal", icon = "ability_warrior_colossussmash", level = 11, name = "Golpe Colosal", type = "informativo", description = "Al alcanzar el nivel 11, cuando impactes a una criatura con un ataque cuerpo a cuerpo en tu turno, puedes destruir sus defensas y otorgar ventaja al próximo ataque de arma contra ese objetivo antes del final de tu próximo turno. Solo puedes usar Golpe Colosal una vez en cada turno.", effects = {} },
            { id = "gue_arm_calma_mortal", icon = "ability_warrior_savageblow", level = 15, name = "Calma Mortal", type = "informativo", description = "A partir del nivel 15, instintivamente adoptas una postura defensiva en situaciones críticas. Mientras estés por debajo de la mitad de tus puntos de golpe máximos, tienes ventaja en las tiradas de salvación de Fuerza, Destreza o Constitución.", effects = {} },
            { id = "gue_arm_golpes_de_oportunidad", icon = "ability_warrior_savageblow", level = 18, name = "Golpes de Oportunidad", type = "informativo", description = "En el nivel 18, respondes con ferocidad a las aperturas en las defensas del enemigo. En combate, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en el tuyo. Solo puedes usar esta reacción para realizar un ataque de oportunidad, y no puedes usarla en el mismo turno en el que uses tu reacción normal.", effects = {} },
        } },
        { id = "furia", name = "Ira", desc = "Berserker de doble empunadura que ataca con ira incontenible.", features = {
            { id = "gue_fur_desatada", level = 3, name = "Ira desatada", cast = "ninguna", type = "accion", actionKind = "unleashedRage", description = "En tu primer ataque del turno puedes desatar tu ira: ventaja en ataques cuerpo a cuerpo con Fuerza ese turno, pero los ataques contra ti tienen ventaja hasta tu próximo turno.", effects = {} },
            { id = "gue_fur_temible", level = 3, name = "Temible", type = "pasivo", description = "Al nivel 3, obtienes competencia en la habilidad de Intimidación si no la tienes ya. Cuando hagas una prueba de esta habilidad, puedes elegir usar Mod. Fuerza en lugar de Mod. Carisma.", effects = { { kind = "skillProf", skill = "Intimidacion" } } },
                        { id = "gue_fur_furia_focalizada", icon = "ability_warrior_focusedrage", level = 7, name = "Ira Focalizada", type = "informativo", description = "A partir del nivel 7, tu fuerza bruta te permite manejar armas con una potencia incomparable. Cuando uses un arma que inflige un único dado de daño, el dado de daño se incrementa en 1. Por ejemplo, una espada corta que normalmente inflige 1d6 de daño, en su lugar inflige 1d8 de daño. El dado de daño de un arma no puede incrementarse más allá de 1d12.", effects = {} },
            { id = "gue_fur_sed_de_sangre", icon = "spell_nature_bloodlust", level = 11, name = "Sed de Sangre", type = "informativo", description = "Al nivel 11, cuando una criatura hostil a 6 metros de ti reciba daño, puedes usar tu reacción para moverte hasta la mitad de tu velocidad hacia ella sin provocar ataques de oportunidad. Si este movimiento te pone al alcance de la criatura, puedes realizar un ataque de arma contra ella como parte de la reacción.", effects = {} },
            { id = "gue_fur_critico_devastador", icon = "ability_warrior_rampage", level = 15, name = "Crítico Devastador", type = "informativo", description = "A partir del nivel 15, cuando consigas un golpe crítico con un ataque de arma, sumas un bono al daño igual a tu nivel en esta clase.", effects = {} },
            { id = "gue_fur_berserker_enloquecido", icon = "ability_warrior_innerrage", level = 18, name = "Berserker Enloquecido", type = "informativo", description = "En el nivel 18, si recibes daño que te reduce a 0 puntos de golpe y no te mata de inmediato, puedes usar tu reacción para retrasar la pérdida de consciencia y tomar un turno adicional de inmediato. Mientras tengas 0 puntos de golpe durante ese turno adicional, recibir daño provoca fallos en las tiradas de salvación de muerte como es habitual, y tres fallos pueden matarte. Al terminar el turno adicional, caes inconsciente si aún tienes 0 puntos de golpe. Una vez que uses esta característica, no puedes volver a usarla hasta que completes un descanso largo.", effects = {} },
        } },
        { id = "proteccion", name = "Proteccion", desc = "Tanque con escudo que protege a sus aliados.", features = {
            { id = "gue_pro_provocacion", level = 3, name = "Provocacion", cast = "accion", type = "informativo", description = "A partir de que elijas este arquetipo al nivel 3, puedes usar tu acción para provocar a criaturas en un radio de 9 metros. Toda criatura que elijas en el rango debe superar una tirada de salvación de Sabiduría contra la CD de tu Furia o tener desventaja en las tiradas de ataque contra criaturas que no seas tú durante 1 minuto. Una criatura puede repetir la salvación al final de cada uno de sus turnos, terminando el efecto si tiene éxito.\n\nUna vez que uses esta característica, no puedes volver a usarla hasta que completes un descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "gue_pro_control", level = 3, name = "Control de ira", type = "informativo", description = "Al nivel 3, tu furia se renueva con los golpes que recibes. Cuando una criatura hostil te golpea con un ataque, ganas 1 punto de furia de inmediato. Solo puedes beneficiarte de este efecto una vez por turno.", effects = {
            -- Lo resuelve el cliente del propio guerrero al recibir el dano.
            { kind = "resourceGain", resource = "rage", amount = 1, trigger = "damage_taken", featureId = "gue_pro_control",
              note = "Control de ira, 1 vez por turno" },
        } },
                        { id = "gue_pro_interceptar", icon = "ability_warrior_charge", level = 7, name = "Interceptar", type = "informativo", description = "A partir del nivel 7, cuando una criatura que puedes ver ataque a un objetivo que no seas tú y que esté a 1,5 metros de ti, puedes usar tu reacción para interceptar el ataque, forzando al atacante a dirigirse a ti en su lugar. Puedes usar esta característica un número de veces igual a Mod. Constitución (mínimo de 1). Recuperas todos los usos gastados al completar un descanso largo.", effects = {} },
            { id = "gue_pro_golpes_atenuados", icon = "ability_warrior_shieldguard", level = 11, name = "Golpes Atenuados", type = "informativo", description = "A partir del nivel 11, incluso los golpes más fuertes no quebrarán tu defensa. Todo golpe crítico contra ti se convierte en un golpe normal y tienes ventaja en cualquier prueba o tirada de salvación para evitar ser derribado.", effects = {} },
            { id = "gue_pro_presencia_inspiradora", icon = "spell_holy_devotionaura", level = 15, name = "Presencia Inspiradora", type = "informativo", description = "A partir del nivel 15, puedes extender el beneficio de tu rasgo Indomable a un aliado. Cuando uses Indomable para repetir una tirada de salvación de Inteligencia, Sabiduría o Carisma y no estés incapacitado, puedes elegir a un aliado a 18 metros de ti que también haya fallado la tirada contra el mismo efecto. Si puede verte u oírte, puede repetir su tirada de salvación y debe usar el nuevo resultado.", effects = {} },
            { id = "gue_pro_nunca_te_rindas", icon = "ability_warrior_defensivestance", level = 18, name = "Nunca Te Rindas", type = "informativo", description = "Al nivel 18, siempre que comiences tu turno con menos de la mitad de tus puntos de golpe máximos, ganas 1d10 + Mod. Constitución en puntos de golpe temporales. No obtienes este beneficio si tienes 0 puntos de golpe.", effects = {} },
        } },
    },
    features = {
        { id = "gue_estilo_combate", level = 1, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad. Elige una opcion.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "defensa", icon = "ability_warrior_defensivestance",    label = "Defensa (+1 CA con armadura)",          effects = { { kind = "flag", flag = "styleDefense" } } },
                { id = "duelo", icon = "ability_warrior_challange",      label = "Duelo (+2 daño un arma a una mano)",    effects = { { kind = "flag", flag = "styleDueling" } } },
                { id = "gran_arma", icon = "ability_warrior_cleave",  label = "Gran Arma (repetir 1-2 en daño a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                { id = "proteccion", label = "Proteccion (desventaja a atacantes, con escudo)", effects = {} },
                { id = "dos_armas", icon = "ability_dualwield",  label = "Combate con Dos Armas (+mod al daño del 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                { id = "tiro_arco", icon = "ability_marksmanship", label = "Tiro con Arco (+2 ataque a distancia)", effects = { { kind = "flag", flag = "styleArchery" } } },
                { id = "tirador", icon = "ability_hunter_snipershot", label = "Tirador en Combate Cercano (+1 ataque a distancia, ignora cobertura)", effects = { { kind = "flag", flag = "styleSharpshooter" } } },
            },
        } },
        { id = "gue_segundo_aliento", level = 1, name = "Segundo aliento", cast = "accion_adicional", type = "accion", description = "Acción adicional: gasta un dado de golpe d10 para recuperar PG (tirada + Mod. Constitución).", actionKind = "secondWind", effects = {} },
        { id = "gue_furia_interna", level = 2, name = "Ira interna", type = "pasivo", description = "Ganas puntos de Ira al dañar con armas; los gastas en maniobras. Máximo de Ira = tu nivel de Guerrero. Los puntos acumulados permanecen 1 hora antes de disiparse, devolviendo tu reserva de ira a 0. CD de Ira = 8 + competencia + Mod. Fuerza.", effects = {
            { kind = "resourceMax", resource = "rage", perClassLevel = "guerrero", base = 0, perLevel = 1 },
        } },
        { id = "guerrero_reserva_ira", icon = "ability_warrior_focusedrage", level = 2, name = "Reserva de ira", cast = "accion_adicional", type = "recurso", description = "Puedes usar una acción adicional en tu turno para aprovechar tu reserva interna de ira y ganar un número de puntos de ira. Una vez que uses tu reserva de ira, no puedes volver a usarla hasta que completes un descanso corto o largo.", uses = { max = 1, recharge = "short" },
            -- Puntos que devuelve, por nivel de Guerrero (tabla del manual). Van dentro de
            -- `grant` porque es lo que el motor de concesion lee: declarados aparte, nadie los
            -- miraba y el rasgo gastaba su uso sin dar nada de ira.
            grant = { self = true, resource = "rage", noun = "puntos de ira",
                byClassLevel = { classId = "guerrero",
                    values = { [2] = 1, [3] = 2, [4] = 2, [5] = 3, [6] = 3 } } }, effects = {} },
        { id = "guerrero_man_golpe_heroico", icon = "ability_warrior_punishingblow", level = 2, name = "Golpe heroico", type = "maniobra", description = "Cuando hagas daño con un ataque de arma cuerpo a cuerpo, puedes gastar 1 o más puntos de ira para volver a tirar 1 dado de daño por cada punto de ira gastado. Debes usar el nuevo resultado.", effects = {
            { kind = "energyManeuver", resource = "rage", cost = 1, levelCost = true, minLevel = 1, maxLevel = 6, attack = true, spendOnHit = true, rerollDamage = true },
        } },
        { id = "guerrero_man_desarme", icon = "ability_warrior_disarm", level = 2, name = "Desarme", type = "maniobra", description = "Puedes gastar 2 puntos de furia cuando hagas una tirada de ataque para intentar un golpe desarmador. Si el ataque impacta, infliges daño normal y el objetivo suelta un objeto de tu elección que esté sujetando.", effects = {
            { kind = "energyManeuver", resource = "rage", cost = 2, attack = true, spendOnHit = true, outcome = "suelta el objeto", onHitAura = 177714, conditionId = "disarmed" },
        } },
        { id = "guerrero_man_carga", icon = "ability_warrior_charge", level = 2, name = "Carga", type = "maniobra", description = "Cuando realizas la acción de Correr y te desplazas al menos 6 metros hacia un objetivo, puedes gastar 1 punto de furia y realizar un ataque de arma contra él como parte de la acción de Correr. Este ataque se realiza con ventaja.", effects = {
            { kind = "energyManeuver", resource = "rage", cost = 1, spendOnHit = true, attack = true },
        } },
        { id = "guerrero_maniobras_3", icon = "ability_warrior_challange", level = 3, name = "Maniobras conocidas", type = "choice", description = "Aprendes maniobras de ira a tu eleccion, ademas de Carga, Desarme y Golpe heroico, que no se pueden cambiar.", effects = {}, choice = {
            slots = 2,
            options = {
                { id = "ira_berserker", label = "Ira berserker", icon = "ability_warrior_rampage", desc = "Puedes usar tu acción y gastar 3 puntos de ira para finalizar un efecto que te esté encantando o asustando.", maneuver = { cost = 3, noTarget = true }, effects = {} },
                { id = "sed_de_sangre", label = "Sed de sangre", icon = "ability_warrior_bloodbath", desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 3 puntos de ira para fortalecerte en el momento. Al hacerlo, ganas puntos de golpe temporales iguales a 1d8 + tu nivel de Guerrero. Estos puntos duran 1 minuto.", maneuver = { cost = 3, attack = true, spendOnHit = true, outcome = "PG temporales 1d8 + nivel" }, effects = {} },
                { id = "cuchillada", label = "Cuchillada", icon = "ability_warrior_cleave", requiresLevel = 6, desc = "Cuando golpeas a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 4 puntos de ira para intentar atacar a otra criatura en el mismo ataque. Elige otra criatura a 5 pies del objetivo original y dentro de tu alcance. Si la tirada de ataque original impactaria al segundo objetivo, realiza el daño como un ataque normal.", maneuver = { cost = 4, attack = true, spendOnHit = true, outcome = "golpea a una segunda criatura" }, effects = {} },
                { id = "heridas_profundas", label = "Heridas profundas", icon = "ability_rogue_bloodsplatter", requiresLevel = 6, desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar infligir una herida profunda. El objetivo debe superar una tirada de salvación de Constitución o perder 1d4 puntos de golpe debido a la pérdida de sangre. La herida profunda dura 1 minuto. Al final de su turno, el objetivo pierde otros 1d4 puntos de golpe y repite la salvación, deteniendo la hemorragia si tiene éxito.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Constitucion", dcAbility = "Fuerza", outcome = "Herida profunda", damageDie = 4 }, effects = {} },
                { id = "ejecutar", label = "Ejecutar", icon = "inv_sword_48", requiresLevel = 6, desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 6 puntos de ira para convertir tu ataque en un golpe crítico. Esto no tiene efecto si la tirada de ataque ya era crítica.", maneuver = { cost = 6, attack = true, spendOnHit = true, outcome = "convierte el impacto en critico" }, effects = {} },
                { id = "golpe_potente", label = "Golpe potente", icon = "ability_warrior_shockwave", desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar forzar a un objetivo a retroceder. Si el objetivo es Grande o más pequeño, debe realizar una tirada de salvación de Fuerza. Si falla, lo empujas hasta 10 pies de distancia.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Fuerza", dcAbility = "Fuerza", outcome = "empujado 3 metros" }, effects = {} },
                { id = "corte_tendones", label = "Corte tendones", icon = "ability_rogue_trip", desc = "Cuando golpees a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar derribar al objetivo. Si el objetivo es Grande o más pequeño, debe superar una tirada de salvación de Fuerza. Si falla, lo derribas.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Fuerza", dcAbility = "Fuerza", outcome = "Derribado", onFailAura = 267937, conditionId = "prone" }, effects = {} },
                { id = "ignorar_dolor", label = "Ignorar dolor", icon = "ability_warrior_shieldwall", desc = "Puedes usar tu reacción y gastar 3 puntos de ira cuando recibas un ataque de arma para darte resistencia al daño contundente, perforante y cortante hasta el inicio de tu próximo turno.", maneuver = { cost = 3, noTarget = true }, effects = {} },
                { id = "golpe_mortal", label = "Golpe mortal", icon = "ability_warrior_savageblow", desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar asestar un golpe mortal. El objetivo debe superar una tirada de salvación de Constitución o no podrá recuperar puntos de golpe hasta el inicio de tu próximo turno.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Constitucion", dcAbility = "Fuerza", outcome = "no recupera PG" }, effects = {} },
                { id = "embate_escudo", label = "Embate con escudo", icon = "ability_warrior_shieldbash", desc = "Cuando golpees a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira y usar tu acción adicional para golpear al objetivo con tu escudo, infligiendo daño igual a 1d4 + tu modificador de Fuerza. Para ello, debes llevar un escudo.", maneuver = { cost = 2, attack = true, spendOnHit = true, outcome = "1d4 + Mod. Fuerza con el escudo" }, effects = {} },
            },
        } },
        { id = "guerrero_maniobras_6", icon = "ability_warrior_challange", level = 6, name = "Maniobra adicional", type = "choice", description = "Aprendes una maniobra de ira mas.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "ira_berserker", label = "Ira berserker", icon = "ability_warrior_rampage", desc = "Puedes usar tu acción y gastar 3 puntos de ira para finalizar un efecto que te esté encantando o asustando.", maneuver = { cost = 3, noTarget = true }, effects = {} },
                { id = "sed_de_sangre", label = "Sed de sangre", icon = "ability_warrior_bloodbath", desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 3 puntos de ira para fortalecerte en el momento. Al hacerlo, ganas puntos de golpe temporales iguales a 1d8 + tu nivel de Guerrero. Estos puntos duran 1 minuto.", maneuver = { cost = 3, attack = true, spendOnHit = true, outcome = "PG temporales 1d8 + nivel" }, effects = {} },
                { id = "cuchillada", label = "Cuchillada", icon = "ability_warrior_cleave", requiresLevel = 6, desc = "Cuando golpeas a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 4 puntos de ira para intentar atacar a otra criatura en el mismo ataque. Elige otra criatura a 5 pies del objetivo original y dentro de tu alcance. Si la tirada de ataque original impactaria al segundo objetivo, realiza el daño como un ataque normal.", maneuver = { cost = 4, attack = true, spendOnHit = true, outcome = "golpea a una segunda criatura" }, effects = {} },
                { id = "heridas_profundas", label = "Heridas profundas", icon = "ability_rogue_bloodsplatter", requiresLevel = 6, desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar infligir una herida profunda. El objetivo debe superar una tirada de salvación de Constitución o perder 1d4 puntos de golpe debido a la pérdida de sangre. La herida profunda dura 1 minuto. Al final de su turno, el objetivo pierde otros 1d4 puntos de golpe y repite la salvación, deteniendo la hemorragia si tiene éxito.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Constitucion", dcAbility = "Fuerza", outcome = "Herida profunda", damageDie = 4 }, effects = {} },
                { id = "ejecutar", label = "Ejecutar", icon = "inv_sword_48", requiresLevel = 6, desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 6 puntos de ira para convertir tu ataque en un golpe crítico. Esto no tiene efecto si la tirada de ataque ya era crítica.", maneuver = { cost = 6, attack = true, spendOnHit = true, outcome = "convierte el impacto en critico" }, effects = {} },
                { id = "golpe_potente", label = "Golpe potente", icon = "ability_warrior_shockwave", desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar forzar a un objetivo a retroceder. Si el objetivo es Grande o más pequeño, debe realizar una tirada de salvación de Fuerza. Si falla, lo empujas hasta 10 pies de distancia.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Fuerza", dcAbility = "Fuerza", outcome = "empujado 3 metros" }, effects = {} },
                { id = "corte_tendones", label = "Corte tendones", icon = "ability_rogue_trip", desc = "Cuando golpees a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar derribar al objetivo. Si el objetivo es Grande o más pequeño, debe superar una tirada de salvación de Fuerza. Si falla, lo derribas.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Fuerza", dcAbility = "Fuerza", outcome = "Derribado", onFailAura = 267937, conditionId = "prone" }, effects = {} },
                { id = "ignorar_dolor", label = "Ignorar dolor", icon = "ability_warrior_shieldwall", desc = "Puedes usar tu reacción y gastar 3 puntos de ira cuando recibas un ataque de arma para darte resistencia al daño contundente, perforante y cortante hasta el inicio de tu próximo turno.", maneuver = { cost = 3, noTarget = true }, effects = {} },
                { id = "golpe_mortal", label = "Golpe mortal", icon = "ability_warrior_savageblow", desc = "Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar asestar un golpe mortal. El objetivo debe superar una tirada de salvación de Constitución o no podrá recuperar puntos de golpe hasta el inicio de tu próximo turno.", maneuver = { cost = 2, attack = true, spendOnHit = true, save = "Constitucion", dcAbility = "Fuerza", outcome = "no recupera PG" }, effects = {} },
                { id = "embate_escudo", label = "Embate con escudo", icon = "ability_warrior_shieldbash", desc = "Cuando golpees a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira y usar tu acción adicional para golpear al objetivo con tu escudo, infligiendo daño igual a 1d4 + tu modificador de Fuerza. Para ello, debes llevar un escudo.", maneuver = { cost = 2, attack = true, spendOnHit = true, outcome = "1d4 + Mod. Fuerza con el escudo" }, effects = {} },
            },
        } },
        { id = "gue_arquetipo_marcial", subclassMarker = true, level = 3, name = "Arquetipo marcial", type = "informativo", description = "Al alcanzar el nivel 3, eliges un arquetipo marcial que buscas emular en tus estilos y técnicas de combate. Elige entre Armas, Furia o Protección, todos detallados al final de la descripción de la clase. Tu arquetipo te concede rasgos en los niveles 3, 7, 11, 15 y 18.", effects = {} },
        ASI("guerrero", 4),
        { id = "gue_ataque_extra", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "gue_accion_adicional", level = 6, name = "Accion adicional", cast = "ninguna", grantsTurnAction = "accion_adicional", type = "accion", description = "Una acción adicional extra en tu turno; recarga con descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
        { id = "gue_ataque_extra_2", icon = "ability_warrior_decisivestrike", level = 20, name = "Ataque adicional (2)", type = "informativo", description = "El número de ataques de tu rasgo de Ataque Extra aumenta a tres cuando alcanzas el nivel 20 en esta clase.", effects = {} },
    },
}

-- Rasgos generados a partir de las opciones de "Maniobras conocidas": el Libro necesita un rasgo
-- de verdad para poder mostrar y ejecutar cada maniobra, pero el texto no se duplica.
do
    local clase = API.GetClass and API.GetClass("guerrero")
    local eleccion
    for _, f in ipairs((clase and clase.features) or {}) do
        if f.id == "guerrero_maniobras_3" then eleccion = f break end
    end
    for _, opcion in ipairs((eleccion and eleccion.choice and eleccion.choice.options) or {}) do
        clase.features[#clase.features + 1] = {
            id = "gue_man_" .. tostring(opcion.id),
            icon = opcion.icon,
            -- Disponible desde que se puede elegir: nivel 3, o el que exija la maniobra.
            level = tonumber(opcion.requiresLevel) or 3,
            name = opcion.label,
            type = "maniobra",
            description = opcion.desc,
            -- Solo se muestra si esa opcion esta elegida (ver GetUnlockedFeatures).
            requiresOption = opcion.id,
            effects = ManeuverEffects(opcion, "rage"),
        }
    end
end
