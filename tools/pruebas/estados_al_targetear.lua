-- LOS ESTADOS SE PIDEN AL TARGETEAR, no solo se difunden al aplicarse.
--
-- Difundir solo al aplicar deja fuera tres casos que pasan constantemente: no estar en el grupo en
-- ese momento, recargar despues, o simplemente empezar a mirar a alguien mas tarde. Es el modelo
-- que los RECURSOS ya usaban bien, y los estados eran el unico dato que se pinta pasivamente y no
-- lo tenia.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- El protocolo se prueba EJECUTANDOLO: ida y vuelta de verdad, no mirando el texto.
local src = io.open("Harford/Core/HarfordSync.lua"):read("*a")
local ini = assert(src:find("function HarfordSync.SerializeConditionRequest2", 1, true))
local fin = assert(src:find("function HarfordSync.BestChannel", ini, true))
local env = { string = string, table = table, math = math, tostring = tostring, tonumber = tonumber,
    ipairs = ipairs, pairs = pairs, type = type,
    HarfordSync = {},
    strsplit = function(sep, s)
        local out = {}
        for trozo in (tostring(s) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do
            out[#out + 1] = trozo
        end
        return (table.unpack or unpack)(out)
    end }
local cargar = loadstring or load
local f
if setfenv then f = assert(cargar(src:sub(ini, fin - 1))); setfenv(f, env)
else f = assert(cargar(src:sub(ini, fin - 1), "t", "t", env)) end
f()
local S = env.HarfordSync

print("La peticion va y vuelve")
chk("se compone", S.SerializeConditionRequest2("Yo"), "DNDCONDREQ|Yo")
chk("y se lee", S.DeserializeConditionRequest2("DNDCONDREQ|Yo"), "Yo")
chk("otro mensaje no se confunde", (S.DeserializeConditionRequest2("DNDCOND|otra")), "nil")

-- La respuesta lleva TODOS los estados de golpe: un mensaje por estado multiplicaria el trafico
-- por nada, y la lista completa cabe de sobra en un envio.
print("La respuesta lleva la lista entera")
local msg = S.SerializeConditionList("GUID-1", "Fulano", {
    { id = "prone", duration = "manual", turns = 0, level = 0 },
    { id = "exhaustion", duration = "rounds", turns = 3, level = 2 },
})
local guid, nombre, lista = S.DeserializeConditionList(msg)
chk("con el guid", guid, "GUID-1")
chk("con el nombre", nombre, "Fulano")
chk("y los dos estados", #lista, 2)
chk("el primero", lista[1] and lista[1].id, "prone")
chk("el segundo con su duracion", lista[2] and lista[2].duration, "rounds")
chk("sus turnos", lista[2] and lista[2].turns, 3)
-- El nivel viaja: sin el, un Cansancio 5 llegaria como 1 y se veria mal en la tira.
chk("y su nivel", lista[2] and lista[2].level, 2)

print("Una lista vacia es una respuesta valida")
guid, nombre, lista = S.DeserializeConditionList(S.SerializeConditionList("GUID-1", "Fulano", {}))
chk("se entiende", guid, "GUID-1")
-- Y es importante que lo sea: "no llevo nada" tiene que poder decirse, o no habria forma de que
-- se limpiaran los estados viejos en el cliente que mira.
chk("sin estados", #lista, 0)

local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
print("El motor pide, contesta y guarda")
chk("pide", cond:find("function API.RequestStatesFrom", 1, true) ~= nil, true)
chk("contesta con los suyos", cond:find("function API.SendMyStatesTo", 1, true) ~= nil, true)
chk("y guarda la respuesta", cond:find("function API.CacheStateList", 1, true) ~= nil, true)
-- La respuesta es una FOTO: sustituye lo que hubiera de ese jugador. Si se fusionara, un estado
-- retirado mientras no mirabas se quedaria puesto para siempre.
chk("sustituyendo, no fusionando",
    cond:find("S.units[key] = next(bucket) and bucket or nil", 1, true) ~= nil, true)
-- Mismo enfriamiento que los recursos: al cambiar de objetivo a menudo, sin el se llenaria el canal.
chk("con enfriamiento por jugador", cond:find("PETICION_ENFRIAMIENTO = 12", 1, true) ~= nil, true)
chk("y no se pide a uno mismo",
    cond:find('if UnitIsUnit and UnitIsUnit(unit, "player") then return false end', 1, true) ~= nil, true)
-- Solo se acepta de quien se puede resolver, igual que el resto de mensajes de efecto.
chk("solo de remitentes de confianza",
    cond:find("if IsTrustedSender(sender) then API.CacheStateList", 1, true) ~= nil, true)
-- Y que la respuesta venga de quien dice ser: nadie puede contarme los estados de un tercero.
-- La UNICA excepcion es un NPC, que no tiene cliente que hable por el, y esta acotada a los que ya
-- estan en el orden de turnos: solo se puede informar de lo que la mesa ya conoce.
chk("y el remitente tiene que ser el interesado",
    cond:find("ShortName(sender) ~= ShortName(name) and not EsNpcDeLosTurnos(guid)", 1, true) ~= nil, true)
chk("salvo los NPC, que no tienen quien hable por ellos",
    cond:find("EsNpcDeLosTurnos = function(guid)", 1, true) ~= nil, true)
chk("y solo los que ya estan en la lista de turnos",
    cond:find('tostring(e.kind or "") == "npc" then return true', 1, true) ~= nil, true)

local comm = io.open("Harford/DnD/Engine/HarfordDnDComm.lua"):read("*a")
print("Se pide al cambiar de objetivo, como los recursos")
chk("en el mismo sitio que los recursos",
    comm:find('HarfordDnDConditions.RequestStatesFrom("target")', 1, true) ~= nil, true)
chk("justo despues de pedirlos",
    comm:find("deps.RequestResourcesFromPlayer(targetName)", 1, true)
    < comm:find("RequestStatesFrom", 1, true), true)

-- El push NO se quita: da inmediatez en combate sin volver a targetear. Los dos juntos.
print("Y el aviso al aplicar se conserva")
chk("sigue publicandose al aplicar", cond:find("local function PublishState", 1, true) ~= nil, true)

-- ─── LOS ESTADOS DE LOS NPC AL ENTRAR ───────────────────────────────────────
-- Quien se une o se reconecta a mitad de combate no sabe nada de lo que llevan encima los NPCs:
-- esos estados solo se difundieron al aplicarse, y el no estaba. Pregunta al entrar.
print("La peticion de estados de NPC va y vuelve")
chk("se compone", S.SerializeNpcStatesRequest("Yo"), "DNDCONDNPCREQ|Yo")
chk("y se lee", S.DeserializeNpcStatesRequest("DNDCONDNPCREQ|Yo"), "Yo")
-- Los dos opcodes empiezan igual; si uno se comiera al otro, la peticion de jugador dejaria de
-- responderse o al reves.
chk("no se confunde con la de jugador",
    (S.DeserializeNpcStatesRequest("DNDCONDREQ|Yo")), "nil")
chk("ni la de jugador con esta",
    (S.DeserializeConditionRequest2("DNDCONDNPCREQ|Yo")), "nil")

-- El guardia que decide si se acepta informacion de estados AJENOS. Se ejecuta, no se busca su
-- texto: es lo unico que separa "el DM me cuenta lo que lleva el ogro" de "cualquiera se inventa
-- condiciones sobre cualquier cosa".
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local i2 = assert(cond:find("EsNpcDeLosTurnos = function(guid)", 1, true))
local f2 = assert(cond:find("function API.CacheStateList", i2, true))
-- El trozo extraido arrastra tambien la declaracion de `API.FuenteNpcGana`, que necesita la tabla
-- para existir al cargarse.
local entorno = { ipairs = ipairs, pairs = pairs, type = type, tostring = tostring,
    tonumber = tonumber, API = {}, _G = {} }
local g
if setfenv then g = assert(cargar(cond:sub(i2, f2 - 1) .. " return EsNpcDeLosTurnos")); setfenv(g, entorno)
else g = assert(cargar(cond:sub(i2, f2 - 1) .. " return EsNpcDeLosTurnos", "t", "t", entorno)) end
local EsNpc = g()

print("Solo se acepta informacion ajena de NPCs que la mesa ya conoce")
entorno._G.HarfordTurnOrderStore = { entries = {
    { kind = "npc", guid = "Creature-0-1-2-3-4-5", name = "Ogro" },
    { kind = "player", guid = "Player-1-ABC", name = "Huldram" },
} }
chk("un NPC de la lista, si", EsNpc("Creature-0-1-2-3-4-5"), true)
-- Un JUGADOR nunca: el suyo lo cuenta su propio cliente, y aceptarlo de un tercero permitiria
-- ponerle condiciones a alguien sin que se entere.
chk("un jugador de la lista, NO", EsNpc("Player-1-ABC"), false)
chk("un guid que no esta, NO", EsNpc("Creature-9-9-9-9-9-9"), false)
chk("vacio, NO", EsNpc(""), false)
chk("nil, NO", EsNpc(nil), false)
entorno._G.HarfordTurnOrderStore = nil
chk("sin combate montado, NO", EsNpc("Creature-0-1-2-3-4-5"), false)

-- Un NPC sin estados TIENE que informarse igual, con la lista vacia: callar dejaria pegado lo que
-- el otro creyera que llevaba encima.
print("Un NPC limpio tambien se informa")
chk("se manda aunque no lleve nada",
    cond:find("HarfordSync.SendConditionList(PREFIX, target, guid", 1, true) ~= nil, true)
-- El core NO decide si eres DM: expone un callback y HarfordAdmin lo sustituye. Es la regla de
-- CLAUDE.md, y ademas hace que sin Admin cargado no conteste nadie, que es lo correcto.
chk("y solo contesta quien pueda", cond:find("if not API.CanAnswerNpcStates() then", 1, true) ~= nil, true)
chk("por defecto, nadie", cond:find("function API.CanAnswerNpcStates()", 1, true) ~= nil, true)
local admin = io.open("HarfordAdmin/HarfordAdminConditions.lua"):read("*a")
chk("y es HarfordAdmin quien lo abre",
    admin:find("HarfordDnDConditions.CanAnswerNpcStates = function()", 1, true) ~= nil, true)

-- ─── VARIOS DMs: MANDA EL LIDER ─────────────────────────────────────────────
-- Puede haber dos o mas DMs, pero el principal suele ser el lider del grupo. Sin desempate los dos
-- contestan y, como la lista SUSTITUYE el saco entero, el segundo pisa al primero: si ese segundo
-- acaba de llegar y aun no sabe nada, borra lo bueno.
local i3 = assert(cond:find("function API.FuenteNpcGana", 1, true))
local f3 = assert(cond:find("local function EsElLider", i3, true))
local ent3 = { tonumber = tonumber, tostring = tostring, API = {},
    ShortName = function(n) return tostring(n or ""):match("^[^%-]+") or "" end }
local h
if setfenv then h = assert(cargar(cond:sub(i3, f3 - 1) .. " return API")); setfenv(h, ent3)
else h = assert(cargar(cond:sub(i3, f3 - 1) .. " return API", "t", "t", ent3)) end
local G = h().FuenteNpcGana

print("Entre dos DMs manda el lider")
chk("sin nada previo, entra", G(nil, false, "Dos", 100, 15), true)
local delLider = { sender = "Uno", lider = true, cuando = 100 }
chk("un secundario NO pisa al lider", G(delLider, false, "Dos", 105, 15), false)
chk("el lider SI pisa al secundario",
    G({ sender = "Dos", lider = false, cuando = 100 }, true, "Uno", 105, 15), true)
-- Si el lider hablo hace mucho, su foto ya no es de fiar y el secundario puede tomar el relevo.
chk("pasada la ventana, el secundario toma el relevo", G(delLider, false, "Dos", 200, 15), true)
-- Y nadie se bloquea a si mismo: el mismo DM tiene que poder actualizar lo que dijo antes.
chk("el mismo se actualiza siempre", G(delLider, true, "Uno", 105, 15), true)
chk("aunque su rol haya cambiado", G(delLider, false, "Uno", 105, 15), true)
chk("y con realm en el nombre tambien", G(delLider, false, "Uno-Apertus", 105, 15), true)
chk("dos secundarios: gana el ultimo",
    G({ sender = "Dos", lider = false, cuando = 100 }, false, "Tres", 105, 15), true)

print("El DM secundario deja hablar antes al principal")
chk("espera antes de contestar",
    cond:find("C_Timer.After(API.RETRASO_DM_SECUNDARIO", 1, true) ~= nil, true)
-- Pero NO se calla: si el lider no es DM, nadie contestaria y quien entra se queda a ciegas.
chk("pero acaba contestando igual",
    cond:find("API.SendNpcStatesTo(target, true)", 1, true) ~= nil, true)
chk("estando solo se cuenta como lider",
    cond:find("if not (IsInGroup and IsInGroup()) then return true end", 1, true) ~= nil, true)

-- ─── LA LISTA NO SE PIERDE NI SE PARTE MAL ──────────────────────────────────
-- `Send` no mide nada: por encima de 255 bytes CTL lanza error y el envio directo lo descarta
-- callado. Una lista larga se perdia ENTERA y quien pregunto no recibia nada -- ni siquiera una
-- parte. Y `sourceName` iba entre `:` dentro de una lista unida por `,` sin escapar.
print("Un nombre con separadores no rompe el parseo")
local conRaros = S.SerializeConditionList("Creature-1", "Ogro", {
    { id = "prone", duration = "manual", turns = 0, level = 0,
      sourceName = "Ana:Bea,Cid", contador = 2 },
})
local _, _, leidos = S.DeserializeConditionList(conRaros)
chk("el origen vuelve entero", leidos[1] and leidos[1].sourceName, "Ana:Bea,Cid")
chk("y no parte la entrada en trozos", #leidos, 1)
chk("el contador tambien", leidos[1] and leidos[1].contador, 2)

print("Una lista larga se recorta en vez de perderse")
local muchos = {}
for i = 1, 30 do
    muchos[i] = { id = "prone", duration = "target_turn_start", turns = 3, level = 0,
                  sourceName = "NombreLargoDeJugador" .. i, contador = i }
end
local payload, recortado = S.SerializeConditionList("Creature-0-1234-5678-90123-45678-000012ABCD",
    "Un NPC con nombre largo", muchos)
chk("cabe en el limite", #payload <= S.MAX_CONDLIST_BYTES, true)
chk("y avisa de que recorto", recortado, true)
-- Lo que queda tiene que seguir siendo legible: recortar por el final, no por la mitad de una
-- entrada.
local _, _, parciales = S.DeserializeConditionList(payload)
chk("lo que queda se lee", #parciales > 0, true)
chk("y cada entrada esta completa", parciales[1] and parciales[1].id, "prone")
-- Una lista corta no se toca.
local corta = { { id = "prone", duration = "manual", turns = 0, level = 0 } }
local p2, r2 = S.SerializeConditionList("g", "n", corta)
chk("una lista corta no se recorta", tostring(r2), "false")

-- ─── LO MIO CADUCA EN MI TURNO, SE LLAME COMO SE LLAME ──────────────────────
-- Esquivar y Preparar guardan tu nombre como origen y caducan al empezar TU turno. Pero si tu
-- turno es el bloque de PJs, la entrada se llama "PJs" y los nombres no casaban: el estado no se
-- retiraba nunca.
print("El turno propio se reconoce aunque se llame PJs")
chk("hay una nocion de turno mio", cond:find("local function EsMiTurno(entry)", 1, true) ~= nil, true)
chk("el hueco colectivo cuenta", cond:find('if k == "players" then return true end', 1, true) ~= nil, true)
-- Y el turno de un BLOQUE caduca lo de TODOS los suyos, uno por uno de su lista de miembros. Lo
-- llevaba una entrada sintetica que fabricaba el avance por bloques; al retirarse ese modo la
-- tarjeta paso a ser una entrada normal, y sin esto un turno de `Enemigos` no caducaba nada.
chk("y un bloque caduca lo de los suyos",
    cond:find('if kind == "players" or kind == "generic" then', 1, true) ~= nil, true)
chk("recorriendo su lista",
    cond:find('for _, m in ipairs(entry.miembros or {}) do', 1, true) ~= nil, true)
chk("se sabe que un registro es mio", cond:find("local function EsMio(guid, name)", 1, true) ~= nil, true)
-- Va ANTES del resto: el hueco colectivo no tiene ni mi guid ni mi nombre, asi que ninguna de las
-- comparaciones de abajo podria acertar.
chk("y se comprueba lo primero",
    cond:find("if EsMio(guid, name) and EsMiTurno(entry) then return true end", 1, true) ~= nil, true)
-- Sin romper lo de siempre: un estado AJENO no puede caducar en mi turno.
chk("pero lo ajeno sigue casando por identidad",
    cond:find('or (name ~= "" and ShortName(name) == ShortName(entry.name))', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
