-- Tiradas grandes de la ficha: dano de arma, maniobras con salvacion posterior, la salvacion que
-- pide otro cliente y el nucleo de tirada con ventaja/desventaja.
--
-- Salen de HarfordDnD.lua por tamano: `RollWeaponDamage` sola son 345 lineas y concentra critico,
-- dano por tipo, mitigacion, Gran Arma y los danos condicionales. Estaba muy poco acoplada -- una
-- sola llamada desde fuera -- asi que se puede aislar sin arrastrar la UI.
--
-- Reglas y calculo; NO crea frames. Lo que necesita de la ficha se inyecta con `Init`.

HarfordDnDWeaponRolls = HarfordDnDWeaponRolls or {}

local ActorIsPlayer, ApplyConditionalDamageRiders, ApplyConditionalHitEffect, ApplyRequestedSaveAuraSelf, ConsumeMode, DamageTypeLabel, FormatCheckRollLabel, FormatSaveOutcome, FormatSaveRollLabel, GetWeaponSlotDamageBonus, OpcionesGolpeMagico, RequestPlayerTargetSave, WeaponRollName, fmtSigned, toN, K, SheetContext

function HarfordDnDWeaponRolls.Init(deps)
    deps = deps or {}
    ActorIsPlayer = deps.ActorIsPlayer or ActorIsPlayer
    ApplyConditionalDamageRiders = deps.ApplyConditionalDamageRiders or ApplyConditionalDamageRiders
    ApplyConditionalHitEffect = deps.ApplyConditionalHitEffect or ApplyConditionalHitEffect
    ApplyRequestedSaveAuraSelf = deps.ApplyRequestedSaveAuraSelf or ApplyRequestedSaveAuraSelf
    ConsumeMode = deps.ConsumeMode or ConsumeMode
    DamageTypeLabel = deps.DamageTypeLabel or DamageTypeLabel
    FormatSaveOutcome = deps.FormatSaveOutcome or FormatSaveOutcome
    FormatSaveRollLabel = deps.FormatSaveRollLabel or FormatSaveRollLabel
    GetWeaponSlotDamageBonus = deps.GetWeaponSlotDamageBonus or GetWeaponSlotDamageBonus
    OpcionesGolpeMagico = deps.OpcionesGolpeMagico or OpcionesGolpeMagico
    FormatCheckRollLabel = deps.FormatCheckRollLabel or FormatCheckRollLabel
    RequestPlayerTargetSave = deps.RequestPlayerTargetSave or RequestPlayerTargetSave
    WeaponRollName = deps.WeaponRollName or WeaponRollName
    fmtSigned = deps.fmtSigned or fmtSigned
    toN = deps.toN or toN
    K = deps.K or K
    SheetContext = deps.SheetContext or SheetContext
end

local function RollWeaponDamage(def, abilKey, maximizeDice, suppressAbilityDamage)
    if SheetContext and SheetContext.active then return 0 end
    if not def or not def.dmgN or not def.dmgS or def.dmgN == 0 or def.dmgS == 0 then
        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = "Daño " .. WeaponRollName(def),
            total = 0,
            dice = "-",
            modifiers = "",
            critical = "",
            mode = ""
        })
        return 0
    end

    local optsMagico = OpcionesGolpeMagico(def)
    local diceStr = HarfordDnDWeapons.WeaponBaseDice(def)
    local n, sides = HarfordDnDWeapons.ParseDice(diceStr)
    if not n or not sides then
        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = "Daño " .. WeaponRollName(def),
            total = 0,
            dice = "-",
            modifiers = "",
            critical = "",
            mode = ""
        })
        return 0
    end

    -- Artes Marciales: solo mejora el dado normal cuando el dado marcial es mayor.
    -- La elegibilidad (arma de monje, sin armadura ni escudo) vive en FeatureEffects.
    if ActorIsPlayer(def) and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetMartialArtsDamageDice then
        local martialN, martialSides = HarfordDnDFeatureEffects.GetMartialArtsDamageDice(def)
        if martialN and martialSides then
            n, sides = martialN, martialSides
            diceStr = tostring(n) .. "d" .. tostring(sides)
        end
    end

    -- Dado desarmado por rasgo (Brazos Mecanicos: 1d6): SOLO al arma Desarmado y nunca por
    -- debajo del dado que ya tenga (Artes Marciales puede haberlo subido mas arriba).
    if ActorIsPlayer(def) and def.key == "Desarmado"
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetUnarmedDie then
        local die = HarfordDnDFeatureEffects.GetUnarmedDie()
        if die and die > (tonumber(sides) or 0) then
            n, sides = 1, die
            diceStr = "1d" .. tostring(die)
        end
    end

    -- GOLPE CRITICO MASIVO (punto de heroe, Luchador Fisico): los dados de daño del arma se
    -- tiran x10 y se suma el nivel de personaje UNA vez. La marca la puso SpendUse (el
    -- auto-impacto ya lo consumio DoWeaponAttack) y se consume en esta tirada.
    local heroMassive = HarfordDnDStore.pendingHeroMassiveDamage and true or false
    if heroMassive then
        HarfordDnDStore.pendingHeroMassiveDamage = nil
        n = n * 10
        diceStr = tostring(n) .. "d" .. tostring(sides)
    end

    local offhand = HarfordDnDStore.GetOffhandActive and HarfordDnDStore.GetOffhandActive(def)
    local abiMod = (not suppressAbilityDamage and def.addAbi and abilKey)
        and HarfordDnDCalc.GetAbilityMod(abilKey) or 0
    -- Por defecto el ataque offhand NO suma Mod. al daño; lo permiten "Combate con Dos Armas"
    -- (flag offhandDamageMod) o, para un embate con escudo, "Maestro Escudero" (flag shieldBash).
    if offhand and abiMod > 0
        and not (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag and HarfordDnDFeatureEffects.HasFlag("offhandDamageMod"))
        and not (def.key == "Escudo" and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag and HarfordDnDFeatureEffects.HasFlag("shieldBash")) then
        abiMod = 0
    end
    -- Las formas ignoran los bonos globales de las armas equipadas, pero NO
    -- su propio bono declarado en la ficha (ej. "1d8 + 4 de dano").
    local wmod = GetWeaponSlotDamageBonus(def)
    if not (def and def.ignoreGlobalWeaponBonuses) then
        wmod = wmod + (HarfordDnDCalc.GetWeaponDamageBonus
            and HarfordDnDCalc.GetWeaponDamageBonus(def) or HarfordDnDCalc.GetWeaponMod())
    end
    if heroMassive then
        wmod = wmod + ((HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
            and tonumber(HarfordDnDProgression.GetTotalLevel())) or 1)
    end

    -- Gran Lucha con Armas (flag greatWeaponFighting): repetir una vez los dados de daño que
    -- saquen 1 o 2, solo con arma a dos manos o versatil usada a dos manos; no en maximizado.
    local gwf = false
    if (not maximizeDice) and ActorIsPlayer(def) and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("greatWeaponFighting") then
        local isMelee = def.mode == "Melee"
        local twoHanded = HarfordDnDStore.HasWeaponProp and HarfordDnDStore.HasWeaponProp(def, "Dos manos")
        local versatileTwoH = HarfordDnDWeapons.GetVersatileDice(def)
            and HarfordDnDCalc.GetVersatileActive and HarfordDnDCalc.GetVersatileActive()
        gwf = isMelee and (twoHanded or versatileTwoH) and true or false
    end

    local rolls, sum = {}, 0
    -- Valores finales de los dados BASE, para que Golpe heroico pueda repetirlos despues.
    local baseFinals = {}
    for i=1,n do
        local r = maximizeDice and sides or HarfordDnDCalc.RollDie(sides)
        local final = r
        if gwf and r <= 2 then
            final = HarfordDnDCalc.RollDie(sides)
            -- Gran Arma: la repeticion va ENTRE PARENTESIS para no confundirse con los "+" de la
            -- suma y el modificador (antes "6+1->4+5" se leia como "4+5"; ahora "6+(1→4)+5").
            rolls[#rolls+1] = "(" .. tostring(r) .. "→" .. tostring(final) .. ")"
        else
            rolls[#rolls+1] = r
        end
        sum = sum + final
        baseFinals[#baseFinals + 1] = final
    end

    -- Dote Perforador (flag piercingReroll): una vez por ataque, con daño PERFORANTE, se
    -- repite el dado base mas bajo y se usa el nuevo resultado (el manual dice por turno; el
    -- cliente no observa el fin de turno, igual que Racha de calor). No en maximizado.
    if (not maximizeDice) and ActorIsPlayer(def) and #baseFinals > 0
        and tostring(def.dmgType or ""):lower():find("perforante", 1, true)
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("piercingReroll") then
        local bajoIdx, bajoVal = 1, baseFinals[1]
        for i = 2, #baseFinals do
            if baseFinals[i] < bajoVal then bajoIdx, bajoVal = i, baseFinals[i] end
        end
        local nuevo = HarfordDnDCalc.RollDie(sides)
        rolls[bajoIdx] = "(" .. tostring(bajoVal) .. "→" .. tostring(nuevo) .. ")"
        sum = sum - bajoVal + nuevo
        baseFinals[bajoIdx] = nuevo
    end

    -- Golpe heroico: se armo al lanzar la maniobra y se resuelve AQUI, antes de sumar el total,
    -- para que el daño que se aplica al objetivo sea ya el definitivo. Se repiten los dados mas
    -- bajos y "debes usar el nuevo resultado", aunque sea peor.
    local reroll = tonumber(HarfordDnDStore.pendingWeaponRerollDice) or 0
    HarfordDnDStore.pendingWeaponRerollDice = nil
    if reroll > 0 and not maximizeDice and #baseFinals > 0 then
        local orden = {}
        for i = 1, #baseFinals do orden[i] = i end
        table.sort(orden, function(a, b) return baseFinals[a] < baseFinals[b] end)
        for i = 1, math.min(reroll, #orden) do
            local idx = orden[i]
            local antes = baseFinals[idx]
            local ahora = HarfordDnDCalc.RollDie(sides)
            baseFinals[idx] = ahora
            sum = sum + (ahora - antes)
            -- Misma notacion entre parentesis que Gran Arma, para no confundir con los "+".
            rolls[idx] = "(" .. tostring(antes) .. "→" .. tostring(ahora) .. ")"
        end
    end

    -- Ataques Salvajes (flag savageCritDie, ej. Orco/Mediorco): en CRITICO tiras un dado
    -- de daño de arma adicional (se tira, no se maximiza, como dice el rasgo).
    if maximizeDice and ActorIsPlayer(def) and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("savageCritDie") then
        local r = HarfordDnDCalc.RollDie(sides)
        rolls[#rolls+1] = r
        sum = sum + r
    end

    local baseTotal = sum + abiMod + wmod
    local rollList = table.concat(rolls, "+")
    local parts = {}
    if abiMod ~= 0 then parts[#parts+1] = fmtSigned(abiMod) end
    if wmod ~= 0 then parts[#parts+1] = fmtSigned(wmod) end
    local bonusTxt = table.concat(parts, "")
    local dtype = def.dmgType or ""

    -- Defensas del objetivo (solo si es NPC): la tirada muestra el dano ya
    -- mitigado y un marcador coloreado R/V/I junto al tipo.
    local total = baseTotal
    local marker = ""
    if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
        local applied, _status, mk = HarfordDamageMitigation.ForTarget("target", dtype, baseTotal, optsMagico)
        total, marker = applied, mk
    end
    -- Acumulador de daño YA MITIGADO por TIPO: la cabecera muestra "N Tipo [R/V/I]" por cada
    -- tipo (p.ej. base cortante + Golpe Runico frio => "6 Cortante  10 Frio"), no un total unico.
    local dmgTypeOrder, dmgTypeMap = {}, {}
    local function AddTypeDamage(t, amount, mk)
        t = (t and t ~= "") and t or dtype
        if t == "" then t = "?" end
        local e = dmgTypeMap[t]
        if not e then e = { total = 0, marker = "" }; dmgTypeMap[t] = e; dmgTypeOrder[#dmgTypeOrder + 1] = t end
        e.total = e.total + (tonumber(amount) or 0)
        if mk and mk ~= "" then e.marker = mk end
    end
    AddTypeDamage(dtype, total, marker)
    local diceParts = { n .. "d" .. sides .. ": " .. rollList .. bonusTxt }

    local extraDamage = {}
    for _, extra in ipairs(def.extraDamage or {}) do extraDamage[#extraDamage + 1] = extra end
    if ActorIsPlayer(def) and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetWeaponExtraDamage then
        for _, extra in ipairs(HarfordDnDFeatureEffects.GetWeaponExtraDamage() or {}) do
            extraDamage[#extraDamage + 1] = {
                dice = tostring(extra.count or 1) .. "d" .. tostring(extra.die or 0),
                damageType = extra.damageType,
                label = extra.label,
            }
        end
    end

    for _, extra in ipairs(extraDamage) do
        local extraN, extraSides = HarfordDnDWeapons.ParseDice(extra.dice)
        if extraN and extraSides then
            local extraRolls, extraTotal = {}, 0
            for i = 1, extraN do
                local r = maximizeDice and extraSides or HarfordDnDCalc.RollDie(extraSides)
                extraRolls[#extraRolls + 1] = r
                extraTotal = extraTotal + r
            end
            local extraType = extra.damageType or ""
            local extraMarker = ""
            if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
                local applied, _status, mk = HarfordDamageMitigation.ForTarget("target", extraType, extraTotal, optsMagico)
                extraTotal, extraMarker = applied, mk
            end
            total = total + extraTotal
            AddTypeDamage(extraType, extraTotal, extraMarker)
            local extraLabel = extra.dice .. ": " .. table.concat(extraRolls, "+")
            if extraType ~= "" and extraType ~= dtype then
                extraLabel = extraLabel .. " " .. extraType
            end
            if extraMarker ~= "" then extraLabel = extraLabel .. " " .. extraMarker end
            diceParts[#diceParts + 1] = extraLabel
        end
    end

    -- Daños condicionales conmutables ACTIVOS (Ataque Furtivo, Golpe del Cruzado, ...): cada
    -- uno suma sus dados (tipo del arma salvo que indique otro). Se CONSUMEN tras la tirada.
    -- Vida efectiva del objetivo para "parar al morir": el daño adicional no se aplica ni se gasta
    -- una vez muerto, y los condicionales de COSTE-POR-DADO (Golpe Runico) solo gastan los dados
    -- que hicieron falta. nil = vida desconocida -> comportamiento de siempre (sin cap).
    local targetHP = HarfordDnDCombat and HarfordDnDCombat.GetTargetEffectiveHP and HarfordDnDCombat.GetTargetEffectiveHP()
    local lethalReached = false

    local active = ActorIsPlayer(def) and (HarfordDnDStore.activeCondDamage or {}) or {}
    local condList = (ActorIsPlayer(def) and HarfordDnDStore.GetConditionalDamageList
        and HarfordDnDStore.GetConditionalDamageList()) or {}
    local consumedAny = false
    for _, cd in ipairs(condList) do
        local originalCd = cd
        local cdLevel = HarfordDnDConditionalDamage.GetSelectedLevel(originalCd)
        cd = HarfordDnDConditionalDamage.GetLeveled(originalCd)
        local cdDice = tonumber(cd.dice) or 0
        local cdFlat = tonumber(cd.flat) or 0
        -- +Mod de caracteristica resuelto AQUI (Golpe Heroico = +Fuerza); no en FeatureEffects
        -- porque GetAbilityMod dentro de Resolve provoca recursion infinita.
        if cd.flatAbility and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
            cdFlat = cdFlat + (tonumber(HarfordDnDCalc.GetAbilityMod(cd.flatAbility)) or 0)
        end
        local isMarkedTarget = cd.requiresMarkedTarget == true
            and HarfordDnDStore.IsHuntersMarkTarget and HarfordDnDStore.IsHuntersMarkTarget("target")
        if (active[cd.id] or isMarkedTarget) and (cdDice > 0 or cdFlat ~= 0 or cd.resourceCost or cd.spellLevelCost) then
            if targetHP and (lethalReached or total >= targetHP) then
                -- El objetivo ya muere con el daño previo: no rolar, no gastar, no aplicar.
                lethalReached = true
                if not isMarkedTarget then
                    HarfordDnDStore.activeCondDamage[cd.id] = nil
                    HarfordDnDStore.condDamageLevel[cd.id] = nil
                    consumedAny = true
                end
            else
            local cdType = (cd.damageType and cd.damageType ~= "" and cd.damageType) or dtype
            -- Coste por dado (Golpe Runico: 1 Poder Runico/dado) + vida conocida = tira dado a dado
            -- y para al morir, gastando solo los usados. Los demas (espacio de conjuro, sin coste)
            -- tiran todos sus dados como siempre.
            local perDie = (cd.resourceCost and cdDice > 0 and targetHP) and true or false
            local cdRolls, rawSum, diceUsed = {}, 0, cdDice
            if perDie then
                diceUsed = 0
                for i = 1, cdDice do
                    local r = maximizeDice and cd.die or HarfordDnDCalc.RollDie(cd.die)
                    cdRolls[i] = r; rawSum = rawSum + r; diceUsed = i
                    local mit = rawSum + cdFlat
                    if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
                        mit = (HarfordDamageMitigation.ForTarget("target", cdType, rawSum + cdFlat, optsMagico))
                    end
                    if total + mit >= targetHP then break end  -- este dado ya mata: para
                end
            else
                for i = 1, cdDice do
                    local r = maximizeDice and cd.die or HarfordDnDCalc.RollDie(cd.die)
                    cdRolls[i] = r; rawSum = rawSum + r
                end
            end

            -- Coste: per-die paga solo los dados usados; el resto, el nivel completo.
            local spendLevel = perDie and diceUsed or cdLevel
            local paid, costText
            if isMarkedTarget then
                paid, costText = true, ""
            else
                paid, costText = HarfordDnDConditionalDamage.Spend(originalCd, spendLevel)
            end
            if not paid then
                if DEFAULT_CHAT_FRAME then
                    HarfordChat.Print("|cffff5555" .. tostring(cd.label or "Daño extra") .. " requiere " .. tostring(costText or "recursos suficientes") .. ".|r")
                end
                HarfordDnDStore.activeCondDamage[cd.id] = nil
                HarfordDnDStore.condDamageLevel[cd.id] = nil
                if not isMarkedTarget then consumedAny = true end
            elseif #cdRolls > 0 or cdFlat ~= 0 then
            if cd.conditionId or cd.onHitAura then
                ApplyConditionalHitEffect(cd.conditionId, cd.onHitAura)
            end
            ApplyConditionalDamageRiders(cd.id)
            local cdTotal = rawSum + cdFlat
            local cdMarker = ""
            if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
                local applied, _s, mk = HarfordDamageMitigation.ForTarget("target", cdType, cdTotal, optsMagico)
                cdTotal, cdMarker = applied, mk
            end
            total = total + cdTotal
            AddTypeDamage(cdType, cdTotal, cdMarker)
            if targetHP and total >= targetHP then lethalReached = true end
            local cdExpr = ""
            if #cdRolls > 0 then
                cdExpr = #cdRolls .. "d" .. cd.die .. ": " .. table.concat(cdRolls, "+")
            end
            if cdFlat ~= 0 then
                cdExpr = cdExpr ~= "" and (cdExpr .. fmtSigned(cdFlat)) or fmtSigned(cdFlat)
            end
            local cdLabel = cd.label .. " " .. cdExpr
            -- El tipo solo se nombra si es DISTINTO del arma: la cabecera ya agrega por tipo, y
            -- repetirlo daba "9 Perforante (1d6: 1+3+1 + Ataque Furtivo 2d6: 2+2 perforante)".
            -- Cuando difiere (un 1d6 de fuego sobre una espada) si hace falta decirlo.
            if cdType ~= "" and cdType ~= dtype then
                cdLabel = cdLabel .. " " .. cdType
            end
            -- El marcador de mitigacion es de ESE componente y va siempre.
            if cdMarker ~= "" then cdLabel = cdLabel .. " " .. cdMarker end
            diceParts[#diceParts + 1] = cdLabel
            if isMarkedTarget and HarfordDnDStore.huntersMark then
                HarfordDnDStore.huntersMark.usedThisTurn = true
            end
            if not isMarkedTarget then consumedAny = true end
            else
                -- Maniobra SIN daño extra (ej. Desarme): solo gasta el coste; deja una nota.
                if cd.conditionId or cd.onHitAura then
                    ApplyConditionalHitEffect(cd.conditionId, cd.onHitAura)
                end
                ApplyConditionalDamageRiders(cd.id)
                local manLabel = cd.label
                if costText and costText ~= "" then manLabel = manLabel .. " (" .. costText .. ")" end
                diceParts[#diceParts + 1] = manLabel
                if not isMarkedTarget then consumedAny = true end
            end
            end
        end
    end
    if consumedAny then
        HarfordDnDStore.activeCondDamage = {}
        HarfordDnDStore.condDamageLevel = {}
        HarfordDnDAttackUI.RefreshWeaponInfo()
    end

    -- Gran maestro de armas: REMATAR (el daño total alcanza la vida conocida del objetivo) con
    -- un arma c/c en tu turno abre un ataque mas como accion adicional — mismo camino que el
    -- critico del ataque. Solo con vida conocida (NPC con Turnos): a un jugador no se le "ve"
    -- caer desde aqui.
    if (lethalReached or (targetHP and total >= targetHP)) and def and def.mode == "Melee"
        and ActorIsPlayer(def)
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("gwmBonusAttack")
        and HarfordDnDConditions and HarfordDnDConditions.Turn
        and HarfordDnDConditions.Turn.GrantBonusWeaponAttack
        and HarfordDnDConditions.Turn.IsActive() and HarfordDnDConditions.Turn.IsMyTurn() then
        HarfordDnDConditions.Turn.GrantBonusWeaponAttack()
        HarfordChat.Print("|cff88ff88Gran maestro de armas:|r remate c/c — tu proximo ataque de este turno se cobra como accion adicional.")
    end

    -- Cabecera por tipo: el render hace "<total> <modifiers>", asi que el primer tipo aporta el
    -- numero de cabecera y el resto van "N Tipo" dentro de modifiers => "6 Cortante 10 Frio". El
    -- numero de cada tipo extra se colorea con COLOR_ROLL (|cff66ccff) para igualar al de cabecera.
    local headlineTotal, modifiersTxt = HarfordDnDRolls.FormatDamageHeader(dmgTypeOrder, dmgTypeMap, total)

    -- El DESTINO va en la etiqueta igual que en la linea de Ataque: el daño de arma se resuelve
    -- siempre contra "target" (la mitigacion de arriba usa esa unidad), asi que su nombre RP
    -- coloreado sale del mismo helper que exporta la ficha.
    local nombreDestino = HarfordDnDStore.ColoredUnitName and HarfordDnDStore.ColoredUnitName("target") or ""
    local etiquetaDano = ((def.actorLabel and (def.actorLabel .. ": ")) or "")
        .. (offhand and "Daño Offhand " or "Daño ") .. WeaponRollName(def)
        .. (nombreDestino ~= "" and (" " .. nombreDestino) or "")

    -- Contra un jugador que corre Harford, la linea la publica EL: solo el conoce sus resistencias,
    -- asi que solo el puede decir el numero definitivo. Sale con ESTA etiqueta y con el nombre del
    -- atacante, o sea igual que si la hubiera publicado este cliente -- lo unico que cambia es que
    -- el numero ya es el de verdad, en vez de un bruto seguido de una linea de correccion.
    --
    -- Si no sabemos que corre Harford, publica este cliente: preferible un numero sin mitigar a que
    -- en la mesa no salga nada. No hay acuse, asi que callarse a ciegas es perder la linea.
    local publicaLaVictima = HarfordDnDCombat and HarfordDnDCombat.VictimaPublicaSuDano
        and HarfordDnDCombat.VictimaPublicaSuDano("target")
    if not publicaLaVictima then
        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = etiquetaDano,
            total = headlineTotal,
            dice = table.concat(diceParts, " + "),
            modifiers = modifiersTxt,
            critical = maximizeDice and "CRÍTICO" or "",
            mode = ""
        })
    end
    -- MUTILAR (punto de heroe): con el daño total ya conocido se publica, DETRAS de la linea de
    -- daño, la salvacion que la victima debe superar -- Constitucion CD 10 o mitad del daño, la
    -- que sea MAYOR -- o pierde el miembro elegido. La CD sale calculada; la amputacion en si se
    -- resuelve en mesa.
    if HarfordDnDStore.pendingHeroMutilate then
        HarfordDnDStore.pendingHeroMutilate = nil
        local cdMutilar = math.max(10, math.floor(total / 2))
        HarfordDnDRolls.Broadcast({
            type = "info",
            label = "MUTILA: Salv CON CD " .. cdMutilar .. " o pierde el miembro elegido",
        })
    end

    -- Segundo valor: los componentes POR TIPO. Contra un jugador viajan tal cual y los mitiga su
    -- cliente; contra un NPC ya vienen mitigados de aqui y el total basta.
    local componentes = {}
    for _, t in ipairs(dmgTypeOrder) do
        componentes[#componentes + 1] = { amount = dmgTypeMap[t].total, damageType = t }
    end
    -- La etiqueta se devuelve SOLO si este cliente ha callado. Las dos decisiones --callarme yo y
    -- publicar tu-- tienen que ser LA MISMA o salen dos lineas: mandar la etiqueta siempre hacia
    -- que la victima publicara aunque el atacante hubiera publicado ya, que es justo lo que este
    -- cambio venia a quitar. Atadas aqui no pueden divergir.
    return total, componentes, (publicaLaVictima and etiquetaDano or nil)
end

-- El nombre de un estado que se APLICA (Derribado, Agarrado, Desarmado...) sale con el color de
-- "estado" de la web (.hl-cond de harfordweb/css/styles.css) en todas las superficies. Con el
-- `conditionId` se usa el label del catalogo LIMPIO, asi que aplicarlo dos veces (emisor y
-- receptor) no dobla el color; sin definicion, el texto queda tal cual.
local COLOR_ESTADO = "|cffff6b6b"
local function EtiquetaDeEstado(conditionId, fallback)
    local def = HarfordDnDConditions and HarfordDnDConditions.GetDefinition
        and HarfordDnDConditions.GetDefinition(conditionId)
    if def and def.label then return COLOR_ESTADO .. tostring(def.label) .. "|r" end
    return fallback
end

local function ResolveWeaponManeuverAfterHitSave(data)
    if not data or not data.save then return end
    if not (UnitExists and UnitExists("target")) then return end
    if UnitIsPlayer and UnitIsPlayer("target") then
        RequestPlayerTargetSave(data.save, data.dc, EtiquetaDeEstado(data.conditionId, data.outcome), data.onFailAura,
            data.conditionId, data.conditionDuration, data.conditionTurns, data.nextAttackExtraDamageDice,
            data.extraDamageType, data.skill, data.actionName)
        if data.nextAttackExtraDamageDice then
            HarfordDnDStore.pendingFormSaveFollowup = {
                target = HarfordClassColors.UnitFullName("target"), dice = data.nextAttackExtraDamageDice,
                damageType = data.extraDamageType,
            }
        end
        return
    end
    -- Una maniobra puede pedir una PRUEBA DE HABILIDAD en vez de una salvacion (Corte de Ala:
    -- Fuerza (Atletismo)). Cambia el bonus -- la competencia en esa habilidad -- y la etiqueta;
    -- el resto de la resolucion es identica.
    local esPrueba = data.skill and data.skill ~= ""
    local saveBonus
    if esPrueba then
        saveBonus = (HarfordDnDCombat and HarfordDnDCombat.GetSkillBonusForUnit
            and HarfordDnDCombat.GetSkillBonusForUnit("target", data.skill)) or 0
    else
        saveBonus = (HarfordDnDCombat and HarfordDnDCombat.GetSaveBonusForUnit
            and HarfordDnDCombat.GetSaveBonusForUnit("target", data.save)) or 0
    end
    -- Fallar automaticamente una salvacion es un efecto de estado; una prueba de habilidad no lo
    -- tiene, asi que solo aplica cuando de verdad es salvacion.
    local autoFail = (not esPrueba) and HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
        and HarfordDnDConditions.IsSaveAutoFailed("target", data.save)
    local saveMode = HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode
        and HarfordDnDConditions.ResolveRollMode("normal", esPrueba and "skill" or "save",
            { actorUnit = "target", ability = data.save, skill = data.skill }) or "normal"
    local d = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(saveMode))
    local saveTotal = d + saveBonus
    local dc = tonumber(data.dc) or 10
    local saved = not autoFail and saveTotal >= dc
    local targetName = (HarfordDnDStore.ColoredUnitName and HarfordDnDStore.ColoredUnitName("target")) or ""
    if targetName == "" then
        targetName = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("target"))
            or HarfordClassColors.UnitFullName("target") or "el objetivo"
    end
    local outcome = FormatSaveOutcome(saved, EtiquetaDeEstado(data.conditionId, data.outcome))
    local conditionApplied = false
    if not saved and (data.conditionId or data.onFailAura) then
        local applied, applyErr = ApplyConditionalHitEffect(data.conditionId, data.onFailAura, {
            duration = data.conditionDuration,
            turns = data.conditionTurns,
            silentFailure = true,
        })
        conditionApplied = applied == true
        if not applied then
            local suffix = applyErr == "immune" and "inmune" or "no aplicado"
            outcome = FormatSaveOutcome(false, tostring(data.outcome or "afectado") .. " (" .. suffix .. ")")
        end
    end
    if not saved and data.nextAttackExtraDamageDice then
        HarfordDnDStore.pendingFormNextAttackDamage = {
            dice = data.nextAttackExtraDamageDice, name = "Embestida", damageType = data.extraDamageType,
        }
    end
    local label = string.format("%s %s", targetName, esPrueba
        and FormatCheckRollLabel(data.skill, saveTotal, d, dc, outcome, saveBonus)
        or FormatSaveRollLabel(data.save, saveTotal, d, dc, outcome, saveBonus))
    if not data.silent then
        HarfordDnDRolls.Broadcast({
            type = "info", targetUnit = "target", label = label,
            total = "", dice = "", modifiers = "", critical = "", mode = ""
        })
    end
    return {
        targetName = targetName, label = label, saved = saved,
        total = saveTotal, die = d, bonus = saveBonus, skill = data.skill,
        conditionApplied = conditionApplied,
    }
end

local function RollRequestedSaveForSelf(ability, dc, outcome, auraId, responseTarget,
    conditionId, conditionDuration, conditionTurns, sourceGuid, sourceName, extraDamageDice, extraDamageType, skill, actionName)
    ability = tostring(ability or "")
    if ability == "" then return end
    -- `skill`: lo que se pide es una PRUEBA de esa habilidad, no una salvacion. La tira el
    -- defensor con SU competencia, que es justo lo que las diferencia.
    --
    -- Puede venir mas de una separadas por "/". Es una tirada ENFRENTADA, y en 5e el que se
    -- defiende elige con cual: un agarre se resiste con Atletismo o con Acrobacias, y quien decide
    -- cual le conviene es el defensor, no el atacante. Por eso se resuelve aqui, en su cliente,
    -- donde estan sus competencias de verdad.
    local skillDef, base, prof
    if skill and skill ~= "" then
        for nombre in tostring(skill):gmatch("[^/]+") do
            local buscado = HarfordClassColors.NormalizeKey(nombre)
            for _, s in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
                if HarfordClassColors.NormalizeKey(s.name) == buscado
                    or HarfordClassColors.NormalizeKey(s.id) == buscado then
                    local b, pr = HarfordDnDCalc.GetSkillRollBonuses(s)
                    if not skillDef or ((b or 0) + (pr or 0)) > ((base or 0) + (prof or 0)) then
                        skillDef, base, prof = s, b, pr
                    end
                    break
                end
            end
        end
    end
    if not skillDef then
        base, prof = HarfordDnDCalc.GetSaveRollBonuses(ability)
    end
    local bonus = (tonumber(base) or 0) + (tonumber(prof) or 0)
    local autoFail = (not skillDef) and HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
        and HarfordDnDConditions.IsSaveAutoFailed("player", ability)
    local mode = HarfordDnDCalc.GetMode()
    if HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode then
        mode = HarfordDnDConditions.ResolveRollMode(mode, "save", { actorUnit = "player", ability = ability })
    end
    local d = 0
    if not autoFail then d = select(1, HarfordDnDCalc.RollD20(mode)) end
    local total = d + bonus
    dc = tonumber(dc) or 10
    local saved = not autoFail and total >= dc
    -- El emisor ya manda el estado coloreado, pero un cliente viejo lo manda plano: con el
    -- conditionId (que viaja aparte) el helper lo re-etiqueta desde el catalogo sin doblar color.
    local result = FormatSaveOutcome(saved, EtiquetaDeEstado(conditionId, outcome))
    if not saved then
        local def = HarfordDnDConditions and HarfordDnDConditions.GetDefinition
            and HarfordDnDConditions.GetDefinition(conditionId)
        if def then
            local applied = HarfordDnDConditions.ApplyOwned(conditionId, {
                sourceGuid = sourceGuid,
                sourceName = sourceName and sourceName ~= "" and sourceName or responseTarget,
                duration = conditionDuration or "manual",
                turns = conditionTurns,
            })
            if applied and HarfordDnDConditions.PublishOwnedCondition then
                HarfordDnDConditions.PublishOwnedCondition(conditionId, "apply")
            end
        elseif auraId and tonumber(auraId) and tonumber(auraId) > 0 then
            ApplyRequestedSaveAuraSelf(auraId)
        end
    end
    if extraDamageDice and extraDamageDice ~= "" and responseTarget and HarfordSync and HarfordSync.SendRequestedSaveResult then
        HarfordSync.SendRequestedSaveResult(K.ADDON_PREFIX, responseTarget, saved, sourceGuid)
    end
    -- El nombre de la accion delante ("[Empujar] Atletismo ..."): sin el, la linea del defensor
    -- es una prueba huerfana y en mesa no se sabe a QUE esta respondiendo. Por la red viaja solo
    -- el NOMBRE (un hyperlink no cabe en el campo), asi que el enlace clicable se reconstruye
    -- AQUI desde el catalogo local de acciones basicas; sin coincidencia, texto plano.
    local accion = tostring(actionName or "")
    local prefijoAccion = ""
    if accion ~= "" then
        local enlace
        if HarfordTRP3 and HarfordTRP3.GetAbilityChatLink and HarfordClassColors.NormalizeKey then
            local buscado = HarfordClassColors.NormalizeKey(accion)
            for _, defAccion in pairs((HarfordDnDActions and HarfordDnDActions.DEFS) or {}) do
                if HarfordClassColors.NormalizeKey(defAccion.name or "") == buscado then
                    enlace = HarfordTRP3.GetAbilityChatLink(defAccion)
                    break
                end
            end
        end
        prefijoAccion = (enlace or ("[" .. accion .. "]")) .. " "
    end
    local rollData = {
        type = "info",
        label = prefijoAccion .. (skillDef
            and FormatCheckRollLabel(skillDef.name, total, d, dc, result, base, prof)
            or FormatSaveRollLabel(ability, total, d, dc, result, base, prof)),
        -- La salvacion la haces TU, no la ficha que tengas cargada.
        player = HarfordDnDRolls.GetOwnName and HarfordDnDRolls.GetOwnName() or nil,
    }
    HarfordDnDRolls.Broadcast(rollData)
    if responseTarget and responseTarget ~= "" and HarfordSync and HarfordSync.Send
        and HarfordDnDRolls and HarfordDnDRolls.Serialize then
        local channel = HarfordSync.BestChannel and HarfordSync.BestChannel() or nil
        if not channel then
            HarfordSync.Send(K.ADDON_PREFIX, HarfordDnDRolls.Serialize(rollData), "WHISPER", responseTarget)
        end
    end
end

local function DoRollEx(label, baseBonus, profBonus, rollType, rollContext)
    baseBonus = toN(baseBonus, 0)
    profBonus = toN(profBonus, 0)
    local miscBonus = HarfordDnDCalc.GetMiscBonus()
    local result = {
        ok = true,
        kind = rollType or "roll",
        label = tostring(label or ""),
        base = baseBonus,
        prof = profBonus,
        misc = miscBonus,
        extra = miscBonus,
        actorUnit = rollContext and rollContext.actorUnit or nil,
        ability = rollContext and rollContext.ability or nil,
        skill = rollContext and rollContext.skill or nil,
        timestamp = time and time() or 0,
    }

    if rollType == "save" and HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
        and HarfordDnDConditions.IsSaveAutoFailed((rollContext and rollContext.actorUnit) or "player",
            rollContext and rollContext.ability) then
        HarfordDnDRolls.Broadcast({ type = "roll", label = label, total = 0, dice = "Fallo automatico", modifiers = "", critical = "FALLO" })
        ConsumeMode()
        result.total = 0
        result.die = 0
        result.dice = "Fallo automatico"
        result.modifiers = ""
        result.crit = "FALLO"
        result.critical = "FALLO"
        result.autoFailed = true
        _G.DND5E_ARC_API = _G.DND5E_ARC_API or {}
        _G.DND5E_ARC_API._lastRoll = result
        return result
    end

    local chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full(rollType, rollContext)
    local total = chosen + baseBonus + profBonus + miscBonus
    local bonusTxt = HarfordDnDCalc.BonusConcat(baseBonus, profBonus, miscBonus)
    local diceText = HarfordDnDCalc.FormatD20Dice(chosen, ra, rb)

    if not (rollContext and rollContext.silent) then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = label,
            total = total,
            dice = diceText,
            modifiers = bonusTxt,
            critical = critTag,
            mode = modeTag,
            miscBonus = miscBonus,
            -- `targetUnit` activa el whisper extra de Broadcast: una tirada dirigida a un jugador
            -- que NO esta en tu grupo le llega igual (la contienda de Empujar lo necesita — sin
            -- esto, la victima no veia la tirada del atacante si no compartian raid).
            targetUnit = rollContext and rollContext.targetUnit or nil,
        })
    end
    ConsumeMode()
    result.total = total
    result.die = chosen
    result.rollA = ra
    result.rollB = rb
    result.dice = diceText
    result.modifiers = bonusTxt
    result.crit = critTag
    result.critical = critTag
    result.mode = modeTag
    _G.DND5E_ARC_API = _G.DND5E_ARC_API or {}
    _G.DND5E_ARC_API._lastRoll = result
    return result
end

-- TIRADA ENFRENTADA (Agarrar, Empujar).
--
-- No es una salvacion contra CD fija: la CD la pone el atacante con su propia tirada. Por eso se
-- resuelve en dos pasos y no en uno -- primero se tira, y el total resultante ES la dificultad.
--
-- La resolucion del defensor NO se duplica: se reusa la misma ruta que las maniobras con salvacion
-- posterior al impacto, que ya sabe distinguir jugador de NPC, pedirle la tirada al cliente
-- defensor y aplicar el estado al que pierde. Lo unico propio de una tirada enfrentada es de donde
-- sale la dificultad.
--
-- En 5e el defensor gana los empates, y eso ya sale bien de `total >= dc`: si iguala, se defiende.
local function RollContest(contest, opts)
    if type(contest) ~= "table" then return false, "sin datos" end
    if not (UnitExists and UnitExists("target")) then return false, "sin objetivo" end
    local api = _G.DND5E_ARC_API
    if not (api and api.RollSkillEx) then return false, "sin tiradas" end

    -- El destino con el helper canonico (RP COLOREADO por clase, como en Ataque Arma y en el
    -- resto de lineas dirigidas) — no el nombre WoW pelado, que salia "DM" sin color.
    local targetName = (HarfordDnDStore and HarfordDnDStore.ColoredUnitName
        and HarfordDnDStore.ColoredUnitName("target")) or ""
    if targetName == "" then
        targetName = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("target"))
            or HarfordClassColors.UnitFullName("target") or "el objetivo"
    end
    local targetIsPlayer = UnitIsPlayer and UnitIsPlayer("target")
    -- La accion va CLICABLE cuando el llamador trae su enlace TRP3; el nombre pelado queda de
    -- respaldo. `targetUnit` hace que la tirada del atacante LLEGUE a la victima aunque no
    -- compartan grupo (whisper extra de Broadcast) — sin el, la victima solo veia su salvacion.
    local prefijo = (opts and opts.actionLink)
        or ("[" .. tostring(opts and opts.actionName or "Contienda") .. "]")
    local propia = api.RollSkillEx(contest.skill,
        targetIsPlayer and (prefijo .. " " .. targetName) or nil,
        targetIsPlayer and { targetUnit = "target" } or { silent = true })
    local total = propia and tonumber(propia.total)
    if not total then return false, "no se pudo tirar" end

    -- La lista completa viaja junta: el defensor elige, no el atacante.
    local contra = contest.against
    if type(contra) == "table" then contra = table.concat(contra, "/") end

    -- La opcion elegida manda sobre el estado por defecto, y puede ser `false` para decir
    -- EXPRESAMENTE que no aplique ninguno (Empujar: apartar mueve, no derriba). Por eso se
    -- resuelve con un `if` y no con `and/or`: ese idioma devuelve el otro lado cuando el valor
    -- es false, que es justo el caso que hay que distinguir.
    local estado = contest.onWin
    if opts and opts.conditionId ~= nil then
        estado = opts.conditionId or nil
    end

    -- `outcome` es lo que le pasa al defensor AL FALLAR (FormatSaveOutcome lo pega detras de
    -- FALLO): la opcion declarada ("Apartar 1,5 m") o el nombre del estado que se le aplica
    -- ("Derribado"). El "resiste" de antes era la semantica invertida -- resistir es lo que hace
    -- al GANAR -- y la victima publicaba el contradictorio "FALLO resiste".
    local alFallar = contest.outcome
    if not alFallar and opts and opts.resultLabel and opts.resultLabel ~= "" then
        alFallar = tostring(opts.resultLabel)
    end
    if not alFallar and estado then
        local condition = HarfordDnDConditions and HarfordDnDConditions.GetDefinition
            and HarfordDnDConditions.GetDefinition(estado)
        alFallar = (condition and condition.label) or tostring(estado)
    end

    local defense = ResolveWeaponManeuverAfterHitSave({
        dc = total,
        skill = contra,
        -- Solo se usa si el defensor no reconoce ninguna de las habilidades pedidas.
        save = contest.ability or "Fuerza",
        conditionId = estado,
        conditionDuration = contest.duration or "manual",
        outcome = alFallar or "",
        actionName = opts and opts.actionName or nil,
        silent = not targetIsPlayer,
    })
    -- Contra NPC conocemos ambas tiradas en este cliente: se publica UNA linea de contienda.
    -- Contra un jugador el defensor debe tirar en su propio cliente, asi que mantiene su linea.
    if defense then
        local ownDice = tostring(propia.dice or "-") .. tostring(propia.modifiers or "")
        local defenseBonus = tonumber(defense.bonus) or 0
        local defenseDice = tostring(defense.die or 0)
            .. (defenseBonus >= 0 and "+" or "") .. tostring(defenseBonus)
        local result = "Sin efecto"
        if not defense.saved and defense.conditionApplied and estado then
            result = EtiquetaDeEstado(estado, tostring(estado))
        end
        local cabecera = prefijo
        if opts and opts.resultLabel and opts.resultLabel ~= "" then
            cabecera = cabecera .. " " .. tostring(opts.resultLabel)
        end
        HarfordDnDRolls.Broadcast({
            type = "info",
            label = string.format("%s %s (|cff66ccff%s %d (%s)|r vs |cff66ccff%s %d (%s)|r) %s",
                cabecera, targetName, tostring(contest.skill or "Prueba"), total, ownDice,
                tostring(defense.skill or contra or "Prueba"), tonumber(defense.total) or 0, defenseDice, result),
        })
    end
    return true
end

HarfordDnDWeaponRolls.EtiquetaDeEstado = EtiquetaDeEstado
HarfordDnDWeaponRolls.RollContest = RollContest
HarfordDnDWeaponRolls.RollWeaponDamage = RollWeaponDamage
HarfordDnDWeaponRolls.ResolveWeaponManeuverAfterHitSave = ResolveWeaponManeuverAfterHitSave
HarfordDnDWeaponRolls.RollRequestedSaveForSelf = RollRequestedSaveForSelf
HarfordDnDWeaponRolls.DoRollEx = DoRollEx
