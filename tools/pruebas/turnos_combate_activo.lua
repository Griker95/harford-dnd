-- ?Hay combate? El marcador de asalto se inserta SIEMPRE y persiste, asi que "la lista no esta
-- vacia" era cierto para siempre: el contador de acciones no se apagaba nunca. Se cuentan solo
-- combatientes reales.
local cargar = loadstring or load
local src = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
-- IsSystemEntry
local i = assert(src:find("local function IsSystemEntry"))
local j = assert(src:find("\nend", i))
local sis = src:sub(i, j + 4)
-- HasActiveCombat
local k = assert(src:find("function HarfordTurnOrderAPI.HasActiveCombat"))
local l = assert(src:find("\nend", k))
local hac = src:sub(k, l + 4)
local env = { ipairs = ipairs, type = type, HarfordTurnOrderAPI = {} }
local f
local codigo = sis .. "\n" .. hac .. "\nreturn HarfordTurnOrderAPI.HasActiveCombat"
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Has = f()
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-6s %s", n, tostring(real), ok and "ok" or "FALLA"))
end
local function set(t) env.HarfordTurnOrderStore = { entries = t } end
print("?Hay combate?  (el bug: el marcador de asalto contaba como combate)")
set({})
chk("lista vacia", Has(), false)
set({ { kind = "round", name = "Inicio de turno" } })
chk("SOLO el marcador de asalto (el caso del bug)", Has(), false)
set({ { kind = "round" }, { kind = "generic", name = "Enemigo" } })
chk("marcador + marcador de fase", Has(), false)
set({ { kind = "round" }, { kind = "players", name = "PJs" } })
chk("marcador + turno PJs (aun sin combatientes)", Has(), false)
set({ { kind = "round" }, { kind = "npc", name = "Gnoll" } })
chk("marcador + un NPC -> SI hay combate", Has(), true)
set({ { kind = "round" }, { kind = "player", name = "Marcos" } })
chk("marcador + un jugador -> SI", Has(), true)
set({ { kind = "target", name = "Objetivo" } })
chk('kind "target" (boton Objetivo) -> SI', Has(), true)
env.HarfordTurnOrderStore = nil
chk("sin store", Has(), false)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
