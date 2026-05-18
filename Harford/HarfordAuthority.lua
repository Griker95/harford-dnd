HarfordAuthority = HarfordAuthority or {}

local API = HarfordAuthority

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, value = pcall(fn, ...)
    if ok then
        return value
    end

    return nil
end

local function ResolvePhaseFunction(name)
    if ARC and ARC.PHASE and type(ARC.PHASE[name]) == "function" then
        return ARC.PHASE[name]
    end

    if ARC and ARC.XAPI and ARC.XAPI.Phase and type(ARC.XAPI.Phase[name]) == "function" then
        return ARC.XAPI.Phase[name]
    end

    return nil
end

local function ResolveCepsilonFunction(name)
    if C_Epsilon and type(C_Epsilon[name]) == "function" then
        return C_Epsilon[name]
    end

    return nil
end

local function PhaseFlag(name)
    local fn = ResolvePhaseFunction(name)
    local value = SafeCall(fn)
    return value == true
end

local function DirectPhaseFlag(name)
    if C_Epsilon and C_Epsilon[name] == true then
        return true
    end

    local fn = ResolveCepsilonFunction(name)
    local value = SafeCall(fn)
    return value == true
end

function API.HasAdminAddon()
    return HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true
end

function API.IsPhaseOwner()
    return PhaseFlag("IsOwner")
end

function API.IsPhaseOfficer()
    return PhaseFlag("IsOfficer")
end

function API.IsPhaseMember()
    return PhaseFlag("IsMember")
end

function API.IsDMMode()
    if PhaseFlag("IsDM") then
        return true
    end

    return DirectPhaseFlag("IsDM")
end

function API.IsDMEnabled()
    return API.IsDMMode() and (API.IsPhaseOfficer() or API.IsPhaseOwner())
end

function API.IsOfficerPlus()
    return API.IsPhaseOfficer() or API.IsPhaseOwner()
end

function API.IsMemberPlus()
    return API.IsPhaseMember() or API.IsOfficerPlus()
end

function API.GetPhaseId()
    local fn = ResolvePhaseFunction("GetPhaseId")
    return SafeCall(fn)
end

function API.CanUseDMTools()
    if API.HasAdminAddon() then
        return true
    end

    return API.IsDMMode()
end

function API.CanUseMemberCommands()
    if API.HasAdminAddon() then
        return true
    end

    return API.IsMemberPlus()
end

function API.CanUseOfficerCommands()
    if API.HasAdminAddon() then
        return true
    end

    return API.IsOfficerPlus()
end

function API.CanUseAdminCommands()
    return API.HasAdminAddon()
end

function API.GetStatus()
    return {
        adminAddon = API.HasAdminAddon(),
        phaseId = API.GetPhaseId(),
        phaseMember = API.IsPhaseMember(),
        phaseOfficer = API.IsPhaseOfficer(),
        phaseOwner = API.IsPhaseOwner(),
        memberPlus = API.IsMemberPlus(),
        officerPlus = API.IsOfficerPlus(),
        dmMode = API.IsDMMode(),
        dmEnabled = API.IsDMEnabled(),
        canUseDMTools = API.CanUseDMTools(),
        canUseMemberCommands = API.CanUseMemberCommands(),
        canUseOfficerCommands = API.CanUseOfficerCommands(),
        canUseAdminCommands = API.CanUseAdminCommands(),
    }
end

local REQUIREMENTS = {
    member = API.CanUseMemberCommands,
    officer = API.CanUseOfficerCommands,
    admin = API.CanUseAdminCommands,
    dm = API.CanUseDMTools,
}

function API.CanUse(requirement)
    requirement = tostring(requirement or ""):lower()
    local checker = REQUIREMENTS[requirement]
    if not checker then
        return false
    end

    return checker()
end

function API.Require(requirement, actionName)
    if API.CanUse(requirement) then
        return true
    end

    return false, tostring(actionName or "accion") .. " requiere permisos " .. tostring(requirement or "desconocidos")
end

function API.RequireDMTools(actionName)
    return API.Require("dm", actionName)
end
