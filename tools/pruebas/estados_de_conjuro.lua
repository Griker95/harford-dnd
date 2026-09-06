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

-- UNA categoria por nivel (trocearlas en hermanas "(1/4), (2/4)..." llenaba el menu en plano);
-- las largas se presentan PAGINADAS como submenus con el corte comun de PaginateCategory.
print("Una categoria por nivel; las largas se paginan como submenus")
local etiquetas = {}
for i = antesCat + 1, #API.CATEGORIES do etiquetas[#etiquetas + 1] = API.CATEGORIES[i].label end
chk("una categoria por nivel", table.concat(etiquetas, "|"),
    "Conjuros: trucos|Conjuros: nivel 1|Conjuros: nivel 2")
chk("GetDefinitionsForCategory resuelve las generadas",
    #API.GetDefinitionsForCategory(API.CATEGORIES[antesCat + 1].id), 1)
local paginas, defs2 = API.PaginateCategory("conjuros_2")
chk("nivel 2 (25) se pagina", paginas ~= nil and #paginas, 2)
chk("el corte reparte 22+3", (paginas[1].hasta - paginas[1].desde + 1) .. "+" .. (paginas[2].hasta - paginas[2].desde + 1), "22+3")
chk("la etiqueta orienta con iniciales", paginas[1].label, "Pagina 1/2 (B–B)")
chk("y devuelve las defs para no pedirlas dos veces", #defs2, 25)
chk("una corta NO se pagina", API.PaginateCategory("conjuros_1"), "nil")

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

-- LOS ESTADOS PROPIOS PERSISTEN ENTRE REINICIOS (peticion de mesa 2026-09-06): antes solo se
-- guardaban los marcados `persist` y un buff puesto se evaporaba al recargar. Se EJECUTA de
-- verdad: se aplica un estado de conjuro, se "reinicia" cargando el fichero OTRA VEZ con el
-- mismo SavedVariable, y el estado tiene que seguir puesto — lo que exige ademas que LoadOwned
-- genere las defs perezosas de conjuro al ver un `conjuro_*` guardado.
print("Un estado puesto sobrevive al reinicio")
local STORE = {}
local function NuevoEntorno()
    local e = setmetatable({
        HarfordDnDConditions = {}, ipairs = ipairs, pairs = pairs, table = table,
        tostring = tostring, tonumber = tonumber, math = math, string = string, type = type,
        select = select, unpack = unpack, setmetatable = setmetatable, next = next,
        error = error, assert = assert, print = function() end, pcall = pcall,
        HarfordCompendioAPI = { GetAllSpells = function() return SPELLS end },
        HarfordDnDPersistStore = STORE,
        GetTime = function() return 0 end, time = function() return 0 end,
        UnitName = function() return "Probador" end, UnitGUID = function() return "GUID-YO" end,
        HarfordClassColors = {
            UnitFullName = function() return "Probador" end,
            StripAccents = function(s) return s end,
            NormalizeKey = function(s) return tostring(s or ""):lower() end,
        },
    }, { __index = function() return nil end })
    e._G = e
    local g
    if setfenv then g = assert(cargar(src)); setfenv(g, e) else g = assert(cargar(src, "t", "t", e)) end
    pcall(g)
    return e.HarfordDnDConditions
end
local S1 = NuevoEntorno()
S1.EnsureSpellStates()
local okAplicar = S1.ApplyOwned("conjuro_luz", { expiresAt = 123 })
chk("se aplica", okAplicar, true)
chk("y queda guardado SIN necesitar marca persist",
    STORE.conditionStates and STORE.conditionStates.Probador
    and STORE.conditionStates.Probador.conjuro_luz ~= nil, true)
local S2 = NuevoEntorno()  -- "reinicio": defs de conjuro NO generadas aun
-- Como en el cliente real: el primer GetActive (la tira al entrar al mundo) dispara LoadOwned,
-- que al ver un `conjuro_*` guardado genera las defs perezosas.
S2.GetActive("player")
chk("tras reiniciar sigue puesto (y LoadOwned genero las defs)",
    S2.Has("player", "conjuro_luz"), true)
chk("el expiresAt de la sesion vieja se descarta",
    S2.State.units.player.conjuro_luz.expiresAt, "nil")

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
-- Ambos consumidores paginan con el corte comun: el engranaje anida submenus de pagina y el
-- menu DM viaja con "ESTADOS:cat#p" por su dispatcher de menuList.
chk("el engranaje pagina con el corte comun",
    uf:find("paginas, defs = C.PaginateCategory(cat.id)", 1, true) ~= nil, true)
chk("el menu DM tambien, via ESTADOS:cat#p",
    adm:find('AddSubmenu(pag.label, "ESTADOS:" .. tostring(categoryId) .. "#" .. p, level)', 1, true) ~= nil
    and adm:find('categoryId:match("^(.-)#(%d+)$")', 1, true) ~= nil, true)
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
-- La concentracion tambien sobrevive al /reload (revierte el diseno efimero inicial): al
-- entrar al mundo, `current` se reconstruye desde el registro persistido de `concentrando`
-- (el conjuro viaja en sourceName) con stateApplied para que el listener de divergencia siga
-- soltandola si el estado se retira a mano.
chk("la concentracion se restaura al entrar al mundo",
    conc:find('ev:RegisterEvent("PLAYER_ENTERING_WORLD")', 1, true) ~= nil
    and conc:find("stateApplied = true,", 1, true) ~= nil, true)
-- LANZAR un conjuro sostenido APLICA su estado (2026-09-06): en el objetivo al que apuntas —
-- CUALQUIER jugador o NPC, sin filtro UnitIsFriend (la faccion WoW no es dato de RP en
-- Epsilon; los requisitos del conjuro, como el alineamiento de Proteccion contra el bien y el
-- mal, los juzga la mesa) — o en ti. Solo la ruta de ANUNCIO de ConfirmCast (ataque y area
-- entran con silent y aplican su propia condicion). La fuente es el lanzador: el arrastre de
-- concentracion depende de ella.
local core = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
chk("ConfirmCast aplica el estado del conjuro al anunciar",
    core:find('local stateId = "conjuro_" .. tostring(spell.id)', 1, true) ~= nil
    and core:find('C.ApplyToUnit("target", stateId,', 1, true) ~= nil, true)
-- Sin filtro de faccion WoW (no es dato de RP en Epsilon); el UNICO filtro es el requisito de
-- ALINEAMIENTO declarado por conjuro (Proteccion contra el bien y el mal): se lee de la
-- cabecera del stat block TRP3 del NPC, sin acentos; con dato que no cumple NO se aplica a
-- NADIE (caer a ponertelo a ti seria inventarse otro objetivo) y se avisa; sin dato no se
-- bloquea. Los jugadores no se filtran: su alineamiento no viaja.
chk("sin filtro de faccion WoW",
    core:find("UnitIsFriend", 1, true) == nil, true)
chk("el requisito de alineamiento es declarativo",
    core:find('proteccion_contra_el_bien_y_el_mal = { "bueno", "buena", "malign", "malvad" },', 1, true) ~= nil, true)
chk("se lee del stat block TRP3 del NPC",
    core:find('local bloque = HarfordTRP3.GetNPCStatBlock("target")', 1, true) ~= nil
    and core:find("bloque and bloque.rawHeader", 1, true) ~= nil, true)
chk("con dato que no cumple, no se aplica a nadie",
    core:find("bloqueado = true", 1, true) ~= nil
    and core:find("if bloqueado then", 1, true) ~= nil, true)
chk("con el lanzador como fuente y publicandolo si es propio",
    core:find('{ duration = "manual", sourceGuid = miGuid, sourceName = miNombre })\n                        and C.PublishOwnedCondition then', 1, true) ~= nil, true)
chk("solo la ruta de anuncio (tras el corte de silent)",
    (core:find("if options and options.silent then return true, costOrErr", 1, true) or math.huge)
    < (core:find('local stateId = "conjuro_"', 1, true) or 0), true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
