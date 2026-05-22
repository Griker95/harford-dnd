HarfordSync = HarfordSync or {}

HarfordSync.MAX_RESOURCE_MESSAGE_BYTES = HarfordSync.MAX_RESOURCE_MESSAGE_BYTES or 240
HarfordSync.RESOURCE_ENCODING_MARKER = HarfordSync.RESOURCE_ENCODING_MARKER or "~"

HarfordSync.ProfileKeys = HarfordSync.ProfileKeys or {}
HarfordSync.ResourceKeys = HarfordSync.ResourceKeys or {}

HarfordSync.ProfileKeys.DnD = {
    "BonusCompetencia",
    "AtributoConjuro",
    "ModIniciativa",

    "Fuerza",
    "Destreza",
    "Constitucion",
    "Inteligencia",
    "Sabiduria",
    "Carisma",

    "Salv_Fuerza",
    "Salv_Destreza",
    "Salv_Constitucion",
    "Salv_Inteligencia",
    "Salv_Sabiduria",
    "Salv_Carisma",

    "Hab_Acrobacias_Prof", "Hab_Acrobacias_Exp",
    "Hab_Atletismo_Prof", "Hab_Atletismo_Exp",
    "Hab_Arcano_Prof", "Hab_Arcano_Exp",
    "Hab_Engano_Prof", "Hab_Engano_Exp",
    "Hab_Historia_Prof", "Hab_Historia_Exp",
    "Hab_Interpretacion_Prof", "Hab_Interpretacion_Exp",
    "Hab_Intimidacion_Prof", "Hab_Intimidacion_Exp",
    "Hab_Investigacion_Prof", "Hab_Investigacion_Exp",
    "Hab_JuegoManos_Prof", "Hab_JuegoManos_Exp",
    "Hab_Medicina_Prof", "Hab_Medicina_Exp",
    "Hab_Naturaleza_Prof", "Hab_Naturaleza_Exp",
    "Hab_Percepcion_Prof", "Hab_Percepcion_Exp",
    "Hab_Perspicacia_Prof", "Hab_Perspicacia_Exp",
    "Hab_Persuasion_Prof", "Hab_Persuasion_Exp",
    "Hab_Religion_Prof", "Hab_Religion_Exp",
    "Hab_Sigilo_Prof", "Hab_Sigilo_Exp",
    "Hab_Supervivencia_Prof", "Hab_Supervivencia_Exp",
    "Hab_Animales_Prof", "Hab_Animales_Exp",
}

HarfordSync.ResourceKeys.Runtime = HarfordSync.ResourceKeys.Runtime or {
    "Res_health_Cur", "Res_health_Max", "Res_mana_Cur", "Res_mana_Max", "Res_temp_health_Cur", "Res_temp_health_Max",
    "Res_chi_Cur", "Res_chi_Max", "Res_energy_Cur", "Res_energy_Max", "Res_fel_point_Cur", "Res_fel_point_Max",
    "Res_focus_Cur", "Res_focus_Max", "Res_holy_power_Cur", "Res_holy_power_Max", "Res_light_point_Cur", "Res_light_point_Max",
    "Res_mage_point_Cur", "Res_mage_point_Max", "Res_rage_Cur", "Res_rage_Max", "Res_runic_power_Cur", "Res_runic_power_Max",
    "Res_soul_shard_Cur", "Res_soul_shard_Max", "Res_astral_power_Cur", "Res_astral_power_Max", "Res_living_seeds_Cur", "Res_living_seeds_Max",
}

HarfordSync.ResourceKeys.Config = HarfordSync.ResourceKeys.Config or {
    "Res_health_Max", "Res_mana_Max", "Res_temp_health_Max", "Res_chi_Max", "Res_energy_Max",
    "Res_fel_point_Max", "Res_focus_Max", "Res_holy_power_Max", "Res_light_point_Max", "Res_mage_point_Max",
    "Res_rage_Max", "Res_runic_power_Max", "Res_soul_shard_Max", "Res_astral_power_Max", "Res_living_seeds_Max",
}

local function ToBase36(n)
    return string.format("%x", tonumber(n) or 0)
end

local function BuildResourceCodeMaps(keyOrder)
    local keyToCode = {}
    local codeToKey = {}
    for i, key in ipairs(keyOrder or {}) do
        local code = ToBase36(i - 1)
        keyToCode[key] = code
        codeToKey[code] = key
    end
    return keyToCode, codeToKey
end

HarfordSync.ResourceKeyToCodeRuntime, HarfordSync.ResourceCodeToKeyRuntime = BuildResourceCodeMaps(HarfordSync.ResourceKeys.Runtime)
HarfordSync.ResourceKeyToCodeConfig, HarfordSync.ResourceCodeToKeyConfig = BuildResourceCodeMaps(HarfordSync.ResourceKeys.Config)

function HarfordSync.RegisterPrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
end

function HarfordSync.Send(prefix, message, channel, target)
    if not prefix or prefix == "" then
        return false, "Prefix invalido"
    end
    if not channel or channel == "" then
        return false, "Sin canal disponible"
    end
    if channel == "WHISPER" and (not target or target == "") then
        return false, "WHISPER requiere target"
    end

    local ok, result
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        ok, result = pcall(C_ChatInfo.SendAddonMessage, prefix, message or "", channel, target)
    elseif SendAddonMessage then
        ok, result = pcall(SendAddonMessage, prefix, message or "", channel, target)
    else
        return false, "SendAddonMessage no disponible"
    end

    if not ok then
        return false, result
    end
    if result == false then
        return false, "SendAddonMessage devolvio false"
    end
    return true
end

function HarfordSync.BestChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

function HarfordSync.CopyTableShallow(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = v
    end
    return out
end

local function DebugLog(...)
    if HarfordDebug and HarfordDebug.Log then
        HarfordDebug.Log(...)
    end
end

local function CountKeys(tbl)
    local n = 0
    for _ in pairs(tbl or {}) do
        n = n + 1
    end
    return n
end

local function CountProfiles(store)
    return CountKeys(store and store.profiles)
end

local function NormalizeProfileName(profileName)
    local raw = tostring(profileName or "")
    if raw == "" then
        return "default"
    end

    local short = raw:match("^[^-]+")
    if short and short ~= "" then
        return short
    end

    return raw
end

function HarfordSync.EnsureStore(store, activeProfileName)
    if type(store) ~= "table" then
        store = {}
    end

    local resolvedProfile = tostring(activeProfileName or store.activeProfile or (UnitName and UnitName("player")) or "default")

    if type(store.profiles) ~= "table" then
        store.profiles = {}
    end

    store.activeProfile = resolvedProfile

    if type(store.profiles[resolvedProfile]) ~= "table" then
        store.profiles[resolvedProfile] = {}
    end

    store.values = nil

    return store
end

function HarfordSync.LoadStoreRuntime(store, activeProfileName)
    local resolvedProfile = tostring(activeProfileName or (UnitName and UnitName("player")) or "default")

    store = HarfordSync.EnsureStore(store, resolvedProfile)

    store.activeProfile = resolvedProfile

    if type(store.profiles[resolvedProfile]) ~= "table" then
        store.profiles[resolvedProfile] = {}
    end

    return store, HarfordSync.CopyTableShallow(store.profiles[resolvedProfile])
end

function HarfordSync.GetValue(store, key, default)
    store = HarfordSync.EnsureStore(store)

    local active = tostring(store.activeProfile or (UnitName and UnitName("player")) or "default")
    local profile = (store.profiles and store.profiles[active]) or {}
    local v = profile[key]

    if v == nil or v == "" then
        return default
    end
    return v
end

function HarfordSync.SetValue(store, key, value)
    store = HarfordSync.EnsureStore(store, store and store.activeProfile)

    local active = tostring(store.activeProfile or (UnitName and UnitName("player")) or "default")

    if type(store.profiles) ~= "table" then
        store.profiles = {}
    end

    if type(store.profiles[active]) ~= "table" then
        store.profiles[active] = {}
    end

    store.profiles[active][key] = tostring(value)

    return store, store.profiles[active]
end

function HarfordSync.ReadProfileFromRuntime(runtimeTable, keys)
    local out = {}
    for _, key in ipairs(keys or {}) do
        local v = runtimeTable and runtimeTable[key]
        if v ~= nil then
            out[key] = tostring(v)
        end
    end
    return out
end

function HarfordSync.WriteProfileToRuntime(runtimeTable, profileTable, keys)
    runtimeTable = runtimeTable or {}
    for _, key in ipairs(keys or {}) do
        if profileTable[key] ~= nil then
            runtimeTable[key] = tostring(profileTable[key])
        end
    end
    return runtimeTable
end

function HarfordSync.SaveProfileToBank(bank, profileName, profileTable)
    bank = bank or {}
    bank[tostring(profileName)] = HarfordSync.CopyTableShallow(profileTable or {})
    return bank
end

function HarfordSync.LoadProfileFromBank(bank, profileName)
    if not bank then return nil end
    local tbl = bank[tostring(profileName)]
    if not tbl then return nil end
    return HarfordSync.CopyTableShallow(tbl)
end

function HarfordSync.SerializeKeyValueTable(tbl, keys)
    local parts = {}
    for _, key in ipairs(keys or {}) do
        local v = tbl and tbl[key]
        if v ~= nil then
            parts[#parts + 1] = key .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, ";")
end

function HarfordSync.DeserializeKeyValueTable(raw)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    for pairStr in string.gmatch(raw, "([^;]+)") do
        local eqPos = string.find(pairStr, "=", 1, true)
        if eqPos then
            local key = string.sub(pairStr, 1, eqPos - 1)
            local value = string.sub(pairStr, eqPos + 1)
            if key and key ~= "" then
                tbl[key] = value
            end
        end
    end

    return tbl
end

function HarfordSync.SerializeProfileMessage(opcode, profileName, profileTable, keys)
    opcode = tostring(opcode or "CFG")
    profileName = tostring(profileName or "default")
    local raw = HarfordSync.SerializeKeyValueTable(profileTable or {}, keys or {})
    return opcode .. "|" .. profileName .. "|" .. raw
end

function HarfordSync.DeserializeProfileMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil, nil
    end

    local firstSep = string.find(message, "|", 1, true)
    if not firstSep then return nil, nil, nil end

    local secondSep = string.find(message, "|", firstSep + 1, true)
    if not secondSep then return nil, nil, nil end

    local opcode = string.sub(message, 1, firstSep - 1)
    local profileName = string.sub(message, firstSep + 1, secondSep - 1)
    local raw = string.sub(message, secondSep + 1)

    if opcode == "" or profileName == "" then
        return nil, nil, nil
    end

    return opcode, profileName, HarfordSync.DeserializeKeyValueTable(raw)
end

function HarfordSync.SendProfile(prefix, opcode, profileName, profileTable, keys, channel, target)
    local ch = channel or HarfordSync.BestChannel()
    if not ch then
        return false, "Sin canal disponible"
    end

    local payload = HarfordSync.SerializeProfileMessage(opcode, profileName, profileTable, keys)
    HarfordSync.Send(prefix, payload, ch, target)
    return true
end

function HarfordSync.SendDnDProfile(prefix, profileName, profileTable, channel, target)
    return HarfordSync.SendProfile(
        prefix,
        "DNDCFG",
        profileName,
        profileTable,
        HarfordSync.ProfileKeys.DnD,
        channel,
        target
    )
end

function HarfordSync.ReceiveDnDProfile(message)
    local opcode, profileName, tbl = HarfordSync.DeserializeProfileMessage(message)
    if opcode ~= "DNDCFG" then
        return nil, nil
    end
    return profileName, tbl
end

function HarfordSync.BroadcastProfiles(prefix, opcode, bank, keys, channel, target)
    local ch = channel or HarfordSync.BestChannel()
    if not ch then
        return false, "Sin canal disponible"
    end

    local count = 0
    for profileName, tbl in pairs(bank or {}) do
        local payload = HarfordSync.SerializeProfileMessage(opcode, profileName, tbl, keys)
        HarfordSync.Send(prefix, payload, ch, target)
        count = count + 1
    end

    return true, count
end

local function DefaultCurKey(resourceKey)
    return "Res_" .. tostring(resourceKey) .. "_Cur"
end

local function DefaultMaxKey(resourceKey)
    return "Res_" .. tostring(resourceKey) .. "_Max"
end

function HarfordSync.IsResourceEntryActive(resourceKey, curValue, maxValue, activityMode)
    local maxNum = tonumber(maxValue) or 0
    local curNum = tonumber(curValue) or 0

    if activityMode == "max" then
        return maxNum > 0
    end

    if resourceKey == "temp_health" then
        return curNum > 0
    end

    return maxNum > 0
end

function HarfordSync.BuildActiveResourcePayloadFromStore(readValueFn, resourceOrder, options)
    local out = {}
    local keysToSend = {}
    options = options or {}

    local includeInactive = options.includeInactive == true
    local includeCurrent = options.includeCurrent ~= false
    local includeMax = options.includeMax ~= false
    local activityMode = options.activityMode or "runtime"
    local makeCurKey = options.makeCurKey or DefaultCurKey
    local makeMaxKey = options.makeMaxKey or DefaultMaxKey

    for _, resourceKey in ipairs(resourceOrder or {}) do
        local curKey = makeCurKey(resourceKey)
        local maxKey = makeMaxKey(resourceKey)
        local curVal = tostring((readValueFn and readValueFn(curKey)) or "0")
        local maxVal = tostring((readValueFn and readValueFn(maxKey)) or "0")
        local isActive = HarfordSync.IsResourceEntryActive(resourceKey, curVal, maxVal, activityMode)

        if includeInactive or isActive then
            if includeCurrent then
                out[curKey] = curVal
                keysToSend[#keysToSend + 1] = curKey
            end
            if includeMax then
                out[maxKey] = maxVal
                keysToSend[#keysToSend + 1] = maxKey
            end
        end
    end

    return out, keysToSend
end

function HarfordSync.BuildActiveResourcePayloadFromTable(sourceTable, resourceOrder, options)
    return HarfordSync.BuildActiveResourcePayloadFromStore(function(key)
        return sourceTable and sourceTable[key]
    end, resourceOrder, options)
end

function HarfordSync.SerializeResourceTable(profileTable, resourceKeys)
    return HarfordSync.SerializeKeyValueTable(profileTable, resourceKeys)
end

function HarfordSync.DeserializeResourceTable(raw)
    return HarfordSync.DeserializeKeyValueTable(raw)
end

function HarfordSync.SerializeResourceRequestMessage(requesterName)
    return "DNDRESREQ|" .. tostring(requesterName or "")
end

function HarfordSync.DeserializeResourceRequestMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil
    end

    local opcode, requesterName = strsplit("|", message)
    if opcode ~= "DNDRESREQ" then
        return nil
    end

    if not requesterName or requesterName == "" then
        return nil
    end

    return requesterName
end

function HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.SerializeResourceMessageWithLimit(
        "DNDRES",
        profileName,
        resourceTable,
        resourceKeys,
        HarfordSync.MAX_RESOURCE_MESSAGE_BYTES
    )
end

function HarfordSync.SerializeResourceConfigMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.SerializeResourceMessageWithLimit(
        "DNDRESCFG",
        profileName,
        resourceTable,
        resourceKeys,
        HarfordSync.MAX_RESOURCE_MESSAGE_BYTES
    )
end

function HarfordSync.SerializeResourceMessageWithLimit(opcode, profileName, resourceTable, resourceKeys, maxBytes)
    opcode = tostring(opcode or "DNDRES")
    profileName = tostring(profileName or "")
    local header = opcode .. "|" .. profileName .. "|"
    local limit = tonumber(maxBytes) or HarfordSync.MAX_RESOURCE_MESSAGE_BYTES or 240

    if #header >= limit then
        return header
    end

    local out = {}
    local used = #header
    local marker = HarfordSync.RESOURCE_ENCODING_MARKER or "~"
    local keyToCode = (opcode == "DNDRESCFG" and HarfordSync.ResourceKeyToCodeConfig) or HarfordSync.ResourceKeyToCodeRuntime
    for _, key in ipairs(resourceKeys or {}) do
        local value = resourceTable and resourceTable[key]
        if value ~= nil then
            local keyCode = keyToCode and keyToCode[key]
            local encodedKey = keyCode or tostring(key)
            local token = encodedKey .. "=" .. tostring(value)
            local tokenLen = #token
            if #out > 0 then
                tokenLen = tokenLen + 1
            else
                tokenLen = tokenLen + #marker
            end

            if used + tokenLen <= limit then
                out[#out + 1] = token
                used = used + tokenLen
            else
                break
            end
        end
    end

    if #out == 0 then
        return header
    end

    return header .. marker .. table.concat(out, ",")
end

local function DeserializeCompactResourceTable(raw, codeToKey)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    local marker = HarfordSync.RESOURCE_ENCODING_MARKER or "~"
    if string.sub(raw, 1, #marker) ~= marker then
        return HarfordSync.DeserializeResourceTable(raw)
    end

    local compactRaw = string.sub(raw, #marker + 1)
    for pairStr in string.gmatch(compactRaw, "([^,]+)") do
        local eqPos = string.find(pairStr, "=", 1, true)
        if eqPos then
            local code = string.sub(pairStr, 1, eqPos - 1)
            local value = string.sub(pairStr, eqPos + 1)
            local key = codeToKey and codeToKey[code]
            if key and key ~= "" then
                tbl[key] = value
            end
        end
    end

    return tbl
end

function HarfordSync.DeserializeResourceResponseMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil
    end

    local firstSep = string.find(message, "|", 1, true)
    if not firstSep then return nil, nil end

    local secondSep = string.find(message, "|", firstSep + 1, true)
    if not secondSep then return nil, nil end

    local opcode = string.sub(message, 1, firstSep - 1)
    local profileName = string.sub(message, firstSep + 1, secondSep - 1)
    local raw = string.sub(message, secondSep + 1)

    if opcode ~= "DNDRES" or profileName == "" then
        return nil, nil
    end

    return profileName, DeserializeCompactResourceTable(raw, HarfordSync.ResourceCodeToKeyRuntime)
end

function HarfordSync.DeserializeResourceConfigMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil
    end

    local firstSep = string.find(message, "|", 1, true)
    if not firstSep then return nil, nil end

    local secondSep = string.find(message, "|", firstSep + 1, true)
    if not secondSep then return nil, nil end

    local opcode = string.sub(message, 1, firstSep - 1)
    local profileName = string.sub(message, firstSep + 1, secondSep - 1)
    local raw = string.sub(message, secondSep + 1)

    if opcode ~= "DNDRESCFG" or profileName == "" then
        return nil, nil
    end

    return profileName, DeserializeCompactResourceTable(raw, HarfordSync.ResourceCodeToKeyConfig)
end

function HarfordSync.ReceiveResourceMessage(message)
    local requesterName = HarfordSync.DeserializeResourceRequestMessage(message)
    if requesterName then
        return "REQ", requesterName, nil
    end

    local profileName, resourceTable = HarfordSync.DeserializeResourceResponseMessage(message)
    if profileName and resourceTable then
        return "RES", profileName, resourceTable
    end

    return nil, nil, nil
end

function HarfordSync.SerializeResourceAdjustMessage(resourceKey, delta)
    local key = tostring(resourceKey or "")
    local amount = tonumber(delta) or 0
    if key == "" or amount == 0 then
        return nil
    end
    if not key:match("^[%w_%-]+$") then
        return nil
    end
    return "RADJ|" .. key .. "|" .. tostring(math.floor(amount))
end

function HarfordSync.DeserializeResourceAdjustMessage(message)
    local opcode, key, delta = strsplit("|", tostring(message or ""))
    if opcode ~= "RADJ" then
        return nil, nil
    end
    delta = tonumber(delta)
    if not key or key == "" or not key:match("^[%w_%-]+$") or not delta or delta == 0 then
        return nil, nil
    end
    return key, math.floor(delta)
end

function HarfordSync.SendResourceAdjust(prefix, resourceKey, delta, target)
    if not target or target == "" then
        return false, "Target invÃ¡lido"
    end

    local payload = HarfordSync.SerializeResourceAdjustMessage(resourceKey, delta)
    if not payload then
        return false, "Ajuste de recurso invÃ¡lido"
    end

    HarfordSync.Send(prefix, payload, "WHISPER", target)
    return true
end

function HarfordSync.SendResourceRequest(prefix, requesterName, target)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceRequestMessage(requesterName)
    HarfordSync.Send(prefix, payload, "WHISPER", target)
    return true
end

function HarfordSync.SendResourceResponse(prefix, profileName, resourceTable, target, resourceKeys)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)
    HarfordSync.Send(prefix, payload, "WHISPER", target)
    return true
end

function HarfordSync.SendResourceConfig(prefix, profileName, resourceTable, target, resourceKeys)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceConfigMessage(profileName, resourceTable, resourceKeys)
    HarfordSync.Send(prefix, payload, "WHISPER", target)
    return true
end

function HarfordSync.ReceiveResourceConfig(message)
    return HarfordSync.DeserializeResourceConfigMessage(message)
end

HarfordSync._resourceBroadcastState = HarfordSync._resourceBroadcastState or {
    pending = false,
    lastPayload = nil,
}

function HarfordSync.SendResourceBroadcast(prefix, profileName, resourceTable, resourceKeys, channel)
    local ch = channel or HarfordSync.BestChannel()
    if ch ~= "RAID" and ch ~= "PARTY" then
        return false, "Sin canal de grupo"
    end

    local payload = HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)
    HarfordSync.Send(prefix, payload, ch)
    return true
end

function HarfordSync.ScheduleResourceBroadcast(prefix, profileNameProvider, resourceTableProvider, resourceKeys, channelProvider)
    HarfordSync._resourceBroadcastState = HarfordSync._resourceBroadcastState or {
        pending = false,
        lastPayload = nil,
    }

    local state = HarfordSync._resourceBroadcastState

    local initialChannel = channelProvider and channelProvider() or HarfordSync.BestChannel()
    if initialChannel ~= "RAID" and initialChannel ~= "PARTY" then
        return false, "Sin canal de grupo"
    end

    if state.pending then
        return true
    end

    state.pending = true

    C_Timer.After(0.20, function()
        state.pending = false

        local finalChannel = channelProvider and channelProvider() or HarfordSync.BestChannel()
        if finalChannel ~= "RAID" and finalChannel ~= "PARTY" then
            return
        end

        local profileName = profileNameProvider and profileNameProvider() or "default"
        local resourceTable = resourceTableProvider and resourceTableProvider() or {}
        local payload = HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)

        if payload == state.lastPayload then
            return
        end

        state.lastPayload = payload
        HarfordSync.Send(prefix, payload, finalChannel)
    end)

    return true
end

function HarfordSync.SerializeTaggedLootMessage(guid, lootTable)
    local encoded = {}
    for i = 1, #(lootTable or {}) do
        local row = lootTable[i]
        encoded[#encoded + 1] = table.concat({
            row[1] or 0,
            row[2] or 0,
            row[3] and 1 or 0
        }, ":")
    end
    return "LOOT|" .. tostring(guid or "") .. "|" .. table.concat(encoded, ",")
end

function HarfordSync.DeserializeTaggedLootMessage(payload)
    if type(payload) ~= "string" or payload == "" then
        return nil, nil
    end

    local msgType, guid, rawRows = strsplit("|", payload)
    if msgType ~= "LOOT" or not guid or guid == "" then
        return nil, nil
    end

    local lootTable = {}
    if rawRows and rawRows ~= "" then
        for token in string.gmatch(rawRows, "[^,]+") do
            local itemId, quantity, available = strsplit(":", token)
            lootTable[#lootTable + 1] = {
                tonumber(itemId) or 0,
                tonumber(quantity) or 0,
                tonumber(available) == 1
            }
        end
    end

    return guid, lootTable
end

function HarfordSync.SendTaggedLoot(prefix, guid, lootTable, channel, target)
    local ch = channel or (HarfordSync.BestChannel and HarfordSync.BestChannel())
    if not ch then
        return false, "Sin canal disponible"
    end

    local payload = HarfordSync.SerializeTaggedLootMessage(guid, lootTable)

    if HarfordSync.Send then
        HarfordSync.Send(prefix, payload, ch, target)
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, payload, ch, target)
    else
        SendAddonMessage(prefix, payload, ch, target)
    end

    return true
end

HarfordSync.LootKeys = HarfordSync.LootKeys or {
    registry = "registry",
    global = "global",
}

function HarfordSync.SerializeLootRegistryTable(tbl)
    local out = {}
    for creatureId, entries in pairs(tbl or {}) do
        local rows = {}
        for i = 1, #entries do
            local e = entries[i]
            rows[#rows + 1] = table.concat({
                e[1] or 0,
                e[2] or 0,
                e[3] or 1,
                e[4] or 1
            }, ":")
        end
        out[#out + 1] = tostring(creatureId) .. "=" .. table.concat(rows, ",")
    end
    return table.concat(out, ";")
end

function HarfordSync.DeserializeLootRegistryTable(raw)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    for block in string.gmatch(raw, "[^;]+") do
        local eqPos = string.find(block, "=", 1, true)
        if eqPos then
            local creatureId = string.sub(block, 1, eqPos - 1)
            local rows = string.sub(block, eqPos + 1)
            local entries = {}

            if rows and rows ~= "" then
                for token in string.gmatch(rows, "[^,]+") do
                    local p1, p2, p3, p4 = strsplit(":", token)
                    entries[#entries + 1] = {
                        tonumber(p1) or 0,
                        tonumber(p2) or 0,
                        tonumber(p3) or 1,
                        tonumber(p4) or 1,
                    }
                end
            end

            if creatureId and creatureId ~= "" then
                tbl[creatureId] = entries
            end
        end
    end

    return tbl
end

function HarfordSync.SerializeLootGlobalTable(tbl)
    local out = {}
    for i = 1, #(tbl or {}) do
        local e = tbl[i]
        out[#out + 1] = table.concat({
            e[1] or 0,
            e[2] or 0,
            e[3] or 1,
            e[4] or 1
        }, ":")
    end
    return table.concat(out, ",")
end

function HarfordSync.DeserializeLootGlobalTable(raw)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    for token in string.gmatch(raw, "[^,]+") do
        local p1, p2, p3, p4 = strsplit(":", token)
        tbl[#tbl + 1] = {
            tonumber(p1) or 0,
            tonumber(p2) or 0,
            tonumber(p3) or 1,
            tonumber(p4) or 1,
        }
    end

    return tbl
end

function HarfordSync.EnsureLootStore(store)
    if type(store) ~= "table" then
        store = {}
    end
    if type(store.registry) ~= "string" then
        store.registry = ""
    end
    if type(store.global) ~= "string" then
        store.global = ""
    end
    store.values = nil
    return store
end

function HarfordSync.LoadLootConfigFromStore(store)
    store = HarfordSync.EnsureLootStore(store)
    local regRaw = store.registry or ""
    local globalRaw = store.global or ""
    return store, regRaw, globalRaw
end

function HarfordSync.SaveLootConfigToStore(store, regRaw, globalRaw)
    store = HarfordSync.EnsureLootStore(store)
    store.registry = tostring(regRaw or "")
    store.global = tostring(globalRaw or "")
    return store
end

function HarfordSync.SerializeLootConfigMessage(regRaw, globalRaw)
    return "LOOTCFG|" .. tostring(regRaw or "") .. "|" .. tostring(globalRaw or "")
end

function HarfordSync.DeserializeLootConfigMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil
    end

    local a, b, c = strsplit("|", message)
    if a ~= "LOOTCFG" then
        return nil, nil
    end

    return b or "", c or ""
end

function HarfordSync.SendLootConfig(prefix, regRaw, globalRaw, channel, target)
    local ch = channel or (HarfordSync.BestChannel and HarfordSync.BestChannel())
    if not ch then
        return false, "Sin canal disponible"
    end

    local payload = HarfordSync.SerializeLootConfigMessage(regRaw, globalRaw)
    if HarfordSync.Send then
        HarfordSync.Send(prefix, payload, ch, target)
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, payload, ch, target)
    else
        SendAddonMessage(prefix, payload, ch, target)
    end
    return true
end

function HarfordSync.LoadLootConfigTables(store, fallbackRegistry, fallbackGlobal)
    store = HarfordSync.EnsureLootStore(store)

    local regRaw = store.registry or ""
    local globalRaw = store.global or ""

    local registry = fallbackRegistry or {}
    local global = fallbackGlobal or {}

    if regRaw ~= "" then
        registry = HarfordSync.DeserializeLootRegistryTable(regRaw)
    end

    if globalRaw ~= "" then
        global = HarfordSync.DeserializeLootGlobalTable(globalRaw)
    end

    return store, registry, global
end

function HarfordSync.SaveLootConfigTables(store, registry, global)
    store = HarfordSync.EnsureLootStore(store)

    local regRaw = HarfordSync.SerializeLootRegistryTable(registry)
    local globalRaw = HarfordSync.SerializeLootGlobalTable(global)

    store.registry = tostring(regRaw or "")
    store.global = tostring(globalRaw or "")

    return store
end

function HarfordSync.SendLootConfigTables(prefix, registry, global, channel, target)
    local regRaw = HarfordSync.SerializeLootRegistryTable(registry)
    local globalRaw = HarfordSync.SerializeLootGlobalTable(global)
    return HarfordSync.SendLootConfig(prefix, regRaw, globalRaw, channel, target)
end

-- Compat namespaces to keep clearer boundaries without romper APIs existentes.
HarfordSync.Generic = HarfordSync.Generic or {
    RegisterPrefix = HarfordSync.RegisterPrefix,
    Send = HarfordSync.Send,
    BestChannel = HarfordSync.BestChannel,
    CopyTableShallow = HarfordSync.CopyTableShallow,
    EnsureStore = HarfordSync.EnsureStore,
    LoadStoreRuntime = HarfordSync.LoadStoreRuntime,
    GetValue = HarfordSync.GetValue,
    SetValue = HarfordSync.SetValue,
    SerializeKeyValueTable = HarfordSync.SerializeKeyValueTable,
    DeserializeKeyValueTable = HarfordSync.DeserializeKeyValueTable,
}

HarfordSync.DnD = HarfordSync.DnD or {
    ProfileKeys = HarfordSync.ProfileKeys,
    SendDnDProfile = HarfordSync.SendDnDProfile,
    ReceiveDnDProfile = HarfordSync.ReceiveDnDProfile,
    BuildActiveResourcePayloadFromStore = HarfordSync.BuildActiveResourcePayloadFromStore,
    BuildActiveResourcePayloadFromTable = HarfordSync.BuildActiveResourcePayloadFromTable,
    SendResourceRequest = HarfordSync.SendResourceRequest,
    SendResourceResponse = HarfordSync.SendResourceResponse,
    SendResourceConfig = HarfordSync.SendResourceConfig,
    SendResourceAdjust = HarfordSync.SendResourceAdjust,
    DeserializeResourceAdjustMessage = HarfordSync.DeserializeResourceAdjustMessage,
    ReceiveResourceMessage = HarfordSync.ReceiveResourceMessage,
    ReceiveResourceConfig = HarfordSync.ReceiveResourceConfig,
    ScheduleResourceBroadcast = HarfordSync.ScheduleResourceBroadcast,
}

HarfordSync.Loot = HarfordSync.Loot or {
    SerializeTaggedLootMessage = HarfordSync.SerializeTaggedLootMessage,
    DeserializeTaggedLootMessage = HarfordSync.DeserializeTaggedLootMessage,
    SendTaggedLoot = HarfordSync.SendTaggedLoot,
    SerializeLootRegistryTable = HarfordSync.SerializeLootRegistryTable,
    DeserializeLootRegistryTable = HarfordSync.DeserializeLootRegistryTable,
    SerializeLootGlobalTable = HarfordSync.SerializeLootGlobalTable,
    DeserializeLootGlobalTable = HarfordSync.DeserializeLootGlobalTable,
    EnsureLootStore = HarfordSync.EnsureLootStore,
    LoadLootConfigTables = HarfordSync.LoadLootConfigTables,
    SaveLootConfigTables = HarfordSync.SaveLootConfigTables,
    SendLootConfigTables = HarfordSync.SendLootConfigTables,
}
