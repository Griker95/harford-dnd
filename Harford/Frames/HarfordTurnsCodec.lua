-- Codec de la red de turnos: escapado, troceado y (de)serializacion de entradas.
--
-- Se separo de HarfordTurns.lua porque no depende de la UI ni del store: entra texto o una tabla
-- de entrada y sale texto, o al reves. Eso lo hace comprobable con un arnes, que es justo lo que
-- no se podia hacer mientras vivia entre 2800 lineas de frames y tarjetas.
--
-- Lo que necesita de fuera se inyecta con `Init`, siguiendo el patron de HarfordCharacterSpellbook:
-- ni lee ni escribe estado global del tracker.

HarfordTurnsCodec = HarfordTurnsCodec or {}
local API = HarfordTurnsCodec

-- Inyectados por HarfordTurns en su carga.
local SafeNumber = function(v, d) local n = tonumber(v) if n == nil then return d or 0 end return n end
local NormalizeKind = function(k) return tostring(k or "npc") end
-- Rutas de icono: la normalizacion vive en HarfordTurns, que es quien las pinta.
local NormalizeIconPath = function(icon) return icon end
local NormalizeColorHex = function(hex) return hex end
local TURN_CHUNK_ENCODED_LIMIT = 170
local TURN_MAX_CHUNKS = 80
local CHUNK_TTL_SECONDS = 15

-- Buffers de reensamblado. Viven aqui porque solo los usa `ApplyChunked`.
local turnChunkBuffers = {}

function API.Init(deps)
    deps = deps or {}
    if deps.SafeNumber then SafeNumber = deps.SafeNumber end
    if deps.NormalizeKind then NormalizeKind = deps.NormalizeKind end
    if deps.NormalizeIconPath then NormalizeIconPath = deps.NormalizeIconPath end
    if deps.NormalizeColorHex then NormalizeColorHex = deps.NormalizeColorHex end
    if deps.chunkEncodedLimit then TURN_CHUNK_ENCODED_LIMIT = deps.chunkEncodedLimit end
    if deps.maxChunks then TURN_MAX_CHUNKS = deps.maxChunks end
    if deps.chunkTTL then CHUNK_TTL_SECONDS = deps.chunkTTL end
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

local function NormalizePlayerUnitID(value)
    value = tostring(value or "")
    if value == "" then return "" end
    if value:find("-", 1, true) then return value end

    local realm = GetRealmName and GetRealmName()
    realm = tostring(realm or ""):gsub("%s+", "")
    if realm == "" then return value end
    return value .. "-" .. realm
end

local function NormalizeEntryLinks(entry)
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
        -- Una entrada jugador nunca debe conservar rutas companion/NPC.
        -- Pueden llegar de estados antiguos o de un sync previo y resolver
        -- la ficha equivocada si se reutilizan como identidad TRP3.
        entry.npcId = ""
        entry.phaseId = ""
        entry.trpFullID = ""
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

-- Los miembros de un bloque: `guid|nombre|esJugador`, separados por `;`. Se escapan los dos
-- separadores dentro de cada campo, que un nombre de NPC puede traerlos.
local function SerializeMembers(lista)
    if type(lista) ~= "table" or #lista == 0 then return "" end
    local partes = {}
    for _, m in ipairs(lista) do
        local nombre = tostring(m.name or ""):gsub("%%", "%%25"):gsub(";", "%%3B"):gsub("|", "%%7C")
        partes[#partes + 1] = table.concat({
            tostring(m.guid or ""), nombre, m.jugador and "1" or "0" }, "|")
    end
    return table.concat(partes, ";")
end

local function DeserializeMembers(texto)
    texto = tostring(texto or "")
    if texto == "" then return nil end
    local fuera = {}
    for trozo in texto:gmatch("[^;]+") do
        local guid, nombre, jugador = strsplit("|", trozo)
        if guid and guid ~= "" then
            nombre = tostring(nombre or ""):gsub("%%7C", "|"):gsub("%%3B", ";"):gsub("%%25", "%%")
            fuera[#fuera + 1] = { guid = guid, name = nombre, jugador = jugador == "1" or nil }
        end
    end
    return (#fuera > 0) and fuera or nil
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
        tostring(entry.armorClass or 0),
        EscapeText(entry.bando),
        tostring(entry.tempHp or 0),
        -- Quien va DENTRO del bloque. Van al final y con separadores propios, para no tocar el
        -- formato de los 22 campos anteriores.
        EscapeText(SerializeMembers(entry.miembros)),
    }, ",")
end

local function DeserializeEntry(raw)
    -- `bando` va el ULTIMO a proposito: un cliente con version anterior lo ignora y sigue leyendo
    -- el resto, en vez de descuadrarse todos los campos.
    local id, name, kind, init, hp, maxHp, hidden, mana, maxMana, unitName, icon, displayId, npcId, phaseId, trpFullID, trpUnitID, reaction, nameColor, trpProfileID, armorClass, bando, tempHp, miembros = strsplit(",", raw or "")
    if not name or name == "" then return nil end
    return NormalizeEntryLinks({
        id = UnescapeText(id),
        name = UnescapeText(name),
        kind = NormalizeKind(UnescapeText(kind)),
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
        armorClass = SafeNumber(armorClass, 0),
        bando = UnescapeText(bando),
        -- La vida temporal es dato de Harford: el servidor no la conoce y no vuelve en ningun
        -- evento. Sin compartirla, cada cliente absorbia una cantidad distinta del MISMO golpe.
        tempHp = SafeNumber(tempHp, 0),
        miembros = DeserializeMembers(UnescapeText(miembros)),
    })
end

local function SerializeTurnNoticeEntry(entry)
    entry = NormalizeEntryLinks(entry or {}) or {}
    -- Nombre corto sin realm para unitName y trpUnitID, igual que el banco de fichas.
    -- El receptor llama a NormalizePlayerUnitID al deserializar si necesita el realm.
    local unitNameShort = Ambiguate and Ambiguate(tostring(entry.unitName or ""), "short")
        or tostring(entry.unitName or ""):match("^[^%-]+")
        or tostring(entry.unitName or "")
    local trpUnitIDShort = Ambiguate and Ambiguate(tostring(entry.trpUnitID or ""), "short")
        or tostring(entry.trpUnitID or ""):match("^[^%-]+")
        or tostring(entry.trpUnitID or "")
    return table.concat({
        EscapeText(entry.id),
        EscapeText(entry.name),
        EscapeText(entry.kind),
        EscapeText(unitNameShort),
        EscapeText(trpUnitIDShort),
    }, ",")
end

local function DeserializeTurnNoticeEntry(raw)
    local id, name, kind, unitName, trpUnitID = strsplit(",", raw or "")
    if not name or name == "" then return nil end
    return NormalizeEntryLinks({
        id = UnescapeText(id),
        name = UnescapeText(name),
        kind = NormalizeKind(UnescapeText(kind)),
        unitName = UnescapeText(unitName),
        trpUnitID = UnescapeText(trpUnitID),
    })
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

local function ApplyChunked(message, sender, opcode, keyPrefix, aplicar)
    local patron = "^" .. opcode .. "|([^|]+)|([^|]+)|([^|]+)|(.*)$"
    local transferId, indexRaw, totalRaw, chunk = tostring(message or ""):match(patron)
    if not transferId or transferId == "" then return false end

    local index = tonumber(indexRaw)
    local total = tonumber(totalRaw)
    if not index or not total or total < 1 or total > TURN_MAX_CHUNKS or index < 1 or index > total then
        return false
    end

    local key = keyPrefix .. tostring(sender or "?") .. ":" .. transferId
    local buffer = turnChunkBuffers[key]
    if not buffer or buffer.total ~= total then
        buffer = { total = total, received = 0, chunks = {} }
        turnChunkBuffers[key] = buffer
        if C_Timer and C_Timer.After then
            C_Timer.After(CHUNK_TTL_SECONDS, function()
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
    -- Con el REMITENTE: sin el, lo que llega troceado no sabe quien lo mando, y el aviso de doble
    -- avance entre dos DMs quedaba mudo justo en un combate grande, que es cuando se trocea.
    return aplicar(table.concat(assembled), sender)
end

API.EscapeText = EscapeText
API.UnescapeText = UnescapeText
API.NormalizePlayerUnitID = NormalizePlayerUnitID
API.NormalizeEntryLinks = NormalizeEntryLinks
API.SerializeEntry = SerializeEntry
API.DeserializeEntry = DeserializeEntry
API.SerializeTurnNoticeEntry = SerializeTurnNoticeEntry
API.DeserializeTurnNoticeEntry = DeserializeTurnNoticeEntry
API.UnescapeChunk = UnescapeChunk
API.SplitEscapedChunks = SplitEscapedChunks
API.ApplyChunked = ApplyChunked
