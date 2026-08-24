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

-- OJO: devolver `x:gsub(...)` directamente propaga DOS valores (texto + nº de sustituciones).
-- Si el resultado cae como ULTIMO elemento de una tabla o lista de argumentos, el contador se
-- cuela como elemento extra (ya provoco un crash al cargar una ficha). Asignar y devolver UNO.
local function NormalizeBuildText(value)
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

-- Se expone para que quien componga texto de About pueda comparar titulos sin markup (p.ej.
-- localizar el frame de una clase por su cabecera) sin duplicar la lista de etiquetas.
API.StripInlineMarkup = StripInlineMarkup

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
    local text = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return text  -- un solo valor: ver la nota de multi-retorno en NormalizeBuildText
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

local ABOUT_VALUE_BOUNDARY = {
    clase = true, clases = true, class = true, raza = true, race = true,
    subraza = true, subrace = true, trasfondo = true, background = true, origen = true,
    caracteristicas = true, atributos = true, habilidades = true, skills = true,
    salvaciones = true, ["tiradas de salvacion"] = true, ataques = true, ataque = true,
    magia = true, conjuros = true, rasgos = true, idiomas = true, competencias = true,
    equipo = true, armas = true, armadura = true, recursos = true,
}

local function IsAboutValueBoundary(line)
    local clean = NormalizeBuildText(line):gsub("[:%-].*$", "")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
    return ABOUT_VALUE_BOUNDARY[clean] == true
end

local function ExtractLabeledAboutValueAndParagraph(lines, labels)
    if type(lines) ~= "table" then return nil end
    for i, line in ipairs(lines) do
        local clean = NormalizeBuildText(line)
        for _, label in ipairs(labels or {}) do
            local normalizedLabel = NormalizeBuildText(label)
            local value, valueIndex
            if clean == normalizedLabel then
                value, valueIndex = lines[i + 1], i + 1
            else
                local sepValue = clean:match("^" .. normalizedLabel .. "%s*[:%-]%s*(.+)$")
                if sepValue and sepValue ~= "" and sepValue ~= normalizedLabel then
                    local raw = line:match("[:%-]%s*(.+)$")
                    value, valueIndex = TrimText(raw or sepValue), i
                else
                    local spaceValue = clean:match("^" .. normalizedLabel .. "%s+(.+)$")
                    if spaceValue and spaceValue ~= "" and spaceValue ~= normalizedLabel then
                        local _, wordCount = normalizedLabel:gsub("%S+", "")
                        local raw = line:match("^%s*" .. string.rep("%S+%s+", wordCount) .. "(.+)$")
                        value, valueIndex = TrimText(raw or spaceValue), i
                    end
                end
            end
            value = TrimText(value or "")
            if value ~= "" then
                local desc = {}
                for j = (valueIndex or i) + 1, #lines do
                    local nextLine = TrimText(lines[j])
                    if nextLine == "" or IsAboutValueBoundary(nextLine) then break end
                    desc[#desc + 1] = nextLine
                    if #table.concat(desc, " ") > 400 then break end
                end
                local paragraph = table.concat(desc, " ")
                if #paragraph > 400 then paragraph = paragraph:sub(1, 400) .. "..." end
                return value, paragraph
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
        local classText = clean:match("^(.-)%s*%(%d+%)%s*$")
        local iconClass = line:match("{icon:classicon_([%w_]+)")
        local isKnownClass = iconClass ~= nil
            or (classText and HarfordDnDBook and HarfordDnDBook.FindClassIdByText
                and HarfordDnDBook.FindClassIdByText(classText) ~= nil)
        if level and isKnownClass then
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

    for rawLine in text:gmatch("[^\r\n]+") do
      -- Un titulo puede llevar multiclase en una sola linea: "Guerrero Armas (3) || Brujo (1)".
      for line in (rawLine .. "||"):gmatch("(.-)%s*||") do
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
    local backgroundText, backgroundDesc = ExtractLabeledAboutValueAndParagraph(lines, { "trasfondo", "background", "origen" })
    if not backgroundText or backgroundText == "" then return nil end
    if backgroundDesc and backgroundDesc ~= "" then
        return ResolveBackgroundFields(backgroundText .. "\n" .. backgroundDesc, true)
    end
    return ResolveBackgroundFields(backgroundText, false)
end

local function BackgroundIdFromProfile(profile)
    local aboutId, aboutRaw, aboutDesc = BackgroundIdFromAbout(CollectRawAboutText(profile))
    local value = ReadProfileBuildField(profile, {
        "BG", "Bg", "background", "Background", "BACKGROUND",
        "trasfondo", "Trasfondo", "TRASFONDO", "origen", "Origen",
    })
    if value and value ~= "" then
        local bgId, raw, desc = ResolveBackgroundFields(value, true)
        if (not desc or desc == "") and aboutDesc and aboutDesc ~= ""
            and NormalizeBuildText(bgId or raw or "") == NormalizeBuildText(aboutId or aboutRaw or "") then
            desc = aboutDesc
        end
        return bgId, raw, desc
    end
    return aboutId, aboutRaw, aboutDesc
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
    -- El TITULO del frame (TI) lleva clase/raza; incluirlo (aunque el cuerpo TX este vacio).
    local title = section.TI and tostring(section.TI) or nil
    if text == "" and (not title or title == "") then return nil end
    local icon = ReadIconField(section, "IC")
    return BuildWrappedSection(title, icon, API.ConvertTRP3Markup(text))
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
            local fr = frames[i]
            if fr then
                -- El TITULO del frame lleva clase/subclase/nivel y raza; sin esto Harford no los lee.
                if fr.TI and tostring(fr.TI) ~= "" then parts[#parts + 1] = tostring(fr.TI) end
                if fr.TX and tostring(fr.TX) ~= "" then parts[#parts + 1] = tostring(fr.TX) end
            end
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

-- Sustituye solo el bloque About del perfil local a traves de la API publica de
-- TRP3. El resto de datos del personaje (nombre, apariencia y campos propios)
-- se conserva tal cual.
-- Escribe el About del perfil LOCAL. Acepta:
--   * una cadena  -> plantilla 1 (texto unico, TE=1/T1.TX)
--   * una lista de frames { IC=icono, TX=texto } -> plantilla 2 (bloques con icono, TE=2/T2)
-- Lo hace EXACTAMENTE como el editor nativo de TRP3 (register_about.lua:save): escribe IN-PLACE
-- sobre `getPlayerCurrentProfile().player.about` (donde TRP3 y Harford leen), hace wipe+copia sin
-- reemplazar la referencia, sube la version `v` (para que el intercambio propague el cambio a otros)
-- y dispara REGISTER_DATA_UPDATED para refrescar la UI. El antiguo `saveInformation(playerID,
-- "character", copiaDelPlayer)` era doblemente incorrecto: anidaba TODO el player bajo la clave
-- "character" y escribia en el nivel equivocado (top-level .about en vez de .player.about).
--
-- IMPORTANTE: el editor nativo de TRP3 lee SIEMPRE las tres plantillas antes de decidir cual
-- mostrar. Por tanto un About de plantilla 1 o 2 tambien debe conservar T1, T2 y T3 (con PH/PS/HI),
-- aunque solo una de ellas contenga informacion. Omitirlas permite ver el perfil, pero rompe al
-- abrirlo para editar con "Nil template1 data or not a table".
local function EnsureAboutSchema(about)
    if type(about) ~= "table" then return false end

    local changed = false
    -- OJO: nada de tablas vacias. Una tabla sin claves NO llega a las SavedVariables, asi
    -- que al recargar T1/T3 volvian a faltar y el editor de TRP3 fallaba con
    -- "Nil template1 data or not a table". Se rellenan con los valores por defecto que el
    -- propio editor lee (`T1.TX or ""`, `T3.PH.BK or 1`), que ademas es contenido legitimo.
    if type(about.T1) ~= "table" then about.T1 = { TX = "" }; changed = true end
    if type(about.T1.TX) ~= "string" then about.T1.TX = ""; changed = true end
    if type(about.T2) ~= "table" then about.T2 = {}; changed = true end
    if type(about.T3) ~= "table" then about.T3 = {}; changed = true end
    for _, key in ipairs({ "PH", "PS", "HI" }) do
        if type(about.T3[key]) ~= "table" then
            about.T3[key] = { BK = 1, TX = "" }
            changed = true
        end
    end
    if type(about.TE) ~= "number" then about.TE = 1; changed = true end
    if type(about.v) ~= "number" then about.v = 1; changed = true end
    return changed
end

local function NotifyAboutUpdated()
    if not (TRP3_API and TRP3_API.events and TRP3_API.events.fireEvent
        and TRP3_API.events.REGISTER_DATA_UPDATED) then
        return
    end
    local profileID = TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfileID
        and SafeCall(TRP3_API.profile.getPlayerCurrentProfileID)
    SafeCall(TRP3_API.events.fireEvent, TRP3_API.events.REGISTER_DATA_UPDATED,
        GetTRP3PlayerID(), profileID, "about")
end

-- Repara el esquema del About del perfil ACTIVO. Es EXPLICITA a proposito: la norma del
-- proyecto es no tocar perfiles existentes por nuestra cuenta. Sirve para los perfiles que
-- quedaron sin T1/T3 por haberlos escrito con tablas vacias, que no sobreviven al guardado.
function API.RepairPlayerAboutSchema()
    if not (TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile) then
        return false, "No hay un perfil local de TRP3 activo."
    end
    local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
    if type(profile) ~= "table" or type(profile.player) ~= "table" then
        return false, "No se encontro el perfil local de TRP3."
    end
    local about = profile.player.about
    if type(about) ~= "table" then
        about = {}
        profile.player.about = about
    end
    local faltaban = {}
    if type(about.T1) ~= "table" then faltaban[#faltaban + 1] = "T1" end
    if type(about.T3) ~= "table" then faltaban[#faltaban + 1] = "T3" end
    local cambiado = EnsureAboutSchema(about)
    if cambiado then NotifyAboutUpdated() end
    return true, (#faltaban > 0 and ("faltaban: " .. table.concat(faltaban, ", "))
        or (cambiado and "esquema completado" or "ya estaba bien"))
end

-- Huella de un frame para reconocer los que genero Harford. djb2 sobre el texto: no necesita ser
-- criptografica, solo estable y corta para guardarla en SavedVariables.
local function FrameHash(text)
    local h = 5381
    for i = 1, #text do
        h = (h * 33 + text:byte(i)) % 4294967296
    end
    return string.format("%x:%d", h, #text)
end

API.FrameHash = FrameHash

function API.ReplaceAboutFrames(frames)
    if type(frames) ~= "table" or #frames == 0 then return false, "Sin frames." end
    -- Reutiliza la ruta normal: sin `previous` no sustituye nada, asi que se le pasa la huella de
    -- TODOS los frames actuales para que los retire y deje exactamente la lista dada.
    local profile = SafeCall(TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile)
    local about = type(profile) == "table" and type(profile.player) == "table" and profile.player.about
    local previas = {}
    for _, fr in ipairs((type(about) == "table" and type(about.T2) == "table") and about.T2 or {}) do
        if type(fr) == "table" and fr.TX then previas[#previas + 1] = FrameHash(tostring(fr.TX)) end
    end
    return API.WritePlayerAbout(frames, { previous = previas })
end

function API.WritePlayerAbout(content, opts)
    if not (TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile) then
        return false, "No hay un perfil local de TRP3 activo."
    end
    local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
    if type(profile) ~= "table" then
        return false, "No se encontro el perfil local de TRP3."
    end
    if type(profile.player) ~= "table" then profile.player = {} end

    -- Harford siempre genera plantilla 2: la ficha se compone de frames de contenido TRP3.
    -- Si algun llamador futuro aporta texto plano, se conserva como un unico frame T2.
    -- Con contenido por defecto, NO vacias: las tablas sin claves no llegan al fichero de
    -- SavedVariables y el editor de TRP3 falla al releer el perfil.
    -- El contenido de las plantillas 1 y 3 se CONSERVA. Harford escribe en la 2, pero blanquear
    -- las otras borraba la biografia de quien la tuviera escrita ahi.
    local prev = type(profile.player.about) == "table" and profile.player.about or {}
    local function KeepSection(seccion)
        local origen = type(prev.T3) == "table" and prev.T3[seccion] or nil
        if type(origen) ~= "table" then return { BK = 1, TX = "" } end
        return { BK = tonumber(origen.BK) or 1, TX = tostring(origen.TX or "") }
    end
    local newAbout = {
        T1 = { TX = (type(prev.T1) == "table" and tostring(prev.T1.TX or "")) or "" },
        T2 = {},
        T3 = {
            PH = KeepSection("PH"),
            PS = KeepSection("PS"),
            HI = KeepSection("HI"),
        },
    }
    local frames = {}
    if type(content) == "table" then
        for _, fr in ipairs(content) do
            if type(fr) == "table" and fr.TX and tostring(fr.TX) ~= "" then
                frames[#frames + 1] = { IC = fr.IC, TX = tostring(fr.TX) }
            end
        end
    else
        local text = tostring(content or "")
        if text == "" then return false, "El About no puede estar vacio." end
        frames[1] = { TX = text }
    end
    if #frames == 0 then return false, "El About no tiene contenido." end

    -- Huellas de lo que Harford escribio la vez anterior. Sin ellas (primera pasada, o perfil
    -- escrito a mano) no se reconoce nada como propio y los frames generados se anaden al FINAL,
    -- detras de lo que ya hubiera: anadir es seguro, sustituir a ciegas no.
    local previas = {}
    for _, h in ipairs((opts and opts.previous) or {}) do previas[h] = true end

    -- Punto de insercion cuando NO se sustituye ningun frame: sin el, lo nuevo cae al final del
    -- About, detras del lore y las notas del jugador. Con `opts.insertAfter` (una huella) se
    -- coloca justo despues de ese frame, que es lo que conserva el orden del perfil.
    local trasEsta = opts and opts.insertAfter
    local antes, despues, sustituidos = {}, {}, 0
    local corte = false
    if type(prev.T2) == "table" then
        for _, fr in ipairs(prev.T2) do
            if type(fr) == "table" and fr.TX then
                local huella = FrameHash(tostring(fr.TX))
                if previas[huella] then
                    sustituidos = sustituidos + 1
                elseif sustituidos > 0 or corte then
                    despues[#despues + 1] = { IC = fr.IC, TX = fr.TX }
                else
                    antes[#antes + 1] = { IC = fr.IC, TX = fr.TX }
                    -- El de referencia se queda en `antes`, asi que lo nuevo entra detras de el.
                    if trasEsta and huella == trasEsta then corte = true end
                end
            end
        end
    end

    local finales, huellas = {}, {}
    for _, fr in ipairs(antes) do finales[#finales + 1] = fr end
    for _, fr in ipairs(frames) do
        finales[#finales + 1] = fr
        huellas[#huellas + 1] = FrameHash(fr.TX)
    end
    for _, fr in ipairs(despues) do finales[#finales + 1] = fr end

    newAbout.TE = 2
    newAbout.T2 = finales

    -- Escritura IN-PLACE sobre profile.player.about (nunca reemplazar la referencia).
    local about = profile.player.about
    if type(about) ~= "table" then
        about = {}
        profile.player.about = about
    end
    local prevVersion = tonumber(about.v) or 0
    local previousBackground = about.BK
    for key in pairs(about) do about[key] = nil end
    for key, value in pairs(newAbout) do about[key] = value end
    about.BK = previousBackground or 1
    EnsureAboutSchema(about)
    if TRP3_API.utils and TRP3_API.utils.math and TRP3_API.utils.math.incrementNumber then
        about.v = SafeCall(TRP3_API.utils.math.incrementNumber, prevVersion, 2) or (prevVersion + 1)
    else
        about.v = prevVersion + 1
    end

    NotifyAboutUpdated()
    -- Las huellas vuelven al llamador, que es quien las persiste para la proxima reescritura.
    return true, nil, huellas, { conservados = #antes + #despues, sustituidos = sustituidos }
end

-- Rellena raza/clase en las characteristics TRP3 (RA/CL) del perfil LOCAL para que cargarficha y los
-- lectores TRP3 (color de clase, nameplates) detecten raza/clase de una ficha recien creada. SOLO
-- escribe campos VACIOS: no pisa la identidad RP que el jugador ya haya puesto. Escribe in-place como
-- WritePlayerAbout y dispara REGISTER_DATA_UPDATED con "characteristics".
function API.WritePlayerRaceClass(raceName, className)
    if not (TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile) then
        return false, "No hay un perfil local de TRP3 activo."
    end
    local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
    if type(profile) ~= "table" then return false, "No se encontro el perfil local de TRP3." end
    if type(profile.player) ~= "table" then profile.player = {} end
    local ch = profile.player.characteristics
    if type(ch) ~= "table" then ch = {}; profile.player.characteristics = ch end

    local wrote = false
    if raceName and tostring(raceName) ~= "" and (ch.RA == nil or tostring(ch.RA) == "") then
        ch.RA = tostring(raceName); wrote = true
    end
    if className and tostring(className) ~= "" and (ch.CL == nil or tostring(ch.CL) == "") then
        ch.CL = tostring(className); wrote = true
    end
    if not wrote then return false end

    local prevVersion = tonumber(ch.v) or 0
    if TRP3_API.utils and TRP3_API.utils.math and TRP3_API.utils.math.incrementNumber then
        ch.v = SafeCall(TRP3_API.utils.math.incrementNumber, prevVersion, 2) or (prevVersion + 1)
    else
        ch.v = prevVersion + 1
    end
    if TRP3_API.events and TRP3_API.events.fireEvent and TRP3_API.events.REGISTER_DATA_UPDATED then
        local profileID = TRP3_API.profile.getPlayerCurrentProfileID
            and SafeCall(TRP3_API.profile.getPlayerCurrentProfileID)
        SafeCall(TRP3_API.events.fireEvent, TRP3_API.events.REGISTER_DATA_UPDATED,
            GetTRP3PlayerID(), profileID, "characteristics")
    end
    return true
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

-- ── Carga de ficha completa desde el About TRP3 (formato "Ficha" de la mesa) ──────
-- Devuelve los DATOS MINIMOS para construir la ficha del jugador, leyendo SIEMPRE del
-- About: clases (multiclase, por classicon + nivel + subclase), 6 caracteristicas,
-- raza/subraza y trasfondo (cabeceras {h1}), descripcion de armadura (+escudo) y armas.
-- NO lee PG/PM/CA: la vida y los recursos los CALCULA el addon; la CA sale del equipo /
-- Other Information. Devuelve nil si no hay About.
do
    local ABIL_NAMES = {
        fuerza = "Fuerza", destreza = "Destreza", constitucion = "Constitucion",
        inteligencia = "Inteligencia", sabiduria = "Sabiduria", carisma = "Carisma",
    }

    -- Las vocales acentuadas y ñ son 2 bytes en UTF-8 (0xC3 0x..). Hay que reemplazar la
    -- SECUENCIA, no clases de bytes (una clase partiria "ó" en dos -> "oo" y rompe el match).
    local function NormAccents(s)
        s = HarfordClassColors.StripAccents(s):lower()
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        return s  -- un solo valor (ver nota de multi-retorno arriba)
    end

    function API.ParsePlayerSheet(profile)
        if type(profile) ~= "table" then return nil end
        local raw = CollectRawAboutText(profile)
        if not raw or raw == "" then return nil end

        local sheet = {
            classes = ClassEntriesFromAbout(raw) or {},
            abilities = {}, weapons = {},
            armorDesc = nil, hasShield = false,
            raceId = nil, subraceId = "", raceRaw = nil,
            background = nil, backgroundRaw = nil, backgroundDesc = nil,
            aboutLines = {},  -- lineas limpias (sin markup) para resolver choices por texto
        }

        local h1s, armasMode = {}, false
        local captureBackgroundDesc, backgroundDescLines = false, {}
        for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
            local h1 = line:match("{h1[^}]*}(.-){/h1}")
            local hLevel = line:match("{h([123])[^}]*}")
            if h1 then
                local h1Text = StripInlineMarkup(h1)
                h1s[#h1s + 1] = h1Text
                armasMode = false
                captureBackgroundDesc = NormAccents(h1Text):match("^trasfondo") ~= nil
            elseif hLevel and captureBackgroundDesc then
                captureBackgroundDesc = false
            end

            local clean = StripInlineMarkup(line)
            if clean ~= "" then sheet.aboutLines[#sheet.aboutLines + 1] = clean end
            if captureBackgroundDesc and not hLevel and clean ~= "" and #backgroundDescLines < 8 then
                backgroundDescLines[#backgroundDescLines + 1] = clean
            end
            local cn = NormAccents(clean)
            local firstWord = cn:match("^(%a+)")

            if firstWord and ABIL_NAMES[firstWord] then
                local score = cn:match("^%a+%s+(%-?%d+)")
                if score then sheet.abilities[ABIL_NAMES[firstWord]] = tonumber(score) end
            elseif cn:match("^armadura") then
                -- Solo la PRIMERA "Armadura ..." (la del bloque de stats); las posteriores son
                -- conjuros ("Armadura de Agathys"). "Armadura <desc> <CA>": el numero CA se ignora.
                if not sheet.armorDesc then
                    local desc = clean:gsub("^%s*[Aa]rmadura%s*", ""):gsub("%s*%+?%d+%s*$", "")
                    desc = desc:gsub("^%s+", ""):gsub("%s+$", "")
                    sheet.armorDesc = desc
                    if NormAccents(desc):find("escudo", 1, true) then sheet.hasShield = true end
                end
            elseif cn:match("^arma") then  -- "Arma" o "Armas" (armadura ya consumida arriba)
                armasMode = true
                local rest = clean:gsub("^%s*[Aa]rmas?%s*", "")
                if rest:find("%dd%d") then sheet.weapons[#sheet.weapons + 1] = rest end  -- arma en la misma linea
            elseif armasMode and clean:match("^%s*%-") then
                local w = clean:gsub("^%s*%-%s*", "")
                if w ~= "" and w:find("%dd%d") then sheet.weapons[#sheet.weapons + 1] = w end
            end
        end

        -- Raza y trasfondo desde cabeceras {h1} (se salta la primera, "Ficha").
        for i = 2, #h1s do
            local hn = NormAccents(h1s[i])
            if hn:match("^trasfondo") then
                if not sheet.background and not sheet.backgroundRaw then
                    local bgText = h1s[i]:gsub("^%s*[Tt]rasfondo%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    sheet.backgroundRaw = bgText
                    sheet.backgroundDesc = table.concat(backgroundDescLines, " ")
                    sheet.background = HarfordDnDBackgrounds and HarfordDnDBackgrounds.FindBackgroundIdByText
                        and HarfordDnDBackgrounds.FindBackgroundIdByText(bgText) or nil
                end
            elseif not sheet.raceId then
                -- Primera cabecera (no-Ficha, no-Trasfondo) que resuelva a una raza conocida.
                local rid = HarfordDnDRaces and HarfordDnDRaces.FindRaceIdByText
                    and HarfordDnDRaces.FindRaceIdByText(h1s[i])
                if rid then
                    sheet.raceId = rid
                    sheet.subraceId = HarfordDnDRaces.FindSubraceIdByText
                        and HarfordDnDRaces.FindSubraceIdByText(rid, h1s[i]) or ""
                    sheet.raceRaw = h1s[i]
                end
            end
        end

        return sheet
    end
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

    -- PRIORIDAD: el jugador escribe su CA en los textos libres de TRP3. Se leen primero
    -- "Other Information" (CO) y luego "Currently" (CU); cualquiera de los dos gana sobre
    -- el campo estructurado de la ficha o la armadura equipada.
    local charData = character and character.character
    if type(charData) == "table" then
        for _, fieldKey in ipairs({ "CO", "CU" }) do
            local txt = charData[fieldKey]
            if type(txt) == "string" and txt ~= "" then
                local fromField = API.ParseArmorClassText(txt)
                if fromField then return fromField end
            end
        end
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

    local DEFAULT_NPC_STATS = {
        strength = { score = 10, mod = 0 },
        dexterity = { score = 10, mod = 0 },
        constitution = { score = 10, mod = 0 },
        intelligence = { score = 10, mod = 0 },
        wisdom = { score = 10, mod = 0 },
        charisma = { score = 10, mod = 0 },
    }

    local function CopyDefaultStats()
        local out = {}
        for key, stat in pairs(DEFAULT_NPC_STATS) do
            out[key] = { score = stat.score, mod = stat.mod }
        end
        return out
    end

    local function NewNPCStatBlock(reason)
        return {
            rawHeader = nil, ac = 10, acDesc = nil,
            stats = CopyDefaultStats(),
            savingThrows = {}, skills = {},
            resistances = {}, vulnerabilities = {}, immunities = {},
            senses = {}, speed = nil,
            isDefault = reason or false,
        }
    end

    local STAT_LABELS = {
        fue = "strength", fuerza = "strength", str = "strength", strength = "strength",
        des = "dexterity", dex = "dexterity", destreza = "dexterity", dexterity = "dexterity",
        con = "constitution", cons = "constitution", constitucion = "constitution", constitution = "constitution",
        int = "intelligence", inteligencia = "intelligence", intelligence = "intelligence",
        sab = "wisdom", sabiduria = "wisdom", wis = "wisdom", wisdom = "wisdom",
        car = "charisma", carisma = "charisma", cha = "charisma", charisma = "charisma",
    }

    local STAT_LABEL_ORDER = {
        "constitucion", "constitution", "inteligencia", "intelligence",
        "sabiduria", "destreza", "dexterity", "charisma", "carisma",
        "strength", "fuerza", "wisdom", "cons", "fue", "str",
        "des", "dex", "con", "int", "sab", "wis", "car", "cha",
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
        caracteristicas="stats", atributos="stats", stats="stats",
        rasgos="traits",
    }

    -- Normaliza a minúsculas sin tildes para comparar claves
    local function NormKey(s)
        s = HarfordClassColors.StripAccents(s):lower()
        s = s:gsub("^%s+",""):gsub("%s+$","")
        return s  -- un solo valor (ver nota de multi-retorno arriba)
    end

    -- Parsea "FUE 20 (+5)" o "STR 20 +5" -> key, score, mod.
    local function CleanStatText(clean)
        local text = NormKey(clean)
        text = text:gsub("{[^}]*}", "")
        text = text:gsub("^%s*[-%*]+%s*", "")
        text = text:gsub("^%s*[•·]+%s*", "")
        text = text:gsub("^%s*\195\162\226\130\172\194\162%s*", "")
        text = text:gsub("^%s*\195\130\194\183%s*", "")
        text = text:gsub(",", " ")
        text = text:gsub("%s+", " ")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        return text  -- un solo valor (ver nota de multi-retorno arriba)
    end

    local function ParseStatAtStart(text)
        text = CleanStatText(text)
        for _, label in ipairs(STAT_LABEL_ORDER) do
            local key = STAT_LABELS[label]
            local sc, md, rest = text:match("^" .. label .. "%s*[:=]?%s*(%d+)%s*%(?%s*([+-]%s*%d+)%s*%)?%s*(.*)$")
            if not sc then
                sc, rest = text:match("^" .. label .. "%s*[:=]?%s*(%d+)%s*(.*)$")
            end
            if sc then
                md = tostring(md or ""):gsub("%s+", "")
                local score = tonumber(sc)
                local mod = tonumber(md)
                if not mod and score then mod = math.floor((score - 10) / 2) end
                return key, score, mod, rest
            end
        end
    end


    local function ParseStatsInto(stats, clean)
        local text = CleanStatText(clean)
        local found = false
        while text and text ~= "" do
            local key, score, mod, rest = ParseStatAtStart(text)
            if not key then break end
            stats[key] = { score = score or 10, mod = mod or 0 }
            found = true
            text = CleanStatText(rest or "")
        end
        return found
    end

    -- Parsea "Nombre +N" (habilidad o tirada de salvación)
    -- Para saving throws intenta mapear el nombre a una stat key.
    local function ParseBonusLine(clean)
        -- Abreviatura o nombre de caracteristica: "CON +8", "Cons +3", "Constitucion +8".
        local norm = CleanStatText(clean)
        local ab, bs = norm:match("^([%a]+)%s+([+-]%s*%d+)%s*$")
        if ab and bs then
            local key = STAT_LABELS[NormKey(ab)]
            if key then return key, tonumber((bs:gsub("%s+", ""))) end
        end
        -- Nombre completo: "Constitución +8" / "Intimidación +3"
        local name, bonus = clean:match("^(.-)%s+([+-]%d+)%s*$")
        if name and bonus then
            local statKey = STAT_LABELS[CleanStatText(name)]
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
        if not rawText or rawText == "" then return NewNPCStatBlock("empty") end

        local result = NewNPCStatBlock(false)

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
                        else
                            local acv2 = clean:match("^C[Aa]%s+(%d+)")
                            if acv2 then result.ac = tonumber(acv2) end
                        end
                        -- Stats de habilidad (acepta una o varias por linea).
                        ParseStatsInto(result.stats, clean)

                    elseif section then
                        if section == "stats" then
                            ParseStatsInto(result.stats, clean)
                        elseif section == "savingThrows" then
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
        return NewNPCStatBlock("missing")
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
    local GLANCE_LINK_CACHE_MAX = 160
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
        while #glanceLinkCache > GLANCE_LINK_CACHE_MAX do
            local old = table.remove(glanceLinkCache, 1)
            if old and old.info and old.info.hyperlink then
                knownGlanceHyperlinks[old.info.hyperlink] = nil
            end
        end
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

-- ─── Enlaces de habilidad clicables via TRP3 ChatLinks ───────────────────────
-- Los enlaces de tipo propio no son clicables en este cliente (no disparan SetItemRef) y no
-- podemos enganchar ChatFrame_OnHyperlinkShow. TRP3 SI hace clicables sus enlaces `totalrp3:`
-- (engancha OnHyperlinkShow internamente) y al clicar pide los datos al emisor por addon-comm.
-- Reutilizamos ese sistema: registramos un ChatLinkModule y generamos el hyperlink `totalrp3`.
do
    -- Solo cacheamos un modulo VALIDO. TRP3 puede terminar de inicializar sus ChatLinks
    -- despues de Harford; recordar un `false` en el primer intento convertia todos los
    -- enlaces de habilidad de la sesion en texto plano.
    local _abilModule

    local function EnsureAbilModule()
        if _abilModule ~= nil then return _abilModule end
        if not (TRP3_API and TRP3_API.ChatLinks and TRP3_API.ChatLinks.InstantiateModule
            and TRP3_API.ChatLink and TRP3_API.ChatLinkTooltipLines) then
            return nil
        end
        local ok, mod = pcall(function()
            -- Si ya existe (recarga del modulo), reutilizar en vez de reinstanciar (lanza assert).
            local existing = TRP3_API.ChatLinks.GetModuleByID
                and TRP3_API.ChatLinks:GetModuleByID("harford_ability")
            local m = existing or TRP3_API.ChatLinks:InstantiateModule("Harford - Habilidad", "harford_ability")
            function m:GetLinkData(feature)
                local nm = tostring((feature and feature.name) or "Habilidad")
                local icon = HarfordDnDData and HarfordDnDData.GetIcon and HarfordDnDData.GetIcon(nm)
                return nm, { name = nm, desc = (feature and feature.description) or "", icon = icon }
            end
            function m:GetTooltipLines(data)
                local nm = tostring((data and data.name) or "?")
                -- TRP3 fija el color base del titulo a blanco y no pinta icono; embebemos ambos en
                -- el propio texto del titulo (textura inline |T...|t + color |c..|r).
                local iconTag = (data and data.icon) and ("|T" .. tostring(data.icon) .. ":22:22|t ") or ""
                local lines = TRP3_API.ChatLinkTooltipLines(iconTag .. "|cffffd100" .. nm .. "|r")
                if data and data.desc and data.desc ~= "" then
                    lines:AddLine(tostring(data.desc))
                end
                return lines
            end
            return m
        end)
        if ok and mod then _abilModule = mod end
        return _abilModule
    end

    -- Devuelve el texto de un enlace de habilidad clicable (hyperlink totalrp3 de TRP3). Si TRP3
    -- no esta disponible, cae a texto de color no clicable. Nunca lanza error.
    function API.GetAbilityChatLink(feature)
        if not feature then return "" end
        local nm = tostring(feature.name or "?")
        local mod = EnsureAbilModule()
        if mod then
            local ok, text = pcall(function()
                local name, data = mod:GetLinkData(feature)
                local link = TRP3_API.ChatLink(name, data, mod:GetID())  -- almacena el enlace
                local id = link:GetIdentifier()
                local player = (TRP3_API.globals and TRP3_API.globals.player_id)
                    or (GetUnitName and GetUnitName("player", true))
                    or UnitName("player") or "?"
                -- Formato nativo de TRP3: |Htotalrp3:<jugador>:<identificador>|h[<nombre>]|h en amarillo.
                return "|cffffd100|Htotalrp3:" .. player .. ":" .. id .. "|h[" .. name .. "]|h|r"
            end)
            if ok and type(text) == "string" then return text end
        end
        -- Fallback no clicable.
        return "|cff66bbff[" .. nm .. "]|r"
    end

    -- Inserta la habilidad usando el propio modulo ChatLinks de TRP3. No construye texto
    -- manualmente: asi Shift+click conserva el mismo comportamiento que un conjuro del
    -- Compendio y que los enlaces nativos de TRP3.
    function API.InsertAbilityChatLink(feature)
        if not feature then return false end
        local mod = EnsureAbilModule()
        if not mod or not mod.InsertLink then return false end
        local ok = pcall(mod.InsertLink, mod, feature)
        return ok
    end
end

-- ─── Enlaces de FACCION clicables via TRP3 ChatLinks ─────────────────────────
-- Mismo mecanismo que las habilidades: hyperlink `totalrp3` clicable; el tooltip muestra
-- icono + nombre coloreado, el rango del emisor y la descripcion de la faccion.
do
    local _factionModule

    local function EnsureFactionModule()
        if _factionModule ~= nil then return _factionModule end
        if not (TRP3_API and TRP3_API.ChatLinks and TRP3_API.ChatLinks.InstantiateModule
            and TRP3_API.ChatLink and TRP3_API.ChatLinkTooltipLines) then
            return nil
        end
        local ok, mod = pcall(function()
            local existing = TRP3_API.ChatLinks.GetModuleByID
                and TRP3_API.ChatLinks:GetModuleByID("harford_faction")
            local m = existing or TRP3_API.ChatLinks:InstantiateModule("Harford - Faccion", "harford_faction")
            function m:GetLinkData(faction, standingText, standingColor)
                local nm = tostring((faction and faction.name) or "Faccion")
                local icon
                if HarfordReputation and HarfordReputation.ResolveIconTexture then
                    icon = HarfordReputation.ResolveIconTexture(faction and faction.icon)
                end
                return nm, {
                    name = nm,
                    desc = (faction and faction.description) or "",
                    icon = icon,
                    color = faction and faction.color,
                    standing = standingText and tostring(standingText) or nil,
                    standingColor = standingColor and tostring(standingColor) or nil,
                }
            end
            function m:GetTooltipLines(data)
                local nm = tostring((data and data.name) or "?")
                local iconTag = (data and data.icon) and ("|T" .. tostring(data.icon) .. ":22:22|t ") or ""
                -- Color del titulo: el color propio de la faccion; oro si no tiene.
                local colorHex = "ffd100"
                if data and type(data.color) == "string" then
                    local hex = data.color:match("(%x%x%x%x%x%x)$")
                    if hex then colorHex = hex end
                end
                local lines = TRP3_API.ChatLinkTooltipLines(iconTag .. "|cff" .. colorHex .. nm .. "|r")
                if data and data.standing and data.standing ~= "" then
                    -- Solo el rango, con el color NATIVO de standing (FACTION_BAR_COLORS):
                    -- rojo Odiado/Hostil, naranja Adverso, amarillo Neutral, verde Amistoso+.
                    local STANDING_BY_NAME = {
                        odiado = 1, hostil = 2, adverso = 3, neutral = 4,
                        amistoso = 5, honorable = 6, reverenciado = 7, exaltado = 8,
                    }
                    local sHex = "ffffff"
                    local id = STANDING_BY_NAME[tostring(data.standing):lower()]
                    local c = id and FACTION_BAR_COLORS and FACTION_BAR_COLORS[id]
                    if c then
                        sHex = string.format("%02x%02x%02x",
                            math.floor((c.r or 1) * 255), math.floor((c.g or 1) * 255), math.floor((c.b or 1) * 255))
                    end
                    lines:AddLine("|cff" .. sHex .. data.standing .. "|r")
                end
                if data and data.desc and data.desc ~= "" then
                    lines:AddLine(tostring(data.desc))
                end
                return lines
            end
            return m
        end)
        if ok and mod then _factionModule = mod end
        return _factionModule
    end

    -- Enlace clicable de faccion (hyperlink totalrp3). `standingText` es el rango que se
    -- congela en el enlace (el que mostraba la fila al compartirlo). Nunca lanza error.
    function API.GetFactionChatLink(faction, standingText)
        if not faction then return "" end
        local nm = tostring(faction.name or "?")
        local mod = EnsureFactionModule()
        if mod then
            local ok, text = pcall(function()
                local name, data = mod:GetLinkData(faction, standingText)
                local link = TRP3_API.ChatLink(name, data, mod:GetID())
                local id = link:GetIdentifier()
                local player = (TRP3_API.globals and TRP3_API.globals.player_id)
                    or (GetUnitName and GetUnitName("player", true))
                    or UnitName("player") or "?"
                return "|cffffd100|Htotalrp3:" .. player .. ":" .. id .. "|h[" .. name .. "]|h|r"
            end)
            if ok and type(text) == "string" then return text end
        end
        return "|cff66bbff[" .. nm .. "]|r"
    end

    -- Inserta la faccion en el editbox usando el InsertLink del propio modulo TRP3: mete el
    -- marcador de texto plano `[TRP3:id]` (lo UNICO que el chat real deja enviar; el filtro
    -- de TRP3 lo convierte en enlace clicable al RECIBIR en cada cliente). GetFactionChatLink
    -- queda para render local (AddMessage/tiradas), donde el hyperlink si funciona.
    function API.InsertFactionChatLink(faction, standingText, standingColor)
        if not faction then return false end
        local mod = EnsureFactionModule()
        if not mod or not mod.InsertLink then return false end
        local ok = pcall(mod.InsertLink, mod, faction, standingText, standingColor)
        return ok
    end
end

-- ─── Enlaces de MISION clicables via TRP3 ChatLinks (imita el link de quest nativo) ──────────
-- Mismo mecanismo que las habilidades: el clicante recibe los datos por addon-comm y ve un tooltip
-- con titulo (amarillo quest), objetivos y recompensa. El color del link es el amarillo de quest.
do
    local _questModule

    local function EnsureQuestModule()
        if _questModule ~= nil then return _questModule end
        _questModule = false
        if not (TRP3_API and TRP3_API.ChatLinks and TRP3_API.ChatLinks.InstantiateModule
            and TRP3_API.ChatLink and TRP3_API.ChatLinkTooltipLines) then
            return false
        end
        local ok, mod = pcall(function()
            local existing = TRP3_API.ChatLinks.GetModuleByID
                and TRP3_API.ChatLinks:GetModuleByID("harford_quest")
            local m = existing or TRP3_API.ChatLinks:InstantiateModule("Harford - Mision", "harford_quest")
            function m:GetLinkData(quest, titleColorHex)
                local title = tostring((quest and quest.title) or "Mision")
                return title, {
                    title      = title,
                    objective  = tostring((quest and quest.objective) or ""),
                    reward     = tostring((quest and quest.reward) or ""),
                    -- Color del titulo del tooltip (hex "ffRRGGBB"). El TEXTO del enlace lo bloquea
                    -- TRP3 en amarillo; el tooltip si es controlable, asi que va por dificultad.
                    titleColor = tostring(titleColorHex or "ffffff00"),
                }
            end
            function m:GetTooltipLines(data)
                local title = tostring((data and data.title) or "?")
                local colorHex = (data and data.titleColor) or "ffffff00"
                -- El tooltip TRP3 auto-ensancha a la anchura del titulo (SetText, cabecera en una
                -- linea), pero el boton X del RefTooltip se solapa con el final del titulo largo. Se
                -- reserva hueco para la X con espacios finales, asi el ancho incluye ese margen.
                local lines = TRP3_API.ChatLinkTooltipLines("|c" .. colorHex .. title .. "|r      ")
                if data and data.objective and data.objective ~= "" then
                    lines:AddLine("|cffffd100Objetivos|r")
                    for objLine in tostring(data.objective):gmatch("[^\n]+") do
                        lines:AddLine(objLine)
                    end
                end
                if data and data.reward and data.reward ~= "" then
                    lines:AddLine("|cffffd100Recompensa|r")
                    lines:AddLine(tostring(data.reward))
                end
                return lines
            end
            return m
        end)
        if ok and mod then _questModule = mod end
        return _questModule
    end

    -- INSERTA en el editbox de chat activo el enlace de mision en el formato ENVIABLE de TRP3
    -- (marcador plano `[TRP3:id]` via ChatLinkModule:InsertLink). Es la unica forma de que el link
    -- sobreviva al envio del jugador: WoW elimina los hyperlinks `|Htotalrp3|h` crudos de los
    -- mensajes salientes; el filtro de TRP3 reconstruye `[TRP3:id]` como link clicable al recibirlo.
    -- Devuelve true si se inserto. `quest` = fila de HarfordQuests (title, objective, reward).
    function API.InsertQuestChatLink(quest, titleColorHex)
        if not quest then return false end
        local mod = EnsureQuestModule()
        if mod and mod.InsertLink then
            local ok = pcall(function() mod:InsertLink(quest, titleColorHex) end)
            if ok then return true end
        end
        return false
    end

    -- Texto de un enlace de mision clicable (hyperlink totalrp3), para render LOCAL via AddMessage
    -- (NO para que un jugador lo envie por chat: para eso usar InsertQuestChatLink). `quest` = fila
    -- de HarfordQuests. Fallback: texto amarillo no clicable. Nunca lanza error.
    function API.GetQuestChatLink(quest)
        if not quest then return "" end
        local title = tostring(quest.title or "Mision")
        local mod = EnsureQuestModule()
        if mod then
            local ok, text = pcall(function()
                local name, data = mod:GetLinkData(quest)
                local link = TRP3_API.ChatLink(name, data, mod:GetID())
                local id = link:GetIdentifier()
                local player = (TRP3_API.globals and TRP3_API.globals.player_id)
                    or (GetUnitName and GetUnitName("player", true))
                    or UnitName("player") or "?"
                return "|cffffff00|Htotalrp3:" .. player .. ":" .. id .. "|h[" .. name .. "]|h|r"
            end)
            if ok and type(text) == "string" then return text end
        end
        return "|cffffff00[" .. title .. "]|r"
    end
end
