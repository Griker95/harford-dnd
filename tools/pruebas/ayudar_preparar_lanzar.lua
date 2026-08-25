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
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
local cat = io.open("Harford/Compendium/HarfordIconCatalog.lua"):read("*a")

print("Ninguna de las tres sigue declarandose sin efecto")
for _, id in ipairs({ "ayudar", "preparar", "lanzar_arma" }) do
    chk(id, A.Get(id).sinEfecto, "nil")
end

-- AYUDAR. Dos usos distintos del manual, no uno con dos efectos: la ventaja se gasta en la primera
-- tirada del tipo que sea, asi que un estado unico la gastaria en la que no era.
print("Ayudar: dos usos, y se declara cual antes")
chk("dos opciones", #A.Get("ayudar").helpOther.options, 2)
chk("prueba", A.Get("ayudar").helpOther.options[1].conditionId, "ayudado_prueba")
chk("ataque", A.Get("ayudar").helpOther.options[2].conditionId, "ayudado_ataque")
chk("el estado de prueba da ventaja en pruebas",
    cond:find('ayudado_prueba = {.-rolls = { ability = true }, mode = "adv"') ~= nil, true)
chk("y se gasta al tirarla", cond:find('ayudado_prueba = {.-consumeAfterRoll = { ability = true }') ~= nil, true)
chk("el de ataque da ventaja en ataques",
    cond:find('ayudado_ataque = {.-rolls = { attack = true }, mode = "adv"') ~= nil, true)
chk("y se gasta al atacar", cond:find('ayudado_ataque = {.-consumeAfterRoll = { attack = true }') ~= nil, true)

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
chk("y cuesta la reaccion", panel:find('cast = "reaccion",', 1, true) ~= nil, true)

-- LANZAR ARMA. Se elige mano porque con cual se lanza cambia el dado y los bonos.
print("Lanzar arma: se elige mano, y solo entre las que llevan arma")
chk("las dos manos", #A.Get("lanzar_arma").throwWeapon.slots, 2)
chk("solo las que devuelven arma", panel:find("local arma = items.GetEquippedWeapon(slot)\n                if arma then", 1, true) ~= nil, true)
chk("sin arma avisa", panel:find('HarfordChat.Print("No llevas ningun arma que lanzar.")', 1, true) ~= nil, true)
-- Un arma lanzada suma tu modificador, como cualquier ataque con arma.
chk("suma el modificador", panel:find("AttackWithBlock(arma, { suppressAbilityDamage = false })", 1, true) ~= nil, true)
chk("sin reimplementar el ataque", panel:find("HarfordDnDStore.AttackWithBlock(arma", 1, true) ~= nil, true)

-- Empujar, Ayudar y Lanzar arma preguntan lo mismo: un menu, no tres.
print("Un solo selector para las tres, no tres copias")
chk("selector generico", panel:find("local function Elegir(opciones, def, ejecutor, yaElegida)", 1, true) ~= nil, true)
chk("una sola opcion no se pregunta",
    panel:find("if #opciones == 1 then ejecutor(def, opciones[1]); return true end", 1, true) ~= nil, true)
chk("lo usa la contienda", panel:find("if Elegir(contest.options, def, Contienda, elegida) then return true end", 1, true) ~= nil, true)
chk("lo usa ayudar", panel:find("if Elegir(def.helpOther.options, def, Ayudar, elegida) then return true end", 1, true) ~= nil, true)
chk("lo usa lanzar arma", panel:find("if Elegir(opciones, def, LanzarArma, nil) then return true end", 1, true) ~= nil, true)

print("Los tres estados nuevos tienen icono")
for _, id in ipairs({ "ayudado_prueba", "ayudado_ataque", "preparado" }) do
    chk(id, cat:find("\n    harford_estado_" .. id .. " = ", 1, true) ~= nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
