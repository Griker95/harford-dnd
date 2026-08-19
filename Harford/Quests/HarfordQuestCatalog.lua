------------------------------------------------------------
-- HarfordQuestCatalog - Catalogo de misiones canonicas reutilizables (patron "indice + libro").
--
-- Misiones "de la naturaleza" (no de contrato) que se repiten entre fases. El ArcSpell/gossip solo
-- necesita pasar el `id` a HarfordQuests.Accept(id); la definicion (titulo, objetivos, recompensa)
-- se rellena desde aqui. El info libre del llamador SOBRESCRIBE lo del catalogo, asi que una fase
-- puede ajustar una entrada o inventar una nueva mision sin catalogo (info completa al aceptar).
--
-- Cada entrada usa la MISMA forma que el `info` de HarfordQuests.Accept:
--   { title, description, category, difficulty, icon, reward, source,
--     objectives = { { text = "...", required = N }, ... } }
-- `objectives` con required>1 son contadores (avanzan por SetObjectiveProgress/AdvanceObjective).
-- Solo datos: nada de logica de estado (esa vive en HarfordQuests).
------------------------------------------------------------

HarfordQuestCatalog = HarfordQuestCatalog or {}
local API = HarfordQuestCatalog

local CATALOG = {
    ["world:heraldo_rocavarancolia"] = {
        title = "El heraldo de Rocavarancolia",
        description = "Un mensajero ha caido cerca del vado. Averigua que portaba antes de que los cuervos den cuenta de el.",
        category = "",
        difficulty = "yellow",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        source = "world",
        -- Sin `reward` string: se deriva del `rewards` estructurado. money con campos separados.
        rewards = {
            rep = { faction = "Guardia", amount = 200 },
            xp = 150,
            money = { gold = 12, silver = 30, copper = 0 },  -- oro / plata / cobre separados
        },
        objectives = {
            { text = "Habla con el capitan en el puente", required = 1 },
            { text = "Recupera sellos de la guarnicion", required = 3 },
        },
    },
    ["world:ecos_bajo_la_mina"] = {
        title = "Ecos bajo la mina",
        description = "Los mineros no vuelven. Algo se mueve en la oscuridad.",
        category = "",
        difficulty = "orange",
        icon = "Interface\\Icons\\INV_Pick_02",
        source = "world",
        reward = "1 Pico runico",
        objectives = {
            { text = "Investiga los ruidos de la mina abandonada", required = 1 },
            { text = "Despeja las galerias tomadas", required = 3 },
        },
    },
}

-- Devuelve la definicion (tal cual; el llamador la copia/mezcla). nil si no existe.
function API.Get(id)
    return CATALOG[tostring(id or "")]
end

-- Lista de ids conocidos (para debug/menus).
function API.GetIds()
    local out = {}
    for id in pairs(CATALOG) do out[#out + 1] = id end
    table.sort(out)
    return out
end
