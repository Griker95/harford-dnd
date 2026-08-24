-- Monje: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "monje", name = "Monje", desc = "Artista marcial que canaliza el chi para golpear con rapidez, sanar con nieblas o resistir como un muro.", hitDie = 8, startingGold = { dice = 4, sides = 1, multiplier = 1 },
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
    subclasses = {
        { id = "cervecero", name = "Maestro cervecero", desc = "Muro resistente que aguanta y dispersa el daño.", features = {
            { id = "monje_cer_competencia", level = 3, name = "Competencia adicional (cervecero)", type = "pasivo", description = "Competencia con herramientas de cervecero (bonus de competencia duplicado en sus pruebas).", effects = {
                { kind = "toolProf", tool = "Herramientas de cervecero" },
            } },
            { id = "monje_cer_buey_negro", level = 3, name = "Brebaje del Buey Negro", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Lo conoces siempre. Gastas 1 punto de chi para darte ventaja en el proximo ataque cuerpo a cuerpo que realices dentro de 1 minuto. Puedes atacar como parte de la misma accion.", effects = {} },
            { id = "monje_cer_brebajes", level = 3, name = "Cervecero elusivo", type = "choice", description = "Canalizas tu chi en brebajes. Conoces el Brebaje del Buey Negro y UNO mas a tu eleccion; aprendes otro a los niveles 6, 11 y 17. Usarlos cuesta una accion y sus puntos de chi cada vez, y necesitas un frasco de liquido potable contigo.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "aliento_fuego", label = "Aliento de Fuego (2 chi)", requiresLevel = 6, desc = "Gastas 2 puntos de chi para exhalar fuego en un cono de 4,6 metros. Cada criatura en el area hace una salvacion de Destreza: dano por fuego igual a tu nivel de Monje mas tu Mod. Sabiduria si falla, la mitad si tiene exito." },
                    { id = "fortificante", label = "Brebaje Fortificante (1 chi)", desc = "Gastas 1 punto de chi para ganar puntos de golpe temporales iguales a la mitad de tu nivel de Monje mas tu Mod. Sabiduria." },
                    { id = "piel_hierro", label = "Brebaje de Piel de Hierro (2 chi)", requiresLevel = 6, desc = "Gastas 2 puntos de chi para ganar resistencia al dano contundente, perforante y cortante infligido por ataques no magicos durante 1 minuto." },
                    { id = "te_trueno", label = "Te de Trueno (1 chi)", desc = "Gastas 1 punto de chi para ganar la fuerza de Xuen. Hasta el final de tu proximo turno, tus ataques cuerpo a cuerpo infligen dano adicional por trueno igual a tu Mod. Sabiduria." },
                    { id = "desmayo", label = "Brebaje del Desmayo (3 chi)", requiresLevel = 11, desc = "Gastas 3 puntos de chi para obtener los efectos del conjuro desenfocar durante 1 minuto." },
                    { id = "vigorizante", label = "Brebaje Vigorizante (4 chi)", requiresLevel = 11, desc = "Gastas 4 puntos de chi para obtener los efectos del conjuro prisa durante 1 minuto." },
                    { id = "agil", label = "Brebaje Agil (3 chi)", requiresLevel = 11, desc = "Gastas 3 puntos de chi para obtener los efectos del conjuro libertad de movimiento durante 1 minuto." },
                    { id = "purificador", label = "Brebaje Purificador (5 chi)", requiresLevel = 17, desc = "Gastas 5 puntos de chi para lanzar restauracion mayor sobre ti mismo." },
            } } },
            { id = "monje_cer_tambaleo", level = 6, name = "Tambaleo", type = "informativo", description = "Reacción al recibir daño: resistencia a todo el daño del ataque salvo psíquico. 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "cervecero_elaboracion_ligera", level = 11, name = "Elaboración Ligera", type = "informativo", description = "A partir del 11º nivel, cuando usas tu acción para beber un brebaje, puedes realizar un golpe desarmado como acción adicional. En el 17º nivel, esto aumenta a dos golpes desarmados.", effects = {} },
            { id = "cervecero_brebajes_elusivos", level = 11, name = "Brebajes Elusivos", type = "informativo", description = "Los brebajes elusivos se presentan en orden alfabético. Si un brebaje requiere un nivel, debes tener ese nivel en esta clase para aprender el brebaje. ***Brebaje del Buey Negro.*** Puedes gastar 1 punto de chi para darte ventaja en el próximo ataque cuerpo a cuerpo que realices dentro de 1 minuto. Puedes realizar un ataque cuerpo a cuerpo como parte de la misma acción. ***Brebaje del Desmayo (Requiere 11º nivel).*** Puedes gastar 3 puntos de chi para obtener los efectos del hechizo *desenfoque* durante 1 minuto. ***Aliento de Fuego (Requiere 6º nivel).*** Puedes gastar 2 puntos de chi para exhalar fuego en un cono de 4,6 metros. Cada criatura en el área debe realizar una tirada de salvación de Destreza, recibiendo daño por fuego igual a tu nivel de Monje + tu modificador de Sabiduría si falla la tirada, o la mitad de daño si tiene éxito.", effects = {} },
        } },
        { id = "tejedor", name = "Tejedor de niebla", desc = "Sanacion y apoyo mediante nieblas restauradoras.", features = {
            { id = "monje_tej_niebla_calmante", level = 3, name = "Niebla reconfortante", type = "recurso", description = "Reserva de chi sanador (= nivel x 10 PG). Acción: rayo a 30 pies que cura; o gasta 5 para curar enfermedad/veneno. Recarga en descanso largo.", effects = {
                { kind = "resourceMax", resource = "healing_mist", perClassLevel = "monje", base = 0, perLevel = 10 },
            } },
            { id = "monje_tej_palma_chiji", level = 3, name = "Palma de chi-ji", type = "accion", actionKind = "chiJiPalm", description = "Al usar Niebla reconfortante, golpe desarmado como acción adicional usando tu Mod. Sabiduría al ataque y daño.", effects = {} },
            { id = "monje_tej_caminante", level = 6, name = "Caminante de la niebla", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Acción + 1 punto de chi: te teletransportas 60 pies y puedes usar Niebla reconfortante desde la nueva posición.", effects = {} },
                        { id = "tejedor_anillo_de_paz", level = 11, name = "Anillo de Paz", type = "informativo", description = "Al alcanzar el nivel 11, puedes usar tu acción y elegir un número de criaturas dentro de 4,6 metros de ti igual a tu modificador de Sabiduría. Un objetivo debe tener éxito en una tirada de salvación de Sabiduría o quedar incapacitado hasta el final de tu próximo turno o hasta que reciba daño. Puedes usar esta característica un número de veces igual a tu modificador de Sabiduría. Recuperas los usos gastados cuando terminas un descanso prolongado.", effects = {} },
            { id = "tejedor_estatua_del_dragon_de_jade", level = 17, name = "Estatua del Dragón de Jade", type = "informativo", description = "A nivel 17, puedes dar forma física a tu chi, moldeándolo en una estatua de Yu'lon, el Dragón de Jade. Puedes gastar 3 puntos de chi como acción y elegir un espacio vacío a 9,1 metros de ti para manifestar una estatua de jade. La estatua tiene puntos de golpe igual al doble de tu nivel de monje, resistencia a todo el daño e inmunidad al daño psíquico y por veneno. Siempre que uses tu característica de Niebla reconfortante, puedes elegir un segundo objetivo dentro de 18,3 metros de la estatua para ser sanado por la mitad de los puntos de golpe que restores. La estatua permanece durante 1 minuto o hasta que sea destruida.", effects = {} },
        } },
        { id = "caminavientos", name = "Viajero del viento", desc = "Daño agil y veloz con golpes encadenados.", features = {
            { id = "monje_cam_golpes_lanza", level = 3, name = "Golpes de mano de lanza", type = "accion", actionKind = "spearHand", description = "Al golpear con Puños de Furia, impones un efecto (derribar, empujar 15 pies o impedir reacciones).", effects = {} },
            { id = "monje_cam_reflejos", level = 3, name = "Reflejos del tigre", type = "pasivo", description = "Sumas tu Mod. Sabiduría a la iniciativa.", effects = {
                { kind = "initiativeAbility", ability = "Sabiduria" },
            } },
            { id = "monje_cam_caminavientos", level = 6, name = "Caminavientos", type = "accion", actionKind = "windwalking", description = "Al usar Paso del Viento ganas velocidad de vuelo (mitad de tu velocidad) hasta el final del turno; reduces daño por caida.", effects = {} },
        } },
    },
    features = {
         { id = "monje_herramientas", level = 1, name = "Herramientas de artesano", type = "choice", description = "Eliges un tipo de herramientas de artesano o un instrumento musical.", effects = {}, choice = { slots = 1, optionsFrom = "artisanTool" } },
        { id = "monje_defensa_sin_armadura", level = 1, name = "Defensa sin armadura", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Sabiduría.", effects = {
            { kind = "unarmoredDefenseAbility", ability = "Sabiduria" },
        } },
        { id = "monje_artes_marciales", level = 1, name = "Artes marciales", type = "pasivo", description = "Con golpes desarmados y armas de monje: usas Destreza al ataque/daño y el dado marcial mejora el daño cuando supera al dado normal. Requiere no llevar armadura ni escudo.", effects = {
            { kind = "martialArts", classId = "monje", values = { 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8, 10, 10, 10, 10 } },
        } },
        { id = "monje_chi", level = 2, name = "Chi", type = "pasivo", description = "Puntos de chi (= nivel) para Puños de Furia, Danza Elusiva, Paso del Viento y Efusion. CD de Chi = 8 + comp + Mod. Sabiduría. Recargan en descanso corto o largo.", effects = {
            { kind = "resourceMax", resource = "chi", perClassLevel = "monje", perLevel = 1 },
        } },
        { id = "monje_chi_punos", level = 2, name = "Punos de Furia", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Inmediatamente despues de tomar la accion de Ataque en tu turno, gastas 1 punto de chi para realizar dos golpes desarmados como accion adicional.", effects = {} },
        { id = "monje_chi_danza", level = 2, name = "Danza Elusiva", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Gastas 1 punto de chi para tomar la accion de Esquivar como accion adicional en tu turno.", effects = {} },
        { id = "monje_chi_paso", level = 2, name = "Paso del Viento", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Gastas 1 punto de chi para tomar la accion de Desengancharse o Correr como accion adicional en tu turno, y tu distancia de salto se duplica ese turno.", effects = {} },
        { id = "monje_chi_efusion", level = 2, name = "Efusion", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Gastas 1 punto de chi y usas tu accion adicional para tocar a una criatura: recupera puntos de golpe iguales a tu Mod. Sabiduria.", effects = {} },
        { id = "monje_rodar", level = 2, name = "Rodar", type = "informativo", description = "Sin escudo, una vez por turno ruedas en línea recta gastando movimiento; los ataques de oportunidad contra ti se hacen con desventaja.", effects = {} },
        { id = "monje_tradicion", level = 3, name = "Tradicion monastica", type = "informativo", description = "Eliges tu tradicion (Maestro Cervecero, Tejedor de Niebla o Caminavientos). Concede rasgos en niveles 3, 6, 11 y 17.", effects = {} },
        { id = "monje_serenidad", level = 3, name = "Serenidad", type = "pasivo", description = "Al usar chi entras en postura serena 1 minuto: usas tu Mod. Sabiduría al ataque/daño con armas de monje o golpes desarmados.", effects = {
            { kind = "toggleState", state = "serene_stance", label = "Postura serena",
              description = "Atacas y danas con Mod. Sabiduria con armas de monje y golpes desarmados. Termina si quedas encantado, asustado o incapacitado." },
            { kind = "weaponAbilityOverride", ability = "Sabiduria", martialArtsOnly = true, requiresState = "serene_stance" },
        } },
        ASI("monje", 4),
        { id = "monje_ataque_adicional", level = 5, name = "Ataque adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la acción de Atacar.", effects = {
            { kind = "flag", flag = "extraAttack" },
        } },
        { id = "monje_palma_aturdidora", level = 5, name = "Palma aturdidora", type = "accion", resourceKey = "chi", resourceCost = 1, spendResourceOnAnnounce = true, description = "Una vez por turno, al golpear cuerpo a cuerpo, gasta 1 punto de chi: el objetivo con salvación de Constitución o aturdido hasta tu próximo turno.", effects = {} },
        { id = "monje_golpes_empoderados_chi", level = 6, name = "Golpes empoderados por el chi", type = "informativo", description = "Tus golpes desarmados cuentan como magicos para superar resistencias e inmunidades no mágicas.", effects = {
            { kind = "flag", flag = "magicalUnarmed" },
        } },
                { id = "monje_evasion", level = 7, name = "Evasión", type = "informativo", description = "En el 7º nivel, tu agilidad instintiva te permite esquivar ciertos efectos de área, como el aliento de escarcha de un dragón azul o el hechizo *bola de fuego*. Cuando te someten a un efecto que te permite realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y recibes la mitad de daño si fallas.", effects = {} },
        { id = "monje_desintoxicacion", level = 7, name = "Desintoxicación", type = "informativo", description = "A partir del 7º nivel, puedes usar tu acción para eliminar una enfermedad o condición de envenenado que te esté afectando.", effects = {} },
        { id = "monje_trascendencia", level = 9, name = "Trascendencia", type = "informativo", description = "Al alcanzar el 9º nivel, puedes concentrar tu chi en una imagen incorpórea de ti mismo a la que podrás trasladarte en el futuro. Puedes usar tu acción y gastar 1 punto de chi para invocar la imagen en tu espacio; la imagen es incorpórea y no se puede interactuar con ella. La imagen permanece durante 1 minuto antes de desaparecer. Mientras estés a 18,3 metros de ella, puedes usar tu acción adicional para trascender el mundo material y teletransportarte al espacio de la imagen. La imagen incorpórea desaparece entonces. En el 18º nivel, tu imagen de jade incorpórea permanece durante 1 hora, y el rango al que puedes trascender a ella se incrementa a 1,6 km.", effects = {} },
        { id = "monje_paz_interior", level = 10, name = "Paz Interior", type = "informativo", description = "A partir del 10º nivel, puedes usar tu acción adicional y gastar 1 punto de chi para finalizar un efecto que te esté causando estar hechizado o asustado.", effects = {} },
        { id = "monje_cuerpo_atemporal", level = 15, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del 15º nivel, tu chi te sostiene de manera que no sufres los efectos de la vejez, y no puedes ser envejecido mágicamente. Aun puedes morir de vejez, sin embargo. Además, ya no necesitas comida ni agua.", effects = {} },
        { id = "monje_zen_perfecto", level = 20, name = "Zen Perfecto", type = "informativo", description = "En el 20º nivel, cuando tires para iniciativa y no tengas puntos de chi restantes, recuperas 4 puntos de chi.", effects = {} },
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
        local coste = tonumber(tostring(opcion.label):match("%((%d+) chi%)")) or 1
        sub.features[#sub.features + 1] = {
            id = "monje_cer_breb_" .. tostring(opcion.id),
            level = tonumber(opcion.requiresLevel) or 3,
            name = (tostring(opcion.label):gsub("%s*%(%d+ chi%)", "")),
            type = "accion",
            description = opcion.desc,
            requiresOption = opcion.id,
            resourceKey = "chi",
            resourceCost = coste,
            spendResourceOnAnnounce = true,
            effects = {},
        }
    end
end
