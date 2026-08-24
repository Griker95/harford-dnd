-- Estados de UN SOLO USO: valen para una tirada y se retiran al hacerla.
--
-- Esto estaba cableado dentro del calculo de la tirada como un `if` con el id de Palabra de Poder:
-- Fortaleza, asi que el Brebaje del Buey Negro del Monje ("ventaja en tu proximo ataque") no tenia
-- forma de existir sin escribir otro `if`. Ahora lo declara cada condicion y el calculo solo
-- pregunta. Lo que se prueba es que pregunte por el TIPO de tirada correcto: si Fortaleza se
-- gastase en un ataque, el jugador perderia su ventaja en la salvacion sin enterarse.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local i = assert(src:find("function API.ConditionsToConsumeAfterRoll"))
local j = assert(src:find("\nfunction API.GetDamageStatus", i))
local codigo = src:sub(i, j) .. "\nreturn API.ConditionsToConsumeAfterRoll"

-- Catalogo real: se leen las declaraciones del propio fichero, no una copia.
local function declara(id, tipo)
    local k = src:find("    " .. id .. " = {", 1, true)
    if not k then return nil end
    local fin = src:find("\n    },", k) or (k + 900)
    local bloque = src:sub(k, fin)
    local c = bloque:match("consumeAfterRoll = %{([^}]*)%}")
    if not c then return false end
    return c:find(tipo .. " = true", 1, true) ~= nil
end

local ACTIVOS = {}
local API = {}
API.GetActive = function() return ACTIVOS end
local env = { ipairs = ipairs, type = type, API = API }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Consumir = f()

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-10s %s", etiqueta, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("El catalogo real declara que se gasta y con que tirada")
chk("palabra_fortaleza en salvacion", declara("palabra_fortaleza", "save"), true)
chk("palabra_fortaleza NO en ataque", declara("palabra_fortaleza", "attack"), false)
chk("buey_negro en ataque", declara("buey_negro", "attack"), true)
chk("buey_negro NO en salvacion", declara("buey_negro", "save"), false)
print("  -- un estado normal no se gasta con ninguna tirada:")
chk("stunned no declara consumo", declara("stunned", "attack"), false)
chk("escudo_sagrado no declara consumo", declara("escudo_sagrado", "attack"), false)

print("Seleccion por tipo de tirada")
local FORT = { id = "palabra_fortaleza", definition = { consumeAfterRoll = { save = true } } }
local BUEY = { id = "buey_negro", definition = { consumeAfterRoll = { attack = true } } }
local ATUR = { id = "stunned", definition = { effects = {} } }

ACTIVOS = { FORT, BUEY, ATUR }
chk("salvacion gasta solo Fortaleza", table.concat(Consumir("save"), ","), "palabra_fortaleza")
chk("ataque gasta solo Buey Negro", table.concat(Consumir("attack"), ","), "buey_negro")
chk("habilidad no gasta nada", #Consumir("skill"), 0)
chk("sin tipo de tirada no gasta nada", #Consumir(nil), 0)

ACTIVOS = { ATUR }
chk("sin estados de un uso no gasta nada", #Consumir("attack"), 0)

ACTIVOS = {}
chk("sin estados activos", #Consumir("save"), 0)

-- Uno que sirva para las dos: se gasta con cualquiera de ellas, pero solo una vez.
ACTIVOS = { { id = "doble", definition = { consumeAfterRoll = { save = true, attack = true } } } }
chk("declarado para dos tipos, ataque", table.concat(Consumir("attack"), ","), "doble")
chk("declarado para dos tipos, salvacion", table.concat(Consumir("save"), ","), "doble")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
