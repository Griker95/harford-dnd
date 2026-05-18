-- Visual initiative tracker for Harford.

HarfordTurnOrderStore = HarfordTurnOrderStore or {}

local COMM_PREFIX = "HARFORDTURN"
local TURN_SINGLE_MESSAGE_LIMIT = 230
local TURN_CHUNK_ENCODED_LIMIT = 170
local TURN_MAX_CHUNKS = 80
local MAX_CARDS = 6
local CARD_W = 70
local CARD_GAP = 6
local CARD_H = 122
local TEX_MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
local TEX_WHITE = "Interface\\Buttons\\WHITE8x8"
local TEX_STATUS = "Interface\\TargetingFrame\\UI-StatusBar"
local ROUND_MARKER_ID = "HARFORD_ROUND_MARKER"

local TurnFrame
local SheetFrame
local SheetScrollChild
local SheetText
local StatusText
local RefreshFrame
local MarkChanged
local suppressBroadcast = false
local broadcastPending = false
local viewStart = 1
local editMode = false
local lastTurnAlertKey = ""
local lastTurnNoticeKey = ""
local lastRoundAlertKey = ""
local turnChunkBuffers = {}
local NormalizeIconPath
local NormalizePlayerUnitID
local NormalizeEntryLinks

local function StripColors(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    return text
end

local function ExtractColorHex(text)
    return tostring(text or ""):match("|cff(%x%x%x%x%x%x)")
end

local function NormalizeColorHex(hex)
    hex = tostring(hex or ""):gsub("#", ""):gsub("|cff", "")
    hex = hex:match("^(%x%x%x%x%x%x)")
    return hex and hex:lower() or nil
end

local function HexToRGB(hex)
    hex = NormalizeColorHex(hex)
    if not hex then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return nil end
    return r / 255, g / 255, b / 255
end

local function GetReactionColor(reaction)
    reaction = tonumber(reaction) or 0
    if reaction <= 0 then return nil end

    if reaction <= 2 then
        return 1.0, 0.12, 0.12, "hostile"
    elseif reaction == 3 then
        return 1.0, 0.48, 0.10, "unfriendly"
    elseif reaction == 4 then
        return 1.0, 0.82, 0.10, "neutral"
    end

    return 0.10, 1.0, 0.10, "friendly"
end

local function EntryIconMarkup(entry, size)
    local icon = tostring(entry and entry.icon or "")
    if icon ~= "" and not tonumber(icon) and not icon:find("\\", 1, true) and not icon:find("/", 1, true) then
        icon = "Interface\\Icons\\" .. icon
    end
    if not icon or icon == "" then return "" end
    size = tonumber(size) or 24
    return "|T" .. icon .. ":" .. tostring(size) .. ":" .. tostring(size) .. ":0:0|t "
end

local function GetEntryNameColor(entry)
    if not entry then return 1, 1, 1 end
    if entry.kind == "round" then return 1.0, 0.82, 0.1 end
    if entry.kind == "player" then
        local r, g, b = HexToRGB(entry.nameColor)
        return r or 0.1, g or 1.0, b or 0.1
    end

    local r, g, b = GetReactionColor(entry.reaction)
    return r or 1.0, g or 0.1, b or 0.1
end

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[D&D]|r " .. tostring(msg or ""))
end

local function GetMyName()
    local fullName = GetUnitName and GetUnitName("player", true)
    if fullName and fullName ~= "" then return fullName end
    return UnitName("player") or "Jugador"
end

local function GetEntryNameForChat(entry)
    local name = tostring(entry and entry.name or "?")
    if entry and entry.kind == "round" then
        return "|cffffff00" .. name .. "|r"
    end
    if entry and entry.kind == "player" then
        return "|cff00ff00" .. name .. "|r"
    end
    return "|cffff3333D&D (" .. name .. ")|r"
end

local function PrintTurn(entry)
    if not entry then return end
    if entry.kind == "round" then
        Print("|cffffff00" .. tostring(entry.name or "Inicio del turno - Estados") .. "|r")
        return
    end
    if entry.kind == "player" then
        Print("Turno de " .. GetEntryNameForChat(entry) .. ".")
    else
        Print("Turno enemigo: " .. GetEntryNameForChat(entry) .. ".")
    end
end

local function EntryBelongsToMe(entry)
    if not entry or entry.kind ~= "player" then return false end

    local myShort = UnitName and UnitName("player")
    local myFull = GetUnitName and GetUnitName("player", true)
    local names = {
        tostring(entry.unitName or ""),
        tostring(entry.name or ""),
        tostring(entry.trpUnitID or ""),
    }

    for _, name in ipairs(names) do
        if name ~= "" then
            local short = Ambiguate and Ambiguate(name, "short") or name:match("^[^-]+")
            if (myFull and name == myFull) or (myShort and (name == myShort or short == myShort)) then
                return true
            end
        end
    end

    return false
end

local function IsSenderSelf(sender)
    sender = tostring(sender or "")
    if sender == "" then return false end

    local myShort = UnitName and UnitName("player")
    local myFull = GetUnitName and GetUnitName("player", true)
    local senderShort = Ambiguate and Ambiguate(sender, "short") or sender:match("^[^-]+")

    return (myFull and sender == myFull)
        or (myShort and (sender == myShort or senderShort == myShort))
end

local function AlertMyTurn(entry, activeIndex, turnSerial)
    if not EntryBelongsToMe(entry) then return end

    local serial = tonumber(turnSerial) or (HarfordTurnOrderStore and tonumber(HarfordTurnOrderStore.turnSerial)) or 0
    local key
    if serial > 0 then
        key = "serial:" .. tostring(serial) .. ":" .. tostring(entry.id or "") .. ":" .. tostring(entry.name or "")
    else
        key = tostring(activeIndex or 0) .. ":" .. tostring(entry.id or "") .. ":" .. tostring(entry.name or "")
    end
    if key == lastTurnAlertKey then return end
    lastTurnAlertKey = key

    local text = "ES TU TURNO"
    if RaidNotice_AddMessage and RaidWarningFrame then
        local info = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"]
        RaidNotice_AddMessage(RaidWarningFrame, text, info)
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
    Print(text .. ": " .. tostring(entry.name or "Jugador"))
end

local function AlertRoundStates(entry, activeIndex, turnSerial)
    if not entry or entry.kind ~= "round" then return end

    local serial = tonumber(turnSerial) or (HarfordTurnOrderStore and tonumber(HarfordTurnOrderStore.turnSerial)) or 0
    local key
    if serial > 0 then
        key = "round:" .. tostring(serial)
    else
        key = "round:" .. tostring(activeIndex or 0) .. ":" .. tostring(entry.id or "") .. ":" .. tostring(entry.name or "")
    end
    if key == lastRoundAlertKey then return end
    lastRoundAlertKey = key

    local text = "ESTADOS"
    if RaidNotice_AddMessage and RaidWarningFrame then
        local info = ChatTypeInfo and ChatTypeInfo["RAID_WARNING"]
        RaidNotice_AddMessage(RaidWarningFrame, text, info)
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
    Print("|cffffff00" .. text .. "|r: " .. tostring(entry.name or "Inicio del turno - Estados"))
end

local function EnsureStore()
    if type(HarfordTurnOrderStore) ~= "table" then HarfordTurnOrderStore = {} end
    if type(HarfordTurnOrderStore.entries) ~= "table" then HarfordTurnOrderStore.entries = {} end
    HarfordTurnOrderStore.activeIndex = tonumber(HarfordTurnOrderStore.activeIndex) or 1
    HarfordTurnOrderStore.adminName = tostring(HarfordTurnOrderStore.adminName or "")
    HarfordTurnOrderStore.turnSerial = tonumber(HarfordTurnOrderStore.turnSerial) or 0
    if HarfordTurnOrderStore.activeIndex < 1 then HarfordTurnOrderStore.activeIndex = 1 end
    return HarfordTurnOrderStore
end

local function AdvanceTurnSerial()
    local store = EnsureStore()
    store.turnSerial = (tonumber(store.turnSerial) or 0) + 1
    return store.turnSerial
end

local function IsTurnAdmin()
    local hasAdmin = false
    local dmMode = false

    if HarfordAuthority then
        if HarfordAuthority.HasAdminAddon then
            hasAdmin = HarfordAuthority.HasAdminAddon() == true
        end
        if HarfordAuthority.IsDMMode then
            dmMode = HarfordAuthority.IsDMMode() == true
        end
    else
        hasAdmin = HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true
        if ARC and ARC.PHASE and type(ARC.PHASE.IsDM) == "function" then
            local ok, value = pcall(ARC.PHASE.IsDM)
            dmMode = ok and value == true
        elseif C_Epsilon then
            if C_Epsilon.IsDM == true then
                dmMode = true
            elseif type(C_Epsilon.IsDM) == "function" then
                local ok, value = pcall(C_Epsilon.IsDM)
                dmMode = ok and value == true
            end
        end
    end

    return hasAdmin and dmMode
end

local function ClaimAdminIfNeeded()
    local store = EnsureStore()
    if tostring(store.adminName or "") == "" then
        store.adminName = GetMyName()
    end
end

local function ClampActiveIndex()
    local store = EnsureStore()
    local count = #store.entries
    if count == 0 then store.activeIndex = 1 return end
    if store.activeIndex > count then store.activeIndex = 1 end
    if store.activeIndex < 1 then store.activeIndex = count end
end

local function ClampViewStart()
    local store = EnsureStore()
    local count = #store.entries
    local maxStart = math.max(1, count - MAX_CARDS + 1)
    viewStart = tonumber(viewStart) or 1
    if viewStart < 1 then viewStart = 1 end
    if viewStart > maxStart then viewStart = maxStart end
    return viewStart
end

local function EnsureActiveVisible()
    local store = EnsureStore()
    ClampActiveIndex()
    local active = tonumber(store.activeIndex) or 1
    if active < viewStart then
        viewStart = active
    elseif active >= viewStart + MAX_CARDS then
        viewStart = active - MAX_CARDS + 1
    end
    ClampViewStart()
end

local function ScrollView(delta)
    viewStart = viewStart + (tonumber(delta) or 0)
    ClampViewStart()
    if RefreshFrame then RefreshFrame() end
end

local function UpdateEditButton()
    if TurnFrame and TurnFrame.editButton then
        TurnFrame.editButton:SetText(editMode and "Listo" or "Editar")
    end
end

local function ToggleEditMode()
    if not IsTurnAdmin() then Print("Solo el admin puede editar los turnos.") return end
    editMode = not editMode
    UpdateEditButton()
    if RefreshFrame then RefreshFrame() end
end

local function MoveEntry(index, delta)
    if not IsTurnAdmin() then Print("Solo el admin puede editar los turnos.") return end
    ClaimAdminIfNeeded()

    local store = EnsureStore()
    local fromIndex = tonumber(index)
    local toIndex = fromIndex and (fromIndex + (tonumber(delta) or 0)) or nil
    if not fromIndex or not toIndex then return end
    if fromIndex < 1 or fromIndex > #store.entries or toIndex < 1 or toIndex > #store.entries then return end
    if fromIndex == toIndex then return end

    store.entries[fromIndex], store.entries[toIndex] = store.entries[toIndex], store.entries[fromIndex]
    if store.activeIndex == fromIndex then
        store.activeIndex = toIndex
    elseif store.activeIndex == toIndex then
        store.activeIndex = fromIndex
    end

    EnsureActiveVisible()
    MarkChanged()
end

local function FindDuplicateEntry(candidate)
    if type(candidate) ~= "table" then return nil end

    NormalizeEntryLinks(candidate)

    local candidateId = tostring(candidate.id or "")
    local candidateUnitName = tostring(candidate.unitName or "")
    local candidateName = tostring(candidate.name or "")
    local candidateTrpUnitID = NormalizePlayerUnitID(candidate.trpUnitID or "")
    local candidateShort = Ambiguate and Ambiguate(candidateUnitName ~= "" and candidateUnitName or candidateName, "short")

    local store = EnsureStore()
    for i, entry in ipairs(store.entries or {}) do
        if entry and entry.kind ~= "round" then
            NormalizeEntryLinks(entry)

            if candidateId ~= "" and tostring(entry.id or "") == candidateId then
                return entry, i
            end

            if candidate.kind == "player" and entry.kind == "player" then
                local entryTrpUnitID = NormalizePlayerUnitID(entry.trpUnitID or "")
                if candidateTrpUnitID ~= "" and entryTrpUnitID ~= "" and candidateTrpUnitID == entryTrpUnitID then
                    return entry, i
                end

                local entryUnitName = tostring(entry.unitName or "")
                local entryName = tostring(entry.name or "")
                local entryShort = Ambiguate and Ambiguate(entryUnitName ~= "" and entryUnitName or entryName, "short")
                if candidateUnitName ~= "" and entryUnitName ~= "" and candidateUnitName == entryUnitName then
                    return entry, i
                end
                if candidateShort and entryShort and candidateShort == entryShort then
                    return entry, i
                end
            end
        end
    end

    return nil
end

local function EnsureRoundMarker()
    local store = EnsureStore()
    for i = 1, #store.entries do
        local entry = store.entries[i]
        if entry and entry.kind == "round" then
            entry.id = ROUND_MARKER_ID
            entry.name = "Inicio del turno - Estados"
            entry.initiative = tonumber(entry.initiative) or 999
            entry.hp = 0
            entry.maxHp = 0
            entry.mana = 0
            entry.maxMana = 0
            return entry
        end
    end

    local marker = {
        id = ROUND_MARKER_ID,
        name = "Inicio del turno - Estados",
        kind = "round",
        initiative = 999,
        hp = 0,
        maxHp = 0,
        mana = 0,
        maxMana = 0,
        unitName = ROUND_MARKER_ID,
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        displayId = 0,
    }

    table.insert(store.entries, 1, marker)
    return marker
end

local function NewId()
    return tostring(time and time() or 0) .. tostring(random(100000, 999999))
end

local function SafeNumber(value, default)
    local n = tonumber(value)
    if n == nil then return default or 0 end
    return n
end

local function EscapeText(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub("|", "%%7C")
    value = value:gsub(";", "%%3B")
    value = value:gsub(",", "%%2C")
    return value
end

local function UnescapeText(value)
    value = tostring(value or "")
    value = value:gsub("%%2C", ",")
    value = value:gsub("%%3B", ";")
    value = value:gsub("%%7C", "|")
    value = value:gsub("%%25", "%%")
    return value
end

NormalizePlayerUnitID = function(value)
    value = tostring(value or "")
    if value == "" then return "" end
    if value:find("-", 1, true) then return value end

    local realm = GetRealmName and GetRealmName()
    realm = tostring(realm or ""):gsub("%s+", "")
    if realm == "" then return value end
    return value .. "-" .. realm
end

NormalizeEntryLinks = function(entry)
    if type(entry) ~= "table" then return entry end

    entry.kind = tostring(entry.kind or "npc")
    if entry.kind == "round" then return entry end

    entry.npcId = tostring(entry.npcId or "")
    entry.phaseId = tostring(entry.phaseId or "")
    entry.trpFullID = tostring(entry.trpFullID or "")
    entry.trpUnitID = tostring(entry.trpUnitID or "")
    entry.trpProfileID = tostring(entry.trpProfileID or "")
    entry.unitName = tostring(entry.unitName or entry.name or "")
    entry.icon = NormalizeIconPath(entry.icon) or tostring(entry.icon or "")
    entry.nameColor = NormalizeColorHex(entry.nameColor)

    if entry.kind == "player" then
        if entry.trpUnitID == "" then
            entry.trpUnitID = NormalizePlayerUnitID(entry.unitName ~= "" and entry.unitName or entry.name)
        end
        return entry
    end

    if entry.trpFullID == "" and entry.phaseId ~= "" and entry.npcId ~= "" then
        entry.trpFullID = entry.phaseId .. "_" .. entry.npcId
    elseif entry.trpFullID ~= "" and (entry.phaseId == "" or entry.npcId == "") then
        local phaseId, npcId = entry.trpFullID:match("^([^_]+)_(.+)$")
        if phaseId and npcId then
            if entry.phaseId == "" then entry.phaseId = phaseId end
            if entry.npcId == "" then entry.npcId = npcId end
        end
    end

    return entry
end

local function SerializeEntry(entry)
    NormalizeEntryLinks(entry)
    return table.concat({
        EscapeText(entry.id),
        EscapeText(entry.name),
        EscapeText(entry.kind),
        tostring(entry.initiative or 0),
        tostring(entry.hp or 0),
        tostring(entry.maxHp or 0),
        entry.hidden and "1" or "0",
        tostring(entry.mana or 0),
        tostring(entry.maxMana or 0),
        EscapeText(entry.unitName),
        EscapeText(entry.icon),
        tostring(entry.displayId or 0),
        EscapeText(entry.npcId),
        EscapeText(entry.phaseId),
        EscapeText(entry.trpFullID),
        EscapeText(entry.trpUnitID),
        tostring(entry.reaction or 0),
        EscapeText(entry.nameColor),
        EscapeText(entry.trpProfileID),
    }, ",")
end

local function DeserializeEntry(raw)
    local id, name, kind, init, hp, maxHp, hidden, mana, maxMana, unitName, icon, displayId, npcId, phaseId, trpFullID, trpUnitID, reaction, nameColor, trpProfileID = strsplit(",", raw or "")
    if not name or name == "" then return nil end
    return NormalizeEntryLinks({
        id = UnescapeText(id),
        name = UnescapeText(name),
        kind = UnescapeText(kind or "npc"),
        initiative = SafeNumber(init, 0),
        hp = SafeNumber(hp, 0),
        maxHp = SafeNumber(maxHp, 0),
        hidden = hidden == "1",
        mana = SafeNumber(mana, 0),
        maxMana = SafeNumber(maxMana, 0),
        unitName = UnescapeText(unitName),
        icon = UnescapeText(icon),
        displayId = SafeNumber(displayId, 0),
        npcId = UnescapeText(npcId),
        phaseId = UnescapeText(phaseId),
        trpFullID = UnescapeText(trpFullID),
        trpUnitID = UnescapeText(trpUnitID),
        reaction = SafeNumber(reaction, 0),
        nameColor = NormalizeColorHex(UnescapeText(nameColor)),
        trpProfileID = UnescapeText(trpProfileID),
    })
end

local function SerializeState()
    local store = EnsureStore()
    local parts = {}
    for i = 1, #store.entries do
        NormalizeEntryLinks(store.entries[i])
        parts[#parts + 1] = SerializeEntry(store.entries[i])
    end
    return "STATE|" .. tostring(store.activeIndex or 1) .. "|" .. EscapeText(store.adminName or "") .. "|" .. table.concat(parts, ";")
end

local function SerializeTurnNoticeEntry(entry)
    entry = NormalizeEntryLinks(entry or {}) or {}
    return table.concat({
        EscapeText(entry.id),
        EscapeText(entry.name),
        EscapeText(entry.kind),
        EscapeText(entry.unitName),
        EscapeText(entry.trpUnitID),
    }, ",")
end

local function DeserializeTurnNoticeEntry(raw)
    local id, name, kind, unitName, trpUnitID = strsplit(",", raw or "")
    if not name or name == "" then return nil end
    return NormalizeEntryLinks({
        id = UnescapeText(id),
        name = UnescapeText(name),
        kind = UnescapeText(kind or "npc"),
        unitName = UnescapeText(unitName),
        trpUnitID = UnescapeText(trpUnitID),
    })
end

local function SerializeTurnNotice()
    local store = EnsureStore()
    local index = tonumber(store.activeIndex) or 1
    local entry = store.entries[index]
    if not entry then return nil end

    return table.concat({
        "TURN",
        tostring(store.turnSerial or 0),
        tostring(index),
        tostring(#store.entries),
        EscapeText(store.adminName or ""),
        SerializeTurnNoticeEntry(entry),
    }, "|")
end

local function PrintTurnNotice(entry, activeIndex, count, turnSerial)
    if not entry then return end

    local noticeKey = tostring(turnSerial or 0) .. ":" .. tostring(activeIndex or 0) .. ":" .. tostring(entry.id or "") .. ":" .. tostring(entry.name or "")
    if noticeKey == lastTurnNoticeKey then return end
    lastTurnNoticeKey = noticeKey

    if count and count > 0 then
        Print("Turno " .. tostring(activeIndex or 0) .. " / " .. tostring(count) .. ": " .. GetEntryNameForChat(entry) .. ".")
    else
        PrintTurn(entry)
    end
end

local function ApplyTurnNotice(message)
    local opcode, serialRaw, activeRaw, countRaw, adminRaw, entryRaw = strsplit("|", message or "")
    if opcode ~= "TURN" then return false end

    local serial = SafeNumber(serialRaw, 0)
    local activeIndex = SafeNumber(activeRaw, 1)
    local count = SafeNumber(countRaw, 0)
    local noticeEntry = DeserializeTurnNoticeEntry(entryRaw)
    if not noticeEntry then return false end

    local store = EnsureStore()
    if adminRaw ~= nil then
        local adminName = UnescapeText(adminRaw)
        if adminName ~= "" then store.adminName = adminName end
    end
    if serial > (tonumber(store.turnSerial) or 0) then
        store.turnSerial = serial
    end

    local entry = noticeEntry
    if activeIndex >= 1 and activeIndex <= #store.entries then
        store.activeIndex = activeIndex
        entry = store.entries[activeIndex] or noticeEntry
        if entry and noticeEntry.id and noticeEntry.id ~= "" and tostring(entry.id or "") ~= tostring(noticeEntry.id) then
            entry = noticeEntry
        end
        EnsureActiveVisible()
    end

    PrintTurnNotice(entry, activeIndex, count, serial)
    AlertRoundStates(entry, activeIndex, serial)
    AlertMyTurn(entry, activeIndex, serial)
    return true
end

local function ApplySerializedState(message)
    local opcode, activeRaw, third, fourth = strsplit("|", message or "")
    if opcode ~= "STATE" then return false end

    local store = EnsureStore()
    store.entries = {}
    store.activeIndex = SafeNumber(activeRaw, 1)
    if fourth ~= nil then store.adminName = UnescapeText(third) end

    local entriesRaw = fourth or third
    if entriesRaw and entriesRaw ~= "" then
        for token in string.gmatch(entriesRaw, "[^;]+") do
            local entry = DeserializeEntry(token)
            if entry then store.entries[#store.entries + 1] = entry end
        end
    end

    ClampActiveIndex()
    EnsureRoundMarker()
    ClampActiveIndex()
    EnsureActiveVisible()
    return true
end

local function EscapeChunkChar(char)
    if char == "%" then return "%25" end
    if char == "|" then return "%7C" end
    return char
end

local function UnescapeChunk(value)
    value = tostring(value or "")
    value = value:gsub("%%7C", "|")
    value = value:gsub("%%25", "%%")
    return value
end

local function SplitEscapedChunks(payload)
    payload = tostring(payload or "")
    local chunks = {}
    local current = ""
    local currentSize = 0

    for i = 1, #payload do
        local encoded = EscapeChunkChar(payload:sub(i, i))
        if currentSize > 0 and (currentSize + #encoded) > TURN_CHUNK_ENCODED_LIMIT then
            chunks[#chunks + 1] = current
            current = ""
            currentSize = 0
        end
        current = current .. encoded
        currentSize = currentSize + #encoded
    end

    if current ~= "" or #chunks == 0 then
        chunks[#chunks + 1] = current
    end

    return chunks
end

local function SendSerializedState(payload, channel)
    if #payload <= TURN_SINGLE_MESSAGE_LIMIT then
        HarfordSync.Send(COMM_PREFIX, payload, channel)
        return true
    end

    local chunks = SplitEscapedChunks(payload)
    if #chunks > TURN_MAX_CHUNKS then
        Print("No se pudo compartir turnos: estado demasiado grande.")
        return false
    end

    local transferId = NewId()
    for i = 1, #chunks do
        HarfordSync.Send(COMM_PREFIX, "SCHUNK|" .. transferId .. "|" .. tostring(i) .. "|" .. tostring(#chunks) .. "|" .. chunks[i], channel)
    end
    return true
end

local function ApplyChunkedState(message, sender)
    local transferId, indexRaw, totalRaw, chunk = tostring(message or ""):match("^SCHUNK|([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if not transferId or transferId == "" then return false end

    local index = tonumber(indexRaw)
    local total = tonumber(totalRaw)
    if not index or not total or total < 1 or total > TURN_MAX_CHUNKS or index < 1 or index > total then
        return false
    end

    local key = tostring(sender or "?") .. ":" .. transferId
    local buffer = turnChunkBuffers[key]
    if not buffer or buffer.total ~= total then
        buffer = { total = total, received = 0, chunks = {} }
        turnChunkBuffers[key] = buffer
        if C_Timer and C_Timer.After then
            C_Timer.After(15, function()
                if turnChunkBuffers[key] == buffer then
                    turnChunkBuffers[key] = nil
                end
            end)
        end
    end

    if not buffer.chunks[index] then
        buffer.chunks[index] = UnescapeChunk(chunk)
        buffer.received = buffer.received + 1
    end

    if buffer.received < total then return false end

    local assembled = {}
    for i = 1, total do
        if not buffer.chunks[i] then return false end
        assembled[i] = buffer.chunks[i]
    end

    turnChunkBuffers[key] = nil
    return ApplySerializedState(table.concat(assembled))
end

local function ApplyTurnMessage(message, sender)
    local opcode = tostring(message or ""):match("^([^|]+)")
    if opcode == "STATE" then
        return ApplySerializedState(message)
    elseif opcode == "SCHUNK" then
        return ApplyChunkedState(message, sender)
    elseif opcode == "TURN" then
        return ApplyTurnNotice(message)
    end
    return false
end

local function SendState()
    if not IsTurnAdmin() then return false end
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not ch then return false end
    return SendSerializedState(SerializeState(), ch)
end

local function SendTurnNotice()
    if not IsTurnAdmin() then return false end
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not ch then return false end

    local payload = SerializeTurnNotice()
    if not payload then return false end
    if #payload > TURN_SINGLE_MESSAGE_LIMIT then
        Print("No se pudo anunciar el turno: mensaje demasiado grande.")
        return false
    end

    HarfordSync.Send(COMM_PREFIX, payload, ch)
    return true
end

local function ScheduleBroadcast()
    if suppressBroadcast or broadcastPending then return end
    broadcastPending = true
    local function sendLater()
        broadcastPending = false
        SendState()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.15, sendLater) else sendLater() end
end

MarkChanged = function()
    if RefreshFrame then RefreshFrame() end
    ScheduleBroadcast()
end

local function SetFrameBackground(frame)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -13)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 7)
    bg:SetTexture(TEX_MARBLE)
    bg:SetAlpha(0.94)
    return bg
end

local function MakeSheetLine(parent, point, rel, relPoint, x, y, width, height, r, g, b, a)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetTexture(TEX_WHITE)
    line:SetVertexColor(r, g, b, a or 1)
    line:SetSize(width, height)
    line:SetPoint(point, rel, relPoint, x, y)
    return line
end

local function MakeButton(parent, text, w, h, point, rel, relPoint, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetPoint(point, rel, relPoint, x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function CreateSheetFrame()
    if SheetFrame then return end

    SheetFrame = CreateFrame("Frame", "HarfordTurnSheetFrame", UIParent, "BackdropTemplate")
    SheetFrame:SetSize(492, 548)
    SheetFrame:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
    SheetFrame:SetFrameStrata("DIALOG")
    SheetFrame:SetMovable(true)
    SheetFrame:EnableMouse(true)
    SheetFrame:RegisterForDrag("LeftButton")
    SheetFrame:SetScript("OnDragStart", SheetFrame.StartMoving)
    SheetFrame:SetScript("OnDragStop", SheetFrame.StopMovingOrSizing)
    SheetFrame:Hide()
    local outerBg = SheetFrame:CreateTexture(nil, "BACKGROUND")
    outerBg:SetPoint("TOPLEFT", SheetFrame, "TOPLEFT", 7, -13)
    outerBg:SetPoint("BOTTOMRIGHT", SheetFrame, "BOTTOMRIGHT", -7, 7)
    outerBg:SetTexture(TEX_WHITE)
    outerBg:SetVertexColor(0.06, 0.015, 0.012, 0.96)

    local panelBg = SheetFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    panelBg:SetPoint("TOPLEFT", SheetFrame, "TOPLEFT", 19, -78)
    panelBg:SetPoint("BOTTOMRIGHT", SheetFrame, "BOTTOMRIGHT", -29, 19)
    panelBg:SetTexture(TEX_WHITE)
    panelBg:SetVertexColor(0.006, 0.006, 0.006, 0.92)

    local border = CreateFrame("Frame", nil, SheetFrame, "DialogBorderTemplate")
    border:SetAllPoints(SheetFrame)
    border:SetFrameStrata(SheetFrame:GetFrameStrata())
    border:SetFrameLevel(SheetFrame:GetFrameLevel() + 5)

    MakeSheetLine(SheetFrame, "TOPLEFT", SheetFrame, "TOPLEFT", 19, -78, 444, 2, 0.78, 0.73, 0.66, 0.95)
    MakeSheetLine(SheetFrame, "BOTTOMLEFT", SheetFrame, "BOTTOMLEFT", 19, 19, 444, 2, 0.78, 0.73, 0.66, 0.95)
    MakeSheetLine(SheetFrame, "TOPLEFT", SheetFrame, "TOPLEFT", 19, -78, 2, 451, 0.78, 0.73, 0.66, 0.95)
    MakeSheetLine(SheetFrame, "TOPRIGHT", SheetFrame, "TOPRIGHT", -29, -78, 2, 451, 0.78, 0.73, 0.66, 0.95)

    SheetFrame.title = SheetFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    SheetFrame.title:SetPoint("TOPLEFT", 32, -31)
    SheetFrame.title:SetPoint("TOPRIGHT", -42, -31)
    SheetFrame.title:SetJustifyH("CENTER")
    SheetFrame.title:SetText("Ficha")
    if STANDARD_TEXT_FONT then
        SheetFrame.title:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    end

    local close = CreateFrame("Button", nil, SheetFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local scroll = CreateFrame("ScrollFrame", nil, SheetFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 42, -102)
    scroll:SetPoint("BOTTOMRIGHT", -44, 31)

    SheetScrollChild = CreateFrame("Frame", nil, scroll)
    SheetScrollChild:SetSize(382, 1)
    scroll:SetScrollChild(SheetScrollChild)

    SheetText = SheetScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SheetText:SetPoint("TOPLEFT", 0, 0)
    SheetText:SetWidth(370)
    SheetText:SetJustifyH("LEFT")
    SheetText:SetJustifyV("TOP")
    if STANDARD_TEXT_FONT then
        SheetText:SetFont(STANDARD_TEXT_FONT, 16, "")
    end
    SheetText:SetTextColor(1.0, 0.93, 0.82)
    SheetText:SetSpacing(6)
    SheetText:SetText("")
end

local function GetEntryTRP3Profile(entry)
    if not entry or not HarfordTRP3 then
        return nil, "HarfordTRP3 no disponible"
    end

    if entry.kind == "player" then
        local unitID = tostring(entry.trpUnitID or "")
        if unitID == "" then
            unitID = tostring(entry.unitName or "")
        end
        if unitID ~= "" and not unitID:find("-", 1, true) and GetRealmName then
            local realm = tostring(GetRealmName() or ""):gsub("%s+", "")
            if realm ~= "" then
                unitID = unitID .. "-" .. realm
            end
        end
        if unitID ~= "" and HarfordTRP3.GetPlayerProfileByUnitID then
            local profile = HarfordTRP3.GetPlayerProfileByUnitID(unitID)
            if profile then
                return profile, nil, unitID
            end
        end

        local units = { "player", "target", "mouseover", "focus" }
        for i = 1, 4 do units[#units + 1] = "party" .. tostring(i) end
        for i = 1, 40 do units[#units + 1] = "raid" .. tostring(i) end
        for _, unit in ipairs(units) do
            if UnitExists and UnitExists(unit) and UnitGUID and UnitGUID(unit) == entry.id and HarfordTRP3.GetPlayerProfile then
                return HarfordTRP3.GetPlayerProfile(unit)
            end
        end

        return nil, "Ficha TRP3 de jugador no disponible para esta entrada"
    end

    local fullID = tostring(entry.trpFullID or "")
    if fullID ~= "" and HarfordTRP3.GetEpsilonNpcProfileByFullID then
        return HarfordTRP3.GetEpsilonNpcProfileByFullID(fullID)
    end

    local profileID = tostring(entry.trpProfileID or "")
    if profileID ~= "" and HarfordTRP3.GetEpsilonNpcProfileByProfileID then
        local profile = HarfordTRP3.GetEpsilonNpcProfileByProfileID(profileID)
        if profile then return profile, nil, profileID end
    end

    if UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target") == entry.id and HarfordTRP3.GetEpsilonNpcProfile then
        return HarfordTRP3.GetEpsilonNpcProfile("target")
    end

    return nil, "Ficha TRP3 no disponible para esta entrada"
end

local function ShowEntrySheet(entry)
    if not entry or entry.kind == "round" then return end

    CreateSheetFrame()
    SheetFrame.title:SetText(EntryIconMarkup(entry, 26) .. tostring(entry.name or "Ficha"))
    SheetFrame.title:SetTextColor(GetEntryNameColor(entry))

    local profile, err = GetEntryTRP3Profile(entry)
    local text
    if profile and HarfordTRP3 and HarfordTRP3.BuildDisplayText then
        text = HarfordTRP3.BuildDisplayText(profile)
    elseif profile and HarfordTRP3 and HarfordTRP3.GetProfileMainText then
        text = HarfordTRP3.GetProfileMainText(profile)
    end

    if not text or text == "" then
        text = tostring(err or "No hay ficha TRP3 disponible para esta entrada.")
    end

    SheetText:SetText(text)
    SheetScrollChild:SetHeight(math.max(416, (SheetText:GetStringHeight() or 0) + 24))
    SheetFrame:Show()
    SheetFrame:Raise()
end

local function GetPortraitTexture(kind)
    if kind == "player" then return "Interface\\Icons\\Achievement_Character_Human_Male" end
    if kind == "target" then return "Interface\\Icons\\Ability_Hunter_MarkedForDeath" end
    return "Interface\\Icons\\INV_Misc_Head_Dragon_01"
end

local function TrySetUnitPortrait(texture, unit, expectedGuid)
    if not texture or not unit or not UnitExists(unit) then return false end
    if expectedGuid and expectedGuid ~= "" and UnitGUID(unit) ~= expectedGuid then return false end
    if SetPortraitTexture then SetPortraitTexture(texture, unit) return true end
    return false
end

local function TrySetCreatureDisplayPortrait(texture, displayId)
    displayId = SafeNumber(displayId, 0)
    if not texture or displayId <= 0 or not SetPortraitTextureFromCreatureDisplayID then
        return false
    end

    SetPortraitTextureFromCreatureDisplayID(texture, displayId)
    return true
end

local function SetEntryPortrait(texture, entry)
    if not texture or not entry then return end
    if entry.kind == "round" then
        texture:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_PocketWatch_01")
        return
    end
    if entry.icon and entry.icon ~= "" then
        texture:SetTexture(entry.icon)
        return
    end
    if TrySetCreatureDisplayPortrait(texture, entry.displayId) then return end
    if TrySetUnitPortrait(texture, "target", entry.id) then return end
    if TrySetUnitPortrait(texture, "mouseover", entry.id) then return end
    if entry.kind == "player" and TrySetUnitPortrait(texture, "player", entry.id) then return end
    texture:SetTexture(GetPortraitTexture(entry.kind))
end

function NormalizeIconPath(icon)
    icon = tostring(icon or "")
    if icon == "" then return nil end
    if tonumber(icon) then return icon end
    if icon:find("\\", 1, true) or icon:find("/", 1, true) then return icon end
    return "Interface\\Icons\\" .. icon
end

local function FindIconInTable(tbl, depth, seen)
    if type(tbl) ~= "table" or depth <= 0 then return nil end
    seen = seen or {}
    if seen[tbl] then return nil end
    seen[tbl] = true

    local direct = tbl.IC or tbl.icon or tbl.Icon or tbl.iconID or tbl.profileIcon
    if type(direct) == "string" and direct ~= "" then return direct end

    for _, v in pairs(tbl) do
        if type(v) == "table" then
            local found = FindIconInTable(v, depth - 1, seen)
            if found then return found end
        end
    end
    return nil
end

local function TryGetTRP3UnitInfo(unit)
    local out = {}
    if not TRP3_API then return out end

    local ok, value
    if TRP3_API.register and TRP3_API.register.getUnitRPName then
        ok, value = pcall(TRP3_API.register.getUnitRPName, unit)
        if ok and value and value ~= "" then
            out.nameColor = ExtractColorHex(value)
            out.name = StripColors(value)
        end
    elseif TRP3_API.r and TRP3_API.r.name then
        ok, value = pcall(TRP3_API.r.name, unit)
        if ok and value and value ~= "" then
            out.nameColor = ExtractColorHex(value)
            out.name = StripColors(value)
        end
    end

    local unitID
    if TRP3_API.register and TRP3_API.register.getUnitID then
        ok, value = pcall(TRP3_API.register.getUnitID, unit)
        if ok then unitID = value end
    elseif TRP3_API.utils and TRP3_API.utils.str and TRP3_API.utils.str.getUnitID then
        ok, value = pcall(TRP3_API.utils.str.getUnitID, unit)
        if ok then unitID = value end
    end

    if HarfordTRP3 then
        local profile
        if UnitIsPlayer and UnitIsPlayer(unit) and HarfordTRP3.GetPlayerProfile then
            profile = HarfordTRP3.GetPlayerProfile(unit)
        elseif HarfordTRP3.GetEpsilonNpcProfile then
            profile = HarfordTRP3.GetEpsilonNpcProfile(unit)
        end

        if profile then
            local icon
            if HarfordTRP3.GetProfileIcon then
                icon = HarfordTRP3.GetProfileIcon(profile)
            else
                icon = FindIconInTable(profile, 4)
            end
            if icon then out.icon = NormalizeIconPath(icon) end
            if HarfordTRP3.GetProfileNameColor then
                out.nameColor = HarfordTRP3.GetProfileNameColor(profile) or out.nameColor
            end
        end

        if not (UnitIsPlayer and UnitIsPlayer(unit)) and HarfordTRP3.BuildEpsilonNpcFullID then
            local fullID, _, npcID, phaseID = HarfordTRP3.BuildEpsilonNpcFullID(unit)
            out.trpFullID = fullID
            out.npcId = npcID
            out.phaseId = phaseID
            if HarfordTRP3.GetEpsilonNpcProfileID then
                local profileID = HarfordTRP3.GetEpsilonNpcProfileID(unit)
                out.trpProfileID = profileID
            end
        elseif UnitIsPlayer and UnitIsPlayer(unit) and HarfordTRP3.BuildUnitID then
            out.trpUnitID = HarfordTRP3.BuildUnitID(unit)
        end
    end

    if AddOn_TotalRP3 and AddOn_TotalRP3.Player and AddOn_TotalRP3.Player.static and AddOn_TotalRP3.Player.static.CreateFromCharacterID and unitID then
        ok, value = pcall(AddOn_TotalRP3.Player.static.CreateFromCharacterID, unitID)
        if ok and value then
            local icon = FindIconInTable(value, 3)
            if value.GetProfile and not icon then
                local okProfile, profile = pcall(value.GetProfile, value)
                if okProfile and profile then icon = FindIconInTable(profile, 3) end
            end
            if icon then out.icon = NormalizeIconPath(icon) end
        end
    end

    return out
end

local function GetFallbackCreatureIcon(unit)
    if UnitIsPlayer and UnitIsPlayer(unit) then
        return nil
    end

    local classification = UnitClassification and UnitClassification(unit)
    if classification == "worldboss" or classification == "elite" or classification == "rareelite" then
        return "Interface\\Icons\\Achievement_Boss_CThun"
    end

    local creatureType = UnitCreatureType and UnitCreatureType(unit)
    if creatureType == "Demon" or creatureType == "Demonio" then
        return "Interface\\Icons\\Spell_Shadow_SummonFelHunter"
    elseif creatureType == "Undead" or creatureType == "No-muerto" then
        return "Interface\\Icons\\Spell_Shadow_AnimateDead"
    elseif creatureType == "Beast" or creatureType == "Bestia" then
        return "Interface\\Icons\\Ability_Hunter_Pet_Wolf"
    elseif creatureType == "Dragonkin" or creatureType == "Dragonante" then
        return "Interface\\Icons\\INV_Misc_Head_Dragon_01"
    elseif creatureType == "Elemental" then
        return "Interface\\Icons\\Spell_Fire_Elemental_Totem"
    elseif creatureType == "Mechanical" or creatureType == "Mecánico" then
        return "Interface\\Icons\\INV_Gizmo_02"
    end

    return "Interface\\Icons\\Ability_Hunter_MarkedForDeath"
end

local function GetResourceFromTable(tbl, resourceKey)
    if type(tbl) ~= "table" then return 0, 0 end
    local cur = SafeNumber(tbl["Res_" .. resourceKey .. "_Cur"], 0)
    local max = SafeNumber(tbl["Res_" .. resourceKey .. "_Max"], 0)
    return cur, max
end

local function GetEntryResourceValues(entry)
    if entry and entry.kind == "player" then
        if HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName then
            local tbl = HarfordDnDAPI.GetResourcesForName(entry.unitName or entry.name)
            if tbl then
                local cur, max = GetResourceFromTable(tbl, "health")
                if max > 0 then
                    return cur, max
                end
            end
        end

        return nil, nil
    end

    return SafeNumber(entry and entry.hp, 0), SafeNumber(entry and entry.maxHp, 0)
end

local function UpdateSmallBar(bar, text, cur, max, r, g, b)
    if cur == nil or max == nil then
        bar:SetMinMaxValues(0, 1)
        bar:SetStatusBarColor(0.28, 0.28, 0.28, 1)
        bar:SetValue(0)
        text:SetText("--/--")
        return
    end

    max = SafeNumber(max, 0)
    cur = SafeNumber(cur, 0)
    local shownMax = max
    if max <= 0 then max = 1 cur = 0 end
    if cur > max then cur = max end
    if cur < 0 then cur = 0 end
    bar:SetMinMaxValues(0, max)
    bar:SetStatusBarColor(r, g, b, 1)
    bar:SetValue(max)
    bar:SetValue(cur)
    text:SetText(tostring(cur) .. "/" .. tostring(shownMax))
end

local function IsEntryCurrentTarget(entry)
    if not entry or not UnitExists or not UnitGUID or not UnitExists("target") then
        return false
    end

    local id = tostring(entry.id or "")
    return id ~= "" and UnitGUID("target") == id
end

local function SetCardTargetState(card, isTarget)
    if not card then return end
    if card.targetTop then
        card.targetTop:SetShown(isTarget)
        card.targetBottom:SetShown(isTarget)
        card.targetLeft:SetShown(isTarget)
        card.targetRight:SetShown(isTarget)
    end
    if card.targetText then
        card.targetText:SetShown(isTarget)
    end
end

local function RefreshTargetNpcHealthFromUnit(unit)
    unit = unit or "target"
    if not UnitExists or not UnitExists(unit) then return false end
    if UnitIsPlayer and UnitIsPlayer(unit) then return false end
    if not UnitGUID then return false end

    local guid = UnitGUID(unit)
    if not guid or guid == "" then return false end

    local hp = UnitHealth and UnitHealth(unit) or nil
    local maxHp = UnitHealthMax and UnitHealthMax(unit) or nil
    if not hp or not maxHp then return false end

    local changed = false
    local store = EnsureStore()
    for _, entry in ipairs(store.entries or {}) do
        if entry and entry.kind ~= "round" and entry.kind ~= "player" and entry.id == guid then
            hp = SafeNumber(hp, entry.hp or 0)
            maxHp = SafeNumber(maxHp, entry.maxHp or hp)
            if SafeNumber(entry.hp, 0) ~= hp or SafeNumber(entry.maxHp, 0) ~= maxHp then
                entry.hp = hp
                entry.maxHp = maxHp
                changed = true
            end
        end
    end

    return changed
end

RefreshFrame = function()
    if not TurnFrame then return end
    local store = EnsureStore()
    EnsureRoundMarker()
    ClampActiveIndex()

    local count = #store.entries
    ClampViewStart()
    local isAdmin = IsTurnAdmin()

    if not isAdmin and editMode then
        editMode = false
    end
    UpdateEditButton()

    local adminName = tostring(store.adminName or "")
    if adminName ~= "" and not isAdmin then
        StatusText:SetText("Turno " .. tostring(count > 0 and store.activeIndex or 0) .. " / " .. tostring(count) .. " - Vista")
    else
        StatusText:SetText("Turno " .. tostring(count > 0 and store.activeIndex or 0) .. " / " .. tostring(count))
    end

    if TurnFrame.adminControls then
        for _, control in ipairs(TurnFrame.adminControls) do
            if control.SetShown then control:SetShown(isAdmin) end
            if control.label and control.label.SetShown then control.label:SetShown(isAdmin) end
        end
    end

    local displayStart = viewStart
    if TurnFrame.viewPrev then
        TurnFrame.viewPrev:SetShown(count > MAX_CARDS)
        TurnFrame.viewNext:SetShown(count > MAX_CARDS)
    end

    for i = 1, MAX_CARDS do
        local card = TurnFrame.cards[i]
        local entryIndex = displayStart + i - 1
        local entry = store.entries[entryIndex]
        if entry then
            card.entryIndex = entryIndex
            card:Show()
            card.name:SetText(entry.name or "Sin nombre")
            if entry.kind == "round" then
                card.name:SetTextColor(GetEntryNameColor(entry))
                card.init:SetText("ESTADOS")
                card.init:Show()
                card.hp:Hide()
            else
                card.name:SetTextColor(GetEntryNameColor(entry))
                card.init:SetText("")
                card.init:Hide()
                local hp, maxHp = GetEntryResourceValues(entry)
                card.hp:Show()
                UpdateSmallBar(card.hp, card.hpText, hp, maxHp, 0.78, 0.05, 0.08)
            end
            SetCardTargetState(card, IsEntryCurrentTarget(entry))
            SetEntryPortrait(card.icon, entry)
            if entryIndex == store.activeIndex then
                card.active:Show()
                card.turn:SetText("ACTIVO")
            else
                card.active:Hide()
                card.turn:SetText("")
            end
            card.minus:SetShown(isAdmin and entry.kind ~= "round")
            card.plus:SetShown(isAdmin and entry.kind ~= "round")
            card.remove:SetShown(isAdmin and entry.kind ~= "round")
            card.moveLeft:SetShown(isAdmin and editMode)
            card.moveRight:SetShown(isAdmin and editMode)
            card.moveLeft:SetEnabled(entryIndex > 1)
            card.moveRight:SetEnabled(entryIndex < #store.entries)
        else
            card.entryIndex = nil
            SetCardTargetState(card, false)
            card:Hide()
        end
    end
end

local function AddEntry(name, initiative, hp, maxHp, kind, id, mana, maxMana, unitName, icon, displayId, meta)
    if not IsTurnAdmin() then Print("Solo el admin puede anadir turnos.") return false end
    ClaimAdminIfNeeded()
    name = tostring(name or "")
    if name == "" then Print("Necesito un nombre para anadir el turno.") return false end

    local store = EnsureStore()
    EnsureRoundMarker()
    local entry = {
        id = id or NewId(),
        name = name,
        kind = kind or "npc",
        initiative = 0,
        hp = SafeNumber(hp, maxHp or 0),
        maxHp = SafeNumber(maxHp, hp or 0),
        mana = SafeNumber(mana, 0),
        maxMana = SafeNumber(maxMana, 0),
        unitName = unitName or name,
        icon = NormalizeIconPath(icon) or "",
        displayId = SafeNumber(displayId, 0),
        npcId = meta and meta.npcId or "",
        phaseId = meta and meta.phaseId or "",
        trpFullID = meta and meta.trpFullID or "",
        trpUnitID = meta and meta.trpUnitID or "",
        trpProfileID = meta and meta.trpProfileID or "",
        reaction = meta and SafeNumber(meta.reaction, 0) or 0,
        nameColor = meta and NormalizeColorHex(meta.nameColor) or nil,
    }
    NormalizeEntryLinks(entry)
    local duplicate = FindDuplicateEntry(entry)
    if duplicate then
        Print(tostring(duplicate.name or entry.name or "El objetivo") .. " ya esta en la lista de turnos.")
        return false
    end

    store.entries[#store.entries + 1] = entry
    ClampActiveIndex()
    MarkChanged()
    return true
end

local function AddUnit(unit, kind)
    if not UnitExists(unit) then Print("No hay unidad valida seleccionada.") return end
    local name = UnitName(unit) or "Unidad"
    local fullName = GetUnitName and GetUnitName(unit, true) or name
    local trp = TryGetTRP3UnitInfo(unit)
    if trp.name and trp.name ~= "" then name = trp.name end
    local guid = UnitGUID(unit) or NewId()
    local hp = UnitHealth and UnitHealth(unit) or 0
    local maxHp = UnitHealthMax and UnitHealthMax(unit) or hp
    local mana = UnitPower and UnitPower(unit, 0) or 0
    local maxMana = UnitPowerMax and UnitPowerMax(unit, 0) or mana
    local entryKind = UnitIsPlayer and UnitIsPlayer(unit) and "player" or (kind or unit)
    local displayId = 0
    if UnitCreatureDisplayID then
        displayId = UnitCreatureDisplayID(unit) or 0
    end
    local reaction = 0
    if UnitReaction and not (UnitIsPlayer and UnitIsPlayer(unit)) then
        reaction = UnitReaction(unit, "player") or 0
    end

    AddEntry(name, 0, hp, maxHp, entryKind, guid, mana, maxMana, fullName, trp.icon or GetFallbackCreatureIcon(unit), displayId, {
        npcId = trp.npcId,
        phaseId = trp.phaseId,
        trpFullID = trp.trpFullID,
        trpUnitID = trp.trpUnitID,
        trpProfileID = trp.trpProfileID,
        reaction = reaction,
        nameColor = trp.nameColor,
    })
    if HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName and UnitIsPlayer and UnitIsPlayer(unit) then
        HarfordDnDAPI.RequestResourcesForName(fullName)
    end
end

local function RemoveEntry(index)
    if not IsTurnAdmin() then Print("Solo el admin puede quitar turnos.") return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    if store.entries[index] and store.entries[index].kind ~= "round" then table.remove(store.entries, index) end
    ClampActiveIndex()
    MarkChanged()
end

local function AdjustHp(index, amount)
    if not IsTurnAdmin() then Print("Solo el admin puede modificar vida.") return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    local entry = store.entries[index]
    if not entry then return end
    if entry.kind == "round" then return end

    amount = SafeNumber(amount, 0)
    if amount == 0 then return end

    if entry.kind == "player" then
        if not HarfordDnDAPI or not HarfordDnDAPI.AdjustResourceForName then
            Print("No puedo enviar ajuste de vida: HarfordDnDAPI no disponible.")
            return
        end

        local targetName = tostring(entry.unitName or entry.name or "")
        local ok, err = HarfordDnDAPI.AdjustResourceForName(targetName, "health", amount)
        if not ok then
            Print("No se pudo enviar ajuste de vida a " .. tostring(entry.name or targetName) .. ": " .. tostring(err or "error desconocido"))
        end
        return
    end

    if not UnitExists or not UnitExists("target") then
        Print("Selecciona el NPC antes de modificar su vida.")
        return
    end

    if UnitGUID and UnitGUID("target") ~= entry.id then
        Print("El objetivo no coincide con el NPC de esta ficha. No se ha modificado la vida.")
        return
    end

    if not HarfordServerActions or not HarfordServerActions.SetNpcHealthDelta then
        Print("No puedo enviar comando NPC: HarfordServerActions no disponible.")
        return
    end

    local ok, err = HarfordServerActions.SetNpcHealthDelta(amount)
    if not ok then
        Print("No se pudo ejecutar npc set health: " .. tostring(err or "error desconocido"))
        return
    end

    local maxHp = SafeNumber(entry.maxHp, 0)
    entry.hp = math.max(0, math.min(SafeNumber(entry.hp, 0) + amount, maxHp))
    MarkChanged()
end

local function PromptAdjustHp(index, direction)
    direction = tonumber(direction) or 1
    direction = direction < 0 and -1 or 1

    local store = EnsureStore()
    local entry = store.entries[index]
    if not entry or entry.kind == "round" then return end

    local dialogName = "HARFORD_TURN_ADJUST_HP"
    StaticPopupDialogs[dialogName] = StaticPopupDialogs[dialogName] or {
        text = "Cantidad de vida:",
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = true,
        editBoxWidth = 120,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText("1")
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self, data)
            local raw = self.editBox:GetText()
            local amount = math.floor(tonumber(raw) or 0)
            if amount <= 0 then
                Print("Introduce una cantidad positiva.")
                return
            end
            AdjustHp(data.index, data.direction * amount)
        end,
        EditBoxOnEnterPressed = function(self, data)
            local parent = self:GetParent()
            local raw = self:GetText()
            local amount = math.floor(tonumber(raw) or 0)
            if amount <= 0 then
                Print("Introduce una cantidad positiva.")
                return
            end
            AdjustHp(data.index, data.direction * amount)
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }

    local verb = direction < 0 and "Restar" or "Sumar"
    StaticPopupDialogs[dialogName].text = verb .. " vida a " .. tostring(entry.name or "entrada") .. ":"
    StaticPopup_Show(dialogName, nil, nil, { index = index, direction = direction })
end

local function NextTurn()
    if not IsTurnAdmin() then Print("Solo el admin puede avanzar turnos.") return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    EnsureRoundMarker()
    if #store.entries == 0 then return end
    store.activeIndex = store.activeIndex + 1
    ClampActiveIndex()
    EnsureActiveVisible()
    local turnSerial = AdvanceTurnSerial()
    MarkChanged()
    PrintTurn(store.entries[store.activeIndex])
    AlertRoundStates(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    AlertMyTurn(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    SendTurnNotice()
end

local function PrevTurn()
    if not IsTurnAdmin() then Print("Solo el admin puede retroceder turnos.") return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    EnsureRoundMarker()
    if #store.entries == 0 then return end
    store.activeIndex = store.activeIndex - 1
    ClampActiveIndex()
    EnsureActiveVisible()
    local turnSerial = AdvanceTurnSerial()
    MarkChanged()
    PrintTurn(store.entries[store.activeIndex])
    AlertRoundStates(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    AlertMyTurn(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    SendTurnNotice()
end

local function CreateCard(parent, index)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    card:SetPoint("TOPLEFT", 18 + (index - 1) * (CARD_W + CARD_GAP), -78)
    card:EnableMouse(true)
    card:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then return end
        local store = EnsureStore()
        local entry = store.entries[self.entryIndex or index]
        ShowEntrySheet(entry)
    end)
    SetFrameBackground(card)

    card.border = CreateFrame("Frame", nil, card, "DialogBorderTemplate")
    card.border:SetAllPoints(card)
    card.border:SetFrameStrata(card:GetFrameStrata())
    card.border:SetFrameLevel(card:GetFrameLevel() + 3)

    card.active = card:CreateTexture(nil, "OVERLAY")
    card.active:SetTexture(TEX_WHITE)
    card.active:SetVertexColor(1.0, 0.78, 0.20, 0.28)
    card.active:SetAllPoints(card)

    card.targetTop = card:CreateTexture(nil, "OVERLAY")
    card.targetTop:SetTexture(TEX_WHITE)
    card.targetTop:SetVertexColor(0.05, 0.85, 1.0, 0.95)
    card.targetTop:SetPoint("TOPLEFT", 2, -2)
    card.targetTop:SetPoint("TOPRIGHT", -2, -2)
    card.targetTop:SetHeight(2)
    card.targetTop:Hide()

    card.targetBottom = card:CreateTexture(nil, "OVERLAY")
    card.targetBottom:SetTexture(TEX_WHITE)
    card.targetBottom:SetVertexColor(0.05, 0.85, 1.0, 0.95)
    card.targetBottom:SetPoint("BOTTOMLEFT", 2, 2)
    card.targetBottom:SetPoint("BOTTOMRIGHT", -2, 2)
    card.targetBottom:SetHeight(2)
    card.targetBottom:Hide()

    card.targetLeft = card:CreateTexture(nil, "OVERLAY")
    card.targetLeft:SetTexture(TEX_WHITE)
    card.targetLeft:SetVertexColor(0.05, 0.85, 1.0, 0.95)
    card.targetLeft:SetPoint("TOPLEFT", 2, -2)
    card.targetLeft:SetPoint("BOTTOMLEFT", 2, 2)
    card.targetLeft:SetWidth(2)
    card.targetLeft:Hide()

    card.targetRight = card:CreateTexture(nil, "OVERLAY")
    card.targetRight:SetTexture(TEX_WHITE)
    card.targetRight:SetVertexColor(0.05, 0.85, 1.0, 0.95)
    card.targetRight:SetPoint("TOPRIGHT", -2, -2)
    card.targetRight:SetPoint("BOTTOMRIGHT", -2, 2)
    card.targetRight:SetWidth(2)
    card.targetRight:Hide()

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(36, 36)
    card.icon:SetPoint("TOP", 0, -9)
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.name:SetPoint("TOPLEFT", 5, -46)
    card.name:SetPoint("TOPRIGHT", -5, -46)
    card.name:SetJustifyH("CENTER")
    card.name:SetHeight(20)

    card.init = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.init:SetPoint("TOP", 0, -65)

    card.hp = CreateFrame("StatusBar", nil, card)
    card.hp:SetSize(58, 10)
    card.hp:SetPoint("TOP", 0, -81)
    card.hp:SetStatusBarTexture(TEX_STATUS)
    card.hpBg = card.hp:CreateTexture(nil, "BACKGROUND")
    card.hpBg:SetAllPoints()
    card.hpBg:SetTexture(TEX_WHITE)
    card.hpBg:SetVertexColor(0.08, 0.08, 0.08, 0.95)
    card.hpText = card.hp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.hpText:SetPoint("CENTER", 0, 0)

    card.turn = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.turn:SetPoint("BOTTOM", 0, 7)

    card.targetText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.targetText:SetPoint("BOTTOM", 0, 20)
    card.targetText:SetText("OBJETIVO")
    card.targetText:SetTextColor(0.05, 0.85, 1.0)
    card.targetText:Hide()

    card.minus = MakeButton(card, "-", 18, 16, "BOTTOMLEFT", card, "BOTTOMLEFT", 5, 4, function()
        local entryIndex = card.entryIndex or index
        if IsShiftKeyDown and IsShiftKeyDown() then
            PromptAdjustHp(entryIndex, -1)
        else
            AdjustHp(entryIndex, -1)
        end
    end)
    card.plus = MakeButton(card, "+", 18, 16, "BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 4, function()
        local entryIndex = card.entryIndex or index
        if IsShiftKeyDown and IsShiftKeyDown() then
            PromptAdjustHp(entryIndex, 1)
        else
            AdjustHp(entryIndex, 1)
        end
    end)
    card.moveLeft = MakeButton(card, "<", 18, 16, "TOPLEFT", card, "TOPLEFT", 3, -4, function()
        MoveEntry(card.entryIndex or index, -1)
    end)
    card.moveLeft:Hide()
    card.moveRight = MakeButton(card, ">", 18, 16, "TOPRIGHT", card, "TOPRIGHT", -20, -4, function()
        MoveEntry(card.entryIndex or index, 1)
    end)
    card.moveRight:Hide()
    card.remove = MakeButton(card, "x", 16, 16, "TOPRIGHT", card, "TOPRIGHT", -2, -4, function()
        RemoveEntry(card.entryIndex or index)
    end)

    return card
end

local function CreateTurnFrame()
    TurnFrame = CreateFrame("Frame", "HarfordTurnOrderFrame", UIParent, "BackdropTemplate")
    TurnFrame:SetSize(512, 238)
    TurnFrame:SetPoint("CENTER", 0, 110)
    TurnFrame:SetFrameStrata("HIGH")
    TurnFrame:SetMovable(true)
    TurnFrame:EnableMouse(true)
    TurnFrame:RegisterForDrag("LeftButton")
    TurnFrame:SetClampedToScreen(true)
    TurnFrame:Hide()
    SetFrameBackground(TurnFrame)

    local mainBorder = CreateFrame("Frame", nil, TurnFrame, "DialogBorderTemplate")
    mainBorder:SetAllPoints(TurnFrame)
    mainBorder:SetFrameStrata(TurnFrame:GetFrameStrata())
    mainBorder:SetFrameLevel(TurnFrame:GetFrameLevel() + 5)

    TurnFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    TurnFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    TurnFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + (elapsed or 0)
        if self.elapsed >= 0.5 then
            self.elapsed = 0
            RefreshFrame()
        end
    end)

    local title = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -15)
    title:SetText("Turnos Harford")

    StatusText = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    StatusText:SetPoint("LEFT", title, "RIGHT", 14, 0)

    local close = CreateFrame("Button", nil, TurnFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -5)

    TurnFrame.adminControls = {}

    local targetButton = MakeButton(TurnFrame, "Objetivo", 62, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 16, -51, function() AddUnit("target", "target") end)
    local editButton = MakeButton(TurnFrame, "Editar", 58, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 16, -206, ToggleEditMode)
    TurnFrame.editButton = editButton
    tinsert(TurnFrame.adminControls, targetButton)
    tinsert(TurnFrame.adminControls, editButton)

    local prevButton = MakeButton(TurnFrame, "Anterior", 68, 22, "BOTTOMLEFT", TurnFrame, "BOTTOMLEFT", 80, 10, PrevTurn)
    local nextButton = MakeButton(TurnFrame, "Siguiente", 72, 22, "BOTTOMLEFT", TurnFrame, "BOTTOMLEFT", 153, 10, NextTurn)
    local shareButton = MakeButton(TurnFrame, "Compartir", 76, 22, "BOTTOMLEFT", TurnFrame, "BOTTOMLEFT", 230, 10, SendState)
    TurnFrame.viewPrev = MakeButton(TurnFrame, "<", 24, 22, "BOTTOMLEFT", TurnFrame, "BOTTOMLEFT", 312, 10, function()
        ScrollView(-1)
    end)
    TurnFrame.viewNext = MakeButton(TurnFrame, ">", 24, 22, "BOTTOMLEFT", TurnFrame, "BOTTOMLEFT", 340, 10, function()
        ScrollView(1)
    end)
    TurnFrame.viewPrev:Hide()
    TurnFrame.viewNext:Hide()
    tinsert(TurnFrame.adminControls, prevButton)
    tinsert(TurnFrame.adminControls, nextButton)
    tinsert(TurnFrame.adminControls, shareButton)

    local clearButton = MakeButton(TurnFrame, "Limpiar", 62, 22, "BOTTOMRIGHT", TurnFrame, "BOTTOMRIGHT", -18, 10, function()
        if not IsTurnAdmin() then Print("Solo el admin puede limpiar turnos.") return end
        ClaimAdminIfNeeded()
        local store = EnsureStore()
        store.entries = {}
        store.activeIndex = 1
        EnsureRoundMarker()
        MarkChanged()
    end)
    tinsert(TurnFrame.adminControls, clearButton)

    TurnFrame.cards = {}
    for i = 1, MAX_CARDS do
        TurnFrame.cards[i] = CreateCard(TurnFrame, i)
    end
    UpdateEditButton()
    RefreshFrame()
end

local function ToggleFrame()
    if not TurnFrame then CreateTurnFrame() end
    TurnFrame:SetShown(not TurnFrame:IsShown())
    if TurnFrame:IsShown() then RefreshFrame() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        EnsureStore()
        if HarfordSync and HarfordSync.RegisterPrefix then
            HarfordSync.RegisterPrefix(COMM_PREFIX)
        elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(COMM_PREFIX)
        end
        CreateTurnFrame()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        if RefreshTargetNpcHealthFromUnit("target") then
            MarkChanged()
            return
        end
        if RefreshFrame then RefreshFrame() end
        return
    end

    local prefix, message, _, sender = ...
    if prefix ~= COMM_PREFIX then return end
    if IsSenderSelf(sender) then return end

    local opcode = tostring(message or ""):match("^([^|]+)")
    suppressBroadcast = true
    local applied = ApplyTurnMessage(message, sender)
    suppressBroadcast = false
    if applied then
        local store = EnsureStore()
        if opcode ~= "TURN" then
            AlertMyTurn(store.entries[store.activeIndex], store.activeIndex)
        end
        RefreshFrame()
    end
end)

HarfordTurnOrderAPI = HarfordTurnOrderAPI or {}
HarfordTurnOrderAPI.Toggle = ToggleFrame
HarfordTurnOrderAPI.Refresh = RefreshFrame
HarfordTurnOrderAPI.SendState = SendState
HarfordTurnOrderAPI.AddEntry = AddEntry
HarfordTurnOrderAPI.AddUnit = AddUnit
HarfordTurnOrderAPI.NextTurn = NextTurn
HarfordTurnOrderAPI.PrevTurn = PrevTurn

SLASH_HARFORDTURNOS1 = "/TurnosHarford"
SLASH_HARFORDTURNOS2 = "/turnos"
SLASH_HARFORDTURNOS3 = "/th"
SlashCmdList["HARFORDTURNOS"] = function(msg)
    msg = tostring(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if cmd == "next" or cmd == "siguiente" then
        NextTurn()
    elseif cmd == "prev" or cmd == "anterior" then
        PrevTurn()
    elseif cmd == "sort" or cmd == "ordenar" or cmd == "edit" or cmd == "editar" then
        ToggleEditMode()
    elseif cmd == "clear" or cmd == "limpiar" then
        if not IsTurnAdmin() then Print("Solo el admin puede limpiar turnos.") return end
        ClaimAdminIfNeeded()
        local store = EnsureStore()
        store.entries = {}
        store.activeIndex = 1
        EnsureRoundMarker()
        MarkChanged()
    elseif cmd == "share" or cmd == "compartir" then
        SendState()
    elseif cmd == "target" or cmd == "objetivo" then
        AddUnit("target", "target")
    elseif cmd == "player" or cmd == "jugador" then
        AddUnit("player", "player")
    elseif cmd == "npc" and rest ~= "" then
        AddEntry(rest, 0, 1, 1, "npc")
    else
        ToggleFrame()
    end
end
