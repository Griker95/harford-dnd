-- HarfordDnDBackgrounds: libro hardcodeado de trasfondos (World of Warcraft D&D 5ª Ed. ES).
-- Solo datos + helpers puros. Los rasgos de trasfondo son "features" con el mismo
-- formato que los de clase/raza (id/name/type/description/effects/choice), para reusar
-- el motor de efectos (HarfordDnDFeatureEffects) y la UI de la pestaña Clases.
--
-- Competencias en habilidades -> effects { kind="skillProf", skill=... }.
-- Herramientas, idiomas, caracteristica y equipo van como `informativo` con su texto.
-- Contenido inicial: los 4 trasfondos nuevos del manual Warcraft (Cap. 3). Los
-- trasfondos estandar del PHB se añadiran como ampliacion cuando corresponda.

HarfordDnDBackgrounds = HarfordDnDBackgrounds or {}

local API = HarfordDnDBackgrounds

local function Skill(skill)
    return { kind = "skillProf", skill = skill }
end

local function Tool(tool)
    return { kind = "toolProf", tool = tool }
end


API.BACKGROUNDS = {
    {
        id = "boticario_oscuro", name = "Boticario Oscuro", source = "Warcraft", icon = "ui_darkshore_warfront_horde_alchemist",
        traits = {
            { id = "bg_bot_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Investigación.", effects = {
                { kind = "skillProf", skill = "Arcano" },
                { kind = "skillProf", skill = "Investigacion" },
            } },
            { id = "bg_bot_herramientas", name = "Competencia con herramientas", type = "pasivo", description = "Suministros de alquimista y equipo de venenos.", effects = {} },
            { id = "bg_bot_caract", icon = "w3reforgedundeadtransport", name = "Caracteristica: Agente de la S.R.B.", type = "pasivo", description = "Tienes acceso a una red de simpatizantes y operativos bajo el respaldo de Lady Sylvanas. Donde haya Renegados, puedes encontrar Boticarios Oscuros dispuestos a ofrecer refugio, información, hierbas o ingredientes alquimicos; a cambio pueden pedirte una o mas tareas.", effects = {} },
            { id = "bg_bot_equipo", name = "Equipo", type = "pasivo", description = "Suministros de alquimista o equipo de venenos, un brazalete con frasco y corona bordados, un cuaderno, un conjunto de tunicas de terciopelo negro y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "doble_agente", name = "Doble Agente", source = "Warcraft",
        aliases = { "agente doble" },
        traits = {
            { id = "bg_dob_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Perspicacia.", effects = {
                { kind = "skillProf", skill = "Engano" },
                { kind = "skillProf", skill = "Perspicacia" },
            } },
            { id = "bg_dob_herramientas", name = "Competencia con herramientas", type = "pasivo", description = "Kit de falsificacion.", effects = {} },
            { id = "bg_dob_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Uno de tu elección perteneciente a la facción opuesta.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_dob_caract", name = "Caracteristica: Dos caras de una moneda", type = "pasivo", description = "Tienes contactos en ambas organizaciones a las que proporcionas información. Suelen permitirte cometer delitos menores sin temor a castigo o manejar un negocio sin pagar todos los impuestos, y puedes obtener audiencias con funcionarios de ambas.", effects = {} },
            { id = "bg_dob_equipo", name = "Equipo", type = "pasivo", description = "Kit de falsificacion, daga, dos piezas de tiza, 4 hojas de pergamino, una botella de tinta, una pluma, un conjunto de ropa de viajero y una bolsa de cinturon con 15 po.", effects = {} },
        },
    },
    {
        id = "crianza_faccion", name = "Crianza en la Faccion", source = "Warcraft",
        aliases = { "criado por la faccion", "criado_por_la_facci_n", "crianza de la faccion" },
        traits = {
            { id = "bg_cri_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Percepción.", effects = {
                { kind = "skillProf", skill = "Historia" },
                { kind = "skillProf", skill = "Percepcion" },
            } },
            { id = "bg_cri_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Puedes hablar Darnassiano, Draenei, Enano o Gnómico.", effects = {}, choice = { slots = 1, options = { { id = "idioma_darnassiano", label = "Darnassiano", effects = { { kind = "language", language = "Darnassiano" } } }, { id = "idioma_draenei", label = "Draenei", effects = { { kind = "language", language = "Draenei" } } }, { id = "idioma_enano", label = "Enano", effects = { { kind = "language", language = "Enano" } } }, { id = "idioma_gnomico", label = "Gnomico", effects = { { kind = "language", language = "Gnomico" } } } } } },
            { id = "bg_cri_caract", name = "Caracteristica: Lealtad falsa", type = "pasivo", description = "Tu raza y apariencia te permiten ingresar y pasar desapercibido en aldeas y ciudades de ambas facciones; aunque recibas miradas, nadie te detendra ni interrogara, ni levantara armas contra ti.", effects = {} },
            { id = "bg_cri_equipo", name = "Equipo", type = "pasivo", description = "Un conjunto de ropa comun, capa con capucha, un amuleto de tu facción, un libro, una botella de tinta, una pluma y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "aprendiz_kirin_tor", name = "Aprendiz del Kirin Tor", source = "Warcraft",
        traits = {
            { id = "bg_kir_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia.", effects = {
                { kind = "skillProf", skill = "Arcano" },
                { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_kir_herramientas", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de herramientas de artesano.", effects = {} },
            { id = "bg_kir_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_kir_caract", name = "Caracteristica: Mentor prominente", type = "pasivo", description = "Conoces a un mago prominente del Kirin Tor al que puedes recurrir en busca de respuestas e información. A discreción del DM, la información del mentor puede ser falsa, incompleta o tardia.", effects = {} },
            { id = "bg_kir_equipo", name = "Equipo", type = "pasivo", description = "Una botella de tinta de alta calidad, una pluma, tiza, un estuche para pergaminos con 5 hojas, tunicas, una vela, caja de yesca y una bolsa con 15 po.", effects = {} },
        },
    },
    -- ===== Trasfondos del Manual del Jugador (PHB 5e ES) =====
    {
        id = "acolito", name = "Acolito", source = "PHB", icon = "spell_holy_impholyconcentration",
        aliases = { "ac_lito" },
        traits = {
            { id = "bg_aco_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Religión.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Religion" },
            } },
            { id = "bg_aco_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "choice", description = "Dos idiomas de tu elección.", effects = {}, choice = { slots = 2, optionsFrom = "language" } },
            { id = "bg_aco_caract", icon = "achievement_dungeon_ataldazar", name = "Caracteristica: Refugio del fiel", type = "pasivo", description = "Tu y tus companeros podeis recibir sanacion y cuidados gratuitos en templos y lugares consagrados a tu fe (aportando los componentes materiales). Los fieles de tu religión te mantienen con un nivel de vida modesto.", effects = {} },
            { id = "bg_aco_equipo", name = "Equipo", type = "pasivo", description = "Símbolo sagrado, devocionario o rueda de oraciones, 5 varas de incienso, vestiduras, ropas comunes y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "animador", name = "Animador", variants = { { id = "animador_gladiador", name = "Gladiador", desc = "Los gladiadores son tan merecedores del título de animador como un juglar o un artista circense, solo que recurren a las artes del combate para dar al público un espectáculo del que disfrutar. Esta clase de florituras marciales son un tipo de actuación, aunque también podrías ganarte la vida como saltimbanqui o actor.  Podrás usar el rasgo Por petición popular para encontrar dónde actuar en cualquier entorno en el que se conciba el combate como un entretenimiento. Una arena de gladiadores o un club de la lucha son dos buenos ejemplos.  Puedes sustituir el instrumento musical de tu equipo inicial por un arma inusual (aunque asequible), como puede ser un tridente o una red.", icon = "achievement_featsofstrength_gladiator_03" } }, source = "PHB", icon = "achievement_halloween_smiley_01",
        traits = {
            { id = "bg_ani_comp", name = "Competencias", type = "pasivo", description = "Competencia en Acrobacias e Interpretación.", effects = {
                { kind = "skillProf", skill = "Acrobacias" }, { kind = "skillProf", skill = "Interpretacion" },
            } },
            { id = "bg_ani_herr", name = "Competencia con herramientas", type = "pasivo", description = "Útiles para disfrazarse y un tipo de instrumento musical.", effects = {} },
            { id = "bg_ani_caract", icon = "eps_bg3_songofrest", name = "Caracteristica: Por peticion popular", type = "pasivo", description = "Siempre encuentras un sitio donde actuar (posada, taberna, circo, teatro, corte) y consigues comida y alojamiento modesto o comodo si actúas cada noche. La gente te reconoce allí donde has actuado.", effects = {} },
            { id = "bg_ani_equipo", name = "Equipo", type = "pasivo", description = "Instrumento musical, el favor de un admirador, disfraz y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "artesano_gremial", name = "Artesano gremial", variants = { { id = "artesano_gremial_comerciante_gremial", name = "Comerciante gremial", desc = "En lugar de pertenecer a un gremio de artesanos, formas parte de un gremio de comerciantes, caravaneros o tenderos. No produces objetos tú mismo, sino que para ganarte la vida compras y vendes el trabajo de los demás (o las materias primas que los artesanos necesitan para hacer su trabajo). Tu gremio podría tratarse de un gran consorcio (o familia) de mercaderes con intereses a lo largo y ancho de la región. Quizás transportabas bienes de un sitio a otro, ya fuera en barco, carro o caravana. O puede que se los compraras a mercaderes itinerantes y los vendieras en tu pequeña tienda. En cierta forma, la vida de un comerciante en tránsito se parece mucho más a la aventura que la de un artesano.  En lugar de ser competente con herramientas de artesano, podrías serlo con herramientas de navegación o en un idioma adicional. Si decides renunciar a las herramientas de artesano, podrías poseer una mula y un carro mercante.", icon = "eps_arc_sign_oribos_trade" } }, source = "PHB", icon = "eps_arc_sign_oribos_trade",
        traits = {
            { id = "bg_art_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Persuasión.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_art_herr", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de herramientas de artesano.", effects = {} },
            { id = "bg_art_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_art_caract", icon = "achievement_guildperk_workingovertime", name = "Caracteristica: Miembro de un gremio", type = "pasivo", description = "Tu gremio te da comida y alojamiento si lo necesitas, contactos comerciales y apoyo politico/legal. Debes pagar una cuota mensual de 5 po para mantener los beneficios.", effects = {} },
            { id = "bg_art_equipo", name = "Equipo", type = "pasivo", description = "Herramientas de artesano (un tipo), carta de presentacion de tu gremio, ropas de viaje y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "charlatan", name = "Charlatan", source = "PHB",
        aliases = { "charlat_n" },
        traits = {
            { id = "bg_cha_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Juego de Manos.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "JuegoManos" },
            } },
            { id = "bg_cha_herr", name = "Competencia con herramientas", type = "pasivo", description = "Útiles para disfrazarse y útiles para falsificar.", effects = {} },
            { id = "bg_cha_caract", name = "Caracteristica: Identidad falsa", type = "pasivo", description = "Tienes una segunda identidad con documentación, disfraces y conocidos que responden por ella. Puedes falsificar cualquier documento cuyo formato o caligrafia hayas visto antes.", effects = {} },
            { id = "bg_cha_equipo", name = "Equipo", type = "pasivo", description = "Ropas de calidad, útiles para disfrazarse, herramientas de un timo a tu elección y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "criminal", name = "Criminal", variants = { { id = "criminal_espia", name = "Espía", desc = "Aunque tus facultades no son muy distintas de las de un ladrón o un contrabandista, las has adquirido y puesto en práctica en un contexto muy distinto: como espía. Quizá seas un agente oficial, autorizado por la corona, o puede que vendieras los secretos que descubriste al mejor postor.", icon = "inv_misc_spyglass_01" } }, source = "PHB",
        traits = {
            { id = "bg_cri_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Sigilo.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_cri_herr", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de juego y herramientas de ladrón.", effects = {} },
            { id = "bg_crim_caract", name = "Caracteristica: Contacto criminal", type = "pasivo", description = "Tienes un contacto de confianza que enlaza con una red de criminales. Sabes enviar y recibir mensajes a través de mensajeros, caravaneros corruptos y marineros incluso a distancia.", effects = {} },
            { id = "bg_crim_equipo", name = "Equipo", type = "pasivo", description = "Palanqueta, ropas oscuras con capucha y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "ermitano", name = "Ermitaño", source = "PHB",
        aliases = { "ermita_o" },
        desc = "Has pasado gran parte de tus años de aprendizaje aislado, ya fuera como parte de una comunidad resguardada del exterior, como un monasterio, o completamente solo. Apartado del clamor de la sociedad has encontrado quietud, soledad y puede que, incluso, algunas de las respuestas que estabas buscando.",
        traits = {
            { id = "bg_erm_comp", name = "Competencias", type = "pasivo", description = "Competencia en Medicina y Religión.", effects = {
                { kind = "skillProf", skill = "Medicina" }, { kind = "skillProf", skill = "Religion" },
            } },
            { id = "bg_erm_herr", name = "Competencia con herramientas", type = "pasivo", description = "Útiles de herborista.", effects = {} },
            { id = "bg_erm_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_erm_caract", name = "Caracteristica: Descubrimiento", type = "pasivo", description = "Tu retiro te hizo participe de un descubrimiento único y poderoso: una gran revelacion sobre el cosmos, un lugar ignoto, un hecho olvidado o una reliquia capaz de reescribir la historia.", effects = {} },
            { id = "bg_erm_equipo", name = "Equipo", type = "pasivo", description = "Estuche con notas de tus estudios u oraciones, manta de invierno, ropas comunes, útiles de herborista y 5 po.", effects = {} },
        },
    },
    {
        id = "erudito", name = "Erudito", source = "PHB", icon = "wh_focusedmind",
        traits = {
            { id = "bg_eru_comp", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia.", effects = {
                { kind = "skillProf", skill = "Arcano" }, { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_eru_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "choice", description = "Dos idiomas de tu elección.", effects = {}, choice = { slots = 2, optionsFrom = "language" } },
            { id = "bg_eru_caract", icon = "w3reforgedarcanescroll", name = "Caracteristica: Investigador", type = "pasivo", description = "Cuando intentas aprender o recordar algo, aunque no tengas la información, sueles saber donde encontrarla o quien puede proporcionartela (biblioteca, universidad, otros eruditos).", effects = {} },
            { id = "bg_eru_equipo", name = "Equipo", type = "pasivo", description = "Botella de tinta negra, pluma, cuchillo pequeño, carta de un colega muerto con una pregunta sin responder, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "heroe_pueblo", name = "Heroe del pueblo", source = "PHB",
        aliases = { "h_roe del pueblo", "h_roe_del_pueblo" },
        traits = {
            { id = "bg_her_comp", name = "Competencias", type = "pasivo", description = "Competencia en Supervivencia y Trato con Animales.", effects = {
                { kind = "skillProf", skill = "Supervivencia" }, { kind = "skillProf", skill = "Animales" },
            } },
            { id = "bg_her_herr", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de herramientas de artesano y vehículos terrestres.", effects = {} },
            { id = "bg_her_caract", name = "Caracteristica: Hospitalidad rural", type = "pasivo", description = "Por tu origen humilde te relacionas con facilidad con el pueblo llano, que te ofrece un lugar donde esconderte, descansar o recuperarte, y te oculta de quien te persiga (sin arriesgar sus vidas).", effects = {} },
            { id = "bg_her_equipo", name = "Equipo", type = "pasivo", description = "Herramientas de artesano (un tipo), pala, olla de hierro, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "huerfano", name = "Huerfano", source = "PHB", icon = "eps_lol_profileicon_ezbereal",
        aliases = { "hu_rfano" },
        traits = {
            { id = "bg_hue_comp", name = "Competencias", type = "pasivo", description = "Competencia en Juego de Manos y Sigilo.", effects = {
                { kind = "skillProf", skill = "JuegoManos" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_hue_herr", name = "Competencia con herramientas", type = "pasivo", description = "Herramientas de ladrón y útiles para disfrazarse.", effects = {} },
            { id = "bg_hue_caract", icon = "eps_lol_profileicon_theblackroseremembers", name = "Caracteristica: Secretos de la ciudad", type = "pasivo", description = "Conoces los pasadizos y patrones secretos de toda ciudad. Fuera de combate, tu y los companeros a los que guies viajais entre dos puntos de una ciudad al doble de velocidad.", effects = {} },
            { id = "bg_hue_equipo", name = "Equipo", type = "pasivo", description = "Cuchillo pequeño, mapa de la ciudad en la que creciste, raton mascota, recuerdo de tus padres, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "marinero", name = "Marinero", variants = { { id = "marinero_pirata", name = "Pirata", desc = "Has pasado tu juventud bajo la influencia de un temible pirata; un asesino despiadado que te enseñó a sobrevivir en un mundo de tiburones y salvajes. Te has dado el gusto de hurtar a otros barcos y has enviado a más de un alma a una tumba salada. El miedo y el derramamiento de sangre no te son extraños, pues te has forjado una despreciable reputación en multitud de puertos.  Si decides que tu carrera como marinero ha incluido la piratería, puedes elegir el rasgo Mala Reputación en lugar de Pasaje en un Barco.", icon = "inv_helm_cloth_b_01pirate_classic" } }, source = "PHB",
        traits = {
            { id = "bg_mar_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Percepción.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Percepcion" },
            } },
            { id = "bg_mar_herr", name = "Competencia con herramientas", type = "pasivo", description = "Herramientas de navegante y vehículos acuaticos.", effects = {} },
            { id = "bg_mar_caract", name = "Caracteristica: Pasaje en un barco", type = "pasivo", description = "Puedes conseguir pasaje gratuito en un velero para ti y tus companeros (a cambio de ayudar a la tripulacion). El DM decide la ruta y el tiempo de viaje.", effects = {} },
            { id = "bg_mar_equipo", name = "Equipo", type = "pasivo", description = "Cabilla (garrote), 50 pies de cuerda de seda, amuleto de la suerte, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "noble", name = "Noble", variants = { { id = "noble_caballero_nobiliario", name = "Caballero nobiliario", desc = "En la mayoría de sociedades, caballero es el más bajo de los títulos nobiliarios. Si quieres ser un caballero, escoge el rasgo Siervos (mira el cuadro de texto) en lugar de Posición de Privilegio. Además, uno de tus siervos es reemplazado por un noble que te acompaña como escudero. Te asiste a cambio de que le ayudes a convertirse en un caballero de pleno derecho. Tus dos siervos restantes podrían ser un palafrenero que se ocupa de tu caballo y un criado que pule tu armadura (y puede que incluso te ayude a ponértela). Como emblema de hidalguía y los ideales del amor cortés, podrías poseer un estandarte o un presente de un señor o señora noble al que has entregado tu corazón. De forma platónica, claro está. Esta persona podría ser tu vínculo. RASGO ALTERNATIVO: SIERVOS Si tu personaje posee el trasfondo \"noble\", puedes elegir este rasgo de trasfondo en lugar de Posición de Privilegio. Tres criados leales a tu familia están a tu servicio. Estos siervos pueden ser asistentes o mensajeros, y uno de ellos podría incluso ser un mayordomo. Los criados son plebeyos que pueden llevar a cabo las tareas mundanas que les pidas, pero no lucharán por ti, no te seguirán a zonas claramente peligrosas (como mazmorras) y te abandonarán si conviertes en una costumbre abusar de ellos o ponerles en peligro.", icon = "wc3_knight" } }, source = "PHB", icon = "w3reforgedgoldring",
        traits = {
            { id = "bg_nob_comp", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Persuasión.", effects = {
                { kind = "skillProf", skill = "Historia" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_nob_herr", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de juego a tu elección.", effects = {} },
            { id = "bg_nob_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_nob_caract", icon = "eps_wc3h_evilhumanqueen", name = "Caracteristica: Posicion de privilegio", type = "pasivo", description = "Por tu alcurnia, la gente piensa lo mejor de ti. Eres bienvenido en la alta sociedad y el pueblo llano evita tu desaprobacion; puedes conseguir audiencia con un noble local.", effects = {} },
            { id = "bg_nob_equipo", name = "Equipo", type = "pasivo", description = "Ropas de calidad, anillo de sellar, documento que acredita el linaje y un monedero con 25 po.", effects = {} },
        },
    },
    {
        id = "salvaje", name = "Salvaje", source = "PHB",
        traits = {
            { id = "bg_sal_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Supervivencia.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Supervivencia" },
            } },
            { id = "bg_sal_herr", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de instrumento musical.", effects = {} },
            { id = "bg_sal_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_sal_caract", name = "Caracteristica: Vagabundo", type = "pasivo", description = "Tienes memoria excelente para geografía y mapas (recuerdas terreno y asentamientos cercanos) y puedes conseguir agua y comida para hasta seis personas al día en territorio con caza, bayas y agua.", effects = {} },
            { id = "bg_sal_equipo", name = "Equipo", type = "pasivo", description = "Bastón, trampa para cazar, trofeo de un animal que mataste, ropas de viaje y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "soldado", name = "Soldado", source = "PHB",
        traits = {
            { id = "bg_sol_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo e Intimidación.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Intimidacion" },
            } },
            { id = "bg_sol_herr", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de juego y vehículos terrestres.", effects = {} },
            { id = "bg_sol_caract", name = "Caracteristica: Rango militar", type = "pasivo", description = "Conservas un rango militar: los leales a tu antigua organización reconocen tu autoridad, obedecen órdenes de rango inferior y puedes solicitar equipo y caballos temporales o acceder a campamentos y fortalezas.", effects = {} },
            { id = "bg_sol_equipo", name = "Equipo", type = "pasivo", description = "Insignia de rango, trofeo de un enemigo muerto, juego de dados o baraja, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    -- ===== Trasfondos de mesa / suplementos usados en perfiles Harford =====
    {
        id = "capitan_veterano_harford", name = "Capitan veterano harford", source = "Harford", icon = "inv_tabard_duelersguild",
        aliases = { "capitan", "capitan harford", "veterano harford" },
        desc = "Fuiste mas que un simple mercenario: diste órdenes que salvaron vidas y lideraste cuando otros habrian huido. Tu reputación como Capitán de la Compañía Harford te precede en muchos rincones del mundo.",
        traits = {
            { id = "bg_capharf_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo.", effects = {
                { kind = "skillProf", skill = "Atletismo" },
            } },
            { id = "bg_har_cap_autoridad", icon = "achievement_bg_3flagcap_nodeaths", name = "Autoridad del capitan harford", type = "pasivo", description = "Fuiste mas que un simple mercenario: diste órdenes que salvaron vidas y lideraste cuando otros habrian huido. Tu reputación como Capitán de la Compañía Harford te precede en muchos rincones del mundo. Cuando busques ayuda, refugio o información en zonas bajo control de la Alianza o entre enclaves mercenarios independientes, puedes invocar tu antiguo rango para obtener apoyo de antiguos subordinados, simpatizantes o contactos respetuosos. Esta ayuda puede manifestarse como alojamiento seguro, acceso a recursos limitados, reclutas dispuestos a seguirte temporalmente o información vital. Además, tienes ventaja en tiradas de Persuasión, Engaño o Intimidación al tratar con otros mercenarios, criminales reformados, soldados veteranos o desertores, oficiales retirados o cualquiera que haya servido en estructuras militares neutrales o de la Alianza. Tu rango en la compañía te permite hablar en calidad de oficial de la misma y ser su portavoz publico. Además, una vez por descanso largo tienes ventaja en una tirada de Persuasión a los mercenarios bajo tu mando.", effects = {} },
        },
    },
    {
        id = "el_loco", name = "El loco", source = "Harford", icon = "spell_magic_polymorphrabbit",
        aliases = { "loco" },
        desc = "Tu paso por la Compañía Harford, la Espada de Ébano y una antigua herida runica te han dejado una reputación irregular, útil y difícil de ignorar.",
        traits = {
            { id = "bg_loco_comp", name = "Competencias", type = "pasivo", description = "Competencia en Persuasión.", effects = {
                { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_loco_espiritu", icon = "inv_tabard_duelersguild", name = "Espiritu harford", type = "pasivo", description = "Cuando trates de obtener ayuda, refugio o información en zonas controladas por la Alianza o por enclaves mercenarios independientes, puedes encontrar a antiguos miembros, simpatizantes o beneficiarios de la Compañía Harford dispuestos a asistirte, aunque de forma irregular o inesperada. Esta ayuda puede tomar la forma de un escondite, un informante, una tarea pagada o incluso un trago gratis y una advertencia a tiempo. Además, tienes ventaja en tiradas de Persuasión o Engaño al tratar con otros mercenarios, criminales reformados, soldados veteranos o desertores.", effects = {} },
            { id = "bg_loco_autoridad_ebano", icon = "inv_jewelry_talisman_12", name = "Autoridad de la orden: Espada de ebano", type = "pasivo", description = "Llevas contigo la reputación de tu orden allá donde vayas. Al tratar con figuras de fe, fuerzas armadas o la ley, tu rango o aura de disciplina a menudo inspiran deferencia o respeto. Una vez por descanso largo, puedes invocar el nombre o el legado de tu orden para obtener ventaja en una prueba de Persuasión o Intimidación.", effects = {} },
            { id = "bg_loco_impotencia_runica", icon = "eps_bg3_concussivestrike", name = "Impotencia runica", type = "pasivo", description = "Una antigua herida espiritual te ha hecho olvidar parte de tu entrenamiento en el uso de runas, impidiendote utilizar ciertos hechizos propios de un caballero de la muerte. No puedes canalizar Agarre de la muerte, Orden Imperiosa ni lanzar tu Espiral de la muerte a distancia.", effects = {} },
        },
    },
    {
        id = "mercenario_veterano_harford", name = "Mercenario veterano", variants = { { id = "mercenario_veterano_harford_veterano_harford", name = "Veterano Harford", desc = "Has combatido bajo una bandera que pocos recordarían con honor, pero que tú llevas con orgullo. Fuiste parte de la Compañía Harford, un grupo caótico, desigual y extremadamente ruidoso de mercenarios cuya fama procede más de su terquedad y supervivencia que de su disciplina o precisión militar. Leal no al mando, sino al emblema de la compañía y a sus camaradas, tu vida ha sido un desfile de asedios imposibles, retiradas gloriosas, saqueos improvisados y victorias ganadas por pura testarudez.  Quizá empuñaste una espada junto a desertores, navegaste en una bañera flotante apodada \"barco\", o luchaste codo con codo con magos descalzos, guerreros sin armadura y gentes extrañas. En Harford no importaba tu raza, pasado o linaje, sino si sabías mantenerte en pie tras una emboscada. Allí aprendiste a sobrevivir más que a guerrear, y a confiar en la fuerza de la costumbre, el ingenio callejero y la suerte de los insensatos.  ***Competencias en habilidades.*** Escoge una entre Atletismo, Persuasión, Engaño, Supervivencia y Perspicacia.  ***Competencias con armas.*** Armas marciales.  ***Competencias con herramientas.*** Un juego y otra herramienta entre herramientas de ladrón, vehículos terrestres o acuáticos o un instrumento musical (cualquier tipo de tambor o flauta popular).  ***Equipo.*** Un recuerdo cochambroso de tu tiempo en Harford (un clavo bendito, una petaca vacía, una insignia oxidada...), un juego al que jugabas con tus compañeros de barco o campamento, un tabardo Harford remendado varias veces, y una bolsa con 8 po (2 po se los quedó el capitán al pagaros).", icon = "inv_tabard_duelersguild" } }, source = "Warcraft", icon = "w3reforgedbandit",
        aliases = { "veterano harford", "mercenario veterano", "mercenario harford" },
        desc = "Has combatido bajo una bandera que pocos recordarían con honor, pero que tú llevas con orgullo. Fuiste parte de la Compañía Harford, un grupo caótico, desigual y extremadamente ruidoso de mercenarios cuya fama procede más de su terquedad y supervivencia que de su disciplina o precisión militar. Leal no al mando, sino al emblema de la compañía y a sus camaradas, tu vida ha sido un desfile de asedios imposibles, retiradas gloriosas, saqueos improvisados y victorias ganadas por pura testarudez.\n\nQuizá empuñaste una espada junto a desertores, navegaste en una bañera flotante apodada \"barco\", o luchaste codo con codo con magos descalzos, guerreros sin armadura y gentes extrañas. En Harford no importaba tu raza, pasado o linaje, sino si sabías mantenerte en pie tras una emboscada. Allí aprendiste a sobrevivir más que a guerrear, y a confiar en la fuerza de la costumbre, el ingenio callejero y la suerte de los insensatos.\n\nNumerosas compañías de mercenarios trabajan por todo lo ancho y largo de Azeroth. La mayoría son grupos a pequeña escala que dan trabajo a entre una docena y cien individuos que ofrecen seguridad, persiguen monstruos o bandoleros, o participan en la guerra a cambio de oro. Ciertas organizaciones poseen cientos o miles de miembros y pueden entregar auténticos ejércitos privados a quienes tienen dinero suficiente para pagarlos.\n\nComo mercenario que lucha en contiendas a cambio de dinero, estás muy acostumbrado a jugarte la vida por la oportunidad de ganar parte de un tesoro. Ahora estás dispuesto a matar a enemigos y a conseguir incluso mejores recompensas como aventurero. Tu experiencia te familiariza con los pormenores de la vida del mercenario y es posible que tengas relatos desgarradores de lo acontecido en el campo de batalla.",
        traits = {
            { id = "bg_merc_hab", name = "Competencia en habilidad", type = "choice", description = "Escoge una competencia entre Atletismo, Persuasión, Engaño, Supervivencia y Perspicacia.", choice = { slots = 1, options = {
                { id = "atletismo", label = "Atletismo", effects = { { kind = "skillProf", skill = "Atletismo" } } },
                { id = "persuasion", label = "Persuasion", effects = { { kind = "skillProf", skill = "Persuasion" } } },
                { id = "engano", label = "Engaño", effects = { { kind = "skillProf", skill = "Engano" } } },
                { id = "supervivencia", label = "Supervivencia", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                { id = "perspicacia", label = "Perspicacia", effects = { { kind = "skillProf", skill = "Perspicacia" } } },
            } }, effects = {} },
            { id = "bg_merc_armas", name = "Competencia con armas", type = "pasivo", description = "Competencia con armas marciales.", effects = {
                { kind = "weaponProf", weapon = "armas marciales" },
            } },
            { id = "bg_merc_herr_juego", name = "Juego", type = "pasivo", description = "Competencia con un juego.", effects = {
                { kind = "toolProf", tool = "Un juego" },
            } },
            { id = "bg_merc_herr", name = "Herramienta adicional", type = "choice", description = "Escoge una herramienta adicional: herramientas de ladrón, vehículos terrestres, vehículos acuaticos o un instrumento musical.", choice = { slots = 1, options = {
                { id = "her_ladron", label = "Herramientas de ladron", effects = { { kind = "toolProf", tool = "Herramientas de ladron" } } },
                { id = "vehiculos_terrestres", label = "Vehiculos terrestres", effects = { { kind = "toolProf", tool = "Vehiculos terrestres" } } },
                { id = "vehiculos_acuaticos", label = "Vehiculos acuaticos", effects = { { kind = "toolProf", tool = "Vehiculos acuaticos" } } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { { kind = "toolProf", tool = "Instrumento musical" } } },
            } }, effects = {} },
            { id = "bg_merc_espiritu", icon = "inv_tabard_duelersguild", name = "Espiritu harford", type = "pasivo", description = "Puedes encontrar antiguos miembros, simpatizantes o beneficiarios de la Compañía Harford dispuestos a asistirte de forma irregular. Además, tienes ventaja en tiradas de Carisma (Persuasión o Engaño) al tratar con mercenarios, criminales reformados, soldados veteranos o desertores.", effects = {} },
            { id = "bg_merc_vida", icon = "w3reforgedmercenarycamp", name = "Vida mercenaria", type = "pasivo", description = "Conoces la vida mercenaria como solo puede hacerlo quien la ha vivido. Identificas a las compañías de mercenarios por sus emblemas y sabes algo de cualquiera de ellas: los nombres y la reputación de sus comandantes y los ejércitos que las han contratado últimamente. Puedes hallar las tabernas y los salones donde moran los mercenarios en cualquier lugar, siempre que hables el idioma local.\n\nSi estructuras tu trabajo de mercenario entre aventuras como parte normal de tu vida cotidiana, obtienes un modo de vida cómodo.", effects = {} },
            { id = "bg_merc_equipo", name = "Equipo", type = "pasivo", description = "Un recuerdo cochambroso de tu tiempo en Harford (un clavo bendito, una petaca vacía, una insignia oxidada...), un juego al que jugabas con tus compañeros de barco o campamento, un tabardo Harford remendado varias veces y una bolsa con 8 po (2 po se los quedó el capitán al pagaros).", effects = {} },
        },
    },
    {
        id = "exiliado_alterac", name = "Exiliado de Alterac", source = "Warcraft",
        aliases = { "alterac", "exiliado alterac", "exiliado de alterac" },
        desc = "Fuiste criado entre los restos de un reino traicionado y borrado del mapa. Tu familia fue leal al trono de Alterac, o quizás solo fue arrastrada por la caída del rey Perenolde y la humillación pública de tu pueblo. Tras la Segunda Guerra, mientras los reinos humanos reescribían la historia, tú creciste escuchando una versión distinta: una de abandono, de culpa compartida, de dignidad pisoteada.\n\nAlgunos de los tuyos se unieron al Sindicato, otros huyeron al exilio, muchos vivieron décadas como ciudadanos de segunda. Pero los exiliados de Alterac no olvidan, y aunque su reino esté en ruinas, su identidad sigue viva. Tú eres uno de ellos: marcado por la historia, endurecido por la pérdida, y con un legado que no desaparece.",
        traits = {
            { id = "bg_alt_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño e Historia.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_alt_herr", name = "Competencia con herramientas", type = "choice", description = "Elige una competencia entre herramientas de falsificacion o kit de disfraz.", choice = { slots = 1, options = {
                { id = "her_falsificacion", label = "Herramientas de falsificacion", effects = { { kind = "toolProf", tool = "Herramientas de falsificacion" } } },
                { id = "her_disfraz", label = "Kit de disfraz", effects = { { kind = "toolProf", tool = "Kit de disfraz" } } },
            } }, effects = {} },
            { id = "bg_alt_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma adicional, como Orco u otro idioma del pueblo que te acogio.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_alt_peso", name = "Peso de un reino caido", type = "pasivo", description = "Puedes identificar a otros exiliados o simpatizantes de Alterac mediante gestos, acentos o simbolos ocultos. Obtienes ventaja en pruebas de Carisma (Persuasión o Engaño) o de Historia cuando trates con individuos marcados por el exilio, la derrota o el legado de la Segunda Guerra. También puedes encontrar refugio entre comunidades marginales, contrabandistas o grupos de exiliados que aun recuerdan a Alterac.", effects = {} },
            { id = "bg_alt_equipo", name = "Equipo", type = "pasivo", description = "Un recuerdo de Alterac, ropa modesta con detalles del color naranja tradicional, un diario familiar o copia clandestina del Decreto de ocupacion, y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "acolito_luz_abisal", name = "Acolito de la Luz Abisal", source = "Warcraft",
        aliases = { "luz abisal", "acolito luz abisal" },
        desc = "Has aprendido a equilibrar devoción, oscuridad y disciplina espiritual en una fe marcada por fuerzas opuestas.",
        traits = {
            { id = "bg_luz_abisal_comp", name = "Competencias", type = "pasivo", description = "Competencia en Religión y Perspicacia.", effects = { Skill("Religion"), Skill("Perspicacia") } },
            { id = "bg_luz_abisal_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con útiles de caligrafo.", effects = { Tool("Utiles de caligrafo") } },
            { id = "bg_luz_abisal_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección, normalmente eredun o shath'yar.", effects = {}, choice = { slots = 1, optionsFrom = "language", exotic = true } },
            { id = "bg_luz_abisal_rasgo", name = "Equilibrio de fuerzas", type = "pasivo", description = "Tu conocimiento de doctrinas contradictorias puede darte acceso, refugio o interpretación religiosa en comunidades marcadas por Luz, Sombra o fuerzas abisales, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "anima_errante", name = "Anima errante", source = "Harford", icon = "ability_warlock_soulswap",
        aliases = { "anima errante" },
        desc = "Eras un eco, una chispa de esencia perdida entre la vida y la muerte, hasta que encontraste un cuerpo vacío y lo ocupaste. Ahora exploras el mundo de los vivos como algo casi humano.",
        traits = {
            { id = "bg_anima_visitante", icon = "ability_argus_deathfog", name = "Visitante del mas alla", type = "pasivo", description = "Puedes percibir presencias no corporeas ocultas (fantasmas, almas, animas) en un radio de 9 m (30 pies), y ellas también pueden percibirte a ti. Obtienes ventaja en pruebas de Sigilo realizadas en lugares oscuros, silenciosos o cargados de energía mágica o espiritual, como cementerios, templos antiguos o ruinas. Los efectos que detectarian vida o muerte, como Detectar el Bien y el Mal o Sentido Divino, te perciben de forma confusa: ni viva ni muerta, apenas un eco. Una vez por descanso largo, puedes alterar levemente tu forma corporal (ojos apagados, silueta desvanecida, voz hueca) para obtener ventaja en una prueba de Intimidación o Engaño según la situación.", effects = {} },
        },
    },
    {
        id = "adepto_cosecha_oscura", name = "Adepto de la cosecha oscura", source = "Warcraft",
        aliases = { "cosecha oscura", "adepto cosecha oscura" },
        desc = "Has seguido códigos y secretos de quienes buscan, estudian o atan poderes demoníacos con disciplina peligrosa.",
        traits = {
            { id = "bg_cosecha_comp", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano y Engaño.", effects = { Skill("Arcano"), Skill("Engano") } },
            { id = "bg_cosecha_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con útiles de caligrafo.", effects = { Tool("Utiles de caligrafo") } },
            { id = "bg_cosecha_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_cosecha_codigo", name = "Codigo del buscador de Demonios", type = "pasivo", description = "Conoces signos, pactos y protocolos ocultistas útiles para tratar con otros buscadores de secretos demoníacos, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "agente_principe_mercante", name = "Agente de principe mercante", source = "Warcraft",
        aliases = { "agente de principe mercante", "agente_de_pr_ncipe_mercante", "principe mercante", "agente mercante" },
        desc = "Los agentes de príncipes mercantes son comerciantes astutos, expertos en cerrar tratos y aprovechar oportunidades en su constante búsqueda de riqueza e influencia.\n\nEres un servidor a merced de un príncipe mercante —ya sea astuto, despiadado, o simplemente codicioso hasta lo enfermizo— y eso te convierte en alguien digno de atención. Como Agente de príncipe mercante, representas los intereses de su cártel en Azeroth y más allá, cerrando tratos, asegurando recursos y expandiendo su influencia por cualquier medio necesario.\n\nEres parte emprendedor, parte matón, parte embaucador de lengua de plata, con un talento innato para convertir riesgos en ganancias. Desde Gadgetzan hasta Trinquete, de salas de juntas goblin hasta yacimientos en la jungla, tu trabajo es simple: hacer más rico a tu jefe... y asegurarte de obtener tu parte.",
        traits = {
            { id = "bg_principe_comp", name = "Competencias", type = "pasivo", description = "Competencia en Persuasión y Perspicacia.", effects = { Skill("Persuasion"), Skill("Perspicacia") } },
            { id = "bg_principe_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con herramientas de navegador y un tipo de herramientas de artesano.", effects = { Tool("Herramientas de navegador"), Tool("Herramientas de artesano") } },
            { id = "bg_principe_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "informativo", description = "Hablas, lees y escribes Goblin.", effects = { { kind = "language", language = "Goblin" } } },
            { id = "bg_principe_conexiones", name = "Conexiones del cartel", type = "pasivo", description = "Puedes recurrir a contactos, intermediarios y favores comerciales del cartel en puertos, mercados y enclaves goblin, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "bucanero_retirado", name = "Bucanero retirado", source = "Warcraft",
        desc = "Los Bucaneros Velasangre comparten un oscuro pasado de piratería y anarquía. A menudo se definen por su crueldad despiadada, astucia marinera y una inclinación por buscar tesoros y poder a través del saqueo en alta mar.\n\nFuiste en su día un temido miembro de una tripulación notoria, sembrando el terror por los mares con tus hazañas piratas.\n\nSin embargo, has dejado atrás tu pasado criminal. Ahora recorres el mundo, buscando demostrar tu valía más allá de la piratería. Ya sea que hayas pertenecido a los Bucaneros Velasangre, los Asaltantes Aguasnegras, las Ratas de Pantoque o cualquier otra tripulación, el mundo te percibe del mismo modo.",
        traits = {
            { id = "bg_buc_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Atletismo.", effects = { Skill("Engano"), Skill("Atletismo") } },
            { id = "bg_buc_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con herramientas de navegación y una herramienta de artesano a tu elección.", effects = { Tool("Herramientas de navegacion"), Tool("Herramientas de artesano") } },
            { id = "bg_buc_canalla", name = "Canalla veterano", type = "pasivo", description = "Reconoces códigos, deudas y costumbres de marineros, piratas y contrabandistas, y puedes encontrar ayuda entre ellos si el DM lo permite.", effects = {} },
        },
    },
    {
        id = "buscador_sombrio", name = "Buscador sombrio", source = "Harford", icon = "dos2_shadow12",
        aliases = { "buscador sombrio" },
        desc = "Nunca has tenido un gran propósito heroico. Te mueven impulsos mas pequeños pero intensos: proteger lo que importa y encontrar tu lugar en un mundo que nunca te lo puso fácil.",
        traits = {
            { id = "bg_busc_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Engaño.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Engano" },
            } },
            { id = "bg_sombrio_sintonia_vil", icon = "eps_wc3h_felpower", name = "Sintonia vil", type = "pasivo", description = "Tu relación con los demonios no es teorica ni lejana: sabes de sacrificios, muerte y decisiones irreversibles. Tienes ventaja en tiradas de salvación contra miedo causadas por demonios, no muertos y efectos de corrupción vil o necrótica. Además, una vez por descanso largo, cuando reduzcas a una criatura a 0 PG con un conjuro necrótico, recuperas mana igual a tu modificador de Inteligencia.", effects = {} },
        },
    },
    {
        id = "caballero_orden", name = "Caballero de la orden", source = "Warcraft",
        aliases = { "caballero de la orden" },
        desc = "Los miembros de las órdenes sagradas —ya sean de la Luz u otras— se distinguen por su convicción inquebrantable. La Mano de Plata enseña humildad y sacrificio; los Caballeros de Sangre predican la fuerza a través del dominio; los Caminasol buscan equilibrio entre lo espiritual y lo marcial; la Cruzada Escarlata demanda celo absoluto; y la Espada de Ébano enseña que incluso la muerte puede redimirse. Sin importar el camino, todos los caballeros de tales órdenes cargan con el peso de sus votos en cada decisión.\n\nFuiste entrenado por una orden marcial estructurada como la Mano de Plata, los Caballeros de Sangre, los Caminasol, la Cruzada Escarlata o la Espada de Ébano, todos ellos devotos de un ideal superior al de ellos mismos.\n\nYa sea que hayas sido un acólito de la Luz, un sacerdote de An’she, o un soldado templado en las sombras, tu disciplina y sentido del deber te distinguen. Algunos aún portan el símbolo de su orden con orgullo; otros recorren un camino solitario, comprometidos con causas que otros han abandonado o repudiado. Ya fuera que tus votos se juraran bajo el sol o se grabaran en la no-muerte, estos continúan moldeando tus convicciones... y tu poder.",
        traits = {
            { id = "bg_ord_comp", name = "Competencias", type = "pasivo", description = "Competencia en Religión y Persuasión.", effects = { Skill("Religion"), Skill("Persuasion") } },
            { id = "bg_ord_herr", name = "Competencia con herramientas", type = "choice", description = "Elige herramientas de herrero o útiles de caligrafo.", choice = { slots = 1, options = {
                { id = "her_herrero", label = "Herramientas de herrero", effects = { Tool("Herramientas de herrero") } },
                { id = "caligrafo", label = "Utiles de caligrafo", effects = { Tool("Utiles de caligrafo") } },
            } }, effects = {} },
            { id = "bg_ord_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_ord_autoridad", icon = "inv_jewelry_talisman_12", name = "Autoridad de la orden", type = "pasivo", description = "Tu afiliacion puede abrir puertas entre miembros, aliados o instituciones que respeten a la orden, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "cruzado_argenta", name = "Cruzado Argenta", source = "Warcraft",
        aliases = { "cruzada argenta", "argenta" },
        desc = "Has servido en la Cruzada Argenta, sobreviviendo al fanatismo, la guerra santa y la disciplina de quienes se enfrentan a horrores imposibles.",
        traits = {
            { id = "bg_arg_comp", name = "Competencias", type = "pasivo", description = "Competencia en Religión y Atletismo.", effects = { Skill("Religion"), Skill("Atletismo") } },
            { id = "bg_arg_juego", name = "Juego", type = "pasivo", description = "Competencia con un juego de azar.", effects = { Tool("Un juego de azar") } },
            { id = "bg_arg_determinacion", name = "Determinacion inquebrantable", type = "pasivo", description = "Tu reputación como cruzado puede darte reconocimiento, ayuda o confianza frente a amenazas no-muertas, corruptas o apocalipticas, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "desertor_errante", name = "Desertor errante", source = "Warcraft", icon = "achievement_general_classicbattles",
        aliases = { "desertor" },
        desc = "Los desertores errantes son individuos que han escapado del dominio de su facción, guiados por el deseo de autonomía personal y la oportunidad de reescribir su destino bajo sus propios términos.\n\nLos desertores errantes son individuos que han dejado atrás las ataduras de su facción anterior, impulsados por una sed de libertad personal y el deseo de forjar su propio destino. Desencantados con las ideologías que antes los definían, siguen ahora un camino incierto como agentes independientes, guiados por un renovado sentido de autonomía y su propio código moral.\n\nEstos desertores están unidos por su valentía para romper con el pasado, abrazando una vida de incertidumbre mientras forjan alianzas, desafían normas y buscan su lugar en el turbulento mundo de Azeroth.",
        traits = {
            { id = "bg_des_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Supervivencia.", effects = { Skill("Perspicacia"), Skill("Supervivencia") } },
            { id = "bg_des_herr", name = "Competencia con herramientas", type = "choice", description = "Elige un juego de azar o un instrumento musical.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego de azar", effects = { Tool("Un juego de azar") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_des_saboteador", icon = "inv_misc_enggizmos_38", name = "Saboteador", type = "pasivo", description = "Conoces rutinas militares y puntos debiles de campamentos, patrullas y suministros, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "eremita", name = "Eremita", source = "Warcraft",
        aliases = { "eremita erudito" },
        desc = "Los Eremitas, como colectivo, comparten una sed insaciable por el conocimiento, una curiosidad inagotable por los misterios del mundo y una devoción inquebrantable por preservar y compartir las historias del pasado, presente y futuro de Azeroth.\n\nComo devoto miembro de los Eremitas, eres un ávido buscador de conocimiento, impulsado por una pasión por desentrañar el rico tapiz de historia, leyenda y cultura que recorre todo Azeroth. Tu insaciable curiosidad y meticulosa atención al detalle te convierten en un hábil historiador y narrador, encargado de preservar las historias más preciadas del mundo. Con reverencia por el pasado y el deseo de compartir sus enseñanzas, te embarcas en misiones en busca de conocimientos olvidados y verdades ocultas, asegurándote de que el legado de Azeroth perdure para las generaciones futuras.",
        traits = {
            { id = "bg_ere_comp", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Perspicacia.", effects = { Skill("Historia"), Skill("Perspicacia") } },
            { id = "bg_ere_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con suministros de caligrafo y un instrumento musical.", effects = { Tool("Suministros de caligrafo"), Tool("Instrumento musical") } },
            { id = "bg_ere_perspicacia", name = "Perspicacia erudita", type = "pasivo", description = "Tu retiro y estudio te permiten reconocer claves historicas, simbolicas o personales que otros pasan por alto, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "feriante_luna_negra", name = "Feriante de la Luna Negra", source = "Warcraft",
        aliases = { "luna negra", "feriante" },
        desc = "Eres un artista cautivador dentro del enigmático reino de la Feria de la Luna Negra. Con tus hipnotizantes actos de magia, arte o hazañas audaces, atraes multitudes que acuden a presenciar tus maravillosas exhibiciones. Como artista de la Feria, ofreces un escape muy necesario de las penas del mundo, brindando sonrisas y asombro a quienes se congregan bajo las coloridas carpas del carnaval.\n\nSin embargo, entre tanto encanto, percibes un misterio más profundo que envuelve los orígenes de la Feria, y navegas sus secretos con la misma destreza con la que ejecutas tus actuaciones.",
        traits = {
            { id = "bg_luna_comp", name = "Competencias", type = "pasivo", description = "Competencia en Interpretación y Juego de Manos.", effects = { Skill("Interpretacion"), Skill("JuegoManos") } },
            { id = "bg_luna_herr1", name = "Kit de disfraces", type = "pasivo", description = "Competencia con kit de disfraces.", effects = { Tool("Kit de disfraces") } },
            { id = "bg_luna_herr2", name = "Juego o instrumento", type = "choice", description = "Elige un juego o un instrumento musical.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_luna_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_luna_actuacion", name = "Actuacion hipnotica", type = "pasivo", description = "Sabes atraer atencion, distraer y leer al publico mediante espectaculo y misterio, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "devoto_elune", name = "Devoto de Elune", source = "Harford", icon = "eps_wow_eluneschosen",
        aliases = { "devoto de elune", "devota de elune", "devoto elune", "devota elune" },
        desc = "Has dedicado tu vida a servir a Elune, la Dama de la Luna, llevando consuelo, remedios y esperanza a quienes sufren. Para ti, mientras quede una chispa de vida, merece la pena intentar salvarla.",
        traits = {
            { id = "bg_elu_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Medicina y Religión.", effects = {
                Skill("Medicina"), Skill("Religion"),
            } },
            { id = "bg_elu_herborista", name = "Kit de herborista", type = "pasivo", description = "Competencia con kit de herborista.", effects = {
                Tool("Kit de herborista"),
            } },
            { id = "bg_elu_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_elu_luz_sanadora", icon = "hots_tyrande_lightofelune", name = "Luz sanadora", type = "pasivo", description = "En asentamientos con templos, santuarios o comunidades dedicadas a la curación, la naturaleza o una divinidad benevola, puedes solicitar alojamiento, comida y asistencia médica básica para ti y quienes estén bajo tu cuidado. Tu reputación puede abrir hospitales, templos, casas de sanadores y comunidades, a discreción del DM.", effects = {} },
            { id = "bg_elu_equipo", name = "Equipo", type = "pasivo", description = "Símbolo sagrado de Elune, kit de herborista, libro de plegarias, recipiente con hierbas medicinales y ungüentos, manto blanco y azul oscuro, y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "forastero", name = "Forastero", source = "Warcraft",
        aliases = { "extranjero" },
        desc = "La mayoría de los habitantes de Azeroth jamás abandonan su tierra natal. Ya sea un campesino de los Reinos del Este, un tabernero en Kalimdor o un comerciante en Zandalar, muchos viven y mueren sin alejarse más que unos pocos kilómetros de donde nacieron. Tú no eres como ellos.\n\nVienes de una región lejana, exótica o directamente desconocida para la mayoría. Quizá naciste en los valles ocultos de Pandaria, entre las ruinas susurrantes de Uldum, o en alguna aldea perdida de Rasganorte. Tal vez incluso tu patria se halle más allá del Gran Mar o en una isla apenas registrada en los mapas de la Horda o la Alianza. Sea como sea, tu historia es inusual, y las razones que te han traído hasta aquí pueden ser personales, políticas, místicas... o un misterio que prefieres no revelar.\n\nAl llegar a estas tierras, muchas costumbres te resultan extrañas, incluso ridículas; pero también hay maravillas que nunca imaginaste: ciudades suspendidas en el aire, mercados infestados de goblins y criaturas que solo habías oído en viejas canciones. De igual forma, tú eres un enigma andante para los demás: alguien con acento raro, hábitos desconcertantes o apariencia única. Donde vayas, despertarás curiosidad, respeto o desconfianza... o las tres cosas a la vez.",
        traits = {
            { id = "bg_for_comp", name = "Competencias", type = "pasivo", description = "Competencia en Percepción y Perspicacia.", effects = { Skill("Percepcion"), Skill("Perspicacia") } },
            { id = "bg_for_herr", name = "Juego o instrumento", type = "choice", description = "Elige un instrumento o juego de tu patria.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_for_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma cualquiera de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_for_mirada", name = "Todos se fijan en ti", type = "pasivo", description = "Tu presencia forastera puede abrir conversaciones, despertar sospechas o atraer ayuda por curiosidad, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "forjador_torio", name = "Forjador de la Hermandad del Torio", source = "Warcraft",
        aliases = { "hermandad del torio", "forjador de torio", "forjador torio" },
        desc = "Los miembros de la Hermandad del Torio son perfeccionistas incansables, curtidos por el calor de las forjas y la presión de estar siempre un paso por delante de sus rivales. Muchos son toscos, silenciosos, incluso paranoicos, pero todos ellos comparten un respeto absoluto por el arte de su trabajo y una ética inquebrantable respecto a la calidad. La desconfianza hacia otros gremios o clanes, y el secretismo con que guardan sus técnicas, son también comunes entre ellos.\n\nEl fuego, el metal y la tradición te forjaron tanto como el yunque. Has dedicado años de tu vida a trabajar bajo la tutela de un maestro herrero de la Hermandad del Torio, soportando un aprendizaje áspero, vigilado por las brasas del Puesto del Torio y las exigencias despiadadas de los enanos Hierro Negro que renunciaron a Ragnaros.\n\nPerteneces a una casta de artesanos que anteponen la perfección a cualquier otra virtud. La Hermandad no acepta mediocridad: solo aquellos que soportan el calor y la presión de sus hornos pueden ganarse un nombre entre los suyos. Has aprendido los secretos de la forja encantada, de la runomagia práctica, y sabes que el valor de un objeto está en su equilibrio entre utilidad y arte.\n\nPuede que seas enano, pero no necesariamente. Aunque raros, se conocen casos de orcos, elfos o humanos que han sido aceptados como aprendices si demostraban una maestría sin igual y un respeto absoluto por el oficio. En cualquier caso, el orgullo de tu trabajo habla antes que tu raza.",
        traits = {
            { id = "bg_torio_comp", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Perspicacia.", effects = { Skill("Historia"), Skill("Perspicacia") } },
            { id = "bg_torio_herr", name = "Herramientas de forja", type = "pasivo", description = "Competencia con herramientas de forja.", effects = { Tool("Herramientas de forja") } },
            { id = "bg_torio_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Enano y un idioma adicional si ya hablas enano.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_torio_prestigio", name = "Prestigio de la Hermandad del Torio", type = "pasivo", description = "Tu relación con la Hermandad del Torio puede darte acceso a artesanos, talleres, materiales o información de forja, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "guardian_salvaje", name = "Guardian de lo salvaje", source = "Warcraft", icon = "ability_hunter_huntervswild",
        aliases = { "guardian de lo salvaje", "guardiana de lo salvaje", "guardian salvaje" },
        desc = "Los guardianes de lo salvaje se definen por la soledad, el instinto y un profundo respeto por el poder de la naturaleza. Ya sean cazadores, chamanes o exploradores, su rol no es conquistar la naturaleza, sino comprenderla y defenderla.\n\nFuiste entrenado por un enclave primitivo, una sociedad de supervivencia o un grupo de sabiduría salvaje vinculados a organizaciones como el Refugio Alblanco, la Senda Oculta, los Errantes, las Centinelas, las expediciones de Hemet Nesingwary o círculos locales en la naturaleza a lo largo de Azeroth.\n\nDesde las brumosas alturas de las Colinas Pardas hasta las enredadas raíces de Val’sharah y los cañones de Nagrand, los parajes salvajes de Azeroth perduran solo bajo la custodia de quienes conocen sus ritmos. Aprendiste no solo a sobrevivir en tierras indómitas, sino a leer sus señales, proteger sus secretos y restaurar su equilibrio cuando se ve amenazado.",
        traits = {
            { id = "bg_gsal_comp", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Supervivencia.", effects = { Skill("Naturaleza"), Skill("Supervivencia") } },
            { id = "bg_gsal_herr", name = "Competencia con herramientas", type = "choice", description = "Elige kit de herboristeria o herramientas de tallador de madera.", choice = { slots = 1, options = {
                { id = "herboristeria", label = "Kit de herboristeria", effects = { Tool("Kit de herboristeria") } },
                { id = "her_tallador", label = "Herramientas de tallador de madera", effects = { Tool("Herramientas de tallador de madera") } },
            } }, effects = {} },
            { id = "bg_gsal_voz", icon = "ability_hunter_onewithnature", name = "Voz de la naturaleza", type = "pasivo", description = "Puedes interpretar señales naturales y tratar con comunidades o guardianes vinculados a lo salvaje, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "guardia_ciudad", name = "Guardia de ciudad", variants = { { id = "guardia_ciudad_detective", name = "Detective", desc = "Los detectives de una comunidad, menos numerosos que los guardias o los miembros de una patrulla, poseen el deber de resolver crímenes en base a hechos. Aunque raramente se da este tipo de persona en zonas rurales, casi cualquier asentamiento de tamaño decente tiene como mínimo a uno o dos miembros de la guardia con la habilidad de investigar los lugares en los que se ha cometido un crimen y perseguir a los malhechores. Si tienes experiencia previa como investigador, posees competencia en  Investigación en vez de en Atletismo.  (edited)", icon = "Secret" } }, source = "Warcraft", icon = "ability_warrior_vigilance",
        aliases = { "guardia urbano", "guardia de ciudad" },
        desc = "Los detectives de una comunidad, menos numerosos que los guardias o los miembros de una patrulla, poseen el deber de resolver crímenes en base a hechos. Aunque raramente se da este tipo de persona en zonas rurales, casi cualquier asentamiento de tamaño decente tiene como mínimo a uno o dos miembros de la guardia con la habilidad de investigar los lugares en los que se ha cometido un crimen y perseguir a los malhechores. Si tienes experiencia previa como investigador, posees competencia en Investigación en vez de en Atletismo.\n\nTrabajas para la comunidad en la que has crecido y eres su primera línea de defensa contra el crimen. No eres un soldado, sino alguien que dirige su mirada a posibles enemigos. En vez de eso, tu servicio a tu ciudad natal consistió en ayudar a controlar su población y proteger a sus ciudadanos de delincuentes y maleantes de toda clase.\n\nPuede que hayas formado parte de la Guardia de Ventormenta, la fuerza policial armada con porras de Tol Barad, que defiende al pueblo llano tanto de ladrones como de la nobleza pendenciera. O puedes haber sido uno de los valientes defensores de Lunargenta, miembro de la Guardia Gris o incluso miembro de la Guardia de Dalaran, portador de magia. Quizá provienes de Kul Tiras y has sido uno de los guardias de Boralus.\n\nAunque no hayas nacido ni te hayas criado en una ciudad, este trasfondo puede describir tus primeros años como miembro de un cuerpo policial. La mayoría de asentamientos de cualquier tamaño tienen agentes y fuerzas policiales. Incluso las comunidades pequeñas cuentan con sheriffs y alguaciles preparados para proteger su comunidad.",
        traits = {
            { id = "bg_guardia_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Perspicacia.", effects = { Skill("Atletismo"), Skill("Perspicacia") } },
            { id = "bg_guardia_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_guardia_ojo", icon = "eps_wc3h_mountedfootman", name = "Ojo de guardian", type = "pasivo", description = "Conoces rutinas urbanas, jerarquias locales y señales de problemas en una ciudad, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "heredero", name = "Heredero", source = "Warcraft",
        desc = "7. Un relato, una canción, un poema o un secreto puesto por escrito\n\n11. Un colgante con un retrato en miniatura de alguien a quien jamás has conocido.\n\n12. Una urna sellada que no puede abrirse por medios convencionales.\n\n13. Una semilla petrificada o una flor congelada que no debería existir en Azeroth.\n\n14. Una varilla, bastón o fragmento arcano que alguna vez formó parte de un artefacto mayor.\n\n15. Una herramienta artesanal con el sello de un gremio desaparecido.\n\nHas heredado algo de gran valor; no solo dinero o fortuna, sino un objeto que se te ha confiado a ti y solo a ti. Puede que esta herencia te la haya legado directamente un miembro de tu familia por derecho de nacimiento, o bien que te la haya dejado un amigo, mentor, profesor o alguien importante. La revelación de esta herencia te cambió la vida, y quizá te condujo al camino de la aventura. Sin embargo, también puede estar cargada de peligros, incluyendo a quienes codician tu tesoro y te lo quieren arrebatar, si hace falta, por la fuerza.",
        traits = {
            { id = "bg_hered_superv", name = "Supervivencia", type = "pasivo", description = "Competencia en Supervivencia.", effects = { Skill("Supervivencia") } },
            { id = "bg_hered_hab", name = "Habilidad adicional", type = "choice", description = "Elige Conocimiento Arcano, Historia o Religión.", choice = { slots = 1, options = {
                { id = "arcano", label = "Conocimiento Arcano", effects = { Skill("Arcano") } },
                { id = "historia", label = "Historia", effects = { Skill("Historia") } },
                { id = "religion", label = "Religion", effects = { Skill("Religion") } },
            } }, effects = {} },
            { id = "bg_hered_herr", name = "Juego o instrumento", type = "choice", description = "Elige un instrumento musical o un juego.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_hered_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma cualquiera de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_hered_rasgo", name = "Herencia", type = "pasivo", description = "Tu herencia puede darte acceso, interes, enemistades o autoridad según su naturaleza, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "miembro_organizacion", name = "Miembro de organizacion", source = "Warcraft",
        aliases = { "miembro de organizacion", "miembro_de_organizaci_n" },
        desc = "Los miembros de organizaciones han sido moldeados por sus años de servicio dentro de una organización que trasciende naciones y gobiernos. Piensa en cómo esa afiliación ha marcado tu forma de ver el mundo: tu manera de hablar, decidir y confiar puede estar profundamente influenciada por los principios, jerarquías o secretos de tu grupo. Tu vínculo puede ser una lealtad férrea, una carga imposible de soltar o una convicción que guía cada acción. Incluso un ideal noble puede volverse una obsesión peligrosa si se lleva al extremo.\n\nMuchas organizaciones activas en Azeroth y más allá no se ven limitadas por las fronteras nacionales. Estas facciones siguen sus propias prioridades, ajenas a los reinos y gobiernos, y sus miembros actúan cuando la causa lo requiere. Se cuentan entre sus filas fisgones, contrabandistas, mercenarios, alquimistas, chismosos, custodios de archivos arcanos, guardianes de santuarios, vigilantes del Vacío, portadores de la Luz y emisarios sombríos. En el corazón de cada facción hay quienes no solo cumplen con una tarea específica, sino que son su cerebro y su alma.\n\nComo preámbulo de tu carrera como aventurero (o para prepararla), fuiste un agente de una facción específica del mundo. Podrías haber trabajado en público o en secreto, dependiendo de la organización y sus objetivos, así como del grado en que sus ideales coincidieran con los tuyos. Convertirte en aventurero no significa necesariamente que hayas abandonado tu lealtad a la facción (si es que podías hacerlo), y puede que sigas en contacto con ella o incluso que hayas ascendido en su jerarquía.",
        traits = {
            { id = "bg_org_perspicacia", name = "Perspicacia", type = "pasivo", description = "Competencia en Perspicacia.", effects = { Skill("Perspicacia") } },
            { id = "bg_org_hab", name = "Habilidad de faccion", type = "choice", description = "Elige una habilidad de Inteligencia, Sabiduría o Carisma apropiada para la facción.", choice = { slots = 1, options = {
                { id = "arcano", label = "Conocimiento Arcano", effects = { Skill("Arcano") } },
                { id = "historia", label = "Historia", effects = { Skill("Historia") } },
                { id = "investigacion", label = "Investigacion", effects = { Skill("Investigacion") } },
                { id = "naturaleza", label = "Naturaleza", effects = { Skill("Naturaleza") } },
                { id = "religion", label = "Religion", effects = { Skill("Religion") } },
                { id = "medicina", label = "Medicina", effects = { Skill("Medicina") } },
                { id = "percepcion", label = "Percepcion", effects = { Skill("Percepcion") } },
                { id = "trato_animales", label = "Trato con Animales", effects = { Skill("Animales") } },
                { id = "engano", label = "Engaño", effects = { Skill("Engano") } },
                { id = "intimidacion", label = "Intimidacion", effects = { Skill("Intimidacion") } },
                { id = "interpretacion", label = "Interpretacion", effects = { Skill("Interpretacion") } },
                { id = "persuasion", label = "Persuasion", effects = { Skill("Persuasion") } },
            } }, effects = {} },
            { id = "bg_org_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "choice", description = "Dos idiomas de tu elección.", effects = {}, choice = { slots = 2, optionsFrom = "language" } },
            { id = "bg_org_refugio", name = "Refugio", type = "pasivo", description = "Puedes solicitar ayuda, información o refugio limitado a miembros de tu organización, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "miembro_anillo_tierra", name = "Miembro del Anillo de la Tierra", source = "Warcraft",
        aliases = { "anillo de la tierra", "miembro del anillo de la tierra" },
        desc = "Los chamanes del Anillo de la Tierra comparten un profundo respeto por el equilibrio elemental, un compromiso inquebrantable con la sanación y la protección, y una conexión profunda con el mundo natural.\n\nComo miembro reverenciado del Anillo de la Tierra, canalizas las fuerzas primigenias de los elementos para restaurar el equilibrio en Azeroth. Guiado por antiguas tradiciones y una profunda conexión con la naturaleza, has dominado el arte del chamanismo, canalizando los poderes de la tierra, el aire, el fuego y el agua.\n\nCon una devoción inquebrantable por la sanación, la protección y el dominio elemental, te eriges como un guardián del orden natural, encargado de mantener la armonía entre los elementos y el mundo que moldean.",
        traits = {
            { id = "bg_anillo_comp", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Medicina.", effects = { Skill("Naturaleza"), Skill("Medicina") } },
            { id = "bg_anillo_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con kit de herboristeria y un instrumento musical.", effects = { Tool("Kit de herboristeria"), Tool("Instrumento musical") } },
            { id = "bg_anillo_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "informativo", description = "Hablas, lees y escribes Kalimag.", effects = { { kind = "language", language = "Kalimag" } } },
            { id = "bg_anillo_sintonia", name = "Sintonia elemental", type = "pasivo", description = "Puedes interpretar señales elementales y tratar con chamanes o comunidades ligadas al Anillo de la Tierra, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "miembro_tribal", name = "Miembro tribal", source = "Warcraft",
        aliases = { "tribal" },
        desc = "Como miembro de una tribu, lo que más importa es la comunidad. Todos deben colaborar y cumplir su papel para que la tribu funcione. Nadie debe quedarse atrás ni dejar que otros carguen con su parte.\n\nNaciste y creciste en las tierras de tu tribu. Tu tribu posee un territorio propio. Puede que procedas de uno de los muchos clanes menores de tauren que habitan Kalimdor, o de una de las vastas tribus de los trols. Tal vez seas miembro de uno de los clanes prominentes. Quizá provengas de una tribu que vive en aislamiento, con poco contacto con el mundo exterior, o de una que comercia activamente con las sociedades civilizadas.",
        traits = {
            { id = "bg_tribal_comp", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Supervivencia.", effects = { Skill("Naturaleza"), Skill("Supervivencia") } },
            { id = "bg_tribal_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con una herramienta de artesano y un instrumento musical.", effects = { Tool("Herramientas de artesano"), Tool("Instrumento musical") } },
            { id = "bg_tribal_naturaleza", name = "Uno con la naturaleza", type = "pasivo", description = "Tu comunidad y sus costumbres te ayudan a comprender tierras salvajes, clanes y tradiciones locales, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "novato_liga_expedicionarios", name = "Novato de la Liga de Expedicionarios", source = "Warcraft",
        aliases = { "liga de expedicionarios", "novato expedicionarios" },
        desc = "Los miembros de la Liga de Expedicionarios comparten universalmente una curiosidad insaciable por lo desconocido, una camaradería firme que trasciende fronteras y una sed incontenible de descubrimiento.\n\nEres un orgulloso miembro de la renombrada Liga de Expedicionarios, una estimada organización dedicada a descubrir tesoros ocultos, artefactos ancestrales y los misterios del pasado de Azeroth. Con una sed de aventuras y pasión por el conocimiento, has recorrido territorios inexplorados, enfrentado desafíos peligrosos y desentrañado acertijos en tu búsqueda por la verdad.\n\nComo miembro de la Liga de Expedicionarios, encarnas el espíritu de la curiosidad, el coraje y la camaradería, siempre dispuesto a revelar los secretos del mundo y compartirlos con mentes ansiosas por aprender.",
        traits = {
            { id = "bg_liga_comp", name = "Competencias", type = "pasivo", description = "Competencia en Historia e Investigación.", effects = { Skill("Historia"), Skill("Investigacion") } },
            { id = "bg_liga_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con herramientas de cartografo y una herramienta de artesano.", effects = { Tool("Herramientas de cartografo"), Tool("Herramientas de artesano") } },
            { id = "bg_liga_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_liga_pionero", name = "Pionero audaz", type = "pasivo", description = "Puedes obtener ayuda, rumores o acceso a recursos basicos de expedicionarios, arqueologos y exploradores, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "operativo_ravenholdt", name = "Operativo de Ravenholdt", source = "Warcraft",
        aliases = { "ravenholdt" },
        desc = "Estos personajes son infiltradores habilidosos y agentes de la secreta organización Ravenholdt, expertos en espionaje y subterfugio mientras persiguen agendas ocultas y verdades encubiertas.\n\nLos miembros del trasfondo Operativo de Ravenholdt son infiltradores expertos y agentes encubiertos dentro de la enigmática organización Ravenholdt. Con talento para el espionaje y el subterfugio, destacan en la obtención de información crítica, la ejecución de misiones sigilosas y el uso de verdades ocultas. Estos operativos navegan con destreza el mundo del secreto, guiados por motivaciones o lealtades propias, manipulando las sombras para cumplir sus objetivos clandestinos.",
        traits = {
            { id = "bg_raven_comp", name = "Competencias", type = "pasivo", description = "Competencia en Sigilo e Investigación.", effects = { Skill("Sigilo"), Skill("Investigacion") } },
            { id = "bg_raven_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con kit de venenos y kit de disfraces.", effects = { Tool("Kit de venenos"), Tool("Kit de disfraces") } },
            { id = "bg_raven_red", name = "Red de sombras", type = "pasivo", description = "Puedes reconocer contactos, códigos o refugios de redes clandestinas y pedir ayuda discreta, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "protector_cenarion", name = "Protector Cenarion", source = "Warcraft",
        aliases = { "cenarion", "protector cenarion" },
        desc = "Sirves o colaboras con el Círculo Cenarion, defendiendo el equilibrio natural frente a corrupción, guerra o abuso.",
        traits = {
            { id = "bg_cen_comp", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Medicina.", effects = { Skill("Naturaleza"), Skill("Medicina") } },
            { id = "bg_cen_herr", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con kit de herboristeria y una herramienta artesanal.", effects = { Tool("Kit de herboristeria"), Tool("Herramientas de artesano") } },
            { id = "bg_cen_guardian", name = "Guardian de la naturaleza", type = "pasivo", description = "Puedes pedir ayuda o reconocimiento entre druidas, guardianes y comunidades cercanas al Círculo Cenarion, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "superviviente_catastrofe", name = "Superviviente de catastrofe", source = "Warcraft",
        aliases = { "superviviente de catastrofe", "superviviente_de_cat_strofe", "catastrofe" },
        desc = "Estás marcado por la guerra, la catástrofe y el dolor de la supervivencia. Algunos se vuelven guerreros endurecidos. Otros recurren a la sabiduría, el aislamiento o la venganza. Pero todos recuerdan.\n\nHas vivido una de las grandes calamidades de Azeroth —ya sea la invasión de la Plaga, el regreso de la Legión Ardiente, el Cataclismo, o la brutal Cuarta Guerra. Estos eventos transformaron el mundo… y también te transformaron a ti.\n\nLlevas cicatrices que nunca sanaron del todo. Ya sea que defendieras la Costa Quebrada, presenciaras el incendio de Teldrassil, sobrevivieras a la caída de Lordaeron o vieras a Alamuerte desgarrar el cielo, sabes de lo que este mundo es realmente capaz. Los horrores de aquella era te endurecieron… pero también te enseñaron a resistir.",
        traits = {
            { id = "bg_cat_comp", name = "Competencias", type = "pasivo", description = "Competencia en Historia e Intimidación.", effects = { Skill("Historia"), Skill("Intimidacion") } },
            { id = "bg_cat_herr", name = "Competencia con herramientas", type = "choice", description = "Elige un juego o kit de herboristeria.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "herboristeria", label = "Kit de herboristeria", effects = { Tool("Kit de herboristeria") } },
            } }, effects = {} },
            { id = "bg_cat_marcado", name = "Marcado pero en pie", type = "pasivo", description = "Tu experiencia con desastres te ayuda a reconocer riesgos, sobrevivientes, ruinas o traumas similares, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "rostro_olvidado", name = "Rostro olvidado", source = "Harford", icon = "ability_rogue_disguise",
        desc = "En un mundo donde el pasado nunca muere del todo, tu lo mataste primero. Fingiste tu muerte para escapar de la justicia y ahora vives con un nuevo nombre y un nuevo rostro, aunque el eco de tus pecados todavía te sigue.",
        traits = {
            { id = "bg_rostro_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Sigilo.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_rostro_sombras", icon = "spell_rogue_shadow_reflection", name = "Vida entre sombras", type = "pasivo", description = "Has perfeccionado el arte de vivir sin dejar rastro. Puedes crear identidades falsas con facilidad y sabes como manipular registros, sellos y lenguaje corporal para mantener una fachada convincente. Puedes gastar una hora y 5 po para establecer una identidad falsa en una localidad, con documentación y contactos creibles. Mientras mantengas esta identidad, ganas ventaja en tiradas de Engaño y Sigilo al interactuar con autoridades o figuras publicas que no conozcan tu verdadero rostro. Una vez por descanso largo, puedes evitar ser reconocido mágicamente, como con localizar criatura o videncia, siempre que estés usando tu identidad falsa. En ciudades o asentamientos, puedes encontrar un contacto útil (informante, falsificador, contrabandista) que te ofrezca información o refugio temporal, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "cazarrecompensas_urbano", name = "Cazarrecompensas urbano", source = "SCAG", icon = "inv_bountyhunting",
        aliases = { "cazarrecompensas", "cazador de recompensas urbano" },
        desc = "Los cazarrecompensas urbanos han aprendido a sobrevivir en un entorno en el que la información vale tanto como la fuerza. Tu experiencia previa puede haber forjado tu carácter en callejones oscuros, tabernas ruidosas o salones aristocráticos donde las máscaras importan más que las armas. Piensa en cómo tu entorno y tus contactos afectan tus reacciones: puede que sientas una afinidad instintiva hacia ciertas clases sociales, o un desprecio absoluto por ellas. Tal vez tu vínculo más fuerte esté ligado a una presa que nunca atrapaste, o a un código profesional que te impide matar sin contrato. Tus ideales pueden girar en torno a la justicia, la reputación, la supervivencia… o simplemente al oro.\n\nAntes de convertirte en aventurero, tu vida ya estaba llena de conflictos y emoción, pues te ganabas el sustento persiguiendo a personas a cambio de dinero. Pero, a diferencia de quienes recogen recompensas, no eres un salvaje que sigue a una presa cruzando la naturaleza. Estás relacionado con un comercio lucrativo en el lugar en el que resides, trabajo que a diario pone a prueba tus habilidades e instintos de supervivencia. Además, no estás solo como lo estaría un cazarrecompensas en la naturaleza. Habitualmente interactúas tanto con la subcultura criminal como con otros cazadores de recompensas y conservas contactos en ambos ambientes que te permiten triunfar.\n\nQuizá seas un cazador de ladrones astuto, que acecha en los tejados para capturar a uno de los muchísimos rateros de la ciudad. Puede que sigas alguien con los oídos abiertos en la calle, un individuo que sabe qué se traen entre manos los gremios de ladrones y las bandas callejeras.",
        traits = {
            { id = "bg_caz_comp", name = "Competencias", type = "choice", description = "Elige dos competencias entre Engaño, Perspicacia, Persuasión y Sigilo.", choice = { slots = 2, options = {
                { id = "engano", label = "Engaño", effects = { { kind = "skillProf", skill = "Engano" } } },
                { id = "perspicacia", label = "Perspicacia", effects = { { kind = "skillProf", skill = "Perspicacia" } } },
                { id = "persuasion", label = "Persuasion", effects = { { kind = "skillProf", skill = "Persuasion" } } },
                { id = "sigilo", label = "Sigilo", effects = { { kind = "skillProf", skill = "Sigilo" } } },
            } }, effects = {} },
            { id = "bg_caz_herr", name = "Competencia con herramientas", type = "choice", description = "Elige dos conjuntos de herramientas entre un juego, un instrumento musical y herramientas de ladrón.", choice = { slots = 2, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
                { id = "her_ladron", label = "Herramientas de ladron", effects = { Tool("Herramientas de ladron") } },
            } }, effects = {} },
            { id = "bg_caz_oidos", icon = "inv_misc_ear_human_01", name = "Oidos atentos", type = "pasivo", description = "Conservas contactos en la clase social o subcultura donde se mueven tus presas: crimen organizado, pueblo llano o alta sociedad.", effects = {} },
        },
    },
    {
        id = "coneja_elemental", name = "Coneja elemental", source = "Harford", icon = "inv_eng_gizmo3",
        desc = "Entre los tuneles industriales de Mecandria y el eco vibrante de sus maquinas, desarrollaste un talento único para percibir sonidos que ningún otro gnomo podía captar.",
        traits = {
            { id = "bg_coneja_escucha", icon = "inv_misc_rabbit_ears", name = "Escucha resonante conejil", type = "pasivo", description = "Obtienes ventaja en pruebas de Sabiduría (Percepción) basadas en escuchar. Tienes un comunicador interno de voz que funciona como una radio y te permite escuchar y enviar mensajes a través de el. Puedes detectar sonidos sutiles como engranajes ocultos, mecanismos tensos, relojeria, pasos lejanos, susurros amortiguados y vibraciones metalicas.", effects = {} },
            { id = "bg_coneja_acuajet", icon = "inv_weapon_rifle_33", name = "Acuajet", type = "pasivo", description = "Arma exotica que requiere sintonización por Ellie Bunny. Es un fusil integrador gnómico con varios modos de funcionamiento: funciona como foco arcano y permite lanzar magia curativa o elemental sin componentes materiales. Canon de agua (Curación): permite lanzar conjuros curativos como si tuvieras Hechizo Lejano; si el hechizo tiene alcance de toque, pasa a 30 pies, y si tiene alcance numerico, se duplica. Canon de aire (Proyectil): ataque a distancia (18/60 m), daño 1d4 + Destreza perforante, usando munición improvisada como tuercas, clavos, perdigones o tornillos. Canalizacion elemental: los conjuros elementales pueden describirse como proyectiles canalizados por el arma sin cambios mecanicos.", effects = {} },
        },
    },
    {
        id = "eco_resurreccion", name = "Eco de resurreccion", source = "Harford", icon = "d3_astralpresence",
        aliases = { "eco de resurreccion" },
        desc = "Tras morir y regresar a la vida, quedaste marcado por el umbral entre ambos mundos y percibes a los seres vivos como sombras rodeadas de mana y energías mágicas.",
        traits = {
            { id = "bg_eco_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia.", effects = {
                { kind = "skillProf", skill = "Perspicacia" },
            } },
            { id = "bg_eco_vision", icon = "wh_rendsoul", name = "Vision espectral", type = "pasivo", description = "Puedes percibir almas y energías mágicas de los seres vivos: criaturas como sombras con un núcleo brillante, rodeadas por el mana y las energías que portan. El uso prolongado fatiga tu vista y tu mente. Puedes identificar de forma aproximada el tipo de magia predominante de una criatura, rastros recientes de magia residual y corrupciones, alteraciones o energías anomalas visibles.", effects = {} },
        },
    },
    {
        id = "senda_sangre_barro", name = "Senda de Sangre y barro", source = "Harford", icon = "wh_burnawaylies",
        aliases = { "senda de sangre y barro", "sangre y barro" },
        desc = "Siempre esperas lo peor, porque la experiencia te ha demostrado que casi siempre llega. Has sobrevivido a cosas que rompieron a otros porque no supiste, o no quisiste, rendirte.",
        traits = {
            { id = "bg_senda_comp", name = "Competencias", type = "pasivo", description = "Competencia en Supervivencia y Perspicacia.", effects = {
                { kind = "skillProf", skill = "Supervivencia" }, { kind = "skillProf", skill = "Perspicacia" },
            } },
            { id = "bg_senda_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Viscerálico.", effects = { { kind = "language", language = "Visceralico" } } },
            { id = "bg_senda_lobo_tuerto", icon = "eps_wc3h_direwolfacutesenses", name = "Suerte del lobo tuerto", type = "pasivo", description = "Una vez por descanso largo, cuando realizas una tirada, puedes decidir torcer tu suerte. Hasta tu próximo descanso largo, la primera pifia (1 natural) que saques se trata como un 20 natural, y el primer 20 natural que saques se trata como una pifia (1 natural). Este efecto se aplica a tiradas de ataque, pruebas de habilidad y tiradas de salvación. Una vez que ambos efectos se hayan activado, la suerte vuelve a la normalidad hasta que la vuelvas a torcer.", effects = {} },
        },
    },
    {
        id = "veterano_campo_batalla", name = "Veterano del campo de batalla", source = "Warcraft", icon = "inv_banner_03",
        aliases = { "veterano de campo de batalla", "veterano" },
        desc = "Los veteranos de los campos de batalla son guerreros endurecidos con destrezas tácticas, un fuerte sentido de camaradería y un espíritu inquebrantable, definidos por su adaptabilidad, coraje y naturaleza competitiva en el fragor del conflicto.\n\nLos veteranos del campo de batalla son guerreros endurecidos por la guerra, con amplia experiencia en los feroces conflictos de los campos de batalla más emblemáticos de Azeroth. Estos veteranos poseen una mezcla de adaptabilidad, camaradería y espíritu competitivo que se ha forjado a lo largo de incontables enfrentamientos.\n\nViven la emoción de la victoria, encarnan el honor del campo de batalla y llevan las cicatrices de sus triunfos y derrotas pasadas. Los veteranos inspiran a otros, forjan lazos inquebrantables y persiguen la gloria con determinación, mientras enfrentan sus propios demonios internos nacidos del caos de la guerra.",
        traits = {
            { id = "bg_vet_endurecido", icon = "ability_pvp_hardiness", name = "Endurecido por la guerra", type = "pasivo", description = "Tu experiencia en campos de batalla te permite reconocer tacticas, amenazas y cadenas de mando con rapidez. El DM decide cuando esa experiencia aporta ventaja narrativa.", effects = {} },
            { id = "bg_vet_comp", name = "Competencias", type = "pasivo", description = "Las competencias concretas se leen de la ficha TRP3 cuando aparecen marcadas como Trasfondo.", effects = {} },
        },
    },
    {
        -- Trasfondo propio: su unica fuente es la ficha TRP3 del jugador. De ahi salen la
        -- descripcion y el rasgo; las competencias, herramientas y equipo no estan
        -- declaradas en ninguna parte y por eso no se inventan aqui.
        id = "gladiador_goriano", name = "Gladiador goriano", source = "Harford", icon = "achievement_dungeon_ogreslagmines",
        aliases = { "gladiador goriano", "gladiador de gorgrond", "gladiador" },
        desc = "Fuiste forjado en las arenas del Imperio Goriano, donde los débiles desaparecían bajo la arena y los fuertes vivían un combate más. Entre cadenas, gritos y acero, aprendiste a convertir el miedo en furia y el dolor en disciplina. Los ogros creyeron haberte domesticado; solo lograron enseñarte a sobrevivir. Ahora luchas por tu propia voluntad, y ningún amo volverá a decidir tu destino.",
        traits = {
            { id = "bg_glad_comp", name = "Competencias", type = "pasivo", description = "Competencia en Acrobacias y Intimidación.", effects = {
                { kind = "skillProf", skill = "Acrobacias" }, { kind = "skillProf", skill = "Intimidacion" },
            } },
            { id = "bg_glad_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Ogro.", effects = { { kind = "language", language = "Ogro" } } },
            { id = "bg_glad_voluntad", icon = "eps_lol_sylas_chainlash", name = "Voluntad del yugo", type = "pasivo", description = "Cuando recibes daño que te reduciría a 0 puntos de golpe, puedes quedarte a 1 punto de golpe en su lugar. No puedes usar este rasgo si el daño proviene de un golpe crítico. Una vez usas este rasgo, no puedes volver a usarlo hasta finalizar un descanso largo.", effects = {} },
        },
    },
}

local bgById, bgOrder

local function Normalize(value)
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))  -- parentesis: gsub devuelve 2 valores
end

local function EnsureIndex()
    if bgById then return end
    bgById, bgOrder = {}, {}
    for _, bgDef in ipairs(API.BACKGROUNDS) do
        bgById[bgDef.id] = bgDef
        bgOrder[#bgOrder + 1] = bgDef.id
    end
end

function API.GetBackgrounds()
    EnsureIndex()
    return API.BACKGROUNDS
end

function API.GetBackground(backgroundId)
    EnsureIndex()
    return bgById[tostring(backgroundId or "")]
end

function API.GetBackgroundOrder()
    EnsureIndex()
    return bgOrder
end

function API.GetBackgroundName(backgroundId)
    local bgDef = API.GetBackground(backgroundId)
    return bgDef and bgDef.name or tostring(backgroundId or "")
end

-- La bolsa inicial pertenece al trasfondo. Mientras los datos heredados conservan el
-- texto de equipo como fuente, este helper solo reconoce la formulacion canónica de
-- "bolsa/monedero ... N po"; no intenta interpretar el resto del inventario.
function API.GetStartingGold(backgroundId)
    local bgDef = API.GetBackground(backgroundId)
    if not bgDef then return 0 end
    if tonumber(bgDef.startingGold) then return math.max(0, math.floor(tonumber(bgDef.startingGold))) end
    for _, trait in ipairs(bgDef.traits or {}) do
        if tostring(trait.id or ""):match("_equipo$") then
            local text = tostring(trait.description or "")
            local amount = text:match("[Bb]olsa[^%d]*(%d+)%s*[Pp][Oo]")
                or text:match("[Mm]onedero[^%d]*(%d+)%s*[Pp][Oo]")
            if amount then return math.max(0, math.floor(tonumber(amount) or 0)) end
        end
    end
    return 0
end

function API.FindBackgroundIdByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil end
    EnsureIndex()
    local bestId, bestLen
    for _, bgDef in ipairs(API.BACKGROUNDS) do
        local candidates = { bgDef.id, bgDef.name }
        for _, alias in ipairs(bgDef.aliases or {}) do
            candidates[#candidates + 1] = alias
        end
        for _, candidate in ipairs(candidates) do
            local normalized = Normalize(candidate)
            if normalized ~= "" and clean:find(normalized, 1, true) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = bgDef.id, len
                end
            end
        end
    end
    return bestId
end

-- Devuelve los rasgos del trasfondo en el MISMO formato que
-- HarfordDnDBook.GetUnlockedFeatures: { { className, level=0, feature }, ... }.
-- Los rasgos sin icono propio heredan el de su trasfondo. De los 190 rasgos, la web solo declara
-- icono para 51; el resto caia al generico `inv_misc_note_01` y todos los trasfondos se veian
-- iguales en el Libro. Se rellena aqui, una vez al cargar, para no repetir la regla en cada
-- consumidor (Libro, lista de Rasgos y About).
do
    for _, bgDef in ipairs(API.BACKGROUNDS or {}) do
        local icono = bgDef.icon
        if icono and icono ~= "" then
            for _, trait in ipairs(bgDef.traits or {}) do
                if not trait.icon or trait.icon == "" then trait.icon = icono end
            end
        end
    end
end

function API.GetBackgroundTraits(backgroundId)
    local out = {}
    local bgDef = API.GetBackground(backgroundId)
    if not bgDef then return out end
    for _, trait in ipairs(bgDef.traits or {}) do
        out[#out + 1] = { className = bgDef.name, level = 0, feature = trait }
    end
    return out
end

function API.GetTrait(traitId)
    traitId = tostring(traitId or "")
    for _, bgDef in ipairs(API.BACKGROUNDS) do
        for _, trait in ipairs(bgDef.traits or {}) do
            if trait.id == traitId then return trait, bgDef end
        end
    end
    return nil
end
