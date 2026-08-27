-- HarfordDnDItems: el parser de la DESCRIPCION de un objeto.
--
-- Es el sitio con mas superficie sin cubrir del proyecto (1366 lineas, 8 de 8 mutaciones pasaban)
-- y con la regla mas delicada: solo una linea COMPLETA con etiqueta conocida y numero cuenta como
-- mecanica; todo lo demas es texto narrativo y no debe conceder nada.
--
-- Equivocarse aqui no da error: concede bonos que el objeto no da, o se traga los que si da.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- Se extrae el bloque del parser -- desde la tabla de etiquetas hasta el final de
-- `ParseTooltipRules` -- porque son funciones locales del modulo.
local src = io.open("Harford/DnD/State/HarfordDnDItems.lua"):read("*a")
-- Desde las tablas de alias, que estan justo encima y las usa el resolutor de etiquetas.
local ini = assert(src:find("local ABILITY_ALIASES = {", 1, true))
local fin = assert(src:find("local function ResolveCategory", ini, true))
local cuerpo = src:sub(ini, fin - 1)

local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable = setmetatable
-- El bloque extraido asigna a `API`, que es un local del modulo declarado mas arriba del corte.
-- Se le da uno de mentira para que esas asignaciones aterricen en algun sitio.
env.API = {}
env.HarfordClassColors = { StripAccents = function(v) return v end }
env.HarfordDnDWeapons = { WEAPONS = {
    { key = "Espada corta" }, { key = "Daga" }, { key = "Mandoble" },
} }

local cargar = loadstring or load
local f
local codigo = cuerpo .. "\nreturn ParseTooltipRules, NormalizeLabel, ResolveRuleLabel"
if setfenv then f = assert(cargar(codigo)); setfenv(f, env)
else f = assert(cargar(codigo, "t", "t", env)) end
local Parsear, Normalizar, ResolverEtiqueta = f()

local function reglas(...)
    local r = Parsear({ ... })
    return r
end
local function descripcion(...)
    local _, d = Parsear({ ... })
    return table.concat(d, " | ")
end

-- ─── Lo que SI es mecanica ──────────────────────────────────────────────────
print("Una linea completa con etiqueta y numero concede")
local r = reglas("Fuerza +2")
chk("caracteristica", r.ability and r.ability.Fuerza, 2)
r = reglas("Naturaleza +1")
chk("habilidad", r.skill and (r.skill.naturaleza or r.skill.Naturaleza), 1)
r = reglas("CA +1")
chk("clase de armadura", r.armorClass, 1)
r = reglas("Ataque +1")
chk("ataque con arma", r.weaponAttack, 1)
r = reglas("Dano +2")
chk("dano con arma", r.weaponDamage, 2)

-- El signo importa: un objeto maldito resta.
print("El signo se respeta")
chk("un menos resta", (reglas("Fuerza -1")).ability.Fuerza, -1)
chk("y no se lee como suma", (reglas("CA -2")).armorClass, -2)

-- La armadura declara su CA BASE, que no es un bonus: sustituye al 10 + Destreza.
print("La CA base de una armadura no es un bonus")
chk("Armadura 14", (reglas("Armadura 14")).armorBase, 14)
chk("y no cuenta como bonus", (reglas("Armadura 14")).armorClass, 0)
-- Con dos lineas de base se queda la MAYOR, no la ultima.
chk("dos bases, la mayor", (reglas("Armadura 12", "CA 16")).armorBase, 16)
chk("y da igual el orden", (reglas("CA 16", "Armadura 12")).armorBase, 16)
-- Pero esa CA base solo cuenta desde el PECHO. Se leia desde cualquier hueco, asi que un anillo,
-- una capa o unas botas con una linea "Armadura 14" en la descripcion fijaban tu CA entera. La
-- armadura del cuerpo es la que pone la CA base; lo de los demas huecos suma como bonus.
local items = io.open("Harford/DnD/State/HarfordDnDItems.lua"):read("*a")
-- Al sacar un item de la cache hay que sacarlo TAMBIEN de la lista de antiguedad. Sin eso quedaba
-- un enlace muerto ahi y, si el mismo item se volvia a resolver, se apuntaba otra vez --para el
-- era nuevo-- y acababa DOS veces: al desalojar, la primera copia borraba una entrada viva y la
-- segunda no liberaba nada.
chk("al soltar de la cache sale de la lista de antiguedad",
    items:find("if resolvedCacheOrder[i] == itemLink then table.remove(resolvedCacheOrder, i) end",
        1, true) ~= nil, true)
chk("la CA base solo cuenta desde el pecho",
    items:find('if slotKey == "Chest" and resolved.rules and resolved.rules.armorBase then',
        1, true) ~= nil, true)

-- ─── Lo que NO debe conceder nada ───────────────────────────────────────────
-- Esta es la regla que mas importa: el texto de sabor no puede dar bonos.
print("El texto narrativo no concede nada")
local narrativas = {
    "Forjada en las profundidades de Rasganorte.",
    "Perteneció a un capitán caído.",
    "Fuerza",                                  -- etiqueta sin numero
    "+2",                                      -- numero sin etiqueta
    "Da mucha fuerza al portador",             -- la palabra suelta dentro de una frase
    "Su fuerza es +2 veces la de un hombre",   -- etiqueta y numero, pero no la linea entera
    "Inventada +3",                            -- etiqueta desconocida
    -- Estas tres son INVENTADAS para la prueba, no salidas de ningun objeto real, y hacen falta
    -- por dos motivos.
    --
    -- El primero es tecnico: son las unicas que discriminan. Su prefijo SI es una etiqueta valida
    -- y el numero tambien, pero la linea CONTINUA, asi que solo el ancla final las rechaza. Con
    -- frases de etiqueta desconocida lo que protege es el catalogo, y la mutacion del ancla pasaba
    -- desapercibida -- se comprobo mutandola y viendo la suite en verde.
    --
    -- El segundo es de reglas, y es el que importa: son BONOS CONDICIONALES, y el addon no puede
    -- evaluar "bajo la luz de la luna" ni "contra no-muertos". La norma del proyecto es no
    -- convertir ventajas situacionales sin una capa mecanica explicita, asi que lo correcto es
    -- justo lo que hace: no conceder nada y dejarlo como texto para que lo aplique la mesa.
    -- Convertirlas en un +1 permanente seria peor que ignorarlas.
    "Fuerza +2 veces mas rapido que un hombre",
    "CA +1 solo bajo la luz de la luna",
    "Ataque +1 contra no-muertos unicamente",
    -- Y al reves: texto ANTES de la etiqueta. Estos NO discriminan el ancla inicial, y no es un
    -- hueco: con `(.-)` perezoso el patron ya casa desde la posicion 1 capturando "Otorga Fuerza"
    -- como etiqueta, que es desconocida. Quitar el `^` no cambia el resultado nunca. Se comprobo
    -- mutandolo. Se quedan porque la regla que afirman -- que no concedan -- sigue valiendo.
    "Otorga Fuerza +2",
    "El portador gana CA +1",
}
for _, linea in ipairs(narrativas) do
    local rr = Parsear({ linea })
    local total = (rr.armorClass or 0) + (rr.weaponAttack or 0) + (rr.weaponDamage or 0)
        + (rr.initiative or 0) + (rr.spellAttack or 0) + (rr.spellDC or 0)
    local caracteristicas = 0
    for _ in pairs(rr.ability or {}) do caracteristicas = caracteristicas + 1 end
    for _ in pairs(rr.skill or {}) do caracteristicas = caracteristicas + 1 end
    for _ in pairs(rr.save or {}) do caracteristicas = caracteristicas + 1 end
    chk('"' .. linea:sub(1, 40) .. '"', total + caracteristicas + (rr.armorBase and 1 or 0), 0)
end

-- Y lo que no concede tiene que quedar como DESCRIPCION: si desapareciera, el objeto perderia su
-- texto sin que nadie lo pidiera.
print("Lo que no concede se conserva como texto")
chk("una frase de sabor se conserva",
    descripcion("Forjada en Rasganorte."), "Forjada en Rasganorte.")
chk("y las lineas vacias no ensucian", descripcion("", "Algo.", ""), "Algo.")
-- Un bono condicional no se concede, pero TIENE que seguir leyendose: es lo unico que permite a la
-- mesa aplicarlo a mano. Perderlo seria peor que no interpretarlo.
chk("un bono condicional se conserva entero",
    descripcion("CA +1 solo bajo la luz de la luna"), "CA +1 solo bajo la luz de la luna")

-- ─── Varias lineas juntas ───────────────────────────────────────────────────
print("Varias reglas en el mismo objeto se acumulan")
r = reglas("Fuerza +2", "CA +1", "Ataque +1", "Un mandoble antiguo.")
chk("la caracteristica", r.ability.Fuerza, 2)
chk("la CA", r.armorClass, 1)
chk("el ataque", r.weaponAttack, 1)
chk("y el texto sobrevive",
    descripcion("Fuerza +2", "Un mandoble antiguo."), "Un mandoble antiguo.")
-- Dos lineas del mismo bonus se SUMAN, no se pisan.
chk("dos veces la misma, se suman", (reglas("CA +1", "CA +2")).armorClass, 3)

-- ─── Dano extra ─────────────────────────────────────────────────────────────
print("Dano extra con su tipo")
r = reglas("Dano extra 1d6 fuego")
chk("hay un componente", #(r.extraDamage or {}), 1)
chk("con sus dados", r.extraDamage[1] and r.extraDamage[1].dice, "1d6")
chk("y su tipo", r.extraDamage[1] and r.extraDamage[1].damageType, "fuego")

-- ─── Tipo de arma declarado ─────────────────────────────────────────────────
-- "Arma: Espada corta" fija el tipo D&D por encima de la subclase de WoW, y consume la linea.
print("El tipo de arma se puede declarar")
chk("con prefijo Arma:", (reglas("Arma: Espada corta")).weaponOverride, "Espada corta")
chk("y con Tipo de arma:", (reglas("Tipo de arma: Daga")).weaponOverride, "Daga")
chk("un arma inventada no fija nada", (reglas("Arma: Bastardo galactico")).weaponOverride, "nil")

-- ─── Normalizacion de etiquetas ─────────────────────────────────────────────
-- Sin esto, "C.A." o "Ca" no casarian con "CA" y el objeto perderia su armadura.
print("Las etiquetas se normalizan antes de compararse")
chk("mayusculas", Normalizar("CA"), Normalizar("ca"))
chk("con espacios", Normalizar(" CA "), Normalizar("CA"))
chk("y con puntos", Normalizar("C.A."), Normalizar("CA"))

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
