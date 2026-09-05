HarfordAdminNPC = HarfordAdminNPC or {}

local API = HarfordAdminNPC

local function Print(message)
    HarfordChat.Print(message)
end

local function GetTargetName()
    if not UnitExists or not UnitExists("target") then
        return nil
    end

    return HarfordClassColors.UnitFullName("target")
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

local function ParseNpcInfoPosition(messages)
    local text = table.concat(messages or {}, "\n")
    text = tostring(text or ""):gsub(",", ".")
    -- Separador entre coordenadas: `[^%d%-]+` (NO `%D+`), para que un `-` inicial de la siguiente
    -- coordenada lo capture su propio `-?` y no se pierda el signo negativo.
    local x, y, z = text:match("[Xx]%s*[:=]%s*(-?%d+%.?%d*)[^%d%-]+[Yy]%s*[:=]%s*(-?%d+%.?%d*)[^%d%-]+[Zz]%s*[:=]%s*(-?%d+%.?%d*)")
    if not x then
        x, y, z = text:match("[Pp]os[^%d%-]*(-?%d+%.?%d*)[^%d%-]+(-?%d+%.?%d*)[^%d%-]+(-?%d+%.?%d*)")
    end
    if not x then
        x, y, z = text:match("(-?%d+%.%d+)[^%d%-]+(-?%d+%.%d+)[^%d%-]+(-?%d+%.%d+)")
    end
    -- Fallback a solo X/Y: Epsilon puede omitir Z (documentado: z=nil). Se asume z=0.
    if not x then
        x, y = text:match("[Xx]%s*[:=]%s*(-?%d+%.?%d*)[^%d%-]+[Yy]%s*[:=]%s*(-?%d+%.?%d*)")
    end
    if not x then
        x, y = text:match("(-?%d+%.%d+)[^%d%-]+(-?%d+%.%d+)")
    end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y then return nil end   -- Z opcional
    z = z or 0
    return { x = x, y = y, z = z, contextId = "" }
end

local function RequestNpcInfoPosition(expectedGuid, callback)
    if not (expectedGuid and expectedGuid ~= "") then
        if callback then callback(false, nil, "GUID NPC invalido") end
        return false, "GUID NPC invalido"
    end
    if not UnitExists or not UnitExists("target") or (UnitIsPlayer and UnitIsPlayer("target")) then
        if callback then callback(false, nil, "Selecciona el NPC origen del area") end
        return false, "Selecciona el NPC origen del area"
    end
    if UnitGUID and UnitGUID("target") ~= expectedGuid then
        if callback then callback(false, nil, "El target ya no coincide con el NPC origen") end
        return false, "El target ya no coincide con el NPC origen"
    end
    if not (HarfordEpsilonCommands and HarfordEpsilonCommands.Send) then
        if callback then callback(false, nil, "HarfordEpsilonCommands no disponible") end
        return false, "HarfordEpsilonCommands no disponible"
    end
    return HarfordEpsilonCommands.Send("npc info", {
        addonName = "HarfordAdmin",
        forceEpsilon = true,
        showMessages = false,
        callback = function(success, messages)
            if not success then
                if callback then callback(false, nil, "npc info no respondio correctamente") end
                return
            end
            if UnitGUID and UnitGUID("target") ~= expectedGuid then
                if callback then callback(false, nil, "El target cambio antes de leer la posicion NPC") end
                return
            end
            local pos = ParseNpcInfoPosition(messages)
            if not pos then
                if callback then callback(false, nil, "No se pudo parsear posicion de npc info") end
                return
            end
            -- `.npc info` confirma X/Y/Z pero no devuelve el mapa. El NPC sigue
            -- seleccionado, asi que comparte el mapa actual del jugador.
            local mapId
            if C_Epsilon and C_Epsilon.GetPosition then
                local okPos, _, _, _, value = pcall(C_Epsilon.GetPosition)
                if okPos then mapId = value end
            end
            if HarfordDnDRange and HarfordDnDRange.BuildPositionContext then
                pos.contextId = HarfordDnDRange.BuildPositionContext(mapId)
            end
            pos.guid = expectedGuid
            pos.name = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("target"))
                or GetTargetName() or "NPC"
            if callback then callback(true, pos) end
        end,
    })
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

-- Para NPCs (target seleccionado en juego). Usa SetNpcAura ("npc set aura ID"),
-- no la firma vieja ApplyAura(id, "target", opts) que ya no existe.
function API.ApplyAuraToTarget(spellId)
    local _, targetErr = RequireTarget()
    if targetErr then
        return false, targetErr
    end

    local safeSpellId, spellErr = ParsePositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    if not HarfordServerActions or not HarfordServerActions.SetNpcAura then
        return false, "HarfordServerActions.SetNpcAura no disponible"
    end

    return HarfordServerActions.SetNpcAura(safeSpellId, { addonName = "HarfordAdmin" })
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

    if not HarfordServerActions or not HarfordServerActions.RemoveNpcAura then
        return false, "HarfordServerActions.RemoveNpcAura no disponible"
    end

    return HarfordServerActions.RemoveNpcAura(safeSpellId, { addonName = "HarfordAdmin" })
end

function API.SetAuraOnTarget(spellId)
    local _, targetErr = RequireTarget()
    if targetErr then
        return false, targetErr
    end

    if UnitIsPlayer and UnitIsPlayer("target") then
        return false, "npc set aura solo debe usarse sobre NPC target"
    end

    local safeSpellId, spellErr = ParsePositiveInteger(spellId, "spellId")
    if not safeSpellId then
        return false, spellErr
    end

    if not HarfordServerActions or not HarfordServerActions.SetNpcAura then
        return false, "HarfordServerActions.SetNpcAura no disponible"
    end

    return HarfordServerActions.SetNpcAura(safeSpellId, { addonName = "HarfordAdmin" })
end

function API.SetLootAuraOnTarget()
    return API.SetAuraOnTarget(140172)
end

do
local npcSheetContext = nil

local NPC_STAT_TO_SHEET = {
    strength = "Fuerza",
    dexterity = "Destreza",
    constitution = "Constitucion",
    intelligence = "Inteligencia",
    wisdom = "Sabiduria",
    charisma = "Carisma",
}

local NPC_SKILL_TO_SHEET = {
    acrobacias = "Acrobacias",
    atletismo = "Atletismo",
    arcano = "Arcano",
    conocimientoarcano = "Arcano",
    engano = "Engano",
    historia = "Historia",
    interpretacion = "Interpretacion",
    intimidacion = "Intimidacion",
    investigacion = "Investigacion",
    juegodemanos = "JuegoManos",
    medicina = "Medicina",
    naturaleza = "Naturaleza",
    percepcion = "Percepcion",
    perspicacia = "Perspicacia",
    persuasion = "Persuasion",
    religion = "Religion",
    sigilo = "Sigilo",
    supervivencia = "Supervivencia",
    animales = "Animales",
    tratoconanimales = "Animales",
    manejodeanimales = "Animales",
}

local function CreateEmptyNpcSheetOverrides()
    local overrides = {
        BonusCompetencia = "0",
        BonoSituacional = "0",
        ModIniciativa = "0",
        AtributoConjuro = "Inteligencia",
    }

    for _, sheetKey in pairs(NPC_STAT_TO_SHEET) do
        overrides[sheetKey] = "10"
        overrides["Salv_" .. sheetKey] = "0"
    end

    for _, sheetKey in pairs(NPC_SKILL_TO_SHEET) do
        overrides["Hab_" .. sheetKey .. "_Prof"] = "0"
        overrides["Hab_" .. sheetKey .. "_Exp"] = "0"
    end

    return overrides
end

local function NormalizeNpcSkillName(value)
    value = HarfordClassColors.StripAccents(value):lower()
    return (value:gsub("[^%w]", ""))  -- parentesis: gsub devuelve 2 valores
end

local function GetReactionTitleColor(unit)
    local reaction = UnitReaction and UnitReaction(unit, "player")
    if reaction and reaction <= 3 then
        return { 1, 0.2, 0.2 }
    elseif reaction == 4 then
        return { 1, 1, 0 }
    elseif reaction then
        return { 0.2, 1, 0.2 }
    end
    return { 1, 0.82, 0 }
end

local function GetReactionTitleColorHex(unit)
    local reaction = UnitReaction and UnitReaction(unit, "player")
    if reaction and reaction <= 3 then
        return "ff3333"
    elseif reaction == 4 then
        return "ffff00"
    elseif reaction then
        return "33ff33"
    end
    return "ffd100"
end

local function GetUnitSelectionColorHex(unit)
    if not UnitSelectionColor then return nil end
    local r, g, b = UnitSelectionColor(unit, true)
    if not r or not g or not b then return nil end
    return ("%02x%02x%02x"):format(
        math.floor(math.max(0, math.min(1, r)) * 255 + 0.5),
        math.floor(math.max(0, math.min(1, g)) * 255 + 0.5),
        math.floor(math.max(0, math.min(1, b)) * 255 + 0.5)
    )
end

local function HexColorToRGB(hex)
    hex = tostring(hex or ""):gsub("|cff", ""):gsub("#", ""):match("^(%x%x%x%x%x%x)")
    if not hex then return nil end
    return {
        (tonumber(hex:sub(1, 2), 16) or 255) / 255,
        (tonumber(hex:sub(3, 4), 16) or 209) / 255,
        (tonumber(hex:sub(5, 6), 16) or 0) / 255,
    }
end

local function GetNpcNameColor(unit)
    local trpHex = HarfordTRP3 and HarfordTRP3.GetUnitNameColor and HarfordTRP3.GetUnitNameColor(unit)
    local hex = trpHex or GetUnitSelectionColorHex(unit) or GetReactionTitleColorHex(unit)
    return hex, HexColorToRGB(hex) or GetReactionTitleColor(unit)
end

local function GetNpcSpellProficiencyBonus(unit, approximateLevel)
    local level = tonumber(approximateLevel)
    if not level and UnitLevel then
        level = tonumber(UnitLevel(unit))
    end
    if not level or level < 1 then level = 1 end

    if level >= 29 then return 9 end
    if level >= 25 then return 8 end
    if level >= 21 then return 7 end
    if level >= 17 then return 6 end
    if level >= 13 then return 5 end
    if level >= 9 then return 4 end
    if level >= 5 then return 3 end
    return 2
end

local function NormalizeAttackText(text)
    text = tostring(text or ""):gsub("{[^}]-}", ""):gsub("\r", "")
    return HarfordClassColors.StripAccents(text):lower()
end

local function GetNpcActionHyperlink(state)
    if not (HarfordTRP3 and HarfordTRP3.CreateGlanceLink and HarfordTRP3.GetLastGlanceLinkInfo) then
        return nil
    end

    local link = HarfordTRP3.CreateGlanceLink({
        AC = true,
        TI = state.title,
        TX = state.text,
        IC = state.rawIcon,
    })
    if not link then
        return nil
    end

    local info = HarfordTRP3.GetLastGlanceLinkInfo()
    return info and info.hyperlink or nil
end

local function ParseDamageComponents(impactText)
    local components = {}
    local text = tostring(impactText or "")
    local cursor = 1

    while true do
        local componentStart = text:find("%d+d%d+", cursor)
        if not componentStart then
            break
        end
        local nextStart = text:find("%d+d%d+", componentStart + 1)
        local segment = text:sub(componentStart, nextStart and (nextStart - 1) or #text)
        segment = segment:gsub("%s*%+%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")

        local dice = segment:match("^(%d+d%d+)")
        local remainder = segment:gsub("^%d+d%d+%s*", "", 1)
        local bonusText = remainder:match("^([+-]%s*%d+)")
        local bonus = bonusText and tonumber((bonusText:gsub("%s", ""))) or 0
        if bonusText then
            remainder = remainder:sub(#bonusText + 1)
        end
        local damageType = remainder:gsub("^%s+", ""):gsub("%s+$", "")
        damageType = damageType:gsub("^de%s+dano%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")

        if dice then
            components[#components + 1] = {
                damageDice = dice,
                damageBonus = bonus,
                damageType = damageType ~= "" and damageType or nil,
            }
        end

        if not nextStart then
            break
        end
        cursor = nextStart
    end

    return components
end

local CONDITION_ABILITY = {
    fue = "Fuerza", fuerza = "Fuerza", des = "Destreza", destreza = "Destreza",
    con = "Constitucion", cons = "Constitucion", constitucion = "Constitucion",
    int = "Inteligencia", inteligencia = "Inteligencia", sab = "Sabiduria", sabiduria = "Sabiduria",
    car = "Carisma", carisma = "Carisma",
}

local function ParseConditionMetadata(clean, conditionId)
    if not conditionId then return "manual", 0, nil, 0, false end
    local persist = clean:match("persistencia:%s*(si)") == "si"
    local finalAbility, finalDC = clean:match("salvacion final:%s*([%a]+)%s+cd%s*(%d+)")
    if finalAbility and finalDC then
        local ability = CONDITION_ABILITY[finalAbility]
        if not ability then return "invalid", 0, nil, 0, persist end
        return "save_at_turn_end", 0, ability, tonumber(finalDC) or 0, persist
    end

    local text = clean:match("duracion:%s*([^%.\n]+)")
    if not text then return "manual", 0, nil, 0, persist end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    local rounds = tonumber(text:match("^(%d+)%s+rondas?$"))
    if rounds then return "rounds", rounds, nil, 0, persist end
    if text == "manual" then return "manual", 0, nil, 0, persist end

    local nextTurn = text:find("siguiente turno", 1, true) and 2 or 1
    if text:find("fin", 1, true) and text:find("fuente", 1, true) then
        return "source_turn_end", nextTurn, nil, 0, persist
    elseif text:find("inicio", 1, true) and text:find("fuente", 1, true) then
        return "source_turn_start", nextTurn, nil, 0, persist
    elseif text:find("fin", 1, true) and text:find("objetivo", 1, true) then
        return "target_turn_end", nextTurn, nil, 0, persist
    elseif text:find("inicio", 1, true) and text:find("objetivo", 1, true) then
        return "target_turn_start", nextTurn, nil, 0, persist
    end
    return "invalid", 0, nil, 0, persist
end

local function ParseNpcActionState(state)
    local clean = NormalizeAttackText(state.text)
    local bonusText = clean:match("([+-]%s*%d+)%s+al%s+ataque")
    local impactText = clean:match("impacto:%s*([^%.]+)")
    local damageComponents = ParseDamageComponents(impactText)
    local firstDamage = damageComponents[1]
    local attackRange = clean:find("ataque cuerpo a cuerpo", 1, true) and "melee" or "ranged"
    local conditionText = clean:match("estado:%s*([^%.\n]+)")
    local conditionId = conditionText and HarfordDnDConditions and HarfordDnDConditions.FindIdByText
        and HarfordDnDConditions.FindIdByText(conditionText:gsub("^%s+", ""):gsub("%s+$", "")) or nil
    local conditionDuration, conditionTurns, conditionSaveAbility, conditionSaveDC, conditionPersist =
        ParseConditionMetadata(clean, conditionId)

    local area
    local areaText = clean:match("area:%s*([^%.\n]+)")
    if areaText then
        areaText = areaText:gsub("^%s+", ""):gsub("%s+$", "")
        local shape = areaText:match("^cono%s+") and "cone"
            or (areaText:match("^radio%s+") or areaText:match("^esfera%s+")) and "sphere"
            or areaText:match("^linea%s+") and "line"
            or (areaText:match("^cubo%s+") or areaText:match("^cuadrado%s+")) and "square"
            or areaText:match("^rectangulo%s+") and "rectangle"
            or "other"
        local sizeText = areaText
        for _, prefix in ipairs({ "cono", "radio", "esfera", "linea", "cubo", "cuadrado", "rectangulo" }) do
            if sizeText:find(prefix .. " ", 1, true) == 1 then
                sizeText = sizeText:sub(#prefix + 2)
                break
            end
        end
        local rawSaveAbility, saveDC = clean:match("salvacion:%s*([%a]+)%s+cd%s*(%d+)")
        local saveAbility = rawSaveAbility and CONDITION_ABILITY[rawSaveAbility] or nil
        if rawSaveAbility and not saveAbility and HarfordChat and HarfordChat.Print then
            HarfordChat.Print("Aviso: caracteristica de salvacion '" .. tostring(rawSaveAbility)
                .. "' no reconocida en el estado del NPC; el area no se resolvera como salvacion.")
        end
        local successText = clean:match("exito:%s*(mitad)") or clean:match("exito:%s*(niega)")
        -- Si hay clausula de salvacion (aunque la caracteristica no se reconozca) NO degradar a
        -- ataque en silencio: un AoE de salvacion mal escrito no debe convertirse en tirada de ataque.
        local resolution = (saveAbility and saveDC and successText and "save")
            or (not rawSaveAbility and bonusText and "attack")
            or nil
        if resolution and (firstDamage or conditionId) then
            area = {
                shape = shape,
                sizeText = sizeText,
                resolution = resolution,
                saveAbility = saveAbility,
                dc = tonumber(saveDC),
                success = successText == "mitad" and "half" or "none",
                attackBonus = bonusText and tonumber((bonusText:gsub("%s", ""))) or nil,
                attackRange = attackRange,
                damageComponents = firstDamage and damageComponents or {},
                conditionId = conditionId,
                conditionDuration = conditionDuration,
                conditionTurns = conditionTurns,
                conditionSaveAbility = conditionSaveAbility,
                conditionSaveDC = conditionSaveDC,
                conditionPersist = conditionPersist,
            }
        end
    end

    return {
        title = state.title ~= "" and state.title or ("Estado " .. tostring(state.index)),
        icon = state.icon,
        text = HarfordTRP3.ConvertTRP3Markup and HarfordTRP3.ConvertTRP3Markup(state.text) or state.text,
        attackBonus = bonusText and tonumber((bonusText:gsub("%s", ""))) or nil,
        damageDice = firstDamage and firstDamage.damageDice or nil,
        damageBonus = firstDamage and firstDamage.damageBonus or 0,
        damageType = firstDamage and firstDamage.damageType or nil,
        damageComponents = damageComponents,
        conditionId = conditionId,
        conditionDuration = conditionDuration,
        conditionTurns = conditionTurns,
        conditionSaveAbility = conditionSaveAbility,
        conditionSaveDC = conditionSaveDC,
        conditionPersist = conditionPersist,
        attackRange = attackRange,
        area = area,
        sourceIndex = state.index,
        hyperlink = GetNpcActionHyperlink(state),
    }
end

local function BuildNpcActions(unit)
    if not (HarfordTRP3 and HarfordTRP3.GetEpsilonNpcProfile and HarfordTRP3.GetProfileStates) then
        return {}
    end
    local profile = HarfordTRP3.GetEpsilonNpcProfile(unit)
    local actions = {}
    for _, state in ipairs((profile and HarfordTRP3.GetProfileStates(profile)) or {}) do
        actions[#actions + 1] = ParseNpcActionState(state)
    end
    return actions
end

local function GetTurnArmorClassForGuid(guid)
    if guid and HarfordTurnOrderAPI and HarfordTurnOrderAPI.GetArmorClassForGuid then
        local armorClass = HarfordTurnOrderAPI.GetArmorClassForGuid(guid)
        if armorClass and armorClass > 0 then return armorClass end
    end
end

local function GetNpcMovementMeters(parsed)
    local raw = parsed and parsed.speed
    if type(raw) == "table" then raw = raw.walk or raw.ground or raw[1] end
    local text = tostring(raw or "")
    -- Leer la unidad INMEDIATA de la primera cifra. Buscar "pie" en toda la
    -- descripcion convertia "9 m a pie" en 2,7432 m y mezclaba caminar con vuelo.
    local cifra, unidad = text:lower():match("(%d+[,.]?%d*)%s*([a-z]*)")
    local value = cifra and tonumber((cifra:gsub(",", ".")))
    if not value then return nil end
    if unidad == "pie" or unidad == "pies" or unidad == "ft"
        or unidad == "foot" or unidad == "feet" then
        return value * 0.3048
    end
    return value
end

function API.UpdateNpcSheetArmorClass(armorClass, guid)
    guid = tostring(guid or (UnitGUID and UnitGUID("target")) or "")
    if guid == "" then return false end
    if HarfordTurnOrderAPI and HarfordTurnOrderAPI.SetArmorClassForGuid then
        return HarfordTurnOrderAPI.SetArmorClassForGuid(guid, armorClass)
    end
    return false, "HarfordTurnOrderAPI.SetArmorClassForGuid no disponible"
end

function API.BuildDnDSheetContext(unit, opts)
    unit = unit or "target"
    opts = opts or {}
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        return nil, "Modo NPC requiere HarfordAdmin y .ph dm activo"
    end
    if not UnitExists(unit) or (UnitIsPlayer and UnitIsPlayer(unit)) then
        return nil, "Selecciona un NPC para cargar su ficha"
    end
    if not (HarfordTRP3 and HarfordTRP3.GetNPCStatBlock and HarfordTRP3.GetNPCDisplayInfo) then
        return nil, "HarfordTRP3 no disponible"
    end

    local parsed = HarfordTRP3.GetNPCStatBlock(unit)
    local name, raidIcon = HarfordTRP3.GetNPCDisplayInfo(unit)
    local prefix = raidIcon and (raidIcon .. " ") or ""
    -- Un NPC no hereda competencia, proficiencias ni atributos de la ficha
    -- del jugador. Partimos de cero y solo cargamos lo declarado en TRP3.
    local overrides = CreateEmptyNpcSheetOverrides()

    if parsed and parsed.stats then
        for statKey, sheetKey in pairs(NPC_STAT_TO_SHEET) do
            local stat = parsed.stats[statKey]
            if stat then
                overrides[sheetKey] = tostring(stat.score or stat)
            end
        end
        for statKey, bonus in pairs(parsed.savingThrows or {}) do
            local sheetKey = NPC_STAT_TO_SHEET[statKey]
            if sheetKey then
                overrides["Salv_" .. sheetKey] = "1"
                overrides["Context_Salv_" .. sheetKey .. "_Bonus"] = tostring(bonus)
            end
        end
        for _, skill in ipairs(parsed.skills or {}) do
            local sheetKey = NPC_SKILL_TO_SHEET[NormalizeNpcSkillName(skill.name)]
            if sheetKey and skill.bonus ~= nil then
                overrides["Context_Hab_" .. sheetKey .. "_Bonus"] = tostring(skill.bonus)
            end
        end
    end

    local npcName = name or "NPC"
    local sourceGuid = UnitGUID(unit)
    local armorClass = GetTurnArmorClassForGuid(sourceGuid) or (parsed and parsed.ac) or 0
    local locked = opts.locked == true
    local rollName = prefix .. npcName
    local titleText = prefix .. (locked and ("[" .. npcName .. "]") or npcName)
    local nameColorHex, nameColorRGB = GetNpcNameColor(unit)
    return {
        kind = "npc",
        lockedSource = locked,
        npcSourceGuid = sourceGuid,
        overrides = overrides,
        armorClass = armorClass,
        rollName = rollName,
        rollColor = nameColorHex,
        titleText = titleText,
        titleColor = nameColorRGB,
        spellProficiencyBonus = GetNpcSpellProficiencyBonus(unit, parsed and parsed.approximateLevel),
        movementMeters = GetNpcMovementMeters(parsed),
        showActionPanel = true,
        actions = BuildNpcActions(unit),
        canAttack = API.CanNpcSheetAttack,
        canDamage = API.CanNpcSheetDamage,
        onAttackAnimation = API.ApplyNpcSheetAttackAnimation,
        onDamageRolled = API.ApplyNpcSheetDamage,
        onArmorClassChanged = API.UpdateNpcSheetArmorClass,
    }
end

local function IsSheetNpcCurrentTarget()
    return npcSheetContext
        and npcSheetContext.guid
        and UnitExists("target")
        and UnitGUID("target") == npcSheetContext.guid
end

function API.CanNpcSheetAttack()
    return IsSheetNpcCurrentTarget() == true
end

function API.CanNpcSheetDamage()
    if not npcSheetContext or not UnitExists("target") then
        return false
    end
    if npcSheetContext.locked then
        return not IsSheetNpcCurrentTarget()
    end
    return UnitIsPlayer and UnitIsPlayer("target") == true
end

function API.ApplyNpcSheetAttackAnimation(animId)
    if not npcSheetContext then
        return false
    end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        Print("Animar ataque requiere HarfordAdmin y .ph dm activo.")
        return false
    end
    if not IsSheetNpcCurrentTarget() then
        Print("Selecciona el NPC de la ficha para lanzar su ataque.")
        return false
    end
    if not (HarfordServerActions and HarfordServerActions.SetNpcEmote) then
        Print("HarfordServerActions.SetNpcEmote no disponible.")
        return false
    end
    local ok, err = HarfordServerActions.SetNpcEmote(animId, { addonName = "HarfordAdmin" })
    if not ok then
        Print("No se pudo animar el ataque: " .. tostring(err or "error desconocido"))
    end
    return ok
end

-- El dano recibido ya viene mitigado por defensas desde la tirada del core
-- (HarfordDamageMitigation); aqui solo se aplica al NPC objetivo. La info de
-- resistencias es publica y se muestra dentro de la propia tirada, no aqui.
function API.ApplyNpcSheetDamage(total, action, rolledComponents, isCritical)
    if not npcSheetContext then
        return false
    end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        Print("Aplicar dano requiere HarfordAdmin y .ph dm activo.")
        return false
    end
    if not UnitExists("target") or (UnitIsPlayer and UnitIsPlayer("target")) then
        Print("Selecciona un NPC objetivo para aplicar el dano de la tirada.")
        return false
    end
    if IsSheetNpcCurrentTarget() then
        Print("El NPC de la ficha no puede recibir su propio dano.")
        return false
    end
    local damage = math.floor(tonumber(total) or 0)
    if damage <= 0 then
        return true
    end
    if not (HarfordServerActions and HarfordServerActions.SetNpcHealthDelta) then
        Print("HarfordServerActions.SetNpcHealthDelta no disponible.")
        return false
    end
    local ok, err = HarfordServerActions.SetNpcHealthDelta(-damage, { addonName = "HarfordAdmin", isCritical = isCritical })
    if not ok then
        Print("No se pudo aplicar dano al NPC: " .. tostring(err or "error desconocido"))
    elseif HarfordServerActions.ModAnim then
        -- La victima es el target del comando NPC; la reaccion visual la hace
        -- el personaje del DM mediante el mismo impacto usado contra jugadores.
        HarfordServerActions.ModAnim(33, { addonName = "HarfordAdmin" })
    end
    return ok
end

function API.IsDnDSheetContextLocked()
    return npcSheetContext and npcSheetContext.locked == true
end

function API.HasDnDSheetContext()
    return npcSheetContext ~= nil
end

function API.ApplyDnDSheetContext(unit, opts)
    if not (HarfordDnDAPI and HarfordDnDAPI.ApplySheetContext) then
        return false, "HarfordDnDAPI.ApplySheetContext no disponible"
    end
    local context, err = API.BuildDnDSheetContext(unit, opts)
    if not context then
        return false, err
    end
    local priorContext = npcSheetContext
    npcSheetContext = { guid = context.npcSourceGuid, locked = context.lockedSource == true }
    local ok, applyErr = HarfordDnDAPI.ApplySheetContext(context)
    if not ok then
        npcSheetContext = priorContext
    end
    return ok, applyErr
end

function API.ClearDnDSheetContext()
    npcSheetContext = nil
    if HarfordDnDAPI and HarfordDnDAPI.ClearSheetContext then
        HarfordDnDAPI.ClearSheetContext()
    end
end
end

function API.GetTargetInfo(callback)
    if not (HarfordEpsilonCommands and HarfordEpsilonCommands.Send) then
        local err = "HarfordEpsilonCommands no disponible"
        if callback then callback(false, { err }) end
        return false, err
    end
    return HarfordEpsilonCommands.Send("npc info", {
        addonName = "HarfordAdmin",
        forceEpsilon = true,
        showMessages = false,
        callback = callback,
    })
end

local function ShowHelp()
    Print("comandos:")
    Print("/harfordadmin npc target")
    Print("/harfordadmin npc trp3")
    Print("/harfordadmin npc aura <spellId>")
    Print("/harfordadmin npc setaura <spellId>")
    Print("/harfordadmin npc lootaura")
    Print("/harfordadmin npc unaura <spellId>")
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

    if mode == "setaura" or mode == "npcaura" then
        local ok, err = API.SetAuraOnTarget(tokens[3])
        if ok then
            Print("npc set aura enviado a target")
        else
            Print(err)
        end
        return true
    end

    if mode == "lootaura" then
        local ok, err = API.SetLootAuraOnTarget()
        if ok then
            Print("Loot Aura enviada a target")
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
        API.GetTargetInfo(function(success, messages)
            if not success then
                Print("npc info fallo")
                for _, line in ipairs(messages or {}) do Print(line) end
                return
            end
            for _, line in ipairs(messages or {}) do Print(line) end
        end)
        return true
    end

    ShowHelp()
    return true
end

-- ── Override DM: shift-click en estados del viewer TRP3 ─────────────────────
-- En modo normal InsertGlanceLink mete [TRP3:id] en el editbox; el jugador
-- lo envía en chat y TRP3 lo formatea como hyperlink clicable.
-- En modo DM queremos saltarnos ese paso: enviamos al NPC target el hyperlink
-- totalrp3 ya respaldado por el ChatLink registrado.
-- Con Ctrl mantenido se abre un prompt de texto que se antepone al hyperlink,
-- produciendo: .npc te [texto] [hyperlink].

-- Popup reutilizable: se registra una vez y se reusa en cada invocacion.
if not StaticPopupDialogs["HARFORD_NPC_TEXTEMOTE_PREFIX"] then
    StaticPopupDialogs["HARFORD_NPC_TEXTEMOTE_PREFIX"] = {
        text = "Texto antes del estado (opcional):",
        button1 = "Enviar",
        button2 = "Cancelar",
        hasEditBox = true,
        maxLetters = 180,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(self)
            local prefixText = self.editBox and self.editBox:GetText() or ""
            local stored = self.data
            if not stored or not stored.hyperlink then return end
            if not (HarfordServerActions and HarfordServerActions.SendNpcTRP3Hyperlink) then
                Print("HarfordServerActions no disponible al confirmar el prompt.")
                return
            end
            local ok, err = HarfordServerActions.SendNpcTRP3Hyperlink(stored.hyperlink, {
                addonName    = "HarfordAdmin",
                forceEpsilon = true,
                textPrefix   = prefixText,
                textSuffix   = stored.textSuffix,
                callback     = stored.callback,
            })
            if not ok then
                Print("No se pudo emitir el estado: " .. tostring(err or "error desconocido"))
            end
        end,
        EditBoxOnEnterPressed = function(self)
            -- Confirmar con Enter igual que con el botón Enviar.
            local parent = self:GetParent()
            StaticPopupDialogs["HARFORD_NPC_TEXTEMOTE_PREFIX"].OnAccept(parent)
            parent:Hide()
        end,
        OnShow = function(self)
            self.editBox:SetFocus()
        end,
    }
end

if HarfordDnDArea and HarfordDnDArea.SetNpcPositionProvider then
    HarfordDnDArea.SetNpcPositionProvider(function(context, callback)
        RequestNpcInfoPosition(context and context.sourceGuid, callback)
    end)
end

do
    local _origInsertGlanceLink

    -- Nombre plano del focus para el textemote del servidor (RP TRP3 o nombre de WoW).
    -- Se anexa DESPUES del hyperlink: ".npc te [estado] <Focus>".
    local function GetFocusEmoteName()
        if not (UnitExists and UnitExists("focus")) then return nil end
        local name = HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("focus")
        if not name or name == "" then
            name = HarfordClassColors.UnitFullName("focus")
        end
        if not name or name == "" then return nil end
        return name
    end

    local function PrintLocalHyperlink(link)
        local sender = TRP3_API and TRP3_API.globals and TRP3_API.globals.player_id
        local id = link and link.GetIdentifier and link:GetIdentifier()
        if sender and id and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(HarfordChat.Format(string.format(
                "|cffffd100|Htotalrp3:%s:%s|h[%s]|h|r", sender, id, id)))
            return true
        end
        return false
    end

    local function OverrideDMInsertGlanceLink()
        if not (HarfordTRP3 and HarfordTRP3.InsertGlanceLink) then return end
        if _origInsertGlanceLink then return end
        _origInsertGlanceLink = HarfordTRP3.InsertGlanceLink

        HarfordTRP3.InsertGlanceLink = function(glance)
            local isDM = HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()
            if not isDM then
                _origInsertGlanceLink(glance)
                return
            end

            local link = HarfordTRP3.CreateGlanceLink and HarfordTRP3.CreateGlanceLink(glance)
            if not link then
                _origInsertGlanceLink(glance)
                return
            end

            local function Fallback(message)
                if message then
                    Print(message)
                end
                if not PrintLocalHyperlink(link) then
                    _origInsertGlanceLink(glance)
                end
            end

            if not UnitExists("target") or (UnitIsPlayer and UnitIsPlayer("target")) then
                Fallback("Selecciona un NPC para emitir el estado; dejo el enlace en chat.")
                return
            end

            local targetGuid = GetTargetGuid()
            local info = HarfordTRP3.GetLastGlanceLinkInfo and HarfordTRP3.GetLastGlanceLinkInfo()
            if not (info and info.hyperlink) then
                Fallback("No se pudo construir el enlace TRP3; dejo el enlace en chat.")
                return
            end

            if targetGuid ~= GetTargetGuid() or (UnitIsPlayer and UnitIsPlayer("target")) then
                Fallback("El target ha cambiado; no se ha emitido el estado.")
                return
            end

            if not (HarfordServerActions and HarfordServerActions.SendNpcTRP3Hyperlink) then
                Fallback("No se puede emitir el estado; dejo el enlace en chat.")
                return
            end

            local fallbackShown = false
            local function ShowFallback(message)
                if fallbackShown then return end
                fallbackShown = true
                Fallback(message)
            end

            local function DoSend(prefixText)
                local ok, err = HarfordServerActions.SendNpcTRP3Hyperlink(info.hyperlink, {
                    addonName    = "HarfordAdmin",
                    forceEpsilon = true,
                    textPrefix   = prefixText,
                    textSuffix   = GetFocusEmoteName(),
                    callback     = function(success)
                        if not success then
                            ShowFallback("El servidor rechazo el estado; dejo el enlace en chat.")
                        end
                    end,
                })
                if not ok then
                    ShowFallback("No se pudo emitir el estado: " .. tostring(err or "error desconocido"))
                end
            end

            -- Ctrl mantenido: pide texto de prefijo antes de emitir.
            if IsControlKeyDown and IsControlKeyDown() then
                local dialog = StaticPopup_Show("HARFORD_NPC_TEXTEMOTE_PREFIX")
                if dialog then
                    dialog.data = {
                        hyperlink  = info.hyperlink,
                        textSuffix = GetFocusEmoteName(),
                        callback   = function(success)
                            if not success then
                                ShowFallback("El servidor rechazo el estado; dejo el enlace en chat.")
                            end
                        end,
                    }
                else
                    -- No se pudo abrir el popup: enviar sin prefijo como fallback.
                    DoSend(nil)
                end
            else
                DoSend(nil)
            end
        end
    end

    -- Nota: NO se registra ningun callback para limpiar el target en "Modo combate".
    -- ClearTarget() es una funcion protegida de WoW (solo Blizzard UI / codigo seguro);
    -- llamarla desde un addon dispara "blocked from an action only available to the
    -- Blizzard UI". La animacion de combate ya se aplica al propio personaje sin
    -- deseleccionar, asi que no hace falta.

    local _f = CreateFrame("Frame")
    _f:RegisterEvent("PLAYER_LOGIN")
    _f:SetScript("OnEvent", function()
        C_Timer.After(0, OverrideDMInsertGlanceLink)
        _f:UnregisterAllEvents()
    end)
end
