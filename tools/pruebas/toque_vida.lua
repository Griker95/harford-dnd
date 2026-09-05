-- TOQUE DE VIDA del Brujo: lanzar sin mana pagando con salud (nivel + nivel del espacio).
--
-- Lo que sella: (1) cubre "NO ME LLEGA", no solo mana a cero — con 2/4 de mana antes no podias
-- ni pagar ni sacrificar vida (decision de mesa 2026-09-05); el sacrificio paga el lanzamiento
-- ENTERO y el mana restante no se toca; (2) el "1 vez por descanso largo" del rasgo SE GASTA al
-- pagar y se comprueba en la disponibilidad — antes el contador existia pero nadie lo consumia,
-- asi que era decorativo y el sacrificio era infinito; (3) si el mana LLEGA, se paga normal y el
-- sacrificio ni se ofrece; (4) no te puedes matar con el: exige salud ESTRICTAMENTE mayor que el
-- coste; (5) solo en modo mana (en slots no esta cableado) y solo conjuros de nivel 1+.

local cargar = loadstring or load
local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local core = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")

-- ─── LA FUNCION REAL, extraida y ejercitada con stubs ───────────────────────
local bloque = core:match("(local function IsWarlockLifeTapAvailable.-\nend\n)")
chk("la funcion existe", bloque ~= nil, true)

local MODO, MANA, COSTE, NIVEL_CAST = "mana", 0, 4, 1
local SPENT, SALUD, TOQUE = 0, 30, { id = "bru_toque_vida", uses = { max = 1, recharge = "long" } }
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string = type, math, table, string
env.API = {
    GetSpellCostMode = function() return MODO end,
    GetManaCurrent = function() return MANA end,
    GetSpellCost = function() return COSTE end,
    GetCastLevel = function() return NIVEL_CAST end,
}
env.HarfordDnDProgression = {
    GetUnlockedFeatures = function() return { { feature = TOQUE } } end,
    IsFeatureEnabled = function() return true end,
    GetTotalLevel = function() return 3 end,
}
env.HarfordDnDFeatureUses = {
    GetMax = function(uses) return (uses and uses.max) or 0 end,
    GetSpent = function() return SPENT end,
}
env.HarfordDnDStore = { GetResourceCurrent = function() return SALUD end }
env.HarfordClassColors = { UnitFullName = function() return "Yo" end }
local fn
if bloque then
    local srcFn = bloque .. "\nreturn IsWarlockLifeTapAvailable"
    local chunk
    if setfenv then chunk = assert(cargar(srcFn)); setfenv(chunk, env)
    else chunk = assert(cargar(srcFn, "t", "t", env)) end
    fn = chunk()
end
local conjuro = { level = 1 }

print("Cubre 'no me llega', no solo mana a cero")
MANA = 2
local ok, hp = fn(conjuro)
chk("con 2/4 de mana se puede sacrificar", ok, true)
chk("y el coste es nivel total + nivel del espacio", hp, 4)  -- 3 + 1
MANA = 0
chk("con mana a cero tambien (caso de siempre)", (fn(conjuro)), true)
MANA = 4
chk("si el mana LLEGA, ni se ofrece: se paga normal", (fn(conjuro)), false)
MANA = 5
chk("y con mana de sobra tampoco", (fn(conjuro)), false)

print("El 1/descanso largo del rasgo se respeta")
MANA, SPENT = 0, 1
chk("sin usos no hay sacrificio", (fn(conjuro)), false)
SPENT = 0
chk("con el uso disponible si", (fn(conjuro)), true)

print("Guardas de siempre")
SALUD = 4
chk("no te puedes matar con el (salud > coste, estricto)", (fn(conjuro)), false)
SALUD = 30
MODO = "slots"
chk("en modo slots no esta cableado", (fn(conjuro)), false)
MODO = "mana"
chk("un truco no gasta espacio: no aplica", (fn({ level = 0 })), false)

-- ─── EL PAGO GASTA EL USO Y AVISA ───────────────────────────────────────────
print("El pago consume el uso del rasgo")
chk("Spend en el punto unico de pago",
    core:find('HarfordDnDFeatureUses.Spend("bru_toque_vida"', 1, true) ~= nil, true)
chk("y se avisa en local de la salud perdida",
    core:find('"Toque de vida: -" .. tostring(hpCost)', 1, true) ~= nil, true)
-- El envoltorio de Cargas Arcanas no debe tragarse el quinto valor (la marca lifeTap).
chk("el wrapper de SpendSpellMana pasa los cinco valores",
    core:find("return ok, a, b, c, d", 1, true) ~= nil, true)
-- Y la disponibilidad (boton/preview) usa la MISMA funcion que el pago: si divergieran, el
-- boton diria "Toque de Vida" y el pago fallaria, o al reves.
local n = 0
for _ in core:gmatch("= IsWarlockLifeTapAvailable%(spell, options%)") do n = n + 1 end
chk("preview y pago comparten la funcion (2 llamadas)", n, 2)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
