-- Sacerdote: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "sacerdote", name = "Sacerdote", desc = "Servidor devoto que canaliza la fe para sanar, proteger o castigar con poder sagrado y sombrio.", hitDie = 6, casterType = "full", startingGold = { dice = 4, sides = 4, multiplier = 1 },
    -- Herramientas de clase segun el manual.
    toolProfs = { "Kit de herborista" },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Una maza", items = { "Maza" } },
            { label = "Un baston", items = { "Bastón" } },
        } },
        { label = "Paquete",
            fixed = { "Simbolo sagrado", "Kit de herboristeria", "Daga", "Daga" },
            options = {
            { label = "Paquete de sacerdote", items = { "Paquete de sacerdote" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Historia", "Perspicacia", "Medicina", "Persuasion", "Religion" },
    saves = { "Sabiduria", "Carisma" },
    armorProfs = {},
    weaponProfs = { "sencillas" },
    subclasses = {
        { id = "disciplina", name = "Disciplina", desc = "Escudos y prevencion que sanan mitigando el daño.", features = {
                { id = "sac_dis_conjuros_1", level = 1, name = "Conjuros del llamado (Disciplina)", type = "informativo", grantedSpells = { "curar_heridas", "infligir_heridas" }, description = "Nivel 1: Curar heridas e Infligir heridas. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 1, ids = { "curar_heridas", "infligir_heridas" } } }, effects = {} },
                { id = "sac_dis_conjuros_3", level = 3, name = "Conjuros del llamado (Disciplina)", type = "informativo", grantedSpells = { "oscuridad", "silencio" }, description = "Nivel 3: Oscuridad y Silencio. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 2, ids = { "oscuridad", "silencio" } } }, effects = {} },
                { id = "sac_dis_conjuros_5", level = 5, name = "Conjuros del llamado (Disciplina)", type = "informativo", grantedSpells = { "estrella_divina", "toque_vampirico" }, description = "Nivel 5: Estrella divina y Toque vampirico. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 3, ids = { "estrella_divina", "toque_vampirico" } } }, effects = {} },
            { id = "sac_dis_truco", level = 1, name = "Truco de bonificacion", type = "choice", choice = { slots = 1, options = {}, extraFrom = "cantrip:Sacerdote" }, description = "Aprendes un truco adicional de sacerdote; no cuenta en tu limite.", effects = {} },
            { id = "sac_dis_supresion", level = 6, name = "Supresion del dolor", cast = "accion_adicional", type = "accion", actionKind = "painSuppression", description = "Acción adicional: barrera invisible a un aliado a 60 pies que reduce daño fisico en 2 + tu bonus de competencia durante 1 minuto.", effects = {} },
                        { id = "sac_dis_expiacion", level = 1, name = "Expiacion", cast = "ninguna", type = "accion", category = "absolution", actionKind = "atonement", description = "Siempre que lances un conjuro de nivel 1 o superior que cause dano, puedes elegir una criatura que puedas ver a 9 metros: recupera puntos de golpe iguales al DOBLE del nivel del conjuro. Ademas, siempre que lances un conjuro de nivel 1 o superior que restaure puntos de golpe, puedes elegir una criatura a 9 metros: recibe dano necrotico o radiante (a tu eleccion) igual al doble del nivel del conjuro. Solo puedes usar uno de los dos efectos por lanzamiento.", effects = {} },
                        { id = "sac_dis_absolucion_penitencia", level = 2, name = "Absolución: Penitencia", cast = "accion", type = "accion", category = "absolution", actionKind = "penance", resourceKey = "light_point", description = "A partir del 2º nivel, puedes usar tu Absolución para liberar una expansión de radiancia o fuerza necrótica. Puedes gastar hasta cinco puntos de fe como acción y lanzar una ráfaga de penitencia hacia un objetivo que puedas ver en un radio de 18,3 metros. Al hacerlo, eliges si deseas encomendar o condenar a ese objetivo. ***Encomendar.*** El objetivo recupera puntos de golpe iguales a 2 + 1d6 por cada punto de fe gastado. Si esto restaura a la criatura a su máximo de puntos de golpe, gana puntos de golpe temporales iguales al número de puntos de golpe que queden en la reserva. ***Condenar.*** El objetivo recibe daño radiante o necrótico (a tu elección) igual a 1d10 por cada punto de fe gastado, y debe superar una tirada de salvación de Sabiduría o quedar asustado de ti hasta el final de tu siguiente turno.", effects = {} },
            { id = "sac_dis_castigo", level = 14, name = "Castigo", type = "informativo", description = "A partir del 14º nivel, cuando lanzas un conjuro que causa daño, elige una criatura dañada por ese conjuro en el turno en que lo lanzaste. Esa criatura recibe daño radiante o necrótico adicional (a tu elección) igual a la mitad de tu nivel de sacerdote. Esta característica solo puede usarse una vez por lanzamiento de un conjuro.", effects = {} },
            { id = "sac_dis_claridad_de_voluntad", level = 20, name = "Claridad de Voluntad", type = "informativo", description = "En el nivel 20, eres capaz de aprovechar tu voluntad enfocada, mejorando tu Supresión del Dolor. Tu barrera de supresión ahora reduce todo el daño recibido. Mientras una criatura esté bajo el efecto de tu barrera de supresión, también tiene ventaja en las tiradas de salvación para evitar ser encantada o asustada.", effects = {} },
        } },
        { id = "sagrado", name = "Sagrado", desc = "Sanacion pura y restauradora con la Luz.", features = {
                { id = "sac_sag_conjuros_1", level = 1, name = "Conjuros del llamado (Sagrado)", type = "informativo", grantedSpells = { "bendicion", "curar_heridas" }, description = "Nivel 1: Bendicion (bendecir) y Curar heridas. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 1, ids = { "bendicion", "curar_heridas" } } }, effects = {} },
                { id = "sac_sag_conjuros_3", level = 3, name = "Conjuros del llamado (Sagrado)", type = "informativo", grantedSpells = { "restablecimiento_menor", "fuerza_brillante" }, description = "Nivel 3: Restablecimiento menor y Fuerza radiante (fuerza brillante). Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 2, ids = { "fuerza_brillante", "restablecimiento_menor" } } }, effects = {} },
                { id = "sac_sag_conjuros_5", level = 5, name = "Conjuros del llamado (Sagrado)", type = "informativo", grantedSpells = { "senal_de_esperanza", "revivir" }, description = "Nivel 5: Senal de esperanza (faro de esperanza) y Revivir. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 3, ids = { "senal_de_esperanza", "revivir" } } }, effects = {} },
            { id = "sac_sag_competencia", level = 1, name = "Saber divino", type = "pasivo", description = "Pericia en Religión (competencia y bonus de competencia duplicado).", effects = {
                { kind = "skillExpertise", skill = "Religion" },
            } },
            { id = "sac_sag_himno", level = 1, name = "Himno divino", cast = "accion", type = "accion", uses = { max = 1, recharge = "short" }, description = "Acción: curación (= nivel x5 PG) repartida entre criaturas a 30 pies (no por encima de la mitad de su maximo). 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "sac_sag_oracion", level = 6, name = "Oracion de curacion", cast = "ninguna", type = "accion", resourceKey = "light_point", resourceCost = 1, rollModifier = { reroll = true, markKey = "oracionCuracion" }, description = "Gasta 1 punto de fe para volver a tirar dados de curación (tuya o de un aliado a 5 pies). 1 vez por turno.", effects = {} },
        } },
        { id = "sombra", name = "Sombra", desc = "Magia de la mente y energía sombria para destruir.", features = {
                { id = "sac_som_conjuros_1", level = 1, name = "Conjuros del llamado (Sombra)", type = "informativo", grantedSpells = { "brazos_de_hadar", "vacio_oscuro" }, description = "Nivel 1: Brazos de Hadar y Vacio oscuro. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 1, ids = { "brazos_de_hadar", "vacio_oscuro" } } }, effects = {} },
                { id = "sac_som_conjuros_3", level = 3, name = "Conjuros del llamado (Sombra)", type = "informativo", grantedSpells = { "fuerza_fantasmal", "aguijon_mental" }, description = "Nivel 3: Fuerza fantasmal y Aguijon mental (la Descarga mental del manual: Mind Spike, 3d8 psiquico con salvacion de Sabiduria y rastreo). Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 2, ids = { "fuerza_fantasmal", "aguijon_mental" } } }, effects = {} },
                { id = "sac_som_conjuros_5", level = 5, name = "Conjuros del llamado (Sombra)", type = "informativo", grantedSpells = { "toque_vampirico" }, description = "Nivel 5: Toque vampirico (Miedo no esta en el compendio). Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar cada dia.", spellGrants = { { level = 3, ids = { "toque_vampirico" } } }, effects = {} },
            { id = "sac_som_voz", level = 1, name = "Voz psiquica", type = "pasivo", description = "Telepatia con cualquier criatura visible a 30 pies (no necesitais compartir idioma, pero debe entender alguno).", effects = {} },
            { id = "sac_som_legado", level = 1, name = "Legado del Vacio", cast = "ninguna", type = "accion", actionKind = "voidLegacy", description = "Al dañar con un truco, daño psíquico extra = Mod. Carisma (con salvación de Sabiduría para seguir usandolo).", effects = {} },
            { id = "sac_som_forma", level = 6, name = "Forma de Sombra", cast = "accion_adicional", type = "accion", uses = { max = 1, recharge = "short" }, description = "Acción adicional 1 minuto: si vas sin armadura sumas Mod. Carisma a la CA; daño necrótico a quien te golpee; tus conjuros ignoran resistencia necrótica/psiquica. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                        { id = "sac_som_mente_dominante", level = 14, name = "Mente Dominante", type = "informativo", description = "Al alcanzar el nivel 14, puedes usar tu voz telepática para dominar las mentes de otros. Como acción, puedes gastar 6 puntos de fe para lanzar *dominar bestia* o *dominar persona* sobre una criatura a 9,1 metros de ti. Además, tienes ventaja en las tiradas de salvación contra ser encantado.", effects = {} },
            { id = "sac_som_rendicion_a_la_locura", level = 20, name = "Rendición a la Locura", type = "informativo", description = "En el nivel 20, puedes abrazar los susurros locos del vacío y dejar que sus poderes fluyan a través de ti. Cuando usas tu acción adicional para cubrirte con tu forma de sombra, o como acción adicional mientras está activa, puedes someterte al vacío durante la duración de la forma de sombra y obtener los siguientes beneficios: - Cuando normalmente lanzarías uno o más dados de daño por un conjuro de sacerdote de nivel 5 o inferior, en su lugar usas el número más alto posible para cada dado. - Puedes usar tu reacción cuando una criatura que puedes ver te ataca o lanza un conjuro contra ti, perforando su mente con los murmullos de los Dioses Antiguos. La criatura debe superar una tirada de salvación de Sabiduría contra tu CD de conjuros o quedar incapacitada hasta el comienzo de tu próximo turno.", effects = {} },
        } },
        { id = "elune", name = "Sacerdocio de Elune", desc = "Especializacion exclusiva de elfos de la noche: devoción a la Madre Luna y disciplina marcial de las centinelas.", requiredRace = "raza_elfo_noche", features = {
            { id = "sac_elu_canalizar_divinidad", level = 1, name = "Canalizar divinidad", type = "pasivo", requiredRace = "raza_elfo_noche", description = "Tu devoción a Elune te permite canalizar energía divina para alimentar sus dones. Dispones de 1 uso de Canalizar Divinidad y recuperas todos los usos al terminar un descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "channel_divinity", value = 1, stack = "max" },
            } },
            { id = "sac_elu_gracia", level = 1, name = "Gracia de Elune", cast = "accion_adicional", type = "accion", requiredRace = "raza_elfo_noche", actionKind = "elunesGrace", description = "Como acción adicional, gastas Canalizar Divinidad para envolver a una criatura que veas a 30 pies en el abrazo protector de Elune. Durante 1 minuto, o hasta que quedes incapacitado o mueras, puede realizar Destrabarse, Esquivar u Ocultarse como acción adicional. Si te eliges a ti, puedes realizar una de esas acciones al activar la gracia.", effects = {} },
            { id = "sac_elu_conjuros", level = 1, name = "Conjuros del sacerdocio de Elune", type = "pasivo", requiredRace = "raza_elfo_noche", description = "Hasta nivel 6, estos conjuros están siempre preparados y no cuentan contra tu limite: nivel 1 Encontrar familiar y Marca del cazador; nivel 2 Rayo de luna y Oleada estelar; nivel 3 Señal de esperanza y Explosión lunar; nivel 4 Destierro e Invisibilidad mayor.", spellGrants = {
                { level = 1, ids = { "encontrar_familiar", "marca_del_cazador" } },
                { level = 2, ids = { "rayo_de_luna", "oleada_estelar" } },
                { level = 3, ids = { "senal_de_esperanza", "explosion_lunar" } },
                { level = 4, ids = { "destierro", "invisibilidad_mayor" } },
            }, effects = {} },
            { id = "sac_elu_entrenamiento_centinela", level = 3, name = "Entrenamiento de centinela", type = "pasivo", requiredRace = "raza_elfo_noche", description = "Tu instruccion con las centinelas te concede competencia con armadura ligera y media. También aprendes Golpe Lunar: cuenta como truco de sacerdote, pero no contra tu limite de trucos conocidos.", cantripSpellIds = { "golpe_lunar" }, effects = {
                { kind = "armorProf", armor = "ligera" },
                { kind = "armorProf", armor = "media" },
            } },
            { id = "sac_elu_furia", level = 3, name = "Furia de Elune", cast = "accion", type = "maniobra", requiredRace = "raza_elfo_noche", description = "Cuando usas tu acción para lanzar un truco de sacerdote, puedes realizar un ataque con arma como acción adicional. Puedes usar esta característica un numero de veces igual a tu modificador de Carisma, mínimo una, y recuperas todos los usos con un descanso corto o largo.", uses = { base = 0, ability = "Carisma", min = 1, recharge = "short" }, effects = { { kind = "energyManeuver", payWithUses = true, cost = 1, attack = true } } },
            { id = "sac_elu_asalto_luz_lunar", level = 6, name = "Asalto de Luz lunar", type = "pasivo", requiredRace = "raza_elfo_noche", description = "Cuando realizas la acción de Atacar en tu turno, puedes realizar un ataque adicional como parte de esa acción.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
        } },
    },
    features = {
        { id = "sac_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "pasivo", description = "Lanzas conjuros de sacerdote usando Carisma (preparas Mod. Carisma + nivel). CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma. Foco: símbolo sagrado.", effects = {} },
        { id = "sac_llamado_divino", level = 1, name = "Llamado divino", type = "informativo", description = "Eliges tu llamado (Disciplina, Sagrado o Sombra) a nivel 1. Concede rasgos en niveles 1, 6, 14 y 20.", effects = {} },
        { id = "sac_ecos_fe", level = 2, name = "Ecos de fe", type = "recurso", description = "Puntos de fe (= nivel) para Devoción (convertir puntos en ranuras de conjuro y viceversa). Recargan en descanso largo.", effects = {
            { kind = "resourceMax", resource = "light_point", perClassLevel = "sacerdote", perLevel = 1 },
        } },
        { id = "sac_crear_ranura", level = 2, name = "Crear espacio de conjuro", cast = "accion_adicional", type = "accion", description = "Accion adicional (Devocion): transformas puntos de fe en una ranura de conjuro. Coste: 2 puntos para una de 1.o, 3 para 2.o, 5 para 3.o, 6 para 4.o y 7 para 5.o. No puedes crear ranuras por encima del 5.o nivel.", actionKind = "slotConversion", slotConversion = { mode = "create", resource = "light_point" }, effects = {} },
        { id = "sac_convertir_ranura", level = 2, name = "Convertir espacio en puntos de fe", cast = "accion_adicional", type = "accion", description = "Accion adicional (Devocion): gastas una ranura de conjuro y ganas puntos de fe iguales al nivel de la ranura.", actionKind = "slotConversion", slotConversion = { mode = "convert", resource = "light_point" }, effects = {} },
        -- Absolucion es una categoria de reglas: sus opciones se muestran como
        -- habilidades independientes, no como una tarjeta clicable del Libro.
        { id = "sac_absolucion", level = 3, name = "Absolucion", type = "pasivo", bookHidden = true, description = "Canalizas tu fe en absoluciones (empiezas con Encadenar No-muertos + una de tu llamado). CD = tu CD de conjuros.", effects = {} },
        { id = "sac_encadenar_no_muertos", level = 3, name = "Encadenar no muertos", cast = "accion", type = "accion", category = "absolution", resourceKey = "light_point", resourceCost = 3, spendResourceOnAnnounce = true, description = "Absolucion. Accion: gastas 3 puntos de fe y presentas tu simbolo sagrado. Cada no-muerto que pueda verte u oirte en un radio de 9,1 metros debe hacer una salvacion de Sabiduria contra la CD de tus conjuros de sacerdote. Si falla, queda aturdido 1 minuto o hasta que reciba cualquier dano.", area = { shape = "sphere", sizeText = "9 m de radio", resolution = "save", saveAbility = "Sabiduria", success = "none", conditionId = "stunned", conditionDuration = "rounds", conditionTurns = 10, note = "Solo afecta a no-muertos que puedan verte u oirte. Termina antes si reciben cualquier dano." }, effects = {} },
        { id = "sac_palabra_poder", level = 3, name = "Palabra de poder", type = "choice", bookHidden = true, description = "Eliges DOS Palabras de Poder; obtienes otra a los niveles 10 y 17. Cada una aparece en el Libro como su propia habilidad.", effects = {}, choice = {
            slots = 2,
            options = {
                { id = "barrera", label = "Barrera", icon = "spell_holy_powerwordshield", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, desc = "Reacción: cuando una criatura a 30 pies recibe el impacto de una tirada de ataque, gastas 1 punto de fe para forzar al atacante a repetir esa tirada. Harford anuncia y descuenta el uso; la repeticion se resuelve manualmente en mesa." },
                { id = "llamada", label = "Llamada", icon = "inv_shoulder_robe_raidpriest_k_01", cast = "reaccion", resourceKey = "light_point", resourceCost = 2, desc = "Puedes usar tu reacción y gastar 2 puntos de fe cuando una criatura aliada dentro de 60 pies de ti se ve obligada a hacer una tirada de salvación para evitar un efecto de área o cae. La criatura es arrastrada a un espacio vacío a 5 pies de ti y no sufre efectos del área si Llamada la saco de la zona ni recibe daño por caer." },
                { id = "castigo", label = "Castigo", icon = "spell_shadow_mindshear", cast = "accion", resourceKey = "light_point", resourceCost = 2, saveAbility = "Sabiduria", conditionId = "incapacitated", conditionDuration = "target_turn_end", desc = "Acción: una criatura a 30 pies hace una salvación de Sabiduría contra tu CD de conjuro. Si falla, queda incapacitada hasta el final de su siguiente turno." },
                { id = "muerte", label = "Muerte", icon = "spell_shadow_demonicfortitude", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, desc = "Cuando infliges daño con un conjuro de sacerdote, puedes volver a tirar tantos dados de daño como tu modificador de Carisma (mínimo uno), usando los nuevos resultados." },
                { id = "fortaleza", label = "Fortaleza", icon = "spell_priest_angelicbulwark", cast = "reaccion", resourceKey = "light_point", resourceCost = 2, resolution = "auto", applicationCountAbility = "Carisma", conditionId = "palabra_fortaleza", conditionDuration = "target_turn_end", desc = "Reacción: cuando se realiza una salvación, eliges hasta tu modificador de Carisma (mínimo una) criaturas a 30 pies. Tienen ventaja en esa salvación. Marca manualmente a cada criatura elegida antes de resolverla." },
                { id = "resplandor", label = "Resplandor", icon = "spell_holy_searinglight", cast = "reaccion", resourceKey = "light_point", resourceCost = 2, saveAbility = "Sabiduria", conditionId = "frightened", conditionDuration = "target_turn_end", desc = "Reacción: cuando una criatura te golpea con un ataque cuerpo a cuerpo, debe superar una salvación de Sabiduría contra tu CD de conjuro o quedar asustada hasta el final de su siguiente turno." },
                { id = "dolor", label = "Dolor", icon = "spell_shadow_shadowwordpain", cast = "accion", resourceKey = "light_point", resourceCost = 1, saveAbility = "Constitucion", conditionId = "palabra_dolor", conditionDuration = "target_turn_end", desc = "Acción: una criatura a 60 pies hace una salvación de Constitución contra tu CD de conjuro. Si falla, tiene desventaja en todas sus tiradas de ataque hasta el final de su siguiente turno." },
                { id = "escudo", label = "Escudo", icon = "spell_holy_powerwordshield", cast = "accion_adicional", resourceKey = "light_point", resourceCost = 2, grant = { resource = "temp_health", ability = "Carisma", perClassLevel = "sacerdote", perLevelDiv = 2, noun = "vida temporal" }, desc = "Acción adicional: una criatura gana PG temporales iguales a la mitad de tu nivel de sacerdote + tu modificador de Carisma." },
                { id = "consuelo", label = "Consuelo", icon = "spell_holy_prayerofmendingtga", cast = "reaccion", resourceKey = "light_point", resourceCost = 1, grant = { resource = "health", ability = "Carisma", noun = "curacion adicional" }, desc = "Cuando restauras PG con un conjuro de nivel 1 o superior, puedes restaurar PG adicionales iguales a tu modificador de Carisma a una criatura afectada." },
            },
        } },
        ASI("sacerdote", 4),
        { id = "sac_restauracion_fieles", level = 5, name = "Restauracion de los fieles", type = "informativo", description = "Recuperas 2 puntos de fe al terminar un descanso corto (3 a nivel 10, 4 a nivel 17).", effects = {
            -- Tabla del manual: 2 puntos de fe en descanso corto desde nivel 5, 3 desde el 10 y 4 desde el 17.
            { kind = "restRestore", resource = "light_point", rest = "short",
              perClassLevel = "sacerdote", values = { 0, 0, 0, 0, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4 } },
        } },
    },
}

-- Rasgos generados a partir de las Palabras de Poder elegidas (Sacerdote). Mismo patron que las
-- maniobras y las Maldiciones: la opcion elegida se convierte en un rasgo real y ejecutable. Antes
-- el rasgo padre resolvia SOLO la primera eleccion (`chosen[1]`), asi que con dos elegidas la
-- segunda quedaba inservible. `powerWordOption` ya lo soportaba el manejador.
do
    local clase = API.GetClass and API.GetClass("sacerdote")
    local padre
    for _, f in ipairs((clase and clase.features) or {}) do
        if f.id == "sac_palabra_poder" then padre = f break end
    end
    for _, opcion in ipairs((padre and padre.choice and padre.choice.options) or {}) do
        clase.features[#clase.features + 1] = {
            id = "sac_pp_" .. tostring(opcion.id),
            icon = opcion.icon,
            level = padre.level,
            name = "Palabra de poder: " .. tostring(opcion.label),
            type = "accion",
            cast = opcion.cast,
            category = "poder",
            description = opcion.desc,
            requiresOption = opcion.id,
            actionKind = "powerWord",
            powerWordParent = padre,
            powerWordOption = opcion,
            effects = {},
        }
    end
end
