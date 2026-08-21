------------------------------------------------------------
-- HarfordProfessionTrainers - Entrenadores de profesion: quien ensena que receta y donde.
--
-- Un entrenador NO concede la profesion (eso sigue siendo competencia de herramienta o
-- decision del DM): es una TIENDA DE RECETAS, y cada uno cubre un RANGO de su profesion
-- (Aprendiz, Oficial, Experto, Artesano, Maestro).
--
-- LA IDENTIDAD ES EL NOMBRE DE CATALOGO, NO EL NPC. Un entrenador no apunta a un NPC: es el NPC
-- el que declara en su gossip que nombre de catalogo encarna (`herreria_experto`). Asi puede
-- haber varios NPCs para el mismo entrenador —uno en cada ciudad—, o cambiarse el NPC de sitio,
-- sin tocar nada aqui.
--
-- MARCAR UN ENTRENADOR COMO COLOCADO ES LO QUE CIERRA SU RANGO: mientras no lo este, sus recetas
-- siguen viniendo con el nivel de habilidad como hasta ahora, porque no habria de quien
-- aprenderlas. Una receta puede ademas traer `trainer = "<id>"` para atarla a uno concreto al
-- margen del rango.
--
-- DOBLE ORIGEN, igual que las misiones (HarfordQuestCatalog + DefineWorldQuest):
--   * CATALOGO hardcodeado (`API.TRAINERS`): la lista canonica. Sirve para que el libro pueda
--     decir "esta receta la ensena X en Y" ANTES de haber hablado nunca con ese NPC.
--   * REGISTRO EN VIVO (`API.Bind` / `API.Define`): un ArcSpell en el gossip del NPC dice que
--     nombre de catalogo encarna al hablar con el, y puede afinar nombre y zona.
-- Lo registrado en vivo manda sobre el catalogo para ese mismo nombre: el mundo es la verdad.
--
-- Este modulo NO ejecuta comandos de servidor ni toca al NPC. Solo responde "quien ensena
-- esto" y "marcalo como aprendido"; colocar al NPC y darle su gossip es cosa del mundo.
------------------------------------------------------------

HarfordProfessionTrainers = HarfordProfessionTrainers or {}
local API = HarfordProfessionTrainers

-- entrenador: { id, name, zone?, profession?, tier?, colocado?, recipes? = { recipeId, ... } }
--
-- `id` es el nombre de catalogo: la identidad, y lo que el NPC nombra en su gossip. Con la forma
-- "<profesion>_<rango>" ya basta: profesion y rango se deducen de ahi (`API.SplitId`) y no hay
-- que declararlos. Solo un entrenador con nombre propio necesita ponerlos a mano.
--
-- Lo normal es declarar `tier`: el entrenador ensena TODAS las recetas de su profesion cuyo
-- `skillReq` cae en ese rango, y la lista se deriva sola. Asi anadir recetas al catalogo no
-- obliga a tocar entrenadores. `recipes` es para casos sueltos (un plano concreto) y se suma a
-- lo que cubra el rango.
--
-- CATALOGO: uno por profesion y rango, solo donde hay recetas que ensenar. Cada linea es el
-- nombre y poco mas, porque el nombre ya dice la profesion y el rango.
-- Todos empiezan sin colocar: el entrenador esta DOCUMENTADO pero todavia no existe en el mundo. Asi el libro ya puede decir "esto lo ensena el Instructor de Herreria (Experto)"
-- antes de que ese NPC exista. Nombres provisionales: cambialos por los reales.
--
-- Un entrenador NO colocado no cierra nada: sus recetas siguen viniendo con el nivel de
-- habilidad, porque no habria de quien aprenderlas. Pon `colocado = true` el dia que exista un
-- NPC que lo encarne.
API.TRAINERS = API.TRAINERS or {
    -- Alquimia
    { id = "alquimia_aprendiz", name = "Instructor de Alquimia" },   -- 12 receta(s)
    { id = "alquimia_oficial", name = "Instructor de Alquimia" },   -- 17 receta(s)
    { id = "alquimia_experto", name = "Instructor de Alquimia" },   -- 28 receta(s)
    { id = "alquimia_artesano", name = "Instructor de Alquimia" },   -- 54 receta(s)
    { id = "alquimia_maestro", name = "Instructor de Alquimia" },   -- 17 receta(s)

    -- Cocina
    { id = "cocina_aprendiz", name = "Instructor de Cocina" },   -- 23 receta(s)
    { id = "cocina_oficial", name = "Instructor de Cocina" },   -- 23 receta(s)
    { id = "cocina_experto", name = "Instructor de Cocina" },   -- 17 receta(s)
    { id = "cocina_artesano", name = "Instructor de Cocina" },   -- 21 receta(s)
    { id = "cocina_maestro", name = "Instructor de Cocina" },   -- 3 receta(s)

    -- Desollar
    { id = "desollar_aprendiz", name = "Instructor de Desollar" },   -- 1 receta(s)
    { id = "desollar_oficial", name = "Instructor de Desollar" },   -- 2 receta(s)
    { id = "desollar_experto", name = "Instructor de Desollar" },   -- 1 receta(s)
    { id = "desollar_artesano", name = "Instructor de Desollar" },   -- 1 receta(s)
    { id = "desollar_maestro", name = "Instructor de Desollar" },   -- 1 receta(s)

    -- Encantamiento
    { id = "encantamiento_aprendiz", name = "Instructor de Encantamiento" },   -- 13 receta(s)
    { id = "encantamiento_oficial", name = "Instructor de Encantamiento" },   -- 32 receta(s)
    { id = "encantamiento_experto", name = "Instructor de Encantamiento" },   -- 41 receta(s)
    { id = "encantamiento_artesano", name = "Instructor de Encantamiento" },   -- 48 receta(s)
    { id = "encantamiento_maestro", name = "Instructor de Encantamiento" },   -- 65 receta(s)

    -- Fabricar venenos
    { id = "envenenador_aprendiz", name = "Instructor de Fabricar venenos" },   -- 2 receta(s)
    { id = "envenenador_oficial", name = "Instructor de Fabricar venenos" },   -- 1 receta(s)
    { id = "envenenador_experto", name = "Instructor de Fabricar venenos" },   -- 1 receta(s)
    { id = "envenenador_artesano", name = "Instructor de Fabricar venenos" },   -- 1 receta(s)
    { id = "envenenador_maestro", name = "Instructor de Fabricar venenos" },   -- 1 receta(s)

    -- Herboristeria
    { id = "herboristeria_aprendiz", name = "Instructor de Herboristeria" },   -- 5 receta(s)
    { id = "herboristeria_oficial", name = "Instructor de Herboristeria" },   -- 4 receta(s)
    { id = "herboristeria_experto", name = "Instructor de Herboristeria" },   -- 3 receta(s)
    { id = "herboristeria_artesano", name = "Instructor de Herboristeria" },   -- 1 receta(s)
    { id = "herboristeria_maestro", name = "Instructor de Herboristeria" },   -- 1 receta(s)

    -- Herreria
    { id = "herreria_aprendiz", name = "Instructor de Herreria" },   -- 23 receta(s)
    { id = "herreria_oficial", name = "Instructor de Herreria" },   -- 35 receta(s)
    { id = "herreria_experto", name = "Instructor de Herreria" },   -- 62 receta(s)
    { id = "herreria_artesano", name = "Instructor de Herreria" },   -- 80 receta(s)
    { id = "herreria_maestro", name = "Instructor de Herreria" },   -- 105 receta(s)

    -- Ingenieria
    { id = "ingenieria_aprendiz", name = "Instructor de Ingenieria" },   -- 10 receta(s)
    { id = "ingenieria_oficial", name = "Instructor de Ingenieria" },   -- 33 receta(s)
    { id = "ingenieria_experto", name = "Instructor de Ingenieria" },   -- 58 receta(s)
    { id = "ingenieria_artesano", name = "Instructor de Ingenieria" },   -- 72 receta(s)
    { id = "ingenieria_maestro", name = "Instructor de Ingenieria" },   -- 20 receta(s)

    -- Inscripcion
    { id = "inscripcion_aprendiz", name = "Instructor de Inscripcion" },   -- 5 receta(s)
    { id = "inscripcion_oficial", name = "Instructor de Inscripcion" },   -- 2 receta(s)
    { id = "inscripcion_experto", name = "Instructor de Inscripcion" },   -- 5 receta(s)
    { id = "inscripcion_artesano", name = "Instructor de Inscripcion" },   -- 4 receta(s)
    { id = "inscripcion_maestro", name = "Instructor de Inscripcion" },   -- 1 receta(s)

    -- Joyeria
    { id = "joyeria_aprendiz", name = "Instructor de Joyeria" },   -- 7 receta(s)
    { id = "joyeria_oficial", name = "Instructor de Joyeria" },   -- 5 receta(s)
    { id = "joyeria_experto", name = "Instructor de Joyeria" },   -- 3 receta(s)
    { id = "joyeria_artesano", name = "Instructor de Joyeria" },   -- 5 receta(s)
    { id = "joyeria_maestro", name = "Instructor de Joyeria" },   -- 1 receta(s)

    -- Mineria
    { id = "mineria_aprendiz", name = "Instructor de Mineria" },   -- 3 receta(s)
    { id = "mineria_oficial", name = "Instructor de Mineria" },   -- 2 receta(s)
    { id = "mineria_experto", name = "Instructor de Mineria" },   -- 3 receta(s)
    { id = "mineria_artesano", name = "Instructor de Mineria" },   -- 3 receta(s)
    { id = "mineria_maestro", name = "Instructor de Mineria" },   -- 2 receta(s)

    -- Peleteria
    { id = "peleteria_aprendiz", name = "Instructor de Peleteria" },   -- 19 receta(s)
    { id = "peleteria_oficial", name = "Instructor de Peleteria" },   -- 39 receta(s)
    { id = "peleteria_experto", name = "Instructor de Peleteria" },   -- 60 receta(s)
    { id = "peleteria_artesano", name = "Instructor de Peleteria" },   -- 106 receta(s)
    { id = "peleteria_maestro", name = "Instructor de Peleteria" },   -- 89 receta(s)

    -- Pesca
    { id = "pesca_aprendiz", name = "Instructor de Pesca" },   -- 1 receta(s)
    { id = "pesca_oficial", name = "Instructor de Pesca" },   -- 2 receta(s)
    { id = "pesca_experto", name = "Instructor de Pesca" },   -- 1 receta(s)
    { id = "pesca_artesano", name = "Instructor de Pesca" },   -- 1 receta(s)
    { id = "pesca_maestro", name = "Instructor de Pesca" },   -- 1 receta(s)

    -- Primeros Auxilios
    { id = "primeros_auxilios_aprendiz", name = "Instructor de Primeros Auxilios" },   -- 2 receta(s)
    { id = "primeros_auxilios_oficial", name = "Instructor de Primeros Auxilios" },   -- 4 receta(s)
    { id = "primeros_auxilios_experto", name = "Instructor de Primeros Auxilios" },   -- 3 receta(s)
    { id = "primeros_auxilios_artesano", name = "Instructor de Primeros Auxilios" },   -- 3 receta(s)
    { id = "primeros_auxilios_maestro", name = "Instructor de Primeros Auxilios" },   -- 2 receta(s)

    -- Sastreria
    { id = "sastreria_aprendiz", name = "Instructor de Sastreria" },   -- 27 receta(s)
    { id = "sastreria_oficial", name = "Instructor de Sastreria" },   -- 38 receta(s)
    { id = "sastreria_experto", name = "Instructor de Sastreria" },   -- 62 receta(s)
    { id = "sastreria_artesano", name = "Instructor de Sastreria" },   -- 84 receta(s)
    { id = "sastreria_maestro", name = "Instructor de Sastreria" },   -- 72 receta(s)
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

-- El nombre de catalogo ya dice lo que es: "herreria_experto" son la profesion y el rango. Se
-- deducen de ahi para que el catalogo sea una linea por entrenador, sin repetir lo que el nombre
-- ya lleva dentro.
--
-- Se parte por el ULTIMO guion bajo, no por el primero: hay profesiones con guion dentro
-- ("primeros_auxilios"). Y solo cuenta si el sufijo es un rango de verdad, asi que un entrenador
-- con nombre propio ("thorgas_yunquegris") no se malinterpreta: ese tiene que declarar sus campos.
function API.SplitId(trainerId)
    local resto, sufijo = tostring(trainerId or ""):match("^(.*)_([^_]+)$")
    if not resto or resto == "" then return nil end
    local _, _, canonico = API.GetTierRange(sufijo)
    if not canonico then return nil end
    return Norm(resto), canonico
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
-- Se resuelve al primer uso y no al cargar: asi da igual el orden del toc. Cuesta un booleano.
local catalogoResuelto = false
local function ResolverCatalogo()
    if catalogoResuelto or not (HarfordProfessions and HarfordProfessions.TIERS) then return end
    for _, def in ipairs(API.TRAINERS) do
        if not (def.profession and def.tier) then
            local prof, rango = API.SplitId(def.id)
            if prof then
                def.profession = def.profession or prof
                def.tier = def.tier or rango
            end
        end
    end
    catalogoResuelto = true
end

function API.GetAll()
    ResolverCatalogo()
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

-- ¿Hay algun entrenador COLOCADO que ensene esta receta? Solo entonces deja de venir con el
-- nivel de habilidad.
--
-- La condicion es estar colocado, no estar en el catalogo: un entrenador documentado que aun no
-- existe en el mundo no puede ensenar nada, asi que cerrar su rango dejaria esas recetas
-- inalcanzables. Con esto el catalogo entero puede existir desde el primer dia —el libro ya dice
-- quien lo ensenara— y cada rango se cierra el dia que se coloca.
function API.IsTaught(recipeId)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return false end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then return false end
    for _, def in ipairs(API.GetAll()) do
        if def.colocado and API.TrainerTeaches(def, recipe) then return true end
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

-- Un NPC declara que nombre de catalogo encarna. Es la via normal del gossip: el entrenador ya
-- esta descrito aqui, el NPC solo dice cual es y, si acaso, afina nombre y zona.
-- Idempotente: hablar dos veces no cambia nada.
function API.Bind(trainerId, opts)
    local def = API.Get(trainerId)
    if not def then
        return false, "Nombre de entrenador desconocido: " .. tostring(trainerId)
    end
    opts = type(opts) == "table" and opts or {}
    -- Se copia el del catalogo para no mutarlo: el catalogo es la version de referencia y el
    -- registro en vivo solo la refina mientras dura la sesion.
    local registrado = {}
    for k, v in pairs(def) do registrado[k] = v end
    if opts.name and tostring(opts.name) ~= "" then registrado.name = tostring(opts.name) end
    if opts.zone and tostring(opts.zone) ~= "" then registrado.zone = tostring(opts.zone) end
    registrado.colocado = true
    vivos[Norm(def.id)] = registrado
    return true, registrado
end

-- Retira el registro en vivo y devuelve el entrenador a lo que diga el catalogo. Solo afecta a
-- lo registrado en esta sesion: un entrenador colocado desde el catalogo se cambia en el Lua.
function API.Unbind(trainerId)
    local id = Norm(trainerId)
    if id == "" or not vivos[id] then return false end
    vivos[id] = nil
    return true
end

-- Registro completo de un entrenador que NO esta en el catalogo. Para casos sueltos; lo normal
-- es que el NPC use `Bind` con un nombre ya catalogado.
-- def = { id, name, zone?, profession, tier?, recipes? }
function API.Define(def)
    if type(def) ~= "table" then return false, "Definicion invalida" end
    local id = Norm(def.id)
    if id == "" then return false, "Falta el nombre de catalogo del entrenador" end
    -- Un nombre con la forma del catalogo ya trae profesion y rango; declararlos es opcional.
    local idProf, idTier = API.SplitId(id)
    local profesion, tier = def.profession or idProf, def.tier or idTier
    if not tier and (type(def.recipes) ~= "table" or #def.recipes == 0) then
        return false, "El entrenador no declara ni rango ni recetas"
    end
    if tier and not API.GetTierRange(tier) then
        return false, "Rango desconocido: " .. tostring(tier)
    end
    -- Solo se aceptan recetas que existan y sean de su profesion: un NPC no puede inventar
    -- contenido ni ensenar recetas de otra profesion.
    local validas, descartadas = {}, 0
    for _, recipeId in ipairs(def.recipes or {}) do
        local r = HarfordProfessions and HarfordProfessions.GetRecipe
            and HarfordProfessions.GetRecipe(recipeId)
        if r and (not profesion or Norm(r.profession) == Norm(profesion)) then
            validas[#validas + 1] = tostring(recipeId)
        else
            descartadas = descartadas + 1
        end
    end

    local registrado = {
        id = id, name = tostring(def.name or id), colocado = true,
        zone = def.zone and tostring(def.zone) or nil,
        profession = profesion and Norm(profesion) or nil,
        tier = tier and select(3, API.GetTierRange(tier)) or nil,
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

-- Aprender una receta de un entrenador, nombrandolo por su nombre de catalogo: es lo que el
-- gossip del NPC tiene delante, y evita aprender de un entrenador que no esta colocado.
function API.Teach(trainerId, recipeId)
    local def = API.Get(trainerId)
    if not def then return false, "Nombre de entrenador desconocido" end
    if not def.colocado then return false, "Ese entrenador aun no existe en el mundo" end
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
_G.HarfordTrainerAPI.BindTrainer = API.Bind
_G.HarfordTrainerAPI.DefineTrainer = API.Define
_G.HarfordTrainerAPI.TeachRecipe = API.Teach
_G.HarfordTrainerAPI.GetTrainer = API.Get
