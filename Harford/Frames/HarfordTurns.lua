-- Tracker visual de turnos de combate de Harford.
-- El orden se fija al INICIAR COMBATE (tirada de iniciativa, mayor primero) y despues puede
-- retocarse a mano con los botones de reordenar.

HarfordTurnOrderStore = HarfordTurnOrderStore or {}

local COMM_PREFIX = "HARFORDTURN"
local TURN_SINGLE_MESSAGE_LIMIT = 230
local TURN_CHUNK_ENCODED_LIMIT = 170
local TURN_MAX_CHUNKS = 80
local TURN_SERIAL_MAX = 999999
local MAX_CARDS = 6
local CARD_W = 70
local CARD_GAP = 6
local CARD_H = 122
local TEX_MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
local TEX_WHITE = "Interface\\Buttons\\WHITE8x8"
local TEX_STATUS = "Interface\\TargetingFrame\\UI-StatusBar"
local ROUND_MARKER_ID = "HARFORD_ROUND_MARKER"

local TurnFrame
local StatusText
local RefreshFrame
local MarkChanged
-- Cuando y quien avanzo el turno por ULTIMA vez desde otro cliente. Se rellena al recibir el
-- aviso; el que lo emite no recibe el suyo.
local ultimoAvanceAjeno = { quien = nil, cuando = 0 }
local avanceConfirmado = 0        -- sello del aviso ya visto, para dejar pasar el segundo clic
local VENTANA_DOBLE_AVANCE = 4
local SendStateTo   -- se asigna abajo; el manejador de mensajes la usa antes
local suppressBroadcast = false
local broadcastPending = false
local viewStart = 1
local editMode = false
local reorderSelectedIndex
local lastTurnAlertKey = ""
local lastTurnNoticeKey = ""
local lastRoundAlertKey = ""
-- El marcador de asalto encabeza siempre la lista: ninguna tirada de iniciativa puede alcanzarlo.
-- No es 20 ni 30 porque "Preparado" (Cazador de Demonios) actua en el conteo 30.
local ROUND_MARKER_INITIATIVE = 9999
-- Una transferencia troceada que nunca se completa no puede quedarse en memoria.
local CHUNK_TTL_SECONDS = 15

-- Escapado, troceado y (de)serializacion viven en HarfordTurnsCodec: no dependen de la UI ni del
-- store, asi que se pueden probar sueltos. Un solo local en vez de los doce que habia.
local Codec = HarfordTurnsCodec
-- Iniciativa, orden e inicio/fin de combate viven en HarfordTurnsCombat.
local Combate = HarfordTurnsCombat
-- La ficha emergente de una entrada es una ventana aparte.
local Ficha = HarfordTurnsSheet
local turnChunkBuffers = {}
local turnSerial = 0
local NormalizeIconPath

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

local function GetPlayerTurnNameColorHex(profile, unit)
    local manual = profile and HarfordTRP3 and HarfordTRP3.GetProfileNameColor and HarfordTRP3.GetProfileNameColor(profile)
    manual = NormalizeColorHex(manual)
    if manual then return manual end
    -- Alias/resolucion de clase viven en HarfordClassColors.
    return HarfordClassColors.ProfileColorHex(profile) or HarfordClassColors.UnitColorHex(unit)
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
    if entry.kind == "players" then return 0.2, 1.0, 0.4 end
    if entry.kind == "player" then
        local r, g, b = HexToRGB(entry.nameColor)
        return r or 0.1, g or 1.0, b or 0.1
    end

    local r, g, b = GetReactionColor(entry.reaction)
    return r or 1.0, g or 0.1, b or 0.1
end

local function Print(msg)
    HarfordChat.Print(msg)
end

-- Devuelve el calificativo de reaccion ("aliado"/"neutral"/"enemigo") y el markup de color.
local function GetNPCReactionLabel(entry)
    local reaction = tonumber(entry and entry.reaction) or 0
    if reaction >= 5 then
        return "aliado",   "|cff33ff33"   -- verde
    elseif reaction == 4 then
        return "neutral",  "|cffffff00"   -- amarillo
    else
        return "enemigo",  "|cffff3333"   -- rojo (hostil, desconocido o 0)
    end
end

local function GetEntryNameForChat(entry)
    local name = tostring(entry and entry.name or "?")
    if entry and entry.kind == "round" then
        return "|cffffff00" .. name .. "|r"
    end
    if entry and (entry.kind == "player" or entry.kind == "players") then
        return "|cff00ff00" .. name .. "|r"
    end
    local _, colorMarkup = GetNPCReactionLabel(entry)
    return colorMarkup .. name .. "|r"
end

local function PrintTurn(entry)
    if not entry then return end
    if entry.kind == "round" then
        Print("|cffffff00" .. tostring(entry.name or "Inicio de turno") .. "|r")
        return
    end
    if entry.kind == "players" then
        Print("Turno de los " .. GetEntryNameForChat(entry) .. ": actuad en el orden que querais.")
        return
    end
    if entry.kind == "player" then
        Print("Turno de " .. GetEntryNameForChat(entry))
    else
        local qualifier, _ = GetNPCReactionLabel(entry)
        Print("Turno " .. qualifier .. ": " .. GetEntryNameForChat(entry))
    end
end

-- Los UNICOS tipos de entrada validos. Cualquier otra cosa se normaliza a "npc": antes el tipo
-- podia acabar siendo el token de unidad ("target", "focus", "mouseover"...) porque `AddUnit`
-- hacia `kind or unit`, y HarfordAdmin llama sin kind.
local ENTRY_KINDS = { round = true, generic = true, players = true, player = true, npc = true }

local function NormalizeKind(kind)
    kind = tostring(kind or "")
    return ENTRY_KINDS[kind] and kind or "npc"
end

-- Entradas que no son una criatura: el marcador de asalto, los marcadores de fase y el turno
-- compartido de los PJs. No tienen vida, CA ni ficha, y no se les puede ajustar nada.
local function IsSystemEntry(entry)
    if not entry then return false end
    return entry.kind == "round" or entry.kind == "generic" or entry.kind == "players"
end

-- El turno "PJs" es de TODOS los jugadores a la vez, asi que pertenece a cualquiera que lo mire:
-- cada cliente recibe su aviso de turno y renueva su propia economia de accion.
local function EntryBelongsToMe(entry)
    if entry and entry.kind == "players" then return true end
    -- El turno del bando de los PJs es el turno de todos los jugadores, incluido yo.
    if entry and entry.kind == "bando" and entry.bando == "pjs" then return true end
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

-- Los mensajes de turnos REESCRIBEN el estado compartido del tracker (entradas, turno activo,
-- vida de los NPC). El emisor difunde por RAID/PARTY, pero `CHAT_MSG_ADDON` entrega tambien
-- WHISPER de cualquiera, asi que se aplica el mismo filtro que el resto de opcodes con efecto:
-- solo se aceptan de un remitente que el cliente reconozca (unidad visible o grupo/raid).
local function IsTrustedTurnSender(sender)
    sender = tostring(sender or "")
    if sender == "" then return false end
    if IsSenderSelf(sender) then return true end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(sender) ~= nil
    end
    return false
end

local function AlertMyTurn(entry, activeIndex, turnSerial)
    if not EntryBelongsToMe(entry) then return end

    local serial = tonumber(turnSerial) or 0
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

    -- Avisa a los listeners registrados (p. ej. el Libro apaga las reacciones preparadas).
    if HarfordTurnOrderAPI and HarfordTurnOrderAPI._myTurnListeners then
        for _, fn in ipairs(HarfordTurnOrderAPI._myTurnListeners) do
            pcall(fn, entry)
        end
    end
end

local function AlertRoundStates(entry, activeIndex, turnSerial)
    if not entry or entry.kind ~= "round" then return end

    local serial = tonumber(turnSerial) or 0
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
    Print("|cffffff00" .. text .. "|r")
end

local function AlertTurnChanged(entry, activeIndex, turnSerial)
    if HarfordTurnOrderAPI and HarfordTurnOrderAPI._turnChangedListeners then
        for _, fn in ipairs(HarfordTurnOrderAPI._turnChangedListeners) do
            pcall(fn, entry, turnSerial, activeIndex)
        end
    end
end

local function EnsureStore()
    if type(HarfordTurnOrderStore) ~= "table" then HarfordTurnOrderStore = {} end
    if type(HarfordTurnOrderStore.entries) ~= "table" then HarfordTurnOrderStore.entries = {} end
    HarfordTurnOrderStore.activeIndex = tonumber(HarfordTurnOrderStore.activeIndex) or 1
    HarfordTurnOrderStore.adminName = nil
    HarfordTurnOrderStore.turnSerial = nil
    if HarfordTurnOrderStore.activeIndex < 1 then HarfordTurnOrderStore.activeIndex = 1 end
    return HarfordTurnOrderStore
end

-- Un combate abandonado no deberia seguir ahi la semana que viene: sus NPC tienen GUIDs que ya no
-- resuelven y la economia de turno lo tomaria por combate en curso. Cuatro horas es de sobra para
-- cubrir un relogeo o una desconexion en mitad de la escena, y corto para no arrastrar sesiones.
-- Sella cuando se toco la lista por ultima vez. Lo lee `PurgeStaleEntries` al entrar para saber
-- si lo guardado es un combate vivo o el resto de una sesion antigua.
local function TouchStore()
    local store = EnsureStore()
    store.lastTouched = (time and time()) or 0
end

local STALE_SECONDS = 4 * 60 * 60

local function PurgeStaleEntries()
    local store = EnsureStore()
    if #store.entries == 0 then return false end
    local ahora = (time and time()) or 0
    local ultimo = tonumber(store.lastTouched) or 0
    -- Sin sello (lista escrita por una version anterior) se considera vieja: es lo que hay guardado
    -- de antes de existir la caducidad, y precisamente eso es lo que sobra.
    if ultimo > 0 and ahora > 0 and (ahora - ultimo) < STALE_SECONDS then return false end
    store.entries = {}
    store.activeIndex = 1
    store.lastTouched = nil
    -- Sin combatientes no hay bandos: dejar el bloque activo apuntando a una lista vacia haria que
    -- el siguiente avance arrancara a media rotacion.
    store.activeBando = nil
    store.faseBando = nil
    return true
end

-- ¿Acaba de avanzar otro DM? Devuelve true si hay que PARARSE y avisar. El segundo clic dentro de
-- los 10 s siguientes pasa: quien insiste sabe lo que hace.
local function OtroDMAcabaDeAvanzar()
    local ahora = (time and time()) or 0
    if ahora - (ultimoAvanceAjeno.cuando or 0) >= VENTANA_DOBLE_AVANCE then return false end
    if ahora - avanceConfirmado < 10 then return false end
    avanceConfirmado = ahora
    Print("|cffffcc00" .. tostring(ultimoAvanceAjeno.quien or "Otro DM")
        .. " acaba de avanzar el turno.|r Pulsa otra vez si quieres avanzarlo igualmente.")
    return true
end

local function AdvanceTurnSerial()
    EnsureStore()
    turnSerial = ((tonumber(turnSerial) or 0) % TURN_SERIAL_MAX) + 1
    return turnSerial
end

-- Permiso de edicion del tracker: la senal de autoridad esta centralizada en
-- HarfordAuthority. CanUseDMTools() == HarfordAdmin cargado Y .ph dm activo
-- (los mismos dos ejes que combinaba el codigo anterior).
local function IsTurnAdmin()
    return HarfordAuthority
        and HarfordAuthority.CanUseDMTools
        and HarfordAuthority.CanUseDMTools() == true
end

local function ClaimAdminIfNeeded()
    EnsureStore()
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
    if not editMode then
        reorderSelectedIndex = nil
    end
    UpdateEditButton()
    if RefreshFrame then RefreshFrame() end
end

local function MoveEntryToIndex(fromIndex, toIndex)
    if not IsTurnAdmin() then Print("Solo el admin puede editar los turnos.") return end
    ClaimAdminIfNeeded()

    local store = EnsureStore()
    fromIndex = tonumber(fromIndex)
    toIndex = tonumber(toIndex)
    if not fromIndex or not toIndex then return end
    if fromIndex < 1 or fromIndex > #store.entries or toIndex < 1 or toIndex > #store.entries then return end
    if fromIndex == toIndex then return end

    local activeEntry = store.entries[store.activeIndex]
    local selectedEntry = reorderSelectedIndex and store.entries[reorderSelectedIndex] or nil
    local entry = table.remove(store.entries, fromIndex)
    table.insert(store.entries, toIndex, entry)
    store.activeIndex = 1
    reorderSelectedIndex = nil
    for i, candidate in ipairs(store.entries) do
        if candidate == activeEntry then
            store.activeIndex = i
        end
        if selectedEntry and candidate == selectedEntry then
            reorderSelectedIndex = i
        end
    end

    EnsureActiveVisible()
    MarkChanged()
end

local function MoveEntry(index, delta)
    index = tonumber(index)
    if not index then return end
    MoveEntryToIndex(index, index + (tonumber(delta) or 0))
end

local function ClickEditEntry(index)
    if not IsTurnAdmin() then Print("Solo el admin puede editar los turnos.") return end
    local store = EnsureStore()
    index = tonumber(index)
    if not index or not store.entries[index] then return end

    if reorderSelectedIndex and reorderSelectedIndex ~= index and store.entries[reorderSelectedIndex] then
        MoveEntryToIndex(reorderSelectedIndex, index)
    elseif reorderSelectedIndex == index then
        reorderSelectedIndex = nil
        if RefreshFrame then RefreshFrame() end
    else
        reorderSelectedIndex = index
        Print("Turno seleccionado para mover. Haz click en otra posicion.")
        if RefreshFrame then RefreshFrame() end
    end
end

local function FindDuplicateEntry(candidate)
    if type(candidate) ~= "table" then return nil end

    Codec.NormalizeEntryLinks(candidate)

    local candidateId = tostring(candidate.id or "")
    local candidateUnitName = tostring(candidate.unitName or "")
    local candidateName = tostring(candidate.name or "")
    local candidateTrpUnitID = Codec.NormalizePlayerUnitID(candidate.trpUnitID or "")
    local candidateShort = Ambiguate and Ambiguate(candidateUnitName ~= "" and candidateUnitName or candidateName, "short")

    local store = EnsureStore()
    for i, entry in ipairs(store.entries or {}) do
        if entry and entry.kind ~= "round" then
            Codec.NormalizeEntryLinks(entry)

            if candidateId ~= "" and tostring(entry.id or "") == candidateId then
                return entry, i
            end

            if candidate.kind == "player" and entry.kind == "player" then
                local entryTrpUnitID = Codec.NormalizePlayerUnitID(entry.trpUnitID or "")
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
            entry.name = "Inicio de turno"
            entry.initiative = ROUND_MARKER_INITIATIVE
            entry.hp = 0
            entry.maxHp = 0
            entry.mana = 0
            entry.maxMana = 0
            return entry
        end
    end

    local marker = {
        id = ROUND_MARKER_ID,
        name = "Inicio de turno",
        kind = "round",
        initiative = ROUND_MARKER_INITIATIVE,
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
-- El codec necesita saber normalizar tipos y leer numeros con el mismo criterio que el tracker,
-- y los limites de troceado son de la capa de red, que vive aqui.
if Codec and Codec.Init then
    Codec.Init({
        SafeNumber = SafeNumber,
        NormalizeKind = NormalizeKind,
        -- Envuelta a proposito: `NormalizeIconPath` se asigna mas abajo que este Init, asi que
        -- pasarla directamente inyectaria nil. El cierre la resuelve al llamarla.
        NormalizeIconPath = function(icon) return NormalizeIconPath(icon) end,
        NormalizeColorHex = function(hex) return NormalizeColorHex(hex) end,
        chunkEncodedLimit = TURN_CHUNK_ENCODED_LIMIT,
        maxChunks = TURN_MAX_CHUNKS,
        chunkTTL = CHUNK_TTL_SECONDS,
    })
end

local function SerializeState()
    local store = EnsureStore()
    local parts = {}
    for i = 1, #store.entries do
        Codec.NormalizeEntryLinks(store.entries[i])
        parts[#parts + 1] = Codec.SerializeEntry(store.entries[i])
    end
    return "STATE|" .. tostring(store.activeIndex or 1) .. "||" .. table.concat(parts, ";")
end

local function SerializeTurnNotice()
    local store = EnsureStore()

    -- En modo bandos el aviso NO va de una criatura. Se manda el bando y, con el, LA LISTA de
    -- quien lo compone: la pertenencia la fija el DM y viaja con el anuncio, en vez de que cada
    -- cliente la deduzca de su copia. Sin esto habia carrera -- el aviso sale ya y la foto va
    -- retrasada 0,15 s -- y un reparto recien corregido llegaba tarde.
    if store.modoBandos then
        local bando = HarfordTurnOrderAPI.BANDOS[tonumber(store.activeBando) or 0]
        if not bando then return nil end
        local ids = {}
        for _, e in ipairs(HarfordTurnOrderAPI.GetBandoMembers(bando)) do
            if e.id and e.id ~= "" then ids[#ids + 1] = tostring(e.id) end
        end
        return table.concat({ "TURNB", tostring(turnSerial or 0), bando,
            table.concat(ids, ","), tostring(store.faseBando or "inicio"),
            tostring(store.asalto or 0) }, "|")
    end

    local index = tonumber(store.activeIndex) or 1
    local entry = store.entries[index]
    if not entry then return nil end

    return table.concat({
        "TURN",
        tostring(turnSerial or 0),
        tostring(index),
        tostring(#store.entries),
        "",
        Codec.SerializeTurnNoticeEntry(entry),
    }, "|")
end

local function PrintTurnNotice(entry, activeIndex, count, turnSerial)
    if not entry then return end

    local noticeKey = tostring(turnSerial or 0) .. ":" .. tostring(activeIndex or 0) .. ":" .. tostring(entry.id or "") .. ":" .. tostring(entry.name or "")
    if noticeKey == lastTurnNoticeKey then return end
    lastTurnNoticeKey = noticeKey

    if entry.kind == "round" then
        Print("|cffffff00" .. tostring(entry.name or "Inicio de turno") .. "|r")
        return
    end
    if count and count > 0 then
        -- Calcular indice y total excluyendo marcadores de ronda (cuentan como posicion 0)
        local store = EnsureStore()
        local displayCount = 0
        local displayIndex = 0
        for i, e in ipairs(store.entries or {}) do
            if e and e.kind ~= "round" then
                displayCount = displayCount + 1
                if i <= (activeIndex or 0) then
                    displayIndex = displayIndex + 1
                end
            end
        end
        if displayCount > 0 then
            Print("Turno " .. tostring(displayIndex) .. "/" .. tostring(displayCount) .. ": " .. GetEntryNameForChat(entry))
        else
            PrintTurn(entry)
        end
    else
        PrintTurn(entry)
    end
end

-- Reconstruye la entrada sintetica de un turno de bando a partir del anuncio. La lista de
-- miembros llega por id; se resuelve contra las entradas locales para sacar guid y nombre, que es
-- con lo que casan los estados. Un id que no exista aqui (foto vieja) simplemente no aporta: se
-- pierde ese miembro, no se rompe el turno.
local function EntradaDeBandoRecibida(bando, idsRaw, fase)
    local store = EnsureStore()
    local porId = {}
    for _, e in ipairs(store.entries) do
        if e.id and e.id ~= "" then porId[tostring(e.id)] = e end
    end
    local guids, nombres, cuantos = {}, {}, 0
    for id in tostring(idsRaw or ""):gmatch("[^,]+") do
        local e = porId[id]
        if e then
            if e.guid and e.guid ~= "" then guids[tostring(e.guid)] = true end
            if e.name and e.name ~= "" then nombres[tostring(e.name)] = true end
            cuantos = cuantos + 1
        end
    end
    return {
        kind = "bando",
        bando = bando,
        fase = fase or "inicio",
        id = "bando:" .. tostring(bando) .. ":" .. tostring(fase or "inicio"),
        name = HarfordTurnOrderAPI.BANDO_ETIQUETA[bando] or tostring(bando),
        -- La lista que mando el DM manda sobre lo que opine este cliente.
        miembros = (cuantos > 0) and { guids = guids, nombres = nombres } or nil,
    }
end

local function ApplyTurnNotice(message)
    local opcode, serialRaw, activeRaw, countRaw, adminRaw, entryRaw = strsplit("|", message or "")

    if (opcode == "TURN" or opcode == "TURNB") and sender and sender ~= "" then
        ultimoAvanceAjeno.quien = Ambiguate and Ambiguate(sender, "short") or sender
        ultimoAvanceAjeno.cuando = (time and time()) or 0
    end

    if opcode == "TURNB" then
        local bando, idsRaw, fase, asaltoRaw = activeRaw, countRaw, adminRaw, entryRaw
        fase = (fase == "fin") and "fin" or "inicio"
        local valido = false
        for _, b in ipairs(HarfordTurnOrderAPI.BANDOS) do if b == bando then valido = true end end
        if not valido then return false end
        local serial = SafeNumber(serialRaw, 0)
        local store = EnsureStore()
        turnSerial = serial
        for i, b in ipairs(HarfordTurnOrderAPI.BANDOS) do
            if b == bando then store.activeBando = i end
        end
        store.modoBandos = true
        store.faseBando = fase
        store.asalto = SafeNumber(asaltoRaw, 0)
        local entrada = EntradaDeBandoRecibida(bando, idsRaw, fase)
        entrada.asalto = store.asalto
        TouchStore()
        if RefreshFrame then RefreshFrame() end
        Print("|cffffff00" .. (HarfordTurnOrderAPI.FASE_ETIQUETA[fase] or "turno de")
            .. " " .. tostring(entrada.name) .. "|r")
        AlertTurnChanged(entrada, store.activeBando, serial)
        if fase == "inicio" then AlertMyTurn(entrada, store.activeBando, serial) end
        return true
    end

    if opcode ~= "TURN" then return false end

    local serial = SafeNumber(serialRaw, 0)
    local activeIndex = SafeNumber(activeRaw, 1)
    local count = SafeNumber(countRaw, 0)
    local noticeEntry = Codec.DeserializeTurnNoticeEntry(entryRaw)
    if not noticeEntry then return false end

    local store = EnsureStore()
    turnSerial = serial

    local entry = noticeEntry
    if activeIndex >= 1 and activeIndex <= #store.entries then
        store.activeIndex = activeIndex
        entry = store.entries[activeIndex] or noticeEntry
        if entry and noticeEntry.id and noticeEntry.id ~= "" and tostring(entry.id or "") ~= tostring(noticeEntry.id) then
            entry = noticeEntry
        end
        EnsureActiveVisible()
    end

    TouchStore()
    PrintTurnNotice(entry, activeIndex, count, serial)
    AlertRoundStates(entry, activeIndex, serial)
    AlertTurnChanged(entry, activeIndex, serial)
    AlertMyTurn(entry, activeIndex, serial)
    return true
end

local function ApplySerializedState(message)
    local opcode, activeRaw, third, fourth = strsplit("|", message or "")
    if opcode ~= "STATE" then return false end

    local store = EnsureStore()
    store.entries = {}
    store.activeIndex = SafeNumber(activeRaw, 1)
    local entriesRaw = fourth or third
    if entriesRaw and entriesRaw ~= "" then
        for token in string.gmatch(entriesRaw, "[^;]+") do
            local entry = Codec.DeserializeEntry(token)
            if entry then store.entries[#store.entries + 1] = entry end
        end
    end

    ClampActiveIndex()
    EnsureRoundMarker()
    ClampActiveIndex()
    EnsureActiveVisible()
    return true
end

local function SendSerializedState(payload, channel, target)
    if #payload <= TURN_SINGLE_MESSAGE_LIMIT then
        return HarfordSync.Send(COMM_PREFIX, payload, channel, target)
    end

    local chunks = Codec.SplitEscapedChunks(payload)
    if #chunks > TURN_MAX_CHUNKS then
        Print("No se pudo compartir turnos: estado demasiado grande.")
        return false
    end

    local transferId = NewId()
    for i = 1, #chunks do
        local ok, err = HarfordSync.Send(COMM_PREFIX, "SCHUNK|" .. transferId .. "|" .. tostring(i) .. "|" .. tostring(#chunks) .. "|" .. chunks[i], channel, target)
        if not ok then return false, err end
    end
    return true
end

-- Reensamblado de un mensaje troceado. Las dos variantes (estado completo `SCHUNK` y aviso de
-- turno `TCHUNK`) eran 39 lineas identicas salvo el prefijo de la clave y la funcion final, asi
-- que comparten cuerpo. El prefijo debe seguir siendo DISTINTO: un mismo remitente puede tener a
-- la vez una transferencia de estado y una de turno con el mismo id.

local function ApplyChunkedState(message, sender)
    return Codec.ApplyChunked(message, sender, "SCHUNK", "", ApplySerializedState)
end

local function ApplyChunkedTurnNotice(message, sender)
    return Codec.ApplyChunked(message, sender, "TCHUNK", "T:", ApplyTurnNotice)
end

-- ─── INICIO Y FIN DE COMBATE ─────────────────────────────────────────────────

-- Bonus de iniciativa que este cliente puede calcular para una entrada.
-- Para MI personaje sale de la ficha, con todos sus rasgos. Para un NPC, del Mod. de Destreza de su
-- stat block TRP3 si se puede localizar la unidad. Para OTRO jugador no se intenta adivinar: su
-- cliente lo hara mejor y responde a INITREQ.

-- Mayor iniciativa primero. `table.sort` no es estable en Lua, asi que el indice actual entra como
-- desempate: dos tiradas iguales conservan el orden que ya tenian en vez de bailar en cada
-- reordenacion.

-- Un jugador responde con SU tirada. Solo el admin la aplica, y solo sobre la entrada que de
-- verdad le pertenece a ese remitente: nadie puede fijar la iniciativa de otro.

-- El DM pide a cada jugador que tire la suya. Se responde por susurro al DM.

local function ApplyTurnMessage(message, sender)
    local opcode = tostring(message or ""):match("^([^|]+)")
    if opcode == "STATE" then
        return ApplySerializedState(message)
    elseif opcode == "SCHUNK" then
        return ApplyChunkedState(message, sender)
    elseif opcode == "TURN" then
        return ApplyTurnNotice(message)
    elseif opcode == "TCHUNK" then
        return ApplyChunkedTurnNotice(message, sender)
    elseif opcode == "TREQ" then
        -- Solo el DM tiene la foto buena. Si hay varios, contestan todos: la foto es la misma y
        -- aplicarla dos veces no cambia nada, a diferencia de los estados de NPC, donde la lista
        -- SUSTITUYE y por eso alli si hizo falta desempate.
        if IsTurnAdmin() and sender and sender ~= "" then SendStateTo(sender) end
        return true
    elseif opcode == "INITREQ" then
        return Combate.ApplyInitiativeRequest(message, sender)
    elseif opcode == "INITRES" then
        return Combate.ApplyInitiativeReply(message, sender)
    end
    return false
end

local function SendState()
    if not IsTurnAdmin() then return false end
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not ch then return false end
    return SendSerializedState(SerializeState(), ch)
end

-- Contestar a uno solo, por susurro: la foto completa solo le interesa a quien la pidio.
SendStateTo = function(target)
    if not IsTurnAdmin() then return false end
    if not (target and target ~= "") then return false end
    return SendSerializedState(SerializeState(), "WHISPER", target)
end

-- Preguntar. Va al canal del GRUPO porque quien entra no sabe quien es el DM; contestan los que lo
-- sean. Con enfriamiento, que `GROUP_ROSTER_UPDATE` se dispara en rafagas.
local ULTIMA_PETICION_TURNOS = 0
local function RequestTurnState()
    local ahora = (time and time()) or 0
    if ahora - ULTIMA_PETICION_TURNOS < 12 then return false end
    ULTIMA_PETICION_TURNOS = ahora
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not ch then return false end
    return HarfordSync.Send(COMM_PREFIX, "TREQ|"
        .. tostring((GetUnitName and GetUnitName("player", true)) or ""), ch)
end

local function SendTurnNotice()
    if not IsTurnAdmin() then return false end
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not ch then return false end

    local payload = SerializeTurnNotice()
    if not payload then return false end

    if #payload <= TURN_SINGLE_MESSAGE_LIMIT then
        return HarfordSync.Send(COMM_PREFIX, payload, ch)
    end

    -- Nombre largo (TRP3 con espacios/caracteres codificados): enviar en TCHUNK.
    local chunks = Codec.SplitEscapedChunks(payload)
    if #chunks > TURN_MAX_CHUNKS then
        Print("No se pudo anunciar el turno: mensaje demasiado grande.")
        return false
    end

    local transferId = NewId()
    for i = 1, #chunks do
        local ok, err = HarfordSync.Send(COMM_PREFIX, "TCHUNK|" .. transferId .. "|" .. tostring(i) .. "|" .. tostring(#chunks) .. "|" .. chunks[i], ch)
        if not ok then return false, err end
    end
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
    TouchStore()
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

local function MakeButton(parent, text, w, h, point, rel, relPoint, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetPoint(point, rel, relPoint, x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

-- Secciones colapsables -----------------------------------------------------

-- Lee fuente de un objeto FontObject de WoW en tiempo de ejecucion.
-- Asi no hardcodeamos rutas ni tamanos - si TRP3 cambia su fuente, nosotros tambien.

do
    local _, bodySize = Ficha.GetTRP3BodyFont()
    SECTION_HDR_H = math.max(28, math.ceil(bodySize * 2.4))
end

-- (BuildStateRows y STATE_ROW_H eliminados: la seccion de rasgos usa bodyText igual que el resto)

-- Popup de estado (se abre al clicar un link harfordstate:) ----------------
local StatePopup

local function EnsureStatePopup()
    if StatePopup then return end
    StatePopup = CreateFrame("Frame", "HarfordStatePopup", UIParent, "BackdropTemplate")
    StatePopup:SetSize(340, 280)
    StatePopup:SetPoint("CENTER")
    StatePopup:SetFrameStrata("DIALOG")
    StatePopup:SetFrameLevel(600)
    StatePopup:SetMovable(true)
    StatePopup:EnableMouse(true)
    StatePopup:RegisterForDrag("LeftButton")
    StatePopup:SetScript("OnDragStart", StatePopup.StartMoving)
    StatePopup:SetScript("OnDragStop",  StatePopup.StopMovingOrSizing)
    StatePopup:Hide()
    local bg = StatePopup:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT",     StatePopup, "TOPLEFT",     7, -13)
    bg:SetPoint("BOTTOMRIGHT", StatePopup, "BOTTOMRIGHT", -7, 7)
    bg:SetTexture(TEX_WHITE)
    bg:SetVertexColor(0.06, 0.015, 0.012, 0.97)
    local border = CreateFrame("Frame", nil, StatePopup, "DialogBorderTemplate")
    border:SetAllPoints(StatePopup)
    border:SetFrameLevel(StatePopup:GetFrameLevel() + 2)
    local close = CreateFrame("Button", nil, StatePopup, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    StatePopup.titleStr = StatePopup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    StatePopup.titleStr:SetPoint("TOPLEFT", 16, -16)
    StatePopup.titleStr:SetPoint("TOPRIGHT", -36, -16)
    StatePopup.titleStr:SetJustifyH("LEFT")
    local bodyFont, bodySize = Ficha.GetTRP3BodyFont()
    local scroll = CreateFrame("ScrollFrame", nil, StatePopup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     StatePopup, "TOPLEFT",     16, -52)
    scroll:SetPoint("BOTTOMRIGHT", StatePopup, "BOTTOMRIGHT", -28, 16)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(280, 1)
    scroll:SetScrollChild(child)
    StatePopup.bodyText = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    StatePopup.bodyText:SetPoint("TOPLEFT", 0, 0)
    StatePopup.bodyText:SetWidth(280)
    StatePopup.bodyText:SetJustifyH("LEFT")
    StatePopup.bodyText:SetJustifyV("TOP")
    StatePopup.bodyText:SetFont(bodyFont, bodySize, "")
    StatePopup.bodyText:SetTextColor(1, 1, 1)
    StatePopup.bodyText:SetSpacing(1)
    StatePopup._child = child
end

local function ShowStatePopup(state)
    EnsureStatePopup()
    local iconMk = ""
    if state.icon and state.icon ~= "" and HarfordTRP3 and HarfordTRP3.IconMarkup then
        iconMk = HarfordTRP3.IconMarkup(state.icon, 22) .. " "
    end
    StatePopup.titleStr:SetText(iconMk .. (state.title or "Estado"))
    local body = (state.text and state.text ~= "") and state.text or "(sin descripción)"
    if HarfordTRP3 and HarfordTRP3.ConvertTRP3Markup then
        body = HarfordTRP3.ConvertTRP3Markup(body)
    end
    StatePopup.bodyText:SetText(body)
    C_Timer.After(0, function()
        local bh = StatePopup.bodyText:GetStringHeight() or 0
        StatePopup._child:SetHeight(math.max(200, bh + 16))
    end)
    StatePopup:Show()
    StatePopup:Raise()
end

-- Hook SetItemRef para links harfordstate: --------------------------------
do
    local function OnItemRef(link)
        if not link or not link:find("^harfordstate:") then return end
        if not HarfordTRP3 or not HarfordTRP3.GetStateFromLink then return end
        local state, err = HarfordTRP3.GetStateFromLink(link)
        if state then
            ShowStatePopup(state)
        else
            HarfordChat.Print("|cffff4444Estado no disponible: " .. tostring(err) .. "|r")
        end
    end
    hooksecurefunc("SetItemRef", function(link) OnItemRef(link) end)
end
-- Fin secciones colapsables -----------------------------------------------

local function GetPortraitTexture(kind)
    if kind == "player" then return "Interface\\Icons\\Achievement_Character_Human_Male" end
    if kind == "players" then return "Interface\\Icons\\INV_Misc_GroupLooking" end
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
            local resolvedUnitID, resolvedProfileID
            profile, _, resolvedUnitID, resolvedProfileID = HarfordTRP3.GetPlayerProfile(unit)
            if resolvedUnitID and resolvedUnitID ~= "" then unitID = resolvedUnitID end
            if resolvedProfileID and resolvedProfileID ~= "" then out.trpProfileID = resolvedProfileID end
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
            out.nameColor = GetPlayerTurnNameColorHex(profile, unit) or out.nameColor
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
            if not out.trpProfileID and TRP3_API and TRP3_API.register and TRP3_API.register.getUnitIDProfileID then
                local okProfileID, profileID = pcall(TRP3_API.register.getUnitIDProfileID, out.trpUnitID)
                if okProfileID then out.trpProfileID = profileID end
            end
        end
    end

    if UnitIsPlayer and UnitIsPlayer(unit) then
        out.nameColor = out.nameColor or GetPlayerTurnNameColorHex(nil, unit)
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

local function RefreshPlayerEntryTRP3Meta(entry)
    if not entry or entry.kind ~= "player" or not HarfordTRP3 then return end

    -- Solo volver a buscar si no se encontro perfil antes, o si pasaron mas de 30s
    -- (cubre cambios de perfil TRP3 en sesion sin buscar en cada RefreshFrame).
    -- El sweep sobre raid1-40 puede ser 47 llamadas por entrada x 6 tarjetas x 2 RefreshFrame
    -- por turno -> ~564 llamadas API WoW por tecla "Siguiente". Con el cache, es 0 si ya se encontro.
    local now = GetTime and GetTime() or 0
    if entry._trpMetaCached and (now - (entry._trpMetaCachedAt or 0)) < 30 then return end

    local profile
    local matchedUnit

    if entry.trpUnitID and entry.trpUnitID ~= "" and HarfordTRP3.GetPlayerProfileByUnitID then
        profile = HarfordTRP3.GetPlayerProfileByUnitID(entry.trpUnitID)
    end

    if not profile then
        local units = { "player", "target", "mouseover", "focus" }
        for i = 1, 4 do units[#units + 1] = "party" .. tostring(i) end
        for i = 1, 40 do units[#units + 1] = "raid" .. tostring(i) end
        for _, unit in ipairs(units) do
            if UnitExists and UnitExists(unit) then
                local guidMatches = UnitGUID and entry.id and entry.id ~= "" and UnitGUID(unit) == entry.id
                local unitID = HarfordTRP3.BuildUnitID and HarfordTRP3.BuildUnitID(unit)
                if guidMatches or (unitID and entry.trpUnitID ~= "" and unitID == entry.trpUnitID) then
                    profile = HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetPlayerProfile(unit)
                    matchedUnit = unit
                    break
                end
            end
        end
    end

    entry.nameColor = GetPlayerTurnNameColorHex(profile, matchedUnit) or entry.nameColor
    -- Marcar como cacheado para no repetir el sweep en cada RefreshFrame.
    -- Se invalida automaticamente a los 30s o cuando ApplySerializedState reconstruye entries.
    entry._trpMetaCached = true
    entry._trpMetaCachedAt = now
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
                local temp = GetResourceFromTable(tbl, "temp_health")
                if max > 0 then
                    return cur, max, temp
                end
            end
        end

        return nil, nil
    end

    return SafeNumber(entry and entry.hp, 0), SafeNumber(entry and entry.maxHp, 0), SafeNumber(entry and entry.tempHp, 0)
end

local function UpdateSmallBar(bar, text, cur, max, r, g, b, temp)
    if cur == nil or max == nil then
        bar:SetMinMaxValues(0, 1)
        bar:SetStatusBarColor(0.28, 0.28, 0.28, 1)
        bar:SetValue(0)
        if bar.tempFill then bar.tempFill:Hide() end
        text:SetText("--/--")
        return
    end

    max = SafeNumber(max, 0)
    cur = SafeNumber(cur, 0)
    temp = math.max(0, SafeNumber(temp, 0))
    local shownMax = max
    if max <= 0 then max = 1 cur = 0 end
    if cur > max then cur = max end
    if cur < 0 then cur = 0 end
    bar:SetMinMaxValues(0, max)
    bar:SetStatusBarColor(r, g, b, 1)
    bar:SetValue(max)
    bar:SetValue(cur)
    if bar.tempFill then
        if temp > 0 then
            local width = bar:GetWidth() or 0
            local tempWidth = math.max(2, width * math.min(temp / max, 1))
            bar.tempFill:ClearAllPoints()
            bar.tempFill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
            bar.tempFill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
            bar.tempFill:SetWidth(tempWidth)
            bar.tempFill:Show()
        else
            bar.tempFill:Hide()
        end
    end
    text:SetText(temp > 0 and (tostring(cur) .. "+" .. tostring(temp) .. "/" .. tostring(shownMax)) or (tostring(cur) .. "/" .. tostring(shownMax)))
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
    if not TurnFrame:IsShown() then return end
    local store = EnsureStore()
    EnsureRoundMarker()
    ClampActiveIndex()

    local count = #store.entries
    ClampViewStart()
    local isAdmin = IsTurnAdmin()

    if not isAdmin and editMode then
        editMode = false
        reorderSelectedIndex = nil
    end
    if reorderSelectedIndex and (reorderSelectedIndex < 1 or reorderSelectedIndex > count) then
        reorderSelectedIndex = nil
    end
    UpdateEditButton()

    StatusText:SetText("Turno " .. tostring(count > 0 and store.activeIndex or 0) .. " / " .. tostring(count))

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
            RefreshPlayerEntryTRP3Meta(entry)
            card.entryIndex = entryIndex
            card:Show()
            card.name:SetText(entry.name or "Sin nombre")
            if entry.kind == "round" then
                card.name:SetTextColor(GetEntryNameColor(entry))
                card.init:SetText("ESTADOS")
                card.init:Show()
                card.armorClass:Hide()
                card.hp:Hide()
            elseif entry.kind == "generic" or entry.kind == "players" then
                -- Marcadores de fase (Aliado/Neutral/Enemigo): sin barra de vida ni texto extra
                card.name:SetTextColor(GetEntryNameColor(entry))
                card.init:SetText("")
                card.init:Hide()
                card.armorClass:Hide()
                card.hp:Hide()
            else
                card.name:SetTextColor(GetEntryNameColor(entry))
                card.init:SetText("")
                card.init:Hide()
                local showArmor = entry.kind ~= "player"
                card.armorClass:SetShown(showArmor)
                if showArmor then
                    card.armorClass:SetText("CA " .. tostring(SafeNumber(entry.armorClass, 0)))
                    card.armorClass:SetEnabled(isAdmin)
                end
                local hp, maxHp, tempHp = GetEntryResourceValues(entry)
                card.hp:Show()
                UpdateSmallBar(card.hp, card.hpText, hp, maxHp, 0.78, 0.05, 0.08, tempHp)
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
            local isSystem = IsSystemEntry(entry)
            card.minus:SetShown(isAdmin and not isSystem)
            card.plus:SetShown(isAdmin and not isSystem)
            card.remove:SetShown(isAdmin and entry.kind ~= "round")
            card.moveLeft:SetShown(isAdmin and editMode)
            card.moveRight:SetShown(isAdmin and editMode)
            card.moveLeft:SetEnabled(entryIndex > 1)
            card.moveRight:SetEnabled(entryIndex < #store.entries)
            card.reorder:SetShown(editMode and reorderSelectedIndex == entryIndex)
        else
            card.entryIndex = nil
            SetCardTargetState(card, false)
            card.reorder:Hide()
            card.armorClass:Hide()
            card:Hide()
        end
    end
end

-- No lleva `initiative`: el orden es manual y el parametro que habia aqui se descartaba.
local function AddEntry(name, hp, maxHp, kind, id, mana, maxMana, unitName, icon, displayId, meta)
    if not IsTurnAdmin() then Print("Solo el admin puede anadir turnos.") return false end
    ClaimAdminIfNeeded()
    name = tostring(name or "")
    if name == "" then Print("Necesito un nombre para anadir el turno.") return false end

    local store = EnsureStore()
    EnsureRoundMarker()
    local entry = {
        id = id or NewId(),
        name = name,
        kind = NormalizeKind(kind),
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
        armorClass = meta and SafeNumber(meta.armorClass, 0) or 0,
        -- Se siembra de la reaccion, pero queda escrito para que el DM pueda corregirlo.
        bando = nil,
    }
    -- "players" es el hueco COLECTIVO de PJs; "player" un jugador concreto. Los dos van a pjs.
    entry.bando = ((tostring(entry.kind or "") == "player"
        or tostring(entry.kind or "") == "players") and "pjs")
        or ((tonumber(entry.reaction) or 0) >= 5 and "aliados")
        or ((tonumber(entry.reaction) or 0) == 4 and "neutrales")
        or "enemigos"
    Codec.NormalizeEntryLinks(entry)
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
    -- Un jugador es "player" mande lo que mande el llamador; lo demas se normaliza.
    local entryKind = (UnitIsPlayer and UnitIsPlayer(unit)) and "player" or NormalizeKind(kind)
    local displayId = 0
    if UnitCreatureDisplayID then
        displayId = UnitCreatureDisplayID(unit) or 0
    end
    local reaction = 0
    if UnitReaction and not (UnitIsPlayer and UnitIsPlayer(unit)) then
        reaction = UnitReaction(unit, "player") or 0
    end
    local armorClass = 0
    if not (UnitIsPlayer and UnitIsPlayer(unit)) and HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local parsed = HarfordTRP3.GetNPCStatBlock(unit)
        armorClass = SafeNumber(parsed and parsed.ac, 0)
    end

    AddEntry(name, hp, maxHp, entryKind, guid, mana, maxMana, fullName, trp.icon or GetFallbackCreatureIcon(unit), displayId, {
        npcId = trp.npcId,
        phaseId = trp.phaseId,
        trpFullID = trp.trpFullID,
        trpUnitID = trp.trpUnitID,
        trpProfileID = trp.trpProfileID,
        reaction = reaction,
        nameColor = trp.nameColor,
        armorClass = armorClass,
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
        local healthDelta = amount
        if amount < 0 then
            local _, _, tempHp = GetEntryResourceValues(entry)
            tempHp = math.max(0, SafeNumber(tempHp, 0))
            if tempHp > 0 then
                local absorb = math.min(tempHp, math.abs(amount))
                local okTemp, errTemp = HarfordDnDAPI.AdjustResourceForName(targetName, "temp_health", -absorb)
                if not okTemp then
                    Print("No se pudo ajustar vida temporal de " .. tostring(entry.name or targetName) .. ": " .. tostring(errTemp or "error desconocido"))
                    return
                end
                healthDelta = amount + absorb
            end
        end

        local ok, err = true, nil
        if healthDelta ~= 0 then
            ok, err = HarfordDnDAPI.AdjustResourceForName(targetName, "health", healthDelta)
        end
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
    if amount < 0 and SafeNumber(entry.tempHp, 0) > 0 then
        local absorb = math.min(SafeNumber(entry.tempHp, 0), math.abs(amount))
        entry.tempHp = math.max(0, SafeNumber(entry.tempHp, 0) - absorb)
        amount = amount + absorb
    end
    if amount ~= 0 then
        entry.hp = math.max(0, math.min(SafeNumber(entry.hp, 0) + amount, maxHp))
    end
    MarkChanged()
end

local function PromptAdjustHp(index, direction)
    direction = tonumber(direction) or 1
    direction = direction < 0 and -1 or 1

    local store = EnsureStore()
    local entry = store.entries[index]
    if not entry or IsSystemEntry(entry) then return end

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

local function SetEntryArmorClass(index, armorClass)
    if not IsTurnAdmin() then Print("Solo el admin puede modificar CA.") return false end
    local store = EnsureStore()
    local entry = store.entries[index]
    if not entry or IsSystemEntry(entry) or entry.kind == "player" then
        return false
    end
    armorClass = math.floor(tonumber(armorClass) or 0)
    if armorClass < 0 then armorClass = 0 end
    if SafeNumber(entry.armorClass, 0) == armorClass then return true end
    entry.armorClass = armorClass
    if HarfordDnDAPI and HarfordDnDAPI.UpdateSheetArmorClassForGuid then
        HarfordDnDAPI.UpdateSheetArmorClassForGuid(entry.id, armorClass)
    end
    MarkChanged()
    return true
end

local function PromptSetArmorClass(index)
    local store = EnsureStore()
    local entry = store.entries[index]
    if not entry or IsSystemEntry(entry) or entry.kind == "player" then return end

    local dialogName = "HARFORD_TURN_SET_ARMOR_CLASS"
    StaticPopupDialogs[dialogName] = StaticPopupDialogs[dialogName] or {
        text = "CA:",
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = true,
        editBoxWidth = 80,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self, data)
            local value = data and data.value or 0
            self.editBox:SetText(tostring(value))
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self, data)
            SetEntryArmorClass(data.index, self.editBox:GetText())
        end,
        EditBoxOnEnterPressed = function(self, data)
            SetEntryArmorClass(data.index, self:GetText())
            self:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }

    StaticPopupDialogs[dialogName].text = "CA de " .. tostring(entry.name or "NPC") .. ":"
    StaticPopup_Show(dialogName, nil, nil, { index = index, value = SafeNumber(entry.armorClass, 0) })
end

-- ─── AVANCE POR BANDOS ──────────────────────────────────────────────────────
-- El turno pasa de BLOQUE a bloque, no de criatura a criatura. Se anuncia con una entrada
-- sintetica -- `kind = "bando"` -- en vez de con un combatiente: asi el aviso que ya recorre a
-- todos los clientes sigue sirviendo sin cambiar el protocolo, y cada uno resuelve lo suyo.
--
-- Los bandos VACIOS se saltan. Un turno de "Neutrales" sin ningun neutral seria un clic perdido
-- cada asalto, y en mesa eso cansa mas que cualquier otra cosa.
local function SiguienteBandoConGente(desde)
    local orden = HarfordTurnOrderAPI.BANDOS
    for salto = 1, #orden do
        local i = ((desde - 1 + salto) % #orden) + 1
        if #HarfordTurnOrderAPI.GetBandoMembers(orden[i]) > 0 then return i end
    end
    return nil
end

local function AnteriorBandoConGente(desde)
    local orden = HarfordTurnOrderAPI.BANDOS
    for salto = 1, #orden do
        local i = ((desde - 1 - salto) % #orden) + 1
        if #HarfordTurnOrderAPI.GetBandoMembers(orden[i]) > 0 then return i end
    end
    return nil
end

-- Un bloque tiene DOS momentos, no uno. Entre ellos el DM juega a sus criaturas, y ahi es donde
-- hace falta poder tocar el reparto: lo que se anade con el bloque ya empezado NO participa en el,
-- porque su inicio ya se resolvio sin ellos y aplicarselo ahora seria contarlo dos veces.
local function EntradaDeBando(bando, fase)
    return {
        kind = "bando",
        bando = bando,
        fase = fase or "inicio",
        id = "bando:" .. tostring(bando) .. ":" .. tostring(fase or "inicio"),
        name = HarfordTurnOrderAPI.BANDO_ETIQUETA[bando] or tostring(bando),
    }
end

local function AnunciarBando(entrada)
    Print("|cffffff00" .. (HarfordTurnOrderAPI.FASE_ETIQUETA[entrada.fase] or "turno de")
        .. " " .. tostring(entrada.name) .. "|r")
end

local function NextTurn()
    if not IsTurnAdmin() then Print("Solo el admin puede avanzar turnos.") return end
    if OtroDMAcabaDeAvanzar() then return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    EnsureRoundMarker()
    if #store.entries == 0 then return end

    if store.modoBandos then
        local actual = tonumber(store.activeBando) or 0
        local bando, fase, nuevoAsalto
        -- Si el bloque en curso solo ha empezado, lo siguiente es CERRARLO, no saltar al otro.
        if actual >= 1 and store.faseBando == "inicio" then
            bando, fase = HarfordTurnOrderAPI.BANDOS[actual], "fin"
        else
            local siguiente = SiguienteBandoConGente(actual)
            if not siguiente then Print("No hay nadie en ningun bando.") return end
            -- Dar la vuelta = asalto nuevo. Tambien al arrancar (`actual` 0), que es el asalto 1.
            nuevoAsalto = (siguiente <= actual) or actual == 0
            store.activeBando = siguiente
            bando, fase = HarfordTurnOrderAPI.BANDOS[siguiente], "inicio"
        end
        store.faseBando = fase
        local turnSerial = AdvanceTurnSerial()
        -- Se cierra el asalto al volver al primer bando: es el unico punto del ciclo que significa
        -- "ha dado la vuelta". Sin esto las duraciones de asalto no bajaban nunca en modo bandos.
        if fase == "inicio" and nuevoAsalto then
            store.asalto = (tonumber(store.asalto) or 0) + 1
            local marca = { kind = "round", id = "asalto:" .. tostring(store.asalto),
                name = "Asalto " .. tostring(store.asalto), asalto = store.asalto }
            Print("|cffffff00Asalto " .. tostring(store.asalto) .. "|r")
            AlertRoundStates(marca, 0, turnSerial)
            AlertTurnChanged(marca, 0, turnSerial)
        end
        MarkChanged()
        local entrada = EntradaDeBando(bando, fase)
        entrada.asalto = store.asalto
        AnunciarBando(entrada)
        AlertTurnChanged(entrada, store.activeBando, turnSerial)
        -- El aviso de "es tu turno" es solo al EMPEZAR: repetirlo al cerrar seria ruido.
        if fase == "inicio" then AlertMyTurn(entrada, store.activeBando, turnSerial) end
        SendTurnNotice()
        return
    end

    store.activeIndex = store.activeIndex + 1
    ClampActiveIndex()
    EnsureActiveVisible()
    local turnSerial = AdvanceTurnSerial()
    MarkChanged()
    PrintTurnNotice(store.entries[store.activeIndex], store.activeIndex, #store.entries, turnSerial)
    AlertRoundStates(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    AlertTurnChanged(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    AlertMyTurn(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    SendTurnNotice()
end

local function PrevTurn()
    if not IsTurnAdmin() then Print("Solo el admin puede retroceder turnos.") return end
    if OtroDMAcabaDeAvanzar() then return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    EnsureRoundMarker()
    if #store.entries == 0 then return end

    if store.modoBandos then
        local actual = tonumber(store.activeBando) or 1
        local bando, fase
        if store.faseBando == "fin" then
            bando, fase = HarfordTurnOrderAPI.BANDOS[actual], "inicio"
        else
            local anterior = AnteriorBandoConGente(actual)
            if not anterior then Print("No hay nadie en ningun bando.") return end
            store.activeBando = anterior
            bando, fase = HarfordTurnOrderAPI.BANDOS[anterior], "fin"
        end
        store.faseBando = fase
        local turnSerial = AdvanceTurnSerial()
        MarkChanged()
        local entrada = EntradaDeBando(bando, fase)
        AnunciarBando(entrada)
        AlertTurnChanged(entrada, store.activeBando, turnSerial)
        SendTurnNotice()
        return
    end

    store.activeIndex = store.activeIndex - 1
    ClampActiveIndex()
    EnsureActiveVisible()
    local turnSerial = AdvanceTurnSerial()
    MarkChanged()
    PrintTurnNotice(store.entries[store.activeIndex], store.activeIndex, #store.entries, turnSerial)
    AlertRoundStates(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    AlertTurnChanged(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    AlertMyTurn(store.entries[store.activeIndex], store.activeIndex, turnSerial)
    SendTurnNotice()
end

-- Menu de reparto por bando (click derecho en la tarjeta). La reaccion del servidor solo PROPONE:
-- un NPC marcado como neutral puede ser hostil en la escena, y solo el DM lo sabe. Cambiarlo es
-- suyo, y el cambio se difunde ya -- no espera al siguiente turno -- porque la pertenencia es lo
-- que decide a quien le bajan los contadores.
local menuBando
local function AbrirMenuDeBando(entry, ancla)
    if not entry then return end
    if not IsTurnAdmin() then Print("Solo el admin reparte los bandos.") return end
    if tostring(entry.kind or "") ~= "npc" and tostring(entry.kind or "") ~= "player" then return end
    if tostring(entry.kind or "") == "player" then
        Print("Los personajes van siempre con los PJs.")
        return
    end
    menuBando = menuBando or CreateFrame("Frame", "HarfordTurnsBandoMenu", UIParent,
        "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menuBando, function(_, level)
        local info = UIDropDownMenu_CreateInfo()
        info.isTitle, info.notCheckable = true, true
        info.text = tostring(entry.name or "?")
        UIDropDownMenu_AddButton(info, level)
        local actual = HarfordTurnOrderAPI.GetBando(entry)
        for _, b in ipairs(HarfordTurnOrderAPI.BANDOS) do
            local i2 = UIDropDownMenu_CreateInfo()
            i2.text = HarfordTurnOrderAPI.BANDO_ETIQUETA[b] or b
            i2.checked = (b == actual)
            i2.func = function()
                local vivo = HarfordTurnOrderAPI.GetActiveBando()
                if HarfordTurnOrderAPI.SetBando(entry, b) then
                    -- Decir SIEMPRE cuando entra en juego. Meter a alguien en el bloque que se
                    -- esta jugando y que no le toque nada seria desconcertante sin explicacion.
                    if vivo == b then
                        Print("El turno de " .. tostring(HarfordTurnOrderAPI.BANDO_ETIQUETA[b] or b)
                            .. " ya esta en juego: entra en el proximo asalto.")
                    end
                    -- Difundir en el acto: si el reparto llegase tarde, el bloque que ya esta en
                    -- juego tocaria con la lista vieja.
                    MarkChanged()
                    Print(tostring(entry.name or "?") .. " pasa a "
                        .. tostring(HarfordTurnOrderAPI.BANDO_ETIQUETA[b] or b) .. ".")
                end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(i2, level)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, menuBando, ancla or "cursor", 0, 0)
end

local function CreateCard(parent, index)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    card:SetPoint("TOPLEFT", 18 + (index - 1) * (CARD_W + CARD_GAP), -78)
    card:EnableMouse(true)
    card:SetScript("OnMouseUp", function(self, button)
        local store = EnsureStore()
        local entryIndex = self.entryIndex or index
        if button == "RightButton" then
            AbrirMenuDeBando(store.entries[entryIndex], self)
            return
        end
        if button ~= "LeftButton" then return end
        if editMode then
            ClickEditEntry(entryIndex)
            return
        end
        local entry = store.entries[entryIndex]
        Ficha.ShowEntrySheet(entry)
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

    card.reorder = card:CreateTexture(nil, "OVERLAY")
    card.reorder:SetTexture(TEX_WHITE)
    card.reorder:SetVertexColor(0.65, 0.25, 1.0, 0.32)
    card.reorder:SetAllPoints(card)
    card.reorder:Hide()

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

    card.armorClass = MakeButton(card, "CA --", 48, 16, "TOP", card, "TOP", 0, -63, function()
        PromptSetArmorClass(card.entryIndex or index)
    end)
    card.armorClass:Hide()

    card.hp = CreateFrame("StatusBar", nil, card)
    card.hp:SetSize(58, 10)
    card.hp:SetPoint("TOP", 0, -81)
    card.hp:SetStatusBarTexture(TEX_STATUS)
    card.hpBg = card.hp:CreateTexture(nil, "BACKGROUND")
    card.hpBg:SetAllPoints()
    card.hpBg:SetTexture(TEX_WHITE)
    card.hpBg:SetVertexColor(0.08, 0.08, 0.08, 0.95)
    card.hp.tempFill = card.hp:CreateTexture(nil, "OVERLAY", nil, 1)
    card.hp.tempFill:SetTexture(TEX_WHITE)
    card.hp.tempFill:SetVertexColor(0.35, 0.82, 1.0, 0.78)
    card.hp.tempFill:Hide()
    card.hpText = card.hp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.hpText:SetPoint("CENTER", 0, 0)
    if card.hpText.SetDrawLayer then card.hpText:SetDrawLayer("OVERLAY", 7) end

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

    local title = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -15)
    title:SetText("Turnos Harford")

    StatusText = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    StatusText:SetPoint("LEFT", title, "RIGHT", 14, 0)

    local close = CreateFrame("Button", nil, TurnFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -5)

    TurnFrame.adminControls = {}

    local targetButton = MakeButton(TurnFrame, "Objetivo", 62, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 16, -51, function() AddUnit("target", "target") end)

    -- Botones de turno generico: anaden una entrada NPC con la reaccion fija
    local GENERIC_TURN_ICON = "Interface\\Icons\\INV_Misc_PocketWatch_01"
    local function AddGenericTurn(name, reaction)
        AddEntry(name, 0, 0, "generic", NewId(), 0, 0, name, GENERIC_TURN_ICON, 0, { reaction = reaction })
    end

    local btnAliado  = MakeButton(TurnFrame, "Aliado",  54, 22, "TOPLEFT", TurnFrame, "TOPLEFT",  82, -51, function() AddGenericTurn("Aliado",  8) end)
    local btnNeutral = MakeButton(TurnFrame, "Neutral", 60, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 140, -51, function() AddGenericTurn("Neutral", 4) end)
    local btnEnemigo = MakeButton(TurnFrame, "Enemigo", 64, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 204, -51, function() AddGenericTurn("Enemigo", 1) end)

    -- Turno compartido de los PJs: iniciativa POR BANDOS. Un solo hueco para todos los
    -- personajes jugadores, que actuan en el orden que quieran entre ellos. Solo tiene sentido
    -- uno, asi que se avisa en vez de apilar varios.
    local PLAYERS_TURN_ICON = "Interface\\Icons\\INV_Misc_GroupLooking"
    local function AddPlayersTurn()
        local store = EnsureStore()
        for _, e in ipairs(store.entries or {}) do
            if e.kind == "players" then
                Print("Ya hay un turno de PJs en la lista.")
                return
            end
        end
        AddEntry("PJs", 0, 0, "players", NewId(), 0, 0, "PJs", PLAYERS_TURN_ICON, 0, {})
    end
    local btnPJs = MakeButton(TurnFrame, "PJs", 44, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 272, -51, AddPlayersTurn)
    -- Abre la lista de candidatos. Se declara aqui pero la funcion vive mas abajo, en su bloque.
    local btnLista = MakeButton(TurnFrame, "Lista", 48, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 448, -51,
        function() HarfordTurnOrderAPI.ToggleCandidates() end)
    btnLista:GetFontString():SetTextColor(0.55, 0.85, 1.0)
    btnPJs:GetFontString():SetTextColor(0.2, 1.0, 0.4)

    btnAliado:GetFontString():SetTextColor(0.2, 1.0, 0.2)
    btnNeutral:GetFontString():SetTextColor(1.0, 1.0, 0.0)
    btnEnemigo:GetFontString():SetTextColor(1.0, 0.2, 0.2)

    local btnIniciar = MakeButton(TurnFrame, "Iniciar", 58, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 320, -51, Combate.StartCombat)
    local btnTerminar = MakeButton(TurnFrame, "Terminar", 66, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 382, -51, Combate.EndCombat)
    btnIniciar:GetFontString():SetTextColor(1.0, 0.82, 0.1)
    btnTerminar:GetFontString():SetTextColor(0.8, 0.8, 0.8)

    local editButton = MakeButton(TurnFrame, "Editar", 58, 22, "TOPLEFT", TurnFrame, "TOPLEFT", 16, -206, ToggleEditMode)
    TurnFrame.editButton = editButton
    tinsert(TurnFrame.adminControls, targetButton)
    tinsert(TurnFrame.adminControls, btnAliado)
    tinsert(TurnFrame.adminControls, btnNeutral)
    tinsert(TurnFrame.adminControls, btnEnemigo)
    tinsert(TurnFrame.adminControls, btnPJs)
    tinsert(TurnFrame.adminControls, btnIniciar)
    tinsert(TurnFrame.adminControls, btnTerminar)
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
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        EnsureStore()
        PurgeStaleEntries()
        if HarfordSync and HarfordSync.RegisterPrefix then
            HarfordSync.RegisterPrefix(COMM_PREFIX)
        elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(COMM_PREFIX)
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Diferido: al entrar, el grupo aun no esta formado y `BestChannel()` devolveria nil, que
        -- es fallar en silencio.
        if C_Timer and C_Timer.After then
            C_Timer.After(4, function() RequestTurnState() end)
        end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        RequestTurnState()
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

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        -- Solo interesa el HP del target (NPC trackeado). Cambios de HP de otras
        -- unidades no modifican el estado de los turnos -> no hacer RefreshFrame.
        if unit == "target" and RefreshTargetNpcHealthFromUnit("target") then
            MarkChanged()
        end
        return
    end

    local prefix, message, _, sender = ...
    if prefix ~= COMM_PREFIX then return end
    if IsSenderSelf(sender) then return end
    if not IsTrustedTurnSender(sender) then return end

    local opcode = tostring(message or ""):match("^([^|]+)")
    suppressBroadcast = true
    local applied = ApplyTurnMessage(message, sender)
    suppressBroadcast = false
    if applied then
        local store = EnsureStore()
        if opcode ~= "TURN" then
            -- TURN y STATE pueden llegar en orden distinto. El serial de sesion
            -- mantiene la clave de deduplicacion alineada sin persistir nada.
            AlertTurnChanged(store.entries[store.activeIndex], store.activeIndex, turnSerial)
            AlertMyTurn(store.entries[store.activeIndex], store.activeIndex, turnSerial)
        end
        RefreshFrame()
    end
end)

-- Superficie de control publica del tracker. Las mutaciones estan gateadas
-- internamente por IsTurnAdmin() (= CanUseDMTools): inertes sin HarfordAdmin + .ph dm.
-- HarfordAdmin las invoca por aqui (p.ej. HarfordAdminUnitMenu usa AddUnit/Toggle);
-- no debe tocar internals del core (store/broadcast). Render/sync/recepcion viven en el core.
-- La ficha emergente recibe aqui lo que necesita del tracker.
if Ficha and Ficha.Init then
    Ficha.Init({
        EntryIconMarkup = EntryIconMarkup,
        GetEntryNameColor = GetEntryNameColor,
        GetPlayerTurnNameColorHex = GetPlayerTurnNameColorHex,
        IsSystemEntry = IsSystemEntry,
        SetFrameBackground = SetFrameBackground,
        MakeButton = MakeButton,
        Print = Print,
    })
end

-- El modulo de combate recibe aqui lo que necesita del tracker. Va DESPUES de MarkChanged, que es
-- de asignacion adelantada (`local` arriba, cuerpo mas abajo): inyectarlo antes pasaria nil.
if Combate and Combate.Init then
    Combate.Init({
        commPrefix = COMM_PREFIX,
        roundMarkerInitiative = ROUND_MARKER_INITIATIVE,
        AdvanceTurnSerial = AdvanceTurnSerial,
        ClaimAdminIfNeeded = ClaimAdminIfNeeded,
        EnsureActiveVisible = EnsureActiveVisible,
        EnsureRoundMarker = EnsureRoundMarker,
        EnsureStore = EnsureStore,
        EntryBelongsToMe = EntryBelongsToMe,
        IsSystemEntry = IsSystemEntry,
        IsTurnAdmin = IsTurnAdmin,
        MarkChanged = MarkChanged,
        Print = Print,
        SafeNumber = SafeNumber,
        SendState = SendState,
    })
end

HarfordTurnOrderAPI = HarfordTurnOrderAPI or {}
-- Listeners notificados cuando empieza TU turno (los invoca AlertMyTurn). Uso: reacciones del Libro.
HarfordTurnOrderAPI._myTurnListeners = HarfordTurnOrderAPI._myTurnListeners or {}
HarfordTurnOrderAPI._turnChangedListeners = HarfordTurnOrderAPI._turnChangedListeners or {}
-- ?Hay un combate en marcha? Cuenta solo COMBATIENTES: el marcador de asalto se inserta siempre
-- (`EnsureRoundMarker`, 8 llamadas) y `entries` PERSISTE en SavedVariables, asi que "la lista no
-- esta vacia" es cierto para siempre en cuanto se abre el tracker una vez. Lo usa la economia de
-- turno para saber si debe llevar la cuenta de acciones.
-- ─── BANDOS ─────────────────────────────────────────────────────────────────
-- La iniciativa va por BANDOS, no por criatura: cuando le toca a Enemigos actuan todos, y sus
-- duraciones bajan de golpe. Es una divergencia deliberada del manual (5e usa iniciativa
-- individual) y esta en la seccion de decisiones de mesa de AGENTS.md.
--
-- El orden es FIJO. Sin tirada: se sabe siempre quien va despues de quien, que en mesa vale mas
-- que la sorpresa de quien empieza.
-- ─── LISTA DE CANDIDATOS ────────────────────────────────────────────────────
-- Anadir de uno en uno targeteando es la unica via que teniamos, y en una escena con seis enemigos
-- son doce clics y perder el objetivo que tenias. Este panel los junta y se anaden pulsando.
--
-- El cliente NO permite enumerar "los NPC cercanos": no hay API. Las dos unicas fuentes reales son
-- el GRUPO (`party1-4` / `raid1-40`, mascotas incluidas) y las PLACAS DE NOMBRE visibles
-- (`C_NamePlate.GetNamePlates()`). Comprobado tambien en Atlas, que resuelve unidades exactamente
-- con esas dos y ninguna mas.
--
-- Va en `do...end` porque este fichero ronda el limite de 200 locales de Lua 5.1.
do
    local FILA_ALTO, PANEL_ANCHO, VISIBLES = 19, 214, 11
    local panel, filas = nil, {}

    -- Quien esta YA en la lista de turnos, por guid. Volver a anadirlo duplicaria la entrada, y un
    -- duplicado en el orden de turnos es de las cosas que mas confunden en mesa.
    local function YaEstan()
        local puestos = {}
        local store = HarfordTurnOrderStore
        if type(store) ~= "table" or type(store.entries) ~= "table" then return puestos end
        for _, e in ipairs(store.entries) do
            if e.guid and e.guid ~= "" then puestos[tostring(e.guid)] = true end
        end
        return puestos
    end

    -- Los candidatos, en dos bloques. El orden es deliberado: el grupo primero porque casi siempre
    -- se anade entero, y las placas despues porque cambian solas al moverse.
    local function Candidatos()
        local puestos, vistos, fuera = YaEstan(), {}, {}

        local function Meter(unit, bloque)
            if not (UnitExists and UnitExists(unit)) then return end
            local guid = UnitGUID and UnitGUID(unit)
            if not guid or guid == "" or vistos[guid] then return end
            -- Ya en la lista: no se muestra. Es mas claro que mostrarlo en gris y no reaccionar.
            if puestos[guid] then return end
            vistos[guid] = true
            local esJugador = UnitIsPlayer and UnitIsPlayer(unit)
            fuera[#fuera + 1] = {
                unit = unit, guid = guid, bloque = bloque,
                nombre = (UnitName and UnitName(unit)) or "?",
                jugador = esJugador and true or false,
                muerto = (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)) and true or false,
                reaccion = (not esJugador) and UnitReaction and UnitReaction("player", unit) or nil,
            }
        end

        Meter("player", "grupo")
        if IsInRaid and IsInRaid() then
            for i = 1, 40 do Meter("raid" .. i, "grupo"); Meter("raidpet" .. i, "grupo") end
        elseif IsInGroup and IsInGroup() then
            for i = 1, 4 do Meter("party" .. i, "grupo"); Meter("partypet" .. i, "grupo") end
        end
        -- El objetivo y el foco pueden no tener placa (fuera de rango de nameplates), asi que se
        -- meten aparte: son justo los que el DM tiene mas a mano.
        Meter("target", "vista")
        Meter("focus", "vista")
        if C_NamePlate and C_NamePlate.GetNamePlates then
            for _, placa in ipairs(C_NamePlate.GetNamePlates() or {}) do
                if placa.namePlateUnitToken then Meter(placa.namePlateUnitToken, "vista")
                elseif placa.unit then Meter(placa.unit, "vista") end
            end
        end
        return fuera
    end

    local function ColorDe(c)
        if c.jugador then
            -- `UnitColorRGB` devuelve r, g, b sueltos (mas classFile), no una tabla.
            if HarfordClassColors and HarfordClassColors.UnitColorRGB then
                local r, g, b = HarfordClassColors.UnitColorRGB(c.unit)
                if r then return r, g, b end
            end
            return 0.6, 0.8, 1.0
        end
        local r = tonumber(c.reaccion) or 0
        if r >= 5 then return 0.35, 0.85, 0.40 end     -- aliado
        if r == 4 then return 0.95, 0.85, 0.30 end     -- neutral
        return 0.95, 0.35, 0.30                        -- hostil
    end

    local function EnsureFila(i)
        local f = filas[i]
        if f then return f end
        f = CreateFrame("Button", nil, panel)
        f:SetSize(PANEL_ANCHO - 16, FILA_ALTO)
        f.fondo = f:CreateTexture(nil, "BACKGROUND")
        f.fondo:SetAllPoints(f)
        f.fondo:SetTexture(TEX_WHITE)
        f.fondo:SetVertexColor(1, 1, 1, 0)
        f.texto = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.texto:SetPoint("LEFT", f, "LEFT", 6, 0)
        f.texto:SetPoint("RIGHT", f, "RIGHT", -6, 0)
        f.texto:SetJustifyH("LEFT")
        f:SetScript("OnEnter", function(self) self.fondo:SetVertexColor(1, 0.82, 0.2, 0.18) end)
        f:SetScript("OnLeave", function(self) self.fondo:SetVertexColor(1, 1, 1, 0) end)
        filas[i] = f
        return f
    end

    local RefrescarLista   -- se asigna abajo; el OnClick de las filas cierra sobre ella

    local function PintarFilas(lista, desde)
        local usadas = 0
        for i = 1, VISIBLES do
            local c = lista[desde + i - 1]
            local f = EnsureFila(i)
            if not c then f:Hide()
            else
                usadas = usadas + 1
                local r, g, b = ColorDe(c)
                local marca = c.bloque == "grupo" and "" or "· "
                f.texto:SetText(marca .. tostring(c.nombre) .. (c.muerto and " |cff888888(muerto)|r" or ""))
                f.texto:SetTextColor(r, g, b)
                f.candidato = c
                f:SetScript("OnClick", function(self)
                    -- Se anade por UNIDAD, que es lo que trae vida, CA, retrato y reaccion. Anadir
                    -- por nombre daria una entrada hueca.
                    AddUnit(self.candidato.unit, self.candidato.jugador and "player" or "npc")
                    if RefrescarLista then RefrescarLista() end
                end)
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -26 - (i - 1) * FILA_ALTO)
                f:Show()
            end
        end
        return usadas
    end

    local function CrearPanel()
        if panel then return panel end
        panel = CreateFrame("Frame", "HarfordTurnCandidatesFrame", UIParent, "BackdropTemplate")
        panel:SetSize(PANEL_ANCHO, 26 + VISIBLES * FILA_ALTO + 30)
        -- DIALOG como el resto de ventanas del proyecto; los overlays de unitframe van a MEDIUM,
        -- pero esto es un panel.
        panel:SetFrameStrata("DIALOG")
        panel:SetFrameLevel(510)
        panel:SetClampedToScreen(true)
        SetFrameBackground(panel)
        panel.border = CreateFrame("Frame", nil, panel, "DialogBorderTemplate")
        panel.border:SetAllPoints(panel)

        panel.titulo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        panel.titulo:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)
        panel.titulo:SetText("Anadir al combate")

        panel.aviso = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        panel.aviso:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)
        panel.aviso:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)
        panel.aviso:SetJustifyH("LEFT")

        -- Solo mientras se ve: la regla del proyecto es no dejar eventos vivos con el panel
        -- cerrado, y las placas de nombre disparan constantemente.
        panel:SetScript("OnShow", function(self)
            self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
            self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
            self:RegisterEvent("GROUP_ROSTER_UPDATE")
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            self:RegisterEvent("PLAYER_FOCUS_CHANGED")
            if RefrescarLista then RefrescarLista() end
        end)
        panel:SetScript("OnHide", function(self) self:UnregisterAllEvents() end)
        panel:SetScript("OnEvent", function() if RefrescarLista then RefrescarLista() end end)
        panel:Hide()
        return panel
    end

    RefrescarLista = function()
        if not (panel and panel:IsShown()) then return end
        local lista = Candidatos()
        local usadas = PintarFilas(lista, 1)
        if #lista == 0 then
            panel.aviso:SetText("Nada que anadir. Acercate o selecciona a alguien.")
        elseif #lista > VISIBLES then
            panel.aviso:SetText(string.format("%d mas fuera de la lista; anade y se recolocan.",
                #lista - VISIBLES))
        else
            panel.aviso:SetText(usadas .. " disponible(s). Pulsa para anadir.")
        end
    end

    -- Se cuelga del lado derecho de la ventana de turnos, para no taparla.
    function HarfordTurnOrderAPI.ToggleCandidates()
        CrearPanel()
        if panel:IsShown() then panel:Hide() return end
        if not (HarfordTurnOrderFrame and HarfordTurnOrderFrame:IsShown()) then
            Print("Abre primero la ventana de turnos.")
            return
        end
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", HarfordTurnOrderFrame, "TOPRIGHT", -6, 0)
        panel:Show()
    end

    HarfordTurnOrderAPI.RefreshCandidates = function() if RefrescarLista then RefrescarLista() end end
end

HarfordTurnOrderAPI.FASES = { "inicio", "fin" }
HarfordTurnOrderAPI.FASE_ETIQUETA = { inicio = "empieza el turno de", fin = "termina el turno de" }

HarfordTurnOrderAPI.BANDOS = { "pjs", "enemigos", "neutrales", "aliados" }
HarfordTurnOrderAPI.BANDO_ETIQUETA = {
    pjs = "Personajes", enemigos = "Enemigos", neutrales = "Neutrales", aliados = "Aliados",
}

-- La reaccion de WoW sirve para PROPONER, nunca para decidir: un NPC hostil de verdad puede estar
-- marcado como neutral en el servidor, y al reves. El DM lo corrige y su correccion manda.
local function BandoSugerido(entry)
    if not entry then return "enemigos" end
    -- Un PJ siempre va con los PJs, mire lo que mire su reaccion.
    local k = tostring(entry.kind or "")
    if k == "player" or k == "players" then return "pjs" end
    local r = tonumber(entry.reaction) or 0
    if r >= 5 then return "aliados" end
    if r == 4 then return "neutrales" end
    return "enemigos"
end

function HarfordTurnOrderAPI.GetBando(entry)
    if not entry then return "enemigos" end
    -- Un PJ no se puede mover de su bando ni a mano: es la regla que pidio la mesa.
    local k = tostring(entry.kind or "")
    if k == "player" or k == "players" then return "pjs" end
    local guardado = tostring(entry.bando or "")
    for _, b in ipairs(HarfordTurnOrderAPI.BANDOS) do
        if guardado == b then return guardado end
    end
    return BandoSugerido(entry)
end

-- Cambiarlo a mano. Se GUARDA en la entrada y viaja en la foto, para que la correccion del DM la
-- vean todos y sobreviva a una recarga; recalcularlo en cada cliente daria versiones distintas.
function HarfordTurnOrderAPI.SetBando(entry, bando)
    if not entry then return false end
    local k = tostring(entry.kind or "")
    if k == "player" or k == "players" then
        return false, "Los personajes van siempre con los PJs"
    end
    bando = tostring(bando or "")
    for _, b in ipairs(HarfordTurnOrderAPI.BANDOS) do
        if bando == b then
            entry.bando = bando
            return true
        end
    end
    return false, "Bando desconocido"
end

-- Quienes componen un bando ahora mismo. Lo usa el avance de turno para saber a quien le baja el
-- contador, y cada cliente lo resuelve por su cuenta: el DM solo anuncia QUE bando empieza.
function HarfordTurnOrderAPI.GetBandoMembers(bando)
    local fuera = {}
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return fuera end
    for _, entry in ipairs(store.entries) do
        if HarfordTurnOrderAPI.GetBando(entry) == bando then fuera[#fuera + 1] = entry end
    end
    return fuera
end

-- Encender o apagar la iniciativa por bandos. Se guarda en el almacen y viaja con la foto, para
-- que la mesa entera este en el mismo modo: media mesa por bandos y media por criatura serian dos
-- combates distintos.
function HarfordTurnOrderAPI.GetActiveBando()
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" then return nil end
    local i = tonumber(store.activeBando)
    return i and HarfordTurnOrderAPI.BANDOS[i] or nil
end

function HarfordTurnOrderAPI.SetModoBandos(activo)
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" then return false end
    store.modoBandos = activo and true or nil
    store.activeBando = activo and (tonumber(store.activeBando) or 0) or nil
    return true
end

function HarfordTurnOrderAPI.IsModoBandos()
    local store = HarfordTurnOrderStore
    return type(store) == "table" and store.modoBandos == true
end

function HarfordTurnOrderAPI.HasActiveCombat()
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return false end
    for _, entry in ipairs(store.entries) do
        if not IsSystemEntry(entry) then return true end
    end
    return false
end

function HarfordTurnOrderAPI.RegisterMyTurnListener(fn)
    if type(fn) == "function" then
        table.insert(HarfordTurnOrderAPI._myTurnListeners, fn)
    end
end
function HarfordTurnOrderAPI.RegisterTurnChangedListener(fn)
    if type(fn) == "function" then
        table.insert(HarfordTurnOrderAPI._turnChangedListeners, fn)
    end
end
HarfordTurnOrderAPI.Toggle = ToggleFrame
HarfordTurnOrderAPI.Refresh = RefreshFrame
HarfordTurnOrderAPI.SendState = SendState
HarfordTurnOrderAPI.AddEntry = AddEntry
HarfordTurnOrderAPI.AddUnit = AddUnit
HarfordTurnOrderAPI.NextTurn = NextTurn
HarfordTurnOrderAPI.PrevTurn = PrevTurn
HarfordTurnOrderAPI.RemoveEntry = RemoveEntry
HarfordTurnOrderAPI.AdjustHp = AdjustHp
HarfordTurnOrderAPI.SetArmorClass = SetEntryArmorClass
HarfordTurnOrderAPI.MoveEntry = MoveEntry
HarfordTurnOrderAPI.ToggleEditMode = ToggleEditMode
HarfordTurnOrderAPI.IsAdmin = IsTurnAdmin
-- Los efectos "una vez por turno" de la ficha se rearman al empezar el turno
-- propio. El estado sigue siendo runtime y no altera el tracker de turnos.
HarfordTurnOrderAPI.RegisterMyTurnListener(function()
    if HarfordDnDStore and HarfordDnDStore.ResetHuntersMarkTurn then
        HarfordDnDStore.ResetHuntersMarkTurn()
    end
end)
function HarfordTurnOrderAPI.GetArmorClassForGuid(guid)
    guid = tostring(guid or "")
    if guid == "" then return nil end
    local store = EnsureStore()
    for _, entry in ipairs(store.entries or {}) do
        if entry and tostring(entry.id or "") == guid then
            return SafeNumber(entry.armorClass, 0), entry
        end
    end
end

function HarfordTurnOrderAPI.SetArmorClassForGuid(guid, armorClass)
    guid = tostring(guid or "")
    if guid == "" then return false end
    local store = EnsureStore()
    for index, entry in ipairs(store.entries or {}) do
        if entry and tostring(entry.id or "") == guid then
            return SetEntryArmorClass(index, armorClass)
        end
    end
    return false
end

-- Comandos sueltos retirados: usar `/harford turnos <args>`.
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
    elseif cmd == "move" or cmd == "mover" then
        local fromIndex, toIndex = rest:match("^(%d+)%s+(%d+)$")
        if not fromIndex or not toIndex then
            Print("Uso: /harford turnos mover <origen> <destino>")
            return
        end
        MoveEntryToIndex(tonumber(fromIndex), tonumber(toIndex))
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
        AddEntry(rest, 1, 1, "npc")
    else
        ToggleFrame()
    end
end
