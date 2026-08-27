HarfordDebugSettings = HarfordDebugSettings or {}

HarfordDebug = HarfordDebug or {}
HarfordDnDDebug = HarfordDebug

local API = HarfordDebug
local commands = {}

local function Print(message)
    print("|cff88ccff[HarfordDebug]|r " .. tostring(message or ""))
end

API.Print = Print

local function IsEnabled()
    return type(HarfordDebugSettings) == "table" and HarfordDebugSettings.enabled == true
end

local function SetEnabled(enabled, silent)
    HarfordDebugSettings = HarfordDebugSettings or {}
    HarfordDebugSettings.enabled = enabled == true
    API.enabled = HarfordDebugSettings.enabled

    if not silent then
        Print("debug " .. (API.enabled and "activado" or "desactivado"))
    end
end

local function SplitCommand(msg)
    msg = tostring(msg or "")
    local command, rest = msg:match("^%s*(%S+)%s*(.-)%s*$")
    return command and command:lower() or "", rest or ""
end

local function ShowHelp()
    Print("comandos:")
    Print("/harford debug on - activa logs y comandos debug")
    Print("/harford debug off - desactiva debug")
    Print("/harford debug toggle - alterna debug")
    Print("/harford debug status - muestra estado")
    Print("/harford debug run <comando> - ejecuta un comando debug registrado")
    Print("/harford debug list - lista comandos debug registrados")
end

local function ShowStatus()
    Print("estado: " .. (IsEnabled() and "ON" or "OFF"))
    Print("comandos registrados: " .. tostring(API.CountCommands()))
end

function API.IsEnabled()
    return IsEnabled()
end

function API.SetEnabled(enabled, silent)
    SetEnabled(enabled, silent)
end

function API.Toggle()
    SetEnabled(not IsEnabled())
end

function API.Log(...)
    if not IsEnabled() then
        return
    end

    print("|cff88ccff[HarfordDebug]|r", ...)
end

function API.CountCommands()
    local count = 0
    for _ in pairs(commands) do
        count = count + 1
    end
    return count
end

function API.RegisterCommand(name, handler, helpText)
    name = tostring(name or ""):lower()
    if name == "" or type(handler) ~= "function" then
        return false
    end

    commands[name] = {
        handler = handler,
        help = tostring(helpText or ""),
    }
    return true
end

function API.RunCommand(name, args)
    name = tostring(name or ""):lower()
    local entry = commands[name]
    if not entry then
        Print("comando debug no registrado: " .. tostring(name))
        return false
    end

    if not IsEnabled() then
        Print("debug esta desactivado. Usa /harford debug on")
        return false
    end

    local ok, err = pcall(entry.handler, args or "")
    if not ok then
        Print("error en comando debug '" .. name .. "': " .. tostring(err))
        return false
    end

    return true
end

function API.ListCommands()
    if API.CountCommands() == 0 then
        Print("no hay comandos debug registrados")
        return
    end

    Print("comandos debug registrados:")
    for name, entry in pairs(commands) do
        local suffix = entry.help ~= "" and (" - " .. entry.help) or ""
        Print(name .. suffix)
    end
end

API.RegisterCommand("deps", function()
    if not HarfordEpsilonCommands or not HarfordEpsilonCommands.GetStatus then
        Print("HarfordEpsilonCommands no disponible")
        return
    end

    local status = HarfordEpsilonCommands.GetStatus("Harford")
    Print("EpsilonLib.AddonCommands: " .. (status.epsilonLib and "OK" or "NO"))
    Print("Registro AddonCommands: " .. (status.addonCommands and "OK" or "NO"))
    if status.addonCommandsError then
        Print("Error registro: " .. tostring(status.addonCommandsError))
    end
    Print("ARC.CMD/ARC.COMM: " .. (status.arc and "OK" or "NO"))
end, "estado de EpsilonLib/ARC")

-- Atajos de prueba para la progresion propia. Permanecen en HarfordDebug: no son
-- comandos de juego ni una alternativa al flujo normal de recompensas/subida.
-- Estado de las barras Harford de XP/reputacion: cuanto ha subido la barra de accion y con
-- que marco se estan pintando. El nativo sube MainMenuBar 14 px con una barra y 19 con dos.
API.RegisterCommand("xpbar", function()
    local X = _G.HarfordCharacterXP
    if not (X and X.GetBarPlacement) then Print("HarfordCharacterXP no cargado"); return end
    local p = X.GetBarPlacement()
    if not p then
        Print("Las barras no estan creadas (config |cffffd100xpbar|r desactivada o sin progresion).")
        return
    end

    local propias = p.visible and (p.repVisible and 2 or 1) or 0
    local esperado = (math.min(2, propias + (p.nativas or 0)) == 2 and 19)
        or (math.min(2, propias + (p.nativas or 0)) == 1 and 14) or 0
    local real = tonumber(p.hostOffset)

    Print(string.format("Barras Harford: |cffffd100%d|r visible(s)   nativas: %d", propias, p.nativas or 0))
    Print(string.format("MainMenuBar subida: %s%s|r   esperado %d",
        (real == esperado) and "|cff38d26a" or "|cffff5555", tostring(real), esperado))
    if real ~= esperado then
        Print("   |cffff9900No coincide.|r Si estabas en combate se reaplica al salir;")
        Print("   si MainMenuBar esta recolocada a mano, el nativo tampoco la movería.")
    end
    Print(string.format("Marco: |cffffd100%s|r   ancho %s", tostring(p.atlas), tostring(math.floor(p.ancho or 0))))

    local host = _G.MainMenuBar
    if host and host.IsUserPlaced then
        Print("MainMenuBar recolocada a mano: " .. (host:IsUserPlaced() and "|cffff5555si|r" or "no"))
    end
    local right = _G.MultiBarBottomRight
    Print("MultiBarBottomRight visible: " ..
        ((right and right.IsShown and right:IsShown()) and "si (marco pequeno)" or "no (marco grande)"))
end, "Estado de las barras Harford de XP/reputacion y del desplazamiento de la barra de accion")

API.RegisterCommand("xp", function(args)
    local X = _G.HarfordCharacterXP
    if not (X and X.AddXP and X.GetXP and X.Progress) then
        Print("HarfordCharacterXP no disponible")
        return
    end
    local texto = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
    -- `xp = 900` fija el total; `xp 300` / `xp -300` suman o restan.
    local absoluto = texto:match("^=%s*(%d+)$")
    local delta = not absoluto and tonumber(texto:match("^%-?%d+$"))

    local antes = X.GetXP()
    local nivelAntes = X.LevelForXP(antes)
    if absoluto then
        if not X.SetXP(tonumber(absoluto)) then Print("No se pudo fijar la XP"); return end
        X.Refresh()
    elseif delta and delta ~= 0 then
        if not X.AddXP(delta, "debug") then Print("No se pudo ajustar la XP"); return end
    else
        Print("Uso: |cffffd100xp <cantidad>|r suma o resta (xp 300 / xp -300)")
        Print("     |cffffd100xp = <total>|r fija el total (xp = 900)")
        local nivel, dentro, tramo = X.Progress()
        Print(string.format("Ahora: %d XP  -  nivel %d, %d/%d del tramo", antes, nivel, dentro, tramo))
        return
    end

    local ahora = X.GetXP()
    local nivel, dentro, tramo = X.Progress()
    Print(string.format("XP %d -> |cffffd100%d|r  (%+d)", antes, ahora, ahora - antes))
    Print(string.format("nivel de XP %d%s   tramo %d/%d",
        nivel,
        (nivel ~= nivelAntes) and string.format(" |cff00ff00(antes %d)|r", nivelAntes) or "",
        dentro, tramo))
    -- Restar por debajo de 0 lo capa SetXP: si pediste mas de lo que tenias, conviene decirlo.
    if delta and delta < 0 and (antes + delta) < 0 then
        Print("   |cffffcc00capado a 0|r: tenias menos XP de la que querias restar")
    end
    if X.PendingLevelUp and X.PendingLevelUp() then
        Print("   hay subida pendiente: |cffffd100/harford char subir|r")
    end
end, "XP propia: xp <cantidad> suma/resta, xp = <total> fija")

API.RegisterCommand("rep", function(args)
    local factionId, amount = tostring(args or ""):match("^%s*(%S+)%s+([%-]?%d+)%s*$")
    amount = tonumber(amount)
    if not factionId or not amount or amount == 0 then
        Print("Uso: rep <faccionId> <cantidad>. Ejemplo: rep compania_harford 100")
        return
    end
    if not (HarfordReputation and HarfordReputation.RememberPlayer and HarfordReputation.AdjustPlayerPoints) then
        Print("HarfordReputation no disponible")
        return
    end
    if not HarfordReputation.GetFaction or not HarfordReputation.GetFaction(factionId) then
        Print("Faccion no encontrada: " .. tostring(factionId))
        return
    end
    local playerKey = HarfordReputation.RememberPlayer("player")
    if not playerKey then
        Print("No se pudo identificar al jugador")
        return
    end
    local ok, err = HarfordReputation.AdjustPlayerPoints(playerKey, factionId, amount, { fromSync = true })
    if not ok then
        Print("No se pudo ajustar reputacion: " .. tostring(err or "error desconocido"))
        return
    end
    local current = HarfordReputation.GetPlayerPoints(playerKey, factionId)
    Print(string.format("Reputacion %s: %s%d -> %d", tostring(factionId), amount >= 0 and "+" or "", amount, tonumber(current) or 0))
end, "suma/resta reputacion propia: rep <faccionId> <cantidad>")

local function ParseDebugMoney(text)
    local amount, unit = tostring(text or ""):lower():match("^%s*(%d+)%s*([gsc]?)%s*$")
    amount = tonumber(amount)
    if not amount then return nil end
    if unit == "c" then return amount end
    if unit == "s" then return amount * 100 end
    return amount * 10000 -- sin sufijo = oro, para pruebas rapidas
end

local function DebugMoneyText(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    local gold = math.floor(copper / 10000)
    copper = copper % 10000
    local silver = math.floor(copper / 100)
    copper = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copper)
end

API.RegisterCommand("dinero", function(args)
    local economy = HarfordDnDEconomy
    if not (economy and economy.IsInitialized and economy.GetBalance) then
        Print("HarfordDnDEconomy no disponible")
        return
    end
    local action, value = tostring(args or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    action = action or ""
    if action == "" or action == "saldo" then
        local balance = economy.GetBalance()
        local native = GetMoney and GetMoney() or nil
        Print("Saldo Harford: " .. (balance and DebugMoneyText(balance) or "sin inicializar")
            .. " | WoW: " .. (native and DebugMoneyText(native) or "no disponible"))
        return
    end
    if action ~= "set" and action ~= "add" and action ~= "take" then
        Print("Uso: dinero [saldo|set|add|take] <cantidad>. Ej.: dinero set 10g; dinero add 50s")
        return
    end
    local amount = ParseDebugMoney(value)
    if not amount then
        Print("Cantidad invalida. Usa oro (10g), plata (50s) o cobre (25c). Sin sufijo = oro.")
        return
    end
    local balance = economy.GetBalance()
    if balance == nil then
        Print("La economia no esta inicializada: termina primero la creacion del personaje.")
        return
    end
    local target = action == "set" and amount or (action == "add" and balance + amount or balance - amount)
    if target < 0 then
        Print("No puedes retirar mas de " .. DebugMoneyText(balance) .. ".")
        return
    end
    local change = target - balance
    if change == 0 then
        Print("El saldo ya es " .. DebugMoneyText(balance) .. ".")
        return
    end
    local method = change > 0 and economy.Grant or economy.Spend
    local ok, err = method(math.abs(change), {
        callback = function(success, messages)
            if success then
                Print("Saldo Harford actualizado: " .. DebugMoneyText(target) .. ".")
            else
                local detail = type(messages) == "table" and messages[1] or messages
                Print("No se pudo actualizar el saldo: " .. tostring(detail or "error"))
            end
        end,
    })
    if not ok then Print("No se pudo enviar el ajuste: " .. tostring(err or "error")) end
end, "prueba economia: dinero [saldo|set|add|take] <10g|50s|25c>")

-- Sonda temporal para comprobar que notifica el cliente tras `.modify money`.
-- No pertenece al flujo normal de economia: solo se activa por comando debug y se destruye sola.
API.RegisterCommand("dineroeventos", function(args)
    local duration = tonumber(tostring(args or ""):match("%d+")) or 15
    duration = math.max(5, math.min(60, math.floor(duration)))
    if not GetMoney then
        Print("GetMoney no esta disponible en este cliente.")
        return
    end

    local startedAt = GetTime and GetTime() or 0
    local lastMoney = GetMoney()
    local frame = CreateFrame("Frame")
    local watched = {
        PLAYER_MONEY = true,
        CURRENCY_DISPLAY_UPDATE = true,
        CHAT_MSG_SYSTEM = true,
        UI_INFO_MESSAGE = true,
    }
    for event in pairs(watched) do frame:RegisterEvent(event) end

    Print("Sonda de dinero activa " .. duration .. " s. Ejecuta .modify money <cobre> ahora.")
    Print("Inicio: " .. DebugMoneyText(lastMoney))

    frame:SetScript("OnEvent", function(_, event, ...)
        local current = GetMoney()
        local suffix = ""
        if event == "CHAT_MSG_SYSTEM" or event == "UI_INFO_MESSAGE" then
            suffix = " texto=" .. tostring((...))
        end
        Print("evento " .. event .. " | WoW " .. DebugMoneyText(current) .. suffix)
        lastMoney = current
    end)
    frame:SetScript("OnUpdate", function(self)
        local now = GetTime and GetTime() or startedAt
        local current = GetMoney()
        if current ~= lastMoney then
            Print("GetMoney cambio sin evento observado: " .. DebugMoneyText(lastMoney)
                .. " -> " .. DebugMoneyText(current))
            lastMoney = current
        end
        if now - startedAt >= duration then
            self:SetScript("OnUpdate", nil)
            self:UnregisterAllEvents()
            Print("Sonda de dinero finalizada. Saldo final: " .. DebugMoneyText(lastMoney))
        end
    end)
end, "sonda temporal: dineroeventos [segundos]; ejecuta .modify money mientras esta activa")

API.RegisterCommand("nivel", function(args)
    local requested, classIndex = tostring(args or ""):match("^%s*(%d+)%s*(%d*)%s*$")
    requested = tonumber(requested)
    classIndex = tonumber(classIndex)
    if not requested or requested < 1 or requested > 20 then
        Print("Uso: nivel <1-20> [indiceClase]. Ejemplo: nivel 4 1")
        return
    end
    if not (HarfordDnDProgression and HarfordDnDProgression.Get and HarfordDnDProgression.SetClassEntry) then
        Print("HarfordDnDProgression no disponible")
        return
    end
    local data = HarfordDnDProgression.Get()
    local classes = data and data.classLevels or {}
    if #classes == 0 then
        Print("No hay clase configurada en la ficha")
        return
    end
    if not classIndex and #classes > 1 then
        Print("Ficha multiclase. Indica el indice: nivel <1-20> <indiceClase>")
        for i, entry in ipairs(classes) do
            Print(string.format("  %d: %s nivel %d", i, tostring(entry.classId or "?"), tonumber(entry.level) or 0))
        end
        return
    end
    classIndex = classIndex or 1
    local entry = classes[classIndex]
    if not entry then
        Print("Indice de clase invalido: " .. tostring(classIndex))
        return
    end
    local ok, updated = HarfordDnDProgression.SetClassEntry(classIndex, entry.classId, entry.subclassId, requested)
    if not ok then
        Print("No se pudo ajustar el nivel: " .. tostring(updated or "error desconocido"))
        return
    end
    -- La XP no sustituye la subida manual, pero nunca debe quedar por debajo del
    -- nivel que el propio comando de prueba acaba de fijar.
    local total = HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel() or requested
    local threshold = HarfordCharacterXP and HarfordCharacterXP.XP_TABLE and HarfordCharacterXP.XP_TABLE[total]
    if threshold and HarfordCharacterXP.GetXP and HarfordCharacterXP.SetXP and HarfordCharacterXP.GetXP() < threshold then
        HarfordCharacterXP.SetXP(threshold)
    end
    Print(string.format("Clase %d (%s) fijada a nivel %d. Nivel total: %d", classIndex, tostring(updated.classId), tonumber(updated.level) or requested, total))
end, "fija nivel de clase: nivel <1-20> [indiceClase]")

API.RegisterCommand("qsharedebug", function()
    _G.HARFORD_QSHARE_DEBUG = not _G.HARFORD_QSHARE_DEBUG
    Print("Diagnostico de compartir misiones: " .. (_G.HARFORD_QSHARE_DEBUG and "ON" or "OFF"))
end, "toggle logging del compartir de misiones (doble-click)")

-- Sonda de objetivos compartidos. No altera el protocolo ni el estado: permite separar si el
-- problema esta en la emision QOBJ, en su llegada al otro cliente o al aplicarlo localmente.
local qobjHookInstalled = false
local function InstallQuestObjectiveProbe()
    if qobjHookInstalled or type(hooksecurefunc) ~= "function" or not HarfordQuests then return end
    qobjHookInstalled = true
    if HarfordQuests.SetObjectiveProgressForGroup then
        hooksecurefunc(HarfordQuests, "SetObjectiveProgressForGroup", function(id, index, current)
            if not _G.HARFORD_QOBJ_DEBUG then return end
            local channel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel() or "ninguno"
            Print(string.format("QOBJ progreso salida: id=%s indice=%s progreso=%s canal=%s", tostring(id), tostring(index), tostring(current), tostring(channel)))
        end)
    end
    if HarfordQuests.CompleteObjectiveForGroup then
        hooksecurefunc(HarfordQuests, "CompleteObjectiveForGroup", function(id, index)
            if not _G.HARFORD_QOBJ_DEBUG then return end
            local channel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel() or "ninguno"
            Print(string.format("QOBJ completado salida: id=%s indice=%s canal=%s", tostring(id), tostring(index), tostring(channel)))
        end)
    end
end

API.RegisterCommand("qobjdebug", function()
    InstallQuestObjectiveProbe()
    _G.HARFORD_QOBJ_DEBUG = not _G.HARFORD_QOBJ_DEBUG
    Print("Diagnostico de objetivos compartidos: " .. (_G.HARFORD_QOBJ_DEBUG and "ON" or "OFF"))
end, "muestra envio/recepcion/aplicacion de QOBJ")

do
    local probe = CreateFrame("Frame")
    probe:RegisterEvent("CHAT_MSG_ADDON")
    probe:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
        if not _G.HARFORD_QOBJ_DEBUG or prefix ~= "HARFORDQUEST" or type(message) ~= "string" then return end
        local doneId, doneIndex = message:match("^QOBJ|(.+)|(%d+)|completed$")
        if doneId then
            Print(string.format("QOBJ completado recibido: de=%s id=%s indice=%s canal=%s", tostring(sender), tostring(doneId), tostring(doneIndex), tostring(channel)))
            if C_Timer and C_Timer.After then
            C_Timer.After(0.10, function()
                local objectives = HarfordQuests and HarfordQuests.GetObjectives and HarfordQuests.GetObjectives(doneId)
                local objective = objectives and objectives[tonumber(doneIndex) or 0]
                if objective then
                    Print("QOBJ completado observado: hecho=" .. tostring(objective.done == true))
                    return
                end
                local ids = {}
                for _, quest in ipairs((HarfordQuests and HarfordQuests.GetAccepted and HarfordQuests.GetAccepted()) or {}) do
                    ids[#ids + 1] = tostring(quest.id)
                end
                Print("QOBJ completado pendiente: no existe ese ID. Aceptadas: "
                    .. (#ids > 0 and table.concat(ids, ", ") or "(ninguna)"))
            end)
            end
            return
        end
        local legacyDoneIndex, legacyDoneId = message:match("^QOBJDONE|(%d+)|(.+)$")
        if legacyDoneId then
            Print(string.format("QOBJDONE legado recibido: de=%s id=%s indice=%s canal=%s", tostring(sender), tostring(legacyDoneId), tostring(legacyDoneIndex), tostring(channel)))
            return
        end
        local index, current, id = message:match("^QOBJ|(%d+)|(%-?%d+)|(.+)$")
        if not id then return end
        Print(string.format("QOBJ recibido: de=%s id=%s indice=%s progreso=%s canal=%s", tostring(sender), tostring(id), tostring(index), tostring(current), tostring(channel)))
        if C_Timer and C_Timer.After then
            C_Timer.After(0.10, function()
                local objectives = HarfordQuests and HarfordQuests.GetObjectives and HarfordQuests.GetObjectives(id)
                local objective = objectives and objectives[tonumber(index) or 0]
                if objective then
                    Print(string.format("QOBJ observado: %d/%d hecho=%s", objective.current or 0, objective.required or 1, tostring(objective.done == true)))
                else
                    Print("QOBJ no aplicado: la mision u objetivo no existe en este cliente")
                end
            end)
        end
    end)
end

InstallQuestObjectiveProbe()

-- Handler de prueba del bus HarfordCourier: el receptor imprime el ping. Se registra en TODOS los
-- clientes al cargar (el que envia no es el que imprime).
if HarfordCourier and HarfordCourier.RegisterHandler then
    HarfordCourier.RegisterHandler("DEBUGPING", function(payload, from)
        if HarfordChat and HarfordChat.Print then
            HarfordChat.Print("|cff88ff88[Courier]|r Ping de " .. tostring(from) .. ": " .. tostring(payload))
        end
    end)
end

API.RegisterCommand("prof", function()
    if not HarfordProfessions then Print("HarfordProfessions no disponible"); return end
    for _, p in ipairs(HarfordProfessions.GetProfessions()) do
        if HarfordProfessions.KnowsProfession(p.id) then
            local s = HarfordProfessions.EffectiveSkill(p.id)
            Print(string.format("%s: %d/%d (%s) [%s]", p.name, s, HarfordProfessions.MAX_SKILL,
                HarfordProfessions.GetTierName(s), p.kind))
        end
    end
end, "lista tus profesiones conocidas y su skill")

API.RegisterCommand("profcraft", function(args)
    local recipeId = tostring(args or ""):match("^(%S+)")
    if not recipeId or recipeId == "" then Print("Uso: profcraft <recipeId>"); return end
    if not HarfordProfessions then Print("HarfordProfessions no disponible"); return end
    HarfordProfessions.Craft(recipeId)
end, "intenta craftear una receta por id")

API.RegisterCommand("profrecipes", function(args)
    local profId = tostring(args or ""):match("^(%S+)")
    if not profId or profId == "" then Print("Uso: profrecipes <profesionId>"); return end
    if not HarfordProfessions then Print("HarfordProfessions no disponible"); return end
    local def = HarfordProfessions.GetDefinition(profId)
    if not def then Print("Profesion desconocida: " .. profId); return end
    local recipes = HarfordProfessions.GetRecipes(profId)
    Print(string.format("%s: %d recetas | skill %d", def.name or profId, #recipes,
        HarfordProfessions.EffectiveSkill(profId)))
    for _, recipe in ipairs(recipes) do
        local ok, reason = HarfordProfessions.CanCraft(recipe.id)
        Print(string.format("%s | req %d | CD %d | %s%s", recipe.id,
            tonumber(recipe.skillReq) or 1, tonumber(recipe.dc) or 10,
            ok and "|cff38d26aLISTA|r" or "|cffff5555" .. tostring(reason) .. "|r",
            recipe.worldLearned and " | mundo" or ""))
    end
end, "lista recetas y requisitos: profrecipes <profesionId>")

API.RegisterCommand("profcheck", function(args)
    local recipeId = tostring(args or ""):match("^(%S+)")
    if not recipeId or recipeId == "" then Print("Uso: profcheck <recipeId>"); return end
    if not HarfordProfessions then Print("HarfordProfessions no disponible"); return end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then Print("Receta desconocida: " .. recipeId); return end
    local ok, reason, materials = HarfordProfessions.CanCraft(recipeId)
    local output = HarfordProfessionsItems and HarfordProfessionsItems.Get and HarfordProfessionsItems.Get(recipe.output and recipe.output.key)
    Print(string.format("%s (%s) | req %d | CD %d | %s", recipe.name or recipeId,
        recipe.profession or "?", tonumber(recipe.skillReq) or 1, tonumber(recipe.dc) or 10,
        ok and "|cff38d26aLISTA|r" or "|cffff5555" .. tostring(reason) .. "|r"))
    local outputKey = recipe.output and recipe.output.key
    local outputId = HarfordProfessionsItems and HarfordProfessionsItems.GetId
        and HarfordProfessionsItems.GetId(outputKey)
    Print(string.format("Resultado: %s x%d | id=%s", output and output.name or tostring(outputKey),
        tonumber(recipe.output and recipe.output.qty) or 1, tostring(outputId or "PENDIENTE")))
    for _, material in ipairs(materials or {}) do
        Print(string.format("  %s: %d/%d | id=%s", material.name or material.key,
            tonumber(material.have) or 0, tonumber(material.need) or 0, tostring(material.id or "PENDIENTE")))
    end
end, "muestra materiales y puerta real: profcheck <recipeId>")

API.RegisterCommand("profitem", function(args)
    local key, qty = tostring(args or ""):match("^(%S+)%s*(%d*)")
    if not key or key == "" then Print("Uso: profitem <claveItem> [cantidad]"); return end
    local items = HarfordProfessionsItems
    local entry = items and items.Get and items.Get(key)
    local itemId = entry and items.GetId and items.GetId(key)
    if not itemId then Print("Item sin ID valido: " .. key); return end
    if not (HarfordServerActions and HarfordServerActions.GiveItem) then Print("HarfordServerActions no disponible"); return end
    local amount = math.max(1, math.floor(tonumber(qty) or 1))
    local ok, err = HarfordServerActions.GiveItem(itemId, amount)
    Print(ok and ("Entregado: " .. tostring(items.GetName(key)) .. " x" .. amount
        .. " (ID " .. tostring(itemId) .. ")") or ("No se pudo entregar: " .. tostring(err)))
end, "entrega un material registrado para pruebas: profitem <clave> [cantidad]")

API.RegisterCommand("profcatalog", function(args)
    local key = tostring(args or ""):match("^(%S+)")
    local items = HarfordProfessionsItems
    local entry = key and items and items.Get and items.Get(key)
    if not entry then Print("Uso: profcatalog <claveItem>"); return end
    local metadata = items.GetMetadata and items.GetMetadata(key)
    local operational = items.GetId and items.GetId(key)
    Print(string.format("%s | Wowhead=%s | operativo=%s | Epsilon fallback=%s",
        items.GetName(key), tostring(entry.wow or "-"), tostring(operational or "PENDIENTE"),
        tostring(items.GetEpsilonId and items.GetEpsilonId(key) or "-")))
    if metadata then
        Print(string.format("  calidad=%s  ilvl=%s  pila=%s  venta=%s  icono=%s",
            tostring(metadata.quality or "-"), tostring(metadata.ilvl or "-"), tostring(metadata.pila or "-"),
            tostring(metadata.sell or "-"), tostring(metadata.icon or "-")))
    else
        Print("  Sin metadata Wowhead (objeto custom/dinamico).")
    end
end, "muestra la resolucion Wowhead/Epsilon: profcatalog <clave>")

API.RegisterCommand("profmaterials", function(args)
    local recipeId = tostring(args or ""):match("^(%S+)")
    if not recipeId or recipeId == "" then Print("Uso: profmaterials <recipeId>"); return end
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then
        Print("HarfordProfessions no disponible")
        return
    end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then Print("Receta desconocida: " .. recipeId); return end
    local items = HarfordProfessionsItems
    if not (items and items.GetId and HarfordServerActions and HarfordServerActions.GiveItem) then
        Print("Registro de items o acciones de servidor no disponibles")
        return
    end
    for _, material in ipairs(recipe.materials or {}) do
        local itemId = items.GetId(material.key)
        local quantity = math.max(1, math.floor(tonumber(material.qty) or 1))
        if not itemId then
            Print("Sin ID para " .. tostring(material.key) .. "; no entregado.")
        else
            local ok, err = HarfordServerActions.GiveItem(itemId, quantity)
            Print(ok and ("Entregado: " .. items.GetName(material.key) .. " x" .. quantity)
                or ("Fallo al entregar " .. items.GetName(material.key) .. ": " .. tostring(err)))
        end
    end
end, "entrega materiales de una receta: profmaterials <recipeId>")

API.RegisterCommand("profgather", function(args)
    local recipeId, seconds = tostring(args or ""):match("^(%S+)%s*(%d*)")
    if not recipeId or recipeId == "" then Print("Uso: profgather <recipeId> [segundosCooldown]"); return end
    if not HarfordProfessions then Print("HarfordProfessions no disponible"); return end
    HarfordProfessions.GatherNode(recipeId, tonumber(seconds) or 30)
end, "prueba un nodo sobre el objetivo actual: profgather <recipeId> [segundos]")

API.RegisterCommand("proflearn", function(args)
    local recipeId = tostring(args or ""):match("^(%S+)")
    if not recipeId or recipeId == "" then Print("Uso: proflearn <recipeId>"); return end
    if not HarfordProfessions then Print("HarfordProfessions no disponible"); return end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not (recipe and recipe.worldLearned) then Print("Solo se pueden probar recetas worldLearned."); return end
    HarfordProfessions.LearnRecipe(recipeId)
    Print("Receta aprendida para pruebas: " .. tostring(recipe.name))
end, "aprende localmente una receta worldLearned para pruebas")

-- Resuelve una profesion por id EXACTO o por su nombre visible, tolerando tildes, mayusculas y
-- espacios ("Herreria", "herrería", "Primeros Auxilios"). Escribir el id crudo era un requisito
-- innecesario para un comando de pruebas.
local function ResolveProfession(texto)
    if not (HarfordProfessions and HarfordProfessions.GetDefinition) then return nil end
    texto = tostring(texto or "")
    local exacta = HarfordProfessions.GetDefinition(texto)
    if exacta then return texto, exacta end
    local function Normaliza(v)
        v = tostring(v or "")
        if HarfordClassColors and HarfordClassColors.StripAccents then
            v = HarfordClassColors.StripAccents(v)
        end
        return v:lower():gsub("[%s_]", "")
    end
    local buscado = Normaliza(texto)
    for _, def in ipairs(HarfordProfessions.GetProfessions and HarfordProfessions.GetProfessions() or {}) do
        if Normaliza(def.id) == buscado or Normaliza(def.name) == buscado then
            return def.id, def
        end
    end
    return nil
end

local function ListProfessions()
    local ids = {}
    for _, def in ipairs(HarfordProfessions and HarfordProfessions.GetProfessions
        and HarfordProfessions.GetProfessions() or {}) do
        ids[#ids + 1] = def.id
    end
    table.sort(ids)
    return table.concat(ids, ", ")
end

API.RegisterCommand("profskill", function(args)
    local texto, value = tostring(args or ""):match("^%s*(.-)%s*(%-?%d*)%s*$")
    if not texto or texto == "" then
        Print("Uso: profskill <profesion> [skill 0-300]. Ej: profskill herreria 150")
        Print("Con skill > 0 el PJ CONOCE la profesion (via de pruebas; lo normal es la competencia de herramienta).")
        Print("|cff808080" .. ListProfessions() .. "|r")
        return
    end
    local profId = ResolveProfession(texto)
    if not profId then
        Print("Profesion desconocida: |cffffd100" .. tostring(texto) .. "|r")
        Print("Validas: |cff808080" .. ListProfessions() .. "|r")
        return
    end
    HarfordProfessions.SetSkill(profId, tonumber(value) or 1)
    local skill = HarfordProfessions.EffectiveSkill(profId)
    Print(string.format("%s: skill %d (%s)%s", profId, skill,
        HarfordProfessions.GetTierName(skill),
        HarfordProfessions.KnowsProfession(profId) and " — conocida" or ""))
end, "fija el skill de una profesion para pruebas (skill > 0 = conocida): profskill <id> [valor]")

API.RegisterCommand("profreset", function(args)
    if tostring(args or ""):lower():gsub("%s+", "") ~= "confirm" then
        Print("Reinicia profesiones de ESTE personaje. Confirma: profreset confirm")
        return
    end
    if not (HarfordProfessions and HarfordProfessions.ResetCharacterState) then
        Print("Sistema de profesiones no disponible.")
        return
    end
    HarfordProfessions.ResetCharacterState()
    Print("Estado de profesiones reiniciado para este personaje.")
end, "reinicia skills, recetas, recetas dinamicas y cooldowns: profreset confirm")

API.RegisterCommand("profmissing", function()
    if not (HarfordProfessionsItems and HarfordProfessionsItems.Missing) then Print("registro no disponible"); return end
    local miss = HarfordProfessionsItems.Missing()
    Print(string.format("Items sin ID (%d): %s", #miss, table.concat(miss, ", ")))
end, "lista claves de item sin ID registrado")

-- ─── Profesiones nativas (solo investigacion; no abre ni altera la UI Blizzard) ──
local NATIVE_PROF_EVENTS = {
    "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE",
    "TRADE_SKILL_ITEM_CRAFTED", "TRADE_SKILL_ITEM_UPDATE",
}

local nativeProfEvents = CreateFrame("Frame")
nativeProfEvents:SetScript("OnEvent", function(_, event, ...)
    if not _G.HARFORD_NATIVE_PROF_EVENTS then return end
    local args = { ... }
    local text = {}
    for i = 1, math.min(#args, 4) do text[#text + 1] = tostring(args[i]) end
    Print("Nativo " .. event .. (#text > 0 and (": " .. table.concat(text, ", ")) or ""))
end)

local function NativeProfFrameInfo(frame)
    if not frame then return nil end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    return {
        shown = frame:IsShown() == true,
        width = frame:GetWidth(), height = frame:GetHeight(),
        scale = frame:GetScale(), strata = frame:GetFrameStrata(), level = frame:GetFrameLevel(),
        point = point, relativeTo = relativeTo and relativeTo:GetName() or nil,
        relativePoint = relativePoint, x = x, y = y,
    }
end

local function NativeCall(name, ...)
    local fn = _G[name]
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if not ok then return { error = tostring(a) } end
    return { a, b, c, d, e }
end

local function CaptureNativeProfession(label)
    HarfordDebugSettings.nativeProfessionProbes = HarfordDebugSettings.nativeProfessionProbes or {}
    label = tostring(label or "ultima"):gsub("[^%w_%-]", "_")
    if label == "" then label = "ultima" end

    local line = NativeCall("GetTradeSkillLine")
    local total = NativeCall("GetNumTradeSkills")
    local count = tonumber(total and total[1]) or 0
    local probe = {
        timestamp = time and time() or 0,
        line = line,
        count = count,
        api = {
            legacy = type(GetNumTradeSkills) == "function",
            cTradeSkillUI = type(C_TradeSkillUI) == "table",
        },
        frames = {
            TradeSkillFrame = NativeProfFrameInfo(_G.TradeSkillFrame),
            TradeSkillListScrollFrame = NativeProfFrameInfo(_G.TradeSkillListScrollFrame),
            TradeSkillCreateButton = NativeProfFrameInfo(_G.TradeSkillCreateButton),
        },
        entries = {},
    }

    for index = 1, math.min(count, 250) do
        local info = NativeCall("GetTradeSkillInfo", index) or {}
        local reagents = {}
        local reagentCount = tonumber((NativeCall("GetTradeSkillNumReagents", index) or {})[1]) or 0
        for reagentIndex = 1, math.min(reagentCount, 12) do
            reagents[#reagents + 1] = {
                info = NativeCall("GetTradeSkillReagentInfo", index, reagentIndex),
                link = NativeCall("GetTradeSkillReagentItemLink", index, reagentIndex),
            }
        end
        probe.entries[#probe.entries + 1] = {
            index = index,
            info = info,
            icon = NativeCall("GetTradeSkillIcon", index),
            link = NativeCall("GetTradeSkillItemLink", index),
            description = NativeCall("GetTradeSkillDescription", index),
            cooldown = NativeCall("GetTradeSkillCooldown", index),
            made = NativeCall("GetTradeSkillNumMade", index),
            reagents = reagents,
        }
    end

    -- La API moderna se guarda como disponibilidad y metodos, sin invocar funciones cuyo
    -- contrato puede variar entre builds de Epsilon.
    if type(C_TradeSkillUI) == "table" then
        probe.api.modernMethods = {}
        for name, value in pairs(C_TradeSkillUI) do
            if type(value) == "function" then probe.api.modernMethods[#probe.api.modernMethods + 1] = name end
        end
        table.sort(probe.api.modernMethods)
    end

    HarfordDebugSettings.nativeProfessionProbes[label] = probe
    Print(string.format("Profesion nativa capturada '%s': linea=%s entradas=%d frame=%s. Haz /reload para guardar.",
        label, tostring(line and line[1] or "(sin linea)"), count,
        probe.frames.TradeSkillFrame and tostring(probe.frames.TradeSkillFrame.shown) or "no existe"))
end

-- ─── nativeprobe: herramienta UNICA de investigacion de frames nativos ───
-- Une en un solo comando la captura de profesiones (antes `nativeprof`), la captura
-- de skin/geometria via probeframe y el registro de soundkits. Todo con subopciones.
do
    local soundHooked = false
    local function LogSound(entry)
        local store = HarfordDebugSettings
        store.soundLog = store.soundLog or {}
        table.insert(store.soundLog, entry)
        if #store.soundLog > 400 then table.remove(store.soundLog, 1) end
        Print("|cff99ff99[sound]|r " .. entry)
    end
    local function EnsureSoundHooks()
        if soundHooked then return end
        soundHooked = true
        -- hooksecurefunc no se puede quitar: el flag decide si se anota o no.
        -- Se anota el frame bajo el raton para saber QUE control disparo el sonido.
        local function MouseFocusName()
            local f = GetMouseFocus and GetMouseFocus()
            if not f then return "?" end
            local name = f.GetName and f:GetName()
            if name then return name end
            local parent = f.GetParent and f:GetParent()
            local pname = parent and parent.GetName and parent:GetName()
            return pname and ("(anon hijo de " .. pname .. ")") or "(anon)"
        end
        hooksecurefunc("PlaySound", function(kit, channel)
            if _G.HARFORD_SOUNDLOG then
                LogSound(string.format("%.1f kit=%s ch=%s sobre=%s", GetTime() % 10000, tostring(kit), tostring(channel or "SFX"), MouseFocusName()))
            end
        end)
        if type(PlaySoundFile) == "function" then
            hooksecurefunc("PlaySoundFile", function(file, channel)
                if _G.HARFORD_SOUNDLOG then
                    LogSound(string.format("%.1f file=%s ch=%s sobre=%s", GetTime() % 10000, tostring(file), tostring(channel or "SFX"), MouseFocusName()))
                end
            end)
        end
    end
    -- Frames candidatos de la UI de profesiones segun cliente (clasica, moderna, artesania)
    local PROF_FRAMES = { "TradeSkillFrame", "ProfessionsFrame", "CraftFrame" }
    local function VisibleProfFrame()
        for _, name in ipairs(PROF_FRAMES) do
            local f = _G[name]
            if f and f.IsShown and f:IsShown() then return name end
        end
        return nil
    end

    API.RegisterCommand("nativeprobe", function(args)
        local action, label = tostring(args or ""):match("^%s*(%S*)%s*(.-)%s*$")
        action = action:lower()

        if action == "" or action == "status" then
            Print("ReputationFrame: " .. (_G.ReputationFrame and (_G.ReputationFrame:IsShown() and "visible" or "oculto") or "no existe"))
            for _, name in ipairs(PROF_FRAMES) do
                local f = _G[name]
                Print(name .. ": " .. (f and (f:IsShown() and "visible" or "oculto") or "no existe"))
            end
            local line = NativeCall("GetTradeSkillLine")
            local count = NativeCall("GetNumTradeSkills")
            Print("API clasica: " .. (type(GetNumTradeSkills) == "function" and "SI" or "NO")
                .. " | C_TradeSkillUI: " .. (type(C_TradeSkillUI) == "table" and "SI" or "NO"))
            Print("Linea: " .. tostring(line and line[1] or "(ninguna)")
                .. " | entradas: " .. tostring(count and count[1] or 0))
            Print("soundlog: " .. (_G.HARFORD_SOUNDLOG and "ON" or "OFF")
                .. " (" .. #(HarfordDebugSettings.soundLog or {}) .. " entradas)")
            return
        end

        -- El frame del entrenador (`Blizzard_TrainerUI`) es de CARGA BAJO DEMANDA: normalmente
        -- solo aparece al hablar con un entrenador, y en Epsilon no hay forma de abrirlo. Pero se
        -- puede cargar a mano, y con eso el frame queda construido con toda su geometria, arte y
        -- fuentes aunque no tenga datos. Eso es justo lo que la sonda necesita.
        if action == "trainer" then
            -- Lo primero: que las rutas del XML nativo EXISTAN en este cliente. Una ruta que no
            -- resuelve se pinta en verde chillon sin avisar, y toda la ventana depende de estas.
            Print("texturas del entrenador en este cliente:")
            for _, ruta in ipairs({
                "Interface\\ClassTrainerFrame\\TrainerTextures",
                "Interface\\GuildFrame\\GuildFrame",
                "Interface\\MoneyFrame\\UI-MoneyFrame-Border",
                "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
            }) do
                local id = GetFileIDFromPath and GetFileIDFromPath(ruta)
                Print("   " .. (id and ("OK  fileID " .. id) or "NO EXISTE") .. "  " .. ruta)
            end
            local cargar = (C_AddOns and C_AddOns.LoadAddOn) or _G.LoadAddOn
            if not cargar then return Print("no hay API para cargar addons bajo demanda") end
            local ok, err = cargar("Blizzard_TrainerUI")
            Print("cargar Blizzard_TrainerUI: " .. (ok and "OK" or ("fallo: " .. tostring(err))))
            local f = _G.ClassTrainerFrame
            if not f then
                Print("ClassTrainerFrame no existe tras cargar; prueba tambien:")
                for _, n in ipairs({ "TrainerFrame", "ProfessionsBookFrame", "ClassTrainerFrameInset" }) do
                    Print("   " .. n .. ": " .. (_G[n] and "existe" or "no"))
                end
                return
            end
            -- Se ensena para que el arte quede colocado. Va en pcall porque su OnShow pide datos
            -- de un entrenador que aqui no hay; si revienta, la geometria del XML ya esta puesta
            -- y la captura sigue valiendo.
            local vistoOk, vistoErr = pcall(function() f:Show() end)
            if not vistoOk then
                Print("Show fallo (esperable sin entrenador): " .. tostring(vistoErr):sub(1, 80))
            end
            local tag = label ~= "" and label or "nativo"
            API.RunCommand("probeframecapture", "ClassTrainerFrame " .. tag)
            -- No dejar la ventana nativa por medio: se abrio solo para poder medirla.
            pcall(function() f:Hide() end)
            Print("capturado ClassTrainerFrame como '" .. tag .. "'. Haz /reload para persistirlo.")
            Print("mostrado: " .. (f:IsShown() and "SI" or "no") ..
                "  tamano: " .. tostring(math.floor(f:GetWidth() or 0)) .. "x" ..
                tostring(math.floor(f:GetHeight() or 0)))
            return
        end

        if action == "rep" then
            local tag = label ~= "" and label or "base"
            API.RunCommand("probeframecapture", "ReputationFrame rep_" .. tag)
            if _G.ReputationDetailFrame and _G.ReputationDetailFrame:IsShown() then
                API.RunCommand("probeframecapture", "ReputationDetailFrame repdetalle_" .. tag)
            end
            return
        end

        if action == "prof" then
            local tag = label ~= "" and label or "ultima"
            CaptureNativeProfession(tag)
            local frameName = VisibleProfFrame()
            if frameName then
                API.RunCommand("probeframecapture", frameName .. " prof_" .. tag)
            else
                Print("Sin frame de profesion visible: solo se guardo la captura de datos (nativeProfessionProbes)")
            end
            return
        end

        if action == "sound" then
            local sub = label:lower()
            if sub == "on" then
                EnsureSoundHooks()
                _G.HARFORD_SOUNDLOG = true
                Print("soundlog ON: cada PlaySound se imprime y se guarda en HarfordDebugSettings.soundLog (max 400)")
            elseif sub == "off" then
                _G.HARFORD_SOUNDLOG = nil
                Print("soundlog OFF")
            elseif sub == "clear" then
                HarfordDebugSettings.soundLog = nil
                Print("soundlog limpiado")
            else
                local log = HarfordDebugSettings.soundLog or {}
                Print("soundlog: " .. #log .. " entradas (ultimas 20):")
                for i = math.max(1, #log - 19), #log do Print("  " .. log[i]) end
            end
            return
        end

        if action == "events" then
            local enabled = label:lower() ~= "off"
            _G.HARFORD_NATIVE_PROF_EVENTS = enabled
            for _, event in ipairs(NATIVE_PROF_EVENTS) do
                if enabled then nativeProfEvents:RegisterEvent(event) else nativeProfEvents:UnregisterEvent(event) end
            end
            Print("Eventos de profesion nativa: " .. (enabled and "ON" or "OFF"))
            return
        end

        if action == "profbook" then
            -- Captura la pestaña Profesiones del LIBRO DE HECHIZOS nativo (pergamino con los
            -- dos marcos primarios arriba y filas de secundarias abajo), para replicar su
            -- arte en Harford. Abrir el libro (P) en la pestaña Profesiones antes de capturar.
            local tag = label ~= "" and label or "profbook"
            local frame = _G.SpellBookProfessionFrame
            if not frame then
                Print("SpellBookProfessionFrame no existe en este cliente. Abre el libro de hechizos (P), pestaña Profesiones.")
                return
            end
            if not frame:IsShown() then
                Print("AVISO: SpellBookProfessionFrame esta oculto; abre la pestaña Profesiones para capturar estados reales.")
            end
            -- El pergamino/fondo lo pinta SpellBookFrame (paginas); los marcos, el frame de profesiones.
            API.RunCommand("probeframecapture", "SpellBookFrame libro_" .. tag)
            API.RunCommand("probeframecapture", "SpellBookProfessionFrame " .. tag)
            for _, name in ipairs({ "PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1", "SecondaryProfession2", "SecondaryProfession3" }) do
                if _G[name] then
                    API.RunCommand("probeframecapture", name .. " " .. tag)
                end
            end
            Print("Capturas de la pestaña Profesiones guardadas con etiqueta '" .. tag .. "'. Haz /reload para persistirlas.")
            return
        end

        if action == "harford" then
            -- Captura NUESTRA UI de profesiones (ventana de recetas + pagina del libro)
            -- con la misma sonda que el nativo, para diffear ambas capturas fuera del juego.
            local tag = label ~= "" and label or "nuestro"
            -- Si la ventana de recetas aun no existe, abrirla con la primera profesion
            -- conocida (o la primera del catalogo) para poder capturarla sin pasos previos.
            if not _G.HarfordProfessionsCraftFrame and HarfordProfessions and HarfordProfessionsCraftUI
                and HarfordProfessionsCraftUI.Open then
                local pick
                for _, def in ipairs(HarfordProfessions.GetProfessions() or {}) do
                    pick = pick or def.id
                    if HarfordProfessions.KnowsProfession and HarfordProfessions.KnowsProfession(def.id) then
                        pick = def.id
                        break
                    end
                end
                if pick then HarfordProfessionsCraftUI.Open(pick) end
            end
            local any = false
            if _G.HarfordProfessionsCraftFrame then
                API.RunCommand("probeframecapture", "HarfordProfessionsCraftFrame craft_" .. tag)
                any = true
            end
            if _G.HarfordSkillsPanelFrame then
                API.RunCommand("probeframecapture", "HarfordSkillsPanelFrame skills_" .. tag)
                any = true
            end
            -- La ventana de entrenador, para diffearla contra la captura de ClassTrainerFrame.
            -- Si no esta abierta se abre con el primer entrenador que tenga recetas.
            if not (_G.HarfordProfessionTrainerFrame and _G.HarfordProfessionTrainerFrame:IsShown())
                and HarfordProfessionTrainers and HarfordProfessionTrainerUI then
                local elegido
                for _, def in ipairs(HarfordProfessions and HarfordProfessions.GetProfessions() or {}) do
                    for _, rango in ipairs({ "aprendiz", "oficial", "experto" }) do
                        local id = def.id .. "_" .. rango
                        if not elegido and HarfordProfessionTrainers.Get
                            and HarfordProfessionTrainers.Get(id) then elegido = id end
                    end
                end
                if elegido then HarfordProfessionTrainerUI.Open(elegido) end
            end
            if _G.HarfordProfessionTrainerFrame then
                API.RunCommand("probeframecapture", "HarfordProfessionTrainerFrame trainer_" .. tag)
                any = true
            end
            if any then
                Print("Capturas Harford guardadas ('" .. tag .. "'). Haz /reload para persistirlas.")
            else
                Print("No se pudo crear la ventana de recetas (¿HarfordProfessions cargado?).")
            end
            return
        end

        if action == "stbm" then
            -- Sonda del StatusTrackingBarManager: para integrar la barra de XP Harford
            -- en el gestor nativo (que recoloca la UI al aparecer/desaparecer barras).
            local mgr = _G.StatusTrackingBarManager
            if not mgr then Print("StatusTrackingBarManager: NO existe") return end
            Print("StatusTrackingBarManager existe; shown=" .. tostring(mgr:IsShown()) .. " h=" .. tostring(math.floor((mgr:GetHeight() or 0) + 0.5)))
            Print("parent=" .. tostring(mgr:GetParent() and mgr:GetParent():GetName()))
            for _, k in ipairs({ "AddBarFromTemplate", "UpdateBarsShown", "LayoutBars", "SetBarSize", "GetNumberVisibleBars", "HideStatusBars", "SetTextLocked" }) do
                Print("  mgr." .. k .. " = " .. type(mgr[k]))
            end
            local bars = mgr.bars
            Print("mgr.bars = " .. type(bars) .. (type(bars) == "table" and (" (" .. #bars .. ")") or ""))
            if type(bars) == "table" then
                for i, b in ipairs(bars) do
                    Print(string.format("  bar%d: %s prio=%s visible=%s", i, tostring(b:GetName() or "(anon)"),
                        tostring(b.GetPriority and b:GetPriority() or "?"), tostring(b.ShouldBeVisible and b:ShouldBeVisible())))
                    for _, k in ipairs({ "ShouldBeVisible", "GetPriority", "Update", "SetBarText", "SetBarValues", "ShowText", "HideText", "StatusBar" }) do
                        if b[k] ~= nil then Print("    ." .. k .. " = " .. type(b[k])) end
                    end
                end
            end
            for _, tpl in ipairs({ "StatusTrackingBarTemplate", "ExpStatusBarTemplate", "ReputationStatusBarTemplate", "HonorStatusBarTemplate" }) do
                local ok = pcall(CreateFrame, "FRAME", nil, UIParent, tpl)
                Print("template " .. tpl .. ": " .. (ok and "OK" or "NO"))
            end
            -- `stbm update`: fuerza UpdateBarsShown SIN tragarse el error, para ver que
            -- metodo/paso exacto falla al maquetar la barra Harford.
            if label:lower() == "update" then
                local ok, err = pcall(mgr.UpdateBarsShown, mgr)
                Print("UpdateBarsShown -> " .. (ok and "OK" or ("|cffff5555ERROR:|r " .. tostring(err))))
                Print("mgr shown=" .. tostring(mgr:IsShown()) .. " h=" .. tostring(mgr:GetHeight()))
                if type(mgr.bars) == "table" then
                    local last = mgr.bars[#mgr.bars]
                    if last then
                        Print(string.format("ultima barra: metodos SVB=%s prio=%s Update=%s shown=%s",
                            type(last.ShouldBeVisible), type(last.GetPriority), type(last.Update), tostring(last:IsShown())))
                    end
                end
            end
            return
        end
        Print("Uso: nativeprobe status | rep [etiqueta] | prof [etiqueta] | profbook [etiqueta] | harford [etiqueta] | stbm [update] | sound on|off|show|clear | events on|off")
    end, "investigacion de frames nativos (reps/profesiones): status | rep | prof | sound | events")
end

-- Busca sonidos en la tabla SOUNDKIT del PROPIO cliente: es la fuente autoritativa para
-- Epsilon (Wowhead lista los de retail y no coinciden necesariamente). Sin patron busca los
-- de profesion/crafteo. `play <NOMBRE|id>` los audiciona para elegir por oido.
API.RegisterCommand("soundkits", function(args)
    local action, rest = tostring(args or ""):match("^%s*(%S*)%s*(.-)%s*$")
    if type(SOUNDKIT) ~= "table" then
        Print("SOUNDKIT no existe en este cliente")
        return
    end

    if action:lower() == "play" then
        local kit = tonumber(rest) or SOUNDKIT[rest] or SOUNDKIT[rest:upper()]
        if not kit then Print("No encuentro el sonido: " .. tostring(rest)); return end
        local ok = PlaySound and select(1, pcall(PlaySound, kit, "Master"))
        Print(string.format("Reproduciendo %s (%d): %s", tostring(rest), kit, ok and "OK" or "fallo"))
        return
    end

    local patterns = action ~= "" and { action:upper() }
        or { "TRADESKILL", "PROFESSION", "CRAFT", "FORGE", "ANVIL", "ALCHEMY", "ENCHANT" }
    local found = {}
    for name, id in pairs(SOUNDKIT) do
        if type(name) == "string" and type(id) == "number" then
            for _, p in ipairs(patterns) do
                if name:upper():find(p, 1, true) then
                    found[#found + 1] = { name = name, id = id }
                    break
                end
            end
        end
    end
    table.sort(found, function(a, b) return a.name < b.name end)
    Print(string.format("SOUNDKIT: %d coincidencias para %s", #found, table.concat(patterns, "/")))
    for _, e in ipairs(found) do
        Print(string.format("  %-46s = %d", e.name, e.id))
    end
    if #found == 0 then
        Print("Prueba con otro patron, p.ej.: soundkits UI")
    else
        Print("Audiciona uno con: soundkits play <NOMBRE>")
    end
end, "lista los SOUNDKIT del cliente por patron (crafteo por defecto) y los audiciona")

API.RegisterCommand("courier", function()
    local st = HarfordCourier and HarfordCourier.GetStatus and HarfordCourier.GetStatus()
    if not st then Print("HarfordCourier no disponible"); return end
    Print(string.format("Courier ready=%s canal=%s aceComm=%s outbox=%d seen=%d",
        tostring(st.ready), tostring(st.channelIndex), tostring(st.aceComm), st.outbox, st.seen))
end, "estado del bus HarfordCourier")

API.RegisterCommand("couriertest", function(args)
    local target, text = tostring(args or ""):match("^(%S+)%s*(.*)$")
    if not target or target == "" then Print("Uso: /harford debug run couriertest <Jugador> [texto]"); return end
    if not (HarfordCourier and HarfordCourier.Send) then Print("HarfordCourier no disponible"); return end
    local id = HarfordCourier.Send(target, "DEBUGPING", (text ~= "" and text) or "ping de prueba")
    Print("Courier: enviado (id=" .. tostring(id) .. ") a " .. target)
end, "envia un DEBUGPING fiable a un jugador")

API.RegisterCommand("tcboarddebug", function()
    _G.HARFORD_TCBOARD_DEBUG = not _G.HARFORD_TCBOARD_DEBUG
    Print("Diagnostico de sync del tablon: " .. (_G.HARFORD_TCBOARD_DEBUG and "ON" or "OFF"))
end, "toggle logging de sincronizacion del tablon de contratos")

API.RegisterCommand("contractsclear", function(args)
    if tostring(args or ""):gsub("%s+", "") ~= "confirm" then
        Print("Vacia TODO el tablon de contratos de ESTE cliente (irreversible). Confirma: contractsclear confirm")
        return
    end
    if not (HarfordContracts and HarfordContracts.Data and HarfordContracts.Data.ClearAllContracts) then
        Print("Tablon de contratos no disponible"); return
    end
    local n = HarfordContracts.Data.ClearAllContracts()
    Print("Tablon vaciado: " .. tostring(n) .. " contratos borrados. Crea el nuevo tablon y comparte para el grupo.")
end, "vacia TODOS los contratos del tablon (contractsclear confirm)")

API.RegisterCommand("contractsnet", function()
    if not (HarfordContracts and HarfordContracts.Comm and HarfordContracts.Comm.GetDebugStatus) then
        Print("HarfordContracts.Comm no disponible")
        return
    end
    local s = HarfordContracts.Comm.GetDebugStatus()
    Print("TCBOARD prefix: " .. tostring(s.prefix))
    Print("canal actual: " .. tostring(s.channel or "nil"))
    Print("DM/Admin activo: " .. tostring(s.dmMode == true))
    Print("chunk bytes/max chunks/ttl: " .. tostring(s.maxChunk) .. "/" .. tostring(s.maxChunks) .. "/" .. tostring(s.transferTTL) .. "s")
    Print("transferencias pendientes/chunks recibidos: " .. tostring(s.pendingTransfers) .. "/" .. tostring(s.receivedChunks))
    Print("snapshots pendientes: " .. tostring(s.pendingSnapshots or 0))
end, "estado de red del tablon de contratos")

-- Volcado profundo de un frame (por defecto CharacterFrame) a la SavedVariable
-- HarfordFrameProbe, para replicar UI nativa. Captura atlas (que el FrameDump externo
-- NO guarda), textura, texCoord, tamaño, anclajes, capa, color y texto. Uso:
--   /harford debug run probeframe            -> vuelca CharacterFrame
--   /harford debug run probeframe NombreFrame
--   /harford debug run probeframecapture PaperDollSidebarTabs tab1
--   /harford debug run probeframediff PaperDollSidebarTabs tab1 tab2
-- Luego /reload para que se escriba al disco, y se lee SavedVariables\Harford.lua.
do
    -- Las capturas no caducaban NUNCA y cada una de un frame grande ronda los 2,5 MB: 45 de
    -- ellas dejaron un HarfordDebug.lua de 27 MB, que WoW parsea entero en cada login. Un tope
    -- por numero no basta (8 capturas grandes ya son 20 MB), asi que el presupuesto va en nodos,
    -- que es lo que de verdad se escribe. Se echan las mas viejas por `capturedAt`.
    local PRESUPUESTO_NODOS = 60000
    local function PodarCapturas()
        local store = HarfordFrameProbe
        if type(store) ~= "table" or type(store.captures) ~= "table" then return end
        local todas = {}
        for frameName, porEtiqueta in pairs(store.captures) do
            if type(porEtiqueta) == "table" then
                for etiqueta, snap in pairs(porEtiqueta) do
                    todas[#todas + 1] = {
                        frame = frameName, etiqueta = etiqueta,
                        nodos = tonumber(type(snap) == "table" and snap.nodos) or 5000,
                        at = tonumber(type(snap) == "table" and snap.capturedAt) or 0,
                    }
                end
            end
        end
        local total = 0
        for _, c in ipairs(todas) do total = total + c.nodos end
        if total <= PRESUPUESTO_NODOS then return end

        table.sort(todas, function(a, b) return a.at < b.at end)
        local echadas = 0
        for _, c in ipairs(todas) do
            if total <= PRESUPUESTO_NODOS then break end
            store.captures[c.frame][c.etiqueta] = nil
            if not next(store.captures[c.frame]) then store.captures[c.frame] = nil end
            total = total - c.nodos
            echadas = echadas + 1
            Print(string.format("|cffffcc00Retirada la captura mas vieja:|r %s / %s (%d nodos)",
                c.frame, c.etiqueta, c.nodos))
        end
        if echadas > 0 then
            Print(string.format("Presupuesto de capturas: %d/%d nodos. Usa |cffffd100svclean frameprobe|r para vaciarlas todas.",
                total, PRESUPUESTO_NODOS))
        end
    end

    local function ProbeFrame(frameName, exportMode, captureLabel)
        frameName = tostring(frameName or ""):match("^%s*(%S+)") or ""
        if frameName == "" then frameName = "CharacterFrame" end
        local root = _G[frameName]
        if not root then
            Print("frame no encontrado: " .. frameName)
            return
        end

        local function safe(obj, method, ...)
            if not obj or not obj[method] then return nil end
            local ok, a, b, c, d, e, f, g, h = pcall(obj[method], obj, ...)
            if not ok then return nil end
            return a, b, c, d, e, f, g, h
        end
        local function pack(...)
            local n = select("#", ...)
            local t = {}
            for i = 1, n do t[i] = select(i, ...) end
            return t
        end
        local function packCall(obj, method, ...)
            if not obj or not obj[method] then return nil end
            local ok, a, b, c, d, e, f, g, h = pcall(obj[method], obj, ...)
            if not ok then return nil end
            return pack(a, b, c, d, e, f, g, h)
        end
        local function objectName(obj)
            return obj and obj.GetName and safe(obj, "GetName") or nil
        end
        -- IDENTIDAD DE CADA OBJETO. Casi ninguna region de Blizzard tiene nombre, asi que un
        -- anclaje "TOPLEFT > None.TOPLEFT" era irreconstruible: no se sabia a QUE apuntaba.
        -- Aqui cada objeto capturado recibe un uid ("f3.r2") y los anclajes guardan el uid del
        -- objetivo, de modo que el arbol se puede recrear mecanicamente sin adivinar nada.
        local uidOf = {}
        local function assignUid(obj, uid)
            if obj and uid then uidOf[obj] = uid end
        end
        local function getPoints(obj)
            local out = {}
            local n = safe(obj, "GetNumPoints") or 0
            for i = 1, n do
                local p, rel, rp, x, y = safe(obj, "GetPoint", i)
                out[i] = {
                    point = p, relativeTo = objectName(rel), relativePoint = rp, x = x, y = y,
                    relativeUid = rel and uidOf[rel] or nil,
                    relativeType = rel and safe(rel, "GetObjectType") or nil,
                }
            end
            return out
        end
        local function addCommon(e, obj)
            e.name = objectName(obj)
            e.objectType = safe(obj, "GetObjectType")
            e.alpha = safe(obj, "GetAlpha")
            e.effectiveScale = safe(obj, "GetEffectiveScale")
            e.shown = obj and obj.IsShown and safe(obj, "IsShown") or nil
            e.visible = obj and obj.IsVisible and safe(obj, "IsVisible") or nil
            e.points = getPoints(obj)
            if obj and obj.GetSize then e.width, e.height = safe(obj, "GetSize") end
            if obj and obj.GetRect then e.left, e.bottom, e.absWidth, e.absHeight = safe(obj, "GetRect") end
            if obj and obj.GetRight then e.right, e.top = safe(obj, "GetRight"), safe(obj, "GetTop") end
            if obj and obj.GetDrawLayer then e.drawLayer = packCall(obj, "GetDrawLayer") end
            if obj and obj.GetFrameStrata then e.frameStrata = safe(obj, "GetFrameStrata") end
            if obj and obj.GetFrameLevel then e.frameLevel = safe(obj, "GetFrameLevel") end
            if obj and obj.GetID then e.id = safe(obj, "GetID") end
            local parent = obj and obj.GetParent and safe(obj, "GetParent")
            if parent then e.parent = objectName(parent) end
            return e
        end
        local function dumpTexture(tex)
            if not tex then return nil end
            local e = addCommon({}, tex)
            if tex.GetAtlas then e.atlas = safe(tex, "GetAtlas") end
            if tex.GetTextureFileID then e.textureFileID = safe(tex, "GetTextureFileID") end
            if tex.GetTexture then e.texture = safe(tex, "GetTexture") end
            if tex.GetTexCoord then e.texCoord = packCall(tex, "GetTexCoord") end
            if tex.GetVertexColor then e.vertexColor = packCall(tex, "GetVertexColor") end
            if tex.GetBlendMode then e.blendMode = safe(tex, "GetBlendMode") end
            if tex.GetDesaturation then e.desaturation = safe(tex, "GetDesaturation") end
            return e
        end
        local function dumpFontString(fs)
            if not fs then return nil end
            local e = addCommon({}, fs)
            if fs.GetText then e.text = safe(fs, "GetText") end
            if fs.GetFont then e.font = packCall(fs, "GetFont") end
            if fs.GetTextColor then e.textColor = packCall(fs, "GetTextColor") end
            if fs.GetShadowColor then e.shadowColor = packCall(fs, "GetShadowColor") end
            if fs.GetShadowOffset then e.shadowOffset = packCall(fs, "GetShadowOffset") end
            if fs.GetJustifyH then e.justifyH = safe(fs, "GetJustifyH") end
            if fs.GetJustifyV then e.justifyV = safe(fs, "GetJustifyV") end
            if fs.GetSpacing then e.spacing = safe(fs, "GetSpacing") end
            if fs.GetWordWrap then e.wordWrap = safe(fs, "GetWordWrap") end
            if fs.GetNonSpaceWrap then e.nonSpaceWrap = safe(fs, "GetNonSpaceWrap") end
            if fs.GetIndentedWordWrap then e.indentedWordWrap = safe(fs, "GetIndentedWordWrap") end
            return e
        end
        local function signatureValue(value)
            if type(value) ~= "table" then return tostring(value) end
            local values = {}
            for i = 1, #value do values[#values + 1] = signatureValue(value[i]) end
            return "[" .. table.concat(values, ",") .. "]"
        end
        local function dumpRegions(frame)
            local regions = {}
            local ok, list = pcall(function() return { frame:GetRegions() } end)
            if not ok then return regions end
            for _, region in ipairs(list) do
                local ot = safe(region, "GetObjectType")
                local entry = addCommon({}, region)
                if ot == "Texture" then
                    entry = dumpTexture(region)
                elseif ot == "FontString" then
                    entry = dumpFontString(region)
                end
                -- Las regiones de Blizzard suelen carecer de nombre. Esta firma es
                -- estable entre estados aunque GetRegions cambie su orden interno.
                local point = entry.points and entry.points[1] or {}
                entry.probeKey = table.concat({
                    tostring(entry.objectType or "?"),
                    tostring(entry.drawLayer and entry.drawLayer[1] or "?"),
                    tostring(entry.atlas or entry.textureFileID or entry.texture or "?"),
                    signatureValue(entry.texCoord),
                    tostring(point.point or "?"),
                    tostring(point.x or 0),
                    tostring(point.y or 0),
                }, ":")
                entry.uid = uidOf[region]
                regions[#regions + 1] = entry
            end
            return regions
        end
        local function dumpButtonTextures(frame)
            local out = {}
            local methods = {
                normal = "GetNormalTexture",
                pushed = "GetPushedTexture",
                highlight = "GetHighlightTexture",
                disabled = "GetDisabledTexture",
                checked = "GetCheckedTexture",
            }
            for key, method in pairs(methods) do
                local tex = safe(frame, method)
                if tex then out[key] = dumpTexture(tex) end
            end
            return next(out) and out or nil
        end
        local function dumpStatusBar(frame)
            if not (frame and frame.GetStatusBarTexture) then return nil end
            return {
                minMax = packCall(frame, "GetMinMaxValues"),
                value = safe(frame, "GetValue"),
                color = packCall(frame, "GetStatusBarColor"),
                orientation = safe(frame, "GetOrientation"),
                reverseFill = frame.GetReverseFill and safe(frame, "GetReverseFill") or nil,
                texture = dumpTexture(safe(frame, "GetStatusBarTexture")),
            }
        end
        local function dumpScrollFrame(frame)
            if not (frame and frame.GetScrollChild) then return nil end
            local child = safe(frame, "GetScrollChild")
            return {
                child = objectName(child),
                horizontalScroll = frame.GetHorizontalScroll and safe(frame, "GetHorizontalScroll") or nil,
                verticalScroll = frame.GetVerticalScroll and safe(frame, "GetVerticalScroll") or nil,
                horizontalRange = frame.GetHorizontalScrollRange and safe(frame, "GetHorizontalScrollRange") or nil,
                verticalRange = frame.GetVerticalScrollRange and safe(frame, "GetVerticalScrollRange") or nil,
            }
        end
        -- Primera pasada: registrar la identidad de todo el arbol. Sin esto, un anclaje a un
        -- objeto que aun no se ha visitado no se podria resolver.
        local function indexTree(frame, uid, depth)
            assignUid(frame, uid)
            local okR, regions = pcall(function() return { frame:GetRegions() } end)
            if okR then
                for i, region in ipairs(regions) do assignUid(region, uid .. ".r" .. i) end
            end
            if depth < 8 and frame.GetChildren then
                local okC, children = pcall(function() return { frame:GetChildren() } end)
                if okC then
                    for i, child in ipairs(children) do
                        indexTree(child, uid .. ".f" .. i, depth + 1)
                    end
                end
            end
        end
        indexTree(root, "root", 0)

        local nodosVolcados = 0
        local function dumpFrame(frame, depth, uid)
            nodosVolcados = nodosVolcados + 1
            local node = addCommon({ children = {} }, frame)
            node.uid = uid or uidOf[frame]
            node.enabled = frame.IsEnabled and safe(frame, "IsEnabled") or nil
            node.mouseEnabled = frame.IsMouseEnabled and safe(frame, "IsMouseEnabled") or nil
            node.movable = frame.IsMovable and safe(frame, "IsMovable") or nil
            node.regions = dumpRegions(frame)
            node.statusBar = dumpStatusBar(frame)
            node.buttonTextures = dumpButtonTextures(frame)
            node.scrollFrame = dumpScrollFrame(frame)
            if depth < 8 and frame.GetChildren then
                local ok, children = pcall(function() return { frame:GetChildren() } end)
                if ok then
                    for i, child in ipairs(children) do
                        node.children[#node.children + 1] = dumpFrame(child, depth + 1, (uid or "root") .. ".f" .. i)
                    end
                end
            end
            return node
        end

        local snapshot = { frame = frameName, capturedAt = time and time() or 0, tree = dumpFrame(root, 0, "root") }
        snapshot.nodos = nodosVolcados
        captureLabel = tostring(captureLabel or ""):match("^%s*(.-)%s*$")
        if captureLabel ~= "" then
            HarfordFrameProbe = type(HarfordFrameProbe) == "table" and HarfordFrameProbe or {}
            HarfordFrameProbe.captures = type(HarfordFrameProbe.captures) == "table" and HarfordFrameProbe.captures or {}
            HarfordFrameProbe.captures[frameName] = type(HarfordFrameProbe.captures[frameName]) == "table"
                and HarfordFrameProbe.captures[frameName] or {}
            HarfordFrameProbe.captures[frameName][captureLabel] = snapshot
            Print(string.format("captura '%s' de %s guardada (%d nodos). Haz /reload para escribirla.",
                captureLabel, frameName, nodosVolcados))
            PodarCapturas()
        elseif exportMode then
            HarfordFrameProbe = type(HarfordFrameProbe) == "table" and HarfordFrameProbe or {}
            HarfordFrameProbe.exports = type(HarfordFrameProbe.exports) == "table" and HarfordFrameProbe.exports or {}
            HarfordFrameProbe.exports[frameName] = snapshot
            HarfordFrameProbe.frame = frameName
            HarfordFrameProbe.tree = snapshot.tree
        else
            HarfordFrameProbe = snapshot
        end
        Print("volcado completo de '" .. frameName .. "' a HarfordFrameProbe. Haz /reload para escribirlo.")
    end

    API.RegisterCommand("probeframe", function(args)
        ProbeFrame(args, false)
    end, "vuelca un frame completo (def. CharacterFrame) a HarfordFrameProbe")

    API.RegisterCommand("probeframeexport", function(args)
        ProbeFrame(args, true)
    end, "vuelca y conserva un frame en HarfordFrameProbe.exports")

    API.RegisterCommand("probeframecapture", function(args)
        local frameName, label = tostring(args or ""):match("^%s*(%S+)%s+(%S+)%s*$")
        if not frameName or not label then
            Print("uso: probeframecapture <NombreFrame> <etiqueta>")
            return
        end
        ProbeFrame(frameName, false, label)
    end, "guarda un estado etiquetado para compararlo despues")

    local function ValueText(value)
        if type(value) ~= "table" then return tostring(value) end
        local values = {}
        for i = 1, #value do values[#values + 1] = ValueText(value[i]) end
        return "[" .. table.concat(values, ",") .. "]"
    end

    local function SameValue(a, b)
        return ValueText(a) == ValueText(b)
    end

    local function IndexProbeNode(node, path, output)
        if type(node) ~= "table" then return end
        output[path] = node
        for i, region in ipairs(node.regions or {}) do
            IndexProbeNode(region, path .. "/region:" .. (region.name or region.probeKey or i), output)
        end
        for i, child in ipairs(node.children or {}) do
            IndexProbeNode(child, path .. "/child:" .. (child.name or i), output)
        end
    end

    API.RegisterCommand("probeframediff", function(args)
        local frameName, beforeLabel, afterLabel = tostring(args or ""):match("^%s*(%S+)%s+(%S+)%s+(%S+)%s*$")
        local captures = type(HarfordFrameProbe) == "table" and HarfordFrameProbe.captures
        local before = captures and captures[frameName] and captures[frameName][beforeLabel]
        local after = captures and captures[frameName] and captures[frameName][afterLabel]
        if not before or not after then
            Print("faltan capturas. Uso: probeframediff <Frame> <antes> <despues>")
            return
        end

        local oldNodes, newNodes = {}, {}
        IndexProbeNode(before.tree, frameName, oldNodes)
        IndexProbeNode(after.tree, frameName, newNodes)
        local fields = { "shown", "visible", "enabled", "alpha", "drawLayer", "texture", "textureFileID", "atlas", "texCoord", "vertexColor", "blendMode" }
        local changes, seen = {}, {}
        for path, oldNode in pairs(oldNodes) do
            local newNode = newNodes[path]
            if newNode then
                for _, field in ipairs(fields) do
                    if not SameValue(oldNode[field], newNode[field]) then
                        changes[#changes + 1] = path .. " | " .. field .. ": "
                            .. ValueText(oldNode[field]) .. " -> " .. ValueText(newNode[field])
                    end
                end
            end
            seen[path] = true
        end
        for path in pairs(newNodes) do
            if not seen[path] then changes[#changes + 1] = path .. " | aparece" end
        end

        Print("diferencias " .. beforeLabel .. " -> " .. afterLabel .. ": " .. tostring(#changes))
        for i = 1, math.min(#changes, 20) do Print("  " .. changes[i]) end
        if #changes > 20 then Print("  ... " .. tostring(#changes - 20) .. " mas (guardadas en HarfordFrameProbe).") end
    end, "compara dos capturas: probeframediff <Frame> <antes> <despues>")

    API.RegisterCommand("probeframeclear", function()
        HarfordFrameProbe = nil
        Print("HarfordFrameProbe limpiado. Haz /reload para escribir el cambio.")
    end, "limpia HarfordFrameProbe")
end

API.RegisterCommand("soundprobe", function(args)
    if not (HarfordUISounds and HarfordUISounds.Probe) then
        Print("HarfordUISounds no disponible")
        return
    end
    local id, kind, channel = tostring(args or ""):match("^%s*(%d+)%s*(%S*)%s*(%S*)%s*$")
    if not id then
        Print("uso: soundprobe <ID> [file|soundkit|both] [SFX|Master]")
        return
    end
    local results, err = HarfordUISounds.Probe(tonumber(id), kind ~= "" and kind or "both", channel ~= "" and channel or "SFX")
    if not results then
        Print("sonido " .. tostring(id) .. ": " .. tostring(err))
        return
    end
    for _, result in ipairs(results) do
        Print("sonido " .. tostring(id) .. " como " .. result.kind .. ": "
            .. (result.played and "ACEPTADO" or "NO aceptado")
            .. " (willPlay=" .. tostring(result.willPlay) .. ", handle=" .. tostring(result.handle) .. ")")
    end
end, "prueba ID como file, soundkit o ambos: soundprobe <ID> [tipo] [canal]")

API.RegisterCommand("soundevent", function(args)
    local event = tostring(args or ""):match("^%s*(%S+)%s*$")
    local entry = event and HarfordUISounds and HarfordUISounds.SOUNDS and HarfordUISounds.SOUNDS[event]
    if not entry then
        Print("evento no registrado: " .. tostring(event or ""))
        return
    end
    local played = HarfordUISounds.Play(event)
    Print("evento " .. event .. " -> id=" .. tostring(entry.id) .. " tipo=" .. tostring(entry.kind)
        .. " resultado=" .. (played and "ACEPTADO" or "NO aceptado"))
end, "prueba un evento registrado: soundevent <evento>")

API.RegisterCommand("booktab", function(args)
    if not (HarfordCharacterPanel and HarfordCharacterPanel.ApplyTabSkin) then
        Print("HarfordCharacterPanel no disponible")
        return
    end
    local w, h, x, y, is = tostring(args or ""):match("^%s*(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)%s*(%-?%d*)")
    local ts = HarfordCharacterPanel.ApplyTabSkin(tonumber(w), tonumber(h), tonumber(x), tonumber(y), tonumber(is))
    Print(("tab skin: w=%d h=%d x=%d y=%d icon=%d (uso: booktab w h x y [iconsize])"):format(ts.w, ts.h, ts.x, ts.y, ts.is))
end, "ajusta en vivo el marco SpellBook-SkillLineTab de los tabs del Libro")

API.RegisterCommand("bookframe", function(args)
    if not (HarfordCharacterPanel and HarfordCharacterPanel.ApplyBookFrame) then
        Print("HarfordCharacterPanel no disponible")
        return
    end
    local kind, x1, y1, x2, y2 = tostring(args or ""):match("^%s*(%a+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    if not kind then
        Print("uso: bookframe <pasivo|activo|reaccion> <x1> <y1> <x2> <y2>  (caja en pixeles del sheet 256x256)")
        return
    end
    local fr = HarfordCharacterPanel.ApplyBookFrame(kind, tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2))
    if not fr then
        Print("categoria desconocida: " .. tostring(kind))
        return
    end
    Print(("bookframe %s: tc=%.4f,%.4f,%.4f,%.4f size=%dx%d"):format(kind, fr.tc[1], fr.tc[2], fr.tc[3], fr.tc[4], fr.w, fr.h))
end, "ajusta en vivo el marco (texCoord/size) de los botones del Libro por categoria")

-- ─── Barra de accion (HarfordActionBars) ─────────────────────────────────────
-- El aviso de inicio de turno se va a montar con el mismo material que usa DiceMaster: atlas
-- NATIVOS del cliente (BossBanner-*, LootBanner-*, *Scenario-TrackerHeader, bonusobjectives-bar-*)
-- mas una sola textura propia para los extremos del estandarte. Antes de construir nada hay que
-- saber cuales existen AQUI: un atlas que falta no borra la textura anterior, la deja como estaba,
-- que es la misma trampa que ya nos comimos con los iconos del Libro.
-- ─── ESPACIOS DE CONJURO ────────────────────────────────────────────────────
-- Los orbes salen solo en modo `slots` y agrupados por nivel, asi que "no veo nada" puede ser
-- cuatro cosas distintas: modo mana, sin niveles de lanzador, sin ancla donde colgarlos, o
-- dibujados donde no miras. Se separan aqui en vez de deducirlas.
API.RegisterCommand("espacios", function(args)
    local M = _G.HarfordDnDMana
    local function Si(v) return v and "|cff88ff88si|r" or "|cffff4444NO|r" end
    if not M then Print("|cffff5555HarfordDnDMana no cargado.|r") return end

    -- `IsEnabled` devuelve true con el MANA activo: la piramide es el caso CONTRARIO. Es la
    -- confusion que mas veces se ha colado al leer este modulo.
    local mana = M.IsEnabled and M.IsEnabled()
    Print("Modo de coste: |cffffcc00" .. (mana and "mana" or "espacios") .. "|r")
    if mana then
        Print("  En modo mana NO hay orbes, a proposito: no hay piramide que pintar.")
        Print("  Cambiar con: /harford config spell_cost_mode slots")
    end

    Print("--- la piramide ---")
    local maxNivel = (M.GetMaxSpellLevel and M.GetMaxSpellLevel()) or 0
    if maxNivel <= 0 then
        Print("  |cffff4444Ningun nivel de conjuro|r: sin niveles de lanzador no hay espacios.")
    end
    local total = 0
    for nivel = 1, maxNivel do
        local quedan, tope = M.GetSpellSlotCurrent and M.GetSpellSlotCurrent(nivel)
        tope = tonumber(tope) or 0
        if tope > 0 then
            total = total + tope
            Print(string.format("  nivel %d: |cff88ccff%s|r de %d", nivel, tostring(quedan), tope))
        end
    end
    -- El brujo suma sus espacios de PACTO a los normales de su nivel, no en reserva aparte: si
    -- esperas una fila separada, no la hay.
    if M.PACT_SLOTS and HarfordDnDProgression and HarfordDnDProgression.GetClassLevels then
        for _, e in ipairs(HarfordDnDProgression.GetClassLevels() or {}) do
            if tostring(e.classId) == "brujo" then
                local pacto = M.PACT_SLOTS[tonumber(e.level) or 0]
                Print("  |cff808080brujo nivel " .. tostring(e.level) .. ": "
                    .. (pacto and (pacto.count .. " de pacto de nivel " .. pacto.level
                        .. ", ya sumados arriba") or "sin tabla") .. "|r")
            end
        end
    end
    Print("  total de espacios: " .. tostring(total))

    Print("--- donde se pintan ---")
    local B = _G.HarfordActionBars
    local fichas, orbes = 0, 0
    if B and B.RefreshTurnEconomy then fichas, orbes = B.RefreshTurnEconomy() end
    Print("  orbes dibujados: " .. tostring(orbes))
    local cont = _G.HarfordTurnEconomyFrame
    if not cont then
        Print("  |cffff4444El contenedor no existe.|r")
        return
    end
    Print("  visible: " .. Si(cont:IsShown())
        .. "   capa " .. tostring(cont:GetFrameStrata()) .. " nivel " .. tostring(cont:GetFrameLevel()))
    local izq, abajo = cont:GetLeft(), cont:GetBottom()
    if izq and abajo then
        Print(string.format("  posicion: (%.0f, %.0f)  tam %.0fx%.0f",
            izq, abajo, cont:GetWidth() or 0, cont:GetHeight() or 0))
    else
        Print("  |cffff4444Sin posicion|r: no esta anclado a nada.")
    end
    if total > 0 and orbes == 0 then
        Print("  |cffff4444Hay espacios pero no se pintan|r: mira el modo y el ancla de arriba.")
    end

    -- Gastar y devolver uno, para ver que el orbe se apaga y se enciende de verdad: contar cuantos
    -- se dibujan no dice que reflejen lo que queda.
    if tostring(args or ""):find("probar") and maxNivel > 0 and M.SpendSpellSlot then
        for nivel = 1, maxNivel do
            local quedan, tope = M.GetSpellSlotCurrent(nivel)
            if (tonumber(quedan) or 0) > 0 then
                Print("Gastando un espacio de nivel " .. nivel .. "...")
                M.SpendSpellSlot(nivel)
                Print("  quedan " .. tostring((M.GetSpellSlotCurrent(nivel))) .. " de " .. tostring(tope))
                Print("  |cffffcc00Miralo, y devuelvelo con:|r /harford debug run espacios devolver " .. nivel)
                return
            end
        end
        Print("No queda ningun espacio que gastar.")
    end
    -- No hay `RestoreSpellSlot`: los espacios vuelven con el descanso, no de uno en uno. Para
    -- probar se baja el contador de gastados a mano, que es lo mismo que hace el descanso.
    local devolver = tonumber(tostring(args or ""):match("devolver%s+(%d+)") or "")
    if devolver and HarfordDnDProgression and HarfordDnDProgression.GetSpellSlotsSpent then
        local gastados = HarfordDnDProgression.GetSpellSlotsSpent(devolver)
        if (tonumber(gastados) or 0) > 0 then
            HarfordDnDProgression.SetSpellSlotsSpent(devolver, gastados - 1)
            Print("Devuelto un espacio de nivel " .. devolver .. ".")
        else
            -- Si se gasto el de PACTO, el contador que bajo fue el suyo, no este.
            local pacto = HarfordDnDProgression.GetPactSpent and HarfordDnDProgression.GetPactSpent()
            if (tonumber(pacto) or 0) > 0 then
                HarfordDnDProgression.SetPactSpent(pacto - 1)
                Print("Devuelto un espacio de PACTO (era el que se habia gastado).")
            else
                Print("No habia ninguno gastado de ese nivel.")
            end
        end
        if B and B.RefreshTurnEconomy then B.RefreshTurnEconomy() end
    end
end, "Los espacios de conjuro: cuantos hay, y por que no se ven (espacios [probar|devolver N])")

-- ─── POR QUE SE BORRO EL COMBATE ────────────────────────────────────────────
-- Una limpieza silenciosa que se lleva un combate en curso es indistinguible de un fallo. Esto
-- dice si limpio, por que, y que habria hecho AHORA con lo que hay guardado.
API.RegisterCommand("combate", function()
    local T = _G.HarfordTurnOrderAPI
    local store = _G.HarfordTurnOrderStore
    if not (T and type(store) == "table") then Print("Turnos no cargados.") return end

    Print("--- lo que hay guardado ---")
    Print("  estado: |cffffcc00" .. tostring(store.estado or "sin combate") .. "|r"
        .. "   asalto: " .. tostring(store.asalto or 0)
        .. "   entradas: " .. tostring(#(store.entries or {})))
    local sello = tonumber(store.lastTouched) or 0
    local ahora = (time and time()) or 0
    -- SIN sello se purga siempre, sin mirar la hora: es lo que hay de antes de existir la
    -- caducidad. Si sale 0 en un combate en curso, eso es la averia.
    if sello <= 0 then
        Print("  |cffff5555sin sello|r: se purga al entrar sin mirar la hora.")
    else
        Print(string.format("  sellada hace %.0f s (%.1f min)", ahora - sello, (ahora - sello) / 60))
    end
    local mando = T.IsTurnAdmin and T.IsTurnAdmin()
    -- El DM tiene mas margen porque su copia es la buena y nadie se la devuelve.
    Print("  mandas: " .. (mando and "|cff88ff88si|r (limite 4 h)" or "no (limite 15 min)"))

    -- Quien deberia estar iluminado. En BANDOS lo decide `activeBando`; en individual,
    -- `activeIndex`. Son variables distintas para la misma pregunta, y mirar la que no es deja la
    -- marca clavada donde estaba.
    Print("--- a quien le toca ---")
    Print("  modo: |cffffcc00" .. (store.modoBandos and "bandos" or "individual") .. "|r")
    if store.modoBandos then
        local i = tonumber(store.activeBando) or 0
        local bando = i >= 1 and T.BANDOS and T.BANDOS[i] or nil
        Print("  activeBando: " .. tostring(i) .. " -> " .. tostring(bando or "ninguno")
            .. "   fase: " .. tostring(store.faseBando or "-"))
        if not bando then
            Print("  |cffff5555Sin bando activo|r: nada que iluminar. Dale a Siguiente.")
        end
    else
        Print("  activeIndex: " .. tostring(store.activeIndex or 0))
    end
    for i, e in ipairs(store.entries or {}) do
        local suyo = T.GetBando and T.GetBando(e) or "?"
        local marcada
        if store.modoBandos then
            local j = tonumber(store.activeBando) or 0
            local bando = j >= 1 and T.BANDOS and T.BANDOS[j] or nil
            marcada = bando ~= nil and tostring(e.kind or "") ~= "round" and suyo == bando
        else
            marcada = (i == store.activeIndex)
        end
        Print(string.format("  %d. %-18s kind=%-8s bando=%-10s %s", i,
            tostring(e.name or "?"), tostring(e.kind or "?"), tostring(suyo),
            marcada and "|cff88ff88<- ACTIVA|r" or ""))
    end

    local p = T.ultimaPurga
    Print("--- la ultima limpieza ---")
    if not p then
        Print("  |cff88ff88no ha limpiado nada|r en esta sesion.")
    else
        Print(string.format("  motivo: |cffff5555%s|r   sello=%s  hace %.0f s  limite %.0f s",
            tostring(p.motivo), tostring(p.sello), (p.ahora or 0) - (p.sello or 0), p.limite or 0))
        Print("  se llevo " .. tostring(p.entradas) .. " entrada(s), estado "
            .. tostring(p.estado or "nil") .. ", mandabas: " .. tostring(p.mandaba))
    end
end, "Por que se borro el combate al entrar")

-- ─── POR QUE NO ARRANCA SOLO EL MOVIMIENTO ──────────────────────────────────
-- El contador tiene que arrancar al empezar TU turno, sin pulsar nada. Son cuatro eslabones y si
-- falla uno no se ve: el aviso de turno, que la entrada sea TUYA, que el combate este activo y que
-- el seguimiento este montado. Se miden en vez de deducirlos.
API.RegisterCommand("movimiento", function(args)
    local U, T = _G.HarfordDnDAttackUI, _G.HarfordTurnOrderAPI
    local function Si(v) return v and "|cff88ff88si|r" or "|cffff4444NO|r" end

    Print("--- 1. El seguimiento esta montado? ---")
    Print("  HarfordDnDAttackUI: " .. Si(U ~= nil))
    if not U then return end
    -- Si esto falta, `AttachMovementTracker` no llego a correr y no hay quien escuche el turno.
    Print("  boton creado: " .. Si(U.Controls and U.Controls.movementButton ~= nil))
    Print("  reinicio expuesto: " .. Si(type(U.ResetTurnMovement) == "function"))

    Print("--- 2. El combate esta ACTIVO? ---")
    Print("  HarfordTurnOrderAPI: " .. Si(T ~= nil))
    if T then
        Print("  estado: |cffffcc00" .. tostring(T.GetCombatState and T.GetCombatState() or "?") .. "|r")
        Print("  HasActiveCombat(): " .. Si(T.HasActiveCombat and T.HasActiveCombat()))
        Print("  HasCombatants(): " .. Si(T.HasCombatants and T.HasCombatants()))
        -- Fuera de combate no arranca SOLO, a proposito: no hay turno que gastar.
        if T.HasActiveCombat and not T.HasActiveCombat() then
            Print("  |cffffcc00Sin combate activo no arranca solo|r: dale a Iniciar.")
        end
    end

    Print("--- 3. El aviso de turno llega? ---")
    local n = 0
    for _ in ipairs(T and T._myTurnListeners or {}) do n = n + 1 end
    -- Si hay cero, nadie se entera de que te toca: el contador no puede arrancar.
    Print("  oyentes de 'es tu turno': " .. tostring(n) .. (n > 0 and "" or "  |cffff4444(nadie escucha)|r"))
    -- Contar oyentes NO basta: pueden ser tres y ninguno el del movimiento. Se comprueba que el
    -- contador este entre ellos, que es lo que fallaba -- el registro dependia del orden de carga
    -- y `HarfordDnD` va ANTES que `HarfordTurns`.
    Print("  el motor esta SIEMPRE mostrado: "
        .. Si(_G.HarfordMovementDriver and _G.HarfordMovementDriver:IsShown()))
    local store = _G.HarfordTurnOrderStore
    if type(store) == "table" then
        Print("  modo: " .. (store.modoBandos and "bandos" or "individual")
            .. "   asalto: " .. tostring(store.asalto or 0))
        if store.modoBandos then
            Print("  bando activo: " .. tostring(store.activeBando or "-")
                .. "   fase: " .. tostring(store.faseBando or "-"))
        end
    end

    Print("--- 4. Cuanto se puede mover ---")
    Print("  tope del turno: " .. string.format("%.1f m",
        (U.GetTurnMovementMax and U.GetTurnMovementMax()) or 0))
    Print("  llevado: " .. string.format("%.1f m",
        (U.GetRecordedMovementMeters and U.GetRecordedMovementMeters()) or 0))
    -- Un tope de 0 esconde la barra y hace que el muro no salte nunca.
    if ((U.GetTurnMovementMax and U.GetTurnMovementMax()) or 0) <= 0 then
        Print("  |cffff4444Tope 0|r: sin raza puesta no hay velocidad que gastar.")
    end

    if tostring(args or ""):find("simular") then
        -- Dispara el aviso de turno a mano, que es el eslabon que no se puede provocar sin montar
        -- un combate entero. Si con esto arranca, lo que falla es que el aviso no llega.
        Print("Simulando 'es tu turno'...")
        for _, fn in ipairs(T and T._myTurnListeners or {}) do pcall(fn, {}) end
        Print("  llevado tras simular: " .. string.format("%.1f m",
            (U.GetRecordedMovementMeters and U.GetRecordedMovementMeters()) or 0))
        Print("  (muevete: deberia subir solo)")
    else
        Print("Para disparar el aviso a mano: |cffffcc00movimiento simular|r")
    end
end, "Por que no arranca solo el contador de movimiento (movimiento [simular])")

-- Los estilos de aviso de turno que hay, uno detras de otro. Elegir a ciegas entre nombres no
-- funciona: hay que VERLOS, y verlos seguidos para poder compararlos.
API.RegisterCommand("banners", function(args)
    local T = HarfordTurnOrderAPI
    if not (T and T.PreviewTurnBanner) then
        Print("HarfordTurnOrderAPI.PreviewTurnBanner no existe.")
        return
    end

    local ESTILOS = {
        { id = "estandarte", que = "Estandarte colgante, como el aviso de jefe" },
        { id = "franja",     que = "Franja discreta cruzando la pantalla" },
    }

    local pedido = tostring(args or ""):match("^%s*(%S*)")
    if pedido ~= "" then
        for _, e in ipairs(ESTILOS) do
            if e.id == pedido then
                Print("Estilo |cffffcc00" .. e.id .. "|r: " .. e.que)
                T.PreviewTurnBanner(e.id, "ES TU TURNO", "Asalto 3", true)
                return
            end
        end
        Print("No conozco el estilo '" .. pedido .. "'.")
    end

    Print("Estilos disponibles (se ven uno detras de otro):")
    for _, e in ipairs(ESTILOS) do
        local puesto = HarfordConfig and HarfordConfig.Get
            and HarfordConfig.Get("turnbanner") == e.id
        Print("  |cffffcc00" .. e.id .. "|r" .. (puesto and " |cff88ff88(puesto)|r" or "")
            .. " - " .. e.que)
    end
    Print("  |cffffcc00off|r - sin aviso")
    Print("Se pone con: /harford config turnbanner <estilo>")

    -- Uno cada cinco segundos: el aviso dura cuatro y hace falta verlo entero antes del siguiente.
    -- `C_Timer.After` de una vez por estilo, sin ticker.
    for i, e in ipairs(ESTILOS) do
        C_Timer.After((i - 1) * 5, function()
            Print("Mostrando |cffffcc00" .. e.id .. "|r")
            -- `esMio` a true en los dos: las tarjetas de opcion solo salen en TU turno, y aqui se
            -- estan comparando estilos, no turnos ajenos.
            T.PreviewTurnBanner(e.id, "ES TU TURNO", e.que, true)
        end)
    end
end, "Ensena todos los estilos de aviso de turno (banners [estilo])")

-- El estandarte solo se ve cuando cambia el turno, que no es un momento que se pueda repetir a
-- voluntad para mirarle la animacion. Esto lo levanta a mano.
API.RegisterCommand("estandarte", function(args)
    if not (HarfordTurnOrderAPI and HarfordTurnOrderAPI.ShowTurnBanner) then
        Print("HarfordTurnOrderAPI.ShowTurnBanner no existe.")
        return
    end
    -- El chat escapa la barra vertical como `||`, asi que separar por ella dejaba la segunda
    -- pegada al subtitulo. Se separa por `;`, que el chat no toca.
    local texto = tostring(args or "")
    -- Primera palabra: el estilo, si es uno de los que hay. Asi se comparan sin dejar puesto
    -- ninguno, que es lo que se quiere al estar eligiendo.
    local estilo
    local primera = texto:match("^%s*(%S+)")
    if primera == "estandarte" or primera == "franja" then
        estilo = primera
        texto = texto:gsub("^%s*%S+%s*", "", 1)
    end
    local titulo, subtitulo = texto:match("^(.-)%s*;%s*(.+)$")
    titulo = titulo or (texto ~= "" and texto) or "ES TU TURNO"
    local ok = HarfordTurnOrderAPI.PreviewTurnBanner(estilo, titulo, subtitulo or "Asalto 1", true)
    if not ok then
        Print("No se pinto: mira `turnbanner` en la config y `/harford debug run atlas`.")
    end
end, "Prueba el aviso de turno (estandarte [estandarte|franja] <titulo> ; <subtitulo>)")

API.RegisterCommand("atlas", function(args)
    local lista = {
        -- El estandarte de jefe, COMPLETO: con los extremos se puede colgar en vertical, que es la
        -- forma que usa DiceMaster. Sin ellos solo sale la franja de en medio.
        "BossBanner-BgBanner-Mid", "BossBanner-BgBanner-Top", "BossBanner-BgBanner-Bottom",
        "BossBanner-RedLightning", "BossBanner-Title", "BossBanner-SkullCircle",
        "BossBanner-Skull", "BossBanner-BgGlow", "BossBanner-Shield",
        -- El titular de escenario: la otra forma nativa de anunciar una fase.
        "ScenarioTrackerToast", "Scenario-Stage-Banner",
        "AllianceScenario-TrackerHeader", "HordeScenario-TrackerHeader",
        "NeutralScenario-TrackerHeader",
        -- El toast de botin, para un aviso pequenio de esquina.
        "LootBanner-ItemBg", "LootBanner-IconGlow", "loottoast-glow",
        -- La barra de objetivo, para el temporizador de turno.
        "bonusobjectives-bar-frame", "bonusobjectives-bar-glow", "bonusobjectives-bar-sheen",
        "bonusobjectives-bar-starburst",
        -- El rotulo de la mision destacada y el marco de campania: dos titulares mas discretos.
        "QuestBonusObjective", "Campaign-QuestLog-LoreBG", "UI-Frame-Bar-InsetLeft",
    }
    -- Y los que pida quien lo llame, para probar uno suelto sin tocar el codigo.
    for extra in tostring(args or ""):gmatch("%S+") do lista[#lista + 1] = extra end

    -- Y las APIs nativas de aviso que aun no usamos. Un atlas se puede sustituir; una API que no
    -- existe no tiene apano, asi que hay que saberlo ANTES de disenar nada encima.
    for nombre, para in pairs({
        SpellActivationOverlay_ShowOverlay  = "fogonazo en los bordes de la pantalla",
        SpellActivationOverlay_HideOverlays = "retirarlo",
        TopBannerManager_Show               = "cola de titulares nativos",
        RaidNotice_AddMessage               = "aviso de raid (ya en uso)",
    }) do
        Print((type(_G[nombre]) == "function" and "|cff88ff88OK|r  " or "|cffff5555NO|r  ")
            .. nombre .. "  |cff808080" .. para .. "|r")
    end
    if AlertFrame and AlertFrame.AddExternallyAnchoredSubSystem then
        Print("|cff88ff88OK|r  AlertFrame:AddExternallyAnchoredSubSystem  |cff808080toast en cola|r")
    else
        Print("|cffff5555NO|r  AlertFrame:AddExternallyAnchoredSubSystem")
    end

    local hay, faltan = 0, 0
    for _, nombre in ipairs(lista) do
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(nombre)
        if info then
            hay = hay + 1
            Print(string.format("|cff88ff88OK|r  %-32s %dx%d", nombre,
                math.floor(info.width or 0), math.floor(info.height or 0)))
        else
            faltan = faltan + 1
            Print("|cffff5555NO|r  " .. nombre)
        end
    end
    Print(string.format("%d disponibles, %d ausentes.", hay, faltan))
end, "Comprueba que existan los atlas del estandarte de turno")

-- El muro de movimiento depende de un `worldport` que ni se ve fallar ni se ve llegar: si el
-- comando no existe en este servidor, o el mapa sale mal, desde fuera parece que el addon
-- simplemente no hace nada. Esto lo parte en dos: primero marca, luego devuelve.
API.RegisterCommand("worldport", function(args)
    local modo = tostring(args or ""):lower():match("^%s*(%S*)")
    _G.HarfordDebugWorldportAnchor = _G.HarfordDebugWorldportAnchor

    if modo ~= "volver" then
        if not (C_Epsilon and C_Epsilon.GetPosition) then
            Print("C_Epsilon.GetPosition no disponible.")
            return
        end
        local ok, x, y, z = pcall(C_Epsilon.GetPosition)
        if not ok or not tonumber(x) then
            Print("GetPosition fallo: " .. tostring(x))
            return
        end
        local okI, mapa = pcall(function() return select(8, GetInstanceInfo()) end)
        Print(string.format("Marcado: x=%.3f y=%.3f z=%.3f mapa=%s o=%.3f",
            tonumber(x), tonumber(y), tonumber(z) or 0,
            tostring(okI and mapa or "ERROR"), (GetPlayerFacing and GetPlayerFacing()) or 0))
        if not tonumber(okI and mapa) then
            Print("|cffff5555El mapa no es un numero:|r sin el no se emite nada.")
        end
        _G.HarfordDebugWorldportAnchor = {
            x = tonumber(x), y = tonumber(y), z = tonumber(z) or 0,
            map = tonumber(okI and mapa),
            o = (GetPlayerFacing and GetPlayerFacing()) or 0,
        }
        Print("Muevete y usa: /harford debug run worldport volver")
        return
    end

    local ancla = _G.HarfordDebugWorldportAnchor
    if not ancla then
        Print("No hay nada marcado. Usa /harford debug run worldport primero.")
        return
    end
    if not (HarfordServerActions and HarfordServerActions.WorldportSelf) then
        Print("|cffff5555HarfordServerActions.WorldportSelf no existe.|r")
        return
    end
    local ok, err = HarfordServerActions.WorldportSelf(ancla, { addonName = "HarfordDebug" })
    Print(ok and "Comando emitido."
        or ("|cffff5555No se emitio:|r " .. tostring(err or "error desconocido")))
end, "Marca tu sitio y te devuelve (worldport | worldport volver)")

API.RegisterCommand("actionbar", function()
    if not (HarfordActionBars and HarfordActionBars.Toggle) then
        Print("HarfordActionBars no disponible")
        return
    end
    Print("barra de accion: " .. (HarfordActionBars.Toggle() and "visible" or "oculta"))
end, "muestra/oculta la barra de accion de prueba")

API.RegisterCommand("actionbarsize", function(args)
    if not (HarfordActionBars and HarfordActionBars.SetGeometry) then
        Print("HarfordActionBars no disponible")
        return
    end
    local h, capW, slot, gap, count = tostring(args or ""):match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    local c = HarfordActionBars.SetGeometry(tonumber(h), tonumber(capW), tonumber(slot), tonumber(gap), tonumber(count))
    Print(("actionbarsize: h=%d capW=%d slot=%d gap=%d count=%d"):format(c.h, c.capW, c.slot, c.gap, c.count))
end, "ajusta altura/tapa/slot/hueco/nº de slots de la barra de accion")

API.RegisterCommand("actionbarset", function(args)
    if not (HarfordActionBars and HarfordActionBars.SetTestTexture) then
        Print("HarfordActionBars no disponible")
        return
    end
    local path = tostring(args or ""):match("^%s*(%S.-)%s*$")
    if not path then Print("uso: actionbarset <ruta de textura>") return end
    HarfordActionBars.SetTestTexture(path)
    Print("barra -> " .. path .. "  (si sale verde, esa textura NO existe en tu cliente)")
end, "prueba una ruta de textura en la barra de accion (verifica si carga)")

API.RegisterCommand("actionbarscan", function(args)
    if not GetFileIDFromPath then
        Print("GetFileIDFromPath no disponible en este cliente.")
        return
    end
    local one = tostring(args or ""):match("^%s*(%S.-)%s*$")
    if one then
        local id = GetFileIDFromPath(one)
        Print((id and id > 0) and ("EXISTE: " .. one .. " (id " .. id .. ")") or ("NO existe: " .. one))
        return
    end
    local candidates = {
        "Interface\\PlayerActionBarAlt\\spellbar-wood_center",
        "Interface\\ExtraButton\\ExtraButtonGeneric",
        "Interface\\ExtraButton\\Default",
        "Interface\\AchievementFrame\\UI-Achievement-WoodBorder-Corner",
        "Interface\\AchievementFrame\\UI-Achievement-WoodBorder-TopLeft",
        "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
        "Interface\\AchievementFrame\\UI-Achievement-Parchment",
        "Interface\\PetBattles\\Pet-Loadout-Frame",
        "Interface\\PetBattles\\PetBattleHUD",
        "Interface\\Garrison\\GarrisonUITiles",
        "Interface\\Archeology\\Arch-ProgressBar",
        "Interface\\QuestFrame\\QuestBG",
        "Interface\\BankFrame\\Bank-Background",
        "Interface\\FrameGeneral\\UI-Background-Rock",
        "Interface\\Spellbook\\Spellbook-Page-1",
    }
    Print("Texturas candidatas que EXISTEN en tu cliente:")
    local any = false
    for _, p in ipairs(candidates) do
        local id = GetFileIDFromPath(p)
        if id and id > 0 then Print("  |cff66ff66OK|r  " .. p); any = true end
    end
    if not any then Print("  (ninguna de la lista). Prueba rutas sueltas: actionbarscan <ruta>") end
end, "escanea que texturas de madera/barra existen en tu cliente (o comprueba una ruta)")

API.RegisterCommand("actionbarslots", function(args)
    if not (HarfordActionBars and HarfordActionBars.RestaurarBarra) then
        Print("HarfordActionBars no expone la barra nativa.") return
    end
    local sub = (args or ""):match("^%s*(%S+)")
    if sub == "limpiar" then
        HarfordActionBarStore = { botones = {} }
        for i = 1, 12 do
            local b = _G["ActionButton" .. i]
            if b and b:GetAttribute("type") == "harford" then HarfordActionBars.LimpiarBoton(b) end
        end
        Print("Ranuras Harford vaciadas.")
        return
    end
    Print("Ranuras con habilidad Harford:")
    local store = HarfordActionBarStore and HarfordActionBarStore.botones or {}
    local n = 0
    for ranura, id in pairs(store) do
        local d = HarfordCharacterPanel and HarfordCharacterPanel.DatosDeHabilidad
            and HarfordCharacterPanel.DatosDeHabilidad(id)
        Print(("  %s  =  %s  %s"):format(ranura, id, d and ("|cff66ff66" .. (d.name or "?") .. "|r")
            or "|cffff6666(ya no esta en tu ficha)|r"))
        n = n + 1
    end
    if n == 0 then Print("  (ninguna)") end
    Print(("Restauradas ahora: %d. En combate: %s"):format(
        HarfordActionBars.RestaurarBarra(), tostring(InCombatLockdown and InCombatLockdown())))
end, "lista las habilidades colocadas en la barra nativa (actionbarslots limpiar las quita)")

-- ─── Panel de personaje / inspeccion / items ─────────────────────────────────
API.RegisterCommand("trp3build", function()
    if HarfordCharacterPanel and HarfordCharacterPanel.RunTRP3BuildDiagnostic then
        HarfordCharacterPanel.RunTRP3BuildDiagnostic()
    else
        Print("HarfordCharacterPanel no disponible")
    end
end, "diagnostica clase/raza/trasfondo/rasgos TRP3 del panel de personaje")

API.RegisterCommand("inspecttarget", function()
    if HarfordCharacterPanel and HarfordCharacterPanel.OpenInspect then
        HarfordCharacterPanel.OpenInspect("target")
    elseif HarfordCharacterInspect and HarfordCharacterInspect.Request then
        HarfordCharacterInspect.Request("target")
    else
        Print("HarfordCharacterPanel/Inspect no disponible")
    end
end, "solicita e inspecciona el panel Harford del target jugador")

API.RegisterCommand("itemrules", function(args)
    if not (HarfordDnDItems and HarfordDnDItems.ResolveSlot) then
        Print("HarfordDnDItems no disponible")
        return
    end
    local slotKey = tostring(args or "")
    if slotKey == "" then slotKey = "MainHand" end
    local resolved = HarfordDnDItems.ResolveSlot(slotKey)
    if not resolved then
        Print("sin item equipado en " .. slotKey)
        return
    end
    Print("item " .. slotKey .. ": " .. tostring(resolved.name or resolved.itemLink or "-"))
    for _, rule in ipairs((resolved.rules and resolved.rules.list) or {}) do
        if rule.kind == "extraDamageDice" then
            Print(string.format("  regla: dano extra %s %s", tostring(rule.dice or "-"), tostring(rule.damageType or "")))
        else
            Print(string.format("  regla: %s %s %s", tostring(rule.kind or "-"), tostring(rule.key or ""), tostring(rule.value or 0)))
        end
    end
    for _, line in ipairs(resolved.descriptionLines or {}) do
        Print("  desc: " .. tostring(line))
    end
end, "muestra reglas parseadas desde la descripcion del item equipado en un slot")

API.RegisterCommand("maestroescudero", function()
    local profileName = HarfordClassColors and HarfordClassColors.UnitFullName
        and HarfordClassColors.UnitFullName("player") or (UnitName and UnitName("player"))
    local hasFeat = HarfordDnDProgression and HarfordDnDProgression.HasFeat
        and HarfordDnDProgression.HasFeat("maestro_escudero", profileName) or false
    local hasFlag = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("shieldBash", profileName) or false
    local shield = HarfordDnDItems and HarfordDnDItems.GetEquippedWeapon
        and HarfordDnDItems.GetEquippedWeapon("SecondaryHand", profileName) or nil
    local isShield = shield and shield.key == "Escudo" or false
    local offhand = HarfordDnDStore and HarfordDnDStore.GetOffhandActive
        and HarfordDnDStore.GetOffhandActive(shield) or false
    local available = HarfordDnDStore and HarfordDnDStore.IsOffhandAvailable
        and HarfordDnDStore.IsOffhandAvailable(shield) or false

    Print("Maestro Escudero: dote=" .. tostring(hasFeat)
        .. " flag=" .. tostring(hasFlag)
        .. " secundaria=" .. tostring(shield and (shield.itemName or shield.key) or "ninguna")
        .. " escudo=" .. tostring(isShield)
        .. " offhand=" .. tostring(offhand)
        .. " disponible=" .. tostring(available))
    if hasFlag and isShield then
        Print("Embate listo: 1d4 + Mod. Fuerza contundente; se aplica solo tras impactar.")
    elseif not hasFeat then
        Print("La ficha TRP3 no ha importado 'Maestro Escudero'. Usa cargarficha tras incluir la dote en el About.")
    elseif not isShield then
        Print("Equipa un escudo en la mano secundaria para habilitar el embate.")
    end
end, "verifica importacion y dano de Maestro Escudero")

API.RegisterCommand("perfitems", function(args)
    if not (HarfordDnDItems and HarfordDnDItems.GetPerfItems) then
        Print("HarfordDnDItems.GetPerfItems no disponible")
        return
    end
    local reset = tostring(args or ""):lower():match("reset") ~= nil
    local p = HarfordDnDItems.GetPerfItems(reset)
    Print("items: eventos=" .. tostring(p.events)
        .. " procesados=" .. tostring(p.processed)
        .. " ignorados=" .. tostring(p.ignored)
        .. " cache=" .. tostring(p.cache) .. "/" .. tostring(p.max)
        .. " pendientes=" .. tostring(p.pending or 0)
        .. " expulsados=" .. tostring(p.evicted))
    if reset then Print("contadores de items reiniciados.") end
end, "mide eventos GET_ITEM_INFO_RECEIVED procesados/ignorados por Harford")

API.RegisterCommand("sync", function()
    if not HarfordSync then
        Print("HarfordSync no disponible")
        return
    end

    Print("BestChannel: " .. tostring(HarfordSync.BestChannel and HarfordSync.BestChannel() or nil))
    Print("MAX_RESOURCE_MESSAGE_BYTES: " .. tostring(HarfordSync.MAX_RESOURCE_MESSAGE_BYTES))
end, "estado basico del transporte Harford")

API.RegisterCommand("areatest", function(args)
    local mode = tostring(args or ""):lower():match("^%s*(%S+)")
    mode = mode == "attack" and "attack" or "save"
    local withState = tostring(args or ""):lower():find("state", 1, true) ~= nil
    if not (HarfordDnDArea and HarfordDnDArea.Open) then
        Print("HarfordDnDArea no disponible")
        return
    end
    local definition = {
        title = "Prueba de area",
        area = {
            shape = "sphere",
            sizeText = "6 m",
            resolution = mode,
            saveAbility = "Destreza",
            dc = 13,
            success = "half",
            attackBonus = 5,
            damageComponents = {
                { damageDice = "2d6", damageBonus = 0, damageType = "fuego" },
                { damageDice = "1d4", damageBonus = 0, damageType = "necrotico" },
            },
            conditionId = withState and "burning" or nil,
            conditionDuration = withState and "save_at_turn_end" or nil,
            conditionSaveAbility = withState and "Constitucion" or nil,
            conditionSaveDC = withState and 13 or nil,
        },
    }
    local ok, err = HarfordDnDArea.Open(definition, { sourceKind = "debug" })
    Print(ok and ("selector de area abierto: " .. mode .. (withState and " + estado" or ""))
        or ("error: " .. tostring(err)))
end, "abre selector de prueba: areatest save|attack [state]")

API.RegisterCommand("conditiontest", function(args)
    if not HarfordDnDConditions then Print("HarfordDnDConditions no disponible"); return end
    local action, id = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")
    action = action ~= "" and action:lower() or "list"
    if action == "apply" and id ~= "" then
        local ok, err = HarfordDnDConditions.ApplyOwned(id, { persist = false })
        Print(ok and ("aplicada: " .. id) or ("error: " .. tostring(err)))
    elseif action == "remove" and id ~= "" then
        local ok, err = HarfordDnDConditions.RemoveOwned(id)
        Print(ok and ("retirada: " .. id) or ("error: " .. tostring(err)))
    else
        local active = HarfordDnDConditions.GetActive("player")
        local labels = {}
        for _, entry in ipairs(active) do labels[#labels + 1] = entry.id end
        Print("condiciones propias: " .. (#labels > 0 and table.concat(labels, ", ") or "ninguna"))
    end
end, "lista/aplica/retira condiciones propias: conditiontest list|apply ID|remove ID")

API.RegisterCommand("auth", function()
    if not HarfordAuthority or not HarfordAuthority.GetStatus then
        Print("HarfordAuthority no disponible")
        return
    end

    local status = HarfordAuthority.GetStatus()
    local function Bool(value)
        return value and "SI" or "NO"
    end

    Print("Admin addon: " .. Bool(status.adminAddon))
    Print("Phase ID: " .. tostring(status.phaseId or "desconocida"))
    Print("Phase member: " .. Bool(status.phaseMember))
    Print("Phase officer: " .. Bool(status.phaseOfficer))
    Print("Phase owner: " .. Bool(status.phaseOwner))
    Print("Member+: " .. Bool(status.memberPlus))
    Print("Officer+: " .. Bool(status.officerPlus))
    Print("DM mode (.ph dm): " .. Bool(status.dmMode))
    Print("DM enabled: " .. Bool(status.dmEnabled))
    Print("Puede comandos member: " .. Bool(status.canUseMemberCommands))
    Print("Puede comandos officer: " .. Bool(status.canUseOfficerCommands))
    Print("Puede comandos admin: " .. Bool(status.canUseAdminCommands))
    Print("Puede herramientas DM: " .. Bool(status.canUseDMTools))
end, "estado de permisos Harford/ARC")

API.RegisterCommand("authraw", function()
    local function RawBool(value)
        return tostring(value) .. " (" .. type(value) .. ")"
    end

    Print("raw C_Epsilon.IsDM: " .. RawBool(C_Epsilon and C_Epsilon.IsDM))
    if ARC and ARC.PHASE and ARC.PHASE.IsDM then
        local ok, value = pcall(ARC.PHASE.IsDM)
        Print("raw ARC.PHASE.IsDM(): " .. (ok and RawBool(value) or ("ERROR " .. tostring(value))))
    else
        Print("raw ARC.PHASE.IsDM(): no disponible")
    end
    if ARC and ARC.XAPI and ARC.XAPI.Phase and ARC.XAPI.Phase.IsDM then
        local ok, value = pcall(ARC.XAPI.Phase.IsDM)
        Print("raw ARC.XAPI.Phase.IsDM(): " .. (ok and RawBool(value) or ("ERROR " .. tostring(value))))
    else
        Print("raw ARC.XAPI.Phase.IsDM(): no disponible")
    end
    Print("HarfordAuthority.IsDMMode(): " .. RawBool(HarfordAuthority and HarfordAuthority.IsDMMode and HarfordAuthority.IsDMMode()))
    Print("raw C_Epsilon.IsOfficer(): " .. RawBool(C_Epsilon and C_Epsilon.IsOfficer and C_Epsilon.IsOfficer()))
    Print("raw C_Epsilon.IsOwner(): " .. RawBool(C_Epsilon and C_Epsilon.IsOwner and C_Epsilon.IsOwner()))
end, "valores raw de C_Epsilon/ARC para .ph dm")

API.RegisterCommand("phase", function()
    if not HarfordServerActions or not HarfordServerActions.GetPhaseInfo then
        Print("HarfordServerActions no disponible")
        return
    end

    HarfordServerActions.GetPhaseInfo(function(success, messages)
        Print("phase info: " .. (success and "OK" or "ERROR"))
        for _, line in ipairs(messages or {}) do
            Print(line)
        end
    end)
end, "prueba phase info via EpsilonLib")

API.RegisterCommand("raw", function(args)
    if not HarfordServerActions or not HarfordServerActions.SendRawDebug then
        Print("HarfordServerActions no disponible")
        return
    end

    if tostring(args or "") == "" then
        Print("uso: /harford debug run raw <comando>")
        return
    end

    HarfordServerActions.SendRawDebug(args, function(success, messages)
        Print("raw: " .. (success and "OK" or "ERROR"))
        for _, line in ipairs(messages or {}) do
            Print(line)
        end
    end)
end, "envia comando raw solo con debug activo")

do
    local function GetLastTRP3LinkInfo()
        if not HarfordTRP3 or not HarfordTRP3.GetLastGlanceLinkInfo then
            Print("HarfordTRP3.GetLastGlanceLinkInfo no disponible")
            return nil
        end

        local info = HarfordTRP3.GetLastGlanceLinkInfo()
        if not info then
            Print("No hay link de estado Harford creado. Haz shift-click en un estado ajeno primero.")
            return nil
        end
        if not info.hyperlink then
            Print("El link no tiene hyperlink local; no se pudo resolver el emisor TRP3.")
            return nil
        end
        return info
    end

    local function RequireNpcTarget()
        if not UnitExists or not UnitExists("target") then
            Print("Selecciona un NPC target antes de enviar la prueba.")
            return false
        end
        if UnitIsPlayer and UnitIsPlayer("target") then
            Print("El target es un jugador; la prueba npc te requiere un NPC.")
            return false
        end
        return true
    end

    local function PrintCommandResult(label)
        return function(success, messages)
            Print(label .. ": " .. (success and "OK" or "ERROR"))
            for _, line in ipairs(messages or {}) do
                Print(line)
            end
        end
    end

    API.RegisterCommand("trp3link", function()
        local info = GetLastTRP3LinkInfo()
        if not info then return end
        Print("TRP3 identifier: " .. tostring(info.identifier))
        Print("TRP3 sender: " .. tostring(info.sender))
        Print("TRP3 marker (" .. tostring(#info.marker) .. "): " .. tostring(info.marker))
        Print("TRP3 hyperlink (" .. tostring(#info.hyperlink) .. "):")
        Print(info.hyperlink)
        Print("npc te hyperlink bytes: " .. tostring(#("npc te " .. info.hyperlink)) .. " / limite <250")
    end, "muestra marker/hyperlink del ultimo estado ajeno Harford")

    API.RegisterCommand("trp3npctest", function(args)
        local mode = tostring(args or ""):lower():match("^%s*(%S+)")
        if mode ~= "marker" and mode ~= "hyperlink" and mode ~= "chat" then
            Print("uso: /harford debug run trp3npctest marker|hyperlink|chat")
            return
        end
        if not RequireNpcTarget() then return end
        local info = GetLastTRP3LinkInfo()
        if not info then return end

        if mode == "marker" then
            if not HarfordServerActions or not HarfordServerActions.SendRawDebug then
                Print("HarfordServerActions.SendRawDebug no disponible")
                return
            end
            HarfordServerActions.SendRawDebug(
                "npc te " .. info.marker,
                PrintCommandResult("npc te marker via EpsilonLib"),
                { addonName = "HarfordDebug" })
        elseif mode == "hyperlink" then
            if not HarfordServerActions or not HarfordServerActions.SendRawDebug then
                Print("HarfordServerActions.SendRawDebug no disponible")
                return
            end
            local command = "npc te " .. info.hyperlink
            if #command >= 250 then
                Print("npc te hyperlink supera el limite <250 de EpsilonLib: " .. tostring(#command))
                return
            end
            HarfordServerActions.SendRawDebug(
                command,
                PrintCommandResult("npc te hyperlink via EpsilonLib"),
                { addonName = "HarfordDebug" })
        else
            if not SendChatMessage then
                Print("SendChatMessage no disponible")
                return
            end
            Print("Enviando .npc te hyperlink por ruta de comando chat; EpsilonLib puede interceptarla segun configuracion.")
            SendChatMessage(".npc te " .. info.hyperlink, "GUILD")
        end
    end, "prueba npc te marker|hyperlink|chat con ultimo link Harford")
end

API.RegisterCommand("trp3icons", function()
    if not HarfordTRP3 or not HarfordTRP3.GetEpsilonNpcProfile then
        Print("HarfordTRP3 no disponible")
        return
    end

    local profile, err, fullID, npcID, phaseID = HarfordTRP3.GetEpsilonNpcProfile("target")
    Print("TRP3 NPC fullID: " .. tostring(fullID or "desconocido"))
    Print("TRP3 NPC npcID: " .. tostring(npcID or "desconocido"))
    Print("TRP3 NPC phaseID: " .. tostring(phaseID or "desconocida"))
    if not profile then
        Print(err or "perfil TRP3 NPC no disponible")
        return
    end

    local icon, rawIcon
    if HarfordTRP3.GetProfileIcon then icon, rawIcon = HarfordTRP3.GetProfileIcon(profile) end
    Print("TRP3 icon elegido: " .. tostring(rawIcon or icon or "nil"))

    if not HarfordTRP3.GetProfileIconCandidates then
        Print("GetProfileIconCandidates no disponible")
        return
    end

    local candidates = HarfordTRP3.GetProfileIconCandidates(profile)
    if #candidates == 0 then
        Print("sin candidatos de icono")
        return
    end

    for i, candidate in ipairs(candidates) do
        Print("candidato " .. tostring(i) .. ": " .. tostring(candidate.path) .. " = " .. tostring(candidate.icon))
    end
end, "lista candidatos de icono TRP3 del target")

local function NormalizeUnitArg(args)
    local unit = tostring(args or ""):match("^%s*(%S*)")
    unit = unit and unit:lower() or "player"
    if unit ~= "target" and unit ~= "focus" then
        unit = "player"
    end
    return unit
end

local function FormatBox(box)
    if not box then
        return "nil"
    end
    if box.x then
        return string.format("x=%.1f y=%.1f w=%.1f h=%.1f", box.x or 0, box.y or 0, box.width or 0, box.height or 0)
    end
    if box.cx then
        return string.format("cx=%.1f cy=%.1f w=%.1f h=%.1f", box.cx or 0, box.cy or 0, box.width or 0, box.height or 0)
    end
    return string.format("w=%.1f h=%.1f", box.width or 0, box.height or 0)
end

local function FrameBounds(frame)
    if not frame or not frame.GetLeft then
        return nil
    end
    local left, top, right, bottom = frame:GetLeft(), frame:GetTop(), frame:GetRight(), frame:GetBottom()
    if not left or not top or not right or not bottom then
        return nil
    end
    return string.format("l=%.1f t=%.1f r=%.1f b=%.1f w=%.1f h=%.1f", left, top, right, bottom, right - left, top - bottom)
end

local function TextureSummary(info)
    if not info then
        return "nil"
    end
    local id = info.atlas or info.path or "sin textura"
    local suffix = info.fallback and " fallback" or ""
    return tostring(id) .. " [" .. tostring(info.source or "sin fuente") .. "]" .. suffix
end

local function FrameLevel(frame)
    if not frame or not frame.GetFrameLevel then
        return "nil"
    end
    return tostring(frame:GetFrameLevel())
end

API.RegisterCommand("ufmeasure", function(args)
    if not HarfordUnitFrames or not HarfordUnitFrames.GetMeasuredLayout then
        Print("HarfordUnitFrames no disponible")
        return
    end

    local unit = NormalizeUnitArg(args)
    local layout = HarfordUnitFrames.GetMeasuredLayout(unit, true)
    if not layout then
        Print("sin layout para " .. unit)
        return
    end

    Print("UnitFrame layout " .. unit .. ": " .. (layout.measured and "medido" or "fallback"))
    Print("root: " .. FormatBox(layout.root))
    Print("texture: " .. tostring(layout.texture and layout.texture.path or "nil") .. " / " .. FormatBox(layout.texture and layout.texture.rel))
    if layout.native then
        Print("native root/health/power: " .. tostring(layout.native.root) .. " / " .. tostring(layout.native.health) .. " / " .. tostring(layout.native.power))
        Print("native portrait/level/name: " .. tostring(layout.native.portrait) .. " / " .. tostring(layout.native.level) .. " / " .. tostring(layout.native.name))
    end
    Print("health bg/fill: " .. TextureSummary(layout.healthBg) .. " / " .. TextureSummary(layout.healthFill))
    Print("power bg/fill: " .. TextureSummary(layout.powerBg) .. " / " .. TextureSummary(layout.powerFill))
    Print("portrait: " .. FormatBox(layout.portrait))
    Print("health: " .. FormatBox(layout.health))
    Print("power: " .. FormatBox(layout.power))
    Print("level: " .. FormatBox(layout.level))
    Print("name: " .. FormatBox(layout.name))
end, "mide el unitframe Blizzard real: ufmeasure player|target|focus")

API.RegisterCommand("ufcompare", function(args)
    if not HarfordUnitFrames or not HarfordUnitFrames.GetMeasuredLayout then
        Print("HarfordUnitFrames no disponible")
        return
    end

    local unit = NormalizeUnitArg(args)
    local layout = HarfordUnitFrames.GetMeasuredLayout(unit, true)
    local frame = HarfordUnitFrames.GetFrame and HarfordUnitFrames.GetFrame(unit)
    if not layout then
        Print("sin layout para " .. unit)
        return
    end

    Print("UnitFrame compare " .. unit .. ": " .. (layout.measured and "medido" or "fallback"))
    Print("Harford frame: " .. (FrameBounds(frame) or "nil"))
    Print("visual: " .. (FrameBounds(frame and frame.visual) or "nil"))
    Print("overlay: " .. (FrameBounds(frame and frame.overlay) or "nil"))
    Print("portrait: " .. (FrameBounds(frame and frame.portrait) or "nil") .. " | esperado " .. FormatBox(layout.portrait))
    local healthBar = frame and frame.bars and frame.bars[1]
    local powerBar = frame and frame.bars and frame.bars[2]
    Print("health bar: " .. (FrameBounds(healthBar and healthBar.container or healthBar) or "nil") .. " | esperado " .. FormatBox(layout.health))
    Print("power bar: " .. (FrameBounds(powerBar and powerBar.container or powerBar) or "nil") .. " | esperado " .. FormatBox(layout.power))
    Print("levels health bg/bar/text/overlay: " .. FrameLevel(healthBar and healthBar.container) .. " / " .. FrameLevel(healthBar) .. " / " .. FrameLevel(healthBar and healthBar.container and healthBar.container.textFrame) .. " / " .. FrameLevel(frame and frame.overlayFrame))
    Print("levels power bg/bar/text/overlay: " .. FrameLevel(powerBar and powerBar.container) .. " / " .. FrameLevel(powerBar) .. " / " .. FrameLevel(powerBar and powerBar.container and powerBar.container.textFrame) .. " / " .. FrameLevel(frame and frame.overlayFrame))
end, "compara piezas Harford contra layout medido: ufcompare player|target|focus")

API.RegisterCommand("groupframes", function()
    if not HarfordUnitFrames or not HarfordUnitFrames.DebugGroupFrames then
        Print("HarfordUnitFrames no disponible")
        return
    end

    local rows = HarfordUnitFrames.DebugGroupFrames()
    local inGroup = IsInGroup and IsInGroup() or false
    local inRaid = IsInRaid and IsInRaid() or false
    Print("Group state: IsInGroup=" .. tostring(inGroup) .. " IsInRaid=" .. tostring(inRaid))
    for i = 1, 4 do
        local unit = "party" .. i
        Print(unit .. ": exists=" .. tostring(UnitExists and UnitExists(unit)) .. " name=" .. tostring(UnitName and UnitName(unit) or nil))
    end
    for i = 1, 5 do
        local unit = "raid" .. i
        Print(unit .. ": exists=" .. tostring(UnitExists and UnitExists(unit)) .. " name=" .. tostring(UnitName and UnitName(unit) or nil))
    end
    Print("Group/Raid frames detectados: " .. tostring(#rows))
    for i = 1, math.min(#rows, 20) do
        Print(rows[i])
    end
    if #rows > 20 then
        Print("... " .. tostring(#rows - 20) .. " mas")
    end
end, "lista frames de party/raid detectados y sus barras nativas")

API.RegisterCommand("barslot", function(args)
    if not HarfordUnitFrames or not HarfordUnitFrames.GetMeasuredLayout then
        Print("HarfordUnitFrames no disponible")
        return
    end

    local unit = NormalizeUnitArg(args)
    local layout = HarfordUnitFrames.GetMeasuredLayout(unit, false)
    if not layout then
        Print("sin layout para " .. unit)
        return
    end

    local tex    = layout.texture
    local tc     = tex and tex.texCoord
    local health = layout.health
    local power  = layout.power or layout.health

    Print("=== barslot debug " .. unit .. " ===")
    Print("texture path: " .. tostring(tex and tex.path or "nil"))
    Print("texCoord count: " .. tostring(tc and #tc or 0))
    if tc then
        Print("texCoord: " .. table.concat(tc, ", "))
    end
    local rel = tex and tex.rel
    Print("rel: " .. FormatBox(rel))
    Print("health: " .. FormatBox(health))
    Print("power: " .. FormatBox(power))

    if not tc or #tc < 4 or not health or not power then
        Print("EARLY RETURN: tc o health/power nil")
        return
    end

    local tcL, tcR, tcT, tcB
    if #tc == 4 then
        tcL, tcR, tcT, tcB = tc[1], tc[2], tc[3], tc[4]
    else
        tcL, tcR = tc[1], tc[5]
        tcT, tcB = tc[2], tc[4]
    end
    local hRange = tcR - tcL
    local vRange = tcB - tcT
    Print(string.format("tcL=%.4f tcR=%.4f tcT=%.4f tcB=%.4f hRange=%.4f vRange=%.4f",
        tcL, tcR, tcT, tcB, hRange, vRange))

    if not rel or rel.height <= 0 then
        Print("rel no medido, usando defaults")
        rel = {x=0, y=0, width=232, height=100}
    end

    local barX   = (power.x or health.x) - rel.x
    local barW   = power.width or health.width
    local relW   = rel.width
    local ovTcL  = tcL + (barX / relW) * hRange
    local ovTcR  = tcL + ((barX + barW) / relW) * hRange
    Print(string.format("barX=%.1f barW=%.1f relW=%.1f ovTcL=%.4f ovTcR=%.4f",
        barX, barW, relW, ovTcL, ovTcR))

    local BPV        = 1
    local BPH_PORTRAIT = 3
    local BPH_OUTER    = 5
    local isLeftPortrait = unit == "player"
    local BPH_L        = isLeftPortrait and BPH_PORTRAIT or BPH_OUTER
    local BPH_R        = isLeftPortrait and BPH_OUTER or BPH_PORTRAIT
    local barH       = power.height or health.height
    local relH       = rel.height
    local topY_tex   = (power.y or health.y) - rel.y
    local botY_tex   = topY_tex + barH
    local slotTopRel = math.max(0, (topY_tex - BPV) / relH)
    local slotBotRel = math.min(1, (botY_tex + BPV) / relH)
    local ovTcT_v    = tcT + slotTopRel * vRange
    local ovTcB_v    = tcT + slotBotRel * vRange
    Print(string.format("barH=%.1f topY=%.1f botY=%.1f BPV=%d BPH_L=%d BPH_R=%d", barH, topY_tex, botY_tex, BPV, BPH_L, BPH_R))
    Print(string.format("ovTcT=%.4f ovTcB=%.4f (topRel=%.3f botRel=%.3f)", ovTcT_v, ovTcB_v, slotTopRel, slotBotRel))

    local ovW = barW + BPH_L + BPH_R
    local ovH = barH + BPV * 2
    local ovX = (power.x or health.x) - BPH_L
    Print(string.format("overlay size: %.1f x %.1f  ovX=%.1f", ovW, ovH, ovX))

    local frame = HarfordUnitFrames.GetFrame and HarfordUnitFrames.GetFrame(unit)
    if frame and frame.barSlotOverlays then
        for i, ov in ipairs(frame.barSlotOverlays) do
            local shown = ov and ov.IsShown and ov:IsShown()
            local w = ov and ov.GetWidth and ov:GetWidth() or 0
            local h = ov and ov.GetHeight and ov:GetHeight() or 0
            Print(string.format("  overlay[%d]: shown=%s size=%.0fx%.0f", i, tostring(shown), w, h))
        end
    else
        Print("sin barSlotOverlays en el frame")
    end
end, "debug UV y posicion de barSlotOverlays: barslot player|target|focus")

API.RegisterCommand("aurageom", function(args)
    if not (HarfordUnitFrames and HarfordUnitFrames.GetFrame) then
        Print("HarfordUnitFrames no disponible"); return
    end
    local unit = NormalizeUnitArg(args)
    if unit ~= "target" and unit ~= "focus" then unit = "target" end
    local frame = HarfordUnitFrames.GetFrame(unit)
    if not frame then Print("sin frame para " .. unit); return end

    Print("=== aurageom " .. unit .. " ===")
    Print(string.format("resourceCount=%s extraResourceHeight=%s",
        tostring(frame.resourceCount), tostring(frame.extraResourceHeight)))
    Print(string.format("frame height=%.1f top=%s bottom=%s",
        frame:GetHeight() or 0,
        frame:GetTop() and string.format("%.1f", frame:GetTop()) or "nil",
        frame:GetBottom() and string.format("%.1f", frame:GetBottom()) or "nil"))
    local n = tonumber(frame.resourceCount) or 0
    local lastBar = frame.bars and frame.bars[n]
    if lastBar and lastBar.GetBottom then
        Print(string.format("ultima barra[%d] top=%s bottom=%s", n,
            lastBar:GetTop() and string.format("%.1f", lastBar:GetTop()) or "nil",
            lastBar:GetBottom() and string.format("%.1f", lastBar:GetBottom()) or "nil"))
    end

    local prefix = unit == "focus" and "FocusFrame" or "TargetFrame"
    local function dumpFrame(label, f)
        if not f then Print(label .. ": nil"); return end
        local shown = (f.IsShown and f:IsShown()) and "shown" or "hidden"
        Print(string.format("%s [%s] name=%s top=%s bottom=%s", label, shown,
            (f.GetName and f:GetName()) or "?",
            f.GetTop and f:GetTop() and string.format("%.1f", f:GetTop()) or "nil",
            f.GetBottom and f:GetBottom() and string.format("%.1f", f:GetBottom()) or "nil"))
        local num = (f.GetNumPoints and f:GetNumPoints()) or 0
        for i = 1, num do
            local p, rel, rp, x, y = f:GetPoint(i)
            Print(string.format("  point%d: %s -> %s %s x=%.1f y=%.1f", i, tostring(p),
                (rel and rel.GetName and rel:GetName()) or tostring(rel), tostring(rp), x or 0, y or 0))
        end
    end
    dumpFrame("Buffs(cont)", _G[prefix .. "Buffs"] or (_G[prefix] and _G[prefix].BuffFrame))
    dumpFrame("Debuffs(cont)", _G[prefix .. "Debuffs"] or (_G[prefix] and _G[prefix].DebuffFrame))
    dumpFrame("Buff1", _G[prefix .. "Buff1"])
    dumpFrame("Buff2", _G[prefix .. "Buff2"])
    dumpFrame("Debuff1", _G[prefix .. "Debuff1"])
    dumpFrame("Debuff2", _G[prefix .. "Debuff2"])
end, "geometria de auras vs barras de recurso: aurageom target|focus")

API.RegisterCommand("totlayer", function()
    local function SafeName(frame)
        if not frame then return "nil" end
        if frame.GetName then
            local ok, name = pcall(frame.GetName, frame)
            if ok and name then return name end
        end
        return tostring(frame)
    end

    local tot = _G.TargetFrameToT
        or (_G.TargetFrame and _G.TargetFrame.totFrame)
        or (_G.TargetFrame and _G.TargetFrame.TargetFrameToT)
    local targetFrame = HarfordUnitFrames and HarfordUnitFrames.GetFrame and HarfordUnitFrames.GetFrame("target")
    local barSlots = targetFrame and targetFrame.barSlotsFrame

    Print("=== TargetFrameToT layer ===")
    Print("tot=" .. SafeName(tot)
        .. " shown=" .. tostring(tot and tot.IsShown and tot:IsShown())
        .. " parent=" .. SafeName(tot and tot.GetParent and tot:GetParent()))
    if tot then
        Print("tot strata=" .. tostring(tot.GetFrameStrata and tot:GetFrameStrata())
            .. " level=" .. tostring(tot.GetFrameLevel and tot:GetFrameLevel())
            .. " topLevel=" .. tostring(tot.IsToplevel and tot:IsToplevel()))
    end
    Print("harford target=" .. SafeName(targetFrame)
        .. " shown=" .. tostring(targetFrame and targetFrame.IsShown and targetFrame:IsShown())
        .. " strata=" .. tostring(targetFrame and targetFrame.GetFrameStrata and targetFrame:GetFrameStrata())
        .. " level=" .. tostring(targetFrame and targetFrame.GetFrameLevel and targetFrame:GetFrameLevel())
        .. " resources=" .. tostring(targetFrame and targetFrame.resourceCount))
    Print("barSlots=" .. SafeName(barSlots)
        .. " shown=" .. tostring(barSlots and barSlots.IsShown and barSlots:IsShown())
        .. " level=" .. tostring(barSlots and barSlots.GetFrameLevel and barSlots:GetFrameLevel()))
    -- Anchor points del ToT (para verificar reposición física)
    if tot and tot.GetNumPoints and tot.GetPoint then
        local ok, numPts = pcall(tot.GetNumPoints, tot)
        if ok and numPts and numPts > 0 then
            for i = 1, numPts do
                local ok2, point, rel, relPoint, x, y = pcall(tot.GetPoint, tot, i)
                if ok2 then
                    Print("  tot anchor[" .. i .. "] " .. tostring(point)
                        .. " rel=" .. SafeName(rel)
                        .. " relPoint=" .. tostring(relPoint)
                        .. " x=" .. tostring(x) .. " y=" .. tostring(y))
                end
            end
        end
    end
    -- Estado Harford de reposición
    local desired = HarfordUnitFrames and HarfordUnitFrames._totDesired
    if desired then
        Print("totDesired extraHeight=" .. tostring(desired.extraHeight)
            .. " level=" .. tostring(desired.level)
            .. " strata=" .. tostring(desired.strata))
    else
        Print("totDesired=nil (no reposición activa)")
    end
end, "muestra parent/strata/level/anchors de TargetFrameToT y barras extra")

API.RegisterCommand("totpieces", function()
    local function SafeName(frame)
        if not frame then return "nil" end
        if frame.GetName then
            local ok, name = pcall(frame.GetName, frame)
            if ok and name then return name end
        end
        return tostring(frame)
    end

    local function BarLine(label, bar)
        if not bar then
            Print(label .. ": nil")
            return
        end
        local minValue, maxValue = "nil", "nil"
        if bar.GetMinMaxValues then
            local ok, minV, maxV = pcall(bar.GetMinMaxValues, bar)
            if ok then
                minValue, maxValue = tostring(minV), tostring(maxV)
            end
        end
        local color = "nil"
        if bar.GetStatusBarColor then
            local ok, r, g, b, a = pcall(bar.GetStatusBarColor, bar)
            if ok then
                color = string.format("%.2f,%.2f,%.2f,%.2f", r or 0, g or 0, b or 0, a or 1)
            end
        end
        Print(label .. ": " .. SafeName(bar)
            .. " type=" .. tostring(bar.GetObjectType and bar:GetObjectType())
            .. " shown=" .. tostring(bar.IsShown and bar:IsShown())
            .. " size=" .. tostring(bar.GetWidth and math.floor((bar:GetWidth() or 0) + 0.5)) .. "x" .. tostring(bar.GetHeight and math.floor((bar:GetHeight() or 0) + 0.5))
            .. " value=" .. tostring(bar.GetValue and bar:GetValue())
            .. " minmax=" .. minValue .. "/" .. maxValue
            .. " color=" .. color)
    end

    local root = _G.TargetFrameToT
        or (_G.TargetFrame and _G.TargetFrame.totFrame)
        or (_G.TargetFrame and _G.TargetFrame.TargetFrameToT)
    Print("=== TargetFrameToT pieces ===")
    Print("root=" .. SafeName(root) .. " unitExists=" .. tostring(UnitExists and UnitExists("targettarget")))
    BarLine("global health", _G.TargetFrameToTHealthBar)
    BarLine("global mana", _G.TargetFrameToTManaBar)
    BarLine("field healthbar", root and root.healthbar)
    BarLine("field manabar", root and root.manabar)
    BarLine("field HealthBar", root and root.HealthBar)
    BarLine("field ManaBar", root and root.ManaBar)

    if root and root.GetChildren then
        local count = 0
        local function scan(frame)
            if not frame or count >= 12 then return end
            if frame.GetObjectType and frame:GetObjectType() == "StatusBar" then
                count = count + 1
                BarLine("child statusbar " .. tostring(count), frame)
            end
            if frame.GetChildren then
                for _, child in ipairs({ frame:GetChildren() }) do
                    scan(child)
                end
            end
        end
        scan(root)
    end
end, "lista piezas candidatas de barras del TargetFrameToT")

local totWatch = {
    active = false,
    hooked = false,
    count = 0,
    maxLines = 60,
}

local function TotSafeName(frame)
    if not frame then return "nil" end
    if frame.GetName then
        local ok, name = pcall(frame.GetName, frame)
        if ok and name then return name end
    end
    return tostring(frame)
end

local function TotRoot()
    return _G.TargetFrameToT
        or (_G.TargetFrame and _G.TargetFrame.totFrame)
        or (_G.TargetFrame and _G.TargetFrame.TargetFrameToT)
end

local function TotPickBar(root, kind)
    if not root then return nil end
    local global = kind == "health" and _G.TargetFrameToTHealthBar or _G.TargetFrameToTManaBar
    if global then return global end
    if kind == "health" then
        if root.healthbar then return root.healthbar end
        if root.HealthBar then return root.HealthBar end
    else
        if root.manabar then return root.manabar end
        if root.ManaBar then return root.ManaBar end
    end
    return nil
end

local function TotBarState(label, bar)
    if not bar then return label .. "=nil" end
    local value = bar.GetValue and bar:GetValue() or "nil"
    local minValue, maxValue = "nil", "nil"
    if bar.GetMinMaxValues then
        local ok, minV, maxV = pcall(bar.GetMinMaxValues, bar)
        if ok then
            minValue, maxValue = tostring(minV), tostring(maxV)
        end
    end
    local color = "nil"
    if bar.GetStatusBarColor then
        local ok, r, g, b, a = pcall(bar.GetStatusBarColor, bar)
        if ok then
            color = string.format("%.2f,%.2f,%.2f,%.2f", r or 0, g or 0, b or 0, a or 1)
        end
    end
    return label .. "=" .. TotSafeName(bar)
        .. " shown=" .. tostring(bar.IsShown and bar:IsShown())
        .. " value=" .. tostring(value)
        .. " minmax=" .. minValue .. "/" .. maxValue
        .. " color=" .. color
end

local function TotWatchLog(reason)
    if not totWatch.active then return end
    local now = GetTime and GetTime() or 0
    if totWatch.untilTime and now > totWatch.untilTime then
        totWatch.active = false
        if totWatch.frame then totWatch.frame:UnregisterAllEvents() end
        Print("totwatch finalizado")
        return
    end
    if totWatch.count >= totWatch.maxLines then return end
    totWatch.count = totWatch.count + 1

    local root = TotRoot()
    local health = TotPickBar(root, "health")
    local power = TotPickBar(root, "power")
    Print("totwatch " .. tostring(totWatch.count) .. " " .. tostring(reason)
        .. " exists=" .. tostring(UnitExists and UnitExists("targettarget"))
        .. " guid=" .. tostring(UnitGUID and UnitGUID("targettarget"))
        .. " root=" .. TotSafeName(root)
        .. " rootShown=" .. tostring(root and root.IsShown and root:IsShown()))
    Print("  " .. TotBarState("health", health))
    Print("  " .. TotBarState("power", power))
end

API.RegisterCommand("totwatch", function(args)
    local seconds = tonumber(tostring(args or ""):match("(%d+)")) or 6
    if seconds < 1 then seconds = 1 end
    if seconds > 20 then seconds = 20 end

    totWatch.active = true
    totWatch.count = 0
    totWatch.untilTime = (GetTime and GetTime() or 0) + seconds
    totWatch.maxLines = 60

    if not totWatch.frame then
        totWatch.frame = CreateFrame("Frame")
        totWatch.frame:SetScript("OnEvent", function(_, event, unit)
            if event == "PLAYER_TARGET_CHANGED"
                or (event == "UNIT_TARGET" and unit == "target")
                or unit == "targettarget" then
                TotWatchLog(event .. (unit and (":" .. tostring(unit)) or ""))
            end
        end)
    end
    totWatch.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    totWatch.frame:RegisterEvent("UNIT_TARGET")
    totWatch.frame:RegisterEvent("UNIT_HEALTH")
    totWatch.frame:RegisterEvent("UNIT_POWER_UPDATE")
    totWatch.frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    totWatch.frame:RegisterEvent("UNIT_NAME_UPDATE")
    totWatch.frame:RegisterEvent("UNIT_AURA")

    if not totWatch.hooked and hooksecurefunc and type(_G.TargetofTarget_Update) == "function" then
        hooksecurefunc("TargetofTarget_Update", function()
            TotWatchLog("post TargetofTarget_Update")
        end)
        totWatch.hooked = true
    end

    Print("totwatch activo durante " .. tostring(seconds) .. "s")
    TotWatchLog("start")
    if C_Timer and C_Timer.After then
        C_Timer.After(seconds, function()
            if totWatch.active then
                totWatch.active = false
                if totWatch.frame then totWatch.frame:UnregisterAllEvents() end
                Print("totwatch finalizado")
            end
        end)
    end
end, "observa eventos/update y valores reales del TargetFrameToT durante unos segundos")

-- Espía los métodos de TargetFrameToTManaBar para ver quién los llama y con qué valores.
-- Uso: /harford debug run totspy [segundos]   (por defecto 5s)
-- IMPORTANTE: usa hooksecurefunc — no puede desinstalarse. Úsalo solo para diagnóstico puntual.
API.RegisterCommand("totspy", function(args)
    local seconds = tonumber(args) or 5
    seconds = math.max(2, math.min(20, seconds))

    local bar = _G["TargetFrameToTManaBar"]
    if not bar then
        Print("totspy: TargetFrameToTManaBar no existe")
        return
    end

    local active = true
    local calls = {}
    local function record(method, ...)
        if not active then return end
        local n = #calls + 1
        if n > 60 then return end  -- max 60 entradas para no spamear
        local args_str = ""
        for i = 1, select("#", ...) do
            args_str = args_str .. tostring(select(i, ...)) .. " "
        end
        calls[n] = method .. "(" .. args_str:gsub("%s+$", "") .. ")"
    end

    -- Hookeamos con hooksecurefunc (no se puede desinstalar, solo para diagnostico)
    local hooked = {}
    local methods = {"SetValue", "SetMinMaxValues", "SetStatusBarColor", "SetAlpha", "Show", "Hide"}
    for _, m in ipairs(methods) do
        if type(bar[m]) == "function" and not hooked[m] then
            hooked[m] = true
            hooksecurefunc(bar, m, function(_, ...)
                record(m, ...)
            end)
        end
    end

    -- También hookeamos TargetofTarget_Update para marcar sus llamadas en el log
    if type(_G.TargetofTarget_Update) == "function" then
        hooksecurefunc("TargetofTarget_Update", function()
            record("---TargetofTarget_Update---")
        end)
    end

    Print("totspy activo " .. seconds .. "s en TargetFrameToTManaBar (max 60 entradas)")

    if C_Timer and C_Timer.After then
        C_Timer.After(seconds, function()
            active = false
            Print("=== totspy resultado (" .. #calls .. " llamadas capturadas) ===")
            for i, entry in ipairs(calls) do
                Print("  [" .. i .. "] " .. entry)
            end
            if #calls == 0 then
                Print("  (ninguna llamada detectada — puede que los metodos no sean hookeables en Epsilon)")
            end
        end)
    end
end, "espia metodos de TargetFrameToTManaBar en tiempo real: totspy [segundos]")

-- Lista scripts registrados en las barras del ToT y sus padres, para encontrar OnUpdate/OnValueChanged que luchen con Harford.
API.RegisterCommand("totscripts", function()
    local targets = {
        "TargetFrameToT",
        "TargetFrameToTHealthBar",
        "TargetFrameToTManaBar",
        "TargetFrame",
    }
    local scriptTypes = {"OnUpdate","OnValueChanged","OnShow","OnHide","OnEvent","OnMinMaxChanged"}
    Print("=== totscripts ===")
    for _, name in ipairs(targets) do
        local f = _G[name]
        if f then
            local found = {}
            for _, s in ipairs(scriptTypes) do
                local ok, has = pcall(function() return f:GetScript(s) ~= nil end)
                if ok and has then found[#found+1] = s end
            end
            if #found > 0 then
                Print(name .. ": " .. table.concat(found, ", "))
            else
                Print(name .. ": sin scripts relevantes")
            end
        else
            Print(name .. ": NO EXISTE en _G")
        end
    end
    -- Verificar también si las barras tienen hijos con scripts
    local mana = _G["TargetFrameToTManaBar"]
    if mana and mana.GetNumRegions then
        Print("TargetFrameToTManaBar regiones: " .. tostring(mana:GetNumRegions()))
    end
    if mana and mana.GetNumChildren then
        Print("TargetFrameToTManaBar hijos: " .. tostring(mana:GetNumChildren()))
    end
end, "lista scripts en barras del ToT (busca OnUpdate/OnValueChanged)")

-- Mide cuántas veces por segundo disparan las funciones clave del ToT y desde qué origen.
-- Uso: /harford debug run totrate [segundos]   (por defecto 5s)
API.RegisterCommand("totrate", function(args)
    local seconds = tonumber(args) or 5
    seconds = math.max(2, math.min(30, seconds))

    local counts = {
        totUpdate   = 0,  -- TargetofTarget_Update (Blizzard)
        unitHealth  = 0,  -- UNIT_HEALTH para targettarget
        unitPower   = 0,  -- UNIT_POWER_UPDATE para targettarget
        unitTarget  = 0,  -- UNIT_TARGET para "target"
        refreshBars = 0,  -- RefreshTargetOfTargetBars total
        alphaZero   = 0,  -- veces que se puso alpha=0 (sin datos)
        alphaOne    = 0,  -- veces que se puso alpha=1 (con datos)
    }
    local startTime = GetTime and GetTime() or time()
    local active = true

    -- Hook TargetofTarget_Update para contar
    local totHooked = false
    if hooksecurefunc and type(_G.TargetofTarget_Update) == "function" then
        hooksecurefunc("TargetofTarget_Update", function()
            if active then counts.totUpdate = counts.totUpdate + 1 end
        end)
        totHooked = true
    end

    -- Frame para escuchar eventos
    local rateFrame = CreateFrame("Frame")
    rateFrame:RegisterEvent("UNIT_HEALTH")
    rateFrame:RegisterEvent("UNIT_POWER_UPDATE")
    rateFrame:RegisterEvent("UNIT_TARGET")
    rateFrame:SetScript("OnEvent", function(_, event, unit, ...)
        if not active then return end
        if event == "UNIT_HEALTH" and unit == "targettarget" then
            counts.unitHealth = counts.unitHealth + 1
        elseif event == "UNIT_POWER_UPDATE" and unit == "targettarget" then
            counts.unitPower = counts.unitPower + 1
        elseif event == "UNIT_TARGET" and unit == "target" then
            counts.unitTarget = counts.unitTarget + 1
        end
    end)

    -- Hook SetAlpha en TargetFrameToTManaBar para ver los toggles
    local powerBar = _G["TargetFrameToTManaBar"]
    local origSetAlpha = powerBar and powerBar.SetAlpha
    if powerBar and origSetAlpha then
        -- No podemos reemplazar metodos en frames de Blizzard directamente;
        -- contamos desde ApplyNativeResourceBars via flag global temporal
        _G._HarfordTotRateActive = counts
    end

    -- OnUpdate para contar el total de RefreshTargetOfTargetBars
    -- Usamos el flag global que leerá ApplyNativeResourceBars
    _G._HarfordTotRateActive = counts

    Print("=== totrate: midiendo " .. seconds .. "s ===")
    if not totHooked then Print("  ADVERTENCIA: no se pudo hookear TargetofTarget_Update") end

    if C_Timer and C_Timer.After then
        C_Timer.After(seconds, function()
            active = false
            rateFrame:UnregisterAllEvents()
            _G._HarfordTotRateActive = nil

            local elapsed = math.max(1, (GetTime and GetTime() or time()) - startTime)
            local function rate(n) return string.format("%.1f/s", n / elapsed) end

            Print("=== totrate resultado (" .. string.format("%.1f", elapsed) .. "s) ===")
            Print("  TargetofTarget_Update : " .. counts.totUpdate  .. "  (" .. rate(counts.totUpdate)  .. ")")
            Print("  UNIT_HEALTH targettarget : " .. counts.unitHealth .. "  (" .. rate(counts.unitHealth) .. ")")
            Print("  UNIT_POWER_UPDATE tot    : " .. counts.unitPower  .. "  (" .. rate(counts.unitPower)  .. ")")
            Print("  UNIT_TARGET target       : " .. counts.unitTarget .. "  (" .. rate(counts.unitTarget) .. ")")
            Print("  refreshBars (total)      : " .. counts.refreshBars .. "  (" .. rate(counts.refreshBars) .. ")")
            Print("  alpha→0 (sin datos)      : " .. counts.alphaZero)
            Print("  alpha→1 (con datos)      : " .. counts.alphaOne)
            if counts.totUpdate > 0 and counts.refreshBars > 0 then
                local ratio = counts.totUpdate / counts.refreshBars
                Print("  ratio update/refresh     : " .. string.format("%.1f", ratio))
            end
        end)
    end
end, "mide frecuencia de llamadas al ToT: totrate [segundos]")

-- Diagnostica el portrait overlay del ToT: muestra si existe, nivel, si está visible, si el icono TRP3 cargó.
API.RegisterCommand("totportrait", function()
    local function SafeName(frame)
        if not frame then return "nil" end
        if frame.GetName then
            local ok, name = pcall(frame.GetName, frame)
            if ok and name then return name end
        end
        return tostring(frame)
    end

    local portraitNative = _G["TargetFrameToTPortrait"]
    Print("=== ToT Portrait Debug ===")
    Print("TargetFrameToTPortrait exists=" .. tostring(portraitNative ~= nil)
        .. " type=" .. tostring(portraitNative and type(portraitNative))
        .. " shown=" .. tostring(portraitNative and portraitNative.IsShown and portraitNative:IsShown()))
    if portraitNative then
        Print("  strata=" .. tostring(portraitNative.GetFrameStrata and portraitNative:GetFrameStrata())
            .. " level=" .. tostring(portraitNative.GetFrameLevel and portraitNative:GetFrameLevel()))
    end

    -- Estado del overlay
    local ov = HarfordUnitFrames and HarfordUnitFrames._totBarsOverlay
    if not ov then
        Print("totBarsOverlay: nil (no se ha creado)")
        return
    end
    local pf = ov.portraitFrame
    if not pf then
        Print("portraitFrame: nil (no se pudo crear)")
        return
    end
    Print("portraitFrame exists=true"
        .. " shown=" .. tostring(pf.IsShown and pf:IsShown())
        .. " level=" .. tostring(pf.GetFrameLevel and pf:GetFrameLevel()))
    if ov.artFrame then
        local count = ov.artFrame.textures and #ov.artFrame.textures or 0
        Print("artFrame shown=" .. tostring(ov.artFrame.IsShown and ov.artFrame:IsShown())
            .. " level=" .. tostring(ov.artFrame.GetFrameLevel and ov.artFrame:GetFrameLevel())
            .. " textures=" .. tostring(count))
    else
        Print("artFrame=nil")
    end
    if pf.icon then
        local ok, tex = pcall(pf.icon.GetTexture, pf.icon)
        Print("  icon texture=" .. tostring(ok and tex or "error"))
    else
        Print("  icon=nil")
    end
    -- TRP3 profile del targettarget
    local unit = "targettarget"
    local exists = UnitExists and UnitExists(unit)
    Print("targettarget exists=" .. tostring(exists))
    if exists and HarfordTRP3 then
        local profile = HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetPlayerProfile(unit)
        Print("  TRP3 profile=" .. tostring(profile ~= nil))
        if profile and HarfordTRP3.GetProfileIcon then
            local icon = HarfordTRP3.GetProfileIcon(profile)
            Print("  TRP3 icon=" .. tostring(icon))
        end
    end
end, "diagnostica portrait overlay del ToT y estado TRP3")

-- Solicita recursos al target actual por WHISPER (DND5EARC REQ).
-- Útil para forzar una actualización cuando el cache de recursos está vacío o desactualizado.
-- Uso: /harford debug run reqres
API.RegisterCommand("reqres", function()
    local unit = "target"
    if not UnitExists or not UnitExists(unit) then
        Print("reqres: sin target.")
        return
    end
    if not (UnitIsPlayer and UnitIsPlayer(unit)) then
        Print("reqres: el target no es un jugador.")
        return
    end
    if not (HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName) then
        Print("reqres: HarfordDnDAPI.RequestResourcesForName no disponible.")
        return
    end
    local name = UnitName and UnitName(unit) or ""
    local ok = HarfordDnDAPI.RequestResourcesForName(name)
    Print("reqres: " .. tostring(name) .. " → " .. (ok and "solicitud enviada" or "fallo (throttle o sin nombre)"))
end, "fuerza solicitud de recursos al target: reqres")

-- Diagnóstico de TRP3 para el jugador target (unitID, profileID, perfil conocido, player_id propio).
-- Uso: /harford debug run trp3player
API.RegisterCommand("trp3player", function()
    Print("=== TRP3 jugador target ===")
    local unit = UnitExists and UnitExists("target") and "target" or "player"
    Print("unit=" .. unit)

    -- globals.player_id
    local selfID = TRP3_API and TRP3_API.globals and TRP3_API.globals.player_id
    Print("globals.player_id=" .. tostring(selfID))

    -- unitID via HarfordTRP3
    if HarfordTRP3 and HarfordTRP3.BuildUnitID then
        local uid = HarfordTRP3.BuildUnitID(unit)
        Print("BuildUnitID(" .. unit .. ")=" .. tostring(uid))

        if uid and TRP3_API and TRP3_API.register then
            local reg = TRP3_API.register
            local known = reg.isUnitIDKnown and reg.isUnitIDKnown(uid)
            Print("isUnitIDKnown=" .. tostring(known))
            if known then
                local pid = reg.hasProfile and reg.hasProfile(uid)
                Print("hasProfile(profileID)=" .. tostring(pid))
                local profile = pid and reg.getProfile and reg.getProfile(pid)
                Print("getProfile=" .. tostring(profile ~= nil))
            end
        end
    else
        Print("HarfordTRP3.BuildUnitID: NO DISPONIBLE")
    end

    -- Verificar openPageByUnitID
    local canOpen = TRP3_API and TRP3_API.register and TRP3_API.register.openPageByUnitID
    Print("openPageByUnitID=" .. tostring(canOpen ~= nil))
    local canOpenFrame = TRP3_API and TRP3_API.navigation and TRP3_API.navigation.openMainFrame
    Print("openMainFrame=" .. tostring(canOpenFrame ~= nil))
end, "diagnóstico TRP3 del target: unitID, profileID y si puede abrir ficha")

-- Diagnóstico de APIs de posición disponibles en Epsilon.
-- Uso: /harford debug run testpos
API.RegisterCommand("testpos", function()
    Print("=== APIs de posición ===")

    -- UnitPosition
    if UnitPosition then
        local a, b, c, d = UnitPosition("player")
        Print("UnitPosition(player) = " .. tostring(a) .. ", " .. tostring(b) .. ", " .. tostring(c) .. ", " .. tostring(d))
    else
        Print("UnitPosition: NO EXISTE")
    end

    -- C_Map.GetPlayerMapPosition
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local mapID = C_Map.GetBestMapForUnit("player")
        Print("C_Map.GetBestMapForUnit(player) = " .. tostring(mapID))
        if mapID then
            local p = C_Map.GetPlayerMapPosition(mapID, "player")
            if p then
                Print("C_Map.GetPlayerMapPosition = x=" .. tostring(p.x) .. " y=" .. tostring(p.y))
            else
                Print("C_Map.GetPlayerMapPosition = nil")
            end
        end
    else
        Print("C_Map.GetPlayerMapPosition: NO EXISTE")
    end

    -- GetPlayerFacing para saber si hay frame de movimiento disponible
    if GetPlayerFacing then
        Print("GetPlayerFacing() = " .. tostring(GetPlayerFacing()))
    else
        Print("GetPlayerFacing: NO EXISTE")
    end
end, "diagnóstico de APIs de posición disponibles en Epsilon")

-- Observa la posición del jugador durante N segundos y muestra si cambia.
-- Útil para confirmar que UnitPosition actualiza mientras el jugador se mueve.
-- Uso: /harford debug run poswatch [segundos]   (por defecto 8s)
do
    local _posWatchFrame
    API.RegisterCommand("poswatch", function(args)
        local seconds = tonumber(args) or 8
        seconds = math.max(2, math.min(30, seconds))

        local startTime = GetTime and GetTime() or 0
        local endTime   = startTime + seconds
        local samples   = 0
        local prevX, prevY, prevZ
        local totalDist = 0
        local YARDS_TO_METERS = 0.9144

        local function GetPosDbg()
            if UnitPosition then
                local a, b, c = UnitPosition("player")
                if a and b then return a, b, c or 0, "UnitPosition" end
            end
            if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
                local mapID = C_Map.GetBestMapForUnit("player")
                if mapID then
                    local p = C_Map.GetPlayerMapPosition(mapID, "player")
                    if p then return p.x, p.y, 0, "C_Map" end
                end
            end
            return nil, nil, nil, "ninguna"
        end

        if not _posWatchFrame then
            _posWatchFrame = CreateFrame("Frame")
        end

        Print("poswatch activo " .. seconds .. "s — muévete para comprobar")

        local elapsed = 0
        _posWatchFrame:SetScript("OnUpdate", function(_, dt)
            local now = GetTime and GetTime() or 0
            if now >= endTime then
                _posWatchFrame:SetScript("OnUpdate", nil)
                Print("=== poswatch resultado (" .. samples .. " muestras, " .. string.format("%.1f", seconds) .. "s) ===")
                Print("  Distancia total acumulada: " .. string.format("%.2f m", totalDist))
                if samples == 0 then
                    Print("  PROBLEMA: ninguna API retornó coordenadas")
                elseif totalDist < 0.01 then
                    Print("  PROBLEMA: posición no cambió — API existe pero no actualiza")
                else
                    Print("  OK: posición se actualizó correctamente")
                end
                return
            end

            elapsed = elapsed + dt
            if elapsed < 0.1 then return end
            elapsed = 0
            samples = samples + 1

            local nx, ny, nz, api = GetPosDbg()
            if not nx then return end

            if prevX then
                local dx = nx - prevX
                local dy = ny - prevY
                local dz = nz - prevZ
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz) * YARDS_TO_METERS
                if dist > 0.02 then
                    totalDist = totalDist + dist
                    Print("  [" .. samples .. "] api=" .. api .. " dist=" .. string.format("+%.2fm", dist)
                        .. " total=" .. string.format("%.2fm", totalDist))
                end
            else
                Print("  [primera muestra] api=" .. api
                    .. " x=" .. string.format("%.4f", nx)
                    .. " y=" .. string.format("%.4f", ny)
                    .. " z=" .. string.format("%.4f", nz))
            end
            prevX, prevY, prevZ = nx, ny, nz
        end)
    end, "observa posición del jugador N segundos para verificar que UnitPosition actualiza: poswatch [segundos]")
end

-- Comandos sueltos retirados: usar `/harford debug <args>`.
SlashCmdList["HARFORDDEBUG"] = function(msg)
    local command, rest = SplitCommand(msg)

    if command == "" or command == "help" or command == "ayuda" then
        ShowHelp()
    elseif command == "on" then
        SetEnabled(true)
    elseif command == "off" then
        SetEnabled(false)
    elseif command == "toggle" then
        API.Toggle()
    elseif command == "status" then
        ShowStatus()
    elseif command == "list" then
        API.ListCommands()
    elseif command == "run" then
        local debugCommand, args = SplitCommand(rest)
        if debugCommand == "" then
            Print("uso: /harford debug run <comando>")
            return
        end
        API.RunCommand(debugCommand, args)
    else
        Print("comando no reconocido: " .. command)
        ShowHelp()
    end
end

-- ── INSPECCIÓN DE FRAME TOT / FOCUS ────────────────────────────────────────
-- Uso: /harford debug run totframe [tot|focustot]
-- Vuelca jerarquía completa del frame para diagnosticar overlays y niveles.
API.RegisterCommand("totframe", function(args)
    local which = tostring(args or ""):match("^%s*(%S*)")
    local rootName, root
    if which == "focustot" then
        rootName = "FocusFrameToT"
        root = _G["FocusFrameToT"]
    else
        rootName = "TargetFrameToT"
        root = _G["TargetFrameToT"]
    end

    if not root then
        Print(rootName .. " no existe en _G")
        return
    end

    local function strata(f)
        return f.GetFrameStrata and f:GetFrameStrata() or "?"
    end
    local function level(f)
        return f.GetFrameLevel and f:GetFrameLevel() or "?"
    end
    local function alpha(f)
        return f.GetAlpha and string.format("%.2f", f:GetAlpha()) or "?"
    end
    local function shown(f)
        return f.IsShown and (f:IsShown() and "SHOWN" or "hidden") or "?"
    end
    local function size(f)
        if not f.GetWidth then return "?" end
        return string.format("%.0fx%.0f", f:GetWidth(), f:GetHeight())
    end

    Print("=== " .. rootName .. " ===")
    Print(string.format("  strata=%s level=%s alpha=%s vis=%s size=%s",
        strata(root), level(root), alpha(root), shown(root), size(root)))

    -- Regiones directas
    if root.GetRegions then
        local ri = 0
        for _, region in ipairs({ root:GetRegions() }) do
            ri = ri + 1
            local objType = region.GetObjectType and region:GetObjectType() or "?"
            local tex = region.GetTexture and region:GetTexture() or nil
            local atl = region.GetAtlas and region:GetAtlas() or nil
            local ralpha = region.GetAlpha and string.format("%.2f", region:GetAlpha()) or "?"
            local rshown = region.IsShown and (region:IsShown() and "SHOWN" or "hidden") or "?"
            Print(string.format("  region[%d] type=%s alpha=%s vis=%s tex=%s atlas=%s",
                ri, objType, ralpha, rshown,
                tostring(tex or "-"), tostring(atl or "-")))
        end
    end

    -- Hijos directos
    if root.GetChildren then
        for _, child in ipairs({ root:GetChildren() }) do
            local n = child.GetName and child:GetName() or "(sin nombre)"
            local objType = child.GetObjectType and child:GetObjectType() or "?"
            Print(string.format("  hijo: %-40s type=%-8s strata=%s level=%s alpha=%s vis=%s size=%s",
                n, objType, strata(child), level(child), alpha(child), shown(child), size(child)))

            -- Regiones del hijo
            if child.GetRegions then
                for _, region in ipairs({ child:GetRegions() }) do
                    local rtype = region.GetObjectType and region:GetObjectType() or "?"
                    local tex = region.GetTexture and region:GetTexture() or nil
                    local atl = region.GetAtlas and region:GetAtlas() or nil
                    local ralpha = region.GetAlpha and string.format("%.2f", region:GetAlpha()) or "?"
                    local rshown = region.IsShown and (region:IsShown() and "SHOWN" or "hidden") or "?"
                    Print(string.format("    region type=%s alpha=%s vis=%s tex=%s atlas=%s",
                        rtype, ralpha, rshown,
                        tostring(tex or "-"), tostring(atl or "-")))
                end
            end

            -- Nietos
            if child.GetChildren then
                for _, grandchild in ipairs({ child:GetChildren() }) do
                    local gn = grandchild.GetName and grandchild:GetName() or "(sin nombre)"
                    local gobjType = grandchild.GetObjectType and grandchild:GetObjectType() or "?"
                    Print(string.format("    nieto: %-36s type=%-8s level=%s alpha=%s vis=%s",
                        gn, gobjType, level(grandchild), alpha(grandchild), shown(grandchild)))
                end
            end
        end
    end

    -- Estado de los globals relevantes
    Print("--- globals ---")
    Print("TargetofTarget_Update: " .. type(_G.TargetofTarget_Update))
    Print("FocusofTarget_Update:  " .. type(_G.FocusofTarget_Update))
    local ov = HarfordUnitFrames and HarfordUnitFrames._totBarsOverlay
    local fov = HarfordUnitFrames and HarfordUnitFrames._focusTotBarsOverlay
    Print("totBarsOverlay creado: " .. tostring(ov ~= nil))
    Print("focusTotOverlay creado: " .. tostring(fov ~= nil))
    if ov then
        Print(string.format("  ov.portraitFrame: vis=%s", shown(ov.portraitFrame or {})))
        local pn = _G["TargetFrameToTPortrait"]
        Print("  TargetFrameToTPortrait alpha: " .. (pn and pn.GetAlpha and string.format("%.2f", pn:GetAlpha()) or "nil"))
    end
    if fov then
        Print(string.format("  fov.portraitFrame: vis=%s", shown(fov.portraitFrame or {})))
        local pn = _G["FocusFrameToTPortrait"]
        Print("  FocusFrameToTPortrait alpha: " .. (pn and pn.GetAlpha and string.format("%.2f", pn:GetAlpha()) or "nil"))
    end
end, "inspecciona jerarquía TargetFrameToT o FocusFrameToT. Args: tot (default) | focustot")

API.RegisterCommand("npinspect", function(args)
    -- Inspecciona la jerarquía de un nameplate para identificar campos disponibles.
    -- Sin argumento usa el target; con argumento "all" lista todos los nameplates visibles.
    local which = tostring(args or ""):match("^%s*(%S*)")

    local function InspectNp(unit, np)
        local unitName = UnitName and UnitName(unit) or "?"
        local isPlayer = UnitIsPlayer and UnitIsPlayer(unit)
        Print(string.format("=== nameplate unit=%s name=%s player=%s ===", unit, unitName, tostring(isPlayer)))

        if not np then
            Print("  (frame nil)")
            return
        end

        -- Campos clave en el raiz del nameplate
        local knownFields = {
            "UnitFrame", "healthBar", "HealthBar", "health", "Health",
            "castBar", "name", "kui", "plate", "unitFrame",
        }
        Print("  Campos raiz relevantes:")
        for _, field in ipairs(knownFields) do
            local v = rawget(np, field)
            if v ~= nil then
                local t = type(v)
                local extra = ""
                if t == "table" or t == "userdata" then
                    local objType = (type(v) == "userdata" or type(v.GetObjectType) == "function")
                                    and v.GetObjectType and v:GetObjectType() or "table"
                    local vis = v.IsShown and (v:IsShown() and "SHOWN" or "hidden") or "?"
                    local w = v.GetWidth and string.format("%.0f", v:GetWidth()) or "?"
                    local h = v.GetHeight and string.format("%.0f", v:GetHeight()) or "?"
                    extra = string.format(" [%s vis=%s size=%sx%s]", objType, vis, w, h)
                end
                Print(string.format("    np.%-20s = %s%s", field, t, extra))
            end
        end

        -- UnitFrame: inspeccionar hijos y campos
        local uf = rawget(np, "UnitFrame")
        if uf then
            Print("  UnitFrame campos relevantes:")
            local ufFields = { "healthBar", "HealthBar", "health", "Health",
                               "powerBar", "PowerBar", "power", "Power",
                               "name", "level", "castBar" }
            for _, field in ipairs(ufFields) do
                local v = rawget(uf, field)
                if v ~= nil then
                    local t = type(v)
                    local extra = ""
                    if t == "table" or t == "userdata" then
                        local objType = v.GetObjectType and v:GetObjectType() or "table"
                        local vis = v.IsShown and (v:IsShown() and "SHOWN" or "hidden") or "?"
                        local w = v.GetWidth and string.format("%.0f", v:GetWidth()) or "?"
                        local h = v.GetHeight and string.format("%.0f", v:GetHeight()) or "?"
                        extra = string.format(" [%s vis=%s size=%sx%s]", objType, vis, w, h)
                    end
                    Print(string.format("    uf.%-20s = %s%s", field, t, extra))
                end
            end
        end

        -- KuiNameplates: inspeccionar nameplate.kui si existe
        local kui = rawget(np, "kui")
        if kui then
            Print("  nameplate.kui existe — campos:")
            -- iterar todos los campos string del table kui
            local kuiFields = {}
            for k, v in pairs(kui) do
                if type(k) == "string" then
                    kuiFields[#kuiFields + 1] = k
                end
            end
            table.sort(kuiFields)
            for _, k in ipairs(kuiFields) do
                local v = kui[k]
                local t = type(v)
                local extra = ""
                if t == "table" or t == "userdata" then
                    local objType = v.GetObjectType and v:GetObjectType() or "table"
                    local vis = v.IsShown and (v:IsShown() and "SHOWN" or "hidden") or "?"
                    local w = v.GetWidth and string.format("%.0f", v:GetWidth()) or "?"
                    local h = v.GetHeight and string.format("%.0f", v:GetHeight()) or "?"
                    extra = string.format(" [%s vis=%s size=%sx%s]", objType, vis, w, h)
                end
                Print(string.format("    kui.%-20s = %s%s", k, t, extra))
            end
        else
            Print("  nameplate.kui: nil (KuiNameplates no activo o campo diferente)")
            Print("  KuiNameplates global: " .. type(KuiNameplates))
        end
    end

    if which == "all" then
        if not C_NamePlate or not C_NamePlate.GetNamePlates then
            Print("C_NamePlate.GetNamePlates no disponible")
            return
        end
        local plates = C_NamePlate.GetNamePlates()
        if #plates == 0 then
            Print("No hay nameplates visibles")
            return
        end
        for _, np in ipairs(plates) do
            local unit = np.namePlateUnitToken
            if unit then InspectNp(unit, np) end
        end
    else
        -- Usar target por defecto
        if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then
            Print("C_NamePlate.GetNamePlateForUnit no disponible")
            return
        end
        local unit = "target"
        local np = C_NamePlate.GetNamePlateForUnit(unit)
        if not np then
            Print("No hay nameplate para el target actual (¿tienes algo seleccionado y visible?)")
            return
        end
        InspectNp(unit, np)
    end
end, "inspecciona jerarquía de nameplates. Sin args: nameplate del target. Args: all")

API.RegisterCommand("npkui", function()
    -- Vuelca TODOS los campos de nameplate.kui y sus regiones para identificar
    -- el frame/textura que Kui usa en modo "name only + health fill".
    if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then
        Print("C_NamePlate no disponible")
        return
    end
    local np = C_NamePlate.GetNamePlateForUnit("target")
    if not np then
        Print("No hay nameplate para el target (¿tienes algo seleccionado y visible?)")
        return
    end
    local kui = rawget(np, "kui")
    if not kui then
        Print("nameplate.kui es nil — KuiNameplates no activo o estructura distinta")
        return
    end

    local unitName = UnitName and UnitName("target") or "?"
    Print(string.format("=== nameplate.kui dump — target: %s ===", unitName))

    -- Todos los campos string del kui frame
    local keys = {}
    for k in pairs(kui) do
        if type(k) == "string" then keys[#keys + 1] = k end
    end
    table.sort(keys)

    for _, k in ipairs(keys) do
        local v = kui[k]
        local t = type(v)
        local extra = ""
        if t == "table" or t == "userdata" then
            local ok, objType = pcall(function() return v:GetObjectType() end)
            objType = ok and objType or "table"
            local vis = v.IsShown and (v:IsShown() and "SHOWN" or "hidden") or "?"
            local visReal = v.IsVisible and (v:IsVisible() and "visible" or "occluded") or "?"
            local w = v.GetWidth  and string.format("%.0f", v:GetWidth())  or "?"
            local h = v.GetHeight and string.format("%.0f", v:GetHeight()) or "?"
            local lv = v.GetFrameLevel and tostring(v:GetFrameLevel()) or "?"
            extra = string.format(" [%s shown=%s vis=%s size=%sx%s level=%s]",
                objType, vis, visReal, w, h, lv)

            -- Regiones directas del hijo (texturas, fontstrings)
            if v.GetRegions then
                local regions = { v:GetRegions() }
                for i, r in ipairs(regions) do
                    local rtype = r.GetObjectType and r:GetObjectType() or "?"
                    local rvis  = r.IsShown and (r:IsShown() and "SHOWN" or "hidden") or "?"
                    local rw    = r.GetWidth  and string.format("%.0f", r:GetWidth())  or "?"
                    local rh    = r.GetHeight and string.format("%.0f", r:GetHeight()) or "?"
                    local rtex  = r.GetTexture and tostring(r:GetTexture() or "-") or "-"
                    local ralpha = r.GetAlpha and string.format("%.2f", r:GetAlpha()) or "?"
                    Print(string.format("    region[%d] %s shown=%s size=%sx%s alpha=%s tex=%s",
                        i, rtype, rvis, rw, rh, ralpha, rtex))
                end
            end
        end
        Print(string.format("  kui.%-28s = %s%s", k, t, extra))
    end

    -- Regiones directas del kui frame (texturas del fondo, bordes, etc.)
    Print("  --- regiones directas de nameplate.kui ---")
    if kui.GetRegions then
        local regions = { kui:GetRegions() }
        if #regions == 0 then
            Print("  (ninguna)")
        end
        for i, r in ipairs(regions) do
            local rtype  = r.GetObjectType and r:GetObjectType() or "?"
            local rvis   = r.IsShown and (r:IsShown() and "SHOWN" or "hidden") or "?"
            local rw     = r.GetWidth  and string.format("%.0f", r:GetWidth())  or "?"
            local rh     = r.GetHeight and string.format("%.0f", r:GetHeight()) or "?"
            local rtex   = r.GetTexture and tostring(r:GetTexture() or "-") or "-"
            local ratlas = r.GetAtlas and tostring(r:GetAtlas() or "-") or "-"
            local ralpha = r.GetAlpha and string.format("%.2f", r:GetAlpha()) or "?"
            Print(string.format("  region[%d] %s shown=%s size=%sx%s alpha=%s tex=%s atlas=%s",
                i, rtype, rvis, rw, rh, ralpha, rtex, ratlas))
        end
    end

    -- Hijos directos del kui frame
    Print("  --- hijos directos de nameplate.kui ---")
    if kui.GetChildren then
        local children = { kui:GetChildren() }
        if #children == 0 then Print("  (ninguno)") end
        for i, c in ipairs(children) do
            local cn    = c.GetName and c:GetName() or "(sin nombre)"
            local ctype = c.GetObjectType and c:GetObjectType() or "?"
            local cvis  = c.IsShown and (c:IsShown() and "SHOWN" or "hidden") or "?"
            local cw    = c.GetWidth  and string.format("%.0f", c:GetWidth())  or "?"
            local ch    = c.GetHeight and string.format("%.0f", c:GetHeight()) or "?"
            local clv   = c.GetFrameLevel and tostring(c:GetFrameLevel()) or "?"
            Print(string.format("  hijo[%d] %-30s %s shown=%s size=%sx%s level=%s",
                i, cn, ctype, cvis, cw, ch, clv))
        end
    end
end, "vuelca nameplate.kui completo del target para identificar name-fill health frame")

API.RegisterCommand("absorbdbg", function()
    -- Inspecciona el estado del absorb en todos los overlays de grupo activos
    local HUF = HarfordUnitFrames
    if not (HUF and HUF.API and HUF.API.S and HUF.API.S.groupOverlays) then
        Print("[AbsorbDbg] HarfordUnitFrames.API.S.groupOverlays no disponible")
        return
    end
    local count = 0
    for name, overlay in pairs(HUF.API.S.groupOverlays) do
        count = count + 1
        local hBar = overlay.bars and overlay.bars.health
        if hBar then
            local bar  = hBar.bar
            local tf   = hBar.textFrame
            local fill = tf and tf._absorbFill
            local edge = tf and tf._absorbEdge
            local bw   = bar and bar.GetWidth  and bar:GetWidth()  or "?"
            local bh   = bar and bar.GetHeight and bar:GetHeight() or "?"
            local data = overlay.healthData
            local cur  = data and data.cur     or "?"
            local max  = data and data.max     or "?"
            local tmp  = data and data.tempCur or "?"
            local fvis = fill and fill:IsShown() and "SHOW" or "HIDE"
            local evis = edge and edge:IsShown() and "SHOW" or "HIDE"
            Print(string.format("[AbsorbDbg] %s bar=%sx%s cur=%s max=%s tmp=%s fill=%s edge=%s",
                name, bw, bh, tostring(cur), tostring(max), tostring(tmp), fvis, evis))
        end
    end
    if count == 0 then Print("[AbsorbDbg] No hay group overlays activos") end
end, "inspecciona absorb en overlays de raid/party activos")

-- ─── Diagnóstico ParseSections ───────────────────────────────────────────────
API.RegisterCommand("trpsections", function(args)
    local unit = (args and args ~= "") and args or "target"
    Print("=== trpsections: " .. unit .. " ===")
    if not HarfordTRP3 then Print("HarfordTRP3 no disponible") return end

    -- Texto raw
    local function tryProfile()
        if HarfordTRP3.GetEpsilonNpcProfile then
            local p = HarfordTRP3.GetEpsilonNpcProfile(unit)
            if p then return p, "NPC companion" end
        end
        if HarfordTRP3.GetPlayerProfile then
            local p = HarfordTRP3.GetPlayerProfile(unit)
            if p then return p, "player" end
        end
        return nil, "no encontrado"
    end

    local profile, kind = tryProfile()
    if not profile then Print("Perfil: " .. kind) return end
    Print("Perfil tipo: " .. kind)

    local rawText = HarfordTRP3.GetProfileMainText and HarfordTRP3.GetProfileMainText(profile) or nil
    if not rawText or rawText == "" then
        rawText = HarfordTRP3.GetPlayerAboutText and HarfordTRP3.GetPlayerAboutText(profile) or nil
    end

    -- Estructura about si es jugador
    local character = profile.player or profile
    if type(character) == "table" and type(character.about) == "table" then
        local about = character.about
        local template = tonumber(about.TE) or 1
        Print("Template: " .. template)
        if template == 2 then
            local frames = about.T2 or {}
            Print("T2 frames: " .. #frames)
            for i, frame in ipairs(frames) do
                if type(frame) == "table" then
                    Print(string.format("  [%d] TI=%s  TX=%d chars", i,
                        frame.TI and ('"'..tostring(frame.TI)..'"') or "nil",
                        #(frame.TX or "")))
                end
            end
        elseif template == 3 then
            local data = about.T3 or {}
            for _, key in ipairs({"PH","PS","HI"}) do
                local sec = data[key]
                if type(sec) == "table" then
                    Print(string.format("  T3.%s TX=%d chars", key, #(sec.TX or "")))
                end
            end
        elseif template == 1 then
            local tx = about.T1 and about.T1.TX or ""
            Print("T1 TX: " .. #tx .. " chars")
        end
    else
        -- NPC companion
        local rawText = profile.data and profile.data.TX
        if not rawText or rawText == "" then
            Print("TX: vacío")
        else
            Print("TX primeros 400 chars:")
            Print(rawText:sub(1, 400))
            local nh1 = select(2, rawText:gsub("{h1}", ""))
            Print(string.format("{h1}=%d", nh1))
        end
    end

    -- ParseSections
    if HarfordTRP3.ParseSections then
        local sections = HarfordTRP3.ParseSections(profile)
        if not sections then
            Print("ParseSections: nil (sin secciones)")
        else
            Print("ParseSections: " .. #sections .. " sección(es)")
            for i, sec in ipairs(sections) do
                Print(string.format("  [%d] title=%s  body=%d chars",
                    i,
                    sec.title and ('"' .. sec.title .. '"') or "nil",
                    #(sec.body or "")))
            end
        end
    else
        Print("ParseSections: función no disponible")
    end
end, "diagnóstico de secciones TRP3 del target (o unit dado)")

-- ─── Diagnóstico Modo NPC ────────────────────────────────────────────────────
API.RegisterCommand("npcblock", function(args)
    local unit = (args and args ~= "") and args or "target"
    Print("=== npcblock: " .. unit .. " ===")

    -- 1. ¿Existe el unit?
    if not UnitExists(unit) then
        Print("Unit '" .. unit .. "' no existe")
        return
    end
    Print("UnitName: " .. tostring(UnitName(unit)))
    Print("UnitIsPlayer: " .. tostring(UnitIsPlayer(unit)))

    -- 2. Intentar companion profile (NPC real Epsilon)
    if HarfordTRP3 and HarfordTRP3.GetEpsilonNpcProfile then
        local prof, err = HarfordTRP3.GetEpsilonNpcProfile(unit)
        if prof then
            local tx = prof.data and prof.data.TX
            Print("CompanionProfile OK — data.TX length: " .. tostring(tx and #tx or 0))
            if tx and #tx > 0 then
                Print("--- primeros 300 chars de data.TX ---")
                Print(tx:sub(1, 300))
            else
                Print("data.TX vacio o nil")
            end
        else
            Print("GetEpsilonNpcProfile fallo: " .. tostring(err))
        end
    else
        Print("HarfordTRP3.GetEpsilonNpcProfile no disponible")
    end

    -- 3. Intentar player profile (NPC interpretado por jugador)
    if HarfordTRP3 and HarfordTRP3.GetPlayerProfile then
        local prof2 = HarfordTRP3.GetPlayerProfile(unit)
        if prof2 then
            Print("PlayerProfile OK")
            if HarfordTRP3.GetPlayerAboutText then
                local txt, err2 = HarfordTRP3.GetPlayerAboutText(prof2)
                Print("AboutText length: " .. tostring(txt and #txt or 0) .. " err=" .. tostring(err2))
                if txt and #txt > 0 then
                    Print("--- primeros 300 chars de AboutText ---")
                    Print(txt:sub(1, 300))
                end
            end
        else
            Print("GetPlayerProfile nil")
        end
    end

    -- 4. Resultado final del parser
    if HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local parsed, perr = HarfordTRP3.GetNPCStatBlock(unit)
        if not parsed then
            Print("GetNPCStatBlock FALLO: " .. tostring(perr))
            return
        end
        Print("GetNPCStatBlock OK")
        Print("  rawHeader: " .. tostring(parsed.rawHeader))
        Print("  ac: " .. tostring(parsed.ac) .. " acDesc: " .. tostring(parsed.acDesc))
        local statNames = {"strength","dexterity","constitution","intelligence","wisdom","charisma"}
        for _, k in ipairs(statNames) do
            local s = parsed.stats and parsed.stats[k]
            if s then
                Print("  " .. k .. " = score:" .. tostring(s.score) .. " mod:" .. tostring(s.mod))
            else
                Print("  " .. k .. " = MISSING")
            end
        end
        if next(parsed.savingThrows) then
            Print("  savingThrows:")
            for k, v in pairs(parsed.savingThrows) do
                Print("    " .. k .. " = " .. tostring(v))
            end
        else
            Print("  savingThrows: (ninguna)")
        end
        if parsed.skills and #parsed.skills > 0 then
            Print("  skills:")
            for _, skill in ipairs(parsed.skills) do
                Print("    " .. tostring(skill.name) .. " = " .. tostring(skill.bonus))
            end
        else
            Print("  skills: (ninguna)")
        end
    end

    -- 5. Estado actual del contexto externo de ficha en la API
    if HarfordDnDAPI then
        Print("HasSheetContext: " .. tostring(HarfordDnDAPI.HasSheetContext and HarfordDnDAPI.HasSheetContext()))
    end
end, "diagnóstico completo del stat block NPC del target (arg: unit, default=target)")

-- ─── Diagnostico: retrato del PlayerFrame que revierte a 3D ───────────────────
-- Caso a investigar: con icono TRP3 en el retrato del player (modo "frame"), al
-- aplicar ciertas auras (p.ej. "llamas" + "asustado") a un NPC, el retrato del
-- player vuelve al modelo 3D hasta el siguiente cambio de target. Este comando
-- registra los eventos relevantes y hookea SetPortraitTexture (guarded) para ver
-- QUIEN/CUANDO repinta el retrato del player. hooksecurefunc no se desinstala,
-- pero todo el log queda tras un flag _pwActive, asi que es inocuo cuando esta off.
do
    local _pw = { active = false, count = 0, max = 120, hooked = false, frame = nil, untilTime = 0 }

    local function PlayerPortraitRegion()
        return _G.PlayerPortrait or (_G.PlayerFrame and _G.PlayerFrame.portrait) or nil
    end

    local function PortraitTexDesc()
        local region = PlayerPortraitRegion()
        if not (region and region.GetTexture) then return "sin region" end
        local tex = region:GetTexture()
        if type(tex) == "string" then return "icono:" .. tex end
        if tex == nil then return "modelo3D/nil" end
        return "fileID:" .. tostring(tex)  -- numerico => normalmente modelo/portrait nativo
    end

    local function PWLog(what)
        if not _pw.active then return end
        if _pw.count >= _pw.max then return end
        _pw.count = _pw.count + 1
        Print(string.format("|cff88ccff[pw %02d]|r %s | retrato=%s", _pw.count, tostring(what), PortraitTexDesc()))
    end

    local function StopWatch()
        if not _pw.active then return end
        _pw.active = false
        if _pw.frame then _pw.frame:UnregisterAllEvents() end
        Print("portraitwatch finalizado (" .. tostring(_pw.count) .. " lineas)")
    end

    API.RegisterCommand("portraitwatch", function(args)
        local arg = tostring(args or ""):lower():match("^%s*(%S*)")
        if arg == "off" then StopWatch() return end

        local seconds = tonumber(tostring(args or ""):match("(%d+)")) or 20
        seconds = math.max(5, math.min(60, seconds))

        _pw.active = true
        _pw.count = 0
        _pw.untilTime = (GetTime and GetTime() or 0) + seconds

        if not _pw.frame then
            _pw.frame = CreateFrame("Frame")
            _pw.frame:SetScript("OnEvent", function(_, event, unit)
                if unit == nil or unit == "player" or unit == "target" then
                    PWLog(event .. (unit and (":" .. tostring(unit)) or ""))
                end
            end)
        end
        _pw.frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        _pw.frame:RegisterEvent("UNIT_AURA")
        _pw.frame:RegisterEvent("UNIT_MODEL_CHANGED")
        _pw.frame:RegisterEvent("UNIT_DISPLAYPOWER")
        _pw.frame:RegisterEvent("PLAYER_TARGET_CHANGED")

        -- Hook (una sola vez) del repintado nativo del retrato. Si algo llama a
        -- SetPortraitTexture sobre el retrato del player, AQUI se ve el culpable:
        -- el addon, con icono TRP3, NO usa SetPortraitTexture (usa SetTexture), asi
        -- que cualquier llamada sobre el player viene de Blizzard.
        if not _pw.hooked and hooksecurefunc then
            local region = PlayerPortraitRegion()
            if type(SetPortraitTexture) == "function" then
                hooksecurefunc("SetPortraitTexture", function(tex, u)
                    if not _pw.active then return end
                    if tex == PlayerPortraitRegion() or u == "player" then
                        PWLog("!! SetPortraitTexture(player) unit=" .. tostring(u))
                    end
                end)
            end
            if type(_G.UnitFramePortrait_Update) == "function" then
                hooksecurefunc("UnitFramePortrait_Update", function(self)
                    if not _pw.active then return end
                    if self == _G.PlayerFrame then PWLog("!! UnitFramePortrait_Update(PlayerFrame)") end
                end)
            end
            if region and region.SetTexture and not region._pwTexHooked then
                hooksecurefunc(region, "SetTexture", function(_, value)
                    if not _pw.active then return end
                    PWLog("PlayerPortrait:SetTexture(" .. tostring(value) .. ")")
                end)
                region._pwTexHooked = true
            end
            _pw.hooked = true
        end

        Print("portraitwatch activo " .. tostring(seconds) .. "s — aplica ahora las auras al NPC. (off para parar)")
        PWLog("start")
        if C_Timer and C_Timer.After then
            C_Timer.After(seconds, StopWatch)
        end
    end, "diagnostica que repinta el retrato del player (auras llamas/asustado). arg: [segundos]|off")
end
-- ─── Fin diagnostico retrato player ───────────────────────────────────────────

-- Prueba del motor de secuencias (HarfordActionSequence). Replica el ejemplo de
-- ArcSpell: anim + sonido nearby + .npc cast repetidos. Util como regresion.
API.RegisterCommand("seqtest", function()
    if not (HarfordActionSequence and HarfordActionSequence.Run) then
        Print("seqtest: HarfordActionSequence no disponible.")
        return
    end
    Print("seqtest: lanzando secuencia (comandos EpsilonLib + sonido TRP3e).")
    HarfordActionSequence.Run({
        { delay = 0,   actionType = "Anim", vars = "3322" },
        { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20" },
        { delay = 0.1, actionType = "Command", vars = ".npc cast 78960" },
        { delay = 0.6, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20" },
        { delay = 0.6, actionType = "Command", vars = ".npc cast 78960" },
        { delay = 1,   actionType = "Anim", vars = "333" },
    }, { addonName = "HarfordAdmin" })
end, "ejecuta una secuencia de ejemplo via HarfordActionSequence")

-- Verifica la intercepcion de impacto: corre OnehandAttack con interceptImpact;
-- los `.npc cast` no se envian, sino que imprimen el momento del impacto.
API.RegisterCommand("seqimpact", function()
    if not (HarfordActionSequence and HarfordActionSequence.RunByName) then
        Print("seqimpact: HarfordActionSequence no disponible.")
        return
    end
    Print("seqimpact: OnehandAttack con interceptImpact (los impactos se imprimen, no se castean).")
    local n = 0
    HarfordActionSequence.RunByName("OnehandAttack", {
        addonName = "HarfordAdmin",
        interceptImpact = true,
        onImpact = function()
            n = n + 1
            Print("seqimpact: IMPACTO #" .. n .. " (aqui iria herida/defensa al objetivo).")
        end,
    })
end, "prueba la intercepcion de impacto (onImpact) de un preset de ataque")

-- Envia `.npc emote <id>` (one-shot) sobre el NPC target actual. Sirve para probar
-- que ID renderiza un parry visible (p.ej. 441) frente al dodge (2030).
API.RegisterCommand("npcemote", function(args)
    local id = tonumber((tostring(args or ""):match("(%d+)")))
    if not id then
        Print("uso: /harford debug run npcemote <id>  (target = NPC). Ej: 441 (parry), 2030 (dodge)")
        return
    end
    if not (HarfordServerActions and HarfordServerActions.SetNpcEmote) then
        Print("npcemote: HarfordServerActions.SetNpcEmote no disponible.")
        return
    end
    Print("npcemote: .npc emote " .. id .. " sobre el target.")
    HarfordServerActions.SetNpcEmote(id, { addonName = "HarfordAdmin" })
end, "envia .npc emote <id> al NPC target (probar parry/dodge)")

-- Muestra la distribucion de PickDefenseSeq (sin modo = default one_hand) en 20 tiradas
-- para comprobar que alterna parry/dodge (no que siempre sale lo mismo).
API.RegisterCommand("defrand", function()
    if not (HarfordEmotes and HarfordEmotes.PickDefenseSeq) then
        Print("defrand: HarfordEmotes.PickDefenseSeq no disponible.")
        return
    end
    local counts = {}
    local line = {}
    for _ = 1, 20 do
        local seq = HarfordEmotes.PickDefenseSeq(nil, false) or "nil"
        counts[seq] = (counts[seq] or 0) + 1
        line[#line + 1] = seq
    end
    Print("defrand: " .. table.concat(line, ", "))
    for seq, n in pairs(counts) do
        Print("  " .. seq .. ": " .. n)
    end
end, "distribucion de PickDefenseSeq en 20 tiradas (parry/dodge)")

local function CountTable(tbl)
    local count = 0
    if type(tbl) ~= "table" then return 0 end
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

local function RefreshAfterSavedVariableClean()
    if HarfordReputationUI and HarfordReputationUI.Refresh then HarfordReputationUI.Refresh() end
    if HarfordReputationAdmin and HarfordReputationAdmin.Refresh then HarfordReputationAdmin.Refresh() end
end

local SAVED_VARIABLES = {
    "HarfordLootTaggedCreatureRegistry",
    "HarfordLootLootRegistry",
    "HarfordLootGlobalLootRegistry",
    "HarfordDnDMinimapSettings",
    "HarfordDnDPersistStore",
    "HarfordDnDTargetResourceSettings",
    "HarfordTurnOrderStore",
    "HarfordDebugSettings",
    "HarfordConfigStore",
    "HarfordReputationStore",
    "HarfordFrameProbe",
    "HarfordCompendioDB",
    "HarfordContractsDB",
    "HarfordQuestsStore",
}

local SAVED_VARIABLES_PER_CHARACTER = {
    "HarfordCompendioCharacterDB",
}

local function PurgeAllSavedVariables()
    local purged = 0
    for _, name in ipairs(SAVED_VARIABLES) do
        if _G[name] ~= nil then
            _G[name] = nil
            purged = purged + 1
            Print("SV purgada: " .. name)
        end
    end
    for _, name in ipairs(SAVED_VARIABLES_PER_CHARACTER) do
        if _G[name] ~= nil then
            _G[name] = nil
            purged = purged + 1
            Print("SV personaje purgada: " .. name)
        end
    end

    if HarfordDnDStore and HarfordDnDStore.state then
        HarfordDnDStore.state.persist = {}
        HarfordDnDStore.state.runtime = {}
    end

    Print("Purgadas " .. tostring(purged) .. " SavedVariables de Harford. Haz /reload para reconstruir desde cero.")
    return purged
end

API.RegisterCommand("svclean", function(args)
    args = tostring(args or ""):lower()
    local action = args:match("^%s*(%S+)") or "status"

    local function CleanReputationLogs()
        if type(HarfordReputationStore) == "table" then
            local count = CountTable(HarfordReputationStore.logs)
            HarfordReputationStore.logs = nil
            Print("logs de reputacion eliminados: " .. tostring(count))
            return count
        end
        Print("HarfordReputationStore no existe.")
        return 0
    end

    local function CleanNpcLinks()
        if type(HarfordReputationStore) == "table" then
            local count = CountTable(HarfordReputationStore.npcLinks)
            HarfordReputationStore.npcLinks = nil
            Print("npcLinks eliminados: " .. tostring(count))
            RefreshAfterSavedVariableClean()
            return count
        end
        Print("HarfordReputationStore no existe.")
        return 0
    end

    local function CleanGuilds()
        if type(HarfordReputationStore) == "table" then
            local count = CountTable(HarfordReputationStore.guilds)
            HarfordReputationStore.guilds = nil
            Print("guilds obsoleto eliminado: " .. tostring(count))
            RefreshAfterSavedVariableClean()
            return count
        end
        Print("HarfordReputationStore no existe.")
        return 0
    end

    local function CleanTargetResourceSettings(force)
        local settings = HarfordDnDTargetResourceSettings
        if type(settings) ~= "table" then
            Print("target resource settings: nada que limpiar.")
            return 0
        end

        if settings.userPlaced == true and not force then
            Print("target resource settings conserva posicion manual. Usa 'targetpos force' para borrarla.")
            return 0
        end

        HarfordDnDTargetResourceSettings = nil
        Print("target resource settings eliminado.")
        return 1
    end

    -- El sistema de votos del tablon se retiro, pero su tabla sigue en las SavedVariables de
    -- quien la tuviera: no la borra nadie porque ya no hay codigo que la mire.
    -- `HarfordDebugSettings` no son solo ajustes: guarda dos acumuladores de diagnostico. El
    -- soundLog esta acotado a 400 entradas; el merchantDump crece a proposito, porque es el
    -- catalogo de ids de Epsilon que se va construyendo, y son ~35 bytes por entrada. Lo que
    -- faltaba era poder vaciarlos cuando ya no hacen falta.
    local function CleanDebugDumps()
        local st = _G.HarfordDebugSettings
        if type(st) ~= "table" then Print("svclean debug: nada guardado."); return end
        local sonidos = type(st.soundLog) == "table" and #st.soundLog or 0
        local mercaderes = 0
        for _ in pairs(type(st.merchantDump) == "table" and st.merchantDump or {}) do
            mercaderes = mercaderes + 1
        end
        st.soundLog, st.merchantDump = nil, nil
        Print(string.format("svclean debug: %d entrada(s) de sonido y %d id(s) de mercader retirados.",
            sonidos, mercaderes))
    end

    local function CleanContractLeftovers()
        local db = _G.HarfordContractsDB
        if type(db) ~= "table" then Print("svclean contratos: no hay tablon guardado."); return end
        local quitados = 0
        for _, clave in ipairs({ "votes", "voteResets" }) do
            if db[clave] ~= nil then db[clave] = nil; quitados = quitados + 1 end
        end
        Print(quitados > 0
            and string.format("svclean contratos: %d resto(s) del sistema de votos retirado(s).", quitados)
            or "svclean contratos: nada que limpiar.")
    end

    -- `addedAt` era una marca de tiempo por contacto que no leia nadie: ni ordena la lista (va
    -- alfabetica), ni se muestra, ni caduca nada. Se dejo de escribir; esto retira las que ya
    -- estaban en disco.
    local function CleanCommunicatorLeftovers()
        local store = _G.HarfordCommunicatorStore
        if type(store) ~= "table" or type(store.contacts) ~= "table" then
            Print("svclean comunicador: no hay contactos guardados.")
            return
        end
        local quitados = 0
        for _, contacto in pairs(store.contacts) do
            if type(contacto) == "table" and contacto.addedAt ~= nil then
                contacto.addedAt = nil
                quitados = quitados + 1
            end
        end
        Print(quitados > 0
            and string.format("svclean comunicador: %d marca(s) de tiempo sin uso retirada(s).", quitados)
            or "svclean comunicador: nada que limpiar.")
    end

    local function CleanFrameProbe()
        local count = CountTable(HarfordFrameProbe)
        HarfordFrameProbe = nil
        Print("HarfordFrameProbe eliminado: " .. tostring(count) .. " claves. Haz /reload para descargarlo de SavedVariables.")
        return count
    end

    local function CleanDnDDefaults()
        if HarfordDnDStore and HarfordDnDStore.PrunePersistedProfiles then
            local removed = HarfordDnDStore.PrunePersistedProfiles()
            Print("defaults de perfiles DnD eliminados: " .. tostring(removed or 0))
            return removed or 0
        end
        Print("HarfordDnDStore.PrunePersistedProfiles no disponible.")
        return 0
    end

    if action == "status" or action == "" then
        local rep = type(HarfordReputationStore) == "table" and HarfordReputationStore or {}
        Print("HarfordReputation.logs: " .. tostring(CountTable(rep.logs)))
        Print("HarfordReputation.npcLinks: " .. tostring(CountTable(rep.npcLinks)) .. " (obsoleto; usar svclean npclinks)")
        Print("HarfordReputation.guilds: " .. tostring(CountTable(rep.guilds)) .. " (obsoleto; la reputacion es por PJ)")
        local settings = HarfordDnDTargetResourceSettings
        if type(settings) == "table" then
            Print("TargetResourceSettings: userPlaced=" .. tostring(settings.userPlaced) .. " x=" .. tostring(settings.x) .. " y=" .. tostring(settings.y))
        else
            Print("TargetResourceSettings: nil")
        end
        Print("HarfordFrameProbe: " .. tostring(CountTable(HarfordFrameProbe)) .. " claves (debug; usar svclean frameprobe tras probeframe)")
        local ps = type(HarfordDnDPersistStore) == "table" and HarfordDnDPersistStore or {}
        -- Progresion/equipo/dados/usos ahora viven anidados en profiles[name]._x; contamos
        -- cuantos perfiles tienen cada uno. (Las top-level antiguas se migran y quedan nil.)
        local nProg, nEquip, nHit, nUses = 0, 0, 0, 0
        for _, p in pairs(type(ps.profiles) == "table" and ps.profiles or {}) do
            if type(p) == "table" then
                if type(p._progression) == "table" then nProg = nProg + 1 end
                if type(p._equipment) == "table" then nEquip = nEquip + 1 end
                if type(p._hitDice) == "table" then nHit = nHit + 1 end
                if type(p._featureUses) == "table" then nUses = nUses + 1 end
            end
        end
        Print("DnD persist: profiles=" .. tostring(CountTable(ps.profiles))
            .. " (_progression=" .. nProg .. " _equipment=" .. nEquip
            .. " _hitDice=" .. nHit .. " _featureUses=" .. nUses .. ")")
        local legacy = CountTable(ps.equipment) + CountTable(ps.classProgression) + CountTable(ps.hitDice) + CountTable(ps.featureUses)
        if legacy > 0 then Print("  top-level antiguas sin migrar: " .. legacy .. " (se migran al cargar)") end
        if HarfordDnDStore and HarfordDnDStore.PrunePersistedProfiles then
            Print("DnD profile pruning: disponible ('svclean dnd' poda defaults + contadores a 0)")
        end
        Print("Purgado total: /harford debug run svclean purge confirm")
        return
    end

    if action == "safe" then
        CleanDnDDefaults()
        CleanReputationLogs()
        CleanTargetResourceSettings(false)
        CleanFrameProbe()
        CleanContractLeftovers()
        CleanCommunicatorLeftovers()
        return
    end

    if action == "logs" then CleanReputationLogs(); return end
    if action == "npclinks" then CleanNpcLinks(); return end
    if action == "guilds" then CleanGuilds(); return end
    if action == "dnd" then CleanDnDDefaults(); return end
    if action == "frameprobe" then CleanFrameProbe(); return end
    if action == "contratos" then CleanContractLeftovers(); return end
    if action == "comunicador" then CleanCommunicatorLeftovers(); return end
    if action == "debug" then CleanDebugDumps(); return end
    if action == "targetpos" then
        local force = args:match("%s+force%s*$") ~= nil
        CleanTargetResourceSettings(force)
        return
    end
    if action == "all" then
        CleanDnDDefaults()
        CleanReputationLogs()
        CleanNpcLinks()
        CleanGuilds()
        CleanTargetResourceSettings(true)
        CleanFrameProbe()
        CleanContractLeftovers()
        CleanCommunicatorLeftovers()
        CleanDebugDumps()
        return
    end
    if action == "purge" then
        if not args:match("%s+confirm%s*$") then
            Print("PELIGRO: borra TODAS las SavedVariables de Harford declaradas en el .toc.")
            Print("Uso confirmado: /harford debug run svclean purge confirm")
            return
        end
        PurgeAllSavedVariables()
        return
    end

    Print("uso: /harford debug run svclean status|safe|dnd|logs|npclinks|guilds|frameprobe|contratos|comunicador|debug|targetpos [force]|all|purge confirm")
end, "limpia SavedVariables obsoletas/controladas")

-- Diagnostico en vivo del fondo del modelo 3D del panel de personaje. Abre antes el panel
-- con /harford char (pestana Ficha). Permite probar tokens de DressUpBackground y contraste.
API.RegisterCommand("modelbg", function(args)
    if not (HarfordCharacterPanel and HarfordCharacterPanel.DebugModelBg) then
        Print("HarfordCharacterPanel.DebugModelBg no disponible")
        return
    end
    Print(tostring(HarfordCharacterPanel.DebugModelBg(args)))
end, "fondo modelo 3D: modelbg [info|reset|<Token>|desat 0/1|dark 0..1|bright 0..1]")

-- Auditoria del sistema de conjuros usando el clasificador REAL del compendio
-- (HarfordCompendioAPI.BuildAreaDefinition), no una replica. Reporta como enruta cada
-- conjuro (ataque directo / salvacion / auto-impacto / zona / informativo) y lista los que
-- caen en "informativo" pese a tener dados de dano o salvacion en el texto: esos son los
-- candidatos a mapear (dar campo condition/autohit/zone o ajustar su texto).
--   /harford debug run spellaudit            -> resumen + candidatos
--   /harford debug run spellaudit full       -> ademas lista TODOS los candidatos
API.RegisterCommand("spellaudit", function(args)
    local capi = _G.HarfordCompendioAPI
    if not (capi and capi.GetAllSpells and capi.BuildAreaDefinition) then
        Print("HarfordCompendioAPI no disponible (compendio no cargado)")
        return
    end
    local showAll = tostring(args or ""):lower():find("full", 1, true) ~= nil

    local counts = { attack = 0, save = 0, auto = 0, info = 0 }
    local zoneN, condN, total = 0, 0, 0
    local candidates = {}  -- info-routed con dados de dano o palabra salvacion

    for _, spell in ipairs(capi.GetAllSpells()) do
        total = total + 1
        if spell.condition then condN = condN + 1 end
        local def = capi.BuildAreaDefinition(spell)
        if def and def.area then
            local res = def.area.resolution or "info"
            counts[res] = (counts[res] or 0) + 1
            if def.area.zone then zoneN = zoneN + 1 end
        else
            counts.info = counts.info + 1
            local text = ((spell.damage or "") .. " " .. (spell.mechanics or "")
                .. " " .. (spell.attack or "")):lower()
            local hasDice = text:find("%dd%d") ~= nil
            local hasSave = text:find("salvaci") ~= nil
            if hasDice or hasSave then
                local tag = (hasDice and "dado" or "") .. ((hasDice and hasSave) and "+" or "")
                    .. (hasSave and "salv" or "")
                candidates[#candidates + 1] = tostring(spell.name or spell.id or "?") .. " (" .. tag .. ")"
            end
        end
    end

    Print(string.format("Conjuros: %d | ataque=%d salv=%d auto=%d info=%d (zona=%d, condicion=%d)",
        total, counts.attack, counts.save, counts.auto, counts.info, zoneN, condN))
    Print(string.format("Candidatos a automatizar (info con dado/salvacion): %d", #candidates))
    local limit = showAll and #candidates or math.min(15, #candidates)
    for i = 1, limit do Print("  - " .. candidates[i]) end
    if not showAll and #candidates > limit then
        Print(string.format("  ... y %d mas. Usa 'spellaudit full' para verlos todos.", #candidates - limit))
    end
end, "audita el enrutado de conjuros y lista candidatos a automatizar")

-- Inspecciona/prueba las recompensas compartidas (XP/rep) de los contratos: que contratos las
-- llevan, su estado y si YA las cobre; permite resetear un cobro y forzar la reconciliacion (util
-- para validar la recuperacion offline: reset -> reconcile -> se vuelve a conceder + anuncia).
--   /harford debug run contractrewards                -> status
--   /harford debug run contractrewards reset <id>     -> retira mi cobro de ese contrato
--   /harford debug run contractrewards reconcile      -> fuerza la reconciliacion ahora
API.RegisterCommand("contractrewards", function(args)
    local HC = _G.HarfordContracts
    if not (HC and HC.GetDB) then Print("HarfordContracts no disponible") return end
    args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if args:lower() == "reconcile" then
        if HC.Rewards and HC.Rewards.Reconcile then HC.Rewards.Reconcile() end
        Print("reconcile ejecutado")
        return
    end

    local resetId = args:match("^[Rr]eset%s+(.+)$")
    if resetId then
        if HarfordQuests and HarfordQuests.ResetClaim then
            HarfordQuests.ResetClaim("contract:" .. resetId)
            Print("cobro reseteado para contrato: " .. resetId)
        else
            Print("HarfordQuests.ResetClaim no disponible")
        end
        return
    end

    local db = HC.GetDB()
    Print("contratos con recompensa compartida (XP/rep):")
    local n = 0
    for _, c in ipairs(db.contracts or {}) do
        if tonumber(c.rewardXP) or type(c.rewardRep) == "table" then
            n = n + 1
            local rep = type(c.rewardRep) == "table"
                and (tostring(c.rewardRep.amount) .. " " .. tostring(c.rewardRep.faction)) or "-"
            local claimed = HarfordQuests and HarfordQuests.IsClaimed
                and HarfordQuests.IsClaimed("contract:" .. tostring(c.id))
            Print(string.format("  [%s] %s | estado=%s | xp=%s rep=%s | cobrada=%s",
                tostring(c.id), tostring(c.title), tostring(c.status),
                tostring(c.rewardXP or "-"), rep, claimed and "SI" or "no"))
        end
    end
    if n == 0 then Print("  (ninguno)") end
end, "recompensas de contrato: status|reset <id>|reconcile")

API.RegisterCommand("contractclean", function(args)
    args = tostring(args or ""):lower():match("^%s*(.-)%s*$")
    if args ~= "quests" then
        Print("uso: /harford debug run contractclean quests")
        return
    end
    if not (HarfordQuests and HarfordQuests.Prune) then
        Print("HarfordQuests.Prune no disponible")
        return
    end
    Print("entradas de misiones eliminadas: " .. tostring(HarfordQuests.Prune()))
end, "limpieza explicita: quests")

-- Acepta misiones de ejemplo para probar el quest log y el tracker en pantalla sin un contrato real.
-- Sub-usos:
--   questtest              -> acepta 2 misiones del catalogo (objetivos con contador) y rastrea una
--   questtest clear        -> abandona todas las aceptadas
--   questtest obj <id> <i> <n>  -> fija el contador n del objetivo i (SetObjectiveProgress)
--   questtest adv <id> <i> -> +1 al objetivo i (AdvanceObjective)
--   questtest done <id>    -> cierra la mision para el grupo (CompleteForGroup; requiere DM)
HarfordDebug.RegisterCommand("questtest", function(args)
    if not (HarfordQuests and HarfordQuests.Accept) then Print("HarfordQuests no disponible") return end
    local raw = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local sub = raw:match("^(%S+)")
    sub = sub and sub:lower() or ""

    if sub == "clear" then
        for _, q in ipairs(HarfordQuests.GetAccepted() or {}) do HarfordQuests.Abandon(q.id) end
        Print("misiones de prueba eliminadas")
        return
    elseif sub == "obj" then
        local id, i, n = raw:match("^%S+%s+(%S+)%s+(%d+)%s+(%d+)")
        if not id then Print("uso: questtest obj <id> <objetivo> <valor>") return end
        Print(HarfordQuests.SetObjectiveProgress(id, tonumber(i), tonumber(n)) and "objetivo actualizado" or "no se pudo")
        return
    elseif sub == "adv" then
        local id, i = raw:match("^%S+%s+(%S+)%s+(%d+)")
        if not id then Print("uso: questtest adv <id> <objetivo>") return end
        Print(HarfordQuests.AdvanceObjective(id, tonumber(i)) and "objetivo +1" or "no se pudo")
        return
    elseif sub == "done" then
        local id = raw:match("^%S+%s+(%S+)")
        if not id then Print("uso: questtest done <id>") return end
        Print(HarfordQuests.CompleteForGroup(id) and "mision cerrada para el grupo" or "sin autoridad DM o mision inexistente")
        return
    end

    -- Sin sub: acepta desde el catalogo (solo id -> el addon rellena objetivos/recompensa).
    HarfordQuests.Accept("world:heraldo_rocavarancolia")
    HarfordQuests.Accept("world:ecos_bajo_la_mina")
    HarfordQuests.SetTracked("world:heraldo_rocavarancolia", true)
    Print("2 misiones del catalogo aceptadas; 'world:heraldo_rocavarancolia' rastreada.")
    Print("Prueba: /harford debug run questtest adv world:heraldo_rocavarancolia 2")
end, "misiones de ejemplo: (sin arg)|clear|obj <id> <i> <n>|adv <id> <i>|done <id>")

-- Escanea las auras de una unidad (target por defecto) e imprime spellId+nombre. Diagnostico para
-- verificar auras de estado de quest sobre NPCs (155096/245633/252527). Defensivo con la API que
-- exista: C_UnitAuras (retail nuevo), UnitAura (clasico) o AuraUtil.ForEachAura como fallback.
HarfordDebug.RegisterCommand("scanauras", function(args)
    local unit = tostring(args or ""):gsub("%s+", "")
    if unit == "" then unit = "target" end
    if not UnitExists(unit) then Print("scanauras: no existe la unidad '" .. unit .. "'") return end
    Print("Auras de " .. (UnitName(unit) or unit) .. ":")
    local found = 0
    local function report(filter, index, id, name)
        found = found + 1
        Print(string.format("  [%s] %d  id=%s  %s", filter, index, tostring(id or "?"), tostring(name or "?")))
    end
    local function scan(filter)
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            for i = 1, 60 do
                local a = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
                if not a then break end
                report(filter, i, a.spellId, a.name)
            end
        elseif UnitAura then
            for i = 1, 60 do
                local n, _, _, _, _, _, _, _, _, sid = UnitAura(unit, i, filter)
                if not n then break end
                report(filter, i, sid, n)
            end
        elseif AuraUtil and AuraUtil.ForEachAura then
            local i = 0
            AuraUtil.ForEachAura(unit, filter, nil, function(name, _, _, _, _, _, _, _, _, spellId)
                i = i + 1
                report(filter, i, spellId, name)
            end)
        end
    end
    scan("HELPFUL")
    scan("HARMFUL")
    if found == 0 then Print("  (ninguna aura visible al cliente)") end
end, "escanea auras del target (o unidad dada) e imprime spellId+nombre")

-- Compara el icono que devuelve la API de auras con los botones visibles del frame nativo.
-- No modifica nada: sirve para detectar si el cliente ha reciclado un BuffN de otra unidad.
HarfordDebug.RegisterCommand("auramatch", function(args)
    local requested = tostring(args or ""):gsub("%s+", "")
    local units = requested ~= "" and { requested } or { "player", "target", "focus" }
    local function prefixFor(unit)
        if unit == "player" then return "PlayerFrame" end
        if unit == "focus" then return "FocusFrame" end
        return "TargetFrame"
    end
    local function auraIcon(unit, index, filter)
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
            return aura and aura.icon or nil, aura and aura.name or nil, aura and aura.spellId or nil
        end
        if UnitAura then
            local name, icon, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, filter)
            return icon, name, spellId
        end
    end
    for _, unit in ipairs(units) do
        if not UnitExists(unit) then
            Print("auramatch: no existe " .. tostring(unit))
        else
            local prefix = prefixFor(unit)
            local harfordFrame = HarfordUnitFrames and HarfordUnitFrames.GetFrame and HarfordUnitFrames.GetFrame(unit)
            Print("auramatch " .. tostring(unit) .. " (" .. tostring(UnitName(unit) or "?") .. ")"
                .. " barras=" .. tostring(harfordFrame and harfordFrame.resourceCount or "-") .. ":")
            for _, row in ipairs({ { "HELPFUL", "Buff" }, { "HARMFUL", "Debuff" } }) do
                for index = 1, 4 do
                    local expected, name, spellId = auraIcon(unit, index, row[1])
                    local button = _G[prefix .. row[2] .. index]
                    local icon = _G[prefix .. row[2] .. index .. "Icon"]
                    local actual = icon and icon.GetTexture and icon:GetTexture() or nil
                    local shown = button and button.IsShown and button:IsShown() or false
                    if expected or shown then
                        local resolved = spellId and GetSpellTexture and GetSpellTexture(spellId) or nil
                        local owner = button and button._harfordAuraUnit or "-"
                        local ownerFilter = button and button._harfordAuraFilter or "-"
                        local ownerIndex = button and button._harfordAuraIndex or "-"
                        Print(string.format("  %s%d api=%s/%s id=%s resuelto=%s native=%s visible=%s harford=%s/%s/%s", row[2], index,
                            tostring(name or "-"), tostring(expected or "-"), tostring(spellId or "-"),
                            tostring(resolved or "-"), tostring(actual or "-"), tostring(shown), tostring(owner),
                            tostring(ownerFilter), tostring(ownerIndex)))
                    end
                end
            end
        end
    end
end, "compara API y botones nativos de auras: auramatch [player|target|focus]")

-- Auditoria acotada para el cruce de auras target/focus y el hover de barras extra.
-- Solo observa el estado: no oculta, ancla ni cambia niveles de ningun frame.
do
    local watcher
    local running = false
    local entries = {}
    local MAX_ENTRIES = 80

    local function ObjectName(object)
        return object and object.GetName and object:GetName() or nil
    end

    local function Point(object)
        if not object or not object.GetPoint then return nil end
        local point, relativeTo, relativePoint, x, y = object:GetPoint(1)
        return {
            point = point,
            relativeTo = ObjectName(relativeTo),
            relativePoint = relativePoint,
            x = x or 0,
            y = y or 0,
        }
    end

    local function Rect(object)
        if not object then return nil end
        return {
            shown = object.IsShown and object:IsShown() or false,
            strata = object.GetFrameStrata and object:GetFrameStrata() or nil,
            level = object.GetFrameLevel and object:GetFrameLevel() or nil,
            top = object.GetTop and object:GetTop() or nil,
            bottom = object.GetBottom and object:GetBottom() or nil,
            point = Point(object),
        }
    end

    local function AuraCount(unit, filter)
        local count = 0
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            for index = 1, 40 do
                if not C_UnitAuras.GetAuraDataByIndex(unit, index, filter) then break end
                count = index
            end
        elseif UnitAura then
            for index = 1, 40 do
                if not UnitAura(unit, index, filter) then break end
                count = index
            end
        end
        return count
    end

    local function AuraSlot(prefix, kind)
        local button = _G[prefix .. kind .. "1"]
        local icon = _G[prefix .. kind .. "1Icon"]
        local out = Rect(button) or {}
        out.texture = icon and icon.GetTexture and icon:GetTexture() or nil
        out.iconShown = icon and icon.IsShown and icon:IsShown() or false
        return out
    end

    local function HarfordFrameState(unit)
        local frame = HarfordUnitFrames and HarfordUnitFrames.GetFrame and HarfordUnitFrames.GetFrame(unit)
        if not frame then return nil end
        local state = Rect(frame) or {}
        state.resourceCount = frame.resourceCount
        state.extraResourceHeight = frame.extraResourceHeight
        state.bars = {}
        for index = 3, frame.maxBarIndex or 0 do
            local bar = frame.bars and frame.bars[index]
            if bar then state.bars[index] = Rect(bar.container or bar) end
        end
        return state
    end

    local function Capture(reason)
        local mouse = GetMouseFocus and GetMouseFocus() or nil
        local row = {
            time = GetTime and GetTime() or 0,
            reason = reason,
            mouseFocus = ObjectName(mouse),
            units = {},
        }
        for _, unit in ipairs({ "player", "target", "focus" }) do
            local prefix = unit == "player" and "PlayerFrame" or (unit == "focus" and "FocusFrame" or "TargetFrame")
            row.units[unit] = {
                exists = UnitExists and UnitExists(unit) or false,
                guid = UnitGUID and UnitGUID(unit) or nil,
                name = UnitName and UnitName(unit) or nil,
                helpful = AuraCount(unit, "HELPFUL"),
                harmful = AuraCount(unit, "HARMFUL"),
                buff1 = AuraSlot(prefix, "Buff"),
                debuff1 = AuraSlot(prefix, "Debuff"),
                harford = HarfordFrameState(unit),
            }
        end
        entries[#entries + 1] = row
        if #entries > MAX_ENTRIES then table.remove(entries, 1) end
    end

    local function CaptureAfterEvent(event, unit)
        Capture(event .. ":inmediato:" .. tostring(unit or ""))
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() if running then Capture(event .. ":post0:" .. tostring(unit or "")) end end)
            C_Timer.After(0.15, function() if running then Capture(event .. ":post150:" .. tostring(unit or "")) end end)
        end
    end

    local function HookExtraBarHover(unit)
        local frame = HarfordUnitFrames and HarfordUnitFrames.GetFrame and HarfordUnitFrames.GetFrame(unit)
        if not frame then return end
        for index = 3, frame.maxBarIndex or 0 do
            local slot = index
            local bar = frame.bars and frame.bars[index]
            local container = bar and bar.innerContainer
            if container and container.HookScript and not container._harfordAuraAuditHooked then
                container._harfordAuraAuditHooked = true
                container:HookScript("OnEnter", function()
                    if running then Capture("hover:entra:" .. unit .. ":barra" .. slot) end
                end)
                container:HookScript("OnLeave", function()
                    if running then Capture("hover:sale:" .. unit .. ":barra" .. slot) end
                end)
            end
        end
    end

    local function OnEvent(_, event, unit)
        if not running then return end
        if event == "UNIT_AURA" and unit ~= "player" and unit ~= "target" and unit ~= "focus" then return end
        CaptureAfterEvent(event, unit)
    end

    API.RegisterCommand("auraaudit", function(args)
        local action = tostring(args or ""):match("^%s*(%S+)")
        action = action and action:lower() or ""
        if action == "start" then
            entries = {}
            running = true
            if not watcher then
                watcher = CreateFrame("Frame")
                watcher:SetScript("OnEvent", OnEvent)
                watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
                watcher:RegisterEvent("PLAYER_FOCUS_CHANGED")
                watcher:RegisterEvent("UNIT_AURA")
            end
            Capture("inicio")
            HookExtraBarHover("player")
            HookExtraBarHover("target")
            HookExtraBarHover("focus")
            Print("auraaudit activo: reproduce el fallo y usa 'auraaudit stop'.")
            return
        end
        if action == "snapshot" then
            Capture("manual")
            Print("auraaudit: captura manual registrada.")
            return
        end
        if action == "stop" then
            running = false
            HarfordFrameProbe = HarfordFrameProbe or {}
            HarfordFrameProbe.auraAudit = entries
            Print("auraaudit guardado: " .. tostring(#entries) .. " capturas. Haz /reload para escribirlo.")
            return
        end
        if action == "status" then
            Print("auraaudit " .. (running and "activo" or "inactivo") .. "; capturas=" .. tostring(#entries))
            return
        end
        Print("uso: auraaudit start|snapshot|stop|status")
    end, "captura player/target/focus, auras, capas y hover: auraaudit start|stop")
end

-- Prueba de quests de mundo sin ArcSpell: define una quest de ejemplo sobre el template del target,
-- lee su estado por aura, y permite simular aceptar/entregar.
--   worldquest define        -> DefineWorldQuest sobre el template id del target
--   worldquest state         -> imprime el estado por aura del target
--   worldquest accept|turnin -> AcceptCurrent/TurnInCurrent sobre el target
HarfordDebug.RegisterCommand("worldquest", function(args)
    if not HarfordWorldQuests then Print("HarfordWorldQuests no disponible") return end
    local sub = tostring(args or ""):gsub("%s+", ""):lower()
    -- id de la quest REALMENTE registrada para el NPC target (del ArcSpell o del test); si no hay
    -- def registrada, cae al id del test. Asi los comandos operan sobre la misma quest que ves.
    local function questId()
        local d = HarfordWorldQuests.GetCurrentDef and HarfordWorldQuests.GetCurrentDef("target")
        if d and d.id then return d.id end
        local tid = HarfordWorldQuests.GetNpcTemplateId("target")
        return tid and ("world:test_" .. tid)
    end
    if sub == "define" then
        local tid = HarfordWorldQuests.GetNpcTemplateId("target")
        if not tid then Print("worldquest define: targetea un NPC (Creature)") return end
        local ok = HarfordWorldQuests.DefineWorldQuest({
            id = "world:test_" .. tid,
            npc = tid,
            title = "Prueba de mundo",
            rewards = { rep = { faction = "Guardia", amount = 50 }, money = { gold = 1, silver = 0, copper = 0 } },
            available = { text = "Una quest de prueba.", objectives = { { text = "Haz algo", required = 1 } } },
            incomplete = { text = "Sigue en ello..." },
            completed = { text = "Buen trabajo." },
        })
        Print(ok and ("quest de mundo definida sobre template " .. tid) or "no se pudo definir")
    elseif sub == "state" then
        local id = questId()
        Print("aura del NPC: " .. tostring(HarfordWorldQuests.GetNpcQuestState("target") or "nil (sin aura conocida)"))
        if id and HarfordQuests then
            Print(string.format("  %s | aceptada=%s completa=%s cobrada(Recompensa)=%s", id,
                tostring(HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(id)),
                tostring(HarfordQuests.IsComplete and HarfordQuests.IsComplete(id)),
                tostring(HarfordQuests.IsClaimed and HarfordQuests.IsClaimed(id))))
        else
            Print("  (no hay def registrada para este NPC; ejecuta el ArcSpell o 'worldquest define')")
        end
    elseif sub == "reset" then
        local id = questId()
        if id and HarfordQuests then
            if HarfordQuests.Abandon then HarfordQuests.Abandon(id) end
            if HarfordQuests.ResetClaim then HarfordQuests.ResetClaim(id) end
            Print("reseteada (abandonada + flag Recompensa limpiado): " .. id)
        else
            Print("reset: targetea el NPC")
        end
    elseif sub == "fresh" then
        -- Deja la mision lista para probar desde cero: limpia estado + pone el NPC en DISPONIBLE.
        local id = questId()
        if id and HarfordQuests then
            if HarfordQuests.Abandon then HarfordQuests.Abandon(id) end
            if HarfordQuests.ResetClaim then HarfordQuests.ResetClaim(id) end
        end
        if HarfordServerActions then
            if HarfordServerActions.RemoveNpcAura then
                HarfordServerActions.RemoveNpcAura(HarfordWorldQuests.AURA_INCOMPLETE)
                HarfordServerActions.RemoveNpcAura(HarfordWorldQuests.AURA_COMPLETE)
            end
            if HarfordServerActions.SetNpcAura then HarfordServerActions.SetNpcAura(HarfordWorldQuests.AURA_AVAILABLE) end
        end
        Print("NPC listo en DISPONIBLE (aura 155096, mision sin aceptar/cobrar): " .. tostring(id))
    elseif sub == "accept" then
        Print(HarfordWorldQuests.AcceptCurrent("target") and "aceptada/compartida" or "no se pudo (¿def registrada para este NPC?)")
    elseif sub == "complete" then
        local id = questId()
        Print(id and HarfordQuests and HarfordQuests.MarkComplete and HarfordQuests.MarkComplete(id)
            and ("completada: " .. id) or "no se pudo (¿aceptada? ¿def registrada? target NPC)")
    elseif sub == "turnin" then
        Print(HarfordWorldQuests.TurnInCurrent("target") and "entregada" or "no se pudo (¿completada? ¿ya cobrada? ¿def registrada?)")
    elseif sub:match("^reward") then
        local id = questId()
        Print(id and HarfordWorldQuests.DmSendReward(id) and "reparto DM enviado" or "no se pudo (¿DM? ¿target definido?)")
    else
        Print("uso: worldquest define|state|fresh|reset|accept|complete|turnin|reward (con un NPC en target)")
    end
end, "quests de mundo: define|state|fresh|reset|accept|complete|turnin|reward sobre el NPC target")

-- Vuelca la fuente (archivo/tamaño) de los elementos de la quest nativa y de las font objects, para
-- clavar la tipografia del panel de world quest. Ejecutar con una QUEST NATIVA abierta si es posible.
HarfordDebug.RegisterCommand("questfonts", function()
    local function dumpFO(name)
        local fo = _G[name]
        if not fo or not fo.GetFont then Print(name .. ": no existe") return end
        local file, size, flags = fo:GetFont()
        Print(string.format("%s: %s  %s  %s", name, tostring(file), tostring(size), tostring(flags)))
    end
    Print("--- font objects ---")
    for _, n in ipairs({ "QuestTitleFont", "QuestFont", "QuestFont_Large", "QuestFont_Super_Huge", "QuestFontNormalLarge" }) do dumpFO(n) end
    Print("--- elementos de quest nativa (si hay una abierta) ---")
    for _, n in ipairs({ "QuestInfoTitleHeader", "QuestInfoObjectivesHeader", "QuestInfoRewardsFrameHeader", "QuestInfoDescriptionText" }) do
        local f = _G[n]
        if f and f.GetFont then
            local file, size = f:GetFont()
            Print(string.format("%s: %s  %s", n, tostring(file), tostring(size)))
        else
            Print(n .. ": no encontrado")
        end
    end
end, "vuelca fuentes de quest nativa y font objects para clavar la tipografia")

-- Diagnostico de la estructura del GossipFrame (para ajustar el panel de quest de mundo).
-- Ejecutar con el gossip de un NPC ABIERTO.
HarfordDebug.RegisterCommand("gossipdump", function()
    local function fs(f)
        if not f then return "nil" end
        -- Sin el `if`, `f.GetSize and f:GetSize()` devolvia solo el ancho y la sonda
        -- imprimia siempre alto 0.
        local w, h
        if f.GetSize then w, h = f:GetSize() end
        return string.format("existe (%.0fx%.0f)", w or 0, h or 0)
    end
    Print("GossipFrame: " .. fs(GossipFrame))
    Print("GossipGreetingScrollChildFrame: " .. fs(_G.GossipGreetingScrollChildFrame))
    Print("GossipGreetingText: " .. (GossipGreetingText and ("existe txt='" .. tostring(GossipGreetingText:GetText()) .. "'") or "nil"))
    Print("GossipFrame.GreetingPanel: " .. fs(GossipFrame and GossipFrame.GreetingPanel))
    if GossipFrame and GossipFrame.GreetingPanel then
        Print("  .ScrollBox: " .. fs(GossipFrame.GreetingPanel.ScrollBox))
    end
    if C_GossipInfo and C_GossipInfo.GetNumOptions then
        Print("C_GossipInfo.GetNumOptions: " .. tostring(C_GossipInfo.GetNumOptions()))
    end
end, "vuelca la estructura del GossipFrame (con un gossip abierto) para ajustar el panel")

-- Ventana copiable reutilizable (Ctrl+A, Ctrl+C) para volcar texto largo que el usuario pega fuera.
local function ShowCopyWindow(title, text)
    local f = _G.HarfordDebugCopyFrame
    if not f then
        f = CreateFrame("Frame", "HarfordDebugCopyFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(600, 440)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
        local scroll = CreateFrame("ScrollFrame", "HarfordDebugCopyScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -30)
        scroll:SetPoint("BOTTOMRIGHT", -32, 12)
        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetWidth(540)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scroll:SetScrollChild(eb)
        f.editbox = eb
    end
    if f.TitleText then f.TitleText:SetText(tostring(title or "Harford")) end
    f.editbox:SetText(tostring(text or ""))
    f:Show()
    f.editbox:SetFocus()
    f.editbox:HighlightText()
end

-- Genera el Lua del ArcSpell de una mision de mundo (para pegar como on-greeting del gossip) a
-- partir de una entrada de HarfordQuestCatalog + el NPC en target (su template id). Evita
-- escribir la def a mano y reduce el drift. Uso: questarc <catalogId>  (con el NPC en target).
API.RegisterCommand("questarc", function(args)
    local id = tostring(args or ""):gsub("%s+", "")
    if id == "" then
        Print("Uso: questarc <catalogId>  (con el NPC en target). Ids: " ..
            table.concat((HarfordQuestCatalog and HarfordQuestCatalog.GetIds and HarfordQuestCatalog.GetIds()) or {}, ", "))
        return
    end
    local base = HarfordQuestCatalog and HarfordQuestCatalog.Get and HarfordQuestCatalog.Get(id)
    if not base then Print("No existe la entrada de catalogo: " .. id); return end
    local tid = HarfordWorldQuests and HarfordWorldQuests.GetNpcTemplateId and HarfordWorldQuests.GetNpcTemplateId("target")

    -- Serializa un valor Lua a literal (strings via %q, tablas array/map con orden estable de claves).
    local function LuaLit(v, indent)
        indent = indent or ""
        local t = type(v)
        if t == "string" then return string.format("%q", v) end
        if t == "number" or t == "boolean" then return tostring(v) end
        if t ~= "table" then return "nil" end
        local inner, parts = indent .. "  ", {}
        if #v > 0 then
            for _, item in ipairs(v) do parts[#parts + 1] = inner .. LuaLit(item, inner) .. "," end
        else
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, k in ipairs(keys) do
                local keyStr = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. LuaLit(k) .. "]")
                parts[#parts + 1] = inner .. keyStr .. " = " .. LuaLit(v[k], inner) .. ","
            end
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, "\n") .. "\n" .. indent .. "}"
    end

    local def = {
        id = id,
        npc = tid or 0,
        title = base.title,
        description = base.description,
        rewards = base.rewards,               -- nil si el catalogo usa `reward` string
        reward = (not base.rewards) and base.reward or nil,
        available = { text = base.description, objectives = base.objectives },
        incomplete = { text = "La mision sigue en curso." },
        completed = { text = "Has completado la mision. Reclama tu recompensa." },
    }
    local lua = "-- ArcSpell (on-greeting del gossip): define la mision de mundo Harford.\n"
        .. "if HarfordQuestAPI and HarfordQuestAPI.DefineWorldQuest then\n"
        .. "  HarfordQuestAPI.DefineWorldQuest(" .. LuaLit(def, "  ") .. ")\n"
        .. "end"
    if not tid then lua = "-- OJO: sin NPC en target; npc=0. Targetea el NPC y repite el comando.\n" .. lua end
    ShowCopyWindow("ArcSpell mision: " .. id, lua)
end, "genera el Lua del ArcSpell de una mision de mundo desde el catalogo (NPC en target)")

-- Genera el Lua del ArcSpell de una mision de mundo desde un CONTRATO del tablon, con sus 4 textos
-- (Descripcion / NPC al dar / en proceso / al entregar), recompensas, objetivos y NPC ya puestos en
-- el editor. Es compatible con clientes antiguos: la def va horneada en el ArcSpell (no depende de
-- sync) y usa el formato nativo de DefineWorldQuest. Uso: contractarc <contractId>.
API.RegisterCommand("contractarc", function(args)
    local id = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local db = HarfordContracts and HarfordContracts.GetDB and HarfordContracts.GetDB()
    local contracts = (db and db.contracts) or {}
    if id == "" then
        local ids = {}
        for _, c in ipairs(contracts) do
            if c.worldNpc then ids[#ids + 1] = tostring(c.id) .. " (" .. tostring(c.title or "?") .. ")" end
        end
        Print("Uso: contractarc <contractId>. Contratos con NPC: " ..
            (#ids > 0 and table.concat(ids, ", ") or "ninguno (pon 'Usar target' en un contrato)"))
        return
    end
    local contract
    for _, c in ipairs(contracts) do if tostring(c.id) == id then contract = c; break end end
    if not contract then Print("No existe contrato con id: " .. id); return end
    if not (HarfordContracts and HarfordContracts.BuildWorldQuestDef) then
        Print("BuildWorldQuestDef no disponible."); return
    end
    local def = HarfordContracts.BuildWorldQuestDef(contract)
    if not def then Print("El contrato no tiene NPC (worldNpc). Ponlo con 'Usar target' en el editor."); return end

    -- Serializa un valor Lua a literal (strings via %q, tablas array/map con orden estable de claves).
    local function LuaLit(v, indent)
        indent = indent or ""
        local t = type(v)
        if t == "string" then return string.format("%q", v) end
        if t == "number" or t == "boolean" then return tostring(v) end
        if t ~= "table" then return "nil" end
        local inner, parts = indent .. "  ", {}
        if #v > 0 then
            for _, item in ipairs(v) do parts[#parts + 1] = inner .. LuaLit(item, inner) .. "," end
        else
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, k in ipairs(keys) do
                local keyStr = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k or ("[" .. LuaLit(k) .. "]")
                parts[#parts + 1] = inner .. keyStr .. " = " .. LuaLit(v[k], inner) .. ","
            end
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, "\n") .. "\n" .. indent .. "}"
    end

    local lua = "-- ArcSpell (on-greeting del gossip): mision de mundo Harford desde contrato " .. id .. ".\n"
        .. "if HarfordQuestAPI and HarfordQuestAPI.DefineWorldQuest then\n"
        .. "  HarfordQuestAPI.DefineWorldQuest(" .. LuaLit(def, "  ") .. ")\n"
        .. "end"
    ShowCopyWindow("ArcSpell contrato: " .. id, lua)
end, "genera el Lua del ArcSpell de una mision de mundo desde un contrato (con los 4 textos)")

-- Vuelca el About TRP3 crudo + la ficha que Harford parsea, en una ventana copiable, para revisar
-- que campos de la ficha se importan y cuales faltan. Uso: dumpsheet (jugador) | dumpsheet target.
API.RegisterCommand("dumpsheet", function(args)
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile) then Print("HarfordTRP3 no disponible") return end
    local unit = tostring(args or ""):lower():find("target") and "target" or "player"
    local profile = HarfordTRP3.GetPlayerProfile(unit)
    if not profile then Print("Sin perfil TRP3 para " .. unit) return end

    local aboutText = HarfordTRP3.GetPlayerAboutText and select(1, HarfordTRP3.GetPlayerAboutText(profile)) or nil
    local sheet = HarfordTRP3.ParsePlayerSheet and HarfordTRP3.ParsePlayerSheet(profile) or nil

    local function serialize(value, indent, out)
        indent = indent or ""
        if type(value) ~= "table" then out[#out + 1] = indent .. tostring(value); return end
        for k, v in pairs(value) do
            if type(v) == "table" then
                out[#out + 1] = indent .. tostring(k) .. ":"
                serialize(v, indent .. "  ", out)
            else
                out[#out + 1] = indent .. tostring(k) .. " = " .. tostring(v)
            end
        end
    end
    local parsed = {}
    serialize(sheet or "(no parseado)", "", parsed)

    local imp = {}
    if HarfordDnDProgression and HarfordDnDProgression.GetImportedProficiencies then
        serialize(HarfordDnDProgression.GetImportedProficiencies() or "(sin datos)", "", imp)
    end

    local full = "===== ABOUT CRUDO (" .. unit .. ") =====\n"
        .. tostring(aboutText or "(sin About)")
        .. "\n\n===== PARSEADO POR HARFORD =====\n" .. table.concat(parsed, "\n")
        .. "\n\n===== COMPETENCIAS IMPORTADAS (tras /harford cargarficha) =====\n" .. table.concat(imp, "\n")

    ShowCopyWindow("Harford - Volcado ficha (Ctrl+A, Ctrl+C)", full)
end, "vuelca About TRP3 + ficha parseada (copiable): dumpsheet [target]")

API.RegisterCommand("contador", function(args)
    local C = _G.HarfordDnDConditions
    if not (C and C.SetVar) then Print("HarfordDnDConditions no cargado"); return end
    local id, valor = tostring(args or ""):match("^%s*(%S*)%s*(%-?%d*)")
    if id == "" then
        Print("Uso: contador <condicion> [numero].  Sin numero, lo quita.")
        Print("Pone a mano el contador que se pinta sobre el icono del aura. En Epsilon no se pueden")
        Print("aplicar auras CON acumulaciones, asi que el numero lo lleva Harford.")
        Print("Solo se ve si la condicion declara |cffffd100auraId|r y la tienes puesta.")
        local conAura = {}
        for cid, def in pairs(C.DEFS or {}) do
            if def.auraId then conAura[#conAura + 1] = cid end
        end
        table.sort(conAura)
        Print("Con aura: |cff808080" .. table.concat(conAura, "  ") .. "|r")
        return
    end
    local def = C.GetDefinition and C.GetDefinition(id)
    if not def then Print("Condicion desconocida: |cffffd100" .. id .. "|r"); return end
    if not def.auraId then
        Print("|cffff5555" .. id .. " no tiene aura|r: el contador existiria pero no habria icono "
            .. "donde pintarlo.")
    end
    local n = tonumber(valor)
    local ok = C.SetVar("player", id, "=", "contador", n or 0)
    if not ok then
        Print("No tienes |cffffd100" .. id .. "|r activa. Aplicala primero: "
            .. "|cffffd100/harford debug run conditiontest apply " .. id .. "|r")
        return
    end
    Print(n and ("Contador de |cffffd100" .. id .. "|r puesto a |cffffd100" .. n .. "|r"
        .. (n <= 1 and "  |cff808080(1 o menos no se pinta)|r" or ""))
        or ("Contador de |cffffd100" .. id .. "|r retirado"))
    if HarfordUnitFrames and HarfordUnitFrames.Refresh then HarfordUnitFrames.Refresh() end
end, "pone a mano el contador que se pinta sobre el icono de un aura: contador <condicion> [numero]")

API.RegisterCommand("aboutprevio", function(args)
    local T = _G.HarfordTRP3
    if not (T and T.GetPreviousAbout) then Print("HarfordTRP3 no cargado"); return end
    local prev, nombre = T.GetPreviousAbout()
    if not prev then
        Print("No hay copia del About de |cffffcc00" .. tostring(nombre) .. "|r.")
        Print("Se guarda cada vez que Harford escribe en el About; si nunca lo ha escrito, no hay nada.")
        return
    end

    local function Frames(about)
        local n, titulos = 0, {}
        for _, f in ipairs((type(about.T2) == "table" and about.T2) or {}) do
            n = n + 1
            -- Primera linea del frame: su cabecera. El corte se compone con string.char para no
            -- depender de escapar el salto de linea dentro del patron.
            local primera = tostring(f.TX or ""):match("^[^" .. string.char(10) .. string.char(13) .. "]*") or ""
            primera = (T.StripInlineMarkup and T.StripInlineMarkup(primera)) or primera
            if #titulos < 12 then titulos[#titulos + 1] = primera:sub(1, 34) end
        end
        return n, titulos
    end

    if tostring(args or ""):lower():gsub("%s+", "") ~= "restaurar" then
        local cuando = prev.cuando and prev.cuando > 0 and date("%d/%m/%Y %H:%M", prev.cuando) or "?"
        local nAnt, tAnt = Frames(prev.datos)
        Print("Copia del About de |cffffcc00" .. tostring(nombre) .. "|r, guardada el |cffffd100"
            .. cuando .. "|r: |cffffd100" .. nAnt .. "|r frame(s)")
        for _, s in ipairs(tAnt) do Print("   |cff808080" .. s .. "|r") end
        local actual = T.GetPlayerProfile and T.GetPlayerProfile("player")
        local about = actual and type(actual.player) == "table" and actual.player.about
        if type(about) == "table" then
            local nHoy = Frames(about)
            Print("AHORA: |cffffd100" .. nHoy .. "|r frame(s)"
                .. (nHoy < nAnt and "  |cffff5555(hay menos que en la copia)|r" or ""))
        end
        Print("Para volver a ella: |cff00ff00/harford debug run aboutprevio restaurar|r")
        return
    end

    local ok, err = T.RestorePreviousAbout()
    Print(ok and ("About de |cffffcc00" .. tostring(err or nombre) .. "|r restaurado tal cual estaba.")
        or ("|cffff5555" .. tostring(err) .. "|r"))
end, "copia del About de TRP3 anterior a que Harford lo escribiera (aboutprevio restaurar)")

API.RegisterCommand("fichaprevia", function(args)
    local P = _G.HarfordDnDProgression
    if not (P and P.GetPreviousProgression) then Print("HarfordDnDProgression no cargado"); return end
    local sub = tostring(args or ""):lower():gsub("%s+", "")
    local prev, name = P.GetPreviousProgression()

    if not prev then
        Print("No hay copia anterior de |cffffcc00" .. tostring(name) .. "|r.")
        Print("Solo se guarda cuando la ficha se MIGRA a un esquema nuevo; si ya estaba al dia, no habia nada que copiar.")
        return
    end

    local cuando = prev.cuando and prev.cuando > 0 and date("%d/%m/%Y %H:%M", prev.cuando) or "?"
    if sub ~= "restaurar" then
        Print("Copia de |cffffcc00" .. tostring(name) .. "|r anterior a la migracion:")
        Print(string.format("   esquema |cffffd100%s|r, guardada el |cffffd100%s|r",
            tostring(prev.schema), cuando))
        local d = prev.datos
        local function cuenta(tabla)
            local n = 0
            for _ in pairs(type(tabla) == "table" and tabla or {}) do n = n + 1 end
            return n
        end
        Print(string.format("   clases %d | elecciones %d | rasgos con estado %d | usos %d | dotes %d",
            cuenta(d.classLevels), cuenta(d.choices), cuenta(d.featureStates),
            cuenta(d.featureUses), cuenta(d.feats)))
        local actual = P.Get()
        Print(string.format("   AHORA:  clases %d | elecciones %d | rasgos con estado %d | usos %d | dotes %d",
            cuenta(actual.classLevels), cuenta(actual.choices), cuenta(actual.featureStates),
            cuenta(actual.featureUses), cuenta(actual.feats)))
        Print("Para volver a esa copia: |cff00ff00/harford debug run fichaprevia restaurar|r")
        return
    end

    local ok, err = P.RestorePreviousProgression()
    if not ok then Print("|cffff5555" .. tostring(err) .. "|r"); return end
    Print("Ficha de |cffffcc00" .. tostring(name) .. "|r restaurada al estado anterior a la migracion.")
    Print("|cffff5555Ojo:|r se volvera a migrar al siguiente acceso. Sirve para MIRAR que habia y "
        .. "recuperar algo concreto, no para quedarse en el esquema viejo. Haz |cff00ff00/reload|r.")
end, "copia de la ficha anterior a la migracion (fichaprevia restaurar para volver a ella)")

API.RegisterCommand("wipesheet", function(args)
    args = tostring(args or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local name = (UnitName and UnitName("player")) or "default"
    if args ~= "confirm" then
        Print("Esto BORRA la ficha Harford de |cffffcc00" .. name .. "|r (progresion, caracteristicas, "
            .. "equipo, dados de golpe, usos y recursos) para dejarla como PJ nuevo. El About de TRP3 NO se toca.")
        Print("Confirma con |cff00ff00/harford debug run wipesheet confirm|r. Recomendado |cff00ff00/reload|r despues.")
        return
    end

    local removed = false
    if type(HarfordDnDPersistStore) == "table" and type(HarfordDnDPersistStore.profiles) == "table" then
        if HarfordDnDPersistStore.profiles[name] ~= nil then
            HarfordDnDPersistStore.profiles[name] = nil
            removed = true
        end
    end
    -- Limpiar el runtime (recursos/estado en vivo) para que no queden barras fantasma antes del reload.
    if HarfordDnDStore and HarfordDnDStore.state and type(HarfordDnDStore.state.runtime) == "table" and wipe then
        wipe(HarfordDnDStore.state.runtime)
    end

    if removed then
        Print("Ficha de |cffffcc00" .. name .. "|r borrada. Haz |cff00ff00/reload|r para arrancar como PJ nuevo.")
    else
        Print("No habia ficha persistida para |cffffcc00" .. name .. "|r (runtime limpiado igualmente). Haz /reload.")
    end
end, "borra la ficha Harford del PJ actual y la deja como nueva. Uso: wipesheet confirm")

API.RegisterCommand("abouttrp3", function()
    if not (HarfordCharacterCreation and HarfordCharacterCreation.RewriteAbout) then
        Print("HarfordCharacterCreation.RewriteAbout no disponible") return
    end
    local ok, err = HarfordCharacterCreation.RewriteAbout()
    if ok then
        Print("About de TRP3 regenerado desde la ficha actual (incluye secciones de magia si tienes conjuros).")
    else
        Print("|cffff5555No se pudo regenerar el About: " .. tostring(err) .. "|r")
    end
end, "regenera el About TRP3 desde la ficha actual (progresion + conjuros del compendio)")

API.RegisterCommand("preparar", function()
    if _G.HarfordOpenPrepareSpellsMenu then
        _G.HarfordOpenPrepareSpellsMenu(false)
    else
        Print("Menu de preparar conjuros no disponible (HarfordCharacterAdvancement no cargado)")
    end
end, "abre el menu de reelegir conjuros preparados (como tras un descanso largo)")

API.RegisterCommand("profitems", function()
    -- Lista claves sin ID operativo. Con Wowhead como fuente temporal, solo deben
    -- aparecer objetos custom/dinamicos o resultados sin equivalente original.
    local reg = HarfordProfessionsItems and HarfordProfessionsItems.REGISTRY
    if not reg then Print("HarfordProfessionsItems no disponible") return end
    local pending, total = {}, 0
    for key, entry in pairs(reg) do
        total = total + 1
        if type(entry) == "table" and not (HarfordProfessionsItems.GetId and HarfordProfessionsItems.GetId(key)) then
            pending[#pending + 1] = { key = key, name = tostring(entry.name or key) }
        end
    end
    table.sort(pending, function(a, b) return a.key < b.key end)
    for _, e in ipairs(pending) do
        Print(string.format("|cffffd100%s|r  %s", e.key, e.name))
    end
    Print(string.format("Pendientes de ID operativo: |cffffcc00%d|r de %d claves.",
        #pending, total))
end, "lista las claves sin ID Wowhead ni fallback custom")

API.RegisterCommand("merchantdump", function(args)
    -- Vuelca los items del mercader abierto. Soporta tanto el MerchantFrame nativo como
    -- Epsilon_Merchant, cuyo inventario vive en EPSILON_VENDOR_DATA y no usa la API nativa.
    -- Pensado para cosechar itemIds de Epsilon y rellenar el registro de profesiones
    -- (HarfordProfessionsItems, claves con id=nil).
    --   merchantdump         -> lista id + nombre + precio de todo el inventario del vendedor
    --   merchantdump match   -> solo los que casan por NOMBRE con una clave pendiente del
    --                           registro, en formato listo para hornear (clave -> id)
    --   merchantdump apply   -> como match, y ademas aplica el id EN CALIENTE con
    --                           HarfordProfessionsItems.Set (solo esta sesion: el registro es
    --                           codigo; para que persista hay que hornearlo en el .lua)
    -- Todo lo listado se acumula ademas en HarfordDebugSettings.merchantDump (SavedVariable),
    -- deduplicado por itemId: tras /reload se puede leer del fichero SV sin copiar del chat.
    args = tostring(args or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local epsilonFrame = _G.Epsilon_MerchantFrame
    local epsilonData = _G.EPSILON_VENDOR_DATA
    local epsilonItems = epsilonFrame and epsilonFrame.merchantID and epsilonData
        and epsilonData[epsilonFrame.merchantID]
    local isEpsilonMerchant = type(epsilonItems) == "table"
    local total = isEpsilonMerchant and #epsilonItems or ((GetMerchantNumItems and GetMerchantNumItems()) or 0)
    if total <= 0 then
        Print("Abre primero la ventana de un mercader (no hay items de vendedor visibles).")
        return
    end
    HarfordDebugSettings = type(HarfordDebugSettings) == "table" and HarfordDebugSettings or {}
    HarfordDebugSettings.merchantDump = type(HarfordDebugSettings.merchantDump) == "table"
        and HarfordDebugSettings.merchantDump or {}
    local dump = HarfordDebugSettings.merchantDump

    local function Norm(text)
        text = tostring(text or "")
        if HarfordClassColors and HarfordClassColors.StripAccents then
            text = HarfordClassColors.StripAccents(text)
        end
        text = text:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        return text
    end

    -- Claves del registro de profesiones aun sin id, indexadas por nombre normalizado.
    local pendingByName = {}
    local registry = HarfordProfessionsItems and HarfordProfessionsItems.REGISTRY
    for key, entry in pairs(registry or {}) do
        if type(entry) == "table" and not entry.id then
            pendingByName[Norm(entry.name or key)] = key
        end
    end

    local vendorName = (UnitExists and UnitExists("npc") and UnitName and UnitName("npc"))
        or (UnitExists and UnitExists("target") and UnitName and UnitName("target")) or "?"
    local listed, matched = 0, 0
    for index = 1, total do
        local itemId, name, price
        if isEpsilonMerchant then
            -- Epsilon_Merchant almacena { itemId, precio, pila, moneda, cantidad }.
            itemId = tonumber(epsilonItems[index] and epsilonItems[index][1])
            price = tonumber(epsilonItems[index] and epsilonItems[index][2])
            if itemId and GetItemInfo then
                name = GetItemInfo(itemId)
            end
        else
            local link = GetMerchantItemLink and GetMerchantItemLink(index)
            itemId = link and tonumber(link:match("item:(%d+)"))
            name = link and link:match("%[(.-)%]")
            local infoName
            infoName, _, price = GetMerchantItemInfo and GetMerchantItemInfo(index)
            name = name or infoName
        end
        name = name or ("item " .. tostring(itemId or index))
        if itemId then
            dump[tostring(itemId)] = name
            listed = listed + 1
            local key = pendingByName[Norm(name)]
            if args == "match" or args == "apply" then
                if key then
                    matched = matched + 1
                    Print(string.format("|cff38d26a%s|r = %d  -- %s", key, itemId, tostring(name)))
                    if args == "apply" and HarfordProfessionsItems and HarfordProfessionsItems.Set then
                        HarfordProfessionsItems.Set(key, itemId)
                    end
                end
            else
                local coins = price and price > 0
                    and (GetCoinTextureString and GetCoinTextureString(price) or tostring(price) .. "c") or "-"
                Print(string.format("%2d) |cffffd100%d|r  %s  (%s)", index, itemId, tostring(name), coins))
            end
        end
    end
    Print(string.format("Mercader |cffffcc00%s|r: %d items listados de %d.", tostring(vendorName), listed, total))
    if args == "match" or args == "apply" then
        Print(string.format("Coinciden con claves pendientes del registro: %d.%s", matched,
            args == "apply" and (matched > 0 and " Aplicados EN CALIENTE (esta sesion); hornear en el .lua para persistir." or "") or ""))
    end
    Print("Volcado acumulado en HarfordDebugSettings.merchantDump (persiste al hacer /reload).")
end, "vuelca los items del mercader abierto (match/apply casan con el registro de profesiones). Uso: merchantdump [match|apply]")

SetEnabled(type(HarfordDebugSettings) == "table" and HarfordDebugSettings.enabled == true, true)

-- Que texturas de la ventana de recetas NO existen en este cliente. La ventana ya las oculta
-- (nunca pinta cuadrados verdes), pero aqui se ven por nombre para poder sustituirlas.
API.RegisterCommand("crafttex", function()
    local ui = _G.HarfordProfessionsCraftUI
    if not ui then Print("HarfordProfessionsCraftUI no cargado"); return end
    if not _G.HarfordProfessionsCraftFrame then
        Print("Abriendo la ventana para poder comprobar sus texturas...")
        if ui.Open and HarfordProfessions then
            for _, def in ipairs(HarfordProfessions.GetProfessions() or {}) do
                if HarfordProfessions.KnowsProfession(def.id) then ui.Open(def.id) break end
            end
        end
    end
    local issues = ui._textureIssues or {}
    Print(string.format("Texturas que faltan en este cliente: %d", #issues))
    for _, line in ipairs(issues) do Print("  " .. line) end
    if #issues == 0 then Print("Todas las texturas de la ventana existen.") end
end, "texturas de la ventana de recetas que no existen en este cliente")

-- Que version del codigo esta corriendo el cliente de verdad. Sirve para distinguir "el cambio
-- no funciona" de "el cliente sigue con el fichero viejo" sin depender de pantallazos.
API.RegisterCommand("craftver", function()
    local ui = _G.HarfordProfessionsCraftUI
    Print("Ventana de recetas build: " .. tostring(ui and ui.BUILD or "NO CARGADA"))
    Print("Panel de personaje: " .. (_G.HarfordCharacterPanel and "cargado" or "NO CARGADO"))
    local issues = ui and ui._textureIssues or {}
    Print("Texturas no cargadas registradas: " .. #issues)
    for _, line in ipairs(issues) do Print("   " .. line) end
    local f = _G.HarfordProfessionsCraftFrame
    -- Si la construccion murio a media, la ventana existe pero sin esta marca: es la senal de
    -- que un error corto el montaje y por eso "todo sigue igual".
    Print("Construccion completa: " .. tostring(f and f._buildComplete == true))
end, "build de la ventana de recetas que esta corriendo el cliente")

-- Resuelve RUTAS de textura a su fileID en ESTE cliente y las contrasta con el fileID que usa
-- el frame nativo. Sirve para dejar de adivinar: si una ruta devuelve el mismo numero que la
-- sonda leyo del nativo, esa es la ruta correcta y se puede usar con garantias.
API.RegisterCommand("texpath", function(args)
    local extra = tostring(args or ""):match("^%s*(.-)%s*$")
    local wanted = {
        { 136570, "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" },
        { 136571, "Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder" },
        { 136569, "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar" },
        { 130849, "Interface\\Buttons\\UI-ScrollBar-Knob" },
        { 130783, "Interface\\Buttons\\UI-Listbox-Highlight2" },
        { 132086, "Interface\\HelpFrame\\HelpFrameTab-Active" },
        { 132085, "Interface\\HelpFrame\\HelpFrameTab-Inactive" },
        { 136580, "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight" },
        { 136580, "Interface\\Buttons\\UI-Panel-Button-Highlight" },
        { 136796, "Interface\\QuestFrame\\UI-QuestItemNameFrame" },
        { 374155, "Interface\\FrameGeneral\\UI-Background-Marble" },
        { 374154, "Interface\\FrameGeneral\\UI-Background-Rock" },
    }
    if extra ~= "" then wanted[#wanted + 1] = { 0, extra } end
    if type(GetFileIDFromPath) ~= "function" then
        Print("GetFileIDFromPath no existe en este cliente"); return
    end
    Print("ruta -> fileID en ESTE cliente (esperado = el que usa el frame nativo):")
    for _, entry in ipairs(wanted) do
        local expected, path = entry[1], entry[2]
        local id = GetFileIDFromPath(path)
        local mark = "?"
        if not id then mark = "|cffff5555NO EXISTE|r"
        elseif expected == 0 then mark = "ok"
        elseif id == expected then mark = "|cff44dd44COINCIDE|r"
        else mark = "|cffffcc00distinto (esperado " .. expected .. ")|r" end
        Print(string.format("  %-58s -> %-10s %s", path, tostring(id), mark))
    end
end, "comprueba a que fileID resuelve cada ruta de textura en este cliente")

-- Recetas dinamicas: probar el flujo que usaria un ArcSpell sin depender del servidor.
--   customrecipe list                       -> las que tiene este personaje
--   customrecipe demo                       -> ensena una de prueba en Herreria
--   customrecipe forget <id>                -> la retira
API.RegisterCommand("customrecipe", function(args)
    local action, rest = tostring(args or ""):match("^%s*(%S*)%s*(.-)%s*$")
    action = action:lower()
    if not HarfordProfessions then Print("HarfordProfessions no cargado"); return end

    if action == "forget" then
        Print(HarfordProfessions.ForgetCustomRecipe(rest) and ("Retirada: " .. rest)
            or ("No existe como dinamica: " .. rest))
        return
    end
    if action == "demo" then
        local ok, err = HarfordProfessions.TeachCustomRecipe({
            id = "demo_lingote_runico",
            profession = "herreria",
            name = "Lingote runico de prueba",
            skillReq = 1, dc = 10,
            icon = "INV_Ingot_03",
            materials = { { id = 14074575, qty = 1, name = "Mena de cobre" } },
            output = { id = 14074638, qty = 1, name = "Barra de cobre" },
        })
        Print(ok and "Receta de prueba ensenada (Herreria)." or ("Fallo: " .. tostring(err)))
        return
    end

    local list = HarfordProfessions.GetCustomRecipes()
    Print("Recetas dinamicas de este personaje: " .. #list)
    for _, r in ipairs(list) do
        Print(string.format("  %-28s %-14s skill %-3d %s", r.id, r.profession, r.skillReq or 1,
            r.learned and "|cff44dd44aprendida|r" or "|cffffcc00sin aprender|r"))
    end
end, "recetas dinamicas: list | demo | forget <id>")

-- Sistemas nuevos de reglas: cansancio, concentracion, puntos de heroe, maniobras y carga.
-- Sirve para probarlos sin depender de que la UI los exponga todavia.
-- Auditoria del compendio: cuenta lo que el motor SI puede resolver y lo que se queda en
-- anuncio, para ver de un vistazo que falta por mecanizar sin abrir los datos.
-- ¿Existen en ESTE cliente las texturas del libro de profesiones nativo? La pestana Profesiones
-- sustituye las dos paginas enteras por Professions-Book-Left/Right (SpellBookFrame.lua,
-- bgFileL/bgFileR); si el build de Epsilon no las trae, hay que caer a los fileID.
-- Sintonizacion y carga: estado y pruebas. `peso <itemId> <libras>` declara el peso de un
-- objeto, que el cliente de WoW NO expone y por eso hay que darselo a mano.
-- Definiciones de faccion en la fase.
API.RegisterCommand("phaserep", function(args)
    local P = _G.HarfordReputationPhase
    if not P then Print("HarfordReputationPhase no cargado"); return end
    local cmd, a = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")

    if cmd == "publicar" then
        P.Publish(false, function(ok, n, extra)
            if not ok then Print("|cffff5555" .. tostring(extra) .. "|r"); return end
            Print(string.format("Publicadas |cffffd100%s|r facciones%s%s", tostring(n),
                (extra and extra.adoptadas or 0) > 0 and (", " .. extra.adoptadas .. " de otros DM") or "",
                (extra and extra.retiradas or 0) > 0 and (", " .. extra.retiradas .. " retiradas") or ""))
        end)
        return
    end

    if cmd == "cargar" then
        P.EnsureCatalog(true, function(ok, n, r)
            if not ok then Print("|cffff5555" .. tostring(n) .. "|r"); return end
            Print(string.format("Aplicadas |cffffd100%s|r facciones%s", tostring(n),
                (tonumber(r) or 0) > 0 and (", " .. r .. " retiradas") or ""))
        end)
        return
    end

    if cmd == "ver" then
        P.Load(function(payload, err)
            if not payload then Print("Nada en la fase" .. (err and (" (" .. err .. ")") or "")); return end
            local n = 0
            for id, f in pairs(payload.factions or {}) do
                n = n + 1
                Print(string.format("   |cffffd100%s|r  %s", tostring(id), tostring(f.name)))
            end
            local m = payload.meta or {}
            Print(string.format("Facciones en la fase: |cffffd100%d|r  |cff808080(por %s)|r",
                n, tostring(m.by or "?")))
            if payload.players then Print("   |cffff5555FUGA: viajaron reputaciones de jugador|r") end
        end)
        return
    end

    if cmd == "purgar" then
        if a ~= "confirmar" then
            Print("|cffff5555Borra el catalogo de facciones de la fase.|r")
            Print("Escribe: |cffffd100phaserep purgar confirmar|r")
            return
        end
        P.Purge(function(ok, n, err)
            Print(ok and ("Purgadas |cffffd100" .. tostring(n) .. "|r claves.")
                or ("|cffff5555" .. tostring(err) .. "|r"))
        end)
        return
    end

    local mk, tk = P.GetKeys()
    local store = _G.HarfordReputation and _G.HarfordReputation.EnsureStore
        and _G.HarfordReputation.EnsureStore() or {}
    local n = 0
    for _ in pairs(store.factions or {}) do n = n + 1 end
    Print("|cffffd100Facciones en la fase|r")
    Print("  Disponible: " .. (P.IsAvailable() and "|cff55ff55si|r" or "|cffff5555no|r")
        .. "   Puedes escribir: " .. (P.CanWrite() and "|cff55ff55si|r" or "|cff808080no|r"))
    Print("  Claves: |cff808080" .. tk .. "|r, |cff808080" .. mk .. "|r")
    Print("  Catalogo local: |cffffd100" .. n .. "|r facciones")
    Print("  |cffffd100phaserep publicar|r  sube el catalogo (fusiona, no pisa)")
    Print("  |cffffd100phaserep cargar|r    trae el de la fase")
    Print("  |cffffd100phaserep ver|r       vuelca lo que hay escrito")
    Print("  |cffffd100phaserep purgar confirmar|r")
end, "Definiciones de faccion guardadas en la fase")

-- Tablas de loot en la fase.
API.RegisterCommand("phaseloot", function(args)
    local P = _G.HarfordLootPhase
    if not P then Print("HarfordLootPhase no cargado"); return end
    local cmd, a = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")

    if cmd == "publicar" then
        P.PublishAll(function(ok, escritas, fallos)
            if not ok and not escritas then Print("|cffff5555" .. tostring(fallos) .. "|r"); return end
            Print(string.format("Subidas |cffffd100%s|r tablas%s", tostring(escritas),
                (tonumber(fallos) or 0) > 0 and (" (" .. fallos .. " con error)") or ""))
        end)
        return
    end

    if cmd == "criatura" then
        local id = tonumber(a)
        if not id then Print("uso: phaseloot criatura <creatureId>"); return end
        P.LoadCreatureLoot(id, function(tabla, err)
            if not tabla then
                Print("Sin tabla para " .. id .. (err and (" (" .. tostring(err) .. ")") or ""))
                return
            end
            Print(string.format("Criatura |cffffd100%d|r: %d entradas", id, #tabla))
            for _, e in ipairs(tabla) do
                Print(string.format("   item |cffffd100%s|r  %s%%  x%s-%s",
                    tostring(e[1]), tostring(e[2]), tostring(e[3]), tostring(e[4])))
            end
        end)
        return
    end

    if cmd == "global" then
        P.LoadGlobalLoot(function(tabla, err)
            if not tabla then Print("Sin tabla global" .. (err and (" (" .. err .. ")") or "")); return end
            Print("Tabla global: |cffffd100" .. #tabla .. "|r entradas")
            for _, e in ipairs(tabla) do
                Print(string.format("   item |cffffd100%s|r  %s%%", tostring(e[1]), tostring(e[2])))
            end
        end)
        return
    end

    if cmd == "manifiesto" then
        P.LoadManifest(function(claves, err)
            claves = type(claves) == "table" and claves or {}
            local espejo = P.GetLocalManifest and P.GetLocalManifest() or {}
            Print(string.format("Claves de loot: |cffffd100%d|r  (espejo local: |cffffd100%d|r)",
                #claves, #espejo))
            if err then Print("   |cffff9900la fase no contesto: " .. tostring(err) .. "|r") end
            for _, k in ipairs(claves) do Print("   |cff808080" .. tostring(k) .. "|r") end
        end)
        return
    end

    if cmd == "historial" then
        -- Que cadaveres tienen saqueo registrado en la fase.
        P.LoadManifest(function(claves, err)
            claves = type(claves) == "table" and claves or {}
            local pref = P.GetTakenPrefix and P.GetTakenPrefix() or "HARFORD_LOOT_T_"
            local n = 0
            for _, k in ipairs(claves) do
                if tostring(k):sub(1, #pref) == pref then
                    n = n + 1
                    Print("   |cff808080" .. tostring(k):sub(#pref + 1) .. "|r")
                end
            end
            Print("Cadaveres con saqueo registrado: |cffffd100" .. n .. "|r"
                .. (err and (" |cffff9900(" .. tostring(err) .. ")|r") or ""))
        end)
        return
    end

    if cmd == "limpiar" then
        if a ~= "confirmar" then
            Print("|cffff5555Esto reinicia el saqueo: todo vuelve a estar por coger.|r")
            Print("Las TABLAS de loot no se tocan, solo el historial.")
            Print("Escribe: |cffffd100phaseloot limpiar confirmar|r")
            return
        end
        P.ClearAllTaken(function(ok, borradas, err)
            if not ok then Print("|cffff5555" .. tostring(err) .. "|r"); return end
            Print("Historial de saqueo borrado: |cffffd100" .. #(borradas or {})
                .. "|r cadaveres. Todo vuelve a estar por coger.")
        end)
        return
    end

    if cmd == "olvidar" then
        -- Un solo cadaver: el del target, o el guid que se le pase.
        local guid = (a ~= "" and a) or (UnitGUID and UnitGUID("target"))
        if not guid then Print("Apunta a un cadaver o pasa su guid."); return end
        P.ClearTaken(guid, function(ok, _, err)
            Print(ok and "Ese cadaver vuelve a estar entero."
                or ("|cffff5555" .. tostring(err) .. "|r"))
        end)
        return
    end

    if cmd == "reconstruir" then
        P.RebuildManifest(function(ok, n, err)
            Print(ok and ("Manifiesto rehecho: |cffffd100" .. tostring(n) .. "|r claves")
                or ("|cffff5555" .. tostring(err) .. "|r"))
        end)
        return
    end

    if cmd == "purgar" then
        if a ~= "confirmar" then
            Print("|cffff5555Esto borra TODAS las tablas de loot de la fase.|r")
            Print("Escribe: |cffffd100phaseloot purgar confirmar|r")
            return
        end
        P.PurgeAll(function(ok, borradas, err)
            if not ok then Print("|cffff5555" .. tostring(err) .. "|r"); return end
            Print("Purgadas |cffffd100" .. #(borradas or {}) .. "|r claves de loot.")
        end)
        return
    end

    local mk, gk, pk = P.GetKeys()
    Print("|cffffd100Tablas de loot en la fase|r")
    Print("  Disponible: " .. (P.IsAvailable() and "|cff55ff55si|r" or "|cffff5555no|r")
        .. "   Puedes escribir: " .. (P.CanWrite() and "|cff55ff55si|r" or "|cff808080no|r"))
    Print("  Claves: |cff808080" .. mk .. "|r, |cff808080" .. gk .. "|r, |cff808080" .. pk .. "<id>|r")
    local n = 0
    for _ in pairs(_G.HarfordLootLootRegistry or {}) do n = n + 1 end
    Print(string.format("  Registro local: |cffffd100%d|r criaturas, global |cffffd100%d|r entradas",
        n, #(_G.HarfordLootGlobalLootRegistry or {})))
    Print("  |cffffd100phaseloot publicar|r     sube el registro local entero")
    Print("  |cffffd100phaseloot criatura <id>|r")
    Print("  |cffffd100phaseloot global|r")
    Print("  |cffffd100phaseloot manifiesto|r")
    Print("  |cffffd100phaseloot historial|r   que cadaveres estan ya saqueados")
    Print("  |cffffd100phaseloot olvidar [guid]|r  un cadaver vuelve a estar entero")
    Print("  |cffffd100phaseloot limpiar confirmar|r  |cffff5555reinicia TODO el saqueo|r")
    Print("  |cffffd100phaseloot reconstruir|r  rehace el manifiesto desde el registro local")
    Print("  |cffffd100phaseloot purgar confirmar|r")
end, "Tablas de loot guardadas en la fase")

-- Tablon de contratos en la fase. Conduce HarfordContractsPhase sin depender de la UI.
API.RegisterCommand("phasetc", function(args)
    local P = HarfordContracts and HarfordContracts.Phase
    if not P then Print("HarfordContractsPhase no cargado"); return end
    local cmd, a = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")

    if cmd == "publicar" then
        -- PublishTracked, no Publish: la segunda reescribe el indice sin fusionar y borraria
        -- de la fase lo que este cliente no tenga.
        P.PublishTracked(false, function(ok, n, extra)
            if not ok then Print("|cffff5555" .. tostring(extra) .. "|r"); return end
            Print("Publicados |cffffd100" .. tostring(n) .. "|r contratos en la fase.")
        end)
        return
    end

    if cmd == "cargar" then
        Print("Pidiendo el indice a la fase...")
        P.LoadBoard(function(ok, info, err)
            if ok then
                Print("|cff55ff55Tablon cargado|r: |cffffd100" .. tostring(info) .. "|r contratos (esbozos).")
                Print("Abre uno con |cffffd100phasetc leer <id>|r para bajar el bloque completo.")
            else
                Print("|cffff5555No se pudo cargar|r: " .. tostring(err))
            end
        end)
        return
    end

    if cmd == "indice" then
        P.LoadIndex(function(indice, err)
            if not indice then Print("|cffff5555" .. tostring(err) .. "|r"); return end
            Print("Indice: |cffffd100" .. #indice .. "|r filas")
            for _, fila in ipairs(indice) do
                Print(string.format("  |cff808080%s|r  %s |cff808080[%s / %s]|r",
                    tostring(fila.id), tostring(fila.title),
                    tostring(fila.difficulty), tostring(fila.status)))
            end
        end)
        return
    end

    if cmd == "leer" then
        if a == "" then Print("uso: phasetc leer <contractId>"); return end
        P.LoadContract(a, function(contract, err)
            if not contract then Print("|cffff5555" .. tostring(err or "vacio") .. "|r"); return end
            Print("|cffffd100" .. tostring(contract.title) .. "|r")
            Print("  objetivos: " .. tostring(#(contract.objectives or {})) ..
                "   descripcion: " .. tostring(#tostring(contract.description or "")) .. " chars")
            -- Lo que NUNCA debe haber viajado.
            if contract.prep or contract.privateNotes then
                Print("  |cffff5555FUGA: viajaron campos privados|r")
            else
                Print("  |cff55ff55sin prep ni privateNotes|r")
            end
            P.ApplyContract(contract)
            Print("  aplicado sobre la BD local")
        end)
        return
    end

    if cmd == "borrar" then
        if a == "" then Print("uso: phasetc borrar <contractId>"); return end
        Print(P.DeleteContract(a) and "Bloque vaciado. Republica para regenerar el indice."
            or "|cffff5555No se pudo borrar|r")
        return
    end

    if cmd == "huerfanos" then
        -- Compara el indice que HAY en la fase contra los publicos locales. Lo que sobra
        -- son bloques que quedaron colgados al borrar contratos.
        P.PruneOrphans(function(ok, lista, err)
            if not ok or type(lista) ~= "table" then
                Print("|cffff5555" .. tostring(err or "fallo") .. "|r"); return
            end
            if #lista == 0 then Print("|cff55ff55Sin huerfanos|r - la fase esta limpia."); return end
            Print("Bloques huerfanos limpiados: |cffffd100" .. #lista .. "|r")
            for _, id in ipairs(lista) do Print("   |cff808080" .. tostring(id) .. "|r") end
        end)
        return
    end

    if cmd == "publicar-limpio" then
        P.PublishTracked(false, function(ok, n, limpiados)
            if not ok then Print("|cffff5555" .. tostring(limpiados or "fallo") .. "|r"); return end
            Print(string.format("Publicados |cffffd100%s|r, claves obsoletas vaciadas |cffffd100%d|r",
                tostring(n), type(limpiados) == "table" and #limpiados or 0))
        end)
        return
    end

    if cmd == "manifiesto" then
        -- El manifiesto es lo unico que hace alcanzable una clave: el servidor no deja
        -- listar ni borrar por prefijo.
        P.LoadManifest(function(claves, err)
            claves = type(claves) == "table" and claves or {}
            if #claves == 0 then
                Print("Manifiesto vacio" .. (err and (" (" .. tostring(err) .. ")") or "") .. ".")
                Print("|cff808080Publica una vez para crearlo.|r")
                return
            end
            local espejo = P.GetLocalManifest and P.GetLocalManifest() or {}
            Print(string.format("Claves conocidas: |cffffd100%d|r  (espejo local: |cffffd100%d|r)",
                #claves, #espejo))
            if err then Print("   |cffff9900la fase no contesto: " .. tostring(err) .. " - lista del espejo|r") end
            for _, k in ipairs(claves) do Print("   |cff808080" .. tostring(k) .. "|r") end
        end)
        return
    end

    if cmd == "purgar" then
        if a ~= "confirmar" then
            Print("|cffff5555Esto borra TODO lo que Harford tiene escrito en la fase.|r")
            Print("Escribe: |cffffd100phasetc purgar confirmar|r")
            return
        end
        P.PurgeAll(function(ok, borradas, err)
            if not ok then Print("|cffff5555" .. tostring(err or "fallo") .. "|r"); return end
            borradas = type(borradas) == "table" and borradas or {}
            Print(string.format("Purgadas |cffffd100%d|r claves + indice + manifiesto.", #borradas))
            for _, k in ipairs(borradas) do Print("   |cff808080" .. tostring(k) .. "|r") end
            Print("|cff808080Una clave que nunca se registro sigue siendo inalcanzable.|r")
        end)
        return
    end

    local claveIndice, prefijo = P.GetKeys()
    Print("|cffffd100Tablon de contratos en la fase|r")
    Print("  Disponible: " .. (P.IsAvailable() and "|cff55ff55si|r" or "|cffff5555no|r") ..
        "   Fase: |cffffd100" .. tostring(P.GetPhaseId()) .. "|r")
    Print("  Claves: |cff808080" .. claveIndice .. "|r  y  |cff808080" .. prefijo .. "<id>|r")
    local db = _G.HarfordContractsDB
    local total, esbozos = 0, 0
    for _, c in ipairs((db and db.contracts) or {}) do
        total = total + 1
        if P.IsStub(c) then esbozos = esbozos + 1 end
    end
    Print(string.format("  BD local: |cffffd100%d|r contratos (|cffffd100%d|r son esbozos de fase)",
        total, esbozos))
    Print("  |cffffd100phasetc publicar|r  escribe el tablon en la fase (DM)")
    Print("  |cffffd100phasetc cargar|r    lee el indice y pinta el tablon")
    Print("  |cffffd100phasetc indice|r    vuelca el indice tal cual")
    Print("  |cffffd100phasetc leer <id>|r baja un contrato completo")
    Print("  |cffffd100phasetc borrar <id>|r  vacia un bloque suelto")
    Print("  |cffffd100phasetc huerfanos|r  limpia bloques que el tablon ya no usa")
    Print("  |cffffd100phasetc publicar-limpio|r  limpia huerfanos y publica")
    Print("  |cffffd100phasetc manifiesto|r  que claves tiene Harford escritas en la fase")
    Print("  |cffffd100phasetc purgar confirmar|r  |cffff5555borra el tablon entero de la fase|r")
end, "Tablon de contratos guardado en la fase")

-- Sonda del almacen de fase de Epsilon (C_Epsilon.Get/SetPhaseAddonData via EpsilonLib).
-- Responde a las tres preguntas que no se pueden contestar leyendo codigo: si hay cuota,
-- cuanto admite una clave y que ocurre al escribir sin permiso.
-- TODA escritura usa claves TEST_* para no rozar jamas datos reales de la fase.
do
    local CLAVE = "TEST_SONDA"
    local ESPERA = 6

    local function Lib()
        return EpsilonLib and EpsilonLib.PhaseAddonData
    end

    local function Libs()
        if not LibStub then return nil, nil end
        return LibStub:GetLibrary("LibSerialize", true), LibStub:GetLibrary("LibDeflate", true)
    end

    -- La API no tiene ruta de error: si el servidor calla, el callback no se llama nunca.
    -- Sin este plazo el comando se quedaria mudo y pareceria colgado.
    local function LeerConPlazo(clave, alRecibir)
        local L = Lib()
        if not L then Print("EpsilonLib.PhaseAddonData no disponible"); return end
        local contestado = false
        L.Get(clave, function(texto)
            contestado = true
            alRecibir(texto or "")
        end)
        C_Timer.After(ESPERA, function()
            if not contestado then
                Print("|cffff5555sin respuesta|r tras " .. ESPERA .. "s para |cffffd100" .. clave .. "|r")
            end
        end)
    end

    -- El servidor VALIDA y lanza error Lua (confirmado: "key should have length <= 100").
    -- Sin pcall, cualquier escritura invalida aborta el comando entero.
    local function Escribir(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok then
            Print("|cffff5555El servidor rechazo la escritura|r")
            Print("   " .. tostring(err):gsub("^.*%.lua:%d+: ", ""))
        end
        return ok
    end

    local function Medir(tab, etiqueta)
        local LS, LD = Libs()
        if not (LS and LD) then Print("LibSerialize/LibDeflate no disponibles"); return end
        local crudo = LS:Serialize(tab)
        local comprimido = LD:CompressDeflate(crudo)
        local codificado = LD:EncodeForPrint(comprimido)
        local segmentos = math.ceil(#codificado / 3000)
        Print(string.format("%s: crudo |cffffd100%d|r -> deflate |cffffd100%d|r -> encode |cffffd100%d|r  = |cff66ccff%d|r segmento(s)",
            etiqueta, #crudo, #comprimido, #codificado, segmentos))
        return codificado
    end

    API.RegisterCommand("phasedata", function(args)
        local cmd, a = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")
        local L = Lib()

        if cmd == "medir" then
            -- Puramente local: no toca el servidor. Mide el tablon real que ya tienes.
            local db = _G.HarfordContractsDB
            local contratos = db and db.contracts
            if not (contratos and #contratos > 0) then
                Print("No hay contratos en el tablon local para medir.")
                return
            end
            local LS, LD = Libs()
            if not (LS and LD) then Print("LibSerialize/LibDeflate no disponibles"); return end

            -- Lo que subiria de verdad: sin notas privadas ni preparacion del DM.
            -- Lo que no se escribe no se puede filtrar.
            local function SoloPublico(c)
                local out = {}
                for k, v in pairs(c) do
                    if k ~= "prep" and k ~= "privateNotes" then out[k] = v end
                end
                return out
            end
            local function Tam(t)
                return #LD:EncodeForPrint(LD:CompressDeflate(LS:Serialize(t)))
            end

            local publicados, borradores = 0, 0
            for _, c in ipairs(contratos) do
                if tostring(c.status) == "draft" then borradores = borradores + 1
                else publicados = publicados + 1 end
            end
            Print(string.format("Contratos: |cffffd100%d|r  (publicados |cffffd100%d|r, borradores |cffffd100%d|r)",
                #contratos, publicados, borradores))

            Medir(contratos, "tablon entero, tal cual")

            local limpios, indice = {}, {}
            for _, c in ipairs(contratos) do
                limpios[#limpios + 1] = SoloPublico(c)
                indice[#indice + 1] = c.id
            end
            Medir(limpios, "tablon sin prep/notas")
            Medir(indice, "solo el indice de ids")

            -- Indice RICO: exactamente los campos que pinta la fila del tablon
            -- (HarfordContractsUI: icono, titulo+color por dificultad, meta duracion||estado,
            -- recompensa) mas los que filtran/buscan. Si esto cabe en un segmento, el tablon
            -- entero se pinta con UNA llamada y el contrato solo se baja al abrirlo.
            local CAMPOS_FILA = { "id", "title", "difficulty", "status", "duration",
                                  "rewardText", "category", "icon" }
            local rico = {}
            for _, c in ipairs(contratos) do
                local fila = {}
                for _, k in ipairs(CAMPOS_FILA) do fila[k] = c[k] end
                rico[#rico + 1] = fila
            end
            local codRico = Medir(rico, "INDICE RICO (lo que pinta la fila)")
            if codRico then
                local margen = 3000 - #codRico
                if margen > 0 then
                    local porContrato = #codRico / math.max(1, #contratos)
                    Print(string.format("   |cff55ff55Cabe en 1 segmento|r - sobran |cffffd100%d|r caracteres, sitio para ~|cffffd100%d|r contratos mas",
                        margen, math.floor(margen / math.max(1, porContrato))))
                else
                    Print("   |cffff5555No cabe en un segmento|r - el indice se troceara")
                end
            end

            local mayor, tamMayor = nil, -1
            for _, c in ipairs(contratos) do
                local tam = Tam(c)
                if tam > tamMayor then mayor, tamMayor = c, tam end
            end
            if mayor then
                Print(" ")
                Medir(mayor, "el mas gordo tal cual (" .. tostring(mayor.title) .. ")")
                Medir(SoloPublico(mayor), "el mas gordo sin prep/notas")
            end

            -- Coste de leer el tablon con cada estrategia, contra el throttle de 45/1.5s.
            local segsBlob = math.ceil(Tam(limpios) / 3000)
            local llamadasPorContrato = 1
            for _, c in ipairs(limpios) do
                llamadasPorContrato = llamadasPorContrato + math.ceil(Tam(c) / 3000)
            end
            Print(" ")
            Print(string.format("Leer todo como un blob unico: |cff66ccff%d|r llamadas", segsBlob))
            Print(string.format("Leer todo por contrato + indice: |cff66ccff%d|r llamadas (tope por tanda: 45)",
                llamadasPorContrato))
            return
        end

        if cmd == "integridad" then
            -- La pregunta que decide el diseno: sobrevive un contrato largo con texto real
            -- (tildes, egnes, pipes de color, item links, saltos de linea) al viaje de ida
            -- y vuelta, incluso cuando pasa de un segmento?
            if not L then Print("EpsilonLib.PhaseAddonData no disponible"); return end

            local SUCIO = "Contrato de la Guardia: |cffffd100[Espada rota]|r "
                .. "\195\161\195\169\195\173\195\179\195\186 \195\177\195\145 \194\161\194\191 "
                .. "|Hitem:6948:0:0:0:0:0:0:0:60|h[Piedra de hogar]|h|r "
                .. "separador || pipe suelto | y salto\nde linea\ty tabulador"

            -- OJO: repetir la misma frase NO agranda el dato, deflate la aplasta (medido:
            -- x72 bajaba de 13577 a 584). Para ejercitar el troceado hace falta texto que no
            -- se pueda comprimir, asi que se genera variado con un LCG.
            local veces = math.max(1, tonumber(a) or 1)
            local semilla = 12345
            local function Siguiente()
                semilla = (semilla * 1103515245 + 12345) % 2147483648
                return semilla
            end
            local ALFABETO = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
            local relleno = {}
            for i = 1, veces * 12 do
                local trozo = {}
                for _ = 1, 120 do
                    local pos = (Siguiente() % #ALFABETO) + 1
                    trozo[#trozo + 1] = ALFABETO:sub(pos, pos)
                end
                relleno[#relleno + 1] = i .. ") " .. SUCIO .. " " .. table.concat(trozo)
            end
            local original = {
                id = "TEST_integridad",
                title = "Prueba \195\161\195\169\195\173 |cffff0000roja|r",
                description = table.concat(relleno, "\n"),
                objectives = { { text = SUCIO, required = 3, current = 0, done = false } },
                rewardMoney = { gold = 12, silver = 34, copper = 56 },
                anidado = { a = { b = { c = SUCIO } } },
                numeros = { 0, -1, 1.5, 2^31, 0.1 + 0.2 },
                booleanos = { verdadero = true, falso = false },
            }

            -- Cuanto ocupa esto de verdad, y en cuantos segmentos cae.
            local codificado = Medir(original, "carga de prueba")
            if not codificado then return end

            local function Comparar(a1, b1, ruta)
                ruta = ruta or ""
                if type(a1) ~= type(b1) then
                    return false, ruta .. " tipo " .. type(a1) .. " -> " .. type(b1)
                end
                if type(a1) ~= "table" then
                    if a1 ~= b1 then
                        return false, ruta .. " valor distinto"
                    end
                    return true
                end
                for k, v in pairs(a1) do
                    local ok, err = Comparar(v, b1[k], ruta .. "." .. tostring(k))
                    if not ok then return false, err end
                end
                for k in pairs(b1) do
                    if a1[k] == nil then return false, ruta .. "." .. tostring(k) .. " sobra al volver" end
                end
                return true
            end

            if not Escribir(L.SaveTable, CLAVE, original) then return end
            Print("Escrito. Releyendo para comparar byte a byte...")

            C_Timer.After(1.5, function()
                L.LoadTable(CLAVE, function(vuelta)
                    if type(vuelta) ~= "table" then
                        Print("|cffff5555No volvio una tabla|r: " .. tostring(vuelta))
                        return
                    end
                    local ok, err = Comparar(original, vuelta)
                    if ok then
                        local segs = math.ceil(#codificado / 3000)
                        Print("|cff55ff55INTEGRO|r - identico campo por campo")
                        Print(string.format("   descripcion: |cffffd100%d|r caracteres, |cff66ccff%d|r segmento(s)",
                            #original.description, segs))
                        Print("   tildes, egnes, pipes, item links, saltos de linea y anidamiento: intactos")
                        if segs > 1 then
                            Print("   |cff55ff55El troceado multi-segmento funciona|r")
                        else
                            Print("   |cffff9900Aun en 1 segmento|r - sube el multiplicador para probar el troceado")
                        end
                    else
                        Print("|cffff5555CORRUPTO|r en " .. tostring(err))
                    end
                end)
            end)
            return
        end

        if cmd == "escribir" then
            if not L then Print("EpsilonLib.PhaseAddonData no disponible"); return end
            -- Viaje redondo con marca de tiempo, para distinguir un dato nuevo de uno viejo.
            local marca = tostring(time())
            if not Escribir(L.SaveTable, CLAVE, { marca = marca, texto = "sonda Harford", n = 12345 }) then
                return
            end
            Print("Escrito con marca |cffffd100" .. marca .. "|r. Releyendo...")
            C_Timer.After(1, function()
                L.LoadTable(CLAVE, function(tab)
                    if type(tab) ~= "table" then
                        Print("|cffff5555Volvio algo que no es tabla|r: " .. tostring(tab))
                        Print("Si no tienes permiso de escritura en la fase, esto es lo que se ve.")
                        return
                    end
                    if tab.marca == marca then
                        Print("|cff55ff55Viaje redondo correcto|r - la escritura SI cuajo.")
                    else
                        Print("|cffff5555Volvio una marca vieja|r (" .. tostring(tab.marca) .. ")")
                        Print("La escritura fue rechazada en silencio: lo que hay es de antes.")
                    end
                end)
            end)
            return
        end

        if cmd == "leer" then
            LeerConPlazo(a ~= "" and a or CLAVE, function(texto)
                Print(string.format("Devuelto |cffffd100%d|r caracteres", #texto))
                if #texto == 0 then Print("Vacio = esa clave no existe en la fase.") end
            end)
            return
        end

        if cmd == "clave" then
            -- Cuanto admite una clave. Escribe y relee con longitudes crecientes.
            if not L then Print("EpsilonLib.PhaseAddonData no disponible"); return end
            local n = tonumber(a) or 60
            local clave = "TEST_" .. string.rep("K", math.max(1, n - 5))
            Print(string.format("Probando clave de |cffffd100%d|r caracteres...", #clave))
            if not Escribir(L.Set, clave, "ok" .. tostring(time())) then
                Print("   |cff808080El troceado anade _2, _3... asi que el presupuesto real es menor.|r")
                return
            end
            C_Timer.After(1, function()
                LeerConPlazo(clave, function(texto)
                    Print(#texto > 0 and ("|cff55ff55Aguanta|r a " .. #clave .. " caracteres")
                        or ("|cffff5555Escribio pero vuelve vacia|r a " .. #clave))
                end)
            end)
            return
        end

        if cmd == "borrar" then
            if not L then Print("EpsilonLib.PhaseAddonData no disponible"); return end
            -- Borrar es escribir vacio; no hay borrado real.
            -- Sin argumento limpia la sonda; con argumento, CUALQUIER clave de la fase.
            local objetivo = (a ~= "" and a) or CLAVE
            Escribir(C_Epsilon.SetPhaseAddonData, objetivo, "")
            for i = 2, 8 do Escribir(C_Epsilon.SetPhaseAddonData, objetivo .. "_" .. i, "") end
            Print("Vaciada |cffffd100" .. objetivo .. "|r y sus segmentos 2..8.")
            Print("|cff808080Comprueba con: phasedata leer " .. objetivo .. "|r")
            return
        end

        -- Estado por defecto.
        Print("|cffffd100Sonda del almacen de fase|r")
        if not C_Epsilon then
            Print("|cffff5555C_Epsilon no existe|r - esto no es un cliente Epsilon.")
            return
        end
        Print("  Fase actual: |cffffd100" .. tostring(C_Epsilon.GetPhaseId and C_Epsilon.GetPhaseId()) .. "|r")
        local function Si(f) return (f and f()) and "|cff55ff55si|r" or "|cff808080no|r" end
        Print(string.format("  Dueno %s   Oficial %s   Miembro %s   DM %s",
            Si(C_Epsilon.IsOwner), Si(C_Epsilon.IsOfficer), Si(C_Epsilon.IsMember),
            (C_Epsilon.IsDM and "|cff55ff55si|r" or "|cff808080no|r")))
        Print("  EpsilonLib.PhaseAddonData: " .. (L and "|cff55ff55cargado|r" or "|cffff5555ausente|r"))
        local LS, LD = Libs()
        Print("  LibSerialize " .. (LS and "|cff55ff55si|r" or "|cffff5555no|r") ..
            "   LibDeflate " .. (LD and "|cff55ff55si|r" or "|cffff5555no|r"))
        Print("  |cffffd100phasedata medir|r    mide el tablon real, sin tocar el servidor")
        Print("  |cffffd100phasedata escribir|r prueba el viaje redondo (y si tienes permiso)")
        Print("  |cffffd100phasedata integridad [n]|r  texto hostil de ida y vuelta (n = multiplicador)")
        Print("  |cffffd100phasedata leer [clave]|r")
        Print("  |cffffd100phasedata clave <n>|r  prueba una clave de n caracteres (tope conocido: 100)")
        Print("  |cffffd100phasedata borrar [clave]|r  vacia la sonda, o CUALQUIER clave que le des")
    end, "Sonda del almacen de fase de Epsilon (cuota, claves, permisos)")
end

-- Resuelve una receta por id EXACTO o por NOMBRE visible, tolerando tildes y mayusculas.
-- Con 1661 recetas, obligar a escribir el id de memoria hace la herramienta inservible.
local function ResolveRecipe(texto)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return nil end
    texto = tostring(texto or "")
    if texto == "" then return nil end
    local exacta = HarfordProfessions.GetRecipe(texto)
    if exacta then return texto, exacta end

    local function Normaliza(v)
        v = tostring(v or "")
        if HarfordClassColors and HarfordClassColors.StripAccents then
            v = HarfordClassColors.StripAccents(v)
        end
        return v:lower():gsub("[%s_]", "")
    end
    local buscado = Normaliza(texto)
    local parciales = {}
    for _, def in ipairs(HarfordProfessions.GetProfessions and HarfordProfessions.GetProfessions() or {}) do
        for _, r in ipairs(HarfordProfessions.GetRecipes and HarfordProfessions.GetRecipes(def.id) or {}) do
            local nid, nname = Normaliza(r.id), Normaliza(r.name)
            if nid == buscado or nname == buscado then return r.id, r end
            if #parciales < 8 and (nid:find(buscado, 1, true) or nname:find(buscado, 1, true)) then
                parciales[#parciales + 1] = string.format("%s (%s)", r.id, tostring(r.name))
            end
        end
    end
    return nil, nil, parciales
end

-- Entrenadores de profesion. Sirve para probar el flujo entero sin tener NPCs colocados:
-- `colocar` simula lo que hara el ArcSpell del gossip al nombrar su entrada de catalogo.
API.RegisterCommand("entrenador", function(args)
    local T = _G.HarfordProfessionTrainers
    if not T then Print("HarfordProfessionTrainers no cargado"); return end
    local cmd, a, b = tostring(args or ""):match("^%s*(%S*)%s*(%S*)%s*(.-)%s*$")

    if cmd == "abrir" then
        -- Lo mismo que hara la opcion de gossip del NPC, para probarla sin tener el NPC puesto.
        if a == "" then Print("uso: entrenador abrir <nombreDeCatalogo>"); return end
        local abrir = _G.HarfordTrainerAPI and _G.HarfordTrainerAPI.OpenTrainer
        local ok, err
        if abrir then ok, err = abrir(a) end
        if not ok then Print("|cffff5555" .. tostring(err or "no se pudo abrir") .. "|r") end
        return
    end

    if cmd == "colocar" or cmd == "quitar" then
        if a == "" then Print("uso: entrenador " .. cmd .. " <nombreDeCatalogo>"); return end
        local def = T.Get(a)
        if not def then
            Print("Nombre de entrenador desconocido: |cffffd100" .. a .. "|r")
            Print("   mira |cffffd100entrenador <profesion>|r para ver los nombres")
            return
        end
        if cmd == "quitar" then
            -- Solo se puede retirar lo registrado en vivo; lo del catalogo se cambia en el Lua.
            local ok = T.Unbind and T.Unbind(def.id)
            Print(ok and ("Retirado del mundo: |cffffd100" .. def.id .. "|r")
                or "|cffff5555Ese entrenador viene colocado desde el catalogo|r")
            return
        end
        local ok, err = T.Bind(def.id, { zone = b ~= "" and b or nil })
        if not ok then Print("|cffff5555" .. tostring(err) .. "|r"); return end
        Print(string.format("Colocado |cffffd100%s|r: cierra |cffffd100%d|r receta(s) de %s %s",
            def.id, #T.GetRecipesFor(def), tostring(def.profession), tostring(def.tier)))
        return
    end

    if cmd == "ensenar" then
        local trainerId, recipeId = a, b
        if trainerId == "" or recipeId == "" then
            Print("uso: entrenador ensenar <nombreDeCatalogo> <receta>"); return
        end
        local resuelta, _, parciales = ResolveRecipe(recipeId)
        if not resuelta then
            Print("Receta desconocida: |cffffd100" .. recipeId .. "|r")
            for _, sug in ipairs(parciales or {}) do Print("   quiza: |cff808080" .. sug .. "|r") end
            return
        end
        local ok, err = T.Teach(trainerId, resuelta)
        recipeId = resuelta
        Print(ok and ("Aprendida: " .. recipeId) or ("|cffff5555" .. tostring(err) .. "|r"))
        return
    end

    if cmd == "receta" then
        if a == "" then Print("uso: entrenador receta <recipeId>"); return end
        local resuelta = ResolveRecipe(a)
        if resuelta then a = resuelta end
        local texto, def = T.DescribeForRecipe(a)
        if not texto then Print("Esa receta no la ensena ningun entrenador conocido."); return end
        Print(string.format("|cffffd100%s|r la ensena |cffffd100%s|r  [%s]%s", a, texto,
            tostring(def.id),
            def.colocado and "" or " |cff808080(aun no existe en el mundo)|r"))
        return
    end

    -- El catalogo son 75 entrenadores: sin filtro se resume por profesion y con el nombre de una
    -- profesion se desglosan sus rangos. Volcar los 75 llenaria el chat sin decir nada.
    local todos = T.GetAll()
    local filtro = cmd ~= "" and ResolveProfession and ResolveProfession(cmd) or nil

    if filtro then
        Print(string.format("Entrenadores de |cffffd100%s|r", tostring(filtro.name or filtro.id)))
        for _, def in ipairs(todos) do
            if def.profession == filtro.id then
                local n = #T.GetRecipesFor(def)
                Print(string.format("  %-22s %-10s %-16s %3d receta(s)  %s",
                    tostring(def.id), tostring(def.tier or "-"), tostring(def.zone or "-"), n,
                    def.colocado and "|cff55ff55colocado|r"
                        or "|cff808080sin colocar: rango abierto|r"))
            end
        end
        return
    end

    local orden, porProf = {}, {}
    for _, def in ipairs(todos) do
        local prof = tostring(def.profession or "-")
        if not porProf[prof] then porProf[prof] = { rangos = 0, puestos = 0, recetas = 0 } end
        local acc = porProf[prof]
        if acc.rangos == 0 then orden[#orden + 1] = prof end
        acc.rangos = acc.rangos + 1
        acc.recetas = acc.recetas + #T.GetRecipesFor(def)
        if def.colocado then acc.puestos = acc.puestos + 1 end
    end
    table.sort(orden)
    Print(string.format("Entrenadores conocidos: |cffffd100%d|r", #todos))
    for _, prof in ipairs(orden) do
        local acc = porProf[prof]
        Print(string.format("  %-16s %d/%d colocados   %3d receta(s) cubiertas", prof,
            acc.puestos, acc.rangos, acc.recetas))
    end
    Print("  |cffffd100entrenador <profesion>|r   desglose por rango")
    Print("  |cffffd100entrenador abrir <nombre>|r   abre su ventana, como hara el gossip")
    Print("  |cffffd100entrenador receta <receta>|r   quien la ensena")
    Print("  |cffffd100entrenador colocar <nombre> [zona]|r  lo pone en el mundo y cierra su rango")
    Print("  |cffffd100entrenador quitar <nombre>|r   lo retira")
    Print("  |cffffd100entrenador ensenar <nombre> <receta>|r  aprende de el")
end, "Entrenadores de profesion: consulta y pruebas sin NPC colocado")

API.RegisterCommand("carga", function(args)
    local B = _G.HarfordDnDBurden
    if not B then Print("HarfordDnDBurden no cargado"); return end
    local cmd, a, b = tostring(args or ""):match("^%s*(%S*)%s*(%S*)%s*(%S*)")

    if cmd == "peso" then
        local id, libras = tonumber(a), tonumber(b)
        if not (id and libras) then Print("uso: carga peso <itemId> <libras>"); return end
        B.SetWeight(id, libras)
        Print(string.format("Peso declarado: objeto %d = %d libras.", id, libras))
        return
    elseif cmd == "romper" then
        local id = tonumber(a)
        if not id then Print("uso: carga romper <itemId>"); return end
        local ok, err = B.Unattune(id)
        if not ok then Print("|cffff5555" .. tostring(err) .. "|r") end
        return
    end

    local e = B.GetStatus()
    Print(string.format("Sintonizacion: |cffffd100%d/%d|r", e.attuned, e.maxAttuned))
    for _, entrada in ipairs(B.GetAttuned()) do
        Print(string.format("   %s |cff808080(id %s)|r", tostring(entrada.name), tostring(entrada.itemId)))
    end
    Print(string.format("Carga: %s%d|r / %d libras (Fuerza x %d)",
        e.overloaded and "|cffff5555" or "|cffffffff",
        e.carried, e.capacity, B.CARRY_PER_STRENGTH))
    if e.unknownWeights > 0 then
        Print(string.format("   |cffff9900%d objeto(s) sin peso declarado|r no cuentan; usa 'carga peso <itemId> <libras>'.",
            e.unknownWeights))
    end
    if e.overloaded then Print("   |cffff5555Sobrecargado.|r") end
    Print("   |cff888888Ctrl+click en un hueco de la ficha sintoniza o rompe la sintonizacion.|r")
end, "Estado de sintonizacion y carga (carga peso <id> <libras> | carga romper <id>)")

-- Ajuste EN VIVO del skin de profesiones. Excepcion consciente a la norma de no crear comandos
-- de ajuste visual: es tooling temporal para cuadrar la superposicion mirandola, y lo que salga
-- se fija despues en PROF_BOOKMARK / PROF_FRAME_OFFSET dentro de HarfordCharacterPanel.
--   marcapaginas <ancho>        ancho de la ventana de recorte
--   marcapaginas mover <dx> <dy>   mueve la VENTANA sobre el libro
--   marcapaginas tex <dx> <dy>     mueve la TEXTURA dentro de la ventana
--   marco <dx> <dy>             mueve el recorte de los cuatro marcos
--   raton                       arrastrar el marcapaginas con el boton izquierdo
--   dump                        imprime los valores listos para fijar en el codigo
API.RegisterCommand("profskin", function(args)
    local panel = _G.HarfordCharacterPanel
    local V = panel and panel._ProfSkinValues
    local Apply = panel and panel._ApplyProfSkin
    local P = panel and panel._professionsState
    if not (V and Apply and P) then
        Print("Abre la pestana |cffffd100Profesiones|r primero.")
        return
    end
    local cmd, a, b, c = tostring(args or ""):lower():match("^%s*(%S*)%s*(%-?%S*)%s*(%-?%S*)%s*(%-?%S*)")

    local function Dump()
        Print("Valores actuales, para fijarlos en HarfordCharacterPanel:")
        Print(string.format("  |cffffd100local PROF_BOOKMARK = { w = %d, tx = %d, ty = %d }|r",
            V.bookmark.w, V.bookmark.tx, V.bookmark.ty))
        Print(string.format("  |cffffd100local PROF_FRAME_OFFSET = { x = %d, y = %d }|r",
            V.frame.x, V.frame.y))
        if V.margen then
            Print(string.format("  |cffffd100local PROF_FRAME_MARGIN = %d|r", V.margen()))
        end
    end

    if cmd == "dump" then Dump(); return end

    if cmd == "marcapaginas" then
        if a == "mover" then
            -- La franja va pegada al borde y con el alto de la pagina; lo unico que se mueve es
            -- la TEXTURA dentro de ella, que es lo que elige que trozo asoma.
            V.bookmark.tx = V.bookmark.tx + (tonumber(b) or 0)
            V.bookmark.ty = V.bookmark.ty + (tonumber(c) or 0)
        elseif a == "tex" then
            V.bookmark.tx = V.bookmark.tx + (tonumber(b) or 0)
            V.bookmark.ty = V.bookmark.ty + (tonumber(c) or 0)
        elseif tonumber(a) then
            V.bookmark.w = math.max(1, tonumber(a))
        else
            Print("uso: profskin marcapaginas <ancho> | mover <dx> <dy> | tex <dx> <dy>")
            return
        end
        Apply()
        Print(string.format("Marcapaginas: ancho %d, textura desplazada (%d, %d)",
            V.bookmark.w, V.bookmark.tx, V.bookmark.ty))
        return
    end

    if cmd == "margen" then
        if not V.margen then Print("Esta version no expone el margen"); return end
        if tonumber(a) then V.margen(tonumber(a)) end
        Apply()
        local m = V.margen()
        Print(string.format("Margen del marco: %d  ->  ventana %dx%d por hueco", m, 437 + m * 2, 81 + m * 2))
        if 81 + m * 2 > 93 then
            Print("   |cffff9900Ojo:|r con mas de 6 los marcos contiguos se solapan (el paso es 93).")
        end
        return
    end

    if cmd == "marco" then
        V.frame.x = V.frame.x + (tonumber(a) or 0)
        V.frame.y = V.frame.y + (tonumber(b) or 0)
        Apply()
        Print(string.format("Marcos: recorte en (%d, %d)", V.frame.x, V.frame.y))
        return
    end

    -- Composicion del icono: el XML nativo pone el aro en OVERLAY y el icono en BORDER con
    -- alphaMode="ADD", y al no haber profesion lo deja desaturado al 60%. Sobre el pergamino del
    -- libro de habilidades ese ADD puede quedar casi invisible bajo el orbe del aro, que es lo
    -- que se ve como "fondo negro". Aqui se compara con la alternativa sin ADD.
    if cmd == "icono" then
        local b = (P.profButtons or {})[1]
        if not (b and b.icon) then Print("El primer hueco aun no existe"); return end
        if a == "normal" then
            for _, boton in ipairs(P.profButtons or {}) do
                if boton.icon then
                    boton.icon:SetBlendMode("BLEND")
                    boton.icon:SetAlpha(1)
                    if SetDesaturation then SetDesaturation(boton.icon, false) end
                end
            end
            Print("Icono en |cff38d26aBLEND, alpha 1, sin desaturar|r (alternativa).")
            return
        elseif a == "nativo" then
            for _, boton in ipairs(P.profButtons or {}) do
                if boton.icon then
                    boton.icon:SetBlendMode("ADD")
                    boton.icon:SetAlpha(0.6)
                    if SetDesaturation then SetDesaturation(boton.icon, true) end
                end
            end
            Print("Icono en |cffffd100ADD, alpha 0.6, desaturado|r (como el XML nativo).")
            return
        elseif a == "aro" then
            for _, boton in ipairs(P.profButtons or {}) do
                if boton.iconBorder then
                    boton.iconBorder:SetShown(not boton.iconBorder:IsShown())
                end
            end
            Print("Aro alternado: si el icono aparece al ocultarlo, es el aro quien lo tapa.")
            return
        end
        Print("Composicion del hueco 1:")
        local function dump(nombre, region)
            if not region then Print("   " .. nombre .. ": no existe"); return end
            local capa, sub = region:GetDrawLayer()
            Print(string.format("   %-10s capa %s/%s  alpha %.2f  mezcla %s  visible %s",
                nombre, tostring(capa), tostring(sub), region:GetAlpha() or 1,
                tostring(region.GetBlendMode and region:GetBlendMode() or "-"),
                tostring(region:IsShown())))
        end
        dump("icono", b.icon)
        dump("aro", b.iconBorder)
        Print(string.format("   nivel del hueco %d, de la lista %d, del marco %d",
            b:GetFrameLevel() or 0,
            P.profList and P.profList:GetFrameLevel() or 0,
            (P.frameCovers or {})[1] and P.frameCovers[1]:GetFrameLevel() or 0))
        Print("  |cffffd100profskin icono normal|r / |cffffd100nativo|r / |cffffd100aro|r para comparar en vivo")
        return
    end

    Print("|cffffd100profskin|r — ajuste en vivo del skin de profesiones:")
    Print("  |cffffd100marcapaginas <ancho>|r           ancho de la franja (ahora 65)")
    Print("  |cffffd100marcapaginas mover <dx> <dy>|r   desplaza la textura dentro de la franja")
    Print("  |cffffd100marco <dx> <dy>|r                mueve el recorte de los 4 marcos")
    Print("  |cffffd100margen <n>|r                     cuanto ornamento se recoge (ahora 6)")
    Print("  |cffffd100icono|r                          composicion del icono y su aro")
    Print("  |cffffd100dump|r                           imprime los valores para fijarlos")
    Dump()
end, "Ajuste en vivo del skin de la pestana Profesiones (marcapaginas y marcos)")

API.RegisterCommand("proftex", function()
    -- El chat scrollea: el VEREDICTO va al final, que es lo unico que queda a la vista.
    -- `GetFileNameFromID` no existe en este cliente, asi que no se usa: la unica prueba fiable
    -- de que una ruta resuelve es que `GetFileIDFromPath` devuelva un id.
    local rutas = {
        { ruta = "Interface\\Spellbook\\Professions-Book-Left",     clave = true },
        { ruta = "Interface\\Spellbook\\Professions-Book-Right",    clave = true },
        { ruta = "Interface\\Spellbook\\ProfessionsBook",           clave = false },
        { ruta = "Interface\\Spellbook\\Professions-Progress-Fill", clave = false },
        { ruta = "Interface\\Spellbook\\Spellbook-Page-1",          clave = false },
        { ruta = "Interface\\Spellbook\\Spellbook-Page-2",          clave = false },
    }
    if not GetFileIDFromPath then
        Print("|cffff5555Este cliente no expone GetFileIDFromPath: no se puede comprobar.|r")
        return
    end

    local faltanClave = {}
    for _, entrada in ipairs(rutas) do
        local id = GetFileIDFromPath(entrada.ruta)
        Print(string.format("  %-28s %s",
            entrada.ruta:match("([^\\]+)$") or entrada.ruta,
            id and ("|cff38d26aOK|r  fileID " .. tostring(id)) or "|cffff5555NO EXISTE|r"))
        if not id and entrada.clave then faltanClave[#faltanClave + 1] = entrada.ruta end
    end

    Print(" ")
    if #faltanClave == 0 then
        Print("|cff38d26aVEREDICTO: las dos paginas de profesiones existen.|r La pestana debe pintarse")
        Print("igual que el libro nativo. Si aun se ve mal, es colocacion, no textura.")
    else
        Print("|cffff5555VEREDICTO: faltan " .. #faltanClave .. " pagina(s) de profesiones en este build.|r")
        Print("Hay que quedarse con los fileID (383588/383589) o recortar de otra textura.")
    end
    -- Alto REAL de la pagina: de el depende hasta donde llegan los marcos de profesion.
    local P = _G.HarfordCharacterPanel and _G.HarfordCharacterPanel._professionsState
    local page1 = P and P.profPage1
    if page1 and page1.GetHeight then
        local h = page1:GetHeight() or 0
        Print(string.format("Pagina de profesiones: alto %d  ->  borde inferior en -%d",
            math.floor(h), math.floor(25 + h)))
        for i = 3, 5 do
            local arriba = 67 + (i - 1) * 93
            Print(string.format("   marco %d: arriba -%d, cabe %d de 81",
                i, arriba, math.max(0, math.min(81, math.floor(25 + h - arriba)))))
        end
    else
        Print("|cff808080Abre la pestana Profesiones para poder medir la pagina.|r")
    end
    Print("Para capturar el frame nativo: abre el libro de hechizos en Profesiones y ejecuta")
    Print("  |cffffd100/harford debug run probeframecapture SpellBookProfessionFrame profbook|r")
    Print("  |cffffd100/harford debug run probeframecapture SpellBookFrame profpagina|r")
    Print("y despues |cffffd100/harford debug run probeframeexport|r")
end, "Comprueba las texturas del libro de profesiones nativo y dice como capturarlo")

API.RegisterCommand("compendio", function(args)
    local api = _G.HarfordCompendioAPI
    local all = api and api.GetAllSpells and api.GetAllSpells() or {}
    if #all == 0 then Print("Compendio no cargado"); return end
    local filtro = tostring(args or ""):lower():match("^%s*(%S*)")

    local total, conc, concDeclarada, ataque, salvacion, area, curacion, informativos = 0, 0, 0, 0, 0, 0, 0, 0
    local pendientes = {}
    for _, spell in ipairs(all) do
        total = total + 1
        if spell.concentration == true then concDeclarada = concDeclarada + 1 end
        if api.RequiresConcentration and api.RequiresConcentration(spell) then conc = conc + 1 end
        if spell.attack and spell.attack ~= "" then ataque = ataque + 1 end
        if spell.savingThrow and spell.savingThrow ~= "" then salvacion = salvacion + 1 end
        local def = api.BuildAreaDefinition and api.BuildAreaDefinition(spell)
        if def then
            local res = def.area and def.area.resolution
            if res == "heal" then curacion = curacion + 1 else area = area + 1 end
        else
            informativos = informativos + 1
            if spell.damage and spell.damage ~= "" then
                pendientes[#pendientes + 1] = spell
            end
        end
    end

    Print(string.format("Conjuros: |cffffd100%d|r", total))
    Print(string.format("  Concentracion efectiva %d (declarada en el campo: %d)", conc, concDeclarada))
    Print(string.format("  Campo ataque %d   salvacion %d", ataque, salvacion))
    Print(string.format("  Resuelve el motor: area/ataque %d   curacion %d", area, curacion))
    Print(string.format("  Solo anuncio: |cffff9900%d|r  (con dano declarado sin via: %d)",
        informativos, #pendientes))
    if filtro == "pendientes" then
        for i = 1, math.min(#pendientes, 40) do
            local s = pendientes[i]
            Print(string.format("   |cffcccccc%s|r  %s", tostring(s.id), tostring(s.damage)))
        end
    else
        Print("  |cff888888/harford debug run compendio pendientes|r para el listado")
        Print("  |cff888888/harford debug run compendio <id>|r para ver como lo resuelve el motor")
    end
end, "Auditoria del compendio de conjuros (que resuelve el motor y que no)")

-- Que produce el motor para UN conjuro concreto: sirve para comprobar en vivo el escalado de
-- trucos por nivel de personaje y la subida por espacio superior, que antes no se aplicaban.
API.RegisterCommand("conjuro", function(args)
    local id = tostring(args or ""):match("^%s*(%S+)")
    if not id then Print("Uso: /harford debug run conjuro <id>  (p.ej. descarga_de_fuego)"); return end
    local api = _G.HarfordCompendioAPI
    local spell = api and api.GetSpellById and api.GetSpellById(id)
    if not spell then Print("No existe el conjuro |cffffd100" .. id .. "|r"); return end

    local nivelPJ = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
        and HarfordDnDProgression.GetTotalLevel() or 0
    Print(string.format("|cffffd100%s|r  nivel %s   (personaje nivel %d)",
        tostring(spell.name), tostring(spell.level), nivelPJ))
    Print(string.format("  duracion: %s", tostring(spell.duration)))
    Print(string.format("  concentracion: campo=%s  |cff00ccffefectiva=%s|r",
        tostring(spell.concentration == true),
        tostring(api.RequiresConcentration and api.RequiresConcentration(spell))))
    Print(string.format("  dano declarado: %s", tostring(spell.damage ~= "" and spell.damage or "-")))

    local def = api.BuildAreaDefinition and api.BuildAreaDefinition(spell)
    if not def or not def.area then
        Print("  |cffff9900El motor NO lo resuelve|r: se queda en anuncio informativo.")
        return
    end
    local area = def.area
    Print(string.format("  resolucion: |cff00ff00%s|r   forma: %s %s",
        tostring(area.resolution), tostring(area.shape), tostring(area.sizeText)))
    if area.dc then Print("  CD: " .. tostring(area.dc) .. "  salvacion: " .. tostring(area.saveAbility)) end
    if area.attackBonus then Print("  bonus de ataque: " .. tostring(area.attackBonus)) end
    for _, c in ipairs(area.damageComponents or area.healingComponents or {}) do
        Print(string.format("   -> |cff66ccff%s%s|r %s",
            tostring(c.damageDice or c.fixedAmount),
            (c.damageBonus and c.damageBonus ~= 0) and string.format("%+d", c.damageBonus) or "",
            tostring(c.damageType or "")))
    end
end, "Volcado de como el motor resuelve un conjuro concreto del compendio")

API.RegisterCommand("reglas", function(args)
    local cmd, rest = tostring(args or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()

    if cmd == "cansancio" then
        local C = _G.HarfordDnDConditions
        if not C then Print("Condiciones no cargadas"); return end
        if rest ~= "" then C.SetExhaustion("player", tonumber(rest) or 0) end
        local nivel = C.GetExhaustion("player")
        Print("Cansancio: nivel " .. nivel)
        for _, efecto in ipairs(C.GetExhaustionEffects(nivel)) do Print("   - " .. efecto) end
        return
    end

    if cmd == "concentracion" then
        local K = _G.HarfordDnDConcentration
        if not K then Print("Concentracion no cargada"); return end
        if rest == "" then
            Print("Concentrado en: " .. tostring(K.GetSpellName() or "nada"))
        elseif rest:lower() == "romper" then
            K.Break("prueba de debug")
        elseif tonumber(rest) then
            K.OnDamage(tonumber(rest), "debug")
        else
            K.Begin(rest)
        end
        return
    end

    if cmd == "heroe" then
        local H = _G.HarfordDnDHeroPoints
        if not H then Print("Puntos de heroe no cargados"); return end
        if rest:lower() == "gastar" then H.Spend() return end
        local st = H.GetStatus()
        Print(string.format("Puntos de heroe: %d/%d (nivel %d)", st.current, st.max, st.level))
        return
    end

    if cmd == "carga" then
        local B = _G.HarfordDnDBurden
        if not B then Print("Carga no cargada"); return end
        local st = B.GetStatus()
        Print(string.format("Carga: %d de %d libras%s", st.carried, st.capacity,
            st.overloaded and " |cffff5555(sobrecargado)|r" or ""))
        Print(string.format("Sintonizados: %d de %d", st.attuned, st.maxAttuned))
        for _, o in ipairs(B.GetAttuned()) do Print("   - " .. tostring(o.name)) end
        if st.unknownWeights > 0 then
            Print(string.format("|cffffcc00%d objetos sin peso declarado|r (el cliente no expone el peso).",
                st.unknownWeights))
        end
        return
    end

    if cmd == "cobertura" then
        local M = _G.HarfordDnDManeuvers
        if not M then Print("Maniobras no cargadas"); return end
        if rest ~= "" then M.SetCover(rest) end
        local nivel, def = M.GetCover()
        Print(string.format("Cobertura: %s (%s)", def and def.label or nivel,
            def and def.ac and ("+" .. def.ac .. " CA y salv. Destreza") or "no se puede elegir como objetivo"))
        return
    end

    Print("Uso: reglas cansancio [0-6] | concentracion [nombre|romper|<dano>] | heroe [gastar] | carga | cobertura [none|half|three|total]")
end, "prueba los sistemas de reglas nuevos")

-- Diagnostico pasivo de la ruta protegida que usa la confirmacion nativa de
-- intercambio. No inspecciona padres, regiones ni modifica frames: solo pide
-- al cliente el origen de taint de globals concretos.
API.RegisterCommand("tainttrade", function()
    if type(issecurevariable) ~= "function" then
        Print("El cliente no expone issecurevariable")
        return
    end

    Print("Taint de trade/UIParent:")
    local names = {
        "TradeFrame",
        "TradeFrame_OnEvent",
        "ClickTradeButton",
        "AcceptTrade",
        "StaticPopup1",
        "StaticPopup2",
        "StaticPopup3",
        "StaticPopup4",
        "UIParent_ManageFramePositions",
        "UIPARENT_MANAGED_FRAME_POSITIONS",
    }
    for _, name in ipairs(names) do
        local secure, source = issecurevariable(name)
        local state = secure and "seguro" or "CONTAMINADO"
        local by = source and (" por " .. tostring(source)) or ""
        Print(string.format("  %s: %s%s", name, state, by))
    end
end, "origen de taint en trade/UIParent; ejecutar tras abrir la confirmacion")

-- Que texturas de barra de lanzamiento resuelven en ESTE cliente. Epsilon no tiene el mismo
-- listado de ficheros que el retail, y una ruta que no resuelve deja la barra vacia EN SILENCIO:
-- `SetTexture` con una ruta inexistente no falla, simplemente no pinta. Fue lo que dejo la barra
-- de fabricacion con el borde perfecto y nada dentro.
-- El bucle de sonido de una profesion se encadena por SOUNDKIT_FINISHED, sin reloj. Esto lo
-- arranca tal cual suena al fabricar y lo corta a los 5 s (lo que dura el casteo) para poder oir
-- que no se solapa ni deja silencio.
-- Los iconos de arma vienen de la web y son nombres de Wowhead: no todos tienen por que existir
-- en el cliente de Epsilon, y una ruta que no resuelve se pinta en VERDE sin avisar. Esto los
-- comprueba los 52 de golpe.
-- Mide el resaltado del selector contra su hueco. El nativo pone 50x50 sobre un hueco de 37x37;
-- si aqui no sale centrado, los numeros lo dicen y no hay que adivinar.
-- Repara el About del perfil TRP3 activo si le faltan T1/T3. Explicito, nunca automatico.
API.RegisterCommand("aboutfix", function()
    if not (_G.HarfordTRP3 and HarfordTRP3.RepairPlayerAboutSchema) then
        return API.Print("HarfordTRP3 no esta cargado")
    end
    local ok, detalle = HarfordTRP3.RepairPlayerAboutSchema()
    API.Print(ok and ("About del perfil activo: " .. tostring(detalle))
        or ("|cffff5555" .. tostring(detalle) .. "|r"))
    if ok then API.Print("Prueba a editar la ficha en TRP3; si sigue fallando, dilo.") end
end, "Completa T1/T3 del About del perfil TRP3 activo")

-- Mueve la seccion "Salvaciones" del panel de personaje para afinarla en juego. Sin argumento
-- solo informa. El valor es la Y de la barra respecto al TOP del panel (mas negativo = mas abajo).
-- Estado de la barra de experiencia del panel: si no se ve, esto dice si existe, donde esta y
-- con que valores, en vez de adivinar.
API.RegisterCommand("seccioncaract", function(args)
    local P = _G.HarfordCharacterPanel
    if not (P and P.SetAbilitySectionY) then
        return API.Print("abre el panel de personaje (/harford char)")
    end
    local y = tostring(args or ""):match("^%s*(-?%d+)%s*$")
    if not y then return API.Print("uso: seccioncaract <y>   (por defecto -84; el historico era -70)") end
    local ok, valor = P.SetAbilitySectionY(tonumber(y))
    if not ok then return API.Print("no se pudo mover") end
    if P.Refresh then P.Refresh() end
    API.Print(string.format("Caracteristicas en y=%d; Rasgos y su scroll bajan lo mismo (%+d)",
        valor, valor + 70))
end, "Sube/baja la seccion de Caracteristicas de la ficha y todo lo que va debajo")

API.RegisterCommand("contratorec", function()
    local TC = _G.HarfordContracts
    local db = TC and TC.GetDB and TC.GetDB()
    if not (db and type(db.contracts) == "table") then
        return API.Print("El tablon no esta cargado")
    end
    local R = TC.Rewards
    API.Print("contratos completados y su recompensa compartida:")
    local n = 0
    for _, c in ipairs(db.contracts) do
        if type(c) == "table" and c.status == "completed" then
            n = n + 1
            local tieneRep = (type(c.rewardReps) == "table" and #c.rewardReps > 0)
                or (type(c.rewardRep) == "table")
            API.Print(string.format("  |cffffd100%s|r", tostring(c.title or c.id)))
            API.Print(string.format("     xp=%s  rep=%s  worldNpc=%s",
                tostring(c.rewardXP), tostring(tieneRep), tostring(c.worldNpc)))
            if R then
                API.Print(string.format("     HasShared=%s  Cobrada=%s  Reclamable=%s",
                    tostring(R.HasShared and R.HasShared(c)),
                    tostring(R.IsSharedClaimed and R.IsSharedClaimed(c)),
                    tostring(R.IsSharedClaimable and R.IsSharedClaimable(c))))
            end
        end
    end
    if n == 0 then API.Print("   (ninguno completado)") end
end, "Por que sale o no el boton de cobrar recompensa de cada contrato completado")

API.RegisterCommand("aboutsync", function(args)
    local C = _G.HarfordCharacterCreation
    if not (C and C.SyncAboutAdditive) then return API.Print("HarfordCharacterCreation no cargado") end
    local aplicar = tostring(args or ""):lower():find("aplicar", 1, true) ~= nil

    if C.CanRewriteAbout then
        local propio, motivo = C.CanRewriteAbout()
        API.Print("About generado por Harford: " .. (propio
            and ("|cff38d26asi|r por " .. tostring(motivo) .. " (una subida lo REGENERA entero)")
            or "|cffffcc00no|r (una subida solo ANADE lo que falte)"))
    end

    local ok, detalle, informe = C.SyncAboutAdditive(nil, { dryRun = not aplicar })
    API.Print((ok and "" or "|cffff5555fallo:|r ") .. tostring(detalle or "?"))
    for _, l in ipairs(informe or {}) do API.Print("   " .. l) end
    if not aplicar and informe and #informe > 0 then
        API.Print("Para aplicarlo de verdad: |cffffd100aboutsync aplicar|r")
    end
end, "Simula (o aplica con 'aplicar') la actualizacion del About sin regenerarlo")

API.RegisterCommand("xpcapas", function(args)
    local P = _G.HarfordCharacterPanel
    local X = _G.HarfordCharacterXP
    local bar = P and P._sheetState and P._sheetState.xpBar
    if not (bar and X and X.SetBarLayer) then
        return API.Print("abre el panel de personaje (/harford char)")
    end
    local capa, estado = tostring(args or ""):match("^%s*(%a+)%s+(%a+)%s*$")
    if not capa then
        API.Print("uso: xpcapas <carril|tono|marco|fondo> <on|off>")
        for _, c in ipairs({ "carril", "tono", "marco", "fondo" }) do
            local tex = ({ carril = bar.harfordRail, tono = bar.harfordTone,
                marco = bar.harfordFrame, fondo = bar.harfordBg })[c]
            API.Print(string.format("   %-7s %s", c,
                tex and (tex:IsShown() and "|cff38d26aon|r" or "|cffff5555off|r") or "|cff888888no existe|r"))
        end
        return
    end
    local visible = (estado:lower() == "on")
    if not X.SetBarLayer(bar, capa:lower(), visible) then
        return API.Print("capa desconocida o no creada: " .. capa)
    end
    API.Print(string.format("capa %s -> %s", capa:lower(), visible and "on" or "off"))
end, "Enciende/apaga capas de la barra de XP del panel para ver cual sobra")

API.RegisterCommand("xpbarpanel", function(args)
    local P = _G.HarfordCharacterPanel
    local SH = P and P._sheetState
    local bar = SH and SH.xpBar
    if not bar then
        return API.Print("no encuentro la barra: abre el panel de personaje (/harford char)")
    end
    -- Con argumentos, recoloca: `xpbarpanel <y> [ancho] [alto] [x]`.
    local y, ancho, alto, x = tostring(args or ""):match("^%s*(-?%d+)%s*(%d*)%s*(%d*)%s*(-?%d*)%s*$")
    if y and P.SetXPBarPlacement then
        local ok, w, h, px, py = P.SetXPBarPlacement(tonumber(y), tonumber(ancho), tonumber(alto), tonumber(x))
        if ok then
            API.Print(string.format("barra movida: %.0fx%.0f en x=%s y=%s", w, h, tostring(px), tostring(py)))
            if P.Refresh then P.Refresh() end
        end
    end
    API.Print(string.format("barra: %.0fx%.0f  visible=%s  alpha=%.2f",
        bar:GetWidth(), bar:GetHeight(), tostring(bar:IsShown()), bar:GetAlpha()))
    local mn, mx = bar:GetMinMaxValues()
    API.Print(string.format("valor %.0f de %.0f-%.0f   tooltip: %s",
        bar:GetValue(), mn, mx, tostring(bar.tipTexto)))
    if _G.HarfordCharacterXP and HarfordCharacterXP.Progress then
        local n, a, b = HarfordCharacterXP.Progress()
        API.Print(string.format("XP: nivel %s, %s de %s", tostring(n), tostring(a), tostring(b)))
    else
        API.Print("|cffff5555HarfordCharacterXP no esta cargado|r")
    end
end, "Estado y recolocacion de la barra de XP del panel: xpbarpanel <y> [ancho] [alto]")

API.RegisterCommand("salvaciones", function(args)
    local P = _G.HarfordCharacterPanel
    if not (P and P.SetSavesSectionY) then
        return API.Print("abre el panel de personaje (/harford char) y repite")
    end
    local y = tonumber(tostring(args or ""):match("(-?%d+)"))
    local ok, actual = P.SetSavesSectionY(y)
    if not ok then return API.Print("el panel no esta construido todavia") end
    API.Print(string.format("Salvaciones en y=%d  (filas en %d, la banda de Atributos acaba en %d)",
        actual, actual - 37, actual + 2))
    if not y then
        API.Print("usa: /harford debug run salvaciones -230   (mas negativo = mas abajo)")
    else
        API.Print("cambia de pestana y vuelve a Atributos para verlo repintado")
    end
end, "Mueve la seccion de Salvaciones del panel para afinarla")

API.RegisterCommand("selectorhl", function()
    local P = _G.HarfordCharacterPanel
    local slots = P and P._slots
    if not slots then
        return API.Print("abre NUESTRO panel de personaje (/harford char) y repite")
    end
    local vistos = 0
    for _, hueco in ipairs(slots) do
        if hueco.basicSelector then
            vistos = vistos + 1
            local hx, hy = hueco:GetLeft(), hueco:GetTop()
            API.Print(string.format("|cffffd100hueco %d|r %.0fx%.0f", vistos,
                hueco:GetWidth(), hueco:GetHeight()))
            local fl = hueco.basicSelector
            API.Print(string.format("   flecha %.0fx%.0f, su izquierda a %+.1f del borde derecho",
                fl:GetWidth(), fl:GetHeight(),
                (fl:GetLeft() or 0) - ((hx or 0) + hueco:GetWidth())))
            -- Sin texCoords la textura sale entera y estirada (una banda, no una pestana).
            local nt = fl.GetNormalTexture and fl:GetNormalTexture()
            if nt and nt.GetTexCoord then
                local c = { nt:GetTexCoord() }
                local partes = {}
                for _, v in ipairs(c) do partes[#partes + 1] = string.format("%.3f", v) end
                API.Print("   texCoords: " .. table.concat(partes, " "))
                if #c == 8 and c[1] == 0 and c[2] == 0 and c[3] == 0 and c[4] == 1 then
                    API.Print("   |cffff5555SIN recorte: sale la textura entera|r")
                end
            else
                API.Print("   |cffff5555no puedo leer la textura de la flecha|r")
            end
            for _, r in ipairs({ hueco:GetRegions() }) do
                if r.GetTexture and tostring(r:GetTexture() or ""):find("GearManager") then
                    local rx, ry = r:GetLeft(), r:GetTop()
                    API.Print(string.format("   resaltado %.0fx%.0f", r:GetWidth(), r:GetHeight()))
                    if hx and rx and hy and ry then
                        API.Print(string.format("   |cff40c040desvio del centro: %+.1f en x, %+.1f en y|r",
                            (rx + r:GetWidth() / 2) - (hx + hueco:GetWidth() / 2),
                            (ry - r:GetHeight() / 2) - (hy - hueco:GetHeight() / 2)))
                    else
                        API.Print("   |cffff5555sin posicion: el hueco esta oculto|r")
                    end
                end
            end
        end
    end
    if vistos == 0 then API.Print("ningun hueco tiene selector (Pecho / manos)") end
end, "Mide el resaltado del selector contra su hueco")

API.RegisterCommand("razasiconos", function()
    local C = _G.HarfordCharacterCreation
    if not (C and C.GetAllOriginIcons) then return API.Print("HarfordCharacterCreation no esta cargado") end
    local sep = string.char(92)
    local ok, faltan = 0, {}
    for _, fila in ipairs(C.GetAllOriginIcons()) do
        local raceId, subId, icon = fila[1], fila[2], fila[3]
        local ruta = "Interface" .. sep .. "Icons" .. sep .. icon
        -- Muchos son iconos custom de Epsilon (eps_wc3h_*, dwarf_m, forsaken_m...): no se puede
        -- dar por hecho que existan solo porque la web los declare.
        if GetFileIDFromPath and GetFileIDFromPath(ruta) then
            ok = ok + 1
        else
            faltan[#faltan + 1] = raceId .. (subId and ("/" .. subId) or "") .. "  ->  " .. icon
        end
    end
    API.Print(string.format("iconos de origen: %d resuelven, %d SIN resolver", ok, #faltan))
    for _, l in ipairs(faltan) do API.Print("   |cffff5555NO EXISTE|r " .. l) end
    if #faltan == 0 then API.Print("   todos correctos") end
end, "Comprueba que los iconos de raza/subraza existen en este cliente")

API.RegisterCommand("armasiconos", function()
    local W = _G.HarfordDnDWeapons
    if not (W and W.WEAPONS) then return API.Print("HarfordDnDWeapons no esta cargado") end
    local ok, faltan, sinCampo = 0, {}, {}
    for _, w in ipairs(W.WEAPONS) do
        if not w.icon or w.icon == "" then
            sinCampo[#sinCampo + 1] = w.key
        else
            -- Se pregunta al MISMO resolutor que usa el juego, no a GetFileIDFromPath a pelo:
            -- si LibRPMedia encuentra el nombre, devuelve un fileID y la ruta directa no
            -- importa. Un icono que no se pudo resolver acaba en el interrogante.
            local resuelto = W.GetIconPath(w)
            if resuelto == "Interface\\Icons\\INV_Misc_QuestionMark" then
                faltan[#faltan + 1] = w.key .. "  ->  " .. w.icon
            else
                ok = ok + 1
            end
        end
    end
    API.Print(string.format("iconos de arma: %d resuelven, %d SIN resolver, %d sin campo",
        ok, #faltan, #sinCampo))
    for _, l in ipairs(faltan) do API.Print("   |cffff5555NO EXISTE|r " .. l) end
    for _, l in ipairs(sinCampo) do API.Print("   |cffffcc00sin icono|r " .. l) end
    if #faltan == 0 and #sinCampo == 0 then API.Print("   todos correctos") end
end, "Comprueba que los iconos de arma existen en este cliente")

API.RegisterCommand("profsonido", function(args)
    local prof = tostring(args or ""):match("^%s*(%S+)") or ""
    local FX = _G.HarfordProfessionFX
    if not FX then return API.Print("HarfordProfessionFX no esta cargado") end
    if prof == "" or not FX.PERFILES[prof] then
        local ids = {}
        for k, v in pairs(FX.PERFILES) do
            ids[#ids + 1] = string.format("%s (sonido %d%s)", k, v.sonido or 0,
                v.sonidoExito and (", remate " .. v.sonidoExito) or "")
        end
        table.sort(ids)
        API.Print("Uso: /harford debug run profsonido <profesion>")
        for _, l in ipairs(ids) do API.Print("   " .. l) end
        return
    end
    local perfil = FX.PERFILES[prof]
    API.Print(string.format("%s: sonido %d en bucle por evento durante 5s%s",
        prof, perfil.sonido or 0,
        perfil.sonidoExito and (", y " .. perfil.sonidoExito .. " al lograrlo") or ""))
    local estado = FX.Begin(prof, nil)
    -- Un unico aviso diferido para cerrar la prueba; no hay tick de por medio.
    C_Timer.After(5, function()
        FX.Finish(estado, true)
        FX.Stop(estado)
        API.Print("fin: el bucle se corto aqui")
    end)
end, "Oye el bucle de sonido de una profesion tal cual suena al fabricar")

API.RegisterCommand("casttex", function()
    local RUTAS = {
        "Interface\\CastingBar\\UI-CastingBar-Fill",
        "Interface\\CastingBar\\UI-CastingBar-Border",
        "Interface\\CastingBar\\UI-CastingBar-Spark",
        "Interface\\CastingBar\\UI-CastingBar-Flash",
        "Interface\\TargetingFrame\\UI-StatusBar",
        "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
        "Interface\\AddOns\\SpellCreator\\assets\\castingbar-fill",
    }
    Print("Texturas de barra en este cliente:")
    for _, ruta in ipairs(RUTAS) do
        local id = GetFileIDFromPath and GetFileIDFromPath(ruta) or nil
        Print(string.format("  %s %s%s", id and "|cff55ff55si |r" or "|cffff5555NO |r", ruta,
            id and ("  |cff808080id " .. id .. "|r") or ""))
    end
    Print("La barra usa la primera que resuelva; si ninguna, color solido.")
end, "que texturas de barra de lanzamiento existen en este cliente")

HarfordDebug.RegisterCommand("golpeheroico", function()
    local def = HarfordDnDStore and HarfordDnDStore.GetWeaponDef
        and HarfordDnDStore.GetWeaponDef(HarfordDnDStore.GetWeaponKey and HarfordDnDStore.GetWeaponKey())
    if not def then
        Print("No hay arma seleccionada en la ficha.")
        return
    end
    local dados = 0
    if def.mode == "Melee" and HarfordDnDWeapons and HarfordDnDWeapons.WeaponBaseDice then
        dados = tonumber(HarfordDnDWeapons.ParseDice(HarfordDnDWeapons.WeaponBaseDice(def))) or 0
    end
    local rage = HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.GetResourceCurrent("rage")
    Print(string.format("Arma %s (%s)  dados base %d", tostring(def.key), tostring(def.mode), dados))
    Print("Puntos de ira: " .. tostring(rage or "?"))
    Print("Puntos que ofrecera el menu: " .. tostring(math.min(dados, tonumber(rage) or 0))
        .. "  (limite = dados del arma y ira disponible)")
    if def.mode ~= "Melee" then
        Print("|cffff5555Golpe heroico solo aplica a cuerpo a cuerpo.|r")
    end
end, "por que Golpe heroico ofrece (o no) puntos con el arma actual")

-- ICONOSCHECK: comprueba que cada icono declarado EXISTE en el cliente de Epsilon.
--
-- Motivo (AGENTS.md): hay texturas de retail que Epsilon no tiene y salen en verde o como
-- interrogacion. El catalogo se importa de la web, que no sabe que tiene este cliente, asi que
-- la unica forma de saberlo es preguntarselo al cliente con `GetFileIDFromPath`.
--
--   /harford debug run iconoscheck            resumen + los que faltan
--   /harford debug run iconoscheck todo       ademas lista los que si existen
--   /harford debug run iconoscheck <texto>    solo los que contengan ese texto
do
    local PREFIJO = "Interface" .. string.char(92) .. "Icons" .. string.char(92)

    local function Existe(nombre)
        nombre = tostring(nombre or "")
        if nombre == "" then return false end
        -- Un icono puede venir ya como ruta completa o como id numerico de textura.
        if tonumber(nombre) then return true end
        -- `spell:<id>` es una forma VALIDA que resuelve HarfordCompendioIconMap con
        -- GetSpellTexture; sin este caso el validador la daba por rota.
        local spellId = nombre:match("^spell:(%d+)$")
        if spellId then
            local tex = GetSpellTexture and GetSpellTexture(tonumber(spellId))
            return tex ~= nil and tex ~= 0
        end
        local ruta = nombre:find(string.char(92), 1, true) and nombre or (PREFIJO .. nombre)
        if GetFileIDFromPath then
            local id = GetFileIDFromPath(ruta)
            if id and id ~= 0 then return true end
        end
        return false
    end

    -- Recorre las tres tablas del catalogo mas el arte de origen, que vive aparte.
    local function Recolecta()
        local out, vistos = {}, {}
        local function anota(origen, clave, icono)
            if not icono or icono == "" then return end
            local firma = tostring(origen) .. "|" .. tostring(clave) .. "|" .. tostring(icono)
            if vistos[firma] then return end
            vistos[firma] = true
            out[#out + 1] = { origen = origen, clave = clave, icono = icono }
        end

        local C = _G.HarfordIconCatalog
        if C then
            for id, icono in pairs(C.features or {}) do anota("rasgo", id, icono) end
            for id, cands in pairs(C.spells or {}) do
                if type(cands) == "table" then
                    for i, icono in ipairs(cands) do
                        anota("conjuro" .. (i > 1 and (" alt" .. i) or ""), id, icono)
                    end
                else
                    anota("conjuro", id, cands)
                end
            end
            for clase, subs in pairs(C.subclasses or {}) do
                for sub, icono in pairs(subs or {}) do
                    anota("subclase", tostring(clase) .. "/" .. tostring(sub), icono)
                end
            end
            for nombre, icono in pairs(C.names or {}) do anota("por nombre", nombre, icono) end
        end

        -- Arte de origen: no esta en el catalogo, tiene tablas propias por sexo.
        local Cre = _G.HarfordCharacterCreation
        if Cre and Cre.GetAllOriginIcons then
            for _, par in ipairs(Cre.GetAllOriginIcons()) do
                local clave = tostring(par[1]) .. (par[2] and ("/" .. tostring(par[2])) or "")
                anota("origen", clave, par[3])
            end
        end
        return out
    end

    HarfordDebug.RegisterCommand("iconoscheck", function(args)
        if not GetFileIDFromPath then
            Print("|cffff5555GetFileIDFromPath no existe en este cliente: no se puede validar.|r")
            return
        end
        local filtro = tostring(args or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local listarTodo = filtro == "todo"
        if listarTodo then filtro = "" end

        local entradas = Recolecta()
        local total, faltan, porOrigen = 0, {}, {}
        for _, e in ipairs(entradas) do
            local pasa = filtro == ""
                or tostring(e.clave):lower():find(filtro, 1, true)
                or tostring(e.icono):lower():find(filtro, 1, true)
            if pasa then
                total = total + 1
                if not Existe(e.icono) then
                    faltan[#faltan + 1] = e
                    porOrigen[e.origen] = (porOrigen[e.origen] or 0) + 1
                elseif listarTodo then
                    Print(string.format("|cff44ff44ok|r   %-10s %-32s %s", e.origen, e.clave, e.icono))
                end
            end
        end

        Print(string.format("Iconos comprobados: |cffffd100%d|r  -  faltan en el cliente: %s%d|r",
            total, #faltan > 0 and "|cffff5555" or "|cff44ff44", #faltan))
        if #faltan == 0 then return end

        -- Se agrupan por icono: un mismo nombre roto suele estar en varios rasgos y no aporta
        -- repetirlo veinte veces.
        local porIcono = {}
        for _, e in ipairs(faltan) do
            porIcono[e.icono] = porIcono[e.icono] or {}
            local lista = porIcono[e.icono]
            lista[#lista + 1] = e.origen .. " " .. e.clave
        end
        local nombres = {}
        for icono in pairs(porIcono) do nombres[#nombres + 1] = icono end
        table.sort(nombres)
        Print("Texturas que este cliente NO tiene (" .. #nombres .. " distintas):")
        for _, icono in ipairs(nombres) do
            local usos = porIcono[icono]
            local muestra = usos[1]
            if #usos > 1 then muestra = muestra .. "  (+" .. (#usos - 1) .. " mas)" end
            Print(string.format("  |cffff5555%-42s|r %s", icono, muestra))
        end
        local resumen = {}
        for origen, n in pairs(porOrigen) do resumen[#resumen + 1] = origen .. "=" .. n end
        table.sort(resumen)
        Print("Por origen: " .. table.concat(resumen, ", "))
    end, "comprueba que cada icono del catalogo existe en el cliente (iconoscheck [todo|texto])")
end

-- Economia de turno: estado de accion/adicional/reaccion y que rasgos declaran su coste.
do
    API.RegisterCommand("turnecon", function(args)
        local T = HarfordDnDConditions and HarfordDnDConditions.Turn
        if not T then Print("HarfordDnDConditions.Turn no esta cargado.") return end
        local arg = tostring(args or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

        if arg == "reset" then
            T.Reset()
            Print("Economia de turno reiniciada.")
            return
        end

        if arg == "rasgos" then
            -- Cuantos rasgos declaran su coste, que es lo que limita el sistema.
            local total, conCoste, porTipo = 0, 0, {}
            local function Contar(lista)
                for _, feature in ipairs(lista or {}) do
                    total = total + 1
                    local kind = T.KindFromFeature(feature)
                    if kind then
                        conCoste = conCoste + 1
                        porTipo[kind] = (porTipo[kind] or 0) + 1
                    end
                end
            end
            for _, classDef in ipairs((HarfordDnDBook and HarfordDnDBook.GetClasses
                and HarfordDnDBook.GetClasses()) or {}) do
                Contar(classDef.features)
                for _, sub in ipairs(classDef.subclasses or {}) do
                    Contar(sub.features)
                end
            end
            Print(string.format("Rasgos: %d; declaran coste: %d", total, conCoste))
            for _, kind in ipairs(T.ORDEN) do
                Print(string.format("  %-10s %d", T.ETIQUETA[kind], porTipo[kind] or 0))
            end
            return
        end

        Print("Orden de turnos activo: " .. (T.IsActive() and "si" or "no"))
        if not T.IsActive() then
            Print("Sin orden de turnos no se lleva la cuenta (los contadores quedan inactivos).")
        end
        for _, kind in ipairs(T.ORDEN) do
            Print(string.format("  %-10s %d/%d  (gastado %d)", T.ETIQUETA[kind],
                T.GetRemaining(kind), T.GetBudget(kind), T.GetSpent(kind)))
        end
        Print("Uso: turnecon [reset|rasgos]")
    end, "estado de la economia de turno (turnecon [reset|rasgos])")
end

-- ─── PRUEBA DE CHOMP ────────────────────────────────────────────────────────
-- Chomp (LibMSP, lo trae TotalRP3) ofrece tres cosas que `SendAddonMessage` crudo no da: aviso de
-- entrega por callback, colas con prioridad y control de ancho de banda, y `BNSendGameData`, que
-- cruza personaje y realm sin necesidad de grupo y admite 4078 bytes en vez de 255.
--
-- Antes de plantear adoptarlo hay que medirlo AQUI, en Epsilon, no fiarse de que la API exista.
-- La pregunta que lo decide todo es la tercera: si el formato de cable es compatible con lo que ya
-- enviamos. Chomp antepone una cabecera de 12 hex (bitField, sesion, id, total) y DESCARTA en
-- silencio cualquier mensaje que no la traiga (`if not hasVersion16 then return end`). Si eso se
-- confirma, Chomp no se puede adoptar de forma incremental sobre `DND5EARC`: el dia que se active,
-- todo cliente sin actualizar deja de recibir, y sin error que lo delate.
do
    local PREFIJO = "HARFCHOMP"
    local recibidor          -- frame propio para ver el cable EN CRUDO
    local registrado = false
    local ultimo = {}        -- lo ultimo visto por cada via, para poder compararlas

    local function Lib()
        return _G.AddOn_Chomp
    end

    -- Lo que llega por la via de Chomp: ya sin cabecera y reensamblado.
    local function AlLlegarPorChomp(prefix, texto, canal, emisor)
        ultimo.chomp = { texto = texto, canal = canal, emisor = emisor }
        Print(string.format("|cff88ff88CHOMP recibe|r [%s] de %s: %s",
            tostring(canal), tostring(emisor), tostring(texto)))
    end

    -- Lo que llega por el evento pelado: el cable tal cual, con cabecera si la trae. Es lo que
    -- permite ver cuanto ocupa esa cabecera y si nuestro receptor de hoy sabria leerlo.
    local function AlLlegarEnCrudo(_, _, prefix, texto, canal, emisor)
        if prefix ~= PREFIJO then return end
        ultimo.crudo = { texto = texto, canal = canal, emisor = emisor }
        local cabecera = tostring(texto):match("^(%x%x%x%x%x%x%x%x%x%x%x%x)")
        Print(string.format("|cffffcc00CRUDO recibe|r [%s] de %s: %d bytes%s",
            tostring(canal), tostring(emisor), #tostring(texto),
            cabecera and (" (cabecera Chomp " .. cabecera .. ")") or " (sin cabecera Chomp)"))
    end

    local function Registrar()
        local C = Lib()
        if not C then return false end
        if registrado then return true end
        if not C.IsAddonPrefixRegistered(PREFIJO) then
            local ok, err = pcall(C.RegisterAddonPrefix, PREFIJO, AlLlegarPorChomp)
            if not ok then Print("no se pudo registrar el prefijo en Chomp: " .. tostring(err)) end
        end
        if not recibidor then
            recibidor = CreateFrame("Frame")
            recibidor:RegisterEvent("CHAT_MSG_ADDON")
            recibidor:SetScript("OnEvent", AlLlegarEnCrudo)
        end
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIJO)
        end
        registrado = true
        return true
    end

    -- A quien se le manda. Por defecto a UNO MISMO: el susurro a si mismo funciona para addon
    -- messages, asi que la prueba se puede hacer con un solo cliente. Con un jugador en target o
    -- un nombre por argumento, se prueba de verdad entre dos.
    local function Destino(args)
        local nombre = args and args:match("^%s*(%S+)%s*$")
        if nombre and nombre ~= "" then return nombre end
        if UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
            return GetUnitName and GetUnitName("target", true) or UnitName("target")
        end
        return GetUnitName and GetUnitName("player", true) or (UnitName and UnitName("player"))
    end

    local function Informe()
        local C = Lib()
        Print("--- Disponibilidad ---")
        Print("  AddOn_Chomp: " .. (C and "si" or "NO -- mira si TotalRP3 esta cargado"))
        if not C then return end
        Print("  version: " .. tostring(C.GetVersion and C.GetVersion() or "?"))
        local bps, rafaga
        if C.GetBPS then bps, rafaga = C.GetBPS() end
        Print(string.format("  ancho de banda: %s bps, rafaga %s", tostring(bps), tostring(rafaga)))
        Print("  ChatThrottleLib presente: " .. (_G.ChatThrottleLib and "si" or "no"))
        Print("--- Battle.net ---")
        Print("  BNSendGameData existe: " .. (_G.BNSendGameData and "si" or "NO"))
        local alcanzables = 0
        if BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
            for i = 1, BNGetNumFriends() do
                local info = C_BattleNet.GetFriendAccountInfo(i)
                local juego = info and info.gameAccountInfo
                -- Solo sirve una cuenta de JUEGO conectada a WoW: el resto no puede recibir datos.
                if juego and juego.isOnline and juego.clientProgram == "WoW" and juego.gameAccountID then
                    alcanzables = alcanzables + 1
                end
            end
        end
        Print("  cuentas de juego WoW alcanzables: " .. alcanzables)
        Print("--- Limites ---")
        Print("  SendAddonMessage: 255 bytes; BNSendGameData: 4078 (16 veces mas)")
        Print("Usa: chomp enviar [nombre] | chomp ctl | chomp bn | chomp limite | chomp crudo")
    end

    -- El experimento que decide: mandar lo MISMO por las dos vias y ver que llega por donde.
    local function Enviar(args)
        local C = Lib()
        if not C then Print("Chomp no disponible.") return end
        if not Registrar() then return end
        local destino = Destino(args)
        local carga = "prueba|" .. tostring(GetTime and math.floor(GetTime()) or 0)
        Print("Destino: " .. tostring(destino) .. "  carga: " .. carga .. " (" .. #carga .. " bytes)")

        -- Via Chomp, con callback de entrega. El callback recibe (callbackArg, salio).
        local ok, err = pcall(C.SendAddonMessage, PREFIJO, carga, "WHISPER", destino, "HIGH", nil,
            function(arg, salio)
                Print("|cff88ff88callback de Chomp|r: salio=" .. tostring(salio)
                    .. " (" .. tostring(arg) .. ")")
            end, "envio1")
        Print("  Chomp acepto el envio: " .. (ok and "si" or ("NO -- " .. tostring(err))))

        -- Via cruda, la de hoy. Sin callback: solo se sabe que la llamada no reventó.
        local ok2 = HarfordSync and HarfordSync.Send
            and HarfordSync.Send(PREFIJO, carga, "WHISPER", destino)
        Print("  crudo acepto el envio: " .. tostring(ok2)
            .. " (sin callback no hay forma de saber si salio)")
        Print("Mira las lineas de recepcion. Si el mensaje CRUDO no sale como 'CHOMP recibe',")
        Print("los dos formatos son incompatibles y Chomp no se puede adoptar a medias.")
    end

    -- El limite de tamano: Chomp lanza error DURO al pasarse; el crudo lo descarta sin decir nada.
    -- Es justo el fallo silencioso que costo encontrar en las tiradas largas.
    local function Limite(args)
        local C = Lib()
        if not C then Print("Chomp no disponible.") return end
        if not Registrar() then return end
        local destino = Destino(args)
        local gordo = string.rep("X", 300)
        Print("Enviando 300 bytes, cuando el limite son 255...")
        local ok, err = pcall(C.SendAddonMessage, PREFIJO, gordo, "WHISPER", destino)
        Print("  Chomp: " .. (ok and "lo acepto, que no deberia" or ("lo rechazo -- " .. tostring(err))))
        local ok2, res = pcall(function()
            return C_ChatInfo.SendAddonMessage(PREFIJO, gordo, "WHISPER", destino)
        end)
        Print("  crudo: " .. (ok2 and ("devolvio " .. tostring(res) .. " y lo descarta en silencio")
            or ("error -- " .. tostring(res))))
    end

    local function BattleNet(args)
        local C = Lib()
        if not C then Print("Chomp no disponible.") return end
        if not _G.BNSendGameData then Print("BNSendGameData no existe en este cliente.") return end
        if not Registrar() then return end
        if not (BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo) then
            Print("API de Battle.net no disponible.")
            return
        end
        local enviados = 0
        for i = 1, BNGetNumFriends() do
            local info = C_BattleNet.GetFriendAccountInfo(i)
            local juego = info and info.gameAccountInfo
            if juego and juego.isOnline and juego.clientProgram == "WoW" and juego.gameAccountID then
                local nombre = tostring(juego.characterName or info.accountName or "?")
                local ok, err = pcall(C.BNSendGameData, juego.gameAccountID, PREFIJO,
                    "prueba bn|" .. tostring(GetTime and math.floor(GetTime()) or 0), "HIGH", nil,
                    function(arg, salio)
                        Print("|cff88ff88callback BN|r (" .. tostring(arg) .. "): salio=" .. tostring(salio))
                    end, nombre)
                Print(string.format("  -> %s (%s): %s", nombre, tostring(juego.gameAccountID),
                    ok and "aceptado" or ("ERROR " .. tostring(err))))
                enviados = enviados + 1
            end
        end
        if enviados == 0 then
            Print("Ningun amigo de Battle.net con WoW abierto. Sin destinatario no se puede probar.")
        end
    end

    -- ChatThrottleLib, que ya esta cargado en Epsilon (lo trae AceComm, y Chomp le DELEGA cuando
    -- lo encuentra). Da callback de entrega, colas con prioridad y control de ancho de banda
    -- IGUAL que Chomp, pero envia el texto TAL CUAL por `C_ChatInfo.SendAddonMessage`: sin
    -- cabecera, sin formato propio. Si eso se confirma aqui, es la via a adoptar, porque da lo que
    -- buscabamos sin romper a ningun cliente antiguo.
    local function CTL(args)
        local L = _G.ChatThrottleLib
        if not L then Print("ChatThrottleLib no disponible.") return end
        if not Registrar() then
            -- Sin Chomp no hay callback suyo, pero el receptor crudo si se puede montar.
            if not recibidor then
                recibidor = CreateFrame("Frame")
                recibidor:RegisterEvent("CHAT_MSG_ADDON")
                recibidor:SetScript("OnEvent", AlLlegarEnCrudo)
            end
            if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
                C_ChatInfo.RegisterAddonMessagePrefix(PREFIJO)
            end
        end
        Print("version de CTL: " .. tostring(L.version))
        local destino = Destino(args)
        local carga = "prueba ctl|" .. tostring(GetTime and math.floor(GetTime()) or 0)
        Print("Destino: " .. tostring(destino) .. "  carga: " .. carga .. " (" .. #carga .. " bytes)")
        -- El callback recibe (callbackArg, salio, resultado): tambien el valor que devolvio el
        -- envio, que es mas de lo que da Chomp.
        local ok, err = pcall(L.SendAddonMessage, L, "ALERT", PREFIJO, carga, "WHISPER", destino,
            nil, function(arg, salio, resultado)
                Print("|cff88ff88callback de CTL|r: salio=" .. tostring(salio)
                    .. " resultado=" .. tostring(resultado) .. " (" .. tostring(arg) .. ")")
            end, "envioctl")
        Print("  CTL acepto el envio: " .. (ok and "si" or ("NO -- " .. tostring(err))))
        Print("Si la linea CRUDO sale SIN cabecera Chomp, CTL no toca el formato: se puede adoptar")
        Print("sin romper a nadie. Prueba tambien el limite:")
        local gordo = string.rep("X", 300)
        local ok2, err2 = pcall(L.SendAddonMessage, L, "BULK", PREFIJO, gordo, "WHISPER", destino)
        Print("  300 bytes -> " .. (ok2 and "los acepto, que no deberia"
            or ("los rechazo con error -- " .. tostring(err2))))
    end

    local function Crudo()
        Print("Ultimo por Chomp: " .. (ultimo.chomp
            and (tostring(ultimo.chomp.texto) .. "  [" .. tostring(ultimo.chomp.canal) .. "]")
            or "nada"))
        Print("Ultimo en crudo:  " .. (ultimo.crudo
            and (#tostring(ultimo.crudo.texto) .. " bytes  [" .. tostring(ultimo.crudo.canal) .. "]")
            or "nada"))
        if ultimo.chomp and ultimo.crudo then
            local extra = #tostring(ultimo.crudo.texto) - #tostring(ultimo.chomp.texto)
            Print("Diferencia de tamano, que es la cabecera de Chomp: " .. extra .. " bytes")
        end
    end

    API.RegisterCommand("chomp", function(args)
        args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local sub, resto = args:match("^(%S+)%s*(.*)$")
        sub = sub and sub:lower() or ""
        if sub == "enviar" then return Enviar(resto) end
        if sub == "bn" then return BattleNet(resto) end
        if sub == "limite" then return Limite(resto) end
        if sub == "ctl" then return CTL(resto) end
        if sub == "crudo" then return Crudo() end
        Informe()
    end, "mide Chomp y CTL frente a SendAddonMessage (chomp [enviar|ctl|bn|limite|crudo])")
end

-- ─── FICHA RAPIDA DE NIVEL 6 ────────────────────────────────────────────────
-- Montar a mano una ficha de nivel 6 para probar algo son doce pasos por el asistente, y hay DOCE
-- clases. Esto la deja hecha de un comando, y `todas` recorre las doce seguidas informando de lo
-- que sale: es la unica forma practica de ver de un vistazo que las doce se montan sin romperse y
-- cuantas elecciones deja cada una sin resolver.
--
-- DESTRUYE la ficha actual. Por eso guarda copia ANTES de tocar nada, y la copia se persiste: si
-- solo viviera en memoria, un /reload en medio se llevaria por delante el personaje de verdad.
do
    local NIVEL = 6
    local Limpiar, Refrescar   -- se asignan mas abajo; `Restaurar` cierra sobre ellas

    local function Prog() return _G.HarfordDnDProgression end
    local function Libro() return _G.HarfordDnDBook end

    local function Clases()
        local L = Libro()
        if not (L and L.GetClasses) then return {} end
        return L.GetClasses() or {}
    end

    -- Copia de seguridad, persistida. Solo se toma la PRIMERA vez: si se encadenan varias fichas
    -- de prueba, la copia buena sigue siendo la del personaje real, no la de la prueba anterior.
    local function Guardar()
        HarfordDebugSettings = HarfordDebugSettings or {}
        if HarfordDebugSettings.fichaPrevia then return false end
        local P = Prog()
        if not (P and P.Get) then return false end
        local datos = P.Get()
        local copia = {}
        local function Copiar(t)
            local out = {}
            for k, v in pairs(t or {}) do
                out[k] = (type(v) == "table") and Copiar(v) or v
            end
            return out
        end
        copia = Copiar(datos)
        HarfordDebugSettings.fichaPrevia = {
            datos = copia,
            perfil = (UnitName and UnitName("player")) or "?",
            cuando = (date and date("%d/%m %H:%M")) or "?",
        }
        return true
    end

    local function Restaurar()
        local guardada = HarfordDebugSettings and HarfordDebugSettings.fichaPrevia
        if not guardada then
            Print("No hay copia guardada. La ficha actual se queda como esta.")
            return
        end
        local P = Prog()
        if not (P and P.Set) then Print("HarfordDnDProgression no disponible") return end
        P.Set(nil, guardada.datos)
        HarfordDebugSettings.fichaPrevia = nil
        Print("Ficha restaurada a la copia de " .. tostring(guardada.cuando)
            .. " (" .. tostring(guardada.perfil) .. ").")
        Refrescar()
    end

    -- Borra lo que la clase anterior dejo puesto. NO se tocan raza ni trasfondo: no son de la
    -- clase, y rehacerlos en cada prueba obligaria a volver a elegirlos por nada.
    Limpiar = function()
        local P = Prog()
        if not (P and P.Get) then return end
        local datos = P.Get()
        datos.classLevels = {}
        -- Elecciones, usos y espacios: todos apuntan a rasgos de la clase que se va.
        datos.choices = {}
        datos.featureStates = {}
        datos.activeStates = {}
        datos.spellSlots = {}
        datos.spellSlotsBonus = {}
        -- Las dotes tambien: una dote de la prueba anterior seguia aplicando sus rasgos sobre un
        -- personaje que ya no la tiene, y no hay nada en pantalla que lo delate.
        datos.feats = {}
        -- Los dados de golpe y los usos por descanso viven en el perfil, no en la progresion.
        -- El origen tambien: una raza que se queda de la prueba anterior deja sus rasgos y sus
        -- bonos sumandose a los de la nueva.
        if P.SetRace then P.SetRace(nil, nil) end
        if P.SetBackground then P.SetBackground(nil) end
        if P.SetBackgroundVariant then P.SetBackgroundVariant(nil) end
        local perfiles = _G.HarfordDnDPersistStore and _G.HarfordDnDPersistStore.profiles
        local nombre = (UnitName and UnitName("player")) or ""
        local slot = perfiles and perfiles[nombre]
        if slot then
            slot._hitDice = nil
            slot._featureUses = nil
        end
    end

    -- Que la ficha cambie SIN /reload. Cada panel abierto tiene que enterarse: si no, se sigue
    -- viendo la clase anterior y parece que el comando no ha hecho nada.
    Refrescar = function()
        if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
            HarfordDnDFeatureEffects.Invalidate()
        end
        if HarfordDnDStore and HarfordDnDStore.ReconcileDerivedResources then
            HarfordDnDStore.ReconcileDerivedResources(nil, "debug ficha6")
        end
        if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
        if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then _G.DND5E_ARC_API.Refresh() end
        if HarfordCharacterPanel then
            if HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
            if HarfordCharacterPanel.RefreshBookIfShown then HarfordCharacterPanel.RefreshBookIfShown() end
        end
    end

    -- Rellena las elecciones pendientes, AL AZAR entre las opciones validas. Sin esto la ficha
    -- llega al 6 con entre 4 y 10 decisiones a medias -- estilo de combate, maniobras, pericias,
    -- mejoras de caracteristica -- y hay que terminarla a mano cada vez que se cambia de clase,
    -- que es justo lo que el comando venia a evitar.
    --
    -- Un hueco YA elegido no se toca: si vuelves a montar la misma clase tras cambiar algo a mano,
    -- tu eleccion se queda.
    local function RellenarElecciones()
        local P, L = Prog(), Libro()
        if not (P and L and P.SetChoiceSlot) then return 0, 0 end
        local puestas, sinOpciones = 0, 0

        -- Rasgos de clase, de raza y de trasfondo, todos por la misma puerta: los tres guardan sus
        -- elecciones en `choices` y los tres se quedarian a medias si solo se mirara la clase.
        local aRellenar = {}
        for _, item in ipairs(L.GetUnlockedFeatures(P.GetClassLevels()) or {}) do
            aRellenar[#aRellenar + 1] = item.feature
        end
        local R = _G.HarfordDnDRaces
        if R and R.GetRaceTraits then
            local raza, subraza = P.GetRace()
            for _, item in ipairs(R.GetRaceTraits(raza, subraza) or {}) do
                aRellenar[#aRellenar + 1] = item.feature or item
            end
        end
        local B = _G.HarfordDnDBackgrounds
        if B and B.GetBackgroundTraits then
            for _, item in ipairs(B.GetBackgroundTraits(P.GetBackground()) or {}) do
                aRellenar[#aRellenar + 1] = item.feature or item
            end
        end

        for _, f in ipairs(aRellenar) do
            -- `GetChoiceOptions`, no `choice.options` en crudo: las elecciones dinamicas
            -- -- Mejora de Caracteristica, Pericia, trucos -- no declaran su lista, la generan
            -- desde los datos. Leyendo el campo pelado se quedaban 18 sin rellenar, 12 de ellas
            -- la misma Mejora de Caracteristica.
            local opciones = (f and f.choice and L.GetChoiceOptions) and L.GetChoiceOptions(f) or nil
            local huecos = (f and f.choice) and L.GetChoiceSlots(f) or 0
            if huecos > 0 then
                if type(opciones) ~= "table" or #opciones == 0 then
                    -- Una eleccion sin opciones no se puede rellenar sola. Se cuenta para poder
                    -- decirlo en vez de dejar creer que la ficha quedo completa.
                    sinOpciones = sinOpciones + 1
                else
                    local yaPuestas = {}
                    local actuales = P.GetChoice and P.GetChoice(f.id) or {}
                    for _, v in ipairs(actuales) do yaPuestas[tostring(v)] = true end
                    for hueco = 1, huecos do
                        local datos = P.Get()
                        local ocupado = datos.choices[f.id] and datos.choices[f.id][hueco]
                        if not (ocupado and ocupado ~= "") then
                            -- AL AZAR entre las que quedan, no siempre la primera: montar la misma
                            -- clase dos veces prueba combinaciones distintas, y elegir siempre la
                            -- primera dejaria el resto de opciones sin pisar nunca.
                            --
                            -- Sin repetir dentro de la misma eleccion: dos huecos con la misma
                            -- opcion serian una maniobra aprendida dos veces y una pericia tirada.
                            local libres = {}
                            for _, o in ipairs(opciones) do
                                if o.id and not yaPuestas[tostring(o.id)] then
                                    libres[#libres + 1] = o
                                end
                            end
                            local elegida = (#libres > 0) and libres[math.random(#libres)] or nil
                            if elegida then
                                P.SetChoiceSlot(f.id, hueco, elegida.id)
                                -- Una DOTE no se aplica con la eleccion: su opcion no lleva
                                -- `effects`, lo que aplica son los rasgos de la dote via
                                -- `progression.feats`. Sin esto se elegia la dote en la Mejora de
                                -- Caracteristica y luego no salia en el Libro, porque `feats`
                                -- seguia vacio. Es lo mismo que hace el asistente de subida.
                                if elegida.feat and P.SetFeatEnabled then
                                    P.SetFeatEnabled(elegida.feat, true)
                                end
                                -- Y un truco elegido se concede aparte, por el mismo motivo.
                                if elegida.spellId and type(_G.HarfordCompendioCharacterDB) == "table" then
                                    local db = _G.HarfordCompendioCharacterDB
                                    db.knownSpells = db.knownSpells or {}
                                    db.knownSpells[elegida.spellId] = true
                                end
                                yaPuestas[tostring(elegida.id)] = true
                                puestas = puestas + 1
                            end
                        end
                    end
                end
            end
        end
        return puestas, sinOpciones
    end

    -- ─── ORIGEN Y CARACTERISTICAS ───────────────────────────────────────────
    -- Sin raza no hay rasgos raciales ni bonos, y sin caracteristicas todo se queda a 10: una ficha
    -- asi no sirve para probar practicamente nada. Se sortean como las elecciones, para que montar
    -- dos veces la misma clase no de siempre el mismo personaje.
    local function Barajar(lista)
        for i = #lista, 2, -1 do
            local j = math.random(i)
            lista[i], lista[j] = lista[j], lista[i]
        end
        return lista
    end

    local function OrigenAlAzar()
        local P = Prog()
        local R, B = _G.HarfordDnDRaces, _G.HarfordDnDBackgrounds
        local razaNombre, trasfondoNombre = "?", "?"
        if R and R.GetRaces and P.SetRace then
            local razas = R.GetRaces() or {}
            local elegida = razas[math.random(#razas)]
            if elegida then
                -- Subraza al azar entre las suyas; si no tiene, la de por defecto.
                local sub
                local subs = elegida.subraces
                if type(subs) == "table" and #subs > 0 then
                    sub = subs[math.random(#subs)].id
                else
                    sub = R.GetDefaultSubraceId and R.GetDefaultSubraceId(elegida.id) or nil
                end
                P.SetRace(elegida.id, sub)
                razaNombre = tostring(elegida.name or elegida.id)
                    .. (sub and sub ~= "" and (" / " .. tostring(sub)) or "")
            end
        end
        if B and B.GetBackgrounds and P.SetBackground then
            local fondos = B.GetBackgrounds() or {}
            local elegido = fondos[math.random(#fondos)]
            if elegido then
                P.SetBackground(elegido.id)
                trasfondoNombre = tostring(elegido.name or elegido.id)
                -- La variante tambien: es una eleccion mas del trasfondo y quedaria sin tocar.
                if P.SetBackgroundVariant then
                    local vs = elegido.variants
                    if type(vs) == "table" and #vs > 0 then
                        local v = vs[math.random(#vs)]
                        P.SetBackgroundVariant(v.id)
                        trasfondoNombre = trasfondoNombre .. " (" .. tostring(v.name or v.id) .. ")"
                    else
                        P.SetBackgroundVariant(nil)
                    end
                end
            end
        end
        return razaNombre, trasfondoNombre
    end

    -- Reparto estandar, repartido al azar. Es el que usa la mesa y da un personaje jugable, a
    -- diferencia de tirar 6d6 -- que puede salir inservible y no sirve para probar.
    local REPARTO = { 15, 14, 13, 12, 10, 8 }

    -- Se HORNEA base + bonos de creacion, igual que hace el asistente: los incrementos de raza y
    -- trasfondo van a `creationBonus` y no se suman en vivo, asi que sin esto el personaje
    -- perderia su bono racial. Va DESPUES de fijar raza, trasfondo y sus elecciones, o el motor no
    -- tendria de donde resolverlos.
    local function CaracteristicasAlAzar()
        local D = _G.HarfordDnDData
        if not (D and D.ABIL and HarfordDnDStore and HarfordDnDStore.SetValue) then return {} end
        local valores = Barajar({ REPARTO[1], REPARTO[2], REPARTO[3], REPARTO[4], REPARTO[5], REPARTO[6] })
        local resumen = {}
        for i, abil in ipairs(D.ABIL) do
            local base = valores[i] or 10
            local bono = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetCreationAbilityBonus
                and HarfordDnDFeatureEffects.GetCreationAbilityBonus(abil.key)) or 0
            local total = base + (tonumber(bono) or 0)
            HarfordDnDStore.SetValue(abil.key, total)
            resumen[#resumen + 1] = string.format("%s %d", tostring(abil.short or abil.key), total)
        end
        return resumen
    end

    -- Monta la ficha. Devuelve un resumen, que es lo que hace util el recorrido de `todas`.
    local function Montar(classId, subclassId)
        local P, L = Prog(), Libro()
        if not (P and L) then return nil, "modulos no disponibles" end
        local classDef = L.GetClass and L.GetClass(classId)
        if not classDef then return nil, "clase desconocida: " .. tostring(classId) end

        Limpiar()
        local datos = P.Get()
        local ok, err = P.SetClassEntry(1, classId, subclassId, NIVEL)
        if not ok then return nil, tostring(err) end

        -- La XP no debe quedar por debajo del nivel recien fijado, o el panel ofreceria subir a un
        -- nivel que ya se tiene.
        local umbral = HarfordCharacterXP and HarfordCharacterXP.XP_TABLE
            and HarfordCharacterXP.XP_TABLE[NIVEL]
        if umbral and HarfordCharacterXP.SetXP then HarfordCharacterXP.SetXP(umbral) end
        local razaNombre, trasfondoNombre = OrigenAlAzar()
        local puestas, sinOpciones = RellenarElecciones()
        -- Las caracteristicas al final: hornean los bonos de raza y trasfondo, que no existen
        -- hasta que sus elecciones estan resueltas.
        local caracteristicas = CaracteristicasAlAzar()
        Refrescar()

        local entrada = P.GetClassLevels()[1]
        local rasgos = (L.GetUnlockedFeatures and L.GetUnlockedFeatures(P.GetClassLevels())) or {}
        local pendientes, conEleccion = 0, {}
        for _, item in ipairs(rasgos) do
            local f = item.feature
            local huecos = (L.GetChoiceSlots and f and f.choice) and L.GetChoiceSlots(f) or 0
            if huecos > 0 then
                local elegido = P.GetChoice and P.GetChoice(f.id)
                local puestos = 0
                if type(elegido) == "table" then
                    for _ in pairs(elegido) do puestos = puestos + 1 end
                elseif elegido then puestos = 1 end
                if puestos < huecos then
                    pendientes = pendientes + (huecos - puestos)
                    conEleccion[#conEleccion + 1] = tostring(f.name or f.id)
                end
            end
        end
        return {
            puestas = puestas, sinOpciones = sinOpciones,
            raza = razaNombre, trasfondo = trasfondoNombre, caract = caracteristicas,
            classId = classDef.id, className = classDef.name,
            subclassId = entrada and entrada.subclassId or "",
            hitDie = classDef.hitDie,
            rasgos = #rasgos, pendientes = pendientes, conEleccion = conEleccion,
            pb = P.GetProficiencyBonus and P.GetProficiencyBonus() or nil,
        }
    end

    local function Listar()
        Print("Clases y sus especializaciones (id que hay que escribir):")
        for _, c in ipairs(Clases()) do
            local subs = {}
            for _, s in ipairs(c.subclasses or {}) do subs[#subs + 1] = tostring(s.id) end
            Print(string.format("  |cffffcc00%-18s|r d%-2s  %s", tostring(c.id),
                tostring(c.hitDie or "?"), table.concat(subs, ", ")))
        end
        Print("Uso: ficha6 <clase> [subclase] | ficha6 todas | ficha6 restaurar")
        Print("|cffff8888Sustituye la ficha actual|r; se guarda copia y se recupera con 'restaurar'.")
    end

    API.RegisterCommand("ficha6", function(args)
        args = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local sub, resto = args:match("^(%S+)%s*(.*)$")
        sub = sub and sub:lower() or ""

        if sub == "" then return Listar() end
        if sub == "restaurar" then return Restaurar() end

        if sub == "todas" then
            Guardar()
            Print("Montando nivel " .. NIVEL .. " de cada clase...")
            local fallos, totalPend = 0, 0
            for _, c in ipairs(Clases()) do
                local r, err = Montar(c.id, nil)
                if not r then
                    fallos = fallos + 1
                    Print(string.format("  |cffff4444%-18s FALLA|r %s", tostring(c.id), tostring(err)))
                else
                    totalPend = totalPend + r.pendientes
                    Print(string.format("  %-18s d%-2s %-16s %2d rasgos  %2d elegidas  %s",
                        tostring(r.classId), tostring(r.hitDie), tostring(r.subclassId),
                        r.rasgos, r.puestas,
                        r.pendientes > 0
                            and ("|cffffcc00" .. r.pendientes .. " sin resolver|r: "
                                .. table.concat(r.conEleccion, ", "))
                            or "|cff88ff88lista|r"))
                    Print(string.format("      %s | %s | %s",
                        tostring(r.raza), tostring(r.trasfondo),
                        table.concat(r.caract or {}, " ")))
                end
            end
            Print(string.format("%d clases, %d fallos, %d elecciones sin resolver.",
                #Clases(), fallos, totalPend))
            if totalPend > 0 then
                Print("Las que quedan no tienen opciones declaradas: no se pueden rellenar solas.")
            end
            -- La ficha queda con la ULTIMA clase montada. Se avisa, porque quedarse con una ficha
            -- de prueba sin saberlo es peor que perderla.
            Print("La ficha ha quedado con la ultima clase. Usa 'ficha6 restaurar' para deshacer.")
            return
        end

        local nueva = Guardar()
        local r, err = Montar(sub, (resto ~= "" and resto or nil))
        if not r then
            Print("|cffff4444" .. tostring(err) .. "|r")
            Print("Usa 'ficha6' a secas para ver las clases.")
            return
        end
        Print(string.format("|cff88ff88%s nivel %d|r (%s), d%s, bono de competencia +%s, %d rasgos.",
            tostring(r.className), NIVEL, tostring(r.subclassId), tostring(r.hitDie),
            tostring(r.pb or "?"), r.rasgos))
        Print("  Raza: " .. tostring(r.raza) .. "   Trasfondo: " .. tostring(r.trasfondo))
        Print("  " .. table.concat(r.caract or {}, "  "))
        Print(string.format("  %d eleccion(es) rellenadas al azar; cambialas en el panel.",
            r.puestas))
        if r.pendientes > 0 then
            Print("  |cffffcc00" .. r.pendientes .. " sin resolver|r (no tienen opciones que elegir): "
                .. table.concat(r.conEleccion, ", "))
        end
        if nueva then Print("  Copia de la ficha anterior guardada ('ficha6 restaurar').") end
    end, "monta una ficha de nivel 6 (ficha6 [clase|todas|restaurar])")
end

-- ─── POR QUE NO SE VEN LAS FICHAS DE ACCION ─────────────────────────────────
-- Las fichas de Accion / Adicional / Reaccion tienen CUATRO condiciones encadenadas, y si falla
-- una no se ven sin que nada lo diga. Con la tira de estados ya paso: tres comprobaciones daban
-- verde mientras el frame estaba 22 pixeles por encima del borde de la pantalla. La leccion fue
-- medir -- tamano, alfa, escala, anclaje y limites en pantalla -- en vez de deducir.
do
    local function Si(v) return v and "|cff88ff88si|r" or "|cffff4444NO|r" end

    API.RegisterCommand("economia", function(args)
        local AB = _G.HarfordActionBars
        local T = _G.HarfordDnDConditions and _G.HarfordDnDConditions.Turn
        Print("--- Modulos ---")
        Print("  HarfordActionBars: " .. Si(AB ~= nil))
        Print("  motor de economia: " .. Si(T ~= nil))
        if not (AB and T) then return end

        Print("--- Condicion 1: hay combate ---")
        local activo = T.IsActive and T.IsActive()
        Print("  Turn.IsActive(): " .. Si(activo))
        local TO = _G.HarfordTurnOrderAPI
        Print("  HasActiveCombat(): " .. Si(TO and TO.HasActiveCombat and TO.HasActiveCombat()))
        local store = _G.HarfordTurnOrderStore
        Print("  combatientes en la lista: "
            .. tostring(type(store) == "table" and type(store.entries) == "table" and #store.entries or 0))
        if not activo then
            Print("  |cffffcc00Sin combate no se pintan a proposito|r: fuera de combate no se lleva")
            Print("  la cuenta, y unas fichas llenas serian informacion falsa.")
        end

        Print("--- Condicion 2: presupuestos ---")
        for _, kind in ipairs(T.ORDEN or {}) do
            Print(string.format("  %-10s %d/%d", tostring(T.ETIQUETA[kind]),
                T.GetRemaining(kind), T.GetBudget(kind)))
        end

        Print("--- Condicion 3: hay ancla ---")
        -- El contenedor se cuelga de la barra de accion NATIVA. Sin ninguna de las cuatro
        -- candidatas creada, no hay de donde colgarlo y se esconde.
        for _, nombre in ipairs({ "ActionButton1", "MainMenuBarArtFrame", "MainMenuBar",
                                  "MultiBarBottomLeftButton1" }) do
            local f = _G[nombre]
            Print(string.format("  %-26s %s%s", nombre, Si(f ~= nil),
                f and (f.IsShown and f:IsShown() and " (visible)" or " (oculta)") or ""))
        end

        Print("--- Condicion 4: el frame, medido ---")
        local n, orbes = AB.RefreshTurnEconomy and AB.RefreshTurnEconomy()
        Print("  fichas dibujadas: " .. tostring(n) .. "   orbes: " .. tostring(orbes))
        local cont = _G.HarfordTurnEconomyFrame
        if not cont then
            Print("  |cffff4444El contenedor no existe|r")
            return
        end
        Print(string.format("  visible=%s  alfa=%.2f  escala=%.2f  tam=%.0fx%.0f",
            Si(cont:IsShown()), cont:GetAlpha() or 0, cont:GetScale() or 1,
            cont:GetWidth() or 0, cont:GetHeight() or 0))
        local izq, abajo = cont:GetLeft(), cont:GetBottom()
        local arriba, der = cont:GetTop(), cont:GetRight()
        if not izq then
            Print("  |cffff4444Sin posicion|r: no esta anclado a nada.")
            return
        end
        local anchoP, altoP = UIParent:GetWidth(), UIParent:GetHeight()
        Print(string.format("  posicion: x %.0f-%.0f  y %.0f-%.0f   (pantalla %.0fx%.0f)",
            izq, der or 0, abajo, arriba or 0, anchoP, altoP))
        -- Esto es lo que se escapo con la tira de estados: estar dibujado no es estar visible.
        local dentro = izq >= 0 and abajo >= 0 and (der or 0) <= anchoP and (arriba or 0) <= altoP
        Print("  dentro de la pantalla: " .. Si(dentro))
        if not dentro then
            Print("  |cffff4444Esta fuera de la pantalla|r: dibujado pero invisible.")
        end
        Print("  strata=" .. tostring(cont:GetFrameStrata())
            .. "  nivel=" .. tostring(cont:GetFrameLevel()))
        -- Estar en pantalla no es estar VISIBLE: en la misma capa, quien tenga mas nivel se pinta
        -- encima. Es lo que escondia las fichas detras de la barra de accion.
        local ancla2 = _G["ActionButton1"] or _G["MainMenuBar"]
        if ancla2 and ancla2.GetFrameLevel then
            local mio, suyo = cont:GetFrameLevel() or 0, ancla2:GetFrameLevel() or 0
            Print(string.format("  la barra nativa esta en %s nivel %d; yo en %d -> %s",
                tostring(ancla2:GetFrameStrata()), suyo, mio,
                mio > suyo and "|cff88ff88delante|r" or "|cffff4444DETRAS, no se ve|r"))
        end
        -- Una ficha suelta, para separar "el contenedor esta mal" de "las fichas estan mal".
        local f1 = cont.fichas and cont.fichas[1]
        if f1 then
            Print(string.format("  ficha 1: visible=%s tam=%.0fx%.0f alfa=%.2f",
                Si(f1:IsShown()), f1:GetWidth() or 0, f1:GetHeight() or 0, f1:GetAlpha() or 0))
        else
            Print("  no hay ninguna ficha creada todavia")
        end

        -- Y la prueba que ninguna medida sustituye: pintarlo a la fuerza donde no puede tapar
        -- nada. Separa "no se esta dibujando" de "se dibuja donde no miras", que son dos averias
        -- distintas y las medidas de arriba no siempre las distinguen.
        if not tostring(args or ""):find("forzar") then
            Print("Para verlo a la fuerza en el centro: |cffffcc00economia forzar|r")
            return
        end
        if not cont.pruebaFondo then
            cont.pruebaFondo = cont:CreateTexture(nil, "BACKGROUND")
            cont.pruebaFondo:SetAllPoints(cont)
        end
        cont.pruebaFondo:SetColorTexture(1, 0, 1, 0.5)
        cont.pruebaFondo:Show()
        cont:ClearAllPoints()
        cont:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        cont:SetFrameStrata("TOOLTIP")
        cont:Show()
        -- Y con presupuesto de mentira, para que haya fichas que pintar aunque no haya combate.
        local fichas = cont.fichas or {}
        for i = 1, 3 do
            local f = fichas[i]
            if f then
                f:ClearAllPoints()
                f:SetPoint("BOTTOMLEFT", cont, "BOTTOMLEFT", (i - 1) * 19, 0)
                f:Show()
            end
        end
        Print("|cffff00ffFondo magenta en el CENTRO durante 10 s.|r Si no lo ves, no se dibuja.")
        C_Timer.After(10, function()
            if cont.pruebaFondo then cont.pruebaFondo:Hide() end
            cont:SetFrameStrata("MEDIUM")
            if AB.RefreshTurnEconomy then AB.RefreshTurnEconomy() end
        end)
    end, "por que no se ven las fichas de accion/adicional/reaccion (economia [forzar])")
end

-- ─── POR QUE NO SALEN LAS DOTES ─────────────────────────────────────────────
-- Una dote llega al Libro por una cadena de cuatro pasos, y si falla uno no sale nada ni se dice
-- por que. Se miden los cuatro en vez de deducirlos.
do
    API.RegisterCommand("dotes", function()
        local P, F, B = _G.HarfordDnDProgression, _G.HarfordDnDFeats, _G.HarfordCharacterBook
        Print("--- 1. Que dotes tiene la ficha ---")
        if not (P and P.Get) then Print("  HarfordDnDProgression no disponible") return end
        local data = P.Get()
        local lista = type(data.feats) == "table" and data.feats or {}
        -- OJO: `data.feats` es una LISTA de ids, no un mapa. Si alguien la escribio como mapa,
        -- `#lista` da 0 y el Libro se la salta entera sin quejarse.
        local porClave = 0
        for k in pairs(lista) do if type(k) ~= "number" then porClave = porClave + 1 end end
        Print(string.format("  data.feats: %d en lista, %d por clave", #lista, porClave))
        if porClave > 0 then
            Print("  |cffff4444Hay claves NO numericas|r: el Libro solo recorre la lista.")
        end
        for i, id in ipairs(lista) do Print("    " .. i .. ". " .. tostring(id)) end
        if #lista == 0 and porClave == 0 then
            Print("  |cffffcc00La ficha no tiene ninguna dote guardada.|r")
            Print("  Se eligen en la Mejora de Caracteristica (nivel 4). Si elegiste una y no")
            Print("  esta aqui, el fallo esta al aplicarla, no al mostrarla.")
        end

        Print("--- 2. Se reconocen en el libro de dotes ---")
        if not (F and F.GetFeat) then Print("  HarfordDnDFeats no disponible") return end
        for _, id in ipairs(lista) do
            local def = F.GetFeat(id)
            Print(string.format("  %-28s %s", tostring(id),
                def and ("|cff88ff88" .. tostring(def.name) .. "|r, " .. #(def.traits or {}) .. " rasgo(s)")
                or "|cffff4444no existe con ese id|r"))
        end

        Print("--- 3. Sus rasgos salen envueltos ---")
        local traits = F.GetFeatTraits and F.GetFeatTraits(lista) or {}
        Print("  GetFeatTraits devuelve: " .. #traits)
        for i, item in ipairs(traits) do
            if i <= 6 then
                Print(string.format("    %s | %s", tostring(item.className),
                    tostring(item.feature and item.feature.name or "|cffff4444SIN feature|r")))
            end
        end

        Print("--- 4. El Libro los deja pasar ---")
        if not (B and B.IsVisible) then Print("  HarfordCharacterBook no disponible") return end
        local visibles, ocultos = 0, {}
        for _, item in ipairs(traits) do
            if item.feature and B.IsVisible(item.feature) then visibles = visibles + 1
            elseif item.feature then ocultos[#ocultos + 1] = tostring(item.feature.name) end
        end
        Print("  pasan el filtro: " .. visibles .. " de " .. #traits)
        for _, n in ipairs(ocultos) do Print("    |cffffcc00filtrado:|r " .. n) end
        if #traits > 0 and visibles == 0 then
            Print("  |cffff4444Los rasgos existen pero el Libro los oculta|r (bookHidden o marcador).")
        end
        if visibles > 0 then
            Print("  |cff88ff88Deberian verse en General.|r Si no salen, el fallo esta al pintar.")
        end
    end, "por que no salen las dotes en el Libro")
end
