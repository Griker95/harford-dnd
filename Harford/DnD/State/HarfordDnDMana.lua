-- HarfordDnDMana: regla adicional de Maná (World of Warcraft D&D 5ª Ed. ES, Parte 3 Reglas Variantes).
-- Solo datos + calculo puro. NO toca recursos ni UI: expone el pool de mana y el nivel
-- maximo de espacio segun el nivel de lanzador. La activacion es GLOBAL mediante
-- HarfordConfig.spell_cost_mode. Cuando esta activo, HarfordDnDFeatureEffects suma el pool como
-- bonus al maximo del recurso "mana" existente (no se crea recurso nuevo).
--
-- Tipo de lanzador SEGUN EL MANUAL (regla de Mana, Parte 3): la tabla "se aplica a druidas, magos,
-- sacerdotes y chamanes"; para "caballeros de la muerte, druidas (ferales) o paladines" se divide el
-- nivel a la mitad. El redondeo HACIA ARRIBA y la puerta de nivel 2 son decisiones de mesa.
--
-- CUIDADO: el **Brujo NO aparece en ninguna de las dos listas** del manual, y sin embargo su tabla de
-- clase es MAGIA DE PACTO, que no se parece a un lanzador completo: a nivel 1-6 tiene 1/2/2/2/2/2
-- ranuras, TODAS del mismo nivel (1.o/1.o/2.o/2.o/3.o/3.o), no una piramide. Hoy esta declarado
-- `casterType = "full"`, asi que en modo espacios recibe 4/3/3 (diez ranuras) en vez de dos de 3.o.
-- Es una divergencia PENDIENTE DE DECIDIR, no algo ya acordado. El Picaro Sutileza tampoco esta en
-- las listas del manual: se le aplica `third` por extension, igual que al Chaman Mejora `half`.

HarfordDnDMana = HarfordDnDMana or {}

local API = HarfordDnDMana

-- Coste de Mana por nivel de espacio de conjuro (1..9). Los trucos no cuestan.
API.COST = { 2, 3, 5, 6, 7, 9, 10, 11, 13 }

-- Mana por Nivel de lanzador: { [nivel] = { mana = N, maxSpell = M } }, niveles 1..20.
API.BY_LEVEL = {
    [1]  = { mana = 3,   maxSpell = 1 },
    [2]  = { mana = 6,   maxSpell = 1 },
    [3]  = { mana = 14,  maxSpell = 2 },
    [4]  = { mana = 17,  maxSpell = 2 },
    [5]  = { mana = 27,  maxSpell = 3 },
    [6]  = { mana = 32,  maxSpell = 3 },
    [7]  = { mana = 38,  maxSpell = 4 },
    [8]  = { mana = 44,  maxSpell = 4 },
    [9]  = { mana = 57,  maxSpell = 5 },
    [10] = { mana = 64,  maxSpell = 5 },
    [11] = { mana = 73,  maxSpell = 6 },
    [12] = { mana = 73,  maxSpell = 6 },
    [13] = { mana = 83,  maxSpell = 7 },
    [14] = { mana = 83,  maxSpell = 7 },
    [15] = { mana = 94,  maxSpell = 8 },
    [16] = { mana = 94,  maxSpell = 8 },
    [17] = { mana = 107, maxSpell = 9 },
    [18] = { mana = 114, maxSpell = 9 },
    [19] = { mana = 123, maxSpell = 9 },
    [20] = { mana = 133, maxSpell = 9 },
}

-- Espacios por nivel de lanzador. Los medio lanzadores ya aportan su nivel reducido
-- mediante GetCasterLevel y reutilizan esta misma progresion.
API.SLOT_COUNT = {
    [1]  = { 2 }, [2]  = { 3 }, [3]  = { 4, 2 }, [4]  = { 4, 3 },
    [5]  = { 4, 3, 2 }, [6]  = { 4, 3, 3 }, [7]  = { 4, 3, 3, 1 },
    [8]  = { 4, 3, 3, 2 }, [9]  = { 4, 3, 3, 3, 1 },
    [10] = { 4, 3, 3, 3, 2 }, [11] = { 4, 3, 3, 3, 2, 1 },
    [12] = { 4, 3, 3, 3, 2, 1 }, [13] = { 4, 3, 3, 3, 2, 1, 1 },
    [14] = { 4, 3, 3, 3, 2, 1, 1 }, [15] = { 4, 3, 3, 3, 2, 1, 1, 1 },
    [16] = { 4, 3, 3, 3, 2, 1, 1, 1 }, [17] = { 4, 3, 3, 3, 2, 1, 1, 1, 1 },
    [18] = { 4, 3, 3, 3, 3, 1, 1, 1, 1 }, [19] = { 4, 3, 3, 3, 3, 2, 1, 1, 1 },
    [20] = { 4, 3, 3, 3, 3, 2, 2, 1, 1 },
}

-- Coste en mana de un espacio del nivel dado (1..9). Trucos (0) o invalidos: 0.
function API.GetSpellCost(spellLevel)
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    return API.COST[spellLevel] or 0
end

-- Aportacion de una entrada de clase al nivel de lanzador (segun casterType y subclase feral).
-- `forSlots` distingue los dos usos: el pool de MANA cuenta el nivel de pacto entero, pero la
-- PIRAMIDE de ranuras no, porque el brujo tiene su propia tabla (`PACT_SLOTS`).
local function CasterContribution(entry, forSlots)
    if type(entry) ~= "table" then return 0 end
    local level = math.floor(tonumber(entry.level) or 0)
    if level <= 0 then return 0 end
    local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(entry.classId)
    if not classDef then return 0 end
    local casterType = classDef.casterType
    -- La SUBCLASE puede cambiar el tipo de lanzador de la clase: Druida feral y Chaman Mejora son
    -- medios lanzadores aunque sus clases base sean completas. Se lee del dato, no de un caso
    -- especial por clase.
    local subclass = HarfordDnDBook and HarfordDnDBook.GetSubclass
        and HarfordDnDBook.GetSubclass(classDef.id, entry.subclassId)
    if subclass and subclass.casterType then
        casterType = subclass.casterType
    end
    if casterType == "pact" then
        -- Magia de pacto: nivel entero para el mana, nada para la piramide.
        return forSlots and 0 or level
    elseif casterType == "full" then
        return level
    elseif casterType == "half" then
        -- Medio lanzador: `ceil(nivel/2)`, pero NO lanza hasta nivel 2. El redondeo hacia arriba
        -- es decision de mesa; la puerta de nivel 2 la manda el compendio
        -- (`HarfordCompendioCore.GetMaxSpellLevel`), que es quien decide que conjuros puede
        -- elegir. Sin ella, un Paladin de nivel 1 tenia ranura y ningun conjuro que meter en ella.
        if level < 2 then return 0 end
        return math.ceil(level / 2)
    elseif casterType == "third" then
        -- Lanzador de tercio (Picaro Sutileza): `ceil(nivel/3)`, el mismo criterio que ya usa
        -- HarfordCompendioCore.GetMaxSpellLevel, para que el picker y las ranuras coincidan.
        -- La puerta de nivel 3 es explicita, igual que la de nivel 2 del medio: normalmente
        -- sobra (antes de la subclase no hay `subclassId`), pero una progresion importada con
        -- subclase puesta a nivel bajo se colaria.
        if level < 3 then return 0 end
        return math.ceil(level / 3)
    end
    return 0
end


-- MAGIA DE PACTO (Brujo). Su tabla de clase no es una piramide: pocas ranuras, TODAS del mismo
-- nivel, del manual (columnas "Ranuras de Conjuro" y "Nivel de Ranura").
--
-- Decision de mesa: **pacto en modo ESPACIOS, completo en modo MANA**. El manual describe la tabla
-- de pacto en la clase, pero su regla variante de Mana no menciona al brujo en ninguna de las dos
-- listas; darle el pool de un lanzador completo es lo mas parecido a la flexibilidad que el pacto
-- le da. Por eso `CasterContribution` cuenta el nivel entero (mana) y las RANURAS salen de aqui.
API.PACT_SLOTS = {
    [1]  = { count = 1, level = 1 },
    [2]  = { count = 2, level = 1 },
    [3]  = { count = 2, level = 2 },
    [4]  = { count = 2, level = 2 },
    [5]  = { count = 2, level = 3 },
    [6]  = { count = 2, level = 3 },
    [7]  = { count = 2, level = 4 },
    [8]  = { count = 2, level = 4 },
    [9]  = { count = 2, level = 5 },
    [10] = { count = 2, level = 5 },
    [11] = { count = 3, level = 5 },
    [12] = { count = 3, level = 5 },
    [13] = { count = 3, level = 5 },
    [14] = { count = 3, level = 5 },
    [15] = { count = 3, level = 5 },
    [16] = { count = 3, level = 5 },
    [17] = { count = 4, level = 5 },
    [18] = { count = 4, level = 5 },
    [19] = { count = 4, level = 5 },
    [20] = { count = 4, level = 5 },
}

-- Niveles totales en clases de pacto. En multiclase, las ranuras de pacto se SUMAN a las normales
-- en vez de llevarse aparte: el manual lo permite explicitamente ("Hechiceria Vil: puedes lanzar
-- conjuros ... usando ranuras de Hechiceria Vil y viceversa"), asi que no hace falta una segunda
-- reserva ni una UI propia.
function API.GetPactLevel(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return 0 end
    local total = 0
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
        local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(entry.classId)
        if classDef and classDef.casterType == "pact" then
            total = total + math.max(0, math.floor(tonumber(entry.level) or 0))
        end
    end
    return math.min(20, total)
end

-- Ranuras de pacto: cuantas y de que nivel. Devuelve 0,0 si no hay niveles de pacto.
function API.GetPactSlots(profileName)
    local nivel = API.GetPactLevel(profileName)
    local fila = nivel > 0 and API.PACT_SLOTS[nivel]
    if not fila then return 0, 0 end
    return fila.count, fila.level
end

-- Nivel de lanzador total del perfil (suma de aportaciones, acotado 0..20).
function API.GetCasterLevel(profileName, forSlots)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return 0 end
    local total = 0
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
        total = total + CasterContribution(entry, forSlots)
    end
    if total < 0 then total = 0 end
    if total > 20 then total = 20 end
    return total
end

-- Pool maximo de mana del perfil segun su nivel de lanzador (0 si no es lanzador).
function API.GetManaPool(profileName)
    local lvl = API.GetCasterLevel(profileName)
    local row = API.BY_LEVEL[lvl]
    return row and row.mana or 0
end

-- Nivel maximo de espacio que el perfil puede crear (0 si no es lanzador).
function API.GetMaxSpellLevel(profileName)
    local lvl = API.GetCasterLevel(profileName)
    local row = API.BY_LEVEL[lvl]
    local maximo = (row and row.maxSpell) or 0
    -- En modo espacios, el brujo puede lanzar al nivel de su ranura de pacto aunque su piramide
    -- sea 0. En modo mana su nivel de lanzador ya es el completo y esto no resta.
    local _, pactLevel = API.GetPactSlots(profileName)
    if pactLevel > maximo then maximo = pactLevel end
    return maximo
end

function API.GetSpellSlotMax(spellLevel, profileName)
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    local slots = API.SLOT_COUNT[API.GetCasterLevel(profileName, true)]
    local base = (slots and tonumber(slots[spellLevel])) or 0
    -- Las de pacto se suman a las normales de su mismo nivel, no van en una reserva aparte.
    local pactCount, pactLevel = API.GetPactSlots(profileName)
    if pactCount > 0 and spellLevel == pactLevel then base = base + pactCount end
    -- Los espacios creados con puntos suman al maximo, para que se CUENTEN igual que los de la
    -- tabla en todo lo que lee GetSpellSlotCurrent (libro de conjuros, compendio, coste al lanzar).
    local extra = HarfordDnDProgression and HarfordDnDProgression.GetSpellSlotsBonus
        and HarfordDnDProgression.GetSpellSlotsBonus(spellLevel, profileName) or 0
    return base + extra
end

function API.GetSpellSlotCurrent(spellLevel, profileName)
    local maximum = API.GetSpellSlotMax(spellLevel, profileName)
    if maximum <= 0 then return 0, maximum end
    local spent = HarfordDnDProgression and HarfordDnDProgression.GetSpellSlotsSpent
        and HarfordDnDProgression.GetSpellSlotsSpent(spellLevel, profileName) or 0
    return math.max(0, maximum - spent), maximum
end

function API.CanSpendSpellSlot(spellLevel, profileName)
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    if spellLevel <= 0 then return true end
    local current, maximum = API.GetSpellSlotCurrent(spellLevel, profileName)
    if maximum <= 0 then return false, "No tienes espacios de nivel " .. tostring(spellLevel) end
    if current <= 0 then return false, "No quedan espacios de nivel " .. tostring(spellLevel) end
    return true, current, maximum
end

function API.SpendSpellSlot(spellLevel, profileName)
    local ok, currentOrErr, maximum = API.CanSpendSpellSlot(spellLevel, profileName)
    if not ok then return false, currentOrErr end
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    if spellLevel <= 0 then return true, 0, 0 end
    local spent = HarfordDnDProgression.GetSpellSlotsSpent(spellLevel, profileName)
    HarfordDnDProgression.SetSpellSlotsSpent(spellLevel, spent + 1, profileName)
    return true, currentOrErr - 1, maximum
end


-- LANZAMIENTO FLEXIBLE / DEVOCION: puntos <-> espacios de conjuro.
--
-- Mago (puntos de hechiceria) y Sacerdote (puntos de fe) tienen la MISMA mecanica con distinto
-- nombre de recurso, asi que va una sola vez aqui y cada rasgo declara el suyo.
--
-- Solo tiene sentido con espacios: si la mesa juega con mana no hay espacios que crear ni
-- convertir, y la conversion se rechaza con un motivo, no en silencio.
API.SLOT_POINT_COST = { 2, 3, 5, 6, 7 }   -- coste en puntos de un espacio de nivel 1..5
API.MAX_CREATABLE_SLOT_LEVEL = 5

local function ModoEspacios(profileName)
    if API.IsEnabled(profileName) then
        return false, "La mesa juega con mana: no hay espacios de conjuro que crear ni convertir."
    end
    return true
end

local function Puntos(resourceKey)
    if not (HarfordDnDStore and HarfordDnDStore.GetResourceCurrent) then return 0 end
    return tonumber(HarfordDnDStore.GetResourceCurrent(resourceKey)) or 0
end

-- Niveles de espacio que puedes permitirte ahora mismo, con su coste. Lo usa el menu.
function API.GetCreatableSlots(resourceKey, profileName)
    local ok, err = ModoEspacios(profileName)
    if not ok then return {}, err end
    local disponibles = Puntos(resourceKey)
    local tope = math.min(API.MAX_CREATABLE_SLOT_LEVEL, API.GetMaxSpellLevel(profileName))
    local out = {}
    for nivel = 1, math.max(0, tope) do
        local coste = API.SLOT_POINT_COST[nivel]
        if coste then
            out[#out + 1] = { level = nivel, cost = coste, affordable = disponibles >= coste }
        end
    end
    return out, nil
end

-- Espacios que tienes disponibles y podrias convertir en puntos.
function API.GetConvertibleSlots(profileName)
    local ok, err = ModoEspacios(profileName)
    if not ok then return {}, err end
    local out = {}
    for nivel = 1, 9 do
        local actual, maximo = API.GetSpellSlotCurrent(nivel, profileName)
        if (maximo or 0) > 0 and (actual or 0) > 0 then
            out[#out + 1] = { level = nivel, current = actual, max = maximo, gain = nivel }
        end
    end
    return out, nil
end

-- Gasta puntos y crea un espacio de ese nivel. Devuelve ok, error.
function API.CreateSlotFromPoints(spellLevel, resourceKey, profileName)
    local ok, err = ModoEspacios(profileName)
    if not ok then return false, err end
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    local coste = API.SLOT_POINT_COST[spellLevel]
    if not coste then
        return false, "Solo puedes crear espacios de nivel 1 a " .. tostring(API.MAX_CREATABLE_SLOT_LEVEL) .. "."
    end
    if spellLevel > API.GetMaxSpellLevel(profileName) then
        return false, "Todavia no puedes lanzar conjuros de nivel " .. tostring(spellLevel) .. "."
    end
    if Puntos(resourceKey) < coste then
        return false, "Necesitas " .. tostring(coste) .. " puntos y tienes " .. tostring(Puntos(resourceKey)) .. "."
    end
    if not (HarfordDnDProgression and HarfordDnDProgression.SetSpellSlotsBonus) then return false end
    HarfordDnDStore.AdjustResourceCurrent(resourceKey, -coste)
    HarfordDnDProgression.SetSpellSlotsBonus(spellLevel,
        HarfordDnDProgression.GetSpellSlotsBonus(spellLevel, profileName) + 1, profileName)
    return true, nil, coste
end

-- Gasta un espacio y da puntos iguales a su nivel, sin pasar del maximo del recurso.
function API.ConvertSlotToPoints(spellLevel, resourceKey, profileName)
    local ok, err = ModoEspacios(profileName)
    if not ok then return false, err end
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    local puede, motivo = API.CanSpendSpellSlot(spellLevel, profileName)
    if not puede then return false, motivo end
    local maximo = (HarfordDnDStore.GetResourceMax and tonumber(HarfordDnDStore.GetResourceMax(resourceKey))) or 0
    local actual = Puntos(resourceKey)
    local ganados = spellLevel
    if maximo > 0 then ganados = math.min(ganados, math.max(0, maximo - actual)) end
    if ganados <= 0 then
        return false, "Ya tienes el maximo de puntos: convertir el espacio no daria ninguno."
    end
    local gastado = API.SpendSpellSlot(spellLevel, profileName)
    if not gastado then return false, "No se pudo gastar el espacio." end
    HarfordDnDStore.AdjustResourceCurrent(resourceKey, ganados)
    return true, nil, ganados
end

-- ¿La mesa usa la variante de mana? La eleccion es global, no viaja con la ficha.
function API.IsEnabled(profileName)
    return not (HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("spell_cost_mode") == "slots")
end
