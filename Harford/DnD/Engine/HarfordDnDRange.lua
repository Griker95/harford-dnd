-- Distancias y alcances de Harford. Epsilon mide el mundo en yardas; las reglas
-- y el compendio se presentan en metros/pies. Esta es la unica frontera que
-- convierte entre ambos y que consulta `.distance`.

HarfordDnDRange = HarfordDnDRange or {}

local API = HarfordDnDRange

API.METROS_POR_YARDA = 0.9144
API.METROS_POR_PIE = 0.3048

local function Numero(text)
    text = tostring(text or ""):gsub(",", ".")
    return tonumber(text)
end

local function Texto(text)
    text = tostring(text or ""):lower()
    -- Las respuestas de AddonCommands pueden conservar colores o texturas de chat.
    -- Si un color se intercala antes del numero, un parser laxo puede leer un cero
    -- de su codigo hexadecimal y convertir un objetivo lejano en "contacto".
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|t.-|t", "")
    text = text:gsub("\194\160", " ") -- espacio no separable UTF-8
    text = text:gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u")
    return text
end

local function Metros(valor, unidad)
    valor = Numero(valor)
    if not valor or valor < 0 then return nil end
    unidad = Texto(unidad)
    if unidad:find("yard", 1, true) or unidad:find("yd", 1, true) then
        return valor * API.METROS_POR_YARDA
    end
    if unidad:find("pie", 1, true) or unidad:find("feet", 1, true) or unidad:find("foot", 1, true)
        or unidad:find("ft", 1, true) then
        return valor * API.METROS_POR_PIE
    end
    return valor
end

function API.FormatMeters(value)
    value = tonumber(value)
    if not value then return "? m" end
    return string.format("%.1f m", value):gsub("%.", ",")
end

-- El mapa separa zonas que pueden reutilizar coordenadas X/Y. La fase no forma
-- parte de las areas de Harford: el grupo juega siempre en el mismo contexto.
function API.BuildPositionContext(mapId)
    mapId = tostring(mapId or "")
    return mapId
end

-- `.distance` devuelve en Epsilon ambas distancias en yardas: hitbox y exacta,
-- cada una en 3D y 2D. Contacto usa hitbox; todo alcance numerico usa exacta.
-- Se conservan los formatos genericos para no romper compatibilidad con respuestas antiguas.
function API.ParseDistanceDetails(messages)
    if type(messages) == "string" then messages = { messages } end
    if type(messages) ~= "table" then return nil, "Respuesta de distancia vacia" end
    for _, raw in ipairs(messages) do
        local text = Texto(raw)
        local hitbox3d = text:match("hitbox%s+distance.-is%s+([%d]+[,.]?[%d]*)%s+in%s+3d")
            or text:match("hitbox%s+distance.-%s([%d]+[,.]?[%d]*)%s+in%s+3d")
        local exact3d = text:match("exact%s+distance.-is%s+([%d]+[,.]?[%d]*)%s+in%s+3d")
            or text:match("exact%s+distance.-%s([%d]+[,.]?[%d]*)%s+in%s+3d")
        if hitbox3d or exact3d then
            return {
                hitboxMeters = hitbox3d and Metros(hitbox3d, "yardas") or nil,
                exactMeters = exact3d and Metros(exact3d, "yardas") or nil,
                raw = raw,
                source = hitbox3d and "hitbox_3d" or "exact_3d",
            }
        end
        local value, unit = text:match("([%d]+[,.]?[%d]*)%s*(yardas?)")
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(yards?)") end
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(yds?%.?)") end
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(metros?)") end
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(meters?)") end
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(pies)") end
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(feet)") end
        if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(ft%.?)") end
        if value then
            local meters = Metros(value, unit)
            if meters then return { hitboxMeters = meters, exactMeters = meters, raw = raw, source = "unit" } end
        end
    end
    return nil, "Epsilon no devolvio una distancia reconocible"
end

-- Compatibilidad de consumidores antiguos: devuelve hitbox si esta presente.
function API.ParseDistanceReply(messages)
    local details, err = API.ParseDistanceDetails(messages)
    if not details then return nil, err end
    return details.hitboxMeters or details.exactMeters, nil, details.raw, details.source
end

-- Interpreta el alcance de un conjuro sin modificar sus datos. `normalMeters` es
-- nil para Personal, ilimitado o texto no mecanizable; esos casos no se bloquean.
function API.ParseSpellRange(rangeText)
    local text = Texto(rangeText)
    if text == "" then return nil end
    if text:find("personal", 1, true) or text:find("uno mismo", 1, true) then
        return { kind = "self", label = "Personal" }
    end
    if text:find("toque", 1, true) then
        return { kind = "touch", normalMeters = 0, requiresContact = true, label = "Toque" }
    end
    if text:find("ilimitado", 1, true) or text:find("ilimitada", 1, true)
        or text:find("especial", 1, true) then
        return { kind = "unlimited", label = tostring(rangeText or "") }
    end
    local value, unit = text:match("([%d]+[,.]?[%d]*)%s*(metros?)")
    if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(meters?)") end
    if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(pies)") end
    if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(feet)") end
    if not value then value, unit = text:match("([%d]+[,.]?[%d]*)%s*(ft%.?)") end
    local meters = value and Metros(value, unit) or nil
    if not meters then return nil end
    return { kind = "distance", normalMeters = meters, label = tostring(rangeText or "") }
end

function API.CheckDistance(distanceMeters, range)
    if type(range) ~= "table" or not tonumber(range.normalMeters) then
        return { ok = true, meters = distanceMeters, unchecked = true }
    end
    distanceMeters = tonumber(distanceMeters)
    if not distanceMeters then return { ok = false, message = "No se pudo medir la distancia al objetivo." } end
    local normal = tonumber(range.normalMeters)
    local long = tonumber(range.longMeters) or normal
    if range.requiresContact then
        -- `.distance` responde cero al tocar el hitbox. La tolerancia minima solo
        -- protege de residuos de coma flotante; no crea un alcance de 1,5 metros.
        if distanceMeters <= 0.01 then
            return { ok = true, meters = distanceMeters, range = range }
        end
        return {
            ok = false,
            outOfRange = true,
            meters = distanceMeters,
            range = range,
            message = "Debes estar en contacto con el objetivo para atacar cuerpo a cuerpo.",
        }
    end
    if distanceMeters <= normal + 0.01 then
        return { ok = true, meters = distanceMeters, range = range }
    end
    if distanceMeters <= long + 0.01 then
        return { ok = true, meters = distanceMeters, range = range, disadvantage = true }
    end
    return {
        ok = false,
        outOfRange = true,
        meters = distanceMeters,
        range = range,
        message = string.format("Objetivo fuera de alcance (%s; maximo %s).",
            API.FormatMeters(distanceMeters), API.FormatMeters(long)),
    }
end

function API.NotifyOutOfRange()
    -- Los globales de error dependen del idioma del cliente. Harford muestra sus
    -- propias reglas en espanol, asi que este aviso debe conservar ese idioma.
    local text = "Objetivo fuera de alcance."
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1, 53, UIERRORS_HOLD_TIME or 5)
    end
    if HarfordUISounds and HarfordUISounds.PlayOutOfRange then
        HarfordUISounds.PlayOutOfRange("SFX")
    end
end

-- Consulta atomica respecto al target: si este cambia mientras Epsilon responde, se descarta.
function API.RequestTargetDistance(callback, expectedGuid)
    if type(callback) ~= "function" then return false, "Falta callback" end
    if not (UnitExists and UnitExists("target")) then
        callback({ ok = false, message = "Necesitas un objetivo para medir el alcance." })
        return false, "Sin objetivo"
    end
    expectedGuid = expectedGuid or (UnitGUID and UnitGUID("target"))
    if not expectedGuid or expectedGuid == "" then
        callback({ ok = false, message = "No se pudo identificar el objetivo." })
        return false, "Sin GUID"
    end
    if not (HarfordEpsilonCommands and HarfordEpsilonCommands.Send) then
        callback({ ok = false, message = "Consulta de distancia no disponible." })
        return false, "Sin EpsilonCommands"
    end
    local sent, err = HarfordEpsilonCommands.Send("distance", {
        addonName = "Harford",
        forceEpsilon = true,
        showMessages = false,
        callback = function(success, messages)
            if not success then
                callback({ ok = false, message = "Epsilon no pudo medir la distancia.", messages = messages })
                return
            end
            local currentGuid = UnitGUID and UnitGUID("target") or nil
            if currentGuid ~= expectedGuid then
                callback({ ok = false, message = "El objetivo cambio mientras se media la distancia.", messages = messages })
                return
            end
            local details, parseErr = API.ParseDistanceDetails(messages)
            if not details then
                callback({ ok = false, message = parseErr or "No se pudo leer la distancia.", messages = messages })
                return
            end
            callback({ ok = true, meters = details.hitboxMeters or details.exactMeters,
                hitboxMeters = details.hitboxMeters, exactMeters = details.exactMeters,
                raw = details.raw, source = details.source, messages = messages, targetGuid = expectedGuid })
        end,
    })
    if not sent then return false, err end
    return true
end

function API.CheckTargetRange(range, callback, expectedGuid)
    return API.RequestTargetDistance(function(result)
        if not result.ok then callback(result); return end
        local meters = range and range.requiresContact and result.hitboxMeters
            or result.exactMeters or result.hitboxMeters
        if not meters then
            callback({ ok = false, message = "Epsilon no devolvio la distancia necesaria para este ataque.",
                messages = result.messages, raw = result.raw, targetGuid = result.targetGuid })
            return
        end
        local checked = API.CheckDistance(meters, range)
        checked.messages, checked.raw, checked.targetGuid = result.messages, result.raw, result.targetGuid
        checked.hitboxMeters, checked.exactMeters = result.hitboxMeters, result.exactMeters
        if checked.outOfRange then API.NotifyOutOfRange() end
        callback(checked)
    end, expectedGuid)
end
