------------------------------------------------------------
-- HarfordProfessions - Core del sistema de profesiones D&D (unifica profesiones WoW + herramientas
-- D&D). Estado por-PJ, skill numerico 1-300 con tiers, y resolucion de crafteo por tirada D&D.
--
-- Reglas fijadas:
--  * Skill NUMERICO 1-300; los tiers se derivan del numero (Aprendiz/Oficial/Experto/Artesano/Maestro).
--  * "Tener la competencia de herramienta = conoces la profesion" (nivel base). Las que no tienen
--    herramienta D&D (Mineria/Pesca/etc.) se conocen al aprenderlas (skill > 0, via DM o mundo).
--  * Recetas gateadas por tier de skill; algunas `worldLearned` (no auto por nivel, se aprenden fuera).
--  * MATERIALES REALES: se verifican con GetItemCount y se consumen con HarfordServerActions.RemoveItem
--    (`.additem <id> -<qty>`, verificado). El output se da con GiveItem (`.additem`).
--  * Los IDs de items viven en HarfordProfessionsItems (registro por clave); receta con material sin
--    ID registrado = "pendiente" (no crafteable) hasta que llegue el ID.
--
-- Datos (catalogo de profesiones + recetas) en HarfordProfessionsData.
------------------------------------------------------------

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
    return out
end

function API.GetRecipe(recipeId)
    recipeId = tostring(recipeId or "")
    local d = Data()
    for _, r in ipairs((d and d.RECIPES) or {}) do
        if r.id == recipeId then return r end
    end
    return nil
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
------------------------------------------------------------
-- Devuelve: resolvable(bool, todos los materiales tienen ID), enough(bool, hay cantidad suficiente),
-- y una lista detallada por material { key, name, need, have, id, missingId }.
local function InspectMaterials(recipe)
    local items = Items()
    local detail, resolvable, enough = {}, true, true
    for _, m in ipairs((recipe and recipe.materials) or {}) do
        local id = items and items.GetId(m.key)
        local have = (items and items.GetOwnedCount(m.key)) or 0
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
    local resolvable, enough, detail = InspectMaterials(r)
    if not resolvable then return false, "Materiales pendientes de ID (aun no crafteable)", detail end
    local outId = Items() and Items().GetId(r.output and r.output.key)
    if not outId then return false, "Resultado pendiente de ID", detail end
    if not enough then return false, "Faltan materiales", detail end
    return true, nil, detail
end

-- Marca una receta worldLearned como aprendida (DM / hallazgo).
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

    -- Tirada: d20 + competencia (si tiene la herramienta) + mod. caracteristica.
    local ability = r.ability or (def and def.ability) or "Inteligencia"
    local d20 = math.random(1, 20)
    local bonus = ProfBonusIfTool(def) + AbilityMod(ability)
    local total = d20 + bonus
    local dc = tonumber(r.dc) or 10
    local crit = (d20 == 20)
    local success = crit or (d20 ~= 1 and total >= dc)

    local outName = items.GetName(r.output.key)
    local line = string.format("%s: %d + %d = %d vs CD %d",
        r.name or outName, d20, bonus, total, dc)

    if not success then
        print("|cffff5555Fallo.|r " .. line)
        -- Fallo: por defecto NO gasta materiales (mas amable para RP). Cambiar si se quiere coste.
        return false, "fallo"
    end

    -- Consumir materiales reales.
    for _, m in ipairs(r.materials or {}) do
        local id = items.GetId(m.key)
        if id and server and server.RemoveItem then server.RemoveItem(id, tonumber(m.qty) or 1) end
    end
    -- Entregar output (doble en critico).
    local outId = items.GetId(r.output.key)
    local outQty = (tonumber(r.output.qty) or 1) * (crit and 2 or 1)
    if outId and server and server.GiveItem then server.GiveItem(outId, outQty) end

    SkillUp(r.profession, r)
    print(string.format("|cff33ff99%s x%d.|r %s%s",
        outName, outQty, line, crit and "  |cffffd100CRITICO (x2)|r" or ""))
    if HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        -- Anuncio en mesa como cualquier accion real (norma de activacion).
        HarfordDnDRolls.BroadcastAbility({ name = "Crafteo: " .. (r.name or outName) })
    end
    return true
end
