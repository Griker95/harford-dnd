-- HarfordCharacterInspect: inspeccion ligera del panel de personaje de otro jugador.
--
-- No importa el perfil remoto como perfil activo local. Pide un snapshot compacto
-- por WHISPER y lo guarda en una cache de lectura: base DnD pequena, recursos,
-- progresion y equipo. El panel de personaje puede pintar esa cache sin editarla.

HarfordCharacterInspect = HarfordCharacterInspect or {}

local API = HarfordCharacterInspect
local ADDON_PREFIX = "DND5EARC"
local REQ_OPCODE = "DNDINSREQ"
local BASE_OPCODE = "DNDINSBASE"

API.Cache = API.Cache or {}

-- Consentimiento (default: inspeccion libre) + throttle anti-spam por solicitante.
if API.AllowRequests == nil then API.AllowRequests = true end
local snapshotSentAt = {}
local SNAPSHOT_THROTTLE = 5  -- segundos minimos entre snapshots al mismo solicitante
local SNAPSHOT_THROTTLE_TTL = 60
local INSPECT_CACHE_MAX = 8
local INSPECT_CACHE_TTL = 300
local inspectCacheOrder = {}

local function CanServe(sender)
    if not API.AllowRequests then return false end
    if not sender or sender == "" then return false end
    local now = GetTime and GetTime() or 0
    for name, sentAt in pairs(snapshotSentAt) do
        if (now - (tonumber(sentAt) or now)) > SNAPSHOT_THROTTLE_TTL then
            snapshotSentAt[name] = nil
        end
    end
    local last = snapshotSentAt[sender]
    if last and (now - last) < SNAPSHOT_THROTTLE then return false end
    snapshotSentAt[sender] = now
    return true
end

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r " .. tostring(msg or ""))
    end
end

local function FullPlayerName(unit)
    if unit and UnitExists and UnitExists(unit)
        and ((not UnitIsPlayer) or UnitIsPlayer(unit))
    then
        return HarfordClassColors.UnitFullName(unit)
    end
    return nil
end

local function IsKnownUnitToken(value)
    value = tostring(value or "")
    return value == "player" or value == "target" or value == "focus"
        or value:match("^party%d+$") or value:match("^raid%d+$")
end

local function ShortName(name)
    if not name or name == "" then return nil end
    if Ambiguate then
        local short = Ambiguate(name, "short")
        if short and short ~= "" then return short end
    end
    return tostring(name):match("^[^%-]+") or tostring(name)
end

local function CacheNames(name)
    local out = {}
    if name and name ~= "" then out[#out + 1] = tostring(name) end
    local short = ShortName(name)
    if short and short ~= "" and short ~= name then out[#out + 1] = short end
    return out
end

local function DropSnapshotAliases(snap)
    if type(snap) ~= "table" then return end
    for key, cached in pairs(API.Cache or {}) do
        if cached == snap then
            API.Cache[key] = nil
        end
    end
end

local function PruneInspectCache()
    local now = GetTime and GetTime() or 0
    local unique = {}
    local freshOrder = {}

    for _, name in ipairs(inspectCacheOrder) do
        local snap = API.Cache[name]
        if type(snap) == "table" and not unique[snap] then
            local age = now - (tonumber(snap.updatedAt) or tonumber(snap.requestedAt) or now)
            if age <= INSPECT_CACHE_TTL then
                unique[snap] = true
                freshOrder[#freshOrder + 1] = name
            else
                DropSnapshotAliases(snap)
            end
        end
    end

    inspectCacheOrder = freshOrder
    while #inspectCacheOrder > INSPECT_CACHE_MAX do
        local oldName = table.remove(inspectCacheOrder, 1)
        local oldSnap = API.Cache[oldName]
        DropSnapshotAliases(oldSnap)
    end
end

local function EnsureSnapshot(name)
    name = tostring(name or "")
    if name == "" then return nil end
    PruneInspectCache()
    local snap = API.Cache[name]
    if type(snap) ~= "table" then
        snap = { profileName = name, updatedAt = 0, requestedAt = 0 }
        API.Cache[name] = snap
        inspectCacheOrder[#inspectCacheOrder + 1] = name
    end
    for _, alias in ipairs(CacheNames(name)) do
        API.Cache[alias] = snap
    end
    return snap
end

local function MarkUpdated(snap)
    if snap then snap.updatedAt = GetTime and GetTime() or 0 end
    if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then
        HarfordCharacterPanel.Refresh()
    end
end

local function SerializeBase(profileName, base)
    return HarfordSync.SerializeProfileMessage(BASE_OPCODE, profileName, base, HarfordSync.ProfileKeys.DnDBase)
end

local function DeserializeBase(message)
    local opcode, profileName, tbl = HarfordSync.DeserializeProfileMessage(message)
    if opcode ~= BASE_OPCODE then return nil, nil end
    return profileName, tbl
end

function API.GetSnapshot(name)
    if not name or name == "" then return nil end
    return API.Cache[name] or API.Cache[ShortName(name) or ""]
end

function API.NoteResources(sender, profileName, tbl)
    local snap = EnsureSnapshot(profileName or sender)
    if not snap then return end
    snap.sender = sender or snap.sender
    snap.resources = tbl
    MarkUpdated(snap)
end

function API.NoteProgression(profileName, data)
    local snap = EnsureSnapshot(profileName)
    if not snap then return end
    snap.progression = data
    -- Caché EFIMERA en el modulo de progresion: el panel la lee sin que se escriba
    -- en HarfordDnDPersistStore (read-only de verdad).
    if HarfordDnDProgression and HarfordDnDProgression.SetInspectData then
        HarfordDnDProgression.SetInspectData(profileName, data)
    end
    MarkUpdated(snap)
end

function API.NoteEquipment(profileName, data)
    local snap = EnsureSnapshot(profileName)
    if not snap then return end
    snap.equipment = data
    if HarfordDnDItems and HarfordDnDItems.SetInspectData then
        HarfordDnDItems.SetInspectData(profileName, data)
    end
    MarkUpdated(snap)
end

-- Limpia las cachés efímeras de inspeccion (al salir del modo inspeccion o cambiar de
-- objetivo). No toca persistencia; solo descarta el snapshot en memoria.
function API.ClearInspectStores()
    if HarfordDnDProgression and HarfordDnDProgression.ClearInspectData then
        HarfordDnDProgression.ClearInspectData()
    end
    if HarfordDnDItems and HarfordDnDItems.ClearInspectData then
        HarfordDnDItems.ClearInspectData()
    end
end

function API.SendSnapshotTo(targetName)
    if not targetName or targetName == "" then return false, "Target invalido" end
    if not (HarfordSync and HarfordSync.Send) then return false, "HarfordSync no disponible" end

    local profileName = tostring((UnitName and UnitName("player")) or "default")

    local base = HarfordSync.ReadProfileFromRuntime(
        HarfordDnDStore and HarfordDnDStore.state and HarfordDnDStore.state.runtime or {},
        HarfordSync.ProfileKeys.DnDBase
    )
    HarfordSync.Send(ADDON_PREFIX, SerializeBase(profileName, base), "WHISPER", targetName)

    if HarfordDnDNet and HarfordDnDNet.SendResourceResponseTo then
        HarfordDnDNet.SendResourceResponseTo(targetName)
    end
    if HarfordDnDProgression and HarfordDnDProgression.Export and HarfordSync.SendDnDClassProgression then
        HarfordSync.SendDnDClassProgression(ADDON_PREFIX, profileName, HarfordDnDProgression.Export(profileName), "WHISPER", targetName, "DNDINSCLASS")
    end
    if HarfordDnDItems and HarfordDnDItems.GetEquipment and HarfordSync.SendDnDEquipment then
        HarfordSync.SendDnDEquipment(ADDON_PREFIX, profileName, HarfordDnDItems.GetEquipment(profileName), "WHISPER", targetName, "DNDINSEQUIP")
    end
    return true
end

function API.Request(unitOrName)
    unitOrName = unitOrName or "target"
    local targetName = FullPlayerName(unitOrName)
    if (not targetName or targetName == "") and not IsKnownUnitToken(unitOrName) then
        targetName = tostring(unitOrName or "")
    end
    if not targetName or targetName == "" then
        Print("No hay jugador para inspeccionar.")
        return false
    end
    local myName = HarfordClassColors.UnitFullName("player") or ""
    if targetName == myName or ShortName(targetName) == ShortName(myName) then
        return false, "No hace falta inspeccionar tu propio panel."
    end
    EnsureSnapshot(targetName).requestedAt = GetTime and GetTime() or 0
    return HarfordSync.Send(ADDON_PREFIX, REQ_OPCODE .. "|" .. tostring(myName), "WHISPER", targetName)
end

function API.HandleAddonMessage(prefix, message, sender)
    if prefix ~= ADDON_PREFIX or type(message) ~= "string" then return false end
    local op = message:match("^([^|]+)") or ""

    -- Solicitud de inspeccion -> responder snapshot (con consentimiento + throttle).
    local requester = message:match("^" .. REQ_OPCODE .. "|(.+)$")
    if requester and requester ~= "" then
        if CanServe(sender) then
            API.SendSnapshotTo(sender)
        end
        return true
    end

    -- Base DnD del inspeccionado.
    local profileName, base = DeserializeBase(message)
    if profileName and base then
        local snap = EnsureSnapshot(profileName)
        snap.sender = sender or snap.sender
        snap.base = base
        MarkUpdated(snap)
        return true
    end

    -- Progresion/equipo de INSPECCION (opcodes DNDINS*): solo caché efimera, nunca
    -- import a persistencia. El sync normal (DNDCLASS/DNDEQUIP) NO entra aqui y sigue
    -- su ruta de import en HarfordDnDComm.
    if op == "DNDINSCLASS" then
        local pn, data = HarfordSync.DeserializeDnDClassProgression(message)
        if pn and data then API.NoteProgression(pn, data) end
        return true
    elseif op == "DNDINSCLASSC" then
        local pn, data = HarfordSync.ReceiveDnDClassProgressionChunk(message, sender)
        if pn and data then API.NoteProgression(pn, data) end
        return true
    elseif op == "DNDINSEQUIP" then
        local pn, data = HarfordSync.DeserializeDnDEquipment(message)
        if pn and data then API.NoteEquipment(pn, data) end
        return true
    elseif op == "DNDINSEQUIPC" then
        local pn, data = HarfordSync.ReceiveDnDEquipmentChunk(message, sender)
        if pn and data then API.NoteEquipment(pn, data) end
        return true
    end

    return false
end

-- El comando /harford debug run inspecttarget se registra en HarfordDebug.lua (convencion del
-- proyecto). Solo usa funciones publicas: HarfordCharacterPanel.OpenInspect / API.Request.
