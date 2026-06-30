-- HarfordDnDCombat: reglas de combate compartidas que no pertenecen a UI.
-- Mantiene fuera de HarfordDnD.lua la resolucion de CA/impacto y aplicaciones
-- pequeñas de combate que consultan unit tokens, TRP3, turnos o cache remota.

HarfordDnDCombat = HarfordDnDCombat or {}
HarfordDnDCombat.ArmorClassOverrides = HarfordDnDCombat.ArmorClassOverrides or {}

local ADDON_PREFIX = "DND5EARC"

local GREEN = "|cff00ff00"
local RED = "|cffff3333"
local ENDCLR = "|r"


local function GetSelfArmorClass()
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("armorClass")
        or 0
    -- La CA manual de la ficha quedo OBSOLETA: se usa la CA de la armadura EQUIPADA
    -- (que ya incluye Destreza por categoria y escudo). La CA de TRP3 "Currently"/"Other
    -- Information" tiene aun mas prioridad y se resuelve antes en GetArmorClassForUnit.
    local equipped = HarfordDnDItems and HarfordDnDItems.GetEquippedArmorClass
        and HarfordDnDItems.GetEquippedArmorClass()
        or nil
    if equipped then
        return math.floor(equipped + bonus)
    end
    -- Sin armadura ni escudo equipados: desarmado 10 + Mod. Destreza. Los rasgos de
    -- "Defensa sin Armadura" (Monje: Sabiduria) suman aqui el Mod. de su caracteristica,
    -- y SOLO aqui: con armadura o escudo equipados se cae a la rama anterior y no aplican.
    local dex = (HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod("Destreza")) or 0
    local unarmored = 0
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetUnarmoredDefenseAbilities and HarfordDnDCalc then
        for _, ability in ipairs(HarfordDnDFeatureEffects.GetUnarmoredDefenseAbilities()) do
            unarmored = unarmored + (HarfordDnDCalc.GetAbilityMod(ability) or 0)
        end
    end
    return math.floor(10 + dex + unarmored + bonus)
end

-- CA efectiva del jugador para PERSISTIR/ENVIAR a otros clientes: TRP3 "Other Information"
-- (CO) / "Currently" (CU) si hay un valor escrito ahi; si no, la CA de la armadura equipada.
-- Asi otros ven tu CA de equipo sin que la pongas en TRP3, pero un valor en TRP3 manda.
function HarfordDnDCombat.ComputeSelfArmorClass()
    local trp3 = HarfordTRP3 and HarfordTRP3.GetPlayerArmorClass
        and HarfordTRP3.GetPlayerArmorClass("player")
    if trp3 then return math.floor(trp3) end
    return GetSelfArmorClass()
end

local function GetUnitKeys(unit)
    local keys = {}
    local guid = UnitGUID and UnitGUID(unit) or nil
    if guid and guid ~= "" then keys[#keys + 1] = guid end

    local fullName = GetUnitName and GetUnitName(unit, true) or nil
    local shortName = UnitName and UnitName(unit) or nil
    if fullName and fullName ~= "" then keys[#keys + 1] = fullName end
    if shortName and shortName ~= "" and shortName ~= fullName then keys[#keys + 1] = shortName end
    return keys
end

local function GetOverrideArmorClassForUnit(unit)
    local overrides = HarfordDnDCombat.ArmorClassOverrides
    for _, key in ipairs(GetUnitKeys(unit)) do
        local value = overrides[key]
        local armorClass = tonumber(value)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end
    end
    return nil
end

local function SetOverrideArmorClassForUnit(unit, armorClass)
    local overrides = HarfordDnDCombat.ArmorClassOverrides
    for _, key in ipairs(GetUnitKeys(unit)) do
        overrides[key] = armorClass
    end
end

function HarfordDnDCombat.GetRemoteArmorClassForUnit(unit)
    if not (UnitName and HarfordDnDResources and HarfordDnDResources.RemoteCache) then
        return nil
    end

    local name = HarfordClassColors.UnitFullName(unit)
    local short = name and Ambiguate and Ambiguate(name, "short") or name
    local cache = (name and HarfordDnDResources.RemoteCache[name])
        or (short and HarfordDnDResources.RemoteCache[short])
    local armorClass = cache and tonumber(cache.ArmorClass)
    if armorClass and armorClass > 0 then
        return math.floor(armorClass)
    end
    return nil
end

function HarfordDnDCombat.GetProfileArmorClassForUnit(unit)
    if not UnitName then return nil end

    local names = {}
    local fullName = GetUnitName and GetUnitName(unit, true) or nil
    local shortName = UnitName(unit)
    if fullName and fullName ~= "" then names[#names + 1] = fullName end
    if shortName and shortName ~= "" and shortName ~= fullName then names[#names + 1] = shortName end

    for _, name in ipairs(names) do
        local profile = HarfordDnDProfileBank and HarfordDnDProfileBank[name]
        local armorClass = profile and tonumber(profile.ArmorClass)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end

        local storeProfile = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
            and HarfordDnDPersistStore.profiles[name]
        armorClass = storeProfile and tonumber(storeProfile.ArmorClass)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end
    end

    return nil
end

function HarfordDnDCombat.GetArmorClassForUnit(unit)
    if not (unit and UnitExists and UnitExists(unit)) then
        return nil
    end

    if UnitIsPlayer and UnitIsPlayer(unit) then
        -- La CA de "Currently" (TRP3) tiene prioridad SIEMPRE, incluso para uno mismo,
        -- por encima de la CA local de la ficha Harford.
        local trp3ArmorClass = HarfordTRP3 and HarfordTRP3.GetPlayerArmorClass
            and HarfordTRP3.GetPlayerArmorClass(unit)
        if trp3ArmorClass then
            return trp3ArmorClass
        end
        if UnitIsUnit and UnitIsUnit(unit, "player") then
            return GetSelfArmorClass()
        end
        return HarfordDnDCombat.GetRemoteArmorClassForUnit(unit)
            or GetOverrideArmorClassForUnit(unit)
            or HarfordDnDCombat.GetProfileArmorClassForUnit(unit)
    end

    local guid = UnitGUID and UnitGUID(unit)
    if guid and HarfordTurnOrderAPI and HarfordTurnOrderAPI.GetArmorClassForGuid then
        local turnArmorClass = HarfordTurnOrderAPI.GetArmorClassForGuid(guid)
        if turnArmorClass and turnArmorClass > 0 then
            return math.floor(turnArmorClass)
        end
    end

    local overrideArmorClass = GetOverrideArmorClassForUnit(unit)
    if overrideArmorClass then
        return overrideArmorClass
    end

    if HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local statBlock = HarfordTRP3.GetNPCStatBlock(unit)
        local armorClass = statBlock and tonumber(statBlock.ac)
        if armorClass and armorClass > 0 then
            return math.floor(armorClass)
        end
    end

    return nil
end

function HarfordDnDCombat.SetArmorClassForUnit(unit, value)
    if not (unit and UnitExists and UnitExists(unit)) then
        return false, "Sin objetivo"
    end

    local armorClass = math.floor(tonumber(value) or 0)
    if armorClass < 0 then armorClass = 0 end

    if UnitIsPlayer and UnitIsPlayer(unit) then
        if UnitIsUnit and UnitIsUnit(unit, "player") then
            if HarfordDnDContext and HarfordDnDContext.Set then
                HarfordDnDContext.Set("ArmorClass", armorClass)
                return true
            end
            return false, "HarfordDnDContext no disponible"
        end

        SetOverrideArmorClassForUnit(unit, armorClass)
        return true
    end

    SetOverrideArmorClassForUnit(unit, armorClass)

    local guid = UnitGUID and UnitGUID(unit) or nil
    if guid and HarfordTurnOrderAPI and HarfordTurnOrderAPI.SetArmorClassForGuid then
        HarfordTurnOrderAPI.SetArmorClassForGuid(guid, armorClass)
    end
    return true
end

function HarfordDnDCombat.IsCriticalRollTag(critTag)
    return critTag == "CRITICO" or critTag == "CR\195\141TICO"
end

function HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, unit)
    local armorClass = HarfordDnDCombat.GetArmorClassForUnit(unit or "target")
    if not armorClass or armorClass <= 0 then
        return nil, nil, ""
    end

    local hit
    if HarfordDnDCombat.IsCriticalRollTag(critTag) then
        hit = true
    elseif critTag == "PIFIA" then
        hit = false
    else
        hit = (tonumber(total) or 0) > armorClass  -- empate = fallo para el atacante (el defensor gana los empates)
    end

    local status = hit and (GREEN .. "Superada" .. ENDCLR) or (RED .. "No superada" .. ENDCLR)
    return armorClass, hit, " vs CA " .. tostring(armorClass) .. " " .. status
end

-- Caracteristica ES -> clave del stat block TRP3 (ingles), para resolver salvaciones.
local SAVE_STAT_KEY = {
    Fuerza = "strength", Destreza = "dexterity", Constitucion = "constitution",
    Inteligencia = "intelligence", Sabiduria = "wisdom", Carisma = "charisma",
}

-- Bonus de tirada de salvacion del objetivo para una caracteristica (nombre ES).
-- NPC companion o jugador interpretado via TRP3: usa la salvacion del stat block si
-- existe; si no, el modificador de la caracteristica; si no hay dato fiable, +0.
function HarfordDnDCombat.GetSaveBonusForUnit(unit, abilityES)
    local statKey = SAVE_STAT_KEY[abilityES]
    if not (statKey and unit and UnitExists and UnitExists(unit)) then return 0 end
    if HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local sb = HarfordTRP3.GetNPCStatBlock(unit)
        if sb then
            local sv = sb.savingThrows and tonumber(sb.savingThrows[statKey])
            if sv then return sv end
            local st = sb.stats and sb.stats[statKey]
            if st and tonumber(st.mod) then return tonumber(st.mod) end
        end
    end
    return 0
end

-- Vida efectiva ACTUAL del objetivo, para "parar al morir" (no gastar/dañar de mas):
--   NPC     -> UnitHealth("target") (= vida D&D, porque Harford la modifica en el servidor).
--   Jugador -> cache remota (health + temp_health; su barra de WoW NO es la vida D&D).
-- Devuelve numero o nil (desconocida -> no se capa, comportamiento de siempre).
function HarfordDnDCombat.GetTargetEffectiveHP()
    if not (UnitExists and UnitExists("target")) then return nil end
    if UnitIsPlayer and UnitIsPlayer("target") then
        local name = HarfordClassColors.UnitFullName("target")
        local cache = HarfordDnDResources and HarfordDnDResources.RemoteCache
        if name and cache and HarfordDnDResources.CurKey then
            local short = Ambiguate and Ambiguate(name, "short") or name
            local tbl = cache[name] or cache[short]
            if tbl then
                local hp = tonumber(tbl[HarfordDnDResources.CurKey("health")])
                if hp then
                    local temp = math.max(0, tonumber(tbl[HarfordDnDResources.CurKey("temp_health")]) or 0)
                    return hp + temp
                end
            end
        end
        return nil
    end
    if UnitHealth then
        local hp = tonumber(UnitHealth("target"))
        if hp and hp > 0 then return hp end
    end
    return nil
end

function HarfordDnDCombat.ApplyWeaponDamageToNpc(total, isCritical)
    if total and total > 0
        and HarfordAuthority and HarfordAuthority.IsOfficerPlus and HarfordAuthority.IsOfficerPlus()
        and UnitExists and UnitExists("target")
        and not (UnitIsPlayer and UnitIsPlayer("target"))
        and HarfordServerActions and HarfordServerActions.SetNpcHealthDelta then
        HarfordServerActions.SetNpcHealthDelta(-total, {
            isCritical = isCritical,
            addonName  = "Harford",
        })
        if HarfordDnDConditions and HarfordDnDConditions.OnDamageTaken then
            HarfordDnDConditions.OnDamageTaken("target", total)
        end
        return true
    end
    return false
end

-- Aplica daño a un jugador (unit token) por RADJ: consume primero temp_health
-- (segun la cache remota) y el resto a health. Si no hay cache, manda todo a health
-- y solicita recursos para futuras tiradas. El cliente receptor aplica el delta (y
-- su propia aura de muerte segun su flag de animaciones).
local function ApplyDamageToPlayerUnit(unit, total)
    local name = HarfordClassColors.UnitFullName(unit)
    if not name or name == "" then return false end
    if not (HarfordSync and HarfordSync.SendResourceAdjust) then return false end

    local tempCur = 0
    local cache = HarfordDnDResources and HarfordDnDResources.RemoteCache
    if cache then
        local short = Ambiguate and Ambiguate(name, "short") or name
        cache = cache[name] or cache[short]
    end
    if cache then
        tempCur = math.max(0, tonumber(cache[HarfordDnDResources.CurKey("temp_health")]) or 0)
    elseif HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName then
        HarfordDnDAPI.RequestResourcesForName(name)
    end

    local tempDmg = math.min(total, tempCur)
    local healthDmg = total - tempDmg
    if tempDmg > 0 then
        HarfordSync.SendResourceAdjust(ADDON_PREFIX, "temp_health", -tempDmg, name)
    end
    if healthDmg > 0 then
        HarfordSync.SendResourceAdjust(ADDON_PREFIX, "health", -healthDmg, name)
    end
    return true
end

local function ApplyWeaponDamageToPlayer(total)
    return ApplyDamageToPlayerUnit("target", total)
end

-- Aplica daño de una accion NPC al jugador en FOCUS (no a uno mismo ni a un NPC).
-- Lo usa el ataque NPC de la ficha para dañar al focus en el impacto sin tirada
-- manual. El focus NPC no se daña por esta via (los `.npc` actuan sobre el target).
function HarfordDnDCombat.ApplyActionDamageToFocus(total)
    if not (total and total > 0 and UnitExists and UnitExists("focus")) then return false end
    -- Focus = mi propio PJ: el NPC ataca a mi personaje -> daño local directo.
    if UnitIsUnit and UnitIsUnit("focus", "player") then
        if HarfordDnDStore and HarfordDnDStore.ApplyLocalResourceDamage then
            HarfordDnDStore.ApplyLocalResourceDamage(total)
            return true
        end
        return false
    end
    if not (UnitIsPlayer and UnitIsPlayer("focus")) then return false end
    return ApplyDamageToPlayerUnit("focus", total)
end

-- ─── Reaccion defensiva al fallar el ataque (parry/dodge) ─────────────────────
-- Registro RUNTIME (no persistente) del modo de combate elegido para cada NPC por
-- su GUID. Se rellena cuando el dropdown de modo de combate de la ficha NPC fija
-- una postura para el NPC cargado; se consulta cuando ese GUID es el defensor.
HarfordDnDCombat.NpcCombatModeByGuid = HarfordDnDCombat.NpcCombatModeByGuid or {}

function HarfordDnDCombat.SetNpcCombatMode(guid, modeKey)
    if guid and guid ~= "" then
        HarfordDnDCombat.NpcCombatModeByGuid[guid] = modeKey
    end
end

function HarfordDnDCombat.GetCombatModeForGuid(guid)
    return guid and guid ~= "" and HarfordDnDCombat.NpcCombatModeByGuid[guid] or nil
end

-- Detecta si el JUGADOR LOCAL lleva un escudo en la mano secundaria (slot 17).
-- Clase 4 (Armadura) / subclase 6 (Escudos) en GetItemInfoInstant.
local function LocalPlayerHasShield()
    if not (GetInventoryItemID and GetItemInfoInstant) then return false end
    local slot = (type(INVSLOT_OFFHAND) == "number" and INVSLOT_OFFHAND) or 17
    local id = GetInventoryItemID("player", slot)
    if not id then return false end
    local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(id)
    return classID == 4 and subClassID == 6
end

-- Ejecuta la defensa del JUGADOR LOCAL (al recibir DODEFENSE o defenderse uno
-- mismo): con escudo equipado -> block; si no, parry/dodge segun su modo de combate
-- activo. Corre la secuencia en su propio cliente (`mod anim` sobre uno mismo, no
-- requiere oficial). Respeta el flag de animaciones del jugador.
function HarfordDnDCombat.PlayLocalDefense()
    if HarfordDnDStore and HarfordDnDStore.AreAnimationsEnabled
        and not HarfordDnDStore.AreAnimationsEnabled() then
        return false
    end
    local modeKey = HarfordDnDStore and HarfordDnDStore.combatModeKey or nil
    local seq = HarfordEmotes and HarfordEmotes.PickDefenseSeq
        and HarfordEmotes.PickDefenseSeq(modeKey, LocalPlayerHasShield())
    if not (seq and HarfordActionSequence and HarfordActionSequence.RunByName) then
        return false
    end
    return HarfordActionSequence.RunByName(seq) or false
end

-- Dispara la reaccion defensiva del defensor cuando el ataque falla.
--   NPC defensor: solo si el atacante es oficial (los no-oficiales no emiten
--     comandos a NPC) -> `.npc emote <id>` one-shot segun el modo recordado del
--     GUID (o dodge por defecto). Actua sobre el NPC seleccionado por el servidor.
--   Jugador ajeno: se le envia DODEFENSE; su cliente ejecuta su propia defensa.
--   Uno mismo: defensa local directa.
function HarfordDnDCombat.TriggerDefenseOnMiss(defenderUnit)
    if not (defenderUnit and UnitExists and UnitExists(defenderUnit)) then return end

    if UnitIsUnit and UnitIsUnit(defenderUnit, "player") then
        HarfordDnDCombat.PlayLocalDefense()
        return
    end

    if UnitIsPlayer and UnitIsPlayer(defenderUnit) then
        local name = HarfordClassColors.UnitFullName(defenderUnit)
        if name and name ~= "" and HarfordSync and HarfordSync.SendDefense then
            HarfordSync.SendDefense(ADDON_PREFIX, name)
        end
        return
    end

    -- NPC: el atacante (origen) ejecuta el `npc emote` en su propio cliente; requiere
    -- su flag de animaciones activo Y ser oficial+ (los no-oficiales no emiten a NPC).
    if HarfordDnDStore and HarfordDnDStore.AreAnimationsEnabled
        and not HarfordDnDStore.AreAnimationsEnabled() then
        return
    end
    if not (HarfordAuthority and HarfordAuthority.IsOfficerPlus and HarfordAuthority.IsOfficerPlus()) then
        return
    end
    -- `.npc emote` actua sobre el NPC seleccionado (target) del servidor. Solo se
    -- ejecuta si el defensor ES ese target; si no (p.ej. defensor "focus" mientras el
    -- target es el NPC atacante de la ficha), animaria al NPC equivocado -> se omite.
    if not (UnitIsUnit and UnitIsUnit(defenderUnit, "target")) then
        return
    end
    local guid = UnitGUID and UnitGUID(defenderUnit) or nil
    local modeKey = HarfordDnDCombat.GetCombatModeForGuid(guid)
    local seq = HarfordEmotes and HarfordEmotes.PickDefenseSeq
        and HarfordEmotes.PickDefenseSeq(modeKey, false)
    -- Misma secuencia que el jugador, pero con npcAnim: los pasos `anim` salen como
    -- `.npc emote` sobre el NPC objetivo (no poseido) y el sonido se reproduce local.
    if seq and HarfordActionSequence and HarfordActionSequence.RunByName then
        HarfordActionSequence.RunByName(seq, { npcAnim = true, addonName = "Harford" })
    end
end

-- IDs de herida (compartidos con NPC_WOUND/CRIT de HarfordEmotes).
local function WoundAnimId(isCritical)
    local key = isCritical and "NPC_WOUND_CRIT" or "NPC_WOUND"
    local def = HarfordEmotes and HarfordEmotes[key]
    return (def and def.id) or (isCritical and 34 or 33)
end

local function AttackerAnimsOn()
    return not (HarfordDnDStore and HarfordDnDStore.AreAnimationsEnabled
        and not HarfordDnDStore.AreAnimationsEnabled())
end

-- Herida del JUGADOR LOCAL (al recibir DOWOUND o herirse uno mismo): `mod anim`
-- 33/34 sobre uno mismo. Respeta el flag de animaciones del jugador.
function HarfordDnDCombat.PlayLocalWound(isCritical)
    if not AttackerAnimsOn() then return false end
    if HarfordServerActions and HarfordServerActions.ModAnim then
        HarfordServerActions.ModAnim(WoundAnimId(isCritical))
        return true
    end
    return false
end

-- Dispara la herida del defensor al impactar.
--   Uno mismo / jugador ajeno: su cliente anima (`mod anim 33/34`) -> DOWOUND.
--   NPC: la herida ya la emite SetNpcHealthDelta al aplicar el daño (npc emote
--        33/34). No se duplica aqui.
function HarfordDnDCombat.TriggerWoundOnHit(defenderUnit, isCritical)
    if not (defenderUnit and UnitExists and UnitExists(defenderUnit)) then return end
    if UnitIsUnit and UnitIsUnit(defenderUnit, "player") then
        HarfordDnDCombat.PlayLocalWound(isCritical)
        return
    end
    if UnitIsPlayer and UnitIsPlayer(defenderUnit) then
        local name = HarfordClassColors.UnitFullName(defenderUnit)
        if name and name ~= "" and HarfordSync and HarfordSync.SendWound then
            HarfordSync.SendWound(ADDON_PREFIX, name, isCritical)
        end
        return
    end
    -- NPC: herida via SetNpcHealthDelta al aplicar el daño; no duplicar.
end

-- Orquesta la animacion de ataque del ORIGEN y sincroniza la reaccion del objetivo
-- con el momento de impacto del preset.
--   opts.family    : familia de animacion (HarfordDnDWeapons.GetAnimFamily) o nil.
--   opts.critical  : golpe critico (elige preset pesado).
--   opts.offhand   : ataque con mano secundaria.
--   opts.hit       : true=impacto, false=fallo, nil=desconocido (sin reaccion).
--   opts.defenderUnit : unit del objetivo ("target"/"focus").
--   opts.npcAttacker  : true si el atacante es un NPC (anim via npc emote).
--   opts.onImpactOnce : callback de daño (mecanico), se ejecuta UNA vez en el impacto.
-- El daño (onImpactOnce) es mecanico y se aplica siempre; el swing/reaccion son
-- animaciones y van detras del flag de animaciones.
function HarfordDnDCombat.RunAttackSequence(opts)
    opts = opts or {}
    local fired = false
    local function impact()
        if fired then return end
        fired = true
        if opts.onImpactOnce then opts.onImpactOnce() end
        if opts.hit == true then
            HarfordDnDCombat.TriggerWoundOnHit(opts.defenderUnit, opts.critical)
        elseif opts.hit == false then
            HarfordDnDCombat.TriggerDefenseOnMiss(opts.defenderUnit)
        end
    end

    local seqName
    if AttackerAnimsOn() and opts.family then
        seqName = HarfordEmotes and HarfordEmotes.GetAttackSequence
            and HarfordEmotes.GetAttackSequence(opts.family, { critical = opts.critical, offhand = opts.offhand })
    end

    if seqName and HarfordActionSequence and HarfordActionSequence.RunByName then
        HarfordActionSequence.RunByName(seqName, {
            npcAnim         = opts.npcAttacker or nil,
            addonName       = "Harford",
            interceptImpact = true,
            onImpact        = impact,
        })
    elseif AttackerAnimsOn() and opts.family == nil and opts.hit ~= nil
        and C_Timer and C_Timer.After then
        -- Sin preset (arco/rifle/conjuro): el swing lo mantiene el emote actual del
        -- llamador; aqui solo se sincroniza la reaccion con un pequeño delay de viaje.
        C_Timer.After(0.4, impact)
    else
        -- Animaciones off o sin reaccion a sincronizar: aplicar impacto ya.
        impact()
    end
end

-- Aplica el daño al objetivo actual segun su tipo: NPC (ruta oficial, en bruto) o
-- jugador ajeno (RADJ con split temp/health). No hace nada contra uno mismo.
function HarfordDnDCombat.ApplyWeaponDamageToTarget(total, isCritical)
    if not (total and total > 0 and UnitExists and UnitExists("target")) then return false end
    if UnitIsUnit and UnitIsUnit("target", "player") then return false end
    if UnitIsPlayer and UnitIsPlayer("target") then
        return ApplyWeaponDamageToPlayer(total)
    end
    return HarfordDnDCombat.ApplyWeaponDamageToNpc(total, isCritical)
end
