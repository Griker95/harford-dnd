HarfordDebugSettings = HarfordDebugSettings or {}

HarfordDebug = HarfordDebug or {}
HarfordDnDDebug = HarfordDebug

local API = HarfordDebug
local commands = {}

local function Print(message)
    print("|cff88ccff[HarfordDebug]|r " .. tostring(message or ""))
end

local function IsEnabled()
    return HarfordDebugSettings.enabled == true
end

local function SetEnabled(enabled, silent)
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
    Print("/harforddebug on - activa logs y comandos debug")
    Print("/harforddebug off - desactiva debug")
    Print("/harforddebug toggle - alterna debug")
    Print("/harforddebug status - muestra estado")
    Print("/harforddebug run <comando> - ejecuta un comando debug registrado")
    Print("/harforddebug list - lista comandos debug registrados")
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
        Print("debug esta desactivado. Usa /harforddebug on")
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
        Print("uso: /harforddebug run raw <comando>")
        return
    end

    HarfordServerActions.SendRawDebug(args, function(success, messages)
        Print("raw: " .. (success and "OK" or "ERROR"))
        for _, line in ipairs(messages or {}) do
            Print(line)
        end
    end)
end, "envia comando raw solo con debug activo")

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
-- Uso: /harforddebug run totspy [segundos]   (por defecto 5s)
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
-- Uso: /harforddebug run totrate [segundos]   (por defecto 5s)
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

SLASH_HARFORDDEBUG1 = "/harforddebug"
SLASH_HARFORDDEBUG2 = "/hdebug"
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
            Print("uso: /harforddebug run <comando>")
            return
        end
        API.RunCommand(debugCommand, args)
    else
        Print("comando no reconocido: " .. command)
        ShowHelp()
    end
end

-- ── INSPECCIÓN DE FRAME TOT / FOCUS ────────────────────────────────────────
-- Uso: /harforddebug run totframe [tot|focustot]
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

SetEnabled(HarfordDebugSettings.enabled == true, true)
