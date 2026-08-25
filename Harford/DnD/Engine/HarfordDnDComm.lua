HarfordDnDComm = HarfordDnDComm or {}

function HarfordDnDComm.CreateHandlers(deps)
    local handlers = {}

    local function IsTrustedEffectSender(sender)
        if handlers.IsSelfSender(sender) then return true end
        if HarfordClassColors and HarfordClassColors.FindUnitByName then
            return HarfordClassColors.FindUnitByName(sender) ~= nil
        end
        return false
    end

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
        local targetName = HarfordClassColors.UnitFullName("target")
        if not targetName or targetName == "" then return end

        local myName = HarfordClassColors.UnitFullName("player")
        if targetName == myName then
            deps.RefreshTargetResourceFrame()
            return
        end

        deps.RequestResourcesFromPlayer(targetName)
        -- Los estados se piden igual que los recursos. Difundirlos solo al aplicarse dejaba fuera
        -- tres casos que pasan siempre: no estar en el grupo en ese momento, recargar despues, o
        -- empezar a mirar a alguien mas tarde. El push se conserva para la inmediatez en combate.
        if HarfordDnDConditions and HarfordDnDConditions.RequestStatesFrom then
            HarfordDnDConditions.RequestStatesFrom("target")
        end
        deps.RefreshTargetResourceFrame()
    end

    -- Retorna true solo cuando se actualiza caché de recursos remotos → el caller
    -- puede refrescar los overlays de unitframes. No retorna true para REQ, tiradas
    -- ni sincronías de perfil que no cambian lo que muestran los overlays.
    handlers.HandleAddonMessage = function(prefix, message, sender, channel)
        if prefix ~= deps.ADDON_PREFIX then return false end

        if HarfordCharacterInspect and HarfordCharacterInspect.HandleAddonMessage
            and HarfordCharacterInspect.HandleAddonMessage(prefix, message, sender)
        then
            return false
        end

        if HarfordDnDConditions and HarfordDnDConditions.HandleMessage
            and HarfordDnDConditions.HandleMessage(message, sender)
        then
            return false
        end

        local armedFeatureId, armedProtectedGuid, armed = HarfordSync.DeserializePreparedAttackReaction
            and HarfordSync.DeserializePreparedAttackReaction(message)
        if armedFeatureId then
            if not IsTrustedEffectSender(sender) then return false end
            if deps.HandlePreparedAttackReactionState then
                deps.HandlePreparedAttackReactionState(sender, armedFeatureId, armedProtectedGuid, armed == true)
            end
            return false
        end

        local reactionRequestId, reactionTrigger, reactionProtectedGuid = HarfordSync.DeserializeAttackReactionRequest
            and HarfordSync.DeserializeAttackReactionRequest(message)
        if reactionRequestId then
            if not IsTrustedEffectSender(sender) then return false end
            local used = false
            if deps.HandleAttackReactionRequest then
                used = deps.HandleAttackReactionRequest(reactionRequestId, reactionTrigger, reactionProtectedGuid, sender) == true
            end
            if HarfordSync.SendAttackReactionResult then
                HarfordSync.SendAttackReactionResult(deps.ADDON_PREFIX, sender, reactionRequestId, used)
            end
            return false
        end

        local reactionResultId, reactionUsed = HarfordSync.DeserializeAttackReactionResult
            and HarfordSync.DeserializeAttackReactionResult(message)
        if reactionResultId then
            if not IsTrustedEffectSender(sender) then return false end
            if deps.HandleAttackReactionResult then
                deps.HandleAttackReactionResult(reactionResultId, reactionUsed == true, sender)
            end
            return false
        end

        if HarfordDnDArea and HarfordDnDArea.HandleRequest
            and HarfordDnDArea.HandleRequest(message, sender, channel)
        then
            return false
        end
        if HarfordDnDArea and HarfordDnDArea.HandleResult
            and HarfordDnDArea.HandleResult(message, sender)
        then
            return false
        end

        local resKind, resourceProfileName, resourceTbl = HarfordSync.ReceiveResourceMessage(message)
        if resKind == "REQ" then
            if sender and sender ~= "" and not handlers.IsSelfSender(sender) then
                deps.SendResourceResponseTo(sender)
            end
            return false
        end

        if resKind == "RES" and resourceTbl then
            deps.CacheRemoteResources(sender, resourceProfileName, resourceTbl)
            if HarfordCharacterInspect and HarfordCharacterInspect.NoteResources then
                HarfordCharacterInspect.NoteResources(sender, resourceProfileName, resourceTbl)
            end
            deps.RefreshTargetResourceFrame()
            if HarfordTurnOrderAPI and HarfordTurnOrderAPI.Refresh then
                HarfordTurnOrderAPI.Refresh()
            end
            return true  -- caché actualizada → refrescar overlays
        end

        -- Dano BRUTO: lo resuelve ESTE cliente, que es la victima. Mismo gate de remitente que
        -- RADJ, porque aplica un efecto real sobre nosotros.
        local dmgComponents, dmgCrit, dmgMagico = HarfordSync.DeserializeDamage and HarfordSync.DeserializeDamage(message)
        if dmgComponents then
            if not IsTrustedEffectSender(sender) then return false end
            if deps.ApplyIncomingDamage then deps.ApplyIncomingDamage(dmgComponents, dmgCrit, sender, dmgMagico) end
            return true  -- cambia la vida -> refrescar overlays
        end

        local adjustKey, adjustDelta = HarfordSync.DeserializeResourceAdjustMessage(message)
        if adjustKey and adjustDelta then
            if not IsTrustedEffectSender(sender) then return false end
            if deps.ApplyResourceDelta then
                deps.ApplyResourceDelta(adjustKey, adjustDelta, sender)
            end
            return true  -- recurso ajustado → refrescar overlays
        end

        -- Señal de aura (Desarme u otra maniobra): el objetivo se aplica `.au <id> self`.
        -- Aplica un efecto real (comando de servidor sin whitelist) -> exige el mismo gate de sender
        -- que DOAPPLYAURA/RADJ: solo propio jugador, unidad visible o miembro de grupo/raid.
        local auraSignalId = HarfordSync.DeserializeAuraSignal and HarfordSync.DeserializeAuraSignal(message)
        if auraSignalId then
            if not IsTrustedEffectSender(sender) then return false end
            if deps.ApplyAuraSelf then deps.ApplyAuraSelf(auraSignalId, sender) end
            return false
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

        -- DNDCLASS (sync normal): import a persistencia. La inspeccion usa DNDINSCLASS
        -- y la consume HarfordCharacterInspect ANTES de llegar aqui; el flag isInspect
        -- es defensa por si ese modulo no estuviera cargado: nunca importar inspeccion.
        local classProfileName, classData, classInspect = HarfordSync.DeserializeDnDClassProgression(message)
        if classProfileName and classData then
            if classInspect then
                if HarfordCharacterInspect and HarfordCharacterInspect.NoteProgression then
                    HarfordCharacterInspect.NoteProgression(classProfileName, classData)
                end
            elseif deps.ApplyClassProgression then
                deps.ApplyClassProgression(classProfileName, classData)
            end
            return false
        end

        if HarfordSync.ReceiveDnDClassProgressionChunk then
            local cpn, ccd, cInspect = HarfordSync.ReceiveDnDClassProgressionChunk(message, sender)
            if cpn and ccd then
                if cInspect then
                    if HarfordCharacterInspect and HarfordCharacterInspect.NoteProgression then
                        HarfordCharacterInspect.NoteProgression(cpn, ccd)
                    end
                elseif deps.ApplyClassProgression then
                    deps.ApplyClassProgression(cpn, ccd)
                end
                return false
            end
        end

        local equipmentProfileName, equipmentData, equipInspect = HarfordSync.DeserializeDnDEquipment
            and HarfordSync.DeserializeDnDEquipment(message)
        if equipmentProfileName and equipmentData then
            if equipInspect then
                if HarfordCharacterInspect and HarfordCharacterInspect.NoteEquipment then
                    HarfordCharacterInspect.NoteEquipment(equipmentProfileName, equipmentData)
                end
            elseif deps.ApplyEquipment then
                deps.ApplyEquipment(equipmentProfileName, equipmentData)
            end
            return false
        end

        if HarfordSync.ReceiveDnDEquipmentChunk then
            local epn, ecd, eInspect = HarfordSync.ReceiveDnDEquipmentChunk(message, sender)
            if epn and ecd then
                if eInspect then
                    if HarfordCharacterInspect and HarfordCharacterInspect.NoteEquipment then
                        HarfordCharacterInspect.NoteEquipment(epn, ecd)
                    end
                elseif deps.ApplyEquipment then
                    deps.ApplyEquipment(epn, ecd)
                end
                return false
            end
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
            if not IsTrustedEffectSender(sender) then return false end
            if deps.HandleApplyAuraSelf then
                deps.HandleApplyAuraSelf(selfAuraId)
            end
            return false
        end

        -- DODEFENSE: el atacante fallo contra nosotros -> ejecutar nuestra defensa
        if HarfordSync.IsDefenseMessage and HarfordSync.IsDefenseMessage(message) then
            if not IsTrustedEffectSender(sender) then return false end
            if deps.HandleDefense then deps.HandleDefense() end
            return false
        end

        -- DOWOUND: el atacante nos golpeo -> animacion de herida (33/34)
        if HarfordSync.DeserializeWound then
            local isWound, woundCrit = HarfordSync.DeserializeWound(message)
            if isWound then
                if not IsTrustedEffectSender(sender) then return false end
                if deps.HandleWound then deps.HandleWound(woundCrit) end
                return false
            end
        end

        -- DOSAVE: el atacante solicita una salvacion, pero la tira y anuncia el
        -- propio cliente defensor para usar sus datos reales de ficha.
        if HarfordSync.DeserializeRequestedSave then
            local saveAbility, saveDC, saveOutcome, saveAura, saveCondition, saveDuration, saveTurns, saveSourceGuid, saveSourceName, saveExtraDice, saveExtraType, saveSkill =
                HarfordSync.DeserializeRequestedSave(message)
            if saveAbility then
                if not IsTrustedEffectSender(sender) then return false end
                if deps.HandleRequestedSave then
                    deps.HandleRequestedSave(saveAbility, saveDC, saveOutcome, saveAura, sender,
                        saveCondition, saveDuration, saveTurns, saveSourceGuid, saveSourceName, saveExtraDice, saveExtraType, saveSkill)
                end
                return false
            end
        end

        if HarfordSync.DeserializeRequestedSaveResult then
            local saved = HarfordSync.DeserializeRequestedSaveResult(message)
            if saved ~= nil then
                if not IsTrustedEffectSender(sender) then return false end
                if deps.HandleRequestedSaveResult then deps.HandleRequestedSaveResult(sender, saved) end
                return false
            end
        end

        deps.HandleRollSync(message)
        return false
    end

    return handlers
end
