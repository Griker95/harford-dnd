HarfordAdminUnitMenu = HarfordAdminUnitMenu or {}

local API = HarfordAdminUnitMenu

local MENU_NAME = "HarfordAdminUnitMenuDropDown"
local BUTTON_SIZE = 22
local BUTTON_VISUAL_X = 0
local BUTTON_VISUAL_Y = 1

local dropdown
local buttons = {}
local current = {}

local function Print(message)
    HarfordChat.Print(message)
end

local function IsAllowed()
    return HarfordAuthority
        and HarfordAuthority.CanUseDMTools
        and HarfordAuthority.CanUseDMTools() == true
end

local function UnitExistsSafe(unit)
    return unit and UnitExists and UnitExists(unit)
end

local function GetUnitNameSafe(unit)
    if not UnitExistsSafe(unit) then return nil end
    return HarfordClassColors.UnitFullName(unit)
end

local function GetUnitSnapshot(unit)
    if not UnitExistsSafe(unit) then return nil end
    local isPlayer = UnitIsPlayer and UnitIsPlayer(unit) == true
    -- isSelf: true si la unidad es el propio jugador local (player frame o target propio)
    local isSelf = UnitIsUnit and UnitIsUnit(unit, "player") == true
    return {
        unit     = unit,
        guid     = UnitGUID and UnitGUID(unit) or "",
        name     = GetUnitNameSafe(unit) or "",
        isPlayer = isPlayer,
        isSelf   = isSelf,
    }
end

local function SameUnit(snapshot)
    if not snapshot or not UnitExistsSafe(snapshot.unit) then return false end
    if snapshot.guid and snapshot.guid ~= "" and UnitGUID then
        return UnitGUID(snapshot.unit) == snapshot.guid
    end
    return true
end

local function EnsureAllowed(actionName)
    if IsAllowed() then return true end
    Print(tostring(actionName or "accion") .. " requiere HarfordAdmin y .ph dm activo.")
    return false
end

local function EnsureSameUnit(snapshot, actionName)
    if not EnsureAllowed(actionName) then return false end
    if SameUnit(snapshot) then return true end
    Print("La unidad ya no coincide con el unitframe. Accion cancelada.")
    return false
end


local function PromptNumber(dialogName, text, callback)
    StaticPopupDialogs[dialogName] = StaticPopupDialogs[dialogName] or {
        text = text,
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = true,
        editBoxWidth = 120,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self, data)
            local value = tonumber(self.editBox:GetText())
            if not value then
                Print("Introduce un numero valido.")
                return
            end
            data.callback(value)
        end,
        EditBoxOnEnterPressed = function(self, data)
            local parent = self:GetParent()
            local value = tonumber(self:GetText())
            if not value then
                Print("Introduce un numero valido.")
                return
            end
            data.callback(value)
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }
    StaticPopupDialogs[dialogName].text = text
    StaticPopup_Show(dialogName, nil, nil, { callback = callback })
end

local function AddToTurns(snapshot)
    if not EnsureSameUnit(snapshot, "anadir a turnos") then return end
    if not HarfordTurnOrderAPI or not HarfordTurnOrderAPI.AddUnit then
        Print("La API de turnos no esta disponible.")
        return
    end
    HarfordTurnOrderAPI.AddUnit(snapshot.unit)
end

local function OpenTurns()
    if not EnsureAllowed("abrir turnos") then return end
    if HarfordTurnOrderAPI and HarfordTurnOrderAPI.Toggle then
        HarfordTurnOrderAPI.Toggle()
    else
        Print("La ventana de turnos no esta disponible.")
    end
end

local function SendSheetToTarget(snapshot)
    if not EnsureSameUnit(snapshot, "enviar ficha al target") then return end
    if snapshot.unit ~= "target" or not snapshot.isPlayer then
        Print("Enviar ficha solo esta disponible desde el TargetFrame de un jugador.")
        return
    end
    if not HarfordDnDAPI or not HarfordDnDAPI.BroadcastConfigForPlayer then
        Print("HarfordDnDAPI.BroadcastConfigForPlayer no disponible.")
        return
    end

    local shortName = UnitName and UnitName(snapshot.unit)
    local fullName = (GetUnitName and GetUnitName(snapshot.unit, true)) or shortName or snapshot.name
    local whisperTarget = fullName or shortName
    if not whisperTarget or whisperTarget == "" then
        Print("No se pudo resolver el nombre del target.")
        return
    end

    local ok, err = false, nil
    if shortName and shortName ~= "" then
        ok, err = HarfordDnDAPI.BroadcastConfigForPlayer(shortName, "WHISPER", whisperTarget)
    end
    if not ok and fullName and fullName ~= "" and fullName ~= shortName then
        ok, err = HarfordDnDAPI.BroadcastConfigForPlayer(fullName, "WHISPER", whisperTarget)
    end

    if ok then
        Print("Ficha enviada a " .. tostring(whisperTarget) .. ".")
    else
        Print("No se pudo enviar ficha: " .. tostring(err or "perfil no encontrado"))
    end
end

local function AdjustResourceForName(characterName, resourceKey, delta)
    characterName = tostring(characterName or "")
    resourceKey = tostring(resourceKey or "")
    delta = tonumber(delta) or 0
    if characterName == "" or resourceKey == "" or delta == 0 then
        return false, "ajuste invalido"
    end
    if not (HarfordSync and HarfordSync.SendResourceAdjust) then
        return false, "HarfordSync.SendResourceAdjust no disponible"
    end

    local myShortName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)
    if characterName == myShortName or (myFullName and characterName == myFullName) then
        characterName = myFullName or myShortName
    end
    return HarfordSync.SendResourceAdjust("DND5EARC", resourceKey, delta, characterName)
end


local function AdjustPlayerHealth(snapshot, delta)
    if not EnsureSameUnit(snapshot, "ajustar vida jugador") then return end
    local ok, err = AdjustResourceForName(snapshot.name, "health", delta)
    if not ok then
        Print("No se pudo ajustar vida: " .. tostring(err or "error desconocido"))
    end
end

local function AdjustNpcHealth(snapshot, delta)
    if not EnsureSameUnit(snapshot, "ajustar vida NPC") then return end
    if snapshot.unit ~= "target" then
        Print("La vida de NPC solo se puede modificar desde TargetFrame.")
        return
    end
    if not HarfordServerActions or not HarfordServerActions.SetNpcHealthDelta then
        Print("HarfordServerActions no disponible.")
        return
    end
    local ok, err = HarfordServerActions.SetNpcHealthDelta(delta, { addonName = "HarfordAdmin" })
    if not ok then
        Print("No se pudo ajustar vida NPC: " .. tostring(err or "error desconocido"))
    end
end

-- GUID del ultimo NPC poseido con Ctrl+Click.
-- nil = ningun NPC poseido desde esta sesion.
-- Si el target al hacer Ctrl+Click coincide con este GUID → solo .unposs.
-- Si es distinto → .unposs + .poss y se guarda el nuevo GUID.
local _lastPossessedGuid = nil

local function RepossessNpc(snapshot)
    if not EnsureSameUnit(snapshot, "reposeer NPC") then return end
    if snapshot.unit ~= "target" or snapshot.isPlayer then
        Print("Ctrl + click solo esta disponible sobre un NPC target.")
        return
    end
    if not HarfordServerActions or not HarfordServerActions.RepossessCurrentNpc then
        Print("HarfordServerActions.RepossessCurrentNpc no disponible.")
        return
    end

    _lastPossessedGuid = snapshot.guid
    local ok, err = HarfordServerActions.RepossessCurrentNpc({ addonName = "HarfordAdmin" })
    if not ok then
        _lastPossessedGuid = nil
        Print("No se pudo actualizar la posesion del NPC: " .. tostring(err or "error desconocido"))
    end
end

local function UnpossessNpc()
    if not EnsureAllowed("soltar posesion NPC") then return end
    if not HarfordServerActions or not HarfordServerActions.UnpossessCurrentNpc then
        Print("HarfordServerActions.UnpossessCurrentNpc no disponible.")
        return
    end

    _lastPossessedGuid = nil
    local ok, err = HarfordServerActions.UnpossessCurrentNpc({ addonName = "HarfordAdmin" })
    if not ok then
        Print("No se pudo soltar la posesion: " .. tostring(err or "error desconocido"))
    end
end

local function PromptHealth(snapshot, isPlayer)
    PromptNumber("HARFORD_ADMIN_HEALTH_DELTA", "Cantidad de vida (+/-):", function(value)
        local amount = math.floor(value)
        if amount == 0 then
            Print("La cantidad no puede ser 0.")
            return
        end
        if isPlayer then
            AdjustPlayerHealth(snapshot, amount)
        else
            AdjustNpcHealth(snapshot, amount)
        end
    end)
end

local function ApplyAura(snapshot, applying)
    if not EnsureSameUnit(snapshot, applying and "aplicar aura" or "quitar aura") then return end
    PromptNumber(applying and "HARFORD_ADMIN_APPLY_AURA" or "HARFORD_ADMIN_REMOVE_AURA", "Spell ID:", function(value)
        local spellId = math.floor(value)
        if spellId <= 0 then
            Print("Spell ID invalido.")
            return
        end

        local ok, err
        if snapshot.isSelf then
            -- Jugador propio: ApplyAura/RemoveAuraSelf añaden "self" automáticamente.
            if applying then
                if HarfordServerActions and HarfordServerActions.ApplyAura then
                    ok, err = HarfordServerActions.ApplyAura(spellId, { addonName = "HarfordAdmin" })
                end
            else
                if HarfordServerActions and HarfordServerActions.RemoveAuraSelf then
                    ok, err = HarfordServerActions.RemoveAuraSelf(spellId, { addonName = "HarfordAdmin" })
                end
            end
        elseif snapshot.unit == "target" and HarfordAdminNPC then
            -- NPC seleccionado: HarfordAdminNPC usa "npc set aura/unaura" internamente.
            if applying and HarfordAdminNPC.ApplyAuraToTarget then
                ok, err = HarfordAdminNPC.ApplyAuraToTarget(spellId)
            elseif not applying and HarfordAdminNPC.RemoveAuraFromTarget then
                ok, err = HarfordAdminNPC.RemoveAuraFromTarget(spellId)
            end
        else
            -- Jugador en target (no propio): .aura/.unaura sin sufijo (target actual del servidor).
            if applying then
                if HarfordServerActions and HarfordServerActions.ApplyAuraToCurrentTarget then
                    ok, err = HarfordServerActions.ApplyAuraToCurrentTarget(spellId, { addonName = "HarfordAdmin" })
                end
            else
                if HarfordServerActions and HarfordServerActions.RemoveAura then
                    ok, err = HarfordServerActions.RemoveAura(spellId, { addonName = "HarfordAdmin" })
                end
            end
        end

        if not ok then
            Print(tostring(err or "No se pudo enviar aura."))
        end
    end)
end

local function SetNpcAura(snapshot, spellId)
    if not EnsureSameUnit(snapshot, "aplicar aura NPC") then return end
    if snapshot.unit ~= "target" then
        Print("Las auras NPC solo se pueden aplicar desde TargetFrame.")
        return
    end

    local ok, err
    if HarfordAdminNPC and HarfordAdminNPC.SetAuraOnTarget then
        ok, err = HarfordAdminNPC.SetAuraOnTarget(spellId)
    elseif HarfordServerActions and HarfordServerActions.SetNpcAura then
        ok, err = HarfordServerActions.SetNpcAura(spellId, { addonName = "HarfordAdmin" })
    else
        ok, err = false, "HarfordServerActions.SetNpcAura no disponible"
    end

    if not ok then
        Print("No se pudo aplicar aura NPC: " .. tostring(err or "error desconocido"))
    end
end

local function PromptNpcAura(snapshot)
    PromptNumber("HARFORD_ADMIN_NPC_SET_AURA", "Spell ID:", function(value)
        local spellId = math.floor(value)
        if spellId <= 0 then
            Print("Spell ID invalido.")
            return
        end
        SetNpcAura(snapshot, spellId)
    end)
end

local function ApplyNpcLootAura(snapshot)
    SetNpcAura(snapshot, 140172)
end

-- ─── Auras de estado de MISION de mundo (fuente unica: HarfordWorldQuests) ──────────────────
-- Las 3 auras codifican el estado de la mision del NPC; solo una debe estar activa a la vez.
local function QuestAuraList()
    local wq = _G.HarfordWorldQuests
    return {
        { label = "Disponible", spell = (wq and wq.AURA_AVAILABLE)  or 155096 },
        { label = "Incompleta", spell = (wq and wq.AURA_INCOMPLETE) or 245633 },
        { label = "Completada", spell = (wq and wq.AURA_COMPLETE)   or 252527 },
    }
end

-- Fija el estado de mision del NPC: quita las OTRAS dos auras de estado y aplica la elegida,
-- para que el NPC nunca quede con dos estados de mision a la vez.
local function SetNpcQuestAura(snapshot, spellId)
    -- Guard: si el DM cambio de target tras abrir el menu, los `RemoveAuraFromTarget` (que usan el
    -- target ACTUAL) borrarian auras del NPC equivocado. Abortar si ya no es el mismo NPC.
    if not EnsureSameUnit(snapshot, "cambiar aura de mision") then return end
    if HarfordAdminNPC and HarfordAdminNPC.RemoveAuraFromTarget then
        for _, a in ipairs(QuestAuraList()) do
            if a.spell ~= spellId then HarfordAdminNPC.RemoveAuraFromTarget(a.spell) end
        end
    end
    SetNpcAura(snapshot, spellId)
end

-- Envía un comando Epsilon usando la API disponible (EpsilonCommands → ARC)
local function SendCmd(cmd)
    if not (HarfordEpsilonCommands and HarfordEpsilonCommands.Send) then
        Print("No hay API para enviar: " .. tostring(cmd or ""))
        return false
    end
    local ok, err = HarfordEpsilonCommands.Send(cmd, {
        addonName = "HarfordAdmin",
        forceEpsilon = true,
        showMessages = false,
    })
    if not ok then
        Print("No se pudo enviar comando: " .. tostring(err or "error desconocido"))
    end
    return ok
end

-- .unaura all self (isSelf) o .unaura all (jugador ajeno en target)
local function RemoveAuraAll(snapshot)
    if not EnsureSameUnit(snapshot, "unaura all") then return end
    SendCmd(snapshot.isSelf and "unaura all self" or "unaura all")
    if HarfordDnDConditions and HarfordDnDConditions.RemoveAllFromUnit then
        HarfordDnDConditions.RemoveAllFromUnit(snapshot.unit)
    end
end

-- .npc set unaura all (sobre el target NPC actual)
local function RemoveNpcAuraAll(snapshot)
    if not EnsureSameUnit(snapshot, "unaura all NPC") then return end
    if snapshot.unit ~= "target" then
        Print("Unaura all NPC solo disponible desde TargetFrame.")
        return
    end
    SendCmd("npc set unaura all")
    if HarfordDnDConditions and HarfordDnDConditions.ClearUnitStateRecords then
        HarfordDnDConditions.ClearUnitStateRecords(snapshot.unit)
    end
end

-- Abre el editor de loot para el NPC del snapshot.
local function OpenLootEditor(snapshot)
    if not EnsureSameUnit(snapshot, "abrir editor de loot") then return end
    if not HarfordAdminLoot or not HarfordAdminLoot.OpenEditor then
        Print("HarfordAdminLoot.OpenEditor no disponible.")
        return
    end
    HarfordAdminLoot.OpenEditor()
end

local function AddTitle(text, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
end

local function AddAction(text, func, level, tooltipTitle, tooltipText)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.notCheckable = true
    info.func = func
    info.tooltipTitle = tooltipTitle
    info.tooltipText = tooltipText
    UIDropDownMenu_AddButton(info, level)
end

local function AddSubmenu(text, menuList, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.notCheckable = true
    info.hasArrow = true
    info.menuList = menuList
    UIDropDownMenu_AddButton(info, level)
end

-- Los 39 estados en plano eran ilegibles: un submenu por categoria del catalogo. La menuList
-- lleva la categoria dentro ("ESTADOS:manual") y el dispatcher la desempaqueta.
local function AddEstadoSubmenus(level)
    local categorias = HarfordDnDConditions and HarfordDnDConditions.CATEGORIES
    if type(categorias) ~= "table" or #categorias == 0 then
        AddSubmenu("Estados", "ESTADOS", level)
        return
    end
    for _, cat in ipairs(categorias) do
        AddSubmenu("Estados: " .. tostring(cat.label), "ESTADOS:" .. tostring(cat.id), level)
    end
end

-- Devolverle a un jugador lo que gasto este turno. Lo aplica SU cliente --es quien lleva su
-- economia-- asi que esto solo manda el aviso: escribirle el contador desde fuera daria dos
-- verdades distintas sobre lo mismo.
local function BuildDevolverSubmenu(snapshot, level)
    local nombre = snapshot and snapshot.name
    if not (nombre and nombre ~= "") then return end
    local OPCIONES = {
        { kind = "action",    etiqueta = "Accion" },
        { kind = "bonus",     etiqueta = "Accion adicional" },
        { kind = "reaction",  etiqueta = "Reaccion" },
        { kind = "movement",  etiqueta = "Movimiento" },
    }
    for _, o in ipairs(OPCIONES) do
        AddAction(o.etiqueta, function()
            local payload = HarfordSync and HarfordSync.SerializeTurnRefund
                and HarfordSync.SerializeTurnRefund(o.kind)
            if not payload then return end
            HarfordSync.Send("DND5EARC", payload, "WHISPER", nombre)
            Print("Devuelto a " .. tostring(nombre) .. ": " .. o.etiqueta:lower() .. ".")
        end, level)
    end
end

-- Con categoria: solo los estados de esa categoria (el catalogo core las declara). Sin ella,
-- la lista completa, que queda como fallback si el catalogo no trae categorias.
local function BuildEstadosSubmenu(snapshot, level, categoryId)
    local definitions
    if categoryId and HarfordDnDConditions and HarfordDnDConditions.GetDefinitionsForCategory then
        definitions = HarfordDnDConditions.GetDefinitionsForCategory(categoryId)
    else
        definitions = HarfordDnDConditions and HarfordDnDConditions.GetDefinitions
            and HarfordDnDConditions.GetDefinitions() or {}
    end
    for _, estado in ipairs(definitions) do
        local activo = HarfordAdminConditions and HarfordAdminConditions.Has
            and HarfordAdminConditions.Has(snapshot, estado.id)
        local label = (activo and "[x] " or "[ ] ") .. estado.label
        AddAction(label, function()
            if not HarfordAdminConditions then Print("HarfordAdminConditions no disponible."); return end
            HarfordAdminConditions.Toggle(snapshot, estado.id)
        end, level, estado.label, estado.description)
    end
end


local function BuildNpcSubmenu(menuList, level)
    local snapshot = current.snapshot
    if menuList == "TURNOS" then
        AddAction("Anadir a turnos", function() AddToTurns(snapshot) end, level)
        AddAction("Abrir turnos", OpenTurns, level)
    elseif menuList == "RECURSOS" then
        -- Mod. Recursos: sin implementacion para NPC de momento
        AddAction("Mod. Salud",    function() PromptHealth(snapshot, false) end, level)
        AddAction("Mod. Recursos", function() end, level)
    elseif menuList == "AURAS" then
        AddAction("Aura",       function() PromptNpcAura(snapshot) end, level)
        AddAction("Unaura",     function() ApplyAura(snapshot, false) end, level)
        AddAction("Unaura all", function() RemoveNpcAuraAll(snapshot) end, level)
        AddEstadoSubmenus(level)
    elseif menuList == "ESTADOS" or (type(menuList) == "string" and menuList:find("^ESTADOS:")) then
        BuildEstadosSubmenu(snapshot, level, type(menuList) == "string" and menuList:match("^ESTADOS:(.+)$") or nil)
    elseif menuList == "LOOT" then
        AddAction("Loot Aura", function() ApplyNpcLootAura(snapshot) end, level)
        AddAction("Cargar loot...", function() OpenLootEditor(snapshot) end, level)
    elseif menuList == "MISIONES" then
        -- Elegir el estado de mision del NPC (aura). Solo una activa; fija la elegida y quita las otras.
        for _, a in ipairs(QuestAuraList()) do
            AddAction(a.label, function() SetNpcQuestAura(snapshot, a.spell) end, level)
        end
    end
end

-- ─── Editor de recursos ────────────────────────────────────────────────────

local resourceEditorFrame = nil
local resourceEditorName  = nil
local resourceEditorRefreshToken = 0

-- ORDER completo con temp_health insertada después de health
local function GetResOrderFull()
    if not (HarfordDnDResources and HarfordDnDResources.ORDER) then return {} end
    local t = {}
    for _, k in ipairs(HarfordDnDResources.ORDER) do
        t[#t+1] = k
        if k == "health" then t[#t+1] = "temp_health" end
    end
    return t
end

local function GetResourcesSnapshot(name)
    if not (HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName) then return nil end
    local tbl = HarfordDnDAPI.GetResourcesForName(name)
    if not tbl then return nil end
    local snap = {}
    local defs = HarfordDnDResources and HarfordDnDResources.DEFS or {}
    for key in pairs(defs) do
        local cur = tonumber(tbl["Res_" .. key .. "_Cur"]) or 0
        local max = tonumber(tbl["Res_" .. key .. "_Max"]) or 0
        snap[key] = { cur = cur, max = max }
    end
    return snap
end

local function QueueResourceEditorPopulate(frame, expectedName)
    if not (C_Timer and C_Timer.After) then
        local snap = GetResourcesSnapshot(expectedName)
        if snap and frame and frame.PopulateRows then frame:PopulateRows(snap) end
        return
    end
    resourceEditorRefreshToken = resourceEditorRefreshToken + 1
    local token = resourceEditorRefreshToken
    expectedName = tostring(expectedName or "")
    C_Timer.After(1.5, function()
        if token ~= resourceEditorRefreshToken then return end
        if not (frame and frame:IsShown() and resourceEditorName == expectedName) then return end
        local snap = GetResourcesSnapshot(expectedName)
        if snap then frame:PopulateRows(snap) end
    end)
end

local function CreateResourceEditorFrame()
    local RES_ORDER = GetResOrderFull()
    local ROWS      = #RES_ORDER
    local ROW_H     = 22
    local W         = 320
    local H         = 50 + 18 + ROWS * ROW_H + 10 + 36 + 10

    local f = CreateFrame("Frame", "HarfordAdminResourceEditor", UIParent, "BackdropTemplate")
    f:SetSize(W, H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(500)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- Título
    f.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.titleText:SetPoint("TOP", f, "TOP", 0, -14)
    f.titleText:SetText("Recursos")

    -- Botón cerrar
    local closeX = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeX:SetScript("OnClick", function() f:Hide() end)

    -- Cabeceras de columna
    local HDR_Y = -38
    local colLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colLbl:SetPoint("TOPLEFT", f, "TOPLEFT", 14, HDR_Y)
    colLbl:SetSize(130, 16); colLbl:SetJustifyH("LEFT"); colLbl:SetText("Recurso")

    local colCur = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colCur:SetPoint("TOPLEFT", f, "TOPLEFT", 152, HDR_Y)
    colCur:SetSize(60, 16); colCur:SetJustifyH("CENTER"); colCur:SetText("Actual")

    local colMax = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colMax:SetPoint("TOPLEFT", f, "TOPLEFT", 224, HDR_Y)
    colMax:SetSize(60, 16); colMax:SetJustifyH("CENTER"); colMax:SetText("Máximo")

    -- Línea separadora
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 14, HDR_Y - 14)
    line:SetSize(W - 28, 1)
    line:SetColorTexture(0.5, 0.4, 0.2, 0.7)

    -- Filas
    f.rows = {}
    local ROW_Y0 = HDR_Y - 18
    for i, key in ipairs(RES_ORDER) do
        local def   = HarfordDnDResources and HarfordDnDResources.DEFS and HarfordDnDResources.DEFS[key]
        local label = def and def.label or key
        local color = def and def.color or {1, 1, 1}
        local y     = ROW_Y0 - (i - 1) * ROW_H

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT", 14, y)
        lbl:SetSize(130, ROW_H)
        lbl:SetJustifyH("LEFT"); lbl:SetJustifyV("MIDDLE")
        lbl:SetText(label)
        lbl:SetTextColor(color[1], color[2], color[3])

        local curBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        curBox:SetSize(55, 18)
        curBox:SetPoint("TOPLEFT", f, "TOPLEFT", 152, y - 2)
        curBox:SetAutoFocus(false)
        curBox:SetNumeric(true)
        curBox:SetMaxLetters(6)
        curBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        local sep = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sep:SetPoint("TOPLEFT", f, "TOPLEFT", 212, y)
        sep:SetSize(8, ROW_H); sep:SetJustifyH("CENTER"); sep:SetJustifyV("MIDDLE")
        sep:SetText("/")

        local maxBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        maxBox:SetSize(55, 18)
        maxBox:SetPoint("TOPLEFT", f, "TOPLEFT", 224, y - 2)
        maxBox:SetAutoFocus(false)
        maxBox:SetNumeric(true)
        maxBox:SetMaxLetters(6)
        maxBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        f.rows[key] = { lbl = lbl, curBox = curBox, maxBox = maxBox, baseCur = 0, baseMax = 0 }
    end

    -- PopulateRows: carga los valores en los campos y guarda base para delta
    function f:PopulateRows(snap)
        for _, key in ipairs(RES_ORDER) do
            local row = self.rows[key]
            local data = snap and snap[key]
            if row and data then
                row.baseCur = data.cur
                row.baseMax = data.max
                row.curBox:SetText(tostring(data.cur))
                row.maxBox:SetText(tostring(data.max))
                local active = data.max > 0 or (key == "temp_health" and data.cur > 0)
                local a = active and 1.0 or 0.45
                row.lbl:SetAlpha(a); row.curBox:SetAlpha(a); row.maxBox:SetAlpha(a)
            end
        end
    end

    -- Botones inferiores
    local btnRefresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnRefresh:SetSize(88, 22)
    btnRefresh:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    btnRefresh:SetText("Refrescar")
    btnRefresh:SetScript("OnClick", function()
        if not resourceEditorName then return end
        if HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName then
            HarfordDnDAPI.RequestResourcesForName(resourceEditorName)
        end
        -- Repoblar ~1.5s después para dar tiempo a que llegue la respuesta de red
        QueueResourceEditorPopulate(f, resourceEditorName)
    end)

    local btnApply = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnApply:SetSize(88, 22)
    btnApply:SetPoint("BOTTOM", f, "BOTTOM", 0, 14)
    btnApply:SetText("Aplicar")
    btnApply:SetScript("OnClick", function()
        if not resourceEditorName then return end
        local sent = 0
        for _, key in ipairs(RES_ORDER) do
            local row = f.rows[key]
            if row then
                local newCur = tonumber(row.curBox:GetText()) or row.baseCur
                local newMax = tonumber(row.maxBox:GetText()) or row.baseMax
                local dCur = newCur - row.baseCur
                local dMax = newMax - row.baseMax
                if dCur ~= 0 then
                    AdjustResourceForName(resourceEditorName, "Res_" .. key .. "_Cur", dCur)
                    row.baseCur = newCur
                    sent = sent + 1
                end
                if dMax ~= 0 then
                    AdjustResourceForName(resourceEditorName, "Res_" .. key .. "_Max", dMax)
                    row.baseMax = newMax
                    sent = sent + 1
                end
            end
        end
        Print(sent > 0
            and ("Recursos enviados (" .. tostring(sent) .. " cambio(s)).")
            or "Sin cambios.")
    end)

    local btnClose = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnClose:SetSize(88, 22)
    btnClose:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 14)
    btnClose:SetText("Cerrar")
    btnClose:SetScript("OnClick", function() f:Hide() end)

    f:Hide()
    return f
end

local function OpenResourceEditor(snapshot)
    if not EnsureSameUnit(snapshot, "editar recursos") then return end
    -- Permitir jugador propio (isSelf) o target jugador; bloquear NPC sin isPlayer
    if not snapshot.isPlayer then
        Print("Editar recursos solo disponible para jugadores.")
        return
    end

    resourceEditorFrame = resourceEditorFrame or CreateResourceEditorFrame()
    local f = resourceEditorFrame

    local shortName = UnitName and UnitName(snapshot.unit)
    local newName = shortName or snapshot.name

    -- Toggle: si el frame ya está abierto para este mismo target, cerrarlo
    if f:IsShown() and resourceEditorName == newName then
        f:Hide()
        return
    end

    resourceEditorName = newName
    f.titleText:SetText("Recursos: " .. tostring(resourceEditorName or "target"))
    if not f:IsShown() then f:SetPoint("CENTER") end

    local snap = GetResourcesSnapshot(resourceEditorName)
    if snap then
        f:PopulateRows(snap)
    else
        -- Sin caché: solicitar y mostrar ceros temporalmente
        if HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName then
            HarfordDnDAPI.RequestResourcesForName(resourceEditorName)
        end
        local empty = {}
        if HarfordDnDResources and HarfordDnDResources.DEFS then
            for key in pairs(HarfordDnDResources.DEFS) do
                empty[key] = { cur = 0, max = 0 }
            end
        end
        f:PopulateRows(empty)
        QueueResourceEditorPopulate(f, resourceEditorName)
    end
    f:Show()
end

-- ─── Fin editor de recursos ─────────────────────────────────────────────────

-- Submenú para jugador ajeno (target jugador, no el propio)
local function BuildPlayerSubmenu(menuList, level)
    local snapshot = current.snapshot
    if menuList == "PROFESIONES" then
        -- Enseñar una receta worldLearned (los remates a skill 300). El gate de DM lo aplica
        -- HarfordProfessions.TeachRecipe; aqui solo se listan y se revalida la unidad.
        local teachables = HarfordProfessions and HarfordProfessions.GetTeachableRecipes
            and HarfordProfessions.GetTeachableRecipes() or {}
        if #teachables == 0 then
            AddAction("(sin recetas enseñables)", function() end, level)
        end
        for _, recipe in ipairs(teachables) do
            local recipeId, recipeName = recipe.id, recipe.name
            AddAction("Enseñar: " .. tostring(recipeName), function()
                if not EnsureSameUnit(snapshot, "enseñar receta") then return end
                HarfordProfessions.TeachRecipe(snapshot.name, recipeId)
            end, level)
        end
    elseif menuList == "TURNOS" then
        AddAction("Anadir a turnos", function() AddToTurns(snapshot) end, level)
        AddAction("Abrir turnos", OpenTurns, level)
        AddSubmenu("Devolver", "TURNOS_DEVOLVER", level)
    elseif menuList == "TURNOS_DEVOLVER" then
        BuildDevolverSubmenu(snapshot, level)
    elseif menuList == "RECURSOS" then
        AddAction("Mod. Salud", function() PromptHealth(snapshot, true) end, level)
        AddAction("Mod. Recursos", function() OpenResourceEditor(snapshot) end, level)
    elseif menuList == "AURAS" then
        AddAction("Aura",       function() ApplyAura(snapshot, true) end, level)
        AddAction("Unaura",     function() ApplyAura(snapshot, false) end, level)
        AddAction("Unaura all", function() RemoveAuraAll(snapshot) end, level)
        AddEstadoSubmenus(level)
    elseif menuList == "ESTADOS" or (type(menuList) == "string" and menuList:find("^ESTADOS:")) then
        BuildEstadosSubmenu(snapshot, level, type(menuList) == "string" and menuList:match("^ESTADOS:(.+)$") or nil)
    end
    -- Loot no aplica a jugadores: solo aparece en el menu de NPC
end

-- Submenú para el jugador propio (player frame)
local function BuildSelfSubmenu(menuList, level)
    local snapshot = current.snapshot
    if menuList == "TURNOS" then
        AddAction("Anadir a turnos", function() AddToTurns(snapshot) end, level)
        AddAction("Abrir turnos", OpenTurns, level)
    elseif menuList == "RECURSOS" then
        AddAction("Mod. Salud", function() PromptHealth(snapshot, true) end, level)
        AddAction("Mod. Recursos", function() OpenResourceEditor(snapshot) end, level)
    elseif menuList == "AURAS" then
        AddAction("Aura",       function() ApplyAura(snapshot, true) end, level)
        AddAction("Unaura",     function() ApplyAura(snapshot, false) end, level)
        AddAction("Unaura all", function() RemoveAuraAll(snapshot) end, level)
        AddEstadoSubmenus(level)
    elseif menuList == "ESTADOS" or (type(menuList) == "string" and menuList:find("^ESTADOS:")) then
        BuildEstadosSubmenu(snapshot, level, type(menuList) == "string" and menuList:match("^ESTADOS:(.+)$") or nil)
    end
end

function API.BuildNpcMenu(unit)
    local snapshot = GetUnitSnapshot(unit)
    if not snapshot then return nil end
    return snapshot
end

function API.BuildPlayerMenu(unit)
    local snapshot = GetUnitSnapshot(unit)
    if not snapshot then return nil end
    return snapshot
end

-- Devuelve el tipo de unidad para la lógica de menu.
-- "self"   → jugador propio (player frame o target = player)
-- "player" → jugador ajeno seleccionado como target
-- "npc"    → NPC / criatura / no jugador
local function GetUnitContext(snapshot)
    if not snapshot then return "npc" end
    if snapshot.isSelf then return "self" end
    if snapshot.isPlayer then return "player" end
    return "npc"
end

local function InitializeMenu(_, level, menuList)
    level = level or 1
    local snapshot = current.snapshot
    if not snapshot then return end
    local ctx = GetUnitContext(snapshot)

    if level == 1 then
        local title = snapshot.name ~= "" and snapshot.name or snapshot.unit
        AddTitle(title, level)

        if ctx == "self" then
            -- Jugador propio: TRP3 propio, turnos, recursos (mod.recursos+mod.salud), auras.
            AddAction("Abrir mi TRP3", function()
                if TRP3_API and TRP3_API.navigation and TRP3_API.navigation.openMainFrame then
                    TRP3_API.navigation.openMainFrame()
                end
                local pid = TRP3_API and TRP3_API.globals and TRP3_API.globals.player_id
                if pid and TRP3_API.register and TRP3_API.register.openPageByUnitID then
                    TRP3_API.register.openPageByUnitID(pid)
                end
            end, level)
            AddSubmenu("Turnos", "TURNOS", level)
            AddSubmenu("Recursos", "RECURSOS", level)
            AddSubmenu("Auras", "AURAS", level)

        elseif ctx == "player" then
            -- Jugador ajeno: enviar ficha (primera opcion), turnos, recursos, auras. Sin TRP3, sin loot.
            AddAction("Enviar ficha", function() SendSheetToTarget(snapshot) end, level)
            -- Sin `Profesiones`: es la ficha del jugador, no una herramienta de mesa, y el DM no
            -- le ensena recetas desde el menu del unitframe.
            AddSubmenu("Turnos", "TURNOS", level)
            AddSubmenu("Recursos", "RECURSOS", level)
            AddSubmenu("Auras", "AURAS", level)

        else -- npc
            -- NPC / criatura: turnos, recursos (mod.recursos+mod.salud), auras, loot, misiones. Sin TRP3.
            AddSubmenu("Turnos", "TURNOS", level)
            AddSubmenu("Recursos", "RECURSOS", level)
            AddSubmenu("Auras", "AURAS", level)
            AddSubmenu("Loot", "LOOT", level)
            AddSubmenu("Misiones", "MISIONES", level)
        end
        return
    end

    -- Submenús (level > 1): despachar según contexto
    if ctx == "self" then
        BuildSelfSubmenu(menuList, level)
    elseif ctx == "player" then
        BuildPlayerSubmenu(menuList, level)
    else
        BuildNpcSubmenu(menuList, level)
    end
end

function API.Open(unit, anchorButton)
    if not EnsureAllowed("abrir menu admin") then
        API.RefreshVisibility()
        return false
    end

    local snapshot = UnitIsPlayer and UnitIsPlayer(unit) and API.BuildPlayerMenu(unit) or API.BuildNpcMenu(unit)
    if not snapshot then
        Print("No hay unidad valida.")
        API.RefreshVisibility()
        return false
    end

    current.snapshot = snapshot
    dropdown = dropdown or CreateFrame("Frame", MENU_NAME, UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(dropdown, InitializeMenu, "MENU")
    ToggleDropDownMenu(1, nil, dropdown, anchorButton or UIParent, 0, 0)
    return true
end

local function StyleButton(button)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("CENTER", button, "CENTER", BUTTON_VISUAL_X, BUTTON_VISUAL_Y)
    bg:SetSize(14, 14)
    bg:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetSize(36, 36)

    local pushed = button:CreateTexture(nil, "OVERLAY")
    pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    pushed:SetAllPoints(button)
    pushed:SetAlpha(0.65)
    pushed:Hide()

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetPoint("CENTER", button, "CENTER", BUTTON_VISUAL_X, BUTTON_VISUAL_Y)
    highlight:SetSize(15, 15)

    button:SetScript("OnMouseDown", function(self)
        if self.pushed then self.pushed:Show() end
        if self.icon then self.icon:SetPoint("CENTER", self, "CENTER", BUTTON_VISUAL_X + 1, BUTTON_VISUAL_Y - 1) end
    end)
    button:SetScript("OnMouseUp", function(self)
        if self.pushed then self.pushed:Hide() end
        if self.icon then
            self.icon:ClearAllPoints()
            self.icon:SetPoint("CENTER", self, "CENTER", BUTTON_VISUAL_X, BUTTON_VISUAL_Y)
        end
    end)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", button, "CENTER", BUTTON_VISUAL_X, BUTTON_VISUAL_Y)
    icon:SetSize(12, 12)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if button.CreateMaskTexture and icon.AddMaskTexture then
        local mask = button:CreateMaskTexture(nil, "BACKGROUND")
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
    end

    button.bg = bg
    button.border = border
    button.pushed = pushed
    button.highlight = highlight
    button.icon = icon

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Harford Admin", 1, 0.82, 0)
        GameTooltip:AddLine("Click: abrir menu DM", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function GetUnitButtonParent(parentName, unit)
    if HarfordUnitFrames and HarfordUnitFrames.GetFrame then
        local frame = HarfordUnitFrames.GetFrame(unit)

        -- HarfordUnitFrames.GetFrame("target") puede devolver HarfordTargetUnitFrame
        -- aunque ese frame esté oculto, por ejemplo con targets NPC.
        -- Si usamos un parent oculto, el botón queda shown=true pero visible=false.
        if frame and frame.IsShown and frame:IsShown() then
            return frame
        end
    end

    return _G[parentName]
end

local function GetMeasuredButtonPoint(unit, parent)
    if not (HarfordUnitFrames and HarfordUnitFrames.GetMeasuredLayout) then return nil end
    if not parent then return nil end

    local layout = HarfordUnitFrames.GetMeasuredLayout(unit, false)
    local anchorBox = layout and (layout.portrait or layout.name or layout.health)
    if not anchorBox then return nil end

    local centerY = -((anchorBox.y or 0) + 13)
    if unit == "target" then
        return "CENTER", parent, "TOPLEFT", (anchorBox.x or 0) + 2, centerY
    end
    return "CENTER", parent, "TOPLEFT", (anchorBox.x or 0) + (anchorBox.width or 0) - 2, centerY
end

local function GetNativeOverlayFrame(parentName)
    if parentName == "TargetFrame" then
        return _G.TargetFrameTextureFrame
    end
    if parentName == "PlayerFrame" then
        return _G.PlayerFrameTextureFrame
    end
    return nil
end

local function SyncButtonFrameLevel(button, parent, parentName)
    if not button or not parent then return end

    if parent.GetFrameStrata and button.SetFrameStrata then
        button:SetFrameStrata(parent:GetFrameStrata())
    end

    if not button.SetFrameLevel then return end

    local parentLevel = parent.GetFrameLevel and parent:GetFrameLevel() or 0
    local overlay = GetNativeOverlayFrame(parentName)
    local overlayLevel = overlay and overlay.GetFrameLevel and overlay:GetFrameLevel() or parentLevel
    button:SetFrameLevel(math.max(parentLevel, overlayLevel) + 10)
end

local function AnchorUnitButton(button, parentName, unit, point, relPoint, x, y)
    local parent = GetUnitButtonParent(parentName, unit)
    if not parent then return false end

    if button:GetParent() ~= parent then
        button:SetParent(parent)
    end
    SyncButtonFrameLevel(button, parent, parentName)
    button:ClearAllPoints()
    local measuredPoint, measuredParent, measuredRelPoint, measuredX, measuredY = GetMeasuredButtonPoint(unit, parent)
    if measuredPoint then
        button:SetPoint(measuredPoint, measuredParent, measuredRelPoint, measuredX, measuredY)
    else
        button:SetPoint(point, parent, relPoint, x, y)
    end
    return true
end

local function CreateUnitButton(key, parentName, unit, point, relPoint, x, y)
    if buttons[key] then return buttons[key] end
    local parent = GetUnitButtonParent(parentName, unit)
    if not parent then return nil end

    local button = CreateFrame("Button", "HarfordAdminUnitMenu" .. key .. "Button", parent)
    StyleButton(button)
    AnchorUnitButton(button, parentName, unit, point, relPoint, x, y)
    button.unit = unit
    button.parentName = parentName
    button.anchorPoint = point
    button.anchorRelPoint = relPoint
    button.anchorX = x
    button.anchorY = y
    button:SetScript("OnClick", function(self)
        API.RefreshVisibility()
        API.Open(self.unit, self)
    end)
    buttons[key] = button
    return button
end

function API.AttachButtons()
    CreateUnitButton("Player", "PlayerFrame", "player", "TOPLEFT", "TOPLEFT", 78, -18)
    CreateUnitButton("Target", "TargetFrame", "target", "TOPRIGHT", "TOPRIGHT", -78, -18)
    API.RefreshAnchors()
    API.RefreshVisibility()
end

function API.RefreshAnchors()
    for _, button in pairs(buttons) do
        AnchorUnitButton(button, button.parentName, button.unit, button.anchorPoint, button.anchorRelPoint, button.anchorX, button.anchorY)
    end
end

function API.RefreshVisibility()
    local allowed = IsAllowed()
    if buttons.Player then
        buttons.Player:SetShown(allowed and UnitExistsSafe("player"))
    end
    if buttons.Target then
        buttons.Target:SetShown(allowed and UnitExistsSafe("target"))
    end
end

-- CHAT_MSG_SYSTEM eliminado: disparaba AttachButtons()+RefreshVisibility() en cada
-- mensaje de sistema sin filtrar. HarfordAuthority.RegisterChangeListener (abajo)
-- ya cubre los cambios de modo DM.
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FLAGS_CHANGED")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "Harford" and addonName ~= "HarfordAdmin" and addonName ~= "SpellCreator" and addonName ~= "EpsilonLib" then
            return
        end
    end
    API.AttachButtons()
    API.RefreshVisibility()
end)

if HarfordAuthority and HarfordAuthority.RegisterChangeListener then
    HarfordAuthority.RegisterChangeListener("HarfordAdminUnitMenu", function()
        API.AttachButtons()
        API.RefreshVisibility()
    end)
end

-- ─── Botón Modo NPC en la ficha D&D ──────────────────────────────────────────
-- Visible solo con HarfordAdmin activo + modo DM.
-- HarfordAdmin construye el contexto NPC; HarfordDnD solo representa/tira el contexto.
do
    local npcBtn, npcBtnIcon

    local function IsDMAdmin()
        return IsAllowed()
    end

    local function RefreshNpcButtonVisibility()
        if not npcBtn then return end
        if IsDMAdmin() then
            npcBtn:Show()
        else
            npcBtn:Hide()
            if HarfordDnDAPI and HarfordDnDAPI.HasSheetContext and HarfordDnDAPI.HasSheetContext() then
                if npcBtnIcon then npcBtnIcon:SetVertexColor(1, 1, 1) end
                if HarfordAdminNPC and HarfordAdminNPC.ClearDnDSheetContext then
                    HarfordAdminNPC.ClearDnDSheetContext()
                end
            end
        end
    end

    local function CreateNpcButton()
        if npcBtn then return end
        local dndAPI = HarfordDnDAPI
        if not (dndAPI and dndAPI.GetPlayerFrame) then return end
        local parentFrame = dndAPI.GetPlayerFrame()
        -- La ficha ya no tiene boton de turnos; el ultimo de su cabecera se publica como
        -- `HarfordDnDHeaderAnchor`. Se acepta el nombre antiguo por si carga una version vieja.
        local anchorFrame = _G.HarfordDnDHeaderAnchor or _G.HarfordDnDTurnButton
        if not parentFrame or not anchorFrame then return end

        npcBtn = CreateFrame("Button", nil, parentFrame)
        npcBtn:SetSize(20, 20)
        npcBtn:SetPoint("LEFT", anchorFrame, "RIGHT", 5, 0)
        npcBtn:Hide()

        npcBtnIcon = npcBtn:CreateTexture(nil, "ARTWORK")
        npcBtnIcon:SetAllPoints()
        npcBtnIcon:SetTexture("Interface\\Icons\\Spell_Shadow_Possession")
        npcBtnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local npcBtnHL = npcBtn:CreateTexture(nil, "HIGHLIGHT")
        npcBtnHL:SetAllPoints()
        npcBtnHL:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        npcBtnHL:SetBlendMode("ADD")

        npcBtn:SetScript("OnClick", function()
            if not HarfordDnDAPI or not HarfordAdminNPC then return end
            if IsControlKeyDown and IsControlKeyDown() then
                local snapshot = GetUnitSnapshot("target")
                local targetGuid = snapshot and snapshot.guid
                local isNpc = snapshot and not snapshot.isPlayer and not snapshot.isSelf
                if isNpc and targetGuid and targetGuid ~= "" then
                    if targetGuid == _lastPossessedGuid then
                        -- Mismo NPC que ya poseemos: solo soltar.
                        UnpossessNpc()
                    else
                        -- NPC diferente: soltar el actual y poseer el nuevo.
                        RepossessNpc(snapshot)
                    end
                else
                    -- Sin target, target jugador, o target propio: solo soltar.
                    UnpossessNpc()
                end
                return
            end
            local lockRequested = IsShiftKeyDown and IsShiftKeyDown()
            local unit = "target"
            if lockRequested and UnitExists(unit) and not UnitIsPlayer(unit) then
                local ok, err = HarfordAdminNPC.ApplyDnDSheetContext(unit, { locked = true })
                if ok then
                    npcBtnIcon:SetVertexColor(1, 0.45, 0)
                else
                    Print(err)
                end
            elseif HarfordDnDAPI.HasSheetContext and HarfordDnDAPI.HasSheetContext() then
                npcBtnIcon:SetVertexColor(1, 1, 1)
                HarfordAdminNPC.ClearDnDSheetContext()
            else
                if UnitExists(unit) and not UnitIsPlayer(unit) then
                    local ok, err = HarfordAdminNPC.ApplyDnDSheetContext(unit)
                    if ok then
                        npcBtnIcon:SetVertexColor(1, 0.7, 0)
                    else
                        Print(err)
                    end
                end
            end
        end)

        npcBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Modo NPC", 1, 0.82, 0)
            GameTooltip:AddLine("Ctrl + Click en NPC nuevo: Unposs + Poss", 0.75, 0.9, 1)
            GameTooltip:AddLine("Ctrl + Click en NPC poseido: solo Unposs", 0.75, 0.9, 1)
            GameTooltip:AddLine("Ctrl + Click sin NPC / player: solo Unposs", 0.75, 0.9, 1)
            if HarfordDnDAPI and HarfordDnDAPI.HasSheetContext and HarfordDnDAPI.HasSheetContext() then
                if HarfordAdminNPC and HarfordAdminNPC.IsDnDSheetContextLocked
                    and HarfordAdminNPC.IsDnDSheetContextLocked() then
                    GameTooltip:AddLine("Bloqueado — atacante marcado en ficha", 1, 0.55, 0)
                else
                    GameTooltip:AddLine("Activo — selecciona atacante o victima", 0, 1, 0)
                end
                GameTooltip:AddLine("Click: desactivar", 1, 1, 1)
            else
                GameTooltip:AddLine("Click: activar con el NPC seleccionado", 1, 1, 1)
                GameTooltip:AddLine("Shift + Click: bloquear atacante", 0.75, 0.9, 1)
            end
            GameTooltip:Show()
        end)

        npcBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        RefreshNpcButtonVisibility()
    end

    -- Actualizar al cambiar de target si el modo NPC está activo
    local function OnTargetChanged()
        if not (HarfordDnDAPI and HarfordDnDAPI.HasSheetContext) then return end
        if not HarfordDnDAPI.HasSheetContext() then return end
        if HarfordAdminNPC and HarfordAdminNPC.IsDnDSheetContextLocked
            and HarfordAdminNPC.IsDnDSheetContextLocked() then
            if HarfordDnDAPI.RefreshSheetActionAvailability then
                HarfordDnDAPI.RefreshSheetActionAvailability()
            end
            return
        end
        local unit = "target"
        -- Solo recargamos la ficha al seleccionar otro NPC.
        -- Si no hay target o es un jugador, la ficha del NPC anterior se mantiene
        -- hasta que el DM desactive el modo NPC manualmente.
        if UnitExists(unit) and not UnitIsPlayer(unit) then
            if HarfordAdminNPC and HarfordAdminNPC.ApplyDnDSheetContext then
                local ok, err = HarfordAdminNPC.ApplyDnDSheetContext(unit)
                if not ok then Print(err) end
            end
        elseif HarfordDnDAPI.RefreshSheetActionAvailability then
            -- En modo normal conservamos la ultima ficha NPC al seleccionar
            -- un jugador para aplicar daño; sin target quedan ambos botones apagados.
            HarfordDnDAPI.RefreshSheetActionAvailability()
        end
    end

    -- Reutilizar el frame de eventos existente si es posible; si no, crear uno propio
    local npcEvtFrame = CreateFrame("Frame")
    npcEvtFrame:RegisterEvent("PLAYER_LOGIN")
    npcEvtFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    npcEvtFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" then
            CreateNpcButton()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnTargetChanged()
        end
    end)

    if HarfordAuthority and HarfordAuthority.RegisterChangeListener then
        HarfordAuthority.RegisterChangeListener("HarfordDnDNpcMode", RefreshNpcButtonVisibility)
    end
end
-- ─── Fin Botón Modo NPC ────────────────────────────────────────────────────────
