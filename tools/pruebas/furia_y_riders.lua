-- Furia Elemental del Chaman + riders del Cazador de Demonios (Embestida vil, Momentum vengativo).
-- Lo que sella: el intercambio de tipo solo toca dano ELEMENTAL, el dado de Caos sigue la tabla
-- del libro, y el punto de Vil solo vuelve con DOS impactos confirmados (nil = no se sabe = manual).
local cargar = loadstring or load
local fallos = 0
local function chk(nombre, real, esperado)
    if real ~= esperado then
        fallos = fallos + 1
        print("  FALLO " .. nombre .. ": " .. tostring(real) .. " ~= " .. tostring(esperado))
    else
        print("  ok " .. nombre)
    end
end

-- ── FURIA ELEMENTAL ──
print("Furia elemental: cadena completa")
local chaman = io.open("Harford/DnD/Data/Classes/Chaman.lua"):read("*a")
chk("el rasgo es un boton con menu", chaman:find('actionKind = "elementalFury"', 1, true) ~= nil, true)
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
chk("el repartidor abre el menu", panel:find('OpenElementalFuryMenu(self.feature', 1, true) ~= nil, true)
local ficha = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("el menu escribe FuriaElemental en el store",
    ficha:find('HarfordDnDStore.SetValue("FuriaElemental", key)', 1, true) ~= nil, true)
chk("y puede apagarse", ficha:find('HarfordDnDStore.SetValue("FuriaElemental", "")', 1, true) ~= nil, true)

-- El intercambio del Compendio, extraido y ejercitado con un stub de store.
local core = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
local bloque = core:match("(%-%- FURIA ELEMENTAL.-\n    end\n)")
chk("el bloque de intercambio existe en BuildAreaDefinition", bloque ~= nil, true)
if bloque then
    local elegido = "cold"
    HarfordDnDStore = { GetValue = function(k, d) return k == "FuriaElemental" and elegido or d end }
    local damageComponents = {
        { damageType = "fire" }, { damageType = "necrotic" }, { damageType = "lightning" },
    }
    local fn = assert(cargar("return function(damageComponents)\n" .. bloque .. "\nend"))()
    fn(damageComponents)
    chk("el fuego se convierte al tipo elegido", damageComponents[1].damageType, "cold")
    chk("el rayo tambien", damageComponents[3].damageType, "cold")
    chk("el necrotico NO se toca", damageComponents[2].damageType, "necrotic")
    elegido = "radiant"  -- no es de la lista elemental: no debe hacer nada
    damageComponents = { { damageType = "fire" } }
    fn(damageComponents)
    chk("un tipo fuera de la lista no convierte nada", damageComponents[1].damageType, "fire")
    elegido = ""
    damageComponents = { { damageType = "fire" } }
    fn(damageComponents)
    chk("apagado conserva el tipo original", damageComponents[1].damageType, "fire")
end

-- ── DADO DE CAOS ──
print("El dado de Caos sigue la tabla del libro")
local abilities = io.open("Harford/DnD/Engine/HarfordDnDAbilities.lua"):read("*a")
local fnCaos = abilities:match("(local function ChaosDieSides%(%).-\nend\n)")
chk("ChaosDieSides existe", fnCaos ~= nil, true)
if fnCaos then
    local niveles
    HarfordDnDProgression = { GetClassLevels = function() return niveles end }
    local caos = assert(cargar(fnCaos .. "\nreturn ChaosDieSides"))()
    niveles = { { classId = "cazador_demonios", level = 2 } }
    chk("nivel 2 -> d4", caos(), 4)
    niveles = { { classId = "cazador_demonios", level = 4 } }
    chk("nivel 4 -> d4", caos(), 4)
    niveles = { { classId = "cazador_demonios", level = 5 } }
    chk("nivel 5 -> d6", caos(), 6)
    niveles = { { classId = "guerrero", level = 5 }, { classId = "cazador_demonios", level = 1 } }
    chk("multiclase: solo cuenta el nivel de CdD", caos(), 0)
    niveles = { { classId = "guerrero", level = 3 } }
    chk("sin CdD no hay dado", caos(), 0)
end

-- ── RIDERS ──
print("Los riders disparan con su condicion exacta")
local cdd = io.open("Harford/DnD/Data/Classes/CazadordeDemonios.lua"):read("*a")
chk("Embestida vil declara felRush", cdd:find('flag = "felRush"', 1, true) ~= nil, true)
chk("Momentum vengativo declara vengefulMomentum", cdd:find('flag = "vengefulMomentum"', 1, true) ~= nil, true)
chk("y ya no lleva el resourceGain manual muerto",
    cdd:find('dh_dev_momentum_vengativo", level = 6, name = "Momentum vengativo", type = "pasivo", resourceGain', 1, true), nil)
chk("DoWeaponAttack devuelve el impacto", ficha:find("return hitFlag", 1, true) ~= nil, true)
chk("Mordida exige DOS impactos estrictos (nil no vale)",
    abilities:find("golpe1 == true and golpe2 == true", 1, true) ~= nil, true)
chk("y solo con el flag activo",
    abilities:find('HasFlag("vengefulMomentum")', 1, true) ~= nil, true)
chk("Embestida se anuncia desde el anuncio de Momentum",
    panel:find('feature.id or "") == "dh_momentum"', 1, true) ~= nil, true)
chk("con su flag delante", panel:find('HasFlag("felRush")', 1, true) ~= nil, true)

-- ── CONVERSION PUNTOS<->RANURAS (ya implementada; candado de la matematica) ──
print("Lanzamiento Flexible / Devocion: la tabla de costes del manual")
local mana = io.open("Harford/DnD/State/HarfordDnDMana.lua"):read("*a")
local costes = mana:match("API%.SLOT_POINT_COST = %{ ([%d, ]+) %}")
chk("costes 2/3/5/6/7 para niveles 1-5", costes, "2, 3, 5, 6, 7")
chk("las ranuras creadas desaparecen al descanso largo",
    io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
        :find("restaura los gastados Y hace desaparecer los creados", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
