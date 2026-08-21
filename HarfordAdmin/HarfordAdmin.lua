-- Modo Admin opcional: incluir este archivo en el TOC para versión de maestros.
HarfordAdminAPI = HarfordAdminAPI or {}
HarfordAdminAPI.IS_ADMIN = true

local function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    HarfordChat.Print(table.concat(parts, " "))
end

local ADMIN_COMMANDS = {
    "/harfordadmin help",
    "/harfordadmin status",
    "/harfordadmin rep                           — Panel de administracion de reputaciones",
    "/harfordadmin loot [raid|party|whisper] [target]",
    "/harfordadmin lootclear [raid|party|whisper] [target]",
    "/harfordadmin enviarficha [NombrePJ] (si no pones nombre, usa target)",
    "/harfordadmin npc [target|aura|unaura|info]",
    "/harfordadmin listprof <Personaje>          — Lista flags de prof/exp de habilidades en el banco",
    "/harfordadmin setprof <Personaje> <Hab> prof|exp|ambos 1|0  — Edita flag en el banco",
}

local function PrintAdminCommands()
    print("|cffffff00Comandos de administracion disponibles:|r")
    for _, line in ipairs(ADMIN_COMMANDS) do
        print("|cffffff00 - " .. line .. "|r")
    end
end

local function PrintAdminStatus()
    if not HarfordEpsilonCommands or not HarfordEpsilonCommands.GetStatus then
        print("|cffff3333HarfordEpsilonCommands no disponible.|r")
        return
    end

    local status = HarfordEpsilonCommands.GetStatus("HarfordAdmin")
    local function yesno(value)
        return value and "|cff00ff00OK|r" or "|cffff3333NO|r"
    end

    print("|cffffff00Estado de dependencias de administracion:|r")
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
        return HarfordLootAPI.ClearRemoteLoot(channel, target, false)
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

-- Fuente de verdad en HarfordSync; no duplicar la lista aquí.
local SKILL_IDS = HarfordSync.PROF_SKILL_IDS

local function ResolveSkillID(input)
    if not input or input == "" then return nil end
    local low = input:lower()
    for _, id in ipairs(SKILL_IDS) do
        if id:lower() == low or id:lower():find(low, 1, true) == 1 then
            return id
        end
    end
    return nil
end

local function HandleListProfCommand(tokens)
    local characterName = tokens[2]
    if not characterName or characterName == "" then
        print("|cffff3333Uso: /harfordadmin listprof <Personaje>|r")
        return
    end
    local bank = _G.HarfordDnDProfileBank
    if not bank or not bank[characterName] then
        print("|cffff3333No existe ficha '" .. characterName .. "' en HarfordDnDProfileBank.|r")
        return
    end
    local tbl = bank[characterName]
    print("|cffffff00Prof/Exp de habilidades para '" .. characterName .. "':|r")
    for _, id in ipairs(SKILL_IDS) do
        local p = tbl["Hab_" .. id .. "_Prof"] or "0"
        local e = tbl["Hab_" .. id .. "_Exp"]  or "0"
        if p == "1" or e == "1" then
            local tag = (e == "1") and "|cff00ff00EXP|r" or "|cffffff00PROF|r"
            print("  " .. tag .. " " .. id)
        end
    end
    print("|cffffff00 (solo se muestran las activas)|r")
end

local function HandleSetProfCommand(tokens)
    -- /harfordadmin setprof <Personaje> <Habilidad> prof|exp|ambos 1|0
    local characterName = tokens[2]
    local habInput      = tokens[3]
    local tipo          = (tokens[4] or ""):lower()
    local valor         = tokens[5]

    if not characterName or characterName == "" or not habInput or habInput == "" then
        print("|cffff3333Uso: /harfordadmin setprof <Personaje> <Habilidad> prof|exp|ambos 1|0|r")
        print("|cffffff00 Habilidades:|r " .. table.concat(SKILL_IDS, ", "))
        return
    end

    local skillID = ResolveSkillID(habInput)
    if not skillID then
        print("|cffff3333Habilidad no reconocida: '" .. habInput .. "'|r")
        print("|cffffff00 Válidas:|r " .. table.concat(SKILL_IDS, ", "))
        return
    end

    if tipo ~= "prof" and tipo ~= "exp" and tipo ~= "ambos" then
        print("|cffff3333Tipo debe ser 'prof', 'exp' o 'ambos'.|r")
        return
    end

    local v = (valor == "1") and "1" or "0"

    local bank = _G.HarfordDnDProfileBank
    if not bank then
        _G.HarfordDnDProfileBank = {}
        bank = _G.HarfordDnDProfileBank
    end
    if not bank[characterName] then
        bank[characterName] = {}
        print("|cffffff00Perfil nuevo creado para '" .. characterName .. "'.|r")
    end

    local tbl = bank[characterName]
    if tipo == "prof" or tipo == "ambos" then
        tbl["Hab_" .. skillID .. "_Prof"] = v
    end
    if tipo == "exp" or tipo == "ambos" then
        tbl["Hab_" .. skillID .. "_Exp"] = v
        -- Experto implica también proficiente
        if v == "1" then tbl["Hab_" .. skillID .. "_Prof"] = "1" end
    end

    local tag = (v == "1") and "|cff00ff00activado|r" or "|cffff8800desactivado|r"
    print("|cff00ff00" .. skillID .. " " .. tipo .. " " .. tag .. " para '" .. characterName .. "' en el banco.|r")
    print("|cffffff00 Recuerda enviar la ficha con /harfordadmin enviarficha " .. characterName .. " para que surta efecto.|r")
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
        print("|cffff3333No existe ficha '" .. tostring(characterName) .. "' en HarfordDnDProfileBank.|r")
        return
    end

    if not IsCharacterOnline(characterName) then
        print("|cffff3333" .. tostring(characterName) .. " no está conectado o no es localizable para whisper.|r")
        return
    end

    local ok, err = SendDnDForCharacter(characterName, channel, target)
    if not ok then
        print("|cffff3333" .. tostring(err) .. "|r")
        return
    end

    print("|cff00ff00Ficha enviada para " .. characterName .. " via WHISPER a " .. tostring(target) .. "|r")
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
            print("|cffffff00'sendpj' está deprecado. Usa '/harfordadmin enviarficha'.|r")
        end
        HandleSendProfileCommand(t)
        return
    end

    if mode == "rep" or mode == "reputation" or mode == "reputacion" then
        if HarfordReputationAdmin and HarfordReputationAdmin.Toggle then
            HarfordReputationAdmin.Toggle()
        else
            print("|cffff3333HarfordReputationAdmin no disponible.|r")
        end
        return
    end

    if mode == "npc" then
        if HarfordAdminNPC and HarfordAdminNPC.HandleSlash then
            HarfordAdminNPC.HandleSlash(t)
        else
            print("|cffff3333HarfordAdminNPC no disponible.|r")
        end
        return
    end

    if mode == "listprof" then
        HandleListProfCommand(t)
        return
    end

    if mode == "setprof" then
        HandleSetProfCommand(t)
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
		print("|cff00ff00Configuración de loot enviada via " .. channel .. "|r")
		return
	end

	if mode == "lootclear" then
		local ok, err = SendLootClear(channel, target)
		if not ok then
			print("|cffff3333" .. tostring(err) .. "|r")
			return
		end
		print("|cff00ff00Limpieza remota de loot enviada via " .. channel .. "|r")
		return
	end

	PrintAdminCommands()
	return
end
