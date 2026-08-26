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

-- ─── AVANCE POR BLOQUES ─────────────────────────────────────────────────────
-- El turno pasa de BLOQUE a bloque. Se extraen los tres ayudantes del avance, que viven mas
-- arriba en el fichero que el API de bandos y por eso hay que sacarlos aparte.
local ia = assert(src:find("local function SiguienteBandoConGente", 1, true))
local fa = assert(src:find("local function NextTurn()", ia, true))
local trozo = src:sub(ia, fa - 1)
    .. " return SiguienteBandoConGente, AnteriorBandoConGente, EntradaDeBando"
local g
if setfenv then g = assert(cargar(trozo)); setfenv(g, env)
else g = assert(cargar(trozo, "t", "t", env)) end
local Siguiente, Anterior, Entrada = g()

print("El avance recorre los bandos en el orden fijo")
env.HarfordTurnOrderStore = { entries = {
    { kind = "player", name = "Gmaster" },
    { kind = "npc", reaction = 1, name = "Cobra" },
    { kind = "npc", reaction = 4, name = "Vendedor" },
    { kind = "npc", reaction = 5, name = "Guardia" },
} }
chk("sin empezar, el primero es PJs", Siguiente(0), 1)
chk("de PJs a Enemigos", Siguiente(1), 2)
chk("de Enemigos a Neutrales", Siguiente(2), 3)
chk("de Neutrales a Aliados", Siguiente(3), 4)
chk("y de Aliados vuelve a PJs", Siguiente(4), 1)
chk("hacia atras, de Enemigos a PJs", Anterior(2), 1)
chk("y de PJs se va al ultimo", Anterior(1), 4)

-- Los bandos vacios se SALTAN. Un turno de Neutrales sin ningun neutral seria un clic perdido
-- cada asalto, y en mesa eso cansa mas que cualquier otra cosa.
print("Los bandos sin nadie se saltan")
env.HarfordTurnOrderStore = { entries = {
    { kind = "player", name = "Gmaster" },
    { kind = "npc", reaction = 1, name = "Cobra" },
} }
chk("de Enemigos salta a PJs sin pasar por vacios", Siguiente(2), 1)
chk("y hacia atras igual", Anterior(1), 2)
env.HarfordTurnOrderStore = { entries = {} }
chk("sin nadie en ningun bando, no hay siguiente", tostring(Siguiente(0)), "nil")

-- La entrada del turno es SINTETICA: representa al bloque, no a una criatura. Asi el aviso que ya
-- recorre a todos los clientes sirve sin cambiar el protocolo.
print("El turno se anuncia con una entrada de bando")
local e = Entrada("enemigos")
chk("se distingue de un combatiente", e.kind, "bando")
chk("dice de que bando es", e.bando, "enemigos")
chk("y se llama como la mesa lo llama", e.name, "Enemigos")
chk("con id propio para no chocar con nadie", e.id, "bando:enemigos")

-- El bloque de los PJs es de todos los jugadores: cada uno tiene que ver su aviso de turno.
local turnos = src
print("El bloque de PJs pertenece a todo jugador")
chk("EntryBelongsToMe lo reconoce",
    turnos:find('entry.kind == "bando" and entry.bando == "pjs" then return true', 1, true) ~= nil, true)
chk("retroceder tambien va por bloques",
    turnos:find("local anterior = AnteriorBandoConGente(actual)", 1, true) ~= nil, true)

-- Dos bandos seguidos comparten asalto pero NO turno: si la clave no los distinguiera, al segundo
-- no le bajaria ningun contador.
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
print("Cada bloque cuenta como un turno distinto")
chk("la clave de turno marca el bando",
    cond:find('("bando:" .. tostring(entry.bando))', 1, true) ~= nil, true)
chk("y un turno de bando casa con cualquiera de sus miembros",
    cond:find('if tostring(entry.kind or "") == "bando" then', 1, true) ~= nil, true)

-- ─── EL ANUNCIO LLEVA LA LISTA ──────────────────────────────────────────────
-- El aviso de turno viajaba serializando `store.entries[activeIndex]`, que en modo bandos NO se
-- mueve: los demas clientes recibian el combatiente de siempre y hacian tocar a quien no era.
-- Ahora se manda el bando Y su lista, para que la pertenencia la fije el DM y no la deduzca cada
-- cliente de su copia, que puede ir retrasada.
print("El aviso de turno habla de bandos, no de una criatura")
chk("existe el opcode propio", turnos:find('"TURNB", tostring(turnSerial or 0), bando', 1, true) ~= nil, true)
chk("y el receptor lo entiende", turnos:find('if opcode == "TURNB" then', 1, true) ~= nil, true)
chk("la lista de miembros viaja con el",
    turnos:find("ids[#ids + 1] = tostring(e.id)", 1, true) ~= nil, true)
chk("y se resuelve contra las entradas locales",
    turnos:find("local function EntradaDeBandoRecibida", 1, true) ~= nil, true)

-- Corregir el reparto tiene que difundirse EN EL ACTO. Si llegase con la foto retrasada, el bloque
-- que ya esta en juego tocaria con la lista vieja.
print("El DM reparte a mano y se difunde ya")
chk("hay menu de bando", turnos:find("local function AbrirMenuDeBando", 1, true) ~= nil, true)
chk("se abre con el boton derecho",
    turnos:find('if button == "RightButton" then', 1, true) ~= nil, true)
chk("solo el admin reparte",
    turnos:find("Solo el admin reparte los bandos", 1, true) ~= nil, true)
chk("y difunde al cambiar",
    turnos:find("if HarfordTurnOrderAPI.SetBando(entry, b) then", 1, true) ~= nil, true)

-- La lista que manda el DM PISA a la que calcularia el cliente: es lo que evita que dos clientes
-- con la foto desincronizada hagan tocar a criaturas distintas.
print("La lista del DM manda sobre la del cliente")
chk("el motor la prefiere", cond:find("if entry.miembros then", 1, true) ~= nil, true)
chk("y solo cae a la suya si no llega",
    cond:find("guids, nombres = MiembrosDeBando(entry.bando)", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
