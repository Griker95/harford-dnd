HarfordSync = HarfordSync or {}

HarfordSync.MAX_RESOURCE_MESSAGE_BYTES = HarfordSync.MAX_RESOURCE_MESSAGE_BYTES or 240
HarfordSync.RESOURCE_ENCODING_MARKER = HarfordSync.RESOURCE_ENCODING_MARKER or "~"

HarfordSync.ProfileKeys = HarfordSync.ProfileKeys or {}
HarfordSync.ResourceKeys = HarfordSync.ResourceKeys or {}

-- IDs de habilidades en el mismo orden que SKILLS en HarfordDnD.lua.
-- Si se añade o reordena una habilidad en SKILLS, actualizar aquí también.
HarfordSync.PROF_SKILL_IDS = {
    "Acrobacias", "Atletismo", "Arcano", "Engano", "Historia",
    "Interpretacion", "Intimidacion", "Investigacion", "JuegoManos",
    "Medicina", "Naturaleza", "Percepcion", "Perspicacia", "Persuasion",
    "Religion", "Sigilo", "Supervivencia", "Animales",
}

-- Claves base del perfil DnD (sin Hab_): caben holgadamente en un mensaje de red.
HarfordSync.ProfileKeys.DnDBase = {
    "BonusCompetencia",
    "ArmorClass",
    "AtributoConjuro",
    "ModIniciativa",
    "Fuerza",
    "Destreza",
    "Constitucion",
    "Inteligencia",
    "Sabiduria",
    "Carisma",
    "Salv_Fuerza",
    "Salv_Destreza",
    "Salv_Constitucion",
    "Salv_Inteligencia",
    "Salv_Sabiduria",
    "Salv_Carisma",
}

-- Lista completa (base + prof/exp): se usa para persist local y banco del DM.
-- NO usar para envío de red — supera el límite de SendAddonMessage.
HarfordSync.ProfileKeys.DnD = {
    "BonusCompetencia",
    "ArmorClass",
    "AtributoConjuro",
    "ModIniciativa",

    "Fuerza",
    "Destreza",
    "Constitucion",
    "Inteligencia",
    "Sabiduria",
    "Carisma",

    "Salv_Fuerza",
    "Salv_Destreza",
    "Salv_Constitucion",
    "Salv_Inteligencia",
    "Salv_Sabiduria",
    "Salv_Carisma",

    "Hab_Acrobacias_Prof", "Hab_Acrobacias_Exp",
    "Hab_Atletismo_Prof", "Hab_Atletismo_Exp",
    "Hab_Arcano_Prof", "Hab_Arcano_Exp",
    "Hab_Engano_Prof", "Hab_Engano_Exp",
    "Hab_Historia_Prof", "Hab_Historia_Exp",
    "Hab_Interpretacion_Prof", "Hab_Interpretacion_Exp",
    "Hab_Intimidacion_Prof", "Hab_Intimidacion_Exp",
    "Hab_Investigacion_Prof", "Hab_Investigacion_Exp",
    "Hab_JuegoManos_Prof", "Hab_JuegoManos_Exp",
    "Hab_Medicina_Prof", "Hab_Medicina_Exp",
    "Hab_Naturaleza_Prof", "Hab_Naturaleza_Exp",
    "Hab_Percepcion_Prof", "Hab_Percepcion_Exp",
    "Hab_Perspicacia_Prof", "Hab_Perspicacia_Exp",
    "Hab_Persuasion_Prof", "Hab_Persuasion_Exp",
    "Hab_Religion_Prof", "Hab_Religion_Exp",
    "Hab_Sigilo_Prof", "Hab_Sigilo_Exp",
    "Hab_Supervivencia_Prof", "Hab_Supervivencia_Exp",
    "Hab_Animales_Prof", "Hab_Animales_Exp",
}

-- NOTA: HarfordSync carga ANTES que HarfordDnDResources (orden del .toc), por eso estas
-- listas son copias hardcodeadas y no se pueden derivar de HarfordDnDResources aqui.
-- Determinan el codigo base36 de cada recurso en la serializacion de red: deben incluir
-- TODA clave de HarfordDnDResources.RUNTIME_KEYS/PROFILE_KEYS. Al anadir un recurso nuevo,
-- APENDARLO AL FINAL (nunca reordenar) para no desplazar los codigos de clientes antiguos.
HarfordSync.ResourceKeys.Runtime = HarfordSync.ResourceKeys.Runtime or {
    "Res_health_Cur", "Res_health_Max", "Res_mana_Cur", "Res_mana_Max", "Res_temp_health_Cur", "Res_temp_health_Max",
    "Res_chi_Cur", "Res_chi_Max", "Res_energy_Cur", "Res_energy_Max", "Res_fel_point_Cur", "Res_fel_point_Max",
    "Res_focus_Cur", "Res_focus_Max", "Res_holy_power_Cur", "Res_holy_power_Max", "Res_light_point_Cur", "Res_light_point_Max",
    "Res_mage_point_Cur", "Res_mage_point_Max", "Res_rage_Cur", "Res_rage_Max", "Res_runic_power_Cur", "Res_runic_power_Max",
    "Res_soul_shard_Cur", "Res_soul_shard_Max", "Res_astral_power_Cur", "Res_astral_power_Max", "Res_living_seeds_Cur", "Res_living_seeds_Max",
    "ArmorClass",
    -- Recursos de clase anadidos despues (apendar al final, no reordenar):
    "Res_lay_on_hands_Cur", "Res_lay_on_hands_Max", "Res_channel_divinity_Cur", "Res_channel_divinity_Max",
    "Res_totem_Cur", "Res_totem_Max", "Res_maelstrom_Cur", "Res_maelstrom_Max",
    "Res_healing_mist_Cur", "Res_healing_mist_Max",
}

HarfordSync.ResourceKeys.Config = HarfordSync.ResourceKeys.Config or {
    "Res_health_Max", "Res_mana_Max", "Res_temp_health_Max", "Res_chi_Max", "Res_energy_Max",
    "Res_fel_point_Max", "Res_focus_Max", "Res_holy_power_Max", "Res_light_point_Max", "Res_mage_point_Max",
    "Res_rage_Max", "Res_runic_power_Max", "Res_soul_shard_Max", "Res_astral_power_Max", "Res_living_seeds_Max",
    -- Recursos de clase anadidos despues (apendar al final, no reordenar):
    "Res_lay_on_hands_Max", "Res_channel_divinity_Max",
    "Res_totem_Max", "Res_maelstrom_Max", "Res_healing_mist_Max",
}

local function ToBase36(n)
    return string.format("%x", tonumber(n) or 0)
end

local function BuildResourceCodeMaps(keyOrder)
    local keyToCode = {}
    local codeToKey = {}
    for i, key in ipairs(keyOrder or {}) do
        local code = ToBase36(i - 1)
        keyToCode[key] = code
        codeToKey[code] = key
    end
    return keyToCode, codeToKey
end

HarfordSync.ResourceKeyToCodeRuntime, HarfordSync.ResourceCodeToKeyRuntime = BuildResourceCodeMaps(HarfordSync.ResourceKeys.Runtime)
HarfordSync.ResourceKeyToCodeConfig, HarfordSync.ResourceCodeToKeyConfig = BuildResourceCodeMaps(HarfordSync.ResourceKeys.Config)

function HarfordSync.RegisterPrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(prefix)
    end
end

-- Prioridad de cada trafico en la cola de ChatThrottleLib. `ALERT` para lo que la mesa espera ver
-- YA -- una tirada, un cambio de turno --; `BULK` para las fotos grandes, que pueden esperar y no
-- deben adelantar a una tirada. El resto, normal.
HarfordSync.PRIORIDAD_POR_PREFIJO = {
    DND5EARC     = "ALERT",   -- tiradas, recursos, estados
    HARFORDTURN  = "ALERT",   -- avance de turno
    HARFORDREP   = "BULK",
    HARFORDLOOT  = "BULK",
    HARFORDCFG   = "BULK",
    TCBOARD      = "BULK",    -- snapshots de contratos
}

-- Lo que CTL devuelve al intentar enviar. Solo se GUARDA -- que se mire es cosa del diagnostico --
-- porque avisar por chat de cada fallo seria peor que el fallo.
HarfordSync.ENTREGA = { ok = 0, fallos = 0, ultimoFallo = nil, ultimoPrefijo = nil }

-- Codigos de `Enum.SendAddonMessageResult`, con nombre para que el diagnostico diga algo util en
-- vez de un numero.
HarfordSync.CAUSA_ENTREGA = {
    [0] = "entregado", [3] = "saturado", [5] = "no estas en el grupo",
    [8] = "canal saturado", [9] = "error general",
}

function HarfordSync._AlEntregar(prefijo, salio, causa)
    local E = HarfordSync.ENTREGA
    if salio then
        E.ok = E.ok + 1
        return
    end
    E.fallos = E.fallos + 1
    E.ultimoFallo = HarfordSync.CAUSA_ENTREGA[causa] or ("codigo " .. tostring(causa))
    E.ultimoPrefijo = tostring(prefijo)
end

function HarfordSync.Send(prefix, message, channel, target)
    if not prefix or prefix == "" then
        return false, "Prefix invalido"
    end
    if not channel or channel == "" then
        return false, "Sin canal disponible"
    end
    if channel == "WHISPER" and (not target or target == "") then
        return false, "WHISPER requiere target"
    end

    -- ChatThrottleLib si esta (lo trae EpsilonLib, y otros siete addons del cliente). Aporta tres
    -- cosas que el envio directo no tiene, y NINGUNA cambia el formato del cable: envia el texto
    -- tal cual por `C_ChatInfo.SendAddonMessage`, sin cabecera. Verificado en Epsilon: 16 bytes
    -- enviados, 16 recibidos.
    --
    --   1. Callback de entrega con CAUSA. `SendAddonMessage` a secas no dice si el mensaje salio;
    --      CTL devuelve el enum, y `NotInGroup = 5` es justo el fallo silencioso que se venia
    --      persiguiendo -- `BestChannel()` a nil, o un grupo del que ya no formas parte.
    --   2. Cola con prioridad y control de ancho de banda. Sin ella, una rafaga de recursos o
    --      estados se descarta sin avisar.
    --   3. Reintento automatico ante saturacion (`AddonMessageThrottle`), donde antes se perdia.
    --
    -- Se descarto Chomp para esto: antepone 12 hex de cabecera y DESCARTA lo que no la traiga, asi
    -- que activarlo dejaria sordo a todo cliente sin actualizar. Ademas delega en CTL cuando lo
    -- encuentra, que es el caso en Epsilon.
    local CTL = _G.ChatThrottleLib
    if CTL and CTL.SendAddonMessage then
        local prioridad = HarfordSync.PRIORIDAD_POR_PREFIJO[prefix] or "NORMAL"
        local enviado, err = pcall(CTL.SendAddonMessage, CTL, prioridad, prefix, message or "",
            channel, target, nil, HarfordSync._AlEntregar, prefix)
        -- Si CTL revienta -- mensaje de mas de 255, canal invalido -- se cae al envio directo en
        -- vez de perder el mensaje: el error ya se registro y el directo puede que aun pase.
        if enviado then return true end
        HarfordSync._UltimoError = tostring(err)
    end

    local ok, result
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        ok, result = pcall(C_ChatInfo.SendAddonMessage, prefix, message or "", channel, target)
    elseif SendAddonMessage then
        ok, result = pcall(SendAddonMessage, prefix, message or "", channel, target)
    else
        return false, "SendAddonMessage no disponible"
    end

    if not ok then
        return false, result
    end
    if result == false then
        return false, "SendAddonMessage devolvio false"
    end
    return true
end

-- PETICION DE ESTADOS (DNDCONDREQ / DNDCONDALL)
--
-- Los estados se difundian SOLO al aplicarse. Eso deja fuera tres casos que pasan constantemente:
-- no estar en el grupo en ese momento, recargar despues, o simplemente empezar a mirar a alguien
-- mas tarde. Se copia el modelo de los recursos, que ya lo resolvia: al targetear se PIDE, y el
-- otro contesta con lo que lleva puesto ahora.
--
-- El push se conserva: mantiene la mesa al dia en pleno combate sin volver a targetear. Uno da
-- inmediatez y el otro, correccion.
function HarfordSync.SerializeConditionRequest2(requester)
    return "DNDCONDREQ|" .. tostring(requester or "")
end

function HarfordSync.DeserializeConditionRequest2(message)
    local opcode, requester = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDCONDREQ" then return nil end
    return tostring(requester or "")
end

function HarfordSync.SendConditionRequest2(prefix, requester, target)
    if not target or target == "" then return false end
    return HarfordSync.Send(prefix, HarfordSync.SerializeConditionRequest2(requester), "WHISPER", target)
end

-- La respuesta lleva TODOS los estados de golpe: `id:duracion:turnos,id:...`. Un mensaje por
-- estado multiplicaria el trafico por nada, y la lista completa cabe de sobra en un envio.
function HarfordSync.SerializeConditionList(targetGuid, targetName, estados)
    local partes = {}
    for _, e in ipairs(estados or {}) do
        partes[#partes + 1] = table.concat({
            tostring(e.id or ""),
            tostring(e.duration or "manual"),
            tostring(math.floor(tonumber(e.turns) or 0)),
            tostring(math.floor(tonumber(e.level) or 0)),
        }, ":")
    end
    return table.concat({ "DNDCONDALL", tostring(targetGuid or ""),
        tostring(targetName or ""), table.concat(partes, ",") }, "|")
end

function HarfordSync.DeserializeConditionList(message)
    local opcode, guid, name, lista = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDCONDALL" then return nil end
    local fuera = {}
    for trozo in tostring(lista or ""):gmatch("[^,]+") do
        local id, duracion, turnos, nivel = strsplit(":", trozo)
        if id and id ~= "" then
            fuera[#fuera + 1] = {
                id = id,
                duration = duracion ~= "" and duracion or "manual",
                turns = tonumber(turnos) or 0,
                level = tonumber(nivel) or 0,
            }
        end
    end
    return tostring(guid or ""), tostring(name or ""), fuera
end

function HarfordSync.SendConditionList(prefix, target, targetGuid, targetName, estados)
    if not target or target == "" then return false end
    return HarfordSync.Send(prefix,
        HarfordSync.SerializeConditionList(targetGuid, targetName, estados), "WHISPER", target)
end

-- PETICION DE ESTADOS DE NPC (DNDCONDNPCREQ)
--
-- Quien se acaba de unir o de reconectar no sabe nada de lo que llevan encima los NPCs: esos
-- estados solo se difundieron al aplicarse, y el no estaba. Se pregunta al entrar y contesta quien
-- tenga herramientas de DM, que es quien los aplico.
--
-- Va al canal del grupo, no por susurro, porque el que pregunta NO SABE quien es el DM. Contestar
-- si es por susurro: la respuesta solo le interesa a quien pregunto.
function HarfordSync.SerializeNpcStatesRequest(requester)
    return "DNDCONDNPCREQ|" .. tostring(requester or "")
end

function HarfordSync.DeserializeNpcStatesRequest(message)
    local opcode, requester = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDCONDNPCREQ" then return nil end
    return tostring(requester or "")
end

function HarfordSync.BestChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

function HarfordSync.CopyTableShallow(src)
    local out = {}
    for k, v in pairs(src or {}) do
        out[k] = v
    end
    return out
end





function HarfordSync.EnsureStore(store, activeProfileName)
    if type(store) ~= "table" then
        store = {}
    end

    local resolvedProfile = tostring(activeProfileName or (UnitName and UnitName("player")) or "default")

    if type(store.profiles) ~= "table" then
        store.profiles = {}
    end

    -- `activeProfile` ya no se persiste: el perfil es SIEMPRE el personaje actual
    -- (UnitName). Se limpia cualquier valor heredado de versiones previas.
    store.activeProfile = nil

    if type(store.profiles[resolvedProfile]) ~= "table" then
        store.profiles[resolvedProfile] = {}
    end

    store.values = nil

    return store
end

function HarfordSync.LoadStoreRuntime(store, activeProfileName)
    local resolvedProfile = tostring(activeProfileName or (UnitName and UnitName("player")) or "default")

    store = HarfordSync.EnsureStore(store, resolvedProfile)

    if type(store.profiles[resolvedProfile]) ~= "table" then
        store.profiles[resolvedProfile] = {}
    end

    return store, HarfordSync.CopyTableShallow(store.profiles[resolvedProfile])
end

function HarfordSync.GetValue(store, key, default)
    store = HarfordSync.EnsureStore(store)

    local active = tostring((UnitName and UnitName("player")) or "default")
    local profile = (store.profiles and store.profiles[active]) or {}
    local v = profile[key]

    if v == nil or v == "" then
        return default
    end
    return v
end

function HarfordSync.SetValue(store, key, value)
    store = HarfordSync.EnsureStore(store)

    local active = tostring((UnitName and UnitName("player")) or "default")

    if type(store.profiles) ~= "table" then
        store.profiles = {}
    end

    if type(store.profiles[active]) ~= "table" then
        store.profiles[active] = {}
    end

    store.profiles[active][key] = tostring(value)

    return store, store.profiles[active]
end

function HarfordSync.ReadProfileFromRuntime(runtimeTable, keys)
    local out = {}
    for _, key in ipairs(keys or {}) do
        local v = runtimeTable and runtimeTable[key]
        if v ~= nil then
            out[key] = tostring(v)
        end
    end
    return out
end

function HarfordSync.WriteProfileToRuntime(runtimeTable, profileTable, keys)
    runtimeTable = runtimeTable or {}
    for _, key in ipairs(keys or {}) do
        if profileTable[key] ~= nil then
            runtimeTable[key] = tostring(profileTable[key])
        end
    end
    return runtimeTable
end

function HarfordSync.SaveProfileToBank(bank, profileName, profileTable)
    bank = bank or {}
    bank[tostring(profileName)] = HarfordSync.CopyTableShallow(profileTable or {})
    return bank
end

function HarfordSync.LoadProfileFromBank(bank, profileName)
    if not bank then return nil end
    local tbl = bank[tostring(profileName)]
    if not tbl then return nil end
    return HarfordSync.CopyTableShallow(tbl)
end

function HarfordSync.SerializeKeyValueTable(tbl, keys)
    local parts = {}
    for _, key in ipairs(keys or {}) do
        local v = tbl and tbl[key]
        if v ~= nil then
            parts[#parts + 1] = key .. "=" .. tostring(v)
        end
    end
    return table.concat(parts, ";")
end

function HarfordSync.DeserializeKeyValueTable(raw)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    for pairStr in string.gmatch(raw, "([^;]+)") do
        local eqPos = string.find(pairStr, "=", 1, true)
        if eqPos then
            local key = string.sub(pairStr, 1, eqPos - 1)
            local value = string.sub(pairStr, eqPos + 1)
            if key and key ~= "" then
                tbl[key] = value
            end
        end
    end

    return tbl
end

function HarfordSync.SerializeProfileMessage(opcode, profileName, profileTable, keys)
    opcode = tostring(opcode or "CFG")
    profileName = tostring(profileName or "default")
    local raw = HarfordSync.SerializeKeyValueTable(profileTable or {}, keys or {})
    return opcode .. "|" .. profileName .. "|" .. raw
end

function HarfordSync.DeserializeProfileMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil, nil
    end

    local firstSep = string.find(message, "|", 1, true)
    if not firstSep then return nil, nil, nil end

    local secondSep = string.find(message, "|", firstSep + 1, true)
    if not secondSep then return nil, nil, nil end

    local opcode = string.sub(message, 1, firstSep - 1)
    local profileName = string.sub(message, firstSep + 1, secondSep - 1)
    local raw = string.sub(message, secondSep + 1)

    if opcode == "" or profileName == "" then
        return nil, nil, nil
    end

    return opcode, profileName, HarfordSync.DeserializeKeyValueTable(raw)
end

function HarfordSync.SendProfile(prefix, opcode, profileName, profileTable, keys, channel, target)
    local ch = channel or HarfordSync.BestChannel()
    if not ch then
        return false, "Sin canal disponible"
    end

    local payload = HarfordSync.SerializeProfileMessage(opcode, profileName, profileTable, keys)
    return HarfordSync.Send(prefix, payload, ch, target)
end

-- Envía las claves base (atributos, salvaciones, misc) como DNDCFG.
-- Las prof/exp de habilidades van en un mensaje DNDPROF separado.
function HarfordSync.SendDnDProfile(prefix, profileName, profileTable, channel, target)
    return HarfordSync.SendProfile(
        prefix,
        "DNDCFG",
        profileName,
        profileTable,
        HarfordSync.ProfileKeys.DnDBase,
        channel,
        target
    )
end

function HarfordSync.ReceiveDnDProfile(message)
    local opcode, profileName, tbl = HarfordSync.DeserializeProfileMessage(message)
    if opcode ~= "DNDCFG" then
        return nil, nil
    end
    return profileName, tbl
end

-- ---------------------------------------------------------------------------
-- DNDPROF: mensaje compacto para los 36 flags Hab_X_Prof / Hab_X_Exp.
-- Formato: "DNDPROF|<profileName>|<18 bits Prof><18 bits Exp>"
-- Cada bit es "1" (competente/experto) o "0", en el orden de PROF_SKILL_IDS.
-- Total ~60 bytes — siempre cabe en un mensaje de red.
-- ---------------------------------------------------------------------------

function HarfordSync.SerializeDnDProfFlags(profileName, tbl)
    profileName = tostring(profileName or "")
    local ids = HarfordSync.PROF_SKILL_IDS
    local profBits = {}
    local expBits  = {}
    for _, id in ipairs(ids) do
        profBits[#profBits + 1] = ((tbl and tbl["Hab_" .. id .. "_Prof"] == "1") and "1" or "0")
        expBits [#expBits  + 1] = ((tbl and tbl["Hab_" .. id .. "_Exp"]  == "1") and "1" or "0")
    end
    return "DNDPROF|" .. profileName .. "|" .. table.concat(profBits) .. table.concat(expBits)
end

function HarfordSync.DeserializeDnDProfFlags(message)
    if type(message) ~= "string" then return nil, nil end
    local s1 = string.find(message, "|", 1, true)
    if not s1 then return nil, nil end
    local s2 = string.find(message, "|", s1 + 1, true)
    if not s2 then return nil, nil end
    local opcode      = string.sub(message, 1, s1 - 1)
    local profileName = string.sub(message, s1 + 1, s2 - 1)
    local bits        = string.sub(message, s2 + 1)
    if opcode ~= "DNDPROF" or profileName == "" or #bits < 36 then
        return nil, nil
    end
    local ids = HarfordSync.PROF_SKILL_IDS
    local n   = #ids  -- 18
    local tbl = {}
    for i, id in ipairs(ids) do
        tbl["Hab_" .. id .. "_Prof"] = string.sub(bits, i,     i    )
        tbl["Hab_" .. id .. "_Exp"]  = string.sub(bits, i + n, i + n)
    end
    return profileName, tbl
end

function HarfordSync.SendDnDProfFlags(prefix, profileName, tbl, channel, target)
    local ch = channel
    if (not ch or ch == "") and (target and target ~= "") then
        ch = "WHISPER"
    end
    if not ch or ch == "" then
        return false, "Sin canal disponible"
    end
    local payload = HarfordSync.SerializeDnDProfFlags(profileName, tbl)
    return HarfordSync.Send(prefix, payload, ch, target)
end

-- ---------------------------------------------------------------------------
-- DNDCLASS: progresion de clases/subclases/rasgos. Separado de DNDCFG para no
-- mezclar tablas anidadas con las claves planas historicas de ficha.
-- ---------------------------------------------------------------------------

local CLASS_CHUNK_BYTES = 180
local CLASS_CHUNK_BUFFER_TTL = 60
local classProgressionChunkBuffers = {}
local equipChunkBuffers = {}
local lootConfigChunkBuffers = {}
local taggedLootChunkBuffers = {}

local function Now()
    return (GetTime and GetTime()) or (time and time()) or 0
end

local function PruneChunkBuffers(buffers)
    local now = Now()
    for key, buffer in pairs(buffers or {}) do
        if (now - (tonumber(buffer.createdAt) or now)) > CLASS_CHUNK_BUFFER_TTL then
            buffers[key] = nil
        end
    end
end

local function EscapeProgressionText(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub("|", "%%7C")
    value = value:gsub(";", "%%3B")
    value = value:gsub(",", "%%2C")
    value = value:gsub(":", "%%3A")
    value = value:gsub("=", "%%3D")
    value = value:gsub("~", "%%7E")  -- delimitador de tokens; debe escaparse en texto libre (desc)
    return value
end

local function UnescapeProgressionText(value)
    value = tostring(value or "")
    value = value:gsub("%%7C", "|")
    value = value:gsub("%%3B", ";")
    value = value:gsub("%%2C", ",")
    value = value:gsub("%%3A", ":")
    value = value:gsub("%%3D", "=")
    value = value:gsub("%%7E", "~")
    value = value:gsub("%%25", "%%")
    return value
end

local function SortedMapParts(map, valueFormatter)
    local parts = {}
    for key, value in pairs(map or {}) do
        if value then
            if valueFormatter then
                parts[#parts + 1] = EscapeProgressionText(key) .. ":" .. valueFormatter(value)
            else
                parts[#parts + 1] = EscapeProgressionText(key)
            end
        end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

local function SerializeImportedProficiencies(imported)
    imported = imported or {}
    return table.concat({
        SortedMapParts(imported.skillRank, function(value) return tostring(tonumber(value) or 1) end),
        SortedMapParts(imported.saveProf),
        SortedMapParts(imported.armorProf),
        SortedMapParts(imported.weaponProf),
        SortedMapParts(imported.toolProf),
    }, "~")
end

local function ReadFlagList(raw, out)
    for token in tostring(raw or ""):gmatch("([^,]+)") do
        local key = UnescapeProgressionText(token)
        if key ~= "" then out[key] = true end
    end
end

local function DeserializeImportedProficiencies(raw)
    local imported = { skillRank = {}, saveProf = {}, armorProf = {}, weaponProf = {}, toolProf = {} }
    local skillRaw, saveRaw, armorRaw, weaponRaw, toolRaw = tostring(raw or ""):match("^([^~]*)~?([^~]*)~?([^~]*)~?([^~]*)~?(.*)$")
    for token in tostring(skillRaw or ""):gmatch("([^,]+)") do
        local key, rank = token:match("^([^:]+):?([^:]*)$")
        key = UnescapeProgressionText(key or "")
        if key ~= "" then imported.skillRank[key] = tonumber(rank) or 1 end
    end
    ReadFlagList(saveRaw, imported.saveProf)
    ReadFlagList(armorRaw, imported.armorProf)
    ReadFlagList(weaponRaw, imported.weaponProf)
    ReadFlagList(toolRaw, imported.toolProf)
    return imported
end

function HarfordSync.SerializeDnDClassProgression(profileName, data, opcode)
    profileName = tostring(profileName or "default")
    opcode = tostring(opcode or "DNDCLASS")
    data = data or {}

    local classParts = {}
    for _, entry in ipairs(data.classLevels or {}) do
        classParts[#classParts + 1] = table.concat({
            EscapeProgressionText(entry.classId),
            EscapeProgressionText(entry.subclassId),
            tostring(tonumber(entry.level) or 1),
        }, ",")
    end

    local featureParts = {}
    for featureId, enabled in pairs(data.featureStates or {}) do
        featureParts[#featureParts + 1] = EscapeProgressionText(featureId) .. ":" .. (enabled and "1" or "0")
    end
    table.sort(featureParts)

    -- Elecciones (choices): featureId : opt1~opt2~...  (slots por "~", entradas por ",")
    local choiceParts = {}
    for featureId, slots in pairs(data.choices or {}) do
        if type(slots) == "table" and #slots > 0 then
            local slotParts = {}
            for _, optionId in ipairs(slots) do
                slotParts[#slotParts + 1] = EscapeProgressionText(optionId)
            end
            choiceParts[#choiceParts + 1] = EscapeProgressionText(featureId) .. ":" .. table.concat(slotParts, "~")
        end
    end
    table.sort(choiceParts)

    -- Dotes: lista de featId separados por "~".
    local featParts = {}
    for _, featId in ipairs(data.feats or {}) do
        if tostring(featId or "") ~= "" then
            featParts[#featParts + 1] = EscapeProgressionText(featId)
        end
    end

    local stateParts = {}
    for stateId, enabled in pairs(data.activeStates or {}) do
        if enabled then
            stateParts[#stateParts + 1] = EscapeProgressionText(stateId)
        end
    end
    table.sort(stateParts)

    local race = type(data.race) == "table" and data.race or {}
    local raw = table.concat({
        "v=" .. tostring(tonumber(data.schema) or 1),
        "c=" .. table.concat(classParts, "~"),
        "f=" .. table.concat(featureParts, ","),
        "h=" .. table.concat(choiceParts, ","),
        "r=" .. EscapeProgressionText(race.id or "") .. "~" .. EscapeProgressionText(race.subraceId or ""),
        "b=" .. EscapeProgressionText(data.background or "") .. "~" .. EscapeProgressionText(data.backgroundDesc or ""),
        "d=" .. table.concat(featParts, "~"),
        "x=" .. tostring(math.max(0, math.floor(tonumber(data.xp) or 0))),
        "s=" .. table.concat(stateParts, "~"),
        "p=" .. SerializeImportedProficiencies(data.importedProficiencies),
    }, ";")

    return opcode .. "|" .. profileName .. "|" .. raw
end

-- Devuelve profileName, data, isInspect. isInspect = true cuando el opcode es el de
-- inspeccion (DNDINSCLASS): el receptor NO debe importarlo a persistencia, solo cachearlo.
function HarfordSync.DeserializeDnDClassProgression(message)
    if type(message) ~= "string" then return nil, nil end
    local opcode, profileName, raw = message:match("^([^|]+)|([^|]+)|(.*)$")
    if (opcode ~= "DNDCLASS" and opcode ~= "DNDINSCLASS") or not profileName or profileName == "" then
        return nil, nil
    end
    local isInspect = (opcode == "DNDINSCLASS")

    local data = { schema = 1, classLevels = {}, featureStates = {}, choices = {}, race = { id = "", subraceId = "" }, background = "", backgroundDesc = "", feats = {}, xp = 0, activeStates = {}, importedProficiencies = { skillRank = {}, saveProf = {}, armorProf = {}, weaponProf = {}, toolProf = {} } }
    for part in tostring(raw or ""):gmatch("([^;]+)") do
        local key, value = part:match("^([^=]+)=(.*)$")
        if key == "v" then
            data.schema = tonumber(value) or 1
        elseif key == "c" and value ~= "" then
            for entryText in value:gmatch("([^~]+)") do
                local classId, subclassId, level = entryText:match("^([^,]*),([^,]*),([^,]*)$")
                if classId and classId ~= "" then
                    data.classLevels[#data.classLevels + 1] = {
                        classId = UnescapeProgressionText(classId),
                        subclassId = UnescapeProgressionText(subclassId),
                        level = tonumber(level) or 1,
                    }
                end
            end
        elseif key == "f" and value ~= "" then
            for featureText in value:gmatch("([^,]+)") do
                local featureId, enabled = featureText:match("^([^:]+):([^:]*)$")
                if featureId and featureId ~= "" then
                    data.featureStates[UnescapeProgressionText(featureId)] = enabled == "1"
                end
            end
        elseif key == "h" and value ~= "" then
            for choiceText in value:gmatch("([^,]+)") do
                local featureId, slotsText = choiceText:match("^([^:]+):(.*)$")
                if featureId and featureId ~= "" then
                    local slots = {}
                    for optionId in tostring(slotsText or ""):gmatch("([^~]+)") do
                        slots[#slots + 1] = UnescapeProgressionText(optionId)
                    end
                    data.choices[UnescapeProgressionText(featureId)] = slots
                end
            end
        elseif key == "r" and value ~= "" then
            local raceId, subraceId = value:match("^([^~]*)~?(.*)$")
            data.race.id = UnescapeProgressionText(raceId or "")
            data.race.subraceId = UnescapeProgressionText(subraceId or "")
        elseif key == "b" and value ~= "" then
            -- Formato nuevo "id~desc"; mensajes antiguos sin "~" -> solo id, desc vacio.
            local bgId, bgDesc = value:match("^([^~]*)~?(.*)$")
            data.background = UnescapeProgressionText(bgId or "")
            data.backgroundDesc = UnescapeProgressionText(bgDesc or "")
        elseif key == "d" and value ~= "" then
            for featId in value:gmatch("([^~]+)") do
                data.feats[#data.feats + 1] = UnescapeProgressionText(featId)
            end
        elseif key == "x" then
            data.xp = math.max(0, math.floor(tonumber(value) or 0))
        elseif key == "s" and value ~= "" then
            for stateId in value:gmatch("([^~]+)") do
                stateId = UnescapeProgressionText(stateId)
                if stateId ~= "" then data.activeStates[stateId] = true end
            end
        elseif key == "p" then
            data.importedProficiencies = DeserializeImportedProficiencies(value)
        end
    end

    return profileName, data, isInspect
end

-- opcode: "DNDCLASS" (sync normal -> import) o "DNDINSCLASS" (inspeccion -> solo cache).
function HarfordSync.SendDnDClassProgression(prefix, profileName, data, channel, target, opcode)
    local ch = channel
    if (not ch or ch == "") and (target and target ~= "") then
        ch = "WHISPER"
    end
    ch = ch or HarfordSync.BestChannel()
    if not ch or ch == "" then
        return false, "Sin canal disponible"
    end

    opcode = tostring(opcode or "DNDCLASS")
    local payload = HarfordSync.SerializeDnDClassProgression(profileName, data, opcode)
    if #payload <= HarfordSync.MAX_RESOURCE_MESSAGE_BYTES then
        return HarfordSync.Send(prefix, payload, ch, target)
    end

    local transferId = tostring((GetServerTime and GetServerTime()) or time() or 0) .. tostring(math.random(1000, 9999))
    local total = math.max(1, math.ceil(#payload / CLASS_CHUNK_BYTES))
    for i = 1, total do
        local chunk = payload:sub(((i - 1) * CLASS_CHUNK_BYTES) + 1, i * CLASS_CHUNK_BYTES)
        local ok, err = HarfordSync.Send(prefix, table.concat({ opcode .. "C", transferId, tostring(i), tostring(total), chunk }, "|"), ch, target)
        if not ok then return false, err end
    end
    return true
end

function HarfordSync.ReceiveDnDClassProgressionChunk(message, sender)
    local opcode, transferId, indexRaw, totalRaw, chunk = tostring(message or ""):match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if opcode ~= "DNDCLASSC" and opcode ~= "DNDINSCLASSC" then return nil, nil end
    if not transferId then return nil, nil end
    local index = tonumber(indexRaw)
    local total = tonumber(totalRaw)
    if not index or not total or index < 1 or index > total or total > 50 then
        return nil, nil
    end

    local key = tostring(sender or "") .. ":" .. transferId
    PruneChunkBuffers(classProgressionChunkBuffers)
    local buffer = classProgressionChunkBuffers[key]
    if not buffer or buffer.total ~= total then
        buffer = { total = total, received = 0, chunks = {}, createdAt = Now() }
        classProgressionChunkBuffers[key] = buffer
    end
    if not buffer.chunks[index] then
        buffer.chunks[index] = chunk
        buffer.received = buffer.received + 1
    end
    if buffer.received < total then return nil, nil end

    local parts = {}
    for i = 1, total do
        if not buffer.chunks[i] then return nil, nil end
        parts[i] = buffer.chunks[i]
    end
    classProgressionChunkBuffers[key] = nil
    return HarfordSync.DeserializeDnDClassProgression(table.concat(parts))
end

-- ---------------------------------------------------------------------------
-- DNDEQUIP: equipo virtual Harford. slot -> itemLink + seleccion basica opcional.
-- ---------------------------------------------------------------------------

function HarfordSync.SerializeDnDEquipment(profileName, equipment, opcode)
    profileName = tostring(profileName or "default")
    opcode = tostring(opcode or "DNDEQUIP")
    local parts = {}
    for slotKey, entry in pairs(equipment or {}) do
        local itemLink = type(entry) == "table" and entry.itemLink or entry
        local basicWeaponKey = type(entry) == "table" and entry.basicWeaponKey or nil
        local basicArmorKey = type(entry) == "table" and entry.basicArmorKey or nil
        if tostring(slotKey or "") ~= "" and (tostring(itemLink or "") ~= "" or tostring(basicWeaponKey or "") ~= "" or tostring(basicArmorKey or "") ~= "") then
            local fields = {}
            if tostring(itemLink or "") ~= "" then fields[#fields + 1] = "i:" .. EscapeProgressionText(itemLink) end
            if tostring(basicWeaponKey or "") ~= "" then fields[#fields + 1] = "w:" .. EscapeProgressionText(basicWeaponKey) end
            if tostring(basicArmorKey or "") ~= "" then fields[#fields + 1] = "a:" .. EscapeProgressionText(basicArmorKey) end
            parts[#parts + 1] = EscapeProgressionText(slotKey) .. "=" .. table.concat(fields, ",")
        end
    end
    table.sort(parts)
    return opcode .. "|" .. profileName .. "|" .. table.concat(parts, ";")
end

-- Devuelve profileName, equipment, isInspect (igual semantica que la progresion).
function HarfordSync.DeserializeDnDEquipment(message)
    if type(message) ~= "string" then return nil, nil end
    local opcode, profileName, raw = message:match("^([^|]+)|([^|]+)|(.*)$")
    if (opcode ~= "DNDEQUIP" and opcode ~= "DNDINSEQUIP") or not profileName or profileName == "" then
        return nil, nil
    end
    local isInspect = (opcode == "DNDINSEQUIP")
    local equipment = {}
    for part in tostring(raw or ""):gmatch("([^;]+)") do
        local slotKey, value = part:match("^([^=]+)=(.*)$")
        slotKey = UnescapeProgressionText(slotKey or "")
        value = tostring(value or "")
        if slotKey ~= "" and value ~= "" then
            local entry = {}
            if value:find("^i:") or value:find("^w:") or value:find("^a:") or value:find(",i:") or value:find(",w:") or value:find(",a:") then
                for field in value:gmatch("([^,]+)") do
                    local fieldKey, fieldValue = field:match("^([^:]+):(.*)$")
                    fieldValue = UnescapeProgressionText(fieldValue or "")
                    if fieldKey == "i" and fieldValue ~= "" then
                        entry.itemLink = fieldValue
                        entry.itemId = tostring(fieldValue):match("item:(%d+)") or fieldValue
                    elseif fieldKey == "w" and fieldValue ~= "" then
                        entry.basicWeaponKey = fieldValue
                    elseif fieldKey == "a" and fieldValue ~= "" then
                        entry.basicArmorKey = fieldValue
                    end
                end
            else
                local itemLink = UnescapeProgressionText(value)
                entry.itemLink = itemLink
                entry.itemId = tostring(itemLink):match("item:(%d+)") or itemLink
            end
            if entry.itemLink or entry.basicWeaponKey or entry.basicArmorKey then
                equipment[slotKey] = entry
            end
        end
    end
    return profileName, equipment, isInspect
end

-- opcode: "DNDEQUIP" (sync normal -> import) o "DNDINSEQUIP" (inspeccion -> solo cache).
function HarfordSync.SendDnDEquipment(prefix, profileName, equipment, channel, target, opcode)
    local ch = channel
    if (not ch or ch == "") and (target and target ~= "") then
        ch = "WHISPER"
    end
    ch = ch or HarfordSync.BestChannel()
    if not ch or ch == "" then
        return false, "Sin canal disponible"
    end

    opcode = tostring(opcode or "DNDEQUIP")
    local payload = HarfordSync.SerializeDnDEquipment(profileName, equipment, opcode)
    if #payload <= HarfordSync.MAX_RESOURCE_MESSAGE_BYTES then
        return HarfordSync.Send(prefix, payload, ch, target)
    end

    local transferId = tostring((GetServerTime and GetServerTime()) or time() or 0) .. tostring(math.random(1000, 9999))
    local total = math.max(1, math.ceil(#payload / CLASS_CHUNK_BYTES))
    for i = 1, total do
        local chunk = payload:sub(((i - 1) * CLASS_CHUNK_BYTES) + 1, i * CLASS_CHUNK_BYTES)
        local ok, err = HarfordSync.Send(prefix, table.concat({ opcode .. "C", transferId, tostring(i), tostring(total), chunk }, "|"), ch, target)
        if not ok then return false, err end
    end
    return true
end

function HarfordSync.ReceiveDnDEquipmentChunk(message, sender)
    local opcode, transferId, indexRaw, totalRaw, chunk = tostring(message or ""):match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if opcode ~= "DNDEQUIPC" and opcode ~= "DNDINSEQUIPC" then return nil, nil end
    if not transferId then return nil, nil end
    local index = tonumber(indexRaw)
    local total = tonumber(totalRaw)
    if not index or not total or index < 1 or index > total or total > 50 then
        return nil, nil
    end

    local key = tostring(sender or "") .. ":" .. transferId
    PruneChunkBuffers(equipChunkBuffers)
    local buffer = equipChunkBuffers[key]
    if not buffer or buffer.total ~= total then
        buffer = { total = total, received = 0, chunks = {}, createdAt = Now() }
        equipChunkBuffers[key] = buffer
    end
    if not buffer.chunks[index] then
        buffer.chunks[index] = chunk
        buffer.received = buffer.received + 1
    end
    if buffer.received < total then return nil, nil end

    local parts = {}
    for i = 1, total do
        if not buffer.chunks[i] then return nil, nil end
        parts[i] = buffer.chunks[i]
    end
    equipChunkBuffers[key] = nil
    return HarfordSync.DeserializeDnDEquipment(table.concat(parts))
end


function HarfordSync.BroadcastProfiles(prefix, opcode, bank, keys, channel, target)
    local ch = channel or HarfordSync.BestChannel()
    if not ch then
        return false, "Sin canal disponible"
    end

    local count = 0
    for profileName, tbl in pairs(bank or {}) do
        local payload = HarfordSync.SerializeProfileMessage(opcode, profileName, tbl, keys)
        local ok, err = HarfordSync.Send(prefix, payload, ch, target)
        if not ok then
            return false, err, count
        end
        count = count + 1
    end

    return true, count
end

local function DefaultCurKey(resourceKey)
    return "Res_" .. tostring(resourceKey) .. "_Cur"
end

local function DefaultMaxKey(resourceKey)
    return "Res_" .. tostring(resourceKey) .. "_Max"
end

function HarfordSync.IsResourceEntryActive(resourceKey, curValue, maxValue, activityMode)
    local maxNum = tonumber(maxValue) or 0
    local curNum = tonumber(curValue) or 0

    if activityMode == "max" then
        return maxNum > 0
    end

    if resourceKey == "temp_health" then
        return curNum > 0
    end

    return maxNum > 0
end

function HarfordSync.BuildActiveResourcePayloadFromStore(readValueFn, resourceOrder, options)
    local out = {}
    local keysToSend = {}
    options = options or {}

    local includeInactive = options.includeInactive == true
    local includeCurrent = options.includeCurrent ~= false
    local includeMax = options.includeMax ~= false
    local activityMode = options.activityMode or "runtime"
    local makeCurKey = options.makeCurKey or DefaultCurKey
    local makeMaxKey = options.makeMaxKey or DefaultMaxKey

    for _, resourceKey in ipairs(resourceOrder or {}) do
        local curKey = makeCurKey(resourceKey)
        local maxKey = makeMaxKey(resourceKey)
        local curVal = tostring((readValueFn and readValueFn(curKey)) or "0")
        local maxVal = tostring((readValueFn and readValueFn(maxKey)) or "0")
        local isActive = HarfordSync.IsResourceEntryActive(resourceKey, curVal, maxVal, activityMode)

        if includeInactive or isActive then
            if includeCurrent then
                out[curKey] = curVal
                keysToSend[#keysToSend + 1] = curKey
            end
            if includeMax then
                out[maxKey] = maxVal
                keysToSend[#keysToSend + 1] = maxKey
            end
        end
    end

    return out, keysToSend
end

function HarfordSync.BuildActiveResourcePayloadFromTable(sourceTable, resourceOrder, options)
    return HarfordSync.BuildActiveResourcePayloadFromStore(function(key)
        return sourceTable and sourceTable[key]
    end, resourceOrder, options)
end

function HarfordSync.SerializeResourceTable(profileTable, resourceKeys)
    return HarfordSync.SerializeKeyValueTable(profileTable, resourceKeys)
end

function HarfordSync.DeserializeResourceTable(raw)
    return HarfordSync.DeserializeKeyValueTable(raw)
end

function HarfordSync.SerializeResourceRequestMessage(requesterName)
    return "DNDRESREQ|" .. tostring(requesterName or "")
end

function HarfordSync.DeserializeResourceRequestMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil
    end

    local opcode, requesterName = strsplit("|", message)
    if opcode ~= "DNDRESREQ" then
        return nil
    end

    if not requesterName or requesterName == "" then
        return nil
    end

    return requesterName
end

function HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.SerializeResourceMessageWithLimit(
        "DNDRES",
        profileName,
        resourceTable,
        resourceKeys,
        HarfordSync.MAX_RESOURCE_MESSAGE_BYTES
    )
end

function HarfordSync.SerializeResourceConfigMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.SerializeResourceMessageWithLimit(
        "DNDRESCFG",
        profileName,
        resourceTable,
        resourceKeys,
        HarfordSync.MAX_RESOURCE_MESSAGE_BYTES
    )
end

function HarfordSync.SerializeResourceMessageWithLimit(opcode, profileName, resourceTable, resourceKeys, maxBytes)
    opcode = tostring(opcode or "DNDRES")
    profileName = tostring(profileName or "")
    local header = opcode .. "|" .. profileName .. "|"
    local limit = tonumber(maxBytes) or HarfordSync.MAX_RESOURCE_MESSAGE_BYTES or 240

    if #header >= limit then
        return header
    end

    local out = {}
    local used = #header
    local marker = HarfordSync.RESOURCE_ENCODING_MARKER or "~"
    local keyToCode = (opcode == "DNDRESCFG" and HarfordSync.ResourceKeyToCodeConfig) or HarfordSync.ResourceKeyToCodeRuntime
    for _, key in ipairs(resourceKeys or {}) do
        local value = resourceTable and resourceTable[key]
        if value ~= nil then
            local keyCode = keyToCode and keyToCode[key]
            local encodedKey = keyCode or tostring(key)
            local token = encodedKey .. "=" .. tostring(value)
            local tokenLen = #token
            if #out > 0 then
                tokenLen = tokenLen + 1
            else
                tokenLen = tokenLen + #marker
            end

            if used + tokenLen <= limit then
                out[#out + 1] = token
                used = used + tokenLen
            else
                break
            end
        end
    end

    if #out == 0 then
        return header
    end

    return header .. marker .. table.concat(out, ",")
end

local function DeserializeCompactResourceTable(raw, codeToKey)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    local marker = HarfordSync.RESOURCE_ENCODING_MARKER or "~"
    if string.sub(raw, 1, #marker) ~= marker then
        return HarfordSync.DeserializeResourceTable(raw)
    end

    local compactRaw = string.sub(raw, #marker + 1)
    for pairStr in string.gmatch(compactRaw, "([^,]+)") do
        local eqPos = string.find(pairStr, "=", 1, true)
        if eqPos then
            local code = string.sub(pairStr, 1, eqPos - 1)
            local value = string.sub(pairStr, eqPos + 1)
            local key = codeToKey and codeToKey[code]
            if key and key ~= "" then
                tbl[key] = value
            end
        end
    end

    return tbl
end

function HarfordSync.DeserializeResourceResponseMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil
    end

    local firstSep = string.find(message, "|", 1, true)
    if not firstSep then return nil, nil end

    local secondSep = string.find(message, "|", firstSep + 1, true)
    if not secondSep then return nil, nil end

    local opcode = string.sub(message, 1, firstSep - 1)
    local profileName = string.sub(message, firstSep + 1, secondSep - 1)
    local raw = string.sub(message, secondSep + 1)

    if opcode ~= "DNDRES" or profileName == "" then
        return nil, nil
    end

    return profileName, DeserializeCompactResourceTable(raw, HarfordSync.ResourceCodeToKeyRuntime)
end

function HarfordSync.DeserializeResourceConfigMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil
    end

    local firstSep = string.find(message, "|", 1, true)
    if not firstSep then return nil, nil end

    local secondSep = string.find(message, "|", firstSep + 1, true)
    if not secondSep then return nil, nil end

    local opcode = string.sub(message, 1, firstSep - 1)
    local profileName = string.sub(message, firstSep + 1, secondSep - 1)
    local raw = string.sub(message, secondSep + 1)

    if opcode ~= "DNDRESCFG" or profileName == "" then
        return nil, nil
    end

    return profileName, DeserializeCompactResourceTable(raw, HarfordSync.ResourceCodeToKeyConfig)
end

function HarfordSync.ReceiveResourceMessage(message)
    local requesterName = HarfordSync.DeserializeResourceRequestMessage(message)
    if requesterName then
        return "REQ", requesterName, nil
    end

    local profileName, resourceTable = HarfordSync.DeserializeResourceResponseMessage(message)
    if profileName and resourceTable then
        return "RES", profileName, resourceTable
    end

    return nil, nil, nil
end

function HarfordSync.SerializeResourceAdjustMessage(resourceKey, delta)
    local key = tostring(resourceKey or "")
    local amount = tonumber(delta) or 0
    if key == "" or amount == 0 then
        return nil
    end
    if not key:match("^[%w_%-]+$") then
        return nil
    end
    return "RADJ|" .. key .. "|" .. tostring(math.floor(amount))
end

-- ─── Dano BRUTO a un jugador (DNDDMG) ────────────────────────────────────────
-- Sustituye a RADJ para el DANO. La diferencia no es el formato: es QUIEN decide.
-- Con RADJ el atacante mitigaba con una copia cacheada de las defensas ajenas y mandaba el
-- resultado; aqui se manda el dano EN BRUTO con su tipo y lo resuelve el cliente de la victima,
-- que es el unico que conoce de verdad sus resistencias, sus reducciones y su vida temporal.
-- Es el mismo modelo que ya usa el motor de area.
-- Los componentes van como `cantidad:tipo,cantidad:tipo`. Un golpe puede tener varios tipos a la
-- vez (arma cortante + Golpe Runico de frio) y la victima necesita CADA uno por separado: puede ser
-- resistente a uno y vulnerable al otro. Mandar un solo tipo daria un resultado erroneo.
-- `esMagico` va como CUARTO campo del payload, no dentro de cada componente: la cualidad de
-- magico es del GOLPE, no de un tipo de dano suelto. Ademas asi es compatible en los dos sentidos:
-- un cliente viejo manda tres campos y aqui sale nil (no magico), y uno viejo que reciba cuatro
-- simplemente ignora el que no conoce.
function HarfordSync.SerializeDamage(components, isCritical, esMagico)
    if type(components) ~= "table" then return nil end
    local partes, total = {}, 0
    for _, c in ipairs(components) do
        local amount = math.floor(tonumber(c.amount) or 0)
        local tipo = tostring(c.damageType or ""):match("^[%w_%-]*$") or ""
        if amount > 0 then
            partes[#partes + 1] = tostring(amount) .. ":" .. tipo:sub(1, 20)
            total = total + amount
        end
    end
    if total <= 0 or #partes == 0 then return nil end
    local payload = "DNDDMG|" .. table.concat(partes, ",") .. "|" .. (isCritical and "C" or "")
        .. "|" .. (esMagico and "M" or "")
    return #payload <= 240 and payload or nil
end

function HarfordSync.DeserializeDamage(message)
    local opcode, lista, crit, mag = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDDMG" or not lista then return nil end
    local out = {}
    for amount, tipo in tostring(lista):gmatch("(%d+):([%w_%-]*)") do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then out[#out + 1] = { amount = amount, damageType = tipo } end
    end
    if #out == 0 then return nil end
    return out, crit == "C", mag == "M"
end

function HarfordSync.SendDamage(prefix, target, components, isCritical, esMagico)
    local payload = HarfordSync.SerializeDamage(components, isCritical, esMagico)
    if not payload then return false end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.DeserializeResourceAdjustMessage(message)
    local opcode, key, delta = strsplit("|", tostring(message or ""))
    if opcode ~= "RADJ" then
        return nil, nil
    end
    delta = tonumber(delta)
    if not key or key == "" or not key:match("^[%w_%-]+$") or not delta or delta == 0 then
        return nil, nil
    end
    return key, math.floor(delta)
end

-- ─── Señal de aura a otro jugador (AURASIG) ──────────────────────────────────
-- El atacante pide al jugador objetivo que se aplique un aura (ej. Desarme): el receptor
-- ejecuta `.au <id> self` en su cliente.
function HarfordSync.SerializeAuraSignal(spellId)
    spellId = math.floor(tonumber(spellId) or 0)
    if spellId <= 0 then return nil end
    return "AURASIG|" .. tostring(spellId)
end

function HarfordSync.DeserializeAuraSignal(message)
    local opcode, id = strsplit("|", tostring(message or ""))
    if opcode ~= "AURASIG" then return nil end
    id = tonumber(id)
    if not id or id <= 0 then return nil end
    return math.floor(id)
end

function HarfordSync.SendAuraSignal(prefix, spellId, target)
    if not target or target == "" then return false, "Target invalido" end
    local payload = HarfordSync.SerializeAuraSignal(spellId)
    if not payload then return false, "Aura invalida" end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

-- ─── Flag de animaciones (ANIMFLG) ───────────────────────────────────────────
function HarfordSync.SerializeAnimFlag(enabled)
    return "ANIMFLG|" .. (enabled and "1" or "0")
end

function HarfordSync.DeserializeAnimFlag(message)
    local opcode, val = strsplit("|", tostring(message or ""))
    if opcode ~= "ANIMFLG" then return nil end
    return val == "1"
end

function HarfordSync.SendAnimFlag(prefix, enabled, target)
    local payload = HarfordSync.SerializeAnimFlag(enabled)
    if target and target ~= "" then
        return HarfordSync.Send(prefix, payload, "WHISPER", target)
    else
        local ch = HarfordSync.BestChannel and HarfordSync.BestChannel()
        if ch then return HarfordSync.Send(prefix, payload, ch) end
    end
    return false, "Sin canal disponible"
end

-- ─── Instrucción de aura sobre uno mismo (DOAPPLYAURA) ────────────────────────
function HarfordSync.SerializeApplyAuraSelf(spellId)
    return "DOAPPLYAURA|" .. tostring(math.floor(tonumber(spellId) or 0))
end

function HarfordSync.DeserializeApplyAuraSelf(message)
    local opcode, id = strsplit("|", tostring(message or ""))
    if opcode ~= "DOAPPLYAURA" then return nil end
    return tonumber(id)
end

function HarfordSync.SendApplyAuraSelf(prefix, spellId, target)
    if not target or target == "" then return false end
    local id = math.floor(tonumber(spellId) or 0)
    if id <= 0 then return false end
    return HarfordSync.Send(prefix, HarfordSync.SerializeApplyAuraSelf(id), "WHISPER", target)
end

-- ─── Instrucción de defensa al fallar un ataque (DODEFENSE) ───────────────────
-- Sin payload: el cliente receptor elige parry/dodge segun SU propio modo de
-- combate. Se envia por WHISPER al jugador objetivo cuando el atacante falla.
function HarfordSync.SerializeDefense()
    return "DODEFENSE"
end

function HarfordSync.IsDefenseMessage(message)
    local opcode = strsplit("|", tostring(message or ""))
    return opcode == "DODEFENSE"
end

function HarfordSync.SendDefense(prefix, target)
    if not target or target == "" then return false end
    return HarfordSync.Send(prefix, HarfordSync.SerializeDefense(), "WHISPER", target)
end

-- Reaccion previa al dano. Solo viajan un identificador efimero y el trigger:
-- el cliente defensor conserva y gasta sus propios recursos.
function HarfordSync.SerializeAttackReactionRequest(requestId, trigger, protectedGuid)
    requestId = tostring(requestId or "")
    trigger = tostring(trigger or "")
    if requestId == "" or trigger == "" then return nil end
    return "DNDREACTREQ|" .. requestId .. "|" .. trigger .. "|" .. tostring(protectedGuid or "")
end

function HarfordSync.DeserializeAttackReactionRequest(message)
    local opcode, requestId, trigger, protectedGuid = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDREACTREQ" or not requestId or requestId == "" or not trigger or trigger == "" then return nil end
    return requestId, trigger, protectedGuid
end

function HarfordSync.SendAttackReactionRequest(prefix, target, requestId, trigger, protectedGuid)
    if not target or target == "" then return false end
    local payload = HarfordSync.SerializeAttackReactionRequest(requestId, trigger, protectedGuid)
    if not payload then return false end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SerializeAttackReactionResult(requestId, used)
    requestId = tostring(requestId or "")
    if requestId == "" then return nil end
    return "DNDREACTRES|" .. requestId .. "|" .. (used and "1" or "0")
end

function HarfordSync.DeserializeAttackReactionResult(message)
    local opcode, requestId, used = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDREACTRES" or not requestId or requestId == "" then return nil end
    return requestId, used == "1"
end

function HarfordSync.SendAttackReactionResult(prefix, target, requestId, used)
    if not target or target == "" then return false end
    local payload = HarfordSync.SerializeAttackReactionResult(requestId, used)
    if not payload then return false end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

-- Registro efimero de una reaccion preparada que protege a una unidad. Se manda
-- al grupo para que el atacante pueda consultar al sacerdote correcto al impactar.
function HarfordSync.SerializePreparedAttackReaction(featureId, protectedGuid, armed)
    featureId = tostring(featureId or "")
    protectedGuid = tostring(protectedGuid or "")
    if featureId == "" or protectedGuid == "" then return nil end
    return "DNDREACTARM|" .. featureId .. "|" .. protectedGuid .. "|" .. (armed and "1" or "0")
end

function HarfordSync.DeserializePreparedAttackReaction(message)
    local opcode, featureId, protectedGuid, armed = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDREACTARM" or not featureId or featureId == "" or not protectedGuid or protectedGuid == "" then return nil end
    return featureId, protectedGuid, armed == "1"
end

function HarfordSync.SendPreparedAttackReaction(prefix, featureId, protectedGuid, armed)
    local payload = HarfordSync.SerializePreparedAttackReaction(featureId, protectedGuid, armed)
    if not payload then return false end
    local channel = HarfordSync.BestChannel and HarfordSync.BestChannel() or nil
    if not channel then return false end
    return HarfordSync.Send(prefix, payload, channel)
end

-- ─── Instrucción de herida al impactar (DOWOUND) ──────────────────────────────
-- El atacante avisa al jugador objetivo de que lo ha golpeado; su cliente
-- reproduce la animacion de herida (mod anim 33 normal / 34 critico).
function HarfordSync.SerializeWound(isCritical)
    return "DOWOUND|" .. (isCritical and "1" or "0")
end

function HarfordSync.DeserializeWound(message)
    local opcode, crit = strsplit("|", tostring(message or ""))
    if opcode ~= "DOWOUND" then return nil end
    return true, crit == "1"
end

function HarfordSync.SendWound(prefix, target, isCritical)
    if not target or target == "" then return false end
    return HarfordSync.Send(prefix, HarfordSync.SerializeWound(isCritical), "WHISPER", target)
end

-- Instruccion de salvacion al objetivo jugador (DOSAVE)
-- El atacante solo envia la CD y el efecto; el receptor calcula sus bonos, tira y
-- publica la linea desde su propio cliente. NPCs no usan este mensaje.
local function SaveRequestField(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub("|", "%%7C")
    return value
end

local function LoadSaveRequestField(value)
    value = tostring(value or "")
    value = value:gsub("%%7C", "|")
    value = value:gsub("%%25", "%%")
    return value
end

-- `skill` (ultimo campo): si viene, lo que se pide NO es una salvacion sino una prueba de esa
-- habilidad contra la misma CD. Va al final a proposito: un cliente anterior lo ignora y resuelve
-- una salvacion, que es una degradacion visible en el chat y no un fallo mudo.
function HarfordSync.SerializeRequestedSave(ability, dc, outcome, auraId, conditionId, conditionDuration, conditionTurns, sourceGuid, sourceName, extraDamageDice, extraDamageType, skill)
    ability = SaveRequestField(ability)
    outcome = SaveRequestField(outcome)
    dc = math.floor(tonumber(dc) or 0)
    auraId = math.floor(tonumber(auraId) or 0)
    conditionId = tostring(conditionId or ""):match("^[%w_%-]+$") or ""
    if #conditionId > 40 then conditionId = "" end
    conditionDuration = SaveRequestField(tostring(conditionDuration or "manual"):sub(1, 24))
    conditionTurns = math.max(0, math.min(99, math.floor(tonumber(conditionTurns) or 0)))
    return table.concat({ "DOSAVE", ability, tostring(dc), outcome, tostring(auraId), conditionId,
        conditionDuration, conditionTurns, SaveRequestField(tostring(sourceGuid or ""):sub(1, 64)),
        SaveRequestField(tostring(sourceName or ""):sub(1, 48)),
        SaveRequestField(tostring(extraDamageDice or ""):match("^%d*d%d+$") or ""),
        SaveRequestField(tostring(extraDamageType or ""):match("^[%a_]+$") or ""),
        SaveRequestField(tostring(skill or ""):sub(1, 32)) }, "|")
end

function HarfordSync.DeserializeRequestedSave(message)
    local opcode, ability, dc, outcome, auraId, conditionId, conditionDuration, conditionTurns, sourceGuid, sourceName, extraDamageDice, extraDamageType, skill =
        strsplit("|", tostring(message or ""))
    if opcode ~= "DOSAVE" then return nil end
    ability = LoadSaveRequestField(ability)
    outcome = LoadSaveRequestField(outcome)
    conditionId = tostring(conditionId or ""):match("^[%w_%-]+$") or ""
    conditionDuration = LoadSaveRequestField(conditionDuration or "manual"):sub(1, 24)
    conditionTurns = math.max(0, math.min(99, math.floor(tonumber(conditionTurns) or 0)))
    return ability, tonumber(dc) or 0, outcome, tonumber(auraId) or 0, conditionId,
        conditionDuration, conditionTurns, LoadSaveRequestField(sourceGuid or ""):sub(1, 64),
        LoadSaveRequestField(sourceName or ""):sub(1, 48), LoadSaveRequestField(extraDamageDice or ""),
        LoadSaveRequestField(extraDamageType or ""), LoadSaveRequestField(skill or ""):sub(1, 32)
end

function HarfordSync.SendRequestedSave(prefix, target, ability, dc, outcome, auraId, conditionId,
    conditionDuration, conditionTurns, sourceGuid, sourceName, extraDamageDice, extraDamageType, skill)
    if not target or target == "" then return false end
    return HarfordSync.Send(prefix, HarfordSync.SerializeRequestedSave(ability, dc, outcome, auraId, conditionId,
        conditionDuration, conditionTurns, sourceGuid, sourceName, extraDamageDice, extraDamageType, skill), "WHISPER", target)
end

function HarfordSync.SerializeRequestedSaveResult(saved, sourceGuid)
    return table.concat({ "DOSAVERES", saved and "1" or "0", SaveRequestField(tostring(sourceGuid or ""):sub(1, 64)) }, "|")
end

function HarfordSync.DeserializeRequestedSaveResult(message)
    local opcode, saved, sourceGuid = strsplit("|", tostring(message or ""))
    if opcode ~= "DOSAVERES" or (saved ~= "0" and saved ~= "1") then return nil end
    return saved == "1", LoadSaveRequestField(sourceGuid or ""):sub(1, 64)
end

function HarfordSync.SendRequestedSaveResult(prefix, target, saved, sourceGuid)
    if not target or target == "" then return false end
    return HarfordSync.Send(prefix, HarfordSync.SerializeRequestedSaveResult(saved, sourceGuid), "WHISPER", target)
end

-- Ataques de area: una peticion se envia individualmente al jugador defensor. Solo
-- transporta resultados mecanicos ya tirados; el receptor resuelve su CA/salvacion,
-- mitigacion y recursos. Nunca contiene comandos de servidor.
local function AreaField(value)
    value = tostring(value or ""):gsub("[\r\n]", " ")
    value = value:gsub("%%", "%%25"):gsub("|", "%%7C")
    value = value:gsub(";", "%%3B"):gsub(",", "%%2C")
    return value
end

local function LoadAreaField(value)
    value = tostring(value or "")
    value = value:gsub("%%2C", ","):gsub("%%3B", ";")
    value = value:gsub("%%7C", "|"):gsub("%%25", "%%")
    return value
end

local function SerializeAreaComponents(components)
    local parts = {}
    for i, component in ipairs(components or {}) do
        if i > 8 then break end
        local amount = math.max(0, math.floor(tonumber(component.amount) or 0))
        local maximum = math.max(0, math.floor(tonumber(component.maximum) or amount))
        local damageType = tostring(component.damageType or ""):match("^[%w_]+$")
        if not damageType then return nil end
        parts[#parts + 1] = table.concat({ amount, maximum, damageType }, ",")
    end
    -- "" (vacio) es valido para conjuros de condicion pura; nil solo si un componente es invalido.
    return table.concat(parts, ";")
end

local function DeserializeAreaComponents(value)
    local out = {}
    for token in tostring(value or ""):gmatch("[^;]+") do
        if #out >= 8 then return nil end
        local amount, maximum, damageType = token:match("^(%d+),(%d+),([%w_]+)$")
        amount, maximum = tonumber(amount), tonumber(maximum)
        if not amount or not maximum or amount > 10000 or maximum > 10000 then return nil end
        out[#out + 1] = { amount = amount, maximum = maximum, damageType = damageType }
    end
    return out  -- {} (vacio) valido para condicion pura
end

local AREA_CONDITION_DURATION = {
    manual = "M", target_turn_start = "TS", source_turn_start = "SS",
    target_turn_end = "TE", source_turn_end = "SE", rounds = "R",
    save_at_turn_end = "SV",
}
local AREA_CONDITION_DURATION_LOAD = {}
for key, code in pairs(AREA_CONDITION_DURATION) do AREA_CONDITION_DURATION_LOAD[code] = key end
local AREA_ABILITY = {
    Fuerza = "F", Destreza = "D", Constitucion = "C",
    Inteligencia = "I", Sabiduria = "S", Carisma = "A",
}
local AREA_ABILITY_LOAD = {}
for key, code in pairs(AREA_ABILITY) do AREA_ABILITY_LOAD[code] = key end

local function TrimAreaLabel(value)
    local limit = math.max(0, #value - 8)
    while limit > 0 do
        local nextByte = value:byte(limit + 1)
        if not nextByte or nextByte < 128 or nextByte >= 192 then break end
        limit = limit - 1
    end
    return value:sub(1, limit)
end

function HarfordSync.SerializeAreaRequest(request)
    request = request or {}
    local id = tostring(request.id or ""):match("^[%w%._%-]+$")
    local mode = request.mode == "attack" and "A" or request.mode == "save" and "S"
        or request.mode == "auto" and "U" or request.mode == "heal" and "H" or nil
    local components = SerializeAreaComponents(request.components)
    if not id or #id > 40 or not mode or not components then return nil end

    local ability = AreaField(tostring(request.ability or ""):sub(1, 24))
    local dc = math.max(0, math.min(99, math.floor(tonumber(request.dc) or 0)))
    local success = request.success == "half" and "H" or "N"
    local attackTotal = math.max(-999, math.min(999, math.floor(tonumber(request.attackTotal) or 0)))
    local critical = request.critical == "critical" and "C" or request.critical == "fumble" and "F" or "N"
    local auraId = math.max(0, math.floor(tonumber(request.auraId) or 0))
    local rawConditionId = tostring(request.conditionId or "")
    local conditionId = rawConditionId:match("^[%w_%-]+$")
    if rawConditionId ~= "" and (not conditionId or #conditionId > 40) then return nil end
    local durationCode, turns, saveCode, conditionSaveDC, persist, sourceGuid, sourceName = "", 0, "", 0, "", "", ""
    local applySaveCode, applySaveDC = "", 0
    if conditionId and conditionId ~= "" then
        durationCode = AREA_CONDITION_DURATION[tostring(request.conditionDuration or "manual")]
        if not durationCode then return nil end
        turns = math.max(0, math.min(99, math.floor(tonumber(request.conditionTurns) or 0)))
        saveCode = AREA_ABILITY[tostring(request.conditionSaveAbility or "")] or ""
        conditionSaveDC = math.max(0, math.min(99, math.floor(tonumber(request.conditionSaveDC) or 0)))
        if durationCode == "R" and turns <= 0 then return nil end
        if durationCode == "SV" and (saveCode == "" or conditionSaveDC <= 0) then return nil end
        persist = request.conditionPersist == true and "P" or ""
        sourceGuid = AreaField(tostring(request.sourceGuid or ""):sub(1, 64))
        sourceName = AreaField(tostring(request.sourceName or ""):sub(1, 48))
        applySaveCode = AREA_ABILITY[tostring(request.conditionApplySaveAbility or "")] or ""
        applySaveDC = math.max(0, math.min(99, math.floor(tonumber(request.conditionApplySaveDC) or 0)))
        if applySaveCode == "" then applySaveDC = 0 end
    end
    local labelText = tostring(request.label or "Ataque de area"):sub(1, 80)
    local function BuildPayload()
        return table.concat({ "DNDAREAREQ", id, mode, ability, dc, success,
            attackTotal, critical, auraId, AreaField(labelText), components, conditionId or "",
            durationCode, turns, saveCode, conditionSaveDC, persist, sourceGuid, sourceName,
            applySaveCode, applySaveDC }, "|")
    end
    local payload = BuildPayload()
    while #payload > 240 and labelText ~= "" do
        labelText = TrimAreaLabel(labelText)
        payload = BuildPayload()
    end
    if #payload > 240 then return nil end
    return payload
end

function HarfordSync.DeserializeAreaRequest(message)
    local opcode, id, mode, ability, dc, success, attackTotal, critical, auraId, label, components, conditionId,
        durationCode, conditionTurns, conditionSaveAbility, conditionSaveDC, conditionPersist, sourceGuid, sourceName,
        conditionApplySaveAbility, conditionApplySaveDC =
        strsplit("|", tostring(message or ""))
    if opcode ~= "DNDAREAREQ" or not id or not id:match("^[%w%._%-]+$") or #id > 40 then return nil end
    mode = mode == "A" and "attack" or mode == "S" and "save" or mode == "U" and "auto"
        or mode == "H" and "heal" or nil
    components = DeserializeAreaComponents(components)
    if not mode or not components then return nil end
    conditionId = tostring(conditionId or ""):match("^[%w_%-]+$") or ""
    local conditionDuration = conditionId ~= ""
        and ((not durationCode or durationCode == "") and "manual" or AREA_CONDITION_DURATION_LOAD[durationCode])
        or "manual"
    if conditionId ~= "" and not conditionDuration then return nil end
    conditionTurns = math.max(0, math.min(99, math.floor(tonumber(conditionTurns) or 0)))
    conditionSaveAbility = AREA_ABILITY_LOAD[conditionSaveAbility or ""]
    conditionSaveDC = math.max(0, math.min(99, math.floor(tonumber(conditionSaveDC) or 0)))
    conditionApplySaveAbility = AREA_ABILITY_LOAD[conditionApplySaveAbility or ""]
    conditionApplySaveDC = math.max(0, math.min(99, math.floor(tonumber(conditionApplySaveDC) or 0)))
    if conditionDuration == "rounds" and conditionTurns <= 0 then return nil end
    if conditionDuration == "save_at_turn_end" and (not conditionSaveAbility or conditionSaveDC <= 0) then return nil end
    return {
        id = id,
        mode = mode,
        ability = LoadAreaField(ability),
        dc = math.max(0, math.min(99, math.floor(tonumber(dc) or 0))),
        success = success == "H" and "half" or "none",
        attackTotal = math.max(-999, math.min(999, math.floor(tonumber(attackTotal) or 0))),
        critical = critical == "C" and "critical" or critical == "F" and "fumble" or "normal",
        auraId = math.max(0, math.floor(tonumber(auraId) or 0)),
        label = LoadAreaField(label):sub(1, 80),
        components = components,
        conditionId = conditionId,
        conditionDuration = conditionDuration,
        conditionTurns = conditionTurns,
        conditionSaveAbility = conditionSaveAbility,
        conditionSaveDC = conditionSaveDC,
        conditionPersist = conditionPersist == "P",
        sourceGuid = LoadAreaField(sourceGuid):sub(1, 64),
        sourceName = LoadAreaField(sourceName):sub(1, 48),
        conditionApplySaveAbility = conditionApplySaveAbility,
        conditionApplySaveDC = conditionApplySaveDC,
    }
end

function HarfordSync.SendAreaRequest(prefix, target, request)
    local payload = HarfordSync.SerializeAreaRequest(request)
    if not payload then return false, "Peticion de area invalida o demasiado grande" end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SerializeAreaResult(result)
    result = result or {}
    local id = tostring(result.id or ""):match("^[%w%._%-]+$")
    local status = tostring(result.status or "invalid"):match("^[%a_]+$")
    if not id or #id > 40 or not status or #status > 16 then return nil end
    local applied = math.max(0, math.min(10000, math.floor(tonumber(result.applied) or 0)))
    local label = AreaField(tostring(result.label or ""):sub(1, 100))
    local payload = table.concat({ "DNDAREARES", id, status, applied, label }, "|")
    return #payload <= 240 and payload or nil
end

function HarfordSync.DeserializeAreaResult(message)
    local opcode, id, status, applied, label = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDAREARES" or not id or not id:match("^[%w%._%-]+$") or #id > 40 then return nil end
    if not status or not status:match("^[%a_]+$") or #status > 16 then return nil end
    return { id = id, status = status, applied = math.max(0, math.floor(tonumber(applied) or 0)), label = LoadAreaField(label):sub(1, 100) }
end

function HarfordSync.SendAreaResult(prefix, target, result)
    local payload = HarfordSync.SerializeAreaResult(result)
    if not payload then return false, "Resultado de area invalido" end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

-- Peticion efimera de posicion para auto-marcar areas. La geometria vive en
-- HarfordDnDArea; por red solo viaja la posicion del jugador que responde.
function HarfordSync.SerializeAreaPositionRequest(id)
    id = tostring(id or ""):match("^[%w%._%-]+$")
    if not id or #id > 40 then return nil end
    return "DNDAREAPOSREQ|" .. id
end

function HarfordSync.DeserializeAreaPositionRequest(message)
    local opcode, id = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDAREAPOSREQ" or not id or not id:match("^[%w%._%-]+$") or #id > 40 then
        return nil
    end
    return id
end

function HarfordSync.SendAreaPositionRequest(prefix, channel, id)
    local payload = HarfordSync.SerializeAreaPositionRequest(id)
    if not payload then return false, "Peticion de posicion invalida" end
    return HarfordSync.Send(prefix, payload, channel)
end

function HarfordSync.SerializeAreaPositionResponse(data)
    data = data or {}
    local id = tostring(data.id or ""):match("^[%w%._%-]+$")
    if not id or #id > 40 then return nil end
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y or not z then return nil end
    local guid = AreaField(tostring(data.guid or ""):sub(1, 64))
    local name = AreaField(tostring(data.name or ""):sub(1, 64))
    local contextId = AreaField(tostring(data.contextId or ""):sub(1, 32))
    return table.concat({
        "DNDAREAPOSRES", id, guid, name,
        string.format("%.4f", x), string.format("%.4f", y), string.format("%.4f", z),
        contextId,
    }, "|")
end

function HarfordSync.DeserializeAreaPositionResponse(message)
    local opcode, id, guid, name, x, y, z, contextId = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDAREAPOSRES" or not id or not id:match("^[%w%._%-]+$") or #id > 40 then
        return nil
    end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return nil end
    return {
        id = id,
        guid = LoadAreaField(guid):sub(1, 64),
        name = LoadAreaField(name):sub(1, 64),
        x = x, y = y, z = z,
        contextId = LoadAreaField(contextId):sub(1, 32),
    }
end

function HarfordSync.SendAreaPositionResponse(prefix, target, data)
    local payload = HarfordSync.SerializeAreaPositionResponse(data)
    if not payload then return false, "Respuesta de posicion invalida" end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

-- Condiciones: solo se transmiten IDs conocidos y metadatos mecanicos acotados.
-- Las definiciones/efectos viven en HarfordDnDConditions y nunca viajan por red.
local function ConditionField(value, maxLen)
    value = tostring(value or ""):gsub("[\r\n]", " "):sub(1, maxLen or 48)
    return (value:gsub("%%", "%%25"):gsub("|", "%%7C"))  -- parentesis: gsub devuelve 2 valores
end

local function LoadConditionField(value, maxLen)
    value = tostring(value or ""):gsub("%%7C", "|"):gsub("%%25", "%%")
    return value:sub(1, maxLen or 48)
end

local function ConditionId(value)
    value = tostring(value or "")
    return #value <= 40 and value:match("^[%w_%-]+$") or nil
end

local function ConditionOperation(value)
    return value == "apply" and "A" or value == "remove" and "R" or nil
end

local function LoadConditionOperation(value)
    return value == "A" and "apply" or value == "R" and "remove" or nil
end


local function ConditionVars(vars)
    if type(vars) ~= "table" then return "" end
    local partes = {}
    for nombre, valor in pairs(vars) do
        nombre = tostring(nombre):match("^[%w_]+$")
        valor = tonumber(valor)
        if nombre and valor and #nombre <= 16 then
            partes[#partes + 1] = nombre .. "=" .. tostring(math.floor(valor))
        end
    end
    table.sort(partes)   -- orden estable: el mismo estado produce el mismo mensaje
    local out = table.concat(partes, ",")
    return #out <= 80 and out or ""
end

local function LoadConditionVars(text)
    text = tostring(text or "")
    if text == "" then return nil end
    local out, n = {}, 0
    for nombre, valor in text:gmatch("([%w_]+)=(-?%d+)") do
        out[nombre] = tonumber(valor)
        n = n + 1
    end
    return n > 0 and out or nil
end

function HarfordSync.SerializeConditionRequest(data)
    data = data or {}
    local id = tostring(data.id or ""):match("^[%w%._%-]+$")
    local op, conditionId = ConditionOperation(data.op), ConditionId(data.conditionId)
    if not id or #id > 40 or not op or not conditionId then return nil end
    local payload = table.concat({
        "DNDCOND", id, op, conditionId,
        ConditionField(data.sourceGuid, 64), ConditionField(data.sourceName, 48),
        ConditionField(data.duration or "manual", 24),
        math.max(0, math.min(99, math.floor(tonumber(data.turns) or 0))),
        ConditionField(data.saveAbility, 20),
        math.max(0, math.min(99, math.floor(tonumber(data.saveDC) or 0))),
        data.persist == true and "P" or "",
        ConditionVars(data.vars),
    }, "|")
    return #payload <= 240 and payload or nil
end

function HarfordSync.DeserializeConditionRequest(message)
    local opcode, id, op, conditionId, sourceGuid, sourceName, duration, turns, saveAbility, saveDC, persist, vars =
        strsplit("|", tostring(message or ""))
    if opcode ~= "DNDCOND" or not id or not id:match("^[%w%._%-]+$") or #id > 40 then return nil end
    op, conditionId = LoadConditionOperation(op), ConditionId(conditionId)
    if not op or not conditionId then return nil end
    return {
        id = id, op = op, conditionId = conditionId,
        sourceGuid = LoadConditionField(sourceGuid, 64), sourceName = LoadConditionField(sourceName, 48),
        duration = LoadConditionField(duration, 24), turns = math.max(0, math.min(99, math.floor(tonumber(turns) or 0))),
        saveAbility = LoadConditionField(saveAbility, 20), saveDC = math.max(0, math.min(99, math.floor(tonumber(saveDC) or 0))),
        persist = persist == "P",
        vars = LoadConditionVars(vars),
    }
end

function HarfordSync.SendConditionRequest(prefix, target, data)
    local payload = HarfordSync.SerializeConditionRequest(data)
    if not payload then return false, "Peticion de condicion invalida" end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SerializeConditionResult(data)
    data = data or {}
    local id = tostring(data.id or ""):match("^[%w%._%-]+$")
    local conditionId = ConditionId(data.conditionId)
    local status = tostring(data.status or "error"):match("^[%a_]+$")
    if not id or #id > 40 or not conditionId or not status or #status > 16 then return nil end
    return table.concat({ "DNDCONDRES", id, conditionId, status }, "|")
end

function HarfordSync.DeserializeConditionResult(message)
    local opcode, id, conditionId, status = strsplit("|", tostring(message or ""))
    if opcode ~= "DNDCONDRES" or not id or not id:match("^[%w%._%-]+$") or #id > 40 then return nil end
    conditionId, status = ConditionId(conditionId), tostring(status or ""):match("^[%a_]+$")
    if not conditionId or not status or #status > 16 then return nil end
    return { id = id, conditionId = conditionId, status = status }
end

function HarfordSync.SendConditionResult(prefix, target, data)
    local payload = HarfordSync.SerializeConditionResult(data)
    if not payload then return false, "Resultado de condicion invalido" end
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SerializeConditionState(data)
    data = data or {}
    local op, conditionId = ConditionOperation(data.op), ConditionId(data.conditionId)
    if not op or not conditionId then return nil end
    local payload = table.concat({
        "DNDCONDSTATE", op, conditionId,
        ConditionField(data.targetGuid, 64), ConditionField(data.targetName, 48),
        ConditionField(data.sourceGuid, 64), ConditionField(data.sourceName, 48),
        ConditionField(data.duration or "manual", 24),
        math.max(0, math.min(99, math.floor(tonumber(data.turns) or 0))),
        ConditionField(data.saveAbility, 20),
        math.max(0, math.min(99, math.floor(tonumber(data.saveDC) or 0))),
    }, "|")
    return #payload <= 240 and payload or nil
end

function HarfordSync.DeserializeConditionState(message)
    local opcode, op, conditionId, targetGuid, targetName, sourceGuid, sourceName, duration, turns, saveAbility, saveDC =
        strsplit("|", tostring(message or ""))
    if opcode ~= "DNDCONDSTATE" then return nil end
    op, conditionId = LoadConditionOperation(op), ConditionId(conditionId)
    if not op or not conditionId then return nil end
    return {
        op = op, conditionId = conditionId,
        targetGuid = LoadConditionField(targetGuid, 64), targetName = LoadConditionField(targetName, 48),
        sourceGuid = LoadConditionField(sourceGuid, 64), sourceName = LoadConditionField(sourceName, 48),
        duration = LoadConditionField(duration, 24), turns = math.max(0, math.min(99, math.floor(tonumber(turns) or 0))),
        saveAbility = LoadConditionField(saveAbility, 20), saveDC = math.max(0, math.min(99, math.floor(tonumber(saveDC) or 0))),
    }
end

function HarfordSync.SendConditionState(prefix, channel, data)
    local payload = HarfordSync.SerializeConditionState(data)
    if not payload then return false, "Estado de condicion invalido" end
    return HarfordSync.Send(prefix, payload, channel)
end

function HarfordSync.SendResourceAdjust(prefix, resourceKey, delta, target)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceAdjustMessage(resourceKey, delta)
    if not payload then
        return false, "Ajuste de recurso inválido"
    end

    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SendResourceRequest(prefix, requesterName, target)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceRequestMessage(requesterName)
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SendResourceResponse(prefix, profileName, resourceTable, target, resourceKeys)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.SendResourceConfig(prefix, profileName, resourceTable, target, resourceKeys)
    if not target or target == "" then
        return false, "Target inválido"
    end

    local payload = HarfordSync.SerializeResourceConfigMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.Send(prefix, payload, "WHISPER", target)
end

function HarfordSync.ReceiveResourceConfig(message)
    return HarfordSync.DeserializeResourceConfigMessage(message)
end

HarfordSync._resourceBroadcastState = HarfordSync._resourceBroadcastState or {
    pending = false,
    lastPayload = nil,
}

function HarfordSync.SendResourceBroadcast(prefix, profileName, resourceTable, resourceKeys, channel)
    local ch = channel or HarfordSync.BestChannel()
    if ch ~= "RAID" and ch ~= "PARTY" then
        return false, "Sin canal de grupo"
    end

    local payload = HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)
    return HarfordSync.Send(prefix, payload, ch)
end

function HarfordSync.ScheduleResourceBroadcast(prefix, profileNameProvider, resourceTableProvider, resourceKeys, channelProvider)
    HarfordSync._resourceBroadcastState = HarfordSync._resourceBroadcastState or {
        pending = false,
        lastPayload = nil,
    }

    local state = HarfordSync._resourceBroadcastState

    local initialChannel = channelProvider and channelProvider() or HarfordSync.BestChannel()
    if initialChannel ~= "RAID" and initialChannel ~= "PARTY" then
        return false, "Sin canal de grupo"
    end

    if state.pending then
        return true
    end

    state.pending = true

    C_Timer.After(0.20, function()
        state.pending = false

        local finalChannel = channelProvider and channelProvider() or HarfordSync.BestChannel()
        if finalChannel ~= "RAID" and finalChannel ~= "PARTY" then
            return
        end

        local profileName = profileNameProvider and profileNameProvider() or "default"
        local resourceTable = resourceTableProvider and resourceTableProvider() or {}
        local payload = HarfordSync.SerializeResourceResponseMessage(profileName, resourceTable, resourceKeys)

        if payload == state.lastPayload then
            return
        end

        state.lastPayload = payload
        HarfordSync.Send(prefix, payload, finalChannel)
    end)

    return true
end

function HarfordSync.SerializeTaggedLootMessage(guid, lootTable)
    local encoded = {}
    for i = 1, #(lootTable or {}) do
        local row = lootTable[i]
        encoded[#encoded + 1] = table.concat({
            row[1] or 0,
            row[2] or 0,
            row[3] and 1 or 0
        }, ":")
    end
    return "LOOT|" .. tostring(guid or "") .. "|" .. table.concat(encoded, ",")
end

function HarfordSync.DeserializeTaggedLootMessage(payload)
    if type(payload) ~= "string" or payload == "" then
        return nil, nil
    end

    local msgType, guid, rawRows = strsplit("|", payload)
    if msgType ~= "LOOT" or not guid or guid == "" then
        return nil, nil
    end

    local lootTable = {}
    if rawRows and rawRows ~= "" then
        for token in string.gmatch(rawRows, "[^,]+") do
            local itemId, quantity, available = strsplit(":", token)
            lootTable[#lootTable + 1] = {
                tonumber(itemId) or 0,
                tonumber(quantity) or 0,
                tonumber(available) == 1
            }
        end
    end

    return guid, lootTable
end

function HarfordSync.SendTaggedLoot(prefix, guid, lootTable, channel, target)
    local ch = channel or (HarfordSync.BestChannel and HarfordSync.BestChannel())
    if not ch then
        return false, "Sin canal disponible"
    end

    local payload = HarfordSync.SerializeTaggedLootMessage(guid, lootTable)

    if #payload <= HarfordSync.MAX_RESOURCE_MESSAGE_BYTES then
        if HarfordSync.Send then
            return HarfordSync.Send(prefix, payload, ch, target)
        elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
            local ok, err = pcall(C_ChatInfo.SendAddonMessage, prefix, payload, ch, target)
            if not ok then return false, err end
        elseif SendAddonMessage then
            local ok, err = pcall(SendAddonMessage, prefix, payload, ch, target)
            if not ok then return false, err end
        else
            return false, "SendAddonMessage no disponible"
        end
        return true
    end

    local escaped = EscapeProgressionText(payload)
    local total = math.max(1, math.ceil(#escaped / CLASS_CHUNK_BYTES))
    if total > 80 then
        return false, "Loot resuelto demasiado grande para compartir"
    end

    local transferId = tostring((GetServerTime and GetServerTime()) or time() or 0) .. tostring(math.random(1000, 9999))
    for i = 1, total do
        local chunk = escaped:sub(((i - 1) * CLASS_CHUNK_BYTES) + 1, i * CLASS_CHUNK_BYTES)
        local ok, err = HarfordSync.Send(prefix, table.concat({ "LOOTC", transferId, tostring(i), tostring(total), chunk }, "|"), ch, target)
        if not ok then return false, err end
    end
    return true
end

function HarfordSync.ReceiveTaggedLootChunk(message, sender)
    local opcode, transferId, indexRaw, totalRaw, chunk = tostring(message or ""):match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if opcode ~= "LOOTC" or not transferId then
        return nil, nil
    end

    local index = tonumber(indexRaw)
    local total = tonumber(totalRaw)
    if not index or not total or index < 1 or index > total or total > 80 then
        return nil, nil
    end

    local key = tostring(sender or "") .. ":" .. transferId
    PruneChunkBuffers(taggedLootChunkBuffers)
    local buffer = taggedLootChunkBuffers[key]
    if not buffer or buffer.total ~= total then
        buffer = { total = total, received = 0, chunks = {}, createdAt = Now() }
        taggedLootChunkBuffers[key] = buffer
    end

    if not buffer.chunks[index] then
        buffer.chunks[index] = chunk or ""
        buffer.received = buffer.received + 1
    end
    if buffer.received < total then return nil, nil end

    local parts = {}
    for i = 1, total do
        if buffer.chunks[i] == nil then return nil, nil end
        parts[i] = buffer.chunks[i]
    end
    taggedLootChunkBuffers[key] = nil

    return HarfordSync.DeserializeTaggedLootMessage(UnescapeProgressionText(table.concat(parts)))
end

HarfordSync.LootKeys = HarfordSync.LootKeys or {
    registry = "registry",
    global = "global",
}

function HarfordSync.SerializeLootRegistryTable(tbl)
    local out = {}
    for creatureId, entries in pairs(tbl or {}) do
        local rows = {}
        for i = 1, #entries do
            local e = entries[i]
            rows[#rows + 1] = table.concat({
                e[1] or 0,
                e[2] or 0,
                e[3] or 1,
                e[4] or 1
            }, ":")
        end
        out[#out + 1] = tostring(creatureId) .. "=" .. table.concat(rows, ",")
    end
    return table.concat(out, ";")
end

function HarfordSync.DeserializeLootRegistryTable(raw)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    for block in string.gmatch(raw, "[^;]+") do
        local eqPos = string.find(block, "=", 1, true)
        if eqPos then
            local creatureId = string.sub(block, 1, eqPos - 1)
            local rows = string.sub(block, eqPos + 1)
            local entries = {}

            if rows and rows ~= "" then
                for token in string.gmatch(rows, "[^,]+") do
                    local p1, p2, p3, p4 = strsplit(":", token)
                    entries[#entries + 1] = {
                        tonumber(p1) or 0,
                        tonumber(p2) or 0,
                        tonumber(p3) or 1,
                        tonumber(p4) or 1,
                    }
                end
            end

            if creatureId and creatureId ~= "" then
                tbl[creatureId] = entries
            end
        end
    end

    return tbl
end

function HarfordSync.SerializeLootGlobalTable(tbl)
    local out = {}
    for i = 1, #(tbl or {}) do
        local e = tbl[i]
        out[#out + 1] = table.concat({
            e[1] or 0,
            e[2] or 0,
            e[3] or 1,
            e[4] or 1
        }, ":")
    end
    return table.concat(out, ",")
end

function HarfordSync.DeserializeLootGlobalTable(raw)
    local tbl = {}
    if type(raw) ~= "string" or raw == "" then
        return tbl
    end

    for token in string.gmatch(raw, "[^,]+") do
        local p1, p2, p3, p4 = strsplit(":", token)
        tbl[#tbl + 1] = {
            tonumber(p1) or 0,
            tonumber(p2) or 0,
            tonumber(p3) or 1,
            tonumber(p4) or 1,
        }
    end

    return tbl
end

function HarfordSync.EnsureLootStore(store)
    if type(store) ~= "table" then
        store = {}
    end
    if type(store.registry) ~= "string" then
        store.registry = ""
    end
    if type(store.global) ~= "string" then
        store.global = ""
    end
    store.values = nil
    return store
end

function HarfordSync.LoadLootConfigFromStore(store)
    store = HarfordSync.EnsureLootStore(store)
    local regRaw = store.registry or ""
    local globalRaw = store.global or ""
    return store, regRaw, globalRaw
end

function HarfordSync.SaveLootConfigToStore(store, regRaw, globalRaw)
    store = HarfordSync.EnsureLootStore(store)
    store.registry = tostring(regRaw or "")
    store.global = tostring(globalRaw or "")
    return store
end

function HarfordSync.SerializeLootConfigMessage(regRaw, globalRaw)
    return "LOOTCFG|" .. tostring(regRaw or "") .. "|" .. tostring(globalRaw or "")
end

function HarfordSync.DeserializeLootConfigMessage(message)
    if type(message) ~= "string" or message == "" then
        return nil, nil
    end

    local a, b, c = strsplit("|", message)
    if a ~= "LOOTCFG" then
        return nil, nil
    end

    return b or "", c or ""
end

function HarfordSync.SendLootConfig(prefix, regRaw, globalRaw, channel, target)
    local ch = channel or (HarfordSync.BestChannel and HarfordSync.BestChannel())
    if not ch then
        return false, "Sin canal disponible"
    end

    local payload = HarfordSync.SerializeLootConfigMessage(regRaw, globalRaw)
    if #payload <= HarfordSync.MAX_RESOURCE_MESSAGE_BYTES then
        if HarfordSync.Send then
            return HarfordSync.Send(prefix, payload, ch, target)
        elseif C_ChatInfo and C_ChatInfo.SendAddonMessage then
            local ok, err = pcall(C_ChatInfo.SendAddonMessage, prefix, payload, ch, target)
            if not ok then return false, err end
        elseif SendAddonMessage then
            local ok, err = pcall(SendAddonMessage, prefix, payload, ch, target)
            if not ok then return false, err end
        else
            return false, "SendAddonMessage no disponible"
        end
        return true
    end

    local escaped = EscapeProgressionText(payload)
    local total = math.max(1, math.ceil(#escaped / CLASS_CHUNK_BYTES))
    if total > 80 then
        return false, "Configuracion de loot demasiado grande para compartir"
    end

    local transferId = tostring((GetServerTime and GetServerTime()) or time() or 0) .. tostring(math.random(1000, 9999))
    for i = 1, total do
        local chunk = escaped:sub(((i - 1) * CLASS_CHUNK_BYTES) + 1, i * CLASS_CHUNK_BYTES)
        local ok, err = HarfordSync.Send(prefix, table.concat({ "LOOTCFGC", transferId, tostring(i), tostring(total), chunk }, "|"), ch, target)
        if not ok then return false, err end
    end
    return true
end

function HarfordSync.ReceiveLootConfigChunk(message, sender)
    local opcode, transferId, indexRaw, totalRaw, chunk = tostring(message or ""):match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if opcode ~= "LOOTCFGC" or not transferId then
        return nil
    end

    local index = tonumber(indexRaw)
    local total = tonumber(totalRaw)
    if not index or not total or index < 1 or index > total or total > 80 then
        return nil
    end

    local key = tostring(sender or "") .. ":" .. transferId
    PruneChunkBuffers(lootConfigChunkBuffers)
    local buffer = lootConfigChunkBuffers[key]
    if not buffer or buffer.total ~= total then
        buffer = { total = total, received = 0, chunks = {}, createdAt = Now() }
        lootConfigChunkBuffers[key] = buffer
    end

    if not buffer.chunks[index] then
        buffer.chunks[index] = chunk or ""
        buffer.received = buffer.received + 1
    end
    if buffer.received < total then return nil end

    local parts = {}
    for i = 1, total do
        if buffer.chunks[i] == nil then return nil end
        parts[i] = buffer.chunks[i]
    end
    lootConfigChunkBuffers[key] = nil

    return UnescapeProgressionText(table.concat(parts))
end

function HarfordSync.LoadLootConfigTables(store, fallbackRegistry, fallbackGlobal)
    store = HarfordSync.EnsureLootStore(store)

    local regRaw = store.registry or ""
    local globalRaw = store.global or ""

    local registry = fallbackRegistry or {}
    local global = fallbackGlobal or {}

    if regRaw ~= "" then
        registry = HarfordSync.DeserializeLootRegistryTable(regRaw)
    end

    if globalRaw ~= "" then
        global = HarfordSync.DeserializeLootGlobalTable(globalRaw)
    end

    return store, registry, global
end

function HarfordSync.SaveLootConfigTables(store, registry, global)
    store = HarfordSync.EnsureLootStore(store)

    local regRaw = HarfordSync.SerializeLootRegistryTable(registry)
    local globalRaw = HarfordSync.SerializeLootGlobalTable(global)

    store.registry = tostring(regRaw or "")
    store.global = tostring(globalRaw or "")

    return store
end

function HarfordSync.SendLootConfigTables(prefix, registry, global, channel, target)
    local regRaw = HarfordSync.SerializeLootRegistryTable(registry)
    local globalRaw = HarfordSync.SerializeLootGlobalTable(global)
    return HarfordSync.SendLootConfig(prefix, regRaw, globalRaw, channel, target)
end

-- Compat namespaces to keep clearer boundaries without romper APIs existentes.
HarfordSync.Generic = HarfordSync.Generic or {
    RegisterPrefix = HarfordSync.RegisterPrefix,
    Send = HarfordSync.Send,
    BestChannel = HarfordSync.BestChannel,
    CopyTableShallow = HarfordSync.CopyTableShallow,
    EnsureStore = HarfordSync.EnsureStore,
    LoadStoreRuntime = HarfordSync.LoadStoreRuntime,
    GetValue = HarfordSync.GetValue,
    SetValue = HarfordSync.SetValue,
    SerializeKeyValueTable = HarfordSync.SerializeKeyValueTable,
    DeserializeKeyValueTable = HarfordSync.DeserializeKeyValueTable,
}

HarfordSync.DnD = HarfordSync.DnD or {
    ProfileKeys = HarfordSync.ProfileKeys,
    SendDnDProfile = HarfordSync.SendDnDProfile,
    ReceiveDnDProfile = HarfordSync.ReceiveDnDProfile,
    BuildActiveResourcePayloadFromStore = HarfordSync.BuildActiveResourcePayloadFromStore,
    BuildActiveResourcePayloadFromTable = HarfordSync.BuildActiveResourcePayloadFromTable,
    SendResourceRequest = HarfordSync.SendResourceRequest,
    SendResourceResponse = HarfordSync.SendResourceResponse,
    SendResourceConfig = HarfordSync.SendResourceConfig,
    SendResourceAdjust = HarfordSync.SendResourceAdjust,
    DeserializeResourceAdjustMessage = HarfordSync.DeserializeResourceAdjustMessage,
    ReceiveResourceMessage = HarfordSync.ReceiveResourceMessage,
    ReceiveResourceConfig = HarfordSync.ReceiveResourceConfig,
    ScheduleResourceBroadcast = HarfordSync.ScheduleResourceBroadcast,
    SendDnDProfFlags         = HarfordSync.SendDnDProfFlags,
    DeserializeDnDProfFlags  = HarfordSync.DeserializeDnDProfFlags,
    SendDnDClassProgression  = HarfordSync.SendDnDClassProgression,
    DeserializeDnDClassProgression = HarfordSync.DeserializeDnDClassProgression,
    ReceiveDnDClassProgressionChunk = HarfordSync.ReceiveDnDClassProgressionChunk,
    SendDnDEquipment = HarfordSync.SendDnDEquipment,
    DeserializeDnDEquipment = HarfordSync.DeserializeDnDEquipment,
    ReceiveDnDEquipmentChunk = HarfordSync.ReceiveDnDEquipmentChunk,
}

HarfordSync.Loot = HarfordSync.Loot or {
    SerializeTaggedLootMessage = HarfordSync.SerializeTaggedLootMessage,
    DeserializeTaggedLootMessage = HarfordSync.DeserializeTaggedLootMessage,
    SendTaggedLoot = HarfordSync.SendTaggedLoot,
    ReceiveTaggedLootChunk = HarfordSync.ReceiveTaggedLootChunk,
    SerializeLootRegistryTable = HarfordSync.SerializeLootRegistryTable,
    DeserializeLootRegistryTable = HarfordSync.DeserializeLootRegistryTable,
    SerializeLootGlobalTable = HarfordSync.SerializeLootGlobalTable,
    DeserializeLootGlobalTable = HarfordSync.DeserializeLootGlobalTable,
    EnsureLootStore = HarfordSync.EnsureLootStore,
    LoadLootConfigTables = HarfordSync.LoadLootConfigTables,
    SaveLootConfigTables = HarfordSync.SaveLootConfigTables,
    SendLootConfigTables = HarfordSync.SendLootConfigTables,
    ReceiveLootConfigChunk = HarfordSync.ReceiveLootConfigChunk,
}
