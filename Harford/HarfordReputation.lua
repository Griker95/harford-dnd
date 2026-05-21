HarfordReputation = HarfordReputation or {}

local API = HarfordReputation

API.PREFIX = "HARFORDREP"
API.ICON_PATH = "Interface\\Icons\\"
API.TABARD_ICON = "INV_Shirt_GuildTabard_01"
API.MIN_POINTS = -42000
API.MAX_POINTS = 42000
API.NEUTRAL_POINTS = 0

local DEFAULT_GROUP = "Reputaciones Harford"

function API.NormalizeIconName(value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" then return API.TABARD_ICON end
    value = value:gsub("/", "\\")
    value = value:gsub("^Interface\\Icons\\", "")
    value = value:gsub("^Interface\\ICONS\\", "")
    value = value:gsub("^interface\\icons\\", "")
    value = value:gsub("%.blp$", ""):gsub("%.BLP$", "")
    value = value:gsub("%.tga$", ""):gsub("%.TGA$", "")
    if value == "" then
        return API.TABARD_ICON
    end
    return value
end

function API.ResolveIconTexture(value)
    return API.ICON_PATH .. API.NormalizeIconName(value)
end

-- Las facciones viven íntegramente en HarfordReputationStore (SavedVariables).
-- No hay defaults hardcodeados: créalas y gestiónalas desde /harfordadmin rep.

local RANKS = {
    { min = -42000, max = -6001, name = "Odiado", color = "ffff2020" },
    { min = -6000, max = -3001, name = "Hostil", color = "ffff7a20" },
    { min = -3000, max = -1, name = "Adverso", color = "ffffc040" },
    { min = 0, max = 2999, name = "Neutral", color = "ffe0e0e0" },
    { min = 3000, max = 8999, name = "Amistoso", color = "ff60d060" },
    { min = 9000, max = 20999, name = "Honorable", color = "ff40a8ff" },
    { min = 21000, max = 41999, name = "Reverenciado", color = "ffb080ff" },
    { min = 42000, max = 42999, name = "Exaltado",     color = "ffffd200" },
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

function API.NormalizeEpsilonFactionId(value)
    value = Trim(value)
    if value == "" then return "" end
    local numberValue = tonumber(value)
    if not numberValue then return "" end
    numberValue = math.floor(numberValue)
    if numberValue <= 0 then return "" end
    return tostring(numberValue)
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
    if type(store.groups) ~= "table" then store.groups = {} end

    return store
end

local function NextGroupSortOrder(store)
    local maxOrder = 0
    for _, groupData in pairs((store and store.groups) or {}) do
        maxOrder = math.max(maxOrder, tonumber(groupData and groupData.sortOrder) or 0)
    end
    return maxOrder + 10
end

local function NextSubgroupSortOrder(groupData)
    local maxOrder = 0
    for _, order in pairs((groupData and groupData.subgroupOrder) or {}) do
        maxOrder = math.max(maxOrder, tonumber(order) or 0)
    end
    return maxOrder + 10
end

local function EnsureGroupRecord(store, groupName)
    groupName = Trim(groupName)
    if groupName == "" then groupName = DEFAULT_GROUP end
    local groupData = store.groups[groupName]
    if type(groupData) ~= "table" then
        groupData = {
            name = groupName,
            subgroups = {},
            subgroupOrder = {},
            sortOrder = NextGroupSortOrder(store),
        }
        store.groups[groupName] = groupData
    end
    groupData.name = groupName
    if type(groupData.subgroups) ~= "table" then groupData.subgroups = {} end
    if type(groupData.subgroupOrder) ~= "table" then groupData.subgroupOrder = {} end
    if groupData.sortOrder == nil then groupData.sortOrder = NextGroupSortOrder(store) end
    return groupData, groupName
end

local function EnsureSubgroupRecord(groupData, subgroupName)
    subgroupName = Trim(subgroupName)
    if subgroupName == "" then return subgroupName end
    if type(groupData.subgroups) ~= "table" then groupData.subgroups = {} end
    if type(groupData.subgroupOrder) ~= "table" then groupData.subgroupOrder = {} end
    local exists = false
    for _, existing in ipairs(groupData.subgroups) do
        if existing == subgroupName then exists = true; break end
    end
    if not exists then
        groupData.subgroups[#groupData.subgroups + 1] = subgroupName
    end
    if groupData.subgroupOrder[subgroupName] == nil then
        groupData.subgroupOrder[subgroupName] = NextSubgroupSortOrder(groupData)
    end
    return subgroupName
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

function API.IsAtWarPoints(points)
    points = Clamp(points, API.MIN_POINTS, API.MAX_POINTS)
    return points <= -3001
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
    -- sortOrder primero (orden manual DM); dentro del mismo sortOrder, alfabético
    table.sort(out, function(a, b)
        local oa = tonumber(a.sortOrder) or 0
        local ob = tonumber(b.sortOrder) or 0
        if oa ~= ob then return oa < ob end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return out
end

-- Acepta tabla de datos o argumentos posicionales (compatibilidad con código viejo)
function API.CreateFaction(nameOrData, description, icon, color)
    if not API.CanEdit() then
        return false, "Solo un DM con .ph dm activo puede crear reputaciones."
    end

    local data
    if type(nameOrData) == "table" then
        data = nameOrData
    else
        data = { name = nameOrData, description = description, icon = icon, color = color }
    end

    local name = Trim(data.name or "")
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

    local group = Trim(data.group or "")
    if group == "" then group = DEFAULT_GROUP end

    store.factions[id] = {
        id = id,
        name = name,
        description = tostring(data.description or ""),
        icon = API.NormalizeIconName(data.icon or API.TABARD_ICON),
        color = tostring(data.color or "ffe0e0e0"),
        epsilonFactionId = API.NormalizeEpsilonFactionId(data.epsilonFactionId),
        group = group,
        subgroup = Trim(data.subgroup or ""),
        hidden = data.hidden == true,
        sortOrder = tonumber(data.sortOrder) or 0,
    }
    FireChanged("FACTION", id)
    return true, id
end

-- Devuelve la lista de grupos únicos (con sus subgrupos) para el panel GM
function API.GetGroups()
    local store = EnsureStore()
    local groupMap = {}
    local groupOrder = {}
    for groupName, groupData in pairs(store.groups or {}) do
        local g = Trim(type(groupData) == "table" and groupData.name or groupName)
        if g ~= "" and not groupMap[g] then
            local stored = EnsureGroupRecord(store, g)
            groupMap[g] = {
                subgroups = {},
                subgroupOrder = stored.subgroupOrder or {},
                sortOrder = tonumber(stored.sortOrder) or 0,
            }
            groupOrder[#groupOrder + 1] = g
        end
        for _, sub in ipairs((groupData and groupData.subgroups) or {}) do
            sub = Trim(sub)
            if sub ~= "" then
                local found = false
                for _, existing in ipairs(groupMap[g].subgroups) do
                    if existing == sub then found = true; break end
                end
                if not found then groupMap[g].subgroups[#groupMap[g].subgroups + 1] = sub end
            end
        end
    end
    for _, faction in pairs(store.factions) do
        local g = Trim(faction.group or "")
        if g == "" then g = DEFAULT_GROUP end
        if not groupMap[g] then
            local stored = EnsureGroupRecord(store, g)
            groupMap[g] = {
                subgroups = {},
                subgroupOrder = stored.subgroupOrder or {},
                sortOrder = tonumber(stored.sortOrder) or 0,
            }
            groupOrder[#groupOrder + 1] = g
        end
        local sub = Trim(faction.subgroup or "")
        if sub ~= "" then
            EnsureSubgroupRecord(store.groups[g], sub)
            groupMap[g].subgroupOrder = store.groups[g].subgroupOrder or groupMap[g].subgroupOrder
            local found = false
            for _, existing in ipairs(groupMap[g].subgroups) do
                if existing == sub then found = true; break end
            end
            if not found then
                groupMap[g].subgroups[#groupMap[g].subgroups + 1] = sub
            end
        end
    end
    table.sort(groupOrder, function(a, b)
        local ga, gb = groupMap[a], groupMap[b]
        local oa, ob = tonumber(ga and ga.sortOrder) or 0, tonumber(gb and gb.sortOrder) or 0
        if oa ~= ob then return oa < ob end
        return tostring(a) < tostring(b)
    end)
    local out = {}
    for _, g in ipairs(groupOrder) do
        local subgroups = groupMap[g].subgroups
        local orderMap = groupMap[g].subgroupOrder or {}
        table.sort(subgroups, function(a, b)
            local oa, ob = tonumber(orderMap[a]) or 0, tonumber(orderMap[b]) or 0
            if oa ~= ob then return oa < ob end
            return tostring(a) < tostring(b)
        end)
        out[#out + 1] = { name = g, subgroups = subgroups, sortOrder = groupMap[g].sortOrder }
    end
    return out
end

function API.CreateGroup(name)
    if not API.CanEdit() then return false, "Solo DM." end
    name = Trim(name)
    if name == "" then return false, "Nombre invalido." end
    local store = EnsureStore()
    EnsureGroupRecord(store, name)
    FireChanged("GROUP")
    return true, name
end

function API.CreateSubgroup(groupName, subgroupName)
    if not API.CanEdit() then return false, "Solo DM." end
    groupName = Trim(groupName)
    subgroupName = Trim(subgroupName)
    if groupName == "" or subgroupName == "" then return false, "Nombre invalido." end
    local store = EnsureStore()
    local groupData = EnsureGroupRecord(store, groupName)
    EnsureSubgroupRecord(groupData, subgroupName)
    FireChanged("GROUP")
    return true, subgroupName
end

function API.SetFactionGroup(factionId, groupName, subgroupName)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    groupName = Trim(groupName)
    subgroupName = Trim(subgroupName)
    if groupName == "" then groupName = DEFAULT_GROUP end
    faction.group = groupName
    faction.subgroup = subgroupName
    local store = EnsureStore()
    local groupData = EnsureGroupRecord(store, groupName)
    if subgroupName ~= "" then EnsureSubgroupRecord(groupData, subgroupName) end
    FireChanged("FACTION", factionId)
    return true
end

-- Renombra un grupo entero (actualiza todas las facciones que lo usen)
function API.RenameGroup(oldName, newName)
    if not API.CanEdit() then return false, "Solo DM." end
    oldName = Trim(oldName)
    newName = Trim(newName)
    if oldName == "" or newName == "" then return false, "Nombre invalido." end
    if oldName == newName then return true end
    local store = EnsureStore()
    if store.groups[oldName] then
        store.groups[newName] = store.groups[oldName]
        store.groups[newName].name = newName
        store.groups[oldName] = nil
    end
    local count = 0
    for _, faction in pairs(store.factions) do
        local g = Trim(faction.group or "")
        if g == "" then g = DEFAULT_GROUP end
        if g == oldName then
            faction.group = newName
            count = count + 1
        end
    end
    FireChanged("GROUP")
    return true
end

-- Renombra un subgrupo dentro de un grupo
function API.RenameSubgroup(groupName, oldSub, newSub)
    if not API.CanEdit() then return false, "Solo DM." end
    groupName = Trim(groupName)
    oldSub = Trim(oldSub or "")
    newSub = Trim(newSub or "")
    local store = EnsureStore()
    if store.groups[groupName] and type(store.groups[groupName].subgroups) == "table" then
        for index, existing in ipairs(store.groups[groupName].subgroups) do
            if existing == oldSub then
                store.groups[groupName].subgroups[index] = newSub
            end
        end
        if type(store.groups[groupName].subgroupOrder) == "table" then
            store.groups[groupName].subgroupOrder[newSub] = store.groups[groupName].subgroupOrder[oldSub]
            store.groups[groupName].subgroupOrder[oldSub] = nil
        end
    end
    local count = 0
    for _, faction in pairs(store.factions) do
        local g = Trim(faction.group or "")
        if g == "" then g = DEFAULT_GROUP end
        if g == groupName and Trim(faction.subgroup or "") == oldSub then
            faction.subgroup = newSub
            count = count + 1
        end
    end
    FireChanged("GROUP")
    return true
end

function API.DeleteGroup(groupName)
    if not API.CanEdit() then return false, "Solo DM." end
    local store = EnsureStore()
    groupName = Trim(groupName or "")
    if groupName == "" then return false, "Nombre invalido." end
    for _, faction in pairs(store.factions or {}) do
        local g = Trim(faction.group or "")
        if g == "" then g = DEFAULT_GROUP end
        if g == groupName then
            return false, "No se puede borrar un grupo con facciones dentro. Muevelas o borralas primero."
        end
    end
    store.groups[groupName] = nil
    FireChanged("GROUP")
    return true
end

function API.DeleteSubgroup(groupName, subgroupName)
    if not API.CanEdit() then return false, "Solo DM." end
    local store = EnsureStore()
    groupName    = Trim(groupName or "")
    subgroupName = Trim(subgroupName or "")
    if groupName == "" or subgroupName == "" then return false, "Nombre invalido." end
    for _, faction in pairs(store.factions or {}) do
        local g = Trim(faction.group or "")
        if g == "" then g = DEFAULT_GROUP end
        if g == groupName and Trim(faction.subgroup or "") == subgroupName then
            faction.subgroup = ""
        end
    end
    local groupData = store.groups[groupName]
    if groupData and type(groupData.subgroups) == "table" then
        for i, sub in ipairs(groupData.subgroups) do
            if sub == subgroupName then
                table.remove(groupData.subgroups, i)
                break
            end
        end
        if type(groupData.subgroupOrder) == "table" then
            groupData.subgroupOrder[subgroupName] = nil
        end
    end
    FireChanged("GROUP")
    return true
end

-- Intercambia el sortOrder de dos facciones (para botones ↑/↓ del panel GM)
function API.MoveGroupOrder(groupName, direction)
    if not API.CanEdit() then return false, "Solo DM." end
    groupName = Trim(groupName or "")
    direction = tonumber(direction) or 0
    if groupName == "" or direction == 0 then return false, "Datos invalidos." end

    local store = EnsureStore()
    local groups = API.GetGroups()
    for index, groupData in ipairs(groups) do
        local record = EnsureGroupRecord(store, groupData.name)
        record.sortOrder = index * 10
    end

    local currentIndex
    for index, groupData in ipairs(groups) do
        if groupData.name == groupName then
            currentIndex = index
            break
        end
    end
    if not currentIndex then return false, "Grupo no encontrado." end

    local targetIndex = currentIndex + (direction < 0 and -1 or 1)
    if targetIndex < 1 or targetIndex > #groups then return false, "No se puede mover mas." end

    local current = EnsureGroupRecord(store, groups[currentIndex].name)
    local target = EnsureGroupRecord(store, groups[targetIndex].name)
    current.sortOrder, target.sortOrder = target.sortOrder, current.sortOrder
    FireChanged("GROUP")
    return true
end

function API.MoveSubgroupOrder(groupName, subgroupName, direction)
    if not API.CanEdit() then return false, "Solo DM." end
    groupName = Trim(groupName or "")
    subgroupName = Trim(subgroupName or "")
    direction = tonumber(direction) or 0
    if groupName == "" or subgroupName == "" or direction == 0 then return false, "Datos invalidos." end

    local store = EnsureStore()
    local groupData = EnsureGroupRecord(store, groupName)
    local subgroups = {}
    for _, sub in ipairs(groupData.subgroups or {}) do
        sub = Trim(sub)
        if sub ~= "" then subgroups[#subgroups + 1] = sub end
    end
    table.sort(subgroups, function(a, b)
        local oa = tonumber(groupData.subgroupOrder and groupData.subgroupOrder[a]) or 0
        local ob = tonumber(groupData.subgroupOrder and groupData.subgroupOrder[b]) or 0
        if oa ~= ob then return oa < ob end
        return tostring(a) < tostring(b)
    end)
    for index, sub in ipairs(subgroups) do
        groupData.subgroupOrder[sub] = index * 10
    end

    local currentIndex
    for index, sub in ipairs(subgroups) do
        if sub == subgroupName then
            currentIndex = index
            break
        end
    end
    if not currentIndex then return false, "Seccion no encontrada." end

    local targetIndex = currentIndex + (direction < 0 and -1 or 1)
    if targetIndex < 1 or targetIndex > #subgroups then return false, "No se puede mover mas." end

    local targetSub = subgroups[targetIndex]
    groupData.subgroupOrder[subgroupName], groupData.subgroupOrder[targetSub] =
        groupData.subgroupOrder[targetSub], groupData.subgroupOrder[subgroupName]
    FireChanged("GROUP")
    return true
end

function API.SwapFactionOrder(factionIdA, factionIdB)
    if not API.CanEdit() then return false, "Solo DM." end
    local fa = API.GetFaction(factionIdA)
    local fb = API.GetFaction(factionIdB)
    if not fa or not fb then return false, "Faccion no encontrada." end
    local oa = tonumber(fa.sortOrder) or 0
    local ob = tonumber(fb.sortOrder) or 0
    fa.sortOrder = ob
    fb.sortOrder = oa
    FireChanged("FACTION", factionIdA)
    return true
end

function API.SetFactionSortOrder(factionId, order)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    faction.sortOrder = tonumber(order) or 0
    FireChanged("FACTION", factionId)
    return true
end

function API.MoveFactionOrder(factionId, direction)
    if not API.CanEdit() then return false, "Solo DM." end
    direction = tonumber(direction) or 0
    if direction == 0 then return false, "Direccion invalida." end

    local factions = API.GetFactions(true)
    for index, faction in ipairs(factions) do
        faction.sortOrder = index
    end

    local currentIndex
    for index, faction in ipairs(factions) do
        if faction.id == factionId then
            currentIndex = index
            break
        end
    end
    if not currentIndex then return false, "Reputacion no encontrada." end

    local targetIndex = currentIndex + (direction < 0 and -1 or 1)
    if targetIndex < 1 or targetIndex > #factions then return false, "No se puede mover mas." end

    local current = factions[currentIndex]
    local target = factions[targetIndex]
    current.sortOrder, target.sortOrder = target.sortOrder, current.sortOrder
    FireChanged("FACTION", factionId)
    return true
end

function API.SetFactionHidden(factionId, hidden)
    if not API.CanEdit() then return false, "Solo DM." end
    local faction = API.GetFaction(factionId)
    if not faction then return false, "Reputacion no encontrada." end
    faction.hidden = hidden == true
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
    faction.icon = API.NormalizeIconName(data.icon or API.TABARD_ICON)
    faction.color = tostring(data.color or "ffe0e0e0")
    faction.epsilonFactionId = API.NormalizeEpsilonFactionId(data.epsilonFactionId)
    faction.group = Trim(data.group)
    if faction.group == "" then faction.group = DEFAULT_GROUP end
    faction.subgroup = Trim(data.subgroup)
    faction.hidden = data.hidden == true
    if data.sortOrder ~= nil then
        faction.sortOrder = tonumber(data.sortOrder) or 0
    end
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
    entry.reps[factionId].atWar = API.IsAtWarPoints(points)

    if opts and opts.guildName and opts.guildName ~= "" then
        entry.guild = opts.guildName
        local guild = EnsureGuildEntry(opts.guildName)
        if guild then
            guild.reps[factionId] = guild.reps[factionId] or {}
            guild.reps[factionId].points = points
            guild.reps[factionId].visible = true
            guild.reps[factionId].atWar = API.IsAtWarPoints(points)
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
    local playerKey = API.RememberPlayerGuild("target")
    if not playerKey then return false, "Jugador invalido." end
    if not HarfordReputationSync or not HarfordReputationSync.BroadcastRepPoints then
        return false, "Sync no disponible."
    end
    -- Calcular el nuevo valor a partir de lo que haya en memoria (sin escribirlo
    -- en el store del DM — los puntos de otros jugadores no se persisten aquí).
    local current   = API.GetPlayerPoints(playerKey, factionId)
    local newPoints = Clamp(current + (tonumber(delta) or 0), API.MIN_POINTS, API.MAX_POINTS)
    local sent = HarfordReputationSync.BroadcastRepPoints(playerKey, factionId, newPoints)
    if not sent then
        return false, "No hay canal de grupo/raid activo; el target debe estar en el mismo grupo."
    end
    local faction = API.GetFaction(factionId)
    local verb = (tonumber(delta) or 0) >= 0 and "subio" or "bajo"
    API.AddLog("GM " .. verb .. " " .. tostring(delta) .. " reputacion a " .. playerKey .. " con " .. tostring(faction and faction.name or factionId) .. ".")
    return true
end

function API.ResetTarget(factionId)
    if not UnitExists or not UnitExists("target") or not UnitIsPlayer or not UnitIsPlayer("target") then
        return false, "Selecciona un jugador objetivo."
    end
    local playerKey = API.RememberPlayerGuild("target")
    if not playerKey then return false, "Jugador invalido." end
    if not HarfordReputationSync or not HarfordReputationSync.BroadcastRepPoints then
        return false, "Sync no disponible."
    end
    local sent = HarfordReputationSync.BroadcastRepPoints(playerKey, factionId, 0)
    if not sent then
        return false, "No hay canal de grupo/raid activo; el target debe estar en el mismo grupo."
    end
    local faction = API.GetFaction(factionId)
    API.AddLog("GM reinicio reputacion de " .. playerKey .. " con " .. tostring(faction and faction.name or factionId) .. ".")
    return true
end

function API.SetTargetPoints(factionId, points)
    if not UnitExists or not UnitExists("target") or not UnitIsPlayer or not UnitIsPlayer("target") then
        return false, "Selecciona un jugador objetivo."
    end
    local playerKey = API.RememberPlayerGuild("target")
    if not playerKey then return false, "Jugador invalido." end
    if not HarfordReputationSync or not HarfordReputationSync.BroadcastRepPoints then
        return false, "Sync no disponible."
    end
    local newPoints = Clamp(tonumber(points) or 0, API.MIN_POINTS, API.MAX_POINTS)
    local sent = HarfordReputationSync.BroadcastRepPoints(playerKey, factionId, newPoints)
    if not sent then
        return false, "No hay canal de grupo/raid activo."
    end
    local faction = API.GetFaction(factionId)
    API.AddLog("GM ajusto reputacion de " .. playerKey .. " con " .. tostring(faction and faction.name or factionId) .. " a " .. tostring(newPoints) .. ".")
    return true
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
