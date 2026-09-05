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

    -- La COBERTURA se DECLARA, no se calcula: el addon conoce posiciones pero no la geometria
    -- del mundo, asi que no puede saber que hay un muro en medio.
    if armorBox then
        local coverBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        coverBtn:SetSize(96, 18)
        coverBtn:SetPoint("TOPRIGHT", armorBox, "BOTTOMRIGHT", 0, -4)
        coverBtn:SetText("Cobertura")

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

        coverBtn:SetScript("OnClick", function(self)
            local M = HarfordDnDManeuvers
            if not M then return end
            if EasyMenu then
                parent._coverMenu = parent._coverMenu
                    or CreateFrame("Frame", "HarfordCoverMenu", UIParent, "UIDropDownMenuTemplate")
                EasyMenu(CoverMenu(M), parent._coverMenu, self, 0, 0, "MENU")
            end
        end)
        coverBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Cobertura", 1, 0.82, 0)
            GameTooltip:AddLine("Cobertura: media +2 o alta +5 a la CA y salvaciones de Destreza del objetivo.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        coverBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        controls.coverButton = coverBtn

        function API.RefreshCover()
            coverBtn:SetText("Cobertura")
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
            and HarfordDnDCalc.GetWeaponDamageBonus(def) or (HarfordDnDCalc and HarfordDnDCalc.GetWeaponMod and HarfordDnDCalc.GetWeaponMod() or 0))
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
    -- La sesion de seguimiento pertenece al NPC poseido o al jugador desde que ARRANCA; el
    -- OnUpdate corta y reinicia cuando el cuerpo activo deja de casar con la sesion.
    local sesionNpc = false
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
    local StopTracking  -- forward: el OnUpdate corta la sesion NPC al des-poseer y se define abajo
    -- Y el ancla del turno AJENO. Va por el oyente de cambio de turno --no por el de condiciones--
    -- porque tiene que dispararse SIEMPRE que el turno pase a otro, aunque tu contador nunca
    -- llegara a arrancar en este combate: el camino viejo solo anclaba al PARAR un seguimiento
    -- vivo, asi que quien se unia, recargaba o empezaba el combate en turno enemigo no tenia ni
    -- ancla ni motor, y cruzaba la sala gratis mientras jugaban los demas.
    local AnclarPorTurnoAjeno
    do
        _G.HarfordTurnOrderAPI = _G.HarfordTurnOrderAPI or {}
        local T = _G.HarfordTurnOrderAPI
        T._myTurnListeners = T._myTurnListeners or {}
        T._myTurnListeners[#T._myTurnListeners + 1] = function()
            if ReiniciarPorTurno then ReiniciarPorTurno() end
        end
        T._turnChangedListeners = T._turnChangedListeners or {}
        T._turnChangedListeners[#T._turnChangedListeners + 1] = function()
            -- El NPC no tiene una entrada de turno individual cuando se juega por bandos. Se
            -- compara el GUID de la criatura poseida contra los miembros del bloque activo.
            local petGuid = UnitGUID and UnitGUID("pet")
            if petGuid and T.IsNpcTurn and T.IsNpcTurn(petGuid) then
                if ReiniciarPorTurno then ReiniciarPorTurno() end
                return
            end
            if AnclarPorTurnoAjeno then AnclarPorTurnoAjeno() end
        end
    end

    -- Se esta llevando a un NPC? Un NPC poseido es el `pet` del cliente. Es la UNICA situacion en
    -- la que no se puede medir por posicion: `UnitPosition` solo habla del jugador, y de la
    -- criatura poseida no devuelve nada.
    local function LlevandoNpc()
        return (UnitExists and UnitExists("pet")) and true or false
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

    -- Metros que puede recorrer el NPC que llevas. Se leen del contexto que HarfordAdmin creo al
    -- seleccionar al NPC, no de `pet`: el perfil TRP3 de una unidad poseida no es consultable de
    -- manera fiable y devolvia nil aunque la ficha tuviera velocidad.
    local function VelocidadDelNpc()
        local guid = UnitGUID and UnitGUID("pet")
        if not (guid and HarfordDnDAPI and HarfordDnDAPI.GetNpcMovementMeters) then return nil end
        return HarfordDnDAPI.GetNpcMovementMeters(guid)
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
        -- Tope MANUAL (engranaje del unitframe): sustituye la base de la ficha — monturas,
        -- dictados de mesa — y las capas de estado (mitad, Correr) siguen aplicando encima.
        local override = tonumber(API.MovementMaxOverride)
        if override and override > 0 then base = override end
        -- Velocidad A LA MITAD (nivel 2 de cansancio y equivalentes): el motor de condiciones lo
        -- sabia (IsSpeedHalved) pero el contador no lo miraba — el tooltip lo decia y el muro te
        -- dejaba andar entero. Correr dobla DESPUES, sobre la velocidad ya partida, como en 5e.
        if HarfordDnDConditions and HarfordDnDConditions.IsSpeedHalved
            and HarfordDnDConditions.IsSpeedHalved("player") then
            base = base / 2
        end
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

    -- El DM se mueve LIBRE mientras no le toca: esta llevando la escena, no jugando su personaje.
    -- Atarle el cuerpo cada dos pasos le impide dirigir. En vez de eso vuelve DE GOLPE al empezar
    -- su turno --el TP de `ReiniciarPorTurno`-- asi que su personaje no gana un palmo de terreno:
    -- roda todo lo que quiera y acaba donde lo dejo.
    --
    -- Solo si esta DENTRO del combate, claro. Un DM que no figura en la lista no tiene turno ni
    -- movimiento que gastar, y `EnCombate` ya devuelve false para el.
    local function DirigiendoLaEscena()
        return HarfordAuthority and HarfordAuthority.CanUseDMTools
            and HarfordAuthority.CanUseDMTools() == true
    end

    -- Moverse es tuyo mientras TE TOCA. Fuera de tu turno el contador no arranca y el muro te
    -- devuelve a donde estabas: si no, cruzabas la sala gratis durante el turno del enemigo.
    local function EsMiTurno()
        -- Llevar un NPC no equivale a que le toque siempre: en un combate por bandos solo puede
        -- moverse cuando su GUID pertenece al bloque activo.
        if LlevandoNpc and LlevandoNpc() then
            local T = HarfordTurnOrderAPI
            local guid = UnitGUID and UnitGUID("pet")
            if T and T.IsNpcTurn and guid then return T.IsNpcTurn(guid) end
            return false
        end
        local T = HarfordTurnOrderAPI
        if not (T and T.IsMyTurn) then return true end
        return T.IsMyTurn()
    end

    -- Te devuelve al punto donde se te acabo el movimiento. Con enfriamiento corto: el servidor
    -- tarda en responder al `worldport`, y sin el se mandaria uno por muestra --veinte por
    -- segundo-- mientras el primero esta de camino.
    local ultimoTiron = 0
    -- ¿Estas de verdad LEJOS del ancla? Sin esta guardia el muro tiraba de ti cada 0,6 s aunque
    -- estuvieras QUIETO encima del ancla: el worldport continuo tenia al PJ "saltando" todo el
    -- turno ajeno y, como worldport tambien fija la orientacion, no dejaba ni girar el
    -- personaje. Girar no cambia la posicion, asi que con la guardia queda libre. Se compara
    -- contra C_Epsilon.GetPosition, la MISMA fuente con la que se capturo el ancla (UnitPosition
    -- vive en otro sistema de coordenadas). Umbral ~1,8 m: tolera el jitter del servidor y un
    -- salto en el sitio, y sigue parando cualquier paso real.
    local function LejosDelAncla(ancla)
        if not (C_Epsilon and C_Epsilon.GetPosition) then return true end
        local ok, x, y, z = pcall(C_Epsilon.GetPosition)
        x, y = tonumber(x), tonumber(y)
        if not ok or not x or not y then return true end
        local dx = x - (tonumber(ancla.x) or 0)
        local dy = y - (tonumber(ancla.y) or 0)
        local dz = (tonumber(z) or 0) - (tonumber(ancla.z) or 0)
        return (dx * dx + dy * dy + dz * dz) > 4  -- 2 yardas (~1,8 m) al cuadrado
    end
    local function Anclar()
        local ancla = API.RecordedMovementAnchor
        if not ancla then return end
        local ahora = (GetTime and GetTime()) or 0
        if ahora - ultimoTiron < 0.6 then return end
        if not LejosDelAncla(ancla) then return end
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

    -- Fija (o retira, con nil/0) el tope de movimiento manual y refresca la barra al momento.
    function API.SetMovementMaxOverride(metros)
        metros = tonumber(metros)
        if metros and metros > 0 then
            API.MovementMaxOverride = metros
            HarfordChat.Print(string.format("|cff88ff88Movimiento máximo fijado en %.1f m.|r", metros))
        else
            API.MovementMaxOverride = nil
            HarfordChat.Print("Movimiento máximo restaurado al de tu ficha.")
        end
        AvisarMovimiento(totalMeters, MaximoDelTurno())
        if tracking then
            button:SetText("Parar " .. FormatMeters(totalMeters))
            label:SetText(FormatMeters(totalMeters))
        end
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

        -- FUERA DE TU TURNO el muro sigue en pie. Antes el motor se desinstalaba al pasar el turno
        -- --con el ancla ya puesta-- asi que no quedaba nadie para hacerla cumplir: podias cruzar
        -- la sala entera durante el turno de los enemigos. Se para de CONTAR, no de vigilar.
        if not tracking then
            -- Al DM no se le ata mientras dirige, ni a quien activo `/harford libre`: los dos
            -- vuelven de una vez al empezar su turno.
            if API.RecordedMovementAnchor and EnCombate() and not LlevandoNpc()
                and not DirigiendoLaEscena() and not API.ModoLibre then
                Anclar()
            end
            return
        end

        -- Una sesion es DEL NPC o DEL JUGADOR desde que arranca (`sesionNpc`), y no se mezclan:
        -- * sesion NPC sin pet -> se acabo la posesion: se corta, o el ritmo fijo seguiria
        --   descontando mientras el DM anda libre.
        -- * sesion de JUGADOR con pet -> acabas de poseer con el contador de tu PJ aun vivo:
        --   se corta y se reinicia COMO NPC (contador a cero, tope del stat block). Este era
        --   el sintoma de "me cuenta el del player": el gasto del NPC caia en tu barra.
        if sesionNpc and not LlevandoNpc() then
            StopTracking()
            return
        end
        if not sesionNpc and LlevandoNpc() then
            tracking = false
            motor:SetScript("OnUpdate", nil)
            if ReiniciarPorTurno then ReiniciarPorTurno() end
            return
        end

        local avance
        if LlevandoNpc() then
            -- Como ATLAS de verdad (combat_tracker OnUpdate): la velocidad es solo el DETECTOR
            -- de "se esta moviendo" (GetUnitSpeed > 0) y el gasto avanza a RITMO FIJO de 7 m/s
            -- (`elapsed * 7`), NO multiplicando la velocidad medida. Detector en `pet` y, si
            -- este da cero, en `player`: en algunos clientes Epsilon la orden de movimiento de
            -- la posesion se expone en el cuerpo del jugador aunque el NPC sea el pet.
            -- GetUnitSpeed devuelve actual/carrera/vuelo/nado. Los parentesis
            -- interiores limitan a UN retorno: el segundo argumento de tonumber
            -- seria la base numerica (8 en base 7 da nil en Lua 5.1).
            local v = GetUnitSpeed and tonumber((GetUnitSpeed("pet"))) or 0
            if v <= 0 then
                v = GetUnitSpeed and tonumber((GetUnitSpeed("player"))) or 0
            end
            if v <= 0 then return end
            avance = 7 * trozo
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
            -- TERRENO DIFICIL: cada metro cuesta DOS. Es gasto, no velocidad — se dobla lo
            -- contado — y con la velocidad a la mitad se acumulan (un cuarto util), como en 5e.
            if HarfordDnDConditions and HarfordDnDConditions.IsMovementDoubled
                and HarfordDnDConditions.IsMovementDoubled("player") then
                avance = avance * 2
            end
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
                -- NPC sin bloqueo: el tope es solo una referencia del contador.
                API.MovimientoSinMuro = true
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

    StopTracking = function()
        if not tracking then return end
        tracking = false
        motor:SetScript("OnUpdate", nil)
        button:SetText("Movimiento")
        label:SetText(totalMeters > 0 and FormatMeters(totalMeters) or "")
        API.RecordedMovementMeters = totalMeters
        AvisarMovimiento(totalMeters, MaximoDelTurno())
        -- Y se ANCLA aqui: es el sitio donde terminaste, al que querras volver si te empujan o te
        -- mueves durante el turno de otro.
        API.RecordedMovementAnchor = not sesionNpc and CapturarAncla() or nil
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
        -- El DM que se movio dirigiendo vuelve AHORA, de una vez, a donde dejo su personaje: se
        -- le deja roldar durante el turno de los demas, pero su PJ no gana terreno por ello. Al
        -- resto no le hace falta -- a ellos el muro ya les fue devolviendo sobre la marcha.
        if API.RecordedMovementAnchor and DirigiendoLaEscena() and EnCombate() then
            ultimoTiron = 0  -- el enfriamiento del muro no debe comerse este tiron
            Anclar()
            -- `Anclar` deja el contador AL MAXIMO, porque su uso normal es el muro: te devuelve
            -- porque ya lo gastaste todo. Aqui es lo contrario --te devuelve para que empieces tu
            -- turno donde debes-- asi que el turno arranca a cero, con todo su movimiento.
            totalMeters = 0
            lastX, lastY, lastZ = nil, nil, nil
        end
        -- El modo libre se APAGA al empezar TU turno — pero SIN devolverte (decision de mesa
        -- 2026-09-05: no hay TP automatico; volver es siempre /harfordcombat posicion, y la casa
        -- se conserva justo para eso). Durante los turnos ajenos sigue encendido.
        local veniaDeLibre = API.ModoLibre and true or false
        if API.ModoLibre then
            API.ModoLibre = nil
            if EnCombate() then
                HarfordChat.Print("Modo libre terminado: es tu turno y juegas desde donde estas. "
                    .. "/harfordcombat posicion te devuelve a tu posicion guardada.")
            end
        end
        -- Fuera de combate la casa ya no apunta a nada util: se recoge.
        if not EnCombate() then API.ModoLibreCasa = nil end
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
        -- La posicion de /harfordcombat posicion se fija en cada INICIO DE TURNO DE PJs, alli
        -- donde estes, y vale hasta que el siguiente la actualice — salvo que vengas de libre:
        -- entonces estas en el punto de roameo y la casa debe seguir apuntando a donde estabas.
        if not veniaDeLibre and EnCombate() and API.TurnStartAnchor then
            API.ModoLibreCasa = API.TurnStartAnchor
        end
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
        -- En modo libre el contador no arranca ni en tu turno: te mueves sin gasto hasta que lo
        -- pares (/harfordcombat stop). A mano sigue valiendo, como medidor.
        if not aMano and API.ModoLibre then return end
        if HarfordDnDConditions and HarfordDnDConditions.IsSpeedZero
            and HarfordDnDConditions.IsSpeedZero("player") then
            RefreshConditionState()
            return
        end

        -- El NPC poseido se cuenta integrando `GetUnitSpeed("pet")`: no necesita ni puede
        -- depender de la posicion del jugador. Pedirsela aqui hacia que el seguimiento no
        -- arrancase justo al poseer, aunque el turno y la velocidad del NPC fueran correctos.
        local x, y, z
        if not LlevandoNpc() then
            x, y, z = GetPosition()
            if not x then
                label:SetText("Sin posición")
                return
            end
        end
        totalMeters, elapsed = 0, 0
        API.RecordedMovementMeters = 0
        lastX, lastY, lastZ = x, y, z
        startX, startY, startZ = x, y, z
        API.RecordedMovementInfo = { meters = 0, startX = x, startY = y, startZ = z, endX = x, endY = y, endZ = z }
        tracking = true
        sesionNpc = LlevandoNpc() and true or false
        button:SetText("Parar  0.0m")
        label:SetText(FormatMeters(0))
        motor:SetScript("OnUpdate", OnUpdate)
    end

    -- Arrancar el motor CONSERVANDO lo restaurado. `ArrancarSeguimiento` pone el contador a cero
    -- --es su trabajo: empieza un turno--, asi que la reanudacion del /reload restauraba los
    -- metros y acto seguido los borraba: imprimia "retomado 8,3 m" y el contador arrancaba en
    -- cero, o sea, recargar a mitad de turno regalaba el movimiento entero otra vez.
    local function RetomarSeguimiento()
        if tracking then return true end
        if HarfordDnDConditions and HarfordDnDConditions.IsSpeedZero
            and HarfordDnDConditions.IsSpeedZero("player") then
            RefreshConditionState()
            return false
        end
        local x, y, z = GetPosition()
        if not x then return false end
        lastX, lastY, lastZ = x, y, z
        API.RecordedMovementMeters = totalMeters
        tracking = true
        sesionNpc = LlevandoNpc() and true or false
        button:SetText("Parar " .. FormatMeters(totalMeters))
        label:SetText(FormatMeters(totalMeters))
        motor:SetScript("OnUpdate", OnUpdate)
        return true
    end

    -- Al pasar el turno a OTRO te quedas donde estas: se ancla TU POSICION DE ESE MOMENTO y se
    -- garantiza que el motor este instalado para hacerla cumplir. Siempre, no solo si el contador
    -- estaba corriendo. El NPC poseido queda fuera, como en el resto del muro.
    --
    -- El DM dirigiendo (Admin + .ph dm, DENTRO de la lista como PJ) NO queda fuera del anclado
    -- (2026-09-05): antes salia ANTES de capturar nada, y eso rompia SU flujo por los dos lados
    -- — sin ancla, `ReiniciarPorTurno` no tenia a donde devolverle el PJ al empezar su turno; y
    -- con `tracking` aun encendido el contador le seguia contando el roaming, se agotaba y el
    -- muro (que en la rama de agotamiento no distingue DM) le tironeaba en pleno turno enemigo.
    -- Ahora se le captura el ancla (el sitio donde DEJA a su PJ) y se le para el contador igual
    -- que a todos; de la vigilancia ya le libra el guard `DirigiendoLaEscena` del OnUpdate, asi
    -- que rueda libre y al empezar su turno el TP de `ReiniciarPorTurno` le devuelve alli.
    AnclarPorTurnoAjeno = function()
        if not EnCombate() then return end
        if EsMiTurno() then return end
        if LlevandoNpc() then return end
        -- Modo libre: el ancla "casa" se capturo al activarlo y NO se pisa con la posicion de
        -- roameo en la que te pille el cambio de turno; el motor ya esta instalado.
        if API.ModoLibre then return end
        tracking = false
        button:SetText("Movimiento")
        -- Ancla FRESCA en el sitio donde te pilla el cambio de turno: es la posicion a la que el
        -- muro te devuelve si andas. La del agotamiento, si existia, apunta al mismo sitio -- el
        -- muro ya te tenia ahi.
        local ancla = CapturarAncla()
        if ancla then API.RecordedMovementAnchor = ancla end
        motor:SetScript("OnUpdate", OnUpdate)
    end

    -- `/harfordcombat libre`: guarda tu CASA y te deja moverte sin gasto ni muro durante los
    -- turnos AJENOS. Al empezar TU turno se apaga solo — SIN devolverte: juegas desde donde
    -- estas, y volver es siempre `/harfordcombat posicion` (la casa se conserva justo para eso).
    -- Repetir `libre` tambien lo para. La casa vive APARTE del ancla del muro
    -- (`API.ModoLibreCasa`): asi los reinicios de turno no la pisan; se recoge al terminar el
    -- combate.
    function API.ModoLibreOn()
        if API.ModoLibre then
            HarfordChat.Print("El modo libre ya estaba activo (repite /harfordcombat libre para pararlo).")
            return
        end
        if not EnCombate() then
            HarfordChat.Print("Modo libre: solo aplica dentro de un combate por turnos (fuera no hay muro).")
            return
        end
        -- La casa: el ancla que hubiera (donde te dejo el muro o el cambio de turno) o donde
        -- estas ahora. El ancla del muro se retira — en libre no vigila y dejarla armada seria
        -- un tiron pendiente esperando a que pares.
        API.ModoLibreCasa = API.ModoLibreCasa or API.RecordedMovementAnchor or CapturarAncla()
        API.RecordedMovementAnchor = nil
        tracking = false
        button:SetText("Movimiento")
        API.ModoLibre = true
        HarfordChat.Print("|cff88ff88Modo libre:|r te mueves sin gasto ni muro hasta que empiece "
            .. "tu turno (se apaga solo, SIN devolverte). /harfordcombat posicion vuelve a tu "
            .. "posicion guardada; repetir /harfordcombat libre tambien lo para.")
    end

    function API.ModoLibreStop()
        if not API.ModoLibre then
            HarfordChat.Print("El modo libre no estaba activo.")
            return
        end
        API.ModoLibre = nil
        if EnCombate() and not LlevandoNpc() then
            if EsMiTurno() then
                -- En tu turno el contador vuelve a correr desde aqui (lo roameado no se cobra).
                if ArrancarSeguimiento then ArrancarSeguimiento(false) end
            else
                -- Turno ajeno: el muro vuelve a valer desde donde estas.
                local ancla = CapturarAncla()
                if ancla then API.RecordedMovementAnchor = ancla end
                motor:SetScript("OnUpdate", OnUpdate)
            end
        end
        HarfordChat.Print("Modo libre parado: te quedas donde estas."
            .. (API.ModoLibreCasa and " /harfordcombat posicion sigue valiendo para volver." or ""))
    end

    function API.ModoLibreVolver()
        local casa = API.ModoLibreCasa
        if not casa then
            HarfordChat.Print("No hay posicion de principio de turno guardada todavia.")
            return
        end
        if not (HarfordServerActions and HarfordServerActions.WorldportSelf) then return end
        local ok, err = HarfordServerActions.WorldportSelf(casa, { addonName = "Harford" })
        if ok then
            -- Vuelves a donde estabas al PRINCIPIO de tu turno Y con el movimiento REINICIADO:
            -- es deshacer el desplazamiento, no un paso mas. La posicion sigue valiendo hasta
            -- que el siguiente inicio de turno de PJs la actualice.
            totalMeters, elapsed = 0, 0
            API.RecordedMovementMeters = 0
            API.MovimientoSinMuro = nil
            lastX, lastY, lastZ = nil, nil, nil
            if EnCombate() and not EsMiTurno() and not API.ModoLibre then
                -- Turno ajeno sin libre: el muro te sostiene EN CASA el resto del asalto (su
                -- ancla vieja apuntaba al sitio del que acabas de volver).
                API.RecordedMovementAnchor = casa
                motor:SetScript("OnUpdate", OnUpdate)
            else
                API.RecordedMovementAnchor = nil
                if tracking then
                    button:SetText("Parar " .. FormatMeters(0))
                    label:SetText(FormatMeters(0))
                elseif EnCombate() and EsMiTurno() and not LlevandoNpc() and not API.ModoLibre then
                    if ArrancarSeguimiento then ArrancarSeguimiento(false) end
                end
            end
            AvisarMovimiento(0, MaximoDelTurno())
            HarfordChat.Print("De vuelta al principio de tu turno, con el movimiento reiniciado.")
        else
            HarfordChat.Print("|cffff5555No se pudo volver:|r " .. tostring(err or "error desconocido"))
        end
    end

    -- Compat: `/harford libre` alterna entre encender y parar.
    function API.ToggleModoLibre()
        if API.ModoLibre then API.ModoLibreStop() else API.ModoLibreOn() end
    end

    -- El turno YA ESTABA EMPEZADO cuando llegaste: te acabas de unir, o vuelves de una
    -- desconexion. El aviso de "es tu turno" paso antes de que estuvieras, asi que nadie arranco
    -- tu contador ni tu economia -- te movias gratis ese turno. Se reconcilia al llegar la FOTO:
    --   * con sello valido (mismo guid, mismo asalto: un /reload limpio) se RETOMA lo gastado;
    --   * sin sello (recien unido, o crash sin guardar) se empieza el turno de cero, entero.
    -- Idempotente: con el seguimiento ya corriendo no toca nada, y restaurar la economia desde el
    -- store es un no-op cuando el store ya refleja lo vivo, que es siempre salvo justo tras volver.
    function API.ReconciliarTurnoEnCurso()
        if LlevandoNpc() then
            -- La posesion ocurre DESPUES de que ya entro el turno del NPC. Por eso el listener
            -- de cambio de turno no puede arrancar el contador: hay que hacerlo al recibir el
            -- control, pero solo si ese NPC es miembro del bloque activo.
            if not EnCombate() or not EsMiTurno() or tracking then return end
            if ReiniciarPorTurno then ReiniciarPorTurno() end
            return
        end
        if not EnCombate() or not EsMiTurno() then return end
        local T = HarfordDnDConditions and HarfordDnDConditions.Turn
        if T and not (T.RestoreFromStore and T.RestoreFromStore()) and T.Reset then
            T.Reset()
        end
        if tracking then return end
        if Restaurar() then
            RetomarSeguimiento()
            AvisarMovimiento(totalMeters, MaximoDelTurno())
        else
            ArrancarSeguimiento()
        end
    end

    -- Atlas no espera a un evento ambiguo: su boton de posesion avisa al contador ANTES de mandar
    -- `.possess`. Aqui se conserva la misma garantia, pero se espera al GUID solicitado para no
    -- arrancar sobre el NPC anterior mientras Epsilon procesa `.unposs` + `.poss`.
    function API.NotifyNpcPossessionRequested(expectedGuid)
        expectedGuid = tostring(expectedGuid or "")
        local tries = 0
        local function Confirmar()
            tries = tries + 1
            local petGuid = UnitGUID and UnitGUID("pet")
            if petGuid and (expectedGuid == "" or petGuid == expectedGuid) then
                if API.ReconciliarTurnoEnCurso then API.ReconciliarTurnoEnCurso() end
                return
            end
            -- La cadena de Epsilon suelta primero al anterior y crea el nuevo pet despues. Dos
            -- segundos cubren ese relevo sin dejar un ticker permanente cuando el comando falla.
            if tries < 20 and C_Timer and C_Timer.After then C_Timer.After(0.1, Confirmar) end
        end
        Confirmar()
    end

    function API.GetNpcMovementDebugState()
        local petGuid = UnitGUID and UnitGUID("pet")
        local speed = GetUnitSpeed and tonumber((GetUnitSpeed("pet"))) or 0
        return {
            pet = LlevandoNpc(),
            petGuid = petGuid,
            speedYards = speed or 0,
            tracking = tracking,
            npcTurn = LlevandoNpc() and EsMiTurno() or false,
            spentMeters = totalMeters,
            maxMeters = MaximoDelTurno(),
        }
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
            -- RETOMAR, no arrancar: arrancar pone el contador a cero y borraba lo restaurado.
            if not RetomarSeguimiento() then return end
            AvisarMovimiento(totalMeters, MaximoDelTurno())
            HarfordChat.Print(string.format(
                "Retomado tu movimiento del turno: |cffffcc00%.1f m|r gastados.", totalMeters))
        end)
    end

    -- `.possess` no cambia el turno: el DM suele poseer al NPC cuando su bloque YA esta activo.
    -- UNIT_PET es la senal estable de que `pet` ya representa la criatura; PLAYER_CONTROL_GAINED
    -- cubre clientes que no emiten la primera en una posesion de Epsilon. Se difiere un frame para
    -- que UnitGUID("pet") y la velocidad esten listos antes de reconciliar.
    do
        local ev = CreateFrame("Frame")
        ev:RegisterEvent("UNIT_PET")
        ev:RegisterEvent("PLAYER_CONTROL_GAINED")
        ev:SetScript("OnEvent", function(_, event, unit)
            if event == "UNIT_PET" and unit ~= "player" then return end
            local function ReconciliarPosesion()
                if API.ReconciliarTurnoEnCurso then API.ReconciliarTurnoEnCurso() end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.1, ReconciliarPosesion)
            else
                ReconciliarPosesion()
            end
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
                -- Al pasar el turno a otro se para de CONTAR donde estabas, pero el motor sigue
                -- puesto: es el que hace cumplir el ancla. Desinstalarlo aqui era lo que dejaba
                -- moverse gratis durante el turno del enemigo -- el ancla estaba, pero nadie la
                -- miraba. Fuera de combate si se desinstala, mas abajo.
                tracking = false
                button:SetText("Movimiento")
                if not API.RecordedMovementAnchor then
                    API.RecordedMovementAnchor = CapturarAncla()
                end
                -- Y si lo que se acabo es el COMBATE, entonces si se desinstala: sin combate no
                -- hay muro que hacer cumplir, y el ancla apunta a un sitio de una pelea que ya no
                -- existe. Dejarlo corriendo seria un OnUpdate permanente para nada.
                if not EnCombate() then motor:SetScript("OnUpdate", nil) end
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
