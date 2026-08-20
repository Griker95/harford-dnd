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
    -- ================================================================
    -- CADENAS COMPLETAS 1-300 (tiers 1/75/150/225/300), inspiradas en las de
    -- WoW Classic y balanceadas a CD 8-18. Los remates a skill 300 son
    -- `worldLearned`: los concede el DM (plano/formula), no se aprenden solos.
    -- ================================================================

    -- ===== Mineria (ampliacion) =====
    { id = "min_piedra", profession = "mineria", skillReq = 10, name = "Extraer piedra aspera", icon = "INV_Stone_12", dc = 10, materials = {}, output = { key = "piedra_aspera", qty = 1 } },
    { id = "min_carbon", profession = "mineria", skillReq = 75, name = "Extraer carbon", icon = "INV_Stone_16", dc = 13, materials = {}, output = { key = "carbon", qty = 1 } },
    { id = "min_mithril", profession = "mineria", skillReq = 175, name = "Extraer mithril", icon = "INV_Ore_Mithril_02", dc = 16, materials = {}, output = { key = "mena_mithril", qty = 1 } },
    { id = "min_torio", profession = "mineria", skillReq = 250, name = "Extraer torio", icon = "INV_Ore_Thorium_02", dc = 17, materials = {}, output = { key = "mena_torio", qty = 1 } },
    { id = "min_roca_oscura", profession = "mineria", skillReq = 300, name = "Extraer roca oscura", icon = "INV_Ore_Arcanite_01", dc = 18, materials = {}, output = { key = "mena_roca_oscura", qty = 1 }, worldLearned = true },

    -- ===== Herboristeria (ampliacion) =====
    { id = "herb_zarzaespina", profession = "herboristeria", skillReq = 50, name = "Recoger zarzaespina", icon = "INV_Misc_Root_01", dc = 12, materials = {}, output = { key = "zarzaespina", qty = 1 } },
    { id = "herb_aceroflor", profession = "herboristeria", skillReq = 85, name = "Recoger aceroflor", icon = "INV_Misc_Flower_02", dc = 13, materials = {}, output = { key = "aceroflor", qty = 1 } },
    { id = "herb_sangrerreal", profession = "herboristeria", skillReq = 125, name = "Recoger sangrerreal", icon = "INV_Misc_Herb_15", dc = 14, materials = {}, output = { key = "sangrerreal", qty = 1 } },
    { id = "herb_raizvida", profession = "herboristeria", skillReq = 150, name = "Recoger raiz de vida", icon = "INV_Misc_Root_02", dc = 15, materials = {}, output = { key = "raizvida", qty = 1 } },
    { id = "herb_espinodorada", profession = "herboristeria", skillReq = 175, name = "Recoger espina dorada", icon = "INV_Misc_Flower_01", dc = 15, materials = {}, output = { key = "espinodorada", qty = 1 } },
    { id = "herb_lotopurpura", profession = "herboristeria", skillReq = 210, name = "Recoger loto purpura", icon = "INV_Misc_Flower_04", dc = 16, materials = {}, output = { key = "lotopurpura", qty = 1 } },
    { id = "herb_matasuenos", profession = "herboristeria", skillReq = 255, name = "Recoger matasuenos", icon = "INV_Misc_Herb_10", dc = 17, materials = {}, output = { key = "matasuenos", qty = 1 } },
    { id = "herb_lotonegro", profession = "herboristeria", skillReq = 300, name = "Recoger loto negro", icon = "INV_Misc_Herb_BlackLotus", dc = 18, materials = {}, output = { key = "lotonegro", qty = 1 }, worldLearned = true },

    -- ===== Desollar (ampliacion) =====
    { id = "des_cuero_medio", profession = "desollar", skillReq = 75, name = "Desollar (cuero medio)", icon = "INV_Misc_LeatherScrap_05", dc = 13, materials = {}, output = { key = "cuero_crudo_medio", qty = 1 } },
    { id = "des_glandula", profession = "desollar", skillReq = 100, name = "Extraer glandula de veneno", icon = "INV_Misc_Organ_01", dc = 14, materials = {}, output = { key = "glandula_veneno", qty = 1 } },
    { id = "des_cuero_pesado", profession = "desollar", skillReq = 150, name = "Desollar (cuero pesado)", icon = "INV_Misc_LeatherScrap_07", dc = 15, materials = {}, output = { key = "cuero_crudo_pesado", qty = 1 } },
    { id = "des_cuero_grueso", profession = "desollar", skillReq = 225, name = "Desollar (cuero grueso)", icon = "INV_Misc_LeatherScrap_08", dc = 16, materials = {}, output = { key = "cuero_crudo_grueso", qty = 1 } },
    { id = "des_escama_dragon", profession = "desollar", skillReq = 300, name = "Desollar escama de dragon", icon = "INV_Misc_MonsterScales_03", dc = 18, materials = {}, output = { key = "escama_dragon", qty = 1 }, worldLearned = true },

    -- ===== Pesca (ampliacion) =====
    { id = "pes_trucha", profession = "pesca", skillReq = 1, name = "Pescar trucha", icon = "INV_Misc_Fish_02", dc = 9, materials = {}, output = { key = "trucha_cruda", qty = 1 } },
    { id = "pes_salmon", profession = "pesca", skillReq = 75, name = "Pescar salmon", icon = "INV_Misc_Fish_32", dc = 12, materials = {}, output = { key = "salmon_crudo", qty = 1 } },
    { id = "pes_bagre", profession = "pesca", skillReq = 125, name = "Pescar bagre", icon = "INV_Misc_Fish_01", dc = 14, materials = {}, output = { key = "bagre_crudo", qty = 1 } },
    { id = "pes_aceitoso", profession = "pesca", skillReq = 175, name = "Pescar pez aceitoso", icon = "INV_Misc_Fish_04", dc = 15, materials = {}, output = { key = "pez_aceitoso", qty = 1 } },
    { id = "pes_piedra", profession = "pesca", skillReq = 225, name = "Pescar pez piedra", icon = "INV_Misc_Fish_20", dc = 16, materials = {}, output = { key = "pez_piedra", qty = 1 } },
    { id = "pes_legendario", profession = "pesca", skillReq = 300, name = "Pescar pez legendario", icon = "INV_Misc_Fish_24", dc = 18, materials = {}, output = { key = "pez_legendario", qty = 1 }, worldLearned = true },

    -- ===== Herreria (ampliacion) =====
    { id = "herr_maza_bronce", profession = "herreria", skillReq = 75, name = "Maza de bronce", icon = "INV_Mace_01", dc = 13, materials = { { key = "lingote_bronce", qty = 3 } }, output = { key = "maza_bronce", qty = 1 } },
    { id = "herr_lingote_hierro", profession = "herreria", skillReq = 125, name = "Fundir hierro", icon = "INV_Ingot_Iron", dc = 13, materials = { { key = "mena_hierro", qty = 1 } }, output = { key = "lingote_hierro", qty = 1 } },
    { id = "herr_cota_hierro", profession = "herreria", skillReq = 140, name = "Cota de escamas de hierro", icon = "INV_Chest_Chain_05", dc = 15, materials = { { key = "lingote_hierro", qty = 6 } }, output = { key = "cota_escamas_hierro", qty = 1 } },
    { id = "herr_lingote_acero", profession = "herreria", skillReq = 150, name = "Fundir acero", icon = "INV_Ingot_Steel", dc = 14, materials = { { key = "lingote_hierro", qty = 1 }, { key = "carbon", qty = 1 } }, output = { key = "lingote_acero", qty = 1 } },
    { id = "herr_espada_acero", profession = "herreria", skillReq = 175, name = "Espada ancha de acero", icon = "INV_Sword_05", dc = 15, materials = { { key = "lingote_acero", qty = 5 } }, output = { key = "espada_ancha_acero", qty = 1 } },
    { id = "herr_escudo_acero", profession = "herreria", skillReq = 200, name = "Escudo de acero", icon = "INV_Shield_05", dc = 16, materials = { { key = "lingote_acero", qty = 4 } }, output = { key = "escudo_acero", qty = 1 } },
    { id = "herr_lingote_mithril", profession = "herreria", skillReq = 225, name = "Fundir mithril", icon = "INV_Ingot_06", dc = 15, materials = { { key = "mena_mithril", qty = 1 } }, output = { key = "lingote_mithril", qty = 1 } },
    { id = "herr_hacha_mithril", profession = "herreria", skillReq = 250, name = "Hacha de mithril", icon = "INV_Axe_04", dc = 16, materials = { { key = "lingote_mithril", qty = 5 } }, output = { key = "hacha_mithril", qty = 1 } },
    { id = "herr_coraza_mithril", profession = "herreria", skillReq = 275, name = "Coraza de mithril", icon = "INV_Chest_Plate04", dc = 17, materials = { { key = "lingote_mithril", qty = 8 } }, output = { key = "coraza_mithril", qty = 1 } },
    { id = "herr_lingote_torio", profession = "herreria", skillReq = 280, name = "Fundir torio", icon = "INV_Ingot_07", dc = 16, materials = { { key = "mena_torio", qty = 1 } }, output = { key = "lingote_torio", qty = 1 } },
    { id = "herr_espada_runica", profession = "herreria", skillReq = 300, name = "Espada runica de torio", icon = "INV_Sword_41", dc = 18, materials = { { key = "lingote_torio", qty = 8 }, { key = "esencia_mayor", qty = 2 } }, output = { key = "espada_runica_torio", qty = 1 }, worldLearned = true },

    -- ===== Peleteria (ampliacion) =====
    { id = "pel_capa_ligera", profession = "peleteria", skillReq = 60, name = "Capa de cuero", icon = "INV_Misc_Cape_11", dc = 12, materials = { { key = "cuero_ligero", qty = 3 } }, output = { key = "capa_cuero", qty = 1 } },
    { id = "pel_curtir_medio", profession = "peleteria", skillReq = 75, name = "Curtir cuero medio", icon = "INV_Misc_LeatherScrap_05", dc = 13, materials = { { key = "cuero_crudo_medio", qty = 1 } }, output = { key = "cuero_medio", qty = 1 } },
    { id = "pel_botas_medio", profession = "peleteria", skillReq = 90, name = "Botas de cuero", icon = "INV_Boots_05", dc = 13, materials = { { key = "cuero_medio", qty = 3 } }, output = { key = "botas_cuero", qty = 1 } },
    { id = "pel_bolsa_cuero", profession = "peleteria", skillReq = 120, name = "Bolsa de cuero", icon = "INV_Misc_Bag_10", dc = 14, materials = { { key = "cuero_medio", qty = 4 } }, output = { key = "bolsa_cuero", qty = 1 } },
    { id = "pel_curtir_pesado", profession = "peleteria", skillReq = 150, name = "Curtir cuero pesado", icon = "INV_Misc_LeatherScrap_07", dc = 14, materials = { { key = "cuero_crudo_pesado", qty = 1 } }, output = { key = "cuero_pesado", qty = 1 } },
    { id = "pel_peto_pesado", profession = "peleteria", skillReq = 175, name = "Peto de cuero pesado", icon = "INV_Chest_Leather_04", dc = 15, materials = { { key = "cuero_pesado", qty = 6 } }, output = { key = "peto_cuero_pesado", qty = 1 } },
    { id = "pel_curtir_grueso", profession = "peleteria", skillReq = 225, name = "Curtir cuero grueso", icon = "INV_Misc_LeatherScrap_08", dc = 15, materials = { { key = "cuero_crudo_grueso", qty = 1 } }, output = { key = "cuero_grueso", qty = 1 } },
    { id = "pel_armadura_gruesa", profession = "peleteria", skillReq = 260, name = "Armadura de cuero grueso", icon = "INV_Chest_Leather_08", dc = 16, materials = { { key = "cuero_grueso", qty = 8 } }, output = { key = "armadura_cuero_grueso", qty = 1 } },
    { id = "pel_armadura_dragon", profession = "peleteria", skillReq = 300, name = "Armadura de escamas de dragon", icon = "INV_Chest_Leather_06", dc = 18, materials = { { key = "escama_dragon", qty = 6 }, { key = "cuero_grueso", qty = 4 } }, output = { key = "armadura_escamas_dragon", qty = 1 }, worldLearned = true },

    -- ===== Sastreria (ampliacion) =====
    { id = "sas_capa_lino", profession = "sastreria", skillReq = 40, name = "Capa de lino", icon = "INV_Misc_Cape_02", dc = 12, materials = { { key = "retal_lino", qty = 3 } }, output = { key = "capa_lino", qty = 1 } },
    { id = "sas_retal_lana", profession = "sastreria", skillReq = 75, name = "Retal de lana", icon = "INV_Fabric_Wool_01", dc = 13, materials = { { key = "tela_lana", qty = 2 } }, output = { key = "retal_lana", qty = 1 } },
    { id = "sas_tunica_lana", profession = "sastreria", skillReq = 95, name = "Tunica de lana", icon = "INV_Chest_Cloth_26", dc = 13, materials = { { key = "retal_lana", qty = 3 } }, output = { key = "tunica_lana", qty = 1 } },
    { id = "sas_retal_seda", profession = "sastreria", skillReq = 150, name = "Retal de seda", icon = "INV_Fabric_Silk_01", dc = 14, materials = { { key = "tela_seda", qty = 2 } }, output = { key = "retal_seda", qty = 1 } },
    { id = "sas_tunica_seda", profession = "sastreria", skillReq = 175, name = "Tunica de seda", icon = "INV_Chest_Cloth_22", dc = 15, materials = { { key = "retal_seda", qty = 3 } }, output = { key = "tunica_seda", qty = 1 } },
    { id = "sas_bolsa_seda", profession = "sastreria", skillReq = 190, name = "Bolsa de seda", icon = "INV_Misc_Bag_09", dc = 15, materials = { { key = "retal_seda", qty = 4 } }, output = { key = "bolsa_seda", qty = 1 } },
    { id = "sas_retal_magico", profession = "sastreria", skillReq = 225, name = "Retal de tejido magico", icon = "INV_Fabric_Mageweave_01", dc = 16, materials = { { key = "tela_tejido_magico", qty = 2 } }, output = { key = "retal_tejido_magico", qty = 1 } },
    { id = "sas_tunica_magica", profession = "sastreria", skillReq = 255, name = "Tunica de tejido magico", icon = "INV_Chest_Cloth_25", dc = 16, materials = { { key = "retal_tejido_magico", qty = 4 } }, output = { key = "tunica_tejido_magico", qty = 1 } },
    { id = "sas_capa_runica", profession = "sastreria", skillReq = 300, name = "Capa runica", icon = "INV_Misc_Cape_16", dc = 18, materials = { { key = "retal_tejido_magico", qty = 6 }, { key = "esencia_mayor", qty = 1 } }, output = { key = "capa_runica", qty = 1 }, worldLearned = true },

    -- ===== Alquimia (ampliacion) =====
    { id = "alq_antidoto", profession = "alquimia", skillReq = 60, name = "Antidoto", icon = "INV_Potion_17", dc = 12, materials = { { key = "zarzaespina", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "antidoto", qty = 1 } },
    { id = "alq_elixir_fuerza", profession = "alquimia", skillReq = 75, name = "Elixir de fuerza", icon = "INV_Potion_61", dc = 13, materials = { { key = "aceroflor", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "elixir_fuerza", qty = 1 } },
    { id = "alq_pocion_curacion", profession = "alquimia", skillReq = 110, name = "Pocion de curacion", icon = "INV_Potion_54", dc = 13, materials = { { key = "sangrerreal", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "pocion_curacion", qty = 1 } },
    { id = "alq_elixir_agilidad", profession = "alquimia", skillReq = 140, name = "Elixir de agilidad", icon = "INV_Potion_95", dc = 14, materials = { { key = "raizvida", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "elixir_agilidad", qty = 1 } },
    { id = "alq_pocion_mayor", profession = "alquimia", skillReq = 180, name = "Pocion de curacion mayor", icon = "INV_Potion_55", dc = 15, materials = { { key = "espinodorada", qty = 1 }, { key = "raizvida", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "pocion_curacion_mayor", qty = 1 } },
    { id = "alq_elixir_sabiduria", profession = "alquimia", skillReq = 210, name = "Elixir de sabiduria", icon = "INV_Potion_97", dc = 16, materials = { { key = "lotopurpura", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "elixir_sabiduria", qty = 1 } },
    { id = "alq_pocion_superior", profession = "alquimia", skillReq = 240, name = "Pocion de curacion superior", icon = "INV_Potion_131", dc = 16, materials = { { key = "matasuenos", qty = 1 }, { key = "lotopurpura", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "pocion_curacion_superior", qty = 1 } },
    { id = "alq_pocion_suprema", profession = "alquimia", skillReq = 300, name = "Pocion de curacion suprema", icon = "INV_Potion_167", dc = 18, materials = { { key = "lotonegro", qty = 1 }, { key = "matasuenos", qty = 2 }, { key = "vial_vacio", qty = 1 } }, output = { key = "pocion_curacion_suprema", qty = 1 }, worldLearned = true },

    -- ===== Cocina (ampliacion) =====
    { id = "coc_trucha_asada", profession = "cocina", skillReq = 10, name = "Trucha asada", icon = "INV_Misc_Fish_02", dc = 9, materials = { { key = "trucha_cruda", qty = 1 } }, output = { key = "trucha_asada", qty = 1 } },
    { id = "coc_estofado", profession = "cocina", skillReq = 75, name = "Estofado sustancioso", icon = "INV_Misc_Food_15", dc = 12, materials = { { key = "carne_cruda", qty = 2 }, { key = "terrablo", qty = 1 } }, output = { key = "estofado_sustancioso", qty = 1 } },
    { id = "coc_salmon_especiado", profession = "cocina", skillReq = 110, name = "Salmon especiado", icon = "INV_Misc_Fish_32", dc = 13, materials = { { key = "salmon_crudo", qty = 1 } }, output = { key = "salmon_especiado", qty = 1 } },
    { id = "coc_filete", profession = "cocina", skillReq = 150, name = "Filete jugoso", icon = "INV_Misc_Food_13", dc = 14, materials = { { key = "carne_cruda", qty = 2 } }, output = { key = "filete_jugoso", qty = 1 } },
    { id = "coc_pastel_pescado", profession = "cocina", skillReq = 190, name = "Pastel de pescado", icon = "INV_Misc_Food_47", dc = 15, materials = { { key = "bagre_crudo", qty = 2 }, { key = "harina", qty = 1 } }, output = { key = "pastel_pescado", qty = 1 } },
    { id = "coc_festin", profession = "cocina", skillReq = 225, name = "Festin de campamento", icon = "INV_Misc_Food_49", dc = 16, materials = { { key = "carne_cruda", qty = 4 }, { key = "pez_piedra", qty = 2 } }, output = { key = "festin_campamento", qty = 1 } },
    { id = "coc_banquete", profession = "cocina", skillReq = 300, name = "Banquete de maestro", icon = "INV_Misc_Food_101", dc = 18, materials = { { key = "pez_legendario", qty = 1 }, { key = "carne_cruda", qty = 4 }, { key = "harina", qty = 2 } }, output = { key = "banquete_maestro", qty = 1 }, worldLearned = true },

    -- ===== Encantamiento (ampliacion) =====
    { id = "enc_desencantar", profession = "encantamiento", skillReq = 1, name = "Desencantar (polvo extrano)", icon = "INV_Enchant_DustStrange", dc = 10, materials = {}, output = { key = "polvo_extrano", qty = 1 } },
    { id = "enc_arma_menor", profession = "encantamiento", skillReq = 50, name = "Encantar arma menor", icon = "INV_Scroll_02", dc = 12, materials = { { key = "polvo_extrano", qty = 3 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_enc_arma_menor", qty = 1 } },
    { id = "enc_esencia_menor", profession = "encantamiento", skillReq = 75, name = "Desencantar (esencia menor)", icon = "INV_Enchant_EssenceMagicSmall", dc = 13, materials = {}, output = { key = "esencia_menor", qty = 1 } },
    { id = "enc_armadura", profession = "encantamiento", skillReq = 100, name = "Encantar armadura", icon = "INV_Scroll_06", dc = 13, materials = { { key = "polvo_extrano", qty = 4 }, { key = "esencia_menor", qty = 1 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_enc_armadura", qty = 1 } },
    { id = "enc_esencia_mayor", profession = "encantamiento", skillReq = 150, name = "Destilar esencia mayor", icon = "INV_Enchant_EssenceMagicLarge", dc = 15, materials = { { key = "esencia_menor", qty = 3 } }, output = { key = "esencia_mayor", qty = 1 } },
    { id = "enc_arma", profession = "encantamiento", skillReq = 175, name = "Encantar arma", icon = "INV_Scroll_07", dc = 15, materials = { { key = "esencia_mayor", qty = 1 }, { key = "polvo_extrano", qty = 5 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_enc_arma", qty = 1 } },
    { id = "enc_fragmento", profession = "encantamiento", skillReq = 225, name = "Desencantar (fragmento brillante)", icon = "INV_Enchant_ShardBrilliantLarge", dc = 16, materials = {}, output = { key = "fragmento_brillante", qty = 1 } },
    { id = "enc_arma_mayor", profession = "encantamiento", skillReq = 250, name = "Encantar arma mayor", icon = "INV_Scroll_11", dc = 16, materials = { { key = "fragmento_brillante", qty = 2 }, { key = "esencia_mayor", qty = 2 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_enc_arma_mayor", qty = 1 } },
    { id = "enc_cristalino", profession = "encantamiento", skillReq = 300, name = "Encantamiento cristalino", icon = "INV_Enchant_PrismaticSphere", dc = 18, materials = { { key = "fragmento_brillante", qty = 4 }, { key = "esencia_mayor", qty = 4 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_enc_cristalino", qty = 1 }, worldLearned = true },

    -- ===== Joyeria (ampliacion) =====
    { id = "joy_prospectar_cobre", profession = "joyeria", skillReq = 20, name = "Prospectar cobre", icon = "INV_Misc_Gem_Emerald_03", dc = 11, materials = { { key = "mena_cobre", qty = 3 } }, output = { key = "gema_malaquita", qty = 1 } },
    { id = "joy_colgante_malaquita", profession = "joyeria", skillReq = 40, name = "Colgante de malaquita", icon = "INV_Jewelry_Necklace_07", dc = 12, materials = { { key = "gema_malaquita", qty = 1 }, { key = "lingote_cobre", qty = 1 } }, output = { key = "colgante_malaquita", qty = 1 } },
    { id = "joy_anillo_bronce", profession = "joyeria", skillReq = 75, name = "Anillo de bronce", icon = "INV_Jewelry_Ring_14", dc = 13, materials = { { key = "lingote_bronce", qty = 2 } }, output = { key = "anillo_bronce", qty = 1 } },
    { id = "joy_prospectar_hierro", profession = "joyeria", skillReq = 125, name = "Prospectar hierro", icon = "INV_Misc_Gem_Emerald_02", dc = 14, materials = { { key = "mena_hierro", qty = 3 } }, output = { key = "gema_jade", qty = 1 } },
    { id = "joy_anillo_jade", profession = "joyeria", skillReq = 150, name = "Anillo de jade", icon = "INV_Jewelry_Ring_03", dc = 15, materials = { { key = "gema_jade", qty = 1 }, { key = "lingote_hierro", qty = 1 } }, output = { key = "anillo_jade", qty = 1 } },
    { id = "joy_prospectar_mithril", profession = "joyeria", skillReq = 225, name = "Prospectar mithril", icon = "INV_Misc_Gem_Sapphire_02", dc = 16, materials = { { key = "mena_mithril", qty = 3 } }, output = { key = "gema_aguamarina", qty = 1 } },
    { id = "joy_amuleto_mithril", profession = "joyeria", skillReq = 250, name = "Amuleto de mithril", icon = "INV_Jewelry_Necklace_03", dc = 16, materials = { { key = "gema_aguamarina", qty = 1 }, { key = "lingote_mithril", qty = 2 } }, output = { key = "amuleto_mithril", qty = 1 } },
    { id = "joy_corona_torio", profession = "joyeria", skillReq = 300, name = "Corona de torio", icon = "INV_Crown_02", dc = 18, materials = { { key = "lingote_torio", qty = 4 }, { key = "gema_aguamarina", qty = 2 } }, output = { key = "corona_torio", qty = 1 }, worldLearned = true },

    -- ===== Inscripcion (ampliacion) =====
    { id = "ins_moler_tenue", profession = "inscripcion", skillReq = 1, name = "Moler pigmento tenue", icon = "INV_Inscription_Pigment_01", dc = 9, materials = { { key = "paciflor", qty = 2 } }, output = { key = "pigmento_tenue", qty = 1 } },
    { id = "ins_moler_ambar", profession = "inscripcion", skillReq = 75, name = "Moler pigmento ambar", icon = "INV_Inscription_Pigment_04", dc = 13, materials = { { key = "zarzaespina", qty = 2 } }, output = { key = "pigmento_ambar", qty = 1 } },
    { id = "ins_pergamino_proteccion", profession = "inscripcion", skillReq = 95, name = "Pergamino de proteccion", icon = "INV_Scroll_05", dc = 13, materials = { { key = "pigmento_ambar", qty = 1 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_proteccion", qty = 1 } },
    { id = "ins_moler_esmeralda", profession = "inscripcion", skillReq = 150, name = "Moler pigmento esmeralda", icon = "INV_Inscription_Pigment_07", dc = 15, materials = { { key = "raizvida", qty = 2 } }, output = { key = "pigmento_esmeralda", qty = 1 } },
    { id = "ins_pergamino_mayor", profession = "inscripcion", skillReq = 175, name = "Pergamino mayor", icon = "INV_Scroll_04", dc = 15, materials = { { key = "pigmento_esmeralda", qty = 1 }, { key = "pergamino", qty = 1 } }, output = { key = "pergamino_inscrito_mayor", qty = 1 } },
    { id = "ins_glifo", profession = "inscripcion", skillReq = 225, name = "Glifo de guerra", icon = "INV_Inscription_Scroll", dc = 16, materials = { { key = "pigmento_esmeralda", qty = 2 }, { key = "pergamino", qty = 1 } }, output = { key = "glifo_guerra", qty = 1 } },
    { id = "ins_tomo", profession = "inscripcion", skillReq = 300, name = "Tomo de secretos", icon = "INV_Misc_Book_09", dc = 18, materials = { { key = "pigmento_esmeralda", qty = 4 }, { key = "lotonegro", qty = 1 }, { key = "pergamino", qty = 5 } }, output = { key = "tomo_secretos", qty = 1 }, worldLearned = true },

    -- ===== Primeros Auxilios (ampliacion) =====
    { id = "pa_vendaje_lana", profession = "primeros_auxilios", skillReq = 75, name = "Vendaje de lana", icon = "INV_Misc_Bandage_02", dc = 12, materials = { { key = "retal_lana", qty = 1 } }, output = { key = "vendaje_lana", qty = 1 } },
    { id = "pa_antiveneno", profession = "primeros_auxilios", skillReq = 100, name = "Antiveneno", icon = "INV_Drink_14", dc = 14, materials = { { key = "glandula_veneno", qty = 1 }, { key = "vial_vacio", qty = 1 } }, output = { key = "antiveneno", qty = 1 } },
    { id = "pa_vendaje_seda", profession = "primeros_auxilios", skillReq = 150, name = "Vendaje de seda", icon = "INV_Misc_Bandage_01", dc = 14, materials = { { key = "retal_seda", qty = 1 } }, output = { key = "vendaje_seda", qty = 1 } },
    { id = "pa_vendaje_magico", profession = "primeros_auxilios", skillReq = 225, name = "Vendaje de tejido magico", icon = "INV_Misc_Bandage_12", dc = 16, materials = { { key = "retal_tejido_magico", qty = 1 } }, output = { key = "vendaje_tejido_magico", qty = 1 } },
    { id = "pa_botiquin", profession = "primeros_auxilios", skillReq = 300, name = "Botiquin de maestro", icon = "INV_Misc_Bag_11", dc = 18, materials = { { key = "vendaje_tejido_magico", qty = 4 }, { key = "antiveneno", qty = 2 } }, output = { key = "botiquin_maestro", qty = 1 }, worldLearned = true },

}
