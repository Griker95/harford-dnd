-- Dos motores pequenos que no tenian ni una prueba:
--   HarfordDnDCustomDamage -> el parser del dano escrito a mano.
--   HarfordDnDHeroPoints   -> cuantos puntos de heroe hay y como se gastan.
-- De 12 mutaciones a cada uno, las 12 pasaban.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local function cargarModulo(ruta, env)
    env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
    env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
    env.setmetatable = setmetatable
    local src = io.open(ruta):read("*a")
    local f
    if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
    pcall(f)
    return env
end

-- ═══ DANO ESCRITO A MANO ════════════════════════════════════════════════════
local envD = cargarModulo("Harford/DnD/Engine/HarfordDnDCustomDamage.lua",
    setmetatable({}, { __index = function() return nil end }))
local CD = envD.HarfordDnDCustomDamage

print("Formato de dados")
local p = CD.Parse("2d6")
chk("dos dados de seis", p and (p.count .. "d" .. p.sides), "2d6")
chk("sin bonus, cero", p and p.bonus, 0)
p = CD.Parse("d8")
chk("sin numero delante, un dado", p and p.count, 1)
p = CD.Parse("3d10+5")
chk("con bonus", p and (p.count .. "d" .. p.sides .. "+" .. p.bonus), "3d10+5")
p = CD.Parse("3d10-2")
chk("con bonus negativo", p and p.bonus, -2)
-- Los espacios y las mayusculas no deberian obligar a escribir con cuidado.
p = CD.Parse("  2 D 6 + 1 ")
chk("espacios y mayusculas dan igual", p and (p.count .. "d" .. p.sides .. "+" .. p.bonus), "2d6+1")

print("Un numero suelto es dano fijo")
p = CD.Parse("7")
chk("siete", p and p.flat, 7)
chk("y no lo confunde con dados", p and p.count, "nil")

print("Lo que no se entiende se rechaza, y lo dice")
chk("vacio", (CD.Parse("")), "nil")
chk("con motivo", select(2, CD.Parse("")), "Introduce dados o un numero")
chk("texto", (CD.Parse("mucho")), "nil")
chk("dados de cero caras", (CD.Parse("2d0")), "nil")
chk("cero dados", (CD.Parse("0d6")), "nil")
-- Medio formato tampoco vale: "2d" no dice de cuantas caras.
chk("dados sin caras", (CD.Parse("2d")), "nil")
chk("bonus suelto", (CD.Parse("+3")), "nil")
-- Un numero negativo no es dano: curar por esta via seria un accidente.
chk("negativo suelto", (CD.Parse("-3")), "nil")

-- ═══ PUNTOS DE HEROE ════════════════════════════════════════════════════════
local NIVEL, PROG = 1, {}
MODIFICABLE = true
local envH = cargarModulo("Harford/DnD/Engine/HarfordDnDHeroPoints.lua",
    setmetatable({
        HarfordDnDProgression = {
            GetTotalLevel = function() return NIVEL end,
            Get = function() return PROG end,
        },
        HarfordChat = { Print = function() end },
        -- El punto se cobra solo si la tirada se pudo modificar de verdad.
        HarfordDnDRolls = { ModifyLastRoll = function()
            if MODIFICABLE then return true, 18, nil, 4 end
            return false, nil, "No hay ninguna tirada reciente que modificar"
        end },
    }, { __index = function() return nil end }))
local H = envH.HarfordDnDHeroPoints

-- Del manual: 5 mas la mitad del nivel, redondeando hacia abajo.
print("Cuantos hay: 5 mas la mitad del nivel")
local esperado = { [1] = 5, [2] = 6, [3] = 6, [4] = 7, [5] = 7, [10] = 10, [20] = 15 }
for _, n in ipairs({ 1, 2, 3, 4, 5, 10, 20 }) do
    NIVEL = n
    chk("nivel " .. n, H.GetMax(), esperado[n])
end
-- Los impares son los que distinguen redondear hacia abajo de hacia arriba.
NIVEL = 3
chk("el nivel 3 no llega a 7 (se redondea abajo)", H.GetMax(), 6)

print("Sin nada guardado se empieza con todos")
NIVEL, PROG = 5, {}
chk("llenos", H.Get(), 7)

print("Lo guardado se respeta, pero acotado")
PROG = { heroPoints = 3 }
chk("tres", H.Get(), 3)
PROG = { heroPoints = 99 }
chk("mas del maximo se corta al maximo", H.Get(), 7)
PROG = { heroPoints = -4 }
chk("y por debajo de cero, cero", H.Get(), 0)

print("Guardar acota igual")
PROG = {}
H.Set(nil, 99)
chk("no deja pasarse", PROG.heroPoints, 7)
H.Set(nil, -5)
chk("ni bajar de cero", PROG.heroPoints, 0)
H.Set(nil, 2.9)
chk("y los decimales se truncan", PROG.heroPoints, 2)

-- Al subir de nivel se PIERDEN los no gastados y se recibe el total nuevo. Es la regla del manual,
-- y por eso no se acumulan de un nivel a otro.
print("Subir de nivel repone, no acumula")
NIVEL, PROG = 5, { heroPoints = 1 }
NIVEL = 6
H.OnLevelUp()
chk("se recibe el total del nivel nuevo", PROG.heroPoints, 8)
PROG = { heroPoints = 8 }
NIVEL = 7
H.OnLevelUp()
chk("y no se suman los que sobraban", PROG.heroPoints, 8)

print("Gastar")
NIVEL, PROG, MODIFICABLE = 5, { heroPoints = 2 }, true
chk("con puntos, se puede", (H.Spend()), true)
chk("y queda uno menos", PROG.heroPoints, 1)
PROG = { heroPoints = 0 }
chk("sin puntos, no", (H.Spend()), false)
chk("y no baja de cero", PROG.heroPoints, 0)

-- Si no hay ninguna tirada a la que aplicarlo, el punto NO se pierde. Perder un recurso escaso por
-- pulsar en mal momento es de las cosas que mas molestan en mesa.
print("Sin tirada que modificar, el punto no se gasta")
PROG, MODIFICABLE = { heroPoints = 3 }, false
chk("no se gasta", (H.Spend()), false)
chk("y sigue habiendo tres", PROG.heroPoints, 3)
MODIFICABLE = true

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
