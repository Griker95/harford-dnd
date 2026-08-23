# -*- coding: utf-8 -*-
# Genera js/compendium-equipment.js: armas del addon (HarfordDnDWeapons) + armaduras estandar (SRD).
import io, re, os, json, sys, unicodedata
sys.stdout.reconfigure(encoding="utf-8")
import glob
sys.path.insert(0, r"C:/Users/marco/Documents/New project/RuleSource")
from metrico import a_metrico
H = glob.glob(r"C:/Users/marco/Documents/New project/Harford/**/HarfordDnDWeapons.lua", recursive=True)[0]
WEB = r"C:/Users/marco/Documents/harfordweb"

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
def slug(s): return re.sub(r"[^a-z0-9]+", "-", sa(s).lower()).strip("-")

t = io.open(H, encoding="utf-8").read()
CAT_ES = {"Simple":"Sencilla", "Marcial":"Marcial", "Especial":"Especial",
          "De fuego":"De fuego", "Racial":"Racial", "Otros":"Otros"}
items = []
for m in re.finditer(r'\{ key="([^"]+)", cat="([^"]+)", mode="([^"]+)", dmgN=(\d+), dmgS=(\d+), dmgType="([^"]*)"[^}]*?props=\{([^}]*)\}', t):
    key, cat, mode, dmgN, dmgS, dmgType, propsraw = m.groups()
    props = [p for p in re.findall(r'"([^"]+)"', propsraw)]
    propBase = [re.sub(r"\s*\([^)]*\)\s*$", "", p) for p in props]
    if int(dmgN) == 0 or not dmgType:
        dmg = "—"
    elif key == "Desarmado":
        dmg = "1 %s" % dmgType
    else:
        dmg = "%sd%s %s" % (dmgN, dmgS, dmgType)
    items.append({
        "id": "arma-" + slug(key), "name": key, "kind": "weapon",
        "category": CAT_ES.get(cat, cat),
        "range": "Distancia" if mode == "Ranged" else "Cuerpo a cuerpo",
        "damage": dmg, "damageType": dmgType.capitalize() if dmgType else "—",
        "props": props, "propBase": propBase,
    })

# armaduras estandar (SRD, ES). ac = texto de CA; props = requisitos/notas.
ARMORS = [
    ("Armadura acolchada", "Ligera", "11 + Mod. Destreza", ["Sigilo con desventaja"]),
    ("Armadura de cuero", "Ligera", "11 + Mod. Destreza", []),
    ("Cuero tachonado", "Ligera", "12 + Mod. Destreza", []),
    ("Armadura de pieles", "Intermedia", "12 + Mod. Destreza (máx. 2)", []),
    ("Camisa de mallas", "Intermedia", "13 + Mod. Destreza (máx. 2)", []),
    ("Coraza", "Intermedia", "14 + Mod. Destreza (máx. 2)", []),
    ("Cota de escamas", "Intermedia", "14 + Mod. Destreza (máx. 2)", ["Sigilo con desventaja"]),
    ("Media placa", "Intermedia", "15 + Mod. Destreza (máx. 2)", ["Sigilo con desventaja"]),
    ("Cota de anillas", "Pesada", "14", ["Sigilo con desventaja"]),
    ("Cota de mallas", "Pesada", "16", ["Fuerza 13", "Sigilo con desventaja"]),
    ("Cota de bandas", "Pesada", "17", ["Fuerza 15", "Sigilo con desventaja"]),
    ("Armadura de placas", "Pesada", "18", ["Fuerza 15", "Sigilo con desventaja"]),
    ("Escudo", "Escudo", "+2", []),
]
ARMORS = [(n, c, a_metrico(a), [a_metrico(x) for x in ns]) for n, c, a, ns in ARMORS]
for name, cat, ac, notes in ARMORS:
    items.append({
        "id": "armadura-" + slug(name), "name": name, "kind": "armor",
        "category": cat, "ac": ac, "props": notes, "propBase": notes,
    })

# ---- equipo de aventuras, herramientas y transporte (datos de tabla: precio y peso) ----
# El PDF trae estas tablas a tres columnas y el texto sale mezclado ("21b", "l po"),
# asi que los valores se recogen como datos en vez de extraerlos del texto.
GEAR = [
    # (nombre, categoria, precio, peso, nota)
    ("Mochila", "Equipo de aventuras", "2 po", "5 lb", "Capacidad de 30 litros o 15 kg."),
    ("Saco de dormir", "Equipo de aventuras", "1 po", "7 lb", ""),
    ("Raciones (1 día)", "Equipo de aventuras", "5 pp", "2 lb", "Comida seca para un día."),
    ("Odre", "Equipo de aventuras", "2 pc", "5 lb", "Lleno pesa 5 lb."),
    ("Antorcha", "Equipo de aventuras", "1 pc", "1 lb", "Luz brillante en 6 metros y tenue 6 metros más, durante 1 hora."),
    ("Linterna sorda", "Equipo de aventuras", "5 po", "2 lb", "Cono de luz brillante de 18 metros, 6 horas por frasco de aceite."),
    ("Farol con capucha", "Equipo de aventuras", "5 po", "2 lb", "Luz brillante en 9 metros y tenue 9 metros más, 6 horas por frasco."),
    ("Aceite (frasco)", "Consumibles", "1 pp", "1 lb", "Arrojadizo: 5 de daño de fuego."),
    ("Yesquero", "Equipo de aventuras", "5 pp", "1 lb", "Encender una antorcha es una acción."),
    ("Cuerda de cáñamo (15 metros)", "Equipo de aventuras", "1 po", "10 lb", "CD 17 de Fuerza para romperla."),
    ("Cuerda de seda (15 metros)", "Equipo de aventuras", "10 po", "5 lb", "CD 17 de Fuerza para romperla."),
    ("Garfio", "Equipo de aventuras", "2 po", "4 lb", ""),
    ("Pica de escalada", "Equipo de aventuras", "5 pc", "1/4 lb", ""),
    ("Palanca", "Equipo de aventuras", "2 po", "5 lb", "Ventaja en pruebas de Fuerza donde sirva de palanca."),
    ("Martillo", "Equipo de aventuras", "1 po", "3 lb", ""),
    ("Pala", "Equipo de aventuras", "2 po", "5 lb", ""),
    ("Piqueta de minero", "Equipo de aventuras", "2 po", "10 lb", ""),
    ("Cadena (3 metros)", "Equipo de aventuras", "5 po", "10 lb", "CD 20 de Fuerza para romperla."),
    ("Esposas", "Equipo de aventuras", "2 po", "6 lb", "Escapar: CD 20 de Destreza; romperlas: CD 20 de Fuerza."),
    ("Cerradura", "Equipo de aventuras", "10 po", "1 lb", "Abrirla con herramientas de ladrón: CD 15."),
    ("Campana", "Equipo de aventuras", "1 po", "—", ""),
    ("Vela", "Equipo de aventuras", "1 pc", "—", "Luz brillante en 1,5 metros y tenue 1,5 metros más, durante 1 hora."),
    ("Catalejo", "Equipo de aventuras", "1.000 po", "1 lb", "Los objetos se ven al doble de tamaño."),
    ("Lupa", "Equipo de aventuras", "100 po", "—", "Ventaja al examinar detalles pequeños; sirve para prender fuego."),
    ("Reloj de arena", "Equipo de aventuras", "25 po", "1 lb", ""),
    ("Brújula", "Equipo de aventuras", "—", "—", ""),
    ("Piedra de afilar", "Equipo de aventuras", "1 pc", "1 lb", ""),
    ("Estuche de mapas y pergaminos", "Equipo de aventuras", "1 po", "1 lb", ""),
    ("Pergamino (hoja)", "Equipo de aventuras", "1 pp", "—", ""),
    ("Tinta (frasco de 1 onza)", "Equipo de aventuras", "10 po", "—", ""),
    ("Pluma de escribir", "Equipo de aventuras", "2 pc", "—", ""),
    ("Bolsa de componentes", "Canalizadores", "25 po", "2 lb", "Sustituye los componentes materiales sin coste indicado."),
    ("Símbolo sagrado", "Canalizadores", "5 po", "1 lb", "Canalizador divino de clérigos y paladines."),
    ("Foco druídico", "Canalizadores", "10 po", "3 lb", "Rama de muérdago, tótem, bastón o vara de tejo."),
    ("Orbe arcano", "Canalizadores", "20 po", "3 lb", "Canalizador arcano."),
    ("Varita", "Canalizadores", "10 po", "1 lb", "Canalizador arcano."),
    ("Poción de curación", "Consumibles", "50 po", "1/2 lb", "Recuperas 2d4 + 2 puntos de golpe al beberla."),
    ("Antitoxina (vial)", "Consumibles", "50 po", "—", "Ventaja en salvaciones contra veneno durante 1 hora."),
    ("Agua bendita (frasco)", "Consumibles", "25 po", "1 lb", "Arrojadiza: 2d6 de daño radiante a muertos vivientes y demonios."),
    ("Fuego del alquimista (frasco)", "Consumibles", "50 po", "1 lb", "Arrojadiza: 1d4 de fuego al inicio de cada turno hasta apagarla."),
    ("Ácido (vial)", "Consumibles", "25 po", "1 lb", "Arrojadizo: 2d6 de daño de ácido."),
    ("Veneno básico (vial)", "Consumibles", "100 po", "—", "Recubre un arma: 1d4 de veneno, salvación de Constitución CD 10."),
    ("Kit de sanador", "Herramientas", "5 po", "3 lb", "10 usos: estabiliza a una criatura moribunda sin prueba."),
    ("Herramientas de ladrón", "Herramientas", "25 po", "1 lb", "Forzar cerraduras y desarmar trampas."),
    ("Herramientas de artesano", "Herramientas", "varía", "varía", "Un juego por oficio: herrero, carpintero, alfarero…"),
    ("Útiles de disfraz", "Herramientas", "25 po", "3 lb", "Cambiar tu apariencia física."),
    ("Útiles de falsificación", "Herramientas", "15 po", "5 lb", "Crear documentos falsos."),
    ("Instrumento musical", "Herramientas", "varía", "varía", "Laúd, flauta, tambor, lira…"),
    ("Kit de herborista", "Herramientas", "5 po", "3 lb", "Identificar plantas y preparar remedios."),
    ("Kit de veneno", "Herramientas", "50 po", "2 lb", "Manipular venenos con seguridad."),
    ("Kit de envenenador", "Herramientas", "50 po", "2 lb", "Aplicar y preparar venenos."),
    ("Naipes", "Herramientas", "5 pp", "—", "Juego."),
    ("Dados", "Herramientas", "1 pp", "—", "Juego."),
    ("Ajedrez de dragones", "Herramientas", "1 po", "1/2 lb", "Juego."),
    ("Flechas (20)", "Munición", "1 po", "1 lb", "Para arco corto o largo."),
    ("Virotes (20)", "Munición", "1 po", "1 1/2 lb", "Para ballesta."),
    ("Balas de honda (20)", "Munición", "4 pc", "1 1/2 lb", ""),
    ("Dardos de cerbatana (50)", "Munición", "1 po", "1 lb", ""),
    ("Balas de arma de fuego (10)", "Munición", "3 po", "2 lb", "Para pistolas, mosquetes y rifles."),
    ("Caballo de monta", "Monturas", "75 po", "—", "Velocidad 18 metros, carga 240 kg."),
    ("Caballo de guerra", "Monturas", "400 po", "—", "Velocidad 18 metros, carga 270 kg."),
    ("Poni", "Monturas", "30 po", "—", "Velocidad 12 metros, carga 112 kg."),
    ("Mastín", "Monturas", "25 po", "—", "Velocidad 12 metros, carga 97 kg."),
    ("Mula", "Monturas", "8 po", "—", "Velocidad 12 metros, carga 210 kg."),
    ("Camello", "Monturas", "50 po", "—", "Velocidad 15 metros, carga 240 kg."),
    ("Silla de montar", "Monturas", "10 po", "25 lb", ""),
    ("Alforjas", "Monturas", "4 po", "8 lb", "Capacidad de 6 litros o 15 kg."),
    ("Carro", "Vehículos", "15 po", "200 lb", ""),
    ("Carreta", "Vehículos", "15 po", "200 lb", ""),
    ("Carruaje", "Vehículos", "100 po", "600 lb", ""),
    ("Barcaza", "Vehículos", "3.000 po", "—", "Velocidad 1,6 km/h."),
    ("Barco de vela", "Vehículos", "10.000 po", "—", "Velocidad 3,2 km/h."),
    ("Galera", "Vehículos", "30.000 po", "—", "Velocidad 6,4 km/h."),
    ("Bote de remos", "Vehículos", "50 po", "100 lb", "Velocidad 2,4 km/h."),
    ("Paquete de explorador", "Paquetes", "10 po", "59 lb", "Mochila, saco de dormir, utensilios, yesquero, 10 antorchas, 10 días de raciones, odre y 15 metros de cuerda."),
    ("Paquete de erudito", "Paquetes", "40 po", "10 lb", "Mochila, libro de conocimiento, tinta, pluma, 10 hojas de pergamino, saquito de arena y cuchillo."),
    ("Paquete de mazmorrero", "Paquetes", "12 po", "61 lb", "Mochila, palanca, martillo, 10 pitones, 10 antorchas, yesquero, 10 días de raciones, odre y 15 metros de cuerda."),
    ("Paquete de sacerdote", "Paquetes", "19 po", "24 lb", "Mochila, manta, 10 velas, yesquero, caja de limosnas, 2 bloques de incienso, incensario, vestiduras, raciones y odre."),
    ("Paquete de artista", "Paquetes", "40 po", "38 lb", "Mochila, saco de dormir, 2 disfraces, 5 velas, raciones, odre y kit de disfraz."),
    ("Paquete de burglar", "Paquetes", "16 po", "44 lb", "Mochila, bolsa de canicas, 3 metros de cordel, campana, 5 velas, palanca, martillo, 10 pitones, farol, 2 frascos de aceite, raciones, yesquero, odre y cuerda."),
    ("Paquete de diplomático", "Paquetes", "39 po", "38 lb", "Cofre, 2 estuches de mapas, ropas finas, tinta, pluma, lámpara, 2 frascos de aceite, papel, perfume, cera de lacrar y jabón."),
]
for nombre, cat, precio, peso, nota in GEAR:
    items.append({"id": "obj-" + slug(nombre), "name": nombre, "kind": "gear",
                  "category": cat, "price": precio, "weight": a_metrico(peso),
                  "props": [], "propBase": [], "note": a_metrico(nota)})

# Iconos ELEGIDOS A MANO, por nombre exacto. Mandan sobre las palabras clave de abajo,
# que solo son un reparto por familia y dejaban cosas como la clava y la gran clava con
# el mismo dibujo, o un hacha arrojadiza haciendo de dardo. No sobrescribir sin permiso.
ICONO_MANUAL = {
    "jabalina": "inv_weapon_halberd_ahnqiraj",
    "hacha de batalla": "inv_axe_18",
    "arco corto": "inv_weapon_bow_05",
    "cerbatana": "inv_blowdart_zandalari",
    "clava": "inv_mace_11",
    "gran clava": "inv_mace_10",
    "dardo": "inv_throwingknife_05",
    "hacha de mano": "inv_axe_14",
    "honda": "ability_hunter_beastcall02",
    "hoz": "inv_misc_1h_farmsickle_a_01",
    "lanza": "inv_polearm_2h_draenorcrafted_d_01_a",
    "alabarda": "inv_weapon_halberd_02",
    # Armaduras: los mismos iconos que la ficha del addon (BASIC_ARMOR en
    # HarfordDnDItems.lua), una por pieza. Antes las 12 compartian tres dibujos.
    "armadura acolchada": "inv_chest_leather_03",
    "armadura de cuero": "inv_chest_leather_09",
    "cuero tachonado": "inv_chest_cloth_45",
    "armadura de pieles": "inv_chest_leather_06",
    "camisa de mallas": "inv_chest_chain",
    "coraza": "inv_chest_plate04",
    "cota de escamas": "inv_chest_chain_05",
    "media placa": "inv_chest_plate06",
    "cota de anillas": "inv_chest_chain_17",
    "cota de mallas": "inv_chest_chain_06",
    "cota de bandas": "inv_chest_plate01",
    "armadura de placas": "inv_chest_plate02",
    "martillo ligero": "inv_hammer_17",
    "pica": "inv_spear_06",
    "arco largo": "inv_weapon_bow_02",
    "ballesta de mano": "inv_weapon_crossbow_03",
    "ballesta pesada": "inv_weapon_crossbow_04",
    "cimitarra": "inv_sword_24",
    "espada larga": "inv_sword_20",
    "espadon": "inv_sword_23",
    "estoque": "inv_sword_30",
    "flagelo": "eps_lol_sejuani_flailofthenorthernwinds2",
    "guja": "inv_weapon_halberd_04",
    "lanza de caballeria": "inv_spear_05",
    "latigo": "inv_misc_crop_01",
    "lucero del alba": "inv_mace_05",
    "martillo de guerra": "inv_hammer_07",
    "mazo de guerra": "inv_hammer_11",
    "pico de guerra": "inv_hammer_19",
    "tridente": "inv_spear_07",
    "pistola": "eps_plunder_piratepistol_03",
    "rifle": "inv_weapon_rifle_04",
    "escopeta": "inv_weapon_rifle_08",
    "martillo arrojadizo enano": "inv_hammer_21",
    "espada quel'dorei": "inv_sword_bloodelf_03",
    "espada lunar kal'dorei": "inv_sword_2h_warfrontsnightelf_d_01",
    "guja lunar kal'dorei": "inv_glaive_1h_tyrande_d_01",
    "doble hoja sin'dorei": "inv_sword_28",
    "alabarda tauren": "inv_weapon_halberd_09",
    "totem de guerra tauren": "inv_relics_totemofrebirth",
    "garra de guerra orca": "inv_hand_1h_bwdraid_d_01",
    "guja de guerra": "inv_glaive_1h_newplayer_a_01",
    "aquajet": "inv_weapon_rifle_33",
}
# iconos: arma por tipo (palabra clave del nombre), armadura por categoria
ARMOR_ICON = {"Ligera": "inv_chest_leather_09", "Intermedia": "inv_chest_chain_05",
              "Pesada": "inv_chest_plate06", "Escudo": "inv_shield_04"}
WEAPON_KW = [  # orden = prioridad
    ("espad", "inv_sword_04"), ("cimitarra", "inv_sword_04"), ("estoque", "inv_sword_04"),
    ("daga", "inv_weapon_shortblade_05"), ("hacha", "inv_axe_09"),
    ("maza", "inv_mace_01"), ("martillo", "inv_mace_01"), ("clava", "inv_mace_01"), ("mangual", "inv_mace_01"), ("luce", "inv_mace_01"),
    ("lanza", "inv_spear_05"), ("pica", "inv_spear_05"), ("alabarda", "inv_spear_05"), ("guja", "inv_spear_05"), ("tridente", "inv_spear_05"), ("jabalina", "inv_spear_05"),
    ("ballesta", "inv_weapon_crossbow_02"), ("arco", "inv_weapon_bow_08"),
    ("honda", "inv_ammo_bullet_01"), ("cerbatana", "inv_ammo_bullet_01"),
    ("baston", "inv_staff_08"), ("vara", "inv_staff_08"), ("garrote", "inv_staff_08"),
    ("pistola", "inv_weapon_rifle_01"), ("mosquete", "inv_weapon_rifle_01"), ("rifle", "inv_weapon_rifle_01"), ("arcabuz", "inv_weapon_rifle_01"),
    ("red", "inv_misc_net_01"), ("dardo", "inv_throwingaxe_01"), ("desarmado", "inv_gauntlets_04")]
GEAR_ICON = [("mochila","inv_misc_bag_08"),("saco","inv_misc_bag_10"),("racion","inv_misc_food_15"),
    ("odre","inv_drink_05"),("antorcha","inv_torch_lit"),("linterna","inv_misc_lantern_01"),
    ("farol","inv_misc_lantern_01"),("aceite","inv_potion_38"),("yesquero","spell_fire_flameblades"),
    ("cuerda","inv_misc_rope_01"),("garfio","inv_misc_hook_01"),("pica","inv_misc_spyglass_02"),
    ("palanca","inv_misc_wrench_01"),("martillo","inv_hammer_16"),("pala","inv_misc_shovel_01"),
    ("piqueta","inv_pick_02"),("cadena","ability_deathknight_deathchain"),("esposas","inv_misc_bandage_15"),
    ("cerradura","inv_misc_key_03"),("campana","inv_misc_bell_01"),("vela","inv_misc_candle_01"),
    ("espejo","inv_misc_enggizmos_20"),("catalejo","inv_misc_spyglass_02"),("lupa","inv_misc_spyglass_01"),
    ("reloj","inv_misc_pocketwatch_01"),("brujula","inv_misc_pocketwatch_02"),("piedra","inv_stone_15"),
    ("estuche","inv_scroll_04"),("pergamino","inv_scroll_03"),("tinta","inv_inscription_80_ultramarinepigment"),
    ("pluma","inv_feather_15"),("componentes","inv_misc_bag_11"),("simbolo","inv_jewelry_talisman_05"),
    ("druidico","inv_staff_01"),("orbe","inv_misc_orb_01"),("varita","inv_wand_01"),
    ("pocion","inv_potion_51"),("antitoxina","inv_potion_19"),("agua bendita","inv_potion_27"),
    ("fuego del alquimista","inv_potion_33"),("acido","inv_potion_25"),("veneno","inv_potion_16"),
    ("sanador","inv_misc_bandage_08"),("ladron","inv_misc_key_10"),("artesano","trade_blacksmithing"),
    ("disfraz","inv_mask_01"),("falsificacion","inv_scroll_11"),("instrumento","inv_misc_drum_01"),
    ("herborista","inv_misc_herb_10"),("envenenador","inv_misc_dust_02"),("naipes","inv_misc_ticket_tarot_madness"),
    ("dados","inv_misc_dice_01"),("ajedrez","inv_misc_toy_10"),("flecha","inv_ammo_arrow_02"),
    ("virote","inv_ammo_bullet_02"),("bala","inv_ammo_bullet_01"),("dardo","inv_throwingknife_02"),
    ("caballo","ability_mount_ridinghorse"),("poni","ability_mount_ridinghorse"),("mastin","ability_hunter_pet_wolf"),
    ("mula","ability_mount_ridinghorse"),("camello","ability_mount_camel_brown"),("silla","inv_horse3saddle001_brown"),
    ("alforja","inv_misc_bag_09"),("carro","inv_misc_noodle_cart_base_level"),("carreta","inv_misc_noodle_cart_base_level"),
    ("carruaje","inv_misc_noodle_cart_base_level"),("barcaza","inv_misc_fish_turtle_02"),("barco","inv_misc_map_01"),
    ("galera","inv_misc_map_01"),("bote","inv_misc_fish_turtle_02"),("paquete","inv_misc_bag_20"),
    # equipo de aventuras y objetos sueltos: sin estas entradas caian todos al icono de
    # bolsa y la pestana entera se veia igual. Los iconos estan comprobados en el dump.
    ("libro de conjuros","inv_misc_book_09"),("libram","inv_misc_book_09"),("libro","inv_misc_book_09"),
    ("papel","inv_misc_note_01"),("pergamino","inv_scroll_03"),("tiza","inv_misc_dust_02"),
    ("bomba","inv_misc_bomb_05"),("dinamita","inv_misc_bomb_05"),("cajabuzz","inv_misc_bomb_05"),
    ("lampara","inv_misc_lantern_01"),("vara de luz","inv_misc_candle_01"),("baliza","inv_torch_lit"),
    ("encendedor","inv_torch_lit"),("cuerno","inv_drink_05"),("frasco","inv_drink_05"),
    ("vial","inv_drink_05"),("perfume","inv_drink_05"),("olla","inv_misc_food_15"),
    ("utiles de cocinero","inv_misc_food_15"),("cana de pescar","inv_misc_fish_23"),
    ("trampa","inv_misc_gear_01"),("polipasto","inv_misc_rope_01"),("utiles de escalada","inv_misc_rope_01"),
    ("aljaba","inv_ammo_arrow_01"),("abrojos","inv_misc_gear_01"),("pinchos","inv_misc_gear_01"),
    ("bolas de metal","inv_misc_gem_pearl_01"),("cesta","inv_misc_basket_01"),("cofre","inv_box_01"),
    ("barril","inv_box_01"),("cubo","inv_box_01"),("bolsa","inv_misc_bag_09"),("mochila","inv_misc_bag_20"),
    ("ropas","inv_shirt_white_01"),("manta","inv_misc_cape_01"),("tienda","inv_misc_cape_01"),
    ("barda","inv_helmet_06"),("paracaidas","inv_misc_cape_01"),("anillo","inv_jewelry_ring_03"),
    ("kit de sutura","inv_misc_bandage_08"),("silbato","inv_misc_bell_01"),
    ("mira","inv_misc_spyglass_02"),("bayoneta","inv_weapon_rifle_07"),
    ("herramientas","trade_engineering"),("set de","inv_misc_enggizmos_01"),
    ("ariete","inv_misc_gear_01")]
def poner_iconos(lista):
    """Icono de cada objeto: por palabra del nombre, y si no por su tipo.

    Se llama tambien al final del script: buena parte del equipo de aventuras se anade
    despues de este punto y se quedaba sin icono.
    """
    for it in lista:
        if it.get("icon"):
            continue
        elegido = ICONO_MANUAL.get(sa(it["name"]).lower().strip())
        if elegido:
            it["icon"] = elegido
            continue
        if it["kind"] == "gear":
            k = sa(it["name"]).lower()
            it["icon"] = next((v for kw, v in GEAR_ICON if kw in k), "inv_misc_bag_08")
        elif it["kind"] == "armor":
            it["icon"] = ARMOR_ICON.get(it["category"], "inv_chest_chain_05")
        else:
            k = sa(it["name"]).lower()
            ic = next((v for kw, v in WEAPON_KW if kw in k), None)
            if not ic and it["category"] == "De fuego":
                ic = "inv_weapon_rifle_01"
            it["icon"] = ic or ("inv_weapon_bow_08" if it.get("range") == "Distancia"
                                else "inv_sword_04")


poner_iconos(items)

# ---- descripciones: JERARQUIA de fuentes ----
# 1) Warcraft 5ª (el sistema que usamos) 2) Manual del Jugador para lo que no cubre.
import phb_equipo, libro1
from limpieza import limpiar   # restos de OCR en las descripciones del PDF
_phb = phb_equipo.cargar()
_nk = phb_equipo.nk
_wc = libro1.equipo()          # prevalece sobre el PHB
# el addon y el manual nombran distinto algunos objetos
ALIAS_PHB = {
    "armadura acolchada": "acolchada", "armadura de cuero": "cuero",
    "armadura de pieles": "pieles", "camisa de mallas": "camisa de malla",
    "cota de mallas": "cota de malla", "cota de anillas": "cota guarnecida",
    "cota de bandas": "armadura de bandas", "media placa": "media armadura",
    "escudo": "escudos",
    "estuche de mapas y pergaminos": "estuche para mapa o pergamino",
    "raciones": "raciones", "kit de sanador": "utiles de sanador",
    "fuego del alquimista": "fuego de alquimista",
    "cuerda de canamo": "cuerda", "cuerda de seda": "cuerda",
    "utiles de disfraz": "utiles para disfrazarse",
    "utiles de falsificacion": "utiles para falsificar",
    "kit de herborista": "utiles de herborista",
    "kit de veneno": "utiles de envenenador", "kit de envenenador": "utiles de envenenador",
    "instrumento musical": "instrumentos musicales",
    "naipes": "juegos", "dados": "juegos", "ajedrez de dragones": "juegos",
    "bolsa de componentes": "saquito de componentes",
    "foco druidico": "canalizador druidico", "orbe arcano": "canalizador arcano",
    "varita": "canalizador arcano", "simbolo sagrado": "simbolo sagrado",
    "flechas": "municion", "virotes": "municion", "balas de honda": "municion",
    "dardos de cerbatana": "municion", "balas de arma de fuego": "municion",
    "paquete de burglar": "paquete de ladron 16 po",
    "silla de montar": "sillas", "bote de remos": "barcos de remos",
}

def _base(n):
    """Nombre base para comparar objetos: sin parentesis ni aposicion.
    'Espejo, acero' y 'Espejo de acero' son el mismo objeto que 'Espejo'."""
    n = re.sub(r"\s*\(.*\)\s*$", "", n or "")
    n = re.split(r"\s*,\s*", n)[0]
    return _nk(n)

# ---- equipo del Manual del Jugador que faltaba (precio y peso de su tabla) ----
import gear_phb
_ya = {_nk(i["name"]) for i in items} | {_base(i["name"]) for i in items}
_add_phb = 0
for _n, _c, _pr, _pe in gear_phb.FALTAN:
    if _nk(_n) in _ya or _base(_n) in _ya: continue
    items.append({"id": "obj-" + slug(_n), "name": _n, "kind": "gear", "category": _c,
                  "price": _pr, "weight": a_metrico(_pe), "props": [], "propBase": [],
                  "note": "", "source": "Manual del Jugador"})
    _ya.add(_nk(_n)); _ya.add(_base(_n)); _add_phb += 1
print("Manual del Jugador: %d objetos anadidos" % _add_phb)

# el escudo esta en la lista de armas del addon (mano secundaria) y ademas como
# armadura con su CA: en el compendio solo debe aparecer una vez, como armadura
items = [i for i in items if not (i["kind"] == "weapon" and _nk(i["name"]) == "escudo")]

# ---- objetos y armas propios del Libro 1 (Warcraft 5ª es el sistema) ----
# Se anaden los que el addon no tiene y se aplican sus reprecios sobre los del PHB.
import objetos_libros
_wa, _wo = objetos_libros.armas(), objetos_libros.objetos()
_por_nombre = {_nk(i["name"]): i for i in items}
for _i in items: _por_nombre.setdefault(_base(_i["name"]), _i)
_nuevos = _reprecio = 0
for k, v in _wo.items():
    it = _por_nombre.get(k) or _por_nombre.get(_base(v["name"]))
    if it:                                    # ya existe: el Libro 1 manda en precio y peso
        if v.get("cost") and v["cost"] != it.get("price"): it["price"] = v["cost"]; _reprecio += 1
        if v.get("weight") and v["weight"] not in ("", "—"): it["weight"] = v["weight"]
        it["source"] = "Warcraft 5ª"
        continue
    items.append({"id": "obj-" + slug(v["name"]), "name": v["name"], "kind": "gear",
                  "category": v["category"], "price": v["cost"], "weight": v["weight"],
                  "props": [], "propBase": [], "note": "", "source": "Warcraft 5ª"})
    _nuevos += 1
# La tabla de exoticas del Libro 1 llama a cinco armas por su nombre corto, y el addon a
# las mismas por su gentilicio. Sin esto salian DOS VECES en la pestana, con dos iconos y
# dos danos distintos. Se queda la racial y la del libro solo le presta precio y peso.
MISMO_QUE_RACIAL = {
    "totem de batalla": "Tótem de guerra tauren",
    "espada lunar": "Espada lunar kal'dorei",
    "guja lunar": "Guja lunar kal'dorei",
    "doble hoja": "Doble hoja sin'dorei",
    "garra de guerra": "Garra de guerra orca",
}
for k, v in _wa.items():
    if k in _por_nombre:
        _por_nombre[k]["source"] = "Warcraft 5ª"; continue
    _racial = MISMO_QUE_RACIAL.get(k)
    if _racial:
        _gemela = _por_nombre.get(_nk(_racial))
        if _gemela:
            if v.get("cost") and not _gemela.get("price"): _gemela["price"] = v["cost"]
            if v.get("weight") and not _gemela.get("weight"): _gemela["weight"] = v["weight"]
            continue
    props = [x.strip().capitalize() for x in re.split(r",(?![^(]*\))", v["props"]) if x.strip()]
    items.append({"id": "arma-" + slug(v["name"]), "name": v["name"], "kind": "weapon",
                  "category": v["category"],
                  "range": "Distancia" if "distancia" in v["category"].lower() else "Cuerpo a cuerpo",
                  "damage": v["damage"],
                  "damageType": (v["damage"].split()[-1].capitalize() if v["damage"] else "—"),
                  "price": v["cost"], "weight": v["weight"],
                  "props": props, "propBase": [re.sub(r"\s*\([^)]*\)\s*$", "", x) for x in props],
                  "source": "Warcraft 5ª"})
    _nuevos += 1
# descripcion del Libro 1 para los objetos nuevos
for it in items:
    if it.get("note"): continue
    d = _wc.get(_nk(it["name"])) or _wc.get(_nk(re.sub(r"\s*\(.*\)\s*$", "", it["name"])))
    if d: it["note"] = limpiar(a_metrico(d))
print("Libro 1: %d objetos/armas anadidos, %d reprecios aplicados" % (_nuevos, _reprecio))

# las descripciones se aplican AL FINAL, con todos los objetos ya anadidos
_enr = 0
_sinfuente = []
for it in items:
    base = re.sub(r"\s*\(.*\)\s*$", "", it["name"]).strip()   # "Aceite (frasco)" -> "Aceite"
    k, kb2 = _nk(it["name"]), _nk(base)
    txt = (_wc.get(k) or _wc.get(kb2)                       # 1) Warcraft 5ª
           or _phb.get(k) or _phb.get(kb2)                   # 2) Manual del Jugador
           or _phb.get(ALIAS_PHB.get(k, "")) or _phb.get(ALIAS_PHB.get(kb2, "")))
    if not txt:
        # los paquetes del manual llevan el precio en el titulo ("paquete de artista 40 po")
        # Solo para paquetes, y solo si lo que sobra del titulo es el precio: sin este
        # limite, "Lanza" se quedaba con la nota de "Lanza de caballeria" (el unico
        # titulo del manual que empieza igual).
        if it["kind"] == "gear":
            pref = [v for c, v in _phb.items()
                    if c.startswith(kb2 + " ") and re.fullmatch(r"\d+\s*(?:po|pp|pe|pc)", c[len(kb2)+1:])]
            if len(pref) == 1: txt = pref[0]
    if txt and len(txt) > len(it.get("note") or ""):
        it["note"] = limpiar(a_metrico(txt)); _enr += 1
    elif not it.get("note"):
        _sinfuente.append(it["name"])
print("descripciones aplicadas: %d (Libro 1: %d objetos disponibles) | sin descripcion: %d" % (_enr, len(_wc), len(_sinfuente)))
if _sinfuente: print("  sin fuente:", ", ".join(_sinfuente[:25]))

# los nombres de herramienta siguen la terminologia canonica ("Útiles de ..."), que hasta
# ahora solo se aplicaba a las profesiones y dejaba el equipo con "Kit de ...",
# "Herramientas de ..." y "Utensilios de ..." mezclados
from normalizar_equipo import normalizar as _norm_equipo
items, _fundidos = _norm_equipo(items)
if _fundidos: print("objetos fundidos por ser el mismo con dos nombres:", ", ".join(_fundidos))

# el libro escribe la propiedad de tres formas ("Arrojadiza (60/120)", "(rango 60/120)",
# "(alcance 20/60)"); en el compendio va siempre la corta, que es la mayoritaria
for _it in items:
    if isinstance(_it.get("props"), list):
        _it["props"] = [re.sub(r"\((?:rango|alcance)\s+", "(", p) for p in _it["props"]]
    if isinstance(_it.get("propBase"), str):
        _it["propBase"] = re.sub(r"\((?:rango|alcance)\s+", "(", _it["propBase"])

# la tabla del libro invierte la aposicion ("Espejo, acero"); en el compendio se lee
# como se dice
_APOSICION = {"Espejo, acero": "Espejo de acero", "Botella, vidrio": "Botella de vidrio"}
for _it in items:
    if _it.get("name") in _APOSICION: _it["name"] = _APOSICION[_it["name"]]

# los nombres visibles llevan tilde aunque el addon los guarde sin ella (los empareja
# como cadena con el arma equipada), igual que clases, conjuros, dotes y recetas
from nombres_display import titulo as _titulo
for _it in items:
    if isinstance(_it.get("name"), str): _it["name"] = _titulo(_it["name"])

# las notas de objeto no pasaban por la terminologia y se quedaban con "tu bonificador
# por competencia" donde el resto del compendio dice "Bonus Competencia"
from terminologia import normalizar_habilidades as _term
for _it in items:
    for _k in ("note", "propBase"):
        if isinstance(_it.get(_k), str): _it[_k] = _term(_it[_k])

# el compendio usa coma decimal; el punto de los millares (1.000 po) se conserva
from limpieza import decimales as _decimales
for _it in items:
    for _k in ("weight", "price", "range", "damage", "note", "propBase"):
        if isinstance(_it.get(_k), str): _it[_k] = _decimales(_it[_k])
# ----- precio y peso de armas y armaduras -----
# El addon no los guarda y eran las unicas fichas de equipo sin esos dos datos. Se leen de
# las tablas del Manual del Jugador y solo se ponen donde falten, sin tocar nada mas.
import precios_manual as _pm
_tabla = _pm.leer()
# El manual titula algunas piezas de otra manera, y el OCR le come los espacios a otras.
# Se emparejan a mano y no por parecido: automatico proponia "Armadura de cuero" contra
# "armaduras de placas" (1.500 po) y "Garra de guerra orca" contra "caballo de guerra".
_ALIAS_MANUAL = {
    "clava": "garrote", "gran clava": "garrote grande",
    "gran hacha": "hacha adosmanos", "hacha de batalla": "hachadeguerra",
    "martillo de guerra": "martillodeguerra", "mazo de guerra": "maza a dos manos",
    "armadura acolchada": "acolchada", "armadura de cuero": "cuero",
    "armadura de pieles": "pieles", "camisa de mallas": "camisa de malla",
    "cota de escamas": "cotadeescamas", "media placa": "media armadura",
    "cota de mallas": "cota de malla", "cota de bandas": "armadura de bandas",
    "armadura de placas": "armaduras de placas",
}
_np = _nw = 0
for _it in items:
    if _it["kind"] not in ("weapon", "armor"):
        continue
    _clave = _pm._nk(_it["name"])
    _dato = _tabla.get(_ALIAS_MANUAL.get(_clave, _clave))
    if not _dato:
        _base_nom = re.sub(r"\s*\(.*\)\s*$", "", _it["name"])
        _dato = _tabla.get(_pm._nk(_base_nom))
    if not _dato:
        continue
    if _dato[0] and not _it.get("price"):
        _it["price"] = _dato[0]; _np += 1
    if _dato[1] and not _it.get("weight"):
        _it["weight"] = _dato[1]; _nw += 1
# Las armas propias de Warcraft no estan en el Manual del Jugador, pero si en la tabla de
# armas exoticas del Libro 1. Ahi el compendio les anade el gentilicio ("Espada lunar
# kal'dorei" por "Espada lunar"), asi que basta con que el nombre del libro este contenido.
_wc = _pm.leer_libro1()
for _it in items:
    if _it["kind"] not in ("weapon", "armor") or (_it.get("price") and _it.get("weight")):
        continue
    _clave = _pm._nk(_it["name"])
    _hit = next((v for k, v in _wc.items() if k == _clave or k in _clave), None)
    if not _hit:
        continue
    if _hit[0] and not _it.get("price"):
        _it["price"] = _hit[0]; _np += 1
    if _hit[1] and not _it.get("weight"):
        _it["weight"] = _hit[1]; _nw += 1

print("Del manual y el Libro 1: %d precios y %d pesos de armas y armaduras" % (_np, _nw))

# los objetos que se anaden despues del primer pase tambien necesitan icono
poner_iconos(items)

payload = "window.HARFORD_COMPENDIUM = window.HARFORD_COMPENDIUM || {};\nwindow.HARFORD_COMPENDIUM.equipment = " + \
          json.dumps(items, ensure_ascii=False, indent=1) + ";\n"
io.open(os.path.join(WEB, "js", "compendium-equipment.js"), "w", encoding="utf-8").write(payload)
print("Equipo: %d objetos (%d armas, %d armaduras)" % (
    len(items), sum(1 for i in items if i["kind"] == "weapon"), sum(1 for i in items if i["kind"] == "armor")))
from collections import Counter
print("categorias:", dict(Counter(i["category"] for i in items)))
