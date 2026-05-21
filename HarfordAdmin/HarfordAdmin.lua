-- Modo Admin opcional: incluir este archivo en el TOC para versión de maestros.
HarfordAdminAPI = HarfordAdminAPI or {}
HarfordAdminAPI.IS_ADMIN = true

local ADMIN_COMMANDS = {
    "/harfordadmin help",
    "/harfordadmin status",
    "/harfordadmin rep                           — Panel de administracion de reputaciones",
    "/harfordadmin loot [raid|party|whisper] [target]",
    "/harfordadmin lootclear [raid|party|whisper] [target]",
    "/harfordadmin enviarficha [NombrePJ] (si no pones nombre, usa target)",
    "/harfordadmin npc [target|aura|unaura|info]",
}

local function PrintAdminCommands()
    print("|cffffff00[HarfordAdmin] Comandos disponibles:|r")
    for _, line in ipairs(ADMIN_COMMANDS) do
        print("|cffffff00 - " .. line .. "|r")
    end
end

local function PrintAdminStatus()
    if not HarfordEpsilonCommands or not HarfordEpsilonCommands.GetStatus then
        print("|cffff3333[HarfordAdmin]|r HarfordEpsilonCommands no disponible.")
        return
    end

    local status = HarfordEpsilonCommands.GetStatus("HarfordAdmin")
    local function yesno(value)
        return value and "|cff00ff00OK|r" or "|cffff3333NO|r"
    end

    print("|cffffff00[HarfordAdmin] Estado de dependencias:|r")
    print("|cffffff00 - EpsilonLib.AddonCommands:|r " .. yesno(status.epsilonLib))
    print("|cffffff00 - Registro AddonCommands:|r " .. yesno(status.addonCommands))
    if status.addonCommandsError then
        print("|cffff3333   " .. tostring(status.addonCommandsError) .. "|r")
    end
    print("|cffffff00 - ARC.CMD/ARC.COMM:|r " .. yesno(status.arc))
end

local function ResolveChannel(raw)
    raw = (raw or ""):lower()
    if raw == "raid" then return "RAID" end
    if raw == "party" then return "PARTY" end
    if raw == "whisper" then return "WHISPER" end
    if raw == "" and HarfordSync and HarfordSync.BestChannel then
        return HarfordSync.BestChannel()
    end
    return nil
end

local function SendLoot(channel, target)
    if HarfordLootAPI and HarfordLootAPI.BroadcastConfig then
        HarfordLootAPI.BroadcastConfig(channel, target)
    end
end

local function SendLootClear(channel, target)
    if HarfordLootAPI and HarfordLootAPI.ClearRemoteLoot then
        return HarfordLootAPI.ClearRemoteLoot(channel, target, true)
    end
    return false, "HarfordLootAPI.ClearRemoteLoot no disponible"
end

local function SendDnDForCharacter(characterName, channel, target)
    if HarfordDnDAPI and HarfordDnDAPI.BroadcastConfigForPlayer then
        return HarfordDnDAPI.BroadcastConfigForPlayer(characterName, channel, target)
    end
    return false, "HarfordDnDAPI no disponible"
end

local function ResolveWhisperTargetForCharacter(characterName)
    local target = characterName
    local myName = UnitName("player")
    if characterName == myName and GetUnitName then
        local fullName = GetUnitName("player", true)
        if fullName and fullName ~= "" then
            target = fullName
        end
    end
    return target
end

local function IsCharacterOnline(name)
    if not name or name == "" then return false end

    local myName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)

    if name == myName or (myFullName and name == myFullName) then
        return true
    end

    if UnitExists("target") then
        local targetName = UnitName("target")
        local targetFullName = GetUnitName and GetUnitName("target", true)
        if (targetName and targetName == name) or (targetFullName and targetFullName == name) then
            return true
        end
    end

    if IsInRaid and IsInRaid() then
        local n = GetNumGroupMembers and GetNumGroupMembers() or 0
        for i = 1, n do
            local unit = "raid" .. i
            local unitName = UnitName(unit)
            local unitFullName = GetUnitName and GetUnitName(unit, true)
            if UnitIsConnected(unit) and ((unitName and unitName == name) or (unitFullName and unitFullName == name)) then
                return true
            end
        end
    elseif IsInGroup and IsInGroup() then
        local n = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for i = 1, n do
            local unit = "party" .. i
            local unitName = UnitName(unit)
            local unitFullName = GetUnitName and GetUnitName(unit, true)
            if UnitIsConnected(unit) and ((unitName and unitName == name) or (unitFullName and unitFullName == name)) then
                return true
            end
        end
    end

    local bn = BNGetNumFriends and BNGetNumFriends() or 0
    for i = 1, bn do
        local accountInfo = C_BattleNet and C_BattleNet.GetFriendAccountInfo and C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName == name and accountInfo.gameAccountInfo.isOnline then
            return true
        end
    end

    return false
end

local function HandleSendProfileCommand(tokens)
    local characterName = tokens[2]
    if not characterName or characterName == "" then
        characterName = UnitName("target")
    end
    if not characterName or characterName == "" then
        PrintAdminCommands()
        return
    end

    local channel = "WHISPER"
    local target = ResolveWhisperTargetForCharacter(characterName)

    local bank = _G.HarfordDnDProfileBank or {}
    if not bank[characterName] then
        print("|cffff3333[HarfordAdmin]|r No existe ficha '" .. tostring(characterName) .. "' en HarfordDnDProfileBank.")
        return
    end

    if not IsCharacterOnline(characterName) then
        print("|cffff3333[HarfordAdmin]|r " .. tostring(characterName) .. " no está conectado o no es localizable para whisper.")
        return
    end

    local ok, err = SendDnDForCharacter(characterName, channel, target)
    if not ok then
        print("|cffff3333[HarfordAdmin]|r " .. tostring(err))
        return
    end

    print("|cff00ff00[HarfordAdmin]|r Ficha enviada para " .. characterName .. " via WHISPER a " .. tostring(target))
end

SLASH_HARFORDADMIN1 = "/harfordadmin"
SlashCmdList["HARFORDADMIN"] = function(msg)
    local t = {}
    for token in string.gmatch((msg or ""), "%S+") do t[#t + 1] = token end
    local mode = (t[1] or ""):lower()

    if mode == "" or mode == "help" or mode == "?" then
        PrintAdminCommands()
        return
    end

    if mode == "status" then
        PrintAdminStatus()
        return
    end

    if mode == "enviarficha" or mode == "sendpj" then
        if mode == "sendpj" then
            print("|cffffff00[HarfordAdmin]|r 'sendpj' está deprecado. Usa '/harfordadmin enviarficha'.")
        end
        HandleSendProfileCommand(t)
        return
    end

    if mode == "rep" or mode == "reputation" or mode == "reputacion" then
        if HarfordReputationAdmin and HarfordReputationAdmin.Toggle then
            HarfordReputationAdmin.Toggle()
        else
            print("|cffff3333[HarfordAdmin]|r HarfordReputationAdmin no disponible.")
        end
        return
    end

    if mode == "npc" then
        if HarfordAdminNPC and HarfordAdminNPC.HandleSlash then
            HarfordAdminNPC.HandleSlash(t)
        else
            print("|cffff3333[HarfordAdmin]|r HarfordAdminNPC no disponible.")
        end
        return
    end

    local channel = ResolveChannel(t[2])
    local target = t[3]
    if not channel then
        PrintAdminCommands()
        return
    end

	if mode == "loot" then
		SendLoot(channel, target)
		print("|cff00ff00[HarfordAdmin]|r Configuración de loot enviada via " .. channel)
		return
	end

	if mode == "lootclear" then
		local ok, err = SendLootClear(channel, target)
		if not ok then
			print("|cffff3333[HarfordAdmin]|r " .. tostring(err))
			return
		end
		print("|cff00ff00[HarfordAdmin]|r Limpieza remota de loot enviada via " .. channel)
		return
	end

	PrintAdminCommands()
	return
end
