------------------------------------------------------------
-- HarfordCourier - Capa de mensajeria FIABLE (store-and-forward) sobre un CANAL de addon propio.
--
-- Problema que resuelve: WoW no tiene buzon de servidor para addon-messages, asi que NO existe
-- entrega a un jugador realmente desconectado. Lo que si se puede es entrega EVENTUAL: el emisor
-- guarda el mensaje en un "outbox" persistente y lo reemite cuando ambos coinciden online. El
-- receptor deduplica por id y devuelve ACK; al recibir el ACK, el emisor lo saca del outbox.
--
-- Transporte: un CANAL de chat propio (HarfordNet) via AceComm-3.0 (lo trae EpsilonLib). Un canal
-- da un bus a nivel de realm/fase independiente de grupo/hermandad, y es la unica via para que un
-- emisor que reconecta alcance a cualquiera que este online sin estar en su grupo. El spam del
-- canal se oculta del chat.
--
-- Recuperacion SIN ticker permanente (regla del proyecto): es puramente por eventos.
--   * Al conectar (PLAYER_ENTERING_WORLD) y con el canal listo -> FlushOutbox (reemite lo no
--     confirmado) + emite un CATCHUP ("estoy online, reenviadme lo mio").
--   * Al recibir CATCHUP de X -> reenvia las entradas del outbox dirigidas a X.
--   * Al recibir ACK(id) -> borra esa entrada del outbox.
--
-- API publica:
--   HarfordCourier.RegisterHandler(opcode, fn)  -- fn(payload<string>, fromShortName, msgId)
--   HarfordCourier.Send(toName, opcode, payload) -> msgId | nil  (fiable, 1 destinatario)
--   HarfordCourier.IsReady()                    -- canal unido y AceComm disponible
--   HarfordCourier.GetStatus()                  -- tabla de diagnostico (para HarfordDebug)
--
-- Grupos: el core apunta a UN destinatario. Para un grupo, el llamante hace fan-out (un Send por
-- miembro), obteniendo asi seguimiento de entrega POR MIEMBRO (lo que Noumenon no hacia).
--
-- Privacidad: el canal es a nivel de realm; cualquiera con el addon puede leer los addon-messages.
-- Es aceptable para RP (como Noumenon), pero NO cifrado. El contenido sensible no deberia ir aqui.
------------------------------------------------------------

HarfordCourier = HarfordCourier or {}
local API = HarfordCourier

local function print(...)
    if not (HarfordChat and HarfordChat.Print) then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    HarfordChat.Print(table.concat(parts, " "))
end

------------------------------------------------------------
-- Config
------------------------------------------------------------
local CHANNEL_NAME = "HarfordNet"
local COMM_PREFIX  = "HARFCOUR"
local SEEN_TTL     = 7 * 86400   -- recordar ids vistos para deduplicar (7 dias)
local OUTBOX_TTL   = 3 * 86400   -- descartar no confirmados tras 3 dias (como Noumenon)
local MAX_OUTBOX   = 500
local MAX_SEEN     = 2000
local JOIN_RETRY   = 3           -- s entre reintentos de resolver el indice del canal

------------------------------------------------------------
-- Estado runtime
------------------------------------------------------------
local aceComm                 -- LibStub("AceComm-3.0")
local channelIndex            -- id del canal (numero) o nil
local handlers = {}           -- [opcode] = fn(payload, fromShort, msgId)
local deliveryCbs = {}        -- [msgId] = fn(msgId, toName)  (runtime; se pierde en /reload)
local msgCounter = 0
local joinPending = false

------------------------------------------------------------
-- Helpers de nombre / persistencia
------------------------------------------------------------
local function ShortName(name)
    name = tostring(name or "")
    return (Ambiguate and Ambiguate(name, "short")) or name:match("^([^-]+)") or name
end

local function MyName()
    return ShortName((UnitName and UnitName("player")) or "Jugador")
end

local function SamePlayer(a, b)
    if not a or not b then return false end
    return a == b or ShortName(a) == ShortName(b)
end

local function Store()
    HarfordCourierStore = HarfordCourierStore or {}
    HarfordCourierStore.outbox = HarfordCourierStore.outbox or {}
    HarfordCourierStore.seen   = HarfordCourierStore.seen or {}
    return HarfordCourierStore
end

------------------------------------------------------------
-- Envelope: type ^ id ^ from ^ to ^ opcode ^ payload
-- from/to/opcode/payload van escapados (`^` y `~` reservados); type e id son controlados.
------------------------------------------------------------
local function Esc(s)
    return (tostring(s or ""):gsub("~", "~t"):gsub("%^", "~c"))
end
local function Unesc(s)
    return (tostring(s or ""):gsub("~c", "^"):gsub("~t", "~"))
end

local function GenId()
    msgCounter = msgCounter + 1
    return MyName() .. "-" .. tostring(time and time() or 0) .. "-" .. tostring(msgCounter)
end

local function BuildEnvelope(kind, id, from, to, opcode, payload)
    return table.concat({ kind, id, Esc(from), Esc(to), Esc(opcode), Esc(payload) }, "^")
end

------------------------------------------------------------
-- Canal
------------------------------------------------------------
local function ResolveChannelIndex()
    if not GetChannelName then return nil end
    for i = 1, 20 do
        local id, chName = GetChannelName(i)
        if chName == CHANNEL_NAME then return id end
    end
    return nil
end

local function TryJoinChannel()
    channelIndex = ResolveChannelIndex()
    if channelIndex and channelIndex ~= 0 then
        joinPending = false
        return true
    end
    if JoinChannelByName then JoinChannelByName(CHANNEL_NAME) end
    -- Un unico reintento diferido acotado (no ticker permanente): CHANNEL_UI_UPDATE tambien lo
    -- reintenta cuando el cliente confirma la union.
    if not joinPending and C_Timer and C_Timer.After then
        joinPending = true
        C_Timer.After(JOIN_RETRY, function()
            joinPending = false
            if not (channelIndex and channelIndex ~= 0) then TryJoinChannel() end
        end)
    end
    return false
end

-- Oculta del chat el trafico del canal propio.
local function InstallChannelFilter()
    if not ChatFrame_AddMessageEventFilter then return end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL",
        function(_, _, _, _, _, _, _, _, chName, _, _, chNum)
            if chName == CHANNEL_NAME or (channelIndex and chNum == channelIndex) then return true end
            return false
        end)
end

local function RawBroadcast(envelope)
    if not (aceComm and channelIndex and channelIndex ~= 0) then return false end
    local ok = pcall(function()
        aceComm:SendCommMessage(COMM_PREFIX, envelope, "CHANNEL", tostring(channelIndex))
    end)
    return ok
end

------------------------------------------------------------
-- Poda
------------------------------------------------------------
local function Prune()
    local store = Store()
    local now = time and time() or 0
    for id, expiry in pairs(store.seen) do
        if (tonumber(expiry) or 0) < now then store.seen[id] = nil end
    end
    for id, entry in pairs(store.outbox) do
        if (tonumber(entry.sentAt) or 0) + OUTBOX_TTL < now then store.outbox[id] = nil end
    end
    -- Cap defensivo del set de vistos: si crece demasiado, vaciar (la dedupe solo evita duplicados
    -- durante la ventana de reintento; perder ids muy viejos no reentrega nada dentro del TTL).
    local seenCount = 0
    for _ in pairs(store.seen) do seenCount = seenCount + 1 end
    if seenCount > MAX_SEEN then wipe(store.seen) end
end

------------------------------------------------------------
-- Recepcion
------------------------------------------------------------
local function MarkSeen(id)
    local store = Store()
    store.seen[id] = (time and time() or 0) + SEEN_TTL
end

local function AlreadySeen(id)
    return Store().seen[id] ~= nil
end

local function SendAck(ackedId, toName)
    RawBroadcast(BuildEnvelope("A", ackedId, MyName(), toName, "", ""))
end

local function ResendOutboxTo(requester)
    local store = Store()
    local me = MyName()
    for id, entry in pairs(store.outbox) do
        if SamePlayer(entry.to, requester) then
            RawBroadcast(BuildEnvelope("M", id, me, entry.to, entry.opcode, entry.payload))
        end
    end
end

local function HandleEnvelope(envelope, sender)
    if type(envelope) ~= "string" then return end
    local kind, id, from, to, opcode, payload = strsplit("^", envelope, 6)
    if not kind then return end
    from, to, opcode, payload = Unesc(from), Unesc(to), Unesc(opcode), Unesc(payload)
    local me = MyName()

    -- SEGURIDAD: el `from` del cuerpo (autodeclarado, spoofeable) DEBE coincidir con el remitente
    -- autenticado del canal (`sender`, lo da WoW y no se puede falsear). Sin esto, cualquiera podia
    -- enviar un ACK falso para borrar un mensaje pendiente ajeno, o suplantar a otro contacto en "M".
    if sender and sender ~= "" and from ~= "" and not SamePlayer(from, sender) then return end

    if kind == "A" then
        -- ACK: el emisor original (to) borra la entrada confirmada. Solo nos concierne si es para mi.
        if SamePlayer(to, me) then
            local existed = Store().outbox[id] ~= nil
            Store().outbox[id] = nil
            local cb = deliveryCbs[id]
            if cb and existed then
                deliveryCbs[id] = nil
                pcall(cb, id, ShortName(from))
            end
        end
        return
    elseif kind == "C" then
        -- Catchup: alguien reconecto y pide lo suyo. Reenvio lo que tenga para el.
        if not SamePlayer(from, me) then ResendOutboxTo(from) end
        return
    elseif kind == "M" then
        if not SamePlayer(to, me) then return end          -- no es para mi
        SendAck(id, from)                                  -- confirma SIEMPRE (aunque sea duplicado)
        if AlreadySeen(id) then return end                 -- ya entregado: solo re-ACK
        MarkSeen(id)
        local fn = handlers[opcode]
        if fn then
            local okCall = pcall(fn, payload, ShortName(from), id)
            if not okCall and HarfordDebug and HarfordDebug.Log then
                HarfordDebug.Log("HarfordCourier: handler '" .. tostring(opcode) .. "' fallo")
            end
        end
    end
end

------------------------------------------------------------
-- Envio / recuperacion
------------------------------------------------------------
local function FlushOutbox()
    local store = Store()
    local me = MyName()
    for id, entry in pairs(store.outbox) do
        RawBroadcast(BuildEnvelope("M", id, me, entry.to, entry.opcode, entry.payload))
    end
end

local function SendCatchupRequest()
    RawBroadcast(BuildEnvelope("C", "-", MyName(), "-", "", ""))
end

-- Envio fiable a UN destinatario. Guarda en outbox (persistente) y emite ya. Si el destino esta
-- online, llega y confirma; si no, queda para la proxima coincidencia online. `onDelivered` (opcional)
-- se invoca al recibir el ACK; es runtime (no sobrevive a /reload), pero el estado de entrega sigue
-- siendo consultable con IsPending (el outbox persiste).
function API.Send(toName, opcode, payload, onDelivered)
    toName = ShortName(toName)
    opcode = tostring(opcode or "")
    if toName == "" or opcode == "" then return nil end
    local store = Store()
    Prune()
    -- Cap del outbox: si esta lleno, descarta la entrada mas antigua (mejor perder la mas vieja
    -- que rechazar el envio nuevo).
    local count, oldestId, oldestAt = 0, nil, nil
    for oid, e in pairs(store.outbox) do
        count = count + 1
        if not oldestAt or (e.sentAt or 0) < oldestAt then oldestAt, oldestId = e.sentAt or 0, oid end
    end
    if count >= MAX_OUTBOX and oldestId then store.outbox[oldestId] = nil end

    local id = GenId()
    store.outbox[id] = { to = toName, opcode = opcode, payload = tostring(payload or ""), sentAt = time and time() or 0 }
    if type(onDelivered) == "function" then deliveryCbs[id] = onDelivered end
    RawBroadcast(BuildEnvelope("M", id, MyName(), toName, opcode, tostring(payload or "")))
    return id
end

-- ¿Sigue sin confirmar (en el outbox)? Permite un estado de "entregado" seguro ante /reload:
-- entregado == not IsPending(courierId).
function API.IsPending(msgId)
    return msgId ~= nil and Store().outbox[msgId] ~= nil
end

function API.RegisterHandler(opcode, fn)
    if type(opcode) == "string" and type(fn) == "function" then handlers[opcode] = fn end
end

function API.IsReady()
    return (aceComm and channelIndex and channelIndex ~= 0) and true or false
end

function API.GetStatus()
    local store = Store()
    local outN, seenN = 0, 0
    for _ in pairs(store.outbox) do outN = outN + 1 end
    for _ in pairs(store.seen) do seenN = seenN + 1 end
    return {
        aceComm = aceComm ~= nil,
        channelIndex = channelIndex,
        ready = API.IsReady(),
        outbox = outN,
        seen = seenN,
        handlers = handlers,
    }
end

------------------------------------------------------------
-- Init (por eventos; sin reintentos de arranque agresivos)
------------------------------------------------------------
local function EnsureAceComm()
    if aceComm then return true end
    if not LibStub then return false end
    local ok, lib = pcall(LibStub.GetLibrary, LibStub, "AceComm-3.0", true)
    if ok and lib then
        aceComm = lib
        aceComm:RegisterComm(COMM_PREFIX, function(_, message, _, sender)
            HandleEnvelope(message, sender)
        end)
        return true
    end
    return false
end

local function OnReady()
    -- Con AceComm + canal listos: reemite lo pendiente y pide catch-up.
    if not API.IsReady() then return end
    Prune()
    FlushOutbox()
    SendCatchupRequest()
end

local initialized = false
local function Init()
    if not EnsureAceComm() then return end
    if not initialized then
        initialized = true
        InstallChannelFilter()
    end
    TryJoinChannel()
    -- Da un instante a que el cliente confirme la union antes del primer flush.
    if C_Timer and C_Timer.After then
        C_Timer.After(1, OnReady)
    else
        OnReady()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHANNEL_UI_UPDATE")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        Init()
    elseif event == "CHANNEL_UI_UPDATE" then
        -- El cliente confirmo/actualizo canales: re-resolver indice y, si acabamos de unirnos,
        -- disparar el flush pendiente.
        local had = API.IsReady()
        channelIndex = ResolveChannelIndex()
        if API.IsReady() and not had then OnReady() end
    end
end)
