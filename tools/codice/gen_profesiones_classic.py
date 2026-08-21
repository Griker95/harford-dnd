# -*- coding: utf-8 -*-
"""Genera las cadenas de profesion al estilo Classic y las inserta en los .lua.

Escala: Harford usa 1-300 (tiers 1/75/150/225/300), la misma que Vanilla, asi que
las profesiones de Classic van con sus valores reales. Joyeria es de TBC (1-375) e
Inscripcion de Lich (1-450): sus umbrales se comprimen a 1-300 (x0.8 y x2/3).

Idempotente: no toca recetas ni claves que ya existan (los ids son referenciados
por la SavedVariable HarfordProfessionsStore y NO se pueden renombrar).
"""
import io
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

BASE = 'Harford/Professions/'
DATA = BASE + 'HarfordProfessionsData.lua'
ITEMS = BASE + 'HarfordProfessionsItems.lua'

TBC = 0.8          # 375 -> 300
LICH = 2.0 / 3.0   # 450 -> 300


def dc_for(skill):
    """CD de la tirada: 8 en lo trivial, 18 en el remate (misma banda que ya habia)."""
    return max(8, min(18, 8 + skill // 30))


# ---------------------------------------------------------------- items nuevos
# clave -> nombre visible. id se deja nil: la receta sale "pendiente" hasta que
# se coseche el itemId real de Epsilon (modelo ya establecido).
NEW_ITEMS = {
    # Mineria / piedras
    'mena_oro': 'Mena de oro', 'lingote_oro': 'Barra de oro',
    'veta_verdadera': 'Veta verdadera', 'lingote_verdadero': 'Barra de plata verdadera',
    'piedra_gruesa': 'Piedra gruesa', 'piedra_pesada': 'Piedra pesada',
    'piedra_solida': 'Piedra solida', 'piedra_densa': 'Piedra densa',
    # Herreria
    'brazales_cobre': 'Brazales de cobre', 'yelmo_cobre': 'Casco de cobre',
    'piedra_afilar_tosca': 'Piedra de afilar tosca', 'piedra_afilar_pesada': 'Piedra de afilar pesada',
    'guanteletes_bronce': 'Guanteletes de bronce', 'grebas_bronce': 'Grebas de bronce',
    'maza_hierro': 'Maza de hierro', 'yelmo_hierro': 'Yelmo de hierro',
    'espada_bastarda_acero': 'Espada bastarda de acero', 'hombreras_acero': 'Hombreras de acero',
    'escudo_mithril': 'Escudo de mithril', 'yelmo_mithril': 'Yelmo de mithril',
    'espada_torio': 'Espada de torio', 'coraza_torio': 'Coraza de torio',
    # Peleteria
    'cuero_curtido': 'Cuero curtido', 'brazales_cuero': 'Brazales de cuero',
    'hombreras_cuero': 'Hombreras de cuero', 'guantes_cuero_pesado': 'Guantes de cuero pesado',
    'capa_cuero_grueso': 'Capa de cuero grueso', 'botas_cuero_curtido': 'Botas de cuero curtido',
    # Sastreria
    'tela_runica': 'Tela runica', 'retal_runico': 'Retal de tela runica',
    'pantalones_lino': 'Pantalones de lino', 'brazales_lana': 'Brazales de lana',
    'capa_lana': 'Capa de lana', 'botas_lana': 'Botas de lana',
    'pantalones_seda': 'Pantalones de seda', 'guantes_seda': 'Guantes de seda',
    'capa_seda': 'Capa de seda', 'pantalones_magico': 'Pantalones de tejido magico',
    'capucha_magica': 'Capucha de tejido magico', 'tunica_runica': 'Tunica runica',
    'bolsa_runica': 'Bolsa runica',
    # Alquimia
    'pocion_mana_menor': 'Pocion de mana menor', 'pocion_mana': 'Pocion de mana',
    'elixir_defensa': 'Elixir de defensa', 'elixir_giganteza': 'Elixir de giganteza',
    'pocion_invisibilidad': 'Pocion de invisibilidad', 'elixir_mente': 'Elixir de mente aguda',
    'frasco_titanes': 'Frasco de los titanes',
    # Cocina
    'sopa_verduras': 'Sopa de verduras', 'carne_especiada': 'Carne especiada',
    'pastel_carne': 'Pastel de carne', 'guiso_cazador': 'Guiso del cazador',
    # Encantamiento
    'polvo_iluminado': 'Polvo iluminado', 'esencia_etérea': 'Esencia eterea',
    'pergamino_enc_capa': 'Pergamino: encantar capa', 'pergamino_enc_botas': 'Pergamino: encantar botas',
    'pergamino_enc_escudo': 'Pergamino: encantar escudo', 'varita_menor': 'Varita magica menor',
    # Joyeria (TBC)
    'alambre_cobre': 'Alambre de cobre delicado', 'engaste_bronce': 'Engaste de bronce',
    'engaste_plata': 'Engaste de plata', 'engaste_oro': 'Engaste de oro',
    'gema_ojotigre': 'Ojo de tigre', 'gema_citrina': 'Citrina',
    'gema_zafiro': 'Zafiro estrella', 'gema_rubi': 'Rubi carmesi',
    'anillo_ojotigre': 'Anillo de ojo de tigre', 'pendiente_citrina': 'Pendiente de citrina',
    'brazalete_zafiro': 'Brazalete de zafiro', 'estatuilla_rubi': 'Estatuilla de rubi',
    # Inscripcion (Lich)
    'tinta_tenue': 'Tinta tenue', 'tinta_ambar': 'Tinta ambar',
    'tinta_esmeralda': 'Tinta esmeralda', 'tinta_umbria': 'Tinta umbria',
    'pigmento_umbrio': 'Pigmento umbrio',
    'glifo_menor': 'Glifo menor', 'glifo_mayor': 'Glifo mayor',
    'carta_destino': 'Carta del destino', 'baraja_presagios': 'Baraja de presagios',
    # Primeros auxilios
    'vendaje_runico': 'Vendaje de tela runica', 'ungüento_curativo': 'Unguento curativo',
    # Venenos (la profesion estaba a medias)
    'veneno_debilitante': 'Veneno debilitante', 'veneno_paralizante': 'Veneno paralizante',
    'veneno_mortal': 'Veneno mortal', 'veneno_sombrio': 'Veneno de las sombras',
    'esencia_veneno': 'Esencia de veneno',
}

# ------------------------------------------------------------- recetas nuevas
# (id, profesion, skillReq, nombre, icono, [(clave, qty), ...], (clave_salida, qty), worldLearned)
R = []


def add(rid, prof, skill, name, icon, mats, out, world=False):
    R.append((rid, prof, int(round(skill)), name, icon, mats, out, world))


# ===== Mineria: completa el set de Classic (oro, veta verdadera, piedras) =====
add('min_oro', 'mineria', 155, 'Extraer oro', 'INV_Ore_Gold_01', [], ('mena_oro', 1))
add('min_veta_verdadera', 'mineria', 230, 'Extraer veta verdadera', 'INV_Ore_TrueSilver_01', [], ('veta_verdadera', 1))
add('min_piedra_gruesa', 'mineria', 65, 'Extraer piedra gruesa', 'INV_Stone_09', [], ('piedra_gruesa', 1))
add('min_piedra_pesada', 'mineria', 125, 'Extraer piedra pesada', 'INV_Stone_10', [], ('piedra_pesada', 1))
add('min_piedra_solida', 'mineria', 190, 'Extraer piedra solida', 'INV_Stone_11', [], ('piedra_solida', 1))
add('min_piedra_densa', 'mineria', 245, 'Extraer piedra densa', 'INV_Stone_13', [], ('piedra_densa', 1))

# ===== Herreria: relleno Classic entre los hitos que ya existian =====
add('herr_brazales_cobre', 'herreria', 20, 'Brazales de cobre', 'INV_Bracer_02', [('lingote_cobre', 3)], ('brazales_cobre', 1))
add('herr_yelmo_cobre', 'herreria', 45, 'Casco de cobre', 'INV_Helmet_09', [('lingote_cobre', 4)], ('yelmo_cobre', 1))
add('herr_afilar_tosca', 'herreria', 1, 'Piedra de afilar tosca', 'INV_Stone_SharpeningStone_01', [('piedra_aspera', 1)], ('piedra_afilar_tosca', 1))
add('herr_afilar_pesada', 'herreria', 110, 'Piedra de afilar pesada', 'INV_Stone_SharpeningStone_03', [('piedra_pesada', 1)], ('piedra_afilar_pesada', 1))
add('herr_guanteletes_bronce', 'herreria', 95, 'Guanteletes de bronce', 'INV_Gauntlets_04', [('lingote_bronce', 4)], ('guanteletes_bronce', 1))
add('herr_grebas_bronce', 'herreria', 115, 'Grebas de bronce', 'INV_Boots_05', [('lingote_bronce', 5)], ('grebas_bronce', 1))
add('herr_lingote_oro', 'herreria', 160, 'Fundir oro', 'INV_Ingot_02', [('mena_oro', 1)], ('lingote_oro', 1))
add('herr_maza_hierro', 'herreria', 155, 'Maza de hierro', 'INV_Mace_02', [('lingote_hierro', 4)], ('maza_hierro', 1))
add('herr_yelmo_hierro', 'herreria', 165, 'Yelmo de hierro', 'INV_Helmet_10', [('lingote_hierro', 5)], ('yelmo_hierro', 1))
add('herr_espada_bastarda', 'herreria', 190, 'Espada bastarda de acero', 'INV_Sword_20', [('lingote_acero', 6)], ('espada_bastarda_acero', 1))
add('herr_hombreras_acero', 'herreria', 205, 'Hombreras de acero', 'INV_Shoulder_21', [('lingote_acero', 6)], ('hombreras_acero', 1))
add('herr_lingote_verdadero', 'herreria', 235, 'Fundir plata verdadera', 'INV_Ingot_Mithril', [('veta_verdadera', 1)], ('lingote_verdadero', 1))
add('herr_escudo_mithril', 'herreria', 240, 'Escudo de mithril', 'INV_Shield_10', [('lingote_mithril', 6)], ('escudo_mithril', 1))
add('herr_yelmo_mithril', 'herreria', 255, 'Yelmo de mithril', 'INV_Helmet_22', [('lingote_mithril', 5)], ('yelmo_mithril', 1))
add('herr_espada_torio', 'herreria', 290, 'Espada de torio', 'INV_Sword_29', [('lingote_torio', 6)], ('espada_torio', 1))
add('herr_coraza_torio', 'herreria', 295, 'Coraza de torio', 'INV_Chest_Plate03', [('lingote_torio', 10), ('lingote_verdadero', 2)], ('coraza_torio', 1))

# ===== Peleteria =====
add('pel_brazales_ligero', 'peleteria', 20, 'Brazales de cuero', 'INV_Bracer_03', [('cuero_ligero', 2)], ('brazales_cuero', 1))
add('pel_hombreras_medio', 'peleteria', 105, 'Hombreras de cuero', 'INV_Shoulder_10', [('cuero_medio', 4)], ('hombreras_cuero', 1))
add('pel_guantes_pesado', 'peleteria', 190, 'Guantes de cuero pesado', 'INV_Gauntlets_17', [('cuero_pesado', 4)], ('guantes_cuero_pesado', 1))
add('pel_curtir_curtido', 'peleteria', 205, 'Curtir cuero curtido', 'INV_Misc_LeatherScrap_11', [('cuero_pesado', 2), ('piedra_solida', 1)], ('cuero_curtido', 1))
add('pel_botas_curtido', 'peleteria', 240, 'Botas de cuero curtido', 'INV_Boots_08', [('cuero_curtido', 4)], ('botas_cuero_curtido', 1))
add('pel_capa_gruesa', 'peleteria', 280, 'Capa de cuero grueso', 'INV_Misc_Cape_08', [('cuero_grueso', 5)], ('capa_cuero_grueso', 1))

# ===== Sastreria (incluye la rama de tela runica que faltaba) =====
add('sas_pantalones_lino', 'sastreria', 30, 'Pantalones de lino', 'INV_Pants_11', [('retal_lino', 3)], ('pantalones_lino', 1))
add('sas_brazales_lana', 'sastreria', 85, 'Brazales de lana', 'INV_Bracer_07', [('retal_lana', 2)], ('brazales_lana', 1))
add('sas_capa_lana', 'sastreria', 110, 'Capa de lana', 'INV_Misc_Cape_04', [('retal_lana', 3)], ('capa_lana', 1))
add('sas_botas_lana', 'sastreria', 125, 'Botas de lana', 'INV_Boots_09', [('retal_lana', 3)], ('botas_lana', 1))
add('sas_pantalones_seda', 'sastreria', 160, 'Pantalones de seda', 'INV_Pants_08', [('retal_seda', 3)], ('pantalones_seda', 1))
add('sas_guantes_seda', 'sastreria', 170, 'Guantes de seda', 'INV_Gauntlets_17', [('retal_seda', 2)], ('guantes_seda', 1))
add('sas_capa_seda', 'sastreria', 200, 'Capa de seda', 'INV_Misc_Cape_07', [('retal_seda', 4)], ('capa_seda', 1))
add('sas_pantalones_magico', 'sastreria', 240, 'Pantalones de tejido magico', 'INV_Pants_07', [('retal_tejido_magico', 4)], ('pantalones_magico', 1))
add('sas_retal_runico', 'sastreria', 250, 'Retal de tela runica', 'INV_Fabric_Purple_01', [('tela_runica', 2)], ('retal_runico', 1))
add('sas_capucha_magica', 'sastreria', 265, 'Capucha de tejido magico', 'INV_Helmet_20', [('retal_tejido_magico', 3)], ('capucha_magica', 1))
add('sas_bolsa_runica', 'sastreria', 275, 'Bolsa runica', 'INV_Misc_Bag_11', [('retal_runico', 4)], ('bolsa_runica', 1))
add('sas_tunica_runica', 'sastreria', 285, 'Tunica runica', 'INV_Chest_Cloth_18', [('retal_runico', 5)], ('tunica_runica', 1))

# ===== Alquimia =====
add('alq_pocion_mana_menor', 'alquimia', 55, 'Pocion de mana menor', 'INV_Potion_70', [('hojaplata', 1), ('vial_vacio', 1)], ('pocion_mana_menor', 1))
add('alq_elixir_defensa', 'alquimia', 105, 'Elixir de defensa', 'INV_Potion_67', [('cardopresto', 1), ('vial_vacio', 1)], ('elixir_defensa', 1))
add('alq_elixir_giganteza', 'alquimia', 145, 'Elixir de giganteza', 'INV_Potion_62', [('hierba_cardenal', 1), ('vial_vacio', 1)], ('elixir_giganteza', 1))
add('alq_pocion_mana', 'alquimia', 165, 'Pocion de mana', 'INV_Potion_73', [('musgo_tumba', 1), ('sangrerreal', 1), ('vial_vacio', 1)], ('pocion_mana', 1))
add('alq_transmutar_oro', 'alquimia', 175, 'Transmutar hierro en oro', 'INV_Ingot_02', [('lingote_hierro', 1), ('esencia_menor', 1)], ('lingote_oro', 1))
add('alq_pocion_invisibilidad', 'alquimia', 200, 'Pocion de invisibilidad', 'INV_Potion_18', [('espinodorada', 1), ('matasuenos', 1), ('vial_vacio', 1)], ('pocion_invisibilidad', 1))
add('alq_elixir_mente', 'alquimia', 230, 'Elixir de mente aguda', 'INV_Potion_92', [('lotopurpura', 1), ('raizvida', 1), ('vial_vacio', 1)], ('elixir_mente', 1))
add('alq_frasco_titanes', 'alquimia', 290, 'Frasco de los titanes', 'INV_Potion_62', [('lotonegro', 1), ('espinodorada', 2), ('vial_vacio', 1)], ('frasco_titanes', 1))

# ===== Cocina =====
add('coc_sopa_verduras', 'cocina', 40, 'Sopa de verduras', 'INV_Drink_16', [('paciflor', 1), ('harina', 1)], ('sopa_verduras', 1))
add('coc_carne_especiada', 'cocina', 90, 'Carne especiada', 'INV_Misc_Food_60', [('carne_cruda', 1), ('marregal', 1)], ('carne_especiada', 1))
add('coc_pastel_carne', 'cocina', 170, 'Pastel de carne', 'INV_Misc_Food_44', [('carne_cruda', 2), ('harina', 1)], ('pastel_carne', 1))
add('coc_guiso_cazador', 'cocina', 245, 'Guiso del cazador', 'INV_Misc_Food_15', [('carne_cruda', 3), ('pez_aceitoso', 1), ('musgo_tumba', 1)], ('guiso_cazador', 1))

# ===== Encantamiento =====
add('enc_polvo_iluminado', 'encantamiento', 125, 'Desencantar (polvo iluminado)', 'INV_Enchant_DustIllusion', [], ('polvo_iluminado', 1))
add('enc_capa', 'encantamiento', 80, 'Encantar capa', 'INV_Scroll_02', [('polvo_extrano', 2), ('pergamino', 1)], ('pergamino_enc_capa', 1))
add('enc_botas', 'encantamiento', 130, 'Encantar botas', 'INV_Scroll_03', [('polvo_iluminado', 2), ('pergamino', 1)], ('pergamino_enc_botas', 1))
add('enc_escudo', 'encantamiento', 200, 'Encantar escudo', 'INV_Scroll_05', [('polvo_iluminado', 3), ('esencia_menor', 1), ('pergamino', 1)], ('pergamino_enc_escudo', 1))
add('enc_esencia_eterea', 'encantamiento', 275, 'Destilar esencia eterea', 'INV_Enchant_EssenceEtherealLarge', [('esencia_mayor', 2), ('fragmento_brillante', 1)], ('esencia_etérea', 1))
add('enc_varita_menor', 'encantamiento', 110, 'Varita magica menor', 'INV_Wand_01', [('polvo_extrano', 3), ('lingote_cobre', 1)], ('varita_menor', 1))

# ===== Ingenieria =====
add('ing_piedra_afilada', 'ingenieria', 20, 'Perno de arco', 'INV_Ammo_Bullet_01', [('piedra_aspera', 1), ('lingote_cobre', 1)], ('pernos_cobre', 2))
add('ing_bomba_hierro', 'ingenieria', 165, 'Granada de hierro', 'INV_Misc_Bomb_08', [('lingote_hierro', 1), ('polvo_tosco', 3)], ('dinamita_tosca', 2))

# ===== Joyeria: progresion de TBC comprimida a 1-300 (x0.8) =====
add('joy_alambre_cobre', 'joyeria', 20 * TBC, 'Alambre de cobre delicado', 'INV_Misc_Wire_01', [('lingote_cobre', 1)], ('alambre_cobre', 2))
add('joy_gema_ojotigre', 'joyeria', 20 * TBC, 'Tallar ojo de tigre', 'INV_Misc_Gem_Opal_02', [('gema_malaquita', 1)], ('gema_ojotigre', 1))
add('joy_anillo_ojotigre', 'joyeria', 30 * TBC, 'Anillo de ojo de tigre', 'INV_Jewelry_Ring_08', [('gema_ojotigre', 1), ('alambre_cobre', 1)], ('anillo_ojotigre', 1))
add('joy_engaste_bronce', 'joyeria', 50 * TBC, 'Engaste de bronce', 'INV_Misc_EngGizmos_20', [('lingote_bronce', 1)], ('engaste_bronce', 1))
add('joy_gema_citrina', 'joyeria', 110 * TBC, 'Tallar citrina', 'INV_Misc_Gem_Opal_01', [('gema_jade', 1)], ('gema_citrina', 1))
add('joy_pendiente_citrina', 'joyeria', 130 * TBC, 'Pendiente de citrina', 'INV_Jewelry_Necklace_11', [('gema_citrina', 1), ('engaste_bronce', 1)], ('pendiente_citrina', 1))
add('joy_engaste_plata', 'joyeria', 150 * TBC, 'Engaste de plata', 'INV_Misc_EngGizmos_19', [('lingote_plata', 1)], ('engaste_plata', 1))
add('joy_gema_zafiro', 'joyeria', 250 * TBC, 'Tallar zafiro estrella', 'INV_Misc_Gem_Sapphire_01', [('gema_aguamarina', 1)], ('gema_zafiro', 1))
add('joy_brazalete_zafiro', 'joyeria', 270 * TBC, 'Brazalete de zafiro', 'INV_Bracer_15', [('gema_zafiro', 1), ('engaste_plata', 1)], ('brazalete_zafiro', 1))
add('joy_engaste_oro', 'joyeria', 300 * TBC, 'Engaste de oro', 'INV_Misc_EngGizmos_18', [('lingote_oro', 1)], ('engaste_oro', 1))
add('joy_gema_rubi', 'joyeria', 340 * TBC, 'Tallar rubi carmesi', 'INV_Misc_Gem_Ruby_02', [('gema_aguamarina', 2)], ('gema_rubi', 1))
add('joy_estatuilla_rubi', 'joyeria', 360 * TBC, 'Estatuilla de rubi', 'INV_Misc_Statue_04', [('gema_rubi', 1), ('engaste_oro', 1)], ('estatuilla_rubi', 1))

# ===== Inscripcion: progresion de Lich comprimida a 1-300 (x2/3).
# Añade la fase de TINTA que faltaba: hierba -> pigmento -> tinta -> glifo/pergamino.
add('ins_tinta_tenue', 'inscripcion', 1, 'Tinta tenue', 'INV_Inscription_INK_01', [('pigmento_tenue', 1)], ('tinta_tenue', 2))
add('ins_tinta_ambar', 'inscripcion', 105 * LICH, 'Tinta ambar', 'INV_Inscription_INK_04', [('pigmento_ambar', 1)], ('tinta_ambar', 2))
add('ins_glifo_menor', 'inscripcion', 75 * LICH, 'Glifo menor', 'INV_Inscription_MinorGlyph01', [('tinta_tenue', 1), ('pergamino', 1)], ('glifo_menor', 1))
add('ins_moler_umbrio', 'inscripcion', 275 * LICH, 'Moler pigmento umbrio', 'INV_Inscription_Pigment_09', [('lotopurpura', 2)], ('pigmento_umbrio', 1))
add('ins_tinta_esmeralda', 'inscripcion', 225 * LICH, 'Tinta esmeralda', 'INV_Inscription_INK_07', [('pigmento_esmeralda', 1)], ('tinta_esmeralda', 2))
add('ins_tinta_umbria', 'inscripcion', 300 * LICH, 'Tinta umbria', 'INV_Inscription_INK_09', [('pigmento_umbrio', 1)], ('tinta_umbria', 2))
add('ins_glifo_mayor', 'inscripcion', 350 * LICH, 'Glifo mayor', 'INV_Inscription_MajorGlyph01', [('tinta_esmeralda', 2), ('pergamino', 1)], ('glifo_mayor', 1))
add('ins_carta_destino', 'inscripcion', 380 * LICH, 'Carta del destino', 'INV_Inscription_Card_Sun', [('tinta_umbria', 1), ('pergamino', 2)], ('carta_destino', 1))
add('ins_baraja_presagios', 'inscripcion', 425 * LICH, 'Baraja de presagios', 'INV_Misc_Ticket_Tarot_Madness', [('carta_destino', 4)], ('baraja_presagios', 1))

# ===== Primeros auxilios =====
add('pa_unguento', 'primeros_auxilios', 45, 'Unguento curativo', 'INV_Potion_16', [('paciflor', 1), ('vial_vacio', 1)], ('ungüento_curativo', 1))
add('pa_vendaje_runico', 'primeros_auxilios', 260, 'Vendaje de tela runica', 'INV_Misc_Bandage_15', [('retal_runico', 1)], ('vendaje_runico', 1))

# ===== Fabricar venenos: la profesion tenia UNA receta y se atascaba en 101 =====
add('env_esencia_veneno', 'envenenador', 60, 'Destilar esencia de veneno', 'INV_Potion_19', [('glandula_veneno', 1), ('vial_vacio', 1)], ('esencia_veneno', 1))
add('env_debilitante', 'envenenador', 110, 'Veneno debilitante', 'INV_Potion_20', [('esencia_veneno', 1), ('zarzaespina', 1), ('vial_vacio', 1)], ('veneno_debilitante', 1))
add('env_paralizante', 'envenenador', 175, 'Veneno paralizante', 'INV_Potion_21', [('esencia_veneno', 1), ('musgo_tumba', 1), ('vial_vacio', 1)], ('veneno_paralizante', 1))
add('env_mortal', 'envenenador', 240, 'Veneno mortal', 'INV_Potion_22', [('esencia_veneno', 2), ('matasuenos', 1), ('vial_vacio', 1)], ('veneno_mortal', 1))
add('env_sombrio', 'envenenador', 300, 'Veneno de las sombras', 'INV_Potion_24', [('esencia_veneno', 3), ('lotonegro', 1), ('vial_vacio', 1)], ('veneno_sombrio', 1), world=True)


# ------------------------------------------------------------------ escritura
data = io.open(DATA, encoding='utf-8').read()
items = io.open(ITEMS, encoding='utf-8').read()

existing_ids = set(re.findall(r'\{\s*id\s*=\s*"([\w_]+)"\s*,\s*profession', data))
existing_keys = set(re.findall(r'\["(\w+)"\]\s*=\s*\{', items))

# --- registro
new_keys = [(k, n) for k, n in NEW_ITEMS.items() if k not in existing_keys]
if new_keys:
    block = ['\n    -- ===== Cadenas Classic / TBC (joyeria) / Lich (inscripcion) =====']
    for k, n in sorted(new_keys):
        block.append('    ["%s"]%s= { id = nil, name = "%s" },'
                     % (k, ' ' * max(1, 28 - len(k)), n))
    marker = '\n}'
    idx = items.index(marker, items.index('API.REGISTRY'))
    items = items[:idx] + '\n' + '\n'.join(block) + items[idx:]
    io.open(ITEMS, 'w', encoding='utf-8', newline='\n').write(items)

# --- recetas
new_recipes = [r for r in R if r[0] not in existing_ids]
if new_recipes:
    lines = ['', '    -- ================================================================',
             '    -- Cadenas al estilo Classic (1-300, la misma escala que Vanilla).',
             '    -- Joyeria usa la progresion de TBC comprimida x0.8 (375 -> 300) e',
             '    -- Inscripcion la de Lich comprimida x2/3 (450 -> 300), incluida su',
             '    -- fase de TINTA (hierba -> pigmento -> tinta -> glifo), que faltaba.',
             '    -- Generado por tools/codice/gen_profesiones_classic.py',
             '    -- ================================================================']
    order = {}
    for r in new_recipes:
        order.setdefault(r[1], []).append(r)
    for prof in sorted(order):
        lines.append('')
        lines.append('    -- ===== %s =====' % prof)
        for rid, p, skill, name, icon, mats, out, world in sorted(order[prof], key=lambda x: x[2]):
            mat_txt = ', '.join('{ key = "%s", qty = %d }' % (k, q) for k, q in mats)
            lines.append(
                '    { id = "%s", profession = "%s", skillReq = %d, name = "%s", icon = "%s", dc = %d, '
                'materials = { %s }, output = { key = "%s", qty = %d }%s },'
                % (rid, p, skill, name, icon, dc_for(skill), mat_txt, out[0], out[1],
                   ', worldLearned = true' if world else ''))
    marker = '\n}\n'
    idx = data.rindex(marker)
    data = data[:idx] + '\n' + '\n'.join(lines) + data[idx:]
    io.open(DATA, 'w', encoding='utf-8', newline='\n').write(data)

print('recetas nuevas: %d (de %d definidas)' % (len(new_recipes), len(R)))
print('claves nuevas:  %d (de %d definidas)' % (len(new_keys), len(NEW_ITEMS)))
