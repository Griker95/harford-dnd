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

-- ─── ESTAR EN LA RAID NO ES ESTAR EN LA PELEA ───────────────────────────────
-- Media hermandad puede ver el combate sin jugarlo. A esos no hay que pintarles fichas de accion,
-- ni barra de movimiento, ni limitarles nada.
print("Solo cuentan los que estan DENTRO")
local q = assert(src:find("function HarfordTurnOrderAPI.AmIInCombat"))
local r = assert(src:find("\n-- Cuantos combatientes", q))
local env3 = { ipairs = ipairs, type = type, tostring = tostring, HarfordTurnOrderAPI = {},
    UnitGUID = function(u) return u == "player" and "GUID-YO" or nil end,
    UnitExists = function() return false end,
    EntryBelongsToMe = function(e) return e and e.name == "Yo" end,
    IsTurnAdmin = function() return false end }
local h
local cod3 = src:sub(q, r)
if setfenv then h = assert(cargar(cod3)); setfenv(h, env3) else h = assert(cargar(cod3, "d", "t", env3)) end
h()
local B = env3.HarfordTurnOrderAPI
env3.HarfordTurnOrderStore = { entries = { { kind = "npc", name = "Gnoll" } } }
chk("mirando desde fuera, NO estoy dentro", B.AmIInCombat(), false)
env3.HarfordTurnOrderStore = { entries = { { kind = "player", name = "Yo" } } }
chk("con entrada propia SI", B.AmIInCombat(), true)
-- Dentro de un BLOQUE tambien cuento, que es como entran los PJs en modo bandos.
env3.HarfordTurnOrderStore = { entries = {
    { kind = "players", name = "PJs", miembros = { { guid = "GUID-YO" } } } } }
chk("dentro de un bloque tambien", B.AmIInCombat(), true)
env3.HarfordTurnOrderStore = { entries = {
    { kind = "players", name = "PJs", miembros = { { guid = "GUID-OTRO" } } } } }
chk("pero el bloque de otro no me mete", B.AmIInCombat(), false)

-- ─── UN COMBATE ABANDONADO CADUCA ENTERO ────────────────────────────────────
-- Te desconectas a media pelea y vuelves al dia siguiente, sin nadie que te mande una foto nueva.
-- La caducidad de cuatro horas limpiaba las ENTRADAS pero no el estado: te encontrabas la lista
-- vacia y `activo` puesto, o sea "en combate" tu solo, con el asalto de ayer.
print("Un combate abandonado caduca entero")
chk("la caducidad borra el estado",
    src:find("store.estado = nil\n    store.asalto = nil", 1, true) ~= nil, true)
-- Lo gastado iba sellado con el asalto, que acaba de irse: se tira con el, o el sello dejaria de
-- valer y podria aplicarse a la pelea siguiente.
chk("y lo gastado, que iba sellado con el asalto",
    src:find("store.movimiento = nil\n    store.economia = nil", 1, true) ~= nil, true)
-- Y no se sale por lista vacia: lo que caduca es el COMBATE, y su estado puede haber quedado
-- puesto sin entradas.
chk("no se sale por lista vacia",
    src:find("if #store.entries == 0 and store.estado == nil", 1, true) ~= nil, true)
-- Se recoge lo demas igual que al Terminar: el contador, el estandarte y el marcador.
chk("y se recoge como al terminar",
    src:find("if Combate and Combate.CleanUpAfterCombat then pcall(Combate.CleanUpAfterCombat) end",
        1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
