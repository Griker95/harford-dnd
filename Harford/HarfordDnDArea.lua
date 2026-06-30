-- Motor comun de ataques de area. La geometria es informativa: el usuario marca
-- explicitamente las victimas y cada una resuelve su propia defensa.

HarfordDnDArea = HarfordDnDArea or {}
local API = HarfordDnDArea

local PREFIX = "DND5EARC"
local MAX_TARGETS = 40
local REQUEST_TTL = 60
local RESPONSE_TIMEOUT = 8
local ROW_COUNT = 8
local ROW_HEIGHT = 25

API.S = API.S or {
    serial = 0,
    session = nil,
    processed = {},
    frame = nil,
}
local S = API.S

local function Now()
    return (GetTime and GetTime()) or (time and time()) or 0
end

local function Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r " .. tostring(message or ""))
    end
end

local function CanonicalDamageType(value)
    value = tostring(value or "")
    if HarfordDamageMitigation and HarfordDamageMitigation.KeyFromTypeText then
        local key = HarfordDamageMitigation.KeyFromTypeText(value)
        if key then return key end
    end
    value = HarfordClassColors.StripAccents(value):lower():gsub("%s+", "")
    if HarfordDamageTypes and HarfordDamageTypes.Exists and HarfordDamageTypes.Exists(value) then
        return value
    end
    return nil
end

local function CanonicalAbility(value)
    value = HarfordClassColors.StripAccents(tostring(value or "")):lower()
        :gsub("^%s+", ""):gsub("%s+$", "")
    local aliases = {
        fue = "Fuerza", fuerza = "Fuerza",
        des = "Destreza", destreza = "Destreza",
        con = "Constitucion", cons = "Constitucion", constitucion = "Constitucion",
        int = "Inteligencia", inteligencia = "Inteligencia",
        sab = "Sabiduria", sabiduria = "Sabiduria",
        car = "Carisma", carisma = "Carisma",
    }
    return aliases[value]
end

local CONDITION_DURATIONS = {
    manual = true,
    target_turn_start = true, source_turn_start = true,
    target_turn_end = true, source_turn_end = true,
    rounds = true, save_at_turn_end = true,
}

local function NormalizeConditionMetadata(area, definition, conditionId)
    if conditionId == "" then
        return "manual", 0, nil, 0, false
    end
    local duration = tostring(area.conditionDuration or definition.conditionDuration or "manual")
    if not CONDITION_DURATIONS[duration] then return nil, "Duracion de condicion de area desconocida" end
    local turns = math.max(0, math.min(99,
        math.floor(tonumber(area.conditionTurns or definition.conditionTurns) or 0)))
    local saveAbility = CanonicalAbility(area.conditionSaveAbility or definition.conditionSaveAbility)
    local saveDC = math.max(0, math.min(99,
        math.floor(tonumber(area.conditionSaveDC or definition.conditionSaveDC) or 0)))
    if duration == "rounds" and turns <= 0 then return nil, "Una condicion por rondas necesita conditionTurns" end
    if duration == "save_at_turn_end" and (not saveAbility or saveDC <= 0) then
        return nil, "La salvacion final de la condicion esta incompleta"
    end
    return duration, turns, saveAbility, saveDC,
        area.conditionPersist == true or definition.conditionPersist == true
end

local function DamageLabel(key)
    return (HarfordDamageTypes and HarfordDamageTypes.GetLabel and HarfordDamageTypes.GetLabel(key)) or tostring(key or "")
end

local function NormalizeComponents(components)
    local out = {}
    for i, component in ipairs(components or {}) do
        if i > 8 then break end
        local dice = tostring(component.damageDice or component.dice or "")
        local count, sides
        if HarfordDnDWeapons and HarfordDnDWeapons.ParseDice then
            count, sides = HarfordDnDWeapons.ParseDice(dice)
        end
        local damageType = CanonicalDamageType(component.damageType or component.type)
        if not count or not sides or count < 1 or count > 100 or sides < 2 or sides > 1000 or not damageType then
            return nil, "Componente de dano de area invalido"
        end
        out[#out + 1] = {
            damageDice = tostring(count) .. "d" .. tostring(sides),
            damageBonus = math.max(-10000, math.min(10000, math.floor(tonumber(component.damageBonus or component.bonus) or 0))),
            damageType = damageType,
        }
    end
    if #out == 0 then return nil, "El ataque de area no tiene dano" end
    return out
end

local function NormalizeDefinition(definition)
    definition = definition or {}
    local area = definition.area or definition
    local resolution = area.resolution == "attack" and "attack" or area.resolution == "save" and "save"
        or area.resolution == "auto" and "auto" or nil
    if not resolution then return nil, "Resolucion de area desconocida" end

    local conditionId = tostring(area.conditionId or definition.conditionId or "")
    if conditionId ~= "" and not (HarfordDnDConditions and HarfordDnDConditions.GetDefinition
        and HarfordDnDConditions.GetDefinition(conditionId)) then
        return nil, "Condicion de area desconocida"
    end

    local components, err = NormalizeComponents(area.damageComponents or definition.damageComponents)
    if not components then
        -- Sin daño es valido SOLO si el conjuro aplica una condicion (control puro).
        if conditionId == "" then return nil, err end
        components = {}
    end

    local shape = tostring(area.shape or "other"):lower()
    if shape ~= "cone" and shape ~= "sphere" and shape ~= "line" and shape ~= "other" then shape = "other" end
    local conditionDuration, conditionTurns, conditionSaveAbility, conditionSaveDC, conditionPersist =
        NormalizeConditionMetadata(area, definition, conditionId)
    if not conditionDuration then return nil, conditionTurns end
    local out = {
        label = tostring(definition.hyperlink or definition.title or definition.name or area.label or "Ataque de area"),
        networkLabel = tostring(definition.title or definition.name or area.label or "Ataque de area"),
        shape = shape,
        sizeText = tostring(area.sizeText or ""):sub(1, 40),
        resolution = resolution,
        damageComponents = components,
        auraId = math.max(0, math.floor(tonumber(area.auraId or area.onFailAura or area.onHitAura or definition.onFailAura or definition.onHitAura) or 0)),
        conditionId = conditionId,
        conditionDuration = conditionDuration,
        conditionTurns = conditionTurns,
        conditionSaveAbility = conditionSaveAbility,
        conditionSaveDC = conditionSaveDC,
        conditionPersist = conditionPersist,
        resourceKey = tostring(area.resourceKey or area.resource or ""),
        resourceCost = math.max(0, math.floor(tonumber(area.resourceCost or area.cost) or 0)),
        attackRange = area.attackRange == "melee" and "melee" or "ranged",
    }
    if resolution == "save" then
        out.saveAbility = CanonicalAbility(area.saveAbility or area.ability)
        out.dc = math.max(1, math.min(99, math.floor(tonumber(area.dc) or 0)))
        out.success = area.success == "half" and "half" or area.success == "none" and "none"
            or (#components == 0 and "none") or nil  -- condicion pura: success no aplica
        if not out.saveAbility or out.dc <= 0 then return nil, "Salvacion de area incompleta" end
        if not out.success then return nil, "Falta indicar si la salvacion reduce a mitad o niega el dano" end
    elseif resolution == "attack" then
        out.attackBonus = math.max(-99, math.min(99, math.floor(tonumber(area.attackBonus or definition.attackBonus) or 0)))
    end  -- resolution == "auto": sin tirada, no necesita campos extra
    return out
end

function API.DefinitionFromFeature(feature)
    if not (feature and type(feature.area) == "table") then return nil end
    return NormalizeDefinition(feature)
end

function API.DefinitionFromAction(action)
    if not (action and type(action.area) == "table") then return nil end
    return NormalizeDefinition(action)
end

local function ShapeText(def)
    local labels = { cone = "Cono", sphere = "Radio", line = "Linea", other = "Area" }
    local text = labels[def.shape] or "Area"
    if def.sizeText ~= "" then text = text .. " " .. def.sizeText end
    return text
end

local function CaptureUnit(unit)
    unit = unit or "target"
    if not (UnitExists and UnitExists(unit) and UnitGUID) then return nil, "Sin objetivo" end
    local guid = UnitGUID(unit)
    if not guid or guid == "" then return nil, "El objetivo no tiene GUID" end
    local isPlayer = UnitIsPlayer and UnitIsPlayer(unit)
    local name
    if HarfordTRP3 and HarfordTRP3.GetUnitRPName then name = HarfordTRP3.GetUnitRPName(unit) end
    name = name or HarfordClassColors.UnitFullName(unit) or "Objetivo"
    return {
        guid = guid,
        kind = isPlayer and "player" or "npc",
        name = name,
        unitName = isPlayer and HarfordClassColors.UnitFullName(unit) or nil,
        status = "Marcado",
        conditionIds = HarfordDnDConditions and HarfordDnDConditions.GetActiveIds
            and HarfordDnDConditions.GetActiveIds(unit) or nil,
    }
end

local RefreshFrame

local function CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    return button
end

local function EnsureFrame()
    if S.frame then return S.frame end
    local frame = CreateFrame("Frame", "HarfordDnDAreaFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(430, 350)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -7)
    title:SetText("Ataque de area")
    frame.areaTitle = title

    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", 18, -35)
    info:SetPoint("RIGHT", -18, 0)
    info:SetJustifyH("LEFT")
    frame.info = info

    local candidate = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    candidate:SetPoint("TOPLEFT", 18, -64)
    candidate:SetPoint("RIGHT", -142, 0)
    candidate:SetJustifyH("LEFT")
    frame.candidate = candidate

    local add = CreateButton(frame, "Anadir objetivo", 120, 22)
    add:SetPoint("TOPRIGHT", -18, -58)
    add:SetScript("OnClick", function() API.AddCurrentTarget() end)
    frame.add = add

    local rows = {}
    for i = 1, ROW_COUNT do
        local row = CreateFrame("Button", nil, frame)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 20, -92 - (i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", -40, 0)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.08, 0.08, 0.08, i % 2 == 0 and 0.7 or 0.45)
        local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        name:SetPoint("LEFT", 6, 0)
        name:SetPoint("RIGHT", -112, 0)
        name:SetJustifyH("LEFT")
        local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("RIGHT", -27, 0)
        status:SetWidth(82)
        status:SetJustifyH("RIGHT")
        local remove = CreateButton(row, "X", 22, 20)
        remove:SetPoint("RIGHT", -1, 0)
        remove:SetScript("OnClick", function(self)
            if self.guid then API.RemoveTarget(self.guid) end
        end)
        row.name, row.status, row.remove = name, status, remove
        rows[i] = row
    end
    frame.rows = rows

    local scroll = CreateFrame("ScrollFrame", "HarfordDnDAreaScrollFrame", frame, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", rows[1], "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", rows[#rows], "BOTTOMRIGHT", 22, 0)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RefreshFrame)
    end)
    frame.scroll = scroll

    local clear = CreateButton(frame, "Limpiar", 82, 22)
    clear:SetPoint("BOTTOMLEFT", 18, 15)
    clear:SetScript("OnClick", function()
        local session = S.session
        if session and not session.resolved then session.targets = {}; RefreshFrame() end
    end)
    frame.clear = clear

    local skip = CreateButton(frame, "Saltar NPC", 92, 22)
    skip:SetPoint("LEFT", clear, "RIGHT", 8, 0)
    skip:SetScript("OnClick", function() API.SkipPendingNpc() end)
    frame.skip = skip

    local cancel = CreateButton(frame, "Cancelar", 82, 22)
    cancel:SetPoint("BOTTOMRIGHT", -18, 15)
    cancel:SetScript("OnClick", function() API.Cancel() end)
    frame.cancel = cancel

    local resolve = CreateButton(frame, "Resolver", 92, 22)
    resolve:SetPoint("RIGHT", cancel, "LEFT", -8, 0)
    resolve:SetScript("OnClick", function() API.Resolve() end)
    frame.resolve = resolve

    -- Solo zonas: avanza al siguiente turno para re-marcar y re-aplicar daño sin re-pagar mana.
    local repeatBtn = CreateButton(frame, "Repetir turno", 100, 22)
    repeatBtn:SetPoint("RIGHT", resolve, "LEFT", -8, 0)
    repeatBtn:SetScript("OnClick", function() API.RepeatTurn() end)
    frame.repeatBtn = repeatBtn

    if frame.CloseButton then frame.CloseButton:SetScript("OnClick", function() API.Cancel() end) end
    S.frame = frame
    return frame
end

RefreshFrame = function()
    local frame = EnsureFrame()
    local session = S.session
    if not session then frame:Hide(); return end
    frame.areaTitle:SetText(session.definition.label)
    local def = session.definition
    local infoText = ShapeText(def) .. " - " .. (
        def.resolution == "save" and ("Salv. " .. def.saveAbility .. " CD " .. def.dc)
        or def.resolution == "auto" and "Auto-impacto"
        or ("Ataque " .. ((def.attackBonus or 0) >= 0 and "+" or "") .. (def.attackBonus or 0)))
    local pending = session.resolved and session.pendingNpc and session.pendingNpc[session.pendingNpcIndex or 1]
    if pending then infoText = infoText .. " | Siguiente NPC: " .. pending.target.name end
    frame.info:SetText(infoText)
    local candidate = CaptureUnit("target")
    frame.candidate:SetText(candidate and ("Objetivo actual: " .. candidate.name) or "Objetivo actual: ninguno")

    local targets = session.targets or {}
    local offset = FauxScrollFrame_GetOffset(frame.scroll) or 0
    FauxScrollFrame_Update(frame.scroll, #targets, ROW_COUNT, ROW_HEIGHT)
    for i, row in ipairs(frame.rows) do
        local target = targets[offset + i]
        if target then
            row:Show()
            row.name:SetText(target.name .. (target.kind == "player" and " |cff66ccff[J]|r" or " |cffffcc66[NPC]|r"))
            local statusLabels = {
                marked = "Marcado", waiting = "Esperando", saved = "Salvada", failed = "Fallada",
                hit = "Impacto", miss = "Fallo", skipped = "Omitido", timeout = "Sin confirmar",
            }
            local rawStatus = tostring(target.status or "")
            local code, suffix = rawStatus:match("^(%a+)(.*)$")
            row.status:SetText((statusLabels[code] or rawStatus) .. (suffix or ""))
            row.remove.guid = target.guid
            row.remove:SetShown(not session.resolved)
        else
            row:Hide()
            row.remove.guid = nil
        end
    end
    frame.add:SetEnabled(not session.resolved and #targets < MAX_TARGETS)
    frame.clear:SetEnabled(not session.resolved and #targets > 0)
    frame.resolve:SetEnabled(not session.resolved and #targets > 0)
    frame.skip:SetShown(session.resolved and session.pendingNpcIndex and session.pendingNpcIndex <= #(session.pendingNpc or {}))
    -- "Repetir turno" solo en zonas ya resueltas (avanza al siguiente turno de la zona persistente).
    frame.repeatBtn:SetShown(session.zone and session.resolved and true or false)
end

function API.Open(definition, context)
    local normalized, err = NormalizeDefinition(definition)
    if not normalized then Print(err); return false, err end
    context = context or {}
    if context.sourceKind == "npc" and context.sourceGuid then
        local currentGuid = UnitGUID and UnitGUID("target")
        if currentGuid ~= context.sourceGuid or (UnitIsPlayer and UnitIsPlayer("target")) then
            local message = "El objetivo ya no coincide con el NPC que ejecuta el ataque."
            Print(message)
            return false, message
        end
    end
    if not context.sourceGuid or context.sourceGuid == "" then
        context.sourceGuid = UnitGUID and UnitGUID(context.sourceKind == "npc" and "target" or "player") or ""
    end
    if not context.sourceName or context.sourceName == "" then
        local sourceUnit = context.sourceKind == "npc" and "target" or "player"
        context.sourceName = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName(sourceUnit))
            or (HarfordClassColors and HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName(sourceUnit))
            or ""
    end
    S.serial = (S.serial % 999999) + 1
    S.session = {
        id = tostring(math.floor(Now() * 1000)) .. "." .. tostring(S.serial),
        definition = normalized,
        context = context,
        targets = {},
        resolved = false,
        zone = context.zone == true,  -- zona persistente: habilita "Repetir turno" (re-aplica sin re-pagar)
        turn = 1,
        sourceConditionIds = HarfordDnDConditions and HarfordDnDConditions.GetActiveIds
            and HarfordDnDConditions.GetActiveIds(context.sourceKind == "player" and "player" or context.sourceGuid) or nil,
    }
    local frame = EnsureFrame()
    if type(context.onBegin) == "function" then context.onBegin(normalized) end
    -- Auto-resolucion de objetivo unico SIN ventana: marca el target actual y resuelve, para que
    -- un ataque/salvacion de conjuro de objetivo unico se sienta como un ataque normal. Si no hay
    -- objetivo valido, cae a mostrar la ventana para marcado manual.
    if context.autoResolve then
        frame:Hide()
        if API.AddCurrentTarget() then
            API.Resolve()
            return true
        end
        Print("Sin objetivo valido: marca las victimas manualmente.")
    end
    frame:Show()
    RefreshFrame()
    return true
end

function API.AddCurrentTarget()
    local session = S.session
    if not session or session.resolved then return false end
    if #session.targets >= MAX_TARGETS then Print("Limite de 40 objetivos alcanzado."); return false end
    local target, err = CaptureUnit("target")
    if not target then Print(err); return false end
    for _, existing in ipairs(session.targets) do
        if existing.guid == target.guid then Print("Ese objetivo ya esta marcado."); return false end
    end
    session.targets[#session.targets + 1] = target
    RefreshFrame()
    return true
end

function API.RemoveTarget(guid)
    local session = S.session
    if not session or session.resolved then return false end
    for i, target in ipairs(session.targets) do
        if target.guid == guid then table.remove(session.targets, i); RefreshFrame(); return true end
    end
    return false
end

local function RollComponents(definition)
    local rolled, details = {}, {}
    for _, component in ipairs(definition.damageComponents) do
        local count, sides = HarfordDnDWeapons.ParseDice(component.damageDice)
        local values, amount = {}, component.damageBonus
        for _ = 1, count do
            local value = HarfordDnDCalc.RollDie(sides)
            values[#values + 1] = value
            amount = amount + value
        end
        rolled[#rolled + 1] = {
            amount = math.max(0, amount),
            maximum = math.max(0, count * sides + component.damageBonus),
            damageType = component.damageType,
        }
        local bonus = component.damageBonus ~= 0 and ((component.damageBonus > 0 and "+" or "") .. component.damageBonus) or ""
        details[#details + 1] = component.damageDice .. bonus .. " " .. DamageLabel(component.damageType)
            .. ": " .. table.concat(values, "+")
    end
    return rolled, table.concat(details, " | ")
end

local function PruneProcessed()
    local now = Now()
    for key, entry in pairs(S.processed) do
        if not entry.expires or entry.expires <= now then S.processed[key] = nil end
    end
end

local function BroadcastInfo(label, responseTarget)
    local roll = { type = "info", label = label }
    HarfordDnDRolls.Broadcast(roll)
    if responseTarget and responseTarget ~= "" and HarfordSync and HarfordSync.BestChannel
        and not HarfordSync.BestChannel() and HarfordDnDRolls.Serialize then
        HarfordSync.Send(PREFIX, HarfordDnDRolls.Serialize(roll), "WHISPER", responseTarget)
    end
end

local function ApplyComponents(unit, request, affected, critical)
    if not affected then return 0, {} end
    local total, summaries = 0, {}
    for _, component in ipairs(request.components or {}) do
        local amount = critical and component.maximum or component.amount
        if request.mode == "save" and request.saved then
            amount = request.success == "half" and math.floor(amount / 2) or 0
        end
        local applied, _status, marker = amount, nil, ""
        if amount > 0 and HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
            applied, _status, marker = HarfordDamageMitigation.ForTarget(unit, component.damageType, amount)
        end
        total = total + (tonumber(applied) or 0)
        summaries[#summaries + 1] = tostring(applied or 0) .. " " .. DamageLabel(component.damageType)
            .. (marker and marker ~= "" and (" " .. marker) or "")
    end
    return total, summaries
end

-- ¿Prende el efecto (aura/condicion) del area sobre la victima? Impacto en ataque, fallo en salvacion.
local function AreaEffectLands(mode, status)
    return mode == "attack" and status == "hit" or mode == "save" and status == "failed" or mode == "auto"
end

-- Opts de condicion derivados del request de area; compartido por la ruta jugador y la NPC
-- (solo cambia el nombre de fuente: el sender en jugador, el sourceName del request en NPC).
local function ConditionOptsFromRequest(request, sourceName)
    return {
        sourceGuid = request.sourceGuid,
        sourceName = sourceName,
        duration = request.conditionDuration,
        turns = request.conditionTurns,
        saveAbility = request.conditionSaveAbility,
        saveDC = request.conditionSaveDC,
        persist = request.conditionPersist == true,
    }
end

-- Linea de resultado por victima: "<nombre> <label>: <rollText> EXITO/FALLO [- daño]".
-- Compartida por la ruta jugador y la NPC.
local function FormatVictimResult(name, request, status, applied, summaries, rollText)
    local result = (status == "saved" or status == "hit") and "|cff00ff00EXITO|r" or "|cffff3333FALLO|r"
    return string.format("%s %s: %s %s%s", name, request.label, rollText or "", result,
        (applied or 0) > 0 and (" - " .. table.concat(summaries, " + ")) or "")
end

local function PlayerResultLabel(request, status, total, summaries, rollText)
    local name = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("player"))
        or UnitName("player") or "Jugador"
    return FormatVictimResult(name, request, status, total, summaries, rollText)
end

local function ResolvePlayerRequest(request, sender)
    local cacheKey = tostring(sender or "") .. "|" .. request.id
    PruneProcessed()
    local cached = S.processed[cacheKey]
    if cached then
        if sender and sender ~= "" then HarfordSync.SendAreaResult(PREFIX, sender, cached.result) end
        return true, cached.result
    end

    local affected, status, rollText, critical = false, "invalid", "", false
    if request.mode == "save" then
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(request.ability)
        local autoFail = HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
            and HarfordDnDConditions.IsSaveAutoFailed("player", request.ability)
        local mode = HarfordDnDCalc.GetMode()
        if HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode then
            mode = HarfordDnDConditions.ResolveRollMode(mode, "save", { actorUnit = "player", ability = request.ability })
        end
        local die = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(mode))
        local total = die + (tonumber(base) or 0) + (tonumber(prof) or 0)
        request.saved = not autoFail and total >= request.dc
        affected = not request.saved or request.success == "half"
        status = request.saved and "saved" or "failed"
        rollText = string.format("Salv %s: %d (%d%+d%+d vs CD %d)", request.ability, total, die,
            tonumber(base) or 0, tonumber(prof) or 0, request.dc)
    elseif request.mode == "auto" then
        -- Auto-impacto (tipo Proyectil Magico): sin tirada, siempre afecta.
        affected, status, rollText = true, "hit", "Impacto automatico"
    else
        local armorClass = HarfordDnDCombat.ComputeSelfArmorClass()
        critical = request.critical == "critical"
        local hit = critical or (request.critical ~= "fumble" and request.attackTotal > armorClass)
        affected = hit
        status = hit and "hit" or "miss"
        rollText = string.format("Ataque %d vs CA %d", request.attackTotal, armorClass)
    end

    local applied, summaries = ApplyComponents("player", request, affected, critical)
    if applied > 0 and HarfordDnDStore.ApplyLocalResourceDamage then
        HarfordDnDStore.ApplyLocalResourceDamage(applied)
        if HarfordDnDCombat and HarfordDnDCombat.PlayLocalWound then HarfordDnDCombat.PlayLocalWound(critical) end
    elseif request.mode == "attack" and status == "miss" and HarfordDnDCombat and HarfordDnDCombat.PlayLocalDefense then
        HarfordDnDCombat.PlayLocalDefense()
    end
    if AreaEffectLands(request.mode, status) then
        if request.conditionId ~= "" and HarfordDnDConditions then
            local appliedCondition = HarfordDnDConditions.ApplyOwned(request.conditionId,
                ConditionOptsFromRequest(request, sender))
            if appliedCondition and HarfordDnDConditions.PublishOwnedCondition then
                HarfordDnDConditions.PublishOwnedCondition(request.conditionId, "apply")
            end
        elseif request.auraId > 0 and HarfordAuras then
            HarfordAuras.ApplyById(request.auraId, "self", { addonName = "Harford" })
        end
    end

    local label = PlayerResultLabel(request, status, applied, summaries, rollText)
    BroadcastInfo(label, sender)
    -- La linea completa ya se publica como tirada. El ACK queda deliberadamente minimo
    -- para no desbordar SendAddonMessage con colores/nombres largos.
    local result = { id = request.id, status = status, applied = applied, label = "" }
    S.processed[cacheKey] = { expires = Now() + REQUEST_TTL, result = result }
    if sender and sender ~= "" then HarfordSync.SendAreaResult(PREFIX, sender, result) end
    return true, result
end

local function ValidateIncomingRequest(request)
    if type(request) ~= "table" or type(request.components) ~= "table" then return false end
    -- Sin componentes de daño solo es valido si trae condicion (conjuro de control puro).
    if #request.components == 0 and not (request.conditionId and request.conditionId ~= "") then return false end
    if request.mode == "save" then
        local validAbility = {
            Fuerza = true, Destreza = true, Constitucion = true,
            Inteligencia = true, Sabiduria = true, Carisma = true,
        }
        if not validAbility[request.ability] or request.dc < 1 or request.dc > 99 then return false end
    elseif request.mode ~= "attack" and request.mode ~= "auto" then
        return false
    end
    for _, component in ipairs(request.components) do
        if not (HarfordDamageTypes and HarfordDamageTypes.Exists and HarfordDamageTypes.Exists(component.damageType)) then
            return false
        end
        if component.amount < 0 or component.amount > 10000 or component.maximum < 0 or component.maximum > 10000 then
            return false
        end
    end
    if request.conditionId and request.conditionId ~= "" then
        if not (HarfordDnDConditions and HarfordDnDConditions.GetDefinition
            and HarfordDnDConditions.GetDefinition(request.conditionId)) then return false end
        if not CONDITION_DURATIONS[request.conditionDuration or "manual"] then return false end
        if request.conditionDuration == "rounds" and (tonumber(request.conditionTurns) or 0) <= 0 then return false end
        if request.conditionDuration == "save_at_turn_end"
            and (not CanonicalAbility(request.conditionSaveAbility) or (tonumber(request.conditionSaveDC) or 0) <= 0) then
            return false
        end
        if request.sourceGuid and request.sourceGuid ~= ""
            and (#request.sourceGuid > 64 or not request.sourceGuid:match("^[%w%-]+$")) then return false end
    end
    return true
end

function API.HandleRequest(message, sender)
    if not (HarfordSync and HarfordSync.DeserializeAreaRequest) then return false end
    local request = HarfordSync.DeserializeAreaRequest(message)
    if not request then return false end
    if not ValidateIncomingRequest(request) then
        if sender and sender ~= "" then
            HarfordSync.SendAreaResult(PREFIX, sender, { id = request.id, status = "invalid", applied = 0 })
        end
        return true
    end
    ResolvePlayerRequest(request, sender)
    return true
end

function API.HandleResult(message, sender)
    if not (HarfordSync and HarfordSync.DeserializeAreaResult) then return false end
    local result = HarfordSync.DeserializeAreaResult(message)
    if not result then return false end
    local session = S.session
    if not session then return true end
    for _, target in ipairs(session.targets or {}) do
        if target.requestId == result.id then
            local expected = target.unitName or ""
            local actual = tostring(sender or "")
            local expectedShort = Ambiguate and Ambiguate(expected, "short") or expected:match("^[^%-]+") or expected
            local actualShort = Ambiguate and Ambiguate(actual, "short") or actual:match("^[^%-]+") or actual
            if expected ~= "" and actual ~= expected and actualShort ~= expectedShort then return true end
            target.status = result.status .. " (" .. tostring(result.applied) .. ")"
            target.result = result
            break
        end
    end
    RefreshFrame()
    return true
end

local function MakeRequest(session, target, index)
    local request = {
        -- El turno entra en el id para que la re-resolucion de zona NO sea deduplicada por el receptor.
        id = session.id .. "." .. tostring(session.turn or 1) .. "." .. tostring(index),
        mode = session.definition.resolution,
        ability = session.definition.saveAbility,
        dc = session.definition.dc,
        success = session.definition.success,
        auraId = session.definition.auraId,
        conditionId = session.definition.conditionId,
        conditionDuration = session.definition.conditionDuration,
        conditionTurns = session.definition.conditionTurns,
        conditionSaveAbility = session.definition.conditionSaveAbility,
        conditionSaveDC = session.definition.conditionSaveDC,
        conditionPersist = session.definition.conditionPersist,
        sourceGuid = session.context.sourceGuid,
        sourceName = session.context.sourceName,
        label = session.definition.networkLabel,
        components = session.rolledComponents,
    }
    if request.mode == "attack" then
        local chosen, dieA, dieB, critTag = HarfordDnDCalc.RollD20Full("attack", {
            actorGuid = session.context.sourceGuid,
            actorConditionIds = session.sourceConditionIds,
            targetGuid = target.guid,
            targetConditionIds = target.conditionIds,
            attackRange = session.definition.attackRange or "ranged",
        })
        local die = chosen
        request.attackTotal = die + session.definition.attackBonus
        request.critical = HarfordDnDCombat.IsCriticalRollTag(critTag) and "critical"
            or critTag == "PIFIA" and "fumble" or "normal"
        target.attackDie = die
    end
    return request
end

-- Anuncia UNA sola tirada de daño BASE del area (los dados se tiran una vez para todas las
-- victimas). El numero aplicado a cada victima se publica por separado en su `BroadcastInfo`
-- y puede diferir del base: salvacion superada (mitad/nada), critico de ataque (maximo) y
-- resistencias/inmunidades/vulnerabilidades por tipo. No leer este total como el daño final.
local function BroadcastSharedRoll(session, details)
    local first = session.rolledComponents[1]
    local modifiers = DamageLabel(first.damageType)
    for i = 2, #session.rolledComponents do
        local c = session.rolledComponents[i]
        modifiers = modifiers .. " |cff66ccff" .. tostring(c.amount) .. "|r " .. DamageLabel(c.damageType)
    end
    HarfordDnDRolls.Broadcast({
        type = "damage",
        label = session.definition.label .. " (" .. ShapeText(session.definition) .. ")",
        total = first.amount,
        dice = details,
        modifiers = modifiers,
    })
end

function API.Resolve()
    local session = S.session
    if not session or session.resolved or #session.targets == 0 then return false end
    -- El coste (onCommit) se paga UNA sola vez; las re-resoluciones de zona (RepeatTurn) no.
    if not session.committed and type(session.context.onCommit) == "function" then
        local ok, err = session.context.onCommit(session.definition)
        if ok == false then Print(err or "No se pudo consumir el uso o recurso."); return false end
    end
    session.committed = true
    session.resolved = true
    session.rolledComponents, session.rollDetails = RollComponents(session.definition)
    -- Condicion pura (sin daño): no hay tirada de daño compartida que anunciar.
    if #session.rolledComponents > 0 then BroadcastSharedRoll(session, session.rollDetails) end
    session.pendingNpc, session.pendingNpcIndex = {}, 1

    for index, target in ipairs(session.targets) do
        local request = MakeRequest(session, target, index)
        target.requestId = request.id
        if target.kind == "player" then
            if target.guid == (UnitGUID and UnitGUID("player")) then
                local _ok, result = ResolvePlayerRequest(request, nil)
                target.status = result and (result.status .. " (" .. tostring(result.applied) .. ")") or "Error"
                target.result = result
            elseif target.unitName and target.unitName ~= "" then
                local ok, err = HarfordSync.SendAreaRequest(PREFIX, target.unitName, request)
                target.status = ok and "Esperando" or "Error"
                if not ok then target.error = err end
                if ok and C_Timer and C_Timer.After then
                    local sessionId, requestId = session.id, request.id
                    C_Timer.After(RESPONSE_TIMEOUT, function()
                        local current = S.session
                        if not current or current.id ~= sessionId then return end
                        for _, item in ipairs(current.targets or {}) do
                            if item.requestId == requestId and item.status == "Esperando" then
                                item.status = "Sin confirmar"
                                RefreshFrame()
                                break
                            end
                        end
                    end)
                end
            else
                target.status = "Sin nombre"
            end
        else
            target.status = "Pendiente"
            session.pendingNpc[#session.pendingNpc + 1] = { target = target, request = request }
        end
    end
    RefreshFrame()
    API.TryResolvePendingNpc()
    return true
end

-- Zona persistente (Nube de Dagas, invocaciones): nuevo turno -> re-marcar quien sigue dentro y
-- re-aplicar daño SIN volver a pagar mana (gate `committed`). Avanza el turno para ids frescos.
function API.RepeatTurn()
    local session = S.session
    if not (session and session.zone and session.resolved) then return false end
    session.turn = (session.turn or 1) + 1
    session.resolved = false
    session.pendingNpc, session.pendingNpcIndex = {}, 1
    for _, target in ipairs(session.targets or {}) do
        target.status, target.result, target.requestId = "Marcado", nil, nil
    end
    RefreshFrame()
    Print("Zona turno " .. tostring(session.turn) .. ": re-marca las victimas dentro y pulsa Resolver.")
    return true
end

local function ResolveNpcEntry(entry)
    local request, target = entry.request, entry.target
    local affected, status, rollText, critical = false, "invalid", "", false
    if request.mode == "save" then
        local bonus = HarfordDnDCombat.GetSaveBonusForUnit("target", request.ability)
        local autoFail = HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
            and HarfordDnDConditions.IsSaveAutoFailed("target", request.ability)
        local mode = HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode
            and HarfordDnDConditions.ResolveRollMode("normal", "save", { actorUnit = "target", ability = request.ability }) or "normal"
        local die = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(mode))
        local total = die + bonus
        request.saved = not autoFail and total >= request.dc
        affected = not request.saved or request.success == "half"
        status = request.saved and "saved" or "failed"
        rollText = string.format("Salv %s: %d (%d%+d vs CD %d)", request.ability, total, die, bonus, request.dc)
    elseif request.mode == "auto" then
        affected, status, rollText = true, "hit", "Impacto automatico"
    else
        critical = request.critical == "critical"
        local critTag = critical and "CRITICO" or request.critical == "fumble" and "PIFIA" or ""
        local armorClass, hit = HarfordDnDCombat.ResolveArmorClassOutcome(request.attackTotal, critTag, "target")
        affected = hit == true
        status = affected and "hit" or "miss"
        rollText = string.format("Ataque %d vs CA %s", request.attackTotal, tostring(armorClass or "?"))
    end
    local applied, summaries = ApplyComponents("target", request, affected, critical)
    if applied > 0 and not HarfordDnDCombat.ApplyWeaponDamageToNpc(applied, critical) then
        target.status = "No aplicado"
        Print("No se pudo modificar la vida del NPC seleccionado.")
        return false
    end
    if AreaEffectLands(request.mode, status) then
        if request.conditionId ~= "" and HarfordDnDConditions then
            local ok, err = HarfordDnDConditions.ApplyToUnit("target", request.conditionId,
                ConditionOptsFromRequest(request, request.sourceName))
            if not ok then Print(err == "immune" and (target.name .. " es inmune a la condicion.") or tostring(err)) end
        elseif request.auraId > 0 and HarfordAuras then
            HarfordAuras.ApplyById(request.auraId, "npc", { addonName = "Harford" })
        end
    end
    BroadcastInfo(FormatVictimResult(target.name, request, status, applied, summaries, rollText))
    target.status = status .. " (" .. tostring(applied) .. ")"
    return true
end

function API.TryResolvePendingNpc()
    local session = S.session
    if not session or not session.resolved then return false end
    local entry = session.pendingNpc and session.pendingNpc[session.pendingNpcIndex or 1]
    if not entry then RefreshFrame(); return false end
    if not (UnitExists and UnitExists("target") and not (UnitIsPlayer and UnitIsPlayer("target")) and UnitGUID) then
        RefreshFrame(); return false
    end
    if UnitGUID("target") ~= entry.target.guid then RefreshFrame(); return false end
    if not ResolveNpcEntry(entry) then RefreshFrame(); return false end
    session.pendingNpcIndex = (session.pendingNpcIndex or 1) + 1
    RefreshFrame()
    return true
end

function API.SkipPendingNpc()
    local session = S.session
    if not session or not session.pendingNpc then return false end
    local entry = session.pendingNpc[session.pendingNpcIndex or 1]
    if not entry then return false end
    entry.target.status = "Omitido"
    session.pendingNpcIndex = (session.pendingNpcIndex or 1) + 1
    RefreshFrame()
    API.TryResolvePendingNpc()
    return true
end

function API.Cancel()
    S.session = nil
    if S.frame then S.frame:Hide() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
    if S.session then
        RefreshFrame()
        if S.session.resolved then API.TryResolvePendingNpc() end
    end
end)
