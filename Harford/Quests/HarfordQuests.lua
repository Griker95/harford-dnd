------------------------------------------------------------
-- HarfordQuests - Estado per-PJ de misiones (quest log Harford)
--
-- Capa de SISTEMA (addon), cross-fase, per-personaje. Es la fuente de verdad del estado
-- por jugador; el ArcSpell del tablon (por fase) habla con esta API. Reparto de recompensas:
--   * item / oro  -> se entregan UNA vez en el turn-in del NPC (NO aqui).
--   * reputacion  -> compartida: cada cliente reclama SU parte una vez (modelo pull).
--   * XP          -> INFORMATIVA: se muestra, pero no hay comando fiable de XP en Epsilon.
-- La lista de COMPLETADAS vive en el Lua compartido del tablon (unica persistencia global
-- posible al no haber vault de fase global); aqui solo se guarda que YO ya reclame (anti-doble).
------------------------------------------------------------

HarfordQuests = HarfordQuests or {}

local API = HarfordQuests

-- La sincronizacion puede llegar justo antes del alta local de una mision compartida.
-- Se declara aqui para que Accept() pueda aplicar esa operacion al terminar el alta.
local ApplyPendingObjectiveOperations

local function PlayQuestSound(event)
    if HarfordUISounds and HarfordUISounds.Play then
        HarfordUISounds.Play(event)
    end
end

-- SavedVariables: HarfordQuestsStore, keyed por nombre de PJ (mismo patron que las fichas en
-- HarfordDnDPersistStore.profiles[name]), por consistencia con el resto del addon.
local function CharKey()
    return tostring((UnitName and UnitName("player")) or "default")
end

local function GetStore(create)
    if type(HarfordQuestsStore) ~= "table" then
        if not create then return nil end
        HarfordQuestsStore = {}
    end
    if type(HarfordQuestsStore.characters) ~= "table" then
        if not create then return nil end
        HarfordQuestsStore.characters = {}
    end
    local key = CharKey()
    local pj = HarfordQuestsStore.characters[key]
    if type(pj) ~= "table" then
        if not create then return nil end
        pj = {}
        HarfordQuestsStore.characters[key] = pj
    end
    if create and type(pj.accepted) ~= "table" then pj.accepted = {} end
    -- `claimed` conserva la entrega individual (oro/objetos). La reputacion compartida se
    -- registra por separado para poder concederla al completar sin bloquear el turn-in.
    if create and type(pj.claimed) ~= "table" then pj.claimed = {} end
    if create and type(pj.sharedClaimed) ~= "table" then pj.sharedClaimed = {} end
    if create and type(pj.tracked) ~= "table" then pj.tracked = {} end
    if create and type(pj.nextAcceptedOrder) ~= "number" then
        -- Migracion: los perfiles antiguos solo tienen `since`. Usarlo como
        -- base mantiene las entradas heredadas antes de las nuevas.
        local latest = 0
        for _, entry in pairs(pj.accepted or {}) do
            latest = math.max(latest, tonumber(entry.acceptedOrder) or tonumber(entry.since) or 0)
        end
        pj.nextAcceptedOrder = latest
    end
    return pj
end

local function EnsureStore()
    return GetStore(true)
end

local listeners = {}

local function FireChanged()
    for i = 1, #listeners do
        local ok = pcall(listeners[i])
        if not ok then end
    end
end

-- El quest log (u otra UI) se registra para repintar cuando cambie el estado.
function API.RegisterChangeListener(fn)
    if type(fn) == "function" then listeners[#listeners + 1] = fn end
end

-- Listeners que se disparan cuando una mision pasa a COMPLETADA (todos los objetivos hechos o
-- MarkComplete). Reciben (id). Lo usa HarfordWorldQuests para difundir el estado al grupo.
local completionListeners = {}
function API.RegisterCompletionListener(fn)
    if type(fn) == "function" then completionListeners[#completionListeners + 1] = fn end
end
local function FireCompleted(id)
    for i = 1, #completionListeners do pcall(completionListeners[i], id) end
end

------------------------------------------------------------
-- Objetivos estructurados y completado
--
-- Cada mision guarda `objectives = { {text, required, current, done}, ... }`. Los avances solo
-- llegan por eventos CONFIRMABLES: contador sincronizado (`SetObjectiveProgress`, que llama el
-- ArcSpell/gossip cuando el mundo dispara algo real) o cierre del DM (`MarkComplete`/broadcast).
-- Nunca se inventa progreso local automatico (nada de credito de kill nativo, poco fiable en
-- Epsilon). El string `objective` que consume el quest log/tracker se COMPONE de esta lista.
------------------------------------------------------------

-- Normaliza a lista estructurada. Acepta info.objectives (array de strings o de {text,required})
-- o, como fallback, un info.objective multilinea (una linea = un objetivo de required 1).
local function NormalizeObjectives(info, previous)
    local out = {}
    local src = info.objectives
    if type(src) == "table" then
        for _, o in ipairs(src) do
            if type(o) == "table" and (o.text or o[1]) then
                local itemId = tonumber(o.item)  -- objetivo por inventario (se persiste para avanzar tras /reload)
                out[#out + 1] = {
                    text = tostring(o.text or o[1] or ""),
                    required = math.max(1, math.floor(tonumber(o.required or o[2]) or 1)),
                    current = 0, done = false,
                    item = itemId,
                    -- Baseline: lo que YA tenia al aceptar, para contar solo lo recogido DESPUES (una
                    -- mision "recoge 50" no debe empezar con progreso por lo que ya llevabas encima).
                    itemBase = (itemId and GetItemCount) and (GetItemCount(itemId) or 0) or nil,
                }
            elseif type(o) == "string" and o ~= "" then
                out[#out + 1] = { text = o, required = 1, current = 0, done = false }
            end
        end
    elseif type(info.objective) == "string" and info.objective ~= "" then
        for line in (info.objective .. "\n"):gmatch("(.-)\n") do
            line = line:gsub("^%s*[%-%*]%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" then out[#out + 1] = { text = line, required = 1, current = 0, done = false } end
        end
    end
    -- Re-aceptar una mision ya en curso preserva el progreso por texto (idempotencia suave).
    if previous and type(previous.objectives) == "table" then
        for _, o in ipairs(out) do
            for _, p in ipairs(previous.objectives) do
                if p.text == o.text then
                    o.current = math.min(o.required, tonumber(p.current) or 0)
                    o.done = o.current >= o.required
                    if p.itemBase ~= nil then o.itemBase = p.itemBase end  -- no reiniciar el baseline al re-aceptar
                end
            end
        end
    end
    return out
end

-- Compone el texto multilinea que renderiza el quest log/tracker (con progreso y check).
local function ComposeObjectiveText(objectives)
    if type(objectives) ~= "table" or #objectives == 0 then return "" end
    local lines = {}
    for _, o in ipairs(objectives) do
        local prog = (o.required and o.required > 1) and string.format(" (%d/%d)", o.current or 0, o.required) or ""
        if o.done then
            lines[#lines + 1] = "|cff40ff40- " .. o.text .. prog .. "|r"  -- solo verde (el check ✓ no renderiza)
        else
            lines[#lines + 1] = "- " .. o.text .. prog
        end
    end
    return table.concat(lines, "\n")
end

-- Marca completado si TODOS los objetivos estan hechos. `by` = origen ("objectives"/"dm"/"turnin").
local function RecomputeCompletion(id, entry, by)
    if type(entry.objectives) ~= "table" or #entry.objectives == 0 then return end
    for _, o in ipairs(entry.objectives) do
        if not o.done then return end
    end
    if not entry.completed then
        entry.completed = time()
        entry.completedBy = by or "objectives"
        PlayQuestSound("quest_completed")
        FireCompleted(id)
    end
end

-- Copia defensiva de la lista de objetivos para las lecturas publicas (no exponer el interno).
local function CopyObjectives(objectives)
    local out = {}
    for i, o in ipairs(objectives or {}) do
        out[i] = { text = o.text, required = o.required, current = o.current or 0, done = o.done == true, item = o.item, itemBase = o.itemBase }
    end
    return out
end

------------------------------------------------------------
-- Recompensas estructuradas
--
-- `rewards = { rep = {faction, amount}, xp = n, money = {gold, silver, copper}, items = {...} }`
-- REPARTO: rep/xp son COMPARTIDAS (cada cliente cobra su parte una vez, modelo pull via
-- ClaimRewards). money/items son INDIVIDUALES (turn-in unico en el NPC; el oro se entrega por
-- comando de servidor). El dinero usa campos SEPARADOS oro/plata/cobre; el total en cobre
-- (`RewardMoneyCopper`) es solo para componer el comando de entrega.
------------------------------------------------------------

local function NormalizeRewards(info)
    local r = type(info.rewards) == "table" and info.rewards or {}
    local out = {}
    -- Reputaciones: `reps` = lista de {faction, factionId, amount}; acepta tambien `rep` (una, legacy).
    -- `faction` = nombre visible (display); `factionId` = id estable (concesion robusta, opcional).
    local reps = {}
    local function pushRep(rr)
        if type(rr) == "table" and (rr.faction or rr.factionId) and tonumber(rr.amount) then
            reps[#reps + 1] = {
                faction = tostring(rr.faction or rr.factionId),
                factionId = rr.factionId and tostring(rr.factionId) or nil,
                amount = math.floor(tonumber(rr.amount)),
            }
        end
    end
    if type(r.reps) == "table" and #r.reps > 0 then
        for _, rr in ipairs(r.reps) do pushRep(rr) end
    elseif type(r.rep) == "table" then
        pushRep(r.rep)
    end
    if #reps > 0 then
        out.reps = reps
        out.rep = reps[1]  -- primera, para lectores que solo miran `rep`
    end
    if tonumber(r.xp) then out.xp = math.floor(tonumber(r.xp)) end
    if type(r.money) == "table" then
        local g = math.max(0, math.floor(tonumber(r.money.gold) or 0))
        local s = math.max(0, math.floor(tonumber(r.money.silver) or 0))
        local c = math.max(0, math.floor(tonumber(r.money.copper) or 0))
        if g + s + c > 0 then out.money = { gold = g, silver = s, copper = c } end
    end
    if type(r.items) == "table" then
        local items = {}
        for _, it in ipairs(r.items) do
            if type(it) == "table" and (it.link or it.id) then
                items[#items + 1] = {
                    link = it.link,
                    id = it.id,
                    name = it.name,
                    icon = it.icon,
                    count = math.max(1, math.floor(tonumber(it.count) or 1)),
                }
            end
        end
        if #items > 0 then out.items = items end
    end
    return out
end

local function CopyRewards(rewards)
    if type(rewards) ~= "table" then return nil end
    local out = {}
    if rewards.rep then out.rep = { faction = rewards.rep.faction, factionId = rewards.rep.factionId, amount = rewards.rep.amount } end
    if type(rewards.reps) == "table" then
        out.reps = {}
        for i, rr in ipairs(rewards.reps) do out.reps[i] = { faction = rr.faction, factionId = rr.factionId, amount = rr.amount } end
    end
    if rewards.xp then out.xp = rewards.xp end
    if rewards.money then out.money = { gold = rewards.money.gold or 0, silver = rewards.money.silver or 0, copper = rewards.money.copper or 0 } end
    if rewards.items then
        out.items = {}
        for i, it in ipairs(rewards.items) do
            out.items[i] = { link = it.link, id = it.id, name = it.name, icon = it.icon, count = it.count or 1 }
        end
    end
    return out
end

-- Total en cobre de la parte de dinero (para el comando de entrega). 1 oro = 100 plata = 10000 cobre.
function API.RewardMoneyCopper(rewards)
    local m = type(rewards) == "table" and rewards.money
    if type(m) ~= "table" then return 0 end
    return (m.gold or 0) * 10000 + (m.silver or 0) * 100 + (m.copper or 0)
end

-- Iconos de moneda: los mismos que usa el Comunicador (Interface\MoneyFrame\UI-MoneyIcons con
-- texcoords oro {0,.25}, plata {.25,.5}, cobre {.5,.75}). Markup inline |T...|t que renderiza en
-- cualquier FontString (quest log/tracker). Los texeles se declaran sobre 64x16 (misma fraccion).
local COIN_TEX = "Interface\\MoneyFrame\\UI-MoneyIcons"
local function CoinIcon(leftPx, rightPx)
    return string.format("|T%s:12:12:0:0:64:16:%d:%d:0:16|t", COIN_TEX, leftPx, rightPx)
end
local GOLD_ICON, SILVER_ICON, COPPER_ICON = CoinIcon(0, 16), CoinIcon(16, 32), CoinIcon(32, 48)

-- Texto de dinero con iconos: "12<oro> 30<plata> 5<cobre>" (solo las denominaciones con valor).
local function FormatMoneyParts(m)
    if type(m) ~= "table" then return "" end
    local parts = {}
    if (m.gold or 0) > 0 then parts[#parts + 1] = m.gold .. GOLD_ICON end
    if (m.silver or 0) > 0 then parts[#parts + 1] = m.silver .. SILVER_ICON end
    if (m.copper or 0) > 0 then parts[#parts + 1] = m.copper .. COPPER_ICON end
    return table.concat(parts, " ")
end

-- Texto de objeto para tooltips/enlaces de mision. Primero conserva el hyperlink real; cuando
-- el cache aun no lo conoce, muestra icono + nombre si estan disponibles y solo entonces cae al
-- nombre entre corchetes. Esta es la fuente unica de ese orden de preferencia.
function API.FormatRewardItemForText(item)
    item = type(item) == "table" and item or {}
    if type(item.link) == "string" and item.link ~= "" then return item.link end

    local name, link, icon = item.name, nil, item.icon
    if item.id and GetItemInfo then
        local resolvedName, resolvedLink, _, _, _, _, _, _, _, resolvedIcon = GetItemInfo(item.id)
        name = name or resolvedName
        link = resolvedLink
        icon = icon or resolvedIcon
    end
    if link and link ~= "" then return link end
    if not icon and item.id and GetItemIcon then icon = GetItemIcon(item.id) end
    if name and name ~= "" then
        if icon and icon ~= "" then return "|T" .. icon .. ":14:14|t" .. name end
        return "[" .. name .. "]"
    end
    return "[objeto " .. tostring(item.id or "?") .. "]"
end

-- Compone el string de display de las recompensas cuando el llamador no da uno explicito.
local function ComposeRewardText(rewards)
    if type(rewards) ~= "table" then return "" end
    local segs = {}
    if rewards.money then
        local money = FormatMoneyParts(rewards.money)
        if money ~= "" then segs[#segs + 1] = money end
    end
    for _, it in ipairs(rewards.items or {}) do
        local label = API.FormatRewardItemForText(it)
        segs[#segs + 1] = (it.count and it.count > 1) and (label .. " x" .. it.count) or label
    end
    if rewards.rep then segs[#segs + 1] = "+" .. rewards.rep.amount .. " rep " .. rewards.rep.faction end
    if rewards.xp then segs[#segs + 1] = rewards.xp .. " XP" end
    return table.concat(segs, ", ")
end

------------------------------------------------------------
-- Aceptadas (alimentan el quest log / tracker)
------------------------------------------------------------

-- info: { title, description, objective|objectives, reward, category, difficulty, icon, source }.
-- Los textos/metadatos los pasa quien acepta (tablon, gossip de NPC, ArcSpell) porque las
-- definiciones viven fuera del addon. Si el `id` existe en HarfordQuestCatalog, la definicion del
-- catalogo se usa de BASE y el info recibido la sobrescribe (permite "solo id" o info libre).
-- category/difficulty/icon dejan que el registro clasico agrupe/coloree sin copiar el tablon.
function API.Accept(id, info)
    id = tostring(id or "")
    if id == "" then return false end
    info = type(info) == "table" and info or {}

    -- Catalogo como base (patron "indice + libro"): el ArcSpell puede pasar solo el id.
    if _G.HarfordQuestCatalog and _G.HarfordQuestCatalog.Get then
        local base = _G.HarfordQuestCatalog.Get(id)
        if type(base) == "table" then
            local merged = {}
            for k, v in pairs(base) do merged[k] = v end
            for k, v in pairs(info) do if v ~= nil then merged[k] = v end end
            info = merged
        end
    end

    local store = EnsureStore()
    local previous = store.accepted[id]
    local wasAccepted = previous ~= nil
    local acceptedOrder = previous and tonumber(previous.acceptedOrder)
    if not acceptedOrder then
        store.nextAcceptedOrder = store.nextAcceptedOrder + 1
        acceptedOrder = store.nextAcceptedOrder
    end
    local rewards = NormalizeRewards(info)
    store.accepted[id] = {
        title = tostring(info.title or id),
        description = tostring(info.description or ""),
        objectives = NormalizeObjectives(info, previous),
        rewards = rewards,
        reward = tostring(info.reward ~= nil and info.reward or ComposeRewardText(rewards)),
        category = tostring(info.category or ""),
        difficulty = tostring(info.difficulty or "normal"),
        icon = info.icon,
        source = tostring(info.source or (previous and previous.source) or "contract"),
        since = time(),
        acceptedOrder = acceptedOrder,
        completed = previous and previous.completed or nil,
        completedBy = previous and previous.completedBy or nil,
    }
    if ApplyPendingObjectiveOperations then
        ApplyPendingObjectiveOperations(id)
    end
    -- Re-aceptar puede haber recuperado progreso -> recomputar cierre por objetivos.
    RecomputeCompletion(id, store.accepted[id], "objectives")
    FireChanged()
    if not wasAccepted then PlayQuestSound("quest_accepted") end
    return true
end

function API.Abandon(id)
    local store = GetStore(false)
    id = tostring(id or "")
    if not store or not (store.accepted or {})[id] then return false end
    store.accepted[id] = nil
    store.tracked[id] = nil
    FireChanged()
    PlayQuestSound("quest_abandoned")
    return true
end

-- Falla una mision y la retira del registro. Se mantiene separada de Abandon
-- para que futuros disparadores puedan expresar el resultado sin inventar otro
-- modelo de estado.
function API.Fail(id)
    local store = GetStore(false)
    id = tostring(id or "")
    if not store or not (store.accepted or {})[id] then return false end
    store.accepted[id] = nil
    store.tracked[id] = nil
    FireChanged()
    PlayQuestSound("quest_failed")
    return true
end

function API.IsAccepted(id)
    local store = GetStore(false)
    return store and (store.accepted or {})[tostring(id or "")] ~= nil or false
end

------------------------------------------------------------
-- Rastreo (subconjunto de las aceptadas que se muestra en el tracker en pantalla)
------------------------------------------------------------

function API.IsTracked(id)
    local store = GetStore(false)
    return store and (store.tracked or {})[tostring(id or "")] == true or false
end

-- on = true/false; solo puede rastrearse una mision aceptada.
-- `silent` se usa cuando aceptar una mision la anade automaticamente al
-- tracker: en ese caso ya se reproduce el sonido de aceptacion.
function API.SetTracked(id, on, silent)
    id = tostring(id or "")
    if id == "" then return false end
    local store = GetStore(on == true)
    if not store then return on ~= true end
    local wasTracked = (store.tracked or {})[id] == true
    if on then
        if not store.accepted[id] then return false end
        store.tracked[id] = true
    else
        store.tracked[id] = nil
    end
    FireChanged()
    if not silent and wasTracked ~= (on == true) then PlayQuestSound("quest_tracking_changed") end
    return true
end

function API.ToggleTracked(id)
    return API.SetTracked(id, not API.IsTracked(id))
end

-- Lista ordenada de misiones rastreadas para el tracker: mismos campos que GetAccepted.
function API.GetTracked()
    local store = GetStore(false)
    local out = {}
    if not store then return out end
    for id, entry in pairs(store.accepted or {}) do
        if (store.tracked or {})[id] then
            out[#out + 1] = {
                id = id,
                title = entry.title,
                description = entry.description,
                objective = ComposeObjectiveText(entry.objectives),
                objectives = CopyObjectives(entry.objectives),
                reward = ComposeRewardText(entry.rewards) ~= "" and ComposeRewardText(entry.rewards) or (entry.reward or ""),
                rewards = CopyRewards(entry.rewards),
                category = entry.category or "",
                difficulty = entry.difficulty or "normal",
                icon = entry.icon,
                source = entry.source or "contract",
                completed = entry.completed ~= nil,
                since = entry.since or 0,
                acceptedOrder = entry.acceptedOrder,
            }
        end
    end
    table.sort(out, function(a, b)
        local ao = tonumber(a.acceptedOrder) or tonumber(a.since) or 0
        local bo = tonumber(b.acceptedOrder) or tonumber(b.since) or 0
        if ao ~= bo then return ao < bo end
        return tostring(a.id) < tostring(b.id)
    end)
    return out
end

-- Lista ordenada por antiguedad para el quest log: { { id, title, description, objective }, ... }
function API.GetAccepted()
    local store = GetStore(false)
    local out = {}
    if not store then return out end
    for id, entry in pairs(store.accepted or {}) do
        out[#out + 1] = {
            id = id,
            title = entry.title,
            description = entry.description,
            objective = ComposeObjectiveText(entry.objectives),
            objectives = CopyObjectives(entry.objectives),
            reward = ComposeRewardText(entry.rewards) ~= "" and ComposeRewardText(entry.rewards) or (entry.reward or ""),
            rewards = CopyRewards(entry.rewards),
            category = entry.category or "",
            difficulty = entry.difficulty or "normal",
            icon = entry.icon,
            source = entry.source or "contract",
            completed = entry.completed ~= nil,
            since = entry.since or 0,
            acceptedOrder = entry.acceptedOrder,
            tracked = (store.tracked or {})[id] == true,
        }
    end
    table.sort(out, function(a, b)
        local ao = tonumber(a.acceptedOrder) or tonumber(a.since) or 0
        local bo = tonumber(b.acceptedOrder) or tonumber(b.since) or 0
        if ao ~= bo then return ao < bo end
        return tostring(a.id) < tostring(b.id)
    end)
    return out
end

------------------------------------------------------------
-- Progreso de objetivos y completado (contadores confirmables + override DM)
------------------------------------------------------------

-- Copia estructurada de los objetivos de una mision (para UI). Vacio si no existe.
function API.GetObjectives(id)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    return entry and CopyObjectives(entry.objectives) or {}
end

-- Copia estructurada de las recompensas de una mision (rep/xp/money/items). nil si no hay.
function API.GetRewards(id)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    return entry and CopyRewards(entry.rewards) or nil
end

function API.IsComplete(id)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    return entry ~= nil and entry.completed ~= nil
end

-- Fija el contador de un objetivo (evento confirmable: lo llama el ArcSpell/gossip/entrega). Al
-- alcanzar `required` marca el objetivo hecho; si todos estan hechos, cierra la mision.
function API.SetObjectiveProgress(id, index, current)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    if not entry then return false end
    local o = entry.objectives and entry.objectives[tonumber(index) or 0]
    if not o then return false end
    local wasDone = o.done == true
    o.current = math.max(0, math.min(o.required, math.floor(tonumber(current) or 0)))
    o.done = o.current >= o.required
    -- Un reinicio puede reabrir una mision ya cerrada por objetivos. No revierte recompensas
    -- que alguien hubiese reclamado, pero el estado y el tracker vuelven a reflejar la realidad.
    if not o.done and entry.completed then
        entry.completed = nil
        entry.completedBy = nil
    end
    RecomputeCompletion(tostring(id or ""), entry, "objectives")
    FireChanged()
    if not wasDone and o.done then PlayQuestSound("quest_objective_completed") end
    return true
end

-- Incrementa el contador de un objetivo (delta por defecto +1).
function API.AdvanceObjective(id, index, delta)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    if not entry then return false end
    local o = entry.objectives and entry.objectives[tonumber(index) or 0]
    if not o then return false end
    return API.SetObjectiveProgress(id, index, (o.current or 0) + (tonumber(delta) or 1))
end

-- Marca un objetivo como hecho (para objetivos booleanos).
function API.CompleteObjective(id, index)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    local o = entry and entry.objectives and entry.objectives[tonumber(index) or 0]
    if not o then return false end
    return API.SetObjectiveProgress(id, index, o.required)
end

-- Marca la mision completa localmente (no difunde). `by` = origen del cierre.
function API.MarkComplete(id, by)
    local store = GetStore(false)
    local entry = store and (store.accepted or {})[tostring(id or "")]
    if not entry then return false end
    for _, o in ipairs(entry.objectives or {}) do o.current = o.required; o.done = true end
    local wasCompleted = entry.completed ~= nil
    if not entry.completed then
        entry.completed = time()
        entry.completedBy = by or "dm"
    end
    FireChanged()
    if not wasCompleted then
        PlayQuestSound("quest_completed")
        FireCompleted(tostring(id or ""))
    end
    return true
end

------------------------------------------------------------
-- Sync: override del DM que cierra la mision para todo el grupo
--
-- El DM (HarfordAdmin + .ph dm) difunde `QDONE|id`; cada cliente que TENGA esa mision aceptada la
-- marca completa. No crea misiones ajenas ni ejecuta nada del servidor. Sender validado como
-- propio/grupo/raid (nunca GUILD), igual disciplina que el resto de mensajes de efecto.
------------------------------------------------------------
local COMM_PREFIX = "HARFORDQUEST"

local function DebugObjectiveSync(message)
    if not _G.HARFORD_QOBJ_DEBUG then return end
    if print then
        print("|cff88ccff[HarfordDebug]|r " .. tostring(message))
    end
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

-- Cierre para el grupo (solo DM): marca local + difunde. Devuelve false si no hay autoridad.
function API.CompleteForGroup(id)
    id = tostring(id or "")
    if id == "" then return false end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        return false
    end
    API.MarkComplete(id, "dm")
    if HarfordSync and HarfordSync.Send then
        HarfordSync.Send(COMM_PREFIX, "QDONE|" .. id, HarfordSync.BestChannel and HarfordSync.BestChannel())
    end
    return true
end

-- Fija el progreso de un objetivo para el grupo (solo DM): aplica local + difunde `QOBJ`. El id va
-- ULTIMO para poder contener cualquier caracter; index/current son numeros. Cada cliente que tenga
-- la mision aceptada aplica el mismo SetObjectiveProgress (y auto-completa si procede).
function API.SetObjectiveProgressForGroup(id, index, current)
    id = tostring(id or "")
    index, current = tonumber(index), tonumber(current)
    if id == "" or not index or not current then return false end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        return false
    end
    -- El DM puede gestionar una mision que no tiene aceptada en su propio personaje. El
    -- estado autoritativo para el grupo sigue siendo el paquete QOBJ absoluto; actualizar
    -- la copia local es util, pero no puede impedir que los jugadores la reciban.
    local wasComplete = API.IsComplete(id)
    local updatedLocal = false
    if API.IsAccepted(id) then
        updatedLocal = API.SetObjectiveProgress(id, index, current) == true
    end
    -- El estado es absoluto, no un delta: recibirlo dos veces es inocuo. Reintentamos una vez
    -- porque los clientes pueden acabar de registrar el prefix al entrar en el grupo.
    local payload = table.concat({ "QOBJ", index, current, id }, "|")
    local channel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    local sent, sendErr = false, "Sin transporte de grupo"
    if HarfordSync and HarfordSync.Send and channel then
        sent, sendErr = HarfordSync.Send(COMM_PREFIX, payload, channel)
        if sent and C_Timer and C_Timer.After then
            C_Timer.After(0.25, function()
                local retryChannel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
                if retryChannel then HarfordSync.Send(COMM_PREFIX, payload, retryChannel) end
            end)
        end
    end
    if not sent then return false, sendErr or "No se pudo compartir el objetivo" end
    if updatedLocal and not wasComplete and API.IsComplete(id) then
        API.GrantSharedRewardsForGroup(id)
    end
    return true
end

-- Cierre semantico de UN objetivo para el grupo. El paquete contiene solo la mision, el indice y
-- el estado final: no depende del contador que tenga cada copia local.
function API.CompleteObjectiveForGroup(id, index)
    id = tostring(id or "")
    index = tonumber(index)
    if id == "" or not index then return false end
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        return false
    end
    if API.IsAccepted(id) then
        API.CompleteObjective(id, index)
    end
    local channel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not (HarfordSync and HarfordSync.Send and channel) then
        return false, "Sin canal de grupo"
    end
    local payload = table.concat({ "QOBJ", id, index, "completed" }, "|")
    local sent, sendErr = HarfordSync.Send(COMM_PREFIX, payload, channel)
    -- El estado final es idempotente. Un segundo envio cubre la entrada tardia en raid sin
    -- convertir el objetivo en un contador distribuido.
    if sent and C_Timer and C_Timer.After then
        C_Timer.After(0.25, function()
            local retryChannel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
            if retryChannel then HarfordSync.Send(COMM_PREFIX, payload, retryChannel) end
        end)
    end
    return sent, sendErr
end

do
    -- El receptor debe conservar una referencia estable durante toda la sesion. Antes el frame
    -- quedaba solo en este bloque local, de modo que su listener podia desaparecer aunque el
    -- prefijo siguiera registrado.
    local comm = API._objectiveSyncFrame or CreateFrame("Frame", "HarfordQuestObjectiveSyncFrame")
    API._objectiveSyncFrame = comm
    comm:RegisterEvent("CHAT_MSG_ADDON")

    -- Operaciones efimeras recibidas antes de QSHARE/Accept. No son progreso ni estado
    -- persistente: Accept() las consume una unica vez al registrar la mision local.
    local pendingObjectiveOperations = {}

    local function ApplyObjectiveOperation(qid, index, operation, allowPending)
        if not API.IsAccepted(qid) then
            if allowPending then
                pendingObjectiveOperations[qid] = pendingObjectiveOperations[qid] or {}
                pendingObjectiveOperations[qid][index] = operation
                DebugObjectiveSync(string.format("QOBJ core: pendiente id=%s indice=%s (mision no aceptada)", tostring(qid), tostring(index)))
                if C_Timer and C_Timer.After then
                    C_Timer.After(10, function()
                        local pending = pendingObjectiveOperations[qid]
                        if pending and pending[index] == operation then
                            pending[index] = nil
                            if not next(pending) then pendingObjectiveOperations[qid] = nil end
                        end
                    end)
                end
            end
            return false
        end

        local applied
        if operation.completed then
            applied = API.CompleteObjective(qid, index)
        else
            applied = API.SetObjectiveProgress(qid, index, operation.current)
        end
        if operation.completed then
            local objective = API.GetObjectives(qid)[index]
            DebugObjectiveSync(string.format("QOBJ core: id=%s indice=%s aplicado=%s hecho=%s", tostring(qid), tostring(index), tostring(applied == true), tostring(objective and objective.done == true)))
        end
        return applied == true
    end

    ApplyPendingObjectiveOperations = function(qid)
        local pending = pendingObjectiveOperations[qid]
        if not pending then return end
        DebugObjectiveSync("QOBJ core: aplicando pendientes al aceptar id=" .. tostring(qid))
        pendingObjectiveOperations[qid] = nil
        for index, operation in pairs(pending) do
            ApplyObjectiveOperation(qid, index, operation, false)
        end
    end

    comm:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
        if _G.HARFORD_QOBJ_DEBUG and prefix == COMM_PREFIX then
            DebugObjectiveSync("QOBJ core: evento recibido mensaje=" .. tostring(message))
        end
        if prefix ~= COMM_PREFIX or type(message) ~= "string" then return end
        -- Confiar en el canal de grupo evita perder el primer mensaje si FindUnitByName aun no
        -- resuelve el roster (mismo fix que el compartir de misiones).
        local groupChannel = channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT"
            or channel == "PARTY_LEADER" or channel == "RAID_LEADER" or channel == "INSTANCE_CHAT_LEADER"

        -- Ruta actual y deliberadamente simple: el DM distribuye exactamente
        -- QOBJ|<id de mision>|<indice>|completed. Se trata antes del parser de
        -- opcodes heredados, que sigue abajo solo para clientes anteriores.
        local completedId, completedIndex = message:match("^QOBJ|(.+)|(%d+)|completed$")
        completedIndex = tonumber(completedIndex)
        if completedId and completedIndex then
            if not groupChannel then
                DebugObjectiveSync(string.format("QOBJ core: descartado fuera de grupo id=%s indice=%s", tostring(completedId), tostring(completedIndex)))
                return
            end
            DebugObjectiveSync(string.format("QOBJ core: directo id=%s indice=%s aceptada=%s", tostring(completedId), tostring(completedIndex), tostring(API.IsAccepted(completedId))))
            ApplyObjectiveOperation(completedId, completedIndex, { completed = true }, true)
            return
        end

        -- El progreso (incluido Reiniciar a 0) mantiene su formato antiguo para que los
        -- clientes previos sigan entendiendolo: QOBJ|<indice>|<progreso>|<id>. Se procesa
        -- aqui, antes del dispatcher heredado, por la misma razon que el cierre directo.
        local progressIndex, progressCurrent, progressId = message:match("^QOBJ|(%d+)|(%-?%d+)|(.+)$")
        progressIndex, progressCurrent = tonumber(progressIndex), tonumber(progressCurrent)
        if progressId and progressIndex and progressCurrent then
            if not groupChannel then
                DebugObjectiveSync(string.format("QOBJ core: progreso descartado fuera de grupo id=%s indice=%s", tostring(progressId), tostring(progressIndex)))
                return
            end
            DebugObjectiveSync(string.format("QOBJ core: progreso directo id=%s indice=%s valor=%s aceptada=%s", tostring(progressId), tostring(progressIndex), tostring(progressCurrent), tostring(API.IsAccepted(progressId))))
            ApplyObjectiveOperation(progressId, progressIndex, { current = progressCurrent }, true)
            return
        end

        if not (groupChannel or SenderIsTrusted(sender)) then return end
        local op, rest = message:match("^(%u+)|(.+)$")
        if op == "QDONE" then
            if rest and API.IsAccepted(rest) then API.MarkComplete(rest, "dm") end
        elseif op == "QREWARD" then
            -- La recompensa compartida se calcula desde la copia local de la mision: solo rep/xp,
            -- nunca oro ni objetos. Cada cliente conserva su recibo propio e idempotente.
            if rest and API.IsAccepted(rest) then
                local rewards = API.GetRewards(rest)
                if rewards then API.ClaimRewards({ id = rest, reward = rewards }) end
            end
        elseif op == "QOBJ" then
            -- Cierre directo: QOBJ|<questId>|<objectiveIndex>|completed.
            -- Se conserva la lectura del paquete numerico anterior para clientes previos.
            local qid, index = rest and rest:match("^(.+)|(%d+)|completed$")
            index = tonumber(index)
            if qid and index then
                DebugObjectiveSync(string.format("QOBJ core: recibido id=%s indice=%s aceptada=%s", tostring(qid), tostring(index), tostring(API.IsAccepted(qid))))
                ApplyObjectiveOperation(qid, index, { completed = true }, true)
            else
                local legacyIndex, current, legacyId = rest and rest:match("^(%d+)|(%-?%d+)|(.+)$")
                legacyIndex, current = tonumber(legacyIndex), tonumber(current)
                if legacyId and legacyIndex and current then
                    ApplyObjectiveOperation(legacyId, legacyIndex, { current = current }, true)
                end
            end
        elseif op == "QOBJDONE" then
            -- Compatibilidad temporal con clientes que aun emiten QOBJDONE.
            local index, qid = rest and rest:match("^(%d+)|(.+)$")
            index = tonumber(index)
            if qid and index then
                ApplyObjectiveOperation(qid, index, { completed = true }, true)
            end
        end
    end)
    if HarfordSync and HarfordSync.RegisterPrefix then
        HarfordSync.RegisterPrefix(COMM_PREFIX)
    elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
    end
end

------------------------------------------------------------
-- Reclamacion de recompensas compartidas (rep)
------------------------------------------------------------

function API.IsClaimed(id)
    local store = GetStore(false)
    return store and (store.claimed or {})[tostring(id or "")] == true or false
end

function API.IsSharedRewardsClaimed(id)
    local store = GetStore(false)
    return store and (store.sharedClaimed or {})[tostring(id or "")] == true or false
end

-- Retira la marca de reclamada (para pruebas/re-concesion controlada; p.ej. debug de contratos).
function API.ResetClaim(id)
    local store = GetStore(false)
    if not store then return end
    local key = tostring(id or "")
    if store.claimed then store.claimed[key] = nil end
    if store.sharedClaimed then store.sharedClaimed[key] = nil end
end

local function MarkClaimed(id)
    EnsureStore().claimed[tostring(id or "")] = true
end

local function MarkSharedRewardsClaimed(id)
    EnsureStore().sharedClaimed[tostring(id or "")] = true
end

-- Marca la mision como entregada/cobrada por este PJ (flag "Recompensa"). Idempotente. Lo usa el
-- turn-in de mundo para impedir doble entrega (dinero+items) aunque el aura del NPC siga abierta.
function API.MarkClaimed(id)
    MarkClaimed(id)
end

-- Concede rep al PROPIO PJ usando SOLO la API publica de HarfordReputation (self-grant via
-- fromSync, que sortea el gate de DM). Resuelve la faccion por id o por nombre. Autocontenido:
-- no requiere anadir nada al modulo core de reputacion.
local function GrantSelfReputation(faction, delta)
    local R = HarfordReputation
    if not (R and R.SetPlayerPoints and R.GetPlayerKey and R.GetPlayerPoints) then return false end
    local factionId
    if R.GetFaction and R.GetFaction(faction) then
        factionId = tostring(faction)
    elseif R.GetFactions and HarfordClassColors then
        local wanted = HarfordClassColors.StripAccents(tostring(faction)):lower()
        for _, f in ipairs(R.GetFactions(true)) do
            if HarfordClassColors.StripAccents(tostring(f.name or "")):lower() == wanted then
                factionId = f.id
                break
            end
        end
    end
    if not factionId then return false end
    local key = R.GetPlayerKey("player")
    if not key then return false end
    local ok = R.SetPlayerPoints(key, factionId, (R.GetPlayerPoints(key, factionId) or 0) + delta, { fromSync = true })
    return ok == true
end

-- Concede al PROPIO PJ su parte de las recompensas compartidas de una mision y la marca
-- reclamada. Idempotente: si ya estaba reclamada, no hace nada. Devuelve true si concedio ahora.
-- item/oro NO se tocan aqui (son turn-in unico); XP queda pendiente de sistema.
function API.ClaimRewards(mission)
    if type(mission) ~= "table" or not mission.id then return false end
    local id = tostring(mission.id)
    if API.IsSharedRewardsClaimed(id) then return false end

    local reward = type(mission.reward) == "table" and mission.reward or {}
    -- Reputaciones (varias): lista `reps`, o `rep` (una, legacy). Se concede cada una que resuelva su
    -- faccion; el id estable manda (robusto ante typos/tildes), cae al nombre si no hay id.
    local repList = {}
    if type(reward.reps) == "table" and #reward.reps > 0 then repList = reward.reps
    elseif type(reward.rep) == "table" then repList = { reward.rep } end
    local grantedAny = false
    local repResolved, repTotal = 0, 0
    for _, rp in ipairs(repList) do
        if (rp.faction or rp.factionId) and tonumber(rp.amount) then
            repTotal = repTotal + 1
            if GrantSelfReputation(rp.factionId or rp.faction, tonumber(rp.amount)) then
                repResolved = repResolved + 1
                grantedAny = true
                if DEFAULT_CHAT_FRAME then
                    local amt = tonumber(rp.amount)
                    HarfordChat.Print(string.format("%s%d de reputacion con %s.",
                        amt >= 0 and "+" or "", amt, tostring(rp.faction or rp.factionId)))
                end
            end
        end
    end
    -- Si habia reps declaradas y NINGUNA resolvio (facciones aun no sincronizadas), no marcar
    -- reclamada: deja que un Reconcile posterior lo reintente cuando lleguen las facciones.
    if repTotal > 0 and repResolved == 0 then
        return false
    end
    -- reward.xp: INFORMATIVA. No hay comando fiable de XP en Epsilon (`.mod xp`/`.modify xp` no
    -- disponible), asi que la XP se MUESTRA en la recompensa pero no se concede. Pendiente de metodo real.
    if not grantedAny then
        return false
    end

    MarkSharedRewardsClaimed(id)
    FireChanged()
    return true
end

-- Distribuye solo la parte compartida de una mision completada. Oro e items siguen ligados al
-- NPC y los recibe exclusivamente quien usa el boton de entrega.
function API.GrantSharedRewardsForGroup(id)
    id = tostring(id or "")
    if id == "" or not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        return false
    end
    local rewards = API.GetRewards(id)
    if type(rewards) ~= "table" then return false end
    local hasReputation = (type(rewards.reps) == "table" and #rewards.reps > 0) or type(rewards.rep) == "table"
    if not hasReputation then return false end

    local alreadyClaimed = API.IsSharedRewardsClaimed(id)
    if not alreadyClaimed then API.ClaimRewards({ id = id, reward = rewards }) end
    -- Tambien se reenvia si el DM ya cobro: sirve para jugadores que se incorporaron tarde o
    -- recuperaron la mision despues de una desconexion. El recibo de cada receptor es idempotente.
    if HarfordSync and HarfordSync.Send then
        HarfordSync.Send(COMM_PREFIX, "QREWARD|" .. id, HarfordSync.BestChannel and HarfordSync.BestChannel())
    end
    return true
end

-- Limpieza explicita, nunca automatica: quita rastreos huerfanos y perfiles que
-- ya no guardan misiones ni recibos. Devuelve el numero de entradas eliminadas.
function API.Prune()
    if type(HarfordQuestsStore) ~= "table" or type(HarfordQuestsStore.characters) ~= "table" then
        return 0
    end
    local removed = 0
    for key, pj in pairs(HarfordQuestsStore.characters) do
        if type(pj) == "table" then
            for id in pairs(pj.tracked or {}) do
                if not (pj.accepted and pj.accepted[id]) then
                    pj.tracked[id] = nil
                    removed = removed + 1
                end
            end
            local emptyAccepted = not next(pj.accepted or {})
            local emptyClaimed = not next(pj.claimed or {})
            local emptySharedClaimed = not next(pj.sharedClaimed or {})
            local emptyTracked = not next(pj.tracked or {})
            if emptyAccepted and emptyClaimed and emptySharedClaimed and emptyTracked then
                HarfordQuestsStore.characters[key] = nil
                removed = removed + 1
            end
        end
    end
    if removed > 0 then FireChanged() end
    return removed
end

-- Al abrir el tablon / entrar en la fase: recorre las COMPLETADAS del Lua compartido y
-- reclama la parte propia de las que aun no cobre. missionsById: { [id] = mission }.
-- completedList: array de ids. Devuelve cuantas reclamo ahora.
function API.Reconcile(completedList, missionsById)
    if type(completedList) ~= "table" or type(missionsById) ~= "table" then return 0 end
    local granted = 0
    for _, id in ipairs(completedList) do
        local mission = missionsById[id] or missionsById[tostring(id)]
        if mission and API.ClaimRewards(mission) then
            granted = granted + 1
        end
    end
    return granted
end

------------------------------------------------------------
-- Alias estable para ArcSpells/macros externos. Subconjunto SEGURO: solo estado de misiones del
-- propio jugador; nunca ejecuta comandos de servidor ni toca a otros clientes directamente. El
-- avance de objetivos es el camino "contador confirmable": el ArcSpell lo llama cuando el mundo
-- dispara un evento real (recoger objeto, hablar con NPC, entrega validada).
------------------------------------------------------------
_G.HarfordQuestAPI = _G.HarfordQuestAPI or {}
do
    local ext = _G.HarfordQuestAPI
    ext.Accept              = API.Accept
    ext.Abandon             = API.Abandon
    ext.IsAccepted          = API.IsAccepted
    ext.IsComplete          = API.IsComplete
    ext.GetObjectives       = API.GetObjectives
    ext.SetObjectiveProgress = API.SetObjectiveProgress
    ext.AdvanceObjective    = API.AdvanceObjective
    ext.CompleteObjective   = API.CompleteObjective
    ext.SetTracked          = API.SetTracked
    ext.CompleteForGroup    = API.CompleteForGroup  -- auto-gateado por CanUseDMTools()
    ext.SetObjectiveProgressForGroup = API.SetObjectiveProgressForGroup  -- DM: progreso a la raid
    ext.CompleteObjectiveForGroup = API.CompleteObjectiveForGroup
    ext.GrantSharedRewardsForGroup = API.GrantSharedRewardsForGroup
end
