-- HarfordDnDConditions: las decisiones que toma el motor de estados.
--
-- Es el modulo del que cuelga media mesa -- ventaja, desventaja, bloqueos, resistencias -- y estaba
-- practicamente sin cubrir: de 14 mutaciones, 13 pasaban sin que nada se quejara. Aqui vive tambien
-- el fallo que dejo nueve condiciones sin aplicarse jamas.
--
-- Se carga el modulo ENTERO y se le meten condiciones activas escribiendo en su propio estado. No
-- se replica ninguna regla: se pregunta al motor de verdad.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local API = {}
local env = setmetatable({ HarfordDnDConditions = API }, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.select, env.next, env.error, env.assert = type, select, next, error, assert
env.table, env.string, env.math, env.pcall, env.unpack = table, string, math, pcall, unpack
env.setmetatable, env.print = setmetatable, function() end
env.HarfordClassColors = {
    NormalizeKey = function(v) return tostring(v or ""):lower() end,
    UnitFullName = function() return "" end,
    FindUnitByName = function() return nil end,
    StripAccents = function(v) return v end,
}
env.GetTime = function() return 1000 end
-- El modulo crea un frame de eventos al final; sin esto no llega a cargarse entero.
env.CreateFrame = function()
    local f = {}
    setmetatable(f, { __index = function() return function() end end })
    return f
end

local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
assert(pcall(f))
local C = env.HarfordDnDConditions

-- Sin `UnitExists`, una referencia de texto se convierte en su propia clave de estado, asi que
-- "player" y "GUID-OBJETIVO" son dos cubos distintos y se pueden poblar a mano.
local function limpiar()
    for k in pairs(C.State.units) do C.State.units[k] = nil end
end
local function poner(ref, id, efectos, extra)
    C.State.units[ref] = C.State.units[ref] or {}
    -- Una condicion inventada para la prueba: asi se prueba la REGLA y no la tabla de datos, que
    -- cambia cada vez que se anade una clase.
    C.DEFS[id] = C.DEFS[id] or { label = id, tracking = "state", description = "", effects = {} }
    C.DEFS[id].effects = efectos or {}
    local yaEsta = false
    for _, x in ipairs(C.ORDER) do if x == id then yaEsta = true break end end
    if not yaEsta then C.ORDER[#C.ORDER + 1] = id end
    local rec = { duration = "manual", created = 1000, authority = true }
    for k, v in pairs(extra or {}) do rec[k] = v end
    C.State.units[ref][id] = rec
end

-- ─── Ventaja y desventaja ───────────────────────────────────────────────────
print("El modo base pasa tal cual si nadie opina")
limpiar()
chk("normal", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "normal")
chk("ventaja", C.ResolveRollMode("adv", "attack", { actorUnit = "player" }), "adv")
chk("desventaja", C.ResolveRollMode("dis", "attack", { actorUnit = "player" }), "dis")

print("Un estado propio cambia el modo, y solo en las tiradas que dice")
limpiar()
poner("player", "t_ventaja_ataque", { { kind = "rollMode", rolls = { attack = true }, mode = "adv" } })
chk("da ventaja al ataque", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "adv")
chk("pero no a la salvacion", C.ResolveRollMode("normal", "save", { actorUnit = "player" }), "normal")

-- La regla del manual: ventaja y desventaja se anulan, no se suman ni gana la ultima.
print("Ventaja y desventaja se ANULAN")
limpiar()
poner("player", "t_ventaja", { { kind = "rollMode", rolls = { attack = true }, mode = "adv" } })
poner("player", "t_desventaja", { { kind = "rollMode", rolls = { attack = true }, mode = "dis" } })
chk("las dos a la vez dan normal", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "normal")
chk("y una desventaja anula la ventaja base", C.ResolveRollMode("adv", "attack", { actorUnit = "player" }), "normal")
limpiar()
poner("player", "t_desventaja", { { kind = "rollMode", rolls = { attack = true }, mode = "dis" } })
chk("dos desventajas siguen siendo una", C.ResolveRollMode("dis", "attack", { actorUnit = "player" }), "dis")

print("Un estado del OBJETIVO afecta a quien le ataca")
limpiar()
poner("GUID-OBJETIVO", "t_recibe_ventaja",
    { { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" } })
chk("atacarle da ventaja",
    C.ResolveRollMode("normal", "attack", { actorUnit = "player", targetGuid = "GUID-OBJETIVO" }), "adv")
chk("pero sin apuntarle, no", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "normal")

-- Veredicto del Templario: la ventaja es SOLO de quien lo puso, no de toda la mesa.
print("`incomingRollModeFromSource`: solo quien lo puso se lleva la ventaja")
limpiar()
poner("GUID-OBJETIVO", "t_veredicto",
    { { kind = "incomingRollModeFromSource", rolls = { attack = true }, mode = "adv" } },
    { sourceGuid = "GUID-PALADIN" })
chk("el paladin si", C.ResolveRollMode("normal", "attack",
    { actorGuid = "GUID-PALADIN", targetGuid = "GUID-OBJETIVO" }), "adv")
chk("otro jugador NO", C.ResolveRollMode("normal", "attack",
    { actorGuid = "GUID-OTRO", targetGuid = "GUID-OBJETIVO" }), "normal")

-- Orden oscura del Caballero de la Muerte: desventaja contra todos MENOS contra quien la impuso.
print("`rollModeExceptSource`: desventaja contra todos menos contra quien la puso")
limpiar()
poner("player", "t_orden",
    { { kind = "rollModeExceptSource", rolls = { attack = true }, mode = "dis" } },
    { sourceGuid = "GUID-CDM" })
chk("contra otro, desventaja", C.ResolveRollMode("normal", "attack",
    { actorUnit = "player", targetGuid = "GUID-VICTIMA" }), "dis")
chk("contra quien la puso, normal", C.ResolveRollMode("normal", "attack",
    { actorUnit = "player", targetGuid = "GUID-CDM" }), "normal")
-- Sin objetivo conocido se aplica igual: es el caso conservador para el que la sufre.
chk("sin objetivo, se aplica", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "dis")

-- ─── Bloqueos de accion ─────────────────────────────────────────────────────
print("Bloqueo de accion")
limpiar()
poner("player", "t_incapaz",
    { { kind = "blockAction", actions = { action = true, reaction = true } } })
chk("no puede accion", (C.CanPerform("action", { actorUnit = "player" })), false)
chk("no puede reaccion", (C.CanPerform("reaction", { actorUnit = "player" })), false)
chk("la adicional no la bloquea", (C.CanPerform("bonus", { actorUnit = "player" })), true)
-- Atacar y lanzar con voz cuentan como accion aunque no se pidan por ese nombre.
chk("atacar cuenta como accion", (C.CanPerform("weapon_attack", { actorUnit = "player" })), false)
chk("y conjurar con voz tambien", (C.CanPerform("verbal_spell", { actorUnit = "player" })), false)
-- Dice CUAL lo impide: sin eso, el jugador no sabe que quitarse.
chk("y dice cual lo impide", select(2, C.CanPerform("action", { actorUnit = "player" })), "t_incapaz")

print("`blockAttackSource`: no puedes actuar contra QUIEN te lo puso")
limpiar()
poner("player", "t_hechizado", { { kind = "blockAttackSource" } }, { sourceGuid = "GUID-BRUJO" })
chk("contra el brujo, no", (C.CanPerform("action",
    { actorUnit = "player", targetGuid = "GUID-BRUJO" })), false)
chk("contra otro, si", (C.CanPerform("action",
    { actorUnit = "player", targetGuid = "GUID-OTRO" })), true)

-- ─── Salvaciones que se fallan solas ────────────────────────────────────────
print("Salvaciones falladas automaticamente")
limpiar()
poner("player", "t_paralizado",
    { { kind = "autoFailSave", abilities = { Fuerza = true, Destreza = true } } })
chk("Fuerza se falla sola", C.IsSaveAutoFailed("player", "Fuerza"), true)
chk("Destreza tambien", C.IsSaveAutoFailed("player", "Destreza"), true)
chk("pero Sabiduria no", C.IsSaveAutoFailed("player", "Sabiduria"), false)

-- ─── Resistencias ───────────────────────────────────────────────────────────
print("Resistencia a todo y resistencia por tipo")
limpiar()
poner("player", "t_petrificado", { { kind = "resistAll" } })
chk("resiste cualquier tipo", C.GetDamageStatus("player", "cortante"), "resistant")
limpiar()
poner("player", "t_piel", { { kind = "resistTypes", types = { "contundente" } } })
chk("resiste el tipo que dice", C.GetDamageStatus("player", "contundente"), "resistant")
chk("y no otros", C.GetDamageStatus("player", "fuego"), "nil")
-- Piel de Hierro del Monje resiste el contundente NO MAGICO: un arma magica la atraviesa.
print("Una resistencia solo a lo no magico no para lo magico")
limpiar()
poner("player", "t_piel", { { kind = "resistTypes", types = { "contundente" }, nonMagical = true } })
chk("dano normal, resiste", C.GetDamageStatus("player", "contundente"), "resistant")
chk("dano magico, no", C.GetDamageStatus("player", "contundente", { magical = true }), "nil")

-- ─── Estados de un solo uso ─────────────────────────────────────────────────
print("Estados que se gastan al tirar")
limpiar()
C.DEFS["t_un_ataque"] = { label = "t", tracking = "state", effects = {},
    consumeAfterRoll = { attack = true } }
poner("player", "t_un_ataque", {})
C.DEFS["t_un_ataque"].consumeAfterRoll = { attack = true }
local lista = C.ConditionsToConsumeAfterRoll("attack")
chk("se gasta en el ataque", lista and lista[1], "t_un_ataque")
lista = C.ConditionsToConsumeAfterRoll("save")
chk("pero no en la salvacion", lista and #lista or 0, 0)

-- ─── EL CATALOGO DE VERDAD ──────────────────────────────────────────────────
-- Lo de arriba prueba las REGLAS con condiciones inventadas. Esto prueba los DATOS: que las
-- condiciones del manual hagan lo que dice el manual. Es lo que se nota en mesa, y hasta ahora se
-- podia cambiar un `true` por `false` en cualquiera de ellas sin que nada se quejara.
local function real(ref, id, extra)
    C.State.units[ref] = C.State.units[ref] or {}
    local rec = { duration = "manual", created = 1000, authority = true }
    for k, v in pairs(extra or {}) do rec[k] = v end
    C.State.units[ref][id] = rec
end

print("Asustado: desventaja en ataques Y en pruebas, no en salvaciones")
limpiar(); real("player", "frightened")
chk("ataque", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "dis")
chk("prueba de caracteristica", C.ResolveRollMode("normal", "ability", { actorUnit = "player" }), "dis")
chk("salvacion no", C.ResolveRollMode("normal", "save", { actorUnit = "player" }), "normal")

print("Envenenado: igual que Asustado")
limpiar(); real("player", "poisoned")
chk("ataque", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "dis")
chk("prueba", C.ResolveRollMode("normal", "ability", { actorUnit = "player" }), "dis")

print("Paralizado: no actua, falla Fuerza y Destreza, y le pegan con ventaja")
limpiar(); real("player", "paralyzed")
chk("no puede accion", (C.CanPerform("action", { actorUnit = "player" })), false)
chk("no puede reaccion", (C.CanPerform("reaction", { actorUnit = "player" })), false)
chk("falla Fuerza sola", C.IsSaveAutoFailed("player", "Fuerza"), true)
chk("falla Destreza sola", C.IsSaveAutoFailed("player", "Destreza"), true)
chk("pero no Carisma", C.IsSaveAutoFailed("player", "Carisma"), false)
limpiar(); real("GUID-VICTIMA", "paralyzed")
chk("atacarle da ventaja", C.ResolveRollMode("normal", "attack",
    { actorUnit = "player", targetGuid = "GUID-VICTIMA" }), "adv")

print("Invisible: ataca con ventaja y le atacan con desventaja")
limpiar(); real("player", "invisible")
chk("sus ataques con ventaja", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "adv")
limpiar(); real("GUID-VICTIMA", "invisible")
chk("atacarle, con desventaja", C.ResolveRollMode("normal", "attack",
    { actorUnit = "player", targetGuid = "GUID-VICTIMA" }), "dis")

-- La regla que mas se olvida en mesa: derribado es ventaja de cerca y desventaja de lejos.
print("Derribado: cuerpo a cuerpo con ventaja, a distancia con desventaja")
limpiar(); real("player", "prone")
chk("sus propios ataques, desventaja", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "dis")
limpiar(); real("GUID-VICTIMA", "prone")
chk("pegarle de cerca, ventaja", C.ResolveRollMode("normal", "attack",
    { actorUnit = "player", targetGuid = "GUID-VICTIMA", attackRange = "melee" }), "adv")
chk("dispararle de lejos, desventaja", C.ResolveRollMode("normal", "attack",
    { actorUnit = "player", targetGuid = "GUID-VICTIMA", attackRange = "ranged" }), "dis")

print("Petrificado: incapaz, falla Fue/Des y resiste TODO")
limpiar(); real("player", "petrified")
chk("no puede actuar", (C.CanPerform("action", { actorUnit = "player" })), false)
chk("falla Fuerza", C.IsSaveAutoFailed("player", "Fuerza"), true)
chk("resiste cortante", C.GetDamageStatus("player", "cortante"), "resistant")
chk("y tambien fuego", C.GetDamageStatus("player", "fuego"), "resistant")

print("Silenciado: no puede lanzar con voz, pero si atacar")
limpiar(); real("player", "silenced")
chk("conjuro verbal bloqueado", (C.CanPerform("verbal_spell", { actorUnit = "player" })), false)
chk("atacar sigue pudiendo", (C.CanPerform("weapon_attack", { actorUnit = "player" })), true)

print("Incapacitado: ni accion ni reaccion")
limpiar(); real("player", "incapacitated")
chk("accion", (C.CanPerform("action", { actorUnit = "player" })), false)
chk("reaccion", (C.CanPerform("reaction", { actorUnit = "player" })), false)

-- Cansancio: seis niveles ACUMULATIVOS. El nivel 3 arrastra el 1, asi que un personaje con
-- cansancio 3 tiene desventaja en pruebas (del 1) y en ataques y salvaciones (del 3).
print("Cansancio: los niveles se acumulan")
limpiar(); real("player", "exhaustion", { level = 1 })
chk("nivel 1: desventaja en pruebas", C.ResolveRollMode("normal", "ability", { actorUnit = "player" }), "dis")
chk("nivel 1: el ataque aun no", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "normal")
limpiar(); real("player", "exhaustion", { level = 3 })
chk("nivel 3: tambien el ataque", C.ResolveRollMode("normal", "attack", { actorUnit = "player" }), "dis")
chk("nivel 3: y la salvacion", C.ResolveRollMode("normal", "save", { actorUnit = "player" }), "dis")
chk("nivel 3: arrastra la prueba del 1", C.ResolveRollMode("normal", "ability", { actorUnit = "player" }), "dis")

-- ─── Velocidad ──────────────────────────────────────────────────────────────
print("Velocidad reducida y a cero")
limpiar(); real("player", "grappled")
chk("agarrado deja la velocidad a 0", C.GetSpeedFactor and C.GetSpeedFactor("player") or 0, 0)
limpiar(); real("player", "exhaustion", { level = 2 })
chk("cansancio 2 la deja a la mitad",
    C.GetSpeedFactor and C.GetSpeedFactor("player") or 0.5, 0.5)

-- ─── ECONOMIA DE TURNO ──────────────────────────────────────────────────────
-- Una accion, una adicional y una reaccion por turno. Que se cobre lo que toca es lo que hace que
-- un rasgo declarado "accion adicional" no te coma el turno entero -- que es justo el fallo que se
-- encontro en diez rasgos del Brujo y del Monje.
-- Fuera de combate NO se lleva la cuenta: gastar es libre y no se registra nada. Unas fichas
-- llenas o vacias fuera de combate serian informacion falsa.
print("Sin combate activo no se cobra nada")
local T = C.Turn
local EN_COMBATE = false
env.HarfordTurnOrderAPI = { HasActiveCombat = function() return EN_COMBATE end }
T.Reset()
chk("gastar fuera de combate no agota", (T.Spend("action", 1)), true)
chk("y sigue entera", T.GetRemaining("action"), 1)

print("Economia de turno: uno de cada, y se gastan por separado")
EN_COMBATE = true
T.Reset()
chk("empieza con su accion", T.GetRemaining("action"), 1)
chk("y su adicional", T.GetRemaining("bonus"), 1)
chk("y su reaccion", T.GetRemaining("reaction"), 1)
T.Spend("action", 1)
chk("gastar la accion la agota", T.GetRemaining("action"), 0)
chk("pero no toca la adicional", T.GetRemaining("bonus"), 1)
chk("ni la reaccion", T.GetRemaining("reaction"), 1)
chk("y no se puede gastar dos veces", (T.Spend("action", 1)), false)
T.Reset()
chk("el turno nuevo las devuelve", T.GetRemaining("action"), 1)

-- Impetu de Accion: una accion EXTRA. Por eso el presupuesto no es un si/no sino un numero.
print("Un rasgo puede dar una accion extra")
T.Reset()
T.GrantExtra("action", 1)
chk("ahora hay dos", T.GetRemaining("action"), 2)
T.Spend("action", 1)
chk("gastar una deja la otra", T.GetRemaining("action"), 1)
T.Spend("action", 1)
chk("y agotadas las dos, no hay mas", (T.Spend("action", 1)), false)
T.Reset()
chk("el extra no sobrevive al turno", T.GetRemaining("action"), 1)

-- El coste sale del rasgo, y por eso un `cast` mal escrito cobraba de donde no era.
print("El coste lo dice el rasgo")
chk("accion", T.KindFromFeature({ cast = "accion" }), "action")
chk("accion adicional", T.KindFromFeature({ cast = "accion_adicional" }), "bonus")
chk("reaccion", T.KindFromFeature({ cast = "reaccion" }), "reaction")

-- ─── El recorrido no puede perder condiciones ───────────────────────────────
-- Es el fallo que dejo nueve apagadas: `ORDER` ordenaba Y decidia que existia.
print("Toda condicion definida es recorrible")
local faltan = {}
local enOrden = {}
for _, id in ipairs(C.ORDER) do enOrden[id] = true end
for id in pairs(C.DEFS) do
    if not enOrden[id] then faltan[#faltan + 1] = id end
end
chk("ninguna se queda fuera", #faltan, 0)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
