HarfordAdminNPC = HarfordAdminNPC or {}

local API = HarfordAdminNPC

local function Print(message)
    print("|cffffff00[HarfordAdminNPC]|r " .. tostring(message or ""))
end

local function GetTargetName()
    if not UnitExists or not UnitExists("target") then
        return nil
    end

    return (GetUnitName and GetUnitName("target", true)) or UnitName("target")
end

local function GetTargetGuid()
    if not UnitGUID then
        return nil
    end

    return UnitGUID("target")
end

local function RequireTarget()
    local name = GetTargetName()
    if not name or name == "" then
        return nil, "No hay target seleccionado"
    end

    return name
end

local function ParsePositiveInteger(raw, label)
    local value = tonumber(raw)
    if not value then
        return nil, tostring(label or "valor") .. " debe ser numerico"
    end

    value = math.floor(value)
    if value <= 0 then
        return nil, tostring(label or "valor") .. " debe ser mayor que 0"
    end

    return value
end

local function PrintCallback(prefix)
    return function(success, messages)
        Print(prefix .. ": " .. (success and "OK" or "ERROR"))
        for _, line in ipairs(messages or {}) do
            Print(line)
        end
    end
end

function API.GetTargetSnapshot()
    local name = GetTargetName()
    return {
        exists = name ~= nil and name ~= "",
        name = name,
        guid = GetTargetGuid(),
        isPlayer = UnitIsPlayer and UnitIsPlayer("target") or false,
        isDead = UnitIsDead and UnitIsDead("target") or false,
        level = UnitLevel and UnitLevel("target") or nil,
    }
end

function API.PrintTarget()
    local target = API.GetTargetSnapshot()
    if not target.exists then
        Print("No hay target seleccionado")
        return false
    end

    Print("Target: " .. tostring(target.name))
    Print("GUID: " .. tostring(target.guid or "desconocido"))
    Print("Player: " .. tostring(target.isPlayer))
    Print("Dead: " .. tostring(target.isDead))
    Print("Level: " .. tostring(target.level or "desconocido"))
    return true
end

function API.PrintTRP3Target()
    if not HarfordTRP3 then
        Print("HarfordTRP3 no disponible")
        return false
    end

    local _, targetErr = RequireTarget()
    if targetErr then
        Print(targetErr)
        return false
    end

    if UnitIsPlayer and UnitIsPlayer("target") then
        local profile, err, unitID = HarfordTRP3.GetPlayerProfile("target")
        Print("TRP3 player unitID: " .. tostring(unitID or "desconocido"))
        if not profile then
            Print(err or "perfil TRP3 de jugador no disponible")
            return false
        end
        Print("TRP3 player profile: OK")
        return true
    end

    local profileID, profileIDErr, fullID, npcID, phaseID = HarfordTRP3.GetEpsilonNpcProfileID("target")
    Print("TRP3 NPC fullID: " .. tostring(fullID or "desconocido"))
    Print("TRP3 NPC npcID: " .. tostring(npcID or "desconocido"))
    Print("TRP3 NPC phaseID: " .. tostring(phaseID or "desconocida"))
    Print("TRP3 NPC profileID: " .. tostring(profileID or "nil"))
    if profileIDErr then
        Print(profileIDErr)
    end

    local text, err = HarfordTRP3.GetEpsilonNpcMainText("target")
    if not text then
        Print(err or "profile.data.TX no disponible")
        return false
    end

    local profile = HarfordTRP3.GetEpsilonNpcProfile("target")
    if profile and HarfordTRP3.GetProfileIcon then
        local icon, rawIcon = HarfordTRP3.GetProfileIcon(profile)
        Print("TRP3 icon elegido: " .. tostring(rawIcon or icon or "nil"))
    end

    local preview = tostring(text):gsub("[\r\n]+", " ")
    if #preview > 220 then
        preview = preview:sub(1, 220) .. "..."
    end
    Print("TRP3 TX chars: " .. tostring(#text))
    Print("TRP3 TX preview: " .. preview)
    return true
end

function API.ApplyAuraToTarget(spellId)
    local _, targetErr = RequireTarget()
    if targetErr then
        return false, targetErr
    end

    local safeSpellId, spellErr = ParsePositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    if not HarfordServerActions or not HarfordServerActions.ApplyAura then
        return false, "HarfordServerActions no disponible"
    end

    return HarfordServerActions.ApplyAura(safeSpellId, "target", { addonName = "HarfordAdmin" })
end

function API.RemoveAuraFromTarget(spellId)
    local _, targetErr = RequireTarget()
    if targetErr then
        return false, targetErr
    end

    local safeSpellId, spellErr = ParsePositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    if not HarfordServerActions or not HarfordServerActions.RemoveAura then
        return false, "HarfordServerActions no disponible"
    end

    return HarfordServerActions.RemoveAura(safeSpellId, "target", { addonName = "HarfordAdmin" })
end

function API.GetTargetInfo(callback)
    local _, targetErr = RequireTarget()
    if targetErr then
        if callback then callback(false, { targetErr }) end
        return false, targetErr
    end

    if not HarfordServerActions or not HarfordServerActions.SendRawDebug then
        local err = "HarfordServerActions.SendRawDebug no disponible"
        if callback then callback(false, { err }) end
        return false, err
    end

    return HarfordServerActions.SendRawDebug("npc info", callback, { addonName = "HarfordAdmin" })
end

local function ShowHelp()
    Print("comandos:")
    Print("/harfordadmin npc target")
    Print("/harfordadmin npc trp3")
    Print("/harfordadmin npc aura <spellId>")
    Print("/harfordadmin npc unaura <spellId>")
    Print("/harfordadmin npc info")
end

function API.HandleSlash(tokens)
    local mode = tostring(tokens[2] or ""):lower()

    if mode == "" or mode == "help" or mode == "?" then
        ShowHelp()
        return true
    end

    if mode == "target" then
        API.PrintTarget()
        return true
    end

    if mode == "trp3" or mode == "profile" or mode == "inspect" then
        API.PrintTRP3Target()
        return true
    end

    if mode == "aura" then
        local ok, err = API.ApplyAuraToTarget(tokens[3])
        if ok then
            Print("Aura enviada a target")
        else
            Print(err)
        end
        return true
    end

    if mode == "unaura" then
        local ok, err = API.RemoveAuraFromTarget(tokens[3])
        if ok then
            Print("Unaura enviada a target")
        else
            Print(err)
        end
        return true
    end

    if mode == "info" then
        API.GetTargetInfo(PrintCallback("npc info"))
        return true
    end

    ShowHelp()
    return true
end
