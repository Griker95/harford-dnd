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
local RuntimeProfile = HarfordDnDStore.state.runtime

local ParseDice
local WeaponBaseDice
local GetWeaponKey
local GetWeaponDef
local GetVersatileDice
local UpdateWeaponInfoUI
local SyncWeaponDrop
local ApplyShortRest
local ApplyLongRest
local ScheduleMyResourceBroadcast
local AnchorTargetResourceFrame
local DoSpellAttack
local RefreshResourceFrame
local RefreshTargetResourceFrame

local F
local ResourceFrame
local TargetResourceFrame

local EnsureDefaults = function() end

local RESOURCE_ORDER = HarfordDnDResources.ORDER
local ALL_RESOURCE_KEYS = HarfordDnDResources.ALL_KEYS
local ResourceCurKey = HarfordDnDResources.CurKey
local ResourceMaxKey = HarfordDnDResources.MaxKey

local function SyncRuntimeProfileRef()
    RuntimeProfile = (HarfordDnDStore.state and HarfordDnDStore.state.runtime) or {}
end

local function EnsurePersist(profileName)
    HarfordDnDStore.EnsurePersist(profileName)
    SyncRuntimeProfileRef()
end

local function LoadPersistToRuntime(profileName)
    HarfordDnDStore.LoadPersistToRuntime(profileName)
    SyncRuntimeProfileRef()
end

local function SaveCurrentProfileToBank(profileName)
    SyncRuntimeProfileRef()
    return HarfordDnDStore.SaveCurrentProfileToBank(profileName)
end

local function ARCGET(k, default)
    local value = HarfordDnDStore.GetValue(k, default)
    SyncRuntimeProfileRef()
    return value
end

local function ARCSET(k, v)
    if _G.HarfordDnDHydratingFromPersist then
        HarfordDnDStore.state.runtime[k] = tostring(v)
    else
        HarfordDnDStore.SetValue(k, tostring(v))
    end
    SyncRuntimeProfileRef()
end

local function RefreshMainUI()
    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
        _G.DND5E_ARC_API.Refresh()
    end
end

local function ApplyProfileTable(tbl, profileName)
    local ok = HarfordDnDStore.ApplyProfileTable(
        tbl,
        profileName,
        ALL_RESOURCE_KEYS,
        ResourceCurKey,
        ResourceMaxKey,
        EnsureDefaults,
        RefreshMainUI
    )
    SyncRuntimeProfileRef()
    return ok
end

local function ApplyResourceConfigTable(tbl, profileName)
    local ok = HarfordDnDStore.ApplyResourceConfigTable(
        tbl,
        profileName,
        ALL_RESOURCE_KEYS,
        ResourceCurKey,
        ResourceMaxKey,
        EnsureDefaults,
        RefreshMainUI
    )
    SyncRuntimeProfileRef()
    return ok
end

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

local TEX = {
    PARCH  = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
    ROCK   = "Interface\\FrameGeneral\\UI-Background-Rock",
    MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble",
    WHITE  = "Interface\\Buttons\\WHITE8x8",
    BOOK   = "Interface\\Icons\\INV_Misc_Book_09",
    QMARK  = "Interface\\Icons\\inv_misc_dice_02",
    STR    = "Interface\\Icons\\Ability_Warrior_StrengthOfArms",
    SHIELD = "Interface\\Icons\\INV_Shield_06",
    EYE    = "Interface\\Icons\\Ability_EyeOfTheOwl",
    ATK    = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
	CAMPFIRE = "Interface\\Icons\\ability_racial_makecamp",
    HOURGLASS = "Interface\\Icons\\INV_Misc_PocketWatch_01",
}

local TEX_SEC_TOP = TEX.PARCH
local TEX_SEC_ABI = TEX.PARCH
local TEX_SEC_SAV = TEX.ROCK
local TEX_SEC_ATK = TEX.PARCH
local TEX_SEC_SKL = TEX.PARCH

local UI = {
    FRAME_W = 420,
    FRAME_H = 405,
    FRAME_X = -210,
    FRAME_Y = 0,

    SEC_X = 14,
    SEC_W = 392,

    TOP_Y = -44,
    TOP_H = 126,

    TAB_Y = -176,
    TAB_H = 28,

    PANEL_Y = -208,
    PANEL_H = 183,
}

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

local function SerializeRoll(data)
    return string.format("%s^%s^%s^%d^%s^%s^%s^%s^%s",
        data.type or "roll",
        UnitName("player") or "Unknown",
        data.label or "",
        data.total or 0,
        data.dice or "",
        data.modifiers or "",
        data.critical or "",
        data.mode or "",
        tostring(data.miscBonus or "")
    )
end

local function DeserializeRoll(msg)
    local parts = {strsplit("^", msg)}
    if #parts < 8 then return nil end
    return {
        type = parts[1],
        player = parts[2],
        label = parts[3],
        total = tonumber(parts[4]) or 0,
        dice = parts[5],
        modifiers = parts[6],
        critical = parts[7],
        mode = parts[8],
        miscBonus = parts[9],
    }
end

local function DisplayRollInChat(data)
    if not data then return end

    local COLOR_HEADER = "|cff00ccff"
    local COLOR_PLAYER = "|cffffcc00"
    local COLOR_ROLL = "|cff66ccff"
    local COLOR_DETAIL = "|cffb0b0b0"
    local COLOR_CRIT = "|cff00ff00"
    local COLOR_FUMBLE = "|cffff3333"

    local parts = {}
    local playerName = data.player or UnitName("player") or "Unknown"
    table.insert(parts, COLOR_HEADER .. "[D&D]" .. ENDCLR .. " " .. COLOR_PLAYER .. playerName .. ENDCLR)

    local modeStr = ""
    if data.mode == "V" then
        modeStr = " " .. COLOR_CRIT .. "[V]" .. ENDCLR
    elseif data.mode == "D" then
        modeStr = " " .. COLOR_FUMBLE .. "[D]" .. ENDCLR
    end

    local labelStr = parts[1] .. modeStr .. " " .. (data.label or "Tirada") .. ": " .. COLOR_ROLL .. tostring(data.total or 0) .. ENDCLR

    local damageTypeStr = ""
    if data.type == "damage" and data.modifiers and data.modifiers ~= "" then
        damageTypeStr = " " .. data.modifiers
    end

    local critStr = ""
    if data.critical == "CRÍTICO" then
        critStr = " " .. COLOR_CRIT .. "CRÍTICO" .. ENDCLR
    elseif data.critical == "PIFIA" then
        critStr = " " .. COLOR_FUMBLE .. "PIFIA" .. ENDCLR
    end

	local detailStr = ""
	local miscOutsideStr = ""

	if data.dice and data.dice ~= "" then
		if data.type ~= "damage" and data.modifiers and data.modifiers ~= "" then
			local modifiersText = tostring(data.modifiers or "")
			local miscRaw = tonumber(data.miscBonus) or 0

			if miscRaw ~= 0 then
				local miscText = fmtSigned(miscRaw)
				local pos = string.find(modifiersText, miscText, 1, true)

				if pos then
					modifiersText = string.sub(modifiersText, 1, pos - 1)
						.. string.sub(modifiersText, pos + string.len(miscText))
				end

				miscOutsideStr = ColorSigned(miscRaw)
			end

			detailStr = " " .. COLOR_DETAIL .. "(" .. data.dice .. modifiersText .. ")" .. ENDCLR .. miscOutsideStr
		else
			detailStr = " " .. COLOR_DETAIL .. "(" .. data.dice .. ")" .. ENDCLR
		end
	end

    local output = labelStr .. damageTypeStr .. critStr .. detailStr
    DEFAULT_CHAT_FRAME:AddMessage(output)
    if ChatFrame2 then
        ChatFrame2:AddMessage(output)
    end
end

local function BroadcastRoll(rollData)
    local channel = BestChannel()
    if channel then
        SendPrefix(ADDON_PREFIX, SerializeRoll(rollData), channel)
    end
    DisplayRollInChat({
        type = rollData.type,
        player = UnitName("player"),
        label = rollData.label,
        total = rollData.total,
        dice = rollData.dice,
        modifiers = rollData.modifiers,
        critical = rollData.critical,
        mode = rollData.mode,
        miscBonus = rollData.miscBonus,
    })
end

local function AbilityMod(score)
    score = toN(score, 10)
    return math.floor((score - 10) / 2)
end

local function RollDie(sides)
    return math.random(1, sides)
end

local function RollD20(mode)
    local a, b = RollDie(20), RollDie(20)
    if mode == "adv" then return math.max(a, b), a, b end
    if mode == "dis" then return math.min(a, b), a, b end
    return a, a, nil
end

local ABIL = {
    { key = "Fuerza",       short = "FUE" },
    { key = "Destreza",     short = "DES" },
    { key = "Constitucion", short = "CON" },
    { key = "Inteligencia", short = "INT" },
    { key = "Sabiduria",    short = "SAB" },
    { key = "Carisma",      short = "CAR" },
}

local SKILLS = {
    { name="Acrobacias", ability="Destreza", id="Acrobacias" },
    { name="Atletismo", ability="Fuerza", id="Atletismo" },
    { name="Conocimiento Arcano", ability="Inteligencia", id="Arcano" },
    { name="Engaño", ability="Carisma", id="Engano" },
    { name="Historia", ability="Inteligencia", id="Historia" },
    { name="Interpretación", ability="Carisma", id="Interpretacion" },
    { name="Intimidación", ability="Carisma", id="Intimidacion" },
    { name="Investigación", ability="Inteligencia", id="Investigacion" },
    { name="Juego de Manos", ability="Destreza", id="JuegoManos" },
    { name="Medicina", ability="Sabiduria", id="Medicina" },
    { name="Naturaleza", ability="Inteligencia", id="Naturaleza" },
    { name="Percepción", ability="Sabiduria", id="Percepcion" },
    { name="Perspicacia", ability="Sabiduria", id="Perspicacia" },
    { name="Persuasión", ability="Carisma", id="Persuasion" },
    { name="Religión", ability="Inteligencia", id="Religion" },
    { name="Sigilo", ability="Destreza", id="Sigilo" },
    { name="Supervivencia", ability="Sabiduria", id="Supervivencia" },
    { name="Trato con Animales", ability="Sabiduria", id="Animales" },
}

local WEAPONS = {
    { key="Desarmado", cat="Especial", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={} },
    { key="Arco corto", cat="Simple", mode="Ranged", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Munición (80/320)","Dos manos"} },
    { key="Ballesta ligera", cat="Simple", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (80/320)","Recarga","Dos manos"} },
    { key="Bastón", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="contundente", addAbi=true, props={"Versátil (1d8)"} },
    { key="Clava", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Ligera"} },
    { key="Daga", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Ligera","Sutil","Arrojadiza (20/60)"} },
    { key="Dardo", cat="Simple", mode="Ranged", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Sutil","Arrojadiza (20/60)"} },
    { key="Gran clava", cat="Simple", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Dos manos"} },
    { key="Hacha de mano", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Ligera","Arrojadiza (20/60)"} },
    { key="Honda", cat="Simple", mode="Ranged", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Munición (30/120)"} },
    { key="Hoz", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Ligera"} },
    { key="Jabalina", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Arrojadiza (30/120)"} },
    { key="Lanza", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Versátil (1d8)","Arrojadiza (20/60)"} },
    { key="Martillo ligero", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Ligera","Arrojadiza (20/60)"} },
    { key="Maza", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="contundente", addAbi=true, props={} },
    { key="Alabarda", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Arco largo", cat="Marcial", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (150/600)","Pesada","Dos manos"} },
    { key="Ballesta de mano", cat="Marcial", mode="Ranged", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Munición (30/120)","Ligera","Recarga"} },
    { key="Ballesta pesada", cat="Marcial", mode="Ranged", dmgN=1, dmgS=10, dmgType="perforante", addAbi=true, props={"Munición (100/400)","Pesada","Recarga","Dos manos"} },
    { key="Cerbatana", cat="Marcial", mode="Ranged", dmgN=1, dmgS=1, dmgType="perforante", addAbi=false, props={"Munición (25/100)","Recarga"} },
    { key="Cimitarra", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Espada corta", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Espada larga", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Versátil (1d10)"} },
    { key="Espadón", cat="Marcial", mode="Melee", dmgN=2, dmgS=6, dmgType="cortante", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Estoque", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Sutil"} },
    { key="Flagelo", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={} },
    { key="Gran hacha", cat="Marcial", mode="Melee", dmgN=1, dmgS=12, dmgType="cortante", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Guja", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Hacha de batalla", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Versátil (1d10)"} },
    { key="Lanza de caballería", cat="Marcial", mode="Melee", dmgN=1, dmgS=12, dmgType="perforante", addAbi=true, props={"Alcance","Especial"} },
    { key="Látigo", cat="Marcial", mode="Melee", dmgN=1, dmgS=4, dmgType="cortante", addAbi=true, props={"Sutil","Alcance"} },
    { key="Lucero del alba", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={} },
    { key="Martillo de guerra", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Versátil (1d10)"} },
    { key="Mazo de guerra", cat="Marcial", mode="Melee", dmgN=2, dmgS=6, dmgType="contundente", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Pica", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="perforante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Pico de guerra", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={} },
    { key="Red", cat="Marcial", mode="Ranged", dmgN=0, dmgS=0, dmgType="", addAbi=false, props={"Especial","Arrojadiza (5/15)"} },
    { key="Tridente", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Versátil (1d8)","Arrojadiza (20/60)"} },
	{ key="Pistola", cat="De fuego", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (30/120)", "Retumbante", "Recarga", "Ligera"} },
	{ key="Rifle", cat="De fuego", mode="Ranged", dmgN=1, dmgS=12, dmgType="perforante", addAbi=true, props={"Munición (60/240)", "Retumbante", "Recarga", "Pesada", "Dos manos"} },
	{ key="Escopeta", cat="De fuego", mode="Ranged", dmgN=2, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (15/60)", "Retumbante", "Recarga", "Dos manos"} },
	{ key="Martillo arrojadizo enano", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Arrojadiza (20/60)"} },
	{ key="Espada quel'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Sutil","Versátil (1d10)"} },
	{ key="Espada lunar kal'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Sutil","Versátil (1d10)"} },
	{ key="Guja lunar kal'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera","Arrojadiza (60/120)"} },
	{ key="Doble hoja sin'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Sutil","Dos manos"} },
	{ key="Alabarda tauren", cat="Racial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Pesada","Alcance","Dos manos"} },
	{ key="Totem de guerra tauren", cat="Racial", mode="Melee", dmgN=2, dmgS=8, dmgType="contundente", addAbi=true, props={"Pesada","Dos manos"} },
	{ key="Garra de guerra orca", cat="Racial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera"} },
	{ key="Guja de guerra", cat="Especial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Arrojadiza (20/60)","Versátil (1d10)"} },
	{ key="Aquajet", cat="Especial", mode="Ranged", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Municion (20/60)","Recarga", "Especial"} },
}

local function GetWeaponMenuGroups()
    local groupOrder = {
        "Simple",
        "Marcial",
        "De fuego",
        "Racial",
        "Otros",
    }

    local groupLabels = {
        ["Simple"] = "Armas simples",
        ["Marcial"] = "Armas marciales",
        ["De fuego"] = "Armas de fuego",
        ["Racial"] = "Armas raciales",
        ["Otros"] = "Otros",
    }

    local groupsByKey = {}
    local groups = {}

    for _, key in ipairs(groupOrder) do
        local group = {
            key = key,
            text = groupLabels[key] or key,
            items = {},
        }
        groupsByKey[key] = group
        table.insert(groups, group)
    end

    for _, w in ipairs(WEAPONS) do
        local cat = w.cat or "Otros"
        local group = groupsByKey[cat] or groupsByKey["Otros"]
        table.insert(group.items, w)
    end

    for _, group in ipairs(groups) do
        table.sort(group.items, function(a, b)
            return tostring(a.key) < tostring(b.key)
        end)
    end

    return groups
end


local RESOURCE_DEFS = HarfordDnDResources.DEFS
local RESOURCE_PROFILE_KEYS = HarfordDnDResources.PROFILE_KEYS
local RESOURCE_RUNTIME_KEYS = HarfordDnDResources.RUNTIME_KEYS


EnsureDefaults = function()
    if ARCGET("BonusCompetencia", nil) == nil then ARCSET("BonusCompetencia", "2") end
    if ARCGET("ModoTirada", nil) == nil then ARCSET("ModoTirada", "normal") end
    if ARCGET("BonoSituacional", nil) == nil then ARCSET("BonoSituacional", "0") end
    if ARCGET("ModIniciativa", nil) == nil then ARCSET("ModIniciativa", "0") end
    if ARCGET("AtributoConjuro", nil) == nil then ARCSET("AtributoConjuro", "Inteligencia") end
    if ARCGET("ArmaSeleccionada", nil) == nil then ARCSET("ArmaSeleccionada", "Desarmado") end
    if ARCGET("ModArma", nil) == nil then ARCSET("ModArma", "0") end
    if ARCGET("Versatil", nil) == nil then ARCSET("Versatil", "0") end
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

    for _, a in ipairs(ABIL) do
        if ARCGET(a.key, nil) == nil then ARCSET(a.key, "10") end
        if ARCGET("Salv_" .. a.key, nil) == nil then ARCSET("Salv_" .. a.key, "0") end
    end

    for _, s in ipairs(SKILLS) do
        if ARCGET("Hab_" .. s.id .. "_Prof", nil) == nil then ARCSET("Hab_" .. s.id .. "_Prof", "0") end
        if ARCGET("Hab_" .. s.id .. "_Exp", nil) == nil then ARCSET("Hab_" .. s.id .. "_Exp", "0") end
    end
end

local function GetPB() return toN(ARCGET("BonusCompetencia", "2"), 2) end
local function GetMode() return ARCGET("ModoTirada", "normal") end
local function GetMiscBonus() return toN(ARCGET("BonoSituacional", "0"), 0) end
function HarfordDnDGetInitiativeMod() return toN(ARCGET("ModIniciativa", "0"), 0) end
local function GetAbilityScore(key) return toN(ARCGET(key, "10"), 10) end
local function GetAbilityMod(key) return AbilityMod(GetAbilityScore(key)) end
local function GetSaveProf(abilityKey) return toN(ARCGET("Salv_" .. abilityKey, "0"), 0) == 1 end
local function GetWeaponMod() return toN(ARCGET("ModArma", "0"), 0) end
local function GetVersatileActive() return toN(ARCGET("Versatil", "0"), 0) == 1 end

local function GetResourceCurrent(key)
    return toN(ARCGET(ResourceCurKey(key), "0"), 0)
end

local function GetResourceMax(key)
    return toN(ARCGET(ResourceMaxKey(key), "0"), 0)
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

local function BuildActiveResourcePayload(readValueFn, options)
    return HarfordDnDResources.BuildPayloadFromRuntime(readValueFn, options)
end

local function ExportCurrentResources()
    EnsurePersist()
    local out = BuildActiveResourcePayload(function(key)
        return ARCGET(key, "0")
    end)
    return out
end

local function GetRemoteResourceValue(tbl, key)
    if not tbl then return 0 end
    return toN(tbl[key], 0)
end

local function RemoteResourceExists(tbl, resourceKey)
    if not tbl then return false end
    local cur = GetRemoteResourceValue(tbl, ResourceCurKey(resourceKey))
    local max = GetRemoteResourceValue(tbl, ResourceMaxKey(resourceKey))
    return HarfordDnDResources.Exists(resourceKey, cur, max)
end

local function SendResourceResponseTo(targetName)
    if not targetName or targetName == "" then
        return false
    end

    local profileName = tostring(HarfordDnDPersistStore.activeProfile or UnitName("player") or "default")

    local tbl, keysToSend = BuildActiveResourcePayload(function(key)
        return ARCGET(key, "0")
    end)

    return HarfordSync.SendResourceResponse(
        ADDON_PREFIX,
        profileName,
        tbl,
        targetName,
        keysToSend
    )
end

local function SendResourceResponseForProfileTo(profileName, targetName)
    if not targetName or targetName == "" then
        return false
    end

    local resolvedProfile = tostring(profileName or HarfordDnDPersistStore.activeProfile or UnitName("player") or "default")
    EnsurePersist(resolvedProfile)

    local profile = HarfordDnDPersistStore.profiles and HarfordDnDPersistStore.profiles[resolvedProfile]
    if type(profile) ~= "table" then
        profile = {}
    end

    local tbl, keysToSend = BuildActiveResourcePayload(function(key)
        return profile[key] or "0"
    end)

    return HarfordSync.SendResourceResponse(
        ADDON_PREFIX,
        resolvedProfile,
        tbl,
        targetName,
        keysToSend
    )
end

local function RequestResourcesFromPlayer(targetName)
    local requester = GetUnitName and GetUnitName("player", true) or UnitName("player") or "default"
    return HarfordSync.SendResourceRequest(ADDON_PREFIX, requester, targetName)
end

local function SendResourceAdjustToPlayer(targetName, resourceKey, delta)
    return HarfordSync.SendResourceAdjust(ADDON_PREFIX, resourceKey, delta, targetName)
end

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
            return BuildActiveResourcePayload(function(key)
                return ARCGET(key, "0")
            end)
        end,
        RESOURCE_RUNTIME_KEYS,
        function()
            return BestChannel()
        end
    )
end

local function GetSkillProfBonus(skill)
    local pb = GetPB()
    local profFlag = toN(ARCGET("Hab_"..skill.id.."_Prof", "0"), 0)
    local expFlag  = toN(ARCGET("Hab_"..skill.id.."_Exp", "0"), 0)
    if expFlag == 1 then return 2 * pb end
    if profFlag == 1 then return pb end
    return 0
end

local function RollTextWithMode(mode, a, b)
    if mode == "adv" then
        return math.max(a, b), a, b, "(V) "
    elseif mode == "dis" then
        return math.min(a, b), a, b, "(D) "
    else
        return a, a, nil, ""
    end
end

local function GetCritTag(mode, a, b)
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

local function BonusConcat(base, prof, misc)
    local parts = {}
    if base ~= 0 then parts[#parts+1] = fmtSigned(base) end
    if prof ~= 0 then parts[#parts+1] = fmtSigned(prof) end
    if misc ~= 0 then parts[#parts+1] = fmtSigned(misc) end
    return table.concat(parts, "")
end

local function DoRoll(label, baseBonus, profBonus)
    baseBonus = toN(baseBonus, 0)
    profBonus = toN(profBonus, 0)
    local miscBonus = GetMiscBonus()

    local mode = GetMode()
    local _, a, b = RollD20(mode)
    local chosen, ra, rb = RollTextWithMode(mode, a, b)
    local critTag = GetCritTag(mode, a, b)
    local totalBonus = baseBonus + profBonus + miscBonus
    local total = chosen + totalBonus
    local bonusTxt = BonusConcat(baseBonus, profBonus, miscBonus)

    local diceStr
    if rb then
        diceStr = tostring(ra) .. "/" .. tostring(rb) .. "→" .. tostring(chosen)
    else
        diceStr = tostring(chosen)
    end

    BroadcastRoll({
        type = "roll",
        label = label,
        total = total,
        dice = diceStr,
        modifiers = bonusTxt,
        critical = critTag,
        mode = (mode == "adv" and "V") or (mode == "dis" and "D") or "",
        miscBonus = miscBonus,
    })
end

local function RollWeaponDamage(def, abilKey)
    if not def or not def.dmgN or not def.dmgS or def.dmgN == 0 or def.dmgS == 0 then
        BroadcastRoll({
            type = "damage",
            label = "Daño " .. (def and def.key or "???"),
            total = 0,
            dice = "-",
            modifiers = "",
            critical = "",
            mode = ""
        })
        return
    end

    local diceStr = WeaponBaseDice(def)
    local n, sides = ParseDice(diceStr)
    if not n or not sides then
        BroadcastRoll({
            type = "damage",
            label = "Daño " .. def.key,
            total = 0,
            dice = "-",
            modifiers = "",
            critical = "",
            mode = ""
        })
        return
    end

    local abiMod = (def.addAbi and abilKey) and GetAbilityMod(abilKey) or 0
    local wmod = GetWeaponMod()

    local rolls, sum = {}, 0
    for i=1,n do
        local r = RollDie(sides)
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

    BroadcastRoll({
        type = "damage",
        label = "Daño " .. def.key,
        total = total,
        dice = n .. "d" .. sides .. ": " .. rollList .. bonusTxt,
        modifiers = dtype,
        critical = "",
        mode = ""
    })
end

local function GetSpellDC()
    local abil = ARCGET("AtributoConjuro", "Carisma")
    local mod = GetAbilityMod(abil)
    return 8 + GetPB() + mod, abil
end

local function GetSpellAbilityKey()
    local v = ARCGET("AtributoConjuro", "Inteligencia")
    for _, a in ipairs(ABIL) do
        if a.key == v then return v end
    end
    return "Inteligencia"
end

local function SendSpellDC()
    local dc, abil = GetSpellDC()
    local pb = GetPB()
    local mod = GetAbilityMod(abil)
    local short = ""
    for _, a in ipairs(ABIL) do if a.key == abil then short = a.short break end end
    local parts = {"8"}
    if pb ~= 0 then parts[#parts+1] = fmtSigned(pb) end
    if mod ~= 0 then parts[#parts+1] = fmtSigned(mod) end

    BroadcastRoll({
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
    local score = GetAbilityScore(abilityKey)
    local mod = GetAbilityMod(abilityKey)
    return ("%s %d %s"):format(short, score, ColorSigned(mod))
end

local function FormatSaveButtonText(short, abilityKey)
    local base = GetAbilityMod(abilityKey)
    local prof = GetSaveProf(abilityKey) and GetPB() or 0
    local total = base + prof
    return ("Salv %s %s"):format(short, ColorSigned(total))
end

local function FormatSkillButtonText(skill)
    local base = GetAbilityMod(skill.ability)
    local prof = GetSkillProfBonus(skill)
    local total = base + prof
    return ("%s %s"):format(skill.name, ColorSigned(total))
end

local function SetFrameBackground(frame, texturePath, alpha)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -13)
    bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 7)
    bg:SetTexture(texturePath)
    bg:SetAlpha(alpha or 1)
    return bg
end

local function CreateSection(parent, titleText, iconPath, x, y, w, h, bgTexture, bgAlpha)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    section:SetSize(w, h)

    local bg = section:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(section)
    bg:SetTexture(bgTexture or TEX.PARCH)
    bg:SetAlpha(bgAlpha or 0.9)

    local border = section:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", 0, 0)
    border:SetTexture(TEX.WHITE)
    border:SetAlpha(0.10)

    local header = CreateFrame("Frame", nil, section)
    header:SetPoint("TOPLEFT", 8, -6)
    header:SetPoint("TOPRIGHT", -8, -6)
    header:SetHeight(20)

    local icon
    if iconPath then
        icon = header:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 0, 0)
        icon:SetTexture(iconPath)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("LEFT", icon and 20 or 0, 0)
    title:SetText(titleText or "")

    local sep = section:CreateTexture(nil, "BORDER")
    sep:SetPoint("TOPLEFT", 8, -28)
    sep:SetPoint("TOPRIGHT", -8, -28)
    sep:SetHeight(1)
    sep:SetTexture(TEX.WHITE)
    sep:SetAlpha(0.20)

    return section
end

local function MakeButton(parent, text, w, h, x, y, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
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
        F:SetPoint("CENTER", UIParent, "CENTER", UI.FRAME_X, UI.FRAME_Y)
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

local function EnsureMinimapState()
    HarfordDnDMinimapSettings = HarfordDnDMinimapSettings or {}
    if HarfordDnDMinimapSettings.angle == nil then HarfordDnDMinimapSettings.angle = 220 end
    if HarfordDnDMinimapSettings.hide == nil then HarfordDnDMinimapSettings.hide = false end
end

local function UpdateMinimapButtonPosition(btn)
    EnsureMinimapState()

    local angle = math.rad(HarfordDnDMinimapSettings.angle or 220)

    -- radio más conservador para que no se salga del anillo
    local radius = 76

    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateDnDMinimapButton()
    EnsureMinimapState()

    if _G.HarfordDnDMinimapButton then
        _G.HarfordDnDMinimapButton:SetShown(not HarfordDnDMinimapSettings.hide)
        UpdateMinimapButtonPosition(_G.HarfordDnDMinimapButton)
        return
    end

    local btn = CreateFrame("Button", "HarfordDnDMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:EnableMouse(true)
    btn:SetFrameStrata("MEDIUM")

    local background = btn:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", 0, 1)
    btn.background = background

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Inv_tabard_duelersguild")
    icon:SetSize(17, 17)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    btn.icon = icon

    local innerHighlight = btn:CreateTexture(nil, "HIGHLIGHT")
    innerHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    innerHighlight:SetBlendMode("ADD")
    innerHighlight:SetAlpha(0.75)
    innerHighlight:SetSize(22, 22)
    innerHighlight:SetPoint("CENTER", 0, 1)
    btn.innerHighlight = innerHighlight

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    btn.overlay = overlay

    local function SetIconPressed(self, pressed)
        if not self.icon then return end
        self.icon:ClearAllPoints()
        if pressed then
            self.icon:SetPoint("CENTER", 1, 0)
        else
            self.icon:SetPoint("CENTER", 0, 1)
        end
    end

    local function UpdateAngleFromCursor(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        px = px / scale
        py = py / scale

        local angle = math.deg(math.atan2(py - my, px - mx))
        HarfordDnDMinimapSettings.angle = angle
        UpdateMinimapButtonPosition(self)
    end

    btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Ficha Harford", 1, 0.82, 0)
		GameTooltip:AddLine("Click izquierdo: abrir/cerrar ficha", 1, 1, 1)
		GameTooltip:AddLine("Click derecho: reiniciar posiciones de los marcos", 1, 1, 1)
		GameTooltip:AddLine("Arrastrar: mover botón", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("/FichaHarford minimap show", 0.7, 0.9, 0.7)
		GameTooltip:AddLine("/FichaHarford minimap hide", 0.7, 0.9, 0.7)
		GameTooltip:Show()
	end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        SetIconPressed(self, false)
    end)

    btn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            SetIconPressed(self, true)
        end
    end)

    btn:SetScript("OnMouseUp", function(self)
        SetIconPressed(self, false)
    end)

	btn:SetScript("OnClick", function(_, button)
		if button == "LeftButton" then
			if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Toggle then
				_G.DND5E_ARC_API.Toggle()
			end
		elseif button == "RightButton" then
			ResetAllFramePositions()
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HarfordDnD]|r Posiciones de los marcos reiniciadas.")
		end
	end)

    btn:SetScript("OnDragStart", function(self)
        SetIconPressed(self, false)
        self:SetScript("OnUpdate", UpdateAngleFromCursor)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        SetIconPressed(self, false)
        UpdateAngleFromCursor(self)
    end)

    UpdateMinimapButtonPosition(btn)
    btn:SetShown(not HarfordDnDMinimapSettings.hide)
end

do
local initialProfile = UnitName("player") or "default"
LoadPersistToRuntime(initialProfile)

F = CreateFrame("Frame", "DND5E_PlayerFrame", UIParent, "BackdropTemplate")
F:SetSize(UI.FRAME_W, UI.FRAME_H)
F:SetPoint("CENTER", UIParent, "CENTER", UI.FRAME_X, UI.FRAME_Y)
F:SetMovable(true)
F:EnableMouse(true)
F:RegisterForDrag("LeftButton")
F:SetScript("OnDragStart", F.StartMoving)
F:SetScript("OnDragStop", F.StopMovingOrSizing)
F:SetFrameStrata("DIALOG")
F:SetFrameLevel(100)
F:Hide()

SetFrameBackground(F, TEX.MARBLE, 0.95)

local mainBorder = CreateFrame("Frame", nil, F, "DialogBorderTemplate")
mainBorder:SetAllPoints(F)
mainBorder:SetFrameStrata(F:GetFrameStrata())
mainBorder:SetFrameLevel(F:GetFrameLevel() + 5)

local title = F:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -15)
title:SetText("Harford DnD 5º – Ficha Jugador")

local restButton = CreateFrame("Button", nil, F)
restButton:SetSize(20, 20)
restButton:SetPoint("TOPLEFT", 18, -15)

local titleIcon = restButton:CreateTexture(nil, "ARTWORK")
titleIcon:SetAllPoints()
titleIcon:SetTexture(TEX.CAMPFIRE)
titleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

HarfordDnDTurnButton = CreateFrame("Button", nil, F)
HarfordDnDTurnButton:SetSize(20, 20)
HarfordDnDTurnButton:SetPoint("LEFT", restButton, "RIGHT", 5, 0)

HarfordDnDTurnIcon = HarfordDnDTurnButton:CreateTexture(nil, "ARTWORK")
HarfordDnDTurnIcon:SetAllPoints()
HarfordDnDTurnIcon:SetTexture(TEX.HOURGLASS)
HarfordDnDTurnIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local RestMenu = CreateFrame("Frame", "HarfordDnDRestMenu", F, "BackdropTemplate")
RestMenu:SetSize(150, 70)
RestMenu:SetPoint("TOPLEFT", F, "TOPLEFT", 12, -38)
RestMenu:SetFrameStrata("DIALOG")
RestMenu:SetFrameLevel(F:GetFrameLevel() + 30)
RestMenu:Hide()

SetFrameBackground(RestMenu, TEX.MARBLE, 0.96)

local restBorder = CreateFrame("Frame", nil, RestMenu, "DialogBorderTemplate")
restBorder:SetAllPoints(RestMenu)
restBorder:SetFrameStrata(RestMenu:GetFrameStrata())
restBorder:SetFrameLevel(RestMenu:GetFrameLevel() + 5)

local shortRestBtn = MakeButton(RestMenu, "Descanso corto", 120, 22, 15, -12, function()
    RestMenu:Hide()
    ApplyShortRest()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HarfordDnD]|r Descanso corto")
end)

local longRestBtn = MakeButton(RestMenu, "Descanso largo", 120, 22, 15, -38, function()
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

SetFrameBackground(ResourceFrame, TEX.MARBLE, 0.95)

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

SetFrameBackground(TargetResourceFrame, TEX.MARBLE, 0.92)

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
    row.bg:SetTexture(TEX.WHITE)
    row.bg:SetVertexColor(0.08, 0.08, 0.08, 0.95)

    row.border = row.bar:CreateTexture(nil, "BORDER")
    row.border:SetAllPoints()
    row.border:SetTexture(TEX.WHITE)
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
    row.bg:SetTexture(TEX.WHITE)
    row.bg:SetVertexColor(0.08, 0.08, 0.08, 0.95)

    row.border = row.bar:CreateTexture(nil, "BORDER")
    row.border:SetAllPoints()
    row.border:SetTexture(TEX.WHITE)
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
    return cur
end

local function ApplyResourceDeltaFromRemote(resourceKey, delta, sender)
    resourceKey = tostring(resourceKey or "")
    delta = tonumber(delta) or 0
    if resourceKey ~= "health" or delta == 0 then
        return false
    end

    AdjustResourceCurrent(resourceKey, delta)
    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then
        RefreshResourceFrame()
    end
    if RefreshTargetResourceFrame then
        RefreshTargetResourceFrame()
    end
    if sender and sender ~= "" then
        SendResourceResponseTo(sender)
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

local function AttachHealthButtonTooltip(button, delta)
    if not button then return end

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if delta and delta > 0 then
            GameTooltip:SetText("Añadir salud", 1, 0.82, 0)
        else
            GameTooltip:SetText("Quitar salud", 1, 0.82, 0)
        end
        GameTooltip:AddLine("Click: modifica Salud", 1, 1, 1)
        GameTooltip:AddLine("Shift + Click: modifica Vida temporal", 0.75, 0.9, 1)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
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

				AdjustResourceCurrent(targetKey, -1)
				UpdateResourceRow(row, key)
				RefreshResourceFrame()
			end)

			row.plus:SetScript("OnClick", function()
				local targetKey = key

				if key == "health" and IsShiftClickDown() then
					targetKey = "temp_health"
				end

				AdjustResourceCurrent(targetKey, 1)
				UpdateResourceRow(row, key)
				RefreshResourceFrame()
			end)

			if key == "health" then
				AttachHealthButtonTooltip(row.minus, -1)
				AttachHealthButtonTooltip(row.plus, 1)
			else
				row.minus:SetScript("OnEnter", nil)
				row.minus:SetScript("OnLeave", nil)
				row.plus:SetScript("OnEnter", nil)
				row.plus:SetScript("OnLeave", nil)
			end

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
        tbl = ExportCurrentResources()
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

    local visibleIndex = 0

    for _, key in ipairs(RESOURCE_ORDER) do
        if RemoteResourceExists(tbl, key) then
            visibleIndex = visibleIndex + 1

            local row = TargetResourceFrame.rows[visibleIndex]
            if not row then
                row = CreateTargetResourceRow(TargetResourceFrame, visibleIndex)
                TargetResourceFrame.rows[visibleIndex] = row
            end

            local def = RESOURCE_DEFS[key]
            local cur = GetRemoteResourceValue(tbl, ResourceCurKey(key))
            local max = GetRemoteResourceValue(tbl, ResourceMaxKey(key))

            if key == "temp_health" then
                max = math.max(cur, max, 1)
            else
                max = math.max(max, 1)
                if cur > max then cur = max end
            end

            row.label:SetText(def.label)

            if key == "health" then
                local temp = GetRemoteResourceValue(tbl, ResourceCurKey("temp_health"))
                if temp > 0 then
                    row.value:SetText(tostring(cur) .. " (+" .. tostring(temp) .. ")/" .. tostring(max))
                else
                    row.value:SetText(tostring(cur) .. "/" .. tostring(max))
                end
            else
                row.value:SetText(tostring(cur) .. "/" .. tostring(max))
            end

            row.bar:SetMinMaxValues(0, max)
            row.bar:SetStatusBarColor(def.color[1], def.color[2], def.color[3], 1)
            row.bar:SetValue(cur)
            row.bar:Show()
			
			if key == "health" and row.tempFill then
				local temp = GetRemoteResourceValue(tbl, ResourceCurKey("temp_health"))
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
    secs.TOP = CreateSection(frame, "Bonificadores", TEX.QMARK, UI.SEC_X, UI.TOP_Y, UI.SEC_W, UI.TOP_H, TEX_SEC_TOP, 0.95)
    secs.ABI = CreateSection(frame, "Características", TEX.STR, 0, 0, UI.SEC_W, 92, TEX_SEC_ABI, 0.92)
    secs.SAV = CreateSection(frame, "Salvaciones", TEX.SHIELD, 0, 0, UI.SEC_W, 92, TEX_SEC_SAV, 0.86)
    secs.ATK = CreateSection(frame, "Ataque", TEX.ATK, 0, 0, UI.SEC_W, UI.PANEL_H, TEX_SEC_ATK, 0.92)
    secs.SKL = CreateSection(frame, "Habilidades", TEX.EYE, 0, 0, UI.SEC_W, UI.PANEL_H, TEX_SEC_SKL, 0.90)
    return secs
end

local SEC = CreateSections(F)
local SEC_TOP, SEC_ABI, SEC_SAV, SEC_ATK, SEC_SKL = SEC.TOP, SEC.ABI, SEC.SAV, SEC.ATK, SEC.SKL
local TabBar = CreateFrame("Frame", nil, F)
TabBar:SetPoint("TOPLEFT", F, "TOPLEFT", UI.SEC_X, UI.TAB_Y)
TabBar:SetSize(UI.SEC_W, UI.TAB_H)
TabBar:SetFrameStrata(F:GetFrameStrata())
TabBar:SetFrameLevel(F:GetFrameLevel() + 10)

local TabPanel = CreateFrame("Frame", nil, F)
TabPanel:SetPoint("TOPLEFT", F, "TOPLEFT", UI.SEC_X, UI.PANEL_Y)
TabPanel:SetSize(UI.SEC_W, UI.PANEL_H)
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

local TAB_W = 110
local TAB_GAP = 8
local TOTAL_TABS_W = TAB_W * 3 + TAB_GAP * 2
local TAB_START_X = math.floor((UI.SEC_W - TOTAL_TABS_W) / 2)

CreateTabButton(TabBar, "BASE", "Características", TAB_START_X, TAB_W)
CreateTabButton(TabBar, "ATK", "Ataque", TAB_START_X + TAB_W + TAB_GAP, TAB_W)
CreateTabButton(TabBar, "SKL", "Habilidades", TAB_START_X + (TAB_W + TAB_GAP) * 2, TAB_W)

local AbilityButtons, SaveButtons, SkillButtons = {}, {}, {}
local modeLabel = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
modeLabel:SetPoint("TOPLEFT", 10, -34)
modeLabel:SetText("Modo activo: Normal")

local pbText = SEC_TOP:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pbText:SetPoint("TOPRIGHT", -6, -34)
pbText:SetJustifyH("RIGHT")
pbText:SetText("Bonus competencia: " .. GREEN .. fmtSigned(GetPB()) .. ENDCLR)

local RefreshTopInfo

MakeButton(SEC_TOP, "Normal", 72, 20, 10, -48, function()
    ARCSET("ModoTirada", "normal")
    if RefreshTopInfo then RefreshTopInfo() end
end)

MakeButton(SEC_TOP, "Ventaja", 72, 20, 88, -48, function()
    ARCSET("ModoTirada", "adv")
    if RefreshTopInfo then RefreshTopInfo() end
end)

MakeButton(SEC_TOP, "Desv.", 72, 20, 166, -48, function()
    ARCSET("ModoTirada", "dis")
    if RefreshTopInfo then RefreshTopInfo() end
end)

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
    for _, a in ipairs(ABIL) do
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

local weaponInfoText = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
weaponInfoText:SetPoint("TOPLEFT", 10, -34)
weaponInfoText:SetWidth(350)
weaponInfoText:SetJustifyH("LEFT")
weaponInfoText:SetJustifyV("TOP")
weaponInfoText:SetWordWrap(true)
weaponInfoText:SetMaxLines(2)
weaponInfoText:SetText("")

local weaponDrop = CreateFrame("Frame", nil, SEC_ATK, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(weaponDrop, 145)
weaponDrop:ClearAllPoints()
weaponDrop:SetPoint("TOPLEFT", -7, -64)

local versBtn = MakeButton(SEC_ATK, "Versátil", 70, 22, 175, -66, function()
    local def = GetWeaponDef(GetWeaponKey())
    if not GetVersatileDice(def) then return end
    ARCSET("Versatil", GetVersatileActive() and 0 or 1)
    UpdateWeaponInfoUI()
end)

local dmgInfoText = SEC_ATK:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
dmgInfoText:SetPoint("TOPLEFT", 10, -98)
dmgInfoText:SetJustifyH("LEFT")
dmgInfoText:SetText("")

GetWeaponKey = function()
    local v = ARCGET("ArmaSeleccionada", "Desarmado")
    for _, w in ipairs(WEAPONS) do
        if w.key == v then return v end
    end
    return "Desarmado"
end

GetWeaponDef = function(key)
    for _, w in ipairs(WEAPONS) do
        if w.key == key then return w end
    end
    return WEAPONS[1]
end

ParseDice = function(diceStr)
    if not diceStr then return nil, nil end
    local n, s = diceStr:match("^(%d+)d(%d+)$")
    n, s = tonumber(n), tonumber(s)
    return n, s
end

GetVersatileDice = function(def)
    if not def or not def.props then return nil end
    for _, p in ipairs(def.props) do
        local d = p:match("Versátil %((%d+d%d+)%)")
        if d then return d end
    end
    return nil
end

WeaponBaseDice = function(def)
    if not def or not def.dmgN or not def.dmgS or def.dmgN == 0 or def.dmgS == 0 then return "-" end
    local use = tostring(def.dmgN) .. "d" .. tostring(def.dmgS)
    local v = GetVersatileDice(def)
    if v and GetVersatileActive() then use = v end
    return use
end

local function WeaponPropsLabel(def)
    if not def or not def.props or #def.props == 0 then return "" end
    local out = {}
    local v = GetVersatileDice(def)
    local vOn = v and GetVersatileActive()
    for _, p in ipairs(def.props) do
        if v and p:find("Versátil") then
            if vOn then
                out[#out+1] = GREEN .. p .. ENDCLR
            else
                out[#out+1] = "|cff999999" .. p .. ENDCLR
            end
        else
            out[#out+1] = p
        end
    end
    return table.concat(out, ", ")
end

local function GetWeaponAttackAbility(def)
    local hasFinesse = false
    if def and def.props then
        for _, p in ipairs(def.props) do
            if p:find("Sutil") then hasFinesse = true break end
        end
    end
    if def and def.mode == "Ranged" then return "Destreza" end
    if hasFinesse then
        local mStr = GetAbilityMod("Fuerza")
        local mDex = GetAbilityMod("Destreza")
        return (mDex >= mStr) and "Destreza" or "Fuerza"
    end
    return "Fuerza"
end

UpdateWeaponInfoUI = function()
    local def = GetWeaponDef(GetWeaponKey())
    weaponInfoText:SetText(WeaponPropsLabel(def))

    local vDice = GetVersatileDice(def)
    if vDice then
        versBtn:Enable()
        versBtn:SetText("Versátil")
    else
        ARCSET("Versatil", 0)
        versBtn:Disable()
        versBtn:SetText("Versátil")
    end

    local abil = GetWeaponAttackAbility(def)
    local abiMod = (def.addAbi and abil) and GetAbilityMod(abil) or 0
    local wmod = GetWeaponMod()
    local dice = WeaponBaseDice(def)

    local parts = {}
    if abiMod ~= 0 then parts[#parts+1] = fmtSigned(abiMod) end
    if wmod ~= 0 then parts[#parts+1] = fmtSigned(wmod) end
    local bonusTxt = table.concat(parts, "")

    local dtype = def.dmgType or ""
    local dtypeTxt = (dtype ~= "") and (" " .. dtype) or ""
    dmgInfoText:SetText(("Daño: %s%s%s"):format(dice, bonusTxt, dtypeTxt))
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
    local groups = GetWeaponMenuGroups()

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
    local def = GetWeaponDef(GetWeaponKey())
    local abil = GetWeaponAttackAbility(def)
    local base = GetAbilityMod(abil)
    local prof = GetPB()
    local wmod = GetWeaponMod()
    local misc = GetMiscBonus()

    local mode = GetMode()
    local _, a, b = RollD20(mode)
    local chosen, ra, rb = RollTextWithMode(mode, a, b)
    local critTag = GetCritTag(mode, a, b)
    local totalBonus = base + prof + wmod + misc
    local total = chosen + totalBonus

    local parts = {}
    if base ~= 0 then parts[#parts+1] = fmtSigned(base) end
    if prof ~= 0 then parts[#parts+1] = fmtSigned(prof) end
    if wmod ~= 0 then parts[#parts+1] = fmtSigned(wmod) end
    if misc ~= 0 then parts[#parts+1] = fmtSigned(misc) end
    local bonusTxt = table.concat(parts, "")

    local diceStr
    if rb then
        diceStr = tostring(ra) .. "/" .. tostring(rb) .. "→" .. tostring(chosen)
    else
        diceStr = tostring(chosen)
    end

    local wmodLabel = ""
    if wmod ~= 0 then wmodLabel = " " .. fmtSigned(wmod) end

    BroadcastRoll({
        type = "attack",
        label = "Ataque " .. def.key .. wmodLabel,
        total = total,
        dice = diceStr,
        modifiers = bonusTxt,
        critical = critTag,
        mode = (mode == "adv" and "V") or (mode == "dis" and "D") or ""
    })
end

MakeButton(SEC_ATK, "Ataque Arma", 110, 22, 266, -66, function()
    DoWeaponAttack()
end)

MakeButton(SEC_ATK, "Daño Arma", 110, 22, 266, -94, function()
    local def = GetWeaponDef(GetWeaponKey())
    local abil = GetWeaponAttackAbility(def)
    RollWeaponDamage(def, abil)
end)

MakeButton(SEC_ATK, "Ataque Conjuro", 110, 22, 266, -122, function()
    DoSpellAttack()
end)

HarfordDnDInitLabel, HarfordDnDInitBox, HarfordDnDSetInitBoxFromARC = MakeSignedEditBox(
    SEC_ATK, "Mod Ini:", -240, -146, "ModIniciativa", 0
)

MakeButton(SEC_ATK, "Iniciativa", 110, 22, 266, -150, function()
    DoRoll("Iniciativa", GetAbilityMod("Destreza"), HarfordDnDGetInitiativeMod())
end)

DoSpellAttack = function()
    local abil = GetSpellAbilityKey()
    local base = GetAbilityMod(abil)
    local prof = GetPB()
    local misc = GetMiscBonus()

    local mode = GetMode()
    local _, a, b = RollD20(mode)
    local chosen, ra, rb = RollTextWithMode(mode, a, b)
    local critTag = GetCritTag(mode, a, b)
    local totalBonus = base + prof + misc
    local total = chosen + totalBonus

    local parts = {}
    if base ~= 0 then parts[#parts+1] = fmtSigned(base) end
    if prof ~= 0 then parts[#parts+1] = fmtSigned(prof) end
    if misc ~= 0 then parts[#parts+1] = fmtSigned(misc) end
    local bonusTxt = table.concat(parts, "")

    local diceStr
    if rb then
        diceStr = tostring(ra) .. "/" .. tostring(rb) .. "→" .. tostring(chosen)
    else
        diceStr = tostring(chosen)
    end

    BroadcastRoll({
        type = "spell",
        label = "Ataque Conjuro",
        total = total,
        dice = diceStr,
        modifiers = bonusTxt,
        critical = critTag,
        mode = (mode == "adv" and "V") or (mode == "dis" and "D") or ""
    })
end

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


MakeButton(SEC_TOP, "Recursos", 96, 22, 286, -6, function()
    if ResourceFrame:IsShown() then
        ResourceFrame:Hide()
    else
        RefreshResourceFrame()
        ResourceFrame:Show()
        ResourceFrame:Raise()
    end
end)

RefreshTopInfo = function()
    local mode = GetMode()
    local modeName = (mode == "adv" and "Ventaja") or (mode == "dis" and "Desventaja") or "Normal"
    modeLabel:SetText("Modo activo: " .. modeName)

    local pb = GetPB()
    pbText:SetText("Bonus competencia: " .. GREEN .. fmtSigned(pb) .. ENDCLR)

    local abil = GetSpellAbilityKey()
    local m = GetAbilityMod(abil)
    local short = ""
    for _, a in ipairs(ABIL) do if a.key == abil then short = a.short break end end

    scModLabel:SetText("Mod Conjuro (" .. short .. "): " .. ColorSigned(m))
    scAtkText:SetText("Ataque Conjuro: " .. GREEN .. fmtSigned(pb + m) .. ENDCLR)
    dcText:SetText(GREEN .. tostring(8 + pb + m) .. ENDCLR)

    SyncSpellDrop()
end

local abiKeys, savKeys = {}, {}
local Layout3Col

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
    local BTN_H = 22
    local PAD_X = 10
    local COL_GAP = 16
    local ROW_GAP = 4

    local sw = (section and section.GetWidth and section:GetWidth()) or 412
    local avail = sw - PAD_X * 2 - 10
    local cap = math.floor((avail - 2 * COL_GAP) / 3)
    local minW = 110

    local maxW = {minW, minW, minW}
    for i, k in ipairs(keys) do
        local b = buttons[k]
        if b then
            local w = MeasureButtonTextWidth(b) + 28
            local col = ((i - 1) % 3) + 1
            if w > maxW[col] then
                maxW[col] = w
            end
        end
    end

    for c = 1, 3 do
        if maxW[c] < minW then maxW[c] = minW end
        if maxW[c] > cap then maxW[c] = cap end
    end

    local totalW = maxW[1] + maxW[2] + maxW[3] + 2 * COL_GAP
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

    local totalContentW = maxW[1] + maxW[2] + maxW[3] + 2 * COL_GAP
    local startX = math.floor((sw - totalContentW) / 2)

    local x1 = startX
    local x2 = x1 + maxW[1] + COL_GAP
    local x3 = x2 + maxW[2] + COL_GAP

    for i, k in ipairs(keys) do
        local b = buttons[k]
        if b then
            local col = (i - 1) % 3
            local row = math.floor((i - 1) / 3)
            local x = (col == 0 and x1) or (col == 1 and x2) or x3
            local w = (col == 0 and maxW[1]) or (col == 1 and maxW[2]) or maxW[3]
            local y = -(topY + row * (BTN_H + ROW_GAP))
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", x, y)
            b:SetSize(w, BTN_H)
        end
    end
end

local function RefreshButtons()
    for _, a in ipairs(ABIL) do
        local b = AbilityButtons[a.key]
        if b then b:SetText(FormatAbilityButtonText(a.short, a.key)) end
    end
    for _, a in ipairs(ABIL) do
        local b = SaveButtons[a.key]
        if b then b:SetText(FormatSaveButtonText(a.short, a.key)) end
    end
    for _, s in ipairs(SKILLS) do
        local b = SkillButtons[s.id]
        if b then b:SetText(FormatSkillButtonText(s)) end
    end

    Layout3Col(SEC_ABI, AbilityButtons, abiKeys, 36)
    Layout3Col(SEC_SAV, SaveButtons, savKeys, 36)
end

local y0 = -36
for i, a in ipairs(ABIL) do
    local col = ((i-1) % 3)
    local row = math.floor((i-1)/3)
    local b = MakeButton(SEC_ABI, "…", 140, 22, 10 + col*160, y0 - row*26, function()
        DoRoll(a.short, GetAbilityMod(a.key), 0)
    end)
    AbilityButtons[a.key] = b
    abiKeys[#abiKeys+1] = a.key
end

local y1 = -36
for i, a in ipairs(ABIL) do
    local col = ((i-1) % 3)
    local row = math.floor((i-1)/3)
    local b = MakeButton(SEC_SAV, "…", 140, 22, 10 + col*160, y1 - row*26, function()
        local base = GetAbilityMod(a.key)
        local prof = GetSaveProf(a.key) and GetPB() or 0
        DoRoll("Salv " .. a.short, base, prof)
    end)
    SaveButtons[a.key] = b
    savKeys[#savKeys+1] = a.key
end

local scroll = CreateFrame("ScrollFrame", nil, SEC_SKL, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 6, -32)
scroll:SetPoint("BOTTOMRIGHT", -28, 6)

local scrollChild = CreateFrame("Frame", nil, scroll)
scrollChild:SetSize(1, 1)
scroll:SetScrollChild(scrollChild)

local BTN_H = 22
local PAD_X, PAD_Y = 8, 6
local GAP_Y, COL_GAP = 4, 16

local function RefreshSkillLayout()
    local sw = (scroll and scroll.GetWidth and scroll:GetWidth()) or ((SEC_SKL and SEC_SKL.GetWidth and SEC_SKL:GetWidth()) or 412) - 34
    local avail = sw - PAD_X*2
    local cap = math.floor((avail - COL_GAP) / 2)

    local maxW1, maxW2 = 160, 160
    for i, s in ipairs(SKILLS) do
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

    for i, s in ipairs(SKILLS) do
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

for i, s in ipairs(SKILLS) do
    local col = ((i-1) % 2)
    local row = math.floor((i-1) / 2)
    local x = PAD_X + col * (200 + COL_GAP)
    local y = -(PAD_Y + row * (BTN_H + GAP_Y))

    local b = MakeButton(scrollChild, "…", 200, BTN_H, x, y, function()
        local base = GetAbilityMod(s.ability)
        local prof = GetSkillProfBonus(s)
        DoRoll(s.name, base, prof)
    end)

    SkillButtons[s.id] = b
end

local totalRows = math.ceil(#SKILLS / 2)
local contentH = PAD_Y + totalRows * (BTN_H + GAP_Y) + 8
scrollChild:SetHeight(contentH)

RefreshButtons()
RefreshSkillLayout()
RefreshTopInfo()
ShowDnDTab("BASE")
CreateDnDMinimapButton()

_G.DND5E_ARC_LOADED = true
_G.DND5E_ARC_API = _G.DND5E_ARC_API or {}

_G.DND5E_ARC_API.Refresh = function()
    local playerProfile = UnitName("player") or "default"

    LoadPersistToRuntime(playerProfile)
	SyncRuntimeProfileRef()

	_G.HarfordDnDHydratingFromPersist = true
	EnsureDefaults()
	_G.HarfordDnDHydratingFromPersist = false

    if SetMiscBoxFromARC then SetMiscBoxFromARC() end
    if HarfordDnDSetInitBoxFromARC then HarfordDnDSetInitBoxFromARC() end
    if SetModArmaFromARC then SetModArmaFromARC() end
    if RefreshButtons then RefreshButtons() end
    if RefreshSkillLayout then RefreshSkillLayout() end
    if RefreshTopInfo then RefreshTopInfo() end
    if SyncWeaponDrop then SyncWeaponDrop() end
    if UpdateWeaponInfoUI then UpdateWeaponInfoUI() end
    if RefreshResourceFrame and ResourceFrame and ResourceFrame:IsShown() then RefreshResourceFrame() end
    if RefreshTargetResourceFrame then RefreshTargetResourceFrame() end
    if HarfordUnitFrames and HarfordUnitFrames.Refresh then HarfordUnitFrames.Refresh() end
    if CreateDnDMinimapButton then CreateDnDMinimapButton() end
    if ShowDnDTab then ShowDnDTab(ActiveTab or "BASE") end
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
    SaveCurrentProfileToBank(profileName)
    return profileName, HarfordSync.LoadProfileFromBank(HarfordDnDProfileBank, profileName)
end

function HarfordDnDAPI.ExportProfile(profileName)
    return HarfordSync.LoadProfileFromBank(HarfordDnDProfileBank, profileName)
end

function HarfordDnDAPI.ApplyProfile(profileName, tbl)
    return ApplyProfileTable(tbl, profileName)
end

function HarfordDnDAPI.BroadcastConfig(channel, target)
    EnsurePersist()
    LoadPersistToRuntime(HarfordDnDPersistStore.activeProfile or (UnitName("player") or "default"))

    local profileName = tostring(HarfordDnDPersistStore.activeProfile or UnitName("player") or "default")
    local tbl = HarfordSync.ReadProfileFromRuntime(RuntimeProfile, HarfordSync.ProfileKeys.DnD)

    return HarfordSync.SendDnDProfile(
        ADDON_PREFIX,
        profileName,
        tbl,
        channel,
        target
    )
end

local function ExportProfileResourcesFromBank(profileName)
    local tbl = HarfordDnDProfileBank and HarfordDnDProfileBank[profileName]
    if type(tbl) ~= "table" then
        return nil
    end

    local out = HarfordDnDResources.BuildPayloadFromTable(tbl, {
        includeCurrent = false,
        includeMax = true,
        activityMode = "max",
    })
    if next(out) == nil then
        return nil
    end
    return out
end

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
        ApplyProfileTable(tbl, characterName)

        local resourceTblLocal = ExportProfileResourcesFromBank(characterName)
        if resourceTblLocal then
            ApplyResourceConfigTable(resourceTblLocal, characterName)
        end

        return true
    end

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

    local resourceTbl = ExportProfileResourcesFromBank(characterName)
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
    return HarfordSync.BroadcastProfiles(
        ADDON_PREFIX,
        "DNDCFG",
        HarfordDnDProfileBank,
        HarfordSync.ProfileKeys.DnD,
        channel,
        target
    )
end

function HarfordDnDAPI.GetCurrentResources()
    return ExportCurrentResources()
end

function HarfordDnDAPI.GetResourcesForName(characterName)
    characterName = tostring(characterName or "")
    if characterName == "" then
        return nil
    end

    local myShortName = UnitName("player")
    local myFullName = GetUnitName and GetUnitName("player", true)

    if characterName == myShortName or (myFullName and characterName == myFullName) then
        return ExportCurrentResources()
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

    return RequestResourcesFromPlayer(characterName)
end

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
        return SendResourceAdjustToPlayer(myFullName or myShortName, resourceKey, delta)
    end

    return SendResourceAdjustToPlayer(characterName, resourceKey, delta)
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:RegisterEvent("PLAYER_TARGET_CHANGED")

local AddonHandlers = HarfordDnDComm.CreateHandlers({
    ADDON_PREFIX = ADDON_PREFIX,
    EnsurePersist = EnsurePersist,
    LoadPersistToRuntime = LoadPersistToRuntime,
    EnsureTargetResourceFrameState = EnsureTargetResourceFrameState,
    CreateDnDMinimapButton = CreateDnDMinimapButton,
    PlayerFrame = F,
    TargetResourceFrame = TargetResourceFrame,
    RefreshTargetResourceFrame = RefreshTargetResourceFrame,
    RequestResourcesFromPlayer = RequestResourcesFromPlayer,
    SendResourceResponseTo = SendResourceResponseTo,
    SendResourceResponseForProfileTo = SendResourceResponseForProfileTo,
    ApplyResourceDelta = ApplyResourceDeltaFromRemote,
    ApplyProfileTable = ApplyProfileTable,
    ApplyResourceConfigTable = ApplyResourceConfigTable,
    BuildRuntimeFromConfig = HarfordDnDResources.BuildRuntimeFromConfig,
    CacheRemoteResources = HarfordDnDResources.CacheRemoteResources,
    HandleRollSync = function(message)
        local data = DeserializeRoll(message)
        if data then
            DisplayRollInChat(data)
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
        return
    end
    local prefix, message, _, sender = ...
    AddonHandlers.HandleAddonMessage(prefix, message, sender)
    if HarfordUnitFrames and HarfordUnitFrames.Refresh then
        HarfordUnitFrames.Refresh()
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
