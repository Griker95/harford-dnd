-- HarfordDnDMana: regla adicional de Maná (World of Warcraft D&D 5ª Ed. ES, Parte 3 Reglas Variantes).
-- Solo datos + calculo puro. NO toca recursos ni UI: expone el pool de mana y el nivel
-- maximo de espacio segun el nivel de lanzador. La activacion es por perfil (toggle
-- progression.useMana). Cuando esta activo, HarfordDnDFeatureEffects suma el pool como
-- bonus al maximo del recurso "mana" existente (no se crea recurso nuevo).
--
-- Tipo de lanzador (manual): Completos (nivel completo) druida, mago, sacerdote, chaman.
-- Mitad (nivel/2 redondeado abajo) caballero de la muerte, paladin y druida FERAL.
-- Brujo (magia de pacto) y no-lanzadores quedan fuera del mana.

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

-- Coste en mana de un espacio del nivel dado (1..9). Trucos (0) o invalidos: 0.
function API.GetSpellCost(spellLevel)
    spellLevel = math.floor(tonumber(spellLevel) or 0)
    return API.COST[spellLevel] or 0
end

-- Aportacion de una entrada de clase al nivel de lanzador (segun casterType y subclase feral).
local function CasterContribution(entry)
    if type(entry) ~= "table" then return 0 end
    local level = math.floor(tonumber(entry.level) or 0)
    if level <= 0 then return 0 end
    local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(entry.classId)
    if not classDef then return 0 end
    local casterType = classDef.casterType
    -- Druida feral es medio lanzador aunque el druida base sea completo.
    if classDef.id == "druida" and tostring(entry.subclassId or "") == "feral" then
        casterType = "half"
    end
    if casterType == "full" then
        return level
    elseif casterType == "half" then
        return math.floor(level / 2)
    end
    return 0
end

-- Nivel de lanzador total del perfil (suma de aportaciones, acotado 0..20).
function API.GetCasterLevel(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return 0 end
    local total = 0
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
        total = total + CasterContribution(entry)
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
    return row and row.maxSpell or 0
end

-- ¿El perfil usa la variante de mana? (toggle por perfil).
function API.IsEnabled(profileName)
    return HarfordDnDProgression and HarfordDnDProgression.GetUseMana
        and HarfordDnDProgression.GetUseMana(profileName) == true
end
