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

-- Metros que puede recorrer el personaje en un turno. La velocidad la declara la raza en el
-- libro; los rasgos la modifican por `bonus.speed`, y una forma activa la sustituye entera.
function HarfordDnDCalc.GetTurnMovement(profileName)
    local forma = HarfordDnDForms and HarfordDnDForms.GetActiveForm and HarfordDnDForms.GetActiveForm()
    if forma and tonumber(forma.speed) then
        -- Las formas declaran su velocidad en PIES, como el stat block de donde salen.
        return tonumber(forma.speed) * 0.3048
    end
    local base = 9   -- el andar de un Mediano; solo se usa si no hay raza puesta
    if HarfordDnDProgression and HarfordDnDProgression.GetRace and HarfordDnDRaces then
        local razaId = HarfordDnDProgression.GetRace(profileName)
        local raza = razaId and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(razaId)
        if raza and tonumber(raza.speed) then base = tonumber(raza.speed) end
    end
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetSpeed then
        return HarfordDnDFeatureEffects.GetSpeed(base, profileName)
    end
    return base
end

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
    -- Solo se NIEGA la competencia cuando la categoria tiene una clave declarable y el personaje
    -- no la tiene. `Racial`, `Especial`, `Otros` y las formas del Druida no se declaran por
    -- categoria en ninguna parte: negarles el bono lo quitaba sin que nada lo dijera, y antes de
    -- esta funcion el bono era incondicional.
    if not claveCat then return true end
    return false
end

-- `def` es el ARMA de la tirada, y es opcional: los estilos de combate CONDICIONALES solo suman
-- con su contexto delante. Sin `def` (rutas que no saben con que arma se tira) no suman -- mejor
-- cero que un bono falso, que era justo el defecto: Tiro con Arco subia tambien los ataques cuerpo
-- a cuerpo, y Duelo daba +2 con cualquier arma. Mismo patron que greatWeaponFighting: el flag se
-- evalua donde vive el contexto, no como bono global.
function HarfordDnDCalc.GetWeaponAttackBonus(def)
    if IsNpcContext() then return 0 end
    local FE = HarfordDnDFeatureEffects
    local bonus = FE and FE.GetBonus and FE.GetBonus("weaponAttack") or 0
    if def and def.mode == "Ranged" and FE and FE.HasFlag then
        if FE.HasFlag("styleArchery") then bonus = bonus + 2 end
        if FE.HasFlag("styleSharpshooter") then bonus = bonus + 1 end
    end
    return bonus
end

function HarfordDnDCalc.GetWeaponDamageBonus(def)
    if IsNpcContext() then return 0 end
    local FE = HarfordDnDFeatureEffects
    local bonus = FE and FE.GetBonus and FE.GetBonus("weaponDamage") or 0
    -- Duelo: +2 al dano con un arma cuerpo a cuerpo a UNA mano y NINGUNA otra cosa en la
    -- secundaria. Un arma Versatil usada a una mano cuenta (no lleva la propiedad "Dos manos").
    if def and def.mode == "Melee" and FE and FE.HasFlag and FE.HasFlag("styleDueling") then
        local dosManos = false
        for _, p in ipairs(def.props or {}) do
            if tostring(p) == "Dos manos" then dosManos = true break end
        end
        local offhand = HarfordDnDItems and HarfordDnDItems.HasOffhandCombatItem
            and HarfordDnDItems.HasOffhandCombatItem()
        if not dosManos and not offhand then bonus = bonus + 2 end
    end
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

-- Puntuacion PASIVA de una habilidad (regla 5e): 10 + bono TOTAL de la habilidad (modificador
-- + competencia/pericia + bonos de rasgos/objetos). No hay tirada: es el valor que el DM
-- compara (Sigilo del que se esconde contra tu Percepcion pasiva). La dote Observador suma
-- su +5 via el bono passivePerception/passiveInvestigation.
function HarfordDnDCalc.GetPassiveScore(skillId)
    local skill
    for _, s in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
        if s.id == skillId then skill = s break end
    end
    if not skill then return nil end
    local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)
    local extra = 0
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus then
        local target = skillId == "Percepcion" and "passivePerception"
            or skillId == "Investigacion" and "passiveInvestigation" or nil
        if target then extra = tonumber(HarfordDnDFeatureEffects.GetBonus(target)) or 0 end
    end
    return 10 + (tonumber(base) or 0) + (tonumber(prof) or 0) + extra
end

function HarfordDnDCalc.GetPassivePerception()
    return HarfordDnDCalc.GetPassiveScore("Percepcion")
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
    -- El GUID solo identifica si EXISTE: `nil == nil` es verdadero, asi que sin este guard una
    -- tirada ajena que no traiga `actorGuid` se contaria como tuya y te gastaria el estado.
    local miGuid = UnitGUID and UnitGUID("player")
    local propia = context and (context.actorUnit == "player"
        or (context.actorGuid ~= nil and context.actorGuid == miGuid))
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
