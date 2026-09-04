-- Descansos de la ficha (corto, largo, dados de golpe y su menu), extraidos de
-- HarfordDnD.lua (fase C de refactorizacion). Mismo patron Build(D) que
-- HarfordDnDActionPanel: la ficha lo llama donde vivia el cluster, con sus dependencias
-- ya vivas, y recibe las cuatro funciones que antes eran locales suyos. Los refrescos
-- llegan como closures de late-binding porque se asignan despues de ese punto.

HarfordDnDRest = HarfordDnDRest or {}

function HarfordDnDRest.Build(D)
    local K = D.K
    local Print = D.Print
    local fmtSigned = D.fmtSigned
    local SheetContext = D.SheetContext
    local ResourceFrame = D.ResourceFrame
    local GetResourceCurrent = D.GetResourceCurrent
    local GetResourceMax = D.GetResourceMax
    local SetResourceCurrent = D.SetResourceCurrent
    local AdjustResourceCurrent = D.AdjustResourceCurrent
    local RefreshResourceFrame = D.RefreshResourceFrame
    local RefreshTargetResourceFrame = D.RefreshTargetResourceFrame
    local ApplyShortRest, ApplyLongRest, RollHitDieHeal, RefreshRestMenu

ApplyShortRest = function()
    -- El descanso corto ya NO auto-cura: la curacion se hace gastando DADOS DE GOLPE
    -- (boton dedicado del menu de descanso). Solo recupera recursos de recarga "short".
    for _, key in ipairs(K.RESOURCE_ORDER) do
        if key ~= "health" then
            local recharge = HarfordDnDResources.GetRecharge(key)
            if recharge == "short" then
                SetResourceCurrent(key, GetResourceMax(key))
            elseif recharge == "reset" then
                SetResourceCurrent(key, 0)  -- pool de combate (Furia): el descanso lo vacia
            end
        end
    end

    -- Recuperaciones PARCIALES declaradas por rasgos (ej. Sacerdote "Restauracion de los fieles":
    -- 2 puntos de fe en descanso corto). Van despues de las recargas para no pisarlas, y se
    -- acotan al maximo del recurso.
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetRestRestores then
        for key, amount in pairs(HarfordDnDFeatureEffects.GetRestRestores("short") or {}) do
            local cantidad = math.floor(tonumber(amount) or 0)
            if cantidad > 0 then
                local maximo = GetResourceMax(key)
                if maximo > 0 then
                    SetResourceCurrent(key, math.min(maximo, GetResourceCurrent(key) + cantidad))
                end
            end
        end
    end

    -- MAGIA DE PACTO (Brujo): sus ranuras recargan en descanso CORTO, no en el largo como las del
    -- resto. Hasta ahora no volvian hasta el descanso largo, que es sencillamente incorrecto para
    -- la clase (su tabla tiene 1 o 2 ranuras: sin esto el brujo se quedaba seco toda la sesion).
    --
    -- LIMITACION conocida: los gastados se guardan en UN solo mapa por nivel
    -- (`data.spellSlots[nivel]`), compartido entre el pacto y la piramide normal. Por eso se
    -- devuelven COMO MUCHO tantas ranuras como le tocan al brujo, y solo en SU nivel de pacto:
    -- en un brujo puro las recupera todas, y en un multiclase nunca regala mas de lo que el pacto
    -- concede. Separar los dos pools (como ya se hizo con `spellSlotsBonus`) lo haria exacto.
    if HarfordDnDMana and HarfordDnDProgression and HarfordDnDProgression.SetPactSpent then
        -- Las ranuras de PACTO llevan su propia cuenta, asi que el descanso corto las devuelve
        -- TODAS y solo esas. Antes se descontaban del pool comun de su nivel y en un multiclase de
        -- brujo eso regalaba espacios de la otra clase en cada descanso corto.
        if HarfordDnDProgression.GetPactSpent(GetProfileName and GetProfileName() or nil) > 0 then
            HarfordDnDProgression.SetPactSpent(0)
        end
    end

    -- Recupera los usos de rasgos de recarga "short" (Tambaleo, Marca de Ursol, etc.).
    if HarfordDnDFeatureUses and HarfordDnDFeatureUses.ResetOnRest then
        HarfordDnDFeatureUses.ResetOnRest("short")
    end

    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then
        RefreshResourceFrame()
    end
    if RefreshTargetResourceFrame then
        RefreshTargetResourceFrame()
    end
    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
        _G.DND5E_ARC_API.Refresh()
    end
end

ApplyLongRest = function()
    -- El descanso largo cura toda la vida y recupera los recursos de recarga
    -- "short" y "long" (los "none", como vida temporal, no se tocan).
    SetResourceCurrent("health", GetResourceMax("health"))

    for _, key in ipairs(K.RESOURCE_ORDER) do
        if key ~= "health" then
            local recharge = HarfordDnDResources.GetRecharge(key)
            if recharge == "short" or recharge == "long" then
                SetResourceCurrent(key, GetResourceMax(key))
            elseif recharge == "reset" then
                SetResourceCurrent(key, 0)  -- pool de combate (Furia): el descanso lo vacia
            end
        end
    end

    -- Recupera la mitad (min 1) de los dados de golpe gastados (regla 5e).
    if HarfordDnDHitDice and HarfordDnDHitDice.RegainOnLongRest then
        HarfordDnDHitDice.RegainOnLongRest()
    end

    -- Recuperaciones PARCIALES declaradas por rasgos (ej. Sacerdote "Restauracion de los fieles":
    -- 2 puntos de fe en descanso corto). Van despues de las recargas para no pisarlas, y se
    -- acotan al maximo del recurso.
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetRestRestores then
        for key, amount in pairs(HarfordDnDFeatureEffects.GetRestRestores("long") or {}) do
            local cantidad = math.floor(tonumber(amount) or 0)
            if cantidad > 0 then
                local maximo = GetResourceMax(key)
                if maximo > 0 then
                    SetResourceCurrent(key, math.min(maximo, GetResourceCurrent(key) + cantidad))
                end
            end
        end
    end

    -- Recupera TODOS los usos de rasgos (recarga "short" y "long").
    if HarfordDnDFeatureUses and HarfordDnDFeatureUses.ResetOnRest then
        HarfordDnDFeatureUses.ResetOnRest("long")
    end

    if HarfordDnDProgression and HarfordDnDProgression.ResetSpellSlots then
        HarfordDnDProgression.ResetSpellSlots()
    end
    if HarfordDnDProgression and HarfordDnDProgression.ResetRestCounters then
        HarfordDnDProgression.ResetRestCounters()
    end

    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then
        RefreshResourceFrame()
    end
    if RefreshTargetResourceFrame then
        RefreshTargetResourceFrame()
    end
    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
        _G.DND5E_ARC_API.Refresh()
    end

    -- Tras el descanso largo, ofrecer reelegir conjuros preparados (silencioso si el PJ no prepara).
    if _G.HarfordOpenPrepareSpellsMenu then _G.HarfordOpenPrepareSpellsMenu(true) end
    -- Y los rasgos `choice` con `rechooseOnLongRest` (Forja de runas del CdM): mismo flujo,
    -- silencioso si el PJ no tiene ninguno.
    if _G.HarfordOpenLongRestChoicesMenu then _G.HarfordOpenLongRestChoicesMenu(true) end
end

-- Gasta un dado de golpe del tipo indicado y cura dX + Mod. Constitucion (min 0).
-- Sirve tanto para el descanso corto como para el "Segundo Aliento" del Guerrero.
RollHitDieHeal = function(sides, sourceFeature)
    if not (HarfordDnDHitDice and HarfordDnDHitDice.SpendDie) then return false end
    if SheetContext and SheetContext.active then return false end  -- solo ficha de jugador propio
    if not HarfordDnDHitDice.SpendDie(sides) then
        HarfordChat.Print("|cffff5555No quedan dados de golpe d" .. tostring(sides) .. "|r")
        return false
    end

    if sourceFeature and HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        HarfordDnDRolls.BroadcastAbility(sourceFeature)
    end

    local roll = HarfordDnDCalc.RollDie(sides)
    -- Regeneracion Troll (flag trollRegenHitDie): el dado de golpe cura el DOBLE del Mod. CON.
    local conMult = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("trollRegenHitDie")) and 2 or 1
    local conMod = HarfordDnDCalc.GetAbilityMod("Constitucion") * conMult
    local heal = roll + conMod
    if heal < 1 then heal = 1 end

    AdjustResourceCurrent("health", heal)
    -- Queda como ULTIMA TIRADA con sus dados, para lo que pueda repetirla despues (Oracion de
    -- Curacion del Sacerdote). Sin los dados registrados no hay nada que repetir.
    if HarfordDnDRolls.RecordHealRoll then
        HarfordDnDRolls.RecordHealRoll({
            label = "Dado de Golpe d" .. sides,
            total = heal, aplicadoA = "self",
            healDice = { { count = 1, sides = sides, bonus = conMod } },
            healRolls = { roll },
        })
    end
    HarfordDnDRolls.Broadcast({
        type = "heal",
        label = "Dado de Golpe d" .. sides .. " (cura)",
        total = heal,
        dice = tostring(roll),
        modifiers = (conMod ~= 0 and fmtSigned(conMod) or ""),
        critical = "",
        mode = "",
    })
    return true
end

-- Segundo Aliento reutiliza exactamente el flujo de dado de golpe: el Guerrero
-- gasta un d10 disponible y la curacion se anuncia/sincroniza por la misma ruta.
HarfordDnDStore.UseSecondWind = function()
    return RollHitDieHeal and RollHitDieHeal(10, {
        id = "gue_segundo_aliento",
        name = "Segundo Aliento",
        description = "Como accion adicional, gastas un dado de golpe d10 para recuperar PG.",
    }) or false
end

RefreshRestMenu = function()
    -- El frame y sus widgets viven en HarfordDnDStore (no en locales de file-scope):
    -- esta funcion se define ~480 lineas debajo del bloque del menu y el chunk roza el
    -- limite de 200 locales, asi que la local `RestMenu` no se captura aqui como upvalue.
    local menu = HarfordDnDStore.restMenu
    local buttons = HarfordDnDStore.restHitDiceButtons
    if not (menu and buttons) then return end
    for _, b in pairs(buttons) do b:Hide() end

    local list = (HarfordDnDHitDice and HarfordDnDHitDice.GetSummaryList
        and HarfordDnDHitDice.GetSummaryList()) or {}

    local shown, y = 0, -84
    for _, e in ipairs(list) do
        local b = buttons[e.sides]
        if b then
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", menu, "TOPLEFT", 15, y)
            b:SetText(string.format("d%d  (%d/%d)", e.sides, e.available, e.max))
            if e.available > 0 then b:Enable() else b:Disable() end
            b:Show()
            shown = shown + 1
            y = y - 22
        end
    end

    if HarfordDnDStore.restHitLabel then
        HarfordDnDStore.restHitLabel:SetShown(shown > 0)
    end
    menu:SetHeight(shown > 0 and (74 + 12 + shown * 22) or 70)
end

    return {
        ApplyShortRest = ApplyShortRest,
        ApplyLongRest = ApplyLongRest,
        RollHitDieHeal = RollHitDieHeal,
        RefreshRestMenu = RefreshRestMenu,
    }
end
