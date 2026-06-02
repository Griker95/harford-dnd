-- HarfordDnDFeatureEffects: interpreta efectos declarativos de rasgos activos.

HarfordDnDFeatureEffects = HarfordDnDFeatureEffects or {}

local API = HarfordDnDFeatureEffects

local function Add(map, key, value)
    if not key then return end
    map[key] = (tonumber(map[key]) or 0) + (tonumber(value) or 0)
end

local function Empty()
    return {
        bonus = {
            ability = {},
            save = {},
            skill = {},
            initiative = 0,
            weaponAttack = 0,
            weaponDamage = 0,
            armorClass = 0,
            spellAttack = 0,
            spellDC = 0,
        },
        -- Modificadores de caracteristica de CREACION (raza/trasfondo/dote). La ficha
        -- cargada ya los incluye horneados en la puntuacion nativa, asi que NO se suman
        -- en vivo (ni aparecen en el tooltip). Solo los usa el pipeline de creacion de
        -- ficha dentro del addon para calcular la puntuacion final. El bucket live
        -- `bonus.ability` queda reservado para bonos/penalizaciones de estado/objeto.
        creationBonus = { ability = {} },
        saveProf = {},
        skillRank = {},
        resourceMax = {},
        armorProf = {},   -- competencias de armadura: ligera/media/pesada/escudo (bool por clave)
        weaponProf = {},  -- competencias de arma: sencillas/marciales/armas de fuego o arma concreta (bool)
    }
end

-- Aplica un efecto declarativo individual sobre la capa resuelta.
local function ApplyEffect(resolved, effect)
    if type(effect) ~= "table" then return end
    local kind = effect.kind
    if kind == "bonus" then
        local target = tostring(effect.target or "")
        local value = tonumber(effect.value) or 0
        if target == "ability" then
            -- Modificador de caracteristica de creacion (raza/trasfondo/dote): va al
            -- bucket de creacion, no al live. La ficha cargada ya lo trae horneado.
            Add(resolved.creationBonus.ability, effect.ability, value)
        elseif target == "save" then
            Add(resolved.bonus.save, effect.ability, value)
        elseif target == "skill" then
            Add(resolved.bonus.skill, effect.skill, value)
        elseif resolved.bonus[target] ~= nil then
            resolved.bonus[target] = (tonumber(resolved.bonus[target]) or 0) + value
        end
    elseif kind == "saveProf" and effect.ability then
        resolved.saveProf[effect.ability] = true
    elseif kind == "skillProf" and effect.skill then
        resolved.skillRank[effect.skill] = math.max(tonumber(resolved.skillRank[effect.skill]) or 0, 1)
    elseif kind == "skillExpertise" and effect.skill then
        resolved.skillRank[effect.skill] = math.max(tonumber(resolved.skillRank[effect.skill]) or 0, 2)
    elseif kind == "resourceMax" and effect.resource then
        Add(resolved.resourceMax, effect.resource, effect.value)
    elseif kind == "armorProf" and (effect.armor or effect.value) then
        resolved.armorProf[tostring(effect.armor or effect.value)] = true
    elseif kind == "weaponProf" and (effect.weapon or effect.value) then
        resolved.weaponProf[tostring(effect.weapon or effect.value)] = true
    end
end

function API.Resolve(profileName)
    local resolved = Empty()
    if not (HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures) then
        return resolved
    end

    -- Salvaciones base de la clase. Regla 5e: en multiclase SOLO la primera clase
    -- otorga sus competencias de salvacion; las siguientes no. Se aplican siempre
    -- (no son rasgos con checkbox): definen la competencia de salvacion del PJ.
    if HarfordDnDProgression.GetClassLevels and HarfordDnDBook and HarfordDnDBook.GetClass then
        local levels = HarfordDnDProgression.GetClassLevels(profileName) or {}
        -- Salvaciones: solo la PRIMERA clase (regla 5e de multiclase).
        local first = levels[1]
        local firstDef = first and HarfordDnDBook.GetClass(first.classId)
        if firstDef and type(firstDef.saves) == "table" then
            for _, abilityKey in ipairs(firstDef.saves) do
                resolved.saveProf[abilityKey] = true
            end
        end
        -- Competencias de armadura/arma: union de TODAS las clases (base por clase).
        for _, entry in ipairs(levels) do
            local classDef = HarfordDnDBook.GetClass(entry.classId)
            if classDef then
                for _, a in ipairs(classDef.armorProfs or {}) do resolved.armorProf[tostring(a)] = true end
                for _, w in ipairs(classDef.weaponProfs or {}) do resolved.weaponProf[tostring(w)] = true end
            end
        end
    end

    for _, item in ipairs(HarfordDnDProgression.GetUnlockedFeatures(profileName)) do
        local feature = item.feature
        if HarfordDnDProgression.IsFeatureEnabled(feature, profileName) then
            -- Efectos base del rasgo.
            for _, effect in ipairs(feature.effects or {}) do
                ApplyEffect(resolved, effect)
            end
            -- Efectos de las opciones elegidas (choice): un optionId por slot.
            if feature.choice and HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                and HarfordDnDProgression.GetChoice then
                for _, optionId in ipairs(HarfordDnDProgression.GetChoice(feature.id, profileName)) do
                    local option = HarfordDnDBook.GetChoiceOption(feature, optionId)
                    if option then
                        for _, effect in ipairs(option.effects or {}) do
                            ApplyEffect(resolved, effect)
                        end
                    end
                end
            end
        end
    end

    -- Variante de Mana: si el perfil la usa, el pool calculado por nivel de lanzador
    -- se aplica como maximo derivado del recurso "mana" existente (no crea recurso).
    if HarfordDnDMana and HarfordDnDMana.IsEnabled and HarfordDnDMana.IsEnabled(profileName) then
        Add(resolved.resourceMax, "mana", HarfordDnDMana.GetManaPool(profileName))
    end

    return resolved
end

function API.GetBonus(target, key, profileName)
    local resolved = API.Resolve(profileName)
    target = tostring(target or "")
    if target == "ability" then return tonumber(resolved.bonus.ability[key]) or 0 end  -- live: estado/objeto
    if target == "save" then return tonumber(resolved.bonus.save[key]) or 0 end
    if target == "skill" then return tonumber(resolved.bonus.skill[key]) or 0 end
    return tonumber(resolved.bonus[target]) or 0
end

-- Modificador de caracteristica de CREACION (raza/trasfondo/dote) para una clave.
-- NO se aplica al score en vivo (la ficha cargada ya lo incluye). Lo usara el
-- pipeline de creacion de ficha dentro del addon para calcular la puntuacion final.
function API.GetCreationAbilityBonus(key, profileName)
    return tonumber(API.Resolve(profileName).creationBonus.ability[key]) or 0
end

function API.HasSaveProf(abilityKey, profileName)
    return API.Resolve(profileName).saveProf[abilityKey] == true
end

function API.GetSkillRank(skillId, profileName)
    return tonumber(API.Resolve(profileName).skillRank[skillId]) or 0
end

function API.GetResourceMaxBonus(resourceKey, profileName)
    return tonumber(API.Resolve(profileName).resourceMax[resourceKey]) or 0
end

-- ===== Competencias de armadura / arma (bool por clave) =====
function API.HasArmorProf(key, profileName)
    return API.Resolve(profileName).armorProf[tostring(key)] == true
end

function API.HasWeaponProf(key, profileName)
    return API.Resolve(profileName).weaponProf[tostring(key)] == true
end

-- Devuelve la lista (ordenada) de claves competentes de una categoria del set resuelto.
local function SortedKeys(map)
    local out = {}
    for k, v in pairs(map or {}) do if v then out[#out + 1] = k end end
    table.sort(out)
    return out
end

function API.GetArmorProfs(profileName)
    return SortedKeys(API.Resolve(profileName).armorProf)
end

function API.GetWeaponProfs(profileName)
    return SortedKeys(API.Resolve(profileName).weaponProf)
end

-- Instantanea unificada de las 4 categorias de competencia para la UI:
-- { armor = {claves}, weapon = {claves}, saves = {claves de salvacion}, skills = {skillId -> rango} }
function API.GetProficiencies(profileName)
    local r = API.Resolve(profileName)
    local saves = {}
    for k, v in pairs(r.saveProf) do if v then saves[#saves + 1] = k end end
    table.sort(saves)
    return {
        armor = SortedKeys(r.armorProf),
        weapon = SortedKeys(r.weaponProf),
        saves = saves,
        skills = r.skillRank,   -- skillId -> rango (1 competente, 2 pericia)
    }
end

function API.GetProficiencyBonus(profileName)
    if HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus then
        return HarfordDnDProgression.GetProficiencyBonus(profileName)
    end
    return nil
end
