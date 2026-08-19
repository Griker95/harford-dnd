-- HarfordQuestTracker: misiones Harford como modulo real del ObjectiveTracker de Shadowlands.
-- No replica a mano el tracker: reutiliza sus cabeceras, bloques, lineas, pool y layout nativos.

local API = {}
_G.HarfordQuestTracker = API

local UPDATE_REASON = 0x40000000
local MODULE_NAME = "HARFORD_QUEST_TRACKER_MODULE"

local module
local initialized = false
local nativeModules
local nativeModulesUIOrder
local harfordOnly = false

local function TrackerEnabled()
    if _G.HarfordConfig and _G.HarfordConfig.Get then
        return _G.HarfordConfig.Get("questtracker") ~= false
    end
    return true
end

local function GetTrackedMissions()
    local quests = _G.HarfordQuests
    if not quests or not quests.GetTracked then
        return {}, nil
    end
    return quests.GetTracked() or {}, quests
end

local function GetObjectiveLines(mission)
    local lines = {}
    -- ObjectiveTracker anade su propio marcador "-". No se le puede pasar el texto compuesto
    -- para el registro (que ya incluye ese marcador) o aparecen guiones duplicados.
    if type(mission.objectives) == "table" and #mission.objectives > 0 then
        for _, objective in ipairs(mission.objectives) do
            local text = tostring(objective.text or ""):gsub("^%s*[%-%*]%s*", "")
            if objective.required and objective.required > 1 then
                text = text .. string.format(" (%d/%d)", objective.current or 0, objective.required)
            end
            if objective.done then text = "|cff40ff40" .. text .. "|r" end
            if text ~= "" then lines[#lines + 1] = text end
        end
        return lines
    end

    local text = tostring(mission.objective or "")
    for line in (text .. "\n"):gmatch("(.-)\n") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        local color, body = line:match("^(|c%x%x%x%x%x%x%x%x)(.*)$")
        if color then
            line = color .. body:gsub("^%s*[%-%*]%s*", "")
        else
            line = line:gsub("^%s*[%-%*]%s*", "")
        end
        if line ~= "" then
            lines[#lines + 1] = line
        end
    end
    return lines
end

local function OpenMission(id)
    if _G.HarfordQuestLog and _G.HarfordQuestLog.OpenTo then
        _G.HarfordQuestLog.OpenTo(id)
    elseif _G.HarfordQuestLog and _G.HarfordQuestLog.Toggle then
        _G.HarfordQuestLog.Toggle()
    end
end

local function ClearModule(moduleToClear)
    if not moduleToClear or not moduleToClear.BeginLayout then
        return
    end
    moduleToClear:BeginLayout()
    moduleToClear:EndLayout()
end

local function SetTrackerContents()
    local tracker = _G.ObjectiveTrackerFrame
    if not tracker or not nativeModules then
        return false
    end

    if TrackerEnabled() then
        if not harfordOnly then
            -- Liberar los bloques que Blizzard ya hubiera mostrado antes de
            -- quedarnos solo con Harford. El root permanece nativo.
            for index = 1, #nativeModules do
                ClearModule(nativeModules[index])
            end
            tracker.MODULES = { module }
            tracker.MODULES_UI_ORDER = { module }
            harfordOnly = true
        end
        return true
    end

    if harfordOnly then
        ClearModule(module)
        tracker.MODULES = nativeModules
        tracker.MODULES_UI_ORDER = nativeModulesUIOrder
        harfordOnly = false
    end
    return false
end

local function InstallModule()
    if initialized then
        return true
    end

    local tracker = _G.ObjectiveTrackerFrame
    if not tracker or not tracker.initialized then
        return false
    end
    if type(_G.ObjectiveTracker_GetModuleInfoTable) ~= "function"
        or type(_G.ObjectiveTracker_Update) ~= "function"
        or type(_G.ObjectiveTracker_AddBlock) ~= "function" then
        return false
    end

    module = _G.ObjectiveTracker_GetModuleInfoTable(MODULE_NAME)
    module.updateReasonModule = UPDATE_REASON
    module.fromHeaderOffsetY = -6
    module.fromModuleOffsetY = -8

    local header = CreateFrame("Frame", nil, tracker.BlocksFrame, "ObjectiveTrackerHeaderTemplate")
    module:SetHeader(header, "Misiones", UPDATE_REASON)

    function module:OnBlockHeaderClick(block, mouseButton)
        local quests = _G.HarfordQuests
        if mouseButton == "RightButton" then
            if quests and quests.SetTracked then
                quests.SetTracked(block.id, false)
            end
            return
        end
        OpenMission(block.id)
    end

    function module:Update()
        self:BeginLayout()

        if TrackerEnabled() then
            local missions = GetTrackedMissions()
            if #missions > 0 then
                self.Header.Text:SetText(string.format("Misiones (%d)", #missions))

                for index = 1, #missions do
                    local mission = missions[index]
                    local block = self:GetBlock(mission.id or ("harford-" .. index))
                    self:SetBlockHeader(block, mission.title or mission.id or "?")

                    local objectives = GetObjectiveLines(mission)
                    for lineIndex = 1, #objectives do
                        self:AddObjective(block, lineIndex, objectives[lineIndex])
                    end

                    block:SetHeight(block.height)
                    if _G.ObjectiveTracker_AddBlock(block) then
                        block:Show()
                        self:FreeUnusedLines(block)
                    end
                end
            end
        end

        self:EndLayout()
    end

    -- Conservamos las listas nativas para restaurarlas si el usuario desactiva
    -- el tracker Harford. Mientras este activo, el root solo recibe nuestro
    -- modulo: asi no se cuelan misiones automaticas del juego bajo las nuestras.
    nativeModules = tracker.MODULES
    nativeModulesUIOrder = tracker.MODULES_UI_ORDER
    initialized = true
    return true
end

function API.Refresh()
    if not InstallModule() then
        return false
    end
    if SetTrackerContents() then
        _G.ObjectiveTracker_Update(UPDATE_REASON)
    else
        _G.ObjectiveTracker_Update(OBJECTIVE_TRACKER_UPDATE_ALL)
    end
    return true
end

function API.Toggle()
    local config = _G.HarfordConfig
    if config and config.Get and config.Set then
        config.Set("questtracker", not TrackerEnabled())
    end
    API.Refresh()
end

local listenerRegistered = false
local function Start()
    if not listenerRegistered and _G.HarfordQuests and _G.HarfordQuests.RegisterChangeListener then
        _G.HarfordQuests.RegisterChangeListener(function()
            API.Refresh()
        end)
        listenerRegistered = true
    end
    API.Refresh()
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("PLAYER_ENTERING_WORLD")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "Blizzard_ObjectiveTracker" then
        return
    end
    Start()
end)
