------------------------------------------------------------
-- HarfordProfessionTrainers - Entrenadores de profesion: quien ensena que receta y donde.
--
-- Un entrenador NO concede la profesion (eso sigue siendo competencia de herramienta o
-- decision del DM): es una TIENDA DE RECETAS. Una receta con `trainer = "<id>"` deja de estar
-- disponible por nivel de habilidad y hay que aprenderla de ese entrenador.
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

-- entrenador: { id, name, npc = <templateId>, zone, profession, recipes = { recipeId, ... } }
-- `npc` es opcional en el catalogo: un entrenador puede estar documentado antes de existir
-- en el mundo. Sin `npc` se puede consultar pero no ensenar.
API.TRAINERS = API.TRAINERS or {}

-- Registrados en vivo por el gossip del NPC. No se persisten: el mundo los vuelve a declarar.
local vivos = {}

local function Norm(v)
    return tostring(v or ""):lower()
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
    recipeId = Norm(recipeId)
    if recipeId == "" then return nil end
    for _, def in ipairs(API.GetAll()) do
        for _, id in ipairs(def.recipes or {}) do
            if Norm(id) == recipeId then return def end
        end
    end
    return nil
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
    if def.zone and def.zone ~= "" then return nombre .. " - " .. tostring(def.zone), def end
    return nombre, def
end

------------------------------------------------------------
-- Registro desde el mundo
------------------------------------------------------------

-- Lo llama el ArcSpell del gossip del NPC. Idempotente: hablar dos veces no duplica nada.
-- def = { id, name, npc = <templateId>, zone?, profession, recipes = { recipeId, ... } }
function API.Define(def)
    if type(def) ~= "table" then return false, "Definicion invalida" end
    local id = Norm(def.id)
    if id == "" then return false, "Falta el id del entrenador" end
    local npc = tonumber(def.npc)
    if not npc then return false, "Falta el template id del NPC" end
    if type(def.recipes) ~= "table" or #def.recipes == 0 then
        return false, "El entrenador no declara ninguna receta"
    end
    -- Solo se aceptan recetas que existan y sean de su profesion: un NPC no puede inventar
    -- contenido ni ensenar recetas de otra profesion.
    local validas, descartadas = {}, 0
    for _, recipeId in ipairs(def.recipes) do
        local r = HarfordProfessions and HarfordProfessions.GetRecipe
            and HarfordProfessions.GetRecipe(recipeId)
        if r and (not def.profession or Norm(r.profession) == Norm(def.profession)) then
            validas[#validas + 1] = tostring(recipeId)
        else
            descartadas = descartadas + 1
        end
    end
    if #validas == 0 then return false, "Ninguna receta declarada es valida" end

    vivos[id] = {
        id = id, name = tostring(def.name or id), npc = npc,
        zone = def.zone and tostring(def.zone) or nil,
        profession = def.profession and Norm(def.profession) or nil,
        recipes = validas,
    }
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

    local ensena = false
    for _, id in ipairs(def.recipes or {}) do
        if Norm(id) == Norm(recipeId) then ensena = true break end
    end
    if not ensena then return false, "Ese entrenador no ensena esa receta" end

    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then
        return false, "Profesiones no disponible"
    end
    local r = HarfordProfessions.GetRecipe(recipeId)
    if not r then return false, "Receta desconocida" end
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
