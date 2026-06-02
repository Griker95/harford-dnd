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

local function toN(x, d)
    local n = tonumber(x)
    if n == nil then return d or 0 end
    return n
end

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

function HarfordDnDRolls.Serialize(data)
    data = data or {}
    return string.format("%s^%s^%s^%d^%s^%s^%s^%s^%s^%s",
        EscapeRollField(data.type or "roll"),
        EscapeRollField(HarfordDnDRolls.GetDisplayName()),
        EscapeRollField(data.label or ""),
        data.total or 0,
        EscapeRollField(data.dice or ""),
        EscapeRollField(data.modifiers or ""),
        EscapeRollField(data.critical or ""),
        EscapeRollField(data.mode or ""),
        EscapeRollField(data.miscBonus or ""),
        EscapeRollField(data.nameColor or "")
    )
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

    local COLOR_HEADER = "|cff00ccff"
    local COLOR_ROLL = "|cff66ccff"
    local COLOR_DETAIL = "|cffb0b0b0"
    local COLOR_CRIT = "|cff00ff00"
    local COLOR_FUMBLE = "|cffff3333"

    local parts = {}
    local playerName = data.player or UnitName("player") or "Unknown"
    local nameColor = data.nameColor and ("|cff" .. data.nameColor) or "|cffffcc00"
    table.insert(parts, COLOR_HEADER .. "[D&D]" .. ENDCLR .. " " .. nameColor .. playerName .. ENDCLR)

    local modeStr = ""
    if data.mode == "V" then
        modeStr = " " .. COLOR_CRIT .. "[V]" .. ENDCLR
    elseif data.mode == "D" then
        modeStr = " " .. COLOR_FUMBLE .. "[D]" .. ENDCLR
    end

    local labelStr = parts[1] .. modeStr .. " " .. (data.label or "Tirada") .. ": "
        .. COLOR_ROLL .. tostring(data.total or 0) .. ENDCLR

    local damageTypeStr = ""
    if data.type == "damage" and data.modifiers and data.modifiers ~= "" then
        damageTypeStr = " " .. data.modifiers
    end

    local critStr = ""
    if data.critical == "CRITICO" or data.critical == "CR\195\141TICO" then
        critStr = " " .. COLOR_CRIT .. data.critical .. ENDCLR
    elseif data.critical == "PIFIA" then
        critStr = " " .. COLOR_FUMBLE .. "PIFIA" .. ENDCLR
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
    if not rollData or rollData.type == "info" then return end
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

    rollData.nameColor = displayColor

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

    HarfordDnDRolls.DisplayInChat({
        type      = rollData.type,
        player    = HarfordDnDRolls.GetDisplayName(),
        nameColor = displayColor,
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
