------------------------------------------------------------
-- HarfordProfessionsData - Catalogo hardcodeado de profesiones + recetas (como HarfordDnDBook).
-- Solo datos. El core (HarfordProfessions) consume esto; los IDs de item viven en
-- HarfordProfessionsItems (aqui se referencian por CLAVE, nunca por ID).
--
-- profesion: { id, name, tool=<nombre exacto de competencia o nil>, kind="craft"/"gather"/"utility",
--              ability=<caracteristica de la tirada>, icon }
-- receta:    { id, profession, skillReq, name, icon, dc, ability?=<override>, worldLearned?,
--              materials = { { key, qty }, ... },   -- vacio en recolección
--              output    = { key, qty } }
------------------------------------------------------------

HarfordProfessionsData = HarfordProfessionsData or {}
local D = HarfordProfessionsData

D.PROFESSIONS = {
    -- ===== WoW (con equivalente de herramienta D&D donde existe) =====
    { id = "herreria",     name = "Herreria",         tool = "Herramientas de herrero",       kind = "craft",  ability = "Fuerza",       icon = "Trade_BlackSmithing" },
    { id = "alquimia",     name = "Alquimia",         tool = "Suministros de alquimista",     kind = "craft",  ability = "Inteligencia", icon = "Trade_Alchemy" },
    { id = "herboristeria",name = "Herboristeria",    tool = "Kit de herborista",             kind = "gather", ability = "Sabiduria",    icon = "Trade_Herbalism" },
    { id = "mineria",      name = "Mineria",          tool = nil,                             kind = "gather", ability = "Fuerza",       icon = "Trade_Mining" },
    { id = "peleteria",    name = "Peleteria",        tool = "Herramientas de curtidor",      kind = "craft",  ability = "Destreza",     icon = "Trade_LeatherWorking" },
    { id = "desollar",     name = "Desollar",         tool = nil,                             kind = "gather", ability = "Destreza",     icon = "INV_Misc_Pelt_Wolf_01" },
    { id = "sastreria",    name = "Sastreria",        tool = "Herramientas de tejedor",       kind = "craft",  ability = "Destreza",     icon = "Trade_Tailoring" },
    { id = "encantamiento",name = "Encantamiento",    tool = nil,                             kind = "craft",  ability = "Inteligencia", icon = "Trade_Engraving" },
    { id = "ingenieria",   name = "Ingenieria",       tool = "Herramientas de hojalatero",    kind = "craft",  ability = "Inteligencia", icon = "Trade_Engineering" },
    { id = "joyeria",      name = "Joyeria",          tool = "Herramientas de joyero",        kind = "craft",  ability = "Inteligencia", icon = "INV_Misc_Gem_Variety_01" },
    { id = "inscripcion",  name = "Inscripcion",      tool = "Suministros de caligrafia",     kind = "craft",  ability = "Inteligencia", icon = "INV_Inscription_Tradeskill01" },
    { id = "cocina",       name = "Cocina",           tool = "Utiles de cocinero",            kind = "craft",  ability = "Sabiduria",    icon = "INV_Misc_Food_15" },
    { id = "pesca",        name = "Pesca",            tool = nil,                             kind = "gather", ability = "Sabiduria",    icon = "Trade_Fishing" },
    { id = "primeros_auxilios", name = "Primeros Auxilios", tool = "Kit de sanador",         kind = "craft",  ability = "Sabiduria",    icon = "Spell_Holy_SealOfSacrifice" },

    -- ===== Artesanias D&D (sin equivalente WoW directo) =====
    { id = "carpinteria",  name = "Carpinteria",      tool = "Herramientas de carpintero",    kind = "craft",  ability = "Fuerza",       icon = "Trade_Engineering" },
    { id = "cartografia",  name = "Cartografia",      tool = "Herramientas de cartografo",    kind = "craft",  ability = "Inteligencia", icon = "INV_Misc_Map_01" },
    { id = "zapateria",    name = "Zapateria",        tool = "Herramientas de zapatero",      kind = "craft",  ability = "Destreza",     icon = "INV_Boots_Cloth_05" },
    { id = "soplavidrio",  name = "Soplado de vidrio",tool = "Herramientas de soplador de vidrio", kind = "craft", ability = "Destreza", icon = "INV_Misc_Orb_02" },
    { id = "albanileria",  name = "Albanileria",      tool = "Herramientas de albanil",       kind = "craft",  ability = "Fuerza",       icon = "Trade_BrewPoison" },
    { id = "pintura",      name = "Pintura",          tool = "Suministros de pintor",         kind = "craft",  ability = "Destreza",     icon = "INV_Misc_Dye_01" },
    { id = "alfareria",    name = "Alfareria",        tool = "Herramientas de alfarero",      kind = "craft",  ability = "Destreza",     icon = "INV_Misc_Pot_01" },
    { id = "talla_madera", name = "Talla de madera",  tool = "Herramientas de tallador de madera", kind = "craft", ability = "Destreza", icon = "INV_Misc_Wood_01" },
    { id = "cerveceria",   name = "Cerveceria",       tool = "Suministros de cervecero",      kind = "craft",  ability = "Inteligencia", icon = "INV_Drink_05" },
    { id = "envenenador",  name = "Fabricar venenos", tool = "Utiles de envenenador",         kind = "craft",  ability = "Inteligencia", icon = "Trade_BrewPoison" },

    -- ===== Utility (no craftean: dan tirada de uso de herramienta) =====
    { id = "disfraz",      name = "Kit de disfraz",   tool = "Kit de disfraz",                kind = "utility",ability = "Carisma",      icon = "INV_Mask_01" },
    { id = "falsificacion",name = "Falsificacion",    tool = "Kit de falsificacion",          kind = "utility",ability = "Destreza",     icon = "INV_Scroll_08" },
    { id = "ladron",       name = "Herramientas de ladron", tool = "Herramientas de ladron",  kind = "utility",ability = "Destreza",     icon = "INV_Misc_Key_03" },
    { id = "navegante",    name = "Navegacion",       tool = "Herramientas de navegante",     kind = "utility",ability = "Inteligencia", icon = "INV_Misc_Spyglass_02" },
    { id = "instrumento",  name = "Instrumento musical", tool = "Instrumento musical",        kind = "utility",ability = "Carisma",      icon = "INV_Misc_Drum_02" },
    { id = "juego",        name = "Juego de azar",    tool = "Juego de azar",                 kind = "utility",ability = "Carisma",      icon = "INV_Misc_Dice_01" },
}

-- ============================================================
-- RECETAS. skillReq = skill numerico requerido (tiers: 1/75/150/225/300).
-- Materiales/output por CLAVE del registro HarfordProfessionsItems.
-- ============================================================
D.RECIPES = {
    -- ===== Mineria (gather: sin materiales, tirada -> mena) =====
    { id = "min_cobre",   profession = "mineria", skillReq = 1,   name = "Extraer cobre",   icon = "INV_Ore_Copper_01", dc = 10, materials = {}, output = { key = "mena_cobre",   qty = 1 } },
    { id = "min_estano",  profession = "mineria", skillReq = 65,  name = "Extraer estano",  icon = "INV_Ore_Tin_01",    dc = 13, materials = {}, output = { key = "mena_estano",  qty = 1 } },
    { id = "min_hierro",  profession = "mineria", skillReq = 125, name = "Extraer hierro",  icon = "INV_Ore_Iron",      dc = 15, materials = {}, output = { key = "mena_hierro",  qty = 1 } },

    -- ===== Herboristeria (gather) =====
    { id = "herb_pazflor",profession = "herboristeria", skillReq = 1,  name = "Recoger paciflor", icon = "INV_Misc_Herb_07", dc = 10, materials = {}, output = { key = "paciflor",   qty = 1 } },
    { id = "herb_terra",  profession = "herboristeria", skillReq = 15, name = "Recoger terrablo", icon = "INV_Misc_Herb_01", dc = 12, materials = {}, output = { key = "terrablo",   qty = 1 } },

    -- ===== Herreria (funde mena -> lingote; forja arma) =====
    { id = "herr_lingote_cobre", profession = "herreria", skillReq = 1,  name = "Fundir cobre",       icon = "INV_Ingot_Copper",         dc = 8,  materials = { { key = "mena_cobre", qty = 1 } }, output = { key = "lingote_cobre", qty = 1 } },
    { id = "herr_daga_cobre",    profession = "herreria", skillReq = 1,  name = "Daga de cobre",      icon = "INV_Weapon_ShortBlade_05", dc = 11, materials = { { key = "lingote_cobre", qty = 2 } }, output = { key = "daga_cobre",   qty = 1 } },
    { id = "herr_espada_cobre",  profession = "herreria", skillReq = 30, name = "Espada de cobre",    icon = "INV_Sword_04",             dc = 13, materials = { { key = "lingote_cobre", qty = 4 } }, output = { key = "espada_cobre", qty = 1 } },
    { id = "herr_broncebar",     profession = "herreria", skillReq = 50, name = "Fundir bronce",      icon = "INV_Ingot_03",             dc = 12, materials = { { key = "lingote_cobre", qty = 1 }, { key = "mena_estano", qty = 1 } }, output = { key = "lingote_bronce", qty = 1 } },

    -- ===== Peleteria (cuero -> equipo) =====
    { id = "pel_curtir_ligero", profession = "peleteria", skillReq = 1,  name = "Curtir cuero ligero", icon = "INV_Misc_LeatherScrap_02", dc = 9,  materials = { { key = "cuero_crudo_ligero", qty = 1 } }, output = { key = "cuero_ligero", qty = 1 } },
    { id = "pel_guantes_cuero", profession = "peleteria", skillReq = 1,  name = "Guantes de cuero",    icon = "INV_Gauntlets_04",         dc = 11, materials = { { key = "cuero_ligero", qty = 2 } }, output = { key = "guantes_cuero", qty = 1 } },
    { id = "pel_armadura_cuero",profession = "peleteria", skillReq = 40, name = "Peto de cuero",       icon = "INV_Chest_Leather_03",     dc = 14, materials = { { key = "cuero_ligero", qty = 5 } }, output = { key = "peto_cuero", qty = 1 } },

    -- ===== Desollar (gather) =====
    { id = "des_cuero_ligero", profession = "desollar", skillReq = 1, name = "Desollar (cuero ligero)", icon = "INV_Misc_LeatherScrap_02", dc = 10, materials = {}, output = { key = "cuero_crudo_ligero", qty = 1 } },

    -- ===== Sastreria (tela -> equipo) =====
    { id = "sas_hilar_lino",  profession = "sastreria", skillReq = 1,  name = "Retal de lino",   icon = "INV_Fabric_Linen_01", dc = 9,  materials = { { key = "tela_lino", qty = 2 } }, output = { key = "retal_lino", qty = 1 } },
    { id = "sas_tunica_lino", profession = "sastreria", skillReq = 1,  name = "Tunica de lino",  icon = "INV_Chest_Cloth_21",  dc = 11, materials = { { key = "retal_lino", qty = 2 } }, output = { key = "tunica_lino", qty = 1 } },
    { id = "sas_bolsa_lino",  profession = "sastreria", skillReq = 20, name = "Bolsa de lino",   icon = "INV_Misc_Bag_08",     dc = 12, materials = { { key = "retal_lino", qty = 3 } }, output = { key = "bolsa_lino", qty = 1 } },

    -- ===== Alquimia (hierbas -> pociones) =====
    { id = "alq_pocion_menor", profession = "alquimia", skillReq = 1,  name = "Pocion de curacion menor", icon = "INV_Potion_51", dc = 10, materials = { { key = "paciflor", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "pocion_curacion_menor", qty = 1 } },
    { id = "alq_pocion_leve",  profession = "alquimia", skillReq = 50, name = "Pocion de curacion leve",  icon = "INV_Potion_52", dc = 13, materials = { { key = "terrablo", qty = 1 }, { key = "paciflor", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "pocion_curacion_leve", qty = 1 } },

    -- ===== Cocina =====
    { id = "coc_pan",          profession = "cocina", skillReq = 1,  name = "Pan recien horneado", icon = "INV_Misc_Food_49", dc = 8,  materials = { { key = "harina", qty = 1 } }, output = { key = "pan", qty = 1 } },
    { id = "coc_carne_asada",  profession = "cocina", skillReq = 1,  name = "Carne asada",         icon = "INV_Misc_Food_59", dc = 10, materials = { { key = "carne_cruda", qty = 1 } }, output = { key = "carne_asada", qty = 1 } },

    -- ===== Primeros Auxilios =====
    { id = "pa_vendaje",       profession = "primeros_auxilios", skillReq = 1, name = "Vendaje de lino", icon = "INV_Misc_Bandage_01", dc = 9, materials = { { key = "retal_lino", qty = 1 } }, output = { key = "vendaje_lino", qty = 1 } },

    -- ===== Joyeria =====
    { id = "joy_anillo_cobre", profession = "joyeria", skillReq = 1, name = "Anillo de cobre", icon = "INV_Jewelry_Ring_03", dc = 11, materials = { { key = "lingote_cobre", qty = 1 } }, output = { key = "anillo_cobre", qty = 1 } },

    -- ===== Inscripcion =====
    { id = "ins_pergamino_menor", profession = "inscripcion", skillReq = 1, name = "Pergamino menor", icon = "INV_Scroll_03", dc = 10, materials = { { key = "pigmento_tenue", qty = 1 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_inscrito_menor", qty = 1 } },

    -- ===== Fabricar venenos (envenenador) =====
    { id = "env_veneno_basico", profession = "envenenador", skillReq = 1, name = "Veneno basico", icon = "Trade_BrewPoison", dc = 12, materials = { { key = "terrablo", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "veneno_basico", qty = 1 } },
}
