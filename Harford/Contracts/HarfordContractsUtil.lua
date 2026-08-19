HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.Util = TC.Util or {}

function TC.Util.ResolveIcon(icon)
  if icon == nil or icon == "" then
    return "Interface\\Icons\\INV_Misc_Note_01"
  end
  if type(icon) == "number" then
    return icon
  end
  if string.find(icon, "\\") or string.find(icon, "/") then
    return icon
  end
  return "Interface\\Icons\\" .. icon
end

function TC.Util.SetIcon(texture, icon)
  if not texture then
    return
  end
  texture:SetTexture(TC.Util.ResolveIcon(icon or TC.icon))
end

function TC.Util.ApplyDifficultyColor(fontString, difficultyKey)
  if not fontString then
    return
  end
  local difficulty = TC.Data.GetDifficulty(difficultyKey)
  local color = difficulty.color or { 1, 1, 1 }
  fontString:SetTextColor(color[1], color[2], color[3])
end

function TC.Util.FormatContractMeta(contract)
  -- Sin dificultad (redundante: el color del titulo ya la indica) y con separadores en gris.
  local status = TC.Data.GetStatusLabel(contract.status)
  local sep = "|cff808080 || |r"
  return (contract.duration and contract.duration ~= "" and contract.duration or "-") .. sep .. status
end

-- Parsea una linea de objetivo del editor: texto + `*N` (contador, required) + `#ID` (objeto de
-- inventario que avanza el contador). Devuelve { text, required, item }. Sin `*N` -> required=1.
function TC.Util.ParseObjective(line)
  line = tostring(line or "")
  local item = tonumber(line:match("#(%d+)"))
  local required = tonumber(line:match("%*(%d+)"))
  local text = line:gsub("%*%d+", ""):gsub("#%d+", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return { text = text, required = math.max(1, math.floor(required or 1)), item = item }
end

-- Lista de strings del contrato -> lista estructurada { {text, required, item}, ... } para el nucleo.
function TC.Util.ParseObjectives(objectives)
  local out = {}
  for _, line in ipairs(objectives or {}) do
    if type(line) == "string" and line ~= "" then out[#out + 1] = TC.Util.ParseObjective(line) end
  end
  return out
end

-- Texto de display de un objetivo (para el tablon): "Texto (0/N)" si es contador, si no "Texto".
function TC.Util.FormatObjectiveDisplay(line)
  local o = TC.Util.ParseObjective(line)
  if o.required > 1 then return o.text .. " (0/" .. o.required .. ")" end
  return o.text
end

function TC.Util.JoinObjectives(objectives)
  if type(objectives) ~= "table" or #objectives == 0 then
    return "Sin objetivos definidos."
  end
  local lines = {}
  for index, objective in ipairs(objectives) do
    lines[index] = "- " .. TC.Util.FormatObjectiveDisplay(objective)  -- muestra el contador bonito
  end
  return table.concat(lines, "\n")
end

function TC.Util.GetItemIcon(itemId)
  itemId = tonumber(itemId)
  if not itemId then
    return "Interface\\Icons\\INV_Misc_QuestionMark"
  end
  if GetItemInfoInstant then
    local _, _, _, _, icon = GetItemInfoInstant(itemId)
    if icon then
      return icon
    end
  end
  local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId)
  return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function TC.Util.GetItemName(itemId)
  itemId = tonumber(itemId)
  if not itemId then
    return "Objeto"
  end
  local name = GetItemInfo(itemId)
  return name or ("ItemID " .. tostring(itemId))
end

function TC.Util.CloneRewardItems(rewardItems)
  local copy = {}
  if type(rewardItems) ~= "table" then
    return copy
  end
  for _, item in ipairs(rewardItems) do
    local itemId = tonumber(item.itemId)
    local quantity = tonumber(item.quantity) or 1
    local claimed = tonumber(item.claimed) or 0
    if itemId then
      table.insert(copy, { itemId = itemId, quantity = math.max(1, quantity), claimed = math.max(0, claimed) })
    end
  end
  return copy
end

function TC.Util.GetRewardItemRemaining(item)
  if type(item) ~= "table" then
    return 0
  end
  local quantity = tonumber(item.quantity) or 1
  local claimed = tonumber(item.claimed) or 0
  local remaining = quantity - claimed
  if remaining < 0 then
    remaining = 0
  end
  return remaining
end

function TC.Util.FormatRewardItems(rewardItems)
  if type(rewardItems) ~= "table" or #rewardItems == 0 then
    return "Sin objetos."
  end
  local lines = {}
  for index, item in ipairs(rewardItems) do
    local remaining = TC.Util.GetRewardItemRemaining(item)
    if remaining > 0 then
      lines[index] = string.format("x%s %s", tostring(remaining), TC.Util.GetItemName(item.itemId))
    else
      lines[index] = string.format("%s extraido", TC.Util.GetItemName(item.itemId))
    end
  end
  return table.concat(lines, "\n")
end

function TC.Util.SendAddItemCommand(itemId, callback)
  itemId = tonumber(itemId)
  if not itemId then
    if callback then callback(false, { "itemId invalido" }) end
    return false
  end
  if not (HarfordServerActions and HarfordServerActions.GiveItem) then
    if callback then callback(false, { "HarfordServerActions no disponible para entregar el objeto." }) end
    TC.Print("HarfordServerActions no disponible para entregar el objeto.")
    return false
  end
  local opts = { addonName = "Harford", forceEpsilon = true }
  local callbackCalled = false
  if callback then
    opts.callback = function(success, messages)
      callbackCalled = true
      callback(success, messages)
    end
  end
  local ok, err = HarfordServerActions.GiveItem(itemId, 1, opts)
  if not ok and err then
    if callback and not callbackCalled then callback(false, { err }) end
    TC.Print("No se pudo entregar el objeto: " .. tostring(err))
  end
  return ok == true
end
