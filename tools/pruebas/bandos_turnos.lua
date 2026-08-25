-- BANDOS EN EL ORDEN DE TURNOS.
--
-- La iniciativa va por bandos y no por criatura: cuando le toca a Enemigos actuan todos y sus
-- duraciones bajan de golpe. Es una divergencia deliberada del manual (5e usa iniciativa
-- individual), decidida en mesa.
--
-- Orden FIJO: PJs, Enemigos, Neutrales, Aliados. Sin tirada, porque saber siempre quien va detras
-- de quien vale mas en mesa que la sorpresa de quien empieza.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- Se extrae el bloque de bandos: son funciones del API de turnos y el fichero entero necesita WoW.
local src = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
local ini = assert(src:find("HarfordTurnOrderAPI.BANDOS = {", 1, true))
local fin = assert(src:find("function HarfordTurnOrderAPI.HasActiveCombat", ini, true))
local env = { ipairs = ipairs, pairs = pairs, tonumber = tonumber, tostring = tostring,
    type = type, table = table, HarfordTurnOrderAPI = {}, HarfordTurnOrderStore = nil }
local cargar = loadstring or load
local f
if setfenv then f = assert(cargar(src:sub(ini, fin - 1))); setfenv(f, env)
else f = assert(cargar(src:sub(ini, fin - 1), "t", "t", env)) end
f()
local T = env.HarfordTurnOrderAPI

print("Cuatro bandos, en orden fijo")
chk("son cuatro", #T.BANDOS, 4)
chk("primero los PJs", T.BANDOS[1], "pjs")
chk("luego enemigos", T.BANDOS[2], "enemigos")
chk("luego neutrales", T.BANDOS[3], "neutrales")
chk("y al final aliados", T.BANDOS[4], "aliados")
chk("con nombre legible", T.BANDO_ETIQUETA.enemigos, "Enemigos")

-- La reaccion de WoW propone; no decide. Un NPC hostil de verdad puede venir marcado como neutral.
print("La reaccion propone el bando")
chk("hostil", T.GetBando({ kind = "npc", reaction = 1 }), "enemigos")
chk("neutral", T.GetBando({ kind = "npc", reaction = 4 }), "neutrales")
chk("amistoso", T.GetBando({ kind = "npc", reaction = 5 }), "aliados")
chk("sin reaccion, enemigo por defecto", T.GetBando({ kind = "npc" }), "enemigos")
chk("sin entrada, tambien", T.GetBando(nil), "enemigos")

print("Pero el DM puede corregirlo, y su correccion manda")
local cobra = { kind = "npc", reaction = 4 }
chk("empieza como neutral", T.GetBando(cobra), "neutrales")
chk("se cambia", (T.SetBando(cobra, "enemigos")), true)
chk("y ahora es enemigo", T.GetBando(cobra), "enemigos")
-- Lo corregido queda ESCRITO en la entrada: es lo que hace que viaje en la foto y lo vean todos.
chk("queda guardado en la entrada", cobra.bando, "enemigos")
chk("un bando inventado se rechaza", (T.SetBando(cobra, "monstruos")), false)
chk("y no cambia el que habia", T.GetBando(cobra), "enemigos")

-- Los PJs no se mueven de su bando, ni por reaccion ni a mano. Es la regla que pidio la mesa.
print("Los personajes van siempre con los PJs")
chk("aunque su reaccion sea hostil", T.GetBando({ kind = "player", reaction = 1 }), "pjs")
chk("aunque sea amistosa", T.GetBando({ kind = "player", reaction = 5 }), "pjs")
local pj = { kind = "player", reaction = 5 }
chk("no se les puede cambiar", (T.SetBando(pj, "aliados")), false)
chk("y siguen en PJs", T.GetBando(pj), "pjs")
-- Ni siquiera si alguien les escribe el campo a mano en la foto.
chk("ni con el campo escrito a mano",
    T.GetBando({ kind = "player", reaction = 5, bando = "aliados" }), "pjs")

print("Los miembros de un bando salen del almacen")
env.HarfordTurnOrderStore = { entries = {
    { kind = "player", name = "Gmaster" },
    { kind = "npc", reaction = 1, name = "Cobra" },
    { kind = "npc", reaction = 1, name = "Ogro" },
    { kind = "npc", reaction = 5, name = "Guardia" },
} }
chk("un PJ", #T.GetBandoMembers("pjs"), 1)
chk("dos enemigos", #T.GetBandoMembers("enemigos"), 2)
chk("un aliado", #T.GetBandoMembers("aliados"), 1)
chk("ningun neutral", #T.GetBandoMembers("neutrales"), 0)
env.HarfordTurnOrderStore = nil
chk("sin almacen, lista vacia", #T.GetBandoMembers("enemigos"), 0)

-- El campo viaja el ULTIMO en la entrada serializada: un cliente con version anterior lo ignora y
-- sigue leyendo el resto, en vez de descuadrarse todos los campos.
local codec = io.open("Harford/Frames/HarfordTurnsCodec.lua"):read("*a")
print("Viaja en la foto, y el ultimo para no romper a los viejos")
chk("se envia", codec:find("EscapeText(entry.bando),", 1, true) ~= nil, true)
chk("se recibe", codec:find("bando = UnescapeText(bando),", 1, true) ~= nil, true)
chk("y va detras de la CA",
    codec:find("EscapeText(entry.bando)", 1, true) > codec:find("tostring(entry.armorClass or 0)", 1, true), true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
