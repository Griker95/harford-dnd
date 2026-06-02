HarfordTRP3 = HarfordTRP3 or {}

local API = HarfordTRP3

local function TrimRealm(realm)
    realm = tostring(realm or "")
    realm = realm:gsub("%s+", "")
    return realm
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, value = pcall(fn, ...)
    if ok then
        return value
    end

    return nil
end

local function NormalizeIconPath(icon)
    icon = tostring(icon or "")
    if icon == "" then return nil end
    if tonumber(icon) then return icon end
    if icon:find("\\", 1, true) or icon:find("/", 1, true) then return icon end
    return "Interface\\Icons\\" .. icon
end

local function ReadIconField(tbl, fieldName)
    if type(tbl) ~= "table" then return nil end
    local value = tbl[fieldName]
    if type(value) == "string" and value ~= "" then
        return value
    end
    if type(value) == "number" then
        return tostring(value)
    end
    return nil
end

local function NormalizeHexColor(value)
    value = tostring(value or "")
    value = value:gsub("|cff", "")
    value = value:gsub("#", "")
    value = value:match("^(%x%x%x%x%x%x)")
    return value and value:lower() or nil
end

local function NormalizeDisplaySpacing(text)
    text = tostring(text or "")
    text = text:gsub("\r", "")
    text = text:gsub("[ \t]+\n", "\n")
    text = text:gsub("\n\n\n+", "\n\n")
    text = text:gsub("^\n+", ""):gsub("\n+$", "")
    return text
end

local function StripInlineMarkup(text)
    text = tostring(text or "")
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("{icon:[^}]+}", "")
    text = text:gsub("{/?col[^}]*}", "")
    text = text:gsub("{/?h%d[^}]*}", "")
    text = text:gsub("{/?p[^}]*}", "")
    text = text:gsub("{/?link[^}]*}", "")
    text = text:gsub("{/?.-}", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function NormalizeBuildText(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    value = value:gsub("[áàäâÁÀÄÂ]", "a")
    value = value:gsub("[éèëêÉÈËÊ]", "e")
    value = value:gsub("[íìïîÍÌÏÎ]", "i")
    value = value:gsub("[óòöôÓÒÖÔ]", "o")
    value = value:gsub("[úùüûÚÙÜÛ]", "u")
    value = value:gsub("[ñÑ]", "n")
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function CleanAboutLines(text)
    local lines = {}
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        local clean = StripInlineMarkup(line)
        if clean and clean ~= "" then
            lines[#lines + 1] = clean
        end
    end
    return lines
end

local function TrimText(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Extrae el valor de una linea "Etiqueta: Valor". El matching de la etiqueta se hace
-- sobre texto normalizado (minusculas/sin acentos) pero el valor se devuelve con su
-- CASING ORIGINAL: los trasfondos/razas personalizados conservan sus mayusculas.
local function ExtractLabeledAboutValue(lines, labels)
    if type(lines) ~= "table" then return nil end
    for i, line in ipairs(lines) do
        local clean = NormalizeBuildText(line)
        for _, label in ipairs(labels or {}) do
            local normalizedLabel = NormalizeBuildText(label)
            if clean == normalizedLabel then
                return lines[i + 1]  -- valor en la linea siguiente: ya viene con casing original
            end
            -- Forma "Etiqueta: Valor" / "Etiqueta - Valor".
            local sepValue = clean:match("^" .. normalizedLabel .. "%s*[:%-]%s*(.+)$")
            if sepValue and sepValue ~= "" and sepValue ~= normalizedLabel then
                local raw = line:match("[:%-]%s*(.+)$")  -- tras el primer separador, casing original
                return TrimText(raw or sepValue)
            end
            -- Forma "Etiqueta Valor" (sin separador): quita las palabras de la etiqueta.
            local spaceValue = clean:match("^" .. normalizedLabel .. "%s+(.+)$")
            if spaceValue and spaceValue ~= "" and spaceValue ~= normalizedLabel then
                local _, wordCount = normalizedLabel:gsub("%S+", "")
                local raw = line:match("^%s*" .. string.rep("%S+%s+", wordCount) .. "(.+)$")
                return TrimText(raw or spaceValue)
            end
        end
    end
    return nil
end

local function ReadStringField(tbl, fields)
    if type(tbl) ~= "table" then return nil end
    for _, field in ipairs(fields or {}) do
        local value = tbl[field]
        if type(value) == "string" and value ~= "" then
            return value
        end
        if type(value) == "number" then
            return tostring(value)
        end
    end
    return nil
end

local CollectRawAboutText

local function ReadProfileBuildField(profile, fields)
    if type(profile) ~= "table" then return nil end
    local character = type(profile.player) == "table" and profile.player or profile
    local sources = {
        character and character.characteristics,
        character and character.character,
        character and character.misc,
        character,
        profile.characteristics,
        profile.character,
        profile.misc,
        profile.data,
        profile,
    }
    for _, source in ipairs(sources) do
        local value = ReadStringField(source, fields)
        if value and value ~= "" then
            return StripInlineMarkup(value)
        end
    end
    return nil
end

local function SumMulticlassLevels(text)
    text = tostring(text or "")
    local total = 0
    local count = 0

    for line in text:gmatch("[^\r\n]+") do
        local clean = StripInlineMarkup(line)
        local level = clean:match("%((%d+)%)%s*$")
        if level and clean:match("%S") then
            total = total + (tonumber(level) or 0)
            count = count + 1
        end
    end

    if count > 0 and total > 0 then
        return tostring(total)
    end

    return nil
end

local function PrimaryClassFromAbout(text)
    text = tostring(text or "")
    local bestClass, bestLevel
    for line in text:gmatch("[^\r\n]+") do
        local iconClass = line:match("{icon:classicon_([%w_]+)")
        local clean = StripInlineMarkup(line)
        local classText, level = clean:match("^(.-)%s*%((%d+)%)%s*$")
        if level or iconClass then
            classText = tostring(classText or ""):gsub("^%s+", ""):gsub("%s+$", "")
            level = tonumber(level) or 0
            if (iconClass or classText ~= "") and level > (bestLevel or -1) then
                bestClass = iconClass or classText
                bestLevel = level
            end
        end
    end
    return bestClass
end

local CLASS_ICON_TO_HARFORD = {
    deathknight = "caballero_muerte",
    demonhunter = "cazador_demonios",
    druid = "druida",
    hunter = "cazador",
    mage = "mago",
    monk = "monje",
    paladin = "paladin",
    priest = "sacerdote",
    rogue = "picaro",
    shaman = "chaman",
    warlock = "brujo",
    warrior = "guerrero",
}

local function ResolveClassIdFromText(text, iconClass)
    if iconClass and CLASS_ICON_TO_HARFORD[iconClass] then
        return CLASS_ICON_TO_HARFORD[iconClass]
    end
    if HarfordDnDBook and HarfordDnDBook.FindClassIdByText then
        return HarfordDnDBook.FindClassIdByText(text)
    end
    return nil
end

local function ClassEntriesFromAbout(text)
    text = tostring(text or "")
    local entries = {}
    local seen = {}
    if not (HarfordDnDBook and HarfordDnDBook.FindClassIdByText) then
        return entries
    end

    for line in text:gmatch("[^\r\n]+") do
        local iconClass = line:match("{icon:classicon_([%w_]+)")
        local clean = StripInlineMarkup(line)
        local classText, levelText = clean:match("^(.-)%s*%((%d+)%)%s*$")
        classText = tostring(classText or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local level = tonumber(levelText)
        if level and level > 0 and (classText ~= "" or iconClass) then
            local classId = ResolveClassIdFromText(classText, iconClass)
            if classId and not seen[classId] then
                local subclassId = HarfordDnDBook.FindSubclassIdByText
                    and HarfordDnDBook.FindSubclassIdByText(classId, classText)
                    or nil
                if not subclassId and HarfordDnDBook.GetSubclassUnlockLevel then
                    local unlockLevel = HarfordDnDBook.GetSubclassUnlockLevel(classId)
                    if unlockLevel and level >= unlockLevel then
                        subclassId = HarfordDnDBook.GetDefaultSubclassId and HarfordDnDBook.GetDefaultSubclassId(classId) or ""
                    end
                end
                entries[#entries + 1] = {
                    classId = classId,
                    subclassId = subclassId or "",
                    level = level,
                    raw = classText,
                }
                seen[classId] = true
            end
        end
    end

    return entries
end

local function RaceEntryFromAbout(text)
    if not (HarfordDnDRaces and HarfordDnDRaces.FindRaceIdByText) then
        return nil
    end
    local lines = CleanAboutLines(text)
    local raceText = ExtractLabeledAboutValue(lines, { "raza", "race", "linaje", "especie" })
    if not raceText or raceText == "" then return nil end
    local raceId = HarfordDnDRaces.FindRaceIdByText(raceText) or raceText
    local subraceText = ExtractLabeledAboutValue(lines, { "subraza", "subrace" }) or raceText
    local subraceId = HarfordDnDRaces.FindSubraceIdByText
        and HarfordDnDRaces.FindSubraceIdByText(raceId, subraceText)
        or nil
    return {
        raceId = raceId,
        subraceId = subraceId or "",
        raw = raceText,
    }
end

local function RaceEntryFromProfile(profile)
    local value = ReadProfileBuildField(profile, { "RA", "Ra", "race", "Race", "RACE", "raza", "Raza", "RAZA" })
    if value and value ~= "" then
        local raceId = HarfordDnDRaces and HarfordDnDRaces.FindRaceIdByText and HarfordDnDRaces.FindRaceIdByText(value) or nil
        raceId = raceId or value
        local subValue = ReadProfileBuildField(profile, { "subrace", "Subrace", "subraza", "Subraza", "SUBRAZA" }) or value
        local subraceId = HarfordDnDRaces and HarfordDnDRaces.FindSubraceIdByText
            and HarfordDnDRaces.FindSubraceIdByText(raceId, subValue)
            or nil
        return { raceId = raceId, subraceId = subraceId or "", raw = value }
    end
    return RaceEntryFromAbout(CollectRawAboutText(profile))
end

-- Separa el texto crudo del trasfondo en nombre (1a linea) y primer parrafo (resto
-- hasta linea en blanco, colapsado a una sola linea y acotado). Los trasfondos
-- personalizados de TRP3 guardan en el campo BG el titulo seguido de su descripcion.
local function SplitBackgroundRaw(raw)
    raw = tostring(raw or "")
    local name, rest = raw:match("^%s*([^\r\n]+)[\r\n]+(.*)$")
    if not name then
        return TrimText(raw), ""
    end
    name = TrimText(name)
    local para = rest:match("^(.-)\r?\n%s*\r?\n") or rest
    para = TrimText(para):gsub("[\r\n]+", " ")
    if #para > 400 then para = para:sub(1, 400) .. "..." end
    return name, para
end

-- Resuelve id/nombre/desc del trasfondo. Si el nombre coincide con uno del libro,
-- usa su id (el libro aporta su propia descripcion, desc = ""). Si es personalizado,
-- id = nombre corto (con casing original) y desc = primer parrafo del campo TRP3.
local function ResolveBackgroundFields(rawValue, fromBuildField)
    rawValue = tostring(rawValue or "")
    if rawValue == "" then return nil end
    local name, desc
    if fromBuildField then
        name, desc = SplitBackgroundRaw(rawValue)
    else
        name, desc = TrimText(rawValue), ""
    end
    if name == "" then return nil end
    local bookId = HarfordDnDBackgrounds and HarfordDnDBackgrounds.FindBackgroundIdByText
        and HarfordDnDBackgrounds.FindBackgroundIdByText(name)
        or nil
    if bookId then
        return bookId, nil, ""
    end
    return name, name, desc
end

local function BackgroundIdFromAbout(text)
    local lines = CleanAboutLines(text)
    local backgroundText = ExtractLabeledAboutValue(lines, { "trasfondo", "background", "origen" })
    if not backgroundText or backgroundText == "" then return nil end
    return ResolveBackgroundFields(backgroundText, false)
end

local function BackgroundIdFromProfile(profile)
    local value = ReadProfileBuildField(profile, {
        "BG", "Bg", "background", "Background", "BACKGROUND",
        "trasfondo", "Trasfondo", "TRASFONDO", "origen", "Origen",
    })
    if value and value ~= "" then
        return ResolveBackgroundFields(value, true)
    end
    return BackgroundIdFromAbout(CollectRawAboutText(profile))
end

local CleanFeatureLine

local function IsFeatureSectionHeading(line)
    local clean = NormalizeBuildText(line)
    if clean == "" then return false end
    return clean == "rasgos de clase"
        or clean == "rasgos de clase y subclase"
        or clean == "rasgos destacables de clase"
end

local function IsMagicSectionHeading(line)
    local clean = NormalizeBuildText(line)
    if clean == "" then return false end
    return clean == "magia"
        or clean == "conjuros"
        or clean == "hechizos"
        or clean == "trucos"
        or clean == "lista de conjuros"
        or clean == "ranuras de conjuro"
        or clean == "espacios de conjuro"
end

local function IsClassInfoHeading(line)
    local clean = CleanFeatureLine(line)
    if not clean or clean == "" then return false end

    local classText, levelText = clean:match("^(.-)%s*%((%d+)%)%s*$")
    if levelText and ResolveClassIdFromText(classText) then
        return true
    end

    if HarfordDnDBook and HarfordDnDBook.FindClassIdByText then
        if HarfordDnDBook.FindClassIdByText(clean) then
            return true
        end
        for _, classDef in ipairs(HarfordDnDBook.GetClasses and HarfordDnDBook.GetClasses() or {}) do
            if classDef and classDef.id then
                local subclassId = HarfordDnDBook.FindSubclassIdByText
                    and HarfordDnDBook.FindSubclassIdByText(classDef.id, clean)
                    or nil
                if subclassId then
                    return true
                end
            end
        end
    end

    return false
end

local function IsFeatureStopHeading(line)
    local clean = NormalizeBuildText(line)
    if clean == "" then return false end
    return clean == "ataque"
        or clean == "ataques"
        or clean == "armas"
        or clean == "equipo"
        or clean == "inventario"
        or clean == "habilidades"
        or clean == "tiradas de salvacion"
        or clean == "salvaciones"
        or clean == "idiomas"
        or clean == "competencia"
        or clean == "competencias"
        or clean == "recursos"
        or clean == "conjuros"
        or clean == "notas"
        or clean == "historia"
end

local function IsSheetStatLine(line)
    local clean = NormalizeBuildText(line)
    return clean:match("^fuerza%s+%d")
        or clean:match("^destreza%s+%d")
        or clean:match("^constitucion%s+%d")
        or clean:match("^inteligencia%s+%d")
        or clean:match("^sabiduria%s+%d")
        or clean:match("^carisma%s+%d")
        or clean:match("^fue%s+%d")
        or clean:match("^des%s+%d")
        or clean:match("^con%s+%d")
        or clean:match("^int%s+%d")
        or clean:match("^sab%s+%d")
        or clean:match("^car%s+%d")
        or clean:match("^pg%s+%d")
        or clean:match("^pm%s+%d")
        or clean:match("^ca%s+%d")
end

CleanFeatureLine = function(line)
    line = StripInlineMarkup(line)
    line = line:gsub("^%s*[-•*]+%s*", "")
    line = line:gsub("^%s*%d+[%.)]%s*", "")
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line == "" then return nil end
    if line:match("^%.+$") then return nil end
    return line
end

local function FeatureLinesFromAbout(text, limit)
    local out = {}
    local inSection = false
    limit = tonumber(limit) or 12
    for rawLine in tostring(text or ""):gmatch("[^\r\n]+") do
        local clean = CleanFeatureLine(rawLine)
        if clean and IsClassInfoHeading(rawLine) then
            inSection = true
        elseif clean and IsMagicSectionHeading(clean) then
            inSection = false
        elseif clean and IsFeatureSectionHeading(clean) then
            inSection = true
        elseif clean and inSection and (IsFeatureStopHeading(clean) or IsSheetStatLine(clean)) then
            inSection = false
        elseif clean and inSection then
            out[#out + 1] = clean
            if #out >= limit then break end
        end
    end
    return out
end

local function IndentDisplayText(text, indent)
    text = NormalizeDisplaySpacing(text)
    if text == "" then return "" end
    indent = indent or "  "
    text = text:gsub("\n", "\n" .. indent)
    return indent .. text
end

local function BuildWrappedSection(title, icon, body)
    body = NormalizeDisplaySpacing(body)
    if body == "" then return nil end

    local header = ""
    if icon then
        header = API.IconMarkup(icon, 28)
    end
    if title and tostring(title) ~= "" then
        if header ~= "" then header = header .. " " end
        header = header .. "|cffffd100" .. tostring(title) .. "|r"
    end

    local line = "|cff8a7a70--------------------------------|r"
    if header == "" then
        return line .. "\n" .. IndentDisplayText(body)
    end

    return header .. "\n" .. line .. "\n" .. IndentDisplayText(body)
end

local function FindIconInTable(tbl, depth, seen, out, path)
    if type(tbl) ~= "table" or depth <= 0 then return nil end
    seen = seen or {}
    if seen[tbl] then return nil end
    seen[tbl] = true
    out = out or {}
    path = path or "profile"

    local fields = { "IC", "icon", "Icon", "iconID", "profileIcon" }
    for _, fieldName in ipairs(fields) do
        local value = ReadIconField(tbl, fieldName)
        if value then
            out[#out + 1] = {
                path = path .. "." .. fieldName,
                icon = value,
                normalized = NormalizeIconPath(value),
            }
        end
    end

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            FindIconInTable(value, depth - 1, seen, out, path .. "." .. tostring(key))
        end
    end

    return out
end

local function GetRegister()
    return TRP3_API and TRP3_API.register
end

local function GetCompanionRegister()
    return TRP3_API
        and TRP3_API.companions
        and TRP3_API.companions.register
end

local function GetTRP3PlayerID()
    return TRP3_API and TRP3_API.globals and TRP3_API.globals.player_id
end

local function IsPlayerUnitID(unitID)
    unitID = tostring(unitID or "")
    if unitID == "" then return false end
    local playerID = GetTRP3PlayerID()
    if playerID and unitID == playerID then return true end
    return API.BuildUnitID and unitID == API.BuildUnitID("player")
end

local function GetCharacterProfileData(profile)
    if type(profile) ~= "table" then return nil end
    if type(profile.player) == "table" then return profile.player end
    return profile
end

function API.IsAvailable()
    return TRP3_API ~= nil
end

function API.HasRegister()
    return GetRegister() ~= nil
end

function API.HasCompanionRegister()
    return GetCompanionRegister() ~= nil
end

function API.BuildUnitID(unit)
    unit = unit or "target"
    if not UnitName then
        return nil
    end

    if TRP3_API and TRP3_API.utils and TRP3_API.utils.str and TRP3_API.utils.str.getUnitID then
        local unitID = SafeCall(TRP3_API.utils.str.getUnitID, unit)
        if unitID and tostring(unitID) ~= "" then
            return unitID
        end
    end

    local name, realm = UnitName(unit)
    if not name or name == "" then
        return nil
    end

    realm = TrimRealm((realm and realm ~= "" and realm) or (GetRealmName and GetRealmName()) or "")
    realm = realm:gsub("%-", "")
    if realm == "" then
        return name
    end

    return name .. "-" .. realm
end

function API.GetPlayerProfile(unit)
    local register = GetRegister()
    if not register then
        return nil, "TRP3_API.register no disponible"
    end

    local unitID = API.BuildUnitID(unit or "target")
    if not unitID then
        return nil, "unitID no disponible"
    end

    if IsPlayerUnitID(unitID) and TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile then
        local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
        if profile then
            local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
            return profile, nil, unitID, profileID
        end
    end

    if register.isUnitIDKnown and not SafeCall(register.isUnitIDKnown, unitID) then
        return nil, "unitID no conocido por TRP3"
    end

    local profile = SafeCall(register.getUnitIDCurrentProfile, unitID)
    if not profile and register.getUnitIDProfile then
        profile = SafeCall(register.getUnitIDProfile, unitID)
    end

    if not profile then
        return nil, "perfil TRP3 de jugador no disponible"
    end

    local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
    return profile, nil, unitID, profileID
end

function API.GetPlayerProfileByUnitID(unitID)
    local register = GetRegister()
    if not register then
        return nil, "TRP3_API.register no disponible"
    end

    unitID = tostring(unitID or "")
    if unitID == "" then
        return nil, "unitID no disponible"
    end

    local profileID
    if register.getUnitIDProfileID then
        profileID = SafeCall(register.getUnitIDProfileID, unitID)
    end
    if not profileID and register.isUnitIDKnown and SafeCall(register.isUnitIDKnown, unitID) and register.hasProfile then
        profileID = SafeCall(register.hasProfile, unitID)
    end
    if profileID and register.getProfile then
        local profile = SafeCall(register.getProfile, profileID)
        if profile then
            return profile, nil, unitID, profileID
        end
    end

    if IsPlayerUnitID(unitID) and TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile then
        local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
        if profile then
            local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
            return profile, nil, unitID, profileID
        end
    end

    if register.isUnitIDKnown and not SafeCall(register.isUnitIDKnown, unitID) then
        return nil, "unitID no conocido por TRP3"
    end

    local profile = SafeCall(register.getUnitIDCurrentProfile, unitID)
    if not profile and register.getUnitIDProfile then
        profile = SafeCall(register.getUnitIDProfile, unitID)
    end
    if not profile and register.getProfile then
        local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
        if profileID then
            profile = SafeCall(register.getProfile, profileID)
        end
    end

    if not profile then
        return nil, "perfil TRP3 de jugador no disponible"
    end

    profileID = profileID or (register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID))
    return profile, nil, unitID, profileID
end

function API.GetPlayerProfileByProfileID(profileID)
    local register = GetRegister()
    if not register then
        return nil, "TRP3_API.register no disponible"
    end

    profileID = tostring(profileID or "")
    if profileID == "" then
        return nil, "profileID no disponible"
    end

    local profile
    if register.getProfileOrNil then
        profile = SafeCall(register.getProfileOrNil, profileID)
    end
    if not profile and register.getProfile then
        profile = SafeCall(register.getProfile, profileID)
    end
    if not profile then
        return nil, "perfil TRP3 de jugador no disponible"
    end

    return profile, nil, profileID
end

local function GetAboutSectionText(section)
    if type(section) ~= "table" then return nil end
    local text = tostring(section.TX or "")
    if text == "" then return nil end
    local icon = ReadIconField(section, "IC")
    return BuildWrappedSection(nil, icon, API.ConvertTRP3Markup(text))
end

CollectRawAboutText = function(profile)
    local character = GetCharacterProfileData(profile)
    if type(character) ~= "table" or type(character.about) ~= "table" then
        return nil
    end

    local about = character.about
    local template = tonumber(about.TE) or 1
    local parts = {}

    if template == 1 then
        local text = about.T1 and about.T1.TX
        if text and tostring(text) ~= "" then parts[#parts + 1] = tostring(text) end
    elseif template == 2 then
        local frames = about.T2 or {}
        for i = 1, #frames do
            local text = frames[i] and frames[i].TX
            if text and tostring(text) ~= "" then parts[#parts + 1] = tostring(text) end
        end
    elseif template == 3 then
        local data = about.T3 or {}
        for _, key in ipairs({ "PH", "PS", "HI" }) do
            local text = data[key] and data[key].TX
            if text and tostring(text) ~= "" then parts[#parts + 1] = tostring(text) end
        end
    end

    if #parts == 0 then return nil end
    return table.concat(parts, "\n")
end

function API.GetPlayerAboutText(profile)
    local character = GetCharacterProfileData(profile)
    if type(character) ~= "table" or type(character.about) ~= "table" then
        return nil, "profile.about vacio"
    end

    local about = character.about
    local template = tonumber(about.TE) or 1
    local parts = {}

    if template == 1 then
        local text = about.T1 and about.T1.TX
        if text and tostring(text) ~= "" then
            parts[#parts + 1] = API.ConvertTRP3Markup(text)
        end
    elseif template == 2 then
        local frames = about.T2 or {}
        for i = 1, #frames do
            local section = frames[i]
            local text = GetAboutSectionText(section)
            if text and text ~= "" then
                parts[#parts + 1] = text
            end
        end
    elseif template == 3 then
        local sections = {
            { key = "PH", title = "Fisico" },
            { key = "PS", title = "Personalidad" },
            { key = "HI", title = "Historia" },
        }
        local data = about.T3 or {}
        for _, sectionInfo in ipairs(sections) do
            local section = data[sectionInfo.key]
            local text = section and section.TX
            if text and tostring(text) ~= "" then
                local icon = ReadIconField(section, "IC")
                parts[#parts + 1] = BuildWrappedSection(sectionInfo.title, icon, API.ConvertTRP3Markup(text))
            end
        end
    end

    if #parts == 0 then
        return nil, "profile.about vacio"
    end

    return table.concat(parts, "\n\n")
end

function API.GetUnitRPName(unit)
    local register = GetRegister()
    if not register or not register.getUnitRPName then
        return nil
    end

    return SafeCall(register.getUnitRPName, unit or "target")
end

function API.NormalizeIconPath(icon)
    return NormalizeIconPath(icon)
end

function API.GetProfileIcon(profile)
    if type(profile) ~= "table" then
        return nil
    end

    local character = GetCharacterProfileData(profile)
    local directPaths = {
        { profile.data, "IC" },
        { profile.data, "icon" },
        { profile.data, "Icon" },
        { profile.characteristics, "IC" },
        { profile.characteristics, "icon" },
        { character and character.characteristics, "IC" },
        { character and character.characteristics, "icon" },
        { profile, "IC" },
        { profile, "icon" },
        { profile, "Icon" },
        { profile, "profileIcon" },
    }

    for _, candidate in ipairs(directPaths) do
        local icon = ReadIconField(candidate[1], candidate[2])
        if icon then
            return NormalizeIconPath(icon), icon
        end
    end

    local candidates = FindIconInTable(profile, 4)
    if candidates and candidates[1] then
        return candidates[1].normalized, candidates[1].icon
    end

    return nil
end

function API.GetProfileIconCandidates(profile)
    return FindIconInTable(profile, 5) or {}
end

function API.GetProfileNameColor(profile)
    local character = GetCharacterProfileData(profile)
    if type(character) ~= "table" or type(character.characteristics) ~= "table" then
        return nil
    end

    return NormalizeHexColor(character.characteristics.CH)
end

-- Devuelve el color hex (6 chars, sin #) del nombre TRP3 del unit, o nil.
-- Prueba companion profile (NPC Epsilon → data.NH) luego player profile (characteristics.CH).
function API.GetUnitNameColor(unit)
    unit = unit or "target"
    -- NPC companion profile: el color del encabezado de nombre está en data.NH
    local compProfile = API.GetEpsilonNpcProfile(unit)
    if compProfile then
        local nh = compProfile.data and compProfile.data.NH
        local hex = NormalizeHexColor(nh)
        if hex then return hex end
    end
    -- Player profile (fallback para NPCs interpretados por jugadores)
    local playerProfile = API.GetPlayerProfile(unit)
    if playerProfile then
        return API.GetProfileNameColor(playerProfile)
    end
    return nil
end

function API.GetProfileLevel(profile)
    if type(profile) ~= "table" then return nil end

    local character = GetCharacterProfileData(profile)
    local candidates = {
        character and character.characteristics and character.characteristics.LV,
        character and character.characteristics and character.characteristics.LVL,
        character and character.characteristics and character.characteristics.level,
        character and character.characteristics and character.characteristics.Nivel,
        character and character.character and character.character.LV,
        character and character.character and character.character.level,
        profile.characteristics and profile.characteristics.LV,
        profile.characteristics and profile.characteristics.LVL,
        profile.characteristics and profile.characteristics.level,
        profile.data and profile.data.LV,
        profile.data and profile.data.level,
        profile.LV,
        profile.level,
    }

    for _, value in ipairs(candidates) do
        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    local aboutText = API.GetPlayerAboutText and API.GetPlayerAboutText(profile)
    aboutText = tostring(aboutText or "")
    local multiclassLevel = SumMulticlassLevels(aboutText)
    if multiclassLevel then return multiclassLevel end

    local level = aboutText:match("[Nn]ivel%s*[:%-]?%s*(%d+)")
        or aboutText:match("[Nn]iv%.%s*[:%-]?%s*(%d+)")
        or aboutText:match("[Ll]evel%s*[:%-]?%s*(%d+)")
    if level then return level end

    return nil
end

function API.GetProfileClassEntries(profile)
    if type(profile) ~= "table" then return {} end
    return ClassEntriesFromAbout(CollectRawAboutText(profile))
end

function API.GetProfileRaceEntry(profile)
    if type(profile) ~= "table" then return nil end
    return RaceEntryFromProfile(profile)
end

function API.GetProfileBackgroundId(profile)
    if type(profile) ~= "table" then return nil end
    return (BackgroundIdFromProfile(profile))  -- solo el id (compat)
end

-- Devuelve id, nombre y descripcion (primer parrafo) del trasfondo. Para trasfondos
-- del libro: id resuelto, name = nil, desc = "" (el libro aporta su descripcion).
-- Para personalizados: id = name = titulo corto (casing original), desc = parrafo TRP3.
function API.GetProfileBackgroundEntry(profile)
    if type(profile) ~= "table" then return nil end
    return BackgroundIdFromProfile(profile)
end

function API.GetProfileFeatureLines(profile, limit)
    if type(profile) ~= "table" then return {} end
    return FeatureLinesFromAbout(CollectRawAboutText(profile), limit)
end

function API.GetProfilePrimaryClass(profile)
    if type(profile) ~= "table" then return nil end

    local aboutText = CollectRawAboutText(profile)
    local aboutClass = PrimaryClassFromAbout(aboutText)
    if aboutClass and aboutClass ~= "" then
        return aboutClass
    end

    local character = GetCharacterProfileData(profile)
    local candidates = {
        character and character.characteristics and character.characteristics.CL,
        character and character.characteristics and character.characteristics.class,
        character and character.characteristics and character.characteristics.Clase,
        character and character.character and character.character.CL,
        character and character.character and character.character.class,
        profile.characteristics and profile.characteristics.CL,
        profile.characteristics and profile.characteristics.class,
        profile.data and profile.data.CL,
        profile.data and profile.data.class,
        profile.CL,
        profile.class,
    }

    for _, value in ipairs(candidates) do
        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    return nil
end

local function ReadArmorClassField(tbl)
    if type(tbl) ~= "table" then return nil end

    local fields = { "ArmorClass", "armorClass", "AC", "ac", "CA", "ca", "Armadura", "armadura" }
    for _, field in ipairs(fields) do
        local value = tonumber(tbl[field])
        if value and value > 0 and value <= 60 then
            return math.floor(value)
        end
    end

    return nil
end

local function ParseArmorClassLine(line)
    local clean = StripInlineMarkup(line)
    clean = clean:gsub("|T.-|t", "")
    clean = clean:gsub("|c%x%x%x%x%x%x%x%x", "")
    clean = clean:gsub("|r", "")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then return nil end

    local value = clean:match("[Cc][Aa]%s*:%s*(%d+)")
        or clean:match("^%s*[Cc][Aa]%s+(%d+)")
        or clean:match("[Cc]lase%s+de%s+[Aa]rmadura%s*[:%-]?%s*(%d+)")
        or clean:match("[Aa]rmor%s+[Cc]lass%s*[:%-]?%s*(%d+)")
    value = tonumber(value)
    if value and value > 0 and value <= 60 then
        return math.floor(value)
    end

    local lower = clean:lower()
    if lower:find("armadura", 1, true) or lower:find("armor", 1, true) then
        local last
        for number in clean:gmatch("(%d+)") do
            last = tonumber(number)
        end
        if last and last > 0 and last <= 60 then
            return math.floor(last)
        end
    end

    return nil
end

function API.ParseArmorClassText(text)
    if type(text) ~= "string" or text == "" then return nil end

    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local armorClass = ParseArmorClassLine(line)
        if armorClass then
            return armorClass
        end
    end

    return nil
end

local function CollectStringsForArmorClass(value, depth, seen, out)
    if depth <= 0 then return end
    local kind = type(value)
    if kind == "string" then
        out[#out + 1] = value
    elseif kind == "table" then
        if seen[value] then return end
        seen[value] = true
        for _, child in pairs(value) do
            CollectStringsForArmorClass(child, depth - 1, seen, out)
        end
    end
end

function API.GetProfileArmorClass(profile)
    if type(profile) ~= "table" then return nil end

    local character = GetCharacterProfileData(profile)

    -- PRIORIDAD: el texto "Currently" (CU) — el jugador escribe alli su CA actual y
    -- debe ganar sobre el campo estructurado de la ficha TRP3 o cualquier otro.
    local charData = character and character.character
    local currentlyText = type(charData) == "table" and charData.CU
    if type(currentlyText) == "string" and currentlyText ~= "" then
        local fromCurrently = API.ParseArmorClassText(currentlyText)
        if fromCurrently then return fromCurrently end
    end

    local sources = {
        character and character.characteristics,
        character and character.character,
        character and character.misc,
        profile.characteristics,
        profile.character,
        profile.misc,
        profile.data,
        profile,
    }

    for _, source in ipairs(sources) do
        local armorClass = ReadArmorClassField(source)
        if armorClass then return armorClass end
    end

    local rawAboutText = CollectRawAboutText(profile)
    local armorClass = API.ParseArmorClassText(rawAboutText)
    if armorClass then return armorClass end

    local mainText = API.GetProfileMainText(profile)
    armorClass = API.ParseArmorClassText(mainText)
    if armorClass then return armorClass end

    local strings = {}
    for _, source in ipairs(sources) do
        CollectStringsForArmorClass(source, 3, {}, strings)
    end
    for _, text in ipairs(strings) do
        armorClass = API.ParseArmorClassText(text)
        if armorClass then return armorClass end
    end

    return nil
end

function API.GetPlayerArmorClass(unit)
    local profile = API.GetPlayerProfile(unit or "target")
    if not profile then return nil end
    return API.GetProfileArmorClass(profile)
end

function API.GetNpcIdFromGUID(guid)
    guid = tostring(guid or "")
    if guid == "" then
        return nil
    end

    return select(6, strsplit("-", guid))
end

function API.GetUnitNpcId(unit)
    if not UnitGUID then
        return nil
    end

    return API.GetNpcIdFromGUID(UnitGUID(unit or "target"))
end

function API.GetPhaseId()
    if C_Epsilon and C_Epsilon.GetPhaseId then
        return SafeCall(C_Epsilon.GetPhaseId)
    end

    if ARC and ARC.PHASE and ARC.PHASE.GetPhaseId then
        return SafeCall(ARC.PHASE.GetPhaseId)
    end

    if ARC and ARC.XAPI and ARC.XAPI.Phase and ARC.XAPI.Phase.GetPhaseId then
        return SafeCall(ARC.XAPI.Phase.GetPhaseId)
    end

    return nil
end

function API.BuildEpsilonNpcFullID(unit)
    local npcID = API.GetUnitNpcId(unit or "target")
    local phaseID = API.GetPhaseId()

    if not npcID or npcID == "" then
        return nil, "npcID no disponible"
    end

    if not phaseID or tostring(phaseID) == "" then
        return nil, "phaseID no disponible"
    end

    return tostring(phaseID) .. "_" .. tostring(npcID), nil, tostring(npcID), tostring(phaseID)
end

function API.GetEpsilonNpcProfile(unit)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getCompanionProfile then
        return nil, "TRP3_API.companions.register.getCompanionProfile no disponible"
    end

    local fullID, err, npcID, phaseID = API.BuildEpsilonNpcFullID(unit or "target")
    if not fullID then
        return nil, err
    end

    local profile = SafeCall(companionRegister.getCompanionProfile, fullID)
    if not profile then
        return nil, "perfil companion/NPC no disponible", fullID, npcID, phaseID
    end

    return profile, nil, fullID, npcID, phaseID
end

function API.GetEpsilonNpcProfileByFullID(fullID)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getCompanionProfile then
        return nil, "TRP3_API.companions.register.getCompanionProfile no disponible"
    end

    fullID = tostring(fullID or "")
    if fullID == "" then
        return nil, "fullID no disponible"
    end

    local profile = SafeCall(companionRegister.getCompanionProfile, fullID)
    if not profile then
        return nil, "perfil companion/NPC no disponible"
    end

    return profile
end

function API.GetEpsilonNpcProfileByProfileID(profileID)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getProfiles then
        return nil, "TRP3_API.companions.register.getProfiles no disponible"
    end

    profileID = tostring(profileID or "")
    if profileID == "" then
        return nil, "profileID no disponible"
    end

    local profiles = SafeCall(companionRegister.getProfiles)
    if type(profiles) ~= "table" then
        return nil, "perfiles companion/NPC no disponibles"
    end

    return profiles[profileID], nil
end

function API.GetEpsilonNpcProfileID(unit)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getCompanionProfileID then
        return nil, "TRP3_API.companions.register.getCompanionProfileID no disponible"
    end

    local fullID, err, npcID, phaseID = API.BuildEpsilonNpcFullID(unit or "target")
    if not fullID then
        return nil, err
    end

    return SafeCall(companionRegister.getCompanionProfileID, fullID), nil, fullID, npcID, phaseID
end

function API.GetEpsilonNpcMainText(unit)
    local profile, err, fullID, npcID, phaseID = API.GetEpsilonNpcProfile(unit or "target")
    if not profile then
        return nil, err, fullID, npcID, phaseID
    end

    local text = profile.data and profile.data.TX
    if not text or text == "" then
        return nil, "profile.data.TX vacio", fullID, npcID, phaseID
    end

    return text, nil, fullID, npcID, phaseID, profile
end

function API.GetProfileMainText(profile)
    if type(profile) ~= "table" then
        return nil, "perfil no disponible"
    end

    local text = profile.data and profile.data.TX
    if not text or text == "" then
        return nil, "profile.data.TX vacio"
    end

    return text
end

function API.GetProfileStates(profile)
    local states = {}
    if type(profile) ~= "table" then
        return states
    end

    local character = GetCharacterProfileData(profile)
    local source = profile.PE
    if type(source) ~= "table" and type(character) == "table" and type(character.misc) == "table" then
        source = character.misc.PE
    end
    if type(source) ~= "table" then
        return states
    end

    for i = 1, 5 do
        local state = source[i] or source[tostring(i)]
        if type(state) == "table" then
            local title = tostring(state.TI or "")
            local text = tostring(state.TX or "")
            local icon = ReadIconField(state, "IC")
            local active = state.AC == true or state.AC == 1 or state.AC == "1"
            if active and (title ~= "" or text ~= "" or icon) then
                states[#states + 1] = {
                    index = i,
                    active = true,
                    title = title,
                    text = text,
                    icon = NormalizeIconPath(icon),
                    rawIcon = icon,
                }
            end
        end
    end

    return states
end

function API.BuildStatesDisplayText(profile)
    local states = API.GetProfileStates(profile)
    if #states == 0 then
        return nil
    end

    local parts = {}
    for _, state in ipairs(states) do
        local title = state.title ~= "" and state.title or ("Estado " .. tostring(state.index))
        local body = ""
        if state.text ~= "" then
            local stateText = API.ConvertTRP3Markup(state.text)
            if stateText ~= "" then
                body = "|cffcccccc" .. stateText .. "|r"
            end
        end

        parts[#parts + 1] = BuildWrappedSection(title, state.icon, body ~= "" and body or " ")
    end

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, "\n")
end

function API.IconMarkup(icon, size)
    icon = NormalizeIconPath(icon)
    if not icon then return "" end
    size = tonumber(size) or 16
    return "|T" .. icon .. ":" .. tostring(size) .. ":" .. tostring(size) .. ":0:0|t"
end

function API.ConvertTRP3Markup(text)
    text = tostring(text or "")
    text = text:gsub("\r", "")

    text = text:gsub("{icon:([^:}]+):?(%d*)}", function(icon, size)
        -- Respetar el tamaño explícito del markup; si no tiene, leer de GameFontNormal
        local sz = tonumber(size)
        if not sz or sz == 0 then
            local fs = 12
            if GameFontNormal and GameFontNormal.GetFont then
                local _, s = GameFontNormal:GetFont()
                fs = s or 12
            end
            sz = math.max(16, math.ceil(fs * 2.2))
        end
        return API.IconMarkup(icon, sz)
    end)

    text = text:gsub("{col:([%x%x%x%x%x%x]+)}", "|cff%1")
    text = text:gsub("{/col}", "|r")

    text = text:gsub("{h1}", "\n|cffffd100")
    text = text:gsub("{/h1}", "|r")
    text = text:gsub("{h2}", "\n|cffffd100")
    text = text:gsub("{/h2}", "|r")
    text = text:gsub("{h3}", "\n|cffffd100")
    text = text:gsub("{/h3}", "|r")

    text = text:gsub("{p:c}", "\n")
    text = text:gsub("{p:l}", "\n")
    text = text:gsub("{p:r}", "\n")
    text = text:gsub("{p}", "\n")
    text = text:gsub("{/p}", "\n")
    text = text:gsub("{br}", "\n")

    text = text:gsub("{hr}", "\n|cff888888------------------------------|r\n")
    text = text:gsub("{li}", "\n- ")
    text = text:gsub("{/li}", "")

    text = text:gsub("{[^}]-}", "")
    text = text:gsub("\n%s+\n", "\n\n")
    return NormalizeDisplaySpacing(text)
end

function API.BuildDisplayText(profile)
    if type(profile) ~= "table" then
        return nil, "perfil no disponible"
    end

    local parts = {}
    local mainText = API.GetProfileMainText(profile)
    if not mainText then
        mainText = API.GetPlayerAboutText(profile)
    end
    if mainText and mainText ~= "" then
        parts[#parts + 1] = API.ConvertTRP3Markup(mainText)
    end

    local statesText = API.BuildStatesDisplayText(profile)
    if statesText then
        parts[#parts + 1] = statesText
    end

    if #parts == 0 then
        return nil, "profile.data.TX vacio"
    end

    return NormalizeDisplaySpacing(table.concat(parts, "\n\n"))
end

-- Devuelve array de { title=string|nil, icon=string|nil, body=string (ya convertido) }
-- leyendo la estructura TRP3 del perfil directamente (templates 1/2/3 y NPC companion).
-- Si hay secciones con h1 en el texto las usa como fallback.
function API.ParseSections(profile)
    if type(profile) ~= "table" then return nil end

    local sections = {}

    local function addSection(title, icon, rawBody)
        if not rawBody or rawBody == "" then return end
        local body = NormalizeDisplaySpacing(API.ConvertTRP3Markup(rawBody))
        -- Colapsar líneas en blanco dobles → simples para replicar densidad TRP3
        body = body:gsub("\n\n+", "\n")
        if body ~= "" then
            -- Convertir colores TRP3 del título a markup WoW; eliminar el resto de etiquetas
            local convertedTitle = title and title
                :gsub("{col:([%x%x%x%x%x%x]+)}", "|cff%1")
                :gsub("{/col}", "|r")
                :gsub("{[^}]-}", "")
                or nil
            if convertedTitle and convertedTitle:match("^[%s|]+$") then convertedTitle = nil end
            sections[#sections + 1] = { title = convertedTitle, icon = icon, body = body }
        end
    end

    -- ── Perfil de jugador (templates TRP3) ──────────────────────────────────
    local character = GetCharacterProfileData(profile)
    if type(character) == "table" and type(character.about) == "table" then
        local about    = character.about
        local template = tonumber(about.TE) or 1

        if template == 1 then
            -- Template 1: un solo bloque de texto libre
            local tx = about.T1 and about.T1.TX
            if tx and tx ~= "" then
                local icon = about.T1 and ReadIconField(about.T1, "IC")
                addSection(nil, icon, tx)
            end

        elseif template == 2 then
            -- Template 2: frames libres con título (TI) e icono (IC) propios.
            -- Si TI está vacío, usa la primera línea del TX como título.
            local frames = about.T2 or {}
            for i = 1, #frames do
                local frame = frames[i]
                if type(frame) == "table" then
                    local ti   = frame.TI and tostring(frame.TI) ~= "" and tostring(frame.TI) or nil
                    local icon = ReadIconField(frame, "IC")
                    local tx   = frame.TX and tostring(frame.TX) or ""

                    if not ti and tx ~= "" then
                        -- Extraer primera línea como título
                        local firstLine, rest = tx:match("^([^\n]+)\n?(.*)")
                        if firstLine then
                            -- Versión limpia solo para medir longitud y validar
                            local stripped = firstLine
                                :gsub("{icon:[^}]-}", "")
                                :gsub("{col:[^}]-}", ""):gsub("{/col}", "")
                                :gsub("{[^}]-}", "")
                                :gsub("^%s+", ""):gsub("%s+$", "")
                            if stripped ~= "" and #stripped <= 60 then
                                -- Pasar la línea ORIGINAL con markup para que addSection
                                -- convierta {col:...} a |cff...|r correctamente
                                ti = firstLine
                                tx = rest or ""
                            end
                        end
                    end

                    addSection(ti, icon, tx)
                end
            end

        elseif template == 3 then
            -- Template 3: secciones fijas (Físico / Personalidad / Historia)
            local t3Defs = {
                { key = "PH", title = "Físico"       },
                { key = "PS", title = "Personalidad" },
                { key = "HI", title = "Historia"     },
            }
            local data = about.T3 or {}
            for _, def in ipairs(t3Defs) do
                local sec = data[def.key]
                if type(sec) == "table" then
                    addSection(def.title, ReadIconField(sec, "IC"), sec.TX)
                end
            end
        end

    else
        -- ── NPC companion (profile.data.TX) ─────────────────────────────────
        local rawText = profile.data and profile.data.TX
        if rawText and rawText ~= "" then
            -- Intentar detectar secciones por etiquetas h1 (no h2/h3 para no fragmentar demasiado)
            local firstH = rawText:find("{h1}", 1, true)
            if firstH then
                if firstH > 1 then
                    local pre = rawText:sub(1, firstH - 1):gsub("^[\n\r%s]+",""):gsub("[\n\r%s]+$","")
                    addSection(nil, nil, pre)
                end
                local cursor = firstH
                while cursor <= #rawText do
                    local _, hE, htitle = rawText:find("{h1}(.-)%{/h1%}", cursor)
                    if not hE then break end
                    local nextH = rawText:find("{h1}", hE + 1, true)
                    local bodyRaw = rawText:sub(hE + 1, nextH and nextH - 1 or #rawText)
                    bodyRaw = bodyRaw:gsub("^[\n\r]+",""):gsub("[\n\r]+$","")
                    addSection(htitle, nil, bodyRaw)
                    cursor = nextH or (#rawText + 1)
                end
            else
                -- Sin etiquetas: sección única
                addSection(nil, nil, rawText)
            end
        end
    end

    -- Rasgos activos (glances TRP3) como sección extra al final, renderizados como texto.
    local rawStates = API.GetProfileStates(profile)
    if #rawStates > 0 then
        sections[#sections + 1] = {
            title = "Rasgos",
            icon  = nil,
            body  = API.BuildStatesDisplayText(profile) or "",
        }
    end

    return #sections > 0 and sections or nil
end

-- Genera el string de hyperlink de chat para un estado específico.
-- profType: "p" (jugador) o "n" (NPC companion)
-- profID:   profileID TRP3 o fullID de companion
function API.BuildStateLinkString(profType, profID, stateIdx, stateTitle)
    if not profType or not profID or profID == "" then return nil end
    local cleanTitle = (stateTitle or "Estado")
        :gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("{[^}]-}", "")
    return string.format("|cff88ccff|Hharfordstate:%s:%s:%d|h[%s]|h|r",
        profType, profID, stateIdx, cleanTitle)
end

-- Busca un estado a partir de los datos de un link "harfordstate:TYPE:ID:IDX".
-- Devuelve (stateObj, nil) o (nil, mensajeError).
function API.GetStateFromLink(linkData)
    local profType, profID, idxStr = linkData:match("^harfordstate:([pn]):([^:]+):(%d+)$")
    if not profType then return nil, "Link inválido" end
    local idx = tonumber(idxStr)
    if not idx then return nil, "Índice inválido" end

    local profile
    if profType == "p" then
        if API.GetPlayerProfileByProfileID then
            profile = API.GetPlayerProfileByProfileID(profID)
        end
    else
        if API.GetEpsilonNpcProfileByFullID then
            profile = API.GetEpsilonNpcProfileByFullID(profID)
        end
        if not profile and API.GetEpsilonNpcProfileByProfileID then
            profile = API.GetEpsilonNpcProfileByProfileID(profID)
        end
    end

    if not profile then return nil, "Perfil no disponible localmente" end

    local states = API.GetProfileStates(profile)
    local state  = states and states[idx]
    if not state then return nil, "Estado no encontrado (idx=" .. idx .. ")" end
    return state, nil
end

function API.StripTRP3Markup(text)
    text = tostring(text or "")
    text = text:gsub("{h1}", "\n")
    text = text:gsub("{h2}", "\n")
    text = text:gsub("{h3}", "\n")
    text = text:gsub("{/h1}", "\n")
    text = text:gsub("{/h2}", "\n")
    text = text:gsub("{/h3}", "\n")
    text = text:gsub("{br}", "\n")
    text = text:gsub("{p}", "\n")
    text = text:gsub("{/p}", "\n")
    text = text:gsub("{col:[^}]-}", "")
    text = text:gsub("{/col}", "")
    text = text:gsub("{icon:[^}]-}", "")
    text = text:gsub("{[^}]-}", "")
    text = text:gsub("\r", "")
    text = text:gsub("\n%s+\n", "\n\n")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

function API.GetPhaseAddonProfileKey(unit)
    local npcID = API.GetUnitNpcId(unit or "target")
    if not npcID or npcID == "" then
        return nil, "npcID no disponible"
    end

    return "TOTALRP_PROFILE_" .. tostring(npcID), nil, tostring(npcID)
end

-- ─── Parser de stat block NPC ──────────────────────────────────────────────────
-- Lee el campo "Acerca de / descripción" de TRP3 y extrae las stats D&D 5e.
-- Formato soportado:
--   Línea libre con tipo/alineamiento
--   CA N (descripción)
--   FUE N (+M)  DES N (+M)  ... (siglas ES o EN)
--   {h3}Sección{/h3}  con contenido en líneas posteriores
-- Las secciones pueden faltar o estar en cualquier orden.
do
    local STAT_ABBREV = {
        FUE="strength", STR="strength",
        DES="dexterity", DEX="dexterity",
        CON="constitution",
        INT="intelligence",
        SAB="wisdom", WIS="wisdom",
        CAR="charisma", CHA="charisma",
    }

    -- Nombres completos normalizados (sin acento, minúsculas)
    local STAT_FULL = {
        fuerza="strength",   strength="strength",
        destreza="dexterity", dexterity="dexterity",
        constitucion="constitution", constitution="constitution",
        inteligencia="intelligence", intelligence="intelligence",
        sabiduria="wisdom",  wisdom="wisdom",
        carisma="charisma",  charisma="charisma",
    }

    -- Títulos de sección normalizados → clave de resultado
    local SECTION_TYPE = {
        vulnerabilidad="vulnerabilities", vulnerabilidades="vulnerabilities",
        resistencia="resistances",        resistencias="resistances",
        inmunidad="immunities",           inmunidades="immunities",
        ["condicion inmune"]="immunities",
        sentidos="senses",
        velocidad="speed",
        ["tiradas de salvacion"]="savingThrows",
        ts="savingThrows",
        habilidades="skills",
        rasgos="traits",
    }

    -- Normaliza a minúsculas sin tildes para comparar claves
    local function NormKey(s)
        s = tostring(s or ""):lower()
        s = s:gsub("á","a"):gsub("é","e"):gsub("í","i"):gsub("ó","o"):gsub("ú","u"):gsub("ü","u")
        s = s:gsub("Á","a"):gsub("É","e"):gsub("Í","i"):gsub("Ó","o"):gsub("Ú","u")
        s = s:gsub("ñ","n"):gsub("Ñ","n")
        return s:gsub("^%s+",""):gsub("%s+$","")
    end

    -- Parsea "FUE 20 (+5)" o "STR 20 +5" → key, score, mod
    local function ParseStatLine(clean)
        local ab, sc, md = clean:match("^([A-Za-z]+)%s+(%d+)%s*%(([+-]%d+)%)")
        if not ab then
            ab, sc, md = clean:match("^([A-Za-z]+)%s+(%d+)%s+([+-]%d+)")
        end
        if not ab then return end
        local key = STAT_ABBREV[ab:upper()]
        return key, tonumber(sc), tonumber(md)
    end

    -- Parsea "Nombre +N" (habilidad o tirada de salvación)
    -- Para saving throws intenta mapear el nombre a una stat key.
    local function ParseBonusLine(clean)
        -- Abreviatura de 3 letras: "CON +8"
        local ab, bs = clean:match("^([A-Za-z][A-Za-z][A-Za-z])%s+([+-]%d+)%s*$")
        if ab then
            local key = STAT_ABBREV[ab:upper()]
            if key then return key, tonumber(bs) end
        end
        -- Nombre completo: "Constitución +8" / "Intimidación +3"
        local name, bonus = clean:match("^(.-)%s+([+-]%d+)%s*$")
        if name and bonus then
            local statKey = STAT_FULL[NormKey(name)]
            return statKey or name, tonumber(bonus)
        end
    end

    local function IsDecor(s)
        return s == "" or (s:match("^[%.%-=•·─_]+$") ~= nil)
    end

    -- Parsea el texto crudo de un stat block NPC.
    -- Devuelve tabla con: rawHeader, ac, acDesc, stats{}, savingThrows{},
    -- skills{}, resistances{}, vulnerabilities{}, immunities{}, senses{}, speed.
    function API.ParseNPCStatBlock(rawText)
        if not rawText or rawText == "" then return nil end

        local result = {
            rawHeader = nil, ac = nil, acDesc = nil,
            stats = {},
            savingThrows = {}, skills = {},
            resistances = {}, vulnerabilities = {}, immunities = {},
            senses = {}, speed = nil,
        }

        local inHeader = true   -- true hasta el primer {h3}
        local section  = nil    -- sección activa

        for line in (rawText .. "\n"):gmatch("([^\n]*)\n") do
            line = line:gsub("\r","")

            -- Cabecera de sección {h3}Titulo{/h3}
            local h3 = line:match("{h3}(.-){/h3}")
            if h3 then
                h3 = h3:gsub("{[^}]*}",""):gsub("^%s+",""):gsub("%s+$","")
                section  = SECTION_TYPE[NormKey(h3)]
                inHeader = false
            elseif not line:match("{h%d") then
                -- Contenido: limpiar todo el markup TRP3
                local clean = line:gsub("{[^}]*}",""):gsub("^%s+",""):gsub("%s+$","")
                if not IsDecor(clean) then
                    if inHeader then
                        -- Primera línea con texto → tipo/alineamiento
                        if not result.rawHeader and clean:match("%a") then
                            result.rawHeader = clean
                        end
                        -- CA N (descripción) o CA N
                        local acv, acd = clean:match("^C[Aa]%s+(%d+)%s*%((.-)%)")
                        if acv then
                            result.ac = tonumber(acv)
                            result.acDesc = acd
                        elseif not result.ac then
                            local acv2 = clean:match("^C[Aa]%s+(%d+)")
                            if acv2 then result.ac = tonumber(acv2) end
                        end
                        -- Stats de habilidad
                        local k, sc, md = ParseStatLine(clean)
                        if k then result.stats[k] = { score = sc, mod = md } end

                    elseif section then
                        if section == "savingThrows" then
                            local k, b = ParseBonusLine(clean)
                            if k and b then result.savingThrows[k] = b end
                        elseif section == "skills" then
                            local name, b = ParseBonusLine(clean)
                            if name and b then
                                result.skills[#result.skills+1] = { name = tostring(name), bonus = b }
                            end
                        elseif section == "speed" then
                            result.speed = result.speed and (result.speed..", "..clean) or clean
                        elseif type(result[section]) == "table" then
                            result[section][#result[section]+1] = clean
                        end
                    end
                end
            end
        end

        return result
    end

    -- Obtiene y parsea el stat block del target (NPC companion TRP3 primero,
    -- luego perfil de jugador como fallback para NPCs interpretados).
    function API.GetNPCStatBlock(unit)
        unit = unit or "target"
        local profile = API.GetEpsilonNpcProfile(unit)
        if profile then
            local tx = profile.data and profile.data.TX
            if tx and tx ~= "" then
                local parsed = API.ParseNPCStatBlock(tx)
                if parsed then return parsed end
            end
        end
        profile = API.GetPlayerProfile(unit)
        if profile then
            local tx = CollectRawAboutText(profile)
            if tx and tx ~= "" then
                return API.ParseNPCStatBlock(tx)
            end
        end
        return nil, "No se encontro stat block para la unidad"
    end

    -- Devuelve (name, raidIconMarkup) para el unit.
    -- name      → nombre RP de TRP3 o nombre WoW.
    -- raidIcon  → markup |T...|t del marcador de raid, o nil si no tiene.
    function API.GetNPCDisplayInfo(unit)
        unit = unit or "target"
        local name = API.GetUnitRPName(unit)
        if not name or name == "" then
            name = (GetUnitName and GetUnitName(unit)) or "NPC"
        end
        local raidIcon = nil
        if GetRaidTargetIndex then
            local idx = GetRaidTargetIndex(unit)
            if idx and idx >= 1 and idx <= 8 then
                raidIcon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"
                    .. idx .. ":14:14|t"
            end
        end
        return name, raidIcon
    end
end
-- ─── Fin parser stat block ─────────────────────────────────────────────────────

-- Links de estado generados localmente por Harford. TRP3 no expone borrado de
-- links enviados, por lo que reutilizamos una copia registrada por contenido.
-- Esta ruta solo existe para estados ajenos: los links propios y los clicks
-- sobre hyperlinks visibles se dejan al comportamiento nativo de TRP3.
do
    local glanceLinkCache = {}
    local knownGlanceHyperlinks = {}
    local lastGlanceLinkInfo

    local function InsertChatText(text)
        local editbox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        if editbox then
            if ChatEdit_FocusActiveWindow then ChatEdit_FocusActiveWindow() end
            editbox:Insert(text)
        elseif ChatFrame_OpenChat then
            ChatFrame_OpenChat(text)
        end
    end

    function API.CreateGlanceLink(glance)
        local module = TRP3_API and TRP3_API.AtFirstGlanceChatLinksModule
        if not (module and glance and glance.AC and TRP3_API.ChatLink) then return nil end

        local title = tostring(glance.TI or "")
        local text = tostring(glance.TX or "")
        local icon = tostring(glance.IC or "")
        for i = 1, #glanceLinkCache do
            local cached = glanceLinkCache[i]
            if cached.title == title and cached.text == text and cached.icon == icon then
                lastGlanceLinkInfo = cached.info
                return cached.link
            end
        end

        local name, data = module:GetLinkData(glance, false)
        local link = TRP3_API.ChatLink(name, data, module:GetID())
        local identifier = link:GetIdentifier()
        local sender = TRP3_API and TRP3_API.globals and TRP3_API.globals.player_id
        local marker = link:GetText()
        local hyperlink = sender and string.format(
            "|cffffd100|Htotalrp3:%s:%s|h[%s]|h|r", sender, identifier, identifier) or nil
        local info = {
            link = link,
            sender = sender,
            identifier = identifier,
            marker = marker,
            hyperlink = hyperlink,
        }
        if hyperlink then
            knownGlanceHyperlinks[hyperlink] = true
        end
        glanceLinkCache[#glanceLinkCache + 1] = {
            title = title,
            text = text,
            icon = icon,
            link = link,
            info = info,
        }
        lastGlanceLinkInfo = info
        return link
    end

    function API.GetLastGlanceLinkInfo()
        return lastGlanceLinkInfo
    end

    function API.IsKnownGlanceHyperlink(hyperlink)
        return knownGlanceHyperlinks[tostring(hyperlink or "")] == true
    end

    function API.InsertGlanceLink(glance)
        local link = API.CreateGlanceLink(glance)
        if not link then return end
        InsertChatText(link:GetText())
    end
end

-- ── Shift-click en estados ajenos en el viewer TRP3 ──────────────────────────
-- TRP3 no inserta estados ajenos por shift-click. Harford añade solo esa ruta;
-- para estados propios se conserva intacto el flujo nativo de TRP3.
--
-- Tres conjuntos de botones cubiertos:
--   TRP3_RegisterMiscViewGlanceSlot1-5          → viewer jugadores (pestaña misc)
--   TRP3_CompanionsPageInformationConsult_GlanceSlot1-5 → viewer NPCs/companions
--   TRP3_GlanceBarSlot1-5                       → barra flotante del target frame
do
    local GLANCE_PREFIXES = {
        "TRP3_RegisterMiscViewGlanceSlot",
        "TRP3_CompanionsPageInformationConsult_GlanceSlot",
        "TRP3_GlanceBarSlot",
    }

    -- Estados ajenos (isCurrentMine=false): TRP3 no hace nada en shift-click,
    -- así que lo añadimos con HookScript.
    local function HookGlanceShiftClick()
        if not (TRP3_API and TRP3_API.AtFirstGlanceChatLinksModule) then return end
        for _, prefix in ipairs(GLANCE_PREFIXES) do
            for i = 1, 5 do
                local btn = _G[prefix .. i]
                if btn and not btn._harfordHooked then
                    btn._harfordHooked = true
                    btn:HookScript("OnClick", function(self, clickType)
                        if clickType ~= "LeftButton" then return end
                        if not IsShiftKeyDown() then return end
                        if self.isCurrentMine then return end
                        local glance = self.data
                        if not glance or not glance.AC then return end
                        API.InsertGlanceLink(glance)
                    end)
                end
            end
        end
    end

    -- PLAYER_LOGIN garantiza que todos los addons han cargado y sus init() han corrido.
    -- C_Timer.After(0) da un frame extra por si TRP3 difiere su init vía scheduler.
    local _glanceHookFrame = CreateFrame("Frame")
    _glanceHookFrame:RegisterEvent("PLAYER_LOGIN")
    _glanceHookFrame:SetScript("OnEvent", function()
        C_Timer.After(0, function()
            HookGlanceShiftClick()
        end)
        _glanceHookFrame:UnregisterAllEvents()
    end)
end
