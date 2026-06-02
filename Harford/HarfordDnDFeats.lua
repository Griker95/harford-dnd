-- HarfordDnDFeats: libro hardcodeado de dotes (World of Warcraft D&D 5ª Ed. ES, Cap. 5 Personalizacion).
-- Solo datos + helpers puros. Cada dote es un conjunto de "features" con el mismo
-- formato que clases/razas/trasfondos (id/name/type/description/effects/choice), para
-- reusar el motor de efectos (HarfordDnDFeatureEffects) y la UI de la pestaña Clases.
--
-- Incrementos de caracteristica ("X o Y +1") -> `choice` con opciones explicitas de las
-- caracteristicas permitidas (no optionsFrom, que daria las 6). Fijos -> effects {bonus}.
-- Competencias -> skillProf; pericias -> skillExpertise. Lo demas -> `informativo`.
-- El campo `requires` es texto descriptivo (el DM decide si se cumple); no se valida.
-- Contenido: solo las dotes del manual Warcraft. Las dotes del PHB son ampliacion futura.

HarfordDnDFeats = HarfordDnDFeats or {}

local API = HarfordDnDFeats

-- Atajo para una opcion de incremento de caracteristica de un `choice`.
local function AbilOpt(ability)
    local key = ability:lower()
    return { id = key, label = ability .. " +1", effects = { { kind = "bonus", target = "ability", ability = ability, value = 1 } } }
end

API.FEATS = {
    -- ===== Dotes especiales =====
    {
        id = "mago_de_batalla", name = "Mago de Batalla", requires = "Capacidad de lanzar al menos un conjuro",
        traits = {
            { id = "feat_mb_trucos", name = "Trucos de Mago", type = "informativo", description = "Aprendes dos trucos extra de la lista de conjuros de mago.", effects = {} },
            { id = "feat_mb_cercania", name = "Sin Desventaja en Cercania", type = "informativo", description = "Al hacer un ataque de conjuro a distancia, no sufres desventaja por estar a 1.5 m de una criatura hostil.", effects = {} },
            { id = "feat_mb_potente", name = "Conjuro Potente", type = "informativo", description = "Antes de lanzar un conjuro instantaneo de ataque a un solo objetivo, puedes recibir -5 a la tirada; si impacta, +10 al daño del conjuro.", effects = {} },
        },
    },
    {
        id = "experto_armas_fuego", name = "Experto en Armas de Fuego", requires = "",
        traits = {
            { id = "feat_eaf_recarga", name = "Sin Recarga", type = "informativo", description = "Ignoras la propiedad de recarga de las armas de fuego con las que eres competente.", effects = {} },
            { id = "feat_eaf_cercania", name = "Sin Desventaja en Cercania", type = "informativo", description = "Estar a 1.5 m de una criatura hostil no impone desventaja en tus ataques a distancia.", effects = {} },
            { id = "feat_eaf_extra", name = "Disparo Adicional", type = "informativo", description = "Al usar la accion de Ataque con un arma de una mano, puedes usar una accion adicional para atacar con un arma de fuego de una mano cargada que sostengas.", effects = {} },
        },
    },
    {
        id = "adepto_armas_fuego", name = "Adepto en Armas de Fuego", requires = "",
        traits = {
            { id = "feat_adf_inc", name = "Incremento de Caracteristica", type = "choice", description = "Destreza o Inteligencia +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Destreza"), AbilOpt("Inteligencia") } } },
            { id = "feat_adf_armero", name = "Competencia con Herramientas de Armero", type = "informativo", description = "Obtienes competencia con herramientas de armero.", effects = {} },
            { id = "feat_adf_armas", name = "Competencia con Armas de Fuego", type = "informativo", description = "Obtienes competencia con armas de fuego.", effects = {} },
        },
    },
    {
        id = "maestro_armas_exoticas", name = "Maestro en Armas Exoticas", requires = "",
        traits = {
            { id = "feat_mae_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_mae_armas", name = "Armas Exoticas", type = "informativo", description = "Competencia con cuatro armas exoticas de tu eleccion.", effects = {} },
        },
    },
    -- ===== Dotes raciales =====
    {
        id = "teletransporte_arcano", name = "Teletransporte Arcano", requires = "Elfo de sangre, renegado (elfo) o nocheterna",
        traits = {
            { id = "feat_ta_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Carisma") } } },
            { id = "feat_ta_conjuro", name = "Paso Brumoso", type = "informativo", description = "Aprendes paso brumoso y puedes lanzarlo una vez sin gastar espacio; lo recuperas al terminar un descanso corto o largo. Caracteristica de lanzamiento: Inteligencia.", effects = {} },
        },
    },
    {
        id = "mejor_quimica", name = "Mejor Quimica", requires = "Goblin",
        traits = {
            { id = "feat_mq_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
            { id = "feat_mq_alquimista", name = "Suministros de Alquimista", type = "informativo", description = "Competencia con suministros de alquimista; si ya la tienes, duplicas tu bono de competencia con ellos.", effects = {} },
            { id = "feat_mq_pocion", name = "Identificar Pocion", type = "informativo", description = "Como accion, identificas una pocion a 1.5 m como si la hubieras probado (debes ver el liquido).", effects = {} },
            { id = "feat_mq_mejora", name = "Mejorar Pocion", type = "informativo", description = "Durante un descanso corto, con suministros de alquimista mejoras una pocion de curacion: durante 1 h quien la beba recupera el maximo de PG en vez de tirar los dados.", effects = {} },
        },
    },
    {
        id = "amigo_criaturas", name = "Amigo de las Criaturas", requires = "Elfo nocturno",
        traits = {
            { id = "feat_ac_animales", name = "Trato con Animales", type = "pasivo", description = "Competencia en Trato con Animales; si ya eres competente, duplicas tu bono de competencia en ella.", effects = { { kind = "skillProf", skill = "Animales" } } },
            { id = "feat_ac_conjuros", name = "Conjuros de Bestias", type = "informativo", description = "Aprendes hablar con animales (a voluntad, sin espacio) y amistad con los animales (una vez con este dote, recuperado en descanso largo). Caracteristica: Sabiduria.", effects = {} },
        },
    },
    {
        id = "herencia_darnassiana", name = "Herencia Darnassiana", requires = "Elfo nocturno",
        traits = {
            { id = "feat_hd_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia o Sabiduria +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria") } } },
            { id = "feat_hd_sigilo", name = "Sigilo en Penumbra", type = "informativo", description = "Ventaja en pruebas de Destreza (Sigilo) en areas con luz tenue o sin luz.", effects = {} },
            { id = "feat_hd_espiritu", name = "Espiritu Protector", type = "informativo", description = "Al fallar una salvacion contra la muerte, invocas un espiritu para cambiar el dado a exito; no puedes repetirlo hasta pasar dos descansos largos.", effects = {} },
        },
    },
    {
        id = "fortaleza_enana", name = "Fortaleza Enana", requires = "Enano",
        traits = {
            { id = "feat_fe_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "feat_fe_esquivar", name = "Esquivar y Curar", type = "informativo", description = "Al tomar la accion de Esquivar, puedes gastar un dado de golpe para curarte (tirada + Mod. Constitucion, minimo 1).", effects = {} },
        },
    },
    {
        id = "precision_elfica", name = "Precision Elfica", requires = "Cualquier elfo o renegado (elfo)",
        traits = {
            { id = "feat_pe_inc", name = "Incremento de Caracteristica", type = "choice", description = "Destreza, Inteligencia, Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Destreza"), AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_pe_reroll", name = "Precision", type = "informativo", description = "Con ventaja en un ataque de Destreza, Inteligencia, Sabiduria o Carisma, puedes volver a tirar uno de los dados una vez.", effects = {} },
        },
    },
    {
        id = "abrazo_vacio", name = "Abrazo del Vacio", requires = "Elfo del Vacio",
        traits = {
            { id = "feat_av_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia, Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_av_reroll", name = "Daño Necrotico", type = "informativo", description = "Al tirar daño necrotico de un conjuro tuyo, puedes volver a tirar los 1 (usas el nuevo resultado, aunque sea otro 1).", effects = {} },
            { id = "feat_av_aura", name = "Aura del Vacio", type = "informativo", description = "Al lanzar un conjuro de daño necrotico, el vacio te envuelve hasta el fin de tu proximo turno: reduce la luz cercana y daña 1d4 a quien te golpee cuerpo a cuerpo a 1.5 m.", effects = {} },
        },
    },
    {
        id = "rencor_faccion", name = "Rencor de Faccion", requires = "Cualquier raza",
        traits = {
            { id = "feat_rf_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza, Constitucion o Sabiduria +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion"), AbilOpt("Sabiduria") } } },
            { id = "feat_rf_enemigos", name = "Enemigos Jurados", type = "informativo", description = "Elige dos razas de la faccion opuesta. En el primer asalto de combate, tus ataques contra ellas tienen ventaja.", effects = {} },
            { id = "feat_rf_oportunidad", name = "Reflejos contra Enemigos", type = "informativo", description = "Cuando un enemigo elegido hace un ataque de oportunidad contra ti, lo hace con desventaja.", effects = {} },
            { id = "feat_rf_conocimiento", name = "Conocimiento del Enemigo", type = "informativo", description = "En pruebas de Inteligencia (Arcano, Historia, Naturaleza o Religion) sobre tus enemigos elegidos, sumas el doble de tu bono de competencia, aunque no seas competente.", effects = {} },
        },
    },
    {
        id = "depredador_endurecido", name = "Depredador Endurecido", requires = "Huargen",
        traits = {
            { id = "feat_de_olfato", name = "Olfato Agudo", type = "informativo", description = "Ventaja en pruebas de Sabiduria (Percepcion) que dependan del olfato.", effects = {} },
            { id = "feat_de_correr", name = "Carrera a Cuatro Patas", type = "informativo", description = "Con ambas manos vacias, puedes Correr como accion adicional, desplazandote a cuatro patas.", effects = {} },
            { id = "feat_de_garras", name = "Garras", type = "informativo", description = "Tus garras son armas naturales: golpe desarmado que inflige 1d4 + Mod. Fuerza cortante.", effects = {} },
            { id = "feat_de_mordisco", name = "Mordisco y Garras", type = "informativo", description = "Si haces un ataque de mordisco como accion, puedes usar tu accion adicional para atacar con las garras.", effects = {} },
        },
    },
    {
        id = "furia_orca", name = "Furia Orca", requires = "Orco",
        traits = {
            { id = "feat_fo_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Constitucion +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion") } } },
            { id = "feat_fo_dado", name = "Golpe Furioso", type = "informativo", description = "Al golpear con un arma simple o marcial, tiras un dado de daño del arma extra (mismo tipo). 1 uso por descanso corto o largo.", effects = {} },
            { id = "feat_fo_reaccion", name = "Furia Implacable", type = "informativo", description = "Justo despues de usar Resistencia Implacable, puedes hacer un ataque con arma como reaccion.", effects = {} },
        },
    },
    {
        id = "prodigio", name = "Prodigio", requires = "Renegado (humano) o humano",
        traits = {
            { id = "feat_pr_competencia", name = "Competencia en Habilidad", type = "choice", description = "Competencia en una habilidad de tu eleccion.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            { id = "feat_pr_extra", name = "Herramienta e Idioma", type = "informativo", description = "Competencia en una herramienta de tu eleccion y fluidez en un idioma de tu eleccion.", effects = {} },
            { id = "feat_pr_pericia", name = "Pericia", type = "choice", description = "Pericia en una habilidad en la que ya tengas competencia (que no se beneficie ya de otra pericia).", effects = {}, choice = { slots = 1, optionsFrom = "skillExpertise" } },
        },
    },
    {
        id = "guia_espiritual", name = "Guia Espiritual", requires = "Enano (Martillo Salvaje), orco, tauren o trol",
        traits = {
            { id = "feat_ge_inc", name = "Incremento de Caracteristica", type = "choice", description = "Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_ge_miedo", name = "Valor Espiritual", type = "informativo", description = "Ventaja en tiradas de salvacion contra el miedo.", effects = {} },
            { id = "feat_ge_conjuro", name = "Espiritu Sanador", type = "informativo", description = "Aprendes espiritu sanador y puedes lanzarlo una vez con este dote, recuperado en descanso largo. Caracteristica: Sabiduria.", effects = {} },
        },
    },
    {
        id = "agilidad_robusta", name = "Agilidad Robusta", requires = "Enano, gnomo o goblin",
        traits = {
            { id = "feat_ar_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_ar_velocidad", name = "Velocidad", type = "informativo", description = "Tu velocidad aumenta en 1.5 metros.", effects = {} },
            { id = "feat_ar_competencia", name = "Acrobacias o Atletismo", type = "choice", description = "Competencia en Acrobacias o Atletismo (tu eleccion).", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "acrobacias", label = "Acrobacias", effects = { { kind = "skillProf", skill = "Acrobacias" } } },
                    { id = "atletismo",  label = "Atletismo",  effects = { { kind = "skillProf", skill = "Atletismo" } } },
                },
            } },
            { id = "feat_ar_agarre", name = "Escapar de Agarres", type = "informativo", description = "Ventaja en pruebas de Fuerza (Atletismo) o Destreza (Acrobacias) para escapar de un agarre.", effects = {} },
        },
    },
    {
        id = "resistencia_tauren", name = "Resistencia Tauren", requires = "Tauren",
        traits = {
            { id = "feat_rt_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza, Destreza o Constitucion +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza"), AbilOpt("Constitucion") } } },
            { id = "feat_rt_piel", name = "Piel Gruesa", type = "informativo", description = "Sin armadura, tu CA = 10 + Mod. Destreza + Mod. Constitucion. Puedes usar escudo y mantener este beneficio.", effects = {} },
            { id = "feat_rt_pg", name = "Vitalidad Tauren", type = "informativo", description = "Tus PG maximos aumentan en tu nivel al adquirir el dote y en +1 por cada nivel posterior.", effects = {} },
        },
    },
    -- ===== Dotes del Manual del Jugador (PHB 5e ES) =====
    {
        id = "acechador", name = "Acechador", requires = "Destreza 13 o mas", source = "PHB",
        traits = {
            { id = "feat_phb_acechador", name = "Beneficios", type = "informativo", description = "Puedes esconderte si solo estas ligeramente oscurecido para la criatura. Fallar un ataque a distancia estando escondido no revela tu posicion. La luz tenue no te da desventaja en Percepcion (vista).", effects = {} },
        },
    },
    {
        id = "actor", name = "Actor", source = "PHB",
        traits = {
            { id = "feat_phb_actor_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Carisma +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
            { id = "feat_phb_actor_b", name = "Beneficios", type = "informativo", description = "Ventaja en Engaño e Interpretacion para hacerte pasar por otra persona. Puedes imitar voces y sonidos oidos al menos 1 minuto.", effects = {} },
        },
    },
    {
        id = "afortunado", name = "Afortunado", source = "PHB",
        traits = {
            { id = "feat_phb_afortunado", name = "Suerte", type = "informativo", description = "Tienes 3 puntos de suerte. Gastas 1 para tirar un d20 extra en un ataque/prueba/salvacion (tuyo o contra ti) y elegir el resultado. Recargan en descanso largo.", effects = {} },
        },
    },
    {
        id = "alerta", name = "Alerta", source = "PHB",
        traits = {
            { id = "feat_phb_alerta_ini", name = "Iniciativa", type = "pasivo", description = "+5 a la iniciativa.", effects = { { kind = "bonus", target = "initiative", value = 5 } } },
            { id = "feat_phb_alerta_b", name = "Beneficios", type = "informativo", description = "Consciente, no puedes ser sorprendido; las criaturas que no ves no obtienen ventaja al atacarte por ello.", effects = {} },
        },
    },
    {
        id = "apresador", name = "Apresador", requires = "Fuerza 13 o mas", source = "PHB",
        traits = {
            { id = "feat_phb_apresador", name = "Beneficios", type = "informativo", description = "Ventaja en ataques contra criaturas que estes agarrando. Con una accion puedes someter a un agarrado: ambos quedais apresados si tienes exito.", effects = {} },
        },
    },
    {
        id = "atacante_carga", name = "Atacante a la Carga", source = "PHB",
        traits = {
            { id = "feat_phb_carga", name = "Beneficios", type = "informativo", description = "Al usar la accion de Correr puedes usar accion adicional para un ataque cuerpo a cuerpo o empujar. Si te moviste 3 m en linea recta antes, +5 al daño o empujas 3 m.", effects = {} },
        },
    },
    {
        id = "atacante_salvaje", name = "Atacante Salvaje", source = "PHB",
        traits = {
            { id = "feat_phb_salvaje", name = "Beneficios", type = "informativo", description = "Una vez por turno, al tirar el daño de un ataque cuerpo a cuerpo con arma, puedes repetir los dados de daño y usar el resultado que prefieras.", effects = {} },
        },
    },
    {
        id = "atleta", name = "Atleta", source = "PHB",
        traits = {
            { id = "feat_phb_atleta_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_atleta_b", name = "Beneficios", type = "informativo", description = "Levantarte derribado cuesta solo 1,5 m. Trepar no cuesta movimiento extra. Saltas con carrerilla tras moverte solo 1,5 m.", effects = {} },
        },
    },
    {
        id = "azote_magos", name = "Azote de Magos", source = "PHB",
        traits = {
            { id = "feat_phb_azote", name = "Beneficios", type = "informativo", description = "Reaccion para atacar cuerpo a cuerpo a quien lance un conjuro a 1,5 m. Si lo dañas mientras se concentra, tiene desventaja en la salvacion de concentracion. Ventaja en salvaciones contra conjuros lanzados a 1,5 m.", effects = {} },
        },
    },
    {
        id = "centinela", name = "Centinela", source = "PHB",
        traits = {
            { id = "feat_phb_centinela", name = "Beneficios", type = "informativo", description = "Al impactar con un ataque de oportunidad, la velocidad del objetivo baja a 0 ese turno. Atacas de oportunidad aunque el enemigo se Destrabe. Reaccion para atacar a quien ataque a un aliado a 1,5 m de ti.", effects = {} },
        },
    },
    {
        id = "combatiente_dos_armas", name = "Combatiente con Dos Armas", source = "PHB",
        traits = {
            { id = "feat_phb_2armas", name = "Beneficios", type = "informativo", description = "+1 CA empuñando un arma cuerpo a cuerpo en cada mano. Puedes combatir con dos armas aunque no sean ligeras. Envainas/desenvainas dos armas a una mano a la vez.", effects = {} },
        },
    },
    {
        id = "combatiente_montado", name = "Combatiente Montado", source = "PHB",
        traits = {
            { id = "feat_phb_montado", name = "Beneficios", type = "informativo", description = "Montado y no incapacitado: ventaja en ataques cuerpo a cuerpo contra criaturas no montadas de tamaño menor que tu montura; rediriges a ti ataques contra tu montura; tu montura no recibe daño si supera una salvacion de Destreza por mitad.", effects = {} },
        },
    },
    {
        id = "duelista_defensivo", name = "Duelista Defensivo", requires = "Destreza 13 o mas", source = "PHB",
        traits = {
            { id = "feat_phb_duelista", name = "Beneficios", type = "informativo", description = "Empuñando un arma sutil con la que seas competente, al recibir un ataque cuerpo a cuerpo puedes usar tu reaccion para sumar tu bono de competencia a la CA contra ese ataque.", effects = {} },
        },
    },
    {
        id = "duro", name = "Duro", source = "PHB",
        traits = {
            { id = "feat_phb_duro", name = "Beneficios", type = "informativo", description = "Tus PG maximos aumentan en 2x tu nivel al adquirir el dote, y +2 por cada nivel posterior.", effects = {} },
        },
    },
    {
        id = "experto_ballestas", name = "Experto en Ballestas", source = "PHB",
        traits = {
            { id = "feat_phb_ballestas", name = "Beneficios", type = "informativo", description = "Ignoras la recarga de ballestas con las que eres competente. Estar a 1,5 m de un enemigo no da desventaja a tus ataques a distancia. Al atacar con un arma a una mano, accion adicional para atacar con ballesta de mano.", effects = {} },
        },
    },
    {
        id = "explorador_mazmorras", name = "Explorador de Mazmorras", source = "PHB",
        traits = {
            { id = "feat_phb_mazmorras", name = "Beneficios", type = "informativo", description = "Ventaja en Percepcion e Investigacion para detectar puertas secretas y en salvaciones contra trampas. Resistencia al daño de trampas. Buscas trampas a ritmo normal.", effects = {} },
        },
    },
    {
        id = "habilidoso", name = "Habilidoso", source = "PHB",
        traits = {
            { id = "feat_phb_habilidoso", name = "Competencias", type = "choice", description = "Competencia en tres habilidades o herramientas de tu eleccion.", effects = {}, choice = { slots = 3, optionsFrom = "skillProf" } },
        },
    },
    {
        id = "iniciado_magia", name = "Iniciado en la Magia", source = "PHB",
        traits = {
            { id = "feat_phb_iniciado", name = "Beneficios", type = "informativo", description = "Elige una clase lanzadora: aprendes dos trucos de su lista y un conjuro de nivel 1 (lanzable 1 vez por descanso largo con este dote). La aptitud magica depende de la clase elegida.", effects = {} },
        },
    },
    {
        id = "lanzador_combate", name = "Lanzador en Combate", requires = "Capacidad de lanzar al menos un conjuro", source = "PHB",
        traits = {
            { id = "feat_phb_lcombate", name = "Beneficios", type = "informativo", description = "Ventaja en salvaciones de Constitucion para mantener concentracion al recibir daño. Ejecutas componentes somaticos con las manos ocupadas por armas/escudo. Reaccion para lanzar un conjuro (1 accion, 1 objetivo) en lugar de un ataque de oportunidad.", effects = {} },
        },
    },
    {
        id = "lanzador_preciso", name = "Lanzador Preciso", requires = "Capacidad de lanzar al menos un conjuro", source = "PHB",
        traits = {
            { id = "feat_phb_lpreciso", name = "Beneficios", type = "informativo", description = "Al lanzar un conjuro con tirada de ataque, su alcance se duplica. Tus ataques de conjuro a distancia ignoran cobertura media y tres cuartos. Aprendes un truco con tirada de ataque.", effects = {} },
        },
    },
    {
        id = "lanzador_ritual", name = "Lanzador Ritual", requires = "Inteligencia o Sabiduria 13 o mas", source = "PHB",
        traits = {
            { id = "feat_phb_lritual", name = "Beneficios", type = "informativo", description = "Obtienes un libro de rituales con dos conjuros de nivel 1 con etiqueta ritual de una clase a elegir. Puedes copiar al libro otros conjuros rituales que encuentres.", effects = {} },
        },
    },
    {
        id = "lider_inspirador", name = "Lider Inspirador", requires = "Carisma 13 o mas", source = "PHB",
        traits = {
            { id = "feat_phb_lider", name = "Beneficios", type = "informativo", description = "Tras 10 minutos, hasta seis criaturas (incluido tu) a 9 m que te vean u oigan reciben PG temporales = tu nivel + Mod. Carisma. No se repite hasta un descanso.", effects = {} },
        },
    },
    {
        id = "ligeramente_acorazado", name = "Ligeramente Acorazado", source = "PHB",
        traits = {
            { id = "feat_phb_lacor_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_lacor_b", name = "Beneficios", type = "informativo", description = "Competencia con armaduras ligeras.", effects = {} },
        },
    },
    {
        id = "linguista", name = "Linguista", source = "PHB",
        traits = {
            { id = "feat_phb_ling_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
            { id = "feat_phb_ling_b", name = "Beneficios", type = "informativo", description = "Aprendes tres idiomas. Puedes crear codigos cifrados para tus mensajes escritos.", effects = {} },
        },
    },
    {
        id = "maestro_armas", name = "Maestro de Armas", source = "PHB",
        traits = {
            { id = "feat_phb_marmas_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_marmas_b", name = "Beneficios", type = "informativo", description = "Competencia con cuatro armas a tu eleccion (sencillas o marciales).", effects = {} },
        },
    },
    {
        id = "maestro_armaduras_medias", name = "Maestro en Armaduras Medias", requires = "Competente con armaduras medias", source = "PHB",
        traits = {
            { id = "feat_phb_amedias", name = "Beneficios", type = "informativo", description = "La armadura media no te da desventaja en Sigilo. Con Destreza 16+ sumas 3 (en vez de 2) a la CA con armadura media.", effects = {} },
        },
    },
    {
        id = "maestro_armaduras_pesadas", name = "Maestro en Armaduras Pesadas", requires = "Competencia con armaduras pesadas", source = "PHB",
        traits = {
            { id = "feat_phb_apes_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
            { id = "feat_phb_apes_b", name = "Beneficios", type = "informativo", description = "Con armadura pesada, el daño contundente/cortante/perforante de armas no magicas que recibes se reduce en 3.", effects = {} },
        },
    },
    {
        id = "maestro_armas_asta", name = "Maestro en Armas de Asta", source = "PHB",
        traits = {
            { id = "feat_phb_asta", name = "Beneficios", type = "informativo", description = "Con alabarda, baston o guja, accion adicional para un ataque con el extremo opuesto (d4 contundente). Atacas de oportunidad a quien entre en el alcance de alabarda/baston/guja/pica.", effects = {} },
        },
    },
    {
        id = "maestro_armas_pesadas", name = "Maestro en Armas Pesadas", source = "PHB",
        traits = {
            { id = "feat_phb_apesadas", name = "Beneficios", type = "informativo", description = "Una vez por turno, con un critico o al reducir a 0 PG con arma cuerpo a cuerpo, accion adicional para otro ataque cuerpo a cuerpo. Con arma pesada competente puedes -5 al ataque por +10 al daño.", effects = {} },
        },
    },
    {
        id = "maestro_escudos", name = "Maestro en Escudos", source = "PHB",
        traits = {
            { id = "feat_phb_escudos", name = "Beneficios", type = "informativo", description = "Con escudo: al usar la accion de Atacar, accion adicional para empujar con el escudo a 1,5 m. Sumas el bono de CA del escudo a salvaciones de Destreza que solo te afecten a ti; con reaccion puedes anular el daño si superas la salvacion.", effects = {} },
        },
    },
    {
        id = "maton_taberna", name = "Maton de Taberna", source = "PHB",
        traits = {
            { id = "feat_phb_maton_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Constitucion +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion") } } },
            { id = "feat_phb_maton_b", name = "Beneficios", type = "informativo", description = "Competente con armas improvisadas. Tus ataques sin armas infligen 1d4. Al impactar con golpe desarmado o arma improvisada, accion adicional para agarrar.", effects = {} },
        },
    },
    {
        id = "mente_aguda", name = "Mente Aguda", source = "PHB",
        traits = {
            { id = "feat_phb_mente_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
            { id = "feat_phb_mente_b", name = "Beneficios", type = "informativo", description = "Siempre sabes donde esta el norte y cuanto falta para el amanecer/anochecer. Recuerdas con exactitud todo lo visto u oido el ultimo mes.", effects = {} },
        },
    },
    {
        id = "moderadamente_acorazado", name = "Moderadamente Acorazado", requires = "Competencia con armaduras ligeras", source = "PHB",
        traits = {
            { id = "feat_phb_macor_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_macor_b", name = "Beneficios", type = "informativo", description = "Competencia con armaduras medias y escudos.", effects = {} },
        },
    },
    {
        id = "movil", name = "Movil", source = "PHB",
        traits = {
            { id = "feat_phb_movil", name = "Beneficios", type = "informativo", description = "Tu velocidad aumenta 3 m. Al Correr, el terreno dificil no cuesta movimiento extra ese turno. Tras un ataque cuerpo a cuerpo a una criatura, no provocas ataques de oportunidad de ella ese turno.", effects = {} },
        },
    },
    {
        id = "muy_acorazado", name = "Muy Acorazado", requires = "Competente con armaduras medias", source = "PHB",
        traits = {
            { id = "feat_phb_muyacor_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
            { id = "feat_phb_muyacor_b", name = "Beneficios", type = "informativo", description = "Competencia con armaduras pesadas.", effects = {} },
        },
    },
    {
        id = "observador", name = "Observador", source = "PHB",
        traits = {
            { id = "feat_phb_obs_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia o Sabiduria +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria") } } },
            { id = "feat_phb_obs_b", name = "Beneficios", type = "informativo", description = "Lees los labios de quien hable un idioma que conozcas y veas su boca. +5 a tu Percepcion e Investigacion pasivas.", effects = {} },
        },
    },
    {
        id = "resiliente", name = "Resiliente", source = "PHB",
        traits = {
            { id = "feat_phb_resiliente", name = "Caracteristica y Salvacion", type = "choice", description = "Una caracteristica +1 (max 20) y competencia en sus salvaciones.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "fuerza",       label = "Fuerza +1 y salvacion",       effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 },       { kind = "saveProf", ability = "Fuerza" } } },
                    { id = "destreza",     label = "Destreza +1 y salvacion",     effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },     { kind = "saveProf", ability = "Destreza" } } },
                    { id = "constitucion", label = "Constitucion +1 y salvacion", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 }, { kind = "saveProf", ability = "Constitucion" } } },
                    { id = "inteligencia", label = "Inteligencia +1 y salvacion", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 }, { kind = "saveProf", ability = "Inteligencia" } } },
                    { id = "sabiduria",    label = "Sabiduria +1 y salvacion",    effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },    { kind = "saveProf", ability = "Sabiduria" } } },
                    { id = "carisma",      label = "Carisma +1 y salvacion",      effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 },      { kind = "saveProf", ability = "Carisma" } } },
                },
            } },
        },
    },
    {
        id = "resistente", name = "Resistente", source = "PHB",
        traits = {
            { id = "feat_phb_resistente_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "feat_phb_resistente_b", name = "Beneficios", type = "informativo", description = "Al tirar un Dado de Golpe para curarte, el minimo que recuperas es 2x tu Mod. Constitucion (minimo 2).", effects = {} },
        },
    },
    {
        id = "sanador", name = "Sanador", source = "PHB",
        traits = {
            { id = "feat_phb_sanador", name = "Beneficios", type = "informativo", description = "Al estabilizar con utiles de sanador, la criatura recupera ademas 1 PG. Como accion, gastas un uso de utiles de sanador para curar 1d6+4 PG mas su numero de Dados de Golpe (1 vez por descanso por criatura).", effects = {} },
        },
    },
    {
        id = "tirador_primera", name = "Tirador de Primera", source = "PHB",
        traits = {
            { id = "feat_phb_tirador", name = "Beneficios", type = "informativo", description = "Sin desventaja a alcance largo. Tus ataques a distancia ignoran cobertura media y tres cuartos. Con arma a distancia competente puedes -5 al ataque por +10 al daño.", effects = {} },
        },
    },
    {
        id = "versado_armas", name = "Versado en las Armas", source = "PHB",
        traits = {
            { id = "feat_phb_versarmas", name = "Beneficios", type = "informativo", description = "Aprendes dos maniobras del Maestro del Combate (guerrero). Ganas un dado de supremacia d6 (o uno mas si ya tienes). Recargan en descanso corto o largo.", effects = {} },
        },
    },
    {
        id = "versado_elemento", name = "Versado en un Elemento", requires = "Capacidad de lanzar al menos un conjuro", source = "PHB",
        traits = {
            { id = "feat_phb_verselem", name = "Beneficios", type = "informativo", description = "Elige un tipo de daño (acido, frio, fuego, relampago o trueno): tus conjuros ignoran la resistencia a ese tipo y puedes contar cualquier 1 en sus dados de daño como 2. Puedes tomar el dote varias veces (tipo distinto).", effects = {} },
        },
    },
    -- ===== Dotes de El Caldero para Todo de Tasha (TCoE 5e ES) =====
    {
        id = "iniciado_artificiero", name = "Iniciado Artificiero", source = "TCoE",
        traits = {
            { id = "feat_tco_artif", name = "Beneficios", type = "informativo", description = "Competencia con un tipo de herramientas de artesano (utilizable como canalizador magico para conjuros con Inteligencia). Aprendes un truco y un conjuro de nivel 1 de la lista de artifice (Inteligencia); el conjuro 1 vez por descanso largo sin espacio.", effects = {} },
        },
    },
    {
        id = "cocinero", name = "Cocinero", source = "TCoE",
        traits = {
            { id = "feat_tco_cocinero_inc", name = "Incremento de Caracteristica", type = "choice", description = "Constitucion o Sabiduria +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Constitucion"), AbilOpt("Sabiduria") } } },
            { id = "feat_tco_cocinero_b", name = "Beneficios", type = "informativo", description = "Competencia con utiles de cocinero. En un descanso corto cocinas comida para 4 + tu bono de competencia (recuperan 1d8 PG extra al gastar Dados de Golpe). Tras un descanso largo preparas golosinas que dan PG temporales.", effects = {} },
        },
    },
    {
        id = "triturador", name = "Triturador", source = "TCoE",
        traits = {
            { id = "feat_tco_trit_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Constitucion +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion") } } },
            { id = "feat_tco_trit_b", name = "Beneficios", type = "informativo", description = "Una vez por turno, al dañar con daño contundente mueves al objetivo 1,5 m. Con un critico contundente, los ataques contra ese objetivo tienen ventaja hasta tu proximo turno.", effects = {} },
        },
    },
    {
        id = "adepto_sobrenatural", name = "Adepto Sobrenatural", requires = "Rasgo Lanzamiento de Conjuros o Magia del Pacto", source = "TCoE",
        traits = {
            { id = "feat_tco_sobren", name = "Beneficios", type = "informativo", description = "Aprendes una Invocacion Sobrenatural de la clase brujo (si tiene requisito, debes cumplirlo como brujo). Puedes cambiarla al subir de nivel.", effects = {} },
        },
    },
    {
        id = "tocado_hadas", name = "Tocado por las Hadas", source = "TCoE",
        traits = {
            { id = "feat_tco_hadas_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia, Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_hadas_b", name = "Beneficios", type = "informativo", description = "Aprendes paso brumoso y un conjuro de nivel 1 de adivinacion o encantamiento; lanzas cada uno 1 vez por descanso largo sin espacio (tambien con espacios). Aptitud magica: la caracteristica aumentada.", effects = {} },
        },
    },
    {
        id = "iniciado_combate", name = "Iniciado en el Combate", requires = "Competencia con un arma marcial", source = "TCoE",
        traits = {
            { id = "feat_tco_inicomb", name = "Beneficios", type = "informativo", description = "Aprendes un Estilo de Combate de la clase guerrero (distinto si ya tienes uno). Puedes cambiarlo al subir de nivel.", effects = {} },
        },
    },
    {
        id = "artillero_dote", name = "Tirador (Armas de Fuego)", source = "TCoE",
        traits = {
            { id = "feat_tco_gunner_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 } } },
            { id = "feat_tco_gunner_b", name = "Beneficios", type = "informativo", description = "Competencia con armas de fuego. Ignoras la propiedad de municion de las armas de fuego. Estar a 1,5 m de un enemigo no da desventaja a tus ataques a distancia.", effects = {} },
        },
    },
    {
        id = "adepto_metamagia", name = "Adepto de la Metamagia", requires = "Rasgo Lanzamiento de Conjuros o Magia del Pacto", source = "TCoE",
        traits = {
            { id = "feat_tco_metamagia", name = "Beneficios", type = "informativo", description = "Aprendes dos opciones de Metamagia de la clase hechicero (cambiables al subir nivel). Obtienes 2 puntos de hechiceria solo para Metamagia, que recargan en descanso largo.", effects = {} },
        },
    },
    {
        id = "perforador", name = "Perforador", source = "TCoE",
        traits = {
            { id = "feat_tco_perf_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_tco_perf_b", name = "Beneficios", type = "informativo", description = "Una vez por turno, al dañar con daño perforante puedes repetir un dado de daño (usas el nuevo). Con un critico perforante, tiras un dado de daño perforante adicional.", effects = {} },
        },
    },
    {
        id = "envenenador", name = "Envenenador", source = "TCoE",
        traits = {
            { id = "feat_tco_envenenador", name = "Beneficios", type = "informativo", description = "Ignoras la resistencia al daño por veneno. Aplicas veneno como accion adicional. Competencia con utiles de envenenador; en 1 hora y 50 po creas dosis de veneno potente (CD 14 Con, 2d8 veneno y envenenado).", effects = {} },
        },
    },
    {
        id = "tocado_sombras", name = "Tocado por las Sombras", source = "TCoE",
        traits = {
            { id = "feat_tco_sombras_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia, Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_sombras_b", name = "Beneficios", type = "informativo", description = "Aprendes invisibilidad y un conjuro de nivel 1 de ilusion o nigromancia; lanzas cada uno 1 vez por descanso largo sin espacio (tambien con espacios). Aptitud magica: la caracteristica aumentada.", effects = {} },
        },
    },
    {
        id = "experto_habilidades", name = "Experto en Habilidades", source = "TCoE",
        traits = {
            { id = "feat_tco_exph_inc", name = "Incremento de Caracteristica", type = "choice", description = "Una caracteristica de tu eleccion +1 (max 20).", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
            { id = "feat_tco_exph_prof", name = "Competencia en Habilidad", type = "choice", description = "Competencia en una habilidad de tu eleccion.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            { id = "feat_tco_exph_exp", name = "Pericia", type = "choice", description = "Pericia en una habilidad en la que ya seas competente (que no tenga ya pericia).", effects = {}, choice = { slots = 1, optionsFrom = "skillExpertise" } },
        },
    },
    {
        id = "cortador", name = "Cortador", source = "TCoE",
        traits = {
            { id = "feat_tco_cort_inc", name = "Incremento de Caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_tco_cort_b", name = "Beneficios", type = "informativo", description = "Una vez por turno, al dañar con daño cortante reduces la velocidad del objetivo en 3 m hasta tu proximo turno. Con un critico cortante, el objetivo tiene desventaja en ataques hasta tu proximo turno.", effects = {} },
        },
    },
    {
        id = "telequinetico", name = "Telequinetico", source = "TCoE",
        traits = {
            { id = "feat_tco_telek_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia, Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_telek_b", name = "Beneficios", type = "informativo", description = "Aprendes mano de mago (sin componentes V/S, mano invisible). Como accion adicional, empujas telequineticamente a una criatura a 9 m (salvacion de Fuerza o movida 1,5 m). Aptitud magica: la caracteristica aumentada.", effects = {} },
        },
    },
    {
        id = "telepata", name = "Telepata", source = "TCoE",
        traits = {
            { id = "feat_tco_telep_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia, Sabiduria o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_telep_b", name = "Beneficios", type = "informativo", description = "Hablas telepaticamente con cualquier criatura a 18 m (en un idioma que conozcas). Lanzas detectar pensamientos 1 vez por descanso largo sin espacio (aptitud: la caracteristica aumentada).", effects = {} },
        },
    },
}

local featById, featOrder

local function EnsureIndex()
    if featById then return end
    featById, featOrder = {}, {}
    for _, featDef in ipairs(API.FEATS) do
        featById[featDef.id] = featDef
        featOrder[#featOrder + 1] = featDef.id
    end
end

function API.GetFeats()
    EnsureIndex()
    return API.FEATS
end

function API.GetFeat(featId)
    EnsureIndex()
    return featById[tostring(featId or "")]
end

function API.GetFeatOrder()
    EnsureIndex()
    return featOrder
end

function API.GetFeatName(featId)
    local featDef = API.GetFeat(featId)
    return featDef and featDef.name or tostring(featId or "")
end

-- Devuelve los rasgos de una lista de dotes (ids) en el MISMO formato que
-- HarfordDnDBook.GetUnlockedFeatures: { { className, level=0, feature }, ... }.
function API.GetFeatTraits(featIds)
    local out = {}
    if type(featIds) ~= "table" then return out end
    for _, featId in ipairs(featIds) do
        local featDef = API.GetFeat(featId)
        if featDef then
            for _, trait in ipairs(featDef.traits or {}) do
                out[#out + 1] = { className = "Dote: " .. featDef.name, level = 0, feature = trait }
            end
        end
    end
    return out
end

function API.GetTrait(traitId)
    traitId = tostring(traitId or "")
    for _, featDef in ipairs(API.FEATS) do
        for _, trait in ipairs(featDef.traits or {}) do
            if trait.id == traitId then return trait, featDef end
        end
    end
    return nil
end
