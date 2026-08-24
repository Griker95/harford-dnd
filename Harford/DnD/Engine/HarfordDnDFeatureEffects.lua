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
            -- Velocidad en METROS, como el dato de raza (9 m = 30 pies). Afinidad Aire suma 1,5.
            speed = 0,
        },
        -- Velocidad FIJA que sustituye a la de la raza mientras dure (Bestia Espiritual: 15 m).
        -- Se queda con la mayor si hubiera varias.
        speedOverride = 0,
        -- Modificadores de caracteristica de CREACION (raza/trasfondo/dote). La ficha
        -- cargada ya los incluye horneados en la puntuacion nativa, asi que NO se suman
        -- en vivo (ni aparecen en el tooltip). Solo los usa el pipeline de creacion de
        -- ficha dentro del addon para calcular la puntuacion final. El bucket live
        -- `bonus.ability` queda reservado para bonos/penalizaciones de estado/objeto.
        creationBonus = { ability = {} },
        saveProf = {},
        skillRank = {},
        resourceMax = {},
        -- Recuperacion PARCIAL de un recurso al descansar, que no es lo mismo que su `recharge`:
        -- el recurso puede recargar en largo y aun asi un rasgo devolver N en el corto
        -- (Sacerdote "Restauracion de los fieles": 2 puntos de fe en descanso corto).
        restRestore = { short = {}, long = {} },
        -- Recurso GANADO por un disparador observable (Guerrero: Ira al recibir un golpe o al
        -- impactar con una maniobra de Ira). Indexado por disparador -> { recurso, cantidad, nota }.
        resourceGain = {},
        hpPerLevel = 0,   -- PG adicionales por nivel TOTAL (ej. dote Duro = 2). Lo suma ComputeMaxHP.
        armorProf = {},   -- competencias de armadura: ligera/media/pesada/escudo (bool por clave)
        weaponProf = {},  -- competencias de arma: sencillas/marciales/armas de fuego o arma concreta (bool)
        toolProf = {},    -- competencias de herramienta: clave libre (ej. "Herramientas de cervecero") -> bool
        language = {},    -- idiomas conocidos: nombre exacto del catalogo -> bool
        critThreshold = { any = 20, melee = 20 },  -- tirada minima de critico (rasgos de critico ampliado)
        flags = {},       -- flags booleanos de rasgo (ej. offhandDamageMod, greatWeaponFighting, extraAttack)
        damageStatus = {},-- resistencia/inmunidad/vulnerabilidad por tipo de dano (clave normalizada -> status)
        conditionImmunity = {}, -- inmunidades mecanicas por conditionId canonico
        conditionalDamageRiders = {}, -- id de dano condicional -> condiciones que aplica al impactar
        conditionalDamage = {}, -- dados de daño condicional conmutables (Ataque Furtivo, Golpe Runico...)
        weaponExtraDamage = {}, -- daño automatico por impacto de arma (ej. Metamorfosis)
        toggleStates = {},
        initiativeAbilities = {}, -- caracteristicas cuyo Mod. se suma a la iniciativa (ej. Alacridad: Carisma)
        allSavesAbilities = {},   -- caracteristicas cuyo Mod. (>= min) se suma a TODAS las salvaciones (Aura de Proteccion)
        unarmoredDefenseAbilities = {}, -- caracteristicas cuyo Mod. se suma a la CA SIN armadura ni escudo (Defensa sin Armadura del Monje: Sabiduria)
        weaponFinesse = {}, -- reglas que permiten tratar armas concretas como Sutiles
        martialArts = {}, -- reglas de armas de monje: Destreza y dado marcial por nivel
        -- Sustitucion de la caracteristica de ataque/dano de un arma (Monje "Serenidad": Sabiduria
        -- con armas de monje mientras dure la postura). Se gatea con `requiresState`.
        weaponAbilityOverride = {},
    }
end

-- Normaliza una palabra de tipo de dano (minusculas, sin acentos) para usarla como clave.
local function NormDamageKey(value)
    value = HarfordClassColors.StripAccents(value):lower()
    return (value:gsub("%s+", ""))  -- parentesis: gsub devuelve 2 valores
end
API.NormDamageKey = NormDamageKey

-- Aplica un efecto declarativo individual sobre la capa resuelta.
-- Nombres equivalentes de una misma competencia de arma. Sin esto la misma competencia aparece
-- dos veces con dos grafias distintas (ver la nota de arriba de weaponProf).
local WEAPON_PROF_ALIAS = {
    ["simples"] = "sencillas",
    ["armas simples"] = "sencillas",
    ["armas sencillas"] = "sencillas",
    ["armas marciales"] = "marciales",
    ["de fuego"] = "armas de fuego",
    ["armas de fuego"] = "armas de fuego",
    -- El libro declara las competencias sueltas en PLURAL ("espadas cortas"), pero la consulta
    -- llega con la clave exacta del arma, en singular ("Espada corta"). Sin estos alias el Picaro
    -- salia "sin competencia" con su propio estoque inicial y el Monje con su espada corta.
    ["espadas cortas"] = "espada corta",
    ["espadas largas"] = "espada larga",
    ["ballestas de mano"] = "ballesta de mano",
    ["hachas de mano"] = "hacha de mano",
    ["gujas"] = "guja",
    ["jabalinas"] = "jabalina",
    ["dagas"] = "daga",
    ["mazas"] = "maza",
    ["bastones"] = "baston",
    ["lanzas"] = "lanza",
    -- El manual llama "florete" a la misma arma que la tabla registra como "Estoque".
    ["floretes"] = "estoque",
    ["florete"] = "estoque",
}

-- Compara idiomas sin acentos ni mayusculas: el About los escribe a mano.
local function NormLanguage(name)
    local texto = tostring(name or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        texto = HarfordClassColors.StripAccents(texto)
    end
    return (texto:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormWeaponProf(key)
    local texto = tostring(key or "")
    local plano = texto
    if HarfordClassColors and HarfordClassColors.StripAccents then
        plano = HarfordClassColors.StripAccents(plano)
    end
    plano = plano:lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return WEAPON_PROF_ALIAS[plano] or plano
end

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
    elseif kind == "speedOverride" then
        resolved.speedOverride = math.max(tonumber(resolved.speedOverride) or 0, tonumber(effect.value) or 0)
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
    elseif kind == "resourceGain" and effect.resource and effect.trigger then
        local t = tostring(effect.trigger)
        resolved.resourceGain[t] = resolved.resourceGain[t] or {}
        resolved.resourceGain[t][#resolved.resourceGain[t] + 1] = {
            resource = tostring(effect.resource),
            amount = math.max(1, math.floor(tonumber(effect.amount) or 1)),
            -- El id del rasgo viaja con la ganancia: la linea que se publica debe llevar SU link,
            -- no una frase; el formato es `[D&D] <Actor> [LINK] <Objetivo>`.
            featureId = effect.featureId and tostring(effect.featureId) or nil,
        }
    elseif kind == "restRestore" and effect.resource then
        -- Mismo escalado por nivel que `resourceMax`: valor fijo o tabla por nivel de clase.
        local v = tonumber(effect.value) or 0
        if effect.perClassLevel and HarfordDnDProgression and HarfordDnDProgression.GetClassLevels then
            local lvl = 0
            for _, e in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
                if e.classId == effect.perClassLevel then lvl = tonumber(e.level) or 0; break end
            end
            if type(effect.values) == "table" then v = tonumber(effect.values[lvl]) or 0 end
        end
        local cual = (tostring(effect.rest or "short") == "long") and "long" or "short"
        if v > 0 then Add(resolved.restRestore[cual], effect.resource, v) end
    elseif kind == "hpPerLevel" then
        -- PG por nivel TOTAL (dote Duro = 2). Lo consume ComputeMaxHP, no resourceMax (la vida es baked).
        resolved.hpPerLevel = (tonumber(resolved.hpPerLevel) or 0) + (tonumber(effect.value) or 0)
    elseif kind == "conditionalDamageRider" and effect.conditionalId then
        -- Condicion que se aplica al impactar CON un dano condicional concreto. Va aparte del
        -- propio dano porque quien la concede puede ser otro rasgo (Orden oscura, N3, sobre el
        -- Golpe runico, N1).
        local clave = tostring(effect.conditionalId)
        resolved.conditionalDamageRiders[clave] = resolved.conditionalDamageRiders[clave] or {}
        local lista = resolved.conditionalDamageRiders[clave]
        lista[#lista + 1] = { conditionId = tostring(effect.conditionId or ""),
                              duration = tostring(effect.duration or "manual") }
    elseif kind == "flag" and effect.flag then
        resolved.flags[tostring(effect.flag)] = true
    elseif kind == "initiativeAbility" and effect.ability then
        resolved.initiativeAbilities[#resolved.initiativeAbilities + 1] = tostring(effect.ability)
    elseif kind == "allSavesAbility" and effect.ability then
        resolved.allSavesAbilities[#resolved.allSavesAbilities + 1] = { ability = tostring(effect.ability), min = tonumber(effect.min) or 0 }
    elseif kind == "unarmoredDefenseAbility" and effect.ability then
        resolved.unarmoredDefenseAbilities[#resolved.unarmoredDefenseAbilities + 1] = tostring(effect.ability)
    elseif kind == "weaponFinesse" then
        resolved.weaponFinesse[#resolved.weaponFinesse + 1] = {
            meleeOnly = effect.meleeOnly ~= false,
            excludeHeavy = effect.excludeHeavy == true,
            excludeTwoHanded = effect.excludeTwoHanded == true,
        }
    elseif kind == "weaponAbilityOverride" and effect.ability then
        resolved.weaponAbilityOverride[#resolved.weaponAbilityOverride + 1] = {
            ability = tostring(effect.ability),
            martialArtsOnly = effect.martialArtsOnly and true or false,
        }
    elseif kind == "martialArts" then
        resolved.martialArts[#resolved.martialArts + 1] = {
            classId = tostring(effect.classId or "monje"),
            values = effect.values,
        }
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
                conditionId = effect.conditionId,
                requiresMarkedTarget = effect.requiresMarkedTarget == true,
            }
        end
    elseif kind == "weaponExtraDamage" then
        local count = tonumber(effect.count) or 1
        local die = tonumber(effect.die) or 0
        if effect.perClassLevel and type(effect.values) == "table" then
            die = tonumber(effect.values[GetClassLevel(profileName, effect.perClassLevel)]) or 0
        end
        if count > 0 and die > 0 then
            resolved.weaponExtraDamage[#resolved.weaponExtraDamage + 1] = {
                id = tostring(effect.id or ("weaponExtra" .. #resolved.weaponExtraDamage)),
                label = tostring(effect.label or "Daño extra"),
                count = count,
                die = die,
                damageType = effect.damageType,
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
    elseif kind == "conditionImmunity" and effect.condition then
        resolved.conditionImmunity[tostring(effect.condition)] = true
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
        resolved.weaponProf[NormWeaponProf(effect.weapon or effect.value)] = true
    elseif kind == "toolProf" and (effect.tool or effect.value) then
        resolved.toolProf[tostring(effect.tool or effect.value)] = true
    elseif kind == "language" and (effect.language or effect.value) then
        resolved.language[tostring(effect.language or effect.value)] = true
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
                for _, w in ipairs(classDef.weaponProfs or {}) do resolved.weaponProf[NormWeaponProf(w)] = true end
                for _, t in ipairs(classDef.toolProfs or {}) do resolved.toolProf[tostring(t)] = true end
                for _, lg in ipairs(classDef.languages or {}) do resolved.language[tostring(lg)] = true end
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
            if enabled then resolved.weaponProf[NormWeaponProf(key)] = true end
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

-- Velocidad efectiva en metros: una velocidad FIJA activa (forma, transformacion) sustituye a la
-- de la raza; si no, se suma el bono. Devuelve nil si no hay base ni override, para que la ficha
-- muestre "-" en vez de un 0 enganoso.
function API.GetSpeed(baseSpeed, profileName)
    local resolved = API.Resolve(profileName)
    local override = tonumber(resolved.speedOverride) or 0
    if override > 0 then return override end
    local base = tonumber(baseSpeed)
    if not base then return nil end
    return base + (tonumber(resolved.bonus.speed) or 0)
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

-- Condiciones que un rasgo cuelga de un dano condicional concreto (Orden oscura sobre Golpe
-- runico). Devuelve lista vacia si ese dano no tiene ninguna.
function API.GetConditionalDamageRiders(conditionalId, profileName)
    local todos = API.Resolve(profileName).conditionalDamageRiders or {}
    return todos[tostring(conditionalId or "")] or {}
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

-- Daños que se aplican AUTOMATICAMENTE al impactar con un arma. A diferencia de
-- `conditionalWeaponDamage`, no se muestran como toggle ni se consumen: dependen
-- de un estado o rasgo ya resuelto (por ejemplo, Metamorfosis).
function API.GetWeaponExtraDamage(profileName)
    return API.Resolve(profileName).weaponExtraDamage
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

local function HasWeaponProperty(def, text)
    for _, prop in ipairs((def and def.props) or {}) do
        if tostring(prop):find(text, 1, true) then return true end
    end
    return false
end

-- Devuelve si un rasgo activo permite escoger Fuerza o Destreza para esta arma.
-- No convierte ataques desarmados ni escudos en armas Sutiles.
function API.TreatWeaponAsFinesse(def, profileName)
    if type(def) ~= "table" or def.key == "Desarmado" or def.key == "Escudo" then return false end
    for _, rule in ipairs(API.Resolve(profileName).weaponFinesse or {}) do
        local valid = (not rule.meleeOnly or def.mode == "Melee")
            and (not rule.excludeHeavy or not HasWeaponProperty(def, "Pesada"))
            and (not rule.excludeTwoHanded or not HasWeaponProperty(def, "Dos manos"))
        if valid then return true end
    end
    return false
end

local function HasBlockingMartialArtsEquipment(profileName)
    if not (HarfordDnDItems and HarfordDnDItems.GetSlot) then return false end
    local chest = HarfordDnDItems.GetSlot("Chest", profileName)
    if chest and chest.basicArmorKey and chest.basicArmorKey ~= "none" then
        local basic = HarfordDnDItems.GetBasicArmorInfo
            and HarfordDnDItems.GetBasicArmorInfo("Chest", profileName)
        if not basic or basic.cat == "media" or basic.cat == "pesada" then return true end
    elseif chest and chest.itemLink then
        local item = HarfordDnDItems.ResolveItem and HarfordDnDItems.ResolveItem(chest.itemLink)
        local kind = item and item.armorKind
        if kind == "mail" or kind == "plate" then return true end
    end

    local offhand = HarfordDnDItems.GetSlot("SecondaryHand", profileName)
    if offhand and (offhand.itemLink or offhand.basicWeaponKey == "Escudo") then return true end
    return false
end

local function IsMartialArtsWeapon(def)
    if type(def) ~= "table" then return false end
    if def.key == "Desarmado" then return true end
    if def.mode ~= "Melee" then return false end
    if def.key == "Espada corta" then return true end
    return def.cat == "Simple"
        and not HasWeaponProperty(def, "Dos manos")
        and not HasWeaponProperty(def, "Pesada")
end

-- Devuelve si el arma actual puede usar Artes Marciales. La comprobacion de equipo
-- evita conceder Destreza o dado marcial con armadura o escudo.
function API.TreatWeaponAsMartialArts(def, profileName)
    if HasBlockingMartialArtsEquipment(profileName) or not IsMartialArtsWeapon(def) then return false end
    return #(API.Resolve(profileName).martialArts or {}) > 0
end

-- Devuelve el dado marcial que mejora el dado normal del arma. Si el arma ya usa
-- un dado igual o mayor, el flujo normal conserva ese dado: el jugador nunca pierde
-- dano por tener Artes Marciales activas.
-- Caracteristica que sustituye a la normal para atacar/danar con este arma, o nil.
function API.GetWeaponAbilityOverride(def, profileName)
    for _, regla in ipairs(API.Resolve(profileName).weaponAbilityOverride or {}) do
        if not regla.martialArtsOnly or API.TreatWeaponAsMartialArts(def, profileName) then
            return regla.ability
        end
    end
    return nil
end

function API.GetMartialArtsDamageDice(def, profileName)
    if not API.TreatWeaponAsMartialArts(def, profileName) then return nil, nil end
    for _, rule in ipairs(API.Resolve(profileName).martialArts or {}) do
        local level = GetClassLevel(profileName, rule.classId)
        local sides = type(rule.values) == "table" and tonumber(rule.values[level]) or nil
        if sides and sides > (tonumber(def.dmgS) or 0) then return 1, sides end
    end
    return nil, nil
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

function API.HasConditionImmunity(conditionId, profileName)
    return API.Resolve(profileName).conditionImmunity[tostring(conditionId or "")] == true
end

function API.GetConditionImmunities(profileName)
    local out = {}
    for id, enabled in pairs(API.Resolve(profileName).conditionImmunity or {}) do
        if enabled then out[#out + 1] = id end
    end
    table.sort(out)
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

-- Recuperaciones parciales al descansar: { [recurso] = cantidad }. Las aplica ApplyShortRest /
-- ApplyLongRest despues de las recargas normales.
-- Ganancias de recurso declaradas para un disparador. Lista vacia si el personaje no tiene ninguna.
function API.GetResourceGains(trigger, profileName)
    local r = API.Resolve(profileName)
    return (r and r.resourceGain and r.resourceGain[tostring(trigger or "")]) or {}
end

function API.GetRestRestores(restType, profileName)
    local r = API.Resolve(profileName)
    local cual = (tostring(restType or "short") == "long") and "long" or "short"
    return (r and r.restRestore and r.restRestore[cual]) or {}
end

function API.GetResourceMaxBonus(resourceKey, profileName)
    return tonumber(API.Resolve(profileName).resourceMax[resourceKey]) or 0
end

-- PG adicionales por nivel TOTAL (dote Duro). Lo suma ComputeMaxHP (la vida no usa resourceMax).
function API.GetHpPerLevelBonus(profileName)
    return tonumber(API.Resolve(profileName).hpPerLevel) or 0
end

-- ===== Competencias de armadura / arma (bool por clave) =====
function API.HasArmorProf(key, profileName)
    return API.Resolve(profileName).armorProf[tostring(key)] == true
end

function API.HasWeaponProf(key, profileName)
    -- La consulta se normaliza igual que el almacenamiento: preguntar por "de fuego" tiene que
    -- encontrar la competencia guardada como "armas de fuego".
    return API.Resolve(profileName).weaponProf[NormWeaponProf(key)] == true
end

-- Clave libre, por nombre exacto como se declara en el efecto `toolProf` (ej. "Herramientas de
-- cervecero"). Lo usan las profesiones: tener la competencia = conocer la profesion.
-- Competente con una herramienta por rasgo/dote, O por saber la profesion que la usa: aprender
-- un oficio incluye manejar sus herramientas.
--
-- La consulta a profesiones va por `HasSkillInProfessionWithTool`, que mira el nivel de
-- habilidad y no `KnowsProfession`: esta ultima pregunta por la competencia de herramienta, y
-- llamarla desde aqui cerraria el ciclo.
function API.HasToolProf(key, profileName)
    if API.Resolve(profileName).toolProf[tostring(key)] == true then return true end
    if HarfordProfessions and HarfordProfessions.HasSkillInProfessionWithTool then
        return HarfordProfessions.HasSkillInProfessionWithTool(key) == true
    end
    return false
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

-- Idiomas derivados de los DATOS (raza, trasfondo, clase, dotes y elecciones). Se fusionan con
-- los importados del About de TRP3, que son los del personaje escrito a mano.
function API.GetLanguages(profileName)
    local out = SortedKeys(API.Resolve(profileName).language)
    local imported = HarfordDnDProgression and HarfordDnDProgression.GetImportedProficiencies
        and HarfordDnDProgression.GetImportedProficiencies(profileName)
    if not (imported and type(imported.languages) == "table") then return out end
    local vistas = {}
    for _, l in ipairs(out) do vistas[NormLanguage(l)] = true end
    for idioma, activo in pairs(imported.languages) do
        local texto = tostring(idioma or "")
        -- El About escribe el idioma como lo teclea el jugador ("Comun", "comun", "Común"):
        -- se compara sin acentos ni mayusculas para no listarlo dos veces.
        if activo and texto ~= "" and not vistas[NormLanguage(texto)] then
            vistas[NormLanguage(texto)] = true
            out[#out + 1] = texto
        end
    end
    table.sort(out)
    return out
end

-- Incluye las herramientas de las profesiones aprendidas, para que la ficha las liste junto a
-- las que dan rasgos y dotes: para el jugador son la misma competencia.
function API.GetToolProfs(profileName)
    local out = SortedKeys(API.Resolve(profileName).toolProf)
    if not (HarfordProfessions and HarfordProfessions.GetKnownTools) then return out end
    local vistas = {}
    for _, t in ipairs(out) do vistas[t] = true end
    for _, t in ipairs(HarfordProfessions.GetKnownTools()) do
        if not vistas[t] then
            vistas[t] = true
            out[#out + 1] = t
        end
    end
    table.sort(out)
    return out
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
