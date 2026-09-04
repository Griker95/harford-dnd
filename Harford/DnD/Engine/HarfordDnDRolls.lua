-- Serializacion, render y emision de tiradas Harford DnD.
-- Mantiene el formato de red historico DND5EARC: 10 campos separados por "^",
-- escapando separadores dentro de campos de texto.

HarfordDnDRolls = HarfordDnDRolls or {}

local ADDON_PREFIX = "DND5EARC"
local ROLL_SOUND_KIT = 36629
local MAX_SAFE_PAYLOAD_BYTES = 240

local GREEN = "|cff00ff00"
local RED   = "|cffff3333"
local ENDCLR = "|r"

local toN = HarfordDnDStore.ToNumber

local function fmtSigned(n)
    n = toN(n, 0)
    if n >= 0 then return "+" .. n end
    return tostring(n)
end

local function ColorSigned(n)
    n = toN(n, 0)
    if n < 0 then return RED .. fmtSigned(n) .. ENDCLR end
    return GREEN .. fmtSigned(n) .. ENDCLR
end

-- Publico: cualquier etiqueta que muestre un bono usa este mismo criterio de color en vez de
-- copiarlo. Verde lo que suma, rojo lo que resta.
HarfordDnDRolls.ColorSigned = ColorSigned

local function EscapeRollField(value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%25")
    value = value:gsub("%^", "%%5E")
    value = value:gsub("\r", "%%0D")
    value = value:gsub("\n", "%%0A")
    return value
end

local function UnescapeRollField(value)
    if value == nil then return nil end
    value = tostring(value)
    value = value:gsub("%%0A", "\n")
    value = value:gsub("%%0D", "\r")
    value = value:gsub("%%5E", "^")
    value = value:gsub("%%25", "%%")
    return value
end

-- Nombre del JUGADOR, sin pasar por la ficha aplicada. `GetDisplayName` antepone el `rollName` del
-- contexto, que es el del NPC cuando hay una ficha de DM cargada: con ella puesta, las tiradas
-- DEFENSIVAS del propio jugador (su salvacion, el dano que recibe) salian a nombre del NPC. Esas
-- lineas hablan de lo que te pasa a TI, asi que llevan tu nombre siempre.
function HarfordDnDRolls.GetOwnName()
    if HarfordTRP3 and HarfordTRP3.GetUnitRPName then
        local trpName = HarfordTRP3.GetUnitRPName("player")
        if trpName and trpName ~= "" then return trpName end
    end
    return (UnitName and UnitName("player")) or "Unknown"
end

function HarfordDnDRolls.GetDisplayName()
    local state = HarfordDnDContext and HarfordDnDContext.State
    if state and state.rollName and state.rollName ~= "" then
        return state.rollName
    end
    if HarfordTRP3 and HarfordTRP3.GetUnitRPName then
        local trpName = HarfordTRP3.GetUnitRPName("player")
        if trpName and trpName ~= "" then
            return trpName
        end
    end
    return UnitName("player") or "Unknown"
end

-- Emision comun de habilidades del Libro. Centraliza el hyperlink TRP3 para que
-- ninguna ruta especial vuelva a publicar el formato heredado "usa <nombre>".
-- Cabecera de dano AGREGADA POR TIPO. El render de una tirada es "<total> <modifiers>", asi que el
-- primer tipo aporta el numero de cabecera y los demas van dentro de modifiers: "6 Cortante 10 Frio".
-- Los numeros de los tipos extra se colorean igual que el de cabecera para que se lean como totales
-- y no como bonificadores.
--
-- Vive aqui porque la usan DOS rutas: el dano de arma del jugador y el dano multicomponente de una
-- accion NPC. Estaba duplicada literalmente en las dos.
--
-- Devuelve `headlineTotal, modifiersTxt`. OJO: `headlineTotal` es el total del PRIMER tipo, no la
-- suma de todos -- es lo que exige el formato del render, y por eso el campo `total` de un
-- broadcast de dano no se puede leer como el gran total.
function HarfordDnDRolls.FormatDamageHeader(dmgTypeOrder, dmgTypeMap, totalPorDefecto)
    local headlineTotal, modifiersTxt = totalPorDefecto, ""
    for i, t in ipairs(dmgTypeOrder or {}) do
        local e = dmgTypeMap and dmgTypeMap[t]
        if e then
            local key = tostring(t or "")
            if HarfordDamageTypes and HarfordDamageTypes.FromWord then
                key = HarfordDamageTypes.FromWord(key) or key
            end
            local name = (HarfordDamageTypes and HarfordDamageTypes.GetLabel
                and HarfordDamageTypes.GetLabel(key)) or key
            local mk = (e.marker and e.marker ~= "" and (" " .. e.marker)) or ""
            if i == 1 then
                headlineTotal = e.total
                modifiersTxt = name .. mk
            else
                modifiersTxt = modifiersTxt .. " |cff66ccff" .. tostring(e.total) .. "|r " .. name .. mk
            end
        end
    end
    return headlineTotal, modifiersTxt
end

function HarfordDnDRolls.BroadcastAbility(feature, opts)
    if not feature then return false end
    opts = opts or {}
    -- Economia de turno: solo se cobra a los rasgos que DECLARAN su coste (`cast`). El resto no
    -- se cuenta, porque `type = "accion"` es la categoria generica y en 5e incluye las adicionales:
    -- adivinarlo daria un contador equivocado, que es peor que no tenerlo.
    if opts.skipTurnCost ~= true and HarfordDnDConditions and HarfordDnDConditions.Turn then
        -- Si el rasgo declara un coste y NO cabe, no se anuncia ni se hace. `SpendForFeature`
        -- devuelve nil cuando el rasgo no declara nada, que no es lo mismo que un false.
        if HarfordDnDConditions.Turn.SpendForFeature(feature) == false then return false end
        -- Y al reves: hay rasgos que CONCEDEN una accion en vez de costarla.
        HarfordDnDConditions.Turn.GrantForFeature(feature)
    end
    local label = HarfordTRP3 and HarfordTRP3.GetAbilityChatLink
        and HarfordTRP3.GetAbilityChatLink(feature)
    if not label or label == "" then
        label = "|cff66ccff[" .. tostring(feature.name or "Habilidad") .. "]|r"
    end
    -- `skipBroadcast`: se ha cobrado y comprobado, pero no se difunde. Lo usa quien va a sacar su
    -- propia linea --una tirada con el nombre de la accion delante-- y no quiere dos diciendo lo
    -- mismo. El coste no depende de cuantas lineas salgan.
    if not opts.skipBroadcast then
        HarfordDnDRolls.Broadcast({
            type = "info",
            label = label,
            targetUnit = opts.targetUnit,
            player = opts.player,
            nameColor = opts.nameColor,
        })
    end
    return true
end

-- Compacta los item links para la RED: el link completo lleva una larga cadena de stats
-- (`|Hitem:18832:0:0:...:80:::::|h`) que puede desbordar el limite de ~255 bytes del addon
-- message. Lo reducimos a su forma minima `|Hitem:<id>|h[<nombre>]|h|r`: SIGUE SIENDO
-- CLICABLE en el cliente ajeno (WoW reconstruye el tooltip desde el ID) y ocupa pocos
-- bytes. Se conservan color (`|c..|r`), nombre visible y pipes escapados para que la
-- tirada salga IGUAL en origen y destino (incluido el contador coloreado de Salv Muerte).
local function CompactItemLinks(text)
    text = tostring(text or "")
    text = text:gsub("(|Hitem:%d+)[^|]-|h", "%1|h")  -- deja solo el ID dentro del enlace
    return text
end

-- Tras recortar la label, cierra/elimina codigos de color partidos para que no "sangre" color.
local function SanitizeLabelTail(label)
    label = label:gsub("|$", "")
    label = label:gsub("|c%x?%x?%x?%x?%x?%x?%x?$", "")  -- |c... incompleto al final
    local _, opens = label:gsub("|c%x%x%x%x%x%x%x%x", "")
    local _, closes = label:gsub("|r", "")
    if opens > closes then label = label .. "|r" end
    return label
end

-- Label para la red: item links compactados (clicables) y acotada por seguridad. El corte
-- duro a 200 tambien se sanea, para que una label larga no deje un `|c` partido (el guard
-- de Serialize solo actua si el payload pasa de MAX_SAFE_PAYLOAD_BYTES).
local function NetworkLabel(label)
    label = CompactItemLinks(label or "")
    if #label > 200 then label = SanitizeLabelTail(label:sub(1, 200)) end
    return label
end

-- Se expone porque el mensaje de dano tambien lleva etiqueta ahora: la victima publica la linea
-- con el arma del atacante, y ese enlace hay que compactarlo igual que en una tirada.
HarfordDnDRolls.NetworkLabel = NetworkLabel

function HarfordDnDRolls.Serialize(data)
    data = data or {}
    local label = NetworkLabel(data.label)
    local function build(lbl)
        return string.format("%s^%s^%s^%d^%s^%s^%s^%s^%s^%s",
            EscapeRollField(data.type or "roll"),
            EscapeRollField(data.player or HarfordDnDRolls.GetDisplayName()),
            EscapeRollField(lbl),
            data.total or 0,
            EscapeRollField(data.dice or ""),
            EscapeRollField(data.modifiers or ""),
            EscapeRollField(data.critical or ""),
            EscapeRollField(data.mode or ""),
            EscapeRollField(data.miscBonus or ""),
            EscapeRollField(data.nameColor or "")
        )
    end
    local payload = build(label)
    -- Recorta SOLO la label (la parte variable larga: notas/maniobras) hasta que el payload
    -- completo quepa en un addon message (~255 bytes; HarfordSync.Send NO trocea tiradas, asi que
    -- un payload mas largo se descarta y la tirada NO llega al target). Usa el mismo umbral seguro
    -- que el aviso de log. La tirada SIEMPRE llega, aunque pierda el flavor del final de la label.
    while #payload > MAX_SAFE_PAYLOAD_BYTES and #label > 0 do
        label = SanitizeLabelTail(label:sub(1, math.max(0, #label - 12)))
        payload = build(label)
    end
    return payload
end

function HarfordDnDRolls.Deserialize(msg)
    local parts = {strsplit("^", msg)}
    if #parts < 8 then return nil end
    local color = UnescapeRollField(parts[10])
    return {
        type      = UnescapeRollField(parts[1]),
        player    = UnescapeRollField(parts[2]),
        label     = UnescapeRollField(parts[3]),
        total     = tonumber(parts[4]) or 0,
        dice      = UnescapeRollField(parts[5]),
        modifiers = UnescapeRollField(parts[6]),
        critical  = UnescapeRollField(parts[7]),
        mode      = UnescapeRollField(parts[8]),
        miscBonus = UnescapeRollField(parts[9]),
        nameColor = (color and color ~= "") and color or nil,
    }
end

-- Paleta del render de tiradas. Vive aqui y no dentro de `DisplayInChat` porque hay lineas que se
-- construyen enteras fuera (la de fabricar, que no encaja en el orden generico) y deben usar los
-- MISMOS colores: duplicarlos era garantizar que un dia dejaran de coincidir.
HarfordDnDRolls.COLORS = {
    roll   = "|cff66ccff",
    detail = "|cffb0b0b0",
    crit   = "|cff00ff00",
    fumble = "|cffff3333",
    close  = "|r",
}

function HarfordDnDRolls.DisplayInChat(data)
    if not data then return end

    local COLOR_ROLL = HarfordDnDRolls.COLORS.roll
    local COLOR_DETAIL = HarfordDnDRolls.COLORS.detail
    local COLOR_CRIT = HarfordDnDRolls.COLORS.crit
    local COLOR_FUMBLE = HarfordDnDRolls.COLORS.fumble

    local parts = {}
    local playerName = data.player or UnitName("player") or "Unknown"
    local nameColor = data.nameColor and ("|cff" .. data.nameColor) or "|cffffcc00"
    local prefix = HarfordChat and HarfordChat.GetPrefix and HarfordChat.GetPrefix() or "|cff00ccff[Harford]|r"
    table.insert(parts, prefix .. " " .. nameColor .. playerName .. ENDCLR)

    -- Mensajes informativos de estado (no son tirada), sin ": total".
    if data.type == "info" then
        local out = parts[1] .. " " .. (data.label or "")
        DEFAULT_CHAT_FRAME:AddMessage(out)
        if ChatFrame2 then ChatFrame2:AddMessage(out) end
        return
    end

    local modeStr = ""
    if data.mode == "V" then
        modeStr = " " .. COLOR_CRIT .. "[V]" .. ENDCLR
    elseif data.mode == "D" then
        modeStr = " " .. COLOR_FUMBLE .. "[D]" .. ENDCLR
    end

    -- Sin ":" entre la etiqueta y el total: lo que hace resaltar el resultado es el color, y los
    -- dos puntos solo anaden ruido en una linea que ya distingue etiqueta, total, detalle y
    -- desenlace por su tinte.
    local labelStr = parts[1] .. modeStr .. " " .. (data.label or "Tirada") .. " "
        .. COLOR_ROLL .. tostring(data.total or 0) .. ENDCLR

    local damageTypeStr = ""
    if (data.type == "damage" or data.type == "heal") and data.modifiers and data.modifiers ~= "" then
        damageTypeStr = " " .. data.modifiers
    end

    -- Desenlace de la tirada: verde lo que sale bien, rojo lo que sale mal.
    --
    -- Las variantes acentuadas se aceptan tal cual porque el texto viaja por la red y llega como
    -- lo escribio el emisor: CRITICO y CR\195\141TICO son el mismo estado.
    local VERDE = { CRITICO = true, ["CR\195\141TICO"] = true,
                    EXITO = true, ["\195\137XITO"] = true }
    local ROJO = { PIFIA = true, FALLO = true }
    local critStr = ""
    if VERDE[data.critical] then
        critStr = " " .. COLOR_CRIT .. data.critical .. ENDCLR
    elseif ROJO[data.critical] then
        critStr = " " .. COLOR_FUMBLE .. data.critical .. ENDCLR
    end

    local detailStr = ""
    local miscOutsideStr = ""

    if data.dice and data.dice ~= "" then
        if data.type ~= "damage" and data.modifiers and data.modifiers ~= "" then
            local modifiersText = tostring(data.modifiers or "")
            local miscRaw = tonumber(data.miscBonus) or 0

            if miscRaw ~= 0 then
                local miscText = fmtSigned(miscRaw)
                local pos = string.find(modifiersText, miscText, 1, true)

                if pos then
                    modifiersText = string.sub(modifiersText, 1, pos - 1)
                        .. string.sub(modifiersText, pos + string.len(miscText))
                end

                miscOutsideStr = ColorSigned(miscRaw)
            end

            detailStr = " " .. COLOR_DETAIL .. "(" .. data.dice .. modifiersText .. ")" .. ENDCLR .. miscOutsideStr
        else
            detailStr = " " .. COLOR_DETAIL .. "(" .. data.dice .. ")" .. ENDCLR
        end
    end

    local output = labelStr .. damageTypeStr .. detailStr .. critStr
    DEFAULT_CHAT_FRAME:AddMessage(output)
    if ChatFrame2 then
        ChatFrame2:AddMessage(output)
    end
end

local function PlayRollSound(rollData)
    -- "info" = mensaje de estado (sin total); "static" = valor calculado sin tirada
    -- (ej. CD Conjuro): se muestra con su total pero NO suena como un dado.
    if not rollData or rollData.type == "info" or rollData.type == "static" then return end
    if not rollData.dice or rollData.dice == "" or rollData.dice == "-" then return end

    if TRP3_API and TRP3_API.ui and TRP3_API.ui.misc and TRP3_API.ui.misc.playSoundKit then
        TRP3_API.ui.misc.playSoundKit(ROLL_SOUND_KIT, "SFX")
    elseif PlaySound then
        PlaySound(ROLL_SOUND_KIT, "SFX")
    end
end

function HarfordDnDRolls.Broadcast(rollData)
    rollData = rollData or {}
    local state = HarfordDnDContext and HarfordDnDContext.State
    local displayColor = state and state.active
        and state.rollColor
        or (HarfordTRP3 and HarfordTRP3.GetUnitNameColor and HarfordTRP3.GetUnitNameColor("player") or nil)

    rollData.nameColor = rollData.nameColor or displayColor

    local channel = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    local payload = HarfordDnDRolls.Serialize(rollData)
    if channel and HarfordSync and HarfordSync.Send then
        local ok, err = HarfordSync.Send(ADDON_PREFIX, payload, channel)
        if HarfordDebug and HarfordDebug.Log and (not ok or string.len(payload) > MAX_SAFE_PAYLOAD_BYTES) then
            HarfordDebug.Log("roll send", tostring(rollData.type or "roll"), "bytes=" .. tostring(string.len(payload)), ok and "OK" or tostring(err))
        end
    elseif HarfordDebug and HarfordDebug.Log then
        HarfordDebug.Log("roll send", tostring(rollData.type or "roll"), "sin canal")
    end

    -- Ataques contra otro jugador: ademas del canal de grupo, susurra la tirada al objetivo
    -- si NO esta en tu grupo (asi la ve aunque no compartais raid/grupo, o estes solo). Si SI
    -- esta en el grupo, ya la recibe por RAID/PARTY y no se duplica.
    local tUnit = rollData.targetUnit
    if tUnit and UnitExists and UnitExists(tUnit) and UnitIsPlayer and UnitIsPlayer(tUnit)
        and not (UnitIsUnit and UnitIsUnit(tUnit, "player")) and HarfordSync and HarfordSync.Send then
        local inGroup = (channel == "RAID" and UnitInRaid and UnitInRaid(tUnit))
            or (channel == "PARTY" and UnitInParty and UnitInParty(tUnit))
        if not inGroup then
            local name = HarfordClassColors.UnitFullName(tUnit)
            if name and name ~= "" then
                HarfordSync.Send(ADDON_PREFIX, payload, "WHISPER", name)
            end
        end
    end

    HarfordDnDRolls.DisplayInChat({
        type      = rollData.type,
        player    = rollData.player or HarfordDnDRolls.GetDisplayName(),
        nameColor = rollData.nameColor or displayColor,
        label     = rollData.label,
        total     = rollData.total,
        dice      = rollData.dice,
        modifiers = rollData.modifiers,
        critical  = rollData.critical,
        mode      = rollData.mode,
        miscBonus = rollData.miscBonus,
    })

    PlayRollSound(rollData)
end

------------------------------------------------------------
-- MODIFICAR UNA TIRADA YA HECHA
--
-- 5e tiene una familia entera de rasgos que se usan DESPUES de tirar y antes de saber si acertaste:
-- los puntos de heroe, los dados de enfoque del Cazador (Ataque Preciso, Llamada de lo Salvaje),
-- Tacticas de Supervivencia... Todos hacen lo mismo: tiran un dado, lo suman a algo que ya esta
-- tirado y lo dicen en mesa, porque cambia un numero que los demas ya han visto.
--
-- Esto vivia entero dentro de los puntos de heroe, con su 1d6 escrito dentro, asi que ningun otro
-- rasgo podia usarlo. Aqui es generico y lo declara cada rasgo.
--
-- La ventana se cierra sola: se modifica `_lastRoll`, y la siguiente tirada la sustituye.
------------------------------------------------------------

-- Tipos de tirada sobre los que tiene sentido intervenir. El DANO queda fuera a proposito: estos
-- rasgos modifican el d20, no la herida.
HarfordDnDRolls.MODIFIABLE_ROLLS = {
    roll = true, attack = true, save = true, ability = true, skill = true,
}

-- Registra una CURACION como ultima tirada. Las tiradas de d20 ya se registran en `DoRollEx`; las
-- curaciones no lo hacian, y sin registro no habia nada que repetir.
--
-- Se guardan los DADOS, no solo el total: repetir una curacion exige saber cuantos dados eran y de
-- que caras. `aplicadoA` dice a quien se le sumo, para poder ajustar la diferencia al repetir.
function HarfordDnDRolls.RecordHealRoll(datos)
    if type(datos) ~= "table" then return end
    _G.DND5E_ARC_API = _G.DND5E_ARC_API or {}
    _G.DND5E_ARC_API._lastRoll = {
        ok = true, kind = "heal",
        label = tostring(datos.label or "Curacion"),
        total = math.max(0, math.floor(tonumber(datos.total) or 0)),
        healDice = datos.healDice,          -- { { count, sides, bonus } }
        healRolls = datos.healRolls,        -- valores concretos que salieron
        aplicadoA = datos.aplicadoA,        -- "self" | nombre de jugador | nil
        timestamp = (time and time()) or 0,
    }
end

function HarfordDnDRolls.GetLastRoll()
    local api = _G.DND5E_ARC_API
    local last = api and api._lastRoll
    if type(last) ~= "table" then return nil, "No hay ninguna tirada reciente" end
    return last
end

-- El campo real es `kind`; `type`/`rollType` se aceptan porque otras rutas los han usado. Los
-- puntos de heroe leian solo `type`, que NUNCA existe en el registro de tirada: su filtro caia
-- siempre en "roll" y dejaba gastar un punto en cualquier cosa.
function HarfordDnDRolls.RollKind(roll)
    return tostring((roll and (roll.kind or roll.rollType or roll.type)) or "roll"):lower()
end

-- Tira el dado de un modificador. Devuelve el dado bruto y lo que se suma de verdad (la Llamada de
-- lo Salvaje suma solo la MITAD, redondeando hacia arriba).
local function RollModifierAmount(spec)
    local bruto = tonumber(spec.amount)
    if not bruto then
        local caras = math.max(1, math.floor(tonumber(spec.die) or 0))
        bruto = math.random(1, caras)
    end
    return bruto, spec.half and math.ceil(bruto / 2) or bruto
end

local function ModifierLabel(spec)
    return tostring(spec.label or "Modificador")
end

-- Suma a la ULTIMA tirada y lo anuncia.
--
-- spec = {
--   label    texto visible
--   die      caras del dado a tirar (o `amount` para una cantidad fija)
--   half     suma solo la mitad, redondeando hacia arriba
--   applies  { attack = true, ... } tipos de tirada admitidos
--   markKey  clave con la que se marca la tirada, para no usarlo dos veces sobre la misma
-- }
--
-- Devuelve ok, total nuevo, error, dado bruto, cantidad sumada.
-- Repite los dados de la ULTIMA curacion y se queda con el resultado nuevo, salga mejor o peor:
-- repetir es repetir, y quedarse con el mejor de los dos seria otra regla.
--
-- Devuelve ok, total nuevo, error, total viejo.
function HarfordDnDRolls.RerollLastHeal(spec)
    spec = spec or {}
    local last, err = HarfordDnDRolls.GetLastRoll()
    if not last then return false, nil, err end
    if HarfordDnDRolls.RollKind(last) ~= "heal" then
        return false, nil, "La ultima tirada no fue una curacion"
    end
    if type(last.healDice) ~= "table" or #last.healDice == 0 then
        return false, nil, "Esa curacion no tenia dados que repetir"
    end
    local marca = tostring(spec.markKey or "healRerolled")
    if last[marca] then return false, nil, "Ya repetiste esa curacion" end

    local nuevos, total = {}, 0
    for _, grupo in ipairs(last.healDice) do
        local caras = math.max(2, math.floor(tonumber(grupo.sides) or 6))
        for _ = 1, math.max(0, math.floor(tonumber(grupo.count) or 0)) do
            local v = HarfordDnDCalc and HarfordDnDCalc.RollDie and HarfordDnDCalc.RollDie(caras)
                or math.random(1, caras)
            nuevos[#nuevos + 1] = v
            total = total + v
        end
        total = total + (tonumber(grupo.bonus) or 0)
    end
    total = math.max(0, total)

    local anterior = tonumber(last.total) or 0
    last.total, last.healRolls, last[marca] = total, nuevos, true

    HarfordDnDRolls.Broadcast({
        type = "heal",
        label = tostring(spec.label or "Repetir curacion") .. ": " .. tostring(last.label or ""),
        total = total,
        dice = table.concat(nuevos, "+"),
        modifiers = string.format("antes %d", anterior),
    })
    return true, total, nil, anterior
end

function HarfordDnDRolls.ModifyLastRoll(spec)
    spec = spec or {}
    local last, err = HarfordDnDRolls.GetLastRoll()
    if not last then return false, nil, err end

    local marca = tostring(spec.markKey or "rollModified")
    if last[marca] then return false, nil, "Ya usaste eso en esa tirada" end

    local admitidos = spec.applies or HarfordDnDRolls.MODIFIABLE_ROLLS
    if not admitidos[HarfordDnDRolls.RollKind(last)] then
        return false, nil, "En esa tirada no se puede usar"
    end

    local bruto, suma = RollModifierAmount(spec)
    local anterior = tonumber(last.total) or 0
    local nuevo = anterior + suma
    last.total = nuevo
    last[marca] = true

    local detalle
    if spec.amount then
        detalle = string.format("%d + %d", anterior, suma)
    elseif spec.half then
        detalle = string.format("%d + d%d: %d / 2 = %d", anterior, tonumber(spec.die) or 0, bruto, suma)
    else
        detalle = string.format("%d + d%d: %d", anterior, tonumber(spec.die) or 0, bruto)
    end

    -- Si la tirada guardo contra que CA iba, se dice si AHORA la supera: es justo lo que el
    -- jugador quiere saber al gastar el dado, y ya no se ve en la linea original.
    local extra = ""
    local ca = tonumber(last.armorClass)
    if ca then
        -- `>`, no `>=`: en esta mesa EL DEFENSOR GANA LOS EMPATES, que es una divergencia
        -- deliberada del manual (5e impacta al igualar la CA). `HarfordDnDCombat` y
        -- `HarfordDnDArea` ya lo hacian asi; esta linea decia lo contrario, y la misma tirada
        -- contra la misma CA salia "No superada" al atacar y "Superada" al gastar el dado.
        extra = string.format(" vs CA %d %s", ca,
            nuevo > ca and "|cff00ff00EXITO|r" or "|cffff3333FALLO|r")
    end

    HarfordDnDRolls.Broadcast({
        type = "roll",
        label = ModifierLabel(spec) .. (last.label and (": " .. tostring(last.label)) or ""),
        total = nuevo,
        dice = detalle,
        modifiers = extra,
    })
    return true, nuevo, nil, bruto, suma
end

-- Tira el dado y anuncia el numero, SIN tocar ninguna tirada. Es para lo que no modifica un d20
-- sino otra cosa que el cliente no lleva: tu CA contra ese ataque, la CD de concentracion que
-- provoca tu disparo, el dano del primer impacto de tu mascota. El numero sale aqui; donde se
-- aplica lo hace la mesa.
function HarfordDnDRolls.AnnounceRollValue(spec)
    spec = spec or {}
    local bruto, suma = RollModifierAmount(spec)
    HarfordDnDRolls.Broadcast({
        type = "roll",
        label = ModifierLabel(spec) .. (spec.valueLabel and (" " .. tostring(spec.valueLabel)) or ""),
        total = suma,
        dice = spec.amount and "" or string.format("d%d: %d", tonumber(spec.die) or 0, bruto),
        modifiers = "",
    })
    return true, suma, nil, bruto, suma
end
