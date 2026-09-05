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
chk("el fin tambien tiene aviso propio", turnos:find('"TEND|"', 1, true) ~= nil, true)
local aplicarTurno = assert(turnos:find("local function ApplyTurnNotice", 1, true))
chk("un turno retrasado fuera de combate se descarta",
    turnos:find("HarfordTurnOrderAPI.HasActiveCombat()", aplicarTurno, true) ~= nil, true)
chk("el fin no dispara oyentes de cambio de turno",
    turnos:find('opcode ~= "TURN" and opcode ~= "TEND"', 1, true) ~= nil, true)
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

-- ─── LA FOTO VIAJA COMPRIMIDA ───────────────────────────────────────────────
-- Esta es de COMPORTAMIENTO, no de texto: comprime, trocea con el codec real, reensambla y
-- descomprime, y compara byte a byte. LibDeflate vive en el cliente (EpsilonLib), no en el repo,
-- asi que si no esta se salta en vez de fallar.
do
    local rutaLib = "G:/Epsilon/_retail_/Interface/AddOns/EpsilonLib/Lib/LibDeflate/LibDeflate.lua"
    local hay = io.open(rutaLib)
    if not hay then
        print("La foto viaja comprimida  (saltada: LibDeflate no esta en este equipo)")
    else
        hay:close()
        local D = dofile(rutaLib)
        print("La foto viaja comprimida")
        local trozo = "1,Nombrelargo,npc,Nombrelargo,,28,34,Interface" .. string.char(92)
            .. "Icons" .. string.char(92) .. "inv_misc_head_undead_01,12345,15,5,ff00ff"
        local original = "STATE|1|~~activo|" .. string.rep(trozo .. ";", 20)
        local marca = "Z|"
        local comprimido = marca .. D:EncodeForWoWAddonChannel(D:CompressDeflate(original, { level = 9 }))
        chk("encoge de verdad", #comprimido < #original, true)
        -- Lo que importa no son los bytes sino los MENSAJES: el reensamblado es todo o nada y no
        -- hay acuse ni reintento, asi que cada trozo de menos es una oportunidad menos de perderlo.
        chk("y en menos trozos",
            #C.SplitEscapedChunks(comprimido) < #C.SplitEscapedChunks(original), true)
        local juntos = {}
        for i, tz in ipairs(C.SplitEscapedChunks(comprimido)) do juntos[i] = C.UnescapeChunk(tz) end
        chk("reensambla identico", table.concat(juntos) == comprimido, true)
        local final = D:DecompressDeflate(D:DecodeForWoWAddonChannel(table.concat(juntos):sub(#marca + 1)))
        chk("y vuelve al original exacto", final == original, true)
    end
end

-- La marca solo se pone cuando NO cabe en un mensaje: por debajo de eso se manda en claro y lo
-- entiende cualquier cliente, incluido uno sin actualizar.
chk("solo se comprime lo que no cabe",
    turnos:find("payload = Comprimir(payload) or payload", 1, true) >
    turnos:find("if #payload <= TURN_SINGLE_MESSAGE_LIMIT then", 1, true), true)
-- La compresion vive en el TRANSPORTE, no aqui: la usan varios sistemas y duplicarla seria tener
-- dos formatos de cable que divergen sin avisar.
local sync = io.open("Harford/Core/HarfordSync.lua"):read("*a")
chk("y vive en el transporte", sync:find("function HarfordSync.Comprimir", 1, true) ~= nil, true)
-- Si no encoge, no compensa.
chk("si no encoge se manda en claro",
    sync:find("if #codificado + #HarfordSync.MARCA_COMPRIMIDO >= #payload then return nil end", 1, true) ~= nil, true)
-- Y NUNCA en el vault de fase: alli trocea EpsilonLib, el servidor lo persiste y sobrescribir con
-- menos datos deja segmentos colgados -- una via real de corrupcion.
chk("y avisa de que el vault de fase queda fuera",
    sync:find("NO se usa para el vault de fase", 1, true) ~= nil, true)

-- ─── EL COMPRIMIDO DE UN SOLO MENSAJE TAMBIEN SE ENTIENDE ──────────────────
-- El agujero de las mesas MEDIANAS: una foto de 300-900 bytes comprime por debajo del limite del
-- mensaje unico y llega ENTERA con su marca (`Z|...`). El enrutado por opcode leia "Z", no
-- encontraba rama y la descartaba en silencio -- la grande se trocea y funcionaba, la pequenia va
-- en claro y funcionaba, y justo la mediana se perdia. Se descomprime ANTES de mirar el opcode.
print("El comprimido de un solo mensaje se enruta")
chk("se descomprime antes de leer el opcode",
    turnos:find("local mensaje = Descomprimir(tostring(message or \"\"))", 1, true) <
    turnos:find("local opcode = message:match(\"^([^|]+)\")", 1, true), true)
-- Y las OTRAS dos rutas con compresion no tienen puerta de prefijo que saltar: sus
-- deserializadores descomprimen dentro y se llaman con el mensaje crudo.
local comm = io.open("Harford/DnD/Engine/HarfordDnDComm.lua"):read("*a")
chk("equipo y progresion llaman al deserializador sin puerta de opcode",
    comm:find("HarfordSync.DeserializeDnDClassProgression(message)", 1, true) ~= nil
    and comm:find("HarfordSync.DeserializeDnDEquipment(message)", 1, true) ~= nil, true)

-- ─── LA VIDA DEL NPC LLEGA, Y CON SUS CAMPOS EN SU SITIO ────────────────────
-- Doble fallo que se tapaba a si mismo: el manejador de `THP` vivia dentro del aviso de turno, a
-- donde el enrutador solo manda los `TURN` --asi que nunca le llegaba nada-- y ademas leia el guid
-- del tercer campo cuando el emisor lo manda en el segundo. Cero sintomas en el emisor, y la vida
-- del NPC sin compartirse, que era todo el proposito del mensaje.
print("La vida del NPC llega y casa campo a campo")
chk("el enrutador tiene rama para THP",
    turnos:find('elseif opcode == "THP" then', 1, true) ~= nil, true)
chk("con manejador propio",
    turnos:find("local function ApplyNpcHealth(message)", 1, true) ~= nil, true)
-- De COMPORTAMIENTO: se construye el mensaje COMO EL EMISOR y se parsea CON EL PATRON DEL
-- RECEPTOR, sacado del fichero. Si alguien cambia un lado y no el otro, esto casca.
local patron = turnos:match('match%("(^THP[^"]+)"%)')
chk("el patron del receptor se encuentra", patron ~= nil, true)
if patron then
    local mensaje = table.concat({ "THP", "Creature-0-1-2-3-4-5", "18", "34" }, "|")
    local guid, hp, mx = mensaje:match(patron)
    chk("el guid sale del campo del guid", guid, "Creature-0-1-2-3-4-5")
    chk("la vida del campo de la vida", hp, "18")
    chk("y el maximo del suyo", mx, "34")
end

-- ─── LA SUPRESION APUNTA, NO TIRA ───────────────────────────────────────────
-- El receptor envuelve la aplicacion en `suppressBroadcast` para no rebotar lo recibido. Pero en
-- TJOIN e INITRES el DM CAMBIA la lista al recibir, y difundirla es el proposito: el descarte a
-- secas hacia que quien se unia no recibiera nunca la foto con el dentro, y que la iniciativa
-- devuelta por un jugador reordenara la lista SOLO en el cliente del DM.
print("La supresion apunta el broadcast, no lo tira")
chk("pedirlo suprimido lo apunta",
    turnos:find("if suppressBroadcast then broadcastSuprimido = true return end", 1, true) ~= nil, true)
chk("y al levantarla se dispara",
    turnos:find("if broadcastSuprimido then", 1, true) ~= nil, true)
-- El orden importa: primero levantar, luego disparar, o se re-apuntaria a si mismo.
chk("despues de levantar la supresion",
    turnos:find("suppressBroadcast = false", 1, true) <
    turnos:find("if broadcastSuprimido then", 1, true), true)

-- ─── QUIEN LLEGA CON EL TURNO EMPEZADO SE RECONCILIA ────────────────────────
-- Unirse durante el turno de PJs, o volver de una desconexion: el aviso de "es tu turno" paso
-- antes de que estuvieras, asi que nadie arrancaba tu contador ni tu economia y ese turno te
-- movias gratis. La foto que te trae al combate dispara ahora la reconciliacion.
local attackui = io.open("Harford/DnD/UI/HarfordDnDAttackUI.lua"):read("*a")
print("Llegar con el turno empezado reconcilia")
chk("la foto recibida la dispara",
    turnos:find("pcall(HarfordDnDAttackUI.ReconciliarTurnoEnCurso)", 1, true) ~= nil, true)
chk("y existe", attackui:find("function API.ReconciliarTurnoEnCurso()", 1, true) ~= nil, true)
-- Con sello valido (mismo guid y asalto: /reload limpio) se RETOMA lo gastado; sin sello (recien
-- unido, o crash sin guardar) el turno empieza de cero. Resetear siempre habria devuelto la
-- accion gastada con solo recargar, que es el exploit que el sello existe para impedir.
chk("economia: retoma el sello o resetea",
    attackui:find("not (T.RestoreFromStore and T.RestoreFromStore()) and T.Reset", 1, true) ~= nil, true)
-- Y el arranque tras restaurar CONSERVA los metros: `ArrancarSeguimiento` pone el contador a
-- cero --es su trabajo, empieza un turno-- asi que la reanudacion del /reload restauraba los
-- metros y acto seguido los borraba: recargar a mitad de turno regalaba el movimiento entero.
chk("movimiento: retomar no pone a cero",
    attackui:find("local function RetomarSeguimiento()", 1, true) ~= nil, true)
chk("y el /reload usa retomar, no arrancar",
    attackui:find("if not RetomarSeguimiento() then return end", 1, true) ~= nil, true)

-- ─── EL TURNO AJENO TE ANCLA DONDE ESTAS, SIEMPRE ──────────────────────────
-- El camino viejo solo ponia el ancla al PARAR un seguimiento vivo: quien se unia, recargaba o
-- empezaba el combate en turno enemigo no tenia ni ancla ni motor, y cruzaba la sala gratis. El
-- oyente de CAMBIO de turno ancla tu posicion de ese momento e instala el motor, incondicional.
print("El turno ajeno ancla siempre")
local atk = io.open("Harford/DnD/UI/HarfordDnDAttackUI.lua"):read("*a")
chk("hay oyente de cambio de turno sembrado",
    atk:find("T._turnChangedListeners[#T._turnChangedListeners + 1]", 1, true) ~= nil, true)
chk("ancla FRESCA en la posicion del cambio",
    atk:find("local ancla = CapturarAncla()", 1, true) ~= nil, true)
chk("e instala el motor aunque nunca arrancara",
    atk:find('motor:SetScript("OnUpdate", OnUpdate)', 1, true) ~= nil, true)
-- El DM dirigiendo TAMBIEN ancla y para el contador (2026-09-05): antes salia antes de capturar
-- y eso le dejaba sin TP de vuelta al empezar su turno Y con el contador contandole el roaming
-- (el muro de agotamiento le tironeaba en el turno enemigo). De la vigilancia le libra el guard
-- del OnUpdate; el TP de vuelta vive en ReiniciarPorTurno.
chk("solo el NPC poseido queda fuera del anclado",
    atk:find("if LlevandoNpc() then return end", 1, true) ~= nil
    and atk:find("if LlevandoNpc() or DirigiendoLaEscena() then return end", 1, true) == nil, true)
chk("la vigilancia si salta al DM",
    atk:find("and not DirigiendoLaEscena() then", 1, true) ~= nil, true)
chk("y al empezar su turno se le devuelve al ancla",
    atk:find("if API.RecordedMovementAnchor and DirigiendoLaEscena() and EnCombate() then", 1, true) ~= nil, true)

-- ─── EL "NO" DE UNIRSE SE CONTESTA ──────────────────────────────────────────
-- "Te unes al combate" era optimista: se imprimia al PEDIR. Si el DM no podia meterte, tu unica
-- pista era que el boton seguia ahi. El motivo viaja ahora de vuelta (TJOINNO por susurro); el
-- "si" no necesita mensaje porque la foto contigo dentro ya es la confirmacion.
print("El no de unirse se contesta")
chk("las tres negativas responden", (function()
    local _, n = turnos:gsub('DecirNo%(', '')
    return n
end)(), 4)  -- 3 llamadas + 1 definicion
chk("por susurro al que pidio", turnos:find('"TJOINNO|" .. tostring(motivo), "WHISPER", sender', 1, true) ~= nil, true)
chk("y el receptor lo cuenta", turnos:find('elseif opcode == "TJOINNO" then', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
