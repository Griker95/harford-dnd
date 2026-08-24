-- HarfordDnDCalc: calculo puro de la ficha D&D 5e (modificadores, dados, bonos).
--
-- No tiene estado de UI ni frames. Lee los valores de la ficha via
-- HarfordDnDContext.Get / HarfordDnDContext.State, por lo que funciona igual en
-- modo jugador y en contexto NPC (overrides). HarfordDnD.lua llama a estas
-- funciones como HarfordDnDCalc.X(...).

HarfordDnDCalc = HarfordDnDCalc or {}

local toN = HarfordDnDStore.ToNumber

local function fmtSigned(n)
    n = toN(n, 0)
    if n >= 0 then return "+" .. n end
    return tostring(n)
end

local function IsNpcContext()
    local State = HarfordDnDContext and HarfordDnDContext.State
    return State and State.active and State.kind == "npc"
end

-- ─── Dados y modificador de caracteristica ───────────────────────────────────
function HarfordDnDCalc.AbilityMod(score)
    score = toN(score, 10)
    return math.floor((score - 10) / 2)
end

function HarfordDnDCalc.RollDie(sides)
    return math.random(1, sides)
end

function HarfordDnDCalc.RollD20(mode)
    local a, b = HarfordDnDCalc.RollDie(20), HarfordDnDCalc.RollDie(20)
    if mode == "adv" then return math.max(a, b), a, b end
    if mode == "dis" then return math.min(a, b), a, b end
    return a, a, nil
end

-- ─── Bonos base (leen ARC via HarfordDnDContext) ─────────────────────────────
function HarfordDnDCalc.GetPB()
    if IsNpcContext() then
        return toN(HarfordDnDContext.Get("BonusCompetencia", "0"), 0)
    end
    local derived = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetProficiencyBonus
        and HarfordDnDFeatureEffects.GetProficiencyBonus()
    if derived then return derived end
    return toN(HarfordDnDContext.Get("BonusCompetencia", "2"), 2)
end

-- Bonus de competencia para conjuros: en contexto NPC usa el valor exclusivo del
-- stat block; en cualquier otro caso cae al PB normal.
function HarfordDnDCalc.GetSpellPB()
    local State = HarfordDnDContext.State
    if State.active and State.kind == "npc" and type(State.spellProficiencyBonus) == "number" then
        return State.spellProficiencyBonus
    end
    return HarfordDnDCalc.GetPB()
end

function HarfordDnDCalc.GetMode()
    return HarfordDnDContext.Get("ModoTirada", "normal")
end

function HarfordDnDCalc.GetMiscBonus()
    return toN(HarfordDnDContext.Get("BonoSituacional", "0"), 0)
end

function HarfordDnDCalc.GetAbilityScore(key)
    local base = toN(HarfordDnDContext.Get(key, "10"), 10)
    if IsNpcContext() then return base end
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("ability", key)
        or 0
    return base + bonus
end

function HarfordDnDCalc.GetAbilityMod(key)
    return HarfordDnDCalc.AbilityMod(HarfordDnDCalc.GetAbilityScore(key))
end

function HarfordDnDCalc.GetSaveProf(abilityKey)
    if IsNpcContext() then
        return toN(HarfordDnDContext.Get("Salv_" .. abilityKey, "0"), 0) == 1
    end
    return toN(HarfordDnDContext.Get("Salv_" .. abilityKey, "0"), 0) == 1
        or (HarfordDnDFeatureEffects
            and HarfordDnDFeatureEffects.HasSaveProf
            and HarfordDnDFeatureEffects.HasSaveProf(abilityKey) == true)
end

function HarfordDnDCalc.GetWeaponMod()
    -- Legacy: el campo manual ModArma se retiro de la ficha. Los bonos de arma
    -- globales vienen de rasgos/items no-arma via GetWeaponAttackBonus/GetWeaponDamageBonus.
    -- Los bonuses del item equipado como arma son por slot y los suma HarfordDnD.lua.
    return 0
end

-- Categoria del arma -> clave de competencia. Las que no tienen categoria propia (raciales,
-- especiales) solo cuentan por su nombre concreto.
local WEAPON_CAT_PROF = {
    ["simple"] = "sencillas",
    ["marcial"] = "marciales",
    ["de fuego"] = "armas de fuego",
}

-- ¿El personaje es competente con esta arma? Por categoria o por nombre concreto.
function HarfordDnDCalc.HasWeaponProficiency(def)
    if IsNpcContext() then return true end
    if type(def) ~= "table" then return true end
    -- El golpe sin armas lo domina todo el mundo.
    if tostring(def.key or "") == "Desarmado" then return true end
    local FE = HarfordDnDFeatureEffects
    if not (FE and FE.HasWeaponProf) then return true end

    local cat = tostring(def.cat or ""):lower()
    local claveCat = WEAPON_CAT_PROF[cat]
    if claveCat and FE.HasWeaponProf(claveCat) then return true end
    -- Por nombre: el libro declara competencias sueltas ("espadas cortas", "hacha de mano").
    local nombre = tostring(def.key or "")
    if nombre ~= "" and FE.HasWeaponProf(nombre) then return true end
    return false
end

function HarfordDnDCalc.GetWeaponAttackBonus()
    if IsNpcContext() then return 0 end
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("weaponAttack")
        or 0
    return bonus
end

function HarfordDnDCalc.GetWeaponDamageBonus()
    if IsNpcContext() then return 0 end
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("weaponDamage")
        or 0
    return bonus
end

function HarfordDnDCalc.GetInitiativeBonus()
    if IsNpcContext() then
        return toN(HarfordDnDContext.Get("ModIniciativa", "0"), 0)
    end
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("initiative")
        or 0
    -- Caracteristicas que suman su Mod. a la iniciativa (ej. Picaro Forajido "Alacridad": Carisma).
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetInitiativeAbilities then
        for _, ability in ipairs(HarfordDnDFeatureEffects.GetInitiativeAbilities()) do
            bonus = bonus + HarfordDnDCalc.GetAbilityMod(ability)
        end
    end
    -- Rasgos que suman el bonus de COMPETENCIA a la iniciativa (ej. Chaman Afinidad Aire).
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("initiativeProfBonus") then
        bonus = bonus + HarfordDnDCalc.GetPB()
    end
    return bonus
end

function HarfordDnDCalc.GetVersatileActive()
    return toN(HarfordDnDContext.Get("Versatil", "0"), 0) == 1
end

-- ─── Bonos compuestos ────────────────────────────────────────────────────────
function HarfordDnDCalc.GetSkillProfBonus(skill)
    if IsNpcContext() then
        local profFlag = toN(HarfordDnDContext.Get("Hab_" .. skill.id .. "_Prof", "0"), 0)
        local expFlag  = toN(HarfordDnDContext.Get("Hab_" .. skill.id .. "_Exp", "0"), 0)
        local pb = HarfordDnDCalc.GetPB()
        if expFlag == 1 then return 2 * pb end
        if profFlag == 1 then return pb end
        return 0
    end
    local pb = HarfordDnDCalc.GetPB()
    local profFlag = toN(HarfordDnDContext.Get("Hab_" .. skill.id .. "_Prof", "0"), 0)
    local expFlag  = toN(HarfordDnDContext.Get("Hab_" .. skill.id .. "_Exp", "0"), 0)
    local featureRank = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetSkillRank
        and HarfordDnDFeatureEffects.GetSkillRank(skill.id)
        or 0
    if expFlag == 1 or featureRank >= 2 then return 2 * pb end
    if profFlag == 1 or featureRank >= 1 then return pb end
    return 0
end

function HarfordDnDCalc.GetSkillRollBonuses(skill)
    local State = HarfordDnDContext.State
    local explicit = State.active and State.overrides
        and tonumber(State.overrides["Context_Hab_" .. skill.id .. "_Bonus"])
    if type(explicit) == "number" then
        return explicit, 0
    end
    if IsNpcContext() then
        return HarfordDnDCalc.GetAbilityMod(skill.ability), HarfordDnDCalc.GetSkillProfBonus(skill)
    end
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("skill", skill.id)
        or 0
    return HarfordDnDCalc.GetAbilityMod(skill.ability) + bonus, HarfordDnDCalc.GetSkillProfBonus(skill)
end

function HarfordDnDCalc.GetSaveRollBonuses(abilityKey)
    local State = HarfordDnDContext.State
    local explicit = State.active and State.overrides
        and tonumber(State.overrides["Context_Salv_" .. abilityKey .. "_Bonus"])
    if type(explicit) == "number" then
        return explicit, 0
    end
    if IsNpcContext() then
        return HarfordDnDCalc.GetAbilityMod(abilityKey),
            HarfordDnDCalc.GetSaveProf(abilityKey) and HarfordDnDCalc.GetPB() or 0
    end
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("save", abilityKey)
        or 0
    -- Bonus a TODAS las salvaciones por rasgos (ej. Paladin "Aura de Proteccion": +max(1, Mod. Carisma)).
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetAllSavesAbilities then
        for _, entry in ipairs(HarfordDnDFeatureEffects.GetAllSavesAbilities()) do
            local mod = HarfordDnDCalc.GetAbilityMod(entry.ability)
            local minVal = tonumber(entry.min) or 0
            bonus = bonus + math.max(minVal, mod)
        end
    end
    return HarfordDnDCalc.GetAbilityMod(abilityKey) + bonus,
        HarfordDnDCalc.GetSaveProf(abilityKey) and HarfordDnDCalc.GetPB() or 0
end

-- ─── Tiradas con modo (ventaja/desventaja) y critico ─────────────────────────
function HarfordDnDCalc.RollTextWithMode(mode, a, b)
    if mode == "adv" then
        return math.max(a, b), a, b, "(V) "
    elseif mode == "dis" then
        return math.min(a, b), a, b, "(D) "
    else
        return a, a, nil, ""
    end
end

-- critThreshold: tirada minima del d20 que cuenta como critico (20 por defecto; 19 con
-- rasgos de critico ampliado como "Maquina de Matar"). Ventaja/desventaja se aplican
-- igual con el umbral generalizado (a>=20 equivale a a==20, asi que es compatible).
function HarfordDnDCalc.GetCritTag(mode, a, b, critThreshold)
    critThreshold = tonumber(critThreshold) or 20
    if mode == "dis" then
        if a >= critThreshold and b >= critThreshold then return "CRÍTICO" end
        if a == 1 or b == 1 then return "PIFIA" end
        return ""
    end
    if mode == "adv" then
        if a >= critThreshold or b >= critThreshold then return "CRÍTICO" end
        if a == 1 and b == 1 then return "PIFIA" end
        return ""
    end
    if a >= critThreshold then return "CRÍTICO" end
    if a == 1 then return "PIFIA" end
    return ""
end

-- Concatena los componentes de bonus no-cero como texto con signo ("+3-1").
-- Acepta cualquier numero de componentes (varargs); el orden se respeta tal cual.
function HarfordDnDCalc.BonusConcat(...)
    local parts = {}
    local n = select("#", ...)
    for i = 1, n do
        -- Parentesis: truncar select() a UN valor; sin ellos, el (i+1)-esimo
        -- vararg se pasaria como 'base' a tonumber -> "base out of range".
        local v = tonumber((select(i, ...))) or 0
        if v ~= 0 then parts[#parts + 1] = fmtSigned(v) end
    end
    return table.concat(parts, "")
end

-- Tirada d20 completa con el modo actual de la ficha. Devuelve:
--   chosen  -> el d20 elegido (alto en ventaja, bajo en desventaja)
--   ra, rb  -> los dos dados (rb = nil si no hay ventaja/desventaja)
--   critTag -> "CRÍTICO" | "PIFIA" | ""
--   modeTag -> "V" | "D" | "" (para el campo mode de la tirada difundida)
function HarfordDnDCalc.RollD20Full(rollType, context)
    -- Estados de un solo uso (Palabra de Poder: Fortaleza, Brebaje del Buey Negro): valen para UNA
    -- tirada y se retiran al hacerla. Cuales son lo declara cada condicion, no una lista escrita
    -- aqui. Solo cuentan si el que tira eres tu: son estados TUYOS.
    local propia = context and (context.actorUnit == "player"
        or context.actorGuid == (UnitGUID and UnitGUID("player")))
    local consumir = propia and HarfordDnDConditions
        and HarfordDnDConditions.ConditionsToConsumeAfterRoll
        and HarfordDnDConditions.ConditionsToConsumeAfterRoll(rollType) or nil
    local mode = HarfordDnDCalc.GetMode()
    if rollType and HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode then
        mode = HarfordDnDConditions.ResolveRollMode(mode, rollType, context)
    end
    local _, a, b = HarfordDnDCalc.RollD20(mode)
    local chosen, ra, rb = HarfordDnDCalc.RollTextWithMode(mode, a, b)
    local critTag = HarfordDnDCalc.GetCritTag(mode, a, b)
    local modeTag = (mode == "adv" and "V") or (mode == "dis" and "D") or ""
    for _, id in ipairs(consumir or {}) do
        if HarfordDnDConditions.RemoveOwned then HarfordDnDConditions.RemoveOwned(id) end
    end
    return chosen, ra, rb, critTag, modeTag, mode
end

-- Texto del/los dado(s) d20: "ra/rb→chosen" con ventaja/desventaja, o "chosen".
function HarfordDnDCalc.FormatD20Dice(chosen, ra, rb)
    if rb then
        return tostring(ra) .. "/" .. tostring(rb) .. "→" .. tostring(chosen)
    end
    return tostring(chosen)
end
