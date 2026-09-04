-- HarfordDnDBackgrounds: libro hardcodeado de trasfondos (World of Warcraft D&D 5ª Ed. ES).
-- Solo datos + helpers puros. Los rasgos de trasfondo son "features" con el mismo
-- formato que los de clase/raza (id/name/type/description/effects/choice), para reusar
-- el motor de efectos (HarfordDnDFeatureEffects) y la UI de la pestaña Clases.
--
-- Competencias en habilidades -> effects { kind="skillProf", skill=... }.
-- Herramientas, idiomas, caracteristica y equipo van como `informativo` con su texto.
-- Las opciones de herramienta llevan prefijo `her_` de HERRAMIENTA (her_ladron,
-- her_instrumento, her_disfraz...). El mismo prefijo lo usan en HarfordProfesiones.lua
-- las 244 recetas de HERRERIA; son espacios de nombres distintos, sin ids repetidos y
-- sin ninguna busqueda comun, asi que la coincidencia es solo de nombre.
-- NO renombrarlos: la eleccion de un personaje se guarda por id de opcion y ya hay
-- compatibilidad para ids viejos en HarfordDnDBook (her_instrumento/her_juego).
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
        id = "boticario_oscuro", name = "Boticario Oscuro", nameF = "Boticaria Oscura", source = "Warcraft", icon = "ui_darkshore_warfront_horde_alchemist",
        desc = "Has formado parte de la Sociedad Real de Boticarios (conocida como la Sociedad de Boticarios o abreviada como S.R.B.), una organización alquímica con sede en el Apothecarium de Entrañas. Fue fundada por Lady Sylvanas Brisaveloz para crear una nueva plaga no-muerta destinada a erradicar a la Plaga. Sus miembros son Renegados u otros tipos de no-muertos que sirven a la causa de Sylvanas. Trabajan constantemente en nuevas plagas y venenos para desatar sobre los enemigos de Sylvanas.\n\nOtras razas de la Horda también colaboran, algunas en busca de una cura para su \"condición\". Los miembros de esta sociedad suelen llamarse boticarios o boticarios oscuros.",
        traits = {
            { id = "bg_bot_competencias", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Investigación.", effects = {
                { kind = "skillProf", skill = "Arcano" },
                { kind = "skillProf", skill = "Investigacion" },
            } },
            { id = "bg_bot_herramientas", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Suministros de alquimista y equipo de venenos.", effects = {} },
            { id = "bg_bot_caract", icon = "w3reforgedundeadtransport", name = "Agente de la S.R.B.", type = "pasivo", description = "Como miembro de la Sociedad Real de Boticarios, tienes acceso a una red de contactos y operativos que trabajan con el apoyo oficial de Lady Sylvanas Brisaveloz. Dondequiera que encuentres a los Renegados, puedes hallar a los Boticarios Oscuros, quienes pueden ayudarte con refugios seguros, búsqueda de información, hierbas o ingredientes alquímicos. Sin embargo, esta red funciona en ambos sentidos, y puede que ellos también esperen algo de ti a cambio.", effects = {} },
            { id = "bg_bot_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Suministros de alquimista o equipo de venenos, un brazalete con frasco y corona bordados, un cuaderno, un conjunto de tunicas de terciopelo negro y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "doble_agente", name = "Doble Agente", source = "Warcraft",
        aliases = { "agente doble" },
        desc = "Eres un informante de una facción u organización opuesta, y les proporcionas en secreto información falsa en nombre de otra organización a la que verdaderamente sirves. Puede que seas un informante de la Cruzada Escarlata, proporcionando datos falsos a nombre de los Renegados. O quizá seas miembro del Cártel Bonvapor, engañando a los comerciantes goblin con información falsa para asegurar el mayor beneficio posible para el cártel sin exponerte.\n\nHabla con tu DM para determinar qué facciones u organizaciones están implicadas, tanto la que sirves como la que engañas.",
        traits = {
            { id = "bg_dob_competencias", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Perspicacia.", effects = {
                { kind = "skillProf", skill = "Engano" },
                { kind = "skillProf", skill = "Perspicacia" },
            } },
            { id = "bg_dob_herramientas", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Kit de falsificación.", effects = {} },
            { id = "bg_dob_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Uno de tu elección perteneciente a la facción opuesta.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_dob_caract", icon = "inv_misc_coin_19", name = "Dos caras de una moneda", type = "pasivo", description = "Tienes contactos dentro de ambas organizaciones a las que proporcionas información, ya sea veraz o falsa. Las organizaciones oficiales a menudo te permitirán cometer delitos menores sin consecuencias legales, o dirigir un negocio sin pagar tasas ni impuestos. Además, puedes solicitar audiencias con funcionarios de ambas organizaciones.", effects = {} },
            { id = "bg_dob_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Kit de falsificación, daga, dos piezas de tiza, 4 hojas de pergamino, una botella de tinta, una pluma, un conjunto de ropa de viajero y una bolsa de cinturon con 15 po.", effects = {} },
        },
    },
    {
        id = "crianza_faccion", name = "Crianza en la Faccion", source = "Warcraft",
        aliases = { "criado por la faccion", "criado_por_la_facci_n", "crianza de la faccion" },
        desc = "Fuiste abandonado al nacer y hallado por miembros de una facción contraria, que te acogieron y criaron como uno de los suyos. Tu infancia estuvo marcada por el rechazo de otros miembros de la facción, que rara vez te aceptaron y apenas toleraron tu presencia.\n\nQuizás fuiste un tauren nacido en los reinos del este, abandonado por tus padres y encontrado por granjeros humanos que te criaron como a uno más. O tal vez fuiste un humano de Theramore que escapó de casa y fue acogido por orcos en Orgrimmar, donde aprendiste a luchar y a hablar su lengua.\n\nHabla con tu DM para definir los detalles de la facción y la raza que te crió, ya que no todas las razas de Azeroth mantienen relaciones igualitarias entre sí.",
        traits = {
            { id = "bg_cri_competencias", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Percepción.", effects = {
                { kind = "skillProf", skill = "Historia" },
                { kind = "skillProf", skill = "Percepcion" },
            } },
            { id = "bg_cri_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Puedes hablar Darnassiano, Draenei, Enano o Gnómico.", effects = {}, choice = { slots = 1, options = { { id = "idioma_darnassiano", label = "Darnassiano", effects = { { kind = "language", language = "Darnassiano" } } }, { id = "idioma_draenei", label = "Draenei", effects = { { kind = "language", language = "Draenei" } } }, { id = "idioma_enano", label = "Enano", effects = { { kind = "language", language = "Enano" } } }, { id = "idioma_gnomico", label = "Gnomico", effects = { { kind = "language", language = "Gnomico" } } } } } },
            { id = "bg_cri_caract", icon = "hots_falseheart", name = "Lealtad falsa", type = "pasivo", description = "Tu raza y apariencia te permiten moverte sin ser molestado por aldeas y ciudades de ambas facciones. A veces te miran con recelo, pero pocos te detienen o interrogan, y rara vez te acusan de nada. Las autoridades pueden dudar de ti, pero tu manifiesto valida tu lealtad y suele bastar para evitar represalias.", effects = {} },
            { id = "bg_cri_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Un conjunto de ropa comun, capa con capucha, un amuleto de tu facción, un libro, una botella de tinta, una pluma y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "aprendiz_kirin_tor", name = "Aprendiz del Kirin Tor", source = "Warcraft",
        desc = "Has aprendido las bases de las escuelas de magia, así como las líneas ley que recorren la superficie de Azeroth. Pasaste incontables horas en las bibliotecas del Kirin Tor, explorando el conocimiento que más te interesaba, y fuiste enviado fuera de Dalaran para buscar sabiduría en otros lugares y adquirir experiencia.",
        traits = {
            { id = "bg_kir_competencias", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia.", effects = {
                { kind = "skillProf", skill = "Arcano" },
                { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_kir_herramientas", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de herramientas de artesano.", effects = {} },
            { id = "bg_kir_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_kir_caract", icon = "hd_letter_kirintor", name = "Mentor prominente", type = "pasivo", description = "Conoces al menos a un mago influyente dentro del Kirin Tor al que puedes recurrir para hacer preguntas o recibir información. Puedes lanzar el conjuro mensaje una vez por descanso largo, sin límite de distancia, pero sólo puede tener como objetivo a tu mentor. Este no está obligado a responder ni lo hará inmediatamente, ya que sus estudios y obligaciones requieren mucho de su tiempo.", effects = {} },
            { id = "bg_kir_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Una botella de tinta de alta calidad, una pluma, tiza, un estuche para pergaminos con 5 hojas, tunicas, una vela, caja de yesca y una bolsa con 15 po.", effects = {} },
        },
    },
    -- ===== Trasfondos del Manual del Jugador (PHB 5e ES) =====
    {
        id = "acolito", name = "Acolito", nameF = "Acolita", source = "PHB", icon = "spell_holy_impholyconcentration",
        aliases = { "ac_lito" },
        desc = "Has dedicado tu vida al servicio de un templo consagrado a un dios o panteón de dioses. Sirves de intermediario entre el reino de lo sagrado y el mundo mortal, realizando rituales religiosos y ofreciendo sacrificios para que los fieles puedan ser partícipes de la presencia divina. No tienes por qué ser un clérigo; llevar a cabo ritos sagrados no es lo mismo que canalizar el poder divino. Escoge un dios, un panteón de deidades o cualquier otro ente cuasidivino de entre los enumerados en el apéndice B o los especificados por tu DM, y habla con este último para definir claramente la naturaleza de tu servicio a la religión. ¿Eras un funcionario menor en el templo, criado desde pequeño para asistir a los sacerdotes en los rituales sacros? ¿O eras un sumo sacerdote que fue llamado por su dios a servirle de otra forma? Quizá fueras el líder de una pequeña secta al margen de cualquier religión establecida o, incluso, de un grupo de adoradores de lo oculto que servían a un amo infernal del que ahora reniegas.",
        traits = {
            { id = "bg_aco_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Religión.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Religion" },
            } },
            { id = "bg_aco_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "choice", description = "Dos idiomas de tu elección.", effects = {}, choice = { slots = 2, optionsFrom = "language" } },
            { id = "bg_aco_caract", icon = "achievement_dungeon_ataldazar", name = "Refugio del fiel", type = "pasivo", description = "Como acólito de tu dios, puedes llevar a cabo sus ceremonias y mereces el respeto de aquellos que comparten tu fe. Puedes esperar que tanto tus compañeros de aventuras como tú recibáis sanación y cuidados sin coste alguno en templos, santuarios u otros lugares consagrados a tu fe, aunque debes aportar los componentes materiales necesarios para los conjuros que se lancen. Los que compartan tu religión te mantendrán (pero solo a ti) con un nivel de vida modesto.\n\nTambién podrías poseer lazos con un templo en particular de los dedicados a tu deidad o panteón. Si es el caso, allí podrías residir. Este podría ser el templo en que solías servir o el que aún mantiene una relación amigable con sus acólitos, y en el que encuentres un nuevo hogar. Cuando estés cerca de este templo podrás pedir ayuda a sus sacerdotes, siempre y cuando el favor que solicites no sea peligroso y tu necesidad bien considerada por ellos.\n\nCaracterísticas recomendadas\n\nLos acólitos han sido modelados por sus experiencias en templos y comunidades religiosas. Piensa en cómo tus vínculos podrían afectar a tus acciones, como su relación con templos, santuarios y jerarquías, afectan sus costumbres sociales. Tus vínculos podrían ser una influencia benévola o una herida abierta. Quizá incluso un ideal o vínculo llevado al extremo.", effects = {} },
            { id = "bg_aco_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Símbolo sagrado (un regalo de cuando fuiste ordenado sacerdote), devocionario o rueda de oraciones, 5 varas de incienso, vestiduras, muda de ropas comunes y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "animador", name = "Animador", nameF = "Animadora", variants = { { id = "animador_gladiador", icon = "achievement_featsofstrength_gladiator_03", name = "Gladiador", desc = "Los gladiadores son tan merecedores del título de animador como un juglar o un artista circense, solo que recurren a las artes del combate para dar al público un espectáculo del que disfrutar. Esta clase de florituras marciales son un tipo de actuación, aunque también podrías ganarte la vida como saltimbanqui o actor.  Podrás usar el rasgo Por petición popular para encontrar dónde actuar en cualquier entorno en el que se conciba el combate como un entretenimiento. Una arena de gladiadores o un club de la lucha son dos buenos ejemplos.  Puedes sustituir el instrumento musical de tu equipo inicial por un arma inusual (aunque asequible), como puede ser un tridente o una red." } }, source = "PHB", icon = "achievement_halloween_smiley_01",
        desc = "Tu sitio favorito es frente al público. Sabes cómo encandilarlo, entretenerlo e incluso inspirarlo. Tus poemas animan el corazón de quienes te escuchan, despertando en ellos la pena, la alegría, la risa o la furia. Tu música levanta sus á nimos o apresa su melancolía. Tus pasos de baile les cautivan y tus burlas les hieren en el alma. Sean cuales sean las técnicas que emplees, tu arte es tu vida.",
        traits = {
            { id = "bg_ani_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Acrobacias e Interpretación.", effects = {
                { kind = "skillProf", skill = "Acrobacias" }, { kind = "skillProf", skill = "Interpretacion" },
            } },
            { id = "bg_ani_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Útiles para disfrazarse y un tipo de instrumento musical.", effects = {} },
            { id = "bg_ani_caract", icon = "eps_bg3_songofrest", name = "Por peticion popular", type = "pasivo", description = "Siempre encuentras un sitio donde actuar (posada, taberna, circo, teatro, corte) y consigues comida y alojamiento modesto o comodo si actúas cada noche. La gente te reconoce allí donde has actuado.", effects = {} },
            { id = "bg_ani_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Instrumento musical (a tu elección), el favor de un admirador (carta de amor, bucle de cabello o bagatela), disfraz y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "artesano_gremial", name = "Artesano gremial", nameF = "Artesana gremial", variants = { { id = "artesano_gremial_comerciante_gremial", icon = "eps_arc_sign_oribos_trade", name = "Comerciante gremial", desc = "En lugar de pertenecer a un gremio de artesanos, formas parte de un gremio de comerciantes, caravaneros o tenderos. No produces objetos tú mismo, sino que para ganarte la vida compras y vendes el trabajo de los demás (o las materias primas que los artesanos necesitan para hacer su trabajo). Tu gremio podría tratarse de un gran consorcio (o familia) de mercaderes con intereses a lo largo y ancho de la región. Quizás transportabas bienes de un sitio a otro, ya fuera en barco, carro o caravana. O puede que se los compraras a mercaderes itinerantes y los vendieras en tu pequeña tienda. En cierta forma, la vida de un comerciante en tránsito se parece mucho más a la aventura que la de un artesano.  En lugar de ser competente con herramientas de artesano, podrías serlo con herramientas de navegación o en un idioma adicional. Si decides renunciar a las herramientas de artesano, podrías poseer una mula y un carro mercante." } }, source = "PHB", icon = "eps_arc_sign_oribos_trade",
        desc = "Eres un miembro de un gremio, hábil en una disciplina concreta y con lazos estrechos con otros artesanos. Tu papel supone una parte fundamental de la cadena comercial, libre de las restricciones de una sociedad fe uda l gracias a tu talento y riqueza. Adquiriste tus habilidades bajo la tutela de un maestro artesano y, gracias al patrocinio de tu gremio, tú mismo te convertirse en maestro por derecho propio.",
        traits = {
            { id = "bg_art_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Persuasión.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_art_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de herramientas de artesano.", effects = {} },
            { id = "bg_art_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_art_caract", icon = "achievement_guildperk_workingovertime", name = "Miembro de un gremio", type = "pasivo", description = "Como miembro consolidado y respetado de un gremio, puedes confiar en que este te prestará su apoyo. Tus compañeros te proporcionarán comida y alojamiento si lo necesitas. Hasta pagarían tu funeral si hiciera falta. En algunas ciudades la casa gremial será un lugar céntrico en el que conocer a otros compañeros de profesión; un lugar ideal para conocer potenciales patrones, aliados o asalariados.", effects = {} },
            { id = "bg_art_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Herramientas de artesano (un tipo a tu elección), carta de presentación de tu gremio, muda de ropas de viaje y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "charlatan", name = "Charlatan", nameF = "Charlatana", source = "PHB",
        aliases = { "charlat_n" },
        desc = "Eres consciente de lo que la gente desea y tú se los das. O, mejor dicho, prometes dárselo. Deberían desconfiar de aquello que parece demasiado bueno para ser verdad, pero el sentido común es el menos común de los sentidos; un hecho que parece acentuarse con tu presencia: seguro que esa botella de líquido rosáceo puede curar ese sarpullido indecoroso; resulta que este ungüento (que en realidad no es más que grasa y una pizca de polvo de plata) proporciona juventud y vigor; casualmente uno de los pendientes de la ciudad está en venta. Todas estas maravillas aparentan ser poco plausibles, pero cuando salen de tus labios suenan auténticas.",
        traits = {
            { id = "bg_cha_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Juego de Manos.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "JuegoManos" },
            } },
            { id = "bg_cha_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Útiles para disfrazarse y útiles para falsificar.", effects = {} },
            { id = "bg_cha_caract", icon = "inv_misc_notepicture2c", name = "Identidad falsa", type = "pasivo", description = "Te has creado una segunda identidad, para la cual posees documentación, disfraces y un grupo de conocidos que pueden responder por ella. Todo lo necesario para asumirla. Además, eres capaz de falsificar cualquier documento (incluyendo cartas personales y documentación oficial) cuyo formato o caligrafía hayas visto antes.", effects = {} },
            { id = "bg_cha_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Muda de ropas de calidad, útiles para disfrazarse, herramientas para un timo de tu elección (diez botellas con tapones de corcho llenas de un líquido coloreado, un juego de dados trucados, una baraja de naipes marcada, un anillo de sellar de un duque imaginario) y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "criminal", name = "Criminal", variants = { { id = "criminal_espia", name = "Espía", desc = "Aunque tus facultades no son muy distintas de las de un ladrón o un contrabandista, las has adquirido y puesto en práctica en un contexto muy distinto: como espía. Quizá seas un agente oficial, autorizado por la corona, o puede que vendieras los secretos que descubriste al mejor postor.", icon = "inv_misc_spyglass_01" } }, source = "PHB",
        desc = "Eres un criminal experto, con una abultada experiencia al margen de la ley. Has pasado mucho tiempo entre delincuentes y todavía conservas numerosos contactos en el mundillo criminal. Estás mucho más familiarizado que la mayoría con el asesinato, el hurto y la violencia que impregnan las entrañas de la civilización. Has logrado sobrevivir todo este tiempo gracias a tu desdén por las reglas y normativas de la sociedad.",
        traits = {
            { id = "bg_cri_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Sigilo.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_cri_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de juego a tu elección, herramientas de ladrón.", effects = {} },
            { id = "bg_crim_caract", icon = "ability_rogue_deadliness", name = "Contacto criminal", type = "pasivo", description = "Tienes un contacto de confianza que enlaza con una red de criminales. Sabes enviar y recibir mensajes a través de mensajeros, caravaneros corruptos y marineros incluso a distancia.", effects = {} },
            { id = "bg_crim_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Palanqueta, muda de ropas corrientes de color oscuro y con capucha, una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "ermitano", name = "Ermitaño", nameF = "Ermitaña", source = "PHB",
        aliases = { "ermita_o" },
        desc = "Has pasado gran parte de tus años de aprendizaje aislado, ya fuera como parte de una comunidad resguardada del exterior, como un monasterio, o completamente solo. Apartado del clamor de la sociedad has encontrado quietud, soledad y puede que, incluso, algunas de las respuestas que estabas buscando.",
        traits = {
            { id = "bg_erm_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Medicina y Religión.", effects = {
                { kind = "skillProf", skill = "Medicina" }, { kind = "skillProf", skill = "Religion" },
            } },
            { id = "bg_erm_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Útiles de herborista.", effects = {} },
            { id = "bg_erm_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_erm_caract", icon = "achievement_bg_winsoa", name = "Descubrimiento", type = "pasivo", description = "El pacífico aislamiento de tu prolongado retiro te ha hecho partícipe de un descubrimiento único y poderoso. Su naturaleza exacta dependerá del tipo de ermitaño que fueras. Podría tratarse de una gran revelación sobre el cosmos, los dioses, seres poderosos de los Planos Exteriores o las fuerzas de la naturaleza. Tal vez de un lugar que nadie más ha visto. Incluso podrías haber descubierto un hecho que llevaba mucho tiempo olvidado o desenterrado una reliquia del pasado capaz de reescribir la historia. Quizá sea información que podría poner en peligro a los que te exiliaron, y precisamente esta sea la razón de tu retorno a la sociedad.", effects = {} },
            { id = "bg_erm_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Estuche para pergaminos lleno de notas de tus estudios u oraciones, manta para el invierno, muda de ropas comunes, útiles de herborista y 5 po.", effects = {} },
        },
    },
    {
        id = "erudito", name = "Erudito", nameF = "Erudita", source = "PHB", icon = "wh_focusedmind",
        desc = "Has pasado años aprendiendo sobre el universo. Has leído detenidamente manuscritos, estudiado pergaminos y escuchado a los mayores expertos de los temas que te interesan. Tus esfuerzos te han convertido en un maestro de tu campo.",
        traits = {
            { id = "bg_eru_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia.", effects = {
                { kind = "skillProf", skill = "Arcano" }, { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_eru_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "choice", description = "Dos idiomas de tu elección.", effects = {}, choice = { slots = 2, optionsFrom = "language" } },
            { id = "bg_eru_caract", icon = "w3reforgedarcanescroll", name = "Investigador", type = "pasivo", description = "Cuando intentas aprender o recordar algo, aunque no tengas la información, sueles saber donde encontrarla o quien puede proporcionartela (biblioteca, universidad, otros eruditos).", effects = {} },
            { id = "bg_eru_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Botella de tinta negra, pluma, cuchillo pequeño, carta de un colega muerto con una pregunta sin responder, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "heroe_pueblo", name = "Heroe del pueblo", nameF = "Heroina del pueblo", source = "PHB",
        aliases = { "h_roe del pueblo", "h_roe_del_pueblo" },
        desc = "Provienes de un estrato social bajo, pero estás destinado a llegar muy lejos. Los habitantes de tu pueblo natal ya te consideran su campeón y los hados te llaman a enfrentarte a los tiranos y monstruos que amenazan a la gente sencilla.",
        traits = {
            { id = "bg_her_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Supervivencia y Trato con Animales.", effects = {
                { kind = "skillProf", skill = "Supervivencia" }, { kind = "skillProf", skill = "Animales" },
            } },
            { id = "bg_her_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de herramientas de artesano y vehículos terrestres.", effects = {} },
            { id = "bg_her_caract", icon = "w3reforgedfarm", name = "Hospitalidad rural", type = "pasivo", description = "Por tu origen humilde te relacionas con facilidad con el pueblo llano, que te ofrece un lugar donde esconderte, descansar o recuperarte, y te oculta de quien te persiga (sin arriesgar sus vidas).", effects = {} },
            { id = "bg_her_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Herramientas de artesano (un tipo a tu elección), pala, olla de hierro, muda de ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "huerfano", name = "Huerfano", nameF = "Huerfana", source = "PHB", icon = "eps_lol_profileicon_ezbereal",
        aliases = { "hu_rfano" },
        desc = "Creciste solo y en la calle, huérfano y pobre. No había nadie que te cuidara o mantuviera, así que aprendiste a sobrevivir por ti mismo. Luchaste ferozmente por conseguir comida y nunca quitabas la vista del resto de pobres almas, que querían robarte. Dormías en tejados y callejones, a la intemperie, y te sobrepusiste a enfermedades sin la ayuda de la medicina o un lugar en el que recuperarte. Contra todo pronóstico, sobreviviste, y lo hiciste gracias a tu astucia, fuerza, velocidad o una combinación de ellas. Empezaste tu vida como aventurero con el dinero suficiente como para vivir de forma modesta pero segura durante al menos diez días. ¿Cómo conseguiste ese dinero? ¿Qué te permitió libera rte de tus circunstancias desesperadas y embarcarte en una vida mejor?",
        traits = {
            { id = "bg_hue_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Juego de Manos y Sigilo.", effects = {
                { kind = "skillProf", skill = "JuegoManos" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_hue_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Herramientas de ladrón y útiles para disfrazarse.", effects = {} },
            { id = "bg_hue_caract", icon = "eps_lol_profileicon_theblackroseremembers", name = "Secretos de la ciudad", type = "pasivo", description = "Conoces el flujo y los patrones secretos que rigen el movimiento de toda ciudad, y puedes encontrar pasadizos en medio de una urbe que otros pasarían por alto. Cuando no estás combatiendo, tú y aquellos compañeros a los que guíes podéis viajar entre dos localizaciones cualesquiera dentro de una ciudad el doble de rápido de lo que vuestra velocidad os lo permitiría.", effects = {} },
            { id = "bg_hue_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Cuchillo pequeño, mapa de la ciudad en la que creciste, ratón (tu mascota), recuerdo de tus padres, muda de ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "marinero", name = "Marinero", nameF = "Marinera", variants = { { id = "marinero_pirata", name = "Pirata", desc = "Has pasado tu juventud bajo la influencia de un temible pirata; un asesino despiadado que te enseñó a sobrevivir en un mundo de tiburones y salvajes. Te has dado el gusto de hurtar a otros barcos y has enviado a más de un alma a una tumba salada. El miedo y el derramamiento de sangre no te son extraños, pues te has forjado una despreciable reputación en multitud de puertos.  Si decides que tu carrera como marinero ha incluido la piratería, puedes elegir el rasgo Mala Reputación en lugar de Pasaje en un Barco.", icon = "inv_helm_cloth_b_01pirate_classic" } }, source = "PHB",
        desc = "Has sido marinero en un barco durante años. A lo largo de este periodo te has enfrentado a tormentas portentosas, monstruos de las profundidades y aquellos que querían hundir tu navío en las profundidades sin fondo. Tu primer amor fueron los vastos horizontes, pero ha llegado la hora de probar algo nuevo.\n\nHabla con tu DM para determinar el tipo de barco en el que navegabas. Pudo tratarse de un navío mercante, un buque de guerra, un velero en busca de descubrimiento o un barco pirata. ¿Era una nave famosa (o infame)?, ¿ha visto mucho mundo?, ¿sigue en activo o se ha perdido junto con su tripulación?\n\nPiensa en cuál era tu labor a bordo: contramaestre, capitán, navegante, cocinero o cualquier otro cargo. ¿Quiénes eran el capitán y el primer oficial? ¿Abandonaste el barco de manera amistosa o huyendo de tus compañeros?",
        traits = {
            { id = "bg_mar_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Percepción.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Percepcion" },
            } },
            { id = "bg_mar_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Herramientas de navegante y vehículos acuaticos.", effects = {} },
            { id = "bg_mar_caract", icon = "w3reforgedship", name = "Pasaje en un barco", type = "pasivo", description = "Si lo necesitas, puedes conseguir, sin coste alguno, un pasaje en un velero para tus compañeros y para ti. Podría tratarse del barco en el que serviste u otro con el que tengas buenas relaciones, quizá coma ndado por un antiguo miembro de tu tripulación. Como estás pidiendo que te hagan un favor, no puedes asegurarte de que la planificación o la ruta se ajustan exactamente a lo que necesitas. Tu Dungeon Master decidirá el tiempo que precisáis para llegar a donde queríais ir. A cambio del pasaje, se espera que tanto tú como tus compañeros ayudéis a la tripulación durante el viaje.", effects = {} },
            { id = "bg_mar_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Cabilla (garrote), 15 metros de cuerda de seda, amuleto de la suerte como una pata de conejo o una piedra pequeña con un agujero en el centro, muda de ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "noble", name = "Noble", variants = { { id = "noble_caballero_nobiliario", name = "Caballero nobiliario", desc = "En la mayoría de sociedades, caballero es el más bajo de los títulos nobiliarios. Si quieres ser un caballero, escoge el rasgo Siervos (mira el cuadro de texto) en lugar de Posición de Privilegio. Además, uno de tus siervos es reemplazado por un noble que te acompaña como escudero. Te asiste a cambio de que le ayudes a convertirse en un caballero de pleno derecho. Tus dos siervos restantes podrían ser un palafrenero que se ocupa de tu caballo y un criado que pule tu armadura (y puede que incluso te ayude a ponértela). Como emblema de hidalguía y los ideales del amor cortés, podrías poseer un estandarte o un presente de un señor o señora noble al que has entregado tu corazón. De forma platónica, claro está. Esta persona podría ser tu vínculo. RASGO ALTERNATIVO: SIERVOS Si tu personaje posee el trasfondo \"noble\", puedes elegir este rasgo de trasfondo en lugar de Posición de Privilegio. Tres criados leales a tu familia están a tu servicio. Estos siervos pueden ser asistentes o mensajeros, y uno de ellos podría incluso ser un mayordomo. Los criados son plebeyos que pueden llevar a cabo las tareas mundanas que les pidas, pero no lucharán por ti, no te seguirán a zonas claramente peligrosas (como mazmorras) y te abandonarán si conviertes en una costumbre abusar de ellos o ponerles en peligro.", icon = "wc3_knight" } }, source = "PHB", icon = "w3reforgedgoldring",
        desc = "Entiendes las riquezas, el poder y los privilegios. Posees un título nobiliario y tu familia es dueña ele tierras. recauda impuestos y ostenta una influencia política no clesde1iable. Podrías ser un aristócrata consentido, que nunca ha trabajado o sufrido incomocliclacl alguna, un antiguo mercader que acaba de entrar a formar parte de la nobleza o un canalla desheredado que se cree que tiene derecho a todo. O quizá seas un terrateniente honesto y diligente, que se preocupa sinceramente por los que viven y trabajan en sus tierras y es consciente de su responsabilidad para con ellos. Habla con tu DM para acordar un título apropiado y determinar cuánta autoridad ostentas. Pero un título nobiliario no existe de forma independiente, sino que está conectado a una familia. Ten en cuenta que pasará a tus hijos en el futuro. Así que no solo tenéis que decidir cuál es tu título exacto. sino que también tendréis que describir tu familia y la influencia que esta posee sobre ti. ¿Perteneces a una estirpe antigua y establecida, o se os ha otorgado el título hace poco? ¿Qué influencia tenéis, y sobre qué región? ¿Qué reputación posee tu familia entre el resto de aristócratas de la zona? ¿Cómo os ve el pueblo llano? ¿Cuál es tu posición en la familia? Puede que seas el futuro sucesor del cabeza de familia o incluso que ya hayas heredado este título. ¿Cómo te afecta esta responsabilidad? También es posible que estés tan abajo en la línea de sucesión que no le importes a nadie, siempre y cuando no avergüences tu apellido. ¿Qué opina el cabeza de familia de tus correrías como aventurero? Es más, ¿eres apreciado por tus parientes o prefieren evitarte? ¿Tenéis un blasón? ¿Y una insignia que figure en tu anillo de sellar? ¿Hay algún color o colores que vistáis siempre? ¿Existe algún animal que sea símbolo de tu linaje? Quizá incluso se trate de un miembro espiritual de tu familia. Este tipo de detalles sirven para establecer tu estirpe y tu título dentro del mundo de vuestra campaña.",
        traits = {
            { id = "bg_nob_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Persuasión.", effects = {
                { kind = "skillProf", skill = "Historia" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_nob_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de juego a tu elección.", effects = {} },
            { id = "bg_nob_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_nob_caract", icon = "eps_wc3h_evilhumanqueen", name = "Posicion de privilegio", type = "pasivo", description = "Debido a tu noble alcurnia, la gente se siente inclinada a pensar lo mejor de ti. Eres bienvenido en la alta sociedad y todos asumen que tienes derecho a estar donde quiera que estés. El pueblo llano hará lo posible para alojarte y evitar tu desaprobación, mientras que personas de clase alta te tratarán como a otro miembro de su ámbito social. Si lo necesitas, podrás conseguir audiencia con un noble local.", effects = {} },
            { id = "bg_nob_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Muda de ropas de calidad, anillo de sellar, documento que acredita el linaje y un monedero con 25 po.", effects = {} },
        },
    },
    {
        id = "salvaje", name = "Salvaje", source = "PHB",
        desc = "Creciste en la naturaleza, apartado de la civilización y las comodidades que la ciudad y la tecnología proporcionan. Has sido testigo de migraciones de rebaños más grandes que algunos bosques, has sobrevivido a climas más extremos de lo que cualquier urbanita podría concebir y has disfrutado de la soledad de quien se sabe el único ser inteligente en kilómetros a la redonda. Ya seas un nómada, un explorador, un ermitaño, un cazador-recolector o incluso un saqueador, la naturaleza salvaje corre por tu sangre. También en aquellos lugares en los que no conoces con exactitud el terreno, todavía puedes confiar en tu conocimiento del mundo natural.",
        traits = {
            { id = "bg_sal_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Supervivencia.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Supervivencia" },
            } },
            { id = "bg_sal_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de instrumento musical.", effects = {} },
            { id = "bg_sal_idiomas", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_sal_caract", icon = "inv_misc_pelt_bear_ruin_05", name = "Vagabundo", type = "pasivo", description = "Tienes una memoria excelente en lo que a geografía y mapas respecta, de modo que puedes recordar fácilmente la disposición general del terreno y la ubicación de asentamientos y otros accidentes geográficos cercanos. Además, puedes conseguir agua potable y comida para un grupo de hasta seis personas cada día, siempre y cuando el territorio en el que te encuentres contenga bayas, caza menor, agua y demás.", effects = {} },
            { id = "bg_sal_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Bastón, trampa para cazar, trofeo de un animal al que has matado, muda de ropas de viaje y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "soldado", name = "Soldado", source = "PHB",
        desc = "Desde que tienes memoria, la guerra ha sido tu vida. Te entrenaste desde pequeño, estudiando el uso de tus a rmas y tu a rmadura. Aprendiste técnicas básicas de supervivencia, e ntre las que se encontraban cómo salir vivo del campo de batalla. Puede que forma ras parte de las fuerzas regula res de un ejército nacional o una compañía mercena ria, o tal vez luchabas en una milicia local que adquirió protagonismo durante una guerra reciente. Cuando escojas este trasfondo habla con tu DM para determinar a qué organización militar perteneces, hasta qué rango ascendiste y qué tipo de experiencias viviste durante tu carrera como militar. ¿Era un ejército perma ne nte, la guardia de una ciudad o la milicia de un pueblo? Quizá incluso se tratara del ejército privado de un noble o comerciante, o una compañía mercena ria.",
        traits = {
            { id = "bg_sol_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo e Intimidación.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Intimidacion" },
            } },
            { id = "bg_sol_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Un tipo de juego a tu elección, vehículos terrestres.", effects = {} },
            { id = "bg_sol_caract", icon = "ability_wintergrasp_rank1", name = "Rango militar", type = "pasivo", description = "Conservas un rango militar: los leales a tu antigua organización reconocen tu autoridad, obedecen órdenes de rango inferior y puedes solicitar equipo y caballos temporales o acceder a campamentos y fortalezas.", effects = {} },
            { id = "bg_sol_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Insignia de tu rango, trofeo tomado de un enemigo muerto (una daga, un filo roto o un pedazo de tela de un estandarte), juego de dados o ba raja de cartas, muda de ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    -- ===== Trasfondos de mesa / suplementos usados en perfiles Harford =====
    {
        id = "capitan_veterano_harford", name = "Capitan veterano harford", nameF = "Capitana veterana harford", source = "Harford", icon = "inv_tabard_duelersguild",
        -- "veterano harford" retirado de aqui: es la VARIANTE del Mercenario veterano y el
        -- buscador la resuelve como tal; con el alias, "Trasfondo Veterano Harford" caia aqui.
        aliases = { "capitan", "capitan harford" },
        desc = "Fuiste mas que un simple mercenario: diste órdenes que salvaron vidas y lideraste cuando otros habrían huido. Tu reputación como Capitán de la Compañía Harford te precede en muchos rincones del mundo.",
        traits = {
            { id = "bg_capharf_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo.", effects = {
                { kind = "skillProf", skill = "Atletismo" },
            } },
            { id = "bg_har_cap_autoridad", icon = "achievement_bg_3flagcap_nodeaths", name = "Autoridad del capitan harford", type = "pasivo", description = "Fuiste mas que un simple mercenario: diste órdenes que salvaron vidas y lideraste cuando otros habrían huido. Tu reputación como Capitán de la Compañía Harford te precede en muchos rincones del mundo. Cuando busques ayuda, refugio o información en zonas bajo control de la Alianza o entre enclaves mercenarios independientes, puedes invocar tu antiguo rango para obtener apoyo de antiguos subordinados, simpatizantes o contactos respetuosos. Esta ayuda puede manifestarse como alojamiento seguro, acceso a recursos limitados, reclutas dispuestos a seguirte temporalmente o información vital. Además, tienes ventaja en tiradas de Persuasión, Engaño o Intimidación al tratar con otros mercenarios, criminales reformados, soldados veteranos o desertores, oficiales retirados o cualquiera que haya servido en estructuras militares neutrales o de la Alianza. Tu rango en la compañía te permite hablar en calidad de oficial de la misma y ser su portavoz publico. Además, una vez por descanso largo tienes ventaja en una tirada de Persuasión a los mercenarios bajo tu mando.", effects = {} },
        },
    },
    {
        id = "el_loco", name = "El loco", nameF = "La loca", source = "Harford", icon = "spell_magic_polymorphrabbit",
        aliases = { "loco" },
        desc = "Tu paso por la Compañía Harford, la Espada de Ébano y una antigua herida rúnica te han dejado una reputación irregular, útil y difícil de ignorar.",
        traits = {
            { id = "bg_loco_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Persuasión.", effects = {
                { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_loco_espiritu", icon = "inv_tabard_duelersguild", name = "Espiritu harford", type = "pasivo", description = "Cuando trates de obtener ayuda, refugio o información en zonas controladas por la Alianza o por enclaves mercenarios independientes, puedes encontrar a antiguos miembros, simpatizantes o beneficiarios de la Compañía Harford dispuestos a asistirte, aunque de forma irregular o inesperada. Esta ayuda puede tomar la forma de un escondite, un informante, una tarea pagada o incluso un trago gratis y una advertencia a tiempo. Además, tienes ventaja en tiradas de Persuasión o Engaño al tratar con otros mercenarios, criminales reformados, soldados veteranos o desertores.", effects = {} },
            { id = "bg_loco_autoridad_ebano", icon = "inv_jewelry_talisman_12", name = "Autoridad de la orden: Espada de ebano", type = "pasivo", description = "Llevas contigo la reputación de tu orden allá donde vayas. Al tratar con figuras de fe, fuerzas armadas o la ley, tu rango o aura de disciplina a menudo inspiran deferencia o respeto. Una vez por descanso largo, puedes invocar el nombre o el legado de tu orden para obtener ventaja en una prueba de Persuasión o Intimidación.", effects = {} },
            { id = "bg_loco_impotencia_runica", icon = "eps_bg3_concussivestrike", name = "Impotencia runica", type = "pasivo", description = "Una antigua herida espiritual te ha hecho olvidar parte de tu entrenamiento en el uso de runas, impidiéndote utilizar ciertos hechizos propios de un caballero de la muerte. No puedes canalizar Agarre de la muerte, Orden Imperiosa ni lanzar tu Espiral de la muerte a distancia.", effects = {} },
        },
    },
    {
        id = "mercenario_veterano_harford", name = "Mercenario veterano", nameF = "Mercenaria veterana", variants = { {
            id = "mercenario_veterano_harford_veterano_harford", icon = "inv_tabard_duelersguild", name = "Veterano Harford",
            desc = "Has combatido bajo una bandera que pocos recordarían con honor, pero que tú llevas con orgullo. Fuiste parte de la Compañía Harford, un grupo caótico, desigual y extremadamente ruidoso de mercenarios cuya fama procede más de su terquedad y supervivencia que de su disciplina o precisión militar. Leal no al mando, sino al emblema de la compañía y a sus camaradas, tu vida ha sido un desfile de asedios imposibles, retiradas gloriosas, saqueos improvisados y victorias ganadas por pura testarudez.\n\nQuizá empuñaste una espada junto a desertores, navegaste en una bañera flotante apodada \"barco\", o luchaste codo con codo con magos descalzos, guerreros sin armadura y gentes extrañas. En Harford no importaba tu raza, pasado o linaje, sino si sabías mantenerte en pie tras una emboscada. Allí aprendiste a sobrevivir más que a guerrear, y a confiar en la fuerza de la costumbre, el ingenio callejero y la suerte de los insensatos.",
            -- Rasgos PROPIOS: sustituyen por completo a los del base (esquema de variantes con
            -- mecanica). Los ids de los choice se conservan del reparto anterior, para que las
            -- elecciones ya guardadas de personajes Veterano Harford sigan casando.
            traits = {
                { id = "bg_merc_hab", name = "Competencia en habilidad", type = "choice", description = "Escoge una competencia entre Atletismo, Persuasión, Engaño, Supervivencia y Perspicacia.", choice = { slots = 1, options = {
                    { id = "atletismo", icon = "inv_scroll_11", label = "Atletismo", effects = { { kind = "skillProf", skill = "Atletismo" } } },
                    { id = "persuasion", icon = "inv_scroll_11", label = "Persuasion", effects = { { kind = "skillProf", skill = "Persuasion" } } },
                    { id = "engano", label = "Engaño", effects = { { kind = "skillProf", skill = "Engano" } } },
                    { id = "supervivencia", icon = "hd_book2motif_gilneas", label = "Supervivencia", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                    { id = "perspicacia", label = "Perspicacia", effects = { { kind = "skillProf", skill = "Perspicacia" } } },
                } }, effects = {} },
                { id = "bg_merc_armas", icon = "inv_scroll_11", name = "Competencia con armas", type = "pasivo", description = "Competencia con armas marciales.", effects = {
                    { kind = "weaponProf", weapon = "armas marciales" },
                } },
                { id = "bg_merc_herr_juego", icon = "inv_misc_dice_02", name = "Juego", type = "pasivo", description = "Competencia con un juego al que jugabas con tus compañeros de barco o campamento.", effects = {
                    { kind = "toolProf", tool = "Un juego" },
                } },
                { id = "bg_merc_herr", name = "Herramienta adicional", type = "choice", description = "Escoge una herramienta adicional: herramientas de ladrón, vehículos terrestres, vehículos acuáticos o un instrumento musical (cualquier tipo de tambor o flauta popular).", choice = { slots = 1, options = {
                    { id = "her_ladron", icon = "inv_scroll_11", label = "Herramientas de ladron", effects = { { kind = "toolProf", tool = "Herramientas de ladron" } } },
                    { id = "vehiculos_terrestres", label = "Vehiculos terrestres", effects = { { kind = "toolProf", tool = "Vehiculos terrestres" } } },
                    { id = "vehiculos_acuaticos", label = "Vehiculos acuaticos", effects = { { kind = "toolProf", tool = "Vehiculos acuaticos" } } },
                    { id = "her_instrumento", icon = "inv_scroll_11", label = "Instrumento musical", effects = { { kind = "toolProf", tool = "Instrumento musical" } } },
                } }, effects = {} },
                { id = "bg_merc_espiritu", icon = "inv_tabard_duelersguild", name = "Espiritu Harford", type = "pasivo", description = "Has sobrevivido a emboscadas sin plan, a líderes sustituidos por sorteo, y a contratos firmados en servilletas. Tu experiencia en la Compañía Harford te ha enseñado a improvisar con lo que haya a mano y a trabajar codo con codo con individuos de lo más variopintos.\n\nCuando trates de obtener ayuda, refugio o información en zonas controladas por la Alianza o por enclaves mercenarios independientes, puedes encontrar a antiguos miembros, simpatizantes o beneficiarios de la Compañía Harford dispuestos a asistirte, aunque de forma irregular o inesperada. Esta ayuda puede tomar la forma de un escondite, un informante, una tarea pagada o incluso un trago gratis y una advertencia a tiempo.\n\nAdemás, tienes ventaja en tiradas de Carisma (Persuasión o Engaño) al tratar con otros mercenarios, criminales reformados, soldados veteranos o desertores.", effects = {} },
                { id = "bg_merc_vh_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Un recuerdo cochambroso de tu tiempo en Harford (un clavo bendito, una petaca vacía, una insignia oxidada...), un juego al que jugabas con tus compañeros de barco o campamento, un tabardo Harford remendado varias veces y una bolsa con 8 po (2 po se los quedó el capitán al pagaros).", effects = {} },
            },
        } }, source = "Warcraft", icon = "w3reforgedbandit",
        -- "veterano harford" ya no es alias del BASE: es su variante, y como alias ganaba el
        -- empate y el buscador devolvia el trasfondo sin la variante.
        aliases = { "mercenario veterano", "mercenario harford" },
        desc = "Como mercenario que lucha en contiendas a cambio de dinero, estás muy acostumbrado a jugarte la vida por la oportunidad de ganar parte de un tesoro. Ahora estás dispuesto a matar a enemigos y a conseguir incluso mejores recompensas como aventurero. Tu experiencia te familiariza con los pormenores de la vida del mercenario y es posible que tengas relatos desgarradores de lo acontecido en el campo de batalla. Tal vez serviste en un batallón grande o en un grupo menor de mercenarios (o puede que incluso con más de uno).\n\nAhora buscas algo distinto, tal vez una recompensa mayor a cambio de los riesgos que asumes o quizá la libertad de escoger tus propias actividades. Sea cual sea el motivo, dejas atrás la vida de un soldado a sueldo, pero tus habilidades son sin duda adecuadas para el combate, de modo que ahora sigues luchando, pero de otro modo.",
        traits = {
            { id = "bg_merc_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Persuasión.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_merc_herr_base", icon = "inv_misc_dice_02", name = "Competencia con herramientas", type = "pasivo", description = "Un juego y vehículos terrestres.", effects = {
                { kind = "toolProf", tool = "Un juego" }, { kind = "toolProf", tool = "Vehiculos terrestres" },
            } },
            { id = "bg_merc_vida", icon = "w3reforgedmercenarycamp", name = "Vida mercenaria", type = "pasivo", description = "Conocer la vida mercenaria como solo puede hacerlo quien la ha vivido. Eres capaz de identificar a las compañías de mercenarios por sus emblemas y sabes un poco sobre cualquiera de ellas, incluyendo los nombres y la reputación de sus comandantes y líderes, así como los ejércitos en los que han contratado últimamente. Puedes hallar las tabernas y los salones donde moran los mercenarios en cualquier lugar, siempre que hables el idioma local. Te encuentras a gusto. Si estructuras tu trabajo de mercenario entre aventuras como parte normal de tu vida cotidiana, obtienes un modo de vida cómodo.", effects = {} },
            { id = "bg_merc_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "El uniforme de tu compañía (ropas de viaje de calidad), una insignia con tu rango, las piezas de un juego que escojas y una bolsa que contiene lo que queda de tu última paga (10 po).", effects = {} },
        },
    },
    {
        id = "exiliado_alterac", name = "Exiliado de Alterac", nameF = "Exiliada de Alterac", source = "Warcraft",
        aliases = { "alterac", "exiliado alterac", "exiliado de alterac" },
        desc = "Fuiste criado entre los restos de un reino traicionado y borrado del mapa. Tu familia fue leal al trono de Alterac, o quizás solo fue arrastrada por la caída del rey Perenolde y la humillación pública de tu pueblo. Tras la Segunda Guerra, mientras los reinos humanos reescribían la historia, tú creciste escuchando una versión distinta: una de abandono, de culpa compartida, de dignidad pisoteada.\n\nAlgunos de los tuyos se unieron al Sindicato, otros huyeron al exilio, muchos vivieron décadas como ciudadanos de segunda. Pero los exiliados de Alterac no olvidan, y aunque su reino esté en ruinas, su identidad sigue viva. Tú eres uno de ellos: marcado por la historia, endurecido por la pérdida, y con un legado que no desaparece.",
        traits = {
            { id = "bg_alt_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Engaño e Historia.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_alt_herr", name = "Competencia con herramientas", type = "choice", description = "Elige una competencia entre herramientas de falsificacion o kit de disfraz.", choice = { slots = 1, options = {
                { id = "her_falsificacion", label = "Herramientas de falsificacion", effects = { { kind = "toolProf", tool = "Herramientas de falsificacion" } } },
                { id = "her_disfraz", label = "Kit de disfraz", effects = { { kind = "toolProf", tool = "Kit de disfraz" } } },
            } }, effects = {} },
            { id = "bg_alt_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma adicional, como Orco u otro idioma del pueblo que te acogio.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_alt_peso", icon = "w3reforgedtinycastle", name = "Peso de un reino caido", type = "pasivo", description = "Has aprendido a moverte entre la humillación, la sospecha y la resistencia. Sabes cuándo callar, cuándo hablar... y con quién. Puedes identificar a otros exiliados o simpatizantes de Alterac mediante gestos, acentos o símbolos ocultos. Obtienes ventaja en pruebas de Carisma (Persuasión o Engaño) o de Historia cuando trates con individuos marcados por el exilio, la derrota o el legado de la Segunda Guerra (como miembros del Sindicato, veteranos de Stromgarde o refugiados de Lordaeron).\n\nAdemás, puedes encontrar refugio entre comunidades marginales, contrabandistas o grupos de exiliados que aún recuerdan a Alterac.\n\n(edited)", effects = {} },
            { id = "bg_alt_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Un recuerdo de Alterac, ropa modesta con detalles del color naranja tradicional, un diario familiar o copia clandestina del Decreto de ocupación, y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "acolito_luz_abisal", name = "Acolito de la Luz Abisal", nameF = "Acolita de la Luz Abisal", source = "Warcraft",
        aliases = { "luz abisal", "acolito luz abisal" },
        desc = "Has sido moldeado por las enseñanzas del Templo de la Luz Abisal, un santuario nacido durante la campaña de Legión, donde discípulos de la Luz y campeones de la Sombra se alzaron juntos en desafío de una oscuridad mayor.\n\nAdiestrado por sacerdotes, caminantes del vacío y profetas poco ortodoxos, aprendiste a transitar el estrecho sendero entre lo divino y lo profano. Ya seas un verdadero creyente, un escéptico que presenció un milagro, o un recipiente reacio imbuido tanto por la Luz como por el Vacío, tu presencia emana una calma que incomoda a los fanáticos de ambos extremos.",
        traits = {
            { id = "bg_luz_abisal_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Religión y Perspicacia.", effects = { Skill("Religion"), Skill("Perspicacia") } },
            { id = "bg_luz_abisal_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con útiles de caligrafo.", effects = { Tool("Utiles de caligrafo") } },
            { id = "bg_luz_abisal_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección, normalmente eredun o shath'yar.", effects = {}, choice = { slots = 1, optionsFrom = "language", exotic = true } },
            { id = "bg_luz_abisal_rasgo", icon = "WH_BalanceEssence", name = "Equilibrio de fuerzas", type = "pasivo", description = "Tu presencia emana quietud en el caos y claridad en la duda. Puedes identificar de forma intuitiva si un efecto mágico o presencia está alineado con energías opuestas (como radiante o necrótica, celestial o demoníaca).\n\nAdemás, obtienes ventaja en pruebas de Carisma al intentar mediar o desescalar situaciones que involucren ideologías u orígenes mágicos opuestos.", effects = {} },
        },
    },
    {
        id = "anima_errante", name = "Anima errante", source = "Harford", icon = "ability_warlock_soulswap",
        aliases = { "anima errante" },
        desc = "Eras un eco, una chispa de esencia perdida entre la vida y la muerte, hasta que encontraste un cuerpo vacío y lo ocupaste. Ahora exploras el mundo de los vivos como algo casi humano.",
        traits = {
            { id = "bg_anima_visitante", icon = "ability_argus_deathfog", name = "Visitante del mas alla", type = "pasivo", description = "Puedes percibir presencias no corporeas ocultas (fantasmas, almas, animas) en un radio de 9 m (9 metros), y ellas también pueden percibirte a ti. Obtienes ventaja en pruebas de Sigilo realizadas en lugares oscuros, silenciosos o cargados de energía mágica o espiritual, como cementerios, templos antiguos o ruinas. Los efectos que detectarian vida o muerte, como Detectar el Bien y el Mal o Sentido Divino, te perciben de forma confusa: ni viva ni muerta, apenas un eco. Una vez por descanso largo, puedes alterar levemente tu forma corporal (ojos apagados, silueta desvanecida, voz hueca) para obtener ventaja en una prueba de Intimidación o Engaño según la situación.", effects = {} },
        },
    },
    {
        id = "adepto_cosecha_oscura", name = "Adepto de la cosecha oscura", nameF = "Adepta de la cosecha oscura", source = "Warcraft",
        aliases = { "cosecha oscura", "adepto cosecha oscura" },
        desc = "Fuiste entrenado por la Cosecha Oscura, una oscura cábala de brujos y eruditos arcanos que buscan dominar la magia vil y del vacío—no por devoción, sino por dominación.\n\nPara la Cosecha Oscura, el conocimiento es el arma más afilada. Sus miembros no sirven a fuerzas oscuras ciegamente—las diseccionan, las controlan y las doblegan a su voluntad. Ya fueras un pícaro siniestro, un superviviente de la influencia demoníaca o un estudioso de saberes prohibidos, tu iniciación te marcó como algo más: un portador de conocimientos peligrosos.\n\nTu entrenamiento fue arduo, secreto y, a menudo, solitario, pero te concedió herramientas que pocos mortales se atreven siquiera a reclamar. Cargas contigo las lecciones de aquellos que creen que el control sobre la oscuridad no solo es posible—es necesario.",
        traits = {
            { id = "bg_cosecha_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano y Engaño.", effects = { Skill("Arcano"), Skill("Engano") } },
            { id = "bg_cosecha_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con útiles de caligrafo.", effects = { Tool("Utiles de caligrafo") } },
            { id = "bg_cosecha_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_cosecha_codigo", icon = "inv_misc_codexofxerrath_chains", name = "Codigo del buscador de Demonios", type = "pasivo", description = "Reconoces los indicios sutiles de actividad demoníaca o corrupta y puedes comunicarte discretamente con otros miembros de la Cosecha Negra para obtener información o asistencia. Siempre puedes detectar la presencia de un demonio, una maldición vil o corrupción del vacío en un radio de 9 metros, aunque no su ubicación exacta ni su fuente precisa. Este sentido es instintivo y no puede ser suprimido, ni siquiera por silencio mágico o ilusión.", effects = {} },
        },
    },
    {
        id = "agente_principe_mercante", name = "Agente de principe mercante", source = "Warcraft",
        aliases = { "agente de principe mercante", "agente_de_pr_ncipe_mercante", "principe mercante", "agente mercante" },
        desc = "Eres parte emprendedor, parte matón, parte embaucador de lengua de plata, con un talento innato para convertir riesgos en ganancias. Desde Gadgetzan hasta Trinquete, de salas de juntas goblin hasta yacimientos en la jungla, tu trabajo es simple: hacer más rico a tu jefe... y asegurarte de obtener tu parte.",
        traits = {
            { id = "bg_principe_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Persuasión y Perspicacia.", effects = { Skill("Persuasion"), Skill("Perspicacia") } },
            { id = "bg_principe_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con herramientas de navegador y un tipo de herramientas de artesano.", effects = { Tool("Herramientas de navegador"), Tool("Herramientas de artesano") } },
            { id = "bg_principe_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "informativo", description = "Hablas, lees y escribes Goblin.", effects = { { kind = "language", language = "Goblin" } } },
            { id = "bg_principe_conexiones", icon = "ability_racial_timeismoney", name = "Conexiones del cartel", type = "pasivo", description = "Como agente de un príncipe mercante, manejas el poder invisible del capitalismo goblin —manos engrasadas, rumores susurrados y tratos en la trastienda. Dondequiera que vayas, puedes recurrir a la vasta red de informantes, corredores y contrabandistas de tu cártel para obtener información privilegiada sobre mercados locales, ubicar bienes raros o restringidos, o concertar una reunión con alguien “que sabe”.\n\nAdemás, tienes ventaja en tiradas de Carisma (Persuasión) realizadas para regatear, negociar o convencer a otros en asuntos de comercio y transacciones.", effects = {} },
        },
    },
    {
        id = "bucanero_retirado", name = "Bucanero retirado", nameF = "Bucanera retirada", source = "Warcraft",
        desc = "Fuiste en su día un temido miembro de una tripulación notoria, sembrando el terror por los mares con tus hazañas piratas.\n\nSin embargo, has dejado atrás tu pasado criminal. Ahora recorres el mundo, buscando demostrar tu valía más allá de la piratería. Ya sea que hayas pertenecido a los Bucaneros Velasangre, los Asaltantes Aguasnegras, las Ratas de Pantoque o cualquier otra tripulación, el mundo te percibe del mismo modo.",
        traits = {
            { id = "bg_buc_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Atletismo.", effects = { Skill("Engano"), Skill("Atletismo") } },
            { id = "bg_buc_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con herramientas de navegación y una herramienta de artesano a tu elección.", effects = { Tool("Herramientas de navegacion"), Tool("Herramientas de artesano") } },
            { id = "bg_buc_canalla", icon = "ability_rogue_blackjack", name = "Canalla veterano", type = "pasivo", description = "Tu vida como corsario te ha brindado conocimientos del inframundo criminal y una gran familiaridad con los mares abiertos. Ya no te ralentiza nadar con armadura media y debes escoger uno de los siguientes beneficios:\n- Ganas ventaja en pruebas de Carisma (Engaño) cuando subvertir o infringir la ley esté en juego.\n- Ganas ventaja en pruebas de Sabiduría (Supervivencia) cuando estés en el mar o a bordo de un barco.", effects = {} },
        },
    },
    {
        id = "buscador_sombrio", name = "Buscador sombrio", nameF = "Buscadora sombria", source = "Harford", icon = "dos2_shadow12",
        aliases = { "buscador sombrio" },
        desc = "Nunca has tenido un gran propósito heroico. Te mueven impulsos mas pequeños pero intensos: proteger lo que importa y encontrar tu lugar en un mundo que nunca te lo puso fácil.",
        traits = {
            { id = "bg_busc_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Engaño.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Engano" },
            } },
            { id = "bg_sombrio_sintonia_vil", icon = "eps_wc3h_felpower", name = "Sintonia vil", type = "pasivo", description = "Tu relación con los demonios no es teorica ni lejana: sabes de sacrificios, muerte y decisiones irreversibles. Tienes ventaja en tiradas de salvación contra miedo causadas por demonios, no muertos y efectos de corrupción vil o necrótica. Además, una vez por descanso largo, cuando reduzcas a una criatura a 0 PG con un conjuro necrótico, recuperas mana igual a Mod. Inteligencia.", effects = {} },
        },
    },
    {
        id = "caballero_orden", name = "Caballero de la orden", nameF = "Caballera de la orden", source = "Warcraft",
        aliases = { "caballero de la orden" },
        desc = "Fuiste entrenado por una orden marcial estructurada como la Mano de Plata, los Caballeros de Sangre, los Caminasol, la Cruzada Escarlata o la Espada de Ébano, todos ellos devotos de un ideal superior al de ellos mismos.\n\nYa sea que hayas sido un acólito de la Luz, un sacerdote de An’she, o un soldado templado en las sombras, tu disciplina y sentido del deber te distinguen. Algunos aún portan el símbolo de su orden con orgullo; otros recorren un camino solitario, comprometidos con causas que otros han abandonado o repudiado. Ya fuera que tus votos se juraran bajo el sol o se grabaran en la no-muerte, estos continúan moldeando tus convicciones... y tu poder.",
        traits = {
            { id = "bg_ord_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Religión y Persuasión.", effects = { Skill("Religion"), Skill("Persuasion") } },
            { id = "bg_ord_herr", name = "Competencia con herramientas", type = "choice", description = "Elige herramientas de herrero o útiles de caligrafo.", choice = { slots = 1, options = {
                { id = "her_herrero", label = "Herramientas de herrero", effects = { Tool("Herramientas de herrero") } },
                { id = "caligrafo", label = "Utiles de caligrafo", effects = { Tool("Utiles de caligrafo") } },
            } }, effects = {} },
            { id = "bg_ord_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_ord_autoridad", icon = "inv_jewelry_talisman_12", name = "Autoridad de la orden", type = "pasivo", description = "Llevas contigo la reputación de tu orden allá donde vayas. Al tratar con figuras de fe, fuerzas armadas o la ley, tu rango o aura de disciplina a menudo inspiran deferencia o respeto. Una vez por descanso largo, puedes invocar el nombre o el legado de tu orden para obtener ventaja en una prueba de Carisma (Persuasión o Intimidación).", effects = {} },
        },
    },
    {
        id = "cruzado_argenta", name = "Cruzado Argenta", nameF = "Cruzada Argenta", source = "Warcraft",
        aliases = { "cruzada argenta", "argenta" },
        desc = "Como miembro leal de la Cruzada Argenta, eres un defensor tenaz contra las fuerzas de oscuridad que amenazan Azeroth. Forjado en el crisol del conflicto, portas el estandarte de la esperanza y empuñas el poder de la rectitud para erradicar horrores no-muertos y otras entidades malévolas. Tu inquebrantable dedicación al honor, al deber y a la justicia te impulsa a luchar al frente de la batalla, liderando la carga contra la oscuridad que busca envolver el mundo.",
        traits = {
            { id = "bg_arg_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Religión y Atletismo.", effects = { Skill("Religion"), Skill("Atletismo") } },
            { id = "bg_arg_juego", icon = "inv_misc_dice_02", name = "Juego", type = "choice", description = "Competencia con un juego a tu eleccion.", effects = {}, choice = { slots = 1, optionsFrom = "game" } },
            { id = "bg_arg_determinacion", icon = "hots_xinzhao_determination", name = "Determinacion inquebrantable", type = "pasivo", description = "Tu compromiso incondicional con la causa te otorga ventaja en las tiradas de salvación contra el miedo, siempre que su origen sea un no-muerto. Además, puedes lanzar el conjuro Bendecir, pero sus efectos solo se aplican a tiradas de ataque y salvación contra no-muertos. Recuperas esta habilidad tras un descanso largo.", effects = {} },
        },
    },
    {
        id = "desertor_errante", name = "Desertor errante", nameF = "Desertora errante", source = "Warcraft", icon = "achievement_general_classicbattles",
        aliases = { "desertor" },
        desc = "Los desertores errantes son individuos que han dejado atrás las ataduras de su facción anterior, impulsados por una sed de libertad personal y el deseo de forjar su propio destino. Desencantados con las ideologías que antes los definían, siguen ahora un camino incierto como agentes independientes, guiados por un renovado sentido de autonomía y su propio código moral.\n\nEstos desertores están unidos por su valentía para romper con el pasado, abrazando una vida de incertidumbre mientras forjan alianzas, desafían normas y buscan su lugar en el turbulento mundo de Azeroth.",
        traits = {
            { id = "bg_des_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Supervivencia.", effects = { Skill("Perspicacia"), Skill("Supervivencia") } },
            { id = "bg_des_herr", name = "Competencia con herramientas", type = "choice", description = "Elige un juego o un instrumento musical.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_des_saboteador", icon = "inv_misc_enggizmos_38", name = "Saboteador", type = "pasivo", description = "Habiendo sido un miembro de confianza de tu antigua facción, posees conocimientos sobre sus tácticas y estrategias. Puedes usar esa familiaridad a tu favor al tratar con individuos de tu facción anterior. Tienes ventaja en pruebas de Carisma (Engaño) para hacerte pasar por un miembro de tu antigua facción, y puedes usar Mod. Inteligencia en lugar de Mod. Carisma al hacer pruebas de Carisma (Engaño).", effects = {} },
        },
    },
    {
        id = "eremita", name = "Eremita", source = "Warcraft",
        aliases = { "eremita erudito" },
        desc = "Como devoto miembro de los Eremitas, eres un ávido buscador de conocimiento, impulsado por una pasión por desentrañar el rico tapiz de historia, leyenda y cultura que recorre todo Azeroth. Tu insaciable curiosidad y meticulosa atención al detalle te convierten en un hábil historiador y narrador, encargado de preservar las historias más preciadas del mundo. Con reverencia por el pasado y el deseo de compartir sus enseñanzas, te embarcas en misiones en busca de conocimientos olvidados y verdades ocultas, asegurándote de que el legado de Azeroth perdure para las generaciones futuras.",
        traits = {
            { id = "bg_ere_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Perspicacia.", effects = { Skill("Historia"), Skill("Perspicacia") } },
            { id = "bg_ere_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "choice", description = "Competencia con suministros de caligrafo y un instrumento musical a tu eleccion.", effects = { Tool("Suministros de caligrafo") }, choice = { slots = 1, optionsFrom = "instrument" } },
            { id = "bg_ere_perspicacia", icon = "achievement_faction_lorewalkers", name = "Perspicacia erudita", type = "pasivo", description = "Tu profundo entendimiento de la historia te otorga ventaja en las pruebas de Inteligencia (Historia) relacionadas con conocimientos ocultos o la decodificación de códigos.\n\nAdemás, puedes gastar 10 minutos e intentar una prueba de Inteligencia (Historia) CD 13 para obtener los beneficios del conjuro comprender idiomas, usando tu experiencia para descifrar e interpretar textos escritos en diversos idiomas.", effects = {} },
        },
    },
    {
        id = "feriante_luna_negra", name = "Feriante de la Luna Negra", source = "Warcraft",
        aliases = { "luna negra", "feriante" },
        desc = "Eres un artista cautivador dentro del enigmático reino de la Feria de la Luna Negra. Con tus hipnotizantes actos de magia, arte o hazañas audaces, atraes multitudes que acuden a presenciar tus maravillosas exhibiciones. Como artista de la Feria, ofreces un escape muy necesario de las penas del mundo, brindando sonrisas y asombro a quienes se congregan bajo las coloridas carpas del carnaval.\n\nSin embargo, entre tanto encanto, percibes un misterio más profundo que envuelve los orígenes de la Feria, y navegas sus secretos con la misma destreza con la que ejecutas tus actuaciones.",
        traits = {
            { id = "bg_luna_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Interpretación y Juego de Manos.", effects = { Skill("Interpretacion"), Skill("JuegoManos") } },
            { id = "bg_luna_herr1", icon = "inv_scroll_11", name = "Kit de disfraces", type = "pasivo", description = "Competencia con kit de disfraces.", effects = { Tool("Kit de disfraces") } },
            { id = "bg_luna_herr2", name = "Juego o instrumento", type = "choice", description = "Elige un juego o un instrumento musical.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_luna_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_luna_actuacion", icon = "inv_darkmoon_vengeance", name = "Actuacion hipnotica", type = "pasivo", description = "Has perfeccionado tus talentos como artista para cautivar y encantar a tu audiencia. Cuando actúas durante al menos un minuto, puedes usar tus habilidades para crear una exhibición mágica y envolvente. Esta exhibición puede distraer o maravillar a los observadores, otorgándote ventaja en pruebas de Carisma (Engaño) hechas para distraer o desviar atención.\n\nAdemás, puedes usar Carisma (Interpretación) para mantener un estilo de vida acomodado durante tus descansos o conseguir alojamiento intercambiando tus servicios en la mayoría de las posadas o tabernas.", effects = {} },
        },
    },
    {
        id = "devoto_elune", name = "Devoto de Elune", nameF = "Devota de Elune", source = "Harford", icon = "eps_wow_eluneschosen",
        aliases = { "devoto de elune", "devota de elune", "devoto elune", "devota elune" },
        desc = "Has dedicado tu vida a servir a Elune, la Dama de la Luna, llevando consuelo, remedios y esperanza a quienes sufren. Para ti, mientras quede una chispa de vida, merece la pena intentar salvarla.",
        traits = {
            { id = "bg_elu_competencias", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Medicina y Religión.", effects = {
                Skill("Medicina"), Skill("Religion"),
            } },
            { id = "bg_elu_herborista", icon = "inv_scroll_11", name = "Kit de herborista", type = "pasivo", description = "Competencia con kit de herborista.", effects = {
                Tool("Kit de herborista"),
            } },
            { id = "bg_elu_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_elu_luz_sanadora", icon = "hots_tyrande_lightofelune", name = "Luz sanadora", type = "pasivo", description = "En asentamientos con templos, santuarios o comunidades dedicadas a la curación, la naturaleza o una divinidad benevola, puedes solicitar alojamiento, comida y asistencia médica básica para ti y quienes estén bajo tu cuidado. Tu reputación puede abrir hospitales, templos, casas de sanadores y comunidades, a discreción del DM.", effects = {} },
            { id = "bg_elu_equipo", icon = "inv_misc_bag_20", name = "Equipo", type = "pasivo", description = "Símbolo sagrado de Elune, kit de herborista, libro de plegarias, recipiente con hierbas medicinales y ungüentos, manto blanco y azul oscuro, y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "forastero", name = "Forastero", nameF = "Forastera", source = "Warcraft",
        aliases = { "extranjero" },
        desc = "La mayoría de los habitantes de Azeroth jamás abandonan su tierra natal. Ya sea un campesino de los Reinos del Este, un tabernero en Kalimdor o un comerciante en Zandalar, muchos viven y mueren sin alejarse más que unos pocos kilómetros de donde nacieron. Tú no eres como ellos.\n\nVienes de una región lejana, exótica o directamente desconocida para la mayoría. Quizá naciste en los valles ocultos de Pandaria, entre las ruinas susurrantes de Uldum, o en alguna aldea perdida de Rasganorte. Tal vez incluso tu patria se halle más allá del Gran Mar o en una isla apenas registrada en los mapas de la Horda o la Alianza. Sea como sea, tu historia es inusual, y las razones que te han traído hasta aquí pueden ser personales, políticas, místicas... o un misterio que prefieres no revelar.\n\nAl llegar a estas tierras, muchas costumbres te resultan extrañas, incluso ridículas; pero también hay maravillas que nunca imaginaste: ciudades suspendidas en el aire, mercados infestados de goblins y criaturas que solo habías oído en viejas canciones. De igual forma, tú eres un enigma andante para los demás: alguien con acento raro, hábitos desconcertantes o apariencia única. Donde vayas, despertarás curiosidad, respeto o desconfianza... o las tres cosas a la vez.",
        traits = {
            { id = "bg_for_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Percepción y Perspicacia.", effects = { Skill("Percepcion"), Skill("Perspicacia") } },
            { id = "bg_for_herr", name = "Juego o instrumento", type = "choice", description = "Elige un instrumento o juego de tu patria.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_for_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma cualquiera de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_for_mirada", icon = "achievement_bg_most_damage_killingblow_dieleast", name = "Todos se fijan en ti", type = "pasivo", description = "Tu acento, maneras, figuras retóricas e incluso tu apariencia te señalan como extranjero. Se te dedican miradas curiosas doquiera que vayas, lo que puede ser un engorro, pero también te brinda el interés amistoso de eruditos y otros fascinados por tierras lejanas, por no mencionar al pueblo llano, que ansía escuchar anécdotas sobre tu patria.\n\nPuedes negociar con esta atención para obtener acceso a personas y lugares que de otro modo no conseguirías, tanto para ti como para tus compañeros de aventura. Señores nobles, estudiosos y príncipes mercantes, por mencionar solo un puñado, pueden tener interés en saber más sobre tu patria lejana y sus gentes.\n\n(edited)", effects = {} },
        },
    },
    {
        id = "forjador_torio", name = "Forjador de la Hermandad del Torio", nameF = "Forjadora de la Hermandad del Torio", source = "Warcraft",
        aliases = { "hermandad del torio", "forjador de torio", "forjador torio" },
        desc = "Perteneces a una casta de artesanos que anteponen la perfección a cualquier otra virtud. La Hermandad no acepta mediocridad: solo aquellos que soportan el calor y la presión de sus hornos pueden ganarse un nombre entre los suyos. Has aprendido los secretos de la forja encantada, de la runomagia práctica, y sabes que el valor de un objeto está en su equilibrio entre utilidad y arte.\n\nPuede que seas enano, pero no necesariamente. Aunque raros, se conocen casos de orcos, elfos o humanos que han sido aceptados como aprendices si demostraban una maestría sin igual y un respeto absoluto por el oficio. En cualquier caso, el orgullo de tu trabajo habla antes que tu raza.",
        traits = {
            { id = "bg_torio_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Perspicacia.", effects = { Skill("Historia"), Skill("Perspicacia") } },
            { id = "bg_torio_herr", icon = "inv_scroll_11", name = "Herramientas de forja", type = "pasivo", description = "Competencia con herramientas de forja.", effects = { Tool("Herramientas de forja") } },
            { id = "bg_torio_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Enano y un idioma adicional si ya hablas enano.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_torio_prestigio", icon = "inv_ingot_07", name = "Prestigio de la Hermandad del Torio", type = "pasivo", description = "Los artesanos de la Hermandad del Torio son respetados, temidos y codiciados por igual. En asentamientos donde el comercio de armas o metalurgia es importante (como Forjaz, Bahía del Botín o incluso Orgrimmar), los miembros de la Hermandad reciben alojamiento gratuito y acceso prioritario a talleres, hornos o yacimientos.\n\nLos gremios y mercaderes saben que tratar contigo abre la puerta a artefactos imbuidos con técnicas ancestrales y poderosas encantaciones.", effects = {} },
        },
    },
    {
        id = "guardian_salvaje", name = "Guardian de lo salvaje", nameF = "Guardiana de lo salvaje", source = "Warcraft", icon = "ability_hunter_huntervswild",
        aliases = { "guardian de lo salvaje", "guardiana de lo salvaje", "guardian salvaje" },
        desc = "Fuiste entrenado por un enclave primitivo, una sociedad de supervivencia o un grupo de sabiduría salvaje vinculados a organizaciones como el Refugio Alblanco, la Senda Oculta, los Errantes, las Centinelas, las expediciones de Hemet Nesingwary o círculos locales en la naturaleza a lo largo de Azeroth.\n\nDesde las brumosas alturas de las Colinas Pardas hasta las enredadas raíces de Val’sharah y los cañones de Nagrand, los parajes salvajes de Azeroth perduran solo bajo la custodia de quienes conocen sus ritmos. Aprendiste no solo a sobrevivir en tierras indómitas, sino a leer sus señales, proteger sus secretos y restaurar su equilibrio cuando se ve amenazado.",
        traits = {
            { id = "bg_gsal_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Supervivencia.", effects = { Skill("Naturaleza"), Skill("Supervivencia") } },
            { id = "bg_gsal_herr", name = "Competencia con herramientas", type = "choice", description = "Elige kit de herboristeria o herramientas de tallador de madera.", choice = { slots = 1, options = {
                { id = "herboristeria", label = "Kit de herboristeria", effects = { Tool("Kit de herboristeria") } },
                { id = "her_tallador", label = "Herramientas de tallador de madera", effects = { Tool("Herramientas de tallador de madera") } },
            } }, effects = {} },
            { id = "bg_gsal_voz", icon = "ability_hunter_onewithnature", name = "Voz de la naturaleza", type = "pasivo", description = "Estás en sintonía con el lenguaje de la tierra y sus ritmos primordiales. En entornos naturales, puedes identificar senderos seguros, notar señales de presencias antinaturales y reconocer marcas territoriales dejadas por bestias o espíritus. Tienes ventaja en pruebas de Sabiduría (Supervivencia) para rastrear u orientarte en áreas salvajes, y a menudo las bestias salvajes o los espíritus naturales te muestran respeto —incluso cuando atacarían a otros al verte.", effects = {} },
        },
    },
    {
        id = "guardia_ciudad", name = "Guardia de ciudad", variants = { { id = "guardia_ciudad_detective", icon = "eps_bg3_identify", name = "Detective", desc = "Los detectives de una comunidad, menos numerosos que los guardias o los miembros de una patrulla, poseen el deber de resolver crímenes en base a hechos. Aunque raramente se da este tipo de persona en zonas rurales, casi cualquier asentamiento de tamaño decente tiene como mínimo a uno o dos miembros de la guardia con la habilidad de investigar los lugares en los que se ha cometido un crimen y perseguir a los malhechores. Si tienes experiencia previa como investigador, posees competencia en  Investigación en vez de en Atletismo.  (edited)" } }, source = "Warcraft", icon = "ability_warrior_vigilance",
        aliases = { "guardia urbano", "guardia de ciudad" },
        desc = "Trabajas para la comunidad en la que has crecido y eres su primera línea de defensa contra el crimen. No eres un soldado, sino alguien que dirige su mirada a posibles enemigos. En vez de eso, tu servicio a tu ciudad natal consistió en ayudar a controlar su población y proteger a sus ciudadanos de delincuentes y maleantes de toda clase.\n\nPuede que hayas formado parte de la Guardia de Ventormenta, la fuerza policial armada con porras de Tol Barad, que defiende al pueblo llano tanto de ladrones como de la nobleza pendenciera. O puedes haber sido uno de los valientes defensores de Lunargenta, miembro de la Guardia Gris o incluso miembro de la Guardia de Dalaran, portador de magia. Quizá provienes de Kul Tiras y has sido uno de los guardias de Boralus.\n\nAunque no hayas nacido ni te hayas criado en una ciudad, este trasfondo puede describir tus primeros años como miembro de un cuerpo policial. La mayoría de asentamientos de cualquier tamaño tienen agentes y fuerzas policiales. Incluso las comunidades pequeñas cuentan con sheriffs y alguaciles preparados para proteger su comunidad.",
        traits = {
            { id = "bg_guardia_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Perspicacia.", effects = { Skill("Atletismo"), Skill("Perspicacia") } },
            { id = "bg_guardia_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_guardia_ojo", icon = "eps_wc3h_mountedfootman", name = "Ojo de guardian", type = "pasivo", description = "Debido a tu experiencia haciendo cumplir las leyes y lidiando con malhechores, tienes cierta intuición para entender la legislación y los criminales de una zona. Puedes encontrar sin mayores problemas el puesto fronterizo de la guardia o una organización parecida en cualquier lugar, así como los escondrijos de la actividad criminal de una comunidad con la misma facilidad, aunque es más probable que seas mejor acogido entre los guardias que entre los ladrones.", effects = {} },
        },
    },
    {
        id = "heredero", name = "Heredero", nameF = "Heredera", source = "Warcraft",
        desc = "Has heredado algo de gran valor; no solo dinero o fortuna, sino un objeto que se te ha confiado a ti y solo a ti. Puede que esta herencia te la haya legado directamente un miembro de tu familia por derecho de nacimiento, o bien que te la haya dejado un amigo, mentor, profesor o alguien importante. La revelación de esta herencia te cambió la vida, y quizá te condujo al camino de la aventura. Sin embargo, también puede estar cargada de peligros, incluyendo a quienes codician tu tesoro y te lo quieren arrebatar, si hace falta, por la fuerza.",
        traits = {
            { id = "bg_hered_superv", icon = "inv_scroll_11", name = "Supervivencia", type = "pasivo", description = "Competencia en Supervivencia.", effects = { Skill("Supervivencia") } },
            { id = "bg_hered_hab", name = "Habilidad adicional", type = "choice", description = "Elige Conocimiento Arcano, Historia o Religión.", choice = { slots = 1, options = {
                { id = "arcano", label = "Conocimiento Arcano", effects = { Skill("Arcano") } },
                { id = "historia", label = "Historia", effects = { Skill("Historia") } },
                { id = "religion", icon = "ability_racial_ancienthistory", label = "Religion", effects = { Skill("Religion") } },
            } }, effects = {} },
            { id = "bg_hered_herr", name = "Juego o instrumento", type = "choice", description = "Elige un instrumento musical o un juego.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
            } }, effects = {} },
            { id = "bg_hered_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma cualquiera de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_hered_rasgo", icon = "inv_icon_heirloomtoken_armor01", name = "Herencia", type = "pasivo", description = "Escoge o determina aleatoriamente tu herencia a partir de las posibilidades de la tabla que hay a continuación. Para definir los detalles, colabora con tu DM. ¿Por qué es tan importante y cuál es la historia que hay tras ella? Tal vez prefieras que el DM invente esos datos como parte del juego, lo que te permite ir averiguando aspectos de tu herencia a medida que lo hace tu personaje.\n\nEl DM puede usar tu herencia como gancho para una historia. Puede hacerte cumplir misiones para desentrañar su historia o su naturaleza real, o bien obligarte a enfrentarte con enemigos que quieren quedársela o evitar que averigües lo que buscas. El DM también elige las propiedades de tu herencia y cómo encajan en la narración y la importancia del objeto. Por ejemplo, puede tratarse de un objeto mágico de poca trascendencia o de uno que empiece con una capacidad moderada y aumente de poder a medida que pasa el tiempo. También puede ser que la naturaleza real no sea aparente al principio y solo se revele si se dan ciertas condiciones.\n\nCuando empieces tu carrera como aventurero, puedes decidir si hablas de inmediato sobre tu herencia con tus compañeros. En vez de atraer la atención, quizá prefieras que siga siendo un secreto hasta que sepas más sobre su significado y sobre su utilidad para ti.", effects = {} },
        },
    },
    {
        id = "miembro_organizacion", name = "Miembro de organizacion", source = "Warcraft",
        aliases = { "miembro de organizacion", "miembro_de_organizaci_n" },
        desc = "Muchas organizaciones activas en Azeroth y más allá no se ven limitadas por las fronteras nacionales. Estas facciones siguen sus propias prioridades, ajenas a los reinos y gobiernos, y sus miembros actúan cuando la causa lo requiere. Se cuentan entre sus filas fisgones, contrabandistas, mercenarios, alquimistas, chismosos, custodios de archivos arcanos, guardianes de santuarios, vigilantes del Vacío, portadores de la Luz y emisarios sombríos. En el corazón de cada facción hay quienes no solo cumplen con una tarea específica, sino que son su cerebro y su alma.\n\nComo preámbulo de tu carrera como aventurero (o para prepararla), fuiste un agente de una facción específica del mundo. Podrías haber trabajado en público o en secreto, dependiendo de la organización y sus objetivos, así como del grado en que sus ideales coincidieran con los tuyos. Convertirte en aventurero no significa necesariamente que hayas abandonado tu lealtad a la facción (si es que podías hacerlo), y puede que sigas en contacto con ella o incluso que hayas ascendido en su jerarquía.",
        traits = {
            { id = "bg_org_perspicacia", icon = "inv_scroll_11", name = "Perspicacia", type = "pasivo", description = "Competencia en Perspicacia.", effects = { Skill("Perspicacia") } },
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
            { id = "bg_org_refugio", icon = "w3reforgedtownhall", name = "Refugio", type = "pasivo", description = "Como agente de una facción posees acceso a una red secreta de simpatizantes y agentes que pueden ofrecerte ayuda en tus aventuras. Conoces un conjunto de señales y contraseñas secretas que puedes usar para identificar al tipo de agentes que te pueden proveer de acceso a un refugio secreto, de alojamiento y comida, o de ayuda para encontrar información. Estos agentes nunca ponen en peligro sus vidas por ti o se arriesgan a revelar sus identidades reales.", effects = {} },
        },
    },
    {
        id = "miembro_anillo_tierra", name = "Miembro del Anillo de la Tierra", source = "Warcraft",
        aliases = { "anillo de la tierra", "miembro del anillo de la tierra" },
        desc = "Como miembro reverenciado del Anillo de la Tierra, canalizas las fuerzas primigenias de los elementos para restaurar el equilibrio en Azeroth. Guiado por antiguas tradiciones y una profunda conexión con la naturaleza, has dominado el arte del chamanismo, canalizando los poderes de la tierra, el aire, el fuego y el agua.\n\nCon una devoción inquebrantable por la sanación, la protección y el dominio elemental, te eriges como un guardián del orden natural, encargado de mantener la armonía entre los elementos y el mundo que moldean.",
        traits = {
            { id = "bg_anillo_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Medicina.", effects = { Skill("Naturaleza"), Skill("Medicina") } },
            { id = "bg_anillo_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "choice", description = "Competencia con kit de herboristeria y un instrumento musical a tu eleccion.", effects = { Tool("Kit de herboristeria") }, choice = { slots = 1, optionsFrom = "instrument" } },
            { id = "bg_anillo_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "informativo", description = "Hablas, lees y escribes Kalimag.", effects = { { kind = "language", language = "Kalimag" } } },
            { id = "bg_anillo_sintonia", icon = "spell_nature_elementalprecision_2", name = "Sintonia elemental", type = "pasivo", description = "Tu profunda conexión con los elementos te otorga una percepción aguda de sus sutiles cambios. Puedes predecir fenómenos naturales inminentes, como tormentas o terremotos, interpretando el comportamiento de los elementos en tu entorno. Además, puedes lanzar augurio como ritual, lo que toma 10 minutos. Solo recibirás una respuesta si los elementos tienen un interés en el resultado de la acción y actuarías conforme a ese interés. Debes completar un descanso largo para volver a lanzar augurio de este modo.", effects = {} },
        },
    },
    {
        id = "miembro_tribal", name = "Miembro tribal", source = "Warcraft",
        aliases = { "tribal" },
        desc = "Naciste y creciste en las tierras de tu tribu. Tu tribu posee un territorio propio. Puede que procedas de uno de los muchos clanes menores de tauren que habitan Kalimdor, o de una de las vastas tribus de los trolls. Tal vez seas miembro de uno de los clanes prominentes. Quizá provengas de una tribu que vive en aislamiento, con poco contacto con el mundo exterior, o de una que comercia activamente con las sociedades civilizadas.",
        traits = {
            { id = "bg_tribal_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Supervivencia.", effects = { Skill("Naturaleza"), Skill("Supervivencia") } },
            { id = "bg_tribal_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "choice", description = "Competencia con una herramienta de artesano y un instrumento musical, a tu eleccion (elige una de cada).", effects = {}, choice = { slots = 2, optionsFrom = "artisanTool" } },
            { id = "bg_tribal_naturaleza", icon = "spell_nature_abolishmagic", name = "Uno con la naturaleza", type = "pasivo", description = "Tienes una familiaridad íntima con la geografía de tu región natal. Sabes dónde encontrar agua, refugio y alimento en un radio de varios kilómetros de tu hogar. También eres hábil encontrando estos recursos fuera de tu región siempre que el clima sea similar al de tu tierra natal.", effects = {} },
        },
    },
    {
        id = "novato_liga_expedicionarios", name = "Novato de la Liga de Expedicionarios", nameF = "Novata de la Liga de Expedicionarios", source = "Warcraft",
        aliases = { "liga de expedicionarios", "novato expedicionarios" },
        desc = "Eres un orgulloso miembro de la renombrada Liga de Expedicionarios, una estimada organización dedicada a descubrir tesoros ocultos, artefactos ancestrales y los misterios del pasado de Azeroth. Con una sed de aventuras y pasión por el conocimiento, has recorrido territorios inexplorados, enfrentado desafíos peligrosos y desentrañado acertijos en tu búsqueda por la verdad.\n\nComo miembro de la Liga de Expedicionarios, encarnas el espíritu de la curiosidad, el coraje y la camaradería, siempre dispuesto a revelar los secretos del mundo y compartirlos con mentes ansiosas por aprender.",
        traits = {
            { id = "bg_liga_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Historia e Investigación.", effects = { Skill("Historia"), Skill("Investigacion") } },
            { id = "bg_liga_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con herramientas de cartografo y una herramienta de artesano.", effects = { Tool("Herramientas de cartografo"), Tool("Herramientas de artesano") } },
            { id = "bg_liga_idioma", icon = "inv_misc_note_05", name = "Idioma", type = "choice", description = "Un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "language" } },
            { id = "bg_liga_pionero", icon = "inv_misc_map02", name = "Pionero audaz", type = "pasivo", description = "Tu amplia experiencia explorando te ha otorgado instintos agudos para orientarte en terrenos desconocidos. No puedes perderte excepto por medios mágicos, y puedes recordar siempre el diseño general de un área que hayas visitado en las últimas 24 horas.\n\nAdemás, tienes ventaja en pruebas de Sabiduría (Percepción) para detectar trampas.", effects = {} },
        },
    },
    {
        id = "operativo_ravenholdt", name = "Operativo de Ravenholdt", nameF = "Operativa de Ravenholdt", source = "Warcraft",
        aliases = { "ravenholdt" },
        desc = "Los miembros del trasfondo Operativo de Ravenholdt son infiltradores expertos y agentes encubiertos dentro de la enigmática organización Ravenholdt. Con talento para el espionaje y el subterfugio, destacan en la obtención de información crítica, la ejecución de misiones sigilosas y el uso de verdades ocultas. Estos operativos navegan con destreza el mundo del secreto, guiados por motivaciones o lealtades propias, manipulando las sombras para cumplir sus objetivos clandestinos.",
        traits = {
            { id = "bg_raven_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Sigilo e Investigación.", effects = { Skill("Sigilo"), Skill("Investigacion") } },
            { id = "bg_raven_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con kit de venenos y kit de disfraces.", effects = { Tool("Kit de venenos"), Tool("Kit de disfraces") } },
            { id = "bg_raven_red", icon = "ability_rogue_honoramongstthieves", name = "Red de sombras", type = "pasivo", description = "Como operativo de Ravenholdt, tienes acceso a una vasta red de espías, informantes y agentes aliados. Puedes usar tus conexiones para obtener información, encontrar refugios seguros o comunicarte con otros miembros de Ravenholdt. Además, tienes ventaja en pruebas de Inteligencia (Investigación) realizadas para obtener información o descubrir secretos en entornos urbanos.", effects = {} },
        },
    },
    {
        id = "protector_cenarion", name = "Protector Cenarion", nameF = "Protectora Cenarion", source = "Warcraft",
        aliases = { "cenarion", "protector cenarion" },
        desc = "Los Protectores Cenarion son guardianes dedicados de la naturaleza, unidos por una conexión inquebrantable con el mundo natural y un solemne deber de preservar su equilibrio. Con una profunda reverencia por lo salvaje, poseen una afinidad innata por la sanación y el dominio sobre plantas y animales. Estos protectores obtienen su fuerza de su inquebrantable compromiso con la protección del entorno, y a menudo se internan en las tierras más indómitas para defenderse de amenazas y nutrir la armonía de los ecosistemas de Azeroth.",
        traits = {
            { id = "bg_cen_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Naturaleza y Medicina.", effects = { Skill("Naturaleza"), Skill("Medicina") } },
            { id = "bg_cen_herr", icon = "inv_scroll_11", name = "Competencia con herramientas", type = "pasivo", description = "Competencia con kit de herboristeria y una herramienta artesanal.", effects = { Tool("Kit de herboristeria"), Tool("Herramientas de artesano") } },
            { id = "bg_cen_guardian", icon = "spell_nature_natureguardian", name = "Guardian de la naturaleza", type = "pasivo", description = "Cuando estés en un entorno natural o en lo salvaje, tu grupo no puede perderse excepto por medios mágicos. También puedes intentar una prueba de Inteligencia (Naturaleza) con CD 13 para determinar si el entorno en un radio de 16,1 km está corrompido, profanado o alterado mágicamente de algún modo.\n\nAdemás, puedes comprender ideas y emociones básicas de los animales, lo que te permite entenderlos hasta cierto punto.", effects = {} },
        },
    },
    {
        id = "superviviente_catastrofe", name = "Superviviente de catastrofe", source = "Warcraft",
        aliases = { "superviviente de catastrofe", "superviviente_de_cat_strofe", "catastrofe" },
        desc = "Has vivido una de las grandes calamidades de Azeroth —ya sea la invasión de la Plaga, el regreso de la Legión Ardiente, el Cataclismo, o la brutal Cuarta Guerra. Estos eventos transformaron el mundo… y también te transformaron a ti.\n\nLlevas cicatrices que nunca sanaron del todo. Ya sea que defendieras la Costa Quebrada, presenciaras el incendio de Teldrassil, sobrevivieras a la caída de Lordaeron o vieras a Alamuerte desgarrar el cielo, sabes de lo que este mundo es realmente capaz. Los horrores de aquella era te endurecieron… pero también te enseñaron a resistir.",
        traits = {
            { id = "bg_cat_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Historia e Intimidación.", effects = { Skill("Historia"), Skill("Intimidacion") } },
            { id = "bg_cat_herr", name = "Competencia con herramientas", type = "choice", description = "Elige un juego o kit de herboristeria.", choice = { slots = 1, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "herboristeria", label = "Kit de herboristeria", effects = { Tool("Kit de herboristeria") } },
            } }, effects = {} },
            { id = "bg_cat_marcado", icon = "achievement_zone_cataclysmgreen", name = "Marcado pero en pie", type = "pasivo", description = "Has visto lo que la mayoría no puede ni imaginar... y has sobrevivido. Cuando hablas sobre invasiones pasadas o catástrofes, tu testimonio es recibido con respeto por soldados, historiadores y otros supervivientes. Puedes identificar símbolos, tácticas o signos de amenazas mayores como la Legión Ardiente, la Plaga o los Dioses Antiguos. Además, una vez por descanso largo, puedes tener ventaja en una tirada de salvación contra el miedo, encantamiento o posesión causada por un demonio, no-muerto o abominación.", effects = {} },
        },
    },
    {
        id = "rostro_olvidado", name = "Rostro olvidado", source = "Harford", icon = "ability_rogue_disguise",
        desc = "En un mundo donde el pasado nunca muere del todo, tu lo mataste primero. Fingiste tu muerte para escapar de la justicia y ahora vives con un nuevo nombre y un nuevo rostro, aunque el eco de tus pecados todavía te sigue.",
        traits = {
            { id = "bg_rostro_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Sigilo.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_rostro_sombras", icon = "spell_rogue_shadow_reflection", name = "Vida entre sombras", type = "pasivo", description = "Has perfeccionado el arte de vivir sin dejar rastro. Puedes crear identidades falsas con facilidad y sabes como manipular registros, sellos y lenguaje corporal para mantener una fachada convincente. Puedes gastar una hora y 5 po para establecer una identidad falsa en una localidad, con documentación y contactos creibles. Mientras mantengas esta identidad, ganas ventaja en tiradas de Engaño y Sigilo al interactuar con autoridades o figuras publicas que no conozcan tu verdadero rostro. Una vez por descanso largo, puedes evitar ser reconocido mágicamente, como con localizar criatura o videncia, siempre que estés usando tu identidad falsa. En ciudades o asentamientos, puedes encontrar un contacto útil (informante, falsificador, contrabandista) que te ofrezca información o refugio temporal, a discreción del DM.", effects = {} },
        },
    },
    {
        id = "cazarrecompensas_urbano", name = "Cazarrecompensas urbano", nameF = "Cazarrecompensas urbana", source = "SCAG", icon = "inv_bountyhunting",
        aliases = { "cazarrecompensas", "cazador de recompensas urbano" },
        desc = "Antes de convertirte en aventurero, tu vida ya estaba llena de conflictos y emoción, pues te ganabas el sustento persiguiendo a personas a cambio de dinero. Pero, a diferencia de quienes recogen recompensas, no eres un salvaje que sigue a una presa cruzando la naturaleza. Estás relacionado con un comercio lucrativo en el lugar en el que resides, trabajo que a diario pone a prueba tus habilidades e instintos de supervivencia. Además, no estás solo como lo estaría un cazarrecompensas en la naturaleza. Habitualmente interactúas tanto con la subcultura criminal como con otros cazadores de recompensas y conservas contactos en ambos ambientes que te permiten triunfar.\n\nQuizá seas un cazador de ladrones astuto, que acecha en los tejados para capturar a uno de los muchísimos rateros de la ciudad. Puede que sigas alguien con los oídos abiertos en la calle, un individuo que sabe qué se traen entre manos los gremios de ladrones y las bandas callejeras. O quizá seas un cazarrecompensas con máscara de terciopelo, alguien capaz de infiltrarse en la alta sociedad y los círculos negros para localizar a los criminales que se aprovechan de personas con características o estafadores. La comunidad en la que llevabas a cabo tus negocios tal vez fuera una de las grandes ciudades o un lugar menos poblado. Sirve cualquier lugar lo suficientemente grande como para tener un flujo continuo de presas potenciales.\n\nComo miembro de un grupo de aventureros, quizá descubras que es más complicado servir a tus intereses personales cuando no encajan con los objetivos del resto. Por otra parte, puedes hacer caer a objetivos mucho más imponentes con la ayuda de tus compañeros.",
        traits = {
            { id = "bg_caz_comp", name = "Competencias", type = "choice", description = "Elige dos competencias entre Engaño, Perspicacia, Persuasión y Sigilo.", choice = { slots = 2, options = {
                { id = "engano", label = "Engaño", effects = { { kind = "skillProf", skill = "Engano" } } },
                { id = "perspicacia", label = "Perspicacia", effects = { { kind = "skillProf", skill = "Perspicacia" } } },
                { id = "persuasion", label = "Persuasion", effects = { { kind = "skillProf", skill = "Persuasion" } } },
                { id = "sigilo", icon = "inv_scroll_11", label = "Sigilo", effects = { { kind = "skillProf", skill = "Sigilo" } } },
            } }, effects = {} },
            { id = "bg_caz_herr", name = "Competencia con herramientas", type = "choice", description = "Elige dos conjuntos de herramientas entre un juego, un instrumento musical y herramientas de ladrón.", choice = { slots = 2, options = {
                { id = "her_juego", label = "Juego", effects = { Tool("Un juego") } },
                { id = "her_instrumento", label = "Instrumento musical", effects = { Tool("Instrumento musical") } },
                { id = "her_ladron", label = "Herramientas de ladron", effects = { Tool("Herramientas de ladron") } },
            } }, effects = {} },
            { id = "bg_caz_oidos", icon = "inv_misc_ear_human_01", name = "Oidos atentos", type = "pasivo", description = "Sueles estar en contacto con personas de la clase social en la que se muevan las presas que has elegido. Estos individuos pueden estar asociados con el crimen organizado, pertenecer al pueblo llano o ser miembros de la alta sociedad. Esta conexión se manifiesta en forma de un contacto en cualquier lugar que visites, alguien que te informa sobre las personas y los lugares de la zona.", effects = {} },
        },
    },
    {
        id = "coneja_elemental", name = "Coneja elemental", source = "Harford", icon = "inv_eng_gizmo3",
        desc = "Entre los túneles industriales de Mecandria y el eco vibrante de sus máquinas, desarrollaste un talento único para percibir sonidos que ningún otro gnomo podía captar.",
        traits = {
            { id = "bg_coneja_escucha", icon = "inv_misc_rabbit_ears", name = "Escucha resonante conejil", type = "pasivo", description = "Obtienes ventaja en pruebas de Sabiduría (Percepción) basadas en escuchar. Tienes un comunicador interno de voz que funciona como una radio y te permite escuchar y enviar mensajes a través de el. Puedes detectar sonidos sutiles como engranajes ocultos, mecanismos tensos, relojeria, pasos lejanos, susurros amortiguados y vibraciones metálicas.", effects = {} },
            { id = "bg_coneja_acuajet", icon = "inv_weapon_rifle_33", name = "Acuajet", type = "pasivo", description = "Arma exótica que requiere sintonización por Ellie Bunny. Es un fusil integrador gnómico con varios modos de funcionamiento: funciona como foco arcano y permite lanzar magia curativa o elemental sin componentes materiales. Canon de agua (Curación): permite lanzar conjuros curativos como si tuvieras Hechizo Lejano; si el hechizo tiene alcance de toque, pasa a 9 metros, y si tiene alcance numerico, se duplica. Canon de aire (Proyectil): ataque a distancia (18/60 m), daño 1d4 + Destreza perforante, usando munición improvisada como tuercas, clavos, perdigones o tornillos. Canalizacion elemental: los conjuros elementales pueden describirse como proyectiles canalizados por el arma sin cambios mecánicos.", effects = {} },
        },
    },
    {
        id = "eco_resurreccion", name = "Eco de resurreccion", source = "Harford", icon = "d3_astralpresence",
        aliases = { "eco de resurreccion" },
        desc = "Tras morir y regresar a la vida, quedaste marcado por el umbral entre ambos mundos y percibes a los seres vivos como sombras rodeadas de mana y energías mágicas.",
        traits = {
            { id = "bg_eco_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia.", effects = {
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
            { id = "bg_senda_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Supervivencia y Perspicacia.", effects = {
                { kind = "skillProf", skill = "Supervivencia" }, { kind = "skillProf", skill = "Perspicacia" },
            } },
            { id = "bg_senda_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Viscerálico.", effects = { { kind = "language", language = "Visceralico" } } },
            { id = "bg_senda_lobo_tuerto", icon = "eps_wc3h_direwolfacutesenses", name = "Suerte del lobo tuerto", type = "pasivo", description = "Una vez por descanso largo, cuando realizas una tirada, puedes decidir torcer tu suerte. Hasta tu próximo descanso largo, la primera pifia (1 natural) que saques se trata como un 20 natural, y el primer 20 natural que saques se trata como una pifia (1 natural). Este efecto se aplica a tiradas de ataque, pruebas de habilidad y tiradas de salvación. Una vez que ambos efectos se hayan activado, la suerte vuelve a la normalidad hasta que la vuelvas a torcer.", effects = {} },
        },
    },
    {
        id = "veterano_campo_batalla", name = "Veterano del campo de batalla", nameF = "Veterana del campo de batalla", source = "Warcraft", icon = "inv_banner_03",
        aliases = { "veterano de campo de batalla", "veterano" },
        desc = "Los veteranos del campo de batalla son guerreros endurecidos por la guerra, con amplia experiencia en los feroces conflictos de los campos de batalla más emblemáticos de Azeroth. Estos veteranos poseen una mezcla de adaptabilidad, camaradería y espíritu competitivo que se ha forjado a lo largo de incontables enfrentamientos.\n\nViven la emoción de la victoria, encarnan el honor del campo de batalla y llevan las cicatrices de sus triunfos y derrotas pasadas. Los veteranos inspiran a otros, forjan lazos inquebrantables y persiguen la gloria con determinación, mientras enfrentan sus propios demonios internos nacidos del caos de la guerra.",
        traits = {
            { id = "bg_vet_endurecido", icon = "ability_pvp_hardiness", name = "Endurecido por la guerra", type = "pasivo", description = "Tu vasta experiencia en el fragor del combate ha agudizado tus instintos y habilidades marciales. Si pasas una hora planeando con tu grupo e inspirándolos antes del combate, los miembros del grupo ganan un +1 a las tiradas de iniciativa y 1,5 m (1,5 metros) de velocidad extra en su primer turno del siguiente combate. El grupo debe seguir el plan que idees o se perderán estas bonificaciones y deben usarse en el siguiente combate que enfrenten.", effects = {} },
            { id = "bg_vet_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Atletismo, Percepción.", effects = {} },
        },
    },
    {
        -- Trasfondo propio: su unica fuente es la ficha TRP3 del jugador. De ahi salen la
        -- descripcion y el rasgo; las competencias, herramientas y equipo no estan
        -- declaradas en ninguna parte y por eso no se inventan aqui.
        id = "gladiador_goriano", name = "Gladiador goriano", nameF = "Gladiadora goriana", source = "Harford", icon = "achievement_dungeon_ogreslagmines",
        aliases = { "gladiador goriano", "gladiador de gorgrond", "gladiador" },
        desc = "Fuiste forjado en las arenas del Imperio Goriano, donde los débiles desaparecían bajo la arena y los fuertes vivían un combate más. Entre cadenas, gritos y acero, aprendiste a convertir el miedo en furia y el dolor en disciplina. Los ogros creyeron haberte domesticado; solo lograron enseñarte a sobrevivir. Ahora luchas por tu propia voluntad, y ningún amo volverá a decidir tu destino.",
        traits = {
            { id = "bg_glad_comp", icon = "inv_scroll_11", name = "Competencias", type = "pasivo", description = "Competencia en Acrobacias y Intimidación.", effects = {
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
function API.GetStartingGold(backgroundId, variantId)
    local bgDef = API.GetBackground(backgroundId)
    if not bgDef then return 0 end
    if tonumber(bgDef.startingGold) then return math.max(0, math.floor(tonumber(bgDef.startingGold))) end
    for _, trait in ipairs(API.ResolveTraits(backgroundId, variantId)) do
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
    local id = API.FindBackgroundAndVariantByText(text)
    return id
end

-- Como FindBackgroundIdByText pero reconociendo tambien los nombres de VARIANTE: el About
-- generado titula "Trasfondo Veterano Harford" (solo la variante), y cargarficha debe
-- resolver desde ahi tanto el trasfondo base como la variante. Devuelve bgId, variantId
-- (variantId nil si el texto casa con el trasfondo a secas).
function API.FindBackgroundAndVariantByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil, nil end
    EnsureIndex()
    local bestId, bestVariant, bestLen
    local function Prueba(candidate, bgId, variantId)
        if not candidate then return end
        local normalized = Normalize(candidate)
        if normalized ~= "" and clean:find(normalized, 1, true) then
            local len = #normalized
            -- A misma longitud gana la lectura CON variante: es la interpretacion mas
            -- especifica del texto ("Veterano Harford" es la variante, no un alias del base).
            if not bestLen or len > bestLen
                or (len == bestLen and variantId and not bestVariant) then
                bestId, bestVariant, bestLen = bgId, variantId, len
            end
        end
    end
    for _, bgDef in ipairs(API.BACKGROUNDS) do
        Prueba(bgDef.id, bgDef.id, nil)
        Prueba(bgDef.name, bgDef.id, nil)
        Prueba(bgDef.nameF, bgDef.id, nil)
        for _, alias in ipairs(bgDef.aliases or {}) do Prueba(alias, bgDef.id, nil) end
        for _, variant in ipairs(bgDef.variants or {}) do
            Prueba(variant.name, bgDef.id, variant.id)
            Prueba(variant.nameF, bgDef.id, variant.id)
        end
    end
    return bestId, bestVariant
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

-- Variante con rasgos PROPIOS (Veterano Harford): sus `traits` SUSTITUYEN por completo a los
-- del trasfondo base. Una variante sin traits es narrativa y deja los del base, como siempre.
function API.GetVariant(backgroundId, variantId)
    variantId = tostring(variantId or "")
    if variantId == "" then return nil end
    local bgDef = API.GetBackground(backgroundId)
    for _, variant in ipairs((bgDef and bgDef.variants) or {}) do
        if tostring(variant.id) == variantId then return variant end
    end
    return nil
end

function API.ResolveTraits(backgroundId, variantId)
    local variant = API.GetVariant(backgroundId, variantId)
    if variant and type(variant.traits) == "table" and #variant.traits > 0 then return variant.traits end
    local bgDef = API.GetBackground(backgroundId)
    return (bgDef and bgDef.traits) or {}
end

function API.GetBackgroundTraits(backgroundId, variantId)
    local out = {}
    local bgDef = API.GetBackground(backgroundId)
    if not bgDef then return out end
    for _, trait in ipairs(API.ResolveTraits(backgroundId, variantId)) do
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
        -- Rasgos propios de una VARIANTE (Veterano Harford): tambien se localizan por id.
        for _, variant in ipairs(bgDef.variants or {}) do
            for _, trait in ipairs(variant.traits or {}) do
                if trait.id == traitId then return trait, bgDef end
            end
        end
    end
    return nil
end
