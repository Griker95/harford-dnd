-- Ficha emergente de una entrada del tracker de turnos.
--
-- Ventana propia y autocontenida: nada mas del tracker la toca, solo se abre con `ShowEntrySheet`.
-- Por eso sale de HarfordTurns.lua sin arrastrar nada de las tarjetas ni del orden de turnos.
--
-- Mantiene su pool de secciones (`SheetSectionPool`) porque el contenido cambia de una entrada a
-- otra: crear frames en cada apertura estaria prohibido por AGENTS.md.

HarfordTurnsSheet = HarfordTurnsSheet or {}
local API = HarfordTurnsSheet

local SheetFrame
local SheetScrollChild
local SheetText
local SheetSectionPool    = {}
local SheetActiveSections = {}
local RefreshSheetLayout  -- forward declaration (definida mas abajo)
local SHEET_CONTENT_W  = 382
local SECTION_BODY_PAD = 8
local SECTION_GAP      = 6
local SECTION_HDR_H  -- calculada tras leer la fuente

-- Inyectadas por HarfordTurns.
local EntryIconMarkup, GetEntryNameColor, GetPlayerTurnNameColorHex, IsSystemEntry, SetFrameBackground, MakeButton, Print

function API.Init(deps)
    deps = deps or {}
    EntryIconMarkup = deps.EntryIconMarkup or EntryIconMarkup
    GetEntryNameColor = deps.GetEntryNameColor or GetEntryNameColor
    GetPlayerTurnNameColorHex = deps.GetPlayerTurnNameColorHex or GetPlayerTurnNameColorHex
    IsSystemEntry = deps.IsSystemEntry or IsSystemEntry
    SetFrameBackground = deps.SetFrameBackground or SetFrameBackground
    MakeButton = deps.MakeButton or MakeButton
    Print = deps.Print or Print
end

local function MakeSheetLine(parent, point, rel, relPoint, x, y, width, height, r, g, b, a)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetTexture(TEX_WHITE)
    line:SetVertexColor(r, g, b, a or 1)
    line:SetSize(width, height)
    line:SetPoint(point, rel, relPoint, x, y)
    return line
end

local function CreateSheetFrame()
    if SheetFrame then return end

    SheetFrame = CreateFrame("Frame", "HarfordTurnSheetFrame", UIParent, "BackdropTemplate")
    SheetFrame:SetSize(492, 548)
    SheetFrame:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
    SheetFrame:SetFrameStrata("DIALOG")
    SheetFrame:SetMovable(true)
    SheetFrame:EnableMouse(true)
    SheetFrame:RegisterForDrag("LeftButton")
    SheetFrame:SetScript("OnDragStart", SheetFrame.StartMoving)
    SheetFrame:SetScript("OnDragStop", SheetFrame.StopMovingOrSizing)
    SheetFrame:Hide()
    local outerBg = SheetFrame:CreateTexture(nil, "BACKGROUND")
    outerBg:SetPoint("TOPLEFT", SheetFrame, "TOPLEFT", 7, -13)
    outerBg:SetPoint("BOTTOMRIGHT", SheetFrame, "BOTTOMRIGHT", -7, 7)
    outerBg:SetTexture(TEX_WHITE)
    outerBg:SetVertexColor(0.06, 0.015, 0.012, 0.96)

    local panelBg = SheetFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    panelBg:SetPoint("TOPLEFT", SheetFrame, "TOPLEFT", 19, -78)
    panelBg:SetPoint("BOTTOMRIGHT", SheetFrame, "BOTTOMRIGHT", -29, 19)
    panelBg:SetTexture(TEX_WHITE)
    panelBg:SetVertexColor(0.006, 0.006, 0.006, 0.92)

    local border = CreateFrame("Frame", nil, SheetFrame, "DialogBorderTemplate")
    border:SetAllPoints(SheetFrame)
    border:SetFrameStrata(SheetFrame:GetFrameStrata())
    border:SetFrameLevel(SheetFrame:GetFrameLevel() + 5)

    MakeSheetLine(SheetFrame, "TOPLEFT", SheetFrame, "TOPLEFT", 19, -78, 444, 2, 0.78, 0.73, 0.66, 0.95)
    MakeSheetLine(SheetFrame, "BOTTOMLEFT", SheetFrame, "BOTTOMLEFT", 19, 19, 444, 2, 0.78, 0.73, 0.66, 0.95)
    MakeSheetLine(SheetFrame, "TOPLEFT", SheetFrame, "TOPLEFT", 19, -78, 2, 451, 0.78, 0.73, 0.66, 0.95)
    MakeSheetLine(SheetFrame, "TOPRIGHT", SheetFrame, "TOPRIGHT", -29, -78, 2, 451, 0.78, 0.73, 0.66, 0.95)

    SheetFrame.title = SheetFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    SheetFrame.title:SetPoint("TOPLEFT", 32, -31)
    SheetFrame.title:SetPoint("TOPRIGHT", -42, -31)
    SheetFrame.title:SetJustifyH("CENTER")
    SheetFrame.title:SetText("Ficha")
    if STANDARD_TEXT_FONT then
        SheetFrame.title:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    end

    local close = CreateFrame("Button", nil, SheetFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local scroll = CreateFrame("ScrollFrame", nil, SheetFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 42, -102)
    scroll:SetPoint("BOTTOMRIGHT", -44, 31)

    SheetScrollChild = CreateFrame("Frame", nil, scroll)
    SheetScrollChild:SetSize(382, 1)
    scroll:SetScrollChild(SheetScrollChild)

    SheetText = SheetScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SheetText:SetPoint("TOPLEFT", 0, 0)
    SheetText:SetWidth(370)
    SheetText:SetJustifyH("LEFT")
    SheetText:SetJustifyV("TOP")
    if STANDARD_TEXT_FONT then
        SheetText:SetFont(STANDARD_TEXT_FONT, 16, "")
    end
    SheetText:SetTextColor(1.0, 0.93, 0.82)
    SheetText:SetSpacing(6)
    SheetText:SetText("")
end

local function GetTRP3BodyFont()
    -- TRP3 usa GameFontNormal para el cuerpo de su panel About
    if GameFontNormal and GameFontNormal.GetFont then
        local f, s, fl = GameFontNormal:GetFont()
        if f and s and s > 0 then return f, s, fl or "" end
    end
    return "Fonts\\FRIZQT__.TTF", 12, ""
end

local function GetTRP3HeaderFont()
    -- Un punto mas que el cuerpo - igual que el titulo de seccion TRP3
    local f, s, fl = GetTRP3BodyFont()
    return f, s + 2, fl
end

local function GetOrCreateSectionWidget(i)
    if SheetSectionPool[i] then return SheetSectionPool[i] end

    local w = {}
    local bodyFont, bodySize, bodyFlags   = GetTRP3BodyFont()
    local hdrFont,  hdrSize,  hdrFlags    = GetTRP3HeaderFont()

    -- Cabecera (clickable)
    w.header = CreateFrame("Frame", nil, SheetScrollChild)
    w.header:SetHeight(SECTION_HDR_H)
    w.header:EnableMouse(true)

    local hBg = w.header:CreateTexture(nil, "BACKGROUND")
    hBg:SetAllPoints()
    hBg:SetTexture(TEX_WHITE)
    hBg:SetVertexColor(0.18, 0.10, 0.05, 0.6)

    w.arrow = w.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    w.arrow:SetPoint("LEFT", w.header, "LEFT", 6, 0)
    w.arrow:SetWidth(hdrSize + 2)
    w.arrow:SetJustifyH("CENTER")
    w.arrow:SetFont(hdrFont, hdrSize, hdrFlags)
    w.arrow:SetTextColor(0.85, 0.65, 0.25)

    w.label = w.header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    w.label:SetPoint("LEFT", w.arrow, "RIGHT", 4, 0)
    w.label:SetPoint("RIGHT", w.header, "RIGHT", -6, 0)
    w.label:SetJustifyH("LEFT")
    w.label:SetFont(hdrFont, hdrSize, hdrFlags)
    -- Sin SetTextColor: el color lo dicta el markup |cff...| del titulo, igual que TRP3

    w.header:SetScript("OnEnter", function() hBg:SetVertexColor(0.28, 0.16, 0.07, 0.75) end)
    w.header:SetScript("OnLeave", function() hBg:SetVertexColor(0.18, 0.10, 0.05, 0.60) end)
    w.header:SetScript("OnMouseDown", function()
        w.expanded = not w.expanded
        w.arrow:SetText(w.expanded and "-" or "+")
        RefreshSheetLayout()
    end)

    -- Cuerpo
    w.body = CreateFrame("Frame", nil, SheetScrollChild)
    w.body:SetWidth(SHEET_CONTENT_W)

    w.bodyText = w.body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    w.bodyText:SetPoint("TOPLEFT", w.body, "TOPLEFT", 4, -SECTION_BODY_PAD)
    w.bodyText:SetWidth(SHEET_CONTENT_W - 8)
    w.bodyText:SetJustifyH("LEFT")
    w.bodyText:SetJustifyV("TOP")
    w.bodyText:SetFont(bodyFont, bodySize, bodyFlags)
    w.bodyText:SetTextColor(1, 1, 1)
    w.bodyText:SetSpacing(0)

    w.expanded = true
    w.bodyH    = 0
    w.hasTitle = false

    SheetSectionPool[i] = w
    return w
end

local function RefreshSheetLayout()
    local totalY = 0
    for _, w in ipairs(SheetActiveSections) do
        if w.hasTitle then
            w.header:ClearAllPoints()
            w.header:SetPoint("TOPLEFT", SheetScrollChild, "TOPLEFT", 0, -totalY)
            w.header:SetWidth(SHEET_CONTENT_W)
            w.header:Show()
            totalY = totalY + SECTION_HDR_H + 2
        else
            w.header:Hide()
        end

        if w.expanded or not w.hasTitle then
            local bh = w.bodyH + SECTION_BODY_PAD * 2
            w.body:ClearAllPoints()
            w.body:SetPoint("TOPLEFT", SheetScrollChild, "TOPLEFT", 0, -totalY)
            w.body:SetHeight(bh)
            w.body:Show()
            totalY = totalY + bh + SECTION_GAP
        else
            w.body:Hide()
            totalY = totalY + SECTION_GAP
        end
    end
    SheetScrollChild:SetHeight(math.max(416, totalY + 12))
end

local function PopulateSections(sections)
    for i, w in ipairs(SheetSectionPool) do
        if i > #sections then
            w.header:Hide()
            w.body:Hide()
        end
    end
    SheetActiveSections = {}

    for i, sec in ipairs(sections) do
        local w = GetOrCreateSectionWidget(i)
        w.hasTitle = sec.title and sec.title ~= ""
        w.expanded = false

        if w.hasTitle then
            local iconMarkup = ""
            if sec.icon and sec.icon ~= "" and HarfordTRP3 and HarfordTRP3.IconMarkup then
                iconMarkup = HarfordTRP3.IconMarkup(sec.icon, 24) .. " "
            end
            w.label:SetText(iconMarkup .. sec.title)
            w.arrow:SetText("+")
        end

        -- Todas las secciones (incluyendo rasgos) se muestran como texto formateado.
        w.bodyText:SetText(sec.body or "")
        w.bodyText:Show()
        w.bodyH = 0  -- se mide tras show

        SheetActiveSections[#SheetActiveSections + 1] = w
    end
end

local function MeasureAndLayout()
    local offsetY = 0
    for _, w in ipairs(SheetActiveSections) do
        if w.hasTitle then offsetY = offsetY + SECTION_HDR_H + 2 end
        w.body:ClearAllPoints()
        w.body:SetPoint("TOPLEFT", SheetScrollChild, "TOPLEFT", 0, -offsetY)
        w.body:SetHeight(400)
        w.body:Show()
        offsetY = offsetY + 400 + SECTION_GAP
    end
    C_Timer.After(0, function()
        for _, w in ipairs(SheetActiveSections) do
            local bh = w.bodyText:GetStringHeight() or 0
            w.bodyH = bh > 0 and bh or 60
        end
        RefreshSheetLayout()
    end)
end

local function GetEntryTRP3Profile(entry)
    if not entry or not HarfordTRP3 then
        return nil, "HarfordTRP3 no disponible"
    end

    Codec.NormalizeEntryLinks(entry)

    if entry.kind == "player" then
        local tried = {}
        local function TryUnitID(value)
            value = tostring(value or "")
            if value == "" or tried[value] then return nil end
            tried[value] = true
            if HarfordTRP3.GetPlayerProfileByUnitID then
                local profile, err, resolved, resolvedProfileID = HarfordTRP3.GetPlayerProfileByUnitID(value)
                if profile then
                    entry.trpUnitID = resolved or entry.trpUnitID
                    entry.trpProfileID = resolvedProfileID or entry.trpProfileID
                    entry.nameColor = GetPlayerTurnNameColorHex(profile) or entry.nameColor
                    return profile, err, resolved or value
                end
            end
        end

        local candidates = {
            entry.trpUnitID,
            entry.unitName,
            entry.name,
        }
        for _, candidate in ipairs(candidates) do
            local profile, err, resolved = TryUnitID(candidate)
            if profile then return profile, err, resolved end
            local normalized = Codec.NormalizePlayerUnitID(candidate)
            profile, err, resolved = TryUnitID(normalized)
            if profile then return profile, err, resolved end
            local short = tostring(candidate or ""):match("^[^-]+")
            profile, err, resolved = TryUnitID(short)
            if profile then return profile, err, resolved end
        end

        local function EntryMatchesUnit(unit)
            if not UnitExists or not UnitExists(unit) then return false end
            if UnitGUID and entry.id and entry.id ~= "" and UnitGUID(unit) == entry.id then return true end
            local unitID = HarfordTRP3.BuildUnitID and HarfordTRP3.BuildUnitID(unit)
            local fullName = GetUnitName and GetUnitName(unit, true)
            local shortName = UnitName and UnitName(unit)
            local entryUnitID = Codec.NormalizePlayerUnitID(entry.trpUnitID ~= "" and entry.trpUnitID or entry.unitName)
            local entryUnitShort = Ambiguate and Ambiguate(entry.unitName or "", "short") or tostring(entry.unitName or ""):match("^[^-]+")
            return (unitID and entryUnitID ~= "" and unitID == entryUnitID)
                or (fullName and fullName ~= "" and (fullName == entry.unitName or fullName == entry.name))
                or (shortName and shortName ~= "" and (shortName == entry.name or shortName == entryUnitShort))
        end

        local units = { "player", "target", "mouseover", "focus" }
        for i = 1, 4 do units[#units + 1] = "party" .. tostring(i) end
        for i = 1, 40 do units[#units + 1] = "raid" .. tostring(i) end
        for _, unit in ipairs(units) do
            if EntryMatchesUnit(unit) and HarfordTRP3.GetPlayerProfile then
                local profile, err, resolved = HarfordTRP3.GetPlayerProfile(unit)
                entry.nameColor = GetPlayerTurnNameColorHex(profile, unit) or entry.nameColor
                if resolved and resolved ~= "" then
                    entry.trpUnitID = resolved
                end
                if profile and TRP3_API and TRP3_API.register and TRP3_API.register.getUnitIDProfileID and resolved then
                    local okProfileID, resolvedProfileID = pcall(TRP3_API.register.getUnitIDProfileID, resolved)
                    if okProfileID and resolvedProfileID then
                        entry.trpProfileID = resolvedProfileID
                    end
                end
                return profile, err, resolved
            end
        end

        return nil, "Ficha TRP3 de jugador no disponible para esta entrada"
    end

    local fullID = tostring(entry.trpFullID or "")
    if fullID ~= "" and HarfordTRP3.GetEpsilonNpcProfileByFullID then
        return HarfordTRP3.GetEpsilonNpcProfileByFullID(fullID)
    end

    local profileID = tostring(entry.trpProfileID or "")
    if profileID ~= "" and HarfordTRP3.GetEpsilonNpcProfileByProfileID then
        local profile = HarfordTRP3.GetEpsilonNpcProfileByProfileID(profileID)
        if profile then return profile, nil, profileID end
    end

    if UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target") == entry.id and HarfordTRP3.GetEpsilonNpcProfile then
        return HarfordTRP3.GetEpsilonNpcProfile("target")
    end

    return nil, "Ficha TRP3 no disponible para esta entrada"
end

local function ShowEntrySheet(entry)
    if not entry or IsSystemEntry(entry) then return end

    CreateSheetFrame()
    SheetFrame.title:SetText(EntryIconMarkup(entry, 26) .. tostring(entry.name or "Ficha"))
    SheetFrame.title:SetTextColor(GetEntryNameColor(entry))

    local profile, err = GetEntryTRP3Profile(entry)

    -- Intentar modo secciones colapsables
    local sections = profile and HarfordTRP3 and HarfordTRP3.ParseSections
                     and HarfordTRP3.ParseSections(profile)

    if sections then
        SheetText:Hide()
        PopulateSections(sections)
        SheetFrame:Show()
        SheetFrame:Raise()
        -- Medir alturas un frame despues de que WoW renderice los FontStrings
        C_Timer.After(0, MeasureAndLayout)
    else
        -- Fallback: texto plano
        for _, w in ipairs(SheetSectionPool) do w.header:Hide() w.body:Hide() end
        SheetActiveSections = {}

        local text
        if profile and HarfordTRP3 and HarfordTRP3.BuildDisplayText then
            text = HarfordTRP3.BuildDisplayText(profile)
        elseif profile and HarfordTRP3 and HarfordTRP3.GetProfileMainText then
            text = HarfordTRP3.GetProfileMainText(profile)
        end
        if not text or text == "" then
            text = tostring(err or "No hay ficha TRP3 disponible para esta entrada.")
        end
        SheetText:SetText(text)
        SheetText:Show()
        SheetScrollChild:SetHeight(math.max(416, (SheetText:GetStringHeight() or 0) + 24))
        SheetFrame:Show()
        SheetFrame:Raise()
    end
end

-- Las fuentes TRP3 las usa tambien el popup de estados, que sigue en HarfordTurns.
API.GetTRP3BodyFont = GetTRP3BodyFont
API.GetTRP3HeaderFont = GetTRP3HeaderFont
API.ShowEntrySheet = ShowEntrySheet
API.RefreshSheetLayout = function(...) return RefreshSheetLayout(...) end
