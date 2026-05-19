HarfordReputationSync = HarfordReputationSync or {}

local API = HarfordReputationSync
local PREFIX = HarfordReputation and HarfordReputation.PREFIX or "HARFORDREP"

local suppress = false

local function Escape(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub("|", "%%7C")
    value = value:gsub(";", "%%3B")
    return value
end

local function Unescape(value)
    value = tostring(value or "")
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
    }, "|")
end

local function DeserializeFaction(message)
    local op, id, name, description, icon, color, hidden, gmNotes, group, subgroup = strsplit("|", message or "")
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

local function HandleMessage(message)
    if not HarfordReputation then return false end
    local opcode = tostring(message or ""):match("^([^|]+)")
    suppress = true
    if opcode == "FAC" then
        local faction = DeserializeFaction(message)
        if faction then HarfordReputation.ApplyFactionFromSync(faction) end
    elseif opcode == "REP" then
        local _, playerKey, factionId, points = strsplit("|", message or "")
        HarfordReputation.ApplyRepFromSync(Unescape(playerKey), Unescape(factionId), tonumber(points) or 0)
    elseif opcode == "NPC" then
        local _, key, factionId = strsplit("|", message or "")
        HarfordReputation.ApplyNpcLinkFromSync(Unescape(key), Unescape(factionId))
    elseif opcode == "LOG" then
        local _, text = strsplit("|", message or "")
        HarfordReputation.AddLog(Unescape(text), { fromSync = true })
    elseif opcode == "DEL" then
        local _, factionId = strsplit("|", message or "")
        local store = HarfordReputation.EnsureStore()
        store.factions[Unescape(factionId)] = nil
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
    HandleMessage(message)
end)
