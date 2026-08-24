-- Comunicador Harford: version segura inspirada en Noumenon Index.
-- Solo transporta texto entre clientes Harford; nunca comandos ni datos de juego.

HarfordCommunicator = HarfordCommunicator or {}

local API = HarfordCommunicator
local PREFIX = "HARFCOM"
local MAX_HISTORY, MAX_CHUNKS, CHUNK_BYTES = 100, 16, 180
local TRANSFER_TTL, DEDUPE_TTL = 30, 300
local COMMUNICATOR_ITEM_ID = 14085291
local store, selectedKey, frame
local inbound, received, pendingGroups = {}, {}, {}
local communicatorAuraActive = false
local ShowContacts, ShowGroups, ShowChat, ShowOptions, ShowContracts, ShowRadio
local RefreshUnreadIndicator
local lastRingAt = 0

local RADIO_STATIONS = {
    { name = "Radio Tiragarde", soundId = 2179260 },
    { name = "Pixel Muerto", soundId = 3038651 },
    { name = "Radio Chapaleos", soundId = 450391 },
    { name = "Disco Eterno", soundId = 567382 },
    { name = "Radio Mechagon", soundId = 3038646 },
    { name = "100 Populares", soundId = 1674366 },
    { name = "El Frente Reluciente", soundId = 3038652 },
    { name = "Susurros de Darrow", soundId = 1538389 },
}

local EMOJIS = {
    [":dado:"] = 237284, [":calavera:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    [":corazon:"] = 135451, [":mision:"] = 4072784, [":alerta:"] = 512904,
    [":espada:"] = 135274, [":escudo:"] = 134952, [":fuego:"] = 135805,
    [":agua:"] = 135861, [":tierra:"] = 132846, [":aire:"] = 132845,
    [":luna:"] = 236704, [":estrellita:"] = 135972, [":pocion:"] = 134829,
    [":ping:"] = 4359250, [":noping:"] = 4352553, [":connect:"] = 4359254,
    [":disconnect:"] = 4359256, [":non:"] = 4359260, [":noff:"] = 4359259,
    [":bon:"] = 4359252, [":boff:"] = 4359251, [":mon:"] = 4359258,
    [":moff:"] = 4359257, [":oon:"] = 4359262, [":ooff:"] = 4359261,
    [":reg:"] = 1397643, [":dec:"] = 1397642, [":op:"] = 1397645,
    [":gmail:"] = 413580, [":mapa:"] = 237387, [":llave:"] = 136058,
    [":notas:"] = 4072784, [":tarjetas:"] = 418250, [":portal:"] = 135748,
    [":cuchillo:"] = 463557, [":pistola:"] = 30090345, [":bomba:"] = 512904,
    [":jazz:"] = 4058847, [":pregunta:"] = 134400, [":risa:"] = 3750310,
    [":sonrisa:"] = 237554, [":enfado:"] = 237553, [":triste:"] = 237555,
    [":pulgararriba:"] = 461267, [":pulgarabajo:"] = 456031, [":rezar:"] = 458227,
    [":flex:"] = 136101, [":beso:"] = 30090326, [":zzz:"] = 1029723,
    [":gato:"] = 656576, [":perro:"] = 22413107, [":pez:"] = 133916,
    [":pollo:"] = 2027860, [":raton:"] = 647701, [":caballo:"] = 132261,
    [":horda:"] = 2173920, [":alianza:"] = 2173919, [":bastion:"] = 3257748,
    [":maldraxxus:"] = 3257749, [":ardenweald:"] = 3257750, [":revendreth:"] = 3257751,
    [":elfosangre:"] = 236440, [":humano:"] = 236448, [":orco:"] = 236452,
    [":enano:"] = 236444, [":gnomo:"] = 236446, [":tauren:"] = 236454,
    [":troll:"] = 236456, [":no-muerto:"] = 236458,
    [":estrella:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    [":circulo:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
    [":rombo:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    [":triangulo:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
    [":lunaobjetivo:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
    [":cuadrado:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    [":cruz:"] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    [":oro:"] = { path = "Interface\\MoneyFrame\\UI-MoneyIcons", coords = { 0, .25, 0, 1 } },
    [":plata:"] = { path = "Interface\\MoneyFrame\\UI-MoneyIcons", coords = { .25, .5, 0, 1 } },
    [":cobre:"] = { path = "Interface\\MoneyFrame\\UI-MoneyIcons", coords = { .5, .75, 0, 1 } },
}

local function Print(msg)
    HarfordChat.Print(msg)
end

local function PlayRadioStation(station)
    local music = TRP3_API and TRP3_API.utils and TRP3_API.utils.music
    if not (music and type(music.playLocalMusic) == "function") then
        Print("La radio requiere Total RP 3 Extended.")
        return false
    end
    music.playLocalMusic(station.soundId, 25)
    return true
end

local function Now() return time and time() or 0 end

local function ShortName(name)
    name = tostring(name or "")
    return Ambiguate and Ambiguate(name, "short") or name:match("^([^-]+)") or name
end

local function FullPlayerName()
    return (GetUnitName and GetUnitName("player", true)) or UnitName("player") or "Jugador"
end

local function Escape(value)
    return (tostring(value or ""):gsub("%%", "%%25"):gsub("|", "%%7C"):gsub("~", "%%7E"):gsub("\n", "%%0A"):gsub("\r", ""))
end

local function Unescape(value)
    return (tostring(value or ""):gsub("%%(%x%x)", function(hex)
        local n = tonumber(hex, 16)
        return n and string.char(n) or ""
    end))
end

local function EmojiPath(data)
    return type(data) == "table" and data.path or data
end

local function SetEmojiTexture(texture, data)
    texture:SetTexture(EmojiPath(data))
    if type(data) == "table" and data.coords then texture:SetTexCoord(unpack(data.coords)) else texture:SetTexCoord(0, 1, 0, 1) end
end

local function RenderEmojis(text, size)
    size = size or 16
    for token, data in pairs(EMOJIS) do
        local path = EmojiPath(data)
        local markup
        if type(data) == "table" and data.coords then
            local c = data.coords
            markup = string.format("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t", path, size, size, c[1] * 64, c[2] * 64, c[3] * 64, c[4] * 64)
        else
            markup = string.format("|T%s:%d|t", path, size)
        end
        -- El token es texto LITERAL, no un patron: escapamos sus caracteres magicos (p.ej. el `-`
        -- de ":no-muerto:") y los `%` del reemplazo, para que gsub lo trate como cadena exacta.
        local pattern = token:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
        text = text:gsub(pattern, (markup:gsub("%%", "%%%%")))
    end
    return text
end

local function EnsureStore()
    HarfordCommunicatorStore = type(HarfordCommunicatorStore) == "table" and HarfordCommunicatorStore or {}
    HarfordCommunicatorStore.contacts = type(HarfordCommunicatorStore.contacts) == "table" and HarfordCommunicatorStore.contacts or {}
    HarfordCommunicatorStore.messages = type(HarfordCommunicatorStore.messages) == "table" and HarfordCommunicatorStore.messages or {}
    HarfordCommunicatorStore.groups = type(HarfordCommunicatorStore.groups) == "table" and HarfordCommunicatorStore.groups or {}
    HarfordCommunicatorStore.options = type(HarfordCommunicatorStore.options) == "table" and HarfordCommunicatorStore.options or {}
    if not HarfordCommunicatorStore.options.ringTone
        or HarfordCommunicatorStore.options.ringTone == "'s Comunicador Harford emite una señal."
        or HarfordCommunicatorStore.options.ringTone == "activa su Comunicador Harford."
        or HarfordCommunicatorStore.options.ringTone == "comunicador emite un pitido." then
        HarfordCommunicatorStore.options.ringTone = "Su comunicador emite un pitido."
    end
    HarfordCommunicatorStore.options.visual = type(HarfordCommunicatorStore.options.visual) == "table" and HarfordCommunicatorStore.options.visual or {}
    local visual = HarfordCommunicatorStore.options.visual
    visual.title = type(visual.title) == "table" and visual.title or { 1, 1, 1, 1 }
    visual.background = type(visual.background) == "table" and visual.background or { 0, 0, 0, .8 }
    visual.wisps = type(visual.wisps) == "table" and visual.wisps or { 1, 1, 1, .3 }
    visual.buttons = type(visual.buttons) == "table" and visual.buttons or { 1, 1, 1, 0 }
    store = HarfordCommunicatorStore
    return store
end

local function HasCommunicatorItem()
    local count
    if C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(COMMUNICATOR_ITEM_ID, false, false)
    elseif GetItemCount then
        count = GetItemCount(COMMUNICATOR_ITEM_ID, false, false)
    end
    return (tonumber(count) or 0) > 0
end

local function SetCommunicatorAura(active)
    if not (HarfordAuras and HarfordAuras.Apply and HarfordAuras.Remove) then return end
    if active then
        if communicatorAuraActive then return end
        local ok = HarfordAuras.Apply("communicator", nil, {
            addonName = "Harford",
            forceEpsilon = true,
            showMessages = false,
        })
        communicatorAuraActive = ok == true
    elseif communicatorAuraActive then
        HarfordAuras.Remove("communicator", nil, {
            addonName = "Harford",
            forceEpsilon = true,
            showMessages = false,
        })
        communicatorAuraActive = false
    end
end

local function LocalHandle()
    EnsureStore()
    local handle = tostring(store.options.handle or ""):match("^%s*(.-)%s*$")
    return handle ~= "" and handle or ShortName(FullPlayerName())
end

local function Conversation(key)
    EnsureStore()
    store.messages[key] = type(store.messages[key]) == "table" and store.messages[key] or {}
    return store.messages[key]
end

local function AddMessage(key, message)
    if not key or key == "" then return end
    local list = Conversation(key)
    list[#list + 1] = message
    while #list > MAX_HISTORY do table.remove(list, 1) end
end

local function ContactKey(name) return "p:" .. tostring(name or "") end
local function GroupKey(id) return "g:" .. tostring(id or "") end

local function FindContact(name)
    EnsureStore()
    for existing in pairs(store.contacts) do
        if existing == name or ShortName(existing) == ShortName(name) then return existing end
    end
end

local function AddContact(name)
    name = tostring(name or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil end
    EnsureStore()
    local existing = FindContact(name)
    if existing then return existing end
    store.contacts[name] = { name = name, alias = ShortName(name) }
    return name
end

local function MakeId()
    return string.format("%x%x%x", Now(), math.floor((GetTime and GetTime() or 0) * 1000) % 0xFFFF, math.random(0, 0xFFFF))
end

local function PruneRuntime()
    local now = Now()
    for id, item in pairs(inbound) do if now - (item.createdAt or now) > TRANSFER_TTL then inbound[id] = nil end end
    for id, seenAt in pairs(received) do if now - seenAt > DEDUPE_TTL then received[id] = nil end end
    for groupId, entries in pairs(pendingGroups) do
        for index = #entries, 1, -1 do
            if now - (entries[index].createdAt or now) > TRANSFER_TTL then table.remove(entries, index) end
        end
        if #entries == 0 then pendingGroups[groupId] = nil end
    end
end

local function SendRaw(target, payload)
    if not HarfordSync or not HarfordSync.Send then return false, "HarfordSync no disponible" end
    return HarfordSync.Send(PREFIX, payload, "WHISPER", target)
end

local function RefreshUI()
    if frame and frame:IsShown() then API.Refresh() end
end

local function SamePlayer(a, b)
    return a == b or (a and b and ShortName(a) == ShortName(b))
end

local function IsGroupMember(group, name)
    if not group or type(group.members) ~= "table" then return false end
    for member, enabled in pairs(group.members) do
        if enabled and SamePlayer(member, name) then return true end
    end
    return false
end

local function GroupMembers(group)
    local out = {}
    for name, enabled in pairs(group.members or {}) do if enabled and not SamePlayer(name, FullPlayerName()) then out[#out + 1] = name end end
    table.sort(out)
    return out
end

-- ¿Esta el bus fiable HarfordCourier operativo? Si lo esta, es el transporte preferido (entrega
-- eventual a quien reconecte); si no, se cae al WHISPER troceado heredado (solo online).
local function CourierReady()
    return HarfordCourier and HarfordCourier.IsReady and HarfordCourier.IsReady() and true or false
end

local function SendGroupDefinition(group, recipients)
    local members = {}
    for name, enabled in pairs(group.members or {}) do if enabled then members[#members + 1] = Escape(name) end end
    -- Campos comunes (mismos que el mensaje "D" heredado, sin el prefijo): id|owner|name|memberBlob.
    local defFields = table.concat({ Escape(group.id), Escape(group.owner), Escape(group.name), table.concat(members, "~") }, "|")
    local legacyPayload = "D|" .. defFields
    for _, target in ipairs(recipients or GroupMembers(group)) do
        if CourierReady() then
            HarfordCourier.Send(target, "CDEF", defFields)
        else
            SendRaw(target, legacyPayload)
        end
    end
end

local function Notify(key, message)
    local mode = tonumber(store.options.notifyMode) or 2
    if RefreshUnreadIndicator then RefreshUnreadIndicator() end
    -- Sin comunicador utilizable se conserva el historial, pero no se emite
    -- ningun aviso visible ni emote al receptor.
    if not HasCommunicatorItem() then return end
    if mode ~= 3 and not store.options.silent and HarfordUISounds and HarfordUISounds.Play then
        HarfordUISounds.Play("communicator_message_received")
    end
    -- Con el comunicador visible, el propio panel ya es el aviso. No repetimos
    -- emotes, mensajes locales ni destellos fuera de la ventana. El sonido si
    -- se mantiene: confirma la recepcion aunque el historial este abierto.
    if frame and frame:IsShown() then return end
    if mode == 3 then return end

    -- Equivalente al NewMsgRing de Noumenon: verde emite una señal, amarillo
    -- deja constancia en el chat y rojo no genera aviso externo.
    local senderLabel = message.sender
    if not senderLabel then
        local privateName = type(key) == "string" and key:match("^p:(.+)$")
        senderLabel = privateName and store.contacts[privateName] and store.contacts[privateName].alias or "un contacto"
    end
    local groupId = type(key) == "string" and key:match("^g:(.+)$")
    if groupId then
        local group = store.groups[groupId]
        senderLabel = senderLabel .. " en " .. (group and group.name or "un grupo")
    end
    local emittedAlert = false
    if not store.options.silent and mode == 1 then
        local now = GetTime and GetTime() or 0
        if now - lastRingAt >= 20 then
            lastRingAt = now
            SendChatMessage(store.options.ringTone, "EMOTE", nil)
            emittedAlert = true
        end
    elseif not store.options.silent and mode == 2 then
        Print("Nuevo mensaje de " .. senderLabel .. ".")
        emittedAlert = true
    end

    if emittedAlert and FlashClientIcon then FlashClientIcon() end
    if emittedAlert and UIFrameFlash and frame and frame.appBar and frame.appBar.contacts then
        UIFrameFlash(frame.appBar.contacts, 0.2, 0.2, 1, false, 0, 0)
    end
end

local function MarkDelivered(contact, id)
    local key = ContactKey(FindContact(contact) or contact)
    for _, message in ipairs(Conversation(key)) do
        if message.id == id and message.sent then message.delivered = true; break end
    end
end

local function IsViewingConversation(key)
    return frame and frame:IsShown() and frame.chat and frame.chat:IsShown() and selectedKey == key
end

local function AddIncomingMessage(key, sender, id, text, isGroup, handle)
    local message = {
        id = id,
        text = text,
        sent = false,
        delivered = true,
        sender = handle ~= "" and handle or (isGroup and ShortName(sender) or nil),
        timestamp = Now(),
        read = IsViewingConversation(key),
    }
    AddMessage(key, message)
    Notify(key, message)
end

local function ReceiveChunk(sender, channelKey, id, part, total, chunk, isGroup, handle)
    part, total = tonumber(part), tonumber(total)
    if not sender or sender == "" or not id or not part or not total or total < 1 or total > MAX_CHUNKS or part < 1 or part > total or #chunk > CHUNK_BYTES + 20 then return end
    -- Los susurros privados no tienen canal de grupo: usan una clave estable
    -- vacia solo para el buffer y la deduplicacion de fragmentos.
    channelKey = isGroup and channelKey or ""
    PruneRuntime()
    local dedupeKey = sender .. "|" .. channelKey .. "|" .. id
    if received[dedupeKey] then return end
    local pending = inbound[dedupeKey]
    if not pending then pending = { total = total, chunks = {}, createdAt = Now() }; inbound[dedupeKey] = pending end
    if pending.total ~= total then inbound[dedupeKey] = nil; return end
    pending.chunks[part] = chunk
    for index = 1, total do if not pending.chunks[index] then return end end
    local text = Unescape(table.concat(pending.chunks))
    inbound[dedupeKey], received[dedupeKey] = nil, Now()
    local key
    if isGroup then
        local group = store.groups[channelKey]
        if not group then
            -- Noumenon conserva los mensajes de grupo que llegan antes que la
            -- definicion del grupo. Hacemos lo mismo, con TTL y limite.
            local queue = pendingGroups[channelKey] or {}
            if #queue < MAX_HISTORY then
                queue[#queue + 1] = { sender = sender, id = id, text = text, handle = Unescape(handle or ""), createdAt = Now() }
                pendingGroups[channelKey] = queue
            end
            return
        end
        if not IsGroupMember(group, sender) then return end
        key = GroupKey(channelKey)
    else
        local contact = AddContact(sender)
        key = ContactKey(contact)
        SendRaw(sender, "A|" .. id)
    end
    AddIncomingMessage(key, sender, id, text, isGroup, Unescape(handle or ""))
    RefreshUI()
end

local function ReceiveDefinition(sender, id, owner, name, members)
    id, owner, name = Unescape(id), Unescape(owner), Unescape(name)
    -- `sender` puede llegar corto y `owner` con `-Realm` (o al reves): comparar normalizado como el
    -- resto del modulo (SamePlayer). Con `sender ~= owner` crudo, la definicion se descartaba y al
    -- resto de miembros NO les aparecia el grupo.
    if id == "" or owner == "" or name == "" or not SamePlayer(sender, owner) then return end
    local group = { id = id, owner = owner, name = name, members = {} }
    for member in tostring(members or ""):gmatch("([^~]+)") do group.members[Unescape(member)] = true end
    group.members[owner] = true
    if not IsGroupMember(group, FullPlayerName()) then return end
    store.groups[id] = group
    local queued = pendingGroups[id]
    if queued then
        pendingGroups[id] = nil
        for _, message in ipairs(queued) do
            if IsGroupMember(group, message.sender) then
                AddIncomingMessage(GroupKey(id), message.sender, message.id, message.text, true, message.handle)
            end
        end
    end
    RefreshUI()
end

function API.HandleAddonMessage(prefix, payload, sender)
    if prefix ~= PREFIX or type(payload) ~= "string" or not sender or sender == "" then return false end
    EnsureStore()
    local kind, rest = payload:match("^(%u)|?(.*)$")
    if kind == "A" then MarkDelivered(sender, rest); RefreshUI(); return true end
    local fields = {}
    for part in (rest .. "|"):gmatch("(.-)|") do fields[#fields + 1] = part end
    if kind == "M" then ReceiveChunk(sender, nil, fields[1], fields[2], fields[3], fields[4] or "", false, fields[5])
    elseif kind == "G" then ReceiveChunk(sender, Unescape(fields[1]), fields[2], fields[3], fields[4], fields[5] or "", true, fields[6])
    elseif kind == "D" then ReceiveDefinition(sender, fields[1], fields[2], fields[3], fields[4]) end
    return true
end

local function SendChunks(target, prefix, id, encoded, handle)
    local total = math.ceil(#encoded / CHUNK_BYTES)
    if total > MAX_CHUNKS then return false, "El mensaje es demasiado largo" end
    for part = 1, total do
        local at = (part - 1) * CHUNK_BYTES + 1
        local payload = prefix .. "|" .. id .. "|" .. part .. "|" .. total .. "|" .. encoded:sub(at, at + CHUNK_BYTES - 1) .. "|" .. Escape(handle or "")
        local ok, err = SendRaw(target, payload)
        if not ok then return false, err or "No se pudo enviar" end
    end
    return true
end

function API.Send(target, text)
    EnsureStore()
    text = tostring(text or ""):match("^%s*(.-)%s*$")
    if text == "" then return false, "Escribe un mensaje" end
    local id, encoded, handle = MakeId(), Escape(text), LocalHandle()
    local group = type(target) == "string" and target:match("^g:(.+)$") and store.groups[target:match("^g:(.+)$")]
    if group then
        local members = GroupMembers(group)
        if #members == 0 then return false, "El grupo no tiene destinatarios" end
        AddMessage(target, { id = id, text = text, sent = true, delivered = true, sender = "Tu", timestamp = Now() })
        -- Fan-out POR MIEMBRO: cada uno recibe su copia fiable (asi el que estaba offline la recibe
        -- al reconectar). Payload de grupo: groupId|id|handle|texto (todo escapado).
        local groupPayload = table.concat({ Escape(group.id), Escape(id), Escape(handle or ""), encoded }, "|")
        for _, member in ipairs(members) do
            if CourierReady() then
                HarfordCourier.Send(member, "CGRP", groupPayload)
            else
                local total = math.ceil(#encoded / CHUNK_BYTES)
                if total > MAX_CHUNKS then return false, "El mensaje es demasiado largo" end
                for part = 1, total do
                    local at = (part - 1) * CHUNK_BYTES + 1
                    local payload = string.format("G|%s|%s|%d|%d|%s|%s", Escape(group.id), id, part, total, encoded:sub(at, at + CHUNK_BYTES - 1), Escape(handle))
                    local ok, err = SendRaw(member, payload)
                    if not ok then return false, err or "No se pudo enviar" end
                end
            end
        end
    else
        -- La UI identifica los hilos privados como p:<nombre>; el transporte
        -- WHISPER necesita el nombre real, nunca la clave interna del hilo.
        local contact = AddContact(type(target) == "string" and target:match("^p:(.+)$") or target)
        if not contact then return false, "Indica un destinatario" end
        local key = ContactKey(contact)
        local outgoing = { id = id, text = text, sent = true, delivered = false, timestamp = Now() }
        AddMessage(key, outgoing)
        if CourierReady() then
            -- Payload DM: id|handle|texto (escapado). El estado "entregado" lo marca el ACK del courier.
            local dmPayload = table.concat({ Escape(id), Escape(handle or ""), encoded }, "|")
            outgoing.courierId = HarfordCourier.Send(contact, "CDM", dmPayload, function()
                MarkDelivered(contact, id); RefreshUI()
            end)
        else
            local ok, err = SendChunks(contact, "M", id, encoded, handle)
            if not ok then RefreshUI(); return false, err end
        end
    end
    RefreshUI()
    return true
end

function API.AddContact(name)
    local contact = AddContact(name)
    if contact then selectedKey = ContactKey(contact); RefreshUI() end
    return contact
end

function API.RemoveContact(name)
    EnsureStore(); name = FindContact(name) or name
    store.contacts[name], store.messages[ContactKey(name)] = nil, nil
    if selectedKey == ContactKey(name) then selectedKey = nil end
    RefreshUI()
end

function API.CreateGroup(name, members)
    EnsureStore(); name = tostring(name or ""):match("^%s*(.-)%s*$")
    if name == "" then return nil, "Indica un nombre" end
    local me, id = FullPlayerName(), MakeId()
    local group = { id = id, owner = me, name = name, members = { [me] = true } }
    for _, member in ipairs(members or {}) do member = AddContact(member); if member then group.members[member] = true end end
    store.groups[id] = group
    SendGroupDefinition(group)
    selectedKey = GroupKey(id); RefreshUI()
    return id
end

function API.AddGroupMember(id, name)
    EnsureStore(); local group = store.groups[id]
    if not group or group.owner ~= FullPlayerName() then return false, "Solo el creador puede modificar el grupo" end
    name = AddContact(name); if not name then return false, "Indica un contacto" end
    group.members[name] = true; SendGroupDefinition(group); RefreshUI(); return true
end

function API.RemoveGroupMember(id, name)
    EnsureStore(); local group = store.groups[id]
    if not group or group.owner ~= FullPlayerName() then return false, "Solo el creador puede modificar el grupo" end
    if name ~= group.owner then group.members[name] = nil end
    SendGroupDefinition(group); RefreshUI(); return true
end

function API.DeleteGroup(id)
    EnsureStore(); store.groups[id], store.messages[GroupKey(id)] = nil, nil
    if selectedKey == GroupKey(id) then selectedKey = nil end
    RefreshUI()
end

function API.GetContacts()
    EnsureStore()
    return store.contacts
end

function API.GetGroups()
    EnsureStore()
    return store.groups
end

function API.OpenChat(key)
    EnsureStore()
    if type(key) == "string" and (key:match("^p:") or key:match("^g:")) then
        selectedKey = key
    else
        local contact = AddContact(key)
        if not contact then return false end
        selectedKey = ContactKey(contact)
    end
    API.Open()
    ShowChat()
    return true
end

local function CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAtlas("UI-Frame-CypherChoice-HideButton")
    button.bg:SetAllPoints()
    button.label = button:CreateFontString(nil, "OVERLAY", "SystemFont_Outline")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button.label:SetTextColor(1, .82, 0)
    button:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 1, 1) end)
    button:SetScript("OnLeave", function(self) self.label:SetTextColor(1, .82, 0) end)
    return button
end

local function CreateCypherButton(parent, text, xOffset, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(90, 40)
    button:SetPoint("BOTTOM", xOffset, 2.5)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAtlas("UI-Frame-CypherChoice-HideButton")
    button.bg:SetAllPoints()
    button.label = button:CreateFontString(nil, "OVERLAY", "SystemFont_Outline")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button.label:SetTextColor(1, .82, 0)
    button:SetScript("OnClick", callback)
    return button
end

local function ApplyVisuals()
    if not frame or not store or not store.options.visual then return end
    local visual = store.options.visual
    if frame.contractsOpen then frame:SetBackdropColor(0, 0, 0, 0) else frame:SetBackdropColor(unpack(visual.background)) end
    frame.wisps:SetVertexColor(unpack(visual.wisps))
    frame.titleBar:SetVertexColor(unpack(visual.title))
    for _, button in ipairs(frame.appBar.buttons or {}) do
        if button.overlay then button.overlay:SetColorTexture(unpack(visual.buttons)) end
    end
end

local function OpenColorPicker(option)
    local r, g, b, a = unpack(option); a = a or 1
    local previous = { r, g, b, a }
    ColorPickerFrame:Hide()
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = nil, nil, nil
    ColorPickerFrame:SetColorRGB(r, g, b); ColorPickerFrame.hasOpacity = true; ColorPickerFrame.opacity = 1 - a
    local function Apply(r1, g1, b1, a1)
        option[1], option[2], option[3], option[4] = r1, g1, b1, a1
        ApplyVisuals()
    end
    ColorPickerFrame.func = function()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        Apply(nr, ng, nb, 1 - OpacitySliderFrame:GetValue())
    end
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.cancelFunc = function() Apply(unpack(previous)) end
    ColorPickerFrame.previousValues = previous
    ColorPickerFrame:Show()
end

StaticPopupDialogs.HARFORD_COMM_ADD_MEMBER = StaticPopupDialogs.HARFORD_COMM_ADD_MEMBER or {
    text = "Anadir contacto al grupo",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 60,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
    end,
    OnAccept = function(self, data)
        local ok, err = API.AddGroupMember(data, self.editBox:GetText())
        if not ok then Print(err) end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local ok, err = API.AddGroupMember(parent.data, self:GetText())
        if not ok then Print(err) end
        parent:Hide()
    end,
}

-- Crea un grupo desde el texto del popup: "Nombre, Personaje, Personaje...". Sin miembros el grupo
-- queda vacio (no hay a quien enviar la definicion ni mensajes), asi que se recogen aqui como Noumenon.
local function CreateGroupFromInput(input)
    input = tostring(input or "")
    local parts = {}
    for part in input:gmatch("([^,]+)") do parts[#parts + 1] = part:match("^%s*(.-)%s*$") end
    local name = table.remove(parts, 1)
    local members = {}
    for _, m in ipairs(parts) do if m ~= "" then members[#members + 1] = m end end
    local id, err = API.CreateGroup(name, members)
    if not id then Print(err) end
    return id
end

StaticPopupDialogs.HARFORD_COMM_CREATE_GROUP = StaticPopupDialogs.HARFORD_COMM_CREATE_GROUP or {
    text = "Grupo: Nombre, Personaje, Personaje...",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 255,
    editBoxWidth = 260,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
    end,
    OnAccept = function(self)
        CreateGroupFromInput(self.editBox:GetText())
    end,
    EditBoxOnEnterPressed = function(self)
        CreateGroupFromInput(self:GetText())
        self:GetParent():Hide()
    end,
}

StaticPopupDialogs.HARFORD_COMM_ADD_CONTACT = StaticPopupDialogs.HARFORD_COMM_ADD_CONTACT or {
    text = "Nombre del jugador",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 60,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
    end,
    OnAccept = function(self)
        local contact = API.AddContact(self.editBox:GetText())
        if not contact then Print("Indica un jugador.") end
    end,
    EditBoxOnEnterPressed = function(self)
        local contact = API.AddContact(self:GetText())
        if not contact then Print("Indica un jugador.") end
        self:GetParent():Hide()
    end,
}

local function CreateEmojiPicker(parent)
    local picker = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    picker:SetSize(150, 225); picker:SetPoint("LEFT", frame, "RIGHT", 0, 0); picker:SetClampedToScreen(true)
    picker:SetFrameStrata("DIALOG"); picker:SetFrameLevel(parent:GetFrameLevel() + 20)
    picker:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    picker:SetBackdropColor(0, 0, 0, .7); picker:Hide()
    picker.title = picker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); picker.title:SetPoint("TOP", 0, -10); picker.title:SetText("Indice de simbolos")
    picker.search = CreateFrame("EditBox", nil, picker, "InputBoxTemplate"); picker.search:SetSize(112, 18); picker.search:SetPoint("TOP", 0, -32); picker.search:SetAutoFocus(false); picker.search:SetTextInsets(4, 4, 0, 0)
    picker.scroll = CreateFrame("ScrollFrame", nil, picker, "UIPanelScrollFrameTemplate"); picker.scroll:SetPoint("TOPLEFT", 12, -54); picker.scroll:SetPoint("BOTTOMRIGHT", -30, 12)
    picker.content = CreateFrame("Frame", nil, picker.scroll); picker.content:SetSize(1, 1); picker.scroll:SetScrollChild(picker.content)
    picker.buttons = {}
    local keys = {}
    for token in pairs(EMOJIS) do keys[#keys + 1] = token end
    table.sort(keys)
    local function RefreshPicker()
        local filter, index = tostring(picker.search:GetText() or ""):lower(), 0
        for _, token in ipairs(keys) do
            if filter == "" or token:lower():find(filter, 1, true) then
                index = index + 1
                local b = picker.buttons[index]
                if not b then
                    b = CreateFrame("Button", nil, picker.content, "BackdropTemplate"); b:SetSize(24, 24)
                    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" }); b:SetBackdropColor(0, 0, 0, .4)
                    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints(); b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
                    picker.buttons[index] = b
                end
                b:ClearAllPoints(); b:SetPoint("TOPLEFT", ((index - 1) % 4) * 28, -math.floor((index - 1) / 4) * 28)
                b.token = token; SetEmojiTexture(b.icon, EMOJIS[token])
                b:SetScript("OnClick", function(self) frame.chat.input:Insert(self.token); picker:Hide() end)
                b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.token); GameTooltip:Show() end); b:SetScript("OnLeave", GameTooltip_Hide); b:Show()
            end
        end
        for i = index + 1, #picker.buttons do picker.buttons[i]:Hide() end
        picker.content:SetHeight(math.max(1, math.ceil(index / 4) * 28))
    end
    picker.search:SetScript("OnTextChanged", RefreshPicker)
    picker.Refresh = RefreshPicker
    RefreshPicker()
    return picker
end

local function EnsureFrame()
    if frame then return frame end
    frame = CreateFrame("Frame", "HarfordCommunicatorFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 400); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetToplevel(true); frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    frame:SetBackdropColor(0, 0, 0, 0.88)
    frame.wisps = frame:CreateTexture(nil, "BACKGROUND", nil, 1); frame.wisps:SetAllPoints(); frame.wisps:SetAtlas("UI-Frame-CypherChoice-FX-Wisps"); frame.wisps:SetVertexColor(1, 1, 1, 0.20)
    frame.titleBar = frame:CreateTexture(nil, "ARTWORK"); frame.titleBar:SetTexture("Interface\\CovenantSanctum\\CovenantSanctumKyrian"); frame.titleBar:SetTexCoord(0.03, 0.09, 0.904296875, 0.978515625); frame.titleBar:SetHeight(60); frame.titleBar:SetPoint("TOPLEFT", 3, 18); frame.titleBar:SetPoint("TOPRIGHT", -3, 18)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.title:SetPoint("CENTER", frame.titleBar)
    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); frame.close:SetPoint("TOPRIGHT", 3, 3)
    frame.ping = CreateFrame("Button", nil, frame)
    frame.ping:SetSize(18, 18); frame.ping:SetPoint("LEFT", frame.titleBar, "LEFT", 5, 0)
    frame.ping.icon = frame.ping:CreateTexture(nil, "OVERLAY"); frame.ping.icon:SetAllPoints(); frame.ping.icon:SetAtlas("FullAlert-BigSpike")
    local function RefreshPing()
        local mode = tonumber(store.options.notifyMode) or 2
        local color = ({ { 0, 1, 0 }, { 1, 1, 0 }, { 1, 0, 0 } })[mode] or { 1, 1, 0 }
        frame.ping.icon:SetVertexColor(color[1], color[2], color[3])
    end
    frame.ping:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame.ping:SetScript("OnClick", function(_, button)
        if button == "RightButton" then ShowOptions(); return end
        store.options.notifyMode = ((tonumber(store.options.notifyMode) or 2) % 3) + 1
        RefreshPing()
    end)
    frame.ping:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Avisos", 1, .82, 0); GameTooltip:AddLine("Verde: emote de aviso. Amarillo: aviso por chat. Rojo: silencio.", 1, 1, 1, true); GameTooltip:AddLine("Los mensajes pendientes se mantienen en los tres modos.", .8, .8, .8, true); GameTooltip:AddLine("Clic derecho: ajustes visuales.", .8, .8, .8, true); GameTooltip:Show() end); frame.ping:SetScript("OnLeave", GameTooltip_Hide); RefreshPing()
    frame:Hide()

    -- Barra lateral: misma geometria y orden de capas que Noumenon. La ornamentacion
    -- necesita su propio frame level para no mezclarse con el icono al reabrir el panel.
    frame.appBar = CreateFrame("Frame", nil, frame); frame.appBar:SetSize(24, frame:GetHeight()); frame.appBar:SetPoint("LEFT", frame, "LEFT", -28, 0); frame.appBar.buttons = {}
    local function AppButton(icon, tip, y, callback)
        local b = CreateFrame("Button", nil, frame.appBar); b:SetSize(32, 32); b:SetPoint("TOP", 0, y)
        local t = b:CreateTexture(nil, "BACKGROUND"); t:SetAllPoints(); t:SetTexture(icon); b.overlay = b:CreateTexture(nil, "ARTWORK", nil, 1); b.overlay:SetAllPoints(); b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
        b:SetScript("OnClick", callback); b:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(tip, 1, .82, 0); GameTooltip:Show() end); b:SetScript("OnLeave", GameTooltip_Hide)
        frame.appBar.buttons[#frame.appBar.buttons + 1] = b
        return b
    end
    frame.appBar.contacts = AppButton("Interface\\Icons\\INV_Gizmo_01", "Contactos", -4, function() ShowContacts() end)
    frame.appBar.radio = AppButton("Interface\\Icons\\INV_Gizmo_GoblinBoomBox_01", "Radio", -42, function() ShowRadio() end)
    frame.appBar.contracts = AppButton("Interface\\Icons\\INV_Scroll_11", "Contratos", -80, function() ShowContracts() end)
    frame.globalUnread = CreateFrame("Frame", nil, frame)
    frame.globalUnread:SetSize(12, 12)
    frame.globalUnread:SetPoint("TOPLEFT", -10, -26)
    frame.globalUnread:SetFrameStrata("HIGH")
    frame.globalUnread.icon = frame.globalUnread:CreateTexture(nil, "OVERLAY")
    frame.globalUnread.icon:SetAllPoints()
    frame.globalUnread.icon:SetTexture(4359250)
    frame.globalUnread.icon:SetVertexColor(.7, .1, .1)
    frame.globalUnread:Hide()
    frame.appBar.finery = CreateFrame("Frame", nil, frame.appBar)
    frame.appBar.finery:SetFrameLevel(frame.appBar:GetFrameLevel() + 10)
    frame.appBar.finery:SetPoint("TOPLEFT", frame.appBar.contacts, "TOPLEFT", -6, 6)
    frame.appBar.finery:SetPoint("BOTTOMRIGHT", frame.appBar.contacts, "BOTTOMRIGHT", 6, -6)
    local topCorner = frame.appBar.finery:CreateTexture(nil, "OVERLAY")
    topCorner:SetAtlas("UI-CharacterCreate-Metal-Finery-Corner"); topCorner:SetSize(32, 32); topCorner:SetPoint("CENTER", frame.appBar.contacts, "CENTER", -6, 6); topCorner:SetVertexColor(1, .84, .56, 1)
    local bottomCorner = frame.appBar.finery:CreateTexture(nil, "OVERLAY")
    bottomCorner:SetAtlas("UI-CharacterCreate-Metal-Finery-Corner"); bottomCorner:SetSize(32, 32); bottomCorner:SetPoint("CENTER", frame.appBar.contacts, "CENTER", 6, -6); bottomCorner:SetTexCoord(1, 0, 1, 0); bottomCorner:SetVertexColor(1, .84, .56, 1)
    local detailLine = frame.appBar.finery:CreateTexture(nil, "OVERLAY")
    detailLine:SetAtlas("Azerite-CenterBG-ChannelGlowBar-Gold"); detailLine:SetPoint("TOPLEFT", frame.appBar.contacts, "TOPLEFT", -5, 0); detailLine:SetPoint("BOTTOMRIGHT", frame.appBar.contacts, "BOTTOMRIGHT", 5, 0)
    frame.appBar.Select = function(button)
        if not button then return end
        frame.appBar.finery:ClearAllPoints()
        frame.appBar.finery:SetPoint("TOPLEFT", button, "TOPLEFT", -6, 6)
        frame.appBar.finery:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -6)
        topCorner:ClearAllPoints(); topCorner:SetPoint("CENTER", button, "CENTER", -6, 6)
        bottomCorner:ClearAllPoints(); bottomCorner:SetPoint("CENTER", button, "CENTER", 6, -6)
        detailLine:ClearAllPoints(); detailLine:SetPoint("TOPLEFT", button, "TOPLEFT", -5, 0); detailLine:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 5, 0)
    end

    local function ContentFrame()
        local f = CreateFrame("Frame", nil, frame)
        f:SetSize(300, 400)
        f:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        return f
    end
    frame.contacts = ContentFrame()
    frame.contacts.search = CreateFrame("EditBox", nil, frame.contacts, "InputBoxTemplate"); frame.contacts.search:SetSize(260, 20); frame.contacts.search:SetPoint("TOP", 3, -30); frame.contacts.search:SetAutoFocus(false); frame.contacts.search:SetTextInsets(5, 5, 0, 0); frame.contacts.search:SetScript("OnTextChanged", function() API.Refresh() end)
    frame.contacts.scroll = CreateFrame("ScrollFrame", nil, frame.contacts, "UIPanelScrollFrameTemplate"); frame.contacts.scroll:SetPoint("TOP", 0, -60); frame.contacts.scroll:SetSize(280, 300)
    frame.contacts.content = CreateFrame("Frame", nil, frame.contacts.scroll); frame.contacts.content:SetSize(280, 300); frame.contacts.scroll:SetScrollChild(frame.contacts.content)
    if frame.contacts.scroll.ScrollBar then frame.contacts.scroll.ScrollBar:Hide(); frame.contacts.scroll.ScrollBar:EnableMouse(false); frame.contacts.scroll.ScrollBar.Show = function() end end
    frame.contacts.addGroup = CreateCypherButton(frame.contacts, "+ Grupo", 15, function() StaticPopup_Show("HARFORD_COMM_CREATE_GROUP") end)
    frame.contacts.addFriend = CreateCypherButton(frame.contacts, "+ Amigo", 100, function()
        if UnitExists("target") and UnitIsPlayer("target") then
            API.AddContact((GetUnitName and GetUnitName("target", true)) or UnitName("target"))
        else
            StaticPopup_Show("HARFORD_COMM_ADD_CONTACT")
        end
    end)
    frame.contactButtons = {}

    frame.groups = ContentFrame(); frame.groups:Hide(); frame.groups.name = CreateFrame("EditBox", nil, frame.groups, "InputBoxTemplate"); frame.groups.name:SetSize(180, 20); frame.groups.name:SetPoint("TOPLEFT", 9, -8); frame.groups.name:SetAutoFocus(false); frame.groups.name:SetTextInsets(5, 5, 0, 0)
    frame.groups.create = CreateButton(frame.groups, "+ Grupo", 75, 22); frame.groups.create:SetPoint("TOPRIGHT", -8, -7); frame.groups.create:SetScript("OnClick", function() local id, err = API.CreateGroup(frame.groups.name:GetText()); if id then frame.groups.name:SetText("") else Print(err) end end)
    frame.groups.scroll = CreateFrame("ScrollFrame", nil, frame.groups, "UIPanelScrollFrameTemplate"); frame.groups.scroll:SetPoint("TOPLEFT", 2, -36); frame.groups.scroll:SetPoint("BOTTOMRIGHT", -18, 5)
    frame.groups.content = CreateFrame("Frame", nil, frame.groups.scroll); frame.groups.content:SetWidth(264); frame.groups.content:SetHeight(1); frame.groups.scroll:SetScrollChild(frame.groups.content); frame.groupButtons = {}

    frame.chat = ContentFrame(); frame.chat:Hide()
    frame.chat.members = CreateButton(frame.chat, "Miembros", 65, 22); frame.chat.members:SetPoint("TOPRIGHT", -7, -6)
    frame.chat.scroll = CreateFrame("ScrollFrame", nil, frame.chat); frame.chat.scroll:SetPoint("TOPLEFT", 8, -35); frame.chat.scroll:SetPoint("BOTTOMRIGHT", -8, 46); frame.chat.content = CreateFrame("Frame", nil, frame.chat.scroll); frame.chat.content:SetWidth(268); frame.chat.content:SetHeight(1); frame.chat.scroll:SetScrollChild(frame.chat.content); frame.chat.scroll:EnableMouseWheel(true); frame.chat.scroll:SetScript("OnMouseWheel", function(self, delta) self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 20))) end)
    frame.chat.content:EnableMouse(true)
    frame.chat.content:SetScript("OnMouseUp", function(_, button)
        if button ~= "RightButton" then return end
        for _, line in ipairs(frame.chat.lines) do
            if line:IsShown() and line:IsMouseOver() then
                local text = line._harfordPlainText or ""
                frame.chat.input:SetText(text)
                frame.chat.input:SetFocus()
                frame.chat.input:HighlightText(0, #text)
                break
            end
        end
    end)
    frame.chat.input = CreateFrame("EditBox", nil, frame.chat, "InputBoxTemplate"); frame.chat.input:SetAutoFocus(false); frame.chat.input:SetPoint("BOTTOMLEFT", 15, 10); frame.chat.input:SetHeight(25); frame.chat.input:SetTextInsets(5, 5, 0, 0)
    frame.chat.input:SetScript("OnEnterPressed", function(self) local ok, err = API.Send(selectedKey, self:GetText()); if ok then self:SetText("") else Print(err) end end)
    frame.chat.send = CreateButton(frame.chat, "Enviar", 60, 32); frame.chat.send:SetPoint("BOTTOMRIGHT", -5, 6); frame.chat.send:SetScript("OnClick", function() local ok, err = API.Send(selectedKey, frame.chat.input:GetText()); if ok then frame.chat.input:SetText("") else Print(err) end end)
    frame.chat.emoji = CreateButton(frame.chat, ":)", 28, 32); frame.chat.emoji:SetPoint("BOTTOMRIGHT", frame.chat.send, "BOTTOMLEFT", -4, 0)
    frame.chat.input:SetPoint("BOTTOMRIGHT", frame.chat.emoji, "BOTTOMLEFT", -6, 0)
    frame.chat.picker = CreateEmojiPicker(frame.chat); frame.chat.emoji:SetScript("OnClick", function() frame.chat.picker:SetShown(not frame.chat.picker:IsShown()) end); frame.chat.lines = {}

    frame.options = ContentFrame(); frame.options:Hide(); frame.options.title = frame.options:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); frame.options.title:SetPoint("TOP", 0, -42); frame.options.title:SetText("Ajustes del comunicador")
    frame.options.handleLabel = frame.options:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.options.handleLabel:SetPoint("TOPLEFT", 50, -76); frame.options.handleLabel:SetText("Alias local")
    frame.options.handle = CreateFrame("EditBox", nil, frame.options, "InputBoxTemplate"); frame.options.handle:SetSize(200, 20); frame.options.handle:SetPoint("TOP", 0, -96); frame.options.handle:SetAutoFocus(false); frame.options.handle:SetTextInsets(5, 5, 0, 0); frame.options.handle:SetScript("OnTextChanged", function(self) store.options.handle = self:GetText() end)
    local function VisualButton(text, y, key)
        local button = CreateButton(frame.options, text, 200, 24)
        button:SetPoint("TOP", 0, y)
        button:SetScript("OnClick", function() OpenColorPicker(store.options.visual[key]) end)
    end
    VisualButton("Color de cabecera", -136, "title")
    VisualButton("Fondo", -164, "background")
    VisualButton("Espirales", -192, "wisps")
    VisualButton("Iconos laterales", -220, "buttons")
    frame.options.silent = CreateFrame("CheckButton", nil, frame.options, "UICheckButtonTemplate"); frame.options.silent:SetPoint("TOPLEFT", 45, -254); frame.options.silent.text = frame.options.silent:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.options.silent.text:SetPoint("LEFT", frame.options.silent, "RIGHT", 2, 0); frame.options.silent.text:SetText("No avisar por chat al recibir mensajes"); frame.options.silent:SetScript("OnClick", function(self) store.options.silent = self:GetChecked() and true or false end)
    frame.options.reset = CreateButton(frame.options, "Restaurar aspecto", 116, 24); frame.options.reset:SetPoint("TOPLEFT", 32, -286); frame.options.reset:SetScript("OnClick", function()
        store.options.visual = { title = { 1, 1, 1, 1 }, background = { 0, 0, 0, .8 }, wisps = { 1, 1, 1, .3 }, buttons = { 1, 1, 1, 0 } }
        ApplyVisuals()
    end)
    frame.options.clear = CreateButton(frame.options, "Borrar historial", 116, 24); frame.options.clear:SetPoint("TOPLEFT", 152, -286); frame.options.clear:SetScript("OnClick", function() wipe(store.messages); RefreshUI() end)
    frame.radio = ContentFrame(); frame.radio:Hide()
    frame.radio.nowPlaying = frame.radio:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.radio.nowPlaying:SetPoint("TOP", 0, -62); frame.radio.nowPlaying:SetWidth(250)
    frame.radio.nowPlaying:SetJustifyH("CENTER")
    for index, station in ipairs(RADIO_STATIONS) do
        local button = CreateButton(frame.radio, station.name, 248, 30)
        button:SetPoint("TOP", 0, -86 - (index - 1) * 32)
        button:SetScript("OnClick", function()
            if PlayRadioStation(station) then
                frame.radio.nowPlaying:SetText("Sintonizando: " .. station.name)
            end
        end)
    end
    frame.radio.stop = CreateButton(frame.radio, "Apagar radio", 248, 30)
    frame.radio.stop:SetPoint("TOP", 0, -86 - #RADIO_STATIONS * 32)
    frame.radio.stop:SetScript("OnClick", function()
        local music = TRP3_API and TRP3_API.utils and TRP3_API.utils.music
        if music and type(music.stopLocalMusic) == "function" then
            music.stopLocalMusic()
            frame.radio.nowPlaying:SetText("Radio apagada")
        else
            Print("La radio requiere Total RP 3 Extended.")
        end
    end)
    frame:SetScript("OnShow", function()
        if not frame._harfordSuppressAura then SetCommunicatorAura(true) end
    end)
    frame:SetScript("OnHide", function()
        SetCommunicatorAura(false)
    end)
    ApplyVisuals()
    return frame
end

local function HasUnread(key)
    for _, message in ipairs(Conversation(key)) do if not message.sent and not message.read then return true end end
end

RefreshUnreadIndicator = function()
    if not frame or not frame.globalUnread then return end
    local hasUnread = false
    for _, messages in pairs(store.messages or {}) do
        for _, message in ipairs(messages) do
            if not message.sent and not message.read then hasUnread = true; break end
        end
        if hasUnread then break end
    end
    frame.globalUnread:SetShown(hasUnread)
end

local function ButtonLine(parent, cache, index, y, text, unread, isGroup, callback, rightClick)
    local b = cache[index]
    if not b then
        b = CreateFrame("Button", nil, parent); b:SetSize(260, 25); b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetColorTexture(.1, .1, .1, .5); b.text = b:CreateFontString(nil, "OVERLAY", "SystemFont_Outline"); b.text:SetPoint("LEFT", 5, 0); b.dot = b:CreateTexture(nil, "OVERLAY"); b.dot:SetSize(16, 16); b.dot:SetPoint("RIGHT", -5, 0); b.dot:SetTexture(4359256); b.unread = b:CreateTexture(nil, "OVERLAY"); b.unread:SetSize(12, 12); b.unread:SetPoint("RIGHT", -25, 0); b.unread:SetTexture(4359250); b.unread:SetVertexColor(.7, .1, .1); b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); cache[index] = b
    end
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", 10, y); b.text:SetText(text); b.text:SetTextColor(isGroup and 1 or 1, isGroup and .75 or .85, isGroup and .1 or 0)
    b.dot:SetVertexColor(isGroup and 1 or .7, isGroup and .75 or .1, isGroup and .1 or .1); b.unread:SetShown(unread)
    b:SetScript("OnClick", callback); b:SetScript("OnMouseUp", function(_, button) if button == "RightButton" and rightClick then rightClick() end end); b:Show()
end

local function RefreshContacts()
    local ui, filter, entries = EnsureFrame(), tostring(frame.contacts.search:GetText() or ""):lower(), {}
    for name, data in pairs(store.contacts) do
        local label = data.alias or name
        if filter == "" or label:lower():find(filter, 1, true) then entries[#entries + 1] = { key = ContactKey(name), name = name, label = label, group = false } end
    end
    for id, group in pairs(store.groups) do
        if filter == "" or group.name:lower():find(filter, 1, true) then entries[#entries + 1] = { key = GroupKey(id), id = id, label = group.name, group = true } end
    end
    table.sort(entries, function(a, b)
        local unreadA, unreadB = HasUnread(a.key), HasUnread(b.key)
        if unreadA ~= unreadB then return unreadA end
        if a.group ~= b.group then return a.group end
        return a.label:lower() < b.label:lower()
    end)
    local y = -2
    for i, entry in ipairs(entries) do
        ButtonLine(ui.contacts.content, ui.contactButtons, i, y, entry.label, HasUnread(entry.key), entry.group, function() selectedKey = entry.key; ShowChat() end, function()
            if entry.group then API.DeleteGroup(entry.id) else API.RemoveContact(entry.name) end
        end)
        y = y - 30
    end
    for i = #entries + 1, #ui.contactButtons do ui.contactButtons[i]:Hide() end
    ui.contacts.content:SetHeight(math.max(1, -y + 4))
    RefreshUnreadIndicator()
end

local function RefreshGroups()
    local ui, entries = EnsureFrame(), {}
    for id, group in pairs(store.groups) do entries[#entries + 1] = { id = id, group = group } end
    table.sort(entries, function(a, b) return a.group.name:lower() < b.group.name:lower() end)
    local y = -2
    for i, entry in ipairs(entries) do
        local members = #GroupMembers(entry.group)
        ButtonLine(ui.groups.content, ui.groupButtons, i, y, entry.group.name .. " (" .. members .. ")", HasUnread(GroupKey(entry.id)), true, function() selectedKey = GroupKey(entry.id); ShowChat() end, function() if entry.group.owner == FullPlayerName() then API.DeleteGroup(entry.id) end end)
        y = y - 28
    end
    for i = #entries + 1, #ui.groupButtons do ui.groupButtons[i]:Hide() end
    ui.groups.content:SetHeight(math.max(1, -y + 4))
end

local function ConversationTitle(key)
    local gid = key and key:match("^g:(.+)$")
    if gid then return (store.groups[gid] and store.groups[gid].name) or "Grupo" end
    local name = key and key:match("^p:(.+)$")
    return (name and store.contacts[name] and store.contacts[name].alias) or ShortName(name)
end

local function RefreshChat()
    local ui, messages = EnsureFrame(), selectedKey and Conversation(selectedKey) or {}
    -- Reconciliacion relog-segura del estado "entregado": si el ACK del courier llego tras un
    -- /reload (perdiendo el callback runtime), el outbox persistente ya no lo tiene pendiente.
    if HarfordCourier and HarfordCourier.IsPending then
        for _, m in ipairs(messages) do
            if m.sent and not m.delivered and m.courierId and not HarfordCourier.IsPending(m.courierId) then
                m.delivered = true
            end
        end
    end
    local gid = selectedKey and selectedKey:match("^g:(.+)$")
    ui.chat.members:SetShown(gid ~= nil)
    ui.chat.members:SetScript("OnClick", function()
        local group = gid and store.groups[gid]; if not group then return end
        if group.owner == FullPlayerName() then
            StaticPopup_Show("HARFORD_COMM_ADD_MEMBER", nil, nil, gid)
        else
            local members = GroupMembers(group)
            Print("Grupo " .. group.name .. ": " .. table.concat(members, ", "))
        end
    end)
    ui.chat.members:SetScript("OnEnter", function(self)
        local group = gid and store.groups[gid]
        if not group then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(group.name, 1, .82, 0)
        if group.owner == FullPlayerName() then
            GameTooltip:AddLine("Anadir un contacto al grupo.", 1, 1, 1, true)
        else
            GameTooltip:AddLine(table.concat(GroupMembers(group), ", "), .8, .8, .8, true)
        end
        GameTooltip:Show()
    end)
    ui.chat.members:SetScript("OnLeave", GameTooltip_Hide)
    local y = 0
    for i, message in ipairs(messages) do
        local line = ui.chat.lines[i]
        if not line then line = ui.chat.content:CreateFontString(nil, "OVERLAY", "GameFontNormal"); line:SetWidth(258); line:SetWordWrap(true); ui.chat.lines[i] = line end
        line:ClearAllPoints(); line:SetPoint("TOPLEFT", 5, -y); line:SetJustifyH(message.sent and "RIGHT" or "LEFT")
        local who = message.sent and "Tu" or (message.sender or ConversationTitle(selectedKey) or "Contacto")
        local color = message.sent and "|cff6F9ED6" or "|cffE39A4C"
        local state = message.sent and not message.delivered and " |cffaaaaaa(...)|r" or ""
        line._harfordPlainText = message.text or ""
        local emojiOnly = line._harfordPlainText:match("^%s*(.-)%s*$")
        -- Un icono enviado solo funciona como mensaje visual, no como glifo
        -- dentro de una frase: le damos espacio y escala propios.
        local emojiSize = EMOJIS[emojiOnly] and 48 or 18
        line:SetText(color .. who .. ":|r " .. RenderEmojis(line._harfordPlainText, emojiSize) .. state); line:Show(); y = y + math.max(emojiSize + 4, line:GetStringHeight() or 15) + 10; if not message.sent then message.read = true end
    end
    for i = #messages + 1, #ui.chat.lines do ui.chat.lines[i]:Hide() end
    ui.chat.content:SetHeight(math.max(ui.chat.scroll:GetHeight(), y + 4)); ui.chat.scroll:UpdateScrollChildRect(); ui.chat.scroll:SetVerticalScroll(ui.chat.scroll:GetVerticalScrollRange())
    RefreshUnreadIndicator()
end

local function LeaveContracts(ui)
    if not ui.contractsOpen then return end
    ui.contractsOpen = nil
    if HarfordContracts and HarfordContracts.UI and HarfordContracts.UI.CloseEmbedded then
        HarfordContracts.UI.CloseEmbedded()
    end
    ui:SetSize(300, 400)
    ui.appBar:SetHeight(ui:GetHeight())
    ui.titleBar:Show(); ui.title:Show(); ui.close:Show(); ui.ping:Show(); ui.wisps:Show()
    ApplyVisuals()
end

local function HideCommunicatorViews(ui)
    ui.contacts:Hide(); ui.groups:Hide(); ui.chat:Hide(); ui.options:Hide(); ui.radio:Hide()
end

ShowContacts = function()
    local ui = EnsureFrame(); LeaveContracts(ui); HideCommunicatorViews(ui)
    ui.contacts:Show(); ui.title:SetText("Comunicador"); ui.appBar.Select(ui.appBar.contacts); RefreshContacts()
end
ShowGroups = function()
    local ui = EnsureFrame(); LeaveContracts(ui); HideCommunicatorViews(ui)
    ui.groups:Show(); ui.title:SetText("Grupos"); ui.appBar.Select(ui.appBar.contacts); RefreshGroups()
end
ShowChat = function()
    if not selectedKey then return ShowContacts() end
    local ui = EnsureFrame(); LeaveContracts(ui); HideCommunicatorViews(ui)
    ui.chat:Show(); ui.title:SetText("Comunicador"); ui.appBar.Select(ui.appBar.contacts); RefreshChat()
end
ShowOptions = function()
    local ui = EnsureFrame(); LeaveContracts(ui); HideCommunicatorViews(ui)
    ui.options:Show(); ui.title:SetText("Comunicador"); ui.appBar.Select(ui.appBar.contacts)
    ui.options.handle:SetText(store.options.handle or ShortName(FullPlayerName())); ui.options.silent:SetChecked(store.options.silent and true or false)
end
ShowContracts = function()
    local ui = EnsureFrame()
    if ui.contractsOpen then return end
    if not (HarfordContracts and HarfordContracts.UI and HarfordContracts.UI.OpenEmbedded) then
        Print("El tablon de contratos aun no esta disponible.")
        return
    end
    HideCommunicatorViews(ui)
    ui:SetSize(860, 560)
    ui.appBar:SetHeight(ui:GetHeight())
    ui.contractsOpen = true
    ui.titleBar:Hide(); ui.title:Hide(); ui.close:Hide(); ui.ping:Hide(); ui.wisps:Hide(); ui.globalUnread:Hide()
    ApplyVisuals()
    ui.appBar.Select(ui.appBar.contracts)
    HarfordContracts.UI.OpenEmbedded(ui, function()
        -- La X del tablon cierra esta ventana completa. Cambiar de aplicacion
        -- solo ocurre al pulsar uno de los iconos de la barra lateral.
        ui.contractsOpen = nil
        ui:SetSize(300, 400)
        ui.appBar:SetHeight(ui:GetHeight())
        ui.titleBar:Show(); ui.title:Show(); ui.close:Show(); ui.ping:Show(); ui.wisps:Show()
        ApplyVisuals()
        if ui:IsShown() then ui:Hide() end
    end)
end
ShowRadio = function()
    local ui = EnsureFrame(); LeaveContracts(ui); HideCommunicatorViews(ui)
    ui.radio:Show(); ui.title:SetText("Radio"); ui.appBar.Select(ui.appBar.radio)
end

function API.Refresh()
    EnsureStore(); local ui = EnsureFrame()
    if ui.contacts:IsShown() then RefreshContacts() elseif ui.groups:IsShown() then RefreshGroups() elseif ui.chat:IsShown() then RefreshChat() end
end

function API.Open()
    EnsureStore()
    local ui = EnsureFrame()
    ui._harfordSuppressAura = false
    ui:Show(); SetCommunicatorAura(true); ShowContacts()
end

function API.OpenRadio()
    EnsureStore()
    local ui = EnsureFrame()
    ui._harfordSuppressAura = true
    ui:Show(); ShowContacts()
end

function API.OpenContracts()
    EnsureStore()
    EnsureFrame():Show()
    ShowContracts()
end

function API.Toggle() local ui = EnsureFrame(); if ui:IsShown() then ui:Hide() else API.Open() end end

function API.Initialize()
    EnsureStore(); if HarfordSync and HarfordSync.RegisterPrefix then HarfordSync.RegisterPrefix(PREFIX) end
    local events = CreateFrame("Frame"); events:RegisterEvent("CHAT_MSG_ADDON")
    events:SetScript("OnEvent", function(_, _, prefix, payload, _, sender) API.HandleAddonMessage(prefix, payload, sender) end)

    -- Transporte fiable (HarfordCourier): DMs, mensajes de grupo y definiciones de grupo. Entrega
    -- eventual a quien reconecte. El WHISPER heredado (HandleAddonMessage) sigue activo como fallback
    -- e interop. La deduplicacion y el ACK los gestiona el courier; aqui solo se archiva/renderiza.
    if HarfordCourier and HarfordCourier.RegisterHandler then
        HarfordCourier.RegisterHandler("CDM", function(payload, from)
            local id, handle, text = strsplit("|", payload or "", 3)
            id, handle, text = Unescape(id or ""), Unescape(handle or ""), Unescape(text or "")
            if id == "" then return end
            local contact = AddContact(from)
            AddIncomingMessage(ContactKey(contact), from, id, text, false, handle)
            RefreshUI()
        end)
        HarfordCourier.RegisterHandler("CGRP", function(payload, from)
            local gid, id, handle, text = strsplit("|", payload or "", 4)
            gid, id, handle, text = Unescape(gid or ""), Unescape(id or ""), Unescape(handle or ""), Unescape(text or "")
            if gid == "" or id == "" then return end
            local group = store.groups[gid]
            if not group then
                -- Mensaje de grupo llegado antes que su definicion: se encola (igual que el heredado).
                local queue = pendingGroups[gid] or {}
                if #queue < MAX_HISTORY then
                    queue[#queue + 1] = { sender = from, id = id, text = text, handle = handle, createdAt = Now() }
                    pendingGroups[gid] = queue
                end
                return
            end
            if not IsGroupMember(group, from) then return end
            AddIncomingMessage(GroupKey(gid), from, id, text, true, handle)
            RefreshUI()
        end)
        HarfordCourier.RegisterHandler("CDEF", function(payload, from)
            -- Mismos campos que el mensaje "D" heredado: id|owner|name|memberBlob (ReceiveDefinition
            -- desescapa por su cuenta).
            local id, owner, name, members = strsplit("|", payload or "", 4)
            ReceiveDefinition(from, id, owner, name, members)
        end)
    end
end

local bootstrap = CreateFrame("Frame"); bootstrap:RegisterEvent("PLAYER_LOGIN")
bootstrap:SetScript("OnEvent", function()
    API.Initialize()
    if HarfordToolTray and HarfordToolTray.Register then
        HarfordToolTray.Register({
            key = "comunicador", label = "Comunicador", icon = "Interface\\Icons\\INV_Gizmo_01",
            tooltip = "Mensajes, radio, contratos y diversos servicios.",
            disabledTooltip = "Requiere el Comunicador Harford en el inventario.",
            isEnabled = HasCommunicatorItem,
            onClick = API.Toggle,
        })
    end
end)

local availability = CreateFrame("Frame")
availability:RegisterEvent("BAG_UPDATE_DELAYED")
availability:RegisterEvent("PLAYER_ENTERING_WORLD")
availability:SetScript("OnEvent", function()
    if HarfordToolTray and HarfordToolTray.RefreshAvailability then
        HarfordToolTray.RefreshAvailability()
    end
end)
