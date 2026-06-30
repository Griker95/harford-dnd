local ADDON_NAME = ...

HarfordCompendioDB = HarfordCompendioDB or {}
HarfordCompendioCharacterDB = HarfordCompendioCharacterDB or {}

local API = _G.HarfordCompendioAPI or {}
_G.HarfordCompendioAPI = API

API.ADDON_NAME = ADDON_NAME
API.VERSION = "0.1.0"

local CLASS_CASTING = {
    ["Druida"] = { mode = "prepared", ability = "Sabiduria" },
    ["Sacerdote"] = { mode = "prepared", ability = "Carisma" },
    ["Chaman"] = { mode = "known", ability = "Sabiduria" },
    ["Mago"] = { mode = "wizard_book", ability = "Inteligencia" },
    ["Paladin"] = { mode = "prepared", ability = "Carisma" },
    ["Caballero de la Muerte"] = { mode = "known", ability = "Carisma" },
    ["Brujo"] = { mode = "known", ability = "Inteligencia" },
    ["Picaro Sutileza"] = { mode = "known", ability = "Inteligencia" },
}

local function EnsureTables()
    HarfordCompendioDB.settings = HarfordCompendioDB.settings or {}
    HarfordCompendioCharacterDB.favorites = HarfordCompendioCharacterDB.favorites or {}
    HarfordCompendioCharacterDB.knownSpells = HarfordCompendioCharacterDB.knownSpells or {}
    HarfordCompendioCharacterDB.preparedSpells = HarfordCompendioCharacterDB.preparedSpells or {}
    HarfordCompendioCharacterDB.wizardBook = HarfordCompendioCharacterDB.wizardBook or {}
    HarfordCompendioCharacterDB.mySpells = HarfordCompendioCharacterDB.mySpells or {}
end

-- Normalizacion de acentos delegada en la fuente unica byte-segura (carga antes que el
-- compendio). Sin mapa propio: ver contrato en AGENTS.md (no duplicar mapas de acentos).
local function NormalizeText(text)
    text = tostring(text or ""):lower()
    if HarfordClassColors and HarfordClassColors.StripAccents then
        return HarfordClassColors.StripAccents(text)
    end
    return text
end

local function Contains(list, value)
    if not list or not value or value == "" then return false end
    local normalizedValue = NormalizeText(value)
    for _, item in ipairs(list) do
        if NormalizeText(item) == normalizedValue then return true end
    end
    return false
end

local function ResourceKey(suffix)
    if HarfordDnDResources and HarfordDnDResources.CurKey and suffix == "Cur" then
        return HarfordDnDResources.CurKey("mana")
    end
    if HarfordDnDResources and HarfordDnDResources.MaxKey and suffix == "Max" then
        return HarfordDnDResources.MaxKey("mana")
    end
    return "Res_mana_" .. suffix
end

local function ReadResourceNumber(key, default)
    if HarfordDnDStore and HarfordDnDStore.GetResourceCurrent and key == "mana" then
        return HarfordDnDStore.GetResourceCurrent("mana")
    end
    if HarfordDnDStore and HarfordDnDStore.GetResourceMax and key == "manaMax" then
        return HarfordDnDStore.GetResourceMax("mana")
    end
    if HarfordDnDContext and HarfordDnDContext.Get then
        local storeKey = key == "manaMax" and ResourceKey("Max") or ResourceKey("Cur")
        return tonumber(HarfordDnDContext.Get(storeKey, tostring(default or 0))) or (default or 0)
    end
    return default or 0
end

local function SpellName(spell)
    return spell and spell.name or "Conjuro"
end

-- Nombre del conjuro como enlace TRP3 clicable para los anuncios; cae al nombre plano si no hay TRP3.
local function SpellLink(spell)
    if API.GetSpellChatLink then
        local link = API.GetSpellChatLink(spell)
        if link and link ~= "" then return link end
    end
    return SpellName(spell)
end

local function TargetLabel()
    if not (UnitExists and UnitExists("target")) then return "" end
    if HarfordTRP3 and HarfordTRP3.GetUnitRPName then
        local rpName = HarfordTRP3.GetUnitRPName("target")
        if rpName and rpName ~= "" then return rpName end
    end
    return (UnitName and UnitName("target")) or ""
end

-- Nombre del target con su color (RP de TRP3 o color de clase), igual que los ataques normales.
local function ColoredTargetName()
    if not (UnitExists and UnitExists("target")) then return "" end
    local name = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("target"))
        or (HarfordClassColors and HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName("target"))
    if not name or name == "" then return "" end
    local hex = HarfordTRP3 and HarfordTRP3.GetUnitNameColor and HarfordTRP3.GetUnitNameColor("target")
    if not (type(hex) == "string" and #hex == 6 and hex:match("^%x+$")) then
        hex = nil
        if HarfordUnitFrames and HarfordUnitFrames.GetClassColor then
            local r, g, b = HarfordUnitFrames.GetClassColor("target")
            if r then
                hex = string.format("%02x%02x%02x",
                    math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
            end
        end
    end
    if hex then return "|cff" .. hex .. name .. "|r" end
    return name
end

local function BroadcastInfo(text)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info", label = text })
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[D&D]|r " .. tostring(text or ""))
    end
end

local function CanonicalAbility(value)
    value = NormalizeText(value):gsub("^%s+", ""):gsub("%s+$", "")
    local aliases = {
        fue = "Fuerza", fuerza = "Fuerza",
        des = "Destreza", destreza = "Destreza",
        con = "Constitucion", cons = "Constitucion", constitucion = "Constitucion",
        int = "Inteligencia", inteligencia = "Inteligencia",
        sab = "Sabiduria", sabiduria = "Sabiduria",
        car = "Carisma", carisma = "Carisma",
    }
    return aliases[value]
end

local function SpellAbilityKey()
    local value = HarfordDnDContext and HarfordDnDContext.Get
        and HarfordDnDContext.Get("AtributoConjuro", "Inteligencia")
        or "Inteligencia"
    return CanonicalAbility(value) or "Inteligencia"
end

local function SpellDC()
    local ability = SpellAbilityKey()
    local mod = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod(ability) or 0
    local pb = HarfordDnDCalc and HarfordDnDCalc.GetSpellPB and HarfordDnDCalc.GetSpellPB() or 0
    local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("spellDC")
        or 0
    return 8 + mod + pb + bonus
end

local function SpellAttackBonus()
    local ability = SpellAbilityKey()
    local mod = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod(ability) or 0
    local pb = HarfordDnDCalc and HarfordDnDCalc.GetSpellPB and HarfordDnDCalc.GetSpellPB() or 0
    local global = HarfordDnDCalc and HarfordDnDCalc.GetMiscBonus and HarfordDnDCalc.GetMiscBonus() or 0
    local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("spellAttack")
        or 0
    return mod + pb + bonus + global, mod, pb, bonus, global
end

local function CanonicalDamageType(value)
    value = tostring(value or "")
    if HarfordDamageMitigation and HarfordDamageMitigation.KeyFromTypeText then
        local key = HarfordDamageMitigation.KeyFromTypeText(value)
        if key then return key end
    end
    if HarfordDamageTypes and HarfordDamageTypes.FromWord then
        local key = HarfordDamageTypes.FromWord(NormalizeText(value):gsub("%s+", ""))
        if key then return key end
    end
    return nil
end

local function Tokenize(text)
    text = NormalizeText(text)
    text = text:gsub("[,;:%(%)%[%]]", " ")
    text = text:gsub("%s+", " ")
    local tokens = {}
    for token in text:gmatch("%S+") do
        tokens[#tokens + 1] = token
    end
    return tokens
end

local function ParseDamageComponents(text)
    local tokens = Tokenize(text)
    local out = {}
    local i = 1
    while i <= #tokens do
        local count, sides, bonus = tokens[i]:match("^(%d*)d(%d+)([+-]%d+)$")
        if not count then
            count, sides = tokens[i]:match("^(%d*)d(%d+)$")
            bonus = 0
        end
        if count and sides then
            count = count ~= "" and tonumber(count) or 1
            sides = tonumber(sides)
            bonus = tonumber(bonus) or 0
            local damageType = CanonicalDamageType(tokens[i + 1] or "")
            if not damageType and tokens[i + 1] and tokens[i + 2] then
                damageType = CanonicalDamageType(tokens[i + 1] .. " " .. tokens[i + 2])
            end
            if count and sides and damageType then
                out[#out + 1] = {
                    damageDice = tostring(count) .. "d" .. tostring(sides),
                    damageBonus = bonus,
                    damageType = damageType,
                }
                i = i + 1
            end
        end
        i = i + 1
    end
    return #out > 0 and out or nil
end

local function SpellText(spell)
    return table.concat({
        spell and spell.attack or "",
        spell and spell.savingThrow or "",
        spell and spell.damage or "",
        spell and spell.range or "",
        spell and spell.mechanics or "",
        spell and spell.description or "",
    }, " ")
end

local function ParseSaveAbility(spell)
    local direct = CanonicalAbility(spell and spell.savingThrow or "")
    if direct then return direct end
    local text = NormalizeText(SpellText(spell))
    local found = text:match("ts%s+de%s+([%a]+)")
        or text:match("salvacion%s+de%s+([%a]+)")
        or text:match("tirada%s+de%s+salvacion%s+de%s+([%a]+)")
    return CanonicalAbility(found)
end

local function ParseAreaMeta(spell)
    local rangeText = NormalizeText(spell and spell.range or "")
    local explicitText = NormalizeText((spell and spell.mechanics or "") .. " " .. (spell and spell.description or ""))
    local marker = explicitText:match("area%s*:%s*(.+)$")
    local text
    if marker then
        text = marker
    elseif rangeText:find("personal", 1, true)
        and (rangeText:find("radio", 1, true)
            or rangeText:find("cono", 1, true)
            or rangeText:find("linea", 1, true)
            or rangeText:find("esfera", 1, true)
            or rangeText:find("cilindro", 1, true)) then
        text = rangeText
    else
        return nil
    end
    local shape, sizeText
    local value = text:match("cono%s+de%s+([%d%.,]+%s*m)")
        or text:match("cono%s+([%d%.,]+%s*m)")
    if value then
        shape, sizeText = "cone", value
    end
    if not shape then
        value = text:match("radio%s+de%s+([%d%.,]+%s*m)")
            or text:match("esfera%s+de%s+([%d%.,]+%s*m)")
            or text:match("cilindro%s+de%s+([%d%.,]+%s*m)")
        if value then shape, sizeText = "sphere", value end
    end
    if not shape then
        value = text:match("linea%s+de%s+([%d%.,]+%s*m)")
            or text:match("linea%s+([%d%.,]+%s*m)")
        if value then shape, sizeText = "line", value end
    end
    if not shape then return nil end
    return { shape = shape, sizeText = sizeText or "" }
end

local function ParseSaveSuccess(spell)
    local text = NormalizeText(SpellText(spell))
    if text:find("mitad", 1, true) then return "half" end
    if text:find("niega", 1, true)
        or text:find("no recibe", 1, true)
        or text:find("no sufre", 1, true)
        or text:find("evita", 1, true) then
        return "none"
    end
    return nil
end

local function SaveFailsForNoDamage(spell)
    local text = NormalizeText(SpellText(spell))
    return text:find("fallo:", 1, true)
        or text:find("si falla", 1, true)
        or text:find("si fallan", 1, true)
        or text:find("debe superar", 1, true)
        or text:find("deben superar", 1, true)
end

local function HasSpellAttackText(spell)
    local attackText = NormalizeText(spell and spell.attack or "")
    if attackText:find("ataque de conjuro", 1, true)
        or attackText:find("ataque con arma", 1, true)
        or (attackText ~= "" and attackText:find("a distancia", 1, true)) then
        return true
    end
    local mechanics = NormalizeText(spell and spell.mechanics or "")
    return mechanics:find("^%s*impacto:") or mechanics:find("%simpacto:")
end

local function IsDirectSaveSpell(spell)
    local saveAbility = ParseSaveAbility(spell)
    if not saveAbility or HasSpellAttackText(spell) then return false end
    local text = NormalizeText((spell and spell.attack or "") .. " " .. (spell and spell.mechanics or ""))
    return text:find("contra salvacion", 1, true)
        or text:find("salvacion", 1, true)
        or text:find("ts de", 1, true)
end

local function IsSpellAttack(spell)
    local text = NormalizeText((spell and spell.attack or "") .. " " .. (spell and spell.mechanics or ""))
    if text:find("contra salvacion", 1, true) or text:find("salvacion", 1, true) then return false end
    return text:find("ataque de conjuro", 1, true)
        or text:find("ataque a distancia", 1, true)
        or text:find("a distancia", 1, true)
end

-- ¿El conjuro requiere objetivo? Solo los ataques de conjuro DIRECTOS (contra el target). Los de
-- area (incluida la salvacion-"Objetivo") se resuelven en el motor de area y no se gatean aqui.
function API.SpellNeedsTarget(spell)
    if API.BuildAreaDefinition and API.BuildAreaDefinition(spell) then return false end
    return IsSpellAttack(spell) and true or false
end

local function SpellAttackRange(spell)
    local text = NormalizeText((spell and spell.attack or "") .. " " .. (spell and spell.mechanics or ""))
    return text:find("cuerpo a cuerpo", 1, true) and "melee" or "ranged"
end

-- Condicion estructurada opcional del conjuro: spell.condition = "restrained" o
-- { id, duration, persist, turns }. id debe existir en HarfordDnDConditions.
local function SpellCondition(spell)
    local c = spell and spell.condition
    if type(c) == "string" then c = { id = c } end
    if type(c) ~= "table" or not c.id or c.id == "" then return nil end
    if HarfordDnDConditions and HarfordDnDConditions.GetDefinition
        and not HarfordDnDConditions.GetDefinition(c.id) then return nil end
    return c
end

function API.BuildAreaDefinition(spell)
    if not spell then return nil end
    local area = ParseAreaMeta(spell)
    local damageComponents = ParseDamageComponents(spell.damage or SpellText(spell))
    local condition = SpellCondition(spell)
    if not damageComponents and not condition then return nil end
    local saveAbility = ParseSaveAbility(spell)
    local directSave = IsDirectSaveSpell(spell)
    if spell.autohit == true and damageComponents then
        -- Auto-impacto (flag estructurado; ej. Proyectil Magico): daño sin tirada ni salvacion.
        -- No se puede detectar por texto sin falsos positivos, por eso es un campo explicito.
        area = area or { shape = "other", sizeText = "Objetivo" }
        area.resolution = "auto"
    elseif saveAbility and (area or directSave or condition) then
        local success = ParseSaveSuccess(spell) or (SaveFailsForNoDamage(spell) and "none")
            or (not damageComponents and "none") or nil  -- condicion pura: success no aplica
        if not success then return nil end
        area = area or { shape = "other", sizeText = "Objetivo" }
        area.resolution = "save"
        area.saveAbility = saveAbility
        area.dc = SpellDC()
        area.success = success
    elseif IsSpellAttack(spell) and (damageComponents or condition) then
        -- Ataque de conjuro de objetivo unico (con daño y/o condicion): se resuelve por el motor
        -- de area como "Objetivo" (auto-marca el target), aplicando daño/condicion a Player y NPC.
        area = area or { shape = "other", sizeText = "Objetivo" }
        area.resolution = "attack"
        area.attackBonus = SpellAttackBonus()
        area.attackRange = SpellAttackRange(spell)
    else
        return nil
    end
    area.damageComponents = damageComponents  -- nil = condicion pura (el motor lo acepta)
    if condition then
        area.conditionId = condition.id
        -- Por defecto una condicion de salvacion repite salvacion al final del turno del objetivo;
        -- sin salvacion se mantiene hasta que el DM la retire (manual).
        area.conditionDuration = condition.duration
            or (area.resolution == "save" and "save_at_turn_end") or "manual"
        area.conditionPersist = condition.persist and true or false
        if condition.turns then area.conditionTurns = condition.turns end
        if area.conditionDuration == "save_at_turn_end" then
            area.conditionSaveAbility = saveAbility
            area.conditionSaveDC = SpellDC()
        end
    end
    if spell.zone == true then
        -- Zona persistente (daño por turno): nunca objetivo unico (siempre ventana para re-marcar).
        area.zone = true
        if area.sizeText == "Objetivo" then area.sizeText = "Zona" end
    end
    return {
        name = SpellName(spell),
        title = SpellName(spell),
        area = area,
    }
end

local function ValidateSpellAttack()
    if not (HarfordDnDCalc and HarfordDnDRolls and HarfordDnDCombat) then
        return false, "Sistema de tiradas no disponible"
    end
    if HarfordDnDConditions and HarfordDnDConditions.CanPerform then
        local allowed, condition = HarfordDnDConditions.CanPerform("verbal_spell", { actorUnit = "player", targetUnit = "target" })
        if not allowed then
            return false, "No puedes lanzar el conjuro: " .. tostring(condition or "condicion activa") .. "."
        end
    end
    if not (UnitExists and UnitExists("target"))
        or (UnitIsUnit and UnitIsUnit("target", "player")) then
        return false, "Necesitas un objetivo valido"
    end
    return true
end

local function RollSpellAttack(spell)
    local valid, err = ValidateSpellAttack()
    if not valid then return false, err end
    local totalBonus, mod, pb, featureBonus, global = SpellAttackBonus()
    local chosen, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full("attack", {
        actorUnit = "player",
        targetUnit = "target",
        attackRange = SpellAttackRange(spell),
    })
    local total = chosen + totalBonus
    local bonusTxt = HarfordDnDCalc.BonusConcat(mod, pb, featureBonus, global)
    local _armorClass, _hit, armorText = HarfordDnDCombat.ResolveArmorClassOutcome(total, critTag, "target")
    if armorText and armorText ~= "" then bonusTxt = bonusTxt .. armorText end
    local target = TargetLabel()
    HarfordDnDRolls.Broadcast({
        type = "spell",
        targetUnit = "target",
        label = "Ataque Conjuro " .. SpellName(spell) .. (target ~= "" and (" " .. target) or ""),
        total = total,
        dice = HarfordDnDCalc.FormatD20Dice(chosen, ra, rb),
        modifiers = bonusTxt,
        critical = critTag,
        mode = modeTag,
    })
    if HarfordDnDStore and HarfordDnDStore.ConsumeRollMode then
        HarfordDnDStore.ConsumeRollMode()
    end
    return true
end

function API.Init()
    EnsureTables()
end

-- Coste de mana por nivel: fuente UNICA = HarfordDnDMana.COST (no duplicar la tabla aqui).
-- Cubre niveles 0..9; el truco (0) cuesta 0. Sin el modulo de mana, sin coste.
function API.GetManaCost(level)
    if HarfordDnDMana and HarfordDnDMana.GetSpellCost then
        return HarfordDnDMana.GetSpellCost(level)
    end
    return 0
end

function API.GetSpellCost(spellOrId, options)
    local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
    if not spell then return 0 end
    if options and options.ritual and spell.ritual == true then
        return 0
    end
    return API.GetManaCost(spell.level)
end

function API.GetManaCurrent()
    return ReadResourceNumber("mana", 0)
end

function API.GetManaMax()
    return ReadResourceNumber("manaMax", 0)
end

function API.GetClassCasting(className)
    return CLASS_CASTING[className]
end

function API.IsFavorite(spellId)
    EnsureTables()
    return HarfordCompendioCharacterDB.favorites[spellId] == true
end

function API.ToggleFavorite(spellId)
    EnsureTables()
    if not spellId then return false end
    HarfordCompendioCharacterDB.favorites[spellId] = not HarfordCompendioCharacterDB.favorites[spellId]
    return HarfordCompendioCharacterDB.favorites[spellId]
end


function API.IsMySpell(spellId)
    EnsureTables()
    return HarfordCompendioCharacterDB.mySpells[spellId] == true
end

function API.ToggleMySpell(spellId)
    EnsureTables()
    if not spellId then return false end
    HarfordCompendioCharacterDB.mySpells[spellId] = not HarfordCompendioCharacterDB.mySpells[spellId]
    return HarfordCompendioCharacterDB.mySpells[spellId]
end

function API.GetAllSpells()
    return _G.HarfordCompendioSpells or {}
end

-- Indice id->conjuro construido una vez (los datos son estaticos). Se reconstruye solo si
-- la tabla de conjuros cambia de referencia, para no escanear los ~383 en cada lookup.
local spellIndex, spellIndexSource
local function GetSpellIndex()
    local all = API.GetAllSpells()
    if spellIndex and spellIndexSource == all then return spellIndex end
    spellIndex = {}
    for _, spell in ipairs(all) do
        if spell.id and spellIndex[spell.id] == nil then spellIndex[spell.id] = spell end
    end
    spellIndexSource = all
    return spellIndex
end

function API.GetSpellById(spellId)
    return GetSpellIndex()[spellId]
end

function API.FilterSpells(filter)
    filter = filter or {}
    local query = NormalizeText(filter.query or "")
    local results = {}
    for _, spell in ipairs(API.GetAllSpells()) do
        local ok = true
        if filter.level ~= nil and spell.level ~= filter.level then ok = false end
        if filter.favoritesOnly and not API.IsFavorite(spell.id) then ok = false end
        if filter.mineOnly and not API.IsMySpell(spell.id) then ok = false end
        if filter.school and filter.school ~= "Todas" and NormalizeText(spell.school) ~= NormalizeText(filter.school) then ok = false end
        if filter.className and filter.className ~= "Todas" and not Contains(spell.classes, filter.className) then ok = false end
        if filter.category and filter.category ~= "Todas" and not Contains(spell.categories, filter.category) then ok = false end
        if filter.affinity and filter.affinity ~= "Todas" and NormalizeText(spell.affinity) ~= NormalizeText(filter.affinity) then ok = false end
        if filter.sourceGroup and filter.sourceGroup ~= "Todas" and NormalizeText(spell.sourceGroup) ~= NormalizeText(filter.sourceGroup) then ok = false end
        if query ~= "" then
            local haystack = NormalizeText((spell.name or "") .. " " .. (spell.school or "") .. " " .. (spell.affinity or "") .. " " .. table.concat(spell.categories or {}, " "))
            if not haystack:find(query, 1, true) then ok = false end
        end
        if ok then table.insert(results, spell) end
    end
    table.sort(results, function(a, b)
        if a.level == b.level then return (a.name or "") < (b.name or "") end
        return (a.level or 0) < (b.level or 0)
    end)
    return results
end

function API.GetKnownSpells()
    EnsureTables()
    return HarfordCompendioCharacterDB.knownSpells
end

function API.GetPreparedSpells()
    EnsureTables()
    return HarfordCompendioCharacterDB.preparedSpells
end

function API.IsPreparedSpell(spellId)
    EnsureTables()
    return HarfordCompendioCharacterDB.preparedSpells[spellId] == true
end

function API.TogglePreparedSpell(spellId)
    EnsureTables()
    if not spellId then return false end
    HarfordCompendioCharacterDB.preparedSpells[spellId] = not HarfordCompendioCharacterDB.preparedSpells[spellId]
    return HarfordCompendioCharacterDB.preparedSpells[spellId]
end
function API.GetWizardBook()
    EnsureTables()
    return HarfordCompendioCharacterDB.wizardBook
end

function API.CanCast(spellId)
    local spell = API.GetSpellById(spellId)
    if not spell then return false, "Conjuro no encontrado" end
    local cost = API.GetSpellCost(spell)
    if cost <= 0 then return true, "Disponible" end
    local current = API.GetManaCurrent()
    if current < cost then
        return false, "Mana insuficiente (" .. tostring(current) .. "/" .. tostring(cost) .. ")"
    end
    return true, "Disponible"
end

function API.SpendSpellMana(spellOrId, options)
    local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
    if not spell then return false, "Conjuro no encontrado" end
    local cost = API.GetSpellCost(spell, options)
    if cost <= 0 then return true, 0, API.GetManaCurrent(), API.GetManaMax() end
    local current = API.GetManaCurrent()
    if current < cost then
        return false, "Mana insuficiente (" .. tostring(current) .. "/" .. tostring(cost) .. ")"
    end
    local newCurrent
    if HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
        newCurrent = HarfordDnDStore.AdjustResourceCurrent("mana", -cost)
    elseif HarfordDnDContext and HarfordDnDContext.Set then
        newCurrent = math.max(0, current - cost)
        HarfordDnDContext.Set(ResourceKey("Cur"), tostring(newCurrent))
    else
        return false, "Sistema de recursos no disponible"
    end
    return true, cost, newCurrent or math.max(0, current - cost), API.GetManaMax()
end

function API.AnnounceCastAttempt(spellId)
    local spell = API.GetSpellById(spellId)
    if not spell then return false, "Conjuro no encontrado" end
    -- Anuncio limpio: solo lanzador (lo antepone el render) + link del conjuro + target si hay.
    local target = ColoredTargetName()
    local suffix = target ~= "" and (" " .. target) or ""
    BroadcastInfo(SpellLink(spell) .. suffix)
    return true
end

function API.ConfirmCast(spellId, options)
    local spell = API.GetSpellById(spellId)
    if not spell then return false, "Conjuro no encontrado" end
    local ok, costOrErr, current, maxValue = API.SpendSpellMana(spell, options)
    if not ok then return false, costOrErr end
    if options and options.silent then return true, costOrErr, current, maxValue end
    local cost = tonumber(costOrErr) or 0
    -- Anuncio limpio: solo lanzador (lo antepone el render) + link del conjuro + target si hay.
    local target = ColoredTargetName()
    local suffix = target ~= "" and (" " .. target) or ""
    BroadcastInfo(SpellLink(spell) .. suffix .. " |cff00ff00EXITO|r")
    return true, cost, current, maxValue
end

function API.ResolveCast(spellId, options)
    local spell = API.GetSpellById(spellId)
    if not spell then return false, "Conjuro no encontrado" end
    options = options or {}
    if options.ritual then
        return API.ConfirmCast(spellId, options)
    end

    local areaDefinition = API.BuildAreaDefinition and API.BuildAreaDefinition(spell)
    if areaDefinition and HarfordDnDArea and HarfordDnDArea.Open then
        -- Objetivo unico: auto-resuelve sin ventana (como un ataque normal). Area real: ventana
        -- para marcar varias victimas.
        local isZone = areaDefinition.area and areaDefinition.area.zone == true
        local isSingle = areaDefinition.area and areaDefinition.area.shape == "other"
            and areaDefinition.area.sizeText == "Objetivo"
        local opened, err = HarfordDnDArea.Open(areaDefinition, {
            sourceKind = "player",
            sourceName = HarfordDnDRolls and HarfordDnDRolls.GetDisplayName and HarfordDnDRolls.GetDisplayName()
                or (UnitName and UnitName("player")) or "Jugador",
            autoResolve = (isSingle and not isZone) and true or nil,
            zone = isZone and true or nil,
            onCommit = function()
                local ok, castErr = API.ConfirmCast(spellId, { silent = true })
                return ok, castErr
            end,
        })
        if not opened then return false, err or "No se pudo abrir el selector de area" end
        return true, 0, API.GetManaCurrent(), API.GetManaMax()
    end

    if IsSpellAttack(spell) then
        local valid, attackErr = ValidateSpellAttack()
        if not valid then return false, attackErr end
        local ok, castErr = API.ConfirmCast(spellId, { silent = true })
        if not ok then return false, castErr end
        return RollSpellAttack(spell)
    end

    return API.ConfirmCast(spellId, options)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, addonName)
    if addonName == ADDON_NAME then
        API.Init()
    end
end)










