-- HarfordDnDCombat: reglas de combate compartidas que no pertenecen a UI.
-- Mantiene fuera de HarfordDnD.lua la resolucion de CA/impacto y aplicaciones
-- pequeñas de combate que consultan unit tokens, TRP3, turnos o cache remota.

HarfordDnDCombat = HarfordDnDCombat or {}
HarfordDnDCombat.ArmorClassOverrides = HarfordDnDCombat.ArmorClassOverrides or {}

local ADDON_PREFIX = "DND5EARC"

local GREEN = "|cff00ff00"
local RED = "|cffff3333"
local ENDCLR = "|r"

local function toN(x, d)
    local n = tonumber(x)
    if n == nil then return d or 0 end
    return n
end

local function GetSelfArmorClass()
    if HarfordDnDContext and HarfordDnDContext.Get then
        return math.floor(toN(HarfordDnDContext.Get("ArmorClass", "10"), 10))
    end
    return 10
end

local function GetUnitKeys(unit)
    local keys = {}
    local guid = UnitGUID and UnitGUID(unit) or nil
    if guid and guid ~= "" then keys[#keys + 1] = guid end

    local fullName = GetUnitName and GetUnitName(unit, true) or nil
    local shortName = UnitName and UnitName(unit) or nil
    if fullName and fullName ~= "" then keys[#keys + 1] = fullName end
    if shortName and shortName ~= "" and shortName ~= fullName then keys[#keys + 1] = shortName end
    return keys
end

local function GetOverrideArmorClassForUnit(unit)
    local overrides = HarfordDnDCombat.ArmorClassOverrides
    for _, key in ipairs(GetUnitKeys(unit)) do
        local value = overrides[key]
        local armorClass = tonumber(value)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end
    end
    return nil
end

local function SetOverrideArmorClassForUnit(unit, armorClass)
    local overrides = HarfordDnDCombat.ArmorClassOverrides
    for _, key in ipairs(GetUnitKeys(unit)) do
        overrides[key] = armorClass
    end
end

function HarfordDnDCombat.GetRemoteArmorClassForUnit(unit)
    if not (UnitName and HarfordDnDResources and HarfordDnDResources.RemoteCache) then
        return nil
    end

    local name = GetUnitName and GetUnitName(unit, true) or UnitName(unit)
    local short = name and Ambiguate and Ambiguate(name, "short") or name
    local cache = (name and HarfordDnDResources.RemoteCache[name])
        or (short and HarfordDnDResources.RemoteCache[short])
    local armorClass = cache and tonumber(cache.ArmorClass)
    if armorClass and armorClass > 0 then
        return math.floor(armorClass)
    end
    return nil
end

function HarfordDnDCombat.GetProfileArmorClassForUnit(unit)
    if not UnitName then return nil end

    local names = {}
    local fullName = GetUnitName and GetUnitName(unit, true) or nil
    local shortName = UnitName(unit)
    if fullName and fullName ~= "" then names[#names + 1] = fullName end
    if shortName and shortName ~= "" and shortName ~= fullName then names[#names + 1] = shortName end

    for _, name in ipairs(names) do
        local profile = HarfordDnDProfileBank and HarfordDnDProfileBank[name]
        local armorClass = profile and tonumber(profile.ArmorClass)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end

        local storeProfile = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
            and HarfordDnDPersistStore.profiles[name]
        armorClass = storeProfile and tonumber(storeProfile.ArmorClass)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end
    end

    return nil
end

function HarfordDnDCombat.GetArmorClassForUnit(unit)
    if not (unit and UnitExists and UnitExists(unit)) then
        return nil
    end

    if UnitIsPlayer and UnitIsPlayer(unit) then
        if UnitIsUnit and UnitIsUnit(unit, "player") then
            return GetSelfArmorClass()
        end
        local trp3ArmorClass = HarfordTRP3 and HarfordTRP3.GetPlayerArmorClass
            and HarfordTRP3.GetPlayerArmorClass(unit)
        return trp3ArmorClass
            or HarfordDnDCombat.GetRemoteArmorClassForUnit(unit)
            or GetOverrideArmorClassForUnit(unit)
            or HarfordDnDCombat.GetProfileArmorClassForUnit(unit)
    end

    local guid = UnitGUID and UnitGUID(unit)
    if guid and HarfordTurnOrderAPI and HarfordTurnOrderAPI.GetArmorClassForGuid then
        local turnArmorClass = HarfordTurnOrderAPI.GetArmorClassForGuid(guid)
        if turnArmorClass and turnArmorClass > 0 then
            return math.floor(turnArmorClass)
        end
    end

    local overrideArmorClass = GetOverrideArmorClassForUnit(unit)
    if overrideArmorClass then
        return overrideArmorClass
    end

    if HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local statBlock = HarfordTRP3.GetNPCStatBlock(unit)
        local armorClass = statBlock and tonumber(statBlock.ac)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end
    end

    return nil
end

function HarfordDnDCombat.SetArmorClassForUnit(unit, value)
    if not (unit and UnitExists and UnitExists(unit)) then
        return false, "Sin objetivo"
    end

    local armorClass = math.floor(tonumber(value) or 0)
    if armorClass < 0 then armorClass = 0 end

    if UnitIsPlayer and UnitIsPlayer(unit) then
        if UnitIsUnit and UnitIsUnit(unit, "player") then
            if HarfordDnDContext and HarfordDnDContext.Set then
                HarfordDnDContext.Set("ArmorClass", armorClass)
                return true
            end
            return false, "HarfordDnDContext no disponible"
        end

        SetOverrideArmorClassForUnit(unit, armorClass)
        return true
    end

    SetOverrideArmorClassForUnit(unit, armorClass)

    local guid = UnitGUID and UnitGUID(unit) or nil
    if guid and HarfordTurnOrderAPI and HarfordTurnOrderAPI.SetArmorClassForGuid then
        HarfordTurnOrderAPI.SetArmorClassForGuid(guid, armorClass)
    end
    return true
end

function HarfordDnDCombat.IsCriticalRollTag(critTag)
    return critTag == "CRITICO" or critTag == "CR\195\141TICO"
end

function HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, unit)
    local armorClass = HarfordDnDCombat.GetArmorClassForUnit(unit or "target")
    if not armorClass or armorClass <= 0 then
        return nil, nil, ""
    end

    local hit
    if HarfordDnDCombat.IsCriticalRollTag(critTag) then
        hit = true
    elseif critTag == "PIFIA" then
        hit = false
    else
        hit = (tonumber(total) or 0) >= armorClass
    end

    local status = hit and (GREEN .. "Superada" .. ENDCLR) or (RED .. "No superada" .. ENDCLR)
    return armorClass, hit, " vs CA " .. tostring(armorClass) .. " " .. status
end

function HarfordDnDCombat.ApplyWeaponDamageToNpc(total, isCritical)
    if total and total > 0
        and HarfordAuthority and HarfordAuthority.IsOfficerPlus and HarfordAuthority.IsOfficerPlus()
        and UnitExists and UnitExists("target")
        and not (UnitIsPlayer and UnitIsPlayer("target"))
        and HarfordServerActions and HarfordServerActions.SetNpcHealthDelta then
        HarfordServerActions.SetNpcHealthDelta(-total, {
            isCritical = isCritical,
            addonName  = "Harford",
        })
        return true
    end
    return false
end

-- Aplica daño a un jugador objetivo (no a uno mismo) por RADJ: consume primero
-- temp_health (segun la cache remota) y el resto a health. Si no hay cache, manda
-- todo a health y solicita recursos para futuras tiradas. El cliente receptor
-- aplica el delta (y su propia aura de muerte segun su flag de animaciones).
local function ApplyWeaponDamageToPlayer(total)
    local targetName = (GetUnitName and GetUnitName("target", true)) or (UnitName and UnitName("target"))
    if not targetName or targetName == "" then return false end
    if not (HarfordSync and HarfordSync.SendResourceAdjust) then return false end

    local tempCur = 0
    local cache = HarfordDnDResources and HarfordDnDResources.RemoteCache
    if cache then
        local short = Ambiguate and Ambiguate(targetName, "short") or targetName
        cache = cache[targetName] or cache[short]
    end
    if cache then
        tempCur = math.max(0, tonumber(cache[HarfordDnDResources.CurKey("temp_health")]) or 0)
    elseif HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName then
        HarfordDnDAPI.RequestResourcesForName(targetName)
    end

    local tempDmg = math.min(total, tempCur)
    local healthDmg = total - tempDmg
    if tempDmg > 0 then
        HarfordSync.SendResourceAdjust(ADDON_PREFIX, "temp_health", -tempDmg, targetName)
    end
    if healthDmg > 0 then
        HarfordSync.SendResourceAdjust(ADDON_PREFIX, "health", -healthDmg, targetName)
    end
    return true
end

-- Aplica el daño al objetivo actual segun su tipo: NPC (ruta oficial, en bruto) o
-- jugador ajeno (RADJ con split temp/health). No hace nada contra uno mismo.
function HarfordDnDCombat.ApplyWeaponDamageToTarget(total, isCritical)
    if not (total and total > 0 and UnitExists and UnitExists("target")) then return false end
    if UnitIsUnit and UnitIsUnit("target", "player") then return false end
    if UnitIsPlayer and UnitIsPlayer("target") then
        return ApplyWeaponDamageToPlayer(total)
    end
    return HarfordDnDCombat.ApplyWeaponDamageToNpc(total, isCritical)
end
