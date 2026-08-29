-- Dos motores de reglas que no tenian ni una prueba (12 de 12 mutaciones pasaban en cada uno):
--   HarfordDnDConcentration -> cuando se pierde la concentracion.
--   HarfordDnDManeuvers     -> agarrar, empujar, escapar, estabilizar y cobertura.

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
    env.setmetatable, env.time = setmetatable, function() return 0 end
    local src = io.open(ruta):read("*a")
    local f
    if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
    pcall(f)
    return env
end

-- ═══ CONCENTRACION ══════════════════════════════════════════════════════════
local ESTADOS, CANSANCIO, DADO, ANUNCIOS = {}, 0, 10, {}
local envC = cargarModulo("Harford/DnD/Engine/HarfordDnDConcentration.lua",
    setmetatable({
        HarfordDnDConditions = {
            Has = function(_, id) return ESTADOS[id] == true end,
            GetExhaustion = function() return CANSANCIO end,
        },
        HarfordDnDCalc = {
            GetAbilityMod = function() return 2 end,
            GetSaveProf = function() return false end,
            GetPB = function() return 2 end,
        },
        HarfordDnDRolls = { Broadcast = function(d) ANUNCIOS[#ANUNCIOS + 1] = d end },
        HarfordChat = { Print = function() end },
    }, { __index = function() return nil end }))
local C = envC.HarfordDnDConcentration
-- El d20 se fija para poder comprobar la regla y no la suerte.
envC.math = setmetatable({ random = function() return DADO end }, { __index = math })

-- CD del manual: 10, o la mitad del dano si es mayor.
print("CD de concentracion: 10 o la mitad del dano, lo que sea mayor")
chk("1 de dano", C.GetSaveDC(1), 10)
chk("20 de dano sigue siendo 10", C.GetSaveDC(20), 10)
chk("21 ya son 10", C.GetSaveDC(21), 10)
chk("22 son 11", C.GetSaveDC(22), 11)
chk("50 son 25", C.GetSaveDC(50), 25)
-- Impares: 23 son 11,5 -> 11, redondeando hacia abajo.
chk("23 son 11, no 12", C.GetSaveDC(23), 11)
chk("sin dano, el minimo", C.GetSaveDC(0), 10)

print("Solo se puede concentrar en UN conjuro")
chk("no hay nada al principio", C.IsActive(), false)
C.Begin("Telarana")
chk("ahora si", C.IsActive(), true)
chk("y se sabe cual", C.GetSpellName(), "Telarana")
C.Begin("Bola de fuego")
chk("empezar otro sustituye al anterior", C.GetSpellName(), "Bola de fuego")
chk("sin nombre no se empieza", (C.Begin("")), false)
C.Break()
chk("soltarla la termina", C.IsActive(), false)
chk("y soltar lo que no hay no hace nada", (C.Break()), false)

print("El dano obliga a una salvacion, una POR FUENTE")
C.Begin("Telarana")
DADO = 20
chk("un 20 natural la mantiene siempre", (C.OnDamage(100)), true)
chk("y sigue concentrado", C.IsActive(), true)
DADO = 1
chk("un 1 natural la pierde siempre", (C.OnDamage(1)), false)
chk("y deja de estarlo", C.IsActive(), false)
-- Con dano 0 no hay salvacion: no toda linea de dano obliga a tirar.
C.Begin("Telarana")
chk("dano cero no pide salvacion", C.OnDamage(0), "nil")
chk("ni un dano negativo", C.OnDamage(-5), "nil")
chk("y sin concentrarse tampoco", (function() C.Break(); return C.OnDamage(10) end)(), "nil")

print("El total es el dado mas el modificador, y la competencia si la hay")
C.Begin("Telarana")
DADO = 9
local _, total, dc = C.OnDamage(4)   -- CD 10, 9+2 = 11 -> mantiene
chk("nueve mas dos son once", total, 11)
chk("contra CD 10", dc, 10)
chk("y la mantiene", C.IsActive(), true)
envC.HarfordDnDCalc.GetSaveProf = function() return true end
C.Begin("Telarana")
DADO = 9
_, total = C.OnDamage(4)
chk("con competencia, dos mas", total, 13)
envC.HarfordDnDCalc.GetSaveProf = function() return false end

-- Estar incapacitado, dormido o muerto la rompe sin tirada.
print("Se pierde al quedar incapacitado, y sin tirar nada")
for _, id in ipairs({ "incapacitated", "paralyzed", "petrified", "stunned", "sleeping" }) do
    C.Begin("Telarana")
    ESTADOS = { [id] = true }
    C.OnConditionsChanged()
    chk("por " .. id, C.IsActive(), false)
    ESTADOS = {}
end
-- Pero no cualquier estado: estar envenenado no te hace perderla.
C.Begin("Telarana")
ESTADOS = { poisoned = true, frightened = true }
C.OnConditionsChanged()
chk("envenenado o asustado NO la rompen", C.IsActive(), true)
ESTADOS = {}
-- Cansancio 6 es la muerte.
CANSANCIO = 5
C.OnConditionsChanged()
chk("cansancio 5 aun no", C.IsActive(), true)
CANSANCIO = 6
C.OnConditionsChanged()
chk("cansancio 6 si, que es morir", C.IsActive(), false)
CANSANCIO = 0

print("Y a 0 puntos de golpe")
C.Begin("Telarana")
C.OnHealthChanged(1)
chk("con 1 de vida sigue", C.IsActive(), true)
C.OnHealthChanged(0)
chk("a cero, se pierde", C.IsActive(), false)

-- ═══ MANIOBRAS ══════════════════════════════════════════════════════════════
local envM = cargarModulo("Harford/DnD/Engine/HarfordDnDManeuvers.lua",
    setmetatable({
        HarfordChat = { Print = function() end },
        HarfordDnDRolls = { Broadcast = function() end },
        HarfordDnDConditions = { Has = function() return false end, ApplyToUnit = function() end,
                                 RemoveOwned = function() end, RemoveFromUnit = function() end },
        UnitExists = function() return true end,
        UnitName = function() return "Objetivo" end,
        HarfordClassColors = { UnitFullName = function() return "Objetivo" end },
    }, { __index = function() return nil end }))
local M = envM.HarfordDnDManeuvers

-- La regla que mas se equivoca: el empate lo gana el DEFENSOR. Hay que GANAR la prueba, no igualarla.
print("Agarrar y empujar: el empate lo gana el defensor")
chk("ganando, agarra", (M.ResolveContest("grapple", "target", 15, 12)), true)
chk("empatando, NO", (M.ResolveContest("grapple", "target", 12, 12)), false)
chk("perdiendo, tampoco", (M.ResolveContest("grapple", "target", 11, 12)), false)
chk("y lo mismo empujando", (M.ResolveContest("shove", "target", 12, 12)), false)

print("Que deja cada una")
chk("agarrar deja Agarrado", select(2, M.ResolveContest("grapple", "target", 15, 10)), "grappled")
chk("empujar deja Derribado", select(2, M.ResolveContest("shove", "target", 15, 10)), "prone")
-- Empujar tiene dos usos: derribar o alejar. Alejar NO deja estado, solo mueve.
chk("pero alejar no deja estado",
    select(2, M.ResolveContest("shove", "target", 15, 10, "push")), "push")

print("Escapar de un agarre")
chk("si no estas agarrado, no hay de que escapar", (M.Escape("Atletismo")), false)
envM.HarfordDnDConditions.Has = function() return true end
chk("agarrado, si se puede", (M.Escape("Atletismo")), true)
chk("y vale tambien Acrobacias", (M.Escape("Acrobacias")), true)

print("Estabilizar: CD 10 de Medicina, o los utiles sin tirada")
-- Con utiles no hay tirada: se estabiliza y punto.
local ok, como = M.Stabilize("target", true)
chk("con utiles, seguro", ok, true)
chk("y sin tirar", como, "kit")

print("Cobertura")
chk("ninguna por defecto", (M.GetCover()), "none")
M.SetCover("half")
chk("media", (M.GetCover()), "half")
chk("suma 2 a la CA", select(2, M.GetCover()).ac, 2)
M.SetCover("three")
chk("tres cuartos suma 5", select(2, M.GetCover()).ac, 5)
-- La cobertura total no se declara desde Harford: impide elegir al objetivo y se resuelve en mesa.
chk("la total no se puede seleccionar", (M.SetCover("total")), false)
chk("una cobertura inventada se rechaza", (M.SetCover("muchisima")), false)
chk("y no cambia la que habia", (M.GetCover()), "three")
M.SetCover("none")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
