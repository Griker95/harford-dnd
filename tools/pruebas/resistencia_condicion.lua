-- Resistencia por CONDICION y por tipo de dano.
--
-- Antes solo existia `resistAll` (Petrificado), asi que una resistencia parcial no se podia
-- declarar: o resistias todo o nada. La Piel de Hierro del Monje resiste contundente, perforante y
-- cortante, y SOLO de golpes no magicos. Estas son las dos cosas que se prueban, porque las dos se
-- pueden perder en silencio: sin el tipo resistiria el fuego, y sin `opts.magical` resistiria un
-- arma encantada.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local i = assert(src:find("local function ClaveDeTipo"))
local j = assert(src:find("\nlocal function PublishState", i))
local codigo = src:sub(i, j) .. "\nreturn API.GetDamageStatus"

-- Efectos activos de la unidad: es lo que devuelve el motor tras mirar auras y estados.
local EFECTOS = {}
local API = {}
local env = {
    ipairs = ipairs, type = type, tostring = tostring, API = API,
    EffectsFor = function() return EFECTOS end,
    HarfordDamageTypes = {
        FromWord = function(w)
            local m = { contundente = "bludgeoning", perforante = "piercing", cortante = "slashing",
                        fuego = "fire", veneno = "poison" }
            return m[w]
        end,
        Exists = function(k)
            local s = { bludgeoning = true, piercing = true, slashing = true, fire = true, poison = true }
            return s[k] == true
        end,
    },
}
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Status = f()

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = real == esp
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-12s %s", etiqueta, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("Sin condiciones no hay resistencia")
chk("contundente", Status("player", "contundente"), nil)

print("Piel de Hierro: contundente/perforante/cortante no magicos")
EFECTOS = { { kind = "resistTypes", nonMagical = true, types = { "bludgeoning", "piercing", "slashing" } } }
chk("contundente (palabra en español)", Status("player", "contundente"), "resistant")
chk("piercing (clave interna)", Status("player", "piercing"), "resistant")
chk("cortante", Status("player", "cortante"), "resistant")
chk("fuego NO", Status("player", "fuego"), nil)
chk("veneno NO", Status("player", "veneno"), nil)
chk("sin tipo no resiste nada", Status("player", nil), nil)

print("  -- y no aplica a golpes magicos:")
chk("contundente magico", Status("player", "contundente", { magical = true }), nil)
chk("contundente no magico", Status("player", "contundente", { magical = false }), "resistant")

print("Una resistencia por tipo SIN el calificador si aplica a golpes magicos")
EFECTOS = { { kind = "resistTypes", types = { "fire" } } }
chk("fuego magico", Status("player", "fuego", { magical = true }), "resistant")

print("resistAll sigue resistiendolo todo, con tipo o sin el")
EFECTOS = { { kind = "resistAll" } }
chk("fuego", Status("player", "fuego"), "resistant")
chk("sin tipo", Status("player", nil), "resistant")
chk("magico", Status("player", "contundente", { magical = true }), "resistant")

print("Otros efectos de condicion no conceden resistencia")
EFECTOS = { { kind = "speedZero" }, { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" } }
chk("contundente", Status("player", "contundente"), nil)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
