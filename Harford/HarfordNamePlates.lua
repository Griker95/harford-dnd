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
            frame._harfordAbsorbSpark:SetPoint("CENTER", frame, "LEFT", realW * pct + 2, 0)
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

-- Color de clase para health bar y etiqueta de nombre.
-- Orden: HarfordUnitFrames (TRP3 → cache → WoW class) → WoW class nativo → verde salud.
local function GetNpClassColor(unit)
    if not unit then return 0.0, 0.82, 0.08 end
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

    -- Etiqueta del nombre encima de las barras, coloreada por clase TRP3.
    -- Se ancla al BOTTOM del nameLabel → TOP del overlay, por lo que queda en el espacio
    -- sobre las barras de HP+recurso sin solaparse con el fill.
    ov.nameLabel = ov:CreateFontString(nil, "OVERLAY")
    ov.nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    ov.nameLabel:SetPoint("BOTTOM", ov, "TOP", 0, 1)
    ov.nameLabel:SetJustifyH("CENTER")
    ov.nameLabel:SetTextColor(1, 1, 1, 1)
    ov.nameLabel:Hide()

    return ov
end

-- ── Posicionamiento por modo ───────────────────────────────────────────────────

local function ApplyNormalMode(ov, kuiFrame, healthBar, hpData, resData)
    -- Frame level ALTO para tapar la barra nativa
    ov:SetFrameLevel((kuiFrame.GetFrameLevel and kuiFrame:GetFrameLevel() or 1) + 5)
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

    -- Etiqueta del nombre sobre las barras, con color de clase TRP3.
    if ov.nameLabel then
        local name = (unit and UnitName and UnitName(unit)) or ""
        ov.nameLabel:SetText(name)
        ov.nameLabel:SetTextColor(hpR, hpG, hpB, 1)
        ov.nameLabel:Show()
    end

    ov:Show()
end

local function ApplyNameOnlyMode(ov, kuiFrame, hpData)
    local nt = kuiFrame.NameText
    if not nt then ov:Hide() ; return end

    -- Frame level BAJO: el NameText (en OVERLAY del kuiFrame) queda encima del fill.
    local targetLevel = math.max(1, (kuiFrame.GetFrameLevel and kuiFrame:GetFrameLevel() or 2) - 1)
    ov:SetFrameLevel(targetLevel)
    -- Fijar también el hpBar explícitamente: cambia cuando ov cambia de nivel.
    ov.hpBar:SetFrameLevel(targetLevel + 1)

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
    -- En name-only el fill ya colorea el nombre; la etiqueta extra quedaría redundante.
    if ov.nameLabel then ov.nameLabel:Hide() end
    ov:Show()
end

-- ── Hooks por frame físico ─────────────────────────────────────────────────────

local function SetupKuiHooks(kuiFrame, healthBar)
    if healthBar._harfordHooked then return end
    healthBar._harfordHooked = true

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
    local kui = IsKuiActive() and rawget(nameplate, "kui")
    if kui then
        local healthBar = kui.HealthBar or kui.healthBar
        if not healthBar then return end

        if not st then st = {} ; npState[unit] = st end
        if not st.ov then
            st.ov      = CreateKuiOverlay(kui)
            st.kuiFrame = kui
        end

        SetupKuiHooks(kui, healthBar)

        if kui.IN_NAMEONLY then
            ApplyNameOnlyMode(st.ov, kui, hpData)
        else
            if healthBar:IsShown() then
                ApplyNormalMode(st.ov, kui, healthBar, hpData, list[2])
            else
                st.ov:Hide()
            end
        end
        return
    end

    -- ── Nativo WoW (sin Kui) ──────────────────────────────────────────────────
    local healthBar = FindNativeHealthBar(nameplate)
    if not healthBar then return end

    if not st then st = {} ; npState[unit] = st end
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

        st.ov = ov
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

if IsKuiActive() and type(KuiNameplates.NewPlugin) == "function" then
    local ok, mod = pcall(function()
        return KuiNameplates:NewPlugin("HarfordDnD", 200)
    end)
    if ok and mod and type(mod.RegisterMessage) == "function" then
        function mod:Initialise()
            self:RegisterMessage("Show")
            self:RegisterMessage("Hide")
        end
        function mod:Show(f)
            local unit = f and f.unit
            if unit and NpEnabled() then API.ApplyUnit(unit) end
        end
        function mod:Hide(f)
            local unit = f and f.unit
            if unit then
                local st = npState[unit]
                if st and st.ov then st.ov:Hide() end
            end
        end
    end
end

-- ── API pública ────────────────────────────────────────────────────────────────

API.RefreshAll = RefreshAll

-- ── Eventos ────────────────────────────────────────────────────────────────────

local npEvents = CreateFrame("Frame")
npEvents:RegisterEvent("NAME_PLATE_UNIT_ADDED")
npEvents:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
npEvents:SetScript("OnEvent", function(_, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        API.ApplyUnit(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        HideUnit(unit)
    end
end)

-- ── Config listener ────────────────────────────────────────────────────────────

if HarfordConfig and HarfordConfig.RegisterChangeListener then
    HarfordConfig.RegisterChangeListener(function()
        if NpEnabled() then
            RefreshAll()
        else
            for unit, st in pairs(npState) do
                if st.ov then st.ov:Hide() end
                npState[unit] = nil
            end
        end
    end)
end
