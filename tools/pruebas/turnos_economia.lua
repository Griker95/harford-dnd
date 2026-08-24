-- Economia de turno: accion, accion adicional y reaccion como presupuesto que se renueva al EMPEZAR
-- tu turno (en 5e la reaccion tambien, no al terminarlo). Informa, no bloquea: `Spend` gasta siempre
-- y devuelve si habia presupuesto.
local cargar = loadstring or load
HarfordTurnOrderStore = { entries = {} }
HarfordTurnOrderAPI = { HasActiveCombat = function()
    for _, e in ipairs(HarfordTurnOrderStore.entries or {}) do
        if e.kind ~= "round" and e.kind ~= "generic" and e.kind ~= "players" then return true end
    end
    return false
end }
HarfordDnDFeatureEffects = { HasFlag = function() return false end }
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local i = assert(src:find("local ECONOMIA"), "no encuentro el bloque")
-- Retroceder a la ultima linea que sea exactamente `do`: es la que abre el bloque.
-- Anclar al texto de alrededor no vale, porque los comentarios cambian.
i = assert(src:sub(1, i):match(".*()\ndo\n"), "no encuentro el do")
local fin = assert(src:find("    API.Turn = Turn\nend", i), "no encuentro el cierre")
local bloque = src:sub(i, fin + #"    API.Turn = Turn\nend")
API = {}
local env = { API = API, math = math, string = string, table = table, ipairs = ipairs,
              tonumber = tonumber, tostring = tostring, type = type,
              Notify = function() end,
              Print = function(m) print("      aviso: " .. m) end,
              HarfordTurnOrderStore = HarfordTurnOrderStore,
              HarfordTurnOrderAPI = HarfordTurnOrderAPI,
              HarfordDnDFeatureEffects = HarfordDnDFeatureEffects }
local f
if setfenv then
    f = assert(cargar(bloque, "economia"))
    setfenv(f, env)
else
    f = assert(cargar(bloque, "economia", "t", env))
end
f()
local T = API.Turn
local fallos = 0
local function chk(nombre, real, esperado)
    local ok = tostring(real) == tostring(esperado)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-12s %s", nombre, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esperado))))
end

print("Sin orden de turnos: no se lleva la cuenta")
chk("IsActive()", T.IsActive(), false)
chk("StatusText() vacio", T.StatusText() == "", true)
chk("Spend no consume fuera de combate", (T.Spend("action")), true)
chk("  y sigue entero", T.GetRemaining("action"), 1)

print("Con orden de turnos activo")
HarfordTurnOrderStore.entries = { { name = "Alguien", kind = "npc" } }
chk("IsActive()", T.IsActive(), true)
chk("gasto la accion -> cabia", (T.Spend("action")), true)
chk("  restante", T.GetRemaining("action"), 0)
chk("gasto otra vez -> NO cabia", (T.Spend("action")), false)
chk("  pero se registra", T.GetSpent("action"), 2)
chk("la adicional intacta", T.GetRemaining("bonus"), 1)
chk("la reaccion intacta", T.GetRemaining("reaction"), 1)

print("Reinicio al empezar tu turno")
T.Reset()
chk("accion", T.GetRemaining("action"), 1)
chk("reaccion", T.GetRemaining("reaction"), 1)

print("Coste declarado por el rasgo")
chk('cast="reaccion"', T.KindFromFeature({ cast = "reaccion" }), "reaction")
chk('cast="accion_adicional"', T.KindFromFeature({ cast = "accion_adicional" }), "bonus")
chk('cast="accion"', T.KindFromFeature({ cast = "accion" }), "action")
chk('sin cast -> nil, no se adivina', T.KindFromFeature({ type = "accion" }), "nil")
chk('SpendForFeature sin cast no cuenta', T.SpendForFeature({ type = "accion" }), "nil")
chk('  accion intacta', T.GetRemaining("action"), 1)

print("Impetu de Accion")
HarfordDnDFeatureEffects.HasFlag = function(f) return f == "extraTurnAction" end
chk("presupuesto de accion pasa a 2", T.GetBudget("action"), 2)

print("Texto de ficha")
HarfordDnDFeatureEffects.HasFlag = function() return false end
T.Reset(); T.Spend("bonus")
print("  " .. T.StatusText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
