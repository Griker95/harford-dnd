HarfordReputationAdmin = HarfordReputationAdmin or {}
local AdminAPI = HarfordReputationAdmin

-- ─── Constantes de layout ─────────────────────────────────────────────────────
local PANEL_W     = 680
local PANEL_H     = 540
local LIST_LEFT   = 8          -- x de la lista (desde TOPLEFT del panel)
local LIST_TOP    = -86        -- y de inicio del área scrollable
local LIST_W      = 322        -- ancho de la lista
local LIST_H      = 400        -- alto del área scrollable
local LIST_ROW_H  = 22         -- alto por fila
local FORM_LEFT   = 338        -- x del formulario (desde TOPLEFT del panel)
local FORM_TOP    = -86        -- y del formulario
local FORM_W      = 326        -- ancho del formulario

local MAX_VISIBLE = math.floor(LIST_H / LIST_ROW_H)  -- filas visibles

local ICON_CHOICES = {
    "INV_Shirt_GuildTabard_01",
    "INV_BannerPVP_01",
    "INV_BannerPVP_02",
    "INV_Misc_Gear_01",
    "INV_Misc_Coin_01",
    "INV_Misc_GroupLooking",
    "Ability_Rogue_BloodyEye",
    "Ability_Warrior_BattleShout",
    "Spell_Holy_SealOfMight",
    "Spell_Holy_DevotionAura",
    "Spell_Shadow_UnholyFrenzy",
    "Spell_Shadow_Charm",
    "Spell_Frost_FrostArmor02",
    "Spell_Nature_Strength",
    "Achievement_GuildPerk_HastyHearth",
    "Achievement_General_StayClassy",
    "Achievement_Reputation_01",
    "Achievement_Reputation_08",
    "Achievement_Reputation_ArgentChampion",
    "Achievement_Reputation_KirinTor",
    "Achievement_Reputation_AshtongueDeathsworn",
    "Achievement_Reputation_Timbermaw",
    "Achievement_BG_winWSG",
    "Achievement_BG_killingblow_berserker",
    "Ability_DualWield",
    "Ability_Hunter_MarkedForDeath",
    "Ability_Paladin_ArtofWar",
    "Ability_Warrior_RallyingCry",
    "INV_Sword_04",
    "INV_Shield_05",
    "INV_Misc_Head_Dragon_Black",
    "INV_Misc_Head_Human_01",
    "INV_Misc_Bone_HumanSkull_01",
    "INV_Misc_Book_09",
    "INV_Scroll_03",
    "INV_Letter_15",
}

-- ─── Estado ───────────────────────────────────────────────────────────────────
local adminPanel
local listRows    = {}   -- frames reutilizables (MAX_VISIBLE)
local flatList    = {}   -- datos planos: {type="header"|"faction", ...}
local listOffset  = 1
local selectedGroup = "Reputaciones Harford"
local selectedSubgroup = ""
local selectedFactionId = nil
local editingId   = nil  -- nil = creando nueva facción

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[HarfordRepAdmin]|r " .. tostring(msg or ""))
end

local function CanEdit()
    return HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()
end

local function TrimInput(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function HexToRGB(hex)
    hex = TrimInput(hex):gsub("#", "")
    if #hex == 6 then hex = "ff" .. hex end
    if #hex ~= 8 or not hex:match("^%x+$") then return 0.88, 0.88, 0.88, 1 end
    local r = tonumber(hex:sub(3,4), 16) / 255
    local g = tonumber(hex:sub(5,6), 16) / 255
    local b = tonumber(hex:sub(7,8), 16) / 255
    return r, g, b, 1
end

local function RGBToHex(r, g, b)
    r = math.max(0, math.min(255, math.floor((tonumber(r) or 0) * 255 + 0.5)))
    g = math.max(0, math.min(255, math.floor((tonumber(g) or 0) * 255 + 0.5)))
    b = math.max(0, math.min(255, math.floor((tonumber(b) or 0) * 255 + 0.5)))
    return string.format("ff%02x%02x%02x", r, g, b)
end

local function MakeBtn(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetText(text)
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

local function MakeEditBox(parent, w, h)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(w, h)
    box:SetAutoFocus(false)
    box:SetMaxLetters(512)
    return box
end

local function MakeTextArea(parent, w, h)
    local holder = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    holder:SetSize(w, h)
    if holder.SetBackdrop then
        holder:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        holder:SetBackdropColor(0, 0, 0, 0.45)
        holder:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.9)
    end

    local scroll = CreateFrame("ScrollFrame", nil, holder)
    scroll:SetPoint("TOPLEFT", holder, "TOPLEFT", 5, -5)
    scroll:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -5, 5)

    local box = CreateFrame("EditBox", nil, scroll)
    box:SetSize(w - 10, h - 10)
    box:SetAutoFocus(false)
    box:SetMultiLine(true)
    box:SetJustifyH("LEFT")
    box:SetJustifyV("TOP")
    box:SetMaxLetters(512)
    box:SetFontObject(ChatFontNormal)
    box:SetTextInsets(0, 0, 0, 0)
    box:SetScript("OnTextChanged", function(self)
        local textHeight = self:GetStringHeight() or 0
        self:SetHeight(math.max(h - 10, textHeight + 4))
    end)
    scroll:SetScrollChild(box)
    holder:SetScript("OnMouseDown", function()
        box:SetFocus()
    end)
    holder.scrollFrame = scroll
    holder.editBox = box
    return holder, box
end

local function MakeLabel(parent, text, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 11)
    fs:SetText(text)
    if color then
        fs:SetTextColor(unpack(color))
    else
        fs:SetTextColor(0.9, 0.82, 0.65, 1)
    end
    return fs
end

local function PromptText(title, initialText, onAccept)
    StaticPopupDialogs.HARFORD_REP_ADMIN_TEXT = {
        text = title,
        button1 = "Aceptar",
        button2 = "Cancelar",
        hasEditBox = true,
        maxLetters = 64,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnShow = function(self, data)
            self.editBox:SetText(data and data.initialText or "")
            self.editBox:SetFocus()
            self.editBox:HighlightText()
        end,
        OnAccept = function(self, data)
            local text = TrimInput(self.editBox:GetText())
            if text ~= "" and data and data.onAccept then
                data.onAccept(text)
            end
        end,
        EditBoxOnEnterPressed = function(self, data)
            local parent = self:GetParent()
            local text = TrimInput(self:GetText())
            if text ~= "" and data and data.onAccept then
                data.onAccept(text)
            end
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
    }
    StaticPopup_Show("HARFORD_REP_ADMIN_TEXT", nil, nil, { initialText = initialText, onAccept = onAccept })
end

-- ─── Lista plana de datos ─────────────────────────────────────────────────────
local function BuildFlatList()
    if not HarfordReputation then return {} end
    local factions = HarfordReputation.GetFactions(true)  -- incluye ocultas

    -- Agrupar por group → subgroup
    local grouped, gOrder = {}, {}
    local function EnsureGroup(g)
        g = TrimInput(g or "")
        if g == "" then g = "Reputaciones Harford" end
        if not grouped[g] then
            grouped[g] = { root = {}, subs = {}, subOrder = {} }
            gOrder[#gOrder + 1] = g
        end
        return grouped[g], g
    end
    local function EnsureSub(data, s)
        s = TrimInput(s or "")
        if s == "" then return data.root, s end
        if not data.subs[s] then
            data.subs[s] = {}
            data.subOrder[#data.subOrder + 1] = s
        end
        return data.subs[s], s
    end
    for _, groupData in ipairs(HarfordReputation.GetGroups and HarfordReputation.GetGroups() or {}) do
        local data = EnsureGroup(groupData.name or "")
        for _, sub in ipairs(groupData.subgroups or {}) do
            EnsureSub(data, sub)
        end
    end
    for _, faction in ipairs(factions) do
        local data = EnsureGroup(faction.group or "")
        local bucket = EnsureSub(data, faction.subgroup or "")
        bucket[#bucket + 1] = faction
    end

    -- Componer lista plana
    local out = {}
    for _, g in ipairs(gOrder) do
        out[#out + 1] = { type = "group", name = g }
        local data = grouped[g]
        for _, faction in ipairs(data.root or {}) do
            out[#out + 1] = { type = "faction", faction = faction, group = g, subgroup = "" }
        end
        for _, s in ipairs(data.subOrder) do
            out[#out + 1] = { type = "subgroup", name = s, group = g }
            for _, faction in ipairs(data.subs[s] or {}) do
                out[#out + 1] = { type = "faction", faction = faction, group = g, subgroup = s }
            end
        end
    end
    return out
end

local function SameDestination(faction, groupName, subgroupName)
    if not faction then return false end
    local g = TrimInput(faction.group or "")
    if g == "" then g = "Reputaciones Harford" end
    local s = TrimInput(faction.subgroup or "")
    return g == TrimInput(groupName or "") and s == TrimInput(subgroupName or "")
end

local function GetNextSortOrderForDestination(groupName, subgroupName)
    local maxOrder = 0
    if HarfordReputation and HarfordReputation.GetFactions then
        for _, faction in ipairs(HarfordReputation.GetFactions(true) or {}) do
            if SameDestination(faction, groupName, subgroupName) then
                maxOrder = math.max(maxOrder, tonumber(faction.sortOrder) or 0)
            end
        end
    end
    return maxOrder + 10
end

-- ─── Formulario de edición ────────────────────────────────────────────────────
-- Referencias a widgets del form; se crean una vez en BuildForm().
local fName, fIcon, fColor, fDesc, fNotes
local fIconPreview, fColorSwatch, fFormTitle
local fDestination
local formContainer  -- frame padre del formulario
local iconPicker

local function UpdateDestinationLabel()
    if not fDestination then return end
    local text = selectedGroup or "Reputaciones Harford"
    if selectedSubgroup and selectedSubgroup ~= "" then
        text = text .. " / " .. selectedSubgroup
    end
    fDestination:SetText("Destino seleccionado: " .. text)
end

local function GetIconLibrary()
    if LibStub then
        local ok, lib = pcall(LibStub.GetLibrary, LibStub, "LibRPMedia-1.0", true)
        if ok and lib and lib.IsIconDataLoaded and lib:IsIconDataLoaded() then
            return lib
        end
    end
end

local function StripIconName(value)
    if HarfordReputation and HarfordReputation.NormalizeIconName then
        return HarfordReputation.NormalizeIconName(value)
    end
    value = TrimInput(value):gsub("/", "\\")
    value = value:gsub("^Interface\\Icons\\", "")
    value = value:gsub("^Interface\\ICONS\\", "")
    value = value:gsub("^interface\\icons\\", "")
    value = value:gsub("%.blp$", ""):gsub("%.BLP$", "")
    value = value:gsub("%.tga$", ""):gsub("%.TGA$", "")
    return value
end

local function IconTexture(value)
    value = StripIconName(value)
    if value == "" then return nil end
    return "Interface\\Icons\\" .. value
end

local function IconSearchText(value)
    local stripped = StripIconName(value)
    return (stripped ~= "" and stripped or value):lower()
end

local function AddIconChoice(out, seen, value, preferBare)
    value = TrimInput(value)
    if value == "" then return end
    local name = StripIconName(value)
    local stored = name
    local texture = IconTexture(stored)
    if not texture then return end
    local key = IconSearchText(stored)
    if key ~= "" and not seen[key] then
        seen[key] = true
        out[#out + 1] = {
            name = name ~= "" and name or stored,
            value = stored,
            texture = texture,
            search = key,
        }
    end
end

local function CollectIconChoices(filter)
    local seen, out = {}, {}
    local filterText = TrimInput(filter):lower()
    local function Matches(choice)
        return filterText == "" or (choice.search and choice.search:find(filterText, 1, true))
    end
    local function Add(value, preferBare)
        local before = #out
        AddIconChoice(out, seen, value, preferBare)
        if #out > before and not Matches(out[#out]) then
            seen[out[#out].search] = nil
            out[#out] = nil
        end
    end

    Add(fIcon and fIcon:GetText() or "", false)

    local lib = GetIconLibrary()
    if lib and lib.FindIcons then
        for _, name in lib:FindIcons(filterText, { method = "substring" }) do
            Add(name, true)
        end
    elseif TRP3_API and TRP3_API.utils and TRP3_API.utils.resources and TRP3_API.utils.resources.getIconList then
        for _, name in ipairs(TRP3_API.utils.resources.getIconList(filterText) or {}) do
            Add(name, true)
        end
    end

    for _, path in ipairs(ICON_CHOICES) do Add(path, false) end
    if HarfordReputation and HarfordReputation.GetFactions then
        for _, faction in ipairs(HarfordReputation.GetFactions(true) or {}) do
            Add(faction.icon, false)
        end
    end
    table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return out
end

local function RenderIconPicker()
    if not iconPicker then return end
    local choices = iconPicker.choices or {}
    local perPage = iconPicker.perPage or 48
    local maxOffset = math.max(1, #choices - perPage + 1)
    iconPicker.offset = math.max(1, math.min(iconPicker.offset or 1, maxOffset))

    for i, button in ipairs(iconPicker.buttons or {}) do
        local choice = choices[(iconPicker.offset or 1) + i - 1]
        button:SetShown(choice ~= nil)
        button.choice = choice
        if choice then
            button.icon:SetTexture(choice.texture)
            button:SetScript("OnClick", function(self)
                local selected = self.choice
                if not selected then return end
                fIcon:SetText(selected.value)
                fIconPreview:SetTexture(selected.texture)
                fIconPreview:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                iconPicker:Hide()
            end)
        end
    end

    if iconPicker.totalText then
        local total = #choices
        local lib = GetIconLibrary()
        if lib and lib.GetNumIcons then total = lib:GetNumIcons() end
        iconPicker.totalText:SetText(string.format("%d / %d", #choices, total))
    end
    if iconPicker.slider then
        iconPicker._syncingSlider = true
        iconPicker.slider:SetMinMaxValues(1, maxOffset)
        iconPicker.slider:SetValue(iconPicker.offset or 1)
        iconPicker._syncingSlider = false
        iconPicker.slider:SetShown(#choices > perPage)
    end
end

local function RefreshIconPickerChoices()
    if not iconPicker then return end
    local filter = iconPicker.filterBox and iconPicker.filterBox:GetText() or ""
    if iconPicker.lastFilter == filter and iconPicker.choices then
        RenderIconPicker()
        return
    end
    iconPicker.lastFilter = filter
    iconPicker.choices = CollectIconChoices(filter)
    iconPicker.offset = 1
    RenderIconPicker()
end

local function OpenIconPicker(anchor)
    if not iconPicker then
        iconPicker = CreateFrame("Frame", "HarfordRepIconPicker", UIParent, "BackdropTemplate")
        iconPicker:SetSize(440, 440)
        iconPicker:SetFrameStrata("FULLSCREEN_DIALOG")
        iconPicker:SetFrameLevel(1000)
        iconPicker:EnableMouse(true)
        iconPicker:SetMovable(true)
        iconPicker:RegisterForDrag("LeftButton")
        iconPicker:SetScript("OnDragStart", iconPicker.StartMoving)
        iconPicker:SetScript("OnDragStop",  iconPicker.StopMovingOrSizing)
        iconPicker.offset = 1
        iconPicker.perPage = 48
        local bg = iconPicker:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", iconPicker, "TOPLEFT", 8, -8)
        bg:SetPoint("BOTTOMRIGHT", iconPicker, "BOTTOMRIGHT", -8, 8)
        bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        bg:SetAlpha(0.98)
        local border = CreateFrame("Frame", nil, iconPicker, "DialogBorderTemplate")
        border:SetAllPoints(iconPicker)
        local title = MakeLabel(iconPicker, "Buscador de icono", 14, {1, 0.82, 0, 1})
        title:SetPoint("TOP", iconPicker, "TOP", 0, -14)
        local close = CreateFrame("Button", nil, iconPicker, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", iconPicker, "TOPRIGHT", -5, -5)

        iconPicker.content = CreateFrame("Frame", nil, iconPicker, "BackdropTemplate")
        iconPicker.content:SetPoint("TOPLEFT", iconPicker, "TOPLEFT", 24, -54)
        iconPicker.content:SetSize(384, 288)
        iconPicker.content:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        iconPicker.content:SetBackdropColor(0.02, 0.02, 0.02, 0.82)

        iconPicker.buttons = {}
        for i = 1, iconPicker.perPage do
            local b = CreateFrame("Button", nil, iconPicker.content)
            b:SetSize(40, 40)
            local col = (i - 1) % 8
            local row = math.floor((i - 1) / 8)
            b:SetPoint("TOPLEFT", iconPicker.content, "TOPLEFT", 10 + col * 46, -10 - row * 46)
            b:RegisterForClicks("LeftButtonUp")
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.icon:SetAllPoints(b)
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            b:SetScript("OnEnter", function(self)
                if not self.choice then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("|T" .. tostring(self.choice.texture) .. ":48:48|t")
                GameTooltip:AddLine(self.choice.name or self.choice.value or "", 1, 0.82, 0)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            iconPicker.buttons[i] = b
        end

        iconPicker.slider = CreateFrame("Slider", nil, iconPicker.content, "UIPanelScrollBarTemplate")
        iconPicker.slider:SetPoint("TOPLEFT", iconPicker.content, "TOPRIGHT", 4, -17)
        iconPicker.slider:SetPoint("BOTTOMLEFT", iconPicker.content, "BOTTOMRIGHT", 4, 17)
        iconPicker.slider:SetValueStep(8)
        iconPicker.slider:SetScript("OnValueChanged", function(self, value)
            if iconPicker._syncingSlider then return end
            local newOffset = math.floor((tonumber(value) or 1) + 0.5)
            if iconPicker.offset ~= newOffset then
                iconPicker.offset = newOffset
                RenderIconPicker()
            end
        end)

        iconPicker.filterArea = CreateFrame("Frame", nil, iconPicker, "BackdropTemplate")
        iconPicker.filterArea:SetPoint("BOTTOMLEFT", iconPicker, "BOTTOMLEFT", 16, 18)
        iconPicker.filterArea:SetPoint("BOTTOMRIGHT", iconPicker, "BOTTOMRIGHT", -16, 18)
        iconPicker.filterArea:SetHeight(66)
        iconPicker.filterArea:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        iconPicker.filterArea:SetBackdropColor(0.06, 0.045, 0.025, 0.9)
        iconPicker.totalText = MakeLabel(iconPicker.filterArea, "", 11, {0.95, 0.95, 0.95, 1})
        iconPicker.totalText:SetPoint("TOP", iconPicker.filterArea, "TOP", 0, -10)
        iconPicker.filterBox = MakeEditBox(iconPicker.filterArea, 150, 20)
        iconPicker.filterBox:SetPoint("BOTTOM", iconPicker.filterArea, "BOTTOM", 0, 10)
        iconPicker.filterLabel = MakeLabel(iconPicker.filterArea, "Filtro", 10, {1, 0.82, 0, 1})
        iconPicker.filterLabel:SetPoint("BOTTOMLEFT", iconPicker.filterBox, "TOPLEFT", 2, -1)
        iconPicker.filterBox:SetScript("OnTextChanged", function()
            iconPicker.offset = 1
            RefreshIconPickerChoices()
        end)

        iconPicker:EnableMouseWheel(true)
        iconPicker:SetScript("OnMouseWheel", function(_, delta)
            local step = 8
            local maxOffset = math.max(1, #(iconPicker.choices or {}) - (iconPicker.perPage or 48) + 1)
            if delta > 0 then
                iconPicker.offset = math.max(1, (iconPicker.offset or 1) - step)
            else
                iconPicker.offset = math.min(maxOffset, (iconPicker.offset or 1) + step)
            end
            RenderIconPicker()
        end)
        iconPicker:Hide()
    end

    iconPicker.offset = 1
    iconPicker.lastFilter = nil
    if iconPicker.filterBox then iconPicker.filterBox:SetText("") end
    RefreshIconPickerChoices()
    iconPicker:ClearAllPoints()
    iconPicker:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    iconPicker:SetFrameStrata("FULLSCREEN_DIALOG")
    iconPicker:SetFrameLevel(1000)
    iconPicker:Show()
    iconPicker:Raise()
end

local function OpenColorPicker()
    local r, g, b = HexToRGB(fColor and fColor:GetText() or "ffe0e0e0")
    local function ApplyColor()
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        local hex = RGBToHex(nr, ng, nb)
        fColor:SetText(hex)
        fColorSwatch:SetColorTexture(nr, ng, nb, 1)
    end
    ColorPickerFrame.func = ApplyColor
    ColorPickerFrame.opacityFunc = ApplyColor
    ColorPickerFrame.cancelFunc = function(previous)
        if previous then
            fColor:SetText(previous.hex)
            fColorSwatch:SetColorTexture(previous.r, previous.g, previous.b, 1)
        end
    end
    ColorPickerFrame.previousValues = { r = r, g = g, b = b, hex = fColor:GetText() }
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Show()
end

local function FormClear()
    fName:SetText("")
    fIcon:SetText("")
    fDesc:SetText("")
    fNotes:SetText("")
    fColor:SetText("ffe0e0e0")
    fIconPreview:SetTexture(nil)
    fColorSwatch:SetColorTexture(0.88, 0.88, 0.88, 1)
    fFormTitle:SetText("Nueva faccion")
    editingId = nil
    selectedFactionId = nil
    UpdateDestinationLabel()
end

local function FormLoad(factionId)
    if not HarfordReputation then return end
    local faction = HarfordReputation.GetFaction(factionId)
    if not faction then return end
    editingId = factionId
    selectedFactionId = factionId
    fName:SetText(faction.name or "")
    fIcon:SetText(StripIconName(faction.icon or ""))
    fDesc:SetText(faction.description or "")
    fNotes:SetText(faction.gmNotes or "")
    fColor:SetText(faction.color or "ffe0e0e0")
    if faction.icon and faction.icon ~= "" then
        fIconPreview:SetTexture(IconTexture(faction.icon))
        fIconPreview:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        fIconPreview:SetTexture(nil)
    end
    local r, g, b = HexToRGB(faction.color or "ffe0e0e0")
    fColorSwatch:SetColorTexture(r, g, b, 1)
    fFormTitle:SetText("Editando: " .. tostring(faction.name or factionId))
end

local function FormSave()
    if not CanEdit() then Print("Solo DM."); return end
    local currentFaction = editingId and HarfordReputation.GetFaction(editingId) or nil
    local changedDestination = not currentFaction or not SameDestination(currentFaction, selectedGroup, selectedSubgroup)
    local data = {
        name        = TrimInput(fName:GetText()),
        group       = selectedGroup or "Reputaciones Harford",
        subgroup    = selectedSubgroup or "",
        icon        = StripIconName(fIcon:GetText()),
        description = TrimInput(fDesc:GetText()),
        gmNotes     = TrimInput(fNotes:GetText()),
        color       = TrimInput(fColor:GetText()),
        sortOrder   = changedDestination and GetNextSortOrderForDestination(selectedGroup, selectedSubgroup) or (currentFaction and currentFaction.sortOrder or 0),
        hidden      = currentFaction and currentFaction.hidden == true or false,
    }
    if data.name == "" then Print("El nombre no puede estar vacio."); return end

    local ok, err
    if editingId then
        ok, err = HarfordReputation.UpdateFaction(editingId, data)
        if ok then Print("Faccion '" .. data.name .. "' actualizada.") end
    else
        ok, err = HarfordReputation.CreateFaction(data)
        if ok then
            editingId = err  -- CreateFaction devuelve (true, id)
            err = nil
            Print("Faccion '" .. data.name .. "' creada.")
        end
    end
    if not ok then Print(tostring(err)) end
    AdminAPI.Refresh()
end

local function MoveEditingToDestination()
    if not editingId or not HarfordReputation then
        Print("Edita una faccion primero.")
        return
    end
    local faction = HarfordReputation.GetFaction(editingId)
    if not faction then return end
    local data = {
        name = faction.name,
        group = selectedGroup or "Reputaciones Harford",
        subgroup = selectedSubgroup or "",
        icon = faction.icon,
        description = faction.description,
        gmNotes = faction.gmNotes,
        color = faction.color,
        hidden = faction.hidden == true,
        sortOrder = GetNextSortOrderForDestination(selectedGroup, selectedSubgroup),
    }
    local ok, err = HarfordReputation.UpdateFaction(editingId, data)
    if ok then
        FormLoad(editingId)
        Print("Faccion movida a " .. tostring(selectedGroup) .. (selectedSubgroup ~= "" and (" / " .. selectedSubgroup) or "") .. ".")
        AdminAPI.Refresh()
    else
        Print(err)
    end
end

local function ShareAllReputations()
    if not CanEdit() then Print("Solo DM."); return end
    if not HarfordReputationSync or not HarfordReputationSync.BroadcastSnapshotAll then
        Print("Sync de reputaciones no disponible.")
        return
    end
    local ok, info = HarfordReputationSync.BroadcastSnapshotAll()
    if ok then
        Print("Reputaciones compartidas con la raid/grupo (" .. tostring(info or 1) .. " fragmentos).")
    else
        Print(tostring(info or "No se pudo compartir."))
    end
end

local function ShareReputationStructure()
    if not CanEdit() then Print("Solo DM."); return end
    if not HarfordReputationSync or not HarfordReputationSync.BroadcastSnapshotStructure then
        Print("Sync de reputaciones no disponible.")
        return
    end
    local ok, info = HarfordReputationSync.BroadcastSnapshotStructure()
    if ok then
        Print("Estructura de reputaciones compartida (" .. tostring(info or 1) .. " fragmentos).")
    else
        Print(tostring(info or "No se pudo compartir."))
    end
end

local function ShareSelectedReputation()
    if not CanEdit() then Print("Solo DM."); return end
    local factionId = selectedFactionId or editingId
    if not factionId or factionId == "" then
        Print("Selecciona o edita una reputacion primero.")
        return
    end
    if not HarfordReputationSync or not HarfordReputationSync.BroadcastSnapshotFaction then
        Print("Sync de reputaciones no disponible.")
        return
    end
    local ok, info = HarfordReputationSync.BroadcastSnapshotFaction(factionId)
    if ok then
        Print("Reputacion seleccionada compartida (" .. tostring(info or 1) .. " fragmentos).")
    else
        Print(tostring(info or "No se pudo compartir."))
    end
end

local function LiveUpdateIconPreview(self)
    local path = TrimInput(self:GetText())
    if path ~= "" then
        fIconPreview:SetTexture(IconTexture(path))
        fIconPreview:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        fIconPreview:SetTexture(nil)
    end
end

local function LiveUpdateColorSwatch(self)
    local r, g, b = HexToRGB(self:GetText())
    fColorSwatch:SetColorTexture(r, g, b, 1)
end

local function BuildForm(parent)
    formContainer = CreateFrame("Frame", nil, parent)
    formContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", FORM_LEFT, FORM_TOP)
    formContainer:SetSize(FORM_W, LIST_H + 40)

    -- Fondo del formulario
    local bg = formContainer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(formContainer)
    bg:SetColorTexture(0.06, 0.05, 0.035, 0.55)

    -- Título del formulario
    fFormTitle = MakeLabel(formContainer, "Nueva faccion", 12, {1, 0.82, 0, 1})
    fFormTitle:SetPoint("TOPLEFT", formContainer, "TOPLEFT", 8, -8)

    fDestination = MakeLabel(formContainer, "", 10, {0.72, 0.72, 0.72, 1})
    fDestination:SetPoint("TOPLEFT", fFormTitle, "BOTTOMLEFT", 0, -4)
    fDestination:SetWidth(FORM_W - 16)
    fDestination:SetJustifyH("LEFT")
    UpdateDestinationLabel()

    -- Separador
    local sep = formContainer:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", formContainer, "TOPLEFT", 0, -36)
    sep:SetPoint("TOPRIGHT", formContainer, "TOPRIGHT", 0, -36)
    sep:SetHeight(1)
    sep:SetColorTexture(0.5, 0.42, 0.22, 0.55)

    -- ── Filas de campos ────────────────────────────────────────────────────────
    local LW, IW = 90, 220  -- label width, input width
    local rowY = -44         -- y inicial desde TOPLEFT del formContainer
    local rowGap = -26       -- espaciado entre filas

    local function AddRow(labelText, widget, height)
        local lbl = MakeLabel(formContainer, labelText, 11)
        lbl:SetPoint("TOPLEFT", formContainer, "TOPLEFT", 8, rowY)
        lbl:SetWidth(LW)
        lbl:SetJustifyH("LEFT")
        widget:SetPoint("TOPLEFT", formContainer, "TOPLEFT", LW + 12, rowY + 1)
        rowY = rowY - math.max(math.abs(rowGap), tonumber(height) or 20) - 6
        return lbl
    end

    fName = MakeEditBox(formContainer, IW, 20); AddRow("Nombre:", fName)

    -- Fila de icono con preview
    fIcon = MakeEditBox(formContainer, IW - 54, 20)
    AddRow("Icono:", fIcon)
    -- el label ya se creó; añadir preview a la derecha del input
    fIconPreview = formContainer:CreateTexture(nil, "ARTWORK")
    fIconPreview:SetSize(22, 22)
    fIconPreview:SetPoint("LEFT", fIcon, "RIGHT", 3, 0)
    fIcon:SetScript("OnTextChanged", LiveUpdateIconPreview)
    local iconPickBtn = MakeBtn(formContainer, "...", 24, 20, function(self) OpenIconPicker(self) end)
    iconPickBtn:SetPoint("LEFT", fIconPreview, "RIGHT", 3, 0)

    -- Fila de color con swatch
    fColor = MakeEditBox(formContainer, IW - 54, 20)
    AddRow("Color (AARRGGBB):", fColor)
    fColorSwatch = formContainer:CreateTexture(nil, "ARTWORK")
    fColorSwatch:SetSize(18, 18)
    fColorSwatch:SetPoint("LEFT", fColor, "RIGHT", 3, 0)
    fColor:SetScript("OnTextChanged", LiveUpdateColorSwatch)
    local colorPickBtn = MakeBtn(formContainer, "...", 24, 20, OpenColorPicker)
    colorPickBtn:SetPoint("LEFT", fColorSwatch, "RIGHT", 3, 0)

    local fDescHolder
    fDescHolder, fDesc = MakeTextArea(formContainer, IW, 72)
    AddRow("Descripcion:", fDescHolder, 72)
    fNotes    = MakeEditBox(formContainer, IW, 20); AddRow("Notas GM:",   fNotes)

    -- Fila orden + checkbox oculta en la misma línea
    -- Botones de acción del form
    local btnGuardar  = MakeBtn(formContainer, "Guardar",  72, 22, FormSave)
    local btnMover = MakeBtn(formContainer, "Mover aqui", 82, 22, MoveEditingToDestination)
    local btnCancelar = MakeBtn(formContainer, "Cancelar", 72, 22, function()
        FormClear()
        AdminAPI.Refresh()
    end)
    rowY = rowY - 4
    btnGuardar:SetPoint("TOPLEFT",  formContainer, "TOPLEFT", 8, rowY)
    btnMover:SetPoint("LEFT", btnGuardar, "RIGHT", 6, 0)
    btnCancelar:SetPoint("LEFT", btnMover, "RIGHT", 6, 0)

    -- Línea de ayuda de grupos existentes
end

-- ─── Filas de la lista ────────────────────────────────────────────────────────
-- Estructura por fila:
-- [up][down] [icon] [name text ................] [vis][edit][del]
-- Para headers (group/subgroup): fondo diferente + botón Renombrar.

local function CreateListRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(LIST_W, LIST_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * LIST_ROW_H))
    row:EnableMouse(true)

    -- Fondo
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(row)
    bg:SetColorTexture(0, 0, 0, 0)
    row.bg = bg

    -- Botón ↑
    local btnUp = CreateFrame("Button", nil, row)
    btnUp:SetSize(16, 16)
    btnUp:SetPoint("LEFT", row, "LEFT", 2, 0)
    btnUp:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    btnUp:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    btnUp:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled", "ADD")
    btnUp:EnableMouse(true)
    row.btnUp = btnUp

    -- Botón ↓
    local btnDown = CreateFrame("Button", nil, row)
    btnDown:SetSize(16, 16)
    btnDown:SetPoint("LEFT", row, "LEFT", 20, 0)
    btnDown:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    btnDown:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    btnDown:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled", "ADD")
    btnDown:EnableMouse(true)
    row.btnDown = btnDown

    -- Icono de facción
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", row, "LEFT", 40, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon

    -- Texto (nombre de facción o encabezado)
    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetPoint("LEFT", row, "LEFT", 60, 0)
    label:SetPoint("RIGHT", row, "RIGHT", -104, 0)
    row.label = label

    -- Boton Ocultar/Mostrar
    local btnVis = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnVis:SetSize(34, 18)
    btnVis:SetPoint("RIGHT", row, "RIGHT", -64, 0)
    btnVis:SetText("Ver")
    btnVis:EnableMouse(true)
    row.btnVis = btnVis

    -- Boton Editar
    local btnEdit = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnEdit:SetSize(34, 18)
    btnEdit:SetPoint("RIGHT", row, "RIGHT", -28, 0)
    btnEdit:SetText("Edit")
    btnEdit:EnableMouse(true)
    row.btnEdit = btnEdit

    -- Boton Borrar
    local btnDel = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnDel:SetSize(24, 18)
    btnDel:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    btnDel:SetText("X")
    btnDel:EnableMouse(true)
    row.btnDel = btnDel

    -- Botón Renombrar (solo visible en headers de grupo/subgrupo)
    local btnRename = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnRename:SetSize(70, 18)
    btnRename:SetPoint("RIGHT", row, "RIGHT", -28, 0)
    btnRename:SetText("Renombrar")
    btnRename:EnableMouse(true)
    btnRename:Hide()
    row.btnRename = btnRename

    -- Botón Borrar encabezado (solo visible en headers de grupo/subgrupo)
    local btnDelHeader = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    btnDelHeader:SetSize(24, 18)
    btnDelHeader:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    btnDelHeader:SetText("X")
    btnDelHeader:EnableMouse(true)
    btnDelHeader:Hide()
    row.btnDelHeader = btnDelHeader

    return row
end

local function ShowRenamePopup(parentRow, rowData, onConfirm)
    if not renamePopup then
        renamePopup = CreateFrame("Frame", "HarfordRepAdminRenamePopup", UIParent, "BackdropTemplate")
        renamePopup:SetSize(280, 80)
        renamePopup:SetFrameStrata("DIALOG")
        renamePopup:SetFrameLevel(500)
        renamePopup:SetMovable(true)
        renamePopup:EnableMouse(true)
        renamePopup:RegisterForDrag("LeftButton")
        renamePopup:SetScript("OnDragStart", renamePopup.StartMoving)
        renamePopup:SetScript("OnDragStop", renamePopup.StopMovingOrSizing)
        local bg = renamePopup:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(renamePopup)
        bg:SetColorTexture(0.08, 0.07, 0.05, 0.98)
        local border = CreateFrame("Frame", nil, renamePopup, "DialogBorderTemplate")
        border:SetAllPoints(renamePopup)

        renamePopup.input = MakeEditBox(renamePopup, 240, 20)
        renamePopup.input:SetPoint("TOPLEFT", renamePopup, "TOPLEFT", 18, -22)

        renamePopup.btnOk     = MakeBtn(renamePopup, "OK",       60, 22, nil)
        renamePopup.btnCancel = MakeBtn(renamePopup, "Cancelar", 80, 22, function()
            renamePopup:Hide()
        end)
        renamePopup.btnOk:SetPoint("BOTTOMLEFT",  renamePopup, "BOTTOMLEFT",  18, 10)
        renamePopup.btnCancel:SetPoint("LEFT", renamePopup.btnOk, "RIGHT", 8, 0)
    end

    renamePopup.input:SetText(rowData.name or "")
    renamePopup.btnOk:SetScript("OnClick", function()
        local newName = TrimInput(renamePopup.input:GetText())
        if newName ~= "" then
            onConfirm(newName)
        end
        renamePopup:Hide()
    end)
    renamePopup:ClearAllPoints()
    renamePopup:SetPoint("TOPLEFT", parentRow, "BOTTOMLEFT", 0, -4)
    renamePopup:Show()
    renamePopup.input:SetFocus()
end

-- ─── Refresh de la lista ──────────────────────────────────────────────────────
local function FindAdjacentFaction(targetIndex, direction)
    local current = flatList[targetIndex] and flatList[targetIndex].faction
    -- Busca la facción más cercana en `direction` (+1/-1) para intercambiar orden
    for i = targetIndex + direction, direction > 0 and #flatList or 1, direction do
        if flatList[i] and flatList[i].type == "faction" and SameDestination(flatList[i].faction, current and current.group, current and current.subgroup) then
            return flatList[i].faction
        end
    end
    return nil
end

local function NormalizeVisibleFactionOrder(groupName, subgroupName)
    local order = 10
    for _, row in ipairs(flatList or {}) do
        if row.type == "faction" and row.faction and SameDestination(row.faction, groupName, subgroupName) then
            row.faction.sortOrder = order
            order = order + 10
        end
    end
end

local function RefreshList()
    flatList = BuildFlatList()
    local maxOffset = math.max(1, #flatList - MAX_VISIBLE + 1)
    if listOffset > maxOffset then listOffset = maxOffset end
    if listOffset < 1 then listOffset = 1 end

    for i, row in ipairs(listRows) do
        local dataIndex = listOffset + i - 1
        local data = flatList[dataIndex]
        if not data then
            row:Hide()
        else
            row:Show()
            -- Ocultar todos los botones de acción primero
            row.btnUp:Hide()
            row.btnDown:Hide()
            row.btnVis:Hide()
            row.btnEdit:Hide()
            row.btnDel:Hide()
            row.btnRename:Hide()
            if row.btnDelHeader then row.btnDelHeader:Hide() end
            row.icon:SetTexture(nil)
            row:SetScript("OnMouseUp", nil)
            row.label:ClearAllPoints()

            if data.type == "group" then
                row.bg:SetColorTexture(0.10, 0.08, 0.05, 0.75)
                row.label:SetFont("Fonts\\FRIZQT__.TTF", 12)
                row.label:SetTextColor(1.0, 0.82, 0.0, 1)
                row.label:SetText("- " .. (data.name or ""))
                row.label:SetPoint("LEFT", row, "LEFT", 44, 0)
                row.label:SetPoint("RIGHT", row.btnRename, "LEFT", -4, 0)
                row:SetScript("OnMouseUp", function()
                    selectedGroup = data.name or "Reputaciones Harford"
                    selectedSubgroup = ""
                    UpdateDestinationLabel()
                    Print("Destino seleccionado: " .. selectedGroup)
                end)
                row.btnUp:Show()
                row.btnUp:SetScript("OnClick", function()
                    if HarfordReputation and HarfordReputation.MoveGroupOrder then
                        local ok, err = HarfordReputation.MoveGroupOrder(data.name, -1)
                        if not ok and err then Print(err) end
                        RefreshList()
                    end
                end)
                row.btnDown:Show()
                row.btnDown:SetScript("OnClick", function()
                    if HarfordReputation and HarfordReputation.MoveGroupOrder then
                        local ok, err = HarfordReputation.MoveGroupOrder(data.name, 1)
                        if not ok and err then Print(err) end
                        RefreshList()
                    end
                end)
                row.btnRename:Show()
                row.btnRename:SetScript("OnClick", function()
                    ShowRenamePopup(row, data, function(newName)
                        if not HarfordReputation then return end
                        HarfordReputation.RenameGroup(data.name, newName)
                        RefreshList()
                    end)
                end)
                if row.btnDelHeader then
                    row.btnDelHeader:Show()
                    row.btnDelHeader:SetScript("OnClick", function()
                        if IsShiftKeyDown() then
                            local ok, err = HarfordReputation.DeleteGroup(data.name)
                            if not ok then Print(tostring(err)) else RefreshList() end
                        else
                            Print("Shift+clic en X para borrar el grupo '" .. tostring(data.name) .. "'.")
                        end
                    end)
                end

            elseif data.type == "subgroup" then
                row.bg:SetColorTexture(0.07, 0.06, 0.04, 0.60)
                row.label:SetFont("Fonts\\FRIZQT__.TTF", 11)
                row.label:SetTextColor(0.85, 0.72, 0.45, 1)
                row.label:SetText("  > " .. (data.name or ""))
                row.label:SetPoint("LEFT", row, "LEFT", 44, 0)
                row.label:SetPoint("RIGHT", row.btnRename, "LEFT", -4, 0)
                row:SetScript("OnMouseUp", function()
                    selectedGroup = data.group or "Reputaciones Harford"
                    selectedSubgroup = data.name or ""
                    UpdateDestinationLabel()
                    Print("Destino seleccionado: " .. selectedGroup .. " / " .. selectedSubgroup)
                end)
                row.btnUp:Show()
                row.btnUp:SetScript("OnClick", function()
                    if HarfordReputation and HarfordReputation.MoveSubgroupOrder then
                        local ok, err = HarfordReputation.MoveSubgroupOrder(data.group, data.name, -1)
                        if not ok and err then Print(err) end
                        RefreshList()
                    end
                end)
                row.btnDown:Show()
                row.btnDown:SetScript("OnClick", function()
                    if HarfordReputation and HarfordReputation.MoveSubgroupOrder then
                        local ok, err = HarfordReputation.MoveSubgroupOrder(data.group, data.name, 1)
                        if not ok and err then Print(err) end
                        RefreshList()
                    end
                end)
                row.btnRename:Show()
                row.btnRename:SetScript("OnClick", function()
                    ShowRenamePopup(row, data, function(newName)
                        if not HarfordReputation then return end
                        HarfordReputation.RenameSubgroup(data.group, data.name, newName)
                        RefreshList()
                    end)
                end)
                if row.btnDelHeader then
                    row.btnDelHeader:Show()
                    row.btnDelHeader:SetScript("OnClick", function()
                        if IsShiftKeyDown() then
                            local ok, err = HarfordReputation.DeleteSubgroup(data.group, data.name)
                            if not ok then Print(tostring(err)) else RefreshList() end
                        else
                            Print("Shift+clic en X para borrar la seccion '" .. tostring(data.name) .. "'.")
                        end
                    end)
                end

            else  -- type == "faction"
                local faction = data.faction
                local isHidden = faction.hidden
                row.bg:SetColorTexture(0, 0, 0, isHidden and 0.05 or 0)
                row.label:SetFont("Fonts\\FRIZQT__.TTF", 11)
                row.label:SetPoint("LEFT", row, "LEFT", 60, 0)
                row.label:SetPoint("RIGHT", row.btnVis, "LEFT", -4, 0)
                if isHidden then
                    row.label:SetTextColor(0.55, 0.55, 0.55, 1)
                    row.label:SetText((faction.name or faction.id or "") .. " [oculta]")
                else
                    row.label:SetTextColor(1, 1, 1, 1)
                    row.label:SetText(faction.name or faction.id or "")
                end
                if faction.icon and faction.icon ~= "" then
                    row.icon:SetTexture(IconTexture(faction.icon))
                else
                    row.icon:SetTexture(HarfordReputation and HarfordReputation.ResolveIconTexture and HarfordReputation.ResolveIconTexture(HarfordReputation.TABARD_ICON) or nil)
                end
                row:SetScript("OnMouseUp", function()
                    selectedFactionId = faction.id
                    Print("Reputacion seleccionada: " .. tostring(faction.name or faction.id))
                end)

                -- ↑
                row.btnUp:Show()
                row.btnUp:SetScript("OnClick", function()
                    local adj = FindAdjacentFaction(dataIndex, -1)
                    if HarfordReputation then
                        NormalizeVisibleFactionOrder(faction.group, faction.subgroup)
                        local ok, err = adj and HarfordReputation.SwapFactionOrder(faction.id, adj.id)
                        if not ok and err then Print(err) end
                        RefreshList()
                    end
                end)

                -- ↓
                row.btnDown:Show()
                row.btnDown:SetScript("OnClick", function()
                    local adj = FindAdjacentFaction(dataIndex, 1)
                    if HarfordReputation then
                        NormalizeVisibleFactionOrder(faction.group, faction.subgroup)
                        local ok, err = adj and HarfordReputation.SwapFactionOrder(faction.id, adj.id)
                        if not ok and err then Print(err) end
                        RefreshList()
                    end
                end)

                row.btnVis:Show()
                row.btnVis:SetText(isHidden and "Ver" or "Oc")
                row.btnVis:SetScript("OnClick", function()
                    if HarfordReputation then
                        HarfordReputation.SetFactionHidden(faction.id, not isHidden)
                        RefreshList()
                    end
                end)

                row.btnEdit:Show()
                row.btnEdit:SetScript("OnClick", function()
                    FormLoad(faction.id)
                end)

                row.btnDel:Show()
                row.btnDel:SetScript("OnClick", function()
                    -- Doble clic o shift para evitar borrados accidentales
                    if IsShiftKeyDown() then
                        if HarfordReputation then
                            local ok, err = HarfordReputation.DeleteFaction(faction.id)
                            if not ok then Print(tostring(err)) end
                            if editingId == faction.id then FormClear() end
                            RefreshList()
                        end
                    else
                        Print("Shift+clic en X para confirmar borrado de '" .. tostring(faction.name or faction.id) .. "'.")
                    end
                end)
            end
        end
    end

    -- Scroll
    if adminPanel then
        if adminPanel.btnScrollUp then
            adminPanel.btnScrollUp:SetEnabled(listOffset > 1)
        end
        if adminPanel.btnScrollDown then
            adminPanel.btnScrollDown:SetEnabled(listOffset < math.max(1, #flatList - MAX_VISIBLE + 1))
        end
    end
end

function AdminAPI.Refresh()
    RefreshList()
    if HarfordReputationUI and HarfordReputationUI.Refresh then
        HarfordReputationUI.Refresh()
    end
end

-- ─── Construcción del panel principal ────────────────────────────────────────
local function CreateAdminPanel()
    if adminPanel then return adminPanel end

    adminPanel = CreateFrame("Frame", "HarfordReputationAdminPanel", UIParent, "ButtonFrameTemplate")
    adminPanel:SetSize(PANEL_W, PANEL_H)
    adminPanel:SetMovable(true)
    adminPanel:EnableMouse(true)
    adminPanel:RegisterForDrag("LeftButton")
    adminPanel:SetScript("OnDragStart", adminPanel.StartMoving)
    adminPanel:SetScript("OnDragStop", adminPanel.StopMovingOrSizing)
    adminPanel:SetFrameStrata("DIALOG")
    adminPanel:SetFrameLevel(130)
    adminPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    adminPanel:Hide()

    if ButtonFrameTemplate_HidePortrait then pcall(ButtonFrameTemplate_HidePortrait, adminPanel) end
    if ButtonFrameTemplate_HideAttic    then pcall(ButtonFrameTemplate_HideAttic,    adminPanel) end

    if adminPanel.TitleText then
        adminPanel.TitleText:SetText("Admin: Reputaciones")
    end

    -- Fondo interior de mármol
    local bg = adminPanel:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 7, -24)
    bg:SetPoint("BOTTOMRIGHT", -7, 7)
    bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
    bg:SetAlpha(0.96)

    local hdrForm = MakeLabel(adminPanel, "Crear / Editar faccion", 12, {1, 0.82, 0, 1})
    hdrForm:SetPoint("TOPLEFT", adminPanel, "TOPLEFT", FORM_LEFT + 8, -62)

    -- Separador vertical entre columnas
    local vSep = adminPanel:CreateTexture(nil, "ARTWORK")
    vSep:SetPoint("TOPLEFT", adminPanel, "TOPLEFT", FORM_LEFT - 4, -62)
    vSep:SetPoint("BOTTOMLEFT", adminPanel, "BOTTOMLEFT", FORM_LEFT - 4, 36)
    vSep:SetWidth(1)
    vSep:SetColorTexture(0.5, 0.42, 0.22, 0.5)

    -- Separador horizontal bajo cabeceras
    local hSep = adminPanel:CreateTexture(nil, "ARTWORK")
    hSep:SetPoint("TOPLEFT",  adminPanel, "TOPLEFT",  LIST_LEFT, LIST_TOP)
    hSep:SetPoint("TOPRIGHT", adminPanel, "TOPRIGHT", -8,        LIST_TOP)
    hSep:SetHeight(1)
    hSep:SetColorTexture(0.5, 0.42, 0.22, 0.5)

    local buttonGroup = CreateFrame("Frame", nil, adminPanel)
    buttonGroup:SetSize(254, 22)
    buttonGroup:SetPoint("TOPLEFT", adminPanel, "TOPLEFT", LIST_LEFT + ((LIST_W - 254) / 2), -60)

    -- Botón "Nueva facción" encima de la lista
    local btnNuevaFaccion = MakeBtn(adminPanel, "Nueva faccion", 110, 22, function()
        FormClear()
    end)
    btnNuevaFaccion:SetPoint("RIGHT", buttonGroup, "RIGHT", 0, 0)

    local btnNuevoGrupo = MakeBtn(adminPanel, "Grupo", 62, 22, function()
        PromptText("Nuevo grupo", "", function(name)
            local ok, err = HarfordReputation.CreateGroup(name)
            if not ok then Print(err) return end
            selectedGroup = name
            selectedSubgroup = ""
            UpdateDestinationLabel()
            RefreshList()
        end)
    end)
    btnNuevoGrupo:SetPoint("RIGHT", btnNuevaFaccion, "LEFT", -6, 0)

    local btnNuevaSeccion = MakeBtn(adminPanel, "Seccion", 72, 22, function()
        local groupName = selectedGroup or "Reputaciones Harford"
        PromptText("Nueva seccion en " .. groupName, "", function(name)
            local ok, err = HarfordReputation.CreateSubgroup(groupName, name)
            if not ok then Print(err) return end
            selectedSubgroup = name
            UpdateDestinationLabel()
            RefreshList()
        end)
    end)
    btnNuevaSeccion:SetPoint("RIGHT", btnNuevoGrupo, "LEFT", -6, 0)

    -- Contenedor scrollable de la lista
    local listHolder = CreateFrame("Frame", nil, adminPanel)
    listHolder:SetPoint("TOPLEFT", adminPanel, "TOPLEFT", LIST_LEFT, LIST_TOP - 4)
    listHolder:SetSize(LIST_W, LIST_H)

    for i = 1, MAX_VISIBLE do
        listRows[i] = CreateListRow(listHolder, i)
    end

    listHolder:EnableMouse(true)
    listHolder:EnableMouseWheel(true)
    listHolder:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            listOffset = math.max(1, listOffset - 1)
        else
            listOffset = listOffset + 1
        end
        RefreshList()
    end)

    -- Formulario de edición (columna derecha)
    local btnShareStructure = MakeBtn(adminPanel, "Compartir estructura", 150, 24, ShareReputationStructure)
    btnShareStructure:SetPoint("BOTTOMLEFT", adminPanel, "BOTTOMLEFT", 18, 8)
    local btnShareAll = MakeBtn(adminPanel, "Compartir todo", 124, 24, ShareAllReputations)
    btnShareAll:SetPoint("LEFT", btnShareStructure, "RIGHT", 8, 0)
    local btnShareSelected = MakeBtn(adminPanel, "Compartir seleccion", 158, 24, ShareSelectedReputation)
    btnShareSelected:SetPoint("LEFT", btnShareAll, "RIGHT", 6, 0)

    BuildForm(adminPanel)

    return adminPanel
end

-- ─── API pública ──────────────────────────────────────────────────────────────
function AdminAPI.Toggle()
    CreateAdminPanel()
    if adminPanel:IsShown() then
        adminPanel:Hide()
    else
        if not CanEdit() then
            Print("Solo disponible en modo DM.")
            return
        end
        adminPanel:Show()
        adminPanel:Raise()
        FormClear()
        AdminAPI.Refresh()
    end
end

function AdminAPI.Open()
    CreateAdminPanel()
    if not CanEdit() then Print("Solo disponible en modo DM."); return end
    adminPanel:Show()
    adminPanel:Raise()
    AdminAPI.Refresh()
end

function AdminAPI.Close()
    if adminPanel then adminPanel:Hide() end
end
