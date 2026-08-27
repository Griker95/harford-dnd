-- HarfordDnDAttackUI: construccion y estado visual de la seccion Ataque.
-- Las reglas, tiradas y aplicacion de dano siguen en HarfordDnD/HarfordDnDCombat.

HarfordDnDAttackUI = HarfordDnDAttackUI or {}

local API = HarfordDnDAttackUI
local DAMAGE_LABEL = "Da" .. string.char(195, 177) .. "o"

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

    -- MANIOBRAS del Manual del Jugador que no son un ataque: agarrar, empujar, escapar,
    -- estabilizar y cobertura. Van todas en un unico boton porque la seccion Ataque no tiene
    -- alto libre para otra fila (las dos filas de botones ya llegan a -166 sobre 183 de panel).
    -- La COBERTURA se DECLARA, no se calcula: el addon conoce posiciones pero no la geometria
    -- del mundo, asi que no puede saber que hay un muro en medio.
    if armorBox then
        local manBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        manBtn:SetSize(96, 18)
        manBtn:SetPoint("TOPRIGHT", armorBox, "BOTTOMRIGHT", 0, -4)

        local function CoverMenu(M)
            local out = {}
            for _, id in ipairs(M.COVER_ORDER) do
                local def = M.COVER[id]
                out[#out + 1] = {
                    text = def.label .. (def.ac and (" (+" .. def.ac .. ")") or " (no elegible)"),
                    checked = select(1, M.GetCover()) == id,
                    func = function()
                        M.SetCover(id)
                        if API.RefreshCover then API.RefreshCover() end
                    end,
                }
            end
            return out
        end

        manBtn:SetScript("OnClick", function(self)
            local M = HarfordDnDManeuvers
            if not M then return end
            -- Agarrar/empujar sustituyen a UNO de tus ataques y son prueba enfrentada: aqui se
            -- tira y se anuncia el numero a superar; quien defiende elige Atletismo o Acrobacias
            -- y responde con su ficha, igual que en las salvaciones de las maniobras de picaro.
            local menu = {
                { text = "Maniobras", isTitle = true, notCheckable = true },
                { text = "Agarrar", notCheckable = true, func = function() M.Grapple("target") end },
                { text = "Empujar", notCheckable = true, func = function() M.Shove("target") end },
                { text = "Escapar del agarre", notCheckable = true, hasArrow = true, menuList = {
                    { text = "Con Atletismo", notCheckable = true, func = function() M.Escape("Atletismo") end },
                    { text = "Con Acrobacias", notCheckable = true, func = function() M.Escape("Acrobacias") end },
                } },
                { text = "Soltar a quien agarras", notCheckable = true, func = function() M.ReleaseGrapple("target") end },
                { text = "Estabilizar", notCheckable = true, hasArrow = true, menuList = {
                    { text = "Prueba de Medicina (CD 10)", notCheckable = true, func = function() M.Stabilize("target", false) end },
                    { text = "Con utiles de sanador (sin prueba)", notCheckable = true, func = function() M.Stabilize("target", true) end },
                } },
                { text = "Cobertura del objetivo", notCheckable = true, hasArrow = true, menuList = CoverMenu(M) },
            }
            if EasyMenu then
                parent._maneuverMenu = parent._maneuverMenu
                    or CreateFrame("Frame", "HarfordManeuverMenu", UIParent, "UIDropDownMenuTemplate")
                EasyMenu(menu, parent._maneuverMenu, self, 0, 0, "MENU")
            end
        end)
        manBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Maniobras", 1, 0.82, 0)
            GameTooltip:AddLine("Agarrar y empujar sustituyen a uno de tus ataques: prueba enfrentada de Atletismo contra el Atletismo o las Acrobacias del objetivo, a su eleccion.", 1, 1, 1, true)
            GameTooltip:AddLine("Estabilizar es una accion: Medicina CD 10, o sin prueba con los utiles de sanador.", 1, 1, 1, true)
            GameTooltip:AddLine("Cobertura: media +2, tres cuartos +5 a la CA y salvaciones de Destreza del objetivo. Total: no puede ser elegido.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        manBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        controls.maneuverButton = manBtn
        controls.coverButton = manBtn   -- compatibilidad con el nombre anterior

        -- La cara del boton muestra la cobertura cuando hay una declarada, porque es el unico
        -- estado del menu que sigue activo y modifica cada tirada de ataque.
        function API.RefreshCover()
            local M = HarfordDnDManeuvers
            local level, def
            if M then level, def = M.GetCover() end
            if def and level ~= "none" then
                manBtn:SetText("Cob: " .. def.label)
            else
                manBtn:SetText("Maniobras")
            end
        end
        API.RefreshCover()
    end

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
    weaponText:SetPoint("TOPLEFT", linkFrame, "TOPLEFT", 0, 0)
    weaponText:SetPoint("BOTTOMRIGHT", linkFrame, "BOTTOMRIGHT", -20, 0)
    weaponText:SetJustifyH("LEFT")
    weaponText:SetJustifyV("TOP")
    weaponText:SetWordWrap(true)
    weaponText:SetMaxLines(2)
    weaponText:SetText("")
    controls.weaponInfoText = weaponText

    -- Flecha de acciones de forma. Solo aparece con una forma activa que tenga
    -- mas de un ataque; no interviene en las armas normales.
    local formAction = CreateFrame("Button", nil, linkFrame)
    -- La textura original mide 23x11 antes de rotarse; al mirar a la derecha
    -- ocupa 11x23. El frame debe tener esas medidas finales para no aplastarla.
    formAction:SetSize(11, 23)
    formAction:SetPoint("RIGHT", linkFrame, "RIGHT", -5, 0)
    formAction.icon = formAction:CreateTexture(nil, "ARTWORK")
    formAction.icon:SetAllPoints(formAction)
    formAction.icon:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
    formAction.icon:SetTexCoord(0.625, 0.984375, 0.7421875, 0.828125)
    if SetClampedTextureRotation then
        SetClampedTextureRotation(formAction.icon, 90)
    elseif formAction.icon.SetRotation then
        formAction.icon:SetRotation(math.pi / 2)
    end
    formAction.hl = formAction:CreateTexture(nil, "HIGHLIGHT")
    formAction.hl:SetAllPoints(formAction)
    formAction.hl:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    formAction.hl:SetBlendMode("ADD")
    formAction:SetScript("OnClick", function(self)
        if not (API.weaponInfoDeps and API.weaponInfoDeps.openFormActionMenu) then return end
        API.weaponInfoDeps.openFormActionMenu(self)
    end)
    formAction:Hide()
    controls.formActionButton = formAction

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
    -- "Natural" es un marcador interno de las formas, no un sufijo que
    -- aparezca en la ficha TRP3. Las propiedades de armas normales si se
    -- mantienen visibles.
    local props = (def and def.source == "form") and "" or (HarfordDnDWeapons
        and HarfordDnDWeapons.WeaponPropsLabel and HarfordDnDWeapons.WeaponPropsLabel(def) or "")
    local infoLabel = props ~= "" and (nameLabel .. " " .. props) or nameLabel
    local context = HarfordDnDContext and HarfordDnDContext.State
    if not (context and context.active)
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("extraAttack") then
        infoLabel = infoLabel .. "  |cff88ccff(Ataque adicional: x2)|r"
    end
    if controls.weaponInfoText then controls.weaponInfoText:SetText(infoLabel) end
    if controls.weaponLinkFrame then
        if def and def.source == "form" and deps.getFormWeaponTooltip then
            local title, lines = deps.getFormWeaponTooltip()
            controls.weaponLinkFrame:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(title or nameLabel, 1, 0.82, 0, true)
                for _, line in ipairs(lines or {}) do GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true) end
                GameTooltip:Show()
            end)
            controls.weaponLinkFrame:SetScript("OnLeave", LeaveItemLink)
        else
            controls.weaponLinkFrame:SetScript("OnEnter", nil)
            controls.weaponLinkFrame:SetScript("OnLeave", nil)
        end
    end
    if controls.formActionButton then
        local actions = deps.getFormActions and deps.getFormActions() or {}
        local specials = deps.getFormSpecialActions and deps.getFormSpecialActions() or {}
        controls.formActionButton:SetShown((#actions + #specials) > 1)
    end

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
            local text = DAMAGE_LABEL .. " extra"
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
    -- Una forma no hereda el bonus del arma equipada, pero el bonus de dano
    -- que trae su propia accion sigue formando parte de la tirada.
    local weaponMod = (deps.getWeaponSlotDamageBonus and deps.getWeaponSlotDamageBonus(def) or 0)
    if not (def and def.ignoreGlobalWeaponBonuses) then
        weaponMod = weaponMod + (HarfordDnDCalc and HarfordDnDCalc.GetWeaponDamageBonus
            and HarfordDnDCalc.GetWeaponDamageBonus() or (HarfordDnDCalc and HarfordDnDCalc.GetWeaponMod and HarfordDnDCalc.GetWeaponMod() or 0))
    end
    -- Para MOSTRAR se usa WeaponDamageText: el desarmado es 1 fijo y "1d1" se lee mal.
    local dice = HarfordDnDWeapons and HarfordDnDWeapons.WeaponDamageText
        and HarfordDnDWeapons.WeaponDamageText(def) or "1d4"
    local parts = {}
    if abilityMod ~= 0 then parts[#parts + 1] = deps.formatSigned(abilityMod) end
    if weaponMod ~= 0 then parts[#parts + 1] = deps.formatSigned(weaponMod) end
    local damageType = def and def.dmgType or ""
    if HarfordDamageTypes and HarfordDamageTypes.FromWord then
        damageType = HarfordDamageTypes.FromWord(damageType) or damageType
    end
    if HarfordDamageTypes and HarfordDamageTypes.GetLabel then
        damageType = HarfordDamageTypes.GetLabel(damageType)
    end
    local damageTypeText = damageType ~= "" and (" " .. damageType) or ""
    if controls.dmgInfoText then
        controls.dmgInfoText:SetText((DAMAGE_LABEL .. ": %s%s%s"):format(dice, table.concat(parts, ""), damageTypeText))
    end
    if store.RefreshWeaponDamageButton then store.RefreshWeaponDamageButton() end
end

-- Economia de turno (accion / adicional / reaccion) en la banda inferior de la seccion Ataque.
-- Se ancla a BOTTOMRIGHT y no a un desplazamiento fijo: las dos filas de botones llegan a -166
-- sobre 183 de panel, asi que la unica franja libre es la de abajo y anclarla por el borde la
-- mantiene ahi aunque cambie el alto del panel.
--
-- Solo se ve mientras hay orden de turnos: fuera de combate no se lleva la cuenta de acciones y
-- un contador congelado a 1/1 seria informacion falsa.
function API.CreateTurnEconomyLabel(opts)
    opts = opts or {}
    local parent = opts.parent
    if not parent then return nil end

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 4)
    label:SetJustifyH("RIGHT")
    label:SetText("")

    local function Refresh()
        local T = HarfordDnDConditions and HarfordDnDConditions.Turn
        label:SetText((T and T.StatusShort and T.StatusShort()) or "")
    end
    Refresh()

    -- El motor de condiciones avisa a sus listeners cada vez que cambia algo, incluido el gasto y
    -- el reinicio de turno, asi que no hace falta ningun ticker.
    if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
        HarfordDnDConditions.RegisterListener(Refresh)
    end

    API.Controls.turnEconomyLabel = label
    API.RefreshTurnEconomy = Refresh
    return label
end

function API.AttachMovementTracker(opts)
    opts = opts or {}
    local parent = opts.parent
    if not parent then return end

    local yardsToMeters = 0.9144
    local pollInterval = 0.1
    local tracking = false
    local totalMeters = 0
    local startX, startY, startZ
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

    -- Al empezar tu turno el movimiento vuelve a cero: es lo que hace que el contador signifique
    -- algo. Antes acumulaba desde que pulsabas y no se enteraba de los turnos.
    local ReiniciarPorTurno
    if HarfordTurnOrderAPI and HarfordTurnOrderAPI.RegisterMyTurnListener then
        HarfordTurnOrderAPI.RegisterMyTurnListener(function()
            if ReiniciarPorTurno then ReiniciarPorTurno() end
        end)
    end

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

    local function MaximoDelTurno()
        return (HarfordDnDCalc and HarfordDnDCalc.GetTurnMovement
            and HarfordDnDCalc.GetTurnMovement()) or 0
    end

    -- Cuanto llevas DE cuanto puedes. Un numero suelto no dice si te has pasado, que es lo unico
    -- que la mesa necesita saber.
    local function FormatMeters(value)
        local tope = MaximoDelTurno()
        if tope <= 0 then return string.format("%.1f m", value) end
        local color = (value > tope + 0.05) and "|cffff4444" or "|cff88ff88"
        return string.format("%s%.1f|r / %.1f m", color, value, tope)
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
        API.RecordedMovementInfo = { meters = totalMeters, startX = startX, startY = startY, startZ = startZ, endX = x, endY = y, endZ = z }
    end

    local function StopTracking()
        if not tracking then return end
        tracking = false
        button:SetScript("OnUpdate", nil)
        button:SetText("Movimiento")
        label:SetText(totalMeters > 0 and FormatMeters(totalMeters) or "")
        API.RecordedMovementMeters = totalMeters
        -- Se cuenta en la mesa AL PARAR, no en cada paso: difundir cada decima llenaria el canal
        -- para decir lo mismo. Lo que importa es cuanto recorriste y si te pasaste.
        if totalMeters > 0.05 and HarfordDnDRolls and HarfordDnDRolls.Broadcast then
            local tope = MaximoDelTurno()
            local texto = (tope > 0)
                and string.format("se mueve %.1f m de %.1f", totalMeters, tope)
                or string.format("se mueve %.1f m", totalMeters)
            if tope > 0 and totalMeters > tope + 0.05 then
                texto = texto .. " |cffff4444(se pasa " .. string.format("%.1f", totalMeters - tope) .. " m)|r"
            end
            HarfordDnDRolls.Broadcast({ type = "info", label = texto })
        end
    end

    -- Vuelve a cero SIN contarlo en la mesa: el turno nuevo empieza limpio, no es que hayas
    -- terminado de moverte.
    ReiniciarPorTurno = function()
        tracking = false
        button:SetScript("OnUpdate", nil)
        button:SetText("Movimiento")
        totalMeters, elapsed = 0, 0
        lastX, lastY, lastZ = nil, nil, nil
        API.RecordedMovementMeters = 0
        API.RecordedMovementInfo = nil
        label:SetText("")
    end

    local function RefreshConditionState()
        local speedZero = HarfordDnDConditions and HarfordDnDConditions.IsSpeedZero
            and HarfordDnDConditions.IsSpeedZero("player")
        if speedZero then
            StopTracking()
            button:Disable()
            label:SetText("Velocidad 0")
        else
            button:Enable()
            if not tracking and label:GetText() == "Velocidad 0" then label:SetText("") end
        end
    end

    button:SetScript("OnClick", function()
        if tracking then
            StopTracking()
            return
        end

        if HarfordDnDConditions and HarfordDnDConditions.IsSpeedZero
            and HarfordDnDConditions.IsSpeedZero("player") then
            RefreshConditionState()
            return
        end

        local x, y, z = GetPosition()
        if not x then
            label:SetText("Sin posición")
            return
        end
        totalMeters, elapsed = 0, 0
        API.RecordedMovementMeters = 0
        lastX, lastY, lastZ = x, y, z
        startX, startY, startZ = x, y, z
        API.RecordedMovementInfo = { meters = 0, startX = x, startY = y, startZ = z, endX = x, endY = y, endZ = z }
        tracking = true
        button:SetText("Parar  0.0m")
        label:SetText("0.0 m")
        button:SetScript("OnUpdate", OnUpdate)
    end)

    if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
        HarfordDnDConditions.RegisterListener(RefreshConditionState)
    end
    RefreshConditionState()
end

function API.GetRecordedMovementMeters()
    return tonumber(API.RecordedMovementMeters) or 0
end

function API.GetRecordedMovementInfo()
    return API.RecordedMovementInfo
end
