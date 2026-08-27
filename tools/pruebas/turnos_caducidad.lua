-- Caducidad de la lista de turnos. `entries` vive en SavedVariables y solo se limpiaba a mano, asi
-- que un combate de hace semanas seguia ahi al entrar. Se comprueba que un relogeo de minutos la
-- CONSERVA y que una de horas se purga: borrar a ciegas seria peor que no borrar.
local cargar = loadstring or load
local src = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
-- La limpieza se movio detras de `IsTurnAdmin` --lo usa para dar mas margen al DM-- asi que el
-- trozo se coge por partes: el almacen y el sello por un lado, la limpieza por otro.
local i = assert(src:find("local function EnsureStore"))
local fin = assert(src:find("\nlocal STALE_SECONDS", i))
local p1 = assert(src:find("local function PurgeStaleEntries"))
local p2 = assert(src:find("\n    return true\nend", p1))
-- Los dos limites van en el trozo: la limpieza los compara, y sin ellos serian globales nil.
local lim1 = assert(src:find("local STALE_SECONDS = "))
local lim2 = assert(src:find("\n", assert(src:find("local STALE_SECONDS_DM = "))))
local bloque = src:sub(i, fin) .. "\n" .. src:sub(lim1, lim2)
    .. src:sub(p1, p2 + #"\n    return true\nend")
    .. "\nreturn TouchStore, PurgeStaleEntries"
local AHORA = 1000000
-- Sin ser DM: el margen corto es el que se comprueba aqui.
local env = { type = type, tonumber = tonumber, time = function() return AHORA end,
              ipairs = ipairs, IsTurnAdmin = function() return false end }
local f
if setfenv then f = assert(cargar(bloque)); setfenv(f, env) else f = assert(cargar(bloque, "t", "t", env)) end
local Touch, Purge = f()
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-6s %s", n, tostring(real), ok and "ok" or "FALLA"))
end
local H = 60 * 60
print("Caducidad de la lista de turnos (15 min; 4 h si mandas)")
env.HarfordTurnOrderStore = { entries = {} }
chk("lista vacia: nada que purgar", Purge(), false)

env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 60 }
chk("tocada hace 1 minuto (relogeo) -> se CONSERVA", Purge(), false)
chk("  y las entradas siguen", #env.HarfordTurnOrderStore.entries, 1)

-- QUINCE minutos. Con el boton de `Unirse` y el relevo entre companeros, volver a un combate en
-- curso ya no depende de la caducidad: es para el caso raro --nadie conectado que te mande la
-- foto-- y cuanto antes limpie, menos rato se arrastra un combate muerto. Las cuatro horas eran de
-- cuando esta era la unica via de vuelta.
env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 10*60 }
chk("tocada hace 10 minutos -> se conserva", Purge(), false)

env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 20*60 }
chk("tocada hace 20 minutos -> se PURGA", Purge(), true)
chk("  lista vacia", #env.HarfordTurnOrderStore.entries, 0)
chk("  indice reiniciado", env.HarfordTurnOrderStore.activeIndex, 1)

env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 30*24*H }
chk("de hace un mes -> se purga", Purge(), true)

env.HarfordTurnOrderStore = { entries = {{kind="npc"}} }
chk("SIN sello (guardada por version anterior) -> se purga", Purge(), true)

print("El sello se pone al tocar")
env.HarfordTurnOrderStore = { entries = {{kind="npc"}} }
Touch()
chk("lastTouched sellado", env.HarfordTurnOrderStore.lastTouched, AHORA)
chk("  y ahora ya no se purga", Purge(), false)
-- ─── EL DM TIENE MAS MARGEN ─────────────────────────────────────────────────
-- Su copia es LA BUENA y nadie puede devolversela: si se le cae el cliente veinte minutos,
-- tirarle el combate es perderlo de verdad, no limpiar un resto. Al que solo lo recibe le sobra
-- con quince minutos, porque volver le cuesta un boton.
print("El DM tiene mas margen")
env.IsTurnAdmin = function() return true end
env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 60*60 }
chk("tocada hace 1 hora, siendo DM -> se conserva", Purge(), false)
env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 5*H }
chk("tocada hace 5 horas -> ni el DM la salva", Purge(), true)
env.IsTurnAdmin = function() return false end
env.HarfordTurnOrderStore = { entries = {{kind="npc"}}, lastTouched = AHORA - 60*60 }
chk("y sin mandar, esa misma hora se purga", Purge(), true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
