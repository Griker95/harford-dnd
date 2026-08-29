------------------------------------------------------------
-- HarfordDnDManeuvers - Maniobras de combate del Manual del Jugador que no son un ataque:
-- agarrar, empujar, escapar de un agarre, estabilizar a un aliado y cobertura.
--
-- Reglas literales del manual:
--
--  AGARRAR: sustituye a uno de tus ataques. El objetivo debe estar a tu alcance y ser como
--  mucho una categoria de tamano mayor que tu. En vez de tirada de ataque, prueba de Fuerza
--  (Atletismo) ENFRENTADA a Fuerza (Atletismo) o Destreza (Acrobacias) del objetivo, A ELECCION
--  DEL OBJETIVO. Con exito le aplicas "agarrado". Puedes soltarlo cuando quieras sin accion.
--
--  ESCAPAR: la criatura agarrada usa su ACCION y hace Fuerza (Atletismo) o Destreza
--  (Acrobacias) enfrentada a la Fuerza (Atletismo) de quien la agarra.
--
--  EMPUJAR: igual que agarrar, pero al ganar eliges DERRIBAR o alejar 5 pies (1,5 m).
--
--  ESTABILIZAR: accion, prueba de Sabiduria (Medicina) CD 10 sobre una criatura inconsciente a
--  0 puntos de golpe. Con los utiles de sanador se estabiliza SIN prueba, gastando un uso.
--  Una criatura estable no tira salvaciones de muerte, sigue inconsciente, y deja de estar
--  estable si recibe cualquier dano.
--
--  COBERTURA: media +2 a CA y salvaciones de Destreza, tres cuartos +5, total no se puede
--  elegir como objetivo. No se acumulan: solo cuenta la mayor.
--
-- POR QUE LA COBERTURA SE DECLARA Y NO SE CALCULA: el addon conoce posiciones, pero no la
-- geometria del mundo; no hay forma de saber que hay un muro en medio. Declararla es lo que
-- hace un DM en mesa. La UNICA que seria calculable es la de criatura interpuesta, y esa se
-- deja para cuando se quiera atar al motor de area, que ya maneja posiciones.
--
-- Las tiradas enfrentadas del defensor las hace SU cliente: aqui se emite la peticion y se
-- resuelve con lo que responda, igual que las salvaciones de las maniobras de picaro.
------------------------------------------------------------

HarfordDnDManeuvers = HarfordDnDManeuvers or {}
local API = HarfordDnDManeuvers

local function Print(text)
    if HarfordChat and HarfordChat.Print then HarfordChat.Print(text) end
end

local function Announce(text)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info", label = text })
    else
        Print(text)
    end
end

------------------------------------------------------------
-- Pruebas enfrentadas
------------------------------------------------------------

-- Bonificador total de una habilidad: modificador de su caracteristica mas competencia. Se
-- resuelve con la entrada real de HarfordDnDData.SKILLS, que es donde vive la caracteristica
-- que rige cada una (Atletismo->Fuerza, Acrobacias->Destreza, Medicina->Sabiduria).
local function SkillEntry(skillName)
    for _, skill in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
        if skill.id == skillName or skill.name == skillName then return skill end
    end
    return nil
end

local function SkillBonus(skillName)
    local skill = SkillEntry(skillName)
    if not (skill and HarfordDnDCalc and HarfordDnDCalc.GetSkillRollBonuses) then return 0 end
    local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)
    return (tonumber(base) or 0) + (tonumber(prof) or 0)
end

local function RollSkill(skillName, label)
    local d20 = math.random(1, 20)
    local bonus = SkillBonus(skillName)
    local total = d20 + bonus
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = label,
            total = total,
            dice = tostring(d20),
            modifiers = bonus ~= 0 and string.format("%s%d", bonus > 0 and "+" or "", bonus) or "",
            critical = d20 == 20 and "CRITICO" or (d20 == 1 and "FALLO" or nil),
        })
    end
    return total, d20, bonus
end

local function TargetName(unit)
    if UnitExists and UnitExists(unit) and UnitName then return (UnitName(unit)) end
    return "el objetivo"
end

------------------------------------------------------------
-- Agarrar y empujar
------------------------------------------------------------

-- Prueba del atacante. El defensor elige Atletismo o Acrobacias, asi que su parte se le pide a
-- el; aqui se emite la tirada y se deja constancia de contra que hay que enfrentarla.
local function ContestedAttack(kind, unit)
    unit = unit or "target"
    if not (UnitExists and UnitExists(unit)) then
        Print("|cffff5555No tienes objetivo.|r")
        return false, "sin objetivo"
    end
    local name = TargetName(unit)
    local etiqueta = (kind == "shove" and "Empujar" or "Agarrar") .. ": Atletismo <" .. name .. ">"
    local total = RollSkill("Atletismo", etiqueta)
    Announce(string.format("%s a %s: %s debe superar %d con Atletismo o Acrobacias.",
        kind == "shove" and "intenta empujar" or "intenta agarrar", name, name, total))
    return true, total
end

function API.Grapple(unit)
    return ContestedAttack("grapple", unit)
end

function API.Shove(unit)
    return ContestedAttack("shove", unit)
end

-- Resolucion cuando ya se conoce la tirada del defensor. `choice` solo aplica al empujon:
-- "prone" para derribar o "push" para alejar 1,5 m.
function API.ResolveContest(kind, unit, attackerTotal, defenderTotal, choice)
    unit = unit or "target"
    local name = TargetName(unit)
    attackerTotal = tonumber(attackerTotal) or 0
    defenderTotal = tonumber(defenderTotal) or 0
    -- El manual resuelve los empates a favor del defensor: hay que GANAR la prueba.
    if attackerTotal <= defenderTotal then
        Announce(string.format("no consigue %s a %s (%d contra %d).",
            kind == "shove" and "empujar" or "agarrar", name, attackerTotal, defenderTotal))
        return false
    end
    if kind == "shove" and choice == "push" then
        Announce(string.format("empuja a %s 1,5 m hacia atras.", name))
        return true, "push"
    end
    local condition = kind == "shove" and "prone" or "grappled"
    if HarfordDnDConditions and HarfordDnDConditions.ApplyToUnit then
        HarfordDnDConditions.ApplyToUnit(unit, condition, { sourceName = UnitName and UnitName("player") })
    end
    Announce(string.format(kind == "shove" and "derriba a %s." or "agarra a %s.", name))
    return true, condition
end

-- La criatura agarrada gasta su ACCION para escapar: elige Atletismo o Acrobacias.
function API.Escape(skillName)
    skillName = (skillName == "Acrobacias") and "Acrobacias" or "Atletismo"
    if HarfordDnDConditions and HarfordDnDConditions.Has
        and not HarfordDnDConditions.Has("player", "grappled") then
        Print("|cffffcc00No estas agarrado.|r")
        return false, "no agarrado"
    end
    local total = RollSkill(skillName, "Escapar del agarre: " .. skillName)
    Announce(string.format("intenta escapar del agarre: %d a superar por quien lo sujeta.", total))
    return true, total
end

-- Se aplica cuando la prueba de escape gana: retira el agarre.
function API.ConfirmEscape()
    if HarfordDnDConditions and HarfordDnDConditions.RemoveOwned then
        HarfordDnDConditions.RemoveOwned("grappled")
    end
    Announce("escapa del agarre.")
    return true
end

-- Soltar a quien tienes agarrado: el manual no exige accion.
function API.ReleaseGrapple(unit)
    unit = unit or "target"
    if HarfordDnDConditions and HarfordDnDConditions.RemoveFromUnit then
        HarfordDnDConditions.RemoveFromUnit(unit, "grappled")
    end
    Announce(string.format("suelta a %s.", TargetName(unit)))
    return true
end

------------------------------------------------------------
-- Estabilizar
------------------------------------------------------------

-- Prueba de Sabiduria (Medicina) CD 10 sobre una criatura inconsciente a 0 puntos de golpe.
-- Con `useKit` se estabiliza SIN prueba, gastando un uso de los utiles de sanador.
function API.Stabilize(unit, useKit)
    unit = unit or "target"
    local name = TargetName(unit)
    if useKit then
        Announce(string.format("usa los utiles de sanador y estabiliza a %s sin necesidad de prueba.", name))
        return true, "kit"
    end
    local total = RollSkill("Medicina", string.format("Estabilizar (CD 10) <%s>", name))
    local ok = total >= 10
    Announce(ok and string.format("estabiliza a %s.", name)
        or string.format("no consigue estabilizar a %s.", name))
    return ok, total
end

------------------------------------------------------------
-- Cobertura
------------------------------------------------------------

-- Los niveles de cobertura que Harford permite declarar. No se acumulan: solo cuenta la mayor.
API.COVER = {
    none    = { id = "none",  label = "Sin cobertura",  ac = 0 },
    half    = { id = "half",  label = "Media",          ac = 2 },
    three   = { id = "three", label = "Cobertura alta", ac = 5 },
}
API.COVER_ORDER = { "none", "half", "three" }

local currentCover = "none"

function API.GetCover()
    return currentCover, API.COVER[currentCover]
end

function API.SetCover(level)
    level = tostring(level or "none")
    if not API.COVER[level] then return false end
    currentCover = level
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

-- Bonificador de CA y salvaciones de Destreza que da la cobertura declarada.
function API.GetCoverBonus(level)
    local def = API.COVER[level or currentCover]
    return def and def.ac or nil
end

-- CA efectiva del objetivo con la cobertura aplicada.
function API.ApplyCoverToArmorClass(baseAC, level)
    local bonus = API.GetCoverBonus(level)
    if bonus == nil then return nil end
    return (tonumber(baseAC) or 10) + bonus
end
