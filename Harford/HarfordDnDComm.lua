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

    -- Retorna true solo cuando se actualiza caché de recursos remotos → el caller
    -- puede refrescar los overlays de unitframes. No retorna true para REQ, tiradas
    -- ni sincronías de perfil que no cambian lo que muestran los overlays.
    handlers.HandleAddonMessage = function(prefix, message, sender)
        if prefix ~= deps.ADDON_PREFIX then return false end

        local resKind, resourceProfileName, resourceTbl = HarfordSync.ReceiveResourceMessage(message)
        if resKind == "REQ" then
            if sender and sender ~= "" and not handlers.IsSelfSender(sender) then
                deps.SendResourceResponseTo(sender)
            end
            return false
        end

        if resKind == "RES" and resourceTbl then
            deps.CacheRemoteResources(sender, resourceProfileName, resourceTbl)
            deps.RefreshTargetResourceFrame()
            if HarfordTurnOrderAPI and HarfordTurnOrderAPI.Refresh then
                HarfordTurnOrderAPI.Refresh()
            end
            return true  -- caché actualizada → refrescar overlays
        end

        local adjustKey, adjustDelta = HarfordSync.DeserializeResourceAdjustMessage(message)
        if adjustKey and adjustDelta then
            if deps.ApplyResourceDelta then
                deps.ApplyResourceDelta(adjustKey, adjustDelta, sender)
            end
            return true  -- recurso ajustado → refrescar overlays
        end

        local profileName, profileTbl = HarfordSync.ReceiveDnDProfile(message)
        if profileName and profileTbl then
            deps.ApplyProfileTable(profileTbl, profileName)
            return false  -- perfil DnD: no afecta overlays de recursos directamente
        end

        -- DNDPROF: flags de proficiencia/expertía de habilidades (mensaje compacto).
        -- Llega justo después de DNDCFG; se fusiona en el perfil sin reemplazarlo.
        local profProfileName, profTbl = HarfordSync.DeserializeDnDProfFlags(message)
        if profProfileName and profTbl then
            deps.MergeProfFlagsTable(profTbl, profProfileName)
            return false
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
            return true  -- caché de config actualizada → refrescar overlays
        end

        -- ANIMFLG: el emisor nos informa de su flag de animaciones → cachear
        local animEnabled = HarfordSync.DeserializeAnimFlag(message)
        if animEnabled ~= nil then
            local short = sender and (Ambiguate and Ambiguate(sender, "short") or sender:match("^[^%-]+") or sender)
            if short and short ~= "" then
                HarfordDnDResources.AnimFlagCache[sender] = animEnabled
                HarfordDnDResources.AnimFlagCache[short]  = animEnabled
            end
            return false
        end

        -- DOAPPLYAURA: el DM nos pide que nos apliquemos una aura a nosotros mismos
        local selfAuraId = HarfordSync.DeserializeApplyAuraSelf(message)
        if selfAuraId and selfAuraId > 0 then
            if deps.HandleApplyAuraSelf then
                deps.HandleApplyAuraSelf(selfAuraId)
            end
            return false
        end

        deps.HandleRollSync(message)
        return false
    end

    return handlers
end
