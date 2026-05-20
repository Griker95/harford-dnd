HarfordReputationUI = HarfordReputationUI or {}

local API = HarfordReputationUI

local TEX_MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
local TEX_PARCH = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
local TEX_WHITE = "Interface\\Buttons\\WHITE8x8"
local TEX_REP_BAR = "Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar"
local TEX_SKILLS_BAR = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
local TEX_REP_HIGHLIGHT = "Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar-Highlight"
local TEX_REP_STAR = "Interface\\Common\\ReputationStar"
local TEX_BTN_PLUS = "Interface\\Buttons\\UI-PlusButton-Up"
local TEX_BTN_MINUS = "Interface\\Buttons\\UI-MinusButton-UP"
local TEX_BTN_HILITE = "Interface\\Buttons\\UI-PlusButton-Hilight"
local TEX_STATUS = "Interface\\TargetingFrame\\UI-StatusBar"

local PANEL_W = 390
local PANEL_H = 460
local ROW_H = 24
local LIST_W = 336
local LIST_H = 360
local BAR_W = 101   -- confirmado FrameDump: ReputationBar2ReputationBar width=101
local BAR_H = 13    -- confirmado FrameDump: height=13; caps=BAR_H+8=21
-- BAR_RIGHT eliminado: nativo es RIGHT row RIGHT 0,0 (sin offset)
local HEADER_Y = -62
local LIST_TOP_Y = -86

local panel
local detail
local editor
local adjustPrompt
local selectedFactionId
local searchText = ""
local collapsedHeaders = {}
local manualRows = {}
local manualOffset = 1
local detailUserClosed = false

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[HarfordRep]|r " .. tostring(message or ""))
end

local function EnsureUiStore()
    if type(HarfordReputationStore) ~= "table" then HarfordReputationStore = {} end
    if type(HarfordReputationStore.ui) ~= "table" then HarfordReputationStore.ui = {} end
    if type(HarfordReputationStore.ui.collapsedHeaders) ~= "table" then
        HarfordReputationStore.ui.collapsedHeaders = {}
    end
    collapsedHeaders = HarfordReputationStore.ui.collapsedHeaders
    return HarfordReputationStore.ui
end

local function SavePanelPosition()
    if not panel then return end
    local ui = EnsureUiStore()
    local point, _, relativePoint, x, y = panel:GetPoint(1)
    ui.point = point or "CENTER"
    ui.relativePoint = relativePoint or "CENTER"
    ui.x = x or 0
    ui.y = y or 0
end

local function RestorePanelPosition()
    if not panel then return end
    local ui = EnsureUiStore()
    panel:ClearAllPoints()
    panel:SetPoint(ui.point or "CENTER", UIParent, ui.relativePoint or "CENTER", tonumber(ui.x) or 0, tonumber(ui.y) or 0)
end

local function SetPanelBackground(frame, alpha)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 7, -24)
    bg:SetPoint("BOTTOMRIGHT", -7, 7)
    bg:SetTexture(TEX_MARBLE)
    bg:SetAlpha(alpha or 0.95)
    return bg
end

local function TryHideButtonFramePieces(frame)
    if not frame then return end
    if ButtonFrameTemplate_HidePortrait then pcall(ButtonFrameTemplate_HidePortrait, frame) end
    if ButtonFrameTemplate_HideAttic then pcall(ButtonFrameTemplate_HideAttic, frame) end
    if ButtonFrameTemplate_HideButtonBar then pcall(ButtonFrameTemplate_HideButtonBar, frame) end
    if frame.portrait then frame.portrait:Hide() end
    if frame.PortraitContainer then frame.PortraitContainer:Hide() end
    if frame.Inset then frame.Inset:Hide() end
end

local function MakeButton(parent, text, w, h, point, rel, relPoint, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetPoint(point, rel, relPoint, x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function ColorWrap(argb, text)
    argb = tostring(argb or "ffe0e0e0")
    if #argb == 6 then argb = "ff" .. argb end
    return "|c" .. argb .. tostring(text or "") .. "|r"
end

local function NormalizeColorInput(value)
    value = tostring(value or ""):gsub("#", ""):gsub("|c", "")
    if #value == 6 then value = "ff" .. value end
    if #value ~= 8 or not value:match("^[0-9a-fA-F]+$") then return "ffe0e0e0" end
    return value:lower()
end

local function FormatNum(n)
    n = math.floor(tonumber(n) or 0)
    local neg = n < 0
    local s = tostring(math.abs(n))
    local pos = #s % 3
    local out = pos > 0 and s:sub(1, pos) or ""
    for i = pos + 1, #s, 3 do
        if out ~= "" then out = out .. "." end
        out = out .. s:sub(i, i + 2)
    end
    return (neg and "-" or "") .. (out == "" and "0" or out)
end

local function ColorToRGB(argb)
    argb = NormalizeColorInput(argb)
    return (tonumber(argb:sub(3, 4), 16) or 224) / 255,
        (tonumber(argb:sub(5, 6), 16) or 224) / 255,
        (tonumber(argb:sub(7, 8), 16) or 224) / 255
end

local function StandingIdFromRankName(rankName)
    local name = tostring(rankName or ""):lower()
    if name == "odiado" then return 1 end
    if name == "hostil" then return 2 end
    if name == "adverso" then return 3 end
    if name == "neutral" then return 4 end
    if name == "amistoso" then return 5 end
    if name == "honorable" then return 6 end
    if name == "reverenciado" then return 7 end
    if name == "exaltado" then return 8 end
    return 4
end

local function GetPlayerKeyForDisplay()
    local hasAdminAddon = (HarfordReputationAdmin ~= nil) or (HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true)
    if HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()
        and hasAdminAddon
        and UnitExists and UnitExists("target")
        and UnitIsPlayer and UnitIsPlayer("target")
        and HarfordReputation.GetPlayerKey
    then
        local targetKey = HarfordReputation.GetPlayerKey("target")
        if targetKey and targetKey ~= "" then
            return targetKey, true
        end
    end
    if HarfordReputation and HarfordReputation.GetPlayerKey then
        return HarfordReputation.GetPlayerKey("player"), false
    end
    return UnitName and UnitName("player") or "player", false
end

local function GetDisplayTitle()
    local _, isTarget = GetPlayerKeyForDisplay()
    if isTarget and UnitExists and UnitExists("target") then
        local name = (GetUnitName and GetUnitName("target", true)) or UnitName("target")
        if name and name ~= "" then
            return "Reputacion: " .. name
        end
    end
    return "Reputacion"
end

local function GetDisplayedPoints(factionId)
    local playerKey = GetPlayerKeyForDisplay()
    if HarfordReputation and playerKey then
        return HarfordReputation.GetPlayerPoints(playerKey, factionId)
    end
    return HarfordReputation and HarfordReputation.GetCurrentPlayerPoints(factionId) or 0
end

local function CanShowAdminActions()
    local hasAdminAddon = (HarfordReputationAdmin ~= nil) or (HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true)
    return hasAdminAddon and HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()
end

local function GetSelectedFaction()
    if selectedFactionId and HarfordReputation then return HarfordReputation.GetFaction(selectedFactionId) end
    return nil
end

local function FactionMatchesSearch(faction)
    if searchText == "" then return true end
    local haystack = (tostring(faction.name or "") .. " " .. tostring(faction.description or "") .. " " .. tostring(faction.group or "") .. " " .. tostring(faction.subgroup or "")):lower()
    return haystack:find(searchText, 1, true) ~= nil
end

local function FlatIndent(data)
    if data.isHeader and not data.isChild then return 2 end
    if data.isHeader and data.isChild then return 21 end
    if data.isChild then return 44 end
    return 25
end

local function BuildFlatList()
    if not HarfordReputation then return {} end
    EnsureUiStore()
    local includeHidden = HarfordReputation.CanEdit and HarfordReputation.CanEdit()
    local grouped, groupOrder = {}, {}
    local groupSort, subgroupSort = {}, {}

    local function EnsureGroup(groupName, preload)
        groupName = tostring(groupName or "")
        if groupName == "" then groupName = "Reputaciones Harford" end
        if not grouped[groupName] then
            grouped[groupName] = { root = {}, subgroups = {}, subgroupOrder = {} }
            if preload or searchText ~= "" then
                groupOrder[#groupOrder + 1] = groupName
                grouped[groupName]._listed = true
            end
        end
        return grouped[groupName], groupName
    end

    local function EnsureSubgroup(group, subgroupName)
        subgroupName = tostring(subgroupName or "")
        if subgroupName == "" then return group.root, subgroupName end
        if not group.subgroups[subgroupName] then
            group.subgroups[subgroupName] = {}
            group.subgroupOrder[#group.subgroupOrder + 1] = subgroupName
        end
        return group.subgroups[subgroupName], subgroupName
    end

    if HarfordReputation.GetGroups then
        for groupIndex, groupData in ipairs(HarfordReputation.GetGroups() or {}) do
            local groupName = tostring(groupData.name or "")
            if groupName ~= "" then
                groupSort[groupName] = groupIndex
                subgroupSort[groupName] = {}
                local shouldPreload = includeHidden and searchText == ""
                local group = EnsureGroup(groupName, shouldPreload)
                for subgroupIndex, subgroupName in ipairs(groupData.subgroups or {}) do
                    subgroupName = tostring(subgroupName or "")
                    if subgroupName ~= "" then
                        subgroupSort[groupName][subgroupName] = subgroupIndex
                        if shouldPreload then EnsureSubgroup(group, subgroupName) end
                    end
                end
            end
        end
    end
    for _, faction in ipairs(HarfordReputation.GetFactions(includeHidden) or {}) do
        if FactionMatchesSearch(faction) then
            local group, groupName = EnsureGroup(faction.group or "", false)
            local bucket = EnsureSubgroup(group, faction.subgroup or "")
            if not group._listed then
                groupOrder[#groupOrder + 1] = groupName
                group._listed = true
            end
            bucket[#bucket + 1] = faction
        end
    end

    table.sort(groupOrder, function(a, b)
        local oa = groupSort[a] or 999999
        local ob = groupSort[b] or 999999
        if oa ~= ob then return oa < ob end
        return tostring(a) < tostring(b)
    end)
    local list = {}
    for _, groupName in ipairs(groupOrder) do
        local groupKey = "g:" .. groupName
        local group = grouped[groupName]
        list[#list + 1] = {
            key = groupKey,
            name = groupName,
            isHeader = true,
            isChild = false,
            isCollapsed = collapsedHeaders[groupKey] == true,
            hasRep = false,
        }
        if not collapsedHeaders[groupKey] then
            for _, faction in ipairs(group.root or {}) do
                local points = GetDisplayedPoints(faction.id)
                local standingText, rankColor, rank = HarfordReputation.GetRank(points)
                local minValue, maxValue = 0, 1
                if rank then
                    minValue = tonumber(rank.min) or 0
                    maxValue = tonumber(rank.max) or minValue + 1
                    if maxValue <= minValue then
                        minValue = maxValue - 1
                    end
                end
                list[#list + 1] = {
                    faction = faction,
                    factionId = faction.id,
                    name = faction.name or faction.id,
                    isHeader = false,
                    isChild = false,
                    isCollapsed = false,
                    hasRep = true,
                    value = points,
                    min = minValue,
                    max = maxValue,
                    standingID = StandingIdFromRankName(standingText),
                    standingText = standingText,
                    rankColor = rankColor,
                }
            end
            table.sort(group.subgroupOrder, function(a, b)
                local map = subgroupSort[groupName] or {}
                local oa = map[a] or 999999
                local ob = map[b] or 999999
                if oa ~= ob then return oa < ob end
                return tostring(a) < tostring(b)
            end)
            for _, subgroupName in ipairs(group.subgroupOrder) do
                local factions = group.subgroups[subgroupName]
                local subgroupKey = groupKey .. ":s:" .. subgroupName
                list[#list + 1] = {
                    key = subgroupKey,
                    name = subgroupName,
                    isHeader = true,
                    isChild = true,
                    isCollapsed = collapsedHeaders[subgroupKey] == true,
                    hasRep = false,
                }
                if not collapsedHeaders[subgroupKey] then
                    for _, faction in ipairs(factions or {}) do
                        local points = GetDisplayedPoints(faction.id)
                        local standingText, rankColor, rank = HarfordReputation.GetRank(points)
                        local minValue, maxValue = 0, 1
                        if rank then
                            minValue = tonumber(rank.min) or 0
                            maxValue = tonumber(rank.max) or minValue + 1
                            if maxValue <= minValue then
                                minValue = maxValue - 1
                            end
                        end
                        list[#list + 1] = {
                            faction = faction,
                            factionId = faction.id,
                            name = faction.name or faction.id,
                            isHeader = false,
                            isChild = true,
                            isCollapsed = false,
                            hasRep = true,
                            value = points,
                            min = minValue,
                            max = maxValue,
                            standingID = StandingIdFromRankName(standingText),
                            standingText = standingText,
                            rankColor = rankColor,
                        }
                    end
                end
            end
        end
    end
    return list
end

local function CreateRow(parent)
    -- Estructura de la fila (equivalente nativo: ReputationBar2):
    --   Button (row, LIST_W × ROW_H)
    --   ├── BACKGROUND  solidBg          ← tinte custom para headers
    --   ├── ARTWORK     rowBg            ← área de nombre (fondo texturado)
    --   ├── OVERLAY     FactionName      ← texto nombre
    --   ├── Button      ExpandOrCollapseButton
    --   ├── StatusBar   bar              ← nivel button+1, BAR_W × BAR_H, RIGHT→row RIGHT
    --   │   ├── BACKGROUND  fill (statusBarTexture)
    --   │   ├── OVERLAY -1  leftTex      ← cap izquierdo (OVERLAY -1 → sobre fill, bajo hl)
    --   │   ├── OVERLAY -1  rightTex     ← cap derecho (OVERLAY -1 → sobre fill, bajo hl)
    --   │   ├── ARTWORK     FactionStanding (FontString, ancho completo del bar)
    --   │   └── Frame       ReputationStar (nivel bar+1)
    --   └── Frame       hlFrame          ← nivel bar+1, SetAllPoints(row) → no clipping al bar
    --       └── OVERLAY 0   hl           ← textura única; Highlight1=Highlight2=hl

    local row = CreateFrame("Button", nil, parent)
    row:SetSize(LIST_W, ROW_H)
    row:EnableMouse(true)

    -- Tinte de header (extensión custom): BACKGROUND en el Button
    local solidBg = row:CreateTexture(nil, "BACKGROUND")
    solidBg:SetAllPoints(row)
    solidBg:SetColorTexture(0, 0, 0, 0)
    row.Background = solidBg

    -- StatusBar: RIGHT→row RIGHT 0,0 | 101×13 | fill=UI-Character-Skills-Bar BACKGROUND 0
    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetSize(BAR_W, BAR_H)
    bar:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    bar:SetStatusBarTexture(TEX_SKILLS_BAR)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:EnableMouse(false)
    row.ReputationBar = bar

    -- LeftTexture: OVERLAY -1 en StatusBar, 62×21px, LEFT→bar LEFT 0,0
    -- Sublevel -1: por encima del fill del StatusBar (que en Epsilon renderiza en ARTWORK o
    -- superior, cubriendo los caps si se dejan en ARTWORK). Por debajo de hl1/hl2 (sublevel 0).
    -- texCoord 8→4: {0.7578125,0, 0.7578125,0.328125, 1,0, 1,0.328125}
    --              → SetTexCoord(0.7578125, 1, 0, 0.328125)
    local leftTex = bar:CreateTexture(nil, "OVERLAY", nil, -1)
    leftTex:SetTexture(TEX_REP_BAR)
    leftTex:SetTexCoord(0.7578125, 1, 0, 0.328125)
    leftTex:SetSize(62, BAR_H + 8)
    leftTex:SetPoint("LEFT", bar, "LEFT", 0, 0)
    row.ReputationBarLeftTexture = leftTex

    -- RightTexture: OVERLAY -1 en StatusBar, 42×21px
    -- Anclado RIGHT→bar RIGHT: el cap cierra visualmente el borde derecho de la barra.
    -- En native WoW la barra es ~258px y leftTex solo cubre el 24% izquierdo; en nuestra
    -- barra de 101px, leftTex ya cubre el 61% → el cap derecho debe nacer desde bar.RIGHT,
    -- no desde leftTex.RIGHT (que quedaría fuera del área visible).
    -- texCoord: {0, 0.1640625, 0.34375, 0.671875}
    local rightTex = bar:CreateTexture(nil, "OVERLAY", nil, -1)
    rightTex:SetTexture(TEX_REP_BAR)
    rightTex:SetTexCoord(0, 0.1640625, 0.34375, 0.671875)
    rightTex:SetSize(42, BAR_H + 8)
    rightTex:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    row.ReputationBarRightTexture = rightTex

    -- Background del área de nombre: ARTWORK en el Button, altura=21px
    -- texCoord: porción izquierda de UI-Character-ReputationBar (0 → 0.7578125 horizontal, top strip)
    -- LEFT→row LEFT (indent, fijado en InitializeRow) | RIGHT→bar LEFT 0,0
    local rowBg = row:CreateTexture(nil, "ARTWORK")
    rowBg:SetTexture(TEX_REP_BAR)
    rowBg:SetTexCoord(0, 0.7578125, 0, 0.328125)
    rowBg:SetHeight(BAR_H + 8)
    row.ReputationBarBackground = rowBg

    -- ── HIGHLIGHT en frame dedicado ──────────────────────────────────────────────
    -- hlFrame cubre el row entero → no hay clipping al StatusBar.
    -- Una sola textura (hl); Highlight1 y Highlight2 apuntan al mismo objeto.
    -- Los anchors (indent-dependientes) se fijan en InitializeRow.
    local hlFrame = CreateFrame("Frame", nil, row)
    hlFrame:SetAllPoints(row)
    hlFrame:SetFrameLevel(bar:GetFrameLevel() + 1)
    hlFrame:EnableMouse(false)

    -- Highlight cuerpo: texCoord 0→0.9609375 (sin el cap nativo del spritesheet).
    -- Anchors en InitializeRow (dependen del indent de cada fila).
    local hl = hlFrame:CreateTexture(nil, "OVERLAY", nil, 0)
    hl:SetTexture(TEX_REP_HIGHLIGHT)
    hl:SetTexCoord(0, 0.9609375, 0, 0.4375)
    hl:SetBlendMode("ADD")
    hl:Hide()
    row.Highlight1 = hl

    -- Highlight cap derecho: texCoord 0.9609375→1 (porción cap del spritesheet).
    -- Tamaño fijo 24×(ROW_H+8), anclado a TOPRIGHT de hlFrame; siempre en el borde derecho del row.
    -- 24px = ROW_H para que el cierre visual sea proporcional a la altura de la fila.
    local hlCap = hlFrame:CreateTexture(nil, "OVERLAY", nil, 0)
    hlCap:SetTexture(TEX_REP_HIGHLIGHT)
    hlCap:SetTexCoord(0.9609375, 1, 0, 0.4375)
    hlCap:SetBlendMode("ADD")
    hlCap:SetSize(24, ROW_H + 8)
    hlCap:SetPoint("TOPRIGHT", hlFrame, "TOPRIGHT", 0, 4)
    hlCap:Hide()
    row.Highlight2 = hlCap

    -- ExpandOrCollapseButton: 13×13, hijo del Button, LEFT→row LEFT +3
    local expand = CreateFrame("Button", nil, row)
    expand:SetSize(13, 13)
    expand:SetPoint("LEFT", row, "LEFT", 3, 0)
    expand:SetNormalTexture(TEX_BTN_MINUS)
    expand:SetPushedTexture(TEX_BTN_MINUS)
    expand:SetHighlightTexture(TEX_BTN_HILITE, "ADD")
    -- expand es Button hijo: captura el click antes de que llegue al row padre.
    -- Delegamos explícitamente al mismo handler de colapso del row.
    expand:SetScript("OnClick", function(self)
        local data = self:GetParent().elementData
        if data and data.isHeader and data.key then
            collapsedHeaders[data.key] = not collapsedHeaders[data.key]
            API.Refresh()
        end
    end)
    row.ExpandOrCollapseButton = expand

    -- FactionName: OVERLAY en el Button (OVERLAY del Button se dibuja antes que los hijos,
    -- pero el texto en OVERLAY es legible en el área del nombre donde no hay StatusBar)
    local name = row:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 10)
    name:SetJustifyH("LEFT")
    name:SetJustifyV("MIDDLE")
    name:SetWordWrap(false)
    row.Name = name

    -- FactionStanding: ARTWORK en StatusBar, ocupa todo el ancho del bar para que los números
    -- con separador de miles quepan sin recortar. Centrado horizontal dentro del StatusBar.
    local standing = bar:CreateFontString(nil, "ARTWORK")
    standing:SetFont("Fonts\\FRIZQT__.TTF", 10)
    standing:SetHeight(BAR_H)
    standing:SetJustifyH("CENTER")
    standing:SetJustifyV("MIDDLE")
    standing:SetPoint("LEFT",  bar, "LEFT",  2, 0)
    standing:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    row.FactionStanding = standing

    -- BonusIcon (estrella de rango máximo): Frame 16×16 hijo del StatusBar, nivel bar+1
    -- CENTER→bar LEFT +4,0 | texCoord cuadrante inferior-derecho de ReputationStar
    local starFrame = CreateFrame("Frame", nil, bar)
    starFrame:SetSize(16, 16)
    starFrame:SetPoint("CENTER", bar, "LEFT", 4, 0)
    local starTex = starFrame:CreateTexture(nil, "ARTWORK")
    starTex:SetTexture(TEX_REP_STAR)
    starTex:SetTexCoord(0.5, 1, 0.5, 1)
    starTex:SetAllPoints(starFrame)
    starFrame:Hide()
    row.ReputationStar = starFrame

    -- Hover: highlight (cuerpo + cap) solo en filas de facción, nunca en headers.
    -- OnLeave restaura el highlight si la fila sigue siendo la seleccionada.
    row:SetScript("OnEnter", function(self)
        local data = self.elementData
        if data and not data.isHeader then
            self.Highlight1:Show()
            self.Highlight2:Show()
        end
        if data and data.hasRep and self.FactionStanding then
            if (data.standingID or 0) >= 8 then
                -- Exaltado: barra llena, texto consistente con el visual
                self.FactionStanding:SetText("1.000 / 1.000")
            else
                local cur = (tonumber(data.value) or 0) - (tonumber(data.min) or 0)
                -- +1: el max del rango es exclusivo (igual que WoW nativo)
                local rng = math.max(1, (tonumber(data.max) or 1) - (tonumber(data.min) or 0) + 1)
                self.FactionStanding:SetText(FormatNum(cur) .. " / " .. FormatNum(rng))
            end
        end
    end)
    row:SetScript("OnLeave", function(self)
        local data = self.elementData
        if data and not data.isHeader then
            local isSelected = data.factionId ~= nil and data.factionId == selectedFactionId
            self.Highlight1:SetShown(isSelected)
            self.Highlight2:SetShown(isSelected)
        end
        if data and self.FactionStanding then
            self.FactionStanding:SetText(data.standingText or "")
        end
    end)

    row:SetScript("OnClick", function(self)
        local data = self.elementData
        if not data then return end
        if data.isHeader and data.key then
            collapsedHeaders[data.key] = not collapsedHeaders[data.key]
            API.Refresh()
            return
        end
        if data.factionId then
            selectedFactionId = data.factionId
            detailUserClosed = false
            API.Refresh()
        end
    end)

    return row
end

local function InitializeRow(row, elementData)
    row.elementData = elementData
    local indent = FlatIndent(elementData)
    local isSelected = elementData.factionId ~= nil and elementData.factionId == selectedFactionId

    if elementData.isHeader then
        -- Header: botón expand visible, nombre dorado 12px, bar oculto.
        -- bar:Hide() silencia automáticamente hl1, hl2 y SelectedHighlight (OVERLAY en bar).
        row.ExpandOrCollapseButton:ClearAllPoints()
        row.ExpandOrCollapseButton:SetPoint("LEFT", row, "LEFT", indent + 3, 0)
        row.ExpandOrCollapseButton:SetNormalTexture(
            elementData.isCollapsed and TEX_BTN_PLUS or TEX_BTN_MINUS
        )
        row.ExpandOrCollapseButton:SetPushedTexture(
            elementData.isCollapsed and TEX_BTN_PLUS or TEX_BTN_MINUS
        )
        row.ExpandOrCollapseButton:Show()

        row.Name:ClearAllPoints()
        row.Name:SetPoint("LEFT", row.ExpandOrCollapseButton, "RIGHT", 10, 0)
        row.Name:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.Name:SetFont("Fonts\\FRIZQT__.TTF", 12)
        row.Name:SetText(elementData.name or "")
        row.Name:SetTextColor(1.0, 0.82, 0.0, 1)

        row.ReputationBar:Hide()
        row.ReputationBarBackground:Hide()
        row.FactionStanding:Hide()
        row.ReputationStar:Hide()
        row.Highlight1:Hide()   -- hl1/hl2 ahora en hlFrame (no en bar), hay que ocultarlos explícitamente
        row.Highlight2:Hide()
        -- Tinte de header (extensión custom, no nativo): BACKGROUND directo en el Button
        row.Background:SetColorTexture(
            0.09, 0.075, 0.045,
            elementData.isChild and 0.22 or 0.32
        )
        return
    end

    -- ── Fila de facción ────────────────────────────────────────────────────────
    row.ExpandOrCollapseButton:Hide()
    row.Background:SetColorTexture(0, 0, 0, 0)

    -- Nombre: LEFT→row LEFT (indent+10) | RIGHT→bar LEFT -3
    row.Name:ClearAllPoints()
    row.Name:SetPoint("LEFT", row, "LEFT", indent + 10, 0)
    row.Name:SetPoint("RIGHT", row.ReputationBar, "LEFT", -3, 0)
    row.Name:SetFont("Fonts\\FRIZQT__.TTF", 11)
    row.Name:SetText(elementData.name or "")
    -- Color del nombre = color asignado a la facción (fallback blanco si no tiene color propio)
    local nr, ng, nb = ColorToRGB(elementData.faction and elementData.faction.color or "ffe0e0e0")
    row.Name:SetTextColor(nr, ng, nb, 1)

    -- Background del área de nombre
    row.ReputationBarBackground:ClearAllPoints()
    row.ReputationBarBackground:SetPoint("LEFT",  row, "LEFT",  indent, 0)
    row.ReputationBarBackground:SetPoint("RIGHT", row.ReputationBar, "LEFT", 0, 0)
    row.ReputationBarBackground:Show()

    -- Highlight cuerpo: desde (indent-2) hasta (row.RIGHT - 24), dejando los últimos 24px al cap.
    -- Anclar a row directamente (no a la textura hlCap) para evitar problemas de resolución
    -- de anchors cruzados entre texturas en Epsilon.
    row.Highlight1:ClearAllPoints()
    row.Highlight1:SetPoint("TOPLEFT",     row, "TOPLEFT",     indent - 2,  4)
    row.Highlight1:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -24,        -4)
    row.Highlight1:SetShown(isSelected)
    row.Highlight2:SetShown(isSelected)

    row.ReputationBar:Show()
    row.ReputationBarLeftTexture:Show()
    row.ReputationBarRightTexture:Show()
    row.FactionStanding:Show()

    local minValue = tonumber(elementData.min) or 0
    local maxValue = tonumber(elementData.max) or minValue + 1
    local value    = tonumber(elementData.value) or minValue
    if (elementData.standingID or 0) >= 8 then
        -- Exaltado: barra siempre llena (1000/1000), independientemente del valor exacto
        row.ReputationBar:SetMinMaxValues(0, 1000)
        row.ReputationBar:SetValue(1000)
    else
        row.ReputationBar:SetMinMaxValues(0, math.max(1, maxValue - minValue))
        row.ReputationBar:SetValue(math.max(0, value - minValue))
    end

    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[elementData.standingID or 4]
    if color then
        row.ReputationBar:SetStatusBarColor(color.r or 0.5, color.g or 0.5, color.b or 0.5, 1)
    else
        local r, g, b = ColorToRGB(elementData.rankColor)
        row.ReputationBar:SetStatusBarColor(r, g, b, 1)
    end
    row.FactionStanding:SetText(elementData.standingText or "")
    row.ReputationStar:Hide()  -- sin indicador especial en Exaltado; la barra llena lo comunica
end

local function RefreshDetail()
    if not detail then return end
    local faction = GetSelectedFaction()
    if not faction or detailUserClosed then
        detail:Hide()
        if panel then
            if panel.hideButton then panel.hideButton:Hide() end
            if panel.deleteButton then panel.deleteButton:Hide() end
        end
        return
    end
    detail:Show()
    if detail.icon then
        local iconValue = faction.icon or (HarfordReputation and HarfordReputation.TABARD_ICON) or "INV_Shirt_GuildTabard_01"
        if HarfordReputation and HarfordReputation.ResolveIconTexture then
            detail.icon:SetTexture(HarfordReputation.ResolveIconTexture(iconValue))
        else
            detail.icon:SetTexture(iconValue)
        end
        detail.icon:Show()
    end
    detail.title:SetText(ColorWrap(faction.color, faction.name or faction.id))
    detail.description:SetText(faction.description ~= "" and faction.description or "Sin descripcion.")
    if detail.standing then detail.standing:Hide() end
    if detail.progress then detail.progress:Hide() end
    if detail.hidden then detail.hidden:Hide() end
    local showAdmin = CanShowAdminActions()
    if detail.description then
        detail.description:SetSize(180, showAdmin and 108 or 132)
    end
    if detail.adjustBtn then
        detail.adjustBtn:SetShown(showAdmin)
        if showAdmin then
            local hasTarget = UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target")
            if hasTarget then
                detail.adjustBtn:SetText("Ajustar: " .. (UnitName("target") or "target"))
            else
                detail.adjustBtn:SetText("Ajustar (propio)")
            end
        end
    end
    if panel then
        if panel.hideButton then panel.hideButton:Hide() end
        if panel.deleteButton then panel.deleteButton:Hide() end
    end
    if detail.adjust then detail.adjust:Hide() end
    if detail.reset  then detail.reset:Hide()  end
    if detail.link   then detail.link:Hide()   end
end

local function RefreshManualRows(list)
    local maxOffset = math.max(1, #list - #manualRows + 1)
    if manualOffset < 1 then manualOffset = 1 end
    if manualOffset > maxOffset then manualOffset = maxOffset end
    for i, row in ipairs(manualRows) do
        local data = list[manualOffset + i - 1]
        if data then
            InitializeRow(row, data)
            row:Show()
        else
            row.elementData = nil
            row:Hide()
        end
    end
    if panel.scrollUp then panel.scrollUp:SetEnabled(manualOffset > 1) end
    if panel.scrollDown then panel.scrollDown:SetEnabled(manualOffset < maxOffset) end
end

local function RefreshScrollBox(list)
    if not panel or not panel.ScrollBox then return false end
    if not CreateDataProvider then return false end
    local provider = CreateDataProvider()
    for _, data in ipairs(list) do provider:Insert(data) end
    panel.ScrollBox:SetDataProvider(provider, ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
    return true
end

local function RefreshAdminButton()
    if not panel or not panel.adminButton then return end
    local haAdmin = (HarfordReputationAdmin and HarfordReputationAdmin.Toggle ~= nil)
        or (HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true)
    local isDM = HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()
    panel.adminButton:SetShown(haAdmin == true and isDM == true)
end

local function RefreshRows()
    if not panel or not HarfordReputation then return end
    local titleText = GetDisplayTitle()
    if panel.TitleText then panel.TitleText:SetText(titleText) end
    if panel.harfordTitle then panel.harfordTitle:SetText(titleText) end
    local list = BuildFlatList()
    if not selectedFactionId then
        for _, data in ipairs(list) do
            if data.factionId then
                selectedFactionId = data.factionId
                break
            end
        end
    end
    if not RefreshScrollBox(list) then
        RefreshManualRows(list)
    end
    RefreshDetail()
    RefreshAdminButton()
end

function API.Refresh()
    RefreshRows()
end

local function AdjustOwnSelected(delta)
    local faction = GetSelectedFaction()
    if not faction or not HarfordReputation then return end
    local playerKey, guildName
    if HarfordReputation.RememberPlayerGuild then
        playerKey, guildName = HarfordReputation.RememberPlayerGuild("player")
    end
    if not playerKey and HarfordReputation.GetPlayerKey then
        playerKey = HarfordReputation.GetPlayerKey("player")
    end
    if not playerKey then Print("Jugador propio invalido."); return end
    local ok, err = HarfordReputation.AdjustPlayerPoints(playerKey, faction.id, delta, { guildName = guildName })
    if not ok then Print(err) end
    RefreshRows()
end

local function AdjustTargetSelected(delta)
    local faction = GetSelectedFaction()
    if not faction then return end
    local ok, err = HarfordReputation.AdjustTarget(faction.id, delta)
    if not ok then Print(err) end
    RefreshRows()
end

local function ResetSelected()
    local faction = GetSelectedFaction()
    if not faction then return end
    local ok, err = HarfordReputation.ResetTarget(faction.id)
    if not ok then Print(err) end
    RefreshRows()
end

local function LinkSelectedNpc()
    local faction = GetSelectedFaction()
    if not faction then return end
    local ok, err = HarfordReputation.LinkFactionToUnit("target", faction.id)
    if ok then Print("NPC vinculado a " .. tostring(faction.name or faction.id) .. ".") else Print(err) end
end

local function ToggleSelectedHidden()
    local faction = GetSelectedFaction()
    if not faction then return end
    local ok, err = HarfordReputation.SetFactionHidden(faction.id, not faction.hidden)
    if not ok then Print(err) end
    RefreshRows()
end

local function DeleteSelectedFaction()
    local faction = GetSelectedFaction()
    if not faction then return end
    local ok, err = HarfordReputation.DeleteFaction(faction.id)
    if ok then selectedFactionId = nil else Print(err) end
    RefreshRows()
end

local function OpenFactionEditor()
    if HarfordReputationAdmin and HarfordReputationAdmin.Open then
        HarfordReputationAdmin.Open()
    else
        Print("HarfordReputationAdmin no esta cargado (solo disponible en el addon HarfordAdmin).")
    end
end

local function BuildScrollBox(parent)
    local okBox, scrollBox = pcall(CreateFrame, "Frame", "HarfordReputationScrollBox", parent, "WowScrollBoxList")
    local okBar, scrollBar = pcall(CreateFrame, "EventFrame", "HarfordReputationScrollBar", parent, "WowTrimScrollBar")
    if not okBox or not okBar or not scrollBox or not scrollBar then return false end
    scrollBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, LIST_TOP_Y)
    scrollBox:SetSize(LIST_W, LIST_H)
    -- Scrollbar pegado al borde interior derecho del panel (no al scrollbox) para evitar el hueco
    scrollBar:SetPoint("TOPRIGHT",    parent, "TOPRIGHT", -9, LIST_TOP_Y - 2)
    scrollBar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -9, 2)

    if ScrollUtil and CreateScrollBoxListLinearView then
        local view = CreateScrollBoxListLinearView()
        view:SetElementExtent(ROW_H)
        view:SetElementInitializer("Button", nil, function(row, elementData)
            if not row._harfordBuilt then
                local built = CreateRow(row)
                built:SetAllPoints(row)
                row._harfordBuilt = built
            end
            InitializeRow(row._harfordBuilt, elementData)
        end)
        if ScrollUtil.InitScrollBoxListWithScrollBar then
            ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
        elseif ScrollUtil.InitScrollBoxWithScrollBar then
            ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, view)
        else
            scrollBox:Hide()
            scrollBar:Hide()
            return false
        end
        parent.ScrollBox = scrollBox
        parent.ScrollBar = scrollBar
        return true
    end

    scrollBox:Hide()
    scrollBar:Hide()
    return false
end

local function BuildManualList(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, LIST_TOP_Y)
    holder:SetSize(LIST_W, LIST_H)
    manualRows = {}
    for i = 1, math.floor(LIST_H / ROW_H) do
        local row = CreateRow(holder)
        row:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -((i - 1) * ROW_H))
        manualRows[#manualRows + 1] = row
    end
    panel.scrollUp = MakeButton(parent, "▲", 18, 18, "TOPLEFT", holder, "TOPRIGHT", 3, 0, function()
        manualOffset = math.max(1, manualOffset - 1)
        RefreshRows()
    end)
    panel.scrollDown = MakeButton(parent, "▼", 18, 18, "BOTTOMLEFT", holder, "BOTTOMRIGHT", 3, 0, function()
        manualOffset = manualOffset + 1
        RefreshRows()
    end)
end

local function OpenAdjustPrompt()
    if not adjustPrompt then
        adjustPrompt = CreateFrame("Frame", "HarfordRepAdjustPrompt", panel, "BackdropTemplate")
        adjustPrompt:SetSize(200, 85)
        SetPanelBackground(adjustPrompt, 0.98)
        local border = CreateFrame("Frame", nil, adjustPrompt, "DialogBorderTemplate")
        border:SetAllPoints(adjustPrompt)

        local label = adjustPrompt:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", adjustPrompt, "TOP", 0, -14)
        label:SetText("Cantidad (- para restar):")

        local eb = CreateFrame("EditBox", "HarfordRepAdjustEB", adjustPrompt, "InputBoxTemplate")
        eb:SetSize(140, 20)
        eb:SetPoint("TOP", label, "BOTTOM", 0, -6)
        eb:SetAutoFocus(false)
        eb:SetMaxLetters(8)
        eb:SetScript("OnEnterPressed", function(self)
            local val = tonumber(self:GetText())
            if val and val ~= 0 then
                if adjustPrompt.mode == "target" then
                    AdjustTargetSelected(math.floor(val))
                else
                    AdjustOwnSelected(math.floor(val))
                end
            end
            adjustPrompt:Hide()
        end)
        eb:SetScript("OnEscapePressed", function() adjustPrompt:Hide() end)
        adjustPrompt.editBox = eb

        MakeButton(adjustPrompt, "OK", 72, 20,
            "BOTTOMLEFT", adjustPrompt, "BOTTOMLEFT", 16, 10,
            function()
                local val = tonumber(adjustPrompt.editBox:GetText())
                if val and val ~= 0 then
                    if adjustPrompt.mode == "target" then
                        AdjustTargetSelected(math.floor(val))
                    else
                        AdjustOwnSelected(math.floor(val))
                    end
                end
                adjustPrompt:Hide()
            end)
        MakeButton(adjustPrompt, "Cancelar", 80, 20,
            "BOTTOMRIGHT", adjustPrompt, "BOTTOMRIGHT", -16, 10,
            function() adjustPrompt:Hide() end)
        adjustPrompt:Hide()
    end

    -- Toggle: segundo click cierra el prompt
    if adjustPrompt:IsShown() then
        adjustPrompt:Hide()
        return
    end

    local hasTarget = UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target")
    adjustPrompt.mode = hasTarget and "target" or "self"
    adjustPrompt:ClearAllPoints()
    adjustPrompt:SetPoint("BOTTOM", detail, "TOP", 0, 6)
    adjustPrompt.editBox:SetText("")
    adjustPrompt:Show()
    adjustPrompt.editBox:SetFocus()
end

local function CreateDetailPanel()
    -- Hijo directo del panel: hereda strata y level relativos automáticamente
    detail = CreateFrame("Frame", "HarfordReputationDetailPanel", panel)
    detail:SetSize(212, 203)
    detail:SetPoint("TOPLEFT", panel, "TOPRIGHT", 1, -18)
    detail:EnableMouse(true)

    local baseBg = detail:CreateTexture(nil, "BACKGROUND", nil, -1)
    baseBg:SetPoint("TOPLEFT", detail, "TOPLEFT", 7, -7)
    baseBg:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -7, 7)
    baseBg:SetColorTexture(0.02, 0.018, 0.014, 0.96)
    detail.baseBackground = baseBg

    local headerBg = detail:CreateTexture(nil, "BACKGROUND", nil, 0)
    headerBg:SetPoint("TOPLEFT", detail, "TOPLEFT", 7, -7)
    headerBg:SetPoint("BOTTOMRIGHT", detail, "TOPRIGHT", -7, -52)
    headerBg:SetColorTexture(0.04, 0.035, 0.025, 0.88)
    detail.headerBackground = headerBg

    local nativeBg = detail:CreateTexture(nil, "BACKGROUND", nil, 1)
    nativeBg:SetPoint("TOPLEFT", detail, "TOPLEFT", 7, -52)
    nativeBg:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", -7, 7)
    nativeBg:SetTexture(TEX_PARCH)
    nativeBg:SetTexCoord(0, 1, 0, 1)
    nativeBg:SetAlpha(0.92)
    detail.nativeBackground = nativeBg

    local nativeBgShade = detail:CreateTexture(nil, "BACKGROUND", nil, 2)
    nativeBgShade:SetPoint("TOPLEFT", nativeBg, "TOPLEFT", 0, 0)
    nativeBgShade:SetPoint("BOTTOMRIGHT", nativeBg, "BOTTOMRIGHT", 0, 0)
    nativeBgShade:SetColorTexture(0, 0, 0, 0.22)
    detail.nativeBackgroundShade = nativeBgShade

    local nativeCorner = detail:CreateTexture(nil, "OVERLAY")
    nativeCorner:SetSize(32, 32)
    nativeCorner:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -6, -7)
    nativeCorner:SetTexture(131073)
    detail.nativeCorner = nativeCorner

    local detailSeparatorShadow = detail:CreateTexture(nil, "BORDER")
    detailSeparatorShadow:SetPoint("LEFT", detail, "LEFT", 10, 0)
    detailSeparatorShadow:SetPoint("RIGHT", detail, "RIGHT", -10, 0)
    detailSeparatorShadow:SetPoint("TOP", detail, "TOP", 0, -52)
    detailSeparatorShadow:SetHeight(1)
    detailSeparatorShadow:SetColorTexture(0, 0, 0, 0.85)
    detail.detailSeparatorShadow = detailSeparatorShadow

    local detailSeparator = detail:CreateTexture(nil, "BORDER")
    detailSeparator:SetPoint("LEFT", detail, "LEFT", 10, 0)
    detailSeparator:SetPoint("RIGHT", detail, "RIGHT", -10, 0)
    detailSeparator:SetPoint("TOP", detail, "TOP", 0, -53)
    detailSeparator:SetHeight(1)
    detailSeparator:SetColorTexture(0.62, 0.50, 0.23, 0.55)
    detail.detailSeparator = detailSeparator
    local border = CreateFrame("Frame", nil, detail, "DialogBorderTemplate")
    border:SetAllPoints(detail)
    border:SetFrameLevel(detail:GetFrameLevel() + 8)
    detail.border = border

    detail.icon = detail:CreateTexture(nil, "ARTWORK")
    detail.icon:SetSize(30, 30)
    detail.icon:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -18)
    detail.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    detail.closeButton = CreateFrame("Button", nil, detail, "UIPanelCloseButton")
    detail.closeButton:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -3, -3)
    detail.closeButton:SetScript("OnClick", function()
        detailUserClosed = true
        if adjustPrompt then adjustPrompt:Hide() end
        detail:Hide()
    end)

    detail.title = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detail.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    detail.title:SetTextColor(1.0, 0.82, 0.0, 1)
    detail.title:SetPoint("LEFT", detail.icon, "RIGHT", 8, 0)
    detail.title:SetSize(126, 14)
    detail.title:SetJustifyH("LEFT")
    detail.description = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail.description:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    detail.description:SetPoint("TOPLEFT", detail, "TOPLEFT", 16, -56)
    detail.description:SetSize(180, 132)
    detail.description:SetJustifyH("LEFT")
    detail.description:SetJustifyV("TOP")
    detail.standing = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail.standing:Hide()
    detail.progress = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.progress:Hide()
    detail.hidden = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.hidden:Hide()

    detail.adjustBtn = MakeButton(detail, "Ajustar (propio)", 130, 20, "BOTTOMLEFT", detail, "BOTTOMLEFT", 14, 14, OpenAdjustPrompt)
    detail.adjustBtn:Hide()
    detail.adjust = nil
    detail.reset = nil
    detail.link = nil
end

local function CreatePanel()
    if panel then return panel end
    EnsureUiStore()
    panel = CreateFrame("Frame", "HarfordReputationPanel", UIParent, "ButtonFrameTemplate")
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePanelPosition()
    end)
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(60)
    panel:Hide()
    RestorePanelPosition()
    TryHideButtonFramePieces(panel)
    SetPanelBackground(panel, 0.96)
    if panel.TitleText then
        panel.TitleText:SetText("Reputacion")
    end

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -10)
    title:SetText("Reputacion")
    panel.harfordTitle = title
    if panel.TitleText then title:Hide() end

    local headerBg = panel:CreateTexture(nil, "BORDER")
    headerBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 9, -27)
    headerBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, -27)
    headerBg:SetHeight(34)
    headerBg:SetColorTexture(0.03, 0.025, 0.018, 0.86)

    local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    search:SetSize(120, 18)
    search:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -44, -38)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        searchText = tostring(self:GetText() or ""):lower()
        manualOffset = 1
        RefreshRows()
    end)
    panel.search = search
    local searchLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchLabel:SetPoint("RIGHT", search, "LEFT", -4, 0)
    searchLabel:SetText("Buscar")

    -- Boton admin visible solo si HarfordAdmin esta cargado y el jugador esta en modo DM.
    panel.adminButton = MakeButton(panel, "Admin DM", 78, 20, "TOPLEFT", panel, "TOPLEFT", 18, -36, OpenFactionEditor)
    panel.adminButton:SetText("Admin DM")
    panel.adminButton:SetShown(false)  -- se muestra en RefreshRows si CanEdit()

    -- Columna "Faccion": alineada con el inicio del contenido de las filas
    local factionHeader = panel:CreateFontString(nil, "OVERLAY")
    factionHeader:SetFont("Fonts\\FRIZQT__.TTF", 12)
    factionHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 44, HEADER_Y)
    factionHeader:SetTextColor(1, 1, 1, 1)
    factionHeader:SetText("Faccion")

    -- Columna "Prestigio": centrada sobre el StatusBar (LIST_LEFT + LIST_W - BAR_W)
    -- list_left=18, BAR_W=101 → barra empieza en 18+(LIST_W-BAR_W) desde el izq del panel
    local barColX = 18 + LIST_W - BAR_W  -- x del borde izquierdo del StatusBar respecto al panel
    local standingHeader = panel:CreateFontString(nil, "OVERLAY")
    standingHeader:SetFont("Fonts\\FRIZQT__.TTF", 12)
    standingHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", barColX, HEADER_Y)
    standingHeader:SetWidth(BAR_W)
    standingHeader:SetJustifyH("CENTER")
    standingHeader:SetTextColor(1, 1, 1, 1)
    standingHeader:SetText("Prestigio")

    -- Línea separadora entre los encabezados de columna y el listado
    local separator = panel:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, LIST_TOP_Y + 2)
    separator:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, LIST_TOP_Y + 2)
    separator:SetHeight(1)
    separator:SetColorTexture(0.55, 0.44, 0.22, 0.65)

    if not BuildScrollBox(panel) then BuildManualList(panel) end

    CreateDetailPanel()
    return panel
end

function API.Toggle()
    CreatePanel()
    panel:SetShown(not panel:IsShown())
    if panel:IsShown() then
        RefreshRows()
    end
end

function API.Open()
    CreatePanel()
    panel:Show()
    RefreshRows()
end

function API.Close()
    if panel then panel:Hide() end
end

SLASH_HARFORDREP1 = "/harfordrep"
SlashCmdList["HARFORDREP"] = function()
    API.Toggle()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FLAGS_CHANGED")   -- Epsilon lo dispara al cambiar .ph dm
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "HarfordAdmin" and addonName ~= "Harford" then return end
    if event == "PLAYER_LOGIN" and panel then RestorePanelPosition() end
    if event == "PLAYER_FLAGS_CHANGED" then
        RefreshAdminButton()
        return
    end
    RefreshRows()
end)
