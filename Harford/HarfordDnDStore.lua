HarfordDnDStore = HarfordDnDStore or {}

HarfordDnDStore.state = HarfordDnDStore.state or {
    persist = HarfordDnDPersistStore or {},
    runtime = {},
}

HarfordDnDStore.state.persist = HarfordDnDPersistStore or HarfordDnDStore.state.persist or {}
HarfordDnDStore.state.runtime = HarfordDnDStore.state.runtime or {}

local function ResolveProfileName(profileName, persist)
    return tostring(profileName or (persist and persist.activeProfile) or (UnitName and UnitName("player")) or "default")
end

local function CopyTable(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = v
    end
    return out
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
    state.persist.activeProfile = resolved

    if type(state.persist.profiles) ~= "table" then
        state.persist.profiles = {}
    end

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
    persist.profiles[active][key] = tostring(value)

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
    state.persist.activeProfile = active

    if type(state.persist.profiles) ~= "table" then
        state.persist.profiles = {}
    end

    local newProfile = {}
    for k, v in pairs(tbl) do
        if v ~= nil then newProfile[k] = tostring(v) end
    end

    for _, resourceKey in ipairs(allResourceKeys or {}) do
        local maxKey = maxKeyFn(resourceKey)
        local curKey = curKeyFn(resourceKey)
        local maxValue = tonumber(newProfile[maxKey]) or 0
        newProfile[curKey] = resourceKey == "temp_health" and "0" or tostring(maxValue)
    end

	state.persist.profiles[active] = newProfile
	state.runtime = CopyTable(state.persist.profiles[active])
	HarfordDnDPersistStore = state.persist

    if ensureDefaultsFn then ensureDefaultsFn() end
    if refreshFn then refreshFn() end
    return true
end

-- Fusiona claves específicas en el perfil existente sin reemplazarlo por completo.
-- Usado para aplicar los flags Hab_X_Prof/Exp llegados via DNDPROF sin destruir
-- los atributos/salvaciones que ya aplicó el mensaje DNDCFG previo.
function HarfordDnDStore.MergeProfileKeys(tbl, profileName, ensureDefaultsFn, refreshFn)
    if type(tbl) ~= "table" then return false end
    local state  = HarfordDnDStore.state
    local active = ResolveProfileName(profileName, state.persist)
    HarfordDnDStore.EnsurePersist(active)
    state.persist.activeProfile = active

    local profile = state.persist.profiles[active]
    if type(profile) ~= "table" then
        profile = {}
        state.persist.profiles[active] = profile
    end

    for k, v in pairs(tbl) do
        if v ~= nil then
            profile[k] = tostring(v)
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
    state.persist.activeProfile = active

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
            profile[maxKey] = tostring(maxValue)
            profile[curKey] = resourceKey == "temp_health" and "0" or tostring(maxValue)
        end
    end

	state.runtime = CopyTable(profile)
	HarfordDnDPersistStore = state.persist
	
    if ensureDefaultsFn then ensureDefaultsFn() end
    if refreshFn then refreshFn() end
    return true
end
