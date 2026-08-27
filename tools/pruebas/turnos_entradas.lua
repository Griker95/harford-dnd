-- A quien le toca y que entradas son "de sistema". Lo critico: el turno del bloque de PJs es de
-- SUS MIEMBROS --no de todo el que tenga el addon puesto, que mandaba "ES TU TURNO" a la raid
-- entera-- y un NPC que se llame igual que tu no debe disparar tu turno.
local cargar = loadstring or load
local src = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
local i = assert(src:find("local function IsSystemEntry"), "no encuentro IsSystemEntry")
-- El corte se busca desde `EntryBelongsToMe`, no desde `IsSystemEntry`: entre las dos hay ahora
-- ayudantes que tambien acaban en "return false", y cortar en el primero dejaba fuera justo la
-- funcion que se quiere probar.
local ini = assert(src:find("local function EntryBelongsToMe", i), "no encuentro EntryBelongsToMe")
local fin = assert(src:find("\n    return false\nend", ini), "no encuentro el cierre")
local bloque = src:sub(i, fin + #"\n    return false\nend")
    .. "\nreturn IsSystemEntry, EntryBelongsToMe"
local env = { ipairs = ipairs, tostring = tostring, type = type,
              UnitGUID = function(u) return u == "player" and "GUID-YO" or nil end,
              UnitName = function() return "Marcos" end,
              GetUnitName = function() return "Marcos-Epsilon" end,
              Ambiguate = function(n) return (n:match("^[^-]+")) end }
local f
if setfenv then f = assert(cargar(bloque)); setfenv(f, env)
else f = assert(cargar(bloque, "turnos", "t", env)) end
local IsSystemEntry, EntryBelongsToMe = f()
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-6s %s", n, tostring(real), ok and "ok" or "FALLA"))
end
print("Entradas de sistema (sin vida, sin CA, sin ficha)")
chk("round (marcador de asalto)", IsSystemEntry({kind="round"}), true)
chk("generic (marcador de fase)", IsSystemEntry({kind="generic"}), true)
chk("players (turno de PJs)", IsSystemEntry({kind="players"}), true)
chk("player (un PJ concreto) NO", IsSystemEntry({kind="player", name="Marcos"}), false)
chk("npc NO", IsSystemEntry({kind="npc"}), false)
print("A quien le toca (esto dispara el reinicio de la economia)")
chk("bloque de PJs sin mi -> NO me toca",
    EntryBelongsToMe({kind="players", name="PJs", miembros={{guid="GUID-OTRO"}}}), false)
chk("bloque de PJs conmigo dentro -> si",
    EntryBelongsToMe({kind="players", name="PJs", miembros={{guid="GUID-YO"}}}), true)
-- Un bloque sin lista no es de nadie: antes lo era de todos.
chk("bloque vacio -> de nadie", EntryBelongsToMe({kind="players", name="PJs"}), false)
chk("turno de otro jugador -> no", EntryBelongsToMe({kind="player", name="Otro"}), false)
chk("mi propio turno -> si", EntryBelongsToMe({kind="player", name="Marcos"}), true)
chk("mi nombre con realm -> si", EntryBelongsToMe({kind="player", name="Marcos-Epsilon"}), true)
chk("un NPC que se llame igual -> no", EntryBelongsToMe({kind="npc", name="Marcos"}), false)
chk("marcador de asalto -> no", EntryBelongsToMe({kind="round", name="Asalto"}), false)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
