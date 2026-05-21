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
    DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[HarfordAdmin]|r " .. tostring(message or ""))
end

local function IsAllowed()
    if not (HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true) then
        return false
    end
    if HarfordAuthority and HarfordAuthority.IsDMMode then
        return HarfordAuthority.IsDMMode() == true
    end
    return false
end

local function UnitExistsSafe(unit)
    return unit and UnitExists and UnitExists(unit)
end

local function GetUnitNameSafe(unit)
    if not UnitExistsSafe(unit) then return nil end
    return (GetUnitName and GetUnitName(unit, true)) or UnitName(unit)
end

local function GetUnitSnapshot(unit)
    if not UnitExistsSafe(unit) then return nil end
    return {
        unit = unit,
        guid = UnitGUID and UnitGUID(unit) or "",
        name = GetUnitNameSafe(unit) or "",
        isPlayer = UnitIsPlayer and UnitIsPlayer(unit) == true,
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

local function TargetForAura(snapshot)
    if snapshot and snapshot.unit == "player" then
        return "self"
    end
    return "target"
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

local function PrintNpcTRP3(snapshot)
    if not EnsureSameUnit(snapshot, "TRP3 NPC") then return end
    if not HarfordTRP3 then
        Print("HarfordTRP3 no disponible.")
        return
    end

    local profileID, profileIDErr, fullID, npcID, phaseID = HarfordTRP3.GetEpsilonNpcProfileID(snapshot.unit)
    Print("NPC: " .. tostring(snapshot.name or "target"))
    Print("fullID: " .. tostring(fullID or "desconocido"))
    Print("npcID: " .. tostring(npcID or "desconocido"))
    Print("phaseID: " .. tostring(phaseID or "desconocida"))
    Print("profileID: " .. tostring(profileID or "nil"))
    if profileIDErr then Print(profileIDErr) end
end

local function OpenNpcTRP3(snapshot)
    if not EnsureSameUnit(snapshot, "abrir ficha TRP3 NPC") then return end
    if not (TRP3_API and TRP3_API.companions and TRP3_API.companions.register and TRP3_API.companions.register.openPage) then
        Print("TRP3 no puede abrir pagina de companion/NPC.")
        return
    end
    if not HarfordTRP3 or not HarfordTRP3.GetEpsilonNpcProfileID then
        Print("HarfordTRP3 no disponible.")
        return
    end

    local profileID, err = HarfordTRP3.GetEpsilonNpcProfileID(snapshot.unit)
    if not profileID or profileID == "" then
        Print(err or "profileID TRP3 NPC no disponible.")
        return
    end
    local profiles = TRP3_API.companions.register.getProfiles and TRP3_API.companions.register.getProfiles()
    if type(profiles) == "table" and not profiles[profileID] then
        Print("La ficha TRP3 NPC no esta en el registro local.")
        return
    end

    TRP3_API.companions.register.openPage(profileID)
end

local function PrintPlayerTRP3(snapshot)
    if not EnsureSameUnit(snapshot, "TRP3 jugador") then return end
    if not HarfordTRP3 then
        Print("HarfordTRP3 no disponible.")
        return
    end

    local unitID = HarfordTRP3.BuildUnitID and HarfordTRP3.BuildUnitID(snapshot.unit)
    Print("Jugador: " .. tostring(snapshot.name or snapshot.unit))
    Print("unitID: " .. tostring(unitID or "desconocido"))
end

local function OpenPlayerTRP3(snapshot)
    if not EnsureSameUnit(snapshot, "abrir ficha TRP3 jugador") then return end
    if not (TRP3_API and TRP3_API.register and TRP3_API.register.openPageByUnitID) then
        Print("TRP3 no puede abrir pagina de jugador.")
        return
    end
    if not HarfordTRP3 or not HarfordTRP3.BuildUnitID then
        Print("HarfordTRP3 no disponible.")
        return
    end

    local unitID = HarfordTRP3.BuildUnitID(snapshot.unit)
    if not unitID or unitID == "" then
        Print("unitID TRP3 no disponible.")
        return
    end

    TRP3_API.register.openPageByUnitID(unitID)
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

local function RequestResources(snapshot)
    if not EnsureSameUnit(snapshot, "refrescar recursos") then return end
    if not HarfordDnDAPI or not HarfordDnDAPI.RequestResourcesForName then
        Print("HarfordDnDAPI no disponible.")
        return
    end
    local ok = HarfordDnDAPI.RequestResourcesForName(snapshot.name)
    Print(ok and "Recursos solicitados." or "No se pudieron solicitar recursos.")
end

local function AdjustPlayerHealth(snapshot, delta)
    if not EnsureSameUnit(snapshot, "ajustar vida jugador") then return end
    if not HarfordDnDAPI or not HarfordDnDAPI.AdjustResourceForName then
        Print("HarfordDnDAPI no disponible.")
        return
    end
    local ok, err = HarfordDnDAPI.AdjustResourceForName(snapshot.name, "health", delta)
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

        local target = TargetForAura(snapshot)
        local ok, err
        if snapshot.unit == "target" and HarfordAdminNPC then
            if applying and HarfordAdminNPC.ApplyAuraToTarget then
                ok, err = HarfordAdminNPC.ApplyAuraToTarget(spellId)
            elseif not applying and HarfordAdminNPC.RemoveAuraFromTarget then
                ok, err = HarfordAdminNPC.RemoveAuraFromTarget(spellId)
            end
        elseif applying then
            if HarfordServerActions and HarfordServerActions.ApplyAura then
                ok, err = HarfordServerActions.ApplyAura(spellId, target, { addonName = "HarfordAdmin" })
            end
        else
            if HarfordServerActions and HarfordServerActions.RemoveAura then
                ok, err = HarfordServerActions.RemoveAura(spellId, target, { addonName = "HarfordAdmin" })
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

local function AddAction(text, func, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.notCheckable = true
    info.func = func
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

local function AddHealthPresets(snapshot, isPlayer, level)
    local values = { 1, -1, 5, -5, 10, -10 }
    for _, amount in ipairs(values) do
        local label = amount > 0 and ("+" .. tostring(amount)) or tostring(amount)
        AddAction(label, function()
            if isPlayer then
                AdjustPlayerHealth(snapshot, amount)
            else
                AdjustNpcHealth(snapshot, amount)
            end
        end, level)
    end
    AddAction("Personalizado...", function() PromptHealth(snapshot, isPlayer) end, level)
end

local function BuildNpcSubmenu(menuList, level)
    local snapshot = current.snapshot
    if menuList == "TRP3" then
        AddAction("Abrir ficha TRP3", function() OpenNpcTRP3(snapshot) end, level)
        AddAction("Mostrar IDs TRP3", function() PrintNpcTRP3(snapshot) end, level)
    elseif menuList == "TURNOS" then
        AddAction("Anadir a turnos", function() AddToTurns(snapshot) end, level)
        AddAction("Abrir turnos", OpenTurns, level)
    elseif menuList == "VIDA" then
        AddHealthPresets(snapshot, false, level)
    elseif menuList == "AURAS" then
        AddAction("Aplicar aura NPC...", function() PromptNpcAura(snapshot) end, level)
        AddAction("Loot Aura", function() ApplyNpcLootAura(snapshot) end, level)
        AddAction("Quitar aura...", function() ApplyAura(snapshot, false) end, level)
    elseif menuList == "LOOT" then
        AddAction("Cargar loot...", function() OpenLootEditor(snapshot) end, level)
    end
end

local function BuildPlayerSubmenu(menuList, level)
    local snapshot = current.snapshot
    if menuList == "FICHA" then
        AddAction("Abrir ficha TRP3", function() OpenPlayerTRP3(snapshot) end, level)
        AddAction("Mostrar TRP3", function() PrintPlayerTRP3(snapshot) end, level)
        if snapshot and snapshot.unit == "target" then
            AddAction("Enviar ficha al target", function() SendSheetToTarget(snapshot) end, level)
        end
    elseif menuList == "TURNOS" then
        AddAction("Anadir a turnos", function() AddToTurns(snapshot) end, level)
        AddAction("Abrir turnos", OpenTurns, level)
    elseif menuList == "RECURSOS" then
        AddAction("Pedir recursos", function() RequestResources(snapshot) end, level)
    elseif menuList == "VIDA" then
        AddHealthPresets(snapshot, true, level)
    elseif menuList == "AURAS" then
        AddAction("Aplicar aura...", function() ApplyAura(snapshot, true) end, level)
        AddAction("Quitar aura...", function() ApplyAura(snapshot, false) end, level)
    elseif menuList == "LOOT" then
        AddAction("Cargar loot...", function() OpenLootEditor(snapshot) end, level)
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

local function InitializeMenu(_, level, menuList)
    level = level or 1
    if level == 1 then
        local snapshot = current.snapshot
        if not snapshot then return end
        AddTitle(snapshot.name ~= "" and snapshot.name or snapshot.unit, level)
        if snapshot.isPlayer then
            AddSubmenu("Ficha", "FICHA", level)
            AddSubmenu("Turnos", "TURNOS", level)
            AddSubmenu("Recursos", "RECURSOS", level)
            AddSubmenu("Vida", "VIDA", level)
            AddSubmenu("Auras", "AURAS", level)
            AddSubmenu("Loot", "LOOT", level)
        else
            AddSubmenu("TRP3", "TRP3", level)
            AddSubmenu("Turnos", "TURNOS", level)
            AddSubmenu("Vida", "VIDA", level)
            AddSubmenu("Auras", "AURAS", level)
            AddSubmenu("Loot", "LOOT", level)
        end
        return
    end

    if current.snapshot and current.snapshot.isPlayer then
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
        if frame then return frame end
    end
    return _G[parentName]
end

local function GetMeasuredButtonPoint(unit, parent)
    if not (HarfordUnitFrames and HarfordUnitFrames.GetMeasuredLayout) then return nil end
    if not (parent and parent.GetName and parent:GetName() and parent:GetName():match("^Harford")) then return nil end

    local layout = HarfordUnitFrames.GetMeasuredLayout(unit, false)
    local anchorBox = layout and (layout.portrait or layout.name or layout.health)
    if not anchorBox then return nil end

    local centerY = -((anchorBox.y or 0) + 13)
    if unit == "target" then
        return "CENTER", parent, "TOPLEFT", (anchorBox.x or 0) + 2, centerY
    end
    return "CENTER", parent, "TOPLEFT", (anchorBox.x or 0) + (anchorBox.width or 0) - 2, centerY
end

local function AnchorUnitButton(button, parentName, unit, point, relPoint, x, y)
    local parent = GetUnitButtonParent(parentName, unit)
    if not parent then return false end

    if button:GetParent() ~= parent then
        button:SetParent(parent)
    end
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

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("CHAT_MSG_SYSTEM")
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
