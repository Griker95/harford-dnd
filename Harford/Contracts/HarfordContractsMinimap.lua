HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.Minimap = TC.Minimap or {}

local Minimap = TC.Minimap

local HUB_COLUMNS = 6
local HUB_SLOTS = 12
local SLOT_SIZE = 38
local SLOT_GAP = 8

local function HideTooltip()
  GameTooltip:Hide()
end

local function ShowTooltip(owner, title, leftClick, rightClick)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:AddLine(title)
  if leftClick then
    GameTooltip:AddLine(leftClick, 1, 1, 1)
  end
  if rightClick then
    GameTooltip:AddLine(rightClick, 1, 1, 1)
  end
  GameTooltip:Show()
end

local function CreateToolButton(parent, index, tool)
  local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
  button:SetSize(SLOT_SIZE, SLOT_SIZE)

  local col = (index - 1) % HUB_COLUMNS
  local row = math.floor((index - 1) / HUB_COLUMNS)
  button:SetPoint("TOPLEFT", 14 + col * (SLOT_SIZE + SLOT_GAP), -14 - row * (SLOT_SIZE + SLOT_GAP))

  button:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })

  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetSize(28, 28)
  button.icon:SetPoint("CENTER")

  if tool then
    button:SetBackdropBorderColor(1, 0.74, 0.12, 1)
    TC.Util.SetIcon(button.icon, tool.icon)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(_, mouseButton)
      if mouseButton == "RightButton" and tool.onRightClick then
        tool.onRightClick()
      elseif tool.onLeftClick then
        tool.onLeftClick()
      end
      if Minimap.hubFrame then
        Minimap.hubFrame:Hide()
      end
    end)
    button:SetScript("OnEnter", function(self)
      ShowTooltip(self, tool.title, tool.leftHint, tool.rightHint)
    end)
    button:SetScript("OnLeave", HideTooltip)
  else
    button:SetBackdropBorderColor(0.35, 0.35, 0.38, 0.55)
    button.icon:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    button.icon:SetVertexColor(0.25, 0.25, 0.28, 0.5)
    button:SetScript("OnEnter", function(self)
      ShowTooltip(self, "Espacio reservado", "Futuro addon")
    end)
    button:SetScript("OnLeave", HideTooltip)
  end

  return button
end

function Minimap.CreateHub()
  if Minimap.hubFrame then
    return
  end

  local width = 28 + HUB_COLUMNS * SLOT_SIZE + (HUB_COLUMNS - 1) * SLOT_GAP
  local height = 28 + 2 * SLOT_SIZE + SLOT_GAP
  local frame = CreateFrame("Frame", "HarfordContractsHubFrame", UIParent, "BackdropTemplate")
  frame:SetSize(width, height)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.04, 0.04, 0.06, 0.94)
  frame:SetBackdropBorderColor(0.95, 0.73, 0.18, 1)

  if MinimapCluster then
    frame:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -8, -8)
  else
    frame:SetPoint("CENTER")
  end

  frame.tools = {
    {
      title = "Tablon de Contratos",
      icon = TC.icon,
      leftHint = "Click izquierdo: abrir tablon",
      rightHint = "Click derecho: editor DM",
      onLeftClick = function()
        TC.Toggle()
      end,
      onRightClick = function()
        TC.OpenDM()
      end,
    },
  }

  for index = 1, HUB_SLOTS do
    CreateToolButton(frame, index, frame.tools[index])
  end

  frame:Hide()
  Minimap.hubFrame = frame
end

function Minimap.ToggleHub()
  Minimap.CreateHub()
  if Minimap.hubFrame:IsShown() then
    Minimap.hubFrame:Hide()
  else
    Minimap.hubFrame:Show()
  end
end

function Minimap.Initialize()
  if Minimap.initialized then
    return
  end
  Minimap.initialized = true

  local db = TC.GetDB()
  local LibStubRef = LibStub
  local LDB = LibStubRef and LibStubRef("LibDataBroker-1.1", true)
  local DBIcon = LibStubRef and LibStubRef("LibDBIcon-1.0", true)

  if not LDB or not DBIcon then
    TC.Print("LibDBIcon no esta disponible. Usa /harford contratos para abrir el tablon.")
    return
  end

  local launcher = LDB:NewDataObject("HarfordContracts", {
    type = "launcher",
    text = "Harford DnD 5e",
    icon = TC.Util.ResolveIcon(TC.icon),
    OnClick = function()
      Minimap.ToggleHub()
    end,
    OnTooltipShow = function(tooltip)
      tooltip:AddLine("Harford DnD 5e")
      tooltip:AddLine("Click: abrir panel de addons", 1, 1, 1)
    end,
  })

  DBIcon:Register("HarfordContracts", launcher, db.settings.minimap)
  Minimap.DBIcon = DBIcon
end

function Minimap.Refresh()
  local db = TC.GetDB()
  if not Minimap.DBIcon then
    return
  end
  if db.settings.minimap.hide then
    Minimap.DBIcon:Hide("HarfordContracts")
  else
    Minimap.DBIcon:Show("HarfordContracts")
  end
end
