HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.Comm = TC.Comm or {}

local Comm = TC.Comm
local PREFIX = "TCBOARD"
local MAX_CHUNK = 220
local MAX_CHUNKS = 80
local TRANSFER_TTL = 60
local CLAIM_TTL = 120
local MAX_PENDING_TRANSFERS = 64
local MAX_SNAPSHOT_CONTRACTS = 250
local transfers = {}
local snapshots = {}
local seenRewardClaims = {}
local initialized = false
local boardAuthoritySender
local transferSerial = 0
local snapshotSerial = 0

local function GetPlayerFullName()
  local name, realm = UnitFullName("player")
  if name and realm and realm ~= "" then
    return name .. "-" .. realm
  end
  return UnitName("player") or ""
end

local function Escape(value)
  value = tostring(value or "")
  value = value:gsub("%%", "%%p")
  value = value:gsub("|", "%%b")
  value = value:gsub("\n", "%%n")
  return value
end

local function Unescape(value)
  value = tostring(value or "")
  value = value:gsub("%%n", "\n")
  value = value:gsub("%%b", "|")
  value = value:gsub("%%p", "%%")
  return value
end

local function SplitPipe(message)
  local parts = {}
  message = tostring(message or "")
  local start = 1
  while true do
    local separator = string.find(message, "|", start, true)
    if not separator then
      table.insert(parts, string.sub(message, start))
      break
    end
    table.insert(parts, string.sub(message, start, separator - 1))
    start = separator + 1
  end
  return parts
end

local function SafeField(value)
  return Escape(value or "")
end

local function EncodeContract(contract)
  if type(contract) ~= "table" then
    return nil
  end

  local objectives = ""
  if type(contract.objectives) == "table" then
    objectives = table.concat(contract.objectives, "\n")
  end

  local rewardItems = {}
  if type(contract.rewardItems) == "table" then
    for _, item in ipairs(contract.rewardItems) do
      local itemId = tonumber(item.itemId)
      local quantity = tonumber(item.quantity) or 1
      local claimed = tonumber(item.claimed) or 0
      if itemId then
        table.insert(rewardItems, tostring(itemId) .. ":" .. tostring(math.max(1, quantity)) .. ":" .. tostring(math.max(0, claimed)))
      end
    end
  end

  return table.concat({
    "PUB",
    SafeField(contract.id),
    SafeField(contract.title),
    SafeField(contract.category),
    SafeField(contract.difficulty),
    SafeField(contract.rewardText),
    SafeField(contract.duration),
    SafeField(contract.players),
    SafeField(contract.location),
    SafeField(contract.status),
    SafeField(contract.description),
    SafeField(objectives),
    SafeField(table.concat(rewardItems, ",")),
    SafeField(contract.sortOrder),
    SafeField(contract.rewardXP),
    SafeField(type(contract.rewardRep) == "table" and contract.rewardRep.faction or ""),
    SafeField(type(contract.rewardRep) == "table" and contract.rewardRep.amount or ""),
    -- Campos NUEVOS al final (compat con clientes viejos que ignoran extras): id estable de la
    -- faccion, dinero estructurado (oro/plata/cobre) y NPC template id de mision de mundo.
    SafeField(type(contract.rewardRep) == "table" and contract.rewardRep.factionId or ""),
    SafeField(type(contract.rewardMoney) == "table" and contract.rewardMoney.gold or ""),
    SafeField(type(contract.rewardMoney) == "table" and contract.rewardMoney.silver or ""),
    SafeField(type(contract.rewardMoney) == "table" and contract.rewardMoney.copper or ""),
    SafeField(contract.worldNpc or ""),
    -- Lista de reputaciones extra `factionId:amount,factionId:amount` (23). El nombre lo resuelve el
    -- receptor desde HarfordReputation por el factionId. El primero ya viaja en 16/17/18 (compat).
    SafeField((function()
      if type(contract.rewardReps) ~= "table" then return "" end
      local parts = {}
      for _, rr in ipairs(contract.rewardReps) do
        if rr.factionId and tonumber(rr.amount) then parts[#parts + 1] = tostring(rr.factionId) .. ":" .. tostring(math.floor(rr.amount)) end
      end
      return table.concat(parts, ",")
    end)()),
    -- (24) dinero ya cobrado (bote unico): 1 = alguien se lo llevo.
    SafeField((type(contract.rewardMoney) == "table" and contract.rewardMoney.claimed) and "1" or ""),
    -- (25-27) textos de mision de mundo (separados de la Descripcion del tablon).
    SafeField(contract.pickupText or ""),
    SafeField(contract.progressText or ""),
    SafeField(contract.turnInText or ""),
  }, "|")
end

local function DecodeContract(payload)
  local parts = SplitPipe(payload)
  if parts[1] ~= "PUB" then
    return nil
  end

  local objectives = {}
  for line in string.gmatch(Unescape(parts[12] or ""), "([^\n]+)") do
    if line ~= "" then
      table.insert(objectives, line)
    end
  end

  local rewardItems = {}
  for itemId, quantity, claimed in string.gmatch(Unescape(parts[13] or ""), "(%d+):(%d+):?(%d*)") do
    table.insert(rewardItems, { itemId = tonumber(itemId), quantity = tonumber(quantity) or 1, claimed = tonumber(claimed) or 0 })
  end

  local rewardRepFaction = Unescape(parts[16] or "")
  local rewardRepAmount = tonumber(Unescape(parts[17] or ""))
  local rewardRepFactionId = Unescape(parts[18] or "")
  local rewardRep
  if (rewardRepFaction ~= "" or rewardRepFactionId ~= "") and rewardRepAmount then
    rewardRep = {
      faction = rewardRepFaction ~= "" and rewardRepFaction or rewardRepFactionId,
      factionId = rewardRepFactionId ~= "" and rewardRepFactionId or nil,
      amount = rewardRepAmount,
    }
  end

  -- Dinero estructurado (campos nuevos 19-21) y NPC de mision de mundo (22). Ausentes en payloads
  -- viejos -> nil/0 (compat).
  local mg = tonumber(Unescape(parts[19] or "")) or 0
  local ms = tonumber(Unescape(parts[20] or "")) or 0
  local mc = tonumber(Unescape(parts[21] or "")) or 0
  local rewardMoney
  if mg + ms + mc > 0 then
    rewardMoney = { gold = mg, silver = ms, copper = mc }
    if Unescape(parts[24] or "") == "1" then rewardMoney.claimed = true end  -- bote de dinero ya cobrado
  end
  local worldNpc = tonumber(Unescape(parts[22] or ""))

  -- Lista de reputaciones (23): `factionId:amount,...`. El nombre se resuelve desde HarfordReputation.
  local rewardReps
  local repsBlob = Unescape(parts[23] or "")
  if repsBlob ~= "" then
    rewardReps = {}
    for factionId, amount in string.gmatch(repsBlob, "([%w_]+):(%-?%d+)") do
      local name = factionId
      if HarfordReputation and HarfordReputation.GetFaction then
        local f = HarfordReputation.GetFaction(factionId)
        if f and f.name then name = f.name end
      end
      rewardReps[#rewardReps + 1] = { factionId = factionId, faction = name, amount = tonumber(amount) }
    end
    if #rewardReps == 0 then rewardReps = nil end
  end

  return {
    id = Unescape(parts[2] or ""),
    title = Unescape(parts[3] or ""),
    category = Unescape(parts[4] or "mercenary"),
    difficulty = TC.Data.NormalizeDifficultyKey(Unescape(parts[5] or "yellow")),
    rewardText = Unescape(parts[6] or ""),
    duration = Unescape(parts[7] or ""),
    players = Unescape(parts[8] or ""),
    location = Unescape(parts[9] or ""),
    status = Unescape(parts[10] or "available"),
    description = Unescape(parts[11] or ""),
    objectives = objectives,
    rewardItems = rewardItems,
    sortOrder = tonumber(Unescape(parts[14] or "")),
    rewardXP = tonumber(Unescape(parts[15] or "")),
    rewardRep = rewardRep,
    rewardReps = rewardReps,
    rewardMoney = rewardMoney,
    worldNpc = worldNpc,
    pickupText = Unescape(parts[25] or ""),
    progressText = Unescape(parts[26] or ""),
    turnInText = Unescape(parts[27] or ""),
    __hasSharedRewardFields = #parts >= 17,
    privateNotes = "",
  }
end


local function GetChannel()
  if IsInRaid and IsInRaid() then
    return "RAID"
  end
  if IsInGroup and IsInGroup() then
    return "PARTY"
  end
  if IsInGuild and IsInGuild() then
    return "GUILD"
  end
  return nil
end

local function SendAddonMessage(message, channel)
  channel = channel or GetChannel()
  if not channel then
    TC.Print("No estas en grupo, banda o hermandad para sincronizar.")
    return false
  end

  -- ChatThrottleLib (lo trae EpsilonLib) ESPACIA los addon-messages. Es CLAVE aqui: el tablon se
  -- envia como SNAPBEGIN + todos los chunks de N contratos + SNAPEND en un bucle sincrono; WoW
  -- DESCARTA addon-messages enviados en rafaga, asi que se perdia algun chunk -> un contrato no
  -- completaba -> el receptor exige received==expected y descartaba TODO el snapshot (destino vacio).
  -- CTL (prioridad BULK) los encola y entrega en orden sin perderlos.
  local CTL = _G.ChatThrottleLib
  if _G.HARFORD_TCBOARD_DEBUG then
    TC.Print("[TCBOARD] TX ch=" .. tostring(channel) .. " ctl=" .. tostring(CTL ~= nil) .. " m=" .. string.sub(message or "", 1, 20))
  end
  if CTL and CTL.SendAddonMessage then
    local ok = pcall(CTL.SendAddonMessage, CTL, "BULK", PREFIX, message, channel)
    if ok then return true end
  end

  if HarfordSync and HarfordSync.Send then
    local ok, err = HarfordSync.Send(PREFIX, message, channel)
    if not ok then
      TC.Print("No se pudo sincronizar el tablon: " .. tostring(err or "error desconocido"))
    end
    return ok == true
  end

  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    local ok, err = pcall(C_ChatInfo.SendAddonMessage, PREFIX, message, channel)
    if not ok then
      TC.Print("No se pudo sincronizar el tablon: " .. tostring(err))
      return false
    end
    return true
  end
  if _G.SendAddonMessage then
    local ok, err = pcall(_G.SendAddonMessage, PREFIX, message, channel)
    if not ok then
      TC.Print("No se pudo sincronizar el tablon: " .. tostring(err))
      return false
    end
    return true
  end

  TC.Print("La API de mensajes de addon no esta disponible.")
  return false
end

local function SenderKey(sender)
  sender = tostring(sender or "")
  if Ambiguate then
    return Ambiguate(sender, "short")
  end
  return sender:match("^[^%-]+") or sender
end

local function IsSelfSender(sender)
  local shortSender = SenderKey(sender)
  local shortPlayer = SenderKey(GetPlayerFullName())
  local unitName = UnitName and UnitName("player") or ""
  return shortSender == shortPlayer or shortSender == unitName or tostring(sender or "") == GetPlayerFullName()
end

local function IsValidRemoteSender(sender)
  return tostring(sender or "") ~= "" and not IsSelfSender(sender)
end

local function SenderPlayerKey(sender)
  sender = tostring(sender or "")
  if sender == "" then
    return ""
  end
  return sender
end

local function TrustBoardSender(sender)
  if not IsValidRemoteSender(sender) then
    return
  end
  local nextSender = tostring(sender)
  if boardAuthoritySender ~= nextSender then
    boardAuthoritySender = nextSender
    if TC.SetSyncStatus then
      TC.SetSyncStatus("Fuente del tablon: " .. SenderKey(sender))
    end
  end
end

local function IsBoardAuthority(sender)
  if not IsValidRemoteSender(sender) then return false end
  if not boardAuthoritySender or boardAuthoritySender == "" then return false end
  return SenderKey(sender) == SenderKey(boardAuthoritySender)
      or tostring(sender or "") == tostring(boardAuthoritySender or "")
end

local function CountPublishedContracts()
  local count = 0
  local db = TC.GetDB and TC.GetDB()
  if type(db) ~= "table" or type(db.contracts) ~= "table" then
    return 0
  end
  for _, contract in ipairs(db.contracts) do
    if type(contract) == "table" and contract.status ~= "draft" and contract.status ~= "archived" then
      count = count + 1
    end
  end
  return count
end

local function IsPublicContract(contract)
  return type(contract) == "table"
      and contract.status ~= "draft"
      and contract.status ~= "archived"
end

local function CountPendingTransfers()
  local count = 0
  for _ in pairs(transfers) do count = count + 1 end
  return count
end

local function PurgeExpiredTransfers()
  local now = time and time() or 0
  for key, transfer in pairs(transfers) do
    if (now - (tonumber(transfer.createdAt) or now)) > TRANSFER_TTL then
      transfers[key] = nil
    end
  end
  for key, snapshot in pairs(snapshots) do
    if (now - (tonumber(snapshot.createdAt) or now)) > TRANSFER_TTL then
      snapshots[key] = nil
    end
  end
  for key, claimTime in pairs(seenRewardClaims) do
    if (now - (tonumber(claimTime) or now)) > CLAIM_TTL then
      seenRewardClaims[key] = nil
    end
  end
end

local function SendPayload(payload)
  if not payload or payload == "" then
    return false
  end

  payload = Escape(payload)
  transferSerial = transferSerial + 1
  local transferId = tostring(time()) .. "-" .. tostring(transferSerial)
  local total = math.ceil(string.len(payload) / MAX_CHUNK)
  if total < 1 then
    total = 1
  end
  if total > MAX_CHUNKS then
    TC.Print("Contrato demasiado grande para sincronizar (" .. tostring(total) .. " fragmentos).")
    return false
  end

  for index = 1, total do
    local startIndex = ((index - 1) * MAX_CHUNK) + 1
    local chunk = string.sub(payload, startIndex, startIndex + MAX_CHUNK - 1)
    local ok = SendAddonMessage(table.concat({
      "CHUNK",
      transferId,
      tostring(index),
      tostring(total),
      chunk,
    }, "|"))
    if not ok then
      return false
    end
  end
  return true
end

local function UpsertPublicContract(contract)
  if not contract or contract.id == "" then
    return false
  end

  local existing = TC.Data.GetContractById(contract.id)
  if existing then
    existing.title = contract.title
    existing.category = contract.category
    existing.difficulty = contract.difficulty
    existing.rewardText = contract.rewardText
    existing.duration = contract.duration
    existing.players = contract.players
    existing.location = contract.location
    existing.status = contract.status
    existing.description = contract.description
    existing.objectives = contract.objectives
    existing.sortOrder = contract.sortOrder
    if contract.__hasSharedRewardFields then
      existing.rewardXP = contract.rewardXP
      existing.rewardRep = contract.rewardRep
      existing.rewardReps = contract.rewardReps
      existing.rewardMoney = contract.rewardMoney
      existing.worldNpc = contract.worldNpc
      existing.pickupText = contract.pickupText
      existing.progressText = contract.progressText
      existing.turnInText = contract.turnInText
    end
    for index, item in ipairs(contract.rewardItems or {}) do
      local existingItem = existing.rewardItems and existing.rewardItems[index]
      if existingItem and tonumber(existingItem.itemId) == tonumber(item.itemId) then
        item.claimed = math.max(tonumber(existingItem.claimed) or 0, tonumber(item.claimed) or 0)
      end
    end
    existing.rewardItems = contract.rewardItems
    existing.privateNotes = existing.privateNotes or ""
  else
    contract.__hasSharedRewardFields = nil
    table.insert(TC.GetDB().contracts, contract)
  end

  TC.Refresh()
  return true
end

local function SnapshotKey(sender)
  return tostring(sender or "")
end

local function FinishSnapshot(sender, snapshot)
  if not snapshot or not snapshot.finished or snapshot.received ~= snapshot.expected then
    if _G.HARFORD_TCBOARD_DEBUG and snapshot then
      TC.Print("[TCBOARD] SNAPEND aun no aplica: finished=" .. tostring(snapshot.finished)
        .. " recibidos=" .. tostring(snapshot.received) .. "/" .. tostring(snapshot.expected))
    end
    return false
  end
  if _G.HARFORD_TCBOARD_DEBUG then TC.Print("[TCBOARD] APLICANDO snapshot: " .. tostring(snapshot.expected) .. " contratos") end
  snapshots[SnapshotKey(sender)] = nil
  if not (TC.Data and TC.Data.ReplacePublishedContracts) then
    return false
  end
  local publicContracts = {}
  for _, contract in pairs(snapshot.contracts) do
    table.insert(publicContracts, contract)
  end
  table.sort(publicContracts, function(a, b)
    local ao = tonumber(a.sortOrder) or math.huge
    local bo = tonumber(b.sortOrder) or math.huge
    if ao ~= bo then return ao < bo end
    return tostring(a.id or "") < tostring(b.id or "")
  end)
  if TC.Data.ReplacePublishedContracts(publicContracts) then
    TrustBoardSender(sender)
    TC.SetSyncStatus("Tablon sincronizado |cff44dd44(completado)|r: " .. tostring(snapshot.expected) .. " contratos de " .. SenderKey(sender))
    TC.Print("Tablon actualizado: " .. tostring(snapshot.expected) .. " contratos recibidos de " .. SenderKey(sender) .. ".")
    return true
  end
  return false
end

local function HandleSnapshotBegin(message, sender)
  if not IsValidRemoteSender(sender) then
    if _G.HARFORD_TCBOARD_DEBUG then TC.Print("[TCBOARD] SNAPBEGIN rechazado: sender invalido (" .. tostring(sender) .. ")") end
    return
  end
  local parts = SplitPipe(message)
  if parts[1] ~= "SNAPBEGIN" then return end
  if boardAuthoritySender and not IsBoardAuthority(sender) then
    if _G.HARFORD_TCBOARD_DEBUG then TC.Print("[TCBOARD] SNAPBEGIN rechazado: autoridad=" .. tostring(boardAuthoritySender) .. " sender=" .. tostring(sender)) end
    TC.SetSyncStatus("SNAPBEGIN ignorado de fuente no autorizada: " .. SenderKey(sender))
    return
  end
  if _G.HARFORD_TCBOARD_DEBUG then TC.Print("[TCBOARD] SNAPBEGIN aceptado de " .. tostring(sender) .. " esperados=" .. tostring(parts[3])) end
  local snapshotId = tostring(parts[2] or "")
  local expected = tonumber(parts[3])
  if snapshotId == "" or not expected or expected < 0 or expected > MAX_SNAPSHOT_CONTRACTS then
    return
  end
  local snapshot = {
    id = snapshotId,
    expected = expected,
    received = 0,
    contracts = {},
    createdAt = time and time() or 0,
    finished = false,
  }
  snapshots[SnapshotKey(sender)] = snapshot
end

local function HandleSnapshotEnd(message, sender)
  if not IsValidRemoteSender(sender) then return end
  local parts = SplitPipe(message)
  if parts[1] ~= "SNAPEND" then return end
  local snapshot = snapshots[SnapshotKey(sender)]
  if not snapshot or snapshot.id ~= tostring(parts[2] or "") then return end
  snapshot.finished = true
  FinishSnapshot(sender, snapshot)
end

local function HandleRewardClaim(message, sender)
  if not IsValidRemoteSender(sender) then return end
  -- La cantidad disponible de una recompensa pertenece al tablero del DM.
  -- Los clientes solo solicitan la entrega y esperan el snapshot posterior;
  -- no deben consumir su propia copia al observar la solicitud de otro jugador.
  if not TC.IsDMMode() then return end
  PurgeExpiredTransfers()
  local parts = SplitPipe(message)
  if parts[1] ~= "CLAIM" then
    return
  end
  local contractId = Unescape(parts[2] or "")
  local rewardIndex = tonumber(parts[3])
  local playerName = SenderPlayerKey(sender)
  local claimKey = SenderKey(sender) .. ":" .. tostring(contractId) .. ":" .. tostring(rewardIndex or "")
  if seenRewardClaims[claimKey] then
    return
  end
  local contract = TC.Data.GetContractById(contractId)
  if not contract or contract.status ~= "completed" then
    return
  end
  local ok = TC.Data.ClaimRewardItem(contractId, rewardIndex)
  if ok then
    seenRewardClaims[claimKey] = time and time() or 0
    TC.Print("Recompensa extraida por " .. tostring(playerName) .. " en " .. tostring(contract and contract.title or "contrato") .. ".")
    TC.SetSyncStatus("Recompensa extraida por " .. tostring(playerName))
    if Comm.SyncPublicContracts then
      Comm.SyncPublicContracts(true)
    end
  end
end

-- Reclamo del BOTE de dinero (una sola persona): el DM es la autoridad, marca el bote como cobrado
-- y re-sincroniza para que a todos se les deshabilite. Espejo de HandleRewardClaim.
local function HandleMoneyClaim(message, sender)
  if not IsValidRemoteSender(sender) then return end
  if not TC.IsDMMode() then return end
  local parts = SplitPipe(message)
  if parts[1] ~= "CLAIMMONEY" then return end
  local contractId = Unescape(parts[2] or "")
  local playerName = SenderPlayerKey(sender)
  local contract = TC.Data.GetContractById(contractId)
  if not contract or contract.status ~= "completed" then return end
  local ok = TC.Data.ClaimMoney(contractId)
  if ok then
    TC.Print("Dinero cobrado por " .. tostring(playerName) .. " en " .. tostring(contract.title or "contrato") .. ".")
    TC.SetSyncStatus("Dinero cobrado por " .. tostring(playerName))
    if Comm.SyncPublicContracts then Comm.SyncPublicContracts(true) end
  end
end

local function HandleStatusMessage(message, sender)
  if not IsValidRemoteSender(sender) then return end
  if not IsBoardAuthority(sender) then
    TC.SetSyncStatus("STATUS ignorado de fuente no autorizada: " .. SenderKey(sender))
    return
  end
  local parts = SplitPipe(message)
  if parts[1] ~= "STATUS" then
    return
  end

  local contractId = Unescape(parts[2] or "")
  local status = Unescape(parts[3] or "")
  local contract = TC.Data.GetContractById(contractId)
  if contract and TC.Data.Statuses[status] then
    contract.status = status
    TC.Refresh()
    TC.Print("Estado actualizado desde " .. tostring(sender) .. ": " .. tostring(contract.title) .. " -> " .. TC.Data.GetStatusLabel(status))
  end
end

local function HandlePayload(payload, sender)
  if not IsValidRemoteSender(sender) then return end
  -- Compatibilidad: un DM sin actualizar aun manda un bloque VOTES dentro del snapshot.
  -- Se ignora en silencio para no inyectarlo como contrato basura.
  if payload == "VOTES" or string.sub(payload or "", 1, 6) == "VOTES|" then
    return
  end
  local contract = DecodeContract(payload)
  local snapshot = snapshots[SnapshotKey(sender)]
  if snapshot then
    if not contract then return end
    if not snapshot.contracts[contract.id] then
      snapshot.received = snapshot.received + 1
    end
    snapshot.contracts[contract.id] = contract
    if snapshot.expected and snapshot.expected > 0 then
      TC.SetSyncStatus("Recibiendo tablon: " .. tostring(snapshot.received) .. "/" .. tostring(snapshot.expected) .. "...")
    end
    FinishSnapshot(sender, snapshot)
    return
  end

  -- Compatibilidad con una publicacion aislada de una version anterior: una
  -- vez conocida la autoridad, puede actualizar un contrato pero no aduenarse
  -- del tablon. La primera sincronizacion debe ser SNAPBEGIN/SNAPEND.
  if contract and IsBoardAuthority(sender) and UpsertPublicContract(contract) then
    TC.SetSyncStatus("Contrato actualizado desde " .. tostring(sender))
  end
end

local function HandleEmptyBoard(message, sender)
  if not IsValidRemoteSender(sender) then return end
  local parts = SplitPipe(message)
  if parts[1] ~= "EMPTY" then
    return
  end
  if not IsBoardAuthority(sender) then
    TC.SetSyncStatus("EMPTY heredado ignorado; espera una sincronizacion completa del DM.")
    return
  end
  local removed = TC.Data.ClearPublishedContracts and TC.Data.ClearPublishedContracts() or 0
  TC.SetSyncStatus("Tablon vacio recibido de " .. tostring(sender))
  if removed > 0 then
    TC.Print("Tablon remoto vacio: contratos publicados limpiados (" .. tostring(removed) .. ").")
  end
end

local function HandleChunk(message, sender)
  if not IsValidRemoteSender(sender) then return end
  PurgeExpiredTransfers()
  local parts = SplitPipe(message)
  if parts[1] ~= "CHUNK" then
    return
  end

  local transferId = parts[2]
  local index = tonumber(parts[3])
  local total = tonumber(parts[4])
  local chunk = parts[5] or ""
  if not transferId or not index or not total or total < 1 or total > MAX_CHUNKS or index < 1 or index > total then
    return
  end

  local key = tostring(sender or "") .. ":" .. transferId
  local transfer = transfers[key]
  if not transfer then
    if CountPendingTransfers() >= MAX_PENDING_TRANSFERS then
      TC.SetSyncStatus("Demasiadas transferencias de tablon pendientes; se ignora una nueva.")
      return
    end
    transfer = { chunks = {}, total = total, received = 0, createdAt = time and time() or 0 }
    transfers[key] = transfer
  elseif transfer.total ~= total then
    transfers[key] = nil
    return
  end

  if not transfer.chunks[index] then
    transfer.received = transfer.received + 1
  end
  transfer.chunks[index] = chunk

  if transfer.received >= transfer.total then
    local payload = {}
    for chunkIndex = 1, transfer.total do
      table.insert(payload, transfer.chunks[chunkIndex] or "")
    end
    transfers[key] = nil
    HandlePayload(Unescape(table.concat(payload, "")), sender)
  end
end

function Comm.PublishContract(contract, quiet)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para sincronizar.")
    return false
  end

  if not IsPublicContract(contract) then
    return false
  end

  -- Un contrato nuevo o editado siempre se publica como foto completa: evita
  -- que los clientes acumulen contratos borrados o estados antiguos.
  return Comm.SyncPublicContracts(quiet)
end

function Comm.SyncPublicContracts(quiet)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para sincronizar.")
    return false
  end

  local contracts = {}
  for _, contract in ipairs(TC.GetDB().contracts or {}) do
    if IsPublicContract(contract) then
      table.insert(contracts, contract)
    end
  end

  snapshotSerial = snapshotSerial + 1
  local snapshotId = tostring(time()) .. "-" .. tostring(snapshotSerial)
  TC.SetSyncStatus("Compartiendo tablon... (" .. tostring(#contracts) .. " contratos)")
  if not SendAddonMessage(table.concat({ "SNAPBEGIN", snapshotId, tostring(#contracts) }, "|")) then
    return false
  end

  for _, contract in ipairs(contracts) do
    local payload = EncodeContract(contract)
    if not payload or not SendPayload(payload) then
      TC.SetSyncStatus("Sincronizacion interrumpida; los clientes conservaron el tablon anterior.")
      return false
    end
  end

  if not SendAddonMessage(table.concat({ "SNAPEND", snapshotId }, "|")) then
    TC.SetSyncStatus("Sincronizacion incompleta; los clientes conservaron el tablon anterior.")
    return false
  end
  boardAuthoritySender = GetPlayerFullName()
  -- Envio ASINCRONO (CTL espacia los mensajes): aqui ya se han encolado todos, pero los clientes
  -- los reciben/aplican en los proximos segundos. Por eso el estado dice "enviado", no "recibido".
  TC.SetSyncStatus("Tablon enviado: " .. tostring(#contracts) .. " contratos (llegan en unos segundos)")
  if not quiet then
    TC.Print("Tablon compartido: " .. tostring(#contracts) .. " contratos. Los clientes lo aplican en unos segundos.")
  end
  return true
end

function Comm.PublishRewardClaim(contractId, rewardIndex)
  if not GetChannel() then
    return false
  end
  return SendAddonMessage(table.concat({
    "CLAIM",
    SafeField(contractId),
    tostring(rewardIndex or 0),
    SafeField(TC.Data.GetPlayerKey()),
  }, "|"))
end

-- Solicita al DM marcar el bote de dinero como cobrado (el jugador ya se lo dio con GiveMoney).
function Comm.PublishMoneyClaim(contractId)
  if not GetChannel() then return false end
  return SendAddonMessage(table.concat({
    "CLAIMMONEY",
    SafeField(contractId),
    SafeField(TC.Data.GetPlayerKey()),
  }, "|"))
end

function Comm.PublishStatus(contractId, status)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para sincronizar estados.")
    return false
  end
  if not GetChannel() then
    return false
  end
  local ok = SendAddonMessage(table.concat({
    "STATUS",
    SafeField(contractId),
    SafeField(status),
  }, "|"))
  if ok then
    TC.SetSyncStatus("Pendiente: estado enviado")
  end
  return ok == true
end

function Comm.GetDebugStatus()
  PurgeExpiredTransfers()
  local pending = 0
  local chunks = 0
  for _, transfer in pairs(transfers) do
    pending = pending + 1
    chunks = chunks + (tonumber(transfer.received) or 0)
  end
  local pendingSnapshots = 0
  for _ in pairs(snapshots) do pendingSnapshots = pendingSnapshots + 1 end
  return {
    prefix = PREFIX,
    maxChunk = MAX_CHUNK,
    maxChunks = MAX_CHUNKS,
    transferTTL = TRANSFER_TTL,
    pendingTransfers = pending,
    receivedChunks = chunks,
    pendingSnapshots = pendingSnapshots,
    channel = GetChannel(),
    dmMode = TC.IsDMMode and TC.IsDMMode() or false,
    boardAuthority = boardAuthoritySender,
  }
end

function Comm.Initialize()
  if initialized then
    return
  end
  initialized = true

  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
  end

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("CHAT_MSG_ADDON")
  frame:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
    if prefix ~= PREFIX then
      return
    end
    if _G.HARFORD_TCBOARD_DEBUG then
      TC.Print("[TCBOARD] RX de=" .. tostring(sender) .. " ch=" .. tostring(channel) .. " m=" .. string.sub(message or "", 1, 20))
    end
    if sender == UnitName("player") or sender == GetPlayerFullName() then
      return
    end
    if string.sub(message or "", 1, 10) == "SNAPBEGIN|" then
      HandleSnapshotBegin(message, sender)
      return
    end
    if string.sub(message or "", 1, 8) == "SNAPEND|" then
      HandleSnapshotEnd(message, sender)
      return
    end
    if string.sub(message or "", 1, 11) == "CLAIMMONEY|" then
      HandleMoneyClaim(message, sender)
      return
    end
    if string.sub(message or "", 1, 6) == "CLAIM|" then
      HandleRewardClaim(message, sender)
      return
    end
    if string.sub(message or "", 1, 5) == "VOTE|" or string.sub(message or "", 1, 10) == "VOTECLEAR|"
      or string.sub(message or "", 1, 10) == "VOTERESET|" then
      -- Sistema de votos retirado: se ignoran mensajes de voto de clientes sin actualizar.
      return
    end
    if string.sub(message or "", 1, 5) == "EMPTY" then
      HandleEmptyBoard(message, sender)
      return
    end
    if string.sub(message or "", 1, 7) == "STATUS|" then
      HandleStatusMessage(message, sender)
      return
    end
    HandleChunk(message, sender)
  end)
  Comm.frame = frame
end
