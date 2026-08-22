------------------------------------------------------------
-- HarfordWorldQuests - Capa de quests de MUNDO (NPC de fase) sobre el nucleo HarfordQuests.
--
-- El ArcSpell del gossip se ejecuta automaticamente y llama a esta API (`_G.HarfordQuestAPI`):
--   DefineWorldQuest(def)   -> registra la quest (idempotente). Identidad = ID del NPC TEMPLATE.
--   GetNpcQuestState(unit)  -> "available"/"incomplete"/"completed"/nil segun el AURA del NPC.
--   AcceptCurrent(unit)     -> la mete en HarfordQuests, la comparte al grupo y (si oficial)
--                              hace swap de aura disponible->incompleta en el NPC.
--   TurnInCurrent(unit)     -> reparte recompensa (dinero+items al que entrega; rep+xp compartido)
--                              y (si oficial) quita el aura de completada (cierra el NPC).
--
-- Estado canonico = aura sobre el NPC (3 constantes globales). Solo los OFICIALES tocan el aura
-- (comandos de servidor). El reparto y el estado de mision viven en el nucleo HarfordQuests.
--
-- Pendiente (siguientes fases): render de gossip propio de Harford; hook BAG_UPDATE_DELAYED para
-- objetivos por inventario; comando DM de reparto a ausentes.
------------------------------------------------------------

HarfordWorldQuests = HarfordWorldQuests or {}
local API = HarfordWorldQuests

local function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    HarfordChat.Print(table.concat(parts, " "))
end

-- Auras de estado: constantes GLOBALES, mismas para todas las quests. Solo codifican el estado.
API.AURA_AVAILABLE  = 155096
API.AURA_INCOMPLETE = 245633
API.AURA_COMPLETE   = 252527

local COMM_PREFIX = "HARFORDQUEST"

-- Diagnostico del compartir (doble-click): togglear con `/harford debug run qsharedebug`.
local function ShareDbg(...)
    if _G.HARFORD_QSHARE_DEBUG then print("[QSHARE]", ...) end
end

-- Registro runtime: por template de NPC y por id de quest. Lo puebla el ArcSpell via DefineWorldQuest.
local byNpc = {}   -- [templateId(number)] = def
local byId  = {}   -- [questId(string)]    = def

local sharedComplete = {}  -- [questId] = true: ya difundido/recibido el completado (anti-bucle)

local RenderGossip  -- forward: definido en la seccion de UI; refresca el panel si el gossip esta abierto

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function IsOfficer()
    return HarfordAuthority and HarfordAuthority.IsOfficerPlus and HarfordAuthority.IsOfficerPlus() == true
end

-- ID del NPC TEMPLATE (creature-entry, 6º token del GUID), NO el spawn unico.
function API.GetNpcTemplateId(unit)
    local guid = UnitGUID(unit or "npc")
    if not guid then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then return nil end
    return tonumber(id)
end

-- Lee el aura de estado del NPC (HELPFUL) y la traduce. El cliente Epsilon no expone C_UnitAuras;
-- cae a UnitAura / AuraUtil.
local function ScanAuraState(unit)
    local function match(spellId)
        if spellId == API.AURA_AVAILABLE then return "available"
        elseif spellId == API.AURA_INCOMPLETE then return "incomplete"
        elseif spellId == API.AURA_COMPLETE then return "completed" end
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 60 do
            local a = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not a then break end
            local s = match(a.spellId); if s then return s end
        end
    elseif UnitAura then
        for i = 1, 60 do
            local n, _, _, _, _, _, _, _, _, sid = UnitAura(unit, i, "HELPFUL")
            if not n then break end
            local s = match(sid); if s then return s end
        end
    elseif AuraUtil and AuraUtil.ForEachAura then
        local found
        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(_, _, _, _, _, _, _, _, _, spellId)
            local s = match(spellId); if s then found = s; return true end
        end)
        return found
    end
    return nil
end

-- Estado de la quest del NPC actual: prioriza "npc" (gossip), cae a "target".
function API.GetNpcQuestState(unit)
    unit = unit or (UnitExists("npc") and "npc") or "target"
    if not UnitExists(unit) then return nil end
    return ScanAuraState(unit)
end

-- Devuelve la def registrada para el NPC actual (por template id), o nil.
function API.GetCurrentDef(unit)
    unit = unit or (UnitExists("npc") and "npc") or "target"
    local tid = API.GetNpcTemplateId(unit)
    return tid and byNpc[tid] or nil
end

------------------------------------------------------------
-- Definicion (la carga el ArcSpell)
------------------------------------------------------------

-- def = { id, npc=<templateId>, title, description?, rewards?, available?, incomplete?, completed? }
-- available/incomplete/completed = { text=..., objectives={ {text,required}, ... } } (por estado).
function API.DefineWorldQuest(def)
    if type(def) ~= "table" then return false end
    local id = tostring(def.id or "")
    local npc = tonumber(def.npc)
    if id == "" or not npc then return false end
    def.id, def.npc = id, npc
    byNpc[npc] = def
    byId[id] = def
    -- Si el ArcSpell define la quest con el gossip ya abierto, pinta el panel al momento.
    if RenderGossip then RenderGossip() end
    return true
end

------------------------------------------------------------
-- Info que se mete en el nucleo (HarfordQuests) segun el estado
------------------------------------------------------------

local function BuildAcceptInfo(def)
    local stateBlock = def.available or {}
    return {
        title = def.title,
        description = (stateBlock.text and stateBlock.text ~= "" and stateBlock.text) or def.description,
        objectives = stateBlock.objectives,
        rewards = def.rewards,
        category = def.category,      -- para agrupar/colorear igual que en el tablon
        difficulty = def.difficulty,
        source = "world",
    }
end

------------------------------------------------------------
-- Compartir al grupo (display basico; la def completa la tiene el ArcSpell de cada cliente)
------------------------------------------------------------

-- Escape para addon message: `~` es el char de escape; ademas de `^` (sep de campo) reservamos
-- `;` (sep de items de lista) y `=` (sep de sub-campos) para la serializacion estructurada de
-- QSHAREF. Encode escapa `~` primero; decode lo restaura el ultimo (esquema reversible).
local function Esc(s)
    s = tostring(s or "")
    return (s:gsub("~", "~t"):gsub("%^", "~c"):gsub(";", "~s"):gsub("=", "~e"):gsub("\n", "~n"))
end
local function Unesc(s)
    s = tostring(s or "")
    return (s:gsub("~n", "\n"):gsub("~e", "="):gsub("~s", ";"):gsub("~c", "^"):gsub("~t", "~"))
end

-- Serializa objetivos estructurados a blob compacto: `Esc(text)=required=item;...` (item vacio si
-- no hay). Reconstruye la forma que consume HarfordQuests.Accept (NormalizeObjectives).
local function SerializeObjectives(objectives)
    if type(objectives) ~= "table" then return "" end
    local parts = {}
    for _, o in ipairs(objectives) do
        parts[#parts + 1] = Esc(o.text or "") .. "=" .. tostring(o.required or 1) .. "=" .. tostring(o.item or "")
    end
    return table.concat(parts, ";")
end
local function DeserializeObjectives(blob)
    local out = {}
    if type(blob) ~= "string" or blob == "" then return out end
    for item in (blob .. ";"):gmatch("(.-);") do
        if item ~= "" then
            local text, req, it = item:match("^(.-)=(.-)=(.-)$")
            if text then
                out[#out + 1] = { text = Unesc(text), required = tonumber(req) or 1, item = tonumber(it) }
            end
        end
    end
    return out
end

local function SenderIsTrusted(sender)
    if not sender or sender == "" then return false end
    local short = sender:match("^[^%-]+") or sender
    local me = UnitName and UnitName("player")
    if me and (short == me or sender == me) then return true end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(short) ~= nil
    end
    return false
end

------------------------------------------------------------
-- Aceptar / Entregar
------------------------------------------------------------

-- Acepta la quest del NPC actual: la mete en HarfordQuests, la comparte al grupo, y si el que
-- acepta es OFICIAL hace el swap de aura disponible->incompleta sobre el NPC.
function API.AcceptCurrent(unit)
    local def = API.GetCurrentDef(unit)
    if not def then return false end
    if not (HarfordQuests and HarfordQuests.Accept) then return false end

    local info = BuildAcceptInfo(def)
    HarfordQuests.Accept(def.id, info)
    -- Que salga en el tracker en pantalla al aceptarla (como una quest normal).
    if HarfordQuests.SetTracked then HarfordQuests.SetTracked(def.id, true, true) end

    -- Compartir al grupo SIEMPRE (no requiere autoridad), ESTRUCTURADO: reusa la ruta unica
    -- ShareAcceptedQuest (QSHAREF con objetivos/recompensas; fallback a texto si se pasa de tamaño).
    API.ShareAcceptedQuest(def.id)

    -- Solo oficiales tocan el aura del NPC (comando de servidor).
    if IsOfficer() and HarfordServerActions then
        if HarfordServerActions.RemoveNpcAura then HarfordServerActions.RemoveNpcAura(API.AURA_AVAILABLE) end
        if HarfordServerActions.SetNpcAura then HarfordServerActions.SetNpcAura(API.AURA_INCOMPLETE) end
    end
    return true
end

-- Entrega la quest del NPC actual (solo tiene sentido en estado "completed"):
--   * dinero + items -> al que entrega (INDIVIDUAL, comando de servidor).
--   * rep + xp       -> compartido (pull, HarfordQuests.ClaimRewards marca el flag "Recompensa").
--   * si es OFICIAL  -> quita el aura de completada (cierra el NPC para todos).
function API.TurnInCurrent(unit)
    local def = API.GetCurrentDef(unit)
    if not def then return false end
    -- Anti DOBLE entrega: si este PJ ya la cobro (flag "Recompensa"), no repartir dinero+items otra
    -- vez aunque el aura del NPC siga en "completada" (tras reconectar, o doble click).
    if HarfordQuests and HarfordQuests.IsClaimed and HarfordQuests.IsClaimed(def.id) then return false end
    -- Recompensas desde la persistencia (lo aceptado manda; sobrevive a /reload), fallback a la def.
    local r = (HarfordQuests and HarfordQuests.GetRewards and HarfordQuests.GetRewards(def.id))
        or (type(def.rewards) == "table" and def.rewards) or {}

    -- Individual: dinero + items al que entrega.
    if r.money and HarfordDnDEconomy and HarfordDnDEconomy.Grant and HarfordQuests.RewardMoneyCopper then
        local copper = HarfordQuests.RewardMoneyCopper(r)
        if copper > 0 then HarfordDnDEconomy.Grant(copper) end
    end
    if type(r.items) == "table" and HarfordServerActions and HarfordServerActions.GiveItem then
        for _, it in ipairs(r.items) do
            if it.id then HarfordServerActions.GiveItem(it.id, it.count or 1) end
        end
    end

    -- Parte compartida y cierre local: rep/XP para cada miembro, nunca oro ni items. No usar
    -- Abandon: una entrega no debe reproducir el sonido de abandono ni dejar estado intermedio.
    if HarfordQuests.FinalizeSharedTurnIn then
        HarfordQuests.FinalizeSharedTurnIn(def.id, r)
    else
        -- Compatibilidad con una version antigua del core durante una actualizacion parcial.
        if (r.reps or r.rep or r.xp) and HarfordQuests.ClaimRewards then
            HarfordQuests.ClaimRewards({ id = def.id, reward = { reps = r.reps, rep = r.rep, xp = r.xp } })
        end
        if HarfordQuests.MarkClaimed then HarfordQuests.MarkClaimed(def.id) end
        if HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(def.id) and HarfordQuests.Abandon then
            HarfordQuests.Abandon(def.id)
        end
    end

    -- Entrega compartida: cada receptor usa su recompensa persistida para reclamar SOLO rep/XP
    -- y retira la misma mision. El paquete no incluye importes ni objetos, asi que no puede
    -- duplicar la recompensa individual del gossip.
    if HarfordSync and HarfordSync.Send then
        local channel = HarfordSync.BestChannel and HarfordSync.BestChannel()
        if channel then HarfordSync.Send(COMM_PREFIX, "QTURNIN^" .. Esc(def.id), channel) end
    end

    -- Oficial: quita el aura de completada (cierra el NPC).
    if IsOfficer() and HarfordServerActions and HarfordServerActions.RemoveNpcAura then
        HarfordServerActions.RemoveNpcAura(API.AURA_COMPLETE)
    end

    -- La mision del tablon pasa a "completada". Si este jugador es oficial la cierra el mismo
    -- en la fase; si no, avisa al lider del grupo para que la cierre por el. `def.id` ES el id
    -- del contrato (TC.BuildWorldQuestDef lo copia tal cual).
    if HarfordContracts and HarfordContracts.Comm and HarfordContracts.Comm.ReportCompletion then
        HarfordContracts.Comm.ReportCompletion(def.id)
    end

    return true
end

-- Comparte al grupo/raid una mision YA ACEPTADA (desde el registro de misiones). Reusa el formato
-- QSHARE con el display persistido en HarfordQuests. Devuelve true si se pudo enviar (hay grupo).
local MAX_SHARE_BYTES = 240  -- margen bajo el limite ~255 de SendAddonMessage
local shareToken = 0         -- id monotonico de compartir troceado (para reensamblar chunks QSHC)

-- Los mensajes addon consecutivos entran en la cola limitada del cliente. Una mision de mundo
-- suele necesitar varios fragmentos; enviarlos todos en el mismo frame hacia que el primero se
-- perdiera a veces y el receptor tuviera que esperar a un segundo click. Es una cola puntual,
-- no un ticker: conserva el orden y deja respirar al transporte entre fragmentos.
local function SendShareChunks(channel, chunks)
    if type(chunks) ~= "table" or #chunks == 0 then return false end

    local function sendAt(index)
        local sent, err = HarfordSync.Send(COMM_PREFIX, chunks[index], channel)
        if not sent then
            ShareDbg("fallo chunk", "indice=" .. tostring(index), "err=" .. tostring(err))
            return false, err
        end
        local nextIndex = index + 1
        if nextIndex <= #chunks then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.08, function() sendAt(nextIndex) end)
            else
                sendAt(nextIndex)
            end
        end
    end

    return sendAt(1)
end

function API.ShareAcceptedQuest(id)
    id = tostring(id or "")
    if id == "" or not (HarfordQuests and HarfordQuests.GetAccepted) then return false end
    if not (HarfordSync and HarfordSync.Send and HarfordSync.BestChannel) then return false end
    local ch = HarfordSync.BestChannel()
    if not ch then return false end  -- sin grupo no hay a quien compartir
    local quest
    for _, q in ipairs(HarfordQuests.GetAccepted()) do
        if q.id == id then quest = q; break end
    end
    if not quest then return false end

    -- Payload ESTRUCTURADO (QSHAREF): objetivos con contador/item + recompensas rep/xp/money/items,
    -- para que el receptor vea la MISMA ficha (panel estructurado) y su auto-completado/inventario
    -- funcione. Si se pasa del limite, cae al texto-only (QSHARE) para garantizar la entrega.
    local r = quest.rewards or {}
    local rep = type(r.rep) == "table" and r.rep or {}
    local money = type(r.money) == "table" and r.money or {}
    local itemParts = {}
    for _, it in ipairs(r.items or {}) do
        if it.id then
            -- El receptor puede no tener el item custom en cache. Enviamos nombre e icono junto
            -- al ID para que la primera oferta ya sea legible; el link real se resuelve despues.
            local name = it.name or (it.link and it.link:match("%[(.-)%]")) or ""
            local icon = it.icon or (GetItemIcon and GetItemIcon(it.id)) or ""
            if name == "" and GetItemInfo then
                local resolvedName, _, _, _, _, _, _, _, _, resolvedIcon = GetItemInfo(it.id)
                name = resolvedName or name
                icon = icon ~= "" and icon or resolvedIcon or ""
            end
            itemParts[#itemParts + 1] = table.concat({
                tostring(it.id), tostring(it.count or 1), Esc(name), Esc(icon),
            }, "=")
        end
    end
    -- Todas las reputaciones (factionId:amount,...); el nombre lo resuelve el receptor por su store.
    local repParts = {}
    for _, rr in ipairs((type(r.reps) == "table" and r.reps) or (type(r.rep) == "table" and { r.rep }) or {}) do
        if rr.factionId and tonumber(rr.amount) then repParts[#repParts + 1] = tostring(rr.factionId) .. ":" .. tostring(math.floor(rr.amount)) end
    end
    local full = table.concat({
        "QSHAREF",
        Esc(id), Esc(quest.title or id), Esc(quest.description or ""),
        Esc(quest.category or ""), Esc(quest.difficulty or "normal"),
        Esc(rep.faction or ""), tostring(rep.amount or ""),
        tostring(r.xp or ""), tostring(money.gold or ""), tostring(money.silver or ""), tostring(money.copper or ""),
        table.concat(itemParts, ";"),
        SerializeObjectives(quest.objectives),
        table.concat(repParts, ","),
    }, "^")

    -- Cabe en un mensaje -> directo. Si no, TROCEA (QSHC) para NO perder datos (antes caia al texto
    -- QSHARE, que perdia categoria/dificultad/descripcion/recompensas estructuradas).
    local sent, sendErr
    if #full <= MAX_SHARE_BYTES then
        sent, sendErr = HarfordSync.Send(COMM_PREFIX, full, ch)
        ShareDbg("envio directo", "canal="..tostring(ch), "bytes="..#full, "sent="..tostring(sent), "err="..tostring(sendErr))
    else
        shareToken = (shareToken or 0) + 1
        local CHUNK = 200
        local n = math.ceil(#full / CHUNK)
        local chunks = {}
        for i = 1, n do
            chunks[i] = "QSHC^" .. shareToken .. "^" .. i .. "^" .. n .. "^"
                .. full:sub((i - 1) * CHUNK + 1, i * CHUNK)
        end
        sent, sendErr = SendShareChunks(ch, chunks)
    end
    return sent == true, sendErr
end

------------------------------------------------------------
-- Recepcion de compartir (QSHARE)
------------------------------------------------------------

-- Procesa un payload QSHAREF completo (directo o reensamblado de chunks) y mete la mision en
-- HarfordQuests con TODA su ficha: categoria/dificultad/descripcion/objetivos (contador/item) y
-- recompensas (varias reps/xp/money/items). Formato: 15 campos separados por `^`.
local function ProcessStructuredShare(message, sender)
    -- El que COMPARTE no debe recibir su propia oferta: los mensajes a PARTY/RAID hacen eco a uno
    -- mismo. El aviso/oferta es solo para el DESTINO.
    if sender then
        local me = UnitName and UnitName("player")
        local short = sender:match("^[^%-]+") or sender
        if me and short == me then ShareDbg("skip: es mi propio eco"); return end
    end
    local _, id, title, desc, category, difficulty,
        repFaction, repAmount, xp, gold, silver, copper, items, objBlob, repsBlob = strsplit("^", message)
    id = Unesc(id or "")
    if id == "" or not (HarfordQuests and HarfordQuests.Accept) then ShareDbg("skip: id vacio o sin API"); return end
    if HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(id) then ShareDbg("skip: ya aceptada", id); return end
    local rewards = {}
    -- Reputaciones: lista `repsBlob` (factionId:amount,...) con nombre resuelto por HarfordReputation;
    -- cae a la rep unica (legacy) si la lista viene vacia.
    local reps = {}
    if repsBlob and repsBlob ~= "" then
        for factionId, amount in tostring(repsBlob):gmatch("([%w_]+):(%-?%d+)") do
            local name = factionId
            if HarfordReputation and HarfordReputation.GetFaction then
                local f = HarfordReputation.GetFaction(factionId); if f and f.name then name = f.name end
            end
            reps[#reps + 1] = { factionId = factionId, faction = name, amount = tonumber(amount) }
        end
    end
    repFaction = Unesc(repFaction or "")
    if #reps == 0 and repFaction ~= "" and tonumber(repAmount) then
        reps[1] = { faction = repFaction, amount = tonumber(repAmount) }
    end
    if #reps > 0 then rewards.reps = reps end
    if tonumber(xp) then rewards.xp = tonumber(xp) end
    local g, s, c = tonumber(gold), tonumber(silver), tonumber(copper)
    if g or s or c then rewards.money = { gold = g or 0, silver = s or 0, copper = c or 0 } end
    if items and items ~= "" then
        rewards.items = {}
        if items:find(";", 1, true) or items:find("=", 1, true) then
            for pair in (items .. ";"):gmatch("(.-);") do
                local iid, cnt, name, icon = pair:match("^(%d+)=(%d+)=(.-)=(.-)$")
                if iid then
                    rewards.items[#rewards.items + 1] = {
                        id = tonumber(iid), count = tonumber(cnt), name = Unesc(name), icon = Unesc(icon),
                    }
                end
            end
        else
            -- Formato anterior: id:cantidad,id:cantidad. Se conserva para clientes previos.
            for pair in (items .. ","):gmatch("(.-),") do
                local iid, cnt = pair:match("^(%d+):(%d+)$")
                if iid then rewards.items[#rewards.items + 1] = { id = tonumber(iid), count = tonumber(cnt) } end
            end
        end
    end
    local info = {
        title = Unesc(title or ""),
        description = Unesc(desc or ""),
        category = Unesc(category or ""),
        difficulty = Unesc(difficulty or ""),
        objectives = DeserializeObjectives(objBlob or ""),
        rewards = rewards,
        source = "world",
    }
    -- Como el nativo: NO auto-aceptar. Suena y abre un cuadro con la mision para Aceptar/Rechazar.
    if HarfordQuestLog and HarfordQuestLog.ShowShareOffer then
        HarfordQuestLog.ShowShareOffer(sender, id, info)
    else
        HarfordQuests.Accept(id, info)  -- fallback si el registro no esta cargado
    end
end

local incomingShares = {}      -- reensamblado de chunks QSHC por (sender:token)
local SHARE_CHUNK_TTL = 20

do
    local comm = CreateFrame("Frame")
    comm:RegisterEvent("CHAT_MSG_ADDON")
    comm:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
        if prefix ~= COMM_PREFIX or type(message) ~= "string" then return end
        if message:sub(1, 4) == "QSHA" or message:sub(1, 4) == "QSHC" then
            ShareDbg("recibido", "canal="..tostring(channel), "de="..tostring(sender), "msg="..message:sub(1, 12))
        end
        -- Un mensaje que llega por canal de grupo YA garantiza que el emisor esta en el grupo (WoW
        -- lo enruta ahi). Confiar en el canal evita perder el PRIMER mensaje cuando FindUnitByName
        -- aun no resuelve el roster (era el bug de "hay que darle a Compartir dos veces").
        local groupChannel = channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT"
            or channel == "PARTY_LEADER" or channel == "RAID_LEADER" or channel == "INSTANCE_CHAT_LEADER"
        if not (groupChannel or SenderIsTrusted(sender)) then
            ShareDbg("DESCARTADO por confianza", "canal="..tostring(channel), "de="..tostring(sender))
            return
        end

        if message:sub(1, 8) == "QSHAREF^" then
            ProcessStructuredShare(message, sender)

        elseif message:sub(1, 5) == "QSHC^" then
            -- Chunk de un QSHAREF grande: `QSHC^token^i^n^slice` (slice puede contener `^`; se captura
            -- con `.*`). Reensambla por (sender, token) y procesa al tener todas las piezas.
            local token, i, n, slice = message:match("^QSHC%^(%d+)%^(%d+)%^(%d+)%^(.*)$")
            if not token then return end
            i, n = tonumber(i), tonumber(n)
            local now = time and time() or 0
            for k, b in pairs(incomingShares) do
                if now - (b.t or now) > SHARE_CHUNK_TTL then incomingShares[k] = nil end
            end
            local key = tostring(sender) .. ":" .. token
            local buf = incomingShares[key]
            if not buf then buf = { n = n, parts = {}, count = 0, t = now }; incomingShares[key] = buf end
            if i and not buf.parts[i] then buf.parts[i] = slice or ""; buf.count = buf.count + 1 end
            if buf.count >= (buf.n or 0) then
                incomingShares[key] = nil
                ProcessStructuredShare(table.concat(buf.parts, "", 1, buf.n), sender)
            end

        elseif message:sub(1, 7) == "QSHARE^" then
            local _, id, title, objective, reward = strsplit("^", message)
            id = Unesc(id)
            if id == "" or not (HarfordQuests and HarfordQuests.Accept) then return end
            if HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(id) then return end
            local info = { title = Unesc(title), objective = Unesc(objective), reward = Unesc(reward), source = "world" }
            if HarfordQuestLog and HarfordQuestLog.ShowShareOffer then
                HarfordQuestLog.ShowShareOffer(sender, id, info)
            else
                HarfordQuests.Accept(id, info)
            end

        elseif message:sub(1, 7) == "QSTATE^" then
            -- Estado compartido: una quest de mundo se completo en otro cliente del grupo.
            local _, id = strsplit("^", message)
            id = Unesc(id)
            if id ~= "" and HarfordQuests and HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(id)
                and not (HarfordQuests.IsComplete and HarfordQuests.IsComplete(id)) then
                sharedComplete[id] = true  -- evita re-difundir cuando dispare el listener local
                if HarfordQuests.MarkComplete then HarfordQuests.MarkComplete(id, "shared") end
            end

        elseif message:sub(1, 8) == "QTURNIN^" then
            -- Entrega de una mision de mundo por otro miembro: usa el reward local persistido
            -- para conceder solo rep/XP y retirar la quest, nunca dinero ni objetos.
            local _, id = strsplit("^", message)
            id = Unesc(id)
            if id ~= "" and HarfordQuests and HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(id)
                and HarfordQuests.FinalizeSharedTurnIn then
                HarfordQuests.FinalizeSharedTurnIn(id)
            end

        elseif message:sub(1, 8) == "QREWARD^" then
            -- Reparto DM de rep/xp a ausentes: cada receptor sin el flag "Recompensa" cobra una vez.
            local _, id, faction, amount, xp = strsplit("^", message)
            id = Unesc(id)
            if id == "" or not (HarfordQuests and HarfordQuests.ClaimRewards) then return end
            if HarfordQuests.IsSharedRewardsClaimed and HarfordQuests.IsSharedRewardsClaimed(id) then return end
            local rep
            faction, amount = Unesc(faction), tonumber(amount)
            if faction ~= "" and amount then rep = { faction = faction, amount = amount } end
            HarfordQuests.ClaimRewards({ id = id, reward = { rep = rep, xp = tonumber(xp) } })
        end
    end)
    if HarfordSync and HarfordSync.RegisterPrefix then
        HarfordSync.RegisterPrefix(COMM_PREFIX)
    elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
    end
end

-- Auto-completado compartido: cuando una quest de MUNDO se completa (todos los objetivos), se
-- difunde el estado al grupo para que a todos se les marque completada. Guard anti-bucle: no
-- re-difunde lo recibido por QSTATE. El swap de aura del NPC a "completada" NO se hace aqui (el
-- oficial puede no estar junto al NPC); se hace de forma oportunista en el gossip (ver RenderGossip).
do
    local function OnQuestCompleted(id)
        id = tostring(id or "")
        if not byId[id] then return end            -- solo quests de mundo
        if sharedComplete[id] then return end      -- ya difundido/recibido
        sharedComplete[id] = true
        if HarfordSync and HarfordSync.Send then
            local ch = HarfordSync.BestChannel and HarfordSync.BestChannel()
            if ch then HarfordSync.Send(COMM_PREFIX, "QSTATE^" .. Esc(id), ch) end
        end
        if RenderGossip then RenderGossip() end     -- refresca el panel si el gossip esta abierto
    end
    if HarfordQuests and HarfordQuests.RegisterCompletionListener then
        HarfordQuests.RegisterCompletionListener(OnQuestCompleted)
    end
end

------------------------------------------------------------
-- Render de gossip propio (PRIMERA PASADA; la disposicion final depende del gossip real de la fase
-- y se ajusta en juego). Parche parchment sobre el saludo, fuentes de quest (oscuras), boton por
-- estado. NO toca las opciones nativas del gossip; solo superpone un panel. Coexistencia con los
-- hooks de EpsilonLib a verificar en juego.
------------------------------------------------------------

local questPanel

-- Resuelve nombre plano + icono de un item de recompensa. Prioriza name/link de la def (items
-- custom de Epsilon); si solo hay id, usa GetItemInfo y pide cargar si aun no esta cacheado.
local function ResolveItem(it)
    local name = it.name or (it.link and it.link:match("%[(.-)%]"))
    local icon = it.id and GetItemIcon and GetItemIcon(it.id) or nil
    if not name and it.id then
        local n, _, _, _, _, _, _, _, _, tex = GetItemInfo(it.id)
        name, icon = n, (tex or icon)
        if not name and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, it.id) end
    end
    return name or ("[objeto " .. tostring(it.id or "?") .. "]"), icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Boton de recompensa nativo (QuestItemTemplate: icono+marco+nombre+cantidad+tooltip), del pool.
local function GetRewardButton(p, i)
    local b = p.rewardButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, p, "QuestItemTemplate")
    b:SetScript("OnEnter", function(self)
        if self.itemId then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemId)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    p.rewardButtons[i] = b
    return b
end

-- Lineas de dinero/xp/rep como la ficha nativa: pares { label, value }. La etiqueta va en FRIZQT
-- (color normal) y el valor (numeros/monedas) en ARIALN blanco, en su propio elemento. Monedas al
-- tamano 16 como la nativa.
local function RewardLines(r)
    if type(r) ~= "table" then return {} end
    local out = {}
    if r.money then
        local c = (r.money.gold or 0) * 10000 + (r.money.silver or 0) * 100 + (r.money.copper or 0)
        if c > 0 then out[#out + 1] = { label = "Recibirás:", value = (GetCoinTextureString and GetCoinTextureString(c, 18)) or (c .. " cobre") } end
    end
    if tonumber(r.xp) and tonumber(r.xp) > 0 then
        out[#out + 1] = { label = "Experiencia:", value = (BreakUpLargeNumbers and BreakUpLargeNumbers(r.xp)) or tostring(r.xp) }
    end
    -- Reputaciones (varias): una fila por faccion. Numero sin signo "+", verde si suma / rojo si
    -- resta; faccion en blanco. Acepta lista `reps` o `rep` (una, legacy).
    local repList = (type(r.reps) == "table" and #r.reps > 0 and r.reps) or (type(r.rep) == "table" and { r.rep }) or {}
    for _, rr in ipairs(repList) do
        if (rr.faction or rr.factionId) and tonumber(rr.amount) then
            local amt = tonumber(rr.amount)
            local color = (amt < 0) and "|cffff3333" or "|cff33ff33"
            out[#out + 1] = { label = "Reputación:", value = color .. tostring(amt) .. "|r " .. tostring(rr.faction or rr.factionId) }
        end
    end
    return out
end

-- Fila de recompensa del pool: etiqueta (FRIZQT normal) + valor (ARIALN blanco).
local function GetRewLine(p, i)
    local ln = p.rewLines[i]
    if ln then return ln end
    ln = {}
    ln.label = p:CreateFontString(nil, "OVERLAY")
    ln.label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")                      -- etiqueta: FRIZQT 13 negro (como la nativa)
    ln.label:SetTextColor(0, 0, 0)
    ln.label:SetJustifyH("LEFT")
    ln.value = p:CreateFontString(nil, "OVERLAY")
    ln.value:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")                 -- valor: ARIALN 16 OUTLINE blanco (como la nativa)
    ln.value:SetTextColor(1, 1, 1)
    ln.value:SetJustifyH("LEFT")
    p.rewLines[i] = ln
    return ln
end

local function ObjectivesText(objectives)
    if type(objectives) ~= "table" or #objectives == 0 then return "" end
    local lines = {}
    for _, o in ipairs(objectives) do
        local prog = (o.required and o.required > 1) and string.format(" (%d/%d)", o.current or 0, o.required) or ""
        -- Completado: solo en verde (el check ✓ no renderiza en este cliente).
        if o.done then
            lines[#lines + 1] = "|cff40ff40- " .. tostring(o.text or "") .. prog .. "|r"
        else
            lines[#lines + 1] = "- " .. tostring(o.text or "") .. prog
        end
    end
    return table.concat(lines, "\n")
end

-- Fuentes de quest (como estaba antes): cabeceras QuestTitleFont, cuerpo QuestFont.
local FONT_TITLE  = "QuestTitleFont"
local FONT_HEADER = "QuestTitleFont"
local FONT_BODY   = "QuestFont"
-- Valores de recompensa (numeros/monedas): ARIALN como la nativa (NumberFontNormalLarge).
local function PickFont(...) for i = 1, select("#", ...) do local f = select(i, ...); if _G[f] then return f end end return "GameFontNormal" end
local FONT_VALUE = PickFont("NumberFontNormalLarge", "NumberFontNormal", "GameFontHighlight")
local GOSSIP_BOTTOM_PADDING = 16

-- El hijo del ScrollFrame no se redimensiona por las regiones de sus hijos. El antiguo
-- SetAllPoints() hacia que el texto pudiera rebasarlo, pero sin dejar margen desplazable.
local function UpdateGossipContentHeight(p, tail)
    local child = _G.GossipGreetingScrollChildFrame
    if not child or p:GetParent() ~= child or not tail then return end

    p._scrollBaseHeight = p._scrollBaseHeight or child:GetHeight()
    local top, bottom = child:GetTop(), tail:GetBottom()
    if not top or not bottom then return end

    local needed = math.ceil(top - bottom + GOSSIP_BOTTOM_PADDING)
    local height = math.max(p._scrollBaseHeight, needed)
    p:SetHeight(height)
    child:SetHeight(height)

    local scroll = _G.GossipGreetingScrollFrame
    if scroll and scroll.UpdateScrollChildRect then
        scroll:UpdateScrollChildRect()
    elseif scroll and ScrollFrame_UpdateScrollChildRect then
        ScrollFrame_UpdateScrollChildRect(scroll)
    end
end

local function EnsurePanel()
    if questPanel then return questPanel end
    -- Replica el DummyQuestFrame de la fase dentro del hijo desplazable del gossip, sin fondo
    -- propio (usa el pergamino nativo). Conserva una altura propia para que el ScrollFrame pueda
    -- respetar el margen final del contenido.
    local parent = _G.GossipGreetingScrollChildFrame or GossipFrame
    if not parent then return nil end
    local p = CreateFrame("Frame", "HarfordWorldQuestGossipPanel", parent)
    if parent == _G.GossipGreetingScrollChildFrame then
        p:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        p:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
        p._scrollBaseHeight = parent:GetHeight()
        p:SetHeight(p._scrollBaseHeight)
    else
        p:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -32)
        p:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 34)
    end

    -- Todo el texto de quest en NEGRO (0,0,0) sobre el pergamino, como la nativa.
    p.title = p:CreateFontString(nil, "OVERLAY", FONT_TITLE)
    p.title:SetWidth(285); p.title:SetJustifyH("LEFT"); p.title:SetPoint("TOPLEFT", 10, -10); p.title:SetTextColor(0, 0, 0)

    p.body = p:CreateFontString(nil, "OVERLAY", FONT_BODY)
    p.body:SetWidth(275); p.body:SetJustifyH("LEFT"); p.body:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -5); p.body:SetTextColor(0, 0, 0)

    p.objHeader = p:CreateFontString(nil, "OVERLAY", FONT_HEADER)
    p.objHeader:SetWidth(285); p.objHeader:SetJustifyH("LEFT"); p.objHeader:SetText("Objetivos"); p.objHeader:SetTextColor(0, 0, 0)
    p.obj = p:CreateFontString(nil, "OVERLAY", FONT_BODY)
    p.obj:SetWidth(275); p.obj:SetJustifyH("LEFT"); p.obj:SetTextColor(0, 0, 0)

    p.rewHeader = p:CreateFontString(nil, "OVERLAY", FONT_HEADER)
    p.rewHeader:SetWidth(285); p.rewHeader:SetJustifyH("LEFT"); p.rewHeader:SetText("Recompensas"); p.rewHeader:SetTextColor(0, 0, 0)
    p.rewardButtons = {}  -- pool de QuestItemTemplate (icono+nombre+cantidad)
    p.rewLines = {}       -- pool de filas dinero/rep/xp (etiqueta FRIZQT + valor ARIALN)

    -- Boton en GossipFrame abajo-izquierda, como los Accept/Continue/Complete de la fase.
    local btnParent = GossipFrame or p
    p.button = CreateFrame("Button", nil, btnParent, "UIPanelButtonTemplate")
    p.button:SetSize(120, 22)
    p.button:SetPoint("BOTTOMLEFT", btnParent, "BOTTOMLEFT", 6, 4)
    p.button:SetFrameStrata("HIGH")

    p:Hide()
    p.button:Hide()
    questPanel = p
    return p
end

-- Apila verticalmente las piezas visibles: body -> objetivos -> recompensa (cabecera + botones de
-- item nativos + dinero/rep/xp). Devuelve nada; solo posiciona. `rewards` = def.rewards o nil.
local function LayoutPanel(p, showObj, showRew, rewards)
    local last = p.body
    if showObj then
        p.objHeader:ClearAllPoints(); p.objHeader:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -12)
        p.obj:ClearAllPoints(); p.obj:SetPoint("TOPLEFT", p.objHeader, "BOTTOMLEFT", 0, -4)
        last = p.obj
    end

    -- Ocultar botones de item y filas de valor antes de recolocar.
    for _, b in ipairs(p.rewardButtons) do b:Hide() end
    for _, ln in ipairs(p.rewLines) do ln.label:Hide(); ln.value:Hide() end

    if showRew then
        -- Elevar solo el bloque de recompensa para conservar margen bajo la ultima linea.
        p.rewHeader:ClearAllPoints(); p.rewHeader:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -8)
        last = p.rewHeader
        -- Dinero/XP/Rep primero (como la ficha nativa): etiqueta FRIZQT + valor ARIALN blanco.
        local rewardLines = RewardLines(rewards)
        for i, data in ipairs(rewardLines) do
            local ln = GetRewLine(p, i)
            ln.label:SetText(data.label)
            ln.label:ClearAllPoints(); ln.label:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, (last == p.rewHeader) and -6 or -5)
            ln.label:Show()
            ln.value:SetText(data.value)
            ln.value:ClearAllPoints(); ln.value:SetPoint("LEFT", ln.label, "RIGHT", 4, 0)  -- pegado al ":"
            ln.value:Show()
            last = ln.label
        end
        -- Luego los botones de item.
        for i, it in ipairs(rewards and rewards.items or {}) do
            local b = GetRewardButton(p, i)
            local name, icon = ResolveItem(it)
            if b.Icon then b.Icon:SetTexture(icon) end
            if b.Name then b.Name:SetText(name) end
            if SetItemButtonCount then SetItemButtonCount(b, it.count or 1) end
            b.itemId = it.id
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -8)
            b:Show()
            last = b
        end
    end
    return last
end

-- Definicion de la funcion adelantada arriba (upvalue): pinta el panel segun el NPC/estado actual.
RenderGossip = function()
    local p = EnsurePanel()
    if not p then return end
    local function hide() p:Hide(); if p.button then p.button:Hide() end end
    if not (GossipFrame and GossipFrame:IsShown()) then hide(); return end
    local tid = API.GetNpcTemplateId("npc")
    local def = tid and byNpc[tid]
    if not def then hide(); return end

    -- Estado EFECTIVO: si el jugador ya la acepto, manda su propio progreso (auto-completada ->
    -- entrega, aunque el aura del NPC aun no se haya cambiado); si no, la oferta segun el aura.
    local state
    local accepted = HarfordQuests and HarfordQuests.IsAccepted and HarfordQuests.IsAccepted(def.id)
    local claimed = HarfordQuests and HarfordQuests.IsClaimed and HarfordQuests.IsClaimed(def.id)
    local auraState = ScanAuraState("npc")
    if accepted then
        local locallyComplete = HarfordQuests.IsComplete and HarfordQuests.IsComplete(def.id)
        -- RECONCILIACION: si el grupo la completo mientras yo estaba desconectado, perdi el QSTATE
        -- en vivo y mi copia sigue "incompleta". El aura del NPC es el estado CANONICO, asi que al
        -- reabrir el gossip (o targetear el NPC) cierro la mision localmente si el aura dice completada.
        if not locallyComplete and auraState == "completed" and HarfordQuests.MarkComplete then
            sharedComplete[def.id] = true  -- ya reflejado en el NPC; no re-difundir
            HarfordQuests.MarkComplete(def.id, "shared")
            locallyComplete = true
        end
        state = locallyComplete and "completed" or "incomplete"
    elseif auraState == "available" then
        -- El NPC volvio a estar DISPONIBLE (nueva ronda). Si este PJ ya la habia entregado, se limpia
        -- su estado para poder RE-TOMARLA. Antes el flag "claimed" la ocultaba para siempre, asi que
        -- tras entregar y reponer el aura "disponible" el gossip no mostraba nada.
        if claimed and HarfordQuests and HarfordQuests.ResetClaim then HarfordQuests.ResetClaim(def.id) end
        state = "available"
    elseif claimed then
        hide(); return  -- ya entregada y el NPC NO esta disponible: no re-ofrecer
    else
        state = auraState
    end
    if not state then hide(); return end

    -- Oportunista: si esta completada y el aura del NPC sigue en "incompleta", y soy OFICIAL, hago
    -- el swap 245633->252527 aprovechando que estoy junto al NPC (actualiza el visual compartido).
    if state == "completed" and IsOfficer() and HarfordServerActions and ScanAuraState("npc") == "incomplete" then
        if HarfordServerActions.RemoveNpcAura then HarfordServerActions.RemoveNpcAura(API.AURA_INCOMPLETE) end
        if HarfordServerActions.SetNpcAura then HarfordServerActions.SetNpcAura(API.AURA_COMPLETE) end
    end

    -- Limpiar el saludo nativo del gossip para que no se cuele bajo/junto al panel (como la fase).
    if GossipGreetingText then GossipGreetingText:SetText("") end

    p.title:SetText(def.title or "")
    local block = def[state] or {}
    p.body:SetText(block.text or def.description or "")

    -- Objetivos: en 'available' desde la def; en curso desde HarfordQuests (con progreso).
    local objectives
    if state == "available" then
        objectives = block.objectives
    else
        objectives = (HarfordQuests and HarfordQuests.GetObjectives and HarfordQuests.GetObjectives(def.id)) or block.objectives
    end
    local objText = ObjectivesText(objectives)
    local showObj = objText ~= "" and state ~= "completed"
    p.objHeader:SetShown(showObj); p.obj:SetShown(showObj)
    if showObj then p.obj:SetText(objText) end

    -- Recompensa: se muestra en oferta y en entrega. Items en botones nativos; dinero/rep/xp en texto.
    local rewards = (state == "available" or state == "completed") and def.rewards or nil
    local hasReward = rewards and ((rewards.items and #rewards.items > 0) or #RewardLines(rewards) > 0)
    p.rewHeader:SetShown(hasReward == true)

    local contentTail = LayoutPanel(p, showObj, hasReward == true, rewards)

    -- Boton por estado. Con feedback en chat (diagnostico + UX).
    if state == "available" then
        p.button:SetText("Aceptar"); p.button:Show()
        p.button:SetScript("OnClick", function()
            local ok = API.AcceptCurrent("npc")
            print(ok and "|cff33ff99Mision aceptada.|r" or "|cffff5555No se pudo aceptar (def no registrada para este NPC).|r")
            if RenderGossip then RenderGossip() end
        end)
    elseif state == "completed" then
        p.button:SetText("Completar"); p.button:Show()
        p.button:SetScript("OnClick", function()
            local ok = API.TurnInCurrent("npc")
            print(ok and "|cff33ff99Mision entregada.|r" or "|cffff5555No se pudo entregar (¿ya cobrada, o def no registrada?).|r")
            if GossipFrame then GossipFrame:Hide() end
        end)
    else
        p.button:Hide()
    end

    local wasShown = p:IsShown()
    p:Show()
    UpdateGossipContentHeight(p, contentTail)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if p:IsShown() then UpdateGossipContentHeight(p, contentTail) end
        end)
    end
    if not wasShown and HarfordUISounds and HarfordUISounds.Play then
        HarfordUISounds.Play("quest_gossip_shown")
    end
end

do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("GOSSIP_SHOW")
    ev:RegisterEvent("GOSSIP_CLOSED")
    ev:RegisterEvent("GET_ITEM_INFO_RECEIVED")  -- re-pintar cuando un item de recompensa cargue su nombre/icono
    ev:SetScript("OnEvent", function(_, event)
        if event == "GOSSIP_CLOSED" then
            if questPanel then questPanel:Hide(); if questPanel.button then questPanel.button:Hide() end end
        elseif event == "GET_ITEM_INFO_RECEIVED" then
            if questPanel and questPanel:IsShown() then RenderGossip() end
            if HarfordQuestLog and HarfordQuestLog.RefreshShareOffer then
                HarfordQuestLog.RefreshShareOffer()
            end
        else
            RenderGossip()
        end
    end)
end

------------------------------------------------------------
-- Progreso por inventario (evento confirmable, sin ticker). Un objetivo puede declarar `item`
-- (itemId) en la def; al cambiar la bolsa se cuenta con GetItemCount y se actualiza el contador.
-- El indice del objetivo en la def coincide con el de HarfordQuests (Accept normaliza en orden).
------------------------------------------------------------
do
    -- Itera las misiones ACEPTADAS (persistidas en HarfordQuests, no el registro runtime `byId`),
    -- para que el progreso por inventario avance aunque la def del ArcSpell aun no este re-cargada
    -- tras un /reload. El `item` del objetivo viaja en HarfordQuests (persistido).
    local function RefreshItemObjectives()
        if not (HarfordQuests and HarfordQuests.GetAccepted and HarfordQuests.SetObjectiveProgress and GetItemCount) then return end
        for _, q in ipairs(HarfordQuests.GetAccepted()) do
            if not q.completed and type(q.objectives) == "table" then
                for i, o in ipairs(q.objectives) do
                    if o.item then
                        -- Solo lo recogido DESPUES de aceptar: cantidad actual menos el baseline.
                        HarfordQuests.SetObjectiveProgress(q.id, i, (GetItemCount(o.item) or 0) - (o.itemBase or 0))
                    end
                end
            end
        end
    end

    local bagEv = CreateFrame("Frame")
    bagEv:RegisterEvent("BAG_UPDATE_DELAYED")
    bagEv:SetScript("OnEvent", RefreshItemObjectives)
    API.RefreshItemObjectives = RefreshItemObjectives
end

------------------------------------------------------------
-- Reparto DM de rep/xp a ausentes: difunde QREWARD para que quien no cobro reclame su parte.
-- Gate: HarfordAuthority.CanUseDMTools(). El reward sale de la def registrada o de HarfordQuests.
------------------------------------------------------------
function API.DmSendReward(questId)
    questId = tostring(questId or "")
    if questId == "" then return false end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        return false
    end
    -- HarfordQuests distribuye por su canal de grupo solo la rep/xp y cada receptor toma la
    -- definicion completa que ya acepto. Evita perder reputaciones multiples del formato viejo.
    return HarfordQuests and HarfordQuests.GrantSharedRewardsForGroup
        and HarfordQuests.GrantSharedRewardsForGroup(questId) or false
end

------------------------------------------------------------
-- Alias para ArcSpells (subconjunto seguro; jamas ejecuta comandos arbitrarios)
------------------------------------------------------------
_G.HarfordQuestAPI = _G.HarfordQuestAPI or {}
do
    local ext = _G.HarfordQuestAPI
    ext.DefineWorldQuest = API.DefineWorldQuest
    ext.GetNpcQuestState = API.GetNpcQuestState
    ext.GetNpcTemplateId = API.GetNpcTemplateId
    ext.AcceptWorldQuest = API.AcceptCurrent
    ext.TurnInWorldQuest = API.TurnInCurrent
    ext.ShowQuestPanel   = function() if RenderGossip then RenderGossip() end end
    ext.HideQuestPanel   = function() if questPanel then questPanel:Hide() end end
    ext.DmSendReward     = API.DmSendReward  -- auto-gateado por CanUseDMTools()
    -- Helpers de PRESENTACION de recompensa reutilizables (fuente unica): el registro de
    -- misiones (HarfordQuestLog) los usa para pintar la recompensa IGUAL que este panel.
    ext.ResolveRewardItem     = ResolveItem   -- it -> name, icon (resuelve id via GetItemInfo)
    ext.GetRewardValueLines   = RewardLines    -- rewards -> { {label, value}, ... } dinero/xp/rep
    ext.ShareQuest            = API.ShareAcceptedQuest  -- comparte al grupo una mision aceptada
end

------------------------------------------------------------
-- Comando DM: reparte la recompensa compartida (rep/xp) a los ausentes de una mision de mundo.
-- Uso: /harford reparto  (con el NPC de la mision en target)  o  /harford reparto <id>.
-- Se enruta desde el dispatcher /harford. Gate real en DmSendReward (CanUseDMTools).
------------------------------------------------------------
SlashCmdList["HARFORDQUESTREWARD"] = function(rest)
    rest = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local id = rest ~= "" and rest or nil
    if not id then
        local d = API.GetCurrentDef and API.GetCurrentDef("target")
        id = d and d.id
    end
    if not id then
        print("|cffff5555Reparto: targetea el NPC de la mision (o pasa el id).|r")
        return
    end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        print("|cffff5555Reparto: requiere modo DM (HarfordAdmin + .ph dm).|r")
        return
    end
    if API.DmSendReward(id) then
        print("|cff33ff99Reparto de rep/xp enviado al grupo para: " .. id .. ".|r")
    else
        print("|cffff5555No se pudo repartir (¿mision registrada/target correcto?).|r")
    end
end
