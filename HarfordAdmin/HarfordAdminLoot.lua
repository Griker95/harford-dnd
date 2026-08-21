HarfordAdminLoot = HarfordAdminLoot or {}

local API = HarfordAdminLoot

local LOOT_EDITOR_ROWS = 8
local LOOT_EDITOR_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Bag_10"

local lootEditor
local lootLinkHooked

local function Print(msg)
    HarfordChat.Print(msg)
end

local function CanEditLoot()
    if not (HarfordAdminAPI and HarfordAdminAPI.IS_ADMIN == true) then
        return false
    end
    if HarfordAuthority and HarfordAuthority.CanUseDMTools then
        return HarfordAuthority.CanUseDMTools() == true
    end
    return false
end

local function ExtractItemId(value)
    value = tostring(value or "")
    local linkedId = value:match("item:(%d+)")
    if linkedId then
        return tonumber(linkedId)
    end
    return tonumber(value:match("(%d+)"))
end

local function NormalizeLootEntry(itemId, chance, minAmount, maxAmount)
    itemId = ExtractItemId(itemId)
    chance = tonumber(chance)
    minAmount = tonumber(minAmount)
    maxAmount = tonumber(maxAmount)

    if not itemId or itemId <= 0 then
        return nil, "ItemID invalido"
    end

    chance = math.floor(chance or 100)
    minAmount = math.floor(minAmount or 1)
    maxAmount = math.floor(maxAmount or minAmount)

    if chance < 1 then chance = 1 end
    if chance > 100 then chance = 100 end
    if minAmount < 1 then minAmount = 1 end
    if maxAmount < minAmount then maxAmount = minAmount end

    return { math.floor(itemId), chance, minAmount, maxAmount }
end

local function SetBoxText(box, value)
    if box then
        box:SetText(tostring(value or ""))
        box:SetCursorPosition(0)
    end
end

local function SetItemBoxFromLink(box, link)
    local itemId = ExtractItemId(link)
    if itemId and box then
        SetBoxText(box, itemId)
        return true
    end
    return false
end

local function GetEditorScope(frame)
    if frame.globalCheck and frame.globalCheck:GetChecked() then
        return "GLOBAL"
    end

    local npcId = frame.creatureBox and strtrim(frame.creatureBox:GetText() or "")
    if npcId and npcId ~= "" then
        return npcId
    end

    return nil
end

local function ClearEditorSelection(frame)
    frame.selectedIndex = nil
    SetBoxText(frame.itemBox, "")
    SetBoxText(frame.chanceBox, "100")
    SetBoxText(frame.minBox, "1")
    SetBoxText(frame.maxBox, "1")
end

local function GetEntries(scope, create)
    if HarfordLootAPI and HarfordLootAPI.GetLootEntries then
        return HarfordLootAPI.GetLootEntries(scope, create)
    end
    return nil
end

local function EditorContainsItem(frame, itemID)
    itemID = tonumber(itemID)
    if not itemID or not frame then return false end

    local entries = GetEntries(GetEditorScope(frame))
    if type(entries) == "table" then
        for i = 1, #entries do
            local entry = entries[i]
            if entry and tonumber(entry[1]) == itemID then
                return true
            end
        end
    end

    local boxItemID = ExtractItemId(frame.itemBox and frame.itemBox:GetText())
    return boxItemID == itemID
end

local function AddOrUpdateLootEntry(scope, itemId, chance, minAmount, maxAmount, index)
    local entry, err = NormalizeLootEntry(itemId, chance, minAmount, maxAmount)
    if not entry then return false, err end

    local entries = GetEntries(scope, true)
    if not entries then return false, "Selecciona un NPC o loot global" end

    index = tonumber(index)
    if index and entries[index] then
        entries[index] = entry
    else
        entries[#entries + 1] = entry
    end

    if HarfordLootAPI and HarfordLootAPI.SaveConfig then
        HarfordLootAPI.SaveConfig()
    end
    return true
end

local function RemoveLootEntry(scope, index)
    local entries = GetEntries(scope)
    index = tonumber(index)
    if not entries or not index or not entries[index] then
        return false, "No hay entrada seleccionada"
    end

    table.remove(entries, index)
    if scope ~= "GLOBAL" and #entries == 0 then
        HarfordLootLootRegistry[scope] = nil
    end

    if HarfordLootAPI and HarfordLootAPI.SaveConfig then
        HarfordLootAPI.SaveConfig()
    end
    return true
end

local function ClearLocalLootHistory()
    if not HarfordLootAPI or not HarfordLootAPI.ClearAllResolvedLoot then
        return false, "HarfordLootAPI.ClearAllResolvedLoot no disponible"
    end

    return HarfordLootAPI.ClearAllResolvedLoot()
end

local function ClearGroupLootHistory()
    if not HarfordLootAPI or not HarfordLootAPI.ClearRemoteLoot then
        return false, "HarfordLootAPI.ClearRemoteLoot no disponible"
    end

    local channel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if channel ~= "RAID" and channel ~= "PARTY" then
        return false, "No hay grupo o raid para limpiar historico remoto."
    end

    return HarfordLootAPI.ClearRemoteLoot(channel, nil, false)
end

local function LoadEditorEntry(frame, index)
    local entries = GetEntries(GetEditorScope(frame))
    local entry = entries and entries[index]
    if not entry then return end

    frame.selectedIndex = index
    SetBoxText(frame.itemBox, entry[1])
    SetBoxText(frame.chanceBox, entry[2])
    SetBoxText(frame.minBox, entry[3])
    SetBoxText(frame.maxBox, entry[4])
end

local function GetTargetCreatureId()
    if HarfordLootAPI and HarfordLootAPI.GetTargetCreatureId then
        return HarfordLootAPI.GetTargetCreatureId()
    end
    return nil
end

local function GetLootEditorNpcPortraitMode()
    if HarfordConfig and HarfordConfig.Get then
        return HarfordConfig.Get("portrait_target_npc") or "trp3"
    end
    return "trp3"
end

local function SetLootEditorPortraitTexture(frame, texture, isIcon)
    local portrait = frame and frame.lootPortrait
    if not portrait then return false end

    if texture then
        texture = tonumber(texture) or texture
        portrait:SetTexture(texture)
        if isIcon then
            portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            portrait:SetTexCoord(0, 1, 0, 1)
        end
        return true
    end

    return false
end

local function ApplyLootEditorFallbackPortrait(frame)
    SetLootEditorPortraitTexture(frame, LOOT_EDITOR_FALLBACK_ICON, true)
end

local function UpdateLootEditorPortrait(frame)
    if not frame or not frame.lootPortrait then return end

    if UnitExists and UnitExists("target") and not UnitIsPlayer("target") and GetTargetCreatureId() then
        local mode = GetLootEditorNpcPortraitMode()
        if mode == "trp3" and HarfordTRP3 and HarfordTRP3.GetEpsilonNpcProfile and HarfordTRP3.GetProfileIcon then
            local profile = HarfordTRP3.GetEpsilonNpcProfile("target")
            local icon = profile and HarfordTRP3.GetProfileIcon(profile)
            if SetLootEditorPortraitTexture(frame, icon, true) then
                return
            end
        end

        if SetPortraitTexture then
            SetPortraitTexture(frame.lootPortrait, "target")
            frame.lootPortrait:SetTexCoord(0, 1, 0, 1)
            return
        end
    end

    ApplyLootEditorFallbackPortrait(frame)
end

function API.Refresh(frame)
    frame = frame or lootEditor
    if not frame then return end

    UpdateLootEditorPortrait(frame)

    local scope = GetEditorScope(frame)
    local entries = scope and GetEntries(scope) or nil
    local isGlobal = scope == "GLOBAL"

    frame.scopeText:SetText(isGlobal and "Loot global" or ("NPC ID: " .. tostring(scope or "sin seleccionar")))
    frame.saveButton:SetEnabled(CanEditLoot())
    frame.deleteButton:SetEnabled(CanEditLoot())
    frame.shareButton:SetEnabled(CanEditLoot())

    for i = 1, LOOT_EDITOR_ROWS do
        local row = frame.rows[i]
        local entry = entries and entries[i]
        if entry then
            local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(entry[1])
            local color = (itemQuality and ITEM_QUALITY_COLORS[itemQuality]) or NORMAL_FONT_COLOR
            row.index = i
            row.icon:SetTexture(itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(itemName or ("Item " .. tostring(entry[1])))
            row.name:SetTextColor(color.r or 1, color.g or 0.82, color.b or 0)
            row.detail:SetText("ID " .. tostring(entry[1]) .. "  " .. tostring(entry[2]) .. "%  x" .. tostring(entry[3]) .. "-" .. tostring(entry[4]))
            row.selected:SetShown(frame.selectedIndex == i)
            row:Show()
        else
            row.index = nil
            row:Hide()
        end
    end

    frame.emptyText:SetShown(not entries or #entries == 0)
end

function API.RefreshFromTarget(frame)
    frame = frame or lootEditor
    if not frame then return end

    local npcId = UnitExists and UnitExists("target") and not UnitIsPlayer("target") and GetTargetCreatureId()
    if npcId then
        if frame.globalCheck then
            frame.globalCheck:SetChecked(false)
        end
        if frame.creatureBox and frame.creatureBox:GetText() ~= tostring(npcId) then
            SetBoxText(frame.creatureBox, npcId)
            frame.selectedIndex = nil
        end
    end

    API.Refresh(frame)
end

local function CreateLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function CreateInput(parent, w, h, x, y, defaultText)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(w, h)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    box:SetAutoFocus(false)
    box:SetText(defaultText or "")
    box:SetCursorPosition(0)
    return box
end

local function InstallLootLinkHook()
    if lootLinkHooked then return end
    lootLinkHooked = true
    if hooksecurefunc and ChatEdit_InsertLink then
        hooksecurefunc("ChatEdit_InsertLink", function(link)
            if lootEditor and lootEditor:IsShown() and lootEditor.activeItemBox and lootEditor.activeItemBox:HasFocus() then
                SetItemBoxFromLink(lootEditor.activeItemBox, link)
            end
        end)
    end
end

local function CreateLootEditor()
    if lootEditor then return lootEditor end
    InstallLootLinkHook()

    local frame = CreateFrame("Frame", "HarfordLootEditorFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(560, 470)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    if frame.TitleText then
        frame.TitleText:SetText("Cargar loot Harford")
    else
        local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("TOP", frame, "TOP", 0, -6)
        title:SetText("Cargar loot Harford")
    end

    local portrait = frame.portrait or _G["HarfordLootEditorFramePortrait"]
    if portrait then
        frame.lootPortrait = portrait
        if portrait.AddMaskTexture and frame.CreateMaskTexture then
            local mask = frame:CreateMaskTexture(nil, "BACKGROUND")
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(portrait)
            portrait:AddMaskTexture(mask)
            frame.lootPortraitMask = mask
        end
        ApplyLootEditorFallbackPortrait(frame)
    end

    frame.scopeText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.scopeText:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -44)
    frame.scopeText:SetText("NPC ID:")

    CreateLabel(frame, "NPC ID", 64, -76)
    frame.creatureBox = CreateInput(frame, 116, 22, 112, -72, "")
    frame.creatureBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        frame.globalCheck:SetChecked(false)
        frame.selectedIndex = nil
        API.Refresh(frame)
    end)

    frame.globalCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.globalCheck:SetPoint("LEFT", frame.creatureBox, "RIGHT", 18, 0)
    frame.globalCheck.label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    frame.globalCheck.label:SetPoint("LEFT", frame.globalCheck, "RIGHT", 0, 1)
    frame.globalCheck.label:SetText("Loot global")
    frame.globalCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            frame.selectedIndex = nil
        end
        API.Refresh(frame)
    end)

    CreateLabel(frame, "ItemID", 64, -116)
    CreateLabel(frame, "Prob.", 232, -116)
    CreateLabel(frame, "Min", 310, -116)
    CreateLabel(frame, "Max", 375, -116)
    frame.itemBox = CreateInput(frame, 150, 22, 64, -132, "")
    frame.itemBox:SetScript("OnEditFocusGained", function(self)
        frame.activeItemBox = self
    end)
    frame.itemBox:SetScript("OnEditFocusLost", function(self)
        if frame.activeItemBox == self then frame.activeItemBox = nil end
    end)
    frame.chanceBox = CreateInput(frame, 55, 22, 232, -132, "100")
    frame.minBox = CreateInput(frame, 45, 22, 310, -132, "1")
    frame.maxBox = CreateInput(frame, 45, 22, 375, -132, "1")
    frame.itemBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput or self._normalizingLink then return end
        local text = self:GetText() or ""
        if not text:find("item:", 1, true) then return end
        local itemId = ExtractItemId(text)
        if itemId then
            self._normalizingLink = true
            self:SetText(tostring(itemId))
            self:SetCursorPosition(0)
            self._normalizingLink = nil
        end
    end)
    frame.itemBox:SetScript("OnReceiveDrag", function(self)
        local cursorType, itemId = GetCursorInfo()
        if cursorType == "item" and itemId then
            self:SetText(tostring(itemId))
            ClearCursor()
        end
    end)

    frame.saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.saveButton:SetSize(86, 24)
    frame.saveButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 432, -129)
    frame.saveButton:SetText("Guardar")
    frame.saveButton:SetScript("OnClick", function()
        if not CanEditLoot() then
            Print("Necesitas HarfordAdmin y .ph dm activo para editar loot.")
            return
        end
        local ok, err = AddOrUpdateLootEntry(
            GetEditorScope(frame),
            frame.itemBox:GetText(),
            frame.chanceBox:GetText(),
            frame.minBox:GetText(),
            frame.maxBox:GetText(),
            frame.selectedIndex
        )
        if not ok then
            Print(err or "No se pudo guardar.")
            return
        end
        ClearEditorSelection(frame)
        API.Refresh(frame)
    end)

    local newButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newButton:SetSize(86, 24)
    newButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 432, -158)
    newButton:SetText("Nuevo")
    newButton:SetScript("OnClick", function()
        ClearEditorSelection(frame)
        API.Refresh(frame)
    end)

    frame.rows = {}
    frame.emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    frame.emptyText:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -234)
    frame.emptyText:SetText("Sin entradas. Elige item y pulsa Guardar.")

    for i = 1, LOOT_EDITOR_ROWS do
        local row = CreateFrame("Button", nil, frame)
        row:SetSize(470, 28)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -198 - ((i - 1) * 29))
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.selected = row:CreateTexture(nil, "BACKGROUND")
        row.selected:SetAllPoints(row)
        row.selected:SetColorTexture(0.15, 0.35, 0.75, 0.35)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(24, 24)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 5)
        row.name:SetWidth(250)
        row.name:SetJustifyH("LEFT")
        row.detail = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.detail:SetPoint("LEFT", row.icon, "RIGHT", 8, -8)
        row.detail:SetWidth(380)
        row.detail:SetJustifyH("LEFT")
        row:SetScript("OnClick", function(self)
            if self.index then
                LoadEditorEntry(frame, self.index)
                API.Refresh(frame)
            end
        end)
        frame.rows[i] = row
    end

    frame.deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.deleteButton:SetSize(80, 24)
    frame.deleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 64, 22)
    frame.deleteButton:SetText("Borrar")
    frame.deleteButton:SetScript("OnClick", function()
        if not CanEditLoot() then
            Print("Necesitas HarfordAdmin y .ph dm activo para editar loot.")
            return
        end
        local ok, err = RemoveLootEntry(GetEditorScope(frame), frame.selectedIndex)
        if not ok then
            Print(err or "No se pudo borrar.")
            return
        end
        ClearEditorSelection(frame)
        API.Refresh(frame)
    end)

    frame.shareButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.shareButton:SetSize(118, 24)
    frame.shareButton:SetPoint("LEFT", frame.deleteButton, "RIGHT", 10, 0)
    frame.shareButton:SetText("Compartir")
    frame.shareButton:SetScript("OnClick", function()
        if not CanEditLoot() then
            Print("Necesitas HarfordAdmin y .ph dm activo para compartir loot.")
            return
        end
        if HarfordLootAPI and HarfordLootAPI.SaveConfig then
            HarfordLootAPI.SaveConfig()
        end
        local ok, err
        if HarfordLootAPI and HarfordLootAPI.BroadcastConfig then ok, err = HarfordLootAPI.BroadcastConfig() end
        if ok then
            Print("Configuracion de loot compartida.")
        else
            Print(err or "No hay canal para compartir.")
        end
    end)

    frame.clearLocalButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.clearLocalButton:SetSize(118, 24)
    frame.clearLocalButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 64, 50)
    frame.clearLocalButton:SetText("Limpiar local")
    frame.clearLocalButton:SetScript("OnClick", function()
        if not CanEditLoot() then
            Print("Necesitas HarfordAdmin y .ph dm activo para limpiar historico.")
            return
        end
        local ok, err = ClearLocalLootHistory()
        if ok then
            Print("Historico de loot local limpiado.")
        else
            Print(err or "No se pudo limpiar el historico local.")
        end
    end)

    frame.clearGroupButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.clearGroupButton:SetSize(132, 24)
    frame.clearGroupButton:SetPoint("LEFT", frame.clearLocalButton, "RIGHT", 10, 0)
    frame.clearGroupButton:SetText("Limpiar grupo")
    frame.clearGroupButton:SetScript("OnClick", function()
        if not CanEditLoot() then
            Print("Necesitas HarfordAdmin y .ph dm activo para limpiar historico.")
            return
        end
        local ok, err = ClearGroupLootHistory()
        if ok then
            ClearLocalLootHistory()
            Print("Historico de loot limpiado localmente y enviado a grupo/raid.")
        else
            Print(err or "No se pudo limpiar el historico remoto.")
        end
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 24)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 22)
    closeButton:SetText("Cerrar")
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    lootEditor = frame
    return frame
end

function API.OpenEditor()
    if not CanEditLoot() then
        Print("Cargar loot requiere HarfordAdmin y .ph dm activo.")
        return
    end

    local frame = CreateLootEditor()
    ClearEditorSelection(frame)
    API.RefreshFromTarget(frame)
    frame:Show()
end

function API.ToggleEditor()
    local frame = CreateLootEditor()
    if frame:IsShown() then
        frame:Hide()
    else
        API.OpenEditor()
    end
end

SlashCmdList["HARFORDLOOTEDITOR"] = function()
    API.ToggleEditor()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if not lootEditor or not lootEditor:IsShown() then return end
    if event == "PLAYER_TARGET_CHANGED" then
        API.RefreshFromTarget(lootEditor)
    else
        local itemID = ...
        if not EditorContainsItem(lootEditor, itemID) then return end
        API.Refresh(lootEditor)
    end
end)

if HarfordAuthority and HarfordAuthority.RegisterChangeListener then
    HarfordAuthority.RegisterChangeListener("HarfordAdminLoot", function()
        if lootEditor and lootEditor:IsShown() then
            API.Refresh(lootEditor)
        end
    end)
end
