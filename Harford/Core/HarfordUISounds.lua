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
}

local function PlayEntry(entry, channel)
    if type(entry) == "number" then entry = { id = entry, kind = "file" } end
    if type(entry) ~= "table" or not entry.id then return false end

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
