HarfordReputation = HarfordReputation or {}

local API = HarfordReputation

API.PREFIX = "HARFORDREP"
API.TABARD_ICON = "Interface\\Icons\\INV_Shirt_GuildTabard_01"
API.MIN_POINTS = -42000
API.MAX_POINTS = 42000
API.NEUTRAL_POINTS = 0

local DEFAULT_FACTIONS = {
    {
        id = "harford",
        name = "La Compania Harford",
        description = "Reputacion con la Compania Harford.",
        icon = API.TABARD_ICON,
        color = "ffd0a43a",
        group = "Reputaciones Harford",
        subgroup = "Companias",
    },
    {
        id = "velasangre",
        name = "Los Velasangre",
        description = "Reputacion con Los Velasangre.",
        icon = "Interface\\Icons\\Ability_Rogue_BloodyEye",
        color = "ffb53333",
        group = "Reputaciones Harford",
        subgroup = "Facciones",
    },
    {
        id = "bonvapor",
        name = "La Compania Bonvapor",
        description = "Reputacion con la Compania Bonvapor.",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        color = "ff31b6c4",
        group = "Reputaciones Harford",
        subgroup = "Companias",
    },
    {
        id = "cruzada_argenta",
        name = "La Cruzada Argenta",
        description = "Reputacion con La Cruzada Argenta.",
        icon = "Interface\\Icons\\INV_BannerPVP_02",
        color = "ffe8e8d0",
        group = "Reputaciones Harford",
        subgroup = "Ordenes",
    },
    {
        id = "senda_justa",
        name = "La Senda Justa",
        description = "Reputacion con La Senda Justa.",
        icon = "Interface\\Icons\\Spell_Holy_HopeAndGrace",
        color = "ff7cc576",
        group = "Reputaciones Harford",
        subgroup = "Ordenes",
    },
}

local RANKS = {
    { min = -42000, max = -6001, name = "Odiado", color = "ffff2020" },
    { min = -6000, max = -3001, name = "Hostil", color = "ffff7a20" },
    { min = -3000, max = -1, name = "Adverso", color = "ffffc040" },
    { min = 0, max = 2999, name = "Neutral", color = "ffe0e0e0" },
    { min = 3000, max = 8999, name = "Amistoso", color = "ff60d060" },
    { min = 9000, max = 20999, name = "Honorable", color = "ff40a8ff" },
    { min = 21000, max = 41999, name = "Venerado", color = "ffb080ff" },
    { min = 42000, max = 42000, name = "Exaltado", color = "ffffd200" },
}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[HarfordRep]|r " .. tostring(message or ""))
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return math.floor(value)
end

local function Trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function NormalizeId(value)
    value = Trim(value):lower()
    value = value:gsub("[^%w_]+", "_")
    value = value:gsub("_+", "_")
    value = value:gsub("^_+", ""):gsub("_+$", "")
    if value == "" then
        value = "faccion_" .. tostring(time and time() or 0)
    end
    return value
end

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

local function EnsureStore()
    if type(HarfordReputationStore) ~= "table" then
        HarfordReputationStore = {}
    end
    local store = HarfordReputationStore
    if type(store.factions) ~= "table" then store.factions = {} end
    if type(store.players) ~= "table" then store.players = {} end
    if type(store.guilds) ~= "table" then store.guilds = {} end
    if type(store.npcLinks) ~= "table" then store.npcLinks = {} end
    if type(store.logs) ~= "table" then store.logs = {} end

    for _, faction in ipairs(DEFAULT_FACTIONS) do
        if type(store.factions[faction.id]) ~= "table" then
            store.factions[faction.id] = CopyTable(faction)
            store.factions[faction.id].hidden = false
            store.factions[faction.id].gmNotes = ""
        else
            store.factions[faction.id].group = store.factions[faction.id].group or faction.group or "Reputaciones Harford"
            store.factions[faction.id].subgroup = store.factions[faction.id].subgroup or faction.subgroup or ""
        end
    end

    return store
end

local function BuildUnitKey(unit)
    if not UnitExists or not UnitExists(unit) then return nil end
    local name = (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
    if not name or name == "" then return nil end
    return name
end

local function BuildNpcKeys(unit)
    if not UnitExists or not UnitExists(unit) or not UnitGUID then return nil, nil end
    local guid = UnitGUID(unit)
    local npcId = HarfordTRP3 and HarfordTRP3.GetUnitNpcId and HarfordTRP3.GetUnitNpcId(unit)
    return guid, npcId
end

local function GetGuildName(unit)
    if GetGuildInfo and UnitExists and UnitExists(unit) then
        local guild = GetGuildInfo(unit)
        return guild and guild ~= "" and guild or nil
    end
    return nil
end

local function EnsurePlayerEntry(playerKey)
    local store = EnsureStore()
    playerKey = tostring(playerKey or "")
    if playerKey == "" then return nil end
    if type(store.players[playerKey]) ~= "table" then
        store.players[playerKey] = { reps = {}, guild = nil }
    end
    if type(store.players[playerKey].reps) ~= "table" then
        store.players[playerKey].reps = {}
    end
    return store.players[playerKey]
end

local function EnsureGuildEntry(guildName)
    local store = EnsureStore()
    guildName = tostring(guildName or "")
    if guildName == "" then return nil end
    if type(store.guilds[guildName]) ~= "table" then
        store.guilds[guildName] = { reps = {} }
    end
    if type(store.guilds[guildName].reps) ~= "table" then
        store.guilds[guildName].reps = {}
    end
    return store.guilds[guildName]
end

local function FireChanged(kind, ...)
    if HarfordReputationUI and HarfordReputationUI.Refresh then
        HarfordReputationUI.Refresh()
    end
    if HarfordReputationTooltip and HarfordReputationTooltip.Refresh then
        HarfordReputationTooltip.Refresh()
    end
    if HarfordReputationSync and HarfordReputationSync.BroadcastChange then
        HarfordReputationSync.BroadcastChange(kind, ...)
    end
end

function API.EnsureStore()
    return EnsureStore()
end

function API.CanEdit()
    return HarfordAuthority and HarfordAuthority.IsDMMode and HarfordAuthority.IsDMMode() == true
end

function API.GetRanks()
    return RANKS
end

function API.GetRank(points)
    points = Clamp(points, API.MIN_POINTS, API.MAX_POINTS)
    for _, rank in ipairs(RANKS) do
        if points >= rank.min and points <= rank.max then
            return rank.name, rank.color, rank
        end
    end
    return "Neutral", "ffe0e0e0", RANKS[4]
end

function API.GetRankProgress(points)
    points = Clamp(points, API.MIN_POINTS, API.MAX_POINTS)
    local _, _, rank = API.GetRank(points)
    if not rank then return 0, 1, 0 end
    local size = math.max(1, rank.max - rank.min + 1)
    local current = math.max(0, points - rank.min)
    if rank.min == rank.max then
        return 1, 1, 1
    end
    return current, size, current / size
end

function API.GetFaction(factionId)
    local store = EnsureStore()
    return store.factions[tostring(factionId or "")]
end

function API.GetFactions(includeHidden)
    local store = EnsureStore()
    local out = {}
    for id, faction in pairs(store.factions) do
        if includeHidden or not faction.hidden then
            out[#out + 1] = faction
            faction.id = id
        end
    end
    table.sort(out, function(a, b)
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return out
end

function API.CreateFaction(name, description, icon, color)
    if not API.CanEdit() then
        return false, "Solo un DM con .ph dm activo puede crear reputaciones."
    end

    name = Trim(name)
    if name == "" then
        return false, "Nombre de reputacion invalido."
    end

    local store = EnsureStore()
    local id = NormalizeId(name)
    local baseId = id
    local n = 2
    while store.factions[id] do
        id = baseId .. "_" .. tostring(n)
        n = n + 1
    end

    store.factions[id] = {
        id = id,
        name = name,
        description = tostring(description or ""),
        icon = tostring(icon or API.TABARD_ICON),
        color = tostring(color or "ffe0e0e0"),
        group = "Reputaciones Harford",
        subgroup = "",
        hidden = false,
        gmNotes = "",
    }
    FireChanged("FACTION", id)
    return true, id
end

function API.SetFactionHidden(factionId, hidden)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    faction.hidden = hidden == true
    FireChanged("FACTION", factionId)
    return true
end

function API.SetFactionNotes(factionId, notes)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    faction.gmNotes = tostring(notes or "")
    FireChanged("FACTION", factionId)
    return true
end

function API.UpdateFaction(factionId, data)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    if type(data) ~= "table" then return false, "Datos invalidos." end

    local name = Trim(data.name)
    if name == "" then
        return false, "Nombre de reputacion invalido."
    end

    faction.name = name
    faction.description = tostring(data.description or "")
    faction.icon = tostring(data.icon or API.TABARD_ICON)
    faction.color = tostring(data.color or "ffe0e0e0")
    faction.group = Trim(data.group)
    if faction.group == "" then faction.group = "Reputaciones Harford" end
    faction.subgroup = Trim(data.subgroup)
    faction.hidden = data.hidden == true
    faction.gmNotes = tostring(data.gmNotes or "")
    FireChanged("FACTION", factionId)
    return true
end

function API.DeleteFaction(factionId)
    if not API.CanEdit() then return false, "Solo DM." end
    local store = EnsureStore()
    factionId = tostring(factionId or "")
    local faction = store.factions[factionId]
    if not faction then return false, "Reputacion no encontrada." end

    store.factions[factionId] = nil
    for _, player in pairs(store.players or {}) do
        if player and player.reps then
            player.reps[factionId] = nil
        end
    end
    for _, guild in pairs(store.guilds or {}) do
        if guild and guild.reps then
            guild.reps[factionId] = nil
        end
    end
    for key, linkedFactionId in pairs(store.npcLinks or {}) do
        if linkedFactionId == factionId then
            store.npcLinks[key] = nil
        end
    end

    API.AddLog("GM borro la reputacion " .. tostring(faction.name or factionId) .. ".")
    FireChanged("DELETE", factionId)
    return true
end

function API.GetPlayerKey(unitOrName)
    if UnitExists and UnitExists(unitOrName) then
        return BuildUnitKey(unitOrName)
    end
    local raw = Trim(unitOrName)
    return raw ~= "" and raw or nil
end

function API.RememberPlayerGuild(unit)
    local playerKey = BuildUnitKey(unit)
    if not playerKey then return nil end
    local entry = EnsurePlayerEntry(playerKey)
    if not entry then return nil end
    local guild = GetGuildName(unit)
    if guild then
        entry.guild = guild
        EnsureGuildEntry(guild)
    end
    return playerKey, guild
end

function API.GetPlayerPoints(playerKey, factionId)
    local store = EnsureStore()
    playerKey = tostring(playerKey or "")
    factionId = tostring(factionId or "")
    local player = store.players[playerKey]
    if player and player.reps and player.reps[factionId] then
        return Clamp(player.reps[factionId].points, API.MIN_POINTS, API.MAX_POINTS), player.reps[factionId]
    end

    local guildName = player and player.guild
    local guild = guildName and store.guilds[guildName]
    if guild and guild.reps and guild.reps[factionId] then
        return Clamp(guild.reps[factionId].points, API.MIN_POINTS, API.MAX_POINTS), guild.reps[factionId]
    end

    return 0, nil
end

function API.SetPlayerPoints(playerKey, factionId, points, opts)
    if not API.CanEdit() and not (opts and opts.fromSync) then
        return false, "Solo un DM con .ph dm activo puede editar reputacion."
    end

    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end

    playerKey = tostring(playerKey or "")
    if playerKey == "" then return false, "Jugador invalido." end

    local entry = EnsurePlayerEntry(playerKey)
    if not entry then return false, "Jugador invalido." end

    points = Clamp(points, API.MIN_POINTS, API.MAX_POINTS)
    entry.reps[factionId] = entry.reps[factionId] or {}
    entry.reps[factionId].points = points
    entry.reps[factionId].visible = entry.reps[factionId].visible ~= false

    if opts and opts.guildName and opts.guildName ~= "" then
        entry.guild = opts.guildName
        local guild = EnsureGuildEntry(opts.guildName)
        if guild then
            guild.reps[factionId] = guild.reps[factionId] or {}
            guild.reps[factionId].points = points
            guild.reps[factionId].visible = true
        end
    end

    if not (opts and opts.silent) then
        FireChanged("REP", playerKey, factionId)
    end
    return true
end

function API.AdjustPlayerPoints(playerKey, factionId, delta, opts)
    local current = API.GetPlayerPoints(playerKey, factionId)
    return API.SetPlayerPoints(playerKey, factionId, current + (tonumber(delta) or 0), opts)
end

function API.ResetPlayerPoints(playerKey, factionId, opts)
    return API.SetPlayerPoints(playerKey, factionId, 0, opts)
end

function API.AdjustTarget(factionId, delta)
    if not UnitExists or not UnitExists("target") or not UnitIsPlayer or not UnitIsPlayer("target") then
        return false, "Selecciona un jugador objetivo."
    end
    local playerKey, guildName = API.RememberPlayerGuild("target")
    if not playerKey then return false, "Jugador invalido." end

    local ok, err = API.AdjustPlayerPoints(playerKey, factionId, delta, { guildName = guildName })
    if ok then
        local faction = API.GetFaction(factionId)
        local verb = (tonumber(delta) or 0) >= 0 and "subio" or "bajo"
        API.AddLog("GM " .. verb .. " " .. tostring(delta) .. " reputacion a " .. playerKey .. " con " .. tostring(faction and faction.name or factionId) .. ".")
    end
    return ok, err
end

function API.ResetTarget(factionId)
    if not UnitExists or not UnitExists("target") or not UnitIsPlayer or not UnitIsPlayer("target") then
        return false, "Selecciona un jugador objetivo."
    end
    local playerKey, guildName = API.RememberPlayerGuild("target")
    if not playerKey then return false, "Jugador invalido." end
    local ok, err = API.ResetPlayerPoints(playerKey, factionId, { guildName = guildName })
    if ok then
        local faction = API.GetFaction(factionId)
        API.AddLog("GM reinicio reputacion de " .. playerKey .. " con " .. tostring(faction and faction.name or factionId) .. ".")
    end
    return ok, err
end

function API.SetTargetPoints(factionId, points)
    if not UnitExists or not UnitExists("target") or not UnitIsPlayer or not UnitIsPlayer("target") then
        return false, "Selecciona un jugador objetivo."
    end
    local playerKey, guildName = API.RememberPlayerGuild("target")
    if not playerKey then return false, "Jugador invalido." end

    local ok, err = API.SetPlayerPoints(playerKey, factionId, points, { guildName = guildName })
    if ok then
        local faction = API.GetFaction(factionId)
        API.AddLog("GM ajusto reputacion de " .. playerKey .. " con " .. tostring(faction and faction.name or factionId) .. " a " .. tostring(points) .. ".")
    end
    return ok, err
end

function API.GetCurrentPlayerPoints(factionId)
    local playerKey = BuildUnitKey("player") or UnitName("player") or "player"
    API.RememberPlayerGuild("player")
    return API.GetPlayerPoints(playerKey, factionId)
end

function API.LinkFactionToUnit(unit, factionId)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    if not UnitExists or not UnitExists(unit) then return false, "Unidad invalida." end

    local guid, npcId = BuildNpcKeys(unit)
    if not guid or guid == "" then return false, "GUID no disponible." end

    local store = EnsureStore()
    store.npcLinks[guid] = factionId
    if npcId and npcId ~= "" then
        store.npcLinks["npc:" .. npcId] = factionId
    end
    FireChanged("NPC", guid, factionId)
    return true
end

function API.GetLinkedFactionForUnit(unit)
    local store = EnsureStore()
    local guid, npcId = BuildNpcKeys(unit)
    if guid and store.npcLinks[guid] then
        return store.npcLinks[guid]
    end
    if npcId and store.npcLinks["npc:" .. npcId] then
        return store.npcLinks["npc:" .. npcId]
    end
    return nil
end

function API.GetUnitFactionRelationship(unit)
    local factionId = API.GetLinkedFactionForUnit(unit)
    if not factionId then return nil end
    local points = API.GetCurrentPlayerPoints(factionId)
    local rank, rankColor = API.GetRank(points)
    return factionId, points, rank, rankColor
end

function API.AddLog(text, opts)
    local store = EnsureStore()
    local row = {
        time = time and time() or 0,
        text = tostring(text or ""),
    }
    store.logs[#store.logs + 1] = row
    while #store.logs > 100 do
        table.remove(store.logs, 1)
    end
    Print(row.text)
    if not (opts and opts.fromSync) then
        FireChanged("LOG", row.text)
    end
end

function API.ApplyFactionFromSync(faction)
    if type(faction) ~= "table" or not faction.id then return false end
    local store = EnsureStore()
    store.factions[faction.id] = faction
    FireChanged(nil)
    return true
end

function API.ApplyRepFromSync(playerKey, factionId, points)
    return API.SetPlayerPoints(playerKey, factionId, points, { fromSync = true, silent = true })
end

function API.ApplyNpcLinkFromSync(key, factionId)
    local store = EnsureStore()
    if key and key ~= "" and factionId and factionId ~= "" then
        store.npcLinks[key] = factionId
        FireChanged(nil)
        return true
    end
    return false
end

EnsureStore()
