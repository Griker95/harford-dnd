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
        id = "feat_mago_de_batalla", icon = "inv_shoulders_cloth_raidmage_s_01", requiredCaster = "any", name = "Mago de batalla", requires = "Capacidad de lanzar al menos un conjuro", description = "Magia de combate a quemarropa: más trucos, sin penalización por tener al enemigo encima y la opción de cambiar puntería por potencia.",
        traits = {
            { id = "feat_mb_trucos", icon = "spell_mage_arcaneorb", name = "Trucos de Mago", type = "pasivo", description = "Aprendes dos trucos extra de la lista de conjuros de mago.", effects = {} },
            { id = "feat_mb_cercania", icon = "spell_misc_hellifrepvpcombatmorale", name = "Sin desventaja en cercania", type = "pasivo", description = "Al hacer un ataque de conjuro a distancia, no sufres desventaja por estar a 1,5 m de una criatura hostil.", effects = { { kind = "flag", flag = "ignoreSpellMeleePenalty" } } },
            { id = "feat_mb_potente", icon = "spell_arcane_arcane03", name = "Conjuro potente", type = "pasivo", description = "Antes de lanzar un conjuro instantaneo de ataque a un solo objetivo, puedes recibir -5 a la tirada; si impacta, +10 al daño del conjuro.", effects = {} },
        },
    },
    {
        id = "feat_experto_armas_fuego", icon = "inv_legendary_gun", name = "Experto en armas de fuego", requires = "", description = "Manejo veterano de la pólvora: recargas sin perder el turno, disparas cómodo en corta distancia y encadenas un segundo tiro.",
        traits = {
            { id = "feat_eaf_recarga", icon = "ability_hunter_lockandload", name = "Sin recarga", type = "pasivo", description = "Ignoras la propiedad de recarga de las armas de fuego con las que eres competente.", effects = {} },
            { id = "feat_eaf_cercania", icon = "spell_misc_hellifrepvpcombatmorale", name = "Sin desventaja en cercania", type = "pasivo", description = "Estar a 1,5 m de una criatura hostil no impone desventaja en tus ataques a distancia.", effects = { { kind = "flag", flag = "ignoreRangedMeleePenalty" } } },
            { id = "feat_eaf_extra", icon = "ability_hunter_rapidregeneration", name = "Disparo adicional", type = "pasivo", description = "Al usar la acción de Ataque con un arma de una mano, puedes usar una acción adicional para atacar con un arma de fuego de una mano cargada que sostengas.", effects = {} },
        },
    },
    {
        id = "feat_adepto_armas_fuego", icon = "w3reforgedflaregun", name = "Adepto en armas de fuego", requires = "", description = "Formación básica en armas de fuego, con las herramientas de armero para mantenerlas a punto.",
        traits = {
            { id = "feat_adf_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Destreza o Inteligencia +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Destreza"), AbilOpt("Inteligencia") } } },
            { id = "feat_adf_armero", icon = "inv_scroll_11", name = "Competencia con herramientas de armero", type = "pasivo", description = "Obtienes competencia con herramientas de armero.", effects = { { kind = "toolProf", tool = "Herramientas de armero" } } },
            { id = "feat_adf_armas", icon = "inv_scroll_11", name = "Competencia con armas de fuego", type = "pasivo", description = "Obtienes competencia con armas de fuego.", effects = { { kind = "weaponProf", weapon = "armas de fuego" } } },
        },
    },
    {
        id = "feat_maestro_armas_exoticas", icon = "inv_legendary_sword", name = "Maestro en armas exoticas", requires = "", description = "Adiestramiento en armamento poco común, del que casi nadie sabe sacar partido.",
        traits = {
            { id = "feat_mae_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_mae_armas", icon = "inv_sword_109", name = "Armas exoticas", type = "pasivo", description = "Competencia con cuatro armas exoticas de tu elección.", effects = {} },
        },
    },
    -- ===== Dotes raciales =====
    {
        id = "feat_teletransporte_arcano", icon = "spell_arcane_arcanepotency_nightborne", requiredRaces = { "raza_elfo_sangre", "raza_renegado_elfo", "raza_nocheterna" }, name = "Teletransporte arcano", requires = "Elfo de sangre, renegado (elfo) o nocheterna", description = "Herencia arcana élfica que permite desaparecer y reaparecer unos pasos más allá, una vez entre descansos.",
        traits = {
            { id = "feat_ta_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Carisma") } } },
            { id = "feat_ta_conjuro", icon = "eps_lol_shen_shadowdashold", name = "Paso brumoso", type = "pasivo", description = "Aprendes paso brumoso y puedes lanzarlo una vez sin gastar espacio; lo recuperas al terminar un descanso corto o largo. Característica de lanzamiento: Inteligencia.", effects = {} },
        },
    },
    {
        id = "feat_mejor_quimica", icon = "ability_racial_betterlivingthroughchemistry", requiredRaces = { "raza_goblin" }, name = "Mejor quimica", requires = "Goblin", description = "Instinto goblin para la alquimia: reconoces una poción de un vistazo y sabes sacarle más provecho.",
        traits = {
            { id = "feat_mq_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
            { id = "feat_mq_alquimista", icon = "inv_misc_5potionbag_special", name = "Suministros de alquimista", type = "pasivo", description = "Competencia con suministros de alquimista; si ya la tienes, duplicas Bonus Competencia con ellos.", effects = { { kind = "toolProf", tool = "Suministros de alquimista" } } },
            { id = "feat_mq_pocion", icon = "eps_bg3_identify", name = "Identificar pocion", type = "pasivo", description = "Como acción, identificas una pocion a 1,5 m como si la hubieras probado (debes ver el líquido).", effects = {} },
            { id = "feat_mq_mejora", icon = "eps_hs_bloodfurypotion", name = "Mejorar pocion", type = "pasivo", description = "Durante un descanso corto, con suministros de alquimista mejoras una pocion de curación: durante 1 h quien la beba recupera el maximo de PG en vez de tirar los dados.", effects = {} },
        },
    },
    {
        id = "feat_amigo_criaturas", icon = "eps_lol_ivern_friendoftheforest", requiredRaces = { "raza_elfo_noche" }, name = "Amigo de las criaturas", requires = "Elfo nocturno", description = "Trato natural con las bestias: te entienden, te escuchan y rara vez te ven como una amenaza.",
        traits = {
            { id = "feat_ac_animales", icon = "eps_bg3_speakwithanimals", name = "Trato con Animales", type = "pasivo", description = "Competencia en Trato con Animales; si ya eres competente, duplicas Bonus Competencia en ella.", effects = { { kind = "skillProf", skill = "Animales" } } },
            { id = "feat_ac_conjuros", icon = "ability_druid_mastershapeshifter", name = "Conjuros de bestias", type = "pasivo", description = "Aprendes hablar con animales (a voluntad, sin espacio) y amistad con los animales (una vez con este dote, recuperado en descanso largo). Característica: Sabiduría.", effects = {} },
        },
    },
    {
        id = "feat_herencia_darnassiana", icon = "eps_wc3_nightelfflag", requiredRaces = { "raza_elfo_noche" }, name = "Herencia darnassiana", requires = "Elfo nocturno", description = "El legado de Darnassus: moverte sin ser visto en la penumbra y un espíritu que vela por ti cuando la muerte se acerca.",
        traits = {
            { id = "feat_hd_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia o Sabiduría +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria") } } },
            { id = "feat_hd_sigilo", icon = "ability_racial_shadowmeld", name = "Sigilo en penumbra", type = "pasivo", description = "Ventaja en pruebas de Destreza (Sigilo) en areas con luz tenue o sin luz.", effects = {} },
            { id = "feat_hd_espiritu", icon = "ability_racial_ultravision", name = "Espiritu protector", type = "pasivo", description = "Al fallar una salvación contra la muerte, invocas un espíritu para cambiar el dado a éxito; no puedes repetirlo hasta pasar dos descansos largos.", effects = {} },
        },
    },
    {
        id = "feat_fortaleza_enana", icon = "WH_DeadlyDetermination", requiredRaces = { "raza_enano" }, name = "Fortaleza enana", requires = "Enano", description = "Aguante enano: cuando te cubres, aprovechas el respiro para recomponerte.",
        traits = {
            { id = "feat_fe_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "feat_fe_esquivar", icon = "hots_xinzhao_determination", name = "Esquivar y curar", type = "pasivo", description = "Al tomar la acción de Esquivar, puedes gastar un dado de golpe para curarte (tirada + Mod. Constitución, mínimo 1).", effects = {} },
        },
    },
    {
        id = "feat_precision_elfica", icon = "ability_hunter_aimedshot", requiredRaces = { "raza_elfo_noche", "raza_elfo_sangre", "raza_nocheterna", "raza_elfo_vacio", "raza_semielfo", "raza_renegado_elfo" }, name = "Precision elfica", requires = "Cualquier elfo o renegado (elfo)", description = "Puntería élfica: cuando la ocasión te favorece, la aprovechas mejor que nadie.",
        traits = {
            { id = "feat_pe_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Destreza, Inteligencia, Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Destreza"), AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_pe_reroll", icon = "hots_tyrande_huntersmark", name = "Precision", type = "pasivo", description = "Con ventaja en un ataque de Destreza, Inteligencia, Sabiduría o Carisma, puedes volver a tirar uno de los dados una vez.", effects = {} },
        },
    },
    {
        id = "feat_abrazo_vacio", icon = "hots_malzahar_voidshift", requiredRaces = { "raza_elfo_vacio" }, name = "Abrazo del Vacio", requires = "Elfo del Vacio", description = "El Vacío responde a tu magia necrótica, la refuerza y te envuelve mientras la canalizas.",
        traits = {
            { id = "feat_av_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia, Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_av_reroll", icon = "spell_necro_deathrift", name = "Daño necrotico", type = "pasivo", description = "Al tirar daño necrótico de un conjuro tuyo, puedes volver a tirar los 1 (usas el nuevo resultado, aunque sea otro 1).", effects = {} },
            { id = "feat_av_aura", icon = "inv_enchant_voidsphere", name = "Aura del Vacio", type = "pasivo", description = "Al lanzar un conjuro de daño necrótico, el vacío te envuelve hasta el fin de tu próximo turno: reduce la luz cercana y daña 1d4 a quien te golpee cuerpo a cuerpo a 1,5 m.", effects = {} },
        },
    },
    {
        id = "feat_rencor_faccion", icon = "eps_lol_tryndamere_undyingrage", name = "Rencor de faccion", requires = "Cualquier raza", description = "Odio jurado a dos razas enemigas: las conoces, las lees y reaccionas antes ante ellas.",
        traits = {
            { id = "feat_rf_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza, Constitución o Sabiduría +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion"), AbilOpt("Sabiduria") } } },
            { id = "feat_rf_enemigos", icon = "eps_lol_gnar_ragegene", name = "Enemigos jurados", type = "pasivo", description = "Elige dos razas de la facción opuesta. En el primer asalto de combate, tus ataques contra ellas tienen ventaja.", effects = {} },
            { id = "feat_rf_oportunidad", icon = "d3_battlerage", name = "Reflejos contra enemigos", type = "pasivo", description = "Cuando un enemigo elegido hace un ataque de oportunidad contra ti, lo hace con desventaja.", effects = {} },
            { id = "feat_rf_conocimiento", icon = "d3_berserkerrage", name = "Conocimiento del enemigo", type = "pasivo", description = "En pruebas de Inteligencia (Arcano, Historia, Naturaleza o Religión) sobre tus enemigos elegidos, sumas el doble de Bonus Competencia, aunque no seas competente.", effects = {} },
        },
    },
    {
        id = "feat_depredador_endurecido", icon = "ability_racial_darkflight", requiredRaces = { "raza_huargen" }, name = "Depredador endurecido", requires = "Huargen", description = "El instinto huargen a flor de piel: olfato, Correr a cuatro patas y garras que cuentan como arma.",
        traits = {
            { id = "feat_de_olfato", icon = "eps_wc3_enchantedbear", name = "Olfato agudo", type = "pasivo", description = "Ventaja en pruebas de Sabiduría (Percepción) que dependan del olfato.", effects = {} },
            { id = "feat_de_correr", icon = "ability_racial_runningwild", name = "Carrera a cuatro patas", type = "pasivo", description = "Con ambas manos vacias, puedes Correr como acción adicional, desplazandote a cuatro patas.", effects = {} },
            { id = "feat_de_garras", icon = "ability_racial_flayer", name = "Garras", type = "pasivo", description = "Tus garras son armas naturales: golpe desarmado que inflige 1d4 + Mod. Fuerza cortante.", effects = {} },
            { id = "feat_de_mordisco", icon = "inv_misc_monsterfang_02", name = "Mordisco y garras", type = "pasivo", description = "Si haces un ataque de mordisco como acción, puedes usar tu acción adicional para atacar con las garras.", effects = {} },
        },
    },
    {
        id = "feat_furia_orca", icon = "spell_winston_rage", requiredRaces = { "raza_orco" }, name = "Furia orca", requires = "Orco", description = "Furia orca en cada golpe, y una embestida más cuando la sangre ya te hierve.",
        traits = {
            { id = "feat_fo_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Constitución +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion") } } },
            { id = "feat_fo_dado", icon = "ability_warrior_deepcuts", name = "Golpe furioso", type = "pasivo", description = "Al golpear con un arma simple o marcial, tiras un dado de daño del arma extra (mismo tipo). 1 uso por descanso corto o largo.", effects = {} },
            { id = "feat_fo_reaccion", icon = "ability_warrior_warcry", name = "Furia implacable", type = "pasivo", description = "Justo después de usar Resistencia Implacable, puedes hacer un ataque con arma como reacción.", effects = {} },
        },
    },
    {
        id = "feat_prodigio", icon = "w3reforgedhumanarcanetower", requiredRaces = { "raza_humano", "raza_renegado_humano" }, name = "Prodigio", requires = "Renegado (humano) o humano", description = "Versatilidad humana: aprendes deprisa una habilidad, una herramienta y un idioma, y dominas algo que ya sabías.",
        traits = {
            { id = "feat_pr_competencia", icon = "inv_scroll_11", name = "Competencia en habilidad", type = "choice", description = "Competencia en una habilidad de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            { id = "feat_pr_extra", icon = "inv_misc_note_05", name = "Herramienta e idioma", type = "choice", description = "Competencia en una herramienta de tu elección (elige abajo) y fluidez en un idioma de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "toolProf" } },
            { id = "feat_pr_pericia", icon = "ability_rogue_stayofexecution", name = "Pericia", type = "choice", description = "Pericia en una habilidad en la que ya tengas competencia (que no se beneficie ya de otra pericia).", effects = {}, choice = { slots = 1, optionsFrom = "skillExpertise" } },
        },
    },
    {
        id = "feat_guia_espiritual", icon = "eps_lol_profileicon_runespirit", requiredRaces = { "raza_enano_martillo_salvaje", "raza_orco", "raza_tauren", "raza_trol" }, name = "Guia espiritual", requires = "Enano (Martillo Salvaje), orco, tauren o trol", description = "Los espíritus de tu pueblo te acompañan: sostienen tu ánimo y sanan a los tuyos.",
        traits = {
            { id = "feat_ge_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_ge_miedo", icon = "eps_lol_profileicon_runespirit2", name = "Valor espiritual", type = "pasivo", description = "Ventaja en tiradas de salvación contra el miedo.", effects = {} },
            { id = "feat_ge_conjuro", icon = "spell_nature_healingwavelesser", name = "Espiritu sanador", type = "pasivo", description = "Aprendes espíritu sanador y puedes lanzarlo una vez con este dote, recuperado en descanso largo. Característica: Sabiduría.", effects = {} },
        },
    },
    {
        id = "feat_agilidad_robusta", icon = "ability_rogue_fleetfooted", requiredRaces = { "raza_enano", "raza_gnomo", "raza_goblin" }, name = "Agilidad robusta", requires = "Enano, gnomo o goblin", description = "Cuerpo bajo y compacto, pero rápido: te mueves más y cuesta sujetarte.",
        traits = {
            { id = "feat_ar_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_ar_velocidad", icon = "ability_rogue_sprint", name = "Velocidad", type = "pasivo", description = "Tu velocidad aumenta en 1,5 metros.", effects = {} },
            { id = "feat_ar_competencia", name = "Acrobacias o atletismo", type = "choice", description = "Competencia en Acrobacias o Atletismo (tu elección).", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "acrobacias", label = "Acrobacias", effects = { { kind = "skillProf", skill = "Acrobacias" } } },
                    { id = "atletismo", icon = "inv_scroll_11",  label = "Atletismo",  effects = { { kind = "skillProf", skill = "Atletismo" } } },
                },
            } },
            { id = "feat_ar_agarre", icon = "inv_scroll_11", name = "Escapar de agarres", type = "pasivo", description = "Ventaja en pruebas de Fuerza (Atletismo) o Destreza (Acrobacias) para escapar de un agarre.", effects = {} },
        },
    },
    {
        id = "feat_resistencia_tauren", icon = "eps_wc3_tauren", requiredRaces = { "raza_tauren" }, name = "Resistencia Tauren", requires = "Tauren", description = "Corpulencia tauren: aguantas golpes sin armadura y tu vida crece con cada nivel.",
        traits = {
            { id = "feat_rt_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza, Destreza o Constitución +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza"), AbilOpt("Constitucion") } } },
            { id = "feat_rt_piel", icon = "inv_misc_nativebeastskin", name = "Piel gruesa", type = "pasivo", description = "Sin armadura, tu CA = 10 + Mod. Destreza + Mod. Constitución. Puedes usar escudo y mantener este beneficio.", effects = {} },
            { id = "feat_rt_pg", icon = "eps_wc3h_taurenanger", name = "Vitalidad Tauren", type = "pasivo", description = "Tus PG máximos aumentan en tu nivel al adquirir el dote y en +1 por cada nivel posterior.", effects = { { kind = "hpPerLevel", value = 1 } } },
        },
    },
    -- ===== Dotes del Manual del Jugador (PHB 5e ES) =====
    {
        id = "feat_acechador", icon = "ability_druid_prowl", requiredAbility = { abilities = { "Destreza" }, min = 13 }, name = "Acechador", requires = "Destreza 13 o mas", description = "Sabes esconderte donde otros no podrían, y un intento fallido no te delata.", source = "PHB",
        traits = {
            { id = "feat_phb_acechador", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Puedes esconderte si solo estas ligeramente oscurecido para la criatura. Fallar un ataque a distancia estando escondido no revela tu posición. La luz tenue no te da desventaja en Percepción (vista).", effects = {} },
        },
    },
    {
        id = "feat_actor", icon = "eps_lol_profileicon_songofnunubraum", name = "Actor", description = "Talento para la imitación y el disfraz verbal: convences con la voz y con el gesto.", source = "PHB",
        traits = {
            { id = "feat_phb_actor_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Carisma +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
            { id = "feat_phb_actor_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Ventaja en Engaño e Interpretación para hacerte pasar por otra persona. Puedes imitar voces y sonidos oidos al menos 1 minuto.", effects = {} },
        },
    },
    {
        id = "feat_afortunado", icon = "inv_misc_herb_goldclover", name = "Afortunado", description = "Una suerte inexplicable que puedes gastar cuando el dado no acompaña.", source = "PHB",
        traits = {
            -- Con `uses` el Libro lo saca como habilidad propia con contador 3/3 y anuncio al
            -- gastar; la repeticion del d20 sigue siendo de mesa.
            { id = "feat_phb_afortunado", icon = "inv_misc_herb_goldclover_leaf", name = "Suerte", type = "activo", uses = { max = 3, recharge = "long" }, description = "Tienes 3 puntos de suerte. Gastas 1 para tirar un d20 extra en un ataque/prueba/salvación (tuyo o contra ti) y elegir el resultado. Recargan en descanso largo.", effects = {} },
        },
    },
    {
        id = "feat_alerta", icon = "inv_misc_bell_01", name = "Alerta", description = "Nada te pilla desprevenido: reaccionas antes que nadie y no te sorprenden.", source = "PHB",
        traits = {
            { id = "feat_phb_alerta_ini", icon = "ability_rogue_fleetfooted", name = "Iniciativa", type = "pasivo", description = "+5 a la iniciativa.", effects = { { kind = "bonus", target = "initiative", value = 5 } } },
            { id = "feat_phb_alerta_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Consciente, no puedes ser sorprendido; las criaturas que no ves no obtienen ventaja al atacarte por ello.", effects = {} },
        },
    },
    {
        id = "feat_apresador", icon = "ability_warrior_titansgrip", requiredAbility = { abilities = { "Fuerza" }, min = 13 }, name = "Apresador", requires = "Fuerza 13 o mas", description = "Pelea pegado al enemigo: agarrar, sujetar y castigar a quien tienes encima.", source = "PHB",
        traits = {
            { id = "feat_phb_apresador", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Ventaja en ataques contra criaturas que estés agarrando. Con una acción puedes someter a un agarrado: ambos quedais apresados si tienes éxito.", effects = {} },
        },
    },
    {
        id = "feat_atacante_carga", icon = "ability_warrior_charge", name = "Atacante a la carga", description = "Aprovechas la carrera para rematarla con un golpe o una embestida.", source = "PHB",
        traits = {
            { id = "feat_phb_carga", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Al usar la acción de Correr puedes usar acción adicional para un ataque cuerpo a cuerpo o empujar. Si te moviste 3 m en línea recta antes, +5 al daño o empujas 3 m.", effects = {} },
        },
    },
    {
        id = "feat_atacante_salvaje", icon = "warrior_wild_strike", name = "Atacante salvaje", description = "Una vez por turno, repites el daño de un golpe cuerpo a cuerpo que no te convenza.", source = "PHB",
        traits = {
            { id = "feat_phb_salvaje", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Una vez por turno, al tirar el daño de un ataque cuerpo a cuerpo con arma, puedes repetir los dados de daño y usar el resultado que prefieras.", effects = {} },
        },
    },
    {
        id = "feat_atleta", icon = "eps_bg3_sprint", name = "Atleta", description = "Cuerpo entrenado: te levantas, trepas y saltas donde otros pierden el turno.", source = "PHB",
        traits = {
            { id = "feat_phb_atleta_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_atleta_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Levantarte derribado cuesta solo 1,5 m. Trepar no cuesta movimiento extra. Saltas con carrerilla tras moverte solo 1,5 m.", effects = {} },
        },
    },
    {
        id = "feat_azote_magos", icon = "ability_demonhunter_consumemagic", name = "Azote de magos", description = "Técnicas para ahogar la magia enemiga en cuanto la tienes al alcance.", source = "PHB",
        traits = {
            { id = "feat_phb_azote", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Reacción para atacar cuerpo a cuerpo a quien lance un conjuro a 1,5 m. Si lo dañas mientras se concentra, tiene desventaja en la salvación de concentración. Ventaja en salvaciones contra conjuros lanzados a 1,5 m.", effects = {} },
        },
    },
    {
        id = "feat_centinela", icon = "ability_warrior_revenge", name = "Centinela", description = "Nadie se escapa de tu lado: castigas a quien lo intenta y frenas a quien pasa.", source = "PHB",
        traits = {
            { id = "feat_phb_centinela", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Al impactar con un ataque de oportunidad, la velocidad del objetivo baja a 0 ese turno. Atacas de oportunidad aunque el enemigo se Destrabe.", effects = {} },
            { id = "feat_phb_centinela_golpe", icon = "ability_warrior_revenge", name = "Golpe de castigo", type = "reaccion", cast = "reaccion", actionKind = "reactionWeaponAttack", description = "Cuando una criatura a 1,5 m de ti ataca a un objetivo que no eres tú, usas tu reacción para hacerle un ataque de arma cuerpo a cuerpo.", effects = {} },
        },
    },
    {
        id = "feat_combatiente_dos_armas", icon = "ability_dualwield", name = "Combatiente con dos armas", description = "Dominio de las dos manos: mejor guardia y golpes de la mano torpe.", source = "PHB",
        traits = {
            { id = "feat_phb_2armas", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "+1 CA empuñando un arma cuerpo a cuerpo en cada mano. Puedes combatir con dos armas aunque no sean ligeras. Envainas/desenvainas dos armas a una mano a la vez.", effects = {} },
        },
    },
    {
        id = "feat_combatiente_montado", icon = "w3reforgedknight", name = "Combatiente montado", description = "A caballo eres otra cosa: proteges a tu montura y golpeas desde arriba.", source = "PHB",
        traits = {
            { id = "feat_phb_montado", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Montado y no incapacitado: ventaja en ataques cuerpo a cuerpo contra criaturas no montadas de tamaño menor que tu montura; rediriges a ti ataques contra tu montura; tu montura no recibe daño si supera una salvación de Destreza por mitad.", effects = {} },
        },
    },
    {
        id = "feat_duelista_defensivo", icon = "ability_parry", requiredAbility = { abilities = { "Destreza" }, min = 13 }, name = "Duelista defensivo", requires = "Destreza 13 o mas", description = "Con arma sutil, conviertes la parada en defensa cuando te van a impactar.", source = "PHB",
        traits = {
            { id = "feat_phb_duelista", icon = "ability_parry", name = "Parada defensiva", type = "reaccion", cast = "reaccion", description = "Empuñando un arma sutil con la que seas competente, al recibir un ataque cuerpo a cuerpo usas tu reacción para sumar tu Bonus de Competencia a la CA contra ese ataque.", effects = {} },
        },
    },
    {
        id = "feat_duro", icon = "ability_warrior_intensifyrage", name = "Duro", description = "Cuerpo curtido: aguantas mucho más castigo del que aparentas.", source = "PHB",
        traits = {
            { id = "feat_phb_duro", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Tus PG máximos aumentan en 2 por cada nivel (2x tu nivel total).", effects = { { kind = "hpPerLevel", value = 2 } } },
        },
    },
    {
        id = "feat_experto_ballestas", icon = "inv_weapon_crossbow_09", name = "Experto en ballestas", description = "La ballesta en tus manos no se atasca ni pierde ritmo, ni con el enemigo encima.", source = "PHB",
        traits = {
            { id = "feat_phb_ballestas", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Ignoras la recarga de ballestas con las que eres competente. Estar a 1,5 m de un enemigo no da desventaja a tus ataques a distancia. Al atacar con un arma a una mano, acción adicional para atacar con ballesta de mano.", effects = { { kind = "flag", flag = "ignoreRangedMeleePenalty" } } },
        },
    },
    {
        id = "feat_explorador_mazmorras", icon = "inv_enchanting_70_pet_torch", name = "Explorador de mazmorras", description = "Ojo entrenado para trampas y puertas secretas, y memoria para el terreno.", source = "PHB",
        traits = {
            { id = "feat_phb_mazmorras", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Ventaja en Percepción e Investigación para detectar puertas secretas y en salvaciones contra trampas. Resistencia al daño de trampas. Buscas trampas a ritmo normal.", effects = {} },
        },
    },
    {
        id = "feat_habilidoso", icon = "ability_kaztik_dominatemind", name = "Habilidoso", description = "Aprendizaje amplio: tres campos nuevos, a tu elección, entre habilidades y herramientas.", source = "PHB",
        traits = {
            { id = "feat_phb_habilidoso", icon = "inv_scroll_11", name = "Competencias", type = "choice", description = "Competencia en tres habilidades o herramientas de tu elección.", effects = {}, choice = { slots = 3, optionsFrom = "skillProf" } },
        },
    },
    {
        id = "feat_iniciado_magia", icon = "spell_mage_presenceofmind", name = "Iniciado en la magia", description = "Un pie en otra tradición mágica: unos trucos y un conjuro prestados.", source = "PHB",
        traits = {
            { id = "feat_phb_iniciado", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Elige una clase lanzadora: aprendes dos trucos de su lista y un conjuro de nivel 1 (lanzable 1 vez por descanso largo con este dote). La aptitud mágica depende de la clase elegida.", effects = {} },
        },
    },
    {
        id = "feat_lanzador_combate", icon = "ability_mage_burnout", requiredCaster = "any", name = "Lanzador en combate", requires = "Capacidad de lanzar al menos un conjuro", description = "Lanzar bajo presión: no pierdes el conjuro por un golpe ni por tener las manos ocupadas.", source = "PHB",
        traits = {
            { id = "feat_phb_lcombate", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Ventaja en salvaciones de Constitución para mantener concentración al recibir daño. Ejecutas componentes somaticos con las manos ocupadas por armas/escudo.", effects = {} },
            { id = "feat_phb_lcombate_conjuro", icon = "ability_mage_burnout", name = "Conjuro de oportunidad", type = "reaccion", cast = "reaccion", description = "Cuando una criatura provoca tu ataque de oportunidad, usas tu reacción para lanzarle un conjuro (1 acción, un solo objetivo) en su lugar. Lánzalo justo después desde tu grimorio.", effects = {} },
        },
    },
    {
        id = "feat_lanzador_preciso", icon = "eps_lol_profileicon_truedamage", requiredCaster = "any", name = "Lanzador preciso", requires = "Capacidad de lanzar al menos un conjuro", description = "Puntería con la magia: tus ataques de conjuro no sufren por la cercanía ni por la cobertura.", source = "PHB",
        traits = {
            { id = "feat_phb_lpreciso", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Al lanzar un conjuro con tirada de ataque, su alcance se duplica. Tus ataques de conjuro a distancia ignoran cobertura media y tres cuartos. Aprendes un truco con tirada de ataque.", effects = {} },
        },
    },
    {
        id = "feat_lanzador_ritual", icon = "hots_mageprofile", requiredAbility = { abilities = { "Inteligencia", "Sabiduria" }, min = 13 }, name = "Lanzador ritual", requires = "Inteligencia o Sabiduria 13 o mas", description = "Un libro propio de rituales que puedes lanzar sin gastar espacios.", source = "PHB",
        traits = {
            { id = "feat_phb_lritual", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Obtienes un libro de rituales con dos conjuros de nivel 1 con etiqueta ritual de una clase a elegir. Puedes copiar al libro otros conjuros rituales que encuentres.", effects = {} },
        },
    },
    {
        id = "feat_lider_inspirador", icon = "achievement_guildperk_everyones a hero", requiredAbility = { abilities = { "Carisma" }, min = 13 }, name = "Lider inspirador", requires = "Carisma 13 o mas", description = "Una arenga antes del combate deja a los tuyos con aguante de sobra.", source = "PHB",
        traits = {
            { id = "feat_phb_lider", icon = "achievement_guildperk_everyones a hero", name = "Arenga inspiradora", type = "accion", cast = "accion", actionKind = "selfHeal", healBase = "level", healAbility = "Carisma", healResource = "temp_health", uses = { max = 1, recharge = "short" }, description = "Tras 10 minutos de arenga, hasta seis criaturas (incluido tú) a 9 m que te vean u oigan reciben PG temporales = tu nivel + Mod. Carisma. Los tuyos se aplican solos; tus aliados se los anotan al ver el anuncio. No se repite hasta un descanso.", effects = {} },
        },
    },
    {
        id = "feat_ligeramente_acorazado", icon = "inv_chest_chain_03", name = "Ligeramente acorazado", description = "Entrenamiento con armadura ligera, para quien no la tenía.", source = "PHB",
        traits = {
            { id = "feat_phb_lacor_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_lacor_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Competencia con armaduras ligeras.", effects = { { kind = "armorProf", armor = "ligera" } } },
        },
    },
    {
        id = "feat_linguista", icon = "trade_archaeology_silverscrollcase", name = "Linguista", description = "Estudio de lenguas y códigos: hablas más idiomas y escribes en clave.", source = "PHB",
        traits = {
            { id = "feat_phb_ling_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
            { id = "feat_phb_ling_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Puedes crear códigos cifrados para tus mensajes escritos.", effects = {} },
            -- Los tres idiomas son eleccion REAL (selector de idiomas, exoticos incluidos):
            -- entran en la entrada Idiomas del Libro con su origen.
            { id = "feat_phb_ling_idiomas", icon = "inv_misc_note_05", name = "Idiomas", type = "choice", description = "Aprendes tres idiomas de tu elección.", effects = {}, choice = { slots = 3, optionsFrom = "language", exotic = true } },
        },
    },
    {
        id = "feat_maestro_armas", icon = "garrison_weaponupgrade", name = "Maestro de armas", description = "Práctica con un puñado de armas nuevas, elegidas por ti.", source = "PHB",
        traits = {
            { id = "feat_phb_marmas_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_marmas_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Competencia con cuatro armas a tu elección (sencillas o marciales).", effects = {} },
        },
    },
    {
        id = "feat_maestro_escudero", icon = "ability_warrior_shieldguard", name = "Maestro escudero", description = "El escudo como muro y como arma: protege a quien tienes al lado y derriba al que tienes delante.", source = "PHB",
        traits = {
            { id = "feat_mesc_defensa", icon = "inv_shield_05", name = "Defensa con escudo", type = "pasivo", description = "Mientras portes un escudo y no estés incapacitado: sumas la CA del escudo a tus salvaciones de Destreza contra ataques o efectos que te tengan a TI de objetivo; y si superas una salvación de Destreza contra un efecto que aun así inflige daño, lo ignoras por completo.", effects = {} },
            { id = "feat_mesc_embate", icon = "ability_warrior_shieldbash", name = "Embate con escudo", type = "pasivo", description = "Al usar la acción de Ataque en tu turno, puedes usar tu acción adicional para embatir con el escudo a una criatura a tu alcance cuerpo a cuerpo: 1d4 + Mod. Fuerza contundente. Activa 'Offhand' con un escudo en la mano secundaria y ataca para tirarlo.", effects = {
                { kind = "flag", flag = "shieldBash" },
            } },
        },
    },
    {
        id = "feat_gran_maestro_armas", icon = "ability_warrior_unrelentingassault", name = "Gran maestro de armas", description = "Armas grandes llevadas al límite: cambias puntería por daño y encadenas ataques cuando cae un enemigo.", source = "PHB",
        traits = {
            { id = "feat_gma_adicional", icon = "eps_bg3_multiattack", name = "Ataque adicional", type = "pasivo", description = "En tu turno, al hacer un golpe crítico con un arma cuerpo a cuerpo o reducir a una criatura a 0 PG con ella, puedes hacer un ataque cuerpo a cuerpo como acción adicional.", effects = {} },
            { id = "feat_gma_potente", icon = "ability_rogue_sabreslash", name = "Golpe potente", type = "recurso", description = "Toggle: antes de atacar c/c con un arma a dos manos competente, -5 a la tirada de ataque y +10 al daño si impacta. Actívalo en 'Daño extra'.", effects = {
                { kind = "conditionalWeaponDamage", id = "gwm_potente", label = "Golpe Potente (-5/+10)", flatBonus = 10, attackPenalty = 5 },
            } },
        },
    },
    {
        id = "feat_maestro_armaduras_medias", icon = "inv_chest_chain_05", requiredProficiency = { armor = "media" }, name = "Maestro en armaduras medias", requires = "Competente con armaduras medias", description = "Te mueves con armadura media como si no la llevaras.", source = "PHB",
        traits = {
            { id = "feat_phb_amedias", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "La armadura media no te da desventaja en Sigilo. Con Destreza 16+ sumas 3 (en vez de 2) a la CA con armadura media.", effects = {} },
        },
    },
    {
        id = "feat_maestro_armaduras_pesadas", icon = "inv_chest_plate02", requiredProficiency = { armor = "pesada" }, name = "Maestro en armaduras pesadas", requires = "Competencia con armaduras pesadas", description = "La armadura pesada desvía contigo golpes que a otros los matarían.", source = "PHB",
        traits = {
            { id = "feat_phb_apes_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
            { id = "feat_phb_apes_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Con armadura pesada, el daño contundente/cortante/perforante de armas no mágicas que recibes se reduce en 3.", effects = {} },
        },
    },
    {
        id = "feat_maestro_armas_asta", icon = "inv_spear_05", name = "Maestro en armas de asta", description = "Alabardas y lanzas largas: golpeas dos veces y castigas a quien se acerca.", source = "PHB",
        traits = {
            { id = "feat_phb_asta", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Con alabarda, bastón o guja, acción adicional para un ataque con el extremo opuesto (d4 contundente). Atacas de oportunidad a quien entre en el alcance de alabarda/bastón/guja/pica.", effects = {} },
        },
    },
    {
        id = "feat_maestro_armas_pesadas", icon = "inv_sword_111", name = "Maestro en armas pesadas", description = "Usas el peso del arma a tu favor y rematas a quien cae.", source = "PHB",
        traits = {
            { id = "feat_phb_apesadas", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Una vez por turno, con un crítico o al reducir a 0 PG con arma cuerpo a cuerpo, acción adicional para otro ataque cuerpo a cuerpo. Con arma pesada competente puedes -5 al ataque por +10 al daño.", effects = {} },
        },
    },
    {
        id = "feat_maestro_escudos", icon = "inv_shield_06", name = "Maestro en escudos", description = "El escudo también golpea: derribas y te cubres de lo que estalla.", source = "PHB",
        traits = {
            { id = "feat_phb_escudos", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Con escudo: al usar la acción de Atacar, acción adicional para empujar con el escudo a 1,5 m. Sumas el bono de CA del escudo a salvaciones de Destreza que solo te afecten a ti.", effects = {} },
            { id = "feat_phb_escudos_abrigo", icon = "inv_shield_06", name = "Abrigo del escudo", type = "reaccion", cast = "reaccion", description = "Si superas una salvación de Destreza contra un efecto que solo te afecta a ti y hace mitad de daño al superarla, usas tu reacción para no recibir ningún daño, interponiendo el escudo.", effects = {} },
        },
    },
    {
        id = "feat_maton_taberna", icon = "ability_racial_brushitoff", name = "Maton de taberna", description = "Pelea sucia: puños, botellas y cualquier cosa que esté a mano.", source = "PHB",
        traits = {
            { id = "feat_phb_maton_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Constitución +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion") } } },
            { id = "feat_phb_maton_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Competente con armas improvisadas. Tus ataques sin armas infligen 1d4. Al impactar con golpe desarmado o arma improvisada, acción adicional para agarrar.", effects = {} },
        },
    },
    {
        id = "feat_mente_aguda", icon = "dos2_mind", name = "Mente aguda", description = "Memoria y orientación infalibles: sabes la hora, el rumbo y lo que se dijo.", source = "PHB",
        traits = {
            { id = "feat_phb_mente_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
            { id = "feat_phb_mente_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Siempre sabes donde esta el norte y cuanto falta para el amanecer/anochecer. Recuerdas con exactitud todo lo visto u oído el ultimo mes.", effects = {} },
        },
    },
    {
        id = "feat_moderadamente_acorazado", icon = "inv_armor_shoulder_plate_naxxramas_raidwarrior_c_01", requiredProficiency = { armor = "ligera" }, name = "Moderadamente acorazado", requires = "Competencia con armaduras ligeras", description = "Entrenamiento con armadura media y escudo, para quien solo llevaba ligera.", source = "PHB",
        traits = {
            { id = "feat_phb_macor_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_phb_macor_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Competencia con armaduras medias y escudos.", effects = { { kind = "armorProf", armor = "media" }, { kind = "armorProf", armor = "escudo" } } },
        },
    },
    {
        id = "feat_movil", icon = "ability_rogue_fleetfooted", name = "Movil", description = "Rápido y escurridizo: cubres más terreno y te vas sin que te castiguen.", source = "PHB",
        traits = {
            -- El +3 m es real (bono de velocidad: ficha y muro de movimiento); terreno dificil
            -- y oportunidad quedan en mesa.
            { id = "feat_phb_movil", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Tu velocidad aumenta 3 m. Al Correr, el terreno difícil no cuesta movimiento extra ese turno. Tras un ataque cuerpo a cuerpo a una criatura, no provocas ataques de oportunidad de ella ese turno.", effects = { { kind = "bonus", target = "speed", value = 3 } } },
        },
    },
    {
        id = "feat_muy_acorazado", icon = "eps_wc3h_platedhelmet", requiredProficiency = { armor = "media" }, name = "Muy acorazado", requires = "Competente con armaduras medias", description = "Entrenamiento con armadura pesada, para quien ya manejaba la media.", source = "PHB",
        traits = {
            { id = "feat_phb_muyacor_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
            { id = "feat_phb_muyacor_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Competencia con armaduras pesadas.", effects = { { kind = "armorProf", armor = "pesada" } } },
        },
    },
    {
        id = "feat_observador", icon = "WH_EagleEye", name = "Observador", description = "Detalle que se te escapa, detalle que no existe; y además lees los labios.", source = "PHB",
        traits = {
            { id = "feat_phb_obs_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia o Sabiduría +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria") } } },
            { id = "feat_phb_obs_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Lees los labios de quien hable un idioma que conozcas y veas su boca. +5 a tu Percepción e Investigación pasivas.", effects = {} },
        },
    },
    {
        id = "feat_resiliente", icon = "hots_hots_resilientshield", name = "Resiliente", description = "Refuerzas una característica y aprendes a salvar con ella.", source = "PHB",
        traits = {
            { id = "feat_phb_resiliente", name = "Caracteristica y salvacion", type = "choice", description = "Una característica +1 (max 20) y competencia en sus salvaciones.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "fuerza",       label = "Fuerza +1 y salvacion",       effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 },       { kind = "saveProf", ability = "Fuerza" } } },
                    { id = "destreza",     label = "Destreza +1 y salvacion",     effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },     { kind = "saveProf", ability = "Destreza" } } },
                    { id = "constitucion", icon = "eps_wow_wildstalkr", label = "Constitucion +1 y salvacion", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 }, { kind = "saveProf", ability = "Constitucion" } } },
                    { id = "inteligencia", label = "Inteligencia +1 y salvacion", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 }, { kind = "saveProf", ability = "Inteligencia" } } },
                    { id = "sabiduria", icon = "hd_plussign_hunter",    label = "Sabiduria +1 y salvacion",    effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },    { kind = "saveProf", ability = "Sabiduria" } } },
                    { id = "carisma", icon = "hd_plussign_hunter",      label = "Carisma +1 y salvacion",      effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 },      { kind = "saveProf", ability = "Carisma" } } },
                },
            } },
        },
    },
    {
        id = "feat_resistente", icon = "ability_warrior_strengthofarms", name = "Resistente", description = "Constitución de sobra: cada nivel te deja más vida de la que te corresponde.", source = "PHB",
        traits = {
            { id = "feat_phb_resistente_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "feat_phb_resistente_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Al tirar un Dado de Golpe para curarte, el mínimo que recuperas es 2x Mod. Constitución (mínimo 2).", effects = {} },
        },
    },
    {
        id = "feat_sanador", icon = "eps_rumble_traithealer", name = "Sanador", description = "Manos de médico: levantas a un caído y curas más de lo normal con un botiquín.", source = "PHB",
        traits = {
            { id = "feat_phb_sanador", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Al estabilizar con útiles de sanador, la criatura recupera además 1 PG.", effects = {} },
            { id = "feat_phb_sanador_botiquin", icon = "eps_rumble_traithealer", name = "Botiquin de sanador", type = "accion", cast = "accion", description = "Gastas un uso de tus útiles de sanador sobre una criatura: recupera 1d6+4 PG más tantos PG como Dados de Golpe tenga. Una vez por descanso por criatura; la curación se aplica en mesa.", effects = {} },
        },
    },
    {
        id = "feat_tirador_primera", icon = "ability_marksmanship", name = "Tirador de primera", description = "Disparos que otros dan por imposibles: distancia, cobertura y potencia a cambio de puntería.", source = "PHB",
        traits = {
            { id = "feat_phb_tirador", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Sin desventaja a alcance largo. Tus ataques a distancia ignoran cobertura media y tres cuartos. Con arma a distancia competente puedes -5 al ataque por +10 al daño.", effects = {} },
        },
    },
    {
        id = "feat_versado_armas", icon = "ability_warrior_weaponmastery", name = "Versado en las armas", description = "Maniobras marciales prestadas, con su dado de superioridad.", source = "PHB",
        traits = {
            { id = "feat_phb_versarmas", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes dos maniobras del Maestro del Combate (guerrero). Ganas un dado de supremacia d6 (o uno mas si ya tienes). Recargan en descanso corto o largo.", effects = {} },
        },
    },
    {
        id = "feat_versado_elemento", icon = "spell_fire_masterofelements", requiredCaster = "any", name = "Versado en un elemento", requires = "Capacidad de lanzar al menos un conjuro", description = "Eliges un elemento y tus conjuros de ese tipo pegan más y atraviesan resistencias.", source = "PHB",
        traits = {
            -- MECANIZADO: la eleccion aplica `elementAdept` — los 1 de los dados de conjuro de
            -- ese tipo valen 2 (lado atacante) y la resistencia del objetivo se ignora (viaja
            -- en la peticion de area; la inmunidad no se perdona).
            { id = "feat_phb_verselem", icon = "inv_scroll_11", name = "Elemento versado", type = "choice", description = "Elige un tipo de daño (acido, frío, fuego, relámpago o trueno): tus conjuros ignoran la resistencia a ese tipo y puedes contar cualquier 1 en sus dados de daño como 2.", effects = {}, choice = { slots = 1, options = {
                { id = "verselem_acido", label = "Acido", effects = { { kind = "elementAdept", damageType = "acido" } } },
                { id = "verselem_frio", label = "Frio", effects = { { kind = "elementAdept", damageType = "frio" } } },
                { id = "verselem_fuego", label = "Fuego", effects = { { kind = "elementAdept", damageType = "fuego" } } },
                { id = "verselem_relampago", label = "Relampago", effects = { { kind = "elementAdept", damageType = "relampago" } } },
                { id = "verselem_trueno", label = "Trueno", effects = { { kind = "elementAdept", damageType = "trueno" } } },
            } } },
        },
    },
    -- ===== Dotes de El Caldero para Todo de Tasha (TCoE 5e ES) =====
    {
        id = "feat_iniciado_artificiero", icon = "eps_lol_profileicon_elementofmagma", name = "Iniciado artificiero", description = "Un poco de la inventiva del artífice: un truco, un conjuro y herramientas.", source = "TCoE",
        traits = {
            { id = "feat_tco_artif_tool", icon = "inv_scroll_11", name = "Herramientas de artesano", type = "choice", description = "Competencia con un tipo de herramientas de artesano de tu elección (canalizador mágico para conjuros con Inteligencia).", effects = {}, choice = { slots = 1, optionsFrom = "toolProf" } },
            { id = "feat_tco_artif", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes un truco y un conjuro de nivel 1 de la lista de artífice (Inteligencia); el conjuro 1 vez por descanso largo sin espacio.", effects = {} },
        },
    },
    {
        id = "feat_cocinero", icon = "achievement_profession_chefhat", name = "Cocinero", description = "Cocina de campamento que alimenta el cuerpo y el ánimo de la partida.", source = "TCoE",
        traits = {
            { id = "feat_tco_cocinero_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Constitución o Sabiduría +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Constitucion"), AbilOpt("Sabiduria") } } },
            { id = "feat_tco_cocinero_b", icon = "inv_scroll_11", name = "Beneficios", type = "informativo", description = "Competencia con útiles de cocinero. En un descanso corto cocinas comida para 4 + Bonus Competencia (recuperan 1d8 PG extra al gastar Dados de Golpe). Tras un descanso largo preparas golosinas que dan PG temporales.", effects = { { kind = "toolProf", tool = "Utiles de cocinero" } } },
        },
    },
    {
        id = "feat_triturador", icon = "ability_smash", name = "Triturador", description = "Golpes que desplazan: mueves al enemigo de sitio y le abres la guardia.", source = "TCoE",
        traits = {
            { id = "feat_tco_trit_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Constitución +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Constitucion") } } },
            { id = "feat_tco_trit_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Una vez por turno, al dañar con daño contundente mueves al objetivo 1,5 m. Con un crítico contundente, los ataques contra ese objetivo tienen ventaja hasta tu próximo turno.", effects = {} },
        },
    },
    {
        id = "feat_adepto_sobrenatural", icon = "ability_ardenweald_warlock", requiredCaster = "class", name = "Adepto sobrenatural", requires = "Rasgo Lanzamiento de Conjuros o Magia del Pacto", description = "Desbloqueas una invocación sobrenatural del brujo.", source = "TCoE",
        traits = {
            { id = "feat_tco_sobren", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes una Invocacion Sobrenatural de la clase brujo (si tiene requisito, debes cumplirlo como brujo). Puedes cambiarla al subir de nivel.", effects = {} },
        },
    },
    {
        id = "feat_tocado_hadas", icon = "eps_bg3_feyprotectiongreen", name = "Tocado por las hadas", description = "La magia feérica te ha marcado: apareces donde no estabas y encantas a quien te mira.", source = "TCoE",
        traits = {
            { id = "feat_tco_hadas_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia, Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_hadas_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes paso brumoso y un conjuro de nivel 1 de adivinacion o encantamiento; lanzas cada uno 1 vez por descanso largo sin espacio (también con espacios). Aptitud mágica: la característica aumentada.", effects = {} },
        },
    },
    {
        id = "feat_iniciado_combate", icon = "ability_rogue_combatreadiness", requiredProficiency = { weapon = "marciales" }, name = "Iniciado en el combate", requires = "Competencia con un arma marcial", description = "Adoptas un estilo de combate y un truco marcial que lo acompaña.", source = "TCoE",
        traits = {
            { id = "feat_tco_inicomb", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes un Estilo de Combate de la clase guerrero (distinto si ya tienes uno). Puedes cambiarlo al subir de nivel.", effects = {} },
        },
    },
    {
        id = "feat_artillero_dote", icon = "inv_misc_ammo_bullet_02", name = "Tirador (armas de fuego)", description = "Mano rápida con la pólvora: recargas sola y disparas sin miedo al cuerpo a cuerpo.", source = "TCoE",
        traits = {
            { id = "feat_tco_gunner_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +1 (max 20).", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 } } },
            { id = "feat_tco_gunner_b", icon = "inv_scroll_11", name = "Beneficios", type = "informativo", description = "Competencia con armas de fuego. Ignoras la propiedad de munición de las armas de fuego. Estar a 1,5 m de un enemigo no da desventaja a tus ataques a distancia.", effects = { { kind = "weaponProf", weapon = "armas de fuego" } } },
        },
    },
    {
        id = "feat_adepto_metamagia", icon = "spell_holy_dispelmagic", requiredCaster = "class", name = "Adepto de la metamagia", requires = "Rasgo Lanzamiento de Conjuros o Magia del Pacto", description = "Aprendes a retorcer tus conjuros con los recursos del hechicero.", source = "TCoE",
        traits = {
            { id = "feat_tco_metamagia", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes dos opciones de Metamagia de la clase hechicero (cambiables al subir nivel). Obtienes 2 puntos de hechicería solo para Metamagia, que recargan en descanso largo.", effects = {} },
        },
    },
    {
        id = "feat_perforador", icon = "ability_warrior_shieldbreak", name = "Perforador", description = "Buscas el hueco de la armadura: repites el daño de tus golpes perforantes.", source = "TCoE",
        traits = {
            { id = "feat_tco_perf_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_tco_perf_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Una vez por turno, al dañar con daño perforante puedes repetir un dado de daño (usas el nuevo). Con un crítico perforante, tiras un dado de daño perforante adicional.", effects = {} },
        },
    },
    {
        id = "feat_envenenador", icon = "trade_brewpoison", name = "Envenenador", description = "Uso experto del veneno: lo aplicas sin perder el turno y atraviesas las defensas habituales.", source = "TCoE",
        traits = {
            { id = "feat_tco_envenenador", icon = "inv_scroll_11", name = "Beneficios", type = "informativo", description = "Ignoras la resistencia al daño por veneno. Aplicas veneno como acción adicional. Competencia con útiles de envenenador; en 1 hora y 50 po creas dosis de veneno potente (CD 14 Con, 2d8 veneno y envenenado).", effects = { { kind = "toolProf", tool = "Utiles de envenenador" } } },
        },
    },
    {
        id = "feat_tocado_sombras", icon = "spell_shadow_shadowembrace", name = "Tocado por las sombras", description = "El Páramo Sombrío te ha cambiado: te vuelves invisible y ves lo que otros no.", source = "TCoE",
        traits = {
            { id = "feat_tco_sombras_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia, Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_sombras_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes invisibilidad y un conjuro de nivel 1 de ilusion o nigromancia; lanzas cada uno 1 vez por descanso largo sin espacio (también con espacios). Aptitud mágica: la característica aumentada.", effects = {} },
        },
    },
    {
        id = "feat_experto_habilidades", icon = "ability_mage_studentofthemind", name = "Experto en habilidades", description = "Perfeccionas lo que ya sabías hasta convertirlo en pericia.", source = "TCoE",
        traits = {
            { id = "feat_tco_exph_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Una característica de tu elección +1 (max 20).", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
            { id = "feat_tco_exph_prof", icon = "inv_scroll_11", name = "Competencia en habilidad", type = "choice", description = "Competencia en una habilidad de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            { id = "feat_tco_exph_exp", icon = "ability_rogue_stayofexecution", name = "Pericia", type = "choice", description = "Pericia en una habilidad en la que ya seas competente (que no tenga ya pericia).", effects = {}, choice = { slots = 1, optionsFrom = "skillExpertise" } },
        },
    },
    {
        id = "feat_cortador", icon = "ability_revendreth_rogue", name = "Cortador", description = "Sabes dónde cortar: tus golpes cortantes frenan o ciegan al enemigo.", source = "TCoE",
        traits = {
            { id = "feat_tco_cort_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Fuerza o Destreza +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Fuerza"), AbilOpt("Destreza") } } },
            { id = "feat_tco_cort_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Una vez por turno, al dañar con daño cortante reduces la velocidad del objetivo en 3 m hasta tu próximo turno. Con un crítico cortante, el objetivo tiene desventaja en ataques hasta tu próximo turno.", effects = {} },
        },
    },
    {
        id = "feat_telequinetico", icon = "WH_FocusedMind", name = "Telequinetico", description = "Mueves objetos y empujas criaturas con la mente.", source = "TCoE",
        traits = {
            { id = "feat_tco_telek_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia, Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_telek_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Aprendes mano de mago (sin componentes V/S, mano invisible). Como acción adicional, empujas telequineticamente a una criatura a 9 m (salvación de Fuerza o movida 1,5 m). Aptitud mágica: la característica aumentada.", effects = {} },
        },
    },
    {
        id = "feat_telepata", icon = "spell_arcane_mindmastery", name = "Telepata", description = "Hablas mente a mente y puedes asomarte a los pensamientos ajenos.", source = "TCoE",
        traits = {
            { id = "feat_tco_telep_inc", icon = "hd_plussign_hunter", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia, Sabiduría o Carisma +1 (max 20).", effects = {}, choice = { slots = 1, options = { AbilOpt("Inteligencia"), AbilOpt("Sabiduria"), AbilOpt("Carisma") } } },
            { id = "feat_tco_telep_b", icon = "inv_scroll_11", name = "Beneficios", type = "pasivo", description = "Hablas telepaticamente con cualquier criatura a 18 m (en un idioma que conozcas). Lanzas detectar pensamientos 1 vez por descanso largo sin espacio (aptitud: la característica aumentada).", effects = {} },
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

-- El requisito racial ESTRUCTURADO (el campo `requires` sigue siendo el texto para el tooltip).
-- Casa contra el id de RAZA o el de SUBRAZA: "renegado (elfo)" es una subraza.
function API.RaceAllowed(featDef, raceId, subraceId)
    local req = featDef and featDef.requiredRaces
    if type(req) ~= "table" or #req == 0 then return true end
    raceId, subraceId = tostring(raceId or ""), tostring(subraceId or "")
    for _, id in ipairs(req) do
        if id == raceId or (subraceId ~= "" and id == subraceId) then return true end
    end
    return false
end

-- Prerequisito de caracteristica ("Destreza 13 o mas"): basta con que UNA de las listadas
-- llegue al minimo (Lanzador ritual pide Inteligencia O Sabiduria). `scoreFn(clave)` la aporta
-- quien llama, porque la puntuacion vive en el borrador durante la creacion y en la ficha viva
-- durante la subida.
function API.AbilityAllowed(featDef, scoreFn)
    local req = featDef and featDef.requiredAbility
    if type(req) ~= "table" or type(scoreFn) ~= "function" then return true end
    local minimo = tonumber(req.min) or 13
    for _, clave in ipairs(req.abilities or {}) do
        if (tonumber(scoreFn(clave)) or 0) >= minimo then return true end
    end
    return false
end

-- Prerequisito de competencia ("Competente con armaduras medias", "arma marcial"). Los sets
-- llegan de quien llama: {armor={ligera=true,...}, weapon={marciales=true,...}} -- del borrador
-- en creacion, de FeatureEffects en subida. `escudo` no cuenta como armadura para esto.
function API.ProficiencyAllowed(featDef, profs)
    local req = featDef and featDef.requiredProficiency
    if type(req) ~= "table" or type(profs) ~= "table" then return true end
    if req.armor and not (profs.armor and profs.armor[tostring(req.armor)]) then return false end
    if req.weapon and not (profs.weapon and profs.weapon[tostring(req.weapon)]) then return false end
    return true
end

-- Prerequisito de lanzador. "any" = capacidad de lanzar AL MENOS un conjuro (vale la magia
-- racial: un Man'ari con Taumaturgia califica); "class" = rasgo de CLASE Lanzamiento de
-- Conjuros o Magia del Pacto (la magia racial NO vale). `caster` = { class = bool, any = bool }.
function API.CasterAllowed(featDef, caster)
    local req = featDef and featDef.requiredCaster
    if not req or type(caster) ~= "table" then return true end
    if req == "class" then return caster.class == true end
    return caster.any == true
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
-- Los rasgos SUELTOS de cada dote. Lo usa quien necesita sus efectos uno a uno -- el motor de
-- efectos, el generador del About --, no quien la muestra.
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

-- UNA entrada por dote, con su nombre y todo lo que hace dentro. Es lo que quiere el Libro: antes
-- se anadia un rasgo suelto por cada cosa que hacia la dote, asi que "Mago de batalla" aparecia
-- como tres habilidades sin nombre reconocible -- "Trucos de Mago", "Sin desventaja en cercania",
-- "Conjuro potente" -- y la dote como tal no salia por ninguna parte.
--
-- Agrupar no pierde nada mientras el rasgo NO sea accionable. Los que SI lo son (`uses`,
-- `cast` o `actionKind` — la Suerte de Afortunado tiene 3 usos por descanso largo) salen como
-- entrada PROPIA ademas de la agrupada: el Libro necesita la fila para el contador y el gasto.
function API.GetFeatAbilities(featIds)
    local out = {}
    if type(featIds) ~= "table" then return out end
    for _, featId in ipairs(featIds) do
        local featDef = API.GetFeat(featId)
        if featDef then
            local partes = {}
            if featDef.description and featDef.description ~= "" then
                partes[#partes + 1] = featDef.description
            end
            for _, trait in ipairs(featDef.traits or {}) do
                if trait.uses or trait.cast or trait.actionKind then
                    out[#out + 1] = { className = "Dote: " .. tostring(featDef.name or featDef.id),
                        level = 0, feature = trait }
                else
                    local nombre = tostring(trait.name or "")
                    local texto = tostring(trait.description or "")
                    -- El nombre del rasgo delante y en negrita: dentro de la dote sigue siendo util
                    -- saber que parte hace que, aunque ya no sea una habilidad aparte.
                    partes[#partes + 1] = (nombre ~= "" and ("|cffffd100" .. nombre .. ":|r ") or "") .. texto
                end
            end
            out[#out + 1] = {
                className = "Dote",
                level = 0,
                feature = {
                    id = featDef.id,
                    -- Con el prefijo: en una lista de treinta habilidades, "Mago de batalla" no
                    -- dice de donde sale. "Dote: Mago de batalla" si.
                    -- El NOMBRE de la dote a secas. El prefijo "Dote: " sobraba: lo que es se
                    -- dice en la etiqueta de categoria, debajo, como el resto de habilidades --
                    -- ninguna se llama "Pasiva: Vision oscura".
                    name = tostring(featDef.name or featDef.id),
                    esDote = true,
                    icon = featDef.icon,
                    type = "pasivo",
                    description = table.concat(partes, "\n\n"),
                },
            }
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
