-- HarfordActionSequence: motor propio de "secuencias de acciones con delay",
-- equivalente ligero a una ArcSpell de SpellCreator (lista de pasos temporizados).
--
-- Una secuencia es un array de pasos: { delay, kind, input, self }
-- Tambien acepta nombres estilo SpellCreator: actionType, vars, selfOnly.
--   delay : segundos desde el inicio (varios pasos con el mismo delay se disparan juntos).
--   kind  : "anim" | "cast" | "npccast" | "command" | "sound"  (ver ACTIONS).
--   input : string con el/los argumento(s) del paso.
--   self  : (opcional) para comandos servidor que aceptan sufijo "self".
--
-- Los comandos servidor salen por HarfordEpsilonCommands con el transporte seguro
-- EpsilonLib. El sonido "nearby" usa TRP3 Extended, igual que SpellCreator.
-- El motor NO valida permisos: el llamador (p.ej. la accion de ataque NPC, gateada
-- por Admin/oficial) decide si puede ejecutarse; el servidor aplica sus permisos.

HarfordActionSequence = HarfordActionSequence or {}

local API = HarfordActionSequence
API.LIBRARY = API.LIBRARY or {}

-- Timers cancelables en vuelo (para Stop). C_Timer.NewTimer como SpellCreator.
local _running = {}

local function BuildCommandOpts(opts)
    local out = {}
    for key, value in pairs(opts or {}) do
        out[key] = value
    end
    if out.forceEpsilon == nil then out.forceEpsilon = true end
    if out.showMessages == nil then out.showMessages = false end
    return out
end

local function SendServerCommand(text, selfFlag, opts)
    if not text or text == "" then return end
    if selfFlag then text = text .. " self" end
    if HarfordEpsilonCommands and HarfordEpsilonCommands.Send then
        HarfordEpsilonCommands.Send(text, BuildCommandOpts(opts))
    end
end

-- Divide "a, b, c" en argumentos sin espacios sobrantes.
local function SplitArgs(input)
    local out = {}
    for piece in tostring(input or ""):gmatch("[^,]+") do
        out[#out + 1] = (piece:gsub("^%s+", ""):gsub("%s+$", ""))
    end
    return out
end

local function ResolveSoundID(soundID)
    if tonumber(soundID) then return tonumber(soundID) end
    if TRP3_API and TRP3_API.utils and TRP3_API.utils.music
        and TRP3_API.utils.music.convertPathToID then
        return TRP3_API.utils.music.convertPathToID(soundID)
    end
    return soundID
end

local function ParseSoundInput(input)
    local args = SplitArgs(input)
    local soundID = ResolveSoundID(args[1])
    if not soundID then return nil end
    return soundID, args[2] or "SFX", tonumber(args[3])
end

local function PositiveInteger(input)
    local value = tonumber(input)
    if not value then return nil end
    value = math.floor(value)
    if value <= 0 then return nil end
    return value
end

-- Ejecutores por tipo de paso. Cada uno recibe (input, action, opts).
API.ACTIONS = {
    -- Animacion/emote sobre el propio personaje (o poseido): .mod anim <id>.
    -- Con opts.npcAnim, en cambio, anima al NPC seleccionado por el servidor via
    -- `.npc emote <id>` (one-shot). Sirve para animar a un NPC defensor NO poseido
    -- (p.ej. parry/dodge al fallar un ataque): `.mod anim` solo afecta al propio
    -- personaje/poseido, asi que no valdria para el NPC objetivo.
    anim = function(input, action, opts)
        local id = PositiveInteger(input)
        if not id then return end
        if opts and opts.npcAnim then
            if HarfordServerActions and HarfordServerActions.SetNpcEmote then
                HarfordServerActions.SetNpcEmote(id, opts)
            end
            return
        end
        if HarfordServerActions and HarfordServerActions.ModAnim and not action.self then
            HarfordServerActions.ModAnim(id, opts)
        else
            SendServerCommand("mod anim " .. tostring(id), action.self, opts)
        end
    end,

    -- Lanzar hechizo: .cast <id>
    cast = function(input, action, opts)
        local id = PositiveInteger(input)
        if not id then return end
        SendServerCommand("cast " .. tostring(id), action.self, opts)
    end,

    -- El NPC poseido/objetivo lanza un hechizo: .npc cast <id>
    npccast = function(input, action, opts)
        local id = PositiveInteger(input)
        if not id then return end
        SendServerCommand("npc cast " .. tostring(id), action.self, opts)
    end,

    -- Comando servidor crudo (con o sin el punto inicial). El llamador es responsable
    -- de que el texto sea de confianza (definido por el DM, no recibido de la red).
    command = function(input, action, opts)
        SendServerCommand(tostring(input), action.self, opts)
    end,

    -- Sonido a los jugadores cercanos via TRP3 Extended: input "soundID, channel, distance".
    -- Replica SpellCreator TRP3e_Sound_playLocalSoundID: usa playLocalSoundID.
    sound = function(input)
        if not (TRP3_API and TRP3_API.utils and TRP3_API.utils.music
            and TRP3_API.utils.music.playLocalSoundID) then
            return
        end
        local soundID, channel, distance = ParseSoundInput(input)
        if not soundID then return end
        TRP3_API.utils.music.playLocalSoundID(soundID, channel, distance)
    end,
}

API.ACTIONS.TRP3e_Sound_playLocalSoundID = API.ACTIONS.sound
API.ACTIONS.Anim = API.ACTIONS.anim
API.ACTIONS.Command = API.ACTIONS.command

-- Ejecuta un paso (resuelve su ejecutor por kind).
local function RunStep(action, opts)
    if type(action) ~= "table" then return end
    local kind = action.kind or action.actionType
    local input = action.input
    if input == nil then input = action.vars end
    if action.self == nil then action.self = action.selfOnly end
    local fn = kind and API.ACTIONS[kind]
    if fn then fn(input, action, opts) end
end

-- Un paso es de "impacto" si lanza `npc cast` (en SpellCreator ese paso es el que
-- aplica el golpe/herida al objetivo). Sirve para que el orquestador de combate
-- intercepte ese instante y, en vez de castear, despache la reaccion del objetivo
-- (herida si impacta, esquiva/parry si falla) en el momento exacto del preset.
local function IsImpactStep(action)
    if type(action) ~= "table" then return false end
    local kind = action.kind or action.actionType
    if kind == "npccast" then return true end
    if kind == "command" or kind == "Command" then
        local input = action.input
        if input == nil then input = action.vars end
        if type(input) == "string" and input:lower():find("npc%s+cast") then
            return true
        end
    end
    return false
end

local function IsAnimStep(action)
    if type(action) ~= "table" then return false end
    local kind = action.kind or action.actionType
    return kind == "anim" or kind == "Anim"
end

-- Ejecuta una secuencia completa. opts se pasa tal cual a los comandos servidor
-- (p.ej. { addonName = "HarfordAdmin" }). Devuelve true si arranco.
-- opts.interceptImpact + opts.onImpact: los pasos de impacto (`npc cast`) NO se
-- envian; en su lugar se llama a opts.onImpact(action, opts) en su `delay`. Lo usa
-- el orquestador de ataque para sincronizar la reaccion del objetivo con el preset.
-- opts.npcAnim: ademas de redirigir anim -> `.npc emote`, se OMITEN los pasos anim
-- posteriores al primero (la "vuelta a postura"). En un NPC no poseido eso pisaria
-- su `npc emote ... repeat`; al no emitirlo, su postura en bucle prevalece sola.
function API.Run(sequence, opts)
    if type(sequence) ~= "table" then return false end
    opts = opts or {}
    local sawAnim = false
    for _, action in ipairs(sequence) do
        local delay = tonumber(action.delay) or 0
        local fire
        if opts.interceptImpact and IsImpactStep(action) then
            fire = function()
                if opts.onImpact then opts.onImpact(action, opts) end
            end
        elseif opts.npcAnim and IsAnimStep(action) then
            if sawAnim then
                fire = nil  -- omitir vuelta a postura: prevalece el npc emote repeat
            else
                sawAnim = true
                fire = function() RunStep(action, opts) end
            end
        else
            fire = function() RunStep(action, opts) end
        end
        if not fire then
            -- paso omitido (p.ej. vuelta a postura en NPC)
        elseif delay <= 0 then
            fire()
        elseif C_Timer and C_Timer.NewTimer then
            local timer
            timer = C_Timer.NewTimer(delay, function()
                _running[timer] = nil
                fire()
            end)
            _running[timer] = true
        else
            fire()  -- sin C_Timer: degradar a inmediato
        end
    end
    return true
end

-- Registra una secuencia con nombre para reutilizarla.
function API.Register(name, sequence)
    if type(name) == "string" and type(sequence) == "table" then
        API.LIBRARY[name] = sequence
    end
end

-- Ejecuta una secuencia previamente registrada.
function API.RunByName(name, opts)
    local sequence = name and API.LIBRARY[name]
    if not sequence then return false end
    return API.Run(sequence, opts)
end

-- Cancela todos los pasos pendientes (timers en vuelo).
function API.Stop()
    for timer in pairs(_running) do
        if timer and timer.Cancel then timer:Cancel() end
        _running[timer] = nil
    end
end
