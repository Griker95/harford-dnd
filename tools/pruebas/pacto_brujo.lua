-- Espacios de PACTO del brujo con cuenta propia.
--
-- El fallo que arregla: estaban fusionados con los normales de su nivel, asi que el descanso corto
-- no sabia de quien eran los gastados. Un Brujo 2 / Mago 3 que gastara espacios DEL MAGO recuperaba
-- dos en cada descanso corto. En brujo puro nunca se noto porque todos eran suyos.
--
-- La regla al gastar: PRIMERO la ranura de pacto. No es preferencia -- vuelve con el descanso corto
-- y la normal con el largo, asi que es estrictamente mejor y no hay que preguntarle nada al jugador.
local cargar = loadstring or load

local PACTO = { count = 0, level = 0 }
local NORMAL = {}
local pactSpent = 0
HarfordDnDProgression = {
    GetSpellSlotsSpent = function(n) return NORMAL[n] or 0 end,
    SetSpellSlotsSpent = function(n, v) NORMAL[n] = v end,
    GetPactSpent = function() return pactSpent end,
    SetPactSpent = function(v) pactSpent = math.max(0, v) return pactSpent end,
    GetSpellSlotsBonus = function() return 0 end,
}
local MAXIMOS = {}
local API = {}
API.GetPactSlots = function() return PACTO.count, PACTO.level end
API.GetSpellSlotMax = function(n) return (MAXIMOS[n] or 0) + ((n == PACTO.level) and PACTO.count or 0) end
API.CanSpendSpellSlot = function(n)
    local c = API.GetSpellSlotCurrent(n)
    if API.GetSpellSlotMax(n) <= 0 then return false, "sin espacios" end
    if c <= 0 then return false, "agotados" end
    return true, c, API.GetSpellSlotMax(n)
end

local src = io.open("Harford/DnD/State/HarfordDnDMana.lua"):read("*a")
local piezas = {}
for _, n in ipairs({ "GetSpellSlotCurrent", "GetPactSpent", "SpendSpellSlot" }) do
    local i = assert(src:find("function API%." .. n .. "%("), n)
    local j = assert(src:find("\nend", i))
    piezas[#piezas+1] = src:sub(i, j + 4)
end
local env = { API = API, HarfordDnDProgression = HarfordDnDProgression, math = math,
              tonumber = tonumber, select = select, ipairs = ipairs }
local f
local codigo = table.concat(piezas, "\n")
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "pacto", "t", env)) end
f()

local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
local function descansoCorto() HarfordDnDProgression.SetPactSpent(0) end

print("Brujo PURO: 2 ranuras de pacto de nivel 1, nada mas")
PACTO, MAXIMOS, NORMAL, pactSpent = { count = 2, level = 1 }, {}, {}, 0
chk("maximo de nivel 1", API.GetSpellSlotMax(1), 2)
chk("disponibles", API.GetSpellSlotCurrent(1), 2)
API.SpendSpellSlot(1)
chk("tras gastar una", API.GetSpellSlotCurrent(1), 1)
chk("  y salio del pacto", pactSpent, 1)
chk("  no del pool normal", NORMAL[1] or 0, 0)
API.SpendSpellSlot(1)
descansoCorto()
chk("descanso corto las devuelve todas", API.GetSpellSlotCurrent(1), 2)

print("Brujo 2 / Mago 3: 2 de pacto + 4 del mago, nivel 1")
PACTO, MAXIMOS, NORMAL, pactSpent = { count = 2, level = 1 }, { [1] = 4 }, {}, 0
chk("maximo combinado", API.GetSpellSlotMax(1), 6)
for _ = 1, 3 do API.SpendSpellSlot(1) end
chk("gastadas 3, quedan 3", API.GetSpellSlotCurrent(1), 3)
chk("  2 del pacto (se gastan primero)", pactSpent, 2)
chk("  1 del mago", NORMAL[1] or 0, 1)
descansoCorto()
chk("descanso corto: vuelven las 2 del pacto", API.GetSpellSlotCurrent(1), 5)
chk("  la del mago sigue gastada", NORMAL[1] or 0, 1)

print("EL BUG DE ANTES: gastar solo espacios del mago")
PACTO, MAXIMOS, NORMAL, pactSpent = { count = 2, level = 1 }, { [1] = 4 }, {}, 0
-- Agotar primero el pacto y descansar, para llegar a un estado donde solo queda gasto del mago.
API.SpendSpellSlot(1); API.SpendSpellSlot(1); descansoCorto()
pactSpent = 0
NORMAL[1] = 3
chk("3 gastadas, todas del mago", API.GetSpellSlotCurrent(1), 3)
descansoCorto()
chk("el descanso corto NO le regala ninguna", API.GetSpellSlotCurrent(1), 3)

print("Fuera del nivel de pacto no cuenta nada")
chk("nivel 2 no tiene pacto", API.GetPactSpent(2), 0)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
