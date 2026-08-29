HarfordUnitFrames = HarfordUnitFrames or {}

local API = HarfordUnitFrames

API.C = API.C or {}
API.C.ADDON_PREFIX = "DND5EARC"
API.C.DEFAULT_FRAME_W = 232
API.C.DEFAULT_FRAME_H = 100
API.C.DEFAULT_BAR_W = 119
API.C.DEFAULT_BAR_H = 10
API.C.BAR_GAP = 2
API.C.BAR_INSET_X = 1
API.C.BAR_INSET_Y = 0
API.C.EXTRA_BAR_BG_ALPHA = 0.42
API.C.TEX_WHITE = "Interface\\Buttons\\WHITE8x8"
API.C.TEX_STATUS = "Interface\\TargetingFrame\\UI-StatusBar"
API.C.TEX_FRAME = "Interface\\TargetingFrame\\UI-TargetingFrame"
API.C.TEX_PORTRAIT_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
API.C.TEX_ABSORB      = "Interface\\RaidFrame\\Shield-Overlay"
API.C.TEX_ABSORB_FILL = "Interface\\RaidFrame\\Shield-Fill"
API.C.TEX_ABSORB_EDGE = "Interface\\RaidFrame\\Shield-Overshield"
API.C.TOT_OVERLAY_STRATA = "MEDIUM"
API.C.TOT_ART_LEVEL = 82
API.C.TOT_BAR_FRAME_LEVEL = 83
API.C.TOT_BAR_LEVEL = 84
API.C.TOT_PORTRAIT_LEVEL = 85
API.C.CLASS_COLOR_CACHE_MAX = 100

API.S = API.S or {}
API.S.frames = API.S.frames or {}
API.S.layouts = API.S.layouts or {}
API.S.resourceRequests = API.S.resourceRequests or {}
API.S.nativeState = API.S.nativeState or {}
API.S.auraAnchors = API.S.auraAnchors or {}
API.S.auraAnchorsByUnit = API.S.auraAnchorsByUnit or { target = {}, focus = {} }
API.S.focusTot = API.S.focusTot or { overlay=nil, lastGUID=nil, hooksInstalled=false }
API.S.nativePortraitMasks = API.S.nativePortraitMasks or {}
API.S.groupOverlays = API.S.groupOverlays or {}
API.S.groupFramesByUnit = API.S.groupFramesByUnit or {}
API.S.groupResourceRequests = API.S.groupResourceRequests or {}
API.S.compactUnitFrameHooksInstalled = API.S.compactUnitFrameHooksInstalled or {}
API.S.compactBarState = API.S.compactBarState or {}
API.S.compactPortraitState = API.S.compactPortraitState or {}
API.S.compactFramesTouched = API.S.compactFramesTouched or {}
API.S.classColorCache = API.S.classColorCache or {}
API.S.classColorCacheOrder = API.S.classColorCacheOrder or {}
-- API.S.focusTot.refresh/hide/ensureHooks se asignan dentro del do-block sin consumir slots de local.
local RefreshTargetOfTargetNative
local RefreshTargetOfTargetBars
local HideToTBarsOverlay
local ReapplyNativeBars
local EnsureNativeAbsorbTexture
local ApplyAbsorbTexture

local BarBackgroundInfo
local StatusBarTextureInfo
local SetTextureFromInfo

-- Clamp/FieldPath/FirstExisting/FindStatusBars/StatusBarScore/PickStatusBar/
-- ScaleBox/IsSaneBox viven en HarfordUIGeom.
local function NativeFrameForUnit(unit)
    if unit == "player" then return _G.PlayerFrame end
    if unit == "target" then return _G.TargetFrame end
    if unit == "focus" then return _G.FocusFrame end
    if unit == "focustarget" then return _G["FocusFrameToT"] end
    if unit == "targettarget" then
        return _G.TargetFrameToT
            or (_G.TargetFrame and _G.TargetFrame.totFrame)
            or (_G.TargetFrame and _G.TargetFrame.TargetFrameToT)
    end
    return nil
end

local function DebugName(frameOrRegion)
    if not frameOrRegion then return "nil" end
    if frameOrRegion.GetName and frameOrRegion:GetName() then
        return frameOrRegion:GetName()
    end
    if frameOrRegion.GetObjectType then
        return "<" .. tostring(frameOrRegion:GetObjectType()) .. ">"
    end
    return tostring(frameOrRegion)
end

-- Resuelve (alocando una tabla + lookups FieldPath) los frames nativos de un unit. Lo envuelve
-- NativePiecesForUnit con cache; NO llamar a BuildNativePieces directamente.
local function BuildNativePieces(unit)
    if unit == "player" then
        local root = _G.PlayerFrame
        local modernMain = HarfordUIGeom.FieldPath(root, "PlayerFrameContent", "PlayerFrameContentMain")
        return {
            root = root,
            portrait = _G.PlayerPortrait,
            health = HarfordUIGeom.FirstExisting(HarfordUIGeom.FieldPath(modernMain, "HealthBarArea", "HealthBar"), _G.PlayerFrameHealthBar),
            power = HarfordUIGeom.FirstExisting(HarfordUIGeom.FieldPath(modernMain, "ManaBarArea", "ManaBar"), HarfordUIGeom.FieldPath(modernMain, "ManaBar"), _G.PlayerFrameManaBar),
            level = _G.PlayerFrameTextureFrameLevelText or _G.PlayerLevelText,
            name = _G.PlayerName,
            texture = _G.PlayerFrameTexture,
        }
    end

    local root = unit == "focus" and _G.FocusFrame
        or unit == "targettarget" and NativeFrameForUnit("targettarget")
        or unit == "focustarget" and _G["FocusFrameToT"]
        or _G.TargetFrame
    local modernMain = HarfordUIGeom.FieldPath(root, "TargetFrameContent", "TargetFrameContentMain")
    local prefix = unit == "focus" and "FocusFrame"
        or unit == "targettarget" and "TargetFrameToT"
        or unit == "focustarget" and "FocusFrameToT"
        or "TargetFrame"
    local health = HarfordUIGeom.FirstExisting(HarfordUIGeom.FieldPath(modernMain, "HealthBar"), _G[prefix .. "HealthBar"], HarfordUIGeom.FieldPath(root, "healthbar"), HarfordUIGeom.FieldPath(root, "HealthBar"))
    local power = HarfordUIGeom.FirstExisting(HarfordUIGeom.FieldPath(modernMain, "ManaBar"), _G[prefix .. "ManaBar"], HarfordUIGeom.FieldPath(root, "manabar"), HarfordUIGeom.FieldPath(root, "ManaBar"))
    if unit == "targettarget" or unit == "focustarget" then
        health = health or HarfordUIGeom.PickStatusBar(root, { "health" })
        power = power or HarfordUIGeom.PickStatusBar(root, { "mana", "power" }, health and { [health] = true } or nil)
    end
    return {
        root = root,
        portrait = HarfordUIGeom.FirstExisting(_G[prefix .. "Portrait"], HarfordUIGeom.FieldPath(root, "portrait"), HarfordUIGeom.FieldPath(root, "Portrait")),
        health = health,
        power = power,
        level = HarfordUIGeom.FirstExisting(_G[prefix .. "TextureFrameLevelText"], _G[prefix .. "LevelText"], HarfordUIGeom.FieldPath(root, "levelText"), HarfordUIGeom.FieldPath(root, "LevelText")),
        name = HarfordUIGeom.FirstExisting(_G[prefix .. "TextureFrameName"], HarfordUIGeom.FieldPath(root, "name"), HarfordUIGeom.FieldPath(root, "Name")),
        texture = HarfordUIGeom.FirstExisting(_G[prefix .. "TextureFrameTexture"], HarfordUIGeom.FieldPath(root, "texture"), HarfordUIGeom.FieldPath(root, "Texture")),
    }
end

-- Cache de pieces nativos para player/target/focus (sus frames y barras nativas son ESTABLES
-- durante la sesion: cambiar de target reusa TargetFrame). Evita alocar tabla + escanear FieldPath
-- en cada llamada (ReapplyNativeBars corre por cada UNIT_HEALTH/POWER, los hooks aun mas). Los
-- callers solo LEEN la tabla. Se invalida en PLAYER_ENTERING_WORLD (recreacion de frames / reload).
-- targettarget/focustarget NO se cachean: sus barras se resuelven de forma mas dinamica.
local nativePiecesCache = {}
local function NativePiecesForUnit(unit)
    if unit == "player" or unit == "target" or unit == "focus" then
        local cached = nativePiecesCache[unit]
        if cached then return cached end
        cached = BuildNativePieces(unit)
        nativePiecesCache[unit] = cached
        return cached
    end
    return BuildNativePieces(unit)
end

local function InvalidateNativePiecesCache()
    if wipe then wipe(nativePiecesCache) else nativePiecesCache = {} end
end

local function SafeUnitName(unit)
    if not UnitExists or not UnitExists(unit) then return nil end
    return HarfordClassColors.UnitFullName(unit)
end

local function UnitIsSupportedPlayer(unit)
    return UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)
end

local function Bounds(frameOrRegion)
    if not frameOrRegion or not frameOrRegion.GetLeft then return nil end
    local left, top, right, bottom = frameOrRegion:GetLeft(), frameOrRegion:GetTop(), frameOrRegion:GetRight(), frameOrRegion:GetBottom()
    if not left or not top or not right or not bottom then return nil end
    return {
        left = left,
        top = top,
        right = right,
        bottom = bottom,
        width = right - left,
        height = top - bottom,
    }
end

local function RelativeBounds(bounds, rootBounds)
    if not bounds or not rootBounds then return nil end
    return {
        x = bounds.left - rootBounds.left,
        y = rootBounds.top - bounds.top,
        width = bounds.width,
        height = bounds.height,
        cx = ((bounds.left + bounds.right) / 2) - rootBounds.left,
        cy = rootBounds.top - ((bounds.top + bounds.bottom) / 2),
    }
end

local function TextureInfo(texture, unit)
    if texture and ((texture.GetTexture and texture:GetTexture()) or (texture.GetAtlas and texture:GetAtlas())) then
        local info = {
            path = texture.GetTexture and texture:GetTexture() or nil,
            atlas = texture.GetAtlas and texture:GetAtlas() or nil,
            color = texture.GetVertexColor and { texture:GetVertexColor() } or nil,
            alpha = texture.GetAlpha and texture:GetAlpha() or nil,
            texCoord = texture.GetTexCoord and { texture:GetTexCoord() } or nil,
            bounds = Bounds(texture),
            source = DebugName(texture),
        }
        return info
    end

    if unit == "player" then
        return {
            path = API.C.TEX_FRAME,
            texCoord = { 1, 0.09375, 0, 0.78125 },
        }
    end

    return {
        path = API.C.TEX_FRAME,
        texCoord = { 0.09375, 1, 0, 0.78125 },
    }
end

-- Cluster de medida/layout nativo: solo GetOrMeasureLayout es publica; los helpers de layout
-- quedan block-local (do...end) para bajar el pico de locales.
local GetOrMeasureLayout
do
local function FallbackLayout(unit)
    local isPlayer = unit == "player"
    return {
        unit = unit,
        root = { width = API.C.DEFAULT_FRAME_W, height = API.C.DEFAULT_FRAME_H },
        texture = TextureInfo(nil, unit),
        portrait = { x = isPlayer and 42 or API.C.DEFAULT_FRAME_W - 42 - 64, y = 12, width = 64, height = 64 },
        health = { x = isPlayer and 106 or 7, y = 41, width = API.C.DEFAULT_BAR_W, height = API.C.DEFAULT_BAR_H },
        power = { x = isPlayer and 106 or 7, y = 54, width = API.C.DEFAULT_BAR_W, height = API.C.DEFAULT_BAR_H },
        level = { cx = isPlayer and 54 or 179.5, cy = 65, width = 22, height = 16 },
        name = { cx = isPlayer and 166 or 66, cy = 31, width = 112, height = 14 },
        measured = false,
    }
end

local function DerivedLayout(unit, rootWidth, rootHeight)
    local fallback = FallbackLayout(unit)
    local sx = (rootWidth or API.C.DEFAULT_FRAME_W) / API.C.DEFAULT_FRAME_W
    local sy = (rootHeight or API.C.DEFAULT_FRAME_H) / API.C.DEFAULT_FRAME_H
    fallback.root = { width = rootWidth or API.C.DEFAULT_FRAME_W, height = rootHeight or API.C.DEFAULT_FRAME_H }
    fallback.portrait = HarfordUIGeom.ScaleBox(fallback.portrait, sx, sy)
    fallback.health = HarfordUIGeom.ScaleBox(fallback.health, sx, sy)
    fallback.power = HarfordUIGeom.ScaleBox(fallback.power, sx, sy)
    fallback.level = HarfordUIGeom.ScaleBox(fallback.level, sx, sy)
    fallback.name = HarfordUIGeom.ScaleBox(fallback.name, sx, sy)
    return fallback
end

local function NormalizeMeasuredLayout(layout)
    local rootW = layout.root and layout.root.width or API.C.DEFAULT_FRAME_W
    local rootH = layout.root and layout.root.height or API.C.DEFAULT_FRAME_H
    local derived = DerivedLayout(layout.unit, rootW, rootH)

    if not HarfordUIGeom.IsSaneBox(layout.portrait, rootW, rootH, 28, 28, 90, 90) then
        layout.portrait = derived.portrait
    else
        local size = math.min(layout.portrait.width, layout.portrait.height)
        size = HarfordUIGeom.Clamp(size, 36, 72)
        layout.portrait.width = size
        layout.portrait.height = size
    end

    if not HarfordUIGeom.IsSaneBox(layout.health, rootW, rootH, 50, 4, 180, 24) then
        layout.health = derived.health
    end
    if not HarfordUIGeom.IsSaneBox(layout.power, rootW, rootH, 50, 4, 180, 24) then
        layout.power = derived.power
    end
    if not HarfordUIGeom.IsSaneBox(layout.name, rootW, rootH, 40, 4, 180, 24) then
        layout.name = derived.name
    end

    return layout
end

local function FindLargestTargetingTexture(root)
    if not root or not root.GetRegions then return nil end
    local best, bestArea = nil, 0
    local function consider(region)
        if not region or not region.GetObjectType or region:GetObjectType() ~= "Texture" then return end
        if not region.GetTexture or not region:GetTexture() then return end
        if not tostring(region:GetTexture()):lower():find("targetingframe", 1, true) then return end
        local b = Bounds(region)
        if not b then return end
        local area = b.width * b.height
        if area > bestArea then
            best = region
            bestArea = area
        end
    end
    for _, region in ipairs({ root:GetRegions() }) do
        consider(region)
    end
    if root.GetChildren then
        for _, child in ipairs({ root:GetChildren() }) do
            if child.GetRegions then
                for _, region in ipairs({ child:GetRegions() }) do
                    consider(region)
                end
            end
        end
    end
    return best
end

function API.MeasureNativeLayout(unit)
    unit = (unit == "target" or unit == "focus") and unit or "player"
    local pieces = NativePiecesForUnit(unit)
    local rootBounds = Bounds(pieces.root)
    if not rootBounds then
        return FallbackLayout(unit)
    end

    local layout = FallbackLayout(unit)
    layout.root = { width = rootBounds.width, height = rootBounds.height }
    layout.measured = true

    local texture = pieces.texture or FindLargestTargetingTexture(pieces.root)
    layout.texture = TextureInfo(texture, unit)
    if layout.texture.bounds then
        layout.texture.rel = RelativeBounds(layout.texture.bounds, rootBounds)
    end

    local portrait = RelativeBounds(Bounds(pieces.portrait), rootBounds)
    local health = RelativeBounds(Bounds(pieces.health), rootBounds)
    local power = RelativeBounds(Bounds(pieces.power), rootBounds)
    local level = RelativeBounds(Bounds(pieces.level), rootBounds)
    local name = RelativeBounds(Bounds(pieces.name), rootBounds)

    if portrait then layout.portrait = portrait end
    if health then layout.health = health end
    if power then layout.power = power end
    if level then layout.level = level end
    if name then layout.name = name end

    layout.healthBg = BarBackgroundInfo(pieces.health, unit)
    layout.powerBg = BarBackgroundInfo(pieces.power, unit)
    layout.healthFill = StatusBarTextureInfo(pieces.health, unit)
    layout.powerFill = StatusBarTextureInfo(pieces.power, unit)
    layout.native = {
        root = DebugName(pieces.root),
        portrait = DebugName(pieces.portrait),
        health = DebugName(pieces.health),
        power = DebugName(pieces.power),
        level = DebugName(pieces.level),
        name = DebugName(pieces.name),
        texture = DebugName(texture),
    }

    return NormalizeMeasuredLayout(layout)
end

function GetOrMeasureLayout(unit, force)
    if force or not API.S.layouts[unit] then
        API.S.layouts[unit] = API.MeasureNativeLayout(unit)
    end
    return API.S.layouts[unit]
end
end  -- do (cluster GetOrMeasureLayout)

local function ResourceValue(tbl, key)
    return tonumber(tbl and tbl[key]) or 0
end

local function GetProfile(unit)
    if not HarfordTRP3 then return nil end
    if unit ~= "player" and not (UnitIsPlayer and UnitIsPlayer(unit)) then
        -- NPC de Epsilon: perfil en companions.register
        if HarfordTRP3.GetEpsilonNpcProfile then
            local profile = HarfordTRP3.GetEpsilonNpcProfile(unit)
            return profile
        end
        return nil
    end
    if HarfordTRP3.GetPlayerProfile then
        return HarfordTRP3.GetPlayerProfile(unit)
    end
    return nil
end

local function ResourceLabel(key)
    local def = HarfordDnDResources and HarfordDnDResources.DEFS and HarfordDnDResources.DEFS[key]
    return def and def.label or tostring(key or "")
end

local function ResourceColor(key)
    local def = HarfordDnDResources and HarfordDnDResources.DEFS and HarfordDnDResources.DEFS[key]
    if def and def.color then
        return def.color[1] or 1, def.color[2] or 1, def.color[3] or 1
    end
    return 0.7, 0.7, 0.7
end

-- Color de clase (alias, normalizacion y resolucion) vive en HarfordClassColors.
-- Aqui solo se conserva el cache por nombre (estado propio de UnitFrames).
local function CacheClassColorForName(unitName, r, g, b, classKey)
    if not unitName or not r then return end
    local entry = API.S.classColorCache[unitName]
    if not entry then
        entry = { r, g, b, classKey }
        API.S.classColorCacheOrder[#API.S.classColorCacheOrder + 1] = unitName
    else
        entry[1], entry[2], entry[3], entry[4] = r, g, b, classKey
    end
    API.S.classColorCache[unitName] = entry
    local short = Ambiguate and Ambiguate(unitName, "short") or unitName
    if short and short ~= "" then
        API.S.classColorCache[short] = entry
    end
    while #API.S.classColorCacheOrder > API.C.CLASS_COLOR_CACHE_MAX do
        local oldName = table.remove(API.S.classColorCacheOrder, 1)
        local oldEntry = API.S.classColorCache[oldName]
        API.S.classColorCache[oldName] = nil
        local oldShort = Ambiguate and Ambiguate(oldName, "short") or oldName
        if oldShort and API.S.classColorCache[oldShort] == oldEntry then
            API.S.classColorCache[oldShort] = nil
        end
    end
end

local function GetCachedClassColorForName(unitName)
    local color = unitName and API.S.classColorCache[unitName]
    if color then return color[1], color[2], color[3], color[4] end
    local short = unitName and Ambiguate and Ambiguate(unitName, "short") or unitName
    color = short and API.S.classColorCache[short]
    if color then return color[1], color[2], color[3], color[4] end
    return nil
end

local function ResourceExists(key, resources)
    local cur = ResourceValue(resources, "Res_" .. tostring(key) .. "_Cur")
    local max = ResourceValue(resources, "Res_" .. tostring(key) .. "_Max")
    if HarfordDnDResources and HarfordDnDResources.Exists then
        return HarfordDnDResources.Exists(key, cur, max)
    end
    return max > 0
end

local function BuildResourceList(resources)
    if type(resources) ~= "table" then return {} end
    local order = HarfordDnDResources and HarfordDnDResources.ORDER or { "health", "mana" }
    local out = {}
    for _, key in ipairs(order) do
        if ResourceExists(key, resources) then
            out[#out + 1] = {
                key = key,
                label = ResourceLabel(key),
                cur = ResourceValue(resources, "Res_" .. tostring(key) .. "_Cur"),
                max = ResourceValue(resources, "Res_" .. tostring(key) .. "_Max"),
                tempCur = key == "health" and ResourceValue(resources, "Res_temp_health_Cur") or nil,
            }
        end
    end
    return out
end

local function BuildCompactOverlaySignature(unit, unitName, icon, list, classColor)
    local sig = tostring(unitName or "") .. "#" .. tostring(UnitGUID and UnitGUID(unit) or "")
        .. "#" .. tostring(icon or "")
    if classColor then
        sig = sig .. string.format("#c:%.3f,%.3f,%.3f", classColor[1] or 0, classColor[2] or 0, classColor[3] or 0)
    else
        sig = sig .. "#c:"
    end
    for i = 1, #list do
        local data = list[i]
        sig = sig .. "#" .. tostring(data.key or "") .. ":" .. tostring(data.cur or 0)
            .. "/" .. tostring(data.max or 0) .. "+" .. tostring(data.tempCur or 0)
    end
    return sig
end

local function GetLevelText(unit, profile)
    local level = HarfordTRP3 and HarfordTRP3.GetProfileLevel and HarfordTRP3.GetProfileLevel(profile)
    if not level or level == "" then
        level = UnitLevel and UnitLevel(unit)
    end
    if not level or tostring(level) == "" or tonumber(level) == 0 then
        return "?"
    end
    return tostring(level):gsub("^Nv%s*", "")
end

local function LearnClassColor(unit, profile)
    local unitName = SafeUnitName(unit)
    local r, g, b, classKey = HarfordClassColors.ProfileColorRGB(profile)
    if r then
        CacheClassColorForName(unitName, r, g, b, classKey)
        return r, g, b, classKey
    end
    r, g, b, classKey = GetCachedClassColorForName(unitName)
    if r then
        return r, g, b, classKey
    end
    return HarfordClassColors.UnitColorRGB(unit)
end

local function RequestResourcesIfNeeded(unit, unitName, resources)
    if unit == "player" or type(resources) == "table" then return end
    if not HarfordDnDAPI or not HarfordDnDAPI.RequestResourcesForName then return end
    local now = GetTime and GetTime() or time()
    local last = API.S.resourceRequests[unitName] or 0
    if now - last < 5 then return end
    API.S.resourceRequests[unitName] = now
    HarfordDnDAPI.RequestResourcesForName(unitName)
end

local function RequestGroupResourcesIfNeeded(unitName, resources)
    if type(resources) == "table" then return end
    if not unitName or unitName == "" then return end
    if not HarfordDnDAPI or not HarfordDnDAPI.RequestResourcesForName then return end
    local now = GetTime and GetTime() or time()
    local last = API.S.groupResourceRequests[unitName] or 0
    if now - last < 8 then return end
    API.S.groupResourceRequests[unitName] = now
    HarfordDnDAPI.RequestResourcesForName(unitName)
end

local function SaveFrameState(frame)
    if not frame or API.S.nativeState[frame] then return end
    API.S.nativeState[frame] = {
        shown = frame.IsShown and frame:IsShown() == true,
        alpha = frame.GetAlpha and frame:GetAlpha() or 1,
        mouse = frame.IsMouseEnabled and frame:IsMouseEnabled() == true,
    }
end

local function SetFrameAlpha(frame, alpha)
    if frame and frame.SetAlpha then frame:SetAlpha(alpha) end
end

local function RestoreFrame(frame)
    local state = frame and API.S.nativeState[frame]
    if not state then return end
    SetFrameAlpha(frame, state.alpha or 1)
    if frame.EnableMouse then frame:EnableMouse(state.mouse == true) end
    if frame.SetShown then
        frame:SetShown(state.shown == true)
    elseif state.shown then
        if frame.Show then frame:Show() end
    elseif frame.Hide then
        frame:Hide()
    end
    API.S.nativeState[frame] = nil
end


local function RestoreNativeUnitFrame(unit)
    RestoreFrame(NativeFrameForUnit(unit))
end

local function KeepNativeUnitFrameVisible(unit)
    local native = NativeFrameForUnit(unit)
    if not native then return end
    RestoreFrame(native)
    SetFrameAlpha(native, 1)
    if native.EnableMouse then native:EnableMouse(true) end
    if native.Show then native:Show() end
end

-- Cluster de ocultado de widgets de poder de clase nativos: solo HideNativeClassPowerWidgets es
-- publica; los helpers quedan block-local (do...end) para bajar el pico de locales.
local HideNativeClassPowerWidgets
do
local function HideNativeClassPowerFrames()
    local names = {
        "ComboFrame",
        "ComboPointPlayerFrame",
        "ClassPowerBar",
        "ClassPowerFrame",
        "ClassResourceFrame",
        "RogueComboPointBarFrame",
        "DruidComboPointBarFrame",
        "PaladinPowerBarFrame",
        "MageArcaneChargesFrame",
        "WarlockPowerFrame",
        "MonkHarmonyBarFrame",
        "RuneFrame",
        "PriestBarFrame",
        "EclipseBarFrame",
        "TotemFrame",
    }
    for _, name in ipairs(names) do
        local frame = _G[name]
        if frame then
            SaveFrameState(frame)
            SetFrameAlpha(frame, 0)
            if frame.EnableMouse then frame:EnableMouse(false) end
        end
    end
end

local function LooksLikeClassPowerFrame(frame)
    if not frame or not frame.GetName then return false end
    local name = frame:GetName()
    if not name then return false end
    name = tostring(name):lower()
    return name:find("combo", 1, true)
        or name:find("classpower", 1, true)
        or name:find("classresource", 1, true)
        or name:find("runeframe", 1, true)
        or name:find("paladinpower", 1, true)
        or name:find("arcanecharges", 1, true)
        or name:find("warlockpower", 1, true)
        or name:find("monkharmony", 1, true)
        or name:find("eclipsebar", 1, true)
end

local function HideClassPowerChildren(root, depth)
    if not root or not root.GetChildren or (depth or 0) > 4 then return end
    for _, child in ipairs({ root:GetChildren() }) do
        if LooksLikeClassPowerFrame(child) then
            SaveFrameState(child)
            SetFrameAlpha(child, 0)
            if child.EnableMouse then child:EnableMouse(false) end
        end
        HideClassPowerChildren(child, (depth or 0) + 1)
    end
end

function HideNativeClassPowerWidgets()
    HideNativeClassPowerFrames()
    HideClassPowerChildren(_G.PlayerFrame, 0)
    HideClassPowerChildren(_G.TargetFrame, 0)
end
end  -- do (cluster HideNativeClassPowerWidgets)

local function RestoreNativeClassPowerWidgets()
    local names = {
        "ComboFrame",
        "ComboPointPlayerFrame",
        "ClassPowerBar",
        "ClassPowerFrame",
        "ClassResourceFrame",
        "RogueComboPointBarFrame",
        "DruidComboPointBarFrame",
        "PaladinPowerBarFrame",
        "MageArcaneChargesFrame",
        "WarlockPowerFrame",
        "MonkHarmonyBarFrame",
        "RuneFrame",
        "PriestBarFrame",
        "EclipseBarFrame",
        "TotemFrame",
    }
    for _, name in ipairs(names) do
        RestoreFrame(_G[name])
    end
end

local function FindTextureRegion(frame, preferredLayer)
    if not frame or not frame.GetRegions then return nil end
    local fallback
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local hasTexture = (region.GetTexture and region:GetTexture()) or (region.GetAtlas and region:GetAtlas())
            if hasTexture then
                local layer = region.GetDrawLayer and region:GetDrawLayer()
                if preferredLayer and layer == preferredLayer then
                    return region
                end
                fallback = fallback or region
            end
        end
    end
    return fallback
end

function StatusBarTextureInfo(bar, unit)
    if not bar then return nil end
    local texture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    local info = TextureInfo(texture, unit)
    if info then
        info.source = DebugName(texture)
    end
    return info
end

function BarBackgroundInfo(bar, unit)
    local texture = FindTextureRegion(bar, "BACKGROUND")
    local info = TextureInfo(texture, unit)
    if info then
        info.source = DebugName(texture)
        return info
    end

    info = StatusBarTextureInfo(bar, unit)
    if info then
        info.fallback = true
        info.color = { 0.025, 0.025, 0.025, 0.82 }
        info.alpha = 0.82
    end
    return info
end

local function SaveAuraPoints(frame, unit)
    if not frame then return end
    unit = unit == "focus" and "focus" or "target"
    API.S.auraAnchorsByUnit[unit] = API.S.auraAnchorsByUnit[unit] or {}
    local anchors = API.S.auraAnchorsByUnit[unit]
    if anchors[frame] then return end
    local points = {}
    for i = 1, frame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
        points[#points + 1] = { point, relativeTo, relativePoint, x or 0, y or 0 }
    end
    anchors[frame] = {
        parent = frame.GetParent and frame:GetParent() or nil,
        level = frame.GetFrameLevel and frame:GetFrameLevel() or nil,
        points = points,
    }
end

local function RestoreUnitAuras(unit)
    unit = unit == "focus" and "focus" or "target"
    API.S.auraAnchorsByUnit[unit] = API.S.auraAnchorsByUnit[unit] or {}
    for frame, data in pairs(API.S.auraAnchorsByUnit[unit]) do
        if frame then
            frame._harfordAuraUnit = nil
            frame._harfordAuraFilter = nil
            frame._harfordAuraIndex = nil
            if data.parent and frame.SetParent then frame:SetParent(data.parent) end
            if data.level and frame.SetFrameLevel then frame:SetFrameLevel(data.level) end
            frame:ClearAllPoints()
            for _, point in ipairs(data.points or {}) do
                frame:SetPoint(point[1], point[2], point[3], point[4], point[5])
            end
        end
    end
    API.S.auraAnchorsByUnit[unit] = {}
    if unit == "target" then
        API.S.auraAnchors = {}
    end
end

local function RestoreTargetAuras()
    RestoreUnitAuras("target")
end

local function RestoreFocusAuras()
    RestoreUnitAuras("focus")
end


-- Coloca las auras del unit bajo la ultima barra de recurso, en orden buffs -> debuffs.
-- En este cliente el orden nativo es el inverso (Debuff1 cuelga del TargetFrame y Buff1
-- del contenedor de debuffs); aqui invertimos: la 1a fila de buffs se ancla bajo la ultima
-- barra y los debuffs bajo TODO el bloque de buffs (su contenedor). Idempotente: fija anclas
-- absolutas (ultima barra / contenedor de buffs), asi que reaplicarla NO acumula offset (sin
-- drift). La usan RefreshFrame y el hook de TargetFrame_UpdateAuras (para sobrevivir a Blizzard).
-- Cluster de anclaje de auras bajo las barras: solo ReanchorAurasBelowBars es publica;
-- el resto (constante + helpers) queda block-local (do...end) para bajar el pico de locales.
local ReanchorAurasBelowBars
local RefreshNativeAuraButtons
do
local AURA_BAR_GAP = 3
local AURA_ICON_GAP = 2
local AURAS_PER_ROW = 8

local function AuraCount(unit, filter)
    local count = 0
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for index = 1, 40 do
            if not C_UnitAuras.GetAuraDataByIndex(unit, index, filter) then break end
            count = index
        end
        return count
    end
    if UnitAura then
        for index = 1, 40 do
            if not UnitAura(unit, index, filter) then break end
            count = index
        end
    end
    return count
end

local function AuraData(unit, index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
    end
    if UnitAura then
        local name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable,
            nameplateShowPersonal, spellId = UnitAura(unit, index, filter)
        if name then
            return {
                name = name,
                icon = icon,
                applications = applications,
                dispelName = dispelName,
                duration = duration,
                expirationTime = expirationTime,
                sourceUnit = sourceUnit,
                isStealable = isStealable,
                nameplateShowPersonal = nameplateShowPersonal,
                spellId = spellId,
            }
        end
    end
end

-- Aura Manager conserva un indice global para target y lo reutiliza al pintar
-- focus. No usamos ese indice: el tooltip se vuelve a construir desde el aura
-- real que corresponde al boton que Harford acaba de colocar.
local function ShowManagedAuraTooltip(button)
    local unit = button and button._harfordAuraUnit
    local index = button and button._harfordAuraIndex
    local filter = button and button._harfordAuraFilter
    local aura = unit and index and filter and AuraData(unit, index, filter)
    if not aura or not aura.spellId or not GameTooltip then return end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if type(_G.GetAuraDescription) == "function" and GameTooltip.SetSpellByID then
        -- Aura Manager resuelve sus nombres, iconos y descripciones por spellId;
        -- esta via evita su mapa targetAuraMappingTable defectuoso.
        GameTooltip:SetSpellByID(aura.spellId)
    elseif GameTooltip.SetUnitAura then
        -- Cliente sin Aura Manager: se conserva el tooltip nativo completo.
        GameTooltip:SetUnitAura(unit, index, filter)
    end
end

local function InstallManagedAuraTooltip(button)
    if not button or button._harfordAuraTooltipHooked or not button.HookScript then return end
    button._harfordAuraTooltipHooked = true
    button:HookScript("OnEnter", ShowManagedAuraTooltip)
end

local function ResolvedAuraIcon(aura)
    if not aura then return nil end
    -- GetSpellTexture queda sustituida por Aura Manager cuando está cargado y
    -- resuelve el icono personalizado de fase por spellId. UnitAura.icon es el
    -- icono crudo: reimponerlo borraba precisamente esa sustitución.
    if aura.spellId and type(_G.GetSpellTexture) == "function" then
        local icon = _G.GetSpellTexture(aura.spellId)
        if icon then return icon end
    end
    return aura.icon
end

-- === TIRA DE ESTADOS HARFORD ================================================
-- Los estados de Harford NO son auras del juego. Solo 15 de las 45 condiciones tienen un aura
-- detras, y esas se ven porque el cliente las pinta; las otras 30 no existen para el juego y no
-- apareceran en ninguna parte del unitframe del objetivo por mucho aura que se les enganche.
--
-- Por eso Harford pinta los suyos APARTE, en una tira propia justo encima del frame. No se mezclan
-- con los buffs nativos a proposito: son de otra naturaleza (los lleva Harford, no el servidor) y
-- confundirlos haria pensar que se pueden disipar o que duran lo que diga el juego.
--
-- La tira se coloca por encima de lo que haya: si las auras nativas siguen sobre el frame (el caso
-- normal, sin barras extra) se ancla sobre la mas alta de ellas, y si Harford las movio bajo las
-- barras se ancla sobre el frame. Recalcular el ancla en cada repaso sale mas barato que mantener
-- dos rutas que se desincronizarian.
do
    -- Dentro del `do`: este fichero roza el limite de 200 locales de Lua 5.1 y estas tres no las
    -- necesita nadie fuera de la tira.
    local ESTADO_TAM, ESTADO_HUECO, ESTADOS_POR_FILA = 20, 3, 8
    local tiras = {}

    local function EnsureTira(unit)
        if tiras[unit] then return tiras[unit] end
        local f = CreateFrame("Frame", "HarfordEstados" .. unit, UIParent)
        f.unidad = unit
        f:SetFrameStrata("MEDIUM")
        f:SetFrameLevel(85)
        f:SetSize(1, ESTADO_TAM)
        f.iconos = {}
        tiras[unit] = f
        return f
    end

    local function EnsureIcono(tira, i)
        local b = tira.iconos[i]
        if b then return b end
        b = CreateFrame("Frame", nil, tira)
        b:SetSize(ESTADO_TAM, ESTADO_TAM)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("TOPLEFT", 1, -1)
        b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        b.marco = b:CreateTexture(nil, "OVERLAY")
        b.marco:SetTexture("Interface\\Common\\WhiteIconFrame")
        b.marco:SetAllPoints()
        b.marco:SetVertexColor(0.68, 0.62, 0.44)
        b.contador = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        b.contador:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, 0)
        b:EnableMouse(true)
        b:SetScript("OnEnter", function(self)
            if not (GameTooltip and self.estado) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.estado.label, 1, 0.82, 0)
            if self.estado.description then
                GameTooltip:AddLine(self.estado.description, 1, 1, 1, true)
            end
            if self.estado.restante then
                GameTooltip:AddLine(self.estado.restante, 0.6, 0.8, 1)
            end
            local unidad = self:GetParent() and self:GetParent().unidad
            if (unidad == "player" and self.estado.id ~= "dying") or (unidad ~= "player" and API.OnConditionIconRightClick) then
                GameTooltip:AddLine("Click derecho: retirar", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        -- Click derecho retira el estado. En el marco PROPIO lo hace el core (es tu estado);
        -- en target/focus solo si HarfordAdmin instalo su callback (patron InsertGlanceLink:
        -- el core expone el gancho y no consulta permisos DM). "Muriendo" propio no se toca:
        -- su aura la gobierna el sistema de Salv Muerte y quitarla a mano lo desincronizaria.
        b:SetScript("OnMouseUp", function(self, boton)
            if boton ~= "RightButton" or not self.estado then return end
            local unidad = self:GetParent() and self:GetParent().unidad
            if unidad == "player" then
                if self.estado.id == "dying" then
                    HarfordChat.Print("Muriendo se retira recuperando vida, no a mano.")
                    return
                end
                if HarfordDnDConditions and HarfordDnDConditions.RequestPlayer then
                    HarfordDnDConditions.RequestPlayer("player", self.estado.id, false)
                end
            elseif API.OnConditionIconRightClick then
                API.OnConditionIconRightClick(unidad, self.estado.id)
            end
            if GameTooltip then GameTooltip:Hide() end
        end)
        tira.iconos[i] = b
        return b
    end

    -- Lo mas alto que ocupa el unitframe ahora mismo, incluidas las auras nativas si siguen encima.
    -- Se devuelve el OBJETO al que anclarse, no una coordenada: el frame se mueve y una coordenada
    -- absoluta se quedaria vieja en cuanto el jugador reposicionara cualquier cosa.
    local function AnclaSuperior(frame, prefix)
        local mejor, mejorY = frame, frame.GetTop and frame:GetTop()
        if not mejorY then return frame end
        for _, kind in ipairs({ "Buff", "Debuff" }) do
            for i = 1, 8 do
                local b = _G[prefix .. kind .. i]
                if not b or not b.IsShown or not b:IsShown() then break end
                local y = b.GetTop and b:GetTop()
                if y and y > mejorY then mejor, mejorY = b, y end
            end
        end
        return mejor
    end

    -- Los estados activos de la unidad, en el orden del catalogo y ya resueltos para pintar.
    local function EstadosDe(unit)
        if not (HarfordDnDConditions and HarfordDnDConditions.GetActive) then return {} end
        local ahora = GetTime and GetTime() or 0
        local fuera = {}
        for _, activo in ipairs(HarfordDnDConditions.GetActive(unit)) do
            local def, record = activo.definition, activo.record
            local restante
            local expira = record and tonumber(record.expiresAt)
            if expira and expira > ahora then
                restante = string.format("Quedan %d s", math.ceil(expira - ahora))
            end
            fuera[#fuera + 1] = {
                id = activo.id,
                label = def.label,
                description = def.description,
                restante = restante,
                icono = HarfordDnDConditions.GetIcon(activo.id),
                contador = HarfordDnDConditions.CounterFor(def, record),
            }
        end
        return fuera
    end

    function API.RefreshConditionStrip(unit)
        if unit ~= "target" and unit ~= "focus" and unit ~= "player" then return end
        -- "player": tus PROPIOS estados, encima de tu unitframe. Sus buffs nativos viven en
        -- BuffFrame (esquina de pantalla), no en el marco, asi que aqui no hay columna de auras
        -- con la que alinearse: el ancla queda en el propio PlayerFrame y desplazamiento 0.
        local prefix = unit == "focus" and "FocusFrame" or (unit == "player" and "PlayerFrame" or "TargetFrame")
        local frame = _G[prefix]
        local tira = EnsureTira(unit)
        local hay = frame and UnitExists and UnitExists(unit)
        local estados = hay and EstadosDe(unit) or {}

        for i = #estados + 1, #tira.iconos do tira.iconos[i]:Hide() end
        if #estados == 0 then
            tira:Hide()
            return 0
        end

        local ancho = 0
        for i, estado in ipairs(estados) do
            local b = EnsureIcono(tira, i)
            b.estado = estado
            b.icon:SetTexture(estado.icono)
            if estado.contador then
                b.contador:SetText(tostring(estado.contador))
                b.contador:Show()
            else
                b.contador:Hide()
            end
            local col = (i - 1) % ESTADOS_POR_FILA
            -- Las filas crecen HACIA ARRIBA: la primera queda pegada al frame, para que al entrar
            -- un estado nuevo no salte toda la tira sobre la cabeza del objetivo.
            local fila = math.floor((i - 1) / ESTADOS_POR_FILA)
            b:ClearAllPoints()
            b:SetPoint("BOTTOMLEFT", tira, "BOTTOMLEFT",
                col * (ESTADO_TAM + ESTADO_HUECO), fila * (ESTADO_TAM + ESTADO_HUECO))
            b:Show()
            ancho = math.max(ancho, (col + 1) * (ESTADO_TAM + ESTADO_HUECO) - ESTADO_HUECO)
        end

        local filas = math.ceil(#estados / ESTADOS_POR_FILA)
        tira:SetSize(math.max(1, ancho), filas * (ESTADO_TAM + ESTADO_HUECO) - ESTADO_HUECO)
        tira:ClearAllPoints()
        local ancla, margen = AnclaSuperior(frame, prefix), 6

        -- En COLUMNA con el primer buff, no pegada al borde del marco. Los botones de aura no
        -- empiezan en el borde izquierdo del frame, asi que anclar al frame dejaba la tira
        -- desplazada respecto a ellos y parecia que no pertenecia al mismo bloque.
        local desplazX, medido = 0, false
        do
            local ref = _G[prefix .. "Buff1"]
            if not (ref and ref.IsShown and ref:IsShown()) then ref = _G[prefix .. "Debuff1"] end
            -- En el marco PROPIO no hay botones de aura: la columna es donde EMPIEZAN las barras
            -- (la de salud), que es donde el ojo espera que arranque la tira. Anclada al borde
            -- del frame quedaba medio metida bajo el retrato y casi no se veia.
            if unit == "player" and not (ref and ref.IsShown and ref:IsShown()) then
                ref = _G[prefix .. "HealthBar"]
            end
            if ref and ref.IsShown and ref:IsShown() and ref.GetLeft and ancla.GetLeft then
                local a, b = ref:GetLeft(), ancla:GetLeft()
                -- `medido` aparte del valor: 0 es un desplazamiento VALIDO -- pasa cuando el ancla
                -- ya es el propio Buff1 -- y usarlo como "no encontrado" recuperaba la columna
                -- aprendida de otro objetivo y movia la tira unos 20 px.
                if a and b then desplazX, medido = a - b, true end
            end
            -- Un objetivo SIN auras no tiene columna con la que alinearse, y la tira se iba al
            -- borde del marco: quedaba en un sitio distinto segun el objetivo llevara buffs o no,
            -- que se lee como un fallo aunque cada caso este bien por separado.
            --
            -- Se RECUERDA la ultima columna aprendida en vez de escribir aqui un numero: el inset
            -- de los botones depende del arte del marco y de la escala, y un valor fijo se
            -- quedaria viejo en cuanto Blizzard o un addon lo tocaran.
            if medido then
                tira.columna = desplazX
            elseif tira.columna then
                desplazX = tira.columna
            end
        end
        tira:SetPoint("BOTTOMLEFT", ancla, "TOPLEFT", desplazX, margen)

        -- El marco del objetivo puede estar pegado al borde superior de la pantalla, y entonces la
        -- tira se coloca BIEN respecto a el pero fuera de la vista. Pasa de verdad: con el marco a
        -- 1005 y la pantalla midiendo 1009, los 20 px de la tira acababan en 1031.
        --
        -- Se baja lo justo para que quepa. Solaparse unos pixeles con lo de arriba del marco es
        -- feo, pero verla mal es infinitamente mejor que no verla: colocada con exquisitez fuera
        -- de la pantalla no le sirve a nadie.
        local techo = UIParent and UIParent:GetHeight()
        local arriba = tira:GetTop()
        if techo and arriba and arriba > techo then
            tira:ClearAllPoints()
            tira:SetPoint("BOTTOMLEFT", ancla, "TOPLEFT", desplazX, margen - (arriba - techo) - 2)
        end
        tira:Show()
        return #estados
    end
end

-- Repinta los contadores de target y focus. Lo llama el motor de condiciones cuando algo cambia,
-- porque el numero puede cambiar SIN que cambie el aura: `UNIT_AURA` no se entera de que Harford
-- haya subido un contador, y sin esto el icono se quedaria con el numero viejo hasta la siguiente
-- aura que entrara o saliera.
function API.RefreshAuraCounters()
    -- "player" va en la lista: es lo que repinta TU tira cuando el motor te pone o quita un
    -- estado (los contadores nativos no aplican: tus buffs no estan en el PlayerFrame).
    for _, unit in ipairs({ "target", "focus", "player" }) do
        -- Los contadores nativos son solo de target/focus (la funcion ademas fuerza a "target"
        -- cualquier otra unidad): con "player" solo se repinta la tira.
        if unit ~= "player" and UnitExists and UnitExists(unit) and RefreshNativeAuraButtons then
            RefreshNativeAuraButtons(unit)
        end
        API.RefreshConditionStrip(unit)
    end
end

-- Contador de Harford sobre el icono de aura nativo.
--
-- En Epsilon no se pueden aplicar auras CON acumulaciones, asi que el numero lo lleva el motor de
-- condiciones y se estampa aqui, donde WoW pondria el suyo. No se crea ningun frame: es un
-- FontString colgado del propio boton, asi que no hay strata que pelear.
--
-- Blizzard repinta estos botones, y por eso esto se llama desde `ApplyAuraButtonData`, que ya se
-- reaplica tras `TargetFrame_UpdateAuras`.
local function PintarContadorAura(button, unit, aura)
    local n = HarfordDnDConditions and HarfordDnDConditions.GetAuraCounter
        and HarfordDnDConditions.GetAuraCounter(unit, aura and aura.spellId)
    if not n and not button._harfordContador then return end
    if not button._harfordContador then
        local fs = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        fs:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 0)
        button._harfordContador = fs
    end
    if n then
        button._harfordContador:SetText(tostring(n))
        button._harfordContador:Show()
    else
        button._harfordContador:Hide()
    end
end

local function ApplyAuraButtonData(button, unit, index, filter)
    local aura = button and AuraData(unit, index, filter)
    if not aura then return false end
    local icon = _G[(button.GetName and button:GetName() or "") .. "Icon"]
    if icon and icon.SetTexture then icon:SetTexture(ResolvedAuraIcon(aura)) end
    button._harfordAuraUnit = unit
    button._harfordAuraFilter = filter
    button._harfordAuraIndex = index
    InstallManagedAuraTooltip(button)
    PintarContadorAura(button, unit, aura)
    if icon and icon.Show then icon:Show() end
    if button.Show then button:Show() end
    return true
end

local function PlaceAuraButtons(unit, prefix, kind, filter, count, anchor)
    if count <= 0 or not anchor then return nil end
    local rowStart, previous
    for index = 1, count do
        local button = _G[prefix .. kind .. index]
        if not ApplyAuraButtonData(button, unit, index, filter) then break end
        SaveAuraPoints(button, unit)
        button:ClearAllPoints()
        if index == 1 then
            button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -AURA_BAR_GAP)
            rowStart = button
        elseif (index - 1) % AURAS_PER_ROW == 0 then
            button:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -AURA_ICON_GAP)
            rowStart = button
        else
            button:SetPoint("TOPLEFT", previous, "TOPRIGHT", AURA_ICON_GAP, 0)
        end
        previous = button
    end
    return rowStart
end

-- El cliente puede dejar visible Buff1 con la textura del focus aunque UnitAura(target)
-- ya este vacio. Solo ocultamos slots que la API confirma vacios; nunca copiamos ni
-- reconstruimos texturas de auras.
function RefreshNativeAuraButtons(unit)
    unit = unit == "focus" and "focus" or "target"
    local prefix = unit == "focus" and "FocusFrame" or "TargetFrame"
    local helpful = AuraCount(unit, "HELPFUL")
    local harmful = AuraCount(unit, "HARMFUL")
    for index = helpful + 1, 40 do
        local button = _G[prefix .. "Buff" .. index]
        if not button then break end
        if button.Hide then button:Hide() end
    end
    for index = harmful + 1, 40 do
        local button = _G[prefix .. "Debuff" .. index]
        if not button then break end
        if button.Hide then button:Hide() end
    end
    -- Esta parte no depende del anclaje de Harford. Aura Manager usa el mapa de
    -- target tambien para FocusFrame; por eso se reconcilia siempre la textura y
    -- la identidad del tooltip, incluso con las dos barras nativas habituales.
    for index = 1, helpful do
        ApplyAuraButtonData(_G[prefix .. "Buff" .. index], unit, index, "HELPFUL")
    end
    for index = 1, harmful do
        ApplyAuraButtonData(_G[prefix .. "Debuff" .. index], unit, index, "HARMFUL")
    end
    return helpful, harmful
end

function ReanchorAurasBelowBars(frame, unit, helpful, harmful)
    if not frame then return false end
    unit = unit == "focus" and "focus" or "target"
    local prefix = unit == "focus" and "FocusFrame" or "TargetFrame"
    helpful = tonumber(helpful) or AuraCount(unit, "HELPFUL")
    harmful = tonumber(harmful) or AuraCount(unit, "HARMFUL")
    if helpful <= 0 and harmful <= 0 then return false end

    local n = tonumber(frame.resourceCount) or 0
    local lastBar = frame.bars and frame.bars[n]
    local barAnchor = lastBar and (lastBar.container or lastBar)
    if not barAnchor then return false end

    -- Los botones nativos de Epsilon pueden conservar la textura del focus aunque
    -- el unit token sea target. Reusamos sus botones/marcos, pero el icono y el
    -- orden provienen siempre de C_UnitAuras para la unidad que se esta renderizando.
    local lastBuffRow = PlaceAuraButtons(unit, prefix, "Buff", "HELPFUL", helpful, barAnchor)
    PlaceAuraButtons(unit, prefix, "Debuff", "HARMFUL", harmful, lastBuffRow or barAnchor)
    return true
end
end  -- do (cluster ReanchorAurasBelowBars)

-- Reancla exclusivamente las auras que la API del cliente confirma para ESTA unidad.
-- La referencia es la ultima barra creada, no la altura acumulada ni el frame raiz.
local function ReanchorActualUnitAuras(unit)
    if unit ~= "target" and unit ~= "focus" then return end
    local frame = API.S.frames and API.S.frames[unit]
    if not frame or not UnitIsSupportedPlayer(unit) then return end
    if (tonumber(frame.resourceCount) or 0) <= 2 then
        RestoreUnitAuras(unit)
        RefreshNativeAuraButtons(unit)
        return
    end

    local helpful, harmful = RefreshNativeAuraButtons(unit)
    if helpful > 0 or harmful > 0 then
        ReanchorAurasBelowBars(frame, unit, helpful, harmful)
    else
        RestoreUnitAuras(unit)
    end
end

local function AdjustUnitAuras(frame, resourceCount, extraHeight)
    local unit = frame and frame.unit
    if unit ~= "target" and unit ~= "focus" then return end
    ReanchorActualUnitAuras(unit)
    -- Despues de reanclar: la tira se apoya en la aura nativa mas alta, que acaba de moverse.
    API.RefreshConditionStrip(unit)
end

local function AdjustTargetAuras(frame, resourceCount, extraHeight)
    AdjustUnitAuras(frame, resourceCount, extraHeight)
end

local function QueueUnitAuraReanchor(unit)
    ReanchorActualUnitAuras(unit)
end

-- Epsilon puede conservar un Buff1 visible tras sustituir el target aunque UnitAura ya
-- no devuelva ninguna aura. No reordenamos ni reconstruimos auras: limpiamos solo los
-- slots que la API confirma vacios, despues de que el cliente haya terminado sus pases.
local function QueueNativeAuraCleanup(unit)
    if unit ~= "target" and unit ~= "focus" then return end
    API.S.nativeAuraCleanupSerial = API.S.nativeAuraCleanupSerial or {}
    local serial = (API.S.nativeAuraCleanupSerial[unit] or 0) + 1
    API.S.nativeAuraCleanupSerial[unit] = serial

    RefreshNativeAuraButtons(unit)
    QueueUnitAuraReanchor(unit)
    if not (C_Timer and C_Timer.After) then return end
    -- El repintado nativo puede ocurrir uno o dos frames despues del evento. Los
    -- pases cortos eliminan el destello sin esperar al fallback de 0.15 segundos.
    for _, delay in ipairs({ 0, 0.01, 0.03, 0.15, 0.35 }) do
        C_Timer.After(delay, function()
            if API.S.nativeAuraCleanupSerial and API.S.nativeAuraCleanupSerial[unit] == serial then
                RefreshNativeAuraButtons(unit)
                QueueUnitAuraReanchor(unit)
            end
        end)
    end
end

-- TargetFrame_UpdateAuras es la ruta comun que tambien usa FocusFrame. Epsilon
-- Aura Manager registra aqui un hook que lee siempre UnitAura("target", ...),
-- por lo que un refresh de focus puede sobrescribir iconos de ambos frames.
-- Este hook se instala tras cargar los addons y recompone cada boton desde la
-- unidad real. No depende de Aura Manager y es un no-op para NPCs/sin barras.
local nativeAuraUpdateHookInstalled = false
local function InstallNativeAuraUpdateHook()
    if nativeAuraUpdateHookInstalled or not hooksecurefunc then return end
    if type(_G.TargetFrame_UpdateAuras) ~= "function" then return end
    nativeAuraUpdateHookInstalled = true
    hooksecurefunc("TargetFrame_UpdateAuras", function(nativeFrame)
        local unit = nativeFrame and nativeFrame.unit
        if unit ~= "target" and unit ~= "focus" then return end
        RefreshNativeAuraButtons(unit)
        ReanchorActualUnitAuras(unit)
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                RefreshNativeAuraButtons(unit)
                ReanchorActualUnitAuras(unit)
            end)
        end
    end)
end

local function FindTargetOfTargetFrame()
    return _G.TargetFrameToT
        or (_G.TargetFrame and _G.TargetFrame.totFrame)
        or (_G.TargetFrame and _G.TargetFrame.TargetFrameToT)
end

local function ApplyTargetOfTargetLayer()
    local tot = FindTargetOfTargetFrame()
    if not tot or not API.S.targetOfTargetDesired then return end
    local newLevel = API.S.targetOfTargetDesired.level or 90
    if tot.SetFrameStrata then
        tot:SetFrameStrata(API.S.targetOfTargetDesired.strata or "HIGH")
    end
    if tot.SetFrameLevel then
        tot:SetFrameLevel(newLevel)
    end
    if tot.SetToplevel then
        tot:SetToplevel(true)
    end
    if tot.Raise then
        tot:Raise()
    end
end


-- Construye un frame StatusBar overlay sobre una barra nativa del ToT.
-- Se parenta a UIParent con strata HIGH para quedar encima de barSlotOverlays
-- sin tapar ventanas DIALOG de otros addons.
-- independientemente de la jerarquía de frames de TargetFrame en Epsilon.
local function MakeToTBarOverlayFrame(nativeBar)
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata(API.C.TOT_OVERLAY_STRATA)
    f:SetFrameLevel(API.C.TOT_BAR_FRAME_LEVEL)
    f:SetAllPoints(nativeBar)

    local bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg:SetAllPoints(f)
    bg:SetColorTexture(0.04, 0.04, 0.04, 1)
    f.bg = bg

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetFrameStrata(API.C.TOT_OVERLAY_STRATA)
    bar:SetFrameLevel(API.C.TOT_BAR_LEVEL)
    bar:SetAllPoints(f)
    bar:SetStatusBarTexture(API.C.TEX_STATUS)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    f.bar = bar

    f:Hide()
    return f
end

-- Recoge las texturas de arte/borde de un frame ToT para replicarlas en el overlay.
-- Excluye por nombre los hijos que son barras/portrait (ya cubiertos por overlays Harford).
-- No filtra por atlas/path porque los nombres varían entre versiones de Epsilon.
local function CollectToTArtRegions(root)
    local rootBounds = Bounds(root)
    if not root or not rootBounds then return {} end

    local rootName = root.GetName and root:GetName() or ""
    local textureFrame = _G[rootName .. "TextureFrame"]
    if not textureFrame and root.GetChildren then
        for _, child in ipairs({ root:GetChildren() }) do
            local n = child.GetName and child:GetName() or ""
            if n == rootName .. "TextureFrame" then
                textureFrame = child
                break
            end
        end
    end

    local regions = {}
    local seen = {}
    local function consider(region)
        if not region or seen[region] then return end
        seen[region] = true
        if not region.GetObjectType or region:GetObjectType() ~= "Texture" then return end
        -- Solo texturas con contenido real. TextureInfo devuelve un fallback TEX_FRAME
        -- para texturas sin textura/atlas cargados; usarlo aquí crearía cuadrados vacíos.
        local hasTex = (region.GetTexture and region:GetTexture()) or (region.GetAtlas and region:GetAtlas())
        if not hasTex then return end
        local info = TextureInfo(region, "targettarget")
        if not info or (not info.path and not info.atlas) then return end
        local path = tostring(info.path or ""):lower()
        local atlas = tostring(info.atlas or ""):lower()
        if not path:find("ui%-targetoftargetframe", 1, false)
        and not path:find("targetoftargetframe", 1, false)
        and not atlas:find("targetoftargetframe", 1, false) then
            return
        end
        local rel = RelativeBounds(info.bounds, rootBounds)
        if not rel or rel.width <= 0 or rel.height <= 0 then return end
        info.rel = rel
        regions[#regions + 1] = info
    end

    if textureFrame and textureFrame.GetRegions then
        for _, region in ipairs({ textureFrame:GetRegions() }) do
            consider(region)
        end
    end

    return regions
end

local function MakeToTArtOverlayFrame(tot)
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata(API.C.TOT_OVERLAY_STRATA)
    f:SetFrameLevel(API.C.TOT_ART_LEVEL)
    f:SetAllPoints(tot)
    f.textures = {}
    f:Hide()
    return f
end

-- Actualiza el artFrame de un overlay ToT con las texturas de arte/borde del frame nativo.
-- Genérico: funciona para TargetFrameToT y FocusFrameToT.
local function UpdateToTArtOverlay(tot, ov)
    if not ov or not ov.artFrame then return end
    if not tot or not (tot.IsShown and tot:IsShown()) then
        ov.artFrame:Hide()
        return
    end

    ov.artFrame:ClearAllPoints()
    ov.artFrame:SetAllPoints(tot)

    local regions = CollectToTArtRegions(tot)
    for i, info in ipairs(regions) do
        local texture = ov.artFrame.textures[i]
        if not texture then
            texture = ov.artFrame:CreateTexture(nil, "OVERLAY", nil, 0)
            ov.artFrame.textures[i] = texture
        end
        SetTextureFromInfo(texture, info)
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", ov.artFrame, "TOPLEFT", info.rel.x, -info.rel.y)
        texture:SetSize(info.rel.width, info.rel.height)
        texture:Show()
    end
    for i = #regions + 1, #ov.artFrame.textures do
        ov.artFrame.textures[i]:Hide()
    end
    if #regions > 0 then
        ov.artFrame:Show()
    else
        ov.artFrame:Hide()
    end
end

-- Oculta los hijos del frame ToT que no son barras ni portrait.
-- En Epsilon aparecen como cuadrados vacíos (buff/debuff slots nativos de WoW).
local function HideToTNativeExtras(tot)
    if not tot or not tot.GetChildren then return end
    local rootName = tot.GetName and tot:GetName() or ""
    for _, child in ipairs({ tot:GetChildren() }) do
        local n = child.GetName and child:GetName() or ""
        if n:match("^" .. rootName .. "Buff%d+$")
        or n:match("^" .. rootName .. "Debuff%d+$") then
            -- HookScript("OnShow", hide): patrón oUF/ElvUI para que el frame
            -- nunca vuelva a mostrarse aunque TargetofTarget_Update lo intente.
            pcall(function()
                child:HookScript("OnShow", function(self) self:Hide() end)
                child:Hide()
            end)
        end
    end
end

-- Oculta permanentemente el portrait nativo de un frame ToT usando HookScript.
-- SetAlpha(0) no es suficiente: TargetofTarget_Update/FocusofTarget_Update lo restaura.
local function HideToTNativePortrait(portraitNative)
    if not portraitNative then return end
    if portraitNative.SetAlpha then portraitNative:SetAlpha(0) end
end

function API._SyncToTNativePortraitAlpha(portraitNative, portraitOverlay)
    if not (portraitNative and portraitNative.SetAlpha) then return end
    local overlayShown = portraitOverlay and portraitOverlay.IsShown and portraitOverlay:IsShown()
    portraitNative:SetAlpha(overlayShown and 0 or 1)
end

-- Crea (o reutiliza) los overlays para health, recurso y portrait del ToT.
-- Las barras siguen como overlays en UIParent; el portrait es hijo del ToT
-- nativo para sustituir solo el icono sin pelear z-order con barras extra.
local function EnsureToTBarsOverlay()
    local healthNative = _G["TargetFrameToTHealthBar"]
    local manaNative   = _G["TargetFrameToTManaBar"]
    local tot          = _G["TargetFrameToT"]
    if not healthNative or not manaNative or not tot then return nil end
    if API.S.totBarsOverlay then return API.S.totBarsOverlay end

    local ov = {
        healthFrame = MakeToTBarOverlayFrame(healthNative),
        manaFrame   = MakeToTBarOverlayFrame(manaNative),
        artFrame    = MakeToTArtOverlayFrame(tot),
    }

    -- Portrait nativo: ocultarlo permanentemente con HookScript (SetAlpha no es suficiente,
    -- TargetofTarget_Update lo restaura). Nuestro overlay sustituye visualmente al nativo.
    local portraitNative = _G["TargetFrameToTPortrait"]
    HideToTNativePortrait(portraitNative)

    if portraitNative then
        local pf = CreateFrame("Frame", nil, tot)
        if pf.SetFrameLevel and tot.GetFrameLevel then pf:SetFrameLevel((tot:GetFrameLevel() or 0) + 3) end
        local ok = pcall(function() pf:SetAllPoints(portraitNative) end)
        if not ok then
            pf:SetSize(32, 32)
            pf:SetPoint("TOPLEFT", tot, "TOPLEFT", 2, -2)
        end

        local pbg = pf:CreateTexture(nil, "BACKGROUND", nil, 0)
        pbg:SetAllPoints(pf)
        pbg:SetColorTexture(0.04, 0.04, 0.04, 1)
        pf.bg = pbg

        local ptex = pf:CreateTexture(nil, "ARTWORK", nil, 1)
        ptex:SetAllPoints(pf)
        ptex:SetTexCoord(0, 1, 0, 1)
        pf.icon = ptex

        if ptex.AddMaskTexture and pf.CreateMaskTexture then
            local mask = pf:CreateMaskTexture(nil, "ARTWORK")
            mask:SetTexture(API.C.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(pf)
            pbg:AddMaskTexture(mask)
            ptex:AddMaskTexture(mask)
            pf.portraitMask = mask
        end

        pf:Hide()
        ov.portraitFrame = pf
    end

    -- Ocultar hijos extra del ToT nativo (buff/debuff slots vacíos)
    HideToTNativeExtras(tot)

    API.S.totBarsOverlay = ov
    HarfordUnitFrames._totBarsOverlay = ov
    return ov
end

-- Actualiza el portrait overlay con el icono TRP3 (o lo oculta si no hay icono).
local function UpdateToTPortraitOverlay(profile)
    local ov = EnsureToTBarsOverlay()
    if not ov or not ov.portraitFrame then return end

    local tot = FindTargetOfTargetFrame()
    if not (UnitExists and UnitExists("targettarget")) or not (tot and tot.IsShown and tot:IsShown()) then
        HideToTBarsOverlay()
        return
    end

    -- GetPortraitCfgKey está definida más abajo; inlineamos la lógica para evitar forward reference
    local isPlayer = UnitIsPlayer and UnitIsPlayer("targettarget")
    local cfgKey = isPlayer and "portrait_target_player" or "portrait_target_npc"
    local useTRP3 = not HarfordConfig or HarfordConfig.Get(cfgKey) ~= "wow"
    local icon = useTRP3 and profile and HarfordTRP3 and HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)

    -- El portrait nativo está permanentemente oculto via HookScript (en EnsureToTBarsOverlay).
    -- Solo mostramos/ocultamos nuestro overlay; no tocamos el alpha nativo.
    if icon then
        ov.portraitFrame.icon:SetTexture(icon)
        ov.portraitFrame.icon:SetTexCoord(0, 1, 0, 1)
        ov.portraitFrame:Show()
    else
        ov.portraitFrame:Hide()
    end
    API._SyncToTNativePortraitAlpha(_G["TargetFrameToTPortrait"], ov.portraitFrame)
end

-- Actualiza los overlays con datos Harford. Llamar tras cada RefreshTargetOfTargetBars.
local function UpdateToTBarsOverlay(healthData, resourceData)
    local ov = EnsureToTBarsOverlay()
    if not ov then return end

    local tot = FindTargetOfTargetFrame()
    if not (UnitExists and UnitExists("targettarget")) or not (tot and tot.IsShown and tot:IsShown()) then
        HideToTBarsOverlay()
        return
    end

    UpdateToTArtOverlay(FindTargetOfTargetFrame(), ov)

    -- Salud
    if healthData then
        local max = math.max(tonumber(healthData.max) or 0, 0)
        local cur = math.max(tonumber(healthData.cur) or 0, 0)
        local tempCur = math.max(tonumber(healthData.tempCur) or 0, 0)
        ov.healthFrame.bar:SetMinMaxValues(0, math.max(max, 1))
        ov.healthFrame.bar:SetValue(cur)
        ov.healthFrame.bar:SetStatusBarColor(0.0, 0.82, 0.08, 0.95)
        ov.healthFrame:Show()
        ApplyAbsorbTexture(EnsureNativeAbsorbTexture(ov.healthFrame.bar), ov.healthFrame.bar, cur, max, tempCur, 0.85)
    else
        ov.healthFrame:Hide()
    end

    -- Primer recurso (reemplaza mana nativo)
    ov.manaFrame:Show()
    if resourceData then
        local max = math.max(tonumber(resourceData.max) or 0, 0)
        local cur = math.max(tonumber(resourceData.cur) or 0, 0)
        local r, g, b = ResourceColor(resourceData.key)
        ov.manaFrame.bar:SetMinMaxValues(0, math.max(max, 1))
        ov.manaFrame.bar:SetValue(cur)
        ov.manaFrame.bar:SetStatusBarColor(r, g, b, 0.95)
    else
        -- Sin datos aún: barra vacía (fondo oscuro cubre el mana WoW)
        ov.manaFrame.bar:SetValue(0)
    end
end

HideToTBarsOverlay = function()
    if not API.S.totBarsOverlay then return end
    API.S.totBarsOverlay.healthFrame:Hide()
    API.S.totBarsOverlay.manaFrame:Hide()
    if API.S.totBarsOverlay.portraitFrame then API.S.totBarsOverlay.portraitFrame:Hide() end
    if API.S.totBarsOverlay.artFrame then API.S.totBarsOverlay.artFrame:Hide() end
    -- Portrait nativo permanentemente oculto via HookScript; no restaurar alpha.
end

local function HideToTResourceOverlays()
    if not API.S.totBarsOverlay then return end
    API.S.totBarsOverlay.healthFrame:Hide()
    API.S.totBarsOverlay.manaFrame:Hide()
    if API.S.totBarsOverlay.artFrame then API.S.totBarsOverlay.artFrame:Hide() end
end

local function EnsureTargetOfTargetHooks(tot)
    if tot and not tot._harfordToTHooked and tot.HookScript then
        tot._harfordToTHooked = true
        tot:HookScript("OnShow", function()
            ApplyTargetOfTargetLayer()
            if RefreshTargetOfTargetBars then
                RefreshTargetOfTargetBars()
            end
        end)
        tot:HookScript("OnHide", function()
            API.S.targetOfTargetLastGUID = nil
            HideToTBarsOverlay()
        end)
    end
    if API.S.targetOfTargetHooksInstalled then return end
    local installed = false
    if hooksecurefunc then
        if type(_G.TargetofTarget_Update) == "function" then
            hooksecurefunc("TargetofTarget_Update", function()
                ApplyTargetOfTargetLayer()
                if RefreshTargetOfTargetBars then
                    RefreshTargetOfTargetBars()
                end
                local ov = API.S.totBarsOverlay
                API._SyncToTNativePortraitAlpha(_G["TargetFrameToTPortrait"], ov and ov.portraitFrame)
            end)
            installed = true
        end
        if type(_G.TargetFrame_Update) == "function" then
            hooksecurefunc("TargetFrame_Update", function()
                ApplyTargetOfTargetLayer()
                if ReapplyNativeBars then
                    ReapplyNativeBars("target")
                end
            end)
            installed = true
        end
    end
    API.S.targetOfTargetHooksInstalled = installed
end

local function QueueTargetNativeReapply()
    if ReapplyNativeBars then
        ReapplyNativeBars("target")
    end
    if API.S.targetNativeRefreshQueued or not (C_Timer and C_Timer.After) then return end
    API.S.targetNativeRefreshQueued = true
    C_Timer.After(0, function()
        API.S.targetNativeRefreshQueued = false
        if ReapplyNativeBars then
            ReapplyNativeBars("target")
        end
    end)
end

local function InstallNativePowerHooks()
    if API.S.nativePowerHooksInstalled then return end
    API.S.nativePowerHooksInstalled = true

    local targetPower = NativePiecesForUnit("target").power
    if targetPower and targetPower.HookScript then
        targetPower:HookScript("OnValueChanged", function(self)
            if self and self._harfordApplying then return end
            QueueTargetNativeReapply()
        end)
        targetPower:HookScript("OnShow", function()
            QueueTargetNativeReapply()
        end)
    end

    if hooksecurefunc then
        if type(_G.TargetFrame_UpdatePower) == "function" then
            hooksecurefunc("TargetFrame_UpdatePower", QueueTargetNativeReapply)
        end
        if type(_G.UnitFrameManaBar_Update) == "function" then
            hooksecurefunc("UnitFrameManaBar_Update", function(frame)
                if frame == _G.TargetFrame or frame == _G.TargetFrameManaBar or frame == targetPower then
                    QueueTargetNativeReapply()
                end
            end)
        end
        if type(_G.TextStatusBar_UpdateTextStringWithValues) == "function" then
            hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", function(statusFrame)
                -- Compara contra el power bar cacheado (`targetPower`) + el global estable, NO
                -- `NativePiecesForUnit("target").power` (que aloca tabla + escanea en CADA update
                -- de texto de barra de TODA la UI — path muy caliente).
                if statusFrame == targetPower or statusFrame == _G.TargetFrameManaBar then
                    QueueTargetNativeReapply()
                end
            end)
        end
        if type(_G.TextStatusBar_UpdateTextString) == "function" then
            hooksecurefunc("TextStatusBar_UpdateTextString", function(statusFrame)
                -- Compara contra el power bar cacheado (`targetPower`) + el global estable, NO
                -- `NativePiecesForUnit("target").power` (que aloca tabla + escanea en CADA update
                -- de texto de barra de TODA la UI — path muy caliente).
                if statusFrame == targetPower or statusFrame == _G.TargetFrameManaBar then
                    QueueTargetNativeReapply()
                end
            end)
        end
    end
end

local function RestoreTargetOfTargetFrame()
    local tot = FindTargetOfTargetFrame()
    API.S.targetOfTargetDesired = nil
    HarfordUnitFrames._totDesired = nil
    if not API.S.targetOfTargetState then return end
    if not tot then
        API.S.targetOfTargetState = nil
        return
    end
    if API.S.targetOfTargetState.strata and tot.SetFrameStrata then
        tot:SetFrameStrata(API.S.targetOfTargetState.strata)
    end
    if API.S.targetOfTargetState.level and tot.SetFrameLevel then
        tot:SetFrameLevel(API.S.targetOfTargetState.level)
    end
    if API.S.targetOfTargetState.topLevel ~= nil and tot.SetToplevel then
        tot:SetToplevel(API.S.targetOfTargetState.topLevel == true)
    end
    API.S.targetOfTargetState = nil
end

local function AdjustTargetOfTargetFrame(frame, resourceCount, extraHeight)
    if not frame or frame.unit ~= "target" then return end
    resourceCount = tonumber(resourceCount) or 0
    extraHeight = tonumber(extraHeight) or 0
    if resourceCount <= 2 or extraHeight <= 0 then
        RestoreTargetOfTargetFrame()
        return
    end

    local tot = FindTargetOfTargetFrame()
    if not tot then return end
    if not API.S.targetOfTargetState then
        API.S.targetOfTargetState = {
            strata   = tot.GetFrameStrata and tot:GetFrameStrata() or nil,
            level    = tot.GetFrameLevel  and tot:GetFrameLevel()  or nil,
            topLevel = tot.IsToplevel     and tot:IsToplevel()     or nil,
        }
    end

    local base = frame.GetFrameLevel and frame:GetFrameLevel() or 40
    local slotLevel = frame.barSlotsFrame and frame.barSlotsFrame.GetFrameLevel and frame.barSlotsFrame:GetFrameLevel() or (base + 18)
    API.S.targetOfTargetDesired = {
        strata = "HIGH",
        level  = math.max(base + 80, slotLevel + 30),
    }
    HarfordUnitFrames._totDesired = API.S.targetOfTargetDesired
    EnsureTargetOfTargetHooks(tot)
    ApplyTargetOfTargetLayer()
end

SetTextureFromInfo = function(texture, info)
    if info and info.atlas and texture.SetAtlas then
        texture:SetAtlas(info.atlas)
    else
        texture:SetTexture((info and info.path) or API.C.TEX_FRAME)
    end
    if info and info.texCoord then
        texture:SetTexCoord(unpack(info.texCoord))
    else
        texture:SetTexCoord(0, 1, 0, 1)
    end
    if info and info.color then
        texture:SetVertexColor(unpack(info.color))
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end
    texture:SetAlpha((info and info.alpha) or 1)
end

local function NativeVisualContentLevel(unit, native)
    local level = native and native.GetFrameLevel and native:GetFrameLevel() or 1
    local pieces = NativePiecesForUnit(unit)
    for _, object in ipairs({ pieces.health, pieces.power, pieces.level, pieces.name, pieces.texture, pieces.portrait }) do
        if object and object.GetFrameLevel then
            level = math.max(level, object:GetFrameLevel() or 0)
        end
        local parent = object and object.GetParent and object:GetParent()
        if parent and parent.GetFrameLevel then
            level = math.max(level, parent:GetFrameLevel() or 0)
        end
    end
    return level
end

local function SyncUnitFrameLayers(frame, native)
    if not frame then return end
    -- El root del unitframe suele estar en nivel 1, pero sus regiones reales viven
    -- dentro de TextureFrame (nivel ~500 en este cliente). El overlay debe quedar por
    -- encima de ese contenido para recibir hover, sin subir de strata ni atravesar UI.
    local baseLevel = NativeVisualContentLevel(frame.unit, native)
    local strata = native and native.GetFrameStrata and native:GetFrameStrata() or "MEDIUM"

    -- El overlay debe vivir en la misma pila que su unitframe nativo. Los niveles
    -- absolutos hacían que barras extra y auras atravesasen ventanas ajenas.
    if frame.SetFrameStrata then frame:SetFrameStrata(strata) end
    if frame.SetFrameLevel then frame:SetFrameLevel(baseLevel + 1) end
    if frame.visual and frame.visual.SetFrameLevel then frame.visual:SetFrameLevel(baseLevel + 1) end
    if frame.overlayFrame and frame.overlayFrame.SetFrameLevel then frame.overlayFrame:SetFrameLevel(baseLevel + 5) end
    if frame.barSlotsFrame and frame.barSlotsFrame.SetFrameLevel then frame.barSlotsFrame:SetFrameLevel(baseLevel + 5) end
    if frame.levelFrame and frame.levelFrame.SetFrameLevel then frame.levelFrame:SetFrameLevel(baseLevel + 7) end

    for _, bar in pairs(frame.bars or {}) do
        local border = bar.container
        local inner = bar.innerContainer
        if border and border.SetFrameLevel then border:SetFrameLevel(baseLevel + 2) end
        if inner and inner.SetFrameLevel then inner:SetFrameLevel(baseLevel + 3) end
        if bar.SetFrameLevel then bar:SetFrameLevel(baseLevel + 4) end
        local textFrame = inner and inner.textFrame
        if textFrame and textFrame.SetFrameLevel then textFrame:SetFrameLevel(baseLevel + 7) end
    end
end

local function ApplyMeasuredLayout(frame, layout)
    local native = NativeFrameForUnit(frame.unit)
    SyncUnitFrameLayers(frame, native)
    frame:ClearAllPoints()
    if native then
        frame:SetPoint("TOPLEFT", native, "TOPLEFT", 0, 0)
    else
        frame:SetPoint(frame.unit == "player" and "TOPLEFT" or "TOP", UIParent, "TOPLEFT", frame.unit == "player" and 20 or 260, -20)
    end
    frame:SetSize(layout.root.width, layout.root.height)

    frame.visual:ClearAllPoints()
    frame.visual:SetAllPoints(frame)

    frame.overlayFrame:ClearAllPoints()
    frame.overlayFrame:SetAllPoints(frame.visual)
    if frame.barSlotsFrame then
        frame.barSlotsFrame:ClearAllPoints()
        frame.barSlotsFrame:SetAllPoints(frame.visual)
    end
    frame.overlay:ClearAllPoints()
    local textureRel = layout.texture and layout.texture.rel
    if textureRel then
        frame.overlay:SetPoint("TOPLEFT", frame.overlayFrame, "TOPLEFT", textureRel.x, -textureRel.y)
        frame.overlay:SetSize(textureRel.width, textureRel.height)
    else
        frame.overlay:SetAllPoints(frame.overlayFrame)
    end
    SetTextureFromInfo(frame.overlay, layout.texture)

    if frame.portraitLayer then
        frame.portraitLayer:ClearAllPoints()
        if native then
            frame.portraitLayer:SetPoint("TOPLEFT", native, "TOPLEFT", 0, 0)
            if native.GetFrameStrata then frame.portraitLayer:SetFrameStrata(native:GetFrameStrata()) end
            if native.GetFrameLevel then frame.portraitLayer:SetFrameLevel(math.max(0, native:GetFrameLevel() - 1)) end
        else
            frame.portraitLayer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        end
        frame.portraitLayer:SetSize(layout.root.width, layout.root.height)
    end

    local p = layout.portrait
    local inset = p.height >= 48 and math.max(2, math.floor(p.height * 0.04)) or 0
    frame.portraitBg:ClearAllPoints()
    frame.portraitBg:SetPoint("TOPLEFT", frame.portraitLayer or frame.visual, "TOPLEFT", p.x, -p.y)
    frame.portraitBg:SetSize(math.max(1, p.width), math.max(1, p.height))
    frame.portraitBg:SetShown(frame.portraitBgMask ~= nil)
    frame.portrait:ClearAllPoints()
    if frame.portraitBg:IsShown() then
        frame.portrait:SetPoint("TOPLEFT", frame.portraitBg, "TOPLEFT", inset, -inset)
    else
        frame.portrait:SetPoint("TOPLEFT", frame.portraitLayer or frame.visual, "TOPLEFT", p.x + inset, -(p.y + inset))
    end
    frame.portrait:SetSize(math.max(1, p.width - inset * 2), math.max(1, p.height - inset * 2))
    if frame.portraitMask then
        frame.portraitMask:ClearAllPoints()
        frame.portraitMask:SetAllPoints(frame.portrait)
    end
    if frame.portraitBgMask then
        frame.portraitBgMask:ClearAllPoints()
        frame.portraitBgMask:SetAllPoints(frame.portraitBg)
    end

    frame.levelFrame:ClearAllPoints()
    frame.levelFrame:SetAllPoints(frame.visual)

    local l = layout.level
    frame.level:ClearAllPoints()
    frame.level:SetPoint("CENTER", frame.levelFrame, "TOPLEFT", l.cx, -l.cy)
    frame.level:SetSize(l.width or 22, l.height or 16)
    if frame.levelBgMask then
        frame.levelBgMask:ClearAllPoints()
        frame.levelBgMask:SetAllPoints(frame.levelBg)
    end

    local name = layout.name
    local health = layout.health
    local nameWidth = (name and name.width and name.width > 0 and name.width) or health.width
    local nameHeight = (name and name.height and name.height > 0 and name.height) or 14
    local nameCx = (name and name.cx) or (health.x + health.width / 2)
    local nameCy = (name and name.cy) or math.max(0, health.y - nameHeight / 2 - 2)

    frame.nameBg:ClearAllPoints()
    frame.nameBg:SetPoint("CENTER", frame.visual, "TOPLEFT", nameCx, -nameCy)
    frame.nameBg:SetSize(nameWidth + 4, nameHeight + 2)
    frame.name:ClearAllPoints()
    frame.name:SetAllPoints(frame.nameBg)

    frame.layout = layout
end

local function CreateUnitFrame(key, unit)
    if API.S.frames[unit] then return API.S.frames[unit] end

    -- El overlay pertenece al unitframe nativo: mantiene el mismo orden de strata y
    -- evita que sus barras se comporten como una ventana independiente de UIParent.
    local parent = NativeFrameForUnit(unit) or UIParent
    local frame = CreateFrame("Button", "Harford" .. key .. "UnitFrame", parent, "SecureUnitButtonTemplate")
    frame.unit = unit
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    -- Mouse desactivado: el frame nativo (TargetFrame/PlayerFrame) sigue visible y maneja
    -- click-to-target, menu y tooltips de buffs. Si Harford captura mouse bloquea los buff icons.
    frame:EnableMouse(false)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(40)

    local visual = CreateFrame("Frame", nil, frame)
    visual:SetFrameLevel(frame:GetFrameLevel())
    frame.visual = visual

    local portraitLayer = CreateFrame("Frame", nil, UIParent)
    portraitLayer:SetFrameStrata("LOW")
    portraitLayer:SetFrameLevel(1)
    frame.portraitLayer = portraitLayer

    local overlayFrame = CreateFrame("Frame", nil, visual)
    overlayFrame:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame.overlayFrame = overlayFrame

    local overlay = overlayFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.overlay = overlay

    -- Frame dedicado exclusivamente para los slot-overlays de barras extra (3+).
    -- Es hijo de visual (no de overlayFrame) para no verse afectado por el
    -- overlayFrame:Hide() del reset flow. Frame level > borderFrame (+4) para
    -- que las texturas queden encima de las barras.
    local barSlotsFrame = CreateFrame("Frame", nil, visual)
    barSlotsFrame:SetAllPoints(visual)
    barSlotsFrame:SetFrameLevel(frame:GetFrameLevel() + 18)
    frame.barSlotsFrame = barSlotsFrame
    frame.barSlotOverlays = {}

    local portraitBg = portraitLayer:CreateTexture(nil, "BACKGROUND")
    portraitBg:SetTexture(API.C.TEX_WHITE)
    portraitBg:SetVertexColor(0.02, 0.02, 0.02, 1)
    frame.portraitBg = portraitBg

    local portrait = portraitLayer:CreateTexture(nil, "ARTWORK")
    portrait:SetTexCoord(0, 1, 0, 1)
    frame.portrait = portrait

    local nameBg = visual:CreateTexture(nil, "ARTWORK")
    nameBg:SetTexture(API.C.TEX_WHITE)
    nameBg:SetVertexColor(0.02, 0.02, 0.02, 0.72)
    frame.nameBg = nameBg

    local levelBg = visual:CreateTexture(nil, "ARTWORK")
    levelBg:SetTexture(API.C.TEX_WHITE)
    levelBg:SetVertexColor(0, 0, 0, 0.92)
    levelBg:Hide()
    frame.levelBg = levelBg

    if portrait.AddMaskTexture and visual.CreateMaskTexture then
        local mask = portraitLayer:CreateMaskTexture(nil, "ARTWORK")
        mask:SetTexture(API.C.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(portrait)
        portrait:AddMaskTexture(mask)
        frame.portraitMask = mask

        if portraitBg.AddMaskTexture then
            local bgMask = portraitLayer:CreateMaskTexture(nil, "ARTWORK")
            bgMask:SetTexture(API.C.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            bgMask:SetAllPoints(portraitBg)
            portraitBg:AddMaskTexture(bgMask)
            frame.portraitBgMask = bgMask
        end

        if levelBg.AddMaskTexture then
            local levelMask = visual:CreateMaskTexture(nil, "ARTWORK")
            levelMask:SetTexture(API.C.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            levelMask:SetAllPoints(levelBg)
            levelBg:AddMaskTexture(levelMask)
            frame.levelBgMask = levelMask
        end
    end

    local levelFrame = CreateFrame("Frame", nil, visual)
    levelFrame:SetFrameLevel(frame:GetFrameLevel() + 35)
    frame.levelFrame = levelFrame

    local level = levelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    level:SetDrawLayer("OVERLAY", 8)
    level:SetJustifyH("CENTER")
    level:SetJustifyV("MIDDLE")
    level:SetTextColor(1, 0.82, 0.1)
    frame.level = level

    local name = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetDrawLayer("OVERLAY", 8)
    name:SetJustifyH("CENTER")
    name:SetJustifyV("MIDDLE")
    name:SetTextColor(1, 0.82, 0.1)
    frame.name = name

    local fallback = visual:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fallback:SetDrawLayer("OVERLAY", 8)
    fallback:SetJustifyH("CENTER")
    fallback:SetJustifyV("MIDDLE")
    fallback:SetTextColor(0.95, 0.95, 0.95)
    frame.fallback = fallback

    frame.bars = {}
    ApplyMeasuredLayout(frame, GetOrMeasureLayout(unit))

    API.S.frames[unit] = frame
    return frame
end

local function GetStatusTextMode()
    if not GetCVar then return "NUMERIC" end
    local val = GetCVar("statusTextDisplay")
    if not val or val == "" then return "NUMERIC" end  -- Epsilon: CVar desconocido → numérico
    return val:upper()
end

local function IsCVarEnabled(name)
    if GetCVarBool then
        local ok, value = pcall(GetCVarBool, name)
        if ok and value ~= nil then
            return value == true or value == 1
        end
    end
    if GetCVar then
        local ok, value = pcall(GetCVar, name)
        if ok then
            value = tostring(value or ""):lower()
            return value == "1" or value == "true" or value == "enabled"
        end
    end
    return false
end

local function BoolOption(value)
    return value == true or value == 1 or value == "1" or value == "true"
end

local function GetActiveRaidProfileOption(optionName)
    if type(GetActiveRaidProfile) == "function" and type(GetRaidProfileOption) == "function" then
        local okProfile, profile = pcall(GetActiveRaidProfile)
        if okProfile and profile then
            local okOption, value = pcall(GetRaidProfileOption, profile, optionName)
            if okOption and value ~= nil then
                return value
            end
        end
    end
    return nil
end

local function ShouldUseCompactClassColor(frame)
    local options = frame and frame.optionTable
    if type(options) == "table" and options.useClassColors ~= nil then
        return BoolOption(options.useClassColors)
    end
    if type(options) == "table" and options.displayClassColor ~= nil then
        return BoolOption(options.displayClassColor)
    end

    local profileValue = GetActiveRaidProfileOption("useClassColors")
    if profileValue ~= nil then
        return BoolOption(profileValue)
    end

    profileValue = GetActiveRaidProfileOption("displayClassColor")
    if profileValue ~= nil then
        return BoolOption(profileValue)
    end

    return IsCVarEnabled("raidFramesDisplayClassColor")
end

-- Texto corto: solo valores, sin nombre de recurso. Se muestra siempre en NUMERIC/PERCENT/BOTH.
local function FormatShortText(cur, max, tempCur)
    local mode = GetStatusTextMode()
    local pct = max > 0 and math.floor(cur / max * 100) or 0
    local temp = (tempCur and tempCur > 0) and ("+" .. tempCur) or ""
    if mode == "PERCENT" then
        return pct .. "%"
    elseif mode == "BOTH" then
        return cur .. temp .. "/" .. max .. " (" .. pct .. "%)"
    end
    return cur .. temp .. "/" .. max
end

-- Texto completo: nombre de recurso + valores. Se muestra en hover (o siempre en NONE).
local function FormatFullText(label, cur, max, tempCur)
    local mode = GetStatusTextMode()
    local pct = max > 0 and math.floor(cur / max * 100) or 0
    local temp = (tempCur and tempCur > 0) and ("+" .. tempCur) or ""
    if mode == "PERCENT" then
        return label .. " " .. pct .. "%"
    elseif mode == "BOTH" then
        return label .. " " .. cur .. temp .. "/" .. max .. " (" .. pct .. "%)"
    end
    return label .. " " .. cur .. temp .. "/" .. max
end

-- Hookea las barras nativas (health/power) una sola vez para mostrar/ocultar
-- el texto de Harford en hover sin reemplazar los scripts originales de WoW.
local function HookNativeBarForHover(nativeBar)
    if not nativeBar or nativeBar._harfordHooked then return end
    nativeBar._harfordHooked = true
    nativeBar:HookScript("OnEnter", function(self)
        local text = self._harfordTextRegion or self.TextString
        if text and self._harfordFullText then
            text:SetText(self._harfordFullText)
            text:Show()
        end
    end)
    nativeBar:HookScript("OnLeave", function(self)
        if not self._harfordShortText and not self._harfordFullText then return end
        local text = self._harfordTextRegion or self.TextString
        if not text then return end
        local mode = GetStatusTextMode()
        if mode ~= "NONE" and mode ~= "0" and self._harfordShortText then
            text:SetText(self._harfordShortText)
            text:Show()
        else
            text:Hide()
        end
    end)
end

local function GetNativeBarTextRegion(nativeBar)
    if not nativeBar then return nil end
    if nativeBar.TextString then return nativeBar.TextString end
    if nativeBar.Text then return nativeBar.Text end
    if InCombatLockdown and InCombatLockdown() then
        return nativeBar._harfordTextRegion
    end
    if not nativeBar._harfordTextRegion and nativeBar.CreateFontString then
        local text = nativeBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetAllPoints(nativeBar)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetTextColor(1, 1, 1)
        nativeBar._harfordTextRegion = text
    end
    return nativeBar._harfordTextRegion
end

ApplyAbsorbTexture = function(texture, owner, cur, max, temp, alpha)
    if not texture or not owner then return end
    max = math.max(tonumber(max) or 0, 0)
    temp = math.max(tonumber(temp) or 0, 0)
    if max <= 0 or temp <= 0 then
        texture:Hide()
        local decorOwner = texture._harfordAbsorbDecorOwner or owner
        if decorOwner then
            if decorOwner._harfordAbsorbBase then decorOwner._harfordAbsorbBase:Hide() end
            if decorOwner._harfordAbsorbEdge then decorOwner._harfordAbsorbEdge:Hide() end
        end
        return
    end

    local function EnsureDecor(frame)
        if not frame or not frame.CreateTexture then return end
        if not frame._harfordAbsorbPattern then
            local pattern = frame:CreateTexture(nil, "ARTWORK", nil, 1)
            pattern:SetTexture(API.C.TEX_ABSORB, "REPEAT", "CLAMP")
            pattern:SetBlendMode("BLEND")
            pattern:SetVertexColor(0.40, 0.70, 1.0, 1.0)
            pattern:Hide()
            frame._harfordAbsorbPattern = pattern
        end
        if not frame._harfordAbsorbSpark then
            local spark = frame:CreateTexture(nil, "ARTWORK", nil, 2)
            spark:SetTexture(API.C.TEX_ABSORB_EDGE)
            spark:SetBlendMode("ADD")
            spark:SetVertexColor(0.55, 0.80, 1.0, 1.0)
            spark:Hide()
            frame._harfordAbsorbSpark = spark
        end
    end

    local function UpdateDecor(frame, pct, ownerWidth, ownerHeight, a)
        EnsureDecor(frame)
        local w = math.max(1, (ownerWidth or 1) * pct)
        local h = math.max(6, ownerHeight or (owner.GetHeight and owner:GetHeight() or 10))
        -- Pattern y glow ocultos: el StatusBar usa TEX_ABSORB_FILL directamente como fill,
        -- así que el overlay de patrón es redundante y causaba ancho=0 cuando ownerWidth no estaba listo.
        if frame._harfordAbsorbPattern then frame._harfordAbsorbPattern:Hide() end
        if frame._harfordAbsorbGlow then frame._harfordAbsorbGlow:Hide() end
        if frame._harfordAbsorbSpark then
            frame._harfordAbsorbSpark:ClearAllPoints()
            frame._harfordAbsorbSpark:SetSize(math.max(5, h * 0.8), math.max(4, h * 0.9))
            -- fillTex:RIGHT en Epsilon apunta al extremo del bar entero (texcoords, no resize).
            -- Calcular posición manual: frame:GetWidth() * pct = píxel exacto del borde del fill.
            local realW = (frame.GetWidth and frame:GetWidth() or 0)
            if realW <= 0 then realW = ownerWidth or 0 end
            local edgeOffset = frame._harfordGroupAbsorb == true and 2 or 0
            frame._harfordAbsorbSpark:SetPoint("CENTER", frame, "LEFT", realW * pct + edgeOffset, 0)
            frame._harfordAbsorbSpark:SetAlpha(math.min(0.65, (a or 0.85) * 0.70))
            frame._harfordAbsorbSpark:Show()
        end
    end

    if texture.SetStatusBarTexture then
        texture:ClearAllPoints()
        texture:SetAllPoints(owner)
        -- Usar la textura de escudo directamente como fill del StatusBar.
        -- Así el fill escala solo (sin depender de GetWidth) y muestra la textura real.
        texture:SetStatusBarTexture(API.C.TEX_ABSORB_FILL)
        local tex = texture.GetStatusBarTexture and texture:GetStatusBarTexture()
        if tex and tex.SetHorizTile then tex:SetHorizTile(false) end  -- Shield-Fill se estira, no tilea
        if tex and tex.SetVertTile then tex:SetVertTile(false) end
        texture:SetMinMaxValues(0, max)
        texture:SetValue(math.min(temp, max))
        texture:SetStatusBarColor(0.35, 0.82, 1.0, 1.0)
        if texture.SetAlpha then texture:SetAlpha(alpha or 0.85) end
        texture:Show()
        local w = owner.GetWidth and owner:GetWidth() or 0
        local h = owner.GetHeight and owner:GetHeight() or 0
        UpdateDecor(texture, math.min(temp / max, 1), w, h, alpha or 0.85)
        return
    end

    local ownerWidth = owner.GetWidth and owner:GetWidth() or 0
    if ownerWidth <= 1 then
        texture:Hide()
        return
    end

    -- El absorb se solapa sobre la barra de vida desde el origen (OVERLAY sobre ARTWORK).
    -- El edge marca el final del área de absorb.
    local absorbWidth = math.max(1, math.min((temp / max) * ownerWidth, ownerWidth))
    local ownerHeight = owner.GetHeight and owner:GetHeight() or 0
    local decorOwner  = texture._harfordAbsorbDecorOwner or owner
    if decorOwner and decorOwner.CreateTexture and not decorOwner._harfordAbsorbBase then
        local base = decorOwner:CreateTexture(nil, "OVERLAY", nil, -3)
        base:SetTexture(API.C.TEX_WHITE)
        base:SetVertexColor(0.10, 0.62, 0.95, 0.88)
        base:Hide()
        decorOwner._harfordAbsorbBase = base
    end
    if decorOwner and decorOwner.CreateTexture and not decorOwner._harfordAbsorbEdge then
        local edge = decorOwner:CreateTexture(nil, "OVERLAY", nil, -1)
        edge:SetTexture(API.C.TEX_ABSORB_EDGE)
        edge:SetBlendMode("ADD")
        edge:SetVertexColor(0.75, 0.95, 1.0, 0.95)
        edge:Hide()
        decorOwner._harfordAbsorbEdge = edge
    end

    if decorOwner and decorOwner._harfordAbsorbBase then
        if decorOwner._harfordAbsorbBase.SetDrawLayer then decorOwner._harfordAbsorbBase:SetDrawLayer("OVERLAY", -3) end
        decorOwner._harfordAbsorbBase:ClearAllPoints()
        decorOwner._harfordAbsorbBase:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
        decorOwner._harfordAbsorbBase:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
        decorOwner._harfordAbsorbBase:SetWidth(absorbWidth)
        decorOwner._harfordAbsorbBase:SetAlpha(math.min(0.88, math.max(0.72, alpha or 0.85)))
        decorOwner._harfordAbsorbBase:Show()
    end

    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    texture:SetPoint("BOTTOMLEFT", owner, "BOTTOMLEFT", 0, 0)
    texture:SetWidth(absorbWidth)
    if texture.SetDrawLayer then texture:SetDrawLayer("OVERLAY", -2) end
    texture:SetTexture(API.C.TEX_ABSORB, "REPEAT", "CLAMP")
    if texture.SetHorizTile then texture:SetHorizTile(true) end
    if texture.SetVertTile then texture:SetVertTile(false) end
    if texture.SetVertexColor then texture:SetVertexColor(0.95, 1.0, 1.0, 1.0) end
    if texture.SetAlpha then texture:SetAlpha(math.min(0.60, (alpha or 0.85) * 0.65)) end
    texture:Show()
    if decorOwner and decorOwner._harfordAbsorbEdge then
        local h = math.max(6, ownerHeight)
        if decorOwner._harfordAbsorbEdge.SetDrawLayer then decorOwner._harfordAbsorbEdge:SetDrawLayer("OVERLAY", -1) end
        decorOwner._harfordAbsorbEdge:ClearAllPoints()
        decorOwner._harfordAbsorbEdge:SetSize(math.max(5, h * 0.8), math.max(4, h * 0.9))
        decorOwner._harfordAbsorbEdge:SetPoint("CENTER", owner, "LEFT", absorbWidth, 0)
        decorOwner._harfordAbsorbEdge:SetAlpha(math.min(0.65, (alpha or 0.85) * 0.70))
        decorOwner._harfordAbsorbEdge:Show()
    end
    if texture._harfordAbsorbGlow then texture._harfordAbsorbGlow:Hide() end
    if texture._harfordAbsorbSpark then texture._harfordAbsorbSpark:Hide() end
end

EnsureNativeAbsorbTexture = function(nativeBar)
    if not nativeBar or not CreateFrame then return nil end
    if nativeBar._harfordAbsorbTexture then return nativeBar._harfordAbsorbTexture end
    local texture = nativeBar:CreateTexture(nil, "OVERLAY", nil, -2)
    texture:SetTexture(API.C.TEX_ABSORB, "REPEAT", "CLAMP")
    if texture.SetHorizTile then texture:SetHorizTile(true) end
    if texture.SetVertTile then texture:SetVertTile(false) end
    texture._harfordAbsorbDecorOwner = nativeBar
    texture:Hide()
    nativeBar._harfordAbsorbTexture = texture
    return texture
end

local function EnsureBar(frame, index)
    frame.bars = frame.bars or {}
    if frame.bars[index] then return frame.bars[index] end

    -- Frame contenedor para posicionamiento y propagación de Show/Hide.
    -- Sin borde de color propio: el overlay de barSlotsFrame (textura del frame
    -- nativo) provee el borde visual igual que en las barras de vida/maná.
    local borderFrame = CreateFrame("Frame", nil, frame.visual)
    borderFrame:SetFrameLevel(frame.visual:GetFrameLevel() + 1)
    borderFrame:EnableMouse(false)

    -- Contenedor interior: llena borderFrame completamente.
    -- El overlay de textura cubre esta área y su "agujero" transparente deja ver la barra.
    local container = CreateFrame("Frame", nil, borderFrame)
    container:SetAllPoints(borderFrame)
    container:SetFrameLevel(borderFrame:GetFrameLevel() + 1)
    container:EnableMouse(true)

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(container)
    bg:SetTexture(API.C.TEX_WHITE)
    bg:SetTexCoord(0, 1, 0, 1)
    bg:SetVertexColor(0.015, 0.015, 0.015, API.C.EXTRA_BAR_BG_ALPHA)
    bg:SetAlpha(API.C.EXTRA_BAR_BG_ALPHA)
    bg:Show()
    container.bg = bg

    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetStatusBarTexture(API.C.TEX_STATUS)
    bar:SetFrameLevel(container:GetFrameLevel() + 1)
    bar:SetAllPoints(container)

    local textFrame = CreateFrame("Frame", nil, container)
    textFrame:SetAllPoints(container)
    -- Debe quedar un nivel sobre barSlotsFrame (+5): al compartir nivel, la
    -- textura del marco puede tapar el texto completo mostrado al pasar el raton.
    textFrame:SetFrameLevel(frame.visual:GetFrameLevel() + 7)
    container.textFrame = textFrame

    local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetAllPoints(textFrame)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(1, 1, 1)
    bar.text = text

    -- bar.container = borderFrame (para posicionamiento y show/hide externo).
    -- bar.innerContainer = container (para acceder a .bg, .textFrame, mouse events).
    -- Los shortcuts permiten que el código externo siga usando bar.container.bg etc.
    bar.container = borderFrame
    bar.innerContainer = container
    borderFrame.bg = bg                        -- bar.container.bg sigue funcionando
    borderFrame.textFrame = container.textFrame -- bar.container.textFrame idem

    container:SetScript("OnEnter", function()
        if bar._harfordFullText then text:SetText(bar._harfordFullText) end
        text:Show()
    end)
    container:SetScript("OnLeave", function()
        local mode = GetStatusTextMode()
        if mode ~= "NONE" and mode ~= "0" and bar._harfordShortText then
            text:SetText(bar._harfordShortText)
            text:Show()
        else
            text:Hide()
        end
    end)

    frame.bars[index] = bar
    frame.maxBarIndex = math.max(frame.maxBarIndex or 0, index)
    return bar
end


local function ApplyExtraBarBackground(bg)
    if not bg then return end
    -- Imitamos el hueco sombreado del unitframe nativo sin arrastrar textura
    -- del aro del portrait ni colores residuales del statusbar.
    bg:SetTexture(API.C.TEX_WHITE)
    bg:SetTexCoord(0, 1, 0, 1)
    bg:SetVertexColor(0.015, 0.015, 0.015, API.C.EXTRA_BAR_BG_ALPHA)
    bg:SetAlpha(API.C.EXTRA_BAR_BG_ALPHA)
    bg:Show()
end


local function ApplyBarTextureInfo(bar, index)
    local layout = bar.ownerLayout
    local bgInfo, fillInfo
    if layout then
        if index == 1 then
            bgInfo = layout.healthBg
            fillInfo = layout.healthFill
        elseif index == 2 then
            bgInfo = layout.powerBg
            fillInfo = layout.powerFill
        end
    end

    if bar.container and bar.container.bg then
        if index and index > 2 then
            ApplyExtraBarBackground(bar.container.bg)
        elseif bgInfo then
            SetTextureFromInfo(bar.container.bg, bgInfo)
            bar.container.bg:SetVertexColor(0.025, 0.025, 0.025, 0.82)
            bar.container.bg:SetAlpha(0.82)
        else
            bar.container.bg:SetTexture(API.C.TEX_STATUS)
            bar.container.bg:SetTexCoord(0, 1, 0, 1)
            bar.container.bg:SetVertexColor(0.025, 0.025, 0.025, 0.72)
            bar.container.bg:SetAlpha(0.72)
        end
    end

    if fillInfo then
        local statusTexture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
        if fillInfo.atlas and statusTexture and statusTexture.SetAtlas then
            statusTexture:SetAtlas(fillInfo.atlas)
        elseif fillInfo.path then
            bar:SetStatusBarTexture(fillInfo.path)
        else
            bar:SetStatusBarTexture(API.C.TEX_STATUS)
        end
    else
        bar:SetStatusBarTexture(API.C.TEX_STATUS)
    end
end

local function ApplyNativeStatusBar(nativeBar, data)
    if not nativeBar or not data then return end
    local max = math.max(tonumber(data.max) or 0, 0)
    local cur = math.max(tonumber(data.cur) or 0, 0)
    local r, g, b = ResourceColor(data.key)
    if data.key == "health" then
        r, g, b = 0.0, 0.82, 0.08
    end

    nativeBar._harfordApplying = true
    if nativeBar.SetMinMaxValues then
        nativeBar:SetMinMaxValues(0, max > 0 and max or 1)
    end
    if nativeBar.SetValue then
        nativeBar:SetValue(math.min(cur, max > 0 and max or cur))
    end
    if nativeBar.SetStatusBarColor then
        nativeBar:SetStatusBarColor(r, g, b, 0.95)
    end
    if nativeBar.GetStatusBarTexture and nativeBar:GetStatusBarTexture() and nativeBar:GetStatusBarTexture().SetDesaturated then
        nativeBar:GetStatusBarTexture():SetDesaturated(false)
    end
    if data.key == "health" then
        ApplyAbsorbTexture(EnsureNativeAbsorbTexture(nativeBar), nativeBar, cur, max, data.tempCur, 0.85)
    elseif nativeBar._harfordAbsorbTexture then
        nativeBar._harfordAbsorbTexture:Hide()
        if nativeBar._harfordAbsorbBase then nativeBar._harfordAbsorbBase:Hide() end
        if nativeBar._harfordAbsorbEdge then nativeBar._harfordAbsorbEdge:Hide() end
    end
    nativeBar._harfordApplying = nil
    nativeBar._harfordShortText = nil
    nativeBar._harfordFullText = nil
    if nativeBar.TextString then
        nativeBar.TextString:SetText("")
        nativeBar.TextString:Hide()
    end
    if nativeBar.LeftText then nativeBar.LeftText:Hide() end
    if nativeBar.RightText then nativeBar.RightText:Hide() end
    if nativeBar.Text then
        nativeBar.Text:SetText("")
        nativeBar.Text:Hide()
    end
end

local function ApplyPendingNativeStatusBar(nativeBar, key)
    if not nativeBar then return end
    nativeBar._harfordApplying = true
    if nativeBar.SetMinMaxValues then
        nativeBar:SetMinMaxValues(0, 1)
    end
    if nativeBar.SetValue then
        nativeBar:SetValue(0)
    end
    if nativeBar.SetStatusBarColor then
        if key == "health" then
            nativeBar:SetStatusBarColor(0.0, 0.55, 0.08, 0.75)
        else
            nativeBar:SetStatusBarColor(0.05, 0.05, 0.05, 0.85)
        end
    end
    if nativeBar.GetStatusBarTexture and nativeBar:GetStatusBarTexture() and nativeBar:GetStatusBarTexture().SetDesaturated then
        nativeBar:GetStatusBarTexture():SetDesaturated(false)
    end
    if nativeBar._harfordAbsorbTexture then
        nativeBar._harfordAbsorbTexture:Hide()
        if nativeBar._harfordAbsorbBase then nativeBar._harfordAbsorbBase:Hide() end
        if nativeBar._harfordAbsorbEdge then nativeBar._harfordAbsorbEdge:Hide() end
    end
    nativeBar._harfordApplying = nil
    nativeBar._harfordShortText = nil
    nativeBar._harfordFullText = nil
    if nativeBar.TextString then
        nativeBar.TextString:SetText("")
        nativeBar.TextString:Hide()
    end
    if nativeBar.LeftText then nativeBar.LeftText:Hide() end
    if nativeBar.RightText then nativeBar.RightText:Hide() end
    if nativeBar.Text then
        nativeBar.Text:SetText("")
        nativeBar.Text:Hide()
    end
end

local function HideNativeStatusBarText(nativeBar)
    if not nativeBar then return end
    if nativeBar.TextString and nativeBar.TextString.Hide then nativeBar.TextString:Hide() end
    if nativeBar.LeftText and nativeBar.LeftText.Hide then nativeBar.LeftText:Hide() end
    if nativeBar.RightText and nativeBar.RightText.Hide then nativeBar.RightText:Hide() end
    if nativeBar.Text and nativeBar.Text.Hide then nativeBar.Text:Hide() end
end

local function ClearHarfordNativeBarMarks(nativeBar)
    if not nativeBar then return end
    nativeBar._harfordShortText = nil
    nativeBar._harfordFullText = nil
    nativeBar._harfordCompactFrame = nil
    nativeBar._harfordApplying = nil
end

local function RestoreNativeStatusText(nativeBar)
    if not nativeBar then return end
    if nativeBar.TextString and nativeBar.TextString.SetText then nativeBar.TextString:SetText("") end
    if nativeBar.LeftText and nativeBar.LeftText.Show then nativeBar.LeftText:Show() end
    if nativeBar.RightText and nativeBar.RightText.Show then nativeBar.RightText:Show() end
    if nativeBar.Text and nativeBar.Text.Show then nativeBar.Text:Show() end
    if type(_G.TextStatusBar_UpdateTextString) == "function" then
        pcall(_G.TextStatusBar_UpdateTextString, nativeBar)
    elseif nativeBar.TextString and nativeBar.TextString.Show then
        nativeBar.TextString:Show()
    end
end

local function GetWoWPowerColor(unit)
    local powerType, powerToken = 0, nil
    if UnitPowerType then
        powerType, powerToken = UnitPowerType(unit)
    end
    local color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if color then
        return color.r or color[1] or 0, color.g or color[2] or 0, color.b or color[3] or 1
    end
    return 0, 0, 1
end

local function RestoreNativeBarFromUnit(nativeBar, unit, kind, showText)
    if not nativeBar or not unit or not (UnitExists and UnitExists(unit)) then return false end

    ClearHarfordNativeBarMarks(nativeBar)
    if nativeBar._harfordAbsorbTexture then
        nativeBar._harfordAbsorbTexture:Hide()
        if nativeBar._harfordAbsorbBase then nativeBar._harfordAbsorbBase:Hide() end
        if nativeBar._harfordAbsorbEdge then nativeBar._harfordAbsorbEdge:Hide() end
    end
    if nativeBar.Show then nativeBar:Show() end
    if nativeBar.SetAlpha then nativeBar:SetAlpha(1) end
    if nativeBar.GetStatusBarTexture and nativeBar:GetStatusBarTexture() and nativeBar:GetStatusBarTexture().SetDesaturated then
        nativeBar:GetStatusBarTexture():SetDesaturated(false)
    end

    local cur, max, r, g, b
    if kind == "power" then
        local powerType = UnitPowerType and UnitPowerType(unit) or 0
        cur = UnitPower and UnitPower(unit, powerType) or 0
        max = UnitPowerMax and UnitPowerMax(unit, powerType) or 1
        r, g, b = GetWoWPowerColor(unit)
    else
        cur = UnitHealth and UnitHealth(unit) or 0
        max = UnitHealthMax and UnitHealthMax(unit) or 1
        r, g, b = 0, 1, 0
    end

    max = math.max(tonumber(max) or 0, 0)
    cur = math.max(tonumber(cur) or 0, 0)
    nativeBar._harfordApplying = true
    if nativeBar.SetMinMaxValues then nativeBar:SetMinMaxValues(0, max > 0 and max or 1) end
    if nativeBar.SetValue then nativeBar:SetValue(math.min(cur, max > 0 and max or cur)) end
    if nativeBar.SetStatusBarColor then nativeBar:SetStatusBarColor(r, g, b, 1) end
    nativeBar._harfordApplying = nil

    if showText ~= false then
        RestoreNativeStatusText(nativeBar)
    else
        if nativeBar.TextString and nativeBar.TextString.Hide then nativeBar.TextString:Hide() end
        if nativeBar.LeftText and nativeBar.LeftText.Hide then nativeBar.LeftText:Hide() end
        if nativeBar.RightText and nativeBar.RightText.Hide then nativeBar.RightText:Hide() end
        if nativeBar.Text and nativeBar.Text.Hide then nativeBar.Text:Hide() end
    end
    return true
end

local function ApplyNativeResourceText(nativeBar, data)
    if not nativeBar or not data then return end
    local cur = math.max(tonumber(data.cur) or 0, 0)
    local max = math.max(tonumber(data.max) or 0, 0)
    local tempCur = math.max(tonumber(data.tempCur) or 0, 0)
    local shortText = FormatShortText(cur, max, tempCur)
    local fullText  = FormatFullText(tostring(data.label or data.key), cur, max, tempCur)

    nativeBar._harfordShortText = shortText
    nativeBar._harfordFullText = fullText
    HookNativeBarForHover(nativeBar)

    local text = GetNativeBarTextRegion(nativeBar)
    if text then
        if text.SetDrawLayer then text:SetDrawLayer("OVERLAY", 7) end
        local mode = GetStatusTextMode()
        local hovering = nativeBar.IsMouseOver and nativeBar:IsMouseOver()
        if hovering then
            text:SetText(fullText)
            text:Show()
        elseif mode ~= "NONE" and mode ~= "0" then
            text:SetText(shortText)
            text:Show()
        else
            text:SetText(fullText)
            text:Hide()
        end
    end
end

local function ApplyNativeResourceBars(unit, maxBars, showText)
    local pieces = NativePiecesForUnit(unit)
    local unitName = SafeUnitName(unit)
    local resources = HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName and HarfordDnDAPI.GetResourcesForName(unitName or "")
    local list = BuildResourceList(resources)

    -- Contadores para /harford debug run totrate
    local _rateCtx = _G._HarfordTotRateActive
    if _rateCtx and unit == "targettarget" then
        _rateCtx.refreshBars = _rateCtx.refreshBars + 1
    end

    if unit == "targettarget" or unit == "focustarget" then
        -- Las barras nativas del ToT (health y power) son repintadas constantemente por
        -- Blizzard via OnUpdate/OnValueChanged. No las tocamos: los overlays Harford las tapan
        -- con StatusBar frames propios en frame level superior.
        if _rateCtx then _rateCtx.alphaOne = _rateCtx.alphaOne + 1 end
    else
        ApplyNativeStatusBar(pieces.health, list[1])
        ApplyNativeStatusBar(pieces.power, list[2])
    end

    HideNativeStatusBarText(pieces.health)
    HideNativeStatusBarText(pieces.power)

    maxBars = math.min(tonumber(maxBars) or 2, 2)
    if showText ~= false then
        for i = 1, math.min(#list, maxBars) do
            ApplyNativeResourceText(i == 1 and pieces.health or pieces.power, list[i])
        end
    end

    return list, resources, unitName
end

-- ── FOCUS TARGET OF TARGET OVERLAY ─────────────────────────────────────────
-- Sistema paralelo al totBarsOverlay para FocusFrameToT / unit "focustarget".
-- Encapsulado en do...end para no consumir slots de local del scope global
-- (el archivo ya roza el límite de 200 locales de Lua 5.1).
-- Las funciones públicas se exponen via focusTot.hide / .refresh / .ensureHooks.
-- IMPORTANTE: este bloque debe estar DESPUÉS de ApplyNativeResourceBars (local).
do

local function EnsureFocusTotBarsOverlay()
    if API.S.focusTot.overlay then return API.S.focusTot.overlay end
    local healthNative = _G["FocusFrameToTHealthBar"]
    local manaNative   = _G["FocusFrameToTManaBar"]
    local tot          = _G["FocusFrameToT"]
    if not healthNative or not manaNative or not tot then return nil end

    local ov = {
        healthFrame = MakeToTBarOverlayFrame(healthNative),
        manaFrame   = MakeToTBarOverlayFrame(manaNative),
        artFrame    = MakeToTArtOverlayFrame(tot),
    }

    -- Portrait nativo: ocultarlo permanentemente con HookScript.
    local portraitNative = _G["FocusFrameToTPortrait"]
    HideToTNativePortrait(portraitNative)

    if portraitNative then
        local pf = CreateFrame("Frame", nil, tot)
        if pf.SetFrameLevel and tot.GetFrameLevel then pf:SetFrameLevel((tot:GetFrameLevel() or 0) + 3) end
        local ok = pcall(function() pf:SetAllPoints(portraitNative) end)
        if not ok then
            pf:SetSize(32, 32)
            pf:SetPoint("TOPLEFT", tot, "TOPLEFT", 2, -2)
        end
        local pbg = pf:CreateTexture(nil, "BACKGROUND", nil, 0)
        pbg:SetAllPoints(pf)
        pbg:SetColorTexture(0.04, 0.04, 0.04, 1)
        pf.bg = pbg
        local ptex = pf:CreateTexture(nil, "ARTWORK", nil, 1)
        ptex:SetAllPoints(pf)
        ptex:SetTexCoord(0, 1, 0, 1)
        pf.icon = ptex
        if ptex.AddMaskTexture and pf.CreateMaskTexture then
            local mask = pf:CreateMaskTexture(nil, "ARTWORK")
            mask:SetTexture(API.C.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(pf)
            pbg:AddMaskTexture(mask)
            ptex:AddMaskTexture(mask)
            pf.portraitMask = mask
        end
        pf:Hide()
        ov.portraitFrame = pf
    end

    -- Ocultar hijos extra del ToT nativo (buff/debuff slots vacíos)
    HideToTNativeExtras(tot)

    API.S.focusTot.overlay = ov
    HarfordUnitFrames._focusTotBarsOverlay = ov
    return ov
end

local function HideFocusTotBarsOverlay()
    local ov = API.S.focusTot.overlay
    if not ov then return end
    -- Resetear lastGUID para que la próxima llamada a RefreshFocusTargetOfTargetBars
    -- re-evalúe el portrait. Sin esto, si Hide se llama desde UpdateFocusTotBarsOverlay
    -- (tot:IsShown() transitoriamente false), el portrait jamás se re-muestra porque
    -- el GUID sigue igual y el branch de portrait-update queda skipped.
    API.S.focusTot.lastGUID = nil
    ov.healthFrame:Hide()
    ov.manaFrame:Hide()
    if ov.portraitFrame then ov.portraitFrame:Hide() end
    if ov.artFrame then ov.artFrame:Hide() end
    -- Portrait nativo permanentemente oculto via HookScript; no restaurar alpha.
end

local function UpdateFocusTotPortraitOverlay(profile)
    local ov = EnsureFocusTotBarsOverlay()
    if not ov or not ov.portraitFrame then return end
    local tot = _G["FocusFrameToT"]
    if not tot or not (tot.IsShown and tot:IsShown()) then
        ov.portraitFrame:Hide()
        return
    end
    -- Portrait nativo permanentemente oculto via HookScript; solo mostramos/ocultamos overlay.
    local isPlayer = UnitIsPlayer and UnitIsPlayer("focustarget")
    local cfgKey = isPlayer and "portrait_target_player" or "portrait_target_npc"
    local useTRP3 = not HarfordConfig or HarfordConfig.Get(cfgKey) ~= "wow"
    local icon = useTRP3 and profile and HarfordTRP3 and HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)
    if icon then
        ov.portraitFrame.icon:SetTexture(icon)
        ov.portraitFrame.icon:SetTexCoord(0, 1, 0, 1)
        ov.portraitFrame:Show()
    else
        ov.portraitFrame:Hide()
    end
    API._SyncToTNativePortraitAlpha(_G["FocusFrameToTPortrait"], ov.portraitFrame)
end

local function UpdateFocusTotBarsOverlay(healthData, resourceData)
    local ov = EnsureFocusTotBarsOverlay()
    if not ov then return end
    local tot = _G["FocusFrameToT"]
    if not (UnitExists and UnitExists("focustarget")) or not (tot and tot.IsShown and tot:IsShown()) then
        HideFocusTotBarsOverlay()
        return
    end
    UpdateToTArtOverlay(tot, ov)
    if healthData then
        local max = math.max(tonumber(healthData.max) or 0, 0)
        local cur = math.max(tonumber(healthData.cur) or 0, 0)
        local tempCur = math.max(tonumber(healthData.tempCur) or 0, 0)
        ov.healthFrame.bar:SetMinMaxValues(0, math.max(max, 1))
        ov.healthFrame.bar:SetValue(cur)
        ov.healthFrame.bar:SetStatusBarColor(0.0, 0.82, 0.08, 0.95)
        ov.healthFrame:Show()
        ApplyAbsorbTexture(EnsureNativeAbsorbTexture(ov.healthFrame.bar), ov.healthFrame.bar, cur, max, tempCur, 0.85)
    else
        ov.healthFrame:Hide()
    end
    ov.manaFrame:Show()
    if resourceData then
        local max = math.max(tonumber(resourceData.max) or 0, 0)
        local cur = math.max(tonumber(resourceData.cur) or 0, 0)
        local r, g, b = ResourceColor(resourceData.key)
        ov.manaFrame.bar:SetMinMaxValues(0, math.max(max, 1))
        ov.manaFrame.bar:SetValue(cur)
        ov.manaFrame.bar:SetStatusBarColor(r, g, b, 0.95)
    else
        ov.manaFrame.bar:SetValue(0)
    end
end

local function RefreshFocusTargetOfTargetBars(forceVisual)
    local unit = "focustarget"
    local tot = _G["FocusFrameToT"]
    if not (UnitExists and UnitExists(unit)) or not (tot and tot.IsShown and tot:IsShown()) then
        API.S.focusTot.lastGUID = nil
        HideFocusTotBarsOverlay()
        return
    end
    local frameMode = HarfordConfig and HarfordConfig.Get("resources") == "frame"
    if frameMode then
        API.S.focusTot.lastGUID = UnitGUID and UnitGUID(unit) or SafeUnitName(unit)
        local ov = API.S.focusTot.overlay
        if ov then
            ov.healthFrame:Hide()
            ov.manaFrame:Hide()
            if ov.artFrame then ov.artFrame:Hide() end
        end
        UpdateFocusTotPortraitOverlay(GetProfile(unit))
        return
    end
    local guid = UnitGUID and UnitGUID(unit) or SafeUnitName(unit)
    if forceVisual or guid ~= API.S.focusTot.lastGUID then
        API.S.focusTot.lastGUID = guid
        UpdateFocusTotPortraitOverlay(GetProfile(unit))
    end
    local list, resources, unitName = ApplyNativeResourceBars(unit, 2, false)
    UpdateFocusTotBarsOverlay(list and list[1], list and list[2])
    if unitName then
        RequestResourcesIfNeeded(unit, unitName, resources)
    end
end

local function EnsureFocusTargetOfTargetHooks()
    if API.S.focusTot.hooksInstalled then return end
    API.S.focusTot.hooksInstalled = true
    local tot = _G["FocusFrameToT"]
    if tot and not tot._harfordFocusToTHooked and tot.HookScript then
        tot._harfordFocusToTHooked = true
        tot:HookScript("OnShow", function()
            if RefreshFocusTargetOfTargetBars then RefreshFocusTargetOfTargetBars() end
        end)
        tot:HookScript("OnHide", function()
            API.S.focusTot.lastGUID = nil
            HideFocusTotBarsOverlay()
        end)
    end
    if hooksecurefunc then
        -- FocusofTarget_Update: análogo a TargetofTarget_Update para el focus frame
        if type(_G.FocusofTarget_Update) == "function" then
            hooksecurefunc("FocusofTarget_Update", function()
                if RefreshFocusTargetOfTargetBars then RefreshFocusTargetOfTargetBars() end
                local ov = API.S.focusTot.overlay
                API._SyncToTNativePortraitAlpha(_G["FocusFrameToTPortrait"], ov and ov.portraitFrame)
            end)
        end
    end
end

-- Exponer funciones públicas via tabla (accesibles desde fuera del do-block)
API.S.focusTot.hide       = HideFocusTotBarsOverlay
API.S.focusTot.refresh    = RefreshFocusTargetOfTargetBars
API.S.focusTot.ensureHooks = EnsureFocusTargetOfTargetHooks

end  -- do-block focus ToT
-- ────────────────────────────────────────────────────────────────────────────

local function ApplyLevelBackdrop(frame, layout)
    if not frame or not frame.levelBg or not layout or not layout.level then return end
    frame.levelBg:Hide()
end

local function EnsureNativePortraitMask(texture)
    if not texture or API.S.nativePortraitMasks[texture] then
        return API.S.nativePortraitMasks[texture]
    end
    if not texture.AddMaskTexture or not texture.GetParent then
        return nil
    end
    local parent = texture:GetParent()
    if not parent or not parent.CreateMaskTexture then
        return nil
    end

    local mask = parent:CreateMaskTexture(nil, "ARTWORK")
    mask:SetTexture(API.C.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    API.S.nativePortraitMasks[texture] = mask
    return mask
end

local function RefreshNativePortraitMask(texture)
    local mask = EnsureNativePortraitMask(texture)
    if mask then
        mask:ClearAllPoints()
        mask:SetAllPoints(texture)
    end
end

-- Deshace lo que Harford escribió en el frame nativo: texto de barras, retrato y nivel.
-- Llamar al entrar en frameMode o cuando la unidad deja de ser soportada.
local function ForceNativeUnitFrameRepaint(unit)
    if unit == "targettarget" then return end
    local pieces = NativePiecesForUnit(unit)
    local root = pieces and pieces.root
    if not root then return end

    if unit == "player" then
        if type(_G.PlayerFrame_Update) == "function" then
            pcall(_G.PlayerFrame_Update)
            pcall(_G.PlayerFrame_Update, root)
        end
    elseif type(_G.TargetFrame_Update) == "function" then
        pcall(_G.TargetFrame_Update, root)
    end

    if type(_G.UnitFrameHealthBar_Update) == "function" then
        pcall(_G.UnitFrameHealthBar_Update, root)
    end
    if type(_G.UnitFrameManaBar_Update) == "function" then
        pcall(_G.UnitFrameManaBar_Update, root)
    end
    if type(_G.TextStatusBar_UpdateTextString) == "function" then
        pcall(_G.TextStatusBar_UpdateTextString, pieces.health)
        pcall(_G.TextStatusBar_UpdateTextString, pieces.power)
    end
    RestoreNativeBarFromUnit(pieces.health, unit, "health", true)
    RestoreNativeBarFromUnit(pieces.power, unit, "power", true)
end

local function RestoreNativeFrameContents(unit)
    if unit == "targettarget" then HideToTBarsOverlay() end
    if unit == "focustarget" then API.S.focusTot.hide() end
    local pieces = NativePiecesForUnit(unit)

    local function ClearBarText(bar)
        if not bar then return end
        if bar.TextString then bar.TextString:SetText("") end
        if bar.LeftText  then bar.LeftText:Show() end
        if bar.RightText then bar.RightText:Show() end
        if bar.Text      then bar.Text:Show() end
    end
    ClearBarText(pieces.health)
    ClearBarText(pieces.power)
    if pieces.health then
        ClearHarfordNativeBarMarks(pieces.health)
        if pieces.health.Show then pieces.health:Show() end
        if pieces.health.SetAlpha then pieces.health:SetAlpha(1) end
    end
    if pieces.power then
        ClearHarfordNativeBarMarks(pieces.power)
        if pieces.power.Show then pieces.power:Show() end
        if pieces.power.SetAlpha then pieces.power:SetAlpha(1) end
    end

    if pieces.portrait and SetPortraitTexture then
        SetPortraitTexture(pieces.portrait, unit)
        if pieces.portrait.SetTexCoord then pieces.portrait:SetTexCoord(0, 1, 0, 1) end
        if pieces.portrait.SetAlpha then pieces.portrait:SetAlpha(1) end
        if pieces.portrait.Show then pieces.portrait:Show() end
    end

    if pieces.level and pieces.level.SetText then
        local lvl = UnitLevel and UnitLevel(unit)
        if lvl then pieces.level:SetText(lvl) end
        if pieces.level.SetTextColor then pieces.level:SetTextColor(1, 0.82, 0.1) end
        if pieces.level.SetAlpha then pieces.level:SetAlpha(1) end
        if pieces.level.Show then pieces.level:Show() end
    end

    if pieces.name and pieces.name.Show then
        pieces.name:Show()
    end
    ForceNativeUnitFrameRepaint(unit)
end

local function GetPortraitCfgKey(unit)
    if unit == "player" then return "portrait_player" end
    if UnitIsPlayer and UnitIsPlayer(unit) then return "portrait_target_player" end
    return "portrait_target_npc"
end

local function ApplyUnitVisuals(frame, unit, pieces, profile, unitName)
    local useTRP3 = not HarfordConfig or HarfordConfig.Get(GetPortraitCfgKey(unit)) ~= "wow"
    local icon = useTRP3 and profile and HarfordTRP3 and HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)
    if pieces.portrait then
        if icon and pieces.portrait.SetTexture then
            pieces.portrait:SetTexture(icon)
            if pieces.portrait.SetTexCoord then
                pieces.portrait:SetTexCoord(0, 1, 0, 1)
            end
        elseif SetPortraitTexture then
            SetPortraitTexture(pieces.portrait, unit)
            if pieces.portrait.SetTexCoord then
                pieces.portrait:SetTexCoord(0, 1, 0, 1)
            end
        end
        if pieces.portrait.SetDrawLayer then
            pieces.portrait:SetDrawLayer("ARTWORK", 0)
        end
        RefreshNativePortraitMask(pieces.portrait)
        if pieces.portrait.SetAlpha then pieces.portrait:SetAlpha(1) end
        if pieces.portrait.Show then pieces.portrait:Show() end
    end
    if frame.portrait then frame.portrait:Hide() end
    if frame.portraitBg then frame.portraitBg:Hide() end
    if frame.portraitLayer then frame.portraitLayer:Hide() end

    if pieces.level and pieces.level.SetText then
        -- Si el jugador está desconectado, ocultar el nivel para que Blizzard muestre
        -- su icono de estado nativo (calavera de desconexión) sin solapamiento.
        local isDisconnected = UnitIsConnected and UnitIsConnected(unit) == false
        if isDisconnected then
            if pieces.level.Hide then pieces.level:Hide() end
        else
            pieces.level:SetText(GetLevelText(unit, profile))
            if pieces.level.SetDrawLayer then
                pieces.level:SetDrawLayer("OVERLAY", 8)
            end
            if pieces.level.SetTextColor then
                pieces.level:SetTextColor(1, 0.82, 0.1)
            end
            if pieces.level.SetAlpha then pieces.level:SetAlpha(1) end
            if pieces.level.Show then pieces.level:Show() end
        end
    end
    if frame.level then frame.level:Hide() end

    if pieces.name and pieces.name.SetText then
        pieces.name:SetText(tostring(unitName or UnitName(unit) or ""))
    end
end

local function ApplyNativeUnitVisuals(unit, pieces, profile, unitName)
    pieces = pieces or NativePiecesForUnit(unit)
    if not pieces or not pieces.root then return end

    local useTRP3 = not HarfordConfig or HarfordConfig.Get(GetPortraitCfgKey(unit)) ~= "wow"
    local icon = useTRP3 and profile and HarfordTRP3 and HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)
    if pieces.portrait then
        if icon and pieces.portrait.SetTexture then
            pieces.portrait:SetTexture(icon)
            if pieces.portrait.SetTexCoord then
                pieces.portrait:SetTexCoord(0, 1, 0, 1)
            end
        elseif SetPortraitTexture then
            SetPortraitTexture(pieces.portrait, unit)
            if pieces.portrait.SetTexCoord then
                pieces.portrait:SetTexCoord(0, 1, 0, 1)
            end
        end
        if pieces.portrait.SetDrawLayer then
            pieces.portrait:SetDrawLayer("ARTWORK", 0)
        end
        RefreshNativePortraitMask(pieces.portrait)
        if pieces.portrait.SetAlpha then pieces.portrait:SetAlpha(1) end
        if pieces.portrait.Show then pieces.portrait:Show() end
    end

    if pieces.level and pieces.level.SetText then
        pieces.level:SetText(GetLevelText(unit, profile))
        if pieces.level.SetDrawLayer then
            pieces.level:SetDrawLayer("OVERLAY", 8)
        end
        if pieces.level.SetTextColor then
            pieces.level:SetTextColor(1, 0.82, 0.1)
        end
        if pieces.level.SetAlpha then pieces.level:SetAlpha(1) end
        if pieces.level.Show then pieces.level:Show() end
    end

    if pieces.name and pieces.name.SetText then
        pieces.name:SetText(tostring(unitName or UnitName(unit) or ""))
    end
end

local function ApplyNativePortraitOption(unit)
    if not (UnitExists and UnitExists(unit)) then return end
    local pieces = NativePiecesForUnit(unit)
    local portrait = pieces and pieces.portrait
    if not portrait then return end

    local profile = GetProfile(unit)
    local useTRP3 = not HarfordConfig or HarfordConfig.Get(GetPortraitCfgKey(unit)) ~= "wow"
    local icon = useTRP3 and profile and HarfordTRP3 and HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)

    if icon and portrait.SetTexture then
        portrait:SetTexture(icon)
        if portrait.SetTexCoord then portrait:SetTexCoord(0, 1, 0, 1) end
        if portrait.SetDrawLayer then portrait:SetDrawLayer("ARTWORK", 0) end
        RefreshNativePortraitMask(portrait)
    elseif SetPortraitTexture then
        SetPortraitTexture(portrait, unit)
        if portrait.SetTexCoord then portrait:SetTexCoord(0, 1, 0, 1) end
    end

    if portrait.SetAlpha then portrait:SetAlpha(1) end
    if portrait.Show then portrait:Show() end
end

-- NOTA (caso limite no resuelto): el retrato del PlayerFrame con icono TRP3 puede
-- revertir al modelo 3D al aplicar ciertas auras (p.ej. "llamas"+"asustado") a un NPC.
-- Se probó un hook defensivo sobre UnitFramePortrait_Update + SetPortraitTexture y
-- NO lo arregla (el repintado de Blizzard persiste). Revertido por no aportar y por el
-- coste del hook global. Se deja documentado en AGENTS.md para no reintentar lo mismo.
-- Diagnostico disponible: /harford debug run portraitwatch.

-- Cluster de barras de recurso: solo RefreshResourceBars es publica; los helpers de barra/slot
-- quedan block-local (do...end) para bajar el pico de locales file-scope.
local RefreshResourceBars
do
local function SetBarBox(bar, relativeTo, point, x, y, width, height)
    local container = bar.container or bar          -- borde exterior (para posición)
    local inner = bar.innerContainer or container   -- contenedor interior (para fill)
    container:ClearAllPoints()
    container:SetPoint(point or "TOPLEFT", relativeTo, point or "TOPLEFT", x or 0, y or 0)
    container:SetSize(math.max(1, width or API.C.DEFAULT_BAR_W), math.max(1, height or API.C.DEFAULT_BAR_H))
    bar:ClearAllPoints()
    bar:SetAllPoints(inner)   -- el StatusBar llena solo el interior (no el borde de 1px)
    if inner.textFrame then
        inner.textFrame:ClearAllPoints()
        inner.textFrame:SetAllPoints(inner)
    end
end

local function PlaceBar(frame, bar, index, lastBar)
    local layout = frame.layout or GetOrMeasureLayout(frame.unit)
    local health = layout.health
    local power = layout.power or {
        x = health.x,
        y = health.y + health.height + API.C.BAR_GAP,
        width = health.width,
        height = health.height,
    }
    local base = index == 1 and health or index == 2 and power or nil

    if base then
        local insetX = API.C.BAR_INSET_X
        local insetY = API.C.BAR_INSET_Y
        SetBarBox(bar, frame.visual, "TOPLEFT", base.x + insetX, -(base.y + insetY), base.width - insetX * 2, base.height - insetY * 2)
        return
    end

    local barW = math.max(1, (power.width or health.width) - API.C.BAR_INSET_X * 2)
    local barH = math.max(1, (power.height or health.height) - API.C.BAR_INSET_Y * 2)
    if lastBar then
        SetBarBox(bar, lastBar.container or lastBar, "TOPLEFT", 0, -(barH + API.C.BAR_GAP), barW, barH)
    else
        local startX = (power.x or health.x) + API.C.BAR_INSET_X
        local startY = (power.y or health.y) + (power.height or health.height) + API.C.BAR_GAP
        SetBarBox(bar, frame.visual, "TOPLEFT", startX, -startY, barW, barH)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Slot overlays para barras extra (índice 3+)
-- Cada barra extra recibe una textura hermana de frame.overlay que usa la franja
-- UV del slot de la power bar nativa. Esa franja tiene píxeles opacos en el borde
-- (el marco dorado de WoW) y transparentes en el interior (deja ver la barra).
-- El resultado es que cada barra extra aparece visualmente dentro del mismo marco.
-- ─────────────────────────────────────────────────────────────────────────────

local function GetOrCreateBarSlotOverlay(frame, slotIndex)
    if not frame.barSlotOverlays[slotIndex] then
        -- barSlotsFrame es hijo directo de visual (no de overlayFrame),
        -- así nunca queda oculto por el reset flow de RefreshUnitFrame.
        local host = frame.barSlotsFrame or frame.overlayFrame
        local ov = host:CreateTexture(nil, "OVERLAY", nil, 7)
        ov:Hide()
        frame.barSlotOverlays[slotIndex] = ov
    end
    return frame.barSlotOverlays[slotIndex]
end

local function HideAllBarSlotOverlays(frame)
    for _, ov in ipairs(frame.barSlotOverlays) do
        ov:Hide()
    end
end

local function ApplyBarSlotOverlays(frame, layout, list)
    HideAllBarSlotOverlays(frame)

    local extraCount = #list - 2
    if extraCount <= 0 then return end

    local tex    = layout and layout.texture
    local tc     = tex and tex.texCoord
    local health = layout and layout.health
    local power  = layout and (layout.power or layout.health)

    if not tc or #tc < 4 or not health or not power then return end

    local rel = tex and tex.rel
    if not rel or rel.height <= 0 then
        rel = {
            x = 0, y = 0,
            width  = (layout.root and layout.root.width)  or API.C.DEFAULT_FRAME_W,
            height = (layout.root and layout.root.height) or API.C.DEFAULT_FRAME_H,
        }
    end

    -- UV base (soporta 4 u 8 valores, y texturas espejadas donde tcL > tcR)
    local tcL, tcR, tcT, tcB
    if #tc == 4 then
        tcL, tcR, tcT, tcB = tc[1], tc[2], tc[3], tc[4]
    else
        tcL, tcR = tc[1], tc[5]
        tcT, tcB = tc[2], tc[4]
    end
    local hRange = tcR - tcL   -- puede ser negativo (frame espejado como player)
    local vRange = tcB - tcT

    -- UV HORIZONTAL: solo el slot de la barra (excluye area de retrato).
    -- Usamos power.x/power.width para el rango horizontal real de la barra.
    -- Esto evita los píxeles opacos del retrato que antes causaban el fondo amarillo.
    local barX    = (power.x or health.x) - rel.x
    local barW    = power.width or health.width
    local relW    = rel.width
    local ovTcL   = tcL + (barX          / relW) * hRange
    local ovTcR   = tcL + ((barX + barW) / relW) * hRange

    -- UV VERTICAL: slot de la power bar + expansion de borde.
    -- Los píxeles de borde (marco dorado) están en las filas FUERA del rango
    -- power.y … power.y+barH en la textura:
    --   · borde superior:  power.y - BPV   ..  power.y        (opaco, marco)
    --   · agujero:         power.y          ..  power.y+barH   (transparente)
    --   · borde inferior:  power.y+barH    ..  power.y+barH+BPV (opaco, marco)
    -- Sin expansión el overlay muestra solo el agujero → invisible sobre la barra.
    --
    -- BPV (border pixels vertical): cuántos píxeles de pantalla expandir arriba/abajo.
    -- Con BAR_GAP=2 y BPV=1, los overlays adyacentes se tocan sin solaparse.
    -- Subir BPV captura más borde pero puede solapar overlays si BPV > BAR_GAP/2.
    local BPV          = 1
    local barH         = power.height or health.height
    local relH         = rel.height
    local topY_tex     = (power.y or health.y) - rel.y
    local botY_tex     = topY_tex + barH

    local slotTopRel   = math.max(0, (topY_tex - BPV) / relH)
    local slotBotRel   = math.min(1, (botY_tex + BPV) / relH)
    local ovTcT        = tcT + slotTopRel * vRange
    local ovTcB        = tcT + slotBotRel * vRange

    -- UV HORIZONTAL: expansion asimetrica izquierda/derecha.
    -- El borde IZQUIERDO del slot de barra proviene de los píxeles del borde
    -- derecho del portrait ring. El borde DERECHO proviene de los elementos
    -- decorativos a la derecha de la barra. Para el player frame (textura espejada,
    -- hRange < 0) el cálculo UV invierte automáticamente via hRange, así que los
    -- mismos valores funcionan para ambos frames sin tratamiento especial.
    -- Capturar solo el pequeño remate/rombo del lado del portrait. Si se amplía
    -- igual que el lado exterior, se arrastran píxeles del aro del retrato.
    local BPH_PORTRAIT = 3
    local BPH_OUTER    = 5
    local isLeftPortrait = frame.unit == "player"
    local BPH_L        = isLeftPortrait and BPH_PORTRAIT or BPH_OUTER
    local BPH_R        = isLeftPortrait and BPH_OUTER or BPH_PORTRAIT
    local ovTcL_exp    = tcL + ((barX - BPH_L) / relW) * hRange
    local ovTcR_exp    = tcL + ((barX + barW + BPH_R) / relW) * hRange

    local col      = tex and tex.color
    local texPath  = (tex and tex.path) or API.C.TEX_FRAME
    local texAtlas = tex and tex.atlas

    -- Overlay con expansión por lado. El lado del portrait solo conserva el
    -- remate/rombo del slot; el lado exterior puede capturar más marco.
    -- Arriba/Abajo: BPV px para capturar borde vertical del slot.
    local ovW       = math.max(1, barW + BPH_L + BPH_R)
    local ovH       = math.max(1, barH + BPV * 2)
    local ovX       = (power.x or health.x) - BPH_L
    local barStep   = barH + API.C.BAR_GAP          -- paso entre barras (no usa ovH)
    local firstBarY = (power.y or health.y) + barH + API.C.BAR_GAP

    local host = frame.barSlotsFrame or frame.visual

    for slot = 1, extraCount do
        local ov = GetOrCreateBarSlotOverlay(frame, slot)

        if texAtlas and ov.SetAtlas then
            ov:SetAtlas(texAtlas)
        else
            ov:SetTexture(texPath)
        end
        ov:SetTexCoord(ovTcL_exp, ovTcR_exp, ovTcT, ovTcB)
        if col then
            ov:SetVertexColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        else
            ov:SetVertexColor(1, 1, 1, 1)
        end

        local barY = firstBarY + (slot - 1) * barStep
        local ovY  = barY - BPV   -- overlay empieza BPV px antes del top de la barra
        ov:ClearAllPoints()
        ov:SetPoint("TOPLEFT", host, "TOPLEFT", ovX, -ovY)
        ov:SetSize(ovW, ovH)
        ov:Show()
    end
end


function RefreshResourceBars(frame, resources)
    local list = BuildResourceList(resources)
    local layout = frame.layout or GetOrMeasureLayout(frame.unit)
    local pieces = NativePiecesForUnit(frame.unit)

    if #list > 0 then
        ApplyNativeStatusBar(pieces.health, list[1])
        if list[2] then
            ApplyNativeStatusBar(pieces.power, list[2])
        else
            ApplyPendingNativeStatusBar(pieces.power, "power")
        end
    else
        ApplyPendingNativeStatusBar(pieces.health, "health")
        ApplyPendingNativeStatusBar(pieces.power, "power")
    end
    HideNativeStatusBarText(pieces.health)
    HideNativeStatusBarText(pieces.power)

    frame.fallback:SetShown(false)
    frame.fallback:ClearAllPoints()
    frame.fallback:SetPoint("TOPLEFT", frame.visual, "TOPLEFT", layout.health.x + API.C.BAR_INSET_X, -(layout.health.y + API.C.BAR_INSET_Y))
    frame.fallback:SetSize(math.max(1, layout.health.width - API.C.BAR_INSET_X * 2), math.max(1, layout.health.height - API.C.BAR_INSET_Y * 2))
    frame.fallback:SetText("")

    local lastBar
    for i, data in ipairs(list) do
        local bar = i > 2 and EnsureBar(frame, i) or nil
        local max = math.max(tonumber(data.max) or 0, 0)
        local cur = math.max(tonumber(data.cur) or 0, 0)
        local r, g, b = ResourceColor(data.key)

        if i <= 2 then
            local nativeBar = i == 1 and pieces.health or pieces.power
            if nativeBar and nativeBar.TextString then
                local tempCur = math.max(tonumber(data.tempCur) or 0, 0)
                local shortText = FormatShortText(cur, max, tempCur)
                local fullText  = FormatFullText(tostring(data.label or data.key), cur, max, tempCur)
                nativeBar._harfordShortText = shortText
                nativeBar._harfordFullText  = fullText
                HookNativeBarForHover(nativeBar)
                local mode = GetStatusTextMode()
                local hovering = nativeBar.IsMouseOver and nativeBar:IsMouseOver()
                if hovering then
                    nativeBar.TextString:SetText(fullText)
                    nativeBar.TextString:Show()
                elseif mode ~= "NONE" and mode ~= "0" then
                    nativeBar.TextString:SetText(shortText)
                    nativeBar.TextString:Show()
                else
                    nativeBar.TextString:SetText(fullText)
                    nativeBar.TextString:Hide()
                end
            end
        else
            local shortText = FormatShortText(cur, max)
            local fullText  = FormatFullText(tostring(data.label or data.key), cur, max)
            bar._harfordShortText = shortText
            bar._harfordFullText  = fullText
            bar.ownerLayout = layout
            PlaceBar(frame, bar, i, lastBar)
            if bar.container and bar.container.bg then bar.container.bg:Show() end
            bar:SetAlpha(1)
            ApplyBarTextureInfo(bar, i)
            bar:SetMinMaxValues(0, max > 0 and max or 1)
            bar:SetValue(math.min(cur, max > 0 and max or cur))
            bar:SetStatusBarColor(r, g, b, 0.95)
            local mode = GetStatusTextMode()
            if mode ~= "NONE" and mode ~= "0" then
                bar.text:SetText(shortText)
                bar.text:Show()
            else
                bar.text:Hide()
            end
            if bar.container then bar.container:Show() end
            bar:Show()
            lastBar = bar
        end
    end

    for i = math.max(#list, 2) + 1, frame.maxBarIndex or 0 do
        if frame.bars[i] then
            if frame.bars[i].container then frame.bars[i].container:Hide() end
            frame.bars[i]:Hide()
        end
    end

    local height = layout.root.height
    local extraHeight = 0
    frame.resourceCount = #list
    if #list > 2 then
        local h = math.max(1, (layout.power and layout.power.height or layout.health.height) - API.C.BAR_INSET_Y * 2)
        extraHeight = ((#list - 2) * (h + API.C.BAR_GAP))
        height = height + extraHeight
    end
    frame:SetHeight(height)
    frame.extraResourceHeight = extraHeight
    ApplyBarSlotOverlays(frame, layout, list)
end
end  -- do (cluster RefreshResourceBars)


RefreshTargetOfTargetNative = function(forceVisual)
    local unit = "targettarget"
    local pieces = NativePiecesForUnit(unit)
    if not pieces or not pieces.root then return end
    EnsureTargetOfTargetHooks(pieces.root)

    local frameMode = HarfordConfig and HarfordConfig.Get("resources") == "frame"
    if not (UnitExists and UnitExists(unit)) then
        API.S.targetOfTargetLastGUID = nil
        RestoreNativeFrameContents(unit)
        return
    end
    if frameMode then
        API.S.targetOfTargetLastGUID = UnitGUID and UnitGUID(unit) or SafeUnitName(unit)
        HideToTResourceOverlays()
        UpdateToTPortraitOverlay(GetProfile(unit))
        return
    end

    local unitName = SafeUnitName(unit)
    local guid = UnitGUID and UnitGUID(unit) or unitName
    local profile = GetProfile(unit)
    if forceVisual or guid ~= API.S.targetOfTargetLastGUID then
        API.S.targetOfTargetLastGUID = guid
        ApplyNativeUnitVisuals(unit, pieces, profile, unitName)
        UpdateToTPortraitOverlay(profile)
    end
    local list, resources = ApplyNativeResourceBars(unit, 2, false)
    UpdateToTBarsOverlay(list and list[1], list and list[2])
    if unitName then
        RequestResourcesIfNeeded(unit, unitName, resources)
    end
end

RefreshTargetOfTargetBars = function(forceVisual)
    local unit = "targettarget"
    local tot = FindTargetOfTargetFrame()
    if not (UnitExists and UnitExists(unit)) or not (tot and tot.IsShown and tot:IsShown()) then
        API.S.targetOfTargetLastGUID = nil
        HideToTBarsOverlay()
        return
    end

    local frameMode = HarfordConfig and HarfordConfig.Get("resources") == "frame"
    if frameMode then
        API.S.targetOfTargetLastGUID = UnitGUID and UnitGUID(unit) or SafeUnitName(unit)
        HideToTResourceOverlays()
        UpdateToTPortraitOverlay(GetProfile(unit))
        return
    end

    local guid = UnitGUID and UnitGUID(unit) or SafeUnitName(unit)
    if forceVisual or guid ~= API.S.targetOfTargetLastGUID then
        API.S.targetOfTargetLastGUID = guid
        -- Actualizar portrait overlay al cambiar de unidad
        UpdateToTPortraitOverlay(GetProfile(unit))
    end
    local list, resources, unitName = ApplyNativeResourceBars(unit, 2, false)
    UpdateToTBarsOverlay(list and list[1], list and list[2])
    if unitName then
        RequestResourcesIfNeeded(unit, unitName, resources)
    end
end

local function RefreshFrame(key, unit, forceMeasure)
    local frame = CreateUnitFrame(key, unit)
    if not frame then return end
    if unit == "focus" and not NativeFrameForUnit("focus") then
        RestoreFocusAuras()
        frame:Hide()
        return
    end
    local supported = UnitIsSupportedPlayer(unit)
	local frameMode = HarfordConfig and HarfordConfig.Get("resources") == "frame"

	-- NPC target: no usar recursos Harford ni overlays de jugador.
	-- Venimos posiblemente de un target jugador, así que hay que limpiar inmediatamente
	-- las marcas Harford de las barras nativas y dejar que el TargetFrame muestre la vida real.
	if unit == "target" and UnitExists("target") and not UnitIsPlayer("target") then
		RestoreNativeUnitFrame("target")
		RestoreNativeFrameContents("target")
		RestoreTargetAuras()
		RestoreTargetOfTargetFrame()
		ApplyNativePortraitOption("target")
		HideToTBarsOverlay()

		if frame.portraitLayer then frame.portraitLayer:Hide() end
		if frame.overlayFrame then frame.overlayFrame:Hide() end
		if frame.portraitBg then frame.portraitBg:Hide() end
		if frame.portrait then frame.portrait:Hide() end
		if frame.level then frame.level:Hide() end
		if frame.levelBg then frame.levelBg:Hide() end
		if frame.nameBg then frame.nameBg:Hide() end
		if frame.name then frame.name:Hide() end
		if frame.fallback then frame.fallback:Hide() end
		if frame.nativeTexts then
			for _, textFrame in pairs(frame.nativeTexts) do
				textFrame:Hide()
			end
		end
		for i = 1, frame.maxBarIndex or 0 do
			local bar = frame.bars and frame.bars[i]
			if bar then
				if bar.container then bar.container:Hide() end
				bar:Hide()
			end
		end

		frame:Hide()

		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if UnitExists("target") and not UnitIsPlayer("target") then
					RestoreNativeUnitFrame("target")
					RestoreNativeFrameContents("target")
					ApplyNativePortraitOption("target")
					HideToTBarsOverlay()
				end
			end)
		end

		return
	end

	if not supported or frameMode then
        RestoreNativeUnitFrame(unit)
        RestoreNativeFrameContents(unit)
        if frameMode then
            RestoreNativeClassPowerWidgets()
        else
            HideNativeClassPowerWidgets()
        end
        if unit == "target" then
            RestoreTargetAuras()
            RestoreTargetOfTargetFrame()
            ApplyNativePortraitOption("target")
            RefreshTargetOfTargetBars()
        elseif unit == "focus" then
            RestoreFocusAuras()
            ApplyNativePortraitOption("focus")
            API.S.focusTot.refresh()
        elseif unit == "player" and frameMode then
            ApplyNativePortraitOption("player")
        end
        if frame.portraitLayer then frame.portraitLayer:Hide() end
        if frame.overlayFrame then frame.overlayFrame:Hide() end
        if frame.portraitBg then frame.portraitBg:Hide() end
        if frame.portrait then frame.portrait:Hide() end
        if frame.level then frame.level:Hide() end
        if frame.levelBg then frame.levelBg:Hide() end
        if frame.nameBg then frame.nameBg:Hide() end
        if frame.name then frame.name:Hide() end
        if frame.fallback then frame.fallback:Hide() end
        if frame.nativeTexts then
            for _, textFrame in pairs(frame.nativeTexts) do
                textFrame:Hide()
            end
        end
        for i = 1, frame.maxBarIndex or 0 do
            local bar = frame.bars and frame.bars[i]
            if bar then
                if bar.container then bar.container:Hide() end
                bar:Hide()
            end
        end
        frame:Hide()
        return
    end

    local layout = GetOrMeasureLayout(unit, forceMeasure)
    ApplyMeasuredLayout(frame, layout)
    KeepNativeUnitFrameVisible(unit)
    HideNativeClassPowerWidgets()
    if frame.portraitLayer then frame.portraitLayer:Hide() end
    if frame.overlayFrame then frame.overlayFrame:Hide() end
    if frame.portraitBg then frame.portraitBg:Hide() end
    if frame.portrait then frame.portrait:Hide() end
    if frame.level then frame.level:Hide() end
    if frame.nameBg then frame.nameBg:Hide() end
    if frame.name then frame.name:Hide() end

    local unitName = SafeUnitName(unit)
    local profile = GetProfile(unit)
    ApplyUnitVisuals(frame, unit, NativePiecesForUnit(unit), profile, unitName)
    ApplyLevelBackdrop(frame, layout)

    local resources = HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName and HarfordDnDAPI.GetResourcesForName(unitName or "")
    RefreshResourceBars(frame, resources)
    if unit == "target" then
        AdjustTargetAuras(frame, frame.resourceCount or 0, frame.extraResourceHeight or 0)
        AdjustTargetOfTargetFrame(frame, frame.resourceCount or 0, frame.extraResourceHeight or 0)
        RefreshTargetOfTargetBars()
    elseif unit == "focus" then
        AdjustUnitAuras(frame, frame.resourceCount or 0, frame.extraResourceHeight or 0)
        API.S.focusTot.ensureHooks()
        API.S.focusTot.refresh()
    end
    if unitName then RequestResourcesIfNeeded(unit, unitName, resources) end
    frame:Show()
end

local function GetCompactFrameUnit(frame)
    if not frame then return nil end
    if frame.unit then return frame.unit end
    if frame.displayedUnit then return frame.displayedUnit end
    if frame.GetAttribute then
        local unit = frame:GetAttribute("unit")
        if unit then return unit end
    end
    local name = frame.GetName and frame:GetName()
    if type(name) == "string" then
        local partyIndex = name:match("^PartyMemberFrame(%d+)$") or name:match("^CompactPartyFrameMember(%d+)$")
        if partyIndex then return "party" .. partyIndex end
        local raidIndex = name:match("^CompactRaidFrame(%d+)$")
        if raidIndex then return "raid" .. raidIndex end
    end
    return nil
end

local function GetGroupFrameName(frame)
    if not frame then return nil end
    if frame.GetName and frame:GetName() then return frame:GetName() end
    return tostring(frame)
end

local function FindGroupHealthBar(frame)
    if not frame then return nil end
    local name = frame.GetName and frame:GetName()
    return frame.healthBar
        or frame.HealthBar
        or frame.healthbar
        or frame.Health
        or HarfordUIGeom.FieldPath(frame, "unitFrame", "healthBar")
        or (name and _G[name .. "HealthBar"])
        or (name and _G[name .. "Health"])
end

local function FindGroupPowerBar(frame)
    if not frame then return nil end
    local name = frame.GetName and frame:GetName()
    return frame.powerBar
        or frame.PowerBar
        or frame.powerbar
        or frame.Power
        or frame.manaBar
        or HarfordUIGeom.FieldPath(frame, "unitFrame", "powerBar")
        or (name and _G[name .. "ManaBar"])
        or (name and _G[name .. "PowerBar"])
        or (name and _G[name .. "Power"])
end

local function FindGroupNameText(frame)
    if not frame then return nil end
    local name = frame.GetName and frame:GetName()
    return frame.name
        or frame.Name
        or frame.nameText
        or frame.NameText
        or frame.unitName
        or frame.UnitName
        or HarfordUIGeom.FieldPath(frame, "unitFrame", "name")
        or HarfordUIGeom.FieldPath(frame, "unitFrame", "nameText")
        or (name and _G[name .. "Name"])
        or (name and _G[name .. "NameText"])
end

local function CompactFrameHasVisiblePowerBar(frame)
    local powerBar = FindGroupPowerBar(frame)
    return powerBar and powerBar.IsShown and powerBar:IsShown()
end

local function FindGroupPortrait(frame)
    if not frame then return nil end
    local name = frame.GetName and frame:GetName()
    return frame.portrait
        or frame.Portrait
        or frame.icon
        or frame.Icon
        or HarfordUIGeom.FieldPath(frame, "unitFrame", "portrait")
        or (name and _G[name .. "Portrait"])
        or (name and _G[name .. "Icon"])
end

local function GroupFrameIsUsable(frame)
    local unit = GetCompactFrameUnit(frame)
    return unit and UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)
end

local function IsGroupUnit(unit)
    return type(unit) == "string" and (unit:match("^party%d+$") or unit:match("^raid%d+$"))
end

local function CacheGroupFrameUnit(frame, unit)
    if not frame or not unit then return end
    local previous = frame._harfordCachedGroupUnit
    if previous and previous ~= unit then
        local oldSet = API.S.groupFramesByUnit[previous]
        if oldSet then
            oldSet[frame] = nil
            if not next(oldSet) then API.S.groupFramesByUnit[previous] = nil end
        end
    end
    frame._harfordCachedGroupUnit = unit
    local set = API.S.groupFramesByUnit[unit]
    if not set then
        set = {}
        API.S.groupFramesByUnit[unit] = set
    end
    set[frame] = true
end

local function IsRaidUnit(unit)
    return type(unit) == "string" and unit:match("^raid%d+$") ~= nil
end

local function IsRaidCompactFrame(frame, unit)
    if IsRaidUnit(unit) then return true end
    local name = GetGroupFrameName(frame)
    return type(name) == "string" and name:match("^CompactRaidFrame%d+$") ~= nil
end

local function IsPartyCompactFrame(frame, unit)
    if type(unit) ~= "string" then return false end
    if IsRaidCompactFrame(frame, unit) then return false end
    return unit == "player" or unit:match("^party%d+$") ~= nil
end

-- Cluster de recoleccion de group frames: solo CollectAllGroupFrames es publica; el resto queda
-- block-local (do...end) para no consumir locales de file-scope (limite 200 Lua 5.1).
local CollectAllGroupFrames
do
local function CollectNamedGroupFrames(out)
    local names = {
        "CompactPartyFrameMember1", "CompactPartyFrameMember2", "CompactPartyFrameMember3", "CompactPartyFrameMember4", "CompactPartyFrameMember5",
        "PartyMemberFrame1", "PartyMemberFrame2", "PartyMemberFrame3", "PartyMemberFrame4",
    }
    for _, name in ipairs(names) do
        local frame = _G[name]
        if frame then out[frame] = true end
    end
    for i = 1, 40 do
        local frame = _G["CompactRaidFrame" .. i]
        if frame then out[frame] = true end
    end
end

local function CollectFrameFromTable(value, out, depth)
    if type(value) ~= "table" or (depth or 0) > 3 then return end
    if value.GetObjectType and GroupFrameIsUsable(value) then
        out[value] = true
        return
    end
    for _, child in pairs(value) do
        if type(child) == "table" then
            CollectFrameFromTable(child, out, (depth or 0) + 1)
        end
    end
end

local function CollectContainerChildren(container, out, depth)
    if not container or not container.GetChildren or (depth or 0) > 6 then return end
    if GroupFrameIsUsable(container) then
        out[container] = true
    end
    CollectFrameFromTable(container.memberUnitFrames, out, 0)
    CollectFrameFromTable(container.unitFrames, out, 0)
    CollectFrameFromTable(container.displayedUnitFrames, out, 0)
    for _, child in ipairs({ container:GetChildren() }) do
        if GroupFrameIsUsable(child) then
            out[child] = true
        end
        CollectContainerChildren(child, out, (depth or 0) + 1)
    end
end

local function CollectGroupFrames()
    local out = {}
    CollectNamedGroupFrames(out)
    CollectContainerChildren(_G.CompactPartyFrame, out)
    CollectContainerChildren(_G.CompactRaidFrameManager, out)
    CollectContainerChildren(_G.CompactRaidFrameContainer, out)
    CollectContainerChildren(_G.CompactRaidGroup1, out)
    CollectContainerChildren(_G.CompactRaidGroup2, out)
    CollectContainerChildren(_G.CompactRaidGroup3, out)
    CollectContainerChildren(_G.CompactRaidGroup4, out)
    CollectContainerChildren(_G.CompactRaidGroup5, out)
    CollectContainerChildren(_G.CompactRaidGroup6, out)
    CollectContainerChildren(_G.CompactRaidGroup7, out)
    CollectContainerChildren(_G.CompactRaidGroup8, out)
    return out
end

function CollectAllGroupFrames()
    local out = CollectGroupFrames()
    return out
end
end  -- do (cluster CollectAllGroupFrames)

function API.DebugGroupFrames()
    local rows = {}
    local profileUseClass = GetActiveRaidProfileOption("useClassColors")
    local profileDisplayClass = GetActiveRaidProfileOption("displayClassColor")
    local cvarClass = GetCVar and GetCVar("raidFramesDisplayClassColor") or nil
    rows[#rows + 1] = "cvars classColor=" .. tostring(cvarClass)
        .. " powerBars=" .. tostring(GetCVar and GetCVar("raidFramesDisplayPowerBars") or nil)
        .. " enabledClass=" .. tostring(IsCVarEnabled("raidFramesDisplayClassColor"))
        .. " enabledPower=" .. tostring(IsCVarEnabled("raidFramesDisplayPowerBars"))
        .. " profileUseClass=" .. tostring(profileUseClass)
        .. " profileDisplayClass=" .. tostring(profileDisplayClass)
    for frame in pairs(CollectAllGroupFrames()) do
        local unit = GetCompactFrameUnit(frame) or "nil"
        local shown = frame.IsShown and frame:IsShown() and "shown" or "hidden"
        local health = FindGroupHealthBar(frame)
        local power = FindGroupPowerBar(frame)
        local profile = unit ~= "nil" and GetProfile(unit) or nil
        local unitID = unit ~= "nil" and HarfordTRP3 and HarfordTRP3.BuildUnitID and HarfordTRP3.BuildUnitID(unit) or nil
        local className = profile and HarfordTRP3 and HarfordTRP3.GetProfilePrimaryClass and HarfordTRP3.GetProfilePrimaryClass(profile) or nil
        -- Cada asignacion multiple va en su propio `if`: en una cadena `and` solo sobrevive el
        -- primer valor devuelto, y este volcado reportaba nil en todo menos el primer campo.
        local cr, cg, cb, classKey
        if unit ~= "nil" then cr, cg, cb, classKey = LearnClassColor(unit, profile) end
        local unitClassKey
        if unit ~= "nil" and UnitClass then local _; _, unitClassKey = UnitClass(unit) end
        local br, bg, bb, ba
        if health and health.GetStatusBarColor then br, bg, bb, ba = health:GetStatusBarColor() end
        local hMin, hMax = nil, nil
        if health and health.GetMinMaxValues then
            hMin, hMax = health:GetMinMaxValues()
        end
        local hValue = health and health.GetValue and health:GetValue() or nil
        local hTex = health and health.GetStatusBarTexture and health:GetStatusBarTexture() or nil
        local tvr, tvg, tvb, tva
        if hTex and hTex.GetVertexColor then tvr, tvg, tvb, tva = hTex:GetVertexColor() end
        local useClassColors = frame.optionTable and frame.optionTable.useClassColors
        local displayClassColor = frame.optionTable and frame.optionTable.displayClassColor
        local exists = unit ~= "nil" and UnitExists and UnitExists(unit) and "exists" or "noexists"
        local isPlayer = unit ~= "nil" and UnitIsPlayer and UnitIsPlayer(unit) and "player" or "notplayer"
        rows[#rows + 1] = string.format(
            "%s unit=%s unitID=%s %s %s/%s useClassColors=%s displayClassColor=%s profileUseClass=%s profileDisplayClass=%s cvarClass=%s useClass=%s profile=%s class=%s key=%s wowClass=%s color=%s barColor=%s texColor=%s value=%s/%s-%s health=%s power=%s usable=%s",
            tostring(GetGroupFrameName(frame) or "unnamed"),
            tostring(unit),
            tostring(unitID),
            shown,
            exists,
            isPlayer,
            tostring(useClassColors),
            tostring(displayClassColor),
            tostring(profileUseClass),
            tostring(profileDisplayClass),
            tostring(cvarClass),
            tostring(ShouldUseCompactClassColor(frame)),
            tostring(profile ~= nil),
            tostring(className),
            tostring(classKey),
            tostring(unitClassKey),
            tostring(cr and string.format("%.2f,%.2f,%.2f", cr, cg, cb) or "nil"),
            tostring(br and string.format("%.2f,%.2f,%.2f,%.2f", br, bg, bb, ba or 1) or "nil"),
            tostring(tvr and string.format("%.2f,%.2f,%.2f,%.2f", tvr, tvg, tvb, tva or 1) or "nil"),
            tostring(hValue),
            tostring(hMin),
            tostring(hMax),
            tostring(health and (health.GetName and health:GetName() or "anon") or "nil"),
            tostring(power and (power.GetName and power:GetName() or "anon") or "nil"),
            tostring(GroupFrameIsUsable(frame))
        )
    end
    table.sort(rows)
    return rows
end

local function SetCompactBarHoverText(nativeBar, showFull)
    if not nativeBar then return end
    local text = nativeBar._harfordTextRegion or nativeBar.TextString
    if not text then return end
    if showFull and nativeBar._harfordFullText then
        text:SetText(nativeBar._harfordFullText)
        text:Show()
        return
    end

    local mode = GetStatusTextMode()
    if mode ~= "NONE" and mode ~= "0" and nativeBar._harfordShortText then
        text:SetText(nativeBar._harfordShortText)
        text:Show()
    else
        text:Hide()
    end
end

local RefreshGroupOverlayTexts

local function SetCompactFrameHoverState(frame, hovering)
    if not frame then return end
    frame._harfordHovering = hovering == true
    -- Party/group: el hover no actúa cuando el texto ya está visible (NUMERIC/PERCENT/BOTH)
    -- para evitar parpadeo sin beneficio real.
    -- Raid: el frame es pequeño y el hover siempre es útil aunque haya texto activo.
    local mode = GetStatusTextMode()
    local isRaid = IsRaidCompactFrame(frame, nil)
    if isRaid or mode == "NONE" or mode == "0" then
        SetCompactBarHoverText(FindGroupHealthBar(frame), frame._harfordHovering)
        SetCompactBarHoverText(FindGroupPowerBar(frame), frame._harfordHovering)
        if RefreshGroupOverlayTexts then
            RefreshGroupOverlayTexts(frame)
        end
    end
end

local function CompactHoverEnter(frame)
    if not frame then return end
    frame._harfordHoverToken = (frame._harfordHoverToken or 0) + 1
    -- CompactUnitFrame_OnEnter de Blizzard llama TextStatusBar_UpdateTextString
    -- en las barras nativas justo antes de que este hook corra, re-mostrando el
    -- TextString que HideNativeStatusBarText habia ocultado. Lo ocultamos de nuevo.
    HideNativeStatusBarText(FindGroupHealthBar(frame))
    HideNativeStatusBarText(FindGroupPowerBar(frame))
    SetCompactFrameHoverState(frame, true)
end

local function CompactHoverLeave(frame)
    if not frame then return end
    frame._harfordHoverToken = (frame._harfordHoverToken or 0) + 1
    local token = frame._harfordHoverToken
    local clear = function()
        if frame._harfordHoverToken == token then
            -- Mismo patron: OnLeave nativo puede restaurar texto; suprimirlo.
            HideNativeStatusBarText(FindGroupHealthBar(frame))
            HideNativeStatusBarText(FindGroupPowerBar(frame))
            SetCompactFrameHoverState(frame, false)
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.03, clear)
    else
        clear()
    end
end

local function HookCompactHoverTarget(target, compactFrame)
    if not target or target._harfordCompactHoverHooked or not target.HookScript then return end
    target._harfordCompactHoverHooked = true
    target:HookScript("OnEnter", function()
        CompactHoverEnter(compactFrame)
    end)
    target:HookScript("OnLeave", function()
        CompactHoverLeave(compactFrame)
    end)
end

local function HookCompactFrameForHover(frame)
    if not frame or frame._harfordCompactHoverHooked or not frame.HookScript then return end
    frame._harfordCompactHoverHooked = true
    frame:HookScript("OnEnter", CompactHoverEnter)
    frame:HookScript("OnLeave", CompactHoverLeave)
end

local function GetOrCreateGroupOverlay(frame)
    if not frame then return nil end
    local name = GetGroupFrameName(frame)
    if not name then return nil end
    local overlay = API.S.groupOverlays[name]
    if overlay then
        overlay.compactFrame = frame
        return overlay
    end
    if InCombatLockdown and InCombatLockdown() then
        return nil
    end

    overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints(frame)
    overlay:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 2)
    overlay:EnableMouse(false)
    -- Desacoplar alpha del padre: en Epsilon el compact frame puede recibir SetAlpha
    -- cuando el jugador esta lejos de phase, lo que haria semitransparente nuestro overlay
    -- y dejaria ver las barras nativas por debajo.
    if overlay.SetIgnoreParentAlpha then overlay:SetIgnoreParentAlpha(true) end
    overlay.compactFrame = frame
    overlay.bars = {}

    local function CreateOverlayBar()
        local container = CreateFrame("Frame", nil, overlay)
        container:EnableMouse(false)
        container:SetFrameLevel(overlay:GetFrameLevel() + 1)
        if container.SetIgnoreParentAlpha then container:SetIgnoreParentAlpha(true) end

        local bg = container:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(container)
        -- Alpha 1.0: opacidad total para tapar completamente la barra nativa subyacente.
        bg:SetColorTexture(0.02, 0.02, 0.02, 1.0)

        local bar = CreateFrame("StatusBar", nil, container)
        bar:SetAllPoints(container)
        bar:SetStatusBarTexture(API.C.TEX_STATUS)
        bar:SetFrameLevel(container:GetFrameLevel() + 1)
        if bar.SetIgnoreParentAlpha then bar:SetIgnoreParentAlpha(true) end

        -- Vida temporal: overlay nativo/cian encima del fill de HP.
        local tempBar = CreateFrame("StatusBar", nil, container)
        tempBar:SetAllPoints(bar)
        tempBar:SetStatusBarTexture(API.C.TEX_ABSORB_FILL)
        local tempTex = tempBar:GetStatusBarTexture()
        if tempTex and tempTex.SetHorizTile then tempTex:SetHorizTile(false) end
        if tempTex and tempTex.SetVertTile then tempTex:SetVertTile(false) end
        tempBar:SetStatusBarColor(0.30, 0.78, 1.00, 0.85)
        tempBar:SetFrameLevel(container:GetFrameLevel() + 2)
        if tempBar.SetIgnoreParentAlpha then tempBar:SetIgnoreParentAlpha(true) end
        tempBar:EnableMouse(false)
        tempBar:Hide()

        local textFrame = CreateFrame("Frame", nil, container)
        textFrame:SetAllPoints(container)
        textFrame:SetFrameLevel(container:GetFrameLevel() + 3)
        if textFrame.SetIgnoreParentAlpha then textFrame:SetIgnoreParentAlpha(true) end

        local text = textFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetAllPoints(textFrame)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetTextColor(1, 1, 1)

        container.bg      = bg
        container.bar     = bar
        container.tempBar = tempBar
        container.textFrame = textFrame
        container.text    = text
        return container
    end

    overlay.bars.health = CreateOverlayBar()
    overlay.bars.power = CreateOverlayBar()

    local nameFrame = CreateFrame("Frame", nil, overlay)
    nameFrame:EnableMouse(false)
    nameFrame:SetFrameLevel(overlay:GetFrameLevel() + 8)
    if nameFrame.SetIgnoreParentAlpha then nameFrame:SetIgnoreParentAlpha(true) end
    local nameText = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetAllPoints(nameFrame)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetTextColor(1, 0.82, 0.1)
    overlay.nameFrame = nameFrame
    overlay.nameText = nameText

    API.S.groupOverlays[name] = overlay
    return overlay
end

local function RefreshGroupOverlayName(overlay, frame, unit)
    if not overlay or not overlay.nameFrame or not overlay.nameText then return end
    local nativeName = FindGroupNameText(frame)
    overlay.nameFrame:ClearAllPoints()
    if nativeName and nativeName.GetObjectType and nativeName:GetObjectType() == "FontString" then
        overlay.nameFrame:SetPoint("TOPLEFT", nativeName, "TOPLEFT", 0, 0)
        overlay.nameFrame:SetPoint("BOTTOMRIGHT", nativeName, "BOTTOMRIGHT", 0, 0)
        if nativeName.GetTextColor then
            local r, g, b, a = nativeName:GetTextColor()
            overlay.nameText:SetTextColor(r or 1, g or 0.82, b or 0.1, a or 1)
        end
    else
        local healthBar = FindGroupHealthBar(frame)
        if healthBar then
            overlay.nameFrame:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
            overlay.nameFrame:SetPoint("RIGHT", healthBar, "RIGHT", 0, 0)
            overlay.nameFrame:SetHeight(math.max(10, (healthBar.GetHeight and (healthBar:GetHeight() or 20) or 20) * 0.45))
        else
            overlay.nameFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
            overlay.nameFrame:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
            overlay.nameFrame:SetHeight(12)
        end
    end
    if overlay.nameFrame.SetFrameLevel then
        overlay.nameFrame:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 30)
    end
    overlay.nameText:SetText(SafeUnitName(unit) or UnitName(unit) or "")
    overlay.nameFrame:Show()
end

local function SetGroupOverlayText(frame, container, data)
    if not container or not container.text or not data then return end
    local cur = math.max(tonumber(data.cur) or 0, 0)
    local max = math.max(tonumber(data.max) or 0, 0)
    local tempCur = math.max(tonumber(data.tempCur) or 0, 0)
    local shortText = FormatShortText(cur, max, tempCur)
    local fullText = FormatFullText(tostring(data.label or data.key), cur, max, tempCur)
    local mode = GetStatusTextMode()
    local unit = GetCompactFrameUnit(frame)
    local partyText = IsPartyCompactFrame(frame, unit)
    local isRaid    = IsRaidCompactFrame(frame, unit)
    if mode ~= "NONE" and mode ~= "0" then
        -- Con texto activo: raid muestra fullText al hacer hover; party siempre shortText.
        if isRaid and frame and frame._harfordHovering then
            container.text:SetText(fullText)
        else
            container.text:SetText(shortText)
        end
        container.text:Show()
    elseif frame and frame._harfordHovering then
        container.text:SetText(partyText and shortText or fullText)
        container.text:Show()
    else
        container.text:SetText(fullText)
        container.text:Hide()
    end
end

local function PositionGroupOverlayBar(container, nativeBar, frame, unit, isHealth)
    if not container or not nativeBar then
        if container then container:Hide() end
        return false
    end
    container:ClearAllPoints()
    container:SetPoint("TOPLEFT", nativeBar, "TOPLEFT", 0, 0)
    container:SetPoint("BOTTOMRIGHT", nativeBar, "BOTTOMRIGHT", 0, 0)
    if nativeBar.GetFrameLevel and container.SetFrameLevel then
        container:SetFrameLevel(nativeBar:GetFrameLevel() + 1)
        if container.bar and container.bar.SetFrameLevel then
            container.bar:SetFrameLevel(container:GetFrameLevel() + 1)
        end
        if container.tempBar and container.tempBar.SetFrameLevel then
            container.tempBar:SetFrameLevel(container:GetFrameLevel() + 2)
        end
        if container.textFrame and container.textFrame.SetFrameLevel then
            container.textFrame:SetFrameLevel(container:GetFrameLevel() + 3)
        end
    end
    container:Show()

    if container.textFrame and container.text then
        container.textFrame:ClearAllPoints()
        container.text:ClearAllPoints()
        if isHealth and frame and CompactFrameHasVisiblePowerBar(frame) then
            local yOffset = IsRaidUnit(unit) and -5 or 0
            container.textFrame:SetPoint("LEFT", container, "LEFT", 0, yOffset)
            container.textFrame:SetPoint("RIGHT", container, "RIGHT", 0, yOffset)
            container.textFrame:SetHeight(container:GetHeight() or 10)
        else
            container.textFrame:SetAllPoints(container)
        end
        container.text:SetAllPoints(container.textFrame)
    end
    return true
end

-- Dibuja el absorb de vida temporal en frames compactos (party/raid).
-- Usa texturas sobre container.textFrame (nivel alto) para quedar encima de la barra
-- de vida sin necesidad de modificar su z-order. El fill empieza donde termina el HP.
local function ApplyGroupOverlayBar(container, nativeBar, frame, unit, data, color, isHealth)
    if not PositionGroupOverlayBar(container, nativeBar, frame, unit, isHealth) or not data then
        if container then container:Hide() end
        return
    end
    local cur = math.max(tonumber(data.cur) or 0, 0)
    local max = math.max(tonumber(data.max) or 0, 0)
    local r, g, b = color and color[1], color and color[2], color and color[3]
    if not r then
        r, g, b = ResourceColor(data.key)
        if data.key == "health" then
            r, g, b = 0.0, 0.82, 0.08
        end
    end
    -- Replicar el estado visual del compact frame (lejos de phase, fuera de rango):
    -- Blizzard llama SetAlpha(~0.55) sobre el compact frame en esos estados.
    -- SetIgnoreParentAlpha(true) evita que las barras nativas sangren por debajo,
    -- pero debemos leer el alpha del frame y aplicarlo nosotros SOLO a la barra y
    -- el texto — el bg permanece opaco para tapar las barras nativas en cualquier estado.
    local stateAlpha = (frame and frame.GetAlpha and frame:GetAlpha()) or 1
    container.bar:SetStatusBarTexture(API.C.TEX_STATUS)
    container.bar:SetMinMaxValues(0, max > 0 and max or 1)
    container.bar:SetValue(math.min(cur, max > 0 and max or cur))
    container.bar:SetStatusBarColor(r, g, b, stateAlpha)
    if container.bar.SetAlpha then container.bar:SetAlpha(stateAlpha) end
    if container.textFrame and container.textFrame.SetAlpha then
        container.textFrame:SetAlpha(stateAlpha)
    end

    -- Vida temporal: solo health bar. El tempBar (nivel superior al bar) muestra el
    -- absorb como overlay encima de la barra de vida usando ApplyAbsorbTexture.
    if isHealth and container.tempBar then
        container.tempBar._harfordGroupAbsorb = IsRaidCompactFrame(frame, unit) == true
        local tempCur = math.max(tonumber(data.tempCur) or 0, 0)
        ApplyAbsorbTexture(container.tempBar, container.bar, cur, max, tempCur, 0.85 * stateAlpha)
    end

    SetGroupOverlayText(frame, container, data)
end

RefreshGroupOverlayTexts = function(frame)
    local overlay = API.S.groupOverlays[GetGroupFrameName(frame)]
    if not overlay or not overlay:IsShown() then return end
    if overlay.healthData then
        SetGroupOverlayText(frame, overlay.bars.health, overlay.healthData)
    end
    if overlay.powerData then
        SetGroupOverlayText(frame, overlay.bars.power, overlay.powerData)
    end
end

local function RestoreCompactNativeTexts(frame)
    if not frame then return end
    RestoreNativeStatusText(FindGroupHealthBar(frame))
    RestoreNativeStatusText(FindGroupPowerBar(frame))
end

local function RestoreGroupNativeBar(nativeBar)
    local state = nativeBar and API.S.compactBarState[nativeBar]
    if not state then return end
    local compactFrame = state.frame or nativeBar._harfordCompactFrame
    if nativeBar.SetStatusBarTexture and state.texture then
        nativeBar:SetStatusBarTexture(state.texture)
    end
    ClearHarfordNativeBarMarks(nativeBar)
    if nativeBar.TextString then
        if nativeBar.TextString.SetText then nativeBar.TextString:SetText("") end
        if nativeBar.TextString.Hide then nativeBar.TextString:Hide() end
    end
    if nativeBar._harfordTextRegion then
        nativeBar._harfordTextRegion:Hide()
    end
    API.S.compactBarState[nativeBar] = nil

    if compactFrame and _G.CompactUnitFrame_UpdateAll then
        pcall(_G.CompactUnitFrame_UpdateAll, compactFrame)
    end
    if compactFrame and _G.CompactUnitFrame_UpdateHealthColor then
        pcall(_G.CompactUnitFrame_UpdateHealthColor, compactFrame)
    end
end

local function SaveCompactPortraitState(portrait)
    if not portrait or API.S.compactPortraitState[portrait] then return end
    API.S.compactPortraitState[portrait] = {
        texture = portrait.GetTexture and portrait:GetTexture() or nil,
        atlas = portrait.GetAtlas and portrait:GetAtlas() or nil,
        texCoord = portrait.GetTexCoord and { portrait:GetTexCoord() } or nil,
        alpha = portrait.GetAlpha and portrait:GetAlpha() or nil,
        shown = portrait.IsShown and portrait:IsShown() or nil,
    }
end

local function RestoreCompactPortrait(portrait)
    local state = portrait and API.S.compactPortraitState[portrait]
    if not state then return end
    if state.atlas and portrait.SetAtlas then
        portrait:SetAtlas(state.atlas)
    elseif state.texture and portrait.SetTexture then
        portrait:SetTexture(state.texture)
    end
    if state.texCoord and portrait.SetTexCoord then
        portrait:SetTexCoord(unpack(state.texCoord))
    end
    if state.alpha and portrait.SetAlpha then
        portrait:SetAlpha(state.alpha)
    end
    if state.shown == true and portrait.Show then
        portrait:Show()
    elseif state.shown == false and portrait.Hide then
        portrait:Hide()
    end
    API.S.compactPortraitState[portrait] = nil
end

local function ShouldHandleCompactUnitFrame(frame)
    if API.S.restoringCompactFrames then return false end
    if HarfordConfig and HarfordConfig.Get("resources") == "frame" then return false end
    if not frame then return false end
    local unit = GetCompactFrameUnit(frame)
    if not unit or unit == "target" then return false end
    if unit ~= "player" and not IsGroupUnit(unit) then return false end
    return UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)
end

local function GetCompactFrameClassColor(frame)
    if not ShouldHandleCompactUnitFrame(frame) then return nil end
    if not ShouldUseCompactClassColor(frame) then return nil end
    local unit = GetCompactFrameUnit(frame)
    local profile = GetProfile(unit)
    return LearnClassColor(unit, profile)
end

local function ApplyCompactHealthClassColor(frame)
    if not ShouldHandleCompactUnitFrame(frame) then return end
    local overlay = API.S.groupOverlays[GetGroupFrameName(frame)]
    if overlay and overlay:IsShown() and overlay.healthData then
        local color = nil
        local r, g, b = GetCompactFrameClassColor(frame)
        if r then color = { r, g, b } end
        ApplyGroupOverlayBar(overlay.bars.health, FindGroupHealthBar(frame), frame, GetCompactFrameUnit(frame), overlay.healthData, color, true)
    end
end

local ApplyCompactStateAlpha

local function ApplyHarfordCompactUnitFrame(frame)
    if not ShouldHandleCompactUnitFrame(frame) then return end
    local unit = GetCompactFrameUnit(frame)
    CacheGroupFrameUnit(frame, unit)
    -- Desconectado o fuera de phase: ocultar overlay y dejar que el frame nativo muestre
    -- el icono de estado (calavera de desconexion, etc.).
    if UnitIsConnected and UnitIsConnected(unit) == false then
        local overlay = API.S.groupOverlays[GetGroupFrameName(frame)]
        if overlay then overlay:Hide() end
        local portrait = FindGroupPortrait(frame)
        if portrait then RestoreCompactPortrait(portrait) end
        return
    end
    API.S.compactFramesTouched[frame] = true
    HookCompactFrameForHover(frame)
    local unitName = SafeUnitName(unit)
    local profile = GetProfile(unit)
    local useTRP3Portrait = not HarfordConfig or HarfordConfig.Get("portrait_target_player") ~= "wow"
    local icon = useTRP3Portrait and profile and HarfordTRP3 and HarfordTRP3.GetProfileIcon and HarfordTRP3.GetProfileIcon(profile)
    local portrait = FindGroupPortrait(frame)
    if portrait then
        SaveCompactPortraitState(portrait)
        if icon and portrait.SetTexture then
            portrait:SetTexture(icon)
            if portrait.SetTexCoord then
                portrait:SetTexCoord(0, 1, 0, 1)
            end
        elseif SetPortraitTexture then
            SetPortraitTexture(portrait, unit)
            if portrait.SetTexCoord then
                portrait:SetTexCoord(0, 1, 0, 1)
            end
        end
        if portrait.SetAlpha then portrait:SetAlpha(1) end
        if portrait.Show then portrait:Show() end
        RefreshNativePortraitMask(portrait)
    end

    local resources = HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName and HarfordDnDAPI.GetResourcesForName(unitName or "")
    local list = BuildResourceList(resources)
    RequestGroupResourcesIfNeeded(unitName, resources)

    if #list == 0 then
        local overlay = API.S.groupOverlays[GetGroupFrameName(frame)]
        if overlay then
            overlay._harfordSignature = nil
            overlay:Hide()
        end
        return
    end

    -- Inyectar vida temporal en el slot de salud para que ApplyGroupOverlayBar la lea
    if list[1] and list[1].key == "health" and type(resources) == "table" then
        local tc = math.max(tonumber(resources["Res_temp_health_Cur"]) or 0, 0)
        if tc > 0 then list[1].tempCur = tc end
    end
    local classColor = nil
    if ShouldUseCompactClassColor(frame) then
        local r, g, b = LearnClassColor(unit, profile)
        if r then classColor = { r, g, b } end
    end
    local signature = BuildCompactOverlaySignature(unit, unitName, icon, list, classColor)
    local healthBar = FindGroupHealthBar(frame)
    local powerBar = FindGroupPowerBar(frame)
    -- Marcar las barras nativas para que el hook global de TextStatusBar las suprima
    -- en cada tick de CompactUnitFrame_OnUpdate mientras el raton este encima.
    if healthBar then healthBar._harfordCompactManaged = true end
    if powerBar  then powerBar._harfordCompactManaged  = true end
    local overlay = GetOrCreateGroupOverlay(frame)
    if overlay then
        if overlay._harfordSignature == signature and overlay:IsShown() then
            ApplyCompactStateAlpha(frame)
            HideNativeStatusBarText(healthBar)
            HideNativeStatusBarText(powerBar)
            HookCompactHoverTarget(healthBar, frame)
            HookCompactHoverTarget(powerBar, frame)
            return
        end
        overlay._harfordSignature = signature
        overlay.healthData = list[1]
        overlay.powerData = list[2]
        RefreshGroupOverlayName(overlay, frame, unit)
        ApplyGroupOverlayBar(overlay.bars.health, healthBar, frame, unit, list[1], classColor, true)
        ApplyGroupOverlayBar(overlay.bars.power, powerBar, frame, unit, list[2], nil, false)
        overlay:Show()
    end
    HideNativeStatusBarText(healthBar)
    HideNativeStatusBarText(powerBar)
    HookCompactHoverTarget(healthBar, frame)
    HookCompactHoverTarget(powerBar, frame)
end

local RefreshGroupOverlays

local function RefreshManagedGroupOverlays()
    if RefreshGroupOverlays then
        RefreshGroupOverlays()
    end
end

local function HookCompactUnitFrameFunction(name, handler)
    if API.S.compactUnitFrameHooksInstalled[name] or not hooksecurefunc or not _G[name] then return false end
    hooksecurefunc(name, handler or ApplyHarfordCompactUnitFrame)
    API.S.compactUnitFrameHooksInstalled[name] = true
    return true
end

-- Handler ligero para replicar el alpha de "lejos de fase" / fuera de rango.
-- CompactUnitFrame_UpdateInRange es llamada por el OnUpdate del compact frame
-- (~1/s) y es donde Blizzard aplica SetAlpha(~0.55). Hookearlo garantiza que
-- el stateAlpha de nuestras barras se actualiza en el mismo tick que el frame
-- nativo, sin esperar al siguiente evento de salud/poder.
ApplyCompactStateAlpha = function(frame)
    local overlay = frame and API.S.groupOverlays[GetGroupFrameName(frame)]
    if not overlay or not overlay:IsShown() then return end
    local stateAlpha = (frame.GetAlpha and frame:GetAlpha()) or 1
    for _, container in pairs(overlay.bars) do
        if container and container:IsShown() then
            if container.bar and container.bar.SetAlpha then
                container.bar:SetAlpha(stateAlpha)
                if container.bar.SetStatusBarColor then
                    -- preservar color existente, solo actualizar alpha
                    local r, g, b = container.bar:GetStatusBarColor()
                    container.bar:SetStatusBarColor(r, g, b, stateAlpha)
                end
            end
            if container.tempBar and container.tempBar:IsShown() then
                container.tempBar:SetAlpha(0.85 * stateAlpha)
                if container.tempBar.SetStatusBarColor then
                    container.tempBar:SetStatusBarColor(0.30, 0.78, 1.0, 0.85 * stateAlpha)
                end
            end
            if container.textFrame and container.textFrame.SetAlpha then
                container.textFrame:SetAlpha(stateAlpha)
            end
        end
    end
end

local function InstallCompactUnitFrameHooks()
    HookCompactUnitFrameFunction("CompactUnitFrame_UpdateAll")
    HookCompactUnitFrameFunction("CompactUnitFrame_UpdateHealth")
    HookCompactUnitFrameFunction("CompactUnitFrame_UpdateHealthColor", ApplyCompactHealthClassColor)
    HookCompactUnitFrameFunction("CompactUnitFrame_UpdatePower")
    -- CompactUnitFrame_UpdateStatus NO se hookea: en Epsilon puede dispararse para estados
    -- "lejos/fuera de fase" ademas de desconexion, causando que ApplyHarfordCompactUnitFrame
    -- se ejecute en frames intermedios y exponga barras nativas. La desconexion ya se cubre
    -- con UNIT_CONNECTION + CompactUnitFrame_UpdateAll.
    -- CompactUnitFrame_UpdateInRange: Blizzard la llama desde OnUpdate (~1/s) y aplica
    -- SetAlpha(~0.55) al frame cuando el jugador esta fuera de rango/fase. Hookeamos
    -- aqui para sincronizar el stateAlpha del overlay en el mismo tick.
    HookCompactUnitFrameFunction("CompactUnitFrame_UpdateInRange", ApplyCompactStateAlpha)

    -- TextStatusBar_UpdateTextString / WithValues: llamadas por CompactUnitFrame_OnUpdate
    -- cada tick mientras el raton esta encima del frame, re-mostrando el TextString nativo.
    -- Nuestro hook de OnEnter solo suprime una vez; el OnUpdate lo restaura cada frame.
    -- Interceptamos globalmente y suprimimos solo en barras marcadas como _harfordCompactManaged.
    if hooksecurefunc then
        local function SuppressCompactBarText(statusFrame)
            if statusFrame and statusFrame._harfordCompactManaged then
                HideNativeStatusBarText(statusFrame)
            end
        end
        if not API.S.compactUnitFrameHooksInstalled["TextStatusBar_UpdateTextString"] then
            if type(_G.TextStatusBar_UpdateTextString) == "function" then
                hooksecurefunc("TextStatusBar_UpdateTextString", SuppressCompactBarText)
                API.S.compactUnitFrameHooksInstalled["TextStatusBar_UpdateTextString"] = true
            end
        end
        if not API.S.compactUnitFrameHooksInstalled["TextStatusBar_UpdateTextStringWithValues"] then
            if type(_G.TextStatusBar_UpdateTextStringWithValues) == "function" then
                hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", SuppressCompactBarText)
                API.S.compactUnitFrameHooksInstalled["TextStatusBar_UpdateTextStringWithValues"] = true
            end
        end
    end

    HookCompactUnitFrameFunction("CompactUnitFrame_SetUnit")
    HookCompactUnitFrameFunction("CompactUnitFrame_SetUpFrame")
    HookCompactUnitFrameFunction("DefaultCompactUnitFrameSetup")
    HookCompactUnitFrameFunction("CompactUnitFrameProfiles_ApplyProfile", RefreshManagedGroupOverlays)
    HookCompactUnitFrameFunction("CompactUnitFrameProfiles_ApplyCurrentSettings", RefreshManagedGroupOverlays)
end

local function RefreshGroupFrameOverlay(frame)
    if not GroupFrameIsUsable(frame) then return end
    CacheGroupFrameUnit(frame, GetCompactFrameUnit(frame))
    local overlay = API.S.groupOverlays[GetGroupFrameName(frame)]
    if overlay then overlay:Hide() end
    ApplyHarfordCompactUnitFrame(frame)
end

local function RefreshGroupOverlayForUnit(unit)
    if not IsGroupUnit(unit) then return false end
    if HarfordConfig and HarfordConfig.Get("resources") == "frame" then return false end

    local refreshed = false
    local frames = API.S.groupFramesByUnit[unit]
    if frames then
        for frame in pairs(frames) do
            if GetCompactFrameUnit(frame) ~= unit then
                frames[frame] = nil
            elseif frame.IsShown and frame:IsShown() and GroupFrameIsUsable(frame) then
                RefreshGroupFrameOverlay(frame)
                refreshed = true
            end
        end
        if not next(frames) then API.S.groupFramesByUnit[unit] = nil end
    end

    if refreshed then return true end
    for frame in pairs(CollectAllGroupFrames()) do
        local frameUnit = GetCompactFrameUnit(frame)
        if frameUnit then CacheGroupFrameUnit(frame, frameUnit) end
        if frameUnit == unit and frame.IsShown and frame:IsShown() and GroupFrameIsUsable(frame) then
            RefreshGroupFrameOverlay(frame)
            refreshed = true
        end
    end
    return refreshed
end

local function UnitMatchesProfileName(unit, profileName)
    if not unit or not profileName or profileName == "" then return false end
    if not (UnitExists and UnitExists(unit)) then return false end
    local full = HarfordClassColors.UnitFullName(unit)
    local short = UnitName and UnitName(unit)
    local wantedShort = Ambiguate and Ambiguate(profileName, "short")
        or tostring(profileName):match("^[^%-]+") or profileName
    return full == profileName or short == profileName or short == wantedShort
end

local function RefreshResourceOverlaysForName(profileName)
    profileName = tostring(profileName or "")
    if profileName == "" then return false end
    local refreshed = false
    local primary = { player = "Player", target = "Target", focus = "Focus" }
    for unit, key in pairs(primary) do
        if UnitMatchesProfileName(unit, profileName) then
            RefreshFrame(key, unit, false)
            refreshed = true
        end
    end
    if IsInRaid and IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. tostring(i)
            if UnitMatchesProfileName(unit, profileName) then
                RefreshGroupOverlayForUnit(unit)
                refreshed = true
            end
        end
    else
        for i = 1, 4 do
            local unit = "party" .. tostring(i)
            if UnitMatchesProfileName(unit, profileName) then
                RefreshGroupOverlayForUnit(unit)
                refreshed = true
            end
        end
    end
    return refreshed
end

-- Cluster de repintado/restauracion de compact frames: solo HideGroupOverlays es publica;
-- los helpers quedan block-local (do...end) para bajar el pico de locales.
local HideGroupOverlays
do
local function RepaintNativeCompactFrames()
    if not _G.CompactUnitFrame_UpdateAll then return end
    API.S.restoringCompactFrames = true
    for frame in pairs(CollectAllGroupFrames()) do
        if frame and frame.IsShown and frame:IsShown() and GroupFrameIsUsable(frame) then
            pcall(_G.CompactUnitFrame_UpdateAll, frame)
        end
    end
    API.S.restoringCompactFrames = false
end

local function RestoreClassicPartyVisibility()
    if InCombatLockdown and InCombatLockdown() then return end
    local inRaid = IsInRaid and IsInRaid()
    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        local unit = "party" .. i
        if frame and frame.Hide and (inRaid or not (UnitExists and UnitExists(unit))) then
            pcall(frame.Hide, frame)
        end
    end
end

local function QueueCompactRestorePasses()
    if API.S.compactRestorePassesQueued then return end
    if not (C_Timer and C_Timer.After) then return end
    API.S.compactRestorePassesQueued = true
    C_Timer.After(0.05, RestoreClassicPartyVisibility)
    C_Timer.After(0.1, RepaintNativeCompactFrames)
    C_Timer.After(0.25, RestoreClassicPartyVisibility)
    C_Timer.After(0.5, function()
        RepaintNativeCompactFrames()
        API.S.compactRestorePassesQueued = false
    end)
end

function HideGroupOverlays()
    API.S.restoringCompactFrames = true
    for _, overlay in pairs(API.S.groupOverlays) do
        overlay:Hide()
        overlay.healthData = nil
        overlay.powerData = nil
        if overlay.nameFrame then overlay.nameFrame:Hide() end
        RestoreCompactNativeTexts(overlay.compactFrame)
    end
    for frame in pairs(CollectAllGroupFrames()) do
        local healthBar = FindGroupHealthBar(frame)
        local powerBar = FindGroupPowerBar(frame)
        local portrait = FindGroupPortrait(frame)
        RestoreCompactPortrait(portrait)
        RestoreCompactNativeTexts(frame)
        for _, nativeBar in pairs({ healthBar, powerBar }) do
            RestoreGroupNativeBar(nativeBar)
        end
    end
    for nativeBar in pairs(API.S.compactBarState) do
        RestoreGroupNativeBar(nativeBar)
    end
    for portrait in pairs(API.S.compactPortraitState) do
        RestoreCompactPortrait(portrait)
    end
    for frame in pairs(API.S.compactFramesTouched) do
        if frame and frame.IsShown and frame:IsShown() and GroupFrameIsUsable(frame) and _G.CompactUnitFrame_UpdateAll then
            pcall(_G.CompactUnitFrame_UpdateAll, frame)
            RestoreCompactNativeTexts(frame)
        end
        API.S.compactFramesTouched[frame] = nil
    end
    API.S.restoringCompactFrames = false
    RestoreClassicPartyVisibility()
    RepaintNativeCompactFrames()
    QueueCompactRestorePasses()
end
end  -- do (cluster HideGroupOverlays)

function RefreshGroupOverlays()
    if HarfordConfig and HarfordConfig.Get("resources") == "frame" then
        HideGroupOverlays()
        return
    end

    local active = {}
    for frame in pairs(CollectAllGroupFrames()) do
        if GroupFrameIsUsable(frame) and frame.IsShown and frame:IsShown() then
            CacheGroupFrameUnit(frame, GetCompactFrameUnit(frame))
            local name = GetGroupFrameName(frame)
            active[name] = true
            RefreshGroupFrameOverlay(frame)
        end
    end

    for name, overlay in pairs(API.S.groupOverlays) do
        if not active[name] then
            overlay:Hide()
        end
    end
end

local function QueueGroupOverlayRefresh(delay)
    if API.S.groupOverlayRefreshQueued then return end
    if not (C_Timer and C_Timer.After) then
        RefreshGroupOverlays()
        return
    end
    API.S.groupOverlayRefreshQueued = true
    C_Timer.After(tonumber(delay) or 0.25, function()
        API.S.groupOverlayRefreshQueued = false
        RefreshGroupOverlays()
    end)
end

function API.GetFrame(unit)
    return API.S.frames[unit]
end

function API.GetMeasuredLayout(unit, force)
    if unit ~= "target" and unit ~= "focus" then unit = "player" end
    return GetOrMeasureLayout(unit, force)
end

-- Reaplica el re-anclaje de auras DESPUES de que Blizzard recoloque buffs/debuffs.
-- Algunas versiones del cliente no pasan el frame como primer argumento, por lo que cada
-- hook conoce su unidad de respaldo en vez de depender de una firma concreta.
local function InstallAuraReanchorHooks()
    -- No instalar hooks hasta conocer el arbol de auras de este cliente. Un hook sobre
    -- nombres clasicos fue la causa de mezclar Buff1/Debuff1 entre target y focus.
end

function API.Attach()
    InstallCompactUnitFrameHooks()
    InstallNativePowerHooks()
    InstallAuraReanchorHooks()
    CreateUnitFrame("Player", "player")
    CreateUnitFrame("Target", "target")
    CreateUnitFrame("Focus", "focus")
    EnsureTargetOfTargetHooks(FindTargetOfTargetFrame())
end

function API.Refresh(forceMeasure)
    API.Attach()
    RefreshFrame("Player", "player", forceMeasure)
    RefreshFrame("Target", "target", forceMeasure)
    RefreshFrame("Focus", "focus", forceMeasure)
    RefreshGroupOverlays()
    if HarfordAdminUnitMenu and HarfordAdminUnitMenu.RefreshAnchors then
        HarfordAdminUnitMenu.RefreshAnchors()
    end
end

-- Re-aplica valores, colores y texto de las barras nativas (health/power) sin reconstruir el frame.
-- Se usa en UNIT_HEALTH / UNIT_POWER_UPDATE: Blizzard resetea fill/color en esos eventos.
ReapplyNativeBars = function(unit)
    if HarfordConfig and HarfordConfig.Get("resources") == "frame" then return end
    local frame = API.S.frames[unit]
    if not frame or not frame:IsShown() then return end
    local pieces = NativePiecesForUnit(unit)
    local unitName = SafeUnitName(unit)
    local resources = HarfordDnDAPI and HarfordDnDAPI.GetResourcesForName and HarfordDnDAPI.GetResourcesForName(unitName or "")
    local list = BuildResourceList(resources)

    -- Re-aplicar fill y color (Blizzard los sobreescribe en UNIT_HEALTH/UNIT_POWER_UPDATE)
    if #list > 0 then
        ApplyNativeStatusBar(pieces.health, list[1])
        if list[2] then
            ApplyNativeStatusBar(pieces.power, list[2])
        else
            ApplyPendingNativeStatusBar(pieces.power, "power")
        end
    else
        ApplyPendingNativeStatusBar(pieces.health, "health")
        ApplyPendingNativeStatusBar(pieces.power, "power")
    end

    HideNativeStatusBarText(pieces.health)
    HideNativeStatusBarText(pieces.power)

    -- Re-aplicar texto
    for i = 1, math.min(#list, 2) do
        local data = list[i]
        local cur = math.max(tonumber(data.cur) or 0, 0)
        local max = math.max(tonumber(data.max) or 0, 0)
        local tempCur = math.max(tonumber(data.tempCur) or 0, 0)
        local shortText = FormatShortText(cur, max, tempCur)
        local fullText  = FormatFullText(tostring(data.label or data.key), cur, max, tempCur)
        local nativeBar = i == 1 and pieces.health or pieces.power
        if nativeBar and nativeBar.TextString then
            nativeBar._harfordShortText = shortText
            nativeBar._harfordFullText  = fullText
            local mode = GetStatusTextMode()
            local hovering = nativeBar.IsMouseOver and nativeBar:IsMouseOver()
            if hovering then
                nativeBar.TextString:SetText(fullText)
                nativeBar.TextString:Show()
            elseif mode ~= "NONE" and mode ~= "0" then
                nativeBar.TextString:SetText(shortText)
                nativeBar.TextString:Show()
            else
                nativeBar.TextString:SetText(fullText)
                nativeBar.TextString:Hide()
            end
        end
    end
end

local EnsureTRP3Hooks

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UNIT_PORTRAIT_UPDATE")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("UNIT_HEALTH")
events:RegisterEvent("UNIT_POWER_UPDATE")
events:RegisterEvent("UNIT_TARGET")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("CVAR_UPDATE")
events:RegisterEvent("UNIT_CONNECTION")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if EnsureTRP3Hooks then EnsureTRP3Hooks() end
        InstallCompactUnitFrameHooks()
        return
    end

    if event == "UNIT_HEALTH" or event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "targettarget" then
            RefreshTargetOfTargetBars()
            return
        elseif unit == "focustarget" then
            API.S.focusTot.refresh()
            return
        elseif unit == "player" or unit == "target" or unit == "focus" then
            ReapplyNativeBars(unit)
        elseif IsGroupUnit(unit) then
            RefreshGroupOverlayForUnit(unit)
        end
        return
    end

    local forceMeasure = event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED"
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        InvalidateNativePiecesCache()  -- los frames nativos pueden recrearse tras reload/zona
        -- Los estados PROPIOS persistidos se restauran antes de que exista el PlayerFrame medible:
        -- primera pintada de la tira propia aqui, que es cuando ya se puede anclar.
        API.RefreshConditionStrip("player")
    end
    if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_NAME_UPDATE" or event == "UNIT_AURA" then
        local unit = ...
        if unit == "targettarget" then
            if event ~= "UNIT_AURA" then
                RefreshTargetOfTargetBars()
            end
            return
        elseif unit == "focustarget" then
            if event ~= "UNIT_AURA" then
                API.S.focusTot.refresh()
            end
            return
        end
        if event == "UNIT_AURA" and (unit == "target" or unit == "focus") then
            -- RestoreUnitAuras devuelve los aura frames a su posición nativa ANTES de
            -- limpiar el caché. Sin esto, SaveAuraPoints guarda la posición ya desplazada
            -- como base y cada UNIT_AURA acumula un desplazamiento extra hasta que los
            -- buff frames salen de pantalla ("congelados").
            RestoreUnitAuras(unit)
            QueueUnitAuraReanchor(unit)
            QueueNativeAuraCleanup(unit)
            -- Aura Manager actualiza FocusFrame usando la matriz global de TargetFrame
            -- y puede sobrescribir sus iconos. Reconciliamos el target real despues.
            if unit == "focus" then QueueNativeAuraCleanup("target") end
        end
        if unit ~= "player" and unit ~= "target" and unit ~= "focus" then
            if IsGroupUnit(unit) then
                RefreshGroupOverlayForUnit(unit)
            end
            return
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message = ...
        if prefix ~= API.C.ADDON_PREFIX then return end
        local opcode = strsplit and strsplit("|", tostring(message or "")) or ""
        if opcode ~= "DNDRES" and opcode ~= "DNDRESCFG" and opcode ~= "RADJ" then return end
        local resourceProfileName
        -- Solo datos de recursos: no refrescar nameplates por tiradas, inspeccion, clases o equipo.
        if HarfordNamePlates then
            if HarfordNamePlates.RefreshName and opcode == "DNDRES" and HarfordSync and HarfordSync.ReceiveResourceMessage then
                local _, profileName = HarfordSync.ReceiveResourceMessage(message)
                resourceProfileName = profileName
                if profileName then HarfordNamePlates.RefreshName(profileName) end
            elseif HarfordNamePlates.RefreshName and opcode == "DNDRESCFG" and HarfordSync and HarfordSync.ReceiveResourceConfig then
                local profileName = HarfordSync.ReceiveResourceConfig(message)
                resourceProfileName = profileName
                if profileName then HarfordNamePlates.RefreshName(profileName) end
            elseif HarfordNamePlates.RefreshName and opcode == "RADJ" then
                local playerName = HarfordClassColors.UnitFullName("player")
                resourceProfileName = playerName
                HarfordNamePlates.RefreshName(playerName)
            end
        end
        if not resourceProfileName and opcode == "RADJ" then
            resourceProfileName = HarfordClassColors.UnitFullName("player")
        elseif not resourceProfileName and opcode == "DNDRES" and HarfordSync and HarfordSync.ReceiveResourceMessage then
            local _, profileName = HarfordSync.ReceiveResourceMessage(message)
            resourceProfileName = profileName
        elseif not resourceProfileName and opcode == "DNDRESCFG" and HarfordSync and HarfordSync.ReceiveResourceConfig then
            resourceProfileName = HarfordSync.ReceiveResourceConfig(message)
        end
        if resourceProfileName then RefreshResourceOverlaysForName(resourceProfileName) end
        return
    elseif event == "PLAYER_TARGET_CHANGED" then
        forceMeasure = true
        QueueNativeAuraCleanup("target")
        API.RefreshConditionStrip("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        forceMeasure = true
        QueueNativeAuraCleanup("focus")
        QueueNativeAuraCleanup("target")
        API.RefreshConditionStrip("focus")
        API.RefreshConditionStrip("target")
    elseif event == "UNIT_TARGET" then
        local unit = ...
        if unit == "target" then
            RefreshTargetOfTargetBars()
        elseif unit == "focus" then
            API.S.focusTot.refresh()
        end
        return
    elseif event == "CVAR_UPDATE" then
        local cvarName = ...
        if cvarName ~= "statusTextDisplay" then return end
    elseif event == "GROUP_ROSTER_UPDATE" then
        wipe(API.S.groupResourceRequests)
        wipe(API.S.resourceRequests)
        RefreshGroupOverlays()
        QueueGroupOverlayRefresh(0.25)
        return
    elseif event == "UNIT_CONNECTION" then
        local unit = ...
        -- Conexion/desconexion de un miembro del grupo: refrescar overlays de raid
        if IsGroupUnit(unit) then
            RefreshGroupOverlayForUnit(unit)
        elseif unit == "player" or unit == "target" or unit == "focus" then
            -- Conexion/desconexion del target (jugador en otro grupo/mundo): forzar refresh
            API.Refresh(false)
        end
        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        if EnsureTRP3Hooks then EnsureTRP3Hooks() end
        InstallCompactUnitFrameHooks()
        -- Todos los addons ya han registrado sus hooks cuando llega PLAYER_LOGIN.
        -- Asi nuestra reconciliacion queda al final de TargetFrame_UpdateAuras.
        InstallNativeAuraUpdateHook()
        RefreshGroupOverlays()
    end

    API.Refresh(forceMeasure)
end)

-- En login TRP3 puede no tener listo el perfil propio cuando corre el refresh
-- inicial, asi que el icono del retrato del player no se aplica (aparecia al
-- cambiar de target). Nos enganchamos a los eventos de TRP3 para re-aplicar en
-- cuanto carga o cuando el perfil propio cambia. Guard de una sola instalacion;
-- si TRP3 aun no expone events, se volvera a intentar en los eventos reales
-- de carga/mundo, sin timers de reintento.
EnsureTRP3Hooks = function()
    if API.S._trp3Hooked then return end
    if not (TRP3_API and TRP3_API.events and TRP3_API.events.registerCallback) then return end
    API.S._trp3Hooked = true

    local playerId = TRP3_API.globals and TRP3_API.globals.player_id

    -- TRP3 termino su carga: el perfil propio ya esta disponible.
    pcall(TRP3_API.events.registerCallback, "WORKFLOW_ON_LOADED", function()
        API.Refresh(false)
    end)

    -- Datos de perfil actualizados. Solo refrescamos para el jugador local (o
    -- unitID nil) para no dispararnos con cada update de perfiles remotos (MSP).
    pcall(TRP3_API.events.registerCallback, "REGISTER_DATA_UPDATED", function(unitID)
        if (not unitID) or (playerId and unitID == playerId) then
            API.Refresh(false)
        end
    end)
end

-- Refresh inmediato al cambiar cualquier opción de HarfordConfig
if HarfordConfig and HarfordConfig.RegisterChangeListener then
    HarfordConfig.RegisterChangeListener(function()
        API.Refresh(false)
        if RefreshTargetOfTargetBars then RefreshTargetOfTargetBars(true) end
        if API.S.focusTot and API.S.focusTot.refresh then API.S.focusTot.refresh(true) end
        if HarfordNamePlates and HarfordNamePlates.RefreshAll then HarfordNamePlates.RefreshAll() end
    end)
end

-- Utilidades compartidas con HarfordNamePlates (cargado después en el TOC)
API.BuildResourceList = BuildResourceList
API.ResourceColor     = ResourceColor

-- Color de clase para nameplates: cache TRP3 → perfil TRP3 directo → clase WoW → nil.
-- HarfordNamePlates lo llama para colorear la barra de salud y la etiqueta de nombre.
API.GetClassColor = function(unit)
    local unitName = SafeUnitName(unit)
    -- 1. Cache poblado por interacciones previas de unitframes
    local r, g, b = GetCachedClassColorForName(unitName)
    if r then return r, g, b end
    -- 2. Perfil TRP3 directo (jugadores visibles en el nameplate pero no en unitframe todavía)
    if TRP3_API and TRP3_API.register and unitName then
        local realm = (GetRealmName and GetRealmName() or ""):gsub("%s+", "")
        local unitID = unitName .. "-" .. realm
        if TRP3_API.register.isUnitIDKnown and TRP3_API.register.isUnitIDKnown(unitID)
        and TRP3_API.register.getUnitIDCurrentProfile then
            local profile = TRP3_API.register.getUnitIDCurrentProfile(unitID)
            if profile then
                r, g, b = HarfordClassColors.ProfileColorRGB(profile)
                if r then CacheClassColorForName(unitName, r, g, b) ; return r, g, b end
            end
        end
    end
    -- 3. Clase WoW nativa (fallback para jugadores sin perfil TRP3)
    return HarfordClassColors.UnitColorRGB(unit)
end
