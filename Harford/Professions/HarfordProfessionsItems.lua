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
    -- ===== Ampliacion cadenas 1-300 (IDs pendientes: rellenar con el phase vault) =====
    ["aceroflor"] = { id = nil, name = "Aceroflor" },
    ["amuleto_mithril"] = { id = nil, name = "Amuleto de mithril" },
    ["anillo_bronce"] = { id = nil, name = "Anillo de bronce" },
    ["anillo_jade"] = { id = nil, name = "Anillo de jade" },
    ["antidoto"] = { id = nil, name = "Antidoto" },
    ["antiveneno"] = { id = nil, name = "Antiveneno" },
    ["armadura_cuero_grueso"] = { id = nil, name = "Armadura de cuero grueso" },
    ["armadura_escamas_dragon"] = { id = nil, name = "Armadura de escamas de dragon" },
    ["bagre_crudo"] = { id = nil, name = "Bagre crudo" },
    ["banquete_maestro"] = { id = nil, name = "Banquete de maestro" },
    ["bolsa_cuero"] = { id = nil, name = "Bolsa de cuero" },
    ["bolsa_seda"] = { id = nil, name = "Bolsa de seda" },
    ["botas_cuero"] = { id = nil, name = "Botas de cuero" },
    ["botiquin_maestro"] = { id = nil, name = "Botiquin de maestro" },
    ["capa_cuero"] = { id = nil, name = "Capa de cuero" },
    ["capa_lino"] = { id = nil, name = "Capa de lino" },
    ["capa_runica"] = { id = nil, name = "Capa runica" },
    ["carbon"] = { id = nil, name = "Carbon" },
    ["colgante_malaquita"] = { id = nil, name = "Colgante de malaquita" },
    ["coraza_mithril"] = { id = nil, name = "Coraza de mithril" },
    ["corona_torio"] = { id = nil, name = "Corona de torio" },
    ["cota_escamas_hierro"] = { id = nil, name = "Cota de escamas de hierro" },
    ["cuero_crudo_grueso"] = { id = nil, name = "Cuero crudo grueso" },
    ["cuero_crudo_medio"] = { id = nil, name = "Cuero crudo medio" },
    ["cuero_crudo_pesado"] = { id = nil, name = "Cuero crudo pesado" },
    ["cuero_grueso"] = { id = nil, name = "Cuero grueso" },
    ["cuero_medio"] = { id = nil, name = "Cuero medio" },
    ["cuero_pesado"] = { id = nil, name = "Cuero pesado" },
    ["elixir_agilidad"] = { id = nil, name = "Elixir de agilidad" },
    ["elixir_fuerza"] = { id = nil, name = "Elixir de fuerza" },
    ["elixir_sabiduria"] = { id = nil, name = "Elixir de sabiduria" },
    ["escama_dragon"] = { id = nil, name = "Escama de dragon" },
    ["escudo_acero"] = { id = nil, name = "Escudo de acero" },
    ["esencia_mayor"] = { id = nil, name = "Esencia magica mayor" },
    ["esencia_menor"] = { id = nil, name = "Esencia magica menor" },
    ["espada_ancha_acero"] = { id = nil, name = "Espada ancha de acero" },
    ["espada_runica_torio"] = { id = nil, name = "Espada runica de torio" },
    ["espinodorada"] = { id = nil, name = "Espina dorada" },
    ["estofado_sustancioso"] = { id = nil, name = "Estofado sustancioso" },
    ["festin_campamento"] = { id = nil, name = "Festin de campamento" },
    ["filete_jugoso"] = { id = nil, name = "Filete jugoso" },
    ["fragmento_brillante"] = { id = nil, name = "Fragmento brillante" },
    ["gema_aguamarina"] = { id = nil, name = "Aguamarina" },
    ["gema_jade"] = { id = nil, name = "Jade" },
    ["gema_malaquita"] = { id = nil, name = "Malaquita" },
    ["glandula_veneno"] = { id = nil, name = "Glandula de veneno" },
    ["glifo_guerra"] = { id = nil, name = "Glifo de guerra" },
    ["hacha_mithril"] = { id = nil, name = "Hacha de mithril" },
    ["lingote_acero"] = { id = nil, name = "Lingote de acero" },
    ["lingote_hierro"] = { id = nil, name = "Lingote de hierro" },
    ["lingote_mithril"] = { id = nil, name = "Lingote de mithril" },
    ["lingote_torio"] = { id = nil, name = "Lingote de torio" },
    ["lotonegro"] = { id = nil, name = "Loto negro" },
    ["lotopurpura"] = { id = nil, name = "Loto purpura" },
    ["matasuenos"] = { id = nil, name = "Matasuenos" },
    ["maza_bronce"] = { id = nil, name = "Maza de bronce" },
    ["mena_mithril"] = { id = nil, name = "Mena de mithril" },
    ["mena_roca_oscura"] = { id = nil, name = "Mena de roca oscura" },
    ["mena_torio"] = { id = nil, name = "Mena de torio" },
    ["pastel_pescado"] = { id = nil, name = "Pastel de pescado" },
    ["pergamino_enc_arma"] = { id = nil, name = "Pergamino: encantar arma" },
    ["pergamino_enc_arma_mayor"] = { id = nil, name = "Pergamino: encantar arma mayor" },
    ["pergamino_enc_arma_menor"] = { id = nil, name = "Pergamino: encantar arma menor" },
    ["pergamino_enc_armadura"] = { id = nil, name = "Pergamino: encantar armadura" },
    ["pergamino_enc_cristalino"] = { id = nil, name = "Pergamino: encantamiento cristalino" },
    ["pergamino_inscrito_mayor"] = { id = nil, name = "Pergamino inscrito mayor" },
    ["pergamino_proteccion"] = { id = nil, name = "Pergamino de proteccion" },
    ["peto_cuero_pesado"] = { id = nil, name = "Peto de cuero pesado" },
    ["pez_aceitoso"] = { id = nil, name = "Pez aceitoso" },
    ["pez_legendario"] = { id = nil, name = "Pez legendario" },
    ["pez_piedra"] = { id = nil, name = "Pez piedra" },
    ["piedra_aspera"] = { id = nil, name = "Piedra aspera" },
    ["pigmento_ambar"] = { id = nil, name = "Pigmento ambar" },
    ["pigmento_esmeralda"] = { id = nil, name = "Pigmento esmeralda" },
    ["pocion_curacion"] = { id = nil, name = "Pocion de curacion" },
    ["pocion_curacion_mayor"] = { id = nil, name = "Pocion de curacion mayor" },
    ["pocion_curacion_superior"] = { id = nil, name = "Pocion de curacion superior" },
    ["pocion_curacion_suprema"] = { id = nil, name = "Pocion de curacion suprema" },
    ["polvo_extrano"] = { id = nil, name = "Polvo extrano" },
    ["raizvida"] = { id = nil, name = "Raiz de vida" },
    ["retal_lana"] = { id = nil, name = "Retal de lana" },
    ["retal_seda"] = { id = nil, name = "Retal de seda" },
    ["retal_tejido_magico"] = { id = nil, name = "Retal de tejido magico" },
    ["salmon_crudo"] = { id = nil, name = "Salmon crudo" },
    ["salmon_especiado"] = { id = nil, name = "Salmon especiado" },
    ["sangrerreal"] = { id = nil, name = "Sangrerreal" },
    ["tela_lana"] = { id = nil, name = "Tela de lana" },
    ["tela_seda"] = { id = nil, name = "Tela de seda" },
    ["tela_tejido_magico"] = { id = nil, name = "Tela de tejido magico" },
    ["tomo_secretos"] = { id = nil, name = "Tomo de secretos" },
    ["trucha_asada"] = { id = nil, name = "Trucha asada" },
    ["trucha_cruda"] = { id = nil, name = "Trucha cruda" },
    ["tunica_lana"] = { id = nil, name = "Tunica de lana" },
    ["tunica_seda"] = { id = nil, name = "Tunica de seda" },
    ["tunica_tejido_magico"] = { id = nil, name = "Tunica de tejido magico" },
    ["vendaje_lana"] = { id = nil, name = "Vendaje de lana" },
    ["vendaje_seda"] = { id = nil, name = "Vendaje de seda" },
    ["vendaje_tejido_magico"] = { id = nil, name = "Vendaje de tejido magico" },
    ["zarzaespina"] = { id = nil, name = "Zarzaespina" },

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
