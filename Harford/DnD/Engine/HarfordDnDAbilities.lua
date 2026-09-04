-- Activaciones de rasgos de clase con mecanica propia.
--
-- Salen de HarfordDnD.lua porque no son UI: son reglas. Cada una gasta su recurso, tira lo que
-- toque por los motores comunes y anuncia. Cuelgan de `HarfordDnDStore` igual que antes, asi que
-- ningun llamador cambia.
--
-- Lo que necesitan de la ficha (la tirada de arma, la aura al impactar) se inyecta con `Init`:
-- este modulo no crea frames ni toca el layout.

local ApplyConditionalHitAura, DoWeaponAttack, IsPriestSpell, Print, GetWeaponDef, GetWeaponKey
local SheetContext

HarfordDnDAbilities = HarfordDnDAbilities or {}

function HarfordDnDAbilities.Init(deps)
    deps = deps or {}
    ApplyConditionalHitAura = deps.ApplyConditionalHitAura or ApplyConditionalHitAura
    DoWeaponAttack = deps.DoWeaponAttack or DoWeaponAttack
    IsPriestSpell = deps.IsPriestSpell or IsPriestSpell
    Print = deps.Print or Print
    GetWeaponDef = deps.GetWeaponDef or GetWeaponDef
    GetWeaponKey = deps.GetWeaponKey or GetWeaponKey
    SheetContext = deps.SheetContext or SheetContext
end

-- Mordida de Demonio: dos ataques de arma como accion adicional tras Atacar. El
-- gasto ocurre al activar el rasgo; cada ataque mantiene su propia tirada contra
-- la CA y nunca suma el modificador de caracteristica al daño.
HarfordDnDStore.UseDemonBite = function()
    if SheetContext and SheetContext.active then return false end
    if not (UnitExists and UnitExists("target"))
        or (UnitIsUnit and UnitIsUnit("target", "player")) then
        Print("Selecciona un objetivo para Mordida de Demonio.")
        return false
    end
    local def = GetWeaponDef(GetWeaponKey())
    if not def or def.mode ~= "Melee" or def.key == "Escudo" then
        Print("Mordida de Demonio requiere un arma cuerpo a cuerpo.")
        return false
    end
    if not (HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.AdjustResourceCurrent)
        or HarfordDnDStore.GetResourceCurrent("fel_point") < 1 then
        Print("No tienes Vil suficiente para Mordida de Demonio.")
        return false
    end

    local targetGuid = UnitGUID and UnitGUID("target") or nil
    if not targetGuid then
        Print("No se pudo identificar el objetivo de Mordida de Demonio.")
        return false
    end
    local last = HarfordDnDStore.lastWeaponAttack
    local now = GetTime and GetTime() or 0
    if not last or last.targetGuid ~= targetGuid or now - (tonumber(last.at) or 0) > 6 then
        Print("Mordida de Demonio debe usarse justo despues de atacar a ese objetivo.")
        return false
    end
    HarfordDnDStore.AdjustResourceCurrent("fel_point", -1)
    if HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        HarfordDnDRolls.BroadcastAbility({
            id = "dh_mordida_demonio",
            name = "Mordida de Demonio",
            description = "Tras atacar con un arma, gastas 1 punto de Vil para realizar dos ataques con arma como accion adicional.",
        }, { targetUnit = "target" })
    end
    local golpe1 = DoWeaponAttack({
        expectedTargetGuid = targetGuid,
        suppressAbilityDamage = true,
        demonBite = true,
        labelSuffix = "[Mordida de Demonio]",
    })
    local golpe2 = DoWeaponAttack({
        expectedTargetGuid = targetGuid,
        suppressAbilityDamage = true,
        demonBite = true,
        labelSuffix = "[Mordida de Demonio]",
    })
    -- MOMENTUM VENGATIVO (Devoradora 6): si AMBOS impactan, recuperas el punto de Vil. Solo
    -- cuando la CA se pudo resolver en los dos (true estricto): con nil no se sabe si impacto,
    -- y devolver recurso por un golpe dudoso seria regalarlo -- ahi queda manual, como antes.
    if golpe1 == true and golpe2 == true
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("vengefulMomentum") then
        HarfordDnDStore.AdjustResourceCurrent("fel_point", 1)
        if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
            HarfordDnDRolls.Broadcast({ type = "info",
                label = "recupera 1 Vil (Momentum vengativo)" })
        end
    end
    return true
end

-- Dado de Caos del Cazador de Demonios, por su tabla de clase: d4 (niveles 2-4), d6 (5-8),
-- d8 (9+). Con multiclase cuenta SOLO el nivel de Cazador de Demonios.
local function ChaosDieSides()
    local nivel = 0
    for _, e in ipairs((HarfordDnDProgression and HarfordDnDProgression.GetClassLevels
        and HarfordDnDProgression.GetClassLevels()) or {}) do
        if tostring(e.classId) == "cazador_demonios" then nivel = nivel + (tonumber(e.level) or 0) end
    end
    if nivel >= 9 then return 8 end
    if nivel >= 5 then return 6 end
    if nivel >= 2 then return 4 end
    return 0
end

-- EMBESTIDA VIL (Devoradora 3): rider de Momentum. Se tira el dado de Caos y se publica cuanto
-- fuego vil recibe quien atraviese el recorrido; a quien se lo lleva lo decide la mesa (el
-- recorrido es geometria del mundo que el cliente no ve), asi que no se aplica dano a nadie aqui.
HarfordDnDStore.AnnounceFelRush = function()
    local caras = ChaosDieSides()
    if caras <= 0 then return end
    local dano = (HarfordDnDCalc and HarfordDnDCalc.RollDie and HarfordDnDCalc.RollDie(caras))
        or math.random(1, caras)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info",
            label = string.format("Embestida vil 1d%d=%d fuego vil a quien atraviese el recorrido", caras, dano) })
    end
end

-- Sacerdocio de Elune: la Gracia consume Canalizar Divinidad y deja un estado
-- temporal de diez rondas en el objetivo actual o, sin objetivo, en su lanzador.
HarfordDnDStore.UseElunesGrace = function()
    if SheetContext and SheetContext.active then return false end
    if not (HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.AdjustResourceCurrent
        and HarfordDnDConditions and HarfordDnDConditions.ApplyToUnit) then
        Print("El sistema de recursos o condiciones no esta disponible.")
        return false
    end
    if HarfordDnDStore.GetResourceCurrent("channel_divinity") < 1 then
        Print("No quedan usos de Canalizar Divinidad.")
        return false
    end
    local unit = (UnitExists and UnitExists("target")) and "target" or "player"
    local ok, err = HarfordDnDConditions.ApplyToUnit(unit, "elunes_grace", {
        duration = "rounds", turns = 10,
        sourceGuid = UnitGUID and UnitGUID("player") or "",
        sourceName = HarfordClassColors.UnitFullName("player"),
    })
    if not ok then
        Print(tostring(err or "No se pudo aplicar Gracia de Elune."))
        return false
    end
    HarfordDnDStore.AdjustResourceCurrent("channel_divinity", -1)
    HarfordDnDRolls.BroadcastAbility({
        id = "sac_elu_gracia", name = "Gracia de Elune",
        description = "Como accion adicional, gastas Canalizar Divinidad para bendecir a una criatura durante 1 minuto.",
    }, { targetUnit = unit })
    return true
end

-- Furia de Elune se resuelve enteramente al activarla: gasta un uso y ejecuta el
-- ataque adicional. No deja un estado temporal pendiente ni depende del siguiente
-- conjuro que se lance desde el Compendio.
HarfordDnDStore.PrepareFuryOfElune = function()
    if SheetContext and SheetContext.active then return false end
    if not (UnitExists and UnitExists("target")) or (UnitIsUnit and UnitIsUnit("target", "player")) then
        Print("Furia de Elune requiere un objetivo para el ataque adicional.")
        return false
    end
    if not (HarfordDnDFeatureUses and HarfordDnDFeatureUses.Spend) then return false end
    local profileName = UnitName and UnitName("player") or "Personaje"
    if not HarfordDnDFeatureUses.Spend("sac_elu_furia", profileName) then
        Print("No quedan usos de Furia de Elune.")
        return false
    end
    local feature = { id = "sac_elu_furia", name = "Furia de Elune" }
    HarfordDnDRolls.BroadcastAbility(feature, { targetUnit = "target" })
    DoWeaponAttack({ labelSuffix = "[Furia de Elune]" })
    if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
        HarfordCharacterPanel.RefreshBookIfShown()
    end
    return true
end

-- Marca del Cazador es una accion sobre la presa actual, no un dano que se
-- prepara desde el menu de ataque. Su identidad vive solo en runtime: una nueva
-- marca sustituye a la anterior y el dado vuelve a estar disponible en tu turno.
HarfordDnDStore.IsHuntersMarkTarget = function(unit)
    local mark = HarfordDnDStore.huntersMark
    local guid = UnitGUID and UnitGUID(unit or "target") or nil
    return mark and mark.guid and guid and mark.guid == guid and not mark.usedThisTurn
end

HarfordDnDStore.ResetHuntersMarkTurn = function()
    if HarfordDnDStore.huntersMark then
        HarfordDnDStore.huntersMark.usedThisTurn = false
    end
end

HarfordDnDStore.UseHuntersMark = function(feature)
    if SheetContext and SheetContext.active then return false end
    if not (UnitExists and UnitExists("target")) or (UnitIsUnit and UnitIsUnit("target", "player")) then
        Print("Marca del Cazador requiere un objetivo.")
        return false
    end
    local guid = UnitGUID and UnitGUID("target") or nil
    if not guid then
        Print("No se pudo identificar el objetivo de Marca del Cazador.")
        return false
    end
    HarfordDnDStore.huntersMark = {
        guid = guid,
        name = HarfordClassColors.UnitFullName("target"),
        usedThisTurn = false,
    }
    local auraId = tonumber(feature and feature.markAuraId) or 0
    if auraId > 0 then
        local ok, err = ApplyConditionalHitAura(auraId, true)
        if ok == false and err and DEFAULT_CHAT_FRAME then
            HarfordChat.Print(err)
        end
    end
    if HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        HarfordDnDRolls.BroadcastAbility(feature or {
            id = "caz_marca_cazador", name = "Marca del Cazador",
        }, { targetUnit = "target" })
    end
    return true
end

-- Palabra de Poder: Muerte no gasta Fe al prepararse. Solo se consume cuando el
-- siguiente conjuro de sacerdote CON daño confirma su lanzamiento.
HarfordDnDStore.PreparePowerWordDeath = function(feature, option)
    if SheetContext and SheetContext.active then return false end
    if not (HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.GetResourceCurrent("light_point") >= 1) then
        Print("No hay puntos de fe suficientes para preparar Muerte.")
        return false
    end
    HarfordDnDStore.preparedPowerWordDeath = {
        feature = feature, option = option,
        expiresAt = (GetTime and GetTime() or 0) + 60,
    }
    if HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        HarfordDnDRolls.BroadcastAbility({
            id = "sac_palabra_poder_muerte",
            name = "Palabra de Poder: Muerte",
            description = option and option.desc,
        })
    end
    return true
end

HarfordDnDStore.ConsumePreparedPowerWordDeath = function(spell, definition)
    local prepared = HarfordDnDStore.preparedPowerWordDeath
    if not prepared then return 0 end
    local now = GetTime and GetTime() or 0
    if now > (tonumber(prepared.expiresAt) or 0) then
        HarfordDnDStore.preparedPowerWordDeath = nil
        return 0
    end
    local components = definition and definition.damageComponents
    if not (IsPriestSpell(spell) and type(components) == "table" and #components > 0) then return 0 end
    if HarfordDnDStore.GetResourceCurrent("light_point") < 1 then return 0 end
    HarfordDnDStore.preparedPowerWordDeath = nil
    HarfordDnDStore.AdjustResourceCurrent("light_point", -1)
    local count = math.max(1, HarfordDnDCalc.GetAbilityMod("Carisma") or 0)
    return count
end
