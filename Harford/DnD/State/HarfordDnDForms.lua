-- HarfordDnDForms: lectura y estado de las formas druídicas declaradas en TRP3.
-- Una forma sustituye CA y ataques, pero nunca escribe sobre el equipo ni los PG base.

HarfordDnDForms = HarfordDnDForms or {}

local API = HarfordDnDForms
local cache = { source = nil, forms = {} }
local DAMAGE_LABEL = "Da" .. string.char(195, 177) .. "o"
local FORM_AURA_IDS = { 24858, 5487, 768, 33891 }

local function AuraIdForForm(form)
    local id = tostring(form and form.id or "")
    if id:find("lechuc", 1, true) then return 24858 end
    if id:find("oso", 1, true) then return 5487 end
    if id:find("gato", 1, true) then return 768 end
    if id:find("antarbol", 1, true) then return 33891 end
    return nil
end

local function SendFormAuraSequence(auraId, previousAuraId)
    -- SendChain espera la respuesta de cada comando. Eso convertia cambiar de
    -- forma en una cola de cinco viajes al servidor. Entre formas conocidas
    -- solo hay que retirar la anterior y aplicar la nueva, por el wrapper
    -- rapido (ARC.CMD cuando esta disponible).
    if not HarfordServerActions then return false end
    if previousAuraId and auraId and previousAuraId ~= auraId then
        HarfordServerActions.RemoveAuraSelf(previousAuraId)
        HarfordServerActions.ApplyAura(auraId)
        return true
    end

    -- Forma normal, o estado previo desconocido: limpieza completa para que
    -- ninguna aura de forma quede persistente tras reload/cambio manual.
    for _, id in ipairs(FORM_AURA_IDS) do HarfordServerActions.RemoveAuraSelf(id) end
    if auraId then HarfordServerActions.ApplyAura(auraId) end
    return true
end

local function Clean(value)
    value = tostring(value or "")
    value = value:gsub("{icon:[^}]+}", "")
    value = value:gsub("{col:[^}]+}", ""):gsub("{/col}", "")
    value = value:gsub("{[^}]+}", "")
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

-- Las fichas TRP3 declaran el icono junto al encabezado de cada forma. Se
-- extrae antes de limpiar el markup para que el selector represente la ficha
-- real, no una aproximacion por nombre (oso/gato/etc.).
local function IconFromTRP3(value)
    local icon = tostring(value or ""):match("{icon:([^}:]+)")
    if not icon or icon == "" then return nil end
    if icon:find("^Interface\\", 1, false) then return icon end
    return "Interface\\Icons\\" .. icon
end

local function Key(value)
    value = HarfordClassColors.StripAccents(Clean(value)):lower()
    value = value:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    return value
end

local function RawAboutText()
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile) then return nil end
    local profile = HarfordTRP3.GetPlayerProfile("player")
    local character = profile and (profile.player or profile)
    local about = character and character.about
    if type(about) ~= "table" then return nil end

    local parts = {}
    local function add(section)
        local text = type(section) == "table" and section.TX or nil
        if text and text ~= "" then parts[#parts + 1] = tostring(text) end
    end
    add(about.T1)
    for _, section in ipairs(about.T2 or {}) do add(section) end
    for _, section in pairs(about.T3 or {}) do add(section) end
    return #parts > 0 and table.concat(parts, "\n") or nil
end

local function TagBlocks(text, tag)
    local blocks, pos = {}, 1
    while true do
        local openStart, openEnd = text:find("{" .. tag .. "[^}]*}", pos)
        if not openStart then break end
        local closeStart, closeEnd = text:find("{/" .. tag .. "}", openEnd + 1, true)
        if not closeStart then break end
        local nextStart = text:find("{" .. tag .. "[^}]*}", closeEnd + 1)
        blocks[#blocks + 1] = {
            title = text:sub(openEnd + 1, closeStart - 1),
            body = text:sub(closeEnd + 1, (nextStart and nextStart - 1) or #text),
        }
        pos = closeEnd + 1
    end
    return blocks
end

local function FindSection(raw)
    for _, block in ipairs(TagBlocks(raw or "", "h1")) do
        if Key(block.title) == "cambio_de_forma" then
            return block.body
        end
    end
    return nil
end

local function ParseAction(block)
    local body = HarfordClassColors.StripAccents(Clean(block.body)):lower()
    -- Un dado dentro de texto narrativo no convierte un rasgo en ataque. Las
    -- acciones reales de la ficha usan la cabecera "Ataque de arma ...".
    if not body:find("ataque de arma", 1, true) then return nil end
    -- La ficha puede declarar el bono de dano con signo (+4 / -2), o dejarlo
    -- ausente. Es un bono propio de la forma, nunca del arma equipada.
    local diceN, diceS, sign, fixed, damageType = body:match("(%d*)d(%d+)%s*([+-])%s*(%d+)%s+de%s+dano%s+([%a]+)")
    if not diceS then
        diceN, diceS, damageType = body:match("(%d*)d(%d+)%s+de%s+dano%s+([%a]+)")
    end
    diceN, diceS = tonumber(diceN == "" and "1" or diceN), tonumber(diceS)
    if not diceN or not diceS or not damageType then return nil end

    local fixedBonus = tonumber(fixed) or 0
    if sign == "-" then fixedBonus = -fixedBonus end

    -- Un "+X al ataque" en un stat block ya es el total de ataque de la
    -- forma; no debe volver a sumar caracteristica ni competencia del PJ.
    local attackSign, attackValue = body:match("([+-])%s*(%d+)%s+al%s+ataque")
    local attackBonusOverride
    if attackValue then
        attackBonusOverride = tonumber(attackValue) or 0
        if attackSign == "-" then attackBonusOverride = -attackBonusOverride end
    end

    local mode = body:find("a distancia", 1, true) and "Ranged" or "Melee"
    local rangeFeet = tonumber(body:match("(%d+)%s+pies"))
    local targetText = body:find("un objetivo", 1, true) and "un objetivo" or ""
    if HarfordDamageTypes and HarfordDamageTypes.FromWord then
        damageType = HarfordDamageTypes.FromWord(damageType) or damageType
    end
    local onHitExtra = body:match("sufre%s+(%d*d%d+)%s+de%s+da[ñn]o%s+adicional")
    local nextAttackExtra = body:match("proximo ataque.-causa%s+(%d*d%d+)%s+de%s+da[ñn]o%s+adicional")
    return {
        key = Clean(block.title),
        icon = IconFromTRP3(block.title),
        cat = "Forma",
        mode = mode,
        rangeFeet = rangeFeet,
        targetText = targetText,
        dmgN = diceN,
        dmgS = diceS,
        dmgType = damageType,
        -- El bloque de forma ya declara su daño final (p.ej. 1d8 + 4).
        addAbi = false,
        weaponDamageBonus = fixedBonus,
        attackBonusOverride = attackBonusOverride,
        ignoreGlobalWeaponBonuses = true,
        source = "form",
        props = { "Natural" },
    }
end

local function ParseSpecialAction(block)
    local body = HarfordClassColors.StripAccents(Clean(block.body)):lower()
    local feet = tonumber(body:match("mueves al menos%s+(%d+)%s+pies"))
    local ability, dc = body:match("salvacion%s+de%s+([%a]+)%s+cd%s*(%d+)")
    if not ability then ability = body:match("salvacion%s+de%s+([%a]+)") end
    if not (feet and ability and body:find("derrib", 1, true)) then return nil end
    ability = ({ fuerza = "Fuerza", destreza = "Destreza", constitucion = "Constitucion", inteligencia = "Inteligencia", sabiduria = "Sabiduria", carisma = "Carisma" })[HarfordClassColors.StripAccents(ability):lower()]
    if not ability then return nil end
    return {
        id = Key(block.title), name = Clean(block.title), icon = IconFromTRP3(block.title),
        description = Clean(block.body),
        minMovementFeet = feet, save = ability, dc = tonumber(dc),
        dynamicDexterityDc = not dc and body:find("cd%s*8%s*%+%s*modificador de%s+destreza", 1) ~= nil,
        requiredActionName = Clean(body:match("ataque de%s+([%a]+)") or body:match("golpeas? con%s+([%a]+)") or ""),
        conditionId = "prone",
        onHitExtraDamageDice = onHitExtra,
        nextAttackExtraDamageDice = nextAttackExtra,
    }
end

local function ResolveSpecialAction(form, special)
    local wanted = Key(special.requiredActionName)
    if wanted == "" then return end
    for _, action in ipairs(form.actions or {}) do
        if Key(action.key) == wanted then special.requiredActionKey = action.key; return end
    end
end

local function ParseForms(raw)
    local section = raw and FindSection(raw)
    if not section then return {} end
    local forms, byId, actionBlocks, lastForm = {}, {}, {}, nil
    local headers = TagBlocks(section, "h2")
    for _, block in ipairs(headers) do
        local title = Clean(block.title)
        local cleanBody = HarfordClassColors.StripAccents(Clean(block.body))
        local armorClass = tonumber(cleanBody:match("CA%s*(%d+)"))
        if armorClass and armorClass > 0 and not Key(title):find("acciones", 1, true) then
            local form = {
                id = Key(title),
                name = title,
                icon = IconFromTRP3(block.title),
                armorClass = armorClass,
                size = cleanBody:match("Tamano%s+([%a]+)"),
                actions = {},
                specialActions = {},
                traits = {},
            }
            form.speed = tonumber(cleanBody:match("Velocidad%s*(%d+)"))
            -- Algunos perfiles dejan las acciones dentro del mismo bloque de
            -- la forma; se conservan como variante compatible.
            for _, actionBlock in ipairs(TagBlocks(block.body, "h3")) do
                local action = ParseAction(actionBlock)
                if action then
                    form.actions[#form.actions + 1] = action
                else
                    local special = ParseSpecialAction(actionBlock)
                    if special then
                        form.specialActions[#form.specialActions + 1] = special
                    else
                        form.traits[#form.traits + 1] = { name = Clean(actionBlock.title), description = Clean(actionBlock.body) }
                    end
                end
            end
            if form.id ~= "" then
                forms[#forms + 1] = form
                byId[form.id] = form
                lastForm = form
            end
        else
            -- Baird y las fichas con la misma plantilla separan la ficha de
            -- cada forma y sus golpes: "Oso" -> "Acciones Oso".
            local actionFor = Key(title):match("^acciones_(.+)$")
            if actionFor and actionFor ~= "" then
                actionBlocks[actionFor] = block.body
            else
                local special = ParseSpecialAction(block)
                if special and lastForm then lastForm.specialActions[#lastForm.specialActions + 1] = special end
            end
        end
    end
    for formId, body in pairs(actionBlocks) do
        local form = byId[formId]
        if form then
            for _, actionBlock in ipairs(TagBlocks(body, "h3")) do
                local action = ParseAction(actionBlock)
                if action then form.actions[#form.actions + 1] = action end
            end
        end
    end
    for _, form in ipairs(forms) do
        for _, special in ipairs(form.specialActions or {}) do ResolveSpecialAction(form, special) end
    end
    return forms
end

local function GetForms()
    local raw = RawAboutText() or ""
    if raw ~= cache.source then
        cache.source = raw
        cache.forms = ParseForms(raw)
    end
    return cache.forms
end

local function IsDruid()
    if not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return false end
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels() or {}) do
        if tostring(entry.classId or "") == "druida" then return true end
    end
    return false
end

function API.GetKnownForms()
    if not IsDruid() then return {} end
    return GetForms()
end

function API.GetActiveForm()
    if not (HarfordDnDProgression and HarfordDnDProgression.GetActiveForm) then return nil end
    local id = HarfordDnDProgression.GetActiveForm()
    if id == "" then return nil end
    for _, form in ipairs(API.GetKnownForms()) do
        if form.id == id then return form end
    end
    return nil
end

function API.IsActive()
    return API.GetActiveForm() ~= nil
end

function API.Select(formId, actionKey)
    if not (HarfordDnDProgression and HarfordDnDProgression.SetActiveForm) then return false end
    for _, form in ipairs(API.GetKnownForms()) do
        if form.id == formId then
            local oldForm = API.GetActiveForm()
            HarfordDnDProgression.SetActiveForm(form.id)
            if HarfordDnDProgression.SetActiveFormAction then
                HarfordDnDProgression.SetActiveFormAction(actionKey or (form.actions[1] and form.actions[1].key) or "")
            end
            HarfordDnDProgression.SetToggleState("wild_shape", true)
            if not oldForm or oldForm.id ~= form.id then
                SendFormAuraSequence(AuraIdForForm(form), AuraIdForForm(oldForm))
            end
            return true, form
        end
    end
    return false
end

function API.Revert()
    if not HarfordDnDProgression then return false end
    if HarfordDnDProgression.SetActiveForm then HarfordDnDProgression.SetActiveForm(nil) end
    if HarfordDnDProgression.SetToggleState then HarfordDnDProgression.SetToggleState("wild_shape", false) end
    SendFormAuraSequence(nil)
    return true
end

function API.GetArmorClass()
    local form = API.GetActiveForm()
    return form and form.armorClass or nil
end

function API.GetWeapon()
    local form = API.GetActiveForm()
    if not (form and form.actions) then return nil end
    local chosen = HarfordDnDProgression and HarfordDnDProgression.GetActiveFormAction
        and HarfordDnDProgression.GetActiveFormAction() or ""
    for _, action in ipairs(form.actions) do
        if action.key == chosen then return action end
    end
    return form.actions[1]
end

function API.GetActiveActions()
    local form = API.GetActiveForm()
    return (form and form.actions) or {}
end

function API.GetActiveSpecialActions()
    local form = API.GetActiveForm()
    return (form and form.specialActions) or {}
end

function API.RevertIfDefeated(currentHealth)
    if API.IsActive() and (tonumber(currentHealth) or 0) <= 0 then
        API.Revert()
        return true
    end
    return false
end

local function FormIcon(form)
    if form and form.icon and form.icon ~= "" then return form.icon end
    local id = tostring(form and form.id or "")
    if id:find("gato", 1, true) then return "Interface\\Icons\\Ability_Druid_CatForm" end
    if id:find("oso", 1, true) then return "Interface\\Icons\\Ability_Druid_Bash" end
    if id:find("lechuc", 1, true) then return "Interface\\Icons\\Spell_Nature_StarFall" end
    if id:find("arbol", 1, true) then return "Interface\\Icons\\Spell_Nature_ForceOfNature" end
    return "Interface\\Icons\\Ability_Druid_Maul"
end

local function FormDetails(form)
    local parts = {}
    local summary = {}
    if form.size and form.size ~= "" then summary[#summary + 1] = "Tamano " .. form.size end
    summary[#summary + 1] = "CA " .. tostring(form.armorClass or "-")
    if tonumber(form.speed) then summary[#summary + 1] = "Velocidad " .. tostring(form.speed) .. " pies" end
    parts[#parts + 1] = table.concat(summary, " | ")
    for _, trait in ipairs(form.traits or {}) do
        parts[#parts + 1] = trait.name
        if trait.description and trait.description ~= "" then parts[#parts + 1] = trait.description end
    end
    for _, special in ipairs(form.specialActions or {}) do
        parts[#parts + 1] = special.name
        if special.description and special.description ~= "" then parts[#parts + 1] = special.description end
    end
    local actions = {}
    for _, action in ipairs(form.actions or {}) do actions[#actions + 1] = tostring(action.key) end
    if #actions > 0 then parts[#parts + 1] = "Acciones: " .. table.concat(actions, ", ") end
    return parts
end

local function ActionIcon(action, form)
    if action and action.icon and action.icon ~= "" then return action.icon end
    return FormIcon(form)
end

local function ActionDetails(action)
    local range = action.mode == "Ranged" and "Ataque a distancia" or "Ataque cuerpo a cuerpo"
    if action.rangeFeet then range = range .. " | " .. tostring(action.rangeFeet) .. " pies" end
    if action.targetText and action.targetText ~= "" then range = range .. " | " .. action.targetText end
    local damageType = tostring(action.dmgType or "")
    if HarfordDamageTypes and HarfordDamageTypes.FromWord then
        damageType = HarfordDamageTypes.FromWord(damageType) or damageType
    end
    if HarfordDamageTypes and HarfordDamageTypes.GetLabel then
        damageType = HarfordDamageTypes.GetLabel(damageType)
    end
    local damage = string.format("%dd%d", tonumber(action.dmgN) or 1, tonumber(action.dmgS) or 4)
    local bonus = tonumber(action.weaponDamageBonus) or 0
    if bonus > 0 then damage = damage .. " + " .. bonus
    elseif bonus < 0 then damage = damage .. " - " .. math.abs(bonus) end
    if damageType ~= "" then damage = damage .. " " .. damageType end

    local attack = action.attackBonusOverride ~= nil
        and ("Ataque: " .. (action.attackBonusOverride >= 0 and "+" or "") .. tostring(action.attackBonusOverride))
        or "Ataque: caracteristica + competencia"
    return { range, attack, DAMAGE_LABEL .. ": " .. damage }
end

local function SpecialDetails(special)
    -- El tooltip debe reflejar la regla declarada por la ficha, no una frase
    -- sintetica que pueda confundir el orden de dano/salvacion de la accion.
    return { tostring(special.description or "") }
end

function API.GetWeaponTooltip()
    local action = API.GetWeapon()
    if not action then return nil end
    return action.key, ActionDetails(action)
end

-- Replica literal del SpellFlyout de Shadowlands 9.2.7. El original es un
-- frame protegido y solo admite hechizos Blizzard, asi que se reproduce su
-- composicion visual (assets, botones de 28 px y espaciados 7/4/4) sin usar
-- sus scripts seguros.
local FLYOUT_BUTTON_SIZE = 28
local FLYOUT_INITIAL_SPACING = 7
local FLYOUT_SPACING = 4
local FLYOUT_FINAL_SPACING = 4

local function SetEndRotation(texture)
    if SetClampedTextureRotation then
        SetClampedTextureRotation(texture, 90)
    elseif texture.SetRotation then
        texture:SetRotation(math.pi / 2)
    end
end

local function SetAnchorFlyoutState(anchor, shown)
    local owner = anchor and (anchor._flyoutOwner or anchor)
    if not owner then return end
    if owner.formFlyoutBorder then owner.formFlyoutBorder:SetShown(shown) end
    if owner.formFlyoutShadow then owner.formFlyoutShadow:SetShown(shown) end
end

local function CreateFlyout(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame.endCap = frame:CreateTexture(nil, "BACKGROUND")
    frame.endCap:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
    frame.endCap:SetSize(37, 22)
    frame.endCap:SetTexCoord(0.015625, 0.59375, 0.7421875, 0.9140625)
    frame.endCap:SetVertexColor(0.7, 0.7, 0.7)

    frame.background = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    frame.background:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton-FlyoutMidLeft")
    frame.background:SetSize(32, 37)
    frame.background:SetTexCoord(0, 1, 0, 0.578125)
    frame.background:SetHorizTile(true)
    frame.background:SetVertexColor(0.7, 0.7, 0.7)
    frame.buttons = {}
    frame:SetScript("OnHide", function(self)
        SetAnchorFlyoutState(self._anchor, false)
        self._anchor = nil
    end)
    frame:Hide()
    return frame
end

local function AcquireFlyoutButton(frame, index)
    local button = frame.buttons[index]
    if button then return button end
    button = CreateFrame("CheckButton", nil, frame)
    button:SetSize(FLYOUT_BUTTON_SIZE, FLYOUT_BUTTON_SIZE)
    button:SetFrameLevel((frame:GetFrameLevel() or 1) + 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(4 / 64, 60 / 64, 4 / 64, 60 / 64)
    -- ActionButtonTemplate: el marco normal NO ocupa 28 px. Sobresale 15 px
    -- por lado; ese detalle es el que crea los cuadros redondeados nativos.
    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    local normal = button:GetNormalTexture()
    normal:ClearAllPoints()
    normal:SetPoint("TOPLEFT", button, "TOPLEFT", -15, 15)
    normal:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 15, -15)
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAllPoints(button) end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetAllPoints(button) end
    button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
    button.active = button:GetCheckedTexture()
    if button.active then button.active:SetAllPoints(button) end
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self._name or "Forma", 1, 0.82, 0, true)
        local function AddDetailLine(line)
            line = tostring(line or "")
            for paragraph in line:gmatch("[^\r\n]+") do GameTooltip:AddLine(paragraph, 0.9, 0.9, 0.9, true) end
        end
        if type(self._detail) == "table" then
            for _, line in ipairs(self._detail) do AddDetailLine(line) end
        elseif self._detail then AddDetailLine(self._detail) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    frame.buttons[index] = button
    return button
end

local function ShowFlyout(menu, anchor, entries, activeKey, onChosen)
    if menu:IsShown() and menu._anchor == anchor then
        menu:Hide()
        return true
    end
    if menu:IsShown() then menu:Hide() end
    menu._anchor = anchor
    local owner = anchor._flyoutOwner or anchor
    -- SpellFlyout se reapadrina al boton que lo abre. Asi conserva el orden
    -- visual del boton y no flota en una capa ajena al Libro.
    if menu:GetParent() ~= owner then menu:SetParent(owner) end
    menu:ClearAllPoints()
    menu:SetPoint("LEFT", owner, "RIGHT", 0, 0)
    menu:SetFrameStrata(owner:GetFrameStrata() or "DIALOG")
    menu:SetFrameLevel((owner:GetFrameLevel() or 1) + 10)
    menu.endCap:ClearAllPoints()
    menu.endCap:SetPoint("RIGHT", menu, "RIGHT", 0, 0)
    SetEndRotation(menu.endCap)
    menu.background:ClearAllPoints()
    menu.background:SetPoint("RIGHT", menu.endCap, "LEFT", 0, 0)
    menu.background:SetPoint("LEFT", menu, "LEFT", 0, 0)
    menu.background:Show()

    local previous
    for i, entry in ipairs(entries) do
        local button = AcquireFlyoutButton(menu, i)
        button:SetFrameLevel((menu:GetFrameLevel() or 1) + 1)
        button:ClearAllPoints()
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", FLYOUT_SPACING, 0)
        else
            button:SetPoint("LEFT", menu, "LEFT", FLYOUT_INITIAL_SPACING, 0)
        end
        button.icon:SetTexture(entry.icon)
        button._name = entry.name
        button._detail = entry.detail
        button:SetChecked(entry.key == activeKey)
        button:SetScript("OnClick", function()
            onChosen(entry)
            menu:Hide()
        end)
        button:Show()
        previous = button
    end
    for i = #entries + 1, #menu.buttons do menu.buttons[i]:Hide() end
    menu:SetSize((FLYOUT_BUTTON_SIZE + FLYOUT_SPACING) * #entries - FLYOUT_SPACING + FLYOUT_INITIAL_SPACING + FLYOUT_FINAL_SPACING, FLYOUT_BUTTON_SIZE)
    SetAnchorFlyoutState(anchor, true)
    menu:Show()
    return true
end

-- Cambio de forma: cada icono es una forma. Sus ataques se eligen en el
-- segundo flyout, desde la seccion Ataque, igual que dos habilidades distintas.
function API.OpenMenu(anchor, onSelect)
    local forms = API.GetKnownForms()
    if #forms == 0 then return false, "No se encontraron formas validas en la ficha TRP3." end
    local menu = API._menu or CreateFlyout("HarfordDnDFormsMenu")
    API._menu = menu
    local active = API.GetActiveForm()
    local entries = {
        { key = "", name = "Forma normal", icon = "Interface\\Icons\\Ability_Druid_TravelForm", normal = true,
          detail = "Vuelve a tu forma normal y recupera tu equipo y ataques habituales." },
    }
    for _, form in ipairs(forms) do
        entries[#entries + 1] = { key = form.id, form = form, name = form.name, icon = FormIcon(form), detail = FormDetails(form) }
    end
    return ShowFlyout(menu, anchor, entries, active and active.id or "", function(choice)
        if choice.normal then API.Revert() else API.Select(choice.form.id) end
        if onSelect then onSelect(choice.form) end
    end)
end

function API.OpenActionMenu(anchor, onSelect)
    local form = API.GetActiveForm()
    local actions = form and form.actions or {}
    if not form then return false, "Selecciona primero una forma." end
    if #actions == 0 then return false, "La forma activa no declara ataques en la ficha TRP3." end
    local menu = API._actionMenu or CreateFlyout("HarfordDnDFormsActionMenu")
    API._actionMenu = menu
    local selected = HarfordDnDProgression and HarfordDnDProgression.GetActiveFormAction
        and HarfordDnDProgression.GetActiveFormAction() or ""
    local entries = {}
    for _, action in ipairs(actions) do
        entries[#entries + 1] = {
            key = action.key, action = action, name = action.key, icon = ActionIcon(action, form),
            detail = ActionDetails(action),
        }
    end
    for _, special in ipairs(API.GetActiveSpecialActions()) do
        entries[#entries + 1] = { key = "special:" .. special.id, special = special, name = special.name,
            icon = special.icon or FormIcon(form), detail = SpecialDetails(special) }
    end
    return ShowFlyout(menu, anchor, entries, selected, function(choice)
        if choice.special then
            if onSelect then onSelect(nil, form, choice.special) end
        else
            API.Select(form.id, choice.action.key)
            if onSelect then onSelect(choice.action, form) end
        end
    end)
end
