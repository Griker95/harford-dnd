-- HarfordDnDCustomDamage: parser, tirada y ventana de daño personalizado.

HarfordDnDCustomDamage = HarfordDnDCustomDamage or {}

local API = HarfordDnDCustomDamage

local function Signed(value)
    value = tonumber(value) or 0
    return value > 0 and ("+" .. value) or tostring(value)
end

local function PrintError(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[Harford]|r " .. tostring(message))
    end
end

function API.Parse(text)
    text = tostring(text or ""):lower():gsub("%s+", "")
    if text == "" then return nil, "Introduce dados o un numero" end

    local count, sides, bonus = text:match("^(%d*)d(%d+)([+-]%d+)$")
    if not sides then
        count, sides = text:match("^(%d*)d(%d+)$")
        bonus = nil
    end
    if sides then
        count = count ~= "" and tonumber(count) or 1
        sides = tonumber(sides)
        bonus = tonumber(bonus) or 0
        if count <= 0 or sides <= 0 then return nil, "Formato de dados invalido" end
        return { count = count, sides = sides, bonus = bonus }
    end

    local flat = text:match("^(%d+)$")
    if flat then return { flat = tonumber(flat) } end
    return nil, "Formato invalido (usa XdY, dY o un numero)"
end

function API.Roll(expr, abilityKey, damageKey, maximizeDice, mitigationUnit)
    mitigationUnit = mitigationUnit or "target"
    local parsed, err = API.Parse(expr)
    if not parsed then
        PrintError(err)
        return 0
    end

    local isFlat = parsed.flat ~= nil
    local rolls, sum = {}, 0
    if isFlat then
        sum = parsed.flat
    else
        for _ = 1, parsed.count do
            local result = maximizeDice and parsed.sides or HarfordDnDCalc.RollDie(parsed.sides)
            rolls[#rolls + 1] = result
            sum = sum + result
        end
    end

    local abilityMod = abilityKey and HarfordDnDCalc.GetAbilityMod(abilityKey) or 0
    local fixedBonus = isFlat and 0 or (parsed.bonus or 0)
    local total = math.max(0, sum + fixedBonus + abilityMod)
    local damageType = HarfordDamageTypes and HarfordDamageTypes.GetLabel
        and HarfordDamageTypes.GetLabel(damageKey) or tostring(damageKey or "")
    damageType = tostring(damageType or ""):lower()

    local marker = ""
    if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
        local applied, _, mitigationMarker = HarfordDamageMitigation.ForTarget(mitigationUnit, damageType, total)
        total, marker = applied, mitigationMarker
    end

    local parts = {}
    if fixedBonus ~= 0 then parts[#parts + 1] = Signed(fixedBonus) end
    if abilityMod ~= 0 then parts[#parts + 1] = Signed(abilityMod) end
    local bonusText = table.concat(parts, "")
    local diceText
    if isFlat then
        diceText = tostring(parsed.flat) .. bonusText
    else
        diceText = parsed.count .. "d" .. parsed.sides .. ": " .. table.concat(rolls, "+") .. bonusText
    end

    local modifiers = damageType
    if marker ~= "" then modifiers = damageType .. " " .. marker end
    HarfordDnDRolls.Broadcast({
        type = "damage",
        label = "Daño",
        total = total,
        dice = diceText,
        critical = maximizeDice and not isFlat and "CRÍTICO" or "",
        modifiers = modifiers,
        mode = "",
    })
    return total
end

function API.Apply()
    local frame = API.Frame
    if not frame then return end
    local applyUnit = frame.applyUnit or "target"
    local blockSelf = applyUnit ~= "focus"
    if not (UnitExists and UnitExists(applyUnit))
        or (blockSelf and UnitIsUnit and UnitIsUnit(applyUnit, "player")) then
        PrintError("Selecciona un objetivo valido para tirar daño custom")
        return
    end

    local isCritical = HarfordDnDStore.pendingWeaponCriticalKey ~= nil
    HarfordDnDStore.pendingWeaponCriticalKey = nil
    local total = API.Roll(
        frame.diceBox and frame.diceBox:GetText(),
        frame.abilityKey,
        frame.damageKey or "slashing",
        isCritical,
        applyUnit
    )
    if applyUnit == "focus" then
        HarfordDnDCombat.ApplyActionDamageToFocus(total)
    else
        HarfordDnDCombat.ApplyWeaponDamageToTarget(total, isCritical)
    end
end

local function EnsureFrame()
    if API.Frame then return API.Frame end

    local frame = CreateFrame("Frame", "HarfordCustomDamageFrame", UIParent, "BackdropTemplate")
    frame:SetSize(300, 154)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(0.02, 0.02, 0.02, 0.92)
        frame:SetBackdropBorderColor(0.75, 0.65, 0.35, 1)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Daño")
    frame.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() frame:Hide() end)

    local diceLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    diceLabel:SetPoint("TOPLEFT", 18, -38)
    diceLabel:SetText("Dados")
    frame.diceBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.diceBox:SetSize(100, 20)
    frame.diceBox:SetPoint("LEFT", diceLabel, "RIGHT", 48, 0)
    frame.diceBox:SetAutoFocus(false)
    frame.diceBox:SetText("1d6")
    frame.diceBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); API.Apply() end)
    frame.diceBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local abilityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abilityLabel:SetPoint("TOPLEFT", 18, -68)
    abilityLabel:SetText("Característica")
    frame.abilityDrop = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(frame.abilityDrop, 120)
    frame.abilityDrop:SetPoint("TOPLEFT", 112, -50)
    frame.abilityKey = nil
    UIDropDownMenu_Initialize(frame.abilityDrop, function(_, level)
        if level ~= 1 then return end
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Ninguno"
        info.checked = frame.abilityKey == nil
        info.func = function()
            frame.abilityKey = nil
            UIDropDownMenu_SetText(frame.abilityDrop, "Ninguno")
        end
        UIDropDownMenu_AddButton(info, level)
        for _, ability in ipairs(HarfordDnDData.ABIL) do
            local abilityKey = ability.key
            info = UIDropDownMenu_CreateInfo()
            info.text = abilityKey
            info.checked = frame.abilityKey == abilityKey
            info.func = function()
                frame.abilityKey = abilityKey
                UIDropDownMenu_SetText(frame.abilityDrop, abilityKey)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(frame.abilityDrop, "Ninguno")

    local damageLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    damageLabel:SetPoint("TOPLEFT", 18, -98)
    damageLabel:SetText("Tipo de daño")
    frame.damageDrop = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(frame.damageDrop, 120)
    frame.damageDrop:SetPoint("TOPLEFT", 112, -80)
    frame.damageKey = "slashing"
    UIDropDownMenu_Initialize(frame.damageDrop, function(_, level)
        if level ~= 1 then return end
        local list = HarfordDamageTypes and HarfordDamageTypes.GetOrderedList
            and HarfordDamageTypes.GetOrderedList() or {}
        for _, option in ipairs(list) do
            local damageKey, label = option.key, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.checked = frame.damageKey == damageKey
            info.func = function()
                frame.damageKey = damageKey
                UIDropDownMenu_SetText(frame.damageDrop, label)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(frame.damageDrop,
        HarfordDamageTypes and HarfordDamageTypes.GetLabel and HarfordDamageTypes.GetLabel("slashing") or "Cortante")

    HarfordDnDUI.MakeButton(frame, "Lanzar", 112, 22, 94, -122, API.Apply)
    API.Frame = frame
    HarfordDnDStore.customDamageFrame = frame
    return frame
end

function API.Open(applyUnit, ownerFrame)
    local frame = EnsureFrame()
    frame.applyUnit = applyUnit or "target"
    ownerFrame = ownerFrame or API.OwnerFrame
    if ownerFrame and ownerFrame.GetFrameLevel then
        frame:SetFrameLevel(ownerFrame:GetFrameLevel() + 200)
    end
    if frame.title then
        frame.title:SetText(frame.applyUnit == "focus" and "Daño Custom (focus)" or "Daño")
    end
    frame:Show()
    frame:Raise()
    if frame.diceBox then frame.diceBox:SetFocus() end
end

function API.Configure(ownerFrame)
    API.OwnerFrame = ownerFrame
    HarfordDnDStore.OpenCustomDamageFrame = function(applyUnit)
        API.Open(applyUnit, ownerFrame)
    end
end

