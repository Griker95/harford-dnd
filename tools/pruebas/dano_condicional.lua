-- HarfordDnDConditionalDamage: cuanto cuesta un dano extra, hasta que nivel llega y cuantos dados
-- salen. Es la fuente unica de esos numeros para la seccion Ataque y para el Libro.
--
-- Estaba sin cubrir del todo: de 14 mutaciones, las 14 pasaban. Aqui un `math.floor` por `ceil`
-- regala un nivel de Golpe Runico, y un `<` por `<=` deja pagar lo que no se tiene.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local RECURSOS, GASTOS = {}, {}
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.HarfordDnDStore = { condDamageLevel = {} }
env.HarfordDnDResources = { DEFS = {
    rage = { label = "Ira" }, chi = { label = "Chi" }, soul_shard = { label = "Fragmentos" },
} }

local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDConditionalDamage.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
f()
local D = env.HarfordDnDConditionalDamage

D.Configure({
    getResourceCurrent = function(clave) return RECURSOS[clave] or 0 end,
    adjustResourceCurrent = function(clave, delta)
        GASTOS[#GASTOS + 1] = clave .. " " .. delta
        RECURSOS[clave] = (RECURSOS[clave] or 0) + delta
    end,
})

-- ─── Nivel maximo ───────────────────────────────────────────────────────────
print("Sin escalado, un dano condicional es de un solo nivel")
chk("simple", D.GetMaxLevel({ id = "x" }), 1)
chk("sin datos, ninguno", D.GetMaxLevel(nil), 0)

-- El techo real es lo que puedes PAGAR: con 3 de ira y 1 por nivel, tres niveles.
print("El recurso pone el techo")
RECURSOS.rage = 3
local ira = { id = "runic_strike", resourceCost = "rage", countPerLevel = 1, maxLevel = 5 }
chk("tres de ira, tres niveles", D.GetMaxLevel(ira), 3)
RECURSOS.rage = 0
chk("sin ira, ninguno", D.GetMaxLevel(ira), 0)
RECURSOS.rage = 10
chk("de sobra, manda el maximo del rasgo", D.GetMaxLevel(ira), 5)

-- Con coste 2 por nivel, 5 de recurso dan DOS niveles, no dos y medio: la division se redondea
-- hacia abajo. Un `ceil` aqui regalaria un nivel que no se puede pagar.
print("Un coste de dos por nivel se redondea hacia ABAJO")
local caro = { id = "caro", resourceCost = "rage", costPerLevel = 2, countPerLevel = 1, maxLevel = 9 }
RECURSOS.rage = 5
chk("cinco de ira a dos por nivel: dos", D.GetMaxLevel(caro), 2)
RECURSOS.rage = 6
chk("seis: tres", D.GetMaxLevel(caro), 3)
RECURSOS.rage = 1
chk("uno: ninguno", D.GetMaxLevel(caro), 0)

-- ─── Coste ──────────────────────────────────────────────────────────────────
print("El coste escala con el nivel elegido")
RECURSOS.rage = 10
local c = D.GetCosts(ira, 3)
chk("un solo recurso", #c, 1)
chk("tres niveles, tres de ira", c[1] and c[1].amount, 3)
chk("con su nombre legible", c[1] and c[1].label, "Ira")
chk("a dos por nivel, el doble", (D.GetCosts(caro, 3))[1].amount, 6)
chk("texto del coste", D.GetCostText(ira, 2), "2 Ira")

-- ─── Si se puede pagar ──────────────────────────────────────────────────────
print("Pagar: hace falta tenerlo, no acercarse")
RECURSOS.rage = 3
chk("justo lo que cuesta, si", (D.CanPay(ira, 3)), true)
chk("uno mas de lo que hay, no", (D.CanPay(ira, 4)), false)
RECURSOS.rage = 2
chk("con dos no llega a tres", (D.CanPay(ira, 3)), false)
chk("pero a dos si", (D.CanPay(ira, 2)), true)
RECURSOS.rage = 0
chk("sin nada, ni el primero", (D.CanPay(ira, 1)), false)

print("HasPayable dice si hay ALGUN nivel pagable")
RECURSOS.rage = 1
chk("con uno, algo se puede", D.HasPayable(ira), true)
RECURSOS.rage = 0
chk("sin nada, no", D.HasPayable(ira), false)

-- ─── Gasto ──────────────────────────────────────────────────────────────────
print("Gastar descuenta lo que dice el coste, y solo si se puede")
RECURSOS.rage, GASTOS = 5, {}
local ok = D.Spend(ira, 2)
chk("se gasta", ok, true)
chk("y descuenta dos", RECURSOS.rage, 3)
GASTOS = {}
ok = D.Spend(ira, 9)
chk("lo que no se puede pagar no se gasta", ok, false)
chk("y no toca el recurso", #GASTOS, 0)
chk("el recurso sigue intacto", RECURSOS.rage, 3)

-- ─── Dados resultantes ──────────────────────────────────────────────────────
-- Golpe Runico y compania: los dados salen del nivel, no de un numero escrito.
print("Los dados salen del nivel elegido")
local r = D.GetLeveled({ id = "x", countPerLevel = 2 }, 3)
chk("dos por nivel, tres niveles: seis dados", r.dice, 6)
r = D.GetLeveled({ id = "x", countPerLevel = 1, extraCountOffset = 1 }, 2)
chk("con un dado de regalo: tres", r.dice, 3)
-- Un tope de dados manda sobre el escalado.
r = D.GetLeveled({ id = "x", countPerLevel = 2, maxCount = 5 }, 4)
chk("el tope manda", r.dice, 5)
-- Sin escalado no se inventa un `dice`: se queda el que traiga el rasgo.
r = D.GetLeveled({ id = "x", dice = 4 }, 3)
chk("sin escalado, el suyo", r.dice, 4)

-- El nivel nunca baja de 1, venga como venga.
print("El nivel nunca baja de uno")
local _, n = D.GetLeveled({ id = "x", countPerLevel = 1 }, 0)
chk("cero se convierte en uno", n, 1)
_, n = D.GetLeveled({ id = "x", countPerLevel = 1 }, -3)
chk("negativo tambien", n, 1)
_, n = D.GetLeveled({ id = "x", countPerLevel = 1 }, 2.7)
chk("y los decimales se truncan", n, 2)

-- ─── Nivel seleccionado ─────────────────────────────────────────────────────
print("El nivel guardado se recuerda, con su minimo")
env.HarfordDnDStore.condDamageLevel = { x = 4 }
chk("lo guardado", D.GetSelectedLevel({ id = "x" }), 4)
chk("sin guardar, el minimo del rasgo", D.GetSelectedLevel({ id = "y", minLevel = 2 }), 2)
chk("y sin minimo, uno", D.GetSelectedLevel({ id = "z" }), 1)
env.HarfordDnDStore.condDamageLevel = { x = 0 }
chk("un cero guardado no baja de uno", D.GetSelectedLevel({ id = "x" }), 1)

-- ─── Tope por caracteristica ────────────────────────────────────────────────
-- Hay rasgos cuyo maximo es tu modificador (no puedes gastar mas veces que tu Mod).
print("Un tope por caracteristica")
env.HarfordDnDCalc = { GetAbilityMod = function() return 3 end }
RECURSOS.chi = 99
local porMod = { id = "m", resourceCost = "chi", maxLevelAbility = "Sabiduria",
                 countPerLevel = 1, maxLevel = 10 }
chk("el modificador manda sobre el maximo", D.GetMaxLevel(porMod), 3)
env.HarfordDnDCalc = { GetAbilityMod = function() return -1 end }
chk("un modificador negativo deja en cero", D.GetMaxLevel(porMod), 0)
env.HarfordDnDCalc = nil

-- ─── Nivel minimo del rasgo ─────────────────────────────────────────────────
-- Hay rasgos que empiezan en 2: no se pueden usar "a nivel 1". El minimo nunca baja de 1 aunque el
-- dato venga a 0, y el maximo por debajo del minimo significa que no se puede usar en absoluto.
print("El minimo del rasgo")
RECURSOS.rage = 10
chk("empieza en 2", D.GetMaxLevel({ id = "m2", minLevel = 2, maxLevel = 4 }), 4)
chk("un minimo por encima del maximo, inutilizable",
    D.GetMaxLevel({ id = "m3", minLevel = 5, maxLevel = 3 }), 0)
chk("un minimo de cero cuenta como uno",
    D.GetMaxLevel({ id = "m4", minLevel = 0, maxLevel = 2 }), 2)
chk("y uno negativo tambien", D.GetMaxLevel({ id = "m5", minLevel = -4, maxLevel = 2 }), 2)

-- ─── Tope por numero de dados ───────────────────────────────────────────────
-- Un rasgo puede topar los DADOS en vez de los niveles: con 5 dados de tope y 1 de regalo, solo
-- quedan 4 niveles que anadan algo.
print("Un tope de dados limita los niveles")
local topado = { id = "t", maxCount = 5, extraCountOffset = 1, countPerLevel = 1, maxLevel = 20 }
chk("cinco dados menos el de regalo: cuatro niveles", D.GetMaxLevel(topado), 4)
chk("sin regalo, cinco", D.GetMaxLevel({ id = "t2", maxCount = 5, extraCountOffset = 0,
    countPerLevel = 1, maxLevel = 20 }), 5)

-- ─── Un maximo con decimales ────────────────────────────────────────────────
-- No se regala medio nivel: 3.7 son 3.
print("Un maximo con decimales se trunca")
chk("3.7 son 3", D.GetMaxLevel({ id = "d", maxLevel = 3.7 }), 3)

-- ─── Coste en espacios de conjuro ───────────────────────────────────────────
-- Con el modo de espacios, el coste es un espacio del nivel elegido; con mana, su equivalente.
print("Coste en espacios de conjuro")
env.HarfordDnDMana = nil
local conjuro = { id = "c", spellLevelCost = "level", maxLevel = 5 }
local cc = D.GetCosts(conjuro, 3)
chk("un espacio del nivel elegido", cc[1] and cc[1].resource, "spell_slot")
chk("y del nivel 3", cc[1] and cc[1].amount, 3)
chk("nivel fijo en vez de escalado", (D.GetCosts({ id = "c2", spellLevelCost = 2 }, 5))[1].amount, 2)
-- Un nivel de conjuro 0 no cuesta espacio: los trucos son gratis.
chk("nivel 0 no cuesta espacio", #D.GetCosts({ id = "c3", spellLevelCost = 0 }, 1), 0)

print("Con mana, el mismo coste sale en mana")
env.HarfordDnDMana = {
    IsEnabled = function() return true end,
    GetSpellCost = function(nivel) return nivel * 2 end,
    CanSpendSpellSlot = function() return false end,
}
cc = D.GetCosts(conjuro, 3)
chk("ahora es mana", cc[1] and cc[1].resource, "mana")
chk("y cuesta lo que diga la tabla", cc[1] and cc[1].amount, 6)
env.HarfordDnDMana = nil

print("Sin espacio disponible no se puede pagar")
env.HarfordDnDMana = { IsEnabled = function() return false end,
    CanSpendSpellSlot = function() return false end }
chk("aunque el nivel exista", (D.CanPay(conjuro, 2)), false)
env.HarfordDnDMana = { IsEnabled = function() return false end,
    CanSpendSpellSlot = function() return true end }
chk("con espacio, si", (D.CanPay(conjuro, 2)), true)
env.HarfordDnDMana = nil

-- ─── El ciclo del boton ─────────────────────────────────────────────────────
-- Un solo boton hace tres cosas segun cuantas veces se pulse: encender al minimo, subir de nivel y
-- apagar al pasarse. Es el gesto que el jugador repite mas veces, y no lo comprobaba nadie.
print("Pulsar el boton: enciende, sube, y al pasarse apaga")
env.HarfordChat = { Print = function() end }
env.HarfordDnDStore.activeCondDamage = {}
env.HarfordDnDStore.condDamageLevel = {}
RECURSOS.rage = 10
local LISTA = { { id = "runic_strike", label = "Golpe Runico", resourceCost = "rage",
                  countPerLevel = 1, die = 6, maxLevel = 3 } }
env.HarfordDnDFeatureEffects = { GetConditionalDamage = function() return LISTA end }

chk("empieza apagado", D.IsActive("runic_strike"), false)
D.Toggle("runic_strike")
chk("una pulsacion lo enciende", D.IsActive("runic_strike"), true)
chk("al nivel minimo", D.GetActiveLevel("runic_strike"), 1)
D.Toggle("runic_strike")
chk("otra sube a dos", D.GetActiveLevel("runic_strike"), 2)
D.Toggle("runic_strike")
chk("y a tres", D.GetActiveLevel("runic_strike"), 3)
D.Toggle("runic_strike")
chk("pasado el maximo, se apaga", D.IsActive("runic_strike"), false)
chk("y olvida el nivel", D.GetActiveLevel("runic_strike"), "nil")

-- Sin recursos no se puede encender, y si estaba encendido se cae solo.
print("Sin recursos no enciende")
RECURSOS.rage = 0
D.Toggle("runic_strike")
chk("no se enciende", D.IsActive("runic_strike"), false)

-- Uno de un solo nivel es un si/no, no un ciclo.
print("Uno de un solo nivel solo se enciende y se apaga")
LISTA = { { id = "simple", label = "Simple", die = 6, dice = 1 } }
env.HarfordDnDStore.activeCondDamage = {}
env.HarfordDnDStore.condDamageLevel = {}
D.Toggle("simple")
chk("encendido", D.IsActive("simple"), true)
D.Toggle("simple")
chk("apagado", D.IsActive("simple"), false)

-- ─── Texto de la opcion ─────────────────────────────────────────────────────
-- Es lo que se lee en el menu: dados, multiplicador y coste.
print("El texto del menu dice dados y coste")
LISTA = { { id = "runic_strike", label = "Golpe Runico", resourceCost = "rage",
            countPerLevel = 1, die = 6, maxLevel = 3 } }
RECURSOS.rage = 10
chk("un nivel", D.GetOptionText(LISTA[1], 1), "Golpe Runico x1 (1d6, 1 Ira)")
chk("dos niveles", D.GetOptionText(LISTA[1], 2), "Golpe Runico x2 (2d6, 2 Ira)")
-- Un dano fijo sin dados no escribe "0d6".
chk("solo bonus fijo", D.GetOptionText({ id = "f", label = "Fijo", flat = 2 }, 1), "Fijo (+2)")
chk("ni dados ni bonus, un guion", D.GetOptionText({ id = "n", label = "Nada" }, 1), "Nada (-)")
-- Un conjuro se lee por su nivel, no por un multiplicador.
chk("por nivel de conjuro",
    D.GetOptionText({ id = "c", label = "Conjuro", spellLevelCost = "level", countPerLevel = 1,
                      die = 8, maxLevel = 3 }, 2),
    "Conjuro nivel 2 (2d8, 2 espacio de nivel 2)")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
