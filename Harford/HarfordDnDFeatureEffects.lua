-- HarfordDnDFeatureEffects: interpreta efectos declarativos de rasgos activos.

HarfordDnDFeatureEffects = HarfordDnDFeatureEffects or {}

local API = HarfordDnDFeatureEffects

-- Memoizacion de Resolve: se reconstruia entero en CADA GetBonus/HasSaveProf/etc.
-- (decenas de veces por refresh, cada uno recorriendo features + equipo). Cacheamos
-- el resultado por perfil y lo invalidamos con un contador de generacion que suben
-- las mutaciones de progresion/equipo/items. La cache guarda referencias inmutables:
-- los consumidores solo leen, nunca mutan la tabla resuelta.
local resolveCache = {}
local resolveGen = {}
local generation = 0
local damageStatusCache = {}

function API.Invalidate()
    generation = generation + 1
    damageStatusCache = {}
end

local function ShortKey(name)
    name = tostring(name or "")
    if Ambiguate then
        local short = Ambiguate(name, "short")
        if short and short ~= "" then return short end
    end
    return name:match("^[^%-]+") or name
end

local function CopyDamageStatus(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

local function StoreDamageStatus(profileName, statusMap)
    local key = tostring(profileName or "")
    local copy = CopyDamageStatus(statusMap)
    damageStatusCache[key] = copy
    local short = ShortKey(key)
    if short ~= key then damageStatusCache[short] = copy end
end

local function Add(map, key, value)
    if not key then return end
    map[key] = (tonumber(map[key]) or 0) + (tonumber(value) or 0)
end

local function GetClassLevel(profileName, classId)
    if not classId or not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return 0 end
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
        if entry.classId == classId then return tonumber(entry.level) or 0 end
    end
    return 0
end

local function GetSubclassLevel(profileName, classId, subclassId)
    if not classId or not subclassId or not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return 0 end
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
        if entry.classId == classId and tostring(entry.subclassId or "") == tostring(subclassId) then
            return tonumber(entry.level) or 0
        end
    end
    return 0
end

local function ResolveFlatBonus(effect, profileName)
    local flat = effect.flatBonus
    if flat == nil then return 0 end
    if type(flat) == "number" then return flat end

    flat = tostring(flat)
    local lower = flat:lower()
    if lower == "pb" or lower == "prof" or lower == "competencia" then
        if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetProficiencyBonus then
            return tonumber(HarfordDnDFeatureEffects.GetProficiencyBonus(profileName)) or 0
        end
        return 0
    end

    if lower == "level" or lower == "nivel" then
        if effect.flatClassId then return GetClassLevel(profileName, effect.flatClassId) end
        if effect.scaleClassId then return GetClassLevel(profileName, effect.scaleClassId) end
        if effect.perClassLevel then return GetClassLevel(profileName, effect.perClassLevel) end
        return HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
            and (tonumber(HarfordDnDProgression.GetTotalLevel(profileName)) or 0) or 0
    end

    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
        return tonumber(HarfordDnDCalc.GetAbilityMod(flat)) or 0
    end
    return 0
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
        toolProf = {},    -- competencias de herramienta: clave libre (ej. "Herramientas de cervecero") -> bool
        critThreshold = { any = 20, melee = 20 },  -- tirada minima de critico (rasgos de critico ampliado)
        flags = {},       -- flags booleanos de rasgo (ej. offhandDamageMod, greatWeaponFighting, extraAttack)
        damageStatus = {},-- resistencia/inmunidad/vulnerabilidad por tipo de dano (clave normalizada -> status)
        conditionalDamage = {}, -- dados de daño condicional conmutables (Ataque Furtivo, Golpe Runico...)
        toggleStates = {},
        initiativeAbilities = {}, -- caracteristicas cuyo Mod. se suma a la iniciativa (ej. Alacridad: Carisma)
        allSavesAbilities = {},   -- caracteristicas cuyo Mod. (>= min) se suma a TODAS las salvaciones (Aura de Proteccion)
        unarmoredDefenseAbilities = {}, -- caracteristicas cuyo Mod. se suma a la CA SIN armadura ni escudo (Defensa sin Armadura del Monje: Sabiduria)
    }
end

-- Normaliza una palabra de tipo de dano (minusculas, sin acentos) para usarla como clave.
local function NormDamageKey(value)
    value = HarfordClassColors.StripAccents(value):lower()
    return value:gsub("%s+", "")
end
API.NormDamageKey = NormDamageKey

-- Aplica un efecto declarativo individual sobre la capa resuelta.
local function ApplyEffect(resolved, effect, profileName)
    if type(effect) ~= "table" then return end
    local kind = effect.kind
    if kind ~= "toggleState" then
        local requiredState = tostring(effect.requiresState or "")
        if requiredState ~= ""
            and HarfordDnDProgression and HarfordDnDProgression.IsToggleStateActive
            and not HarfordDnDProgression.IsToggleStateActive(requiredState, profileName) then
            return
        end
    end

    if kind == "toggleState" and effect.state then
        local stateId = tostring(effect.state or "")
        if stateId ~= "" then
            resolved.toggleStates[stateId] = {
                id = stateId,
                label = tostring(effect.label or effect.name or stateId),
                description = tostring(effect.description or ""),
            }
        end
    elseif kind == "bonus" then
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
        -- Valor fijo (effect.value) o escalado por nivel de una clase:
        -- `base + perLevel * (nivel de effect.perClassLevel)`. Ej. Poder Runico = 1 + nivel CdM.
        local v = tonumber(effect.value) or 0
        if effect.perClassLevel and HarfordDnDProgression and HarfordDnDProgression.GetClassLevels then
            local lvl = 0
            for _, e in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
                if e.classId == effect.perClassLevel then lvl = tonumber(e.level) or 0; break end
            end
            if type(effect.values) == "table" then
                v = tonumber(effect.values[lvl]) or 0  -- tabla exacta del manual indexada por nivel
            else
                v = (tonumber(effect.base) or 0) + lvl * (tonumber(effect.perLevel) or 1)
            end
        end
        Add(resolved.resourceMax, effect.resource, v)
    elseif kind == "flag" and effect.flag then
        resolved.flags[tostring(effect.flag)] = true
    elseif kind == "initiativeAbility" and effect.ability then
        resolved.initiativeAbilities[#resolved.initiativeAbilities + 1] = tostring(effect.ability)
    elseif kind == "allSavesAbility" and effect.ability then
        resolved.allSavesAbilities[#resolved.allSavesAbilities + 1] = { ability = tostring(effect.ability), min = tonumber(effect.min) or 0 }
    elseif kind == "unarmoredDefenseAbility" and effect.ability then
        resolved.unarmoredDefenseAbilities[#resolved.unarmoredDefenseAbilities + 1] = tostring(effect.ability)
    elseif kind == "conditionalWeaponDamage" then
        -- Daño condicional conmutable que el jugador suma al siguiente Daño Arma.
        -- Nº de dados: fijo (effect.count) o ceil(nivel/2) de effect.perTwoClassLevels (Ataque Furtivo).
        -- Daño plano opcional: "pb", "level" o nombre de caracteristica.
        local count = tonumber(effect.count) or 0
        local die = tonumber(effect.die) or 6
        if effect.perTwoClassLevels and HarfordDnDProgression and HarfordDnDProgression.GetClassLevels then
            local lvl = GetClassLevel(profileName, effect.perTwoClassLevels)
            count = math.ceil(lvl / 2)
        end
        -- Dado escalado por nivel de clase (Marca del Cazador: 1d4 -> 1d6/1d8/1d10).
        -- effect.dieScale = lista {minNivel, caras} en orden ascendente; effect.scaleClassId la clase.
        if effect.dieScale and effect.scaleClassId and HarfordDnDProgression and HarfordDnDProgression.GetClassLevels then
            local lvl = GetClassLevel(profileName, effect.scaleClassId)
            for _, pair in ipairs(effect.dieScale) do
                if lvl >= (tonumber(pair[1]) or 0) then die = tonumber(pair[2]) or die end
            end
            if count == 0 then count = 1 end  -- por defecto 1 dado cuando solo escala el tamaño
        end
        local flat = ResolveFlatBonus(effect, profileName)
        local damageType = effect.damageType
        if effect.id == "runic_strike" and GetSubclassLevel(profileName, "caballero_muerte", "escarcha") >= 3 then
            die = 8
            damageType = "frio"
        end
        if count > 0 or flat ~= 0 or effect.resourceCost or effect.spellLevelCost then
            resolved.conditionalDamage[#resolved.conditionalDamage + 1] = {
                id = tostring(effect.id or ("cd" .. #resolved.conditionalDamage)),
                label = tostring(effect.label or "Daño extra"),
                dice = count,
                die = die,
                flat = flat,
                damageType = damageType,  -- nil = mismo tipo del arma
                spellLevelCost = effect.spellLevelCost,
                resourceCost = effect.resourceCost,
                costPerLevel = tonumber(effect.costPerLevel) or nil,
                minLevel = tonumber(effect.minLevel) or nil,
                maxLevel = tonumber(effect.maxLevel) or nil,
                maxSpellLevel = effect.maxSpellLevel == true,
                maxLevelAbility = effect.maxLevelAbility,
                countPerLevel = tonumber(effect.countPerLevel) or nil,
                extraCountOffset = tonumber(effect.extraCountOffset) or nil,
                maxCount = tonumber(effect.maxCount) or nil,
                attackPenalty = tonumber(effect.attackPenalty) or nil,  -- penalizacion a la tirada de ataque (Gran Maestro de Armas: -5/+10)
                flatAbility = effect.flatAbility,  -- +Mod de caracteristica resuelto EN LA TIRADA (no aqui: GetAbilityMod dentro de Resolve recurre)
                onHitAura = tonumber(effect.onHitAura) or nil,  -- aura a aplicar al objetivo al impactar (Desarme)
            }
        end
    elseif (kind == "resist" or kind == "immune" or kind == "vuln") and (effect.damage or effect.damageType) then
        local key = NormDamageKey(effect.damage or effect.damageType)
        if key ~= "" then
            local status = (kind == "immune" and "immune") or (kind == "vuln" and "vulnerable") or "resistant"
            -- Inmunidad gana sobre resistencia; vulnerabilidad es independiente.
            local prev = resolved.damageStatus[key]
            if status == "immune" or prev == nil or (prev == "resistant" and status == "immune") then
                resolved.damageStatus[key] = status
            elseif prev == "resistant" and status == "vulnerable" then
                resolved.damageStatus[key] = "vulnerable"
            end
        end
    elseif kind == "critRange" then
        -- Critico ampliado: la tirada minima que cuenta como critico baja a effect.value
        -- (p.ej. 19). `effect.melee = true` lo restringe a armas cuerpo a cuerpo.
        local v = tonumber(effect.value) or 20
        if effect.melee then
            resolved.critThreshold.melee = math.min(resolved.critThreshold.melee, v)
        else
            resolved.critThreshold.any = math.min(resolved.critThreshold.any, v)
        end
    elseif kind == "armorProf" and (effect.armor or effect.value) then
        resolved.armorProf[tostring(effect.armor or effect.value)] = true
    elseif kind == "weaponProf" and (effect.weapon or effect.value) then
        resolved.weaponProf[tostring(effect.weapon or effect.value)] = true
    elseif kind == "toolProf" and (effect.tool or effect.value) then
        resolved.toolProf[tostring(effect.tool or effect.value)] = true
    end
end

function API.Resolve(profileName)
    local cacheKey = tostring(profileName or "")
    if resolveCache[cacheKey] and resolveGen[cacheKey] == generation then
        return resolveCache[cacheKey]
    end

    local resolved = Empty()
    if not (HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures) then
        -- No cachear: si el modulo aun no esta cargado, el siguiente intento debe reintentar.
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
                for _, t in ipairs(classDef.toolProfs or {}) do resolved.toolProf[tostring(t)] = true end
            end
        end
    end

    -- Competencias importadas literalmente desde la ficha TRP3:
    -- "Habilidades" -> rank 1, "Pericia" -> rank 2,
    -- "Tiradas de salvacion" -> saveProf, "Competencia" -> armadura/armas/herramientas.
    if HarfordDnDProgression.GetImportedProficiencies then
        local imported = HarfordDnDProgression.GetImportedProficiencies(profileName) or {}
        for skillId, rank in pairs(imported.skillRank or {}) do
            resolved.skillRank[skillId] = math.max(tonumber(resolved.skillRank[skillId]) or 0, tonumber(rank) or 0)
        end
        for abilityKey, enabled in pairs(imported.saveProf or {}) do
            if enabled then resolved.saveProf[abilityKey] = true end
        end
        for key, enabled in pairs(imported.armorProf or {}) do
            if enabled then resolved.armorProf[tostring(key)] = true end
        end
        for key, enabled in pairs(imported.weaponProf or {}) do
            if enabled then resolved.weaponProf[tostring(key)] = true end
        end
        for key, enabled in pairs(imported.toolProf or {}) do
            if enabled then resolved.toolProf[tostring(key)] = true end
        end
    end

    for _, item in ipairs(HarfordDnDProgression.GetUnlockedFeatures(profileName)) do
        local feature = item.feature
        if HarfordDnDProgression.IsFeatureEnabled(feature, profileName) then
            -- Efectos base del rasgo.
            for _, effect in ipairs(feature.effects or {}) do
                ApplyEffect(resolved, effect, profileName)
            end
            -- Efectos de las opciones elegidas (choice): un optionId por slot.
            if feature.choice and HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                and HarfordDnDProgression.GetChoice then
                for _, optionId in ipairs(HarfordDnDProgression.GetChoice(feature.id, profileName)) do
                    local option = HarfordDnDBook.GetChoiceOption(feature, optionId)
                    if option then
                        for _, effect in ipairs(option.effects or {}) do
                            ApplyEffect(resolved, effect, profileName)
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

    -- Equipo virtual Harford: suma bonuses live seguros detectados por GetItemStats
    -- y por lineas mecanicas claras del tooltip (ej. "Naturaleza +1", "CA +1").
    -- La CA base de armadura se resuelve en HarfordDnDCombat.
    if HarfordDnDItems and HarfordDnDItems.GetEquippedBonuses then
        local itemBonuses = HarfordDnDItems.GetEquippedBonuses(profileName)
        for abilityKey, value in pairs((itemBonuses and itemBonuses.ability) or {}) do
            Add(resolved.bonus.ability, abilityKey, value)
        end
        for skillKey, value in pairs((itemBonuses and itemBonuses.skill) or {}) do
            Add(resolved.bonus.skill, skillKey, value)
        end
        for saveKey, value in pairs((itemBonuses and itemBonuses.save) or {}) do
            Add(resolved.bonus.save, saveKey, value)
        end
        for _, key in ipairs({ "initiative", "weaponAttack", "weaponDamage", "armorClass", "spellAttack", "spellDC" }) do
            resolved.bonus[key] = (tonumber(resolved.bonus[key]) or 0) + (tonumber(itemBonuses and itemBonuses[key]) or 0)
        end
    end

    resolveCache[cacheKey] = resolved
    resolveGen[cacheKey] = generation
    StoreDamageStatus(cacheKey, resolved.damageStatus)
    return resolved
end

function API.Prime(profileName)
    API.Resolve(profileName)
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

-- Flag booleano de rasgo activo (ej. "offhandDamageMod", "greatWeaponFighting", "extraAttack").
function API.HasFlag(flagName, profileName)
    return API.Resolve(profileName).flags[tostring(flagName or "")] == true
end

-- Lista de daños condicionales conmutables disponibles (cada uno {id,label,dice,die,damageType}).
function API.GetConditionalDamage(profileName)
    return API.Resolve(profileName).conditionalDamage
end

function API.GetToggleStates(profileName)
    local out = {}
    for _, state in pairs(API.Resolve(profileName).toggleStates or {}) do
        out[#out + 1] = state
    end
    table.sort(out, function(a, b)
        return tostring(a.label or a.id) < tostring(b.label or b.id)
    end)
    return out
end

-- Caracteristicas cuyo Mod. se suma a la iniciativa (ej. Alacridad: Carisma).
function API.GetInitiativeAbilities(profileName)
    return API.Resolve(profileName).initiativeAbilities
end

-- Lista {ability, min} cuyo Mod. (>= min) se suma a TODAS las salvaciones (Aura de Proteccion).
function API.GetAllSavesAbilities(profileName)
    return API.Resolve(profileName).allSavesAbilities
end

-- Lista de caracteristicas cuyo Mod. se suma a la CA SIN armadura ni escudo (Defensa sin Armadura).
function API.GetUnarmoredDefenseAbilities(profileName)
    return API.Resolve(profileName).unarmoredDefenseAbilities
end

-- Estado del jugador frente a un tipo de dano por rasgos: "resistant"/"immune"/"vulnerable"
-- o nil (normal). `damageType` admite la palabra en español ("veneno", "fuego"...).
function API.GetDamageStatus(damageType, profileName)
    return API.Resolve(profileName).damageStatus[NormDamageKey(damageType)]
end

-- Lectura barata de la lista de defensas ya resuelta para un perfil. No recorre rasgos.
function API.GetCachedDamageStatus(damageType, profileName)
    local map = damageStatusCache[tostring(profileName or "")]
    if not map then
        map = damageStatusCache[ShortKey(profileName)]
    end
    return map and map[NormDamageKey(damageType)] or nil
end

-- Mapa completo {claveNormalizada -> status} para sincronizar/inspeccionar.
function API.GetDamageStatusMap(profileName)
    local out = {}
    for k, v in pairs(API.Resolve(profileName).damageStatus) do out[k] = v end
    return out
end

-- Tirada minima del d20 que cuenta como critico para un arma (20 por defecto). Si la
-- tirada es de arma cuerpo a cuerpo, aplica tambien el umbral melee (Maquina de Matar).
function API.GetWeaponCritThreshold(isMelee, profileName)
    local ct = API.Resolve(profileName).critThreshold or { any = 20, melee = 20 }
    local t = tonumber(ct.any) or 20
    if isMelee then t = math.min(t, tonumber(ct.melee) or 20) end
    return t
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

function API.HasToolProf(key, profileName)
    return API.Resolve(profileName).toolProf[tostring(key)] == true
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

function API.GetToolProfs(profileName)
    return SortedKeys(API.Resolve(profileName).toolProf)
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
        tool = SortedKeys(r.toolProf),
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
