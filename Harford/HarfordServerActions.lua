HarfordServerActions = HarfordServerActions or {}

local API = HarfordServerActions

-- Validaciones, plantillas y constantes de emote viven en sus respectivos modulos:
--   * HarfordCommandTemplates.* + Build(template, args) -> string
--   * HarfordEmotes.NPC_WOUND.id                        -> emote 33 (ONESHOT_WOUND)
--
-- Este modulo se encarga solo de validar los inputs y delegar a la capa de
-- transporte (HarfordEpsilonCommands). No construye strings literales.

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

-- Variante que admite 0: la postura "Stand" del modo combate NPC se envia como
-- `npc emote 0 repeat`, por lo que el emote 0 es valido en ese contexto.
local function ToNonNegativeInteger(value, name)
    local numberValue = tonumber(value)
    if not numberValue then
        return nil, tostring(name or "valor") .. " debe ser numerico"
    end

    numberValue = math.floor(numberValue)
    if numberValue < 0 then
        return nil, tostring(name or "valor") .. " no puede ser negativo"
    end

    return numberValue
end

local function SendCommand(command, opts)
    if not HarfordEpsilonCommands or not HarfordEpsilonCommands.Send then
        return false, "HarfordEpsilonCommands no disponible"
    end

    return HarfordEpsilonCommands.Send(command, opts)
end

local function BuildAndSend(templateKey, args, opts)
    local template = HarfordCommandTemplates and HarfordCommandTemplates[templateKey]
    if not template then
        return false, "template desconocida: " .. tostring(templateKey)
    end
    local command, err = HarfordCommandTemplates.Build(template, args)
    if not command then
        return false, err
    end
    return SendCommand(command, opts)
end

local function GetNpcWoundEmoteId(isCritical)
    if isCritical then
        return (HarfordEmotes and HarfordEmotes.NPC_WOUND_CRIT and HarfordEmotes.NPC_WOUND_CRIT.id) or 34
    end
    return (HarfordEmotes and HarfordEmotes.NPC_WOUND and HarfordEmotes.NPC_WOUND.id) or 33
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

    return BuildAndSend("ADD_ITEM", { id = safeItemId, qty = safeQuantity }, opts)
end

-- Aplica un aura al propio personaje: envia "aura ID self".
function API.ApplyAura(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return BuildAndSend("AURA_SELF", { id = safeSpellId }, opts)
end

-- Aplica un aura al unit actualmente seleccionado en el cliente (sin sufijo).
function API.ApplyAuraToCurrentTarget(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return BuildAndSend("AURA_TARGET", { id = safeSpellId }, opts)
end

-- Quita un aura del propio personaje: envia "unaura ID self".
function API.RemoveAuraSelf(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return BuildAndSend("UNAURA_SELF", { id = safeSpellId }, opts)
end

-- Quita un aura del unit actualmente seleccionado en el cliente (sin sufijo).
function API.RemoveAura(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return BuildAndSend("UNAURA_TARGET", { id = safeSpellId }, opts)
end

function API.GetPhaseInfo(callback, opts)
    opts = opts or {}
    opts.callback = callback
    opts.forceEpsilon = true
    return BuildAndSend("PHASE_INFO", {}, opts)
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

    local sign = amount > 0 and "+" or "-"
    local absAmount = math.abs(amount)
    local ok, err = BuildAndSend("NPC_SET_HEALTH", { sign = sign, amount = absAmount }, opts)
    if ok and amount < -1 then
        -- ONESHOT_WOUND: reaccion breve del NPC al recibir dano real.
        -- No reutilizar callback: pertenece al cambio de salud, no al emote.
        -- opts.isCritical controla si se usa la variante critica (emote 34).
        local emoteOpts = {}
        for key, value in pairs(opts or {}) do
            if key ~= "callback" then
                emoteOpts[key] = value
            end
        end
        API.SetNpcEmote(GetNpcWoundEmoteId(opts and opts.isCritical), emoteOpts)
    end
    return ok, err
end

function API.ModAnim(animId, opts)
    local safeAnimId, animErr = ToPositiveInteger(animId, "animId")
    if not safeAnimId then
        return false, animErr
    end

    return BuildAndSend("MOD_ANIM", { id = safeAnimId }, opts)
end

function API.SetNpcEmote(emoteId, opts)
    local safeEmoteId, emoteErr = ToPositiveInteger(emoteId, "emoteId")
    if not safeEmoteId then
        return false, emoteErr
    end

    -- Canal silencioso de EpsilonLib: ARC.CMD dejaria visible la confirmacion
    -- del servidor ("... is now ... emote N") en el chat.
    opts = opts or {}
    opts.forceEpsilon = true
    if opts.showMessages == nil then opts.showMessages = false end
    return BuildAndSend("NPC_EMOTE", { id = safeEmoteId }, opts)
end

-- Postura de combate persistente: "npc emote ID repeat" (bucle hasta otro emote).
-- Admite emote 0 (Stand: salir del modo combate).
function API.SetNpcEmoteRepeat(emoteId, opts)
    local safeEmoteId, emoteErr = ToNonNegativeInteger(emoteId, "emoteId")
    if not safeEmoteId then
        return false, emoteErr
    end

    -- Mismo motivo que SetNpcEmote: forzar EpsilonLib y ocultar la respuesta.
    opts = opts or {}
    opts.forceEpsilon = true
    if opts.showMessages == nil then opts.showMessages = false end
    return BuildAndSend("NPC_EMOTE_REPEAT", { id = safeEmoteId }, opts)
end

function API.RepossessCurrentNpc(opts)
    if not HarfordEpsilonCommands or not HarfordEpsilonCommands.SendChain then
        return false, "HarfordEpsilonCommands.SendChain no disponible"
    end

    opts = opts or {}
    opts.forceEpsilon = true
    local unposs = HarfordCommandTemplates and HarfordCommandTemplates.UNPOSS or "unposs"
    local poss   = HarfordCommandTemplates and HarfordCommandTemplates.POSS   or "poss"
    return HarfordEpsilonCommands.SendChain({ unposs, poss }, opts.callback, opts)
end

function API.UnpossessCurrentNpc(opts)
    opts = opts or {}
    opts.forceEpsilon = true
    return BuildAndSend("UNPOSS", {}, opts)
end

function API.SetNpcAura(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return BuildAndSend("NPC_SET_AURA", { id = safeSpellId }, opts)
end

function API.RemoveNpcAura(spellId, opts)
    local safeSpellId, spellErr = ToPositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    return BuildAndSend("NPC_SET_UNAURA", { id = safeSpellId }, opts)
end

function API.SendNpcTRP3Hyperlink(hyperlink, opts)
    local text = tostring(hyperlink or "")
    if not HarfordTRP3 or not HarfordTRP3.IsKnownGlanceHyperlink
        or not HarfordTRP3.IsKnownGlanceHyperlink(text) then
        return false, "hyperlink TRP3 no generado por Harford"
    end

    -- opts.textPrefix: texto libre que aparece ANTES del hyperlink en el textemote.
    -- opts.textSuffix: texto libre que aparece DESPUES del hyperlink (p.ej. nombre del focus).
    local prefix = (opts and opts.textPrefix and #opts.textPrefix > 0)
        and (opts.textPrefix .. " ") or ""
    local suffix = (opts and opts.textSuffix and #opts.textSuffix > 0)
        and (" " .. opts.textSuffix) or ""
    local command = "npc te " .. prefix .. text .. suffix
    if #command >= 250 then
        return false, "hyperlink TRP3 demasiado largo para EpsilonLib.AddonCommands"
    end

    opts = opts or {}
    opts.forceEpsilon = true
    return SendCommand(command, opts)
end

function API.SetPhaseNpcFaction(factionId, opts)
    local safeFactionId, factionErr = ToPositiveInteger(factionId, "Faction ID")
    if not safeFactionId then
        return false, factionErr
    end

    opts = opts or {}
    opts.forceEpsilon = true
    return BuildAndSend("PH_F_N_FAC", { factionId = safeFactionId }, opts)
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
