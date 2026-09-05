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

-- CONJUROS DE DOBLE USO (2026-09-05): crean algo util por si solo y ADEMAS pueden dañar.
-- Sin objetivo se lanzan sin mas (ConfirmCast: anuncio, coste, concentracion); con objetivo,
-- daño por la via normal. Antes el gate de alcance los abortaba ("Necesitas un objetivo").
print("Doble uso: sin objetivo se lanza sin mas, con objetivo hace daño")
chk("la puerta existe y cae a ConfirmCast",
    core:find("if DUAL_USE_SPELLS[spellId] and not (UnitExists and UnitExists(\"target\")) then", 1, true) ~= nil, true)
for _, id in ipairs({ "crear_fogata", "crear_llama", "hoja_de_fuego", "hoja_sombria", "esfera_de_llamas", "rayo_de_luna" }) do
    chk(id .. " esta en la lista", core:find("    " .. id .. " = true,", 1, true) ~= nil, true)
end
-- Y los ataques PUROS con sabor de luz NO: sin objetivo, su aviso es el correcto.
chk("ira_solar no esta (ataque puro)", core:find("    ira_solar = true,", 1, true) == nil, true)
-- La puerta va ANTES del selector de variante de daño: para iluminar no se elige formula.
-- (El literal de variantes existe tambien en BuildAreaDefinition: se busca DESDE la puerta.)
local posDual = core:find("if DUAL_USE_SPELLS[spellId]", 1, true)
chk("y antes de exigir la variante de daño",
    posDual ~= nil
    and core:find("local variants = API.GetDamageVariants(spell)", posDual, true) ~= nil, true)

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
