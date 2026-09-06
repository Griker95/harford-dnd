-- Estilos de combate CONDICIONALES: el flag se declara en los datos y se consume en el motor
-- CON su contexto. El defecto que esto sella: eran bonos globales -- Tiro con Arco sumaba +2
-- tambien cuerpo a cuerpo, Duelo con cualquier arma y Defensa desnudo.
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

-- ── DATOS: toda opcion de estilo condicional declara flag, nunca bono pelado ──
print("Los estilos condicionales son flags en los datos")
local CONDICIONALES = { defensa = true, duelo = true, duelos = true, tiro_arco = true, tirador = true }
local FLAGS = { styleDefense = 0, styleDueling = 0, styleArchery = 0, styleSharpshooter = 0 }
local pelados = {}
for fichero in ("CaballerodelaMuerte Cazador Guerrero Paladin"):gmatch("%S+") do
    local src = io.open("Harford/DnD/Data/Classes/" .. fichero .. ".lua"):read("*a")
    for linea in src:gmatch("[^\n]+") do
        local id = linea:match('id = "([a-z_]+)"')
        if id and (CONDICIONALES[id] or id:find("doble_empu", 1, true) == 1) then
            local flag = linea:match('kind = "flag", flag = "(style%w+)"')
            if flag then
                FLAGS[flag] = (FLAGS[flag] or 0) + 1
            elseif linea:find('kind = "bonus"', 1, true) then
                pelados[#pelados + 1] = fichero .. ":" .. id
            end
        end
    end
end
chk("ningun estilo con bono pelado", table.concat(pelados, ","), "")
chk("Defensa declarada en 3 clases", FLAGS.styleDefense, 3)
chk("Duelo declarado en 3 clases", FLAGS.styleDueling, 3)
chk("Tiro con Arco en 2 clases", FLAGS.styleArchery, 2)
chk("Tirador en 2 clases", FLAGS.styleSharpshooter, 2)

-- ── MOTOR: Calc consume los flags con el arma delante ──
print("Calc suma cada flag solo con su contexto")
local desempaquetar = unpack or table.unpack
local src = io.open("Harford/DnD/Engine/HarfordDnDCalc.lua"):read("*a")
HarfordDnDCalc = {}
HarfordDnDContext = { State = {} }
local flagsActivos = {}
HarfordDnDFeatureEffects = {
    GetBonus = function() return 0 end,
    HasFlag = function(f) return flagsActivos[f] == true end,
}
HarfordDnDItems = { HasOffhandCombatItem = function() return flagsActivos.__offhand == true end }
local function extraer(nombre)
    local i = src:find("function HarfordDnDCalc%." .. nombre .. "%(")
    local j = src:find("\nend", i)
    assert(i and j, nombre)
    assert(cargar("local function IsNpcContext() return false end\n" .. src:sub(i, j + 4)))()
end
extraer("GetWeaponAttackBonus")
extraer("GetWeaponDamageBonus")
local A, D = HarfordDnDCalc.GetWeaponAttackBonus, HarfordDnDCalc.GetWeaponDamageBonus

local distancia = { mode = "Ranged", props = { "Municion", "Dos manos" } }
local unaMano = { mode = "Melee", props = {} }
local dosManos = { mode = "Melee", props = { "Pesada", "Dos manos" } }

chk("sin flags nadie suma", A(distancia) + D(unaMano), 0)

flagsActivos = { styleArchery = true }
chk("Tiro con Arco: +2 a distancia", A(distancia), 2)
chk("Tiro con Arco: NADA cuerpo a cuerpo", A(unaMano), 0)

flagsActivos = { styleSharpshooter = true }
chk("Tirador: +1 a distancia", A(distancia), 1)
flagsActivos = { styleArchery = true, styleSharpshooter = true }
chk("los dos estilos de distancia acumulan", A(distancia), 3)

flagsActivos = { styleDueling = true }
chk("Duelo: +2 a una mano sin secundaria", D(unaMano), 2)
chk("Duelo: NADA a dos manos", D(dosManos), 0)
chk("Duelo: NADA a distancia", D(distancia), 0)
flagsActivos = { styleDueling = true, __offhand = true }
chk("Duelo: NADA con algo en la secundaria", D(unaMano), 0)

-- sin arma delante, cero: nunca bono falso
flagsActivos = { styleArchery = true, styleDueling = true, styleSharpshooter = true }
chk("sin def, ataque a cero", A(), 0)
chk("sin def, dano a cero", D(), 0)

-- ── MOTOR: Defensa vive en Combat con su contexto de armadura ──
print("Defensa exige armadura puesta")
local combat = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
chk("consulta el flag", combat:find('HasFlag("styleDefense")', 1, true) ~= nil, true)
chk("y la armadura", combat:find("LlevaArmadura()", 1, true) ~= nil, true)
chk("mirando el pecho, no el escudo", combat:find('GetSlot("Chest")', 1, true) ~= nil, true)

-- ── LLAMADORES: los tres puntos con arma en mano la pasan ──
print("Los llamadores pasan el arma")
local LLAMADORES = {
    { "Harford/DnD/Engine/HarfordDnDWeaponRolls.lua", "GetWeaponDamageBonus(def)" },
    { "Harford/DnD/UI/HarfordDnD.lua", "GetWeaponAttackBonus(def)" },
    { "Harford/DnD/UI/HarfordDnDAttackUI.lua", "GetWeaponDamageBonus(def)" },
}
for _, par in ipairs(LLAMADORES) do
    local t = io.open(par[1]):read("*a")
    chk(par[1]:match("([^/]+)%.lua") .. " pasa def", t:find(par[2], 1, true) ~= nil, true)
end

-- ── GUERRERO BENDITO (2026-09-06): elegir el estilo destapa la eleccion de sus 2 trucos ──
-- La opcion sola no daba nada que elegir: el rasgo derivado `pal_guerrero_bendito_trucos`
-- (requiresOption, patron Sistema de Emergencia) abre la eleccion de DOS trucos de la lista
-- del sacerdote (extraFrom los lista uno a uno del compendio). Y el grimorio resuelve trucos
-- elegidos por opcion tambien en rasgos de CLASE — antes solo lo hacia la rama de raza, asi
-- que el truco se elegia y no aparecia.
print("Guerrero Bendito abre sus dos trucos de sacerdote")
local pal = io.open("Harford/DnD/Data/Classes/Paladin.lua"):read("*a")
chk("rasgo derivado de la opcion",
    pal:find('id = "pal_guerrero_bendito_trucos", requiresOption = "guerrero_bendito"', 1, true) ~= nil, true)
chk("dos huecos de la lista del sacerdote",
    pal:find('extraFrom = "cantrip:Sacerdote",', 1, true) ~= nil
    and pal:find("slots = 2,\n            extraFrom", 1, true) ~= nil, true)
local comp = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
chk("el grimorio resuelve trucos por opcion en rasgos de CLASE",
    (comp:find("-- Trucos ELEGIDOS en un rasgo de eleccion de CLASE", 1, true) or 0)
    < (comp:find("-- CONJUROS DE RAZA", 1, true) or 0), true)

-- ── FORMATO DEL ABOUT (2026-09-06) ──
-- Los rasgos de Canalizar pierden el prefijo "Canalizar:" y el sufijo "(sagrado/proteccion/
-- represion)" — cada uno vive en el tab de SU camino y era redundante. En el About, los rasgos
-- DE ESPECIALIZACION llevan el nombre coloreado con el color de la clase, y un TRUCO elegido
-- (opcion con spellId) no va incrustado en la cabecera: cae a la linea cian de Pericia.
print("Canalizar sin prefijo y rasgos de especializacion coloreados")
chk("sin 'Canalizar:' en los nombres", pal:find('name = "Canalizar:', 1, true) == nil, true)
chk("sin sufijo de camino", pal:find('name = "Canalizar divinidad (', 1, true) == nil, true)
local crea = io.open("Harford/Character/HarfordCharacterCreation.lua"):read("*a")
chk("cabecera de subclase coloreada",
    crea:find('elseif entry.source == "Subclase" then', 1, true) ~= nil
    and crea:find(':25} {col:" .. hexClase .. "}"', 1, true) ~= nil, true)
chk("el truco elegido va a la linea cian, no a la cabecera",
    crea:find("if option and option.spellId then option = nil end", 1, true) ~= nil, true)

-- ── PLANTILLA DE MESA DEL GUERRERO BENDITO (2026-09-06) ──
-- El rasgo derivado NO sale como bloque del About (aboutHidden): sus trucos van en la linea
-- cian bajo la cabecera del Estilo de combate, separados por "|", con el icono de la OPCION
-- (ability_paladin_veneration, perfil de Melyan) mandando sobre el del rasgo.
print("Los trucos del Guerrero Bendito viven bajo su estilo en el About")
chk("el derivado se oculta del About", pal:find("aboutHidden = true", 1, true) ~= nil
    and crea:find("and not feature.aboutHidden then", 1, true) ~= nil, true)
chk("sus elegidos van en la linea cian dependiente",
    crea:find('lineaCianInline = table.concat(nombres, " {col:cccccc}|{/col} ")', 1, true) ~= nil
    and crea:find("if lineaCianInline then lines[#lines + 1] = lineaCianInline end", 1, true) ~= nil, true)
chk("el icono de la opcion manda en la cabecera",
    crea:find("(inlineIcono or FeatureIconName(feature))", 1, true) ~= nil, true)
chk("icono y descripcion de la mesa en la opcion",
    pal:find('id = "guerrero_bendito", icon = "ability_paladin_veneration"', 1, true) ~= nil, true)

-- ── REEMPLAZO AL SUBIR DE NIVEL (mecanizado) ──
-- "Siempre que ganes un nivel en esta clase, puedes reemplazar uno de estos trucos por otro":
-- rechooseOnLevelUp = "paladin" en el derivado; al aplicar una subida que toque esa clase,
-- FinishLevelUp abre el menu opcional (HarfordOfferLevelUpSwaps) — nivel 1 lo elegido, nivel 2
-- el sustituto sin ofrecer las ya elegidas; el truco reemplazado sale del grimorio y entra el
-- nuevo. En la cadena de creacion no se ofrece (se acaban de elegir).
print("El reemplazo por nivel esta mecanizado")
chk("el derivado lo declara", pal:find('rechooseOnLevelUp = "paladin"', 1, true) ~= nil, true)
local adv = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")
chk("el menu existe y filtra por clase subida",
    adv:find("local function OfferLevelUpSwaps(classIds)", 1, true) ~= nil
    and adv:find("clases[tostring(f.rechooseOnLevelUp)]", 1, true) ~= nil, true)
chk("no ofrece las ya elegidas en otros huecos",
    adv:find("if s ~= slot then ocupadas[tostring(opt)] = true end", 1, true) ~= nil, true)
chk("el truco reemplazado sale del grimorio y entra el nuevo",
    adv:find("db.knownSpells[optAnterior.spellId] = nil", 1, true) ~= nil
    and adv:find("if elegida.spellId then db.knownSpells[elegida.spellId] = true end", 1, true) ~= nil, true)
local draftSrc = io.open("Harford/Character/HarfordCharacterDraft.lua"):read("*a")
chk("la subida lo ofrece, la cadena de creacion no",
    draftSrc:find("if not veniaDeCadena and _G.HarfordOfferLevelUpSwaps then", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
