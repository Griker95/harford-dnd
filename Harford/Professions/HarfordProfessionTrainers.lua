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
-- Todas las recetas no iniciales se aprenden explicitamente. Colocar un entrenador solo anade
-- su nombre y zona reales al catalogo; los IDs deducidos siguen pudiendo abrirse desde gossip.
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
-- Lo unico que NO se puede deducir es cuales existen ya en el mundo. Eso es esto, y empieza
-- vacio. Una entrada aqui aporta el nombre y la zona reales. Basta el nombre pelado:
--
--   "herreria_experto",
--
-- La forma larga solo anade el texto de "donde se aprende", para que el libro pueda mandar al
-- jugador a un sitio en vez de decirle solo que rango busca:
--
--   { id = "herreria_experto", name = "Thorgas Yunquegris", zone = "Forjaz" },
--
-- `recipes` ata ademas recetas sueltas al margen del rango.
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
    for i, def in ipairs(API.PLACED) do
        -- Basta el nombre pelado para dar un rango por puesto. `name` y `zone` son opcionales y
        -- solo alimentan el texto de "donde se aprende": sin ellos se dice el rango y punto.
        if type(def) == "string" then
            def = { id = def }
            API.PLACED[i] = def
        end
        if not vistos[Norm(def.id)] then
            -- Sin profesion ni rango no cubriria ninguna receta, asi que no cerraria nada. Se
            -- deducen del nombre y se dejan puestas: es idempotente y ahorra repetirlo.
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
-- Los entrenadores se construyen al vuelo, y comprobar que el par profesion/rango TIENE recetas
-- obliga a recorrer las 1614 del catalogo. Eso es aceptable una vez, no una por fila que entra en
-- pantalla al hacer scroll. Se memoiza igual que la resolucion por receta, y `OlvidarCache()`
-- limpia las dos.
local cacheEntrenadores = {}

function API.Get(trainerId)
    local id = Norm(trainerId)
    if id == "" then return nil end
    local memo = cacheEntrenadores[id]
    if memo ~= nil then
        if memo == false then return nil end
        return memo
    end
    local construido = API._Construir(id)
    cacheEntrenadores[id] = construido or false
    return construido
end

function API._Construir(id)
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
-- Que entrenador ensena cada receta NO cambia en caliente: sale del catalogo y de PLACED, ambos
-- estaticos en la sesion. Resolverlo costaba 0.28 ms por receta -recorre los declarados y monta
-- el entrenador del rango- y la lista lo pedia por cada fila visible en cada refresco. Se memoiza
-- por id; `API.OlvidarCache()` lo limpia si alguna vez se toca PLACED o se define una receta nueva.
local cacheEntrenadorPorReceta = {}

function API.OlvidarCache()
    cacheEntrenadorPorReceta = {}
    cacheEntrenadores = {}
end

function API.GetForRecipe(recipeId)
    if not (HarfordProfessions and HarfordProfessions.GetRecipe) then return nil end
    local memo = cacheEntrenadorPorReceta[recipeId]
    if memo ~= nil then
        if memo == false then return nil end
        return memo
    end
    local resultado = API._ResolverParaReceta(recipeId)
    cacheEntrenadorPorReceta[recipeId] = resultado or false
    return resultado
end

function API._ResolverParaReceta(recipeId)
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
    -- La cache memoriza tambien los negativos, asi que sin limpiarla el entrenador soltado seguia
    -- resolviendo.
    API.OlvidarCache()
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
-- gossip del NPC tiene delante.
--
-- NO exige que el entrenador este colocado: si el gossip abrio esta ventana, ya estas hablando
-- con su representacion. `colocado` solo aporta metadatos de nombre y zona al catalogo.
--
-- Las condiciones se comprueban aqui y no en la ventana: la UI las repite para pintar el boton,
-- pero quien decide es esto, asi que no hay forma de aprender saltandose el requisito.
local function ValidateTeach(trainerId, recipeId)
    local def = API.Get(trainerId)
    if not def then return false, "Nombre de entrenador desconocido" end
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
    -- Lo que decide es el RANGO, no el requisito exacto de la receta: siendo Aprendiz se pueden
    -- aprender TODAS las de Aprendiz, aunque alguna quede por encima de tu habilidad y salga en
    -- rojo. Fabricarla sera dificil -CD 20-, pero tenerla es cosa de haber llegado al rango.
    --
    -- Comparar contra el `skillReq` de cada receta dejaba media lista del entrenador fuera de
    -- alcance justo despues de pagarle por llegar a su rango.
    local skill = HarfordProfessions.EffectiveSkill
        and HarfordProfessions.EffectiveSkill(r.profession) or 0
    local rango = HarfordProfessions.GetTierName and HarfordProfessions.GetTierName(SkillReq(r))
    local minimo = rango and API.GetTierRange(rango) or SkillReq(r)
    if skill < minimo then
        return false, "Te falta habilidad: ese rango empieza en " .. minimo
    end
    if HarfordProfessions.IsRecipeLearned and HarfordProfessions.IsRecipeLearned(recipeId) then
        return false, "Ya conoces esa receta"
    end
    return true, nil, recipeId
end

function API.Teach(trainerId, recipeId)
    local ok, err, normalizedId = ValidateTeach(trainerId, recipeId)
    if not ok then return false, err end
    if not HarfordProfessions.LearnRecipe then return false, "No se puede aprender" end
    return HarfordProfessions.LearnRecipe(normalizedId)
end

-- Precio de aprendizaje en cobre. El catalogo conserva el valor exacto cuando la exportacion lo
-- trae; las recetas importadas sin precio usan una tarifa por rango para que nunca se aprendan
-- gratis solo por faltar ese metadato.
function API.GetRecipeCost(recipeId)
    local recipe = HarfordProfessions and HarfordProfessions.GetRecipe
        and HarfordProfessions.GetRecipe(recipeId)
    if not recipe then return 0 end
    if recipe.trainCost ~= nil then
        return math.max(0, math.floor(tonumber(recipe.trainCost) or 0))
    end
    if HarfordProfessions.IsStarterRecipe and HarfordProfessions.IsStarterRecipe(recipe) then
        return 0
    end
    local req = SkillReq(recipe)
    if req < 75 then return 50 end
    if req < 150 then return 500 end
    if req < 225 then return 2500 end
    if req < 300 then return 7500 end
    return 15000
end

-- Compra asincrona: primero valida la receta, luego retira el dinero y SOLO entonces aprende.
-- `callback(ok, err, recipe)` se llama exactamente una vez incluso si el transporte no existe.
-- Segundos para dar por muerta la confirmacion del servidor.
--
-- Ni este modulo, ni la economia, ni HarfordEpsilonCommands, ni EpsilonLib tienen plazo: el
-- callback se dispara cuando el servidor RESPONDE, y si calla no se dispara nunca. Sin esto la
-- ventana se quedaba con el boton apagado para siempre, porque solo lo reactiva el callback.
local PLAZO_PAGO = 8

-- Una compra en vuelo a la vez. La economia ya lo rechazaria por su lado, pero aqui la receta se
-- concede ANTES de cobrar: sin este guard, encadenar clicks concedia la segunda y la deshacia un
-- instante despues, con el parpadeo correspondiente.
local compraEnVuelo = nil

-- Compra: la receta se concede EN EL MOMENTO y el cobro se lanza a la vez.
--
-- El orden importa. Antes se esperaba la confirmacion del servidor para conceder, y eso metia
-- una espera visible en algo que para el jugador es instantaneo. Ahora se concede primero y solo
-- se DESHACE si el servidor rechaza el pago explicitamente.
--
-- Si el servidor calla no se revierte nada: no se sabe si cobro o no, y quitarle la receta a
-- alguien a quien quiza si le cobraron es peor que dejarsela. Se le avisa y que lo mire.
--
-- `callback(ok, err, recipe)` se llama exactamente una vez, pase lo que pase.
function API.Purchase(trainerId, recipeId, callback)
    callback = type(callback) == "function" and callback or function() end
    local callbackDone = false
    local function Finish(ok, err, recipe)
        if callbackDone then return end
        callbackDone = true
        compraEnVuelo = nil
        callback(ok, err, recipe)
    end

    if compraEnVuelo then
        -- NO se usa `Finish`: limpia `compraEnVuelo`, y aqui esa marca es de la compra que sigue
        -- viva. Borrarla dejaba pasar el siguiente clic y se cobraba dos veces.
        callbackDone = true
        callback(false, "Espera a que termine la compra anterior", nil)
        return false, "Hay una compra en curso"
    end

    local def = API.Get(trainerId)
    local recipe = HarfordProfessions and HarfordProfessions.GetRecipe
        and HarfordProfessions.GetRecipe(recipeId)
    if not def or not recipe then
        Finish(false, "Receta o entrenador desconocido", recipe)
        return false, "Receta o entrenador desconocido"
    end

    -- Sin coste no hay nada que confirmar: se concede y ya.
    local cost = API.GetRecipeCost(recipeId)
    if cost <= 0 then
        local ok, err = API.Teach(trainerId, recipeId)
        Finish(ok, err, recipe)
        return ok, err
    end

    if not (HarfordDnDEconomy and HarfordDnDEconomy.CanAfford and HarfordDnDEconomy.CanAfford(cost)) then
        local err = "No tienes suficiente dinero"
        Finish(false, err, recipe)
        return false, err
    end
    if not (HarfordDnDEconomy and HarfordDnDEconomy.Spend) then
        Finish(false, "No se puede cobrar el entrenamiento", recipe)
        return false, "No se puede cobrar el entrenamiento"
    end

    -- CONCEDER YA. `Teach` revalida rango, profesion, habilidad y si ya la sabes.
    compraEnVuelo = recipeId
    local learned, learnErr = API.Teach(trainerId, recipeId)
    if not learned then
        Finish(false, learnErr, recipe)
        return false, learnErr
    end

    local function Deshacer()
        if HarfordProfessions and HarfordProfessions.UnlearnRecipe then
            HarfordProfessions.UnlearnRecipe(recipeId)
        end
    end

    local sent, sendErr = HarfordDnDEconomy.Spend(cost, {
        callback = function(success, messages)
            if success then
                Finish(true, nil, recipe)
                return
            end
            Deshacer()
            Finish(false, (messages and messages[1]) or "El servidor rechazo el pago", recipe)
        end,
    })
    if not sent then
        Deshacer()
        Finish(false, sendErr or "No se pudo enviar el pago", recipe)
        return false, sendErr
    end

    -- Red de seguridad. No deshace: solo libera la ventana y lo dice.
    if C_Timer and C_Timer.After then
        C_Timer.After(PLAZO_PAGO, function()
            Finish(false, "El servidor no confirmo el pago. Comprueba tu oro.", recipe)
        end)
    end
    return true
end

-- API para el ArcSpell del gossip, con el mismo nombre publico que usan las misiones de mundo.
_G.HarfordTrainerAPI = _G.HarfordTrainerAPI or {}
_G.HarfordTrainerAPI.BindTrainer = API.Bind
_G.HarfordTrainerAPI.DefineTrainer = API.Define
_G.HarfordTrainerAPI.TeachRecipe = API.Teach
_G.HarfordTrainerAPI.PurchaseRecipe = API.Purchase
_G.HarfordTrainerAPI.GetTrainer = API.Get
