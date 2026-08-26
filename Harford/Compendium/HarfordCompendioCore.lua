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
    -- Mejora sustituye la tabla del Chaman por la suya desde N3 y cuenta como MEDIO lanzador.
    ["Chaman Mejora"] = { mode = "known", ability = "Sabiduria" },
}

-- Progresion magica por clase, niveles 1-6 (Libro 1 - Warcraft 5ª). TOTALES acumulados:
--   cantrips[n] = trucos conocidos al nivel n.
--   spells[n]   = POOL FIJO que eliges: conjuros conocidos (known) o conjuros del libro (wizard).
--                 Ausente en lanzadores "prepared": conocen toda su lista, no eligen un pool fijo.
--   prepared    = formula de conjuros PREPARABLES (un CALCULO, no tabla), del texto de Lanzamiento
--                 de Conjuros: "full" = Mod + nivel; "half" = Mod + floor(nivel/2). El Mago tiene
--                 AMBOS: pool fijo del libro + preparacion diaria calculada desde ese libro.
-- El picker de la creacion usa el DELTA de cantrips/spells para saber cuantos elegir en cada subida;
-- la preparacion (prepared) es un total recalculable, no incremental.
local SPELL_PROGRESSION = {
    ["Mago"]                   = { cantrips = {3,3,3,4,4,4}, spells = {6,8,10,12,14,16}, prepared = "full" }, -- libro 6 + 2/nivel
    ["Druida"]                 = { cantrips = {2,2,2,2,2,2}, prepared = "full" },                              -- prepara toda la lista
    ["Sacerdote"]              = { cantrips = {3,3,3,4,4,4}, prepared = "full" },                              -- prepara toda la lista
    ["Paladin"]                = { cantrips = {0,0,0,0,0,0}, prepared = "half" },                              -- sin trucos; prepara ½ nivel, desde N2
    ["Chaman"]                 = { cantrips = {2,2,2,3,3,3}, spells = {4,5,6,7,8,9} },
    ["Caballero de la Muerte"] = { cantrips = {0,2,2,2,2,2}, spells = {0,2,3,3,4,4} },      -- lanza desde N2
    ["Picaro Sutileza"]        = { cantrips = {0,0,3,3,3,3}, spells = {0,0,3,4,4,4} },      -- subclase desde N3
    ["Brujo"]                  = { cantrips = {2,2,2,3,3,3}, spells = {2,3,4,5,6,7} },      -- Libro 1 confirmado
    ["Chaman Mejora"]          = { cantrips = {2,2,2,2,2,2}, spells = {4,5,5,5,5,6} },      -- subclase desde N3
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

-- Conjuros concedidos por una subclase. Se calculan desde el Libro en vivo y no
-- se copian a la lista persistida del personaje.
local function IsFeatureGrantedSpell(spellId)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures
        and HarfordDnDProgression.IsFeatureEnabled) then
        return false
    end
    local profileName = HarfordClassColors and HarfordClassColors.UnitFullName
        and HarfordClassColors.UnitFullName("player") or (UnitName and UnitName("player"))
    local wanted = tostring(spellId)
    local classLevels = HarfordDnDProgression.GetClassLevels and HarfordDnDProgression.GetClassLevels(profileName) or {}
    for _, item in ipairs(HarfordDnDProgression.GetUnlockedFeatures(profileName) or {}) do
        local feature = item.feature
        if feature and HarfordDnDProgression.IsFeatureEnabled(feature, profileName) then
            local ownerLevel = tonumber(item.level) or 0
            for _, entry in ipairs(classLevels) do
                if tostring(entry.classId or "") == tostring(item.classId or "")
                    and tostring(entry.subclassId or "") == tostring(item.subclassId or "") then
                    ownerLevel = tonumber(entry.level) or ownerLevel
                    break
                end
            end
            for _, grant in ipairs(feature.spellGrants or {}) do
                if ownerLevel >= (tonumber(grant.level) or 0) then
                    for _, id in ipairs(grant.ids or {}) do
                        if tostring(id) == wanted then return true end
                    end
                end
            end
            for _, id in ipairs(feature.cantripSpellIds or {}) do
                if tostring(id) == wanted then return true end
            end
        end
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
        HarfordChat.Print(text)
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
            local firstTypeIndex = i + 1
            -- El Compendio admite tanto "3d4+3 fuerza" como "3d4 + 3 puntos de dano por fuerza".
            -- El segundo formato se usa, entre otros, en Proyectil Magico.
            if (tokens[firstTypeIndex] == "+" or tokens[firstTypeIndex] == "-")
                and tonumber(tokens[firstTypeIndex + 1]) then
                local sign = tokens[firstTypeIndex] == "-" and -1 or 1
                bonus = bonus + sign * tonumber(tokens[firstTypeIndex + 1])
                firstTypeIndex = firstTypeIndex + 2
            end
            local damageType
            for typeIndex = firstTypeIndex, math.min(#tokens, firstTypeIndex + 5) do
                damageType = CanonicalDamageType(tokens[typeIndex] or "")
                if not damageType and tokens[typeIndex] and tokens[typeIndex + 1] then
                    damageType = CanonicalDamageType(tokens[typeIndex] .. " " .. tokens[typeIndex + 1])
                end
                if damageType then break end
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

-- Escalado seguro por nivel de espacio: solo se interpreta una formula explicita de dados.
-- Ejemplos admitidos: "+1d6 por cada nivel ... por encima del 1" y "+2d10 ...".
-- No intenta inferir objetivos, duracion ni otros cambios narrativos.
local function ApplyUpcastDamage(spell, components, castLevel)
    if not components or not castLevel then return components end
    local baseLevel = math.max(0, math.floor(tonumber(spell and spell.level) or 0))
    local extraLevels = math.max(0, math.floor(tonumber(castLevel) or baseLevel) - baseLevel)
    if extraLevels <= 0 then return components end
    local text = NormalizeText((spell and spell.damage or "") .. " " .. (spell and spell.mechanics or "")
        .. " " .. (spell and spell.description or ""))
    local addCount, sides = text:match("%+(%d*)d(%d+)%s+por%s+cada%s+nivel.-por%s+encima")
    if not sides then return components end
    addCount = addCount ~= "" and tonumber(addCount) or 1
    sides = tonumber(sides)
    if not addCount or not sides then return components end
    -- Cuando hay varios tipos de dano, la formula se aplica a cada componente que comparte ese dado.
    -- Es el caso comun "fuego y frio aumentan en 1d6". Si el dado no coincide, no lo inventamos.
    for _, component in ipairs(components) do
        -- La asignacion va SEPARADA de la guarda: `a and b and f(x)` se queda con el PRIMER
        -- retorno de f y descarta el resto, asi que `componentSides` salia siempre nil y esta
        -- comparacion nunca se cumplia (ningun conjuro escalaba al subirlo de nivel).
        local count, componentSides
        if HarfordDnDWeapons and HarfordDnDWeapons.ParseDice then
            count, componentSides = HarfordDnDWeapons.ParseDice(component.damageDice)
        end
        if count and componentSides == sides then
            component.damageDice = tostring(count + addCount * extraLevels) .. "d" .. tostring(componentSides)
        end
    end
    return components
end

-- ESCALADO DE TRUCOS (Manual del Jugador, "Trucos"): el dano de un truco aumenta en un dado al
-- alcanzar el nivel de PERSONAJE 5, 11 y 17. Es una regla general, no un dato por conjuro: por eso
-- se aplica aqui y no se espera a que cada entrada la escriba. De los 31 trucos con dano del
-- compendio, 7 no la declaran en su texto y hasta ahora se quedaban en 1 dado a cualquier nivel;
-- `ApplyUpcastDamage` tampoco los tocaba, porque un truco no gasta espacio y su `extraLevels` es 0.
local function CantripDamageTier(characterLevel)
    characterLevel = math.floor(tonumber(characterLevel) or 1)
    if characterLevel >= 17 then return 4 end
    if characterLevel >= 11 then return 3 end
    if characterLevel >= 5 then return 2 end
    return 1
end

-- Trucos que NO escalan multiplicando dados: los que suman proyectiles (Descarga Sobrenatural
-- pasa de un rayo a cuatro, cada uno de 1d10). Multiplicarles el dado los dispararia al doble.
local function CantripScalesByProjectiles(spell)
    local text = NormalizeText((spell and spell.mechanics or "") .. " " .. (spell and spell.description or ""))
    return text:find("numero de rayos", 1, true) ~= nil
        or text:find("numero de dardos", 1, true) ~= nil
        or text:find("numero de proyectiles", 1, true) ~= nil
end

local function ApplyCantripScaling(spell, components)
    if not components then return components end
    if math.floor(tonumber(spell and spell.level) or 0) ~= 0 then return components end
    if CantripScalesByProjectiles(spell) then return components end
    local level = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
        and HarfordDnDProgression.GetTotalLevel() or 1
    local tier = CantripDamageTier(level > 0 and level or 1)
    if tier <= 1 then return components end
    for _, component in ipairs(components) do
        local count, sides
        if HarfordDnDWeapons and HarfordDnDWeapons.ParseDice then
            count, sides = HarfordDnDWeapons.ParseDice(component.damageDice)
        end
        if count and sides then
            component.damageDice = tostring(count * tier) .. "d" .. tostring(sides)
        end
    end
    return components
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

local AREA_SIZE_UNITS = { "metros", "metro", "m", "pies", "pie", "ft" }

local function CleanAreaSize(value)
    value = tostring(value or ""):gsub("%s+", " ")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value ~= "" and value or nil
end

local function MatchSizedPhrase(text, word)
    text = tostring(text or "")
    for _, unit in ipairs(AREA_SIZE_UNITS) do
        local value = text:match(word .. "%s+de%s+([%d%.,]+%s*" .. unit .. ")")
            or text:match(word .. "%s+([%d%.,]+%s*" .. unit .. ")")
        value = CleanAreaSize(value)
        if value then return value end
    end
    local value = text:match(word .. "%s+de%s+([%d%.,]+)")
        or text:match(word .. "%s+([%d%.,]+)")
    return CleanAreaSize(value)
end

local function MatchRadiusSize(text)
    for _, word in ipairs({ "radio", "esfera", "cilindro", "area", "zona" }) do
        local value = MatchSizedPhrase(text, word)
        if value then return value end
    end
    for _, unit in ipairs(AREA_SIZE_UNITS) do
        local value = text:match("([%d%.,]+%s*" .. unit .. ")%s+de%s+radio")
        value = CleanAreaSize(value)
        if value then return value end
    end
    return nil
end

local function MatchLineSize(text)
    for _, unit in ipairs(AREA_SIZE_UNITS) do
        local a, b = text:match("linea%s+de%s+([%d%.,]+%s*" .. unit .. ")%s+por%s+([%d%.,]+%s*" .. unit .. ")")
        if not a then
            a, b = text:match("linea%s+de%s+([%d%.,]+%s*" .. unit .. ")%s+de%s+largo%s+y%s+([%d%.,]+%s*" .. unit .. ")%s+de%s+ancho")
        end
        a, b = CleanAreaSize(a), CleanAreaSize(b)
        if a and b then return a .. " x " .. b end
    end
    return MatchSizedPhrase(text, "linea")
end

local function MatchRectangleSize(text)
    for _, unit in ipairs(AREA_SIZE_UNITS) do
        local a, b = text:match("rectangulo%s+de%s+([%d%.,]+%s*" .. unit .. ")%s*x%s*([%d%.,]+%s*" .. unit .. ")")
        if not a then
            a, b = text:match("rectangulo%s+([%d%.,]+%s*" .. unit .. ")%s*x%s*([%d%.,]+%s*" .. unit .. ")")
        end
        a, b = CleanAreaSize(a), CleanAreaSize(b)
        if a and b then return a .. " x " .. b end
    end
    return nil
end

local function HasAreaShapeText(text)
    return text:find("cono", 1, true)
        or text:find("radio", 1, true)
        or text:find("linea", 1, true)
        or text:find("esfera", 1, true)
        or text:find("cilindro", 1, true)
        or text:find("cubo", 1, true)
        or text:find("cuadrado", 1, true)
        or text:find("rectangulo", 1, true)
end

local function TextLooksLikeAreaEffect(text)
    text = tostring(text or "")
    if text:find("area%s*:", 1) then return true end
    if text:find("cada%s+criatura", 1) or text:find("toda%s+criatura", 1) then return true end
    if text:find("criaturas%s+en", 1) or text:find("criaturas%s+dentro", 1) then return true end
    if text:find("criatura%s+en%s+el%s+area", 1) or text:find("criatura%s+dentro%s+del%s+area", 1) then return true end
    if text:find("las%s+criaturas%s+afectadas", 1) or text:find("objetivos%s+afectados", 1) then return true end
    if text:find("salvacion", 1, true) or text:find("ts%s+de%s+", 1) then return true end
    if text:find("entra%s+en%s+el%s+area", 1) or text:find("entran%s+en%s+el%s+area", 1) then return true end
    if text:find("empieza%s+alli", 1) or text:find("comienza%s+su%s+turno", 1) then return true end
    return false
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
            or rangeText:find("cilindro", 1, true)
            or rangeText:find("cubo", 1, true)
            or rangeText:find("cuadrado", 1, true)
            or rangeText:find("rectangulo", 1, true)) then
        text = rangeText
    elseif HasAreaShapeText(explicitText) and TextLooksLikeAreaEffect(explicitText) then
        text = explicitText
    else
        return nil
    end
    local shape, sizeText
    local value = MatchSizedPhrase(text, "cono")
    if value then
        shape, sizeText = "cone", value
    elseif text:find("cono", 1, true) then
        shape, sizeText = "cone", ""
    end
    if not shape then
        value = MatchRadiusSize(text)
        if value then shape, sizeText = "sphere", value end
    end
    if not shape then
        value = MatchLineSize(text)
        if value then
            shape, sizeText = "line", value
        elseif text:find("linea", 1, true) then
            shape, sizeText = "line", ""
        end
    end
    if not shape then
        value = MatchSizedPhrase(text, "cubo")
            or MatchSizedPhrase(text, "cuadrado")
        if value then shape, sizeText = "square", value end
    end
    if not shape then
        value = MatchRectangleSize(text)
        if value then shape, sizeText = "rectangle", value end
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
    -- El campo `attack` es declarativo y tiene prioridad: algunos ataques (Rayo de
    -- Enfermedad) describen una salvacion POSTERIOR en mechanics, sin dejar de ser ataques.
    local attackText = NormalizeText(spell and spell.attack or "")
    if attackText:find("ataque de conjuro", 1, true)
        or attackText:find("ataque a distancia", 1, true) then
        return true
    end
    if attackText:find("contra salvacion", 1, true) or attackText:find("salvacion", 1, true) then
        return false
    end
    local mechanics = NormalizeText(spell and spell.mechanics or "")
    if mechanics:find("contra salvacion", 1, true) then return false end
    return mechanics:find("ataque de conjuro", 1, true)
        or mechanics:find("ataque a distancia", 1, true)
end

local NUMBER_WORDS = { un = 1, una = 1, dos = 2, tres = 3, cuatro = 4, cinco = 5, seis = 6 }

-- Cuenta impactos homogeneos de un ataque de conjuro. Cada aplicacion conserva su propio
-- d20 y sus propios dados: pueden repartirse entre objetivos o concentrarse en uno.
local function RepeatedAttackCount(spell)
    if not IsSpellAttack(spell) then return nil end
    local text = NormalizeText((spell and spell.damage or "") .. " " .. (spell and spell.mechanics or "")
        .. " " .. (spell and spell.description or ""))
    if tostring(spell and spell.id or "") == "descarga_sobrenatural" then
        local level = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
            and HarfordDnDProgression.GetTotalLevel() or 1
        if level >= 17 then return 4 elseif level >= 11 then return 3 elseif level >= 5 then return 2 end
        return 1
    end
    local raw = text:match("(%d+)%s+rayos") or text:match("(%d+)%s+fragmentos")
        or text:match("(%d+)%s+proyectiles")
    if raw then return math.max(1, math.min(40, tonumber(raw) or 1)) end
    local word = text:match("([%a]+)%s+rayos") or text:match("([%a]+)%s+fragmentos")
        or text:match("([%a]+)%s+proyectiles")
    return word and NUMBER_WORDS[word] or nil
end

-- Los multiimpactos con componentes o salvaciones heterogeneas siguen guiados. El caso
-- homogeneo (rayos/proyectiles/fragmentos) ya lo resuelve RepeatedAttackCount.
local function NeedsRepeatedAttackResolution(spell)
    local text = NormalizeText((spell and spell.damage or "") .. " " .. (spell and spell.mechanics or ""))
    if RepeatedAttackCount(spell) then return false end
    return text:find("%d+%s+fragmentos")
        or text:find("%d+%s+proyectiles")
        or text:find("%d+%s+orbes")
        or text:find("%d+%s+llamas")
        or text:find("%d+%s+meteoros")
        or text:find("por cada%s+rayo")
        or text:find("por cada%s+proyectil")
        or text:find("por cada%s+fragmento")
        or text:find("tres%s+rayos")
        or text:find("dos%s+rayos")
end

-- Algunos conjuros usan un impacto inicial y una segunda resolucion distinta (explosion,
-- salvacion o dano recurrente). No se mezclan ambas fases en el mismo ataque: hasta que exista
-- su secuencia propia permanecen guiados para no aplicar dano que no corresponde.
local function NeedsStagedResolution(spell)
    local text = NormalizeText((spell and spell.damage or "") .. " " .. (spell and spell.mechanics or ""))
    if text:find("impacte o falle", 1, true) and text:find("explota", 1, true) then return true end
    if text:find("luego el objetivo", 1, true) and text:find("salvacion", 1, true) then return true end
    if text:find("por turno", 1, true) or text:find("turnos posteriores", 1, true) then return true end
    if text:find("al aparecer", 1, true) and text:find("accion adicional", 1, true) then return true end
    if text:find("si lleva armadura de metal", 1, true) or text:find("puedes recibir", 1, true) then return true end
    if text:find("contra aberracion", 1, true) or text:find("contra engendro", 1, true) then return true end
    if text:find("dano variable", 1, true) or text:find("dano de tipo variable", 1, true) then return true end
    return false
end

-- El modificador por caracteristica de lanzamiento se escribe de varias formas en las fuentes
-- ("modificador de conjuro", "por aptitud magica", "de lanzamiento de conjuros"...). Reconocer
-- solo una dejaba curaciones como Cadena de Curacion sanando los dados SIN el modificador.
local CASTING_MODIFIER_PHRASES = {
    "modificador por caracteristica para lanzar conjuros",
    "modificador de caracteristica para lanzar conjuros",
    "modificador de lanzamiento de conjuros",
    "modificador por aptitud magica",
    "modificador de aptitud magica",
    "modificador de conjuro",
}

local function MentionsCastingModifier(text)
    text = NormalizeText(text)
    for _, phrase in ipairs(CASTING_MODIFIER_PHRASES) do
        if text:find(phrase, 1, true) then return true end
    end
    return false
end

local function HealingDefinition(spell, options)
    local categories = spell and spell.categories or {}
    local isHealing = false
    for _, category in ipairs(categories) do
        if NormalizeText(category) == "curacion" then isHealing = true; break end
    end
    if not isHealing then return nil end
    local text = NormalizeText(SpellText(spell))
    if not text:find("recuper", 1, true) then return nil end
    local count, sides = text:match("(%d*)d(%d+)")
    if not sides then return nil end
    count = tonumber(count) or 1
    sides = tonumber(sides)
    if count < 1 or sides < 2 then return nil end
    local targetCount = tonumber(text:match("hasta%s+(%d+)%s+criaturas"))
    if not targetCount then
        local word = text:match("hasta%s+([%a]+)%s+criaturas")
        targetCount = word and NUMBER_WORDS[word] or 1
    end
    targetCount = math.max(1, math.min(40, targetCount or 1))
    local bonus = 0
    if MentionsCastingModifier(text) then
        local ability = SpellAbilityKey()
        bonus = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod(ability) or 0
    end
    local components = ApplyUpcastDamage(spell, {
        { damageDice = tostring(count) .. "d" .. tostring(sides), damageBonus = bonus },
    }, API.GetCastLevel and API.GetCastLevel(spell, options) or spell.level)
    return {
        shape = "other",
        sizeText = targetCount > 1 and ("Hasta " .. tostring(targetCount) .. " objetivos") or "Objetivo",
        resolution = "heal",
        healingComponents = components,
        applicationCount = targetCount,
        rollPerTarget = targetCount > 1,
        -- Nivel al que se lanza: Guia Ancestral solo repite dados de conjuros de nivel 1 o superior.
        castLevel = API.GetCastLevel and API.GetCastLevel(spell, options) or spell.level,
    }
end

-- ¿El conjuro requiere objetivo? Solo los ataques de conjuro DIRECTOS (contra el target). Los de
-- area (incluida la salvacion-"Objetivo") se resuelven en el motor de area y no se gatean aqui.
function API.SpellNeedsTarget(spell)
    -- `BuildAreaDefinition` CONSUME la carga arcana pendiente, asi que no puede usarse como
    -- predicado: abrir la ficha de un conjuro en el compendio bastaba para perder el bono.
    if API.BuildAreaDefinition and API.BuildAreaDefinition(spell, { soloConsultar = true }) then
        return false
    end
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

function API.BuildAreaDefinition(spell, options)
    if not spell then return nil end
    if NeedsRepeatedAttackResolution(spell) or NeedsStagedResolution(spell) then return nil end
    local healing = HealingDefinition(spell, options)
    if healing then
        return { name = SpellName(spell), title = SpellName(spell), area = healing }
    end
    local area = ParseAreaMeta(spell)
    local damageComponents = ParseDamageComponents(spell.damage or SpellText(spell))
    damageComponents = ApplyUpcastDamage(spell, damageComponents, API.GetCastLevel(spell, options))
    damageComponents = ApplyCantripScaling(spell, damageComponents)
    local condition = SpellCondition(spell)
    if not damageComponents and not condition then return nil end
    -- Carga arcana gastada en "+X al ataque y dano de tu proximo conjuro": se consume UNA vez por
    -- lanzamiento y se reparte al ataque y a cada componente de dano.
    -- Solo se cobra si hay DONDE aplicarla. Antes se tomaba siempre y un conjuro que solo pone
    -- una condicion se la comia sin que el bono llegara a ninguna tirada.
    -- Consultar NO gasta: `SpellNeedsTarget` llama aqui como predicado y sin esto abrir la ficha
    -- de cualquier conjuro con dano se comia la carga.
    -- Se MIRA sin gastar; el cobro real se hace al final, cuando ya se sabe que hay definicion
    -- que devolver. Cobrar aqui perdia la carga en las dos ramas que salen con nil.
    local soloMirando = options and options.soloConsultar == true
    local cargaArcana = 0
    if not soloMirando and damageComponents and HarfordDnDStore
        and HarfordDnDStore.PeekArcaneSpellBonus then
        cargaArcana = HarfordDnDStore.PeekArcaneSpellBonus() or 0
    end
    if cargaArcana > 0 and damageComponents then
        for _, comp in ipairs(damageComponents) do
            comp.damageBonus = (tonumber(comp.damageBonus) or 0) + cargaArcana
        end
    end

    local saveAbility = ParseSaveAbility(spell)
    local directSave = IsDirectSaveSpell(spell)
    if spell.autohit == true and damageComponents then
        -- Auto-impacto (flag estructurado; ej. Proyectil Magico): daño sin tirada ni salvacion.
        -- No se puede detectar por texto sin falsos positivos, por eso es un campo explicito.
        area = area or { shape = "other", sizeText = "Objetivo" }
        area.resolution = "auto"
    elseif saveAbility and not IsSpellAttack(spell) and (area or directSave or condition) then
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
        area.attackBonus = SpellAttackBonus() + cargaArcana
        area.attackRange = SpellAttackRange(spell)
        local applications = RepeatedAttackCount(spell)
        if applications and applications > 1 then
            area.shape = "other"
            area.sizeText = tostring(applications) .. " impactos"
            area.applicationCount = applications
            area.repeatTargets = true
            area.rollPerTarget = true
        end
    else
        return nil
    end
    -- Aqui ya no hay salida con nil: se cobra la carga que se conto arriba. Cobrarla antes la
    -- perdia en las dos ramas que devuelven nil sin llegar a ninguna tirada.
    if cargaArcana > 0 and HarfordDnDStore and HarfordDnDStore.TakeArcaneSpellBonus then
        HarfordDnDStore.TakeArcaneSpellBonus()
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
        -- Algunos ataques impactan primero y solo despues permiten una salvacion contra la
        -- condicion (Rayo de Enfermedad). Esta tirada NO transforma el dano en una salvacion.
        if area.resolution == "attack" and saveAbility then
            area.conditionApplySaveAbility = saveAbility
            area.conditionApplySaveDC = SpellDC()
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

local function RollSpellAttack(spell, skipValidation)
    if not skipValidation then
        local valid, err = ValidateSpellAttack()
        if not valid then return false, err end
    end
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

-- Nivel efectivo del lanzamiento. Un conjuro siempre puede usar un espacio superior,
-- pero nunca inferior a su nivel ni superior al maximo que permite el lanzador.
function API.GetCastLevel(spellOrId, options)
    local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
    if not spell then return 0 end
    local baseLevel = math.max(0, math.floor(tonumber(spell.level) or 0))
    if baseLevel <= 0 then return 0 end
    local requested = options and tonumber(options.castLevel) or baseLevel
    requested = math.floor(requested or baseLevel)
    return math.max(baseLevel, requested)
end

function API.GetMaxCastLevel(spellOrId)
    local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
    if not spell then return 0 end
    local baseLevel = math.max(0, math.floor(tonumber(spell.level) or 0))
    if baseLevel <= 0 then return 0 end
    local available = HarfordDnDMana and HarfordDnDMana.GetMaxSpellLevel
        and HarfordDnDMana.GetMaxSpellLevel() or baseLevel
    return math.max(baseLevel, math.min(9, math.floor(tonumber(available) or baseLevel)))
end

function API.GetSpellCost(spellOrId, options)
    local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
    if not spell then return 0 end
    if options and options.ritual and spell.ritual == true then
        return 0
    end
    return API.GetManaCost(API.GetCastLevel(spell, options))
end

function API.GetSpellCostMode()
    return (HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("spell_cost_mode") == "slots")
        and "slots" or "mana"
end

function API.GetManaCurrent()
    return ReadResourceNumber("mana", 0)
end

function API.GetManaMax()
    return ReadResourceNumber("manaMax", 0)
end

local function IsWarlockLifeTapAvailable(spell, options)
    if not (spell and (tonumber(spell.level) or 0) > 0) then return false end
    if API.GetSpellCostMode() ~= "mana" or API.GetManaCurrent() > 0 then return false end
    if not (HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures
        and HarfordDnDProgression.IsFeatureEnabled) then return false end
    local profileName = HarfordClassColors and HarfordClassColors.UnitFullName
        and HarfordClassColors.UnitFullName("player") or (UnitName and UnitName("player"))
    local hasTouch = false
    for _, item in ipairs(HarfordDnDProgression.GetUnlockedFeatures(profileName) or {}) do
        if item.feature and item.feature.id == "bru_toque_vida"
            and HarfordDnDProgression.IsFeatureEnabled(item.feature, profileName) then
            hasTouch = true
            break
        end
    end
    if not hasTouch then return false end
    local level = HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(profileName) or 0
    local hpCost = math.max(1, tonumber(level) or 0) + API.GetCastLevel(spell, options)
    local health = HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
        and HarfordDnDStore.GetResourceCurrent("health") or 0
    return health > hpCost, hpCost
end

function API.GetClassCasting(className)
    return CLASS_CASTING[className]
end

function API.GetSpellProgression(className)
    return SPELL_PROGRESSION[className]
end

-- Cuantos trucos/conjuros NUEVOS se eligen al alcanzar `level` en esta clase (delta con el nivel
-- anterior). Devuelve (cantrips, spells); spells = nil si la clase prepara toda su lista.
function API.GetSpellPickCounts(className, level)
    local prog = SPELL_PROGRESSION[className]
    if not prog then return 0, nil end
    level = math.max(1, math.min(6, tonumber(level) or 1))
    local function delta(tbl)
        if not tbl then return nil end
        local cur = tonumber(tbl[level]) or 0
        local prev = level > 1 and (tonumber(tbl[level - 1]) or 0) or 0
        return math.max(0, cur - prev)
    end
    return delta(prog.cantrips) or 0, delta(prog.spells)
end

-- Numero de conjuros PREPARABLES (calculo del texto de Lanzamiento de Conjuros): "full" = Mod +
-- nivel; "half" = Mod + floor(nivel/2). Minimo 1. Devuelve nil si la clase no prepara (solo known).
function API.GetPreparedCount(className, abilityMod, level)
    local prog = SPELL_PROGRESSION[className]
    if not (prog and prog.prepared) then return nil end
    abilityMod = tonumber(abilityMod) or 0
    level = math.max(1, tonumber(level) or 1)
    local base = prog.prepared == "half" and math.floor(level / 2) or level
    return math.max(1, abilityMod + base)
end

-- Nivel de conjuro MAXIMO lanzable por una clase a un nivel dado (para filtrar el picker). Segun el
-- tipo de lanzador: completo (Mago/Druida/Sacerdote/Chaman/Brujo), medio (Paladin/CdM, nivel efectivo
-- = ceil/2) o tercio (Picaro Sutileza, nivel efectivo = ceil/3). Devuelve 0 si aun no lanza.
local HALF_CASTERS = { ["Paladin"] = true, ["Caballero de la Muerte"] = true, ["Chaman Mejora"] = true }
local THIRD_CASTERS = { ["Picaro Sutileza"] = true }
function API.GetMaxSpellLevel(className, level)
    if not SPELL_PROGRESSION[className] then return 0 end
    level = tonumber(level) or 1
    local eff = level
    if HALF_CASTERS[className] then eff = math.ceil(level / 2)
    elseif THIRD_CASTERS[className] then eff = math.ceil(level / 3) end
    -- Los medios/tercios no lanzan hasta N2/N3 respectivamente.
    if HALF_CASTERS[className] and level < 2 then return 0 end
    if THIRD_CASTERS[className] and level < 3 then return 0 end
    if eff < 1 then return 0 end
    return math.min(9, math.ceil(eff / 2))
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
    return HarfordCompendioCharacterDB.mySpells[spellId] == true or IsFeatureGrantedSpell(spellId)
end

function API.ToggleMySpell(spellId)
    EnsureTables()
    if not spellId then return false end
    HarfordCompendioCharacterDB.mySpells[spellId] = not HarfordCompendioCharacterDB.mySpells[spellId]
    return HarfordCompendioCharacterDB.mySpells[spellId]
end

-- CONCENTRACION DECLARADA CONTRA DURACION: muchas entradas traen la concentracion escrita en
-- `duration` ("Concentracion, hasta 1 minuto") pero con `concentration = false`. La duracion es
-- el texto copiado del manual, asi que manda: si lo dice ahi, el conjuro exige concentracion
-- aunque el campo booleano no lo declare. Se resuelve aqui y no en los datos porque
-- HarfordCompendioData lo mantiene el pipeline del codice y se regenera.
function API.RequiresConcentration(spell)
    if type(spell) ~= "table" then return false end
    if spell.concentration == true then return true end
    -- "concentraci" y no "concentracion": asi acierta con o sin tilde aunque NormalizeText
    -- caiga al `lower` simple porque HarfordClassColors no estuviera cargado.
    return NormalizeText(spell.duration):find("concentraci", 1, true) ~= nil
end

-- Los conjuros viven en el addon HarfordCompendioData, marcado LoadOnDemand: son 609 KB de
-- constructores de tabla que WoW parseaba en cada login aunque nadie abriera el compendio.
-- Esta funcion es la UNICA puerta a esos datos, asi que la compuerta va aqui y ningun llamador
-- cambia. `GetSpellIndex` ya se reconstruye cuando la tabla cambia de referencia, asi que el
-- indice se rehace solo en cuanto los datos entran.
local conjurosPedidos, conjurosListos = false, false
function API.EnsureSpellData()
    if conjurosListos then return true end
    if _G.HarfordCompendioSpells then
        conjurosListos = true
        return true
    end
    if conjurosPedidos then return false end
    conjurosPedidos = true
    local cargar = (C_AddOns and C_AddOns.LoadAddOn) or _G.LoadAddOn
    if not cargar then return false end
    cargar("HarfordCompendioData")
    conjurosListos = _G.HarfordCompendioSpells ~= nil
    if not conjurosListos and HarfordChat and HarfordChat.Print then
        HarfordChat.Print("No se pudo cargar |cffffcc00HarfordCompendioData|r: "
            .. "el compendio se quedara sin conjuros. Comprueba que la carpeta esta instalada y activada.")
    end
    return conjurosListos
end

function API.GetAllSpells()
    if not conjurosListos then API.EnsureSpellData() end
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
    return HarfordCompendioCharacterDB.preparedSpells[spellId] == true or IsFeatureGrantedSpell(spellId)
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

function API.CanCast(spellId, options)
    local spell = API.GetSpellById(spellId)
    if not spell then return false, "Conjuro no encontrado" end
    if (tonumber(spell.level) or 0) <= 0 then return true, "Disponible" end
    local castLevel = API.GetCastLevel(spell, options)
    local maxLevel = API.GetMaxCastLevel(spell)
    if castLevel > maxLevel then
        return false, "No puedes usar un espacio de nivel " .. tostring(castLevel)
    end
    if API.GetSpellCostMode() == "slots" then
        if not (HarfordDnDMana and HarfordDnDMana.CanSpendSpellSlot) then
            return false, "Sistema de espacios no disponible"
        end
        local ok, currentOrErr, maximum = HarfordDnDMana.CanSpendSpellSlot(castLevel)
        if not ok then return false, currentOrErr end
        return true, "Espacios: " .. tostring(currentOrErr) .. "/" .. tostring(maximum)
    end
    local cost = API.GetSpellCost(spell, options)
    if cost <= 0 then return true, "Disponible" end
    local current = API.GetManaCurrent()
    if current < cost then
        local canTap, hpCost = IsWarlockLifeTapAvailable(spell, options)
        if canTap then return true, "Toque de Vida: -" .. tostring(hpCost) .. " Salud" end
        return false, "Mana insuficiente (" .. tostring(current) .. "/" .. tostring(cost) .. ")"
    end
    return true, "Disponible"
end

function API.SpendSpellMana(spellOrId, options)
    local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
    if not spell then return false, "Conjuro no encontrado" end
    -- `free`: el conjuro ya se ha pagado con OTRO recurso. Lo usan los rasgos que conceden "los
    -- efectos del conjuro X" -- los brebajes del Monje cuestan chi -- y que por tanto no gastan
    -- mana ni espacios; un Monje ademas no tiene ninguno de los dos. Todo lo demas del lanzamiento
    -- sigue igual, y en particular la concentracion, que si le aplica.
    if options and options.free then return true, 0, API.GetManaCurrent(), API.GetManaMax() end
    if not (options and options.ritual and spell.ritual == true) and API.GetSpellCostMode() == "slots" then
        if (tonumber(spell.level) or 0) <= 0 then return true, 0, 0, 0 end
        if not (HarfordDnDMana and HarfordDnDMana.SpendSpellSlot) then
            return false, "Sistema de espacios no disponible"
        end
        local castLevel = API.GetCastLevel(spell, options)
        local maxLevel = API.GetMaxCastLevel(spell)
        if castLevel > maxLevel then
            return false, "No puedes usar un espacio de nivel " .. tostring(castLevel)
        end
        local ok, currentOrErr, maximum = HarfordDnDMana.SpendSpellSlot(castLevel)
        if not ok then return false, currentOrErr end
        return true, 1, currentOrErr, maximum
    end
    local cost = API.GetSpellCost(spell, options)
    if cost <= 0 then return true, 0, API.GetManaCurrent(), API.GetManaMax() end
    local current = API.GetManaCurrent()
    if current < cost then
        local canTap, hpCost = IsWarlockLifeTapAvailable(spell, options)
        if canTap and HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
            local health = HarfordDnDStore.AdjustResourceCurrent("health", -hpCost)
            return true, 0, current, API.GetManaMax(), { lifeTap = true, health = health, healthCost = hpCost }
        end
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
    -- CONCENTRACION: el conjuro declara si la exige. Empezar sustituye a la anterior, porque el
    -- manual no permite concentrarse en dos a la vez; el modulo se encarga de anunciarlo.
    if API.RequiresConcentration(spell) and HarfordDnDConcentration and HarfordDnDConcentration.Begin then
        HarfordDnDConcentration.Begin(spell.name or tostring(spellId), spellId)
    end
    if options and options.silent then return true, costOrErr, current, maxValue end
    local cost = tonumber(costOrErr) or 0
    -- Anuncio limpio: solo lanzador (lo antepone el render) + link del conjuro + target si hay.
    local target = ColoredTargetName()
    local suffix = target ~= "" and (" " .. target) or ""
    BroadcastInfo(SpellLink(spell) .. suffix .. " |cff00ff00EXITO|r")
    return true, cost, current, maxValue
end

-- "Cargas Arcanas" (Mago del Arcano) se gana al LANZAR un conjuro de mago de nivel 1 o superior.
-- Se engancha aqui, en el punto UNICO donde se paga, y como envoltorio para no tocar los multiples
-- puntos de retorno de SpendSpellMana. El rasgo decide si aplica: si el mago no lo tiene, no pasa nada.
do
    local original = API.SpendSpellMana
    API.SpendSpellMana = function(spellOrId, options)
        local ok, a, b, c, d = original(spellOrId, options)
        if ok and HarfordDnDStore and HarfordDnDStore.GainArcaneCharge then
            local spell = type(spellOrId) == "table" and spellOrId or API.GetSpellById(spellOrId)
            local esMago = false
            for _, clase in ipairs((spell and spell.classes) or {}) do
                if tostring(clase) == "Mago" then esMago = true break end
            end
            if esMago then
                HarfordDnDStore.GainArcaneCharge(API.GetCastLevel(spell, options))
            end
        end
        return ok, a, b, c, d
    end
end

-- El ultimo conjuro de objetivo unico que se resolvio, si sigue siendo reciente. Caduca a los dos
-- minutos: redirigir un conjuro lanzado hace media hora no es lo que dice ningun rasgo.
local VENTANA_ULTIMO_CONJURO = 120

function API.GetLastSingleTargetCast()
    local u = API._ultimoConjuroUnico
    if type(u) ~= "table" then return nil, "No has lanzado ningun conjuro de objetivo unico" end
    local ahora = (time and time()) or 0
    if ahora > 0 and u.cuando > 0 and (ahora - u.cuando) > VENTANA_ULTIMO_CONJURO then
        return nil, "Ese conjuro es de hace demasiado"
    end
    return u
end

-- Vuelve a resolver ese conjuro contra otro objetivo SIN volver a pagarlo: lo que se paga es el
-- recurso del rasgo que lo permite. `marca` evita usar dos veces el mismo rasgo sobre el mismo
-- lanzamiento.
function API.RecastLastSingleTarget(marca, etiqueta)
    local u, err = API.GetLastSingleTargetCast()
    if not u then return false, err end
    marca = tostring(marca or "recast")
    u.usado = u.usado or {}
    if u.usado[marca] then return false, "Ya lo usaste sobre ese conjuro" end
    if not (HarfordDnDArea and HarfordDnDArea.Open) then
        return false, "El motor de areas no esta disponible"
    end
    local def = {}
    for k, v in pairs(u.definicion) do def[k] = v end
    if etiqueta and etiqueta ~= "" then
        def.label = etiqueta .. ": " .. tostring(def.label or u.nombre)
        def.networkLabel = etiqueta .. ": " .. tostring(def.networkLabel or u.nombre)
    end
    -- Sin `onCommit`: el conjuro ya se pago al lanzarlo la primera vez.
    local opened, abrirErr = HarfordDnDArea.Open(def, {
        sourceKind = "player",
        sourceGuid = UnitGUID and UnitGUID("player") or nil,
        sourceName = HarfordDnDRolls and HarfordDnDRolls.GetDisplayName and HarfordDnDRolls.GetDisplayName()
            or (UnitName and UnitName("player")) or "Jugador",
        autoResolve = true,
    })
    if not opened then return false, abrirErr or "No se pudo resolver el conjuro" end
    u.usado[marca] = true
    return true, u.nombre
end

function API.ResolveCast(spellId, options)
    local spell = API.GetSpellById(spellId)
    if not spell then return false, "Conjuro no encontrado" end
    options = options or {}
    if options.ritual then
        return API.ConfirmCast(spellId, options)
    end

    local areaDefinition = API.BuildAreaDefinition and API.BuildAreaDefinition(spell, options)
    if areaDefinition and HarfordDnDArea and HarfordDnDArea.Open then
        -- Objetivo unico: auto-resuelve sin ventana (como un ataque normal). Area real: ventana
        -- para marcar varias victimas.
        local isZone = areaDefinition.area and areaDefinition.area.zone == true
        local isSingle = areaDefinition.area and areaDefinition.area.shape == "other"
            and areaDefinition.area.sizeText == "Objetivo"
        -- ULTIMO CONJURO DE OBJETIVO UNICO. Se guarda su definicion ya construida para los rasgos
        -- que actuan DESPUES de lanzarlo: apuntar a una segunda criatura (Caos del Brujo) o
        -- redirigirlo si fallo (Quemar alma: Rebotar). Solo objetivo unico: "otra criatura" no
        -- significa nada en un area que ya cubre a varias.
        if isSingle and not isZone then
            API._ultimoConjuroUnico = {
                spellId = spellId,
                nombre = tostring(spell.name or spellId),
                definicion = areaDefinition,
                castLevel = API.GetCastLevel(spell, options),
                cuando = (time and time()) or 0,
            }
        end
        local opened, err = HarfordDnDArea.Open(areaDefinition, {
            sourceKind = "player",
            sourceName = HarfordDnDRolls and HarfordDnDRolls.GetDisplayName and HarfordDnDRolls.GetDisplayName()
                or (UnitName and UnitName("player")) or "Jugador",
            autoResolve = (isSingle and not isZone) and true or nil,
            zone = isZone and true or nil,
            onCommit = function()
                local commitOptions = { silent = true, free = options.free,
                    castLevel = API.GetCastLevel(spell, options) }
                local ok, castErr = API.ConfirmCast(spellId, commitOptions)
                return ok, castErr
            end,
            beforeRoll = function(definition)
                if HarfordDnDStore and HarfordDnDStore.ConsumePreparedPowerWordDeath then
                    definition.rerollDamageDice = HarfordDnDStore.ConsumePreparedPowerWordDeath(spell, definition)
                end
            end,
        })
        if not opened then return false, err or "No se pudo abrir el selector de area" end
        return true, 0, API.GetManaCurrent(), API.GetManaMax()
    end

    if IsSpellAttack(spell) then
        local valid, attackErr = ValidateSpellAttack()
        if not valid then return false, attackErr end
        local ok, castErr = API.ConfirmCast(spellId, { silent = true, free = options.free,
            castLevel = API.GetCastLevel(spell, options) })
        if not ok then return false, castErr end
        return RollSpellAttack(spell, true)
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
