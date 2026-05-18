HarfordDnDComm = HarfordDnDComm or {}

function HarfordDnDComm.CreateHandlers(deps)
    local handlers = {}

    handlers.IsSelfSender = function(name)
        if not name or name == "" then return false end
        local myShortName = UnitName("player")
        local myFullName = GetUnitName and GetUnitName("player", true)
        return (myShortName and name == myShortName) or (myFullName and name == myFullName)
    end

    handlers.HandlePlayerLogin = function()
		local playerProfile = UnitName("player") or "default"

		deps.EnsurePersist()
		deps.EnsureTargetResourceFrameState()
		deps.LoadPersistToRuntime(playerProfile)
		deps.CreateDnDMinimapButton()
		deps.PlayerFrame:Hide()
		deps.RefreshAPI()
	end

    handlers.HandlePlayerTargetChanged = function()
        deps.TargetResourceFrame:Hide()
        deps.RefreshTargetResourceFrame()

        if not UnitExists("target") or not UnitIsPlayer("target") then return end
        local targetName = (GetUnitName and GetUnitName("target", true)) or UnitName("target")
        if not targetName or targetName == "" then return end

        local myName = (GetUnitName and GetUnitName("player", true)) or UnitName("player")
        if targetName == myName then
            deps.RefreshTargetResourceFrame()
            return
        end

        deps.RequestResourcesFromPlayer(targetName)
        deps.RefreshTargetResourceFrame()
    end

    handlers.HandleAddonMessage = function(prefix, message, sender)
        if prefix ~= deps.ADDON_PREFIX then return end

        local resKind, resourceProfileName, resourceTbl = HarfordSync.ReceiveResourceMessage(message)
        if resKind == "REQ" then
            if sender and sender ~= "" and not handlers.IsSelfSender(sender) then
                deps.SendResourceResponseTo(sender)
            end
            return
        end

        if resKind == "RES" and resourceTbl then
            deps.CacheRemoteResources(sender, resourceProfileName, resourceTbl)
            deps.RefreshTargetResourceFrame()
            if HarfordTurnOrderAPI and HarfordTurnOrderAPI.Refresh then
                HarfordTurnOrderAPI.Refresh()
            end
            return
        end

        local adjustKey, adjustDelta = HarfordSync.DeserializeResourceAdjustMessage(message)
        if adjustKey and adjustDelta then
            if deps.ApplyResourceDelta then
                deps.ApplyResourceDelta(adjustKey, adjustDelta, sender)
            end
            return
        end

        local profileName, profileTbl = HarfordSync.ReceiveDnDProfile(message)
        if profileName and profileTbl then
            deps.ApplyProfileTable(profileTbl, profileName)
            return
        end

        local resourceProfileNameCfg, resourceCfgTbl = HarfordSync.ReceiveResourceConfig(message)
        if resourceProfileNameCfg and resourceCfgTbl then
            deps.ApplyResourceConfigTable(resourceCfgTbl, resourceProfileNameCfg)
            local runtimeTbl = deps.BuildRuntimeFromConfig(resourceCfgTbl)
            deps.CacheRemoteResources(sender, resourceProfileNameCfg, runtimeTbl)
            deps.RefreshTargetResourceFrame()
            if HarfordTurnOrderAPI and HarfordTurnOrderAPI.Refresh then
                HarfordTurnOrderAPI.Refresh()
            end
            if sender and sender ~= "" and not handlers.IsSelfSender(sender) then
                deps.SendResourceResponseForProfileTo(resourceProfileNameCfg, sender)
            end
            return
        end

        deps.HandleRollSync(message)
    end

    return handlers
end
