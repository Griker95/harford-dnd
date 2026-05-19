HarfordNamePlates = HarfordNamePlates or {}

-- Overlay de barras D&D sobre nameplates nativos o KuiNameplates.
--
-- Arquitectura Kui (kesava-wow/kuinameplates2 + npinspect):
--   kui.HealthBar   → StatusBar 126x14, Hide() en name-only (no SetAlpha)
--   kui.NameText    → FontString del nombre (centro del nameplate)
--   kui.IN_NAMEONLY → bool, true cuando la barra está oculta
--   kui.unit        → unit token actual (actualizado por Kui al reciclar frames)
--
-- Modos visuales:
--   Normal     → overlay sobre kui.HealthBar: bg opaco, HP + recurso
--   Name-only  → overlay sobre kui.NameText, frame level BAJO (NameText queda encima),
--                bg semitransparente, fill usa el color propio del nombre. No recurso.
--   Nativo WoW → overlay sobre UnitFrame.healthBar, solo normal mode.

local API = HarfordNamePlates

local npState    = {}   -- [unitToken] = { ov, kuiFrame }
local npRequests = {}   -- throttle sync: [unitName] = timestamp
local kuiPluginRegistered
local kuiClassPowersWasEnabled

-- ── Helpers ────────────────────────────────────────────────────────────────────

local function NpEnabled()
    return not HarfordConfig or HarfordConfig.Get("nameplates") ~= "off"
end

local function IsKuiActive()
    return type(KuiNameplates) == "table"
end

local function GetTex()
    return (HarfordUnitFrames and HarfordUnitFrames.C and HarfordUnitFrames.C.TEX_STATUS)
        or "Interface\\TargetingFrame\\UI-StatusBar"
end

local function GetAbsorbTex(useKui)
    if useKui then
        return "Interface\\AddOns\\Kui_Media\\t\\stippled-bar"
    end
    return (HarfordUnitFrames and HarfordUnitFrames.C and HarfordUnitFrames.C.TEX_ABSORB_FILL)
        or "Interface\\RaidFrame\\Shield-Fill"
end

local function GetAbsorbEdgeTex(useKui)
    if useKui then
        return "Interface\\AddOns\\Kui_Media\\t\\spark"
    end
    return (HarfordUnitFrames and HarfordUnitFrames.C and HarfordUnitFrames.C.TEX_ABSORB_EDGE)
        or "Interface\\RaidFrame\\Shield-Overshield"
end

local function ApplyAbsorbTexture(texture, owner, cur, max, temp, alpha)
    if not texture or not owner then return end
    max = math.max(tonumber(max) or 0, 0)
    temp = math.max(tonumber(temp) or 0, 0)
    if max <= 0 or temp <= 0 then
        texture:Hide()
        return
    end

    local function EnsureDecor(frame)
        if not frame or not frame.CreateTexture then return end
        local useKui = frame._harfordUseKui == true
        if not frame._harfordAbsorbPattern then
            local pattern = frame:CreateTexture(nil, "ARTWORK", nil, 1)
            pattern:SetTexture(GetAbsorbTex(useKui))
            pattern:SetBlendMode(useKui and "BLEND" or "ADD")
            pattern:SetVertexColor(0.72, 0.98, 1.0, useKui and 0.65 or 0.95)
            pattern:Hide()
            frame._harfordAbsorbPattern = pattern
        end
        if not frame._harfordAbsorbGlow then
            local glow = frame:CreateTexture(nil, "ARTWORK", nil, 2)
            glow:SetTexture((HarfordUnitFrames and HarfordUnitFrames.C and HarfordUnitFrames.C.TEX_ABSORB)
                or "Interface\\RaidFrame\\Shield-Overlay")
            glow:SetBlendMode("ADD")
            glow:SetVertexColor(0.65, 0.95, 1.0, 0.45)
            glow:Hide()
            frame._harfordAbsorbGlow = glow
        end
        if not frame._harfordAbsorbSpark then
            local spark = frame:CreateTexture(nil, "ARTWORK", nil, 3)
            spark:SetTexture(GetAbsorbEdgeTex(useKui))
            spark:SetBlendMode("ADD")
            spark:SetVertexColor(0.75, 0.95, 1.0, 0.95)
            spark:Hide()
            frame._harfordAbsorbSpark = spark
        end
    end

    local function UpdateDecor(frame, pct, ownerWidth, ownerHeight, a)
        EnsureDecor(frame)
        local h = math.max(6, ownerHeight or (owner.GetHeight and owner:GetHeight() or 10))
        -- Ancho real del fill (compartido por glow y spark).
        -- fillTex:RIGHT no es fiable en Epsilon (texcoords-based, no resize).
        local realW = (frame.GetWidth and frame:GetWidth() or 0)
        if realW <= 0 then realW = ownerWidth or 0 end

        -- Pattern: oculto (el StatusBar ya usa Shield-Fill directamente como fill).
        if frame._harfordAbsorbPattern then frame._harfordAbsorbPattern:Hide() end

        -- Glow: Shield-Overlay tileado sobre el área del fill (combo con Shield-Fill).
        -- Efecto final = Shield-Fill (fill sólido tintado) + Shield-Overlay (patrón rayado encima).
        if frame._harfordAbsorbGlow then
            if realW > 0 then
                local fillW = math.max(1, realW * pct)
                frame._harfordAbsorbGlow:ClearAllPoints()
                frame._harfordAbsorbGlow:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, 0)
                frame._harfordAbsorbGlow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
                frame._harfordAbsorbGlow:SetWidth(fillW)
                if frame._harfordAbsorbGlow.SetHorizTile then
                    frame._harfordAbsorbGlow:SetHorizTile(true)
                end
                frame._harfordAbsorbGlow:SetVertexColor(0.65, 0.95, 1.0, 0.45)
                frame._harfordAbsorbGlow:Show()
            else
                frame._harfordAbsorbGlow:Hide()
            end
        end

        -- Spark en el borde exacto del fill.
        if frame._harfordAbsorbSpark then
            frame._harfordAbsorbSpark:ClearAllPoints()
            frame._harfordAbsorbSpark:SetSize(math.max(5, h * 0.8), math.max(4, h * 0.9))
            frame._harfordAbsorbSpark:SetPoint("CENTER", frame, "LEFT", realW * pct, 0)
            frame._harfordAbsorbSpark:SetAlpha(a or 0.85)
            frame._harfordAbsorbSpark:Show()
        end
    end

    if texture.SetStatusBarTexture then
        texture:ClearAllPoints()
        texture:SetAllPoints(owner)
        -- Usar la textura de absorción correcta como fill del StatusBar (Kui o Shield-Overlay).
        -- Así el fill escala solo y muestra la textura real sin depender de GetWidth.
        local useKui = texture._harfordUseKui == true
        texture:SetStatusBarTexture(GetAbsorbTex(useKui))
        local tex = texture.GetStatusBarTexture and texture:GetStatusBarTexture()
        if tex and tex.SetHorizTile then tex:SetHorizTile(useKui) end  -- stippled-bar tilea, Shield-Fill no
        if tex and tex.SetVertTile then tex:SetVertTile(false) end
        texture:SetMinMaxValues(0, max)
        texture:SetValue(math.min(temp, max))
        texture:SetStatusBarColor(0.35, 0.82, 1.0, 1.0)
        if texture.SetAlpha then texture:SetAlpha(alpha or 0.85) end
        texture:Show()
        local w = owner.GetWidth and owner:GetWidth() or 0
        local h = owner.GetHeight and owner:GetHeight() or 0
        UpdateDecor(texture, math.min(temp / max, 1), w, h, alpha or 0.85)
        return
    end

    local ownerWidth = owner.GetWidth and owner:GetWidth() or 0
    if ownerWidth <= 1 then
        texture:Hide()
        return
    end

    local widthPct = temp / max
    widthPct = math.min(widthPct, 1)

    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    texture:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    texture:SetWidth(math.max(1, ownerWidth * widthPct))
    local useKui = texture._harfordUseKui == true
    texture:SetTexture(GetAbsorbTex(useKui), "CLAMP", "CLAMP")
    if texture.SetHorizTile then texture:SetHorizTile(useKui) end
    if texture.SetVertTile then texture:SetVertTile(useKui) end
    if texture.SetVertexColor then texture:SetVertexColor(0.45, 0.90, 1.0, alpha or 0.75) end
    if texture.SetAlpha then texture:SetAlpha(alpha or 0.85) end
    texture:Show()
end

local function GetBuildResourceList()
    local uf = HarfordUnitFrames
    return uf and uf.BuildResourceList
end

local function GetResourceColor()
    local uf = HarfordUnitFrames
    return uf and uf.ResourceColor
end

local function ResourceColor(key)
    local fn = GetResourceColor()
    if fn then return fn(key) end
    return 0.7, 0.7, 0.7
end

local function BuildResourceList(resources)
    local fn = GetBuildResourceList()
    return fn and fn(resources) or {}
end

local function RequestIfNeeded(unitName)
    if not HarfordDnDAPI or not HarfordDnDAPI.RequestResourcesForName then return end
    local now = GetTime and GetTime() or time()
    if (now - (npRequests[unitName] or 0)) < 5 then return end
    npRequests[unitName] = now
    HarfordDnDAPI.RequestResourcesForName(unitName)
end

-- Lee el color del texto del NameText de Kui (clase o blanco por defecto).
local function GetNameTextColor(nt)
    if not nt then return 1, 1, 1 end
    local r, g, b
    if nt.GetTextColor  then r, g, b = nt:GetTextColor()  end
    if (not r or r == 0) and nt.GetVertexColor then r, g, b = nt:GetVertexColor() end
    if r and (r ~= 1 or g ~= 1 or b ~= 1) then return r, g, b end
    return 1, 1, 1
end

local function ColorHex(r, g, b)
    r = math.max(0, math.min(255, math.floor((tonumber(r) or 1) * 255 + 0.5)))
    g = math.max(0, math.min(255, math.floor((tonumber(g) or 1) * 255 + 0.5)))
    b = math.max(0, math.min(255, math.floor((tonumber(b) or 1) * 255 + 0.5)))
    return string.format("%02x%02x%02x", r, g, b)
end

local function SplitUtf8(text)
    local chars = {}
    text = tostring(text or "")
    for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    if #chars == 0 and text ~= "" then
        for i = 1, #text do chars[#chars + 1] = text:sub(i, i) end
    end
    return chars
end

local function BuildProgressNameText(text, pct, r, g, b, fallbackR, fallbackG, fallbackB)
    local chars = SplitUtf8(text)
    if #chars == 0 then return "" end
    pct = math.max(0, math.min(1, tonumber(pct) or 0))
    local filled = math.floor((#chars * pct) + 0.5)
    if filled <= 0 then
        return "|cff" .. ColorHex(fallbackR or 0.55, fallbackG or 0.55, fallbackB or 0.55) .. table.concat(chars) .. "|r"
    end
    if filled >= #chars then
        return "|cff" .. ColorHex(r, g, b) .. table.concat(chars) .. "|r"
    end
    local left, right = {}, {}
    for i = 1, #chars do
        if i <= filled then left[#left + 1] = chars[i] else right[#right + 1] = chars[i] end
    end
    return "|cff" .. ColorHex(r, g, b) .. table.concat(left) .. "|r"
        .. "|cff" .. ColorHex(fallbackR or 0.45, fallbackG or 0.45, fallbackB or 0.45) .. table.concat(right) .. "|r"
end

local function SetKuiClassPowersSuppressed(suppressed)
    local cpf = KuiNameplates and KuiNameplates.ClassPowersFrame
    local plugin = KuiNameplates and KuiNameplates.GetPlugin and KuiNameplates:GetPlugin("ClassPowers")
    local shouldSuppress = suppressed == true
    API._suppressKuiClassPowers = shouldSuppress
    if suppressed then
        if plugin and kuiClassPowersWasEnabled == nil then
            kuiClassPowersWasEnabled = plugin.enabled == true
        end
        if plugin and plugin.enabled and plugin.Disable then
            if plugin.Disable then plugin:Disable() end
        end
    else
        if plugin and kuiClassPowersWasEnabled then
            if plugin.Enable then plugin:Enable() end
        end
        kuiClassPowersWasEnabled = nil
    end

    if not cpf then return end
    cpf._harfordSuppressed = shouldSuppress
    if cpf._harfordSuppressed then
        if not cpf._harfordHooked then
            cpf._harfordHooked = true
            cpf:HookScript("OnShow", function(frame)
                if frame._harfordSuppressed then frame:Hide() end
            end)
        end
        cpf:Hide()
    end
end

local WOW_CLASS_ALIASES = {
    { "guerrero", "WARRIOR" }, { "warrior", "WARRIOR" },
    { "paladin", "PALADIN" },
    { "cazador de demonios", "DEMONHUNTER" }, { "demon hunter", "DEMONHUNTER" }, { "demonhunter", "DEMONHUNTER" },
    { "cazador", "HUNTER" }, { "hunter", "HUNTER" },
    { "picaro", "ROGUE" }, { "picar", "ROGUE" }, { "rogue", "ROGUE" },
    { "sacerdote", "PRIEST" }, { "priest", "PRIEST" },
    { "caballero de la muerte", "DEATHKNIGHT" }, { "death knight", "DEATHKNIGHT" }, { "deathknight", "DEATHKNIGHT" },
    { "chaman", "SHAMAN" }, { "shaman", "SHAMAN" },
    { "mago", "MAGE" }, { "mage", "MAGE" },
    { "brujo", "WARLOCK" }, { "warlock", "WARLOCK" },
    { "monje", "MONK" }, { "monk", "MONK" },
    { "druida", "DRUID" }, { "druid", "DRUID" },
    { "evocador", "EVOKER" }, { "evoker", "EVOKER" },
}

local function NormalizeClassKey(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    value = value:gsub("[áàäâÁÀÄÂ]", "a")
    value = value:gsub("[éèëêÉÈËÊ]", "e")
    value = value:gsub("[íìïîÍÌÏÎ]", "i")
    value = value:gsub("[óòöôÓÒÖÔ]", "o")
    value = value:gsub("[úùüûÚÙÜÛ]", "u")
    value = value:gsub("[ñÑ]", "n")
    return value
end

local function GetTRP3ClassColor(unit)
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetProfilePrimaryClass) then return nil end
    local profile = HarfordTRP3.GetPlayerProfile(unit)
    local classText = NormalizeClassKey(profile and HarfordTRP3.GetProfilePrimaryClass(profile))
    if classText == "" then return nil end
    for _, entry in ipairs(WOW_CLASS_ALIASES) do
        if classText:find(entry[1], 1, true) then
            local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry[2]]
            if color then return color.r, color.g, color.b end
        end
    end
    return nil
end

local function GetFallbackHealthData(unit)
    if not unit or not UnitHealth or not UnitHealthMax then return nil end
    local maxHp = tonumber(UnitHealthMax(unit)) or 0
    if maxHp <= 0 then return nil end
    return {
        key = "health",
        label = "Salud",
        cur = tonumber(UnitHealth(unit)) or 0,
        max = maxHp,
    }
end

-- Nombre RP del jugador vía HarfordTRP3.
-- Usa GetPlayerProfile (BuildUnitID maneja tokens de nameplate) + lee FN/LN del perfil.
-- Fallback: GetUnitRPName si no hay perfil directo.
local function GetTRP3Name(unit)
    if not HarfordTRP3 then return nil end
    -- Obtener perfil (BuildUnitID convierte nameplate1→name-realm correctamente)
    if HarfordTRP3.GetPlayerProfile then
        local profile = HarfordTRP3.GetPlayerProfile(unit)
        if profile then
            local char = (profile.data and profile.data.characteristics)
                      or profile.characteristics
            if char then
                local fn = char.FN or ""
                local ln = char.LN or ""
                local full = fn .. (ln ~= "" and (" " .. ln) or "")
                if full ~= "" then return full end
            end
        end
    end
    -- Fallback: función directa de TRP3 (puede no funcionar con tokens nameplate)
    if HarfordTRP3.GetUnitRPName then
        return HarfordTRP3.GetUnitRPName(unit)
    end
    return nil
end

-- Color de clase para health bar y etiqueta de nombre.
-- Orden: HarfordUnitFrames (TRP3 → cache → WoW class) → WoW class nativo → verde salud.
local function GetNpClassColor(unit)
    if not unit then return 0.0, 0.82, 0.08 end
    local tr, tg, tb = GetTRP3ClassColor(unit)
    if tr then return tr, tg, tb end
    if HarfordUnitFrames and HarfordUnitFrames.GetClassColor then
        local r, g, b = HarfordUnitFrames.GetClassColor(unit)
        if r then return r, g, b end
    end
    if UnitClass then
        local _, classFile = UnitClass(unit)
        if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
            local c = RAID_CLASS_COLORS[classFile]
            return c.r, c.g, c.b
        end
    end
    return 0.0, 0.82, 0.08   -- verde salud por defecto (NPC / sin clase)
end

-- ── Detección health bar nativo ───────────────────────────────────────────────

local function FindNativeHealthBar(nameplate)
    local uf = rawget(nameplate, "UnitFrame")
    if uf then return uf.healthBar or uf.HealthBar end
    return nameplate.healthBar or nameplate.HealthBar
end

-- ── Creación del overlay ───────────────────────────────────────────────────────

-- Layout HP + recurso (normal mode).
local function LayoutNormal(ov, hasResource)
    ov.hpBar:ClearAllPoints()
    ov.resBar:ClearAllPoints()
    ov.sep:ClearAllPoints()
    if hasResource then
        ov.hpBar:SetPoint("TOPLEFT",     ov, "TOPLEFT",     0,  0)
        ov.hpBar:SetPoint("BOTTOMRIGHT", ov, "BOTTOMRIGHT", 0,  5)
        ov.sep:SetPoint("BOTTOMLEFT",  ov.hpBar, "BOTTOMLEFT",  0, 0)
        ov.sep:SetPoint("BOTTOMRIGHT", ov.hpBar, "BOTTOMRIGHT", 0, 0)
        ov.resBar:SetPoint("BOTTOMLEFT",  ov, "BOTTOMLEFT",  0, 0)
        ov.resBar:SetPoint("BOTTOMRIGHT", ov, "BOTTOMRIGHT", 0, 0)
        ov.resBar:SetHeight(4)
        ov.sep:Show()
        ov.resBar:Show()
    else
        ov.hpBar:SetAllPoints(ov)
        ov.sep:Hide()
        ov.resBar:Hide()
    end
end

-- Un solo overlay por nameplate, parented al kuiFrame (no al HealthBar).
-- Así sigue visible aunque Kui haga HealthBar:Hide() en name-only.
local function CreateKuiOverlay(kuiFrame)
    local ov = CreateFrame("Frame", nil, kuiFrame)
    ov:EnableMouse(false)
    ov:Hide()

    ov.bg = ov:CreateTexture(nil, "BACKGROUND")
    ov.bg:SetAllPoints(ov)

    ov.hpBar = CreateFrame("StatusBar", nil, ov)
    ov.hpBar:SetStatusBarTexture(GetTex())
    ov.hpBar:SetFrameLevel(ov:GetFrameLevel() + 1)
    ov.hpBar:EnableMouse(false)

    ov.sep = ov:CreateTexture(nil, "BORDER")
    ov.sep:SetColorTexture(0, 0, 0, 1)
    ov.sep:SetHeight(1)

    ov.resBar = CreateFrame("StatusBar", nil, ov)
    ov.resBar:SetStatusBarTexture(GetTex())
    ov.resBar:SetFrameLevel(ov:GetFrameLevel() + 1)
    ov.resBar:EnableMouse(false)

    -- Vida temporal: overlay rayado/cian encima del fill de HP.
    ov.tempBar = CreateFrame("StatusBar", nil, ov)
    ov.tempBar._harfordUseKui = true
    ov.tempBar:SetStatusBarTexture(GetAbsorbTex(true))
    local tempTex = ov.tempBar:GetStatusBarTexture()
    if tempTex and tempTex.SetHorizTile then tempTex:SetHorizTile(true) end
    if tempTex and tempTex.SetVertTile then tempTex:SetVertTile(true) end
    ov.tempBar:SetStatusBarColor(0.35, 0.82, 1.00, 0.85)
    ov.tempBar:SetFrameLevel(ov:GetFrameLevel() + 2)
    ov.tempBar:EnableMouse(false)
    ov.tempBar:Hide()

    ov.nameHost = CreateFrame("Frame", nil, ov)
    ov.nameHost:SetAllPoints(kuiFrame)
    ov.nameHost:SetFrameLevel(ov:GetFrameLevel() + 4)
    ov.nameHost:EnableMouse(false)
    ov.nameHost:Hide()

    -- Fallback de nombre propio. El camino principal usa kui.NameText directamente,
    -- porque Kui lo reposiciona/reparenta segun modo y respeta su plano visual.
    ov.nameLabel = ov.nameHost:CreateFontString(nil, "HIGHLIGHT")
    ov.nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    ov.nameLabel:SetPoint("BOTTOM", ov, "TOP", 0, 2)
    ov.nameLabel:SetJustifyH("CENTER")
    ov.nameLabel:SetTextColor(1, 1, 1, 1)
    ov.nameLabel:Hide()

    return ov
end

-- ── Posicionamiento por modo ───────────────────────────────────────────────────

local function ApplyNormalMode(ov, kuiFrame, healthBar, hpData, resData)
    SetKuiClassPowersSuppressed(kuiFrame.unit == "target")

    -- Frame level ALTO para tapar la barra nativa
    local baseLevel = (kuiFrame.GetFrameLevel and kuiFrame:GetFrameLevel() or 1) + 5
    ov:SetFrameLevel(baseLevel)
    if ov.hpBar and ov.hpBar.SetFrameLevel then ov.hpBar:SetFrameLevel(baseLevel + 1) end
    if ov.resBar and ov.resBar.SetFrameLevel then ov.resBar:SetFrameLevel(baseLevel + 1) end
    if ov.tempBar and ov.tempBar.SetFrameLevel then ov.tempBar:SetFrameLevel(baseLevel + 2) end
    if ov.hpBar then ov.hpBar:Show() end
    if ov.nameHost then
        ov.nameHost:SetFrameLevel(baseLevel + 5)
        ov.nameHost:ClearAllPoints()
        ov.nameHost:SetAllPoints(kuiFrame)
        ov.nameHost:Show()
    end
    ov:ClearAllPoints()
    ov:SetAllPoints(healthBar)

    -- bg opaco: tapa completamente la barra nativa
    ov.bg:SetColorTexture(0.02, 0.02, 0.02, 1.0)

    local unit = kuiFrame.unit
    local maxHp = math.max(tonumber(hpData.max) or 0, 0)
    local curHp = math.min(math.max(tonumber(hpData.cur) or 0, 0), maxHp > 0 and maxHp or 1)
    ov.hpBar:SetMinMaxValues(0, maxHp > 0 and maxHp or 1)
    ov.hpBar:SetValue(curHp)
    -- Color de clase TRP3 para la barra de salud; fallback clase WoW → verde.
    local hpR, hpG, hpB = GetNpClassColor(unit)
    ov.hpBar:SetStatusBarColor(hpR, hpG, hpB)

    if resData then
        local maxRes = math.max(tonumber(resData.max) or 0, 0)
        local curRes = math.min(math.max(tonumber(resData.cur) or 0, 0), maxRes > 0 and maxRes or 1)
        local r, g, b = ResourceColor(resData.key)
        ov.resBar:SetMinMaxValues(0, maxRes > 0 and maxRes or 1)
        ov.resBar:SetValue(curRes)
        ov.resBar:SetStatusBarColor(r, g, b)
    end
    LayoutNormal(ov, resData ~= nil)

    -- Vida temporal
    if ov.tempBar then
        local tempCur = math.max(tonumber(hpData.tempCur) or 0, 0)
        ApplyAbsorbTexture(ov.tempBar, ov.hpBar, curHp, maxHp, tempCur, 0.85)
    end

    -- Mantener el NameText nativo de Kui: es el elemento que Kui recoloca y pinta
    -- correctamente en cada modo. Solo cambiamos texto/color, no lo ocultamos.
    local nt = kuiFrame.NameText
    local name = GetTRP3Name(unit) or (unit and UnitName and UnitName(unit)) or ""
    if nt then
        if nt.SetText then nt:SetText(name) end
        if nt.SetTextColor then nt:SetTextColor(hpR, hpG, hpB, 1) end
        if nt.SetAlpha then nt:SetAlpha(1) end
        if nt.Show then nt:Show() end
        if ov.nameLabel then ov.nameLabel:Hide() end
    elseif ov.nameLabel then
        ov.nameLabel:SetText(name)
        ov.nameLabel:SetTextColor(hpR, hpG, hpB, 1)
        ov.nameLabel:Show()
    end

    if nt and ov.nameHost and nt.GetParent and nt.SetParent and nt:GetParent() ~= ov.nameHost then
        nt:SetParent(ov.nameHost)
        if kuiFrame.UpdateNameTextPosition then
            kuiFrame:UpdateNameTextPosition()
        end
    end
    if nt and nt.SetDrawLayer then nt:SetDrawLayer("OVERLAY", 7) end

    ov:Show()
end

local function ApplyNameOnlyMode(ov, kuiFrame, hpData)
    local nt = kuiFrame.NameText
    if not nt then ov:Hide() ; return end
    SetKuiClassPowersSuppressed(kuiFrame.unit == "target")

    -- Frame level BAJO: el NameText (en OVERLAY del kuiFrame) queda encima del fill.
    local targetLevel = math.max(1, (kuiFrame.GetFrameLevel and kuiFrame:GetFrameLevel() or 2) - 1)
    ov:SetFrameLevel(targetLevel)
    -- Fijar también el hpBar explícitamente: cambia cuando ov cambia de nivel.
    ov.hpBar:SetFrameLevel(targetLevel + 1)
    if ov.nameHost then ov.nameHost:Hide() end
    if nt.SetParent and nt:GetParent() ~= kuiFrame then
        nt:SetParent(kuiFrame)
        if kuiFrame.UpdateNameTextPosition then
            kuiFrame:UpdateNameTextPosition()
        end
    end

    ov:ClearAllPoints()
    ov:SetPoint("TOPLEFT",     nt, "TOPLEFT",     0,  0)
    ov:SetPoint("BOTTOMRIGHT", nt, "BOTTOMRIGHT", 0,  0)

    -- Sin fondo visible: que solo el fill coloree el nombre, nada más.
    ov.bg:SetColorTexture(0, 0, 0, 0)

    -- Prioridad: color de clase TRP3 → color que Kui puso en NameText → blanco.
    local unit = kuiFrame.unit
    local r, g, b = GetNpClassColor(unit)
    if r == 0.0 and g == 0.82 and b == 0.08 then
        -- Devolvió verde (NPC / sin clase): usar el color que Kui ya puso en NameText.
        r, g, b = GetNameTextColor(nt)
    end
    local maxHp = math.max(tonumber(hpData.max) or 0, 0)
    local curHp = math.min(math.max(tonumber(hpData.cur) or 0, 0), maxHp > 0 and maxHp or 1)
    local pct   = maxHp > 0 and (curHp / maxHp) or 0

    -- El hpBar se mantiene siempre "lleno" (value=1) pero su ancho es HP%*ancho del nombre.
    -- Así el efecto es: el propio nombre se va coloreando de izquierda a derecha.
    -- Harford name-only no dibuja barras: colorea el texto real por porcentaje.
    local name = GetTRP3Name(unit) or (unit and UnitName and UnitName(unit)) or ""
    if nt.SetText then nt:SetText(BuildProgressNameText(name, pct, r, g, b, 0.48, 0.48, 0.48)) end
    if nt.SetTextColor then nt:SetTextColor(1, 1, 1, 1) end
    if nt.SetAlpha then nt:SetAlpha(1) end
    if nt.Show then nt:Show() end
    if ov.hpBar then ov.hpBar:Hide() end
    if ov.sep then ov.sep:Hide() end
    if ov.resBar then ov.resBar:Hide() end
    if ov.tempBar then ov.tempBar:Hide() end
    if ov.nameLabel then ov.nameLabel:Hide() end
    ov:Hide()
    return
end

--[[
    local fullW = nt:GetWidth()
    ov.hpBar:ClearAllPoints()
    if fullW and fullW > 2 then
        ov.hpBar:SetPoint("TOPLEFT",    ov, "TOPLEFT",    0, 0)
        ov.hpBar:SetPoint("BOTTOMLEFT", ov, "BOTTOMLEFT", 0, 0)
        ov.hpBar:SetWidth(math.max(1, fullW * pct))
        ov.hpBar:SetMinMaxValues(0, 1)
        ov.hpBar:SetValue(1)
    else
        -- Fallback: el nombre aún no tiene ancho calculado; usar SetValue normal.
        ov.hpBar:SetAllPoints(ov)
        ov.hpBar:SetMinMaxValues(0, maxHp > 0 and maxHp or 1)
        ov.hpBar:SetValue(curHp)
    end
    ov.hpBar:SetStatusBarColor(r, g, b, 0.70)

    ov.sep:Hide()
    ov.resBar:Hide()
    if ov.tempBar then ov.tempBar:Hide() end
    -- En name-only Kui necesita su NameText visible (el fill lo colorea de izq a der).
    -- Restaurar alpha por si venimos de normal mode donde lo ocultamos.
    local name = GetTRP3Name(unit) or (unit and UnitName and UnitName(unit)) or ""
    if nt.SetText then nt:SetText(name) end
    if nt and nt.SetAlpha then nt:SetAlpha(1) end
    if ov.nameLabel then ov.nameLabel:Hide() end
    ov:Show()
end

-- ── Hooks por frame físico ─────────────────────────────────────────────────────

]]

local function SetupKuiHooks(kuiFrame, healthBar)
    if healthBar._harfordHooked then return end
    healthBar._harfordHooked = true

    if not kuiFrame._harfordNameHooked then
        kuiFrame._harfordNameHooked = true
        if type(kuiFrame.UpdateNameText) == "function" then
            hooksecurefunc(kuiFrame, "UpdateNameText", function(frame)
                local unit = frame and frame.unit
                if unit and NpEnabled() and not API._applying then API.ApplyUnit(unit) end
            end)
        end
        if type(kuiFrame.UpdateNameTextPosition) == "function" then
            hooksecurefunc(kuiFrame, "UpdateNameTextPosition", function(frame)
                local unit = frame and frame.unit
                if unit and NpEnabled() and not API._applying then API.ApplyUnit(unit) end
            end)
        end
    end

    -- HealthBar:Show → Kui salió de name-only
    healthBar:HookScript("OnShow", function()
        local unit = kuiFrame.unit
        if unit and NpEnabled() then API.ApplyUnit(unit) end
    end)

    -- HealthBar:Hide → Kui entró en name-only
    healthBar:HookScript("OnHide", function()
        local unit = kuiFrame.unit
        if unit and NpEnabled() and kuiFrame.IN_NAMEONLY then
            API.ApplyUnit(unit)
        end
    end)

    -- HealthBar:OnSizeChanged → Kui redimensionó el frame (select/deselect).
    -- El spark de absorción usa un offset en píxeles calculado con el ancho anterior;
    -- hay que recalcular ApplyAbsorbTexture con el nuevo ancho.
    healthBar:HookScript("OnSizeChanged", function()
        local unit = kuiFrame.unit
        if unit and NpEnabled() then API.ApplyUnit(unit) end
    end)
end

-- ── Lógica principal ───────────────────────────────────────────────────────────

function API.ApplyUnit(unit)
    if not NpEnabled() then return end
    if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end

    local unitName = UnitName and UnitName(unit)
    if not unitName then return end

    local isPlayer = UnitIsPlayer and UnitIsPlayer(unit)
    local resources = HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName
                      and HarfordDnDAPI.GetResourcesForName(unitName)

    if isPlayer and not resources then RequestIfNeeded(unitName) end

    local list = resources and BuildResourceList(resources) or {}
    local hpData = list[1]
    local kui = IsKuiActive() and rawget(nameplate, "kui")
    if (not hpData) and kui and kui.IN_NAMEONLY then
        hpData = GetFallbackHealthData(unit)
    end

    -- Inyectar vida temporal en hpData para que los renders la usen
    if hpData and hpData.key == "health" and type(resources) == "table" then
        local tc = math.max(tonumber(resources["Res_temp_health_Cur"]) or 0, 0)
        if tc > 0 then hpData.tempCur = tc end
    end

    local st = npState[unit]

    if not hpData then
        if st and st.ov then st.ov:Hide() end
        return
    end

    -- ── Kui ───────────────────────────────────────────────────────────────────
    -- IsKuiActive() + rawget son ambos dinámicos: Kui puede no estar todavía inicializado
    -- cuando se dispara NAME_PLATE_UNIT_ADDED, por lo que el nameplate podría haberse
    -- creado antes en modo nativo. Si el modo cambia, destruimos y recreamos el overlay.
    if kui then
        SetKuiClassPowersSuppressed(true)
        local healthBar = kui.HealthBar or kui.healthBar
        if not healthBar then return end

        if not st then st = {} ; npState[unit] = st end
        -- Recrear si el overlay fue creado en modo nativo (modo incompatible)
        if st.ov and not st.isKui then
            st.ov:Hide()
            st.ov = nil
        end
        if not st.ov then
            st.ov       = CreateKuiOverlay(kui)
            st.kuiFrame = kui
            st.isKui    = true
        end

        SetupKuiHooks(kui, healthBar)

        API._applying = true
        if kui.IN_NAMEONLY then
            ApplyNameOnlyMode(st.ov, kui, hpData)
        else
            if healthBar:IsShown() then
                ApplyNormalMode(st.ov, kui, healthBar, hpData, list[2])
            else
                st.ov:Hide()
            end
        end
        API._applying = nil
        return
    end

    -- ── Nativo WoW (sin Kui) ──────────────────────────────────────────────────
    local healthBar = FindNativeHealthBar(nameplate)
    if not healthBar then return end

    if not st then st = {} ; npState[unit] = st end
    -- Recrear si el overlay fue creado en modo Kui (modo incompatible)
    if st.ov and st.isKui then
        st.ov:Hide()
        st.ov  = nil
        st.isKui = nil
    end
    if not st.ov then
        -- Para nativo usamos un overlay simple parented al nameplate directamente
        local ov = CreateFrame("Frame", nil, healthBar)
        ov:SetAllPoints(healthBar)
        ov:SetFrameLevel((healthBar.GetFrameLevel and healthBar:GetFrameLevel() or 1) + 5)
        ov:EnableMouse(false)
        ov:Hide()

        -- OnSizeChanged: WoW redimensiona el nameplate al seleccionar/deseleccionar.
        -- El spark de absorción usa offset en píxeles; hay que recalcular con el nuevo ancho.
        -- Guarda npState[unit]: los nameplates se reciclan; si la unidad ya no está
        -- activa (HideUnit la borró), no re-aplicar con el token antiguo.
        if not healthBar._harfordNativeHooked then
            healthBar._harfordNativeHooked = true
            healthBar:HookScript("OnSizeChanged", function()
                if unit and NpEnabled() and npState[unit] then
                    API.ApplyUnit(unit)
                end
            end)
        end

        ov.bg = ov:CreateTexture(nil, "BACKGROUND")
        ov.bg:SetAllPoints(ov)
        ov.bg:SetColorTexture(0.02, 0.02, 0.02, 1.0)

        ov.hpBar = CreateFrame("StatusBar", nil, ov)
        ov.hpBar:SetStatusBarTexture(GetTex())
        ov.hpBar:SetFrameLevel(ov:GetFrameLevel() + 1)
        ov.hpBar:EnableMouse(false)

        ov.sep = ov:CreateTexture(nil, "BORDER")
        ov.sep:SetColorTexture(0, 0, 0, 1)
        ov.sep:SetHeight(1)

        ov.resBar = CreateFrame("StatusBar", nil, ov)
        ov.resBar:SetStatusBarTexture(GetTex())
        ov.resBar:SetFrameLevel(ov:GetFrameLevel() + 1)
        ov.resBar:EnableMouse(false)

        ov.tempBar = CreateFrame("StatusBar", nil, ov)
        ov.tempBar:SetStatusBarTexture(GetAbsorbTex(false))
        local tempTex = ov.tempBar:GetStatusBarTexture()
        if tempTex and tempTex.SetHorizTile then tempTex:SetHorizTile(false) end
        if tempTex and tempTex.SetVertTile then tempTex:SetVertTile(false) end
        ov.tempBar:SetStatusBarColor(0.30, 0.78, 1.00, 0.85)
        ov.tempBar:SetFrameLevel(ov:GetFrameLevel() + 2)
        ov.tempBar:EnableMouse(false)
        ov.tempBar:Hide()

        st.ov    = ov
        st.isKui = false
    end

    local np = nameplate  -- para claridad
    local _ = np  -- suprimir warning

    local maxHp = math.max(tonumber(hpData.max) or 0, 0)
    local curHp = math.min(math.max(tonumber(hpData.cur) or 0, 0), maxHp > 0 and maxHp or 1)
    st.ov.hpBar:SetMinMaxValues(0, maxHp > 0 and maxHp or 1)
    st.ov.hpBar:SetValue(curHp)
    -- Color de clase TRP3 → clase WoW nativa → verde salud (NPC).
    local hpR, hpG, hpB = GetNpClassColor(unit)
    st.ov.hpBar:SetStatusBarColor(hpR, hpG, hpB)

    local resData = list[2]
    if resData then
        local maxRes = math.max(tonumber(resData.max) or 0, 0)
        local curRes = math.min(math.max(tonumber(resData.cur) or 0, 0), maxRes > 0 and maxRes or 1)
        local r, g, b = ResourceColor(resData.key)
        st.ov.resBar:SetMinMaxValues(0, maxRes > 0 and maxRes or 1)
        st.ov.resBar:SetValue(curRes)
        st.ov.resBar:SetStatusBarColor(r, g, b)
    end

    LayoutNormal(st.ov, resData ~= nil)

    -- Vida temporal
    if st.ov.tempBar then
        local tempCur = math.max(tonumber(hpData.tempCur) or 0, 0)
        ApplyAbsorbTexture(st.ov.tempBar, st.ov.hpBar, curHp, maxHp, tempCur, 0.85)
    end

    st.ov:Show()
end

local function HideUnit(unit)
    local st = npState[unit]
    if st then
        -- Restaurar alpha del NameText de Kui antes de ocultar (puede haberse puesto a 0).
        if st.kuiFrame then
            local nt = st.kuiFrame.NameText
            if nt and nt.SetAlpha then nt:SetAlpha(1) end
            if nt and nt.SetParent and nt:GetParent() ~= st.kuiFrame then
                nt:SetParent(st.kuiFrame)
                if st.kuiFrame.UpdateNameTextPosition then
                    st.kuiFrame:UpdateNameTextPosition()
                end
            end
        end
        if st.ov then st.ov:Hide() end
        npState[unit] = nil
    end
end

local function RefreshAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, np in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = np.namePlateUnitToken
        if unit then API.ApplyUnit(unit) end
    end
end

-- ── Plugin API de Kui ──────────────────────────────────────────────────────────
-- Diferido a PLAYER_LOGIN: Kui puede no estar inicializado en tiempo de carga del TOC.
-- Si Kui no existe en ningún momento, el bloque es no-op completo.

local function TryRegisterKuiPlugin()
    if kuiPluginRegistered then return end
    if not IsKuiActive() then return end
    if type(KuiNameplates.NewPlugin) ~= "function" then return end
    local ok, mod = pcall(function()
        return KuiNameplates:NewPlugin("HarfordDnD", 200)
    end)
    if not ok or not mod or type(mod.RegisterMessage) ~= "function" then return end
    kuiPluginRegistered = true
    function mod:Initialise()
        self:RegisterMessage("Show")
        self:RegisterMessage("Hide")
        self:RegisterMessage("HealthUpdate")
        self:RegisterMessage("HealthColourChange")
        self:RegisterMessage("GainedTarget")
        self:RegisterMessage("LostTarget")
    end
    local function RefreshFrame(f)
        local unit = f and f.unit
        if unit and NpEnabled() then API.ApplyUnit(unit) end
    end
    function mod:Show(f)
        RefreshFrame(f)
    end
    function mod:Hide(f)
        local unit = f and f.unit
        if unit then
            HideUnit(unit)
        end
    end
    mod.HealthUpdate = RefreshFrame
    mod.HealthColourChange = RefreshFrame
    mod.GainedTarget = RefreshFrame
    mod.LostTarget = RefreshFrame

    -- Si Harford registra el plugin durante PLAYER_LOGIN despues de que Kui ya haya
    -- inicializado su lista, hay que activar este plugin manualmente.
    if type(mod.Initialise) == "function" then mod:Initialise() end
    if type(mod.Enable) == "function" then mod:Enable() end
end

-- ── API pública ────────────────────────────────────────────────────────────────

API.RefreshAll = RefreshAll

-- ── Eventos ────────────────────────────────────────────────────────────────────

local npEvents = CreateFrame("Frame")
npEvents:RegisterEvent("NAME_PLATE_UNIT_ADDED")
npEvents:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
npEvents:RegisterEvent("PLAYER_LOGIN")
npEvents:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        API.ApplyUnit(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        HideUnit(unit)
    elseif event == "PLAYER_LOGIN" then
        -- Intentar registrar el plugin de Kui ahora que todos los addons están cargados.
        TryRegisterKuiPlugin()
        if NpEnabled() then SetKuiClassPowersSuppressed(true) end
    end
end)

-- ── Config listener ────────────────────────────────────────────────────────────

if HarfordConfig and HarfordConfig.RegisterChangeListener then
    HarfordConfig.RegisterChangeListener(function()
        if NpEnabled() then
            SetKuiClassPowersSuppressed(true)
            RefreshAll()
        else
            for unit, st in pairs(npState) do
                HideUnit(unit)
            end
            SetKuiClassPowersSuppressed(false)
        end
    end)
end
