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
local AlguienSeQuedaElClick   -- idem: la tarjeta se crea antes que el API
local AnnounceCombatStart   -- idem: la usa el manejador de TSTART
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
-- Estoy YO en la lista de miembros de un bloque? Se compara por guid, que es lo que guarda cada
-- miembro. Sin bloque o sin lista, no.
local function SoyMiembroDe(entry)
    local miGuid = UnitGUID and UnitGUID("player")
    if not miGuid then return false end
    for _, m in ipairs((type(entry) == "table" and entry.miembros) or {}) do
        if tostring(m.guid or "") == miGuid then return true end
    end
    return false
end

local function EntryBelongsToMe(entry)
    -- El turno del bloque de PJs es de SUS MIEMBROS, no de todo el que tenga el addon puesto.
    -- Devolver true a secas mandaba "ES TU TURNO" a la raid entera, incluida la gente que solo
    -- estaba mirando: la pertenencia la fija el DM y esta guardada, asi que hay que consultarla.
    if entry and entry.kind == "players" then return SoyMiembroDe(entry) end
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
    -- El estandarte O el aviso de raid, no los dos: salian a la vez y quedaban tres "ES TU TURNO"
    -- pisandose en la misma esquina. El estandarte es el aviso; el de raid es su respaldo para
    -- cuando esta apagado o el arte no existe -- por eso se mira lo que DEVUELVE.
    local conEstandarte = HarfordTurnOrderAPI.ShowTurnBanner
        -- El asalto sale de la ENTRADA, no del store: aqui arriba `EnsureStore` todavia no existe.
        and HarfordTurnOrderAPI.ShowTurnBanner(text,
            (tonumber(entry.asalto) or 0) > 0 and ("Asalto " .. entry.asalto)
                or tostring(entry.name or ""), true)
    if not conEstandarte and RaidNotice_AddMessage and RaidWarningFrame then
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

    -- Sin aviso de "ESTADOS": era de cuando las condiciones se repasaban a mano al llegar el
    -- marcador de asalto. Ahora cada una caduca sola, en el turno de su dueno, asi que anunciarlo
    -- pedia a la mesa que hiciera algo que ya estaba hecho. El marcador de asalto se queda --dice
    -- por que vuelta vamos-- pero callado.
end

-- Repinta sin que un fallo pueda llevarse por delante lo que venga detras, pero DICIENDOLO. Una
-- proteccion silenciosa cambia un error visible por una funcionalidad que no va, que es peor.
local avisadoRepintado = false
local function RepintarProtegido(fn)
    if not fn then return end
    local ok, err = pcall(fn)
    if not ok and not avisadoRepintado then
        avisadoRepintado = true
        Print("|cffff5555Fallo pintando la ventana de turnos|r (el turno sigue funcionando): "
            .. tostring(err))
    end
end

local function AlertTurnChanged(entry, activeIndex, turnSerial)
    -- Protegido: un fallo pintando el marcador no puede llevarse por delante el aviso a los
    -- oyentes, que es lo que apaga estados y reinicia el turno en el resto del addon.
    RepintarProtegido(HarfordTurnOrderAPI.RefreshTurnMarker)
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

-- QUINCE MINUTOS para quien puede recuperarla: con el boton de `Unirse`, la foto automatica y el
-- relevo entre companeros, volver a un combate en curso ya no depende de esto. Cuanto antes limpie,
-- menos rato se arrastra un combate muerto.
local STALE_SECONDS = 15 * 60

-- CUATRO HORAS para el DM. Su copia es LA BUENA y no hay nadie que pueda devolversela: si se le
-- cae el cliente veinte minutos, tirarle el combate es perderlo de verdad, no limpiar un resto.
-- Al que solo lo recibe le sobra con quince minutos, porque volver le cuesta un boton.
local STALE_SECONDS_DM = 4 * 60 * 60


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

local function PurgeStaleEntries()
    local store = EnsureStore()
    -- No se sale por lista vacia: lo que caduca es el COMBATE, y su estado puede haber quedado
    -- puesto sin entradas. Si no hay ni entradas ni estado no hay nada que hacer.
    if #store.entries == 0 and store.estado == nil and not store.movimiento
        and not store.economia then
        return false
    end
    local ahora = (time and time()) or 0
    local ultimo = tonumber(store.lastTouched) or 0
    -- Sin sello (lista escrita por una version anterior) se considera vieja: es lo que hay guardado
    -- de antes de existir la caducidad, y precisamente eso es lo que sobra.
    local limite = (IsTurnAdmin and IsTurnAdmin()) and STALE_SECONDS_DM or STALE_SECONDS
    if ultimo > 0 and ahora > 0 and (ahora - ultimo) < limite then return false end
    HarfordTurnOrderAPI.ultimaPurga = {
        sello = ultimo, ahora = ahora, limite = limite,
        motivo = (ultimo <= 0) and "sin sello" or "caducado",
        mandaba = (IsTurnAdmin and IsTurnAdmin()) and true or false,
        entradas = #store.entries, estado = store.estado,
    }
    store.entries = {}
    store.activeIndex = 1
    store.lastTouched = nil
    -- Sin combatientes no hay bandos: dejar el bloque activo apuntando a una lista vacia haria que
    -- el siguiente avance arrancara a media rotacion.
    store.activeBando = nil
    store.faseBando = nil
    -- Y el COMBATE se acabo. Sin esto, el que se desconecta a media pelea y vuelve al dia
    -- siguiente --sin nadie que le mande una foto nueva-- se encontraba las entradas limpias pero
    -- el estado en `activo`: seguia "en combate" el solo, con su asalto de ayer.
    store.estado = nil
    store.asalto = nil
    -- Lo gastado iba sellado con el asalto, que acaba de irse: se tira con el, o el sello dejaria
    -- de valer y podria aplicarse a la pelea siguiente.
    store.movimiento = nil
    store.economia = nil
    if Combate and Combate.CleanUpAfterCombat then pcall(Combate.CleanUpAfterCombat) end
    return true
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
    -- El tercer campo llevaba vacio desde siempre; ahora lleva el modo. Un receptor antiguo lo
    -- ignora y sigue leyendo las entradas del cuarto, que es donde ya las buscaba.
    -- El tercer campo llevaba vacio desde siempre; ahora lleva el modo Y donde va la rotacion.
    -- Sin la posicion, un DM que recibe la foto sin haber visto un TURNB arranca de cero.
    -- Los DMs secundarios van en el mismo hueco que el modo, detras: quien delega tiene que ver
    -- la MISMA cadena que los demas o mandaria el efecto a alguien que nadie reconoce.
    local dms = table.concat(store.dms or {}, ";")
    -- El estado del combate va al final del tercer hueco, detras de los DMs. Un cliente anterior
    -- lee modo y DMs como siempre y no llega a mirar esto, en vez de descuadrarse los campos.
    local estado = HarfordTurnOrderAPI.GetCombatState() or ""
    -- Hueco del antiguo modo de turnos. Va vacio, pero SIGUE: el tercer campo es "modo~dms~estado"
    -- y quitarlo descuadraria los otros dos en un cliente que aun no se haya actualizado.
    local modo = ""
    return "STATE|" .. tostring(store.activeIndex or 1) .. "|"
        .. modo .. "~" .. dms .. "~" .. estado .. "|" .. table.concat(parts, ";")
end

local function SerializeTurnNotice()
    local store = EnsureStore()

    local index = tonumber(store.activeIndex) or 1
    local entry = store.entries[index]
    if not entry then return nil end

    return table.concat({
        "TURN",
        tostring(turnSerial or 0),
        tostring(index),
        tostring(#store.entries),
        -- El ASALTO. Este hueco iba vacio --era la fase del avance por bloques-- asi que entra sin
        -- cambiar el numero de campos y un cliente sin actualizar lo ignora igual que antes.
        -- Hace falta porque el avance ya no manda la foto entera, y el asalto viajaba en ella:
        -- sin esto las duraciones medidas en asaltos dejarian de bajar en los demas clientes.
        tostring(store.asalto or 0),
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

local function ApplyTurnNotice(message, sender)
    local opcode, serialRaw, activeRaw, countRaw, adminRaw, entryRaw = strsplit("|", message or "")

    if (opcode == "TURN" or opcode == "TURNB") and sender and sender ~= "" then
        ultimoAvanceAjeno.quien = Ambiguate and Ambiguate(sender, "short") or sender
        ultimoAvanceAjeno.cuando = (time and time()) or 0
    end

    -- `TURNB` era el aviso de turno por bloque. Se descarta en silencio: un cliente sin actualizar
    -- puede seguir mandandolo, y aplicarlo volveria a meter aqui el modo que se ha retirado.
    -- Vida de un NPC, sola. Se aplica a su tarjeta y a su hueco dentro de un bloque, que tambien
    -- guarda vida y no tiene tarjeta propia.
    if opcode == "THP" then
        local guid, hpRaw, maxRaw = activeRaw, countRaw, adminRaw
        if not (guid and guid ~= "") then return false end
        local store = EnsureStore()
        local hp, maxHp = SafeNumber(hpRaw, 0), SafeNumber(maxRaw, 0)
        local cambio = false
        local function Aplicar(lista)
            for _, e in ipairs(lista or {}) do
                if e and tostring(e.guid or e.id or "") == guid then
                    if SafeNumber(e.hp, 0) ~= hp or SafeNumber(e.maxHp, 0) ~= maxHp then
                        e.hp, e.maxHp = hp, maxHp
                        cambio = true
                    end
                end
            end
        end
        for _, entry in ipairs(store.entries or {}) do
            Aplicar({ entry })
            Aplicar(entry.miembros)
        end
        if cambio then
            TouchStore()
            RepintarProtegido(RefreshFrame)
        end
        return true
    end

    if opcode == "TURNB" then return false end

    if opcode ~= "TURN" then return false end

    local serial = SafeNumber(serialRaw, 0)
    local activeIndex = SafeNumber(activeRaw, 1)
    local count = SafeNumber(countRaw, 0)
    local noticeEntry = Codec.DeserializeTurnNoticeEntry(entryRaw)
    if not noticeEntry then return false end

    local store = EnsureStore()
    turnSerial = serial
    -- El asalto viene en el aviso desde que el avance dejo de mandar la foto entera. Un cliente
    -- anterior manda aqui la fase (texto), y `SafeNumber` la deja en 0: se ignora, que es lo que
    -- se quiere -- no bajar el asalto de nadie por recibir un aviso viejo.
    local asaltoRecibido = SafeNumber(adminRaw, 0)
    if asaltoRecibido > 0 then store.asalto = asaltoRecibido end

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
    -- La entrada se lo lleva puesto: `HarfordDnDConditions.OnTurnChanged` lee `entry.asalto` para
    -- bajar las duraciones medidas en asaltos.
    if asaltoRecibido > 0 and type(entry) == "table" then entry.asalto = asaltoRecibido end
    PrintTurnNotice(entry, activeIndex, count, serial)
    AlertRoundStates(entry, activeIndex, serial)
    AlertTurnChanged(entry, activeIndex, serial)
    AlertMyTurn(entry, activeIndex, serial)
    return true
end

-- Recibir el estado de otro cliente NO pasa por `MarkChanged` (seria reenviarlo), asi que el
-- marcador se repinta aparte o se queda con lo del turno anterior.
--
-- Y si el combate se ha ACABADO ahi tambien hay que recoger: quien pulsa Terminar limpia su ficha,
-- no la de los demas. Sin esto solo quedaba limpio el que dio al boton -- al resto se le quedaba el
-- contador de movimiento corriendo y el estandarte del ultimo turno puesto.
local habiaCombate = false
local function RefrescarMarcadorTrasRecibir()
    local hay = HarfordTurnOrderAPI.HasActiveCombat and HarfordTurnOrderAPI.HasActiveCombat()
    if habiaCombate and not hay then
        if Combate and Combate.CleanUpAfterCombat then pcall(Combate.CleanUpAfterCombat) end
    end
    habiaCombate = hay and true or false
    if HarfordTurnOrderAPI.RefreshTurnMarker then HarfordTurnOrderAPI.RefreshTurnMarker() end
end

-- Cuando se vio la ultima foto. Lo mira el relevo entre companeros para no contestar si el DM ya
-- lo hizo.
ULTIMA_FOTO_VISTA = 0

-- LibDeflate viene con EpsilonLib (y con TRP3, y con Epsilon_Book): se registra en LibStub y como
-- global. Se busca en caliente y se tolera que no este -- entonces no se comprime y todo sigue
-- como antes.
local function GetDeflate()
    if LibStub and LibStub.GetLibrary then
        local ok, lib = pcall(LibStub.GetLibrary, LibStub, "LibDeflate", true)
        if ok and lib then return lib end
    end
    return _G.LibDeflate
end

-- Marca de payload comprimido. Un cliente sin actualizar no la reconoce y descarta el mensaje sin
-- romperse: su parser exige que empiece por `STATE`. Se queda sin actualizar la lista, que es lo
-- mismo que le pasa HOY cuando se pierde uno de los doce trozos -- solo que hoy pasa a menudo.
local MARCA_COMPRIMIDO = "Z|"

-- La foto entera son ~2400 bytes de texto muy repetitivo --las mismas rutas de icono, la misma
-- estructura de campos-- y comprime a ~275: de doce mensajes troceados a dos. Importa porque el
-- reensamblado es todo o nada y no hay acuse ni reintento: perder un trozo tira el estado entero.
local function Comprimir(payload)
    local D = GetDeflate()
    if not (D and D.CompressDeflate and D.EncodeForWoWAddonChannel) then return nil end
    local ok, comprimido = pcall(D.CompressDeflate, D, payload, { level = 9 })
    if not ok or not comprimido then return nil end
    local ok2, codificado = pcall(D.EncodeForWoWAddonChannel, D, comprimido)
    if not ok2 or not codificado then return nil end
    -- Si no encoge, no compensa: se manda en claro y lo entiende todo el mundo.
    if #codificado + #MARCA_COMPRIMIDO >= #payload then return nil end
    return MARCA_COMPRIMIDO .. codificado
end

local function Descomprimir(payload)
    if payload:sub(1, #MARCA_COMPRIMIDO) ~= MARCA_COMPRIMIDO then return payload end
    local D = GetDeflate()
    if not (D and D.DecodeForWoWAddonChannel and D.DecompressDeflate) then return nil end
    local ok, bruto = pcall(D.DecodeForWoWAddonChannel, D, payload:sub(#MARCA_COMPRIMIDO + 1))
    if not ok or not bruto then return nil end
    local ok2, texto = pcall(D.DecompressDeflate, D, bruto)
    if not ok2 or not texto then return nil end
    return texto
end

local function ApplySerializedState(message)
    -- Puede venir comprimido: se deshace antes de mirar el opcode. Si no se puede --sin LibDeflate,
    -- o datos corruptos-- se descarta, que es preferible a aplicar medio estado.
    message = Descomprimir(tostring(message or ""))
    if not message then return false end
    local opcode, activeRaw, third, fourth = strsplit("|", message)
    if opcode ~= "STATE" then return false end

    local store = EnsureStore()
    store.entries = {}
    store.activeIndex = SafeNumber(activeRaw, 1)
    -- Solo se acepta la marca si viene en el hueco del modo Y hay un cuarto campo: en el formato
    -- viejo las entradas iban en el tercero y una que empezara por "B" se tomaria por el modo.
    if fourth then
        local modoRaw, dmsRaw, estadoRaw = strsplit("~", tostring(third or ""))
        -- Sin estado en el mensaje (cliente anterior) NO se toca el nuestro: poner nil ahi mataria
        -- un combate en curso cada vez que hablara alguien sin actualizar.
        if estadoRaw ~= nil then
            HarfordTurnOrderAPI.SetCombatState(estadoRaw ~= "" and estadoRaw or nil)
        end
        local listaDms = {}
        for nombre in tostring(dmsRaw or ""):gmatch("[^;]+") do listaDms[#listaDms + 1] = nombre end
        store.dms = (#listaDms > 0) and listaDms or nil
        -- El hueco del modo llega vacio. De un cliente sin actualizar puede venir con contenido, y
        -- se ignora igual: el turno va de criatura en criatura y no hay otro modo que aplicar.
        store.modoBandos = nil
        store.activeBando = nil
        store.faseBando = nil
    end
    local entriesRaw = fourth or third
    if entriesRaw and entriesRaw ~= "" then
        for token in string.gmatch(entriesRaw, "[^;]+") do
            local entry = Codec.DeserializeEntry(token)
            if entry then store.entries[#store.entries + 1] = entry end
        end
    end

    ULTIMA_FOTO_VISTA = (time and time()) or 0
    -- Y se SELLA. Recibir la foto es la unica senal de vida que tiene un jugador que no manda
    -- nada: sin esto su sello se quedaba a nil --"lista de una version anterior", o sea vieja-- y
    -- un `/reload` justo despues de entrar en combate le borraba la pelea en curso. La caducidad
    -- solo mira cuando se toco por ultima vez, y recibirla es tocarla.
    TouchStore()
    ClampActiveIndex()
    EnsureRoundMarker()
    ClampActiveIndex()
    EnsureActiveVisible()
    RefrescarMarcadorTrasRecibir()
    return true
end

local function SendSerializedState(payload, channel, target)
    if #payload <= TURN_SINGLE_MESSAGE_LIMIT then
        return HarfordSync.Send(COMM_PREFIX, payload, channel, target)
    end

    -- Solo cuando NO cabe: por debajo de un mensaje no hay nada que ganar, y mandarlo en claro lo
    -- entiende cualquier cliente. Comprimir arriba cambia doce trozos por dos.
    payload = Comprimir(payload) or payload
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
        return ApplyTurnNotice(message, sender)
    elseif opcode == "TCHUNK" then
        return ApplyChunkedTurnNotice(message, sender)
    elseif opcode == "TSTART" then
        local _, cuantos = strsplit("|", message or "")
        AnnounceCombatStart(SafeNumber(cuantos, 0))
        return true
    elseif opcode == "TREQ" then
        -- Solo el DM tiene la foto buena. Si hay varios, contestan todos: la foto es la misma y
        -- aplicarla dos veces no cambia nada, a diferencia de los estados de NPC, donde la lista
        -- SUSTITUYE y por eso alli si hizo falta desempate.
        if not (sender and sender ~= "") then return true end
        if IsTurnAdmin() then SendStateTo(sender) return true end
        -- Y si el DM se ha caido, no contesta NADIE y quien entra se queda sin combate. Un
        -- companero tiene la misma foto --se la mandaron a el igual-- asi que puede servirla,
        -- pero DESPUES de esperar: la del DM es la buena y tiene que llegar primero si esta.
        --
        -- No se responde si desde entonces ha pasado una foto por el canal: eso significa que
        -- alguien con mas derecho ya contesto.
        if not HarfordTurnOrderAPI.HasCombatants() then return true end
        local pedido = (time and time()) or 0
        if C_Timer and C_Timer.After then
            C_Timer.After(5, function()
                if (ULTIMA_FOTO_VISTA or 0) >= pedido then return end
                SendStateTo(sender, true)
            end)
        end
        return true
    elseif opcode == "TJOIN" then
        -- Alguien entra en el combate en curso. Se mete SOLO, sin que el DM tenga que aceptar
        -- nada: al DM se le avisa y ya. Pasa por el porque la lista es suya --una entrada anadida
        -- en local desapareceria con la siguiente foto--, no porque haya que pedirle permiso.
        if not IsTurnAdmin() then return true end
        if HarfordTurnOrderAPI.GetCombatState() ~= "activo" then
            Print(tostring(sender) .. " pide unirse, pero no hay combate empezado.")
            return true
        end
        local unidad = HarfordClassColors and HarfordClassColors.FindUnitByName
            and HarfordClassColors.FindUnitByName(sender)
        if not unidad then
            Print("|cffff5555" .. tostring(sender) .. " pide unirse|r pero no lo veo: metelo a mano.")
            return true
        end
        -- Al bloque de PJs, que es donde va un jugador se ponga donde se ponga.
        local store = EnsureStore()
        for _, e in ipairs(store.entries) do
            if tostring(e.kind or "") == "players" then
                local ok, err = HarfordTurnOrderAPI.AddBlockMember(e, unidad)
                Print(ok and ("|cff88ff88" .. tostring(sender) .. " se une al combate.|r")
                    or (tostring(sender) .. " no se pudo unir: " .. tostring(err)))
                -- La foto se manda por el camino normal (`MarkChanged` la programa): llamar aqui
                -- a `SendState` seria usarla antes de declararla.
                if ok then MarkChanged() end
                return true
            end
        end
        Print("|cffff5555" .. tostring(sender) .. " pide unirse|r pero no hay bloque de PJs.")
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
-- `comoPar`: la manda alguien que NO es DM, porque el DM no contesto. Es el unico caso en que se
-- permite; el resto de la vida la foto la sirve quien manda.
SendStateTo = function(target, comoPar)
    if not comoPar and not IsTurnAdmin() then return false end
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

-- Aviso de que empieza el combate. Es de un solo uso y no lleva estado: la lista va aparte, en la
-- foto, y esto solo abre la ventana y lo dice.
local function SendCombatStart(combatientes)
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not ch then return false end
    return HarfordSync.Send(COMM_PREFIX, "TSTART|" .. tostring(math.floor(tonumber(combatientes) or 0)), ch)
end

AnnounceCombatStart = function(combatientes)
    local texto = "COMIENZA EL COMBATE"
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, texto, ChatTypeInfo and ChatTypeInfo["RAID_WARNING"])
    end
    if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
    Print("|cffffff00" .. texto .. ".|r " .. tostring(combatientes) .. " combatiente(s) en la lista.")
    -- Y se abre la ventana: estar en turnos sin verlos es peor que no estar.
    if TurnFrame and not TurnFrame:IsShown() then TurnFrame:Show() end
    if RefreshFrame then RefreshFrame() end
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

local MarcarLocal

-- Cambio LOCAL: se apunta y se repinta, pero no se manda la foto. Para lo que el aviso de turno
-- ya cuenta por su cuenta -- avanzar y retroceder --, donde mandarla ademas era repetir con 12
-- mensajes lo que ya iba en uno.
MarcarLocal = function()
    TouchStore()
    RepintarProtegido(RefreshFrame)
    RepintarProtegido(HarfordTurnOrderAPI.RefreshTurnMarker)
end

MarkChanged = function()
    TouchStore()
    -- LA DIFUSION VA PRIMERO, Y LOS REPINTADOS PROTEGIDOS. Estaban antes y sin `pcall`: si
    -- cualquiera de los dos petaba --y repintar toca muchos frames-- la funcion moria ahi y
    -- `ScheduleBroadcast` no llegaba a correr NUNCA. La mesa dejaba de recibir el estado entero
    -- por un fallo de dibujo, y en el otro cliente eso no se ve como un error: se ve como que el
    -- addon del DM ha dejado de hablar.
    ScheduleBroadcast()
    RepintarProtegido(RefreshFrame)
    -- El marcador tambien: iniciar y terminar el combate no son cambios de TURNO, asi que no
    -- pasan por `AlertTurnChanged` y se quedaria puesto despues de terminar.
    RepintarProtegido(HarfordTurnOrderAPI.RefreshTurnMarker)
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
    -- Se calcula aqui porque depende de la fuente de TRP3, pero quien la usa es el modulo de la
    -- ficha. Escribirla sin pasarsela creaba una global que su propio local tapaba: le llegaba nil
    -- y `SetHeight(nil)` reventaba al abrir cualquier ficha con secciones.
    local alto = math.max(28, math.ceil(bodySize * 2.4))
    if Ficha.SetSectionHeaderHeight then Ficha.SetSectionHeaderHeight(alto) end
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

-- Pinta una tarjeta a partir de su entrada. La usan la ventana de turnos Y la lista de miembros
-- de un bloque en HarfordAdmin: si cada una pintara la suya, se irian separando con cada cambio.
local function PaintEntryCard(card, entry, isAdmin)
    if not (card and entry) then return end
    card.name:SetText(entry.name or "Sin nombre")
    if entry.kind == "round" then
        card.name:SetTextColor(GetEntryNameColor(entry))
        -- La tarjeta del marcador dice el asalto y nada mas: "ESTADOS" pedia un repaso a
        -- mano que ya no existe -- cada estado caduca solo, en el turno de su dueno.
        card.init:SetText("")
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
            card.armorClass:SetEnabled(isAdmin and true or false)
        end
        local hp, maxHp, tempHp = GetEntryResourceValues(entry)
        card.hp:Show()
        UpdateSmallBar(card.hp, card.hpText, hp, maxHp, 0.78, 0.05, 0.08, tempHp)
    end
    SetEntryPortrait(card.icon, entry)
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
    -- Los miembros de un bloque tambien llevan vida, y no tienen tarjeta propia: si no se
    -- actualizan aqui, la suya se queda con la del momento en que se les metio.
    local function Aplicar(lista)
        for _, e in ipairs(lista or {}) do
            if e and e.kind ~= "round" and e.kind ~= "player"
                and tostring(e.guid or e.id or "") == guid then
                local h = SafeNumber(hp, e.hp or 0)
                local m = SafeNumber(maxHp, e.maxHp or h)
                if SafeNumber(e.hp, 0) ~= h or SafeNumber(e.maxHp, 0) ~= m then
                    e.hp, e.maxHp = h, m
                    changed = true
                end
            end
        end
    end
    for _, entry in ipairs(store.entries or {}) do
        Aplicar(entry.miembros)
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

    return changed, guid, hp, maxHp
end

-- La vida de un NPC va SOLA por el cable, no dentro de la foto entera. `UNIT_HEALTH` dispara en
-- rafaga durante un combate, y cada una difundia los 2400 bytes de la lista completa --doce
-- mensajes troceados-- para cambiar un numero. Con esto es uno.
local envioVidaPendiente
local function EnviarVidaNpc(guid, hp, maxHp)
    if not IsTurnAdmin() then return false end
    if not (guid and guid ~= "") then return false end
    if envioVidaPendiente then return false end
    envioVidaPendiente = true
    local function mandar()
        envioVidaPendiente = nil
        local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
        if not ch then return end
        HarfordSync.Send(COMM_PREFIX, table.concat({ "THP", tostring(guid),
            tostring(SafeNumber(hp, 0)), tostring(SafeNumber(maxHp, 0)) }, "|"), ch)
    end
    -- Mismo aplazamiento que la foto: una rafaga de golpes se resume en un envio.
    if C_Timer and C_Timer.After then C_Timer.After(0.15, mandar) else mandar() end
    return true
end

RefreshFrame = function()
    if not TurnFrame then return end
    if not TurnFrame:IsShown() then return end
    -- Los controles que anade HarfordAdmin se repintan solos si se registraron con
    -- `RegisterAdminControl`; el core no sabe lo que son.
    for _, extra in ipairs(TurnFrame.adminExtras or {}) do
        if extra.Refrescar then extra.Refrescar() end
    end
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
    -- `Unirse` ocupa el sitio de `Limpiar`, que es de DM: nunca se ven los dos. Solo aparece si hay
    -- combate empezado y tu no estas dentro -- si ya estas, no hay nada que pedir.
    if TurnFrame.joinButton then
        TurnFrame.joinButton:SetShown(not isAdmin
            and HarfordTurnOrderAPI.HasActiveCombat()
            and not HarfordTurnOrderAPI.AmIInCombat())
    end

    for i = 1, MAX_CARDS do
        local card = TurnFrame.cards[i]
        local entryIndex = displayStart + i - 1
        local entry = store.entries[entryIndex]
        if entry then
            RefreshPlayerEntryTRP3Meta(entry)
            card.entryIndex = entryIndex
            card:Show()
            PaintEntryCard(card, entry, isAdmin)
            -- El marco de OBJETIVO. Se llama aqui y no dentro del pintor porque depende de a quien
            -- tengas seleccionado TU, que es del cliente y no de la entrada: la lista de un bloque
            -- pinta las mismas tarjetas y ahi no aplica.
            SetCardTargetState(card, IsEntryCurrentTarget(entry))
            local esActiva = (entryIndex == store.activeIndex)
            if esActiva then
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
    -- Montar la mesa es PREPARAR. Sirve para distinguir "hay gente puesta pero no hemos empezado"
    -- de "no hay nada", que es lo que antes no se podia decir. No pisa un combate ya empezado.
    if HarfordTurnOrderAPI.GetCombatState() == nil then
        HarfordTurnOrderAPI.SetCombatState("preparando")
    end
    ClampActiveIndex()
    MarkChanged()
    return true
end

local function CapturarUnidadDeTurno(unit, kind)
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

    return name, hp, maxHp, entryKind, guid, mana, maxMana, fullName,
        trp.icon or GetFallbackCreatureIcon(unit), displayId, {
        npcId = trp.npcId,
        phaseId = trp.phaseId,
        trpFullID = trp.trpFullID,
        trpUnitID = trp.trpUnitID,
        trpProfileID = trp.trpProfileID,
        reaction = reaction,
        nameColor = trp.nameColor,
        armorClass = armorClass,
    }
end

local function AddUnit(unit, kind)
    if not UnitExists(unit) then Print("No hay unidad valida seleccionada.") return end
    AddEntry(CapturarUnidadDeTurno(unit, kind))
    if HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName and UnitIsPlayer and UnitIsPlayer(unit) then
        HarfordDnDAPI.RequestResourcesForName((GetUnitName and GetUnitName(unit, true)) or UnitName(unit))
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

-- El objetivo de una operacion de tarjeta puede venir como posicion en la lista o como la entrada
-- misma. Un miembro de bloque NO esta en `store.entries`, asi que por posicion no hay forma de
-- alcanzarlo -- y es una tarjeta igual que las demas.
local function EntradaDe(objetivo)
    if type(objetivo) == "table" then return objetivo end
    return EnsureStore().entries[objetivo]
end

local function AdjustHp(index, amount)
    if not IsTurnAdmin() then Print("Solo el admin puede modificar vida.") return end
    ClaimAdminIfNeeded()
    local entry = EntradaDe(index)
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

    local Cond = HarfordDnDConditions
    if not (Cond and Cond.AplicarEfectoNpc) then
        Print("No puedo modificar la vida del NPC: falta el motor de condiciones.")
        return
    end

    -- Un punto unico: si soy oficial lo emite, y si no lo manda al lider para que lo emita el.
    -- El signo es el del comando -- negativo resta --, que es el mismo que ya trae `amount`.
    local via = Cond.AplicarEfectoNpc(entry.id, amount < 0 and "damage" or "heal",
        math.abs(amount), "target")
    if not via then
        Print("No se pudo modificar la vida del NPC, y no hay lider a quien pedirselo.")
        return
    end
    if via == "delegado" then
        Print(string.format("%d de %s enviado al lider: se aplicara cuando tenga a %s seleccionado.",
            math.abs(amount), amount < 0 and "dano" or "curacion", tostring(entry.name or "el NPC")))
    end

    local maxHp = SafeNumber(entry.maxHp, 0)
    if amount < 0 and SafeNumber(entry.tempHp, 0) > 0 then
        local absorb = math.min(SafeNumber(entry.tempHp, 0), math.abs(amount))
        entry.tempHp = math.max(0, SafeNumber(entry.tempHp, 0) - absorb)
        amount = amount + absorb
    end
    if amount ~= 0 then
        local nuevo = math.max(0, SafeNumber(entry.hp, 0) + amount)
        -- El tope SOLO si se conoce: sin maximo, `math.min(hp + amount, 0)` dejaba al NPC en 0 de
        -- un clic -- tambien curandolo -- y el cero se difundia a toda la mesa.
        if maxHp > 0 then nuevo = math.min(nuevo, maxHp) end
        entry.hp = nuevo
    end
    MarkChanged()
end

local function PromptAdjustHp(index, direction)
    direction = tonumber(direction) or 1
    direction = direction < 0 and -1 or 1

    local entry = EntradaDe(index)
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
    local entry = EntradaDe(index)
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
    local entry = EntradaDe(index)
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
local function NextTurn()
    if not IsTurnAdmin() then Print("Solo el admin puede avanzar turnos.") return end
    if OtroDMAcabaDeAvanzar() then return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    EnsureRoundMarker()
    if #store.entries == 0 then return end

    store.activeIndex = store.activeIndex + 1
    ClampActiveIndex()
    EnsureActiveVisible()
    local turnSerial = AdvanceTurnSerial()
    -- Pasar por el marcador es haber dado la vuelta: ahi sube el asalto. Lo llevaba el modo por
    -- bloques, que era el unico sitio donde se contaba, asi que al retirarlo habria dejado de
    -- contarse -- y las duraciones por asaltos dependen de esta cuenta.
    local activa = store.entries[store.activeIndex]
    if activa and activa.kind == "round" then
        store.asalto = (tonumber(store.asalto) or 0) + 1
        activa.asalto = store.asalto
        Print("|cffffff00Asalto " .. tostring(store.asalto) .. "|r")
    end
    -- SIN mandar la foto: el aviso de turno lleva serial, indice, asalto y la entrada, que es todo
    -- lo que el receptor necesita para avanzar. La lista no ha cambiado. Mandarla igual eran 12
    -- mensajes troceados por pulsacion, y basta con perder UNO para que el receptor descarte el
    -- estado entero en silencio -- no hay acuse ni reintento.
    MarcarLocal()
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

    store.activeIndex = store.activeIndex - 1
    ClampActiveIndex()
    EnsureActiveVisible()
    local turnSerial = AdvanceTurnSerial()
    MarcarLocal()
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
-- Las PIEZAS visuales de una tarjeta, sin los controles de la ventana de turnos (mover, quitar,
-- +/-). Se expone para que la lista de miembros de un bloque monte las MISMAS, en vez de una
-- imitacion que se desvia en cuanto se toca cualquiera de las dos.
local function CreateCardVisuals(parent, Objetivo)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    SetFrameBackground(card)
    -- A que apunta esta tarjeta. Por defecto, a su posicion en la lista de turnos.
    Objetivo = Objetivo or function() return card.entryIndex end

    card.border = CreateFrame("Frame", nil, card, "DialogBorderTemplate")
    card.border:SetAllPoints(card)
    card.border:SetFrameStrata(card:GetFrameStrata())
    card.border:SetFrameLevel(card:GetFrameLevel() + 3)

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
        PromptSetArmorClass(Objetivo())
    end)
    card.armorClass:Hide()

    -- Shift para escribir la cantidad; sin Shift, de uno en uno. Es el gesto que ya tenian las
    -- tarjetas de la ventana de turnos.
    card.minus = MakeButton(card, "-", 18, 16, "BOTTOMLEFT", card, "BOTTOMLEFT", 5, 4, function()
        if IsShiftKeyDown and IsShiftKeyDown() then PromptAdjustHp(Objetivo(), -1)
        else AdjustHp(Objetivo(), -1) end
    end)
    card.plus = MakeButton(card, "+", 18, 16, "BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 4, function()
        if IsShiftKeyDown and IsShiftKeyDown() then PromptAdjustHp(Objetivo(), 1)
        else AdjustHp(Objetivo(), 1) end
    end)
    card.minus:Hide()
    card.plus:Hide()

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

    -- El marco de OBJETIVO es de la tarjeta, no de la ventana de turnos. Vivia en `CreateCard`,
    -- asi que las tarjetas de la lista de un bloque no lo tenian -- y `SetCardTargetState`
    -- comprueba `if card.targetTop then`, asi que no fallaba: no hacia nada, en silencio.
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


    card.targetText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.targetText:SetPoint("BOTTOM", 0, 20)
    card.targetText:SetText("OBJETIVO")
    card.targetText:SetTextColor(0.05, 0.85, 1.0)
    card.targetText:Hide()
    return card
end

local function CreateCard(parent, index)
    local card
    card = CreateCardVisuals(parent, function()
        return (card and card.entryIndex) or index
    end)
    card:SetPoint("TOPLEFT", 18 + (index - 1) * (CARD_W + CARD_GAP), -78)
    card:EnableMouse(true)
    card:SetScript("OnMouseUp", function(self, button)
        local store = EnsureStore()
        local entryIndex = self.entryIndex or index
        if button == "RightButton" then
            -- El core no abre menus de DM: expone el gesto y HarfordAdmin decide. Sin Admin
            -- cargado no pasa nada, que es lo correcto.
            HarfordTurnOrderAPI.OnCardRightClick(store.entries[entryIndex], self)
            return
        end
        if button ~= "LeftButton" then return end
        if editMode then
            ClickEditEntry(entryIndex)
            return
        end
        local entry = store.entries[entryIndex]
        -- Si nadie se lo queda, lo de siempre: la ficha de la entrada.
        if AlguienSeQuedaElClick(entry) then return end
        -- Salvo un BLOQUE, que abre su lista. La abre CUALQUIERA: mirar quien esta dentro es
        -- informacion, no una herramienta de DM; editarla si lo es, y eso lo aporta Admin.
        if HarfordTurnOrderAPI.OpenBlockPanel(entry) then return end
        Ficha.ShowEntrySheet(entry)
    end)

    card.active = card:CreateTexture(nil, "OVERLAY")
    card.active:SetTexture(TEX_WHITE)
    card.active:SetVertexColor(1.0, 0.78, 0.20, 0.28)
    card.active:SetAllPoints(card)

    card.reorder = card:CreateTexture(nil, "OVERLAY")
    card.reorder:SetTexture(TEX_WHITE)
    card.reorder:SetVertexColor(0.65, 0.25, 1.0, 0.32)
    card.reorder:SetAllPoints(card)
    card.reorder:Hide()

    card.turn = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    card.turn:SetPoint("BOTTOM", 0, 7)


    -- Reordenar es SOLO de la ventana de turnos: mueve la entrada dentro de `store.entries`, y un
    -- miembro de bloque no vive ahi. Por eso estos dos no van en el constructor comun.
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

-- Se declara AQUI, no junto a su API mil lineas mas abajo: `CreateTurnFrame` la recorre, y una
-- local declarada despues de usarse se compila como lectura de GLOBAL -- o sea nil --, asi que
-- `ipairs(nil or {})` no recorria nada y los avisos de "ventana creada" no se disparaban NUNCA.
-- No da error: simplemente no pasa.
local alCrearVentana = {}

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
    -- Se recuerda si estaba abierta. Un `/reload` a media pelea la cerraba y habia que volver a
    -- abrirla a mano: la ventana solo se muestra sola al INICIAR el combate, y eso ya habia
    -- pasado. Se apunta en el propio store, que es SavedVariable.
    TurnFrame:HookScript("OnShow", function()
        local store = HarfordTurnOrderStore
        if type(store) == "table" then store.ventanaAbierta = true end
    end)
    -- Y NO se usa `OnHide`: al recargar o salir, WoW oculta todos los frames, asi que la marca se
    -- borraba justo antes de guardar y al volver la ventana siempre parecia cerrada. Solo cuenta
    -- que la cierre el JUGADOR, y eso son dos gestos concretos: la X y el comando.
    local function Cerrada()
        local store = HarfordTurnOrderStore
        if type(store) == "table" then store.ventanaAbierta = nil end
    end
    TurnFrame.MarcarCerrada = Cerrada
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
    close:HookScript("OnClick", Cerrada)

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
    -- Con el resto de controles de admin: si no, un jugador normal ve un boton suelto flotando
    -- en una ventana sin controles, y al pulsarlo solo le dicen que no puede.
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

    -- Para el que NO esta en la pelea: pide entrar. Se sale FUERA de combate por defecto --nadie
    -- entra solo porque haya un combate en su raid-- y este boton es la unica via, que ademas la
    -- decide el DM: la lista es suya, y una entrada anadida en local desapareceria con la foto
    -- siguiente.
    TurnFrame.joinButton = MakeButton(TurnFrame, "Unirse", 62, 22, "BOTTOMRIGHT", TurnFrame,
        "BOTTOMRIGHT", -18, 10, function()
        local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
        if not ch then Print("No hay grupo al que pedirselo.") return end
        HarfordSync.Send(COMM_PREFIX, "TJOIN|"
            .. tostring((GetUnitName and GetUnitName("player", true)) or ""), ch)
        Print("Te unes al combate.")
    end)
    TurnFrame.joinButton:Hide()

    local clearButton = MakeButton(TurnFrame, "Limpiar", 62, 22, "BOTTOMRIGHT", TurnFrame, "BOTTOMRIGHT", -18, 10, function()
        if not IsTurnAdmin() then Print("Solo el admin puede limpiar turnos.") return end
        ClaimAdminIfNeeded()
        local store = EnsureStore()
        store.entries = {}
        store.activeIndex = 1
        -- Vaciar la mesa es ademas salir del combate: si no, quedaria un combate "activo" sin
        -- nadie dentro. Terminar y limpiar son distintos, pero limpiar implica terminar.
        HarfordTurnOrderAPI.SetCombatState(nil)
        store.asalto = nil
        store.activeBando = nil
        store.faseBando = nil
        EnsureRoundMarker()
        if Combate and Combate.CleanUpAfterCombat then pcall(Combate.CleanUpAfterCombat) end
        MarkChanged()
    end)
    tinsert(TurnFrame.adminControls, clearButton)

    TurnFrame.cards = {}
    for i = 1, MAX_CARDS do
        TurnFrame.cards[i] = CreateCard(TurnFrame, i)
    end
    UpdateEditButton()
    RefreshFrame()
    -- Ya existe: quien esperaba para colgar sus controles puede hacerlo.
    for _, fn in ipairs(alCrearVentana or {}) do pcall(fn) end
end

local function ToggleFrame()
    if not TurnFrame then CreateTurnFrame() end
    TurnFrame:SetShown(not TurnFrame:IsShown())
    if TurnFrame:IsShown() then RefreshFrame()
    elseif TurnFrame.MarcarCerrada then TurnFrame.MarcarCerrada() end
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
        -- Y se reabre si estaba abierta, pero solo si queda algo que enseniar: reabrirla vacia
        -- despues de que la caducidad se llevara el combate seria un frame en blanco.
        if HarfordTurnOrderStore.ventanaAbierta and HarfordTurnOrderAPI.HasCombatants() then
            -- La ventana se crea al abrirla por primera vez, asi que aqui todavia no existe.
            if not TurnFrame then CreateTurnFrame() end
            TurnFrame:Show()
            if RefreshFrame then RefreshFrame() end
        end
        -- La limpieza espera a que la peticion de foto haya tenido su oportunidad: purgar al
        -- instante tiraba el combate ANTES de preguntar si seguia vivo, y luego lo recuperaba --o
        -- no-- por los pelos. Si en ese rato llega una foto, no hay nada que limpiar.
        if C_Timer and C_Timer.After then
            local alEntrar = (time and time()) or 0
            C_Timer.After(12, function()
                if (ULTIMA_FOTO_VISTA or 0) >= alEntrar then return end
                if PurgeStaleEntries() then
                    Print("|cff808080Se retiro un combate abandonado.|r")
                end
            end)
        else
            PurgeStaleEntries()
        end
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
        local cambio, guid, hp, maxHp = RefreshTargetNpcHealthFromUnit("target")
        if cambio then
            MarcarLocal()
            EnviarVidaNpc(guid, hp, maxHp)
            return
        end
        if RefreshFrame then RefreshFrame() end
        return
    end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        -- Solo interesa el HP del target (NPC trackeado). Cambios de HP de otras
        -- unidades no modifican el estado de los turnos -> no hacer RefreshFrame.
        if unit == "target" then
            local cambio, guid, hp, maxHp = RefreshTargetNpcHealthFromUnit("target")
            if cambio then
                MarcarLocal()
                EnviarVidaNpc(guid, hp, maxHp)
            end
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
        -- Faltaba: se usa en tres sitios de la ficha y resolvia a nil, asi que abrir la ficha de
        -- una entrada reventaba.
        Codec = Codec,
        TEX_WHITE = TEX_WHITE,
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
        AnnounceCombatStart = AnnounceCombatStart,
        SendCombatStart = SendCombatStart,
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
        -- Fuera SOLO el marcador de asalto: sin filtrarlo caia por reaccion 0 en "enemigos" y ese
        -- bando no parecia vacio nunca. `IsSystemEntry` no vale aqui porque tambien tapa `players`
        -- y `generic`, que son justo los bloques.
        if tostring(entry.kind or "") ~= "round"
            and HarfordTurnOrderAPI.GetBando(entry) == bando then
            fuera[#fuera + 1] = entry
            -- Y quien va DENTRO del bloque: no tienen tarjeta, pero les toca el turno igual y sus
            -- contadores bajan con el suyo.
            for _, m in ipairs(entry.miembros or {}) do
                fuera[#fuera + 1] = { id = m.guid, guid = m.guid, name = m.name, kind = "npc" }
            end
        end
    end
    return fuera
end

-- ─── PUERTAS PARA HarfordAdmin ──────────────────────────────────────────────
-- El core no tiene UI de DM: expone gestos y sitios donde colgar controles, y HarfordAdmin los
-- rellena en su PLAYER_LOGIN. Es el patron de `HarfordTRP3.InsertGlanceLink`. Sin HarfordAdmin
-- cargado no aparece nada, que es justo la regla de carga del proyecto.

-- Click derecho sobre una tarjeta. Por defecto no hace nada.
-- Una tarjeta, montada y pintada por el core. La lista de miembros de un bloque (HarfordAdmin) usa
-- estas dos y no una copia: si cada una pintara la suya, se irian separando con cada cambio, que es
-- justo lo que paso al montar la lista por primera vez.
-- `.ph dm on` no dispara ningun evento de WoW: sin esto, la ventana seguia en modo jugador hasta
-- que la cerrabas y la volvias a abrir. Los controles de DM se deciden en cada refresco, asi que
-- basta con refrescar cuando cambia la autoridad.
if HarfordAuthority and HarfordAuthority.RegisterChangeListener then
    HarfordAuthority.RegisterChangeListener("HarfordTurns", function()
        if TurnFrame and TurnFrame:IsShown() and RefreshFrame then RefreshFrame() end
        -- Y la lista de un bloque, que tiene sus propios controles de DM colgados: sin esto,
        -- ponerse `.ph dm` con la lista abierta no hacia aparecer los botones.
        if HarfordTurnOrderAPI.RefreshBlockPanel then HarfordTurnOrderAPI.RefreshBlockPanel() end
    end)
end

-- ─── EL MARCADOR DE TURNO ───────────────────────────────────────────────────
-- Una ventanita que se QUEDA, con de quien es el turno y por que asalto vamos. El estandarte pasa
-- en cuatro segundos; esto contesta la misma pregunta cinco minutos despues, que es cuando se hace
-- de verdad -- hasta ahora esa informacion vivia solo en la ventana de turnos, que nadie tiene
-- abierta todo el rato.
--
-- Arte NATIVO: `AllianceScenario-TrackerHeader` / `HordeScenario-TrackerHeader` (243x77), la misma
-- cabecera que usa el juego para los escenarios y que DiceMaster usa para lo mismo que esto.
--
-- Va en un `do...end` (el fichero ronda los 140 locales y el limite de Lua 5.1 es 200) y SIN
-- ticker: se repinta cuando cambia el turno, que es la unica vez que cambia lo que dice.
do
    local marcador
    local PintarRecursos

    local function Activo()
        if HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("turnmarker") == "off" then
            return false
        end
        return HarfordTurnOrderAPI.HasActiveCombat()
    end

    local function Crear()
        if marcador then return marcador end
        marcador = CreateFrame("Frame", "HarfordTurnMarkerFrame", UIParent)
        -- Mas alto que el atlas (243x77): debajo del turno van la barra de movimiento y las
        -- fichas de economia, que antes vivian sueltas encima de la barra de accion.
        marcador:SetSize(243, 96)
        marcador:SetPoint("TOP", UIParent, "TOP", 0, -18)
        -- MEDIUM, no DIALOG: se queda en pantalla y no puede ponerse por delante de una ventana.
        marcador:SetFrameStrata("MEDIUM")
        marcador:SetFrameLevel(60)
        marcador:SetClampedToScreen(true)
        marcador:SetMovable(true)
        marcador:EnableMouse(true)
        marcador:RegisterForDrag("LeftButton")
        marcador:SetScript("OnDragStart", marcador.StartMoving)
        marcador:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            self:SetUserPlaced(true)
        end)
        marcador:SetUserPlaced(true)

        marcador.fondo = marcador:CreateTexture(nil, "BACKGROUND")
        -- Por faccion, como el nativo. Si la sonda no lo encuentra no se pinta nada: un atlas que
        -- falta deja la textura anterior, no la borra.
        local faccion = (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance"
        local nombre = (faccion == "Horde") and "HordeScenario-TrackerHeader"
            or "AllianceScenario-TrackerHeader"
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(nombre) then
            marcador.fondo:SetAtlas(nombre, true)
            marcador.fondo:SetPoint("CENTER")
        end

        marcador.titulo = marcador:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
        marcador.titulo:SetPoint("TOPLEFT", marcador, "TOPLEFT", 14, -16)
        marcador.titulo:SetWidth(150)
        marcador.titulo:SetJustifyH("LEFT")
        marcador.titulo:SetMaxLines(1)

        marcador.asalto = marcador:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall2")
        marcador.asalto:SetPoint("TOPRIGHT", marcador, "TOPRIGHT", -14, -16)
        marcador.asalto:SetJustifyH("RIGHT")

        marcador.detalle = marcador:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        marcador.detalle:SetPoint("TOPLEFT", marcador.titulo, "BOTTOMLEFT", 0, -2)
        marcador.detalle:SetWidth(210)
        marcador.detalle:SetJustifyH("LEFT")
        marcador.detalle:SetTextColor(0.75, 0.72, 0.62)

        -- Barra de movimiento. Click IZQUIERDO: vuelves a donde empezaste el turno y el contador
        -- se pone a cero. Es lo que quieres cuando te has colocado mal, y no tenia gesto.
        marcador.mov = CreateFrame("Button", nil, marcador)
        marcador.mov:SetHeight(12)
        -- Mas adentro que el titulo: el marco del castbar sobresale 23 px por cada lado.
        marcador.mov:SetPoint("TOPLEFT", marcador, "TOPLEFT", 32, -46)
        marcador.mov:SetPoint("RIGHT", marcador, "RIGHT", -32, 0)
        marcador.mov.barra = CreateFrame("StatusBar", nil, marcador.mov)
        marcador.mov.barra:SetAllPoints()
        marcador.mov.barra:SetStatusBarTexture(
            (not GetFileIDFromPath or GetFileIDFromPath("Interface\\CastingBar\\UI-CastingBar-Fill"))
            and "Interface\\CastingBar\\UI-CastingBar-Fill"
            or "Interface\\TargetingFrame\\UI-StatusBar")
        marcador.mov.barra:SetMinMaxValues(0, 1)
        marcador.mov.fondo = marcador.mov.barra:CreateTexture(nil, "BACKGROUND")
        marcador.mov.fondo:SetAllPoints()
        marcador.mov.fondo:SetColorTexture(0, 0, 0, 0.6)
        -- Marco de barra de lanzamiento. Se estira a lo ancho, que es lo que hace el propio juego
        -- cuando la barra crece; los desplazamientos son los del `CastingBarFrame` nativo, en
        -- proporcion a nuestra altura. Se comprueba que la textura EXISTA: una que falta no borra
        -- la anterior, la deja como estaba, y aqui quedaria un rectangulo con arte de otra cosa.
        local RUTA_MARCO = "Interface\\CastingBar\\UI-CastingBar-Border"
        if not GetFileIDFromPath or GetFileIDFromPath(RUTA_MARCO) then
            -- El marco va en su PROPIO frame, con nivel por encima del de la barra. Como textura
            -- del boton se quedaba debajo: un frame hijo (la barra) se dibuja siempre sobre las
            -- texturas de su padre, por mucho `OVERLAY` que se le ponga.
            marcador.mov.marcoFrame = CreateFrame("Frame", nil, marcador.mov)
            marcador.mov.marcoFrame:SetAllPoints()
            marcador.mov.marcoFrame:SetFrameLevel(marcador.mov.barra:GetFrameLevel() + 2)
            marcador.mov.marco = marcador.mov.marcoFrame:CreateTexture(nil, "OVERLAY")
            marcador.mov.marco:SetTexture(RUTA_MARCO)
            marcador.mov.marco:SetPoint("TOPLEFT", marcador.mov, "TOPLEFT", -23, 19)
            marcador.mov.marco:SetPoint("BOTTOMRIGHT", marcador.mov, "BOTTOMRIGHT", 23, -18)
        end
        local RUTA_FONDO = "Interface\\CastingBar\\UI-CastingBar-Background"
        if not GetFileIDFromPath or GetFileIDFromPath(RUTA_FONDO) then
            marcador.mov.fondo:SetTexture(RUTA_FONDO)
            marcador.mov.fondo:SetVertexColor(1, 1, 1, 1)
        end
        -- Y el numero por encima del marco, que si no lo tapa el adorno de los extremos.
        marcador.mov.texto = (marcador.mov.marcoFrame or marcador.mov.barra):CreateFontString(
            nil, "OVERLAY", "GameFontHighlightSmall")
        marcador.mov.texto:SetPoint("CENTER", marcador.mov, "CENTER", 0, 0)
        marcador.mov:SetScript("OnClick", function()
            if HarfordDnDAttackUI and HarfordDnDAttackUI.ReturnToTurnStart then
                HarfordDnDAttackUI.ReturnToTurnStart()
            end
        end)
        marcador.mov:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine("Movimiento", 1, 1, 1)
            GameTooltip:AddLine("Click: vuelves a donde empezaste el turno.", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        marcador.mov:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

        -- Las fichas de accion, adicional y reaccion. Una por punto de presupuesto: un Impetu de
        -- Accion se ve como dos, que es lo que hace que se lean de un vistazo.
        marcador.fichas = {}

        marcador:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine("Turno de combate", 1, 1, 1)
            GameTooltip:AddLine("Arrastra para moverlo.", 0.7, 0.7, 0.7)
            GameTooltip:AddLine("Se apaga con /harford config turnmarker off", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
        marcador:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        marcador:Hide()
        return marcador
    end

    local COLOR_FICHA = {
        action   = { 0.36, 0.74, 0.36 },   -- verde, los mismos que BG3 y que la barra de accion
        bonus    = { 0.62, 0.42, 0.24 },   -- marron
        reaction = { 0.62, 0.36, 0.80 },   -- morado
    }

    -- Barra de movimiento y fichas de economia. Solo tienen sentido si TU estas en el combate:
    -- `Turn.IsActive` ya lo mira, asi que no hay que repetirlo aqui.
    PintarRecursos = function()
        local U = HarfordDnDAttackUI
        local tope = (U and U.GetTurnMovementMax and U.GetTurnMovementMax()) or 0
        local T = HarfordDnDConditions and HarfordDnDConditions.Turn
        local activa = T and T.IsActive and T.IsActive()

        if activa and tope > 0 then
            local gastado = (U.GetRecordedMovementMeters and U.GetRecordedMovementMeters()) or 0
            local quedan = math.max(0, tope - gastado)
            local fraccion = quedan / tope
            marcador.mov.barra:SetValue(fraccion)
            -- Verde mientras te queda, ambar en el ultimo tercio y roja al agotarse, que es cuando
            -- el muro te devuelve a donde se te acabo.
            if fraccion <= 0.001 then marcador.mov.barra:SetStatusBarColor(0.75, 0.25, 0.25)
            elseif fraccion < 0.34 then marcador.mov.barra:SetStatusBarColor(0.90, 0.68, 0.25)
            else marcador.mov.barra:SetStatusBarColor(0.35, 0.72, 0.40) end
            -- De QUIEN es el movimiento. Llevando un NPC son SUS metros, y ensenar "9.0 m" a
            -- secas hace creer que son los tuyos.
            local dueno = U.GetTurnMovementOwner and U.GetTurnMovementOwner()
            marcador.mov.texto:SetText(dueno
                and string.format("%s  %.1f m", tostring(dueno), quedan)
                or string.format("%.1f m", quedan))
            marcador.mov:Show()
        else
            marcador.mov:Hide()
        end

        local n = 0
        if activa then
            for _, tipo in ipairs(T.ORDEN or {}) do
                local total, quedan = T.GetBudget(tipo), T.GetRemaining(tipo)
                for punto = 1, total do
                    n = n + 1
                    local f = marcador.fichas[n]
                    if not f then
                        f = CreateFrame("Frame", nil, marcador)
                        f:SetSize(13, 13)
                        f.fondo = f:CreateTexture(nil, "ARTWORK")
                        f.fondo:SetPoint("TOPLEFT", 2, -2)
                        f.fondo:SetPoint("BOTTOMRIGHT", -2, 2)
                        f.marco = f:CreateTexture(nil, "OVERLAY")
                        f.marco:SetTexture("Interface\\Common\\WhiteIconFrame")
                        f.marco:SetAllPoints()
                        marcador.fichas[n] = f
                    end
                    local c = COLOR_FICHA[tipo] or { 0.7, 0.7, 0.7 }
                    -- La gastada se apaga en vez de desaparecer: asi se ve cuantas TENIAS.
                    if punto > quedan then
                        f.fondo:SetColorTexture(c[1] * 0.22, c[2] * 0.22, c[3] * 0.22, 0.9)
                        f.marco:SetVertexColor(0.35, 0.35, 0.35)
                    else
                        f.fondo:SetColorTexture(c[1], c[2], c[3], 1)
                        f.marco:SetVertexColor(c[1] * 1.1, c[2] * 1.1, c[3] * 1.1)
                    end
                    f:ClearAllPoints()
                    f:SetPoint("TOPLEFT", marcador, "TOPLEFT", 14 + (n - 1) * 16, -60)
                    f:Show()
                end
            end
        end
        for i = n + 1, #marcador.fichas do marcador.fichas[i]:Hide() end
    end

    -- Repinta con lo que hay ahora. Sale de la MISMA fuente que la ventana de turnos, para que no
    -- puedan decir cosas distintas.
    -- Se repinta tambien cuando cambia el movimiento o la economia, no solo al cambiar de turno:
    -- si no, la barra se quedaria llena mientras andas y las fichas encendidas al gastarlas.
    do
        local function Repintar()
            if marcador and marcador:IsShown() then PintarRecursos() end
        end
        if HarfordDnDAttackUI and HarfordDnDAttackUI.RegisterMovementListener then
            HarfordDnDAttackUI.RegisterMovementListener(Repintar)
        end
        if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
            HarfordDnDConditions.RegisterListener(Repintar)
        end
    end

    function HarfordTurnOrderAPI.RefreshTurnMarker()
        if not Activo() then
            if marcador then marcador:Hide() end
            return false
        end
        Crear()
        local store = HarfordTurnOrderStore
        if type(store) ~= "table" then marcador:Hide() return false end

        local nombre, detalle
        local entrada = store.entries and store.entries[store.activeIndex or 0]
        nombre = entrada and tostring(entrada.name or "") or "Sin empezar"
        if entrada and entrada.kind == "round" then nombre = "Cambio de asalto" end
        marcador.titulo:SetText(tostring(nombre))
        marcador.detalle:SetText(tostring(detalle or ""))
        local asalto = tonumber(store.asalto) or 0
        marcador.asalto:SetText(asalto > 0 and ("Asalto " .. asalto) or "")
        PintarRecursos()
        marcador:Show()
        return true
    end
end

-- Que es cada cosa de la economia de turno, en una linea. Vive aqui y no dentro del estandarte
-- porque el marcador y los tooltips dicen lo mismo: dos copias se acaban contradiciendo.
HarfordTurnOrderAPI.TEXTO_ECONOMIA = {
    action   = "Atacar, lanzar, correr, esquivar, ayudar, preparar...",
    bonus    = "Solo lo que un rasgo tuyo declare como adicional.",
    reaction = "Fuera de tu turno. Vuelve al empezar el siguiente.",
}

-- ─── EL ESTANDARTE DE TURNO ────────────────────────────────────────────
-- El aviso grande de que empieza un turno. Hay DOS formas, porque no todas las mesas quieren lo
-- mismo: una franja discreta que cruza la pantalla, y el estandarte colgante del aviso de jefe.
-- Se elige con el ajuste `turnbanner` (`estandarte` | `franja` | `off`).
--
-- Todo el arte es NATIVO (`BossBanner-*`), comprobado con `/harford debug run atlas`: existen los
-- tres trozos del estandarte (Top/Mid/Bottom, 440x112 los extremos), el medallon `-SkullCircle` y
-- los rayos `-RedLightning`. NO existen `-Title`, `-Skull`, `-BgGlow` ni `-Shield`, asi que el
-- titulo es texto y no hay resplandor de fondo.
--
-- Va en un `do...end`: el fichero ronda los 140 locales de file-scope y el limite de Lua 5.1 es 200.
-- Sin ticker: entra con `AnimationGroup` y se retira con un `C_Timer` de una sola vez.
do
    local banner, ocultar, estiloMontado

    local function Estilo()
        local v = HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("turnbanner")
        v = tostring(v or "franja")
        -- `on` es lo que valia antes de haber estilos: se respeta y significa el de por defecto.
        if v == "on" then return "franja" end
        return v
    end

    local function Crear()
        if banner then return banner end
        banner = CreateFrame("Frame", "HarfordTurnBannerFrame", UIParent)
        banner:SetPoint("TOP", UIParent, "TOP", 0, -120)
        -- HIGH y no DIALOG: tiene que verse sobre la interfaz de juego, pero NO tapar una ventana
        -- que el jugador tenga abierta -- dura cuatro segundos y no se puede quitar de en medio.
        banner:SetFrameStrata("HIGH")
        banner:EnableMouse(false)
        banner:Hide()

        -- Los tres trozos del estandarte. `-Mid` se estira entre los dos extremos; los extremos
        -- llevan su tamano de atlas, que es el que hace que el dibujo case.
        banner.arriba = banner:CreateTexture(nil, "BACKGROUND")
        banner.arriba:SetAtlas("BossBanner-BgBanner-Top", true)
        banner.abajo = banner:CreateTexture(nil, "BACKGROUND")
        banner.abajo:SetAtlas("BossBanner-BgBanner-Bottom", true)
        banner.medio = banner:CreateTexture(nil, "BACKGROUND")
        banner.medio:SetAtlas("BossBanner-BgBanner-Mid", false)

        banner.medallon = banner:CreateTexture(nil, "ARTWORK")
        banner.medallon:SetAtlas("BossBanner-SkullCircle", true)

        -- Los rayos salen de los DOS lados, espejados. Es lo que le da el golpe de entrada.
        banner.rayoDer = banner:CreateTexture(nil, "ARTWORK")
        banner.rayoDer:SetAtlas("BossBanner-RedLightning", true)
        banner.rayoDer:SetBlendMode("ADD")
        banner.rayoIzq = banner:CreateTexture(nil, "ARTWORK")
        banner.rayoIzq:SetAtlas("BossBanner-RedLightning", true)
        banner.rayoIzq:SetBlendMode("ADD")
        banner.rayoIzq:SetTexCoord(1, 0, 0, 1)

        banner.titulo = banner:CreateFontString(nil, "OVERLAY", "GameFont_Gigantic")
        banner.titulo:SetJustifyH("CENTER")
        banner.subtitulo = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        banner.subtitulo:SetTextColor(0.85, 0.82, 0.72)

        -- La entrada: el estandarte se despliega en horizontal (escala en X desde casi nada) y el
        -- texto entra despues, para que se lea cuando ya hay sitio donde leerlo.
        local ent = banner:CreateAnimationGroup()
        ent:SetToFinalAlpha(true)
        for _, clave in ipairs({ "arriba", "medio", "abajo" }) do
            local abre = ent:CreateAnimation("Scale")
            abre:SetChildKey(clave)
            abre:SetDuration(0.30)
            abre:SetFromScale(0.08, 1)
            abre:SetToScale(1, 1)
            abre:SetSmoothing("OUT")
            local aparece = ent:CreateAnimation("Alpha")
            aparece:SetChildKey(clave)
            aparece:SetDuration(0.20)
            aparece:SetFromAlpha(0)
            aparece:SetToAlpha(1)
        end
        -- El medallon cae de golpe encima, como en el aviso de jefe.
        local caeMedallon = ent:CreateAnimation("Scale")
        caeMedallon:SetChildKey("medallon")
        caeMedallon:SetDuration(0.15)
        caeMedallon:SetFromScale(5, 5)
        caeMedallon:SetToScale(1, 1)
        for _, clave in ipairs({ "titulo", "subtitulo" }) do
            local a = ent:CreateAnimation("Alpha")
            a:SetChildKey(clave)
            a:SetStartDelay(0.22)
            a:SetDuration(0.22)
            a:SetFromAlpha(0)
            a:SetToAlpha(1)
        end
        for _, clave in ipairs({ "rayoDer", "rayoIzq" }) do
            local brilla = ent:CreateAnimation("Alpha")
            brilla:SetChildKey(clave)
            brilla:SetDuration(0.18)
            brilla:SetFromAlpha(0)
            brilla:SetToAlpha(1)
            local apaga = ent:CreateAnimation("Alpha")
            apaga:SetChildKey(clave)
            apaga:SetStartDelay(0.18)
            apaga:SetDuration(0.45)
            apaga:SetFromAlpha(1)
            apaga:SetToAlpha(0)
        end
        banner.entrada = ent

        local sal = banner:CreateAnimationGroup()
        local fuera = sal:CreateAnimation("Alpha")
        fuera:SetDuration(0.5)
        fuera:SetFromAlpha(1)
        fuera:SetToAlpha(0)
        sal:SetScript("OnFinished", function() banner:Hide() end)
        banner.salida = sal
        return banner
    end

    -- Cada estilo re-ancla las MISMAS piezas y esconde las que no usa. Un frame por estilo daria
    -- dos juegos de animaciones que mantener en paralelo.
    local function AplicarEstilo(estilo)
        if estiloMontado == estilo then return end
        estiloMontado = estilo
        local b = banner
        b.arriba:ClearAllPoints() b.abajo:ClearAllPoints() b.medio:ClearAllPoints()
        b.medallon:ClearAllPoints() b.titulo:ClearAllPoints() b.subtitulo:ClearAllPoints()
        b.rayoDer:ClearAllPoints() b.rayoIzq:ClearAllPoints()

        if estilo == "franja" then
            -- Solo la franja de en medio, cruzando la pantalla. Discreta y baja.
            b:SetSize(600, 90)
            b.arriba:Hide() b.abajo:Hide() b.medallon:Hide()
            b.medio:Show()
            b.medio:SetPoint("TOPLEFT")
            b.medio:SetPoint("BOTTOMRIGHT")
            b.titulo:SetPoint("CENTER", b, "CENTER", 0, 8)
            b.subtitulo:SetPoint("TOP", b.titulo, "BOTTOM", 0, -2)
            b.rayoDer:SetPoint("LEFT", b, "CENTER", 40, 0)
            b.rayoIzq:SetPoint("RIGHT", b, "CENTER", -40, 0)
            return
        end

        -- El estandarte colgante: extremo arriba, extremo abajo y la franja estirada entre los dos.
        b:SetSize(440, 230)
        b.arriba:Show() b.abajo:Show() b.medallon:Show() b.medio:Show()
        b.arriba:SetPoint("TOP", b, "TOP", 0, 0)
        b.abajo:SetPoint("BOTTOM", b, "BOTTOM", 0, 0)
        -- Solapado a proposito: los extremos traen su propio degradado y si se dejan al ras se ve
        -- la costura entre las tres piezas.
        b.medio:SetPoint("TOPLEFT", b.arriba, "BOTTOMLEFT", 0, 34)
        b.medio:SetPoint("BOTTOMRIGHT", b.abajo, "TOPRIGHT", 0, -25)
        b.medallon:SetPoint("CENTER", b.arriba, "TOP", 0, -14)
        b.titulo:SetPoint("CENTER", b, "CENTER", 0, 10)
        b.subtitulo:SetPoint("TOP", b.titulo, "BOTTOM", 0, -4)
        b.rayoDer:SetPoint("LEFT", b, "CENTER", 60, 0)
        b.rayoIzq:SetPoint("RIGHT", b, "CENTER", -60, 0)
    end

    -- Lo que te queda por gastar este turno, en tarjetas debajo del estandarte. Es la idea que
    -- mejor funciona de DiceMaster: el aviso no solo dice que te toca, ENSENA lo que puedes hacer.
    -- La diferencia es que lo suyo es una lista fija escrita a mano y esto sale de la economia de
    -- turno real, asi que un Impetu de Accion se ve como dos acciones y no como una.
    --
    -- Fondo `LootBanner-ItemBg` (269x41) y aro `LootBanner-IconGlow` (40x40), los dos nativos.
    local TARJ_ALTO, TARJ_HUECO = 41, 4
    local COLOR_TIPO = {
        action   = { 0.36, 0.74, 0.36 },   -- verde, como las fichas de la barra
        bonus    = { 0.62, 0.42, 0.24 },   -- marron
        reaction = { 0.62, 0.36, 0.80 },   -- morado
    }
    local ICONO_TIPO = {
        action   = "Interface\\Icons\\Ability_Warrior_Charge",
        bonus    = "Interface\\Icons\\Ability_Rogue_SprintB",
        reaction = "Interface\\Icons\\Ability_Warrior_ShieldWall",
    }

    local function EnsureOpcion(i)
        banner.opciones = banner.opciones or {}
        local o = banner.opciones[i]
        if o then return o end
        o = CreateFrame("Frame", nil, banner)
        o:SetSize(269, TARJ_ALTO)
        o.fondo = o:CreateTexture(nil, "BACKGROUND")
        o.fondo:SetAtlas("LootBanner-ItemBg", false)
        o.fondo:SetAllPoints()
        o.icono = o:CreateTexture(nil, "ARTWORK")
        o.icono:SetSize(28, 28)
        o.icono:SetPoint("LEFT", o, "LEFT", 10, 0)
        o.icono:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        o.aro = o:CreateTexture(nil, "OVERLAY")
        o.aro:SetAtlas("LootBanner-IconGlow", true)
        o.aro:SetBlendMode("ADD")
        o.aro:SetPoint("CENTER", o.icono, "CENTER")
        o.titulo = o:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        o.titulo:SetPoint("TOPLEFT", o.icono, "TOPRIGHT", 9, -2)
        o.titulo:SetJustifyH("LEFT")
        o.detalle = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        o.detalle:SetPoint("TOPLEFT", o.titulo, "BOTTOMLEFT", 0, -1)
        o.detalle:SetWidth(210)
        o.detalle:SetJustifyH("LEFT")
        o.detalle:SetTextColor(0.78, 0.75, 0.66)
        banner.opciones[i] = o
        return o
    end

    -- Devuelve cuantas tarjetas quedaron puestas, para que el estandarte crezca lo justo.
    local function PintarOpciones(esMio)
        banner.opciones = banner.opciones or {}
        local n = 0
        -- Solo en TU turno: lo que puedes hacer tu no le interesa a nadie mas, y en el turno de
        -- otro serian cuatro tarjetas de relleno tapando la pantalla.
        local T = esMio and HarfordDnDConditions and HarfordDnDConditions.Turn or nil
        if T and T.IsActive and T.IsActive() then
            for _, tipo in ipairs(T.ORDEN or {}) do
                local quedan = (T.GetRemaining and T.GetRemaining(tipo)) or 0
                -- Lo GASTADO no se pinta: la tarjeta esta para decirte lo que te queda.
                if quedan > 0 then
                    n = n + 1
                    local o = EnsureOpcion(n)
                    local c = COLOR_TIPO[tipo] or { 0.8, 0.8, 0.8 }
                    local etiqueta = (T.ETIQUETA and T.ETIQUETA[tipo]) or tipo
                    o.icono:SetTexture(ICONO_TIPO[tipo] or "Interface\\Icons\\INV_Misc_QuestionMark")
                    o.aro:SetVertexColor(c[1], c[2], c[3])
                    o.titulo:SetText(etiqueta .. (quedan > 1 and ("  x" .. quedan) or ""))
                    o.titulo:SetTextColor(c[1] + 0.2, c[2] + 0.2, c[3] + 0.2)
                    o.detalle:SetText(HarfordTurnOrderAPI.TEXTO_ECONOMIA[tipo] or "")
                    o:ClearAllPoints()
                    o:SetPoint("TOP", banner, "BOTTOM", 0, -(n - 1) * (TARJ_ALTO + TARJ_HUECO) - 2)
                    o:Show()
                end
            end
            -- El movimiento no es una ficha entera sino un resto continuo, asi que va como una
            -- tarjeta mas pero contando metros.
            local U = HarfordDnDAttackUI
            local tope = (U and U.GetTurnMovementMax and U.GetTurnMovementMax()) or 0
            if tope > 0 then
                local gastado = (U.GetRecordedMovementMeters and U.GetRecordedMovementMeters()) or 0
                local quedan = math.max(0, tope - gastado)
                n = n + 1
                local o = EnsureOpcion(n)
                o.icono:SetTexture("Interface\\Icons\\Ability_Rogue_Sprint")
                o.aro:SetVertexColor(0.45, 0.72, 0.85)
                o.titulo:SetText(string.format("Movimiento  %.1f m", quedan))
                o.titulo:SetTextColor(0.65, 0.88, 1)
                o.detalle:SetText("Correr dobla el resto de este turno.")
                o:ClearAllPoints()
                o:SetPoint("TOP", banner, "BOTTOM", 0, -(n - 1) * (TARJ_ALTO + TARJ_HUECO) - 2)
                o:Show()
            end
        end
        for i = n + 1, #banner.opciones do banner.opciones[i]:Hide() end
        return n
    end

    function HarfordTurnOrderAPI.ShowTurnBanner(titulo, subtitulo, esMio)
        local estilo = Estilo()
        if estilo == "off" then return false end
        if not (C_Texture and C_Texture.GetAtlasInfo
            and C_Texture.GetAtlasInfo("BossBanner-BgBanner-Mid")) then
            -- Un atlas que no existe no borra la textura anterior, la deja como estaba: mas vale no
            -- pintar nada que pintar un rectangulo con la textura de otra cosa.
            return false
        end
        Crear()
        AplicarEstilo(estilo)
        if ocultar then ocultar:Cancel() ocultar = nil end
        banner.salida:Stop()
        banner:SetAlpha(1)
        banner.titulo:SetText(tostring(titulo or ""))
        -- Tu turno en dorado; el de otro en el gris de siempre. Es la unica diferencia que hace
        -- falta: lo que importa es saber de un vistazo si te toca.
        if esMio then banner.titulo:SetTextColor(1, 0.82, 0)
        else banner.titulo:SetTextColor(0.95, 0.95, 0.95) end
        banner.subtitulo:SetText(tostring(subtitulo or ""))
        PintarOpciones(esMio)
        banner:Show()
        banner.entrada:Stop()
        banner.entrada:Play()
        if PlaySound and SOUNDKIT and SOUNDKIT.UI_PERSONAL_LOOT_BANNER then
            PlaySound(SOUNDKIT.UI_PERSONAL_LOOT_BANNER, "Master")
        end
        ocultar = C_Timer.NewTimer(4, function()
            if banner:IsShown() then banner.salida:Play() end
        end)
        return true
    end

    -- Se retira YA, sin desvanecerse. Al terminar el combate no hay nada que rematar: si se dejara
    -- salir solo, el aviso del ultimo turno seguiria en pantalla cuatro segundos despues de que el
    -- combate haya dejado de existir.
    function HarfordTurnOrderAPI.HideTurnBanner()
        if not banner then return end
        if ocultar then ocultar:Cancel() ocultar = nil end
        banner.entrada:Stop()
        banner.salida:Stop()
        banner:Hide()
    end

    -- Para probar un estilo sin dejarlo puesto: lo aplica a la siguiente aparicion y nada mas.
    function HarfordTurnOrderAPI.PreviewTurnBanner(estilo, titulo, subtitulo, esMio)
        local antes = HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("turnbanner")
        if estilo and estilo ~= "" and HarfordConfig and HarfordConfig.Set then
            HarfordConfig.Set("turnbanner", estilo)
        end
        local ok = HarfordTurnOrderAPI.ShowTurnBanner(titulo, subtitulo, esMio)
        if estilo and estilo ~= "" and HarfordConfig and HarfordConfig.Set then
            HarfordConfig.Set("turnbanner", antes)
        end
        return ok
    end
end

-- ─── LA LISTA DE UN BLOQUE ──────────────────────────────────────────────────
-- Vive en el CORE porque MIRAR quien esta dentro no es cosa del DM: un jugador tiene que poder
-- abrirla igual, y HarfordAdmin no esta instalado en su cliente. Lo que si es del DM es EDITARLA,
-- y eso lo aporta Admin con `RegisterBlockPanelDecorator`.
--
-- Va entero en un `do...end`: el fichero ronda los 139 locales de file-scope y el limite de Lua 5.1
-- son 200. Aqui dentro no cuesta ninguno.
do
    -- Las medidas de tarjeta son las de la ventana de turnos, no una copia.
    local TARJ_HUECO, COLUMNAS, FILAS_A_LA_VISTA = 6, 3, 4
    local TARJ_W, TARJ_H, PANEL_ANCHO, ALTO_VISTA
    local function Medidas()
        TARJ_W, TARJ_H = CARD_W, CARD_H
        -- 22 de mas para la barra de desplazamiento: si no, se come media tarjeta.
        PANEL_ANCHO = 16 + COLUMNAS * TARJ_W + (COLUMNAS - 1) * TARJ_HUECO + 22
        ALTO_VISTA = FILAS_A_LA_VISTA * (TARJ_H + TARJ_HUECO)
    end

    local panel, tarjetas, bloqueActual = nil, {}, nil
    local decoradores = {}
    local RefrescarPanel

    local function EnsureTarjeta(i)
        if tarjetas[i] then return tarjetas[i] end
        local f
        f = CreateCardVisuals(panel.contenido, function() return f.miembro end)
        f:EnableMouse(true)
        f:SetScript("OnMouseUp", function(self, boton)
            local m = self.miembro
            if not m then return end
            if boton == "RightButton" then
                -- El core no abre menus de DM: expone el gesto y HarfordAdmin decide. Sin Admin
                -- cargado no pasa nada, que es lo correcto.
                HarfordTurnOrderAPI.OnCardRightClick(m, self)
                return
            end
            if boton ~= "LeftButton" then return end
            if AlguienSeQuedaElClick(m) then return end
            Ficha.ShowEntrySheet(m)
        end)
        tarjetas[i] = f
        return f
    end

    local function CrearPanel()
        if panel then return panel end
        Medidas()
        panel = CreateFrame("Frame", "HarfordTurnBlockFrame", UIParent, "BackdropTemplate")
        panel:SetSize(PANEL_ANCHO, 30 + ALTO_VISTA + 40)
        panel:SetFrameStrata("DIALOG")
        panel:SetFrameLevel(520)
        panel:SetClampedToScreen(true)
        panel:SetMovable(true)
        panel:EnableMouse(true)
        panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart", panel.StartMoving)
        panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
        SetFrameBackground(panel)
        panel.borde = CreateFrame("Frame", nil, panel, "DialogBorderTemplate")
        panel.borde:SetAllPoints(panel)
        panel.titulo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        panel.titulo:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)

        panel.scroll = CreateFrame("ScrollFrame", "HarfordTurnBlockScroll", panel,
            "UIPanelScrollFrameTemplate")
        panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -30)
        panel.scroll:SetSize(COLUMNAS * TARJ_W + (COLUMNAS - 1) * TARJ_HUECO, ALTO_VISTA)
        panel.contenido = CreateFrame("Frame", nil, panel.scroll)
        panel.contenido:SetSize(COLUMNAS * TARJ_W + (COLUMNAS - 1) * TARJ_HUECO, ALTO_VISTA)
        panel.scroll:SetScrollChild(panel.contenido)

        panel.cerrar = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        panel.cerrar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
        panel.cerrar:SetScript("OnClick", function() panel:Hide() end)
        -- Solo mientras se ve: el objetivo y la vida cambian constantemente y repintar una lista
        -- cerrada es trabajo tirado.
        panel:SetScript("OnShow", function(self)
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            self:RegisterEvent("UNIT_HEALTH")
            RefrescarPanel()
        end)
        panel:SetScript("OnHide", function(self) self:UnregisterAllEvents() end)
        panel:SetScript("OnEvent", function() RefrescarPanel() end)
        panel:Hide()
        return panel
    end

    RefrescarPanel = function()
        if not (panel and panel:IsShown() and bloqueActual) then return end
        local dentro = bloqueActual.miembros or {}
        panel.titulo:SetText(tostring(bloqueActual.name or "Bloque")
            .. "  |cff999999(" .. #dentro .. ")|r")
        -- El alto del contenido crece con las tarjetas; el area a la vista no. Eso es lo que hace
        -- que aparezca la barra en vez de recortar la lista.
        local filasNecesarias = math.max(FILAS_A_LA_VISTA, math.ceil(#dentro / COLUMNAS))
        panel.contenido:SetHeight(filasNecesarias * (TARJ_H + TARJ_HUECO))
        for i = 1, math.max(#dentro, #tarjetas) do
            local m, f = dentro[i], EnsureTarjeta(i)
            if not m then
                f:Hide()
            else
                -- El miembro YA ES una entrada: se le pasa tal cual, sin rellenar de la unidad que
                -- tengas delante. Por eso no se pierde nada al cambiar de objetivo.
                local mando = IsTurnAdmin()
                PaintEntryCard(f, m, mando)
                -- El marco de OBJETIVO, igual que en la ventana de turnos: son las mismas
                -- tarjetas y "a quien tengo delante" se pregunta lo mismo en las dos. El `id` de
                -- un miembro es su guid, que es lo que compara `IsEntryCurrentTarget`.
                SetCardTargetState(f, IsEntryCurrentTarget(m))
                f.miembro = m
                -- Sin mando la lista es de LECTURA: se ve quien hay, no se le toca la vida ni la
                -- CA. Es la misma regla que ya seguian las tarjetas de la ventana de turnos.
                f.minus:SetShown(mando)
                f.plus:SetShown(mando)
                f:ClearAllPoints()
                local col, fila = (i - 1) % COLUMNAS, math.floor((i - 1) / COLUMNAS)
                f:SetPoint("TOPLEFT", panel.contenido, "TOPLEFT",
                    col * (TARJ_W + TARJ_HUECO), -fila * (TARJ_H + TARJ_HUECO))
                f:Show()
            end
        end
        -- Y aqui es donde el DM cuelga lo suyo. Sin Admin no pasa nada, que es lo correcto.
        for _, fn in ipairs(decoradores) do
            pcall(fn, panel, bloqueActual, tarjetas, #dentro)
        end
    end

    -- Abre la lista de un bloque. La puede abrir cualquiera: es informacion, no una herramienta.
    function HarfordTurnOrderAPI.OpenBlockPanel(entry)
        if type(entry) ~= "table" then return false end
        local k = tostring(entry.kind or "")
        if k ~= "players" and k ~= "generic" then return false end
        CrearPanel()
        bloqueActual = entry
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        panel:Show()
        RefrescarPanel()
        return true
    end

    -- HarfordAdmin aniade aqui sus controles de edicion. Se llama en CADA refresco, asi que el
    -- decorador debe reutilizar sus botones y no crear uno nuevo cada vez.
    function HarfordTurnOrderAPI.RegisterBlockPanelDecorator(fn)
        if type(fn) ~= "function" then return false end
        decoradores[#decoradores + 1] = fn
        return true
    end

    function HarfordTurnOrderAPI.RefreshBlockPanel()
        RefrescarPanel()
    end

    function HarfordTurnOrderAPI.GetBlockPanelWidth()
        if not PANEL_ANCHO then Medidas() end
        return PANEL_ANCHO
    end
end

function HarfordTurnOrderAPI.CreateCardVisuals(parent, onArmorClick)
    return CreateCardVisuals(parent, onArmorClick)
end

function HarfordTurnOrderAPI.PaintEntryCard(card, entry, isAdmin)
    return PaintEntryCard(card, entry, isAdmin)
end

function HarfordTurnOrderAPI.OnCardRightClick(entry, ancla)
end

-- Click IZQUIERDO. A diferencia del derecho, aqui el core SI tiene comportamiento propio -- abrir
-- la ficha de la entrada --, asi que HarfordAdmin se apunta y devuelve true para quedarselo.
local alClickIzquierdo = {}
function HarfordTurnOrderAPI.RegisterOnCardLeftClick(fn)
    if type(fn) ~= "function" then return false end
    alClickIzquierdo[#alClickIzquierdo + 1] = fn
    return true
end

AlguienSeQuedaElClick = function(entry)
    for _, fn in ipairs(alClickIzquierdo) do
        local ok, tomado = pcall(fn, entry)
        if ok and tomado then return true end
    end
    return false
end

-- Cuelga un control en la ventana de turnos. Se oculta solo cuando quien mira no es admin, igual
-- que los controles propios, y se le pide repintarse en cada refresco si trae `Refrescar`.
function HarfordTurnOrderAPI.RegisterAdminControl(control)
    if type(control) ~= "table" or not TurnFrame then return false end
    TurnFrame.adminExtras = TurnFrame.adminExtras or {}
    TurnFrame.adminExtras[#TurnFrame.adminExtras + 1] = control
    if control.frame then
        TurnFrame.adminControls = TurnFrame.adminControls or {}
        TurnFrame.adminControls[#TurnFrame.adminControls + 1] = control.frame
    end
    return true
end

-- La ventana, para que HarfordAdmin pueda anclar sus controles.
function HarfordTurnOrderAPI.GetFrame()
    return TurnFrame
end

-- La ventana se crea al abrirla por primera vez, que puede ser despues de que HarfordAdmin haya
-- arrancado. Se le avisa para que cuelgue entonces lo suyo.
function HarfordTurnOrderAPI.RegisterOnFrameCreated(fn)
    if type(fn) ~= "function" then return false end
    alCrearVentana[#alCrearVentana + 1] = fn
    return true
end

-- Repartir la foto desde fuera del core. HarfordAdmin cambia datos -- bandos, modo, DMs -- y
-- necesita que la mesa se entere sin conocer el transporte.
function HarfordTurnOrderAPI.Broadcast()
    MarkChanged()
end

-- ─── DMs SECUNDARIOS ────────────────────────────────────────────────────────
-- Solo el DATO y su reparto. Nombrarlos es cosa de HarfordAdmin.
--
-- Sirven para repartir la carga de emitir comandos de servidor: un efecto delegado recorre la
-- cadena -- lider primero, secundarios detras -- y lo aplica el PRIMERO que pueda. En cadena y no
-- a todos, porque si dos lo aplicaran el golpe contaria dos veces.
-- ─── QUIEN VA DENTRO DE UN BLOQUE ───────────────────────────────────────────
-- Se guardan en la propia entrada del bloque y viajan con ella. No son entradas de turno: no
-- tienen tarjeta, ni iniciativa, ni vida en la lista -- eso se mira en el unitframe del NPC.

-- Los bloques que hay en la lista, por bando.
function HarfordTurnOrderAPI.GetBlockEntry(bando)
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return nil end
    for _, e in ipairs(store.entries) do
        local k = tostring(e.kind or "")
        if (k == "players" or k == "generic") and HarfordTurnOrderAPI.GetBando(e) == bando then
            return e
        end
    end
    return nil
end

function HarfordTurnOrderAPI.GetBlockMembers(entry)
    if type(entry) ~= "table" or type(entry.miembros) ~= "table" then return {} end
    return entry.miembros
end

-- Anadir por UNIDAD: se guarda guid y nombre, que es lo que hace falta para reconocerlo cuando le
-- toque el turno. Nada mas -- la vida y la CA se leen de la unidad viva.
function HarfordTurnOrderAPI.AddBlockMember(entry, unit)
    if type(entry) ~= "table" then return false, "No es un bloque" end
    if not (UnitExists and UnitExists(unit)) then return false, "No hay unidad" end
    local guid = UnitGUID and UnitGUID(unit)
    if not guid or guid == "" then return false, "Sin guid" end
    entry.miembros = entry.miembros or {}
    for _, m in ipairs(entry.miembros) do
        if m.guid == guid then return false, "Ya esta en ese bloque" end
    end
    -- Un miembro se guarda con los MISMOS datos que una tarjeta normal (icono, displayId, vida,
    -- CA, unitName...), porque su tarjeta es la misma y se pinta con el mismo pintor. Guardar solo
    -- guid/nombre obligaba a rellenar el resto de la unidad que tuvieras delante: al cambiar de
    -- objetivo se perdia el icono, la CA salia 0 y la vida de un PJ era la nativa, no la Harford.
    local nombre, hp, maxHp, entryKind, id, mana, maxMana, unitName, icon, displayId, meta =
        CapturarUnidadDeTurno(unit, nil)
    local miembro = {
        id = id, guid = guid, name = nombre, kind = entryKind, unitName = unitName,
        hp = hp, maxHp = maxHp, mana = mana, maxMana = maxMana,
        icon = NormalizeIconPath(icon) or "", displayId = displayId,
        armorClass = meta.armorClass or 0, reaction = meta.reaction or 0,
        nameColor = meta.nameColor,
        jugador = (entryKind == "player") and true or nil,
    }
    Codec.NormalizeEntryLinks(miembro)
    entry.miembros[#entry.miembros + 1] = miembro
    -- La vida de un jugador la sirve el sistema Harford, no la unidad: hay que pedirsela.
    if entryKind == "player" and HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName then
        HarfordDnDAPI.RequestResourcesForName(unitName)
    end
    MarkChanged()
    return true
end

function HarfordTurnOrderAPI.RemoveBlockMember(entry, guid)
    if type(entry) ~= "table" or type(entry.miembros) ~= "table" then return false end
    for i = #entry.miembros, 1, -1 do
        if entry.miembros[i].guid == guid then
            table.remove(entry.miembros, i)
            MarkChanged()
            return true
        end
    end
    return false
end

function HarfordTurnOrderAPI.GetSecondaryDMs()
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.dms) ~= "table" then return {} end
    return store.dms
end

function HarfordTurnOrderAPI.SetSecondaryDMs(lista)
    local store = EnsureStore()
    local limpia = {}
    for _, n in ipairs(type(lista) == "table" and lista or {}) do
        local nombre = tostring(n or "")
        if nombre ~= "" then limpia[#limpia + 1] = nombre end
    end
    store.dms = (#limpia > 0) and limpia or nil
    MarkChanged()
    return true
end

-- ─── EL ESTADO DEL COMBATE ───────────────────────────────────────────────────
-- Tres estados, como en Atlas: sin combate, `preparando` (montando la lista) y `activo` (ya se
-- juegan turnos). Antes "hay combate" se DEDUCIA de que hubiera entradas en la lista, y eso hacia
-- que terminar el combate y vaciar la lista fueran lo mismo: no se podia dejar la mesa montada
-- entre escenas, y un `/reload` con entradas guardadas resucitaba un combate ya cerrado.
HarfordTurnOrderAPI.ESTADO_NINGUNO   = nil
HarfordTurnOrderAPI.ESTADO_PREPARA   = "preparando"
HarfordTurnOrderAPI.ESTADO_ACTIVO    = "activo"

function HarfordTurnOrderAPI.GetCombatState()
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" then return nil end
    local e = tostring(store.estado or "")
    if e == "activo" or e == "preparando" then return e end
    return nil
end

function HarfordTurnOrderAPI.SetCombatState(estado)
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" then return false end
    if estado ~= "activo" and estado ~= "preparando" then estado = nil end
    if store.estado == estado then return false end
    store.estado = estado
    return true
end

-- Estoy YO dentro del combate? Estar en la raid no es estar en la pelea: media hermandad puede
-- ver el combate sin jugarlo, y a esos no hay que pintarles la barra de movimiento ni limitarles
-- nada. Cuento como dentro si tengo entrada propia, si estoy en la lista de algun bloque, o si
-- estoy llevando a un NPC poseido -- en ese caso estoy jugando SU turno.
function HarfordTurnOrderAPI.AmIInCombat()
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return false end
    local miGuid = UnitGUID and UnitGUID("player")
    for _, entry in ipairs(store.entries) do
        if EntryBelongsToMe(entry) and tostring(entry.kind or "") ~= "players" then return true end
        for _, m in ipairs(entry.miembros or {}) do
            if miGuid and tostring(m.guid or "") == miGuid then return true end
        end
    end
    -- El DM que lleva un NPC esta jugando el turno de ese NPC, aunque el no figure en la lista.
    if UnitExists and UnitExists("pet") and IsTurnAdmin and IsTurnAdmin() then return true end
    return false
end

-- Es MI turno ahora mismo? En bandos, que el bloque activo sea el de los PJs y este EMPEZADO --el
-- cierre de un bloque no es tiempo de jugar--. En individual, que la entrada activa sea la mia.
--
-- Hace falta para lo que NO se puede hacer fuera de tu turno: la accion, la adicional y el
-- movimiento son tuyos mientras te toca. La reaccion no, que para eso es una reaccion.
function HarfordTurnOrderAPI.IsMyTurn()
    if not HarfordTurnOrderAPI.HasActiveCombat() then return false end
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" then return false end
    local entrada = store.entries and store.entries[store.activeIndex or 0]
    return entrada ~= nil and EntryBelongsToMe(entrada)
end

-- Cuantos combatientes hay montados, este el combate empezado o no. Lo que antes contestaba
-- `HasActiveCombat`, y lo que de verdad hace falta para saber si se puede iniciar.
-- Lo consulta el diagnostico de por que se borro un combate: el limite de caducidad depende de si
-- mandas, y sin poder preguntarlo desde fuera no se puede explicar la decision.
function HarfordTurnOrderAPI.IsTurnAdmin()
    return IsTurnAdmin and IsTurnAdmin() or false
end

function HarfordTurnOrderAPI.HasCombatants()
    local store = HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return false end
    for _, entry in ipairs(store.entries) do
        -- Lo unico que NO cuenta es el marcador de asalto. Un BLOQUE si cuenta.
        if tostring(entry.kind or "") ~= "round" then return true end
    end
    return false
end

-- "Hay combate" es ahora que se haya INICIADO, no que haya gente en la lista. Montar la mesa y
-- jugar turnos son dos cosas distintas: la economia de turno, el contador de movimiento y las
-- fichas de accion solo tienen sentido en la segunda.
function HarfordTurnOrderAPI.HasActiveCombat()
    if HarfordTurnOrderAPI.GetCombatState() == "activo" then return true end
    -- Compatibilidad hacia atras: una lista guardada por una version anterior no trae estado, y
    -- sin esto un combate en curso se quedaba muerto al actualizar el addon.
    local store = HarfordTurnOrderStore
    if type(store) == "table" and store.estado == nil and store.asalto and store.asalto > 0 then
        return HarfordTurnOrderAPI.HasCombatants()
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
