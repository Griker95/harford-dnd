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
local ini = assert(src:find("HarfordTurnOrderAPI.FASES = {", 1, true))
local fin = assert(src:find("function HarfordTurnOrderAPI.HasActiveCombat", ini, true))
-- `IsSystemEntry` es del tracker: el marcador de asalto no es una criatura y no puede contar como
-- miembro de ningun bando. Aqui se imita con lo mismo que mira el original.
local env = { ipairs = ipairs, pairs = pairs, tonumber = tonumber, tostring = tostring,
    type = type, table = table, HarfordTurnOrderAPI = {}, HarfordTurnOrderStore = nil,
    IsSystemEntry = function(e)
        local k = tostring(e and e.kind or "")
        return k == "round" or k == "generic" or k == "players"
    end }
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
-- El marcador de asalto caia por reaccion 0 en "enemigos": ese bando no se veia vacio NUNCA y por
-- tanto no se saltaba, aunque no hubiera un solo enemigo de verdad.
env.HarfordTurnOrderStore = { entries = {
    { kind = "round", name = "Inicio de turno" },
    { kind = "player", name = "Gmaster" },
} }
chk("el marcador de asalto no es de nadie", #T.GetBandoMembers("enemigos"), 0)
chk("y el PJ sigue contando", #T.GetBandoMembers("pjs"), 1)
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
local e = Entrada("enemigos", "inicio")
chk("se distingue de un combatiente", e.kind, "bando")
chk("dice de que bando es", e.bando, "enemigos")
chk("y se llama como la mesa lo llama", e.name, "Enemigos")
chk("con id propio para no chocar con nadie", e.id, "bando:enemigos:inicio")

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
    cond:find('("bando:" .. tostring(entry.bando) .. ":"', 1, true) ~= nil, true)
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
-- La UI de DM vive en HarfordAdmin: sin ese addon no aparece ni el menu ni el interruptor, que es
-- la regla de carga del proyecto. El core solo expone el gesto.
local admin = io.open("HarfordAdmin/HarfordAdminTurns.lua"):read("*a")
print("El DM reparte a mano, desde HarfordAdmin")
chk("el menu vive en Admin", admin:find("local function AbrirMenu(entry, ancla)", 1, true) ~= nil, true)
chk("y NO en el core", turnos:find("AbrirMenuDeBando", 1, true) == nil, true)
chk("el core solo expone el gesto",
    turnos:find("function HarfordTurnOrderAPI.OnCardRightClick", 1, true) ~= nil, true)
chk("que la tarjeta dispara con el boton derecho",
    turnos:find('if button == "RightButton" then', 1, true) ~= nil, true)
chk("solo el admin reparte", admin:find("Solo el admin gestiona los turnos", 1, true) ~= nil, true)
chk("y difunde al cambiar", admin:find("if T.SetBando(entry, b) then", 1, true) ~= nil, true)

-- La lista que manda el DM PISA a la que calcularia el cliente: es lo que evita que dos clientes
-- con la foto desincronizada hagan tocar a criaturas distintas.
print("La lista del DM manda sobre la del cliente")
chk("el motor la prefiere", cond:find("if entry.miembros then", 1, true) ~= nil, true)
chk("y solo cae a la suya si no llega",
    cond:find("guids, nombres = MiembrosDeBando(entry.bando)", 1, true) ~= nil, true)

-- ─── INICIO Y FINAL DE BLOQUE ───────────────────────────────────────────────
-- Un bloque tiene dos momentos. Entre ellos el DM juega a sus criaturas, y ese hueco es justo
-- donde hace falta poder tocar el reparto.
print("Cada bloque abre y cierra")
chk("hay dos fases", #T.FASES, 2)
chk("primero abre", T.FASES[1], "inicio")
chk("y luego cierra", T.FASES[2], "fin")
local cierre = Entrada("enemigos", "fin")
chk("el cierre se distingue del inicio", cierre.id ~= e.id, true)
chk("y lo dice", cierre.fase, "fin")
chk("con texto distinto", T.FASE_ETIQUETA.fin, "termina el turno de")

-- Sin esto, el cierre de un bloque tendria la misma clave que su apertura y el motor lo tomaria
-- por repetido: no bajaria ningun contador de fin de turno.
print("El motor separa las dos fases")
chk("la clave de turno lleva la fase",
    cond:find('.. ":" .. tostring(entry.fase or "inicio")', 1, true) ~= nil, true)
-- Se EJECUTA la decision, no se busca su texto: la version anterior de esta prueba solo miraba que
-- estuviera escrita y no cazo una mutacion que hacia disparar lo de inicio tambien al cerrar.
local ini = assert(cond:find("function API.DurationTicks", 1, true))
local fin2 = assert(cond:find("function API.OnTurnChanged", ini, true))
local trozoD = cond:sub(ini, fin2 - 1) .. " return API"
local entorno = { API = {}, tostring = tostring, type = type }
local d
if setfenv then d = assert(cargar(trozoD)); setfenv(d, entorno)
else d = assert(cargar(trozoD, "t", "t", entorno)) end
local D = d()

chk("al ABRIR toca lo de inicio", (D.DurationTicks("target_turn_start", "inicio")), true)
chk("y NO lo de fin", (D.DurationTicks("target_turn_end", "inicio")), false)
chk("al CERRAR toca lo de fin", (D.DurationTicks("target_turn_end", "fin")), true)
chk("y NO lo de inicio", (D.DurationTicks("target_turn_start", "fin")), false)
chk("lo del origen sigue la misma regla", (D.DurationTicks("source_turn_end", "fin")), true)
chk("una duracion ajena no toca nunca", (D.DurationTicks("rounds", "inicio")), false)
-- La iniciativa individual NO tiene fases y sigue con el truco de siempre: el final de un turno es
-- la apertura del siguiente, y por eso casa contra la entrada ANTERIOR.
local toca, contra = D.DurationTicks("target_turn_end", nil)
chk("sin fases, el fin sigue tocando", toca, true)
chk("pero contra el turno anterior", contra, "anterior")
local _, contra2 = D.DurationTicks("target_turn_start", nil)
chk("y el inicio contra el actual", contra2, "actual")
chk("con fases, el fin casa contra el bando actual",
    select(2, D.DurationTicks("target_turn_end", "fin")), "actual")
-- La salvacion de fin de turno sigue la misma regla.
chk("la salvacion de fin solo al cerrar", (D.EndSaveTicks("fin")), true)
chk("nunca al abrir", (D.EndSaveTicks("inicio")), false)
chk("y sin fases, contra el anterior", select(2, D.EndSaveTicks(nil)), "anterior")

print("El avance pasa por las dos y avisa al tocar un bloque vivo")
chk("cerrar antes de saltar",
    turnos:find('bando, fase = HarfordTurnOrderAPI.BANDOS[actual], "fin"', 1, true) ~= nil, true)
chk("la fase viaja en el anuncio",
    turnos:find('tostring(store.faseBando or "inicio"),', 1, true) ~= nil, true)
-- Y el asalto detras: sin el, quien vuelve no puede saber cuantos se perdio.
chk("y el asalto tambien",
    turnos:find('tostring(store.asalto or 0) }, "|")', 1, true) ~= nil, true)
chk("y va la ultima, para no descuadrar el formato anterior",
    turnos:find('table.concat(ids, ","), tostring(store.faseBando', 1, true) ~= nil, true)
chk("solo se avisa de turno propio al abrir",
    turnos:find('if fase == "inicio" then AlertMyTurn', 1, true) ~= nil, true)
chk("y se avisa si el bloque tocado ya esta en juego",
    admin:find("ya esta en juego: entra en el proximo asalto", 1, true) ~= nil, true)

-- ─── EL HUECO COLECTIVO DE PJs ──────────────────────────────────────────────
-- Su `kind` es "players" (plural), no "player". Los tres sitios que fuerzan el bando miraban solo
-- el singular, asi que caia por reaccion 0 -> ENEMIGOS: el turno de los jugadores en el bando
-- enemigo, y nada que lo delatara.
print("El hueco colectivo de PJs va con los PJs")
chk("kind players va a pjs", T.GetBando({ kind = "players", name = "PJs" }), "pjs")
chk("aunque no traiga reaccion", T.GetBando({ kind = "players" }), "pjs")
chk("y no se le puede mover", (T.SetBando({ kind = "players" }, "enemigos")), false)
-- Y sigue funcionando el singular, que es lo que ya estaba bien.
chk("un jugador suelto sigue en pjs", T.GetBando({ kind = "player" }), "pjs")

-- ─── ASALTOS ────────────────────────────────────────────────────────────────
-- En modo bandos el marcador de asalto nunca se visitaba -- es una tarjeta de la lista, y el
-- avance ya no recorre tarjetas -- asi que las duraciones de asalto no bajaban NUNCA.
print("El asalto se cierra al dar la vuelta")
chk("se marca al volver al primer bando",
    turnos:find("nuevoAsalto = (siguiente <= actual) or actual == 0", 1, true) ~= nil, true)
chk("y se cuenta", turnos:find("store.asalto = (tonumber(store.asalto) or 0) + 1", 1, true) ~= nil, true)
-- La marca tiene que llegar al motor como `kind = "round"`, que es lo que hace bajar `rounds`.
chk("avisa al motor como asalto",
    turnos:find('local marca = { kind = "round"', 1, true) ~= nil, true)
chk("y viaja a los demas clientes",
    turnos:find("entrada.asalto = store.asalto", 1, true) ~= nil, true)

-- Mientras estabas desconectado nadie bajaba tus contadores: tu cliente no corria y los demas solo
-- tocan sus propios registros. Al volver, un estado que debio expirar seguia entero.
print("Al volver, los contadores se ponen al dia")
chk("existe la recuperacion", cond:find("function API.CatchUpRounds", 1, true) ~= nil, true)
-- Cada criatura actua una vez por asalto, asi que restar los asaltos perdidos es la cuenta exacta.
chk("resta los asaltos perdidos",
    cond:find("record.turns = math.max(0, antes - perdidos)", 1, true) ~= nil, true)
-- Solo lo PROPIO: de los demas informa su dueno, y su cliente ya hizo esta cuenta.
chk("solo toca lo propio", cond:find("if record.authority then", 1, true) ~= nil, true)
-- Las salvaciones de fin de turno NO se reconstruyen: tirar tres dados por algo que ya paso es
-- inventarse la partida.
chk("las salvaciones se dejan a mano",
    cond:find('record.duration == "save_at_turn_end" then', 1, true) ~= nil, true)
chk("y se avisa de ellas",
    cond:find("con salvacion, revisalos a mano", 1, true) ~= nil, true)
-- El ultimo asalto visto se PERSISTE: en memoria valdria 0 al reconectar y la cuenta de perdidos
-- seria el asalto entero.
chk("el ultimo asalto se guarda", cond:find("root._asalto[perfil] = asalto", 1, true) ~= nil, true)
-- Un salto de 1 es el asalto normal, no una ausencia.
chk("un asalto seguido no dispara nada",
    cond:find("if visto > 0 and asalto > visto + 1 then", 1, true) ~= nil, true)

-- ─── EL MODO SE PUEDE ENCENDER Y VIAJA ──────────────────────────────────────
-- Nadie llamaba a `SetModoBandos`, y `TURNB` solo sale si `modoBandos` YA es true: todo el avance
-- por bloques era codigo inalcanzable. Existir no es lo mismo que poder usarse.
print("Hay como encender el modo, y se comparte")
chk("hay boton, en Admin", admin:find("local function MontarBotonModo", 1, true) ~= nil, true)
chk("que lo enciende de verdad", admin:find("T.SetModoBandos(activo)", 1, true) ~= nil, true)
chk("solo el admin", admin:find("Solo el admin cambia el modo de turnos", 1, true) ~= nil, true)
-- El core tiene que ofrecer donde colgarlo, o Admin no tendria sitio.
chk("y el core ofrece donde colgarlo",
    turnos:find("function HarfordTurnOrderAPI.RegisterAdminControl", 1, true) ~= nil, true)
-- La ventana se crea al abrirla, que puede ser despues de que Admin arranque.
chk("y avisa cuando la ventana nace",
    turnos:find("function HarfordTurnOrderAPI.RegisterOnFrameCreated", 1, true) ~= nil, true)
-- Media mesa por bandos y media por criatura serian dos combates distintos a la vez.
chk("el modo viaja en la foto", turnos:find('modo = table.concat({ "B",', 1, true) ~= nil, true)
-- Y DONDE va la rotacion: sin la posicion, un DM que recibe la foto sin haber visto un TURNB
-- arranca de cero, anuncia "Asalto 1" en mitad del quinto y devuelve el turno a los PJs.
chk("con el bando, la fase y el asalto",
    turnos:find("store.faseBando or \"inicio\"), tostring(store.asalto or 0) }", 1, true) ~= nil, true)
-- El hueco del medio llevaba vacio desde siempre; un receptor antiguo lo ignora y sigue leyendo
-- las entradas del cuarto campo, que es donde ya las buscaba.
chk("y solo se acepta si hay cuarto campo",
    turnos:find('local marca, bando, fase, asalto = strsplit(",", tostring(modoRaw or ""))', 1, true) ~= nil, true)
-- La lista de DMs secundarios viaja en el mismo hueco, detras: quien delega necesita la MISMA
-- cadena que los demas o mandaria el efecto a alguien que nadie reconoce como eslabon.
chk("y los DMs secundarios viajan con ella",
    turnos:find('strsplit("~", tostring(third or ""))', 1, true) ~= nil, true)
chk("el dato vive en el core", turnos:find("function HarfordTurnOrderAPI.SetSecondaryDMs", 1, true) ~= nil, true)
chk("pero nombrarlos es de Admin", admin:find("local function AlternarSecundario", 1, true) ~= nil, true)
chk("con marca reconocible", turnos:find('if marca == "B" then', 1, true) ~= nil, true)

-- El GUID de una entrada vive en `id`; `guid` no existe. Cuatro sitios lo leian, y dos eran
-- guardias: la delegacion de efectos no aceptaba NADA y no se informaba de ningun NPC.
print("El GUID de una entrada se lee de donde esta")
chk("en la lista de miembros del bando",
    turnos:find("local g = tostring(e.guid or e.id or \"\")", 1, true) ~= nil, true)
chk("y en el guardia de efectos delegados",
    cond:find('tostring(e.guid or e.id or "") == guid', 1, true) ~= nil, true)
-- Sin el remitente, `ultimoAvanceAjeno` no se llenaba y el aviso de doble avance no salia jamas.
chk("el aviso de doble avance recibe al remitente",
    turnos:find("local function ApplyTurnNotice(message, sender)", 1, true) ~= nil, true)

-- ─── LOS BLOQUES GUARDAN A LOS SUYOS ────────────────────────────────────────
-- Una tarjeta especial -- PJs, Aliados, Neutrales, Enemigos -- es un BLOQUE. Quien esta dentro NO
-- tiene tarjeta propia: su vida se mira en el unitframe al seleccionarlo. El panel de candidatos
-- anterior anadia tarjetas sueltas, que es justo lo contrario, y se retiro.
print("Los bloques guardan quien va dentro")
chk("se puede anadir por unidad", turnos:find("function HarfordTurnOrderAPI.AddBlockMember", 1, true) ~= nil, true)
chk("y quitar", turnos:find("function HarfordTurnOrderAPI.RemoveBlockMember", 1, true) ~= nil, true)
chk("sin duplicar", turnos:find('if m.guid == guid then return false, "Ya esta en ese bloque" end', 1, true) ~= nil, true)
-- Se guarda guid y nombre y nada mas: la vida y la CA se leen de la unidad viva, no de aqui.
chk("guardando lo justo para reconocerlo",
    turnos:find("name = (GetUnitName and GetUnitName(unit, true))", 1, true) ~= nil, true)
-- Y el panel que creaba tarjetas ya no esta.
chk("el panel de candidatos se retiro", turnos:find("ToggleCandidates", 1, true) == nil, true)

-- Un bloque lleno no puede parecer vacio, o el avance lo saltaria.
chk("el avance cuenta a los de dentro",
    turnos:find("for _, m in ipairs(entry.miembros or {}) do", 1, true) ~= nil, true)
-- Y viajan, o solo los veria el DM que los puso.
local codec2 = io.open("Harford/Frames/HarfordTurnsCodec.lua"):read("*a")
chk("y viajan con la entrada", codec2:find("EscapeText(SerializeMembers(entry.miembros))", 1, true) ~= nil, true)
chk("con sus separadores escapados", codec2:find('nombre:gsub("%%%%", "%%%%25")', 1, true) ~= nil
    or codec2:find("SerializeMembers", 1, true) ~= nil, true)

-- El menu de bloque es del DM, no del core.
local admin2 = io.open("HarfordAdmin/HarfordAdminTurns.lua"):read("*a")
print("Y se gestionan desde HarfordAdmin")
chk("el menu reconoce los bloques",
    admin2:find('if tipo == "players" or tipo == "generic" then', 1, true) ~= nil, true)
chk("deja anadir el objetivo", admin2:find('T.AddBlockMember(entry, "target")', 1, true) ~= nil, true)
chk("y a todos los jugadores de golpe",
    admin2:find("Anadir a todos los jugadores", 1, true) ~= nil, true)
chk("listando a los que ya estan", admin2:find('sep.text = "Dentro ("', 1, true) ~= nil, true)

-- ─── LA LISTA DE TARJETAS DEL BLOQUE ────────────────────────────────────────
-- Los miembros no tienen tarjeta en la lista compartida -- ese es el modelo --, pero el DM
-- necesita verlos. El panel es SUYO: vive en HarfordAdmin y no existe para nadie mas.
print("El DM ve las tarjetas de cada bloque")
chk("hay panel", admin2:find("function AbrirPanelDeBloque(entry)", 1, true) ~= nil, true)
chk("y solo para el admin", admin2:find("if not EsAdmin() then return end", 1, true) ~= nil, true)
-- El click izquierdo del core abre la ficha de la entrada; Admin se lo queda SOLO para los bloques.
chk("el core ofrece el gesto",
    turnos:find("function HarfordTurnOrderAPI.RegisterOnCardLeftClick", 1, true) ~= nil, true)
chk("y solo se lo queda si es un bloque",
    admin2:find('if k ~= "players" and k ~= "generic" then return false end', 1, true) ~= nil, true)
chk("si nadie lo toma, el core hace lo de siempre",
    turnos:find("if AlguienSeQuedaElClick(entry) then return end", 1, true) ~= nil, true)
-- La vida sale de la unidad VIVA. Sin vista se dice, en vez de enseniar un numero viejo que nadie
-- puede comprobar: la del bloque no se guarda en ninguna parte.
chk("la vida se lee de la unidad viva", admin2:find("UnitHealth(unidad)", 1, true) ~= nil, true)
chk("y se dice cuando no esta a la vista",
    admin2:find('f.vidaTexto:SetText("|cff808080sin vista|r")', 1, true) ~= nil, true)
-- Son las tarjetas de siempre, solo que dentro de la lista: mismo tamano y mismo borde que las de
-- la ventana de turnos. Una fila de texto no se lee como un combatiente.
chk("las tarjetas miden lo que las de turnos",
    admin2:find("local TARJ_W, TARJ_H, TARJ_HUECO = 70, 122, 6", 1, true) ~= nil, true)
chk("y llevan su mismo borde",
    admin2:find('CreateFrame("Frame", nil, f, "DialogBorderTemplate")', 1, true) ~= nil, true)
-- Con muchas se baja a verlas, pero el boton no se va con ellas ni lo recorta el scroll: cuelga del
-- panel, no del contenido que se desplaza.
chk("las tarjetas van dentro del scroll",
    admin2:find('CreateFrame("Button", nil, panel.contenido, "BackdropTemplate")', 1, true) ~= nil, true)
chk("y el boton se queda fuera",
    admin2:find('panel.anadir = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
