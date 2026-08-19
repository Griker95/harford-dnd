-- HarfordDnDNet: capa de recursos/red de la ficha (export, request, adjust).
--
-- Saca de HarfordDnD.lua la logica de construccion de payloads de recursos y el
-- envio/solicitud por HarfordSync. HarfordDnDAPI delega aqui; las firmas publicas
-- no cambian. La APLICACION local de deltas (UI, aura de muerte) se queda en
-- HarfordDnD.lua: este modulo solo construye datos y habla con la red.

HarfordDnDNet = HarfordDnDNet or {}

local ADDON_PREFIX = "DND5EARC"

local toN = HarfordDnDStore.ToNumber

-- Antes sumaba en vivo el bonus de rasgos a las claves "_Max". Ya NO: los maximos se
-- CALCULAN y se hornean en SavedVariables al ejecutar `/harford cargarficha`, asi que el
-- valor leido (base SV) ya es el efectivo. Sumar aqui el bonus derivado lo duplicaria.
-- Se conserva la firma como passthrough para no tocar los llamadores.
local function WrapDerivedMax(baseReader, profileName, allowDerived)
    return baseReader
end

-- ─── Construccion de payloads ────────────────────────────────────────────────
function HarfordDnDNet.BuildActiveResourcePayload(readValueFn, options)
    local out, keysToSend = HarfordDnDResources.BuildPayloadFromRuntime(readValueFn, options)
    if options == nil or options.includeArmorClass ~= false then
        out.ArmorClass = tostring((readValueFn and readValueFn("ArmorClass")) or "10")
        keysToSend[#keysToSend + 1] = "ArmorClass"
    end
    return out, keysToSend
end

function HarfordDnDNet.ExportCurrentResources()
    HarfordDnDStore.EnsurePersist()
    -- En contexto NPC aplicado no se inyecta el bonus de rasgos del jugador.
    local allowDerived = not (HarfordDnDContext.State and HarfordDnDContext.State.active)
    local out = HarfordDnDNet.BuildActiveResourcePayload(WrapDerivedMax(function(key)
        return HarfordDnDContext.Get(key, "0")
    end, nil, allowDerived))
    return out
end

function HarfordDnDNet.ExportProfileResourcesFromBank(profileName)
    local tbl = HarfordDnDProfileBank and HarfordDnDProfileBank[profileName]
    if type(tbl) ~= "table" then
        return nil
    end

    local out = HarfordDnDResources.BuildPayloadFromTable(tbl, {
        includeCurrent = false,
        includeMax = true,
        activityMode = "max",
    })
    if next(out) == nil then
        return nil
    end
    return out
end

-- ─── Lectura de cache remota ─────────────────────────────────────────────────
function HarfordDnDNet.GetRemoteResourceValue(tbl, key)
    if not tbl then return 0 end
    return toN(tbl[key], 0)
end

function HarfordDnDNet.RemoteResourceExists(tbl, resourceKey)
    if not tbl then return false end
    local cur = HarfordDnDNet.GetRemoteResourceValue(tbl, HarfordDnDResources.CurKey(resourceKey))
    local max = HarfordDnDNet.GetRemoteResourceValue(tbl, HarfordDnDResources.MaxKey(resourceKey))
    return HarfordDnDResources.Exists(resourceKey, cur, max)
end

-- ─── Envio / solicitud por HarfordSync ───────────────────────────────────────
function HarfordDnDNet.SendResourceResponseTo(targetName)
    if not targetName or targetName == "" then
        return false
    end

    local profileName = tostring((UnitName and UnitName("player")) or "default")

    local allowDerived = not (HarfordDnDContext.State and HarfordDnDContext.State.active)
    local tbl, keysToSend = HarfordDnDNet.BuildActiveResourcePayload(WrapDerivedMax(function(key)
        return HarfordDnDContext.Get(key, "0")
    end, nil, allowDerived))

    -- Junto con los recursos, informamos de nuestro flag de animaciones
    HarfordSync.SendAnimFlag(ADDON_PREFIX, HarfordDnDStore.animsEnabled ~= false, targetName)

    return HarfordSync.SendResourceResponse(
        ADDON_PREFIX,
        profileName,
        tbl,
        targetName,
        keysToSend
    )
end

function HarfordDnDNet.SendResourceResponseForProfileTo(profileName, targetName)
    if not targetName or targetName == "" then
        return false
    end

    local resolvedProfile = tostring(profileName or (UnitName and UnitName("player")) or "default")
    HarfordDnDStore.EnsurePersist(resolvedProfile)

    local profile = HarfordDnDPersistStore.profiles and HarfordDnDPersistStore.profiles[resolvedProfile]
    if type(profile) ~= "table" then
        profile = {}
    end

    local tbl, keysToSend = HarfordDnDNet.BuildActiveResourcePayload(WrapDerivedMax(function(key)
        return profile[key] or "0"
    end, resolvedProfile, true))

    return HarfordSync.SendResourceResponse(
        ADDON_PREFIX,
        resolvedProfile,
        tbl,
        targetName,
        keysToSend
    )
end

-- Throttle de solicitudes por jugador (estado privado del modulo).
local _resourceRequestTimes = {}
local RESOURCE_REQUEST_COOLDOWN = 12  -- segundos mínimos entre requests al mismo jugador

function HarfordDnDNet.RequestResourcesFromPlayer(targetName)
    if not targetName or targetName == "" then return false end
    local now = GetTime and GetTime() or 0
    local last = _resourceRequestTimes[targetName] or 0
    if (now - last) < RESOURCE_REQUEST_COOLDOWN then return false end
    _resourceRequestTimes[targetName] = now
    local requester = HarfordClassColors.UnitFullName("player") or "default"
    return HarfordSync.SendResourceRequest(ADDON_PREFIX, requester, targetName)
end

function HarfordDnDNet.SendResourceAdjustToPlayer(targetName, resourceKey, delta)
    return HarfordSync.SendResourceAdjust(ADDON_PREFIX, resourceKey, delta, targetName)
end

-- Pide a OTRO jugador que se aplique un aura (Desarme): el receptor ejecuta `.au <id> self`.
function HarfordDnDNet.SendAuraToPlayer(targetName, spellId)
    if not targetName or targetName == "" then return false end
    return HarfordSync.SendAuraSignal(ADDON_PREFIX, spellId, targetName)
end
