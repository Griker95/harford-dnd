-- HarfordDnDItems: equipo virtual de ficha usando objetos reales del cliente.
--
-- "Equipar" aqui no toca el equipo real del personaje WoW. Guarda item links por
-- slot de ficha Harford, resuelve icono/stats cuando el cliente tenga el item en
-- cache y expone una capa derivada para caracteristicas, CA y arma activa.

HarfordDnDItems = HarfordDnDItems or {}

local API = HarfordDnDItems

local SLOT_ORDER = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrists",
    "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
    "MainHand", "SecondaryHand",
}

-- Reservado: mapa equipLoc -> slot de ficha para auto-asignar el hueco al soltar un
-- objeto (pendiente de cablear en el panel). No eliminar; es andamiaje de esa feature.
local EQUIP_LOC_TO_SLOT = {
    INVTYPE_HEAD = "Head",
    INVTYPE_NECK = "Neck",
    INVTYPE_SHOULDER = "Shoulder",
    INVTYPE_CLOAK = "Back",
    INVTYPE_CHEST = "Chest",
    INVTYPE_ROBE = "Chest",
    INVTYPE_BODY = "Shirt",
    INVTYPE_TABARD = "Tabard",
    INVTYPE_WRIST = "Wrists",
    INVTYPE_HAND = "Hands",
    INVTYPE_WAIST = "Waist",
    INVTYPE_LEGS = "Legs",
    INVTYPE_FEET = "Feet",
    INVTYPE_FINGER = "Finger0",
    INVTYPE_TRINKET = "Trinket0",
    INVTYPE_WEAPON = "MainHand",
    INVTYPE_WEAPONMAINHAND = "MainHand",
    INVTYPE_2HWEAPON = "MainHand",
    INVTYPE_RANGED = "MainHand",
    INVTYPE_RANGEDRIGHT = "MainHand",
    INVTYPE_HOLDABLE = "SecondaryHand",
    INVTYPE_SHIELD = "SecondaryHand",
    INVTYPE_WEAPONOFFHAND = "SecondaryHand",
}

-- equipLoc (INVTYPE_*) aceptados por cada slot de ficha. Multi-slot resuelto a mano:
-- anillos/abalorios en ambos huecos; arma a 1 mano en cualquier mano; 2 manos solo
-- principal; escudo/holdable/offhand solo secundaria.
local SLOT_ACCEPTS = {
    Head          = { INVTYPE_HEAD = true },
    Neck          = { INVTYPE_NECK = true },
    Shoulder      = { INVTYPE_SHOULDER = true },
    Back          = { INVTYPE_CLOAK = true },
    Chest         = { INVTYPE_CHEST = true, INVTYPE_ROBE = true },
    Shirt         = { INVTYPE_BODY = true },
    Tabard        = { INVTYPE_TABARD = true },
    Wrists        = { INVTYPE_WRIST = true },
    Hands         = { INVTYPE_HAND = true },
    Waist         = { INVTYPE_WAIST = true },
    Legs          = { INVTYPE_LEGS = true },
    Feet          = { INVTYPE_FEET = true },
    Finger0       = { INVTYPE_FINGER = true },
    Finger1       = { INVTYPE_FINGER = true },
    Trinket0      = { INVTYPE_TRINKET = true },
    Trinket1      = { INVTYPE_TRINKET = true },
    MainHand      = { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_2HWEAPON = true, INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true },
    SecondaryHand = { INVTYPE_WEAPON = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_HOLDABLE = true, INVTYPE_SHIELD = true },
}

-- Devuelve true si un objeto con ese equipLoc puede ir en ese slot de ficha.
function HarfordDnDItems.CanEquipInSlot(equipLoc, slotKey)
    local accepts = SLOT_ACCEPTS[tostring(slotKey or "")]
    return (accepts and accepts[tostring(equipLoc or "")]) == true
end

local STAT_TO_ABILITY = {
    ITEM_MOD_STRENGTH_SHORT = "Fuerza",
    ITEM_MOD_AGILITY_SHORT = "Destreza",
    ITEM_MOD_STAMINA_SHORT = "Constitucion",
    ITEM_MOD_INTELLECT_SHORT = "Inteligencia",
    ITEM_MOD_SPIRIT_SHORT = "Sabiduria",
    ITEM_MOD_STRENGTH = "Fuerza",
    ITEM_MOD_AGILITY = "Destreza",
    ITEM_MOD_STAMINA = "Constitucion",
    ITEM_MOD_INTELLECT = "Inteligencia",
    ITEM_MOD_SPIRIT = "Sabiduria",
}

local ARMOR_SUBCLASS_TO_KIND = {
    ["Tela"] = "cloth",
    ["Cuero"] = "leather",
    ["Malla"] = "mail",
    ["Placas"] = "plate",
    ["Escudos"] = "shield",
}

local ARMOR_KIND_BASE = {
    cloth = 10,
    leather = 11,
    mail = 13,
    plate = 16,
}

-- Categoria 5e por tipo de armadura WoW (para sumar Destreza con su tope).
local ARMOR_KIND_CAT = {
    cloth = "ligera",
    leather = "ligera",
    mail = "media",
    plate = "pesada",
}

-- Set completo de armaduras D&D 5e (nombres nivel20). `cat` decide como suma la
-- Destreza al calcular la CA: ligera = Des completa; media = Des hasta +2; pesada = 0.
-- "Sin armadura" = 10 + Des (como ligera). El escudo (+2) se gestiona aparte.
local ARMOR_ICON_BASE = "Interface\\Icons\\"
local BASIC_ARMOR = {
    { key = "none",            label = "Sin armadura",        base = 10, cat = "ninguna", caText = "10 + Des" },
    -- Ligeras (CA = base + Des)
    { key = "acolchada",       label = "Acolchada",           base = 11, cat = "ligera",  caText = "11 + Des",         icon = ARMOR_ICON_BASE .. "INV_Chest_Leather_03" },
    { key = "cuero",           label = "Cuero",               base = 11, cat = "ligera",  caText = "11 + Des",         icon = ARMOR_ICON_BASE .. "INV_Chest_Leather_09" },
    { key = "cuero_tachonado", label = "Cuero tachonado",     base = 12, cat = "ligera",  caText = "12 + Des",         icon = ARMOR_ICON_BASE .. "INV_Chest_Cloth_45" },
    -- Medias (CA = base + Des, max 2)
    { key = "pieles",          label = "Pieles",              base = 12, cat = "media",   caText = "12 + Des (max 2)", icon = ARMOR_ICON_BASE .. "INV_Chest_Leather_06" },
    { key = "camisa_malla",    label = "Camisa de malla",     base = 13, cat = "media",   caText = "13 + Des (max 2)", icon = ARMOR_ICON_BASE .. "INV_Chest_Chain" },
    { key = "coraza",          label = "Coraza",              base = 14, cat = "media",   caText = "14 + Des (max 2)", icon = ARMOR_ICON_BASE .. "INV_Chest_Plate04" },
    { key = "cota_escamas",    label = "Cota de escamas",     base = 14, cat = "media",   caText = "14 + Des (max 2)", icon = ARMOR_ICON_BASE .. "INV_Chest_Chain_05" },
    { key = "media_armadura",  label = "Media armadura",      base = 15, cat = "media",   caText = "15 + Des (max 2)", icon = ARMOR_ICON_BASE .. "INV_Chest_Plate06" },
    -- Pesadas (CA = base, sin Des)
    { key = "cota_guarnecida", label = "Cota guarnecida",     base = 14, cat = "pesada",  caText = "14",               icon = ARMOR_ICON_BASE .. "INV_Chest_Chain_17" },
    { key = "cota_malla",      label = "Cota de malla",       base = 16, cat = "pesada",  caText = "16",               icon = ARMOR_ICON_BASE .. "INV_Chest_Chain_06" },
    { key = "bandas",          label = "Armadura de bandas",  base = 17, cat = "pesada",  caText = "17",               icon = ARMOR_ICON_BASE .. "INV_Chest_Plate01" },
    { key = "placas",          label = "Armadura de placas",  base = 18, cat = "pesada",  caText = "18",               icon = ARMOR_ICON_BASE .. "INV_Chest_Plate02" },
}

-- Aporte de Destreza a la CA segun categoria de armadura.
local function ArmorDexBonus(cat, dexMod)
    dexMod = tonumber(dexMod) or 0
    if cat == "media" then return math.min(dexMod, 2) end
    if cat == "pesada" then return 0 end
    return dexMod  -- ligera / ninguna: Destreza completa
end

-- Modificador de Destreza del contexto activo (jugador propio). En inspeccion es
-- aproximado (la CA manual del snapshot suele ganar por max()).
local function SelfDexMod()
    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
        return tonumber(HarfordDnDCalc.GetAbilityMod("Destreza")) or 0
    end
    return 0
end

local WEAPON_SUBCLASS_TO_KEY = {
    ["Dagas"] = "Daga",
    ["Espadas de una mano"] = "Espada larga",
    ["Espadas de dos manos"] = "Espad\195\179n",
    ["Hachas de una mano"] = "Hacha de batalla",
    ["Hachas de dos manos"] = "Gran hacha",
    ["Mazas de una mano"] = "Maza",
    ["Mazas de dos manos"] = "Mazo de guerra",
    ["Armas de asta"] = "Alabarda",
    ["Bastones"] = "Bast\195\179n",
    ["Arcos"] = "Arco largo",
    ["Ballestas"] = "Ballesta pesada",
    ["Armas de fuego"] = "Rifle",
    ["Pu\195\177os"] = "Desarmado",
    ["Varitas"] = "Dardo",
}

local ABILITY_ALIASES = {
    fuerza = "Fuerza", fue = "Fuerza",
    destreza = "Destreza", des = "Destreza",
    constitucion = "Constitucion", con = "Constitucion",
    inteligencia = "Inteligencia", int = "Inteligencia",
    sabiduria = "Sabiduria", sab = "Sabiduria",
    carisma = "Carisma", car = "Carisma",
}

local SKILL_ALIASES = {
    acrobacias = "Acrobacias",
    atletismo = "Atletismo",
    arcano = "Arcano",
    conocimientoarcano = "Arcano",
    enganio = "Engano",
    engano = "Engano",
    historia = "Historia",
    interpretacion = "Interpretacion",
    intimidacion = "Intimidacion",
    investigacion = "Investigacion",
    investigacin = "Investigacion",
    juegodemanos = "JuegoManos",
    prestidigitacion = "JuegoManos",
    medicina = "Medicina",
    naturaleza = "Naturaleza",
    percepcion = "Percepcion",
    perspicacia = "Perspicacia",
    persuasion = "Persuasion",
    religion = "Religion",
    sigilo = "Sigilo",
    supervivencia = "Supervivencia",
    tratoconanimales = "Animales",
    animales = "Animales",
}

local RULE_LABELS = {
    ca = "armorClass",
    clasearmadura = "armorClass",
    -- `NormalizeLabel` quita los espacios pero NO las palabras: "Clase de Armadura" queda
    -- `clasedearmadura`, que no casaba con nada. Quien escribia el nombre completo en la
    -- descripcion no obtenia bonus y no habia forma de saberlo desde el juego.
    clasedearmadura = "armorClass",
    armadura = "armorClass",
    escudo = "armorClass",
    iniciativa = "initiative",
    ataque = "weaponAttack",
    ataquearma = "weaponAttack",
    ataqueconarma = "weaponAttack",
    dano = "weaponDamage",
    dao = "weaponDamage",
    danio = "weaponDamage",
    danioarma = "weaponDamage",
    danoarma = "weaponDamage",
    daoarma = "weaponDamage",
    cdconjuro = "spellDC",
    cddeconjuro = "spellDC",
    ataqueconjuro = "spellAttack",
    ataquedeconjuro = "spellAttack",
}

local DAMAGE_TYPE_ALIASES = {
    acido = "acido",
    contundente = "contundente",
    cortante = "cortante",
    frio = "frio",
    fuego = "fuego",
    fuerza = "fuerza",
    rayo = "rayo",
    necrotico = "necrotico",
    perforante = "perforante",
    veneno = "veneno",
    psiquico = "psiquico",
    radiante = "radiante",
    trueno = "trueno",
}

local resolvedCache = {}
local resolvedCacheOrder = {}
local RESOLVED_CACHE_MAX = 160
local resolvedCacheCount = 0
local pendingResolveCount = 0
local perfItems = { events = 0, processed = 0, ignored = 0, evicted = 0 }
local scanTooltip
local EMPTY_EQUIPMENT = {}

local function CountTable(t)
    local n = 0
    if type(t) == "table" then
        for _ in pairs(t) do n = n + 1 end
    end
    return n
end

local function CacheResolvedItem(itemLink, resolved)
    itemLink = tostring(itemLink or "")
    if itemLink == "" then return resolved end
    local previous = resolvedCache[itemLink]
    local wasPending = previous and previous.pending == true
    local isPending = resolved and resolved.pending == true
    if previous == nil then
        resolvedCacheOrder[#resolvedCacheOrder + 1] = itemLink
        resolvedCacheCount = resolvedCacheCount + 1
    end
    if wasPending and not isPending then
        pendingResolveCount = math.max(0, pendingResolveCount - 1)
    elseif (not wasPending) and isPending then
        pendingResolveCount = pendingResolveCount + 1
    end
    resolvedCache[itemLink] = resolved
    while resolvedCacheCount > RESOLVED_CACHE_MAX and #resolvedCacheOrder > 0 do
        local old = table.remove(resolvedCacheOrder, 1)
        if old and resolvedCache[old] then
            if resolvedCache[old].pending then
                pendingResolveCount = math.max(0, pendingResolveCount - 1)
            end
            resolvedCache[old] = nil
            resolvedCacheCount = math.max(0, resolvedCacheCount - 1)
            perfItems.evicted = perfItems.evicted + 1
        end
    end
    return resolved
end

local function DropResolvedCache(itemLink)
    itemLink = tostring(itemLink or "")
    local cached = resolvedCache[itemLink]
    if not cached then return end
    if cached.pending then
        pendingResolveCount = math.max(0, pendingResolveCount - 1)
    end
    resolvedCache[itemLink] = nil
    resolvedCacheCount = math.max(0, resolvedCacheCount - 1)
    -- Y FUERA de la lista de antiguedad. Sin esto quedaba un enlace muerto ahi, y si el mismo item
    -- se volvia a resolver, `CacheResolvedItem` lo apuntaba OTRA VEZ --para el era nuevo-- y
    -- acababa dos veces en la lista: al desalojar, la primera copia borraba una entrada VIVA y la
    -- segunda no liberaba nada. La lista esta acotada al tope de la cache, asi que recorrerla sale
    -- barato.
    for i = #resolvedCacheOrder, 1, -1 do
        if resolvedCacheOrder[i] == itemLink then table.remove(resolvedCacheOrder, i) end
    end
end

local function CopyTable(src)
    local out = {}
    for k, v in pairs(src or {}) do
        if type(v) == "table" then
            out[k] = CopyTable(v)
        else
            out[k] = v
        end
    end
    return out
end

local function ResolveProfileName(profileName)
    return tostring(profileName or (UnitName and UnitName("player")) or "default")
end

-- El equipo virtual se guarda anidado en profiles[name]._equipment (todo lo de la ficha
-- agrupado por perfil). ProfileSlot devuelve (y crea) profiles[name].
local function ProfileSlot(name)
    HarfordDnDPersistStore = HarfordDnDPersistStore or {}
    if type(HarfordDnDPersistStore.profiles) ~= "table" then HarfordDnDPersistStore.profiles = {} end
    if type(HarfordDnDPersistStore.profiles[name]) ~= "table" then HarfordDnDPersistStore.profiles[name] = {} end
    return HarfordDnDPersistStore.profiles[name]
end

local function EnsureProfile(profileName)
    local name = ResolveProfileName(profileName)
    local slot = ProfileSlot(name)
    if type(slot._equipment) ~= "table" then slot._equipment = {} end
    return slot._equipment, name
end

-- Override EFIMERO (no persistido) para inspeccion read-only: el equipo del jugador
-- inspeccionado vive aqui (keyed por nombre corto) y NO se escribe en persistencia.
local inspectData = {}

local function ShortKey(name)
    name = tostring(name or "")
    if Ambiguate then
        local short = Ambiguate(name, "short")
        if short and short ~= "" then return short end
    end
    return name:match("^[^%-]+") or name
end

function API.SetInspectData(name, data)
    local key = ShortKey(name)
    if key == "" then return false end
    inspectData[key] = (type(data) == "table") and CopyTable(data) or nil
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
    end
    return true
end

function API.ClearInspectData(name)
    if name ~= nil then
        inspectData[ShortKey(name)] = nil
    else
        inspectData = {}
    end
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
    end
end

-- Tabla de equipo SOLO LECTURA: prefiere el override de inspeccion si existe.
-- Las funciones de escritura siguen usando EnsureProfile (persistencia propia).
local function ReadProfile(profileName)
    local name = ResolveProfileName(profileName)
    local ins = inspectData[ShortKey(name)]
    if ins then return ins, name end
    local persist = HarfordDnDPersistStore
    local profiles = type(persist) == "table" and persist.profiles or nil
    local slot = type(profiles) == "table" and profiles[name] or nil
    if type(slot) == "table" and type(slot._equipment) == "table" then
        return slot._equipment, name
    end
    return EMPTY_EQUIPMENT, name
end

-- Invalida la memoizacion de FeatureEffects tras cualquier cambio de equipo.
local function Touch()
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()
    end
end

local function ItemKey(itemLink)
    local text = tostring(itemLink or "")
    local itemId = text:match("item:(%d+)")
    return itemId or text
end

local function FindWeaponDefByKey(key)
    if not (HarfordDnDWeapons and HarfordDnDWeapons.WEAPONS) then return nil end
    for _, def in ipairs(HarfordDnDWeapons.WEAPONS) do
        if def.key == key then return CopyTable(def) end
    end
    return nil
end

local function GetWeaponIcon(def)
    if not def then return nil end
    -- El icono PROPIO del arma manda. Viene de la web (fuente canonica) en el campo `icon`
    -- de HarfordDnDWeapons.WEAPONS; antes todas las de cuerpo a cuerpo caian en el mismo
    -- INV_Sword_04 generico y los huecos del paperdoll se veian todos iguales.
    if def.icon and def.icon ~= "" and HarfordDnDWeapons and HarfordDnDWeapons.GetIconPath then
        return HarfordDnDWeapons.GetIconPath(def)
    end
    -- De aqui abajo, red de seguridad para entradas que aun no traigan icono propio.
    if def.key == "Escudo" then return "Interface\\Icons\\INV_Shield_04" end
    if def.mode == "Ranged" then return "Interface\\Icons\\INV_Weapon_Bow_05" end
    if def.cat == "De fuego" then return "Interface\\Icons\\INV_Weapon_Rifle_01" end
    if def.key == "Desarmado" then return "Interface\\Icons\\Ability_Rogue_Waylay" end
    return "Interface\\Icons\\INV_Sword_04"
end

local function FindArmorDefByKey(key)
    key = tostring(key or "")
    for _, def in ipairs(BASIC_ARMOR) do
        if def.key == key then return CopyTable(def) end
    end
    return nil
end

local function GetStats(itemLink)
    if not GetItemStats then return {} end
    local ok, stats = pcall(GetItemStats, itemLink)
    return (ok and type(stats) == "table") and stats or {}
end

local function StripAccentsMarkup(value)
    value = tostring(value or "")
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("|T.-|t", "")
    return HarfordClassColors.StripAccents(value)
end

local function NormalizeLabel(value)
    value = StripAccentsMarkup(value):lower()
    value = value:gsub("[^%w]+", "")
    return value
end

-- Como NormalizeLabel pero CONSERVANDO la separacion de palabras (un espacio), para
-- poder buscar nombres de arma como frase completa con limites de palabra.
local function NormalizePhrase(value)
    value = StripAccentsMarkup(value):lower()
    value = value:gsub("[^%w]+", " ")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

-- Deteccion robusta del tipo de arma: busca en una lista de textos (nombre + lineas de
-- descripcion) la clave de arma MAS ESPECIFICA (la mas larga) que aparezca como FRASE
-- COMPLETA con limites de palabra. Asi detecta el tipo este como este escrito:
-- "Espada corta +1", "Gran espada corta rota", una linea suelta "Espada corta", etc.
-- (sin confundir "Espada cortante" con "Espada corta"). Ignora "Desarmado".
local function DetectWeaponKey(texts)
    if not (HarfordDnDWeapons and HarfordDnDWeapons.WEAPONS) then return nil end
    local best, bestLen
    for _, text in ipairs(texts or {}) do
        local hay = " " .. NormalizePhrase(text) .. " "
        for _, def in ipairs(HarfordDnDWeapons.WEAPONS) do
            if def.key ~= "Desarmado" then
                local needle = NormalizePhrase(def.key)
                if needle ~= "" and hay:find(" " .. needle .. " ", 1, true) then
                    if not bestLen or #needle > bestLen then
                        best, bestLen = def.key, #needle
                    end
                end
            end
        end
    end
    return best
end

-- Clave de armadura BASICA mas especifica que aparezca como frase en el texto (la
-- descripcion "Armadura <X>" del About TRP3). "none"/Sin armadura se ignora -> desarmado.
local function FindBasicArmorKeyByText(text)
    local hay = " " .. NormalizePhrase(text) .. " "
    local best, bestLen
    for _, def in ipairs(BASIC_ARMOR) do
        if def.key ~= "none" then
            local needle = NormalizePhrase(def.label)
            if needle ~= "" and hay:find(" " .. needle .. " ", 1, true) then
                if not bestLen or #needle > bestLen then best, bestLen = def.key, #needle end
            end
        end
    end
    return best
end

local function CleanTooltipLine(value)
    value = tostring(value or "")
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("|T.-|t", "")
    value = value:gsub("%$%x%x%x%x%x%x%$", ""):gsub("%$", "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function ExtractMarkedSegments(value)
    value = tostring(value or "")
    local out = {}
    for segment in value:gmatch("|c%x%x%x%x%x%x%x%x(.-)|r") do
        segment = CleanTooltipLine(segment)
        if segment ~= "" then out[#out + 1] = segment end
    end
    for segment in value:gmatch("%$%x%x%x%x%x%x%$(.-)%$") do
        segment = CleanTooltipLine(segment)
        if segment ~= "" then out[#out + 1] = segment end
    end
    return out
end

local function MarkedNarrativeRemainder(value)
    value = tostring(value or "")
    value = value:gsub("|c%x%x%x%x%x%x%x%x.-|r", "")
    value = value:gsub("%$%x%x%x%x%x%x%$.-%$", "")
    return CleanTooltipLine(value)
end

local function GetScanTooltip()
    if scanTooltip or not CreateFrame then return scanTooltip end
    scanTooltip = CreateFrame("GameTooltip", "HarfordDnDItemsScanTooltip", UIParent, "GameTooltipTemplate")
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    return scanTooltip
end

local function ScanTooltipLines(itemLink)
    local tip = GetScanTooltip()
    if not tip or not itemLink then return {} end
    tip:ClearLines()
    local ok = pcall(tip.SetHyperlink, tip, itemLink)
    if not ok then return {} end
    local lines = {}
    local name = tip:GetName()
    for i = 2, 30 do
        local left = _G[name .. "TextLeft" .. tostring(i)]
        local right = _G[name .. "TextRight" .. tostring(i)]
        local text = left and left:GetText()
        if text and text ~= "" then lines[#lines + 1] = tostring(text) end
        local rtext = right and right:GetText()
        if rtext and rtext ~= "" then lines[#lines + 1] = tostring(rtext) end
    end
    tip:ClearLines()
    return lines
end

local function ResolveRuleLabel(label)
    local normalized = NormalizeLabel(label)
    if ABILITY_ALIASES[normalized] then return "ability", ABILITY_ALIASES[normalized] end
    if SKILL_ALIASES[normalized] then return "skill", SKILL_ALIASES[normalized] end
    if RULE_LABELS[normalized] then return RULE_LABELS[normalized] end

    local saveAbility = normalized:match("^salvacion(.+)$")
        or normalized:match("^salv(.+)$")
        or normalized:match("^tiradadesalvacion(.+)$")
    if saveAbility and ABILITY_ALIASES[saveAbility] then
        return "save", ABILITY_ALIASES[saveAbility]
    end
    return nil
end

local function AddRule(rules, kind, key, value)
    value = tonumber(value) or 0
    if not kind or value == 0 then return end
    rules.list[#rules.list + 1] = { kind = kind, key = key, value = value }
    if kind == "ability" then
        rules.ability[key] = (tonumber(rules.ability[key]) or 0) + value
    elseif kind == "skill" then
        rules.skill[key] = (tonumber(rules.skill[key]) or 0) + value
    elseif kind == "save" then
        rules.save[key] = (tonumber(rules.save[key]) or 0) + value
    elseif rules[kind] ~= nil then
        rules[kind] = (tonumber(rules[kind]) or 0) + value
    end
end

local function ParseDamageType(value)
    local normalized = NormalizeLabel(value)
    return DAMAGE_TYPE_ALIASES[normalized] or tostring(value or ""):lower()
end

local function AddExtraDamageRule(rules, dice, damageType)
    dice = tostring(dice or "")
    local n, sides = dice:match("^(%d+)d(%d+)$")
    n, sides = tonumber(n), tonumber(sides)
    if not n or not sides or n <= 0 or sides <= 0 then return false end
    local entry = {
        kind = "extraDamageDice",
        dice = tostring(n) .. "d" .. tostring(sides),
        damageType = ParseDamageType(damageType or ""),
    }
    rules.extraDamage[#rules.extraDamage + 1] = entry
    rules.list[#rules.list + 1] = entry
    return true
end

local function ParseDiceDamageSegment(text)
    local clean = CleanTooltipLine(text)
    local dice, after = clean:match("(%d+d%d+)%s*(.*)$")
    if not dice then return nil end
    after = after:gsub("^%s*[%+%-]?%s*%d*%s*", "")
    after = after:gsub("^de%s+", ""):gsub("^da\195\177o%s+", "")
    after = after:gsub("^dano%s+", ""):gsub("^danio%s+", "")
    after = after:gsub("^por%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return dice, after
end

local function ParseAllDiceDamageSegments(text)
    local out = {}
    local clean = CleanTooltipLine(text)
    for dice, dtype in clean:gmatch("(%d+d%d+)%s+([%a\128-\255]+)") do
        out[#out + 1] = { dice = dice, damageType = dtype }
    end
    return out
end

local function ParseExtraDamageLine(line)
    local clean = CleanTooltipLine(line)
    local normalized = NormalizeLabel(clean)
    if not normalized:find("dano", 1, true) and not normalized:find("danio", 1, true) then
        return nil
    end
    if not normalized:find("extra", 1, true) and not normalized:find("adicional", 1, true) then
        return nil
    end
    local dice = clean:match("(%d+d%d+)")
    if not dice then return nil end
    return ParseDiceDamageSegment(clean)
end

-- Busca una clave de arma de HarfordDnDWeapons por nombre (normalizado, sin acentos/caso).
-- Permite que la descripcion declare el tipo exacto de arma D&D cuando la subclase WoW no
-- distingue (p.ej. "Espadas de una mano" -> espada larga/corta/estoque/cimitarra...).
local function FindWeaponKeyByName(name)
    local target = NormalizeLabel(name)
    if target == "" then return nil end
    if not (HarfordDnDWeapons and HarfordDnDWeapons.WEAPONS) then return nil end
    for _, def in ipairs(HarfordDnDWeapons.WEAPONS) do
        if NormalizeLabel(def.key) == target then return def.key end
    end
    return nil
end

local function ApplyMarkedSegmentRule(rules, segment)
    segment = CleanTooltipLine(segment)
    if segment == "" then return false end
    local parsed = false

    if not rules.weaponOverride then
        local wkey = FindWeaponKeyByName(segment) or DetectWeaponKey({ segment })
        if wkey then
            rules.weaponOverride = wkey
            rules.list[#rules.list + 1] = { kind = "weaponType", key = wkey }
            parsed = true
        end
    end

    for _, item in ipairs(ParseAllDiceDamageSegments(segment)) do
        if AddExtraDamageRule(rules, item.dice, item.damageType) then
            parsed = true
        end
    end

    -- Bonus/penalizadores mecanicos: requieren etiqueta explicita ANTES del signo.
    -- Ej.: "Ataque -3", "Dano +3", "Investigacion +1". Un "+1" suelto se ignora.
    local tokens = {}
    for token in segment:gmatch("%S+") do tokens[#tokens + 1] = token end
    for i, token in ipairs(tokens) do
        local sign, amount = tostring(token):match("^([%+%-])(%d+)$")
        if sign and amount then
            for span = math.min(4, i - 1), 1, -1 do
                local parts = {}
                for j = i - span, i - 1 do parts[#parts + 1] = tokens[j] end
                local label = table.concat(parts, " "):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[:：]+$", "")
                local kind, key = ResolveRuleLabel(label)
                if kind then
                    local value = tonumber(amount) or 0
                    if sign == "-" then value = -value end
                    AddRule(rules, kind, key, value)
                    parsed = true
                    break
                end
            end
        end
    end

    local baseLabel, baseAmount = segment:match("^%s*(.-)%s+(%d+)%s*$")
    local normalized = NormalizeLabel(baseLabel)
    if baseAmount and (normalized == "ca" or normalized == "armadura" or normalized == "clasearmadura") then
        rules.armorBase = math.max(tonumber(rules.armorBase) or 0, tonumber(baseAmount) or 0)
        rules.list[#rules.list + 1] = { kind = "armorBase", value = tonumber(baseAmount) or 0 }
        parsed = true
    end

    return parsed
end

local function ParseTooltipRules(lines)
    local rules = {
        list = {},
        ability = {},
        skill = {},
        save = {},
        armorClass = 0,
        armorBase = nil,
        initiative = 0,
        weaponAttack = 0,
        weaponDamage = 0,
        spellAttack = 0,
        spellDC = 0,
        extraDamage = {},
    }
    local description = {}
    for _, line in ipairs(lines or {}) do
        local parsed = false
        local markedParsed = false
        local fallbackParsed = false
        for _, segment in ipairs(ExtractMarkedSegments(line)) do
            if ApplyMarkedSegmentRule(rules, segment) then
                parsed = true
                markedParsed = true
            end
        end
        if not markedParsed and DetectWeaponKey({ CleanTooltipLine(line) }) then
            if ApplyMarkedSegmentRule(rules, line) then
                parsed = true
                fallbackParsed = true
            end
        end
        local extraDice, extraType = ParseExtraDamageLine(line)
        if extraDice then
            parsed = AddExtraDamageRule(rules, extraDice, extraType)
        end
        local label, sign, amount = line:match("^%s*(.-)%s*([%+%-])%s*(%d+)%s*$")
        if not parsed and label and sign and amount then
            label = label:gsub("[:：]+$", "")
            local kind, key = ResolveRuleLabel(label)
            if kind then
                local value = tonumber(amount) or 0
                if sign == "-" then value = -value end
                AddRule(rules, kind, key, value)
                parsed = true
            end
        end
        if not parsed then
            local baseLabel, baseAmount = line:match("^%s*(.-)%s+(%d+)%s*$")
            local normalized = NormalizeLabel(baseLabel)
            if baseAmount and (normalized == "ca" or normalized == "armadura" or normalized == "clasearmadura") then
                rules.armorBase = math.max(tonumber(rules.armorBase) or 0, tonumber(baseAmount) or 0)
                rules.list[#rules.list + 1] = { kind = "armorBase", value = tonumber(baseAmount) or 0 }
                parsed = true
            end
        end
        -- Declaracion EXPLICITA del tipo con prefijo ("Arma: Espada corta" / "Tipo de
        -- arma: ..."): consume y oculta la linea. El resto de formas (nombre, linea suelta,
        -- tipo embebido en texto mas largo) las cubre DetectWeaponKey en ResolveFromClient.
        if not parsed and not rules.weaponOverride then
            local armaName = line:match("^%s*[Aa]rma%s*:%s*(.+)$")
                or line:match("^%s*[Tt]ipo de [Aa]rma%s*:%s*(.+)$")
            local wkey = armaName and FindWeaponKeyByName(armaName) or nil
            if wkey then
                rules.weaponOverride = wkey
                rules.list[#rules.list + 1] = { kind = "weaponType", key = wkey }
                parsed = true
            end
        end
        if markedParsed then
            local narrative = MarkedNarrativeRemainder(line)
            if narrative ~= "" then description[#description + 1] = narrative end
        elseif fallbackParsed then
            description[#description + 1] = CleanTooltipLine(line)
        elseif not parsed and line ~= "" then
            description[#description + 1] = CleanTooltipLine(line)
        end
    end
    return rules, description
end

local function ResolveCategory(itemClass, itemSubClass, equipLoc)
    if equipLoc == "INVTYPE_SHIELD" or itemSubClass == "Escudos" then return "escudo" end
    if itemClass == "Arma" or itemClass == "Weapon" then return "arma" end
    if itemClass == "Armadura" or itemClass == "Armor" then return "armadura" end
    return "misc"
end

local function BuildWeapon(itemSubClass, itemName, itemLink, rules)
    -- El tipo declarado en la descripcion (rules.weaponOverride) manda sobre la subclase WoW.
    local key = (rules and rules.weaponOverride) or WEAPON_SUBCLASS_TO_KEY[tostring(itemSubClass or "")]
    local def = key and FindWeaponDefByKey(key) or nil
    if not def then return nil end
    def.itemName = itemName
    def.itemLink = itemLink
    def.source = "item"
    def.extraDamage = CopyTable((rules and rules.extraDamage) or {})
    return def
end

local function BuildShieldWeapon(itemName, itemLink, rules)
    local def = FindWeaponDefByKey("Escudo")
    if not def then return nil end
    def.itemName = itemName or "Escudo"
    def.itemLink = itemLink
    def.source = "item"
    def.extraDamage = CopyTable((rules and rules.extraDamage) or {})
    return def
end

-- Bonus automatico por rareza/calidad del objeto (estilo arma/armadura magica +N):
-- Verde/Infrecuente +1, Azul/Raro +2, Morado/Epico +3, Naranja/Legendario +4.
-- En armas se aplica a ataque y daño; en armadura/escudo a la CA.
local QUALITY_BONUS = { [2] = 1, [3] = 2, [4] = 3, [5] = 4 }

-- Calidad derivada del COLOR del itemLink. Mas fiable para items custom de Epsilon, cuyo
-- GetItemInfo a veces devuelve una rareza distinta a la que muestra el color del enlace.
local LINK_COLOR_QUALITY = {
    ["9d9d9d"] = 0, ["ffffff"] = 1, ["1eff00"] = 2,
    ["0070dd"] = 3, ["a335ee"] = 4, ["ff8000"] = 5,
}
local function QualityFromLink(itemLink)
    local rgb = tostring(itemLink or ""):match("|c%x%x(%x%x%x%x%x%x)")
    return rgb and LINK_COLOR_QUALITY[rgb:lower()] or nil
end

local function ResolveFromClient(itemLink)
    local name, link, quality, itemLevel, reqLevel, itemClass, itemSubClass, maxStack, equipLoc, icon =
        GetItemInfo and GetItemInfo(itemLink)
    if not name then
        if GetItemInfo then pcall(GetItemInfo, itemLink) end
        return {
            itemLink = itemLink,
            itemId = ItemKey(itemLink),
            pending = true,
            icon = GetItemIcon and GetItemIcon(itemLink) or nil,
        }
    end

    local detailedLevel = itemLevel
    if GetDetailedItemLevelInfo then
        local ok, level = pcall(GetDetailedItemLevelInfo, itemLink)
        if ok and level then detailedLevel = level end
    end

    local category = ResolveCategory(itemClass, itemSubClass, equipLoc)
    local tooltipLines = ScanTooltipLines(link or itemLink)
    local rules, descriptionLines = ParseTooltipRules(tooltipLines)
    -- Deteccion robusta del tipo (si no hubo declaracion explicita "Arma: ..."): busca el
    -- arma como frase completa en el NOMBRE y en las lineas de descripcion. Cubre "Espada
    -- corta +1", una linea suelta "Espada corta", o el tipo embebido en texto mas largo.
    if not rules.weaponOverride then
        local texts = { name }
        for _, l in ipairs(descriptionLines) do texts[#texts + 1] = l end
        rules.weaponOverride = DetectWeaponKey(texts)
    end
    local resolved = {
        itemLink = link or itemLink,
        itemId = ItemKey(link or itemLink),
        name = name,
        quality = quality,
        itemLevel = detailedLevel,
        reqLevel = reqLevel,
        itemClass = itemClass,
        itemSubClass = itemSubClass,
        equipLoc = equipLoc,
        icon = icon or (GetItemIcon and GetItemIcon(itemLink)),
        category = category,
        stats = GetStats(link or itemLink),
        tooltipLines = tooltipLines,
        descriptionLines = descriptionLines,
        rules = rules,
        pending = false,
    }
    resolved.armorKind = ARMOR_SUBCLASS_TO_KIND[tostring(itemSubClass or "")]
    -- El tipo D&D de la armadura, del NOMBRE o de la descripcion, igual que ya se hace con las
    -- armas. Antes salia SOLO de la subclase de WoW, y WoW nada mas distingue Tela/Cuero/Malla/
    -- Placas: un cuero tachonado (base 12) entraba como cuero (base 11) y no habia forma de
    -- decirlo. `FindBasicArmorKeyByText` ya existia para leer la ficha de TRP3 y busca la
    -- etiqueta MAS LARGA que aparezca como frase completa, asi que "cuero tachonado" gana a
    -- "cuero" en vez de quedarse en el primero que casa.
    if category == "armadura" then
        local textos = { name }
        for _, l in ipairs(descriptionLines) do textos[#textos + 1] = l end
        for _, texto in ipairs(textos) do
            local clave = FindBasicArmorKeyByText(texto)
            if clave then resolved.armorBasicKey = clave break end
        end
    end
    -- Prioridad del arma resuelta: tipo declarado en descripcion > escudo > arma por subclase.
    if rules.weaponOverride then
        resolved.weapon = BuildWeapon(itemSubClass, name, link or itemLink, rules)
    elseif category == "escudo" or equipLoc == "INVTYPE_SHIELD" then
        resolved.weapon = BuildShieldWeapon(name, link or itemLink, rules)
    elseif category == "arma" then
        resolved.weapon = BuildWeapon(itemSubClass, name, link or itemLink, rules)
    end

    -- Bonus por calidad/rareza: armadura/escudo -> +N CA; arma -> +N ataque y daño.
    -- (El escudo se evalua antes que el arma: su +N va a CA, no al golpe de escudo.)
    -- La calidad se toma del color del enlace si esta disponible (mas fiable en Epsilon).
    local effectiveQuality = QualityFromLink(link or itemLink) or quality
    resolved.quality = effectiveQuality
    local qb = QUALITY_BONUS[tonumber(effectiveQuality) or 0]
    if qb then
        resolved.qualityBonus = qb
        if category == "escudo" or category == "armadura" or equipLoc == "INVTYPE_SHIELD" then
            rules.armorClass = (tonumber(rules.armorClass) or 0) + qb
            rules.list[#rules.list + 1] = { kind = "qualityBonus", target = "armorClass", value = qb }
        elseif resolved.weapon then
            rules.weaponAttack = (tonumber(rules.weaponAttack) or 0) + qb
            rules.weaponDamage = (tonumber(rules.weaponDamage) or 0) + qb
            rules.list[#rules.list + 1] = { kind = "qualityBonus", target = "weapon", value = qb }
        end
    end
    if resolved.weapon then
        -- Bonos mecanicos del arma (rareza + lineas "Ataque/Daño +N") son del slot
        -- equipado, no bonos globales de personaje. HarfordDnD.lua los suma solo al
        -- arma activa para que main hand no contamine offhand.
        resolved.weapon.weaponAttackBonus = tonumber(rules.weaponAttack) or 0
        resolved.weapon.weaponDamageBonus = tonumber(rules.weaponDamage) or 0
    end
    return resolved
end

function API.GetSlotOrder()
    return SLOT_ORDER
end

function API.GetSlot(slotKey, profileName)
    local profile = ReadProfile(profileName)
    local entry = profile[tostring(slotKey or "")]
    if type(entry) == "table" then return entry end
    if type(entry) == "string" and entry ~= "" then return { itemLink = entry } end
    return nil
end

function API.GetEquipment(profileName)
    local profile = ReadProfile(profileName)
    return profile
end

function API.SetEquipment(profileName, data)
    local name = ResolveProfileName(profileName)
    ProfileSlot(name)._equipment = type(data) == "table" and CopyTable(data) or {}
    Touch()
    return true
end

-- ¿El arma de un slot ocupa las dos manos? `GetEquippedWeapon` ya resuelve tanto el objeto de
-- Epsilon como el arma basica, asi que no hace falta mirar la entrada a mano.
local DOS_MANOS_EQUIPLOC = {
    INVTYPE_2HWEAPON = true,
    INVTYPE_RANGED = true,
    INVTYPE_RANGEDRIGHT = true,
}

function API.SlotIsTwoHanded(slotKey, profileName)
    -- 1) Señal nativa del objeto: funciona con CUALQUIER arma de Epsilon, aunque su tipo D&D no
    -- se haya podido deducir del nombre ni de la descripcion.
    local entry = API.GetSlot(slotKey, profileName)
    if entry and entry.itemLink and entry.itemLink ~= "" then
        local resolved = API.ResolveItem(entry.itemLink)
        if resolved and DOS_MANOS_EQUIPLOC[tostring(resolved.equipLoc or "")] then
            -- La ranura nativa a distancia agrupa arcos con PISTOLAS y varitas. Si el tipo D&D del
            -- arma dice que no es de dos manos, manda el libro: una pistola no desequipa el escudo.
            --
            -- `DetectWeaponKey` recibe una LISTA de textos, `props` es una TABLA -- no una cadena --
            -- y el def se busca recorriendo `WEAPONS`, que es una lista.
            local clave = DetectWeaponKey({ resolved.name or "", entry.itemLink })
            local def = clave and FindWeaponDefByKey(clave)
            if def then
                for _, prop in ipairs(def.props or {}) do
                    if tostring(prop) == "Dos manos" then return true end
                end
                return false
            end
            return true
        end
    end
    -- 2) Propiedad D&D del arma (basica, o deducida del objeto).
    local def = API.GetEquippedWeapon(slotKey, profileName)
    if not def then return false end
    if HarfordDnDStore and HarfordDnDStore.HasWeaponProp then
        return HarfordDnDStore.HasWeaponProp(def, "Dos manos") and true or false
    end
    for _, p in ipairs(def.props or {}) do
        if tostring(p) == "Dos manos" then return true end
    end
    return false
end

-- Si la mano principal pasa a llevar un arma a dos manos, se vacia la secundaria.
local function EnforceTwoHanded(slotKey, profileName)
    if tostring(slotKey or "") ~= "MainHand" then return end
    if API.SlotIsTwoHanded("MainHand", profileName) then
        API.UnequipSlot("SecondaryHand", profileName)
    end
end

function API.EquipSlot(slotKey, itemLink, profileName)
    slotKey = tostring(slotKey or "")
    itemLink = tostring(itemLink or "")
    if slotKey == "" or itemLink == "" then return false end
    local profile = EnsureProfile(profileName)
    local entry = type(profile[slotKey]) == "table" and profile[slotKey] or {}
    entry.itemLink = itemLink
    entry.itemId = ItemKey(itemLink)
    profile[slotKey] = entry
    DropResolvedCache(itemLink)
    EnforceTwoHanded(slotKey, profileName)
    Touch()
    return true
end

-- Desequipa el slot por completo: quita tanto el objeto como la seleccion basica
-- (arma/armadura). El slot queda vacio -> arma = Desarmado hasta que se elija un basico
-- o se equipe otro objeto (no se conserva ningun "basico guardado" bajo el objeto).
function API.UnequipSlot(slotKey, profileName)
    local profile = EnsureProfile(profileName)
    local key = tostring(slotKey or "")
    profile[key] = nil
    Touch()
    return true
end

function API.GetBasicWeapons()
    local out = {}
    if not (HarfordDnDWeapons and HarfordDnDWeapons.WEAPONS) then return out end
    for _, def in ipairs(HarfordDnDWeapons.WEAPONS) do
        out[#out + 1] = {
            key = def.key,
            label = def.key,
            cat = def.cat,
            icon = GetWeaponIcon(def),
        }
    end
    table.sort(out, function(a, b)
        return tostring(a.cat or "") .. tostring(a.label or "") < tostring(b.cat or "") .. tostring(b.label or "")
    end)
    return out
end

function API.GetBasicArmors()
    return CopyTable(BASIC_ARMOR)
end

function API.GetArmorMenuGroups()
    local order = { "ligera", "media", "pesada" }
    local labels = {
        ligera = "Armaduras ligeras",
        media = "Armaduras medias",
        pesada = "Armaduras pesadas",
    }
    local byKey, groups = {}, {}
    for _, key in ipairs(order) do
        local group = { key = key, text = labels[key], items = {} }
        byKey[key] = group
        groups[#groups + 1] = group
    end
    for _, armor in ipairs(BASIC_ARMOR) do
        local group = byKey[armor.cat]
        if group then group.items[#group.items + 1] = CopyTable(armor) end
    end
    return groups
end

function API.SetBasicWeapon(slotKey, weaponKey, profileName)
    local profile = EnsureProfile(profileName)
    slotKey = tostring(slotKey or "")
    if slotKey == "" then return false end
    local entry = type(profile[slotKey]) == "table" and profile[slotKey] or {}
    weaponKey = tostring(weaponKey or "")
    entry.basicWeaponKey = weaponKey ~= "" and weaponKey or nil
    if not entry.itemLink and not entry.basicWeaponKey and not entry.basicArmorKey then
        profile[slotKey] = nil
    else
        profile[slotKey] = entry
    end
    EnforceTwoHanded(slotKey, profileName)
    Touch()
    return true
end

function API.GetBasicWeapon(slotKey, profileName)
    local entry = API.GetSlot(slotKey, profileName)
    return entry and entry.basicWeaponKey or nil
end

function API.GetBasicWeaponInfo(slotKey, profileName)
    local weaponKey = API.GetBasicWeapon(slotKey, profileName)
    local def = weaponKey and FindWeaponDefByKey(weaponKey) or nil
    if not def then return nil end
    return {
        key = def.key,
        label = def.key,
        icon = GetWeaponIcon(def),
        def = def,
    }
end

function API.SetBasicArmor(slotKey, armorKey, profileName)
    local profile = EnsureProfile(profileName)
    slotKey = tostring(slotKey or "")
    if slotKey == "" then return false end
    local entry = type(profile[slotKey]) == "table" and profile[slotKey] or {}
    armorKey = tostring(armorKey or "")
    -- "none" (Sin armadura) = limpiar la seleccion (no deja icono ni CA de equipo).
    entry.basicArmorKey = (armorKey ~= "" and armorKey ~= "none") and armorKey or nil
    if not entry.itemLink and not entry.basicWeaponKey and not entry.basicArmorKey then
        profile[slotKey] = nil
    else
        profile[slotKey] = entry
    end
    Touch()
    return true
end

function API.GetBasicArmor(slotKey, profileName)
    local entry = API.GetSlot(slotKey, profileName)
    return entry and entry.basicArmorKey or nil
end

-- Carga el equipo BASICO desde una ficha parseada del TRP3 (HarfordTRP3.ParsePlayerSheet):
-- vacia Chest/MainHand/SecondaryHand y coloca armadura basica (por descripcion), arma(s)
-- basicas (por DetectWeaponKey) y escudo si procede. Las armas/armaduras con nombre propio
-- que no resuelven a un basico se omiten (quedan desarmado/sin armadura).
function API.LoadBasicEquipmentFromSheet(sheet, profileName)
    if type(sheet) ~= "table" then return end
    for _, slot in ipairs({ "Chest", "MainHand", "SecondaryHand" }) do
        API.UnequipSlot(slot, profileName)
    end

    if sheet.armorDesc and sheet.armorDesc ~= "" then
        local key = FindBasicArmorKeyByText(sheet.armorDesc)
        if key then API.SetBasicArmor("Chest", key, profileName) end
    end

    local handSlots, placed = { "MainHand", "SecondaryHand" }, 0
    for _, wtext in ipairs(sheet.weapons or {}) do
        if placed >= 2 then break end
        local key = DetectWeaponKey({ wtext })
        if key then
            placed = placed + 1
            API.SetBasicWeapon(handSlots[placed], key, profileName)
        end
    end

    if sheet.hasShield and placed < 2 then
        API.SetBasicWeapon("SecondaryHand", "Escudo", profileName)
    end
    Touch()
end

function API.GetBasicArmorInfo(slotKey, profileName)
    local armorKey = API.GetBasicArmor(slotKey, profileName)
    local def = armorKey and FindArmorDefByKey(armorKey) or nil
    if not def then return nil end
    return {
        key = def.key,
        label = def.label,
        base = def.base,
        cat = def.cat,
        caText = def.caText,
        icon = def.icon or "Interface\\Icons\\INV_Chest_Leather_09",
    }
end

function API.GetSlotBasicLabel(slotKey, profileName)
    local entry = API.GetSlot(slotKey, profileName)
    if not entry then return nil end
    if entry.basicWeaponKey then return entry.basicWeaponKey end
    local armor = entry.basicArmorKey and FindArmorDefByKey(entry.basicArmorKey) or nil
    return armor and armor.label or nil
end

-- forceResolve solo lo usa RefreshPending (evento GET_ITEM_INFO_RECEIVED): las lecturas
-- normales devuelven el pending cacheado SIN re-escanear el tooltip (era O(lecturas) caro).
function API.ResolveItem(itemLink, forceResolve)
    itemLink = tostring(itemLink or "")
    if itemLink == "" then return nil end
    local cached = resolvedCache[itemLink]
    if cached and (not cached.pending or not forceResolve) then return cached end
    local resolved = ResolveFromClient(itemLink)
    return CacheResolvedItem(itemLink, resolved)
end

function API.ResolveSlot(slotKey, profileName)
    local entry = API.GetSlot(slotKey, profileName)
    return entry and API.ResolveItem(entry.itemLink) or nil
end

function API.GetDescriptionLines(itemLink)
    local resolved = API.ResolveItem(itemLink)
    return resolved and resolved.descriptionLines or {}
end

function API.GetParsedRules(itemLink)
    local resolved = API.ResolveItem(itemLink)
    return resolved and resolved.rules or nil
end

function API.GetEquippedBonuses(profileName)
    local bonuses = {
        ability = {},
        skill = {},
        save = {},
        armorClass = 0,
        initiative = 0,
        weaponAttack = 0,
        weaponDamage = 0,
        spellAttack = 0,
        spellDC = 0,
    }
    local profile = ReadProfile(profileName)
    for _, entry in pairs(profile) do
        local resolved = type(entry) == "table" and API.ResolveItem(entry.itemLink) or nil
        for statKey, value in pairs((resolved and resolved.stats) or {}) do
            local ability = STAT_TO_ABILITY[statKey]
            if ability then
                bonuses.ability[ability] = (tonumber(bonuses.ability[ability]) or 0) + (tonumber(value) or 0)
            end
        end
        local rules = resolved and resolved.rules
        for abilityKey, value in pairs((rules and rules.ability) or {}) do
            bonuses.ability[abilityKey] = (tonumber(bonuses.ability[abilityKey]) or 0) + (tonumber(value) or 0)
        end
        for skillKey, value in pairs((rules and rules.skill) or {}) do
            bonuses.skill[skillKey] = (tonumber(bonuses.skill[skillKey]) or 0) + (tonumber(value) or 0)
        end
        for saveKey, value in pairs((rules and rules.save) or {}) do
            bonuses.save[saveKey] = (tonumber(bonuses.save[saveKey]) or 0) + (tonumber(value) or 0)
        end
        for _, key in ipairs({ "armorClass", "initiative", "weaponAttack", "weaponDamage", "spellAttack", "spellDC" }) do
            local value = tonumber(rules and rules[key]) or 0
            if (key == "weaponAttack" or key == "weaponDamage")
                and (resolved and (resolved.weapon or resolved.category == "arma")) then
                value = 0
            end
            bonuses[key] = (tonumber(bonuses[key]) or 0) + value
        end
    end
    return bonuses
end

function API.GetEquippedWeapon(slotKey, profileName)
    slotKey = slotKey or "MainHand"
    local entry = API.GetSlot(slotKey, profileName)
    local resolved = entry and entry.itemLink and API.ResolveItem(entry.itemLink) or nil
    if resolved and resolved.weapon then return resolved.weapon end
    if entry and entry.itemLink then return nil end
    local weaponKey = entry and entry.basicWeaponKey
    local def = weaponKey and FindWeaponDefByKey(weaponKey) or nil
    if def then
        def.source = "basic"
        def.basicSlotKey = slotKey
        def.icon = GetWeaponIcon(def)
    end
    return def
end

function API.HasOffhandCombatItem(profileName)
    local entry = API.GetSlot("SecondaryHand", profileName)
    if not entry then return false end
    if entry.basicWeaponKey and entry.basicWeaponKey ~= "" then return true end
    if not entry.itemLink or entry.itemLink == "" then return false end

    local resolved = API.ResolveItem(entry.itemLink)
    if not resolved then return false end
    if resolved.pending then return true end
    return resolved.weapon ~= nil
        or resolved.category == "escudo"
        or resolved.equipLoc == "INVTYPE_SHIELD"
end

function API.GetEquippedArmorClass(profileName)
    local profile = ReadProfile(profileName)
    local dex = SelfDexMod()
    local bestArmor, shieldBonus = nil, 0
    local function consider(finalCA)
        finalCA = tonumber(finalCA)
        if finalCA then bestArmor = math.max(bestArmor or 0, finalCA) end
    end
    for slotKey, entry in pairs(profile) do
        local resolved = type(entry) == "table" and API.ResolveItem(entry.itemLink) or nil
        if resolved and not resolved.pending then
            if resolved.category == "escudo" or resolved.equipLoc == "INVTYPE_SHIELD" then
                shieldBonus = math.max(shieldBonus, 2)
            elseif resolved.category == "armadura" and slotKey == "Chest" then
                -- El tipo reconocido por el nombre manda sobre la subclase de WoW: lleva la base y
                -- la categoria D&D de verdad (cuero tachonado 12 ligera, cota de malla 16 pesada),
                -- que la subclase no puede distinguir.
                local def = resolved.armorBasicKey and FindArmorDefByKey(resolved.armorBasicKey) or nil
                if def and def.base then
                    consider(def.base + ArmorDexBonus(def.cat, dex))
                else
                    local base = ARMOR_KIND_BASE[resolved.armorKind]
                    if base then consider(base + ArmorDexBonus(ARMOR_KIND_CAT[resolved.armorKind], dex)) end
                end
            end
            -- CA explicita del item (ya final): no se le suma Destreza automatica. SOLO desde el
            -- pecho: `armorBase` sale de una linea `Armadura 14` de la descripcion, y se estaba
            -- leyendo desde CUALQUIER hueco -- un anillo, una capa o unas botas con esa linea
            -- fijaban tu CA entera. La armadura del cuerpo es la que pone la CA base; lo que
            -- lleven los demas huecos suma como bonus (`ca`), no sustituye.
            if slotKey == "Chest" and resolved.rules and resolved.rules.armorBase then
                consider(resolved.rules.armorBase)
            end
        elseif type(entry) == "table" and not entry.itemLink then
            if slotKey == "Chest" and entry.basicArmorKey then
                local armor = FindArmorDefByKey(entry.basicArmorKey)
                if armor and armor.base then consider(armor.base + ArmorDexBonus(armor.cat, dex)) end
            elseif slotKey == "SecondaryHand" and entry.basicWeaponKey == "Escudo" then
                shieldBonus = math.max(shieldBonus, 2)
            end
        end
    end
    if bestArmor or shieldBonus > 0 then
        return (bestArmor or (10 + dex)) + shieldBonus  -- sin armadura: 10 + Des (p.ej. solo escudo)
    end
    return nil
end

function API.RefreshPending()
    perfItems.events = perfItems.events + 1
    if pendingResolveCount <= 0 then
        perfItems.ignored = perfItems.ignored + 1
        return false, {}
    end
    local changed = false
    local changedProfiles = {}
    local function markProfile(profileName)
        profileName = tostring(profileName or "")
        if profileName ~= "" then changedProfiles[profileName] = true end
    end
    local function scan(profile, profileName)
        if type(profile) ~= "table" then return end
        for _, entry in pairs(profile) do
            if type(entry) == "table" and entry.itemLink then
                local cached = resolvedCache[tostring(entry.itemLink or "")]
                if not cached or cached.pending then
                    local resolved = API.ResolveItem(entry.itemLink, true)  -- fuerza re-resolucion solo si estaba pendiente
                    if resolved and not resolved.pending then
                        changed = true
                        markProfile(profileName)
                    end
                end
            end
        end
    end
    -- Equipo anidado: profiles[name]._equipment de todos los perfiles persistidos.
    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
    if type(profiles) == "table" then
        for profileName, p in pairs(profiles) do
            if type(p) == "table" then scan(p._equipment, profileName) end
        end
    end
    for profileName, profile in pairs(inspectData) do scan(profile, profileName) end
    if changed and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Invalidate then
        HarfordDnDFeatureEffects.Invalidate()  -- los bonus de equipo pueden haber cambiado
    end
    if changed then
        perfItems.processed = perfItems.processed + 1
    else
        perfItems.ignored = perfItems.ignored + 1
    end
    return changed, changedProfiles
end

function API.GetPerfItems(reset)
    local snapshot = {
        events = perfItems.events,
        processed = perfItems.processed,
        ignored = perfItems.ignored,
        evicted = perfItems.evicted,
        cache = resolvedCacheCount,
        pending = pendingResolveCount,
        max = RESOLVED_CACHE_MAX,
    }
    if reset then
        perfItems.events = 0
        perfItems.processed = 0
        perfItems.ignored = 0
        perfItems.evicted = 0
    end
    return snapshot
end

if CreateFrame then
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    eventFrame:SetScript("OnEvent", function()
        local changed, changedProfiles = API.RefreshPending()
        if changed then
            if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
            if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then _G.DND5E_ARC_API.Refresh() end
            if HarfordUnitFrames and HarfordUnitFrames.Refresh then HarfordUnitFrames.Refresh() end
            if HarfordNamePlates and HarfordNamePlates.RefreshName then
                for profileName in pairs(changedProfiles or {}) do
                    HarfordNamePlates.RefreshName(profileName)
                end
            end
        end
    end)
end

-- El comando /harford debug run itemrules se registra en HarfordDebug.lua (convencion del
-- proyecto). Solo usa la funcion publica HarfordDnDItems.ResolveSlot.
