-- Paladin: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "paladin", name = "Paladin", desc = "Cruzado sagrado que une fuerza marcial y Luz Sagrada para proteger, castigar y sanar.", hitDie = 10, casterType = "half", startingGold = { dice = 5, sides = 4, multiplier = 1 },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Un arma marcial y un escudo", items = { { pick = "Marcial" }, "Escudo" } },
            { label = "Dos armas marciales", items = { { pick = "Marcial" }, { pick = "Marcial" } } },
        } },
        { label = "Paquete",
            fixed = { "Cota de malla", "Simbolo sagrado" },
            options = {
            { label = "Paquete de sacerdote", items = { "Paquete de sacerdote" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Atletismo", "Perspicacia", "Intimidacion", "Medicina", "Persuasion",
        "Religion" },
    saves = { "Sabiduria", "Carisma" },
    armorProfs = { "ligera", "media", "pesada", "escudo" },
    weaponProfs = { "sencillas", "marciales" },
    subclasses = {
        { id = "sagrado", name = "Sagrado", desc = "Luz sanadora y apoyo para los aliados.", features = {
                { id = "pal_sag_conjuros_3", level = 3, name = "Conjuros de camino (Sagrado)", type = "informativo", grantedSpells = { "proteccion_contra_el_bien_y_el_mal" }, description = "Nivel 3: Proteccion contra el bien y el mal (falta Penitencia en el compendio). Los conjuros de camino siempre los tienes preparados y NO cuentan contra los conjuros de paladin que puedes preparar.", effects = {} },
                { id = "pal_sag_conjuros_5", level = 5, name = "Conjuros de camino (Sagrado)", type = "informativo", grantedSpells = { "prisma_sagrado", "restablecimiento_menor" }, description = "Nivel 5: Prisma sagrado y Restablecimiento menor. Los conjuros de camino siempre los tienes preparados y NO cuentan contra los conjuros de paladin que puedes preparar.", effects = {} },
            { id = "pal_sag_canalizar", level = 3, name = "Canalizar divinidad (sagrado)", type = "informativo", description = "Opciones: Luz del Amanecer (disipa oscuridad y cura) y Martillo de Luz (estallido de luz, salvación de Constitución).", effects = {} },
            { id = "pal_sag_luz_amanecer", level = 3, name = "Canalizar: Luz del Amanecer", cast = "accion", type = "accion", resourceKey = "channel_divinity", resourceCost = 1, spendResourceOnAnnounce = true, announceValues = { { classLevel = "paladin", multiplier = 5, label = "PG de curacion a repartir en el cono" } }, description = "Accion: disipas la oscuridad magica en un cono de 9 metros frente a ti y liberas energia curativa. Restauras un total de puntos de golpe igual a cinco veces tu nivel de paladin, repartidos entre las criaturas que elijas dentro del cono. No afecta a no-muertos ni constructos.", effects = {} },
            { id = "pal_sag_martillo_luz", level = 3, name = "Canalizar: Martillo de Luz", cast = "accion", type = "accion", resourceKey = "channel_divinity", resourceCost = 1, dcAbility = "Carisma", area = { shape = "sphere", sizeText = "1,5 m de radio", resolution = "save", saveAbility = "Constitucion", success = "half", damageComponents = { { damageDice = "2d10", damageType = "radiante" } }, damageBonusFrom = { classLevel = "paladin" } }, description = "Accion: golpeas el suelo con un martillo divino en un espacio a 9 metros; un pilar de luz sagrada de 1,5 metros de radio se alza. Cada criatura en el alcance hace una salvacion de Constitucion: 2d10 + tu nivel de paladin de dano radiante si falla, la mitad si tiene exito.", effects = {} },
            { id = "pal_sag_destello", level = 3, name = "Destello de Luz", cast = "accion_adicional", type = "accion", actionKind = "flashOfLight", description = "Acción adicional + ranura de conjuro: curas a un objetivo a 20 pies (2d6 por ranura de 1er nivel, +1d6 por nivel superior, max 6d6).", effects = {} },
        } },
        { id = "proteccion", name = "Proteccion", desc = "Guardian acorazado que protege a los suyos.", features = {
                { id = "pal_pro_conjuros_3", level = 3, name = "Conjuros de camino (Proteccion)", type = "informativo", grantedSpells = { "santuario", "escudo_de_fe" }, description = "Nivel 3: Santuario y Escudo de fe. Los conjuros de camino siempre los tienes preparados y NO cuentan contra los conjuros de paladin que puedes preparar.", effects = {} },
                { id = "pal_pro_conjuros_5", level = 5, name = "Conjuros de camino (Proteccion)", type = "informativo", grantedSpells = { "guardian_del_rey" }, description = "Nivel 5: Guardian del rey (Castigo deslumbrante sin identificar). Los conjuros de camino siempre los tienes preparados y NO cuentan contra los conjuros de paladin que puedes preparar.", effects = {} },
            { id = "pal_pro_canalizar", level = 3, name = "Canalizar divinidad (proteccion)", type = "informativo", description = "Opciones: Consagracion (radio 30 pies, daño radiante + PG temporal a aliados) y Escudo Sagrado (desventaja a atacantes; daño al fallar contra ti).", effects = {} },
            { id = "pal_pro_consagracion", level = 3, name = "Canalizar: Consagracion", cast = "accion", type = "accion", resourceKey = "channel_divinity", resourceCost = 1, dcAbility = "Carisma", area = { shape = "sphere", sizeText = "9 m de radio", resolution = "save", saveAbility = "Destreza", success = "half", damageFrom = { classLevel = "paladin", multiplier = 0.5, damageType = "radiante" } }, announceValues = { { classLevel = "paladin", multiplier = 0.5, abilityMod = "Carisma", label = "PG temporales para cada aliado que elijas" } }, description = "Accion: consagras el suelo en un radio de 9 metros. Cada criatura de tu eleccion en el rango hace una salvacion de Destreza: dano radiante igual a la mitad de tu nivel de paladin si falla, la mitad si tiene exito. Ademas, cada criatura de tu eleccion gana puntos de golpe temporales iguales a la mitad de tu nivel de paladin mas tu Mod. Carisma.", effects = {} },
            { id = "pal_pro_escudo_sagrado", level = 3, name = "Canalizar: Escudo Sagrado", cast = "accion_adicional", type = "accion", resourceKey = "channel_divinity", resourceCost = 1, selfCondition = { id = "escudo_sagrado", duration = "rounds", turns = 10 }, description = "Accion adicional: durante 1 minuto, las tiradas de ataque contra ti se hacen con desventaja. Ademas, una vez por turno, cuando una criatura te ataque puedes infligirle dano radiante igual a 1d6 mas la mitad de tu nivel de paladin.", effects = {} },
            { id = "pal_pro_bastion", level = 3, name = "Bastion divino", type = "recurso", description = "Al golpear cuerpo a cuerpo, gasta ranura de conjuro: +2d6 radiante (1er nivel; +1d6 por nivel superior, max 6d6) y el objetivo tiene desventaja en ataques contra otros. No se combina con Golpe del Cruzado (elige solo uno por ataque). Toggle por nivel en 'Daño extra'.", effects = {
                { kind = "conditionalWeaponDamage", id = "divine_bastion", label = "Bastion Divino", count = 2, die = 6, damageType = "radiante", spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, extraCountOffset = 1, maxCount = 6 },
            } },
        } },
        { id = "represion", name = "Represion", desc = "Castigo sagrado que aniquila al impio.", features = {
                { id = "pal_ret_conjuros_3", level = 3, name = "Conjuros de camino (Retribucion)", type = "informativo", grantedSpells = { "duelo_obligado", "golpe_furioso" }, description = "Nivel 3: Duelo obligado (duelo forzado) y Castigo furioso (castigo abrasador). Los conjuros de camino siempre los tienes preparados y NO cuentan contra los conjuros de paladin que puedes preparar.", effects = {} },
                { id = "pal_ret_conjuros_5", level = 5, name = "Conjuros de camino (Retribucion)", type = "informativo", grantedSpells = { "arma_magica" }, description = "Nivel 5: Arma magica (Castigo justo sin identificar). Los conjuros de camino siempre los tienes preparados y NO cuentan contra los conjuros de paladin que puedes preparar.", effects = {} },
            { id = "pal_ret_canalizar", level = 3, name = "Canalizar divinidad (represion)", type = "informativo", description = "Opciones: Veredicto del Templario (ventaja en ataques contra una criatura 1 minuto) y Rechazar lo Profano (apartar demonios/no-muertos).", effects = {} },
            { id = "pal_ret_veredicto", level = 3, name = "Canalizar: Veredicto del Templario", cast = "accion_adicional", type = "accion", resourceKey = "channel_divinity", resourceCost = 1, dcAbility = "Carisma", area = { shape = "other", sizeText = "Objetivo", resolution = "auto", conditionId = "veredicto", conditionDuration = "rounds", conditionTurns = 10 }, description = "Accion adicional: emites un veredicto contra una criatura a 9 metros. Obtienes ventaja en las tiradas de ataque contra ella durante 1 minuto, hasta que caiga a 0 puntos de golpe o quede inconsciente.", effects = {} },
            { id = "pal_ret_rechazar", level = 3, name = "Canalizar: Rechazar lo Profano", cast = "accion", type = "accion", resourceKey = "channel_divinity", resourceCost = 1, dcAbility = "Carisma", area = { shape = "sphere", sizeText = "9 m de radio", resolution = "save", saveAbility = "Sabiduria", success = "none", conditionId = "apartado", conditionDuration = "rounds", conditionTurns = 10 }, description = "Accion: presentas tu simbolo sagrado. Cada demonio o no-muerto a 9 metros que pueda verte u oirte hace una salvacion de Sabiduria; si falla, queda apartado durante 1 minuto o hasta que reciba dano. Una criatura apartada gasta sus turnos alejandose de ti lo mas posible y no puede acercarse voluntariamente.", effects = {} },
            { id = "pal_ret_tormenta", level = 3, name = "Tormenta divina", cast = "ninguna", type = "accion", actionKind = "divineStorm", description = "Al golpear, gasta ranura de conjuro: daño radiante a la criatura y a todo a 5 pies (salvación de Destreza por mitad). No se combina con Golpe del Cruzado.", effects = {} },
        } },
    },
    features = {
        { id = "pal_sentido_divino", level = 1, name = "Sentido divino", cast = "accion", type = "informativo", description = "Acción: detectas celestiales, infernales y no-muertos a 60 pies, y lugares/objetos consagrados o profanados. Usos = 1 + Mod. Carisma.", uses = { base = 1, ability = "Carisma", min = 1, recharge = "long" }, effects = {} },
        { id = "pal_imposicion_manos", level = 1, name = "Imposicion de manos", cast = "accion", type = "accion", actionKind = "layOnHands", description = "Reserva de curación igual a tu nivel de paladín x5 PG. Como acción, tocas a una criatura y restauras la cantidad de PG que elijas de la reserva. Recarga en descanso largo.", uses = { base = 0, perClassLevel = "paladin", perLevel = 5, recharge = "long" }, effects = {} },
        { id = "pal_estilo_combate", level = 2, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "guerrero_bendito", label = "Guerrero Bendito (2 trucos de sacerdote, Carisma)", effects = {} },
                { id = "defensa",          label = "Defensa (+1 CA con armadura)",            effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                { id = "doble_empuñadura", label = "Doble Empuñadura (+2 daño un arma a una mano)", effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                { id = "doble_empunadura", label = "Doble Empunadura (+2 dano con un arma a una mano y sin otras armas)", effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                { id = "gran_arma",        label = "Gran Arma (repetir 1-2 a dos manos)",     effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                { id = "proteccion",       label = "Proteccion (desventaja a atacantes, con escudo)", effects = {} },
            },
        } },
        { id = "pal_lanzamiento_conjuros", level = 2, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de paladín usando Carisma (preparas Mod. Carisma + mitad de nivel). CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma.", effects = {} },
        { id = "pal_golpe_cruzado", level = 2, name = "Golpe del cruzado", type = "pasivo", description = "Al golpear cuerpo a cuerpo, gasta ranura de conjuro: +2d8 radiante (1er nivel; +1d8 por nivel superior, max 6d8; +1d8 contra no-muertos/infernales). El toggle suma el daño base de 1er nivel (2d8); los dados extra por ranura superior se añaden manualmente.", effects = {
            { kind = "conditionalWeaponDamage", id = "smite", label = "Golpe del Cruzado", count = 2, die = 8, damageType = "radiante", spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, extraCountOffset = 1, maxCount = 6 },
        } },
        { id = "pal_camino_sagrado", level = 3, name = "Camino sagrado", type = "recurso", description = "Eliges tu camino (de lo Sagrado, de la Protección o de la Represion). Concede rasgos y Canalizar Divinidad (1 uso, recarga en descanso corto o largo) en niveles 3, 7, 15 y 20.", effects = {
            { kind = "resourceMax", resource = "channel_divinity", value = 1, stack = "max" },
        } },
        ASI("paladin", 4),
        { id = "pal_ataque_extra", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "pal_aura_proteccion", level = 6, name = "Aura de proteccion", type = "pasivo", description = "Tu y aliados a 10 pies suman tu Mod. Carisma (mínimo +1) a sus tiradas de salvación mientras estés consciente.", effects = {
            { kind = "allSavesAbility", ability = "Carisma", min = 1 },
        } },
                { id = "pal_aura_de_coraje", level = 10, name = "Aura de Coraje", type = "informativo", description = "A partir de nivel 10. ni tú ni las criaturas amistosas a 3 metros o menos de ti podréis ser asustadas mientras permanezcas consciente. A nivel 18 el alcance de esta aura aumenta a 9,1 metros.", effects = {} },
        { id = "pal_toque_purificador", level = 14, name = "Toque Purificador", type = "informativo", description = "A partir de nivel 14, puedes utilizar tu acción para finalizar un conjuro que te esté afectando a ti o a una criatura voluntaria a la que toques. Puedes emplear este rasgo tantas veces como tu modificador por Carisma (mínimo una vez). Recuperas todos los usos tras finalizar un descanso largo.", effects = {} },
    },
}
