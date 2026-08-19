-- HarfordDnDConditionalDamage: costes, niveles y escalado de daños condicionales.

HarfordDnDConditionalDamage = HarfordDnDConditionalDamage or {}

local API = HarfordDnDConditionalDamage
local deps = {}

function API.Configure(options)
    deps = options or {}
end

function API.GetSelectedLevel(conditional)
    if not conditional then return 1 end
    local levels = HarfordDnDStore.condDamageLevel or {}
    return math.max(1, math.floor(tonumber(levels[conditional.id]) or tonumber(conditional.minLevel) or 1))
end

function API.GetMaxLevel(conditional)
    if not conditional then return 0 end
    local minLevel = math.max(1, math.floor(tonumber(conditional.minLevel) or 1))
    local maxLevel = tonumber(conditional.maxLevel) or (conditional.countPerLevel and 20 or 1)

    if conditional.maxSpellLevel and HarfordDnDMana and HarfordDnDMana.GetMaxSpellLevel then
        maxLevel = math.min(maxLevel, tonumber(HarfordDnDMana.GetMaxSpellLevel()) or 0)
    end
    if conditional.maxCount and conditional.extraCountOffset then
        maxLevel = math.min(maxLevel, math.max(0,
            (tonumber(conditional.maxCount) or 0) - (tonumber(conditional.extraCountOffset) or 0)))
    end
    if conditional.maxLevelAbility and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
        maxLevel = math.min(maxLevel,
            math.max(0, tonumber(HarfordDnDCalc.GetAbilityMod(conditional.maxLevelAbility)) or 0))
    end
    if conditional.resourceCost and deps.getResourceCurrent then
        local perLevel = math.max(1, tonumber(conditional.costPerLevel) or 1)
        maxLevel = math.min(maxLevel,
            math.floor((tonumber(deps.getResourceCurrent(conditional.resourceCost)) or 0) / perLevel))
    end

    maxLevel = math.floor(tonumber(maxLevel) or 0)
    return maxLevel < minLevel and 0 or maxLevel
end

function API.GetCosts(conditional, level)
    local costs = {}
    level = math.max(1, math.floor(tonumber(level) or API.GetSelectedLevel(conditional)))

    local manaEnabled = HarfordDnDMana and HarfordDnDMana.IsEnabled and HarfordDnDMana.IsEnabled()
    if conditional and conditional.spellLevelCost and manaEnabled then
        local spellLevel = conditional.spellLevelCost == "level" and level
            or math.floor(tonumber(conditional.spellLevelCost) or 0)
        local cost = spellLevel > 0 and HarfordDnDMana.GetSpellCost
            and HarfordDnDMana.GetSpellCost(spellLevel) or 0
        if cost and cost > 0 then
            costs[#costs + 1] = { resource = "mana", amount = cost, label = "maná" }
        end
    elseif conditional and conditional.spellLevelCost then
        local spellLevel = conditional.spellLevelCost == "level" and level
            or math.floor(tonumber(conditional.spellLevelCost) or 0)
        if spellLevel > 0 then
            costs[#costs + 1] = { resource = "spell_slot", amount = spellLevel,
                label = "espacio de nivel " .. tostring(spellLevel) }
        end
    end

    if conditional and conditional.resourceCost then
        local amount = level * math.max(1, tonumber(conditional.costPerLevel) or 1)
        if amount > 0 then
            local resourceDef = HarfordDnDResources and HarfordDnDResources.DEFS
                and HarfordDnDResources.DEFS[conditional.resourceCost]
            costs[#costs + 1] = {
                resource = conditional.resourceCost,
                amount = amount,
                label = resourceDef and resourceDef.label or tostring(conditional.resourceCost),
            }
        end
    end
    return costs
end

function API.GetCostText(conditional, level)
    local parts = {}
    for _, cost in ipairs(API.GetCosts(conditional, level)) do
        parts[#parts + 1] = tostring(cost.amount) .. " " .. tostring(cost.label)
    end
    return table.concat(parts, ", ")
end

function API.CanPay(conditional, level)
    local maxLevel = API.GetMaxLevel(conditional)
    if maxLevel <= 0 then return false, "" end
    level = math.max(1, math.floor(tonumber(level) or API.GetSelectedLevel(conditional)))
    if level > maxLevel then return false, "" end
    for _, cost in ipairs(API.GetCosts(conditional, level)) do
        if cost.resource == "spell_slot" then
            local ok = HarfordDnDMana and HarfordDnDMana.CanSpendSpellSlot
                and HarfordDnDMana.CanSpendSpellSlot(cost.amount)
            if not ok then return false, tostring(cost.label) end
        else
            local current = deps.getResourceCurrent and deps.getResourceCurrent(cost.resource) or 0
            if current < cost.amount then
                return false, tostring(cost.amount) .. " " .. tostring(cost.label)
            end
        end
    end
    return true, API.GetCostText(conditional, level)
end

function API.HasPayable(conditional)
    local maxLevel = API.GetMaxLevel(conditional)
    local minLevel = math.max(1, math.floor(tonumber(conditional and conditional.minLevel) or 1))
    for level = minLevel, maxLevel do
        if API.CanPay(conditional, level) then return true end
    end
    return false
end

function API.Spend(conditional, level)
    local valid, costText = API.CanPay(conditional, level)
    if not valid then return false, costText end
    for _, cost in ipairs(API.GetCosts(conditional, level)) do
        if cost.resource == "spell_slot" and HarfordDnDMana and HarfordDnDMana.SpendSpellSlot then
            local ok, err = HarfordDnDMana.SpendSpellSlot(cost.amount)
            if not ok then return false, err end
        elseif deps.adjustResourceCurrent then
            deps.adjustResourceCurrent(cost.resource, -cost.amount)
        end
    end
    return true, costText
end

function API.GetLeveled(conditional, level)
    level = math.max(1, math.floor(tonumber(level) or API.GetSelectedLevel(conditional)))
    local resolved = {}
    for key, value in pairs(conditional or {}) do resolved[key] = value end
    if conditional and conditional.countPerLevel then
        local count = level * (tonumber(conditional.countPerLevel) or 1)
            + (tonumber(conditional.extraCountOffset) or 0)
        if conditional.maxCount then
            count = math.min(count, tonumber(conditional.maxCount) or count)
        end
        resolved.dice = math.max(0, count)
    end
    return resolved, level
end

local function Signed(value)
    value = tonumber(value) or 0
    return value >= 0 and ("+" .. value) or tostring(value)
end

function API.GetList()
    local context = HarfordDnDContext and HarfordDnDContext.State
    if context and context.active then return {} end
    if not (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetConditionalDamage) then return {} end
    return HarfordDnDFeatureEffects.GetConditionalDamage() or {}
end

-- Algunos daños se aplican por un estado propio de la habilidad (p. ej. Marca
-- del Cazador sobre su presa). Siguen en la lista completa para la tirada, pero
-- no pertenecen al selector manual de "Daño extra".
function API.GetToggleList()
    local out = {}
    for _, conditional in ipairs(API.GetList()) do
        if not conditional.requiresMarkedTarget then
            out[#out + 1] = conditional
        end
    end
    return out
end

function API.GetById(conditionalId)
    conditionalId = tostring(conditionalId or "")
    if conditionalId == "" then return nil end
    for _, conditional in ipairs(API.GetList()) do
        if conditional.id == conditionalId then
            return conditional, API.GetMaxLevel(conditional)
        end
    end
    return nil
end

function API.GetOptionText(conditional, level)
    local leveled = API.GetLeveled(conditional, level)
    local dice = tonumber(leveled.dice) or 0
    local die = tonumber(leveled.die) or 0
    local suffix = ""
    if conditional.spellLevelCost == "level" then
        suffix = " nivel " .. tostring(level)
    elseif API.GetMaxLevel(conditional) > 1 then
        suffix = " x" .. tostring(level)
    end
    local flat = tonumber(leveled.flat) or 0
    if conditional.flatAbility and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
        flat = flat + (tonumber(HarfordDnDCalc.GetAbilityMod(conditional.flatAbility)) or 0)
    end
    local expression = dice > 0 and (dice .. "d" .. die) or ""
    if flat ~= 0 then expression = expression ~= "" and (expression .. Signed(flat)) or Signed(flat) end
    if expression == "" then expression = "-" end
    local text = tostring(conditional.label or "Daño extra") .. suffix .. " (" .. expression
    local costText = API.GetCostText(conditional, level)
    if costText ~= "" then text = text .. ", " .. costText end
    return text .. ")"
end

local function RefreshConsumers()
    if HarfordDnDAttackUI and HarfordDnDAttackUI.RefreshWeaponInfo then
        HarfordDnDAttackUI.RefreshWeaponInfo()
    end
    if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
        HarfordCharacterPanel.RefreshBookIfShown()
    end
end

function API.IsActive(conditionalId)
    return (HarfordDnDStore.activeCondDamage or {})[conditionalId] == true
end

function API.GetActiveLevel(conditionalId)
    return (HarfordDnDStore.condDamageLevel or {})[conditionalId]
end

function API.Toggle(conditionalId)
    local conditional = API.GetById(conditionalId)
    if not conditional then return end
    local store = HarfordDnDStore
    store.activeCondDamage = store.activeCondDamage or {}
    store.condDamageLevel = store.condDamageLevel or {}
    local maxLevel = API.GetMaxLevel(conditional)
    local minLevel = math.max(1, math.floor(tonumber(conditional.minLevel) or 1))
    if maxLevel <= 0 then
        store.activeCondDamage[conditionalId] = nil
        store.condDamageLevel[conditionalId] = nil
        HarfordChat.Print("|cffff5555" .. tostring(conditional.label or "Daño extra")
            .. ": sin recursos suficientes.|r")
    elseif not store.activeCondDamage[conditionalId] then
        store.activeCondDamage[conditionalId] = true
        store.condDamageLevel[conditionalId] = minLevel
    elseif maxLevel > minLevel then
        local current = API.GetSelectedLevel(conditional)
        if current < maxLevel then
            store.condDamageLevel[conditionalId] = current + 1
        else
            store.activeCondDamage[conditionalId] = nil
            store.condDamageLevel[conditionalId] = nil
        end
    else
        store.activeCondDamage[conditionalId] = nil
        store.condDamageLevel[conditionalId] = nil
    end
    RefreshConsumers()
end

function API.InstallUI(parent)
    local store = HarfordDnDStore
    store.activeCondDamage = store.activeCondDamage or {}
    store.condDamageLevel = store.condDamageLevel or {}

    local attackMenu = CreateFrame("Frame", "HarfordDnDCondDamageMenu", parent, "UIDropDownMenuTemplate")
    attackMenu:Hide()
    UIDropDownMenu_Initialize(attackMenu, function()
        for _, conditional in ipairs(API.GetToggleList()) do
            local maxLevel = API.GetMaxLevel(conditional)
            local minLevel = math.max(1, math.floor(tonumber(conditional.minLevel) or 1))
            if maxLevel <= 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.text = API.GetOptionText(conditional, minLevel)
                info.disabled = true
                UIDropDownMenu_AddButton(info)
            else
                for level = minLevel, maxLevel do
                    local option, optionLevel = conditional, level
                    local canPay = API.CanPay(option, optionLevel)
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = API.GetOptionText(option, optionLevel)
                    info.keepShownOnClick = true
                    info.isNotRadio = true
                    info.disabled = not canPay
                    info.checked = canPay and store.activeCondDamage[option.id] == true
                        and API.GetSelectedLevel(option) == optionLevel
                    info.func = function()
                        if not API.CanPay(option, optionLevel) then
                            store.activeCondDamage[option.id] = nil
                            store.condDamageLevel[option.id] = nil
                        elseif store.activeCondDamage[option.id]
                            and API.GetSelectedLevel(option) == optionLevel then
                            store.activeCondDamage[option.id] = nil
                            store.condDamageLevel[option.id] = nil
                        else
                            store.activeCondDamage[option.id] = true
                            store.condDamageLevel[option.id] = optionLevel
                        end
                        RefreshConsumers()
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end
        end
    end, "MENU")
    API.AttackMenu = attackMenu

    local bookMenu = CreateFrame("Frame", "HarfordBookCondDamageMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(bookMenu, function()
        local conditional = API.bookConditionalId and API.GetById(API.bookConditionalId)
        if not conditional then return end
        local maxLevel = API.GetMaxLevel(conditional)
        local minLevel = math.max(1, math.floor(tonumber(conditional.minLevel) or 1))
        local off = UIDropDownMenu_CreateInfo()
        off.text = "Ninguno"
        off.checked = not store.activeCondDamage[conditional.id]
        off.func = function()
            store.activeCondDamage[conditional.id] = nil
            store.condDamageLevel[conditional.id] = nil
            RefreshConsumers()
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(off)
        for level = minLevel, maxLevel do
            local optionLevel = level
            local info = UIDropDownMenu_CreateInfo()
            info.text = API.GetOptionText(conditional, optionLevel)
            info.disabled = not API.CanPay(conditional, optionLevel)
            info.checked = store.activeCondDamage[conditional.id] == true
                and API.GetSelectedLevel(conditional) == optionLevel
            info.func = function()
                store.activeCondDamage[conditional.id] = true
                store.condDamageLevel[conditional.id] = optionLevel
                RefreshConsumers()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")
    API.BookMenu = bookMenu

    store.GetConditionalDamageList = API.GetList
    store.IsConditionalDamageActive = API.IsActive
    store.GetConditionalDamageActiveLevel = API.GetActiveLevel
    store.GetConditionalDamageById = API.GetById
    store.ToggleConditionalDamage = API.Toggle
    store.OpenConditionalDamageMenu = function(conditionalId, anchor)
        local conditional = API.GetById(conditionalId)
        if not conditional then return end
        local minLevel = math.max(1, math.floor(tonumber(conditional.minLevel) or 1))
        if API.GetMaxLevel(conditional) <= minLevel then
            API.Toggle(conditionalId)
            return
        end
        API.bookConditionalId = conditionalId
        ToggleDropDownMenu(1, nil, bookMenu, anchor or "cursor", 0, 0)
    end
end

function API.ToggleAttackMenu(anchor)
    if API.AttackMenu then
        ToggleDropDownMenu(1, nil, API.AttackMenu, anchor, 0, 0)
    end
end
