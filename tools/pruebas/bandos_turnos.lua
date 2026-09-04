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

-- Los tres ficheros que se leen como texto para comprobar que el codigo dice lo que debe.
local turnos = src
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local admin = io.open("HarfordAdmin/HarfordAdminTurns.lua"):read("*a")

print("El hueco colectivo de PJs va con los PJs")
chk("kind players va a pjs", T.GetBando({ kind = "players", name = "PJs" }), "pjs")
chk("aunque no traiga reaccion", T.GetBando({ kind = "players" }), "pjs")
chk("y no se le puede mover", (T.SetBando({ kind = "players" }, "enemigos")), false)
-- Y sigue funcionando el singular, que es lo que ya estaba bien.
chk("un jugador suelto sigue en pjs", T.GetBando({ kind = "player" }), "pjs")

-- ─── ASALTOS ────────────────────────────────────────────────────────────────
-- El asalto sube al PASAR POR EL MARCADOR, que es una tarjeta mas de la lista. Lo contaba el
-- avance por bloques --el unico sitio donde se contaba--, asi que al retirarlo habria dejado de
-- contarse, y las duraciones medidas en asaltos dependen de esta cuenta.
print("El asalto sube al pasar por el marcador")
chk("se detecta el marcador",
    turnos:find('if activa and activa.kind == "round" then', 1, true) ~= nil, true)
chk("y se cuenta", turnos:find("store.asalto = (tonumber(store.asalto) or 0) + 1", 1, true) ~= nil, true)
chk("la tarjeta se lo lleva", turnos:find("activa.asalto = store.asalto", 1, true) ~= nil, true)

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
-- ─── EL MODO POR BLOQUES SE RETIRO ──────────────────────────────────────────
-- Habia dos formas de avanzar el turno --de criatura en criatura y de bloque en bloque-- con un
-- interruptor en la ventana. La de bloques no funcionaba bien y nadie sabia para que estaba, asi
-- que se quito: queda UNA. Los bloques siguen siendo tarjetas y siguen guardando a los suyos; lo
-- que se fue es el modo de avance.
print("El avance por bloques ya no existe")
chk("sin interruptor en Admin", admin:find("MontarBotonModo", 1, true) == nil, true)
chk("sin encenderlo desde fuera", turnos:find("SetModoBandos", 1, true) == nil, true)
chk("sin preguntarlo", turnos:find("IsModoBandos", 1, true) == nil, true)
chk("sin ramas por modo", turnos:find("if store.modoBandos then", 1, true) == nil, true)
chk("sin fases de turno", turnos:find("FASE_ETIQUETA", 1, true) == nil, true)
chk("sin entrada sintetica de bando", turnos:find("local function EntradaDeBando", 1, true) == nil, true)
chk("y ya no se emite el aviso por bloque",
    turnos:find('table.concat({ "TURNB"', 1, true) == nil, true)
-- Recibirlo SI se tolera: un cliente sin actualizar puede seguir mandandolo, y lo que no se
-- entiende se descarta en silencio en vez de aplicarse a medias.
chk("pero recibirlo no rompe", turnos:find('if opcode == "TURNB" then return false end', 1, true) ~= nil, true)
-- El hueco del modo se queda VACIO en la foto, no desaparece: el tercer campo es "modo~dms~estado"
-- y quitarlo descuadraria los otros dos en un cliente que aun no se haya actualizado.
chk("el hueco sigue en la foto", turnos:find('local modo = ""', 1, true) ~= nil, true)
chk("y los DMs secundarios viajan con el",
    turnos:find('strsplit("~", tostring(third or ""))', 1, true) ~= nil, true)
chk("el dato vive en el core", turnos:find("function HarfordTurnOrderAPI.SetSecondaryDMs", 1, true) ~= nil, true)
chk("pero nombrarlos es de Admin", admin:find("local function AlternarSecundario", 1, true) ~= nil, true)
-- El core tiene que ofrecer donde colgar los controles de DM, o Admin no tendria sitio.
chk("y el core sigue ofreciendo donde colgar",
    turnos:find("function HarfordTurnOrderAPI.RegisterAdminControl", 1, true) ~= nil, true)

-- El GUID de una entrada vive en `id`; `guid` no existe. Cuatro sitios lo leian, y dos eran
-- guardias: la delegacion de efectos no aceptaba NADA y no se informaba de ningun NPC.
print("El GUID de una entrada se lee de donde esta")
chk("en el guardia de efectos delegados",
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
-- Y se guarda ENTERO, no solo guid y nombre: su tarjeta es la misma que la de una entrada normal.
chk("guardando todo lo que pinta su tarjeta",
    turnos:find("armorClass = meta.armorClass or 0, reaction = meta.reaction or 0,", 1, true) ~= nil, true)
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
-- Y NO abre un submenu de anadir: eso vive en la lista, que es donde ademas se ve la vida y la CA
-- de quien esta dentro. Tenerlo en los dos sitios era la misma cosa dos veces, y la de aqui peor.
chk("el click derecho de un bloque abre su lista, sin submenu",
    admin2:find("then\n            API().OpenBlockPanel(entry)", 1, true) ~= nil, true)
-- Y sin ser admin no dice nada: el click derecho se da constantemente, y avisar cada vez llenaba
-- el chat de la misma linea.
chk("y sin admin calla", admin2:find('Print("Solo el admin gestiona los turnos.")', 1, true) == nil, true)

-- ─── LA LISTA DE TARJETAS DEL BLOQUE ────────────────────────────────────────
-- Los miembros no tienen tarjeta en la lista compartida -- ese es el modelo --, pero el DM
-- necesita verlos. El panel es SUYO: vive en HarfordAdmin y no existe para nadie mas.
print("El DM ve las tarjetas de cada bloque")
-- La lista vive en el CORE y la abre CUALQUIERA: mirar quien esta dentro es informacion, no una
-- herramienta de DM. HarfordAdmin no esta instalado en el cliente de un jugador, asi que un panel
-- que viviera alli no existiria para el.
chk("hay panel, y es del core",
    turnos:find("function HarfordTurnOrderAPI.OpenBlockPanel(entry)", 1, true) ~= nil, true)
chk("y el click izquierdo lo abre sin pedir permiso",
    turnos:find("if HarfordTurnOrderAPI.OpenBlockPanel(entry) then return end", 1, true) ~= nil, true)
chk("Admin ya no tiene panel propio",
    admin2:find("HarfordAdminBlockFrame", 1, true) == nil, true)
-- Lo que SI es del DM es editarla, y se cuelga con un decorador. Sin Admin la lista sigue estando,
-- solo que de lectura.
chk("el core deja colgar la edicion",
    turnos:find("function HarfordTurnOrderAPI.RegisterBlockPanelDecorator(fn)", 1, true) ~= nil, true)
chk("y Admin la cuelga", admin2:find("T.RegisterBlockPanelDecorator(", 1, true) ~= nil, true)
chk("los botones de anadir son suyos",
    admin2:find("AnadirObjetivo = function()", 1, true) ~= nil
    and turnos:find("AnadirObjetivo", 1, true) == nil, true)
-- El decorador corre en CADA refresco: si creara los botones cada vez seria una fuga silenciosa.
chk("y no crea un boton por refresco",
    admin2:find("if not p.anadir then", 1, true) ~= nil, true)
-- DOS botones en el bloque de PJs: apuntar a uno y anadirlo, o desplegar el grupo entero. Antes en
-- PJs solo estaba la lista, asi que meter al que tenias delante obligaba a buscarlo en ella.
chk("y boton de grupo", admin2:find("AnadirDelGrupo = function()", 1, true) ~= nil, true)
-- En RAID, `raidN` ya te incluye: anadir ademas "player" te listaba DOS veces. Se filtra por guid
-- --es la misma unidad se llame como se llame-- en vez de por el tipo de grupo.
chk("la lista del grupo no repite a nadie",
    admin2:find("if not guid or vistos[guid] then return end", 1, true) ~= nil, true)
chk("y el de grupo se esconde fuera de PJs",
    admin2:find("p.anadirGrupo:Hide()", 1, true) ~= nil, true)
-- El bloque de PJs es de JUGADORES: un NPC ahi rompe el bando igual de callado que un PJ entre NPCs.
chk("un NPC no entra en el bloque de PJs",
    admin2:find("if esBloqueDePJs and not esJugador then", 1, true) ~= nil, true)
chk("y solo para el admin", admin2:find("if not EsAdmin() then return end", 1, true) ~= nil, true)
-- El click izquierdo del core abre la ficha de la entrada; Admin se lo queda SOLO para los bloques.
chk("el core ofrece el gesto",
    turnos:find("function HarfordTurnOrderAPI.RegisterOnCardLeftClick", 1, true) ~= nil, true)
chk("y solo se lo queda si es un bloque",
    admin2:find('if k ~= "players" and k ~= "generic" then return false end', 1, true) ~= nil, true)
chk("si nadie lo toma, el core hace lo de siempre",
    turnos:find("if AlguienSeQuedaElClick(entry) then return end", 1, true) ~= nil, true)
-- Un MIEMBRO ES UNA ENTRADA: se captura con los mismos datos que una tarjeta normal (icono,
-- displayId, vida, CA, unitName) y se pinta tal cual. Guardar solo guid/nombre obligaba a
-- rellenar el resto de la unidad que tuvieras delante: al cambiar de objetivo se perdia el icono,
-- la CA salia 0 y la vida de un PJ era la NATIVA, no la del sistema Harford.
chk("el miembro se captura como una entrada",
    turnos:find("CapturarUnidadDeTurno(unit, nil)", 1, true) ~= nil, true)
chk("con el mismo capturador que una tarjeta normal",
    turnos:find("AddEntry(CapturarUnidadDeTurno(unit, kind))", 1, true) ~= nil, true)
chk("y guarda su icono", turnos:find("icon = NormalizeIconPath(icon)", 1, true) ~= nil, true)
-- Un jugador conserva su `kind`, que es lo que hace que el pintor le saque la vida del sistema
-- Harford por nombre en vez de la de la unidad.
chk("un jugador sigue siendo player", turnos:find("jugador = (entryKind == ", 1, true) ~= nil, true)
chk("y se le piden sus recursos",
    turnos:find('if entryKind == "player" and HarfordDnDAPI', 1, true) ~= nil, true)
-- Y viaja entero: en el otro cliente la unidad puede no estar ni a la vista, asi que lo que no se
-- mande no se puede recuperar alli.
local codec = io.open("Harford/Frames/HarfordTurnsCodec.lua"):read("*a")
chk("el miembro viaja con su icono y su CA",
    codec:find("Campo(m.icon), tostring(SafeNumber(m.displayId, 0))", 1, true) ~= nil, true)
chk("y los campos nuevos van detras",
    codec:find("local guid, nombre, jugador, kind, unitName, hp, maxHp, icon, displayId",
        1, true) ~= nil, true)
-- Son las tarjetas de siempre, solo que dentro de la lista: NO una imitacion. Las monta y las pinta
-- el core con las mismas dos funciones que la ventana de turnos, porque la primera version las
-- rehizo aqui y las dos se actualizaban de forma distinta.
chk("las monta el core",
    turnos:find("CreateCardVisuals(panel.contenido, function() return f.miembro end)",
        1, true) ~= nil, true)
-- Se le pasa el miembro TAL CUAL, sin sintetizar una entrada a medias.
chk("y las pinta el core", turnos:find("PaintEntryCard(f, m, mando)", 1, true) ~= nil, true)
chk("el core expone el constructor",
    turnos:find("function HarfordTurnOrderAPI.CreateCardVisuals(parent, onArmorClick)", 1, true) ~= nil, true)
chk("y el pintor",
    turnos:find("function HarfordTurnOrderAPI.PaintEntryCard(card, entry, isAdmin)", 1, true) ~= nil, true)
-- Y la ventana de turnos usa las MISMAS: si el core se quedara con una copia propia, seguiriamos
-- teniendo dos.
chk("la ventana de turnos usa el mismo constructor",
    turnos:find("card = CreateCardVisuals(parent, function()", 1, true) ~= nil, true)
chk("y el mismo pintor",
    turnos:find("PaintEntryCard(card, entry, isAdmin)", 1, true) ~= nil, true)
-- Con muchas se baja a verlas, pero el boton no se va con ellas ni lo recorta el scroll: cuelga del
-- panel, no del contenido que se desplaza.
chk("las tarjetas van dentro del scroll",
    turnos:find("CreateCardVisuals(panel.contenido,", 1, true) ~= nil, true)
-- Y son tarjetas ENTERAS: se les puede tocar la CA y la vida, como a las de la ventana de turnos.
-- Los controles se montan en el constructor comun, asi que ninguna de las dos puede quedarse sin.
chk("con sus controles de CA y vida",
    turnos:find("PromptSetArmorClass(Objetivo())", 1, true) ~= nil
    and turnos:find("AdjustHp(Objetivo(), -1)", 1, true) ~= nil, true)
-- Una operacion apunta a la ENTRADA o a su posicion: un miembro de bloque no esta en la lista de
-- turnos, asi que por posicion no habria forma de alcanzarlo.
chk("que apuntan a la entrada, no a una posicion",
    turnos:find("local function EntradaDe(objetivo)", 1, true) ~= nil, true)
-- Sin mando, de LECTURA: se ve quien hay y no se le toca nada.
chk("y sin mando no se tocan",
    turnos:find("f.minus:SetShown(mando)", 1, true) ~= nil, true)
-- Toda pieza que el refresco toca tiene que EXISTIR. Al sacar los controles al constructor comun
-- se llevaron por delante `moveLeft`/`moveRight`, y el refresco petaba en la primera tarjeta y
-- dejaba la fila entera a medio pintar. Compilar no lo caza: son campos, no variables.
print("La tarjeta tiene todas sus piezas")
for _, pieza in ipairs({ "icon", "name", "init", "armorClass", "hp", "hpText", "minus", "plus",
                         "remove", "moveLeft", "moveRight", "active", "reorder", "turn" }) do
    chk("card." .. pieza, turnos:find("card." .. pieza .. " = ", 1, true) ~= nil, true)
end

-- Y toda pieza creada tiene que USARSE. `moveLeft` se creaba y el refresco petaba al tocarla;
-- `targetText` se creaba y NADIE la encendia, asi que el marco de objetivo desaparecio en silencio.
-- Crear y llamar son dos fallos distintos y hacen falta las dos comprobaciones.
chk("el marco de objetivo se enciende",
    turnos:find("SetCardTargetState(card, IsEntryCurrentTarget(entry))", 1, true) ~= nil, true)
-- Y tambien en la lista de un bloque, PJs o NPCs: son las mismas tarjetas y "a quien tengo
-- delante" se pregunta lo mismo en las dos. El `id` de un miembro es su guid.
chk("tambien en la lista de un bloque",
    turnos:find("SetCardTargetState(f, IsEntryCurrentTarget(m))", 1, true) ~= nil, true)
-- Y hay que repintar al cambiar de objetivo, o el marco se queda donde estaba.
chk("y se repinta al cambiar de objetivo",
    turnos:find('self:RegisterEvent("PLAYER_TARGET_CHANGED")', 1, true) ~= nil, true)

-- Los mismos gestos que una tarjeta normal: izquierdo su ficha, derecho el menu.
chk("responden al click como las de siempre",
    turnos:find("HarfordTurnOrderAPI.OnCardRightClick(m, self)", 1, true) ~= nil, true)
chk("y el boton se queda fuera",
    admin2:find('CreateFrame("Button", nil, p, "UIPanelButtonTemplate")', 1, true) ~= nil, true)

-- ─── EL ESTANDARTE DE TURNO ─────────────────────────────────────────────────
-- El aviso que se ve sin estar mirando el chat. Todo el arte es NATIVO (`BossBanner-*`): un atlas
-- propio habria que meterlo en el addon, y uno que no existe no borra la textura anterior -- la
-- deja como estaba, que es la trampa de los iconos del Libro.
-- Un desconectado NO se enumera: no va a jugar su turno, y con una hermandad detras eran veinte
-- lineas muertas para encontrar a los tres que estaban.
chk("un desconectado no se enumera",
    admin2:find("(desconectado)", 1, true) == nil, true)

-- ─── EL MARCADOR PERMANENTE ─────────────────────────────────────────────────
-- El estandarte pasa en cuatro segundos; la pregunta "de quien es el turno" se hace cinco minutos
-- despues. Hasta ahora esa respuesta vivia solo en la ventana de turnos, que nadie tiene abierta
-- todo el rato.
-- ─── LA RECOGIDA DE FIN DE COMBATE ──────────────────────────────────────────
-- UN solo sitio. Antes cada cosa que caducaba al terminar se enganchaba donde buenamente podia --el
-- contador de movimiento acabo escuchando al motor de condiciones para enterarse-- y de lo que se
-- anadia despues no se acordaba nadie. Atlas lo tiene en una funcion (`EndCombatState`) que recoge
-- todo de golpe, y es la forma correcta.
-- ─── EL ESTADO DEL COMBATE ES EXPLICITO ─────────────────────────────────────
-- Antes se DEDUCIA de que hubiera entradas, asi que terminar y vaciar la lista eran lo mismo.
-- ─── UNIRSE A UN COMBATE EN CURSO ───────────────────────────────────────────
-- Se sale FUERA de combate por defecto: nadie entra solo porque haya una pelea en su raid. Para
-- entrar hay un boton, y lo decide el DM -- la lista es suya, y una entrada anadida en local
-- desapareceria con la foto siguiente.
print("Unirse a un combate en curso")
chk("hay peticion", turnos:find('"TJOIN|"', 1, true) ~= nil, true)
chk("y la atiende el DM",
    turnos:find('elseif opcode == "TJOIN" then', 1, true) ~= nil, true)
chk("que mete al que pide en el bloque de PJs",
    turnos:find("HarfordTurnOrderAPI.AddBlockMember(e, unidad)", 1, true) ~= nil, true)
-- No se mete a quien no se ve: un nombre suelto no basta para saber a quien estas anadiendo.
chk("pero solo si lo ve",
    turnos:find("HarfordClassColors.FindUnitByName(sender)", 1, true) ~= nil, true)
-- El boton solo sale si hay combate y NO estas dentro: si ya estas, no hay nada que pedir.
chk("el boton sale solo cuando toca",
    turnos:find("and not HarfordTurnOrderAPI.AmIInCombat())", 1, true) ~= nil, true)

-- ─── LA VENTANA SOBREVIVE A UN /RELOAD ──────────────────────────────────────
-- Solo se abre sola al INICIAR el combate, y eso ya habia pasado: un /reload a media pelea la
-- cerraba y habia que volver a abrirla a mano.
print("La ventana de turnos vuelve tras un /reload")
chk("se apunta si estaba abierta",
    turnos:find("store.ventanaAbierta = true", 1, true) ~= nil, true)
-- Y NO se borra en `OnHide`: al recargar o salir, WoW oculta todos los frames, asi que la marca se
-- borraba justo antes de guardar y al volver la ventana siempre parecia cerrada. Solo cuenta que
-- la cierre el JUGADOR: la X y el comando.
chk("pero no se borra al ocultarse",
    turnos:find('TurnFrame:HookScript("OnHide"', 1, true) == nil, true)
chk("solo al cerrarla a mano",
    turnos:find("close:HookScript(\"OnClick\", Cerrada)", 1, true) ~= nil, true)
chk("o con el comando",
    turnos:find("elseif TurnFrame.MarcarCerrada then TurnFrame.MarcarCerrada() end", 1, true) ~= nil, true)
chk("y se reabre al entrar",
    turnos:find("if HarfordTurnOrderStore.ventanaAbierta and HarfordTurnOrderAPI.HasCombatants() then",
        1, true) ~= nil, true)
-- Pero solo si queda algo que enseniar: reabrirla vacia despues de que la caducidad se llevara el
-- combate seria un frame en blanco.
chk("solo si queda gente montada",
    turnos:find("HarfordTurnOrderStore.ventanaAbierta and HarfordTurnOrderAPI.HasCombatants()",
        1, true) ~= nil, true)
-- La ventana se crea al abrirla por primera vez: al entrar todavia no existe.
chk("creandola si hace falta",
    turnos:find("if not TurnFrame then CreateTurnFrame() end\n            TurnFrame:Show()", 1, true) ~= nil, true)

-- ─── LA MARCA DE ACTIVO SIGUE AL BANDO ──────────────────────────────────────
-- En bandos el turno lo lleva `activeBando`, no `activeIndex`: la marca se quedaba clavada en la
-- tarjeta 1 --el marcador de asalto-- mientras el turno iba por Enemigos. Es la misma entrada la
-- que manda en cada modo, pero no es la misma variable.
print("La marca de ACTIVO sigue al indice")
chk("y no hay otra variable que mirar",
    turnos:find("local esActiva = (entryIndex == store.activeIndex)", 1, true) ~= nil, true)
-- Sin aviso de ESTADOS: cada condicion caduca sola en el turno de su dueno, asi que anunciarlo
-- pedia a la mesa algo que ya estaba hecho.
chk("y no se anuncia ESTADOS",
    turnos:find('local text = "ESTADOS"', 1, true) == nil, true)

print("El estado del combate es explicito")
chk("tres estados", turnos:find("function HarfordTurnOrderAPI.GetCombatState()", 1, true) ~= nil, true)
chk("montar la mesa es preparar",
    turnos:find('HarfordTurnOrderAPI.SetCombatState("preparando")', 1, true) ~= nil, true)
-- Terminar deja la mesa MONTADA: son dos cosas distintas y juntarlas obligaba a rehacerla entre
-- escena y escena. Vaciar es el boton Limpiar, y ese si termina ademas.
local combate2 = io.open("Harford/Frames/HarfordTurnsCombat.lua"):read("*a")
chk("terminar no vacia la lista",
    combate2:find("store.entries = {}", 1, true) == nil, true)
chk("pero limpiar si termina",
    turnos:find("SetCombatState(nil)\n        store.asalto = nil", 1, true) ~= nil, true)
-- Y viaja al final del tercer hueco: un cliente anterior lee modo y DMs como siempre y no llega a
-- mirarlo, en vez de descuadrarse los campos.
chk("el estado viaja detras de los DMs",
    turnos:find('.. modo .. "~" .. dms .. "~" .. estado .. "|"', 1, true) ~= nil, true)
-- Y si el mensaje no lo trae NO se toca el nuestro: poner nil ahi mataria un combate en curso cada
-- vez que hablara alguien sin actualizar.
chk("y un cliente sin estado no mata el combate",
    turnos:find("if estadoRaw ~= nil then", 1, true) ~= nil, true)

print("Al terminar el combate se recoge todo, en un sitio")
local combate = io.open("Harford/Frames/HarfordTurnsCombat.lua"):read("*a")
chk("hay un punto unico", combate:find("local function RecogerTodo()", 1, true) ~= nil, true)
chk("y un modulo nuevo trae su limpieza consigo",
    combate:find("function API.RegisterCombatCleanup(nombre, fn)", 1, true) ~= nil, true)
-- Cada apartado con `pcall`: que falle uno no puede dejar los demas sin recoger, porque entonces
-- el combate siguiente arranca con restos del anterior.
chk("un fallo no arrastra al resto", combate:find("local ok, err = pcall(l.fn)", 1, true) ~= nil, true)
chk("recoge la economia de turno",
    combate:find("HarfordDnDConditions.Turn.Reset", 1, true) ~= nil, true)
chk("el movimiento", combate:find("HarfordDnDAttackUI.StopTurnMovement", 1, true) ~= nil, true)
chk("y el estandarte", combate:find("HarfordTurnOrderAPI.HideTurnBanner", 1, true) ~= nil, true)
-- Y al RECIBIR el fin de combate hay que recoger igual: quien pulsa Terminar limpia su ficha, no
-- la de los demas. Sin esto solo quedaba limpio el que dio al boton.
chk("tambien al recibirlo de otro",
    turnos:find("if habiaCombate and not hay then", 1, true) ~= nil, true)
chk("y el estandarte se retira YA, sin desvanecerse",
    turnos:find("function HarfordTurnOrderAPI.HideTurnBanner()", 1, true) ~= nil, true)
-- El jugador puede salir de un cliente atascado sin mandar TEND ni alterar el combate del DM.
chk("hay salida local de emergencia",
    turnos:find("function HarfordTurnOrderAPI.StopLocalCombat()", 1, true) ~= nil, true)
local fichaComando = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("y el comando no termina el combate remoto",
    fichaComando:find('elseif sub == "combatstop" then', 1, true) ~= nil
    and fichaComando:find("HarfordTurnOrderAPI.StopLocalCombat()", 1, true) ~= nil, true)

print("El marcador de turno")
chk("existe", turnos:find("function HarfordTurnOrderAPI.RefreshTurnMarker()", 1, true) ~= nil, true)
-- Arte nativo, y por faccion como el del juego.
chk("con la cabecera de escenario",
    turnos:find("AllianceScenario-TrackerHeader", 1, true) ~= nil
    and turnos:find("HordeScenario-TrackerHeader", 1, true) ~= nil, true)
-- Si el atlas no estuviera no se pinta: uno que falta deja la textura anterior, no la borra.
chk("comprobando que exista",
    turnos:find("C_Texture.GetAtlasInfo(nombre)", 1, true) ~= nil, true)
-- Se repinta en los TRES sitios donde cambia lo que dice. Iniciar y terminar el combate no son
-- cambios de turno, asi que sin el de `MarkChanged` se quedaba puesto despues de terminar; y
-- recibir el estado de otro cliente no pasa por ahi, asi que necesita el suyo.
chk("se repinta al cambiar el turno",
    turnos:find("RepintarProtegido(HarfordTurnOrderAPI.RefreshTurnMarker)", 1, true) ~= nil, true)
-- La DIFUSION va primero y los repintados protegidos: estaban antes y sin pcall, asi que un
-- fallo pintando mataba ScheduleBroadcast y la mesa dejaba de recibir el estado entero.
chk("y difundir va antes que pintar",
    turnos:find('ScheduleBroadcast()\n    RepintarProtegido(RefreshFrame)', 1, true) ~= nil, true)
chk("y al recibirlo de otro",
    turnos:find("RefrescarMarcadorTrasRecibir()", 1, true) ~= nil, true)
-- Sin fase que contar: un bloque esta jugando o no esta. La fase de cierre se retiro porque
-- obligaba a pulsar `Siguiente` dos veces por bloque.
-- Sin detalle: que el bloque salga ahi ya quiere decir que le toca.
chk("el marcador no anade texto de sobra",
    turnos:find("detalle = \"jugando\"", 1, true) == nil, true)
chk("se puede apagar", turnos:find('HarfordConfig.Get("turnmarker") == "off"', 1, true) ~= nil, true)
-- ── LO QUE TE QUEDA, DENTRO DEL MARCADOR ────────────────────────────────────
-- La barra de movimiento y las fichas vivian sueltas encima de la barra de accion. Es todo lo
-- mismo --lo que te queda este turno-- y en dos sitios obliga a mirar a dos sitios.
chk("lleva la barra de movimiento", turnos:find("marcador.mov.barra", 1, true) ~= nil, true)
-- El marco va en su PROPIO frame, con nivel por encima del de la barra: como textura del boton se
-- quedaba DEBAJO, porque un frame hijo se dibuja siempre sobre las texturas de su padre por mucho
-- OVERLAY que se le ponga.
chk("y el marco por encima de ella",
    turnos:find("marcador.mov.marcoFrame:SetFrameLevel(marcador.mov.barra:GetFrameLevel() + 2)",
        1, true) ~= nil, true)
chk("y las fichas de economia", turnos:find("marcador.fichas[n] = f", 1, true) ~= nil, true)
-- Click en la barra: vuelves a donde empezaste el turno. Ese gesto no existia.
chk("click para volver al inicio del turno",
    turnos:find("HarfordDnDAttackUI.ReturnToTurnStart()", 1, true) ~= nil, true)
local ataqueSrc2 = io.open("Harford/DnD/UI/HarfordDnDAttackUI.lua"):read("*a")
chk("y el gesto esta expuesto",
    ataqueSrc2:find("function API.ReturnToTurnStart()", 1, true) ~= nil, true)
-- Y se repinta al moverse o gastar, no solo al cambiar de turno: si no, la barra se quedaria
-- llena mientras andas y las fichas encendidas al gastarlas.
chk("se repinta al moverse",
    turnos:find("HarfordDnDAttackUI.RegisterMovementListener(Repintar)", 1, true) ~= nil, true)
-- El marco de OBJETIVO es de la TARJETA, no de la ventana: vivia en `CreateCard`, asi que las de
-- la lista no lo tenian y `SetCardTargetState` no hacia nada, en silencio.
chk("el marco de objetivo lo crea el constructor comun",
    turnos:find("card.targetTop = card:CreateTexture", 1, true)
    < turnos:find("local function CreateCard(parent, index)", 1, true), true)

print("El estandarte de turno")
chk("existe", turnos:find("function HarfordTurnOrderAPI.ShowTurnBanner(titulo, subtitulo, esMio)",
    1, true) ~= nil, true)
chk("y usa arte nativo", turnos:find('SetAtlas("BossBanner-BgBanner-Mid"', 1, true) ~= nil, true)
-- Y si el atlas no estuviera, no se pinta NADA: mas vale eso que un rectangulo con la textura de
-- otra cosa.
chk("comprobando que exista",
    turnos:find('C_Texture.GetAtlasInfo("BossBanner-BgBanner-Mid")', 1, true) ~= nil, true)
-- Lo levanta TU turno, no el de un bloque: el estandarte era el aviso de "empieza el bando" y al
-- retirar ese modo se habria quedado sin quien lo levantara. Ahora sale desde `AlertMyTurn`, que
-- es el mismo momento para quien lo mira: le toca.
chk("lo levanta tu turno",
    turnos:find("local conEstandarte = HarfordTurnOrderAPI.ShowTurnBanner", 1, true) ~= nil, true)
-- El aviso de raid es su RESPALDO, no un segundo aviso: salian los dos y quedaban tres "ES TU
-- TURNO" pisandose en la misma esquina. Por eso se mira lo que DEVUELVE el estandarte.
chk("y el aviso de raid solo si no hubo estandarte",
    turnos:find("if not conEstandarte and RaidNotice_AddMessage", 1, true) ~= nil, true)
-- Sin ticker: se retira con un temporizador de una sola vez, cancelable si vuelve a salir.
chk("se retira solo", turnos:find("ocultar = C_Timer.NewTimer(4, function()", 1, true) ~= nil, true)
chk("y se puede apagar", turnos:find('if estilo == "off" then return false end', 1, true) ~= nil, true)
-- DOS formas, no una: la franja discreta y el estandarte colgante del aviso de jefe. Los tres
-- trozos del estandarte existen en este cliente, comprobado con la sonda de atlas.
-- El estandarte O el aviso de raid, NO los dos: salian a la vez y quedaban tres "ES TU TURNO"
-- pisandose en la misma esquina. El de raid es el RESPALDO para cuando el estandarte esta apagado
-- o el arte no existe, por eso se mira lo que DEVUELVE.
chk("el aviso de raid es respaldo, no acompanante",
    turnos:find("if not conEstandarte and RaidNotice_AddMessage", 1, true) ~= nil, true)
chk("hay dos estilos",
    turnos:find('SetAtlas("BossBanner-BgBanner-Top"', 1, true) ~= nil
    and turnos:find('SetAtlas("BossBanner-BgBanner-Bottom"', 1, true) ~= nil, true)
-- ── LAS TARJETAS DE OPCION ──────────────────────────────────────────────────
-- La idea que mejor funciona de DiceMaster: el aviso no solo dice que te toca, ENSENA lo que
-- puedes hacer. La diferencia es que lo suyo es una lista fija escrita a mano y esto sale de la
-- economia real, asi que un Impetu de Accion se ve como dos acciones y no como una.
chk("el estandarte lista lo que te queda",
    turnos:find("local function PintarOpciones(esMio)", 1, true) ~= nil, true)
chk("con arte nativo",
    turnos:find('SetAtlas("LootBanner-ItemBg"', 1, true) ~= nil, true)
-- Lo GASTADO no se pinta: la tarjeta esta para decir lo que QUEDA.
chk("y solo lo que queda", turnos:find("if quedan > 0 then", 1, true) ~= nil, true)
-- Solo en TU turno: en el de otro serian cuatro tarjetas de relleno tapando la pantalla.
chk("solo en tu turno",
    turnos:find("local T = esMio and HarfordDnDConditions", 1, true) ~= nil, true)
-- El movimiento no es una ficha entera sino un resto continuo, pero se lee en la misma fila.
chk("el movimiento va con ellas",
    turnos:find('string.format("Movimiento  %.1f m", quedan)', 1, true) ~= nil, true)
-- El texto de cada tipo vive en la API: dos copias se acaban contradiciendo.
chk("y el texto de cada tipo no se duplica",
    turnos:find("HarfordTurnOrderAPI.TEXTO_ECONOMIA = {", 1, true) ~= nil, true)
chk("y se eligen sin dejarlos puestos",
    turnos:find("function HarfordTurnOrderAPI.PreviewTurnBanner(", 1, true) ~= nil, true)
local config = io.open("Harford/Core/HarfordConfig.lua"):read("*a")
chk("con su ajuste declarado", config:find("turnbanner", 1, true) ~= nil, true)

print("El modo DM entra en caliente")
chk("la ventana se entera de .ph dm",
    turnos:find('HarfordAuthority.RegisterChangeListener("HarfordTurns"', 1, true) ~= nil, true)
chk("y se refresca sola",
    turnos:find("if TurnFrame and TurnFrame:IsShown() and RefreshFrame then RefreshFrame() end",
        1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
