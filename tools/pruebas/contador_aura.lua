-- CONTADOR sobre el icono de un aura.
--
-- En Epsilon no se pueden aplicar auras CON acumulaciones, asi que el numero no puede salir del
-- aura: lo lleva Harford en la instancia de la condicion y se pinta encima del icono nativo.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
-- Desde `CounterFor`: es la regla del numero, y `GetAuraCounter` la reutiliza en vez de repetirla.
local i = assert(src:find("function API.CounterFor", 1, true))
local j = assert(src:find("function API.SetVar", i, true))
local codigo = "local API = ...\n" .. src:sub(i, j - 1) .. "\nreturn API.GetAuraCounter"

local ACTIVAS = {}
local API = { GetActive = function() return ACTIVAS end }
local env = { ipairs = ipairs, tonumber = tonumber, math = math }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Contador = f(API)

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("Sin condiciones no hay numero")
chk("nada", Contador("player", 267937), "nil")

print("La condicion se busca por el AURA, no por su id")
ACTIVAS = { { definition = { auraId = 267937 }, record = { vars = { contador = 3 } } } }
chk("acierta el aura", Contador("player", 267937), 3)
chk("otro aura distinto", Contador("player", 30900), "nil")
chk("sin spellId", Contador("player", nil), "nil")

print("1 o menos NO se pinta: un '1' encima de un icono no dice nada")
ACTIVAS = { { definition = { auraId = 267937 }, record = { vars = { contador = 1 } } } }
chk("uno", Contador("player", 267937), "nil")
ACTIVAS = { { definition = { auraId = 267937 }, record = { vars = { contador = 0 } } } }
chk("cero", Contador("player", 267937), "nil")
ACTIVAS = { { definition = { auraId = 267937 }, record = { vars = { contador = 2 } } } }
chk("dos si", Contador("player", 267937), 2)

print("Una condicion con NIVELES usa su nivel como contador")
ACTIVAS = { { definition = { auraId = 999, leveled = true }, record = { level = 4 } } }
chk("cansancio 4", Contador("player", 999), 4)
ACTIVAS = { { definition = { auraId = 999, leveled = true }, record = { level = 1 } } }
chk("nivel 1 no se pinta", Contador("player", 999), "nil")

print("Una condicion sin contador no pinta nada aunque tenga aura")
ACTIVAS = { { definition = { auraId = 30900 }, record = {} } }
chk("sin vars", Contador("player", 30900), "nil")

print("Con varias activas, coge la del aura preguntada")
ACTIVAS = {
    { definition = { auraId = 30900 }, record = { vars = { contador = 9 } } },
    { definition = { auraId = 267937 }, record = { vars = { contador = 4 } } },
}
chk("la primera", Contador("player", 30900), 9)
chk("la segunda", Contador("player", 267937), 4)

print("Se pinta desde la ruta que Blizzard reaplica")
local uf = io.open("Harford/Frames/HarfordUnitFrames.lua"):read("*a")
chk("dentro de ApplyAuraButtonData", uf:find("PintarContadorAura(button, unit, aura)", 1, true) ~= nil, true)
chk("colgado del propio boton, sin frames nuevos",
    uf:find("button._harfordContador = fs", 1, true) ~= nil, true)



-- QUE PASA SI EL TARGET SE PONE O SE QUITA UN AURA.
--
-- El numero NO se recuerda por boton: se recalcula del `spellId` del aura que hay en ese boton en
-- ese momento. Por eso al desplazarse los indices sigue al aura y no se queda pegado al hueco.
print("El numero sigue al aura, no al boton")
ACTIVAS = {
    { definition = { auraId = 30900 }, record = { vars = { contador = 9 } } },
    { definition = { auraId = 267937 }, record = { vars = { contador = 4 } } },
}
-- Debuff1 tenia el 30900 y ahora, tras entrar otra aura, tiene el 267937.
chk("antes, en ese hueco", Contador("player", 30900), 9)
chk("despues, en el mismo hueco", Contador("player", 267937), 4)
chk("un aura que no es de Harford no lleva numero", Contador("player", 12345), "nil")

local uf2 = io.open("Harford/Frames/HarfordUnitFrames.lua"):read("*a")
chk("se reprocesan TODOS los botones visibles",
    uf2:find("ApplyAuraButtonData(_G[prefix ..", 1, true) ~= nil, true)
chk("y se ocultan los sobrantes", uf2:find("if button.Hide then button:Hide() end", 1, true) ~= nil, true)

-- Y al reves: el contador puede cambiar SIN que cambie ninguna aura, y ahi UNIT_AURA no dispara.
print("Y si cambia el numero sin cambiar el aura, tambien se repinta")
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
chk("el motor avisa a los unitframes",
    cond:find("HarfordUnitFrames.RefreshAuraCounters()", 1, true) ~= nil, true)
chk("y existe donde avisar", uf2:find("function API.RefreshAuraCounters", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
