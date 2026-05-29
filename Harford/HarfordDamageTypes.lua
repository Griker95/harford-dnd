-- HarfordDamageTypes: tabla de datos de tipos de dano D&D 5e.
-- Solo identidad y presentacion (label, color, category).
-- La logica de mitigacion (inmune/resistente/vulnerable) vive en HarfordDamageMitigation.
-- La aplicacion de dano efectiva vive en HarfordDamage.

HarfordDamageTypes = HarfordDamageTypes or {}

-- Orden canonico (3 fisicos + 10 magicos). El campo "category" decide si un tipo
-- cuenta como fisico o magico para reglas que dependen de ello (ej. armadura natural).
HarfordDamageTypes.ORDER = {
    -- Fisicos
    "slashing",
    "piercing",
    "bludgeoning",
    -- Magicos
    "fire",
    "cold",
    "lightning",
    "thunder",
    "acid",
    "poison",
    "necrotic",
    "radiant",
    "psychic",
    "force",
}

HarfordDamageTypes.CATEGORIES = { "fisico", "magico" }

HarfordDamageTypes.DEFS = {
    slashing    = { label = "Cortante",   color = {0.78, 0.78, 0.78}, category = "fisico" },
    piercing    = { label = "Perforante", color = {0.82, 0.86, 0.92}, category = "fisico" },
    bludgeoning = { label = "Contundente",color = {0.68, 0.60, 0.45}, category = "fisico" },

    fire        = { label = "Fuego",      color = {1.00, 0.40, 0.10}, category = "magico" },
    cold        = { label = "Frio",       color = {0.55, 0.85, 1.00}, category = "magico" },
    lightning   = { label = "Rayo",       color = {0.95, 0.85, 0.25}, category = "magico" },
    thunder     = { label = "Trueno",     color = {0.55, 0.60, 0.85}, category = "magico" },
    acid        = { label = "Acido",      color = {0.55, 0.85, 0.30}, category = "magico" },
    poison      = { label = "Veneno",     color = {0.40, 0.75, 0.30}, category = "magico" },
    necrotic    = { label = "Necrotico",  color = {0.40, 0.20, 0.45}, category = "magico" },
    radiant     = { label = "Radiante",   color = {1.00, 0.95, 0.65}, category = "magico" },
    psychic     = { label = "Psiquico",   color = {0.85, 0.40, 0.85}, category = "magico" },
    force       = { label = "Fuerza",     color = {0.65, 0.55, 0.90}, category = "magico" },
}

function HarfordDamageTypes.Exists(key)
    return key ~= nil and HarfordDamageTypes.DEFS[key] ~= nil
end

function HarfordDamageTypes.Get(key)
    return key and HarfordDamageTypes.DEFS[key] or nil
end

function HarfordDamageTypes.GetLabel(key)
    local def = HarfordDamageTypes.DEFS[key]
    return def and def.label or tostring(key)
end

function HarfordDamageTypes.GetColor(key)
    local def = HarfordDamageTypes.DEFS[key]
    return def and def.color or {1, 1, 1}
end

function HarfordDamageTypes.GetCategory(key)
    local def = HarfordDamageTypes.DEFS[key]
    return def and def.category or nil
end

function HarfordDamageTypes.IsPhysical(key)
    return HarfordDamageTypes.GetCategory(key) == "fisico"
end

function HarfordDamageTypes.IsMagical(key)
    return HarfordDamageTypes.GetCategory(key) == "magico"
end

-- Devuelve la lista ordenada con metadatos para alimentar dropdowns/UI.
function HarfordDamageTypes.GetOrderedList()
    local list = {}
    for _, key in ipairs(HarfordDamageTypes.ORDER) do
        local def = HarfordDamageTypes.DEFS[key]
        if def then
            list[#list + 1] = {
                key      = key,
                label    = def.label,
                color    = def.color,
                category = def.category,
            }
        end
    end
    return list
end

-- Normaliza una palabra del texto (ej. "perforante", "necrotico") a la key canonica.
-- Util para parsear damageComponents producidos por TRP3.
local SPANISH_ALIASES = {
    cortante     = "slashing",   slashing    = "slashing",
    perforante   = "piercing",   piercing    = "piercing",
    contundente  = "bludgeoning",bludgeoning = "bludgeoning",
    fuego        = "fire",       fire        = "fire",
    frio         = "cold",       cold        = "cold",
    ["frío"]     = "cold",
    rayo         = "lightning",  lightning   = "lightning",
    relampago    = "lightning",
    trueno       = "thunder",    thunder     = "thunder",
    acido        = "acid",       acid        = "acid",
    ["ácido"]    = "acid",
    veneno       = "poison",     poison      = "poison",
    necrotico    = "necrotic",   necrotic    = "necrotic",
    ["necrótico"]= "necrotic",
    radiante     = "radiant",    radiant     = "radiant",
    psiquico     = "psychic",    psychic     = "psychic",
    ["psíquico"] = "psychic",
    fuerza       = "force",      force       = "force",
}

function HarfordDamageTypes.FromWord(word)
    if type(word) ~= "string" then return nil end
    return SPANISH_ALIASES[word:lower()]
end
