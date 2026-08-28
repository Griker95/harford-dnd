-- Economia de turno: accion, accion adicional y reaccion como presupuesto que se renueva al EMPEZAR
-- tu turno (en 5e la reaccion tambien, no al terminarlo). Informa, no bloquea: `Spend` gasta siempre
-- y devuelve si habia presupuesto.
local cargar = loadstring or load
HarfordTurnOrderStore = { entries = {} }
HarfordTurnOrderAPI = { HasActiveCombat = function()
    for _, e in ipairs(HarfordTurnOrderStore.entries or {}) do
        if e.kind ~= "round" and e.kind ~= "generic" and e.kind ~= "players" then return true end
    end
    return false
end }
HarfordDnDFeatureEffects = { HasFlag = function() return false end }
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local i = assert(src:find("local ECONOMIA"), "no encuentro el bloque")
-- Retroceder a la ultima linea que sea exactamente `do`: es la que abre el bloque.
-- Anclar al texto de alrededor no vale, porque los comentarios cambian.
i = assert(src:sub(1, i):match(".*()\ndo\n"), "no encuentro el do")
local fin = assert(src:find("    API.Turn = Turn\nend", i), "no encuentro el cierre")
local bloque = src:sub(i, fin + #"    API.Turn = Turn\nend")
API = {}
local env = { API = API, math = math, string = string, table = table, ipairs = ipairs,
              tonumber = tonumber, tostring = tostring, type = type,
              Notify = function() end,
              Print = function(m) print("      aviso: " .. m) end,
              HarfordTurnOrderStore = HarfordTurnOrderStore,
              HarfordTurnOrderAPI = HarfordTurnOrderAPI,
              HarfordDnDFeatureEffects = HarfordDnDFeatureEffects }
local f
if setfenv then
    f = assert(cargar(bloque, "economia"))
    setfenv(f, env)
else
    f = assert(cargar(bloque, "economia", "t", env))
end
f()
local T = API.Turn
local fallos = 0
local function chk(nombre, real, esperado)
    local ok = tostring(real) == tostring(esperado)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-12s %s", nombre, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esperado))))
end

print("Sin orden de turnos: no se lleva la cuenta")
chk("IsActive()", T.IsActive(), false)
chk("StatusText() vacio", T.StatusText() == "", true)
chk("Spend no consume fuera de combate", (T.Spend("action")), true)
chk("  y sigue entero", T.GetRemaining("action"), 1)

print("Con orden de turnos activo")
HarfordTurnOrderStore.entries = { { name = "Alguien", kind = "npc" } }
chk("IsActive()", T.IsActive(), true)
chk("gasto la accion -> cabia", (T.Spend("action")), true)
chk("  restante", T.GetRemaining("action"), 0)
chk("gasto otra vez -> NO cabia", (T.Spend("action")), false)
-- Y NO se apunta: antes se sumaba igual y el contador se iba a negativo, asi que el "ya lo habias
-- gastado" era un aviso y nada mas. Devolver false tiene que significar que la accion NO ocurre,
-- y para eso el gasto que no cabe no puede dejar rastro.
chk("  y no deja rastro", T.GetSpent("action"), 1)
chk("la adicional intacta", T.GetRemaining("bonus"), 1)
chk("la reaccion intacta", T.GetRemaining("reaction"), 1)

print("Reinicio al empezar tu turno")
T.Reset()
chk("accion", T.GetRemaining("action"), 1)
chk("reaccion", T.GetRemaining("reaction"), 1)

print("Coste declarado por el rasgo")
chk('cast="reaccion"', T.KindFromFeature({ cast = "reaccion" }), "reaction")
chk('cast="accion_adicional"', T.KindFromFeature({ cast = "accion_adicional" }), "bonus")
chk('cast="accion"', T.KindFromFeature({ cast = "accion" }), "action")
chk('sin cast -> nil, no se adivina', T.KindFromFeature({ type = "accion" }), "nil")
chk('SpendForFeature sin cast no cuenta', T.SpendForFeature({ type = "accion" }), "nil")
chk('  accion intacta', T.GetRemaining("action"), 1)

print("Impetu de Accion")
HarfordDnDFeatureEffects.HasFlag = function(f) return f == "extraTurnAction" end
chk("presupuesto de accion pasa a 2", T.GetBudget("action"), 2)

print("Texto de ficha")
HarfordDnDFeatureEffects.HasFlag = function() return false end
T.Reset(); T.Spend("bonus")
print("  " .. T.StatusText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
-- ─── UN /RELOAD NO TE DEVUELVE LA ACCION ────────────────────────────────────
-- La economia era una tabla de runtime: recargabas y recuperabas accion, adicional y reaccion. Con
-- la economia BLOQUEANDO, eso deja de ser un detalle y pasa a ser la forma de saltarsela.
print("La economia sobrevive a un /reload")
HarfordTurnOrderStore.asalto = 2
T.Reset()
chk("gasto la accion", (T.Spend("action")), true)
chk("  queda 0", T.GetRemaining("action"), 0)
chk("se guardo", type(HarfordTurnOrderStore.economia), "table")
-- Se simula la recarga: se guarda la foto, se vacia la tabla viva --`Reset` guarda la suya, asi
-- que la foto hay que apartarla antes-- y se restaura.
local foto = HarfordTurnOrderStore.economia
T.Reset()
HarfordTurnOrderStore.economia = foto
chk("tras recargar, se retoma", T.RestoreFromStore(), true)
chk("  y la accion sigue gastada", T.GetRemaining("action"), 0)
-- El sello es lo que impide que lo de un combate se aplique a otro.
T.Reset()
HarfordTurnOrderStore.economia = foto
HarfordTurnOrderStore.asalto = 5
chk("otro asalto no vale", T.RestoreFromStore(), false)
chk("  y se empieza limpio", T.GetRemaining("action"), 1)

-- ─── UNA MANIOBRA ES UNA ACCION ─────────────────────────────────────────────
-- Solo 5 de las 15 declaraban su coste, asi que diez no costaban nada -- y su ataque tampoco,
-- porque salta el cobro dando por hecho que ya se pago al anunciarla. Se deduce del tipo en vez de
-- escribirlo en quince tablas: la que se anada manana tambien tiene que costar.
print("Una maniobra cuesta la accion aunque no lo diga")
chk("por su tipo", T.KindFromFeature({ type = "maniobra" }), "action")
chk("o por su efecto",
    T.KindFromFeature({ effects = { { kind = "energyManeuver" } } }), "action")
-- Lo declarado MANDA: una maniobra que diga que es adicional lo sigue siendo.
chk("pero lo declarado manda",
    T.KindFromFeature({ type = "maniobra", cast = "accion_adicional" }), "bonus")
-- Y un rasgo cualquiera sin `cast` sigue sin costar: adivinarlo por `type = "accion"` daria un
-- contador equivocado, que es peor que no tenerlo.
chk("y un rasgo normal sin cast sigue sin costar",
    T.KindFromFeature({ type = "accion" }), nil)
-- Se cobra al EJECUTARLA, despues de comprobar recurso y usos: cobrar antes obligaria a devolver
-- la accion en cada uno de esos cortes.
local ficha2 = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("y se cobra al ejecutarla",
    ficha2:find("HarfordDnDConditions.Turn.SpendForFeature(feature) == false then", 1, true) ~= nil, true)

-- ─── EL DM PUEDE DEVOLVER LO GASTADO ────────────────────────────────────────
-- Algo no llego a pasar --se cancelo, el objetivo ya no estaba-- y cobrarlo seria quitarle el
-- turno a alguien por un error de mesa. No es lo mismo que conceder una accion EXTRA: aquello sube
-- el presupuesto, esto deshace un gasto.
print("Se puede devolver lo gastado")
HarfordTurnOrderStore.entries = { { name = "Alguien", kind = "npc" } }
T.Reset()
chk("nada gastado -> no hay nada que devolver", T.Refund("action"), false)
T.Spend("action")
chk("  tras gastarla, queda 0", T.GetRemaining("action"), 0)
chk("se devuelve", T.Refund("action"), true)
chk("  y vuelve a estar", T.GetRemaining("action"), 1)
-- Devolver no REGALA: dos devoluciones seguidas no dan dos acciones.
chk("y no se puede devolver dos veces", T.Refund("action"), false)
chk("  sigue habiendo una", T.GetRemaining("action"), 1)
-- Un tipo que no existe no toca nada: lo que llega por el cable no elige a que se llama.
chk("un tipo inventado no hace nada", T.Refund("loquesea"), false)
-- Y el mensaje lleva lista cerrada por lo mismo.
local sync = io.open("Harford/Core/HarfordSync.lua"):read("*a")
chk("el mensaje tiene lista cerrada",
    sync:find("local TGIVE_TIPOS = { action = true, bonus = true, reaction = true, movement = true }",
        1, true) ~= nil, true)
-- Lo aplica el RECEPTOR: es quien lleva su economia, y escribirsela desde fuera daria dos verdades
-- distintas sobre lo mismo.
local comm = io.open("Harford/DnD/Engine/HarfordDnDComm.lua"):read("*a")
chk("y lo aplica el receptor",
    comm:find("HarfordDnDConditions.Turn.Refund(refundKind)", 1, true) ~= nil, true)
-- Con el mismo filtro de remitente que el resto de mensajes con efecto: cambia lo que TU puedes
-- hacer este turno.
chk("con el filtro de siempre",
    comm:find("if not IsTrustedEffectSender(sender) then return false end", 1, true) ~= nil, true)

-- ─── FUERA DE TU TURNO NO TIENES ACCION NI ADICIONAL ────────────────────────
-- Son tuyas mientras te TOCA. La reaccion no: para eso es una reaccion, se usa en el turno de otro
-- por definicion. No se "gastan" al pasar el turno --se consideran no disponibles-- porque gastarlas
-- de verdad haria imposible distinguirlas de un gasto real a la hora de devolverlas.
print("Fuera de tu turno no hay accion ni adicional")
HarfordTurnOrderStore.entries = { { name = "Alguien", kind = "npc" } }
T.Reset()
local miTurno = true
HarfordTurnOrderAPI.IsMyTurn = function() return miTurno end
chk("en tu turno, la accion esta", T.GetRemaining("action"), 1)
chk("y la adicional tambien", T.GetRemaining("bonus"), 1)
miTurno = false
chk("en turno ajeno, sin accion", T.GetRemaining("action"), 0)
chk("ni adicional", T.GetRemaining("bonus"), 0)
-- Y la REACCION tampoco. Es una divergencia DELIBERADA del manual, decidida en mesa: en 5e una
-- reaccion se usa por definicion en el turno de otro --Oportunidad, Escudo, Contrahechizo, Esquiva
-- Sobrenatural--, asi que bloquearla aqui las deja inservibles. Se quiere igual, porque lo que se
-- busca es que cuando le toca a los enemigos los jugadores esten QUIETOS.
-- Para volver al manual basta sacar `reaction` de `FUERA_DE_TURNO`; esta prueba es lo unico mas
-- que habria que cambiar.
chk("y la reaccion TAMPOCO (divergencia de mesa)", T.GetRemaining("reaction"), 0)
-- Y no se ha gastado nada: al volver tu turno esta entera.
chk("no se apunto como gastada", T.GetSpent("action"), 0)
miTurno = true
chk("y vuelve entera", T.GetRemaining("action"), 1)
chk("  y la reaccion tambien", T.GetRemaining("reaction"), 1)

-- La UNICA rendija del turno ajeno: PREPARAR. Pagaste la accion por adelantado y comprometiste la
-- reaccion, asi que con el estado `preparado` puesto la reaccion vuelve a estar disponible en el
-- turno de otro -- solo ella, y solo mientras dure el estado. Sin esta rendija, el bloqueo total
-- dejaba Preparar muerto: su segundo clic cobra reaccion y siempre daba cero.
print("Preparar es la unica rendija del turno ajeno")
miTurno = false
local preparado = false
API.Has = function(unit, id) return unit == "player" and id == "preparado" and preparado end
chk("sin preparar, la reaccion sigue a cero", T.GetRemaining("reaction"), 0)
preparado = true
chk("PREPARADO: la reaccion vuelve", T.GetRemaining("reaction"), 1)
chk("  pero la accion no (solo la reaccion)", T.GetRemaining("action"), 0)
chk("  ni la adicional", T.GetRemaining("bonus"), 0)
-- Y si ya la habias gastado este turno, preparar no te da otra.
T.Spend("reaction")
chk("  y gastada, gastada esta", T.GetRemaining("reaction"), 0)
T.Reset()
preparado = false
miTurno = true
API.Has = nil
HarfordTurnOrderAPI.IsMyTurn = nil

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
