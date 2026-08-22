HarfordReputationSync = HarfordReputationSync or {}

local API = HarfordReputationSync
local PREFIX = HarfordReputation and HarfordReputation.PREFIX or "HARFORDREP"
local SNAPSHOT_CHUNK_BYTES = 190
local SNAPSHOT_BUFFER_TTL = 60
local SNAPSHOT_MAX_CHUNKS = 200
local REMOTE_VIEW_TTL = 600

local suppress = false
local snapshotBuffers = {}
local remoteSnapshotBuffers = {}
local remoteViews = {}

local function Now()
    return (GetTime and GetTime()) or (time and time()) or 0
end

local function PruneSnapshotBuffers(buffers)
    local now = Now()
    for key, buffer in pairs(buffers or {}) do
        if (now - (tonumber(buffer.createdAt) or now)) > SNAPSHOT_BUFFER_TTL then
            buffers[key] = nil
        end
    end
end

local function PruneRemoteViews()
    local now = Now()
    for alias, view in pairs(remoteViews or {}) do
        if (now - (tonumber(view and view.receivedAt) or now)) > REMOTE_VIEW_TTL then
            remoteViews[alias] = nil
        end
    end
end

local function Escape(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub("|", "%%7C")
    value = value:gsub(";", "%%3B")
    value = value:gsub(",", "%%2C")
    value = value:gsub("\r", "%%0D")
    value = value:gsub("\n", "%%0A")
    return value
end

local function Unescape(value)
    value = tostring(value or "")
    value = value:gsub("%%0A", "\n")
    value = value:gsub("%%0D", "\r")
    value = value:gsub("%%2C", ",")
    value = value:gsub("%%3B", ";")
    value = value:gsub("%%7C", "|")
    value = value:gsub("%%25", "%%")
    return value
end

local function BestChannel()
    return HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
end

local function Send(payload)
    local channel = BestChannel()
    if not channel then return false end
    if HarfordSync and HarfordSync.Send then
        return HarfordSync.Send(PREFIX, payload, channel)
    end
    return false
end

local function GetLocalPlayerKey()
    if HarfordReputation and HarfordReputation.GetPlayerKey then
        local key = HarfordReputation.GetPlayerKey("player")
        if key and key ~= "" then return key end
    end
    return HarfordClassColors.UnitFullName("player") or "player"
end

local function IsTrustedSender(sender)
    sender = tostring(sender or "")
    if sender == "" then return false end
    local localKey = GetLocalPlayerKey()
    local localName = UnitName and UnitName("player")
    local localFull = (GetUnitName and GetUnitName("player", true)) or localName
    if sender == localKey or sender == localName or sender == localFull then return true end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(sender) ~= nil
    end
    return false
end

local function IsAtWarPoints(points)
    if HarfordReputation and HarfordReputation.IsAtWarPoints then
        return HarfordReputation.IsAtWarPoints(points)
    end
    return (tonumber(points) or 0) <= -3001
end

local function SerializeFaction(faction)
    if type(faction) ~= "table" then return nil end
    return table.concat({
        "FAC",
        Escape(faction.id),
        Escape(faction.name),
        Escape(faction.description),
        Escape(faction.icon),
        Escape(faction.color),
        faction.hidden and "1" or "0",
        Escape(faction.group),
        Escape(faction.subgroup),
        tostring(tonumber(faction.sortOrder) or 0),
        Escape(faction.epsilonFactionId),
    }, "|")
end

local function DeserializeFaction(message)
    local op, id, name, description, icon, color, hidden, group, subgroup, sortOrder, epsilonFactionId = strsplit("|", message or "")
    if op ~= "FAC" or not id or id == "" then return nil end
    return {
        id = Unescape(id),
        name = Unescape(name),
        description = Unescape(description),
        icon = Unescape(icon),
        color = Unescape(color),
        hidden = hidden == "1",
        group = Unescape(group),
        subgroup = Unescape(subgroup),
        sortOrder = tonumber(sortOrder) or 0,
        epsilonFactionId = Unescape(epsilonFactionId),
    }
end

function API.BroadcastChange(kind, ...)
    if suppress then return false end
    if not HarfordReputation then return false end

    if kind == "FACTION" then
        local factionId = ...
        local faction = HarfordReputation.GetFaction(factionId)
        local payload = SerializeFaction(faction)
        if payload then return Send(payload) end
    elseif kind == "REP" then
        local playerKey, factionId = ...
        local points = HarfordReputation.GetPlayerPoints(playerKey, factionId)
        return Send(table.concat({ "REP", Escape(playerKey), Escape(factionId), tostring(points or 0) }, "|"))
    elseif kind == "LOG" then
        local text = ...
        return Send(table.concat({ "LOG", Escape(text) }, "|"))
    elseif kind == "DELETE" then
        local factionId = ...
        return Send(table.concat({ "DEL", Escape(factionId) }, "|"))
    end

    return false
end

-- Envía los puntos de un jugador directamente por red sin leerlos del store local.
-- AdjustTarget/ResetTarget/SetTargetPoints lo usan para que el DM no acumule
-- datos de otros jugadores en sus propias SavedVariables.
function API.BroadcastRepPoints(playerKey, factionId, points)
    if suppress then return false end
    playerKey = tostring(playerKey or "")
    factionId = tostring(factionId or "")
    points    = tonumber(points) or 0
    if playerKey == "" or factionId == "" then return false end
    return Send(table.concat({ "REP", Escape(playerKey), Escape(factionId), tostring(points) }, "|"))
end

function API.BroadcastRepDelta(factionId, delta)
    if suppress then return false end
    factionId = tostring(factionId or "")
    delta = tonumber(delta) or 0
    if factionId == "" or delta == 0 then return false end
    return Send(table.concat({ "RDELTA", Escape(factionId), tostring(delta) }, "|"))
end

function API.BroadcastAll()
    if not HarfordReputation then return false end
    local channel = BestChannel()
    if not channel then return false end

    local store = HarfordReputation.EnsureStore()
    for _, faction in pairs(store.factions or {}) do
        local payload = SerializeFaction(faction)
        if payload then
            local ok, err = HarfordSync.Send(PREFIX, payload, channel)
            if not ok then return false, err end
        end
    end
    for playerKey, player in pairs(store.players or {}) do
        for factionId, rep in pairs((player and player.reps) or {}) do
            local ok, err = HarfordSync.Send(PREFIX, table.concat({ "REP", Escape(playerKey), Escape(factionId), tostring(rep.points or 0) }, "|"), channel)
            if not ok then return false, err end
        end
    end
    return true
end

local function SerializeSnapshot(scope, selectedFactionId)
    if not HarfordReputation then return nil end
    local store = HarfordReputation.EnsureStore()
    scope = scope or "ALL"
    local includeAll = scope ~= "FACTION"
    local includePoints = scope ~= "STRUCTURE"
    local lines = { "SNAP|" .. Escape(scope or "ALL") .. "|" .. Escape(selectedFactionId or "") }
    local includedFactions = {}

    local function IncludeFaction(factionId)
        return includeAll or tostring(factionId or "") == tostring(selectedFactionId or "")
    end

    for groupName, groupData in pairs(store.groups or {}) do
        local includeGroup = includeAll
        if not includeGroup and selectedFactionId and store.factions[selectedFactionId] then
            includeGroup = tostring(store.factions[selectedFactionId].group or "") == tostring(groupName or "")
        end
        if includeGroup then
            local resolvedName = (groupData and groupData.name) or groupName
            lines[#lines + 1] = table.concat({
                "GRP",
                Escape(resolvedName),
                tostring(tonumber(groupData and groupData.sortOrder) or 0),
            }, "|")
            for _, sub in ipairs((groupData and groupData.subgroups) or {}) do
                local subOrder = 0
                if type(groupData and groupData.subgroupOrder) == "table" then
                    subOrder = tonumber(groupData.subgroupOrder[sub]) or 0
                end
                lines[#lines + 1] = table.concat({
                    "SUB",
                    Escape(resolvedName),
                    Escape(sub),
                    tostring(subOrder),
                }, "|")
            end
        end
    end

    for factionId, faction in pairs(store.factions or {}) do
        if IncludeFaction(factionId) then
            faction.id = factionId
            includedFactions[factionId] = true
            lines[#lines + 1] = SerializeFaction(faction)
        end
    end

    if includePoints then
        for factionId in pairs(includedFactions) do
            local points = HarfordReputation.GetCurrentPlayerPoints and HarfordReputation.GetCurrentPlayerPoints(factionId) or 0
            lines[#lines + 1] = table.concat({ "SELFREP", Escape(factionId), tostring(points or 0) }, "|")
        end
    end

    if includePoints then
        for playerKey, player in pairs(store.players or {}) do
            for factionId, rep in pairs((player and player.reps) or {}) do
                if IncludeFaction(factionId) then
                    lines[#lines + 1] = table.concat({ "REP", Escape(playerKey), Escape(factionId), tostring(rep.points or 0) }, "|")
                end
            end
        end
    end

    return table.concat(lines, "\n")
end

-- Debounce: colapsa ráfagas de mensajes REP/RDELTA en un único refresh de UI.
-- BroadcastAll() y BroadcastRepPoints() envían un mensaje por jugador/facción;
-- sin debounce cada uno dispararía un Refresh completo.
local _refreshViewsPending = false
local function RefreshReputationViews()
    if _refreshViewsPending then return end
    _refreshViewsPending = true
    C_Timer.After(0.1, function()
        _refreshViewsPending = false
        if HarfordReputationUI and HarfordReputationUI.Refresh then HarfordReputationUI.Refresh() end
        if HarfordReputationAdmin and HarfordReputationAdmin.Refresh then HarfordReputationAdmin.Refresh() end
    end)
end

local function ParseSnapshot(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    local parsed = { scope = "ALL", selectedFactionId = "", groups = {}, factions = {}, players = {}, selfReps = {} }

    for line in string.gmatch(raw, "([^\n]+)") do
        local opcode = tostring(line or ""):match("^([^|]+)")
        if opcode == "SNAP" then
            local _, scope, factionId = strsplit("|", line)
            parsed.scope = Unescape(scope)
            parsed.selectedFactionId = Unescape(factionId)
        elseif opcode == "GRP" then
            local _, groupName, sortOrder = strsplit("|", line)
            groupName = Unescape(groupName)
            if groupName ~= "" then
                parsed.groups[groupName] = parsed.groups[groupName] or { name = groupName, subgroups = {}, subgroupOrder = {} }
                parsed.groups[groupName].name = groupName
                parsed.groups[groupName].sortOrder = tonumber(sortOrder) or 0
                parsed.groups[groupName].subgroups = parsed.groups[groupName].subgroups or {}
                parsed.groups[groupName].subgroupOrder = parsed.groups[groupName].subgroupOrder or {}
            end
        elseif opcode == "SUB" then
            local _, groupName, subgroupName, sortOrder = strsplit("|", line)
            groupName, subgroupName = Unescape(groupName), Unescape(subgroupName)
            if groupName ~= "" and subgroupName ~= "" then
                parsed.groups[groupName] = parsed.groups[groupName] or { name = groupName, subgroups = {}, subgroupOrder = {} }
                parsed.groups[groupName].subgroups = parsed.groups[groupName].subgroups or {}
                parsed.groups[groupName].subgroupOrder = parsed.groups[groupName].subgroupOrder or {}
                parsed.groups[groupName].subgroups[#parsed.groups[groupName].subgroups + 1] = subgroupName
                parsed.groups[groupName].subgroupOrder[subgroupName] = tonumber(sortOrder) or (#parsed.groups[groupName].subgroups * 10)
            end
        elseif opcode == "FAC" then
            local faction = DeserializeFaction(line)
            if faction and faction.id then parsed.factions[faction.id] = faction end
        elseif opcode == "REP" then
            local _, playerKey, factionId, points = strsplit("|", line)
            playerKey, factionId = Unescape(playerKey), Unescape(factionId)
            if playerKey ~= "" and factionId ~= "" then
                parsed.players[playerKey] = parsed.players[playerKey] or { reps = {} }
                local repPoints = tonumber(points) or 0
                parsed.players[playerKey].reps[factionId] = { points = repPoints, visible = true, atWar = IsAtWarPoints(repPoints) }
            end
        elseif opcode == "SELFREP" then
            local _, factionId, points = strsplit("|", line)
            factionId = Unescape(factionId)
            if factionId ~= "" then
                parsed.selfReps[factionId] = tonumber(points) or 0
            end
        end
    end
    return parsed
end

local function BuildRemoteAliases(playerKey)
    local aliases = {}
    playerKey = tostring(playerKey or "")
    if playerKey ~= "" then
        aliases[#aliases + 1] = playerKey
        if Ambiguate then
            aliases[#aliases + 1] = Ambiguate(playerKey, "short")
        end
        local short = playerKey:match("^[^-]+")
        if short and short ~= "" then aliases[#aliases + 1] = short end
    end
    return aliases
end

local function StoreRemoteView(playerKey, parsed)
    if not parsed or not playerKey or playerKey == "" then return false end
    PruneRemoteViews()
    local view = {
        playerKey = playerKey,
        scope = parsed.scope or "ALL",
        groups = parsed.groups or {},
        factions = parsed.factions or {},
        points = {},
        receivedAt = GetTime and GetTime() or time(),
    }
    for factionId, points in pairs(parsed.selfReps or {}) do
        view.points[factionId] = tonumber(points) or 0
    end
    for _, alias in ipairs(BuildRemoteAliases(playerKey)) do
        remoteViews[alias] = view
    end
    return true
end

local function ApplySnapshot(raw)
    if not HarfordReputation then return false end
    local parsed = ParseSnapshot(raw)
    if not parsed then return false end

    local store = HarfordReputation.EnsureStore()
    suppress = true
    if parsed.scope == "FACTION" then
        local factionId = tostring(parsed.selectedFactionId or "")
        if factionId == "" then suppress = false return false end
        store.factions[factionId] = parsed.factions[factionId]
        local faction = store.factions[factionId]
        if faction and faction.group and faction.group ~= "" then
            store.groups[faction.group] = parsed.groups[faction.group] or store.groups[faction.group] or { name = faction.group, subgroups = {} }
            if faction.subgroup and faction.subgroup ~= "" then
                local found = false
                store.groups[faction.group].subgroups = store.groups[faction.group].subgroups or {}
                for _, sub in ipairs(store.groups[faction.group].subgroups) do
                    if sub == faction.subgroup then found = true break end
                end
                if not found then
                    store.groups[faction.group].subgroups[#store.groups[faction.group].subgroups + 1] = faction.subgroup
                end
            end
        end
        -- Solo actualizar los puntos del jugador local; no persistir datos ajenos.
        local localKey = GetLocalPlayerKey()
        if store.players[localKey] and store.players[localKey].reps then
            store.players[localKey].reps[factionId] = nil
        end
        if parsed.players[localKey] then
            store.players[localKey] = store.players[localKey] or { reps = {} }
            store.players[localKey].reps[factionId] = parsed.players[localKey].reps[factionId]
        end
        store.players[localKey] = store.players[localKey] or { reps = {} }
        store.players[localKey].reps = store.players[localKey].reps or {}
        if parsed.selfReps[factionId] ~= nil then
            local repPoints = parsed.selfReps[factionId]
            store.players[localKey].reps[factionId] = { points = repPoints, visible = true, atWar = IsAtWarPoints(repPoints) }
        end
    elseif parsed.scope == "STRUCTURE" then
        local preservedPlayers = store.players or {}
        store.factions = parsed.factions
        store.npcLinks = nil
        store.groups = parsed.groups
        for _, player in pairs(preservedPlayers) do
            if player and player.reps then
                for factionId in pairs(player.reps) do
                    if not parsed.factions[factionId] then
                        player.reps[factionId] = nil
                    end
                end
            end
        end
        local localKey = GetLocalPlayerKey()
        preservedPlayers[localKey] = preservedPlayers[localKey] or { reps = {} }
        preservedPlayers[localKey].reps = preservedPlayers[localKey].reps or {}
        for factionId in pairs(parsed.factions or {}) do
            preservedPlayers[localKey].reps[factionId] = preservedPlayers[localKey].reps[factionId] or { points = 0, visible = true, atWar = false }
        end
        store.players = preservedPlayers
        store.guilds = nil
    else
        store.factions = parsed.factions
        store.npcLinks = nil
        store.groups   = parsed.groups
        store.guilds   = nil
        -- players: solo conservar el jugador local; descartar el resto para no
        -- acumular datos de otros jugadores en las SavedVariables de cada cliente.
        local localKey = GetLocalPlayerKey()
        store.players = {}
        if parsed.players[localKey] then
            store.players[localKey] = parsed.players[localKey]
        end
        store.players[localKey] = store.players[localKey] or { reps = {} }
        store.players[localKey].reps = store.players[localKey].reps or {}
        for factionId, points in pairs(parsed.selfReps or {}) do
            store.players[localKey].reps[factionId] = { points = points, visible = true, atWar = IsAtWarPoints(points) }
        end
    end
    suppress = false
    RefreshReputationViews()
    return true
end

local function SendRemoteView(target)
    target = tostring(target or "")
    if target == "" or not HarfordSync or not HarfordSync.Send then return false end
    local raw = SerializeSnapshot("ALL")
    if not raw or raw == "" then return false end
    local payload = Escape(raw)
    local transferId = tostring((time and time() or 0) % 100000) .. tostring(math.random(1000, 9999))
    local total = math.max(1, math.ceil(#payload / SNAPSHOT_CHUNK_BYTES))
    if total > 80 then
        return false, "Snapshot de reputacion demasiado grande."
    end
    for index = 1, total do
        local chunk = payload:sub(((index - 1) * SNAPSHOT_CHUNK_BYTES) + 1, index * SNAPSHOT_CHUNK_BYTES)
        local ok, err = HarfordSync.Send(PREFIX, table.concat({ "RVIEWC", transferId, tostring(index), tostring(total), chunk }, "|"), "WHISPER", target)
        if not ok then return false, err end
    end
    return true, total
end

local function SendSnapshot(scope, selectedFactionId)
    local channel = BestChannel()
    if not channel or not HarfordSync or not HarfordSync.Send then return false, "No hay canal de grupo/raid." end
    local raw = SerializeSnapshot(scope, selectedFactionId)
    if not raw or raw == "" then return false, "No hay datos para compartir." end
    local payload = Escape(raw)
    local transferId = tostring((time and time() or 0) % 100000) .. tostring(math.random(1000, 9999))
    local total = math.max(1, math.ceil(#payload / SNAPSHOT_CHUNK_BYTES))
    if total > 80 then
        return false, "Snapshot de reputacion demasiado grande."
    end
    for index = 1, total do
        local chunk = payload:sub(((index - 1) * SNAPSHOT_CHUNK_BYTES) + 1, index * SNAPSHOT_CHUNK_BYTES)
        local ok, err = HarfordSync.Send(PREFIX, table.concat({ "SNAPC", transferId, scope or "ALL", tostring(index), tostring(total), chunk }, "|"), channel)
        if not ok then return false, err end
    end
    return true, total
end

function API.BroadcastSnapshotAll()
    return SendSnapshot("ALL")
end

function API.BroadcastSnapshotStructure()
    return SendSnapshot("STRUCTURE")
end

function API.BroadcastSnapshotFaction(factionId)
    factionId = tostring(factionId or "")
    if factionId == "" or not HarfordReputation or not HarfordReputation.GetFaction(factionId) then
        return false, "No hay reputacion seleccionada."
    end
    return SendSnapshot("FACTION", factionId)
end

function API.RequestPlayerSnapshot(playerKey)
    if not HarfordSync or not HarfordSync.Send then return false end
    playerKey = tostring(playerKey or "")
    if playerKey == "" then return false end
    local ok, err = HarfordSync.Send(PREFIX, "RVIEWREQ", "WHISPER", playerKey)
    if ok then return true end
    local short = Ambiguate and Ambiguate(playerKey, "short") or playerKey:match("^[^-]+")
    if short and short ~= "" and short ~= playerKey then
        return HarfordSync.Send(PREFIX, "RVIEWREQ", "WHISPER", short)
    end
    return false, err
end

function API.GetRemoteView(playerKey)
    PruneRemoteViews()
    for _, alias in ipairs(BuildRemoteAliases(playerKey)) do
        if remoteViews[alias] then return remoteViews[alias] end
    end
    return nil
end

function API.SetRemoteViewPoints(playerKey, factionId, points)
    local view = API.GetRemoteView(playerKey)
    if not view then return false end
    factionId = tostring(factionId or "")
    if factionId == "" then return false end
    view.points = view.points or {}
    view.points[factionId] = tonumber(points) or 0
    return true
end

local function HandleMessage(message, sender)
    if not HarfordReputation then return false end
    local opcode = tostring(message or ""):match("^([^|]+)")

    if opcode == "RVIEWREQ" then
        SendRemoteView(sender)
        return true
    end

    if opcode == "RVIEWC" then
        local transferId, index, total, chunk = tostring(message or ""):match("^RVIEWC|([^|]+)|(%d+)|(%d+)|(.*)$")
        if transferId and index and total and chunk then
            index, total = tonumber(index), tonumber(total)
            if not index or not total or index < 1 or index > total or total > SNAPSHOT_MAX_CHUNKS then
                return true
            end
            PruneSnapshotBuffers(remoteSnapshotBuffers)
            local key = tostring(sender or "?") .. ":" .. transferId
            local buffer = remoteSnapshotBuffers[key] or { chunks = {}, total = total, createdAt = Now() }
            if buffer.total ~= total then
                buffer = { chunks = {}, total = total, createdAt = Now() }
            end
            buffer.chunks[index] = chunk
            remoteSnapshotBuffers[key] = buffer
            local ready = true
            for i = 1, buffer.total do
                if not buffer.chunks[i] then ready = false break end
            end
            if ready then
                local assembled = {}
                for i = 1, buffer.total do assembled[i] = buffer.chunks[i] end
                remoteSnapshotBuffers[key] = nil
                local parsed = ParseSnapshot(Unescape(table.concat(assembled)))
                if parsed then
                    StoreRemoteView(sender, parsed)
                    RefreshReputationViews()
                end
            end
        end
        return true
    end

    -- Cambio de puntos individual enviado por el DM tras AdjustTarget.
    -- Solo se persiste si los puntos son del jugador local; los demás miembros
    -- del grupo que reciben el broadcast simplemente refrescan su UI.
    if opcode == "REP" then
        local _, playerKey, factionId, points = strsplit("|", message)
        playerKey = Unescape(playerKey or "")
        factionId = Unescape(factionId or "")
        points    = tonumber(points) or 0
        if playerKey ~= "" and factionId ~= "" then
            local localKey = GetLocalPlayerKey()
            if playerKey == localKey then
                HarfordReputation.SetPlayerPoints(playerKey, factionId, points, { fromSync = true })
            end
        end
        RefreshReputationViews()
        return true
    end

    if opcode == "RDELTA" then
        local _, factionId, delta = strsplit("|", message)
        factionId = Unescape(factionId or "")
        delta = tonumber(delta) or 0
        if factionId ~= "" and delta ~= 0 then
            local localKey = GetLocalPlayerKey()
            local localName = UnitName and UnitName("player")
            local localFull = (GetUnitName and GetUnitName("player", true)) or localName
            if sender ~= localKey and sender ~= localName and sender ~= localFull then
                local current = HarfordReputation.GetPlayerPoints(localKey, factionId)
                HarfordReputation.SetPlayerPoints(localKey, factionId, (current or 0) + delta, { fromSync = true })
            end
        end
        RefreshReputationViews()
        return true
    end

    if opcode ~= "SNAPC" then
        return false
    end
    suppress = true
    if opcode == "SNAPC" then
        local transferId, mode, index, total, chunk = tostring(message or ""):match("^SNAPC|([^|]+)|([^|]+)|(%d+)|(%d+)|(.*)$")
        if transferId and index and total and chunk then
            index, total = tonumber(index), tonumber(total)
            if not index or not total or index < 1 or index > total or total > SNAPSHOT_MAX_CHUNKS then
                suppress = false
                return true
            end
            PruneSnapshotBuffers(snapshotBuffers)
            local key = tostring(sender or "?") .. ":" .. transferId
            local buffer = snapshotBuffers[key] or { chunks = {}, mode = mode, total = total, createdAt = Now() }
            if buffer.total ~= total then
                buffer = { chunks = {}, mode = mode, total = total, createdAt = Now() }
            end
            buffer.chunks[index] = chunk
            snapshotBuffers[key] = buffer
            local ready = true
            for i = 1, buffer.total do
                if not buffer.chunks[i] then ready = false break end
            end
            if ready then
                local assembled = {}
                for i = 1, buffer.total do assembled[i] = buffer.chunks[i] end
                snapshotBuffers[key] = nil
                local ok, err = pcall(ApplySnapshot, Unescape(table.concat(assembled)))
                if not ok and HarfordDebug and HarfordDebug.Log then
                    HarfordDebug.Log("reputation snapshot error", tostring(err))
                end
            end
        end
    end
    suppress = false
    return true
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("CHAT_MSG_ADDON")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        if HarfordSync and HarfordSync.RegisterPrefix then
            HarfordSync.RegisterPrefix(PREFIX)
        elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(PREFIX)
        end
        return
    end

    local prefix, message, _, sender = ...
    if prefix ~= PREFIX then return end
    local myName = HarfordClassColors.UnitFullName("player")
    if sender and myName and sender == myName then return end
    if not IsTrustedSender(sender) then return end
    -- Alguien publico el catalogo en la fase: releerlo ahora en vez de esperar al cambio de
    -- fase. El aviso no trae datos; lo que vale es lo escrito en la fase.
    if HarfordReputationPhase and _G.HarfordPhaseStore and _G.HarfordPhaseStore.HandleNotify then
        if _G.HarfordPhaseStore.HandleNotify(message, "facciones", function()
            HarfordReputationPhase.EnsureCatalog(true)
        end) then
            return
        end
    end
    HandleMessage(message, sender)
end)
