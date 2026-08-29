-- Los COSTES de las opciones son datos, no parte del nombre.
--
-- Estaban escritos dentro de la etiqueta: "Brebaje Fortificante (1 chi)". Asi el motor no los podia
-- cobrar, el Libro no los podia mostrar como recurso y el catalogo de iconos no casaba por nombre.
-- Esta suite lee los ficheros de clase REALES y comprueba que no vuelvan a colarse ahi.
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local CLASES = { "Brujo","CaballerodelaMuerte","Cazador","CazadordeDemonios","Chaman","Druida",
                 "Guerrero","Mago","Monje","Paladin","Picaro","Sacerdote" }
local conCoste, sinDeclarar, total = 0, 0, 0
local ejemplos = {}
for _, cl in ipairs(CLASES) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    if fh then
        local s = fh:read("*a"); fh:close()
        for cabeza, lab, resto in s:gmatch('{ id = "[a-z_0-9]+", label = "([^"]*)()"([^\n]*)') do end
        for lab, resto in s:gmatch('{ id = "[a-z_0-9]+", label = "([^"]+)"([^\n]*)') do
            total = total + 1
            -- Un coste dentro del NOMBRE: "(2 chi)", "(3 puntos)".
            if lab:lower():match("%(%s*%d+%s*chi%s*%)") or lab:lower():match("%(%s*%d+%s*puntos?%s*%)") then
                conCoste = conCoste + 1
                ejemplos[#ejemplos + 1] = cl .. ": " .. lab
            end
            -- Si el TEXTO dice que gasta N de un recurso, deberia declararlo.
            if resto:match("resourceCost") == nil and resto:match('desc = "[^"]*[Gg]astas %d+ punto') then
                sinDeclarar = sinDeclarar + 1
            end
        end
    end
end
print("Etiquetas de opcion revisadas: " .. total)
chk("ninguna lleva el coste dentro del nombre", conCoste, 0)
for i = 1, math.min(#ejemplos, 5) do print("     sobra: " .. ejemplos[i]) end
chk("ninguna dice 'gastas N puntos' sin declararlo", sinDeclarar, 0)

-- Un `castsSpell` que apunte a un conjuro inexistente no da error: el rasgo simplemente no hace
-- nada al pulsarlo. Se comprueba contra los datos REALES del compendio.
print("Rasgos que lanzan un conjuro del compendio")
local compendio = io.open("HarfordCompendio/HarfordCompendio.lua")
local datos = compendio and compendio:read("*a") or ""
if compendio then compendio:close() end
local revisados, huerfanos = 0, {}
for _, cl in ipairs(CLASES) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    local src = fh and fh:read("*a") or ""
    if fh then fh:close() end
    for id in src:gmatch('castsSpell = "([a-z_0-9]+)"') do
        revisados = revisados + 1
        if not datos:find('id = "' .. id .. '"', 1, true) then
            huerfanos[#huerfanos + 1] = id
        end
    end
end
print("  referencias a conjuro revisadas: " .. revisados)
for _, id in ipairs(huerfanos) do print("     no existe en el compendio: " .. id) end
chk("todas apuntan a un conjuro que existe", #huerfanos, 0)


-- Un `conditionId` que no exista en el catalogo hace que el motor rechace el area entera con
-- "Condicion de area desconocida", asi que el rasgo deja de funcionar del todo.
print("Condiciones referidas por los datos de clase")
local fh = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua")
local motor = fh and fh:read("*a") or ""
if fh then fh:close() end
local condRevisadas, condHuerfanas = 0, {}
local vistas = {}
for _, cl in ipairs(CLASES) do
    local f2 = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    local src = f2 and f2:read("*a") or ""
    if f2 then f2:close() end
    -- Tres formas de nombrar una condicion: en un area (`conditionId`), en un estado propio
    -- (`selfCondition`) y en una carga que se lleva encima (`carriedCharge`). Las tres tienen que
    -- apuntar al catalogo.
    local nombradas = {}
    for id in src:gmatch('conditionId = "([a-z_0-9]+)"') do nombradas[#nombradas + 1] = id end
    for id in src:gmatch('selfCondition = %{ id = "([a-z_0-9]+)"') do nombradas[#nombradas + 1] = id end
    for id in src:gmatch('carriedCharge = %{ condition = "([a-z_0-9]+)"') do nombradas[#nombradas + 1] = id end
    for _, id in ipairs(nombradas) do
        if not vistas[id] then
            vistas[id] = true
            condRevisadas = condRevisadas + 1
            if not motor:find("    " .. id .. " = {", 1, true) then
                condHuerfanas[#condHuerfanas + 1] = id
            end
        end
    end
end
print("  condiciones distintas revisadas: " .. condRevisadas)
for _, id in ipairs(condHuerfanas) do print("     no esta en el catalogo: " .. id) end
chk("todas existen en el catalogo", #condHuerfanas, 0)



-- ─── EL SELECTOR DE IDIOMA NO OFRECE LOS YA CONOCIDOS ───────────────────────
-- "Un idioma adicional de tu eleccion" ofrecia Comun y Goblin al propio Goblin. El dialogo
-- filtra con DraftLanguages (mismos origenes que las competencias del borrador; en subida sin
-- borrador, los idiomas vivos del perfil) y nunca se queda vacio.
print("El selector de idioma filtra los conocidos")
local adv = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")
chk("el dialogo filtra por optionsFrom language",
    adv:find('== "language"', 1, true) ~= nil and adv:find("Draft.DraftLanguages", 1, true) ~= nil, true)
chk("y no se queda vacio", adv:find("if #nuevas > 0 then options = nuevas end", 1, true) ~= nil, true)
local draft = io.open("Harford/Character/HarfordCharacterDraft.lua"):read("*a")
chk("DraftLanguages recorre los mismos origenes que las competencias",
    draft:find("local function DraftLanguages(excludeFeatureId)", 1, true) ~= nil, true)
chk("y solo mezcla el perfil vivo SIN borrador de origen (re-crear no filtra con la ficha vieja)",
    draft:find("if not S.raceId and HarfordDnDFeatureEffects", 1, true) ~= nil, true)
-- Y no solo idiomas: el filtro es GENERICO (habilidades ya competentes, dotes/trucos ya tomados
-- en otra eleccion), excluye lo marcado en la eleccion ABIERTA (debe poder desmarcarse) y deja
-- en paz las apilables.
chk("el filtro cubre competencias de habilidad",
    adv:find('e.kind == "skillProf" and e.skill and habilidades[e.skill]', 1, true) ~= nil, true)
chk("y dotes/trucos repetidos entre elecciones",
    adv:find('(option.feat or id:find("^truco_")) and elegidosOtra[id]', 1, true) ~= nil, true)
chk("la eleccion abierta se excluye del computo",
    adv:find("Draft.DraftLanguages(feature.id)", 1, true) ~= nil
    and adv:find("Draft.DraftSkillProficiencies(feature.id)", 1, true) ~= nil, true)
chk("las apilables no se filtran",
    adv:find("if not IsStackableChoice(feature) and Draft.DraftLanguages", 1, true) ~= nil, true)
chk("el draft sabe excluir una eleccion",
    draft:find("if excludeFeatureId and feature.id == excludeFeatureId then return end", 1, true) ~= nil, true)



-- ─── LAS CATEGORIAS DE HERRAMIENTA SE ELIGEN POR MIEMBRO CONCRETO ───────────
-- "Instrumento musical" y "Juego" son categorias: el selector lista laud, flauta, dados... y no
-- la categoria entera. Un perfil viejo que eligio la categoria sigue resolviendo (fallback).
print("Instrumento y juego se expanden a miembros concretos")
local datos = io.open("Harford/DnD/Data/HarfordDnDData.lua"):read("*a")
chk("hay instrumentos concretos en TOOLS", datos:find('instrumento=true', 1, true) ~= nil, true)
chk("y juegos concretos", datos:find('juego=true', 1, true) ~= nil, true)
local libroSrc = io.open("Harford/DnD/Data/HarfordDnDBook.lua"):read("*a")
chk("las opciones literales expanden la categoria",
    libroSrc:find('o.id == "her_instrumento" or o.id == "her_juego"', 1, true) ~= nil, true)
chk("artisanTool lista instrumentos, no la categoria",
    libroSrc:find("if tool.artisan or tool.instrumento then", 1, true) ~= nil, true)
chk("toolProf salta los marcadores de categoria",
    libroSrc:find("if not tool.categoria then", 1, true) ~= nil, true)
chk("la eleccion vieja de categoria sigue resolviendo",
    libroSrc:find('if optionId == "her_instrumento" then', 1, true) ~= nil, true)



-- ─── LOS REQUISITOS RACIALES SE APLICAN, NO SOLO SE ESCRIBEN ────────────────
print("Dotes raciales y Sacerdocio de Elune se filtran por raza")
local feats = io.open("Harford/DnD/Data/HarfordDnDFeats.lua"):read("*a")
chk("hay validador estructurado", feats:find("function API.RaceAllowed(featDef, raceId, subraceId)", 1, true) ~= nil, true)
chk("las 13 dotes raciales llevan requiredRaces",
    (function() local n = 0 for _ in feats:gmatch("requiredRaces = {") do n = n + 1 end return n end)(), 13)
local advSrc = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")
chk("el dialogo de dotes filtra por raza",
    advSrc:find("ok = HarfordDnDFeats.RaceAllowed(def, razaId, subrazaId)", 1, true) ~= nil, true)
chk("las tarjetas de subclase tambien",
    advSrc:find("if not sub.requiredRace or razaId ==", 1, true) ~= nil, true)
local progSrc = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("y el runtime respeta requiredRaces con subraza",
    progSrc:find('tostring(id) == tostring(data.race.subraceId or "")', 1, true) ~= nil, true)
-- Y los prerequisitos de CARACTERISTICA: campo estructurado + validador "una de la lista llega
-- al minimo" + filtro en el dialogo con la puntuacion del borrador (creacion) o de la ficha
-- viva (subida).
chk("las 5 dotes con prerequisito de caracteristica lo llevan estructurado",
    (function() local n = 0 for _ in feats:gmatch("requiredAbility = {") do n = n + 1 end return n end)(), 5)
chk("el validador acepta cualquiera de la lista",
    feats:find("function API.AbilityAllowed(featDef, scoreFn)", 1, true) ~= nil, true)
chk("y el dialogo lo usa con la puntuacion que toca",
    advSrc:find("ok = HarfordDnDFeats.AbilityAllowed(def, Puntuacion)", 1, true) ~= nil
    and advSrc:find("local base = BaseScoreFor and tonumber(BaseScoreFor(clave)) or 0", 1, true) ~= nil, true)

-- El validador de verdad, ejecutado con stubs:
do
    local cargar = loadstring or load
    local src = feats
    local i = src:find("function API.AbilityAllowed", 1, true)
    local j = src:find("\nend", i)
    local envA = { ipairs = ipairs, type = type, tonumber = tonumber }
    local f = cargar("local API = {}\n" .. src:sub(i, j + 4) .. "\nreturn API.AbilityAllowed")
    if setfenv then setfenv(f, envA) end
    local AbilityAllowed = f()
    local dote = { requiredAbility = { abilities = { "Inteligencia", "Sabiduria" }, min = 13 } }
    chk("INT 14 pasa", AbilityAllowed(dote, function(k) return k == "Inteligencia" and 14 or 8 end), true)
    chk("SAB 13 justo pasa", AbilityAllowed(dote, function(k) return k == "Sabiduria" and 13 or 8 end), true)
    chk("ninguna al minimo NO pasa", AbilityAllowed(dote, function() return 12 end), false)
    chk("sin requisito siempre pasa", AbilityAllowed({}, function() return 1 end), true)
end

-- Y los de COMPETENCIA: armadura por token, arma por token; escudo no vale como armadura.
print("Prerequisitos de competencia validados de verdad")
chk("las 5 dotes con prerequisito de competencia lo llevan estructurado",
    (function() local n = 0 for _ in feats:gmatch("requiredProficiency = {") do n = n + 1 end return n end)(), 5)
do
    local cargar = loadstring or load
    local i = feats:find("function API.ProficiencyAllowed", 1, true)
    local j = feats:find(string.char(10) .. "end", i)
    local f = cargar("local API = {}" .. string.char(10) .. feats:sub(i, j + 4)
        .. string.char(10) .. "return API.ProficiencyAllowed")
    local ProficiencyAllowed = f()
    local media = { requiredProficiency = { armor = "media" } }
    chk("con la armadura, pasa", ProficiencyAllowed(media, { armor = { media = true }, weapon = {} }), true)
    chk("sin ella, no", ProficiencyAllowed(media, { armor = { ligera = true }, weapon = {} }), false)
    local marcial = { requiredProficiency = { weapon = "marciales" } }
    chk("arma marcial pasa", ProficiencyAllowed(marcial, { armor = {}, weapon = { marciales = true } }), true)
    chk("solo sencillas no", ProficiencyAllowed(marcial, { armor = {}, weapon = { sencillas = true } }), false)
end
chk("el dialogo filtra tambien por competencia",
    advSrc:find("ok = HarfordDnDFeats.ProficiencyAllowed(def, profsCache)", 1, true) ~= nil, true)
local draftSrc2 = io.open("Harford/Character/HarfordCharacterDraft.lua"):read("*a")
chk("el borrador agrega armorProfs y weaponProfs de las clases",
    draftSrc2:find("for _, a in ipairs(classDef.armorProfs or {}) do", 1, true) ~= nil, true)

-- Y los de LANZADOR: "any" acepta magia racial, "class" exige rasgo de clase (medio desde
-- nivel 2, tercio desde 3, pacto y completo desde 1).
print("Prerequisitos de lanzador validados")
chk("las 6 dotes de lanzador lo llevan estructurado",
    (function() local n = 0 for _ in feats:gmatch('requiredCaster = "') do n = n + 1 end return n end)(), 6)
do
    local cargar = loadstring or load
    local i = feats:find("function API.CasterAllowed", 1, true)
    local j = feats:find(string.char(10) .. "end", i)
    local f = cargar("local API = {}" .. string.char(10) .. feats:sub(i, j + 4)
        .. string.char(10) .. "return API.CasterAllowed")
    local CasterAllowed = f()
    local anyF = { requiredCaster = "any" }
    local classF = { requiredCaster = "class" }
    chk("magia racial vale para any", CasterAllowed(anyF, { class = false, any = true }), true)
    chk("pero NO para class", CasterAllowed(classF, { class = false, any = true }), false)
    chk("lanzador de clase vale para ambos", CasterAllowed(classF, { class = true, any = true }), true)
    chk("mundano no vale para any", CasterAllowed(anyF, { class = false, any = false }), false)
    chk("sin requisito siempre pasa", CasterAllowed({}, { class = false, any = false }), true)
end
chk("el dialogo filtra por lanzador",
    advSrc:find("ok = HarfordDnDFeats.CasterAllowed(def, casterCache or {})", 1, true) ~= nil, true)
chk("con las puertas de nivel del medio y el tercio",
    draftSrc2:find('elseif ct == "half" then', 1, true) ~= nil
    and draftSrc2:find('elseif ct == "third" then', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
