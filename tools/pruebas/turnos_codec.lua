-- Arnes del codec de turnos. Ya no hace falta simular frames ni el store.
strsplit = function(sep, str)
    local out = {}
    for part in (tostring(str) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do out[#out+1] = part end
    return (unpack or table.unpack)(out)
end
Ambiguate = function(n) return (tostring(n):match("^[^-]+")) or n end
GetRealmName = function() return "Epsilon" end
dofile("Harford/Frames/HarfordTurnsCodec.lua")
local C = HarfordTurnsCodec
C.Init({ NormalizeKind = function(k)
    local ok = { round=1, generic=1, players=1, player=1, npc=1 }
    k = tostring(k or "")
    return ok[k] and k or "npc"
end })
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-22s %s", n, tostring(real):sub(1,22), ok and "ok" or ("FALLA: " .. tostring(esp))))
end

print("Escapado: los separadores del protocolo no pueden colarse")
for _, t in ipairs({ "Grom|Hellscream", "a,b;c", "100%", "Nombre normal", "|c00ff00Verde|r", "" }) do
    chk("ida y vuelta: " .. (t == "" and "(vacio)" or t), C.UnescapeText(C.EscapeText(t)), t)
end
chk("no queda ninguna | cruda", C.EscapeText("a|b"):find("|", 1, true), "nil")
chk("no queda ninguna , cruda", C.EscapeText("a,b"):find(",", 1, true), "nil")
chk("no queda ningun ; crudo", C.EscapeText("a;b"):find(";", 1, true), "nil")

print("Entrada completa: ida y vuelta")
local e = { id = "abc-1", name = "Gnoll|Jefe, el 100%", kind = "npc", initiative = 17,
            hp = 23, maxHp = 40, hidden = false, mana = 3, maxMana = 9,
            unitName = "Gnoll-Epsilon", icon = "Interface/Icons/X", displayId = 5,
            armorClass = 15 }
local v = C.DeserializeEntry(C.SerializeEntry(e))
chk("nombre con separadores intacto", v.name, e.name)
chk("iniciativa", v.initiative, 17)
chk("vida", v.hp .. "/" .. v.maxHp, "23/40")
chk("CA", v.armorClass, 15)
chk("tipo", v.kind, "npc")

print("Tipos: lo que llega raro se normaliza")
local raro = C.DeserializeEntry(C.SerializeEntry({ id="x", name="N", kind="focus" }))
chk('un cliente viejo manda "focus"', raro.kind, "npc")

print("Troceado y reensamblado de una carga larga")
local largo = string.rep("Nombre|con,separadores;raros ", 40)
local trozos = C.SplitEscapedChunks(largo)
print(string.format("  %d trozos para %d caracteres", #trozos, #largo))
local buf = {}
local hecho = false
for i, t in ipairs(trozos) do
    local r = C.ApplyChunked("SCHUNK|tid|" .. i .. "|" .. #trozos .. "|" .. t, "Pepe", "SCHUNK", "",
        function(m) buf[1] = m hecho = true return true end)
end
chk("se reensambla completo", hecho, true)
chk("y es identico al original", buf[1], largo)
-- ─── LA VIDA TEMPORAL VIAJA ─────────────────────────────────────────────────
-- `tempHp` se usaba para pintar la barra y para ABSORBER dano, pero no estaba entre los campos
-- que se envian: cada cliente calculaba el mismo golpe con una absorcion distinta, y nadie mas
-- que el DM veia la vida temporal de un NPC.
local codec = io.open("Harford/Frames/HarfordTurnsCodec.lua"):read("*a")
print("La vida temporal de un NPC se comparte")
chk("se envia", codec:find("tostring(entry.tempHp or 0),", 1, true) ~= nil, true)
chk("y se recibe", codec:find("tempHp = SafeNumber(tempHp, 0),", 1, true) ~= nil, true)
-- Detras de `bando`, que es el ultimo que se anadio: un cliente sin actualizar lo ignora en vez de
-- descuadrarse todos los campos.
chk("y va el ultimo, para no romper a los viejos",
    codec:find("tostring(entry.tempHp or 0)", 1, true) > codec:find("EscapeText(entry.bando)", 1, true), true)

-- Empezar el combate era mudo para todos menos para el DM: los demas se encontraban metidos en
-- turnos sin que nada se lo dijera.
local turnos = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
print("Empezar el combate avisa a la mesa")
chk("hay aviso propio", turnos:find('"TSTART|"', 1, true) ~= nil, true)
chk("y quien lo recibe lo ve", turnos:find("COMIENZA EL COMBATE", 1, true) ~= nil, true)
chk("se le abre la ventana", turnos:find("if TurnFrame and not TurnFrame:IsShown() then TurnFrame:Show() end", 1, true) ~= nil, true)
-- Mensaje PROPIO y no deducido de la foto: quien llega tarde tambien recibe una foto con combate
-- activo, y deducirlo de ahi le anunciaria un combate que empezo hace cinco asaltos.
local combate = io.open("Harford/Frames/HarfordTurnsCombat.lua"):read("*a")
chk("la foto se manda ANTES que el aviso",
    combate:find("SendState()", 1, true) < combate:find("SendCombatStart(combatientes)", 1, true), true)

-- ─── EL AVISO DE TURNO SE BASTA SOLO ────────────────────────────────────────
-- Avanzar el turno mandaba TAMBIEN la foto entera: 12 mensajes troceados por pulsacion, cuando el
-- aviso ya lleva todo lo que el receptor necesita. Y basta perder UNO de los doce para que el
-- receptor descarte el estado completo en silencio, porque no hay acuse ni reintento.
local turnos = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
print("El aviso de turno lleva el asalto")
-- Va en el quinto hueco, que iba vacio desde que se retiro el avance por bloques: asi no cambia el
-- numero de campos y un cliente sin actualizar lo ignora como ignoraba el hueco.
chk("se envia", turnos:find("tostring(store.asalto or 0),", 1, true) ~= nil, true)
chk("se recibe", turnos:find("local asaltoRecibido = SafeNumber(adminRaw, 0)", 1, true) ~= nil, true)
-- Un cliente anterior manda ahi la fase (texto): `SafeNumber` la deja en 0 y se ignora, que es lo
-- que se quiere -- no bajarle el asalto a nadie por recibir un aviso viejo.
chk("y un aviso viejo no lo pisa", turnos:find("if asaltoRecibido > 0 then store.asalto = asaltoRecibido end", 1, true) ~= nil, true)
-- `OnTurnChanged` lee `entry.asalto` para bajar las duraciones medidas en asaltos.
chk("y la entrada se lo lleva puesta",
    turnos:find("if asaltoRecibido > 0 and type(entry) == \"table\" then entry.asalto = asaltoRecibido end", 1, true) ~= nil, true)

print("Avanzar y retroceder NO mandan la foto")
chk("hay una marca local sin difusion", turnos:find("MarcarLocal = function()", 1, true) ~= nil, true)
-- Se declara adelantada: se usa en `NextTurn`, muy por encima de donde se asigna. Una local
-- declarada despues de usarse se compila como lectura de global -- o sea nil.
chk("declarada antes de usarse",
    turnos:find("local MarcarLocal", 1, true) < turnos:find("MarcarLocal = function()", 1, true), true)
local nextIni = turnos:find("local function NextTurn()", 1, true)
local nextFin = turnos:find("local function PrevTurn()", nextIni, true)
chk("y avanzar ya no difunde la foto",
    turnos:sub(nextIni, nextFin):find("MarkChanged()", 1, true) == nil, true)
local prevFin = turnos:find("local function StartCombat", nextFin, true) or (nextFin + 3000)
chk("retroceder tampoco",
    turnos:sub(nextFin, prevFin):find("MarkChanged()", 1, true) == nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
