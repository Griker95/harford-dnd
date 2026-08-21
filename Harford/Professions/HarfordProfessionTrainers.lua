------------------------------------------------------------
-- HarfordProfessionTrainers - Entrenadores de profesion: quien ensena que receta y donde.
--
-- Un entrenador NO concede la profesion (eso sigue siendo competencia de herramienta o
-- decision del DM): es una TIENDA DE RECETAS, y cada uno cubre un RANGO de su profesion
-- (Aprendiz, Oficial, Experto, Artesano, Maestro).
--
-- COLOCAR EL NPC DE UN RANGO ES LO QUE CIERRA ESE RANGO: mientras el entrenador no tenga `npc`,
-- sus recetas siguen viniendo con el nivel de habilidad como hasta ahora, porque no habria de
-- quien aprenderlas. En cuanto ese entrenador existe en el mundo, hay que aprenderlas de el. Una
-- receta puede ademas traer `trainer = "<id>"` para atarla a uno concreto al margen del rango.
--
-- DOBLE ORIGEN, igual que las misiones (HarfordQuestCatalog + DefineWorldQuest):
--   * CATALOGO hardcodeado (`API.TRAINERS`): la lista canonica. Sirve para que el libro pueda
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
-- `npc` es opcional: un entrenador puede estar documentado antes de existir en el mundo.
--
-- CATALOGO: uno por profesion y rango, solo donde hay recetas que ensenar.
-- `npc` y `zone` van a nil a proposito: el entrenador esta DOCUMENTADO pero aun no colocado en
-- el mundo. Asi el libro ya puede decir "esto lo ensena el Instructor de Herreria (Experto)"
-- aunque todavia no exista el NPC; sin `npc` se puede consultar pero no aprender de el.
-- Nombres provisionales: cambialos por los reales segun se vayan colocando.
--
-- Un entrenador SIN `npc` no cierra nada: sus recetas siguen viniendo con el nivel de habilidad,
-- porque no habria de quien aprenderlas. El rango se cierra el dia que se le pone NPC.
API.TRAINERS = API.TRAINERS or {
    -- Alquimia
    { id = "alquimia_aprendiz", name = "Instructor de Alquimia", profession = "alquimia", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 12 receta(s)
    { id = "alquimia_oficial", name = "Instructor de Alquimia", profession = "alquimia", tier = "Oficial",
      npc = nil, zone = nil },   -- 17 receta(s)
    { id = "alquimia_experto", name = "Instructor de Alquimia", profession = "alquimia", tier = "Experto",
      npc = nil, zone = nil },   -- 28 receta(s)
    { id = "alquimia_artesano", name = "Instructor de Alquimia", profession = "alquimia", tier = "Artesano",
      npc = nil, zone = nil },   -- 54 receta(s)
    { id = "alquimia_maestro", name = "Instructor de Alquimia", profession = "alquimia", tier = "Maestro",
      npc = nil, zone = nil },   -- 17 receta(s)

    -- Cocina
    { id = "cocina_aprendiz", name = "Instructor de Cocina", profession = "cocina", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 23 receta(s)
    { id = "cocina_oficial", name = "Instructor de Cocina", profession = "cocina", tier = "Oficial",
      npc = nil, zone = nil },   -- 23 receta(s)
    { id = "cocina_experto", name = "Instructor de Cocina", profession = "cocina", tier = "Experto",
      npc = nil, zone = nil },   -- 17 receta(s)
    { id = "cocina_artesano", name = "Instructor de Cocina", profession = "cocina", tier = "Artesano",
      npc = nil, zone = nil },   -- 21 receta(s)
    { id = "cocina_maestro", name = "Instructor de Cocina", profession = "cocina", tier = "Maestro",
      npc = nil, zone = nil },   -- 3 receta(s)

    -- Desollar
    { id = "desollar_aprendiz", name = "Instructor de Desollar", profession = "desollar", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "desollar_oficial", name = "Instructor de Desollar", profession = "desollar", tier = "Oficial",
      npc = nil, zone = nil },   -- 2 receta(s)
    { id = "desollar_experto", name = "Instructor de Desollar", profession = "desollar", tier = "Experto",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "desollar_artesano", name = "Instructor de Desollar", profession = "desollar", tier = "Artesano",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "desollar_maestro", name = "Instructor de Desollar", profession = "desollar", tier = "Maestro",
      npc = nil, zone = nil },   -- 1 receta(s)

    -- Encantamiento
    { id = "encantamiento_aprendiz", name = "Instructor de Encantamiento", profession = "encantamiento", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 13 receta(s)
    { id = "encantamiento_oficial", name = "Instructor de Encantamiento", profession = "encantamiento", tier = "Oficial",
      npc = nil, zone = nil },   -- 32 receta(s)
    { id = "encantamiento_experto", name = "Instructor de Encantamiento", profession = "encantamiento", tier = "Experto",
      npc = nil, zone = nil },   -- 41 receta(s)
    { id = "encantamiento_artesano", name = "Instructor de Encantamiento", profession = "encantamiento", tier = "Artesano",
      npc = nil, zone = nil },   -- 48 receta(s)
    { id = "encantamiento_maestro", name = "Instructor de Encantamiento", profession = "encantamiento", tier = "Maestro",
      npc = nil, zone = nil },   -- 65 receta(s)

    -- Fabricar venenos
    { id = "envenenador_aprendiz", name = "Instructor de Fabricar venenos", profession = "envenenador", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 2 receta(s)
    { id = "envenenador_oficial", name = "Instructor de Fabricar venenos", profession = "envenenador", tier = "Oficial",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "envenenador_experto", name = "Instructor de Fabricar venenos", profession = "envenenador", tier = "Experto",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "envenenador_artesano", name = "Instructor de Fabricar venenos", profession = "envenenador", tier = "Artesano",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "envenenador_maestro", name = "Instructor de Fabricar venenos", profession = "envenenador", tier = "Maestro",
      npc = nil, zone = nil },   -- 1 receta(s)

    -- Herboristeria
    { id = "herboristeria_aprendiz", name = "Instructor de Herboristeria", profession = "herboristeria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 5 receta(s)
    { id = "herboristeria_oficial", name = "Instructor de Herboristeria", profession = "herboristeria", tier = "Oficial",
      npc = nil, zone = nil },   -- 4 receta(s)
    { id = "herboristeria_experto", name = "Instructor de Herboristeria", profession = "herboristeria", tier = "Experto",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "herboristeria_artesano", name = "Instructor de Herboristeria", profession = "herboristeria", tier = "Artesano",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "herboristeria_maestro", name = "Instructor de Herboristeria", profession = "herboristeria", tier = "Maestro",
      npc = nil, zone = nil },   -- 1 receta(s)

    -- Herreria
    { id = "herreria_aprendiz", name = "Instructor de Herreria", profession = "herreria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 23 receta(s)
    { id = "herreria_oficial", name = "Instructor de Herreria", profession = "herreria", tier = "Oficial",
      npc = nil, zone = nil },   -- 35 receta(s)
    { id = "herreria_experto", name = "Instructor de Herreria", profession = "herreria", tier = "Experto",
      npc = nil, zone = nil },   -- 62 receta(s)
    { id = "herreria_artesano", name = "Instructor de Herreria", profession = "herreria", tier = "Artesano",
      npc = nil, zone = nil },   -- 80 receta(s)
    { id = "herreria_maestro", name = "Instructor de Herreria", profession = "herreria", tier = "Maestro",
      npc = nil, zone = nil },   -- 105 receta(s)

    -- Ingenieria
    { id = "ingenieria_aprendiz", name = "Instructor de Ingenieria", profession = "ingenieria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 10 receta(s)
    { id = "ingenieria_oficial", name = "Instructor de Ingenieria", profession = "ingenieria", tier = "Oficial",
      npc = nil, zone = nil },   -- 33 receta(s)
    { id = "ingenieria_experto", name = "Instructor de Ingenieria", profession = "ingenieria", tier = "Experto",
      npc = nil, zone = nil },   -- 58 receta(s)
    { id = "ingenieria_artesano", name = "Instructor de Ingenieria", profession = "ingenieria", tier = "Artesano",
      npc = nil, zone = nil },   -- 72 receta(s)
    { id = "ingenieria_maestro", name = "Instructor de Ingenieria", profession = "ingenieria", tier = "Maestro",
      npc = nil, zone = nil },   -- 20 receta(s)

    -- Inscripcion
    { id = "inscripcion_aprendiz", name = "Instructor de Inscripcion", profession = "inscripcion", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 5 receta(s)
    { id = "inscripcion_oficial", name = "Instructor de Inscripcion", profession = "inscripcion", tier = "Oficial",
      npc = nil, zone = nil },   -- 2 receta(s)
    { id = "inscripcion_experto", name = "Instructor de Inscripcion", profession = "inscripcion", tier = "Experto",
      npc = nil, zone = nil },   -- 5 receta(s)
    { id = "inscripcion_artesano", name = "Instructor de Inscripcion", profession = "inscripcion", tier = "Artesano",
      npc = nil, zone = nil },   -- 4 receta(s)
    { id = "inscripcion_maestro", name = "Instructor de Inscripcion", profession = "inscripcion", tier = "Maestro",
      npc = nil, zone = nil },   -- 1 receta(s)

    -- Joyeria
    { id = "joyeria_aprendiz", name = "Instructor de Joyeria", profession = "joyeria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 7 receta(s)
    { id = "joyeria_oficial", name = "Instructor de Joyeria", profession = "joyeria", tier = "Oficial",
      npc = nil, zone = nil },   -- 5 receta(s)
    { id = "joyeria_experto", name = "Instructor de Joyeria", profession = "joyeria", tier = "Experto",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "joyeria_artesano", name = "Instructor de Joyeria", profession = "joyeria", tier = "Artesano",
      npc = nil, zone = nil },   -- 5 receta(s)
    { id = "joyeria_maestro", name = "Instructor de Joyeria", profession = "joyeria", tier = "Maestro",
      npc = nil, zone = nil },   -- 1 receta(s)

    -- Mineria
    { id = "mineria_aprendiz", name = "Instructor de Mineria", profession = "mineria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "mineria_oficial", name = "Instructor de Mineria", profession = "mineria", tier = "Oficial",
      npc = nil, zone = nil },   -- 2 receta(s)
    { id = "mineria_experto", name = "Instructor de Mineria", profession = "mineria", tier = "Experto",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "mineria_artesano", name = "Instructor de Mineria", profession = "mineria", tier = "Artesano",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "mineria_maestro", name = "Instructor de Mineria", profession = "mineria", tier = "Maestro",
      npc = nil, zone = nil },   -- 2 receta(s)

    -- Peleteria
    { id = "peleteria_aprendiz", name = "Instructor de Peleteria", profession = "peleteria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 19 receta(s)
    { id = "peleteria_oficial", name = "Instructor de Peleteria", profession = "peleteria", tier = "Oficial",
      npc = nil, zone = nil },   -- 39 receta(s)
    { id = "peleteria_experto", name = "Instructor de Peleteria", profession = "peleteria", tier = "Experto",
      npc = nil, zone = nil },   -- 60 receta(s)
    { id = "peleteria_artesano", name = "Instructor de Peleteria", profession = "peleteria", tier = "Artesano",
      npc = nil, zone = nil },   -- 106 receta(s)
    { id = "peleteria_maestro", name = "Instructor de Peleteria", profession = "peleteria", tier = "Maestro",
      npc = nil, zone = nil },   -- 89 receta(s)

    -- Pesca
    { id = "pesca_aprendiz", name = "Instructor de Pesca", profession = "pesca", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "pesca_oficial", name = "Instructor de Pesca", profession = "pesca", tier = "Oficial",
      npc = nil, zone = nil },   -- 2 receta(s)
    { id = "pesca_experto", name = "Instructor de Pesca", profession = "pesca", tier = "Experto",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "pesca_artesano", name = "Instructor de Pesca", profession = "pesca", tier = "Artesano",
      npc = nil, zone = nil },   -- 1 receta(s)
    { id = "pesca_maestro", name = "Instructor de Pesca", profession = "pesca", tier = "Maestro",
      npc = nil, zone = nil },   -- 1 receta(s)

    -- Primeros Auxilios
    { id = "primeros_auxilios_aprendiz", name = "Instructor de Primeros Auxilios", profession = "primeros_auxilios", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 2 receta(s)
    { id = "primeros_auxilios_oficial", name = "Instructor de Primeros Auxilios", profession = "primeros_auxilios", tier = "Oficial",
      npc = nil, zone = nil },   -- 4 receta(s)
    { id = "primeros_auxilios_experto", name = "Instructor de Primeros Auxilios", profession = "primeros_auxilios", tier = "Experto",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "primeros_auxilios_artesano", name = "Instructor de Primeros Auxilios", profession = "primeros_auxilios", tier = "Artesano",
      npc = nil, zone = nil },   -- 3 receta(s)
    { id = "primeros_auxilios_maestro", name = "Instructor de Primeros Auxilios", profession = "primeros_auxilios", tier = "Maestro",
      npc = nil, zone = nil },   -- 2 receta(s)

    -- Sastreria
    { id = "sastreria_aprendiz", name = "Instructor de Sastreria", profession = "sastreria", tier = "Aprendiz",
      npc = nil, zone = nil },   -- 27 receta(s)
    { id = "sastreria_oficial", name = "Instructor de Sastreria", profession = "sastreria", tier = "Oficial",
      npc = nil, zone = nil },   -- 38 receta(s)
    { id = "sastreria_experto", name = "Instructor de Sastreria", profession = "sastreria", tier = "Experto",
      npc = nil, zone = nil },   -- 62 receta(s)
    { id = "sastreria_artesano", name = "Instructor de Sastreria", profession = "sastreria", tier = "Artesano",
      npc = nil, zone = nil },   -- 84 receta(s)
    { id = "sastreria_maestro", name = "Instructor de Sastreria", profession = "sastreria", tier = "Maestro",
      npc = nil, zone = nil },   -- 72 receta(s)
}

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

-- ¿Hay algun entrenador COLOCADO EN EL MUNDO que ensene esta receta? Solo entonces deja de
-- venir con el nivel de habilidad.
--
-- La condicion es tener `npc`, no estar en el catalogo: un entrenador documentado pero sin NPC
-- no puede ensenar nada, asi que cerrar su rango dejaria esas recetas inalcanzables. Con esto el
-- catalogo entero puede existir desde el primer dia —el libro ya dice quien lo ensenara— y cada
-- rango se cierra el dia que se coloca su NPC.
function API.IsTaught(recipeId)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return false end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then return false end
    for _, def in ipairs(API.GetAll()) do
        if def.npc and API.TrainerTeaches(def, recipe) then return true end
    end
    return false
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
