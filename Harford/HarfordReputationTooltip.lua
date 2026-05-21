HarfordReputationTooltip = HarfordReputationTooltip or {}

local API = HarfordReputationTooltip
local hooked = false

local function AddFactionLines(tooltip, unit)
    if not tooltip or not unit or not HarfordReputation then return end
    if not UnitExists or not UnitExists(unit) then return end
    if UnitIsPlayer and UnitIsPlayer(unit) then return end

    local factionId, points, rank, rankColor = HarfordReputation.GetUnitFactionRelationship(unit)
    if not factionId then return end

    local faction = HarfordReputation.GetFaction(factionId)
    if not faction then return end

    tooltip:AddLine(" ")
    tooltip:AddLine("Faccion: " .. tostring(faction.name or factionId), 1, 0.82, 0)

    local color = tostring(rankColor or "ffe0e0e0")
    local r = tonumber(color:sub(3, 4), 16) or 224
    local g = tonumber(color:sub(5, 6), 16) or 224
    local b = tonumber(color:sub(7, 8), 16) or 224
    tooltip:AddLine("Relacion contigo: " .. tostring(rank or "Neutral"), r / 255, g / 255, b / 255)
    tooltip:AddLine("Reputacion: " .. tostring(points or 0), 1, 1, 1)
end

function API.Refresh()
    if GameTooltip and GameTooltip:IsShown() then
        GameTooltip:Show()
    end
end

function API.Attach()
    if hooked or not GameTooltip or not GameTooltip.HookScript then return end
    hooked = true
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        local _, unit = self:GetUnit()
        AddFactionLines(self, unit)
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    API.Attach()
end)

if C_Timer and C_Timer.After then
    C_Timer.After(1, function() API.Attach() end)
end
