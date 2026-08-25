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
chk("y el remitente tiene que ser el interesado",
    cond:find("if ShortName(sender) ~= ShortName(name) then return false end", 1, true) ~= nil, true)

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

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
