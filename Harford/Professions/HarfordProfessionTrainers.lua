------------------------------------------------------------
-- HarfordProfessionTrainers - Entrenadores de profesion: quien ensena que receta y donde.
--
-- Un entrenador NO concede la profesion (eso sigue siendo competencia de herramienta o
-- decision del DM): es una TIENDA DE RECETAS, y cada uno cubre un RANGO de su profesion
-- (Aprendiz, Oficial, Experto, Artesano, Maestro).
--
-- DECLARAR UN ENTRENADOR PARA UN RANGO ES LO QUE CIERRA ESE RANGO: mientras nadie lo ensene,
-- sus recetas siguen viniendo con el nivel de habilidad como hasta ahora. En cuanto existe un
-- entrenador que las cubre, hay que aprenderlas de el. Una receta puede ademas traer
-- `trainer = "<id>"` para atarla a uno concreto al margen del rango.
--
-- DOBLE ORIGEN, igual que las misiones (HarfordQuestCatalog + DefineWorldQuest):
--   * CATALOGO hardcodeado (`D.TRAINERS`): la lista canonica. Sirve para que el libro pueda
--     decir "esta receta la ensena X en Y" ANTES de haber hablado nunca con ese NPC.
--   * REGISTRO EN VIVO (`API.Define`): un ArcSpell en el gossip del NPC se registra al hablar
--     con el. La identidad es el TEMPLATE ID del NPC, como en las misiones de mundo.
-- Lo registrado en vivo manda sobre el catalogo para ese mismo id: el mundo es la verdad.
--
-- Este modulo NO ejecuta comandos de servidor ni toca al NPC. Solo responde "quien ensena
-- esto" y "marcalo como aprendido"; colocar al NPC y darle su gossip es cosa del mundo.
------------------------------------------------------------

HarfordProfessionTrainers = HarfordProfessionTrainers or {}
local API = HarfordProfessionTrainers

-- entrenador: { id, name, npc = <templateId>, zone, profession, tier = "Aprendiz".."Maestro",
--               recipes? = { recipeId, ... } }
--
-- Lo normal es declarar `tier`: el entrenador ensena TODAS las recetas de su profesion cuyo
-- `skillReq` cae en ese rango, y la lista se deriva sola. Asi anadir recetas al catalogo no
-- obliga a tocar entrenadores. `recipes` es para casos sueltos (un plano concreto) y se suma a
-- lo que cubra el rango.
--
-- `npc` es opcional en el catalogo: un entrenador puede estar documentado antes de existir en
-- el mundo. Sin `npc` se puede consultar pero no ensenar.
API.TRAINERS = API.TRAINERS or {}

-- Registrados en vivo por el gossip del NPC. No se persisten: el mundo los vuelve a declarar.
local vivos = {}

local function Norm(v)
    local t = tostring(v or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        t = HarfordClassColors.StripAccents(t)
    end
    return t:lower()
end

-- Rango por nombre -> [minimo, maximo) de skillReq. El maximo es el minimo del rango siguiente,
-- asi que cada receta cae en uno y solo uno.
function API.GetTierRange(tierName)
    local tiers = HarfordProfessions and HarfordProfessions.TIERS
    if not tiers then return nil end
    local buscado = Norm(tierName)
    if buscado == "" then return nil end
    for i, t in ipairs(tiers) do
        if Norm(t.name) == buscado then
            local siguiente = tiers[i + 1]
            return t.min, siguiente and siguiente.min or math.huge, t.name
        end
    end
    return nil
end

-- ¿Este entrenador ensena esta receta? Por rango o por lista explicita.
function API.TrainerTeaches(def, recipe)
    if not (def and recipe) then return false end
    for _, id in ipairs(def.recipes or {}) do
        if Norm(id) == Norm(recipe.id) then return true end
    end
    if not def.tier then return false end
    if Norm(recipe.profession) ~= Norm(def.profession) then return false end
    local minimo, maximo = API.GetTierRange(def.tier)
    if not minimo then return false end
    local req = tonumber(recipe.skillReq) or 1
    return req >= minimo and req < maximo
end

-- Las recetas que cubre, ya resueltas. Util para la ficha del entrenador y para ver el alcance
-- de un rango antes de declararlo.
function API.GetRecipesFor(def)
    local out = {}
    if not (def and HarfordProfessions and HarfordProfessions.GetRecipes) then return out end
    for _, r in ipairs(HarfordProfessions.GetRecipes(def.profession) or {}) do
        if API.TrainerTeaches(def, r) then out[#out + 1] = r end
    end
    return out
end

------------------------------------------------------------
-- Consulta
------------------------------------------------------------

-- Todos los entrenadores conocidos: catalogo mas lo registrado en vivo, que tiene prioridad.
function API.GetAll()
    local out, vistos = {}, {}
    for _, def in pairs(vivos) do
        out[#out + 1] = def
        vistos[Norm(def.id)] = true
    end
    for _, def in ipairs(API.TRAINERS) do
        if not vistos[Norm(def.id)] then out[#out + 1] = def end
    end
    return out
end

function API.Get(trainerId)
    trainerId = Norm(trainerId)
    if trainerId == "" then return nil end
    for _, def in ipairs(API.GetAll()) do
        if Norm(def.id) == trainerId then return def end
    end
    return nil
end

-- Entrenador registrado para un NPC concreto (por template id).
function API.GetByNpc(templateId)
    templateId = tonumber(templateId)
    if not templateId then return nil end
    for _, def in ipairs(API.GetAll()) do
        if tonumber(def.npc) == templateId then return def end
    end
    return nil
end

-- ¿Quien ensena esta receta? Es la consulta que usa el libro para decir donde aprenderla.
function API.GetForRecipe(recipeId)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return nil end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then return nil end
    for _, def in ipairs(API.GetAll()) do
        if API.TrainerTeaches(def, recipe) then return def end
    end
    return nil
end

-- ¿Hay ALGUN entrenador que ensene esta receta? Si lo hay, la receta deja de venir con el nivel
-- de habilidad: declarar un entrenador para un rango es lo que cierra ese rango.
function API.IsTaught(recipeId)
    return API.GetForRecipe(recipeId) ~= nil
end

function API.GetForProfession(profId)
    profId = Norm(profId)
    local out = {}
    for _, def in ipairs(API.GetAll()) do
        if Norm(def.profession) == profId then out[#out + 1] = def end
    end
    return out
end

-- Texto corto para la ficha de la receta: "Nombre — Zona".
function API.DescribeForRecipe(recipeId)
    local def = API.GetForRecipe(recipeId)
    if not def then return nil end
    local nombre = tostring(def.name or def.id)
    if def.tier then nombre = nombre .. " (" .. tostring(def.tier) .. ")" end
    if def.zone and def.zone ~= "" then return nombre .. " - " .. tostring(def.zone), def end
    return nombre, def
end

------------------------------------------------------------
-- Registro desde el mundo
------------------------------------------------------------

-- Lo llama el ArcSpell del gossip del NPC. Idempotente: hablar dos veces no duplica nada.
-- def = { id, name, npc = <templateId>, zone?, profession, tier?, recipes? }
function API.Define(def)
    if type(def) ~= "table" then return false, "Definicion invalida" end
    local id = Norm(def.id)
    if id == "" then return false, "Falta el id del entrenador" end
    local npc = tonumber(def.npc)
    if not npc then return false, "Falta el template id del NPC" end
    if not def.tier and (type(def.recipes) ~= "table" or #def.recipes == 0) then
        return false, "El entrenador no declara ni rango ni recetas"
    end
    if def.tier and not API.GetTierRange(def.tier) then
        return false, "Rango desconocido: " .. tostring(def.tier)
    end
    -- Solo se aceptan recetas que existan y sean de su profesion: un NPC no puede inventar
    -- contenido ni ensenar recetas de otra profesion.
    local validas, descartadas = {}, 0
    for _, recipeId in ipairs(def.recipes or {}) do
        local r = HarfordProfessions and HarfordProfessions.GetRecipe
            and HarfordProfessions.GetRecipe(recipeId)
        if r and (not def.profession or Norm(r.profession) == Norm(def.profession)) then
            validas[#validas + 1] = tostring(recipeId)
        else
            descartadas = descartadas + 1
        end
    end

    local registrado = {
        id = id, name = tostring(def.name or id), npc = npc,
        zone = def.zone and tostring(def.zone) or nil,
        profession = def.profession and Norm(def.profession) or nil,
        tier = def.tier and select(3, API.GetTierRange(def.tier)) or nil,
        recipes = validas,
    }
    -- Un entrenador que no acaba cubriendo nada no se registra: seria un NPC mudo.
    if #API.GetRecipesFor(registrado) == 0 then
        return false, "El entrenador no cubre ninguna receta"
    end
    vivos[id] = registrado
    return true, descartadas
end

------------------------------------------------------------
-- Ensenar
------------------------------------------------------------

-- Aprender una receta de un entrenador. `npcTemplateId` identifica al NPC con el que se habla,
-- para que nadie aprenda de un entrenador que no tiene delante.
function API.Teach(npcTemplateId, recipeId)
    local def = API.GetByNpc(npcTemplateId)
    if not def then return false, "Ese NPC no es un entrenador registrado" end
    recipeId = tostring(recipeId or "")

    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then
        return false, "Profesiones no disponible"
    end
    local r = HarfordProfessions.GetRecipe(recipeId)
    if not r then return false, "Receta desconocida" end
    if not API.TrainerTeaches(def, r) then return false, "Ese entrenador no ensena esa receta" end
    if not HarfordProfessions.KnowsProfession(r.profession) then
        return false, "No conoces esa profesion"
    end
    if HarfordProfessions.IsRecipeLearned(recipeId) then
        return false, "Ya conoces esa receta"
    end
    if not HarfordProfessions.LearnRecipe then return false, "No se puede aprender" end
    return HarfordProfessions.LearnRecipe(recipeId)
end

-- API para el ArcSpell del gossip, con el mismo nombre publico que usan las misiones de mundo.
_G.HarfordTrainerAPI = _G.HarfordTrainerAPI or {}
_G.HarfordTrainerAPI.DefineTrainer = API.Define
_G.HarfordTrainerAPI.TeachRecipe = API.Teach
_G.HarfordTrainerAPI.GetTrainerForNpc = API.GetByNpc
