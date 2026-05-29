-- HarfordDnDCalc: calculo puro de la ficha D&D 5e (modificadores, dados, bonos).
--
-- No tiene estado de UI ni frames. Lee los valores de la ficha via
-- HarfordDnDContext.Get / HarfordDnDContext.State, por lo que funciona igual en
-- modo jugador y en contexto NPC (overrides). HarfordDnD.lua llama a estas
-- funciones como HarfordDnDCalc.X(...).

HarfordDnDCalc = HarfordDnDCalc or {}

-- Utiles privados (duplicados triviales de los de HarfordDnD.lua para no acoplar).
local function toN(x, d)
    local n = tonumber(x)
    if n == nil then return d or 0 end
    return n
end

local function fmtSigned(n)
    n = toN(n, 0)
    if n >= 0 then return "+" .. n end
    return tostring(n)
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
    return toN(HarfordDnDContext.Get(key, "10"), 10)
end

function HarfordDnDCalc.GetAbilityMod(key)
    return HarfordDnDCalc.AbilityMod(HarfordDnDCalc.GetAbilityScore(key))
end

function HarfordDnDCalc.GetSaveProf(abilityKey)
    return toN(HarfordDnDContext.Get("Salv_" .. abilityKey, "0"), 0) == 1
end

function HarfordDnDCalc.GetWeaponMod()
    return toN(HarfordDnDContext.Get("ModArma", "0"), 0)
end

function HarfordDnDCalc.GetVersatileActive()
    return toN(HarfordDnDContext.Get("Versatil", "0"), 0) == 1
end

-- ─── Bonos compuestos ────────────────────────────────────────────────────────
function HarfordDnDCalc.GetSkillProfBonus(skill)
    local pb = HarfordDnDCalc.GetPB()
    local profFlag = toN(HarfordDnDContext.Get("Hab_" .. skill.id .. "_Prof", "0"), 0)
    local expFlag  = toN(HarfordDnDContext.Get("Hab_" .. skill.id .. "_Exp", "0"), 0)
    if expFlag == 1 then return 2 * pb end
    if profFlag == 1 then return pb end
    return 0
end

function HarfordDnDCalc.GetSkillRollBonuses(skill)
    local State = HarfordDnDContext.State
    local explicit = State.active and State.overrides
        and tonumber(State.overrides["Context_Hab_" .. skill.id .. "_Bonus"])
    if type(explicit) == "number" then
        return explicit, 0
    end
    return HarfordDnDCalc.GetAbilityMod(skill.ability), HarfordDnDCalc.GetSkillProfBonus(skill)
end

function HarfordDnDCalc.GetSaveRollBonuses(abilityKey)
    local State = HarfordDnDContext.State
    local explicit = State.active and State.overrides
        and tonumber(State.overrides["Context_Salv_" .. abilityKey .. "_Bonus"])
    if type(explicit) == "number" then
        return explicit, 0
    end
    return HarfordDnDCalc.GetAbilityMod(abilityKey),
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

function HarfordDnDCalc.GetCritTag(mode, a, b)
    if mode == "dis" then
        if a == 20 and b == 20 then return "CRÍTICO" end
        if a == 1 or b == 1 then return "PIFIA" end
        return ""
    end
    if mode == "adv" then
        if a == 20 or b == 20 then return "CRÍTICO" end
        if a == 1 and b == 1 then return "PIFIA" end
        return ""
    end
    if a == 20 then return "CRÍTICO" end
    if a == 1 then return "PIFIA" end
    return ""
end

function HarfordDnDCalc.BonusConcat(base, prof, misc)
    local parts = {}
    if base ~= 0 then parts[#parts+1] = fmtSigned(base) end
    if prof ~= 0 then parts[#parts+1] = fmtSigned(prof) end
    if misc ~= 0 then parts[#parts+1] = fmtSigned(misc) end
    return table.concat(parts, "")
end
