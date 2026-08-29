-- Efectos de las opciones elegidas (brebajes del Monje, trampas del Cazador, Maldiciones del
-- Brujo). Lo que se prueba es `ResolveAreaValues`: los datos declaran DE DONDE sale cada numero
-- (`dcAbility`, `damageFrom`, `damageDiceFrom`) y esta funcion los convierte en la CD y los dados
-- reales de la ficha que la usa. Sin esto un area declarada en el libro llevaria valores fijos,
-- que es justo lo que no puede ser: dependen del nivel y de la caracteristica del personaje.
local cargar = loadstring or load
local src = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))
local i = assert(src:find("local function OptionSaveDC"))
local j = assert(src:find("\n%-%- Abre el area de un rasgo", i))
local codigo = src:sub(i, j) .. "\nreturn ResolveAreaValues, OptionSaveDC"

-- Ficha de prueba: Monje 6 / Cazador 5 / Brujo 11, Sabiduria +3, Carisma +4, competencia +3.
local NIVELES = { { classId = "monje", level = 6 }, { classId = "cazador", level = 5 }, { classId = "brujo", level = 11 } }
local MODS = { Sabiduria = 3, Carisma = 4, Destreza = 2 }
local env = {
    ipairs = ipairs, pairs = pairs, type = type, tonumber = tonumber, tostring = tostring, math = math,
    GetProfileName = function() return "Prueba" end,
    HarfordDnDProgression = { GetClassLevels = function() return NIVELES end },
    HarfordDnDCalc = { GetAbilityMod = function(a) return MODS[a] or 0 end, GetSpellPB = function() return 3 end },
    HarfordDnDFeatureEffects = { GetBonus = function() return 0 end },
}
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Resolve, DC = f()

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = real == esp
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-46s %-14s %s", etiqueta, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("CD de salvacion segun la caracteristica declarada")
chk("Monje/trampa (Sabiduria): 8+3+3", DC({ dcAbility = "Sabiduria" }), 14)
chk("Palabra de Poder (Carisma): 8+3+4", DC({ dcAbility = "Carisma" }), 15)
chk("sin declarar cae a Carisma", DC({}), 15)

print("Aliento de Fuego: nivel de Monje + Mod. Sabiduria, dano FIJO")
local brebaje = Resolve({ dcAbility = "Sabiduria", area = {
    shape = "cone", resolution = "save", saveAbility = "Destreza", success = "half",
    damageFrom = { classLevel = "monje", abilityMod = "Sabiduria", damageType = "fuego" } } })
chk("dano fijo 6+3", brebaje.area.damageComponents[1].fixedAmount, 9)
chk("tipo de dano", brebaje.area.damageComponents[1].damageType, "fuego")
chk("CD rellenada", brebaje.area.dc, 14)
chk("damageFrom consumido", brebaje.area.damageFrom, nil)

print("Trampa explosiva: el DOBLE del nivel de Cazador")
local trampa = Resolve({ dcAbility = "Sabiduria", area = {
    resolution = "save", saveAbility = "Destreza", success = "half",
    damageFrom = { classLevel = "cazador", multiplier = 2, damageType = "fuego" } } })
chk("dano fijo 5x2", trampa.area.damageComponents[1].fixedAmount, 10)

print("Maldicion de la Agonia: los dados escalan con el nivel de Brujo")
local function agonia(nivelBrujo)
    NIVELES[3].level = nivelBrujo
    return Resolve({ dcAbility = "Carisma", area = { resolution = "auto", damageDiceFrom = {
        die = 4, classLevel = "brujo", scale = { { 5, 2 }, { 11, 3 }, { 17, 4 } }, damageType = "psiquico" } } })
        .area.damageComponents[1].damageDice
end
chk("nivel 2", agonia(2), "1d4")
chk("nivel 4 (aun no escala)", agonia(4), "1d4")
chk("nivel 5", agonia(5), "2d4")
chk("nivel 10", agonia(10), "2d4")
chk("nivel 11", agonia(11), "3d4")
chk("nivel 17", agonia(17), "4d4")
NIVELES[3].level = 11

print("El coste del rasgo llega al area (el motor solo mira area.resourceKey)")
local conCoste = Resolve({ resourceKey = "chi", resourceCost = 2, area = { resolution = "auto",
    damageFrom = { classLevel = "monje", damageType = "fuego" } } })
chk("resourceKey heredado", conCoste.area.resourceKey, "chi")
chk("resourceCost heredado", conCoste.area.resourceCost, 2)

print("No se toca la tabla original del libro (es compartida)")
local original = { dcAbility = "Sabiduria", area = { resolution = "save", saveAbility = "Destreza",
    success = "half", damageFrom = { classLevel = "monje", damageType = "fuego" } } }
Resolve(original)
chk("damageFrom sigue en el libro", type(original.area.damageFrom), "table")
chk("sin CD escrita en el libro", original.area.dc, nil)

print("Un rasgo sin area pasa tal cual")
local pelado = { name = "X" }
chk("misma tabla", Resolve(pelado), pelado)


print("Canalizar Divinidad del Paladin (nivel 6, Carisma +4, competencia +3)")
NIVELES[1] = { classId = "paladin", level = 6 }
MODS.Carisma = 4
local martillo = Resolve({ dcAbility = "Carisma", area = {
    shape = "sphere", resolution = "save", saveAbility = "Constitucion", success = "half",
    damageComponents = { { damageDice = "2d10", damageType = "radiante" } },
    damageBonusFrom = { classLevel = "paladin" } } })
chk("Martillo de Luz: dados intactos", martillo.area.damageComponents[1].damageDice, "2d10")
chk("Martillo de Luz: +nivel como bonus", martillo.area.damageComponents[1].damageBonus, 6)
chk("Martillo de Luz: CD 8+3+4", martillo.area.dc, 15)
chk("damageBonusFrom consumido", martillo.area.damageBonusFrom, nil)

local consagracion = Resolve({ dcAbility = "Carisma", area = {
    shape = "sphere", resolution = "save", saveAbility = "Destreza", success = "half",
    damageFrom = { classLevel = "paladin", multiplier = 0.5, damageType = "radiante" } } })
chk("Consagracion: medio nivel, redondeado abajo", consagracion.area.damageComponents[1].fixedAmount, 3)

-- El bonus se suma al PRIMER componente y no toca la tabla del libro.
local libro = { dcAbility = "Carisma", area = { resolution = "auto",
    damageComponents = { { damageDice = "2d10", damageType = "radiante" } },
    damageBonusFrom = { classLevel = "paladin" } } }
Resolve(libro); Resolve(libro)
chk("aplicado dos veces no acumula", Resolve(libro).area.damageComponents[1].damageBonus, 6)
chk("el libro conserva damageBonusFrom", type(libro.area.damageBonusFrom), "table")
chk("el libro no gana damageBonus", libro.area.damageComponents[1].damageBonus, nil)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
