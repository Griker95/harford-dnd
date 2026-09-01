-- HarfordCharacterCreation: valida y aplica el borrador del creador, incluido
-- el About de TRP3. El panel solo construye el borrador; este modulo es la
-- frontera que escribe datos persistentes.

HarfordCharacterCreation = HarfordCharacterCreation or {}

local API = HarfordCharacterCreation

-- Formato comun de ficha TRP3 (calcado 1:1 de los perfiles reales del proyecto, p.ej. Hizdahr/TH/Reena):
-- iconos por caracteristica/derivado y paleta de colores exacta. Los frames usan plantilla 2.
local COL_SCORE   = "a7a7a7"  -- puntuacion base en gris
local COL_MOD     = "00ff00"  -- modificador positivo en verde vivo (exacto de los perfiles)
local COL_NEG     = "ff0000"  -- modificador negativo en rojo
local COL_DERIVED = "ff9900"  -- PG/PM/CA/dano en naranja
local COL_PB      = "14b200"  -- bono de competencia en verde (distinto del mod)
local COL_PROP    = "00ffff"  -- propiedades de arma en cian
local COL_TAG     = "cccccc"  -- etiquetas "(Trasfondo)" y separadores en gris claro

local ABILITY_ICONS = {
    FUE = "ability_warrior_strengthofarms",
    DES = "ability_rogue_sprint_blue",
    CON = "ability_warrior_intensifyrage",
    INT = "ability_kaztik_dominatemind",
    SAB = "ability_hunter_onewithnature",
    CAR = "achievement_halloween_smiley_01",
}
local ICON_HP     = "hd_fellowshipplussign_deathknight"
local ICON_MANA   = "inv_elemental_mote_mana"
local ICON_ARMOR  = "garrison_armorupgrade"
local ICON_WEAPON = "garrison_building_armory"
local ICON_FICHA_FRAME = "inv_misc_notepicture2c"  -- icono real del frame "Ficha" en los perfiles
local ICON_MAGIC_FRAME = "garrison_building_magetower"  -- frame de magia
-- Colores de las secciones de magia (de los perfiles): nivel/trucos, coste de mana, escuela.
local COL_SPELL_LEVEL = "00d1ff"
local COL_MANA        = "0000ff"
local COL_SCHOOL      = "3ec6ea"
local COL_RACIAL      = "008c7f"  -- titulo de "Magia Racial" (teal, como en los perfiles)

-- Icono del frame de raza por GENERO { masculino, femenino }, extraido de los perfiles reales del
-- proyecto. Solo las razas confirmadas; el resto usa el generico (no inventar iconos por raza).
-- Iconos de raza por genero { masculino, femenino }, importados de la web canonica de
-- Harford (compendium-data.js, campos `icon`/`iconF`). Cubre las 17 razas; sin esto solo
-- habia 7 y las hembras de huargen/pandaren/vulpera repetian el arte masculino.
local RACE_FRAME_ICONS = {
    raza_humano                    = { "achievement_character_human_male", "achievement_character_human_female" },
    raza_enano            = { "achievement_character_dwarf_male", "achievement_character_dwarf_female" },
    raza_elfo_noche       = { "achievement_character_nightelf_male", "achievement_character_nightelf_female" },
    raza_semielfo         = { "eps_wc3h_highelfrangermale", "eps_wc3h_highelfbaddiegirl" },
    raza_gnomo            = { "gnome_m", "gnome_f" },
    raza_draenei          = { "achievement_character_draenei_male", "achievement_character_draenei_female" },
    raza_huargen          = { "achievement_worganhead", "ability_worgen_darkflight" },
    raza_orco             = { "achievement_character_orc_male", "achievement_character_orc_female" },
    raza_renegado         = { "forsaken_m", "forsaken_f" },
    raza_tauren           = { "tauren_m", "tauren_f" },
    raza_trol             = { "troll_m", "troll_f" },
    raza_elfo_sangre      = { "achievement_character_bloodelf_male", "achievement_character_bloodelf_female" },
    raza_goblin           = { "achievement_goblinhead", "achievement_femalegoblinhead" },
    raza_pandaren         = { "w3reforgedpandarenbrewmaster", "achievement_character_pandaren_female" },
    raza_nocheterna       = { "nightborne_m", "nightborne_f" },
    raza_elfo_vacio       = { "voidelf_m", "voidelf_f" },
    raza_vulpera          = { "vulpera_m", "vulpera_f" },
}

-- Iconos de subraza, tambien de la web. Van anidados por raza porque los ids de subraza se
-- repiten entre razas (renegado tiene "humano" y "elfo").
local SUBRACE_FRAME_ICONS = {
    raza_enano = {
        raza_enano_forjaz           = { "dwarf_m", "dwarf_f" },
        raza_enano_martillo_salvaje = { "eps_wc3h_wildhammermale", "eps_hots_dwarfshaman" },
        raza_enano_hierro_negro     = { "darkiron_m", "darkiron_f" },
    },
    raza_elfo_noche = {
        raza_elfo_noche_altonato         = { "eps_wc3h_nightelfmalewarrior", "eps_wc3h_nightelfcharm" },
    },
    raza_gnomo = {
        raza_gnomo_gnomeregan       = { "achievement_character_gnome_male", "achievement_character_gnome_female" },
        raza_gnomo_mecagnomo        = { "mechagnome_m", "mechagnome_f" },
    },
    raza_draenei = {
        raza_draenei_exodar           = { "draenei_m", "draenei_f" },
        raza_draenei_forjado_luz      = { "lightforged_m", "lightforged_f" },
        raza_draenei_tabido           = { "broken", "eps_wc3_brokendraeneimage" },
        raza_draenei_man_ari          = { "eps_wc3h_eredardiabolist", "achievement_boss_argus_femaleeredar" },
    },
    raza_orco = {
        raza_orco_cazadores        = { "eps_wc3_orcwarlock", "eps_wc3h_orchuntress" },
        raza_orco_misticos         = { "eps_wc3_orcwarlockred", "eps_wc3h_orcwarden" },
        raza_orco_guerreros        = { "eps_wc3h_orcwarlord", "eps_wc3h_orcfemalewarrior" },
    },
    raza_renegado = {
        raza_renegado_humano           = { "achievement_character_undead_male", "achievement_character_undead_female" },
        raza_renegado_elfo             = { "eps_wc3h_forsakenhunter", "eps_wc3h_undeadsanlaynbaddiegirl" },
    },
    raza_tauren = {
        raza_tauren_mulgore          = { "achievement_character_tauren_male", "achievement_character_tauren_female" },
        raza_tauren_monte_alto       = { "highmountain_m", "highmountain_f" },
        raza_tauren_taunka           = { "eps_wc3h_taunkachieftain", "inv_misc_head_tauren_02" },
    },
    raza_trol = {
        raza_trol_jungla           = { "achievement_character_troll_male", "achievement_character_troll_female" },
        raza_trol_zandalari        = { "inv_zandalarimalehead", "inv_zandalarifemalehead" },
        raza_trol_bosque           = { "eps_wc3_foresttrollpriest", "eps_wc3h_trolltrollpriestessfemale" },
        raza_trol_hielo            = { "eps_wc3_icetrollshadowpriest", "eps_wc3h_trollpeasant" },
    },
}
-- Color de spec por subclase (clave normalizada sin tildes).
--
-- Los marcados como PERFIL salen de los perfiles TRP3 reales: son los tonos que ya usan las
-- fichas. Los marcados como TEMA son propuestos a partir de la identidad visual de esa spec en
-- WoW, porque no aparecen en ningun perfil todavia; se eligieron para contrastar con el color de
-- su clase y que el nombre de la subclase no se pierda. Si algun dia existe una ficha con esa
-- spec, sustituye el valor por el del perfil: manda siempre el perfil real.
local SUBCLASS_SPEC_COLORS = {
    -- Guerrero
    armas = "b3743a",            -- PERFIL
    proteccion = "cc9900",       -- PERFIL (lo comparte Paladin)
    furia = "c0392b",            -- TEMA: rojo ira
    -- Paladin
    represion = "d17f69",        -- PERFIL
    -- Picaro
    asesinato = "83bd3e",        -- PERFIL
    forajido = "cc9900",         -- PERFIL
    sutileza = "7f38b5",         -- PERFIL
    -- Cazador
    punteria = "ff7f3f",         -- PERFIL
    supervivencia = "ffb954",    -- PERFIL
    bestias = "9c6b3f",          -- TEMA: marron bestia (las otras dos specs son naranjas)
    -- Druida
    feral = "ff9c00",            -- PERFIL
    restauracion = "4bb3ff",     -- PERFIL
    equilibrio = "8a6fe8",       -- TEMA: morado lunar (Restauracion ya ocupa el azul)
    -- Mago / Brujo
    fuego = "c93c27",            -- PERFIL
    destruccion = "c72811",      -- PERFIL
    arcano = "b06ee8",           -- TEMA: morado arcano (la clase ya es cian)
    afliccion = "6cbf5a",        -- TEMA: verde afliccion
    demonologia = "9b59d0",      -- TEMA: morado demoniaco
    -- Caballero de la Muerte (escarcha lo comparte el Mago)
    sangre = "cd0000",           -- PERFIL
    escarcha = "00d1ff",         -- PERFIL
    profano = "5aa832",          -- TEMA: verde plaga
    -- Cazador de Demonios
    ira = "ff0000",              -- PERFIL
    devastacion = "8fd13f",      -- TEMA: verde vil
    venganza = "3c9a6e",         -- TEMA: verde oscuro demoniaco
    -- Sacerdote (las tres specs y Elune comparten el dorado palido de los perfiles)
    disciplina = "e5cc7f",       -- PERFIL
    sagrado = "e5cc7f",          -- PERFIL
    ["sacerdocio de elune"] = "e5cc7f",  -- PERFIL
    sombra = "8b5cd6",           -- TEMA: morado sombra
    -- Chaman
    elemental = "f2c14e",        -- TEMA: amarillo rayo
    mejora = "e07b39",           -- TEMA: naranja forja
    -- Monje
    ["maestro cervecero"] = "c8873c",    -- TEMA: ambar cerveza
    ["tejedor de niebla"] = "4fd6b0",    -- TEMA: verde niebla
    ["viajero del viento"] = "2ec4b6",   -- TEMA: turquesa viento
}
-- Raza/trasfondo sin icono -> generico (no inventar iconos por raza).
local ICON_GENERIC = "inv_misc_note_01"
local ICON_TRAIT_DEFAULT = "inv_misc_note_01"

-- Icono de origen segun sexo del jugador (2=masculino, 3=femenino). La subraza tiene prioridad
-- cuando trae arte propio: es lo que da nombre a la tarjeta y al frame, asi que el icono debe
-- acompanarla. Si no lo tiene, cae a la raza; si tampoco, al generico. Nunca uno inventado.
local function RaceFrameIcon(raceId, subraceId)
    local race = tostring(raceId or ""):lower()
    local female = UnitSex and UnitSex("player") == 3
    local entry
    local sub = tostring(subraceId or ""):lower()
    if sub ~= "" and SUBRACE_FRAME_ICONS[race] then
        entry = SUBRACE_FRAME_ICONS[race][sub]
    end
    entry = entry or RACE_FRAME_ICONS[race]
    if not entry then return ICON_GENERIC end
    return entry[female and 2 or 1] or entry[1]
end

-- Icono de raza para la UI (rejilla del asistente de creacion). Se expone desde aqui para no
-- duplicar las tablas: son la unica fuente y ya resuelven el sexo del jugador.
function API.GetRaceIcon(raceId, subraceId)
    return RaceFrameIcon(raceId, subraceId)
end

-- Pares { raceId, subraceId or nil, icono } de todo el arte declarado. Solo lo consume el
-- diagnostico que comprueba que el cliente tiene cada textura.
function API.GetAllOriginIcons()
    local out = {}
    for raceId, entry in pairs(RACE_FRAME_ICONS) do
        out[#out + 1] = { raceId, nil, entry[1] }
        if entry[2] ~= entry[1] then out[#out + 1] = { raceId, nil, entry[2] } end
    end
    for raceId, subs in pairs(SUBRACE_FRAME_ICONS) do
        for subId, entry in pairs(subs) do
            out[#out + 1] = { raceId, subId, entry[1] }
            if entry[2] ~= entry[1] then out[#out + 1] = { raceId, subId, entry[2] } end
        end
    end
    table.sort(out, function(a, b) return tostring(a[3]) < tostring(b[3]) end)
    return out
end

-- Icono generico para elementos sin arte propio (p.ej. trasfondos).
function API.GetGenericIcon()
    return ICON_GENERIC
end

-- Color de spec de una subclase; si no hay dato, cae al color de la clase.
-- Nombre de raza/subraza segun el sexo del PJ. La web publica `nameF` para las 17 razas y 22
-- subrazas, y se importo a `HarfordDnDRaces` (tools/codice/importar_femenino.py). Solo lo llevan
-- las que CAMBIAN: Draenei, Tauren, Troll, Goblin, Pandaren y Vulpera son invariables.
-- El lector del propio addon (`Masculinize` en HarfordDnDRaces) ya daba por hecho que el About
-- viene en femenino; hasta ahora el generador nunca lo escribia asi.
local function NombreDeOrigen(def)
    if type(def) ~= "table" then return "" end
    local femenino = UnitSex and UnitSex("player") == 3
    if femenino and def.nameF and def.nameF ~= "" then return tostring(def.nameF) end
    return tostring(def.name or "")
end

-- Publico: el asistente de creacion/subida tambien pinta nombres de raza/subraza y debe
-- respetar el sexo del PJ igual que el About (los iconos ya lo hacian; el texto no).
API.NombreDeOrigen = NombreDeOrigen

local function SubclassColor(subName, classHex)
    local key = HarfordClassColors and HarfordClassColors.StripAccents
        and HarfordClassColors.StripAccents(tostring(subName or "")):lower() or tostring(subName or ""):lower()
    return SUBCLASS_SPEC_COLORS[key] or classHex
end

-- Etiquetas de competencia como en los perfiles reales (tokens internos -> texto mostrado).
local WEAPON_PROF_LABELS = {
    sencillas = "Armas simples", marciales = "Armas marciales",
    ["armas de fuego"] = "Armas de fuego", pistolas = "Pistolas", rifles = "Rifles",
}
local ARMOR_PROF_LABELS = {
    ligera = "Armadura ligera", media = "Armadura intermedia",
    pesada = "Armadura pesada", escudos = "Escudos", escudo = "Escudos",
}
local function LabelFrom(map, token)
    token = tostring(token or "")
    if map[token:lower()] then return map[token:lower()] end
    return token:sub(1, 1):upper() .. token:sub(2)  -- capitaliza lo desconocido, sin inventar
end

local WEAPON_ORDER = { "sencillas", "marciales", "armas de fuego", "pistolas", "rifles" }
local ARMOR_ORDER  = { "ligera", "media", "pesada", "escudos", "escudo" }
-- Devuelve las claves de un set en orden de prioridad y luego alfabetico (salida determinista).
local function OrderedKeys(set, priority)
    local seen, out = {}, {}
    for _, want in ipairs(priority or {}) do
        for key in pairs(set or {}) do
            if not seen[key] and tostring(key):lower() == want then out[#out + 1] = key; seen[key] = true end
        end
    end
    local rest = {}
    for key in pairs(set or {}) do if not seen[key] then rest[#rest + 1] = tostring(key) end end
    table.sort(rest)
    for _, key in ipairs(rest) do out[#out + 1] = key end
    return out
end

local function Trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Resumen para el About: DOS parrafos como maximo. Las descripciones de origen (trasfondo,
-- variante) pueden traer paginas enteras del manual, y el About es la ficha del personaje,
-- no el manual: quien quiera el detalle lo tiene en el creador y en el Libro.
local function Resumen2(value)
    local texto = Trim(value)
    if texto == "" then return "" end
    local parrafos = {}
    for p in (texto .. "\n\n"):gmatch("(.-)\n%s*\n") do
        p = Trim(p)
        if p ~= "" then
            parrafos[#parrafos + 1] = p
            if #parrafos == 2 then break end
        end
    end
    return table.concat(parrafos, "\n\n")
end

-- Ruta de icono (Interface\Icons\X o solo X) -> NOMBRE que usa el markup {icon:NOMBRE}.
local function IconName(path)
    path = tostring(path or ""):gsub("^.*[\\/]", "")
    return path
end

-- Token de clase en INGLES para {icon:classicon_TOKEN}: los classicon_ solo existen en ingles
-- (classicon_mage), no en espanol (classicon_mago daria icono vacio). El parser de cargarficha
-- tambien mapea desde el token ingles.
local function ClassIconToken(className)
    local file = HarfordClassColors and HarfordClassColors.ClassFileFromText
        and HarfordClassColors.ClassFileFromText(className)
    return (file or "WARRIOR"):lower()
end

local function ClassHex(className)
    local file = HarfordClassColors and HarfordClassColors.ClassFileFromText
        and HarfordClassColors.ClassFileFromText(className)
    if file then
        local r, g, b = HarfordClassColors.ColorRGBForClassFile(file)
        local hex = r and HarfordClassColors.RGBToHex(r, g, b)
        if hex then return hex end
    end
    return "ffd100"
end

-- Formato exacto de los perfiles: "<score>{/col} {col:00ff00}+N{/col}" / " {col:ff0000}-N{/col}" / " 0".
local function FormatMod(mod)
    mod = tonumber(mod) or 0
    if mod > 0 then return " {col:" .. COL_MOD .. "}+" .. mod .. "{/col}" end
    if mod < 0 then return " {col:" .. COL_NEG .. "}" .. mod .. "{/col}" end
    return " 0"
end

-- Un nombre valido para el markup {icon:NOMBRE} de TRP3, o nil. TRP3 antepone
-- Interface\ICONS\ al TEXTO tal cual (Utils.getIconTexture), asi que un fileID numerico o un
-- "spell:<id>" salen como textura rota. Y un nombre que ESTE build de Epsilon no tiene (pasa
-- con arte declarado por la web: ver tools/codice/_iconos_faltan_en_epsilon.md) pinta el
-- cuadro verde: en juego se comprueba con GetFileIDFromPath, igual que hacen los frames.
local function IconNameParaMarkup(value)
    if type(value) == "number" then return nil end
    local name = IconName(value)
    if name == "" or name:find("^spell:") or name:match("^%d+$") then return nil end
    if GetFileIDFromPath and not GetFileIDFromPath("Interface\\Icons\\" .. name) then return nil end
    return name
end

-- Titulo visible de un rasgo en el About. Los trasfondos sincronizados de la web titulan
-- "Caracteristica: Descubrimiento", pero los perfiles reales escriben el nombre A SECAS:
-- el prefijo se retira solo aqui (el Libro y el creador conservan el nombre completo).
local function TituloDeRasgo(name)
    local titulo = tostring(name or "Rasgo")
    titulo = titulo:gsub("^%s*Caracteristica%s*:%s*", "")
    titulo = titulo:gsub("^%s*Caracter\195\173stica%s*:%s*", "")
    return titulo ~= "" and titulo or tostring(name or "Rasgo")
end

local function FeatureIconName(feature)
    local path = HarfordDnDData and HarfordDnDData.GetFeatureIcon and HarfordDnDData.GetFeatureIcon(feature)
    return IconNameParaMarkup(path)
        or IconNameParaMarkup(feature and feature.icon)
        or ICON_TRAIT_DEFAULT
end

local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = Copy(child) end
    return out
end

local function GetRaceTraits(draft)
    local out = {}
    local race = HarfordDnDRaces.GetRace(draft.raceId)
    for _, feature in ipairs((race and race.traits) or {}) do out[#out + 1] = { feature = feature, source = "Raza" } end
    local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
    for _, feature in ipairs((subrace and subrace.traits) or {}) do out[#out + 1] = { feature = feature, source = "Subraza" } end
    return out
end

-- Rasgos de trasfondo PARA EL ABOUT: solo el rasgo caracteristico (Herencia, Descubrimiento,
-- Vida mercenaria...) acompaña a la descripcion. Los LISTADOS -- competencias, idiomas,
-- herramientas, equipo y las elecciones -- son cosa del creador y del Libro, no de la ficha
-- publica: en el About solo ensuciaban el frame. Un rasgo caracteristico se reconoce por ser
-- pasivo, sin efectos mecanicos y sin nombre de listado.
local function EsRasgoDeAbout(feature)
    if type(feature) ~= "table" then return false end
    if feature.choice then return false end
    if type(feature.effects) == "table" and #feature.effects > 0 then return false end
    local nombre = tostring(feature.name or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        nombre = HarfordClassColors.StripAccents(nombre)
    end
    nombre = nombre:lower()
    for _, listado in ipairs({ "^competencia", "^equipo", "^equipamiento", "^idioma",
        "^herramienta", "^juego", "^habilidad", "^instrumento" }) do
        if nombre:find(listado) then return false end
    end
    return true
end

local function GetBackgroundTraits(draft)
    local out = {}
    local traits = HarfordDnDBackgrounds.ResolveTraits
        and HarfordDnDBackgrounds.ResolveTraits(draft.backgroundId, draft.backgroundVariantId)
        or ((HarfordDnDBackgrounds.GetBackground(draft.backgroundId) or {}).traits) or {}
    for _, feature in ipairs(traits) do
        if EsRasgoDeAbout(feature) then
            out[#out + 1] = { feature = feature, source = "Trasfondo" }
        end
    end
    return out
end


local function ChoiceText(feature, choices)
    local selected = choices[tostring(feature.id or "")] or {}
    -- Un rasgo con `choice` SIEMPRE dice en que quedo: sin nada elegido, "pendiente". Callarlo
    -- dejaba el volcado de opciones (Defensa, Duelo, Gran Arma...) como si las tuviera todas.
    if #selected == 0 then
        return type(feature.choice) == "table" and " Eleccion: pendiente." or ""
    end
    local labels = {}
    for _, optionId in ipairs(selected) do
        local option = HarfordDnDBook.GetChoiceOption(feature, optionId)
        labels[#labels + 1] = tostring(option and option.label or optionId)
    end
    return #labels > 0 and " Eleccion: " .. table.concat(labels, ", ") .. "." or ""
end

-- Marcadores que los perfiles reales NO muestran como rasgo con icono (competencias/idiomas/equipo/
-- incrementos ya se reflejan en el bloque de la Ficha o son elecciones sin descripcion propia).
local MARKER_PATTERNS = {
    "^incremento de caracteristica", "^idiomas$", "^idioma extra", "^idioma adicional",
    "^versatilidad", "^competencias", "^competencia con herramientas", "^equipo$",
}
local function IsMarkerFeature(feature)
    -- Marcadores de subclase ("Arquetipo marcial", "Estudio Magico", "Camino Sagrado"...): mismo
    -- criterio que el Libro, que ya los oculta. No son rasgos, solo anuncian que eliges subclase.
    local Book = _G.HarfordCharacterBook
    if Book and Book.IsSubclassMarker and Book.IsSubclassMarker(feature) then return true end
    local name = tostring(feature and feature.name or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then name = HarfordClassColors.StripAccents(name) end
    name = name:lower()
    for _, pat in ipairs(MARKER_PATTERNS) do
        if name:find(pat) then return true end
    end
    return false
end

-- Colorea palabras clave dentro de una descripcion siguiendo las convenciones de los perfiles
-- reales: dados/daño y ventaja/desventaja en cian; acciones y terminos mecanicos en gris. El dato
-- del libro se mantiene en texto plano (para tooltips); el color solo se aplica al generar el About,
-- que renderiza {col:} de forma nativa.
local GRAY_TERMS = {
    "Desengancharse", "Esquivar", "Destrabarse", "Ocultarse",
    "descanso corto", "descanso largo",
}
local function ColorizeDescription(text)
    text = tostring(text or "")
    text = text:gsub("(%d*d%d+)", "{col:" .. COL_PROP .. "}%1{/col}")          -- dados: 1d6, 2d8, d4
    text = text:gsub("%f[%a][Dd]esventaja%f[%A]", "{col:" .. COL_PROP .. "}%0{/col}")
    text = text:gsub("%f[%a][Vv]entaja%f[%A]", "{col:" .. COL_PROP .. "}%0{/col}")
    for _, term in ipairs(GRAY_TERMS) do
        text = text:gsub("%f[%a]" .. term .. "%f[%A]", "{col:" .. COL_TAG .. "}%0{/col}")
    end
    return text
end

-- Cuerpo de rasgos con estilo de ficha real: cada rasgo = "{h2}{icon:X:25} Nombre{/h2}" +
-- descripcion. Devuelve "" si no hay rasgos, para que el llamador omita el frame.
local function BuildTraitLines(traits, draft)
    if #traits == 0 then return "" end
    local lines = {}
    for _, entry in ipairs(traits) do
        local feature = entry.feature
        if not IsMarkerFeature(feature) then
            -- Un rasgo con ELECCION no usa la seccion del manual: esa seccion enumera TODAS
            -- las opciones ("Palabra de Poder" con sus ocho palabras, "Estilo de Combate" con
            -- todos los estilos) y el About del personaje solo debe llevar lo SUYO. Su texto
            -- corto + la linea de eleccion bastan; las opciones elegidas con entrada propia
            -- (sac_pp_*, requiresOption) ya salen como rasgos derivados.
            local description
            if feature.choice then
                description = feature.description
            else
                description = HarfordDnDBookText and HarfordDnDBookText.GetFeatureDescription
                    and HarfordDnDBookText.GetFeatureDescription(feature, entry.classId, entry.source, draft.backgroundId, true)
                    or feature.description
            end
            if feature.type == "maniobra" then
                local hexClase = COL_TAG
                local clase = entry.classId and HarfordDnDBook and HarfordDnDBook.GetClass
                    and HarfordDnDBook.GetClass(entry.classId)
                if clase and clase.name then hexClase = ClassHex(clase.name) end
                lines[#lines + 1] = "{h3}{icon:" .. FeatureIconName(feature) .. ":25}{col:" .. hexClase
                    .. "} Maniobra{/col}{col:" .. COL_NEG .. "} "
                    .. tostring(feature.name or "Maniobra") .. "{/col}{/h3}"
            else
                lines[#lines + 1] = "{h2}{icon:" .. FeatureIconName(feature) .. ":25} "
                    .. TituloDeRasgo(feature.name) .. "{/h2}"
            end
            -- Opciones ELEGIDAS con texto propio (Metamagia, Palabras...): cada una sale como
            -- bloque con su icono y su descripcion, como en los perfiles reales. Las que no
            -- tienen texto se resumen en la linea "Eleccion: X" de siempre.
            local bloques, sinTexto = {}, {}
            if feature.choice then
                for _, optionId in ipairs(draft.choices[tostring(feature.id or "")] or {}) do
                    local option = HarfordDnDBook.GetChoiceOption(feature, optionId)
                    local descOpcion = Trim(option and (option.desc or option.description))
                    if option and descOpcion ~= "" then
                        bloques[#bloques + 1] = "{h2}{icon:" .. FeatureIconName(option) .. ":25} "
                            .. tostring(option.label or optionId) .. "{/h2}"
                        bloques[#bloques + 1] = ColorizeDescription(descOpcion)
                    else
                        sinTexto[#sinTexto + 1] = tostring(option and option.label or optionId)
                    end
                end
            end
            local colaEleccion = ""
            if feature.choice and #bloques == 0 then
                colaEleccion = ChoiceText(feature, draft.choices)
            elseif #sinTexto > 0 then
                colaEleccion = " Eleccion: " .. table.concat(sinTexto, ", ") .. "."
            end
            lines[#lines + 1] = ColorizeDescription(Trim(description)) .. colaEleccion
            for _, bloque in ipairs(bloques) do lines[#lines + 1] = bloque end
        end
    end
    return table.concat(lines, "\n")
end

-- Rasgos (clase + subclase) de UNA entrada de clase, para su propio frame coloreado.
-- Devuelve los rasgos de CLASE y los de SUBCLASE POR SEPARADO: van a frames distintos. El orden
-- canonico es [Clase, Especializacion <Sub>, Magia <Clase>, Magia <Sub>] y asi lo tienen los 45
-- perfiles reales; antes se escribian todos mezclados en el frame de la clase.
local function OpcionesElegidasDelDraft(draft)
    local elegidas = {}
    for _, seleccion in pairs((draft and draft.choices) or {}) do
        for _, optId in pairs(seleccion or {}) do elegidas[tostring(optId)] = true end
    end
    return elegidas
end

local function GetClassEntryTraits(entry, elegidas)
    local function Concedido(feature)
        local req = feature and feature.requiresOption
        if not req then return true end
        return elegidas ~= nil and elegidas[tostring(req)] == true
    end
    local base, sub = {}, {}
    local class = HarfordDnDBook.GetClass(entry.classId)
    local subclass
    if class then
        for _, feature in ipairs(class.features or {}) do
            if (tonumber(feature.level) or 99) <= entry.level and Concedido(feature) then
                base[#base + 1] = { feature = feature, source = "Clase", classId = class.id }
            end
        end
        subclass = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
        for _, feature in ipairs((subclass and subclass.features) or {}) do
            if (tonumber(feature.level) or 99) <= entry.level and Concedido(feature) then
                sub[#sub + 1] = { feature = feature, source = "Subclase", classId = class.id }
            end
        end
    end
    return base, class, sub, subclass
end

function API.Validate(draft)
    if type(draft) ~= "table" then return false, "Borrador invalido." end
    -- La ficha Harford NO depende de TRP3 (tiene su propio store). El About es best-effort en Apply.
    if not HarfordDnDRaces.GetRace(draft.raceId) then return false, "Elige una raza valida." end
    if not HarfordDnDBackgrounds.GetBackground(draft.backgroundId) then return false, "Elige un trasfondo valido." end
    local total = 0
    if #(draft.classes or {}) < 1 or #(draft.classes or {}) > 2 then return false, "La ficha necesita una o dos clases." end
    for _, entry in ipairs(draft.classes or {}) do
        local class = HarfordDnDBook.GetClass(entry.classId)
        if not class then return false, "Hay una clase invalida." end
        total = total + math.max(0, math.floor(tonumber(entry.level) or 0))
        local unlock = HarfordDnDBook.GetSubclassUnlockLevel(entry.classId) or 99
        if entry.level >= unlock and #(class.subclasses or {}) > 0 and not HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId) then
            return false, "Falta elegir una subclase."
        end
    end
    -- La creacion confirma SOLO el nivel 1; los niveles 2 y 3 se encadenan despues como
    -- subidas automaticas desde el asistente (HarfordCharacterAdvancement).
    if total ~= 1 then return false, "La ficha inicial debe sumar nivel 1." end
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        -- BuildCreationDraft rellena con base 0 las no asignadas; `tonumber(0)` pasaria el guard.
        -- Una puntuacion base valida siempre es > 0 (los arrays empiezan en 8), asi que exigimos > 0.
        local score = tonumber((draft.abilities or {})[ability.key])
        if not score or score <= 0 then
            return false, "Falta asignar " .. ability.key .. "."
        end
    end
    return true
end

-- Una entrada de conjuro con el formato de los perfiles: titulo + metadatos (escuela/tiempo/alcance/
-- componentes/duracion separados por ||) + descripcion coloreada.
local function FormatSpellEntry(spell)
    -- TRP3 {icon:NOMBRE} necesita el NOMBRE del icono, no un fileID/ruta. GetSpellIcon resuelve a
    -- fileID (cuadro verde en el markup), asi que se toma el NOMBRE crudo del catalogo de conjuros:
    -- el PRIMER candidato que sea un nombre valido en este build ("spell:<id>" y numericos se
    -- saltan). El icon del propio conjuro en el Compendio es casi siempre un fileID y NO sirve
    -- aqui; sin candidato valido se cae al icono por defecto, nunca a un numero.
    local IC = _G.HarfordIconCatalog
    local cands = IC and IC.GetSpellCandidates and spell and IC.GetSpellCandidates(spell.id)
    local icon
    for _, cand in ipairs(type(cands) == "table" and cands or {}) do
        icon = IconNameParaMarkup(cand)
        if icon then break end
    end
    icon = icon or IconNameParaMarkup(spell and spell.icon) or ICON_TRAIT_DEFAULT
    local lines = { "{h3}{icon:" .. icon .. ":25} " .. tostring(spell.name or "Conjuro") .. "{/h3}" }
    local sep = " {col:" .. COL_TAG .. "}||{/col} "
    local meta = "{col:" .. COL_SCHOOL .. "}" .. tostring(spell.school or "") .. "{/col}"
    if spell.castingTime and spell.castingTime ~= "" then meta = meta .. " " .. tostring(spell.castingTime) end
    for _, field in ipairs({ spell.range, spell.components, spell.duration }) do
        if field and tostring(field) ~= "" then meta = meta .. sep .. tostring(field) end
    end
    lines[#lines + 1] = meta
    if spell.description and tostring(spell.description) ~= "" then
        lines[#lines + 1] = ColorizeDescription(Trim(spell.description))
    end
    return table.concat(lines, "\n")
end

-- Frames de magia (uno por clase lanzadora del PJ): cabecera "Ataque Conjuro/DC Conjuro" + conjuros
-- agrupados por nivel (Trucos, Nivel 1...). Lee los conjuros conocidos/preparados/libro del compendio
-- segun el modo de la clase. Vacio al crear (los conjuros se eligen despues en el compendio).
-- Icono del rasgo "Lanzamiento de conjuros" de una clase: es el arte que los perfiles reales
-- usan en su frame "Magia <Clase>". Sin rasgo (o sin arte valido) se cae al generico.
local function IconoLanzamiento(classDef)
    for _, feature in ipairs((classDef and classDef.features) or {}) do
        local nombre = tostring(feature.name or "")
        if HarfordClassColors and HarfordClassColors.StripAccents then
            nombre = HarfordClassColors.StripAccents(nombre)
        end
        if nombre:lower():find("^lanzamiento de conjuros") then
            return IconNameParaMarkup(HarfordDnDData and HarfordDnDData.GetFeatureIcon
                and HarfordDnDData.GetFeatureIcon(feature))
        end
    end
    return nil
end

local function BuildMagicFrames(profileName, idsRaciales)
    local C = _G.HarfordCompendioAPI
    if not (C and C.GetSpellById and C.GetClassCasting) then return {} end
    local Calc = HarfordDnDCalc
    local pb = (Calc and Calc.GetSpellPB and Calc.GetSpellPB()) or (Calc and Calc.GetPB and Calc.GetPB()) or 2
    -- Indexado por POSICION de la clase en la progresion, para poder intercalarlos en su bloque.
    local porEntrada = {}
    local classLevels = (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels
        and HarfordDnDProgression.GetClassLevels(profileName)) or {}

    local opcionesElegidas
    local function OpcionElegida(optionId)
        if not opcionesElegidas then
            opcionesElegidas = {}
            local data = (HarfordDnDProgression and HarfordDnDProgression.Get
                and HarfordDnDProgression.Get(profileName)) or {}
            for _, seleccion in pairs(data.choices or {}) do
                for _, optId in pairs(seleccion or {}) do opcionesElegidas[tostring(optId)] = true end
            end
        end
        return opcionesElegidas[tostring(optionId)] == true
    end

    -- Clave de lanzamiento de cada clase (la de CLASS_CASTING) y cuantas lanzan en total.
    local claveDeEntrada, lanzadoras = {}, 0
    for i, entry in ipairs(classLevels) do
        local class = HarfordDnDBook.GetClass(entry.classId)
        if class then
            local clave = C.GetClassCasting(class.name) and class.name or nil
            if not clave then
                local sub = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
                local compuesta = sub and (class.name .. " " .. sub.name)
                if compuesta and C.GetClassCasting(compuesta) then clave = compuesta end
            end
            if clave then
                claveDeEntrada[i] = clave
                lanzadoras = lanzadoras + 1
            end
        end
    end

    -- Que clase concede cada conjuro (indice de la entrada), respetando nivel y `requiresOption`.
    local concedidoPor = {}
    for i, entry in ipairs(classLevels) do
        local sub = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
        for _, feature in ipairs((sub and sub.features) or {}) do
            if (tonumber(feature.level) or 99) <= (tonumber(entry.level) or 0)
                and (not feature.requiresOption or OpcionElegida(feature.requiresOption)) then
                for _, spellId in ipairs(feature.grantedSpells or {}) do
                    if concedidoPor[spellId] == nil then concedidoPor[spellId] = i end
                end
            end
        end
    end

    local duenoDe = {}

    -- Con UN solo lanzador no se filtra: un conjuro sin etiquetar (fuente propia, custom de
    -- Epsilon) se perderia, y no hay ambiguedad que resolver.
    local function EsDeLaClave(spell, clave)
        if lanzadoras < 2 then return true end
        local limpia = HarfordClassColors and HarfordClassColors.StripAccents
            and HarfordClassColors.StripAccents(tostring(clave)):lower() or tostring(clave):lower()
        local propia = false
        for _, etiqueta in ipairs(spell.classes or {}) do
            local e = HarfordClassColors and HarfordClassColors.StripAccents
                and HarfordClassColors.StripAccents(tostring(etiqueta)):lower() or tostring(etiqueta):lower()
            if e == limpia then return true end
            for j, otra in pairs(claveDeEntrada) do
                local o = HarfordClassColors and HarfordClassColors.StripAccents
                    and HarfordClassColors.StripAccents(tostring(otra)):lower() or tostring(otra):lower()
                if e == o then propia = true end
            end
        end
        -- Si no lo reclama NINGUNA de sus clases lanzadoras, no se tira: va a la primera.
        if propia then return false end
        for j = 1, #classLevels do
            if claveDeEntrada[j] then return claveDeEntrada[j] == clave end
        end
        return true
    end
    for indiceClase, entry in ipairs(classLevels) do
        local frames = porEntrada[indiceClase] or {}
        porEntrada[indiceClase] = frames
        local class = HarfordDnDBook.GetClass(entry.classId)
        if class then
            local casting = C.GetClassCasting(class.name)
            -- Hay clases que NO lanzan de por si y solo lanzan por su subclase (Picaro Sutileza,
            -- Chaman Mejora). Ahi los conjuros son de la SUBCLASE: los perfiles reales tienen
            -- "Magia Sutileza" x3 y ni un solo "Magia Picaro".
            local soloSubclase = false
            if not casting then
                local sub = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
                if sub then
                    casting = C.GetClassCasting(class.name .. " " .. sub.name)
                    soloSubclase = casting ~= nil
                end
            end
            local subclass = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
            if casting then
                -- Union de fuentes: knownSpells lleva SIEMPRE los trucos (y, en known casters, todo);
                -- ademas el pool del modo (libro / preparados). Set por id, sin duplicados.
                local ids = {}
                local function collect(tbl) for id, on in pairs(tbl or {}) do if on then ids[id] = true end end end
                collect(C.GetKnownSpells and C.GetKnownSpells())
                if casting.mode == "wizard_book" then collect(C.GetWizardBook and C.GetWizardBook())
                elseif casting.mode == "prepared" then collect(C.GetPreparedSpells and C.GetPreparedSpells()) end
                local claveLanzamiento = claveDeEntrada[indiceClase]
                -- Dos cubos: los conjuros propios de la clase y los concedidos por la subclase.
                -- El corte NO es trucos/niveles: hay perfiles reales con "Nivel 1" en los dos
                -- frames (Cody, Caballero de la Muerte Sangre).
                local porClase, porSub = {}, {}
                for spellId in pairs(ids) do
                    local spell = C.GetSpellById(spellId)
                    local quienLoConcede = concedidoPor[spellId]
                    -- Racial y sin clase que lo conceda: es del frame de la raza, no de este.
                    if quienLoConcede == nil and idsRaciales and idsRaciales[spellId] then
                        spell = nil
                    end
                    -- Un conjuro concedido va SIEMPRE al frame de quien lo concede, sin pasar por
                    -- el filtro por clase; el resto se reparte por etiqueta.
                    local destino
                    if quienLoConcede ~= nil then
                        if quienLoConcede == indiceClase then destino = porSub end
                    elseif EsDeLaClave(spell, claveLanzamiento) then
                        if duenoDe[spellId] == nil then duenoDe[spellId] = indiceClase end
                        if duenoDe[spellId] == indiceClase then destino = porClase end
                    end
                    if spell and destino then
                        local lvl = tonumber(spell.level) or 0
                        destino[lvl] = destino[lvl] or {}
                        destino[lvl][#destino[lvl] + 1] = spell
                    end
                end
                local abilityMod = (Calc and Calc.GetAbilityMod and Calc.GetAbilityMod(casting.ability)) or 0
                local hex = ClassHex(class.name)

                local function EscribirFrame(byLevel, titulo, colorTitulo, icono, tituloPropio)
                    local levels = {}
                    for lvl in pairs(byLevel) do levels[#levels + 1] = lvl end
                    if #levels == 0 then return end
                    table.sort(levels)
                    local cabecera = tituloPropio
                        and ("{h1:c}{col:" .. colorTitulo .. "}" .. tostring(tituloPropio) .. "{/col}{/h1}")
                        or ("{h1:c}Magia {col:" .. colorTitulo .. "}" .. tostring(titulo) .. "{/col}{/h1}")
                    local out = {
                        cabecera,
                        "{h3:c}Ataque Conjuro{col:" .. COL_DERIVED .. "} +" .. (pb + abilityMod)
                            .. " {/col}{col:" .. COL_TAG .. "}||{/col} DC Conjuro{col:" .. COL_DERIVED .. "} "
                            .. (8 + pb + abilityMod) .. "{/col}{/h3}",
                    }
                    for _, lvl in ipairs(levels) do
                        local spells = byLevel[lvl]
                        table.sort(spells, function(a, b) return tostring(a.name or "") < tostring(b.name or "") end)
                        if lvl == 0 then
                            out[#out + 1] = "{h2}{col:" .. COL_SPELL_LEVEL .. "}Trucos{/col}{/h2}"
                        else
                            out[#out + 1] = "{h2}{col:" .. COL_SPELL_LEVEL .. "}Nivel " .. lvl .. " {/col}{col:"
                                .. COL_MANA .. "}(" .. (lvl + 1) .. " Mana){/col}{/h2}"
                        end
                        for _, spell in ipairs(spells) do out[#out + 1] = FormatSpellEntry(spell) end
                    end
                    frames[#frames + 1] = { IC = icono or ICON_MAGIC_FRAME, TX = table.concat(out, "\n") }
                end

                -- Iconos de los perfiles reales: el frame "Magia <Clase>" lleva el arte del
                -- rasgo Lanzamiento de conjuros de esa clase, y "Magia <Sub>" el del catalogo
                -- subclassSpells (sacado de esos mismos perfiles); nunca el generico si hay
                -- algo mejor. GetSubclassSpellsIconName ya devuelve NOMBRE pelado.
                local iconoClase = IconoLanzamiento(class) or ICON_MAGIC_FRAME
                local iconoSub = IconNameParaMarkup(HarfordIconCatalog
                        and HarfordIconCatalog.GetSubclassSpellsIconName
                        and HarfordIconCatalog.GetSubclassSpellsIconName(class.id, subclass and subclass.id))
                    or iconoClase
                if soloSubclase and subclass then
                    -- Todo lo que lanza lo concede la subclase: un unico frame, con su nombre.
                    for lvl, lista in pairs(porClase) do
                        porSub[lvl] = porSub[lvl] or {}
                        for _, sp in ipairs(lista) do porSub[lvl][#porSub[lvl] + 1] = sp end
                    end
                    EscribirFrame(porSub, subclass.name, SubclassColor(subclass.name, hex), iconoSub)
                elseif casting.mode == "wizard_book" then
                    -- MAGO: el frame se titula "Libro de conjuros", como los perfiles reales
                    -- (Dornalei, Reena), y lleva TODO lo aprendido del libro. Es un frame EXTRA
                    -- de clase para el orden canonico (EXTRAS_DE_CLASE ya lo conoce).
                    EscribirFrame(porClase, class.name, hex, iconoClase, "Libro de conjuros")
                    if subclass then
                        EscribirFrame(porSub, subclass.name, SubclassColor(subclass.name, hex), iconoSub)
                    end
                else
                    EscribirFrame(porClase, class.name, hex, iconoClase)
                    if subclass then
                        EscribirFrame(porSub, subclass.name, SubclassColor(subclass.name, hex), iconoSub)
                    end
                end
            end
        end
    end
    return porEntrada
end

-- Conjuros concedidos por la RAZA (spellGrants/cantripSpellIds de raza+subraza). Devuelve la lista
-- { spell, note } y la caracteristica de lanzamiento racial (normalmente Inteligencia).
local function CollectRacialSpells(draft)
    local C = _G.HarfordCompendioAPI
    if not (C and C.GetSpellById) then return {}, nil end
    local race = HarfordDnDRaces.GetRace(draft.raceId)
    local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
    local features = {}
    for _, f in ipairs((race and race.traits) or {}) do features[#features + 1] = f end
    for _, f in ipairs((subrace and subrace.traits) or {}) do features[#features + 1] = f end
    local out, ability, seen = {}, nil, {}
    local function add(id, note)
        if id and not seen[id] then
            local spell = C.GetSpellById(id)
            if spell then out[#out + 1] = { spell = spell, note = note }; seen[id] = true end
        end
    end
    for _, feature in ipairs(features) do
        for _, grant in ipairs(feature.spellGrants or {}) do
            ability = ability or grant.ability
            for _, id in ipairs(grant.ids or {}) do add(id, grant.note) end
        end
        for _, id in ipairs(feature.cantripSpellIds or {}) do add(id, nil) end
        -- Trucos ELEGIDOS en un rasgo de eleccion racial (Legado elfico del Semielfo): la opcion
        -- lleva su spellId y el rasgo declara la caracteristica en `spellAbility`.
        if feature.choice then
            ability = ability or feature.spellAbility
            for _, optId in ipairs((draft.choices or {})[feature.id] or {}) do
                local opt = HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                    and HarfordDnDBook.GetChoiceOption(feature, optId)
                if opt and opt.spellId then add(opt.spellId, nil) end
            end
        end
    end
    return out, ability
end

-- Frame "Magia Racial <Raza>" (titulo teal) con cabecera Ataque/DC de la caracteristica racial y los
-- conjuros concedidos por la raza. Devuelve nil si la raza no concede conjuros.
-- Frame "Profesiones" del About: una linea por profesion conocida, con icono, tier y skill.
-- Mismo formato visual que el resto de frames (h1 centrado + lineas con {icon}).
-- Profesiones conocidas como lineas de la seccion "Competencia": "- Herreria {col:...}Aprendiz{/col}".
-- Solo el rango, sin el numero de skill: el About es la ficha de cara al RP, no el contador.
local function ProfessionProficiencyLines()
    local P = _G.HarfordProfessions
    if not (P and P.GetProfessions and P.KnowsProfession and P.EffectiveSkill and P.GetTierName) then
        return {}
    end
    local lines = {}
    for _, def in ipairs(P.GetProfessions() or {}) do
        if P.KnowsProfession(def.id) then
            lines[#lines + 1] = "- " .. tostring(def.name)
                .. " {col:" .. COL_TAG .. "}" .. tostring(P.GetTierName(P.EffectiveSkill(def.id))) .. "{/col}"
        end
    end
    return lines
end

local function BuildRacialMagicFrame(draft)
    local spells, ability = CollectRacialSpells(draft)
    if #spells == 0 then return nil end
    local race = HarfordDnDRaces.GetRace(draft.raceId)
    local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
    -- Icono del frame: el del rasgo racial que CONCEDE la magia (Magia vil, Juicio de la
    -- Luz...), no el generico de magia. Primer rasgo con spellGrants/trucos y arte valido.
    local iconoRacial
    for _, lista in ipairs({ (race and race.traits) or {}, (subrace and subrace.traits) or {} }) do
        for _, feature in ipairs(lista) do
            if (feature.spellGrants and #feature.spellGrants > 0)
                or (feature.cantripSpellIds and #feature.cantripSpellIds > 0) then
                iconoRacial = iconoRacial or IconNameParaMarkup(HarfordDnDData
                    and HarfordDnDData.GetFeatureIcon and HarfordDnDData.GetFeatureIcon(feature))
            end
        end
    end
    local raceName = NombreDeOrigen(subrace) ~= "" and NombreDeOrigen(subrace) or NombreDeOrigen(race)
    local Calc = HarfordDnDCalc
    local pb = (Calc and Calc.GetSpellPB and Calc.GetSpellPB()) or (Calc and Calc.GetPB and Calc.GetPB()) or 2
    local mod = (ability and Calc and Calc.GetAbilityMod and Calc.GetAbilityMod(ability)) or 0
    local out = {
        "{h1:c}Magia {col:" .. COL_RACIAL .. "}" .. raceName .. "{/col}{/h1}",
        "{h3:c}Ataque Conjuro{col:" .. COL_DERIVED .. "} +" .. (pb + mod)
            .. " {/col}{col:" .. COL_TAG .. "}||{/col} DC Conjuro{col:" .. COL_DERIVED .. "} "
            .. (8 + pb + mod) .. "{/col}{/h3}",
    }
    for _, entry in ipairs(spells) do
        local text = FormatSpellEntry(entry.spell)
        if entry.note and entry.note ~= "" then
            text = text:gsub("({/h3})", " {col:" .. COL_SPELL_LEVEL .. "}" .. entry.note .. "{/col}%1", 1)
        end
        out[#out + 1] = text
    end
    return { IC = iconoRacial or ICON_MAGIC_FRAME, TX = table.concat(out, "\n") }
end

-- Devuelve una LISTA DE FRAMES (plantilla 2 de TRP3): cada frame = { IC=icono, TX=texto }. Replica
-- el FORMATO COMUN de ficha de los perfiles reales del proyecto (identidad+caracteristicas con
-- iconos y colores, competencia, salvaciones, habilidades; luego frames de raza/trasfondo/clase con
-- titulo centrado y cada rasgo como {h2}{icon} Nombre + descripcion). `profileName` permite leer los
-- valores YA calculados de la ficha recien creada (Calc lee el contexto activo local).
function API.BuildAbout(draft, profileName)
    local race = HarfordDnDRaces.GetRace(draft.raceId)
    local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
    local bg = HarfordDnDBackgrounds.GetBackground(draft.backgroundId)
    local Calc = HarfordDnDCalc
    local resolved = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Resolve
        and HarfordDnDFeatureEffects.Resolve(profileName) or {}
    local frames = {}

    -- ===== Frame 1: FICHA (identidad + caracteristicas + competencia) =====
    local ficha = { "{h1:c}Ficha{/h1}" }
    -- Clase(s): "{icon:classicon_TOKEN}{col:CLASE} Nombre{/col}{col:CLASE} Subclase{/col} (nivel)".
    -- (El color de spec por subclase se escoge a mano en los perfiles; sin dato usamos el de clase.)
    for _, entry in ipairs(draft.classes or {}) do
        local class = HarfordDnDBook.GetClass(entry.classId)
        local subclass = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
        local hex = ClassHex(class.name)
        local line = "{h2}{icon:classicon_" .. ClassIconToken(class.name) .. ":25}{col:" .. hex .. "} "
            .. tostring(class.name) .. "{/col}"
        if subclass then
            line = line .. "{col:" .. SubclassColor(subclass.name, hex) .. "} " .. tostring(subclass.name) .. "{/col}"
        end
        ficha[#ficha + 1] = line .. " (" .. tostring(entry.level) .. "){/h2}"
    end
    ficha[#ficha + 1] = ""  -- linea en blanco antes de las caracteristicas
    -- 6 caracteristicas con icono, puntuacion (gris) y modificador (verde/rojo).
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        local score = (Calc and Calc.GetAbilityScore and Calc.GetAbilityScore(ability.key))
            or math.floor(tonumber(draft.abilities[ability.key]) or 0)
        local mod = (Calc and Calc.GetAbilityMod and Calc.GetAbilityMod(ability.key))
            or (Calc and Calc.AbilityMod and Calc.AbilityMod(score)) or 0
        local icon = ABILITY_ICONS[ability.short] or ICON_TRAIT_DEFAULT
        ficha[#ficha + 1] = "{h3}{icon:" .. icon .. ":25} " .. tostring(ability.key)
            .. " {col:" .. COL_SCORE .. "}" .. score .. "{/col}" .. FormatMod(mod) .. "{/h3}"
    end
    ficha[#ficha + 1] = ""; ficha[#ficha + 1] = ""  -- doble linea en blanco antes de los derivados
    -- Derivados: PG, (PM si aplica) y Armadura (CA).
    local hp = tonumber(HarfordDnDStore and HarfordDnDStore.GetValue and HarfordDnDStore.GetValue("Res_health_Max", 0)) or 0
    local mana = tonumber(HarfordDnDStore and HarfordDnDStore.GetValue and HarfordDnDStore.GetValue("Res_mana_Max", 0)) or 0
    if hp > 0 then
        ficha[#ficha + 1] = "{h3}{icon:" .. ICON_HP .. ":25} PG{col:" .. COL_DERIVED .. "} " .. hp .. "{/col}{/h3}"
    end
    if mana > 0 then
        ficha[#ficha + 1] = "{h3}{icon:" .. ICON_MANA .. ":25} PM{col:" .. COL_DERIVED .. "} " .. mana .. "{/col}{/h3}"
    end
    local ca = HarfordDnDCombat and HarfordDnDCombat.ComputeSelfArmorClass and HarfordDnDCombat.ComputeSelfArmorClass()
    if tonumber(ca) then
        ficha[#ficha + 1] = "{h3}{icon:" .. ICON_ARMOR .. ":25} Armadura {col:" .. COL_SCORE
            .. "}Sin armadura{/col}{col:" .. COL_DERIVED .. "} " .. tonumber(ca) .. "{/col}{/h3}"
    end
    -- Competencia (+PB): armas, armaduras, herramientas, salvaciones y habilidades.
    local pb = (Calc and Calc.GetPB and Calc.GetPB()) or 2
    ficha[#ficha + 1] = ""
    ficha[#ficha + 1] = "{h2}Competencia {col:" .. COL_PB .. "}(+" .. pb .. "){/col}{/h2}"
    for _, w in ipairs(OrderedKeys(resolved.weaponProf, WEAPON_ORDER)) do
        ficha[#ficha + 1] = "- " .. LabelFrom(WEAPON_PROF_LABELS, w)
    end
    for _, a in ipairs(OrderedKeys(resolved.armorProf, ARMOR_ORDER)) do
        ficha[#ficha + 1] = "- " .. LabelFrom(ARMOR_PROF_LABELS, a)
    end
    local toolKeys = OrderedKeys(resolved.toolProf, {})
    if #toolKeys > 0 then
        ficha[#ficha + 1] = ""
        for _, t in ipairs(toolKeys) do ficha[#ficha + 1] = "- " .. tostring(t) end
    end
    local profLines = ProfessionProficiencyLines()
    if #profLines > 0 then
        ficha[#ficha + 1] = ""
        for _, l in ipairs(profLines) do ficha[#ficha + 1] = l end
    end
    -- Salvaciones competentes.
    local saveList = {}
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        local prof = (resolved.saveProf and resolved.saveProf[ability.key])
            or (Calc and Calc.GetSaveProf and Calc.GetSaveProf(ability.key))
        if prof then saveList[#saveList + 1] = tostring(ability.key) end
    end
    if #saveList > 0 then
        ficha[#ficha + 1] = ""
        ficha[#ficha + 1] = "{h3}Tiradas de salvacion{/h3}"
        for _, s in ipairs(saveList) do ficha[#ficha + 1] = "- " .. s end
    end
    -- Habilidades competentes (pericia si rank>=2).
    local skillLines = {}
    for _, skill in ipairs(HarfordDnDData.SKILLS or {}) do
        local rank = resolved.skillRank and resolved.skillRank[skill.id]
        if rank and rank >= 1 then
            local suffix = rank >= 2 and " {col:" .. COL_DERIVED .. "}(Pericia){/col}" or ""
            skillLines[#skillLines + 1] = "- " .. tostring(skill.name) .. suffix
        end
    end
    if #skillLines > 0 then
        ficha[#ficha + 1] = ""
        ficha[#ficha + 1] = "{h3}Habilidades{/h3}"
        for _, l in ipairs(skillLines) do ficha[#ficha + 1] = l end
    end

    -- Idiomas. El importador los lee desde siempre, pero nadie los escribia: el viaje de ida
    -- y vuelta estaba roto por ese lado.
    do
        -- Fuente unica: los derivados de raza/trasfondo/clase/elecciones MAS los importados. Leer
        -- solo lo importado dejaba la seccion vacia en una ficha creada con el asistente.
        local idiomas = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetLanguages
            and HarfordDnDFeatureEffects.GetLanguages(profileName)) or {}
        if #idiomas > 0 then
            ficha[#ficha + 1] = ""
            ficha[#ficha + 1] = "{h3}Idiomas{/h3}"
            for _, l in ipairs(idiomas) do ficha[#ficha + 1] = "- " .. l end
        end
    end

    -- Equipo: el resto de lo que lleva, detras de Idiomas. El arma y la armadura ya salen
    -- arriba en sus propias lineas, asi que aqui va lo demas. Es una SECCION del frame Ficha,
    -- no un frame propio.
    do
        local lista = (HarfordDnDProgression and HarfordDnDProgression.GetEquipmentList
            and HarfordDnDProgression.GetEquipmentList(profileName)) or {}
        -- Lo equipado ya sale arriba en Armadura y Armas: aqui va solo el resto.
        local _, equipo = API.SplitStartingEquipment(lista)
        if #equipo > 0 then
            ficha[#ficha + 1] = ""
            ficha[#ficha + 1] = "{h3}Equipo{/h3}"
            for _, item in ipairs(equipo) do ficha[#ficha + 1] = "- " .. tostring(item) end
        end
    end

    frames[#frames + 1] = { IC = ICON_FICHA_FRAME, TX = table.concat(ficha, "\n") }

    -- Dotes del personaje, al final del frame de RAZA (ver el bloque de abajo).
    local function BuildFeatLines(prof)
        local F = HarfordDnDFeats
        local Pg = HarfordDnDProgression
        if not (F and F.GetFeat and Pg and Pg.GetFeats) then return "" end
        local out = {}
        for _, featId in ipairs(Pg.GetFeats(prof) or {}) do
            local def = F.GetFeat(featId)
            if def then
                -- Icono de la PROPIA dote (todas lo declaran ya); el respaldo del primer trait
                -- daba el signo '+' del Incremento de caracteristica, que no es arte de la dote.
                local icono = FeatureIconName({ id = def.id, icon = def.icon, name = def.name })
                out[#out + 1] = "{h2}{icon:" .. icono .. ":25}{col:" .. COL_RACIAL
                    .. "} Dote{/col} " .. tostring(def.name) .. "{/h2}"
                -- Formato de los perfiles reales: descripcion de la dote debajo de la cabecera,
                -- SIEMPRE (una dote sin cuerpo salia como titulo suelto), y los traits despues.
                local desc = Trim(def.description)
                if desc ~= "" then out[#out + 1] = ColorizeDescription(desc) end
                local cuerpo = F.GetFeatTraits and BuildTraitLines(F.GetFeatTraits({ featId }), draft) or ""
                if cuerpo ~= "" then out[#out + 1] = cuerpo end
            end
        end
        return table.concat(out, string.char(10))
    end

    -- ===== Frame 2: RAZA ===== (titulo centrado + rasgos; sin linea "Raza:", como los perfiles reales)
    do
        local raceName = NombreDeOrigen(subrace or race)
        local lines = { "{h1:c}" .. raceName .. "{/h1}" }
        local body = BuildTraitLines(GetRaceTraits(draft), draft)
        if body ~= "" then lines[#lines + 1] = body end
        -- Las dotes van AQUI, detras de los rasgos raciales: es donde las tienen los perfiles
        -- reales (5 de 5 en los {PJ}) y donde las busca ResolveFeatsFromAbout al recargar.
        local dotes = BuildFeatLines(profileName)
        if dotes ~= "" then lines[#lines + 1] = dotes end
        frames[#frames + 1] = { IC = IconNameParaMarkup(RaceFrameIcon(race.id, subrace and subrace.id)) or ICON_GENERIC, TX = table.concat(lines, "\n") }
    end

    -- ===== Frame 3: TRASFONDO ===== (nombre coloreado teal como en los perfiles)
    -- Sin trasfondo no hay frame: no todos los personajes tienen uno.
    if bg then
        -- Variante elegida (Gladiador, Espia, Comerciante gremial...): entra en el titulo entre
        -- parentesis -- NormalizeAboutHeading los quita, asi que cargarficha sigue reconociendo
        -- el trasfondo -- y su texto va como bloque propio tras la descripcion base. Antes la
        -- variante NO entraba en el About en absoluto.
        local variante
        for _, v in ipairs(bg.variants or {}) do
            if tostring(v.id) == tostring(draft.backgroundVariantId or "") then variante = v break end
        end
        local titulo = tostring(bg.name) .. (variante and (" (" .. tostring(variante.name) .. ")") or "")
        local lines = { "{h1:c}Trasfondo {col:" .. COL_RACIAL .. "}" .. titulo .. "{/col}{/h1}" }
        -- Las descripciones de origen son RESUMEN en el About: dos parrafos como maximo.
        local desc = Resumen2(bg.desc)
        if desc ~= "" then lines[#lines + 1] = desc end
        if variante then
            local iconoVar = FeatureIconName({ id = variante.id, icon = variante.icon, name = variante.name })
            lines[#lines + 1] = "{h2}{icon:" .. iconoVar .. ":25} " .. tostring(variante.name) .. "{/h2}"
            local descVar = Resumen2(variante.desc)
            if descVar ~= "" then lines[#lines + 1] = ColorizeDescription(descVar) end
        end
        local body = BuildTraitLines(GetBackgroundTraits(draft), draft)
        if body ~= "" then lines[#lines + 1] = body end
        local iconoBg = IconNameParaMarkup(HarfordDnDData and HarfordDnDData.GetFeatureIcon
            and HarfordDnDData.GetFeatureIcon({ id = bg.id, icon = bg.icon, name = bg.name }))
        frames[#frames + 1] = { IC = iconoBg or ICON_GENERIC, TX = table.concat(lines, "\n") }
    end

    -- ===== Bloques de CLASE: [Clase, Especializacion <Sub>, Magia <Clase>, Magia <Sub>] =====
    local opcionesDelDraft = OpcionesElegidasDelDraft(draft)
    local idsRaciales = {}
    for _, entrada in ipairs((CollectRacialSpells(draft)) or {}) do
        local sp = entrada and entrada.spell
        if sp and sp.id then idsRaciales[sp.id] = true end
    end
    local magiaPorClase = BuildMagicFrames(profileName, idsRaciales)
    for indiceClase, entry in ipairs(draft.classes or {}) do
        local traits, class, subTraits, subclass = GetClassEntryTraits(entry, opcionesDelDraft)
        local body = BuildTraitLines(traits, draft)
        if class and body ~= "" then
            local hex = ClassHex(class.name)
            local lines = { "{h1:c}{col:" .. hex .. "}" .. tostring(class.name) .. "{/col}{/h1}", body }
            frames[#frames + 1] = { IC = "classicon_" .. ClassIconToken(class.name), TX = table.concat(lines, "\n") }
        end
        -- Frame propio de la especializacion, justo detras del de su clase.
        if class and subclass then
            local subBody = BuildTraitLines(subTraits, draft)
            if subBody ~= "" then
                local hex = ClassHex(class.name)
                -- Formato nuevo: "{Clase} {Subclase}" con el color de clase y el de spec
                -- ("Picaro Asesinato"). El formato viejo "Especializacion <Sub>" se sigue
                -- LEYENDO (TituloRango) para los perfiles anteriores; solo cambia lo escrito.
                local lines = {
                    "{h1:c}{col:" .. hex .. "}" .. tostring(class.name) .. "{/col} {col:"
                        .. SubclassColor(subclass.name, hex) .. "}"
                        .. tostring(subclass.name) .. "{/col}{/h1}",
                    subBody,
                }
                local icono = IconNameParaMarkup(HarfordDnDData and HarfordDnDData.GetSubclassIcon
                    and HarfordDnDData.GetSubclassIcon(class.id, subclass.id))
                frames[#frames + 1] = {
                    IC = icono or ("classicon_" .. ClassIconToken(class.name)),
                    TX = table.concat(lines, "\n"),
                }
            end
        end
        -- Magia de esta clase (primero la de la clase, luego la que concede su subclase).
        for _, frame in ipairs(magiaPorClase[indiceClase] or {}) do frames[#frames + 1] = frame end
    end

    -- ===== Frame de MAGIA RACIAL (si la raza concede conjuros, p.ej. Detectar magia) =====
    local racialFrame = BuildRacialMagicFrame(draft)
    if racialFrame then frames[#frames + 1] = racialFrame end

    return frames
end

-- Regenera el About TRP3 desde el estado ACTUAL de la ficha (progresion + conjuros del compendio),
-- reconstruyendo un draft equivalente. Es la via para que aparezcan las secciones de magia despues
-- de elegir conjuros (la creacion solo escribe el About inicial, sin conjuros).
-- Huellas de los frames que Harford escribio en el About, anidadas en el perfil igual que
-- `_equipment` o `_progression`. Sirven para reconocer en la proxima reescritura cuales son suyos
-- y cuales ha anadido el jugador, y asi no borrarle contenido.
local function HashSlot(name, clave, nuevas)
    HarfordDnDPersistStore = HarfordDnDPersistStore or {}
    if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
    local perfiles = HarfordDnDPersistStore.profiles
    if type(perfiles[name]) ~= "table" then perfiles[name] = {} end
    if nuevas then
        perfiles[name][clave] = (#nuevas > 0) and nuevas or nil
        return nuevas
    end
    local guardadas = perfiles[name][clave]
    return type(guardadas) == "table" and guardadas or {}
end

-- Huellas de los frames REGENERADOS (ficha creada con el asistente).
local function AboutFrameHashes(name, nuevas)
    return HashSlot(name, "_aboutFrames", nuevas)
end

-- Devuelve true si Harford puede reescribir el About sin pisarle nada al jugador: o esta vacio,
-- o al menos uno de los frames que hay lo escribio Harford (su huella casa con las guardadas).
--
-- Una ficha llevada a mano NUNCA casa, asi que la subida se aplica solo en la mecanica del addon
-- y se le pide al jugador que actualice su TRP3. Es preferible a regenerarle el perfil por su
-- cuenta o a dejarle frames duplicados.
-- Anade al About el bloque del nivel recien ganado sin tocar nada mas. Reescribe SIEMPRE el mismo
-- frame propio, acumulando niveles, en vez de dejar uno nuevo por cada subida.
-- Rangos fijos de los frames que no pertenecen a ninguna clase.
local RANGO_FICHA, RANGO_RAZA, RANGO_TRASFONDO = 1, 2, 3
local RANGO_RACIAL = 9000

-- Quita un prefijo de cabecera ("Magia ", "Especializacion ", "Rasgos ") y devuelve el resto.
-- La comparacion es sin acentos y en minusculas, porque los perfiles reales escriben
-- "Especializacion" con tilde y con mayuscula inicial.
local function SinPrefijo(titulo, prefijo)
    local t = tostring(titulo or "")
    local limpioT = HarfordClassColors and HarfordClassColors.StripAccents
        and HarfordClassColors.StripAccents(t):lower() or t:lower()
    local limpioP = HarfordClassColors and HarfordClassColors.StripAccents
        and HarfordClassColors.StripAccents(prefijo):lower() or tostring(prefijo):lower()
    if limpioT:sub(1, #limpioP) ~= limpioP then return nil end
    return (t:sub(#limpioP + 1):gsub("^%s+", ""))
end

-- Rango de una cabecera dentro del orden canonico, o nil si no se reconoce (frames propios del
-- jugador: lore, notas, relatos...). `clases` es la progresion, para saber a que bloque pertenece.
-- Cabeceras de frames EXTRA de una clase: no la nombran, asi que heredan el bloque del frame
-- reconocido inmediatamente anterior (`rangoPrevio`).
local EXTRAS_DE_CLASE = {
    ["libro de conjuros"] = true,
    ["cambio de forma"] = true,
    ["estilo de combate"] = true,
}

local function TituloRango(titulo, clases, raceId, rangoPrevio)
    local t = tostring(titulo or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if t == "" then return nil end
    local B, R = HarfordDnDBook, HarfordDnDRaces

    local function RangoClase(texto, delta)
        if not (B and B.FindClassIdByText) then return nil end
        for i, e in ipairs(clases or {}) do
            if B.FindClassIdByText(texto) == e.classId then return 10 * i + delta end
        end
        return nil
    end
    local function RangoSubclase(texto, delta)
        if not (B and B.FindSubclassIdByText) then return nil end
        for i, e in ipairs(clases or {}) do
            local sub = B.FindSubclassIdByText(e.classId, texto)
            if sub and sub ~= "" and (e.subclassId == "" or sub == e.subclassId) then
                return 10 * i + delta
            end
        end
        return nil
    end
    local function EsRaza(texto)
        if not (R and R.FindRaceIdByText) then return false end
        -- La cabecera puede traer raza y subraza juntas ("Enano Martillo Salvaje"), y el
        -- buscador ya tolera genero ("Renegada Humana", "Gnoma").
        -- Un titulo que resuelve a una raza conocida ES un frame de raza, coincida o no con la
        -- del personaje. Exigir la coincidencia dejaba fuera cabeceras de raza perfectamente
        -- validas cuando la raza deducida del perfil no era la misma (o no se dedujo bien), y
        -- equivocarse aqui es inofensivo: como mucho se ancla tras un frame de raza.
        if (R.FindRaceIdByText(texto) or "") ~= "" then return true end
        return raceId and R.FindSubraceIdByText and (R.FindSubraceIdByText(raceId, texto) or "") ~= ""
    end

    if HarfordClassColors and HarfordClassColors.StripAccents
        and HarfordClassColors.StripAccents(t):lower() == "ficha" then return RANGO_FICHA end

    local resto = SinPrefijo(t, "Magia ")
    if resto then
        return RangoSubclase(resto, 4) or RangoClase(resto, 3) or (EsRaza(resto) and RANGO_RACIAL) or nil
    end
    resto = SinPrefijo(t, "Especializacion ")
    if resto then return RangoSubclase(resto, 2) end
    resto = SinPrefijo(t, "Rasgos ")
    if resto then
        -- Titulacion HEREDADA: es el frame de la clase o el de la raza, con el mismo rango que
        -- si vinieran sin prefijo. No es un bloque posterior. Solo se conserva para leer perfiles
        -- antiguos; lo que Harford escribe usa el nombre a secas.
        return RangoClase(resto, 1) or (EsRaza(resto) and RANGO_RAZA) or nil
    end
    local plano = HarfordClassColors and HarfordClassColors.StripAccents
        and HarfordClassColors.StripAccents(t):lower() or t:lower()
    if EXTRAS_DE_CLASE[plano] then
        -- Dentro del bloque de la clase anterior (base + 5). Fuera de un bloque de clase no se
        -- reconoce: seria adivinar, y un frame sin clasificar simplemente no sirve de ancla.
        local prev = tonumber(rangoPrevio) or 0
        if prev >= 10 and prev < RANGO_RACIAL then
            return math.floor(prev / 10) * 10 + 5
        end
        return nil
    end
    if SinPrefijo(t, "Trasfondo ") then return RANGO_TRASFONDO end

    -- Formato nuevo "Clase Subclase" ("Picaro Asesinato"): si el texto resuelve la clase Y
    -- ADEMAS una subclase suya, es el frame de SUBCLASE. Va antes que RangoClase, que lo
    -- reclamaria como frame de clase. El formato viejo "Especializacion <Sub>" ya se leyo.
    if B and B.FindClassIdByText and B.FindSubclassIdByText then
        for i, e in ipairs(clases or {}) do
            if B.FindClassIdByText(t) == e.classId then
                local sub = B.FindSubclassIdByText(e.classId, t)
                if sub and sub ~= "" and (e.subclassId == "" or sub == e.subclassId) then
                    return 10 * i + 2
                end
            end
        end
    end
    return RangoClase(t, 1) or RangoSubclase(t, 2) or (EsRaza(t) and RANGO_RAZA) or nil
end

-- Trocea el texto de un frame en bloques: cada cabecera {h2}...{/h2} con su cuerpo hasta la
-- siguiente. Lo que va antes de la primera cabecera (el titulo {h1} y su descripcion) es el
-- preambulo y se conserva intacto.
local function BloquesDeFrame(tx)
    tx = tostring(tx or "")
    local preambulo, bloques = tx, {}
    local primera = tx:find("{h2}", 1, true)
    if primera then
        preambulo = tx:sub(1, primera - 1)
        local resto = tx:sub(primera)
        local ini = 1
        while true do
            local sig = resto:find("{h2}", ini + 4, true)
            local trozo = resto:sub(ini, (sig and sig - 1) or #resto)
            local cab = trozo:match("^{h2}(.-){/h2}") or ""
            bloques[#bloques + 1] = { cabecera = cab, texto = trozo }
            if not sig then break end
            ini = sig
        end
    end
    return preambulo, bloques
end

-- Cabecera comparable: sin markup, sin acentos, en minusculas.
local function ClaveBloque(cab)
    local limpio = HarfordTRP3 and HarfordTRP3.StripInlineMarkup
        and HarfordTRP3.StripInlineMarkup(cab) or tostring(cab or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        limpio = HarfordClassColors.StripAccents(limpio)
    end
    return (limpio:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Una cabecera de DOTE: "Dote <Nombre>" (o el formato antiguo "Dote: <Nombre>").
local function EsBloqueDote(clave)
    return clave:match("^dote%s") ~= nil or clave:match("^dote:") ~= nil
end

-- Anade a `destino` los bloques de `origen` que no tenga ya. Devuelve el texto y cuantos anadio.
--
-- Los bloques normales entran ANTES de la primera dote, porque la dote es siempre lo ultimo del
-- frame de raza. Los bloques del jugador NO se reordenan: solo se elige donde encajar los nuevos.
local function FusionarBloques(destino, origen)
    local preambulo, propios = BloquesDeFrame(destino)
    local tengo = {}
    for _, b in ipairs(propios) do tengo[ClaveBloque(b.cabecera)] = true end

    local _, candidatos = BloquesDeFrame(origen)
    local normales, dotes = {}, {}
    for _, b in ipairs(candidatos) do
        local clave = ClaveBloque(b.cabecera)
        if clave ~= "" and not tengo[clave] then
            tengo[clave] = true
            if EsBloqueDote(clave) then dotes[#dotes + 1] = b else normales[#normales + 1] = b end
        end
    end
    local anadidos = #normales + #dotes
    if anadidos == 0 then return tostring(destino), 0 end

    -- Primera dote ya presente: los bloques normales nuevos van justo antes.
    local corte = #propios + 1
    for i, b in ipairs(propios) do
        if EsBloqueDote(ClaveBloque(b.cabecera)) then corte = i break end
    end

    local partes = { (preambulo:gsub("%s+$", "")) }
    local function mete(b) partes[#partes + 1] = (b.texto:gsub("%s+$", "")) end
    for i = 1, corte - 1 do mete(propios[i]) end
    for _, b in ipairs(normales) do mete(b) end
    for i = corte, #propios do mete(propios[i]) end
    for _, b in ipairs(dotes) do mete(b) end
    return table.concat(partes, string.char(10)), anadidos
end

-- Draft a partir de la progresion guardada. Lo usan la regeneracion completa y la
-- actualizacion aditiva, que necesitan exactamente los mismos datos.
local function DraftDesdeProgresion(profileName)
    local P = HarfordDnDProgression
    if not (P and P.Get) then return nil, "Progresion no disponible." end
    local data = P.Get(profileName)
    local race = (P.GetRace and P.GetRace(profileName)) or {}
    local draft = {
        raceId = race.id or "",
        subraceId = race.subraceId or "",
        backgroundId = (P.GetBackground and P.GetBackground(profileName)) or "",
        backgroundVariantId = (P.GetBackgroundVariant and P.GetBackgroundVariant(profileName)) or "",
        classes = {},
        abilities = {},
        choices = (data and data.choices) or {},
    }
    for _, e in ipairs((P.GetClassLevels and P.GetClassLevels(profileName)) or {}) do
        draft.classes[#draft.classes + 1] = { classId = e.classId, subclassId = e.subclassId, level = e.level }
    end
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        draft.abilities[ability.key] = HarfordDnDStore and HarfordDnDStore.GetValue
            and HarfordDnDStore.GetValue(ability.key, 0) or 0
    end
    if #draft.classes == 0 then return nil, "No hay una ficha creada para regenerar." end
    return draft
end

-- Actualiza el About del jugador SIN regenerarlo: ver la nota de arriba.
function API.SyncAboutAdditive(profileName, opts)
    profileName = tostring(profileName or (UnitName and UnitName("player")) or "default")
    if not (HarfordTRP3 and HarfordTRP3.ReplaceAboutFrames and HarfordTRP3.GetPlayerProfile) then
        return false, "TRP3 no disponible."
    end
    local draft, err = DraftDesdeProgresion(profileName)
    if not draft then return false, err end

    local P = HarfordDnDProgression
    local clases = (P and P.GetClassLevels and P.GetClassLevels(profileName)) or {}
    local raza = P and P.GetRace and P.GetRace(profileName)
    local razaId = raza and raza.id
    local salto = string.char(10)
    local function Cabecera(tx)
        local primera = tostring(tx):match("^[^" .. salto .. "]+") or ""
        local limpio = HarfordTRP3.StripInlineMarkup and HarfordTRP3.StripInlineMarkup(primera) or primera
        return (limpio:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    -- Frames canonicos, con su rango.
    local generados = {}
    do
        local previo = 0
        for _, fr in ipairs(API.BuildAbout(draft, profileName) or {}) do
            local r = TituloRango(Cabecera(fr.TX), clases, razaId, previo)
            if r then previo = r end
            generados[#generados + 1] = { frame = fr, rango = r or (previo + 1) }
        end
        table.sort(generados, function(a, b) return a.rango < b.rango end)
    end

    local profile = HarfordTRP3.GetPlayerProfile("player")
    local about = profile and type(profile.player) == "table" and profile.player.about
    local suyos = (type(about) == "table" and type(about.T2) == "table") and about.T2 or {}

    local informe = {}
    local final, g, cambios, insertados = {}, 1, 0, 0
    local previo = 0
    for _, fr in ipairs(suyos) do
        local tx = type(fr) == "table" and fr.TX and tostring(fr.TX)
        if tx and tx ~= "" then
            local rango = TituloRango(Cabecera(tx), clases, razaId, previo)
            if rango then
                previo = rango
                -- Los canonicos que van ANTES de este y no existen, se insertan aqui.
                while generados[g] and generados[g].rango < rango do
                    final[#final + 1] = generados[g].frame
                    insertados = insertados + 1
                    informe[#informe + 1] = "crear      " .. Cabecera(generados[g].frame.TX)
                    g = g + 1
                end
                if generados[g] and generados[g].rango == rango then
                    local gen = generados[g].frame
                    if rango == RANGO_FICHA then
                        -- Dato puro: se sustituye. Anadir no vale para un valor que cambia.
                        if tostring(gen.TX) ~= tx then
                            fr = { IC = fr.IC or gen.IC, TX = gen.TX }
                            cambios = cambios + 1
                            informe[#informe + 1] = "sustituir  Ficha (nivel, caracteristicas, PG)"
                        end
                    else
                        local texto, n = FusionarBloques(tx, gen.TX)
                        if n > 0 then
                            fr = { IC = fr.IC, TX = texto }
                            cambios = cambios + 1
                            informe[#informe + 1] = string.format("anadir     %d bloque(s) a %s",
                                n, Cabecera(tx))
                        end
                    end
                    g = g + 1
                end
            end
            final[#final + 1] = fr
        end
    end
    while generados[g] do
        final[#final + 1] = generados[g].frame
        insertados = insertados + 1
        informe[#informe + 1] = "crear      " .. Cabecera(generados[g].frame.TX)
        g = g + 1
    end

    if cambios == 0 and insertados == 0 then return true, "el About ya estaba al dia", informe end
    -- Simulacion: se informa de lo que se haria y NO se escribe.
    if opts and opts.dryRun then
        return true, string.format("(simulacion) %d frame(s) a actualizar, %d a crear",
            cambios, insertados), informe
    end
    local ok, werr = HarfordTRP3.ReplaceAboutFrames(final)
    if not ok then return false, werr, informe end
    return true, string.format("%d frame(s) actualizados, %d anadidos", cambios, insertados), informe
end

function API.CanRewriteAbout(profileName)
    profileName = tostring(profileName or (UnitName and UnitName("player")) or "default")
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.FrameHash) then return false end
    local profile = HarfordTRP3.GetPlayerProfile("player")
    local about = profile and type(profile.player) == "table" and profile.player.about
    local frames = (type(about) == "table" and type(about.T2) == "table") and about.T2 or {}

    -- Sin contenido no hay nada que destruir.
    local conTexto = 0
    for _, fr in ipairs(frames) do
        if type(fr) == "table" and fr.TX and tostring(fr.TX) ~= "" then conTexto = conTexto + 1 end
    end
    if conTexto == 0 then return true end

    local guardadas = {}
    for _, h in ipairs(AboutFrameHashes(profileName)) do guardadas[h] = true end
    for _, fr in ipairs(frames) do
        if type(fr) == "table" and fr.TX and guardadas[HarfordTRP3.FrameHash(tostring(fr.TX))] then
            return true, "huella guardada"
        end
    end

    -- Sin huellas: la cabecera "Ficha" es marca del generador de Harford. Sin esto, cualquier
    -- personaje creado antes de que existieran las huellas se trataba como llevado a mano.
    local salto = string.char(10)
    for _, fr in ipairs(frames) do
        local tx = type(fr) == "table" and fr.TX and tostring(fr.TX)
        if tx and tx ~= "" then
            local primera = tx:match("^[^" .. salto .. "]+") or ""
            local limpio = HarfordTRP3.StripInlineMarkup and HarfordTRP3.StripInlineMarkup(primera) or primera
            limpio = limpio:gsub("^%s+", ""):gsub("%s+$", "")
            if HarfordClassColors and HarfordClassColors.StripAccents then
                limpio = HarfordClassColors.StripAccents(limpio)
            end
            if limpio:lower() == "ficha" then return true, "cabecera Ficha" end
        end
    end
    return false
end

-- Nombre de conjuro -> definicion, normalizado (sin acentos, minusculas).
local function SpellsByName()
    local C = _G.HarfordCompendioAPI
    if not (C and C.GetAllSpells) then return nil end
    local mapa = {}
    for _, spell in ipairs(C.GetAllSpells() or {}) do
        local n = tostring(spell.name or "")
        if HarfordClassColors and HarfordClassColors.StripAccents then n = HarfordClassColors.StripAccents(n) end
        n = n:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        if n ~= "" then mapa[n] = spell end
    end
    return mapa
end

-- Lee los conjuros del About y los deja en el compendio. Devuelve cuantos importo.
function API.ImportSpellsFromAbout(profileName)
    profileName = tostring(profileName or (UnitName and UnitName("player")) or "default")
    local C = _G.HarfordCompendioAPI
    if not (C and HarfordTRP3 and HarfordTRP3.GetPlayerProfile) then return 0 end
    local mapa = SpellsByName()
    if not mapa then return 0 end
    local db = _G.HarfordCompendioCharacterDB
    if type(db) ~= "table" then return 0 end

    local profile = HarfordTRP3.GetPlayerProfile("player")
    local about = profile and type(profile.player) == "table" and profile.player.about
    local frames = (type(about) == "table" and type(about.T2) == "table") and about.T2 or {}

    -- Carga destructiva, como el resto del comando: el About manda sobre lo que hubiera.
    local conocidos, libro, preparados, total = {}, {}, {}, 0
    local salto = string.char(10)
    -- Modo de la ultima clase lanzadora vista: los frames de subclase heredan el suyo.
    local ultimoModo
    local raza = HarfordDnDProgression and HarfordDnDProgression.GetRace
        and HarfordDnDProgression.GetRace(profileName)
    local razaId = raza and raza.id
    for _, fr in ipairs(frames) do
        local tx = type(fr) == "table" and fr.TX and tostring(fr.TX)
        local titulo = tx and (tx:match("^[^" .. salto .. "]+") or "")
        local limpio = titulo and HarfordTRP3.StripInlineMarkup and HarfordTRP3.StripInlineMarkup(titulo) or ""
        local nombreClase = limpio:match("^%s*Magia%s+(.+)%s*$")
        if nombreClase then
            nombreClase = (nombreClase:gsub("%s+$", ""))
            local casting = C.GetClassCasting and C.GetClassCasting(nombreClase)
            local modo
            if casting then
                modo = casting.mode
                ultimoModo = casting.mode
            else
                local R = HarfordDnDRaces
                local esRaza = R and ((R.FindRaceIdByText and (R.FindRaceIdByText(nombreClase) or "") ~= "")
                    or (razaId and R.FindSubraceIdByText and (R.FindSubraceIdByText(razaId, nombreClase) or "") ~= ""))
                -- Racial -> conocidos. Subclase -> el modo de la clase a la que sigue.
                modo = (not esRaza and ultimoModo) or "known"
            end
            for icono, nombre in tx:gmatch("{h3}{icon:[^}]+}%s*([^{]*)") do
                local n = tostring(nombre or "")
                if HarfordClassColors and HarfordClassColors.StripAccents then
                    n = HarfordClassColors.StripAccents(n)
                end
                n = n:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                local spell = mapa[n]
                if spell then
                    total = total + 1
                    local nivel = tonumber(spell.level) or 0
                    if nivel == 0 then
                        conocidos[spell.id] = true
                    elseif modo == "wizard_book" then
                        libro[spell.id] = true
                    elseif modo == "prepared" then
                        preparados[spell.id] = true
                        conocidos[spell.id] = true
                    else
                        conocidos[spell.id] = true
                    end
                end
                local _ = icono
            end
        end
    end
    if total == 0 then return 0 end
    db.knownSpells, db.wizardBook, db.preparedSpells = conocidos, libro, preparados
    return total
end

-- Objetos que aporta un trasfondo, de su rasgo "Equipo". El manual los escribe como una frase
-- con comas, asi que se trocea por comas y se limpia; una entrada vacia no cuenta.
function API.BackgroundEquipment(backgroundId, variantId)
    local out = {}
    local traits = (HarfordDnDBackgrounds and HarfordDnDBackgrounds.ResolveTraits
        and HarfordDnDBackgrounds.ResolveTraits(backgroundId, variantId)) or {}
    for _, trait in ipairs(traits) do
        if tostring(trait.name or "") == "Equipo" then
            for trozo in tostring(trait.description or ""):gmatch("[^,]+") do
                local item = trozo:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.$", "")
                if item ~= "" then out[#out + 1] = item end
            end
        end
    end
    return out
end

-- Lista completa del equipo inicial: lo elegido de la clase mas lo del trasfondo.
-- `seleccion` es { [indiceDeGrupo] = indiceDeOpcion } por clase, tal y como lo devuelve el
-- asistente. Devuelve la lista y, aparte, el arma y la armadura, que van a sus propias lineas.
-- Definicion de arma basica por nombre, o nil si no es un arma.
local function ArmaPorNombre(nombre)
    local buscado = tostring(nombre or ""):lower()
    for _, w in ipairs((HarfordDnDWeapons and HarfordDnDWeapons.WEAPONS) or {}) do
        if tostring(w.key or ""):lower() == buscado then return w end
    end
    return nil
end

local function EsArmadura(nombre)
    local buscado = tostring(nombre or ""):lower()
    for _, a in ipairs((HarfordDnDItems and HarfordDnDItems.GetBasicArmors and HarfordDnDItems.GetBasicArmors()) or {}) do
        if tostring(a.label or ""):lower() == buscado and a.key ~= "none" then return true end
    end
    return false
end

local function EsEscudo(nombre)
    return tostring(nombre or ""):lower():find("escudo", 1, true) ~= nil
end

local function EsDosManos(arma)
    for _, p in ipairs((arma and arma.props) or {}) do
        if tostring(p) == "Dos manos" then return true end
    end
    return false
end

-- Devuelve lo equipado y el RESTO. El orden manda: la primera armadura se viste y la primera arma
-- va a la mano principal.
function API.SplitStartingEquipment(items)
    local equipado, resto = {}, {}
    local principal
    for _, item in ipairs(items or {}) do
        local nombre = tostring(item or "")
        local arma = ArmaPorNombre(nombre)
        if not equipado.armadura and EsArmadura(nombre) then
            equipado.armadura = nombre
        elseif arma and not principal then
            principal = arma
            equipado.mainhand = nombre
        elseif not equipado.offhand and principal and not EsDosManos(principal)
            and (EsEscudo(nombre) or (arma and not EsDosManos(arma))) then
            equipado.offhand = nombre
        else
            resto[#resto + 1] = nombre
        end
    end
    return equipado, resto
end

-- Armas de una categoria ("Marcial", "Simple", "De fuego"...), para que la seleccion ofrezca
-- armas concretas donde el manual dice solo "un arma marcial".
function API.WeaponsByCategory(cat, mode)
    local out = {}
    for _, w in ipairs((HarfordDnDWeapons and HarfordDnDWeapons.WEAPONS) or {}) do
        -- `mode` filtra Melee/Ranged: el manual pide a veces "arma marcial cuerpo a cuerpo".
        local casaModo = (not mode) or (tostring(w.mode or "") == tostring(mode))
        if tostring(w.cat or "") == tostring(cat or "") and casaModo then out[#out + 1] = w.key end
    end
    table.sort(out)
    return out
end

-- `seleccion[i]` = { opcion = n, armas = { "Espadon", ... } }: la opcion elegida del grupo y las
-- armas concretas para sus huecos de categoria, en orden. Tambien admite un numero suelto, que se
-- interpreta como la opcion sin concretar.
function API.BuildStartingEquipment(classId, seleccion, backgroundId)
    local items = {}
    local clase = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(classId)
    for indice, grupo in ipairs((clase and clase.startingEquipment) or {}) do
        -- Objetos que el manual concede sin eleccion ("ademas de..."): siempre entran.
        for _, item in ipairs(grupo.fixed or {}) do items[#items + 1] = tostring(item) end
        local elec = (seleccion and seleccion[indice]) or nil
        local nOpcion = (type(elec) == "table" and tonumber(elec.opcion)) or tonumber(elec) or 1
        local armas = (type(elec) == "table" and elec.armas) or {}
        local elegida = grupo.options[nOpcion]
        local hueco = 0
        for _, item in ipairs((elegida and elegida.items) or {}) do
            if type(item) == "table" and item.pick then
                hueco = hueco + 1
                -- Sin concretar se guarda la categoria: se pierde precision, no la linea.
                items[#items + 1] = tostring(armas[hueco] or ("Arma " .. tostring(item.pick):lower()))
            else
                items[#items + 1] = tostring(item)
            end
        end
    end
    for _, item in ipairs(API.BackgroundEquipment(backgroundId)) do items[#items + 1] = item end
    return items
end

function API.RewriteAbout(profileName)
    profileName = tostring(profileName or (UnitName and UnitName("player")) or "default")
    local draft, err = DraftDesdeProgresion(profileName)
    if not draft then return false, err end
    local ok, err, huellas, resumen = HarfordTRP3.WritePlayerAbout(
        API.BuildAbout(draft, profileName),
        { previous = AboutFrameHashes(profileName) })
    if not ok then return false, err end
    AboutFrameHashes(profileName, huellas or {})
    -- Solo se avisa si habia contenido ajeno: que el jugador sepa que su texto sigue ahi.
    if resumen and (resumen.conservados or 0) > 0 and HarfordChat and HarfordChat.Print then
        HarfordChat.Print(string.format("About actualizado: %d frame(s) propios conservados.",
            resumen.conservados))
    end
    return true
end

function API.Apply(draft)
    local ok, err = API.Validate(draft)
    if not ok then return false, err end
    local profileName = tostring((UnitName and UnitName("player")) or "default")

    -- Crear desde cero sustituye la identidad mecanica completa del personaje.
    -- Las profesiones son SavedVariablesPerCharacter separadas de la progresion
    -- DnD, por lo que deben reiniciarse aqui de manera explicita.
    if HarfordProfessions and HarfordProfessions.ResetCharacterState then
        HarfordProfessions.ResetCharacterState()
    end

    -- Equipo inicial elegido en el asistente: se guarda la lista y se visten los slots. Lo que se
    -- equipa NO se repite en la seccion "Equipo" del About (ver SplitStartingEquipment).
    if type(draft.equipment) == "table" and #draft.equipment > 0 then
        local P2 = HarfordDnDProgression
        if P2 and P2.SetEquipmentList then P2.SetEquipmentList(draft.equipment, profileName) end
        local eq = API.SplitStartingEquipment(draft.equipment)
        local I = HarfordDnDItems
        if I and I.SetBasicArmor and eq.armadura and I.GetBasicArmors then
            local buscado = tostring(eq.armadura):lower()
            for _, a in ipairs(I.GetBasicArmors() or {}) do
                if tostring(a.label or ""):lower() == buscado then
                    I.SetBasicArmor("Chest", a.key, profileName)
                    break
                end
            end
        end
        if I and I.SetBasicWeapon then
            if eq.mainhand then I.SetBasicWeapon("MainHand", eq.mainhand, profileName) end
            if eq.offhand then I.SetBasicWeapon("SecondaryHand", eq.offhand, profileName) end
        end
    end
    -- La XP tambien vuelve a cero: es del personaje anterior, no del que se esta creando. Las
    -- subidas encadenadas a nivel 2 y 3 la volveran a poner en el umbral que toque.
    if HarfordCharacterXP and HarfordCharacterXP.ResetXP then
        HarfordCharacterXP.ResetXP()
    end

    -- La ficha HARFORD es lo esencial (tiene su propio store; no depende de TRP3). Se crea PRIMERO
    -- y de forma atomica: progresion + caracteristicas. Si esto falla, no se toca nada mas.
    local created, createErr = HarfordDnDProgression.ReplaceCreation(draft, profileName)
    if not created then return false, createErr or "No se pudo crear la progresion de la ficha." end
    -- Las caracteristicas se guardan HORNEADAS (base asignada + incrementos de creacion), igual
    -- que las que llegan del About en `/harford cargarficha`. El draft trae SOLO la base: los
    -- incrementos de raza/subraza/trasfondo/dote y las Mejoras de Caracteristica elegidas van al
    -- bucket `creationBonus` de HarfordDnDFeatureEffects y NO se suman en vivo, asi que hay que
    -- aplicarlos aqui o el personaje perderia su bono racial (el asistente ya lo mostraba sumado).
    -- Se hace DESPUES de ReplaceCreation: raza, trasfondo, dotes y choices ya estan fijados, de
    -- modo que el motor puede resolverlos.
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        local base = math.floor(tonumber(draft.abilities[ability.key]) or 0)
        local creationBonus = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetCreationAbilityBonus
            and HarfordDnDFeatureEffects.GetCreationAbilityBonus(ability.key, profileName)) or 0
        local baked = base + (tonumber(creationBonus) or 0)
        HarfordDnDStore.SetValue(ability.key, baked)
        -- El About se construye con este mismo draft: dejarlo horneado para que el perfil TRP3
        -- muestre exactamente la misma puntuacion que la ficha (antes rendia la base sin bono).
        draft.abilities[ability.key] = baked
    end
    if HarfordDnDStore.ReconcileDerivedResources then
        HarfordDnDStore.ReconcileDerivedResources(profileName, "creation")
    end

    -- El oro se inicia SOLO al terminar la primera creacion valida. No se deduce de
    -- perfiles importados ni se toca el dinero de un personaje sin ficha Harford.
    if HarfordDnDEconomy and HarfordDnDEconomy.InitializeFromCreation then
        local initialized, economyErr = HarfordDnDEconomy.InitializeFromCreation(draft, profileName, function(success, messages)
            if success or not (HarfordChat and HarfordChat.Print) then return end
            local detail = type(messages) == "table" and messages[1] or messages
            HarfordChat.Print("|cffff5555La ficha se creo, pero no se pudo ajustar el oro inicial: "
                .. tostring(detail or "error desconocido") .. "|r")
        end)
        if not initialized and HarfordChat and HarfordChat.Print then
            HarfordChat.Print("|cffff5555La ficha se creo, pero no se pudo enviar el ajuste de oro inicial: "
                .. tostring(economyErr or "error desconocido") .. "|r")
        end
    end

    -- About de TRP3: BEST-EFFORT. Si TRP3 no esta disponible o no hay perfil activo, la ficha Harford
    -- YA quedo creada; solo se avisa de que no se escribio el About. No aborta la creacion.
    local about = API.BuildAbout(draft, profileName)
    -- Se pasan las huellas anteriores tambien aqui: crear ficha de cero sobre un perfil que ya
    -- tenia una sustituye SUS frames, no los anade encima de los viejos. Y se guardan las nuevas,
    -- o la primera subida de nivel no reconoceria nada como propio.
    local wrote, writeErr, huellas = HarfordTRP3.WritePlayerAbout(about,
        { previous = AboutFrameHashes(profileName) })
    if wrote then AboutFrameHashes(profileName, huellas or {}) end
    if not wrote and HarfordChat and HarfordChat.Print then
        HarfordChat.Print("|cffffcc00Ficha creada, pero no se escribio el About de TRP3: "
            .. tostring(writeErr or "TRP3 no disponible") .. "|r")
    end

    -- Rellena raza/clase en las characteristics TRP3 (solo si estan vacias) para el round-trip de
    -- cargarficha y los lectores TRP3 (color de clase). No pisa valores RP que el jugador ya tenga.
    if HarfordTRP3.WritePlayerRaceClass then
        local race = HarfordDnDRaces.GetRace(draft.raceId)
        local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
        local raceName = NombreDeOrigen(subrace) ~= "" and NombreDeOrigen(subrace) or NombreDeOrigen(race)
        local classNames = {}
        for _, entry in ipairs(draft.classes or {}) do
            local cls = HarfordDnDBook.GetClass(entry.classId)
            if cls and cls.name then classNames[#classNames + 1] = cls.name end
        end
        HarfordTRP3.WritePlayerRaceClass(raceName, table.concat(classNames, " / "))
    end

    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then _G.DND5E_ARC_API.Refresh() end
    if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
    return true, about
end

function API.CopyDraft(draft)
    return Copy(draft)
end
