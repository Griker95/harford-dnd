-- ACCIONES BASICAS y su coste.
--
-- Lo que es accion es accion y lo que es adicional es adicional. Pero si una clase abre una accion
-- como adicional (Accion Astuta del Picaro, Paso del Viento del Monje), el boton debe ofrecer LAS
-- DOS y que elija el jugador.
--
-- El rasgo no duplica la accion: la REFERENCIA por id. Duplicarla seria garantizar que el dia que
-- cambie una haya dos versiones y solo se actualice una.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Data/HarfordDnDActions.lua"):read("*a")
local env = { string = string, table = table, pairs = pairs, ipairs = ipairs, tonumber = tonumber,
              tostring = tostring, type = type, HarfordDnDActions = nil }
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
f()
local A = env.HarfordDnDActions

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-30s %s", etiqueta, "'" .. tostring(real) .. "'",
        ok and "ok" or ("FALLA, esperaba '" .. tostring(esp) .. "'")))
end
local function costes(id, rasgos)
    local out = {}
    for _, c in ipairs(A.CostsFor(id, rasgos)) do out[#out + 1] = c.cast end
    return table.concat(out, ",")
end

print("El catalogo, en el orden del manual y no alfabetico")
local orden = {}
for _, d in ipairs(A.GetOrdered()) do orden[#orden + 1] = d.id end
chk("orden", table.concat(orden, ","),
    "esquivar,correr,desengancharse,esconderse,agarrar,empujar,ayudar,estabilizar,lanzar_arma,preparar")

print("Sin rasgos que la abran, solo su coste base")
chk("esquivar", costes("esquivar", {}), "accion")
chk("esconderse", costes("esconderse", {}), "accion")

local astuta = { name = "Accion astuta", grantsAsBonus = { "correr", "desengancharse", "esconderse" } }
print("Accion Astuta abre tres de ellas como adicional")
chk("esconderse", costes("esconderse", { astuta }), "accion,accion_adicional")
chk("correr", costes("correr", { astuta }), "accion,accion_adicional")
chk("desengancharse", costes("desengancharse", { astuta }), "accion,accion_adicional")
chk("esquivar NO: no la abre", costes("esquivar", { astuta }), "accion")

print("El recurso lo pone el RASGO que abre, no la accion")
local paso = { name = "Paso del Viento", resourceKey = "chi", resourceCost = 1,
               grantsAsBonus = { "correr", "desengancharse" } }
local c = A.CostsFor("correr", { paso })
chk("dos costes", #c, 2)
chk("el base no cuesta recurso", tostring(c[1].resourceKey), "nil")
chk("el abierto si", c[2].resourceKey, "chi")
chk("y dice por que rasgo", c[2].porRasgo, "Paso del Viento")

print("Dos rasgos que abren lo mismo no duplican la opcion")
chk("una sola vez", costes("correr", { astuta, paso }), "accion,accion_adicional")

print("Una accion que no existe no inventa costes")
chk("vacio", costes("volar", { astuta }), "")

print("Lo que NO tiene efecto lo dice, en vez de fingirlo")
chk("correr", A.Get("correr").sinEfecto ~= nil, true)
chk("desengancharse", A.Get("desengancharse").sinEfecto ~= nil, true)
chk("esquivar si tiene efecto", A.Get("esquivar").selfCondition.id, "esquivando")
chk("esconderse tira Sigilo", A.Get("esconderse").skillCheck.skill, "Sigilo")
-- Sin CD: la de esconderse es la Percepcion pasiva de quien mira, que este cliente no conoce.
chk("y sin CD, que no la sabemos", tostring(A.Get("esconderse").skillCheck.dc), "nil")
-- Estabilizar es la unica de las nuevas con CD fija en el manual.
chk("estabilizar: Medicina", A.Get("estabilizar").skillCheck.skill, "Medicina")
chk("estabilizar: CD 10", A.Get("estabilizar").skillCheck.dc, 10)
-- Agarrar y Empujar se resuelven por tirada enfrentada (ver `tirada_enfrentada`), asi que ya no
-- son narrativas. Una accion tiene UNA forma de resolverse: declarar las dos seria contradecirse.
print("Las que se resuelven por contienda no declaran ademas que no hacen nada")
for _, id in ipairs({ "agarrar", "empujar" }) do
    chk(id .. ": contienda", type(A.Get(id).contest), "table")
    chk(id .. ": sin nota de narrativa", A.Get(id).sinEfecto, "nil")
end

-- Ayudar, Lanzar arma y Preparar ya se resuelven (ver `ayudar_preparar_lanzar`). Solo Correr y
-- Desengancharse siguen siendo narrativas, y por una razon declarada: el addon no lleva
-- presupuesto de movimiento ni ataques de oportunidad.
print("Ya no queda ninguna accion narrativa por accidente")
for _, id in ipairs({ "ayudar", "lanzar_arma", "preparar" }) do
    chk(id .. ": se resuelve", A.Get(id).sinEfecto, "nil")
end
local narrativas = 0
for _, def in ipairs(A.GetOrdered()) do
    if def.sinEfecto then narrativas = narrativas + 1 end
end
chk("solo Correr y Desengancharse", narrativas, 2)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
