HarfordReputationSync = HarfordReputationSync or {}

local API = HarfordReputationSync
local PREFIX = HarfordReputation and HarfordReputation.PREFIX or "HARFORDREP"
local SNAPSHOT_CHUNK_BYTES = 190

local suppress = false
local snapshotBuffers = {}

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
        HarfordSync.Send(PREFIX, payload, channel)
        return true
    end
    return false
end

local function GetLocalPlayerKey()
    if HarfordReputation and HarfordReputation.GetPlayerKey then
        local key = HarfordReputation.GetPlayerKey("player")
        if key and key ~= "" then return key end
    end
    return (GetUnitName and GetUnitName("player", true)) or (UnitName and UnitName("player")) or "player"
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
        Escape(faction.gmNotes),
        Escape(faction.group),
        Escape(faction.subgroup),
        tostring(tonumber(faction.sortOrder) or 0),
    }, "|")
end

local function DeserializeFaction(message)
    local op, id, name, description, icon, color, hidden, gmNotes, group, subgroup, sortOrder = strsplit("|", message or "")
    if op ~= "FAC" or not id or id == "" then return nil end
    return {
        id = Unescape(id),
        name = Unescape(name),
        description = Unescape(description),
        icon = Unescape(icon),
        color = Unescape(color),
        hidden = hidden == "1",
        gmNotes = Unescape(gmNotes),
        group = Unescape(group),
        subgroup = Unescape(subgroup),
        sortOrder = tonumber(sortOrder) or 0,
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
    elseif kind == "NPC" then
        local key, factionId = ...
        return Send(table.concat({ "NPC", Escape(key), Escape(factionId) }, "|"))
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

function API.BroadcastAll()
    if not HarfordReputation then return false end
    local channel = BestChannel()
    if not channel then return false end

    local store = HarfordReputation.EnsureStore()
    for _, faction in pairs(store.factions or {}) do
        local payload = SerializeFaction(faction)
        if payload then HarfordSync.Send(PREFIX, payload, channel) end
    end
    for playerKey, player in pairs(store.players or {}) do
        for factionId, rep in pairs((player and player.reps) or {}) do
            HarfordSync.Send(PREFIX, table.concat({ "REP", Escape(playerKey), Escape(factionId), tostring(rep.points or 0) }, "|"), channel)
        end
    end
    for key, factionId in pairs(store.npcLinks or {}) do
        HarfordSync.Send(PREFIX, table.concat({ "NPC", Escape(key), Escape(factionId) }, "|"), channel)
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
            lines[#lines + 1] = table.concat({ "GRP", Escape(resolvedName) }, "|")
            for _, sub in ipairs((groupData and groupData.subgroups) or {}) do
                lines[#lines + 1] = table.concat({ "SUB", Escape(resolvedName), Escape(sub) }, "|")
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
                    lines[#lines + 1] = table.concat({ "REP", Escape(playerKey), Escape(factionId), tostring(rep.points or 0), Escape(player.guild or "") }, "|")
                end
            end
        end

        for guildName, guild in pairs(store.guilds or {}) do
            for factionId, rep in pairs((guild and guild.reps) or {}) do
                if IncludeFaction(factionId) then
                    lines[#lines + 1] = table.concat({ "GREP", Escape(guildName), Escape(factionId), tostring(rep.points or 0) }, "|")
                end
            end
        end
    end

    for key, factionId in pairs(store.npcLinks or {}) do
        if IncludeFaction(factionId) then
            lines[#lines + 1] = table.concat({ "NPC", Escape(key), Escape(factionId) }, "|")
        end
    end

    return table.concat(lines, "\n")
end

local function RefreshReputationViews()
    if HarfordReputationUI and HarfordReputationUI.Refresh then HarfordReputationUI.Refresh() end
    if HarfordReputationTooltip and HarfordReputationTooltip.Refresh then HarfordReputationTooltip.Refresh() end
    if HarfordReputationAdmin and HarfordReputationAdmin.Refresh then HarfordReputationAdmin.Refresh() end
end

local function ApplySnapshot(raw)
    if not HarfordReputation or type(raw) ~= "string" or raw == "" then return false end
    local parsed = { scope = "ALL", selectedFactionId = "", groups = {}, factions = {}, players = {}, guilds = {}, npcLinks = {}, selfReps = {} }

    for line in string.gmatch(raw, "([^\n]+)") do
        local opcode = tostring(line or ""):match("^([^|]+)")
        if opcode == "SNAP" then
            local _, scope, factionId = strsplit("|", line)
            parsed.scope = Unescape(scope)
            parsed.selectedFactionId = Unescape(factionId)
        elseif opcode == "GRP" then
            local _, groupName = strsplit("|", line)
            groupName = Unescape(groupName)
            if groupName ~= "" then parsed.groups[groupName] = parsed.groups[groupName] or { name = groupName, subgroups = {} } end
        elseif opcode == "SUB" then
            local _, groupName, subgroupName = strsplit("|", line)
            groupName, subgroupName = Unescape(groupName), Unescape(subgroupName)
            if groupName ~= "" and subgroupName ~= "" then
                parsed.groups[groupName] = parsed.groups[groupName] or { name = groupName, subgroups = {} }
                parsed.groups[groupName].subgroups[#parsed.groups[groupName].subgroups + 1] = subgroupName
            end
        elseif opcode == "FAC" then
            local faction = DeserializeFaction(line)
            if faction and faction.id then parsed.factions[faction.id] = faction end
        elseif opcode == "REP" then
            local _, playerKey, factionId, points, guildName = strsplit("|", line)
            playerKey, factionId = Unescape(playerKey), Unescape(factionId)
            if playerKey ~= "" and factionId ~= "" then
                parsed.players[playerKey] = parsed.players[playerKey] or { reps = {} }
                parsed.players[playerKey].guild = Unescape(guildName)
                parsed.players[playerKey].reps[factionId] = { points = tonumber(points) or 0, visible = true }
            end
        elseif opcode == "SELFREP" then
            local _, factionId, points = strsplit("|", line)
            factionId = Unescape(factionId)
            if factionId ~= "" then
                parsed.selfReps[factionId] = tonumber(points) or 0
            end
        elseif opcode == "GREP" then
            local _, guildName, factionId, points = strsplit("|", line)
            guildName, factionId = Unescape(guildName), Unescape(factionId)
            if guildName ~= "" and factionId ~= "" then
                parsed.guilds[guildName] = parsed.guilds[guildName] or { reps = {} }
                parsed.guilds[guildName].reps[factionId] = { points = tonumber(points) or 0, visible = true }
            end
        elseif opcode == "NPC" then
            local _, key, factionId = strsplit("|", line)
            key, factionId = Unescape(key), Unescape(factionId)
            if key ~= "" and factionId ~= "" then parsed.npcLinks[key] = factionId end
        end
    end

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
            store.players[localKey].guild = parsed.players[localKey].guild
            store.players[localKey].reps[factionId] = parsed.players[localKey].reps[factionId]
        end
        for _, guild in pairs(store.guilds or {}) do
            if guild.reps then guild.reps[factionId] = nil end
        end
        for guildName, guild in pairs(parsed.guilds or {}) do
            store.guilds[guildName] = store.guilds[guildName] or { reps = {} }
            store.guilds[guildName].reps[factionId] = guild.reps[factionId]
        end
        for key, linkedFactionId in pairs(store.npcLinks or {}) do
            if linkedFactionId == factionId then store.npcLinks[key] = nil end
        end
        for key, linkedFactionId in pairs(parsed.npcLinks or {}) do
            store.npcLinks[key] = linkedFactionId
        end
        store.players[localKey] = store.players[localKey] or { reps = {} }
        store.players[localKey].reps = store.players[localKey].reps or {}
        if parsed.selfReps[factionId] ~= nil then
            store.players[localKey].reps[factionId] = { points = parsed.selfReps[factionId], visible = true }
        end
    elseif parsed.scope == "STRUCTURE" then
        local preservedPlayers = store.players or {}
        local preservedGuilds = store.guilds or {}
        store.factions = parsed.factions
        store.npcLinks = parsed.npcLinks
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
        for _, guild in pairs(preservedGuilds) do
            if guild and guild.reps then
                for factionId in pairs(guild.reps) do
                    if not parsed.factions[factionId] then
                        guild.reps[factionId] = nil
                    end
                end
            end
        end
        local localKey = GetLocalPlayerKey()
        preservedPlayers[localKey] = preservedPlayers[localKey] or { reps = {} }
        preservedPlayers[localKey].reps = preservedPlayers[localKey].reps or {}
        for factionId in pairs(parsed.factions or {}) do
            preservedPlayers[localKey].reps[factionId] = preservedPlayers[localKey].reps[factionId] or { points = 0, visible = true }
        end
        store.players = preservedPlayers
        store.guilds = preservedGuilds
    else
        store.factions = parsed.factions
        store.npcLinks = parsed.npcLinks
        store.groups   = parsed.groups
        store.guilds   = parsed.guilds
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
            store.players[localKey].reps[factionId] = { points = points, visible = true }
        end
    end
    suppress = false
    RefreshReputationViews()
    return true
end

local function SendSnapshot(scope, selectedFactionId)
    local channel = BestChannel()
    if not channel or not HarfordSync or not HarfordSync.Send then return false, "No hay canal de grupo/raid." end
    local raw = SerializeSnapshot(scope, selectedFactionId)
    if not raw or raw == "" then return false, "No hay datos para compartir." end
    local payload = Escape(raw)
    local transferId = tostring((time and time() or 0) % 100000) .. tostring(math.random(1000, 9999))
    local total = math.max(1, math.ceil(#payload / SNAPSHOT_CHUNK_BYTES))
    for index = 1, total do
        local chunk = payload:sub(((index - 1) * SNAPSHOT_CHUNK_BYTES) + 1, index * SNAPSHOT_CHUNK_BYTES)
        HarfordSync.Send(PREFIX, table.concat({ "SNAPC", transferId, scope or "ALL", tostring(index), tostring(total), chunk }, "|"), channel)
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

local function HandleMessage(message, sender)
    if not HarfordReputation then return false end
    local opcode = tostring(message or ""):match("^([^|]+)")

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

    if opcode ~= "SNAPC" then
        return false
    end
    suppress = true
    if opcode == "SNAPC" then
        local transferId, mode, index, total, chunk = tostring(message or ""):match("^SNAPC|([^|]+)|([^|]+)|(%d+)|(%d+)|(.*)$")
        if transferId and index and total and chunk then
            local key = tostring(sender or "?") .. ":" .. transferId
            local buffer = snapshotBuffers[key] or { chunks = {}, mode = mode, total = tonumber(total) or 0 }
            buffer.chunks[tonumber(index)] = chunk
            snapshotBuffers[key] = buffer
            local ready = true
            for i = 1, buffer.total do
                if not buffer.chunks[i] then ready = false break end
            end
            if ready then
                local assembled = {}
                for i = 1, buffer.total do assembled[i] = buffer.chunks[i] end
                snapshotBuffers[key] = nil
                ApplySnapshot(Unescape(table.concat(assembled)))
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
    local myName = (GetUnitName and GetUnitName("player", true)) or UnitName("player")
    if sender and myName and sender == myName then return end
    HandleMessage(message, sender)
end)
