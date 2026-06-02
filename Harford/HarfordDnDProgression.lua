-- HarfordDnDProgression: estado de clase/subclase/rasgos por perfil.

HarfordDnDProgression = HarfordDnDProgression or {}

local API = HarfordDnDProgression
local SCHEMA_VERSION = 1

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
    local store = HarfordDnDPersistStore or {}
    return tostring(profileName or store.activeProfile or (UnitName and UnitName("player")) or "default")
end

local function EnsureRoot()
    HarfordDnDPersistStore = HarfordDnDPersistStore or {}
    if type(HarfordDnDPersistStore.classProgression) ~= "table" then
        HarfordDnDPersistStore.classProgression = {}
    end
    return HarfordDnDPersistStore.classProgression
end

local function EmptyProgression()
    return {
        schema = SCHEMA_VERSION,
        classLevels = {},
        featureStates = {},
        choices = {},
        race = { id = "", subraceId = "" },
        background = "",
        backgroundDesc = "",  -- descripcion (1er parrafo) de un trasfondo PERSONALIZADO; vacio si es del libro
        feats = {},
        useMana = false,
    }
end

local function Migrate(data)
    if type(data) ~= "table" then data = EmptyProgression() end
    data.schema = tonumber(data.schema) or SCHEMA_VERSION
    if type(data.classLevels) ~= "table" then data.classLevels = {} end
    if type(data.featureStates) ~= "table" then data.featureStates = {} end
    if type(data.choices) ~= "table" then data.choices = {} end
    if type(data.race) ~= "table" then data.race = { id = "", subraceId = "" } end
    data.race.id = tostring(data.race.id or "")
    data.race.subraceId = tostring(data.race.subraceId or "")
    data.background = tostring(data.background or "")
    data.backgroundDesc = tostring(data.backgroundDesc or "")
    if type(data.feats) ~= "table" then data.feats = {} end
    data.useMana = data.useMana == true
    return data
end

local function ClampLevel(level)
    level = math.floor(tonumber(level) or 1)
    if level < 1 then return 1 end
    if level > 20 then return 20 end
    return level
end

function API.Get(profileName)
    local root = EnsureRoot()
    local name = ResolveProfileName(profileName)
    root[name] = Migrate(root[name])
    return root[name], name
end

function API.Set(profileName, data)
    local root = EnsureRoot()
    local name = ResolveProfileName(profileName)
    root[name] = Migrate(CopyTable(data))
    return root[name], name
end

function API.HasProgression(profileName)
    local root = EnsureRoot()
    local data = root[ResolveProfileName(profileName)]
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
        subclassId = subclassId == nil and (HarfordDnDBook.GetDefaultSubclassId(classDef.id) or "") or tostring(subclassId or ""),
        level = ClampLevel(level),
    }
    data.classLevels[index] = entry
    return true, entry
end

function API.RemoveClassEntry(index, profileName)
    local data = API.Get(profileName)
    index = math.floor(tonumber(index) or 0)
    if index < 1 or index > #data.classLevels then return false end
    table.remove(data.classLevels, index)
    return true
end

function API.SetFeatureEnabled(featureId, enabled, profileName)
    local data = API.Get(profileName)
    featureId = tostring(featureId or "")
    if featureId == "" then return false end
    data.featureStates[featureId] = enabled and true or false
    return true
end

function API.IsFeatureEnabled(feature, profileName)
    if not feature or not feature.id then return false end
    local data = API.Get(profileName)
    local value = data.featureStates[feature.id]
    if value ~= nil then return value == true end
    return feature.type == "pasivo" or feature.type == "recurso" or feature.type == "choice"
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
    return true
end

-- Variante de Mana (regla adicional): toggle por perfil. El usuario elige entre
-- maná y espacios de conjuro. Al activarlo, el pool de maná (HarfordDnDMana) se
-- aplica como bonus al maximo del recurso "mana" via HarfordDnDFeatureEffects.
function API.GetUseMana(profileName)
    local data = API.Get(profileName)
    return data.useMana == true
end

function API.SetUseMana(enabled, profileName)
    local data = API.Get(profileName)
    data.useMana = enabled and true or false
    return true
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

    if tostring(data.background or "") == "" and HarfordTRP3.GetProfileBackgroundEntry then
        local bgId, _, bgDesc = HarfordTRP3.GetProfileBackgroundEntry(profile)
        if bgId and bgId ~= "" then
            API.SetBackground(bgId, profileName)
            if bgDesc and bgDesc ~= "" then API.SetBackgroundDesc(bgDesc, profileName) end
            importedAny = true
        end
    end

    return importedAny
end

function API.Export(profileName)
    local data = API.Get(profileName)
    return CopyTable(data)
end

function API.Import(profileName, data)
    if type(data) ~= "table" then return false end
    API.Set(profileName, data)
    return true
end
