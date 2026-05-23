HarfordServerActions = HarfordServerActions or {}

local API = HarfordServerActions

local DEFAULT_TARGET = "self"

local function ToPositiveInteger(value, name)
    local numberValue = tonumber(value)
    if not numberValue then
        return nil, tostring(name or "valor") .. " debe ser numerico"
    end

    numberValue = math.floor(numberValue)
    if numberValue <= 0 then
        return nil, tostring(name or "valor") .. " debe ser mayor que 0"
    end

    return numberValue
end

local function NormalizeTarget(target)
    target = tostring(target or DEFAULT_TARGET)
    target = target:gsub("^%s+", ""):gsub("%s+$", "")
    if target == "" then
        target = DEFAULT_TARGET
    end

    if not target:match("^[%w_%-]+$") then
        return nil, "target invalido"
    end

    return target
end

local function SendCommand(command, opts)
    if not HarfordEpsilonCommands or not HarfordEpsilonCommands.Send then
        return false, "HarfordEpsilonCommands no disponible"
    end

    return HarfordEpsilonCommands.Send(command, opts)
end

function API.GiveItem(itemId, quantity, opts)
    local safeItemId, itemErr = ToPositiveInteger(itemId, "itemId")
    if not safeItemId then
        return false, itemErr
    end

    local safeQuantity, quantityErr = ToPositiveInteger(quantity or 1, "quantity")
    if not safeQuantity then
        return false, quantityErr
    end

    return SendCommand("additem " .. tostring(safeItemId) .. " " .. tostring(safeQuantity), opts)
end

function API.ApplyAura(spellId, target, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    local safeTarget, targetErr = NormalizeTarget(target)
    if not safeTarget then
        return false, targetErr
    end

    return SendCommand("aura " .. tostring(safeSpellId) .. " " .. safeTarget, opts)
end

function API.RemoveAura(spellId, target, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    local safeTarget, targetErr = NormalizeTarget(target)
    if not safeTarget then
        return false, targetErr
    end

    return SendCommand("unaura " .. tostring(safeSpellId) .. " " .. safeTarget, opts)
end

function API.GetPhaseInfo(callback, opts)
    opts = opts or {}
    opts.callback = callback
    opts.forceEpsilon = true
    return SendCommand("phase info addon", opts)
end

function API.SetNpcHealthDelta(delta, opts)
    local amount = tonumber(delta)
    if not amount or amount == 0 then
        return false, "delta invalido"
    end

    amount = math.floor(amount)
    if math.abs(amount) > 9999 then
        return false, "delta NPC demasiado grande"
    end

    local sign = amount > 0 and ("+" .. tostring(amount)) or tostring(amount)
    return SendCommand("npc set health " .. sign, opts)
end

function API.SetNpcAura(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return SendCommand("npc set aura " .. tostring(safeSpellId), opts)
end

function API.SetPhaseNpcFaction(factionId, opts)
    local safeFactionId, factionErr = ToPositiveInteger(factionId, "Faction ID")
    if not safeFactionId then
        return false, factionErr
    end

    opts = opts or {}
    opts.forceEpsilon = true
    return SendCommand("ph f n fac " .. tostring(safeFactionId), opts)
end

function API.SendRawDebug(command, callback, opts)
    if not HarfordDebug or not HarfordDebug.IsEnabled or not HarfordDebug.IsEnabled() then
        local err = "debug desactivado"
        if callback then callback(false, { err }) end
        return false, err
    end

    opts = opts or {}
    opts.callback = callback
    opts.forceEpsilon = true
    return SendCommand(command, opts)
end
