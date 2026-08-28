HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.DM = TC.DM or {}

local DM = TC.DM
local editingContractId
local selectedCategory = "mercenary"
local selectedDifficulty = "yellow"
local selectedStatus = "draft"
local selectedRepFactionId = nil    -- id estable de la faccion de reputacion elegida (o nil)
local selectedRepFactionName = nil  -- nombre visible de esa faccion (para el texto del dropdown)
local currentRewardItems = {}
local currentRewardReps = {}        -- lista de { factionId, faction, amount } (varias reps por mision)
local REP_DEFAULT_GROUP = "Reputaciones Harford"  -- grupo por defecto de facciones sin grupo
local summaryPage = 1
local SUMMARY_ROWS_PER_PAGE = 7
local summarySelectedContractId
local summaryTypeFilter = "all"
local summaryStatusFilter = "all"
local SUMMARY_STATUS_ACTIONS = {
  { label = "Aceptar", status = "accepted" },
  { label = "Prepar.", status = "preparing" },
  { label = "En curso", status = "active" },
  { label = "Completar", status = "completed" },
  { label = "Archivar", status = "archived" },
}

local LABEL_X = 22
local FIELD_X = 150
local FIELD_WIDTH = 430

local function CreateLabel(parent, text)
  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetText(text or "")
  return label
end

local function CreateButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width or 120, height or 24)
  button:SetText(text or "")
  return button
end

local function CreateEditBox(parent, width)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(width or 240, 24)
  box:SetAutoFocus(false)
  return box
end

local function CreateLargeEditBox(parent, width, height)
  local outer = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  outer:SetSize(width or 240, height or 70)
  outer:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  outer:SetBackdropColor(0.01, 0.01, 0.012, 0.88)
  outer:SetBackdropBorderColor(0.55, 0.55, 0.58, 0.8)

  -- Multilinea con scroll y cursor CORRECTOS via InputScrollFrameTemplate, montado EXACTAMENTE como
  -- lo hacen EpsilonLib/SpellCreator en este cliente. CLAVE: hay que fijar el ancho del EditBox
  -- (EditBox:SetWidth) o no funciona el cursor. El template gestiona scroll y seguimiento de cursor.
  local scrollFrame = CreateFrame("ScrollFrame", nil, outer, "InputScrollFrameTemplate")
  if scrollFrame.CharCount then scrollFrame.CharCount:Hide() end
  scrollFrame:SetPoint("TOPLEFT", 8, -8)
  scrollFrame:SetPoint("BOTTOMRIGHT", -8, 8)

  local box = scrollFrame.EditBox
  box:SetWidth((width or 240) - 34)  -- ancho del marco menos insets y hueco de barra (patron addons)
  box:SetFontObject("ChatFontNormal")
  box:SetTextColor(1, 1, 1)
  box:SetAutoFocus(false)
  if box.SetMaxLetters then box:SetMaxLetters(0) end
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  outer.scrollFrame = scrollFrame
  outer.editBox = box
  return outer, box
end

local function SetLargeText(box, text)
  if box then
    box:SetText(text or "")
  end
end

local function GetShareChatChannel()
  if IsInRaid and IsInRaid() then
    return "RAID"
  end
  if IsInGroup and IsInGroup() then
    return "PARTY"
  end
  return "SAY"
end

local function IsTRP3LinkLine(line)
  line = tostring(line or "")
  return string.find(line, "%[TRP3:", 1) ~= nil or string.find(line, "TRP3:", 1, true) ~= nil
end

local function SendTRP3LinksFromText(text)
  local sent = 0
  local channel = GetShareChatChannel()
  for line in string.gmatch(text or "", "([^\n]+)") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and IsTRP3LinkLine(line) then
      SendChatMessage(line, channel)
      sent = sent + 1
    end
  end

  if sent > 0 then
    TC.Print("Links TRP3 enviados al chat: " .. tostring(sent) .. ".")
  else
    TC.Print("No se encontraron links TRP3 en el campo NPCs.")
  end
end

local function GetPageCount(total, perPage)
  local pages = math.ceil((total or 0) / (perPage or 1))
  if pages < 1 then
    pages = 1
  end
  return pages
end

local function GetContractTypeLabel(contract)
  local contractType = contract and TC.Data.GetTypeByKey(contract.category)
  return contractType and contractType.label or "Sin tipo"
end

local function GetSortedSummaryContracts()
  local contracts = {}
  local db = TC.GetDB and TC.GetDB()
  for _, contract in ipairs((db and db.contracts) or {}) do
    local include = true
    if summaryTypeFilter ~= "all" and contract.category ~= summaryTypeFilter then
      include = false
    end
    if summaryStatusFilter == "open" then
      if contract.status == "completed" or contract.status == "archived" or contract.status == "draft" then
        include = false
      end
    elseif summaryStatusFilter == "history" then
      if contract.status ~= "completed" and contract.status ~= "archived" then
        include = false
      end
    elseif summaryStatusFilter ~= "all" and contract.status ~= summaryStatusFilter then
      include = false
    end
    if include then
      table.insert(contracts, contract)
    end
  end

  table.sort(contracts, TC.Data.CompareByDifficulty)

  return contracts
end

local function SetSummaryTypeFilter(value)
  summaryTypeFilter = value or "all"
  summaryPage = 1
  if DM.summaryTypeDropDown then
    local label = "Todos"
    local contractType = TC.Data.GetTypeByKey(summaryTypeFilter)
    if contractType then
      label = contractType.label
    end
    UIDropDownMenu_SetText(DM.summaryTypeDropDown, label)
  end
  DM.RefreshSummary()
end

local function GetSummaryStatusFilterLabel(value)
  if value == "all" then
    return "Todos"
  elseif value == "open" then
    return "Activas"
  elseif value == "history" then
    return "Historial"
  end
  return TC.Data.GetStatusLabel(value)
end

local function RefreshSummaryViewButtons()
  if DM.summaryActiveButton then
    DM.summaryActiveButton:SetEnabled(summaryStatusFilter ~= "open")
  end
  if DM.summaryHistoryButton then
    DM.summaryHistoryButton:SetEnabled(summaryStatusFilter ~= "history")
  end
end

local function SetSummaryStatusFilter(value)
  summaryStatusFilter = value or "all"
  summaryPage = 1
  if DM.summaryStatusDropDown then
    UIDropDownMenu_SetText(DM.summaryStatusDropDown, GetSummaryStatusFilterLabel(summaryStatusFilter))
  end
  RefreshSummaryViewButtons()
  DM.RefreshSummary()
end

local function ClearSummaryRows()
  if not DM.summaryRows then
    DM.summaryRows = {}
  end
  for _, row in ipairs(DM.summaryRows) do
    row:Hide()
  end
end

local function RefreshSummaryActions()
  if not DM.summaryFrame or not DM.summaryStatusButtons then
    return
  end

  local contract = summarySelectedContractId and TC.Data.GetContractById(summarySelectedContractId)
  if contract then
    DM.summaryFrame.selectedText:SetText("Seleccionada: " .. tostring(contract.title or "Contrato"))
  else
    DM.summaryFrame.selectedText:SetText("Selecciona una mision del resumen.")
  end

  for _, button in ipairs(DM.summaryStatusButtons) do
    button:SetEnabled(contract ~= nil and contract.status ~= button.statusKey)
  end
  if DM.summaryDuplicateButton then
    DM.summaryDuplicateButton:SetEnabled(contract ~= nil)
  end
end

local function ObjectivesToText(objectives)
  if type(objectives) ~= "table" then
    return ""
  end
  return table.concat(objectives, "\n")
end

local function TextToObjectives(text)
  local objectives = {}
  for line in string.gmatch(text or "", "([^\n]+)") do
    line = line:gsub("^%s*[-*]?%s*", ""):gsub("%s*$", "")
    if line ~= "" then
      table.insert(objectives, line)
    end
  end
  return objectives
end


local function SaveEditing()
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para editar contratos.")
    return nil
  end
  local contract = editingContractId and TC.Data.GetContractById(editingContractId)
  if not contract then
    contract = TC.Data.AddDraft(selectedCategory or "mercenary")
    if not contract then
      TC.Print("Activa el modo DM con .ph dm on para editar contratos.")
      return nil
    end
    editingContractId = contract.id
  end
  local previousCategory = contract.category
  local previousDifficulty = contract.difficulty
  local title = (DM.titleBox:GetText() or ""):match("^%s*(.-)%s*$")
  if title == "" then
    TC.Print("El contrato necesita un nombre antes de guardarse.")
    return nil
  end
  contract.title = title
  contract.category = selectedCategory or "mercenary"
  contract.difficulty = TC.Data.NormalizeDifficultyKey(selectedDifficulty)
  if previousCategory ~= contract.category or previousDifficulty ~= contract.difficulty then
    contract.sortOrder = nil
  end
  contract.status = selectedStatus or "draft"
  contract.rewardText = DM.rewardBox:GetText()
  contract.rewardXP = tonumber(DM.rewardXPBox:GetText())
  -- Reputaciones (varias): la lista acumulada + si el dropdown tiene una eleccion con cantidad sin
  -- "Añadir" aun, se incluye tambien (comodidad). `rewardRep` (uno) se conserva = primero, para
  -- lectores antiguos; `rewardReps` es la lista canonica.
  local pendingAmount = tonumber(DM.rewardRepAmountBox:GetText())
  if selectedRepFactionId and pendingAmount then
    local found = false
    for _, rr in ipairs(currentRewardReps) do if rr.factionId == selectedRepFactionId then found = true; break end end
    if not found then
      currentRewardReps[#currentRewardReps + 1] = { factionId = selectedRepFactionId, faction = selectedRepFactionName, amount = math.floor(pendingAmount) }
    end
  end
  if #currentRewardReps > 0 then
    contract.rewardReps = {}
    for i, rr in ipairs(currentRewardReps) do
      contract.rewardReps[i] = { factionId = rr.factionId, faction = rr.faction, amount = rr.amount }
    end
    contract.rewardRep = { factionId = currentRewardReps[1].factionId, faction = currentRewardReps[1].faction, amount = currentRewardReps[1].amount }
  else
    contract.rewardReps = nil
    contract.rewardRep = nil
  end
  -- Dinero estructurado (oro/plata/cobre); nil si todo es 0.
  local mg = tonumber(DM.rewardGoldBox:GetText()) or 0
  local ms = tonumber(DM.rewardSilverBox:GetText()) or 0
  local mc = tonumber(DM.rewardCopperBox:GetText()) or 0
  contract.rewardMoney = (mg + ms + mc > 0) and { gold = mg, silver = ms, copper = mc } or nil
  -- NPC de mision de mundo (template id); nil = solo contrato de tablon.
  contract.worldNpc = tonumber(DM.worldNpcBox:GetText())
  contract.rewardItems = TC.Util.CloneRewardItems(currentRewardItems)
  contract.duration = DM.durationBox:GetText()
  contract.players = DM.playersBox:GetText()
  contract.location = DM.locationBox:GetText()
  contract.description = DM.descriptionBox:GetText()
  contract.objectives = TextToObjectives(DM.objectivesBox:GetText())
  contract.privateNotes = DM.privateBox:GetText()
  -- Textos de mision de mundo (vacio = usar defecto). Separados de la Descripcion del tablon.
  contract.pickupText = DM.pickupBox:GetText()
  contract.progressText = DM.progressBox:GetText()
  contract.turnInText = DM.turnInBox:GetText()
  TC.Print("Contrato guardado.")
  TC.Refresh()
  return contract
end

local function GetDuplicateTitle(source)
  local db = TC.GetDB()
  local baseTitle = tostring((source and source.title) or "Contrato")
  local changed = true
  while changed do
    local cleaned = baseTitle:gsub("%s*%(%s*copia%s*%)%s*$", "")
    cleaned = cleaned:gsub("%s+copia%s+%d+%s*$", "")
    changed = cleaned ~= baseTitle
    baseTitle = cleaned
  end
  if baseTitle == "" then
    baseTitle = "Contrato"
  end

  local maxCopy = 1
  local pattern = "^" .. baseTitle:gsub("([^%w])", "%%%1") .. "%s+copia%s+(%d+)$"
  for _, contract in ipairs(db.contracts or {}) do
    local title = tostring(contract.title or "")
    if title == baseTitle then
      maxCopy = math.max(maxCopy, 1)
    else
      local copyNumber = tonumber(string.match(title, pattern))
      if copyNumber then
        maxCopy = math.max(maxCopy, copyNumber)
      end
    end
  end

  return baseTitle .. " copia " .. tostring(maxCopy + 1)
end

local function DuplicateContractById(contractId)
  if not contractId then
    TC.Print("Selecciona un contrato para duplicar.")
    return
  end

  local source = TC.Data.GetContractById(contractId)
  if not source then
    TC.Print("No se encontro el contrato a duplicar.")
    return
  end

  local db = TC.GetDB()
  local duplicate = {
    id = TC.Data.NewContractId(),
    title = GetDuplicateTitle(source),
    category = source.category or "mercenary",
    difficulty = TC.Data.NormalizeDifficultyKey(source.difficulty),
    rewardText = source.rewardText or "",
    rewardXP = source.rewardXP,
    rewardRep = source.rewardRep and { factionId = source.rewardRep.factionId, faction = source.rewardRep.faction, amount = source.rewardRep.amount } or nil,
    rewardReps = (function()
      if type(source.rewardReps) ~= "table" then return nil end
      local out = {}
      for i, rr in ipairs(source.rewardReps) do out[i] = { factionId = rr.factionId, faction = rr.faction, amount = rr.amount } end
      return out
    end)(),
    rewardMoney = source.rewardMoney and { gold = source.rewardMoney.gold, silver = source.rewardMoney.silver, copper = source.rewardMoney.copper } or nil,
    worldNpc = source.worldNpc,
    pickupText = source.pickupText,
    progressText = source.progressText,
    turnInText = source.turnInText,
    rewardItems = TC.Util.CloneRewardItems(source.rewardItems),
    duration = source.duration or "",
    players = source.players or "",
    location = source.location or "",
    status = "draft",
    description = source.description or "",
    objectives = {},
    privateNotes = source.privateNotes or "",
    prep = {
      secretNotes = source.prep and source.prep.secretNotes or "",
      enemies = source.prep and source.prep.enemies or "",
      npcs = source.prep and source.prep.npcs or "",
      success = source.prep and source.prep.success or "",
      failure = source.prep and source.prep.failure or "",
    },
  }
  for _, objective in ipairs(source.objectives or {}) do
    table.insert(duplicate.objectives, objective)
  end
  table.insert(db.contracts, duplicate)
  editingContractId = duplicate.id
  DM.LoadEditingContract()
  TC.Refresh()
  TC.Print("Contrato duplicado como borrador.")
  return duplicate
end

local function DuplicateEditing()
  return DuplicateContractById(editingContractId)
end

local function RefreshRewardItems()
  if DM.rewardItemsText then
    DM.rewardItemsText:SetText(TC.Util.FormatRewardItems(currentRewardItems))
  end
  if not DM.rewardItemRows then
    return
  end
  for index, row in ipairs(DM.rewardItemRows) do
    local item = currentRewardItems[index]
    if item then
      row.text:SetText(string.format("x%s %s", tostring(tonumber(item.quantity) or 1), TC.Util.GetItemName(item.itemId)))
      row.removeButton.itemIndex = index
      row:Show()
    else
      row.removeButton.itemIndex = nil
      row:Hide()
    end
  end
end

local function SetRewardItems(rewardItems)
  currentRewardItems = TC.Util.CloneRewardItems(rewardItems)
  RefreshRewardItems()
end

local function SetCategory(categoryKey)
  selectedCategory = categoryKey or "mercenary"
  local contractType = TC.Data.GetTypeByKey(selectedCategory)
  if DM.categoryDropDown then
    UIDropDownMenu_SetText(DM.categoryDropDown, contractType and contractType.label or selectedCategory)
  end
  if DM.categoryIcon and contractType then
    TC.Util.SetIcon(DM.categoryIcon, contractType.icon)
  end
end

local function SetDifficulty(difficultyKey)
  selectedDifficulty = TC.Data.NormalizeDifficultyKey(difficultyKey)
  local difficulty = TC.Data.GetDifficulty(selectedDifficulty)
  if DM.difficultyDropDown then
    UIDropDownMenu_SetText(DM.difficultyDropDown, difficulty.label)
  end
  if DM.difficultyIcon then
    TC.Util.SetIcon(DM.difficultyIcon, difficulty.icon)
  end
end

local function SetStatus(statusKey)
  selectedStatus = statusKey or "draft"
  if DM.statusDropDown then
    UIDropDownMenu_SetText(DM.statusDropDown, TC.Data.GetStatusLabel(selectedStatus))
  end
end

function DM.SetContractStatus(contractId, statusKey, confirmed)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para cambiar estados.")
    return false
  end
  if not TC.Data.Statuses[statusKey] then
    TC.Print("Estado no valido.")
    return false
  end

  local contract = contractId and TC.Data.GetContractById(contractId)
  if not contract then
    TC.Print("Selecciona una mision para cambiar su estado.")
    return false
  end

  if statusKey == "archived" and not confirmed then
    StaticPopupDialogs.TABLONCONTRATOS_ARCHIVE_CONTRACT = StaticPopupDialogs.TABLONCONTRATOS_ARCHIVE_CONTRACT or {
      text = "Archivar este contrato?\n%s",
      button1 = "Archivar",
      button2 = CANCEL,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
      OnAccept = function(_, data)
        if data and data.contractId then
          DM.SetContractStatus(data.contractId, "archived", true)
        end
      end,
    }
    StaticPopup_Show("TABLONCONTRATOS_ARCHIVE_CONTRACT", contract.title or "Contrato", nil, { contractId = contract.id })
    return false
  end

  contract.status = statusKey
  if editingContractId == contract.id then
    SetStatus(statusKey)
  end

  if TC.Comm and TC.Comm.SyncPublicContracts then
    -- El estado forma parte de la foto autoritativa del DM. Asi archivar una
    -- mision tambien la retira de los clientes, sin dejar restos remotos.
    TC.Comm.SyncPublicContracts(true)
  end

  TC.Print("Estado cambiado: " .. tostring(contract.title) .. " -> " .. TC.Data.GetStatusLabel(statusKey))
  TC.Refresh()
  RefreshSummaryActions()
  return true
end

function DM.ClearEditor()
  DM.Create()
  editingContractId = nil

  local currentCategory = TC.UI and TC.UI.GetSelectedCategory and TC.UI.GetSelectedCategory()
  SetCategory(currentCategory or "mercenary")
  SetDifficulty("yellow")
  SetStatus("draft")

  DM.titleBox:SetText("")
  DM.rewardBox:SetText("")
  DM.rewardXPBox:SetText("")
  -- Reset inline del selector de rep (SetSelectedRepFaction se declara mas abajo).
  selectedRepFactionId = nil
  selectedRepFactionName = nil
  if DM.rewardRepDropDown then UIDropDownMenu_SetText(DM.rewardRepDropDown, "(Ninguna)") end
  DM.rewardRepAmountBox:SetText("")
  currentRewardReps = {}
  if DM.rewardRepsText then DM.rewardRepsText:SetText("|cff808080(sin reputaciones)|r") end
  if DM.rewardGoldBox then DM.rewardGoldBox:SetText("") end
  if DM.rewardSilverBox then DM.rewardSilverBox:SetText("") end
  if DM.rewardCopperBox then DM.rewardCopperBox:SetText("") end
  if DM.worldNpcBox then DM.worldNpcBox:SetText("") end
  SetRewardItems({})
  DM.durationBox:SetText("")
  DM.playersBox:SetText("")
  DM.locationBox:SetText("")
  DM.descriptionBox:SetText("")
  DM.objectivesBox:SetText("")
  DM.privateBox:SetText("")
  if DM.pickupBox then DM.pickupBox:SetText("") end
  if DM.progressBox then DM.progressBox:SetText("") end
  if DM.turnInBox then DM.turnInBox:SetText("") end
end

-- ─── Selector jerarquico de faccion de reputacion (grupo -> subgrupo -> faccion) ───────────────
local function SetSelectedRepFaction(id, name)
  selectedRepFactionId = id
  selectedRepFactionName = name
  if DM.rewardRepDropDown then
    UIDropDownMenu_SetText(DM.rewardRepDropDown, name or "(Ninguna)")
  end
end

local function RepGroupName(faction)
  local g = faction and faction.group
  if not g or g == "" then return REP_DEFAULT_GROUP end
  return g
end

-- Refresca el texto de la lista de reputaciones acumuladas (verde suma / rojo resta).
local function RefreshRewardReps()
  if not DM.rewardRepsText then return end
  if #currentRewardReps == 0 then
    DM.rewardRepsText:SetText("|cff808080(sin reputaciones)|r")
    return
  end
  local parts = {}
  for _, rr in ipairs(currentRewardReps) do
    local amt = tonumber(rr.amount) or 0
    local color = (amt < 0) and "|cffff3333" or "|cff33ff33"
    parts[#parts + 1] = color .. (amt >= 0 and "+" or "") .. amt .. "|r " .. tostring(rr.faction or rr.factionId)
  end
  DM.rewardRepsText:SetText(table.concat(parts, "    "))
end

local function AddRepFactionButton(faction, level)
  local info = UIDropDownMenu_CreateInfo()
  info.text = faction.name
  info.notCheckable = true
  info.func = function() SetSelectedRepFaction(faction.id, faction.name); CloseDropDownMenus() end
  UIDropDownMenu_AddButton(info, level)
end

-- Local: solo lo referencia este fichero (UIDropDownMenu_Initialize recibe la referencia).
-- Era un global accidental.
local function RepFactionDropDownInit(self, level, menuList)
  level = level or 1
  local R = HarfordReputation
  if not (R and R.GetFactions) then return end
  local factions = R.GetFactions(false)

  if level == 1 then
    local none = UIDropDownMenu_CreateInfo()
    none.text = "(Ninguna)"; none.notCheckable = true
    none.func = function() SetSelectedRepFaction(nil, nil); CloseDropDownMenus() end
    UIDropDownMenu_AddButton(none, level)

    local groups = (R.GetGroups and R.GetGroups()) or {}
    if #groups == 0 then  -- sin estructura de grupos: lista plana
      for _, f in ipairs(factions) do AddRepFactionButton(f, level) end
      return
    end
    for _, g in ipairs(groups) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = g.name; info.notCheckable = true; info.hasArrow = true
      info.menuList = "G\1" .. g.name
      UIDropDownMenu_AddButton(info, level)
    end

  elseif type(menuList) == "string" and menuList:sub(1, 2) == "G\1" then
    local groupName = menuList:sub(3)
    local group
    for _, g in ipairs((R.GetGroups and R.GetGroups()) or {}) do
      if g.name == groupName then group = g; break end
    end
    for _, sub in ipairs((group and group.subgroups) or {}) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = sub; info.notCheckable = true; info.hasArrow = true
      info.menuList = "S\1" .. groupName .. "\2" .. sub
      UIDropDownMenu_AddButton(info, level)
    end
    for _, f in ipairs(factions) do
      if RepGroupName(f) == groupName and (f.subgroup or "") == "" then AddRepFactionButton(f, level) end
    end

  elseif type(menuList) == "string" and menuList:sub(1, 2) == "S\1" then
    local groupName, sub = menuList:sub(3):match("^(.-)\2(.*)$")
    for _, f in ipairs(factions) do
      if RepGroupName(f) == groupName and (f.subgroup or "") == sub then AddRepFactionButton(f, level) end
    end
  end
end

function DM.Create()
  if DM.frame then
    return
  end

  local frame = CreateFrame("Frame", "HarfordContractsDMFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(760, 980)  -- Recompensas unificadas arriba; info publica, NPC y notas debajo
  frame:SetPoint("CENTER", 40, -20)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(200)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetScript("OnHide", function()
    if not DM.suppressClearOnHide then
      DM.ClearEditor()
    end
  end)
  DM.frame = frame
  DM.suppressClearOnHide = true
  frame:Hide()
  DM.suppressClearOnHide = false

  local blocker = frame:CreateTexture(nil, "BACKGROUND")
  blocker:SetAllPoints(frame)
  blocker:SetColorTexture(0.02, 0.02, 0.025, 0.96)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.title:SetPoint("TOPLEFT", 16, -5)
  frame.title:SetText("Editor DM - Tablon de Contratos")

  local newButton = CreateButton(frame, "Nuevo contrato", 130, 24)
  newButton:SetPoint("TOPLEFT", 18, -42)
  newButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para crear contratos.")
      return
    end
    DM.ClearEditor()
    TC.Print("Formulario limpio para nuevo contrato.")
  end)

  local saveButton = CreateButton(frame, "Guardar", 90, 24)
  saveButton:SetPoint("LEFT", newButton, "RIGHT", 8, 0)
  saveButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para guardar.")
      return
    end
    SaveEditing()
  end)

  local publishButton = CreateButton(frame, "Publicar", 90, 24)
  publishButton:SetPoint("LEFT", saveButton, "RIGHT", 8, 0)
  publishButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para publicar.")
      return
    end
    local contract = SaveEditing()
    if contract then
      contract.status = "available"
      SetStatus("available")
      TC.Print("Contrato publicado: " .. tostring(contract.title or "Contrato"))
      TC.SetSyncStatus("Pendiente: publicar " .. tostring(contract.title or "contrato"))
      if TC.Comm and TC.Comm.PublishContract then
        TC.Comm.PublishContract(contract)
      end
      TC.Refresh()
    end
  end)

  local duplicateButton = CreateButton(frame, "Duplicar", 90, 24)
  duplicateButton:SetPoint("LEFT", publishButton, "RIGHT", 8, 0)
  duplicateButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para duplicar.")
      return
    end
    DuplicateEditing()
  end)

  local deleteButton = CreateButton(frame, "Borrar", 90, 24)
  deleteButton:SetPoint("LEFT", duplicateButton, "RIGHT", 8, 0)
  deleteButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para borrar.")
      return
    end
    if not editingContractId then
      TC.Print("No hay contrato seleccionado.")
      return
    end
    local contract = TC.Data.GetContractById(editingContractId)
    StaticPopupDialogs.TABLONCONTRATOS_DELETE_CONTRACT = StaticPopupDialogs.TABLONCONTRATOS_DELETE_CONTRACT or {
      text = "Borrar este contrato?\n%s",
      button1 = "Borrar",
      button2 = CANCEL,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
      OnAccept = function(_, data)
        if not data or not data.contractId then
          return
        end
        if TC.Data.DeleteContract(data.contractId) then
          if TC.Comm and TC.Comm.SyncPublicContracts then
            TC.Comm.SyncPublicContracts(true)
          end
          DM.ClearEditor()
          if TC.UI and TC.UI.SelectContract then
            TC.UI.SelectContract(nil)
          else
            TC.Refresh()
          end
          TC.Print("Contrato borrado.")
        end
      end,
    }
    StaticPopup_Show("TABLONCONTRATOS_DELETE_CONTRACT", contract and contract.title or "Contrato", nil, { contractId = editingContractId })
  end)

  local syncButton = CreateButton(frame, "Sincronizar", 110, 24)
  syncButton:SetPoint("LEFT", deleteButton, "RIGHT", 8, 0)
  syncButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para sincronizar.")
      return
    end
    if TC.Comm and TC.Comm.SyncPublicContracts then
      TC.Comm.SyncPublicContracts()
    else
      TC.Print("La sincronizacion no esta disponible.")
    end
  end)

  local basicSection = CreateLabel(frame, "Datos basicos")
  basicSection:SetPoint("TOPLEFT", LABEL_X, -72)

  local nameLabel = CreateLabel(frame, "Nombre")
  nameLabel:SetPoint("TOPLEFT", LABEL_X, -100)

  DM.titleBox = CreateEditBox(frame, 520)
  DM.titleBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -92)

  local categoryLabel = CreateLabel(frame, "Tipo")
  categoryLabel:SetPoint("TOPLEFT", LABEL_X, -140)

  DM.categoryIcon = frame:CreateTexture(nil, "ARTWORK")
  DM.categoryIcon:SetSize(24, 24)
  DM.categoryIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -132)

  DM.categoryDropDown = CreateFrame("Frame", "HarfordContractsDMCategoryDropDown", frame, "UIDropDownMenuTemplate")
  DM.categoryDropDown:SetPoint("LEFT", DM.categoryIcon, "RIGHT", -10, -2)
  UIDropDownMenu_SetWidth(DM.categoryDropDown, 140)
  UIDropDownMenu_Initialize(DM.categoryDropDown, function(_, level)
    if level ~= 1 then
      return
    end
    for _, contractType in ipairs(TC.Data.ContractTypes) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = contractType.label
      info.arg1 = contractType.key
      info.func = function(_, value)
        SetCategory(value)
      end
      info.checked = selectedCategory == contractType.key
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local difficultyLabel = CreateLabel(frame, "Dificultad")
  difficultyLabel:SetPoint("TOPLEFT", 360, -140)

  DM.difficultyIcon = frame:CreateTexture(nil, "ARTWORK")
  DM.difficultyIcon:SetSize(24, 24)
  DM.difficultyIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 460, -132)

  DM.difficultyDropDown = CreateFrame("Frame", "HarfordContractsDMDifficultyDropDown", frame, "UIDropDownMenuTemplate")
  DM.difficultyDropDown:SetPoint("LEFT", DM.difficultyIcon, "RIGHT", -10, -2)
  UIDropDownMenu_SetWidth(DM.difficultyDropDown, 120)
  UIDropDownMenu_Initialize(DM.difficultyDropDown, function(_, level)
    if level ~= 1 then
      return
    end
    for _, difficultyKey in ipairs(TC.Data.DifficultyOrder) do
      local difficulty = TC.Data.GetDifficulty(difficultyKey)
      local info = UIDropDownMenu_CreateInfo()
      info.text = difficulty.label
      info.tooltipTitle = difficulty.label
      info.tooltipText = difficulty.description
      info.arg1 = difficultyKey
      info.func = function(_, value)
        SetDifficulty(value)
      end
      info.checked = selectedDifficulty == difficultyKey
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local statusLabel = CreateLabel(frame, "Estado")
  statusLabel:SetPoint("TOPLEFT", LABEL_X, -180)

  DM.statusDropDown = CreateFrame("Frame", "HarfordContractsDMStatusDropDown", frame, "UIDropDownMenuTemplate")
  DM.statusDropDown:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X - 16, -172)
  UIDropDownMenu_SetWidth(DM.statusDropDown, 160)
  UIDropDownMenu_Initialize(DM.statusDropDown, function(_, level)
    if level ~= 1 then
      return
    end
    for _, statusKey in ipairs(TC.Data.StatusOrder) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = TC.Data.GetStatusLabel(statusKey)
      info.arg1 = statusKey
      info.func = function(_, value)
        SetStatus(value)
      end
      info.checked = selectedStatus == statusKey
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local rewardsSection = CreateLabel(frame, "Recompensas")
  rewardsSection:SetPoint("TOPLEFT", LABEL_X, -222)

  local labels = {
    { key = "rewardBox", label = "Recompensa", y = -250 },
    { key = "durationBox", label = "Duracion", y = -514 },
    { key = "playersBox", label = "Jugadores", y = -554 },
    { key = "locationBox", label = "Localizacion", y = -594 },
  }

  for _, row in ipairs(labels) do
    local label = CreateLabel(frame, row.label)
    label:SetPoint("TOPLEFT", LABEL_X, row.y)
    local box = CreateEditBox(frame, 520)
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, row.y + 8)
    DM[row.key] = box
  end

  -- ── Dinero (oro/plata/cobre): parte de la recompensa ──
  local moneyLabel = CreateLabel(frame, "Dinero")
  moneyLabel:SetPoint("TOPLEFT", LABEL_X, -282)
  DM.rewardGoldBox = CreateEditBox(frame, 54)
  DM.rewardGoldBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -274)
  DM.rewardGoldBox:SetNumeric(true)
  local goldTag = CreateLabel(frame, "oro"); goldTag:SetPoint("LEFT", DM.rewardGoldBox, "RIGHT", 4, 0)
  DM.rewardSilverBox = CreateEditBox(frame, 54)
  DM.rewardSilverBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 110, -274)
  DM.rewardSilverBox:SetNumeric(true)
  local silverTag = CreateLabel(frame, "plata"); silverTag:SetPoint("LEFT", DM.rewardSilverBox, "RIGHT", 4, 0)
  DM.rewardCopperBox = CreateEditBox(frame, 54)
  DM.rewardCopperBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 240, -274)
  DM.rewardCopperBox:SetNumeric(true)
  local copperTag = CreateLabel(frame, "cobre"); copperTag:SetPoint("LEFT", DM.rewardCopperBox, "RIGHT", 4, 0)

  -- ── XP de raid + reputaciones (compartidas: cada jugador cobra su parte una vez) ──
  local xpLabel = CreateLabel(frame, "XP raid")
  xpLabel:SetPoint("TOPLEFT", LABEL_X, -316)
  DM.rewardXPBox = CreateEditBox(frame, 60)
  DM.rewardXPBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -308)
  DM.rewardXPBox:SetNumeric(true)

  local repLabel = CreateLabel(frame, "Rep")
  repLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 76, -316)
  -- Selector JERARQUICO de faccion (grupo -> subgrupo -> faccion) en vez de texto libre.
  DM.rewardRepDropDown = CreateFrame("Frame", "HarfordContractsDMRepDropDown", frame, "UIDropDownMenuTemplate")
  DM.rewardRepDropDown:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 100, -312)
  UIDropDownMenu_SetWidth(DM.rewardRepDropDown, 200)
  UIDropDownMenu_Initialize(DM.rewardRepDropDown, RepFactionDropDownInit)
  UIDropDownMenu_SetText(DM.rewardRepDropDown, "(Ninguna)")

  DM.rewardRepAmountBox = CreateEditBox(frame, 58)
  DM.rewardRepAmountBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 360, -308)
  -- SIN SetNumeric: hay que permitir el signo `-` para reputacion NEGATIVA (quita rep). Se valida
  -- con tonumber al guardar/añadir (acepta negativos).

  -- Boton para ACUMULAR varias reputaciones distintas en la misma mision (patron de los items).
  local addRepButton = CreateButton(frame, "Anadir rep", 90, 22)
  addRepButton:SetPoint("LEFT", DM.rewardRepAmountBox, "RIGHT", 8, 0)
  addRepButton:SetScript("OnClick", function()
    local amount = tonumber(DM.rewardRepAmountBox:GetText())
    if not selectedRepFactionId or not amount then
      TC.Print("Elige una faccion en el desplegable y escribe una cantidad (puede ser negativa).")
      return
    end
    -- Reemplaza si ya existe esa faccion en la lista (no duplicar); si no, añade.
    local replaced = false
    for _, rr in ipairs(currentRewardReps) do
      if rr.factionId == selectedRepFactionId then rr.amount = math.floor(amount); rr.faction = selectedRepFactionName; replaced = true; break end
    end
    if not replaced then
      currentRewardReps[#currentRewardReps + 1] = { factionId = selectedRepFactionId, faction = selectedRepFactionName, amount = math.floor(amount) }
    end
    SetSelectedRepFaction(nil, nil)
    DM.rewardRepAmountBox:SetText("")
    RefreshRewardReps()
  end)
  local clearRepButton = CreateButton(frame, "Limpiar", 70, 22)
  clearRepButton:SetPoint("LEFT", addRepButton, "RIGHT", 6, 0)
  clearRepButton:SetScript("OnClick", function() currentRewardReps = {}; RefreshRewardReps() end)

  DM.rewardRepsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  DM.rewardRepsText:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -346)
  DM.rewardRepsText:SetWidth(560)
  DM.rewardRepsText:SetJustifyH("LEFT")

  -- ── Mision de mundo (NPC): al fondo, en su propia seccion (no es una recompensa) ──
  local worldSection = CreateLabel(frame, "Mision de mundo")
  worldSection:SetPoint("TOPLEFT", LABEL_X, -806)
  local worldLabel = CreateLabel(frame, "NPC mundo")
  worldLabel:SetPoint("TOPLEFT", LABEL_X, -834)
  DM.worldNpcBox = CreateEditBox(frame, 110)
  DM.worldNpcBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -826)
  DM.worldNpcBox:SetNumeric(true)
  local worldTargetButton = CreateButton(frame, "Usar target", 96, 24)
  worldTargetButton:SetPoint("LEFT", DM.worldNpcBox, "RIGHT", 8, 0)
  worldTargetButton:SetScript("OnClick", function()
    local tid = HarfordWorldQuests and HarfordWorldQuests.GetNpcTemplateId and HarfordWorldQuests.GetNpcTemplateId("target")
    if tid then DM.worldNpcBox:SetText(tostring(tid)) else TC.Print("Targetea un NPC (criatura) para tomar su template id.") end
  end)
  local worldTextButton = CreateButton(frame, "Textos...", 74, 24)
  worldTextButton:SetPoint("LEFT", worldTargetButton, "RIGHT", 8, 0)
  worldTextButton:SetScript("OnClick", function()
    if DM.wqTextFrame then DM.wqTextFrame:SetShown(not DM.wqTextFrame:IsShown()) end
  end)
  local worldHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  worldHint:SetPoint("TOPLEFT", DM.worldNpcBox, "BOTTOMLEFT", 0, -4)
  worldHint:SetWidth(500); worldHint:SetJustifyH("LEFT")
  worldHint:SetText("Con NPC = mision de mundo. 'Textos...' edita lo que dice el NPC (dar / en proceso / entregar).")

  local itemLabel = CreateLabel(frame, "Objeto")
  itemLabel:SetPoint("TOPLEFT", LABEL_X, -378)

  DM.itemIdBox = CreateEditBox(frame, 110)
  DM.itemIdBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -370)
  DM.itemIdBox:SetNumeric(true)

  local quantityLabel = CreateLabel(frame, "Cantidad")
  quantityLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 132, -378)

  DM.itemQuantityBox = CreateEditBox(frame, 58)
  DM.itemQuantityBox:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X + 202, -370)
  DM.itemQuantityBox:SetNumeric(true)
  DM.itemQuantityBox:SetText("1")

  local addItemButton = CreateButton(frame, "Anadir", 76, 24)
  addItemButton:SetPoint("LEFT", DM.itemQuantityBox, "RIGHT", 8, 0)
  addItemButton:SetScript("OnClick", function()
    local itemId = tonumber(DM.itemIdBox:GetText())
    local quantity = tonumber(DM.itemQuantityBox:GetText()) or 1
    if not itemId then
      TC.Print("Escribe un itemID valido.")
      return
    end
    table.insert(currentRewardItems, { itemId = itemId, quantity = math.max(1, quantity) })
    DM.itemIdBox:SetText("")
    DM.itemQuantityBox:SetText("1")
    RefreshRewardItems()
  end)

  local clearItemsButton = CreateButton(frame, "Limpiar", 76, 24)
  clearItemsButton:SetPoint("LEFT", addItemButton, "RIGHT", 8, 0)
  clearItemsButton:SetScript("OnClick", function()
    SetRewardItems({})
  end)

  local itemListLabel = CreateLabel(frame, "Objetos")
  itemListLabel:SetPoint("TOPLEFT", LABEL_X, -410)

  DM.rewardItemsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  DM.rewardItemsText:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -408)
  DM.rewardItemsText:SetWidth(520)
  DM.rewardItemsText:SetHeight(54)
  DM.rewardItemsText:SetJustifyH("LEFT")
  DM.rewardItemsText:SetJustifyV("TOP")

  DM.rewardItemsPanel = CreateFrame("Frame", nil, frame)
  DM.rewardItemsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -402)
  DM.rewardItemsPanel:SetSize(520, 72)
  DM.rewardItemRows = {}
  for index = 1, 5 do
    local row = CreateFrame("Frame", nil, DM.rewardItemsPanel)
    row:SetSize(520, 14)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 14))
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 0, 0)
    row.text:SetWidth(400)
    row.text:SetJustifyH("LEFT")
    row.removeButton = CreateButton(row, "Quitar", 70, 16)
    row.removeButton:SetPoint("RIGHT", 0, 0)
    row.removeButton:SetScript("OnClick", function(self)
      if self.itemIndex and currentRewardItems[self.itemIndex] then
        table.remove(currentRewardItems, self.itemIndex)
        RefreshRewardItems()
      end
    end)
    row:Hide()
    DM.rewardItemRows[index] = row
  end
  DM.rewardItemsText:Hide()

  local publicSection = CreateLabel(frame, "Informacion publica")
  publicSection:SetPoint("TOPLEFT", LABEL_X, -486)

  local descriptionLabel = CreateLabel(frame, "Descripcion")
  descriptionLabel:SetPoint("TOPLEFT", LABEL_X, -626)
  DM.descriptionOuter, DM.descriptionBox = CreateLargeEditBox(frame, 520, 86)
  DM.descriptionOuter:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -618)

  local objectivesLabel = CreateLabel(frame, "Objetivos")
  objectivesLabel:SetPoint("TOPLEFT", LABEL_X, -732)
  DM.objectivesOuter, DM.objectivesBox = CreateLargeEditBox(frame, 520, 64)
  DM.objectivesOuter:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -724)

  local dmSection = CreateLabel(frame, "Preparacion / Notas DM")
  dmSection:SetPoint("TOPLEFT", LABEL_X, -870)

  local privateLabel = CreateLabel(frame, "Notas DM")
  privateLabel:SetPoint("TOPLEFT", LABEL_X, -898)
  DM.privateOuter, DM.privateBox = CreateLargeEditBox(frame, 520, 54)
  DM.privateOuter:SetPoint("TOPLEFT", frame, "TOPLEFT", FIELD_X, -890)

  -- Textos de MISION DE MUNDO en VENTANA APARTE (el editor ya es grande): NPC al dar, en proceso y
  -- al entregar. Distintos de la Descripcion (que es el texto del tablon/registro). Las cajas viven
  -- aqui pero el save/load/reset las lee igual (DM.pickupBox/progressBox/turnInBox).
  local wqFrame = CreateFrame("Frame", "HarfordContractsWorldTextFrame", UIParent, "BasicFrameTemplate")
  wqFrame:SetSize(560, 296)
  wqFrame:SetPoint("CENTER")
  wqFrame:SetFrameStrata("FULLSCREEN_DIALOG")
  wqFrame:SetMovable(true); wqFrame:EnableMouse(true); wqFrame:RegisterForDrag("LeftButton")
  wqFrame:SetScript("OnDragStart", wqFrame.StartMoving); wqFrame:SetScript("OnDragStop", wqFrame.StopMovingOrSizing)
  if wqFrame.TitleText then wqFrame.TitleText:SetText("Textos de mision de mundo") end
  wqFrame:Hide()
  DM.wqTextFrame = wqFrame
  local pickupLabel = CreateLabel(wqFrame, "NPC al dar la mision")
  pickupLabel:SetPoint("TOPLEFT", 16, -32)
  DM.pickupOuter, DM.pickupBox = CreateLargeEditBox(wqFrame, 524, 44)
  DM.pickupOuter:SetPoint("TOPLEFT", 16, -48)
  local progressLabel = CreateLabel(wqFrame, "Mision en proceso")
  progressLabel:SetPoint("TOPLEFT", 16, -110)
  DM.progressOuter, DM.progressBox = CreateLargeEditBox(wqFrame, 524, 44)
  DM.progressOuter:SetPoint("TOPLEFT", 16, -126)
  local turnInLabel = CreateLabel(wqFrame, "Al entregar la mision")
  turnInLabel:SetPoint("TOPLEFT", 16, -188)
  DM.turnInOuter, DM.turnInBox = CreateLargeEditBox(wqFrame, 524, 44)
  DM.turnInOuter:SetPoint("TOPLEFT", 16, -204)

  DM.help = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  DM.help:SetPoint("BOTTOMLEFT", 20, 8)
  DM.help:SetWidth(660)
  DM.help:SetJustifyH("LEFT")
  DM.help:SetText("Un objetivo por linea. Contador: anade *N (ej: Recoge polvora *50). Contar objetos del inventario: anade #itemID (ej: Recoge polvora *50 #14026825).")

  DM.frame = frame
end

local function SavePrep()
  local contract = DM.prepContractId and TC.Data.GetContractById(DM.prepContractId)
  if not contract then
    TC.Print("No hay contrato seleccionado para preparar.")
    return
  end

  contract.prep = contract.prep or {}
  contract.prep.secretNotes = DM.prepSecretBox:GetText()
  contract.prep.enemies = DM.prepEnemiesBox:GetText()
  contract.prep.npcs = DM.prepNpcsBox:GetText()
  contract.prep.success = DM.prepSuccessBox:GetText()
  contract.prep.failure = DM.prepFailureBox:GetText()
  TC.Print("Preparacion DM guardada.")
end

function DM.CreatePrep()
  if DM.prepFrame then
    return
  end

  local frame = CreateFrame("Frame", "HarfordContractsPrepFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(680, 680)
  frame:SetPoint("CENTER", 120, -10)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(230)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  local blocker = frame:CreateTexture(nil, "BACKGROUND")
  blocker:SetAllPoints(frame)
  blocker:SetColorTexture(0.02, 0.02, 0.025, 0.98)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.title:SetPoint("TOPLEFT", 16, -5)
  frame.title:SetText("Preparacion DM - Tablon de Contratos")

  frame.contractTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.contractTitle:SetPoint("TOPLEFT", 22, -44)
  frame.contractTitle:SetWidth(620)
  frame.contractTitle:SetJustifyH("LEFT")
  frame.contractTitle:SetText("Contrato")

  local saveButton = CreateButton(frame, "Guardar", 96, 24)
  saveButton:SetPoint("TOPRIGHT", -24, -40)
  saveButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para guardar preparacion.")
      return
    end
    SavePrep()
  end)

  local sendTRPButton = CreateButton(frame, "Enviar links TRP3", 140, 24)
  sendTRPButton:SetPoint("RIGHT", saveButton, "LEFT", -8, 0)
  sendTRPButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para enviar links TRP3.")
      return
    end
    SavePrep()
    SendTRP3LinksFromText(DM.prepNpcsBox:GetText())
  end)

  local fields = {
    { key = "prepSecretBox", label = "Notas secretas", y = -86, h = 82 },
    { key = "prepEnemiesBox", label = "Enemigos", y = -184, h = 82 },
    { key = "prepNpcsBox", label = "NPCs / TRP3", y = -282, h = 74 },
    { key = "prepSuccessBox", label = "Si ganan", y = -402, h = 74 },
    { key = "prepFailureBox", label = "Si fallan", y = -500, h = 74 },
  }

  for _, field in ipairs(fields) do
    local label = CreateLabel(frame, field.label)
    label:SetPoint("TOPLEFT", 24, field.y)
    local outer, box = CreateLargeEditBox(frame, 490, field.h)
    outer:SetPoint("TOPLEFT", frame, "TOPLEFT", 150, field.y + 8)
    DM[field.key .. "Outer"] = outer
    DM[field.key] = box
  end

  frame.trpHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.trpHelp:SetPoint("TOPLEFT", DM.prepNpcsBoxOuter, "BOTTOMLEFT", 4, -4)
  frame.trpHelp:SetWidth(490)
  frame.trpHelp:SetJustifyH("LEFT")
  frame.trpHelp:SetText("Pega aqui enlaces importables de companero TRP3 con Shift+Click. El boton envia esos links al chat.")

  frame.help = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.help:SetPoint("BOTTOMLEFT", 22, 18)
  frame.help:SetWidth(620)
  frame.help:SetJustifyH("LEFT")
  frame.help:SetText("Privado DM: estos datos no se muestran a jugadores ni se envian en la sincronizacion publica.")

  DM.prepFrame = frame
end

function DM.OpenPrepForContract(contractId)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para preparar misiones.")
    return
  end

  local contract = contractId and TC.Data.GetContractById(contractId)
  if not contract then
    TC.Print("Selecciona una mision para preparar.")
    return
  end

  DM.CreatePrep()
  DM.prepContractId = contractId
  contract.prep = contract.prep or {}
  DM.prepFrame.contractTitle:SetText(contract.title or "Contrato")
  SetLargeText(DM.prepSecretBox, contract.prep.secretNotes)
  SetLargeText(DM.prepEnemiesBox, contract.prep.enemies)
  SetLargeText(DM.prepNpcsBox, contract.prep.npcs)
  SetLargeText(DM.prepSuccessBox, contract.prep.success)
  SetLargeText(DM.prepFailureBox, contract.prep.failure)
  DM.prepFrame:Show()
  DM.prepFrame:Raise()
end


function DM.CreateSummary()
  if DM.summaryFrame then
    return
  end

  local frame = CreateFrame("Frame", "HarfordContractsSummaryFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(760, 620)
  frame:SetPoint("CENTER", 70, -20)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(240)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  local blocker = frame:CreateTexture(nil, "BACKGROUND")
  blocker:SetAllPoints(frame)
  blocker:SetColorTexture(0.02, 0.02, 0.025, 0.98)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.title:SetPoint("TOPLEFT", 16, -5)
  frame.title:SetText("Resumen DM - Tablon de Contratos")

  local refreshButton = CreateButton(frame, "Actualizar", 96, 24)
  refreshButton:SetPoint("TOPRIGHT", -24, -40)
  refreshButton:SetScript("OnClick", function()
    DM.RefreshSummary()
  end)

  frame.totalText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.totalText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -104)
  frame.totalText:SetWidth(180)
  frame.totalText:SetJustifyH("RIGHT")

  frame.syncStatusText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.syncStatusText:SetPoint("TOPRIGHT", refreshButton, "BOTTOMRIGHT", 0, -4)
  frame.syncStatusText:SetWidth(260)
  frame.syncStatusText:SetJustifyH("RIGHT")
  frame.syncStatusText:SetText(TC.GetSyncStatus())

  local typeLabel = CreateLabel(frame, "Tipo")
  typeLabel:SetPoint("TOPLEFT", 24, -76)
  DM.summaryTypeDropDown = CreateFrame("Frame", "HarfordContractsSummaryTypeDropDown", frame, "UIDropDownMenuTemplate")
  DM.summaryTypeDropDown:SetPoint("TOPLEFT", frame, "TOPLEFT", 52, -68)
  UIDropDownMenu_SetWidth(DM.summaryTypeDropDown, 120)
  UIDropDownMenu_Initialize(DM.summaryTypeDropDown, function(_, level)
    if level ~= 1 then
      return
    end
    local allInfo = UIDropDownMenu_CreateInfo()
    allInfo.text = "Todos"
    allInfo.arg1 = "all"
    allInfo.func = function(_, value)
      SetSummaryTypeFilter(value)
    end
    allInfo.checked = summaryTypeFilter == "all"
    UIDropDownMenu_AddButton(allInfo, level)
    for _, contractType in ipairs(TC.Data.ContractTypes) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = contractType.label
      info.arg1 = contractType.key
      info.func = function(_, value)
        SetSummaryTypeFilter(value)
      end
      info.checked = summaryTypeFilter == contractType.key
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local statusLabel = CreateLabel(frame, "Estado")
  statusLabel:SetPoint("TOPLEFT", 224, -76)
  DM.summaryStatusDropDown = CreateFrame("Frame", "HarfordContractsSummaryStatusDropDown", frame, "UIDropDownMenuTemplate")
  DM.summaryStatusDropDown:SetPoint("TOPLEFT", frame, "TOPLEFT", 270, -68)
  UIDropDownMenu_SetWidth(DM.summaryStatusDropDown, 130)
  UIDropDownMenu_Initialize(DM.summaryStatusDropDown, function(_, level)
    if level ~= 1 then
      return
    end
    local options = {
      { text = "Todos", value = "all" },
      { text = "Activas", value = "open" },
      { text = "Historial", value = "history" },
      { text = TC.Data.GetStatusLabel("completed"), value = "completed" },
      { text = TC.Data.GetStatusLabel("archived"), value = "archived" },
      { text = TC.Data.GetStatusLabel("available"), value = "available" },
      { text = TC.Data.GetStatusLabel("accepted"), value = "accepted" },
      { text = TC.Data.GetStatusLabel("preparing"), value = "preparing" },
      { text = TC.Data.GetStatusLabel("active"), value = "active" },
      { text = TC.Data.GetStatusLabel("draft"), value = "draft" },
    }
    for _, option in ipairs(options) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = option.text
      info.arg1 = option.value
      info.func = function(_, value)
        SetSummaryStatusFilter(value)
      end
      info.checked = summaryStatusFilter == option.value
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local viewLabel = CreateLabel(frame, "Vista")
  viewLabel:SetPoint("TOPLEFT", 24, -108)

  DM.summaryActiveButton = CreateButton(frame, "Activas", 86, 22)
  DM.summaryActiveButton:SetPoint("TOPLEFT", 70, -104)
  DM.summaryActiveButton:SetScript("OnClick", function()
    SetSummaryStatusFilter("open")
  end)

  DM.summaryHistoryButton = CreateButton(frame, "Historial", 90, 22)
  DM.summaryHistoryButton:SetPoint("LEFT", DM.summaryActiveButton, "RIGHT", 8, 0)
  DM.summaryHistoryButton:SetScript("OnClick", function()
    SetSummaryStatusFilter("history")
  end)

  local headers = {
    { text = "Contrato", x = 26, width = 290 },
    { text = "Tipo", x = 330, width = 96 },
    { text = "Estado", x = 438, width = 96 },
  }

  for _, header in ipairs(headers) do
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", header.x, -132)
    label:SetWidth(header.width)
    label:SetJustifyH("LEFT")
    label:SetText(header.text)
  end

  frame.rowsPanel = CreateFrame("Frame", nil, frame)
  frame.rowsPanel:SetPoint("TOPLEFT", 18, -152)
  frame.rowsPanel:SetSize(720, 360)

  frame.prevPageButton = CreateButton(frame, "<", 28, 20)
  frame.prevPageButton:SetPoint("BOTTOMLEFT", 24, 54)
  frame.prevPageButton:SetScript("OnClick", function()
    if summaryPage > 1 then
      summaryPage = summaryPage - 1
      DM.RefreshSummary()
    end
  end)

  frame.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.pageText:SetPoint("LEFT", frame.prevPageButton, "RIGHT", 6, 0)
  frame.pageText:SetWidth(24)
  frame.pageText:SetJustifyH("CENTER")

  frame.nextPageButton = CreateButton(frame, ">", 28, 20)
  frame.nextPageButton:SetPoint("LEFT", frame.pageText, "RIGHT", 6, 0)
  frame.nextPageButton:SetScript("OnClick", function()
    local total = #GetSortedSummaryContracts()
    local pageCount = GetPageCount(total, SUMMARY_ROWS_PER_PAGE)
    if summaryPage < pageCount then
      summaryPage = summaryPage + 1
      DM.RefreshSummary()
    end
  end)

  frame.selectedText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.selectedText:SetPoint("BOTTOMLEFT", 190, 54)
  frame.selectedText:SetWidth(330)
  frame.selectedText:SetJustifyH("LEFT")
  frame.selectedText:SetText("Selecciona una mision del resumen.")

  frame.statusActionsPanel = CreateFrame("Frame", nil, frame)
  frame.statusActionsPanel:SetPoint("BOTTOMLEFT", 190, 24)
  frame.statusActionsPanel:SetSize(430, 24)
  DM.summaryStatusButtons = {}
  for index, action in ipairs(SUMMARY_STATUS_ACTIONS) do
    local button = CreateButton(frame.statusActionsPanel, action.label, 76, 22)
    button:SetPoint("LEFT", (index - 1) * 80, 0)
    button.statusKey = action.status
    button:SetScript("OnClick", function(self)
      if summarySelectedContractId then
        DM.SetContractStatus(summarySelectedContractId, self.statusKey)
      end
    end)
    DM.summaryStatusButtons[index] = button
  end

  DM.summaryDuplicateButton = CreateButton(frame, "Duplicar", 90, 22)
  DM.summaryDuplicateButton:SetPoint("BOTTOMRIGHT", -24, 54)
  DM.summaryDuplicateButton:SetScript("OnClick", function()
    if not TC.IsDMMode() then
      TC.Print("Activa el modo DM con .ph dm on para duplicar.")
      return
    end
    if summarySelectedContractId then
      local duplicate = DuplicateContractById(summarySelectedContractId)
      if duplicate then
        summarySelectedContractId = duplicate.id
        DM.RefreshSummary()
        if DM.frame then
          DM.frame:Show()
          DM.frame:Raise()
        end
      end
    end
  end)

  frame.help = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  frame.help:SetPoint("BOTTOMRIGHT", -24, 82)
  frame.help:SetWidth(190)
  frame.help:SetJustifyH("RIGHT")
  frame.help:SetText("Click en una fila: abrir y seleccionar.")

  DM.summaryFrame = frame
end

function DM.RefreshSyncStatus()
  if DM.summaryFrame and DM.summaryFrame.syncStatusText then
    DM.summaryFrame.syncStatusText:SetText(TC.GetSyncStatus())
  end
end

function DM.RefreshSummary()
  if not DM.summaryFrame or not DM.summaryFrame:IsShown() then
    return
  end

  local frame = DM.summaryFrame
  local contracts = GetSortedSummaryContracts()
  if summarySelectedContractId then
    local selectedVisible = false
    for _, contract in ipairs(contracts) do
      if contract.id == summarySelectedContractId then
        selectedVisible = true
        break
      end
    end
    if not selectedVisible then
      summarySelectedContractId = nil
    end
  end
  local pageCount = GetPageCount(#contracts, SUMMARY_ROWS_PER_PAGE)
  if summaryPage > pageCount then
    summaryPage = pageCount
  end
  if summaryPage < 1 then
    summaryPage = 1
  end

  ClearSummaryRows()
  if summaryStatusFilter == "history" then
    frame.totalText:SetText(tostring(#contracts) .. " en historial")
  elseif summaryStatusFilter == "open" then
    frame.totalText:SetText(tostring(#contracts) .. " activos")
  else
    frame.totalText:SetText(tostring(#contracts) .. " contratos visibles")
  end
  frame.pageText:SetText(tostring(summaryPage))
  frame.prevPageButton:SetEnabled(summaryPage > 1)
  frame.nextPageButton:SetEnabled(summaryPage < pageCount)

  if #contracts == 0 then
    local empty = DM.summaryRows[1]
    if not empty then
      empty = frame.rowsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
      empty:SetPoint("TOPLEFT", 8, -8)
      empty:SetWidth(690)
      empty:SetJustifyH("LEFT")
      DM.summaryRows[1] = empty
    end
    if summaryStatusFilter == "history" then
      empty:SetText("No hay contratos completados o archivados todavia.")
    else
      empty:SetText("No hay contratos para este filtro.")
    end
    empty:Show()
    RefreshSummaryActions()
    return
  end

  local startIndex = ((summaryPage - 1) * SUMMARY_ROWS_PER_PAGE) + 1
  local endIndex = math.min(startIndex + SUMMARY_ROWS_PER_PAGE - 1, #contracts)
  local visualIndex = 0

  for index = startIndex, endIndex do
    local contract = contracts[index]
    visualIndex = visualIndex + 1

    local row = DM.summaryRows[visualIndex]
    if not row or row:GetObjectType() ~= "Button" then
      row = CreateFrame("Button", nil, frame.rowsPanel, "BackdropTemplate")
      row:SetSize(720, 44)
      row:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 12,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })

      row.icon = row:CreateTexture(nil, "ARTWORK")
      row.icon:SetSize(30, 30)
      row.icon:SetPoint("LEFT", 8, 0)

      row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      row.title:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
      row.title:SetWidth(260)
      row.title:SetJustifyH("LEFT")

      row.typeText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      row.typeText:SetPoint("LEFT", row.title, "RIGHT", 12, 0)
      row.typeText:SetWidth(96)
      row.typeText:SetJustifyH("LEFT")

      row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      row.statusText:SetPoint("LEFT", row.typeText, "RIGHT", 12, 0)
      row.statusText:SetWidth(96)
      row.statusText:SetJustifyH("LEFT")

      row:SetScript("OnClick", function(self)
        summarySelectedContractId = self.contractId
        if TC.UI and TC.UI.OpenContract and self.contractId then
          TC.UI.OpenContract(self.contractId)
        end
        DM.RefreshSummary()
      end)

      DM.summaryRows[visualIndex] = row
    end

    local difficulty = TC.Data.GetDifficulty(contract.difficulty)
    local color = difficulty.color or { 1, 1, 1 }

    row.contractId = contract.id
    row:SetPoint("TOPLEFT", 0, -(visualIndex - 1) * 48)
    row:SetBackdropColor(0.05, 0.05, 0.06, 0.88)
    if summarySelectedContractId == contract.id then
      row:SetBackdropBorderColor(0.95, 0.82, 0.2, 1.0)
    else
      row:SetBackdropBorderColor(color[1], color[2], color[3], 0.55)
    end
    TC.Util.SetIcon(row.icon, contract.icon or difficulty.icon)
    row.title:SetText(contract.title or "Contrato sin nombre")
    TC.Util.ApplyDifficultyColor(row.title, contract.difficulty)
    row.typeText:SetText(GetContractTypeLabel(contract))
    row.statusText:SetText(TC.Data.GetStatusLabel(contract.status))
    row:Show()
  end
  RefreshSummaryActions()
end

function DM.OpenSummary()
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para ver el resumen.")
    return
  end

  DM.CreateSummary()
  summaryPage = 1
  summarySelectedContractId = nil
  SetSummaryTypeFilter(summaryTypeFilter)
  SetSummaryStatusFilter(summaryStatusFilter)
  DM.summaryFrame:Show()
  DM.summaryFrame:Raise()
  DM.RefreshSummary()
end

function DM.LoadEditingContract()
  DM.Create()
  local contract = editingContractId and TC.Data.GetContractById(editingContractId)
  if not contract then
    DM.titleBox:SetText("")
    SetCategory("mercenary")
  SetDifficulty("yellow")
    SetStatus("draft")
    DM.rewardBox:SetText("")
    DM.rewardXPBox:SetText("")
    SetSelectedRepFaction(nil, nil)
    DM.rewardRepAmountBox:SetText("")
    currentRewardReps = {}
    RefreshRewardReps()
    DM.rewardGoldBox:SetText("")
    DM.rewardSilverBox:SetText("")
    DM.rewardCopperBox:SetText("")
    DM.worldNpcBox:SetText("")
    SetRewardItems({})
    DM.durationBox:SetText("")
    DM.playersBox:SetText("")
    DM.locationBox:SetText("")
    DM.descriptionBox:SetText("")
    DM.objectivesBox:SetText("")
    DM.privateBox:SetText("")
    if DM.pickupBox then DM.pickupBox:SetText("") end
    if DM.progressBox then DM.progressBox:SetText("") end
    if DM.turnInBox then DM.turnInBox:SetText("") end
    return
  end
  DM.titleBox:SetText(contract.title or "")
  SetCategory(contract.category or "mercenary")
  SetDifficulty(contract.difficulty or "yellow")
  SetStatus(contract.status or "draft")
  DM.rewardBox:SetText(contract.rewardText or "")
  DM.rewardXPBox:SetText(contract.rewardXP and tostring(contract.rewardXP) or "")
  -- Carga la LISTA de reputaciones (fallback: la unica rewardRep antigua). El dropdown queda vacio
  -- (sirve para AÑADIR nuevas); la lista muestra las guardadas.
  currentRewardReps = {}
  local repsSource = (type(contract.rewardReps) == "table" and #contract.rewardReps > 0 and contract.rewardReps)
    or (type(contract.rewardRep) == "table" and { contract.rewardRep }) or {}
  for i, rr in ipairs(repsSource) do
    local name = rr.faction
    if not name and rr.factionId and HarfordReputation and HarfordReputation.GetFaction then
      local f = HarfordReputation.GetFaction(rr.factionId); name = f and f.name or rr.factionId
    end
    currentRewardReps[i] = { factionId = rr.factionId, faction = name, amount = rr.amount }
  end
  SetSelectedRepFaction(nil, nil)
  DM.rewardRepAmountBox:SetText("")
  RefreshRewardReps()
  local money = contract.rewardMoney or {}
  DM.rewardGoldBox:SetText(money.gold and money.gold > 0 and tostring(money.gold) or "")
  DM.rewardSilverBox:SetText(money.silver and money.silver > 0 and tostring(money.silver) or "")
  DM.rewardCopperBox:SetText(money.copper and money.copper > 0 and tostring(money.copper) or "")
  DM.worldNpcBox:SetText(contract.worldNpc and tostring(contract.worldNpc) or "")
  SetRewardItems(contract.rewardItems)
  DM.durationBox:SetText(contract.duration or "")
  DM.playersBox:SetText(contract.players or "")
  DM.locationBox:SetText(contract.location or "")
  DM.descriptionBox:SetText(contract.description or "")
  DM.objectivesBox:SetText(ObjectivesToText(contract.objectives))
  DM.privateBox:SetText(contract.privateNotes or "")
  if DM.pickupBox then DM.pickupBox:SetText(contract.pickupText or "") end
  if DM.progressBox then DM.progressBox:SetText(contract.progressText or "") end
  if DM.turnInBox then DM.turnInBox:SetText(contract.turnInText or "") end
end

function DM.Toggle()
  DM.Create()
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para usar el editor.")
    DM.frame:Hide()
    return
  end
  if DM.frame:IsShown() then
    DM.frame:Hide()
  else
    DM.frame:Show()
    DM.ClearEditor()
  end
end

function DM.OpenForContract(contractId)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para editar contratos.")
    return
  end
  DM.Create()
  editingContractId = contractId
  DM.LoadEditingContract()
  DM.frame:Show()
end

function DM.Refresh()
  if DM.frame then
    if DM.frame:IsShown() and not TC.IsDMMode() then
      DM.frame:Hide()
    end
  end
  if DM.prepFrame then
    if DM.prepFrame:IsShown() and not TC.IsDMMode() then
      DM.prepFrame:Hide()
    end
  end
  if DM.summaryFrame then
    if DM.summaryFrame:IsShown() and not TC.IsDMMode() then
      DM.summaryFrame:Hide()
    elseif DM.summaryFrame:IsShown() then
      DM.RefreshSummary()
    end
  end
end
