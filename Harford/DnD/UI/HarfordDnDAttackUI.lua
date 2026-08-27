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
local movListeners = {}

-- Avisa a quien pinte el movimiento. `tope` viene aparte del calculo de velocidad porque incluye
-- el doble de `Correr`, que es de ESTE turno y no una propiedad del personaje.
local function AvisarMovimiento(metros, tope)
    for _, fn in ipairs(movListeners) do
        pcall(fn, metros, tope)
    end
end

function API.RegisterMovementListener(fn)
    if type(fn) ~= "function" then return false end
    movListeners[#movListeners + 1] = fn
    return true
end

-- Metros que puede recorrer este turno, con el doble de `Correr` ya aplicado. Lo de fuera no puede
-- calcularlo por su cuenta: `Correr` vive aqui.
function API.GetTurnMovementMax()
    -- UNA sola cuenta. El seguimiento la publica al montarse y sabe cosas que aqui no se saben:
    -- que llevando un NPC manda la velocidad de SU ficha, no la tuya. Calcularlo aparte daba dos
    -- topes distintos --la barra ensenaba el tuyo mientras el contador usaba el suyo-- que es
    -- exactamente el fallo que ya nos costo la barra de movimiento entera.
    if API.CalcularTopeTurno then return API.CalcularTopeTurno() end
    -- Sin seguimiento montado se calcula igual: un dato que depende de que otro haya pasado por
    -- ahi no es un dato.
    local base = (HarfordDnDCalc and HarfordDnDCalc.GetTurnMovement
        and HarfordDnDCalc.GetTurnMovement()) or 0
    return API.DashActive and (base * 2) or base
end

-- De quien es el movimiento que se esta contando: tuyo, o del NPC que llevas. Lo usa la barra para
-- no hacer creer que 9 m son los tuyos cuando son los de un esqueleto.
function API.GetTurnMovementOwner()
    if API.MovimientoDeNpc and API.MovimientoDeNpc() then
        return (UnitName and UnitName("pet")) or "NPC", true
    end
    return nil, false
end

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
    local pollInterval = 0.05
    local tracking = false
    local ArrancarSeguimiento  -- se asigna abajo; lo llama el reinicio de turno, que esta antes
    local ultimoTiron = 0
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

    -- Al empezar tu turno el movimiento vuelve a cero y arranca solo: es lo que hace que el
    -- contador signifique algo.
    --
    -- Se apunta DIRECTAMENTE en la lista, sin pasar por `RegisterMyTurnListener`, porque este
    -- fichero carga ANTES que `HarfordTurns.lua` (linea 102 del toc contra la 123) y esa funcion
    -- todavia no existe: el `if` de antes no se cumplia nunca y el oyente no se registraba jamas.
    -- La lista si se puede sembrar, porque `HarfordTurns` la crea con `or {}` y respeta lo que
    -- encuentre. Esto NO es un apano de orden con temporizadores -- es no depender del orden.
    local ReiniciarPorTurno
    do
        _G.HarfordTurnOrderAPI = _G.HarfordTurnOrderAPI or {}
        local T = _G.HarfordTurnOrderAPI
        T._myTurnListeners = T._myTurnListeners or {}
        T._myTurnListeners[#T._myTurnListeners + 1] = function()
            if ReiniciarPorTurno then ReiniciarPorTurno() end
        end
    end

    -- Se esta llevando a un NPC? Un NPC poseido es el `pet` del cliente. Es la UNICA situacion en
    -- la que no se puede medir por posicion: `UnitPosition` solo habla del jugador, y de la
    -- criatura poseida no devuelve nada.
    local function LlevandoNpc()
        return (UnitExists and UnitExists("pet")) and true or false
    end

    -- Velocidad REAL del NPC en metros por segundo. `GetUnitSpeed` da yardas/segundo y responde a
    -- ralentizaciones y aceleraciones; dar por buena la carrera base (7 yd/s, que es lo que hace
    -- Atlas) haria que un NPC ralentizado gastase su turno igual de rapido que uno suelto.
    local function VelocidadMetrosNpc()
        if not GetUnitSpeed then return 0 end
        return (tonumber(GetUnitSpeed("pet")) or 0) * 0.9144
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

    -- Donde terminaste tu movimiento, para poder volver si te desplazan o te vas de sitio durante
    -- el turno de otro. `C_Epsilon.GetPosition` da x/y/z; el mapa del SERVIDOR sale de
    -- `GetInstanceInfo` -- `C_Map` devuelve el id de la interfaz, que no es el mismo -- y la
    -- orientacion de `GetPlayerFacing`, para no aparecer mirando al norte.
    local function CapturarAncla()
        if not (C_Epsilon and C_Epsilon.GetPosition) then return nil end
        local ok, x, y, z = pcall(C_Epsilon.GetPosition)
        if not ok or not tonumber(x) or not tonumber(y) then return nil end
        local mapa
        if GetInstanceInfo then
            local okI, id = pcall(function() return select(8, GetInstanceInfo()) end)
            if okI then mapa = tonumber(id) end
        end
        return {
            x = tonumber(x), y = tonumber(y), z = tonumber(z) or 0,
            map = mapa,
            o = (GetPlayerFacing and GetPlayerFacing()) or 0,
        }
    end

    -- `Correr` dobla el tope de ESTE turno. Se guarda aparte del calculo de velocidad porque no es
    -- una propiedad del personaje sino algo que hizo en este asalto.
    -- Frame de 1x1 pegado a UIParent, sin textura ni raton: existe solo para que su `OnUpdate`
    -- corra siempre. No se puede colgar del boton -- un frame oculto NO ejecuta `OnUpdate`, y con
    -- la ficha cerrada el contador se quedaba parado sin que nada lo dijera.
    local motor = API.MovementDriver
    if not motor then
        motor = CreateFrame("Frame", "HarfordMovementDriver", UIParent)
        motor:SetSize(1, 1)
        motor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        motor:Show()
        API.MovementDriver = motor
    end

    local corriendo = false

    -- Metros que puede recorrer el NPC que llevas, de SU stat block TRP3 ("Velocidad 9 m"). Sin
    -- esto se le aplicaba la velocidad de TU raza, que no tiene nada que ver con la suya -- y si
    -- el jugador no tenia raza puesta salia 0, o sea sin limite.
    local function VelocidadDelNpc()
        if not (HarfordTRP3 and HarfordTRP3.GetNPCStatBlock) then return nil end
        local ok, bloque = pcall(HarfordTRP3.GetNPCStatBlock, "pet")
        local texto = ok and bloque and tostring(bloque.speed or "") or ""
        if texto == "" then return nil end
        -- Se escribe a mano: "9 m", "9m", "9 metros", "30 pies". El primer numero es el que vale.
        local n = tonumber(texto:match("([%d%.]+)"))
        if not n then return nil end
        if texto:lower():find("pie") then return n * 0.3048 end
        return n
    end

    -- Se publica para que la barra del marcador use ESTA cuenta y no otra.
    local MaximoDelTurno
    API.MovimientoDeNpc = function() return LlevandoNpc() and VelocidadDelNpc() ~= nil end

    MaximoDelTurno = function()
        -- Llevando un NPC, su velocidad manda: la tuya no pinta nada mientras juegas lo suyo.
        if LlevandoNpc and LlevandoNpc() then
            local suya = VelocidadDelNpc()
            if suya and suya > 0 then
                local tope = corriendo and (suya * 2) or suya
                API.TurnMovementMax = tope
                return tope
            end
        end
        local base = (HarfordDnDCalc and HarfordDnDCalc.GetTurnMovement
            and HarfordDnDCalc.GetTurnMovement()) or 0
        local tope = corriendo and (base * 2) or base
        API.TurnMovementMax = tope
        return tope
    end
    API.CalcularTopeTurno = MaximoDelTurno

    -- Cuanto llevas DE cuanto puedes. Un numero suelto no dice si te has pasado, que es lo unico
    -- que la mesa necesita saber.
    local function FormatMeters(value)
        local tope = MaximoDelTurno()
        if tope <= 0 then return string.format("%.1f m", value) end
        local color = (value > tope + 0.05) and "|cffff4444" or "|cff88ff88"
        return string.format("%s%.1f|r / %.1f m", color, value, tope)
    end

    -- Hay combate Y YO ESTOY DENTRO: estar en la raid no es estar en la pelea. A quien solo mira
    -- no se le cuenta el movimiento ni se le pone muro.
    local function EnCombate()
        local T = HarfordTurnOrderAPI
        if not (T and T.HasActiveCombat and T.HasActiveCombat()) then return false end
        if T.AmIInCombat then return T.AmIInCombat() end
        return true
    end

    -- Moverse es tuyo mientras TE TOCA. Fuera de tu turno el contador no arranca y el muro te
    -- devuelve a donde estabas: si no, cruzabas la sala gratis durante el turno del enemigo.
    local function EsMiTurno()
        -- Llevar un NPC ES jugar SU turno: el DM lo mueve cuando le toca a el, no a los PJs.
        -- Preguntar aqui por el turno de los PJs le bloquearia el movimiento justo cuando debe
        -- moverse.
        if LlevandoNpc and LlevandoNpc() then return true end
        local T = HarfordTurnOrderAPI
        if not (T and T.IsMyTurn) then return true end
        return T.IsMyTurn()
    end

    -- Te devuelve al punto donde se te acabo el movimiento. Con enfriamiento corto: el servidor
    -- tarda en responder al `worldport`, y sin el se mandaria uno por muestra --veinte por
    -- segundo-- mientras el primero esta de camino.
    local ultimoTiron = 0
    local function Anclar()
        local ancla = API.RecordedMovementAnchor
        if not ancla then return end
        local ahora = (GetTime and GetTime()) or 0
        if ahora - ultimoTiron < 0.6 then return end
        if not (HarfordServerActions and HarfordServerActions.WorldportSelf) then return end
        ultimoTiron = ahora
        local ok, err = HarfordServerActions.WorldportSelf(ancla, { addonName = "Harford" })
        if ok then
            totalMeters = MaximoDelTurno()
            API.RecordedMovementMeters = totalMeters
            AvisarMovimiento(totalMeters, MaximoDelTurno())
        else
            HarfordChat.Print("|cffff5555No se pudo devolverte a tu sitio:|r "
                .. tostring(err or "error desconocido"))
        end
    end

    -- Se guarda en el store de turnos --que es SavedVariable-- sellado con el ASALTO y con tu
    -- guid. El sello es lo que impide que lo guardado de un combate se aplique a otro: si el
    -- asalto no coincide, no vale y se empieza limpio.
    local function Guardar()
        local store = HarfordTurnOrderStore
        if type(store) ~= "table" then return end
        store.movimiento = {
            guid = UnitGUID and UnitGUID("player") or nil,
            asalto = tonumber(store.asalto) or 0,
            metros = totalMeters,
            corriendo = corriendo or nil,
            ancla = API.RecordedMovementAnchor,
            inicio = API.TurnStartAnchor,
        }
    end

    local function Restaurar()
        local store = HarfordTurnOrderStore
        local g = type(store) == "table" and store.movimiento
        if type(g) ~= "table" then return false end
        -- Distinto asalto o distinto personaje: lo guardado no habla de este turno.
        if g.guid ~= (UnitGUID and UnitGUID("player")) then return false end
        if (tonumber(g.asalto) or -1) ~= (tonumber(store.asalto) or 0) then return false end
        totalMeters = tonumber(g.metros) or 0
        corriendo = g.corriendo and true or false
        API.DashActive = corriendo and true or nil
        API.RecordedMovementMeters = totalMeters
        API.RecordedMovementAnchor = g.ancla
        API.TurnStartAnchor = g.inicio
        return true
    end

    function API.SetDashActive(activo)
        API.DashActive = activo and true or nil
        corriendo = activo and true or false
        -- Correr DOBLA el tope, asi que si ya estabas agotado vuelves a tener sitio: hay que
        -- levantar el muro. Sin esto la accion se gastaba, el tope subia y el ancla seguia
        -- devolviendote al metro nueve -- o sea, Correr no hacia nada.
        if corriendo and API.RecordedMovementAnchor
            and totalMeters < MaximoDelTurno() then
            API.RecordedMovementAnchor = nil
            API.MovimientoSinMuro = nil
            HarfordChat.Print("|cff88ff88Correr:|r vuelves a tener movimiento.")
        end
        if API.RefreshMovement then API.RefreshMovement() end
        AvisarMovimiento(totalMeters, MaximoDelTurno())
    end

    local function OnUpdate(_, delta)
        elapsed = elapsed + delta
        if elapsed < pollInterval then return end
        local trozo = elapsed
        elapsed = 0

        local avance
        if LlevandoNpc() then
            -- De una criatura poseida no hay posicion que leer, asi que se INTEGRA su velocidad.
            -- Es una estimacion, pero con la velocidad REAL, no con la de carrera base.
            local v = VelocidadMetrosNpc()
            if v <= 0 then return end
            avance = v * trozo
        else
            -- Un JUGADOR si tiene posicion: se mide de donde estaba a donde esta. Eso es el dato
            -- real, y para el jugador no hace falta estimar nada.
            local x, y, z = GetPosition()
            if not x then return end
            if not lastX then lastX, lastY, lastZ = x, y, z return end
            local dx, dy, dz = x - lastX, y - lastY, z - lastZ
            avance = math.sqrt(dx * dx + dy * dy + dz * dz) * yardsToMeters
            lastX, lastY, lastZ = x, y, z
            -- Nadie recorre cinco metros en una vigesima de segundo a pie: eso es un
            -- desplazamiento (el teleporte de vuelta, un empujon), no un paso.
            if avance > 5 then avance = 0 end
            if avance <= 0.05 then return end
        end

        totalMeters = totalMeters + avance
        -- Se publica EN CADA PASO, no solo al parar. `GetRecordedMovementMeters` es lo que lee la
        -- barra de la economia, y solo se escribia en `StopTracking`: la barra se refrescaba bien
        -- --el aviso llegaba-- pero leia un cero, asi que se quedaba llena mientras el contador
        -- corria por dentro y hasta te avisaba de que lo habias agotado.
        API.RecordedMovementMeters = totalMeters
        button:SetText("Parar " .. FormatMeters(totalMeters))
        label:SetText(FormatMeters(totalMeters))
        AvisarMovimiento(totalMeters, MaximoDelTurno())

        -- Fuera de combate el contador MIDE, pero no ata: no se marca ancla y por tanto no hay
        -- muro. Solo dentro de un combate por turnos el movimiento es un recurso que se acaba.
        -- Si ya te habias quedado sin recurso y sigues andando, se te devuelve otra vez: el muro
        -- no es un aviso de una sola vez. El salto de vuelta no cuenta como paso (guardia de 5 m),
        -- asi que no se realimenta.
        if API.RecordedMovementAnchor and EnCombate() then Anclar() end

        local tope = MaximoDelTurno()
        if EnCombate() and tope > 0 and totalMeters >= tope and not API.RecordedMovementAnchor
            and not API.MovimientoSinMuro then
            if LlevandoNpc() then
                -- Al NPC se le cuenta y se le avisa, pero no se le pone muro: no hay con que.
                -- `worldport` mueve TU cuerpo, no a la criatura poseida, y `npc info` actua sobre
                -- el objetivo, que mientras posees no es ella. Corregir es cosa del DM, igual que
                -- en Atlas, cuyo muro se salta entero mientras se posee.
                API.MovimientoSinMuro = true
                HarfordChat.Print("|cffffcc00" .. tostring(UnitName and UnitName("pet") or "El NPC")
                    .. " ha agotado su movimiento.|r Devuelvelo tu: no hay comando que mueva a una "
                    .. "criatura poseida.")
            else
                -- Se marca EL PUNTO EXACTO donde se acabo y te quedas ahi EN ESE MOMENTO, no al
                -- soltar la tecla: el recurso se agota cuando se agota, y esperar a que pares
                -- deja andar metros de regalo mientras tanto.
                API.RecordedMovementAnchor = CapturarAncla()
                HarfordChat.Print("|cffffcc00Has agotado tu movimiento.|r")
                Anclar()
            end
        end
        API.RecordedMovementInfo = { meters = totalMeters }
        Guardar()
    end

    local function StopTracking()
        if not tracking then return end
        tracking = false
        motor:SetScript("OnUpdate", nil)
        button:SetText("Movimiento")
        label:SetText(totalMeters > 0 and FormatMeters(totalMeters) or "")
        API.RecordedMovementMeters = totalMeters
        AvisarMovimiento(totalMeters, MaximoDelTurno())
        -- Y se ANCLA aqui: es el sitio donde terminaste, al que querras volver si te empujan o te
        -- mueves durante el turno de otro.
        API.RecordedMovementAnchor = CapturarAncla()
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
    -- Se expone para que la recogida de fin de combate pueda pararlo desde fuera.
    API.ResetTurnMovement = function() if ReiniciarPorTurno then ReiniciarPorTurno() end end
    -- Como el reinicio de turno pero SIN tocar el ancla de inicio: sigues donde estas y en el
    -- mismo turno, solo que sin deber los metros. Reiniciar del todo te dejaria sin sitio al que
    -- volver si luego te pasas.
    API.ResetTurnMovementKeepAnchor = function()
        totalMeters = 0
        lastX, lastY, lastZ = nil, nil, nil
        API.RecordedMovementMeters = 0
        API.RecordedMovementAnchor = nil
        API.MovimientoSinMuro = nil
        if label then label:SetText(FormatMeters(0)) end
        AvisarMovimiento(0, MaximoDelTurno())
        HarfordChat.Print("|cff88ff88Se te ha devuelto el movimiento de este turno.|r")
    end
    ReiniciarPorTurno = function()
        tracking = false
        motor:SetScript("OnUpdate", nil)
        button:SetText("Movimiento")
        totalMeters, elapsed = 0, 0
        lastX, lastY, lastZ = nil, nil, nil
        API.RecordedMovementMeters = 0
        API.RecordedMovementInfo = nil
        -- El ancla del turno pasado ya no vale: volver ahi te devolveria un asalto entero atras.
        API.RecordedMovementAnchor = nil
        API.MovimientoSinMuro = nil
        -- Y si corriste el turno pasado, ese doble no se hereda.
        corriendo = false
        API.DashActive = nil
        ultimoTiron = 0
        label:SetText("")
        -- Y arranca SOLO. Tener que acordarse de pulsar el boton cada turno es la friccion que
        -- hace que la cuenta no se lleve nunca; el boton queda para pararla antes de tiempo.
        AvisarMovimiento(0, MaximoDelTurno())
        -- Donde empiezas el turno. Son DOS anclas y hacen cosas distintas: a esta se vuelve a mano
        -- para deshacer el turno entero; a la del agotamiento te devuelve el muro.
        API.TurnStartAnchor = CapturarAncla()
        if Guardar then Guardar() end
        if ArrancarSeguimiento then ArrancarSeguimiento(false) end
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

    ArrancarSeguimiento = function(aMano)
        if tracking then return end
        -- Fuera de combate no hay turno que gastar: el contador no arranca solo. A mano si -- el
        -- boton sigue valiendo para medir una distancia cuando te apetezca.
        if not aMano and (not EnCombate() or not EsMiTurno()) then return end
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
        label:SetText(FormatMeters(0))
        motor:SetScript("OnUpdate", OnUpdate)
    end

    -- Deshacer el movimiento del turno: vuelves a donde EMPEZASTE y el contador se pone a cero,
    -- como si no te hubieras movido. Es lo que quieres cuando te has colocado mal, no volver al
    -- punto donde se te acabo -- para eso ya esta el muro.
    local function VolverAlAncla()
        local ancla = API.TurnStartAnchor
        if not ancla then
            HarfordChat.Print("No se donde empezaste el turno: no hay sitio al que volver.")
            return
        end
        if not (HarfordServerActions and HarfordServerActions.WorldportSelf) then return end
        local ok, err = HarfordServerActions.WorldportSelf(ancla, { addonName = "Harford" })
        if not ok then
            HarfordChat.Print("No se pudo volver: " .. tostring(err or "error desconocido"))
            return
        end
        totalMeters = 0
        lastX, lastY, lastZ = nil, nil, nil
        API.RecordedMovementMeters = 0
        API.RecordedMovementAnchor = nil
        label:SetText(FormatMeters(0))
        AvisarMovimiento(0, MaximoDelTurno())
        HarfordChat.Print("Vuelves a donde empezaste el turno. Movimiento a cero.")
    end
    API.DoReturnToTurnStart = VolverAlAncla

    -- Tras un `/reload` no hay aviso de turno que espere: el turno ya estaba empezado. Se retoma
    -- con lo que quedo guardado, o el resto del turno seria movimiento gratis.
    do
        local ev = CreateFrame("Frame")
        ev:RegisterEvent("PLAYER_ENTERING_WORLD")
        ev:SetScript("OnEvent", function(self)
            self:UnregisterAllEvents()
            if not EnCombate() then return end
            if not Restaurar() then return end
            label:SetText(FormatMeters(totalMeters))
            AvisarMovimiento(totalMeters, MaximoDelTurno())
            ArrancarSeguimiento(true)
            HarfordChat.Print(string.format(
                "Retomado tu movimiento del turno: |cffffcc00%.1f m|r gastados.", totalMeters))
        end)
    end

    -- RESPALDO del muro: el tiron principal salta en el instante en que se agota el recurso, aqui
    -- arriba en el `OnUpdate`. Esto solo recoge el caso de que sueltes la tecla justo cuando se
    -- acababa y la ultima muestra no llegara a verlo. `TurnOrActionStop` queda FUERA a proposito
    -- -- es el giro de camara con el raton, y girar la vista no es moverse.
    do
        local TECLAS = {
            "MoveForwardStop", "MoveBackwardStop",
            "StrafeLeftStop", "StrafeRightStop",
            "TurnLeftStop", "TurnRightStop",
            "CameraOrSelectOrMoveStop", "JumpOrAscendStart",
        }
        local function Tirar()
            -- Doble guardia: sin combate no se tira de nadie ni aunque quedara un ancla vieja de
            -- un combate anterior.
            if not EnCombate() then return end
            local ancla = API.RecordedMovementAnchor
            if not ancla then return end
            local tope = MaximoDelTurno()
            if tope <= 0 or totalMeters <= tope + 0.3 then return end
            -- Comparte enfriamiento con el tiron del `OnUpdate`: soltar varias teclas a la vez
            -- dispara varios enganches seguidos, y eso serian tres `worldport` para un frenazo.
            Anclar()
        end
        for _, nombre in ipairs(TECLAS) do
            if type(_G[nombre]) == "function" then
                hooksecurefunc(nombre, function()
                    if tracking then Tirar() end
                end)
            end
        end
    end

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, boton)
        -- Derecho: volver al ancla. Es un comando que te MUEVE, asi que va en un gesto distinto
        -- del que se pulsa cada turno, no vaya a portarte por querer parar el contador.
        if boton == "RightButton" then
            VolverAlAncla()
            return
        end
        if tracking then
            StopTracking()
            return
        end
        -- A mano se arranca aunque no haya combate: el boton tambien sirve para medir una
        -- distancia sin mas. Lo que no ocurre fuera de combate es que arranque SOLO.
        ArrancarSeguimiento(true)
    end)

    if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
        HarfordDnDConditions.RegisterListener(function()
            RefreshConditionState()
            -- Al terminar el combate se para y se limpia. El turno no "termina" -- desaparece el
            -- combate entero --, asi que sin esto el contador se quedaba corriendo con un tope que
            -- ya no significaba nada, y el muro seguia devolviendote a un sitio de otro combate.
            if tracking and (not EnCombate() or not EsMiTurno()) then
                -- Al pasar el turno a otro se para donde estabas: el ancla se queda, asi que si
                -- sigues andando el muro te devuelve. Moverse en el turno de otro no es gratis.
                tracking = false
                motor:SetScript("OnUpdate", nil)
                button:SetText("Movimiento")
                if not API.RecordedMovementAnchor then
                    API.RecordedMovementAnchor = CapturarAncla()
                end
            end
        end)
    end
    RefreshConditionState()
end

-- Para el contador y lo deja a cero. Lo llama la recogida de fin de combate: fuera de un combate
-- no hay turno que gastar, y el ancla del muro apunta a un sitio de un combate que ya no existe.
-- Vuelve a donde EMPEZASTE el turno y pone el contador a cero. Se expone porque el gesto vive en
-- la barra del marcador de turnos, que esta en otro modulo.
function API.ReturnToTurnStart()
    if API.DoReturnToTurnStart then API.DoReturnToTurnStart() end
end

-- Devuelve el movimiento del turno: contador a cero y muro levantado. Lo usa el DM cuando el
-- desplazamiento no llego a contar --te empujaron, se cancelo-- y no tiene sentido que lo pagues.
-- No te MUEVE: solo deja de deberlo.
function API.RefundTurnMovement()
    if API.ResetTurnMovementKeepAnchor then API.ResetTurnMovementKeepAnchor() end
end

function API.StopTurnMovement()
    if API.ResetTurnMovement then API.ResetTurnMovement() end
end

function API.GetRecordedMovementMeters()
    return tonumber(API.RecordedMovementMeters) or 0
end

function API.GetRecordedMovementInfo()
    return API.RecordedMovementInfo
end
