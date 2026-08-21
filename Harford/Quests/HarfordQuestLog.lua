------------------------------------------------------------
-- HarfordQuestLog - Registro de misiones Harford.
--
-- Replica la composicion de ClassicQuestLog 2.1.0 para Shadowlands:
-- ButtonFrameTemplate, HybridScrollFrameTemplate y QuestScrollFrameTemplate.
-- El estado de las misiones vive exclusivamente en HarfordQuests.
------------------------------------------------------------

HarfordQuestLog = HarfordQuestLog or {}
local API = HarfordQuestLog

local FRAME_W, FRAME_H = 667, 496
local ROW_HEIGHT = 16
local MIN_CONTENT_W = 150
local frame
local listButtons
local selectedId
local collapsedCategories = {}
local optionsDropdown  -- dropdown DM del boton "Opciones" (creado bajo demanda)

local function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    HarfordChat.Print(table.concat(parts, " "))
end

local function PlayQuestSound(event)
    if HarfordUISounds and HarfordUISounds.Play then
        HarfordUISounds.Play(event)
    end
end

local function GetScrollBar(scrollFrame)
    return scrollFrame and (scrollFrame.scrollBar or scrollFrame.ScrollBar or _G[scrollFrame:GetName() .. "ScrollBar"])
end

local function SetAtlasOrTexture(region, atlas, texture)
    if region and region.SetAtlas and atlas then
        local ok, usable = pcall(region.SetAtlas, region, atlas)
        if ok and usable ~= false then return true end
    end
    if region and texture then region:SetTexture(texture) end
    return false
end

local function GetContentWidth(scrollFrame)
    return math.max(math.floor((scrollFrame:GetWidth() or 0) + 0.5), MIN_CONTENT_W)
end

local function UpdateListBackground(scrollFrame, hasQuests)
    local background = scrollFrame and scrollFrame.background
    if not background then return end
    -- QuestMapLogAtlas contiene dos mitades: telarana para un registro vacio
    -- y mapa oscuro para uno con misiones. ClassicQuestLog cambia este UV en
    -- cada UpdateLog; sin ello se ve la hoja completa de sprites.
    if hasQuests then
        background:SetTexCoord(0, 0.28125, 0.5, 1)
    else
        background:SetTexCoord(0, 0.28125, 0, 0.5)
    end
end

local function SetQuestText(fs, r, g, b)
    if fs and fs.SetTextColor then fs:SetTextColor(r, g, b) end
end

local function GetCategoryInfo(key)
    local data = HarfordContracts and HarfordContracts.Data
    local category = data and data.GetTypeByKey and data.GetTypeByKey(key)
    if category then return category end
    return {
        key = key ~= "" and key or "harford",
        label = key ~= "" and key or "Misiones Harford",
        icon = "INV_Misc_Note_01",
    }
end

local function GetDifficultyColor(key)
    local data = HarfordContracts and HarfordContracts.Data
    local difficulty = data and data.GetDifficulty and data.GetDifficulty(key)
    return (difficulty and difficulty.color) or { 1, 0.82, 0 }
end

-- Color de dificultad como hex "ffRRGGBB" (misma fuente que la lista) para el titulo del tooltip
-- del enlace de chat. El TEXTO del enlace lo bloquea TRP3 en amarillo; el tooltip si es controlable.
local function DifficultyColorHex(key)
    local c = GetDifficultyColor(key)
    return string.format("ff%02x%02x%02x",
        math.floor((c[1] or 1) * 255 + 0.5),
        math.floor((c[2] or 0.82) * 255 + 0.5),
        math.floor((c[3] or 0) * 255 + 0.5))
end

local function EnrichQuestFromContract(quest)
    local data = HarfordContracts and HarfordContracts.Data
    local contract = data and data.GetContractById and data.GetContractById(quest.id)
    if not contract then return quest end
    -- Las misiones aceptadas antes de introducir los metadatos siguen siendo
    -- validas. El log recupera su categoria/dificultad desde el contrato sin
    -- reescribir SavedVariables por el mero hecho de dibujarse.
    if not quest.category or quest.category == "" then quest.category = contract.category or "" end
    if not quest.difficulty or quest.difficulty == "" then quest.difficulty = contract.difficulty or "normal" end
    if not quest.icon then
        local category = data.GetTypeByKey and data.GetTypeByKey(contract.category)
        quest.icon = category and category.icon or nil
    end
    return quest
end

local function BuildListItems(quests)
    local groups, order = {}, {}
    for _, quest in ipairs(quests) do
        quest = EnrichQuestFromContract(quest)
        local key = tostring(quest.category or "")
        if not groups[key] then
            groups[key] = {}
            order[#order + 1] = key
        end
        groups[key][#groups[key] + 1] = quest
    end

    local out = {}
    for _, key in ipairs(order) do
        local category = GetCategoryInfo(key)
        out[#out + 1] = {
            kind = "header",
            key = key,
            category = category,
            collapsed = collapsedCategories[key] == true,
        }
        if not collapsedCategories[key] then
            for _, quest in ipairs(groups[key]) do
                out[#out + 1] = { kind = "quest", quest = quest, category = category }
            end
        end
    end
    return out
end

local function HasExpandedCategories(items)
    for _, item in ipairs(items) do
        if item.kind == "header" and not item.collapsed then return true end
    end
    return false
end

local function CreateListRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(MIN_CONTENT_W, ROW_HEIGHT)

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    row.highlight:SetBlendMode("ADD")
    row.highlight:Hide()

    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLeft")
    row.text:SetPoint("LEFT", 20, 0)
    row.text:SetPoint("RIGHT", -20, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)

    row.check = row:CreateTexture(nil, "OVERLAY")
    row.check:SetSize(16, 16)
    row.check:SetPoint("LEFT", row.text, "RIGHT", 0, 0)
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:Hide()
    row.expand = row:CreateTexture(nil, "OVERLAY")
    row.expand:SetSize(16, 16)
    row.expand:SetPoint("LEFT", 2, 0)
    row.expand:Hide()
    row.expandHighlight = row:CreateTexture(nil, "OVERLAY")
    row.expandHighlight:SetSize(16, 16)
    row.expandHighlight:SetPoint("LEFT", 3, 0)
    row.expandHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    row.expandHighlight:SetBlendMode("ADD")
    row.expandHighlight:SetAlpha(0.75)
    row.expandHighlight:Hide()
    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("RIGHT", row.check, "LEFT", -2, 0)
    row.icon:Hide()
    row:SetScript("OnClick", function(self)
        if self.item and self.item.kind == "header" then
            local key = self.item.key
            collapsedCategories[key] = not collapsedCategories[key]
            API.Refresh()
        elseif self.questId then
            if IsShiftKeyDown and IsShiftKeyDown() then
                -- Imita al registro nativo: con un editbox de chat abierto, shift-click INSERTA el
                -- enlace de mision clicable; si no hay chat abierto, togglea el rastreo (como antes).
                local editBox = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
                local quest = self.item and self.item.quest
                if editBox and quest and HarfordTRP3 and HarfordTRP3.InsertQuestChatLink then
                    -- inserta [TRP3:id] enviable (TRP3 lo reconstruye); tooltip con titulo por dificultad
                    HarfordTRP3.InsertQuestChatLink(quest, DifficultyColorHex(quest.difficulty))
                elseif HarfordQuests and HarfordQuests.ToggleTracked then
                    HarfordQuests.ToggleTracked(self.questId)
                    API.Refresh()
                end
                return
            else
                selectedId = self.questId
            end
            API.Refresh()
        end
    end)
    row:SetScript("OnEnter", function(self)
        if self.item and self.item.kind == "header" then self.expandHighlight:Show() end
    end)
    row:SetScript("OnLeave", function(self) self.expandHighlight:Hide() end)
    return row
end

local function CreateDetailText(parent, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template)
    fs:SetWidth(MIN_CONTENT_W)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    return fs
end

local function CreateAllTab(parent)
    -- ClassicQuestLog construye esta pestaña con las tres piezas
    -- UI-QuestLogSortTab. No es un UIPanelButton azul.
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(75, 32)
    local left = button:CreateTexture(nil, "BACKGROUND")
    left:SetTexture("Interface\\QuestFrame\\UI-QuestLogSortTab-Left")
    left:SetSize(8, 32)
    left:SetPoint("LEFT")
    local right = button:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\QuestFrame\\UI-QuestLogSortTab-Right")
    right:SetSize(8, 32)
    right:SetPoint("RIGHT")
    local middle = button:CreateTexture(nil, "BACKGROUND")
    middle:SetTexture("Interface\\QuestFrame\\UI-QuestLogSortTab-Middle")
    middle:SetPoint("LEFT", left, "RIGHT")
    middle:SetPoint("RIGHT", right, "LEFT")
    middle:SetHeight(32)
    button.expand = button:CreateTexture(nil, "ARTWORK")
    button.expand:SetSize(16, 16)
    button.expand:SetPoint("LEFT", 7, -4)
    SetAtlasOrTexture(button.expand, "Campaign_HeaderIcon_Open", "Interface\\Buttons\\UI-MinusButton-UP")
    button.expandHighlight = button:CreateTexture(nil, "OVERLAY")
    button.expandHighlight:SetSize(16, 16)
    button.expandHighlight:SetPoint("LEFT", 7, -4)
    button.expandHighlight:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    button.expandHighlight:SetBlendMode("ADD")
    button.expandHighlight:SetAlpha(0.75)
    button.expandHighlight:Hide()
    button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalLeft")
    button.text:SetPoint("CENTER", 6, -4)
    button.text:SetText("Todas")
    button:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
        self.expandHighlight:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.text:SetTextColor(1, 0.82, 0)
        self.expandHighlight:Hide()
    end)
    button.text:SetTextColor(1, 0.82, 0)
    return button
end

local function CreateCountFrame(parent)
    local ok, count = pcall(CreateFrame, "Frame", nil, parent, "InsetFrameTemplate3")
    if not ok or not count then
        count = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    end
    count:SetSize(120, 20)
    count:SetPoint("TOPLEFT", 132, -33)
    count.text = count:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count.text:SetPoint("CENTER")
    return count
end

local function CreateFooterButton(parent, width)
    local ok, button = pcall(CreateFrame, "Button", nil, parent, "MagicButtonTemplate")
    if not ok or not button then
        button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    end
    button:SetSize(width, 22)
    return button
end

local function CreateClassicScrollFrame(name, parent)
    local ok, scroll = pcall(CreateFrame, "ScrollFrame", name, parent, "HybridScrollFrameTemplate")
    if not ok or not scroll then
        scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    end
    scroll.scrollBarHideIfUnscrollable = false
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        self:SetVerticalScroll(math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 36)))
    end)

    local bar = GetScrollBar(scroll)
    if bar then
        -- El template ya conoce sus anclajes. Reanclar sus hijos desde Lua
        -- rompe los limites del inset en el cliente Epsilon.
        bar:Show()
        bar:SetAlpha(1)
        if bar.ScrollUpButton then bar.ScrollUpButton:Show() end
        if bar.ScrollDownButton then bar.ScrollDownButton:Show() end
    end
    return scroll
end

local function AddListScrollChrome(scroll)
    if not scroll or scroll.HarfordScrollChrome then return end

    -- Mismo carril de tres piezas que ClassicQuestLog/log.xml. El template
    -- hibrido aporta el slider; esta carcasa lo integra visualmente en el
    -- borde derecho de la pagina izquierda.
    local texture = "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar"
    local top = scroll:CreateTexture(nil, "BACKGROUND", nil, -7)
    top:SetTexture(texture)
    top:SetSize(29, 102)
    top:SetPoint("TOPLEFT", scroll, "TOPRIGHT", -6, 5)
    top:SetTexCoord(0, 0.445, 0, 0.4)

    local bottom = scroll:CreateTexture(nil, "BACKGROUND", nil, -7)
    bottom:SetTexture(texture)
    bottom:SetSize(29, 106)
    bottom:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -6, -2)
    bottom:SetTexCoord(0.515625, 0.960625, 0, 0.4140625)

    local middle = scroll:CreateTexture(nil, "BACKGROUND", nil, -7)
    middle:SetTexture(texture)
    middle:SetWidth(29)
    middle:SetPoint("TOP", top, "BOTTOM")
    middle:SetPoint("BOTTOM", bottom, "TOP")
    middle:SetTexCoord(0, 0.445, 0.75, 1)

    local bar = GetScrollBar(scroll)
    if bar then
        scroll.scrollBar = bar
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 0, -13)
        bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 0, 14)
        bar:Show()
    end
    scroll.HarfordScrollChrome = { top = top, middle = middle, bottom = bottom }
end

local function SetListRowItem(row, item)
    row.item = item
    row.questId = nil
    row.check:Hide()
    row.icon:Hide()
    row.expand:Hide()
    row.expandHighlight:Hide()
    row.highlight:Hide()
    row.text:ClearAllPoints()

    if item.kind == "header" then
        row.text:SetPoint("LEFT", 20, 0)
        row.text:SetText(item.category.label)
        row.text:SetWidth(math.min(row:GetWidth() - 42, row.text:GetStringWidth()))
        SetQuestText(row.text, 0.75, 0.75, 0.75)
        SetAtlasOrTexture(
            row.expand,
            item.collapsed and "Campaign_HeaderIcon_Closed" or "Campaign_HeaderIcon_Open",
            item.collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-UP"
        )
        row.expand:Show()
        return
    end

    local quest = item.quest
    row.questId = quest.id
    row.text:SetPoint("LEFT", 22, 0)
    row.text:SetText((quest.title or "") .. (quest.completed and " (Completada)" or ""))
    local color = GetDifficultyColor(quest.difficulty)
    local selected = quest.id == selectedId
    SetQuestText(row.text, selected and 1 or color[1], selected and 1 or color[2], selected and 1 or color[3])
    if selected then row.highlight:SetVertexColor(color[1], color[2], color[3]) end
    row.highlight:SetShown(selected)
    row.check:SetShown(quest.tracked == true)
    -- El registro no muestra iconos por fila: solo conserva la marca de
    -- rastreo y el espacio nativo de la derecha.
    local rightPadding = 20
    if quest.tracked then rightPadding = rightPadding + 16 end
    row.text:SetWidth(math.min(row:GetWidth() - 22 - rightPadding, row.text:GetStringWidth()))
end

local function SetDetailColors(d)
    for _, fs in ipairs({ d.title, d.descHeader, d.rewardHeader }) do
        SetQuestText(fs, 0, 0, 0)
    end
    for _, fs in ipairs({ d.objectives, d.description, d.reward, d.empty }) do
        SetQuestText(fs, 0.08, 0.06, 0.03)
    end
end

local function UpdateTopControls(questCount)
    if not frame then return end
    frame.countFrame.text:SetText(string.format("Misiones: |cffffffff%d/35|r", questCount))
    frame.allButton:SetEnabled(questCount > 0)
    local items = BuildListItems((HarfordQuests and HarfordQuests.GetAccepted and HarfordQuests.GetAccepted()) or {})
    SetAtlasOrTexture(
        frame.allButton.expand,
        HasExpandedCategories(items) and "Campaign_HeaderIcon_Open" or "Campaign_HeaderIcon_Closed",
        HasExpandedCategories(items) and "Interface\\Buttons\\UI-MinusButton-UP" or "Interface\\Buttons\\UI-PlusButton-Up"
    )
end

local function CreateDetailControls(parent)
    local d = {}
    d.content = parent
    d.padX = 8
    d.padTop = 10
    d.padBottom = 8
    d.empty = CreateDetailText(parent, "QuestFont")
    d.empty:SetPoint("TOPLEFT", d.padX, -d.padTop)
    d.empty:SetText("No tienes misiones aceptadas.")

    d.title = CreateDetailText(parent, "QuestTitleFont")
    d.objectives = CreateDetailText(parent, "QuestFont")
    d.descHeader = CreateDetailText(parent, "QuestTitleFont")
    d.description = CreateDetailText(parent, "QuestFont")
    d.rewardHeader = CreateDetailText(parent, "QuestTitleFont")
    d.reward = CreateDetailText(parent, "QuestFont")  -- fallback de texto (misiones sin rewards estructurados)
    d.rewardButtons = {}  -- pool de QuestItemTemplate (icono+nombre+cantidad), igual que el ArcSpell
    d.rewLines = {}       -- pool de filas dinero/rep/xp (etiqueta FRIZQT + valor ARIALN blanco)
    d.descHeader:SetText("Descripcion")
    d.rewardHeader:SetText("Recompensa")
    SetDetailColors(d)
    return d
end

local function BuildFrame()
    if frame then return frame end

    frame = _G.HarfordQuestLogFrame
    if not frame then
        local ok, created = pcall(CreateFrame, "Frame", "HarfordQuestLogFrame", UIParent, "ButtonFrameTemplate")
        frame = ok and created or CreateFrame("Frame", "HarfordQuestLogFrame", UIParent, "BasicFrameTemplateWithInset")
    end
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then pcall(frame.SetResizeBounds, frame, FRAME_W, 300, FRAME_W, 700) end
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    if not frame._harfordQuestSoundHooks then
        frame:HookScript("OnShow", function() PlayQuestSound("quest_log_opened") end)
        frame:HookScript("OnHide", function() PlayQuestSound("quest_log_closed") end)
        frame._harfordQuestSoundHooks = true
    end

    if frame.SetTitle then
        frame:SetTitle("Registro de misiones")
    elseif frame.TitleContainer and frame.TitleContainer.TitleText then
        frame.TitleContainer.TitleText:SetText("Registro de misiones")
    elseif frame.TitleText then
        frame.TitleText:SetText("Registro de misiones")
    end
    if not frame.CloseButton then
        local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
    end

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetFrameLevel(frame:GetFrameLevel() + 20)
    resizeGrip:SetSize(20, 20)
    resizeGrip:SetPoint("BOTTOMRIGHT")
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up.blp")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight.blp", "ADD")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down.blp")
    resizeGrip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    resizeGrip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    frame.resizeGrip = resizeGrip

    if not frame.BookPortrait then
        local portrait = frame:CreateTexture(nil, "OVERLAY", nil, -1)
        portrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
        portrait:SetSize(64, 64)
        portrait:SetPoint("TOPLEFT", -9, 9)
        frame.BookPortrait = portrait
    end
    -- Franja de controles superior: mismos puntos base del addon de referencia.
    frame.allButton = CreateAllTab(frame)
    frame.allButton:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame.allButton:SetScript("OnClick", function()
        local quests = (HarfordQuests and HarfordQuests.GetAccepted and HarfordQuests.GetAccepted()) or {}
        local items = BuildListItems(quests)
        local collapse = HasExpandedCategories(items)
        for _, item in ipairs(items) do
            if item.kind == "header" then
                collapsedCategories[item.key] = collapse
            end
        end
        API.Refresh()
    end)
    frame.countFrame = CreateCountFrame(frame)
    frame.countFrame:SetFrameLevel(frame:GetFrameLevel() + 20)

    local listScroll = frame.ListScroll
    if not listScroll then
        listScroll = CreateClassicScrollFrame("HarfordQuestLogListScroll", frame)
        listScroll:SetSize(305, FRAME_H - 93)
        listScroll:SetPoint("TOPLEFT", 6, -64)
    else
        listScroll:EnableMouseWheel(true)
        listScroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            self:SetVerticalScroll(math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 36)))
        end)
    end
    if not listScroll.background then
        local background = listScroll:CreateTexture(nil, "BACKGROUND", nil, -8)
        background:SetTexture("Interface\\QuestFrame\\QuestMapLogAtlas")
        background:SetPoint("TOPLEFT", 0, 1)
        background:SetPoint("BOTTOMRIGHT", -2, -2)
        listScroll.background = background
    end
    AddListScrollChrome(listScroll)
    frame.allButton:SetPoint("BOTTOMLEFT", listScroll, "TOPLEFT", 48, 0)
    local listContent = listScroll.Content
    if not listContent then
        listContent = CreateFrame("Frame", nil, listScroll)
        listContent:SetWidth(MIN_CONTENT_W)
        listContent:SetHeight(1)
        listScroll:SetScrollChild(listContent)
    end
    listContent:SetFrameLevel(listScroll:GetFrameLevel() + 10)
    listButtons = {}
    frame.listScroll = listScroll
    frame.listContent = listContent

    local detailScroll = frame.DetailScroll
    if not detailScroll then
        local ok, created = pcall(CreateFrame, "ScrollFrame", "HarfordQuestLogDetailScroll", frame, "QuestScrollFrameTemplate")
        detailScroll = ok and created or CreateClassicScrollFrame("HarfordQuestLogDetailScroll", frame)
        detailScroll:SetSize(300, FRAME_H - 93)
        detailScroll:SetPoint("TOPLEFT", frame, "TOP", 2, -64)
    else
        detailScroll:EnableMouseWheel(true)
        detailScroll:SetScript("OnMouseWheel", function(self, delta)
            local range = self:GetVerticalScrollRange() or 0
            self:SetVerticalScroll(math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 36)))
        end)
    end
    if not detailScroll.HarfordParchment then
        local parchment = detailScroll:CreateTexture(nil, "BACKGROUND", nil, -8)
        parchment:SetTexture("Interface\\QuestFrame\\QuestBG")
        parchment:SetTexCoord(0, 0.5859375, 0, 0.65625)
        parchment:SetPoint("TOPLEFT", -2, 1)
        parchment:SetPoint("BOTTOMRIGHT", 1, -1)
        detailScroll.HarfordParchment = parchment
    end
    local detailContent = detailScroll.Content
    if not detailContent then
        detailContent = CreateFrame("Frame", nil, detailScroll)
        detailContent:SetWidth(MIN_CONTENT_W)
        detailContent:SetHeight(1)
        detailScroll:SetScrollChild(detailContent)
    end
    detailContent:SetFrameLevel(detailScroll:GetFrameLevel() + 10)
    frame.detailScroll = detailScroll

    local d = CreateDetailControls(detailContent)
    local footer = {}
    footer.abandon = CreateFooterButton(frame, 108)
    footer.abandon:SetFrameLevel(frame:GetFrameLevel() + 20)
    footer.abandon:SetPoint("BOTTOMLEFT", 4, 4)
    footer.abandon:SetText("Abandonar")
    footer.abandon:SetScript("OnClick", function()
        if selectedId and HarfordQuests and HarfordQuests.Abandon then
            HarfordQuests.Abandon(selectedId)
            selectedId = nil
            API.Refresh()
        end
    end)

    footer.share = CreateFooterButton(frame, 108)
    footer.share:SetFrameLevel(frame:GetFrameLevel() + 20)
    footer.share:SetPoint("LEFT", footer.abandon, "RIGHT", 0, 0)
    footer.share:SetText("Compartir")
    footer.share:SetScript("OnClick", function()
        if not selectedId then return end
        local api = _G.HarfordQuestAPI
        if api and api.ShareQuest and api.ShareQuest(selectedId) then
            print("|cff33ff99Mision compartida al grupo.|r")
        else
            print("|cffff5555No se pudo compartir (¿estas en grupo/raid?).|r")
        end
    end)
    footer.share:Disable()

    footer.track = CreateFooterButton(frame, 108)
    footer.track:SetFrameLevel(frame:GetFrameLevel() + 20)
    footer.track:SetPoint("LEFT", footer.share, "RIGHT", 0, 0)
    footer.track:SetText("Rastrear")
    footer.track:SetScript("OnClick", function()
        if selectedId and HarfordQuests and HarfordQuests.ToggleTracked then
            HarfordQuests.ToggleTracked(selectedId)
            API.Refresh()
        end
    end)
    footer.close = CreateFooterButton(frame, 108)
    footer.close:SetFrameLevel(frame:GetFrameLevel() + 20)
    footer.close:SetPoint("BOTTOMRIGHT", -6, 4)
    footer.close:SetText("Cerrar")
    footer.close:SetScript("OnClick", function() frame:Hide() end)
    footer.options = CreateFooterButton(frame, 110)
    footer.options:SetFrameLevel(frame:GetFrameLevel() + 20)
    footer.options:SetPoint("RIGHT", footer.close, "LEFT", 0, 0)
    footer.options:SetText("Opciones")
    -- Solo DM (admin + .ph dm): configura la mision en el phase (cambiar estado, reparto, etc).
    -- La visibilidad se controla en Refresh; aqui solo se cablea el menu de acciones.
    footer.options:SetScript("OnClick", function(self)
        if not selectedId then return end
        if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then return end
        local id = selectedId
        local menu = {
            { text = "Opciones de mision (DM)", isTitle = true, notCheckable = true },
        }
        -- Modificar la mision en el editor del tablon (si es un contrato).
        if HarfordContracts and HarfordContracts.Data and HarfordContracts.Data.GetContractById
            and HarfordContracts.Data.GetContractById(id) and HarfordContracts.DM and HarfordContracts.DM.OpenForContract then
            menu[#menu + 1] = { text = "Modificar (editor DM)", notCheckable = true, func = function()
                HarfordContracts.DM.OpenForContract(id)
            end }
        end
        menu[#menu + 1] = { text = "Marcar completada (grupo)", notCheckable = true, func = function()
            if HarfordQuests and HarfordQuests.CompleteForGroup then HarfordQuests.CompleteForGroup(id) end
            API.Refresh()
        end }
        menu[#menu + 1] = { text = "Reiniciar entrega", notCheckable = true, func = function()
            if HarfordQuests and HarfordQuests.ResetClaim then HarfordQuests.ResetClaim(id) end
            API.Refresh()
        end }
        menu[#menu + 1] = { text = "Repartir recompensa a ausentes", notCheckable = true, func = function()
            local api = _G.HarfordQuestAPI
            if api and api.DmSendReward then api.DmSendReward(id) end
        end }
        -- Submenu de OBJETIVOS: el DM fija el progreso de cada objetivo PARA EL GRUPO (broadcast
        -- SetObjectiveProgress a la raid; cada cliente con la mision aceptada se actualiza).
        local objectives = (HarfordQuests and HarfordQuests.GetObjectives and HarfordQuests.GetObjectives(id)) or {}
        if #objectives > 0 then
            local objMenu = { { text = "Objetivos (grupo)", isTitle = true, notCheckable = true } }
            for i, o in ipairs(objectives) do
                local cur, req = o.current or 0, o.required or 1
                local done = o.done == true
                local sub = {}
                -- "+1" solo tiene sentido en objetivos con contador (required>1); en booleanos sobra.
                if req > 1 and not done then
                    sub[#sub + 1] = { text = "+1", notCheckable = true, func = function()
                        HarfordQuests.SetObjectiveProgressForGroup(id, i, cur + 1); API.Refresh()
                    end }
                end
                if done then
                    sub[#sub + 1] = { text = "Completado", disabled = true, notCheckable = true }
                else
                    sub[#sub + 1] = { text = "Completar", notCheckable = true, func = function()
                        HarfordQuests.CompleteObjectiveForGroup(id, i); API.Refresh()
                    end }
                end
                sub[#sub + 1] = { text = "Reiniciar (0)", notCheckable = true, func = function()
                    HarfordQuests.SetObjectiveProgressForGroup(id, i, 0); API.Refresh()
                end }
                objMenu[#objMenu + 1] = {
                    text = string.format("%d/%d %s%s", cur, req, tostring(o.text or ""), done and " (Completado)" or ""),
                    notCheckable = true, hasArrow = true, menuList = sub,
                }
            end
            menu[#menu + 1] = { text = "Objetivos (DM)", notCheckable = true, hasArrow = true, menuList = objMenu }
        end
        if not optionsDropdown then
            optionsDropdown = CreateFrame("Frame", "HarfordQuestLogOptionsDropdown", UIParent, "UIDropDownMenuTemplate")
        end
        if EasyMenu then EasyMenu(menu, optionsDropdown, self, 0, 0, "MENU") end
    end)
    footer.options:Hide()

    d.abandon = footer.abandon
    d.track = footer.track
    d.share = footer.share
    d.close = footer.close
    frame.footer = footer
    frame.detail = d
    frame:HookScript("OnSizeChanged", function(self)
        local h = math.max(200, (self:GetHeight() or FRAME_H) - 93)
        self.listScroll:SetHeight(h)
        self.detailScroll:SetHeight(h)
        if self:IsShown() then API.Refresh() end
    end)
    -- Re-pintar cuando un item de recompensa resuelva su nombre/icono (carga asincrona) o cambie
    -- el grupo (habilita/deshabilita el boton Compartir).
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:HookScript("OnEvent", function(self, event)
        if (event == "GET_ITEM_INFO_RECEIVED" or event == "GROUP_ROSTER_UPDATE") and self:IsShown() then
            API.Refresh()
        end
    end)
    return frame
end

-- Fila de valor dinero/rep/xp del pool del registro: etiqueta FRIZQT + valor ARIALN blanco,
-- igual que el panel del ArcSpell (HarfordWorldQuests.GetRewLine).
local function GetRewLine(d, i)
    local ln = d.rewLines[i]
    if ln then return ln end
    ln = {}
    ln.label = d.content:CreateFontString(nil, "OVERLAY")
    ln.label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    ln.label:SetTextColor(0, 0, 0)
    ln.label:SetJustifyH("LEFT")
    ln.value = d.content:CreateFontString(nil, "OVERLAY")
    ln.value:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
    ln.value:SetTextColor(1, 1, 1)
    ln.value:SetJustifyH("LEFT")
    d.rewLines[i] = ln
    return ln
end

-- Boton de item de recompensa del pool (QuestItemTemplate: icono+marco+nombre+cantidad+tooltip).
local function GetRewardButton(d, i)
    local b = d.rewardButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, d.content, "QuestItemTemplate")
    b:SetScript("OnEnter", function(self)
        if self.itemId then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemId)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    d.rewardButtons[i] = b
    return b
end

local function LayoutDetail(d, quest)
    local y = d.padTop
    local function Place(fs, text, gap)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", d.content, "TOPLEFT", d.padX, -y)
        fs:SetText(text or "")
        fs:Show()
        y = y + math.max(fs:GetStringHeight() or 0, 14) + (gap or 0)
    end

    -- Marca "(Completada)" tras el titulo cuando la mision esta completada (aun sin entregar).
    Place(d.title, (quest.title or "") .. (quest.completed and " (Completada)" or ""), 8)
    Place(d.objectives, quest.objective ~= "" and quest.objective or "", 14)
    Place(d.descHeader, "Descripcion", 6)
    Place(d.description, quest.description ~= "" and quest.description or "-", 14)

    -- Recompensa estructurada IGUAL que el panel del ArcSpell: dinero/rep/xp como filas
    -- (etiqueta + valor blanco con monedas grandes) y los items en botones nativos. Se usan
    -- los helpers de presentacion de HarfordWorldQuests (fuente unica). Fallback: texto plano.
    for _, b in ipairs(d.rewardButtons) do b:Hide() end
    for _, ln in ipairs(d.rewLines) do ln.label:Hide(); ln.value:Hide() end
    d.reward:Hide()

    local api = _G.HarfordQuestAPI
    local rewards = quest.rewards
    local valueLines = (api and api.GetRewardValueLines and rewards and api.GetRewardValueLines(rewards)) or {}
    local items = (rewards and rewards.items) or {}
    local hasStructured = (#valueLines > 0) or (#items > 0)
    local hasText = (not hasStructured) and quest.reward and quest.reward ~= ""

    d.rewardHeader:SetShown(hasStructured or hasText)
    if hasStructured then
        Place(d.rewardHeader, "Recompensa", 8)
        for i, data in ipairs(valueLines) do
            local ln = GetRewLine(d, i)
            ln.label:SetText(data.label)
            ln.label:ClearAllPoints()
            ln.label:SetPoint("TOPLEFT", d.content, "TOPLEFT", d.padX, -y)
            ln.label:Show()
            ln.value:SetText(data.value)
            ln.value:ClearAllPoints()
            ln.value:SetPoint("LEFT", ln.label, "RIGHT", 4, 0)
            ln.value:Show()
            y = y + math.max(ln.label:GetStringHeight() or 0, 16) + 5
        end
        for i, it in ipairs(items) do
            local b = GetRewardButton(d, i)
            local name, icon = api.ResolveRewardItem(it)
            if b.Icon then b.Icon:SetTexture(icon) end
            if b.Name then b.Name:SetText(name) end
            if SetItemButtonCount then SetItemButtonCount(b, it.count or 1) end
            b.itemId = it.id
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", d.content, "TOPLEFT", d.padX, -(y + 4))
            b:Show()
            y = y + (b:GetHeight() or 34) + 10
        end
    elseif hasText then
        Place(d.rewardHeader, "Recompensa", 6)
        Place(d.reward, quest.reward, 8)
    end

    d.content:SetHeight(math.max(y + d.padBottom, 1))
end

function API.Refresh()
    if not frame or not frame:IsShown() then return end
    local quests = (HarfordQuests and HarfordQuests.GetAccepted and HarfordQuests.GetAccepted()) or {}
    local selected
    for _, quest in ipairs(quests) do
        if quest.id == selectedId then selected = quest break end
    end
    if not selected and quests[1] then
        selected = quests[1]
        selectedId = selected.id
    end

    local items = BuildListItems(quests)
    UpdateListBackground(frame.listScroll, #items > 0)
    local listWidth = math.max(MIN_CONTENT_W, GetContentWidth(frame.listScroll) - 6)
    frame.listContent:SetWidth(listWidth)
    for i = #listButtons + 1, #items do
        local row = CreateListRow(frame.listContent)
        row:SetPoint("TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        listButtons[i] = row
    end
    for i = 1, #listButtons do
        local row = listButtons[i]
        local item = items[i]
        row:SetWidth(listWidth)
        if item then
            SetListRowItem(row, item)
            row:Show()
        else
            row.questId = nil
            row.item = nil
            row:Hide()
        end
    end
    local listHeight = math.max(#items * ROW_HEIGHT, frame.listScroll:GetHeight() or 1)
    frame.listContent:SetHeight(listHeight)
    if HybridScrollFrame_Update and frame.listScroll.scrollBar then
        HybridScrollFrame_Update(frame.listScroll, #items * ROW_HEIGHT, ROW_HEIGHT)
    end
    UpdateTopControls(#quests)

    local d = frame.detail
    local detailWidth = math.max(MIN_CONTENT_W, GetContentWidth(frame.detailScroll) - (d.padX * 2))
    d.content:SetWidth(detailWidth)
    for _, fs in ipairs({ d.empty, d.title, d.objectives, d.descHeader, d.description, d.rewardHeader, d.reward }) do
        fs:SetWidth(detailWidth)
    end
    if selected then
        d.empty:Hide()
        LayoutDetail(d, selected)
        d.track:SetText(selected.tracked and "No rastrear" or "Rastrear")
        d.track:Enable()
        d.abandon:Enable()
        -- Compartir: solo tiene sentido con grupo/raid (hay a quien enviar la mision).
        local inGroup = (IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid())
        d.share:SetEnabled(inGroup and true or false)
        -- Opciones (DM): solo visible con admin + .ph dm; configura la mision en el phase.
        local canDM = HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()
        frame.footer.options:SetShown(canDM and true or false)
    else
        for _, fs in ipairs({ d.title, d.objectives, d.descHeader, d.description, d.rewardHeader, d.reward }) do
            fs:Hide()
        end
        for _, b in ipairs(d.rewardButtons) do b:Hide() end
        for _, ln in ipairs(d.rewLines) do ln.label:Hide(); ln.value:Hide() end
        d.content:SetHeight(1)
        d.empty:Show()
        d.track:Disable()
        d.abandon:Disable()
        d.share:Disable()
        frame.footer.options:Hide()  -- sin mision seleccionada no hay que configurar
    end
    frame.detailScroll:SetVerticalScroll(0)
end

function API.Show()
    BuildFrame()
    frame:Show()
    API.Refresh()
end

function API.Hide()
    if frame then frame:Hide() end
end

function API.Toggle()
    local questFrame = BuildFrame()
    if questFrame:IsShown() then
        questFrame:Hide()
        return false
    end

    questFrame:Show()
    API.Refresh()
    return true
end

function API.OpenTo(id)
    BuildFrame()
    if id then selectedId = tostring(id) end
    frame:Show()
    API.Refresh()
end

if HarfordQuests and HarfordQuests.RegisterChangeListener then
    HarfordQuests.RegisterChangeListener(function()
        if frame and frame:IsShown() then API.Refresh() end
    end)
end

-- Al entrar/salir de modo DM, re-evaluar la visibilidad del boton "Opciones" si el registro esta abierto.
if HarfordAuthority and HarfordAuthority.RegisterChangeListener then
    HarfordAuthority.RegisterChangeListener("HarfordQuestLog", function()
        if frame and frame:IsShown() then API.Refresh() end
    end)
end

-- Feedback de completado (como el nativo): al cerrarse una mision (objetivos hechos, cierre DM o
-- completado compartido) suena el jingle de quest y avisa en chat con el titulo.
if HarfordQuests and HarfordQuests.RegisterCompletionListener then
    HarfordQuests.RegisterCompletionListener(function(id)
        local title
        for _, q in ipairs((HarfordQuests.GetAccepted and HarfordQuests.GetAccepted()) or {}) do
            if q.id == id then title = q.title; break end
        end
        print("|cff33ff99Mision completada" .. (title and (": " .. title) or "") .. ".|r")
    end)
end

-- ─── Oferta de mision compartida (como el nativo: suena + cuadro con Aceptar/Rechazar) ──────────
local shareOffer

local function ShareObjectivesText(info)
    if type(info.objectives) == "table" and #info.objectives > 0 then
        local out = {}
        for _, o in ipairs(info.objectives) do
            local prog = (o.required and o.required > 1) and (" (0/" .. o.required .. ")") or ""
            -- Algunas definiciones de ArcSpell ya escriben el objetivo como "- Texto".
            -- El render de la oferta aporta su propio marcador, asi que evitamos duplicarlo.
            local text = tostring(o.text or ""):gsub("^%s*[%-%*%•]%s*", "")
            out[#out + 1] = "- " .. text .. prog
        end
        return table.concat(out, "\n")
    end
    return tostring(info.objective or "")
end

local function ShareRewardSummary(rewards)
    if type(rewards) ~= "table" then return "" end
    local parts = {}
    if rewards.money then
        local c = (rewards.money.gold or 0) * 10000 + (rewards.money.silver or 0) * 100 + (rewards.money.copper or 0)
        if c > 0 and GetCoinTextureString then parts[#parts + 1] = GetCoinTextureString(c) end
    end
    for _, rr in ipairs(rewards.reps or (rewards.rep and { rewards.rep }) or {}) do
        local amt = tonumber(rr.amount)
        if amt then parts[#parts + 1] = (amt < 0 and "|cffff3333" or "|cff33ff33") .. amt .. "|r rep " .. tostring(rr.faction or rr.factionId or "") end
    end
    if tonumber(rewards.xp) then parts[#parts + 1] = "|cff66ccff+" .. tostring(rewards.xp) .. " XP|r" end
    for _, it in ipairs(rewards.items or {}) do
        local itemText = HarfordQuests and HarfordQuests.FormatRewardItemForText
            and HarfordQuests.FormatRewardItemForText(it)
            or ("[objeto " .. tostring(it.id or "?") .. "]")
        parts[#parts + 1] = itemText .. (it.count and it.count > 1 and (" x" .. it.count) or "")
    end
    return table.concat(parts, "   ")
end

local function GetShareSenderUnit(sender)
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(sender)
    end
    return nil
end

local function RefreshSharePortrait(offer, sender)
    if not offer or not offer.portrait then return end

    local unit = GetShareSenderUnit(sender)
    local useTRP3 = not HarfordConfig or HarfordConfig.Get("portrait_target_player") ~= "wow"
    local icon
    if useTRP3 and unit and HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetProfileIcon then
        local profile = HarfordTRP3.GetPlayerProfile(unit)
        icon = profile and HarfordTRP3.GetProfileIcon(profile)
    end

    if icon then
        offer.portrait:SetTexture(icon)
        offer.portrait:SetTexCoord(0, 1, 0, 1)
    elseif unit and SetPortraitTexture then
        SetPortraitTexture(offer.portrait, unit)
        offer.portrait:SetTexCoord(0, 1, 0, 1)
    else
        offer.portrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
        offer.portrait:SetTexCoord(0, 1, 0, 1)
    end
end

-- Muestra la oferta de una mision compartida con ESTILO QUEST NATIVO (pergamino + QuestTitleFont/
-- QuestFont + Aceptar/Rechazar), como el DummyQuestFrame de referencia. `info` = tabla para Accept.
function API.ShowShareOffer(sender, id, info, refreshOnly)
    if type(info) ~= "table" or not id then return end
    if HarfordQuests and HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(id) then return end

    if not shareOffer then
        -- La oferta usa el mismo cromo de Gossip/Quest que el resto de paneles Harford. No es
        -- un Dialog independiente: ButtonFrame aporta cabecera, borde, titulo y cierre nativos.
        -- Preferimos el template real de GossipFrame: aporta el marco, retrato, cabecera y
        -- envoltorio nativos. En clientes donde no exista, ButtonFrame mantiene el fallback.
        local ok, f = pcall(CreateFrame, "Frame", "HarfordQuestShareOffer", UIParent, "GossipFrameTemplate")
        if not ok or not f then
            f = CreateFrame("Frame", "HarfordQuestShareOffer", UIParent, "ButtonFrameTemplate")
        end
        -- Medidas y anclajes capturados del GossipFrame nativo de Shadowlands.
        f:SetSize(338, 496)
        f:SetPoint("CENTER", 0, 80)
        f:SetFrameStrata("DIALOG"); f:SetFrameLevel(100)
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
        if ButtonFrameTemplate_HideButtonBar then
            ButtonFrameTemplate_HideButtonBar(f)
        end
        -- El InsetFrameTemplate es el envoltorio nativo del pergamino. Ocultarlo dejaba el
        -- contenido sin cuerpo ni borde, aunque la cabecera del ButtonFrame siguiera visible.
        if f.Inset then
            f.Inset:ClearAllPoints()
            f.Inset:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -60)
            f.Inset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 26)
            f.Inset:Show()
        end
        if f.Bg then f.Bg:Show() end
        if f.SetTitle then f:SetTitle("Mision compartida") end

        -- El detalle usa el scroll nativo de quest. El pergamino vive EN el ScrollChild, asi
        -- que el borde, el clip y la barra siguen siendo una sola composicion de Gossip.
        local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, f, "GossipGreetingScrollFrameTemplate")
        if not ok or not scroll then
            ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, f, "QuestScrollFrameTemplate")
        end
        if not ok or not scroll then
            scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        end
        scroll:ClearAllPoints()
        scroll:SetSize(300, 403)
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -65)
        scroll:SetFrameLevel(f:GetFrameLevel() + 6)
        scroll:EnableMouseWheel(true)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll() or 0
            local child = self:GetScrollChild()
            local childHeight = child and child:GetHeight() or 0
            local maxScroll = math.max(0, childHeight - (self:GetHeight() or 0))
            self:SetVerticalScroll(math.max(0, math.min(current - delta * 32, maxScroll)))
        end)
        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(276)
        content:SetHeight(1)
        scroll:SetScrollChild(content)
        f.detailScroll = scroll
        f.content = content

        -- El pergamino cubre siempre el visor. Solo el texto y las recompensas se desplazan;
        -- si vive en el ScrollChild deja un hueco negro al final de una mision corta.
        local parch = scroll:CreateTexture(nil, "BACKGROUND", nil, -1)
        parch:SetTexture("Interface\\QuestFrame\\QuestBG")
        parch:SetTexCoord(0, 0.5859375, 0, 0.65625)
        parch:SetAllPoints(scroll)
        f.parch = parch

        local close = f.CloseButton or CreateFrame("Button", nil, f, "UIPanelCloseButton")
        if not f.CloseButton then close:SetPoint("TOPRIGHT", -4, -4) end
        close:SetScript("OnClick", function() f:Hide() end)

        -- Retrato circular del jugador que comparte: icono TRP3 o retrato nativo segun ajuste.
        local portrait = f.Portrait
        if not portrait then
            local portraitBg = f:CreateTexture(nil, "OVERLAY", nil, 3)
            portraitBg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            portraitBg:SetVertexColor(0.72, 0.56, 0.16, 1)
            portraitBg:SetSize(62, 62); portraitBg:SetPoint("TOPLEFT", -9, 8)
            portrait = f:CreateTexture(nil, "OVERLAY", nil, 4)
            portrait:SetSize(56, 56); portrait:SetPoint("CENTER", portraitBg)
            if f.CreateMaskTexture and portrait.AddMaskTexture then
                local mask = f:CreateMaskTexture(nil, "OVERLAY")
                mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(portrait)
                portrait:AddMaskTexture(mask)
                f.portraitMask = mask
            end
        end
        f.portrait = portrait

        f.from = content:CreateFontString(nil, "OVERLAY", "QuestFontNormalSmall")
        f.from:SetWidth(260); f.from:SetJustifyH("LEFT")
        f.qtitle = content:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
        f.qtitle:SetWidth(260); f.qtitle:SetJustifyH("LEFT")
        f.desc = content:CreateFontString(nil, "OVERLAY", "QuestFont")
        f.desc:SetWidth(260)
        f.desc:SetJustifyH("LEFT"); f.desc:SetJustifyV("TOP")
        f.objTitle = content:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
        f.objTitle:SetWidth(260); f.objTitle:SetText("Objetivos")
        f.obj = content:CreateFontString(nil, "OVERLAY", "QuestFont")
        f.obj:SetWidth(260)
        f.obj:SetJustifyH("LEFT"); f.obj:SetJustifyV("TOP")
        f.rewTitle = content:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
        f.rewTitle:SetWidth(260); f.rewTitle:SetText("Recompensa")
        f.rew = content:CreateFontString(nil, "OVERLAY", "QuestFont")
        f.rew:SetWidth(260)
        f.rew:SetJustifyH("LEFT"); f.rew:SetJustifyV("TOP")
        -- La oferta reutiliza exactamente el pool visual del registro: lineas de valores y
        -- QuestItemTemplate para items, en lugar de comprimir toda la recompensa en una frase.
        f.rewLines = {}
        f.rewardButtons = {}

        f.accept = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.accept:SetSize(110, 24); f.accept:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 4); f.accept:SetText("Aceptar")
        f.accept:SetScript("OnClick", function()
            if f.qid and f.qinfo and HarfordQuests and HarfordQuests.Accept then
                HarfordQuests.Accept(f.qid, f.qinfo)
                if HarfordQuests.SetTracked then HarfordQuests.SetTracked(f.qid, true, true) end
            end
            f:Hide()
        end)
        f.decline = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.decline:SetSize(110, 24); f.decline:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 4); f.decline:SetText("Rechazar")
        f.decline:SetScript("OnClick", function() f:Hide() end)
        shareOffer = f
    end

    shareOffer.qid = id
    shareOffer.qinfo = info
    shareOffer.sender = sender
    local shortSender = sender and (Ambiguate and Ambiguate(sender, "short") or sender) or "Alguien"
    local senderUnit = GetShareSenderUnit(sender)
    local senderName = senderUnit and HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName(senderUnit)
    senderName = senderName or shortSender
    if shareOffer.SetTitle then shareOffer:SetTitle(senderName) end
    RefreshSharePortrait(shareOffer, sender)
    -- El remitente ya ocupa la cabecera del GossipFrame; no repetirlo en el cuerpo.
    shareOffer.from:Hide()
    local objText = ShareObjectivesText(info)
    local rewText = ShareRewardSummary(info.rewards)
    if (not rewText or rewText == "") and info.reward and info.reward ~= "" then rewText = info.reward end
    for _, button in ipairs(shareOffer.rewardButtons) do button:Hide() end
    for _, line in ipairs(shareOffer.rewLines) do line.label:Hide(); line.value:Hide() end

    local rewardApi = _G.HarfordQuestAPI
    local rewards = info.rewards
    local valueLines = (rewardApi and rewardApi.GetRewardValueLines and rewards and rewardApi.GetRewardValueLines(rewards)) or {}
    local items = (rewards and rewards.items) or {}
    local structured = #valueLines > 0 or #items > 0
    local y = 14
    local content = shareOffer.content
    local function Place(fs, text, gap)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
        -- QuestTitleFont viene centrada en algunos clientes aunque el FontString tenga ancho.
        -- La oferta de mision usa los encabezados alineados al margen izquierdo del pergamino.
        fs:SetJustifyH("LEFT")
        fs:SetText(text or "")
        fs:Show()
        y = y + math.max(fs:GetStringHeight() or 0, 14) + (gap or 0)
    end

    -- Margen superior deliberado: el contenido empieza bajo la cabecera como el detalle de gossip.
    Place(shareOffer.qtitle, info.title or "Mision", 10)
    Place(shareOffer.desc, (info.description and info.description ~= "" and info.description) or "-", 14)
    if objText ~= "" then
        Place(shareOffer.objTitle, "Objetivos", 5)
        Place(shareOffer.obj, objText, 14)
    else
        shareOffer.objTitle:Hide(); shareOffer.obj:Hide()
    end
    if structured or (rewText and rewText ~= "") then
        Place(shareOffer.rewTitle, "Recompensa", 6)
    else
        shareOffer.rewTitle:Hide()
    end
    shareOffer.rew:Hide()

    if structured then
        for i, data in ipairs(valueLines) do
            local line = GetRewLine(shareOffer, i)
            line.label:SetText(data.label)
            line.label:ClearAllPoints()
            line.label:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
            line.label:Show()
            line.value:SetText(data.value)
            line.value:ClearAllPoints()
            line.value:SetPoint("LEFT", line.label, "RIGHT", 4, 0)
            line.value:Show()
            y = y + math.max(line.label:GetStringHeight() or 0, 16) + 5
        end
        for i, item in ipairs(items) do
            local button = GetRewardButton(shareOffer, i)
            local name, icon
            if rewardApi and rewardApi.ResolveRewardItem then
                name, icon = rewardApi.ResolveRewardItem(item)
            else
                name, icon = "[objeto " .. tostring(item.id or "?") .. "]", "Interface\\Icons\\INV_Misc_QuestionMark"
            end
            if button.Icon then button.Icon:SetTexture(icon) end
            if button.Name then button.Name:SetText(name) end
            if SetItemButtonCount then SetItemButtonCount(button, item.count or 1) end
            button.itemId = item.id
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -y)
            button:Show()
            y = y + (button:GetHeight() or 36) + 6
        end
    elseif rewText and rewText ~= "" then
        Place(shareOffer.rew, rewText, 8)
    end

    content:SetHeight(math.max(y + 14, shareOffer.detailScroll:GetHeight() or 1))
    shareOffer.detailScroll:SetVerticalScroll(0)

    -- Aviso en chat en el DESTINO: "X esta compartiendo [Mision]" (enlace clicable si TRP3 esta).
    local link
    if HarfordTRP3 and HarfordTRP3.GetQuestChatLink then
        link = HarfordTRP3.GetQuestChatLink({ title = info.title, objective = objText, reward = rewText })
    end
    if not link or link == "" then
        local c = GetDifficultyColor(info.difficulty)
        link = string.format("|cff%02x%02x%02x[%s]|r", (c[1] or 1) * 255, (c[2] or 1) * 255, (c[3] or 1) * 255, tostring(info.title or "Mision"))
    end
    if not refreshOnly then
        HarfordChat.Print(shortSender .. " esta compartiendo " .. link)
        if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.UI_QUEST_ROLLING_FORWARD_01 or 6199) end
    end
    shareOffer:Show()
    shareOffer:Raise()
end

-- La primera consulta de un item puede devolver solo su ID. Al terminar la carga del cliente,
-- se vuelve a pintar la oferta ya abierta para sustituir el fallback por nombre y enlace reales.
function API.RefreshShareOffer()
    if not shareOffer or not shareOffer:IsShown() or not shareOffer.qid or not shareOffer.qinfo then return end
    API.ShowShareOffer(shareOffer.sender, shareOffer.qid, shareOffer.qinfo, true)
end

SlashCmdList["HARFORDQUESTLOG"] = function()
    API.Toggle()
end
