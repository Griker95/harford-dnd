HarfordLootLootRegistry = HarfordLootLootRegistry or {}

HarfordLootGlobalLootRegistry = HarfordLootGlobalLootRegistry or {}

HarfordLootTaggedCreatureRegistry = HarfordLootTaggedCreatureRegistry or {}
HarfordLootConfigStore = HarfordLootConfigStore or {}

local COMM_PREFIX = "HARFORDLOOT"
local LOOT_CFG_PREFIX = "HARFORDCFG"

local SendLootSync
local SendLootClearRemote
local RefreshLootFrameIfTargetMatches

HarfordLootAPI = HarfordLootAPI or {}

function HarfordLootAPI.ExportConfigStrings()
    return
        HarfordSync.SerializeLootRegistryTable(HarfordLootLootRegistry),
        HarfordSync.SerializeLootGlobalTable(HarfordLootGlobalLootRegistry)
end

function HarfordLootAPI.ApplyConfigStrings(regRaw, globalRaw)
    if regRaw and regRaw ~= "" then
        HarfordLootLootRegistry = HarfordSync.DeserializeLootRegistryTable(regRaw)
    else
        HarfordLootLootRegistry = {}
    end

    if globalRaw and globalRaw ~= "" then
        HarfordLootGlobalLootRegistry = HarfordSync.DeserializeLootGlobalTable(globalRaw)
    else
        HarfordLootGlobalLootRegistry = {}
    end
end

function HarfordLootAPI.LoadConfig()
    HarfordLootConfigStore, HarfordLootLootRegistry, HarfordLootGlobalLootRegistry =
        HarfordSync.LoadLootConfigTables(
            HarfordLootConfigStore,
            HarfordLootLootRegistry,
            HarfordLootGlobalLootRegistry
        )

    return (next(HarfordLootLootRegistry) ~= nil) or (next(HarfordLootGlobalLootRegistry) ~= nil)
end

function HarfordLootAPI.SaveConfig()
    HarfordLootConfigStore = HarfordSync.SaveLootConfigTables(
        HarfordLootConfigStore,
        HarfordLootLootRegistry,
        HarfordLootGlobalLootRegistry
    )
end

function HarfordLootAPI.ApplyConfig(payload)
    local regRaw, globalRaw = HarfordSync.DeserializeLootConfigMessage(payload)
    if regRaw == nil then
        return false
    end

    HarfordLootAPI.ApplyConfigStrings(regRaw, globalRaw)
    HarfordLootAPI.SaveConfig()
    return true
end

function HarfordLootAPI.BroadcastConfig(channel, target)
    return HarfordSync.SendLootConfigTables(
        LOOT_CFG_PREFIX,
        HarfordLootLootRegistry,
        HarfordLootGlobalLootRegistry,
        channel,
        target
    )
end

function HarfordLootAPI.ClearRemoteLoot(channel, target, clearConfigToo)
    if clearConfigToo then
        HarfordSync.SendLootConfigTables(LOOT_CFG_PREFIX, {}, {}, channel, target)
    end

    return SendLootClearRemote("ALL", channel, target)
end

function HarfordLootAPI.SetConfigTables(registryTable, globalTable, saveNow)
    if type(registryTable) == "table" then
        HarfordLootLootRegistry = registryTable
    else
        HarfordLootLootRegistry = {}
    end

    if type(globalTable) == "table" then
        HarfordLootGlobalLootRegistry = globalTable
    else
        HarfordLootGlobalLootRegistry = {}
    end

    if saveNow then
		HarfordLootAPI.SaveConfig()
	end

    return true
end

function HarfordLootAPI.GetConfigTables()
    return HarfordLootLootRegistry, HarfordLootGlobalLootRegistry
end

function HarfordLootAPI.ImportConfigTables(registryTable, globalTable, saveNow, broadcastNow, channel, target)
    HarfordLootAPI.SetConfigTables(registryTable, globalTable, saveNow)

    if broadcastNow then
        HarfordLootAPI.BroadcastConfig(channel, target)
    end

    return true
end

local function GetTargetCreatureId()
    local guid = UnitGUID and UnitGUID("target")
    if not guid or guid == "" then return nil end
    local _, _, _, _, _, npcId = strsplit("-", guid)
    if npcId and npcId ~= "" then
        return tostring(npcId)
    end
    return nil
end

function HarfordLootAPI.GetTargetCreatureId()
    return GetTargetCreatureId()
end

function HarfordLootAPI.GetLootEntries(creatureId, createIfMissing)
    if creatureId == "GLOBAL" then
        return HarfordLootGlobalLootRegistry
    end
    if not creatureId or creatureId == "" then
        return nil
    end
    if createIfMissing then
        HarfordLootLootRegistry[creatureId] = HarfordLootLootRegistry[creatureId] or {}
    end
    return HarfordLootLootRegistry[creatureId]
end

function HarfordLootAPI.HasResolvedLoot(guid)
    return guid ~= nil and HarfordLootTaggedCreatureRegistry[guid] ~= nil
end

function HarfordLootAPI.GetResolvedLoot(guid)
    return guid and HarfordLootTaggedCreatureRegistry[guid] or nil
end

function HarfordLootAPI.SetResolvedLoot(guid, lootTable, syncNow)
    if not guid or guid == "" then
        return false
    end

    HarfordLootTaggedCreatureRegistry[guid] = lootTable or {}

    if syncNow then
        SendLootSync(guid, HarfordLootTaggedCreatureRegistry[guid])
    end

    RefreshLootFrameIfTargetMatches(guid, HarfordLootTaggedCreatureRegistry[guid])
    return true
end

function HarfordLootAPI.ClearResolvedLoot(guid)
    if not guid or guid == "" then
        return false
    end

    HarfordLootTaggedCreatureRegistry[guid] = nil

    local currentGuid = UnitGUID("target")
    if currentGuid and currentGuid == guid and HarfordLootFrame and HarfordLootFrame:IsShown() then
        HarfordLootFrame:Hide()
    end

    return true
end

function HarfordLootAPI.ClearAllResolvedLoot()
    HarfordLootTaggedCreatureRegistry = {}

    if HarfordLootFrame then
        HarfordLootFrame.lootTable = {}
        if HarfordLootFrame:IsShown() then
            HarfordLootFrame:Hide()
        end
    end

    return true
end

function HarfordLootAPI.ClearAllLootData(saveNow)
    HarfordLootLootRegistry = {}
    HarfordLootGlobalLootRegistry = {}
    HarfordLootTaggedCreatureRegistry = {}
    HarfordLootConfigStore = HarfordSync.SaveLootConfigTables(HarfordLootConfigStore, {}, {})

    if HarfordLootFrame and HarfordLootFrame:IsShown() then
        HarfordLootFrame:Hide()
    end

    if saveNow and HarfordLootAPI.SaveConfig then
        HarfordLootAPI.SaveConfig()
    end

    return true
end

local commFrame = CreateFrame("Frame")

SendLootSync = function(guid, lootTable)
    return HarfordSync.SendTaggedLoot(COMM_PREFIX, guid, lootTable)
end

SendLootClearRemote = function(scope, channel, target)
    local payload = "LOOTCLEAR|" .. tostring(scope or "ALL")

    if HarfordSync and HarfordSync.Send then
        HarfordSync.Send(COMM_PREFIX, payload, channel, target)
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(COMM_PREFIX, payload, channel, target)
    else
        SendAddonMessage(COMM_PREFIX, payload, channel, target)
    end

    return true
end

RefreshLootFrameIfTargetMatches = function(guid, lootTable)
    local currentGuid = UnitGUID("target")
    if currentGuid and currentGuid == guid and HarfordLootFrame and HarfordLootFrame:IsShown() then
        HarfordLootFrame.lootTable = lootTable
        HarfordLootFrame_Update()
    end
end

commFrame:RegisterEvent("PLAYER_LOGIN")
commFrame:RegisterEvent("CHAT_MSG_ADDON")
commFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        local loadedFromSync = HarfordLootAPI.LoadConfig and HarfordLootAPI.LoadConfig()
		if loadedFromSync then
			print("|cff00ff00[HarfordLoot]|r Configuración de loot cargada automáticamente desde Sync.")
		end
        if HarfordSync and HarfordSync.RegisterPrefix then
			HarfordSync.RegisterPrefix(COMM_PREFIX)
		elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
			C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
		elseif RegisterAddonMessagePrefix then
			RegisterAddonMessagePrefix(COMM_PREFIX)
		end
        if HarfordSync and HarfordSync.RegisterPrefix then
            HarfordSync.RegisterPrefix(LOOT_CFG_PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(LOOT_CFG_PREFIX)
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, sender = ...
        if sender == UnitName("player") then
            return
        end
		if prefix == COMM_PREFIX then
			if type(message) == "string" and message ~= "" then
				local opcode, arg = strsplit("|", message)

				if opcode == "LOOTCLEAR" then
					local scope = tostring(arg or "ALL")

					if scope == "ALL" or scope == "RESOLVED" then
						HarfordLootAPI.ClearAllResolvedLoot()
					end

					return
				end
			end

			local guid, lootTable = HarfordSync.DeserializeTaggedLootMessage(message)
			if guid and lootTable then
				HarfordLootAPI.SetResolvedLoot(guid, lootTable, false)
			end
		elseif prefix == LOOT_CFG_PREFIX then
			if message and message:find("^LOOTCFG|") then
				local ok = HarfordLootAPI.ApplyConfig(message)
				if ok then
					print("|cff00ff00[HarfordLoot]|r Configuración de loot recibida de " .. (sender or "otro cliente") .. ".")
				end
			end
		end
    end
end)

HarfordLootFrame = HarfordLootFrame or CreateFrame("Frame", "HarfordLootFrame", UIParent, "ButtonFrameTemplate")
HarfordLootFrame:SetFrameStrata("HIGH")
HarfordLootFrame:SetMovable(true)
HarfordLootFrame:EnableMouse(true)
HarfordLootFrame:SetClampedToScreen(true)
HarfordLootFrame:Hide()
HarfordLootFrame:SetPoint("TOPLEFT", 16, -116)
HarfordLootFrame:SetSize(170, 240)
HarfordLootFrame.portrait = HarfordLootFrame:CreateTexture("HarfordLootFramePortrait", "OVERLAY")
HarfordLootFrame.portrait:SetTexture("Interface\\TargetingFrame\\TargetDead")
HarfordLootFrame.portrait:SetSize(58, 58)
HarfordLootFrame.portrait:SetPoint("TOPLEFT", -5, 5)
local titleText = HarfordLootFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
titleText:SetText("Botín")
titleText:SetPoint("CENTER", 12, 108)
local prevButtonText = HarfordLootFrame:CreateFontString("HarfordLootFramePrevText", "ARTWORK", "GameFontNormal")
prevButtonText:SetText("Anterior")
prevButtonText:SetPoint("BOTTOMLEFT", 45, 18)

local nextButtonText = HarfordLootFrame:CreateFontString("HarfordLootFrameNextText", "ARTWORK", "GameFontNormal")
nextButtonText:SetText("Siguiente")
nextButtonText:SetPoint("BOTTOMRIGHT", HarfordLootFrame, "BOTTOMLEFT", 127, 18)
local function LootItem(slot, entry, quantity)
    if not HarfordLootFrame:IsShown() then
        return
    end

    local numLootToShow = 4
    if (HarfordLootFrame.lootTable and #HarfordLootFrame.lootTable > 4) then
        numLootToShow = numLootToShow - 1
    end

    if ((slot > 0) and (slot < (numLootToShow + 1))) then
        local button = _G["HarfordLootButton" .. slot]
        if (button) then
            if HarfordServerActions and HarfordServerActions.GiveItem then
                HarfordServerActions.GiveItem(HarfordLootFrame.lootTable[entry][1], quantity)
            end
            HarfordLootFrame.lootTable[entry][3] = false

			local guid = UnitGUID("target")
			if guid and HarfordLootTaggedCreatureRegistry[guid] ~= nil then
				HarfordLootAPI.SetResolvedLoot(guid, HarfordLootFrame.lootTable, true)
			end

            button:Hide()
        end
    end

    local button
    local allButtonsHidden = 1
    for index = 1, 4 do
        button = _G["HarfordLootButton" .. index]
        if (button:IsShown()) then
            allButtonsHidden = nil
        end
    end

    if (allButtonsHidden and HarfordLootFrameDownButton:IsShown()) then
        HarfordLootFrameDownButton:Click()
    end

    return
end
for i = 1, 4 do
    local lootButton = CreateFrame("ItemButton", "HarfordLootButton" .. i, HarfordLootFrame)
    lootButton:SetHitRectInsets(0, -107, 0, 0)
    lootButton:SetPoint("TOPLEFT", 9, -(68 + (i - 1) * 41))

    lootButton.NameFrame = lootButton:CreateTexture("HarfordLootButton" .. i .. "NameFrame", "ARTWORK")
    lootButton.NameFrame:SetTexture("Interface/QuestFrame/UI-QuestItemNameFrame")
    lootButton.NameFrame:SetSize(130, 62)
    lootButton.NameFrame:SetPoint("LEFT", 30, 0)

    lootButton.Text = lootButton:CreateFontString("HarfordLootButton" .. i .. "Text", "ARTWORK", "GameFontNormal")
    lootButton.Text:SetSize(93, 38)
    lootButton.Text:SetJustifyH("LEFT")
    lootButton.Text:SetPoint("LEFT", lootButton, "RIGHT", 8, 0)

    lootButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.item then
            GameTooltip:SetItemByID(self.item)
        end
        GameTooltip:Show()
        self:SetScript("OnUpdate", function(frame)
            if GameTooltip:IsOwned(frame) and frame.item then
                GameTooltip:SetItemByID(frame.item)
            end
        end)
    end)

    lootButton:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        GameTooltip_Hide()
    end)

    lootButton:SetScript("OnClick", function(self)
        if self.slot then
            LootItem(i, self.slot, self.quantity)
        end
    end)

    lootButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    lootButton.hasItem = 1
end
local scrollUpButton = CreateFrame("Button", "HarfordLootFrameUpButton", HarfordLootFrame)
scrollUpButton:SetSize(32, 32)
scrollUpButton:SetPoint("BOTTOMLEFT", HarfordLootFrame, "BOTTOMLEFT", 8, 6)
scrollUpButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
scrollUpButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
scrollUpButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled")
scrollUpButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
local scrollDownButton = CreateFrame("Button", "HarfordLootFrameDownButton", HarfordLootFrame)
scrollDownButton:SetSize(32, 32)
scrollDownButton:SetPoint("BOTTOMLEFT", HarfordLootFrame, "BOTTOMLEFT", 130, 6)
scrollDownButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
scrollDownButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
scrollDownButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
scrollDownButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
HarfordLootFrame.lootTable = {}
local function MapNineSliceCornerUVs(nineSlice, topLeftRelUV, topRightRelUV, botLeftRelUV, botRightRelUV)
    if (nineSlice) then
        local function MapTextureUV(texture, relU, relV, dirU, dirV)
            if (texture) then
                local cullU = 1.0 - Saturate(relU)
                local cullV = 1.0 - Saturate(relV)
                local startU = cullU * Saturate(dirU)
                local startV = cullV * Saturate(dirV)
                local endU = startU + (1.0 - cullU)
                local endV = startV + (1.0 - cullV)
                texture:SetTexCoord(startU, endU, startV, endV)
                texture:SetWidth(texture:GetWidth() * relU)
                texture:SetHeight(texture:GetHeight() * relV)
            end
        end
        MapTextureUV(nineSlice.TopLeftCorner, topLeftRelUV[1], topLeftRelUV[2], 0, 0)
        MapTextureUV(nineSlice.TopRightCorner, topRightRelUV[1], topRightRelUV[2], 1.0, 0)
        MapTextureUV(nineSlice.BottomLeftCorner, botLeftRelUV[1], botLeftRelUV[2], 0, 1.0)
        MapTextureUV(nineSlice.BottomRightCorner, botRightRelUV[1], botRightRelUV[2], 1.0, 1.0)
    end
end
ButtonFrameTemplate_HideButtonBar(HarfordLootFrame)
MapNineSliceCornerUVs(HarfordLootFrame.NineSlice, {.65, .6}, {.25, .4}, {.55, .4}, {.35, .4})
HarfordLootFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_STARTED_MOVING" then
        if self:IsShown() then
            self:Hide()
        end
        return
    end

    if event == "GET_ITEM_INFO_RECEIVED" then
        if self:IsShown() then
            HarfordLootFrame_Update()
        end
        return
    end

    if event ~= "PLAYER_TARGET_CHANGED" then
        return
    end

    if not UnitExists("target") then
        self.lootTable = {}
        self:Hide()
        return
    end

    if not UnitIsDead("target") then
        self.lootTable = {}
        self:Hide()
        return
    end

    if not IsItemInRange(37727) then
        self.lootTable = {}
        self:Hide()
        return
    end

    if not AuraUtil.FindAuraByName("Loot Room Completion Area", "target") then
        self.lootTable = {}
        self:Hide()
        return
    end

    local guid = UnitGUID("target")
    if not guid or guid == "" then
        self.lootTable = {}
        self:Hide()
        return
    end

    local _, _, _, _, _, id = strsplit("-", guid)
    if not id or id == "" then
        self.lootTable = {}
        self:Hide()
        return
    end

    local taggedCreatures = HarfordLootTaggedCreatureRegistry or {}

    if taggedCreatures[guid] ~= nil then
        self.lootTable = taggedCreatures[guid]
        RefreshLootFrameIfTargetMatches(guid, taggedCreatures[guid])
        self:Show()
        HarfordLootFrame_Update()
        return
    end

    if not HarfordLootLootRegistry[id] then
        self.lootTable = {}
        self:Hide()
        return
    end

    local lootTable = {}

    for i = 1, #HarfordLootLootRegistry[id] do
        local itemID, chance, minAmount, maxAmount =
            HarfordLootLootRegistry[id][i][1],
            HarfordLootLootRegistry[id][i][2],
            HarfordLootLootRegistry[id][i][3],
            HarfordLootLootRegistry[id][i][4]

        if random(100) <= chance then
            local entry = { itemID, random(minAmount, maxAmount), true }
            tinsert(lootTable, entry)
        end
    end

    for i = 1, #HarfordLootGlobalLootRegistry do
        local itemID, chance, minAmount, maxAmount =
            HarfordLootGlobalLootRegistry[i][1],
            HarfordLootGlobalLootRegistry[i][2],
            HarfordLootGlobalLootRegistry[i][3],
            HarfordLootGlobalLootRegistry[i][4]

        if random(100) <= chance then
            local entry = { itemID, random(minAmount, maxAmount), true }
            tinsert(lootTable, entry)
        end
    end

    HarfordLootAPI.SetResolvedLoot(guid, lootTable, true)
    self.lootTable = HarfordLootTaggedCreatureRegistry[guid]
    self:Show()
    HarfordLootFrame_Update()
end)

local function LootSlotHasItem(slot)
    if HarfordLootFrame.lootTable and HarfordLootFrame.lootTable[slot] then
        return HarfordLootFrame.lootTable[slot][3]
    end
    return false
end
HarfordLootFrameDownButton:SetScript("OnClick", function()
    HarfordLootFrame.page = HarfordLootFrame.page + 1
    HarfordLootFrame_Update()
end)
HarfordLootFrameUpButton:SetScript("OnClick", function()
    HarfordLootFrame.page = HarfordLootFrame.page - 1
    HarfordLootFrame_Update()
end)
HarfordLootFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
HarfordLootFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
HarfordLootFrame:RegisterEvent("PLAYER_STARTED_MOVING")
HarfordLootFrame:SetScript("OnShow", function(self)
    if (#self.lootTable == 0) then
        PlaySound(SOUNDKIT.LOOT_WINDOW_OPEN_EMPTY)
    end
    self.page = 1
    HarfordLootFrame_Update()
    if HarfordServerActions and HarfordServerActions.ApplyAura then
        HarfordServerActions.ApplyAura(224063, "self")
    end
end)
HarfordLootFrame:SetScript("OnHide", function(self)
    if HarfordServerActions and HarfordServerActions.RemoveAura then
        HarfordServerActions.RemoveAura(224063, "self")
    end
end)
function HarfordLootFrame_UpdateButton(index)
    local numLootItems = #HarfordLootFrame.lootTable or 0
    local numLootToShow = 4
    local self = HarfordLootFrame

    if (numLootItems > 4) then
        numLootToShow = numLootToShow - 1
    end

    local button = _G["HarfordLootButton" .. index]
    local slot = (numLootToShow * (HarfordLootFrame.page - 1)) + index

    if (slot <= numLootItems) then
        if (LootSlotHasItem(slot) and index <= numLootToShow) then
            local item, quantity = self.lootTable[slot][1], self.lootTable[slot][2]
            local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(item)
            local text = _G["HarfordLootButton" .. index .. "Text"]

            if (itemTexture) then
                local color = ITEM_QUALITY_COLORS[itemQuality]
                SetItemButtonQuality(button, itemQuality, itemLink)
                _G["HarfordLootButton" .. index .. "IconTexture"]:SetTexture(itemTexture)
                text:SetText(itemName)
                SetItemButtonNameFrameVertexColor(button, 0.5, 0.5, 0.5)
                SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0)
                SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0)
                text:SetVertexColor(color.r, color.g, color.b)

                local countString = _G["HarfordLootButton" .. index .. "Count"]
                if (quantity > 1) then
                    countString:SetText(quantity)
                    countString:Show()
                else
                    countString:Hide()
                end

                button.item = item
                button.slot = slot
                button.quality = itemQuality
                button.quantity = quantity
                button:Enable()
            else
				text:SetText("Cargando...")
				_G["HarfordLootButton" .. index .. "IconTexture"]:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0)
				button:Disable()
			end

            button:Show()
        else
            button:Hide()
        end
    else
        button:Hide()
    end
end
function HarfordLootFrame_Update()
    for index = 1, 4 do
        HarfordLootFrame_UpdateButton(index)
    end

    if (HarfordLootFrame.page == 1) then
        HarfordLootFrameUpButton:Hide()
        HarfordLootFramePrevText:Hide()
    else
        HarfordLootFrameUpButton:Show()
        HarfordLootFramePrevText:Show()
    end

    local numItemsPerPage = 4
    if (#HarfordLootFrame.lootTable > 4) then
        numItemsPerPage = numItemsPerPage - 1
    end

    if (HarfordLootFrame.page == ceil(#HarfordLootFrame.lootTable / numItemsPerPage) or #HarfordLootFrame.lootTable == 0) then
        HarfordLootFrameDownButton:Hide()
        HarfordLootFrameNextText:Hide()
    else
        HarfordLootFrameDownButton:Show()
        HarfordLootFrameNextText:Show()
    end
end

local function OnLootMessage(_, _, message)
    if not message or message == "" then
        return false
    end

    if message:find("Command : Additem, itemId = ", 1, true) then
        return true
    end

    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", OnLootMessage)
