-- HarfordDnDProgression: estado de clase/subclase/rasgos por perfil.

HarfordDnDProgression = HarfordDnDProgression or {}

local API = HarfordDnDProgression
local SCHEMA_VERSION = 3
local MAX_TOTAL_LEVEL = 20
API.MAX_TOTAL_LEVEL = MAX_TOTAL_LEVEL

local function CopyTable(src)
    local out = {}
    for k, v in pairs(src or {}) do
        if type(v) == "table" then
            out[k] = CopyTable(v)
        else
            out[k] = v
        end
    end
    return out
end

local function ResolveProfileName(profileName)
    return tostring(profileName or (UnitName and UnitName("player")) or "default")
end

local function NormalizeText(value)
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
    -- Asignar y devolver UN solo valor: `gsub` devuelve (string, count) y si ese count se
    -- propaga como ultimo retorno (p.ej. OptionMatchName -> tabla) se cuela un numero.
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

-- La progresion se guarda anidada en profiles[name]._progression (todo lo de la ficha
-- agrupado por perfil). ProfileSlot devuelve (y crea) profiles[name].
local function ProfileSlot(name)
    HarfordDnDPersistStore = HarfordDnDPersistStore or {}
    if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
    if type(HarfordDnDPersistStore.profiles[name]) ~= "table" then HarfordDnDPersistStore.profiles[name] = {} end
    return HarfordDnDPersistStore.profiles[name]
end

local function EmptyProgression()
    return {
        schema = SCHEMA_VERSION,
        classLevels = {},
        featureStates = {},
        choices = {},
        importedProficiencies = { skillRank = {}, saveProf = {}, armorProf = {}, weaponProf = {}, toolProf = {}, languages = {} },
        race = { id = "", subraceId = "" },
        background = "",
        backgroundDesc = "",  -- descripcion (1er parrafo) de un trasfondo PERSONALIZADO; vacio si es del libro
        feats = {},
        xp = 0, -- experiencia acumulada D&D 5e de Harford; la subida sigue siendo manual.
        spellSlots = {}, -- espacios de conjuro gastados por nivel; se restauran en descanso largo.
        -- Espacios CREADOS gastando puntos (Lanzamiento Flexible del Mago, Devocion del
        -- Sacerdote). Van aparte de `spellSlots` para que "gastados" siga siendo un numero no
        -- negativo; suman al maximo y desaparecen en el mismo descanso largo.
        spellSlotsBonus = {},
        -- Espacios de PACTO gastados. Van aparte de `spellSlots` porque recargan en descanso CORTO
        -- y los normales en largo: fusionarlos hacia que un descanso corto devolviese espacios de
        -- OTRA clase en un multiclase de brujo.
        pactSpent = 0,
        activeStates = {},
        activeForm = "", -- forma druidica activa; vacio = forma normal.
        activeFormAction = "",
        activeCompanion = "",    -- criatura acompanante invocada; vacio = ninguna.
        activeCore = "",         -- nucleo demoniaco sostenido; excluyente con activeCompanion.
        -- Contadores "desde el ultimo descanso largo" para rasgos que NO tienen un maximo de usos
        -- y por tanto no encajan en `_featureUses` (que necesita un tope). Ej.: Legado del Vacio,
        -- cuya CD sube 1 por cada uso adicional y solo se corta al fallar la salvacion.
        restCounters = {},
        activeCompanionHP = 0,
    }
end

-- Ids de rasgo renombrados a la convencion <abrevClase>_<abrevSub>_<cosa>. El estado del jugador
-- se guarda POR ID (`choices`, `featureStates`, `featureUses`, `activeStates`), asi que sin esto un
-- personaje perderia su eleccion de Estilo de combate, su brebaje o sus usos por descanso.
--
-- Solo se recorre al migrar desde un esquema anterior a 3: despues, cada perfil ya esta traducido
-- y la tabla no se vuelve a mirar. Se puede borrar cuando no queden perfiles viejos.
local IDS_RENOMBRADOS = {
    ["abrazo_vacio"] = "feat_abrazo_vacio",
    ["acechador"] = "feat_acechador",
    ["actor"] = "feat_actor",
    ["adepto_armas_fuego"] = "feat_adepto_armas_fuego",
    ["adepto_metamagia"] = "feat_adepto_metamagia",
    ["adepto_sobrenatural"] = "feat_adepto_sobrenatural",
    ["afortunado"] = "feat_afortunado",
    ["agilidad_robusta"] = "feat_agilidad_robusta",
    ["alerta"] = "feat_alerta",
    ["amigo_criaturas"] = "feat_amigo_criaturas",
    ["apresador"] = "feat_apresador",
    ["artillero_dote"] = "feat_artillero_dote",
    ["atacante_carga"] = "feat_atacante_carga",
    ["atacante_salvaje"] = "feat_atacante_salvaje",
    ["atleta"] = "feat_atleta",
    ["azote_magos"] = "feat_azote_magos",
    ["centinela"] = "feat_centinela",
    ["cocinero"] = "feat_cocinero",
    ["combatiente_dos_armas"] = "feat_combatiente_dos_armas",
    ["combatiente_montado"] = "feat_combatiente_montado",
    ["cortador"] = "feat_cortador",
    ["depredador_endurecido"] = "feat_depredador_endurecido",
    ["duelista_defensivo"] = "feat_duelista_defensivo",
    ["duro"] = "feat_duro",
    ["envenenador"] = "feat_envenenador",
    ["experto_armas_fuego"] = "feat_experto_armas_fuego",
    ["experto_ballestas"] = "feat_experto_ballestas",
    ["experto_habilidades"] = "feat_experto_habilidades",
    ["explorador_mazmorras"] = "feat_explorador_mazmorras",
    ["fortaleza_enana"] = "feat_fortaleza_enana",
    ["furia_orca"] = "feat_furia_orca",
    ["gran_maestro_armas"] = "feat_gran_maestro_armas",
    ["guia_espiritual"] = "feat_guia_espiritual",
    ["habilidoso"] = "feat_habilidoso",
    ["herencia_darnassiana"] = "feat_herencia_darnassiana",
    ["iniciado_artificiero"] = "feat_iniciado_artificiero",
    ["iniciado_combate"] = "feat_iniciado_combate",
    ["iniciado_magia"] = "feat_iniciado_magia",
    ["lanzador_combate"] = "feat_lanzador_combate",
    ["lanzador_preciso"] = "feat_lanzador_preciso",
    ["lanzador_ritual"] = "feat_lanzador_ritual",
    ["lider_inspirador"] = "feat_lider_inspirador",
    ["ligeramente_acorazado"] = "feat_ligeramente_acorazado",
    ["linguista"] = "feat_linguista",
    ["maestro_armaduras_medias"] = "feat_maestro_armaduras_medias",
    ["maestro_armaduras_pesadas"] = "feat_maestro_armaduras_pesadas",
    ["maestro_armas"] = "feat_maestro_armas",
    ["maestro_armas_asta"] = "feat_maestro_armas_asta",
    ["maestro_armas_exoticas"] = "feat_maestro_armas_exoticas",
    ["maestro_armas_pesadas"] = "feat_maestro_armas_pesadas",
    ["maestro_escudero"] = "feat_maestro_escudero",
    ["maestro_escudos"] = "feat_maestro_escudos",
    ["mago_de_batalla"] = "feat_mago_de_batalla",
    ["maton_taberna"] = "feat_maton_taberna",
    ["mejor_quimica"] = "feat_mejor_quimica",
    ["mente_aguda"] = "feat_mente_aguda",
    ["moderadamente_acorazado"] = "feat_moderadamente_acorazado",
    ["movil"] = "feat_movil",
    ["muy_acorazado"] = "feat_muy_acorazado",
    ["observador"] = "feat_observador",
    ["perforador"] = "feat_perforador",
    ["precision_elfica"] = "feat_precision_elfica",
    ["prodigio"] = "feat_prodigio",
    ["rencor_faccion"] = "feat_rencor_faccion",
    ["resiliente"] = "feat_resiliente",
    ["resistencia_tauren"] = "feat_resistencia_tauren",
    ["resistente"] = "feat_resistente",
    ["sanador"] = "feat_sanador",
    ["telepata"] = "feat_telepata",
    ["telequinetico"] = "feat_telequinetico",
    ["teletransporte_arcano"] = "feat_teletransporte_arcano",
    ["tirador_primera"] = "feat_tirador_primera",
    ["tocado_hadas"] = "feat_tocado_hadas",
    ["tocado_sombras"] = "feat_tocado_sombras",
    ["triturador"] = "feat_triturador",
    ["versado_armas"] = "feat_versado_armas",
    ["versado_elemento"] = "feat_versado_elemento",
    ["afliccion_aflicciones_inestables"] = "bru_afl_aflicciones_inestables",
    ["afliccion_aflicciones_potentes"] = "bru_afl_aflicciones_potentes",
    ["afliccion_drenar_alma"] = "bru_afl_drenar_alma",
    ["armas_calma_mortal"] = "gue_arm_calma_mortal",
    ["armas_golpe_colosal"] = "gue_arm_golpe_colosal",
    ["armas_golpes_de_oportunidad"] = "gue_arm_golpes_de_oportunidad",
    ["armas_grito_de_mando"] = "gue_arm_grito_de_mando",
    ["bestias_vinculo_del_companero"] = "caz_bes_vinculo_del_companero",
    ["brujo_nigromancia_del_vacio_nivel_6"] = "bru_nigromancia_del_vacio_nivel_6",
    ["brujo_nigromancia_del_vacio_nivel_7"] = "bru_nigromancia_del_vacio_nivel_7",
    ["caballero_mu_forja_de_runas_superior"] = "cdm_forja_de_runas_superior",
    ["caballero_mu_sin_muerte"] = "cdm_sin_muerte",
    ["caballero_mu_voluntad_de_la_tumba"] = "cdm_voluntad_de_la_tumba",
    ["cazador_acechador"] = "caz_acechador",
    ["cazador_aspecto_de_lo_salvaje"] = "caz_aspecto_de_lo_salvaje",
    ["cazador_conocimiento_del_depredador"] = "caz_conocimiento_del_depredador",
    ["cazador_demo_alas_demoniacas"] = "dh_alas_demoniacas",
    ["cazador_demo_cuerpo_atemporal"] = "dh_cuerpo_atemporal",
    ["cazador_demo_destreza_illidari"] = "dh_destreza_illidari",
    ["cazador_demo_evasion"] = "dh_evasion",
    ["cazador_demo_mirada_reveladora"] = "dh_mirada_reveladora",
    ["cazador_demo_preparado"] = "dh_preparado",
    ["cazador_demo_purificado_por_las_llamas"] = "dh_purificado_por_las_llamas",
    ["cazador_demo_resiliencia_abisal"] = "dh_resiliencia_abisal",
    ["cazador_demo_un_cazador_por_encima_de_todo"] = "dh_un_cazador_por_encima_de_todo",
    ["cazador_sentidos_agudizados"] = "caz_sentidos_agudizados",
    ["cdm_comando_oscuro"] = "cdm_san_comando_oscuro",
    ["cdm_escarcha_conjuros_3"] = "cdm_esc_conjuros_3",
    ["cdm_escarcha_conjuros_5"] = "cdm_esc_conjuros_5",
    ["cdm_escudo_sangre"] = "cdm_san_escudo_sangre",
    ["cdm_golpe_escarcha"] = "cdm_esc_golpe_escarcha",
    ["cdm_maquina_matar"] = "cdm_esc_maquina_matar",
    ["cdm_portador_plagas"] = "cdm_pro_portador_plagas",
    ["cdm_profana_conjuros_3"] = "cdm_pro_conjuros_3",
    ["cdm_profana_conjuros_5"] = "cdm_pro_conjuros_5",
    ["cdm_sangre_conjuros_3"] = "cdm_san_conjuros_3",
    ["cdm_sangre_conjuros_5"] = "cdm_san_conjuros_5",
    ["cervecero_brebajes_elusivos"] = "monje_cer_brebajes_elusivos",
    ["cervecero_elaboracion_ligera"] = "monje_cer_elaboracion_ligera",
    ["demonologia_furia_demoniaca"] = "bru_dem_furia_demoniaca",
    ["demonologia_grimorio_de_supremacia"] = "bru_dem_grimorio_de_supremacia",
    ["demonologia_somos_legion"] = "bru_dem_somos_legion",
    ["destruccion_infierno"] = "bru_des_infierno",
    ["destruccion_llamas_de_xerrath"] = "bru_des_llamas_de_xerrath",
    ["destruccion_resolucion_inquebrantable"] = "bru_des_resolucion_inquebrantable",
    ["disciplina_absolucion_penitencia"] = "sac_dis_absolucion_penitencia",
    ["disciplina_castigo"] = "sac_dis_castigo",
    ["disciplina_claridad_de_voluntad"] = "sac_dis_claridad_de_voluntad",
    ["disciplina_expiacion"] = "sac_dis_expiacion",
    ["druida_alma_del_bosque"] = "dru_alma_del_bosque",
    ["druida_cuerpo_atemporal"] = "dru_cuerpo_atemporal",
    ["equilibrio_bendicion_de_los_ancestros"] = "dru_eq_bendicion_de_los_ancestros",
    ["equilibrio_encarnacion_elegido_de_elune"] = "dru_eq_encarnacion_elegido_de_elune",
    ["equilibrio_influencia_astral"] = "dru_eq_influencia_astral",
    ["escarcha_anillo_de_escarcha"] = "mago_esc_anillo_de_escarcha",
    ["escarcha_corazon_congelado"] = "cdm_esc_corazon_congelado",
    ["escarcha_garras_de_hielo"] = "cdm_esc_garras_de_hielo",
    ["escarcha_invierno_implacable"] = "cdm_esc_invierno_implacable",
    ["escarcha_manos_de_escarcha"] = "mago_esc_manos_de_escarcha",
    ["escarcha_pilar_de_escarcha"] = "cdm_esc_pilar_de_escarcha",
    ["feral_afinidad_superior_feral_o_guar"] = "dru_fer_afinidad_superior_feral_o_guar",
    ["feral_encarnacion_guardian_de_las_ti"] = "dru_fer_encarnacion_guardian_de_las_ti",
    ["feral_mutilacion_brutal"] = "dru_fer_mutilacion_brutal",
    ["fuego_combustion"] = "mago_fue_combustion",
    ["fuego_prender"] = "mago_fue_prender",
    ["furia_berserker_enloquecido"] = "gue_fur_berserker_enloquecido",
    ["furia_critico_devastador"] = "gue_fur_critico_devastador",
    ["furia_furia_focalizada"] = "gue_fur_furia_focalizada",
    ["furia_sed_de_sangre"] = "gue_fur_sed_de_sangre",
    ["guerrero_accion_adicional"] = "gue_accion_adicional",
    ["guerrero_arquetipo_marcial"] = "gue_arquetipo_marcial",
    ["guerrero_ataque_extra"] = "gue_ataque_extra",
    ["guerrero_ataque_extra_2"] = "gue_ataque_extra_2",
    ["guerrero_estilo_combate"] = "gue_estilo_combate",
    ["guerrero_furia_interna"] = "gue_furia_interna",
    ["guerrero_segundo_aliento"] = "gue_segundo_aliento",
    ["pal_proteccion_conjuros_3"] = "pal_pro_conjuros_3",
    ["pal_proteccion_conjuros_5"] = "pal_pro_conjuros_5",
    ["pal_represion_conjuros_3"] = "pal_ret_conjuros_3",
    ["pal_represion_conjuros_5"] = "pal_ret_conjuros_5",
    ["pal_sagrado_conjuros_3"] = "pal_sag_conjuros_3",
    ["pal_sagrado_conjuros_5"] = "pal_sag_conjuros_5",
    ["paladin_aura_de_coraje"] = "pal_aura_de_coraje",
    ["paladin_toque_purificador"] = "pal_toque_purificador",
    ["picaro_anticipacion"] = "pic_anticipacion",
    ["picaro_esquivo"] = "pic_esquivo",
    ["picaro_evasion"] = "pic_evasion",
    ["picaro_golpe_de_suerte"] = "pic_golpe_de_suerte",
    ["proteccion_golpes_atenuados"] = "gue_pro_golpes_atenuados",
    ["proteccion_interceptar"] = "gue_pro_interceptar",
    ["proteccion_nunca_te_rindas"] = "gue_pro_nunca_te_rindas",
    ["proteccion_presencia_inspiradora"] = "gue_pro_presencia_inspiradora",
    ["punteria_aspecto_del_aguila"] = "caz_pun_aspecto_del_aguila",
    ["punteria_ataque_multiple"] = "caz_pun_ataque_multiple",
    ["punteria_enfoque_del_tirador"] = "caz_pun_enfoque_del_tirador",
    ["restauracion_corteza_de_hierro"] = "dru_res_corteza_de_hierro",
    ["restauracion_encarnacion_arbol_de_vida"] = "dru_res_encarnacion_arbol_de_vida",
    ["restauracion_guardia_cenarion"] = "dru_res_guardia_cenarion",
    ["restauracion_rejuvenecimiento"] = "dru_res_rejuvenecimiento",
    ["restauracion_tranquilidad"] = "dru_res_tranquilidad",
    ["sac_disciplina_conjuros_1"] = "sac_dis_conjuros_1",
    ["sac_disciplina_conjuros_3"] = "sac_dis_conjuros_3",
    ["sac_disciplina_conjuros_5"] = "sac_dis_conjuros_5",
    ["sac_sagrado_conjuros_1"] = "sac_sag_conjuros_1",
    ["sac_sagrado_conjuros_3"] = "sac_sag_conjuros_3",
    ["sac_sagrado_conjuros_5"] = "sac_sag_conjuros_5",
    ["sac_sombra_conjuros_1"] = "sac_som_conjuros_1",
    ["sac_sombra_conjuros_3"] = "sac_som_conjuros_3",
    ["sac_sombra_conjuros_5"] = "sac_som_conjuros_5",
    ["sangre_arma_runica_danza"] = "cdm_san_arma_runica_danza",
    ["sangre_golpe_al_corazon"] = "cdm_san_golpe_al_corazon",
    ["sangre_purgatorio"] = "cdm_san_purgatorio",
    ["sangre_tormenta_de_huesos"] = "cdm_san_tormenta_de_huesos",
    ["sombra_mente_dominante"] = "sac_som_mente_dominante",
    ["sombra_rendicion_a_la_locura"] = "sac_som_rendicion_a_la_locura",
    ["supervivencia_camuflaje_natural"] = "caz_sup_camuflaje_natural",
    ["supervivencia_contraataque_marcado"] = "caz_sup_contraataque_marcado",
    ["supervivencia_terminos_de_compromiso"] = "caz_sup_terminos_de_compromiso",
    ["tejedor_anillo_de_paz"] = "monje_tej_anillo_de_paz",
    ["tejedor_estatua_del_dragon_de_jade"] = "monje_tej_estatua_del_dragon_de_jade",
    ["venganza_aura_de_inmolacion"] = "dh_ven_aura_de_inmolacion",
    ["venganza_ultimo_recurso"] = "dh_ven_ultimo_recurso",
}

-- Traduce las claves de una tabla indexada por id de rasgo. Reconstruye en una tabla NUEVA: anadir
-- claves mientras se itera con pairs() sobre la misma es comportamiento indefinido en Lua 5.1.
-- `data.feats` es una LISTA de ids, no una tabla indexada por id: se traduce por valor.
local function RenombrarValores(t)
    if type(t) ~= "table" then return t, 0 end
    local n = 0
    for i = 1, #t do
        local nuevo = IDS_RENOMBRADOS[t[i]]
        if nuevo then t[i] = nuevo n = n + 1 end
    end
    return t, n
end

local function RenombrarClaves(t)
    if type(t) ~= "table" then return t, 0 end
    local fuera, n = {}, 0
    for k, v in pairs(t) do
        local nuevo = IDS_RENOMBRADOS[k]
        if nuevo then n = n + 1 end
        fuera[nuevo or k] = v
    end
    return fuera, n
end

-- Ids de HERRAMIENTA renombrados a `her_`. Van aparte de IDS_RENOMBRADOS porque no se guardan como
-- CLAVE sino como VALOR: la opcion elegida en una eleccion de competencia con herramientas
-- (`choices["bg_des_herr"] = { "instrumento" }`). Ocho de estos ids existen tambien como profesion,
-- asi que traducirlos por su nombre suelto habria sido ambiguo.
local HERRAMIENTAS_RENOMBRADAS = {
    ["albanil"] = "her_albanil",
    ["alfarero"] = "her_alfarero",
    ["alquimista"] = "her_alquimista",
    ["armero"] = "her_armero",
    ["caligrafia"] = "her_caligrafia",
    ["carpintero"] = "her_carpintero",
    ["cartografo"] = "her_cartografo",
    ["cervecero"] = "her_cervecero",
    ["cocinero"] = "her_cocinero",
    ["curtidor"] = "her_curtidor",
    ["disfraz"] = "her_disfraz",
    ["envenenador"] = "her_envenenador",
    ["falsificacion"] = "her_falsificacion",
    ["herborista"] = "her_herborista",
    ["herrero"] = "her_herrero",
    ["hojalatero"] = "her_hojalatero",
    ["instrumento"] = "her_instrumento",
    ["joyero"] = "her_joyero",
    ["juego"] = "her_juego",
    ["ladron"] = "her_ladron",
    ["navegante"] = "her_navegante",
    ["pintor"] = "her_pintor",
    ["soplavidrio"] = "her_soplavidrio",
    ["tallador"] = "her_tallador",
    ["tejedor"] = "her_tejedor",
    ["vehiculos_agua"] = "her_vehiculos_agua",
    ["vehiculos_tierra"] = "her_vehiculos_tierra",
    ["zapatero"] = "her_zapatero",
}

-- Las elecciones guardan LISTAS de ids de opcion. Se traducen sus valores.
local function RenombrarOpciones(choices)
    if type(choices) ~= "table" then return 0 end
    local n = 0
    for _, lista in pairs(choices) do
        if type(lista) == "table" then
            for i = 1, #lista do
                local nuevo = HERRAMIENTAS_RENOMBRADAS[lista[i]]
                if nuevo then lista[i] = nuevo n = n + 1 end
            end
        end
    end
    return n
end

-- Entidades de RAZA renombradas a `raza_`. Se guardan como CAMPO (`data.race.id`,
-- `data.race.subraceId`), no como clave ni como valor de lista, asi que llevan su propia
-- traduccion. La subraza incluye su raza padre porque `humano` era raza Y subraza (Renegado
-- Humano): sin eso, los dos destinos serian el mismo.
local RAZAS_RENOMBRADAS = {
    ["altonato"] = "raza_elfo_noche_altonato",
    ["bosque"] = "raza_trol_bosque",
    ["cazadores"] = "raza_orco_cazadores",
    ["draenei"] = "raza_draenei",
    ["elfo"] = "raza_renegado_elfo",
    ["elfo_noche"] = "raza_elfo_noche",
    ["elfo_sangre"] = "raza_elfo_sangre",
    ["elfo_vacio"] = "raza_elfo_vacio",
    ["enano"] = "raza_enano",
    ["exodar"] = "raza_draenei_exodar",
    ["forjado_luz"] = "raza_draenei_forjado_luz",
    ["forjaz"] = "raza_enano_forjaz",
    ["gnomeregan"] = "raza_gnomo_gnomeregan",
    ["gnomo"] = "raza_gnomo",
    ["goblin"] = "raza_goblin",
    ["guerreros"] = "raza_orco_guerreros",
    ["hielo"] = "raza_trol_hielo",
    ["hierro_negro"] = "raza_enano_hierro_negro",
    ["huargen"] = "raza_huargen",
    ["humano"] = "raza_humano",
    ["jungla"] = "raza_trol_jungla",
    ["man_ari"] = "raza_draenei_man_ari",
    ["martillo_salvaje"] = "raza_enano_martillo_salvaje",
    ["mecagnomo"] = "raza_gnomo_mecagnomo",
    ["misticos"] = "raza_orco_misticos",
    ["monte_alto"] = "raza_tauren_monte_alto",
    ["mulgore"] = "raza_tauren_mulgore",
    ["nocheterna"] = "raza_nocheterna",
    ["orco"] = "raza_orco",
    ["pandaren"] = "raza_pandaren",
    ["renegado"] = "raza_renegado",
    ["semielfo"] = "raza_semielfo",
    ["tabido"] = "raza_draenei_tabido",
    ["taunka"] = "raza_tauren_taunka",
    ["tauren"] = "raza_tauren",
    ["trol"] = "raza_trol",
    ["vulpera"] = "raza_vulpera",
    ["zandalari"] = "raza_trol_zandalari",
}

local SUBRAZAS_RENOMBRADAS = {
    ["altonato"] = "raza_elfo_noche_altonato",
    ["bosque"] = "raza_trol_bosque",
    ["cazadores"] = "raza_orco_cazadores",
    ["elfo"] = "raza_renegado_elfo",
    ["elfo_noche"] = "raza_elfo_noche",
    ["elfo_sangre"] = "raza_elfo_sangre",
    ["elfo_vacio"] = "raza_elfo_vacio",
    ["exodar"] = "raza_draenei_exodar",
    ["forjado_luz"] = "raza_draenei_forjado_luz",
    ["forjaz"] = "raza_enano_forjaz",
    ["gnomeregan"] = "raza_gnomo_gnomeregan",
    ["guerreros"] = "raza_orco_guerreros",
    ["hielo"] = "raza_trol_hielo",
    ["hierro_negro"] = "raza_enano_hierro_negro",
    ["humano"] = "raza_renegado_humano",
    ["jungla"] = "raza_trol_jungla",
    ["man_ari"] = "raza_draenei_man_ari",
    ["martillo_salvaje"] = "raza_enano_martillo_salvaje",
    ["mecagnomo"] = "raza_gnomo_mecagnomo",
    ["misticos"] = "raza_orco_misticos",
    ["monte_alto"] = "raza_tauren_monte_alto",
    ["mulgore"] = "raza_tauren_mulgore",
    ["tabido"] = "raza_draenei_tabido",
    ["taunka"] = "raza_tauren_taunka",
    ["zandalari"] = "raza_trol_zandalari",
}

local function RenombrarRaza(race)
    if type(race) ~= "table" then return 0 end
    local n = 0
    local r = RAZAS_RENOMBRADAS[race.id]
    if r then race.id = r n = n + 1 end
    local s = SUBRAZAS_RENOMBRADAS[race.subraceId]
    if s then race.subraceId = s n = n + 1 end
    return n
end

-- `silencioso`: la ficha que se migra no es la tuya. El snapshot de inspeccion pasa por aqui para
-- que sus ids viejos se lean bien, pero anunciar "Ficha actualizada" mientras miras a otro no
-- significa nada para quien lo lee: parecia que se te habia tocado la tuya.
-- `slot` es el hueco del perfil, que es donde viven los usos por descanso: la progresion no los
-- tiene, asi que sin el no se les puede renombrar nada.
local function Migrate(data, silencioso, slot)
    if type(data) ~= "table" then data = EmptyProgression() end
    local oldSchema = tonumber(data.schema) or 0

    -- COPIA ANTES DE TOCAR NADA. La migracion reescribe la ficha en el sitio, corre sola al primer
    -- acceso y no se puede repetir: si un renombrado sale mal, el rasgo desaparece sin dar error y
    -- sin nada a lo que volver. La copia se guarda con la propia ficha, asi que sobrevive al
    -- /reload y se restaura sin depender de que alguien se acordara de copiar el WTF.
    --
    -- Se guarda SOLO la anterior: encadenar copias de copias creceria sin limite y la util es la
    -- de justo antes del cambio que rompio algo.
    -- Las fotos de INSPECCION llegan sin `schema`, asi que contaban como viejas y cada una
    -- duplicaba la ficha entera. Son efimeras y de otro jugador: no hay nada que rescatar.
    local previo
    if oldSchema < SCHEMA_VERSION and not silencioso then
        local limpio = {}
        for k, v in pairs(data) do
            if k ~= "_previo" then limpio[k] = v end
        end
        previo = CopyTable(limpio)
    end
    if type(data.classLevels) ~= "table" then data.classLevels = {} end
    -- El progreso de jugador esta limitado a nivel total 20. Normalizar tambien perfiles
    -- antiguos/importados para que no sobreviva una multiclase invalida al nuevo contrato.
    do
        local normalized, total = {}, 0
        for _, entry in ipairs(data.classLevels) do
            if type(entry) == "table" and total < MAX_TOTAL_LEVEL then
                local level = math.floor(tonumber(entry.level) or 1)
                level = math.max(1, math.min(20, level, MAX_TOTAL_LEVEL - total))
                entry.level = level
                normalized[#normalized + 1] = entry
                total = total + level
            end
        end
        data.classLevels = normalized
    end
    if type(data.featureStates) ~= "table" then data.featureStates = {} end
    if type(data.choices) ~= "table" then data.choices = {} end
    if type(data.importedProficiencies) ~= "table" then data.importedProficiencies = {} end
    if type(data.importedProficiencies.skillRank) ~= "table" then data.importedProficiencies.skillRank = {} end
    if type(data.importedProficiencies.saveProf) ~= "table" then data.importedProficiencies.saveProf = {} end
    if type(data.importedProficiencies.armorProf) ~= "table" then data.importedProficiencies.armorProf = {} end
    if type(data.importedProficiencies.weaponProf) ~= "table" then data.importedProficiencies.weaponProf = {} end
    if type(data.importedProficiencies.toolProf) ~= "table" then data.importedProficiencies.toolProf = {} end
    if type(data.importedProficiencies.languages) ~= "table" then data.importedProficiencies.languages = {} end
    if type(data.importedProficiencies.professions) ~= "table" then data.importedProficiencies.professions = {} end
    if type(data.race) ~= "table" then data.race = { id = "", subraceId = "" } end
    data.race.id = tostring(data.race.id or "")
    data.race.subraceId = tostring(data.race.subraceId or "")
    data.background = tostring(data.background or "")
    data.backgroundDesc = tostring(data.backgroundDesc or "")
    if type(data.feats) ~= "table" then data.feats = {} end
    data.xp = math.max(0, math.floor(tonumber(data.xp) or 0))
    -- `useMana` fue una eleccion por ficha en versiones anteriores. El modo de coste es
    -- ahora global (HarfordConfig.spell_cost_mode), asi que se descarta al migrar.
    data.useMana = nil
    if type(data.spellSlots) ~= "table" then data.spellSlots = {} end
    if type(data.spellSlotsBonus) ~= "table" then data.spellSlotsBonus = {} end
    data.pactSpent = math.max(0, math.floor(tonumber(data.pactSpent) or 0))
    -- Reconstruir en una tabla nueva: añadir claves nuevas mientras se itera con pairs() sobre la
    -- misma tabla es comportamiento indefinido en Lua 5.1 (podia perder/duplicar espacios gastados).
    do
        local migrated = {}
        for level, spent in pairs(data.spellSlots) do
            local numericLevel = math.floor(tonumber(level) or 0)
            local n = math.max(0, math.floor(tonumber(spent) or 0))
            if numericLevel >= 1 and numericLevel <= 9 and n > 0 then
                migrated[numericLevel] = n
            end
        end
        data.spellSlots = migrated
    end
    -- Renombrado de ids: solo al venir de un esquema anterior.
    if oldSchema < 3 then
        local total = 0
        for _, campo in ipairs({ "choices", "featureStates", "activeStates" }) do
            if type(data[campo]) == "table" then
                local nuevo, n = RenombrarClaves(data[campo])
                data[campo] = nuevo
                total = total + n
            end
        end
        -- Los usos por descanso NO viven en la progresion sino en el perfil, asi que buscarlos en
        -- `data` era un no-op: los gastados volvian a estar llenos y las claves viejas se quedaban.
        if slot and type(slot._featureUses) == "table" then
            local nuevo, n = RenombrarClaves(slot._featureUses)
            slot._featureUses = nuevo
            total = total + n
        end
        local _, nf = RenombrarValores(data.feats)
        total = total + nf
        total = total + RenombrarOpciones(data.choices)
        total = total + RenombrarRaza(data.race)
        if total > 0 and not silencioso and HarfordChat and HarfordChat.Print then
            HarfordChat.Print(("Ficha actualizada: %d rasgo(s) renombrados a la convencion nueva."):format(total))
            HarfordChat.Print("Se ha guardado una copia de la ficha anterior. Si algo no cuadra: "
                .. "|cffffd100/harford debug run fichaprevia|r")
        end
    end
    if previo then
        data._previo = { schema = oldSchema, cuando = (time and time()) or 0, datos = previo }
    end
    data.schema = SCHEMA_VERSION
    if type(data.activeStates) ~= "table" then data.activeStates = {} end
    data.activeForm = tostring(data.activeForm or "")
    data.activeFormAction = tostring(data.activeFormAction or "")
    data.activeCompanion = tostring(data.activeCompanion or "")
    data.activeCore = tostring(data.activeCore or "")
    if type(data.restCounters) ~= "table" then data.restCounters = {} end
    data.activeCompanionHP = math.max(0, math.floor(tonumber(data.activeCompanionHP) or 0))
    return data
end

local function ClampLevel(level)
    level = math.floor(tonumber(level) or 1)
    if level < 1 then return 1 end
    if level > 20 then return 20 end
    return level
end

-- Override EFIMERO (no persistido) para inspeccion read-only. Cuando inspeccionas a
-- otro jugador, su progresion vive aqui (keyed por nombre corto) y NO se escribe en
-- HarfordDnDPersistStore. El panel lee normal via API.Get y obtiene el snapshot.
local inspectData = {}

local function ShortKey(name)
    name = tostring(name or "")
    if Ambiguate then
        local short = Ambiguate(name, "short")
        if short and short ~= "" then return short end
    end
    return name:match("^[^%-]+") or name
end

-- Invalida la memoizacion de FeatureEffects tras cualquier cambio de progresion.
local function Touch(profileName)
    local resolvedName = ResolveProfileName(profileName)
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
        if HarfordDnDFeatureEffects.Prime then
            HarfordDnDFeatureEffects.Prime(resolvedName)
        end
    end
    if HarfordDnDStore and HarfordDnDStore.ReconcileDerivedResources then
        HarfordDnDStore.ReconcileDerivedResources(resolvedName, "progression")
    end
    -- El texto de la barra de XP depende tambien del nivel total (aviso de subida
    -- disponible), no solo de `xp`. Refrescarla al editar clases, raza o elecciones.
    if HarfordCharacterXP and HarfordCharacterXP.Refresh then
        HarfordCharacterXP.Refresh()
    end
end

function API.SetInspectData(name, data)
    local key = ShortKey(name)
    if key == "" then return false end
    inspectData[key] = (type(data) == "table") and Migrate(CopyTable(data), true) or nil
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
        if HarfordDnDFeatureEffects.Prime then
            HarfordDnDFeatureEffects.Prime(name)
        end
    end
    return true
end

function API.ClearInspectData(name)
    if name ~= nil then
        inspectData[ShortKey(name)] = nil
    else
        inspectData = {}
    end
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
    end
end

function API.Get(profileName)
    local name = ResolveProfileName(profileName)
    local ins = inspectData[ShortKey(name)]
    if ins then return ins, name end  -- modo inspeccion: snapshot efimero, sin tocar persistencia
    local slot = ProfileSlot(name)
    slot._progression = Migrate(slot._progression, nil, slot)
    return slot._progression, name
end

-- Copia de la ficha de justo antes de la ultima migracion, si la hubo.
function API.GetPreviousProgression(profileName)
    local name = ResolveProfileName(profileName)
    local slot = ProfileSlot(name)
    local prev = slot._progression and slot._progression._previo
    if type(prev) ~= "table" or type(prev.datos) ~= "table" then return nil, name end
    return prev, name
end

-- Devuelve la ficha al estado anterior a la migracion. NO migra al restaurar: se deja tal cual
-- estaba, para poder mirarla. Volvera a migrarse al siguiente acceso, asi que esto sirve para
-- comparar y para recuperar algo concreto, no para quedarse en el esquema viejo.
function API.RestorePreviousProgression(profileName)
    local prev, name = API.GetPreviousProgression(profileName)
    if not prev then return false, "No hay copia anterior de " .. tostring(name) end
    local slot = ProfileSlot(name)
    slot._progression = CopyTable(prev.datos)
    Touch(name)
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
    end
    return true, name
end

function API.Set(profileName, data)
    local name = ResolveProfileName(profileName)
    local slot = ProfileSlot(name)
    -- Con el hueco: `Migrate` sella el esquema SIEMPRE y el renombrado de usos por descanso solo
    -- corre con el esquema viejo. Una ficha que llegara por aqui antes de leerse gastaba la ventana
    -- y el renombrado ya no ocurria nunca.
    slot._progression = Migrate(CopyTable(data), nil, slot)
    Touch(name)
    return slot._progression, name
end

-- XP acumulada de Harford. Se centraliza aqui para conservar la invalidacion y la
-- persistencia del perfil aunque la UI que la modifica no este abierta.
function API.SetXP(amount, profileName)
    local data, name = API.Get(profileName)
    if not data then return false end
    data.xp = math.max(0, math.floor(tonumber(amount) or 0))
    Touch(name)
    return true, data.xp
end

function API.HasProgression(profileName)
    local inspect = inspectData[ShortKey(ResolveProfileName(profileName))]
    if type(inspect) == "table" and type(inspect.classLevels) == "table" and #inspect.classLevels > 0 then
        return true
    end
    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
    local slot = profiles and profiles[ResolveProfileName(profileName)]
    local data = slot and slot._progression
    return type(data) == "table" and type(data.classLevels) == "table" and #data.classLevels > 0
end

-- TRP3 es un indice de la ficha, no puede expresar de forma fiable todas las
-- elecciones del Libro (por ejemplo, una mejora de caracteristica). Este
-- marcador permite que la UI no las presente como pendientes tras importar.
function API.IsImportedFromTRP3(profileName)
    local name = ResolveProfileName(profileName)
    local inspect = inspectData[ShortKey(name)]
    if type(inspect) == "table" then
        return inspect.importedFromTRP3 == true
    end
    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
    local slot = profiles and profiles[name]
    local data = slot and slot._progression
    return type(data) == "table" and data.importedFromTRP3 == true
end

function API.GetClassLevels(profileName)
    local data = API.Get(profileName)
    return data.classLevels
end

function API.GetTotalLevel(profileName)
    local data = API.Get(profileName)
    local total = 0
    for _, entry in ipairs(data.classLevels or {}) do
        total = total + (tonumber(entry.level) or 0)
    end
    return total
end

function API.GetProficiencyBonus(profileName)
    local level = API.GetTotalLevel(profileName)
    if level <= 0 then return nil end
    if level <= 4 then return 2 end
    if level <= 8 then return 3 end
    if level <= 12 then return 4 end
    if level <= 16 then return 5 end
    if level <= 20 then return 6 end
    if level <= 24 then return 7 end
    if level <= 28 then return 8 end
    return 9
end

function API.SetClassEntry(index, classId, subclassId, level, profileName)
    local data = API.Get(profileName)
    index = math.floor(tonumber(index) or (#data.classLevels + 1))
    if index < 1 then index = 1 end
    -- Nunca dejar huecos: `classLevels` se recorre con ipairs (nivel total, PG, sync), y un
    -- indice salteado cortaria el recorrido en el hueco y falsearia esos calculos en silencio.
    if index > #data.classLevels + 1 then index = #data.classLevels + 1 end

    local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(classId)
    if not classDef then return false, "Clase invalida" end

    local requestedLevel = ClampLevel(level)
    local previous = data.classLevels[index]
    local previousLevel = previous and math.max(0, math.floor(tonumber(previous.level) or 0)) or 0
    local currentTotal = API.GetTotalLevel(profileName)
    if currentTotal - previousLevel + requestedLevel > MAX_TOTAL_LEVEL then
        return false, "El nivel total maximo es " .. tostring(MAX_TOTAL_LEVEL)
    end

    local entry = {
        classId = classDef.id,
        subclassId = subclassId == nil and (HarfordDnDBook.GetDefaultSubclassId(classDef.id) or "")
            or ((HarfordDnDBook.NormalizeSubclassId and HarfordDnDBook.NormalizeSubclassId(classDef.id, subclassId)) or tostring(subclassId or "")),
        level = requestedLevel,
    }
    data.classLevels[index] = entry
    Touch(profileName)
    return true, entry
end

function API.RemoveClassEntry(index, profileName)
    local data = API.Get(profileName)
    index = math.floor(tonumber(index) or 0)
    if index < 1 or index > #data.classLevels then return false end
    table.remove(data.classLevels, index)
    Touch(profileName)
    return true
end

function API.SetFeatureEnabled(featureId, enabled, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    if featureId == "" then return false end
    data.featureStates[featureId] = enabled and true or false
    Touch(profileName)
    return true
end

function API.IsFeatureEnabled(feature, profileName)
    if not feature or not feature.id then return false end
    local data = API.Get(profileName)
    -- Una subclase especial puede exigir raza concreta. Durante una importacion
    -- incompleta no bloqueamos la ficha; una raza ya conocida distinta si la bloquea.
    -- Lista de razas admitidas (dotes raciales): casa contra raza O subraza.
    if type(feature.requiredRaces) == "table" and #feature.requiredRaces > 0
        and data.race and data.race.id ~= "" then
        local ok = false
        for _, id in ipairs(feature.requiredRaces) do
            if tostring(id) == tostring(data.race.id)
                or tostring(id) == tostring(data.race.subraceId or "") then ok = true break end
        end
        if not ok then return false end
    end
    if feature.requiredRace and data.race and data.race.id ~= ""
        and tostring(data.race.id) ~= tostring(feature.requiredRace) then
        return false
    end
    -- Nucleo demoniaco del Brujo: los cinco rasgos existen desde nivel 2, pero solo cuenta el
    -- del nucleo que sostienes. Sin esto, sus `spellGrants` darian los conjuros de los cinco a la
    -- vez, cuando el manual deja llevar uno.
    if feature.requiredCore and tostring(data.activeCore or "") ~= tostring(feature.requiredCore) then
        return false
    end
    local value = data.featureStates[feature.id]
    if value ~= nil then return value == true end
    -- Los rasgos desbloqueados son funcionales por defecto. `featureStates` es estado
    -- interno para elecciones que se desactiven expresamente, no una segunda puerta
    -- que obligue a guardar `true` para cada accion, reaccion o uso limitado.
    return true
end

-- Elecciones de un rasgo: lista de optionId por slot. choices[featureId] = { ... }.
-- Devuelve las opciones elegidas COMPACTADAS. `choices[featureId]` esta indexado por SLOT y el
-- desplegable por slot del panel permite dejar huecos (poner el 2 sin el 1). Los consumidores
-- recorren la lista con `ipairs`, que se detiene en el primer hueco: con el slot 1 vacio la
-- eleccion entera se comportaba como si no existiera -- sin efecto, sin salir en el About y
-- marcada como pendiente en el Libro. Compactar aqui lo arregla para TODOS a la vez.
function API.GetChoice(featureId, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    local slots = data.choices[featureId]
    if type(slots) ~= "table" then return {} end
    local out = {}
    for i = 1, 20 do
        local v = slots[i]
        if v ~= nil and v ~= "" then out[#out + 1] = v end
    end
    -- Claves no numericas (importaciones antiguas): se conservan al final para no perderlas.
    for k, v in pairs(slots) do
        if type(k) ~= "number" and v ~= nil and v ~= "" then out[#out + 1] = v end
    end
    return out
end

-- La misma tabla pero SIN compactar, indexada por hueco. La necesita quien pinta un control por
-- hueco; `GetChoice` no sirve ahi porque mueve las elecciones de sitio.
function API.GetChoiceSlotMap(featureId, profileName)
    local data = API.Get(profileName)
    local slots = data.choices[tostring(featureId or "")]
    if type(slots) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(slots) do
        if type(k) == "number" and v ~= nil and v ~= "" then out[k] = v end
    end
    return out
end

function API.SetChoiceSlot(featureId, slotIndex, optionId, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    slotIndex = math.floor(tonumber(slotIndex) or 0)
    if featureId == "" or slotIndex < 1 then return false end
    if type(data.choices[featureId]) ~= "table" then data.choices[featureId] = {} end
    optionId = tostring(optionId or "")
    if optionId == "" then
        data.choices[featureId][slotIndex] = nil
    else
        data.choices[featureId][slotIndex] = optionId
    end
    Touch(profileName)
    return true
end

-- Raza del perfil (id + subraza). Solo runtime/persistido, sin nivel.
function API.GetRace(profileName)
    local data = API.Get(profileName)
    return data.race
end

function API.SetRace(raceId, subraceId, profileName)
    local data = API.Get(profileName)
    raceId = tostring(raceId or "")
    local raceDef = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(raceId)
    data.race.id = raceDef and raceDef.id or raceId
    if subraceId == nil then
        data.race.subraceId = HarfordDnDRaces and HarfordDnDRaces.GetDefaultSubraceId
            and HarfordDnDRaces.GetDefaultSubraceId(data.race.id) or ""
    else
        data.race.subraceId = tostring(subraceId)
    end
    Touch(profileName)
    return true
end

-- Reemplaza el estado derivable de una ficha nueva de una vez. La creacion usa
-- este punto unico para no dejar clases, elecciones o estados activos de una
-- ficha anterior mezclados con el nuevo personaje.
function API.ReplaceCreation(draft, profileName)
    if type(draft) ~= "table" then return false, "Borrador invalido." end
    local data = API.Get(profileName)
    data.classLevels = {}
    data.featureStates = {}
    data.choices = {}
    data.importedProficiencies = EmptyProgression().importedProficiencies
    data.feats = {}
    data.spellSlots = {}
    data.spellSlotsBonus = {}
    data.pactSpent = nil
    data.activeStates = {}
    data.activeForm = ""
    data.activeFormAction = ""
    data.importedFromTRP3 = nil

    API.SetRace(draft.raceId, draft.subraceId, profileName)
    API.SetBackground(draft.backgroundId, profileName)
    -- Despues de SetBackground, que borra la variante del trasfondo anterior.
    API.SetBackgroundVariant(draft.backgroundVariantId, profileName)
    for index, entry in ipairs(draft.classes or {}) do
        local ok, err = API.SetClassEntry(index, entry.classId, entry.subclassId, entry.level, profileName)
        if not ok then return false, err end
    end
    for featureId, selections in pairs(draft.choices or {}) do
        -- `pairs`, no `ipairs`: `choices` esta indexado por HUECO y un hueco vacio corta el
        -- recorrido, dejando fuera las elecciones posteriores. Este mismo fichero lo documenta.
        for slot, optionId in pairs(selections or {}) do
            if type(slot) == "number" then
                API.SetChoiceSlot(featureId, slot, optionId, profileName)
                -- Una DOTE elegida no se aplica sola: su opcion no lleva `effects`, lo que aplica
                -- son los rasgos de la dote via `feats`. Aqui se vaciaba `data.feats` y no se
                -- volvia a escribir, asi que una dote elegida en creacion se perdia al aplicarla.
                local feature = HarfordDnDBook and HarfordDnDBook.GetFeature
                    and HarfordDnDBook.GetFeature(featureId)
                local opcion = feature and HarfordDnDBook.GetChoiceOption
                    and HarfordDnDBook.GetChoiceOption(feature, optionId)
                if opcion and opcion.feat then API.SetFeatEnabled(opcion.feat, true, profileName) end
            end
        end
    end
    Touch(profileName)
    return true
end

-- Trasfondo del perfil. Solo runtime/persistido, sin nivel.
function API.GetBackground(profileName)
    local data = API.Get(profileName)
    return data.background
end

function API.SetBackground(backgroundId, profileName)
    local data = API.Get(profileName)
    backgroundId = tostring(backgroundId or "")
    local bgDef = HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(backgroundId)
    data.background = bgDef and bgDef.id or backgroundId
    -- Al fijar un trasfondo (del libro o ninguno) se limpia la desc personalizada;
    -- SeedFromTRP3 la re-asigna despues si el trasfondo cargado es personalizado.
    data.backgroundDesc = ""
    -- La variante pertenece al trasfondo anterior: cambiar de trasfondo la invalida.
    data.backgroundVariant = nil
    Touch(profileName)
    return true
end

-- Variante de trasfondo (Criminal -> Espia, Noble -> Caballero nobiliario...). Es OPCIONAL.
-- La mayoria son narrativas, pero una variante puede declarar `traits` propios que SUSTITUYEN
-- a los del base (Veterano Harford): por eso la variante viaja a todos los consumidores de
-- rasgos de trasfondo. Se guarda unicamente cuando hay una elegida — la clave se BORRA al
-- deseleccionar, en vez de dejar "" en las SavedVariables.
function API.GetBackgroundVariant(profileName)
    local data = API.Get(profileName)
    return data.backgroundVariant or ""
end

function API.SetBackgroundVariant(variantId, profileName)
    local data = API.Get(profileName)
    variantId = tostring(variantId or "")
    if variantId == "" then
        data.backgroundVariant = nil
    else
        data.backgroundVariant = variantId
    end
    Touch(profileName)
    return true
end

-- Descripcion (1er parrafo) de un trasfondo personalizado. Solo se usa para el tooltip
-- cuando el trasfondo no esta en el libro (los del libro usan su propia desc).
function API.GetBackgroundDesc(profileName)
    local data = API.Get(profileName)
    return data.backgroundDesc or ""
end

function API.SetBackgroundDesc(desc, profileName)
    local data = API.Get(profileName)
    data.backgroundDesc = tostring(desc or "")
    Touch(profileName)
    return true
end

local function BackgroundIsFromBook(backgroundId)
    return backgroundId and backgroundId ~= ""
        and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(backgroundId) ~= nil
end

local function SetBackgroundFromIndex(backgroundId, backgroundDesc, profileName)
    backgroundId = tostring(backgroundId or "")
    backgroundDesc = tostring(backgroundDesc or "")
    if backgroundId == "" then
        return API.SetBackground("", profileName)
    end
    API.SetBackground(backgroundId, profileName)
    -- La ficha TRP3 es indice; el libro Harford es la fuente de reglas/texto.
    -- Solo guardamos descripcion TRP3 cuando el trasfondo no existe en el libro.
    if not BackgroundIsFromBook(backgroundId) and backgroundDesc ~= "" then
        API.SetBackgroundDesc(backgroundDesc, profileName)
    end
    return true
end

-- Dotes del perfil: lista de featId. Solo runtime/persistido, sin nivel.
-- Equipo inicial como LISTA de nombres. No son items de Epsilon: es lo que el personaje declara
-- llevar, y de ahi salen la seccion "Equipo" del About y (mas adelante) los slots equipados.
function API.GetEquipmentList(profileName)
    local data = API.Get(profileName)
    if type(data.equipmentList) ~= "table" then data.equipmentList = {} end
    return data.equipmentList
end

function API.SetEquipmentList(items, profileName)
    local data, name = API.Get(profileName)
    local limpio = {}
    for _, item in ipairs(items or {}) do
        local texto = tostring(item or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if texto ~= "" then limpio[#limpio + 1] = texto end
    end
    data.equipmentList = limpio
    Touch(name)
    return true
end

function API.GetFeats(profileName)
    local data = API.Get(profileName)
    return data.feats
end

function API.HasFeat(featId, profileName)
    local data = API.Get(profileName)
    featId = tostring(featId or "")
    for _, id in ipairs(data.feats) do
        if id == featId then return true end
    end
    return false
end

function API.SetFeatEnabled(featId, enabled, profileName)
    local data = API.Get(profileName)
    featId = tostring(featId or "")
    if featId == "" then return false end
    local featDef = HarfordDnDFeats and HarfordDnDFeats.GetFeat and HarfordDnDFeats.GetFeat(featId)
    if featDef then featId = featDef.id end
    -- Quita siempre las ocurrencias previas (evita duplicados).
    for i = #data.feats, 1, -1 do
        if data.feats[i] == featId then table.remove(data.feats, i) end
    end
    if enabled then data.feats[#data.feats + 1] = featId end
    Touch(profileName)
    return true
end

-- Variante de Mana (regla adicional): toggle por perfil. El usuario elige entre
-- maná y espacios de conjuro. Al activarlo, el pool de maná (HarfordDnDMana) se
-- aplica como bonus al maximo del recurso "mana" via HarfordDnDFeatureEffects.
function API.GetSpellSlotsSpent(level, profileName)
    local data = API.Get(profileName)
    return math.max(0, math.floor(tonumber(data.spellSlots[math.floor(tonumber(level) or 0)]) or 0))
end

function API.SetSpellSlotsSpent(level, spent, profileName)
    level = math.floor(tonumber(level) or 0)
    if level < 1 or level > 9 then return false end
    local data = API.Get(profileName)
    spent = math.max(0, math.floor(tonumber(spent) or 0))
    if spent > 0 then data.spellSlots[level] = spent else data.spellSlots[level] = nil end
    Touch(profileName)
    return true
end

-- Contadores por descanso largo. Genericos a proposito: cualquier rasgo con la forma "N desde el
-- ultimo descanso largo" los usa sin inventarse su propio almacen.
function API.GetRestCounter(key, profileName)
    local data = API.Get(profileName)
    return math.floor(tonumber(data.restCounters[tostring(key or "")]) or 0)
end

function API.SetRestCounter(key, value, profileName)
    key = tostring(key or "")
    if key == "" then return false end
    local data = API.Get(profileName)
    value = math.floor(tonumber(value) or 0)
    if value ~= 0 then data.restCounters[key] = value else data.restCounters[key] = nil end
    Touch(profileName)
    return true
end

function API.ResetRestCounters(profileName)
    local data = API.Get(profileName)
    if next(data.restCounters) == nil then return false end
    data.restCounters = {}
    Touch(profileName)
    return true
end

-- Espacios de pacto gastados. Un solo numero por perfil: el pacto concede todas sus ranuras al
-- mismo nivel, asi que no hace falta desglosarlo por nivel como los normales.
function API.GetPactSpent(profileName)
    local data = API.Get(profileName)
    return math.max(0, math.floor(tonumber(data.pactSpent) or 0))
end

function API.SetPactSpent(spent, profileName)
    local data = API.Get(profileName)
    spent = math.max(0, math.floor(tonumber(spent) or 0))
    -- El 0 no se persiste, igual que el resto de contadores: no engordar SavedVariables.
    data.pactSpent = spent > 0 and spent or nil
    Touch(profileName)
    return spent
end

function API.GetSpellSlotsBonus(level, profileName)
    local data = API.Get(profileName)
    return math.max(0, math.floor(tonumber(data.spellSlotsBonus[math.floor(tonumber(level) or 0)]) or 0))
end

function API.SetSpellSlotsBonus(level, bonus, profileName)
    level = math.floor(tonumber(level) or 0)
    if level < 1 or level > 9 then return false end
    local data = API.Get(profileName)
    bonus = math.max(0, math.floor(tonumber(bonus) or 0))
    if bonus > 0 then data.spellSlotsBonus[level] = bonus else data.spellSlotsBonus[level] = nil end
    Touch(profileName)
    return true
end

function API.ResetSpellSlots(profileName)
    local data = API.Get(profileName)
    -- El descanso largo restaura los gastados Y hace desaparecer los creados con puntos.
    -- El pacto entra en la guarda: si lo unico gastado son ranuras de pacto, el descanso largo
    -- SI tiene algo que restaurar.
    if next(data.spellSlots) == nil and next(data.spellSlotsBonus) == nil
        and (tonumber(data.pactSpent) or 0) <= 0 then return false end
    data.spellSlots = {}
    data.spellSlotsBonus = {}
    data.pactSpent = nil
    Touch(profileName)
    return true
end

-- Estados activables por el jugador, declarados por rasgos con `toggleState`.
-- No son checkboxes generales de rasgo: solo aparecen cuando un rasgo desbloqueado
-- declara un estado de combate concreto (transformado, lobo solitario, metamorfosis...).
function API.IsToggleStateActive(stateId, profileName)
    local data = API.Get(profileName)
    stateId = tostring(stateId or "")
    return stateId ~= "" and data.activeStates[stateId] == true
end

function API.SetToggleState(stateId, enabled, profileName)
    local data = API.Get(profileName)
    stateId = tostring(stateId or "")
    if stateId == "" then return false end
    data.activeStates[stateId] = enabled and true or nil
    Touch(profileName)
    return true
end

function API.GetActiveStates(profileName)
    local data = API.Get(profileName)
    return data.activeStates
end

-- La forma concreta completa el flag generico wild_shape. Se guarda separada para que
-- revertir no toque ni el equipo ni los valores base de la ficha.
function API.GetActiveForm(profileName)
    local data = API.Get(profileName)
    return tostring(data.activeForm or "")
end

function API.SetActiveForm(formId, profileName)
    local data = API.Get(profileName)
    data.activeForm = tostring(formId or "")
    if data.activeForm == "" then data.activeFormAction = "" end
    Touch(profileName)
    return true
end

function API.GetActiveFormAction(profileName)
    local data = API.Get(profileName)
    return tostring(data.activeFormAction or "")
end

function API.SetActiveFormAction(actionKey, profileName)
    local data = API.Get(profileName)
    data.activeFormAction = tostring(actionKey or "")
    Touch(profileName)
    return true
end

function API.GetImportedProficiencies(profileName)
    local data = API.Get(profileName)
    return data.importedProficiencies or {}
end

function API.GetUnlockedFeatures(profileName)
    local data = API.Get(profileName)
    local out = {}
    -- Filtro comun a TODAS las fuentes: `requiresOption` (el rasgo solo entra con esa opcion
    -- elegida; antes solo se aplicaba a clase/subclase y las razas no podian derivar rasgos de
    -- una eleccion, como el Sistema de Emergencia del Mecagnomo) y `minCharacterLevel` (puerta
    -- por NIVEL TOTAL de personaje, como la de spellGrants: la segunda Mejora mecanica es de
    -- nivel 5).
    local elegidas, nivelTotal
    local function Entra(item)
        local feature = item and item.feature
        if not feature then return false end
        -- Puertas de MULTICLASE (regla del manual: solo la clase INICIAL da sus competencias
        -- completas). `onlyFirstClass` = el rasgo solo existe si esa clase es la primera del PJ;
        -- `onlyMulticlass` = solo si NO lo es. Asi la eleccion de habilidades de clase completa
        -- y su variante multiclase (1 habilidad, o fija) se excluyen mutuamente y la que no
        -- aplica no aparece en NINGUNA superficie (Libro, asistente, Resolve).
        if feature.onlyFirstClass or feature.onlyMulticlass then
            local primera = data.classLevels and data.classLevels[1]
            local esPrimera = primera ~= nil and tostring(primera.classId) == tostring(item.classId)
            if feature.onlyFirstClass and not esPrimera then return false end
            if feature.onlyMulticlass and esPrimera then return false end
        end
        local minimo = tonumber(feature.minCharacterLevel)
        if minimo then
            if not nivelTotal then
                nivelTotal = 0
                for _, e in ipairs(data.classLevels or {}) do
                    nivelTotal = nivelTotal + (tonumber(e.level) or 0)
                end
            end
            if nivelTotal < minimo then return false end
        end
        local req = feature.requiresOption
        if req then
            if not elegidas then
                elegidas = {}
                for _, seleccion in pairs(data.choices or {}) do
                    for _, optId in ipairs(seleccion or {}) do elegidas[tostring(optId)] = true end
                end
            end
            return elegidas[tostring(req)] == true
        end
        return true
    end
    -- Rasgos raciales (activos al elegir raza, con el filtro comun).
    if HarfordDnDRaces and HarfordDnDRaces.GetRaceTraits and data.race and data.race.id ~= "" then
        for _, item in ipairs(HarfordDnDRaces.GetRaceTraits(data.race.id, data.race.subraceId)) do
            if Entra(item) then out[#out + 1] = item end
        end
    end
    -- Rasgos de trasfondo (activos al elegir trasfondo).
    if HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgroundTraits and data.background and data.background ~= "" then
        for _, item in ipairs(HarfordDnDBackgrounds.GetBackgroundTraits(data.background, data.backgroundVariant)) do
            if Entra(item) then out[#out + 1] = item end
        end
    end
    -- Rasgos de dotes (activos al elegir el dote).
    if HarfordDnDFeats and HarfordDnDFeats.GetFeatTraits and data.feats and #data.feats > 0 then
        for _, item in ipairs(HarfordDnDFeats.GetFeatTraits(data.feats)) do
            if Entra(item) then out[#out + 1] = item end
        end
    end
    -- Rasgos de clase/subclase. Los que declaran `requiresOption` (maniobras elegibles) solo
    -- entran si esa opcion esta realmente elegida: existen como rasgo para que el Libro pueda
    -- mostrarlas y ejecutarlas, pero el PJ solo conoce las que ha aprendido.
    if HarfordDnDBook and HarfordDnDBook.GetUnlockedFeatures then
        for _, item in ipairs(HarfordDnDBook.GetUnlockedFeatures(data.classLevels)) do
            if Entra(item) then out[#out + 1] = item end
        end
    end
    return out
end

function API.SeedFromTRP3(profileName)
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile) then return false end
    local profile = HarfordTRP3.GetPlayerProfile("player")
    if not profile then return false end
    local data = API.Get(profileName)
    local importedAny = false

    if not API.HasProgression(profileName) and HarfordDnDBook and HarfordTRP3.GetProfileClassEntries then
        local entries = HarfordTRP3.GetProfileClassEntries(profile)
        if type(entries) == "table" and #entries > 0 then
            local imported = 0
            for i, entry in ipairs(entries) do
                local ok = API.SetClassEntry(i, entry.classId, entry.subclassId, entry.level, profileName)
                if ok then imported = imported + 1 end
            end
            if imported > 0 then importedAny = true end
        end
    end

    if not importedAny and not API.HasProgression(profileName) and HarfordDnDBook then
        local classText = HarfordTRP3.GetProfilePrimaryClass and HarfordTRP3.GetProfilePrimaryClass(profile)
        local levelText = HarfordTRP3.GetProfileLevel and HarfordTRP3.GetProfileLevel(profile)
        local classId = HarfordDnDBook.FindClassIdByText(classText)
        local level = tonumber(levelText)
        if classId and level and level > 0 then
            importedAny = API.SetClassEntry(1, classId, nil, level, profileName) or importedAny
        end
    end

    if data.race and tostring(data.race.id or "") == "" and HarfordTRP3.GetProfileRaceEntry then
        local raceEntry = HarfordTRP3.GetProfileRaceEntry(profile)
        if raceEntry and raceEntry.raceId and raceEntry.raceId ~= "" then
            importedAny = API.SetRace(raceEntry.raceId, raceEntry.subraceId, profileName) or importedAny
        end
    end

    if (tostring(data.background or "") == "" or tostring(data.backgroundDesc or "") == "") and HarfordTRP3.GetProfileBackgroundEntry then
        local bgId, _, bgDesc = HarfordTRP3.GetProfileBackgroundEntry(profile)
        if tostring(data.background or "") == "" and bgId and bgId ~= "" then
            SetBackgroundFromIndex(bgId, bgDesc, profileName)
            importedAny = true
        elseif tostring(data.backgroundDesc or "") == "" and bgDesc and bgDesc ~= "" then
            local current = tostring(data.background or "")
            if not BackgroundIsFromBook(current) and NormalizeText(current) == NormalizeText(bgId or "") then
                API.SetBackgroundDesc(bgDesc, profileName)
                importedAny = true
            end
        end
    end

    return importedAny
end

function API.Export(profileName)
    local data = API.Get(profileName)
    return CopyTable(data)
end

-- Reemplazo DESTRUCTIVO de la progresion con la ficha parseada del TRP3
-- (HarfordTRP3.ParsePlayerSheet). Limpia clases/featureStates/choices/activeStates (todo
-- derivable de clase/raza) y fija clases (orden del About = la 1a clase es la "primera"
-- para el calculo de PG), raza/subraza y trasfondo (id del libro o texto raw como visual).
-- Nombre de match de una opcion de choice: el texto del label antes del primer "(" (ej.
-- "Combate con Dos Armas (...)" -> "combate con dos armas"), normalizado.
local function OptionMatchName(label)
    local head = tostring(label or ""):match("^(.-)%s*%(") or tostring(label or "")
    return NormalizeText(head)
end

local function FeatureMatchNames(feature)
    local names = {}
    local base = NormalizeText(feature and feature.name or "")
    if base ~= "" then
        names[#names + 1] = base
        local beforeOr = base:match("^(.-)%s+o%s+.+$")
        if beforeOr and beforeOr ~= "" then names[#names + 1] = beforeOr end
    end
    return names
end

local function AddUnique(list, value)
    value = tostring(value or "")
    if value == "" then return end
    for _, existing in ipairs(list or {}) do
        if existing == value then return end
    end
    list[#list + 1] = value
end

local function NormalizeAboutHeading(line)
    local text = NormalizeText(line)
    text = text:gsub("^[-%*]+%s*", "")
    text = text:gsub("%b()", "")
    text = text:gsub("[:%.]+$", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local SKILL_SECTION_HEADINGS = {
    habilidades = "skills",
    ["competencia en habilidades"] = "skills",
    ["competencias en habilidades"] = "skills",
    pericia = "expertise",
    pericias = "expertise",
    expertise = "expertise",
}

local ABOUT_CHOICE_BOUNDARIES = {
    clase = true, clases = true, raza = true, subraza = true, trasfondo = true,
    caracteristicas = true, atributos = true, recursos = true, armas = true, arma = true,
    armadura = true, equipo = true, inventario = true, magia = true, conjuros = true,
    hechizos = true, idiomas = true, rasgos = true, ["rasgos de clase"] = true,
    ["tiradas de salvacion"] = true, salvaciones = true, ataques = true, ataque = true,
}

local SAVE_SECTION_HEADINGS = {
    ["tiradas de salvacion"] = true,
    salvaciones = true,
}

local PROF_SECTION_HEADINGS = {
    competencia = true,
    competencias = true,
}

local LANGUAGE_SECTION_HEADINGS = {
    idiomas = true, idioma = true, lenguas = true, lengua = true, languages = true,
}

-- Etiquetas de fuente que pueden colgar al final de un idioma (se recortan): "Comun", "Enano Trasfondo".
local LANGUAGE_SOURCE_TAGS = {
    trasfondo = true, racial = true, clase = true, raza = true, eleccion = true,
}

local function GetSkillMatchOptions()
    local options = {}
    for _, skill in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
        local names = {
            NormalizeText(skill.id),
            NormalizeText(skill.name),
            OptionMatchName(skill.name),
        }
        local seen, cleanNames = {}, {}
        for _, name in ipairs(names) do
            if name ~= "" and not seen[name] then
                cleanNames[#cleanNames + 1] = name
                seen[name] = true
            end
        end
        options[#options + 1] = { id = skill.id, names = cleanNames }
    end
    table.sort(options, function(a, b)
        local al, bl = 0, 0
        for _, n in ipairs(a.names or {}) do al = math.max(al, #n) end
        for _, n in ipairs(b.names or {}) do bl = math.max(bl, #n) end
        return al > bl
    end)
    return options
end

local function AddSkillMatchesFromLine(pool, line)
    local text = NormalizeText(line)
    if text == "" then return end
    for _, option in ipairs(GetSkillMatchOptions()) do
        for _, name in ipairs(option.names or {}) do
            if name ~= "" and text:find(name, 1, true) then
                AddUnique(pool, option.id)
                break
            end
        end
    end
end

local function EmptyImportedProficiencies()
    return { skillRank = {}, saveProf = {}, armorProf = {}, weaponProf = {}, toolProf = {},
        languages = {}, professions = {} }
end

local function AddMapFlag(map, key)
    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if key ~= "" then map[key] = true end
end

local function MatchAbilityKey(line)
    local text = NormalizeText(line)
    for _, abil in ipairs((HarfordDnDData and HarfordDnDData.ABIL) or {}) do
        if text:find(NormalizeText(abil.key), 1, true) or text:find(NormalizeText(abil.short), 1, true) then
            return abil.key
        end
    end
    return nil
end

local function NormalizeProfLine(line)
    local text = tostring(line or "")
    text = text:gsub("^%s*[-%*]+%s*", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

-- "Herreria Aprendiz" -> ("herreria", 1). El rango es opcional: sin el cuenta como Aprendiz,
-- que es el escalon minimo de conocer la profesion.
--
-- El nombre tiene que casar ENTERO, no por substring: asi "Herramientas de herrero" sigue siendo
-- una competencia de herramienta y no se confunde con la profesion "Herreria".
local function MatchProfessionLine(text)
    local P = _G.HarfordProfessions
    if not (P and P.GetProfessions and P.GetTierMin) then return nil end

    local cuerpo, skill = text, 1
    local ultima = text:match("(%S+)%s*$")
    local minimo = ultima and P.GetTierMin(ultima)
    if minimo then
        cuerpo = NormalizeText(text:sub(1, #text - #ultima))
        skill = minimo
    end
    if cuerpo == "" then return nil end

    for _, def in ipairs(P.GetProfessions() or {}) do
        if NormalizeText(def.name or "") == cuerpo or NormalizeText(def.id or "") == cuerpo then
            return def.id, skill
        end
    end
    return nil
end

-- Recorta la etiqueta de fuente final ("Armas de fuego Trasfondo" -> "Armas de fuego"). Es la
-- misma lista que en Idiomas: en el About marcan de donde viene la competencia, no forman parte
-- de su nombre.
local function StripSourceTag(raw)
    local last = raw:match("(%S+)%s*$")
    if last and LANGUAGE_SOURCE_TAGS[NormalizeText(last)] then
        return (raw:sub(1, #raw - #last):gsub("%s+$", ""))
    end
    return raw
end

local function ImportGeneralProficiency(imported, line)
    local raw = StripSourceTag(NormalizeProfLine(line))
    local text = NormalizeText(raw)
    if text == "" then return end

    local profId, profSkill = MatchProfessionLine(text)
    if profId then
        imported.professions[profId] = math.max(tonumber(imported.professions[profId]) or 0, profSkill)
        return
    end

    if text:find("armadura", 1, true) or text == "escudo" or text == "escudos" then
        if text:find("ligera", 1, true) then AddMapFlag(imported.armorProf, "ligera") end
        if text:find("media", 1, true) or text:find("intermedia", 1, true) then AddMapFlag(imported.armorProf, "media") end
        if text:find("pesada", 1, true) then AddMapFlag(imported.armorProf, "pesada") end
        if text:find("escudo", 1, true) then AddMapFlag(imported.armorProf, "escudo") end
        return
    end

    local weapon = text:gsub("^armas%s+", "")
    if weapon == "simples" then weapon = "sencillas" end
    if weapon ~= "" and (text:find("arma", 1, true)
        or text:find("espada", 1, true)
        or text:find("ballesta", 1, true)
        or text:find("estoque", 1, true)
        or text:find("florete", 1, true)
        or text:find("pistola", 1, true)
        or text:find("rifle", 1, true)
        or text:find("marcial", 1, true)
        or text:find("sencilla", 1, true)
        or text:find("simple", 1, true)) then
        AddMapFlag(imported.weaponProf, weapon)
        return
    end

    AddMapFlag(imported.toolProf, raw)
end

-- Un idioma por linea (lista con vinetas): "- Comun", "- Enano Trasfondo". Recorta la vineta y
-- la etiqueta de fuente final; guarda el nombre limpio.
local function ImportLanguage(imported, line)
    local text = tostring(line or ""):gsub("^%s*[-%*]+%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end
    local last = text:match("(%S+)%s*$")
    if last and LANGUAGE_SOURCE_TAGS[NormalizeText(last)] then
        text = text:sub(1, #text - #last):gsub("%s+$", "")
    end
    if text ~= "" then imported.languages[text] = true end
end

-- El About decide QUE profesiones tienes; el skill local decide CUANTO, mientras no baje del rango
-- que declara la ficha:
--   * nombrada en el About -> se queda el mayor entre tu skill y el minimo de ese rango. El rango
--     es grueso (Aprendiz cubre de 1 a 74), asi que un "Aprendiz" no puede tirarte un 25 a 1; solo
--     te SUBE si vienes por debajo del escalon declarado.
--   * ausente del About -> no la tienes, se borra.
--
-- Barrer TODAS las profesiones y no solo las nombradas es seguro aqui porque el unico llamador es
-- `/harford cargarficha`, que ya ha abortado antes si no pudo leer la ficha del About: si esta
-- tabla llega vacia es porque el perfil no declara ninguna, no porque el parseo fallase.
--
-- Solo toca el skill guardado. Una profesion que conozcas por competencia de herramienta de un
-- rasgo sigue saliendo como Aprendiz via `KnowsProfession`/`EffectiveSkill`: eso lo concede el
-- rasgo, no el store, y borrarlo aqui no lo quitaria.
local function ApplyImportedProfessions(imported)
    local P = _G.HarfordProfessions
    if not (P and P.SetSkill and P.GetSkill and P.GetProfessions) then return end
    local declaradas = (imported and imported.professions) or {}
    for _, def in ipairs(P.GetProfessions() or {}) do
        local declarada = tonumber(declaradas[def.id])
        if declarada then
            P.SetSkill(def.id, math.max(tonumber(P.GetSkill(def.id)) or 0, declarada))
        else
            P.SetSkill(def.id, 0)
        end
    end
end

local function ExtractImportedProficiencies(aboutLines)
    local imported = EmptyImportedProficiencies()
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return imported end

    local section
    for _, line in ipairs(aboutLines) do
        local heading = NormalizeAboutHeading(line)
        if SKILL_SECTION_HEADINGS[heading] == "skills" then
            section = "skills"
        elseif SAVE_SECTION_HEADINGS[heading] then
            section = "saves"
        elseif PROF_SECTION_HEADINGS[heading] then
            section = "profs"
        elseif SKILL_SECTION_HEADINGS[heading] == "expertise" then
            section = "expertise"
        elseif LANGUAGE_SECTION_HEADINGS[heading] then
            section = "languages"
        elseif ABOUT_CHOICE_BOUNDARIES[heading] then
            section = nil
        elseif section == "skills" then
            local matches = {}
            AddSkillMatchesFromLine(matches, line)
            for _, skillId in ipairs(matches) do
                imported.skillRank[skillId] = math.max(tonumber(imported.skillRank[skillId]) or 0, 1)
            end
        elseif section == "expertise" then
            local matches = {}
            AddSkillMatchesFromLine(matches, line)
            for _, skillId in ipairs(matches) do
                imported.skillRank[skillId] = math.max(tonumber(imported.skillRank[skillId]) or 0, 2)
            end
            if #matches > 0 then section = nil end
        elseif section == "saves" then
            local ability = MatchAbilityKey(line)
            if ability then imported.saveProf[ability] = true end
        elseif section == "profs" then
            ImportGeneralProficiency(imported, line)
        elseif section == "languages" then
            -- Solo items de lista (con vineta). En cuanto llega una linea sin vineta (titulo de
            -- otro frame, descripcion...) se cierra la seccion para no tragar el resto del About.
            if line:match("^%s*[-%*]") then
                ImportLanguage(imported, line)
            else
                section = nil
            end
        else
            local normalized = NormalizeText(line)
            if normalized:find("pericia", 1, true) or normalized:find("expertise", 1, true) then
                local matches = {}
                AddSkillMatchesFromLine(matches, line)
                for _, skillId in ipairs(matches) do
                    imported.skillRank[skillId] = math.max(tonumber(imported.skillRank[skillId]) or 0, 2)
                end
            end
        end
    end

    return imported
end

local function ExtractSkillChoicePools(aboutLines)
    local pools = { skillProf = {}, skillExpertise = {} }
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return pools end

    local section
    for _, line in ipairs(aboutLines) do
        local heading = NormalizeAboutHeading(line)
        if SKILL_SECTION_HEADINGS[heading] then
            section = SKILL_SECTION_HEADINGS[heading]
        elseif ABOUT_CHOICE_BOUNDARIES[heading] then
            section = nil
        else
            local normalized = NormalizeText(line)
            if normalized:find("pericia", 1, true) or normalized:find("expertise", 1, true) then
                AddSkillMatchesFromLine(pools.skillExpertise, line)
            elseif section == "expertise" then
                local before = #pools.skillExpertise
                AddSkillMatchesFromLine(pools.skillExpertise, line)
                -- En las fichas TRP3 actuales, "Pericia" es cabecera y la siguiente
                -- linea contiene las habilidades elegidas ("Acrobacias | Sigilo").
                -- Tras capturar esa linea, no seguimos leyendo textos narrativos/conjuros.
                if #pools.skillExpertise > before then section = nil end
            elseif section == "skills" then
                AddSkillMatchesFromLine(pools.skillProf, line)
            end
        end
    end

    return pools
end

local function CollectFixedSkillRanks(profileName)
    local fixed = {}
    if not API.GetUnlockedFeatures then return fixed end
    for _, item in ipairs(API.GetUnlockedFeatures(profileName) or {}) do
        local feature = item and item.feature
        if feature and not (feature.type == "choice" and type(feature.choice) == "table") then
            for _, effect in ipairs(feature.effects or {}) do
                if effect.kind == "skillExpertise" and effect.skill then
                    fixed[effect.skill] = math.max(tonumber(fixed[effect.skill]) or 0, 2)
                elseif effect.kind == "skillProf" and effect.skill then
                    fixed[effect.skill] = math.max(tonumber(fixed[effect.skill]) or 0, 1)
                end
            end
        end
    end
    return fixed
end

local function ChooseOptionsFromPool(feature, pool, slots, used)
    local chosen = {}
    if type(pool) ~= "table" or #pool == 0 then return chosen end
    local byId = {}
    for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
        byId[tostring(opt.id or "")] = opt
    end
    for _, skillId in ipairs(pool) do
        if #chosen >= slots then break end
        if byId[skillId] and not used[skillId] then
            chosen[#chosen + 1] = skillId
            used[skillId] = true
        end
    end
    return chosen
end

-- Las Palabras de Poder se guardan en TRP3 como habilidades independientes. Segun la
-- especializacion pueden llevar un subtitulo entre "Palabra de" y la opcion final
-- (por ejemplo, "Palabra de las Sombras Dolor"), por lo que no comparten una linea
-- con el rasgo padre. Se importan todas las cabeceras explicitas, incluso si el
-- perfil corresponde a un nivel que en el libro normal solo tendria una eleccion.
local function ResolvePowerWordChoices(feature, normLines)
    local chosen, seen = {}, {}
    for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
        local optionName = OptionMatchName(opt.label or "")
        if optionName ~= "" then
            local escapedName = optionName:gsub("([^%w])", "%%%1")
            for _, line in ipairs(normLines) do
                -- Las Palabras de Poder en TRP3 se titulan SIEMPRE con el prefijo "Palabra de ... X"
                -- (p.ej. "Palabra de poder Escudo", "Palabra de las Sombras Dolor"). Un titulo suelto
                -- igual al nombre de la opcion (p.ej. el hechizo "Escudo") NO es una Palabra de Poder:
                -- exigir el prefijo evita el falso positivo (Ashzynde tiene el CONJURO Escudo, que es
                -- otra cosa, y NO la Palabra de Poder Escudo). Solo se aceptan titulos completos, para
                -- no detectar "dolor"/"muerte" dentro de la descripcion narrativa de otro rasgo.
                if line:match("^palabra de .+ " .. escapedName .. "$") then
                    if not seen[opt.id] then
                        chosen[#chosen + 1] = opt.id
                        seen[opt.id] = true
                    end
                    break
                end
            end
        end
    end
    return chosen
end

-- Resuelve las elecciones (choice) con opciones EXPLICITAS desde el texto del About: por cada
-- rasgo choice desbloqueado, busca la LINEA que contiene el nombre del rasgo (ej. "Estilo de
-- Combate") y dentro de ESA linea matchea el nombre de una opcion (ej. "Gran Arma"). Asi no
-- confunde con otra linea (p.ej. un conjuro llamado "Proteccion"). Los choice de habilidades
-- generados con `optionsFrom` se resuelven desde secciones "Habilidades"/"Pericia"; los ASI
-- NO se resuelven porque sus datos ya vienen horneados en el About (puntuaciones).
local function ResolveChoicesFromAbout(profileName, aboutLines)
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return end
    if not (HarfordDnDBook and HarfordDnDBook.GetChoiceOptions and API.GetUnlockedFeatures) then return end

    local normLines = {}
    for i, l in ipairs(aboutLines) do normLines[i] = NormalizeText(l) end
    local pools = ExtractSkillChoicePools(aboutLines)
    local fixedSkills = CollectFixedSkillRanks(profileName)
    local usedSkillProf, usedSkillExpertise = {}, {}
    for skillId, rank in pairs(fixedSkills) do
        if tonumber(rank) >= 1 then usedSkillProf[skillId] = true end
    end

    for _, item in ipairs(API.GetUnlockedFeatures(profileName) or {}) do
        local feature = item and item.feature
        local choice = feature and feature.choice
        if feature and feature.type == "choice" and type(choice) == "table" then
            local slots = math.max(1, math.floor(tonumber(choice.slots) or 1))
            local featureNames = FeatureMatchNames(feature)
            local chosen, used = {}, {}
            if feature.actionKind == "powerWord" then
                chosen = ResolvePowerWordChoices(feature, normLines)
            elseif #featureNames > 0 then
                for lineIndex, ln in ipairs(normLines) do
                    local featureLine = false
                    for _, fname in ipairs(featureNames) do
                        if fname ~= "" and ln:find(fname, 1, true) then
                            featureLine = true
                            break
                        end
                    end
                    if featureLine then
                        local scanLine = ln
                        local nextLine = normLines[lineIndex + 1]
                        if nextLine and nextLine ~= "" then
                            scanLine = scanLine .. " " .. nextLine
                        end
                        local matches = {}
                        for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
                            if not used[opt.id] then
                                -- Probar id normalizado ("gran_arma"->"gran arma") Y nombre del
                                -- label: el About puede escribir el estilo distinto al label del
                                -- libro (ej. "Gran Arma" vs label "Gran Lucha con Armas").
                                local bestPos, bestLen
                                for _, nm in ipairs({ NormalizeText(opt.id), OptionMatchName(opt.label or "") }) do
                                    local pos = (nm ~= "") and scanLine:find(nm, 1, true) or nil
                                    if pos and (not bestLen or #nm > bestLen) then
                                        bestPos, bestLen = pos, #nm
                                    end
                                end
                                if bestPos then
                                    matches[#matches + 1] = { id = opt.id, pos = bestPos, len = bestLen or 0 }
                                end
                            end
                        end
                        table.sort(matches, function(a, b)
                            if a.pos ~= b.pos then return a.pos < b.pos end
                            return a.len > b.len
                        end)
                        for _, match in ipairs(matches) do
                            if not used[match.id] then
                                chosen[#chosen + 1] = match.id
                                used[match.id] = true
                                if choice.optionsFrom == "skillProf" then usedSkillProf[match.id] = true end
                                if choice.optionsFrom == "skillExpertise" then usedSkillExpertise[match.id] = true end
                            end
                            if #chosen >= slots then break end
                        end
                    end
                end
            end
            -- Cabecera suelta: una linea que ES EXACTAMENTE el nombre de una opcion (el About
            -- puede escribir el estilo como su propio h2, ej. "Gran Arma", sin "Estilo de
            -- combate" delante). Solo opciones explicitas; igualdad exacta = sin falsos positivos.
            if #chosen < slots and feature.actionKind ~= "powerWord" and type(choice.options) == "table" then
                for _, ln in ipairs(normLines) do
                    for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
                        if not used[opt.id] then
                            for _, nm in ipairs({ NormalizeText(opt.id), OptionMatchName(opt.label or "") }) do
                                if nm ~= "" and ln == nm then
                                    chosen[#chosen + 1] = opt.id
                                    used[opt.id] = true
                                    break
                                end
                            end
                        end
                        if #chosen >= slots then break end
                    end
                    if #chosen >= slots then break end
                end
            end
            if #chosen == 0 and choice.optionsFrom == "skillExpertise" then
                chosen = ChooseOptionsFromPool(feature, pools.skillExpertise, slots, usedSkillExpertise)
            elseif #chosen == 0 and choice.optionsFrom == "skillProf" then
                chosen = ChooseOptionsFromPool(feature, pools.skillProf, slots, usedSkillProf)
            end
            for slot, optId in ipairs(chosen) do
                API.SetChoiceSlot(feature.id, slot, optId, profileName)
            end
        end
    end
end

-- Resuelve DOTES desde el About: el perfil marca cada dote con "Dote <Nombre>" (cabecera con
-- {col} Dote{/col} <Nombre>, normalmente en la seccion de raza). Por cada linea que contiene
-- "dote", busca el nombre de dote del libro mas largo presente en esa linea y la activa. Que
-- un PJ tenga dote a nivel 4 implica que NO uso la Mejora de Caracteristica (esa choice queda
-- sin resolver, que es lo correcto: las puntuaciones ya vienen horneadas del About).
local function ResolveFeatsFromAbout(profileName, aboutLines)
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return end
    if not (HarfordDnDFeats and HarfordDnDFeats.GetFeats and API.SetFeatEnabled) then return end
    local feats = HarfordDnDFeats.GetFeats() or {}
    for _, ln0 in ipairs(aboutLines) do
        local ln = NormalizeText(ln0)
        if ln:find("dote", 1, true) then
            local bestId, bestLen
            for _, f in ipairs(feats) do
                local nm = NormalizeText(f.name or "")
                if nm ~= "" and ln:find(nm, 1, true) and (not bestLen or #nm > bestLen) then
                    bestId, bestLen = f.id, #nm
                end
            end
            if bestId then API.SetFeatEnabled(bestId, true, profileName) end
        end
    end
    -- Cabecera suelta SIN marcador "Dote": una linea que ES EXACTAMENTE el nombre de una dote
    -- MULTIPALABRA (p.ej. "Gran Maestro de Armas"). Se exige nombre con espacio para evitar
    -- falsos positivos con dotes de una sola palabra (esas requieren el marcador "Dote").
    for _, ln0 in ipairs(aboutLines) do
        local ln = NormalizeText(ln0)
        for _, f in ipairs(feats) do
            local nm = NormalizeText(f.name or "")
            if nm ~= "" and nm:find(" ", 1, true) and ln == nm then
                API.SetFeatEnabled(f.id, true, profileName)
                break
            end
        end
    end
end

function API.LoadFromTRP3Replace(sheet, profileName)
    if type(sheet) ~= "table" then return false end
    local data = API.Get(profileName)
    data.classLevels = {}
    data.featureStates = {}
    data.choices = {}
    data.activeStates = {}
    data.feats = {}
    data.importedFromTRP3 = true
    data.importedProficiencies = ExtractImportedProficiencies(sheet.aboutLines)
    ApplyImportedProfessions(data.importedProficiencies)

    local idx = 0
    for _, c in ipairs(sheet.classes or {}) do
        idx = idx + 1
        API.SetClassEntry(idx, c.classId, c.subclassId or "", c.level, profileName)
    end

    if sheet.raceId and sheet.raceId ~= "" then
        -- Import TRP3 exacto: si la ficha solo dice "Elfo de la Noche", no forzar la
        -- primera subraza disponible (p.ej. Altonato). La subraza solo se aplica si el
        -- texto TRP3 la nombra de forma explicita.
        data.race = { id = tostring(sheet.raceId or ""), subraceId = tostring(sheet.subraceId or "") }
    else
        data.race = { id = "", subraceId = "" }
    end

    if sheet.background and sheet.background ~= "" then
        SetBackgroundFromIndex(sheet.background, sheet.backgroundDesc, profileName)
    elseif sheet.backgroundRaw and sheet.backgroundRaw ~= "" then
        SetBackgroundFromIndex(sheet.backgroundRaw, sheet.backgroundDesc, profileName)  -- valor visual si no esta en el libro
    else
        API.SetBackground("", profileName)
    end
    -- Variante detectada en el titulo del About ("Trasfondo Veterano Harford"): se persiste
    -- solo si vino resuelta; sin dato no se pisa lo que hubiera.
    if sheet.backgroundVariant and sheet.backgroundVariant ~= "" and API.SetBackgroundVariant then
        API.SetBackgroundVariant(sheet.backgroundVariant, profileName)
    end

    -- Con clases/raza/trasfondo ya fijados, resolver desde el texto del About: las elecciones
    -- con opciones explicitas (estilo de combate, afinidades...) y las dotes ("Dote <Nombre>").
    ResolveChoicesFromAbout(profileName, sheet.aboutLines)
    ResolveFeatsFromAbout(profileName, sheet.aboutLines)

    Touch(profileName)
    return true
end

-- Importa una ficha TRP3 como snapshot de inspeccion: NO persiste nada en SavedVariables.
-- Se usa para que calculos remotos (p.ej. resistencias de clase) tengan una lista derivada
-- de efectos sin tener que recorrer los rasgos cada vez que entra dano.
function API.SetInspectDataFromTRP3Sheet(profileName, sheet)
    if type(sheet) ~= "table" then return false end
    profileName = ResolveProfileName(profileName)
    if profileName == "" then return false end

    API.SetInspectData(profileName, EmptyProgression())
    local importedAny = false

    for i, c in ipairs(sheet.classes or {}) do
        local ok = API.SetClassEntry(i, c.classId, c.subclassId or "", c.level, profileName)
        importedAny = ok or importedAny
    end

    local data = API.Get(profileName)
    data.importedFromTRP3 = true
    data.importedProficiencies = ExtractImportedProficiencies(sheet.aboutLines)

    if sheet.raceId and sheet.raceId ~= "" then
        data.race = { id = tostring(sheet.raceId or ""), subraceId = tostring(sheet.subraceId or "") }
        importedAny = true
    end

    if sheet.background and sheet.background ~= "" then
        SetBackgroundFromIndex(sheet.background, sheet.backgroundDesc, profileName)
        importedAny = true
    elseif sheet.backgroundRaw and sheet.backgroundRaw ~= "" then
        SetBackgroundFromIndex(sheet.backgroundRaw, sheet.backgroundDesc, profileName)
        importedAny = true
    end

    ResolveChoicesFromAbout(profileName, sheet.aboutLines)
    ResolveFeatsFromAbout(profileName, sheet.aboutLines)

    if not importedAny then
        API.SetInspectData(profileName, nil)
        return false
    end

    Touch(profileName)
    return true
end

-- Vida maxima por la regla del manual: PG nivel 1 = dado de golpe maximo + Mod. CON de la
-- PRIMERA clase; cada nivel restante (incluido L1 de otras clases) = dado/2+1 + Mod. CON.
function API.ComputeMaxHP(conMod, profileName)
    conMod = tonumber(conMod) or 0
    local levels = API.GetClassLevels(profileName) or {}
    if #levels == 0 then return 0 end
    local hp, totalLevel = 0, 0
    for i, e in ipairs(levels) do
        local def = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(e.classId)
        local die = (def and tonumber(def.hitDie)) or 8
        local lvl = math.max(0, math.floor(tonumber(e.level) or 0))
        for l = 1, lvl do
            totalLevel = totalLevel + 1
            if i == 1 and l == 1 then
                hp = hp + die
            else
                hp = hp + math.floor(die / 2) + 1
            end
        end
    end
    -- PG por nivel total de dotes/rasgos (ej. Duro = 2/nivel). La vida es baked; se incluye aqui
    -- para que entre al hornear en cargarficha y al reconciliar recursos derivados.
    local hpPerLevel = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetHpPerLevelBonus
        and (HarfordDnDFeatureEffects.GetHpPerLevelBonus(profileName) or 0) or 0
    return math.max(1, hp + conMod * totalLevel + hpPerLevel * totalLevel)
end

function API.Import(profileName, data)
    if type(data) ~= "table" then return false end
    API.Set(profileName, data)
    return true
end

-- ===========================================================================
-- Dados de Golpe (Hit Dice): derivados del nivel/tipo de dado de cada clase.
-- Pool max por tipo de dado = suma de niveles de clases con ese hitDie. Los dados
-- gastados se persisten en HarfordDnDPersistStore.profiles[name]._hitDice.spent (por tipo).
-- ===========================================================================
HarfordDnDHitDice = HarfordDnDHitDice or {}
do
    local HD = HarfordDnDHitDice

    -- Dados de golpe gastados: profiles[name]._hitDice = { spent = { [sides] = n } }.
    local function hitProfiles()
        HarfordDnDPersistStore = HarfordDnDPersistStore or {}
        if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
        return HarfordDnDPersistStore.profiles
    end

    -- Entrada de ESCRITURA: crea la tabla si no existe (solo al gastar).
    local function hitEntry(profileName)
        local profiles = hitProfiles()
        local name = ResolveProfileName(profileName)
        if type(profiles[name]) ~= "table" then profiles[name] = {} end
        local p = profiles[name]
        if type(p._hitDice) ~= "table" then p._hitDice = { spent = {} } end
        if type(p._hitDice.spent) ~= "table" then p._hitDice.spent = {} end
        return p._hitDice
    end

    -- Entrada de LECTURA: NO crea nada (leer no debe generar cruft persistido).
    local function hitEntryRead(profileName)
        local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
        local p = profiles and profiles[ResolveProfileName(profileName)]
        return p and p._hitDice or nil
    end

    -- Si la reserva gastada quedo a 0, elimina la sub-tabla del perfil (no persistir vacios).
    local function hitPruneIfEmpty(profileName)
        local name = ResolveProfileName(profileName)
        local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
        local p = profiles and profiles[name]
        local entry = p and p._hitDice
        if entry then
            for sides, n in pairs(entry.spent or {}) do
                if (tonumber(n) or 0) <= 0 then entry.spent[sides] = nil end
            end
            if not entry.spent or next(entry.spent) == nil then p._hitDice = nil end
        end
    end

    -- Pool maximo por tipo de dado, derivado de las clases (multiclase = varios tipos).
    function HD.GetPoolByDie(profileName)
        local pool = {}
        if HarfordDnDBook and HarfordDnDBook.GetClass then
            for _, e in ipairs(API.GetClassLevels(profileName) or {}) do
                local def = HarfordDnDBook.GetClass(e.classId)
                local sides = def and tonumber(def.hitDie)
                local lvl = tonumber(e.level) or 0
                if sides and lvl > 0 then pool[sides] = (pool[sides] or 0) + lvl end
            end
        end
        return pool
    end

    function HD.GetSpent(profileName)
        local e = hitEntryRead(profileName)
        return (e and e.spent) or {}
    end

    function HD.GetAvailable(profileName)
        local pool, spent, avail = HD.GetPoolByDie(profileName), HD.GetSpent(profileName), {}
        for sides, n in pairs(pool) do
            avail[sides] = math.max(0, n - (tonumber(spent[sides]) or 0))
        end
        return avail
    end

    function HD.GetTotalMax(profileName)
        local t = 0
        for _, n in pairs(HD.GetPoolByDie(profileName)) do t = t + n end
        return t
    end

    function HD.GetTotalAvailable(profileName)
        local t = 0
        for _, n in pairs(HD.GetAvailable(profileName)) do t = t + n end
        return t
    end

    -- Lista ordenada (dado mayor primero) de { sides, max, available }.
    function HD.GetSummaryList(profileName)
        local pool, avail, list = HD.GetPoolByDie(profileName), HD.GetAvailable(profileName), {}
        for sides, n in pairs(pool) do
            list[#list + 1] = { sides = sides, max = n, available = avail[sides] or 0 }
        end
        table.sort(list, function(a, b) return a.sides > b.sides end)
        return list
    end

    -- "3d8 + 2d10 (4 disp.)" para mostrar en la ficha.
    function HD.GetSummaryText(profileName)
        local parts = {}
        for _, e in ipairs(HD.GetSummaryList(profileName)) do
            parts[#parts + 1] = e.max .. "d" .. e.sides
        end
        if #parts == 0 then return "-" end
        return table.concat(parts, " + ") .. " (" .. HD.GetTotalAvailable(profileName) .. " disp.)"
    end

    -- Gasta un dado de un tipo si hay disponible. Devuelve true si gasto.
    function HD.SpendDie(sides, profileName)
        sides = tonumber(sides)
        if not sides then return false end
        if (HD.GetAvailable(profileName)[sides] or 0) <= 0 then return false end
        local entry = hitEntry(profileName)
        entry.spent[sides] = (tonumber(entry.spent[sides]) or 0) + 1
        return true
    end

    -- Descanso largo: recupera floor(total/2) (min 1) dados, de mayor a menor tipo.
    function HD.RegainOnLongRest(profileName)
        local total = HD.GetTotalMax(profileName)
        if total <= 0 then return end
        local regain = math.max(1, math.floor(total / 2))
        local entry = hitEntry(profileName)
        local sidesList = {}
        for sides in pairs(entry.spent) do sidesList[#sidesList + 1] = sides end
        table.sort(sidesList, function(a, b) return a > b end)
        for _, sides in ipairs(sidesList) do
            if regain <= 0 then break end
            local s = tonumber(entry.spent[sides]) or 0
            local take = math.min(s, regain)
            entry.spent[sides] = s - take
            regain = regain - take
        end
        hitPruneIfEmpty(profileName)  -- no persistir entradas a 0
    end
end

-- ===========================================================================
-- Usos de rasgos (Feature Uses): contador ligero para rasgos "X/descanso" cuyo
-- EFECTO no se modela pero el numero de usos si es rastreable (Sentido Divino,
-- Sentir Demonios, Marca de Ursol, Tambaleo, etc.). Solo para el perfil ACTIVO
-- (el max dinamico usa el Mod. de caracteristica via HarfordDnDCalc del jugador).
-- Un rasgo se rastrea declarando `uses = { max=<N|spec>, recharge="short"/"long" }`
-- en HarfordDnDBook/Races/Feats. `max` puede ser un numero fijo o, si es 0/ausente,
-- se calcula como `base + Mod(ability) + perClassLevel*perLevel`, acotado a >= min.
-- Persistencia: HarfordDnDPersistStore.profiles[name]._featureUses[featureId] = gastados.
-- ===========================================================================
HarfordDnDFeatureUses = HarfordDnDFeatureUses or {}
do
    local FU = HarfordDnDFeatureUses
    FU._listeners = FU._listeners or {}

    local function Notify(featureId, profileName)
        for _, listener in ipairs(FU._listeners) do
            -- Un refresco visual no puede impedir gastar, restaurar o recargar
            -- un uso si una ventana fue destruida durante un reload.
            pcall(listener, featureId, ResolveProfileName(profileName))
        end
    end

    -- Punto de refresco comun para cualquier consumidor visual. El estado sigue
    -- siendo propiedad exclusiva de este modulo; las interfaces no necesitan
    -- conocer si el gasto vino de una accion, reaccion, area o descanso.
    function FU.RegisterListener(listener)
        if type(listener) == "function" then
            FU._listeners[#FU._listeners + 1] = listener
        end
    end

    -- Usos de rasgos gastados: profiles[name]._featureUses = { [featureId] = gastados }.
    local function usesProfiles()
        HarfordDnDPersistStore = HarfordDnDPersistStore or {}
        if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
        return HarfordDnDPersistStore.profiles
    end

    -- Entrada de ESCRITURA (crea si no existe); usar solo al gastar.
    local function usesEntry(profileName)
        local profiles = usesProfiles()
        local name = ResolveProfileName(profileName)
        if type(profiles[name]) ~= "table" then profiles[name] = {} end
        local p = profiles[name]
        if type(p._featureUses) ~= "table" then p._featureUses = {} end
        return p._featureUses
    end

    -- Entrada de LECTURA: NO crea nada (leer no debe generar cruft persistido).
    local function usesEntryRead(profileName)
        local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
        local p = profiles and profiles[ResolveProfileName(profileName)]
        return p and p._featureUses or nil
    end

    -- Resuelve el maximo de usos de un rasgo a partir de su spec `uses`.
    function FU.GetMax(uses, profileName)
        if type(uses) ~= "table" then return 0 end
        if type(uses.max) == "number" then return math.max(0, uses.max) end
        local v = tonumber(uses.base) or 0
        if uses.proficiencyBonus and API.GetProficiencyBonus then
            v = v + (tonumber(API.GetProficiencyBonus(profileName)) or 0)
        end
        if uses.ability and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
            v = v + (HarfordDnDCalc.GetAbilityMod(uses.ability) or 0)
        end
        if uses.perClassLevel then
            local lvl = 0
            for _, e in ipairs(API.GetClassLevels(profileName) or {}) do
                if e.classId == uses.perClassLevel then lvl = tonumber(e.level) or 0; break end
            end
            -- `values` da el maximo por nivel de clase (1 uso a nivel 2, 2 a nivel 6...), igual
            -- que resourceMax. Si no lo hay, se mantiene el producto por nivel de siempre.
            if type(uses.values) == "table" then
                v = v + (tonumber(uses.values[lvl]) or 0)
            else
                v = v + lvl * (tonumber(uses.perLevel) or 1)
            end
        end
        if uses.min then v = math.max(tonumber(uses.min) or 0, v) end
        return math.max(0, v)
    end

    function FU.GetSpent(featureId, profileName)
        local e = usesEntryRead(profileName)
        return (e and tonumber(e[tostring(featureId)])) or 0
    end

    function FU.SetSpent(featureId, value, profileName)
        local v = math.max(0, tonumber(value) or 0)
        local id = tostring(featureId)
        if v > 0 then
            usesEntry(profileName)[id] = v
        else
            -- No persistir ceros (default = sin gastar): elimina la entrada y la tabla del
            -- perfil si queda vacia.
            local e = usesEntryRead(profileName)
            if e then
                e[id] = nil
                if next(e) == nil then
                    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
                    local p = profiles and profiles[ResolveProfileName(profileName)]
                    if p then p._featureUses = nil end
                end
            end
        end
        Notify(id, profileName)
    end

    -- Lista de rasgos rastreables del perfil: { featureId, name, max, spent, available, recharge }.
    function FU.GetTracked(profileName)
        local out = {}
        for _, item in ipairs(API.GetUnlockedFeatures(profileName) or {}) do
            local feature = item and item.feature
            local uses = feature and feature.uses
            if uses and (not API.IsFeatureEnabled or API.IsFeatureEnabled(feature, profileName)) then
                local maxUses = FU.GetMax(uses, profileName)
                if maxUses > 0 then
                    local spent = math.min(FU.GetSpent(feature.id, profileName), maxUses)
                    out[#out + 1] = {
                        featureId = feature.id,
                        name = tostring(feature.name or feature.id),
                        max = maxUses,
                        spent = spent,
                        available = maxUses - spent,
                        recharge = uses.recharge or "long",
                    }
                end
            end
        end
        return out
    end

    -- Gasta una cantidad de usos si queda disponible. Sin cantidad conserva el gasto de 1
    -- para los rasgos normales; las reservas, como Imposicion de Manos, pueden gastar PG.
    function FU.Spend(featureId, profileName, amount)
        amount = math.max(1, math.floor(tonumber(amount) or 1))
        local tracked
        for _, t in ipairs(FU.GetTracked(profileName)) do
            if t.featureId == featureId then tracked = t; break end
        end
        if not tracked or tracked.available < amount then return false end
        FU.SetSpent(featureId, tracked.spent + amount, profileName)
        return true
    end

    -- Restaura 1 uso (deshacer). Devuelve true si restauro.
    function FU.Restore(featureId, profileName)
        local spent = FU.GetSpent(featureId, profileName)
        if spent <= 0 then return false end
        FU.SetSpent(featureId, spent - 1, profileName)
        return true
    end

    -- Descanso: "short" recupera los rasgos de recarga "short"; "long" recupera ambos.
    function FU.ResetOnRest(restType, profileName)
        for _, t in ipairs(FU.GetTracked(profileName)) do
            if t.recharge == "short" or restType == "long" then
                FU.SetSpent(t.featureId, 0, profileName)
            end
        end
    end
end
