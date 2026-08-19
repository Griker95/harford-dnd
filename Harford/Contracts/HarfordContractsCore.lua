local ADDON_NAME = ...

HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.name = ADDON_NAME or "HarfordContracts"
TC.version = "0.1.0"
TC.title = "Tablon de Contratos"
TC.icon = "eps_lol_profileicon_titlescroll"
TC.syncStatus = ""

local defaults = {
  contracts = {},
  settings = {
    minimap = {
      hide = false,
      minimapPos = 220,
    },
  },
}

local function CopyDefaults(src, dst)
  if type(src) ~= "table" then
    return dst
  end
  if type(dst) ~= "table" then
    dst = {}
  end
  for key, value in pairs(src) do
    if type(value) == "table" then
      dst[key] = CopyDefaults(value, dst[key])
    elseif dst[key] == nil then
      dst[key] = value
    end
  end
  return dst
end

function TC.Print(message)
  HarfordChat.Print(message)
end

function TC.SetSyncStatus(message)
  TC.syncStatus = tostring(message or "")
  if TC.UI and TC.UI.RefreshSyncStatus then
    TC.UI.RefreshSyncStatus()
  end
  if TC.DM and TC.DM.RefreshSyncStatus then
    TC.DM.RefreshSyncStatus()
  end
end

function TC.GetSyncStatus()
  return TC.syncStatus or ""
end

function TC.GetDB()
  HarfordContractsDB = CopyDefaults(defaults, HarfordContractsDB)
  return HarfordContractsDB
end

function TC.IsDMMode()
  -- Las herramientas del tablon publican/modifican estado global; requieren HarfordAdmin
  -- cargado y .ph dm activo. No basta con ser DM en Epsilon: HarfordAdmin es la
  -- capa ejecutora de herramientas de maestro.
  if HarfordAuthority and HarfordAuthority.CanUseDMTools then
    return HarfordAuthority.CanUseDMTools() == true
  end
  return false
end

-- Registra un contrato como MISION DE MUNDO si declara `worldNpc` (template id): construye la def
-- estructurada (objetivos + recompensas rep/xp/money/items) y la entrega a HarfordWorldQuests via
-- HarfordQuestAPI.DefineWorldQuest. Asi el gossip del NPC muestra la mision SIN ArcSpell; el estado
-- sigue viviendo en el aura del NPC (oficiales). Idempotente (solo re-setea byNpc[tid]).
-- Construye la DEF de mision de mundo desde un contrato (sin registrarla). La usan tanto el registro
-- runtime como el generador de ArcSpell (`/harford debug run contractarc`), para que el Lua generado
-- lleve EXACTAMENTE lo mismo (incluidos los 4 textos). Devuelve nil si el contrato no tiene NPC.
function TC.BuildWorldQuestDef(contract)
  if type(contract) ~= "table" then return nil end
  local npc = tonumber(contract.worldNpc)
  if not npc then return nil end

  -- Objetivos estructurados (texto + contador `*N` + objeto de inventario `#ID`).
  local objectives = (TC.Util and TC.Util.ParseObjectives and TC.Util.ParseObjectives(contract.objectives)) or {}

  local rewards = {}
  local repsSrc = (type(contract.rewardReps) == "table" and #contract.rewardReps > 0 and contract.rewardReps)
    or (type(contract.rewardRep) == "table" and { contract.rewardRep }) or nil
  if repsSrc then
    rewards.reps = {}
    for _, rr in ipairs(repsSrc) do
      if (rr.faction or rr.factionId) and tonumber(rr.amount) then
        rewards.reps[#rewards.reps + 1] = { faction = rr.faction, factionId = rr.factionId, amount = tonumber(rr.amount) }
      end
    end
    if #rewards.reps == 0 then rewards.reps = nil end
    -- Compat antigua: los clientes viejos leen `rep` (una sola). Incluir la primera como `rep`
    -- ademas de la lista `reps`, para que el ArcSpell generado funcione en ambas versiones.
    if rewards.reps and rewards.reps[1] then rewards.rep = rewards.reps[1] end
  end
  if tonumber(contract.rewardXP) then rewards.xp = tonumber(contract.rewardXP) end
  if type(contract.rewardMoney) == "table" then
    rewards.money = { gold = contract.rewardMoney.gold, silver = contract.rewardMoney.silver, copper = contract.rewardMoney.copper }
  end
  if type(contract.rewardItems) == "table" then
    local items = {}
    for _, it in ipairs(contract.rewardItems) do
      if it.itemId then items[#items + 1] = { id = tonumber(it.itemId), count = tonumber(it.quantity) or 1 } end
    end
    if #items > 0 then rewards.items = items end
  end

  -- 4 textos: Descripcion = tablon/registro; pickupText = lo que dice el NPC al dar la mision;
  -- progressText = mision en proceso; turnInText = al entregar. Cada uno cae a un defecto si esta vacio.
  return {
    id = contract.id,
    npc = npc,
    title = contract.title,
    description = contract.description,
    category = contract.category,
    difficulty = contract.difficulty,
    rewards = rewards,
    available = {
      text = (contract.pickupText and contract.pickupText ~= "" and contract.pickupText) or contract.description,
      objectives = objectives,
    },
    incomplete = { text = (contract.progressText and contract.progressText ~= "" and contract.progressText) or "La mision sigue en curso." },
    completed = { text = (contract.turnInText and contract.turnInText ~= "" and contract.turnInText) or "Has completado la mision. Reclama tu recompensa." },
  }
end

function TC.RegisterWorldQuestFromContract(contract)
  if not (_G.HarfordQuestAPI and _G.HarfordQuestAPI.DefineWorldQuest) then return end
  local def = TC.BuildWorldQuestDef(contract)
  if def then _G.HarfordQuestAPI.DefineWorldQuest(def) end
end

function TC.RegisterAllWorldQuests()
  for _, contract in ipairs((TC.GetDB and TC.GetDB().contracts) or {}) do
    if contract and contract.worldNpc then TC.RegisterWorldQuestFromContract(contract) end
  end
end

function TC.Refresh()
  -- Reconcilia recompensas compartidas (XP/rep) de contratos completados: cada cliente cobra
  -- su parte una vez. Idempotente y barato; cubre login, sync (Comm -> Refresh) y cambios de estado.
  if TC.Rewards and TC.Rewards.Reconcile then
    TC.Rewards.Reconcile()
  end
  -- Registra las misiones de mundo de contratos con NPC (idempotente): cubre login, sync y edicion.
  TC.RegisterAllWorldQuests()
  if TC.UI and TC.UI.Refresh then
    TC.UI.Refresh()
  end
  if TC.DM and TC.DM.Refresh then
    TC.DM.Refresh()
  end
end

function TC.Toggle()
  if TC.UI and TC.UI.Toggle then
    TC.UI.Toggle()
  end
end

function TC.OpenDM()
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para usar el editor.")
    return
  end
  if TC.DM and TC.DM.Toggle then
    TC.DM.Toggle()
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, addonName)
  if event == "ADDON_LOADED" and (addonName == "Harford" or addonName == TC.name) then
    TC.GetDB()
  elseif event == "PLAYER_LOGIN" then
    if TC.UI and TC.UI.Create then
      TC.UI.Create()
    end
    -- La UI DM del tablon es pesada y solo debe construirse bajo demanda desde
    -- TC.OpenDM()/TC.DM.Toggle(), ya gateada por CanUseDMTools().
    -- Boton de minimapa de contratos DESACTIVADO: solo debe haber un boton Harford (el hub
    -- "Herramientas de Rol"). Los contratos se abren desde el Comunicador Harford.
    -- if TC.Minimap and TC.Minimap.Initialize then TC.Minimap.Initialize() end
    if TC.Comm and TC.Comm.Initialize then
      TC.Comm.Initialize()
    end
    TC.Refresh()
    if HarfordDebug and HarfordDebug.Log then
      HarfordDebug.Log("HarfordContracts cargado.")
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    TC.Refresh()
  end
end)

-- Sin SLASH_ global: se enruta por el dispatcher /harford contratos (patron del addon). El
-- handler recibe los sub-args (dm/minimap) via el `rest` del dispatcher.
SlashCmdList.HARFORDCONTRACTS = function(msg)
  msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
  if msg == "dm" then
    TC.OpenDM()
  elseif msg == "minimap" then
    local db = TC.GetDB()
    db.settings.minimap.hide = not db.settings.minimap.hide
    if TC.Minimap and TC.Minimap.Refresh then
      TC.Minimap.Refresh()
    end
  else
    -- La ruta de comando siempre abre el tablón autónomo. El comunicador usa
    -- OpenEmbedded de forma explícita para mostrarlo dentro de su propia UI.
    if TC.UI and TC.UI.OpenStandalone then
      TC.UI.OpenStandalone()
    else
      TC.Toggle()
    end
  end
end
