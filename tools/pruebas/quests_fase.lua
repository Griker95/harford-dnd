-- DEFINICIONES DE QUEST DE MUNDO EN LA FASE (PhaseAddonData) — el modulo real con stubs.
--
-- Lo que sella: (1) la def de FASE (HARFORD_WQ_<tid>) pisa a la inline de un ArcSpell viejo —
-- es la editable; (2) una def vacia ({} escrito al retirar) NO cuenta como def; (3) se consulta
-- UNA vez por NPC y fase (force la salta); (4) publicar exige herramientas DM, escribe la clave
-- y actualiza el indice HARFORD_WQ_INDEX; retirar escribe {} y limpia runtime e indice; (5) una
-- lectura contestada tras CAMBIAR de fase se descarta; (6) el ArcSpell generico (OpenWorldQuest)
-- esta exportado para ArcSpells y el gossip dispara el fetch aunque haya def inline.

local cargar = loadstring or load
local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-60s %-12s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── Entorno ────────────────────────────────────────────────────────────────
local FASE = "fase-A"
local ALMACEN = {}          -- lo escrito en la "fase"
local LECTURA_DIFERIDA      -- si se fija, LoadTable guarda el callback en vez de contestar
local ESCRITAS = {}

local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tostring, env.tonumber = ipairs, pairs, tostring, tonumber
env.type, env.table, env.string, env.math, env.select = type, table, string, math, select
env.setmetatable, env.next, env.pcall, env.error, env.assert = setmetatable, next, pcall, error, assert
env.unpack = table.unpack or unpack
env._G = env
env.strsplit = function(sep, s)
    local out = {}
    for p in (tostring(s) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do out[#out + 1] = p end
    return (table.unpack or unpack)(out)
end
env.CreateFrame = function()
    local f = {}
    setmetatable(f, { __index = function() return function() end end })
    return f
end
env.C_Timer = { After = function() end }
env.SlashCmdList = {}
env.UnitName = function() return "DM" end
env.UnitExists = function() return false end
env.UnitGUID = function() return nil end
env.HarfordChat = { Print = function() end }
env.HarfordAuthority = { CanUseDMTools = function() return env._ES_DM == true end,
    IsOfficerPlus = function() return false end }
env.C_Epsilon = { GetPhaseId = function() return FASE end, GetPhaseAddonData = function() end }
env.EpsilonLib = { PhaseAddonData = {
    SaveTable = function(clave, tabla)
        ALMACEN[clave] = tabla
        ESCRITAS[#ESCRITAS + 1] = clave
    end,
    LoadTable = function(clave, cb)
        if LECTURA_DIFERIDA then LECTURA_DIFERIDA = { clave = clave, cb = cb } return end
        cb(ALMACEN[clave])
    end,
} }

local src = io.open("Harford/Quests/HarfordWorldQuests.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
assert(pcall(f))
local WQ = env.HarfordWorldQuests

-- ─── (1) LA FASE PISA A LA INLINE ───────────────────────────────────────────
print("La def de fase manda sobre la inline")
WQ.DefineWorldQuest({ id = "vieja", npc = 700, title = "Inline del ArcSpell" })
ALMACEN["HARFORD_WQ_700"] = { id = "wq_700", npc = 700, title = "Editada en fase" }
local recibida
WQ.FetchPhaseDef(700, function(d) recibida = d end)
chk("la fase contesta", recibida and recibida.title, "Editada en fase")
chk("queda marcada como de fase", recibida.fromPhase, true)
-- Que PISO el registro runtime lo prueba la rama cacheada de abajo: sin force devuelve
-- byNpc[tid], y si sale el titulo de fase es que la inline ya no esta.

-- ─── (3) UNA CONSULTA POR NPC Y FASE ────────────────────────────────────────
print("Se consulta una vez por NPC y fase")
ALMACEN["HARFORD_WQ_700"] = { id = "wq_700", npc = 700, title = "Cambiada otra vez" }
recibida = nil
WQ.FetchPhaseDef(700, function(d) recibida = d end)
chk("sin force devuelve la cacheada", recibida and recibida.title, "Editada en fase")
WQ.FetchPhaseDef(700, function(d) recibida = d end, true)
chk("con force re-lee del servidor", recibida and recibida.title, "Cambiada otra vez")

-- ─── (2) UNA DEF VACIA NO CUENTA ────────────────────────────────────────────
print("Def vacia = no hay quest")
ALMACEN["HARFORD_WQ_701"] = {}
recibida = "sin-tocar"
WQ.FetchPhaseDef(701, function(d) recibida = d end)
chk("el callback recibe nil", recibida == nil, true)

-- ─── (4) PUBLICAR Y RETIRAR (DM) ────────────────────────────────────────────
print("Publicar exige DM y escribe clave + indice")
env._ES_DM = false
local ok, err = WQ.PublishWorldQuest({ id = "wq_702", npc = 702, title = "Nueva" })
chk("sin DM se rechaza", ok, false)
env._ES_DM = true
ok = WQ.PublishWorldQuest({ id = "wq_702", npc = 702, title = "Nueva" })
chk("con DM publica", ok, true)
chk("escribe su clave", ALMACEN["HARFORD_WQ_702"] and ALMACEN["HARFORD_WQ_702"].title, "Nueva")
chk("y el indice apunta al titulo", ALMACEN["HARFORD_WQ_INDEX"] and ALMACEN["HARFORD_WQ_INDEX"]["702"], "Nueva")
ok = WQ.PublishWorldQuest({ id = "", npc = 703 })
chk("una def invalida se rechaza", ok, false)

print("Retirar escribe {} y limpia indice")
ok = WQ.DeleteWorldQuest(702)
chk("retira", ok, true)
chk("la clave queda vacia", next(ALMACEN["HARFORD_WQ_702"] or { x = 1 }), nil)
chk("y sale del indice", (ALMACEN["HARFORD_WQ_INDEX"] or {})["702"], nil)

-- ─── (5) CAMBIO DE FASE DURANTE LA LECTURA ──────────────────────────────────
print("Una lectura que llega tras cambiar de fase se descarta")
ALMACEN["HARFORD_WQ_704"] = { id = "wq_704", npc = 704, title = "De la fase A" }
LECTURA_DIFERIDA = true
recibida = "sin-tocar"
WQ.FetchPhaseDef(704, function(d) recibida = d end)
local pendiente = LECTURA_DIFERIDA
LECTURA_DIFERIDA = nil
FASE = "fase-B"
pendiente.cb(ALMACEN[pendiente.clave])
chk("el dato de la fase A no entra en la B", recibida == nil, true)
FASE = "fase-A"

-- ─── (6) CABLEADO ───────────────────────────────────────────────────────────
print("ArcSpell generico y disparo desde el gossip")
chk("OpenWorldQuest exportado para ArcSpells", type(env.HarfordQuestAPI.OpenWorldQuest), "function")
chk("el gossip consulta la fase aunque haya def inline",
    src:find("if tid and API.FetchPhaseDef then API.FetchPhaseDef(tid) end", 1, true) ~= nil, true)
chk("el editor DM existe", type(WQ.OpenWorldQuestEditor), "function")
chk("questarc tiene modo generico",
    io.open("HarfordDebug/HarfordDebug.lua"):read("*a"):find('id == "generic"', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
