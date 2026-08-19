-- HarfordClassColors: fuente unica de verdad para el color de clase WoW.
--
-- Centraliza la tabla de alias (es->classFile), la normalizacion de texto y la
-- resolucion a color RGB/hex, que antes estaba triplicada en HarfordUnitFrames,
-- HarfordNamePlates y HarfordTurns. Solo datos + helpers puros; sin estado de UI.

HarfordClassColors = HarfordClassColors or {}

local UTF8_ACCENT_MAP = {
    ["\195\129"] = "A", ["\195\161"] = "a", ["\195\128"] = "A", ["\195\160"] = "a",
    ["\195\132"] = "A", ["\195\164"] = "a", ["\195\130"] = "A", ["\195\162"] = "a",
    ["\195\137"] = "E", ["\195\169"] = "e", ["\195\136"] = "E", ["\195\168"] = "e",
    ["\195\139"] = "E", ["\195\171"] = "e", ["\195\138"] = "E", ["\195\170"] = "e",
    ["\195\141"] = "I", ["\195\173"] = "i", ["\195\140"] = "I", ["\195\172"] = "i",
    ["\195\143"] = "I", ["\195\175"] = "i", ["\195\142"] = "I", ["\195\174"] = "i",
    ["\195\147"] = "O", ["\195\179"] = "o", ["\195\146"] = "O", ["\195\178"] = "o",
    ["\195\150"] = "O", ["\195\182"] = "o", ["\195\148"] = "O", ["\195\180"] = "o",
    ["\195\154"] = "U", ["\195\186"] = "u", ["\195\153"] = "U", ["\195\185"] = "u",
    ["\195\156"] = "U", ["\195\188"] = "u", ["\195\155"] = "U", ["\195\187"] = "u",
    ["\195\145"] = "N", ["\195\177"] = "n",
}

-- Elimina acentos sustituyendo secuencias UTF-8 completas. No cambia mayusculas,
-- espacios, puntuacion ni separadores; cada consumidor conserva esas decisiones.
function HarfordClassColors.StripAccents(value)
    return (tostring(value or ""):gsub("\195.", UTF8_ACCENT_MAP))
end

-- Nombre completo de una unidad (con realm) o nil. Unifica el idiom repetido
-- `(GetUnitName and GetUnitName(unit, true)) or (UnitName and UnitName(unit))`.
-- El caller conserva su propio fallback: `UnitFullName(u) or "..."`.
function HarfordClassColors.UnitFullName(unit)
    return (GetUnitName and GetUnitName(unit, true)) or (UnitName and UnitName(unit)) or nil
end

-- Nombre corto (sin realm) de un NOMBRE ya resuelto. Unifica
-- `Ambiguate(name, "short") or name:match("^[^%-]+")`.
function HarfordClassColors.ShortName(name)
    if not name or name == "" then return name end
    return (Ambiguate and Ambiguate(name, "short")) or name:match("^[^%-]+") or name
end

function HarfordClassColors.UnitNameMatches(name, unit)
    if not (name and name ~= "" and unit and UnitExists and UnitExists(unit)) then return false end
    local full = HarfordClassColors.UnitFullName(unit)
    local short = HarfordClassColors.ShortName(full)
    local needleShort = HarfordClassColors.ShortName(name)
    return full == name or (short and needleShort and short == needleShort)
end

function HarfordClassColors.FindUnitByName(name)
    if not name or name == "" then return nil end
    for _, unit in ipairs({ "player", "target", "focus", "mouseover", "targettarget", "focustarget" }) do
        if HarfordClassColors.UnitNameMatches(name, unit) then return unit end
    end
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if HarfordClassColors.UnitNameMatches(name, unit) then return unit end
        end
    elseif IsInGroup and IsInGroup() then
        for i = 1, 4 do
            local unit = "party" .. i
            if HarfordClassColors.UnitNameMatches(name, unit) then return unit end
        end
    end
    return nil
end

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
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
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
-- Valores EXACTOS del color canonico de cada clase, escritos como n/255 para que
-- `RGBToHex` devuelva justo ese hex. Antes eran floats de dos decimales y el hex salia
-- desviado: Mago daba `69ccf0` (el tono pre-Legion) en vez de `3fc7eb`, y Guerrero o
-- Caballero de la Muerte fallaban por 1 en algun canal. Eso se veia en el About generado.
HarfordClassColors.FALLBACK_RGB = {
    WARRIOR     = { 198/255, 155/255, 109/255 },  -- c69b6d
    PALADIN     = { 244/255, 140/255, 186/255 },  -- f48cba
    HUNTER      = { 170/255, 211/255, 114/255 },  -- aad372
    ROGUE       = { 255/255, 244/255, 104/255 },  -- fff468
    PRIEST      = { 255/255, 255/255, 255/255 },  -- ffffff
    DEATHKNIGHT = { 196/255,  30/255,  58/255 },  -- c41e3a
    SHAMAN      = {   0/255, 112/255, 221/255 },  -- 0070dd
    MAGE        = {  63/255, 199/255, 235/255 },  -- 3fc7eb
    WARLOCK     = { 135/255, 136/255, 238/255 },  -- 8788ee
    MONK        = {   0/255, 255/255, 152/255 },  -- 00ff98
    DRUID       = { 255/255, 124/255,  10/255 },  -- ff7c0a
    DEMONHUNTER = { 163/255,  48/255, 201/255 },  -- a330c9
    EVOKER      = {  51/255, 147/255, 127/255 },  -- 33937f
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
