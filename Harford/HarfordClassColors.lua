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

-- Paleta de respaldo (RGB 0-1) por si RAID_CLASS_COLORS no tiene la clave en el cliente.
HarfordClassColors.FALLBACK_RGB = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    MAGE        = { 0.41, 0.80, 0.94 },
    WARLOCK     = { 0.58, 0.51, 0.79 },
    MONK        = { 0.00, 1.00, 0.59 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

-- classFile -> r,g,b (o nil). Usa RAID_CLASS_COLORS y cae al respaldo si falta.
function HarfordClassColors.ColorRGBForClassFile(classFile)
    if not classFile then return nil end
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then return color.r, color.g, color.b end
    local fb = HarfordClassColors.FALLBACK_RGB[classFile]
    if fb then return fb[1], fb[2], fb[3] end
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
