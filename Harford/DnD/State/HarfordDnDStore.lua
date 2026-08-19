HarfordDnDStore = HarfordDnDStore or {}

HarfordDnDStore.state = HarfordDnDStore.state or {
    persist = HarfordDnDPersistStore or {},
    runtime = {},
}

HarfordDnDStore.state.persist = HarfordDnDPersistStore or HarfordDnDStore.state.persist or {}
HarfordDnDStore.state.runtime = HarfordDnDStore.state.runtime or {}

function HarfordDnDStore.ToNumber(value, default)
    local number = tonumber(value)
    if number == nil then return default or 0 end
    return number
end

local function ResolveProfileName(profileName, persist)
    return tostring(profileName or (UnitName and UnitName("player")) or "default")
end

local function CopyTable(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = v
    end
    return out
end

local DEFAULT_PROFILE_VALUES = {
    BonusCompetencia = "2",
    BonoSituacional = "0",
    ArmorClass = "10",
    AtributoConjuro = "Inteligencia",
    ModIniciativa = "0",
    ArmaSeleccionada = "Desarmado",
}

-- Claves SOLO de runtime: estado momentaneo de combate/tirada, NO datos de ficha. Nunca se
-- persisten en profiles. Se tratan como "default" en cualquier valor para que SetValue no
-- los guarde y PruneProfileTable limpie los antiguos guardados por versiones previas.
--   Versatil/Offhand = toggles de arma del momento; ModoTirada = ventaja/desventaja de la
--   tirada actual; ModArma = campo legacy retirado de la ficha (ver HarfordDnDCalc).
local RUNTIME_ONLY_KEYS = {
    Versatil = true,
    Offhand = true,
    ModoTirada = true,
    ModArma = true,
}

-- Claves retiradas: Metamorfosis e Imposicion de Manos pasaron de barra de recurso a
-- uso de rasgo. Se borran al podar perfiles heredados para que no queden datos ni
-- sincronizacion obsoletos.
local REMOVED_PROFILE_KEYS = {
    Res_metamorphosis_Cur = true,
    Res_metamorphosis_Max = true,
    Res_lay_on_hands_Cur = true,
    Res_lay_on_hands_Max = true,
}

local DEFAULT_ABILITY_VALUES = {
    Fuerza = "10",
    Destreza = "10",
    Constitucion = "10",
    Inteligencia = "10",
    Sabiduria = "10",
    Carisma = "10",
}

local function IsDefaultProfileValue(key, value, profile)
    key = tostring(key or "")
    value = tostring(value or "")

    if REMOVED_PROFILE_KEYS[key] then
        return true
    end
    if RUNTIME_ONLY_KEYS[key] then
        return true  -- runtime-only: nunca se guarda en el perfil persistido
    end
    if DEFAULT_PROFILE_VALUES[key] ~= nil then
        return value == DEFAULT_PROFILE_VALUES[key]
    end
    if DEFAULT_ABILITY_VALUES[key] ~= nil then
        return value == DEFAULT_ABILITY_VALUES[key]
    end
    if string.match(key, "^Salv_") then
        return value == "0"
    end
    if string.match(key, "^Hab_.+_Prof$") or string.match(key, "^Hab_.+_Exp$") then
        return value == "0"
    end
    local resourceCurrent = string.match(key, "^Res_(.+)_Cur$")
    if resourceCurrent then
        local maxKey = "Res_" .. resourceCurrent .. "_Max"
        local maxValue = type(profile) == "table" and tonumber(profile[maxKey]) or nil
        if maxValue and maxValue > 0 then
            return false
        end
        return value == "0"
    end
    if string.match(key, "^Res_.+_Max$") then
        return value == "0"
    end

    return false
end

local function PruneProfileTable(profile)
    if type(profile) ~= "table" then return 0, true end

    local removed = 0
    for key, value in pairs(profile) do
        if type(value) == "table" then
            -- Sub-tabla estructurada anidada (_progression/_equipment/...): solo se retira
            -- si quedo completamente vacia; nunca se trata como valor plano por defecto.
            if next(value) == nil then
                profile[key] = nil
                removed = removed + 1
            end
        elseif IsDefaultProfileValue(key, value, profile) then
            profile[key] = nil
            removed = removed + 1
        end
    end

    return removed, next(profile) == nil
end

local function HasTableContent(tbl)
    return type(tbl) == "table" and next(tbl) ~= nil
end

local function HasRelatedProfileData(persist, profileName)
    if type(persist) ~= "table" then return false end
    profileName = tostring(profileName or "")

    -- Modelo actual: datos anidados en profiles[name]._x
    local profiles = persist.profiles
    local p = type(profiles) == "table" and profiles[profileName] or nil
    if type(p) == "table" then
        if HasTableContent(p._progression) then return true end
        if HasTableContent(p._equipment) then return true end
        if HasTableContent(p._hitDice) then return true end
        if HasTableContent(p._featureUses) then return true end
    end

    -- Compat: tablas top-level previas a la migracion (tras migrar suelen ser nil).
    if HasTableContent(persist.classProgression and persist.classProgression[profileName]) then return true end
    if HasTableContent(persist.equipment and persist.equipment[profileName]) then return true end
    if HasTableContent(persist.hitDice and persist.hitDice[profileName]) then return true end
    if HasTableContent(persist.featureUses and persist.featureUses[profileName]) then return true end

    return false
end

-- Poda contadores persistidos (hitDice/featureUses): elimina entradas a 0 y tablas de
-- perfil vacias. Tambien retira sub-tablas auxiliares vacias (equipment/classProgression).
-- Leer ya no crea estas tablas, pero esto limpia el cruft guardado por versiones previas.
local function PruneAuxStores(persist)
    local removed = 0

    -- `activeProfile` quedo obsoleto (el perfil es siempre el personaje actual).
    if persist.activeProfile ~= nil then persist.activeProfile = nil; removed = removed + 1 end

    local hitDice = persist.hitDice
    if type(hitDice) == "table" then
        for name, entry in pairs(hitDice) do
            local spent = type(entry) == "table" and entry.spent or nil
            if type(spent) == "table" then
                for sides, n in pairs(spent) do
                    if (tonumber(n) or 0) <= 0 then spent[sides] = nil; removed = removed + 1 end
                end
            end
            if type(spent) ~= "table" or next(spent) == nil then hitDice[name] = nil; removed = removed + 1 end
        end
    end

    local featureUses = persist.featureUses
    if type(featureUses) == "table" then
        for name, entry in pairs(featureUses) do
            if type(entry) == "table" then
                for id, n in pairs(entry) do
                    if (tonumber(n) or 0) <= 0 then entry[id] = nil; removed = removed + 1 end
                end
            end
            if type(entry) ~= "table" or next(entry) == nil then featureUses[name] = nil; removed = removed + 1 end
        end
    end

    for _, key in ipairs({ "equipment", "classProgression" }) do
        local store = persist[key]
        if type(store) == "table" then
            for name, entry in pairs(store) do
                if type(entry) ~= "table" or next(entry) == nil then store[name] = nil; removed = removed + 1 end
            end
        end
    end

    return removed
end

-- Mapa de tablas top-level ANTIGUAS (keyed por nombre) -> sub-clave anidada dentro de
-- profiles[name]. La progresion/equipo/dados/usos ahora viven en profiles[name]._x para
-- que TODO lo de una ficha quede agrupado por perfil en SavedVariables.
local NESTED_PROFILE_KEYS = {
    classProgression = "_progression",
    equipment        = "_equipment",
    hitDice          = "_hitDice",
    featureUses      = "_featureUses",
}
HarfordDnDStore.NESTED_PROFILE_KEYS = NESTED_PROFILE_KEYS

-- Migracion idempotente: mueve las tablas top-level antiguas a profiles[name]._x y borra
-- las top-level. Si ya esta migrado (top-level ausente) no hace nada. No pisa datos
-- anidados existentes (preferimos lo ya migrado).
local function MigrateNestedIntoProfiles(persist)
    if type(persist) ~= "table" then return end
    if type(persist.profiles) ~= "table" then persist.profiles = {} end
    for oldKey, subKey in pairs(NESTED_PROFILE_KEYS) do
        local old = persist[oldKey]
        if type(old) == "table" then
            for name, data in pairs(old) do
                if type(data) == "table" and next(data) ~= nil then
                    if type(persist.profiles[name]) ~= "table" then persist.profiles[name] = {} end
                    if persist.profiles[name][subKey] == nil then
                        persist.profiles[name][subKey] = data
                    end
                end
            end
            persist[oldKey] = nil
        end
    end
end
HarfordDnDStore.MigrateNestedIntoProfiles = MigrateNestedIntoProfiles

local function PrunePersistedProfiles(persist)
    if type(persist) ~= "table" then return 0 end

    MigrateNestedIntoProfiles(persist)

    -- Primero los contadores/aux: asi HasRelatedProfileData refleja el estado limpio y un
    -- perfil cuyo unico "dato relacionado" era cruft a 0 pasa a ser borrable.
    local removed = PruneAuxStores(persist)

    if type(persist.profiles) ~= "table" then
        return removed
    end

    local active = tostring((UnitName and UnitName("player")) or "")
    for profileName, profile in pairs(persist.profiles) do
        local count, empty = PruneProfileTable(profile)
        removed = removed + count
        if empty and tostring(profileName) ~= active and not HasRelatedProfileData(persist, profileName) then
            persist.profiles[profileName] = nil
        end
    end

    return removed
end

function HarfordDnDStore.IsDefaultProfileValue(key, value)
    return IsDefaultProfileValue(key, value)
end

function HarfordDnDStore.PrunePersistedProfiles()
    local state = HarfordDnDStore.state
    state.persist = HarfordDnDPersistStore or state.persist or {}
    local removed = PrunePersistedProfiles(state.persist)
    HarfordDnDPersistStore = state.persist
    return removed
end

function HarfordDnDStore.EnsurePersist(profileName)
    local state = HarfordDnDStore.state
    state.persist = HarfordDnDPersistStore or state.persist or {}

    local resolved = ResolveProfileName(profileName, state.persist)

    state.persist = HarfordSync.EnsureStore(state.persist, resolved)
    HarfordDnDPersistStore = state.persist

    if type(state.runtime) ~= "table" then
        state.runtime = {}
    end

    return state.persist, state.runtime
end

function HarfordDnDStore.LoadPersistToRuntime(profileName)
    local state = HarfordDnDStore.state
    state.persist = HarfordDnDPersistStore or state.persist or {}

    local resolved = ResolveProfileName(profileName, state.persist)

    HarfordDnDStore.EnsurePersist(resolved)

    state.persist = HarfordDnDPersistStore or state.persist or {}

    if type(state.persist.profiles) ~= "table" then
        state.persist.profiles = {}
    end
    PrunePersistedProfiles(state.persist)

    local profile = state.persist.profiles[resolved]
    if type(profile) ~= "table" then
        profile = {}
        state.persist.profiles[resolved] = profile
    end
	
    state.runtime = CopyTable(profile)

    HarfordDnDPersistStore = state.persist

    return state.persist, state.runtime
end

function HarfordDnDStore.GetValue(key, default)
    local state = HarfordDnDStore.state

    if type(state.persist) ~= "table" then
        state.persist = HarfordDnDPersistStore or {}
    end
    if type(state.runtime) ~= "table" then
        state.runtime = {}
    end

    local runtime = state.runtime
    local v = runtime[key]

    if v == nil or v == "" then
        return default
    end

    return v
end

function HarfordDnDStore.SetValue(key, value)
    local state = HarfordDnDStore.state
    local persist = HarfordDnDStore.EnsurePersist()
    local active = ResolveProfileName(nil, persist)

    if type(state.runtime) ~= "table" then
        state.runtime = {}
    end
    state.runtime[key] = tostring(value)

    if type(persist.profiles) ~= "table" then
        persist.profiles = {}
    end
    if type(persist.profiles[active]) ~= "table" then
        persist.profiles[active] = {}
    end
    if IsDefaultProfileValue(key, value, persist.profiles[active]) then
        persist.profiles[active][key] = nil
    else
        persist.profiles[active][key] = tostring(value)
    end

    HarfordDnDPersistStore = persist
    return persist, state.runtime
end

function HarfordDnDStore.SaveCurrentProfileToBank(profileName)
    local state = HarfordDnDStore.state
    local resolved = ResolveProfileName(profileName, state.persist)
    local profileTable = HarfordSync.ReadProfileFromRuntime(state.runtime, HarfordSync.ProfileKeys.DnD)
    HarfordDnDProfileBank = HarfordSync.SaveProfileToBank(HarfordDnDProfileBank, resolved, profileTable)
    return profileTable
end

function HarfordDnDStore.ApplyProfileTable(tbl, profileName, allResourceKeys, curKeyFn, maxKeyFn, ensureDefaultsFn, refreshFn)
    if type(tbl) ~= "table" then return false end

    local state = HarfordDnDStore.state
    local active = ResolveProfileName(profileName, state.persist)
    HarfordDnDStore.EnsurePersist(active)

    if type(state.persist.profiles) ~= "table" then
        state.persist.profiles = {}
    end

    -- Preservar las sub-tablas estructuradas (progresion/equipo/dados/usos) del perfil
    -- anterior: este perfil se RECONSTRUYE desde los recursos planos entrantes ("Enviar
    -- ficha"/import) y, sin esto, borraria la progresion y el equipo anidados.
    local prev = state.persist.profiles[active]
    local preserved = {}
    if type(prev) == "table" then
        for _, subKey in pairs(NESTED_PROFILE_KEYS) do
            preserved[subKey] = prev[subKey]
        end
    end

    local newProfile = {}
    for k, v in pairs(tbl) do
        -- Solo claves planas (string): nunca volcamos sub-tablas como texto.
        if v ~= nil and type(v) ~= "table" and not IsDefaultProfileValue(k, v, tbl) then
            newProfile[k] = tostring(v)
        end
    end

    for _, resourceKey in ipairs(allResourceKeys or {}) do
        local maxKey = maxKeyFn(resourceKey)
        local curKey = curKeyFn(resourceKey)
        local maxValue = tonumber(newProfile[maxKey]) or 0
        local curValue = tonumber(newProfile[curKey])
        if maxValue > 0 and resourceKey ~= "temp_health" and curValue and curValue > maxValue then
            newProfile[curKey] = tostring(maxValue)
        end
    end

	state.persist.profiles[active] = newProfile
	state.runtime = CopyTable(newProfile)  -- runtime PLANO (sin sub-tablas anidadas)
	-- Re-anexar las sub-tablas SOLO al perfil persistido (no a runtime).
	for subKey, subVal in pairs(preserved) do
		if subVal ~= nil then newProfile[subKey] = subVal end
	end
	HarfordDnDPersistStore = state.persist

    if ensureDefaultsFn then ensureDefaultsFn() end
    if refreshFn then refreshFn() end
    return true
end

HarfordDnDStore.PrunePersistedProfiles()

-- Fusiona claves específicas en el perfil existente sin reemplazarlo por completo.
-- Usado para aplicar los flags Hab_X_Prof/Exp llegados via DNDPROF sin destruir
-- los atributos/salvaciones que ya aplicó el mensaje DNDCFG previo.
function HarfordDnDStore.MergeProfileKeys(tbl, profileName, ensureDefaultsFn, refreshFn)
    if type(tbl) ~= "table" then return false end
    local state  = HarfordDnDStore.state
    local active = ResolveProfileName(profileName, state.persist)
    HarfordDnDStore.EnsurePersist(active)

    local profile = state.persist.profiles[active]
    if type(profile) ~= "table" then
        profile = {}
        state.persist.profiles[active] = profile
    end

    for k, v in pairs(tbl) do
        if v ~= nil then
            if IsDefaultProfileValue(k, v, profile) then
                profile[k] = nil
            else
                profile[k] = tostring(v)
            end
        end
    end

    state.runtime = CopyTable(profile)
    HarfordDnDPersistStore = state.persist

    if ensureDefaultsFn then ensureDefaultsFn() end
    if refreshFn        then refreshFn()        end
    return true
end

function HarfordDnDStore.ApplyResourceConfigTable(tbl, profileName, allResourceKeys, curKeyFn, maxKeyFn, ensureDefaultsFn, refreshFn)
    if type(tbl) ~= "table" then return false end

    local state = HarfordDnDStore.state
    local active = ResolveProfileName(profileName, state.persist)
    HarfordDnDStore.EnsurePersist(active)

    if type(state.persist.profiles) ~= "table" then
        state.persist.profiles = {}
    end

    local profile = state.persist.profiles[active]
    if type(profile) ~= "table" then
        profile = {}
        state.persist.profiles[active] = profile
    end

    for _, resourceKey in ipairs(allResourceKeys or {}) do
        local maxKey = maxKeyFn(resourceKey)
        local curKey = curKeyFn(resourceKey)
        if tbl[maxKey] ~= nil then
            local maxValue = tonumber(tbl[maxKey]) or 0
            if maxValue > 0 then
                profile[maxKey] = tostring(maxValue)
                if resourceKey ~= "temp_health" then
                    local curValue = tonumber(profile[curKey])
                    if curValue and curValue > maxValue then
                        profile[curKey] = tostring(maxValue)
                    end
                end
            else
                profile[maxKey] = nil
                profile[curKey] = nil
            end
        end
    end

	state.runtime = CopyTable(profile)
	HarfordDnDPersistStore = state.persist
	
    if ensureDefaultsFn then ensureDefaultsFn() end
    if refreshFn then refreshFn() end
    return true
end
