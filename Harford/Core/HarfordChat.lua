-- Salida comun para mensajes visibles de Harford.
HarfordChat = HarfordChat or {}

local API = HarfordChat
local PREFIX = "|cff00ccff[Harford]|r"

function API.GetPrefix()
    return PREFIX
end

function API.Format(message)
    local text = tostring(message or "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%x%[Harford[^%]]*%]|r%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%x%[D&D%]|r%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%x%[Mision compartida%]|r%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%xComunicador Harford:|r%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%xHarfordCompendio:|r%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%xHarfordContracts:|r%s*", "")
    text = text:gsub("^|c%x%x%x%x%x%x%x%x%[Harford[^%]]*%]%s*", "")
    return PREFIX .. " " .. text
end

function API.Print(message)
    local text = API.Format(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    elseif print then
        print(text)
    end
    return text
end
