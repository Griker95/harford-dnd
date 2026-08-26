-- COLA DE AURAS PENDIENTES SOBRE NPC.
--
-- Poner o quitar un aura a un NPC exige tenerlo SELECCIONADO: el comando de servidor actua sobre el
-- objetivo actual y no hay forma de hacerlo en bloque. Eso choca con los contadores, que bajan de
-- golpe para todo un bando sin tocar a nadie: si a cinco enemigos les expira algo a la vez, el
-- numero desaparece al instante pero el icono se queda pegado.
--
-- Se apunta lo que falta y se ejecuta sola al seleccionar a ese NPC, que el DM va a hacer
-- igualmente porque le toca actuar.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local API = {}
local OBJETIVO, ES_JUGADOR, PERMISO, RETIRADAS, FALLA_SERVIDOR = nil, false, true, {}, false
local env = setmetatable({ HarfordDnDConditions = API }, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.select, env.next, env.error, env.assert = type, select, next, error, assert
env.table, env.string, env.math, env.pcall = table, string, math, pcall
env.setmetatable, env.print = setmetatable, function() end
env.HarfordClassColors = { NormalizeKey = function(v) return tostring(v or ""):lower() end,
    UnitFullName = function() return "" end, FindUnitByName = function() return nil end,
    StripAccents = function(v) return v end }
env.GetTime = function() return 1000 end
env.CreateFrame = function()
    local f = {}
    setmetatable(f, { __index = function() return function() end end })
    return f
end
env.UnitExists = function() return OBJETIVO ~= nil end
env.UnitIsPlayer = function() return ES_JUGADOR end
env.UnitGUID = function() return OBJETIVO end
env.HarfordAuthority = { CanUseOfficerCommands = function() return PERMISO end }
env.HarfordServerActions = {
    RemoveAura = function(id)
        if FALLA_SERVIDOR then return false end
        RETIRADAS[#RETIRADAS + 1] = id
        return true
    end,
    ApplyAuraToCurrentTarget = function() return true end,
}

local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
assert(pcall(f))
local C = env.HarfordDnDConditions

print("Se apunta lo que no se puede hacer ahora")
C.ClearPendingAuras()
chk("empieza vacia", C.GetPendingAuraCount(), 0)
C.QueueNpcAura("GUID-COBRA", 267937, "remove")
chk("se apunta", C.GetPendingAuraCount(), 1)
-- Apuntar dos veces lo mismo no anade nada: seria retirar el aura dos veces.
C.QueueNpcAura("GUID-COBRA", 267937, "remove")
chk("sin duplicados", C.GetPendingAuraCount(), 1)
-- Pero dos auras distintas del mismo bicho si son dos cosas.
C.QueueNpcAura("GUID-COBRA", 30900, "remove")
chk("dos auras distintas si", C.GetPendingAuraCount(), 2)
chk("un aura invalida no se apunta", (C.QueueNpcAura("GUID-COBRA", 0, "remove")), false)
chk("ni sin guid", (C.QueueNpcAura("", 5, "remove")), false)

print("Se ejecuta al seleccionar a ESE npc")
OBJETIVO, ES_JUGADOR, RETIRADAS = "GUID-OTRO", false, {}
chk("con otro delante, nada", C.FlushPendingAuras("target"), 0)
chk("y siguen apuntadas", C.GetPendingAuraCount(), 2)
OBJETIVO = "GUID-COBRA"
chk("con el delante, se hacen las dos", C.FlushPendingAuras("target"), 2)
chk("y la cola queda vacia", C.GetPendingAuraCount(), 0)
chk("se retiraron las dos auras", #RETIRADAS, 2)

print("Un jugador no entra en esta cola")
C.ClearPendingAuras()
C.QueueNpcAura("GUID-JUGADOR", 267937, "remove")
OBJETIVO, ES_JUGADOR = "GUID-JUGADOR", true
chk("no se le toca el aura", C.FlushPendingAuras("target"), 0)
ES_JUGADOR = false

-- Sin permiso se DEJA apuntado en vez de perderlo: otro con permiso podra hacerlo.
print("Sin permiso de oficial se conserva, no se pierde")
C.ClearPendingAuras()
C.QueueNpcAura("GUID-COBRA", 267937, "remove")
OBJETIVO, PERMISO = "GUID-COBRA", false
chk("no se ejecuta", C.FlushPendingAuras("target"), 0)
chk("pero sigue apuntada", C.GetPendingAuraCount(), 1)
PERMISO = true
chk("con permiso, ya", C.FlushPendingAuras("target"), 1)

-- Un fallo del servidor no puede tachar el recordatorio: se reintentara en la siguiente seleccion.
print("Si el servidor falla, no se tacha")
C.ClearPendingAuras()
C.QueueNpcAura("GUID-COBRA", 267937, "remove")
FALLA_SERVIDOR = true
chk("no cuenta como hecha", C.FlushPendingAuras("target"), 0)
chk("y sigue pendiente", C.GetPendingAuraCount(), 1)
FALLA_SERVIDOR = false
chk("al reintentar, se hace", C.FlushPendingAuras("target"), 1)

print("Se puede consultar cuanto queda, para poder decirlo")
C.ClearPendingAuras()
C.QueueNpcAura("GUID-A", 1, "remove")
C.QueueNpcAura("GUID-B", 2, "remove")
chk("total de dos bichos", C.GetPendingAuraCount(), 2)
chk("y por bicho", #(C.GetPendingAurasFor("GUID-A") or {}), 1)
chk("de uno sin nada, nada", (C.GetPendingAurasFor("GUID-Z")), "nil")

local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
print("Se dispara al cambiar de objetivo, como la cola de areas")
chk("engancha el evento", cond:find('events:RegisterEvent("PLAYER_TARGET_CHANGED")', 1, true) ~= nil, true)
chk("y vacia la cola", cond:find('API.FlushPendingAuras("target")', 1, true) ~= nil, true)
-- Se reusa la accion que ya existia; no hace falta uina nueva de servidor.
chk("reusa la accion existente", cond:find("HarfordServerActions.RemoveAura(p.auraId", 1, true) ~= nil, true)

-- ─── EFECTOS DELEGADOS AL LIDER ─────────────────────────────────────────────
-- Un jugador que no es oficial no puede bajarle la vida a un NPC ni ponerle un aura: el servidor
-- se lo rechaza. Pero SI puede tirar, calcular su dano y mitigarlo -- eso es del cliente. Asi que
-- resuelve todo y manda el EFECTO YA CALCULADO a quien puede emitir el comando.
--
-- No se delega la DECISION, solo la EJECUCION: el lider no vuelve a tirar ni a mitigar.
local sync = io.open("Harford/Core/HarfordSync.lua"):read("*a")
local ini = assert(sync:find("function HarfordSync.SerializeNpcEffect", 1, true))
local fin = assert(sync:find("function HarfordSync.BestChannel", ini, true))
local ent = { table = table, math = math, tostring = tostring, tonumber = tonumber,
    HarfordSync = {},
    strsplit = function(sep, s)
        local out = {}
        for trozo in (tostring(s) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do
            out[#out + 1] = trozo
        end
        return (table.unpack or unpack)(out)
    end }
local cargarS = loadstring or load
local fS
if setfenv then fS = assert(cargarS(sync:sub(ini, fin - 1))); setfenv(fS, ent)
else fS = assert(cargarS(sync:sub(ini, fin - 1), "t", "t", ent)) end
fS()
local SY = ent.HarfordSync

print("El efecto delegado va y vuelve")
chk("se compone", SY.SerializeNpcEffect("Creature-1", "damage", 7, "Deryk"),
    "DNDNPCDO|Creature-1|damage|7|Deryk")
local g, tp, v, a = SY.DeserializeNpcEffect("DNDNPCDO|Creature-1|damage|7|Deryk")
chk("y se lee el guid", g, "Creature-1")
chk("el tipo", tp, "damage")
chk("la cantidad", v, 7)
chk("y quien lo mando", a, "Deryk")
-- Sin guid no hay a quien aplicarselo, y un mensaje de otro opcode no debe colarse.
chk("sin guid se rechaza", (SY.DeserializeNpcEffect("DNDNPCDO||damage|7|X")), "nil")
chk("otro opcode no se confunde", (SY.DeserializeNpcEffect("DNDCOND|algo")), "nil")
-- El valor se normaliza a entero: media vida no existe en el comando de servidor.
chk("la cantidad se entera", select(3, SY.DeserializeNpcEffect(
    SY.SerializeNpcEffect("Creature-1", "damage", 7.8, "X"))), 7)

print("La cola distingue dano de aura")
-- Dos golpes de 7 son catorce, no siete: el dano se SUMA, al reves que las auras, donde repetir
-- la misma no anade nada.
chk("el dano se suma en una sola entrada",
    cond:find("p.cantidad = p.cantidad + cantidad", 1, true) ~= nil, true)
chk("y las auras siguen sin duplicarse",
    cond:find("if p.auraId == auraId and p.op == op then return true end", 1, true) ~= nil, true)
chk("el dano llega ya mitigado y no se recalcula",
    cond:find("SetNpcHealthDelta(-math.abs(p.cantidad)", 1, true) ~= nil, true)

print("Quien puede lo hace; quien no, lo delega")
chk("hay punto unico", cond:find("function API.AplicarEfectoNpc", 1, true) ~= nil, true)
chk("se manda al lider", cond:find("local function NombreDelLider", 1, true) ~= nil, true)
-- Recibirlo sin poder emitirlo seria acumular trabajo que no se hara, y ademas dejaria creer al
-- que lo mando que esta resuelto.
chk("no se acepta si no puedo emitirlo",
    cond:find("if not API.PuedoAplicarEnNpc() then return false end", 1, true) ~= nil, true)
-- Y solo sobre NPCs que la mesa ya conoce: si no, cualquiera podria pedir dano sobre cualquier cosa.
chk("y solo sobre NPCs de la lista de turnos",
    cond:find("if not EsNpcDeLosTurnos(guid) then return false end", 1, true) ~= nil, true)
chk("el remitente tiene que ser de fiar",
    cond:find("if IsTrustedSender(sender) then API.RecibirEfectoNpc", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
