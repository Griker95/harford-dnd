-- Monje: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "monje", name = "Monje", desc = "El cuerpo entrenado como arma. Golpea rápido, encaja lo que otros esquivan y reparte su chi entre defensa, curación y velocidad.", hitDie = 8, startingGold = { dice = 4, sides = 1, multiplier = 1 },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Una espada corta", items = { "Espada corta" } },
            { label = "Cualquier arma simple", items = { { pick = "Simple" } } },
        } },
        { label = "Paquete",
            fixed = { "10 dardos" },
            options = {
            { label = "Mochila de aventurero", items = { "Paquete de aventurero" } },
            { label = "Mochila de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Acrobacias", "Atletismo", "Historia", "Perspicacia", "Religion", "Sigilo" },
    saves = { "Fuerza", "Destreza" },
    armorProfs = { "ligera" },
    weaponProfs = { "sencillas", "espadas cortas" },
    -- Seccion "Multiclase" del manual: al ENTRAR en la clase (no siendo la inicial).
    multiclass = { minimums = { { "Destreza" }, { "Sabiduria" } },
        armorProfs = { "ligera" }, weaponProfs = { "sencillas", "espadas cortas" } },
    subclasses = {
        { id = "cervecero", name = "Maestro cervecero", nameF = "Maestra cervecera", desc = "Muro resistente que aguanta y dispersa el daño.", features = {
            { id = "monje_cer_competencia", level = 3, name = "Competencia adicional (cervecero)", type = "pasivo", description = "A partir del 3er nivel, obtienes competencia con herramientas de cervecero. Si ya eres competente con estas herramientas, tu bonificación de competencia se duplica para cualquier prueba de habilidad que hagas con ellas.", effects = {
                { kind = "toolProf", tool = "Herramientas de cervecero" },
            } },
            { id = "monje_cer_buey_negro", level = 3, name = "Brebaje del Buey Negro", cast = "accion", type = "accion", resourceKey = "chi", resourceCost = 1, selfCondition = { id = "buey_negro", duration = "rounds", turns = 10 }, description = "Lo conoces siempre. Gastas 1 punto de chi para darte ventaja en el proximo ataque cuerpo a cuerpo que realices dentro de 1 minuto. Puedes atacar como parte de la misma accion.", effects = {} },
            { id = "monje_cer_brebajes", level = 3, name = "Cervecero elusivo", actionKind = "optionAbility", bookHidden = true, type = "choice", description = "Canalizas tu chi en brebajes. Conoces el Brebaje del Buey Negro y UNO mas a tu eleccion; aprendes otro a los niveles 6, 11 y 17. Usarlos cuesta una accion y sus puntos de chi cada vez, y necesitas un frasco de liquido potable contigo.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "aliento_fuego", icon = "inv_misc_head_dragon_01", label = "Aliento de Fuego", resourceKey = "chi", resourceCost = 2, requiresLevel = 6, area = { shape = "cone", sizeText = "4,6 m", resolution = "save", saveAbility = "Destreza", success = "half", damageFrom = { classLevel = "monje", abilityMod = "Sabiduria", damageType = "fuego" } }, desc = "Gastas 2 puntos de chi para exhalar fuego en un cono de 4,6 metros. Cada criatura en el area hace una salvacion de Destreza: dano por fuego igual a tu nivel de Monje mas tu Mod. Sabiduria si falla, la mitad si tiene exito." },
                    { id = "fortificante", icon = "ability_monk_fortifyingale_new", label = "Brebaje Fortificante", resourceKey = "chi", resourceCost = 1, grant = { self = true, resource = "temp_health", ability = "Sabiduria", perClassLevel = "monje", perLevelDiv = 2, noun = "vida temporal" }, desc = "Gastas 1 punto de chi para ganar puntos de golpe temporales iguales a la mitad de tu nivel de Monje mas tu Mod. Sabiduria." },
                    { id = "piel_hierro", icon = "ability_monk_ironskinbrew", label = "Brebaje de Piel de Hierro", resourceKey = "chi", resourceCost = 2, requiresLevel = 6, selfCondition = { id = "piel_hierro", duration = "rounds", turns = 10 }, desc = "Gastas 2 puntos de chi para ganar resistencia al dano contundente, perforante y cortante infligido por ataques no magicos durante 1 minuto." },
                    { id = "te_trueno", icon = "ability_monk_thunderfocustea", label = "Te de Trueno", resourceKey = "chi", resourceCost = 1, effects = { { kind = "conditionalWeaponDamage", id = "monje_te_trueno", label = "Te de Trueno", flatAbility = "Sabiduria", damageType = "trueno", resourceCost = "chi", costPerLevel = 1, minLevel = 1, maxLevel = 1 } }, desc = "Gastas 1 punto de chi para ganar la fuerza de Xuen. Hasta el final de tu proximo turno, tus ataques cuerpo a cuerpo infligen dano adicional por trueno igual a tu Mod. Sabiduria." },
                    { id = "desmayo", icon = "inv_drink_05", label = "Brebaje del Desmayo", resourceKey = "chi", resourceCost = 3, requiresLevel = 11, castsSpell = "contorno_borroso", desc = "Gastas 3 puntos de chi para obtener los efectos del conjuro desenfocar durante 1 minuto." },
                    { id = "vigorizante", icon = "ability_monk_vivify", label = "Brebaje Vigorizante", resourceKey = "chi", resourceCost = 4, requiresLevel = 11, castsSpell = "acelerar", desc = "Gastas 4 puntos de chi para obtener los efectos del conjuro prisa durante 1 minuto." },
                    { id = "agil", icon = "ability_monk_effuse", label = "Brebaje Agil", resourceKey = "chi", resourceCost = 3, requiresLevel = 11, castsSpell = "libertad_de_movimiento", desc = "Gastas 3 puntos de chi para obtener los efectos del conjuro libertad de movimiento durante 1 minuto." },
                    { id = "purificador", icon = "achievement_faction_brewmaster", label = "Brebaje Purificador", resourceKey = "chi", resourceCost = 5, requiresLevel = 17, desc = "Gastas 5 puntos de chi para lanzar restauracion mayor sobre ti mismo." },
            } } },
            { id = "monje_cer_tambaleo", level = 6, name = "Tambaleo", cast = "reaccion", type = "informativo", description = "A partir del 6º nivel, aprendes a resistir ataques dañinos contra ti. Puedes usar tu reacción al recibir daño para darte resistencia a todo el daño infligido por el ataque, excepto daño psíquico.\n\nPuedes usar esta característica dos veces. Recuperas los usos gastados cuando terminas un descanso corto o largo.", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "monje_cer_elaboracion_ligera", icon = "inv_drink_13", level = 11, name = "Elaboración Ligera", type = "informativo", description = "A partir del 11º nivel, cuando usas tu acción para beber un brebaje, puedes realizar un golpe desarmado como acción adicional. En el 17º nivel, esto aumenta a dos golpes desarmados.", effects = {} },
            { id = "monje_cer_brebajes_elusivos", icon = "spell_monk_brewmaster_spec", level = 11, name = "Brebajes Elusivos", type = "informativo", description = "Los brebajes elusivos se presentan en orden alfabético. Si un brebaje requiere un nivel, debes tener ese nivel en esta clase para aprender el brebaje. ***Brebaje del Buey Negro.*** Puedes gastar 1 punto de chi para darte ventaja en el próximo ataque cuerpo a cuerpo que realices dentro de 1 minuto. Puedes realizar un ataque cuerpo a cuerpo como parte de la misma acción. ***Brebaje del Desmayo (Requiere 11º nivel).*** Puedes gastar 3 puntos de chi para obtener los efectos del hechizo *desenfoque* durante 1 minuto. ***Aliento de Fuego (Requiere 6º nivel).*** Puedes gastar 2 puntos de chi para exhalar fuego en un cono de 4,5 metros. Cada criatura en el área debe realizar una tirada de salvación de Destreza, recibiendo daño por fuego igual a tu nivel de Monje + Mod. Sabiduría si falla la tirada, o la mitad de daño si tiene éxito.", effects = {} },
        } },
        { id = "tejedor", name = "Tejedor de niebla", nameF = "Tejedora de niebla", desc = "Sanacion y apoyo mediante nieblas restauradoras.", features = {
            { id = "monje_tej_niebla_calmante", level = 3, name = "Niebla reconfortante", cast = "accion", type = "accion", description = "Reserva de chi sanador (= nivel x 10 PG). Acción: rayo a 9 metros que cura; o gasta 5 para curar enfermedad/veneno. Recarga en descanso largo.",
                -- La cantidad la ELIGE el jugador: el manual dice "hasta el maximo que quede en tu
                -- reservorio", asi que no hay una cifra que declarar aqui. Los escalones son solo
                -- atajos del menu; el tope real es lo que quede.
                poolHeal = { resource = "healing_mist", noun = "curacion",
                             steps = { 5, 10, 20, 50 },
                             cure = { amount = 5, label = "Curar enfermedad o veneno" } },
                effects = {
                { kind = "resourceMax", resource = "healing_mist", perClassLevel = "monje", base = 0, perLevel = 10 },
            } },
            { id = "monje_tej_palma_chiji", level = 3, name = "Palma de chi-ji", cast = "accion_adicional", type = "accion", actionKind = "chiJiPalm", description = "Al usar Niebla reconfortante, golpe desarmado como acción adicional usando tu Mod. Sabiduría al ataque y daño.", effects = {} },
            { id = "monje_tej_caminante", level = 6, name = "Caminante de la niebla", cast = "accion", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "A partir del 6º nivel, puedes teletransportarte distancias cortas a través de la niebla. Como acción, puedes gastar 1 punto de chi y teletransportarte 18 metros a un espacio desocupado que puedas ver. Como parte de la misma acción, puedes usar tu Niebla Calmante en un objetivo dentro del alcance de tu nueva posición.", effects = {} },
                        { id = "monje_tej_anillo_de_paz", icon = "spell_monk_ringofpeace", level = 11, name = "Anillo de Paz", type = "informativo", description = "Al alcanzar el nivel 11, puedes usar tu acción y elegir un número de criaturas dentro de 4,5 metros de ti igual a Mod. Sabiduría. Un objetivo debe tener éxito en una tirada de salvación de Sabiduría o quedar incapacitado hasta el final de tu próximo turno o hasta que reciba daño. Puedes usar esta característica un número de veces igual a Mod. Sabiduría. Recuperas los usos gastados cuando terminas un descanso largo.", effects = {} },
            { id = "monje_tej_estatua_del_dragon_de_jade", icon = "ability_monk_summonserpentstatue", level = 17, name = "Estatua del Dragón de Jade", type = "informativo", description = "A nivel 17, puedes dar forma física a tu chi, moldeándolo en una estatua de Yu'lon, el Dragón de Jade. Puedes gastar 3 puntos de chi como acción y elegir un espacio vacío a 9 metros de ti para manifestar una estatua de jade. La estatua tiene puntos de golpe igual al doble de tu nivel de monje, resistencia a todo el daño e inmunidad al daño psíquico y por veneno. Siempre que uses tu característica de Niebla reconfortante, puedes elegir un segundo objetivo dentro de 18 metros de la estatua para ser sanado por la mitad de los puntos de golpe que restores. La estatua permanece durante 1 minuto o hasta que sea destruida.", effects = {} },
        } },
        { id = "caminavientos", name = "Viajero del viento", desc = "Daño agil y veloz con golpes encadenados.", features = {
            { id = "monje_cam_golpes_lanza", level = 3, name = "Golpes de mano de lanza", cast = "ninguna", type = "accion", actionKind = "spearHand", description = "Al golpear con Puños de Furia, impones un efecto (derribar, empujar 15 pies o impedir reacciones).", effects = {} },
            { id = "monje_cam_reflejos", level = 3, name = "Reflejos del tigre", type = "pasivo", description = "También a nivel 3, reaccionas con la rapidez de un tigre. Puedes darte un bono a tu iniciativa igual a Mod. Sabiduría.", effects = {
                { kind = "initiativeAbility", ability = "Sabiduria" },
            } },
            { id = "monje_cam_caminavientos", level = 6, name = "Caminavientos", cast = "ninguna", type = "accion", actionKind = "windwalking", description = "Al usar Paso del Viento ganas velocidad de vuelo (mitad de tu velocidad) hasta el final del turno; reduces daño por caida.", effects = {} },
        } },
    },
    features = {
         { id = "monje_herramientas", level = 1, name = "Herramientas de artesano", type = "choice", description = "Eliges un tipo de herramientas de artesano o un instrumento musical.", effects = {}, choice = { slots = 1, optionsFrom = "artisanTool" } },
        { id = "monje_defensa_sin_armadura", level = 1, name = "Defensa sin armadura", type = "pasivo", description = "A partir del 1er nivel, mientras no lleves armadura ni estés empuñando un escudo, tu CA será igual a 10 + Mod. Destreza + Mod. Sabiduría.", effects = {
            { kind = "unarmoredDefenseAbility", ability = "Sabiduria" },
        } },
        { id = "monje_artes_marciales", level = 1, name = "Artes marciales", type = "pasivo", description = "En el 1er nivel, tu práctica de las artes marciales te da maestría en estilos de combate que usan golpes desarmados y armas de monje, que son las espadas cortas y cualquier arma cuerpo a cuerpo simple que no tenga la propiedad de dos manos ni pesada.\n\nObtienes los siguientes beneficios mientras estás desarmado o empuñando solo armas de monje y no llevas armadura de malla o de placas, ni empuñas un escudo:\n- Puedes usar Destreza en lugar de Fuerza para las tiradas de ataque y daño de tus golpes desarmados y armas de monje.\n- Puedes tirar un d4 en lugar del daño normal de tu golpe desarmado o arma de monje. Este dado cambia a medida que ganas niveles como monje, como se muestra en la columna de Artes Marciales de la tabla de Monje.\n- Cuando usas la acción de Ataque con un golpe desarmado o un arma de monje en tu turno, puedes realizar un golpe desarmado como acción adicional. Por ejemplo, si tomas la acción de Ataque y atacas con un bastón, puedes realizar también un golpe desarmado como acción adicional.", effects = {
            { kind = "martialArts", classId = "monje", values = { 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8, 10, 10, 10, 10 } },
        } },
        { id = "monje_chi", level = 2, name = "Chi", type = "pasivo", description = "A partir del 2º nivel, tu entrenamiento te permite aprovechar la energía mística del chi. Tu acceso a esta energía se representa por una cantidad de puntos de chi. Tu nivel de monje determina cuántos puntos tienes, como se muestra en la columna de Puntos de Chi de la tabla de Monje.\n\nPuedes gastar estos puntos para alimentar varias características de chi. Comienzas conociendo cuatro de estas características: Puños de Furia, Danza Elusiva, Paso del Viento y Efusión. Aprendes más características de chi a medida que subes de nivel en esta clase.\n\nCuando gastas un punto de chi, no está disponible hasta que termines un descanso corto o largo, al final del cual recuperas todos los puntos de chi gastados. Debes pasar 30 minutos del descanso meditando para recuperar tus puntos de chi.\n\nAlgunas de tus características de chi requieren que tu objetivo haga una tirada de salvación para resistir sus efectos. La CD de la tirada de salvación se calcula de la siguiente manera:\n\n**CD de salvación de Chi** = 8 + Bonus Competencia + Mod. Sabiduría", effects = {
            { kind = "resourceMax", resource = "chi", perClassLevel = "monje", perLevel = 1 },
        } },
        { id = "monje_chi_punos", level = 2, name = "Punos de Furia", cast = "accion_adicional", type = "accion", resourceKey = "chi", resourceCost = 1, extraAttacks = { count = 2, weaponKey = "Desarmado" }, description = "Inmediatamente despues de tomar la accion de Ataque en tu turno, gastas 1 punto de chi para realizar dos golpes desarmados como accion adicional.", effects = {} },
        { id = "monje_chi_danza", level = 2, name = "Danza Elusiva", cast = "accion_adicional", type = "accion", resourceKey = "chi", resourceCost = 1, selfCondition = { id = "esquivando", duration = "source_turn_start" }, description = "Gastas 1 punto de chi para tomar la accion de Esquivar como accion adicional en tu turno.", effects = {} },
        { id = "monje_chi_paso", level = 2, name = "Paso del Viento", cast = "accion_adicional", type = "accion", grantsAsBonus = { "correr", "desengancharse" }, resourceKey = "chi", resourceCost = 1, description = "Gastas 1 punto de chi para tomar la accion de Desengancharse o Correr como accion adicional en tu turno, y tu distancia de salto se duplica ese turno.", effects = {} },
        { id = "monje_chi_efusion", level = 2, name = "Efusion", cast = "accion_adicional", type = "accion", resourceKey = "chi", resourceCost = 1, grant = { resource = "health", ability = "Sabiduria", noun = "curacion" }, description = "Puedes gastar 1 punto de chi y usar tu acción adicional para tocar a una criatura. La criatura recupera puntos de golpe iguales a Mod. Sabiduría.", effects = {} },
        { id = "monje_rodar", level = 2, name = "Rodar", type = "pasivo", description = "A partir del 2º nivel, puedes rodar por el campo de batalla cuando no estés empuñando un escudo. Una vez por turno, puedes gastar movimiento para rodar una cantidad de metros en línea recta igual al movimiento gastado. Puedes rodar a través del espacio de criaturas hostiles, sin embargo, no puedes terminar tu rodar dentro de su espacio.\n\nCualquier ataque de oportunidad realizado contra ti mientras estás rodando se hace con desventaja.", effects = {} },
        { id = "monje_tradicion", subclassMarker = true, level = 3, name = "Tradicion monastica", type = "informativo", description = "Cuando alcanzas el 3er nivel, te comprometes con una tradición monástica: el Camino del Maestro Cervecero, el Camino del Tejedor de Niebla o el Camino del Caminante del Viento, todos detallados al final de la descripción de la clase. Tu tradición te otorga características en el 3er nivel y de nuevo en el 6º, 11º y 17º nivel.", effects = {} },
        { id = "monje_serenidad", level = 3, name = "Serenidad", type = "pasivo", description = "En el 3er nivel, puedes entrar en una postura serena durante 1 minuto cuando usas puntos de chi. Mientras estés en esta postura, usas Mod. Sabiduría para tus tiradas de ataque y daño cuando ataques con un arma de monje o tus golpes desarmados.\n\nTu serenidad termina de manera prematura si te vuelves encantado, asustado o incapacitado, o si intentas realizar una tarea más extenuante que interactuar con un objeto.", effects = {
            { kind = "toggleState", state = "serene_stance", label = "Postura serena",
              description = "Atacas y danas con Mod. Sabiduria con armas de monje y golpes desarmados. Termina si quedas encantado, asustado o incapacitado." },
            { kind = "weaponAbilityOverride", ability = "Sabiduria", martialArtsOnly = true, requiresState = "serene_stance" },
        } },
        ASI("monje", 4),
        { id = "monje_ataque_adicional", level = 5, name = "Ataque adicional", type = "pasivo", description = "A partir del 5º nivel, puedes atacar dos veces, en lugar de una, siempre que tomes la acción de Ataque en tu turno.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "monje_palma_aturdidora", level = 5, name = "Palma aturdidora", type = "maniobra", description = "Una vez por turno, al golpear cuerpo a cuerpo, gasta 1 punto de chi: el objetivo con salvación de Constitución o aturdido hasta tu próximo turno.", effects = { { kind = "energyManeuver", resource = "chi", cost = 1, spendOnHit = true, attack = true, save = "Constitucion", outcome = "Aturdido", dcAbility = "Sabiduria", conditionId = "stunned", conditionDuration = "source_turn_start" } } },
        { id = "monje_golpes_empoderados_chi", level = 6, name = "Golpes empoderados por el chi", type = "informativo", description = "A partir del 6º nivel, tus golpes desarmados cuentan como mágicos para propósitos de superar resistencias e inmunidades a ataques y daño no mágicos.", effects = {
            { kind = "flag", flag = "magicalUnarmed" },
        } },
                { id = "monje_evasion", icon = "spell_shadow_shadowward", level = 7, name = "Evasión", type = "informativo", description = "En el 7º nivel, tu agilidad instintiva te permite esquivar ciertos efectos de área, como el aliento de escarcha de un dragón azul o el hechizo *bola de fuego*. Cuando te someten a un efecto que te permite realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y recibes la mitad de daño si fallas.", effects = {} },
        { id = "monje_desintoxicacion", icon = "ability_monk_detox", level = 7, name = "Desintoxicación", type = "informativo", description = "A partir del 7º nivel, puedes usar tu acción para eliminar una enfermedad o condición de envenenado que te esté afectando.", effects = {} },
        { id = "monje_trascendencia", icon = "monk_ability_transcendence", level = 9, name = "Trascendencia", type = "informativo", description = "Al alcanzar el 9º nivel, puedes concentrar tu chi en una imagen incorpórea de ti mismo a la que podrás trasladarte en el futuro. Puedes usar tu acción y gastar 1 punto de chi para invocar la imagen en tu espacio; la imagen es incorpórea y no se puede interactuar con ella. La imagen permanece durante 1 minuto antes de desaparecer. Mientras estés a 18 metros de ella, puedes usar tu acción adicional para trascender el mundo material y teletransportarte al espacio de la imagen. La imagen incorpórea desaparece entonces. En el 18º nivel, tu imagen de jade incorpórea permanece durante 1 hora, y el rango al que puedes trascender a ella se incrementa a 1,6 km.", effects = {} },
        { id = "monje_paz_interior", level = 10, name = "Paz Interior", type = "informativo", description = "A partir del 10º nivel, puedes usar tu acción adicional y gastar 1 punto de chi para finalizar un efecto que te esté causando estar hechizado o asustado.", effects = {} },
        { id = "monje_cuerpo_atemporal", icon = "spell_holy_blessingofagility", level = 15, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del 15º nivel, tu chi te sostiene de manera que no sufres los efectos de la vejez, y no puedes ser envejecido mágicamente. Aun puedes morir de vejez, sin embargo. Además, ya no necesitas comida ni agua.", effects = {} },
        { id = "monje_zen_perfecto", icon = "ability_monk_zenmeditation", level = 20, name = "Zen Perfecto", type = "informativo", description = "En el 20º nivel, cuando tires para iniciativa y no tengas puntos de chi restantes, recuperas 4 puntos de chi.", effects = {} },
    },
}

-- Rasgos generados a partir del Brebaje elegido (Monje, Maestro Cervecero). Mismo patron que las
-- maniobras del Guerrero. El coste en chi va en la etiqueta y se cobra al usarlo.
do
    local clase = API.GetClass and API.GetClass("monje")
    local sub
    for _, sc in ipairs((clase and clase.subclasses) or {}) do
        if sc.id == "cervecero" then sub = sc break end
    end
    local eleccion
    for _, f in ipairs((sub and sub.features) or {}) do
        if f.id == "monje_cer_brebajes" then eleccion = f break end
    end
    -- El coste en puntos de chi se lee de la etiqueta ("(2 chi)"), que es donde lo declara la opcion.
    for _, opcion in ipairs((eleccion and eleccion.choice and eleccion.choice.options) or {}) do
        -- El coste es un DATO de la opcion. Antes se sacaba del nombre con un patron "(N chi)",
        -- que dejo de existir al separarlo: todos los brebajes acabaron costando 1.
        local mecanica = opcion.area or opcion.grant or opcion.effects or opcion.castsSpell
            or opcion.selfCondition
        sub.features[#sub.features + 1] = {
            id = "monje_cer_breb_" .. tostring(opcion.id),
            icon = opcion.icon,
            level = tonumber(opcion.requiresLevel) or 3,
            name = opcion.label,
            -- "Usarlos cuesta una accion", dice la eleccion: se cobra al beberlo.
            cast = "accion",
            type = "accion",
            description = opcion.desc,
            requiresOption = opcion.id,
            resourceKey = "chi",
            resourceCost = tonumber(opcion.resourceCost) or 1,
            -- Las salvaciones del Aliento de Fuego son de Sabiduria, como todo lo del Monje.
            dcAbility = "Sabiduria",
            area = opcion.area,
            grant = opcion.grant,
            castsSpell = opcion.castsSpell,
            selfCondition = opcion.selfCondition,
            -- Solo cobra el chi al anunciar si NO hay motor que lo cobre en su propia ruta
            -- (el area lo gasta al confirmar, la concesion al aplicarla, el dano condicional al
            -- prepararlo). Si no, se pagaria dos veces.
            spendResourceOnAnnounce = (not mecanica) or nil,
            effects = opcion.effects or {},
        }
    end
end
