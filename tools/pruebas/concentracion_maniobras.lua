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
local LLAMADAS = {}   -- registro de ApplyOwned/RemoveOwned del estado `concentrando`
local envC = cargarModulo("Harford/DnD/Engine/HarfordDnDConcentration.lua",
    setmetatable({
        HarfordDnDConditions = {
            Has = function(_, id) return ESTADOS[id] == true end,
            GetExhaustion = function() return CANSANCIO end,
            -- El mock imita al motor real: aplicar deja el estado consultable por Has.
            ApplyOwned = function(id, opts)
                ESTADOS[id] = true
                LLAMADAS[#LLAMADAS + 1] = "apply:" .. tostring(id) .. ":" .. tostring(opts and opts.sourceName)
                return true
            end,
            RemoveOwned = function(id)
                ESTADOS[id] = nil
                LLAMADAS[#LLAMADAS + 1] = "remove:" .. tostring(id)
                return true
            end,
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

-- Una linea por gesto (decision de mesa 2026-09-05): empezar NO anuncia nada por chat -- la
-- linea del lanzamiento ya sale con el desenlace CONCENTRACION -- y el estado visible es el
-- estado NUESTRO `concentrando` de la tira Harford, con el conjuro activo como detalle
-- (viaja en sourceName). Soltar/perder SI anuncia (es su unica linea).
print("Empezar es silencioso y pone el estado; soltar anuncia y lo retira")
local antes = #ANUNCIOS
LLAMADAS = {}
C.Begin("Telarana")
chk("Begin no emite ninguna linea", #ANUNCIOS, antes)
chk("y aplica el estado con el conjuro como fuente", LLAMADAS[1], "apply:concentrando:Telarana")
C.Begin("Bola de fuego")
chk("cambiar de conjuro tampoco anuncia", #ANUNCIOS, antes)
chk("y re-aplica el estado con el conjuro nuevo", LLAMADAS[#LLAMADAS], "apply:concentrando:Bola de fuego")
C.Break()
chk("Break si anuncia (su unica linea)", #ANUNCIOS, antes + 1)
chk("y retira el estado", LLAMADAS[#LLAMADAS], "remove:concentrando")

-- El click derecho en la tira retira el estado SIN pasar por Break: el listener lo detecta y
-- suelta la concentracion para que estado y modulo no diverjan.
print("Retirar el estado desde la tira suelta la concentracion")
C.Begin("Telarana")
ESTADOS.concentrando = nil   -- lo que deja RequestPlayer("player", "concentrando", false)
C.OnConditionsChanged()
chk("la concentracion se solto", C.IsActive(), false)
chk("y se anuncio la soltada", #ANUNCIOS > antes + 1, true)

-- La linea del lanzamiento: un conjuro con concentracion no dice EXITO, dice CONCENTRACION en
-- morado. Y el estado existe en el catalogo de condiciones con su icono y su detalle de fuente.
print("La linea de lanzamiento y el estado del catalogo")
local core = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
chk("el desenlace es condicional a la concentracion",
    core:find('esConcentracion and " |cffa335eeCONCENTRACION|r" or " |cff00ff00EXITO|r"', 1, true) ~= nil, true)
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local defConc = cond:find("concentrando = {", 1, true)
chk("el estado concentrando existe en el catalogo", defConc ~= nil, true)
if defConc then
    local bloque = cond:sub(defConc, defConc + 500)
    chk("como estado propio, sin aura de servidor", bloque:find('tracking = "state"', 1, true) ~= nil, true)
    chk("con la fuente como detalle del tooltip", bloque:find("sourceAsDetail = true", 1, true) ~= nil, true)
end
local cat = io.open("Harford/Compendium/HarfordIconCatalog.lua"):read("*a")
chk("tiene icono en el catalogo",
    cat:find("\n    harford_estado_concentrando = ", 1, true) ~= nil, true)
local uf = io.open("Harford/Frames/HarfordUnitFrames.lua"):read("*a")
chk("la tira pinta el detalle en cian tras el titulo",
    uf:find("GameTooltip:AddLine(self.estado.detalle, 0, 1, 1)", 1, true) ~= nil, true)

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

-- Estar incapacitado, dormido o muerto la rompe sin tirada. OJO: al reasignar ESTADOS hay que
-- conservar `concentrando` puesto (en el juego real el estado sigue ahi), o el listener creeria
-- que se retiro desde la tira y rompe por la via equivocada.
print("Se pierde al quedar incapacitado, y sin tirar nada")
for _, id in ipairs({ "incapacitated", "paralyzed", "petrified", "stunned", "sleeping" }) do
    C.Begin("Telarana")
    ESTADOS = { [id] = true, concentrando = true }
    C.OnConditionsChanged()
    chk("por " .. id, C.IsActive(), false)
    ESTADOS = {}
end
-- Pero no cualquier estado: estar envenenado no te hace perderla.
C.Begin("Telarana")
ESTADOS = { poisoned = true, frightened = true, concentrando = true }
C.OnConditionsChanged()
chk("envenenado o asustado NO la rompen", C.IsActive(), true)
ESTADOS = { concentrando = true }
-- Cansancio 6 es la muerte.
CANSANCIO = 5
C.OnConditionsChanged()
chk("cansancio 5 aun no", C.IsActive(), true)
CANSANCIO = 6
C.OnConditionsChanged()
chk("cansancio 6 si, que es morir", C.IsActive(), false)
CANSANCIO = 0
ESTADOS = {}

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
