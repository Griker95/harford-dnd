-- ?Hay combate? El marcador de asalto se inserta SIEMPRE y persiste, asi que "la lista no esta
-- vacia" era cierto para siempre: el contador de acciones no se apagaba nunca. Se cuentan solo
-- combatientes reales.
local cargar = loadstring or load
local src = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
-- IsSystemEntry
local i = assert(src:find("local function IsSystemEntry"))
local j = assert(src:find("\nend", i))
local sis = src:sub(i, j + 4)
-- Contar combatientes reales es ahora `HasCombatants`: `HasActiveCombat` pasa a contestar otra
-- pregunta --si el combate se ha INICIADO-- y confundirlas era el problema de fondo.
local k = assert(src:find("function HarfordTurnOrderAPI.HasCombatants"))
local l = assert(src:find("\nend", k))
local hac = src:sub(k, l + 4)
local env = { ipairs = ipairs, type = type, tostring = tostring, HarfordTurnOrderAPI = {} }
local f
local codigo = sis .. "\n" .. hac .. "\nreturn HarfordTurnOrderAPI.HasCombatants"
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Has = f()
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-6s %s", n, tostring(real), ok and "ok" or "FALLA"))
end
local function set(t) env.HarfordTurnOrderStore = { entries = t } end
print("?Hay combatientes montados?  (el marcador de asalto no cuenta)")
set({})
chk("lista vacia", Has(), false)
set({ { kind = "round", name = "Inicio de turno" } })
chk("SOLO el marcador de asalto (el caso del bug)", Has(), false)
-- Un BLOQUE cuenta como combatiente. Antes no, y montar PJs/Neutral/Enemigo y darle a Iniciar
-- decia "no hay combatientes" con la mesa llena: `IsSystemEntry` tapaba `players` y `generic`, que
-- son justo las tarjetas que representan a los bandos. Lo unico que no cuenta es el asalto.
set({ { kind = "round" }, { kind = "generic", name = "Enemigo" } })
chk("marcador + bloque de enemigos -> SI", Has(), true)
set({ { kind = "round" }, { kind = "players", name = "PJs" } })
chk("marcador + bloque de PJs -> SI", Has(), true)
set({ { kind = "round" }, { kind = "npc", name = "Gnoll" } })
chk("marcador + un NPC -> SI hay combate", Has(), true)
set({ { kind = "round" }, { kind = "player", name = "Marcos" } })
chk("marcador + un jugador -> SI", Has(), true)
set({ { kind = "target", name = "Objetivo" } })
chk('kind "target" (boton Objetivo) -> SI', Has(), true)
env.HarfordTurnOrderStore = nil
chk("sin store", Has(), false)

-- ─── EL ESTADO ES EXPLICITO ─────────────────────────────────────────────────
-- "Hay combate" se DEDUCIA de que hubiera entradas, asi que terminar el combate y vaciar la lista
-- eran lo mismo: no se podia dejar la mesa montada entre escenas, y un /reload con entradas
-- guardadas resucitaba un combate ya cerrado.
print("El estado del combate es explicito")
local m = assert(src:find("function HarfordTurnOrderAPI.GetCombatState"))
local n2 = assert(src:find("\nfunction HarfordTurnOrderAPI.RegisterMyTurnListener", m))
local env2 = { ipairs = ipairs, type = type, tostring = tostring, tonumber = tonumber,
    HarfordTurnOrderAPI = {} }
local g
local cod2 = sis .. "\n" .. src:sub(m, n2)
if setfenv then g = assert(cargar(cod2)); setfenv(g, env2) else g = assert(cargar(cod2, "e", "t", env2)) end
g()
local A = env2.HarfordTurnOrderAPI
env2.HarfordTurnOrderStore = { entries = { { kind = "npc", name = "Gnoll" } } }
chk("con gente pero sin iniciar, NO hay combate", A.HasActiveCombat(), false)
A.SetCombatState("preparando")
chk("preparando tampoco es combate", A.HasActiveCombat(), false)
A.SetCombatState("activo")
chk("iniciado SI", A.HasActiveCombat(), true)
A.SetCombatState(nil)
-- Terminar YA NO vacia la lista: la mesa se queda montada para la escena siguiente.
chk("terminado NO, aunque siga la gente puesta", A.HasActiveCombat(), false)
chk("y los combatientes siguen ahi", A.HasCombatants(), true)
-- Una lista guardada por una version anterior no trae estado. Sin este apano, un combate en curso
-- se quedaba muerto al actualizar el addon.
env2.HarfordTurnOrderStore = { entries = { { kind = "npc" } }, asalto = 3 }
chk("un combate de antes de esto se respeta", A.HasActiveCombat(), true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
