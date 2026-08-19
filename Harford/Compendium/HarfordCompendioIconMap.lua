local API = _G.HarfordCompendioAPI
if not API then return end
local IconCatalog = _G.HarfordIconCatalog

local PENDING_ICON_NAME = "eps_buildershaven_gobinfo"

local iconCache = {}

local function GetLibRPMedia()
    if not LibStub then return nil end
    local ok, lib = pcall(LibStub.GetLibrary, LibStub, "LibRPMedia-1.0", true)
    if ok then return lib end
end

local function ResolveIcon(iconName)
    if not iconName or iconName == "" then return nil end
    if type(iconName) == "number" then return iconName end
    if type(iconName) == "string" then
        local spellId = iconName:match("^spell:(%d+)$")
        if spellId and GetSpellTexture then
            local texture = GetSpellTexture(tonumber(spellId))
            if texture then return texture end
        end
        if iconName:match("^Interface\\") then return iconName end
    end
    if iconCache[iconName] ~= nil then return iconCache[iconName] or nil end

    local resolved
    local media = GetLibRPMedia()
    if media and media.IsIconDataLoaded and media:IsIconDataLoaded() then
        local ok, fileId = pcall(media.GetIconFileByName, media, iconName)
        if ok and fileId then
            resolved = fileId
        end
    end

    iconCache[iconName] = resolved or false
    return resolved
end

function API.ResolveRP3IconName(iconName, fallback)
    return ResolveIcon(iconName) or fallback
end

function API.GetBG3IconName(spell)
    if not spell then return nil end
    local candidates = (IconCatalog and IconCatalog.GetSpellCandidates and IconCatalog.GetSpellCandidates(spell.id))

    if type(candidates) == "table" then
        return candidates[1]
    end
end

function API.GetSpellIcon(spell)
    if not spell then return "Interface\\Icons\\INV_Misc_Book_09" end
    local candidates = (IconCatalog and IconCatalog.GetSpellCandidates and IconCatalog.GetSpellCandidates(spell.id))

    if type(candidates) == "table" then
        for _, iconName in ipairs(candidates) do
            local resolved = ResolveIcon(iconName)
            if resolved then return resolved end
        end
    end
    return ResolveIcon(PENDING_ICON_NAME) or "Interface\\Icons\\INV_Misc_Book_09"
end






