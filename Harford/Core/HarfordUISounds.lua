------------------------------------------------------------
-- HarfordUISounds - sonidos de interfaz centralizados.
--
-- Los modulos piden un evento semantico. Cada entrada declara si su ID
-- es un FileDataID o un SoundKitID, para no repartir esa decision por
-- la interfaz ni mezclar las dos APIs de Blizzard.
------------------------------------------------------------

HarfordUISounds = HarfordUISounds or {}
local API = HarfordUISounds

API.SOUNDS = API.SOUNDS or {
    quest_accepted = { id = 567400, kind = "file" },
    quest_gossip_shown = { id = 567503, kind = "file" },
    quest_log_opened = { id = 567504, kind = "file" },
    quest_tracking_changed = { id = 567504, kind = "file" },
    quest_log_closed = { id = 567508, kind = "file" },
    quest_completed = { id = 567439, kind = "file" },
    quest_abandoned = { id = 567459, kind = "file" },
    quest_failed = { id = 567459, kind = "file" },
    quest_objective_completed = { id = 1045704, kind = "file" },
    communicator_message_received = { id = 567402, kind = "file" },
    character_panel_opened = { id = 567507, kind = "file" },
    character_panel_tab_changed = { id = 567422, kind = "file" },
    character_sidebar_tab_changed = { id = 567407, kind = "file" },
    skills_panel_opened = { id = 567440, kind = "file" },
    skills_panel_tab_changed = { id = 567440, kind = "file" },
    reputation_tracking_changed = { id = 856, kind = "soundkit" },
    -- Crafteo. NO reutilizar aqui los ids de mision: fabricar sonaria igual que completar
    -- una mision. Se resuelven por NOMBRE contra la tabla SOUNDKIT del cliente (el primero
    -- que exista gana) y, si ninguno existe, el evento queda MUDO en vez de sonar a otra cosa.
    -- Los del TradeSkillFrame nativo se capturan con `nativeprobe sound on` y se pegan aqui
    -- como `{ id = N, kind = "soundkit" }`.
    craft_started = { names = { "UI_PROFESSIONS_CRAFT_START", "TRADESKILL_CREATE" } },
    craft_succeeded = { names = { "UI_PROFESSIONS_CRAFT_COMPLETE", "TRADESKILL_CREATE" } },
    craft_failed = { names = { "UI_PROFESSIONS_CRAFT_FAIL", "IG_QUEST_FAILED" } },
    -- Abrir y cerrar la ventana de recetas. Capturados del libro de profesiones NATIVO con
    -- `nativeprobe sound on` sobre su boton de profesion: 73917 al abrir, 73918 al cerrar.
    -- Van por ID y no por nombre porque no aparecen en la tabla SOUNDKIT del cliente.
    craft_window_opened = { id = 73917, kind = "soundkit" },
    craft_window_closed = { id = 73918, kind = "soundkit" },
    -- Seleccionar una receta de la lista (capturado sobre una fila del TradeSkillFrame nativo).
    craft_recipe_selected = { id = 173752, kind = "soundkit" },
    -- Cambio de pestana LATERAL del libro (capturado sobre SpellBookSkillLineTab del nativo).
    -- Ojo: no es el 856 de la reputacion, aunque se parezcan.
    book_side_tab_changed = { id = 836, kind = "soundkit" },
    -- Pasar pagina. Comparte kit con la pestana lateral (asi es en el nativo), pero tiene
    -- nombre propio: son eventos distintos y uno podria cambiar sin arrastrar al otro.
    book_page_turned = { id = 836, kind = "soundkit" },
    -- Abrir el desplegable de filtros. Comparte kit con reputation_tracking_changed (856), que
    -- es el sonido generico de marcar en la interfaz de Blizzard.
    filter_menu_opened = { id = 856, kind = "soundkit" },
}

local function PlayEntry(entry, channel)
    if type(entry) == "number" then entry = { id = entry, kind = "file" } end
    if type(entry) ~= "table" then return false end
    -- Entrada por NOMBRE de SOUNDKIT: se resuelve contra el cliente, sin numeros inventados.
    -- Si el cliente no conoce ninguno, se queda muda a proposito.
    if not entry.id and type(entry.names) == "table" then
        if type(SOUNDKIT) ~= "table" then return false end
        for _, name in ipairs(entry.names) do
            local kit = SOUNDKIT[name]
            if kit then
                entry = { id = kit, kind = "soundkit" }
                break
            end
        end
    end
    if not entry.id then return false end

    local kind = tostring(entry.kind or "file"):lower()
    local ok, willPlay, handle
    if kind == "file" then
        if type(PlaySoundFile) ~= "function" then return false end
        ok, willPlay, handle = pcall(PlaySoundFile, tostring(entry.id), channel or "SFX")
    elseif kind == "soundkit" then
        if type(PlaySound) ~= "function" then return false end
        ok, willPlay, handle = pcall(PlaySound, tonumber(entry.id), channel or "SFX")
    else
        return false
    end
    return ok and willPlay == true, willPlay, handle
end

function API.Play(event, channel)
    local entry = API.SOUNDS[event]
    local played = PlayEntry(entry, channel)
    return played == true
end

-- Diagnostico explicito: permite averiguar si un numero debe catalogarse como
-- FileDataID o SoundKitID sin repartir pruebas directas por la interfaz.
function API.Probe(id, kind, channel)
    id = tonumber(id)
    if not id then return nil, "ID invalido" end

    kind = tostring(kind or "both"):lower()
    local kinds = kind == "both" and { "file", "soundkit" } or { kind }
    local results = {}
    for _, probeKind in ipairs(kinds) do
        if probeKind == "file" or probeKind == "soundkit" then
            local played, willPlay, handle = PlayEntry({ id = id, kind = probeKind }, channel)
            results[#results + 1] = {
                kind = probeKind,
                played = played == true,
                willPlay = willPlay,
                handle = handle,
            }
        end
    end
    if #results == 0 then return nil, "tipo invalido (file, soundkit o both)" end
    return results
end
