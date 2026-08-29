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

-- MANUAL WARCRAFT (2026-08-29): un punto o ninguno, NO se recibe por defecto ni al subir de
-- nivel (lo concede el DM por actos heroicos) y gastarlo publica uno de los seis usos.
print("Un punto o ninguno")
for _, n in ipairs({ 1, 5, 20 }) do
    NIVEL = n
    chk("maximo 1 a nivel " .. n, H.GetMax(), 1)
end

print("Sin dato NO hay punto: es algo especial, lo concede el DM")
NIVEL, PROG = 5, {}
chk("a cero", H.Get(), 0)
PROG = { heroPoints = 99 }
chk("mas de uno se corta a uno", H.Get(), 1)

print("Subir de nivel no regala nada")
PROG = {}
H.OnLevelUp()
chk("sigue sin punto", H.Get(), 0)
PROG = { heroPoints = 1 }
H.OnLevelUp()
chk("y el concedido se conserva", H.Get(), 1)

print("Conceder no acumula")
PROG = {}
chk("se concede", (H.Grant()), true)
chk("y queda uno", PROG.heroPoints, 1)
chk("con punto, no se concede otro", (H.Grant()), false)
chk("sigue habiendo uno", PROG.heroPoints, 1)

print("Gastar publica el uso elegido y deja cero")
PROG = { heroPoints = 1 }
chk("uso valido", (H.SpendUse("defensa_esquiva")), true)
chk("queda a cero", PROG.heroPoints, 0)
chk("sin punto no se gasta", (H.SpendUse("impulso")), false)
PROG = { heroPoints = 1 }
chk("uso desconocido no cobra", (H.SpendUse("volar")), false)
chk("y el punto sigue ahi", PROG.heroPoints, 1)

print("Los seis usos del manual estan declarados")
local ids = {}
for _, u in ipairs(H.USOS) do ids[u.id] = true end
for _, id in ipairs({ "impulso", "fisico_poderoso", "fisico_mutilar", "magico_sobrecarga",
                      "magico_preciso", "defensa_esquiva", "defensa_resistente",
                      "sobreviviente", "experto" }) do
    chk("uso " .. id, ids[id], true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
