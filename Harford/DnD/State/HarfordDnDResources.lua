HarfordDnDResources = HarfordDnDResources or {}

HarfordDnDResources.ORDER = {
    "health",
    "mana",
    "chi",
    "energy",
    "fel_point",
    "focus",
    "holy_power",
    "light_point",
    "mage_point",
    "rage",
    "runic_power",
    "soul_shard",
    "astral_power",
    "living_seeds",
    "channel_divinity",
    "totem",
    "maelstrom",
    "healing_mist",
}

HarfordDnDResources.ALL_KEYS = {
    "health",
    "temp_health",
    "mana",
    "chi",
    "energy",
    "fel_point",
    "focus",
    "holy_power",
    "light_point",
    "mage_point",
    "rage",
    "runic_power",
    "soul_shard",
    "astral_power",
    "living_seeds",
    "channel_divinity",
    "totem",
    "maelstrom",
    "healing_mist",
}

-- recharge: "short" = se recupera al maximo en descanso corto (y tambien en el largo);
--           "long"  = se recupera al maximo solo en descanso largo;
--           "reset" = pool de combate que se ACUMULA desde 0 (ej. Furia): el descanso lo
--                     vacia a 0 en vez de rellenarlo;
--           "none"  = no se toca con descansos (gestion manual; ej. vida temporal).
-- Fuente: manual Warcraft 5DnD (ver AGENTS.md, contrato de recursos/descansos).
HarfordDnDResources.DEFS = {
    health       = { label = "Salud",               color = {0.78, 0.16, 0.16}, recharge = "long" },
    mana         = { label = "Maná",                color = {0.18, 0.35, 0.95}, recharge = "long" },
    temp_health  = { label = "Vida temporal",       color = {0.45, 0.75, 1.00}, recharge = "none" },
    chi          = { label = "Chi",                 color = {0.35, 0.90, 0.70}, recharge = "short" },
    energy       = { label = "Energía",             color = {0.95, 0.85, 0.20}, recharge = "short" },
    fel_point    = { label = "Vil",    				color = {0.55, 0.15, 0.70}, recharge = "short" },
    focus        = { label = "Enfoque",             color = {0.95, 0.55, 0.10}, recharge = "short" },
    holy_power   = { label = "Poder sagrado",       color = {0.95, 0.90, 0.55}, recharge = "long" },
    light_point  = { label = "Puntos de Fe",       	color = {1.00, 0.95, 0.72}, recharge = "long" },
    mage_point 	 = { label = "Puntos de Hechicería",   color = {0.35, 0.80, 1.00}, recharge = "long" },
    rage         = { label = "Ira",                 color = {0.85, 0.18, 0.18}, recharge = "reset" },
    runic_power  = { label = "Poder rúnico",        color = {0.10, 0.80, 0.95}, recharge = "long" },
    soul_shard   = { label = "Fragmentos de alma",  color = {0.55, 0.30, 0.90}, recharge = "long" },
    astral_power = { label = "Poder astral",        color = {0.48, 0.62, 1.00}, recharge = "long" },
    living_seeds = { label = "Rejuvenecimiento",     color = {0.30, 0.85, 0.35}, recharge = "long" },
    channel_divinity = { label = "Canalizar Divinidad", color = {1.00, 0.82, 0.30}, recharge = "short" },
    totem        = { label = "Tótem",               color = {0.55, 0.40, 0.20}, recharge = "short" },
    maelstrom    = { label = "Torbellino",          color = {0.20, 0.70, 0.85}, recharge = "short" },
    healing_mist = { label = "Chi sanador",          color = {0.40, 0.90, 0.75}, recharge = "long" },
}

-- Devuelve la regla de recarga ("short"/"long"/"none") de un recurso (default "long").
function HarfordDnDResources.GetRecharge(key)
    local def = HarfordDnDResources.DEFS[key]
    return (def and def.recharge) or "long"
end

HarfordDnDResources.PROFILE_KEYS = {
    "Res_health_Max", "Res_mana_Max", "Res_temp_health_Max", "Res_chi_Max", "Res_energy_Max",
    "Res_fel_point_Max", "Res_focus_Max", "Res_holy_power_Max", "Res_light_point_Max", "Res_mage_point_Max",
    "Res_rage_Max", "Res_runic_power_Max", "Res_soul_shard_Max", "Res_astral_power_Max", "Res_living_seeds_Max",
    "Res_channel_divinity_Max",
    "Res_totem_Max", "Res_maelstrom_Max", "Res_healing_mist_Max",
}

HarfordDnDResources.RUNTIME_KEYS = {
    "Res_health_Cur", "Res_health_Max", "Res_mana_Cur", "Res_mana_Max", "Res_temp_health_Cur", "Res_temp_health_Max",
    "Res_chi_Cur", "Res_chi_Max", "Res_energy_Cur", "Res_energy_Max", "Res_fel_point_Cur", "Res_fel_point_Max",
    "Res_focus_Cur", "Res_focus_Max", "Res_holy_power_Cur", "Res_holy_power_Max", "Res_light_point_Cur", "Res_light_point_Max",
    "Res_mage_point_Cur", "Res_mage_point_Max", "Res_rage_Cur", "Res_rage_Max", "Res_runic_power_Cur", "Res_runic_power_Max",
    "Res_soul_shard_Cur", "Res_soul_shard_Max", "Res_astral_power_Cur", "Res_astral_power_Max", "Res_living_seeds_Cur", "Res_living_seeds_Max",
    "Res_channel_divinity_Cur", "Res_channel_divinity_Max",
    "Res_totem_Cur", "Res_totem_Max", "Res_maelstrom_Cur", "Res_maelstrom_Max",
    "Res_healing_mist_Cur", "Res_healing_mist_Max",
    "ArmorClass",
}

HarfordDnDResources.RemoteCache    = HarfordDnDResources.RemoteCache    or {}
-- Cache del flag de animaciones por jugador (nombre corto → boolean).
-- true = quiere recibir animaciones; nil = desconocido (tratar como true).
HarfordDnDResources.AnimFlagCache  = HarfordDnDResources.AnimFlagCache  or {}

function HarfordDnDResources.CurKey(key)
    return "Res_" .. tostring(key) .. "_Cur"
end

function HarfordDnDResources.MaxKey(key)
    return "Res_" .. tostring(key) .. "_Max"
end

function HarfordDnDResources.Exists(key, curValue, maxValue)
    local cur = tonumber(curValue) or 0
    local max = tonumber(maxValue) or 0
    if key == "temp_health" then
        return cur > 0
    end
    return max > 0
end

function HarfordDnDResources.BuildPayloadFromRuntime(readValueFn, options)
    if HarfordSync and HarfordSync.BuildActiveResourcePayloadFromStore then
        return HarfordSync.BuildActiveResourcePayloadFromStore(readValueFn, HarfordDnDResources.ALL_KEYS, options)
    end
    return {}, {}
end

function HarfordDnDResources.BuildPayloadFromTable(tbl, options)
    return HarfordDnDResources.BuildPayloadFromRuntime(function(key)
        return tbl and tbl[key]
    end, options)
end

function HarfordDnDResources.BuildRuntimeFromConfig(cfg)
    local runtimeTbl = {}
    for _, key in ipairs(HarfordDnDResources.RUNTIME_KEYS) do
        if string.find(key, "_Max", 1, true) then
            runtimeTbl[key] = tostring(tonumber(cfg[key]) or 0)
        elseif string.find(key, "_Cur", 1, true) then
            local maxKey = string.gsub(key, "_Cur$", "_Max")
            local maxValue = tonumber(cfg[maxKey]) or 0
            runtimeTbl[key] = key == "Res_temp_health_Cur" and "0" or tostring(maxValue)
        end
    end
    return runtimeTbl
end

function HarfordDnDResources.CacheRemoteResources(senderName, profileName, tbl)
    if type(tbl) ~= "table" then
        return
    end

    local function cacheName(name)
        if not name or name == "" then return end
        HarfordDnDResources.RemoteCache[name] = tbl
        local short = Ambiguate and Ambiguate(name, "short") or name
        if short and short ~= "" then
            HarfordDnDResources.RemoteCache[short] = tbl
        end
    end

    cacheName(senderName)
    cacheName(profileName)
end

function HarfordDnDResources.PruneRemoteCache()
    local keep = {}
    local function keepName(name)
        if not name or name == "" then return end
        keep[name] = true
        local short = Ambiguate and Ambiguate(name, "short") or name:match("^[^%-]+") or name
        if short and short ~= "" then keep[short] = true end
    end

    for _, unit in ipairs({ "player", "target", "focus" }) do
        if UnitExists and UnitExists(unit) then
            keepName(HarfordClassColors.UnitFullName(unit))
        end
    end
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists and UnitExists(unit) then
                keepName(HarfordClassColors.UnitFullName(unit))
            end
        end
    else
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists and UnitExists(unit) then
                keepName(HarfordClassColors.UnitFullName(unit))
            end
        end
    end

    local removed = 0
    for name in pairs(HarfordDnDResources.RemoteCache or {}) do
        if not keep[name] then
            HarfordDnDResources.RemoteCache[name] = nil
            removed = removed + 1
        end
    end
    -- AnimFlagCache tiene el mismo ciclo de vida (cache por jugador remoto). Se poda con el
    -- mismo set `keep` para que no crezca sin limite (antes solo se escribia, nunca se limpiaba).
    for name in pairs(HarfordDnDResources.AnimFlagCache or {}) do
        if not keep[name] then
            HarfordDnDResources.AnimFlagCache[name] = nil
        end
    end
    return removed
end

if CreateFrame then
    local pruneFrame = CreateFrame("Frame")
    pruneFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    pruneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    pruneFrame:SetScript("OnEvent", function()
        if HarfordDnDResources.PruneRemoteCache then
            HarfordDnDResources.PruneRemoteCache()
        end
    end)
end
