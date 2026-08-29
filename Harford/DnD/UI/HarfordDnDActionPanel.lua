-- Panel de acciones externas para contextos de ficha (por ejemplo NPC desde Admin),
-- extraido de HarfordDnD.lua (fase C de refactorizacion). La extension proporciona los
-- datos ya parseados; este modulo solo renderiza y tira.
--
-- No puede construirse al cargar: sus frames se anclan a K.SEC_ATK, que crea HarfordDnD.
-- Por eso expone Build(D), que HarfordDnD llama EN EL MISMO PUNTO donde vivia el IIFE,
-- con sus dependencias ya vivas, y devuelve la funcion de refresco.

HarfordDnDActionPanel = HarfordDnDActionPanel or {}

function HarfordDnDActionPanel.Build(D)
    local K = D.K
    local Print = D.Print
    local DoRoll = D.DoRoll
    local ConsumeMode = D.ConsumeMode
    local fmtSigned = D.fmtSigned
    local toN = D.toN
    local ColoredUnitName = D.ColoredUnitName
    local MakeArmorClassEditBox = D.MakeArmorClassEditBox
    local RefreshArmorClassBoxes = D.RefreshArmorClassBoxes
    local SheetContext = D.SheetContext
    local RefreshSheetActionPanel

    local panel = CreateFrame("Frame", nil, K.SEC_ATK)
    panel:SetPoint("TOPLEFT", K.SEC_ATK, "TOPLEFT", 4, -29)
    panel:SetPoint("BOTTOMRIGHT", K.SEC_ATK, "BOTTOMRIGHT", -4, 4)
    panel:SetFrameLevel(K.SEC_ATK:GetFrameLevel() + 100)
    panel:EnableMouse(true)
    if panel.SetPropagateMouseClicks then panel:SetPropagateMouseClicks(false) end
    panel:SetScript("OnMouseDown", function() end)
    panel:Hide()

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(HarfordDnDUI.SECTION_TEX.ATK)
    bg:SetAlpha(0.98)

    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", 9, -11)
    label:SetText("Accion:")

    local drop = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(drop, 155)
    drop:SetPoint("TOPLEFT", 47, 4)

    local npcArmorClassLabel, npcArmorClassBox, SetNpcArmorClassBox = MakeArmorClassEditBox(panel, -14, -8)

    -- Dropdown de emote de animación NPC (solo visible en modo DM).
    -- Lista canónica en HarfordEmotes; aquí solo se consume.
    local EMOTE_OPTIONS = (HarfordEmotes and HarfordEmotes.GetOrderedList()) or {}
    local selectedEmoteIndex = 1

    local emoteDrop = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(emoteDrop, 104)
    emoteDrop:SetPoint("TOPLEFT", 47, -86)

    UIDropDownMenu_Initialize(emoteDrop, function(_, level)
        if level ~= 1 then return end
        for i, opt in ipairs(EMOTE_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.checked = (i == selectedEmoteIndex)
            info.func    = function()
                selectedEmoteIndex = i
                UIDropDownMenu_SetText(emoteDrop, opt.label)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(emoteDrop, (EMOTE_OPTIONS[1] and EMOTE_OPTIONS[1].label) or "Ninguno")

    -- Dropdown "Modo combate": postura persistente del NPC ficha vía npc emote
    -- (Stand 26 + 4254..4337). Empieza en "Stand"; al seleccionar ejecuta el emote.
    local COMBAT_OPTIONS = (HarfordEmotes and HarfordEmotes.GetCombatList()) or {}
    local selectedCombatIndex = 1

    local combatDrop = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(combatDrop, 104)
    combatDrop:SetPoint("TOPLEFT", 173, -86)

    UIDropDownMenu_Initialize(combatDrop, function(_, level)
        if level ~= 1 then return end
        for i, opt in ipairs(COMBAT_OPTIONS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.checked = (i == selectedCombatIndex)
            info.func    = function()
                selectedCombatIndex = i
                UIDropDownMenu_SetText(combatDrop, opt.label)
                -- Todas las posturas del dropdown de combate van en bucle (repeat).
                -- En NPC se usa npcId (Stand = 0, salir de combate); el resto = id.
                if opt.npcId and HarfordServerActions and HarfordServerActions.SetNpcEmoteRepeat then
                    HarfordServerActions.SetNpcEmoteRepeat(opt.npcId)
                end
                -- Recordar el modo de combate de ESTE NPC por GUID (runtime) para que,
                -- si luego es el defensor de un ataque, su parry/dodge use esta postura.
                -- El `npc emote repeat` actua sobre el NPC seleccionado (target); se usa
                -- ese GUID, con fallback al GUID de la fuente fijada de la ficha.
                if HarfordDnDCombat and HarfordDnDCombat.SetNpcCombatMode then
                    local g = (UnitExists and UnitExists("target")
                        and not (UnitIsPlayer and UnitIsPlayer("target"))
                        and UnitGUID and UnitGUID("target")) or SheetContext.npcSourceGuid
                    HarfordDnDCombat.SetNpcCombatMode(g, opt.key)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(combatDrop, (COMBAT_OPTIONS[1] and COMBAT_OPTIONS[1].label) or "Stand")

    local function MakeDropLabel(text, centerX)
        local holder = CreateFrame("Frame", nil, panel)
        holder:SetFrameLevel(panel:GetFrameLevel() + 40)
        holder:SetPoint("TOPLEFT", panel, "TOPLEFT", centerX - 58, -72)
        holder:SetSize(116, 14)
        local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetAllPoints()
        fs:SetJustifyH("CENTER")
        fs:SetJustifyV("MIDDLE")
        fs:SetText(text)
        return holder, fs
    end

    MakeDropLabel("Anim Ataque", 128)
    MakeDropLabel("Modo Combate", 254)

    -- Solo se muestra el resumen de tirada (bonus de ataque + daño); la
    -- descripcion completa del estado TRP3 no se renderiza en la ficha NPC.
    local parsedText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    parsedText:SetPoint("TOPLEFT", 14, -56)
    parsedText:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
    parsedText:SetJustifyH("LEFT")
    parsedText:SetWordWrap(true)

    local selectedIndex = 1
    local selectedAction
    local attackButton
    local damageButton
    local pendingCriticalAction
    local RollActionDamage  -- forward decl: RollActionAttack auto-tira daño al focus

    local function GetAction(index)
        return SheetContext.actions and SheetContext.actions[index] or nil
    end

    -- Una accion es "de ataque utilizable" si el NPC puede tirar ataque o daño.
    local function IsAttackAction(action)
        return action ~= nil
            and (action.attackBonus ~= nil or action.damageDice ~= nil)
    end

    local function GetActionChatName(action)
        if not action then return "Accion" end
        return action.hyperlink or action.title or "Accion"
    end

    -- Nombre del focus con la logica habitual de nombre/color: nombre RP TRP3 (o de
    -- WoW como fallback) coloreado por el color de nombre TRP3 (companion NH / player
    -- CH) y, si no hay, por color de clase.
    local function GetFocusColoredName()
        local n = ColoredUnitName("focus")
        return (n ~= "" and n) or nil
    end

    local function RollActionAttack(action, reactionChecked, savedRoll)
        -- Cada nuevo ataque descarta el pendiente NPC vs NPC anterior (no consumido).
        HarfordDnDStore.pendingNpcAttack = nil
        local actorRef = SheetContext.npcSourceGuid or "target"
        local focusExists = UnitExists and UnitExists("focus")
        if HarfordDnDConditions and HarfordDnDConditions.CanPerform then
            local allowed, condition = HarfordDnDConditions.CanPerform("action", {
                actorUnit = UnitGUID and UnitGUID("target") == SheetContext.npcSourceGuid and "target" or nil,
                actorGuid = actorRef, targetUnit = focusExists and "focus" or nil,
            })
            if not allowed then Print("El NPC no puede atacar: " .. tostring(condition or "condicion activa") .. "."); return nil end
        end
        if not focusExists then
            return DoRoll("Ataque " .. GetActionChatName(action), action.attackBonus, 0, "attack", { actorGuid = actorRef })
        end

        local base = toN(action.attackBonus, 0)
        local misc = HarfordDnDCalc.GetMiscBonus()
        local chosen, ra, rb, critTag, modeTag
        if savedRoll then
            chosen, ra, rb = savedRoll.chosen, savedRoll.ra, savedRoll.rb
            critTag, modeTag = savedRoll.critTag, savedRoll.modeTag
        else
            chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full("attack", {
                actorGuid = actorRef, targetUnit = "focus", attackRange = action.attackRange or "melee",
            })
        end
        local total = chosen + base + misc
        local bonusTxt = HarfordDnDCalc.BonusConcat(base, 0, misc)
        local armorClass, hit, armorText = HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, "focus")
        if armorText and armorText ~= "" then
            bonusTxt = bonusTxt .. armorText
        end

        -- (La consulta de Barrera se retiro: ver el ataque de jugador. Inalcanzable desde
        -- que RequestAttackReaction devuelve false siempre.)

        -- "Ataque <NOMBREFOCUS coloreado> <link de la accion>".
        local focusName = GetFocusColoredName()
        HarfordDnDRolls.Broadcast({
            type = "roll",
            targetUnit = "focus",
            label = "Ataque " .. (focusName and (focusName .. " ") or "") .. GetActionChatName(action),
            total = total,
            dice = HarfordDnDCalc.FormatD20Dice(chosen, ra, rb),
            modifiers = bonusTxt,
            critical = critTag,
            mode = modeTag,
            miscBonus = misc,
        })
        local isCritical = HarfordDnDCombat.IsCriticalRollTag(critTag)
        -- Focus jugador (incluye mi propio PJ: el NPC puede atacar a mi personaje).
        local focusPlayer = UnitIsPlayer and UnitIsPlayer("focus")

        if armorClass and focusPlayer then
            -- Focus jugador: en el impacto se aplica el daño de la accion (sin tirada
            -- manual) y se despacha herida/defensa al focus, sincronizado.
            local onImpactOnce
            if hit and (action.damageDice or action.conditionId) then
                onImpactOnce = function()
                    -- mitigationUnit "focus": jugador → sin mitigacion (no NPC).
                    local damageTotal, damageComponents, etiquetaDano
                    if action.damageDice then
                        damageTotal, damageComponents, etiquetaDano = RollActionDamage(action, isCritical, "focus")
                    end
                    damageTotal = damageTotal or 0
                    if damageTotal and damageTotal > 0 then
                        -- Contra otro jugador va el desglose por tipo EN BRUTO (lo resuelve su
                        -- cliente); contra uno mismo o un NPC, el total ya mitigado.
                        local paraFocus = damageTotal
                        if HarfordDamageMitigation and HarfordDamageMitigation.TargetResolvesOwnDamage
                            and HarfordDamageMitigation.TargetResolvesOwnDamage("focus") and damageComponents then
                            paraFocus = {}
                            for _, c in ipairs(damageComponents) do
                                paraFocus[#paraFocus + 1] = { amount = c.total, damageType = c.damageType }
                            end
                        end
                        -- La etiqueta viaja: la publica el jugador del focus con el nombre del NPC.
                        HarfordDnDCombat.ApplyActionDamageToFocus(paraFocus, nil, isCritical,
                            { label = etiquetaDano })
                    end
                    if action.conditionId and HarfordDnDConditions and HarfordDnDConditions.ApplyToUnit then
                        HarfordDnDConditions.ApplyToUnit("focus", action.conditionId, {
                            sourceGuid = SheetContext.npcSourceGuid,
                            sourceName = SheetContext.rollName,
                            duration = action.conditionDuration,
                            turns = action.conditionTurns,
                            saveAbility = action.conditionSaveAbility,
                            saveDC = action.conditionSaveDC,
                            persist = action.conditionPersist == true,
                        })
                    end
                end
            end
            HarfordDnDCombat.RunAttackSequence({
                family       = nil,  -- el swing del NPC lo da onAttackAnimation (boton Atacar)
                critical     = isCritical,
                hit          = hit == true,
                defenderUnit = "focus",
                npcAttacker  = true,
                onImpactOnce = onImpactOnce,
            })
        elseif armorClass and not focusPlayer then
            -- Focus NPC: combate NPC vs NPC ASINCRONO. Los comandos `.npc` (daño/herida/
            -- esquiva) solo actuan sobre el TARGET, y aqui la victima es el focus, no el
            -- target. Guardamos un "ataque pendiente" ligado al GUID de la victima; el
            -- daño (acierto) o la esquiva/parry (fallo) se aplican en la fase 2, cuando el
            -- DM targetea a ese NPC victima (ver HarfordDnDStore.ResolvePendingNpcAttack).
            -- El swing del atacante lo dispara el boton "Atacar" tras este roll.
            HarfordDnDStore.pendingNpcAttack = {
                guid = UnitGUID and UnitGUID("focus") or nil,
                action = action,
                isCritical = isCritical,
                hit = hit == true,
            }
            if DEFAULT_CHAT_FRAME then
                HarfordChat.Print("Ataque pendiente: targetea al NPC victima para aplicar el "
                    .. (hit and "daño" or "esquiva/parry") .. ".")
            end
        end
        ConsumeMode()
        return critTag
    end

    RollActionDamage = function(action, maximizeDice, mitigationUnit)
        if not action or not action.damageDice then return nil end
        mitigationUnit = mitigationUnit or "target"
        local components = action.damageComponents
        if type(components) ~= "table" or #components == 0 then
            components = {
                {
                    damageDice = action.damageDice,
                    damageBonus = action.damageBonus,
                    damageType = action.damageType,
                },
            }
        end
        local total, rolledComponents, details = 0, {}, {}
        for _, component in ipairs(components) do
            local n, sides = HarfordDnDWeapons.ParseDice(component.damageDice)
            if n and sides then
                local values, componentTotal = {}, tonumber(component.damageBonus) or 0
                for i = 1, n do
                    local value = maximizeDice and sides or HarfordDnDCalc.RollDie(sides)
                    values[#values + 1] = value
                    componentTotal = componentTotal + value
                end
                -- Defensas del objetivo (solo NPC): mitiga este componente y
                -- añade el marcador coloreado R/V/I junto al tipo de daño.
                local appliedTotal, marker = componentTotal, ""
                if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
                    local applied, _status, mk = HarfordDamageMitigation.ForTarget(
                        mitigationUnit, component.damageType, componentTotal)
                    appliedTotal, marker = applied, mk
                end
                local suffix = component.damageBonus and component.damageBonus ~= 0
                    and fmtSigned(component.damageBonus) or ""
                local typeSuffix = component.damageType and (" " .. component.damageType) or ""
                if marker ~= "" then typeSuffix = typeSuffix .. " " .. marker end
                details[#details + 1] = component.damageDice .. ": "
                    .. table.concat(values, "+") .. suffix .. typeSuffix
                rolledComponents[#rolledComponents + 1] = {
                    total = appliedTotal,
                    damageType = component.damageType,
                    marker = marker,
                }
                total = total + appliedTotal
            end
        end
        if #rolledComponents == 0 then return nil end
        -- Cabecera por tipo (igual que el daño de arma): el render hace "<total> <modifiers>",
        -- asi que el primer tipo aporta el numero y el resto van "N Tipo [R/V/I]" en modifiers.
        local dmgTypeOrder, dmgTypeMap = {}, {}
        for _, c in ipairs(rolledComponents) do
            local t = (c.damageType and c.damageType ~= "" and c.damageType) or "?"
            local e = dmgTypeMap[t]
            if not e then e = { total = 0, marker = "" }; dmgTypeMap[t] = e; dmgTypeOrder[#dmgTypeOrder + 1] = t end
            e.total = e.total + (tonumber(c.total) or 0)
            if c.marker and c.marker ~= "" then e.marker = c.marker end
        end
        local headlineTotal, modifiersTxt = HarfordDnDRolls.FormatDamageHeader(dmgTypeOrder, dmgTypeMap, total)
        local etiquetaDano = "Daño " .. tostring(action.title or "Accion")
        -- Igual que el ataque de arma: si la victima es un jugador que corre Harford, la linea la
        -- publica EL con su numero ya mitigado. Contra un NPC se resuelve aqui como siempre.
        local publicaLaVictima = HarfordDnDCombat and HarfordDnDCombat.VictimaPublicaSuDano
            and HarfordDnDCombat.VictimaPublicaSuDano(mitigationUnit)
        if not publicaLaVictima then
            HarfordDnDRolls.Broadcast({
                type = "damage",
                label = etiquetaDano,
                total = headlineTotal,
                dice = table.concat(details, " + "),
                modifiers = modifiersTxt,
                critical = maximizeDice and "CRÍTICO" or "",
                mode = "",
            })
        end
        -- Igual que el arma: la etiqueta solo se devuelve si este cliente ha callado, o
        -- publicarian los dos.
        return total, rolledComponents, (publicaLaVictima and etiquetaDano or nil)
    end

    -- Fase 2 del combate NPC vs NPC: cuando el DM targetea al NPC victima cuyo GUID
    -- coincide con el ataque pendiente (guardado en RollActionAttack), se ejecuta
    -- automaticamente. Acierto → tirada de daño (mitigada contra el target/victima) +
    -- SetNpcHealthDelta (con su herida). Fallo → esquiva/parry del NPC victima. El
    -- pendiente se consume siempre. La aplicacion a NPC va gateada por la propia
    -- HarfordDnDCombat (eje Oficial / IsOfficerPlus); el core no comprueba modo DM.
    HarfordDnDStore.ResolvePendingNpcAttack = function()
        local p = HarfordDnDStore.pendingNpcAttack
        if not p then return end
        if not (UnitExists and UnitExists("target")) then return end
        if UnitIsPlayer and UnitIsPlayer("target") then return end
        if not (UnitGUID and UnitGUID("target") == p.guid) then return end
        HarfordDnDStore.pendingNpcAttack = nil   -- consumir el pendiente
        if p.hit then
            local total = RollActionDamage(p.action, p.isCritical, "target")
            if total and total > 0 and HarfordDnDCombat and HarfordDnDCombat.ApplyWeaponDamageToNpc then
                HarfordDnDCombat.ApplyWeaponDamageToNpc(total, p.isCritical)
            end
            if p.action and p.action.conditionId and HarfordDnDConditions and HarfordDnDConditions.ApplyToUnit then
                HarfordDnDConditions.ApplyToUnit("target", p.action.conditionId, {
                    sourceGuid = SheetContext.npcSourceGuid,
                    sourceName = SheetContext.rollName,
                    duration = p.action.conditionDuration,
                    turns = p.action.conditionTurns,
                    saveAbility = p.action.conditionSaveAbility,
                    saveDC = p.action.conditionSaveDC,
                    persist = p.action.conditionPersist == true,
                })
            end
        elseif HarfordDnDCombat and HarfordDnDCombat.TriggerDefenseOnMiss then
            HarfordDnDCombat.TriggerDefenseOnMiss("target")
        end
    end

    -- Hay un focus victima valido: existe y no es el propio NPC (target). SI se
    -- permite que el focus sea mi propio PJ (el NPC puede atacar a mi personaje).
    local function HasFocusVictim()
        return UnitExists and UnitExists("focus")
            and not (UnitIsUnit and UnitIsUnit("focus", "target"))
    end

    local function RefreshSelectedAction()
        selectedAction = GetAction(selectedIndex)
        if not selectedAction then
            UIDropDownMenu_SetText(drop, "Sin ataques")
            parsedText:SetText("No se detectaron habilidades de ataque del NPC.")
            attackButton:Disable()
            damageButton:Disable()
            return
        end

        UIDropDownMenu_SetText(drop, selectedAction.title or ("Estado " .. tostring(selectedIndex)))

        local summary = {}
        if selectedAction.attackBonus ~= nil then
            summary[#summary + 1] = "Ataque " .. fmtSigned(selectedAction.attackBonus)
        end
        if selectedAction.damageDice then
            local damageParts = {}
            local components = selectedAction.damageComponents
            if type(components) ~= "table" or #components == 0 then
                components = { selectedAction }
            end
            for _, component in ipairs(components) do
                local bonus = component.damageBonus and component.damageBonus ~= 0
                    and fmtSigned(component.damageBonus) or ""
                damageParts[#damageParts + 1] = component.damageDice .. bonus
                    .. (component.damageType and (" " .. component.damageType) or "")
            end
            summary[#summary + 1] = "Daño " .. table.concat(damageParts, " + ")
        end
        if selectedAction.area then
            local shape = ({ cone = "Cono", sphere = "Radio", line = "Linea", other = "Area" })[selectedAction.area.shape] or "Area"
            summary[#summary + 1] = shape .. (selectedAction.area.sizeText and (" " .. selectedAction.area.sizeText) or "")
        end
        parsedText:SetText(#summary > 0 and table.concat(summary, "   ") or "No se pudo interpretar una tirada automatica.")
        -- Atacar y Daño Custom requieren un focus victima valido (no yo, no el NPC).
        local hasFocus = HasFocusVictim()
        local isArea = type(selectedAction.area) == "table"
        local canAttack = isArea or (selectedAction.attackBonus ~= nil and hasFocus)
        local canDamage = (not isArea) and hasFocus  -- daño custom: no depende de que la accion tenga dados
        if canAttack and SheetContext.canAttack then
            canAttack = SheetContext.canAttack() == true
        end
        if canDamage and SheetContext.canDamage then
            canDamage = SheetContext.canDamage() == true
        end
        attackButton:SetEnabled(canAttack)
        damageButton:SetEnabled(canDamage)
        attackButton:SetText(isArea and "Marcar area" or "Atacar")
    end

    UIDropDownMenu_Initialize(drop, function(_, level)
        if level ~= 1 then return end
        -- Solo se ofrecen las habilidades detectadas como ataque utilizable.
        for i, action in ipairs(SheetContext.actions or {}) do
            if IsAttackAction(action) then
                local info = UIDropDownMenu_CreateInfo()
                info.text = action.title or ("Estado " .. tostring(i))
                info.checked = (i == selectedIndex)
                info.func = function()
                    selectedIndex = i
                    RefreshSelectedAction()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    attackButton = HarfordDnDUI.MakeButton(panel, "Atacar", 112, 22, 72, -122, function()
        if selectedAction and selectedAction.area then
            if HarfordDnDConditions and HarfordDnDConditions.CanPerform then
                local allowed, condition = HarfordDnDConditions.CanPerform("action", {
                    actorUnit = UnitGUID and UnitGUID("target") == SheetContext.npcSourceGuid and "target" or nil,
                    actorGuid = SheetContext.npcSourceGuid,
                })
                if not allowed then Print("El NPC no puede actuar: " .. tostring(condition or "condicion activa") .. "."); return end
            end
            local definition, err
            if HarfordDnDArea and HarfordDnDArea.DefinitionFromAction then
                definition, err = HarfordDnDArea.DefinitionFromAction(selectedAction)
            end
            if not definition then
                if DEFAULT_CHAT_FRAME then
                    HarfordChat.Print(tostring(err or "Definicion de area incompleta."))
                end
                return
            end
            local emoteOpt = EMOTE_OPTIONS[selectedEmoteIndex]
            local emoteId = emoteOpt and emoteOpt.id
            HarfordDnDArea.Open(definition, {
                sourceKind = "npc",
                sourceGuid = SheetContext.npcSourceGuid,
                onBegin = function()
                    if emoteId and SheetContext.onAttackAnimation then SheetContext.onAttackAnimation(emoteId) end
                end,
            })
        elseif selectedAction and selectedAction.attackBonus ~= nil then
            -- Admin valida que el NPC de la ficha siga siendo el target exacto.
            local critTag = RollActionAttack(selectedAction)
            pendingCriticalAction = critTag == "CRÍTICO" and selectedAction or nil
            -- Animacion: se dispara DESPUES del roll para poder elegir el emote correcto.
            -- Critico → critEmoteId si existe, fallback al emote del dropdown.
            -- Normal  → emote del dropdown.
            local emoteOpt = EMOTE_OPTIONS[selectedEmoteIndex]
            local normalId = emoteOpt and emoteOpt.id
            local isCrit   = critTag == "CRÍTICO"
            local eid = (isCrit and selectedAction.critEmoteId) or normalId
            if eid then
                if SheetContext.onAttackAnimation then
                    SheetContext.onAttackAnimation(eid)
                elseif HarfordServerActions and HarfordServerActions.SetNpcEmote then
                    HarfordServerActions.SetNpcEmote(eid)
                end
            end
        end
    end)

    -- "Daño Custom": abre el frame de daño custom aplicado al FOCUS, en nombre del
    -- NPC (la tirada usa el contexto NPC activo → nombre/color del NPC). El daño de
    -- ataque al impactar ya esta automatizado en RollActionAttack.
    damageButton = HarfordDnDUI.MakeButton(panel, "Daño Custom", 112, 22, 198, -122, function()
        if HarfordDnDStore.OpenCustomDamageFrame then
            HarfordDnDStore.OpenCustomDamageFrame("focus")
        end
    end)

    local function SetPlayerControlShown(control, shown)
        if not control then return end

        if shown then
            if control.Show then control:Show() end
            if control._harfordNpcModeWasEnabled ~= nil and control.Enable and control.Disable then
                if control._harfordNpcModeWasEnabled then
                    control:Enable()
                else
                    control:Disable()
                end
                control._harfordNpcModeWasEnabled = nil
            end
            return
        end

        if control._harfordNpcModeWasEnabled == nil and control.IsEnabled then
            control._harfordNpcModeWasEnabled = control:IsEnabled() and true or false
        end
        if control.Disable then control:Disable() end
        if control.Hide then control:Hide() end
    end

    RefreshSheetActionPanel = function(resetSelection)
        local inNpcMode = SheetContext.showActionPanel
        for _, control in pairs(HarfordDnDStore.playerAttackControls or {}) do
            SetPlayerControlShown(control, not inNpcMode)
        end
        -- El checkbox de animaciones no tiene sentido en la ficha NPC
        local chk   = HarfordDnDStore.animsCheckbox
        local label = HarfordDnDStore.animsCheckboxLabel
        if chk   then chk:SetShown(not inNpcMode) end
        if label then label:SetShown(not inNpcMode) end
        -- El botón de modo combate del jugador es exclusivo del modo jugador.
        local combatBtn = HarfordDnDStore.combatModeButton
        if combatBtn then
            combatBtn:SetShown((not inNpcMode) and HarfordDnDStore.AreAnimationsEnabled())
        end
        if inNpcMode and HarfordDnDStore.customDamageFrame then
            HarfordDnDStore.customDamageFrame:Hide()
        end

        if not inNpcMode then
            RefreshArmorClassBoxes()
            HarfordDnDAttackUI.RefreshWeaponInfo()
            panel:Hide()
            return
        end
        if resetSelection ~= false then
            -- Por defecto, el ultimo ataque utilizable: los ataques principales
            -- suelen estar al final de la lista de estados TRP3.
            local actions = SheetContext.actions or {}
            selectedIndex = 1
            for i = #actions, 1, -1 do
                if IsAttackAction(actions[i]) then
                    selectedIndex = i
                    break
                end
            end
        end
        panel:Show()
        panel:Raise()
        RefreshArmorClassBoxes()
        RefreshSelectedAction()
    end

    return RefreshSheetActionPanel
end
