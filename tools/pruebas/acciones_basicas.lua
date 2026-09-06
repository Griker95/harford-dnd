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
-- `trabado_melee` (Flanqueado) fue RETIRADO del catalogo (2026-09-06): el estado `trabado` se
-- pone y quita desde el engranaje del unitframe propio, y la fila del Libro duplicaba el gesto.
chk("orden", table.concat(orden, ","),
    "esquivar,correr,desengancharse,esconderse,agarrar,empujar,ayudar,estabilizar,lanzar_arma,preparar,ataque_oportunidad")

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
-- `Correr` YA tiene efecto: dobla el tope del contador de movimiento. Decia que se llevaba en
-- mesa "porque Harford no cuenta cuanto te queda por moverte", y eso dejo de ser cierto en cuanto
-- el contador supo su maximo.
chk("correr ya hace algo", A.Get("correr").dobleMovimiento, true)
chk("y ya no dice que no", A.Get("correr").sinEfecto, "nil")
-- Desengancharse tampoco imprime coletilla: la mesa ya sabe que las oportunidades son suyas
-- y la linea gris solo era ruido en el chat (retirada a peticion de mesa, 2026-08-29).
chk("desengancharse tampoco dice que no", A.Get("desengancharse").sinEfecto, "nil")
chk("esquivar si tiene efecto", A.Get("esquivar").selfCondition.id, "esquivando")
chk("esconderse tira Sigilo", A.Get("esconderse").skillCheck.skill, "Sigilo")
-- Sin CD: la de esconderse es la Percepcion pasiva de quien mira, que este cliente no conoce.
chk("y sin CD, que no la sabemos", tostring(A.Get("esconderse").skillCheck.dc), "nil")
-- Estabilizar es la unica de las nuevas con CD fija en el manual. El exito otorga ademas
-- 1 PG al objetivo (decision de mesa 2026-09-06): lo declara la accion (healOnSuccess) y lo
-- entrega la rama de skillCheck via EntregarAObjetivo, solo a jugadores — la vida de un NPC
-- la gestiona su ficha de DM.
chk("estabilizar: Medicina", A.Get("estabilizar").skillCheck.skill, "Medicina")
chk("estabilizar: CD 10", A.Get("estabilizar").skillCheck.dc, 10)
chk("estabilizar: 1 PG al exito", A.Get("estabilizar").skillCheck.healOnSuccess, 1)
-- Y SOLO sobre un objetivo a 0 PG (2026-09-06), comprobado ANTES de cobrar la accion: la vida
-- propia del recurso local, la de otro jugador de su cache sincronizada (mapa Res_health_Cur),
-- la del NPC de su vida real (1 de servidor = "a 0" de mesa). Sin dato no se bloquea.
chk("estabilizar: exige objetivo a 0", A.Get("estabilizar").skillCheck.requiresTargetAtZero, true)
-- Al usarla (pasadas las guardias) lanza la animacion de servidor `cas 211155` (primeros
-- auxilios), por el wrapper validado y con o sin exito en la tirada.
chk("estabilizar: animacion de servidor declarada", A.Get("estabilizar").skillCheck.castSpellId, 211155)
local panelG = io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a")
chk("la guardia corre antes de cobrar",
    (panelG:find("def.skillCheck.requiresTargetAtZero then", 1, true) or math.huge)
    < (panelG:find("if AnnounceAbility(anuncio", 1, true) or 0), true)
chk("y mira las tres fuentes de vida",
    panelG:find('vida = tonumber(GetResourceCurrent("health"))', 1, true) ~= nil
    and panelG:find("vida = tonumber(tbl.Res_health_Cur)", 1, true) ~= nil
    and panelG:find('vida = (hp <= 1) and 0 or hp', 1, true) ~= nil, true)
chk("y el ejecutor lanza el cast por el wrapper",
    panelG:find('HarfordEpsilonCommands.Send("cas " .. tostring(def.skillCheck.castSpellId)', 1, true) ~= nil, true)

-- Desengancharse deja su estado visible hasta el FIN de tu turno (2026-09-06): los ataques de
-- oportunidad siguen siendo de la mesa, pero la mesa VE quien esta desenganchado en la tira.
chk("desengancharse aplica su estado",
    A.Get("desengancharse").selfCondition.id .. "/" .. A.Get("desengancharse").selfCondition.duration,
    "desenganchado/source_turn_end")
local condsrc = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
chk("el estado existe en el catalogo", condsrc:find("\n    desenganchado = {", 1, true) ~= nil, true)
chk("en la categoria de combate", condsrc:find('"esquivando", "desenganchado", "escondido", "apartado"', 1, true) ~= nil, true)

-- Esconderse TIRA Sigilo y ademas deja el estado Escondido con su aura de servidor (8822):
-- el estado sobre uno mismo ya no es excluyente con la tirada en el ejecutor (bloque propio).
chk("esconderse tira Y deja estado",
    A.Get("esconderse").skillCheck.skill .. "/" .. A.Get("esconderse").selfCondition.id,
    "Sigilo/escondido")
chk("el estado lleva el aura de sigilo",
    condsrc:find('label = "Escondido", auraId = 8822, tracking = "aura_state",', 1, true) ~= nil, true)
chk("y el ejecutor aplica estado y tirada juntos",
    panelG:find("-- El estado sobre uno mismo NO es excluyente con la tirada: bloque propio, no rama.", 1, true) ~= nil, true)
local panelBA = io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a")
chk("la entrega existe y respeta al NPC",
    panelBA:find("if supera and def.skillCheck.healOnSuccess and EntregarAObjetivo", 1, true) ~= nil
    and panelBA:find('EntregarAObjetivo("health", def.skillCheck.healOnSuccess, def.name)', 1, true) ~= nil, true)
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
chk("ninguna accion lleva coletilla narrativa", narrativas, 0)

-- ─── TODA ACCION TIENE FORMA DE RESOLVERSE ──────────────────────────────────
-- La bateria en juego comprueba lo mismo, y se le habia quedado vieja la lista: Correr paso de
-- "se lleva en mesa" a doblar de verdad el tope del contador y salia en rojo. Aqui se fija para
-- que las dos listas no se separen otra vez.
print("Toda accion basica sabe resolverse")
local RUTAS = { "selfCondition", "skillCheck", "contest", "helpOther", "throwWeapon",
                "readyAction", "dobleMovimiento", "soloAnuncio", "opportunityAttack" }
for _, def in ipairs(A.GetOrdered()) do
    local tiene = false
    for _, k in ipairs(RUTAS) do if def[k] then tiene = true break end end
    chk("  " .. tostring(def.id), tiene, true)
end
local verif = io.open("HarfordDebug/HarfordDebugVerify.lua"):read("*a")
for _, k in ipairs(RUTAS) do
    chk("la bateria en juego mira " .. k, verif:find("def." .. k, 1, true) ~= nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))

-- GRACIA DE ELUNE abre Desengancharse, Esquivar y Esconderse como accion adicional, igual que la
-- Accion Astuta del Picaro, pero solo MIENTRAS DURA. Por eso el resolutor de costes acepta las dos
-- procedencias sin distinguirlas: lo que importa es que algo lo abra, no de donde viene.
print("Un coste alternativo puede venir de un rasgo o de una condicion")
local porCondicion = {
    { label = "Gracia de Elune", grantsAsBonus = { "desengancharse", "esquivar", "esconderse" } },
}
for _, id in ipairs({ "desengancharse", "esquivar", "esconderse" }) do
    local costes = A.CostsFor(id, porCondicion)
    chk(id .. ": dos costes", #costes, 2)
    chk(id .. ": el segundo es adicional", costes[2].cast, "accion_adicional")
    -- La condicion se llama `label`, el rasgo `name`: el resolutor lee el que haya.
    chk(id .. ": lo firma quien lo abre", costes[2].porRasgo, "Gracia de Elune")
end
chk("y no abre lo que no declara", #A.CostsFor("agarrar", porCondicion), 1)

local cond2 = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
chk("la condicion lo declara", cond2:find('elunes_grace = {.-grantsAsBonus = { "desengancharse", "esquivar", "esconderse" }') ~= nil, true)
local panel2 = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))
chk("y el panel las aporta", panel2:find('if type(activo.definition.grantsAsBonus) == "table" then', 1, true) ~= nil, true)
