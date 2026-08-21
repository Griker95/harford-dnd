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
-- COLOCAR UN ENTRENADOR ES LO QUE CIERRA SU RANGO: mientras no lo este, sus recetas
-- siguen viniendo con el nivel de habilidad como hasta ahora, porque no habria de quien
-- aprenderlas. Una receta puede ademas traer `trainer = "<id>"` para atarla a uno concreto al
-- margen del rango.
--
-- DOS SITIOS DONDE UN ENTRENADOR SE DA POR PUESTO:
--   * `API.PLACED` hardcodeado: los que ya estan en el mundo, con su nombre y zona reales. Sirve
--     para que el libro diga "esta receta la ensena X en Y" sin haber hablado nunca con el NPC.
--   * REGISTRO EN VIVO (`API.Bind` / `API.Define`): un ArcSpell en el gossip del NPC dice que
--     nombre de catalogo encarna al hablar con el, y puede afinar nombre y zona.
-- Lo registrado en vivo manda para ese mismo nombre: el mundo es la verdad.
--
-- Este modulo NO ejecuta comandos de servidor ni toca al NPC. Solo responde "quien ensena
-- esto" y "marcalo como aprendido"; colocar al NPC y darle su gossip es cosa del mundo.
------------------------------------------------------------

HarfordProfessionTrainers = HarfordProfessionTrainers or {}
local API = HarfordProfessionTrainers

-- NO HAY LISTA DE ENTRENADORES: se deducen. Existe uno por cada par (profesion, rango) que
-- tenga recetas, su nombre de catalogo es "<profesion>_<rango>" y de ahi salen tambien su
-- profesion, su rango, las recetas que cubre y hasta como se llama por defecto ("Instructor de
-- Herreria"). Escribir esa lista era escribir 75 veces lo que ya estaba en el nombre.
--
-- Lo unico que NO se puede deducir es cuales existen ya en el mundo y como se llama de verdad el
-- NPC que los encarna. Eso es esto, y empieza vacio:
--
--   { id = "herreria_experto", name = "Thorgas Yunquegris", zone = "Forjaz" },
--
-- Una entrada aqui CIERRA ese rango: sus recetas dejan de venir con el nivel de habilidad y hay
-- que aprenderlas del entrenador. `name` y `zone` son solo el texto de "donde se aprende"; si
-- faltan, se usa el nombre por defecto y no se dice zona. `recipes` ata recetas sueltas de mas.
API.PLACED = API.PLACED or {}

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
-- Requisito de habilidad de una receta, ya acotado al primer rango. Hay recetas con `skillReq`
-- 0, y `tonumber(0) or 1` sigue siendo 0: quedaban por debajo del minimo de Aprendiz (1) y
-- entonces no caian en NINGUN rango, asi que se quedaban sin entrenador que las cubriera.
local function SkillReq(recipe)
    local req = tonumber(recipe and recipe.skillReq) or 1
    return req < 1 and 1 or req
end

-- El rango al que pertenece una receta por su requisito de habilidad.
local function TierForRecipe(recipe)
    local req, nombre = SkillReq(recipe), nil
    for _, t in ipairs((HarfordProfessions and HarfordProfessions.TIERS) or {}) do
        if req >= t.min then nombre = t.name end
    end
    return nombre
end

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
    local req = SkillReq(recipe)
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

-- Los declarados a mano: los de `API.PLACED` mas lo registrado en vivo, que manda. Son pocos
-- —solo los que existen en el mundo—, asi que recorrerlos sale barato y es lo que permite que
-- `IsTaught`, que se llama por cada fila de la lista de recetas, no construya ni una tabla.
local function Declarados()
    local out, vistos = {}, {}
    for _, def in pairs(vivos) do
        out[#out + 1] = def
        vistos[Norm(def.id)] = true
    end
    for _, def in ipairs(API.PLACED) do
        if not vistos[Norm(def.id)] then
            -- Una entrada escrita a mano es solo { id, name, zone }: sin profesion ni rango no
            -- cubriria ninguna receta y no cerraria nada. Se deducen del nombre y se dejan
            -- puestas, que es idempotente y ahorra repetirlo en cada consulta.
            if not (def.profession and def.tier) then
                local prof, tier = API.SplitId(def.id)
                def.profession = def.profession or prof
                def.tier = def.tier or tier
            end
            out[#out + 1] = def
        end
    end
    return out
end

-- Nombre por defecto de un entrenador mientras el mundo no diga otra cosa.
local function NombrePorDefecto(profId)
    local visible = profId
    local def = HarfordProfessions and HarfordProfessions.GetDefinition
        and HarfordProfessions.GetDefinition(profId)
    if def and def.name and def.name ~= "" then visible = def.name end
    return "Instructor de " .. tostring(visible)
end

-- El entrenador con ese nombre de catalogo, construido al vuelo. nil si ese par (profesion,
-- rango) no tiene ninguna receta que ensenar: entonces ese entrenador no existe.
function API.Get(trainerId)
    local id = Norm(trainerId)
    if id == "" then return nil end
    local declarado
    for _, def in ipairs(Declarados()) do
        if Norm(def.id) == id then declarado = def break end
    end
    local prof, tier = API.SplitId(id)
    -- Un nombre propio ("thorgas_yunquegris") no se puede deducir: solo existe si esta declarado.
    if not prof then return declarado end

    local def = {
        id = id, profession = prof, tier = tier,
        name = declarado and declarado.name or NombrePorDefecto(prof),
        zone = declarado and declarado.zone or nil,
        recipes = declarado and declarado.recipes or nil,
        colocado = declarado ~= nil,
    }
    if #API.GetRecipesFor(def) == 0 then return nil end
    return def
end

-- Todos los que existen: cada par (profesion, rango) con recetas, mas los de nombre propio.
function API.GetAll()
    local out, vistos = {}, {}
    local tiers = (HarfordProfessions and HarfordProfessions.TIERS) or {}
    for _, prof in ipairs(HarfordProfessions and HarfordProfessions.GetProfessions() or {}) do
        for _, t in ipairs(tiers) do
            local def = API.Get(prof.id .. "_" .. Norm(t.name))
            if def then out[#out + 1] = def; vistos[Norm(def.id)] = true end
        end
    end
    for _, def in ipairs(Declarados()) do
        if not vistos[Norm(def.id)] then out[#out + 1] = def end
    end
    return out
end

-- ¿Quien ensena esta receta? Es la consulta que usa el libro para decir donde aprenderla.
function API.GetForRecipe(recipeId)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return nil end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then return nil end
    -- Primero los declarados: uno puede atar una receta suelta al margen de su rango.
    for _, def in ipairs(Declarados()) do
        if API.TrainerTeaches(def, recipe) then return API.Get(def.id) or def end
    end
    -- Si no, el que le toca por profesion y rango. Directo, sin recorrer nada.
    local tier = TierForRecipe(recipe)
    if not tier then return nil end
    return API.Get(Norm(recipe.profession) .. "_" .. Norm(tier))
end

-- ¿Hay algun entrenador COLOCADO que ensene esta receta? Solo entonces deja de venir con el
-- nivel de habilidad.
--
-- Solo un entrenador colocado cierra su rango: uno deducido pero que aun no existe en el mundo no
-- puede ensenar nada, y cerrarlo dejaria esas recetas inalcanzables. Por eso basta con recorrer
-- los declarados, que son justamente los colocados.
function API.IsTaught(recipeId)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return false end
    local recipe = HarfordProfessions.GetRecipe(recipeId)
    if not recipe then return false end
    for _, def in ipairs(Declarados()) do
        if API.TrainerTeaches(def, recipe) then return true end
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
    local registrado = def   -- Get ya lo construye al vuelo: no hay nada compartido que mutar.
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
