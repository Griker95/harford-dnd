HarfordTRP3 = HarfordTRP3 or {}

local API = HarfordTRP3

local function TrimRealm(realm)
    realm = tostring(realm or "")
    realm = realm:gsub("%s+", "")
    return realm
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, value = pcall(fn, ...)
    if ok then
        return value
    end

    return nil
end

local function NormalizeIconPath(icon)
    icon = tostring(icon or "")
    if icon == "" then return nil end
    if tonumber(icon) then return icon end
    if icon:find("\\", 1, true) or icon:find("/", 1, true) then return icon end
    return "Interface\\Icons\\" .. icon
end

local function ReadIconField(tbl, fieldName)
    if type(tbl) ~= "table" then return nil end
    local value = tbl[fieldName]
    if type(value) == "string" and value ~= "" then
        return value
    end
    if type(value) == "number" then
        return tostring(value)
    end
    return nil
end

local function NormalizeHexColor(value)
    value = tostring(value or "")
    value = value:gsub("|cff", "")
    value = value:gsub("#", "")
    value = value:match("^(%x%x%x%x%x%x)")
    return value and value:lower() or nil
end

local function NormalizeDisplaySpacing(text)
    text = tostring(text or "")
    text = text:gsub("\r", "")
    text = text:gsub("[ \t]+\n", "\n")
    text = text:gsub("\n\n\n+", "\n\n")
    text = text:gsub("^\n+", ""):gsub("\n+$", "")
    return text
end

local function StripInlineMarkup(text)
    text = tostring(text or "")
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("{icon:[^}]+}", "")
    text = text:gsub("{/?col[^}]*}", "")
    text = text:gsub("{/?h%d[^}]*}", "")
    text = text:gsub("{/?p[^}]*}", "")
    text = text:gsub("{/?link[^}]*}", "")
    text = text:gsub("{/?.-}", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

local function SumMulticlassLevels(text)
    text = tostring(text or "")
    local total = 0
    local count = 0

    for line in text:gmatch("[^\r\n]+") do
        local clean = StripInlineMarkup(line)
        local level = clean:match("%((%d+)%)%s*$")
        if level and clean:match("%S") then
            total = total + (tonumber(level) or 0)
            count = count + 1
        end
    end

    if count > 0 and total > 0 then
        return tostring(total)
    end

    return nil
end

local function PrimaryClassFromAbout(text)
    text = tostring(text or "")
    local bestClass, bestLevel
    for line in text:gmatch("[^\r\n]+") do
        local iconClass = line:match("{icon:classicon_([%w_]+)")
        local clean = StripInlineMarkup(line)
        local classText, level = clean:match("^(.-)%s*%((%d+)%)%s*$")
        if level or iconClass then
            classText = tostring(classText or ""):gsub("^%s+", ""):gsub("%s+$", "")
            level = tonumber(level) or 0
            if (iconClass or classText ~= "") and level > (bestLevel or -1) then
                bestClass = iconClass or classText
                bestLevel = level
            end
        end
    end
    return bestClass
end

local function IndentDisplayText(text, indent)
    text = NormalizeDisplaySpacing(text)
    if text == "" then return "" end
    indent = indent or "  "
    text = text:gsub("\n", "\n" .. indent)
    return indent .. text
end

local function BuildWrappedSection(title, icon, body)
    body = NormalizeDisplaySpacing(body)
    if body == "" then return nil end

    local header = ""
    if icon then
        header = API.IconMarkup(icon, 28)
    end
    if title and tostring(title) ~= "" then
        if header ~= "" then header = header .. " " end
        header = header .. "|cffffd100" .. tostring(title) .. "|r"
    end

    local line = "|cff8a7a70--------------------------------|r"
    if header == "" then
        return line .. "\n" .. IndentDisplayText(body)
    end

    return header .. "\n" .. line .. "\n" .. IndentDisplayText(body)
end

local function FindIconInTable(tbl, depth, seen, out, path)
    if type(tbl) ~= "table" or depth <= 0 then return nil end
    seen = seen or {}
    if seen[tbl] then return nil end
    seen[tbl] = true
    out = out or {}
    path = path or "profile"

    local fields = { "IC", "icon", "Icon", "iconID", "profileIcon" }
    for _, fieldName in ipairs(fields) do
        local value = ReadIconField(tbl, fieldName)
        if value then
            out[#out + 1] = {
                path = path .. "." .. fieldName,
                icon = value,
                normalized = NormalizeIconPath(value),
            }
        end
    end

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            FindIconInTable(value, depth - 1, seen, out, path .. "." .. tostring(key))
        end
    end

    return out
end

local function GetRegister()
    return TRP3_API and TRP3_API.register
end

local function GetCompanionRegister()
    return TRP3_API
        and TRP3_API.companions
        and TRP3_API.companions.register
end

local function GetTRP3PlayerID()
    return TRP3_API and TRP3_API.globals and TRP3_API.globals.player_id
end

local function IsPlayerUnitID(unitID)
    unitID = tostring(unitID or "")
    if unitID == "" then return false end
    local playerID = GetTRP3PlayerID()
    if playerID and unitID == playerID then return true end
    return API.BuildUnitID and unitID == API.BuildUnitID("player")
end

local function GetCharacterProfileData(profile)
    if type(profile) ~= "table" then return nil end
    if type(profile.player) == "table" then return profile.player end
    return profile
end

function API.IsAvailable()
    return TRP3_API ~= nil
end

function API.HasRegister()
    return GetRegister() ~= nil
end

function API.HasCompanionRegister()
    return GetCompanionRegister() ~= nil
end

function API.BuildUnitID(unit)
    unit = unit or "target"
    if not UnitName then
        return nil
    end

    if TRP3_API and TRP3_API.utils and TRP3_API.utils.str and TRP3_API.utils.str.getUnitID then
        local unitID = SafeCall(TRP3_API.utils.str.getUnitID, unit)
        if unitID and tostring(unitID) ~= "" then
            return unitID
        end
    end

    local name, realm = UnitName(unit)
    if not name or name == "" then
        return nil
    end

    realm = TrimRealm((realm and realm ~= "" and realm) or (GetRealmName and GetRealmName()) or "")
    realm = realm:gsub("%-", "")
    if realm == "" then
        return name
    end

    return name .. "-" .. realm
end

function API.GetPlayerProfile(unit)
    local register = GetRegister()
    if not register then
        return nil, "TRP3_API.register no disponible"
    end

    local unitID = API.BuildUnitID(unit or "target")
    if not unitID then
        return nil, "unitID no disponible"
    end

    if IsPlayerUnitID(unitID) and TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile then
        local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
        if profile then
            local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
            return profile, nil, unitID, profileID
        end
    end

    if register.isUnitIDKnown and not SafeCall(register.isUnitIDKnown, unitID) then
        return nil, "unitID no conocido por TRP3"
    end

    local profile = SafeCall(register.getUnitIDCurrentProfile, unitID)
    if not profile and register.getUnitIDProfile then
        profile = SafeCall(register.getUnitIDProfile, unitID)
    end

    if not profile then
        return nil, "perfil TRP3 de jugador no disponible"
    end

    local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
    return profile, nil, unitID, profileID
end

function API.GetPlayerProfileByUnitID(unitID)
    local register = GetRegister()
    if not register then
        return nil, "TRP3_API.register no disponible"
    end

    unitID = tostring(unitID or "")
    if unitID == "" then
        return nil, "unitID no disponible"
    end

    local profileID
    if register.getUnitIDProfileID then
        profileID = SafeCall(register.getUnitIDProfileID, unitID)
    end
    if not profileID and register.isUnitIDKnown and SafeCall(register.isUnitIDKnown, unitID) and register.hasProfile then
        profileID = SafeCall(register.hasProfile, unitID)
    end
    if profileID and register.getProfile then
        local profile = SafeCall(register.getProfile, profileID)
        if profile then
            return profile, nil, unitID, profileID
        end
    end

    if IsPlayerUnitID(unitID) and TRP3_API and TRP3_API.profile and TRP3_API.profile.getPlayerCurrentProfile then
        local profile = SafeCall(TRP3_API.profile.getPlayerCurrentProfile)
        if profile then
            local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
            return profile, nil, unitID, profileID
        end
    end

    if register.isUnitIDKnown and not SafeCall(register.isUnitIDKnown, unitID) then
        return nil, "unitID no conocido por TRP3"
    end

    local profile = SafeCall(register.getUnitIDCurrentProfile, unitID)
    if not profile and register.getUnitIDProfile then
        profile = SafeCall(register.getUnitIDProfile, unitID)
    end
    if not profile and register.getProfile then
        local profileID = register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID)
        if profileID then
            profile = SafeCall(register.getProfile, profileID)
        end
    end

    if not profile then
        return nil, "perfil TRP3 de jugador no disponible"
    end

    profileID = profileID or (register.getUnitIDProfileID and SafeCall(register.getUnitIDProfileID, unitID))
    return profile, nil, unitID, profileID
end

function API.GetPlayerProfileByProfileID(profileID)
    local register = GetRegister()
    if not register then
        return nil, "TRP3_API.register no disponible"
    end

    profileID = tostring(profileID or "")
    if profileID == "" then
        return nil, "profileID no disponible"
    end

    local profile
    if register.getProfileOrNil then
        profile = SafeCall(register.getProfileOrNil, profileID)
    end
    if not profile and register.getProfile then
        profile = SafeCall(register.getProfile, profileID)
    end
    if not profile then
        return nil, "perfil TRP3 de jugador no disponible"
    end

    return profile, nil, profileID
end

local function GetAboutSectionText(section)
    if type(section) ~= "table" then return nil end
    local text = tostring(section.TX or "")
    if text == "" then return nil end
    local icon = ReadIconField(section, "IC")
    return BuildWrappedSection(nil, icon, API.ConvertTRP3Markup(text))
end

local function CollectRawAboutText(profile)
    local character = GetCharacterProfileData(profile)
    if type(character) ~= "table" or type(character.about) ~= "table" then
        return nil
    end

    local about = character.about
    local template = tonumber(about.TE) or 1
    local parts = {}

    if template == 1 then
        local text = about.T1 and about.T1.TX
        if text and tostring(text) ~= "" then parts[#parts + 1] = tostring(text) end
    elseif template == 2 then
        local frames = about.T2 or {}
        for i = 1, #frames do
            local text = frames[i] and frames[i].TX
            if text and tostring(text) ~= "" then parts[#parts + 1] = tostring(text) end
        end
    elseif template == 3 then
        local data = about.T3 or {}
        for _, key in ipairs({ "PH", "PS", "HI" }) do
            local text = data[key] and data[key].TX
            if text and tostring(text) ~= "" then parts[#parts + 1] = tostring(text) end
        end
    end

    if #parts == 0 then return nil end
    return table.concat(parts, "\n")
end

function API.GetPlayerAboutText(profile)
    local character = GetCharacterProfileData(profile)
    if type(character) ~= "table" or type(character.about) ~= "table" then
        return nil, "profile.about vacio"
    end

    local about = character.about
    local template = tonumber(about.TE) or 1
    local parts = {}

    if template == 1 then
        local text = about.T1 and about.T1.TX
        if text and tostring(text) ~= "" then
            parts[#parts + 1] = API.ConvertTRP3Markup(text)
        end
    elseif template == 2 then
        local frames = about.T2 or {}
        for i = 1, #frames do
            local section = frames[i]
            local text = GetAboutSectionText(section)
            if text and text ~= "" then
                parts[#parts + 1] = text
            end
        end
    elseif template == 3 then
        local sections = {
            { key = "PH", title = "Fisico" },
            { key = "PS", title = "Personalidad" },
            { key = "HI", title = "Historia" },
        }
        local data = about.T3 or {}
        for _, sectionInfo in ipairs(sections) do
            local section = data[sectionInfo.key]
            local text = section and section.TX
            if text and tostring(text) ~= "" then
                local icon = ReadIconField(section, "IC")
                parts[#parts + 1] = BuildWrappedSection(sectionInfo.title, icon, API.ConvertTRP3Markup(text))
            end
        end
    end

    if #parts == 0 then
        return nil, "profile.about vacio"
    end

    return table.concat(parts, "\n\n")
end

function API.GetUnitRPName(unit)
    local register = GetRegister()
    if not register or not register.getUnitRPName then
        return nil
    end

    return SafeCall(register.getUnitRPName, unit or "target")
end

function API.NormalizeIconPath(icon)
    return NormalizeIconPath(icon)
end

function API.GetProfileIcon(profile)
    if type(profile) ~= "table" then
        return nil
    end

    local character = GetCharacterProfileData(profile)
    local directPaths = {
        { profile.data, "IC" },
        { profile.data, "icon" },
        { profile.data, "Icon" },
        { profile.characteristics, "IC" },
        { profile.characteristics, "icon" },
        { character and character.characteristics, "IC" },
        { character and character.characteristics, "icon" },
        { profile, "IC" },
        { profile, "icon" },
        { profile, "Icon" },
        { profile, "profileIcon" },
    }

    for _, candidate in ipairs(directPaths) do
        local icon = ReadIconField(candidate[1], candidate[2])
        if icon then
            return NormalizeIconPath(icon), icon
        end
    end

    local candidates = FindIconInTable(profile, 4)
    if candidates and candidates[1] then
        return candidates[1].normalized, candidates[1].icon
    end

    return nil
end

function API.GetProfileIconCandidates(profile)
    return FindIconInTable(profile, 5) or {}
end

function API.GetProfileNameColor(profile)
    local character = GetCharacterProfileData(profile)
    if type(character) ~= "table" or type(character.characteristics) ~= "table" then
        return nil
    end

    return NormalizeHexColor(character.characteristics.CH)
end

function API.GetProfileLevel(profile)
    if type(profile) ~= "table" then return nil end

    local character = GetCharacterProfileData(profile)
    local candidates = {
        character and character.characteristics and character.characteristics.LV,
        character and character.characteristics and character.characteristics.LVL,
        character and character.characteristics and character.characteristics.level,
        character and character.characteristics and character.characteristics.Nivel,
        character and character.character and character.character.LV,
        character and character.character and character.character.level,
        profile.characteristics and profile.characteristics.LV,
        profile.characteristics and profile.characteristics.LVL,
        profile.characteristics and profile.characteristics.level,
        profile.data and profile.data.LV,
        profile.data and profile.data.level,
        profile.LV,
        profile.level,
    }

    for _, value in ipairs(candidates) do
        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    local aboutText = API.GetPlayerAboutText and API.GetPlayerAboutText(profile)
    aboutText = tostring(aboutText or "")
    local multiclassLevel = SumMulticlassLevels(aboutText)
    if multiclassLevel then return multiclassLevel end

    local level = aboutText:match("[Nn]ivel%s*[:%-]?%s*(%d+)")
        or aboutText:match("[Nn]iv%.%s*[:%-]?%s*(%d+)")
        or aboutText:match("[Ll]evel%s*[:%-]?%s*(%d+)")
    if level then return level end

    return nil
end

function API.GetProfilePrimaryClass(profile)
    if type(profile) ~= "table" then return nil end

    local aboutText = CollectRawAboutText(profile)
    local aboutClass = PrimaryClassFromAbout(aboutText)
    if aboutClass and aboutClass ~= "" then
        return aboutClass
    end

    local character = GetCharacterProfileData(profile)
    local candidates = {
        character and character.characteristics and character.characteristics.CL,
        character and character.characteristics and character.characteristics.class,
        character and character.characteristics and character.characteristics.Clase,
        character and character.character and character.character.CL,
        character and character.character and character.character.class,
        profile.characteristics and profile.characteristics.CL,
        profile.characteristics and profile.characteristics.class,
        profile.data and profile.data.CL,
        profile.data and profile.data.class,
        profile.CL,
        profile.class,
    }

    for _, value in ipairs(candidates) do
        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end

    return nil
end

function API.GetNpcIdFromGUID(guid)
    guid = tostring(guid or "")
    if guid == "" then
        return nil
    end

    return select(6, strsplit("-", guid))
end

function API.GetUnitNpcId(unit)
    if not UnitGUID then
        return nil
    end

    return API.GetNpcIdFromGUID(UnitGUID(unit or "target"))
end

function API.GetPhaseId()
    if C_Epsilon and C_Epsilon.GetPhaseId then
        return SafeCall(C_Epsilon.GetPhaseId)
    end

    if ARC and ARC.PHASE and ARC.PHASE.GetPhaseId then
        return SafeCall(ARC.PHASE.GetPhaseId)
    end

    if ARC and ARC.XAPI and ARC.XAPI.Phase and ARC.XAPI.Phase.GetPhaseId then
        return SafeCall(ARC.XAPI.Phase.GetPhaseId)
    end

    return nil
end

function API.BuildEpsilonNpcFullID(unit)
    local npcID = API.GetUnitNpcId(unit or "target")
    local phaseID = API.GetPhaseId()

    if not npcID or npcID == "" then
        return nil, "npcID no disponible"
    end

    if not phaseID or tostring(phaseID) == "" then
        return nil, "phaseID no disponible"
    end

    return tostring(phaseID) .. "_" .. tostring(npcID), nil, tostring(npcID), tostring(phaseID)
end

function API.GetEpsilonNpcProfile(unit)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getCompanionProfile then
        return nil, "TRP3_API.companions.register.getCompanionProfile no disponible"
    end

    local fullID, err, npcID, phaseID = API.BuildEpsilonNpcFullID(unit or "target")
    if not fullID then
        return nil, err
    end

    local profile = SafeCall(companionRegister.getCompanionProfile, fullID)
    if not profile then
        return nil, "perfil companion/NPC no disponible", fullID, npcID, phaseID
    end

    return profile, nil, fullID, npcID, phaseID
end

function API.GetEpsilonNpcProfileByFullID(fullID)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getCompanionProfile then
        return nil, "TRP3_API.companions.register.getCompanionProfile no disponible"
    end

    fullID = tostring(fullID or "")
    if fullID == "" then
        return nil, "fullID no disponible"
    end

    local profile = SafeCall(companionRegister.getCompanionProfile, fullID)
    if not profile then
        return nil, "perfil companion/NPC no disponible"
    end

    return profile
end

function API.GetEpsilonNpcProfileByProfileID(profileID)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getProfiles then
        return nil, "TRP3_API.companions.register.getProfiles no disponible"
    end

    profileID = tostring(profileID or "")
    if profileID == "" then
        return nil, "profileID no disponible"
    end

    local profiles = SafeCall(companionRegister.getProfiles)
    if type(profiles) ~= "table" then
        return nil, "perfiles companion/NPC no disponibles"
    end

    return profiles[profileID], nil
end

function API.GetEpsilonNpcProfileID(unit)
    local companionRegister = GetCompanionRegister()
    if not companionRegister or not companionRegister.getCompanionProfileID then
        return nil, "TRP3_API.companions.register.getCompanionProfileID no disponible"
    end

    local fullID, err, npcID, phaseID = API.BuildEpsilonNpcFullID(unit or "target")
    if not fullID then
        return nil, err
    end

    return SafeCall(companionRegister.getCompanionProfileID, fullID), nil, fullID, npcID, phaseID
end

function API.GetEpsilonNpcMainText(unit)
    local profile, err, fullID, npcID, phaseID = API.GetEpsilonNpcProfile(unit or "target")
    if not profile then
        return nil, err, fullID, npcID, phaseID
    end

    local text = profile.data and profile.data.TX
    if not text or text == "" then
        return nil, "profile.data.TX vacio", fullID, npcID, phaseID
    end

    return text, nil, fullID, npcID, phaseID, profile
end

function API.GetProfileMainText(profile)
    if type(profile) ~= "table" then
        return nil, "perfil no disponible"
    end

    local text = profile.data and profile.data.TX
    if not text or text == "" then
        return nil, "profile.data.TX vacio"
    end

    return text
end

function API.GetProfileStates(profile)
    local states = {}
    if type(profile) ~= "table" then
        return states
    end

    local character = GetCharacterProfileData(profile)
    local source = profile.PE
    if type(source) ~= "table" and type(character) == "table" and type(character.misc) == "table" then
        source = character.misc.PE
    end
    if type(source) ~= "table" then
        return states
    end

    for i = 1, 5 do
        local state = source[i] or source[tostring(i)]
        if type(state) == "table" then
            local title = tostring(state.TI or "")
            local text = tostring(state.TX or "")
            local icon = ReadIconField(state, "IC")
            local active = state.AC == true or state.AC == 1 or state.AC == "1"
            if active and (title ~= "" or text ~= "" or icon) then
                states[#states + 1] = {
                    index = i,
                    active = true,
                    title = title,
                    text = text,
                    icon = NormalizeIconPath(icon),
                    rawIcon = icon,
                }
            end
        end
    end

    return states
end

function API.BuildStatesDisplayText(profile)
    local states = API.GetProfileStates(profile)
    if #states == 0 then
        return nil
    end

    local parts = {}
    for _, state in ipairs(states) do
        local title = state.title ~= "" and state.title or ("Estado " .. tostring(state.index))
        local body = ""
        if state.text ~= "" then
            local stateText = API.ConvertTRP3Markup(state.text)
            if stateText ~= "" then
                body = "|cffcccccc" .. stateText .. "|r"
            end
        end

        parts[#parts + 1] = BuildWrappedSection(title, state.icon, body ~= "" and body or " ")
    end

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, "\n")
end

function API.IconMarkup(icon, size)
    icon = NormalizeIconPath(icon)
    if not icon then return "" end
    size = tonumber(size) or 16
    return "|T" .. icon .. ":" .. tostring(size) .. ":" .. tostring(size) .. ":0:0|t"
end

function API.ConvertTRP3Markup(text)
    text = tostring(text or "")
    text = text:gsub("\r", "")

    text = text:gsub("{icon:([^:}]+):?(%d*)}", function(icon, size)
        return API.IconMarkup(icon, tonumber(size) or 24)
    end)

    text = text:gsub("{col:([%x%x%x%x%x%x]+)}", "|cff%1")
    text = text:gsub("{/col}", "|r")

    text = text:gsub("{h1}", "\n|cffffd100")
    text = text:gsub("{/h1}", "|r\n")
    text = text:gsub("{h2}", "\n|cffffd100")
    text = text:gsub("{/h2}", "|r\n")
    text = text:gsub("{h3}", "\n|cffffd100")
    text = text:gsub("{/h3}", "|r\n")

    text = text:gsub("{p:c}", "\n")
    text = text:gsub("{p:l}", "\n")
    text = text:gsub("{p:r}", "\n")
    text = text:gsub("{p}", "\n")
    text = text:gsub("{/p}", "\n")
    text = text:gsub("{br}", "\n")

    text = text:gsub("{hr}", "\n|cff888888------------------------------|r\n")
    text = text:gsub("{li}", "\n- ")
    text = text:gsub("{/li}", "")

    text = text:gsub("{[^}]-}", "")
    text = text:gsub("\n%s+\n", "\n\n")
    return NormalizeDisplaySpacing(text)
end

function API.BuildDisplayText(profile)
    if type(profile) ~= "table" then
        return nil, "perfil no disponible"
    end

    local parts = {}
    local mainText = API.GetProfileMainText(profile)
    if not mainText then
        mainText = API.GetPlayerAboutText(profile)
    end
    if mainText and mainText ~= "" then
        parts[#parts + 1] = API.ConvertTRP3Markup(mainText)
    end

    local statesText = API.BuildStatesDisplayText(profile)
    if statesText then
        parts[#parts + 1] = statesText
    end

    if #parts == 0 then
        return nil, "profile.data.TX vacio"
    end

    return NormalizeDisplaySpacing(table.concat(parts, "\n\n"))
end

function API.StripTRP3Markup(text)
    text = tostring(text or "")
    text = text:gsub("{h1}", "\n")
    text = text:gsub("{h2}", "\n")
    text = text:gsub("{h3}", "\n")
    text = text:gsub("{/h1}", "\n")
    text = text:gsub("{/h2}", "\n")
    text = text:gsub("{/h3}", "\n")
    text = text:gsub("{br}", "\n")
    text = text:gsub("{p}", "\n")
    text = text:gsub("{/p}", "\n")
    text = text:gsub("{col:[^}]-}", "")
    text = text:gsub("{/col}", "")
    text = text:gsub("{icon:[^}]-}", "")
    text = text:gsub("{[^}]-}", "")
    text = text:gsub("\r", "")
    text = text:gsub("\n%s+\n", "\n\n")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text
end

function API.GetPhaseAddonProfileKey(unit)
    local npcID = API.GetUnitNpcId(unit or "target")
    if not npcID or npcID == "" then
        return nil, "npcID no disponible"
    end

    return "TOTALRP_PROFILE_" .. tostring(npcID), nil, tostring(npcID)
end
