-- AYUDAR, PREPARAR y LANZAR ARMA: las tres acciones basicas que quedaban narrativas.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local src = io.open("Harford/DnD/Data/HarfordDnDActions.lua"):read("*a")
local env = { HarfordDnDActions = {}, tostring = tostring, tonumber = tonumber,
    ipairs = ipairs, pairs = pairs, table = table }
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
f()
local A = env.HarfordDnDActions

local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local panel = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))
local cat = io.open("Harford/Compendium/HarfordIconCatalog.lua"):read("*a")

print("Ninguna de las tres sigue declarandose sin efecto")
for _, id in ipairs({ "ayudar", "preparar", "lanzar_arma" }) do
    chk(id, A.Get(id).sinEfecto, "nil")
end

-- AYUDAR. Decision de mesa 2026-09: UN solo estado sin declarar el uso. La ventaja va a la
-- SIGUIENTE tirada de ataque o de prueba del ayudado, la que llegue antes, y ahi se gasta.
-- Una unica opcion => `Elegir` ejecuta directo y no hay menu.
print("Ayudar: un solo estado, sin declarar el uso")
chk("una opcion", #A.Get("ayudar").helpOther.options, 1)
chk("el estado unico", A.Get("ayudar").helpOther.options[1].conditionId, "ayudado")
chk("da ventaja en ataque Y prueba",
    cond:find('ayudado = {.-rolls = { attack = true, ability = true }, mode = "adv"') ~= nil, true)
chk("y se gasta con la primera de las dos",
    cond:find('ayudado = {.-consumeAfterRoll = { attack = true, ability = true }') ~= nil, true)
-- Los estados antiguos siguen DEFINIDOS (compat con DNDCOND de clientes viejos) pero fuera de
-- las categorias del menu DM.
chk("compat prueba definida", cond:find("ayudado_prueba = {") ~= nil, true)
chk("compat ataque definida", cond:find("ayudado_ataque = {") ~= nil, true)
chk("fuera del menu DM", cond:find('"ayudado_ataque", "ayudado_prueba", "preparado"') == nil, true)
chk("el unificado en el menu DM", cond:find('"ayudado", "preparado"', 1, true) ~= nil, true)

-- El estado va sobre el ALIADO. `ApplyToUnit` ya sabe pedirselo a su cliente si es jugador.
print("Ayudar: el estado va sobre el aliado, no sobre quien ayuda")
chk("por la ruta que llega a otro cliente",
    panel:find('HarfordDnDConditions.ApplyToUnit("target", elegida.conditionId', 1, true) ~= nil, true)
chk("sin objetivo no hace nada", panel:find('HarfordChat.Print("Ayudar necesita un objetivo.")', 1, true) ~= nil, true)

-- PREPARAR no concede NADA: adelanta la accion y compromete la reaccion. Que su estado no tenga
-- efectos es la afirmacion, no un olvido.
print("Preparar: no concede nada, y su estado lo dice")
chk("estado sin efectos", cond:find("preparado = {.-effects = {},") ~= nil, true)
chk("dura hasta tu proximo turno", A.Get("preparar").readyAction.duration, "source_turn_start")
chk("el segundo clic lo dispara", panel:find('if C.Has and C.Has("player", spec.conditionId) then', 1, true) ~= nil, true)
-- El anuncio es lo que la economia de turno mira para cobrar, y ocurre ANTES de la rama: si no se
-- decide ahi, disparar cobraba otra ACCION ademas de la reaccion. La accion ya se pago al preparar.
chk("y cuesta SOLO la reaccion",
    panel:find('cast = disparando and "reaccion" or coste.cast,', 1, true) ~= nil, true)
chk("se decide antes de anunciar",
    panel:find("local disparando = type(def.readyAction)", 1, true)
    < panel:find("if AnnounceAbility(anuncio", 1, true), true)
chk("y no se anuncia dos veces",
    select(2, panel:gsub("Se dispara la accion preparada", "")), 1)

-- LANZAR ARMA. Se elige mano porque con cual se lanza cambia el dado y los bonos.
print("Lanzar arma: se elige mano, y solo entre las que llevan arma")
chk("las dos manos", #A.Get("lanzar_arma").throwWeapon.slots, 2)
chk("solo las que devuelven arma", panel:find("local arma = items.GetEquippedWeapon(slot)\n                if arma then", 1, true) ~= nil, true)
chk("sin arma avisa", panel:find('HarfordChat.Print("No llevas ningun arma que lanzar.")', 1, true) ~= nil, true)
-- Un arma lanzada suma tu modificador, como cualquier ataque con arma, y mide su alcance de
-- LANZAMIENTO (attackMode thrown), no el contacto de melee.
chk("suma el modificador y mide como lanzada",
    panel:find('AttackWithBlock(proyectil, { suppressAbilityDamage = false, attackMode = "thrown" })', 1, true) ~= nil, true)
chk("sin reimplementar el ataque", panel:find("HarfordDnDStore.AttackWithBlock(proyectil", 1, true) ~= nil, true)
-- SIN la propiedad Arrojadiza es un ataque IMPROVISADO (1d4, 20/60, sin competencia): se lanza
-- una COPIA marcada, nunca el def compartido del catalogo.
chk("improvisada = copia con 1d4",
    panel:find("proyectil.dmgN, proyectil.dmgS = 1, 4", 1, true) ~= nil
    and panel:find("proyectil.improvised = true", 1, true) ~= nil, true)
local armas = io.open("Harford/DnD/Data/HarfordDnDWeapons.lua"):read("*a")
chk("alcance improvisado 20/60 en el gate",
    armas:find('kind = "thrown", improvised = true', 1, true) ~= nil, true)
local dnd = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("la improvisada pierde la competencia",
    dnd:find("and not (def and def.improvised)", 1, true) ~= nil, true)

-- Empujar, Ayudar y Lanzar arma preguntan lo mismo: un menu, no tres.
print("Un solo selector para las tres, no tres copias")
chk("selector generico", panel:find("local function Elegir(opciones, def, ejecutor, yaElegida)", 1, true) ~= nil, true)
chk("una sola opcion no se pregunta",
    panel:find("if #opciones == 1 then ejecutor(def, opciones[1]); return true end", 1, true) ~= nil, true)
chk("lo usa la contienda antes de ejecutarla",
    panel:find("if Elegir(def.contest.options, def, ConEleccion, nil) then return true end", 1, true) ~= nil, true)
chk("lo usa ayudar", panel:find("if Elegir(def.helpOther.options, def, Ayudar, elegida) then return true end", 1, true) ~= nil, true)
chk("lo usa lanzar arma", panel:find("if Elegir(opciones, def, LanzarArma, nil) then return true end", 1, true) ~= nil, true)

print("Los estados tienen icono")
for _, id in ipairs({ "ayudado", "ayudado_prueba", "ayudado_ataque", "preparado" }) do
    chk(id, cat:find("\n    harford_estado_" .. id .. " = ", 1, true) ~= nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
