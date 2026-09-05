-- HarfordAuras: tabla de datos de auras "conocidas" por el addon.
-- Sigue el patron canonico de HarfordDnDResources: ORDER + DEFS + helpers.
-- Envuelve la llamada a HarfordServerActions segun el scope de cada aura, asi el
-- resto del codigo deja de manejar IDs literales (29266, 224063, ...).
--
-- scope:
--   "self"           -> HarfordServerActions.ApplyAura / RemoveAuraSelf  (.aura ID self / .unaura ID self)
--   "current_target" -> ApplyAuraToCurrentTarget / RemoveAura            (.aura ID / .unaura ID)
--   "npc"            -> SetNpcAura / RemoveNpcAura                       (.npc set aura ID / .npc set unaura ID)

HarfordAuras = HarfordAuras or {}

HarfordAuras.ORDER = { "death", "loot", "communicator", "concentration" }

HarfordAuras.DEFS = {
    death = {
        id    = 29266,
        label = "Aura de muerte",
        scope = "self",
        note  = "Aplicada al llegar a 0 HP si HarfordDnDStore.animsEnabled; retirada al subir HP.",
    },
    loot = {
        id    = 224063,
        label = "Marca de loot",
        scope = "self",
        note  = "Visual asociada al frame de loot activo.",
    },
    communicator = {
        id    = 309862,
        label = "Comunicador",
        scope = "self",
        note  = "Aura visual aplicada al abrir el Comunicador Harford.",
    },
    concentration = {
        id    = 19746,
        label = "Concentracion",
        scope = "self",
        note  = "La pone HarfordDnDConcentration.Begin y la retira Break: es la cara visible de estar concentrado en un conjuro.",
    },
}

local function ResolveScope(def, scopeOverride)
    local scope = scopeOverride or (def and def.scope) or "self"
    return scope
end

function HarfordAuras.Get(key)
    return key and HarfordAuras.DEFS[key] or nil
end

function HarfordAuras.GetId(key)
    local def = HarfordAuras.DEFS[key]
    return def and def.id or nil
end

-- Aplica un aura conocida por su key (death/loot/...).
-- scopeOverride opcional: fuerza otro scope para esta invocacion sin tocar el DEF.
function HarfordAuras.Apply(key, scopeOverride, opts)
    local def = HarfordAuras.DEFS[key]
    if not def then return false, "aura desconocida: " .. tostring(key) end
    return HarfordAuras.ApplyById(def.id, ResolveScope(def, scopeOverride), opts)
end

function HarfordAuras.Remove(key, scopeOverride, opts)
    local def = HarfordAuras.DEFS[key]
    if not def then return false, "aura desconocida: " .. tostring(key) end
    return HarfordAuras.RemoveById(def.id, ResolveScope(def, scopeOverride), opts)
end

function HarfordAuras.ApplyById(spellId, scope, opts)
    if not HarfordServerActions then
        return false, "HarfordServerActions no disponible"
    end

    scope = scope or "self"
    if scope == "self" and HarfordServerActions.ApplyAura then
        return HarfordServerActions.ApplyAura(spellId, opts)
    elseif scope == "current_target" and HarfordServerActions.ApplyAuraToCurrentTarget then
        return HarfordServerActions.ApplyAuraToCurrentTarget(spellId, opts)
    elseif scope == "npc" and HarfordServerActions.SetNpcAura then
        return HarfordServerActions.SetNpcAura(spellId, opts)
    end

    return false, "scope no soportado: " .. tostring(scope)
end

function HarfordAuras.RemoveById(spellId, scope, opts)
    if not HarfordServerActions then
        return false, "HarfordServerActions no disponible"
    end

    scope = scope or "self"
    if scope == "self" and HarfordServerActions.RemoveAuraSelf then
        return HarfordServerActions.RemoveAuraSelf(spellId, opts)
    elseif scope == "current_target" and HarfordServerActions.RemoveAura then
        return HarfordServerActions.RemoveAura(spellId, opts)
    elseif scope == "npc" and HarfordServerActions.RemoveNpcAura then
        return HarfordServerActions.RemoveNpcAura(spellId, opts)
    end

    return false, "scope no soportado: " .. tostring(scope)
end
