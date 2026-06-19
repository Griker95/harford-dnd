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

-- Volcado profundo de un frame (por defecto CharacterFrame) a la SavedVariable
-- HarfordFrameProbe, para replicar UI nativa. Captura atlas (que el FrameDump externo
-- NO guarda), textura, texCoord, tamaño, anclajes, capa, color y texto. Uso:
--   /harford debug probeframe            -> vuelca CharacterFrame
--   /harford debug probeframe NombreFrame
-- Luego /reload para que se escriba al disco, y se lee SavedVariables\Harford.lua.
API.RegisterCommand("probeframe", function(args)
    local frameName = tostring(args or ""):match("^%s*(%S+)") or ""
    if frameName == "" then frameName = "CharacterFrame" end
    local root = _G[frameName]
    if not root then
        Print("frame no encontrado: " .. frameName)
        return
    end

    local function pack(...)
        local n = select("#", ...)
        local t = {}
        for i = 1, n do t[i] = select(i, ...) end
        return t
    end
    local function getPoints(obj)
        local out = {}
        local n = (obj.GetNumPoints and obj:GetNumPoints()) or 0
        for i = 1, n do
            local p, rel, rp, x, y = obj:GetPoint(i)
            local relName = rel and rel.GetName and rel:GetName() or nil
            out[i] = { point = p, relativeTo = relName, relativePoint = rp, x = x, y = y }
        end
        return out
    end
    local function dumpRegions(frame)
        local regions = {}
        for _, r in ipairs({ frame:GetRegions() }) do
            local ot = r.GetObjectType and r:GetObjectType()
            local e = { objectType = ot, name = r.GetName and r:GetName() or nil, points = getPoints(r) }
            if r.GetSize then e.width, e.height = r:GetSize() end
            if r.GetDrawLayer then e.drawLayer = pack(r:GetDrawLayer()) end
            if ot == "Texture" then
                if r.GetAtlas then e.atlas = r:GetAtlas() end
                if r.GetTextureFileID then e.textureFileID = r:GetTextureFileID() end
                if r.GetTexture then e.texture = r:GetTexture() end
                if r.GetTexCoord then e.texCoord = pack(r:GetTexCoord()) end
                if r.GetVertexColor then e.vertexColor = pack(r:GetVertexColor()) end
            elseif ot == "FontString" then
                if r.GetText then e.text = r:GetText() end
                if r.GetFont then e.font = pack(r:GetFont()) end
                if r.GetTextColor then e.textColor = pack(r:GetTextColor()) end
            end
            regions[#regions + 1] = e
        end
        return regions
    end
    local function dumpFrame(frame, depth)
        local node = {
            name = frame.GetName and frame:GetName() or nil,
            objectType = frame.GetObjectType and frame:GetObjectType() or nil,
            shown = frame.IsShown and frame:IsShown() or nil,
            points = getPoints(frame),
            regions = dumpRegions(frame),
            children = {},
        }
        if frame.GetSize then node.width, node.height = frame:GetSize() end
        if depth < 8 and frame.GetChildren then
            for _, c in ipairs({ frame:GetChildren() }) do
                node.children[#node.children + 1] = dumpFrame(c, depth + 1)
            end
        end
        return node
    end

    HarfordFrameProbe = { frame = frameName, tree = dumpFrame(root, 0) }
    Print("volcado de '" .. frameName .. "' a HarfordFrameProbe. Haz /reload y avisa.")
end, "vuelca un frame (def. CharacterFrame) a HarfordFrameProbe")

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

    local icon, rawIcon = HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)
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
        return
    end

    if action == "logs" then CleanReputationLogs(); return end
    if action == "npclinks" then CleanNpcLinks(); return end
    if action == "guilds" then CleanGuilds(); return end
    if action == "dnd" then CleanDnDDefaults(); return end
    if action == "frameprobe" then CleanFrameProbe(); return end
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

    Print("uso: /harford debug run svclean status|safe|dnd|logs|npclinks|guilds|frameprobe|targetpos [force]|all|purge confirm")
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

SetEnabled(type(HarfordDebugSettings) == "table" and HarfordDebugSettings.enabled == true, true)
