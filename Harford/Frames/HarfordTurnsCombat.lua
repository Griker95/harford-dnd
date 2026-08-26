-- Combate del tracker de turnos: tirada de iniciativa, orden e inicio/fin.
--
-- Separado de HarfordTurns.lua porque es donde va a crecer el sistema: hay rasgos que manipulan la
-- iniciativa de formas que aun no estan implementadas -- "Preparado" (Cazador de Demonios) actua
-- DOS veces el primer asalto, en el conteo 30 y en su tirada; "Desplazamiento temporal" (Mago
-- Arcano) INTERCAMBIA su resultado con otra criatura; y el companero del Cazador comparte conteo.
--
-- Contrato importante: la iniciativa de un JUGADOR la tira SU cliente, no el DM. El bonus depende
-- de rasgos que solo su ficha conoce (Alacridad suma Carisma, Afinidad Aire suma competencia), asi
-- que el DM hace una tirada provisional, pide por INITREQ, y cada cliente responde con la suya.
-- Si alguien no contesta se queda la provisional: el combate nunca se queda esperando.

HarfordTurnsCombat = HarfordTurnsCombat or {}
local API = HarfordTurnsCombat

-- El marcador de asalto encabeza siempre: ninguna tirada puede alcanzarlo. No es 20 ni 30 porque
-- "Preparado" actua en el conteo 30.
local ROUND_MARKER_INITIATIVE = 9999
local COMM_PREFIX

-- Inyectadas por HarfordTurns: este modulo no toca su estado interno directamente.
local AdvanceTurnSerial, ClaimAdminIfNeeded, EnsureActiveVisible, EnsureRoundMarker, EnsureStore, EntryBelongsToMe, IsSystemEntry, IsTurnAdmin, MarkChanged, Print, SafeNumber, SendState

function API.Init(deps)
    deps = deps or {}
    COMM_PREFIX = deps.commPrefix or COMM_PREFIX
    ROUND_MARKER_INITIATIVE = deps.roundMarkerInitiative or ROUND_MARKER_INITIATIVE
    AdvanceTurnSerial = deps.AdvanceTurnSerial or AdvanceTurnSerial
    ClaimAdminIfNeeded = deps.ClaimAdminIfNeeded or ClaimAdminIfNeeded
    EnsureActiveVisible = deps.EnsureActiveVisible or EnsureActiveVisible
    EnsureRoundMarker = deps.EnsureRoundMarker or EnsureRoundMarker
    EnsureStore = deps.EnsureStore or EnsureStore
    EntryBelongsToMe = deps.EntryBelongsToMe or EntryBelongsToMe
    IsSystemEntry = deps.IsSystemEntry or IsSystemEntry
    IsTurnAdmin = deps.IsTurnAdmin or IsTurnAdmin
    MarkChanged = deps.MarkChanged or MarkChanged
    Print = deps.Print or Print
    SafeNumber = deps.SafeNumber or SafeNumber
    SendState = deps.SendState or SendState
end

local function RollD20()
    return random and random(1, 20) or 1
end

local function LocalInitiativeBonus(entry)
    if not entry then return 0 end
    if entry.kind == "player" and EntryBelongsToMe(entry) then
        if HarfordDnDCalc and HarfordDnDCalc.GetInitiativeBonus then
            return tonumber(HarfordDnDCalc.GetInitiativeBonus()) or 0
        end
        return 0
    end
    if entry.kind == "player" then return 0 end
    local unit = entry.unitName and HarfordClassColors and HarfordClassColors.FindUnitByName
        and HarfordClassColors.FindUnitByName(entry.unitName)
    if unit and HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local stats = HarfordTRP3.GetNPCStatBlock(unit)
        local dex = stats and stats.abilities and stats.abilities.Destreza
        if dex then return math.floor(((tonumber(dex.value) or 10) - 10) / 2) end
    end
    return 0
end

local function SortByInitiative()
    local store = EnsureStore()
    for i, entry in ipairs(store.entries) do
        entry._ordenPrevio = i
    end
    table.sort(store.entries, function(a, b)
        local ia = tonumber(a.initiative) or 0
        local ib = tonumber(b.initiative) or 0
        if ia ~= ib then return ia > ib end
        return (a._ordenPrevio or 0) < (b._ordenPrevio or 0)
    end)
    for _, entry in ipairs(store.entries) do
        entry._ordenPrevio = nil
    end
end

local function ApplyInitiativeReply(message, sender)
    local opcode, entryId, valueRaw = strsplit("|", message or "")
    if opcode ~= "INITRES" then return false end
    if not IsTurnAdmin() then return false end
    local valor = SafeNumber(valueRaw, nil)
    if not valor then return false end
    local store = EnsureStore()
    for _, entry in ipairs(store.entries) do
        if tostring(entry.id or "") == tostring(entryId or "") and entry.kind == "player" then
            local corto = Ambiguate and Ambiguate(tostring(sender or ""), "short") or tostring(sender or "")
            local suyo = Ambiguate and Ambiguate(tostring(entry.unitName or entry.name or ""), "short")
                or tostring(entry.unitName or entry.name or "")
            if corto ~= "" and corto == suyo then
                entry.initiative = valor
                SortByInitiative()
                MarkChanged()
                return true
            end
            return false
        end
    end
    return false
end

local function ApplyInitiativeRequest(message, sender)
    local opcode = strsplit("|", message or "")
    if opcode ~= "INITREQ" then return false end
    local store = EnsureStore()
    for _, entry in ipairs(store.entries) do
        if entry.kind == "player" and EntryBelongsToMe(entry) then
            local valor = RollD20() + LocalInitiativeBonus(entry)
            entry.initiative = valor
            if HarfordSync and HarfordSync.Send and sender then
                HarfordSync.Send(COMM_PREFIX,
                    "INITRES|" .. tostring(entry.id) .. "|" .. tostring(valor), "WHISPER", sender)
            end
            if HarfordDnDConditions and HarfordDnDConditions.Turn then
                HarfordDnDConditions.Turn.Reset()
            end
            Print("Iniciativa: |cff66ccff" .. tostring(valor) .. "|r")
            return true
        end
    end
    return false
end

local function StartCombat()
    if not IsTurnAdmin() then Print("Solo el admin puede iniciar el combate.") return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    EnsureRoundMarker()
    if not HarfordTurnOrderAPI.HasActiveCombat() then
        Print("Anade combatientes antes de iniciar el combate.")
        return
    end

    local jugadores, combatientes = 0, 0
    for _, entry in ipairs(store.entries) do
        if not IsSystemEntry(entry) then
            entry.initiative = RollD20() + LocalInitiativeBonus(entry)
            combatientes = combatientes + 1
            if entry.kind == "player" and not EntryBelongsToMe(entry) then
                jugadores = jugadores + 1
            end
        end
    end
    SortByInitiative()
    store.activeIndex = 1
    -- El ciclo de bandos vuelve al principio: un combate nuevo no hereda por donde iba el anterior.
    store.activeBando = nil
    store.faseBando = nil
    store.asalto = 0
    EnsureActiveVisible()

    -- Cada jugador vuelve a tirar la suya con su propio bonus y responde.
    local ch = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if ch and jugadores > 0 then
        HarfordSync.Send(COMM_PREFIX, "INITREQ|" .. tostring(AdvanceTurnSerial()), ch)
    end

    -- La economia de turno arranca limpia para todos: es un combate nuevo.
    if HarfordDnDConditions and HarfordDnDConditions.Turn then
        HarfordDnDConditions.Turn.Reset()
    end
    Print("|cffffff00Comienza el combate.|r Iniciativa tirada para "
        .. tostring(combatientes) .. " combatiente(s).")
    MarkChanged()
    SendState()
end

local function EndCombat()
    if not IsTurnAdmin() then Print("Solo el admin puede terminar el combate.") return end
    ClaimAdminIfNeeded()
    local store = EnsureStore()
    store.entries = {}
    store.activeIndex = 1
    store.lastTouched = nil
    -- Sin combatientes no hay bandos. Dejarlos puestos haria que el siguiente combate arrancara a
    -- media rotacion, igual que pasaba al caducar la lista.
    store.activeBando = nil
    store.faseBando = nil
    store.asalto = nil
    EnsureRoundMarker()
    Print("|cffffff00Fin del combate.|r")
    MarkChanged()
    SendState()
end

API.RollD20 = RollD20
API.LocalInitiativeBonus = LocalInitiativeBonus
API.SortByInitiative = SortByInitiative
API.ApplyInitiativeReply = ApplyInitiativeReply
API.ApplyInitiativeRequest = ApplyInitiativeRequest
API.StartCombat = StartCombat
API.EndCombat = EndCombat
