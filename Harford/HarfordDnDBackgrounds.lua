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

API.BACKGROUNDS = {
    {
        id = "boticario_oscuro", name = "Boticario Oscuro",
        traits = {
            { id = "bg_bot_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Investigacion.", effects = {
                { kind = "skillProf", skill = "Arcano" },
                { kind = "skillProf", skill = "Investigacion" },
            } },
            { id = "bg_bot_herramientas", name = "Competencia con Herramientas", type = "informativo", description = "Suministros de alquimista y equipo de venenos.", effects = {} },
            { id = "bg_bot_caract", name = "Caracteristica: Agente de la S.R.B.", type = "informativo", description = "Tienes acceso a una red de simpatizantes y operativos bajo el respaldo de Lady Sylvanas. Donde haya Renegados, puedes encontrar Boticarios Oscuros dispuestos a ofrecer refugio, informacion, hierbas o ingredientes alquimicos; a cambio pueden pedirte una o mas tareas.", effects = {} },
            { id = "bg_bot_equipo", name = "Equipo", type = "informativo", description = "Suministros de alquimista o equipo de venenos, un brazalete con frasco y corona bordados, un cuaderno, un conjunto de tunicas de terciopelo negro y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "doble_agente", name = "Doble Agente",
        traits = {
            { id = "bg_dob_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Perspicacia.", effects = {
                { kind = "skillProf", skill = "Engano" },
                { kind = "skillProf", skill = "Perspicacia" },
            } },
            { id = "bg_dob_herramientas", name = "Competencia con Herramientas", type = "informativo", description = "Kit de falsificacion.", effects = {} },
            { id = "bg_dob_idiomas", name = "Idiomas", type = "informativo", description = "Puedes hablar Darnassiano, Draenei, Enano o Gnomico.", effects = {} },
            { id = "bg_dob_caract", name = "Caracteristica: Dos Caras de Una Moneda", type = "informativo", description = "Tienes contactos en ambas organizaciones a las que proporcionas informacion. Suelen permitirte cometer delitos menores sin temor a castigo o manejar un negocio sin pagar todos los impuestos, y puedes obtener audiencias con funcionarios de ambas.", effects = {} },
            { id = "bg_dob_equipo", name = "Equipo", type = "informativo", description = "Kit de falsificacion, daga, dos piezas de tiza, 4 hojas de pergamino, una botella de tinta, una pluma, un conjunto de ropa de viajero y una bolsa de cinturon con 15 po.", effects = {} },
        },
    },
    {
        id = "crianza_faccion", name = "Crianza en la Faccion",
        traits = {
            { id = "bg_cri_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Percepcion.", effects = {
                { kind = "skillProf", skill = "Historia" },
                { kind = "skillProf", skill = "Percepcion" },
            } },
            { id = "bg_cri_idiomas", name = "Idiomas", type = "informativo", description = "Puedes hablar Darnassiano, Draenei, Enano o Gnomico.", effects = {} },
            { id = "bg_cri_caract", name = "Caracteristica: Lealtad Falsa", type = "informativo", description = "Tu raza y apariencia te permiten ingresar y pasar desapercibido en aldeas y ciudades de ambas facciones; aunque recibas miradas, nadie te detendra ni interrogara, ni levantara armas contra ti.", effects = {} },
            { id = "bg_cri_equipo", name = "Equipo", type = "informativo", description = "Un conjunto de ropa comun, capa con capucha, un amuleto de tu faccion, un libro, una botella de tinta, una pluma y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "aprendiz_kirin_tor", name = "Aprendiz del Kirin Tor",
        traits = {
            { id = "bg_kir_competencias", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia.", effects = {
                { kind = "skillProf", skill = "Arcano" },
                { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_kir_herramientas", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de herramientas de artesano.", effects = {} },
            { id = "bg_kir_idiomas", name = "Idiomas", type = "informativo", description = "Un idioma de tu eleccion.", effects = {} },
            { id = "bg_kir_caract", name = "Caracteristica: Mentor Prominente", type = "informativo", description = "Conoces a un mago prominente del Kirin Tor al que puedes recurrir en busca de respuestas e informacion. A discrecion del DM, la informacion del mentor puede ser falsa, incompleta o tardia.", effects = {} },
            { id = "bg_kir_equipo", name = "Equipo", type = "informativo", description = "Una botella de tinta de alta calidad, una pluma, tiza, un estuche para pergaminos con 5 hojas, tunicas, una vela, caja de yesca y una bolsa con 15 po.", effects = {} },
        },
    },
    -- ===== Trasfondos del Manual del Jugador (PHB 5e ES) =====
    {
        id = "acolito", name = "Acolito", source = "PHB",
        traits = {
            { id = "bg_aco_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Religion.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Religion" },
            } },
            { id = "bg_aco_idiomas", name = "Idiomas", type = "informativo", description = "Dos idiomas de tu eleccion.", effects = {} },
            { id = "bg_aco_caract", name = "Caracteristica: Refugio del Fiel", type = "informativo", description = "Tu y tus companeros podeis recibir sanacion y cuidados gratuitos en templos y lugares consagrados a tu fe (aportando los componentes materiales). Los fieles de tu religion te mantienen con un nivel de vida modesto.", effects = {} },
            { id = "bg_aco_equipo", name = "Equipo", type = "informativo", description = "Simbolo sagrado, devocionario o rueda de oraciones, 5 varas de incienso, vestiduras, ropas comunes y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "animador", name = "Animador", source = "PHB",
        traits = {
            { id = "bg_ani_comp", name = "Competencias", type = "pasivo", description = "Competencia en Acrobacias e Interpretacion.", effects = {
                { kind = "skillProf", skill = "Acrobacias" }, { kind = "skillProf", skill = "Interpretacion" },
            } },
            { id = "bg_ani_herr", name = "Competencia con Herramientas", type = "informativo", description = "Utiles para disfrazarse y un tipo de instrumento musical.", effects = {} },
            { id = "bg_ani_caract", name = "Caracteristica: Por Peticion Popular", type = "informativo", description = "Siempre encuentras un sitio donde actuar (posada, taberna, circo, teatro, corte) y consigues comida y alojamiento modesto o comodo si actuas cada noche. La gente te reconoce alli donde has actuado.", effects = {} },
            { id = "bg_ani_equipo", name = "Equipo", type = "informativo", description = "Instrumento musical, el favor de un admirador, disfraz y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "artesano_gremial", name = "Artesano Gremial", source = "PHB",
        traits = {
            { id = "bg_art_comp", name = "Competencias", type = "pasivo", description = "Competencia en Perspicacia y Persuasion.", effects = {
                { kind = "skillProf", skill = "Perspicacia" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_art_herr", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de herramientas de artesano.", effects = {} },
            { id = "bg_art_idiomas", name = "Idiomas", type = "informativo", description = "Un idioma de tu eleccion.", effects = {} },
            { id = "bg_art_caract", name = "Caracteristica: Miembro de un Gremio", type = "informativo", description = "Tu gremio te da comida y alojamiento si lo necesitas, contactos comerciales y apoyo politico/legal. Debes pagar una cuota mensual de 5 po para mantener los beneficios.", effects = {} },
            { id = "bg_art_equipo", name = "Equipo", type = "informativo", description = "Herramientas de artesano (un tipo), carta de presentacion de tu gremio, ropas de viaje y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "charlatan", name = "Charlatan", source = "PHB",
        traits = {
            { id = "bg_cha_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Juego de Manos.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "JuegoManos" },
            } },
            { id = "bg_cha_herr", name = "Competencia con Herramientas", type = "informativo", description = "Utiles para disfrazarse y utiles para falsificar.", effects = {} },
            { id = "bg_cha_caract", name = "Caracteristica: Identidad Falsa", type = "informativo", description = "Tienes una segunda identidad con documentacion, disfraces y conocidos que responden por ella. Puedes falsificar cualquier documento cuyo formato o caligrafia hayas visto antes.", effects = {} },
            { id = "bg_cha_equipo", name = "Equipo", type = "informativo", description = "Ropas de calidad, utiles para disfrazarse, herramientas de un timo a tu eleccion y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "criminal", name = "Criminal", source = "PHB",
        traits = {
            { id = "bg_cri_comp", name = "Competencias", type = "pasivo", description = "Competencia en Engaño y Sigilo.", effects = {
                { kind = "skillProf", skill = "Engano" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_cri_herr", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de juego y herramientas de ladron.", effects = {} },
            { id = "bg_cri_caract", name = "Caracteristica: Contacto Criminal", type = "informativo", description = "Tienes un contacto de confianza que enlaza con una red de criminales. Sabes enviar y recibir mensajes a traves de mensajeros, caravaneros corruptos y marineros incluso a distancia.", effects = {} },
            { id = "bg_cri_equipo", name = "Equipo", type = "informativo", description = "Palanqueta, ropas oscuras con capucha y una bolsa con 15 po.", effects = {} },
        },
    },
    {
        id = "ermitano", name = "Ermitaño", source = "PHB",
        traits = {
            { id = "bg_erm_comp", name = "Competencias", type = "pasivo", description = "Competencia en Medicina y Religion.", effects = {
                { kind = "skillProf", skill = "Medicina" }, { kind = "skillProf", skill = "Religion" },
            } },
            { id = "bg_erm_herr", name = "Competencia con Herramientas", type = "informativo", description = "Utiles de herborista.", effects = {} },
            { id = "bg_erm_idiomas", name = "Idiomas", type = "informativo", description = "Un idioma de tu eleccion.", effects = {} },
            { id = "bg_erm_caract", name = "Caracteristica: Descubrimiento", type = "informativo", description = "Tu retiro te hizo participe de un descubrimiento unico y poderoso: una gran revelacion sobre el cosmos, un lugar ignoto, un hecho olvidado o una reliquia capaz de reescribir la historia.", effects = {} },
            { id = "bg_erm_equipo", name = "Equipo", type = "informativo", description = "Estuche con notas de tus estudios u oraciones, manta de invierno, ropas comunes, utiles de herborista y 5 po.", effects = {} },
        },
    },
    {
        id = "erudito", name = "Erudito", source = "PHB",
        traits = {
            { id = "bg_eru_comp", name = "Competencias", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia.", effects = {
                { kind = "skillProf", skill = "Arcano" }, { kind = "skillProf", skill = "Historia" },
            } },
            { id = "bg_eru_idiomas", name = "Idiomas", type = "informativo", description = "Dos idiomas de tu eleccion.", effects = {} },
            { id = "bg_eru_caract", name = "Caracteristica: Investigador", type = "informativo", description = "Cuando intentas aprender o recordar algo, aunque no tengas la informacion, sueles saber donde encontrarla o quien puede proporcionartela (biblioteca, universidad, otros eruditos).", effects = {} },
            { id = "bg_eru_equipo", name = "Equipo", type = "informativo", description = "Botella de tinta negra, pluma, cuchillo pequeño, carta de un colega muerto con una pregunta sin responder, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "heroe_pueblo", name = "Heroe del Pueblo", source = "PHB",
        traits = {
            { id = "bg_her_comp", name = "Competencias", type = "pasivo", description = "Competencia en Supervivencia y Trato con Animales.", effects = {
                { kind = "skillProf", skill = "Supervivencia" }, { kind = "skillProf", skill = "Animales" },
            } },
            { id = "bg_her_herr", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de herramientas de artesano y vehiculos terrestres.", effects = {} },
            { id = "bg_her_caract", name = "Caracteristica: Hospitalidad Rural", type = "informativo", description = "Por tu origen humilde te relacionas con facilidad con el pueblo llano, que te ofrece un lugar donde esconderte, descansar o recuperarte, y te oculta de quien te persiga (sin arriesgar sus vidas).", effects = {} },
            { id = "bg_her_equipo", name = "Equipo", type = "informativo", description = "Herramientas de artesano (un tipo), pala, olla de hierro, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "huerfano", name = "Huerfano", source = "PHB",
        traits = {
            { id = "bg_hue_comp", name = "Competencias", type = "pasivo", description = "Competencia en Juego de Manos y Sigilo.", effects = {
                { kind = "skillProf", skill = "JuegoManos" }, { kind = "skillProf", skill = "Sigilo" },
            } },
            { id = "bg_hue_herr", name = "Competencia con Herramientas", type = "informativo", description = "Herramientas de ladron y utiles para disfrazarse.", effects = {} },
            { id = "bg_hue_caract", name = "Caracteristica: Secretos de la Ciudad", type = "informativo", description = "Conoces los pasadizos y patrones secretos de toda ciudad. Fuera de combate, tu y los companeros a los que guies viajais entre dos puntos de una ciudad al doble de velocidad.", effects = {} },
            { id = "bg_hue_equipo", name = "Equipo", type = "informativo", description = "Cuchillo pequeño, mapa de la ciudad en la que creciste, raton mascota, recuerdo de tus padres, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "marinero", name = "Marinero", source = "PHB",
        traits = {
            { id = "bg_mar_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Percepcion.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Percepcion" },
            } },
            { id = "bg_mar_herr", name = "Competencia con Herramientas", type = "informativo", description = "Herramientas de navegante y vehiculos acuaticos.", effects = {} },
            { id = "bg_mar_caract", name = "Caracteristica: Pasaje en un Barco", type = "informativo", description = "Puedes conseguir pasaje gratuito en un velero para ti y tus companeros (a cambio de ayudar a la tripulacion). El DM decide la ruta y el tiempo de viaje.", effects = {} },
            { id = "bg_mar_equipo", name = "Equipo", type = "informativo", description = "Cabilla (garrote), 50 pies de cuerda de seda, amuleto de la suerte, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "noble", name = "Noble", source = "PHB",
        traits = {
            { id = "bg_nob_comp", name = "Competencias", type = "pasivo", description = "Competencia en Historia y Persuasion.", effects = {
                { kind = "skillProf", skill = "Historia" }, { kind = "skillProf", skill = "Persuasion" },
            } },
            { id = "bg_nob_herr", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de juego a tu eleccion.", effects = {} },
            { id = "bg_nob_idiomas", name = "Idiomas", type = "informativo", description = "Un idioma de tu eleccion.", effects = {} },
            { id = "bg_nob_caract", name = "Caracteristica: Posicion de Privilegio", type = "informativo", description = "Por tu alcurnia, la gente piensa lo mejor de ti. Eres bienvenido en la alta sociedad y el pueblo llano evita tu desaprobacion; puedes conseguir audiencia con un noble local.", effects = {} },
            { id = "bg_nob_equipo", name = "Equipo", type = "informativo", description = "Ropas de calidad, anillo de sellar, documento que acredita el linaje y un monedero con 25 po.", effects = {} },
        },
    },
    {
        id = "salvaje", name = "Salvaje", source = "PHB",
        traits = {
            { id = "bg_sal_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo y Supervivencia.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Supervivencia" },
            } },
            { id = "bg_sal_herr", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de instrumento musical.", effects = {} },
            { id = "bg_sal_idiomas", name = "Idiomas", type = "informativo", description = "Un idioma de tu eleccion.", effects = {} },
            { id = "bg_sal_caract", name = "Caracteristica: Vagabundo", type = "informativo", description = "Tienes memoria excelente para geografia y mapas (recuerdas terreno y asentamientos cercanos) y puedes conseguir agua y comida para hasta seis personas al dia en territorio con caza, bayas y agua.", effects = {} },
            { id = "bg_sal_equipo", name = "Equipo", type = "informativo", description = "Baston, trampa para cazar, trofeo de un animal que mataste, ropas de viaje y una bolsa con 10 po.", effects = {} },
        },
    },
    {
        id = "soldado", name = "Soldado", source = "PHB",
        traits = {
            { id = "bg_sol_comp", name = "Competencias", type = "pasivo", description = "Competencia en Atletismo e Intimidacion.", effects = {
                { kind = "skillProf", skill = "Atletismo" }, { kind = "skillProf", skill = "Intimidacion" },
            } },
            { id = "bg_sol_herr", name = "Competencia con Herramientas", type = "informativo", description = "Un tipo de juego y vehiculos terrestres.", effects = {} },
            { id = "bg_sol_caract", name = "Caracteristica: Rango Militar", type = "informativo", description = "Conservas un rango militar: los leales a tu antigua organizacion reconocen tu autoridad, obedecen ordenes de rango inferior y puedes solicitar equipo y caballos temporales o acceder a campamentos y fortalezas.", effects = {} },
            { id = "bg_sol_equipo", name = "Equipo", type = "informativo", description = "Insignia de rango, trofeo de un enemigo muerto, juego de dados o baraja, ropas comunes y una bolsa con 10 po.", effects = {} },
        },
    },
}

local bgById, bgOrder

local function Normalize(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    value = value:gsub("[áàäâÁÀÄÂ]", "a")
    value = value:gsub("[éèëêÉÈËÊ]", "e")
    value = value:gsub("[íìïîÍÌÏÎ]", "i")
    value = value:gsub("[óòöôÓÒÖÔ]", "o")
    value = value:gsub("[úùüûÚÙÜÛ]", "u")
    value = value:gsub("[ñÑ]", "n")
    return value:gsub("^%s+", ""):gsub("%s+$", "")
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

function API.FindBackgroundIdByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil end
    EnsureIndex()
    local bestId, bestLen
    for _, bgDef in ipairs(API.BACKGROUNDS) do
        local candidates = { bgDef.id, bgDef.name }
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
