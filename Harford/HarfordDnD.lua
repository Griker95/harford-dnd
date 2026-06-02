-- DND 5e (persistencia local + sync) + UI completa (/FichaHarford)

if _G.DND5E_ARC_LOADED and _G.DND5E_PlayerFrame then
    local api = _G.DND5E_ARC_API
    if api and api.Toggle then
        api.Toggle()
    else
        local f = _G.DND5E_PlayerFrame
        f:SetShown(not f:IsShown())
    end
    return
end

local ADDON_PREFIX = "DND5EARC"
local ADDON_VERSION = "1.0"

HarfordDnDPersistStore = HarfordDnDPersistStore or {}
HarfordDnDStore = HarfordDnDStore or {}
HarfordDnDStore.state = HarfordDnDStore.state or { persist = HarfordDnDPersistStore, runtime = {} }
HarfordDnDStore.state.persist = HarfordDnDPersistStore
HarfordDnDStore.state.runtime = HarfordDnDStore.state.runtime or {}

local GetWeaponKey
local GetWeaponDef
local UpdateWeaponInfoUI
local SyncWeaponDrop
local ApplyShortRest
local ApplyLongRest
local ScheduleMyResourceBroadcast
local AnchorTargetResourceFrame
local DoSpellAttack
local RefreshResourceFrame
local RefreshTargetResourceFrame
local RefreshSheetActionPanel
local RefreshDyingState

local F
local FrameTitle          -- FontString del titulo principal; admite contexto externo de ficha
local ResourceFrame
local TargetResourceFrame

local EnsureDefaults = function() end

local RESOURCE_ORDER = HarfordDnDResources.ORDER
local ALL_RESOURCE_KEYS = HarfordDnDResources.ALL_KEYS
local ResourceCurKey = HarfordDnDResources.CurKey
local ResourceMaxKey = HarfordDnDResources.MaxKey

-- Contexto temporal de ficha y accesores ARC: viven en HarfordDnDContext.
-- El runtime profile se lee siempre en vivo de HarfordDnDStore.state.runtime
-- (ya no hay alias local ni sync-hook).
local SheetContext = HarfordDnDContext.State

local ARCGET = HarfordDnDContext.Get
local ARCSET = HarfordDnDContext.Set

local function RefreshMainUI()
    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
        _G.DND5E_ARC_API.Refresh()
    end
end

-- Persistencia de perfil: EnsurePersist/LoadPersistToRuntime/SaveCurrentProfileToBank
-- se invocan directamente sobre HarfordDnDStore. Apply*/MergeProfFlags viven en
-- HarfordDnDProfile (con EnsureDefaults/RefreshMainUI inyectados via SetHooks mas abajo).

local function RegisterPrefix(prefix)
    if HarfordSync and HarfordSync.RegisterPrefix then
        HarfordSync.RegisterPrefix(prefix)
    elseif C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
end

local function SendPrefix(prefix, message, channel, target)
    if HarfordSync and HarfordSync.Send then
        HarfordSync.Send(prefix, message, channel, target)
    elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(prefix, message, channel, target)
    elseif SendAddonMessage then
        SendAddonMessage(prefix, message, channel, target)
    end
end

local function BestChannel()
    if HarfordSync and HarfordSync.BestChannel then
        return HarfordSync.BestChannel()
    end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

local GREEN = "|cff00ff00"
local RED   = "|cffff3333"
local ENDCLR = "|r"

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

local function ColorSigned(n)
    n = toN(n, 0)
    if n < 0 then return RED .. fmtSigned(n) .. ENDCLR end
    return GREEN .. fmtSigned(n) .. ENDCLR
end

RegisterPrefix(ADDON_PREFIX)

-- AbilityMod, RollDie, RollD20 viven en HarfordDnDCalc.

-- ABIL/SKILLS viven en HarfordDnDData; WEAPONS y helpers de arma en HarfordDnDWeapons.
-- Se referencian directamente como HarfordDnDData.* / HarfordDnDWeapons.* (no aliases locales).

local RESOURCE_DEFS = HarfordDnDResources.DEFS
local RESOURCE_PROFILE_KEYS = HarfordDnDResources.PROFILE_KEYS
local RESOURCE_RUNTIME_KEYS = HarfordDnDResources.RUNTIME_KEYS


EnsureDefaults = function()
    if ARCGET("BonusCompetencia", nil) == nil then ARCSET("BonusCompetencia", "2") end
    if ARCGET("ModoTirada", nil) == nil then ARCSET("ModoTirada", "normal") end
    if ARCGET("BonoSituacional", nil) == nil then ARCSET("BonoSituacional", "0") end
    if ARCGET("ArmorClass", nil) == nil then ARCSET("ArmorClass", "10") end
    if ARCGET("ModIniciativa", nil) == nil then ARCSET("ModIniciativa", "0") end
    if ARCGET("AtributoConjuro", nil) == nil then ARCSET("AtributoConjuro", "Inteligencia") end
    if ARCGET("ArmaSeleccionada", nil) == nil then ARCSET("ArmaSeleccionada", "Desarmado") end
    if ARCGET("ModArma", nil) == nil then ARCSET("ModArma", "0") end
    if ARCGET("Versatil", nil) == nil then ARCSET("Versatil", "0") end
    if ARCGET("Offhand", nil) == nil then ARCSET("Offhand", "0") end
	if ARCGET(ResourceCurKey("health"), nil) == nil then ARCSET(ResourceCurKey("health"), "0") end
    if ARCGET(ResourceMaxKey("health"), nil) == nil then ARCSET(ResourceMaxKey("health"), "0") end

    if ARCGET(ResourceCurKey("mana"), nil) == nil then ARCSET(ResourceCurKey("mana"), "0") end
    if ARCGET(ResourceMaxKey("mana"), nil) == nil then ARCSET(ResourceMaxKey("mana"), "0") end

    if ARCGET(ResourceCurKey("temp_health"), nil) == nil then ARCSET(ResourceCurKey("temp_health"), "0") end
    if ARCGET(ResourceMaxKey("temp_health"), nil) == nil then ARCSET(ResourceMaxKey("temp_health"), "0") end

	for _, key in ipairs(ALL_RESOURCE_KEYS) do
		if ARCGET(ResourceCurKey(key), nil) == nil then ARCSET(ResourceCurKey(key), "0") end
		if ARCGET(ResourceMaxKey(key), nil) == nil then ARCSET(ResourceMaxKey(key), "0") end
	end

    for _, a in ipairs(HarfordDnDData.ABIL) do
        if ARCGET(a.key, nil) == nil then ARCSET(a.key, "10") end
        if ARCGET("Salv_" .. a.key, nil) == nil then ARCSET("Salv_" .. a.key, "0") end
    end

    for _, s in ipairs(HarfordDnDData.SKILLS) do
        if ARCGET("Hab_" .. s.id .. "_Prof", nil) == nil then ARCSET("Hab_" .. s.id .. "_Prof", "0") end
        if ARCGET("Hab_" .. s.id .. "_Exp", nil) == nil then ARCSET("Hab_" .. s.id .. "_Exp", "0") end
    end
end

-- HarfordDnDProfile aplica tablas de perfil/recursos; le inyectamos los callbacks
-- de la ficha (defaults + refresh) una vez definidos.
HarfordDnDProfile.SetHooks(EnsureDefaults, RefreshMainUI)

-- GetPB, GetSpellPB, GetMode, GetMiscBonus, GetAbilityScore, GetAbilityMod,
-- GetSaveProf, GetWeaponMod, GetVersatileActive viven en HarfordDnDCalc.

-- true cuando el modo ventaja/desventaja se activó sin shift: se consume tras la próxima tirada.
local _modoTiradaSingleUse = false
-- Forward declaration necesaria: ConsumeMode se define aquí pero RefreshTopInfo se asigna
-- más abajo. Sin esta declaración previa, la referencia dentro de ConsumeMode sería global nil.
local RefreshTopInfo

-- Llamar al final de CADA tirada que lee HarfordDnDCalc.GetMode(). Si el modo era de un solo uso, lo resetea.
local function ConsumeMode()
    if _modoTiradaSingleUse then
        _modoTiradaSingleUse = false
        ARCSET("ModoTirada", "normal")
        if RefreshTopInfo then RefreshTopInfo() end
    end
end
function HarfordDnDGetInitiativeMod() return toN(ARCGET("ModIniciativa", "0"), 0) end

HarfordDnDStore.HasWeaponProp = function(def, name)
    if not def or type(def.props) ~= "table" then return false end
    for _, prop in ipairs(def.props) do
        if tostring(prop or ""):find(name, 1, true) then
            return true
        end
    end
    return false
end

HarfordDnDStore.IsOffhandAvailable = function(def)
    return def ~= nil
        and def.key ~= "Desarmado"
        and def.mode == "Melee"
        and not HarfordDnDCalc.GetVersatileActive()
        and not HarfordDnDStore.HasWeaponProp(def, "Dos manos")
end

HarfordDnDStore.GetOffhandActive = function(def)
    return HarfordDnDStore.IsOffhandAvailable(def) and toN(ARCGET("Offhand", "0"), 0) == 1
end

HarfordDnDStore.AreAnimationsEnabled = function()
    return HarfordDnDStore.animsEnabled ~= false
end

local function GetResourceCurrent(key)
    return toN(ARCGET(ResourceCurKey(key), "0"), 0)
end

local function GetResourceMax(key)
    local base = toN(ARCGET(ResourceMaxKey(key), "0"), 0)
    local bonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetResourceMaxBonus
        and HarfordDnDFeatureEffects.GetResourceMaxBonus(key)
        or 0
    return base + bonus
end

local function SetResourceCurrent(key, value)
    local newValue = math.max(0, toN(value, 0))
    local curKey = ResourceCurKey(key)
    local oldValue = toN(ARCGET(curKey, "0"), 0)

    if oldValue == newValue then
        return
    end

    ARCSET(curKey, newValue)
    ScheduleMyResourceBroadcast()
end

local function IsShiftClickDown()
    return IsShiftKeyDown and IsShiftKeyDown()
end

local function ResourceExists(key)
    return HarfordDnDResources.Exists(key, GetResourceCurrent(key), GetResourceMax(key))
end

-- BuildActiveResourcePayload, ExportCurrentResources, GetRemoteResourceValue,
-- RemoteResourceExists, SendResourceResponseTo, SendResourceResponseForProfileTo,
-- RequestResourcesFromPlayer y SendResourceAdjustToPlayer viven en HarfordDnDNet.

ScheduleMyResourceBroadcast = function()
    if HarfordUnitFrames and HarfordUnitFrames.Refresh then
        HarfordUnitFrames.Refresh()
    end

    if not HarfordSync or not HarfordSync.ScheduleResourceBroadcast then
        return
    end

    HarfordSync.ScheduleResourceBroadcast(
        ADDON_PREFIX,
        function()
            return tostring(HarfordDnDPersistStore.activeProfile or UnitName("player") or "default")
        end,
        function()
            return HarfordDnDNet.BuildActiveResourcePayload(function(key)
                return ARCGET(key, "0")
            end)
        end,
        RESOURCE_RUNTIME_KEYS,
        function()
            return BestChannel()
        end
    )
end

-- GetSkillProfBonus, GetSkillRollBonuses, GetSaveRollBonuses, RollTextWithMode,
-- GetCritTag, BonusConcat viven en HarfordDnDCalc.

local function DoRoll(label, baseBonus, profBonus)
    baseBonus = toN(baseBonus, 0)
    profBonus = toN(profBonus, 0)
    local miscBonus = HarfordDnDCalc.GetMiscBonus()

    local chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full()
    local total = chosen + baseBonus + profBonus + miscBonus
    local bonusTxt = HarfordDnDCalc.BonusConcat(baseBonus, profBonus, miscBonus)

    HarfordDnDRolls.Broadcast({
        type = "roll",
        label = label,
        total = total,
        dice = HarfordDnDCalc.FormatD20Dice(chosen, ra, rb),
        modifiers = bonusTxt,
        critical = critTag,
        mode = modeTag,
        miscBonus = miscBonus,
    })
    ConsumeMode()
    return critTag
end

local function RollWeaponDamage(def, abilKey, maximizeDice)
    if not def or not def.dmgN or not def.dmgS or def.dmgN == 0 or def.dmgS == 0 then
        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = "Daño " .. (def and def.key or "???"),
            total = 0,
            dice = "-",
            modifiers = "",
            critical = "",
            mode = ""
        })
        return 0
    end

    local diceStr = HarfordDnDWeapons.WeaponBaseDice(def)
    local n, sides = HarfordDnDWeapons.ParseDice(diceStr)
    if not n or not sides then
        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = "Daño " .. def.key,
            total = 0,
            dice = "-",
            modifiers = "",
            critical = "",
            mode = ""
        })
        return 0
    end

    local offhand = HarfordDnDStore.GetOffhandActive and HarfordDnDStore.GetOffhandActive(def)
    local abiMod = (def.addAbi and abilKey) and HarfordDnDCalc.GetAbilityMod(abilKey) or 0
    if offhand and abiMod > 0 then
        abiMod = 0
    end
    local wmod = HarfordDnDCalc.GetWeaponDamageBonus and HarfordDnDCalc.GetWeaponDamageBonus() or HarfordDnDCalc.GetWeaponMod()

    local rolls, sum = {}, 0
    for i=1,n do
        local r = maximizeDice and sides or HarfordDnDCalc.RollDie(sides)
        rolls[#rolls+1] = r
        sum = sum + r
    end

    local total = sum + abiMod + wmod
    local rollList = table.concat(rolls, "+")
    local parts = {}
    if abiMod ~= 0 then parts[#parts+1] = fmtSigned(abiMod) end
    if wmod ~= 0 then parts[#parts+1] = fmtSigned(wmod) end
    local bonusTxt = table.concat(parts, "")
    local dtype = def.dmgType or ""

    -- Defensas del objetivo (solo si es NPC): la tirada muestra el dano ya
    -- mitigado y un marcador coloreado R/V/I junto al tipo.
    local marker = ""
    if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
        local applied, _status, mk = HarfordDamageMitigation.ForTarget("target", dtype, total)
        total, marker = applied, mk
    end
    local modifiersTxt = dtype
    if marker ~= "" then modifiersTxt = dtype .. " " .. marker end

    HarfordDnDRolls.Broadcast({
        type = "damage",
        label = (offhand and "Daño Offhand " or "Daño ") .. def.key,
        total = total,
        dice = n .. "d" .. sides .. ": " .. rollList .. bonusTxt,
        modifiers = modifiersTxt,
        critical = maximizeDice and "CRÍTICO" or "",
        mode = ""
    })
    return total
end

local function GetSpellDC()
    local abil = ARCGET("AtributoConjuro", "Carisma")
    local mod = HarfordDnDCalc.GetAbilityMod(abil)
    return 8 + HarfordDnDCalc.GetSpellPB() + mod, abil
end

local function GetSpellAbilityKey()
    local v = ARCGET("AtributoConjuro", "Inteligencia")
    for _, a in ipairs(HarfordDnDData.ABIL) do
        if a.key == v then return v end
    end
    return "Inteligencia"
end

local function SendSpellDC()
    local dc, abil = GetSpellDC()
    local pb = HarfordDnDCalc.GetSpellPB()
    local mod = HarfordDnDCalc.GetAbilityMod(abil)
    local short = ""
    for _, a in ipairs(HarfordDnDData.ABIL) do if a.key == abil then short = a.short break end end
    local parts = {"8"}
    if pb ~= 0 then parts[#parts+1] = fmtSigned(pb) end
    if mod ~= 0 then parts[#parts+1] = fmtSigned(mod) end

    HarfordDnDRolls.Broadcast({
        type = "info",
        label = "CD Conjuro (" .. short .. ")",
        total = dc,
        dice = table.concat(parts, ""),
        modifiers = "",
        critical = "",
        mode = ""
    })
end

local function FormatAbilityButtonText(short, abilityKey)
    local score = HarfordDnDCalc.GetAbilityScore(abilityKey)
    local mod = HarfordDnDCalc.GetAbilityMod(abilityKey)
    return ("%s %d %s"):format(short, score, ColorSigned(mod))
end

local function FormatSaveButtonText(short, abilityKey)
    local base, prof = HarfordDnDCalc.GetSaveRollBonuses(abilityKey)
    local total = base + prof
    return ("Salv %s %s"):format(short, ColorSigned(total))
end

local function FormatSkillButtonText(skill)
    local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)
    local total = base + prof
    return ("%s %s"):format(skill.name, ColorSigned(total))
end

local function MakeSignedEditBox(parent, labelText, xRight, yTop, arcKey, default)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetText(labelText)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(64, 20)
    box:SetPoint("TOPRIGHT", xRight, yTop)
    box:SetAutoFocus(false)

    label:SetPoint("RIGHT", box, "LEFT", -6, 0)
    label:SetJustifyH("RIGHT")

    local function getVal()
        return toN(ARCGET(arcKey, tostring(default or 0)), default or 0)
    end

    local function setBoxFromARC()
        local v = tostring(getVal())
        if v:sub(1,1) ~= "-" and v:sub(1,1) ~= "+" then
            local nv = tonumber(v)
            if nv and nv > 0 then v = "+" .. v end
        end
        box:SetText(v)
    end

    local function commitBox()
        local t = (box:GetText() or ""):gsub("%s+", "")
        if t == "" then t = "0" end
        local n = tonumber(t)
        if not n then
            setBoxFromARC()
            return
        end
        ARCSET(arcKey, n)
        setBoxFromARC()
    end

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        commitBox()
    end)

    box:SetScript("OnEditFocusLost", function()
        commitBox()
    end)

    setBoxFromARC()
    return label, box, setBoxFromARC, commitBox
end

local armorClassBoxSetters = {}

local function GetActiveArmorClassUnit()
    if SheetContext.active and SheetContext.kind == "npc"
        and UnitExists and UnitExists("focus") then
        return "focus"
    end
    if UnitExists and UnitExists("target") then
        return "target"
    end
    return nil
end

local function GetArmorClassValue()
    local unit = GetActiveArmorClassUnit()
    if unit and HarfordDnDCombat and HarfordDnDCombat.GetArmorClassForUnit then
        local unitArmorClass = HarfordDnDCombat.GetArmorClassForUnit(unit)
        if unitArmorClass then
            return unitArmorClass
        end
        if unit == "focus" then
            return 0
        end
    end
    if SheetContext.active and SheetContext.kind == "npc" and SheetContext.armorClass ~= nil then
        return toN(SheetContext.armorClass, 0)
    end
    return toN(ARCGET("ArmorClass", "10"), 10)
end

local function SetArmorClassValue(value)
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then n = 0 end

    local unit = GetActiveArmorClassUnit()
    if unit and HarfordDnDCombat and HarfordDnDCombat.SetArmorClassForUnit then
        local ok = HarfordDnDCombat.SetArmorClassForUnit(unit, n)
        if ok and UnitIsUnit and UnitIsUnit(unit, "player") then
            ScheduleMyResourceBroadcast()
        end
        return
    end

    if SheetContext.active and SheetContext.kind == "npc" then
        SheetContext.armorClass = n
        if SheetContext.onArmorClassChanged then
            SheetContext.onArmorClassChanged(n, SheetContext.npcSourceGuid)
        end
    else
        ARCSET("ArmorClass", n)
        ScheduleMyResourceBroadcast()
    end
end

local function RefreshArmorClassBoxes()
    local text = tostring(GetArmorClassValue())
    for _, setter in ipairs(armorClassBoxSetters) do
        setter(text)
    end
end

local function MakeArmorClassEditBox(parent, xRight, yTop)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetText("CA:")

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(44, 20)
    box:SetPoint("TOPRIGHT", xRight, yTop)
    box:SetAutoFocus(false)
    box:SetNumeric(true)

    label:SetPoint("RIGHT", box, "LEFT", -6, 0)
    label:SetJustifyH("RIGHT")

    local function setText(text)
        box:SetText(tostring(text or GetArmorClassValue()))
    end

    local function commitBox()
        SetArmorClassValue(box:GetText())
        RefreshArmorClassBoxes()
    end

    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        commitBox()
    end)
    box:SetScript("OnEditFocusLost", commitBox)

    armorClassBoxSetters[#armorClassBoxSetters + 1] = setText
    setText()
    return label, box, setText
end

local function EnsureTargetResourceFrameState()
    HarfordDnDTargetResourceSettings = HarfordDnDTargetResourceSettings or {}
end

local function SaveTargetResourceFramePosition(frame)
    if not frame then return end
    EnsureTargetResourceFrameState()

    local ui = UIParent
    local frameScale = frame:GetEffectiveScale() or 1
    local uiScale = ui:GetEffectiveScale() or 1

    local fx, fy = frame:GetCenter()
    local ux, uy = ui:GetCenter()

    if not fx or not fy or not ux or not uy then
        return
    end

    local x = (fx * frameScale - ux * uiScale) / uiScale
    local y = (fy * frameScale - uy * uiScale) / uiScale

    HarfordDnDTargetResourceSettings.userPlaced = true
    HarfordDnDTargetResourceSettings.point = "CENTER"
    HarfordDnDTargetResourceSettings.relativePoint = "CENTER"
    HarfordDnDTargetResourceSettings.x = x
    HarfordDnDTargetResourceSettings.y = y
end

local function RestoreTargetResourceFramePosition(frame)
    if not frame then return false end
    EnsureTargetResourceFrameState()

    if not HarfordDnDTargetResourceSettings.userPlaced then
        return false
    end

    local x = tonumber(HarfordDnDTargetResourceSettings.x)
    local y = tonumber(HarfordDnDTargetResourceSettings.y)
    if not x or not y then
        return false
    end

    local point = HarfordDnDTargetResourceSettings.point or "CENTER"
    local relativePoint = HarfordDnDTargetResourceSettings.relativePoint or "CENTER"

    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relativePoint, x, y)
    frame.isUserPlaced = true
    return true
end

local function ResetTargetResourceFramePosition()
    EnsureTargetResourceFrameState()
    HarfordDnDTargetResourceSettings.userPlaced = false
    HarfordDnDTargetResourceSettings.point = nil
    HarfordDnDTargetResourceSettings.relativePoint = nil
    HarfordDnDTargetResourceSettings.x = nil
    HarfordDnDTargetResourceSettings.y = nil
    TargetResourceFrame.isUserPlaced = false
    AnchorTargetResourceFrame()
end

local function ResetAllFramePositions()
    if F then
        F:StopMovingOrSizing()
        F:ClearAllPoints()
        F:SetPoint("CENTER", UIParent, "CENTER", HarfordDnDUI.LAYOUT.FRAME_X, HarfordDnDUI.LAYOUT.FRAME_Y)
    end

    if ResourceFrame and F then
        ResourceFrame:StopMovingOrSizing()
        ResourceFrame:ClearAllPoints()
        ResourceFrame:SetPoint("TOPLEFT", F, "TOPRIGHT", 8, 0)
    end

    if TargetResourceFrame then
        TargetResourceFrame:StopMovingOrSizing()
        ResetTargetResourceFramePosition()
    end
end

-- El boton de minimapa vive en HarfordDnDMinimap. Registramos el handler de
-- reinicio de posiciones (click derecho), que sigue siendo logica de esta ficha.
HarfordDnDMinimap.SetResetHandler(ResetAllFramePositions)


do
local initialProfile = UnitName("player") or "default"
HarfordDnDStore.LoadPersistToRuntime(initialProfile)

F = CreateFrame("Frame", "DND5E_PlayerFrame", UIParent, "BackdropTemplate")
F:SetSize(HarfordDnDUI.LAYOUT.FRAME_W, HarfordDnDUI.LAYOUT.FRAME_H)
F:SetPoint("CENTER", UIParent, "CENTER", HarfordDnDUI.LAYOUT.FRAME_X, HarfordDnDUI.LAYOUT.FRAME_Y)
F:SetMovable(true)
F:EnableMouse(true)
F:RegisterForDrag("LeftButton")
F:SetScript("OnDragStart", F.StartMoving)
F:SetScript("OnDragStop", F.StopMovingOrSizing)
F:SetFrameStrata("DIALOG")
F:SetFrameLevel(100)
F:Hide()

HarfordDnDUI.SetFrameBackground(F, HarfordDnDUI.TEX.MARBLE, 0.95)

local mainBorder = CreateFrame("Frame", nil, F, "DialogBorderTemplate")
mainBorder:SetAllPoints(F)
mainBorder:SetFrameStrata(F:GetFrameStrata())
mainBorder:SetFrameLevel(F:GetFrameLevel() + 5)

FrameTitle = F:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
FrameTitle:SetPoint("TOP", 0, -15)
FrameTitle:SetText("Harford DnD 5ª - Ficha")

local restButton = CreateFrame("Button", nil, F)
restButton:SetSize(20, 20)
restButton:SetPoint("TOPLEFT", 18, -15)

local titleIcon = restButton:CreateTexture(nil, "ARTWORK")
titleIcon:SetAllPoints()
titleIcon:SetTexture(HarfordDnDUI.TEX.CAMPFIRE)
titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

HarfordDnDTurnButton = CreateFrame("Button", nil, F)
HarfordDnDTurnButton:SetSize(20, 20)
HarfordDnDTurnButton:SetPoint("LEFT", restButton, "RIGHT", 5, 0)

HarfordDnDTurnIcon = HarfordDnDTurnButton:CreateTexture(nil, "ARTWORK")
HarfordDnDTurnIcon:SetAllPoints()
HarfordDnDTurnIcon:SetTexture(HarfordDnDUI.TEX.HOURGLASS)
HarfordDnDTurnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local RestMenu = CreateFrame("Frame", "HarfordDnDRestMenu", F, "BackdropTemplate")
RestMenu:SetSize(150, 70)
RestMenu:SetPoint("TOPLEFT", F, "TOPLEFT", 12, -38)
RestMenu:SetFrameStrata("DIALOG")
RestMenu:SetFrameLevel(F:GetFrameLevel() + 30)
RestMenu:Hide()

HarfordDnDUI.SetFrameBackground(RestMenu, HarfordDnDUI.TEX.MARBLE, 0.96)

local restBorder = CreateFrame("Frame", nil, RestMenu, "DialogBorderTemplate")
restBorder:SetAllPoints(RestMenu)
restBorder:SetFrameStrata(RestMenu:GetFrameStrata())
restBorder:SetFrameLevel(RestMenu:GetFrameLevel() + 5)

local shortRestBtn = HarfordDnDUI.MakeButton(RestMenu, "Descanso corto", 120, 22, 15, -12, function()
    RestMenu:Hide()
    ApplyShortRest()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HarfordDnD]|r Descanso corto")
end)

local longRestBtn = HarfordDnDUI.MakeButton(RestMenu, "Descanso largo", 120, 22, 15, -38, function()
    RestMenu:Hide()
    ApplyLongRest()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HarfordDnD]|r Descanso largo")
end)

restButton:SetScript("OnClick", function()
    if RestMenu:IsShown() then
        RestMenu:Hide()
    else
        RestMenu:Show()
        RestMenu:Raise()
    end
end)

restButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Descanso", 1, 0.82, 0)
    GameTooltip:AddLine("Click: elegir descanso corto o largo", 1, 1, 1)
    GameTooltip:Show()
end)

restButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

HarfordDnDTurnButton:SetScript("OnClick", function()
    if HarfordTurnOrderAPI and HarfordTurnOrderAPI.Toggle then
        HarfordTurnOrderAPI.Toggle()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[HarfordDnD]|r La ventana de turnos aun no esta disponible.")
    end
end)

HarfordDnDTurnButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Turnos", 1, 0.82, 0)
    GameTooltip:AddLine("Click: abrir o cerrar la ventana de turnos", 1, 1, 1)
    GameTooltip:Show()
end)

HarfordDnDTurnButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

F:HookScript("OnHide", function()
    if RestMenu and RestMenu:IsShown() then
        RestMenu:Hide()
    end
end)

local close = CreateFrame("Button", nil, F, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -6, -4)

-- Icono de reputacion: a la izquierda del boton cerrar
do
    local repBtn = CreateFrame("Button", nil, F)
    repBtn:SetSize(20, 20)
    repBtn:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, -11)

    local repIcon = repBtn:CreateTexture(nil, "ARTWORK")
    repIcon:SetAllPoints()
    repIcon:SetTexture("Interface\\Icons\\INV_Shirt_GuildTabard_01")
    repIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local repHL = repBtn:CreateTexture(nil, "HIGHLIGHT")
    repHL:SetAllPoints()
    repHL:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    repHL:SetBlendMode("ADD")

    repBtn:SetScript("OnClick", function()
        if HarfordCharacterPanel and HarfordCharacterPanel.Toggle then
            HarfordCharacterPanel.Toggle("sheet")
        elseif HarfordReputationUI and HarfordReputationUI.Toggle then
            HarfordReputationUI.Toggle()
        end
    end)
    repBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Personaje", 1, 0.82, 0)
        GameTooltip:AddLine("Abre el panel de personaje.", 1, 1, 1)
        GameTooltip:AddLine("Ficha, creacion, subida y acceso a reputacion.", 1, 1, 1)
        GameTooltip:AddLine("/harfordchar - acceso directo", 0.7, 0.9, 0.7)
        GameTooltip:Show()
    end)
    repBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

ResourceFrame = CreateFrame("Frame", "HarfordDnDResourceFrame", UIParent, "BackdropTemplate")
ResourceFrame:SetSize(250, 280)
ResourceFrame:SetPoint("TOPLEFT", F, "TOPRIGHT", 8, 0)
ResourceFrame:SetMovable(true)
ResourceFrame:EnableMouse(true)
ResourceFrame:RegisterForDrag("LeftButton")
ResourceFrame:SetScript("OnDragStart", ResourceFrame.StartMoving)
ResourceFrame:SetScript("OnDragStop", ResourceFrame.StopMovingOrSizing)
ResourceFrame:SetFrameStrata("DIALOG")
ResourceFrame:SetFrameLevel(F:GetFrameLevel() + 20)
ResourceFrame:Hide()

HarfordDnDUI.SetFrameBackground(ResourceFrame, HarfordDnDUI.TEX.MARBLE, 0.95)

local resourceBorder = CreateFrame("Frame", nil, ResourceFrame, "DialogBorderTemplate")
resourceBorder:SetAllPoints(ResourceFrame)
resourceBorder:SetFrameStrata(ResourceFrame:GetFrameStrata())
resourceBorder:SetFrameLevel(ResourceFrame:GetFrameLevel() + 5)

local resourceTitle = ResourceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
resourceTitle:SetPoint("TOP", 0, -15)
resourceTitle:SetText("Recursos")

local resourceClose = CreateFrame("Button", nil, ResourceFrame, "UIPanelCloseButton")
resourceClose:SetPoint("TOPRIGHT", -6, -4)

ResourceFrame.rows = {}

TargetResourceFrame = CreateFrame("Frame", "HarfordDnDTargetResourceFrame", UIParent, "BackdropTemplate")
TargetResourceFrame:SetSize(200, 80)
TargetResourceFrame:SetFrameStrata("MEDIUM")
TargetResourceFrame:SetFrameLevel(30)
TargetResourceFrame:SetMovable(true)
TargetResourceFrame:EnableMouse(true)
TargetResourceFrame:RegisterForDrag("LeftButton")
TargetResourceFrame:SetClampedToScreen(true)
TargetResourceFrame:Hide()

TargetResourceFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

TargetResourceFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self.isUserPlaced = true
    SaveTargetResourceFramePosition(self)
end)

HarfordDnDUI.SetFrameBackground(TargetResourceFrame, HarfordDnDUI.TEX.MARBLE, 0.92)

local targetResourceBorder = CreateFrame("Frame", nil, TargetResourceFrame, "DialogBorderTemplate")
targetResourceBorder:SetAllPoints(TargetResourceFrame)
targetResourceBorder:SetFrameStrata(TargetResourceFrame:GetFrameStrata())
targetResourceBorder:SetFrameLevel(TargetResourceFrame:GetFrameLevel() + 5)

TargetResourceFrame.rows = {}
end

local function CreateResourceRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(218, 24)
    row:SetPoint("TOPLEFT", 16, -(38 + (index - 1) * 26))

    row.minus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.minus:SetSize(20, 20)
    row.minus:SetPoint("LEFT", 0, 0)
    row.minus:SetText("-")

    row.plus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.plus:SetSize(20, 20)
    row.plus:SetPoint("RIGHT", 0, 0)
    row.plus:SetText("+")

    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("TOPLEFT", row.minus, "TOPRIGHT", 4, 0)
    row.bar:SetPoint("BOTTOMRIGHT", row.plus, "BOTTOMLEFT", -4, 0)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(0)
	
	row.tempFill = row.bar:CreateTexture(nil, "OVERLAY")
	row.tempFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.tempFill:SetPoint("TOPLEFT", row.bar, "TOPLEFT", 0, 0)
	row.tempFill:SetPoint("BOTTOMLEFT", row.bar, "BOTTOMLEFT", 0, 0)
	row.tempFill:SetWidth(0)
	row.tempFill:SetVertexColor(0.45, 0.75, 1.00, 0.95)
	row.tempFill:Hide()

    row.bg = row.bar:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(HarfordDnDUI.TEX.WHITE)
    row.bg:SetVertexColor(0.08, 0.08, 0.08, 0.95)

    row.border = row.bar:CreateTexture(nil, "BORDER")
    row.border:SetAllPoints()
    row.border:SetTexture(HarfordDnDUI.TEX.WHITE)
    row.border:SetVertexColor(0.30, 0.30, 0.30, 0.85)

    row.label = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", 6, 0)
    row.label:SetJustifyH("LEFT")

    row.value = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", -6, 0)
    row.value:SetJustifyH("RIGHT")

    return row
end

local function CreateTargetResourceRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(170, 16)
    row:SetPoint("TOPLEFT", 15, -(12 + (index - 1) * 18))

    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetAllPoints()
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(0)
	
	row.tempFill = row.bar:CreateTexture(nil, "OVERLAY")
	row.tempFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.tempFill:SetPoint("TOPLEFT", row.bar, "TOPLEFT", 0, 0)
	row.tempFill:SetPoint("BOTTOMLEFT", row.bar, "BOTTOMLEFT", 0, 0)
	row.tempFill:SetWidth(0)
	row.tempFill:SetVertexColor(0.45, 0.75, 1.00, 0.95)
	row.tempFill:Hide()

    row.bg = row.bar:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(HarfordDnDUI.TEX.WHITE)
    row.bg:SetVertexColor(0.08, 0.08, 0.08, 0.95)

    row.border = row.bar:CreateTexture(nil, "BORDER")
    row.border:SetAllPoints()
    row.border:SetTexture(HarfordDnDUI.TEX.WHITE)
    row.border:SetVertexColor(0.28, 0.28, 0.28, 0.80)

    row.label = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetJustifyH("LEFT")

    row.value = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", -4, 0)
    row.value:SetJustifyH("RIGHT")

    return row
end

AnchorTargetResourceFrame = function()
    if not TargetFrame or not TargetFrame:IsShown() then
        TargetResourceFrame:Hide()
        return
    end

    if RestoreTargetResourceFramePosition(TargetResourceFrame) then
        return
    end

    TargetResourceFrame:ClearAllPoints()

    local offsetY = -34
    if TargetFrameToT and TargetFrameToT:IsShown() then
        offsetY = -52
    end

    TargetResourceFrame:SetPoint("TOP", TargetFrame, "BOTTOM", 0, offsetY)
end

local function AdjustResourceCurrent(key, delta)
    local cur = GetResourceCurrent(key)
    local max = GetResourceMax(key)

    cur = cur + toN(delta, 0)

    if cur < 0 then
        cur = 0
    end

    if key ~= "temp_health" then
        if max < 0 then max = 0 end
        if cur > max then
            cur = max
        end
    end

    SetResourceCurrent(key, cur)

    if key == "health" then
        if cur <= 0 and not HarfordDnDStore.deathAuraActive then
            -- Salud llega a 0: si el jugador tiene animaciones activas, aplicar aura de muerte.
            if HarfordDnDStore.animsEnabled ~= false and HarfordAuras then
                local ok = HarfordAuras.Apply("death")
                if ok then HarfordDnDStore.deathAuraActive = true end
            end
        elseif cur > 0 and (HarfordDnDStore.deathAuraActive
            or (HarfordDnDStore.deathSaveActive and HarfordDnDStore.animsEnabled ~= false)) then
            -- Al levantarse del estado moribundo, la retirada es autoritativa aunque
            -- se haya perdido la marca local de la aura durante un reload/sync.
            HarfordDnDStore.deathAuraActive = false
            if HarfordAuras then HarfordAuras.Remove("death") end
        end

        -- Notificar al sistema de moribundo.
        if RefreshDyingState then RefreshDyingState() end
    end

    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then
        RefreshResourceFrame()
    end

    return cur
end

-- Aplica daño al PROPIO jugador en local (temp_health primero, luego health). Lo usa
-- el ataque NPC cuando el focus victima es uno mismo (el DM ataca a su propio PJ).
HarfordDnDStore.ApplyLocalResourceDamage = function(total)
    total = tonumber(total) or 0
    if total <= 0 then return end
    local tempCur = math.max(0, GetResourceCurrent("temp_health"))
    local tempDmg = math.min(total, tempCur)
    local healthDmg = total - tempDmg
    if tempDmg > 0 then AdjustResourceCurrent("temp_health", -tempDmg) end
    if healthDmg > 0 then AdjustResourceCurrent("health", -healthDmg) end
end

local function ApplyResourceDeltaFromRemote(resourceKey, delta, sender)
    resourceKey = tostring(resourceKey or "")
    delta = tonumber(delta) or 0
    if resourceKey == "" or delta == 0 then return false end

    -- Clave corta legacy → ajusta _Cur
    -- Clave completa "Res_X_Cur" / "Res_X_Max" → ajusta esa clave directamente (editor admin)
    local baseKey, isMax
    if resourceKey == "health" or resourceKey == "temp_health" then
        baseKey = resourceKey
    else
        local b = resourceKey:match("^Res_(.+)_Cur$")
        if b then baseKey = b end
        b = resourceKey:match("^Res_(.+)_Max$")
        if b then baseKey, isMax = b, true end
    end

    local defs = HarfordDnDResources and HarfordDnDResources.DEFS
    if not baseKey or not defs or not defs[baseKey] then return false end

    if isMax then
        local maxKey = ResourceMaxKey(baseKey)
        local newMax = math.max(0, toN(ARCGET(maxKey, "0"), 0) + delta)
        ARCSET(maxKey, newMax)
        ScheduleMyResourceBroadcast()
    else
        AdjustResourceCurrent(baseKey, delta)
    end

    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then
        RefreshResourceFrame()
    end
    if RefreshTargetResourceFrame then
        RefreshTargetResourceFrame()
    end
    if sender and sender ~= "" then
        HarfordDnDNet.SendResourceResponseTo(sender)
    end
    return true
end

ApplyShortRest = function()
    local healthMax = GetResourceMax("health")
    local healthCur = GetResourceCurrent("health")
    local healthRecover = math.floor(healthMax / 2)

    local newHealth = healthCur + healthRecover
    if newHealth > healthMax then
        newHealth = healthMax
    end
    SetResourceCurrent("health", newHealth)

    for _, key in ipairs(RESOURCE_ORDER) do
        if key ~= "mana" and key ~= "health" then
            local maxValue = GetResourceMax(key)
            SetResourceCurrent(key, maxValue)
        end
    end

    if GetResourceCurrent("health") > healthMax then
        SetResourceCurrent("health", healthMax)
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
    local healthMax = GetResourceMax("health")
    SetResourceCurrent("health", healthMax)

    for _, key in ipairs(RESOURCE_ORDER) do
        local maxValue = GetResourceMax(key)
        SetResourceCurrent(key, maxValue)
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

local function AttachResourceButtonTooltip(button, key, delta)
    if not button then return end

    button:SetScript("OnEnter", function(self)
        local def = RESOURCE_DEFS[key]
        local label = (def and def.label) or key
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText((delta and delta > 0 and "Añadir " or "Quitar ") .. label, 1, 0.82, 0)
        GameTooltip:AddLine("Click: modifica " .. label, 1, 1, 1)
        if key == "health" then
            GameTooltip:AddLine("Shift + Click: modifica Vida temporal", 0.75, 0.9, 1)
        end
        GameTooltip:AddLine("Ctrl + Click: cantidad personalizada", 0.75, 0.9, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Prompt de Ctrl+click en los botones del frame de recursos: pide una cantidad y
-- la suma (boton +) o resta (boton -) al recurso. Registrado una sola vez.
if not StaticPopupDialogs["HARFORD_RESOURCE_ADJUST"] then
    StaticPopupDialogs["HARFORD_RESOURCE_ADJUST"] = {
        text = "Cantidad a %s en %s:",
        button1 = ACCEPT or "Aceptar",
        button2 = CANCEL or "Cancelar",
        hasEditBox = true,
        maxLetters = 6,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local data = self.data or {}
            local amount = math.abs(math.floor(tonumber(self.editBox:GetText()) or 0))
            if amount == 0 or not data.key then return end
            AdjustResourceCurrent(data.key, (data.sign or 1) * amount)
            if RefreshResourceFrame then RefreshResourceFrame() end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            StaticPopupDialogs["HARFORD_RESOURCE_ADJUST"].OnAccept(parent)
            parent:Hide()
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    }
end

local function PromptResourceAdjust(key, sign)
    local def = RESOURCE_DEFS[key]
    local label = (def and def.label) or key
    local dialog = StaticPopup_Show("HARFORD_RESOURCE_ADJUST", sign < 0 and "restar" or "sumar", label)
    if dialog then dialog.data = { key = key, sign = sign } end
end

local function UpdateResourceRow(row, key)
    if not row or not key then return end

    local def = RESOURCE_DEFS[key]
    if not def then return end

    local cur = GetResourceCurrent(key)
    local max = GetResourceMax(key)

    if key == "temp_health" then
        max = math.max(cur, max, 1)
    else
        max = math.max(max, 1)
        if cur > max then cur = max end
    end

    row.key = key
    row.label:SetText(def.label)
    if key == "health" then
    local temp = GetResourceCurrent("temp_health")
		if temp > 0 then
			row.value:SetText(tostring(cur) .. " (+" .. tostring(temp) .. ") / " .. tostring(max))
		else
			row.value:SetText(tostring(cur) .. " / " .. tostring(max))
		end
	else
		row.value:SetText(tostring(cur) .. " / " .. tostring(max))
	end

    row.bar:SetStatusBarColor(def.color[1], def.color[2], def.color[3], 1)
    row.bar:SetMinMaxValues(0, max)
    row.bar:SetValue(cur)
	
	if key == "health" and row.tempFill then
    local temp = GetResourceCurrent("temp_health")
    local barWidth = row.bar:GetWidth() or 0

    if temp > 0 and max > 0 and barWidth > 0 then
        local tempWidth = math.floor(barWidth * (temp / max))

        if tempWidth < 0 then tempWidth = 0 end
        if tempWidth > barWidth then tempWidth = barWidth end

        row.tempFill:ClearAllPoints()
        row.tempFill:SetPoint("TOPLEFT", row.bar, "TOPLEFT", 0, 0)
        row.tempFill:SetPoint("BOTTOMLEFT", row.bar, "BOTTOMLEFT", 0, 0)
        row.tempFill:SetWidth(tempWidth)
        row.tempFill:SetVertexColor(0.45, 0.75, 1.00, 0.95)
        row.tempFill:Show()
    else
        row.tempFill:SetWidth(0)
        row.tempFill:Hide()
    end
	elseif row.tempFill then
		row.tempFill:SetWidth(0)
		row.tempFill:Hide()
	end

    row:Show()
end

RefreshResourceFrame = function()
    local visibleIndex = 0

    for _, key in ipairs(RESOURCE_ORDER) do
        if ResourceExists(key) then
            visibleIndex = visibleIndex + 1

            local row = ResourceFrame.rows[visibleIndex]
            if not row then
                row = CreateResourceRow(ResourceFrame, visibleIndex)
                ResourceFrame.rows[visibleIndex] = row
            end

            UpdateResourceRow(row, key)

            row.minus:SetScript("OnClick", function()
			local targetKey = key

				if key == "health" and IsShiftClickDown() then
					targetKey = "temp_health"
				end

				if IsControlKeyDown and IsControlKeyDown() then
					PromptResourceAdjust(targetKey, -1)
					return
				end

				AdjustResourceCurrent(targetKey, -1)
				UpdateResourceRow(row, key)
				RefreshResourceFrame()
			end)

			row.plus:SetScript("OnClick", function()
				local targetKey = key

				if key == "health" and IsShiftClickDown() then
					targetKey = "temp_health"
				end

				if IsControlKeyDown and IsControlKeyDown() then
					PromptResourceAdjust(targetKey, 1)
					return
				end

				AdjustResourceCurrent(targetKey, 1)
				UpdateResourceRow(row, key)
				RefreshResourceFrame()
			end)

			AttachResourceButtonTooltip(row.minus, key, -1)
			AttachResourceButtonTooltip(row.plus, key, 1)

            row:Show()
        end
    end

    for i = visibleIndex + 1, #ResourceFrame.rows do
        ResourceFrame.rows[i]:Hide()
    end

    local h = math.max(100, 52 + visibleIndex * 26)
    ResourceFrame:SetHeight(h)
end

RefreshTargetResourceFrame = function()
    if HarfordConfig and HarfordConfig.Get("resources") ~= "frame" then
        TargetResourceFrame:Hide()
        return
    end

    if not UnitExists("target") or not UnitIsPlayer("target") then
        TargetResourceFrame:Hide()
        return
    end

    local targetName = GetUnitName and GetUnitName("target", true)
    if not targetName or targetName == "" then
        targetName = UnitName("target")
    end

    if not targetName or targetName == "" then
        TargetResourceFrame:Hide()
        return
    end

    local myName = GetUnitName and GetUnitName("player", true)
    if not myName or myName == "" then
        myName = UnitName("player")
    end

    local tbl
    if targetName == myName then
        tbl = HarfordDnDNet.ExportCurrentResources()
    else
        tbl = HarfordDnDResources.RemoteCache and HarfordDnDResources.RemoteCache[targetName]

        if not tbl then
            local shortTarget = UnitName("target")
            if shortTarget and shortTarget ~= "" then
                tbl = HarfordDnDResources.RemoteCache and HarfordDnDResources.RemoteCache[shortTarget]
            end
        end
    end

    AnchorTargetResourceFrame()
    TargetResourceFrame:SetWidth(200)
    local visibleIndex = 0

    for _, key in ipairs(RESOURCE_ORDER) do
        if HarfordDnDNet.RemoteResourceExists(tbl, key) then
            visibleIndex = visibleIndex + 1

            local def = RESOURCE_DEFS[key]
            local cur = HarfordDnDNet.GetRemoteResourceValue(tbl, ResourceCurKey(key))
            local max = HarfordDnDNet.GetRemoteResourceValue(tbl, ResourceMaxKey(key))

            if key == "temp_health" then
                max = math.max(cur, max, 1)
            else
                max = math.max(max, 1)
                if cur > max then cur = max end
            end

            local row = TargetResourceFrame.rows[visibleIndex]
            if not row then
                row = CreateTargetResourceRow(TargetResourceFrame, visibleIndex)
                TargetResourceFrame.rows[visibleIndex] = row
            end

            if key == "health" and row.tempFill then
                local temp = HarfordDnDNet.GetRemoteResourceValue(tbl, ResourceCurKey("temp_health"))
                local barWidth = row.bar:GetWidth() or 0
                if temp > 0 and max > 0 and barWidth > 0 then
                    local tempWidth = math.min(math.max(math.floor(barWidth * (temp / max)), 0), barWidth)
                    row.tempFill:ClearAllPoints()
                    row.tempFill:SetPoint("TOPLEFT", row.bar, "TOPLEFT", 0, 0)
                    row.tempFill:SetPoint("BOTTOMLEFT", row.bar, "BOTTOMLEFT", 0, 0)
                    row.tempFill:SetWidth(tempWidth)
                    row.tempFill:SetVertexColor(0.45, 0.75, 1.00, 0.95)
                    row.tempFill:Show()
                else
                    row.tempFill:SetWidth(0)
                    row.tempFill:Hide()
                end
            elseif row.tempFill then
                row.tempFill:SetWidth(0)
                row.tempFill:Hide()
            end

            row.label:SetText(def.label)
            if key == "health" then
                local temp = HarfordDnDNet.GetRemoteResourceValue(tbl, ResourceCurKey("temp_health"))
                row.value:SetText(temp > 0
                    and (tostring(cur) .. " (+" .. tostring(temp) .. ")/" .. tostring(max))
                    or  (tostring(cur) .. "/" .. tostring(max)))
            else
                row.value:SetText(tostring(cur) .. "/" .. tostring(max))
            end
            row.bar:SetMinMaxValues(0, max)
            row.bar:SetStatusBarColor(def.color[1], def.color[2], def.color[3], 1)
            row.bar:SetValue(cur)
            row.bar:Show()
            row:Show()
        end
    end

    for i = visibleIndex + 1, #TargetResourceFrame.rows do
        TargetResourceFrame.rows[i]:Hide()
    end

    if visibleIndex == 0 then
        TargetResourceFrame:Hide()
        return
    end

    TargetResourceFrame:SetHeight(20 + visibleIndex * 18)
    TargetResourceFrame:Show()
end

local function CreateSections(frame)
    local secs = {}
    secs.TOP = HarfordDnDUI.CreateSection(frame, "Bonificadores", HarfordDnDUI.TEX.QMARK, HarfordDnDUI.LAYOUT.SEC_X, HarfordDnDUI.LAYOUT.TOP_Y, HarfordDnDUI.LAYOUT.SEC_W, HarfordDnDUI.LAYOUT.TOP_H, HarfordDnDUI.SECTION_TEX.TOP, 0.95)
    secs.ABI = HarfordDnDUI.CreateSection(frame, "Características", HarfordDnDUI.TEX.STR, 0, 0, HarfordDnDUI.LAYOUT.SEC_W, 92, HarfordDnDUI.SECTION_TEX.ABI, 0.92)
    secs.SAV = HarfordDnDUI.CreateSection(frame, "Salvaciones", HarfordDnDUI.TEX.SHIELD, 0, 0, HarfordDnDUI.LAYOUT.SEC_W, 92, HarfordDnDUI.SECTION_TEX.SAV, 0.86)
    secs.ATK = HarfordDnDUI.CreateSection(frame, "Ataque", HarfordDnDUI.TEX.ATK, 0, 0, HarfordDnDUI.LAYOUT.SEC_W, HarfordDnDUI.LAYOUT.PANEL_H, HarfordDnDUI.SECTION_TEX.ATK, 0.92)
    secs.SKL = HarfordDnDUI.CreateSection(frame, "Habilidades", HarfordDnDUI.TEX.EYE, 0, 0, HarfordDnDUI.LAYOUT.SEC_W, HarfordDnDUI.LAYOUT.PANEL_H, HarfordDnDUI.SECTION_TEX.SKL, 0.90)
    return secs
end

local SEC = CreateSections(F)
local SEC_TOP, SEC_ABI, SEC_SAV, SEC_ATK, SEC_SKL = SEC.TOP, SEC.ABI, SEC.SAV, SEC.ATK, SEC.SKL
local TabBar = CreateFrame("Frame", nil, F)
TabBar:SetPoint("TOPLEFT", F, "TOPLEFT", HarfordDnDUI.LAYOUT.SEC_X, HarfordDnDUI.LAYOUT.TAB_Y)
TabBar:SetSize(HarfordDnDUI.LAYOUT.SEC_W, HarfordDnDUI.LAYOUT.TAB_H)
TabBar:SetFrameStrata(F:GetFrameStrata())
TabBar:SetFrameLevel(F:GetFrameLevel() + 10)

local TabPanel = CreateFrame("Frame", nil, F)
TabPanel:SetPoint("TOPLEFT", F, "TOPLEFT", HarfordDnDUI.LAYOUT.SEC_X, HarfordDnDUI.LAYOUT.PANEL_Y)
TabPanel:SetSize(HarfordDnDUI.LAYOUT.SEC_W, HarfordDnDUI.LAYOUT.PANEL_H)
TabPanel:SetFrameStrata(F:GetFrameStrata())
TabPanel:SetFrameLevel(F:GetFrameLevel() + 1)

local BasePanel = CreateFrame("Frame", nil, TabPanel)
BasePanel:SetAllPoints(TabPanel)

SEC_ABI:SetParent(BasePanel)
SEC_SAV:SetParent(BasePanel)
SEC_ATK:SetParent(TabPanel)
SEC_SKL:SetParent(TabPanel)

SEC_ABI:ClearAllPoints()
SEC_SAV:ClearAllPoints()
SEC_ATK:ClearAllPoints()
SEC_SKL:ClearAllPoints()

SEC_ABI:SetPoint("TOPLEFT", BasePanel, "TOPLEFT", 0, 0)
SEC_SAV:SetPoint("TOPLEFT", BasePanel, "TOPLEFT", 0, -92)

SEC_ATK:SetPoint("TOPLEFT", TabPanel, "TOPLEFT", 0, 0)
SEC_SKL:SetPoint("TOPLEFT", TabPanel, "TOPLEFT", 0, 0)

local TabSections = {
    BASE = BasePanel,
    ATK = SEC_ATK,
    SKL = SEC_SKL,
}

local TabButtons = {}
local ActiveTab = "BASE"

local function ShowDnDTab(tabKey)
    ActiveTab = tabKey

    for key, section in pairs(TabSections) do
        section:SetShown(key == tabKey)
    end

    for key, button in pairs(TabButtons) do
        if key == tabKey then
            button:Disable()
            button:GetFontString():SetTextColor(1, 0.82, 0)
        else
            button:Enable()
            button:GetFontString():SetTextColor(1, 1, 1)
        end
    end

    if RefreshSkillLayout and tabKey == "SKL" then
        RefreshSkillLayout()
    end
end

local function CreateTabButton(parent, key, text, x, w)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    b:SetPoint("TOPLEFT", x, 0)
    b:SetText(text)
    b:SetScript("OnClick", function()
        ShowDnDTab(key)
    end)
    TabButtons[key] = b
    return b
end

local TAB_W        = 118
local TAB_GAP      = 6
local TOTAL_TABS_W = TAB_W * 3 + TAB_GAP * 2
local TAB_START_X  = math.floor((HarfordDnDUI.LAYOUT.SEC_W - TOTAL_TABS_W) / 2)

CreateTabButton(TabBar, "BASE", "Características", TAB_START_X, TAB_W)
CreateTabButton(TabBar, "ATK", "Ataque", TAB_START_X + (TAB_W + TAB_GAP), TAB_W)
CreateTabButton(TabBar, "SKL", "Habilidades", TAB_START_X + (TAB_W + TAB_GAP) * 2, TAB_W)
if TabButtons["BASE"] then TabButtons["BASE"]:SetText("Caracteristicas") end


local AbilityButtons, SaveButtons, SkillButtons = {}, {}, {}
local modeLabel = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
modeLabel:SetPoint("TOPLEFT", 10, -34)
modeLabel:SetText("Modo activo: Normal")

local pbText = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pbText:SetPoint("TOPRIGHT", -6, -34)
pbText:SetJustifyH("RIGHT")
pbText:SetText("Bonus competencia: " .. GREEN .. fmtSigned(HarfordDnDCalc.GetPB()) .. ENDCLR)

HarfordDnDUI.MakeButton(SEC_TOP, "Normal", 72, 20, 10, -48, function()
    _modoTiradaSingleUse = false
    ARCSET("ModoTirada", "normal")
    if RefreshTopInfo then RefreshTopInfo() end
end)

local function IsAnyShiftDown()
    return (IsShiftKeyDown and IsShiftKeyDown())
        or (IsLeftShiftKeyDown and IsLeftShiftKeyDown())
        or (IsRightShiftKeyDown and IsRightShiftKeyDown())
end

local _btnVentaja, _btnDesventaja

local function RefreshModeButtonLabels()
    local shift = IsAnyShiftDown()
    if _btnVentaja    then _btnVentaja:SetText(shift    and "Modo V" or "Ventaja")    end
    if _btnDesventaja then _btnDesventaja:SetText(shift and "Modo D" or "Desventaja") end
    if HarfordDnDStore.RefreshWeaponDamageButton then
        HarfordDnDStore.RefreshWeaponDamageButton()
    end
end

-- MODIFIER_STATE_CHANGED no dispara para shift izquierdo en Epsilon.
-- OnUpdate en SEC_TOP: una comparación booleana por frame, solo mientras la ficha está abierta.
do
    local _lastShift = false
    SEC_TOP:SetScript("OnUpdate", function()
        local now = IsAnyShiftDown()
        if now ~= _lastShift then
            _lastShift = now
            RefreshModeButtonLabels()
        end
    end)
end

local function MakeModeButton(label, labelShift, xOff, arcValue)
    local btn = HarfordDnDUI.MakeButton(SEC_TOP, label, 72, 20, xOff, -48, function()
        -- Sin shift → un solo uso. Con shift → permanente.
        _modoTiradaSingleUse = not IsAnyShiftDown()
        ARCSET("ModoTirada", arcValue)
        if RefreshTopInfo then RefreshTopInfo() end
    end)
    return btn
end

_btnVentaja    = MakeModeButton("Ventaja",    "Modo V", 88,  "adv")
_btnDesventaja = MakeModeButton("Desventaja", "Modo D", 166, "dis")

local scModLabel = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
scModLabel:SetPoint("TOPLEFT", 10, -74)
scModLabel:SetJustifyH("LEFT")

local scDrop = CreateFrame("Frame", nil, SEC_TOP, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(scDrop, 150)
scDrop:ClearAllPoints()
scDrop:SetPoint("TOPLEFT", -7, -90)

local SetSpellAbilityKey

local function SyncSpellDrop()
    UIDropDownMenu_SetText(scDrop, GetSpellAbilityKey())
end

UIDropDownMenu_Initialize(scDrop, function(self, level)
    local current = GetSpellAbilityKey()
    for _, a in ipairs(HarfordDnDData.ABIL) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = a.key
        info.value = a.key
        info.func = function() SetSpellAbilityKey(a.key) end
        info.checked = (a.key == current)
        UIDropDownMenu_AddButton(info, level)
    end
end)

SetSpellAbilityKey = function(v)
    ARCSET("AtributoConjuro", v)
    SyncSpellDrop()
    if RefreshTopInfo then RefreshTopInfo() end
end

SyncSpellDrop()

local miscLabel, miscBox, SetMiscBoxFromARC = MakeSignedEditBox(
    SEC_TOP, "Mod Global:", -10, -96, "BonoSituacional", 0
)

local modArmaLabel, modArmaBox, SetModArmaFromARC = MakeSignedEditBox(
    SEC_ATK, "Mod Arma:", -240, -118, "ModArma", 0
)

local armorClassLabel, armorClassBox, SetArmorClassBoxFromARC = MakeArmorClassEditBox(SEC_ATK, -18, -34)

local weaponInfoText = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
weaponInfoText:SetPoint("TOPLEFT", 10, -34)
weaponInfoText:SetWidth(280)
weaponInfoText:SetJustifyH("LEFT")
weaponInfoText:SetJustifyV("TOP")
weaponInfoText:SetWordWrap(true)
weaponInfoText:SetMaxLines(2)
weaponInfoText:SetText("")

local weaponDrop = CreateFrame("Frame", nil, SEC_ATK, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(weaponDrop, 145)
weaponDrop:ClearAllPoints()
weaponDrop:SetPoint("TOPLEFT", -7, -64)

local versBtn = HarfordDnDUI.MakeButton(SEC_ATK, "Versátil", 70, 22, 175, -66, function()
    local def = GetWeaponDef(GetWeaponKey())
    if not HarfordDnDWeapons.GetVersatileDice(def) then return end
    ARCSET("Versatil", HarfordDnDCalc.GetVersatileActive() and 0 or 1)
    UpdateWeaponInfoUI()
end)

local dmgInfoText = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dmgInfoText:SetPoint("TOPLEFT", 10, -98)
dmgInfoText:SetWidth(158)
dmgInfoText:SetJustifyH("LEFT")
dmgInfoText:SetText("")

HarfordDnDStore.offhandCheckbox = CreateFrame("CheckButton", nil, SEC_ATK, "UICheckButtonTemplate")
HarfordDnDStore.offhandCheckbox:SetPoint("TOPLEFT", SEC_ATK, "TOPLEFT", 170, -88)
HarfordDnDStore.offhandCheckbox:SetSize(22, 22)
HarfordDnDStore.offhandCheckbox:SetScript("OnClick", function(self)
    ARCSET("Offhand", self:GetChecked() and 1 or 0)
    UpdateWeaponInfoUI()
end)

HarfordDnDStore.offhandCheckboxLabel = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
HarfordDnDStore.offhandCheckboxLabel:SetPoint("LEFT", HarfordDnDStore.offhandCheckbox, "RIGHT", -1, 0)
HarfordDnDStore.offhandCheckboxLabel:SetText("Offhand")

GetWeaponKey = function()
    local v = ARCGET("ArmaSeleccionada", "Desarmado")
    for _, w in ipairs(HarfordDnDWeapons.WEAPONS) do
        if w.key == v then return v end
    end
    return "Desarmado"
end

GetWeaponDef = function(key)
    for _, w in ipairs(HarfordDnDWeapons.WEAPONS) do
        if w.key == key then return w end
    end
    return HarfordDnDWeapons.WEAPONS[1]
end

-- ParseDice, GetVersatileDice, WeaponBaseDice y WeaponPropsLabel viven en HarfordDnDWeapons.

local function GetWeaponAttackAbility(def)
    local hasFinesse = false
    if def and def.props then
        for _, p in ipairs(def.props) do
            if p:find("Sutil") then hasFinesse = true break end
        end
    end
    if def and def.mode == "Ranged" then return "Destreza" end
    if hasFinesse then
        local mStr = HarfordDnDCalc.GetAbilityMod("Fuerza")
        local mDex = HarfordDnDCalc.GetAbilityMod("Destreza")
        return (mDex >= mStr) and "Destreza" or "Fuerza"
    end
    return "Fuerza"
end

HarfordDnDStore.GetWeaponAttackEmoteId = function(def, offhand, critTag)
    if not def then return nil end
    if critTag == "CRÍTICO" and def.critEmoteId then return def.critEmoteId end
    if def.emoteId then return def.emoteId end
    if not (HarfordEmotes and HarfordEmotes.Get) then return nil end

    local emoteKey
    if offhand then
        if def.key == "Desarmado" then
            emoteKey = "unarmed_offhand"
        elseif def.dmgType == "perforante" or HarfordDnDStore.HasWeaponProp(def, "Sutil") then
            emoteKey = "thrust_offhand"
        else
            emoteKey = "offhand"
        end
    elseif def.key == "Desarmado" then
        emoteKey = "unarmed"
    elseif def.mode == "Ranged" then
        if HarfordDnDStore.HasWeaponProp(def, "Arrojadiza") then
            emoteKey = "throw"
        elseif def.key:find("Arco") then
            emoteKey = "bow"
        else
            emoteKey = "rifle"
        end
    elseif HarfordDnDStore.HasWeaponProp(def, "Alcance") and HarfordDnDStore.HasWeaponProp(def, "Dos manos") then
        emoteKey = "polearm"
    elseif HarfordDnDCalc.GetVersatileActive() or HarfordDnDStore.HasWeaponProp(def, "Dos manos") then
        emoteKey = "two_hand"
    elseif def.dmgType == "perforante" or HarfordDnDStore.HasWeaponProp(def, "Sutil") then
        emoteKey = "thrust"
    else
        emoteKey = "one_hand"
    end

    local emote = HarfordEmotes.Get(emoteKey)
    return emote and emote.id or nil
end

UpdateWeaponInfoUI = function()
    local def = GetWeaponDef(GetWeaponKey())
    weaponInfoText:SetText(HarfordDnDWeapons.WeaponPropsLabel(def))

    local vDice = HarfordDnDWeapons.GetVersatileDice(def)
    if vDice then
        versBtn:Enable()
        versBtn:SetText("Versátil")
    else
        ARCSET("Versatil", 0)
        versBtn:Disable()
        versBtn:SetText("Versátil")
    end

    local offhandAvailable = HarfordDnDStore.IsOffhandAvailable(def)
    if not offhandAvailable then
        ARCSET("Offhand", 0)
    end
    if HarfordDnDStore.offhandCheckbox then
        HarfordDnDStore.offhandCheckbox:SetShown(offhandAvailable)
        HarfordDnDStore.offhandCheckbox:SetChecked(offhandAvailable and HarfordDnDStore.GetOffhandActive(def))
    end
    if HarfordDnDStore.offhandCheckboxLabel then
        HarfordDnDStore.offhandCheckboxLabel:SetShown(offhandAvailable)
    end

    local abil = GetWeaponAttackAbility(def)
    local abiMod = (def.addAbi and abil) and HarfordDnDCalc.GetAbilityMod(abil) or 0
    if HarfordDnDStore.GetOffhandActive(def) and abiMod > 0 then
        abiMod = 0
    end
    local wmod = HarfordDnDCalc.GetWeaponDamageBonus and HarfordDnDCalc.GetWeaponDamageBonus() or HarfordDnDCalc.GetWeaponMod()
    local dice = HarfordDnDWeapons.WeaponBaseDice(def)

    local parts = {}
    if abiMod ~= 0 then parts[#parts+1] = fmtSigned(abiMod) end
    if wmod ~= 0 then parts[#parts+1] = fmtSigned(wmod) end
    local bonusTxt = table.concat(parts, "")

    local dtype = def.dmgType or ""
    local dtypeTxt = (dtype ~= "") and (" " .. dtype) or ""
    dmgInfoText:SetText(("Daño: %s%s%s"):format(dice, bonusTxt, dtypeTxt))
    if HarfordDnDStore.RefreshWeaponDamageButton then
        HarfordDnDStore.RefreshWeaponDamageButton()
    end
end

local function SyncWeaponDrop()
    UIDropDownMenu_SetText(weaponDrop, GetWeaponKey())
end

local function SetWeaponType(v)
    ARCSET("ArmaSeleccionada", v)
    SyncWeaponDrop()
    UpdateWeaponInfoUI()
end

UIDropDownMenu_Initialize(weaponDrop, function(self, level, menuList)
    local current = GetWeaponKey()
    local groups = HarfordDnDWeapons.GetWeaponMenuGroups()

    if level == 1 then
        for _, group in ipairs(groups) do
            if #group.items > 0 then
                local info = UIDropDownMenu_CreateInfo()
                info.text = group.text
                info.hasArrow = true
                info.notCheckable = true
                info.menuList = group.key
                UIDropDownMenu_AddButton(info, level)
            end
        end
        return
    end

    if level == 2 and menuList then
        for _, group in ipairs(groups) do
            if group.key == menuList then
                for _, w in ipairs(group.items) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = w.key
                    info.value = w.key
                    info.func = function()
                        SetWeaponType(w.key)
                    end
                    info.checked = (w.key == current)
                    UIDropDownMenu_AddButton(info, level)
                end
                return
            end
        end
    end
end)

SyncWeaponDrop()
UpdateWeaponInfoUI()

local function DoWeaponAttack()
    -- Requiere target valido (no uno mismo).
    if not (UnitExists and UnitExists("target"))
        or (UnitIsUnit and UnitIsUnit("target", "player")) then
        return
    end
    local def = GetWeaponDef(GetWeaponKey())
    local offhand = HarfordDnDStore.GetOffhandActive and HarfordDnDStore.GetOffhandActive(def)
    local abil = GetWeaponAttackAbility(def)
    local base = HarfordDnDCalc.GetAbilityMod(abil)
    local prof = HarfordDnDCalc.GetPB()
    local wmod = HarfordDnDCalc.GetWeaponAttackBonus and HarfordDnDCalc.GetWeaponAttackBonus() or HarfordDnDCalc.GetWeaponMod()
    local misc = HarfordDnDCalc.GetMiscBonus()

    local chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full()
    local total = chosen + base + prof + wmod + misc
    local bonusTxt = HarfordDnDCalc.BonusConcat(base, prof, wmod, misc)
    local armorClass, hit, armorText = HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, "target")
    if armorText and armorText ~= "" then
        bonusTxt = bonusTxt .. armorText
    end

    local wmodLabel = ""
    if wmod ~= 0 then wmodLabel = " " .. fmtSigned(wmod) end

    HarfordDnDRolls.Broadcast({
        type = "attack",
        label = (offhand and "Ataque Offhand " or "Ataque ") .. def.key .. wmodLabel,
        total = total,
        dice = HarfordDnDCalc.FormatD20Dice(chosen, ra, rb),
        modifiers = bonusTxt,
        critical = critTag,
        mode = modeTag
    })
    local isCritical = HarfordDnDCombat.IsCriticalRollTag(critTag)
    HarfordDnDStore.pendingWeaponCriticalKey = isCritical and def.key or nil

    -- Familia de animacion del arma (nil = arco/rifle/conjuro: sin preset melee).
    local family = HarfordDnDWeapons.GetAnimFamily
        and HarfordDnDWeapons.GetAnimFamily(def, HarfordDnDCalc.GetVersatileActive())

    -- Reaccion sincronizada con el impacto del preset solo si la CA esta resuelta
    -- (hit/miss conocido). El daño (onImpactOnce) es mecanico y se aplica siempre.
    local hitFlag, onImpactOnce
    if armorClass then
        hitFlag = hit == true
        if hit then
            onImpactOnce = function()
                local damageTotal = RollWeaponDamage(def, abil, isCritical)
                HarfordDnDStore.pendingWeaponCriticalKey = nil
                HarfordDnDCombat.ApplyWeaponDamageToTarget(damageTotal, isCritical)
            end
        else
            HarfordDnDStore.pendingWeaponCriticalKey = nil
        end
    end

    -- Atacante: corre el preset de ataque (swing) y despacha herida/defensa al
    -- objetivo en el instante de impacto. Para armas sin preset (ranged/conjuro) la
    -- secuencia solo sincroniza la reaccion; el swing lo da el emote actual de abajo.
    HarfordDnDCombat.RunAttackSequence({
        family       = family,
        critical     = isCritical,
        offhand      = offhand,
        hit          = hitFlag,
        defenderUnit = "target",
        npcAttacker  = false,
        onImpactOnce = onImpactOnce,
    })

    -- Swing del atacante SOLO para armas sin preset melee (arco/rifle/conjuro):
    -- mantiene el emote actual. Las familias melee ya animan con el preset.
    if family == nil and HarfordDnDStore.AreAnimationsEnabled and HarfordDnDStore.AreAnimationsEnabled()
        and HarfordServerActions and HarfordServerActions.ModAnim then
        local eid = HarfordDnDStore.GetWeaponAttackEmoteId
            and HarfordDnDStore.GetWeaponAttackEmoteId(def, offhand, critTag)
        if eid then
            HarfordServerActions.ModAnim(eid)
        end
    end
    ConsumeMode()
end

-- Checkbox: activar/desactivar animaciones (emotes, auras) al atacar/dañar
-- Flag en HarfordDnDStore para no añadir un local de chunk (límite 200 Lua 5.1)
do
    HarfordDnDStore.animsEnabled = true

    local chk = CreateFrame("CheckButton", nil, SEC_ATK, "UICheckButtonTemplate")
    chk:SetPoint("TOPLEFT", SEC_ATK, "TOPLEFT", 266, -6)
    chk:SetSize(24, 24)
    chk:SetChecked(true)

    local chkLabel = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chkLabel:SetPoint("LEFT", chk, "RIGHT", 2, 0)
    chkLabel:SetText("Animaciones")

    chk:SetScript("OnClick", function(self)
        HarfordDnDStore.animsEnabled = self:GetChecked() == true or self:GetChecked() == 1
        if not HarfordDnDStore.AreAnimationsEnabled() and HarfordDnDStore.deathAuraActive and HarfordAuras then
            HarfordDnDStore.deathAuraActive = false
            HarfordAuras.Remove("death")
        end
        -- El botón de modo combate solo existe con animaciones activas.
        if HarfordDnDStore.combatModeButton then
            HarfordDnDStore.combatModeButton:SetShown(
                HarfordDnDStore.AreAnimationsEnabled() and not SheetContext.showActionPanel)
        end
        -- Informar al resto (DMs) del nuevo estado
        if HarfordSync and HarfordSync.SendAnimFlag then
            local ch = HarfordSync.BestChannel and HarfordSync.BestChannel()
            if ch then
                HarfordSync.SendAnimFlag(ADDON_PREFIX, HarfordDnDStore.animsEnabled, nil)
            end
        end
    end)

    HarfordDnDStore.animsCheckbox = chk
    HarfordDnDStore.animsCheckboxLabel = chkLabel
end

-- Botón "Modo combate" (jugador): postura de combate vía `mod anim` según el
-- arma equipada. Solo visible con animaciones activas y fuera de la ficha NPC.
-- Pulsar de nuevo SIN cambiar de arma vuelve a Stand (emote 26).
-- do...end para no consumir un local de chunk (límite 200 Lua 5.1).
do
    -- Mapea el arma equipada a la clave de emote de combate.
    -- Versátil activo en un arma versátil → siempre la postura a dos manos.
    local function GetCombatEmoteKeyForWeapon(def)
        if not def or def.key == "Desarmado" then return "unarmed" end

        local vDice = HarfordDnDWeapons.GetVersatileDice(def)
        if vDice and HarfordDnDCalc.GetVersatileActive() then return "two_hand" end

        local props = def.props or {}
        local function hasProp(name)
            for _, p in ipairs(props) do
                if p:find(name) then return true end
            end
            return false
        end

        if def.mode == "Ranged" then
            if def.key:find("Arco") then return "bow" end
            if def.key:find("Ballesta") or def.cat == "De fuego" or def.key == "Cerbatana" then
                return "rifle"
            end
            -- Hondas, dardos, redes y demás a distancia: postura arrojadiza.
            return "thrown"
        end

        -- Cuerpo a cuerpo: asta (alcance + dos manos), dos manos, o una mano.
        if hasProp("Alcance") and hasProp("Dos manos") then return "polearm" end
        if hasProp("Dos manos") then return "two_hand" end
        return "one_hand"
    end

    local btn = HarfordDnDUI.MakeButton(SEC_ATK, "Modo combate", 110, 22, 150, -6, function()
        if not (HarfordDnDStore.AreAnimationsEnabled and HarfordDnDStore.AreAnimationsEnabled()) then return end
        if not (HarfordServerActions and HarfordServerActions.ModAnim) then return end
        -- No se limpia el target aqui: ClearTarget() es una funcion protegida de WoW
        -- (solo Blizzard UI / codigo seguro) y un addon no puede llamarla. La animacion
        -- de combate se aplica al propio personaje sin necesidad de deseleccionar.

        local def = GetWeaponDef(GetWeaponKey())
        local key = (def and def.key) or "Desarmado"
        local stand = HarfordEmotes and HarfordEmotes.GetCombat and HarfordEmotes.GetCombat("stand")
        local standId = (stand and stand.id) or 26

        if HarfordDnDStore.combatModeWeaponKey == key then
            -- Mismo arma sin cambio previo: salir del modo combate.
            HarfordServerActions.ModAnim(standId)
            HarfordDnDStore.combatModeWeaponKey = nil
            HarfordDnDStore.combatModeKey = nil
        else
            local combatKey = GetCombatEmoteKeyForWeapon(def)
            local cdef = HarfordEmotes and HarfordEmotes.GetCombat
                and HarfordEmotes.GetCombat(combatKey)
            if cdef and cdef.id then
                HarfordServerActions.ModAnim(cdef.id)
            end
            HarfordDnDStore.combatModeWeaponKey = key
            -- Postura activa (one_hand/two_hand/...) para elegir parry/dodge si nos atacan.
            HarfordDnDStore.combatModeKey = combatKey
        end
    end)

    HarfordDnDStore.combatModeButton = btn
    btn:SetShown(HarfordDnDStore.AreAnimationsEnabled())
end

local weaponAttackButton = HarfordDnDUI.MakeButton(SEC_ATK, "Ataque Arma", 110, 22, 266, -66, function()
    DoWeaponAttack()
end)

-- El daño de arma al impactar esta automatizado en `DoWeaponAttack`; este boton
-- queda como activador del frame de Daño Custom (sin Shift) sobre el target.
local weaponDamageButton = HarfordDnDUI.MakeButton(SEC_ATK, "Daño Custom", 110, 22, 266, -94, function()
    if HarfordDnDStore.RefreshWeaponDamageButton
        and not HarfordDnDStore.RefreshWeaponDamageButton() then
        return
    end
    if HarfordDnDStore.OpenCustomDamageFrame then
        HarfordDnDStore.OpenCustomDamageFrame("target")
    end
end)

HarfordDnDStore.RefreshWeaponDamageButton = function()
    local enabled = UnitExists and UnitExists("target")
        and not (UnitIsUnit and UnitIsUnit("target", "player"))
    if weaponDamageButton then
        weaponDamageButton:SetText("Daño Custom")
        if enabled then
            weaponDamageButton:Enable()
        else
            weaponDamageButton:Disable()
        end
    end
    -- Ataque Arma y Ataque Conjuro tambien requieren target valido (no propio).
    if weaponAttackButton then
        if enabled then weaponAttackButton:Enable() else weaponAttackButton:Disable() end
    end
    local spellBtn = HarfordDnDStore.playerAttackControls
        and HarfordDnDStore.playerAttackControls.spellAttackButton
    if spellBtn then
        if enabled then spellBtn:Enable() else spellBtn:Disable() end
    end
    return enabled
end
HarfordDnDStore.RefreshWeaponDamageButton()

do
    -- Acepta notacion de dados (XdY, dY, XdY+Z, dY-Z; X opcional = 1) o un numero
    -- plano. El numero plano es un valor FIJO (no se tira 1dN): devuelve { flat = N }
    -- y RollCustomDamage le aplica el bonus de caracteristica como a cualquier tirada.
    local function ParseCustomDamageInput(text)
        text = tostring(text or ""):lower():gsub("%s+", "")
        if text == "" then return nil, "Introduce dados o un numero" end

        local n, sides, bonus = text:match("^(%d*)d(%d+)([+-]%d+)$")
        if not sides then
            n, sides = text:match("^(%d*)d(%d+)$")
            bonus = nil
        end
        if sides then
            n = (n ~= "" and tonumber(n)) or 1
            sides = tonumber(sides)
            bonus = tonumber(bonus) or 0
            if n <= 0 or sides <= 0 then return nil, "Formato de dados invalido" end
            return { count = n, sides = sides, bonus = bonus }
        end

        local flat = text:match("^(%d+)$")
        if flat then
            return { flat = tonumber(flat) }
        end

        return nil, "Formato invalido (usa XdY, dY o un numero)"
    end

    local function PrintCustomDamageError(message)
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff5555[Harford]|r " .. tostring(message))
        end
    end

    local function RollCustomDamage(expr, abilityKey, damageKey, maximizeDice, mitigationUnit)
        mitigationUnit = mitigationUnit or "target"
        local parsed, err = ParseCustomDamageInput(expr)
        if not parsed then
            PrintCustomDamageError(err)
            return 0
        end

        local isFlat = parsed.flat ~= nil
        local rolls, sum = {}, 0
        if isFlat then
            sum = parsed.flat
        else
            for i = 1, parsed.count do
                local r = maximizeDice and parsed.sides or HarfordDnDCalc.RollDie(parsed.sides)
                rolls[#rolls + 1] = r
                sum = sum + r
            end
        end

        local abilityMod = abilityKey and HarfordDnDCalc.GetAbilityMod(abilityKey) or 0
        local fixedBonus = isFlat and 0 or (parsed.bonus or 0)
        local total = sum + fixedBonus + abilityMod
        if total < 0 then total = 0 end

        local dtype = HarfordDamageTypes and HarfordDamageTypes.GetLabel
            and HarfordDamageTypes.GetLabel(damageKey)
            or tostring(damageKey or "")
        dtype = tostring(dtype or ""):lower()

        local marker = ""
        if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
            local applied, _status, mk = HarfordDamageMitigation.ForTarget(mitigationUnit, dtype, total)
            total, marker = applied, mk
        end

        local parts = {}
        if fixedBonus ~= 0 then parts[#parts + 1] = fmtSigned(fixedBonus) end
        if abilityMod ~= 0 then parts[#parts + 1] = fmtSigned(abilityMod) end
        local bonusTxt = table.concat(parts, "")

        -- Numero plano: muestra el valor fijo + bonus (sin "XdY"); dados: muestra la tirada.
        local diceText
        if isFlat then
            diceText = tostring(parsed.flat) .. bonusTxt
        else
            diceText = parsed.count .. "d" .. parsed.sides .. ": " .. table.concat(rolls, "+") .. bonusTxt
        end

        local modifiersTxt = dtype
        if marker ~= "" then modifiersTxt = dtype .. " " .. marker end

        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = "Daño",
            total = total,
            dice = diceText,
            -- Sin dados no hay critico que maximizar; el valor fijo no se marca CRITICO.
            critical = (maximizeDice and not isFlat) and "CRÍTICO" or "",
            modifiers = modifiersTxt,
            mode = "",
        })
        return total
    end

    local function ApplyCustomDamage()
        local frame = HarfordDnDStore.customDamageFrame
        if not frame then return end
        -- applyUnit: "target" (panel jugador) o "focus" (panel NPC, daño en nombre del NPC).
        -- En "focus" SI se permite que sea uno mismo (el NPC ataca a mi propio PJ).
        local applyUnit = frame.applyUnit or "target"
        local blockSelf = applyUnit ~= "focus"
        if not (UnitExists and UnitExists(applyUnit))
            or (blockSelf and UnitIsUnit and UnitIsUnit(applyUnit, "player")) then
            PrintCustomDamageError("Selecciona un objetivo valido para tirar daño custom")
            return
        end

        local isCritical = HarfordDnDStore.pendingWeaponCriticalKey ~= nil
        HarfordDnDStore.pendingWeaponCriticalKey = nil

        local total = RollCustomDamage(
            frame.diceBox and frame.diceBox:GetText(),
            frame.abilityKey,
            frame.damageKey or "slashing",
            isCritical,
            applyUnit
        )

        -- Aplica el daño: focus (jugador, en nombre del NPC, RADJ) o target (NPC oficial / jugador ajeno).
        if applyUnit == "focus" then
            HarfordDnDCombat.ApplyActionDamageToFocus(total)
        else
            HarfordDnDCombat.ApplyWeaponDamageToTarget(total, isCritical)
        end
    end

    local function EnsureCustomDamageFrame()
        if HarfordDnDStore.customDamageFrame then
            return HarfordDnDStore.customDamageFrame
        end

        local frame = CreateFrame("Frame", "HarfordCustomDamageFrame", UIParent, "BackdropTemplate")
        frame:SetSize(300, 154)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        if F and F.GetFrameLevel then
            frame:SetFrameLevel(F:GetFrameLevel() + 200)
        else
            frame:SetFrameLevel(200)
        end
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 12,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            frame:SetBackdropColor(0.02, 0.02, 0.02, 0.92)
            frame:SetBackdropBorderColor(0.75, 0.65, 0.35, 1)
        end

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Daño")
        frame.title = title

        local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)
        close:SetScript("OnClick", function() frame:Hide() end)

        local diceLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        diceLabel:SetPoint("TOPLEFT", 18, -38)
        diceLabel:SetText("Dados")

        frame.diceBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        frame.diceBox:SetSize(100, 20)
        frame.diceBox:SetPoint("LEFT", diceLabel, "RIGHT", 48, 0)
        frame.diceBox:SetAutoFocus(false)
        frame.diceBox:SetText("1d6")
        frame.diceBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ApplyCustomDamage() end)
        frame.diceBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        local abilLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        abilLabel:SetPoint("TOPLEFT", 18, -68)
        abilLabel:SetText("Característica")

        frame.abilityDrop = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(frame.abilityDrop, 120)
        frame.abilityDrop:SetPoint("TOPLEFT", 112, -50)
        frame.abilityKey = nil

        UIDropDownMenu_Initialize(frame.abilityDrop, function(_, level)
            if level ~= 1 then return end
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Ninguno"
            info.checked = frame.abilityKey == nil
            info.func = function()
                frame.abilityKey = nil
                UIDropDownMenu_SetText(frame.abilityDrop, "Ninguno")
            end
            UIDropDownMenu_AddButton(info, level)
            for _, abil in ipairs(HarfordDnDData.ABIL) do
                local abilKey = abil.key
                info = UIDropDownMenu_CreateInfo()
                info.text = abilKey
                info.checked = frame.abilityKey == abilKey
                info.func = function()
                    frame.abilityKey = abilKey
                    UIDropDownMenu_SetText(frame.abilityDrop, abilKey)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetText(frame.abilityDrop, "Ninguno")

        local typeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        typeLabel:SetPoint("TOPLEFT", 18, -98)
        typeLabel:SetText("Tipo de daño")

        frame.damageDrop = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
        UIDropDownMenu_SetWidth(frame.damageDrop, 120)
        frame.damageDrop:SetPoint("TOPLEFT", 112, -80)
        frame.damageKey = "slashing"

        UIDropDownMenu_Initialize(frame.damageDrop, function(_, level)
            if level ~= 1 then return end
            local list = HarfordDamageTypes and HarfordDamageTypes.GetOrderedList
                and HarfordDamageTypes.GetOrderedList()
                or {}
            for _, opt in ipairs(list) do
                local damageKey = opt.key
                local damageLabel = opt.label
                local info = UIDropDownMenu_CreateInfo()
                info.text = damageLabel
                info.checked = frame.damageKey == damageKey
                info.func = function()
                    frame.damageKey = damageKey
                    UIDropDownMenu_SetText(frame.damageDrop, damageLabel)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        UIDropDownMenu_SetText(frame.damageDrop,
            HarfordDamageTypes and HarfordDamageTypes.GetLabel and HarfordDamageTypes.GetLabel("slashing") or "Cortante")

        HarfordDnDUI.MakeButton(frame, "Lanzar", 112, 22, 94, -122, ApplyCustomDamage)

        HarfordDnDStore.customDamageFrame = frame
        return frame
    end

    HarfordDnDStore.OpenCustomDamageFrame = function(applyUnit)
        local frame = EnsureCustomDamageFrame()
        frame.applyUnit = applyUnit or "target"
        if F and F.GetFrameLevel then
            frame:SetFrameLevel(F:GetFrameLevel() + 200)
        end
        if frame.title then
            frame.title:SetText(frame.applyUnit == "focus" and "Daño Custom (focus)" or "Daño")
        end
        frame:Show()
        frame:Raise()
        if frame.diceBox then frame.diceBox:SetFocus() end
    end
end

local spellAttackButton = HarfordDnDUI.MakeButton(SEC_ATK, "Ataque Conjuro", 110, 22, 266, -122, function()
    DoSpellAttack()
end)

HarfordDnDInitLabel, HarfordDnDInitBox, HarfordDnDSetInitBoxFromARC = MakeSignedEditBox(
    SEC_ATK, "Mod Ini:", -240, -146, "ModIniciativa", 0
)

local initiativeButton = HarfordDnDUI.MakeButton(SEC_ATK, "Iniciativa", 110, 22, 266, -150, function()
    DoRoll("Iniciativa", HarfordDnDCalc.GetAbilityMod("Destreza"), HarfordDnDGetInitiativeMod())
end)

HarfordDnDStore.playerAttackControls = {
    weaponInfoText = weaponInfoText,
    weaponDrop = weaponDrop,
    versBtn = versBtn,
    dmgInfoText = dmgInfoText,
    offhandCheckbox = HarfordDnDStore.offhandCheckbox,
    offhandCheckboxLabel = HarfordDnDStore.offhandCheckboxLabel,
    modArmaLabel = modArmaLabel,
    modArmaBox = modArmaBox,
    armorClassLabel = armorClassLabel,
    armorClassBox = armorClassBox,
    initLabel = HarfordDnDInitLabel,
    initBox = HarfordDnDInitBox,
    weaponAttackButton = weaponAttackButton,
    weaponDamageButton = weaponDamageButton,
    spellAttackButton = spellAttackButton,
    initiativeButton = initiativeButton,
}

-- ─── Tracker de movimiento ──────────────────────────────────────────────────
do
    local YARDS_TO_METERS = 0.9144
    local POLL_INTERVAL   = 0.1

    local _tracking    = false
    local _totalMeters = 0
    local _lastX, _lastY, _lastZ
    local _elapsed     = 0

	local movLabel = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	movLabel:SetPoint("TOPLEFT", SEC_ATK, "TOPLEFT", 166, -134)
	movLabel:SetSize(90, 14)
	movLabel:SetJustifyH("CENTER")
	movLabel:SetText("")

	local movBtn = HarfordDnDUI.MakeButton(SEC_ATK, "Movimiento", 90, 22, 166, -150, function() end)
    HarfordDnDStore.playerAttackControls.movementLabel = movLabel
    HarfordDnDStore.playerAttackControls.movementButton = movBtn

    -- Detecta qué API de posición está disponible en este cliente
    local function GetPos()
        if UnitPosition then
            local x, y, z = UnitPosition("player")
            if x and y then return x, y, z or 0 end
        end
        if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local p = C_Map.GetPlayerMapPosition(mapID, "player")
                if p then return p.x, p.y, 0 end
            end
        end
        return nil
    end

    local function FormatMeters(m)
        return string.format("%.1f m", m)
    end

    -- Throttle a 10fps; activo solo mientras _tracking=true
    movBtn:SetScript("OnUpdate", function(_, dt)
        if not _tracking then return end
        _elapsed = _elapsed + dt
        if _elapsed < POLL_INTERVAL then return end
        _elapsed = 0

        local nx, ny, nz = GetPos()
        if not nx then return end
        if _lastX then
            local dx = nx - _lastX
            local dy = ny - _lastY
            local dz = nz - _lastZ
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz) * YARDS_TO_METERS
            if dist > 0.05 then
                _totalMeters = _totalMeters + dist
                movBtn:SetText(string.format("Parar %s", FormatMeters(_totalMeters)))
                movLabel:SetText(FormatMeters(_totalMeters))
            end
        end
        _lastX, _lastY, _lastZ = nx, ny, nz
    end)

    movBtn:SetScript("OnClick", function()
        if _tracking then
            -- Parar
            _tracking = false
            movBtn:SetText("Movimiento")
            movLabel:SetText(_totalMeters > 0 and FormatMeters(_totalMeters) or "")
        else
            -- Arrancar: verificar que hay API de posición disponible
            local x, y, z = GetPos()
            if not x then
                movLabel:SetText("Sin posición")
                return
            end
            _totalMeters = 0
            _elapsed     = 0
            _lastX, _lastY, _lastZ = x, y, z
            _tracking = true
            movBtn:SetText("Parar  0.0m")
            movLabel:SetText("0.0 m")
        end
    end)
end
-- ─── Fin tracker movimiento ─────────────────────────────────────────────────

DoSpellAttack = function()
    -- Requiere target valido (no uno mismo): igual que Ataque Arma.
    if not (UnitExists and UnitExists("target"))
        or (UnitIsUnit and UnitIsUnit("target", "player")) then
        return
    end

    local abil = GetSpellAbilityKey()
    local base = HarfordDnDCalc.GetAbilityMod(abil)
    local prof = HarfordDnDCalc.GetSpellPB()
    local misc = HarfordDnDCalc.GetMiscBonus()
    local spellAttackBonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("spellAttack")
        or 0

    local chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full()
    local total = chosen + base + prof + spellAttackBonus + misc
    local bonusTxt = HarfordDnDCalc.BonusConcat(base, prof, spellAttackBonus, misc)
    -- Ataque Conjuro se resuelve contra la CA del target (como Ataque Arma).
    local _armorClass, _hit, armorText = HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, "target")
    if armorText and armorText ~= "" then
        bonusTxt = bonusTxt .. armorText
    end

    HarfordDnDRolls.Broadcast({
        type = "spell",
        label = "Ataque Conjuro",
        total = total,
        dice = HarfordDnDCalc.FormatD20Dice(chosen, ra, rb),
        modifiers = bonusTxt,
        critical = critTag,
        mode = modeTag
    })
    ConsumeMode()
end

-- Panel de acciones externas para contextos de ficha (por ejemplo NPC desde Admin).
-- La extension proporciona los datos ya parseados; este modulo solo renderiza y tira.
-- IIFE para no consumir locales del chunk principal (límite 200 Lua 5.1).
;(function()
    local panel = CreateFrame("Frame", nil, SEC_ATK)
    panel:SetPoint("TOPLEFT", SEC_ATK, "TOPLEFT", 4, -29)
    panel:SetPoint("BOTTOMRIGHT", SEC_ATK, "BOTTOMRIGHT", -4, 4)
    panel:SetFrameLevel(SEC_ATK:GetFrameLevel() + 100)
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
        if not (UnitExists and UnitExists("focus")) then return nil end
        local name = HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("focus")
        if not name or name == "" then
            name = (GetUnitName and GetUnitName("focus", true)) or (UnitName and UnitName("focus"))
        end
        if not name or name == "" then return nil end

        local hex = HarfordTRP3 and HarfordTRP3.GetUnitNameColor and HarfordTRP3.GetUnitNameColor("focus")
        if not (type(hex) == "string" and #hex == 6 and hex:match("^%x+$")) then
            hex = nil
            if HarfordUnitFrames and HarfordUnitFrames.GetClassColor then
                local r, g, b = HarfordUnitFrames.GetClassColor("focus")
                if r then
                    hex = string.format("%02x%02x%02x",
                        math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
                end
            end
        end
        if hex then return "|cff" .. hex .. name .. "|r" end
        return name
    end

    local function RollActionAttack(action)
        -- Cada nuevo ataque descarta el pendiente NPC vs NPC anterior (no consumido).
        HarfordDnDStore.pendingNpcAttack = nil
        if not (UnitExists and UnitExists("focus")) then
            return DoRoll("Ataque " .. GetActionChatName(action), action.attackBonus, 0)
        end

        local base = toN(action.attackBonus, 0)
        local misc = HarfordDnDCalc.GetMiscBonus()
        local chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full()
        local total = chosen + base + misc
        local bonusTxt = HarfordDnDCalc.BonusConcat(base, 0, misc)
        local armorClass, hit, armorText = HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, "focus")
        if armorText and armorText ~= "" then
            bonusTxt = bonusTxt .. armorText
        end

        -- "Ataque <NOMBREFOCUS coloreado> <link de la accion>".
        local focusName = GetFocusColoredName()
        HarfordDnDRolls.Broadcast({
            type = "roll",
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
            if hit and action.damageDice then
                onImpactOnce = function()
                    -- mitigationUnit "focus": jugador → sin mitigacion (no NPC).
                    local damageTotal = RollActionDamage(action, isCritical, "focus")
                    if damageTotal and damageTotal > 0 then
                        HarfordDnDCombat.ApplyActionDamageToFocus(damageTotal)
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
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r Ataque pendiente: targetea al NPC victima para aplicar el "
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
                }
                total = total + appliedTotal
            end
        end
        if #rolledComponents == 0 then return nil end
        HarfordDnDRolls.Broadcast({
            type = "damage",
            label = "Daño " .. tostring(action.title or "Accion"),
            total = total,
            dice = table.concat(details, " + "),
            modifiers = "",
            critical = maximizeDice and "CRÍTICO" or "",
            mode = "",
        })
        return total, rolledComponents
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
        parsedText:SetText(#summary > 0 and table.concat(summary, "   ") or "No se pudo interpretar una tirada automatica.")
        -- Atacar y Daño Custom requieren un focus victima valido (no yo, no el NPC).
        local hasFocus = HasFocusVictim()
        local canAttack = selectedAction.attackBonus ~= nil and hasFocus
        local canDamage = hasFocus  -- daño custom: no depende de que la accion tenga dados
        if canAttack and SheetContext.canAttack then
            canAttack = SheetContext.canAttack() == true
        end
        if canDamage and SheetContext.canDamage then
            canDamage = SheetContext.canDamage() == true
        end
        attackButton:SetEnabled(canAttack)
        damageButton:SetEnabled(canDamage)
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
        if selectedAction and selectedAction.attackBonus ~= nil then
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
            if HarfordDnDStore.RefreshWeaponDamageButton then
                HarfordDnDStore.RefreshWeaponDamageButton()
            end
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
end)()

local scAtkText = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
scAtkText:SetPoint("TOPRIGHT", -6, -52)
scAtkText:SetJustifyH("RIGHT")

local dcText = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dcText:SetPoint("TOPRIGHT", -6, -70)
dcText:SetJustifyH("RIGHT")

local dcButton = CreateFrame("Button", nil, SEC_TOP, "UIPanelButtonTemplate")
dcButton:SetSize(96, 22)
dcButton:SetPoint("RIGHT", dcText, "LEFT", -6, -1)
dcButton:SetText("CD conjuro")
dcButton:SetScript("OnClick", function()
    SendSpellDC()
end)


HarfordDnDUI.MakeButton(SEC_TOP, "Recursos", 96, 22, 286, -6, function()
    if ResourceFrame:IsShown() then
        ResourceFrame:Hide()
    else
        RefreshResourceFrame()
        ResourceFrame:Show()
        ResourceFrame:Raise()
    end
end)

-- El titulo de la ficha solo cambia al representar un contexto NPC externo.
local function RefreshSheetTitle()
    if not FrameTitle then return end
    if SheetContext.active and SheetContext.kind == "npc" then return end
    FrameTitle:SetText("Harford DnD 5\194\170 - Ficha")
    FrameTitle:SetTextColor(1, 0.82, 0)
end

RefreshTopInfo = function()
    local mode = HarfordDnDCalc.GetMode()
    local modeName
    if mode == "adv" then
        modeName = _modoTiradaSingleUse and "Ventaja" or "Ventaja Perm."
    elseif mode == "dis" then
        modeName = _modoTiradaSingleUse and "Desventaja" or "Desventaja Perm."
    else
        modeName = "Normal"
    end
    modeLabel:SetText("Modo activo: " .. modeName)

    local spellPB = HarfordDnDCalc.GetSpellPB()
    pbText:SetText("Bonus competencia: " .. GREEN .. fmtSigned(spellPB) .. ENDCLR)

    local abil = GetSpellAbilityKey()
    local m = HarfordDnDCalc.GetAbilityMod(abil)
    local spellAttackBonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("spellAttack")
        or 0
    local spellDCBonus = HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("spellDC")
        or 0
    local short = ""
    for _, a in ipairs(HarfordDnDData.ABIL) do if a.key == abil then short = a.short break end end

    scModLabel:SetText("Mod Conjuro (" .. short .. "): " .. ColorSigned(m))
    scAtkText:SetText("Ataque Conjuro: " .. GREEN .. fmtSigned(spellPB + m + spellAttackBonus) .. ENDCLR)
    dcText:SetText(GREEN .. tostring(8 + spellPB + m + spellDCBonus) .. ENDCLR)

    SyncSpellDrop()
end

local abiKeys, savKeys = {}, {}
local Layout3Col
local RefreshSkillLayout

-- IIFE: los locales de creación de botones de atributos, salvaciones y habilidades
-- viven en su propio scope de función para no consumir el cupo de 200 del chunk.
-- Layout3Col y RefreshSkillLayout se asignan a upvalues del chunk declarados arriba.
;(function()
    local function MeasureButtonTextWidth(btn)
        local fs = btn and btn.GetFontString and btn:GetFontString()
        if not fs then return 0 end
        return fs:GetStringWidth() or 0
    end

    local function Clamp(v, lo, hi)
        if v < lo then return lo end
        if v > hi then return hi end
        return v
    end

    Layout3Col = function(section, buttons, keys, topY)
        local BH = 22
        local PX = 10
        local CG = 16
        local RG = 4
        local sw = (section and section.GetWidth and section:GetWidth()) or 412
        local avail = sw - PX * 2 - 10
        local cap = math.floor((avail - 2 * CG) / 3)
        local minW = 110
        local maxW = {minW, minW, minW}
        for i, k in ipairs(keys) do
            local b = buttons[k]
            if b then
                local w = MeasureButtonTextWidth(b) + 28
                local col = ((i - 1) % 3) + 1
                if w > maxW[col] then maxW[col] = w end
            end
        end
        for c = 1, 3 do
            if maxW[c] < minW then maxW[c] = minW end
            if maxW[c] > cap then maxW[c] = cap end
        end
        local totalW = maxW[1] + maxW[2] + maxW[3] + 2 * CG
        if totalW > avail then
            local over = totalW - avail
            for _ = 1, 3 do
                local biggest = 1
                if maxW[2] > maxW[biggest] then biggest = 2 end
                if maxW[3] > maxW[biggest] then biggest = 3 end
                local can = maxW[biggest] - minW
                if can <= 0 then break end
                local cut = math.min(over, can)
                maxW[biggest] = maxW[biggest] - cut
                over = over - cut
                if over <= 0 then break end
            end
        end
        local totalContentW = maxW[1] + maxW[2] + maxW[3] + 2 * CG
        local startX = math.floor((sw - totalContentW) / 2)
        local x1 = startX
        local x2 = x1 + maxW[1] + CG
        local x3 = x2 + maxW[2] + CG
        for i, k in ipairs(keys) do
            local b = buttons[k]
            if b then
                local col = (i - 1) % 3
                local row = math.floor((i - 1) / 3)
                local x = (col == 0 and x1) or (col == 1 and x2) or x3
                local w = (col == 0 and maxW[1]) or (col == 1 and maxW[2]) or maxW[3]
                local y = -(topY + row * (BH + RG))
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", x, y)
                b:SetSize(w, BH)
            end
        end
    end

    -- Botones de características
    for i, a in ipairs(HarfordDnDData.ABIL) do
        local col = ((i-1) % 3)
        local row = math.floor((i-1)/3)
        local b = HarfordDnDUI.MakeButton(SEC_ABI, "…", 140, 22, 10 + col*160, -36 - row*26, function()
            DoRoll(a.short, HarfordDnDCalc.GetAbilityMod(a.key), 0)
        end)
        AbilityButtons[a.key] = b
        abiKeys[#abiKeys+1] = a.key
    end

    -- Botones de tiradas de salvación
    for i, a in ipairs(HarfordDnDData.ABIL) do
        local col = ((i-1) % 3)
        local row = math.floor((i-1)/3)
        local b = HarfordDnDUI.MakeButton(SEC_SAV, "…", 140, 22, 10 + col*160, -36 - row*26, function()
            local base, prof = HarfordDnDCalc.GetSaveRollBonuses(a.key)
            DoRoll("Salv " .. a.short, base, prof)
        end)
        SaveButtons[a.key] = b
        savKeys[#savKeys+1] = a.key
    end

    -- Sección de habilidades con scroll
    local scroll = CreateFrame("ScrollFrame", nil, SEC_SKL, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -32)
    scroll:SetPoint("BOTTOMRIGHT", -28, 6)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(1, 1)
    scroll:SetScrollChild(scrollChild)

    local BTN_H = 22
    local PAD_X, PAD_Y = 8, 6
    local GAP_Y, COL_GAP = 4, 16

    RefreshSkillLayout = function()
        local sw = (scroll and scroll.GetWidth and scroll:GetWidth())
            or ((SEC_SKL and SEC_SKL.GetWidth and SEC_SKL:GetWidth()) or 412) - 34
        local avail = sw - PAD_X * 2
        local cap = math.floor((avail - COL_GAP) / 2)
        local maxW1, maxW2 = 160, 160
        for i, s in ipairs(HarfordDnDData.SKILLS) do
            local b = SkillButtons[s.id]
            if b then
                local w = MeasureButtonTextWidth(b) + 28
                if ((i-1) % 2) == 0 then
                    if w > maxW1 then maxW1 = w end
                else
                    if w > maxW2 then maxW2 = w end
                end
            end
        end
        maxW1 = Clamp(maxW1, 160, cap)
        maxW2 = Clamp(maxW2, 160, cap)
        if (maxW1 + COL_GAP + maxW2) > avail then
            local over = (maxW1 + COL_GAP + maxW2) - avail
            if maxW1 >= maxW2 then
                maxW1 = Clamp(maxW1 - over, 160, cap)
            else
                maxW2 = Clamp(maxW2 - over, 160, cap)
            end
        end
        for i, s in ipairs(HarfordDnDData.SKILLS) do
            local b = SkillButtons[s.id]
            if b then
                local col = ((i-1) % 2)
                local row = math.floor((i-1) / 2)
                local w = (col == 0) and maxW1 or maxW2
                local x = PAD_X + (col == 0 and 0 or (maxW1 + COL_GAP))
                local y = -(PAD_Y + row * (BTN_H + GAP_Y))
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", x, y)
                b:SetSize(w, BTN_H)
            end
        end
        scrollChild:SetWidth(PAD_X + maxW1 + COL_GAP + maxW2 + 6)
    end

    for i, s in ipairs(HarfordDnDData.SKILLS) do
        local col = ((i-1) % 2)
        local row = math.floor((i-1) / 2)
        local x = PAD_X + col * (200 + COL_GAP)
        local y = -(PAD_Y + row * (BTN_H + GAP_Y))
        local b = HarfordDnDUI.MakeButton(scrollChild, "…", 200, BTN_H, x, y, function()
            local base, prof = HarfordDnDCalc.GetSkillRollBonuses(s)
            DoRoll(s.name, base, prof)
        end)
        SkillButtons[s.id] = b
    end

    scrollChild:SetHeight(PAD_Y + math.ceil(#HarfordDnDData.SKILLS / 2) * (BTN_H + GAP_Y) + 8)
end)()

-- ─────────────────────────────────────────────────────────────────────────────
-- SISTEMA MORIBUNDO (Salvación Muerte)
-- Cuando salud = 0 en modo jugador (no contexto NPC), todos los botones de la
-- ficha se desactivan salvo Salv CON, que pasa a ser "Salv Muerte". El jugador
-- tira una salvacion de CON normal, pero contabiliza fallos/exitos de muerte:
--   Éxito (≥10): +1  |  Crítico (20): +2
--   Fallo (<10): -1  |  Pifia (1): -2
--   Alcanzar +3 → recupera 1 PV y sale del estado.
--   Alcanzar -3 → incapacitado, el botón se deshabilita.
-- ─────────────────────────────────────────────────────────────────────────────
do
    -- Estado persistido en HarfordDnDStore para no gastar locales de file-scope.
    HarfordDnDStore.deathSaveActive    = false
    HarfordDnDStore.deathSaveSuccesses = 0
    HarfordDnDStore.deathSaveFailures  = 0

    -- Label de contador en SEC_SAV (oculto por defecto).
    local _dsLabel = SEC_SAV:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    _dsLabel:SetPoint("BOTTOM", SEC_SAV, "BOTTOM", 0, 10)
    _dsLabel:SetJustifyH("CENTER")
    _dsLabel:Hide()

    local function FormatDeathCounter()
        local failures = HarfordDnDStore.deathSaveFailures or 0
        local successes = HarfordDnDStore.deathSaveSuccesses or 0
        return "|cffff3333" .. failures .. "|r|cffd9d9d9|||r|cff00cc00" .. successes .. "|r"
    end

    local function UpdateDyingUI()
        local f = HarfordDnDStore.deathSaveFailures  or 0
        _dsLabel:SetText(FormatDeathCounter())
        _dsLabel:Show()

        local conBtn = SaveButtons["Constitucion"]
        if conBtn then
            -- RefreshButtons/Layout3Col puede restaurar su celda original tras entrar en moribundo.
            conBtn:ClearAllPoints()
            conBtn:SetPoint("TOP", SEC_SAV, "TOP", 0, -36)
            if f >= 3 then
                conBtn:SetText("Incapacitado")
                conBtn:Disable()
            else
                conBtn:SetText("Salv Muerte")
                conBtn:Enable()
            end
        end
    end

    -- Solo afecta widgets, no toca HarfordDnDStore.deathSave*: idempotente.
    -- Usado tanto al entrar en estado moribundo como al volver de modo NPC
    -- mientras el jugador sigue muerto.
    local function ApplyDyingVisualState()
        ShowDnDTab("BASE")
        if TabButtons["ATK"] then TabButtons["ATK"]:Disable() end
        if TabButtons["SKL"] then TabButtons["SKL"]:Disable() end

        for _, b in pairs(AbilityButtons) do b:Disable() end

        for key, b in pairs(SaveButtons) do
            if key == "Constitucion" then
                b:ClearAllPoints()
                b:SetPoint("TOP", SEC_SAV, "TOP", 0, -36)
                b:Enable()
                b:Show()
            else
                b:Hide()
            end
        end

        UpdateDyingUI()
    end

    -- Restaura la UI normal sin tocar contadores. Usado al salir de moribundo
    -- y tambien al entrar en modo NPC para "esconder" la UI de muerte temporalmente.
    local function ClearDyingVisualState()
        for _, b in pairs(AbilityButtons) do b:Enable() end
        for _, b in pairs(SaveButtons) do
            b:Show()
            b:Enable()
        end

        local conBtn = SaveButtons["Constitucion"]
        if conBtn then conBtn:SetText(FormatSaveButtonText("CON", "Constitucion")) end
        if Layout3Col then Layout3Col(SEC_SAV, SaveButtons, savKeys, 36) end
        if TabButtons["ATK"] then TabButtons["ATK"]:Enable() end
        if TabButtons["SKL"] then TabButtons["SKL"]:Enable() end

        ShowDnDTab(ActiveTab or "BASE")
        _dsLabel:Hide()
    end

    local function EnterDyingState()
        HarfordDnDStore.deathSaveActive    = true
        HarfordDnDStore.deathSaveSuccesses = 0
        HarfordDnDStore.deathSaveFailures  = 0
        ApplyDyingVisualState()
    end

    local function ExitDyingState()
        HarfordDnDStore.deathSaveActive    = false
        HarfordDnDStore.deathSaveSuccesses = 0
        HarfordDnDStore.deathSaveFailures  = 0
        ClearDyingVisualState()
    end

    -- Funcion publica asignada al forward-declare: se llama al cambiar la salud
    -- y al activar/desactivar contexto NPC (ApplySheetContext/ClearSheetContext).
    RefreshDyingState = function()
        local hp = GetResourceCurrent("health")
        local dying = HarfordDnDStore.deathSaveActive

        -- Modo NPC del DM: la ficha debe verse normal aunque el jugador siga
        -- moribundo. Ocultar la UI de muerte sin resetear contadores; el estado
        -- persistido se recupera al volver al modo jugador.
        if SheetContext.active then
            if dying then ClearDyingVisualState() end
            return
        end

        if hp <= 0 and not dying then
            EnterDyingState()
        elseif hp <= 0 and dying then
            -- Cubre tanto refresh post-tirada como retorno de modo NPC con HP=0.
            ApplyDyingVisualState()
        elseif hp > 0 and dying then
            ExitDyingState()
        end
    end

    -- Tirada especial: usa los mismos bonus/modo que Salv CON, pero computa muerte.
    local function DoDeathSave()
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses("Constitucion")
        local misc = HarfordDnDCalc.GetMiscBonus()
        local mode = HarfordDnDCalc.GetMode()
        local _, a, b = HarfordDnDCalc.RollD20(mode)
        local chosen, ra, rb = HarfordDnDCalc.RollTextWithMode(mode, a, b)
        local total = chosen + base + prof + misc
        local diceStr = rb and (tostring(ra) .. "/" .. tostring(rb) .. "→" .. tostring(chosen)) or tostring(chosen)
        local bonusTxt = HarfordDnDCalc.BonusConcat(base, prof, misc)
        local resultText

        if chosen == 20 then
            resultText = "CRÍTICO"
            HarfordDnDStore.deathSaveSuccesses = (HarfordDnDStore.deathSaveSuccesses or 0) + 2
        elseif chosen == 1 then
            resultText = "PIFIA"
            HarfordDnDStore.deathSaveFailures = (HarfordDnDStore.deathSaveFailures or 0) + 2
        elseif total >= 10 then
            resultText = "Éxito"
            HarfordDnDStore.deathSaveSuccesses = (HarfordDnDStore.deathSaveSuccesses or 0) + 1
        else
            resultText = "Fallo"
            HarfordDnDStore.deathSaveFailures = (HarfordDnDStore.deathSaveFailures or 0) + 1
        end

        -- El marcador acumulado distingue este resultado de una salvacion CON normal.
        HarfordDnDRolls.Broadcast({
            type     = "roll",
            label    = "Salv Muerte " .. FormatDeathCounter(),
            total    = total,
            dice     = diceStr,
            modifiers = bonusTxt,
            critical = resultText,
            mode     = (mode == "adv" and "V") or (mode == "dis" and "D") or "",
            miscBonus = misc,
        })
        ConsumeMode()

        local successes = HarfordDnDStore.deathSaveSuccesses or 0
        local failures  = HarfordDnDStore.deathSaveFailures  or 0

        if successes >= 3 then
            -- AdjustResourceCurrent llamará RefreshDyingState → ExitDyingState,
            -- y también quitará la aura de muerte si estaba activa.
            AdjustResourceCurrent("health", 1)
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff00cc00[Harford]|r ¡Salvación con éxito! Recuperas 1 punto de vida."
            )
        elseif failures >= 3 then
            UpdateDyingUI()  -- muestra "Incapacitado" y deshabilita el botón
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff3333[Harford]|r El personaje queda incapacitado."
            )
        else
            UpdateDyingUI()
        end
    end

    -- Sobreescribir el script del botón CON para manejar el estado moribundo.
    local conBtn = SaveButtons["Constitucion"]
    if conBtn then
        conBtn:SetScript("OnClick", function()
            if HarfordDnDStore.deathSaveActive then
                DoDeathSave()
            else
                local base, prof = HarfordDnDCalc.GetSaveRollBonuses("Constitucion")
                DoRoll("Salv CON", base, prof)
            end
        end)
    end
end  -- fin bloque moribundo

local function RefreshButtons()
    for _, a in ipairs(HarfordDnDData.ABIL) do
        local b = AbilityButtons[a.key]
        if b then b:SetText(FormatAbilityButtonText(a.short, a.key)) end
    end
    for _, a in ipairs(HarfordDnDData.ABIL) do
        local b = SaveButtons[a.key]
        if b then b:SetText(FormatSaveButtonText(a.short, a.key)) end
    end
    for _, s in ipairs(HarfordDnDData.SKILLS) do
        local b = SkillButtons[s.id]
        if b then b:SetText(FormatSkillButtonText(s)) end
    end
    Layout3Col(SEC_ABI, AbilityButtons, abiKeys, 36)
    Layout3Col(SEC_SAV, SaveButtons, savKeys, 36)
end

-- La preparacion de clases/progresion vive ahora en HarfordCharacterPanel.
RefreshButtons()
RefreshSkillLayout()
RefreshTopInfo()
ShowDnDTab("BASE")
HarfordDnDMinimap.Create()

_G.DND5E_ARC_LOADED = true
_G.DND5E_ARC_API = _G.DND5E_ARC_API or {}

_G.DND5E_ARC_API.Refresh = function()
    local playerProfile = UnitName("player") or "default"

    HarfordDnDStore.LoadPersistToRuntime(playerProfile)
    if HarfordDnDProgression and HarfordDnDProgression.SeedFromTRP3 then
        HarfordDnDProgression.SeedFromTRP3(playerProfile)
    end

	_G.HarfordDnDHydratingFromPersist = true
	EnsureDefaults()
	_G.HarfordDnDHydratingFromPersist = false

    if SetMiscBoxFromARC then SetMiscBoxFromARC() end
    if HarfordDnDSetInitBoxFromARC then HarfordDnDSetInitBoxFromARC() end
    if SetModArmaFromARC then SetModArmaFromARC() end
    if SetArmorClassBoxFromARC then RefreshArmorClassBoxes() end
    if RefreshButtons then RefreshButtons() end
    if RefreshSkillLayout then RefreshSkillLayout() end
    if RefreshSheetTitle then RefreshSheetTitle() end
    if RefreshTopInfo then RefreshTopInfo() end
    if SyncWeaponDrop then SyncWeaponDrop() end
    if UpdateWeaponInfoUI then UpdateWeaponInfoUI() end
    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then RefreshResourceFrame() end
    if RefreshTargetResourceFrame then RefreshTargetResourceFrame() end
    if HarfordUnitFrames and HarfordUnitFrames.Refresh then HarfordUnitFrames.Refresh() end
    if HarfordDnDMinimap and HarfordDnDMinimap.Create then HarfordDnDMinimap.Create() end
    if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
    if ShowDnDTab then ShowDnDTab(ActiveTab or "BASE") end
    -- Tras refrescar botones y pestañas, aplicar estado moribundo si corresponde.
    if RefreshDyingState then RefreshDyingState() end
end

_G.DND5E_ARC_API.Toggle = function()
    local f = _G.DND5E_PlayerFrame
    if not f then return end
    local show = not f:IsShown()
    f:SetShown(show)
    if show then
        f:Raise()
        if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
            _G.DND5E_ARC_API.Refresh()
        end
    end
end

if not _G.DND5E_ARC_API._onShowHooked then
    local f = _G.DND5E_PlayerFrame
    if f and f.HookScript then
        f:HookScript("OnShow", function()
            if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
                _G.DND5E_ARC_API.Refresh()
            end
        end)
    end
    _G.DND5E_ARC_API._onShowHooked = true
end

HarfordDnDAPI = HarfordDnDAPI or {}

function HarfordDnDAPI.ExportCurrentProfile()
    local profileName = tostring(HarfordDnDPersistStore.activeProfile or UnitName("player") or "default")
    HarfordDnDStore.SaveCurrentProfileToBank(profileName)
    return profileName, HarfordSync.LoadProfileFromBank(HarfordDnDProfileBank, profileName)
end

function HarfordDnDAPI.ExportProfile(profileName)
    return HarfordSync.LoadProfileFromBank(HarfordDnDProfileBank, profileName)
end

function HarfordDnDAPI.ApplyProfile(profileName, tbl)
    return HarfordDnDProfile.Apply(tbl, profileName)
end

function HarfordDnDAPI.BroadcastConfig(channel, target)
    HarfordDnDStore.EnsurePersist()
    HarfordDnDStore.LoadPersistToRuntime(HarfordDnDPersistStore.activeProfile or (UnitName("player") or "default"))

    local profileName = tostring(HarfordDnDPersistStore.activeProfile or UnitName("player") or "default")
    local tbl = HarfordSync.ReadProfileFromRuntime(HarfordDnDStore.state.runtime, HarfordSync.ProfileKeys.DnD)

    local ok, err = HarfordSync.SendDnDProfile(
        ADDON_PREFIX,
        profileName,
        tbl,
        channel,
        target
    )
    if not ok then return false, err end
    HarfordSync.SendDnDProfFlags(ADDON_PREFIX, profileName, tbl, channel, target)
    if HarfordDnDProgression and HarfordSync.SendDnDClassProgression then
        HarfordSync.SendDnDClassProgression(ADDON_PREFIX, profileName, HarfordDnDProgression.Export(profileName), channel, target)
    end
    return true
end

-- ExportProfileResourcesFromBank vive en HarfordDnDNet.

function HarfordDnDAPI.BroadcastConfigForPlayer(characterName, channel, target)
    characterName = tostring(characterName or "")
    channel = channel or "WHISPER"

    local resolvedTarget = target
    if not resolvedTarget or resolvedTarget == "" then
        resolvedTarget = characterName
    end

    local myShortName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)

    if resolvedTarget == myShortName and myFullName and myFullName ~= "" then
        resolvedTarget = myFullName
    end

    if characterName == "" then
        return false, "Nombre de personaje inválido"
    end

    local tbl = HarfordDnDProfileBank and HarfordDnDProfileBank[characterName]
    if type(tbl) ~= "table" then
        return false, "Perfil no encontrado: " .. tostring(characterName)
    end

    if resolvedTarget == myShortName or (myFullName and resolvedTarget == myFullName) then
        HarfordDnDProfile.Apply(tbl, characterName)
        HarfordDnDProfile.MergeProfFlags(tbl, characterName)

        local resourceTblLocal = HarfordDnDNet.ExportProfileResourcesFromBank(characterName)
        if resourceTblLocal then
            HarfordDnDProfile.ApplyResourceConfig(resourceTblLocal, characterName)
        end

        return true
    end

    -- Mensaje 1: DNDCFG — atributos, salvaciones, misc (cabe en un mensaje de red)
    local ok, err = HarfordSync.SendDnDProfile(
        ADDON_PREFIX,
        characterName,
        tbl,
        channel,
        resolvedTarget
    )

    if not ok then
        return false, err
    end

    -- Mensaje 2: DNDPROF — flags prof/exp de las 18 habilidades (compacto, ~60 bytes).
    -- Se envía siempre aunque todos sean "0" para garantizar un estado limpio en el cliente.
    HarfordSync.SendDnDProfFlags(ADDON_PREFIX, characterName, tbl, channel, resolvedTarget)
    if HarfordDnDProgression and HarfordSync.SendDnDClassProgression then
        local okClass, errClass = HarfordSync.SendDnDClassProgression(
            ADDON_PREFIX,
            characterName,
            HarfordDnDProgression.Export(characterName),
            channel,
            resolvedTarget
        )
        if not okClass then
            return false, errClass
        end
    end

    local resourceTbl = HarfordDnDNet.ExportProfileResourcesFromBank(characterName)
    if resourceTbl then
        local okRes, errRes = HarfordSync.SendResourceConfig(
            ADDON_PREFIX,
            characterName,
            resourceTbl,
            resolvedTarget,
            RESOURCE_PROFILE_KEYS
        )
        if not okRes then
            return false, errRes
        end
    end

    return true
end

function HarfordDnDAPI.BroadcastAll(channel, target)
    local ok, count = HarfordSync.BroadcastProfiles(
        ADDON_PREFIX,
        "DNDCFG",
        HarfordDnDProfileBank,
        HarfordSync.ProfileKeys.DnDBase,
        channel,
        target
    )
    -- DNDPROF masivo: un mensaje compacto por perfil en el banco
    for name, tbl in pairs(HarfordDnDProfileBank or {}) do
        HarfordSync.SendDnDProfFlags(ADDON_PREFIX, name, tbl, channel, target)
        if HarfordDnDProgression and HarfordSync.SendDnDClassProgression then
            HarfordSync.SendDnDClassProgression(ADDON_PREFIX, name, HarfordDnDProgression.Export(name), channel, target)
        end
    end
    return ok, count
end

function HarfordDnDAPI.GetCurrentResources()
    return HarfordDnDNet.ExportCurrentResources()
end

function HarfordDnDAPI.GetResourcesForName(characterName)
    characterName = tostring(characterName or "")
    if characterName == "" then
        return nil
    end

    local myShortName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)

    if characterName == myShortName or (myFullName and characterName == myFullName) then
        return HarfordDnDNet.ExportCurrentResources()
    end

    if HarfordDnDResources and HarfordDnDResources.RemoteCache then
        if HarfordDnDResources.RemoteCache[characterName] then
            return HarfordDnDResources.RemoteCache[characterName]
        end

        local shortName = Ambiguate and Ambiguate(characterName, "short")
        if shortName and HarfordDnDResources.RemoteCache[shortName] then
            return HarfordDnDResources.RemoteCache[shortName]
        end
    end

    return nil
end

function HarfordDnDAPI.RequestResourcesForName(characterName)
    characterName = tostring(characterName or "")
    if characterName == "" then
        return false
    end

    local myShortName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)
    if characterName == myShortName or (myFullName and characterName == myFullName) then
        return true
    end

    return HarfordDnDNet.RequestResourcesFromPlayer(characterName)
end

-- Puente de sync aun requerido por HarfordTurns. Cuando los controles DM de
-- turnos migren a HarfordAdmin, esta emision remota debe moverse con ellos.
function HarfordDnDAPI.AdjustResourceForName(characterName, resourceKey, delta)
    characterName = tostring(characterName or "")
    resourceKey = tostring(resourceKey or "")
    delta = tonumber(delta) or 0
    if characterName == "" or resourceKey == "" or delta == 0 then
        return false, "ajuste invalido"
    end

    local myShortName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)
    if characterName == myShortName or (myFullName and characterName == myFullName) then
        return HarfordDnDNet.SendResourceAdjustToPlayer(myFullName or myShortName, resourceKey, delta)
    end

    return HarfordDnDNet.SendResourceAdjustToPlayer(characterName, resourceKey, delta)
end

-- ─── API de contexto temporal de ficha ────────────────────────────────────────
-- HarfordAdmin puede proporcionar una ficha alternativa para render/tiradas.
-- Este core no busca NPCs, no consulta permisos DM y no crea herramientas admin.

function HarfordDnDAPI.GetPlayerFrame()
    return F
end

function HarfordDnDAPI.HasSheetContext()
    return SheetContext.active
end

function HarfordDnDAPI.ApplySheetContext(context)
    if type(context) ~= "table" then
        return false, "contexto de ficha invalido"
    end

    SheetContext.active = true
    SheetContext.overrides = type(context.overrides) == "table" and context.overrides or {}
    SheetContext.rollName = context.rollName
    SheetContext.rollColor = context.rollColor
    SheetContext.npcSourceGuid = context.npcSourceGuid
    SheetContext.armorClass = tonumber(context.armorClass)
    SheetContext.actions = type(context.actions) == "table" and context.actions or {}
    SheetContext.showActionPanel = context.showActionPanel == true
    SheetContext.kind = context.kind
    SheetContext.lockedSource = context.lockedSource == true
    SheetContext.canAttack = type(context.canAttack) == "function" and context.canAttack or nil
    SheetContext.canDamage = type(context.canDamage) == "function" and context.canDamage or nil
    SheetContext.onAttackAnimation = type(context.onAttackAnimation) == "function" and context.onAttackAnimation or nil
    SheetContext.onDamageRolled = type(context.onDamageRolled) == "function" and context.onDamageRolled or nil
    SheetContext.onArmorClassChanged = type(context.onArmorClassChanged) == "function" and context.onArmorClassChanged or nil
    SheetContext.spellProficiencyBonus = SheetContext.kind == "npc" and tonumber(context.spellProficiencyBonus) or nil
    if FrameTitle and SheetContext.kind == "npc" then
        FrameTitle:SetText(context.titleText or SheetContext.rollName or "Harford DnD 5\194\170 - Ficha")
        local color = context.titleColor or { 1, 0.82, 0 }
        FrameTitle:SetTextColor(color[1] or 1, color[2] or 0.82, color[3] or 0)
    elseif FrameTitle then
        FrameTitle:SetText("Harford DnD 5\194\170 - Ficha")
        FrameTitle:SetTextColor(1, 0.82, 0)
    end
    RefreshMainUI()
    RefreshArmorClassBoxes()
    if RefreshSheetActionPanel then RefreshSheetActionPanel() end
    -- Si el jugador estaba moribundo, oculta visualmente la UI de muerte
    -- sin tocar contadores (el estado persiste hasta que vuelva al modo jugador).
    if RefreshDyingState then RefreshDyingState() end
    return true
end

function HarfordDnDAPI.ClearSheetContext()
    SheetContext.active = false
    SheetContext.overrides = nil
    SheetContext.rollName = nil
    SheetContext.rollColor = nil
    SheetContext.npcSourceGuid = nil
    SheetContext.armorClass = nil
    SheetContext.actions = nil
    SheetContext.showActionPanel = false
    SheetContext.spellProficiencyBonus = nil
    SheetContext.kind = nil
    SheetContext.lockedSource = false
    SheetContext.canAttack = nil
    SheetContext.canDamage = nil
    SheetContext.onAttackAnimation = nil
    SheetContext.onDamageRolled = nil
    SheetContext.onArmorClassChanged = nil
    if RefreshSheetTitle then RefreshSheetTitle() end
    RefreshMainUI()
    RefreshArmorClassBoxes()
    if RefreshSheetActionPanel then RefreshSheetActionPanel() end
    -- Si el jugador sigue moribundo al volver al modo jugador, re-aplicar la UI.
    if RefreshDyingState then RefreshDyingState() end
end

function HarfordDnDAPI.RefreshSheetActionAvailability()
    if RefreshSheetActionPanel then
        RefreshSheetActionPanel(false)
    end
end

function HarfordDnDAPI.UpdateSheetArmorClassForGuid(guid, armorClass)
    if not (SheetContext.active and SheetContext.kind == "npc") then return false end
    guid = tostring(guid or "")
    if guid ~= "" and SheetContext.npcSourceGuid and guid ~= SheetContext.npcSourceGuid then
        return false
    end
    SheetContext.armorClass = math.max(0, math.floor(tonumber(armorClass) or 0))
    RefreshArmorClassBoxes()
    return true
end
-- ─── Fin API de contexto temporal de ficha ────────────────────────────────────

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")
listener:RegisterEvent("PLAYER_FOCUS_CHANGED")

local AddonHandlers = HarfordDnDComm.CreateHandlers({
    ADDON_PREFIX = ADDON_PREFIX,
    EnsurePersist = HarfordDnDStore.EnsurePersist,
    LoadPersistToRuntime = HarfordDnDStore.LoadPersistToRuntime,
    EnsureTargetResourceFrameState = EnsureTargetResourceFrameState,
    CreateDnDMinimapButton = HarfordDnDMinimap.Create,
    PlayerFrame = F,
    TargetResourceFrame = TargetResourceFrame,
    RefreshTargetResourceFrame = RefreshTargetResourceFrame,
    RequestResourcesFromPlayer = HarfordDnDNet.RequestResourcesFromPlayer,
    SendResourceResponseTo = HarfordDnDNet.SendResourceResponseTo,
    SendResourceResponseForProfileTo = HarfordDnDNet.SendResourceResponseForProfileTo,
    ApplyResourceDelta = ApplyResourceDeltaFromRemote,
    ApplyProfileTable = HarfordDnDProfile.Apply,
    MergeProfFlagsTable = HarfordDnDProfile.MergeProfFlags,
    ApplyClassProgression = function(profileName, data)
        if HarfordDnDProgression and HarfordDnDProgression.Import then
            HarfordDnDProgression.Import(profileName, data)
            if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
            if RefreshTopInfo then RefreshTopInfo() end
            if RefreshButtons then RefreshButtons() end
            if UpdateWeaponInfoUI then UpdateWeaponInfoUI() end
            return true
        end
        return false
    end,
    ApplyResourceConfigTable = HarfordDnDProfile.ApplyResourceConfig,
    BuildRuntimeFromConfig = HarfordDnDResources.BuildRuntimeFromConfig,
    CacheRemoteResources = HarfordDnDResources.CacheRemoteResources,
    HandleRollSync = function(message)
        local data = HarfordDnDRolls.Deserialize(message)
        if data then
            HarfordDnDRolls.DisplayInChat(data)
        end
    end,
    -- El DM nos ordena aplicarnos una aura a nosotros mismos
    HandleApplyAuraSelf = function(spellId)
        if HarfordDnDStore.AreAnimationsEnabled and not HarfordDnDStore.AreAnimationsEnabled() then
            return
        end
        if HarfordAuras then
            HarfordAuras.ApplyById(spellId, "self")
            -- Si es la aura de muerte conocida, recordarlo para quitarla al subir HP.
            if spellId == HarfordAuras.GetId("death") then
                HarfordDnDStore.deathAuraActive = true
            end
        end
    end,
    -- Un atacante fallo contra nosotros -> reaccion defensiva local (parry/dodge)
    HandleDefense = function()
        if HarfordDnDCombat and HarfordDnDCombat.PlayLocalDefense then
            HarfordDnDCombat.PlayLocalDefense()
        end
    end,
    -- Un atacante nos golpeo -> animacion de herida local (mod anim 33/34)
    HandleWound = function(isCritical)
        if HarfordDnDCombat and HarfordDnDCombat.PlayLocalWound then
            HarfordDnDCombat.PlayLocalWound(isCritical)
        end
    end,
    RefreshAPI = function()
        if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
            _G.DND5E_ARC_API.Refresh()
        end
    end,
})

listener:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        AddonHandlers.HandlePlayerLogin()
        return
    end
    if event == "PLAYER_TARGET_CHANGED" then
        AddonHandlers.HandlePlayerTargetChanged()
        RefreshArmorClassBoxes()
        if HarfordDnDStore.RefreshWeaponDamageButton then
            HarfordDnDStore.RefreshWeaponDamageButton()
        end
        -- Fase 2 NPC vs NPC: si hay ataque pendiente y el nuevo target es la victima,
        -- aplicar daño (acierto) o esquiva/parry (fallo) automaticamente.
        if HarfordDnDStore.ResolvePendingNpcAttack then
            HarfordDnDStore.ResolvePendingNpcAttack()
        end
        -- El panel NPC depende del target (focus debe diferir del NPC).
        if RefreshSheetActionPanel then RefreshSheetActionPanel(false) end
        return
    end
    if event == "PLAYER_FOCUS_CHANGED" then
        -- Pedir los recursos del focus (jugador ajeno) para cachear su ArmorClass;
        -- al llegar el RES, la rama de resourcesChanged refresca la CA de nuevo.
        if UnitExists and UnitExists("focus") and UnitIsPlayer and UnitIsPlayer("focus")
            and not (UnitIsUnit and UnitIsUnit("focus", "player"))
            and HarfordDnDAPI and HarfordDnDAPI.RequestResourcesForName then
            local focusName = (GetUnitName and GetUnitName("focus", true)) or UnitName("focus")
            if focusName and focusName ~= "" then
                HarfordDnDAPI.RequestResourcesForName(focusName)
            end
        end
        RefreshArmorClassBoxes()
        -- El panel NPC depende del focus (Atacar/Daño Custom contra el focus victima).
        if RefreshSheetActionPanel then RefreshSheetActionPanel(false) end
        return
    end
    local prefix, message, _, sender = ...
    local resourcesChanged = AddonHandlers.HandleAddonMessage(prefix, message, sender)
    -- Refrescar overlays de unitframes solo cuando llegaron datos de recursos remotos.
    -- Evita un Refresh completo en cada mensaje de turnos, loot, reputaciones, tiradas.
    if resourcesChanged and HarfordUnitFrames and HarfordUnitFrames.Refresh then
        HarfordUnitFrames.Refresh()
    end
    if resourcesChanged then
        RefreshArmorClassBoxes()
    end
end)

SLASH_DND5EARC1 = "/FichaHarford"
SlashCmdList["DND5EARC"] = function(msg)
    msg = (msg or ""):lower():gsub("%s+", "")
    if msg == "r" or msg == "refresh" then
        if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
            _G.DND5E_ARC_API.Refresh()
        end
        return
    end
    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Toggle then
        _G.DND5E_ARC_API.Toggle()
    end
end

-- Reaccionar a cambios de configuración: sincronizar TargetResourceFrame y unitframe
if HarfordConfig and HarfordConfig.RegisterChangeListener then
    HarfordConfig.RegisterChangeListener(function()
        RefreshTargetResourceFrame()
        if HarfordUnitFrames and HarfordUnitFrames.Refresh then
            HarfordUnitFrames.Refresh(false)
        end
    end)
end
