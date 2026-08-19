------------------------------------------------------------
-- HarfordProfessionsItems - Registro CENTRAL de items de profesiones (materiales y resultados).
--
-- Objetivo: que los IDs de Epsilon NO queden sueltos por las recetas. Cada item se referencia por
-- una CLAVE estable (p.ej. "mena_cobre") y aqui se mapea a su item real. Las recetas usan la clave;
-- este modulo resuelve clave -> id. Asi se rellenan los IDs de forma incremental sin tocar recetas.
--
-- Una clave SIN `id` (aun no proporcionado) es valida: la receta que la use aparece como "pendiente"
-- (no crafteable) hasta que se registre el ID. Nada se rompe por IDs que falten.
--
-- Formato de entrada:  ["clave"] = { id = <itemId Epsilon> | nil, name = "<nombre visible>", icon = "<opcional>" }
--
-- API:
--   HarfordProfessionsItems.Get(key)      -> entrada { id, name, icon } o nil
--   HarfordProfessionsItems.GetId(key)    -> itemId (numero) o nil
--   HarfordProfessionsItems.HasId(key)    -> bool (¿tiene ID real registrado?)
--   HarfordProfessionsItems.GetLink(key)  -> itemLink real (si el cliente lo tiene cacheado) o el nombre
--   HarfordProfessionsItems.Set(key, id, name, icon)  -> registra/actualiza (para rellenar rapido o DM)
--   HarfordProfessionsItems.Missing()     -> lista de claves sin ID (para saber que falta)
------------------------------------------------------------

HarfordProfessionsItems = HarfordProfessionsItems or {}
local API = HarfordProfessionsItems

-- ============================================================
-- REGISTRO. Rellenar `id` con el itemId de Epsilon a medida que se indiquen.
-- Mantener las claves en snake_case, estables (las recetas dependen de ellas).
-- Agrupar por familia para que sea facil localizarlas al pegar IDs.
-- ============================================================
-- Rellenar el `id` de cada uno con su itemId de Epsilon cuando se indique. Mientras `id=nil`, la
-- receta que use ese item sale como "pendiente" (no crafteable). Nombres provisionales tipo WoW.
API.REGISTRY = {
    -- ===== Mineria / Herreria =====
    ["mena_cobre"]     = { id = nil, name = "Mena de cobre" },
    ["mena_estano"]    = { id = nil, name = "Mena de estano" },
    ["mena_hierro"]    = { id = nil, name = "Mena de hierro" },
    ["lingote_cobre"]  = { id = nil, name = "Lingote de cobre" },
    ["lingote_bronce"] = { id = nil, name = "Lingote de bronce" },
    ["daga_cobre"]     = { id = nil, name = "Daga de cobre" },
    ["espada_cobre"]   = { id = nil, name = "Espada de cobre" },

    -- ===== Herboristeria / Alquimia =====
    ["paciflor"]                = { id = nil, name = "Paciflor" },
    ["terrablo"]                = { id = nil, name = "Terrablo" },
    ["vial_vacio"]              = { id = nil, name = "Vial vacio" },
    ["pocion_curacion_menor"]   = { id = nil, name = "Pocion de curacion menor" },
    ["pocion_curacion_leve"]    = { id = nil, name = "Pocion de curacion leve" },

    -- ===== Peleteria / Desollar / Sastreria =====
    ["cuero_crudo_ligero"] = { id = nil, name = "Cuero crudo ligero" },
    ["cuero_ligero"]       = { id = nil, name = "Cuero ligero" },
    ["guantes_cuero"]      = { id = nil, name = "Guantes de cuero" },
    ["peto_cuero"]         = { id = nil, name = "Peto de cuero" },
    ["tela_lino"]          = { id = nil, name = "Tela de lino" },
    ["retal_lino"]         = { id = nil, name = "Retal de lino" },
    ["tunica_lino"]        = { id = nil, name = "Tunica de lino" },
    ["bolsa_lino"]         = { id = nil, name = "Bolsa de lino" },

    -- ===== Joyeria / Inscripcion =====
    ["anillo_cobre"]              = { id = nil, name = "Anillo de cobre" },
    ["pigmento_tenue"]           = { id = nil, name = "Pigmento tenue" },
    ["pergamino"]                = { id = nil, name = "Pergamino" },
    ["pergamino_inscrito_menor"] = { id = nil, name = "Pergamino inscrito menor" },

    -- ===== Cocina / Primeros Auxilios =====
    ["harina"]       = { id = nil, name = "Harina" },
    ["pan"]          = { id = nil, name = "Pan recien horneado" },
    ["carne_cruda"]  = { id = nil, name = "Carne cruda" },
    ["carne_asada"]  = { id = nil, name = "Carne asada" },
    ["vendaje_lino"] = { id = nil, name = "Vendaje de lino" },

    -- ===== Venenos =====
    ["veneno_basico"] = { id = nil, name = "Veneno basico" },
}

------------------------------------------------------------
-- API
------------------------------------------------------------
function API.Get(key)
    key = tostring(key or "")
    return API.REGISTRY[key]
end

function API.GetId(key)
    local e = API.Get(key)
    local id = e and tonumber(e.id)
    return id
end

function API.HasId(key)
    return API.GetId(key) ~= nil
end

-- Nombre visible: el registrado, o la propia clave como fallback legible.
function API.GetName(key)
    local e = API.Get(key)
    if e and e.name and e.name ~= "" then return e.name end
    return tostring(key or "")
end

-- itemLink real si el cliente ya cacheo el item (para tooltip clicable); si no, el nombre plano.
function API.GetLink(key)
    local id = API.GetId(key)
    if id and GetItemInfo then
        local _, link = GetItemInfo(id)
        if link then return link end
    end
    return API.GetName(key)
end

-- ¿Cuantos de este item tiene el jugador en la bolsa? (0 si no hay ID o no hay contador).
function API.GetOwnedCount(key)
    local id = API.GetId(key)
    if not id then return 0 end
    if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(id, false, false) or 0 end
    if GetItemCount then return GetItemCount(id, false, false) or 0 end
    return 0
end

-- Registro/actualizacion rapida (para pegar IDs o para que el DM añada items en caliente).
function API.Set(key, id, name, icon)
    key = tostring(key or "")
    if key == "" then return false end
    local e = API.REGISTRY[key] or {}
    if id ~= nil then e.id = tonumber(id) end
    if name ~= nil then e.name = tostring(name) end
    if icon ~= nil then e.icon = icon end
    API.REGISTRY[key] = e
    return true
end

-- Claves declaradas sin ID real: util para saber que falta por rellenar.
function API.Missing()
    local out = {}
    for key in pairs(API.REGISTRY) do
        if not API.HasId(key) then out[#out + 1] = key end
    end
    table.sort(out)
    return out
end
