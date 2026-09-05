-- COMPETENCIAS DE MULTICLASE (seccion "Multiclase" del manual, por clase).
--
-- Lo que sella: (1) las DOCE clases declaran su tabla `multiclass` con los minimos de
-- caracteristica del manual; (2) entrar en una clase sin ser la inicial ya no da sus listas
-- completas: da el subconjunto declarado (la regla de Resolve la canda `efectos_rasgos`);
-- (3) la eleccion de habilidades COMPLETA lleva `onlyFirstClass` y las clases que dan "una
-- habilidad de su lista" al multiclasear generan la variante `_competencias_multiclase`
-- (slots=1, `onlyMulticlass`); el Druida da Naturaleza FIJA y el Mago no da nada; (4) las
-- CUATRO superficies que recorren rasgos de clase aplican las puertas: Progression
-- (GetUnlockedFeatures), el Libro, el asistente de subida/creacion y el About del generador;
-- (5) el asistente AVISA de los minimos al estrenar clase — no bloquea (decision: una ficha
-- llevada a mano puede tener puntuaciones sin importar y bloquear sobre 10s por defecto
-- seria hostil).

local cargar = loadstring or load
local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-60s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── CARGA REAL: Libro + 12 clases + derivados, orden del .toc ──────────────
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tostring, env.tonumber = ipairs, pairs, tostring, tonumber
env.type, env.table, env.string, env.math, env.select = type, table, string, math, select
env.setmetatable, env.next, env.print, env.error, env.assert = setmetatable, next, function() end, error, assert
env.unpack = table.unpack or unpack
env._G = env  -- HarfordDnDData lee _G.HarfordIconCatalog al cargar
for _, ruta in ipairs({
    "Harford/DnD/Data/HarfordDnDData.lua",
    "Harford/DnD/Data/HarfordDnDBook.lua",
    "Harford/DnD/Data/Classes/CaballerodelaMuerte.lua",
    "Harford/DnD/Data/Classes/CazadordeDemonios.lua",
    "Harford/DnD/Data/Classes/Druida.lua",
    "Harford/DnD/Data/Classes/Cazador.lua",
    "Harford/DnD/Data/Classes/Mago.lua",
    "Harford/DnD/Data/Classes/Monje.lua",
    "Harford/DnD/Data/Classes/Paladin.lua",
    "Harford/DnD/Data/Classes/Sacerdote.lua",
    "Harford/DnD/Data/Classes/Picaro.lua",
    "Harford/DnD/Data/Classes/Chaman.lua",
    "Harford/DnD/Data/Classes/Brujo.lua",
    "Harford/DnD/Data/Classes/Guerrero.lua",
    "Harford/DnD/Data/HarfordDnDBookDerived.lua",
}) do
    local src = assert(io.open(ruta)):read("*a")
    local f
    if setfenv then f = assert(cargar(src, ruta)); setfenv(f, env)
    else f = assert(cargar(src, ruta, "t", env)) end
    assert(pcall(f))
end
local B = env.HarfordDnDBook

-- ─── (1) LAS DOCE DECLARAN SU SECCION DE MULTICLASE ─────────────────────────
print("Las doce clases declaran multiclass con sus minimos")
local clases = {}
for _, c in ipairs(B.GetClasses and B.GetClasses() or B.CLASSES) do clases[c.id] = c end
local n = 0
for id, c in pairs(clases) do
    n = n + 1
    if not (type(c.multiclass) == "table" and type(c.multiclass.minimums) == "table"
        and #c.multiclass.minimums > 0) then
        chk(id .. ": multiclass.minimums declarado", false, true)
    end
end
chk("doce clases revisadas", n, 12)
-- Muestras cotejadas contra el manual (la letra de cada seccion "Multiclase").
chk("Guerrero: Fuerza O Destreza (un grupo con dos)",
    table.concat(clases.guerrero.multiclass.minimums[1], "/"), "Fuerza/Destreza")
chk("CdM: Fuerza Y Carisma (dos grupos)", #clases.caballero_muerte.multiclass.minimums, 2)
chk("Mago: no da competencias", clases.mago.multiclass.armorProfs == nil
    and clases.mago.multiclass.weaponProfs == nil and clases.mago.multiclass.skillChoices == nil, true)
chk("Paladin: escudo incluido", table.concat(clases.paladin.multiclass.armorProfs, ","), "ligera,media,escudo")
chk("Paladin: pesada NO (la da solo como inicial)",
    tostring(table.concat(clases.paladin.multiclass.armorProfs, ",")):find("pesada"), nil)
chk("Picaro: herramientas de ladron",
    clases.picaro.multiclass.toolProfs[1], "Herramientas de ladron")
chk("CdD: guja de guerra viaja tambien al multiclasear",
    table.concat(clases.cazador_demonios.multiclass.weaponProfs, ","), "sencillas,marciales,Guja de guerra")

-- ─── (3) VARIANTES GENERADAS ────────────────────────────────────────────────
print("Variantes de Competencias de clase")
local function rasgo(c, id)
    for _, f in ipairs(c.features or {}) do if f.id == id then return f end end
end
for _, id in ipairs({ "cazador", "sacerdote", "picaro", "brujo" }) do
    local full = rasgo(clases[id], id .. "_competencias_clase")
    local multi = rasgo(clases[id], id .. "_competencias_multiclase")
    chk(id .. ": la completa es solo de clase inicial", full and full.onlyFirstClass, true)
    chk(id .. ": variante multiclase de 1 habilidad",
        multi and multi.onlyMulticlass == true and multi.choice and multi.choice.slots, 1)
end
local dru = rasgo(clases.druida, "druida_competencias_multiclase")
chk("Druida: Naturaleza FIJA (pasivo, sin eleccion)",
    dru and dru.choice == nil and dru.effects[1].kind == "skillProf" and dru.effects[1].skill, "Naturaleza")
chk("Mago: sin variante multiclase", rasgo(clases.mago, "mago_competencias_multiclase"), nil)
-- Toda opcion generada lleva la regla de su habilidad (el About/selector la muestran).
local conDesc = true
for _, opt in ipairs(rasgo(clases.picaro, "picaro_competencias_multiclase").choice.options) do
    if tostring(opt.desc or "") == "" then conDesc = false end
end
chk("las opciones llevan la descripcion de la habilidad", conDesc, true)

-- ─── (4) LAS CUATRO SUPERFICIES APLICAN LAS PUERTAS ─────────────────────────
print("Las cuatro superficies aplican onlyFirstClass/onlyMulticlass")
local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("Progression.GetUnlockedFeatures (Entra)",
    prog:find("if feature.onlyFirstClass and not esPrimera then return false end", 1, true) ~= nil, true)
local libro = io.open("Harford/Character/HarfordCharacterBook.lua"):read("*a")
chk("el Libro (por posicion de la entrada)",
    libro:find("(it.feature.onlyFirstClass and i > 1)", 1, true) ~= nil, true)
local adv = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")
chk("el asistente de subida/creacion",
    adv:find("(feature.onlyFirstClass and not esClasePrimera)", 1, true) ~= nil, true)
local crea = io.open("Harford/Character/HarfordCharacterCreation.lua"):read("*a")
chk("el About del generador",
    crea:find("(feature.onlyFirstClass and not esPrimera)", 1, true) ~= nil, true)

-- ─── (4b) LAS FICHAS ANTIGUAS SE ACOPLAN, NO PIERDEN EN SILENCIO ────────────
-- Una multiclase creada con la regla vieja eligio 2-3 habilidades por la eleccion COMPLETA de
-- su segunda clase; la puerta nueva la apagaria en silencio. La migracion de Migrate traslada
-- la PRIMERA elegida a `_competencias_multiclase` (las demas caen, que es la regla), conserva
-- la eleccion vieja por si esa clase vuelve a ser inicial, y es idempotente.
print("Migracion de elecciones antiguas de la segunda clase")
local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("traslada al primer slot con valor (los slots admiten huecos)",
    prog:find("for s = 1, 8 do if viejo[s] ~= nil then primera = viejo[s] break end end", 1, true) ~= nil, true)
chk("solo si la variante esta vacia (idempotente)",
    prog:find('primera and (type(nuevo) ~= "table" or next(nuevo) == nil)', 1, true) ~= nil, true)
chk("rellena la variante multiclase",
    prog:find("data.choices[claveNueva] = { primera }", 1, true) ~= nil, true)
chk("y NO borra la eleccion vieja",
    prog:find('data.choices[tostring(entry.classId) .. "_competencias_clase"] = nil', 1, true), nil)
chk("avisando al jugador (no silencioso)",
    prog:find("conservas ", 1, true) ~= nil, true)

-- ─── (5) EL AVISO DE MINIMOS: AVISA, NO BLOQUEA ─────────────────────────────
print("Minimos de caracteristica al estrenar clase")
chk("el asistente los revisa (clase nueva Y las que ya tienes)",
    adv:find("local function RevisaMinimos(def)", 1, true) ~= nil, true)
chk("con el umbral 13 del manual", adv:find(">= 13 then cumple = true end", 1, true) ~= nil, true)
chk("y avisa sin bloquear", adv:find("aqui no se bloquea", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
