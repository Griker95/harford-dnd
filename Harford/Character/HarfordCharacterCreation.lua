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
local RACE_FRAME_ICONS = {
    humano      = { "achievement_character_human_male",    "achievement_character_human_female" },
    elfo_noche  = { "achievement_character_nightelf_male", "achievement_character_nightelf_female" },
    elfo_sangre = { "achievement_character_bloodelf_male", "achievement_character_bloodelf_female" },
    semielfo    = { "eps_wc3h_highelfrangermale",          "eps_wc3h_highelfbaddiegirl" },
    huargen     = { "achievement_worganhead",              "achievement_worganhead" },
    pandaren    = { "w3reforgedpandarenbrewmaster",        "w3reforgedpandarenbrewmaster" },
    vulpera     = { "vulpera_m",                           "vulpera_m" },
}
-- Color de spec por subclase (clave normalizada sin tildes), extraido de los perfiles reales.
local SUBCLASS_SPEC_COLORS = {
    armas = "b3743a", proteccion = "cc9900",
    asesinato = "83bd3e", forajido = "cc9900",
    punteria = "ff7f3f", supervivencia = "ffb954",
    feral = "ff9c00", restauracion = "4bb3ff",
    destruccion = "c72811", fuego = "c93c27",
}
-- Raza/trasfondo sin icono -> generico (no inventar iconos por raza).
local ICON_GENERIC = "inv_misc_note_01"
local ICON_TRAIT_DEFAULT = "inv_misc_note_01"

-- Icono del frame de raza segun sexo del jugador (2=masculino, 3=femenino); generico si no hay dato.
local function RaceFrameIcon(raceId)
    local entry = RACE_FRAME_ICONS[tostring(raceId or ""):lower()]
    if not entry then return ICON_GENERIC end
    local female = UnitSex and UnitSex("player") == 3
    return entry[female and 2 or 1] or entry[1]
end

-- Color de spec de una subclase; si no hay dato, cae al color de la clase.
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

local function FeatureIconName(feature)
    local path = HarfordDnDData and HarfordDnDData.GetFeatureIcon and HarfordDnDData.GetFeatureIcon(feature)
    local name = IconName(path)
    if name == "" then name = IconName(feature and feature.icon) end
    if name == "" then name = ICON_TRAIT_DEFAULT end
    return name
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

local function GetBackgroundTraits(draft)
    local bg = HarfordDnDBackgrounds.GetBackground(draft.backgroundId)
    local out = {}
    for _, feature in ipairs((bg and bg.traits) or {}) do out[#out + 1] = { feature = feature, source = "Trasfondo" } end
    return out
end

local function GetClassTraits(draft)
    local out = {}
    for _, entry in ipairs(draft.classes or {}) do
        local class = HarfordDnDBook.GetClass(entry.classId)
        if class then
            for _, feature in ipairs(class.features or {}) do
                if (tonumber(feature.level) or 99) <= entry.level then
                    out[#out + 1] = { feature = feature, source = "Clase", classId = class.id }
                end
            end
            local subclass = HarfordDnDBook.GetSubclass(class.id, entry.subclassId)
            for _, feature in ipairs((subclass and subclass.features) or {}) do
                if (tonumber(feature.level) or 99) <= entry.level then
                    out[#out + 1] = { feature = feature, source = "Subclase", classId = class.id }
                end
            end
        end
    end
    return out
end

local function ChoiceText(feature, choices)
    local selected = choices[tostring(feature.id or "")] or {}
    if #selected == 0 then return "" end
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
            local description = HarfordDnDBookText and HarfordDnDBookText.GetFeatureDescription
                and HarfordDnDBookText.GetFeatureDescription(feature, entry.classId, entry.source, draft.backgroundId, true)
                or feature.description
            lines[#lines + 1] = "{h2}{icon:" .. FeatureIconName(feature) .. ":25} "
                .. tostring(feature.name or "Rasgo") .. "{/h2}"
            lines[#lines + 1] = ColorizeDescription(Trim(description)) .. ChoiceText(feature, draft.choices)
        end
    end
    return table.concat(lines, "\n")
end

-- Rasgos (clase + subclase) de UNA entrada de clase, para su propio frame coloreado.
local function GetClassEntryTraits(entry)
    local out = {}
    local class = HarfordDnDBook.GetClass(entry.classId)
    if class then
        for _, feature in ipairs(class.features or {}) do
            if (tonumber(feature.level) or 99) <= entry.level then
                out[#out + 1] = { feature = feature, source = "Clase", classId = class.id }
            end
        end
        local subclass = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
        for _, feature in ipairs((subclass and subclass.features) or {}) do
            if (tonumber(feature.level) or 99) <= entry.level then
                out[#out + 1] = { feature = feature, source = "Subclase", classId = class.id }
            end
        end
    end
    return out, class
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
    if total ~= 4 then return false, "La ficha inicial debe sumar nivel 4." end
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
    -- fileID (cuadro verde en el markup), asi que se toma el NOMBRE crudo del catalogo de conjuros.
    local IC = _G.HarfordIconCatalog
    local cands = IC and IC.GetSpellCandidates and spell and IC.GetSpellCandidates(spell.id)
    local iconName = (type(cands) == "table" and cands[1]) or (spell and spell.icon)
    local icon = IconName(iconName)
    if icon == "" then icon = ICON_TRAIT_DEFAULT end
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
local function BuildMagicFrames(profileName)
    local C = _G.HarfordCompendioAPI
    if not (C and C.GetSpellById and C.GetClassCasting) then return {} end
    local Calc = HarfordDnDCalc
    local pb = (Calc and Calc.GetSpellPB and Calc.GetSpellPB()) or (Calc and Calc.GetPB and Calc.GetPB()) or 2
    local frames = {}
    local classLevels = (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels
        and HarfordDnDProgression.GetClassLevels(profileName)) or {}
    for _, entry in ipairs(classLevels) do
        local class = HarfordDnDBook.GetClass(entry.classId)
        if class then
            local casting = C.GetClassCasting(class.name)
            if not casting then
                local subclass = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
                if subclass then casting = C.GetClassCasting(class.name .. " " .. subclass.name) end
            end
            if casting then
                -- Union de fuentes: knownSpells lleva SIEMPRE los trucos (y, en known casters, todo);
                -- ademas el pool del modo (libro / preparados). Set por id, sin duplicados.
                local ids = {}
                local function collect(tbl) for id, on in pairs(tbl or {}) do if on then ids[id] = true end end end
                collect(C.GetKnownSpells and C.GetKnownSpells())
                if casting.mode == "wizard_book" then collect(C.GetWizardBook and C.GetWizardBook())
                elseif casting.mode == "prepared" then collect(C.GetPreparedSpells and C.GetPreparedSpells()) end
                local byLevel = {}
                for spellId in pairs(ids) do
                    local spell = C.GetSpellById(spellId)
                    if spell then
                        local lvl = tonumber(spell.level) or 0
                        byLevel[lvl] = byLevel[lvl] or {}
                        byLevel[lvl][#byLevel[lvl] + 1] = spell
                    end
                end
                local levels = {}
                for lvl in pairs(byLevel) do levels[#levels + 1] = lvl end
                if #levels > 0 then
                    table.sort(levels)
                    local abilityMod = (Calc and Calc.GetAbilityMod and Calc.GetAbilityMod(casting.ability)) or 0
                    local hex = ClassHex(class.name)
                    local out = {
                        "{h1:c}Magia {col:" .. hex .. "}" .. tostring(class.name) .. "{/col}{/h1}",
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
                    frames[#frames + 1] = { IC = ICON_MAGIC_FRAME, TX = table.concat(out, "\n") }
                end
            end
        end
    end
    return frames
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
    end
    return out, ability
end

-- Frame "Magia Racial <Raza>" (titulo teal) con cabecera Ataque/DC de la caracteristica racial y los
-- conjuros concedidos por la raza. Devuelve nil si la raza no concede conjuros.
local function BuildRacialMagicFrame(draft)
    local spells, ability = CollectRacialSpells(draft)
    if #spells == 0 then return nil end
    local race = HarfordDnDRaces.GetRace(draft.raceId)
    local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
    local raceName = tostring((subrace and subrace.name) or (race and race.name) or "")
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
    return { IC = ICON_MAGIC_FRAME, TX = table.concat(out, "\n") }
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
    frames[#frames + 1] = { IC = ICON_FICHA_FRAME, TX = table.concat(ficha, "\n") }

    -- ===== Frame 2: RAZA ===== (titulo centrado + rasgos; sin linea "Raza:", como los perfiles reales)
    do
        local raceName = tostring(subrace and subrace.name or race.name)
        local lines = { "{h1:c}" .. raceName .. "{/h1}" }
        local body = BuildTraitLines(GetRaceTraits(draft), draft)
        if body ~= "" then lines[#lines + 1] = body end
        frames[#frames + 1] = { IC = RaceFrameIcon(race.id), TX = table.concat(lines, "\n") }
    end

    -- ===== Frame 3: TRASFONDO ===== (nombre coloreado teal como en los perfiles)
    do
        local lines = { "{h1:c}Trasfondo {col:" .. COL_RACIAL .. "}" .. tostring(bg.name) .. "{/col}{/h1}" }
        local desc = Trim(bg.desc)
        if desc ~= "" then lines[#lines + 1] = desc end
        local body = BuildTraitLines(GetBackgroundTraits(draft), draft)
        if body ~= "" then lines[#lines + 1] = body end
        frames[#frames + 1] = { IC = ICON_GENERIC, TX = table.concat(lines, "\n") }
    end

    -- ===== Frames de CLASE (uno por clase, con titulo coloreado) =====
    for _, entry in ipairs(draft.classes or {}) do
        local traits, class = GetClassEntryTraits(entry)
        local body = BuildTraitLines(traits, draft)
        if class and body ~= "" then
            local hex = ClassHex(class.name)
            local lines = { "{h1:c}{col:" .. hex .. "}" .. tostring(class.name) .. "{/col}{/h1}", body }
            frames[#frames + 1] = { IC = "classicon_" .. ClassIconToken(class.name), TX = table.concat(lines, "\n") }
        end
    end

    -- ===== Frames de MAGIA (uno por clase lanzadora, si el PJ tiene conjuros) =====
    for _, frame in ipairs(BuildMagicFrames(profileName)) do frames[#frames + 1] = frame end

    -- ===== Frame de MAGIA RACIAL (si la raza concede conjuros, p.ej. Detectar magia) =====
    local racialFrame = BuildRacialMagicFrame(draft)
    if racialFrame then frames[#frames + 1] = racialFrame end

    return frames
end

-- Regenera el About TRP3 desde el estado ACTUAL de la ficha (progresion + conjuros del compendio),
-- reconstruyendo un draft equivalente. Es la via para que aparezcan las secciones de magia despues
-- de elegir conjuros (la creacion solo escribe el About inicial, sin conjuros).
function API.RewriteAbout(profileName)
    profileName = tostring(profileName or (UnitName and UnitName("player")) or "default")
    local P = HarfordDnDProgression
    if not (P and P.Get) then return false, "Progresion no disponible." end
    local data = P.Get(profileName)
    local race = (P.GetRace and P.GetRace(profileName)) or {}
    local draft = {
        raceId = race.id or "",
        subraceId = race.subraceId or "",
        backgroundId = (P.GetBackground and P.GetBackground(profileName)) or "",
        classes = {},
        abilities = {},
        choices = (data and data.choices) or {},
    }
    for _, e in ipairs((P.GetClassLevels and P.GetClassLevels(profileName)) or {}) do
        draft.classes[#draft.classes + 1] = { classId = e.classId, subclassId = e.subclassId, level = e.level }
    end
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        draft.abilities[ability.key] = HarfordDnDStore and HarfordDnDStore.GetValue and HarfordDnDStore.GetValue(ability.key, 0) or 0
    end
    if #draft.classes == 0 then return false, "No hay una ficha creada para regenerar." end
    return HarfordTRP3.WritePlayerAbout(API.BuildAbout(draft, profileName))
end

function API.Apply(draft)
    local ok, err = API.Validate(draft)
    if not ok then return false, err end
    local profileName = tostring((UnitName and UnitName("player")) or "default")

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

    -- About de TRP3: BEST-EFFORT. Si TRP3 no esta disponible o no hay perfil activo, la ficha Harford
    -- YA quedo creada; solo se avisa de que no se escribio el About. No aborta la creacion.
    local about = API.BuildAbout(draft, profileName)
    local wrote, writeErr = HarfordTRP3.WritePlayerAbout(about)
    if not wrote and HarfordChat and HarfordChat.Print then
        HarfordChat.Print("|cffffcc00Ficha creada, pero no se escribio el About de TRP3: "
            .. tostring(writeErr or "TRP3 no disponible") .. "|r")
    end

    -- Rellena raza/clase en las characteristics TRP3 (solo si estan vacias) para el round-trip de
    -- cargarficha y los lectores TRP3 (color de clase). No pisa valores RP que el jugador ya tenga.
    if HarfordTRP3.WritePlayerRaceClass then
        local race = HarfordDnDRaces.GetRace(draft.raceId)
        local subrace = HarfordDnDRaces.GetSubrace(draft.raceId, draft.subraceId)
        local raceName = tostring((subrace and subrace.name) or (race and race.name) or "")
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
