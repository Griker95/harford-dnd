-- Adaptador DM de condiciones. Harford contiene reglas/recepcion; este modulo
-- valida autoridad y ejecuta aplicaciones sobre jugadores o NPC concretos.

HarfordAdminConditions = HarfordAdminConditions or {}
local API = HarfordAdminConditions
local pendingRemovals = {}

local function Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[HarfordAdmin]|r " .. tostring(message or ""))
    end
end

local function IsAllowed()
    return HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools() == true
end

local function SameUnit(snapshot)
    return snapshot and snapshot.unit and UnitExists and UnitExists(snapshot.unit)
        and (not snapshot.guid or snapshot.guid == "" or not UnitGUID or UnitGUID(snapshot.unit) == snapshot.guid)
end

local function Options(snapshot, extra)
    local out = {}
    for key, value in pairs(extra or {}) do out[key] = value end
    out.sourceGuid = out.sourceGuid or ""
    out.sourceName = out.sourceName or ""
    out.targetGuid = snapshot and snapshot.guid or ""
    out.targetName = snapshot and snapshot.name or ""
    out.authority = snapshot and not snapshot.isPlayer or false
    return out
end

function API.Has(snapshot, conditionId)
    if not (snapshot and HarfordDnDConditions and HarfordDnDConditions.Has) then return false end
    return HarfordDnDConditions.Has(snapshot.unit or snapshot.guid, conditionId)
end

function API.Apply(snapshot, conditionId, extra)
    if not IsAllowed() then return false, "Requiere HarfordAdmin y .ph dm activo" end
    if not SameUnit(snapshot) then return false, "La unidad ya no coincide con el unitframe" end
    local def = HarfordDnDConditions and HarfordDnDConditions.GetDefinition
        and HarfordDnDConditions.GetDefinition(conditionId)
    if not def then return false, "Condicion desconocida" end
    if HarfordDnDConditions.HasConditionImmunity(snapshot.unit, conditionId) then
        return false, tostring(snapshot.name or "El objetivo") .. " es inmune a " .. tostring(def.label)
    end

    local opts = Options(snapshot, extra)
    if snapshot.isPlayer then
        return HarfordDnDConditions.RequestPlayer(snapshot.unit, conditionId, true, opts)
    end

    if def.auraId then
        local ok, err = HarfordAuras.ApplyById(def.auraId, "npc", { addonName = "HarfordAdmin" })
        if ok == false then return false, err end
    end
    return HarfordDnDConditions.SetUnitState(snapshot.unit, conditionId, opts)
end

function API.Remove(snapshot, conditionId)
    if not IsAllowed() then return false, "Requiere HarfordAdmin y .ph dm activo" end
    if not SameUnit(snapshot) then return false, "La unidad ya no coincide con el unitframe" end
    local def = HarfordDnDConditions and HarfordDnDConditions.GetDefinition
        and HarfordDnDConditions.GetDefinition(conditionId)
    if not def then return false, "Condicion desconocida" end

    if snapshot.isPlayer then
        return HarfordDnDConditions.RequestPlayer(snapshot.unit, conditionId, false)
    end
    if def.auraId then
        local ok, err = HarfordAuras.RemoveById(def.auraId, "npc", { addonName = "HarfordAdmin" })
        if ok == false then return false, err end
    end
    HarfordDnDConditions.RemoveUnitState(snapshot.unit, conditionId)
    return true, "removed"
end

function API.Toggle(snapshot, conditionId, extra)
    local ok, err
    if API.Has(snapshot, conditionId) then ok, err = API.Remove(snapshot, conditionId)
    else ok, err = API.Apply(snapshot, conditionId, extra) end
    if not ok and err then Print(err) end
    return ok, err
end

if HarfordDnDConditions and HarfordDnDConditions.SetAdminHooks then
    HarfordDnDConditions.SetAdminHooks({
        applyAura = function(ref, conditionId)
            local def = HarfordDnDConditions.GetDefinition(conditionId)
            local guid = type(ref) == "table" and ref.guid or tostring(ref or "")
            if not (def and def.auraId) then return true end
            if not IsAllowed() then return false, "Requiere HarfordAdmin y .ph dm activo" end
            if not (UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target") == guid
                and not (UnitIsPlayer and UnitIsPlayer("target"))) then
                return false, "El target ya no coincide con el NPC de la condicion"
            end
            return HarfordAuras.ApplyById(def.auraId, "npc", { addonName = "HarfordAdmin" })
        end,
        removeAura = function(ref, conditionId)
            local def = HarfordDnDConditions.GetDefinition(conditionId)
            local guid = type(ref) == "table" and ref.guid or tostring(ref or "")
            if not (def and def.auraId) then return true end
            if not IsAllowed() then return false, "Requiere HarfordAdmin y .ph dm activo" end
            if not (UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target") == guid) then
                pendingRemovals[guid] = pendingRemovals[guid] or {}
                pendingRemovals[guid][conditionId] = true
                return true
            end
            return HarfordAuras.RemoveById(def.auraId, "npc", { addonName = "HarfordAdmin" })
        end,
    })
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
    local guid = UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target") or nil
    if guid and not (UnitIsPlayer and UnitIsPlayer("target"))
        and HarfordDnDConditions and HarfordDnDConditions.ResolvePendingForUnit then
        HarfordDnDConditions.ResolvePendingForUnit("target")
    end
    local bucket = guid and pendingRemovals[guid]
    if not bucket or (UnitIsPlayer and UnitIsPlayer("target")) then return end
    for conditionId in pairs(bucket) do
        local def = HarfordDnDConditions.GetDefinition(conditionId)
        if def and def.auraId then HarfordAuras.RemoveById(def.auraId, "npc", { addonName = "HarfordAdmin" }) end
    end
    pendingRemovals[guid] = nil
end)
