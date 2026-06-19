-- HarfordDnDAttackUI: construccion y estado visual de la seccion Ataque.
-- Las reglas, tiradas y aplicacion de dano siguen en HarfordDnD/HarfordDnDCombat.

HarfordDnDAttackUI = HarfordDnDAttackUI or {}

local API = HarfordDnDAttackUI

API.Controls = API.Controls or {}

local function OpenItemLink(self, link, text, button)
    if IsModifiedClick and IsModifiedClick("CHATLINK") then
        if ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
    elseif SetItemRef then
        SetItemRef(link, text, button, self)
    end
end

local function EnterItemLink(self, link)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end

local function LeaveItemLink()
    if GameTooltip then GameTooltip:Hide() end
end

function API.CreateBase(opts)
    opts = opts or {}
    local parent = opts.parent
    if not parent then return API.Controls end

    local controls = API.Controls
    local armorLabel, armorBox
    if opts.createArmorClassEditBox then
        armorLabel, armorBox = opts.createArmorClassEditBox(parent, -18, -34)
    end
    controls.armorClassLabel = armorLabel
    controls.armorClassBox = armorBox

    local linkFrame = CreateFrame("Frame", nil, parent)
    linkFrame:SetPoint("TOPLEFT", 10, -34)
    linkFrame:SetSize(285, 30)
    linkFrame:EnableMouse(true)
    if linkFrame.SetHyperlinksEnabled then linkFrame:SetHyperlinksEnabled(true) end
    linkFrame:SetScript("OnHyperlinkClick", OpenItemLink)
    linkFrame:SetScript("OnHyperlinkEnter", EnterItemLink)
    linkFrame:SetScript("OnHyperlinkLeave", LeaveItemLink)
    controls.weaponLinkFrame = linkFrame

    local weaponText = linkFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    weaponText:SetAllPoints(linkFrame)
    weaponText:SetJustifyH("LEFT")
    weaponText:SetJustifyV("TOP")
    weaponText:SetWordWrap(true)
    weaponText:SetMaxLines(2)
    weaponText:SetText("")
    controls.weaponInfoText = weaponText

    local damageText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageText:SetPoint("TOPLEFT", 10, -62)
    damageText:SetWidth(300)
    damageText:SetJustifyH("LEFT")
    damageText:SetText("")
    controls.dmgInfoText = damageText

    controls.versBtn = HarfordDnDUI.MakeButton(parent, "Versátil", 70, 22, 10, -88, function()
        if opts.onVersatile then opts.onVersatile() end
    end)

    local offhand = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    offhand:SetPoint("TOPLEFT", parent, "TOPLEFT", 88, -88)
    offhand:SetSize(22, 22)
    offhand:SetScript("OnClick", function(self)
        if opts.onOffhand then opts.onOffhand(self:GetChecked()) end
    end)
    controls.offhandCheckbox = offhand

    local offhandLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    offhandLabel:SetPoint("LEFT", offhand, "RIGHT", -1, 0)
    offhandLabel:SetText("Offhand")
    controls.offhandCheckboxLabel = offhandLabel

    controls.condDamageButton = HarfordDnDUI.MakeButton(parent, "Daño extra", 130, 22, 168, -88, function(self)
        if opts.onConditionalDamage then opts.onConditionalDamage(self) end
    end)

    return controls
end

function API.CreateAnimationControls(opts)
    opts = opts or {}
    local parent = opts.parent
    if not parent then return end

    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 266, -6)
    checkbox:SetSize(24, 24)
    checkbox:SetChecked(opts.checked ~= false)
    checkbox:SetScript("OnClick", function(self)
        if opts.onChanged then
            opts.onChanged(self:GetChecked() == true or self:GetChecked() == 1)
        end
    end)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    label:SetText("Animaciones")

    API.Controls.animsCheckbox = checkbox
    API.Controls.animsCheckboxLabel = label
end

function API.CreateCombatModeButton(opts)
    opts = opts or {}
    if not opts.parent then return nil end
    local button = HarfordDnDUI.MakeButton(opts.parent, "Modo combate", 110, 22, 150, -6, function()
        if opts.onClick then opts.onClick() end
    end)
    button:SetShown(opts.shown ~= false)
    API.Controls.combatModeButton = button
    return button
end

function API.CreateActionButtons(opts)
    opts = opts or {}
    local parent = opts.parent
    if not parent then return API.Controls end
    local controls = API.Controls

    controls.weaponAttackButton = HarfordDnDUI.MakeButton(parent, "Ataque Arma", 110, 22, 10, -116, function()
        if opts.onWeaponAttack then opts.onWeaponAttack() end
    end)
    controls.weaponDamageButton = HarfordDnDUI.MakeButton(parent, "Daño Custom", 110, 22, 130, -116, function()
        if opts.onCustomDamage then opts.onCustomDamage() end
    end)
    controls.spellAttackButton = HarfordDnDUI.MakeButton(parent, "Ataque Conjuro", 110, 22, 250, -116, function()
        if opts.onSpellAttack then opts.onSpellAttack() end
    end)
    controls.initiativeButton = HarfordDnDUI.MakeButton(parent, "Iniciativa", 110, 22, 10, -144, function()
        if opts.onInitiative then opts.onInitiative() end
    end)
    return controls
end

function API.RefreshActionButtons(enabled)
    local controls = API.Controls
    if controls.weaponDamageButton then
        controls.weaponDamageButton:SetText("Daño Custom")
    end
    for _, button in ipairs({
        controls.weaponAttackButton,
        controls.weaponDamageButton,
        controls.spellAttackButton,
    }) do
        if button then
            if enabled then button:Enable() else button:Disable() end
        end
    end
    return enabled
end

function API.ConfigureWeaponInfo(opts)
    API.weaponInfoDeps = opts or {}
end

function API.RefreshWeaponInfo()
    local deps = API.weaponInfoDeps or {}
    if not (deps.getWeaponDef and deps.getWeaponKey) then return end

    local store = HarfordDnDStore
    local controls = API.Controls
    local def = deps.getWeaponDef(deps.getWeaponKey())
    local nameLabel = deps.weaponDisplayLabel and deps.weaponDisplayLabel(def) or tostring(def and def.key or "Desarmado")
    local props = HarfordDnDWeapons and HarfordDnDWeapons.WeaponPropsLabel
        and HarfordDnDWeapons.WeaponPropsLabel(def) or ""
    local infoLabel = props ~= "" and (nameLabel .. " " .. props) or nameLabel
    local context = HarfordDnDContext and HarfordDnDContext.State
    if not (context and context.active)
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("extraAttack") then
        infoLabel = infoLabel .. "  |cff88ccff(Ataque Extra: x2)|r"
    end
    if controls.weaponInfoText then controls.weaponInfoText:SetText(infoLabel) end

    local versatileDice = HarfordDnDWeapons and HarfordDnDWeapons.GetVersatileDice
        and HarfordDnDWeapons.GetVersatileDice(def)
    if controls.versBtn then
        controls.versBtn:SetText("Versátil")
        if versatileDice then
            controls.versBtn:Enable()
        else
            if deps.setValue then deps.setValue("Versatil", 0) end
            controls.versBtn:Disable()
        end
    end

    local offhandAvailable = store.IsOffhandAvailable and store.IsOffhandAvailable(def)
    if not offhandAvailable and deps.setValue then deps.setValue("Offhand", 0) end
    if controls.offhandCheckbox then
        controls.offhandCheckbox:SetShown(offhandAvailable)
        controls.offhandCheckbox:SetChecked(offhandAvailable and store.GetOffhandActive(def))
    end
    if controls.offhandCheckboxLabel then
        controls.offhandCheckboxLabel:SetShown(offhandAvailable)
    end

    local conditionalList = store.GetConditionalDamageList and store.GetConditionalDamageList() or {}
    if controls.condDamageButton then
        if #conditionalList == 0 then
            store.activeCondDamage = {}
            controls.condDamageButton:Hide()
        else
            controls.condDamageButton:Show()
            local availableIds, activeNames, usableCount = {}, {}, 0
            for _, conditional in ipairs(conditionalList) do
                availableIds[conditional.id] = true
                if deps.hasPayableConditionalDamage and deps.hasPayableConditionalDamage(conditional) then
                    usableCount = usableCount + 1
                end
            end
            for id in pairs(store.activeCondDamage or {}) do
                if not availableIds[id] then
                    store.activeCondDamage[id] = nil
                    store.condDamageLevel[id] = nil
                end
            end
            for _, conditional in ipairs(conditionalList) do
                local level = deps.getConditionalSelectedLevel and deps.getConditionalSelectedLevel(conditional) or 1
                local canPay = deps.canPayConditionalDamage and deps.canPayConditionalDamage(conditional, level)
                if not canPay then
                    store.activeCondDamage[conditional.id] = nil
                    store.condDamageLevel[conditional.id] = nil
                end
                if store.activeCondDamage[conditional.id] then
                    local text = deps.conditionalOptionText and deps.conditionalOptionText(conditional, level)
                        or conditional.label or "Daño extra"
                    activeNames[#activeNames + 1] = text:match("^(.-) %(") or conditional.label
                end
            end
            local text = "Daño extra"
            if #activeNames == 1 then text = activeNames[1]
            elseif #activeNames > 1 then text = "Extra (" .. #activeNames .. ")" end
            controls.condDamageButton:SetText(text)
            if usableCount > 0 then controls.condDamageButton:Enable()
            else controls.condDamageButton:Disable() end
        end
    end

    local ability = deps.getWeaponAttackAbility and deps.getWeaponAttackAbility(def)
    local abilityMod = (def and def.addAbi and ability and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod)
        and HarfordDnDCalc.GetAbilityMod(ability) or 0
    if store.GetOffhandActive and store.GetOffhandActive(def) and abilityMod > 0
        and not (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag and HarfordDnDFeatureEffects.HasFlag("offhandDamageMod"))
        and not (def and def.key == "Escudo" and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag and HarfordDnDFeatureEffects.HasFlag("shieldBash")) then
        abilityMod = 0
    end
    local weaponMod = (HarfordDnDCalc and HarfordDnDCalc.GetWeaponDamageBonus
        and HarfordDnDCalc.GetWeaponDamageBonus() or (HarfordDnDCalc and HarfordDnDCalc.GetWeaponMod and HarfordDnDCalc.GetWeaponMod() or 0))
        + (deps.getWeaponSlotDamageBonus and deps.getWeaponSlotDamageBonus(def) or 0)
    local dice = HarfordDnDWeapons and HarfordDnDWeapons.WeaponBaseDice
        and HarfordDnDWeapons.WeaponBaseDice(def) or "1d4"
    local parts = {}
    if abilityMod ~= 0 then parts[#parts + 1] = deps.formatSigned(abilityMod) end
    if weaponMod ~= 0 then parts[#parts + 1] = deps.formatSigned(weaponMod) end
    local damageType = def and def.dmgType or ""
    local damageTypeText = damageType ~= "" and (" " .. damageType) or ""
    if controls.dmgInfoText then
        controls.dmgInfoText:SetText(("Daño: %s%s%s"):format(dice, table.concat(parts, ""), damageTypeText))
    end
    if store.RefreshWeaponDamageButton then store.RefreshWeaponDamageButton() end
end

function API.AttachMovementTracker(opts)
    opts = opts or {}
    local parent = opts.parent
    if not parent then return end

    local yardsToMeters = 0.9144
    local pollInterval = 0.1
    local tracking = false
    local totalMeters = 0
    local lastX, lastY, lastZ
    local elapsed = 0

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 250, -148)
    label:SetSize(130, 14)
    label:SetJustifyH("LEFT")
    label:SetText("")

    local button = HarfordDnDUI.MakeButton(parent, "Movimiento", 110, 22, 130, -144, function() end)
    API.Controls.movementLabel = label
    API.Controls.movementButton = button

    local function GetPosition()
        if UnitPosition then
            local x, y, z = UnitPosition("player")
            if x and y then return x, y, z or 0 end
        end
        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local point = C_Map.GetPlayerMapPosition(mapID, "player")
                if point then return point.x, point.y, 0 end
            end
        end
        return nil
    end

    local function FormatMeters(value)
        return string.format("%.1f m", value)
    end

    local function OnUpdate(_, delta)
        elapsed = elapsed + delta
        if elapsed < pollInterval then return end
        elapsed = 0

        local x, y, z = GetPosition()
        if not x then return end
        if lastX then
            local dx, dy, dz = x - lastX, y - lastY, z - lastZ
            local distance = math.sqrt(dx * dx + dy * dy + dz * dz) * yardsToMeters
            if distance > 0.05 then
                totalMeters = totalMeters + distance
                button:SetText("Parar " .. FormatMeters(totalMeters))
                label:SetText(FormatMeters(totalMeters))
            end
        end
        lastX, lastY, lastZ = x, y, z
    end

    button:SetScript("OnClick", function()
        if tracking then
            tracking = false
            button:SetScript("OnUpdate", nil)
            button:SetText("Movimiento")
            label:SetText(totalMeters > 0 and FormatMeters(totalMeters) or "")
            return
        end

        local x, y, z = GetPosition()
        if not x then
            label:SetText("Sin posición")
            return
        end
        totalMeters, elapsed = 0, 0
        lastX, lastY, lastZ = x, y, z
        tracking = true
        button:SetText("Parar  0.0m")
        label:SetText("0.0 m")
        button:SetScript("OnUpdate", OnUpdate)
    end)
end
