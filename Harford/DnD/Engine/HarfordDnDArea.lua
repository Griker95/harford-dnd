-- Motor comun de ataques de area. El marcado manual sigue siendo la fuente segura.
-- Opcionalmente puede auto-marcar jugadores usando C_Epsilon.GetPosition() + geometria
-- simple X/Y. HarfordAdmin puede aportar la posicion del NPC origen mediante .npc info.

HarfordDnDArea = HarfordDnDArea or {}
local API = HarfordDnDArea

local PREFIX = "DND5EARC"
local MAX_TARGETS = 40
local REQUEST_TTL = 60
local RESPONSE_TIMEOUT = 8
local ROW_COUNT = 8
local ROW_HEIGHT = 25
local POSITION_RESPONSE_TIMEOUT = 4
local DEFAULT_MAX_Z = 5
local DEFAULT_CONE_ANGLE = 90
local DEFAULT_LINE_WIDTH = 5

API.S = API.S or {
    serial = 0,
    session = nil,
    processed = {},
    frame = nil,
}
local S = API.S
local npcPositionProvider

local function Now()
    return (GetTime and GetTime()) or (time and time()) or 0
end

local function Print(message)
    HarfordChat.Print(message)
end

local function CanonicalDamageType(value)
    value = tostring(value or "")
    if HarfordDamageMitigation and HarfordDamageMitigation.KeyFromTypeText then
        local key = HarfordDamageMitigation.KeyFromTypeText(value)
        if key then return key end
    end
    value = HarfordClassColors.StripAccents(value):lower():gsub("%s+", "")
    if HarfordDamageTypes and HarfordDamageTypes.Exists and HarfordDamageTypes.Exists(value) then
        return value
    end
    return nil
end

local function CanonicalAbility(value)
    value = HarfordClassColors.StripAccents(tostring(value or "")):lower()
        :gsub("^%s+", ""):gsub("%s+$", "")
    local aliases = {
        fue = "Fuerza", fuerza = "Fuerza",
        des = "Destreza", destreza = "Destreza",
        con = "Constitucion", cons = "Constitucion", constitucion = "Constitucion",
        int = "Inteligencia", inteligencia = "Inteligencia",
        sab = "Sabiduria", sabiduria = "Sabiduria",
        car = "Carisma", carisma = "Carisma",
    }
    return aliases[value]
end

local function CapturePlayerPosition()
    if not (C_Epsilon and C_Epsilon.GetPosition) then return nil, "C_Epsilon.GetPosition no disponible" end
    local ok, x, y, z, contextId = pcall(C_Epsilon.GetPosition)
    if not ok or not tonumber(x) or not tonumber(y) then
        return nil, "No se pudo leer la posicion"
    end
    -- z puede faltar en algunos builds de Epsilon (igual que UnitPosition); default 0 para no
    -- fallar el auto-marcado. Solo afecta a la separacion vertical (maxZ), no a la distancia 2D.
    return {
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z) or 0,
        contextId = tostring(contextId or ""),
    }
end

local function PositionDistance2DSq(a, b)
    local dx, dy = (a.x or 0) - (b.x or 0), (a.y or 0) - (b.y or 0)
    return dx * dx + dy * dy
end

local function SamePositionContext(a, b, maxZ)
    if not a or not b then return false end
    if tostring(a.contextId or "") ~= "" and tostring(b.contextId or "") ~= ""
        and tostring(a.contextId) ~= tostring(b.contextId) then
        return false
    end
    if maxZ and math.abs((a.z or 0) - (b.z or 0)) > maxZ then
        return false
    end
    return true
end

local function ParseAreaNumbers(text)
    local numbers = {}
    text = HarfordClassColors.StripAccents(tostring(text or "")):lower():gsub(",", ".")
    for raw in text:gmatch("(%d+%.?%d*)") do
        numbers[#numbers + 1] = tonumber(raw)
    end
    return numbers
end

-- UNIDADES. Las posiciones del cliente vienen en YARDAS (`C_Epsilon.GetPosition`, igual que
-- `UnitPosition`), pero el tamano del area se escribe en METROS -- o en PIES cuando el texto lo
-- dice, porque los conjuros del compendio conservan la unidad de su manual.
--
-- Sin convertir pasaban dos cosas: un "radio 9 m" cubria 9 yardas = 8,2 m, un 9% corto en TODAS
-- las areas; y un "cono de 30 pies" se leia como 30, casi cuatro veces su tamano real.
local YARDAS_POR_METRO = 1 / 0.9144
local YARDAS_POR_PIE = 1 / 3

local function FactorAYardas(texto)
    texto = HarfordClassColors.StripAccents(tostring(texto or "")):lower()
    if texto:find("%f[%a]pies?%f[%A]") or texto:find("%f[%a]ft%f[%A]") then
        return YARDAS_POR_PIE
    end
    return YARDAS_POR_METRO
end

local function AreaGeometry(def)
    local texto = def and def.sizeText
    local nums = ParseAreaNumbers(texto)
    local f = FactorAYardas(texto)
    -- Solo se convierten las DISTANCIAS. El segundo numero de un cono son grados de apertura, no
    -- una longitud: convertirlo abriria o cerraria el cono sin motivo.
    local function d(v) return v and (v * f) or nil end
    local shape = tostring(def and def.shape or "other")
    if shape == "sphere" then
        return { shape = "circle", radius = d(nums[1]) or 0, maxZ = DEFAULT_MAX_Z }
    elseif shape == "cone" then
        return { shape = "cone", range = d(nums[1]) or 0, angle = nums[2] or DEFAULT_CONE_ANGLE, maxZ = DEFAULT_MAX_Z }
    elseif shape == "line" then
        return { shape = "line", length = d(nums[1]) or 0, width = d(nums[2]) or DEFAULT_LINE_WIDTH, maxZ = DEFAULT_MAX_Z }
    elseif shape == "square" then
        return { shape = "square", size = d(nums[1]) or 0, maxZ = DEFAULT_MAX_Z }
    elseif shape == "rectangle" then
        return { shape = "rectangle", length = d(nums[1]) or 0,
                 width = d(nums[2]) or d(nums[1]) or 0, maxZ = DEFAULT_MAX_Z }
    end
    return nil
end

local function IsInCircle(player, center, radius, maxZ)
    if not SamePositionContext(player, center, maxZ) or radius <= 0 then return false end
    return PositionDistance2DSq(player, center) <= radius * radius
end

local function IsInCone(player, origin, aim, range, angle, maxZ)
    if not SamePositionContext(player, origin, maxZ) or not aim or range <= 0 then return false end
    local dirX, dirY = (aim.x or 0) - (origin.x or 0), (aim.y or 0) - (origin.y or 0)
    local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
    if dirLen <= 0 then return false end
    dirX, dirY = dirX / dirLen, dirY / dirLen
    local offX, offY = (player.x or 0) - (origin.x or 0), (player.y or 0) - (origin.y or 0)
    local distance = math.sqrt(offX * offX + offY * offY)
    if distance > range then return false end
    if distance <= 0 then return true end
    offX, offY = offX / distance, offY / distance
    return (dirX * offX + dirY * offY) >= math.cos(math.rad((tonumber(angle) or DEFAULT_CONE_ANGLE) / 2))
end

local function IsInLine(player, origin, aim, length, width, maxZ)
    if not SamePositionContext(player, origin, maxZ) or not aim or length <= 0 then return false end
    local dirX, dirY = (aim.x or 0) - (origin.x or 0), (aim.y or 0) - (origin.y or 0)
    local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
    if dirLen <= 0 then return false end
    dirX, dirY = dirX / dirLen, dirY / dirLen
    local offX, offY = (player.x or 0) - (origin.x or 0), (player.y or 0) - (origin.y or 0)
    local forward = offX * dirX + offY * dirY
    local sideways = math.abs(offX * dirY - offY * dirX)
    return forward >= 0 and forward <= length and sideways <= (width or DEFAULT_LINE_WIDTH) / 2
end

local function IsInSquare(player, center, size, maxZ)
    if not SamePositionContext(player, center, maxZ) or size <= 0 then return false end
    local half = size / 2
    return math.abs((player.x or 0) - (center.x or 0)) <= half
        and math.abs((player.y or 0) - (center.y or 0)) <= half
end

local function IsInRectangle(player, center, aim, length, width, maxZ)
    if not SamePositionContext(player, center, maxZ) or not aim or length <= 0 or width <= 0 then return false end
    local dirX, dirY = (aim.x or 0) - (center.x or 0), (aim.y or 0) - (center.y or 0)
    local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
    if dirLen <= 0 then dirX, dirY, dirLen = 1, 0, 1 end
    dirX, dirY = dirX / dirLen, dirY / dirLen
    local offX, offY = (player.x or 0) - (center.x or 0), (player.y or 0) - (center.y or 0)
    local forward = offX * dirX + offY * dirY
    local sideways = offX * dirY - offY * dirX
    return math.abs(forward) <= length / 2 and math.abs(sideways) <= width / 2
end

-- DISTANCIA AL AREA, para poder ENSENARLA. Saber quien entra no basta: lo que se discute en mesa
-- es por que uno entro y otro no, y por cuanto.
--
-- Cada figura se mide desde SU referencia, que no es la misma:
--   esfera, cubo, rectangulo -> desde el CENTRO
--   cono, linea              -> desde el ORIGEN, que es quien lanza
-- Medirlas todas desde el lanzador daria un numero que no explica nada en las dos primeras.
--
-- Se devuelve en METROS, que es como se escriben las areas y como piensa el jugador; por dentro
-- todo son yardas, que es como mide el mundo.
local METROS_POR_YARDA = 0.9144

local function AreaDistanceInfo(geometry, player, origin, aim)
    if not (geometry and player and origin) then return nil end
    local dist = math.sqrt(PositionDistance2DSq(player, origin))
    local shape = geometry.shape
    if shape == "circle" then
        return dist * METROS_POR_YARDA, (geometry.radius or 0) * METROS_POR_YARDA, "centro"
    elseif shape == "square" then
        return dist * METROS_POR_YARDA, ((geometry.size or 0) / 2) * METROS_POR_YARDA, "centro"
    elseif shape == "rectangle" then
        return dist * METROS_POR_YARDA, ((geometry.length or 0) / 2) * METROS_POR_YARDA, "centro"
    elseif shape == "cone" then
        return dist * METROS_POR_YARDA, (geometry.range or 0) * METROS_POR_YARDA, "origen"
    elseif shape == "line" then
        -- En una linea la distancia que importa es lo que AVANZA por el eje, no la directa: alguien
        -- muy a un lado puede estar cerca de ti y aun asi quedar fuera por anchura.
        if aim then
            local dirX, dirY = (aim.x or 0) - (origin.x or 0), (aim.y or 0) - (origin.y or 0)
            local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
            if dirLen > 0 then
                dirX, dirY = dirX / dirLen, dirY / dirLen
                local offX, offY = (player.x or 0) - (origin.x or 0), (player.y or 0) - (origin.y or 0)
                local forward = offX * dirX + offY * dirY
                return forward * METROS_POR_YARDA, (geometry.length or 0) * METROS_POR_YARDA, "origen"
            end
        end
        return dist * METROS_POR_YARDA, (geometry.length or 0) * METROS_POR_YARDA, "origen"
    end
    return nil
end

-- Texto corto para la fila: "4,2 / 9,8 m". La coma decimal, que es como se escribe en español.
local function AreaDistanceText(geometry, player, origin, aim)
    local d, limite = AreaDistanceInfo(geometry, player, origin, aim)
    if not d then return "" end
    return (string.format("%.1f / %.1f m", d, limite):gsub("%.", ","))
end

local function IsPositionAffected(geometry, player, origin, aim)
    if not geometry then return false end
    if geometry.shape == "circle" then
        return IsInCircle(player, origin, geometry.radius, geometry.maxZ)
    elseif geometry.shape == "cone" then
        return IsInCone(player, origin, aim, geometry.range, geometry.angle, geometry.maxZ)
    elseif geometry.shape == "line" then
        return IsInLine(player, origin, aim, geometry.length, geometry.width, geometry.maxZ)
    elseif geometry.shape == "square" then
        return IsInSquare(player, origin, geometry.size, geometry.maxZ)
    elseif geometry.shape == "rectangle" then
        return IsInRectangle(player, origin, aim, geometry.length, geometry.width, geometry.maxZ)
    end
    return false
end

local CONDITION_DURATIONS = {
    manual = true,
    target_turn_start = true, source_turn_start = true,
    target_turn_end = true, source_turn_end = true,
    rounds = true, save_at_turn_end = true,
}

local function NormalizeConditionMetadata(area, definition, conditionId)
    if conditionId == "" then
        return "manual", 0, nil, 0, false
    end
    local duration = tostring(area.conditionDuration or definition.conditionDuration or "manual")
    if not CONDITION_DURATIONS[duration] then return nil, "Duracion de condicion de area desconocida" end
    local turns = math.max(0, math.min(99,
        math.floor(tonumber(area.conditionTurns or definition.conditionTurns) or 0)))
    local saveAbility = CanonicalAbility(area.conditionSaveAbility or definition.conditionSaveAbility)
    local saveDC = math.max(0, math.min(99,
        math.floor(tonumber(area.conditionSaveDC or definition.conditionSaveDC) or 0)))
    if duration == "rounds" and turns <= 0 then return nil, "Una condicion por rondas necesita conditionTurns" end
    if duration == "save_at_turn_end" and (not saveAbility or saveDC <= 0) then
        return nil, "La salvacion final de la condicion esta incompleta"
    end
    return duration, turns, saveAbility, saveDC,
        area.conditionPersist == true or definition.conditionPersist == true
end

local function DamageLabel(key)
    if key == "heal" then return "curacion" end
    return (HarfordDamageTypes and HarfordDamageTypes.GetLabel and HarfordDamageTypes.GetLabel(key)) or tostring(key or "")
end

local function NormalizeComponents(components)
    local out = {}
    for i, component in ipairs(components or {}) do
        if i > 8 then break end
        -- Dano FIJO sin dados. Existe en 5e (el Aliento de Fuego del Monje inflige "tu nivel de
        -- Monje mas tu Mod. Sabiduria", las trampas del Cazador "el doble de tu nivel"), y hasta
        -- ahora solo lo aceptaba la curacion, asi que esos efectos no se podian declarar.
        local fixedAmount = tonumber(component.fixedAmount)
        if fixedAmount then
            local damageType = CanonicalDamageType(component.damageType or component.type)
            if not damageType then return nil, "Componente de dano de area invalido" end
            out[#out + 1] = {
                fixedAmount = math.max(1, math.min(10000, math.floor(fixedAmount))),
                damageType = damageType,
            }
        else
        local dice = tostring(component.damageDice or component.dice or "")
        local count, sides
        if HarfordDnDWeapons and HarfordDnDWeapons.ParseDice then
            count, sides = HarfordDnDWeapons.ParseDice(dice)
        end
        local damageType = CanonicalDamageType(component.damageType or component.type)
        if not count or not sides or count < 1 or count > 100 or sides < 2 or sides > 1000 or not damageType then
            return nil, "Componente de dano de area invalido"
        end
        out[#out + 1] = {
            damageDice = tostring(count) .. "d" .. tostring(sides),
            damageBonus = math.max(-10000, math.min(10000, math.floor(tonumber(component.damageBonus or component.bonus) or 0))),
            damageType = damageType,
        }
        end
    end
    if #out == 0 then return nil, "El ataque de area no tiene dano" end
    return out
end

local function NormalizeDefinition(definition)
    definition = definition or {}
    local area = definition.area or definition
    local resolution = area.resolution == "attack" and "attack" or area.resolution == "save" and "save"
        or area.resolution == "auto" and "auto" or area.resolution == "heal" and "heal" or nil
    if not resolution then return nil, "Resolucion de area desconocida" end

    local conditionId = tostring(area.conditionId or definition.conditionId or "")
    if conditionId ~= "" and not (HarfordDnDConditions and HarfordDnDConditions.GetDefinition
        and HarfordDnDConditions.GetDefinition(conditionId)) then
        return nil, "Condicion de area desconocida"
    end

    local components, err
    if resolution == "heal" then
        components = {}
        for _, component in ipairs(area.healingComponents or definition.healingComponents or {}) do
            local fixedAmount = tonumber(component.fixedAmount)
            if fixedAmount then
                fixedAmount = math.max(1, math.min(10000, math.floor(fixedAmount)))
                components[#components + 1] = {
                    fixedAmount = fixedAmount,
                    damageType = "heal",
                }
            else
                local dice = tostring(component.damageDice or component.dice or "")
                -- Asignacion separada de la guarda: en una cadena `and` solo sobrevive el primer
                -- retorno, y `sides` quedaba nil, de modo que esta validacion rechazaba TODAS las
                -- curaciones.
                local count, sides
                if HarfordDnDWeapons and HarfordDnDWeapons.ParseDice then
                    count, sides = HarfordDnDWeapons.ParseDice(dice)
                end
                if not count or not sides or count < 1 or count > 100 or sides < 2 or sides > 1000 then
                    return nil, "Componente de curacion invalido"
                end
                components[#components + 1] = {
                    damageDice = tostring(count) .. "d" .. tostring(sides),
                    damageBonus = math.max(-10000, math.min(10000, math.floor(tonumber(component.damageBonus or component.bonus) or 0))),
                    damageType = "heal",
                }
            end
        end
        if #components == 0 then return nil, "El efecto no tiene curacion" end
    else
        components, err = NormalizeComponents(area.damageComponents or definition.damageComponents)
    end
    if not components then
        -- Sin daño es valido SOLO si el conjuro aplica una condicion (control puro).
        if conditionId == "" then return nil, err end
        components = {}
    end

    local shape = tostring(area.shape or "other"):lower()
    if shape == "circle" or shape == "radius" then shape = "sphere" end
    if shape == "cube" then shape = "square" end
    if shape ~= "cone" and shape ~= "sphere" and shape ~= "line"
        and shape ~= "square" and shape ~= "rectangle" and shape ~= "other" then
        shape = "other"
    end
    local conditionDuration, conditionTurns, conditionSaveAbility, conditionSaveDC, conditionPersist =
        NormalizeConditionMetadata(area, definition, conditionId)
    if not conditionDuration then return nil, conditionTurns end
    local conditionApplySaveAbility = CanonicalAbility(area.conditionApplySaveAbility or definition.conditionApplySaveAbility)
    local conditionApplySaveDC = math.max(0, math.min(99,
        math.floor(tonumber(area.conditionApplySaveDC or definition.conditionApplySaveDC) or 0)))
    if not conditionApplySaveAbility then conditionApplySaveDC = 0 end
    local out = {
        label = tostring(definition.hyperlink or definition.title or definition.name or area.label or "Ataque de area"),
        networkLabel = tostring(definition.title or definition.name or area.label or "Ataque de area"),
        shape = shape,
        sizeText = tostring(area.sizeText or ""):sub(1, 40),
        resolution = resolution,
        castLevel = math.max(0, math.floor(tonumber(area.castLevel or definition.castLevel) or 0)),
        damageComponents = components,
        auraId = math.max(0, math.floor(tonumber(area.auraId or area.onFailAura or area.onHitAura or definition.onFailAura or definition.onHitAura) or 0)),
        conditionId = conditionId,
        conditionDuration = conditionDuration,
        conditionTurns = conditionTurns,
        conditionSaveAbility = conditionSaveAbility,
        conditionSaveDC = conditionSaveDC,
        conditionApplySaveAbility = conditionApplySaveAbility,
        conditionApplySaveDC = conditionApplySaveDC,
        conditionPersist = conditionPersist,
        resourceKey = tostring(area.resourceKey or area.resource or ""),
        resourceCost = math.max(0, math.floor(tonumber(area.resourceCost or area.cost) or 0)),
        attackRange = area.attackRange == "melee" and "melee" or "ranged",
        repeatTargets = area.repeatTargets == true or definition.repeatTargets == true,
        rollPerTarget = area.rollPerTarget == true or definition.rollPerTarget == true,
        rerollDamageDice = math.max(0, math.min(99,
            math.floor(tonumber(area.rerollDamageDice or definition.rerollDamageDice) or 0))),
        applicationCount = math.max(1, math.min(MAX_TARGETS,
            math.floor(tonumber(area.applicationCount or definition.applicationCount) or 1))),
    }
    if resolution == "save" then
        out.saveAbility = CanonicalAbility(area.saveAbility or area.ability)
        out.dc = math.max(1, math.min(99, math.floor(tonumber(area.dc) or 0)))
        out.success = area.success == "half" and "half" or area.success == "none" and "none"
            or (#components == 0 and "none") or nil  -- condicion pura: success no aplica
        if not out.saveAbility or out.dc <= 0 then return nil, "Salvacion de area incompleta" end
        if not out.success then return nil, "Falta indicar si la salvacion reduce a mitad o niega el dano" end
    elseif resolution == "attack" then
        out.attackBonus = math.max(-99, math.min(99, math.floor(tonumber(area.attackBonus or definition.attackBonus) or 0)))
    end  -- auto/heal: sin tirada, no necesita campos extra
    return out
end

function API.DefinitionFromFeature(feature)
    if not (feature and type(feature.area) == "table") then return nil end
    return NormalizeDefinition(feature)
end

function API.DefinitionFromAction(action)
    if not (action and type(action.area) == "table") then return nil end
    return NormalizeDefinition(action)
end

local function ShapeText(def)
    local labels = { cone = "Cono", sphere = "Radio", line = "Linea", square = "Cuadrado", rectangle = "Rectangulo", other = "Area" }
    local text = labels[def.shape] or "Area"
    if def.sizeText ~= "" then text = text .. " " .. def.sizeText end
    return text
end

local function CaptureUnit(unit)
    unit = unit or "target"
    if not (UnitExists and UnitExists(unit) and UnitGUID) then return nil, "Sin objetivo" end
    local guid = UnitGUID(unit)
    if not guid or guid == "" then return nil, "El objetivo no tiene GUID" end
    local isPlayer = UnitIsPlayer and UnitIsPlayer(unit)
    local name
    if HarfordTRP3 and HarfordTRP3.GetUnitRPName then name = HarfordTRP3.GetUnitRPName(unit) end
    name = name or HarfordClassColors.UnitFullName(unit) or "Objetivo"
    return {
        guid = guid,
        kind = isPlayer and "player" or "npc",
        name = name,
        unitName = isPlayer and HarfordClassColors.UnitFullName(unit) or nil,
        status = "Marcado",
        conditionIds = HarfordDnDConditions and HarfordDnDConditions.GetActiveIds
            and HarfordDnDConditions.GetActiveIds(unit) or nil,
    }
end

local RefreshFrame

function API.SetNpcPositionProvider(provider)
    npcPositionProvider = type(provider) == "function" and provider or nil
end

local function AddTargetFromPosition(session, position, status)
    if not session or session.resolved or not position or position.guid == "" then return false end
    for _, existing in ipairs(session.targets or {}) do
        if existing.guid == position.guid then return false end
    end
    if #(session.targets or {}) >= MAX_TARGETS then return false end
    session.targets[#session.targets + 1] = {
        guid = position.guid,
        kind = "player",
        name = position.name ~= "" and position.name or "Jugador",
        unitName = position.name ~= "" and position.name or nil,
        status = status or "Auto",
        position = position,
    }
    return true
end

local function ReevaluatePositionResponses(session)
    if not (session and session.positionScan and session.geometry and session.positionScan.origin) then return 0 end
    local scan = session.positionScan
    local aim = scan.aim
    if not aim and scan.aimGuid and scan.responses then
        aim = scan.responses[scan.aimGuid]
        scan.aim = aim
    end
    if (session.geometry.shape == "cone" or session.geometry.shape == "line" or session.geometry.shape == "rectangle") and not aim then
        return 0
    end
    local added = 0
    -- Los que respondieron y NO entran se guardan aparte para poder ensenarlos. NUNCA en
    -- `session.targets`: esa lista es la que recibe el dano, y meter ahi a alguien que quedo fuera
    -- se lo aplicaria.
    session.outside = {}
    for _, position in pairs(scan.responses or {}) do
        if IsPositionAffected(session.geometry, position, scan.origin, aim) then
            if AddTargetFromPosition(session, position, "Auto") then added = added + 1 end
        else
            session.outside[#session.outside + 1] = {
                name = position.name ~= "" and position.name or "Jugador",
                distancia = AreaDistanceText(session.geometry, position, scan.origin, aim),
            }
        end
    end
    -- Del mas cerca al mas lejos: el que casi entra es el que interesa mirar.
    table.sort(session.outside, function(a, b) return tostring(a.distancia) < tostring(b.distancia) end)
    return added
end

local function AreaAimGuid(session)
    if session and session.context and session.context.sourceKind == "npc" then
        if UnitExists and UnitExists("focus") and UnitIsPlayer and UnitIsPlayer("focus") then
            return UnitGUID and UnitGUID("focus") or nil
        end
    end
    if UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
        return UnitGUID and UnitGUID("target") or nil
    end
    return nil
end

local function AreaPositionChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

local function SenderUnitFromName(sender)
    sender = tostring(sender or "")
    if sender == "" then return nil end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        local unit = HarfordClassColors.FindUnitByName(sender)
        if unit then return unit end
    end
    local senderShort = HarfordClassColors.ShortName and HarfordClassColors.ShortName(sender) or sender:match("^[^%-]+") or sender
    local function matches(unit)
        if not (UnitExists and UnitExists(unit)) then return false end
        local full = HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName(unit) or UnitName(unit)
        local short = HarfordClassColors.ShortName and HarfordClassColors.ShortName(full) or tostring(full or ""):match("^[^%-]+") or full
        return full == sender or short == senderShort
    end
    if matches("player") then return "player" end
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if matches(unit) then return unit end
        end
    elseif IsInGroup and IsInGroup() then
        for i = 1, 4 do
            local unit = "party" .. i
            if matches(unit) then return unit end
        end
    end
    return nil
end

local function IsTrustedAreaSender(sender)
    sender = tostring(sender or "")
    return sender ~= "" and SenderUnitFromName(sender) ~= nil
end

local function NormalizePositionSender(position, sender)
    if not position then return nil end
    local unit = SenderUnitFromName(sender)
    local guid = unit and UnitGUID and UnitGUID(unit) or nil
    local name = unit and HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName(unit) or nil
    position.guid = guid and guid ~= "" and guid or tostring(sender or "")
    position.name = name and name ~= "" and name or tostring(sender or "")
    return position
end

local function BeginPositionRequest(session, origin)
    local channel = AreaPositionChannel()
    if not channel then
        Print("Necesitas estar en grupo o raid para pedir posiciones.")
        return false
    end
    local requestId = session.id .. ".pos." .. tostring(session.turn or 1)
    session.positionScan = {
        id = requestId,
        origin = origin,
        aimGuid = AreaAimGuid(session),
        responses = {},
        startedAt = Now(),
    }
    local myGuid = UnitGUID and UnitGUID("player") or ""
    local myName = HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName("player") or UnitName("player") or ""
    local ownPosition = CapturePlayerPosition()
    if ownPosition and myGuid ~= "" then
        ownPosition.guid, ownPosition.name = myGuid, myName
        session.positionScan.responses[myGuid] = ownPosition
    end
    ReevaluatePositionResponses(session)
    local ok, sendErr = HarfordSync.SendAreaPositionRequest(PREFIX, channel, requestId)
    if not ok then Print(sendErr or "No se pudo pedir posiciones."); return false end
    Print("Peticion de posiciones enviada. Los jugadores dentro se marcaran automaticamente.")
    if C_Timer and C_Timer.After then
        C_Timer.After(POSITION_RESPONSE_TIMEOUT, function()
            if S.session == session and session.positionScan and session.positionScan.id == requestId then
                local count = ReevaluatePositionResponses(session)
                Print("Auto area: " .. tostring(count) .. " nuevo(s) jugador(es) marcado(s).")
                RefreshFrame()
            end
        end)
    end
    RefreshFrame()
    return true
end

local function CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    return button
end

local function EnsureFrame()
    if S.frame then return S.frame end
    local frame = CreateFrame("Frame", "HarfordDnDAreaFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(430, 350)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -7)
    title:SetText("Ataque de area")
    frame.areaTitle = title

    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", 18, -35)
    info:SetPoint("RIGHT", -18, 0)
    info:SetJustifyH("LEFT")
    frame.info = info

    local candidate = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    candidate:SetPoint("TOPLEFT", 18, -64)
    candidate:SetPoint("RIGHT", -220, 0)
    candidate:SetJustifyH("LEFT")
    frame.candidate = candidate

    local add = CreateButton(frame, "Anadir objetivo", 120, 22)
    add:SetPoint("TOPRIGHT", -18, -58)
    add:SetScript("OnClick", function() API.AddCurrentTarget() end)
    frame.add = add

    local autoPlayers = CreateButton(frame, "Auto jugadores", 92, 22)
    autoPlayers:SetPoint("RIGHT", add, "LEFT", -8, 0)
    autoPlayers:SetScript("OnClick", function() API.RequestPlayerPositions() end)
    frame.autoPlayers = autoPlayers

    local rows = {}
    for i = 1, ROW_COUNT do
        local row = CreateFrame("Button", nil, frame)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 20, -92 - (i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", -40, 0)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.08, 0.08, 0.08, i % 2 == 0 and 0.7 or 0.45)
        local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        name:SetPoint("LEFT", 6, 0)
        name:SetPoint("RIGHT", -112, 0)
        name:SetJustifyH("LEFT")
        local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("RIGHT", -27, 0)
        status:SetWidth(82)
        status:SetJustifyH("RIGHT")
        local remove = CreateButton(row, "X", 22, 20)
        remove:SetPoint("RIGHT", -1, 0)
        remove:SetScript("OnClick", function(self)
            if self.targetIndex then API.RemoveTarget(self.targetIndex) end
        end)
        row.name, row.status, row.remove = name, status, remove
        rows[i] = row
    end
    frame.rows = rows

    local scroll = CreateFrame("ScrollFrame", "HarfordDnDAreaScrollFrame", frame, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", rows[1], "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", rows[#rows], "BOTTOMRIGHT", 22, 0)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RefreshFrame)
    end)
    frame.scroll = scroll

    local clear = CreateButton(frame, "Limpiar", 82, 22)
    clear:SetPoint("BOTTOMLEFT", 18, 15)
    clear:SetScript("OnClick", function()
        local session = S.session
        if session and not session.resolved then session.targets = {}; RefreshFrame() end
    end)
    frame.clear = clear

    local skip = CreateButton(frame, "Saltar NPC", 92, 22)
    skip:SetPoint("LEFT", clear, "RIGHT", 8, 0)
    skip:SetScript("OnClick", function() API.SkipPendingNpc() end)
    frame.skip = skip

    local cancel = CreateButton(frame, "Cancelar", 82, 22)
    cancel:SetPoint("BOTTOMRIGHT", -18, 15)
    cancel:SetScript("OnClick", function() API.Cancel() end)
    frame.cancel = cancel

    local resolve = CreateButton(frame, "Resolver", 92, 22)
    resolve:SetPoint("RIGHT", cancel, "LEFT", -8, 0)
    resolve:SetScript("OnClick", function() API.Resolve() end)
    frame.resolve = resolve

    -- Solo zonas: avanza al siguiente turno para re-marcar y re-aplicar daño sin re-pagar mana.
    local repeatBtn = CreateButton(frame, "Repetir turno", 100, 22)
    repeatBtn:SetPoint("RIGHT", resolve, "LEFT", -8, 0)
    repeatBtn:SetScript("OnClick", function() API.RepeatTurn() end)
    frame.repeatBtn = repeatBtn

    if frame.CloseButton then frame.CloseButton:SetScript("OnClick", function() API.Cancel() end) end
    S.frame = frame
    return frame
end

RefreshFrame = function()
    local frame = EnsureFrame()
    local session = S.session
    if not session then frame:Hide(); return end
    frame.areaTitle:SetText(session.definition.label)
    local def = session.definition
    local infoText = ShapeText(def) .. " - " .. (
        def.resolution == "save" and ("Salv. " .. def.saveAbility .. " CD " .. def.dc)
        or def.resolution == "auto" and "Auto-impacto"
        or def.resolution == "heal" and "Curacion"
        or ("Ataque " .. ((def.attackBonus or 0) >= 0 and "+" or "") .. (def.attackBonus or 0)))
    if (def.applicationCount or 1) > 1 then
        infoText = infoText .. " | " .. tostring(#(session.targets or {})) .. "/" .. tostring(def.applicationCount) .. " aplicaciones"
    end
    local pending = session.resolved and session.pendingNpc and session.pendingNpc[session.pendingNpcIndex or 1]
    if pending then infoText = infoText .. " | Siguiente NPC: " .. pending.target.name end
    frame.info:SetText(infoText)
    local candidate = CaptureUnit("target")
    frame.candidate:SetText(candidate and ("Objetivo actual: " .. candidate.name) or "Objetivo actual: ninguno")

    local targets = session.targets or {}
    -- Detras de los marcados van, en gris, los que respondieron y quedaron FUERA. Sin ellos, quien
    -- no entra simplemente desaparece de la ventana y no hay forma de saber por que.
    local filas = {}
    for _, target in ipairs(targets) do filas[#filas + 1] = { target = target } end
    for _, fuera in ipairs(session.outside or {}) do filas[#filas + 1] = { fuera = fuera } end

    local scan = session.positionScan
    local aimPos = scan and scan.aim
    local offset = FauxScrollFrame_GetOffset(frame.scroll) or 0
    FauxScrollFrame_Update(frame.scroll, #filas, ROW_COUNT, ROW_HEIGHT)
    for i, row in ipairs(frame.rows) do
        local fila = filas[offset + i]
        local target = fila and fila.target
        if fila and fila.fuera then
            row:Show()
            row.name:SetText("|cff707070" .. fila.fuera.name .. "|r")
            row.status:SetText("|cff707070fuera  " .. tostring(fila.fuera.distancia) .. "|r")
            row.remove.targetIndex = nil
            row.remove:Hide()
        elseif target then
            row:Show()
            local number = (def.applicationCount or 1) > 1 and (tostring(offset + i) .. ". ") or ""
            -- La distancia va con el nombre: es lo que permite ver de un vistazo quien esta al
            -- borde y decidir a mano, que es lo que se acaba haciendo igualmente.
            local dist = ""
            if target.position and session.geometry and scan and scan.origin then
                local texto = AreaDistanceText(session.geometry, target.position, scan.origin, aimPos)
                if texto ~= "" then dist = "  |cff909090" .. texto .. "|r" end
            end
            row.name:SetText(number .. target.name
                .. (target.kind == "player" and " |cff66ccff[J]|r" or " |cffffcc66[NPC]|r") .. dist)
            local statusLabels = {
                marked = "Marcado", waiting = "Esperando", saved = "Salvada", failed = "Fallada",
                hit = "Impacto", miss = "Fallo", skipped = "Omitido", timeout = "Sin confirmar",
            }
            local rawStatus = tostring(target.status or "")
            local code, suffix = rawStatus:match("^(%a+)(.*)$")
            row.status:SetText((statusLabels[code] or rawStatus) .. (suffix or ""))
            row.remove.targetIndex = offset + i
            row.remove:SetShown(not session.resolved)
        else
            row:Hide()
            row.remove.targetIndex = nil
        end
    end
    local targetLimit = session.definition.applicationCount or MAX_TARGETS
    frame.add:SetEnabled(not session.resolved and #targets < math.min(MAX_TARGETS, targetLimit))
    local canAuto = not session.resolved and session.geometry ~= nil
        and (session.context.sourceKind ~= "npc" or session.context.sourcePosition or npcPositionProvider)
    frame.autoPlayers:SetEnabled(canAuto)
    frame.clear:SetEnabled(not session.resolved and #targets > 0)
    frame.resolve:SetEnabled(not session.resolved and #targets > 0)
    frame.skip:SetShown(session.resolved and session.pendingNpcIndex and session.pendingNpcIndex <= #(session.pendingNpc or {}))
    -- "Repetir turno" solo en zonas ya resueltas (avanza al siguiente turno de la zona persistente).
    frame.repeatBtn:SetShown(session.zone and session.resolved and true or false)
end

function API.Open(definition, context)
    local normalized, err = NormalizeDefinition(definition)
    if not normalized then Print(err); return false, err end
    context = context or {}
    if context.sourceKind == "npc" and context.sourceGuid then
        local currentGuid = UnitGUID and UnitGUID("target")
        if currentGuid ~= context.sourceGuid or (UnitIsPlayer and UnitIsPlayer("target")) then
            local message = "El objetivo ya no coincide con el NPC que ejecuta el ataque."
            Print(message)
            return false, message
        end
    end
    if not context.sourceGuid or context.sourceGuid == "" then
        context.sourceGuid = UnitGUID and UnitGUID(context.sourceKind == "npc" and "target" or "player") or ""
    end
    if not context.sourceName or context.sourceName == "" then
        local sourceUnit = context.sourceKind == "npc" and "target" or "player"
        context.sourceName = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName(sourceUnit))
            or (HarfordClassColors and HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName(sourceUnit))
            or ""
    end
    S.serial = (S.serial % 999999) + 1
    S.session = {
        id = tostring(math.floor(Now() * 1000)) .. "." .. tostring(S.serial),
        definition = normalized,
        context = context,
        targets = {},
        resolved = false,
        geometry = AreaGeometry(normalized),
        zone = context.zone == true,  -- zona persistente: habilita "Repetir turno" (re-aplica sin re-pagar)
        turn = 1,
        sourceConditionIds = HarfordDnDConditions and HarfordDnDConditions.GetActiveIds
            and HarfordDnDConditions.GetActiveIds(context.sourceKind == "player" and "player" or context.sourceGuid) or nil,
    }
    local frame = EnsureFrame()
    if type(context.onBegin) == "function" then context.onBegin(normalized) end
    -- Auto-resolucion de objetivo unico SIN ventana: marca el target actual y resuelve, para que
    -- un ataque/salvacion de conjuro de objetivo unico se sienta como un ataque normal. Si no hay
    -- objetivo valido, cae a mostrar la ventana para marcado manual.
    if context.autoResolve then
        frame:Hide()
        if API.AddCurrentTarget() then
            API.Resolve()
            return true
        end
        Print("Sin objetivo valido: marca las victimas manualmente.")
    end
    frame:Show()
    RefreshFrame()
    return true
end

function API.AddCurrentTarget()
    local session = S.session
    if not session or session.resolved then return false end
    local limit = math.min(MAX_TARGETS, tonumber(session.definition.applicationCount) or MAX_TARGETS)
    if #session.targets >= limit then Print("Todas las aplicaciones ya estan asignadas."); return false end
    local target, err = CaptureUnit("target")
    if not target then Print(err); return false end
    if not session.definition.repeatTargets then
        for _, existing in ipairs(session.targets) do
            if existing.guid == target.guid then Print("Ese objetivo ya esta marcado."); return false end
        end
    end
    session.targets[#session.targets + 1] = target
    if target.kind == "npc" and npcPositionProvider then
        npcPositionProvider({ sourceGuid = target.guid }, function(ok, position)
            if S.session ~= session then return end
            if ok and position then
                for _, entry in ipairs(session.targets or {}) do
                    if entry.guid == target.guid and not entry.position then
                        entry.position = position
                        break
                    end
                end
            end
        end)
    end
    RefreshFrame()
    return true
end

function API.RemoveTarget(index)
    local session = S.session
    if not session or session.resolved then return false end
    index = tonumber(index)
    if not index or not session.targets[index] then return false end
    table.remove(session.targets, index)
    RefreshFrame()
    return true
end

function API.RequestPlayerPositions()
    local session = S.session
    if not session or session.resolved then return false end
    if not session.geometry then
        Print("Esta area no tiene geometria automatica.")
        return false
    end
    if session.context and session.context.sourceKind == "npc" then
        if session.context.sourcePosition then
            return BeginPositionRequest(session, session.context.sourcePosition)
        end
        if not npcPositionProvider then
            Print("HarfordAdmin no ha registrado proveedor de posicion NPC. Marca manualmente.")
            return false
        end
        Print("Leyendo posicion del NPC...")
        npcPositionProvider(session.context, function(ok, position, err)
            if S.session ~= session then return end
            if ok and position then
                session.context.sourcePosition = position
                BeginPositionRequest(session, position)
            else
                Print(tostring(err or "No se pudo leer la posicion del NPC."))
            end
        end)
        return true
    end
    local origin, err = CapturePlayerPosition()
    if not origin then Print(err); return false end
    return BeginPositionRequest(session, origin)
end

local function RollComponents(definition)
    local rolled, details = {}, {}
    local rachaUsada = false   -- "Racha de calor": una vez por lanzamiento, no por componente
    for _, component in ipairs(definition.damageComponents) do
        -- Dano fijo: no hay dados que tirar ni que repetir, asi que ninguna de las reglas de
        -- repeticion de abajo le aplica.
        if component.fixedAmount then
            local amount = math.max(0, math.floor(tonumber(component.fixedAmount) or 0))
            rolled[#rolled + 1] = { amount = amount, maximum = amount, damageType = component.damageType }
            details[#details + 1] = tostring(amount) .. " " .. DamageLabel(component.damageType)
        else
        local count, sides = HarfordDnDWeapons.ParseDice(component.damageDice)
        local values, amount = {}, component.damageBonus
        for _ = 1, count do
            local value = HarfordDnDCalc.RollDie(sides)
            values[#values + 1] = value
            amount = amount + value
        end
        -- Palabra de Poder: Muerte. El lanzador decide preparar la palabra antes del
        -- conjuro; al resolverlo se repiten automaticamente los dados mas bajos para
        -- que el resultado no dependa de una segunda tirada paralela ni de la UI.
        local rerolls = math.max(0, math.floor(tonumber(definition.rerollDamageDice) or 0))
        local replaced = {}
        while rerolls > 0 and #values > 0 do
            local lowestIndex, lowestValue = 1, values[1]
            for index = 2, #values do
                if values[index] < lowestValue then lowestIndex, lowestValue = index, values[index] end
            end
            local newValue = HarfordDnDCalc.RollDie(sides)
            values[lowestIndex] = newValue
            amount = amount - lowestValue + newValue
            replaced[#replaced + 1] = tostring(lowestValue) .. "->" .. tostring(newValue)
            rerolls = rerolls - 1
        end
        -- "Racha de calor" (Mago de Fuego): si un dado saca el maximo, tiras UNO mas y lo SUMAS
        -- -- al reves que la repeticion de Palabra de Poder: Muerte, que SUSTITUYE el mas bajo.
        -- Mismo criterio que Guia Ancestral para saber que es un conjuro: `castLevel >= 1`, asi que
        -- los trucos y las areas de un rasgo del Libro quedan fuera. Una sola vez por lanzamiento;
        -- el manual dice por turno y el cliente no observa el fin de turno.
        local racha
        if not rachaUsada and (tonumber(definition.castLevel) or 0) >= 1
            and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
            and HarfordDnDFeatureEffects.HasFlag("heatStreak") then
            for _, v in ipairs(values) do
                if v == sides then
                    racha = HarfordDnDCalc.RollDie(sides)
                    amount = amount + racha
                    rachaUsada = true
                    break
                end
            end
        end
        rolled[#rolled + 1] = {
            amount = math.max(0, amount),
            maximum = math.max(0, count * sides + component.damageBonus),
            damageType = component.damageType,
        }
        local bonus = component.damageBonus ~= 0 and ((component.damageBonus > 0 and "+" or "") .. component.damageBonus) or ""
        details[#details + 1] = component.damageDice .. bonus .. " " .. DamageLabel(component.damageType)
            .. ": " .. table.concat(values, "+")
            .. (#replaced > 0 and (" (Muerte " .. table.concat(replaced, ", ") .. ")") or "")
            .. (racha and (" (Racha de calor +" .. tostring(racha) .. ")") or "")
        end
    end
    return rolled, table.concat(details, " | ")
end

local function RollHealingComponents(definition)
    local rolled, details = {}, {}
    for _, component in ipairs(definition.damageComponents or {}) do
        local fixedAmount = tonumber(component.fixedAmount)
        local count, sides
        local values, amount = {}, tonumber(component.damageBonus) or 0
        if fixedAmount then
            amount = math.max(0, math.floor(fixedAmount))
        else
            count, sides = HarfordDnDWeapons.ParseDice(component.damageDice)
            -- Guia Ancestral (Chaman de Restauracion): un dado de curacion que saque 1 o 2 se
            -- repite UNA vez y hay que usar el nuevo resultado, aunque sea otro 1 o 2. Igual que
            -- Gran Arma en el dano de arma, y con la misma notacion entre parentesis. Solo en
            -- conjuros de nivel 1 o superior: los trucos y las reservas fijas quedan fuera.
            local repiteBajos = (tonumber(definition.castLevel) or 0) >= 1
                and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
                and HarfordDnDFeatureEffects.HasFlag("ancestralGuidance")
            for _ = 1, count do
                local value = HarfordDnDCalc.RollDie(sides)
                if repiteBajos and value <= 2 then
                    local nuevo = HarfordDnDCalc.RollDie(sides)
                    values[#values + 1] = "(" .. tostring(value) .. "→" .. tostring(nuevo) .. ")"
                    value = nuevo
                else
                    values[#values + 1] = value
                end
                amount = amount + value
            end
        end
        rolled[#rolled + 1] = {
            amount = math.max(0, amount),
            maximum = fixedAmount and amount or math.max(0, count * sides + (tonumber(component.damageBonus) or 0)),
            damageType = "heal",
        }
        if fixedAmount then
            details[#details + 1] = tostring(amount)
        else
        local bonus = (tonumber(component.damageBonus) or 0) ~= 0
            and (((tonumber(component.damageBonus) or 0) > 0 and "+" or "") .. tostring(component.damageBonus)) or ""
        details[#details + 1] = component.damageDice .. bonus .. ": " .. table.concat(values, "+")
        end
    end
    return rolled, table.concat(details, " | ")
end

local function PruneProcessed()
    local now = Now()
    for key, entry in pairs(S.processed) do
        if not entry.expires or entry.expires <= now then S.processed[key] = nil end
    end
end

-- `propio`: la linea habla de lo que le pasa a ESTE jugador (su salvacion, lo que recibe), asi que
-- lleva su nombre aunque tenga una ficha de NPC cargada por estar en modo DM. Sin esto salia a
-- nombre del NPC, que no es quien esta salvando.
local function BroadcastInfo(label, responseTarget, propio)
    local roll = { type = "info", label = label }
    if propio and HarfordDnDRolls.GetOwnName then roll.player = HarfordDnDRolls.GetOwnName() end
    HarfordDnDRolls.Broadcast(roll)
    if responseTarget and responseTarget ~= "" and HarfordSync and HarfordSync.BestChannel
        and not HarfordSync.BestChannel() and HarfordDnDRolls.Serialize then
        HarfordSync.Send(PREFIX, HarfordDnDRolls.Serialize(roll), "WHISPER", responseTarget)
    end
end

local function ApplyComponents(unit, request, affected, critical)
    if not affected then return 0, {} end
    local total, summaries = 0, {}
    for _, component in ipairs(request.components or {}) do
        local amount = critical and component.maximum or component.amount
        if request.mode == "save" and request.saved then
            amount = request.success == "half" and math.floor(amount / 2) or 0
        end
        local applied, _status, marker = amount, nil, ""
        if amount > 0 and HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
            applied, _status, marker = HarfordDamageMitigation.ForTarget(unit, component.damageType, amount)
        end
        total = total + (tonumber(applied) or 0)
        summaries[#summaries + 1] = tostring(applied or 0) .. " " .. DamageLabel(component.damageType)
            .. (marker and marker ~= "" and (" " .. marker) or "")
    end
    return total, summaries
end

local function ApplyLocalHealing(total)
    total = math.max(0, math.floor(tonumber(total) or 0))
    if total <= 0 or not (HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent) then return 0 end
    local current = HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.GetResourceCurrent("health") or 0
    local maximum = HarfordDnDStore.GetResourceMax and HarfordDnDStore.GetResourceMax("health") or current
    local applied = math.max(0, math.min(total, math.max(0, maximum - current)))
    if applied > 0 then HarfordDnDStore.AdjustResourceCurrent("health", applied) end
    return applied
end


local function ApplyNpcHealing(total)
    total = math.max(0, math.floor(tonumber(total) or 0))
    if total <= 0 then return 0 end
    -- El servidor conserva la vida autoritativa del NPC, pero el cliente conoce su tope
    -- visible. No pedir una curacion que sobrepase ese maximo cuando esta disponible.
    if UnitHealth and UnitHealthMax then
        local current, maximum = tonumber(UnitHealth("target")) or 0, tonumber(UnitHealthMax("target")) or 0
        if maximum > 0 then total = math.min(total, math.max(0, maximum - current)) end
    end
    if total <= 0 then return 0 end
    if HarfordServerActions and HarfordServerActions.SetNpcHealthDelta
        and HarfordServerActions.SetNpcHealthDelta(total, { addonName = "Harford" }) then
        return total
    end
    return 0
end

-- ¿Prende el efecto (aura/condicion) del area sobre la victima? Impacto en ataque, fallo en salvacion.
local function AreaEffectLands(mode, status)
    return mode == "attack" and status == "hit" or mode == "save" and status == "failed" or mode == "auto"
end

-- Opts de condicion derivados del request de area; compartido por la ruta jugador y la NPC
-- (solo cambia el nombre de fuente: el sender en jugador, el sourceName del request en NPC).
local function ConditionOptsFromRequest(request, sourceName)
    return {
        sourceGuid = request.sourceGuid,
        sourceName = sourceName,
        duration = request.conditionDuration,
        turns = request.conditionTurns,
        saveAbility = request.conditionSaveAbility,
        saveDC = request.conditionSaveDC,
        persist = request.conditionPersist == true,
    }
end

-- Algunos ataques de conjuro aplican una condicion solo si la victima falla una segunda
-- salvacion despues de recibir el impacto (por ejemplo, Rayo de Enfermedad). La resuelve el
-- propio defensor para no usar ni transmitir sus bonificadores desde el atacante.
local function ResolveConditionApplySave(unit, request)
    local ability, dc = request.conditionApplySaveAbility, tonumber(request.conditionApplySaveDC)
    if not ability or ability == "" or not dc or dc <= 0 then return false, nil end
    local autoFail = HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
        and HarfordDnDConditions.IsSaveAutoFailed(unit, ability)
    local mode = "normal"
    if HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode then
        mode = HarfordDnDConditions.ResolveRollMode(mode, "save", { actorUnit = unit, ability = ability })
    end
    local die = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(mode))
    local bonus, prof
    if unit == "player" then
        bonus, prof = HarfordDnDCalc.GetSaveRollBonuses(ability)
    else
        bonus, prof = HarfordDnDCombat.GetSaveBonusForUnit(unit, ability), 0
    end
    local total = die + (tonumber(bonus) or 0) + (tonumber(prof) or 0)
    local saved = not autoFail and total >= dc
    local detail = string.format("Salv %s: %d (%d%+d%+d vs CD %d) %s", ability, total, die,
        tonumber(bonus) or 0, tonumber(prof) or 0, dc,
        saved and "|cff00ff00EXITO|r" or "|cffff3333FALLO|r")
    return saved, detail
end

-- Linea de resultado por victima: "<nombre> <label>: <rollText> EXITO/FALLO [- daño]".
-- Compartida por la ruta jugador y la NPC.
local function FormatVictimResult(name, request, status, applied, summaries, rollText)
    local result = (status == "saved" or status == "hit") and "|cff00ff00EXITO|r" or "|cffff3333FALLO|r"
    return string.format("%s %s: %s %s%s", name, request.label, rollText or "", result,
        (applied or 0) > 0 and (" - " .. table.concat(summaries, " + ")) or "")
end

local function PlayerResultLabel(request, status, total, summaries, rollText)
    local name = (HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("player"))
        or UnitName("player") or "Jugador"
    return FormatVictimResult(name, request, status, total, summaries, rollText)
end

local function ResolvePlayerRequest(request, sender)
    local cacheKey = tostring(sender or "") .. "|" .. request.id
    PruneProcessed()
    local cached = S.processed[cacheKey]
    if cached then
        if sender and sender ~= "" then HarfordSync.SendAreaResult(PREFIX, sender, cached.result) end
        return true, cached.result
    end

    local affected, status, rollText, critical = false, "invalid", "", false
    if request.mode == "heal" then
        affected, status, rollText = true, "hit", "Curacion"
    elseif request.mode == "save" then
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(request.ability)
        local autoFail = HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
            and HarfordDnDConditions.IsSaveAutoFailed("player", request.ability)
        local mode = HarfordDnDCalc.GetMode()
        if HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode then
            mode = HarfordDnDConditions.ResolveRollMode(mode, "save", { actorUnit = "player", ability = request.ability })
        end
        local die = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(mode))
        local total = die + (tonumber(base) or 0) + (tonumber(prof) or 0)
        request.saved = not autoFail and total >= request.dc
        affected = not request.saved or request.success == "half"
        status = request.saved and "saved" or "failed"
        rollText = string.format("Salv %s: %d (%d%+d%+d vs CD %d)", request.ability, total, die,
            tonumber(base) or 0, tonumber(prof) or 0, request.dc)
    elseif request.mode == "auto" then
        -- Auto-impacto (tipo Proyectil Magico): sin tirada, siempre afecta.
        affected, status, rollText = true, "hit", "Impacto automatico"
    else
        local armorClass = HarfordDnDCombat.ComputeSelfArmorClass()
        critical = request.critical == "critical"
        local hit = critical or (request.critical ~= "fumble" and request.attackTotal > armorClass)
        affected = hit
        status = hit and "hit" or "miss"
        rollText = string.format("Ataque %d vs CA %d", request.attackTotal, armorClass)
    end

    local applied, summaries
    if request.mode == "heal" then
        local total = 0
        for _, component in ipairs(request.components or {}) do total = total + (tonumber(component.amount) or 0) end
        applied = ApplyLocalHealing(total)
        summaries = { tostring(applied) .. " curacion" }
    else
        applied, summaries = ApplyComponents("player", request, affected, critical)
    end
    if request.mode ~= "heal" and applied > 0 and HarfordDnDStore.ApplyLocalResourceDamage then
        HarfordDnDStore.ApplyLocalResourceDamage(applied)
        if HarfordDnDCombat and HarfordDnDCombat.PlayLocalWound then HarfordDnDCombat.PlayLocalWound(critical) end
    elseif request.mode == "attack" and status == "miss" and HarfordDnDCombat and HarfordDnDCombat.PlayLocalDefense then
        HarfordDnDCombat.PlayLocalDefense()
    end
    local conditionLands = AreaEffectLands(request.mode, status)
    if conditionLands and request.conditionId and request.conditionId ~= "" then
        local saved, detail = ResolveConditionApplySave("player", request)
        if detail then
            rollText = rollText ~= "" and (rollText .. " | " .. detail) or detail
            conditionLands = not saved
        end
    end
    if conditionLands then
        if request.conditionId and request.conditionId ~= "" and HarfordDnDConditions then
            local appliedCondition = HarfordDnDConditions.ApplyOwned(request.conditionId,
                ConditionOptsFromRequest(request, request.sourceName ~= "" and request.sourceName or sender))
            if appliedCondition and HarfordDnDConditions.PublishOwnedCondition then
                HarfordDnDConditions.PublishOwnedCondition(request.conditionId, "apply")
            end
        elseif (tonumber(request.auraId) or 0) > 0 and HarfordAuras then
            HarfordAuras.ApplyById(request.auraId, "self", { addonName = "Harford" })
        end
    end

    local label = PlayerResultLabel(request, status, applied, summaries, rollText)
    BroadcastInfo(label, sender, true)
    -- La linea completa ya se publica como tirada. El ACK queda deliberadamente minimo
    -- para no desbordar SendAddonMessage con colores/nombres largos.
    local result = { id = request.id, status = status, applied = applied, label = "" }
    S.processed[cacheKey] = { expires = Now() + REQUEST_TTL, result = result }
    if sender and sender ~= "" then HarfordSync.SendAreaResult(PREFIX, sender, result) end
    return true, result
end

local function ValidateIncomingRequest(request)
    if type(request) ~= "table" or type(request.components) ~= "table" then return false end
    -- Sin componentes de daño solo es valido si trae condicion (conjuro de control puro).
    if #request.components == 0 and not (request.conditionId and request.conditionId ~= "") then return false end
    if request.mode == "save" then
        local validAbility = {
            Fuerza = true, Destreza = true, Constitucion = true,
            Inteligencia = true, Sabiduria = true, Carisma = true,
        }
        local dc = tonumber(request.dc)
        if not validAbility[request.ability] or not dc or dc < 1 or dc > 99 then return false end
        request.dc = dc
    elseif request.mode == "attack" then
        local attackTotal = tonumber(request.attackTotal)
        if not attackTotal or attackTotal < -100 or attackTotal > 200 then return false end
        request.attackTotal = attackTotal
    elseif request.mode ~= "auto" and request.mode ~= "heal" then
        return false
    end
    for _, component in ipairs(request.components) do
        if request.mode ~= "heal" and not (HarfordDamageTypes and HarfordDamageTypes.Exists and HarfordDamageTypes.Exists(component.damageType)) then
            return false
        end
        local amount = tonumber(component.amount)
        local maximum = tonumber(component.maximum)
        if not amount or not maximum or amount < 0 or amount > 10000 or maximum < 0 or maximum > 10000 then
            return false
        end
        component.amount, component.maximum = amount, maximum
    end
    if request.conditionId and request.conditionId ~= "" then
        if not (HarfordDnDConditions and HarfordDnDConditions.GetDefinition
            and HarfordDnDConditions.GetDefinition(request.conditionId)) then return false end
        if not CONDITION_DURATIONS[request.conditionDuration or "manual"] then return false end
        if request.conditionDuration == "rounds" and (tonumber(request.conditionTurns) or 0) <= 0 then return false end
        if request.conditionDuration == "save_at_turn_end"
            and (not CanonicalAbility(request.conditionSaveAbility) or (tonumber(request.conditionSaveDC) or 0) <= 0) then
            return false
        end
        if request.sourceGuid and request.sourceGuid ~= ""
            and (#request.sourceGuid > 64 or not request.sourceGuid:match("^[%w%-]+$")) then return false end
    end
    return true
end

function API.HandleRequest(message, sender, channel)
    if HarfordSync and HarfordSync.DeserializeAreaPositionRequest then
        local positionRequestId = HarfordSync.DeserializeAreaPositionRequest(message)
        if positionRequestId then
            if channel ~= "PARTY" and channel ~= "RAID" then
                return true
            end
            local position = CapturePlayerPosition()
            if position and sender and sender ~= "" then
                position.id = positionRequestId
                position.guid = UnitGUID and UnitGUID("player") or ""
                position.name = HarfordClassColors.UnitFullName and HarfordClassColors.UnitFullName("player")
                    or UnitName("player") or ""
                HarfordSync.SendAreaPositionResponse(PREFIX, sender, position)
            end
            return true
        end
    end
    if HarfordSync and HarfordSync.DeserializeAreaPositionResponse then
        local position = HarfordSync.DeserializeAreaPositionResponse(message)
        if position then
            local session = S.session
            if session and session.positionScan and session.positionScan.id == position.id then
                NormalizePositionSender(position, sender)
                session.positionScan.responses[position.guid] = position
                local added = ReevaluatePositionResponses(session)
                if added > 0 then RefreshFrame() end
            end
            return true
        end
    end
    if not (HarfordSync and HarfordSync.DeserializeAreaRequest) then return false end
    local request = HarfordSync.DeserializeAreaRequest(message)
    if not request then return false end
    if not IsTrustedAreaSender(sender) then return true end
    if not ValidateIncomingRequest(request) then
        if sender and sender ~= "" then
            HarfordSync.SendAreaResult(PREFIX, sender, { id = request.id, status = "invalid", applied = 0 })
        end
        return true
    end
    ResolvePlayerRequest(request, sender)
    return true
end

function API.HandleResult(message, sender)
    if not (HarfordSync and HarfordSync.DeserializeAreaResult) then return false end
    local result = HarfordSync.DeserializeAreaResult(message)
    if not result then return false end
    local session = S.session
    if not session then return true end
    for _, target in ipairs(session.targets or {}) do
        if target.requestId == result.id then
            local expected = target.unitName or ""
            local actual = tostring(sender or "")
            local expectedShort = Ambiguate and Ambiguate(expected, "short") or expected:match("^[^%-]+") or expected
            local actualShort = Ambiguate and Ambiguate(actual, "short") or actual:match("^[^%-]+") or actual
            if expected ~= "" and actual ~= expected and actualShort ~= expectedShort then return true end
            target.status = result.status .. " (" .. tostring(result.applied) .. ")"
            target.result = result
            break
        end
    end
    RefreshFrame()
    return true
end

local function MakeRequest(session, target, index)
    local request = {
        -- El turno entra en el id para que la re-resolucion de zona NO sea deduplicada por el receptor.
        id = session.id .. "." .. tostring(session.turn or 1) .. "." .. tostring(index),
        mode = session.definition.resolution,
        ability = session.definition.saveAbility,
        dc = session.definition.dc,
        success = session.definition.success,
        auraId = session.definition.auraId,
        conditionId = session.definition.conditionId,
        conditionDuration = session.definition.conditionDuration,
        conditionTurns = session.definition.conditionTurns,
        conditionSaveAbility = session.definition.conditionSaveAbility,
        conditionSaveDC = session.definition.conditionSaveDC,
        conditionApplySaveAbility = session.definition.conditionApplySaveAbility,
        conditionApplySaveDC = session.definition.conditionApplySaveDC,
        conditionPersist = session.definition.conditionPersist,
        sourceGuid = session.context.sourceGuid,
        sourceName = session.context.sourceName,
        label = session.definition.networkLabel,
        components = session.rolledComponents,
    }
    if request.mode == "attack" then
        local chosen, dieA, dieB, critTag = HarfordDnDCalc.RollD20Full("attack", {
            actorGuid = session.context.sourceGuid,
            actorConditionIds = session.sourceConditionIds,
            targetGuid = target.guid,
            targetConditionIds = target.conditionIds,
            attackRange = session.definition.attackRange or "ranged",
        })
        local die = chosen
        request.attackTotal = die + session.definition.attackBonus
        request.critical = HarfordDnDCombat.IsCriticalRollTag(critTag) and "critical"
            or critTag == "PIFIA" and "fumble" or "normal"
        target.attackDie = die
    end
    return request
end

-- Anuncia UNA sola tirada de daño BASE del area (los dados se tiran una vez para todas las
-- victimas). El numero aplicado a cada victima se publica por separado en su `BroadcastInfo`
-- y puede diferir del base: salvacion superada (mitad/nada), critico de ataque (maximo) y
-- resistencias/inmunidades/vulnerabilidades por tipo. No leer este total como el daño final.
local function BroadcastSharedRoll(session, details)
    local first = session.rolledComponents[1]
    local modifiers = DamageLabel(first.damageType)
    for i = 2, #session.rolledComponents do
        local c = session.rolledComponents[i]
        modifiers = modifiers .. " |cff66ccff" .. tostring(c.amount) .. "|r " .. DamageLabel(c.damageType)
    end
    HarfordDnDRolls.Broadcast({
        type = session.definition.resolution == "heal" and "heal" or "damage",
        label = (session.definition.resolution == "heal" and "Curacion " or "")
            .. session.definition.label .. " (" .. ShapeText(session.definition) .. ")",
        total = first.amount,
        dice = details,
        modifiers = modifiers,
    })
end

function API.Resolve()
    local session = S.session
    if not session or session.resolved or #session.targets == 0 then return false end
    -- El coste (onCommit) se paga UNA sola vez; las re-resoluciones de zona (RepeatTurn) no.
    if not session.committed and type(session.context.onCommit) == "function" then
        local ok, err = session.context.onCommit(session.definition)
        if ok == false then Print(err or "No se pudo consumir el uso o recurso."); return false end
    end
    session.committed = true
    if session.context.abilityFeature and HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        HarfordDnDRolls.BroadcastAbility(session.context.abilityFeature)
    end
    session.resolved = true
    if type(session.context.beforeRoll) == "function" then
        session.context.beforeRoll(session.definition)
    end
    if session.definition.rollPerTarget then
        session.rolledComponents, session.rollDetails = nil, nil
    elseif session.definition.resolution == "heal" then
        session.rolledComponents, session.rollDetails = RollHealingComponents(session.definition)
    else
        session.rolledComponents, session.rollDetails = RollComponents(session.definition)
    end
    -- Condicion pura (sin daño): no hay tirada de daño compartida que anunciar.
    if session.rolledComponents and #session.rolledComponents > 0 and not session.definition.rollPerTarget then
        BroadcastSharedRoll(session, session.rollDetails)
    end
    session.pendingNpc, session.pendingNpcIndex = {}, 1

    for index, target in ipairs(session.targets) do
        if session.definition.rollPerTarget then
            if session.definition.resolution == "heal" then
                session.rolledComponents, session.rollDetails = RollHealingComponents(session.definition)
            else
                session.rolledComponents, session.rollDetails = RollComponents(session.definition)
            end
            if #session.rolledComponents > 0 then
                local first = session.rolledComponents[1]
                HarfordDnDRolls.Broadcast({
                    type = session.definition.resolution == "heal" and "heal" or "damage",
                    label = (session.definition.resolution == "heal" and "Curacion " or "")
                        .. session.definition.label .. " " .. tostring(index),
                    total = first.amount,
                    dice = session.rollDetails,
                    modifiers = DamageLabel(first.damageType),
                })
            end
        end
        local request = MakeRequest(session, target, index)
        target.requestId = request.id
        if target.kind == "player" then
            if target.guid == (UnitGUID and UnitGUID("player")) then
                local _ok, result = ResolvePlayerRequest(request, nil)
                target.status = result and (result.status .. " (" .. tostring(result.applied) .. ")") or "Error"
                target.result = result
            elseif target.unitName and target.unitName ~= "" then
                local ok, err = HarfordSync.SendAreaRequest(PREFIX, target.unitName, request)
                target.status = ok and "Esperando" or "Error"
                if not ok then target.error = err end
                if ok and C_Timer and C_Timer.After then
                    local sessionId, requestId = session.id, request.id
                    C_Timer.After(RESPONSE_TIMEOUT, function()
                        local current = S.session
                        if not current or current.id ~= sessionId then return end
                        for _, item in ipairs(current.targets or {}) do
                            if item.requestId == requestId and item.status == "Esperando" then
                                item.status = "Sin confirmar"
                                RefreshFrame()
                                break
                            end
                        end
                    end)
                end
            else
                target.status = "Sin nombre"
            end
        else
            target.status = "Pendiente"
            session.pendingNpc[#session.pendingNpc + 1] = { target = target, request = request }
        end
    end
    RefreshFrame()
    API.TryResolvePendingNpc()
    return true
end

-- Zona persistente (Nube de Dagas, invocaciones): nuevo turno -> re-marcar quien sigue dentro y
-- re-aplicar daño SIN volver a pagar mana (gate `committed`). Avanza el turno para ids frescos.
function API.RepeatTurn()
    local session = S.session
    if not (session and session.zone and session.resolved) then return false end
    session.turn = (session.turn or 1) + 1
    session.resolved = false
    session.pendingNpc, session.pendingNpcIndex = {}, 1
    for _, target in ipairs(session.targets or {}) do
        target.status, target.result, target.requestId = "Marcado", nil, nil
    end
    RefreshFrame()
    Print("Zona turno " .. tostring(session.turn) .. ": re-marca las victimas dentro y pulsa Resolver.")
    return true
end

local function ResolveNpcEntry(entry)
    local request, target = entry.request, entry.target
    local affected, status, rollText, critical = false, "invalid", "", false
    if request.mode == "heal" then
        affected, status, rollText = true, "hit", "Curacion"
    elseif request.mode == "save" then
        local bonus = HarfordDnDCombat.GetSaveBonusForUnit("target", request.ability)
        local autoFail = HarfordDnDConditions and HarfordDnDConditions.IsSaveAutoFailed
            and HarfordDnDConditions.IsSaveAutoFailed("target", request.ability)
        local mode = HarfordDnDConditions and HarfordDnDConditions.ResolveRollMode
            and HarfordDnDConditions.ResolveRollMode("normal", "save", { actorUnit = "target", ability = request.ability }) or "normal"
        local die = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(mode))
        local total = die + bonus
        request.saved = not autoFail and total >= request.dc
        affected = not request.saved or request.success == "half"
        status = request.saved and "saved" or "failed"
        rollText = string.format("Salv %s: %d (%d%+d vs CD %d)", request.ability, total, die, bonus, request.dc)
    elseif request.mode == "auto" then
        affected, status, rollText = true, "hit", "Impacto automatico"
    else
        critical = request.critical == "critical"
        local critTag = critical and "CRITICO" or request.critical == "fumble" and "PIFIA" or ""
        local armorClass, hit = HarfordDnDCombat.ResolveArmorClassOutcome(request.attackTotal, critTag, "target")
        affected = hit == true
        status = affected and "hit" or "miss"
        rollText = string.format("Ataque %d vs CA %s", request.attackTotal, tostring(armorClass or "?"))
    end
    local applied, summaries
    if request.mode == "heal" then
        local total = 0
        for _, component in ipairs(request.components or {}) do total = total + (tonumber(component.amount) or 0) end
        applied = ApplyNpcHealing(total)
        summaries = { tostring(applied) .. " curacion" }
    else
        applied, summaries = ApplyComponents("target", request, affected, critical)
        if applied > 0 and not HarfordDnDCombat.ApplyWeaponDamageToNpc(applied, critical) then
            target.status = "No aplicado"
            Print("No se pudo modificar la vida del NPC seleccionado.")
            return false
        end
    end
    local conditionLands = AreaEffectLands(request.mode, status)
    if conditionLands and request.conditionId and request.conditionId ~= "" then
        local saved, detail = ResolveConditionApplySave("target", request)
        if detail then
            rollText = rollText ~= "" and (rollText .. " | " .. detail) or detail
            conditionLands = not saved
        end
    end
    if conditionLands then
        if request.conditionId and request.conditionId ~= "" and HarfordDnDConditions then
            local ok, err = HarfordDnDConditions.ApplyToUnit("target", request.conditionId,
                ConditionOptsFromRequest(request, request.sourceName))
            if not ok then Print(err == "immune" and (target.name .. " es inmune a la condicion.") or tostring(err)) end
        elseif (tonumber(request.auraId) or 0) > 0 and HarfordAuras then
            HarfordAuras.ApplyById(request.auraId, "npc", { addonName = "Harford" })
        end
    end
    BroadcastInfo(FormatVictimResult(target.name, request, status, applied, summaries, rollText))
    target.status = status .. " (" .. tostring(applied) .. ")"
    return true
end

function API.TryResolvePendingNpc()
    local session = S.session
    if not session or not session.resolved then return false end
    local entry = session.pendingNpc and session.pendingNpc[session.pendingNpcIndex or 1]
    if not entry then RefreshFrame(); return false end
    if not (UnitExists and UnitExists("target") and not (UnitIsPlayer and UnitIsPlayer("target")) and UnitGUID) then
        RefreshFrame(); return false
    end
    if UnitGUID("target") ~= entry.target.guid then RefreshFrame(); return false end
    if not ResolveNpcEntry(entry) then RefreshFrame(); return false end
    session.pendingNpcIndex = (session.pendingNpcIndex or 1) + 1
    RefreshFrame()
    -- Varias aplicaciones (rayos, proyectiles o curacion) pueden recaer sobre el mismo
    -- NPC. Mientras el siguiente GUID sea el actual se resuelve sin pedir al usuario que
    -- vuelva a seleccionar exactamente el mismo objetivo.
    local nextEntry = session.pendingNpc[session.pendingNpcIndex]
    if nextEntry and nextEntry.target and nextEntry.target.guid == UnitGUID("target") then
        API.TryResolvePendingNpc()
    end
    return true
end

function API.SkipPendingNpc()
    local session = S.session
    if not session or not session.pendingNpc then return false end
    local entry = session.pendingNpc[session.pendingNpcIndex or 1]
    if not entry then return false end
    entry.target.status = "Omitido"
    session.pendingNpcIndex = (session.pendingNpcIndex or 1) + 1
    RefreshFrame()
    API.TryResolvePendingNpc()
    return true
end

function API.Cancel()
    S.session = nil
    if S.frame then S.frame:Hide() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
    if S.session then
        RefreshFrame()
        if S.session.resolved then API.TryResolvePendingNpc() end
    end
end)
