-- HarfordDnDProgression: estado de clase/subclase/rasgos por perfil.

HarfordDnDProgression = HarfordDnDProgression or {}

local API = HarfordDnDProgression
local SCHEMA_VERSION = 2

local function CopyTable(src)
    local out = {}
    for k, v in pairs(src or {}) do
        if type(v) == "table" then
            out[k] = CopyTable(v)
        else
            out[k] = v
        end
    end
    return out
end

local function ResolveProfileName(profileName)
    return tostring(profileName or (UnitName and UnitName("player")) or "default")
end

local function NormalizeText(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    -- Acentos por SECUENCIA UTF-8 (lider \195); NO clases de bytes (corrompen multibyte).
    value = value:gsub("\195[\129\161\128\160\132\164\130\162]", "a")
    value = value:gsub("\195[\137\169\136\168\139\171\138\170]", "e")
    value = value:gsub("\195[\141\173\140\172\143\175\142\174]", "i")
    value = value:gsub("\195[\147\179\146\178\150\182\148\180]", "o")
    value = value:gsub("\195[\154\186\153\185\156\188\155\187]", "u")
    value = value:gsub("\195[\145\177]", "n")
    -- Asignar y devolver UN solo valor: `gsub` devuelve (string, count) y si ese count se
    -- propaga como ultimo retorno (p.ej. OptionMatchName -> tabla) se cuela un numero.
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

-- La progresion se guarda anidada en profiles[name]._progression (todo lo de la ficha
-- agrupado por perfil). ProfileSlot devuelve (y crea) profiles[name].
local function ProfileSlot(name)
    HarfordDnDPersistStore = HarfordDnDPersistStore or {}
    if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
    if type(HarfordDnDPersistStore.profiles[name]) ~= "table" then HarfordDnDPersistStore.profiles[name] = {} end
    return HarfordDnDPersistStore.profiles[name]
end

local function EmptyProgression()
    return {
        schema = SCHEMA_VERSION,
        classLevels = {},
        featureStates = {},
        choices = {},
        importedProficiencies = { skillRank = {}, saveProf = {}, armorProf = {}, weaponProf = {}, toolProf = {} },
        race = { id = "", subraceId = "" },
        background = "",
        backgroundDesc = "",  -- descripcion (1er parrafo) de un trasfondo PERSONALIZADO; vacio si es del libro
        feats = {},
        -- useMana: variante de mana ACTIVA por defecto (ausente = true). Solo se persiste
        -- el opt-out explicito (false), nunca el default -> no se guarda aqui.
        activeStates = {},
    }
end

local function Migrate(data)
    if type(data) ~= "table" then data = EmptyProgression() end
    local oldSchema = tonumber(data.schema) or 0
    if type(data.classLevels) ~= "table" then data.classLevels = {} end
    if type(data.featureStates) ~= "table" then data.featureStates = {} end
    if type(data.choices) ~= "table" then data.choices = {} end
    if type(data.importedProficiencies) ~= "table" then data.importedProficiencies = {} end
    if type(data.importedProficiencies.skillRank) ~= "table" then data.importedProficiencies.skillRank = {} end
    if type(data.importedProficiencies.saveProf) ~= "table" then data.importedProficiencies.saveProf = {} end
    if type(data.importedProficiencies.armorProf) ~= "table" then data.importedProficiencies.armorProf = {} end
    if type(data.importedProficiencies.weaponProf) ~= "table" then data.importedProficiencies.weaponProf = {} end
    if type(data.importedProficiencies.toolProf) ~= "table" then data.importedProficiencies.toolProf = {} end
    if type(data.race) ~= "table" then data.race = { id = "", subraceId = "" } end
    data.race.id = tostring(data.race.id or "")
    data.race.subraceId = tostring(data.race.subraceId or "")
    data.background = tostring(data.background or "")
    data.backgroundDesc = tostring(data.backgroundDesc or "")
    if type(data.feats) ~= "table" then data.feats = {} end
    -- Variante de mana ON por defecto. Migracion a schema 2 (una sola vez): el default
    -- ANTIGUO persistia useMana=false en cada ficha sin ser una eleccion deliberada (la
    -- variante estaba off), asi que se limpia. Tras esto solo se persiste un opt-out real.
    if oldSchema < 2 and data.useMana == false then
        data.useMana = nil
    end
    if data.useMana ~= false then data.useMana = nil end  -- el default (true) no se guarda
    data.schema = SCHEMA_VERSION
    if type(data.activeStates) ~= "table" then data.activeStates = {} end
    return data
end

local function ClampLevel(level)
    level = math.floor(tonumber(level) or 1)
    if level < 1 then return 1 end
    if level > 20 then return 20 end
    return level
end

-- Override EFIMERO (no persistido) para inspeccion read-only. Cuando inspeccionas a
-- otro jugador, su progresion vive aqui (keyed por nombre corto) y NO se escribe en
-- HarfordDnDPersistStore. El panel lee normal via API.Get y obtiene el snapshot.
local inspectData = {}

local function ShortKey(name)
    name = tostring(name or "")
    if Ambiguate then
        local short = Ambiguate(name, "short")
        if short and short ~= "" then return short end
    end
    return name:match("^[^%-]+") or name
end

-- Invalida la memoizacion de FeatureEffects tras cualquier cambio de progresion.
local function Touch(profileName)
    local resolvedName = ResolveProfileName(profileName)
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
        if HarfordDnDFeatureEffects.Prime then
            HarfordDnDFeatureEffects.Prime(resolvedName)
        end
    end
    if HarfordDnDStore and HarfordDnDStore.ReconcileDerivedResources then
        HarfordDnDStore.ReconcileDerivedResources(resolvedName, "progression")
    end
end

function API.SetInspectData(name, data)
    local key = ShortKey(name)
    if key == "" then return false end
    inspectData[key] = (type(data) == "table") and Migrate(CopyTable(data)) or nil
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
        if HarfordDnDFeatureEffects.Prime then
            HarfordDnDFeatureEffects.Prime(name)
        end
    end
    return true
end

function API.ClearInspectData()
    inspectData = {}
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
    end
end

function API.Get(profileName)
    local name = ResolveProfileName(profileName)
    local ins = inspectData[ShortKey(name)]
    if ins then return ins, name end  -- modo inspeccion: snapshot efimero, sin tocar persistencia
    local slot = ProfileSlot(name)
    slot._progression = Migrate(slot._progression)
    return slot._progression, name
end

function API.Set(profileName, data)
    local name = ResolveProfileName(profileName)
    local slot = ProfileSlot(name)
    slot._progression = Migrate(CopyTable(data))
    Touch(name)
    return slot._progression, name
end

function API.HasProgression(profileName)
    local inspect = inspectData[ShortKey(ResolveProfileName(profileName))]
    if type(inspect) == "table" and type(inspect.classLevels) == "table" and #inspect.classLevels > 0 then
        return true
    end
    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
    local slot = profiles and profiles[ResolveProfileName(profileName)]
    local data = slot and slot._progression
    return type(data) == "table" and type(data.classLevels) == "table" and #data.classLevels > 0
end

function API.GetClassLevels(profileName)
    local data = API.Get(profileName)
    return data.classLevels
end

function API.GetTotalLevel(profileName)
    local data = API.Get(profileName)
    local total = 0
    for _, entry in ipairs(data.classLevels or {}) do
        total = total + (tonumber(entry.level) or 0)
    end
    return total
end

function API.GetProficiencyBonus(profileName)
    local level = API.GetTotalLevel(profileName)
    if level <= 0 then return nil end
    if level <= 4 then return 2 end
    if level <= 8 then return 3 end
    if level <= 12 then return 4 end
    if level <= 16 then return 5 end
    if level <= 20 then return 6 end
    if level <= 24 then return 7 end
    if level <= 28 then return 8 end
    return 9
end

function API.SetClassEntry(index, classId, subclassId, level, profileName)
    local data = API.Get(profileName)
    index = math.floor(tonumber(index) or (#data.classLevels + 1))
    if index < 1 then index = 1 end

    local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(classId)
    if not classDef then return false, "Clase invalida" end

    local entry = {
        classId = classDef.id,
        subclassId = subclassId == nil and (HarfordDnDBook.GetDefaultSubclassId(classDef.id) or "")
            or ((HarfordDnDBook.NormalizeSubclassId and HarfordDnDBook.NormalizeSubclassId(classDef.id, subclassId)) or tostring(subclassId or "")),
        level = ClampLevel(level),
    }
    data.classLevels[index] = entry
    Touch(profileName)
    return true, entry
end

function API.RemoveClassEntry(index, profileName)
    local data = API.Get(profileName)
    index = math.floor(tonumber(index) or 0)
    if index < 1 or index > #data.classLevels then return false end
    table.remove(data.classLevels, index)
    Touch(profileName)
    return true
end

function API.SetFeatureEnabled(featureId, enabled, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    if featureId == "" then return false end
    data.featureStates[featureId] = enabled and true or false
    Touch(profileName)
    return true
end

function API.IsFeatureEnabled(feature, profileName)
    if not feature or not feature.id then return false end
    local data = API.Get(profileName)
    local value = data.featureStates[feature.id]
    if value ~= nil then return value == true end
    return feature.type == "pasivo" or feature.type == "recurso" or feature.type == "choice"
        or feature.type == "maniobra"
end

-- Elecciones de un rasgo: lista de optionId por slot. choices[featureId] = { ... }.
function API.GetChoice(featureId, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    local slots = data.choices[featureId]
    return type(slots) == "table" and slots or {}
end

function API.SetChoiceSlot(featureId, slotIndex, optionId, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    slotIndex = math.floor(tonumber(slotIndex) or 0)
    if featureId == "" or slotIndex < 1 then return false end
    if type(data.choices[featureId]) ~= "table" then data.choices[featureId] = {} end
    optionId = tostring(optionId or "")
    if optionId == "" then
        data.choices[featureId][slotIndex] = nil
    else
        data.choices[featureId][slotIndex] = optionId
    end
    Touch(profileName)
    return true
end

-- Raza del perfil (id + subraza). Solo runtime/persistido, sin nivel.
function API.GetRace(profileName)
    local data = API.Get(profileName)
    return data.race
end

function API.SetRace(raceId, subraceId, profileName)
    local data = API.Get(profileName)
    raceId = tostring(raceId or "")
    local raceDef = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(raceId)
    data.race.id = raceDef and raceDef.id or raceId
    if subraceId == nil or tostring(subraceId) == "" then
        data.race.subraceId = HarfordDnDRaces and HarfordDnDRaces.GetDefaultSubraceId
            and HarfordDnDRaces.GetDefaultSubraceId(data.race.id) or ""
    else
        data.race.subraceId = tostring(subraceId)
    end
    Touch(profileName)
    return true
end

-- Trasfondo del perfil. Solo runtime/persistido, sin nivel.
function API.GetBackground(profileName)
    local data = API.Get(profileName)
    return data.background
end

function API.SetBackground(backgroundId, profileName)
    local data = API.Get(profileName)
    backgroundId = tostring(backgroundId or "")
    local bgDef = HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(backgroundId)
    data.background = bgDef and bgDef.id or backgroundId
    -- Al fijar un trasfondo (del libro o ninguno) se limpia la desc personalizada;
    -- SeedFromTRP3 la re-asigna despues si el trasfondo cargado es personalizado.
    data.backgroundDesc = ""
    Touch(profileName)
    return true
end

-- Descripcion (1er parrafo) de un trasfondo personalizado. Solo se usa para el tooltip
-- cuando el trasfondo no esta en el libro (los del libro usan su propia desc).
function API.GetBackgroundDesc(profileName)
    local data = API.Get(profileName)
    return data.backgroundDesc or ""
end

function API.SetBackgroundDesc(desc, profileName)
    local data = API.Get(profileName)
    data.backgroundDesc = tostring(desc or "")
    Touch(profileName)
    return true
end

local function BackgroundIsFromBook(backgroundId)
    return backgroundId and backgroundId ~= ""
        and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(backgroundId) ~= nil
end

local function SetBackgroundFromIndex(backgroundId, backgroundDesc, profileName)
    backgroundId = tostring(backgroundId or "")
    backgroundDesc = tostring(backgroundDesc or "")
    if backgroundId == "" then
        return API.SetBackground("", profileName)
    end
    API.SetBackground(backgroundId, profileName)
    -- La ficha TRP3 es indice; el libro Harford es la fuente de reglas/texto.
    -- Solo guardamos descripcion TRP3 cuando el trasfondo no existe en el libro.
    if not BackgroundIsFromBook(backgroundId) and backgroundDesc ~= "" then
        API.SetBackgroundDesc(backgroundDesc, profileName)
    end
    return true
end

-- Dotes del perfil: lista de featId. Solo runtime/persistido, sin nivel.
function API.GetFeats(profileName)
    local data = API.Get(profileName)
    return data.feats
end

function API.HasFeat(featId, profileName)
    local data = API.Get(profileName)
    featId = tostring(featId or "")
    for _, id in ipairs(data.feats) do
        if id == featId then return true end
    end
    return false
end

function API.SetFeatEnabled(featId, enabled, profileName)
    local data = API.Get(profileName)
    featId = tostring(featId or "")
    if featId == "" then return false end
    local featDef = HarfordDnDFeats and HarfordDnDFeats.GetFeat and HarfordDnDFeats.GetFeat(featId)
    if featDef then featId = featDef.id end
    -- Quita siempre las ocurrencias previas (evita duplicados).
    for i = #data.feats, 1, -1 do
        if data.feats[i] == featId then table.remove(data.feats, i) end
    end
    if enabled then data.feats[#data.feats + 1] = featId end
    Touch(profileName)
    return true
end

-- Variante de Mana (regla adicional): toggle por perfil. El usuario elige entre
-- maná y espacios de conjuro. Al activarlo, el pool de maná (HarfordDnDMana) se
-- aplica como bonus al maximo del recurso "mana" via HarfordDnDFeatureEffects.
function API.GetUseMana(profileName)
    local data = API.Get(profileName)
    return data.useMana ~= false  -- default ACTIVO: solo false (opt-out explicito) lo desactiva
end

function API.SetUseMana(enabled, profileName)
    local data = API.Get(profileName)
    -- Solo se persiste el opt-out (false); activarlo es el default y queda ausente.
    if enabled then data.useMana = nil else data.useMana = false end
    Touch(profileName)
    return true
end

-- Estados activables por el jugador, declarados por rasgos con `toggleState`.
-- No son checkboxes generales de rasgo: solo aparecen cuando un rasgo desbloqueado
-- declara un estado de combate concreto (transformado, lobo solitario, metamorfosis...).
function API.IsToggleStateActive(stateId, profileName)
    local data = API.Get(profileName)
    stateId = tostring(stateId or "")
    return stateId ~= "" and data.activeStates[stateId] == true
end

function API.SetToggleState(stateId, enabled, profileName)
    local data = API.Get(profileName)
    stateId = tostring(stateId or "")
    if stateId == "" then return false end
    data.activeStates[stateId] = enabled and true or nil
    Touch(profileName)
    return true
end

function API.GetActiveStates(profileName)
    local data = API.Get(profileName)
    return data.activeStates
end

function API.GetImportedProficiencies(profileName)
    local data = API.Get(profileName)
    return data.importedProficiencies or {}
end

function API.GetUnlockedFeatures(profileName)
    local data = API.Get(profileName)
    local out = {}
    -- Rasgos raciales (siempre activos al elegir raza).
    if HarfordDnDRaces and HarfordDnDRaces.GetRaceTraits and data.race and data.race.id ~= "" then
        for _, item in ipairs(HarfordDnDRaces.GetRaceTraits(data.race.id, data.race.subraceId)) do
            out[#out + 1] = item
        end
    end
    -- Rasgos de trasfondo (siempre activos al elegir trasfondo).
    if HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgroundTraits and data.background and data.background ~= "" then
        for _, item in ipairs(HarfordDnDBackgrounds.GetBackgroundTraits(data.background)) do
            out[#out + 1] = item
        end
    end
    -- Rasgos de dotes (siempre activos al elegir el dote).
    if HarfordDnDFeats and HarfordDnDFeats.GetFeatTraits and data.feats and #data.feats > 0 then
        for _, item in ipairs(HarfordDnDFeats.GetFeatTraits(data.feats)) do
            out[#out + 1] = item
        end
    end
    -- Rasgos de clase/subclase.
    if HarfordDnDBook and HarfordDnDBook.GetUnlockedFeatures then
        for _, item in ipairs(HarfordDnDBook.GetUnlockedFeatures(data.classLevels)) do
            out[#out + 1] = item
        end
    end
    return out
end

function API.SeedFromTRP3(profileName)
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile) then return false end
    local profile = HarfordTRP3.GetPlayerProfile("player")
    if not profile then return false end
    local data = API.Get(profileName)
    local importedAny = false

    if not API.HasProgression(profileName) and HarfordDnDBook and HarfordTRP3.GetProfileClassEntries then
        local entries = HarfordTRP3.GetProfileClassEntries(profile)
        if type(entries) == "table" and #entries > 0 then
            local imported = 0
            for i, entry in ipairs(entries) do
                local ok = API.SetClassEntry(i, entry.classId, entry.subclassId, entry.level, profileName)
                if ok then imported = imported + 1 end
            end
            if imported > 0 then importedAny = true end
        end
    end

    if not importedAny and not API.HasProgression(profileName) and HarfordDnDBook then
        local classText = HarfordTRP3.GetProfilePrimaryClass and HarfordTRP3.GetProfilePrimaryClass(profile)
        local levelText = HarfordTRP3.GetProfileLevel and HarfordTRP3.GetProfileLevel(profile)
        local classId = HarfordDnDBook.FindClassIdByText(classText)
        local level = tonumber(levelText)
        if classId and level and level > 0 then
            importedAny = API.SetClassEntry(1, classId, nil, level, profileName) or importedAny
        end
    end

    if data.race and tostring(data.race.id or "") == "" and HarfordTRP3.GetProfileRaceEntry then
        local raceEntry = HarfordTRP3.GetProfileRaceEntry(profile)
        if raceEntry and raceEntry.raceId and raceEntry.raceId ~= "" then
            importedAny = API.SetRace(raceEntry.raceId, raceEntry.subraceId, profileName) or importedAny
        end
    end

    if (tostring(data.background or "") == "" or tostring(data.backgroundDesc or "") == "") and HarfordTRP3.GetProfileBackgroundEntry then
        local bgId, _, bgDesc = HarfordTRP3.GetProfileBackgroundEntry(profile)
        if tostring(data.background or "") == "" and bgId and bgId ~= "" then
            SetBackgroundFromIndex(bgId, bgDesc, profileName)
            importedAny = true
        elseif tostring(data.backgroundDesc or "") == "" and bgDesc and bgDesc ~= "" then
            local current = tostring(data.background or "")
            if not BackgroundIsFromBook(current) and NormalizeText(current) == NormalizeText(bgId or "") then
                API.SetBackgroundDesc(bgDesc, profileName)
                importedAny = true
            end
        end
    end

    return importedAny
end

function API.Export(profileName)
    local data = API.Get(profileName)
    return CopyTable(data)
end

-- Reemplazo DESTRUCTIVO de la progresion con la ficha parseada del TRP3
-- (HarfordTRP3.ParsePlayerSheet). Limpia clases/featureStates/choices/activeStates (todo
-- derivable de clase/raza) y fija clases (orden del About = la 1a clase es la "primera"
-- para el calculo de PG), raza/subraza y trasfondo (id del libro o texto raw como visual).
-- Nombre de match de una opcion de choice: el texto del label antes del primer "(" (ej.
-- "Combate con Dos Armas (...)" -> "combate con dos armas"), normalizado.
local function OptionMatchName(label)
    local head = tostring(label or ""):match("^(.-)%s*%(") or tostring(label or "")
    return NormalizeText(head)
end

local function FeatureMatchNames(feature)
    local names = {}
    local base = NormalizeText(feature and feature.name or "")
    if base ~= "" then
        names[#names + 1] = base
        local beforeOr = base:match("^(.-)%s+o%s+.+$")
        if beforeOr and beforeOr ~= "" then names[#names + 1] = beforeOr end
    end
    return names
end

local function AddUnique(list, value)
    value = tostring(value or "")
    if value == "" then return end
    for _, existing in ipairs(list or {}) do
        if existing == value then return end
    end
    list[#list + 1] = value
end

local function NormalizeAboutHeading(line)
    local text = NormalizeText(line)
    text = text:gsub("^[-%*]+%s*", "")
    text = text:gsub("%b()", "")
    text = text:gsub("[:%.]+$", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local SKILL_SECTION_HEADINGS = {
    habilidades = "skills",
    ["competencia en habilidades"] = "skills",
    ["competencias en habilidades"] = "skills",
    pericia = "expertise",
    pericias = "expertise",
    expertise = "expertise",
}

local ABOUT_CHOICE_BOUNDARIES = {
    clase = true, clases = true, raza = true, subraza = true, trasfondo = true,
    caracteristicas = true, atributos = true, recursos = true, armas = true, arma = true,
    armadura = true, equipo = true, inventario = true, magia = true, conjuros = true,
    hechizos = true, idiomas = true, rasgos = true, ["rasgos de clase"] = true,
    ["tiradas de salvacion"] = true, salvaciones = true, ataques = true, ataque = true,
}

local SAVE_SECTION_HEADINGS = {
    ["tiradas de salvacion"] = true,
    salvaciones = true,
}

local PROF_SECTION_HEADINGS = {
    competencia = true,
    competencias = true,
}

local function GetSkillMatchOptions()
    local options = {}
    for _, skill in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
        local names = {
            NormalizeText(skill.id),
            NormalizeText(skill.name),
            OptionMatchName(skill.name),
        }
        local seen, cleanNames = {}, {}
        for _, name in ipairs(names) do
            if name ~= "" and not seen[name] then
                cleanNames[#cleanNames + 1] = name
                seen[name] = true
            end
        end
        options[#options + 1] = { id = skill.id, names = cleanNames }
    end
    table.sort(options, function(a, b)
        local al, bl = 0, 0
        for _, n in ipairs(a.names or {}) do al = math.max(al, #n) end
        for _, n in ipairs(b.names or {}) do bl = math.max(bl, #n) end
        return al > bl
    end)
    return options
end

local function AddSkillMatchesFromLine(pool, line)
    local text = NormalizeText(line)
    if text == "" then return end
    for _, option in ipairs(GetSkillMatchOptions()) do
        for _, name in ipairs(option.names or {}) do
            if name ~= "" and text:find(name, 1, true) then
                AddUnique(pool, option.id)
                break
            end
        end
    end
end

local function EmptyImportedProficiencies()
    return { skillRank = {}, saveProf = {}, armorProf = {}, weaponProf = {}, toolProf = {} }
end

local function AddMapFlag(map, key)
    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if key ~= "" then map[key] = true end
end

local function MatchAbilityKey(line)
    local text = NormalizeText(line)
    for _, abil in ipairs((HarfordDnDData and HarfordDnDData.ABIL) or {}) do
        if text:find(NormalizeText(abil.key), 1, true) or text:find(NormalizeText(abil.short), 1, true) then
            return abil.key
        end
    end
    return nil
end

local function NormalizeProfLine(line)
    local text = tostring(line or "")
    text = text:gsub("^%s*[-%*]+%s*", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function ImportGeneralProficiency(imported, line)
    local raw = NormalizeProfLine(line)
    local text = NormalizeText(raw)
    if text == "" then return end

    if text:find("armadura", 1, true) or text == "escudo" or text == "escudos" then
        if text:find("ligera", 1, true) then AddMapFlag(imported.armorProf, "ligera") end
        if text:find("media", 1, true) or text:find("intermedia", 1, true) then AddMapFlag(imported.armorProf, "media") end
        if text:find("pesada", 1, true) then AddMapFlag(imported.armorProf, "pesada") end
        if text:find("escudo", 1, true) then AddMapFlag(imported.armorProf, "escudo") end
        return
    end

    local weapon = text:gsub("^armas%s+", "")
    if weapon == "simples" then weapon = "sencillas" end
    if weapon ~= "" and (text:find("arma", 1, true)
        or text:find("espada", 1, true)
        or text:find("ballesta", 1, true)
        or text:find("estoque", 1, true)
        or text:find("florete", 1, true)
        or text:find("pistola", 1, true)
        or text:find("rifle", 1, true)
        or text:find("marcial", 1, true)
        or text:find("sencilla", 1, true)
        or text:find("simple", 1, true)) then
        AddMapFlag(imported.weaponProf, weapon)
        return
    end

    AddMapFlag(imported.toolProf, raw)
end

local function ExtractImportedProficiencies(aboutLines)
    local imported = EmptyImportedProficiencies()
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return imported end

    local section
    for _, line in ipairs(aboutLines) do
        local heading = NormalizeAboutHeading(line)
        if SKILL_SECTION_HEADINGS[heading] == "skills" then
            section = "skills"
        elseif SAVE_SECTION_HEADINGS[heading] then
            section = "saves"
        elseif PROF_SECTION_HEADINGS[heading] then
            section = "profs"
        elseif SKILL_SECTION_HEADINGS[heading] == "expertise" then
            section = "expertise"
        elseif ABOUT_CHOICE_BOUNDARIES[heading] then
            section = nil
        elseif section == "skills" then
            local matches = {}
            AddSkillMatchesFromLine(matches, line)
            for _, skillId in ipairs(matches) do
                imported.skillRank[skillId] = math.max(tonumber(imported.skillRank[skillId]) or 0, 1)
            end
        elseif section == "expertise" then
            local matches = {}
            AddSkillMatchesFromLine(matches, line)
            for _, skillId in ipairs(matches) do
                imported.skillRank[skillId] = math.max(tonumber(imported.skillRank[skillId]) or 0, 2)
            end
            if #matches > 0 then section = nil end
        elseif section == "saves" then
            local ability = MatchAbilityKey(line)
            if ability then imported.saveProf[ability] = true end
        elseif section == "profs" then
            ImportGeneralProficiency(imported, line)
        else
            local normalized = NormalizeText(line)
            if normalized:find("pericia", 1, true) or normalized:find("expertise", 1, true) then
                local matches = {}
                AddSkillMatchesFromLine(matches, line)
                for _, skillId in ipairs(matches) do
                    imported.skillRank[skillId] = math.max(tonumber(imported.skillRank[skillId]) or 0, 2)
                end
            end
        end
    end

    return imported
end

local function ExtractSkillChoicePools(aboutLines)
    local pools = { skillProf = {}, skillExpertise = {} }
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return pools end

    local section
    for _, line in ipairs(aboutLines) do
        local heading = NormalizeAboutHeading(line)
        if SKILL_SECTION_HEADINGS[heading] then
            section = SKILL_SECTION_HEADINGS[heading]
        elseif ABOUT_CHOICE_BOUNDARIES[heading] then
            section = nil
        else
            local normalized = NormalizeText(line)
            if normalized:find("pericia", 1, true) or normalized:find("expertise", 1, true) then
                AddSkillMatchesFromLine(pools.skillExpertise, line)
            elseif section == "expertise" then
                local before = #pools.skillExpertise
                AddSkillMatchesFromLine(pools.skillExpertise, line)
                -- En las fichas TRP3 actuales, "Pericia" es cabecera y la siguiente
                -- linea contiene las habilidades elegidas ("Acrobacias | Sigilo").
                -- Tras capturar esa linea, no seguimos leyendo textos narrativos/conjuros.
                if #pools.skillExpertise > before then section = nil end
            elseif section == "skills" then
                AddSkillMatchesFromLine(pools.skillProf, line)
            end
        end
    end

    return pools
end

local function CollectFixedSkillRanks(profileName)
    local fixed = {}
    if not API.GetUnlockedFeatures then return fixed end
    for _, item in ipairs(API.GetUnlockedFeatures(profileName) or {}) do
        local feature = item and item.feature
        if feature and not (feature.type == "choice" and type(feature.choice) == "table") then
            for _, effect in ipairs(feature.effects or {}) do
                if effect.kind == "skillExpertise" and effect.skill then
                    fixed[effect.skill] = math.max(tonumber(fixed[effect.skill]) or 0, 2)
                elseif effect.kind == "skillProf" and effect.skill then
                    fixed[effect.skill] = math.max(tonumber(fixed[effect.skill]) or 0, 1)
                end
            end
        end
    end
    return fixed
end

local function ChooseOptionsFromPool(feature, pool, slots, used)
    local chosen = {}
    if type(pool) ~= "table" or #pool == 0 then return chosen end
    local byId = {}
    for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
        byId[tostring(opt.id or "")] = opt
    end
    for _, skillId in ipairs(pool) do
        if #chosen >= slots then break end
        if byId[skillId] and not used[skillId] then
            chosen[#chosen + 1] = skillId
            used[skillId] = true
        end
    end
    return chosen
end

-- Resuelve las elecciones (choice) con opciones EXPLICITAS desde el texto del About: por cada
-- rasgo choice desbloqueado, busca la LINEA que contiene el nombre del rasgo (ej. "Estilo de
-- Combate") y dentro de ESA linea matchea el nombre de una opcion (ej. "Gran Arma"). Asi no
-- confunde con otra linea (p.ej. un conjuro llamado "Proteccion"). Los choice de habilidades
-- generados con `optionsFrom` se resuelven desde secciones "Habilidades"/"Pericia"; los ASI
-- NO se resuelven porque sus datos ya vienen horneados en el About (puntuaciones).
local function ResolveChoicesFromAbout(profileName, aboutLines)
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return end
    if not (HarfordDnDBook and HarfordDnDBook.GetChoiceOptions and API.GetUnlockedFeatures) then return end

    local normLines = {}
    for i, l in ipairs(aboutLines) do normLines[i] = NormalizeText(l) end
    local pools = ExtractSkillChoicePools(aboutLines)
    local fixedSkills = CollectFixedSkillRanks(profileName)
    local usedSkillProf, usedSkillExpertise = {}, {}
    for skillId, rank in pairs(fixedSkills) do
        if tonumber(rank) >= 1 then usedSkillProf[skillId] = true end
    end

    for _, item in ipairs(API.GetUnlockedFeatures(profileName) or {}) do
        local feature = item and item.feature
        local choice = feature and feature.choice
        if feature and feature.type == "choice" and type(choice) == "table" then
            local slots = math.max(1, math.floor(tonumber(choice.slots) or 1))
            local featureNames = FeatureMatchNames(feature)
            local chosen, used = {}, {}
            if #featureNames > 0 then
                for lineIndex, ln in ipairs(normLines) do
                    local featureLine = false
                    for _, fname in ipairs(featureNames) do
                        if fname ~= "" and ln:find(fname, 1, true) then
                            featureLine = true
                            break
                        end
                    end
                    if featureLine then
                        local scanLine = ln
                        local nextLine = normLines[lineIndex + 1]
                        if nextLine and nextLine ~= "" then
                            scanLine = scanLine .. " " .. nextLine
                        end
                        local matches = {}
                        for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
                            if not used[opt.id] then
                                -- Probar id normalizado ("gran_arma"->"gran arma") Y nombre del
                                -- label: el About puede escribir el estilo distinto al label del
                                -- libro (ej. "Gran Arma" vs label "Gran Lucha con Armas").
                                local bestPos, bestLen
                                for _, nm in ipairs({ NormalizeText(opt.id), OptionMatchName(opt.label or "") }) do
                                    local pos = (nm ~= "") and scanLine:find(nm, 1, true) or nil
                                    if pos and (not bestLen or #nm > bestLen) then
                                        bestPos, bestLen = pos, #nm
                                    end
                                end
                                if bestPos then
                                    matches[#matches + 1] = { id = opt.id, pos = bestPos, len = bestLen or 0 }
                                end
                            end
                        end
                        table.sort(matches, function(a, b)
                            if a.pos ~= b.pos then return a.pos < b.pos end
                            return a.len > b.len
                        end)
                        for _, match in ipairs(matches) do
                            if not used[match.id] then
                                chosen[#chosen + 1] = match.id
                                used[match.id] = true
                                if choice.optionsFrom == "skillProf" then usedSkillProf[match.id] = true end
                                if choice.optionsFrom == "skillExpertise" then usedSkillExpertise[match.id] = true end
                            end
                            if #chosen >= slots then break end
                        end
                    end
                end
            end
            -- Cabecera suelta: una linea que ES EXACTAMENTE el nombre de una opcion (el About
            -- puede escribir el estilo como su propio h2, ej. "Gran Arma", sin "Estilo de
            -- combate" delante). Solo opciones explicitas; igualdad exacta = sin falsos positivos.
            if #chosen < slots and type(choice.options) == "table" then
                for _, ln in ipairs(normLines) do
                    for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
                        if not used[opt.id] then
                            for _, nm in ipairs({ NormalizeText(opt.id), OptionMatchName(opt.label or "") }) do
                                if nm ~= "" and ln == nm then
                                    chosen[#chosen + 1] = opt.id
                                    used[opt.id] = true
                                    break
                                end
                            end
                        end
                        if #chosen >= slots then break end
                    end
                    if #chosen >= slots then break end
                end
            end
            if #chosen == 0 and choice.optionsFrom == "skillExpertise" then
                chosen = ChooseOptionsFromPool(feature, pools.skillExpertise, slots, usedSkillExpertise)
            elseif #chosen == 0 and choice.optionsFrom == "skillProf" then
                chosen = ChooseOptionsFromPool(feature, pools.skillProf, slots, usedSkillProf)
            end
            for slot, optId in ipairs(chosen) do
                API.SetChoiceSlot(feature.id, slot, optId, profileName)
            end
        end
    end
end

-- Resuelve DOTES desde el About: el perfil marca cada dote con "Dote <Nombre>" (cabecera con
-- {col} Dote{/col} <Nombre>, normalmente en la seccion de raza). Por cada linea que contiene
-- "dote", busca el nombre de dote del libro mas largo presente en esa linea y la activa. Que
-- un PJ tenga dote a nivel 4 implica que NO uso la Mejora de Caracteristica (esa choice queda
-- sin resolver, que es lo correcto: las puntuaciones ya vienen horneadas del About).
local function ResolveFeatsFromAbout(profileName, aboutLines)
    if type(aboutLines) ~= "table" or #aboutLines == 0 then return end
    if not (HarfordDnDFeats and HarfordDnDFeats.GetFeats and API.SetFeatEnabled) then return end
    local feats = HarfordDnDFeats.GetFeats() or {}
    for _, ln0 in ipairs(aboutLines) do
        local ln = NormalizeText(ln0)
        if ln:find("dote", 1, true) then
            local bestId, bestLen
            for _, f in ipairs(feats) do
                local nm = NormalizeText(f.name or "")
                if nm ~= "" and ln:find(nm, 1, true) and (not bestLen or #nm > bestLen) then
                    bestId, bestLen = f.id, #nm
                end
            end
            if bestId then API.SetFeatEnabled(bestId, true, profileName) end
        end
    end
    -- Cabecera suelta SIN marcador "Dote": una linea que ES EXACTAMENTE el nombre de una dote
    -- MULTIPALABRA (p.ej. "Gran Maestro de Armas"). Se exige nombre con espacio para evitar
    -- falsos positivos con dotes de una sola palabra (esas requieren el marcador "Dote").
    for _, ln0 in ipairs(aboutLines) do
        local ln = NormalizeText(ln0)
        for _, f in ipairs(feats) do
            local nm = NormalizeText(f.name or "")
            if nm ~= "" and nm:find(" ", 1, true) and ln == nm then
                API.SetFeatEnabled(f.id, true, profileName)
                break
            end
        end
    end
end

function API.LoadFromTRP3Replace(sheet, profileName)
    if type(sheet) ~= "table" then return false end
    local data = API.Get(profileName)
    data.classLevels = {}
    data.featureStates = {}
    data.choices = {}
    data.activeStates = {}
    data.feats = {}
    data.importedProficiencies = ExtractImportedProficiencies(sheet.aboutLines)

    local idx = 0
    for _, c in ipairs(sheet.classes or {}) do
        idx = idx + 1
        API.SetClassEntry(idx, c.classId, c.subclassId or "", c.level, profileName)
    end

    if sheet.raceId and sheet.raceId ~= "" then
        -- Import TRP3 exacto: si la ficha solo dice "Elfo de la Noche", no forzar la
        -- primera subraza disponible (p.ej. Altonato). La subraza solo se aplica si el
        -- texto TRP3 la nombra de forma explicita.
        data.race = { id = tostring(sheet.raceId or ""), subraceId = tostring(sheet.subraceId or "") }
    else
        data.race = { id = "", subraceId = "" }
    end

    if sheet.background and sheet.background ~= "" then
        SetBackgroundFromIndex(sheet.background, sheet.backgroundDesc, profileName)
    elseif sheet.backgroundRaw and sheet.backgroundRaw ~= "" then
        SetBackgroundFromIndex(sheet.backgroundRaw, sheet.backgroundDesc, profileName)  -- valor visual si no esta en el libro
    else
        API.SetBackground("", profileName)
    end

    -- Con clases/raza/trasfondo ya fijados, resolver desde el texto del About: las elecciones
    -- con opciones explicitas (estilo de combate, afinidades...) y las dotes ("Dote <Nombre>").
    ResolveChoicesFromAbout(profileName, sheet.aboutLines)
    ResolveFeatsFromAbout(profileName, sheet.aboutLines)

    Touch(profileName)
    return true
end

-- Importa una ficha TRP3 como snapshot de inspeccion: NO persiste nada en SavedVariables.
-- Se usa para que calculos remotos (p.ej. resistencias de clase) tengan una lista derivada
-- de efectos sin tener que recorrer los rasgos cada vez que entra dano.
function API.SetInspectDataFromTRP3Sheet(profileName, sheet)
    if type(sheet) ~= "table" then return false end
    profileName = ResolveProfileName(profileName)
    if profileName == "" then return false end

    API.SetInspectData(profileName, EmptyProgression())
    local importedAny = false

    for i, c in ipairs(sheet.classes or {}) do
        local ok = API.SetClassEntry(i, c.classId, c.subclassId or "", c.level, profileName)
        importedAny = ok or importedAny
    end

    local data = API.Get(profileName)
    data.importedProficiencies = ExtractImportedProficiencies(sheet.aboutLines)

    if sheet.raceId and sheet.raceId ~= "" then
        data.race = { id = tostring(sheet.raceId or ""), subraceId = tostring(sheet.subraceId or "") }
        importedAny = true
    end

    if sheet.background and sheet.background ~= "" then
        SetBackgroundFromIndex(sheet.background, sheet.backgroundDesc, profileName)
        importedAny = true
    elseif sheet.backgroundRaw and sheet.backgroundRaw ~= "" then
        SetBackgroundFromIndex(sheet.backgroundRaw, sheet.backgroundDesc, profileName)
        importedAny = true
    end

    ResolveChoicesFromAbout(profileName, sheet.aboutLines)
    ResolveFeatsFromAbout(profileName, sheet.aboutLines)

    if not importedAny then
        API.SetInspectData(profileName, nil)
        return false
    end

    Touch(profileName)
    return true
end

-- Vida maxima por la regla del manual: PG nivel 1 = dado de golpe maximo + Mod. CON de la
-- PRIMERA clase; cada nivel restante (incluido L1 de otras clases) = dado/2+1 + Mod. CON.
function API.ComputeMaxHP(conMod, profileName)
    conMod = tonumber(conMod) or 0
    local levels = API.GetClassLevels(profileName) or {}
    if #levels == 0 then return 0 end
    local hp, totalLevel = 0, 0
    for i, e in ipairs(levels) do
        local def = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(e.classId)
        local die = (def and tonumber(def.hitDie)) or 8
        local lvl = math.max(0, math.floor(tonumber(e.level) or 0))
        for l = 1, lvl do
            totalLevel = totalLevel + 1
            if i == 1 and l == 1 then
                hp = hp + die
            else
                hp = hp + math.floor(die / 2) + 1
            end
        end
    end
    return math.max(1, hp + conMod * totalLevel)
end

function API.Import(profileName, data)
    if type(data) ~= "table" then return false end
    API.Set(profileName, data)
    return true
end

-- ===========================================================================
-- Dados de Golpe (Hit Dice): derivados del nivel/tipo de dado de cada clase.
-- Pool max por tipo de dado = suma de niveles de clases con ese hitDie. Los dados
-- gastados se persisten en HarfordDnDPersistStore.profiles[name]._hitDice.spent (por tipo).
-- ===========================================================================
HarfordDnDHitDice = HarfordDnDHitDice or {}
do
    local HD = HarfordDnDHitDice

    -- Dados de golpe gastados: profiles[name]._hitDice = { spent = { [sides] = n } }.
    local function hitProfiles()
        HarfordDnDPersistStore = HarfordDnDPersistStore or {}
        if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
        return HarfordDnDPersistStore.profiles
    end

    -- Entrada de ESCRITURA: crea la tabla si no existe (solo al gastar).
    local function hitEntry(profileName)
        local profiles = hitProfiles()
        local name = ResolveProfileName(profileName)
        if type(profiles[name]) ~= "table" then profiles[name] = {} end
        local p = profiles[name]
        if type(p._hitDice) ~= "table" then p._hitDice = { spent = {} } end
        if type(p._hitDice.spent) ~= "table" then p._hitDice.spent = {} end
        return p._hitDice
    end

    -- Entrada de LECTURA: NO crea nada (leer no debe generar cruft persistido).
    local function hitEntryRead(profileName)
        local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
        local p = profiles and profiles[ResolveProfileName(profileName)]
        return p and p._hitDice or nil
    end

    -- Si la reserva gastada quedo a 0, elimina la sub-tabla del perfil (no persistir vacios).
    local function hitPruneIfEmpty(profileName)
        local name = ResolveProfileName(profileName)
        local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
        local p = profiles and profiles[name]
        local entry = p and p._hitDice
        if entry then
            for sides, n in pairs(entry.spent or {}) do
                if (tonumber(n) or 0) <= 0 then entry.spent[sides] = nil end
            end
            if not entry.spent or next(entry.spent) == nil then p._hitDice = nil end
        end
    end

    -- Pool maximo por tipo de dado, derivado de las clases (multiclase = varios tipos).
    function HD.GetPoolByDie(profileName)
        local pool = {}
        if HarfordDnDBook and HarfordDnDBook.GetClass then
            for _, e in ipairs(API.GetClassLevels(profileName) or {}) do
                local def = HarfordDnDBook.GetClass(e.classId)
                local sides = def and tonumber(def.hitDie)
                local lvl = tonumber(e.level) or 0
                if sides and lvl > 0 then pool[sides] = (pool[sides] or 0) + lvl end
            end
        end
        return pool
    end

    function HD.GetSpent(profileName)
        local e = hitEntryRead(profileName)
        return (e and e.spent) or {}
    end

    function HD.GetAvailable(profileName)
        local pool, spent, avail = HD.GetPoolByDie(profileName), HD.GetSpent(profileName), {}
        for sides, n in pairs(pool) do
            avail[sides] = math.max(0, n - (tonumber(spent[sides]) or 0))
        end
        return avail
    end

    function HD.GetTotalMax(profileName)
        local t = 0
        for _, n in pairs(HD.GetPoolByDie(profileName)) do t = t + n end
        return t
    end

    function HD.GetTotalAvailable(profileName)
        local t = 0
        for _, n in pairs(HD.GetAvailable(profileName)) do t = t + n end
        return t
    end

    -- Lista ordenada (dado mayor primero) de { sides, max, available }.
    function HD.GetSummaryList(profileName)
        local pool, avail, list = HD.GetPoolByDie(profileName), HD.GetAvailable(profileName), {}
        for sides, n in pairs(pool) do
            list[#list + 1] = { sides = sides, max = n, available = avail[sides] or 0 }
        end
        table.sort(list, function(a, b) return a.sides > b.sides end)
        return list
    end

    -- "3d8 + 2d10 (4 disp.)" para mostrar en la ficha.
    function HD.GetSummaryText(profileName)
        local parts = {}
        for _, e in ipairs(HD.GetSummaryList(profileName)) do
            parts[#parts + 1] = e.max .. "d" .. e.sides
        end
        if #parts == 0 then return "-" end
        return table.concat(parts, " + ") .. " (" .. HD.GetTotalAvailable(profileName) .. " disp.)"
    end

    -- Gasta un dado de un tipo si hay disponible. Devuelve true si gasto.
    function HD.SpendDie(sides, profileName)
        sides = tonumber(sides)
        if not sides then return false end
        if (HD.GetAvailable(profileName)[sides] or 0) <= 0 then return false end
        local entry = hitEntry(profileName)
        entry.spent[sides] = (tonumber(entry.spent[sides]) or 0) + 1
        return true
    end

    -- Descanso largo: recupera floor(total/2) (min 1) dados, de mayor a menor tipo.
    function HD.RegainOnLongRest(profileName)
        local total = HD.GetTotalMax(profileName)
        if total <= 0 then return end
        local regain = math.max(1, math.floor(total / 2))
        local entry = hitEntry(profileName)
        local sidesList = {}
        for sides in pairs(entry.spent) do sidesList[#sidesList + 1] = sides end
        table.sort(sidesList, function(a, b) return a > b end)
        for _, sides in ipairs(sidesList) do
            if regain <= 0 then break end
            local s = tonumber(entry.spent[sides]) or 0
            local take = math.min(s, regain)
            entry.spent[sides] = s - take
            regain = regain - take
        end
        hitPruneIfEmpty(profileName)  -- no persistir entradas a 0
    end
end

-- ===========================================================================
-- Usos de rasgos (Feature Uses): contador ligero para rasgos "X/descanso" cuyo
-- EFECTO no se modela pero el numero de usos si es rastreable (Sentido Divino,
-- Sentir Demonios, Marca de Ursol, Tambaleo, etc.). Solo para el perfil ACTIVO
-- (el max dinamico usa el Mod. de caracteristica via HarfordDnDCalc del jugador).
-- Un rasgo se rastrea declarando `uses = { max=<N|spec>, recharge="short"/"long" }`
-- en HarfordDnDBook/Races/Feats. `max` puede ser un numero fijo o, si es 0/ausente,
-- se calcula como `base + Mod(ability) + perClassLevel*perLevel`, acotado a >= min.
-- Persistencia: HarfordDnDPersistStore.profiles[name]._featureUses[featureId] = gastados.
-- ===========================================================================
HarfordDnDFeatureUses = HarfordDnDFeatureUses or {}
do
    local FU = HarfordDnDFeatureUses

    -- Usos de rasgos gastados: profiles[name]._featureUses = { [featureId] = gastados }.
    local function usesProfiles()
        HarfordDnDPersistStore = HarfordDnDPersistStore or {}
        if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
        return HarfordDnDPersistStore.profiles
    end

    -- Entrada de ESCRITURA (crea si no existe); usar solo al gastar.
    local function usesEntry(profileName)
        local profiles = usesProfiles()
        local name = ResolveProfileName(profileName)
        if type(profiles[name]) ~= "table" then profiles[name] = {} end
        local p = profiles[name]
        if type(p._featureUses) ~= "table" then p._featureUses = {} end
        return p._featureUses
    end

    -- Entrada de LECTURA: NO crea nada (leer no debe generar cruft persistido).
    local function usesEntryRead(profileName)
        local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
        local p = profiles and profiles[ResolveProfileName(profileName)]
        return p and p._featureUses or nil
    end

    -- Resuelve el maximo de usos de un rasgo a partir de su spec `uses`.
    function FU.GetMax(uses, profileName)
        if type(uses) ~= "table" then return 0 end
        if type(uses.max) == "number" then return math.max(0, uses.max) end
        local v = tonumber(uses.base) or 0
        if uses.ability and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
            v = v + (HarfordDnDCalc.GetAbilityMod(uses.ability) or 0)
        end
        if uses.perClassLevel then
            local lvl = 0
            for _, e in ipairs(API.GetClassLevels(profileName) or {}) do
                if e.classId == uses.perClassLevel then lvl = tonumber(e.level) or 0; break end
            end
            v = v + lvl * (tonumber(uses.perLevel) or 1)
        end
        if uses.min then v = math.max(tonumber(uses.min) or 0, v) end
        return math.max(0, v)
    end

    function FU.GetSpent(featureId, profileName)
        local e = usesEntryRead(profileName)
        return (e and tonumber(e[tostring(featureId)])) or 0
    end

    function FU.SetSpent(featureId, value, profileName)
        local v = math.max(0, tonumber(value) or 0)
        local id = tostring(featureId)
        if v > 0 then
            usesEntry(profileName)[id] = v
        else
            -- No persistir ceros (default = sin gastar): elimina la entrada y la tabla del
            -- perfil si queda vacia.
            local e = usesEntryRead(profileName)
            if e then
                e[id] = nil
                if next(e) == nil then
                    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
                    local p = profiles and profiles[ResolveProfileName(profileName)]
                    if p then p._featureUses = nil end
                end
            end
        end
    end

    -- Lista de rasgos rastreables del perfil: { featureId, name, max, spent, available, recharge }.
    function FU.GetTracked(profileName)
        local out = {}
        for _, item in ipairs(API.GetUnlockedFeatures(profileName) or {}) do
            local feature = item and item.feature
            local uses = feature and feature.uses
            if uses and (not API.IsFeatureEnabled or API.IsFeatureEnabled(feature, profileName)) then
                local maxUses = FU.GetMax(uses, profileName)
                if maxUses > 0 then
                    local spent = math.min(FU.GetSpent(feature.id, profileName), maxUses)
                    out[#out + 1] = {
                        featureId = feature.id,
                        name = tostring(feature.name or feature.id),
                        max = maxUses,
                        spent = spent,
                        available = maxUses - spent,
                        recharge = uses.recharge or "long",
                    }
                end
            end
        end
        return out
    end

    -- Gasta 1 uso si queda disponible. Devuelve true si gasto.
    function FU.Spend(featureId, profileName)
        local tracked
        for _, t in ipairs(FU.GetTracked(profileName)) do
            if t.featureId == featureId then tracked = t; break end
        end
        if not tracked or tracked.available <= 0 then return false end
        FU.SetSpent(featureId, tracked.spent + 1, profileName)
        return true
    end

    -- Restaura 1 uso (deshacer). Devuelve true si restauro.
    function FU.Restore(featureId, profileName)
        local spent = FU.GetSpent(featureId, profileName)
        if spent <= 0 then return false end
        FU.SetSpent(featureId, spent - 1, profileName)
        return true
    end

    -- Descanso: "short" recupera los rasgos de recarga "short"; "long" recupera ambos.
    function FU.ResetOnRest(restType, profileName)
        for _, t in ipairs(FU.GetTracked(profileName)) do
            if t.recharge == "short" or restType == "long" then
                FU.SetSpent(t.featureId, 0, profileName)
            end
        end
    end
end
