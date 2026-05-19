HarfordReputationUI = HarfordReputationUI or {}

local API = HarfordReputationUI

local TEX_MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
local TEX_WHITE = "Interface\\Buttons\\WHITE8x8"
local TEX_REP_BAR = "Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar"
local TEX_SKILLS_BAR = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
local TEX_SKILLS_BAR_BORDER = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder"
local TEX_REP_HIGHLIGHT = "Interface\\PaperDollInfoFrame\\UI-Character-ReputationBar-Highlight"
local TEX_REP_STAR = "Interface\\Common\\ReputationStar"
local TEX_BTN_PLUS = "Interface\\Buttons\\UI-PlusButton-Up"
local TEX_BTN_MINUS = "Interface\\Buttons\\UI-MinusButton-UP"
local TEX_BTN_HILITE = "Interface\\Buttons\\UI-PlusButton-Hilight"
local TEX_STATUS = "Interface\\TargetingFrame\\UI-StatusBar"

local PANEL_W = 360
local PANEL_H = 438
local ROW_H = 24
local LIST_W = 304
local LIST_H = 336
local BAR_W = 104
local BAR_H = 14
local BAR_RIGHT = -14
local HEADER_Y = -58
local LIST_TOP_Y = -82

local panel
local detail
local editor
local selectedFactionId
local searchText = ""
local collapsedHeaders = {}
local manualRows = {}
local manualOffset = 1

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
    if name == "venerado" then return 7 end
    if name == "exaltado" then return 8 end
    return 4
end

local function GetTargetPlayerKey()
    if not UnitExists or not UnitExists("target") or not UnitIsPlayer or not UnitIsPlayer("target") then return nil end
    return HarfordReputation and HarfordReputation.GetPlayerKey and HarfordReputation.GetPlayerKey("target")
end

local function GetPlayerKeyForDisplay()
    local targetKey = GetTargetPlayerKey()
    if HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit() and targetKey then
        return targetKey, true
    end
    if HarfordReputation and HarfordReputation.GetPlayerKey then
        return HarfordReputation.GetPlayerKey("player"), false
    end
    return UnitName and UnitName("player") or "player", false
end

local function GetDisplayedPoints(factionId)
    local playerKey = GetPlayerKeyForDisplay()
    if HarfordReputation and playerKey then
        return HarfordReputation.GetPlayerPoints(playerKey, factionId)
    end
    return HarfordReputation and HarfordReputation.GetCurrentPlayerPoints(factionId) or 0
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
    for _, faction in ipairs(HarfordReputation.GetFactions(includeHidden) or {}) do
        if FactionMatchesSearch(faction) then
            local groupName = tostring(faction.group or "")
            if groupName == "" then groupName = "Reputaciones Harford" end
            local subgroupName = tostring(faction.subgroup or "")
            if not grouped[groupName] then
                grouped[groupName] = { subgroups = {}, subgroupOrder = {} }
                groupOrder[#groupOrder + 1] = groupName
            end
            if not grouped[groupName].subgroups[subgroupName] then
                grouped[groupName].subgroups[subgroupName] = {}
                grouped[groupName].subgroupOrder[#grouped[groupName].subgroupOrder + 1] = subgroupName
            end
            grouped[groupName].subgroups[subgroupName][#grouped[groupName].subgroups[subgroupName] + 1] = faction
        end
    end

    table.sort(groupOrder)
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
            table.sort(group.subgroupOrder)
            for _, subgroupName in ipairs(group.subgroupOrder) do
                local factions = group.subgroups[subgroupName]
                local subgroupKey = groupKey .. ":s:" .. subgroupName
                local useSubgroup = subgroupName ~= ""
                if useSubgroup then
                    list[#list + 1] = {
                        key = subgroupKey,
                        name = subgroupName,
                        isHeader = true,
                        isChild = true,
                        isCollapsed = collapsedHeaders[subgroupKey] == true,
                        hasRep = false,
                    }
                end
                if not useSubgroup or not collapsedHeaders[subgroupKey] then
                    table.sort(factions, function(a, b) return tostring(a.name or "") < tostring(b.name or "") end)
                    for _, faction in ipairs(factions) do
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
                            isChild = useSubgroup,
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
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(LIST_W, ROW_H)
    row:EnableMouse(true)

    local container = CreateFrame("Frame", nil, row)
    container:SetAllPoints(row)
    row.Container = container

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(container)
    bg:SetColorTexture(0.02, 0.018, 0.014, 0)
    row.Background = bg

    local selected = container:CreateTexture(nil, "BACKGROUND", nil, 1)
    selected:SetTexture(TEX_REP_HIGHLIGHT)
    selected:SetPoint("LEFT", container, "LEFT", 0, 0)
    selected:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    selected:SetHeight(ROW_H)
    selected:SetBlendMode("ADD")
    selected:SetAlpha(0.55)
    selected:Hide()
    row.SelectedHighlight = selected

    local mouseHighlight = container:CreateTexture(nil, "HIGHLIGHT")
    mouseHighlight:SetTexture(TEX_REP_HIGHLIGHT)
    mouseHighlight:SetPoint("LEFT", container, "LEFT", 0, 0)
    mouseHighlight:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    mouseHighlight:SetHeight(ROW_H)
    mouseHighlight:SetBlendMode("ADD")
    mouseHighlight:SetAlpha(0.28)
    row.Highlight = mouseHighlight

    local expand = CreateFrame("Button", nil, container)
    expand:SetSize(12, 12)
    expand:SetNormalTexture(TEX_BTN_MINUS)
    expand:SetPushedTexture(TEX_BTN_MINUS)
    expand:SetHighlightTexture(TEX_BTN_HILITE, "ADD")
    row.ExpandOrCollapseButton = expand

    local name = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.Name = name

    local barBg = container:CreateTexture(nil, "BACKGROUND", nil, 2)
    barBg:SetTexture(TEX_REP_BAR)
    barBg:SetSize(BAR_W + 8, BAR_H + 4)
    barBg:SetPoint("CENTER", row.ReputationBar or container, "CENTER", 0, 0)
    row.ReputationBarBackground = barBg

    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetSize(BAR_W, BAR_H)
    bar:SetPoint("RIGHT", container, "RIGHT", BAR_RIGHT, 0)
    bar:SetStatusBarTexture(TEX_SKILLS_BAR)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:EnableMouse(false)
    row.ReputationBar = bar

    barBg:ClearAllPoints()
    barBg:SetPoint("CENTER", bar, "CENTER", 0, 0)

    local barBorder = container:CreateTexture(nil, "OVERLAY", nil, 1)
    barBorder:SetTexture(TEX_SKILLS_BAR_BORDER)
    barBorder:SetTexCoord(0, 1.0, 0.0625, 0.75)
    barBorder:SetSize(BAR_W + 8, BAR_H + 7)
    barBorder:SetPoint("CENTER", bar, "CENTER", 0, 0)
    row.ReputationBarBorder = barBorder

    local standing = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    standing:SetAllPoints(bar)
    standing:SetJustifyH("CENTER")
    standing:SetJustifyV("MIDDLE")
    row.FactionStanding = standing

    local star = container:CreateTexture(nil, "OVERLAY")
    star:SetTexture(TEX_REP_STAR)
    star:SetSize(14, 14)
    star:SetPoint("RIGHT", bar, "LEFT", -2, 0)
    star:Hide()
    row.ReputationStar = star

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
            API.Refresh()
        end
    end)

    return row
end

local function InitializeRow(row, elementData)
    row.elementData = elementData
    local indent = FlatIndent(elementData)
    row.Name:ClearAllPoints()
    row.Name:SetPoint("LEFT", row.Container, "LEFT", indent, 0)
    row.Name:SetWidth(math.max(70, LIST_W - indent - BAR_W - 38))
    row.Name:SetText(elementData.name or "")
    row.SelectedHighlight:SetShown(elementData.factionId and elementData.factionId == selectedFactionId)

    if elementData.isHeader then
        row.ExpandOrCollapseButton:ClearAllPoints()
        row.ExpandOrCollapseButton:SetPoint("LEFT", row.Container, "LEFT", indent, 0)
        row.ExpandOrCollapseButton:SetNormalTexture(elementData.isCollapsed and TEX_BTN_PLUS or TEX_BTN_MINUS)
        row.ExpandOrCollapseButton:SetPushedTexture(elementData.isCollapsed and TEX_BTN_PLUS or TEX_BTN_MINUS)
        row.ExpandOrCollapseButton:Show()
        row.Name:SetPoint("LEFT", row.Container, "LEFT", indent + 16, 0)
        row.Name:SetTextColor(1.0, 0.82, 0.0)
        row.ReputationBar:Hide()
        row.ReputationBarBackground:Hide()
        if row.ReputationBarBorder then row.ReputationBarBorder:Hide() end
        row.FactionStanding:Hide()
        row.ReputationStar:Hide()
        row.Background:SetColorTexture(0.09, 0.075, 0.045, elementData.isChild and 0.18 or 0.28)
        return
    end

    row.ExpandOrCollapseButton:Hide()
    row.Name:SetTextColor(1.0, 0.82, 0.0)
    row.ReputationBar:Show()
    row.ReputationBarBackground:Show()
    if row.ReputationBarBorder then row.ReputationBarBorder:Show() end
    row.FactionStanding:Show()

    local minValue = tonumber(elementData.min) or 0
    local maxValue = tonumber(elementData.max) or minValue + 1
    local value = tonumber(elementData.value) or minValue
    row.ReputationBar:SetMinMaxValues(0, math.max(1, maxValue - minValue))
    row.ReputationBar:SetValue(math.max(0, value - minValue))

    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[elementData.standingID or 4]
    if color then
        row.ReputationBar:SetStatusBarColor(color.r or 0.5, color.g or 0.5, color.b or 0.5, 1)
    else
        local r, g, b = ColorToRGB(elementData.rankColor)
        row.ReputationBar:SetStatusBarColor(r, g, b, 1)
    end
    row.FactionStanding:SetText(elementData.standingText or "")
    row.ReputationStar:SetShown((elementData.standingID or 0) >= 8)
    row.Background:SetColorTexture(0.02, 0.018, 0.014, 0)
end

local function RefreshDetail()
    if not detail then return end
    local faction = GetSelectedFaction()
    if not faction then
        detail:Hide()
        if panel then
            if panel.newButton then panel.newButton:SetShown(HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()) end
            if panel.hideButton then panel.hideButton:Hide() end
            if panel.deleteButton then panel.deleteButton:Hide() end
        end
        return
    end
    local canEdit = HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()
    detail:Show()
    detail.icon:SetTexture(faction.icon or (HarfordReputation and HarfordReputation.TABARD_ICON) or "Interface\\Icons\\INV_Shirt_GuildTabard_01")
    detail.title:SetText(ColorWrap(faction.color, faction.name or faction.id))
    detail.description:SetText(faction.description ~= "" and faction.description or "Sin descripcion.")
    local points = GetDisplayedPoints(faction.id)
    local standingText, rankColor = HarfordReputation.GetRank(points)
    local cur, max = HarfordReputation.GetRankProgress(points)
    detail.standing:SetText("Relacion: " .. ColorWrap(rankColor, standingText) .. " (" .. tostring(points) .. ")")
    detail.progress:SetText("Progreso: " .. tostring(cur) .. " / " .. tostring(max))
    detail.hidden:SetText(faction.hidden and "Oculta para jugadores" or "Visible para jugadores")
    if panel then
        if panel.newButton then panel.newButton:SetShown(canEdit) end
        if panel.hideButton then panel.hideButton:SetShown(canEdit) end
        if panel.deleteButton then panel.deleteButton:SetShown(canEdit) end
    end
    if detail.plus then detail.plus:SetShown(canEdit) end
    if detail.minus then detail.minus:SetShown(canEdit) end
    if detail.reset then detail.reset:SetShown(canEdit) end
    if detail.link then detail.link:SetShown(canEdit) end
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

local function RefreshRows()
    if not panel or not HarfordReputation then return end
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
end

function API.Refresh()
    RefreshRows()
end

local function AdjustSelected(delta)
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
    Print("El editor avanzado de reputacion queda pendiente de migrar al panel SL custom.")
end

local function BuildScrollBox(parent)
    local okBox, scrollBox = pcall(CreateFrame, "Frame", "HarfordReputationScrollBox", parent, "WowScrollBoxList")
    local okBar, scrollBar = pcall(CreateFrame, "EventFrame", "HarfordReputationScrollBar", parent, "WowTrimScrollBar")
    if not okBox or not okBar or not scrollBox or not scrollBar then return false end
    scrollBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, LIST_TOP_Y)
    scrollBox:SetSize(LIST_W, LIST_H)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 3, -2)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 3, 2)

    if ScrollUtil and CreateScrollBoxListLinearView then
        local view = CreateScrollBoxListLinearView()
        view:SetElementExtent(ROW_H)
        view:SetElementInitializer("Frame", nil, function(row, elementData)
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

local function CreateDetailPanel()
    detail = CreateFrame("Frame", "HarfordReputationDetailPanel", panel, "BackdropTemplate")
    detail:SetSize(260, 210)
    detail:SetPoint("TOPLEFT", panel, "TOPRIGHT", 6, -24)
    detail:SetFrameStrata(panel:GetFrameStrata())
    detail:SetFrameLevel(panel:GetFrameLevel() + 8)
    SetPanelBackground(detail, 0.98)
    local border = CreateFrame("Frame", nil, detail, "DialogBorderTemplate")
    border:SetAllPoints(detail)

    detail.icon = detail:CreateTexture(nil, "ARTWORK")
    detail.icon:SetSize(30, 30)
    detail.icon:SetPoint("TOPLEFT", 16, -16)
    detail.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    detail.title = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detail.title:SetPoint("LEFT", detail.icon, "RIGHT", 8, 0)
    detail.title:SetWidth(190)
    detail.title:SetJustifyH("LEFT")
    detail.description = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail.description:SetPoint("TOPLEFT", 18, -56)
    detail.description:SetSize(224, 54)
    detail.description:SetJustifyH("LEFT")
    detail.description:SetJustifyV("TOP")
    detail.standing = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail.standing:SetPoint("TOPLEFT", 18, -116)
    detail.progress = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.progress:SetPoint("TOPLEFT", 18, -136)
    detail.hidden = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    detail.hidden:SetPoint("TOPLEFT", 18, -156)

    detail.plus = MakeButton(detail, "+100", 48, 20, "BOTTOMLEFT", detail, "BOTTOMLEFT", 14, 14, function() AdjustSelected(100) end)
    detail.minus = MakeButton(detail, "-100", 48, 20, "BOTTOMLEFT", detail, "BOTTOMLEFT", 66, 14, function() AdjustSelected(-100) end)
    detail.reset = MakeButton(detail, "Reset", 52, 20, "BOTTOMLEFT", detail, "BOTTOMLEFT", 118, 14, ResetSelected)
    detail.link = MakeButton(detail, "NPC", 44, 20, "BOTTOMLEFT", detail, "BOTTOMLEFT", 174, 14, LinkSelectedNpc)
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
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(120)
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
    if panel.TitleText then title:Hide() end

    local headerBg = panel:CreateTexture(nil, "BORDER")
    headerBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 9, -27)
    headerBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, -27)
    headerBg:SetHeight(34)
    headerBg:SetColorTexture(0.03, 0.025, 0.018, 0.86)

    local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    search:SetSize(112, 18)
    search:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -42, -36)
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

    local factionHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    factionHeader:SetPoint("TOPLEFT", 32, HEADER_Y)
    factionHeader:SetText("Faccion")
    local standingHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    standingHeader:SetPoint("TOPRIGHT", -44, HEADER_Y)
    standingHeader:SetText("Prestigio")

    if not BuildScrollBox(panel) then BuildManualList(panel) end

    panel.newButton = MakeButton(panel, "Nueva", 58, 20, "BOTTOMRIGHT", panel, "BOTTOMRIGHT", -82, 16, OpenFactionEditor)
    panel.hideButton = MakeButton(panel, "Ocultar", 62, 20, "LEFT", panel.newButton, "RIGHT", 4, 0, ToggleSelectedHidden)
    panel.deleteButton = MakeButton(panel, "Borrar", 58, 20, "RIGHT", panel.newButton, "LEFT", -4, 0, DeleteSelectedFaction)
    CreateDetailPanel()
    return panel
end

function API.Toggle()
    CreatePanel()
    panel:SetShown(not panel:IsShown())
    if panel:IsShown() then
        panel:Raise()
        RefreshRows()
    end
end

function API.Open()
    CreatePanel()
    panel:Show()
    panel:Raise()
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
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" and panel then RestorePanelPosition() end
    RefreshRows()
end)
