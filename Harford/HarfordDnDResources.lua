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
}

HarfordDnDResources.DEFS = {
    health       = { label = "Salud",               color = {0.78, 0.16, 0.16} },
    mana         = { label = "Maná",                color = {0.18, 0.35, 0.95} },
    temp_health  = { label = "Vida temporal",       color = {0.45, 0.75, 1.00} },
    chi          = { label = "Chi",                 color = {0.35, 0.90, 0.70} },
    energy       = { label = "Energía",             color = {0.95, 0.85, 0.20} },
    fel_point    = { label = "Vil",    				color = {0.55, 0.15, 0.70} },
    focus        = { label = "Enfoque",             color = {0.95, 0.55, 0.10} },
    holy_power   = { label = "Poder sagrado",       color = {0.95, 0.90, 0.55} },
    light_point  = { label = "Puntos de Fe",       	color = {1.00, 0.95, 0.72} },
    mage_point 	 = { label = "Puntos de Hechicería",   color = {0.35, 0.80, 1.00} },
    rage         = { label = "Ira",                 color = {0.85, 0.18, 0.18} },
    runic_power  = { label = "Poder rúnico",        color = {0.10, 0.80, 0.95} },
    soul_shard   = { label = "Fragmentos de alma",  color = {0.55, 0.30, 0.90} },
    astral_power = { label = "Poder astral",        color = {0.48, 0.62, 1.00} },
    living_seeds = { label = "Semillas vivas",      color = {0.30, 0.85, 0.35} },
}

HarfordDnDResources.PROFILE_KEYS = {
    "Res_health_Max", "Res_mana_Max", "Res_temp_health_Max", "Res_chi_Max", "Res_energy_Max",
    "Res_fel_point_Max", "Res_focus_Max", "Res_holy_power_Max", "Res_light_point_Max", "Res_mage_point_Max",
    "Res_rage_Max", "Res_runic_power_Max", "Res_soul_shard_Max", "Res_astral_power_Max", "Res_living_seeds_Max",
}

HarfordDnDResources.RUNTIME_KEYS = {
    "Res_health_Cur", "Res_health_Max", "Res_mana_Cur", "Res_mana_Max", "Res_temp_health_Cur", "Res_temp_health_Max",
    "Res_chi_Cur", "Res_chi_Max", "Res_energy_Cur", "Res_energy_Max", "Res_fel_point_Cur", "Res_fel_point_Max",
    "Res_focus_Cur", "Res_focus_Max", "Res_holy_power_Cur", "Res_holy_power_Max", "Res_light_point_Cur", "Res_light_point_Max",
    "Res_mage_point_Cur", "Res_mage_point_Max", "Res_rage_Cur", "Res_rage_Max", "Res_runic_power_Cur", "Res_runic_power_Max",
    "Res_soul_shard_Cur", "Res_soul_shard_Max", "Res_astral_power_Cur", "Res_astral_power_Max", "Res_living_seeds_Cur", "Res_living_seeds_Max",
}

HarfordDnDResources.RemoteCache = HarfordDnDResources.RemoteCache or {}

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
