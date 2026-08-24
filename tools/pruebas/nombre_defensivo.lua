-- De quien es la tirada: tuya o de la ficha que tengas cargada.
--
-- `GetDisplayName` antepone el `rollName` del contexto de ficha. Con una ficha de NPC aplicada -- lo
-- normal en modo DM -- eso hace que TODAS las tiradas del cliente salgan a nombre del NPC,
-- incluidas las DEFENSIVAS del propio jugador: se veia "test Recibido: 9 Perforante" cuando quien
-- recibia el golpe era Gmaster.
--
-- Esas lineas hablan de lo que te pasa a TI, asi que van con `GetOwnName`, que no mira la ficha.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")
local i = assert(src:find("function HarfordDnDRolls.GetOwnName", 1, true))
local j = assert(src:find("\n-- Emision comun de habilidades", i, true))
local codigo = "local HarfordDnDRolls, HarfordDnDContext, HarfordTRP3, UnitName = ...\n"
    .. src:sub(i, j) .. "\nreturn HarfordDnDRolls"

local R = {}
local ctx = { State = {} }
local trp = { GetUnitRPName = function() return nil end }
local function nombreWow() return "Griker" end
local f
local env = { tostring = tostring }
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
f(R, ctx, trp, nombreWow)

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = real == esp
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-48s %-14s %s", etiqueta, "'" .. tostring(real) .. "'",
        ok and "ok" or ("FALLA, esperaba '" .. tostring(esp) .. "'")))
end

print("Sin ficha aplicada los dos dan lo mismo")
chk("propio", R.GetOwnName(), "Griker")
chk("de presentacion", R.GetDisplayName(), "Griker")

print("Con nombre de rol de TRP3, gana el de rol")
trp.GetUnitRPName = function() return "Griker Vaughn" end
chk("propio", R.GetOwnName(), "Griker Vaughn")
chk("de presentacion", R.GetDisplayName(), "Griker Vaughn")

print("Con ficha de NPC cargada (modo DM) es donde se separan")
ctx.State.rollName = "test"
chk("de presentacion: la ficha", R.GetDisplayName(), "test")
chk("propio: TU, no la ficha", R.GetOwnName(), "Griker Vaughn")

print("Sin TRP3 cae al nombre del personaje")
trp.GetUnitRPName = function() return "" end
chk("propio", R.GetOwnName(), "Griker")
chk("de presentacion sigue siendo la ficha", R.GetDisplayName(), "test")

print("Las rutas defensivas piden el nombre propio")
local dnd = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
local wr = io.open("Harford/DnD/Engine/HarfordDnDWeaponRolls.lua"):read("*a")
local ar = io.open("Harford/DnD/Engine/HarfordDnDArea.lua"):read("*a")
chk("dano recibido", dnd:find("player = HarfordDnDRolls.GetOwnName", 1, true) ~= nil, true)
chk("salvacion pedida", wr:find("player = HarfordDnDRolls.GetOwnName", 1, true) ~= nil, true)
chk("resolucion de area del defensor", ar:find("BroadcastInfo(label, sender, true)", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
