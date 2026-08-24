-- Pestana FICHA del panel de personaje: el paperdoll estilo CharacterFrame, sus tres vistas
-- laterales (resumen / habilidades / detalles) y el refresco de todas sus filas.
--
-- Sale de HarfordCharacterPanel.lua porque era la mitad del fichero -- 1853 lineas -- y solo tenia
-- DOS llamadas desde fuera. Todo lo que no usa nadie mas (calculos de habilidad y salvacion,
-- tooltips de clase, filas de la ficha) se viene aqui; lo compartido se inyecta con `Init`.
--
-- Mantiene el contrato del panel: geometria y texturas salen de las capturas del probe, no se
-- clonan scripts ni eventos del CharacterFrame vivo.

HarfordCharacterSheet = HarfordCharacterSheet or {}

-- Estado y constantes del panel, mas los ayudantes compartidos. Inyectados por HarfordCharacterPanel.
local S, K, API
local AbilityBaseAndBonus, GetClassColorParts, GetInspectSnapshot, GetPrimaryClassId, RawSigned
local AbilityMod, AbilityScore, ColorSigned, CreateButton, CreateFS, GetBackgroundLabel, GetClassFeatureRows, GetClassParts, GetClassSummary, GetFeatsLabel, GetPortraitUnit, GetProfileName, GetProfileValue, GetProgression, GetRaceLabel, GetTRP3FeatureRows, IsInspecting, Print, RefreshGameUI, RefreshPanel, RefreshRaceModelBackground, SetColoredTextList, SetTexCoord8, Signed, TooltipLines

function HarfordCharacterSheet.Init(deps)
    deps = deps or {}
    S = deps.S or S
    K = deps.K or K
    API = deps.API or API
    AbilityBaseAndBonus = deps.AbilityBaseAndBonus or AbilityBaseAndBonus
    GetClassColorParts = deps.GetClassColorParts or GetClassColorParts
    GetInspectSnapshot = deps.GetInspectSnapshot or GetInspectSnapshot
    GetPrimaryClassId = deps.GetPrimaryClassId or GetPrimaryClassId
    RawSigned = deps.RawSigned or RawSigned
    AbilityMod = deps.AbilityMod or AbilityMod
    AbilityScore = deps.AbilityScore or AbilityScore
    ColorSigned = deps.ColorSigned or ColorSigned
    CreateButton = deps.CreateButton or CreateButton
    CreateFS = deps.CreateFS or CreateFS
    GetBackgroundLabel = deps.GetBackgroundLabel or GetBackgroundLabel
    GetClassFeatureRows = deps.GetClassFeatureRows or GetClassFeatureRows
    GetClassParts = deps.GetClassParts or GetClassParts
    GetClassSummary = deps.GetClassSummary or GetClassSummary
    GetFeatsLabel = deps.GetFeatsLabel or GetFeatsLabel
    GetPortraitUnit = deps.GetPortraitUnit or GetPortraitUnit
    GetProfileName = deps.GetProfileName or GetProfileName
    GetProfileValue = deps.GetProfileValue or GetProfileValue
    GetProgression = deps.GetProgression or GetProgression
    GetRaceLabel = deps.GetRaceLabel or GetRaceLabel
    GetTRP3FeatureRows = deps.GetTRP3FeatureRows or GetTRP3FeatureRows
    IsInspecting = deps.IsInspecting or IsInspecting
    Print = deps.Print or Print
    RefreshGameUI = deps.RefreshGameUI or RefreshGameUI
    RefreshPanel = deps.RefreshPanel or RefreshPanel
    RefreshRaceModelBackground = deps.RefreshRaceModelBackground or RefreshRaceModelBackground
    SetColoredTextList = deps.SetColoredTextList or SetColoredTextList
    SetTexCoord8 = deps.SetTexCoord8 or SetTexCoord8
    Signed = deps.Signed or Signed
    TooltipLines = deps.TooltipLines or TooltipLines
end

local function SlotLabelES(key)
    return K.PAPERDOLL_SLOT_LABELS_ES[tostring(key or "")] or tostring(key or "")
end

local function AbilityTooltipTitle(key)
    -- `bonus` es solo el bono/penalizacion LIVE (estado/objeto): los modificadores de
    -- raza/trasfondo ya estan horneados en la puntuacion de la ficha cargada y no se
    -- muestran aqui. Se colorea verde (positivo) / rojo (negativo).
    --
    -- El parentesis NO es solo la puntuacion repetida: es el unico sitio donde se ve ese
    -- bono live. Por eso se conserva.
    local base, bonus = AbilityBaseAndBonus(key)
    if bonus ~= 0 then
        local color = bonus > 0 and "ff40ff40" or "ffff4040"
        return key .. " (" .. tostring(base) .. "|c" .. color .. RawSigned(bonus) .. "|r)"
    end
    return key .. " (" .. tostring(base) .. ")"
end

local function RefreshSubtitleClasses(SH, data)
    if not SH then return end
    local parts = GetClassParts(data)
    if not parts then
        if SH.subtitle then
            SH.subtitle:SetText("Sin clase")
            SH.subtitle:SetTextColor(1, 0.82, 0)
            SH.subtitle:Show()
        end
        return
    end

    if SH.subtitle then SH.subtitle:Hide() end
    SetColoredTextList(SH.page or S.frame, SH, "subtitleClassTexts", parts, { font = "GameFontNormal" })

    local gap = 10
    local maxWidth = 320
    local total = 0
    for i, fs in ipairs(SH.subtitleClassTexts or {}) do
        if i <= #parts then
            fs:SetWidth(1000)
            if fs.SetWordWrap then fs:SetWordWrap(false) end
            total = total + (fs:GetStringWidth() or 0)
            if i > 1 then total = total + gap end
        end
    end

    if total <= maxWidth then
        local x = -total / 2
        for i, fs in ipairs(SH.subtitleClassTexts or {}) do
            if i <= #parts then
                local w = fs:GetStringWidth() or 0
                fs:SetWidth(w)
                fs:SetPoint("TOPLEFT", SH.page or S.frame, "TOP", x, -36)
                x = x + w + gap
            end
        end
    else
        local yOffset = 0
        for i, fs in ipairs(SH.subtitleClassTexts or {}) do
            if i <= #parts then
                fs:SetWidth(maxWidth)
                fs:SetJustifyH("CENTER")
                if fs.SetWordWrap then fs:SetWordWrap(true) end
                if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
                fs:SetPoint("TOP", SH.page or S.frame, "TOP", 0, -34 - yOffset)
                local h = 14
                if fs.GetStringHeight then
                    h = math.max(h, math.ceil(fs:GetStringHeight() or h))
                end
                yOffset = yOffset + h
            end
        end
    end
end

local function GetClassInfoAtlas(data)
    local harfordAtlas = K.CLASS_INFO_ATLAS[GetPrimaryClassId(data)]
    if harfordAtlas then return harfordAtlas end
    if UnitClass then
        local _, classFile = UnitClass("player")
        local nativeAtlas = classFile and K.CLASS_FILE_TO_ATLAS[classFile]
        if nativeAtlas then return nativeAtlas end
    end
    return "UI-Character-Info-Warrior-BG"
end

local function ApplyAtlasOrTexture(texture, atlas, fallback)
    if not texture then return false end
    if atlas and texture.SetAtlas then
        local ok = pcall(texture.SetAtlas, texture, atlas)
        if ok then return true end
    end
    if fallback then
        texture:SetTexture(fallback)
        return true
    end
    return false
end

local function RefreshPaperDollSlots(sheet)
    if not (sheet and sheet.slots) then return end
    for _, slot in ipairs(sheet.slots) do
        if slot.icon then
            local texture = nil
            local equipped = HarfordDnDItems and HarfordDnDItems.ResolveSlot
                and HarfordDnDItems.ResolveSlot(slot.harfordSlotKey or slot.slotToken, GetProfileName())
            if equipped and equipped.icon then
                texture = equipped.icon
            else
                local basicInfo
                if HarfordDnDItems and HarfordDnDItems.GetBasicWeaponInfo then
                    basicInfo = HarfordDnDItems.GetBasicWeaponInfo(slot.harfordSlotKey or slot.slotToken, GetProfileName())
                end
                if not basicInfo and HarfordDnDItems and HarfordDnDItems.GetBasicArmorInfo then
                    basicInfo = HarfordDnDItems.GetBasicArmorInfo(slot.harfordSlotKey or slot.slotToken, GetProfileName())
                end
                texture = basicInfo and basicInfo.icon or slot.emptyTexture
                if slot.slotToken and GetInventorySlotInfo then
                    local _, nativeTexture = GetInventorySlotInfo(slot.slotToken)
                    if not basicInfo then texture = nativeTexture or texture end
                end
            end
            slot.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            slot.icon:SetTexCoord(0, 1, 0, 1)
            slot.icon:SetVertexColor(1, 1, 1, 0.88)
            slot.icon:Show()
        end
    end
end

local function CreateFramePage(key)
    local page = CreateFrame("Frame", nil, S.frame)
    page:SetAllPoints(S.frame)
    S.pages[key] = page
    return page
end

-- Lee un recurso (cur/max) del runtime via contexto.
local function ResourceValue(suffixKey)
    if IsInspecting() then
        local snap = GetInspectSnapshot()
        local resources = snap and snap.resources
        if not resources and HarfordDnDResources and HarfordDnDResources.RemoteCache then
            resources = HarfordDnDResources.RemoteCache[GetProfileName()]
        end
        return tonumber(resources and resources[suffixKey] or 0) or 0
    end
    return tonumber(GetProfileValue(suffixKey, 0)) or 0
end

-- Borde interior NineSlice nativo (atlas UI-Frame-Inner* del CharacterFrameInset).
-- Dibuja las 4 esquinas (tamaño de atlas) y los 4 bordes tileados alrededor de 'frame'.
local function MakeInnerBorder(frame)
    local function tex()
        local t = frame:CreateTexture(nil, "BORDER")
        return t
    end
    local function atlas(t, name, useSize)
        if t.SetAtlas then pcall(t.SetAtlas, t, name, useSize and true or false) end
    end
    local tl = tex(); atlas(tl, "UI-Frame-InnerTopLeft", true); tl:SetPoint("TOPLEFT")
    local tr = tex(); atlas(tr, "UI-Frame-InnerTopRight", true); tr:SetPoint("TOPRIGHT")
    local bl = tex(); atlas(bl, "UI-Frame-InnerBotLeftCorner", true); bl:SetPoint("BOTTOMLEFT")
    local br = tex(); atlas(br, "UI-Frame-InnerBotRight", true); br:SetPoint("BOTTOMRIGHT")
    -- Tiras de borde: grosor fijo (3px como el nativo, 256x3 / 3x256); el eje que abarca
    -- lo fijan los anclajes entre esquinas. SIN tamaño transversal salian estiradas/grises.
    local top = tex(); atlas(top, "_UI-Frame-InnerTopTile", true)
    top:SetHeight(3)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0); top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    if top.SetHorizTile then top:SetHorizTile(true) end
    local bot = tex(); atlas(bot, "_UI-Frame-InnerBotTile", true)
    bot:SetHeight(3)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    if bot.SetHorizTile then bot:SetHorizTile(true) end
    local lft = tex(); atlas(lft, "!UI-Frame-InnerLeftTile", true)
    lft:SetWidth(3)
    lft:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0); lft:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    if lft.SetVertTile then lft:SetVertTile(true) end
    local rgt = tex(); atlas(rgt, "!UI-Frame-InnerRightTile", true)
    rgt:SetWidth(3)
    rgt:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0); rgt:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    if rgt.SetVertTile then rgt:SetVertTile(true) end
end

local function MakePaperDollInnerBorder(parent)
    local function part(name, file, coords, w, h)
        local t = parent:CreateTexture(name, "ARTWORK")
        t:SetTexture(file)
        SetTexCoord8(t, coords)
        t:SetSize(w, h)
        return t
    end
    local parts = "Interface\\CharacterFrame\\Char-Paperdoll-Parts"
    local vertical = "Interface\\CharacterFrame\\Char-Paperdoll-Vertical"
    local horizontal = "Interface\\CharacterFrame\\Char-Paperdoll-Horizontal"
    local tl = part(nil, parts, { 0.40625, 0.8046875, 0.40625, 0.859375, 0.43359375, 0.8046875, 0.43359375, 0.859375 }, 7, 7)
    tl:SetPoint("TOPLEFT", parent, "TOPLEFT", 46, -4)
    local tr = part(nil, parts, { 0.40625, 0.734375, 0.40625, 0.7890625, 0.43359375, 0.734375, 0.43359375, 0.7890625 }, 7, 7)
    tr:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -47, -4)
    local bl = part(nil, parts, { 0.40625, 0.6640625, 0.40625, 0.71875, 0.43359375, 0.6640625, 0.43359375, 0.71875 }, 7, 7)
    bl:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 46, 31)
    local br = part(nil, parts, { 0.40625, 0.59375, 0.40625, 0.6484375, 0.43359375, 0.59375, 0.43359375, 0.6484375 }, 7, 7)
    br:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -47, 31)
    local left = part(nil, vertical, { 0.0625, 0, 0.0625, 1, 0.375, 0, 0.375, 1 }, 5, 32)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", -1, 0)
    left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", -1, 0)
    if left.SetVertTile then left:SetVertTile(true) end
    local right = part(nil, vertical, { 0.5, 0, 0.5, 1, 0.8125, 0, 0.8125, 1 }, 5, 32)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 1, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 1, 0)
    if right.SetVertTile then right:SetVertTile(true) end
    local top = part(nil, horizontal, { 0, 0.5, 0, 0.8125, 1, 0.5, 1, 0.8125 }, 32, 5)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 1)
    top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 1)
    if top.SetHorizTile then top:SetHorizTile(true) end
    local bottom = part(nil, horizontal, { 0, 0.0625, 0, 0.375, 1, 0.0625, 1, 0.375 }, 32, 5)
    bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, -1)
    bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, -1)
    if bottom.SetHorizTile then bottom:SetHorizTile(true) end
end

local function CreateSidebarTabs(parent)
    local tabs = CreateFrame("Frame", nil, parent)
    tabs:SetSize(168, 35)
    tabs:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", -6, -1)
    tabs.buttons = {}
    local texFile = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs"

    local top = tabs:CreateTexture(nil, "BACKGROUND")
    top:SetTexture(texFile)
    SetTexCoord8(top, K.SBTAB_TC.TOP)
    top:SetSize(28, 11)
    top:SetPoint("BOTTOMLEFT", tabs, "BOTTOMLEFT", 0, 0)

    local bottom = tabs:CreateTexture(nil, "BACKGROUND")
    bottom:SetTexture(texFile)
    SetTexCoord8(bottom, K.SBTAB_TC.BOTTOM)
    bottom:SetSize(28, 13)
    bottom:SetPoint("BOTTOMRIGHT", tabs, "BOTTOMRIGHT", 0, 0)

    local function selectView(key)
        if S.sheetView ~= key and HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("character_sidebar_tab_changed")
        end
        S.sheetView = key
        RefreshPanel()
    end
    -- bodyKind: tabla de texCoords (icono baked) o "portrait" (retrato del jugador).
    local function makeTab(key, bodyKind, anchorTo)
        local b = CreateFrame("Button", nil, tabs)
        b:SetSize(33, 35)
        if anchorTo then
            b:SetPoint("RIGHT", anchorTo, "LEFT", -4, 0)
        else
            b:SetPoint("BOTTOMRIGHT", tabs, "BOTTOMRIGHT", -30, 0)
        end
        b:EnableMouse(true)
        b:SetScript("OnClick", function() selectView(key) end)

        -- Fondo nativo de la pestana (50x43). La seleccion cambia este mismo
        -- recorte de GLOW a ACTIVE_BG; no usa una capa ni un marco adicional.
        local glow = b:CreateTexture(nil, "BACKGROUND")
        glow:SetTexture(texFile)
        SetTexCoord8(glow, K.SBTAB_TC.GLOW)
        glow:SetSize(50, 43)
        glow:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", -9, -2)

        -- Cuerpo (icono 33x34 o retrato).
        local body = b:CreateTexture(nil, "ARTWORK")
        if bodyKind == "portrait" then
            body:SetSize(29, 31)
            body:SetPoint("BOTTOM", b, "BOTTOM", 1, 0)
            body:SetTexCoord(0.109375, 0.890625, 0.09375, 0.90625)
            tabs.portrait = body
        else
            body:SetSize(33, 35)
            body:SetPoint("BOTTOM", b, "BOTTOM", 1, -2)
            body:SetTexture(texFile)
            SetTexCoord8(body, bodyKind)
        end

        -- Separador inferior nativo (34x19).
        local divider = b:CreateTexture(nil, "OVERLAY")
        divider:SetTexture(texFile)
        SetTexCoord8(divider, K.SBTAB_TC.DIVIDER)
        divider:SetSize(34, 19)
        divider:SetPoint("BOTTOM", b, "BOTTOM", 0, 0)

        -- El probe del PaperDollSidebarTab nativo confirma capa HIGHLIGHT y mezcla BLEND.
        local hilite = b:CreateTexture(nil, "HIGHLIGHT")
        hilite:SetTexture(texFile)
        SetTexCoord8(hilite, K.SBTAB_TC.HILITE)
        hilite:SetSize(31, 31)
        hilite:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -3)
        hilite:Hide()

        b.body = body
        b.background = glow
        b.hover = hilite
        b.tooltipText = K.SBTAB_TOOLTIP[key]
        b:SetScript("OnEnter", function(self)
            if not self.selected and self.hover then
                self.hover:Show()
            end
            if self.tooltipText and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tooltipText, 1, 0.82, 0)
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function(self)
            if self.hover then
                self.hover:Hide()
            end
            if GameTooltip then GameTooltip:Hide() end
        end)
        tabs.buttons[key] = b
        return b
    end

    -- Orden nativo (derecha a izquierda): details, skills, summary(retrato).
    local details = makeTab("details", K.SBTAB_TC.ICON3)
    local skills = makeTab("skills", K.SBTAB_TC.ICON2, details)
    makeTab("summary", "portrait", skills)

    function tabs:SetSelected(key)
        for viewKey, button in pairs(self.buttons) do
            local selected = (viewKey == key)
            button.selected = selected
            button:SetAlpha(1)
            SetTexCoord8(button.background, selected and K.SBTAB_TC.ACTIVE_BG or K.SBTAB_TC.GLOW)
            if button.hover then button.hover:Hide() end
        end
    end
    return tabs
end

-- Crea la pagina de Ficha con estilo del panel de personaje nativo.
-- Las coordenadas base salen de CharacterFrame/PaperDollFrame medidos con
-- /harford debug run probeframe CharacterFrame y FrameDump.lua, no de ajustes a ojo.
local function CreateSheetPage()
    local page = CreateFramePage("sheet")
    local SH = {}
    S.sheet = SH
    SH.page = page

    -- CharacterFrameInset: TOPLEFT CharacterFrame 4,-60; BOTTOMRIGHT
    -- CharacterFrame BOTTOMLEFT 332,4. Este bloque mantiene el mismo hueco que
    -- el PaperDoll nativo para modelo y slots.
    local leftInset = CreateFrame("Frame", nil, page)
    leftInset:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -60)
    leftInset:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", 332, 4)
    local lbg = leftInset:CreateTexture(nil, "BACKGROUND")
    lbg:SetAllPoints(leftInset)
    lbg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", true, true)
    if lbg.SetHorizTile then lbg:SetHorizTile(true) end
    if lbg.SetVertTile then lbg:SetVertTile(true) end
    MakeInnerBorder(leftInset)
    SH.leftInset = leftInset

    -- Subtitulo superior del paperdoll. Se alimenta con progresion Harford, pero
    -- usa posicion/fuente de cabecera nativa.
    SH.subtitle = CreateFS(page, "GameFontNormal", "")
    SH.subtitle:SetPoint("TOP", page, "TOP", 0, -36)
    SH.subtitle:SetWidth(320)
    SH.subtitle:SetJustifyH("CENTER")
    SH.subtitle:SetTextColor(1, 0.82, 0)

    -- ===== Huecos de equipo (anclados al inset, posiciones exactas del nativo) =====
    local function MakeSlot(parent, key)
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(37, 37)
        b.harfordSlotKey = key
        b.nativeName = K.PAPERDOLL_SLOT_NAMES[key]
        b.slotToken = K.PAPERDOLL_SLOT_TOKENS[key]
        local frame = b:CreateTexture(nil, "BACKGROUND", nil, -1)
        frame:SetTexture("Interface\\CharacterFrame\\Char-Paperdoll-Parts")
        SetTexCoord8(frame, { 0.20703125, 0.59375, 0.20703125, 0.9375, 0.3984375, 0.59375, 0.3984375, 0.9375 })
        frame:SetSize(49, 44)
        frame:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 0)
        local fill = b:CreateTexture(nil, "BORDER", nil, -2)
        fill:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
        fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
        fill:SetColorTexture(0.015, 0.014, 0.012, 0.25)
        local bevel = b:CreateTexture(nil, "BORDER", nil, -1)
        bevel:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1)
        bevel:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", -1, 1)
        bevel:SetColorTexture(0.18, 0.18, 0.16, 0.08)
        local icon = b:CreateTexture(nil, "BORDER")
        icon:SetAllPoints(b)
        if GetInventorySlotInfo and b.slotToken then
            local _, nativeTexture = GetInventorySlotInfo(b.slotToken)
            b.emptyTexture = nativeTexture
            icon:SetTexture(nativeTexture)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetVertexColor(1, 1, 1, 0.88)
        if icon.SetDesaturated then pcall(icon.SetDesaturated, icon, false) end
        icon:Show()
        b.icon = icon
        local function makeBasicSelector()
            local isWeaponSlot = key == "MainHand" or key == "SecondaryHand"
            local isArmorSlot = key == "Chest"
            if not (isWeaponSlot or isArmorSlot) then return end

            -- FLECHA: plantilla del propio cliente, la misma que usa el PaperDollFrame nativo
            -- (`PaperDollFrame.xml` la declara como `$parentPopoutButton`). Asi sale la flecha
            -- amarilla de verdad y no una aproximacion. Si no existiese, se cae al arte de chat
            -- que habia antes, que al menos se ve.
            -- Medidas EXACTAS del nativo. El template `EquipmentFlyoutPopoutButtonTemplate`
            -- nace 16x32 anclado LEFT->RIGHT, pero `PaperDollItemSlotButton_OnLoad` lo
            -- reconfigura para cada hueco: en la orientacion horizontal queda 16 de ancho x38
            -- de alto, en `LEFT -> hueco.RIGHT (-8, 0)` -metido 8px SOBRE el hueco- y con unos
            -- texCoords de OCHO argumentos que giran la flecha. Con 14x14 en la esquina, que
            -- es lo que habia, no se parecia ni se veia.
            -- Las manos usan la orientacion VERTICAL del nativo: la flecha va DEBAJO del
            -- hueco y apunta hacia abajo. El pecho usa la horizontal, a su derecha.
            local esVertical = isWeaponSlot
            local arrow = CreateFrame("Button", nil, b)
            if esVertical then
                arrow:SetSize(38, 16)
                arrow:SetPoint("TOP", b, "BOTTOM", 0, 4)
            else
                arrow:SetSize(16, 38)
                -- DESVIACION del nativo, que la mete 8px SOBRE el hueco (`-8`). En el paperdoll
                -- de Blizzard hay sitio a la derecha; en el nuestro la columna izquierda va pegada
                -- al modelo y con -8 la flecha mordia el icono. -4 es el punto medio ajustado a ojo
                -- sobre la ventana real.
                arrow:SetPoint("LEFT", b, "RIGHT", -4, 0)
            end
            arrow:SetFrameLevel((b:GetFrameLevel() or 1) + 5)
            local flechaNormal = arrow:CreateTexture(nil, "ARTWORK")
            flechaNormal:SetAllPoints(arrow)
            flechaNormal:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-FlyoutButton")
            arrow:SetNormalTexture(flechaNormal)
            local flechaHl = arrow:CreateTexture(nil, "HIGHLIGHT")
            flechaHl:SetAllPoints(arrow)
            flechaHl:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-FlyoutButton")
            arrow:SetHighlightTexture(flechaHl)

            -- `EquipmentFlyoutPopoutButton_SetReversed`: al abrirse, la flecha se da la
            -- vuelta. Son los mismos ocho numeros con las dos mitades intercambiadas.
            -- Se usan las texturas que hemos creado, NO `GetNormalTexture()`: si eso devolviera
            -- otra cosa, el guard se lo tragaba en silencio y la flecha quedaba SIN texCoords,
            -- o sea con el fichero entero estirado a 16x38 -una banda amarilla en vez de la
            -- pestana-. Los ocho numeros son los de `EquipmentFlyoutPopoutButton_SetReversed`
            -- en su rama horizontal: definen las cuatro esquinas y giran el recorte 90 grados.
            -- Cada orientacion tiene SUS recortes. El vertical usa la forma normal de cuatro
            -- numeros -con arriba y abajo invertidos, que es lo que hace que apunte hacia
            -- abajo-; el horizontal usa la de ocho, que ademas gira el recorte 90 grados.
            local function OrientarFlecha(abierta)
                if esVertical then
                    if abierta then
                        flechaNormal:SetTexCoord(0.15625, 0.84375, 0, 0.5)
                        flechaHl:SetTexCoord(0.15625, 0.84375, 0.5, 1)
                    else
                        flechaNormal:SetTexCoord(0.15625, 0.84375, 0.5, 0)
                        flechaHl:SetTexCoord(0.15625, 0.84375, 1, 0.5)
                    end
                elseif abierta then
                    flechaNormal:SetTexCoord(0.15625, 0, 0.84375, 0, 0.15625, 0.5, 0.84375, 0.5)
                    flechaHl:SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 1, 0.84375, 1)
                else
                    flechaNormal:SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0)
                    flechaHl:SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5)
                end
            end
            OrientarFlecha(false)
            arrow:Show()

            -- Resaltado sobre el HUECO mientras su menu esta abierto: el nativo lo pinta con
            -- `UI-GearManager-ItemButton-Highlight` a 50x50 (EquipmentFlyoutFrame.Highlight).
            -- POR DETRAS del hueco, no encima. El nativo lo pinta en el frame del flyout, que
            -- monta a `itemButton:GetFrameLevel() - 1`: el resaltado asoma alrededor del hueco
            -- como un halo, y el icono y el borde quedan por delante. Puesto en OVERLAY tapaba
            -- las dos cosas y por eso se veia como un recuadro descuadrado encima.
            local resaltado = b:CreateTexture(nil, "BACKGROUND", nil, -3)
            resaltado:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-ItemButton-Highlight")
            resaltado:SetSize(50, 50)
            resaltado:SetPoint("CENTER", b, "CENTER", 0, 0)
            resaltado:Hide()

            -- Y la MISMA marca que lleva la pieza elegida dentro de la rejilla, sobre el icono
            -- del hueco de origen: mientras el menu esta abierto se ve de un vistazo de que
            -- hueco salio. Es la textura de los botones marcados (`CheckButtonHilight` en ADD),
            -- al tamano del icono, no del borde.
            local marcaOrigen = b:CreateTexture(nil, "OVERLAY", nil, 3)
            marcaOrigen:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            marcaOrigen:SetBlendMode("ADD")
            marcaOrigen:SetAllPoints(b)
            marcaOrigen:Hide()

            local function refreshAfterChoice()
                RefreshGameUI()
                RefreshPanel()
            end

            -- ── Reglas de que se puede poner en cada mano ──────────────────────────────────
            local offhand, mainhand = (key == "SecondaryHand"), (key == "MainHand")
            local function isTwoHanded(weapon)
                for _, p in ipairs(weapon.props or {}) do
                    if tostring(p) == "Dos manos" then return true end
                end
                return false
            end
            local function isAllowed(weapon)
                -- Desarmado no se ofrece: sin objeto ni arma basica ya cuentas como desarmado.
                if weapon.key == "Desarmado" then return false end
                local isShield = (weapon.key == "Escudo")
                if mainhand and isShield then return false end
                -- Mano secundaria: solo se excluyen las de DOS MANOS. Las de una mano valen,
                -- incluidas las a distancia (pistola, ballesta de mano) y el escudo.
                if offhand and not isShield and isTwoHanded(weapon) then return false end
                return true
            end

            local function GruposPermitidos()
                local fuera = {}
                if isArmorSlot then
                    for _, g in ipairs((HarfordDnDItems and HarfordDnDItems.GetArmorMenuGroups
                        and HarfordDnDItems.GetArmorMenuGroups()) or {}) do
                        if #(g.items or {}) > 0 then fuera[#fuera + 1] = g end
                    end
                    return fuera
                end
                for _, g in ipairs((HarfordDnDWeapons and HarfordDnDWeapons.GetWeaponMenuGroups
                    and HarfordDnDWeapons.GetWeaponMenuGroups()) or {}) do
                    local permitidas = {}
                    for _, w in ipairs(g.items or {}) do
                        if isAllowed(w) then permitidas[#permitidas + 1] = w end
                    end
                    if #permitidas > 0 then
                        fuera[#fuera + 1] = { key = g.key, text = g.text, items = permitidas }
                    end
                end
                return fuera
            end

            -- Una ruta que el cliente no tenga se pinta en verde chillon sin avisar.
            local function IconoSeguro(ruta, alternativa)
                if not GetFileIDFromPath then return ruta end
                if GetFileIDFromPath(ruta) then return ruta end
                return alternativa
            end

            local function IconoDe(pieza)
                if isArmorSlot then
                    return pieza.icon or "Interface\\Icons\\INV_Chest_Leather_09"
                end
                if HarfordDnDWeapons and HarfordDnDWeapons.GetIconPath then
                    return HarfordDnDWeapons.GetIconPath(pieza)
                end
                return "Interface\\Icons\\INV_Misc_QuestionMark"
            end

            local function Actual()
                if isArmorSlot then
                    return HarfordDnDItems and HarfordDnDItems.GetBasicArmor
                        and HarfordDnDItems.GetBasicArmor(key, GetProfileName())
                end
                return HarfordDnDItems and HarfordDnDItems.GetBasicWeapon
                    and HarfordDnDItems.GetBasicWeapon(key, GetProfileName())
            end

            local function Poner(claveElegida)
                if isArmorSlot then
                    if HarfordDnDItems and HarfordDnDItems.SetBasicArmor then
                        HarfordDnDItems.SetBasicArmor(key, claveElegida, GetProfileName())
                    end
                elseif HarfordDnDItems and HarfordDnDItems.SetBasicWeapon then
                    HarfordDnDItems.SetBasicWeapon(key, claveElegida, GetProfileName())
                end
                refreshAfterChoice()
            end

            -- REJILLA: replica del EquipmentFlyout nativo. Dos pasos -categorias y luego las
            -- piezas de la elegida-, porque el catalogo tiene 52 armas y una rejilla plana se
            -- desbordaria.
            --
            -- Constantes de `EquipmentFlyout.lua`: ITEMS_PER_ROW=5, EFITEM 37x37, XOFFSET=4,
            -- YOFFSET=-5 (paso vertical 42), BORDERWIDTH=3.
            local POR_FILA, LADO, BORDE, PASO_X, PASO_Y = 5, 37, 3, 41, 42

            -- El fondo NO es un marco generico: el nativo lo monta por piezas de
            -- `UI-GearManager-Flyout` con recortes distintos segun haya un solo hueco, una fila
            -- o varias. Estos son sus texCoords y medidas tal cual.
            local FLY_TEX = "Interface\\PaperDollInfoFrame\\UI-GearManager-Flyout"
            local UNO_IZQ = { 0, 0.09765625, 0.5546875, 0.77734375 }
            local UNO_DER = { 0.41796875, 0.51171875, 0.5546875, 0.77734375 }
            local UNO_IZQ_W, UNO_DER_W = 25, 24
            local FILA_IZQ = { 0, 0.16796875, 0.5546875, 0.77734375 }
            local FILA_CEN = { 0.16796875, 0.328125, 0.5546875, 0.77734375 }
            local FILA_DER = { 0.328125, 0.51171875, 0.5546875, 0.77734375 }
            local FILA_H, FILA_IZQ_W, FILA_CEN_W, FILA_DER_W = 54, 43, 41, 47
            local MULTI_ARR = { 0, 0.8359375, 0, 0.19140625 }
            local MULTI_MED = { 0, 0.8359375, 0.19140625, 0.35546875 }
            local MULTI_ABA = { 0, 0.8359375, 0.35546875, 0.546875 }
            local MULTI_W, MULTI_ARR_H, MULTI_MED_H, MULTI_ABA_H = 214, 49, 42, 49

            -- Cuelga de UIParent, NO del hueco: dentro del arbol del panel la rejilla quedaba
            -- por debajo del marco exterior, porque el NineSlice del panel es un frame hijo con
            -- nivel superior. FULLSCREEN_DIALOG es la strata de los desplegables sobre un dialogo.
            local flyout = CreateFrame("Frame", nil, UIParent)
            flyout:SetFrameStrata("FULLSCREEN_DIALOG")
            -- Como el nativo: en vertical la rejilla nace DEBAJO de la flecha
            -- (verticalAnchorX/Y = 0,0); en horizontal, a su derecha.
            if esVertical then
                flyout:SetPoint("TOPLEFT", arrow, "BOTTOMLEFT", 0, 0)
            else
                flyout:SetPoint("TOPLEFT", arrow, "TOPRIGHT", 0, 0)
            end
            flyout:Hide()
            flyout.botones = {}
            flyout.fondos = {}

            local function PiezaDeFondo(i)
                local t = flyout.fondos[i]
                if t then return t end
                t = flyout:CreateTexture(nil, "BACKGROUND")
                t:SetTexture(FLY_TEX)
                flyout.fondos[i] = t
                return t
            end

            -- Monta el fondo con las mismas piezas y en el mismo orden que
            -- `EquipmentFlyout_UpdateFlyout`. Todas arrancan en TOPLEFT (-5, +4) de la rejilla.
            local function MontarFondo(cuantos, filas)
                local usadas, ultima = 0, nil
                local function Pieza(coords, ancho, alto, anclaA, punto)
                    usadas = usadas + 1
                    local t = PiezaDeFondo(usadas)
                    t:ClearAllPoints()
                    t:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                    t:SetSize(ancho, alto)
                    if anclaA then
                        t:SetPoint("TOPLEFT", anclaA, punto or "TOPRIGHT", 0, 0)
                    else
                        t:SetPoint("TOPLEFT", flyout, "TOPLEFT", -5, 4)
                    end
                    t:Show()
                    ultima = t
                    return t
                end
                if cuantos == 1 then
                    Pieza(UNO_IZQ, UNO_IZQ_W, FILA_H)
                    Pieza(UNO_DER, UNO_DER_W, FILA_H, ultima)
                elseif cuantos <= POR_FILA then
                    Pieza(FILA_IZQ, FILA_IZQ_W, FILA_H)
                    for _ = 2, cuantos - 1 do
                        Pieza(FILA_CEN, FILA_CEN_W, FILA_H, ultima)
                    end
                    Pieza(FILA_DER, FILA_DER_W, FILA_H, ultima)
                else
                    Pieza(MULTI_ARR, MULTI_W, MULTI_ARR_H)
                    for _ = 2, filas - 1 do
                        Pieza(MULTI_MED, MULTI_W, MULTI_MED_H, ultima, "BOTTOMLEFT")
                    end
                    Pieza(MULTI_ABA, MULTI_W, MULTI_ABA_H, ultima, "BOTTOMLEFT")
                end
                for i = usadas + 1, #flyout.fondos do flyout.fondos[i]:Hide() end
            end

            local function BotonDeRejilla(i)
                local bt = flyout.botones[i]
                if bt then return bt end
                bt = CreateFrame("Button", nil, flyout)
                bt:SetSize(LADO, LADO)
                bt.icon = bt:CreateTexture(nil, "BORDER")
                bt.icon:SetAllPoints(bt)
                bt.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                bt.marco = bt:CreateTexture(nil, "OVERLAY")
                bt.marco:SetTexture("Interface\\Common\\WhiteIconFrame")
                bt.marco:SetAllPoints(bt)
                bt:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
                -- Marca de "esto es lo que llevas puesto".
                bt.puesta = bt:CreateTexture(nil, "OVERLAY", nil, 1)
                bt.puesta:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                bt.puesta:SetBlendMode("ADD")
                bt.puesta:SetAllPoints(bt)
                bt.puesta:Hide()
                bt:SetScript("OnEnter", function(self)
                    if not (GameTooltip and self.tituloTooltip) then return end
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.tituloTooltip, 1, 0.82, 0, true)
                    if self.subTooltip then
                        GameTooltip:AddLine(self.subTooltip, 1, 1, 1, true)
                    end
                    GameTooltip:Show()
                end)
                bt:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
                flyout.botones[i] = bt
                return bt
            end

            local Pintar   -- forward: el paso 1 necesita volver a pintarse desde el paso 2

            -- `entradas` = { { icon, titulo, sub, marcada, alPulsar } }
            --
            -- Sin titulo: el flyout nativo no lo lleva. Cada icono se identifica por su
            -- tooltip, incluidas las categorias del primer paso.
            local function PintarRejilla(_, entradas)
                local cuantos = math.max(1, #entradas)
                local filas = math.ceil(cuantos / POR_FILA)
                local columnas = math.min(POR_FILA, cuantos)
                -- Medidas del nativo: el buttonAnchor mide
                -- (n * 37) + ((n - 1) * 4) + 3 de ancho, y 43 + (filas - 1) * 42 de alto.
                flyout:SetSize(columnas * LADO + (columnas - 1) * (PASO_X - LADO) + BORDE,
                    (LADO + 2 * BORDE) + (filas - 1) * PASO_Y)
                MontarFondo(cuantos, filas)
                for i, e in ipairs(entradas) do
                    local bt = BotonDeRejilla(i)
                    local fila, col = math.floor((i - 1) / POR_FILA), (i - 1) % POR_FILA
                    bt:ClearAllPoints()
                    -- Igual que el nativo: el primero de cada fila cuelga del TOPLEFT con el
                    -- borde, y los demas se encadenan a la derecha del anterior.
                    bt:SetPoint("TOPLEFT", flyout, "TOPLEFT",
                        BORDE + col * PASO_X, -(BORDE + fila * PASO_Y))
                    bt.icon:SetTexture(e.icon)
                    bt.tituloTooltip, bt.subTooltip = e.titulo, e.sub
                    bt.puesta:SetShown(e.marcada and true or false)
                    bt:SetScript("OnClick", e.alPulsar)
                    bt:Show()
                end
                for i = #entradas + 1, #flyout.botones do flyout.botones[i]:Hide() end
                flyout:Show()
            end

            local function PintarCategoria(grupo)
                local actual = Actual()
                local entradas = {}
                for _, pieza in ipairs(grupo.items or {}) do
                    entradas[#entradas + 1] = {
                        icon = IconoDe(pieza),
                        titulo = pieza.label or pieza.key,
                        sub = isArmorSlot
                            and ("CA " .. tostring(pieza.caText or pieza.base or 10))
                            or (HarfordDnDWeapons and HarfordDnDWeapons.WeaponPropsLabel
                                and HarfordDnDWeapons.WeaponPropsLabel(pieza) or nil),
                        marcada = (actual == pieza.key),
                        alPulsar = function() Poner(pieza.key); flyout:Hide() end,
                    }
                end
                -- Volver a las categorias sin cerrar la rejilla.
                entradas[#entradas + 1] = {
                    icon = IconoSeguro("Interface\\Buttons\\UI-RefreshButton",
                        "Interface\\Icons\\INV_Misc_QuestionMark"),
                    titulo = "Volver",
                    alPulsar = function() Pintar() end,
                }
                PintarRejilla(grupo.text or grupo.key, entradas)
            end

            Pintar = function()
                local actual = Actual()
                local entradas = {}
                for _, grupo in ipairs(GruposPermitidos()) do
                    -- La categoria no tiene icono propio: se usa el de su primera pieza como
                    -- emblema, que es lo que hace reconocible el grupo de un vistazo.
                    local primera = (grupo.items or {})[1]
                    entradas[#entradas + 1] = {
                        icon = primera and IconoDe(primera) or "Interface\\Icons\\INV_Misc_QuestionMark",
                        titulo = grupo.text or grupo.key,
                        sub = #(grupo.items or {}) .. (isArmorSlot and " armaduras" or " armas"),
                        alPulsar = function() PintarCategoria(grupo) end,
                    }
                end
                -- Quitar la basica: deja el hueco a desarmado / sin armadura.
                entradas[#entradas + 1] = {
                    icon = IconoSeguro("Interface\\Buttons\\UI-GroupLoot-Pass-Up",
                        "Interface\\Icons\\INV_Misc_QuestionMark"),
                    titulo = isArmorSlot and "Sin armadura" or "Sin arma basica",
                    sub = isArmorSlot and "CA 10 + Destreza" or "Cuentas como desarmado",
                    marcada = (not actual or actual == "none"),
                    alPulsar = function() Poner(nil); flyout:Hide() end,
                }
                PintarRejilla(isArmorSlot and "Armadura basica" or "Arma basica", entradas)
            end

            flyout:SetScript("OnHide", function()
                OrientarFlecha(false)
                resaltado:Hide()
                marcaOrigen:Hide()
                -- Deja de ser el abierto. Se comprueba la identidad porque otro hueco puede
                -- haberlo relevado ya al abrirse.
                if API._flyoutAbierto == flyout then API._flyoutAbierto = nil end
            end)
            -- El nativo dispara el kit 856 (SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) desde el
            -- propio boton de la flecha, tanto al abrir como al cerrar; lo confirma
            -- `/harford debug run nativeprobe sound on` sobre el paperdoll de Blizzard.
            --
            -- Suena en el CLIC, no en el OnHide: asi cambiar de hueco hace UN solo sonido -el
            -- de abrir- en vez de encadenar el cierre del anterior con la apertura del nuevo,
            -- y cerrar el panel entero no suena, que seria ruido.
            local function SonarSelector()
                if PlaySound then
                    PlaySound((SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) or 856, "SFX")
                end
            end
            arrow:SetScript("OnClick", function()
                if IsInspecting() then return end
                if flyout:IsShown() then
                    flyout:Hide()
                    SonarSelector()
                else
                    -- Solo puede haber UNA rejilla abierta: abrir la de un hueco cierra la del
                    -- anterior, como cualquier menu. Se guarda en la tabla del modulo y no en una
                    -- local nueva: este fichero anda justo del limite de 200 locales de Lua 5.1.
                    if API._flyoutAbierto and API._flyoutAbierto ~= flyout then
                        API._flyoutAbierto:Hide()
                    end
                    API._flyoutAbierto = flyout
                    Pintar()
                    OrientarFlecha(true)
                    resaltado:Show()
                    marcaOrigen:Show()
                    SonarSelector()
                end
            end)
            arrow:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(isArmorSlot and "Armadura basica" or "Arma basica", 1, 0.82, 0, true)
                GameTooltip:AddLine("Se usa solo si no hay un objeto equipado en este slot.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            arrow:SetScript("OnLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
            -- Al colgar de UIParent ya no se oculta sola con el panel: hay que llevarla.
            b:HookScript("OnHide", function() flyout:Hide() end)
            b.basicSelector = arrow
            b.basicFlyout = flyout
        end
        makeBasicSelector()
        local white = b:CreateTexture(nil, "OVERLAY")
        white:SetTexture("Interface\\Common\\WhiteIconFrame")
        white:SetSize(37, 37)
        white:SetPoint("CENTER", b, "CENTER", 0, 0)
        white:Hide()
        local normal = b:CreateTexture(nil, "ARTWORK")
        normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        normal:SetSize(64, 64)
        normal:SetPoint("CENTER", b, "CENTER", 0, -1)
        normal:SetVertexColor(1, 1, 1, 1)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:RegisterForDrag("LeftButton")
        local function equipFromCursor()
            if IsInspecting() then return false end
            if not (HarfordDnDItems and HarfordDnDItems.EquipSlot and GetCursorInfo) then return false end
            local cursorType, itemId, itemLink = GetCursorInfo()
            if cursorType ~= "item" then return false end
            itemLink = itemLink or (itemId and select(2, GetItemInfo(itemId)))
            if not itemLink or itemLink == "" then return false end
            -- Solo se permite equipar objetos que correspondan a este slot.
            local itemName, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
            if itemName and not (HarfordDnDItems.CanEquipInSlot and HarfordDnDItems.CanEquipInSlot(equipLoc, key)) then
                Print("Ese objeto no va en el slot " .. SlotLabelES(key) .. ".")
                return false
            end
            HarfordDnDItems.EquipSlot(key, itemLink, GetProfileName())
            if ClearCursor then ClearCursor() end
            RefreshGameUI()
            RefreshPanel()
            return true
        end
        b:SetScript("OnReceiveDrag", equipFromCursor)
        b:SetScript("OnClick", function(self, button)
            -- Shift+click en un objeto equipado (no basico): linkearlo en el chat como un
            -- objeto normal. Funciona tambien en inspeccion (solo comparte el link).
            local slotEntry = HarfordDnDItems and HarfordDnDItems.GetSlot and HarfordDnDItems.GetSlot(key, GetProfileName())
            if slotEntry and slotEntry.itemLink and slotEntry.itemLink ~= ""
                and ((IsModifiedClick and IsModifiedClick("CHATLINK")) or (IsShiftKeyDown and IsShiftKeyDown()))
            then
                if ChatEdit_InsertLink then ChatEdit_InsertLink(slotEntry.itemLink) end
                return
            end
            if IsInspecting() then return end
            -- Ctrl+click: sintonizar o romper la sintonizacion. Es el unico gesto libre del
            -- slot (shift linkea, click derecho/alt desequipa, click izquierdo equipa) y hasta
            -- ahora la sintonizacion solo existia como API, sin forma de usarla desde la ficha.
            if IsControlKeyDown and IsControlKeyDown() and HarfordDnDBurden then
                local link = slotEntry and slotEntry.itemLink
                local itemId = tonumber(tostring(link or ""):match("item:(%d+)"))
                if not itemId then
                    Print("|cffffcc00Ese hueco no tiene un objeto real que sintonizar.|r")
                    return
                end
                if HarfordDnDBurden.IsAttuned(itemId) then
                    HarfordDnDBurden.Unattune(itemId)
                elseif not HarfordDnDBurden.RequiresAttunement(link) then
                    Print("|cffffcc00Ese objeto no pide sintonizacion.|r")
                    return
                else
                    local nombre = tostring(link):match("%[(.-)%]") or ("Objeto " .. itemId)
                    local ok, err = HarfordDnDBurden.Attune(itemId, nombre)
                    if not ok then Print("|cffff5555" .. tostring(err) .. ".|r") end
                end
                RefreshPanel()
                return
            end
            if button == "RightButton" or (IsAltKeyDown and IsAltKeyDown()) then
                if HarfordDnDItems and HarfordDnDItems.UnequipSlot then
                    HarfordDnDItems.UnequipSlot(key, GetProfileName())
                    RefreshGameUI()
                    RefreshPanel()
                end
                return
            end
            equipFromCursor()
        end)
        b:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            local entry = HarfordDnDItems and HarfordDnDItems.GetSlot and HarfordDnDItems.GetSlot(key, GetProfileName())
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            -- Solo SetHyperlink con un link de objeto REAL (contiene "|H..."). Las armas/armaduras
            -- basicas no tienen itemLink (solo una clave); pasarlas a SetHyperlink lanza
            -- "Unknown link type". El pcall protege ademas de items custom de Epsilon no cacheados.
            local linkShown = false
            if entry and entry.itemLink and tostring(entry.itemLink):find("|H", 1, true) then
                linkShown = pcall(GameTooltip.SetHyperlink, GameTooltip, entry.itemLink)
            end
            if linkShown then
                local basicLabel = HarfordDnDItems and HarfordDnDItems.GetSlotBasicLabel and HarfordDnDItems.GetSlotBasicLabel(key, GetProfileName())
                if basicLabel then
                    GameTooltip:AddLine("Basico guardado: " .. tostring(basicLabel) .. " (ignorado por el objeto equipado)", 0.7, 0.7, 0.7, true)
                end
                if not IsInspecting() then
                    GameTooltip:AddLine("Click derecho para desequipar", 0.4, 1, 0.4, true)
                    -- Sintonizacion: solo se menciona si el objeto la pide o ya la tiene, para
                    -- no llenar de ruido el tooltip de cada pieza corriente.
                    if HarfordDnDBurden then
                        local itemId = tonumber(tostring(entry.itemLink):match("item:(%d+)"))
                        if itemId and HarfordDnDBurden.IsAttuned(itemId) then
                            GameTooltip:AddLine(string.format("Sintonizado (%d/%d) - Ctrl+click para romperla",
                                HarfordDnDBurden.CountAttuned(), HarfordDnDBurden.MAX_ATTUNED), 0.4, 1, 0.4, true)
                        elseif itemId and HarfordDnDBurden.RequiresAttunement(entry.itemLink) then
                            GameTooltip:AddLine(string.format("Requiere sintonizacion (%d/%d usadas) - Ctrl+click",
                                HarfordDnDBurden.CountAttuned(), HarfordDnDBurden.MAX_ATTUNED), 1, 0.82, 0, true)
                        end
                    end
                end
            else
                GameTooltip:SetText(SlotLabelES(key), 1, 0.82, 0, true)
                if IsInspecting() then
                    GameTooltip:AddLine("Sin objeto informado en el snapshot remoto.", 1, 1, 1, true)
                else
                    GameTooltip:AddLine("Arrastra un objeto aqui para equiparlo en la ficha Harford.", 1, 1, 1, true)
                    local basicLabel = HarfordDnDItems and HarfordDnDItems.GetSlotBasicLabel and HarfordDnDItems.GetSlotBasicLabel(key, GetProfileName())
                    if basicLabel then
                        GameTooltip:AddLine("Basico activo: " .. tostring(basicLabel), 0.3, 1, 0.3, true)
                    end
                end
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        SH.slots = SH.slots or {}
        SH.slots[#SH.slots + 1] = b
        -- Acceso para diagnostico: rastrear el arbol de frames desde fuera es fragil.
        API._slots = SH.slots
        return b
    end
    local head = MakeSlot(leftInset, "Head")
    head:SetPoint("TOPLEFT", leftInset, "TOPLEFT", 4, -2)
    local prev = head
    for _, t in ipairs({ "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrists" }) do
        local s = MakeSlot(leftInset, t)
        s:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
        prev = s
    end
    local hands = MakeSlot(leftInset, "Hands")
    hands:SetPoint("TOPRIGHT", leftInset, "TOPRIGHT", -4, -2)
    prev = hands
    for _, t in ipairs({ "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1" }) do
        local s = MakeSlot(leftInset, t)
        s:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
        prev = s
    end
    local mainHand = MakeSlot(leftInset, "MainHand")
    mainHand:SetPoint("BOTTOMLEFT", leftInset, "BOTTOMLEFT", 130, 16)
    local offHand = MakeSlot(leftInset, "SecondaryHand")
    offHand:SetPoint("TOPLEFT", mainHand, "TOPRIGHT", 4, 0)

    -- CharacterModelFrame: 231x320, TOPLEFT PaperDollFrame 52,-66.
    local model = CreateFrame("PlayerModel", nil, leftInset)
    model:SetSize(231, 320)
    model:SetPoint("TOPLEFT", leftInset, "TOPLEFT", 48, -6)
    if model.SetClipsChildren then pcall(model.SetClipsChildren, model, true) end
    local sceneTL = model:CreateTexture(nil, "BACKGROUND")
    sceneTL:SetTexture(131081); sceneTL:SetTexCoord(0.171875, 1, 0.039215688, 1)
    sceneTL:SetSize(212, 245); sceneTL:SetPoint("TOPLEFT", model, "TOPLEFT", 0, 0)
    local sceneTR = model:CreateTexture(nil, "BACKGROUND")
    sceneTR:SetTexture(131082); sceneTR:SetTexCoord(0, 0.296875, 0.039215688, 1)
    sceneTR:SetSize(19, 245); sceneTR:SetPoint("TOPLEFT", sceneTL, "TOPRIGHT", 0, 0)
    local sceneBL = model:CreateTexture(nil, "BACKGROUND")
    sceneBL:SetTexture(131083); sceneBL:SetTexCoord(0.171875, 1, 0, 1)
    sceneBL:SetSize(212, 128); sceneBL:SetPoint("TOPLEFT", sceneTL, "BOTTOMLEFT", 0, 0)
    local sceneBR = model:CreateTexture(nil, "BACKGROUND")
    sceneBR:SetTexture(131084); sceneBR:SetTexCoord(0, 0.296875, 0, 1)
    sceneBR:SetSize(19, 128); sceneBR:SetPoint("TOPLEFT", sceneTL, "BOTTOMRIGHT", 0, 0)
    SH.modelBg = { tl = sceneTL, tr = sceneTR, bl = sceneBL, br = sceneBR }
    for _, q in pairs(SH.modelBg) do
        if q.SetDesaturated then pcall(q.SetDesaturated, q, true) end   -- escena en blanco y negro
        if q.SetDesaturation then pcall(q.SetDesaturation, q, 1) end
    end
    local sceneDark = model:CreateTexture(nil, "BORDER")
    sceneDark:SetAllPoints(model); sceneDark:SetColorTexture(0, 0, 0, 0.4)
    SH.modelDark = sceneDark
    model:SetScript("OnShow", function(self) if self.SetUnit then self:SetUnit(GetPortraitUnit()) end end)
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self)
        self._lastX = ({ GetCursorPosition() })[1]
        self:SetScript("OnUpdate", function(s)
            local x = ({ GetCursorPosition() })[1]
            local dx = x - (s._lastX or x)
            s._lastX = x
            s._rot = (s._rot or 0) + dx * 0.012
            if s.SetRotation then s:SetRotation(s._rot) end
        end)
    end)
    model:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
    model:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    SH.model = model
    MakePaperDollInnerBorder(leftInset)
    -- El inset nativo tapa toda la zona bajo el modelo con una banda oscura.
    -- Si dejamos asomar el Marble del fondo aparecen franjas grises en la base.
    local lowerMask = leftInset:CreateTexture(nil, "BACKGROUND", nil, 1)
    lowerMask:SetColorTexture(0.012, 0.011, 0.01, 0.98)
    lowerMask:SetPoint("BOTTOMLEFT", leftInset, "BOTTOMLEFT", 4, 5)
    lowerMask:SetPoint("TOPRIGHT", leftInset, "BOTTOMRIGHT", -4, 52)
    local lowerTop = leftInset:CreateTexture(nil, "BORDER", nil, 1)
    lowerTop:SetColorTexture(0.9, 0.82, 0.58, 0.12)
    lowerTop:SetPoint("TOPLEFT", lowerMask, "TOPLEFT", 0, 0)
    lowerTop:SetPoint("TOPRIGHT", lowerMask, "TOPRIGHT", 0, 0)
    lowerTop:SetHeight(1)

    -- CharacterFrameInsetRight: TOPLEFT CharacterFrameInset TOPRIGHT 1,0;
    -- BOTTOMRIGHT CharacterFrame -4,4.
    local right = CreateFrame("Frame", nil, page)
    right:SetPoint("TOPLEFT", leftInset, "TOPRIGHT", 1, 0)
    right:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 4)
    local rbg = right:CreateTexture(nil, "BACKGROUND")
    rbg:SetAllPoints(right)
    rbg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", true, true)
    if rbg.SetHorizTile then rbg:SetHorizTile(true) end
    if rbg.SetVertTile then rbg:SetVertTile(true) end
    MakeInnerBorder(right)
    SH.right = right
    SH.sidebarTabs = CreateSidebarTabs(right)

    -- CharacterStatsPane: TOPLEFT right 3,-3; BOTTOMRIGHT right -3,2.
    local statsPane = CreateFrame("Frame", nil, right)
    statsPane:SetPoint("TOPLEFT", right, "TOPLEFT", 3, -3)
    statsPane:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -3, 2)
    SH.statsPane = statsPane
    SH.statsBg = statsPane:CreateTexture(nil, "BACKGROUND")
    SH.statsBg:SetAllPoints(statsPane)
    ApplyAtlasOrTexture(SH.statsBg, "UI-Character-Info-Warrior-BG", 1400895)

    local function CatBar(label, y)
        local bar = CreateFrame("Frame", nil, statsPane)
        bar:SetSize(197, 40)
        bar:SetPoint("TOP", statsPane, "TOP", 0, y)
        local tex = bar:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(bar)
        if tex.SetAtlas then tex:SetAtlas("UI-Character-Info-Title") else tex:SetTexture(1400895) end
        local t = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        t:SetPoint("CENTER", bar, "CENTER", 0, 1)
        t:SetText(label)
        bar.text = t
        return bar
    end
    local function ValueBounceFrame(anchor)
        local valueFrame = CreateFrame("Frame", nil, statsPane)
        valueFrame:SetSize(187, 29)
        valueFrame:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
        local bg = valueFrame:CreateTexture(nil, "BORDER")
        bg:SetSize(162, 29)
        bg:SetPoint("CENTER", valueFrame, "CENTER", 0, 0)
        if not ApplyAtlasOrTexture(bg, "UI-Character-Info-ItemLevel-Bounce", 1400895) then
            bg:SetTexture(1400895)
        end
        bg:SetAlpha(0.298)
        valueFrame.bg = bg
        return valueFrame
    end
    local function PaneRow(y)
        local rowFrame = CreateFrame("Frame", nil, statsPane)
        rowFrame:SetSize(170, 15)
        rowFrame:SetPoint("TOPLEFT", statsPane, "TOPLEFT", 14, y + 3)
        local stripe = rowFrame:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints(rowFrame)
        stripe:SetColorTexture(1, 1, 1, 0.045)
        local l = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        l:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
        l:SetJustifyH("LEFT")
        l:SetTextColor(1, 0.82, 0)
        local v = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        v:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
        v:SetJustifyH("RIGHT")
        v:SetTextColor(1, 1, 1)
        return { f = rowFrame, l = l, v = v, stripe = stripe }
    end

    SH.levelBar = CatBar("Nivel", -2)
    SH.levelValueFrame = ValueBounceFrame(SH.levelBar)
    SH.levelText = SH.levelValueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    SH.levelText:SetPoint("CENTER", SH.levelValueFrame, "CENTER", 0, -1)
    SH.levelText:SetTextColor(1, 0.82, 0)

    -- Acceso a la subida: el "+" nativo, el mismo arte que usan las filas del panel de
    -- reputacion. Antes era la flecha del ReputationBar (FileDataID 130821/130837), que se leia
    -- como "desplegar" y no como "hay algo que hacer aqui".
    --
    -- Solo se muestra si hay subida DISPONIBLE (ver el refresco de la vista de ficha): el nivel
    -- no sube solo, pero el boton tampoco debe invitar a subir sin XP para ello.
    local levelUp = CreateFrame("Button", nil, SH.levelValueFrame)
    levelUp:SetSize(13, 13)
    levelUp:SetPoint("LEFT", SH.levelText, "RIGHT", 3, 0)
    levelUp:SetNormalTexture("Interface" .. string.char(92) .. "Buttons" .. string.char(92) .. "UI-PlusButton-Up")
    -- El arte "pulsado" no esta en todos los clientes; si falta se reutiliza el normal en vez de
    -- dejar el boton sin textura al hacer click.
    local plusDown = "Interface" .. string.char(92) .. "Buttons" .. string.char(92) .. "UI-PlusButton-Down"
    if GetFileIDFromPath and not GetFileIDFromPath(plusDown) then
        plusDown = "Interface" .. string.char(92) .. "Buttons" .. string.char(92) .. "UI-PlusButton-Up"
    end
    levelUp:SetPushedTexture(plusDown)
    levelUp:SetHighlightTexture("Interface" .. string.char(92) .. "Buttons" .. string.char(92) .. "UI-PlusButton-Hilight", "ADD")
    levelUp:SetScript("OnClick", function()
        if not IsInspecting() and HarfordCharacterAdvancement and HarfordCharacterAdvancement.OpenLevelUp then
            HarfordCharacterAdvancement.OpenLevelUp()
        end
    end)
    levelUp:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Subir de nivel", 1, 0.82, 0)
        GameTooltip:AddLine("Abre la subida moderna para elegir clase, subclase y rasgos.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    levelUp:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    SH.levelUpButton = levelUp

    -- BARRA DE EXPERIENCIA. Es LA MISMA barra del borde inferior de la pantalla, solo que fina y
    -- al ancho de la seccion: el arte lo pone `HarfordCharacterXP.SkinBar`, que es la unica fuente.
    --
    -- Va en la franja inferior de la banda del numero de nivel porque entre esa banda (acaba en
    -- -71) y la barra de "Caracteristicas" (-70) no queda hueco libre.
    --
    -- NO usar aqui los caps de UI-Character-ReputationBar: a este tamano se renderizan rotos (dos
    -- trozos rojos en los extremos). El envoltorio bueno es el atlas nativo de SkinBar.
    local xpBar = CreateFrame("StatusBar", nil, statsPane)
    -- 199x9 en y=-12 y 3 a la derecha: valores afinados en juego con `xpbarpanel`. La barra cae
    -- POR DEBAJO de la banda del numero (que acaba en -71), de ahi que la seccion de
    -- "Caracteristicas" baje para dejarle el hueco (ver S.ABIL_BAR_Y).
    SH.xpBarX, SH.xpBarY = 3, -12
    xpBar:SetSize(199, 9)
    xpBar:SetPoint("BOTTOM", SH.levelValueFrame, "BOTTOM", SH.xpBarX, SH.xpBarY)
    if HarfordCharacterXP and HarfordCharacterXP.SkinBar then
        -- `true`: con envoltorio. El atlas nativo ya dibuja el carril vacio, asi que la barra se
        -- ve tambien con 0 de experiencia, que era el motivo del tinte manual anterior.
        HarfordCharacterXP.SkinBar(xpBar, true)
    else
        xpBar:SetMinMaxValues(0, 1)
    end
    xpBar:SetValue(0)

    xpBar:EnableMouse(true)
    xpBar:SetScript("OnEnter", function(self)
        if not (GameTooltip and self.tipTexto) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Experiencia", 1, 0.82, 0)
        GameTooltip:AddLine(self.tipTexto, 1, 1, 1)
        GameTooltip:Show()
    end)
    xpBar:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    xpBar:Hide()
    SH.xpBar = xpBar
    -- Acceso para diagnostico (/harford debug run xpbar).
    API._sheetState = SH

    SH.abilBar = CatBar("Caracteristicas", S.ABIL_BAR_Y)
    SH.abilRows = {}
    for i = 1, 6 do
        SH.abilRows[i] = PaneRow(-110 - (i - 1) * 15)
        SH.abilRows[i].stripe:SetAlpha((i % 2 == 0) and 0.03 or 0.07)
    end

    SH.combatBar = CatBar("Combate", -206)
    SH.combatRows = {}
    for i = 1, 7 do
        SH.combatRows[i] = PaneRow(-246 - (i - 1) * 15)
        SH.combatRows[i].stripe:SetAlpha((i % 2 == 0) and 0.03 or 0.07)
    end
    SH.sheetRows = {}
    for i = 1, 26 do
        SH.sheetRows[i] = PaneRow(-52 - (i - 1) * 14)
        SH.sheetRows[i].stripe:SetAlpha((i % 2 == 0) and 0.025 or 0.065)
    end

    -- Zona scrollable de "Rasgos" (vista resumen): la scrollbar nativa
    -- aparece sola cuando los rasgos desbordan el alto del area.
    local featScroll = CreateFrame("ScrollFrame", "HarfordCharPanelFeatScroll", statsPane, "UIPanelScrollFrameTemplate")
    -- -243 = barra de seccion (-206) - 40 de alto + 3, el mismo espacio que "Caracteristicas".
    SH.abilBarY = S.ABIL_BAR_Y
    -- -243 es la regla del panel (barra de Rasgos -206, menos 40 de alto, mas 3); se desplaza lo
    -- mismo que la seccion de Caracteristicas para que el bloque entero baje junto.
    featScroll:SetPoint("TOPLEFT", statsPane, "TOPLEFT", 14, -243 + (S.ABIL_BAR_Y + 70))
    featScroll:SetPoint("BOTTOMRIGHT", statsPane, "BOTTOMRIGHT", -26, 8)
    local featChild = CreateFrame("Frame", nil, featScroll)
    featChild:SetSize(150, 10)
    featScroll:SetScrollChild(featChild)
    featScroll:Hide()
    SH.featScroll = featScroll

    -- Banda de "Atributos": del hueco bajo su barra (-39) hasta justo encima de la barra de
    -- "Salvaciones" (-206). Si el contenido no cabe, scrollea; nunca invade la de abajo.
    local attrScroll = CreateFrame("ScrollFrame", "HarfordCharPanelAttrScroll", statsPane,
        "UIPanelScrollFrameTemplate")
    -- Y de donde este esa barra dependen tres cosas: ella misma, sus filas y el fondo de la
    -- banda scrollable de Atributos. Se guarda en el estado para poder afinarla en vivo con
    -- `/harford debug run salvaciones <y>` sin recargar.
    SH.savesBarY = -226
    attrScroll:SetPoint("TOPLEFT", statsPane, "TOPLEFT", 14, -39)
    attrScroll:SetPoint("BOTTOMRIGHT", statsPane, "TOPRIGHT", -26, SH.savesBarY + 2)
    local attrChild = CreateFrame("Frame", nil, attrScroll)
    attrChild:SetSize(154, 10)
    attrScroll:SetScrollChild(attrChild)
    attrScroll:Hide()
    SH.attrScroll = attrScroll
    SH.attrChild = attrChild
    SH.featChild = featChild
    SH.featRows = {}

    -- Origen oculto (el nativo no lo muestra; se reubicara mas adelante).
    SH.origin = CreateFS(page, "GameFontHighlightSmall", "")
    SH.origin:SetPoint("BOTTOMLEFT", leftInset, "BOTTOMLEFT", 6, 2)
    SH.origin:Hide()

    -- Capa modal interna: existe solo para una ficha vacia y queda por encima de
    -- todas las regiones del panel, sin abrir otra ventana ni crear una pestana.
    local empty = CreateFrame("Frame", nil, S.frame)
    empty:SetPoint("TOPLEFT", S.frame, "TOPLEFT", 8, -42)
    empty:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -8, 28)
    empty:SetFrameLevel((S.frame:GetFrameLevel() or 1) + 60)
    empty:EnableMouse(true)
    local dim = empty:CreateTexture(nil, "BACKGROUND")
    dim:SetAllPoints(empty)
    dim:SetColorTexture(0.01, 0.01, 0.008, 0.88)
    local card = CreateFrame("Frame", nil, empty)
    card:SetSize(318, 150)
    card:SetPoint("CENTER", empty, "CENTER", 0, -4)
    card:SetFrameLevel(empty:GetFrameLevel() + 2)
    local cardBg = card:CreateTexture(nil, "BACKGROUND")
    cardBg:SetAllPoints(card)
    cardBg:SetColorTexture(0.06, 0.05, 0.03, 0.98)
    local topLine = card:CreateTexture(nil, "BORDER")
    topLine:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    topLine:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    topLine:SetHeight(2)
    topLine:SetColorTexture(0.82, 0.65, 0.22, 0.9)
    local emptyTitle = CreateFS(card, "GameFontNormalLarge", "No tienes una ficha creada")
    emptyTitle:SetPoint("TOP", card, "TOP", 0, -20)
    emptyTitle:SetTextColor(1, 0.82, 0)
    local emptyText = CreateFS(card, "GameFontHighlightSmall", "Crea el origen, las caracteristicas y la clase de tu personaje.")
    emptyText:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -12)
    emptyText:SetWidth(270)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetNonSpaceWrap(false)
    local emptyButton = CreateButton(card, "Abrir creador", 142, 24, function()
        empty:Hide()
        if HarfordCharacterAdvancement and HarfordCharacterAdvancement.OpenPrototype then
            HarfordCharacterAdvancement.OpenPrototype("guerrero")
        else
            Print("El creador de personaje no esta disponible.")
        end
    end)
    emptyButton:SetPoint("BOTTOM", card, "BOTTOM", 0, 18)
    emptyButton:SetFrameLevel(card:GetFrameLevel() + 2)
    SH.emptyPrompt = empty
    empty:Hide()
end

local function SetSheetBar(bar, label, y, shown)
    if not bar then return end
    bar:ClearAllPoints()
    bar:SetPoint("TOP", S.sheet.statsPane, "TOP", 0, y)
    if bar.text then bar.text:SetText(label or "") end
    bar:SetShown(shown ~= false)
end

local function SetSheetRow(row, y, label, value, tooltipTitle, tooltipText, opts)
    if not row then return 14 end
    opts = type(opts) == "table" and opts or nil
    -- Contenedor: por defecto el panel, pero una vista puede pasar el hijo de un ScrollFrame
    -- para que sus filas scrolleen en vez de desbordar sobre la seccion siguiente. Se
    -- REPARENTA siempre, porque las filas se comparten entre vistas.
    local host = (opts and opts.container) or S.sheet.statsPane
    local enScroll = (opts and opts.container) and true or false
    local hostX = enScroll and 0 or 14
    if row.f:GetParent() ~= host then row.f:SetParent(host) end
    row.f:ClearAllPoints()
    row.f:SetPoint("TOPLEFT", host, "TOPLEFT", hostX, y)
    -- Dentro de un scroll la fila se estrecha 16px: si no, la barra de scroll se come el borde
    -- derecho y corta los valores, que van alineados a la derecha.
    row.f:SetSize(enScroll and 154 or 170, 15)
    row.l:ClearAllPoints()
    if opts and opts.labelTop then
        row.l:SetPoint("TOPLEFT", row.f, "TOPLEFT", 0, 0)
        if row.l.SetJustifyV then row.l:SetJustifyV("TOP") end
    else
        row.l:SetPoint("LEFT", row.f, "LEFT", 0, 0)
        if row.l.SetJustifyV then row.l:SetJustifyV("MIDDLE") end
    end
    row.l:SetWidth(opts and opts.labelWidth or (enScroll and 110 or 118))
    row.l:SetJustifyH("LEFT")
    if row.l.SetWordWrap then row.l:SetWordWrap(false) end
    if row.l.SetNonSpaceWrap then row.l:SetNonSpaceWrap(false) end
    row.v:ClearAllPoints()
    row.v:SetWidth(opts and opts.valueWidth or (enScroll and 62 or 72))
    if row.v.SetWordWrap then row.v:SetWordWrap(opts and opts.wrapValue or false) end
    if row.v.SetNonSpaceWrap then row.v:SetNonSpaceWrap(false) end
    if opts and opts.valueAlign == "LEFT" then
        row.v:SetPoint("TOPLEFT", row.f, "TOPLEFT", opts.valueX or 78, 0)
        row.v:SetJustifyH("LEFT")
    else
        row.v:SetPoint("TOPRIGHT", row.f, "TOPRIGHT", 0, 0)
        row.v:SetJustifyH("RIGHT")
    end
    if row.classTexts then
        for _, fs in ipairs(row.classTexts) do
            fs:Hide()
        end
    end
    if row.abilityScoreText then row.abilityScoreText:Hide() end
    if row.abilityModText then row.abilityModText:Hide() end
    row.l:SetText(label or "")
    row.v:SetText(value or "")
    local valueHeight = 14
    if row.v.GetStringHeight then
        valueHeight = math.max(valueHeight, math.ceil(row.v:GetStringHeight() or 14))
    end
    local rowHeight = math.max(14, valueHeight)
    row.f:SetHeight(rowHeight)
    if tooltipTitle or tooltipText then
        row.f:EnableMouse(true)
        row.f:SetScript("OnEnter", function(self) TooltipLines(self, tooltipTitle or label, tooltipText, opts and opts.tooltip) end)
        row.f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    else
        row.f:SetScript("OnEnter", nil)
        row.f:SetScript("OnLeave", nil)
        row.f:EnableMouse(false)
    end
    row.f:Show()
    row.l:Show()
    row.v:Show()
    return rowHeight
end

local function SetAbilitySheetRow(row, y, label, score, mod, tooltipTitle, tooltipText)
    SetSheetRow(row, y, label, "", tooltipTitle, tooltipText, { tooltip = { nativeAbility = true } })
    if not row then return 14 end
    row.v:Hide()
    if not row.abilityScoreText then
        row.abilityScoreText = row.f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.abilityScoreText:SetJustifyH("RIGHT")
    end
    if not row.abilityModText then
        row.abilityModText = row.f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.abilityModText:SetJustifyH("RIGHT")
    end
    row.abilityScoreText:ClearAllPoints()
    row.abilityScoreText:SetPoint("RIGHT", row.f, "RIGHT", -28, 0)
    row.abilityScoreText:SetWidth(24)
    row.abilityScoreText:SetText("|cffffffff" .. tostring(score or 0) .. "|r")
    row.abilityScoreText:Show()

    row.abilityModText:ClearAllPoints()
    row.abilityModText:SetPoint("RIGHT", row.f, "RIGHT", 0, 0)
    row.abilityModText:SetWidth(24)
    row.abilityModText:SetText(ColorSigned(mod))
    row.abilityModText:Show()
    return row.f:GetHeight() or 14
end

-- Tooltip de clase para la fila multiclase: una entrada por clase con su color y su
-- descripcion (subclase si esta elegida, si no la clase). El bloque coloreado de la
-- fila no admite el OnEnter de SetSheetRow, asi que lo gestionamos aqui directamente.
local function ShowClassTooltip(owner, data)
    if not (GameTooltip and owner and data and data.classLevels and HarfordDnDBook) then return end
    if #data.classLevels == 0 then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clase", 1, 0.82, 0, true)
    for _, entry in ipairs(data.classLevels) do
        local className = (HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId)) or entry.classId
        local subName = (HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(entry.classId, entry.subclassId)) or ""
        local classDef = HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(entry.classId)
        local subDef = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
        local r, g, b = GetClassColorParts(entry, className, className)
        local head = tostring(className or "")
        if subName ~= "" then head = head .. " " .. subName end
        head = head .. " (" .. tostring(entry.level or 1) .. ")"
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(head, r or 1, g or 0.82, b or 0, true)
        local desc = (subDef and subDef.desc) or (classDef and classDef.desc)
        if desc and desc ~= "" then
            GameTooltip:AddLine(desc, 1, 1, 1, true)
        end
    end
    GameTooltip:Show()
end

local function SetClassSheetRow(row, y, data, opts)
    SetSheetRow(row, y, "Clase", "", nil, nil, opts)
    if not row then return 14 end
    row.l:ClearAllPoints()
    row.l:SetPoint("TOPLEFT", row.f, "TOPLEFT", 0, 0)
    if row.l.SetJustifyV then row.l:SetJustifyV("TOP") end
    local parts = GetClassParts(data) or { { text = "Sin clase", r = 1, g = 0.82, b = 0 } }
    SetColoredTextList(row.f, row, "classTexts", parts, { font = "GameFontHighlightSmall" })
    row.v:Hide()

    local valueWidth = 112
    local lineHeight = 12
    local yOffset = 0
    for i, fs in ipairs(row.classTexts or {}) do
        if i <= #parts then
            fs:ClearAllPoints()
            fs:SetPoint("TOPRIGHT", row.f, "TOPRIGHT", 0, -yOffset)
            fs:SetWidth(valueWidth)
            fs:SetJustifyH("RIGHT")
            if fs.SetWordWrap then fs:SetWordWrap(true) end
            if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
            fs:SetTextColor(parts[i].r or 1, parts[i].g or 1, parts[i].b or 1)
            fs:Show()
            local h = lineHeight
            if fs.GetStringHeight then
                h = math.max(lineHeight, math.ceil(fs:GetStringHeight() or lineHeight))
            end
            yOffset = yOffset + h
        end
    end
    local rowHeight = math.max(14, yOffset)
    row.f:SetHeight(rowHeight)
    -- Tooltip multiclase (SetSheetRow desactivo el mouse al no pasar tooltip).
    if data and data.classLevels and #data.classLevels > 0 then
        row.f:EnableMouse(true)
        row.f:SetScript("OnEnter", function(self) ShowClassTooltip(self, data) end)
        row.f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    return rowHeight
end

local function HideSheetRows(SH)
    local function hideList(list)
        if not list then return end
        for _, row in ipairs(list) do
            if row and row.f then row.f:Hide() end
        end
    end
    hideList(SH.abilRows)
    hideList(SH.combatRows)
    hideList(SH.sheetRows)
    if SH.levelBar then SH.levelBar:Hide() end
    if SH.levelValueFrame then SH.levelValueFrame:Hide() end
    if SH.abilBar then SH.abilBar:Hide() end
    if SH.combatBar then SH.combatBar:Hide() end
    if SH.levelText then SH.levelText:Hide() end
end

local function SkillTotal(skill)
    if IsInspecting() then
        local name = GetProfileName()
        local pb = HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus
            and HarfordDnDProgression.GetProficiencyBonus(name)
            or tonumber(GetProfileValue("BonusCompetencia", 2)) or 2
        local profFlag = tonumber(GetProfileValue("Hab_" .. skill.id .. "_Prof", 0)) or 0
        local expFlag = tonumber(GetProfileValue("Hab_" .. skill.id .. "_Exp", 0)) or 0
        local featureRank = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetSkillRank
            and HarfordDnDFeatureEffects.GetSkillRank(skill.id, name)
            or 0
        local prof = 0
        if expFlag == 1 or featureRank >= 2 then
            prof = 2 * pb
        elseif profFlag == 1 or featureRank >= 1 then
            prof = pb
        end
        local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
            and HarfordDnDFeatureEffects.GetBonus("skill", skill.id, name)
            or 0
        return AbilityMod(AbilityScore(skill.ability)) + (tonumber(bonus) or 0) + prof
    end
    if HarfordDnDCalc and HarfordDnDCalc.GetSkillRollBonuses then
        local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)
        return (tonumber(base) or 0) + (tonumber(prof) or 0)
    end
    return AbilityMod(AbilityScore(skill.ability))
end

local function SaveTotal(abilityKey)
    if IsInspecting() then
        local name = GetProfileName()
        local pb = HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus
            and HarfordDnDProgression.GetProficiencyBonus(name)
            or tonumber(GetProfileValue("BonusCompetencia", 2)) or 2
        local prof = tonumber(GetProfileValue("Salv_" .. abilityKey, 0)) == 1
            or (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasSaveProf
                and HarfordDnDFeatureEffects.HasSaveProf(abilityKey, name) == true)
        local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
            and HarfordDnDFeatureEffects.GetBonus("save", abilityKey, name)
            or 0
        if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetAllSavesAbilities then
            for _, entry in ipairs(HarfordDnDFeatureEffects.GetAllSavesAbilities(name)) do
                local mod = AbilityMod(AbilityScore(entry.ability))
                local minVal = tonumber(entry.min) or 0
                bonus = bonus + math.max(minVal, mod)
            end
        end
        return AbilityMod(AbilityScore(abilityKey)) + (tonumber(bonus) or 0) + (prof and pb or 0)
    end
    if HarfordDnDCalc and HarfordDnDCalc.GetSaveRollBonuses then
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(abilityKey)
        return (tonumber(base) or 0) + (tonumber(prof) or 0)
    end
    return AbilityMod(AbilityScore(abilityKey))
end

-- Pinta los rasgos en el area scrollable (vista resumen). Cada fila muestra el nombre
-- del rasgo con su descripcion en tooltip. El alto del child decide si sale scrollbar.
local function SetFeatureScroll(rows)
    local SH = S.sheet
    if not (SH and SH.featChild and SH.featScroll) then return end
    rows = rows or {}
    SH.featRows = SH.featRows or {}
    local lineH = 15
    for i, r in ipairs(rows) do
        local row = SH.featRows[i]
        if not row then
            row = CreateFrame("Button", nil, SH.featChild)
            row:SetHeight(lineH)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetJustifyH("LEFT")
            row.text:SetTextColor(1, 0.82, 0)
            if row.text.SetWordWrap then row.text:SetWordWrap(false) end
            if row.text.SetNonSpaceWrap then row.text:SetNonSpaceWrap(false) end
            row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.value:SetJustifyH("RIGHT")
            row.value:SetTextColor(1, 1, 1)
            if row.value.SetWordWrap then row.value:SetWordWrap(false) end
            if row.value.SetNonSpaceWrap then row.value:SetNonSpaceWrap(false) end
            SH.featRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", SH.featChild, "TOPLEFT", 0, -(i - 1) * lineH)
        row:SetPoint("RIGHT", SH.featChild, "RIGHT", -2, 0)
        row.text:ClearAllPoints()
        row.value:ClearAllPoints()
        local value = tostring(r[2] or "")
        local valueWidth = (value ~= "") and 62 or 0
        row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -valueWidth - 4, 0)
        row.text:SetText(tostring(r[1] or ""))
        row.text:SetTextColor(1, 0.82, 0)
        row.value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row.value:SetWidth(valueWidth)
        row.value:SetText(value)
        row.value:SetShown(value ~= "")
        row:SetScript("OnClick", nil)
        local tipTitle, tipText = r[3] or r[1], r[4]
        row:SetScript("OnEnter", function(self)
            if GameTooltip and tipTitle then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tostring(tipTitle), 1, 0.82, 0, true)
                if tipText and tipText ~= "" then GameTooltip:AddLine(tostring(tipText), 1, 1, 1, true) end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        row:Show()
    end
    for i = #rows + 1, #SH.featRows do SH.featRows[i]:Hide() end
    SH.featChild:SetWidth(math.max(1, (SH.featScroll:GetWidth() or 150) - 18))
    SH.featChild:SetHeight(math.max(1, #rows * lineH + 2))
end

local function RefreshSheet()
    local SH = S.sheet
    if not SH then return end
    if SH.featScroll then SH.featScroll:Hide() end  -- solo se muestra en la vista resumen
    local name = GetProfileName()
    local data = GetProgression()
    local total = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(name) or 0

    if SH.emptyPrompt then
        SH.emptyPrompt:SetShown(not IsInspecting() and total <= 0)
    end

    RefreshSubtitleClasses(SH, data)
    if SH.model and SH.model.SetUnit then SH.model:SetUnit(GetPortraitUnit()) end
    RefreshRaceModelBackground(SH, data)
    RefreshPaperDollSlots(SH)
    if SH.sidebarTabs and SH.sidebarTabs.portrait and SetPortraitTexture then
        SetPortraitTexture(SH.sidebarTabs.portrait, "player")
        SH.sidebarTabs.portrait:SetTexCoord(0.109375, 0.890625, 0.09375, 0.90625)
        if SH.sidebarTabs.SetSelected then SH.sidebarTabs:SetSelected(S.sheetView or "summary") end
    end
    if SH.statsBg then
        local atlas = GetClassInfoAtlas(data)
        if not ApplyAtlasOrTexture(SH.statsBg, atlas, 1400895) then
            ApplyAtlasOrTexture(SH.statsBg, "UI-Character-Info-Warrior-BG", 1400895)
        end
    end

    HideSheetRows(SH)
    if SH.levelUpButton then SH.levelUpButton:Hide() end

    local list = (HarfordDnDData and HarfordDnDData.ABIL) or K.ABIL_KEYS
    local pb = HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus and HarfordDnDProgression.GetProficiencyBonus(name) or nil
    local dexMod = AbilityMod(AbilityScore("Destreza"))
    local initBonus = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus and HarfordDnDFeatureEffects.GetBonus("initiative", nil, name)) or 0
    -- Mismo calculo que HarfordDnDCalc.GetInitiativeBonus pero por perfil mostrado (soporta inspect):
    -- + Mod. de caracteristicas que suman a iniciativa (Alacridad/Reflejos/Instintos) y + PB (Afinidad Aire).
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetInitiativeAbilities then
        for _, ability in ipairs(HarfordDnDFeatureEffects.GetInitiativeAbilities(name)) do
            initBonus = initBonus + AbilityMod(AbilityScore(ability))
        end
    end
    if pb and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("initiativeProfBonus", name) then
        initBonus = initBonus + pb
    end
    local manualCA = tonumber(GetProfileValue("ArmorClass", 10)) or 10
    local itemCA = HarfordDnDItems and HarfordDnDItems.GetEquippedArmorClass and HarfordDnDItems.GetEquippedArmorClass(name) or nil
    local featCA = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus and HarfordDnDFeatureEffects.GetBonus("armorClass", nil, name)) or 0
    local ca = math.floor(math.max(manualCA, tonumber(itemCA) or 0) + featCA)
    local hpCur = HarfordDnDResources and ResourceValue(HarfordDnDResources.CurKey("health")) or 0
    local hpMax = HarfordDnDResources and ResourceValue(HarfordDnDResources.MaxKey("health")) or 0
    local speed
    if data and data.race and HarfordDnDRaces and HarfordDnDRaces.GetRace then
        local rd = HarfordDnDRaces.GetRace(data.race.id)
        speed = rd and rd.speed
    end
    -- Velocidad efectiva: bonos de rasgo (Afinidad Aire) o una velocidad fija activa
    -- (Bestia Espiritual). En inspeccion no se aplica: los efectos resueltos son los del jugador local.
    if not IsInspecting() and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetSpeed then
        speed = HarfordDnDFeatureEffects.GetSpeed(speed)
    end

    local view = S.sheetView or "summary"
    if view == "skills" then
        -- Sin barra de "Bonificador por competencia" (libera espacio); el bono va en la cabecera.
        SetSheetBar(SH.levelBar, "", 0, false)
        if SH.xpBar then SH.xpBar:Hide() end
        if SH.attrScroll then SH.attrScroll:Hide() end
        SetSheetBar(SH.abilBar, "Habilidades " .. (pb and ("(" .. ColorSigned(pb) .. ")") or ""), -2, true)
        local skills = HarfordDnDData and HarfordDnDData.SKILLS or {}
        -- Agrupadas por caracteristica (cabecera "Fuerza (+3)" y sus habilidades debajo).
        local y, index = -42, 1
        for _, abil in ipairs(list) do
            local group = {}
            for _, skill in ipairs(skills) do
                if skill.ability == abil.key then group[#group + 1] = skill end
            end
            if #group > 0 and SH.sheetRows[index] then
                SetSheetRow(SH.sheetRows[index], y,
                    "|cffffd200" .. abil.key .. " |r" .. ColorSigned(AbilityMod(AbilityScore(abil.key))), "")
                y = y - 13; index = index + 1
                for _, skill in ipairs(group) do
                    if SH.sheetRows[index] then
                        SetSheetRow(SH.sheetRows[index], y, "   " .. skill.name, ColorSigned(SkillTotal(skill)),
                            skill.name, skill.desc or ("Caracteristica: " .. abil.key .. "."),
                            { labelWidth = 140, valueWidth = 32 })
                        y = y - 13; index = index + 1
                    end
                end
            end
        end
    elseif view == "details" then
        SetSheetBar(SH.levelBar, "Atributos", -2, true)
        if SH.xpBar then SH.xpBar:Hide() end
        -- Tooltips de raza/trasfondo: subraza si existe, si no la raza.
        local raceTipTitle, raceTipText, bgTipTitle, bgTipText
        if data and data.race and HarfordDnDRaces and HarfordDnDRaces.GetRace then
            local rd = HarfordDnDRaces.GetRace(data.race.id)
            local sd = HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(data.race.id, data.race.subraceId)
            local txt = (sd and sd.desc) or (rd and rd.desc)
            if txt and txt ~= "" then raceTipTitle, raceTipText = GetRaceLabel(data), txt end
        end
        if data and data.background and data.background ~= "" and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground then
            local bd = HarfordDnDBackgrounds.GetBackground(data.background)
            local txt = bd and (bd.desc or bd.description)
            -- Trasfondo personalizado (no esta en el libro): usa el 1er parrafo cargado del TRP3.
            if (not txt or txt == "") and data.backgroundDesc and data.backgroundDesc ~= "" then
                txt = data.backgroundDesc
            end
            bgTipTitle, bgTipText = (bd and bd.name) or GetBackgroundLabel(data), txt
        elseif data and data.background and data.background ~= "" then
            bgTipTitle = GetBackgroundLabel(data)
        end
        local rows = {
            { "Puntos de Golpe", hpMax > 0 and (tostring(hpCur) .. " / " .. tostring(hpMax)) or "-" },
            { "Clase de Armadura", tostring(ca) },
            { "Clase", GetClassSummary(data, "\n") },
            { "Raza", GetRaceLabel(data), raceTipTitle, raceTipText },
            { "Trasfondo", GetBackgroundLabel(data), bgTipTitle, bgTipText },
            { "Iniciativa", Signed(dexMod + initBonus) },
            -- 7,5 + 1,5 da "9.0" con tostring; se recorta el decimal cuando es entero.
            { "Velocidad", speed and (string.format((speed % 1 == 0) and "%d m" or "%.1f m", speed)) or "-" },
            -- "Bonus Competencia" y no "Competencia" a secas: en esta misma lista hay una fila
            -- "Competencias" (las de armadura/arma/herramienta) y se confundian.
            { "Bonus Competencia", pb and Signed(pb) or "-" },
        }
        if HarfordDnDConditions and HarfordDnDConditions.GetActive then
            local conditionRef = IsInspecting() and S.inspectUnit or "player"
            if conditionRef then
                local labels = {}
                for _, active in ipairs(HarfordDnDConditions.GetActive(conditionRef)) do
                    labels[#labels + 1] = active.definition.label
                end
                if #labels > 0 then
                    rows[#rows + 1] = { "Estados", table.concat(labels, ", "), "Estados activos", table.concat(labels, "\n") }
                end
            end
        end
        if HarfordDnDHitDice and HarfordDnDHitDice.GetTotalMax and HarfordDnDHitDice.GetTotalMax(name) > 0 then
            rows[#rows + 1] = { "Dados de Golpe", HarfordDnDHitDice.GetSummaryText(name) }
        end
        -- Competencias (armadura / arma / herramienta) en UNA sola fila: la lista de filas de
        -- detalle comparte espacio con la barra de "Salvaciones" (fija en -206), asi que una
        -- fila por categoria desbordaria. El desglose completo va en el tooltip.
        if HarfordDnDFeatureEffects then
            -- Mismas lineas que el tooltip del libro: un unico constructor, sin duplicar.
            local lineasProf = API.GetProficiencyLines and API.GetProficiencyLines() or {}
            if #lineasProf > 0 then
                -- El resumen corto de la fila: solo armadura y armas, que son las que caben.
                local corto = {}
                for _, l in ipairs(lineasProf) do
                    local titulo, valor = l:match("^%- |cffffd100([^:]+):|r (.+)$")
                    if titulo == "Armadura" or titulo == "Armas" then corto[#corto + 1] = valor end
                end
                rows[#rows + 1] = { "Competencias", table.concat(corto, " · "),
                    "Competencias", table.concat(lineasProf, "\n") }
            end
        end
        -- Sintonizacion y carga. Solo del personaje PROPIO: `HarfordDnDBurden` resuelve la
        -- Fuerza con `HarfordDnDCalc`, que es el del jugador local, asi que en inspeccion daria
        -- los numeros de uno bajo el nombre de otro. Mejor no ensenar la fila que mentir.
        if HarfordDnDBurden and not IsInspecting() then
            local estado = HarfordDnDBurden.GetStatus()
            if estado then
                local sintonizados = HarfordDnDBurden.GetAttuned()
                local detalle = {}
                for _, entrada in ipairs(sintonizados) do
                    detalle[#detalle + 1] = "|cffffd100" .. tostring(entrada.name) .. "|r"
                end
                if #detalle == 0 then detalle[1] = "Ningun objeto sintonizado." end
                detalle[#detalle + 1] = " "
                detalle[#detalle + 1] = "Un objeto solo se sintoniza con una criatura a la vez, y"
                detalle[#detalle + 1] = "no puedes llevar mas de " .. estado.maxAttuned .. " ni dos copias del mismo."
                rows[#rows + 1] = { "Sintonizacion",
                    string.format("%d / %d", estado.attuned, estado.maxAttuned),
                    "Objetos sintonizados", table.concat(detalle, "\n") }

                -- La carga solo se muestra si hay algun peso DECLARADO: el cliente de WoW no
                -- expone el peso de un objeto, asi que sin datos la cifra seria siempre 0 y
                -- pareceria que no llevas nada encima.
                if estado.carried > 0 or estado.capacity > 0 then
                    local texto = string.format("%d / %d", estado.carried, estado.capacity)
                    if estado.overloaded then texto = "|cffff5555" .. texto .. "|r" end
                    local tip = {
                        "Capacidad = Fuerza x " .. HarfordDnDBurden.CARRY_PER_STRENGTH .. " libras.",
                    }
                    if estado.unknownWeights > 0 then
                        texto = texto .. " |cff808080(+" .. estado.unknownWeights .. "?)|r"
                        tip[#tip + 1] = " "
                        tip[#tip + 1] = "|cffff9900" .. estado.unknownWeights ..
                            " objeto(s) sin peso declarado|r no cuentan en el total:"
                        tip[#tip + 1] = "el peso no viene del juego, lo declara el objeto o el DM."
                    end
                    if estado.overloaded then
                        tip[#tip + 1] = " "
                        tip[#tip + 1] = "|cffff5555Sobrecargado.|r"
                    end
                    rows[#rows + 1] = { "Carga", texto, "Carga", table.concat(tip, "\n") }
                end
            end
        end
        if HarfordDnDMana and HarfordDnDMana.IsEnabled and HarfordDnDMana.IsEnabled(name) then
            local pool = HarfordDnDMana.GetManaPool and HarfordDnDMana.GetManaPool(name) or 0
            -- La variante ya esta ON por defecto; la fila solo tiene sentido para lanzadores
            -- (pool > 0), si no un no-lanzador mostraria "Mana: 0".
            if pool > 0 then
                local ms = HarfordDnDMana.GetMaxSpellLevel and HarfordDnDMana.GetMaxSpellLevel(name) or 0
                rows[#rows + 1] = { "Mana", tostring(pool) .. "  (esp. " .. tostring(ms) .. ")" }
            end
        end
        -- Dentro del scroll: la `y` es relativa al hijo y arranca en 0, porque el propio
        -- ScrollFrame ya esta colocado bajo la barra.
        if SH.attrScroll then SH.attrScroll:Show() end
        local y = 0
        for i, r in ipairs(rows) do
            if r[1] == "Clase" then
                y = y - SetClassSheetRow(SH.sheetRows[i], y, data, { container = SH.attrChild })
            else
                -- 64 + 88 = 152, dentro de los 154 de la fila con scroll. Con los 70 + 104 de
                -- la version sin scroll el valor se salia por debajo de la barra.
                local opts = r[1] == "Trasfondo"
                    and { wrapValue = true, labelTop = true, labelWidth = 64, valueWidth = 88 }
                    or {}
                opts.container = SH.attrChild
                y = y - SetSheetRow(SH.sheetRows[i], y, r[1], "|cffffffff" .. tostring(r[2] or "") .. "|r", r[3], r[4], opts)
            end
        end
        -- El alto del hijo es lo que decide si aparece la barra de scroll.
        if SH.attrChild then SH.attrChild:SetHeight(math.max(10, -y)) end
        SetSheetBar(SH.abilBar, "Salvaciones", SH.savesBarY or -226, true)
        for i, abil in ipairs(list) do
            -- Mismo espacio bajo el titulo que "Caracteristicas": barra - 40 de alto + 3.
            SetSheetRow(SH.sheetRows[#rows + i], (SH.savesBarY or -226) - 37 - (i - 1) * 14, abil.key, ColorSigned(SaveTotal(abil.key)), "Salvacion de " .. abil.key, abil.saveDesc or abil.desc or ("Tirada de salvacion de " .. abil.key .. "."))
        end
    else
        SetSheetBar(SH.levelBar, "Nivel", -2, true)
        if SH.xpBar then
            local xpNivel, xpActual, xpNecesaria = 0, 0, 0
            if HarfordCharacterXP and HarfordCharacterXP.Progress then
                xpNivel, xpActual, xpNecesaria = HarfordCharacterXP.Progress()
            end
            xpNecesaria = math.max(1, tonumber(xpNecesaria) or 1)
            xpActual = math.max(0, math.min(xpNecesaria, tonumber(xpActual) or 0))
            SH.xpBar:SetMinMaxValues(0, xpNecesaria)
            SH.xpBar:SetValue(xpActual)
            SH.xpBar.tipTexto = string.format("%d / %d para el nivel %d",
                xpActual, xpNecesaria, (tonumber(xpNivel) or 0) + 1)
            SH.xpBar:Show()
        end
        -- La ficha no usa el scroll de Atributos: si viene de esa pestana, hay que apagarlo.
        if SH.attrScroll then SH.attrScroll:Hide() end
        local maxTotal = tonumber(HarfordDnDProgression and HarfordDnDProgression.MAX_TOTAL_LEVEL) or 20
        -- La XP puede ir por delante del nivel; ese desfase es lo que habilita la subida.
        local subidaDisponible = HarfordCharacterXP and HarfordCharacterXP.PendingLevelUp
            and HarfordCharacterXP.PendingLevelUp()
        if SH.levelUpButton and not IsInspecting() and total < maxTotal and subidaDisponible then
            SH.levelUpButton:Show()
        end
        if SH.levelValueFrame then SH.levelValueFrame:Show() end
        if SH.levelText then
            SH.levelText:SetText(tostring(total))
            SH.levelText:Show()
        end
        local abilY = SH.abilBarY or S.ABIL_BAR_Y
        local abilDelta = abilY + 70
        SetSheetBar(SH.abilBar, "Caracteristicas", abilY, true)
        for i, abil in ipairs(list) do
            local score = AbilityScore(abil.key)
            local mod = AbilityMod(score)
            -- barra - 40 de alto + 3, la misma regla de espaciado que el resto de secciones.
            SetAbilitySheetRow(SH.sheetRows[i], abilY - 37 - (i - 1) * 15, abil.key,
                score,
                mod,
                AbilityTooltipTitle(abil.key),
                K.ABILITY_TOOLTIP_TEXT[abil.key] or "")
        end
        SetSheetBar(SH.combatBar, "Rasgos", -206 + abilDelta, true)
        -- Lista completa de rasgos (sin tope de 5) en el area scrollable: la scrollbar
        -- aparece sola al desbordar. Las filas fijas sobrantes se ocultan.
        local featureRows = GetClassFeatureRows(100) or GetTRP3FeatureRows(100) or {
            { "Raza", GetRaceLabel(data), "Raza", GetRaceLabel(data) },
            { "Trasfondo", GetBackgroundLabel(data), "Trasfondo", GetBackgroundLabel(data) },
            { "Dotes", GetFeatsLabel(data), "Dotes", GetFeatsLabel(data) },
            { "Bonus Competencia", pb and Signed(pb) or "-", "Bonus Competencia", "Bonificador por competencia actual." },
            { "Puntos de Golpe", hpMax > 0 and (tostring(hpCur) .. " / " .. tostring(hpMax)) or "-", "Puntos de Golpe", "Salud actual / maxima." },
        }
        for i = 7, #SH.sheetRows do
            if SH.sheetRows[i] and SH.sheetRows[i].f then SH.sheetRows[i].f:Hide() end
        end
        SetFeatureScroll(featureRows)
        if SH.featScroll then SH.featScroll:Show() end
    end

    SH.origin:SetText("Raza: " .. GetRaceLabel(data) .. "\nTrasfondo: " .. GetBackgroundLabel(data) .. "\n" .. GetFeatsLabel(data))
end

HarfordCharacterSheet.CreateSheetPage = CreateSheetPage
HarfordCharacterSheet.RefreshSheet = RefreshSheet
HarfordCharacterSheet.RefreshPaperDollSlots = RefreshPaperDollSlots
HarfordCharacterSheet.CreateSidebarTabs = CreateSidebarTabs
HarfordCharacterSheet.RefreshSubtitleClasses = RefreshSubtitleClasses
HarfordCharacterSheet.SkillTotal = SkillTotal
HarfordCharacterSheet.SaveTotal = SaveTotal
