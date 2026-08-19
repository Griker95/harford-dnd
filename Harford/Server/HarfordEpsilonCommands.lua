HarfordEpsilonCommands = HarfordEpsilonCommands or {}

local API = HarfordEpsilonCommands
local DEFAULT_ADDON_COMMANDS_NAME = "Harford"

local senders = {}

local function Trim(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function NormalizeCommand(command)
    local text = Trim(command)
    if text == "" then
        return nil, "Comando vacio"
    end
    -- Un comando es SIEMPRE de una linea. Se eliminan saltos y caracteres de control porque
    -- algunos comandos incrustan texto libre (p.ej. el prefijo del prompt en `npc te`): un `\n`
    -- pegado por accidente convertiria el resto de la cadena en un segundo comando.
    text = text:gsub("[%c]+", " ")
    text = Trim(text)
    if text == "" then
        return nil, "Comando vacio"
    end
    text = text:gsub("^%.", "")
    return text
end

local function ResolveMessageOverride(opts)
    opts = opts or {}
    if opts.showMessages == true then return true end
    if opts.showMessages == false then return false end
    return nil
end

local function ResolveName(opts)
    opts = opts or {}
    local name = tostring(opts.addonName or DEFAULT_ADDON_COMMANDS_NAME)
    if name == "" then
        name = DEFAULT_ADDON_COMMANDS_NAME
    end
    return name
end

function API.HasEpsilonLib()
    return EpsilonLib
        and EpsilonLib.AddonCommands
        and EpsilonLib.AddonCommands.Register
end

function API.HasARC()
    return ARC and (ARC.CMD or ARC.COMM)
end

function API.EnsureAddonCommands(addonName)
    addonName = tostring(addonName or DEFAULT_ADDON_COMMANDS_NAME)
    if senders[addonName] and senders[addonName].send then
        return true
    end

    if not API.HasEpsilonLib() then
        return false, "EpsilonLib.AddonCommands no disponible"
    end

    local ok, sendFn, chainFn = pcall(EpsilonLib.AddonCommands.Register, addonName, false)
    if ok and sendFn then
        senders[addonName] = { send = sendFn, chain = chainFn }
        return true
    end

    if EpsilonLib.AddonCommands.Get then
        local getOk, registered = pcall(EpsilonLib.AddonCommands.Get, addonName)
        if getOk and registered and registered.SendAddonCommand then
            senders[addonName] = {
                send = registered.SendAddonCommand,
                chain = registered.SendAddonCommandChain,
            }
            return true
        end
    end

    return false, tostring(sendFn or "No se pudo registrar " .. addonName .. " en EpsilonLib.AddonCommands")
end

function API.Send(command, opts)
    opts = opts or {}

    local text, err = NormalizeCommand(command)
    if not text then
        if opts.callback then opts.callback(false, { err }) end
        return false, err
    end

    local addonName = ResolveName(opts)
    local overrideMessages = ResolveMessageOverride(opts)

    if opts.callback then
        local ok, regErr = API.EnsureAddonCommands(addonName)
        if not ok then
            opts.callback(false, { regErr })
            return false, regErr
        end

        local sender = senders[addonName]
        local sentOk, sendErr = pcall(sender.send, text, opts.callback, overrideMessages)
        if not sentOk then
            local msg = tostring(sendErr)
            opts.callback(false, { msg })
            return false, msg
        end

        return true
    end

    if not opts.forceEpsilon and API.HasARC() then
        local cmdFn = ARC.CMD or ARC.COMM
        local ok, arcErr = pcall(cmdFn, text)
        if ok then
            return true
        end

        if not opts.allowEpsilonFallback then
            return false, tostring(arcErr)
        end
    end

    local ok, regErr = API.EnsureAddonCommands(addonName)
    if not ok then
        return false, regErr
    end

    local sender = senders[addonName]
    local sentOk, sendErr = pcall(sender.send, text, nil, overrideMessages)
    if not sentOk then
        return false, tostring(sendErr)
    end

    return true
end

function API.SendChain(commands, callback, opts)
    opts = opts or {}
    if type(commands) ~= "table" or #commands == 0 then
        local err = "SendChain necesita una lista de comandos"
        if callback then callback(false, { err }) end
        return false, err
    end

    local normalized = {}
    for i = 1, #commands do
        local text, err = NormalizeCommand(commands[i])
        if not text then
            local msg = "Comando invalido en posicion " .. tostring(i) .. ": " .. tostring(err)
            if callback then callback(false, { msg }) end
            return false, msg
        end
        normalized[i] = text
    end

    local addonName = ResolveName(opts)
    local ok, regErr = API.EnsureAddonCommands(addonName)
    if not ok then
        if callback then callback(false, { regErr }) end
        return false, regErr
    end

    local sender = senders[addonName]
    if not sender.chain then
        local err = "EpsilonLib.AddonCommands.SendChain no disponible"
        if callback then callback(false, { err }) end
        return false, err
    end

    local sentOk, sendErr = pcall(sender.chain, normalized, callback, ResolveMessageOverride(opts))
    if not sentOk then
        local msg = tostring(sendErr)
        if callback then callback(false, { msg }) end
        return false, msg
    end

    return true
end

function API.GetStatus(addonName)
    addonName = tostring(addonName or DEFAULT_ADDON_COMMANDS_NAME)
    local addonOk, addonErr = API.EnsureAddonCommands(addonName)
    return {
        epsilonLib = API.HasEpsilonLib() and true or false,
        addonCommands = addonOk and true or false,
        addonCommandsError = addonOk and nil or addonErr,
        arc = API.HasARC() and true or false,
    }
end

