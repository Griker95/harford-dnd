HarfordAuthority = HarfordAuthority or {}

local API = HarfordAuthority
local listeners = {}
local lastSignature
local epsilonEventRegistered = false

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

local function IsTruthy(value)
    return value == true or value == 1 or value == "1" or value == "true" or value == "TRUE"
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
    return IsTruthy(value)
end

local function DirectPhaseFlag(name)
    if C_Epsilon and IsTruthy(C_Epsilon[name]) then
        return true
    end

    local fn = ResolveCepsilonFunction(name)
    local value = SafeCall(fn)
    return IsTruthy(value)
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
    return API.HasAdminAddon() and API.IsDMMode()
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

local function StatusSignature(status)
    status = status or API.GetStatus()
    return table.concat({
        tostring(status.adminAddon),
        tostring(status.phaseId),
        tostring(status.phaseMember),
        tostring(status.phaseOfficer),
        tostring(status.phaseOwner),
        tostring(status.dmMode),
        tostring(status.dmEnabled),
    }, "|")
end

local function ReportListenerError(owner, err)
    if HarfordDebug and HarfordDebug.Print then
        HarfordDebug.Print("authority listener " .. tostring(owner) .. ": " .. tostring(err))
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[HarfordAuthority]|r listener " .. tostring(owner) .. ": " .. tostring(err))
    end
end

local function InvokeListener(owner, callback, status, reason)
    local ok, err = pcall(callback, status, reason)
    if not ok then
        ReportListenerError(owner, err)
        return false
    end
    return true
end

function API.NotifyChanged(reason, force)
    local status = API.GetStatus()
    local signature = StatusSignature(status)
    if not force and signature == lastSignature then
        return false
    end

    lastSignature = signature
    for owner, callback in pairs(listeners) do
        if type(callback) == "function" then
            InvokeListener(owner, callback, status, reason)
        end
    end
    return true
end

function API.ScheduleRefresh(reason)
    API.NotifyChanged(reason, true)
end

function API.RegisterChangeListener(owner, callback)
    if type(owner) ~= "string" or owner == "" or type(callback) ~= "function" then
        return false
    end

    listeners[owner] = callback
    InvokeListener(owner, callback, API.GetStatus(), "register")
    return true
end

function API.UnregisterChangeListener(owner)
    listeners[owner] = nil
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

local function RegisterEpsilonEventManager()
    if epsilonEventRegistered then
        return
    end

    if EpsilonLib and EpsilonLib.EventManager and EpsilonLib.EventManager.Register then
        local ok = pcall(EpsilonLib.EventManager.Register, EpsilonLib.EventManager, "EPSILON_PHASE_CHANGE", function()
            API.ScheduleRefresh("EPSILON_PHASE_CHANGE")
        end)
        epsilonEventRegistered = ok == true
    end
end

local eventFrame = CreateFrame and CreateFrame("Frame")
if eventFrame then
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
    eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
    eventFrame:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" then
            if addonName ~= "Harford" and addonName ~= "HarfordAdmin" and addonName ~= "SpellCreator" and addonName ~= "EpsilonLib" then
                return
            end
            RegisterEpsilonEventManager()
        elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            RegisterEpsilonEventManager()
        end
        API.ScheduleRefresh(event)
    end)
end
