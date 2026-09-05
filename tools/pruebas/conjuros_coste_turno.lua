-- LOS CONJUROS COBRAN SU TIEMPO DE LANZAMIENTO en la economia de turno: accion, accion
-- adicional o reaccion, ANTES que el mana. El bug que canda esta suite: `silent` (que solo
-- deberia callar el anuncio) tambien saltaba el cobro, y como las rutas de ATAQUE y de AREA
-- lanzan con silent (su tirada ya anuncia), los conjuros de COMBATE eran gratis en la economia.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local core = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")

print("El cobro no depende de silent")
chk("solo lo saltan ritual y skipTurnCost explicito",
    core:find("not (options and (options.skipTurnCost or options.ritual))", 1, true) ~= nil, true)
chk("y se cobra antes que el mana (orden en ConfirmCast)",
    core:find("not (options and (options.skipTurnCost or options.ritual))", 1, true)
    < core:find("local ok, costOrErr, current, maxValue = API.SpendSpellMana", 1, true), true)

print("Las rutas de combate llaman a ConfirmCast (y por tanto cobran)")
chk("area: en el onCommit",
    core:find("local commitOptions = { silent = true, free = options.free,", 1, true) ~= nil, true)
chk("ataque: antes de tirar",
    core:find('local ok, castErr = API.ConfirmCast(spellId, { silent = true, free = options.free,', 1, true) ~= nil, true)

-- SIN OBJETIVO = LANZAMIENTO SIN MAS (2026-09-05, regla UNIVERSAL, no por lista): cualquier
-- conjuro sin target cae a ConfirmCast (anuncio, coste, concentracion) — Crear llama ilumina,
-- una Descarga de fuego contra un barril la resuelve la mesa. Con objetivo, daño por la via
-- normal. La unica excepcion es la curacion, que sin objetivo se resuelve sobre uno mismo.
print("Sin objetivo se lanza sin mas; con objetivo hace daño")
chk("la puerta universal existe",
    core:find('if not (UnitExists and UnitExists("target")) then', 1, true) ~= nil, true)
chk("y cae a ConfirmCast salvo curacion",
    core:find('local esCuracion = preview and preview.area and preview.area.resolution == "heal"', 1, true) ~= nil, true)
chk("consultando el area sin consumir cargas",
    core:find('API.BuildAreaDefinition(spell, { soloConsultar = true })\n        local esCuracion', 1, true) ~= nil, true)
-- La puerta va ANTES del selector de variante de daño: para lanzar sin mas no se elige formula.
-- (El literal de variantes existe tambien en BuildAreaDefinition: se busca DESDE la puerta.)
local posPuerta = core:find('if not (UnitExists and UnitExists("target")) then', 1, true)
chk("y antes de exigir la variante de daño",
    posPuerta ~= nil
    and core:find("local variants = API.GetDamageVariants(spell)", posPuerta, true) ~= nil, true)

print("El mapeo de castingTime cubre el catalogo")
chk("adicional -> accion_adicional",
    core:find('texto:find("adicional") or texto:find("bonus")', 1, true) ~= nil, true)
chk("reaccion -> reaccion", core:find('texto:find("reacc")', 1, true) ~= nil, true)
-- "1 accion, u 8 horas" existe en el compendio: accion se comprueba ANTES que minutos/horas.
chk("accion gana a horas (1 accion, u 8 horas)",
    core:find('elseif texto:find("accion") then coste = "accion"', 1, true) ~= nil
    and core:find('elseif texto:find("accion") then coste = "accion"', 1, true)
    < core:find('elseif texto:find("minuto") or texto:find("hora") then coste = nil end', 1, true), true)
chk("minutos/horas no cobran (fuera de turnos)",
    core:find('elseif texto:find("minuto") or texto:find("hora") then coste = nil end', 1, true) ~= nil, true)
chk("se cobra con el motor comun (SpendForFeature)",
    core:find("HarfordDnDConditions.Turn.SpendForFeature", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
