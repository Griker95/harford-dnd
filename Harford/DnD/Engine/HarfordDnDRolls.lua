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
function HarfordDnDRolls.BroadcastAbility(feature, opts)
    if not feature then return false end
    opts = opts or {}
    -- Economia de turno: solo se cobra a los rasgos que DECLARAN su coste (`cast`). El resto no
    -- se cuenta, porque `type = "accion"` es la categoria generica y en 5e incluye las adicionales:
    -- adivinarlo daria un contador equivocado, que es peor que no tenerlo.
    if opts.skipTurnCost ~= true and HarfordDnDConditions and HarfordDnDConditions.Turn then
        HarfordDnDConditions.Turn.SpendForFeature(feature)
    end
    local label = HarfordTRP3 and HarfordTRP3.GetAbilityChatLink
        and HarfordTRP3.GetAbilityChatLink(feature)
    if not label or label == "" then
        label = "|cff66ccff[" .. tostring(feature.name or "Habilidad") .. "]|r"
    end
    HarfordDnDRolls.Broadcast({
        type = "info",
        label = label,
        targetUnit = opts.targetUnit,
        player = opts.player,
        nameColor = opts.nameColor,
    })
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

function HarfordDnDRolls.DisplayInChat(data)
    if not data then return end

    local COLOR_ROLL = "|cff66ccff"
    local COLOR_DETAIL = "|cffb0b0b0"
    local COLOR_CRIT = "|cff00ff00"
    local COLOR_FUMBLE = "|cffff3333"

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

    local labelStr = parts[1] .. modeStr .. " " .. (data.label or "Tirada") .. ": "
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

    local output = labelStr .. damageTypeStr .. critStr .. detailStr
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
