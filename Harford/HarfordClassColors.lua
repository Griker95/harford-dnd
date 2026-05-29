-- HarfordClassColors: fuente unica de verdad para el color de clase WoW.
--
-- Centraliza la tabla de alias (es->classFile), la normalizacion de texto y la
-- resolucion a color RGB/hex, que antes estaba triplicada en HarfordUnitFrames,
-- HarfordNamePlates y HarfordTurns. Solo datos + helpers puros; sin estado de UI.

HarfordClassColors = HarfordClassColors or {}

-- token (sin tildes, minusculas) -> classFile de RAID_CLASS_COLORS.
HarfordClassColors.ALIASES = {
    { "guerrero", "WARRIOR" }, { "warrior", "WARRIOR" },
    { "paladin", "PALADIN" },
    { "cazador de demonios", "DEMONHUNTER" }, { "demon hunter", "DEMONHUNTER" }, { "demonhunter", "DEMONHUNTER" },
    { "cazador", "HUNTER" }, { "hunter", "HUNTER" },
    { "picaro", "ROGUE" }, { "picar", "ROGUE" }, { "rogue", "ROGUE" },
    { "sacerdote", "PRIEST" }, { "priest", "PRIEST" },
    { "caballero de la muerte", "DEATHKNIGHT" }, { "death knight", "DEATHKNIGHT" }, { "deathknight", "DEATHKNIGHT" },
    { "chaman", "SHAMAN" }, { "shaman", "SHAMAN" },
    { "mago", "MAGE" }, { "mage", "MAGE" },
    { "brujo", "WARLOCK" }, { "warlock", "WARLOCK" },
    { "monje", "MONK" }, { "monk", "MONK" },
    { "druida", "DRUID" }, { "druid", "DRUID" },
    { "evocador", "EVOKER" }, { "evoker", "EVOKER" },
}

-- Normaliza a minusculas sin tildes y con separadores como espacio.
function HarfordClassColors.NormalizeKey(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    value = value:gsub("[áàäâÁÀÄÂ]", "a")
    value = value:gsub("[éèëêÉÈËÊ]", "e")
    value = value:gsub("[íìïîÍÌÏÎ]", "i")
    value = value:gsub("[óòöôÓÒÖÔ]", "o")
    value = value:gsub("[úùüûÚÙÜÛ]", "u")
    value = value:gsub("[ñÑ]", "n")
    return value
end

-- Texto libre de clase (es/en) -> classFile o nil.
function HarfordClassColors.ClassFileFromText(text)
    local classText = HarfordClassColors.NormalizeKey(text)
    if classText == "" then return nil end
    for _, entry in ipairs(HarfordClassColors.ALIASES) do
        if classText:find(entry[1], 1, true) then
            return entry[2]
        end
    end
    return nil
end

function HarfordClassColors.RGBToHex(r, g, b)
    if not r or not g or not b then return nil end
    r = math.max(0, math.min(255, math.floor((tonumber(r) or 1) * 255 + 0.5)))
    g = math.max(0, math.min(255, math.floor((tonumber(g) or 1) * 255 + 0.5)))
    b = math.max(0, math.min(255, math.floor((tonumber(b) or 1) * 255 + 0.5)))
    return string.format("%02x%02x%02x", r, g, b)
end

-- classFile -> r,g,b (o nil).
function HarfordClassColors.ColorRGBForClassFile(classFile)
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    return nil
end

-- Color por clase principal del perfil TRP3. Devuelve r,g,b,classFile o nil.
function HarfordClassColors.ProfileColorRGB(profile)
    if not (profile and HarfordTRP3 and HarfordTRP3.GetProfilePrimaryClass) then return nil end
    local classFile = HarfordClassColors.ClassFileFromText(HarfordTRP3.GetProfilePrimaryClass(profile))
    if not classFile then return nil end
    local r, g, b = HarfordClassColors.ColorRGBForClassFile(classFile)
    if r then return r, g, b, classFile end
    return nil
end

function HarfordClassColors.ProfileColorHex(profile)
    local r, g, b = HarfordClassColors.ProfileColorRGB(profile)
    return HarfordClassColors.RGBToHex(r, g, b)
end

-- Color por la clase nativa WoW de la unidad. Devuelve r,g,b,classFile o nil.
function HarfordClassColors.UnitColorRGB(unit)
    if not (unit and UnitClass) then return nil end
    local _, classFile = UnitClass(unit)
    local r, g, b = HarfordClassColors.ColorRGBForClassFile(classFile)
    if r then return r, g, b, classFile end
    return nil
end

function HarfordClassColors.UnitColorHex(unit)
    local r, g, b = HarfordClassColors.UnitColorRGB(unit)
    return HarfordClassColors.RGBToHex(r, g, b)
end
