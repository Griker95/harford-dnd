-- TODA condicion definida tiene que ser RECORRIBLE.
--
-- `API.ORDER` es el orden de presentacion, pero `GetActive` tambien lo usa para recorrer las
-- condiciones. Eso convierte una lista de presentacion en una lista de existencia: una condicion
-- definida y no listada no aparece como activa nunca, y sus efectos no se aplican jamas. No falla,
-- no avisa y compila igual. Paso nueve veces, seis sin que nadie lo notara.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local API = { DEFS = {}, ORDER = {} }
-- Se ejecuta el fichero de verdad para que la completacion corra, con un entorno minimo.
local cargar = loadstring or load
local env = setmetatable({ HarfordDnDConditions = API, ipairs = ipairs, pairs = pairs,
    table = table, tostring = tostring, tonumber = tonumber, math = math, string = string,
    type = type, select = select, unpack = unpack, setmetatable = setmetatable, next = next,
    error = error, assert = assert, print = function() end }, { __index = function() return nil end })
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
pcall(f)
API = env.HarfordDnDConditions

local definidas, enOrden = 0, {}
for _ in pairs(API.DEFS) do definidas = definidas + 1 end
for _, id in ipairs(API.ORDER) do enOrden[id] = true end

local faltan = {}
for id in pairs(API.DEFS) do
    if not enOrden[id] then faltan[#faltan + 1] = id end
end
table.sort(faltan)

print("Ninguna condicion se queda fuera del recorrido")
chk("hay condiciones", definidas > 0, true)
chk("y todas son recorribles", #faltan, 0)
for _, id in ipairs(faltan) do print("     invisible: " .. id) end

-- Las que si estan declaradas conservan su sitio: el orden de la tira no es alfabetico.
print("El orden declarado se respeta; lo que falte se anade al final")
chk("la primera sigue siendo la declarada", API.ORDER[1], "blinded")
chk("sin duplicados", #API.ORDER, definidas)

-- Y la completacion es estable: dos cargas dan el mismo orden, o la tira bailaria entre sesiones.
print("Y el orden es estable entre cargas")
chk("se ordena antes de anadir", src:find("table.sort(resto)", 1, true) ~= nil, true)

-- ─── LAS CATEGORIAS CUBREN EL CATALOGO ENTERO, SIN SOLAPES NI FANTASMAS ────
-- El menu DM lista los estados POR CATEGORIA: una id fuera de toda categoria desaparece del
-- menu en silencio, y una id en dos categorias sale duplicada. Un id fantasma en una categoria
-- es una fila muerta.
print("Las categorias cubren el catalogo entero")
local vistos, dobles, fantasmas = {}, {}, {}
local totalCat = 0
for _, cat in ipairs(API.CATEGORIES or {}) do
    for _, id in ipairs(cat.ids or {}) do
        totalCat = totalCat + 1
        if vistos[id] then dobles[#dobles + 1] = id end
        vistos[id] = true
        if not API.DEFS[id] then fantasmas[#fantasmas + 1] = cat.id .. ":" .. id end
    end
end
local huerfanos = {}
for _, id in ipairs(API.ORDER) do
    if not vistos[id] then huerfanos[#huerfanos + 1] = id end
end
chk("hay categorias", (API.CATEGORIES and #API.CATEGORIES or 0) > 0, true)
chk("toda id de ORDER esta en una categoria", table.concat(huerfanos, ","), "")
chk("ninguna id en dos categorias", table.concat(dobles, ","), "")
chk("ninguna categoria con ids fantasma", table.concat(fantasmas, ","), "")
chk("y no hay ids extra fuera de ORDER", totalCat, #API.ORDER)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
