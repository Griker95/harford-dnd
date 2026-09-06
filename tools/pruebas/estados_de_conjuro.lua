-- ESTADOS DE CONJURO (peticion de mesa 2026-09-06).
--
-- TODO conjuro del compendio con duracion sostenida (no instantanea) existe como estado del
-- catalogo, con EL MISMO icono del conjuro y categorias propias por nivel en los menus. Se
-- generan PEREZOSOS porque los datos viven en el addon LoadOnDemand HarfordCompendio: la
-- generacion corre al abrir un menu de estados o al recibir por red un `conjuro_*` desconocido.
-- Y la CONCENTRACION arrastra: al romperse, cae tambien el estado del conjuro mantenido.
--
-- Esto se EJECUTA con un compendio falso, no se busca en el texto: la generacion tiene
-- suficientes piezas (filtro, orden, troceo, ORDER) como para que un literal no demuestre nada.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")

-- Compendio FALSO: dos sostenidos (un truco y un nivel 1 con concentracion), un instantaneo
-- que NO debe generar estado, y 25 de nivel 2 para forzar el troceo de categorias.
local SPELLS = {
    { id = "proteccion_bm", name = "Proteccion contra el bien y el mal", level = 1,
      duration = "10 minutos", concentration = true, icon = 135945,
      mechanics = "Ciertas criaturas te atacan con desventaja." },
    { id = "luz", name = "Luz", level = 0, duration = "1 hora", concentration = false, icon = 135922 },
    { id = "toque", name = "Toque", level = 0, duration = "Instantáneo", concentration = false, icon = 1 },
}
for i = 1, 25 do
    SPELLS[#SPELLS + 1] = { id = "buff" .. i, name = string.format("Buff %02d", i), level = 2,
        duration = "1 minuto", concentration = false, icon = 1000 + i }
end

local env = setmetatable({
    HarfordDnDConditions = {}, ipairs = ipairs, pairs = pairs, table = table,
    tostring = tostring, tonumber = tonumber, math = math, string = string, type = type,
    select = select, unpack = unpack, setmetatable = setmetatable, next = next,
    error = error, assert = assert, print = function() end, pcall = pcall,
    HarfordCompendioAPI = { GetAllSpells = function() return SPELLS end },
}, { __index = function() return nil end })
env._G = env
local cargar = loadstring or load
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
pcall(f)
local API = env.HarfordDnDConditions

print("La generacion existe y filtra por duracion sostenida")
chk("el motor cargo", API.EnsureSpellStates ~= nil, true)
local antesOrden, antesCat = #API.ORDER, #API.CATEGORIES
chk("genera", API.EnsureSpellStates(), true)
chk("27 sostenidos entran en ORDER (recorribles)", #API.ORDER - antesOrden, 27)
chk("el instantaneo NO genera estado", API.DEFS.conjuro_toque, "nil")

print("La def hereda el conjuro")
chk("label = nombre del conjuro", API.DEFS.conjuro_proteccion_bm.label, "Proteccion contra el bien y el mal")
chk("icono = el del conjuro (FileDataID)", API.DEFS.conjuro_proteccion_bm.spellIcon, 135945)
chk("GetIcon lo devuelve tal cual", API.GetIcon("conjuro_proteccion_bm"), 135945)
chk("concentracion marcada", API.DEFS.conjuro_proteccion_bm.concentration, true)
chk("la descripcion dice duracion y concentracion",
    API.DEFS.conjuro_proteccion_bm.description:find("10 minutos (Concentracion)", 1, true) ~= nil, true)

print("Categorias por nivel, troceadas para que el submenu quepa")
local etiquetas = {}
for i = antesCat + 1, #API.CATEGORIES do etiquetas[#etiquetas + 1] = API.CATEGORIES[i].label end
chk("trucos y nivel 1 en categoria propia", table.concat(etiquetas, "|"),
    "Conjuros: trucos|Conjuros: nivel 1|Conjuros: nivel 2 (1/2)|Conjuros: nivel 2 (2/2)")
chk("el troceo reparte 22+3", #API.CATEGORIES[antesCat + 3].ids .. "+" .. #API.CATEGORIES[antesCat + 4].ids, "22+3")
chk("GetDefinitionsForCategory resuelve las generadas",
    #API.GetDefinitionsForCategory(API.CATEGORIES[antesCat + 1].id), 1)

print("Idempotente y estable")
API.EnsureSpellStates()
chk("repetir no anade nada", #API.ORDER - antesOrden, 27)
chk("los trucos van antes que nivel 1 en ORDER",
    (function()
        local a, b
        for i, id in ipairs(API.ORDER) do
            if id == "conjuro_luz" then a = i end
            if id == "conjuro_proteccion_bm" then b = i end
        end
        return a < b
    end)(), true)

-- UN ESTADO DE CONJURO PUESTO SOBRE OTROS cae cuando su LANZADOR pierde la concentracion.
-- Cada cliente barre lo suyo al recibir el remove de `concentrando`: sus estados propios cuya
-- FUENTE sea quien rompio, y los registros cacheados sobre NPCs con esa fuente. El filtro por
-- fuente es obligatorio (puedes llevar la Bendicion del mago Y tu propia concentracion), y un
-- estado sin fuente (declarado a mano) no se toca. Se EJECUTA sembrando registros.
print("Perder la concentracion arrastra lo puesto sobre otros, solo lo de esa fuente")
API.State.units.player = API.State.units.player or {}
API.State.units.player.conjuro_proteccion_bm = { sourceGuid = "GUID-MAGO", sourceName = "Mago" }
API.State.units.player.conjuro_buff1 = { sourceGuid = "GUID-OTRO", sourceName = "Otra" }
API.State.units["npc-123"] = { conjuro_proteccion_bm = { sourceGuid = "GUID-MAGO" } }
-- buff1 NO es de concentracion: aunque la fuente casara, no debe caer.
API.State.units.player.conjuro_buff2 = { sourceGuid = "GUID-MAGO", sourceName = "Mago" }
API.OnConcentrationBroken("GUID-MAGO", "Mago")
chk("cae el del mago sobre mi", API.State.units.player and API.State.units.player.conjuro_proteccion_bm, "nil")
chk("cae el del mago sobre el NPC registrado", API.State.units["npc-123"], "nil")
chk("NO cae el de otra fuente", API.State.units.player.conjuro_buff1 ~= nil, true)
chk("NO cae uno sin concentracion aunque case la fuente", API.State.units.player.conjuro_buff2 ~= nil, true)

-- Los puntos de ENTRADA de la generacion perezosa y el arrastre de la concentracion se fijan
-- por texto: son enganches de una linea en modulos que la suite no puede ejecutar entera.
print("Enganches: menus, red y concentracion")
local uf = io.open("Harford/Frames/HarfordUnitFrames.lua"):read("*a")
local adm = io.open("HarfordAdmin/HarfordAdminUnitMenu.lua"):read("*a")
local conc = io.open("Harford/DnD/Engine/HarfordDnDConcentration.lua"):read("*a")
chk("el engranaje genera al abrir su menu",
    uf:find("if C.EnsureSpellStates then C.EnsureSpellStates() end", 1, true) ~= nil, true)
chk("el menu DM tambien",
    adm:find("HarfordDnDConditions.EnsureSpellStates()", 1, true) ~= nil, true)
chk("el receptor de red genera ante un conjuro_ desconocido",
    src:find('if cid:find("^conjuro_") and not API.DEFS[cid] and API.EnsureSpellStates then', 1, true) ~= nil, true)
-- Romper la concentracion retira TODO estado de conjuro marcado `concentration` (solo puedes
-- concentrarte en uno) y publica la retirada para el resto de clientes.
chk("Break retira el estado del conjuro mantenido",
    conc:find("if activo.definition and activo.definition.concentration then", 1, true) ~= nil
    and conc:find('HarfordDnDConditions.PublishOwnedCondition(activo.id, "remove")', 1, true) ~= nil, true)
-- El remove de `concentrando` ES la senal para los receptores: Begin publica el apply y Break
-- el remove; el receptor de DNDCONDSTATE dispara OnConcentrationBroken con la fuente, y el
-- lanzador hace ademas su barrido local (NPCs registrados en su cliente).
chk("Begin publica concentrando",
    conc:find('HarfordDnDConditions.PublishOwnedCondition("concentrando", "apply")', 1, true) ~= nil, true)
chk("Break publica el remove que dispara a los receptores",
    conc:find('HarfordDnDConditions.PublishOwnedCondition("concentrando", "remove")', 1, true) ~= nil, true)
chk("el receptor barre al ver el remove",
    src:find('if state.op == "remove" and cid == "concentrando" and API.OnConcentrationBroken then', 1, true) ~= nil, true)
chk("y el lanzador barre sus registros locales",
    conc:find("HarfordDnDConditions.OnConcentrationBroken(", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
