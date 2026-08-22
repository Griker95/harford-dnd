------------------------------------------------------------
-- HarfordProfessions - Core del sistema de profesiones D&D (unifica profesiones WoW + herramientas
-- D&D). Estado por-PJ, skill numerico 1-300 con tiers, y resolucion de crafteo por tirada D&D.
--
-- Reglas fijadas:
--  * Skill NUMERICO 1-300; los tiers se derivan del numero (Aprendiz/Oficial/Experto/Artesano/Maestro).
--  * "Tener la competencia de herramienta = conoces la profesion" (nivel base). Las que no tienen
--    herramienta D&D (Mineria/Pesca/etc.) se conocen al aprenderlas (skill > 0, via DM o mundo).
--  * Recetas gateadas por tier de skill; algunas `worldLearned` (no auto por nivel, se aprenden
--    fuera) y otras `trainer = "<id>"` (se compran a un entrenador; ver HarfordProfessionTrainers).
--  * MATERIALES REALES: se verifican con GetItemCount y se consumen con HarfordServerActions.RemoveItem
--    (`.additem <id> -<qty>`, verificado). El output se da con GiveItem (`.additem`).
--  * Los IDs de items viven en HarfordProfessionsItems (registro por clave); receta con material sin
--    ID registrado = "pendiente" (no crafteable) hasta que llegue el ID.
--
-- Datos (catalogo de profesiones + recetas) en HarfordProfessionsData.
------------------------------------------------------------

-- Declaracion adelantada: sin ella, la referencia de mas arriba compila como acceso a
-- un GLOBAL, que nunca se asigna y queda nil.
local SerializeDynamicRecipe

HarfordProfessions = HarfordProfessions or {}
local API = HarfordProfessions

local function print(...)
    if not (HarfordChat and HarfordChat.Print) then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    HarfordChat.Print(table.concat(parts, " "))
end

API.MAX_SKILL = 300
-- Tiers por umbral de skill (de mayor a menor al buscar).
API.TIERS = {
    { name = "Aprendiz", min = 1 },
    { name = "Oficial",  min = 75 },
    { name = "Experto",  min = 150 },
    { name = "Artesano", min = 225 },
    { name = "Maestro",  min = 300 },
}

------------------------------------------------------------
-- Persistencia (per-character)
------------------------------------------------------------
local function Store()
    HarfordProfessionsStore = HarfordProfessionsStore or {}
    HarfordProfessionsStore.skills = HarfordProfessionsStore.skills or {}   -- [profId] = skill (num)
    HarfordProfessionsStore.learned = HarfordProfessionsStore.learned or {} -- [recipeId] = true (worldLearned)
    HarfordProfessionsStore.nodeCooldowns = HarfordProfessionsStore.nodeCooldowns or {} -- [nodeGuid] = expiraEpoch
    HarfordProfessionsStore.custom = HarfordProfessionsStore.custom or {} -- [recipeId] = definicion dinamica
    return HarfordProfessionsStore
end

local function ProfileName()
    if HarfordDnD and HarfordDnDAPI and HarfordDnDAPI.GetProfileName then
        local n = HarfordDnDAPI.GetProfileName(); if n and n ~= "" then return n end
    end
    return (UnitName and UnitName("player")) or "player"
end

------------------------------------------------------------
-- Catalogo (delega en HarfordProfessionsData)
------------------------------------------------------------
local function Data() return _G.HarfordProfessionsData end
local function Items() return _G.HarfordProfessionsItems end

function API.GetProfessions()
    local d = Data()
    return (d and d.PROFESSIONS) or {}
end

function API.GetDefinition(profId)
    profId = tostring(profId or "")
    for _, p in ipairs(API.GetProfessions()) do
        if p.id == profId then return p end
    end
    return nil
end

function API.GetRecipes(profId)
    profId = tostring(profId or "")
    local out = {}
    local d = Data()
    for _, r in ipairs((d and d.RECIPES) or {}) do
        if r.profession == profId then out[#out + 1] = r end
    end
    -- Recetas DINAMICAS del personaje (ver DefineRecipe): viven en la SavedVariable, no en el
    -- catalogo, y se comportan igual que cualquier otra a partir de aqui.
    for _, r in pairs(Store().custom) do
        if type(r) == "table" and r.profession == profId then out[#out + 1] = r end
    end
    return out
end

-- Indice id -> receta del catalogo. Se construye una vez: GetRecipe se llama una vez por fila
-- visible en cada refresco de la ventana (y el buscador refresca en cada tecla), asi que el
-- recorrido lineal sobre las 230 recetas se notaba.
local recipeIndex
local function RecipeIndex()
    local d = Data()
    local list = (d and d.RECIPES) or {}
    if not recipeIndex or recipeIndex.count ~= #list then
        recipeIndex = { count = #list, byId = {} }
        for _, r in ipairs(list) do recipeIndex.byId[r.id] = r end
    end
    return recipeIndex.byId
end

function API.GetRecipe(recipeId)
    recipeId = tostring(recipeId or "")
    local custom = Store().custom[recipeId]
    if type(custom) == "table" then return custom end
    return RecipeIndex()[recipeId]
end

------------------------------------------------------------
-- Skill / tiers / conocer
------------------------------------------------------------
function API.GetSkill(profId)
    return tonumber(Store().skills[tostring(profId or "")]) or 0
end

function API.SetSkill(profId, value)
    profId = tostring(profId or "")
    if profId == "" then return end
    value = math.max(0, math.min(API.MAX_SKILL, math.floor(tonumber(value) or 0)))
    Store().skills[profId] = value > 0 and value or nil
end

-- ¿Conoce la profesion? Por competencia de herramienta (auto) o por skill aprendido (>0).
function API.KnowsProfession(profId)
    if API.GetSkill(profId) > 0 then return true end
    local def = API.GetDefinition(profId)
    if def and def.tool and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasToolProf
        and HarfordDnDFeatureEffects.HasToolProf(def.tool, ProfileName()) then
        return true
    end
    return false
end

-- Skill efectivo: si conoce por competencia pero no tiene skill guardado, cuenta como 1 (base).
function API.EffectiveSkill(profId)
    local s = API.GetSkill(profId)
    if s > 0 then return s end
    return API.KnowsProfession(profId) and 1 or 0
end

function API.GetTierName(skill)
    skill = tonumber(skill) or 0
    local name = "-"
    for _, t in ipairs(API.TIERS) do
        if skill >= t.min then name = t.name end
    end
    return name
end

-- Instantanea segura para UI externa/Arcanum. No devuelve la persistencia interna.
function API.GetStationInfo(profId)
    profId = tostring(profId or ""):lower()
    local def = API.GetDefinition(profId)
    if not def then return nil end
    local skill = API.EffectiveSkill(profId)
    return {
        id = def.id,
        name = def.name,
        kind = def.kind,
        known = API.KnowsProfession(profId),
        skill = skill,
        tier = API.GetTierName(skill),
    }
end

-- Entrada publica para un Spark/ArcSpell de estacion. El argumento es SIEMPRE el id
-- de profesion ("herreria", "alquimia"...), nunca un tipo de objeto como "forja".
function API.OpenStation(profId)
    profId = tostring(profId or ""):lower()
    local info = API.GetStationInfo(profId)
    if not info then
        print("|cffff5555Estacion mal configurada: profesion desconocida (" .. profId .. ").|r")
        return false, "Profesion desconocida: " .. profId
    end
    if not (HarfordCharacterPanel and HarfordCharacterPanel.OpenProfession) then
        print("|cffff5555No se pudo abrir la estacion: panel de profesiones no disponible.|r")
        return false, "Panel de profesiones no disponible"
    end
    return HarfordCharacterPanel.OpenProfession(profId)
end

------------------------------------------------------------
-- Tirada de la profesion (competencia herramienta + caracteristica)
------------------------------------------------------------
local function ProfBonusIfTool(def)
    if not (def and def.tool) then return 0 end
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasToolProf
        and HarfordDnDFeatureEffects.HasToolProf(def.tool, ProfileName())
        and HarfordDnDCalc and HarfordDnDCalc.GetProficiencyBonus then
        return tonumber(HarfordDnDCalc.GetProficiencyBonus()) or 0
    end
    return 0
end

local function AbilityMod(ability)
    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and ability then
        return tonumber(HarfordDnDCalc.GetAbilityMod(ability)) or 0
    end
    return 0
end

------------------------------------------------------------
-- Materiales (registro de items)
--
-- RESERVA DE MATERIAL EN VUELO. `RemoveItem` es un comando de servidor ASINCRONO: entre que se
-- craftea y que el servidor descuenta, `GetItemCount` sigue devolviendo el valor viejo. Sin esto,
-- craftear en rafaga (o repulsar "Crear todo") permitiria fabricar mas de lo que los materiales
-- dan de si, porque cada comprobacion leeria bolsas sin actualizar.
--
-- Solucion: al craftear se APUNTA lo consumido como reservado y `InspectMaterials` lo resta del
-- `have`. La reserva de una clave se libera cuando las bolsas confirman el descuento (BAG_UPDATE
-- con recuento ya por debajo del esperado) o, como red de seguridad si el comando se perdio, al
-- expirar RESERVE_TTL. No es un tick: son eventos + un one-shot.
------------------------------------------------------------
local RESERVE_TTL = 15
local reserved = {}  -- key -> { qty = <en vuelo>, expected = <recuento objetivo>, at = <time> }

local function ReservedQty(key)
    local r = reserved[key]
    return r and r.qty or 0
end

local function ReleaseSettledReservations()
    local items = Items()
    if not items then return end
    local now = time()
    for key, r in pairs(reserved) do
        local have = items.GetOwnedCount(key) or 0
        if have <= (r.expected or 0) or (now - (r.at or now)) >= RESERVE_TTL then
            reserved[key] = nil
        end
    end
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("BAG_UPDATE_DELAYED")
    watcher:RegisterEvent("BAG_UPDATE")
    watcher:SetScript("OnEvent", ReleaseSettledReservations)
end

-- Deshace la reserva de una receta (crafteo abortado: el material nunca se gasto).
local function ReleaseMaterials(recipe)
    for _, m in ipairs((recipe and recipe.materials) or {}) do
        local r = reserved[m.key]
        if r then
            r.qty = r.qty - (tonumber(m.qty) or 1)
            if r.qty <= 0 then reserved[m.key] = nil end
        end
    end
end

-- Apunta como en vuelo lo que acaba de gastar un crafteo.
local function ReserveMaterials(recipe)
    local items = Items()
    if not items then return end
    for _, m in ipairs((recipe and recipe.materials) or {}) do
        local qty = tonumber(m.qty) or 1
        local prev = reserved[m.key]
        local have = items.GetOwnedCount(m.key) or 0
        reserved[m.key] = {
            qty = (prev and prev.qty or 0) + qty,
            expected = math.max(0, have - qty),
            at = time(),
        }
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(RESERVE_TTL + 1, ReleaseSettledReservations)
    end
end

-- Devuelve: resolvable(bool, todos los materiales tienen ID), enough(bool, hay cantidad suficiente),
-- y una lista detallada por material { key, name, need, have, id, missingId }.
local function InspectMaterials(recipe)
    local items = Items()
    local detail, resolvable, enough = {}, true, true
    for _, m in ipairs((recipe and recipe.materials) or {}) do
        local id = items and items.GetId(m.key)
        -- El material ya comprometido por un crafteo anterior no vuelve a contar como disponible.
        local have = math.max(0, ((items and items.GetOwnedCount(m.key)) or 0) - ReservedQty(m.key))
        local need = tonumber(m.qty) or 1
        if not id then resolvable = false end
        if have < need then enough = false end
        detail[#detail + 1] = {
            key = m.key, name = (items and items.GetName(m.key)) or m.key,
            need = need, have = have, id = id, missingId = (id == nil),
        }
    end
    return resolvable, enough, detail
end

-- ¿Se puede intentar craftear? Devuelve ok, razon.
function API.CanCraft(recipeId)
    local r = API.GetRecipe(recipeId)
    if not r then return false, "Receta desconocida" end
    if not API.KnowsProfession(r.profession) then return false, "No conoces esa profesion" end
    if API.EffectiveSkill(r.profession) < (tonumber(r.skillReq) or 1) then
        return false, "Skill insuficiente (requiere " .. tostring(r.skillReq) .. ")"
    end
    if r.worldLearned and not Store().learned[r.id] then
        return false, "Receta no aprendida (se obtiene en el mundo)"
    end
    -- Receta de ENTRENADOR: no viene con el nivel de habilidad, hay que aprenderla de el.
    -- El motivo dice DONDE, que es lo unico accionable para el jugador.
    local deEntrenador = r.trainer
        or (HarfordProfessionTrainers and HarfordProfessionTrainers.IsTaught
            and HarfordProfessionTrainers.IsTaught(r.id))
    if deEntrenador and not Store().learned[r.id] then
        local donde = HarfordProfessionTrainers and HarfordProfessionTrainers.DescribeForRecipe
            and HarfordProfessionTrainers.DescribeForRecipe(r.id)
        return false, donde and ("La ensena " .. donde) or "Receta de entrenador (aun no aprendida)"
    end
    local resolvable, enough, detail = InspectMaterials(r)
    if not resolvable then return false, "Materiales pendientes de ID (aun no crafteable)", detail end
    local outId = Items() and Items().GetId(r.output and r.output.key)
    if not outId then return false, "Resultado pendiente de ID", detail end
    if not enough then return false, "Faltan materiales", detail end
    return true, nil, detail
end

-- Marca una receta worldLearned como aprendida (DM / hallazgo).
-- ¿Esta aprendida? Las recetas normales van con la profesion; las worldLearned requieren
-- que el DM las haya enseñado (LearnRecipe/TEACH).
-- ¿Se ha aprendido EXPLICITAMENTE (de un entrenador o por hallazgo)? Es otra pregunta distinta
-- de `IsRecipeLearned`, que responde "puedes usarla" y por tanto devuelve true SIEMPRE para una
-- receta que no esta restringida. La ventana del entrenador necesita esta: con la otra pintaba
-- "Ya la conoces" en todas las filas y dejaba `Aprender` en gris para siempre.
function API.HasLearnedRecipe(recipeId)
    return Store().learned[tostring(recipeId or "")] == true
end

function API.IsRecipeLearned(recipeId)
    local r = API.GetRecipe(recipeId)
    if not r then return false end
    local deEntrenador = r.trainer
        or (HarfordProfessionTrainers and HarfordProfessionTrainers.IsTaught
            and HarfordProfessionTrainers.IsTaught(recipeId))
    if not (r.worldLearned or deEntrenador) then return true end
    return Store().learned[tostring(recipeId)] == true
end

-- Tirada suelta de la herramienta de la profesion (sin receta ni CD): d20 + competencia de
-- herramienta (si la tiene) + modificador de la caracteristica. Es la prueba de "uso de
-- herramientas" de 5e, independiente de fabricar; la regla vive aqui, no en la UI.
function API.RollTool(profId)
    local def = API.GetDefinition(profId)
    if not def then return false end
    local d20 = math.random(1, 20)
    local bonus = ProfBonusIfTool(def) + AbilityMod(def.ability)
    local total = d20 + bonus
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = def.tool or def.name,
            total = total,
            dice = "d20: " .. d20,
            modifiers = bonus ~= 0 and string.format("%s%d", bonus > 0 and "+" or "", bonus) or "",
            critical = d20 == 20 and "CRITICO" or (d20 == 1 and "FALLO" or nil),
        })
    end
    return true, total
end

------------------------------------------------------------
-- RECETAS DINAMICAS (fuera del catalogo)
--
-- Para contenido puntual que no tiene sentido hornear en HarfordProfessionsData: un plano que
-- suelta un jefe, una receta de evento, una recompensa de mision. Un ArcSpell/gossip llama a
-- `TeachCustomRecipe` y la receta queda definida Y aprendida en ese personaje, persistida en su
-- SavedVariable. A partir de ahi se comporta como cualquier otra: sale en la ventana, comprueba
-- materiales, tira en mesa y sube skill.
--
-- Los materiales y el resultado se pueden dar por ITEM ID directo (lo normal en contenido
-- suelto) o por clave del registro. Los itemId se registran al vuelo con una clave sintetica,
-- de modo que el resto del sistema no necesita saber que la receta es dinamica.
--
-- Ejemplo para un ArcSpell:
--   HarfordProfessions.TeachCustomRecipe({
--       id = "plano_espada_rota", profession = "herreria", name = "Espada rota reforjada",
--       skillReq = 60, dc = 13, icon = "INV_Sword_04",
--       materials = { { id = 14074638, qty = 2, name = "Barra de cobre" } },
--       output = { id = 14074640, qty = 1, name = "Espada reforjada" },
--   })
------------------------------------------------------------

-- Convierte { id = N, name = "..." } en una clave del registro, registrandola si hace falta.
local function ResolveDynamicKey(entry, fallbackName)
    if type(entry) ~= "table" then return nil end
    if entry.key and tostring(entry.key) ~= "" then return tostring(entry.key) end
    local id = tonumber(entry.id)
    if not id then return nil end
    local key = "din_" .. id
    local items = Items()
    if items and items.Set then
        items.Set(key, id, entry.name or fallbackName or ("Objeto " .. id), entry.icon)
    end
    return key
end

-- Registra (o actualiza) una receta dinamica. NO la marca como aprendida.
function API.DefineRecipe(def)
    if type(def) ~= "table" then return false, "Definicion invalida" end
    local id = tostring(def.id or "")
    local profession = tostring(def.profession or "")
    if id == "" then return false, "Falta el id de la receta" end
    if not API.GetDefinition(profession) then
        return false, "Profesion desconocida: " .. profession
    end
    -- Un id del catalogo no se puede pisar: romperia las recetas horneadas de todos.
    local d = Data()
    for _, r in ipairs((d and d.RECIPES) or {}) do
        if r.id == id then return false, "Ese id ya existe en el catalogo: " .. id end
    end
    local outKey = ResolveDynamicKey(def.output, def.name)
    if not outKey then return false, "El resultado necesita `key` o `id`" end

    local materials = {}
    local outQty = math.max(1, math.floor(tonumber(def.output.qty) or 1))
    for _, m in ipairs(def.materials or {}) do
        local key = ResolveDynamicKey(m)
        if not key then return false, "Un material no tiene `key` ni `id`" end
        local qty = math.max(1, math.floor(tonumber(m.qty) or 1))
        -- Una receta que devuelve MAS unidades del mismo objeto que consume es dinero infinito.
        -- Se rechaza aqui porque estas recetas las inyecta contenido del mundo, no el catalogo.
        if key == outKey and outQty >= qty then
            return false, "La receta produciria mas de lo que consume del mismo objeto"
        end
        materials[#materials + 1] = { key = key, qty = qty }
    end
    if #materials == 0 then
        local prof = API.GetDefinition(profession)
        if not (prof and prof.kind == "gather") then
            return false, "Una receta que no es de recoleccion necesita materiales"
        end
    end

    Store().custom[id] = {
        id = id,
        profession = profession,
        name = tostring(def.name or id),
        icon = def.icon,
        skillReq = math.max(1, math.min(API.MAX_SKILL, math.floor(tonumber(def.skillReq) or 1))),
        dc = math.max(5, math.min(30, math.floor(tonumber(def.dc) or 12))),
        ability = def.ability,
        worldLearned = true,   -- una receta suelta SIEMPRE hay que aprenderla
        dynamic = true,
        materials = materials,
        output = { key = outKey, qty = outQty },
        definedAt = (time and time()) or 0,
        description = def.description,
    }
    API.PruneCustomRecipes()
    return true
end

-- Define y aprende de una vez: es la puerta pensada para ArcSpell/gossip.
function API.TeachCustomRecipe(def)
    local ok, err = API.DefineRecipe(def)
    if not ok then
        print("|cffff5555No se pudo enseñar la receta:|r " .. tostring(err))
        return false, err
    end
    local id = tostring(def.id)
    local already = Store().learned[id] == true
    Store().learned[id] = true
    local recipe = API.GetRecipe(id)
    if not already then
        print(string.format("Has aprendido |cffffd100%s|r (%s).", recipe.name,
            (API.GetDefinition(recipe.profession) or {}).name or recipe.profession))
        if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("craft_succeeded") end
    end
    if HarfordProfessionsCraftUI and HarfordProfessionsCraftUI.Refresh then
        HarfordProfessionsCraftUI.Refresh()
    end
    return true
end

-- Retira una receta dinamica de este personaje (no toca el catalogo).
function API.ForgetCustomRecipe(recipeId)
    recipeId = tostring(recipeId or "")
    if not Store().custom[recipeId] then return false end
    Store().custom[recipeId] = nil
    Store().learned[recipeId] = nil
    if HarfordProfessionsCraftUI and HarfordProfessionsCraftUI.Refresh then
        HarfordProfessionsCraftUI.Refresh()
    end
    return true
end

-- Poda de recetas dinamicas: la SavedVariable no puede crecer sin limite con recetas de
-- evento. Se quitan primero las que ni siquiera llegaron a aprenderse, de la mas antigua a la
-- mas nueva. Devuelve cuantas se han retirado.
local MAX_CUSTOM_RECIPES = 100
function API.PruneCustomRecipes(limit)
    limit = tonumber(limit) or MAX_CUSTOM_RECIPES
    local custom = Store().custom
    local entries = {}
    for id, r in pairs(custom) do
        if type(r) == "table" then
            entries[#entries + 1] = { id = id, at = tonumber(r.definedAt) or 0,
                                      learned = Store().learned[id] == true }
        end
    end
    if #entries <= limit then return 0 end
    -- Orden de sacrificio: sin aprender antes que aprendidas, y dentro de cada grupo la mas vieja.
    table.sort(entries, function(a, b)
        if a.learned ~= b.learned then return not a.learned end
        return a.at < b.at
    end)
    local removed = 0
    for i = 1, #entries - limit do
        custom[entries[i].id] = nil
        Store().learned[entries[i].id] = nil
        removed = removed + 1
    end
    return removed
end

-- Lista de recetas dinamicas del personaje (copia, para UI/debug).
function API.GetCustomRecipes()
    local out = {}
    for id, r in pairs(Store().custom) do
        if type(r) == "table" then
            out[#out + 1] = { id = id, name = r.name, profession = r.profession,
                              skillReq = r.skillReq, learned = Store().learned[id] == true }
        end
    end
    table.sort(out, function(a, b) return tostring(a.id) < tostring(b.id) end)
    return out
end

-- Copia del material en vuelo (solo diagnostico: no exponer la tabla interna).
function API.GetReservedMaterials()
    ReleaseSettledReservations()
    local out = {}
    for key, r in pairs(reserved) do
        out[key] = { qty = r.qty, expected = r.expected, at = r.at }
    end
    return out
end

-- Item id del resultado de una receta (para iconos/tooltips de UI).
function API.GetOutputItemId(recipeId)
    local r = API.GetRecipe(recipeId)
    local items = Items()
    if r and items and r.output then return items.GetId(r.output.key) end
    return nil
end

function API.LearnRecipe(recipeId)
    recipeId = tostring(recipeId or "")
    if API.GetRecipe(recipeId) then Store().learned[recipeId] = true; return true end
    return false
end

-- Sube skill al craftear con exito, estilo WoW: solo si aun aprendes de la receta (skill por debajo
-- del umbral "gris" = skillReq + 100) y por debajo del maximo.
local function SkillUp(profId, recipe)
    local cur = API.GetSkill(profId)
    -- Primer craft (conocia por competencia, skill 0): persiste el punto base = 1 (no saltar a 2).
    if cur <= 0 then API.SetSkill(profId, 1); return end
    local grey = (tonumber(recipe.skillReq) or 1) + 100
    if cur < API.MAX_SKILL and cur < grey then
        API.SetSkill(profId, cur + 1)
    end
end

-- Ejecuta el crafteo: tirada, consumo de materiales reales y entrega del output.
function API.Craft(recipeId)
    local ok, reason, detail = API.CanCraft(recipeId)
    if not ok then print("|cffff5555" .. tostring(reason) .. "|r"); return false, reason end
    local r = API.GetRecipe(recipeId)
    local def = API.GetDefinition(r.profession)
    local items = Items()
    local server = HarfordServerActions
    -- Sin canal de servidor no se puede ni descontar ni entregar: se avisa ANTES de tirar, para
    -- no gastar la tirada ni dejar el crafteo a medias.
    if not (server and server.RemoveItem and server.GiveItem) then
        print("|cffff5555No hay canal de servidor: no se puede fabricar ahora.|r")
        return false, "sin canal de servidor"
    end

    -- Tirada: d20 + competencia (si tiene la herramienta) + mod. caracteristica.
    local ability = r.ability or (def and def.ability) or "Inteligencia"
    local d20 = math.random(1, 20)
    local bonus = ProfBonusIfTool(def) + AbilityMod(ability)
    local total = d20 + bonus
    local dc = tonumber(r.dc) or 10
    local crit = (d20 == 20)
    local success = crit or (d20 ~= 1 and total >= dc)

    local outName = items.GetName(r.output.key)

    -- El crafteo es una ACCION REAL: se tira en mesa como cualquier otra prueba, no se
    -- resuelve en el chat local del artesano. Se emite siempre, salga bien o mal.
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = string.format("%s: %s (CD %d)", def and def.name or r.profession,
                r.name or outName, dc),
            total = total,
            dice = "d20: " .. d20,
            modifiers = bonus ~= 0 and string.format("%s%d", bonus > 0 and "+" or "", bonus) or "",
            critical = crit and "CRITICO" or (d20 == 1 and "FALLO" or nil),
        })
    end

    local function Announce(text)
        if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
            HarfordDnDRolls.Broadcast({ type = "info", label = text })
        else
            HarfordChat.Print(text)
        end
    end

    if not success then
        -- Fallo: por defecto NO gasta materiales (mas amable para RP). Cambiar si se quiere coste.
        Announce(string.format("falla al fabricar %s.", r.name or outName))
        return false, "fallo"
    end

    -- Consumir materiales reales. Se reservan ANTES de emitir los comandos: hasta que el servidor
    -- confirme el descuento, esa cantidad deja de contar como disponible para el siguiente crafteo.
    ReserveMaterials(r)
    -- Los comandos DEVUELVEN (ok, err) y hay que mirarlos: si el descuento falla y seguimos,
    -- el personaje se queda el objeto sin pagar los materiales y ademas sube skill.
    local consumed, failure = {}, nil
    for _, m in ipairs(r.materials or {}) do
        local id = items.GetId(m.key)
        local qty = tonumber(m.qty) or 1
        local okRemove, removeErr = server.RemoveItem(id, qty)
        if okRemove then
            consumed[#consumed + 1] = { id = id, qty = qty }
        else
            failure = removeErr or "no se pudo descontar " .. tostring(items.GetName(m.key))
            break
        end
    end
    if failure then
        -- Devolver lo ya descontado para no dejar al personaje a medias, y liberar la reserva.
        for _, c in ipairs(consumed) do server.GiveItem(c.id, c.qty) end
        ReleaseMaterials(r)
        print("|cffff5555Crafteo cancelado: " .. tostring(failure) .. "|r")
        return false, failure
    end

    -- Entregar output (doble en critico).
    local outId = items.GetId(r.output.key)
    local outQty = (tonumber(r.output.qty) or 1) * (crit and 2 or 1)
    local okGive, giveErr = server.GiveItem(outId, outQty)
    if not okGive then
        -- Los materiales YA se gastaron: se avisa claramente en vez de fingir que salio bien.
        print("|cffff5555Se gastaron los materiales pero no se pudo entregar " ..
            tostring(outName) .. ": " .. tostring(giveErr) .. ". Avisa al DM.|r")
        return false, giveErr
    end

    SkillUp(r.profession, r)
    Announce(string.format("fabrica %s x%d.%s", outName, outQty,
        crit and " |cffffd100Obra maestra: produccion doble.|r" or ""))
    return true
end

------------------------------------------------------------
-- Nodos de recoleccion en el mundo (vetas, plantas, bancos de peces).
--
-- El DM coloca un NPC/objeto de fase y su gossip ejecuta un ArcSpell que llama:
--     HarfordProfessions.GatherNode("min_cobre", 300)
-- (recipeId de una profesion de RECOLECCION + cooldown en segundos, opcional, 300 por defecto).
--
-- Mismo patron que HarfordWorldQuests: la identidad del nodo es el GUID de la unidad del gossip,
-- asi que hace falta tener el nodo como unidad activa (npc/target). El cooldown es POR NODO Y POR
-- PERSONAJE, persiste en HarfordProfessionsStore.nodeCooldowns y se aplica AL INTENTO (exito o
-- fallo): la tirada ya se hizo, el nodo queda "trabajado" y no se puede reintentar en bucle.
-- La tirada, materiales, entrega y anuncio son los de Craft(); esto solo añade la puerta de nodo.
------------------------------------------------------------
-- Clave estable de un nodo. El GUID completo lleva servidor/instancia, que pueden cambiar
-- tras un reinicio y regalarian el cooldown. De "Creature-0-serv-inst-zona-NPCID-spawnUID" nos
-- quedamos con NPCID y spawnUID, que identifican al nodo y sobreviven al reinicio.
local function NodeKey(guid)
    if not guid or guid == "" then return nil end
    local npcId, spawnUid = tostring(guid):match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-(%w+)$")
    if npcId and spawnUid then return npcId .. ":" .. spawnUid end
    return guid
end

local function PruneNodeCooldowns()
    local cooldowns = Store().nodeCooldowns
    local now = time and time() or 0
    for guid, expira in pairs(cooldowns) do
        if (tonumber(expira) or 0) <= now then cooldowns[guid] = nil end
    end
end

function API.GatherNode(recipeId, cooldownSeconds)
    local r = API.GetRecipe(recipeId)
    if not r then print("|cffff5555Nodo mal configurado: receta desconocida (" .. tostring(recipeId) .. ").|r") return false end
    local def = API.GetDefinition(r.profession)
    if not (def and def.kind == "gather") then
        print("|cffff5555Los nodos de mundo son solo de recoleccion (" .. tostring(r.profession) .. " no lo es).|r")
        return false
    end
    local guid = (UnitExists and UnitExists("npc") and UnitGUID and UnitGUID("npc"))
        or (UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target"))
    guid = NodeKey(guid)
    if not guid then
        print("|cffff5555No se detecta el nodo: interactua con la veta/planta (gossip o target).|r")
        return false
    end
    PruneNodeCooldowns()
    local cooldowns = Store().nodeCooldowns
    local now = time and time() or 0
    local expira = tonumber(cooldowns[guid]) or 0
    if expira > now then
        local resta = expira - now
        print(string.format("|cffffcc00Este nodo ya esta trabajado. Vuelve en %d min %d s.|r",
            math.floor(resta / 60), resta % 60))
        return false
    end
    -- Validar ANTES de consumir el nodo: si el personaje no puede ni intentarlo (no conoce la
    -- profesion, skill corto, item pendiente de ID), Craft avisara pero el nodo no debe gastarse.
    local puede, motivo = API.CanCraft(recipeId)
    if not puede then
        print("|cffff5555" .. tostring(motivo) .. "|r")
        return false
    end
    -- El INTENTO consume el nodo aunque la tirada falle: sin reintentos en bucle.
    cooldowns[guid] = now + math.max(30, math.floor(tonumber(cooldownSeconds) or 300))
    local ok = API.Craft(recipeId)
    return ok and true or false
end

------------------------------------------------------------
-- Enseñar recetas `worldLearned` (los remates a skill 300: planos, formulas, tomos).
--
-- El DM (HarfordAdmin + .ph dm) targetea al jugador y usa el menu de unidad
-- ("Profesiones > Enseñar receta") o llama `HarfordProfessions.TeachRecipe(nombre, recipeId)`.
-- Viaja como `TEACH|recipeId` por el prefix propio HARFORDPROF (WHISPER). El receptor solo
-- concede un beneficio (marcar la receta como aprendida), asi que basta el filtro estandar de
-- remitente reconocido; el gate de DM esta en el EMISOR, como en QDONE de las misiones.
------------------------------------------------------------
local COMM_PREFIX = "HARFORDPROF"

-- Recetas que se pueden enseñar (las marcadas worldLearned), para el menu del DM.
function API.GetTeachableRecipes()
    local out = {}
    for _, recipe in ipairs((Data() and Data().RECIPES) or {}) do
        if recipe.worldLearned then out[#out + 1] = recipe end
    end
    -- Las dinamicas tambien se pueden enseñar: viajan con su definicion completa.
    for _, recipe in pairs(Store().custom) do
        if type(recipe) == "table" then out[#out + 1] = recipe end
    end
    table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return out
end

function API.TeachRecipe(targetName, recipeId)
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        print("|cffff5555Enseñar recetas requiere HarfordAdmin y .ph dm activo.|r")
        return false
    end
    local recipe = API.GetRecipe(recipeId)
    if not recipe then print("|cffff5555Receta desconocida: " .. tostring(recipeId) .. "|r") return false end
    if not recipe.worldLearned then
        print("|cffff5555Esa receta se aprende sola por skill; solo se enseñan las worldLearned.|r")
        return false
    end
    targetName = tostring(targetName or "")
    if targetName == "" then print("|cffff5555Falta el nombre del jugador.|r") return false end
    if not (HarfordSync and HarfordSync.Send) then print("|cffff5555HarfordSync no disponible.|r") return false end

    -- Una receta del catalogo viaja por id (el receptor ya la tiene); una DINAMICA tiene que
    -- viajar entera, porque en el otro cliente no existe.
    local payload = "TEACH|" .. tostring(recipe.id)
    if recipe.dynamic then
        local serialized, serErr = SerializeDynamicRecipe(recipe)
        if not serialized then
            print("|cffff5555No se pudo enviar la receta: " .. tostring(serErr) .. "|r")
            return false, serErr
        end
        payload = serialized
    end
    local ok, err = HarfordSync.Send(COMM_PREFIX, payload, "WHISPER", targetName)
    if ok then
        print(string.format("Receta |cffffd100%s|r enseñada a |cffffcc00%s|r.", tostring(recipe.name), targetName))
    else
        print("|cffff5555No se pudo enviar: " .. tostring(err) .. "|r")
    end
    return ok and true or false
end

-- SERIALIZACION DE UNA RECETA DINAMICA
--
-- `TEACH|id` no sirve para las dinamicas: el receptor buscaria ese id en SU catalogo y no lo
-- encontraria, porque la receta solo existe en el cliente que la definio. Para repartirlas se
-- envia la DEFINICION entera en un solo mensaje:
--
--   TEACHDEF|id|profesion|skillReq|dc|icono|outItemId:qty|matId:qty,matId:qty|nombre
--
-- El nombre va el ULTIMO para que pueda contener cualquier cosa menos `|`. Si no cabe en el
-- limite de SendAddonMessage se avisa en vez de mandar un mensaje truncado que el receptor
-- interpretaria mal.
local MAX_TEACH_BYTES = 240

SerializeDynamicRecipe = function(recipe)
    local items = Items()
    if not items then return nil, "Registro de items no disponible" end
    local outId = items.GetId(recipe.output.key)
    if not outId then return nil, "El resultado no tiene itemId real" end
    local mats = {}
    for _, m in ipairs(recipe.materials or {}) do
        local id = items.GetId(m.key)
        if not id then return nil, "Un material no tiene itemId real" end
        mats[#mats + 1] = id .. ":" .. tostring(m.qty or 1)
    end
    local name = tostring(recipe.name or recipe.id):gsub("|", "/")
    local payload = table.concat({
        "TEACHDEF", recipe.id, recipe.profession, recipe.skillReq or 1, recipe.dc or 12,
        recipe.icon or "", outId .. ":" .. tostring(recipe.output.qty or 1),
        table.concat(mats, ","), name,
    }, "|")
    if #payload > MAX_TEACH_BYTES then
        return nil, "La receta no cabe en un mensaje (acorta el nombre o los materiales)"
    end
    return payload
end

local function ParseDynamicRecipe(message)
    local id, prof, skill, dc, icon, out, mats, name =
        message:match("^TEACHDEF|([^|]+)|([^|]+)|(%d+)|(%d+)|([^|]*)|([^|]+)|([^|]*)|(.+)$")
    if not (id and prof and out) then return nil end
    local outId, outQty = out:match("^(%d+):(%d+)$")
    if not outId then return nil end
    local materials = {}
    for entry in tostring(mats):gmatch("[^,]+") do
        local mid, mqty = entry:match("^(%d+):(%d+)$")
        if not mid then return nil end
        materials[#materials + 1] = { id = tonumber(mid), qty = tonumber(mqty) }
    end
    return {
        id = id, profession = prof, name = name,
        skillReq = tonumber(skill), dc = tonumber(dc),
        icon = icon ~= "" and icon or nil,
        materials = materials,
        output = { id = tonumber(outId), qty = tonumber(outQty) },
    }
end

local function IsTrustedSender(sender)
    sender = tostring(sender or "")
    if sender == "" then return false end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(sender) ~= nil
    end
    return false
end

local comm = CreateFrame("Frame")
comm:RegisterEvent("PLAYER_LOGIN")
comm:RegisterEvent("CHAT_MSG_ADDON")
comm:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(COMM_PREFIX)
        end
        return
    end
    if prefix ~= COMM_PREFIX then return end
    if not IsTrustedSender(sender) then return end
    message = tostring(message or "")
    if message:find("^TEACHDEF|") then
        -- Receta dinamica completa: se define en este cliente y se aprende. DefineRecipe aplica
        -- sus propias validaciones (profesion conocida, no pisar el catalogo, nada de dinero
        -- infinito), asi que un mensaje mal formado no puede colar contenido invalido.
        local def = ParseDynamicRecipe(message)
        if not def then return end
        if Store().learned[def.id] and Store().custom[def.id] then return end
        if API.TeachCustomRecipe(def) then
            local who = (Ambiguate and Ambiguate(tostring(sender), "short")) or tostring(sender)
            print("(enseñada por " .. who .. ")")
        end
        return
    end
    local recipeId = message:match("^TEACH|([^|]+)$")
    if not recipeId then return end
    local recipe = API.GetRecipe(recipeId)
    if not (recipe and recipe.worldLearned) then return end
    if Store().learned[recipeId] then
        print(string.format("Ya conocias la receta |cffffd100%s|r.", tostring(recipe.name)))
        return
    end
    API.LearnRecipe(recipeId)
    local short = (Ambiguate and Ambiguate(tostring(sender), "short")) or tostring(sender)
    print(string.format("|cff38d26aHas aprendido la receta:|r |cffffd100%s|r (enseñada por %s).",
        tostring(recipe.name), short))
end)
