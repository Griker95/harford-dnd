-- Estilos de combate CONDICIONALES: el flag se declara en los datos y se consume en el motor
-- CON su contexto. El defecto que esto sella: eran bonos globales -- Tiro con Arco sumaba +2
-- tambien cuerpo a cuerpo, Duelo con cualquier arma y Defensa desnudo.
local cargar = loadstring or load
local fallos = 0
local function chk(nombre, real, esperado)
    if real ~= esperado then
        fallos = fallos + 1
        print("  FALLO " .. nombre .. ": " .. tostring(real) .. " ~= " .. tostring(esperado))
    else
        print("  ok " .. nombre)
    end
end

-- ── DATOS: toda opcion de estilo condicional declara flag, nunca bono pelado ──
print("Los estilos condicionales son flags en los datos")
local CONDICIONALES = { defensa = true, duelo = true, duelos = true, tiro_arco = true, tirador = true }
local FLAGS = { styleDefense = 0, styleDueling = 0, styleArchery = 0, styleSharpshooter = 0 }
local pelados = {}
for fichero in ("CaballerodelaMuerte Cazador Guerrero Paladin"):gmatch("%S+") do
    local src = io.open("Harford/DnD/Data/Classes/" .. fichero .. ".lua"):read("*a")
    for linea in src:gmatch("[^\n]+") do
        local id = linea:match('id = "([a-z_]+)"')
        if id and (CONDICIONALES[id] or id:find("doble_empu", 1, true) == 1) then
            local flag = linea:match('kind = "flag", flag = "(style%w+)"')
            if flag then
                FLAGS[flag] = (FLAGS[flag] or 0) + 1
            elseif linea:find('kind = "bonus"', 1, true) then
                pelados[#pelados + 1] = fichero .. ":" .. id
            end
        end
    end
end
chk("ningun estilo con bono pelado", table.concat(pelados, ","), "")
chk("Defensa declarada en 3 clases", FLAGS.styleDefense, 3)
chk("Duelo declarado en 3 clases", FLAGS.styleDueling, 3)
chk("Tiro con Arco en 2 clases", FLAGS.styleArchery, 2)
chk("Tirador en 2 clases", FLAGS.styleSharpshooter, 2)

-- ── MOTOR: Calc consume los flags con el arma delante ──
print("Calc suma cada flag solo con su contexto")
local desempaquetar = unpack or table.unpack
local src = io.open("Harford/DnD/Engine/HarfordDnDCalc.lua"):read("*a")
HarfordDnDCalc = {}
HarfordDnDContext = { State = {} }
local flagsActivos = {}
HarfordDnDFeatureEffects = {
    GetBonus = function() return 0 end,
    HasFlag = function(f) return flagsActivos[f] == true end,
}
HarfordDnDItems = { HasOffhandCombatItem = function() return flagsActivos.__offhand == true end }
local function extraer(nombre)
    local i = src:find("function HarfordDnDCalc%." .. nombre .. "%(")
    local j = src:find("\nend", i)
    assert(i and j, nombre)
    assert(cargar("local function IsNpcContext() return false end\n" .. src:sub(i, j + 4)))()
end
extraer("GetWeaponAttackBonus")
extraer("GetWeaponDamageBonus")
local A, D = HarfordDnDCalc.GetWeaponAttackBonus, HarfordDnDCalc.GetWeaponDamageBonus

local distancia = { mode = "Ranged", props = { "Municion", "Dos manos" } }
local unaMano = { mode = "Melee", props = {} }
local dosManos = { mode = "Melee", props = { "Pesada", "Dos manos" } }

chk("sin flags nadie suma", A(distancia) + D(unaMano), 0)

flagsActivos = { styleArchery = true }
chk("Tiro con Arco: +2 a distancia", A(distancia), 2)
chk("Tiro con Arco: NADA cuerpo a cuerpo", A(unaMano), 0)

flagsActivos = { styleSharpshooter = true }
chk("Tirador: +1 a distancia", A(distancia), 1)
flagsActivos = { styleArchery = true, styleSharpshooter = true }
chk("los dos estilos de distancia acumulan", A(distancia), 3)

flagsActivos = { styleDueling = true }
chk("Duelo: +2 a una mano sin secundaria", D(unaMano), 2)
chk("Duelo: NADA a dos manos", D(dosManos), 0)
chk("Duelo: NADA a distancia", D(distancia), 0)
flagsActivos = { styleDueling = true, __offhand = true }
chk("Duelo: NADA con algo en la secundaria", D(unaMano), 0)

-- sin arma delante, cero: nunca bono falso
flagsActivos = { styleArchery = true, styleDueling = true, styleSharpshooter = true }
chk("sin def, ataque a cero", A(), 0)
chk("sin def, dano a cero", D(), 0)

-- ── MOTOR: Defensa vive en Combat con su contexto de armadura ──
print("Defensa exige armadura puesta")
local combat = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
chk("consulta el flag", combat:find('HasFlag("styleDefense")', 1, true) ~= nil, true)
chk("y la armadura", combat:find("LlevaArmadura()", 1, true) ~= nil, true)
chk("mirando el pecho, no el escudo", combat:find('GetSlot("Chest")', 1, true) ~= nil, true)

-- ── LLAMADORES: los tres puntos con arma en mano la pasan ──
print("Los llamadores pasan el arma")
local LLAMADORES = {
    { "Harford/DnD/Engine/HarfordDnDWeaponRolls.lua", "GetWeaponDamageBonus(def)" },
    { "Harford/DnD/UI/HarfordDnD.lua", "GetWeaponAttackBonus(def)" },
    { "Harford/DnD/UI/HarfordDnDAttackUI.lua", "GetWeaponDamageBonus(def)" },
}
for _, par in ipairs(LLAMADORES) do
    local t = io.open(par[1]):read("*a")
    chk(par[1]:match("([^/]+)%.lua") .. " pasa def", t:find(par[2], 1, true) ~= nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
