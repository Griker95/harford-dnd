-- HarfordCharacterPanel: panel de personaje unificado.
-- No sustituye el panel de reputaciones; lo usa como modulo externo desde una
-- pestana. La primera vista siempre es la ficha/resumen del PJ.

HarfordCharacterPanel = HarfordCharacterPanel or {}

local API = HarfordCharacterPanel
local S = {
    frame = nil,
    content = nil,
    portrait = nil,
    portraitMask = nil,
    title = nil,
    activeTab = "sheet",
    sheetView = "summary",
    tabs = {},
    pages = {},
    refreshers = {},
    selectedClassIndex = 1,
    classId = nil,
    subclassId = nil,
}

local TEX_PORTRAIT_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
-- Tamano/aspecto del CharacterFrame nativo (medido con FrameDump: Bg 536x401 + insets).
local NORMAL_W, NORMAL_H = 540, 424
local REPUTATION_W, REPUTATION_H = 390, 460
local BOTTOM_TAB_W, BOTTOM_TAB_H, BOTTOM_TAB_GAP = 85, 28, 4

local ABIL_KEYS = {
    { key = "Fuerza", short = "FUE" },
    { key = "Destreza", short = "DES" },
    { key = "Constitucion", short = "CON" },
    { key = "Inteligencia", short = "INT" },
    { key = "Sabiduria", short = "SAB" },
    { key = "Carisma", short = "CAR" },
}

local CLASS_INFO_ATLAS = {
    caballero_muerte = "UI-Character-Info-DeathKnight-BG",
    cazador_demonios = "UI-Character-Info-DemonHunter-BG",
    druida = "UI-Character-Info-Druid-BG",
    cazador = "UI-Character-Info-Hunter-BG",
    mago = "UI-Character-Info-Mage-BG",
    monje = "UI-Character-Info-Monk-BG",
    paladin = "UI-Character-Info-Paladin-BG",
    sacerdote = "UI-Character-Info-Priest-BG",
    picaro = "UI-Character-Info-Rogue-BG",
    chaman = "UI-Character-Info-Shaman-BG",
    brujo = "UI-Character-Info-Warlock-BG",
    guerrero = "UI-Character-Info-Warrior-BG",
}

local CLASS_FILE_TO_ATLAS = {
    DEATHKNIGHT = "UI-Character-Info-DeathKnight-BG",
    DEMONHUNTER = "UI-Character-Info-DemonHunter-BG",
    DRUID = "UI-Character-Info-Druid-BG",
    HUNTER = "UI-Character-Info-Hunter-BG",
    MAGE = "UI-Character-Info-Mage-BG",
    MONK = "UI-Character-Info-Monk-BG",
    PALADIN = "UI-Character-Info-Paladin-BG",
    PRIEST = "UI-Character-Info-Priest-BG",
    ROGUE = "UI-Character-Info-Rogue-BG",
    SHAMAN = "UI-Character-Info-Shaman-BG",
    WARLOCK = "UI-Character-Info-Warlock-BG",
    WARRIOR = "UI-Character-Info-Warrior-BG",
}

local CLASS_ID_TO_CLASS_FILE = {
    caballero_muerte = "DEATHKNIGHT",
    cazador_demonios = "DEMONHUNTER",
    druida = "DRUID",
    cazador = "HUNTER",
    mago = "MAGE",
    monje = "MONK",
    paladin = "PALADIN",
    sacerdote = "PRIEST",
    picaro = "ROGUE",
    chaman = "SHAMAN",
    brujo = "WARLOCK",
    guerrero = "WARRIOR",
}

local CLASS_PROFICIENCIES = {
    caballero_muerte = { armor = "Ligera, media, pesada, escudos", weapons = "Armas simples y marciales" },
    cazador_demonios = { armor = "Ligera", weapons = "Armas simples y marciales sin pesadas/dos manos como base narrativa" },
    druida = { armor = "Ligera, media, escudos", weapons = "Armas simples; armas druidicas segun mesa" },
    cazador = { armor = "Ligera, media, escudos", weapons = "Armas simples y marciales" },
    mago = { armor = "Ninguna", weapons = "Armas simples" },
    monje = { armor = "Ninguna", weapons = "Armas simples y armas de monje" },
    paladin = { armor = "Ligera, media, pesada, escudos", weapons = "Armas simples y marciales" },
    sacerdote = { armor = "Ligera", weapons = "Armas simples" },
    picaro = { armor = "Ligera", weapons = "Armas simples, pistolas/rifles si Forajido" },
    chaman = { armor = "Ligera, media, escudos", weapons = "Armas simples; marciales si Mejora" },
    brujo = { armor = "Ligera", weapons = "Armas simples" },
    guerrero = { armor = "Ligera, media, pesada, escudos", weapons = "Armas simples y marciales" },
}

local MODEL_BG_SOURCES = {
    { key = "tl" },
    { key = "tr" },
    { key = "bl" },
    { key = "br" },
}

local MODEL_BG_TEXCOORDS = {
    tl = { 0.171875, 1, 0.039215688, 1 },
    tr = { 0, 0.296875, 0.039215688, 1 },
    bl = { 0.171875, 1, 0, 1 },
    br = { 0, 0.296875, 0, 1 },
}

local MODEL_BG_RACE_TOKENS = {
    humano = "Human",
    enano = { default = "Dwarf", subraces = { hierro_negro = "DarkIronDwarf" } },
    elfo_noche = "NightElf",
    gnomo = { default = "Gnome", subraces = { mecagnomo = "Mechagnome" } },
    draenei = { default = "Draenei", subraces = { forjado_luz = "LightforgedDraenei" } },
    huargen = "Worgen",
    orco = "Orc",
    renegado = "Scourge",
    tauren = { default = "Tauren", subraces = { monte_alto = "HighmountainTauren" } },
    trol = { default = "Troll", subraces = { zandalari = "ZandalariTroll" } },
    elfo_sangre = "BloodElf",
    goblin = "Goblin",
    nocheterna = "Nightborne",
    pandaren = "Pandaren",
    elfo_vacio = "VoidElf",
    vulpera = "Vulpera",
}

local PAPERDOLL_SLOT_NAMES = {
    Head = "CharacterHeadSlot",
    Neck = "CharacterNeckSlot",
    Shoulder = "CharacterShoulderSlot",
    Back = "CharacterBackSlot",
    Chest = "CharacterChestSlot",
    Shirt = "CharacterShirtSlot",
    Tabard = "CharacterTabardSlot",
    Wrists = "CharacterWristSlot",
    Hands = "CharacterHandsSlot",
    Waist = "CharacterWaistSlot",
    Legs = "CharacterLegsSlot",
    Feet = "CharacterFeetSlot",
    Finger0 = "CharacterFinger0Slot",
    Finger1 = "CharacterFinger1Slot",
    Trinket0 = "CharacterTrinket0Slot",
    Trinket1 = "CharacterTrinket1Slot",
    MainHand = "CharacterMainHandSlot",
    SecondaryHand = "CharacterSecondaryHandSlot",
}

local PAPERDOLL_SLOT_TOKENS = {
    Head = "HeadSlot",
    Neck = "NeckSlot",
    Shoulder = "ShoulderSlot",
    Back = "BackSlot",
    Chest = "ChestSlot",
    Shirt = "ShirtSlot",
    Tabard = "TabardSlot",
    Wrists = "WristSlot",
    Hands = "HandsSlot",
    Waist = "WaistSlot",
    Legs = "LegsSlot",
    Feet = "FeetSlot",
    Finger0 = "Finger0Slot",
    Finger1 = "Finger1Slot",
    Trinket0 = "Trinket0Slot",
    Trinket1 = "Trinket1Slot",
    MainHand = "MainHandSlot",
    SecondaryHand = "SecondaryHandSlot",
}

local POINT_BUY_COST = {
    [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9,
}

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r " .. tostring(msg or ""))
    end
end

local function GetProfileName()
    local store = HarfordDnDPersistStore or {}
    return tostring(store.activeProfile or (UnitName and UnitName("player")) or "Personaje")
end

local function GetPortraitUnit()
    if S.activeTab == "reputation"
        and UnitExists and UnitExists("target")
        and UnitIsPlayer and UnitIsPlayer("target")
        and HarfordReputation and HarfordReputation.CanEdit and HarfordReputation.CanEdit()
    then
        return "target"
    end
    return "player"
end

local function GetPortraitMode(unit)
    if HarfordConfig and HarfordConfig.Get then
        if unit == "player" then
            return HarfordConfig.Get("portrait_player") or "trp3"
        end
        return HarfordConfig.Get("portrait_target_player") or "trp3"
    end
    return "trp3"
end

local function RefreshPortrait()
    if not (S.frame and S.portrait) then return end
    local unit = GetPortraitUnit()
    local mode = GetPortraitMode(unit)
    local icon
    if mode ~= "wow" and HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetProfileIcon then
        local profile = HarfordTRP3.GetPlayerProfile(unit)
        icon = profile and HarfordTRP3.GetProfileIcon(profile)
    end
    if icon and S.portrait.SetTexture then
        S.portrait:SetTexture(tonumber(icon) or icon)
        S.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    elseif SetPortraitTexture then
        SetPortraitTexture(S.portrait, unit)
        S.portrait:SetTexCoord(0, 1, 0, 1)
    end
    S.portrait:Show()
end

local function GetPanelTitle()
    if S.activeTab == "reputation" then
        return "Reputacion"
    end
    local name = HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("player")
    return name or GetProfileName()
end

local TAB_ORDER = { "sheet", "reputation", "creation", "leveling" }

local function PositionTabs()
    if not S.frame then return end
    -- Anclaje nativo: primera pestaña a BOTTOMLEFT(11,2), las siguientes solapadas a la
    -- derecha (-15) igual que CharacterFrameTab1/2/3.
    local prev
    for _, key in ipairs(TAB_ORDER) do
        local btn = S.tabs[key]
        if btn then
            btn:ClearAllPoints()
            if prev then
                btn:SetPoint("LEFT", prev, "RIGHT", -15, 0)
            else
                btn:SetPoint("TOPLEFT", S.frame, "BOTTOMLEFT", 11, 2)
            end
            prev = btn
        end
    end
end

local function ApplyFrameLayout()
    if not S.frame then return end
    local isRep = S.activeTab == "reputation"
    S.frame:SetSize(isRep and REPUTATION_W or NORMAL_W, isRep and REPUTATION_H or NORMAL_H)
    if S.content then
        S.content:ClearAllPoints()
        S.content:SetPoint("TOPLEFT", S.frame, "TOPLEFT", isRep and 18 or 14, isRep and -62 or -52)
        S.content:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", isRep and -18 or -14, isRep and 30 or 12)
    end
    if S.title then
        S.title:SetText(GetPanelTitle())
    elseif S.frame.TitleText then
        S.frame.TitleText:SetText(GetPanelTitle())
    end
    PositionTabs()
    RefreshPortrait()
end

local function GetProgression()
    if HarfordDnDProgression and HarfordDnDProgression.Get then
        return HarfordDnDProgression.Get(GetProfileName())
    end
    return nil
end

local function SeedProgressionFromTRP3()
    if HarfordDnDProgression and HarfordDnDProgression.SeedFromTRP3 then
        HarfordDnDProgression.SeedFromTRP3(GetProfileName())
    end
end

local function RefreshGameUI()
    if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Refresh then
        _G.DND5E_ARC_API.Refresh()
    end
    if HarfordUnitFrames and HarfordUnitFrames.Refresh then
        HarfordUnitFrames.Refresh()
    end
    if HarfordNamePlates and HarfordNamePlates.Refresh then
        HarfordNamePlates.Refresh()
    end
end

local function AbilityScore(key)
    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityScore then
        return HarfordDnDCalc.GetAbilityScore(key)
    end
    if HarfordDnDContext and HarfordDnDContext.Get then
        return tonumber(HarfordDnDContext.Get(key, 10)) or 10
    end
    return 10
end

local function AbilityBaseAndBonus(key)
    local base = 10
    if HarfordDnDContext and HarfordDnDContext.Get then
        base = tonumber(HarfordDnDContext.Get(key, 10)) or 10
    end
    local total = AbilityScore(key)
    return base, total - base
end

local function RawSigned(n)
    n = tonumber(n) or 0
    if n == 0 then return "0" end
    return (n >= 0 and "+" or "") .. tostring(n)
end

local function AbilityTooltipTitle(key)
    -- `bonus` es solo el bono/penalizacion LIVE (estado/objeto): los modificadores de
    -- raza/trasfondo ya estan horneados en la puntuacion de la ficha cargada y no se
    -- muestran aqui. Se colorea verde (positivo) / rojo (negativo).
    local base, bonus = AbilityBaseAndBonus(key)
    if bonus ~= 0 then
        local color = bonus > 0 and "ff40ff40" or "ffff4040"
        return key .. " (" .. tostring(base) .. "|c" .. color .. RawSigned(bonus) .. "|r)"
    end
    return key .. " (" .. tostring(base) .. ")"
end

local function AbilityMod(score)
    if HarfordDnDCalc and HarfordDnDCalc.AbilityMod then
        return HarfordDnDCalc.AbilityMod(score)
    end
    return math.floor(((tonumber(score) or 10) - 10) / 2)
end

local function Signed(n)
    n = tonumber(n) or 0
    if n == 0 then return "0" end
    return (n >= 0 and "+" or "") .. tostring(n)
end

local function ColorSigned(n)
    n = tonumber(n) or 0
    local color = n > 0 and "ff40ff40" or (n < 0 and "ffff4040" or "ffd0d0d0")
    return "|c" .. color .. Signed(n) .. "|r"
end

local function ColorSignedAligned(n)
    n = tonumber(n) or 0
    local color = n > 0 and "ff40ff40" or (n < 0 and "ffff4040" or "ffd0d0d0")
    local text = n == 0 and " 0" or Signed(n)
    return "|c" .. color .. text .. "|r"
end

-- Descripciones de caracteristicas: fuente unica en HarfordDnDData.ABIL[].desc.
local ABILITY_TOOLTIP_TEXT = {}
for _, a in ipairs((HarfordDnDData and HarfordDnDData.ABIL) or {}) do
    if a.key and a.desc then ABILITY_TOOLTIP_TEXT[a.key] = a.desc end
end

local function TooltipLines(owner, title, text, opts)
    if not (GameTooltip and owner and title) then return end
    opts = type(opts) == "table" and opts or nil
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if opts and opts.nativeAbility then
        GameTooltip:SetText(title, 1, 1, 1, true)
    else
        GameTooltip:SetText(title, 1, 0.82, 0, true)
    end
    if text and text ~= "" then
        if opts and opts.nativeAbility then
            GameTooltip:AddLine(text, 1, 0.82, 0, true)
        else
            GameTooltip:AddLine(text, 1, 1, 1, true)
        end
    end
    GameTooltip:Show()
end

local function CreateFS(parent, template, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    return fs
end

local function CreateButton(parent, text, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w or 100, h or 22)
    b:SetText(text or "")
    b:SetScript("OnClick", onClick)
    return b
end

-- Texturas exactas del CharacterFrameTab nativo (sacadas de /harforddebug probeframe).
local TAB_TEX_INACTIVE = "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab"
local TAB_TEX_ACTIVE   = "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"
local TAB_TEX_HILITE   = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-RealHighlight"

-- Pestana inferior replicando el CharacterFrameTab nativo: 3-slice inactivo (32px),
-- 3-slice activo (34px, ActiveTab) y highlight de hover (RealHighlight).
local function CreateNativeTab(parent, id, text, onClick)
    local b = CreateFrame("Button", "HarfordCharPanelTab" .. id, parent)
    b:SetHeight(32)

    -- Estado INACTIVO: regiones CharacterFrameTab*Left/Middle/Right.
    local il = b:CreateTexture(nil, "BACKGROUND"); il:SetTexture(TAB_TEX_INACTIVE); il:SetTexCoord(0, 0.15625, 0, 1); il:SetSize(20, 32); il:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -1)
    local im = b:CreateTexture(nil, "BACKGROUND"); im:SetTexture(TAB_TEX_INACTIVE); im:SetTexCoord(0.15625, 0.84375, 0, 1); im:SetHeight(32); im:SetPoint("LEFT", il, "RIGHT", 0, 0)
    local ir = b:CreateTexture(nil, "BACKGROUND"); ir:SetTexture(TAB_TEX_INACTIVE); ir:SetTexCoord(0.84375, 1, 0, 1); ir:SetSize(20, 32); ir:SetPoint("LEFT", im, "RIGHT", 0, 0)
    b.inactive = { il, im, ir }

    -- Estado ACTIVO/seleccionado: regiones *Disabled del CharacterFrameTab.
    local al = b:CreateTexture(nil, "BACKGROUND"); al:SetTexture(TAB_TEX_ACTIVE); al:SetTexCoord(0, 0.15625, 0, 0.546875); al:SetSize(20, 35); al:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    local am = b:CreateTexture(nil, "BACKGROUND"); am:SetTexture(TAB_TEX_ACTIVE); am:SetTexCoord(0.15625, 0.84375, 0, 0.546875); am:SetHeight(35); am:SetPoint("LEFT", al, "RIGHT", 0, 0)
    local ar = b:CreateTexture(nil, "BACKGROUND"); ar:SetTexture(TAB_TEX_ACTIVE); ar:SetTexCoord(0.84375, 1, 0, 0.546875); ar:SetSize(20, 35); ar:SetPoint("LEFT", am, "RIGHT", 0, 0)
    b.active = { al, am, ar }

    -- Hover nativo, pero solo para pestanas inactivas.
    local h = b:CreateTexture(nil, "OVERLAY")
    h:SetTexture(TAB_TEX_HILITE)
    h:SetPoint("TOPLEFT", b, "TOPLEFT", 3, 5)
    h:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 0)
    if h.SetBlendMode then h:SetBlendMode("ADD") end
    h:Hide()
    b.hover = h

    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("CENTER", 0, -3)
    t:SetText(text)
    b.label = t
    local tabWidth = math.max(64, math.floor((t:GetStringWidth() or 40) + 0.5) + 36)
    b:SetWidth(tabWidth)
    im:SetWidth(math.max(1, tabWidth - 40))
    am:SetWidth(math.max(1, tabWidth - 40))
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self)
        if not self.selected and self.hover then
            self.hover:Show()
            if self.label then self.label:SetTextColor(1, 1, 1) end
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self.hover then
            self.hover:Hide()
        end
        if self.label and not self.selected then
            self.label:SetTextColor(1, 0.82, 0)
        end
    end)

    function b:SetSelectedLook(sel)
        self.selected = sel and true or false
        for _, x in ipairs(self.active) do x:SetShown(sel) end
        for _, x in ipairs(self.inactive) do x:SetShown(not sel) end
        if self.hover then self.hover:Hide() end
        self.label:ClearAllPoints()
        self.label:SetPoint("CENTER", self, "CENTER", 0, sel and -3 or 2)
        if sel then
            -- CharacterFrameTab*Text nativo: pestaña seleccionada en blanco.
            self.label:SetTextColor(1, 1, 1)
        else
            -- Pestañas no seleccionadas: dorado Blizzard.
            self.label:SetTextColor(1, 0.82, 0)
        end
    end
    b:SetSelectedLook(false)
    return b
end

local function CreateEdit(parent, w, numeric)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(w or 60, 20)
    box:SetAutoFocus(false)
    box:SetNumeric(numeric and true or false)
    box:SetJustifyH("CENTER")
    return box
end

local function CreateDrop(parent, width)
    local drop = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(drop, width or 130)
    return drop
end

local function CreateCheck(parent, text, onClick)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c.text = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.text:SetPoint("LEFT", c, "RIGHT", -2, 0)
    c.text:SetText(text or "")
    c:SetScript("OnClick", function(self)
        if onClick then onClick(self, self:GetChecked()) end
    end)
    return c
end

local function SetDropText(drop, text)
    if drop then UIDropDownMenu_SetText(drop, text or "-") end
end

local function ClearDynamicRows(parent)
    parent._harfordRows = parent._harfordRows or {}
    for _, row in ipairs(parent._harfordRows) do row:Hide() end
    wipe(parent._harfordRows)
end

local function AddDynamicRow(parent, row)
    parent._harfordRows = parent._harfordRows or {}
    parent._harfordRows[#parent._harfordRows + 1] = row
    return row
end

local function MakeLine(parent, text, x, y, template)
    local fs = AddDynamicRow(parent, CreateFS(parent, template or "GameFontHighlightSmall", text))
    fs:SetPoint("TOPLEFT", x or 0, y or 0)
    fs:SetWidth(math.max(80, (parent:GetWidth() or 620) - (x or 0) - 10))
    fs:SetNonSpaceWrap(true)
    fs:Show()
    return fs
end

local function GetRaceLabel(data)
    local race = data and data.race or {}
    local raceName = HarfordDnDRaces and HarfordDnDRaces.GetRaceName and HarfordDnDRaces.GetRaceName(race.id)
    local sub = HarfordDnDRaces and HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(race.id, race.subraceId)
    if raceName and raceName ~= "" then
        return sub and (raceName .. " / " .. sub.name) or raceName
    end
    return "Sin raza"
end

local function GetBackgroundLabel(data)
    local id = data and data.background
    if id and id ~= "" and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgroundName then
        return HarfordDnDBackgrounds.GetBackgroundName(id)
    end
    return "Sin trasfondo"
end

local function GetFeatsLabel(data)
    local count = data and data.feats and #data.feats or 0
    return count > 0 and ("Dotes: " .. tostring(count)) or "Sin dotes"
end

local function GetTRP3FeatureRows(limit)
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetProfileFeatureLines) then
        return nil
    end
    local profile = HarfordTRP3.GetPlayerProfile("player")
    if not profile then return nil end
    local lines = HarfordTRP3.GetProfileFeatureLines(profile, limit or 5)
    if type(lines) ~= "table" or #lines == 0 then return nil end
    local rows = {}
    for _, line in ipairs(lines) do
        local text = tostring(line or "")
        rows[#rows + 1] = { text, "", text, text }
    end
    return rows
end

local function IsMagicLikeFeature(feature)
    local name = tostring(feature and feature.name or ""):lower()
    name = name:gsub("[áàäâ]", "a"):gsub("[éèëê]", "e"):gsub("[íìïî]", "i")
    name = name:gsub("[óòöô]", "o"):gsub("[úùüû]", "u"):gsub("ñ", "n")
    return name:find("conjuro", 1, true)
        or name:find("hechizo", 1, true)
        or name:find("truco", 1, true)
        or name:find("metamagia", 1, true)
        or name:find("fuente de magia", 1, true)
        or name:find("mana", 1, true)
end

local function GetClassFeatureRows(limit)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures) then
        return nil
    end
    local unlocked = HarfordDnDProgression.GetUnlockedFeatures(GetProfileName())
    if type(unlocked) ~= "table" then return nil end
    local rows = {}
    limit = tonumber(limit) or 5
    for _, item in ipairs(unlocked) do
        local feature = item and item.feature
        if item.classId and feature and feature.name and not IsMagicLikeFeature(feature) then
            rows[#rows + 1] = {
                tostring(feature.name),
                "",
                tostring(feature.name),
                tostring(feature.description or item.className or ""),
            }
            if #rows >= limit then break end
        end
    end
    return #rows > 0 and rows or nil
end

local GetClassFileForEntry, GetClassColorParts

local function GetClassSummary(data, separator)
    if not (data and data.classLevels and HarfordDnDBook) then return "Sin clase" end
    local parts = {}
    separator = separator or "  "
    for _, entry in ipairs(data.classLevels) do
        local className = HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId) or entry.classId
        local subName = HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(entry.classId, entry.subclassId) or ""
        local label = className
        if subName ~= "" then label = label .. " " .. subName end
        label = label .. " (" .. tostring(entry.level or 1) .. ")"
        local _, _, _, hex = GetClassColorParts(entry, className, label)
        if hex then
            label = "|cff" .. hex .. label .. "|r"
        end
        parts[#parts + 1] = label
    end
    return #parts > 0 and table.concat(parts, separator) or "Sin clase"
end

local function GetClassParts(data)
    if not (data and data.classLevels and HarfordDnDBook) then return nil end
    local parts = {}
    for _, entry in ipairs(data.classLevels) do
        local className = HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId) or entry.classId
        local subName = HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(entry.classId, entry.subclassId) or ""
        local label = tostring(className or "")
        if subName ~= "" then label = label .. " " .. subName end
        label = label .. " (" .. tostring(entry.level or 1) .. ")"

        local r, g, b = GetClassColorParts(entry, className, label)
        parts[#parts + 1] = { text = label, r = r, g = g, b = b }
    end
    return #parts > 0 and parts or nil
end

local function SetColoredTextList(parent, owner, key, parts, opts)
    if not owner then return end
    opts = type(opts) == "table" and opts or {}
    owner[key] = owner[key] or {}
    parts = parts or {}
    local texts = owner[key]
    for i = 1, #parts do
        if not texts[i] then
            texts[i] = CreateFS(parent, opts.font or "GameFontHighlightSmall", "")
        end
        local fs = texts[i]
        local text = parts[i].text or ""
        fs:SetText(text)
        fs:SetTextColor(parts[i].r or 1, parts[i].g or 1, parts[i].b or 1)
        fs:ClearAllPoints()
        fs:Show()
    end
    for i = #parts + 1, #texts do
        texts[i]:Hide()
    end
end

local function RefreshSubtitleClasses(SH, data)
    if not SH then return end
    local parts = GetClassParts(data)
    if not parts then
        if SH.subtitle then
            SH.subtitle:SetText("Sin clase")
            SH.subtitle:SetTextColor(1, 0.82, 0)
            SH.subtitle:Show()
        end
        return
    end

    if SH.subtitle then SH.subtitle:Hide() end
    SetColoredTextList(SH.page or S.frame, SH, "subtitleClassTexts", parts, { font = "GameFontNormal" })

    local gap = 10
    local maxWidth = 320
    local total = 0
    for i, fs in ipairs(SH.subtitleClassTexts or {}) do
        if i <= #parts then
            fs:SetWidth(1000)
            if fs.SetWordWrap then fs:SetWordWrap(false) end
            total = total + (fs:GetStringWidth() or 0)
            if i > 1 then total = total + gap end
        end
    end

    if total <= maxWidth then
        local x = -total / 2
        for i, fs in ipairs(SH.subtitleClassTexts or {}) do
            if i <= #parts then
                local w = fs:GetStringWidth() or 0
                fs:SetWidth(w)
                fs:SetPoint("TOPLEFT", SH.page or S.frame, "TOP", x, -36)
                x = x + w + gap
            end
        end
    else
        local yOffset = 0
        for i, fs in ipairs(SH.subtitleClassTexts or {}) do
            if i <= #parts then
                fs:SetWidth(maxWidth)
                fs:SetJustifyH("CENTER")
                if fs.SetWordWrap then fs:SetWordWrap(true) end
                if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
                fs:SetPoint("TOP", SH.page or S.frame, "TOP", 0, -34 - yOffset)
                local h = 14
                if fs.GetStringHeight then
                    h = math.max(h, math.ceil(fs:GetStringHeight() or h))
                end
                yOffset = yOffset + h
            end
        end
    end
end

local function GetCompetencyRows(data)
    local armorSet, weaponSet = {}, {}
    local armorOrder, weaponOrder = {}, {}
    local function addWords(targetSet, targetOrder, text)
        text = tostring(text or "")
        if text == "" then return end
        local lowered = text:lower()
        if targetSet == weaponSet then
            if lowered:find("simple", 1, true) and not targetSet["Armas simples"] then
                targetSet["Armas simples"] = true
                targetOrder[#targetOrder + 1] = "Armas simples"
            end
            if lowered:find("marcial", 1, true) and not targetSet["Armas marciales"] then
                targetSet["Armas marciales"] = true
                targetOrder[#targetOrder + 1] = "Armas marciales"
            end
            return
        end
        for part in text:gmatch("[^,;]+") do
            part = part:gsub("^%s+", ""):gsub("%s+$", "")
            if part ~= "" and not targetSet[part] then
                targetSet[part] = true
                targetOrder[#targetOrder + 1] = part
            end
        end
    end
    if data and data.classLevels then
        for _, entry in ipairs(data.classLevels) do
            local prof = entry.classId and CLASS_PROFICIENCIES[entry.classId]
            if prof then
                addWords(armorSet, armorOrder, prof.armor)
                addWords(weaponSet, weaponOrder, prof.weapons)
            end
        end
    end
    local armor = #armorOrder > 0 and table.concat(armorOrder, ", ") or "-"
    local weapons = #weaponOrder > 0 and table.concat(weaponOrder, ", ") or "-"
    return {
        { "Armadura", armor, "Competencias de armadura", "Se calcula como union de las competencias base de tus clases Harford. No modifica la CA por si sola." },
        { "Armas", weapons, "Competencias de armas", "Se calcula como union de las competencias base de tus clases Harford. Los rasgos concretos de subclase se consultan en Subida." },
        { "Armas sencillas", weaponSet["Armas simples"] and "Si" or "-", "Armas sencillas", "Competencia para armas simples/sencillas segun tus clases." },
        { "Armas marciales", weaponSet["Armas marciales"] and "Si" or "-", "Armas marciales", "Competencia para armas marciales. Algunos rasgos pueden conceder excepciones adicionales." },
    }
end

local function RefreshPanel()
    if not S.frame or not S.frame:IsShown() then return end
    SeedProgressionFromTRP3()
    ApplyFrameLayout()
    local isReputation = S.activeTab == "reputation"
    if isReputation then
        if S.content then S.content:Hide() end
        if HarfordReputationUI and HarfordReputationUI.EmbedInto then
            HarfordReputationUI.EmbedInto(S.frame)
        end
    else
        if HarfordReputationUI and HarfordReputationUI.DetachEmbedded then
            HarfordReputationUI.DetachEmbedded(true)
        end
        if S.content then S.content:Show() end
    end
    for key, page in pairs(S.pages) do
        page:SetShown((not isReputation) and key == S.activeTab)
    end
    -- Estado de las pestañas inferiores (3-slice nativo): activa = ActiveTab + texto amarillo.
    for key, button in pairs(S.tabs) do
        if button.SetSelectedLook then button:SetSelectedLook(key == S.activeTab) end
    end
    if S.refreshers[S.activeTab] then
        S.refreshers[S.activeTab]()
    end
end

local function CreatePage(key)
    local parent = S.content or S.frame
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    S.pages[key] = page
    return page
end

local function GetPrimaryClassId(data)
    local bestId, bestLevel
    if not (data and data.classLevels) then return nil end
    for _, entry in ipairs(data.classLevels) do
        local level = tonumber(entry.level) or 0
        if entry.classId and (not bestLevel or level > bestLevel) then
            bestId, bestLevel = entry.classId, level
        end
    end
    return bestId
end

local function GetClassInfoAtlas(data)
    local harfordAtlas = CLASS_INFO_ATLAS[GetPrimaryClassId(data)]
    if harfordAtlas then return harfordAtlas end
    if UnitClass then
        local _, classFile = UnitClass("player")
        local nativeAtlas = classFile and CLASS_FILE_TO_ATLAS[classFile]
        if nativeAtlas then return nativeAtlas end
    end
    return "UI-Character-Info-Warrior-BG"
end

GetClassFileForEntry = function(entry, className, label)
    if not HarfordClassColors then return nil end
    local rawId = tostring(entry and entry.classId or "")
    return CLASS_ID_TO_CLASS_FILE[rawId]
        or (HarfordClassColors.ClassFileFromText and HarfordClassColors.ClassFileFromText(rawId))
        or (HarfordClassColors.ClassFileFromText and HarfordClassColors.ClassFileFromText(className))
        or (HarfordClassColors.ClassFileFromText and HarfordClassColors.ClassFileFromText(label))
end

GetClassColorParts = function(entry, className, label)
    local r, g, b = 1, 0.82, 0
    local hex
    if HarfordClassColors then
        local classFile = GetClassFileForEntry(entry, className, label)
        local cr, cg, cb
        if HarfordClassColors.ColorRGBForClassFile then
            cr, cg, cb = HarfordClassColors.ColorRGBForClassFile(classFile)
        end
        if cr and cg and cb then
            r, g, b = cr, cg, cb
            if HarfordClassColors.RGBToHex then
                hex = HarfordClassColors.RGBToHex(r, g, b)
            end
        end
    end
    return r, g, b, hex
end

local function ApplyAtlasOrTexture(texture, atlas, fallback)
    if not texture then return false end
    if atlas and texture.SetAtlas then
        local ok = pcall(texture.SetAtlas, texture, atlas)
        if ok then return true end
    end
    if fallback then
        texture:SetTexture(fallback)
        return true
    end
    return false
end

local function SetTexCoord8(texture, coords)
    if texture and coords then
        if coords[8] then
            texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4], coords[5], coords[6], coords[7], coords[8])
        else
            texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    end
end

local function GetModelBackgroundToken(race)
    race = race or {}
    local def = MODEL_BG_RACE_TOKENS[tostring(race.id or "")]
    if type(def) == "table" then
        local subToken = def.subraces and def.subraces[tostring(race.subraceId or "")]
        return subToken or def.default
    end
    return def
end

local function SetModelBackgroundBlack(texture)
    if not texture then return end
    texture:SetColorTexture(0, 0, 0, 1)
    texture:SetTexCoord(0, 1, 0, 1)
    texture:SetVertexColor(1, 1, 1, 1)
    texture:SetAlpha(1)
end

local function RefreshRaceModelBackground(sheet, data)
    if not (sheet and sheet.modelBg) then return end
    local token = GetModelBackgroundToken(data and data.race)
    for index, spec in ipairs(MODEL_BG_SOURCES) do
        local t = sheet.modelBg[spec.key]
        if t then
            if token then
                t:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. token .. tostring(index))
                SetTexCoord8(t, MODEL_BG_TEXCOORDS[spec.key])
                t:SetVertexColor(1, 1, 1, 1)
                t:SetAlpha(1)
            else
                SetModelBackgroundBlack(t)
            end
            -- Escena en blanco y negro como el CharacterFrame nativo.
            if t.SetDesaturated then pcall(t.SetDesaturated, t, true) end
            if t.SetDesaturation then pcall(t.SetDesaturation, t, 1) end
        end
    end
end

local function RefreshPaperDollSlots(sheet)
    if not (sheet and sheet.slots) then return end
    for _, slot in ipairs(sheet.slots) do
        if slot.icon then
            local texture = slot.emptyTexture
            if slot.slotToken and GetInventorySlotInfo then
                local _, nativeTexture = GetInventorySlotInfo(slot.slotToken)
                texture = nativeTexture or texture
            end
            slot.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            slot.icon:SetTexCoord(0, 1, 0, 1)
            slot.icon:SetVertexColor(1, 1, 1, 0.88)
            slot.icon:Show()
        end
    end
end

local function CreateFramePage(key)
    local page = CreateFrame("Frame", nil, S.frame)
    page:SetAllPoints(S.frame)
    S.pages[key] = page
    return page
end

-- Lee un recurso (cur/max) del runtime via contexto.
local function ResourceValue(suffixKey)
    if HarfordDnDContext and HarfordDnDContext.Get then
        return tonumber(HarfordDnDContext.Get(suffixKey, 0)) or 0
    end
    return 0
end


-- Borde interior NineSlice nativo (atlas UI-Frame-Inner* del CharacterFrameInset).
-- Dibuja las 4 esquinas (tamaño de atlas) y los 4 bordes tileados alrededor de 'frame'.
local function MakeInnerBorder(frame)
    local function tex()
        local t = frame:CreateTexture(nil, "BORDER")
        return t
    end
    local function atlas(t, name, useSize)
        if t.SetAtlas then pcall(t.SetAtlas, t, name, useSize and true or false) end
    end
    local tl = tex(); atlas(tl, "UI-Frame-InnerTopLeft", true); tl:SetPoint("TOPLEFT")
    local tr = tex(); atlas(tr, "UI-Frame-InnerTopRight", true); tr:SetPoint("TOPRIGHT")
    local bl = tex(); atlas(bl, "UI-Frame-InnerBotLeftCorner", true); bl:SetPoint("BOTTOMLEFT")
    local br = tex(); atlas(br, "UI-Frame-InnerBotRight", true); br:SetPoint("BOTTOMRIGHT")
    -- Tiras de borde: grosor fijo (3px como el nativo, 256x3 / 3x256); el eje que abarca
    -- lo fijan los anclajes entre esquinas. SIN tamaño transversal salian estiradas/grises.
    local top = tex(); atlas(top, "_UI-Frame-InnerTopTile", true)
    top:SetHeight(3)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0); top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 0)
    if top.SetHorizTile then top:SetHorizTile(true) end
    local bot = tex(); atlas(bot, "_UI-Frame-InnerBotTile", true)
    bot:SetHeight(3)
    bot:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, 0); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    if bot.SetHorizTile then bot:SetHorizTile(true) end
    local lft = tex(); atlas(lft, "!UI-Frame-InnerLeftTile", true)
    lft:SetWidth(3)
    lft:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0); lft:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", 0, 0)
    if lft.SetVertTile then lft:SetVertTile(true) end
    local rgt = tex(); atlas(rgt, "!UI-Frame-InnerRightTile", true)
    rgt:SetWidth(3)
    rgt:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 0, 0); rgt:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    if rgt.SetVertTile then rgt:SetVertTile(true) end
end

local function MakePaperDollInnerBorder(parent)
    local function part(name, file, coords, w, h)
        local t = parent:CreateTexture(name, "ARTWORK")
        t:SetTexture(file)
        SetTexCoord8(t, coords)
        t:SetSize(w, h)
        return t
    end
    local parts = "Interface\\CharacterFrame\\Char-Paperdoll-Parts"
    local vertical = "Interface\\CharacterFrame\\Char-Paperdoll-Vertical"
    local horizontal = "Interface\\CharacterFrame\\Char-Paperdoll-Horizontal"
    local tl = part(nil, parts, { 0.40625, 0.8046875, 0.40625, 0.859375, 0.43359375, 0.8046875, 0.43359375, 0.859375 }, 7, 7)
    tl:SetPoint("TOPLEFT", parent, "TOPLEFT", 46, -4)
    local tr = part(nil, parts, { 0.40625, 0.734375, 0.40625, 0.7890625, 0.43359375, 0.734375, 0.43359375, 0.7890625 }, 7, 7)
    tr:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -47, -4)
    local bl = part(nil, parts, { 0.40625, 0.6640625, 0.40625, 0.71875, 0.43359375, 0.6640625, 0.43359375, 0.71875 }, 7, 7)
    bl:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 46, 31)
    local br = part(nil, parts, { 0.40625, 0.59375, 0.40625, 0.6484375, 0.43359375, 0.59375, 0.43359375, 0.6484375 }, 7, 7)
    br:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -47, 31)
    local left = part(nil, vertical, { 0.0625, 0, 0.0625, 1, 0.375, 0, 0.375, 1 }, 5, 32)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", -1, 0)
    left:SetPoint("BOTTOMLEFT", bl, "TOPLEFT", -1, 0)
    if left.SetVertTile then left:SetVertTile(true) end
    local right = part(nil, vertical, { 0.5, 0, 0.5, 1, 0.8125, 0, 0.8125, 1 }, 5, 32)
    right:SetPoint("TOPRIGHT", tr, "BOTTOMRIGHT", 1, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 1, 0)
    if right.SetVertTile then right:SetVertTile(true) end
    local top = part(nil, horizontal, { 0, 0.5, 0, 0.8125, 1, 0.5, 1, 0.8125 }, 32, 5)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 1)
    top:SetPoint("TOPRIGHT", tr, "TOPLEFT", 0, 1)
    if top.SetHorizTile then top:SetHorizTile(true) end
    local bottom = part(nil, horizontal, { 0, 0.0625, 0, 0.375, 1, 0.0625, 1, 0.375 }, 32, 5)
    bottom:SetPoint("BOTTOMLEFT", bl, "BOTTOMRIGHT", 0, -1)
    bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, -1)
    if bottom.SetHorizTile then bottom:SetHorizTile(true) end
end

-- texCoords EXACTOS del PaperDollSidebarTabs nativo (sacados de /harforddebug probeframe).
local SBTAB_TC = {
    TOP     = { 0.015625, 0.003906, 0.015625, 0.046875, 0.453125, 0.003906, 0.453125, 0.046875 },
    BOTTOM  = { 0.015625, 0.054688, 0.015625, 0.105469, 0.453125, 0.054688, 0.453125, 0.105469 },
    GLOW    = { 0.015625, 0.613281, 0.015625, 0.781250, 0.796875, 0.613281, 0.796875, 0.781250 }, -- glow seleccion 50x43
    DIVIDER = { 0.015625, 0.113281, 0.015625, 0.187500, 0.546875, 0.113281, 0.546875, 0.187500 }, -- separador 33x19
    HILITE  = { 0.015625, 0.195313, 0.015625, 0.316406, 0.500000, 0.195313, 0.500000, 0.316406 },
    ICON2   = { 0.015625, 0.324219, 0.015625, 0.460938, 0.531250, 0.324219, 0.531250, 0.460938 }, -- icono tab2 33x34
    ICON3   = { 0.015625, 0.468750, 0.015625, 0.605469, 0.531250, 0.468750, 0.531250, 0.605469 }, -- icono tab3 33x34
    PORTRAIT_BG = { 0.015625, 0.789063, 0.015625, 0.957031, 0.796875, 0.789063, 0.796875, 0.957031 },
}

local function CreateSidebarTabs(parent)
    local tabs = CreateFrame("Frame", nil, parent)
    tabs:SetSize(168, 35)
    tabs:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", -6, -1)
    tabs.buttons = {}
    local texFile = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs"

    local top = tabs:CreateTexture(nil, "BACKGROUND")
    top:SetTexture(texFile)
    SetTexCoord8(top, SBTAB_TC.TOP)
    top:SetSize(28, 11)
    top:SetPoint("BOTTOMLEFT", tabs, "BOTTOMLEFT", 0, 0)

    local bottom = tabs:CreateTexture(nil, "BACKGROUND")
    bottom:SetTexture(texFile)
    SetTexCoord8(bottom, SBTAB_TC.BOTTOM)
    bottom:SetSize(28, 13)
    bottom:SetPoint("BOTTOMRIGHT", tabs, "BOTTOMRIGHT", 0, 0)

    local function selectView(key)
        S.sheetView = key
        RefreshPanel()
    end
    -- bodyKind: tabla de texCoords (icono baked) o "portrait" (retrato del jugador).
    local function makeTab(key, bodyKind, anchorTo)
        local b = CreateFrame("Button", nil, tabs)
        b:SetSize(33, 35)
        if anchorTo then
            b:SetPoint("RIGHT", anchorTo, "LEFT", -4, 0)
        else
            b:SetPoint("BOTTOMRIGHT", tabs, "BOTTOMRIGHT", -30, 0)
        end
        b:EnableMouse(true)
        b:SetScript("OnClick", function() selectView(key) end)

        -- Marco/base grande (50x43). En tabs 2/3 es parte del icono nativo;
        -- no es hover. El estado activo se expresa por alpha del boton completo.
        local glow = b:CreateTexture(nil, "BACKGROUND")
        glow:SetTexture(texFile)
        SetTexCoord8(glow, SBTAB_TC.GLOW)
        glow:SetSize(50, 43)
        glow:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", -9, -2)

        -- Cuerpo (icono 33x34 o retrato).
        local body = b:CreateTexture(nil, "ARTWORK")
        if bodyKind == "portrait" then
            glow:Hide()
            local bg = b:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture(texFile)
            SetTexCoord8(bg, SBTAB_TC.PORTRAIT_BG)
            bg:SetSize(50, 43)
            bg:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", -9, -2)
            b.portraitBg = bg
            body:SetSize(29, 31)
            body:SetPoint("BOTTOM", b, "BOTTOM", 1, 0)
            body:SetTexCoord(0.109375, 0.890625, 0.09375, 0.90625)
            tabs.portrait = body
        else
            body:SetSize(33, 35)
            body:SetPoint("BOTTOM", b, "BOTTOM", 1, -2)
            body:SetTexture(texFile)
            SetTexCoord8(body, bodyKind)
        end

        -- Separador inferior (33x19).
        local divider = b:CreateTexture(nil, "OVERLAY")
        divider:SetTexture(texFile)
        SetTexCoord8(divider, SBTAB_TC.DIVIDER)
        divider:SetSize(33, 19)
        divider:SetPoint("BOTTOM", b, "BOTTOM", 0, 0)

        local hilite = b:CreateTexture(nil, "OVERLAY")
        hilite:SetTexture(texFile)
        SetTexCoord8(hilite, SBTAB_TC.HILITE)
        hilite:SetSize(31, 31)
        hilite:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -3)
        if hilite.SetBlendMode then hilite:SetBlendMode("ADD") end
        hilite:Hide()

        b.body = body
        b.frameGlow = glow
        b.hover = hilite
        b:SetScript("OnEnter", function(self)
            if not self.selected and self.hover then
                self.hover:Show()
            end
        end)
        b:SetScript("OnLeave", function(self)
            if self.hover then
                self.hover:Hide()
            end
        end)
        tabs.buttons[key] = b
        return b
    end

    -- Orden nativo (derecha a izquierda): details, skills, summary(retrato).
    local details = makeTab("details", SBTAB_TC.ICON3)
    local skills = makeTab("skills", SBTAB_TC.ICON2, details)
    makeTab("summary", "portrait", skills)

    function tabs:SetSelected(key)
        for viewKey, button in pairs(self.buttons) do
            local selected = (viewKey == key)
            button.selected = selected
            button:SetAlpha(selected and 1 or 0.498)
            if button.hover then button.hover:Hide() end
        end
    end
    return tabs
end

-- Crea la pagina de Ficha con estilo del panel de personaje nativo.
-- Las coordenadas base salen de CharacterFrame/PaperDollFrame medidos con
-- /harforddebug probeframe CharacterFrame y FrameDump.lua, no de ajustes a ojo.
local function CreateSheetPage()
    local page = CreateFramePage("sheet")
    local SH = {}
    S.sheet = SH
    SH.page = page

    -- CharacterFrameInset: TOPLEFT CharacterFrame 4,-60; BOTTOMRIGHT
    -- CharacterFrame BOTTOMLEFT 332,4. Este bloque mantiene el mismo hueco que
    -- el PaperDoll nativo para modelo y slots.
    local leftInset = CreateFrame("Frame", nil, page)
    leftInset:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -60)
    leftInset:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", 332, 4)
    local lbg = leftInset:CreateTexture(nil, "BACKGROUND")
    lbg:SetAllPoints(leftInset)
    lbg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", true, true)
    if lbg.SetHorizTile then lbg:SetHorizTile(true) end
    if lbg.SetVertTile then lbg:SetVertTile(true) end
    MakeInnerBorder(leftInset)
    SH.leftInset = leftInset

    -- Subtitulo superior del paperdoll. Se alimenta con progresion Harford, pero
    -- usa posicion/fuente de cabecera nativa.
    SH.subtitle = CreateFS(page, "GameFontNormal", "")
    SH.subtitle:SetPoint("TOP", page, "TOP", 0, -36)
    SH.subtitle:SetWidth(320)
    SH.subtitle:SetJustifyH("CENTER")
    SH.subtitle:SetTextColor(1, 0.82, 0)

    -- ===== Huecos de equipo (anclados al inset, posiciones exactas del nativo) =====
    local function MakeSlot(parent, key)
        local b = CreateFrame("Button", nil, parent)
        b:SetSize(37, 37)
        b.nativeName = PAPERDOLL_SLOT_NAMES[key]
        b.slotToken = PAPERDOLL_SLOT_TOKENS[key]
        local frame = b:CreateTexture(nil, "BACKGROUND", nil, -1)
        frame:SetTexture("Interface\\CharacterFrame\\Char-Paperdoll-Parts")
        SetTexCoord8(frame, { 0.20703125, 0.59375, 0.20703125, 0.9375, 0.3984375, 0.59375, 0.3984375, 0.9375 })
        frame:SetSize(49, 44)
        frame:SetPoint("TOPLEFT", b, "TOPLEFT", -4, 0)
        local fill = b:CreateTexture(nil, "BORDER", nil, -2)
        fill:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
        fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
        fill:SetColorTexture(0.015, 0.014, 0.012, 0.25)
        local bevel = b:CreateTexture(nil, "BORDER", nil, -1)
        bevel:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1)
        bevel:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", -1, 1)
        bevel:SetColorTexture(0.18, 0.18, 0.16, 0.08)
        local icon = b:CreateTexture(nil, "BORDER")
        icon:SetAllPoints(b)
        if GetInventorySlotInfo and b.slotToken then
            local _, nativeTexture = GetInventorySlotInfo(b.slotToken)
            b.emptyTexture = nativeTexture
            icon:SetTexture(nativeTexture)
        else
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetVertexColor(1, 1, 1, 0.88)
        if icon.SetDesaturated then pcall(icon.SetDesaturated, icon, false) end
        icon:Show()
        b.icon = icon
        local white = b:CreateTexture(nil, "OVERLAY")
        white:SetTexture("Interface\\Common\\WhiteIconFrame")
        white:SetSize(37, 37)
        white:SetPoint("CENTER", b, "CENTER", 0, 0)
        white:Hide()
        local normal = b:CreateTexture(nil, "ARTWORK")
        normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        normal:SetSize(64, 64)
        normal:SetPoint("CENTER", b, "CENTER", 0, -1)
        normal:SetVertexColor(1, 1, 1, 1)
        SH.slots = SH.slots or {}
        SH.slots[#SH.slots + 1] = b
        return b
    end
    local head = MakeSlot(leftInset, "Head")
    head:SetPoint("TOPLEFT", leftInset, "TOPLEFT", 4, -2)
    local prev = head
    for _, t in ipairs({ "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrists" }) do
        local s = MakeSlot(leftInset, t)
        s:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
        prev = s
    end
    local hands = MakeSlot(leftInset, "Hands")
    hands:SetPoint("TOPRIGHT", leftInset, "TOPRIGHT", -4, -2)
    prev = hands
    for _, t in ipairs({ "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1" }) do
        local s = MakeSlot(leftInset, t)
        s:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
        prev = s
    end
    local mainHand = MakeSlot(leftInset, "MainHand")
    mainHand:SetPoint("BOTTOMLEFT", leftInset, "BOTTOMLEFT", 130, 16)
    local offHand = MakeSlot(leftInset, "SecondaryHand")
    offHand:SetPoint("TOPLEFT", mainHand, "TOPRIGHT", 4, 0)

    -- CharacterModelFrame: 231x320, TOPLEFT PaperDollFrame 52,-66.
    local model = CreateFrame("PlayerModel", nil, leftInset)
    model:SetSize(231, 320)
    model:SetPoint("TOPLEFT", leftInset, "TOPLEFT", 48, -6)
    if model.SetClipsChildren then pcall(model.SetClipsChildren, model, true) end
    local sceneTL = model:CreateTexture(nil, "BACKGROUND")
    sceneTL:SetTexture(131081); sceneTL:SetTexCoord(0.171875, 1, 0.039215688, 1)
    sceneTL:SetSize(212, 245); sceneTL:SetPoint("TOPLEFT", model, "TOPLEFT", 0, 0)
    local sceneTR = model:CreateTexture(nil, "BACKGROUND")
    sceneTR:SetTexture(131082); sceneTR:SetTexCoord(0, 0.296875, 0.039215688, 1)
    sceneTR:SetSize(19, 245); sceneTR:SetPoint("TOPLEFT", sceneTL, "TOPRIGHT", 0, 0)
    local sceneBL = model:CreateTexture(nil, "BACKGROUND")
    sceneBL:SetTexture(131083); sceneBL:SetTexCoord(0.171875, 1, 0, 1)
    sceneBL:SetSize(212, 128); sceneBL:SetPoint("TOPLEFT", sceneTL, "BOTTOMLEFT", 0, 0)
    local sceneBR = model:CreateTexture(nil, "BACKGROUND")
    sceneBR:SetTexture(131084); sceneBR:SetTexCoord(0, 0.296875, 0, 1)
    sceneBR:SetSize(19, 128); sceneBR:SetPoint("TOPLEFT", sceneTL, "BOTTOMRIGHT", 0, 0)
    SH.modelBg = { tl = sceneTL, tr = sceneTR, bl = sceneBL, br = sceneBR }
    for _, q in pairs(SH.modelBg) do
        if q.SetDesaturated then pcall(q.SetDesaturated, q, true) end   -- escena en blanco y negro
        if q.SetDesaturation then pcall(q.SetDesaturation, q, 1) end
    end
    local sceneDark = model:CreateTexture(nil, "BORDER")
    sceneDark:SetAllPoints(model); sceneDark:SetColorTexture(0, 0, 0, 0.4)
    model:SetScript("OnShow", function(self) if self.SetUnit then self:SetUnit("player") end end)
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self)
        self._lastX = ({ GetCursorPosition() })[1]
        self:SetScript("OnUpdate", function(s)
            local x = ({ GetCursorPosition() })[1]
            local dx = x - (s._lastX or x)
            s._lastX = x
            s._rot = (s._rot or 0) + dx * 0.012
            if s.SetRotation then s:SetRotation(s._rot) end
        end)
    end)
    model:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
    model:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    SH.model = model
    MakePaperDollInnerBorder(leftInset)
    -- El inset nativo tapa toda la zona bajo el modelo con una banda oscura.
    -- Si dejamos asomar el Marble del fondo aparecen franjas grises en la base.
    local lowerMask = leftInset:CreateTexture(nil, "BACKGROUND", nil, 1)
    lowerMask:SetColorTexture(0.012, 0.011, 0.01, 0.98)
    lowerMask:SetPoint("BOTTOMLEFT", leftInset, "BOTTOMLEFT", 4, 5)
    lowerMask:SetPoint("TOPRIGHT", leftInset, "BOTTOMRIGHT", -4, 52)
    local lowerTop = leftInset:CreateTexture(nil, "BORDER", nil, 1)
    lowerTop:SetColorTexture(0.9, 0.82, 0.58, 0.12)
    lowerTop:SetPoint("TOPLEFT", lowerMask, "TOPLEFT", 0, 0)
    lowerTop:SetPoint("TOPRIGHT", lowerMask, "TOPRIGHT", 0, 0)
    lowerTop:SetHeight(1)

    -- CharacterFrameInsetRight: TOPLEFT CharacterFrameInset TOPRIGHT 1,0;
    -- BOTTOMRIGHT CharacterFrame -4,4.
    local right = CreateFrame("Frame", nil, page)
    right:SetPoint("TOPLEFT", leftInset, "TOPRIGHT", 1, 0)
    right:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 4)
    local rbg = right:CreateTexture(nil, "BACKGROUND")
    rbg:SetAllPoints(right)
    rbg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", true, true)
    if rbg.SetHorizTile then rbg:SetHorizTile(true) end
    if rbg.SetVertTile then rbg:SetVertTile(true) end
    MakeInnerBorder(right)
    SH.right = right
    SH.sidebarTabs = CreateSidebarTabs(right)

    -- CharacterStatsPane: TOPLEFT right 3,-3; BOTTOMRIGHT right -3,2.
    local statsPane = CreateFrame("Frame", nil, right)
    statsPane:SetPoint("TOPLEFT", right, "TOPLEFT", 3, -3)
    statsPane:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -3, 2)
    SH.statsPane = statsPane
    SH.statsBg = statsPane:CreateTexture(nil, "BACKGROUND")
    SH.statsBg:SetAllPoints(statsPane)
    ApplyAtlasOrTexture(SH.statsBg, "UI-Character-Info-Warrior-BG", 1400895)

    local function CatBar(label, y)
        local bar = CreateFrame("Frame", nil, statsPane)
        bar:SetSize(197, 40)
        bar:SetPoint("TOP", statsPane, "TOP", 0, y)
        local tex = bar:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(bar)
        if tex.SetAtlas then tex:SetAtlas("UI-Character-Info-Title") else tex:SetTexture(1400895) end
        local t = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        t:SetPoint("CENTER", bar, "CENTER", 0, 1)
        t:SetText(label)
        bar.text = t
        return bar
    end
    local function ValueBounceFrame(anchor)
        local valueFrame = CreateFrame("Frame", nil, statsPane)
        valueFrame:SetSize(187, 29)
        valueFrame:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
        local bg = valueFrame:CreateTexture(nil, "BORDER")
        bg:SetSize(162, 29)
        bg:SetPoint("CENTER", valueFrame, "CENTER", 0, 0)
        if not ApplyAtlasOrTexture(bg, "UI-Character-Info-ItemLevel-Bounce", 1400895) then
            bg:SetTexture(1400895)
        end
        bg:SetAlpha(0.298)
        valueFrame.bg = bg
        return valueFrame
    end
    local function PaneRow(y)
        local rowFrame = CreateFrame("Frame", nil, statsPane)
        rowFrame:SetSize(170, 15)
        rowFrame:SetPoint("TOPLEFT", statsPane, "TOPLEFT", 14, y + 3)
        local stripe = rowFrame:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints(rowFrame)
        stripe:SetColorTexture(1, 1, 1, 0.045)
        local l = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        l:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
        l:SetJustifyH("LEFT")
        l:SetTextColor(1, 0.82, 0)
        local v = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        v:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
        v:SetJustifyH("RIGHT")
        v:SetTextColor(1, 1, 1)
        return { f = rowFrame, l = l, v = v, stripe = stripe }
    end

    SH.levelBar = CatBar("Nivel", -2)
    SH.levelValueFrame = ValueBounceFrame(SH.levelBar)
    SH.levelText = SH.levelValueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    SH.levelText:SetPoint("CENTER", SH.levelValueFrame, "CENTER", 0, -1)
    SH.levelText:SetTextColor(1, 0.82, 0)

    SH.abilBar = CatBar("Caracteristicas", -70)
    SH.abilRows = {}
    for i = 1, 6 do
        SH.abilRows[i] = PaneRow(-110 - (i - 1) * 15)
        SH.abilRows[i].stripe:SetAlpha((i % 2 == 0) and 0.03 or 0.07)
    end

    SH.combatBar = CatBar("Combate", -206)
    SH.combatRows = {}
    for i = 1, 7 do
        SH.combatRows[i] = PaneRow(-246 - (i - 1) * 15)
        SH.combatRows[i].stripe:SetAlpha((i % 2 == 0) and 0.03 or 0.07)
    end
    SH.sheetRows = {}
    for i = 1, 26 do
        SH.sheetRows[i] = PaneRow(-52 - (i - 1) * 14)
        SH.sheetRows[i].stripe:SetAlpha((i % 2 == 0) and 0.025 or 0.065)
    end

    -- Origen oculto (el nativo no lo muestra; se reubicara mas adelante).
    SH.origin = CreateFS(page, "GameFontHighlightSmall", "")
    SH.origin:SetPoint("BOTTOMLEFT", leftInset, "BOTTOMLEFT", 6, 2)
    SH.origin:Hide()
end

local function SetSheetBar(bar, label, y, shown)
    if not bar then return end
    bar:ClearAllPoints()
    bar:SetPoint("TOP", S.sheet.statsPane, "TOP", 0, y)
    if bar.text then bar.text:SetText(label or "") end
    bar:SetShown(shown ~= false)
end

local function SetSheetRow(row, y, label, value, tooltipTitle, tooltipText, opts)
    if not row then return 14 end
    opts = type(opts) == "table" and opts or nil
    row.f:ClearAllPoints()
    row.f:SetPoint("TOPLEFT", S.sheet.statsPane, "TOPLEFT", 14, y)
    row.f:SetSize(170, 15)
    row.l:ClearAllPoints()
    row.l:SetPoint("LEFT", row.f, "LEFT", 0, 0)
    row.l:SetWidth(opts and opts.labelWidth or 118)
    row.l:SetJustifyH("LEFT")
    if row.l.SetWordWrap then row.l:SetWordWrap(false) end
    if row.l.SetNonSpaceWrap then row.l:SetNonSpaceWrap(false) end
    row.v:ClearAllPoints()
    row.v:SetWidth(opts and opts.valueWidth or 72)
    if row.v.SetWordWrap then row.v:SetWordWrap(opts and opts.wrapValue or false) end
    if row.v.SetNonSpaceWrap then row.v:SetNonSpaceWrap(false) end
    if opts and opts.valueAlign == "LEFT" then
        row.v:SetPoint("TOPLEFT", row.f, "TOPLEFT", opts.valueX or 78, 0)
        row.v:SetJustifyH("LEFT")
    else
        row.v:SetPoint("TOPRIGHT", row.f, "TOPRIGHT", 0, 0)
        row.v:SetJustifyH("RIGHT")
    end
    if row.classTexts then
        for _, fs in ipairs(row.classTexts) do
            fs:Hide()
        end
    end
    row.l:SetText(label or "")
    row.v:SetText(value or "")
    local valueHeight = 14
    if row.v.GetStringHeight then
        valueHeight = math.max(valueHeight, math.ceil(row.v:GetStringHeight() or 14))
    end
    local rowHeight = math.max(14, valueHeight)
    row.f:SetHeight(rowHeight)
    if tooltipTitle or tooltipText then
        row.f:EnableMouse(true)
        row.f:SetScript("OnEnter", function(self) TooltipLines(self, tooltipTitle or label, tooltipText, opts and opts.tooltip) end)
        row.f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    else
        row.f:SetScript("OnEnter", nil)
        row.f:SetScript("OnLeave", nil)
        row.f:EnableMouse(false)
    end
    row.f:Show()
    row.l:Show()
    row.v:Show()
    return rowHeight
end

-- Tooltip de clase para la fila multiclase: una entrada por clase con su color y su
-- descripcion (subclase si esta elegida, si no la clase). El bloque coloreado de la
-- fila no admite el OnEnter de SetSheetRow, asi que lo gestionamos aqui directamente.
local function ShowClassTooltip(owner, data)
    if not (GameTooltip and owner and data and data.classLevels and HarfordDnDBook) then return end
    if #data.classLevels == 0 then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText("Clase", 1, 0.82, 0, true)
    for _, entry in ipairs(data.classLevels) do
        local className = (HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId)) or entry.classId
        local subName = (HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(entry.classId, entry.subclassId)) or ""
        local classDef = HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(entry.classId)
        local subDef = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
        local r, g, b = GetClassColorParts(entry, className, className)
        local head = tostring(className or "")
        if subName ~= "" then head = head .. " " .. subName end
        head = head .. " (" .. tostring(entry.level or 1) .. ")"
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(head, r or 1, g or 0.82, b or 0, true)
        local desc = (subDef and subDef.desc) or (classDef and classDef.desc)
        if desc and desc ~= "" then
            GameTooltip:AddLine(desc, 1, 1, 1, true)
        end
    end
    GameTooltip:Show()
end

local function SetClassSheetRow(row, y, data)
    SetSheetRow(row, y, "Clase", "")
    if not row then return 14 end
    local parts = GetClassParts(data) or { { text = "Sin clase", r = 1, g = 0.82, b = 0 } }
    SetColoredTextList(row.f, row, "classTexts", parts, { font = "GameFontHighlightSmall" })
    row.v:Hide()

    local valueWidth = 112
    local lineHeight = 12
    local yOffset = 0
    for i, fs in ipairs(row.classTexts or {}) do
        if i <= #parts then
            fs:ClearAllPoints()
            fs:SetPoint("TOPRIGHT", row.f, "TOPRIGHT", 0, -yOffset)
            fs:SetWidth(valueWidth)
            fs:SetJustifyH("RIGHT")
            if fs.SetWordWrap then fs:SetWordWrap(true) end
            if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(false) end
            fs:SetTextColor(parts[i].r or 1, parts[i].g or 1, parts[i].b or 1)
            fs:Show()
            local h = lineHeight
            if fs.GetStringHeight then
                h = math.max(lineHeight, math.ceil(fs:GetStringHeight() or lineHeight))
            end
            yOffset = yOffset + h
        end
    end
    local rowHeight = math.max(14, yOffset)
    row.f:SetHeight(rowHeight)
    -- Tooltip multiclase (SetSheetRow desactivo el mouse al no pasar tooltip).
    if data and data.classLevels and #data.classLevels > 0 then
        row.f:EnableMouse(true)
        row.f:SetScript("OnEnter", function(self) ShowClassTooltip(self, data) end)
        row.f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    return rowHeight
end

local function HideSheetRows(SH)
    local function hideList(list)
        if not list then return end
        for _, row in ipairs(list) do
            if row and row.f then row.f:Hide() end
        end
    end
    hideList(SH.abilRows)
    hideList(SH.combatRows)
    hideList(SH.sheetRows)
    if SH.levelBar then SH.levelBar:Hide() end
    if SH.levelValueFrame then SH.levelValueFrame:Hide() end
    if SH.abilBar then SH.abilBar:Hide() end
    if SH.combatBar then SH.combatBar:Hide() end
    if SH.levelText then SH.levelText:Hide() end
end

local function SkillTotal(skill)
    if HarfordDnDCalc and HarfordDnDCalc.GetSkillRollBonuses then
        local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)
        return (tonumber(base) or 0) + (tonumber(prof) or 0)
    end
    return AbilityMod(AbilityScore(skill.ability))
end

local function SaveTotal(abilityKey)
    if HarfordDnDCalc and HarfordDnDCalc.GetSaveRollBonuses then
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(abilityKey)
        return (tonumber(base) or 0) + (tonumber(prof) or 0)
    end
    return AbilityMod(AbilityScore(abilityKey))
end

local function RefreshSheet()
    local SH = S.sheet
    if not SH then return end
    local name = GetProfileName()
    local data = GetProgression()
    local total = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(name) or 0

    RefreshSubtitleClasses(SH, data)
    if SH.model and SH.model.SetUnit then SH.model:SetUnit("player") end
    RefreshRaceModelBackground(SH, data)
    RefreshPaperDollSlots(SH)
    if SH.sidebarTabs and SH.sidebarTabs.portrait and SetPortraitTexture then
        SetPortraitTexture(SH.sidebarTabs.portrait, "player")
        SH.sidebarTabs.portrait:SetTexCoord(0.109375, 0.890625, 0.09375, 0.90625)
        if SH.sidebarTabs.SetSelected then SH.sidebarTabs:SetSelected(S.sheetView or "summary") end
    end
    if SH.statsBg then
        local atlas = GetClassInfoAtlas(data)
        if not ApplyAtlasOrTexture(SH.statsBg, atlas, 1400895) then
            ApplyAtlasOrTexture(SH.statsBg, "UI-Character-Info-Warrior-BG", 1400895)
        end
    end

    HideSheetRows(SH)

    local list = (HarfordDnDData and HarfordDnDData.ABIL) or ABIL_KEYS
    local pb = HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus and HarfordDnDProgression.GetProficiencyBonus(name) or nil
    local dexMod = AbilityMod(AbilityScore("Destreza"))
    local initBonus = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus and HarfordDnDFeatureEffects.GetBonus("initiative", nil, name)) or 0
    local ca = (HarfordDnDContext and HarfordDnDContext.Get and tonumber(HarfordDnDContext.Get("ArmorClass", 10))) or 10
    local hpCur = HarfordDnDResources and ResourceValue(HarfordDnDResources.CurKey("health")) or 0
    local hpMax = HarfordDnDResources and ResourceValue(HarfordDnDResources.MaxKey("health")) or 0
    local speed
    if data and data.race and HarfordDnDRaces and HarfordDnDRaces.GetRace then
        local rd = HarfordDnDRaces.GetRace(data.race.id)
        speed = rd and rd.speed
    end

    local view = S.sheetView or "summary"
    if view == "skills" then
        -- Sin barra de "Bonificador por competencia" (libera espacio); el bono va en la cabecera.
        SetSheetBar(SH.levelBar, "", 0, false)
        SetSheetBar(SH.abilBar, "Habilidades " .. (pb and ("(" .. ColorSigned(pb) .. ")") or ""), -2, true)
        local skills = HarfordDnDData and HarfordDnDData.SKILLS or {}
        -- Agrupadas por caracteristica (cabecera "Fuerza (+3)" y sus habilidades debajo).
        local y, index = -42, 1
        for _, abil in ipairs(list) do
            local group = {}
            for _, skill in ipairs(skills) do
                if skill.ability == abil.key then group[#group + 1] = skill end
            end
            if #group > 0 and SH.sheetRows[index] then
                SetSheetRow(SH.sheetRows[index], y,
                    "|cffffd200" .. abil.key .. " |r" .. ColorSigned(AbilityMod(AbilityScore(abil.key))), "")
                y = y - 13; index = index + 1
                for _, skill in ipairs(group) do
                    if SH.sheetRows[index] then
                        SetSheetRow(SH.sheetRows[index], y, "   " .. skill.name, ColorSigned(SkillTotal(skill)),
                            skill.name, skill.desc or ("Caracteristica: " .. abil.key .. "."),
                            { labelWidth = 140, valueWidth = 32 })
                        y = y - 13; index = index + 1
                    end
                end
            end
        end
    elseif view == "details" then
        SetSheetBar(SH.levelBar, "Atributos", -2, true)
        -- Tooltips de raza/trasfondo: subraza si existe, si no la raza.
        local raceTipTitle, raceTipText, bgTipTitle, bgTipText
        if data and data.race and HarfordDnDRaces and HarfordDnDRaces.GetRace then
            local rd = HarfordDnDRaces.GetRace(data.race.id)
            local sd = HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(data.race.id, data.race.subraceId)
            local txt = (sd and sd.desc) or (rd and rd.desc)
            if txt and txt ~= "" then raceTipTitle, raceTipText = GetRaceLabel(data), txt end
        end
        if data and data.background and data.background ~= "" and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground then
            local bd = HarfordDnDBackgrounds.GetBackground(data.background)
            local txt = bd and (bd.desc or bd.description)
            -- Trasfondo personalizado (no esta en el libro): usa el 1er parrafo cargado del TRP3.
            if (not txt or txt == "") and data.backgroundDesc and data.backgroundDesc ~= "" then
                txt = data.backgroundDesc
            end
            if txt and txt ~= "" then bgTipTitle, bgTipText = (bd and bd.name) or GetBackgroundLabel(data), txt end
        end
        local rows = {
            { "Puntos de Golpe", hpMax > 0 and (tostring(hpCur) .. " / " .. tostring(hpMax)) or "-" },
            { "Clase de Armadura", tostring(ca) },
            { "Clase", GetClassSummary(data, "\n") },
            { "Raza", GetRaceLabel(data), raceTipTitle, raceTipText },
            { "Trasfondo", GetBackgroundLabel(data), bgTipTitle, bgTipText },
            { "Iniciativa", Signed(dexMod + initBonus) },
            { "Velocidad", speed and (tostring(speed) .. " m") or "-" },
            { "Competencia", pb and Signed(pb) or "-" },
        }
        if HarfordDnDMana and HarfordDnDProgression and HarfordDnDProgression.GetUseMana
            and HarfordDnDProgression.GetUseMana(name) then
            local pool = HarfordDnDMana.GetManaPool and HarfordDnDMana.GetManaPool(name) or 0
            local ms = HarfordDnDMana.GetMaxSpellLevel and HarfordDnDMana.GetMaxSpellLevel(name) or 0
            rows[#rows + 1] = { "Mana", tostring(pool) .. "  (esp. " .. tostring(ms) .. ")" }
        end
        local y = -50
        for i, r in ipairs(rows) do
            if r[1] == "Clase" then
                y = y - SetClassSheetRow(SH.sheetRows[i], y, data)
            else
                local opts = r[1] == "Trasfondo" and { wrapValue = true, labelWidth = 70, valueWidth = 104 } or nil
                y = y - SetSheetRow(SH.sheetRows[i], y, r[1], "|cffffffff" .. tostring(r[2] or "") .. "|r", r[3], r[4], opts)
            end
        end
        SetSheetBar(SH.abilBar, "Salvaciones", -206, true)
        for i, abil in ipairs(list) do
            SetSheetRow(SH.sheetRows[#rows + i], -244 - (i - 1) * 14, abil.key, ColorSigned(SaveTotal(abil.key)), "Salvacion de " .. abil.key, abil.saveDesc or abil.desc or ("Tirada de salvacion de " .. abil.key .. "."))
        end
    else
        SetSheetBar(SH.levelBar, "Nivel", -2, true)
        if SH.levelValueFrame then SH.levelValueFrame:Show() end
        if SH.levelText then
            SH.levelText:SetText(tostring(total))
            SH.levelText:Show()
        end
        SetSheetBar(SH.abilBar, "Caracteristicas", -70, true)
        for i, abil in ipairs(list) do
            local score = AbilityScore(abil.key)
            local mod = AbilityMod(score)
            SetSheetRow(SH.sheetRows[i], -107 - (i - 1) * 15, abil.key,
                "|cffffffff" .. tostring(score) .. "|r   " .. ColorSignedAligned(mod),
                AbilityTooltipTitle(abil.key),
                ABILITY_TOOLTIP_TEXT[abil.key] or "",
                { tooltip = { nativeAbility = true } })
        end
        SetSheetBar(SH.combatBar, "Rasgos destacables", -206, true)
        local featureRows = GetClassFeatureRows(5) or GetTRP3FeatureRows(5) or {
            { "Raza", GetRaceLabel(data), "Raza", GetRaceLabel(data) },
            { "Trasfondo", GetBackgroundLabel(data), "Trasfondo", GetBackgroundLabel(data) },
            { "Dotes", GetFeatsLabel(data), "Dotes", GetFeatsLabel(data) },
            { "Competencia", pb and Signed(pb) or "-", "Competencia", "Bonificador por competencia actual." },
            { "Puntos de Golpe", hpMax > 0 and (tostring(hpCur) .. " / " .. tostring(hpMax)) or "-", "Puntos de Golpe", "Salud actual / maxima." },
        }
        for i, r in ipairs(featureRows) do
            SetSheetRow(SH.sheetRows[6 + i], -244 - (i - 1) * 15, r[1], "|cffffffff" .. r[2] .. "|r", r[3], r[4])
        end
    end

    SH.origin:SetText("Raza: " .. GetRaceLabel(data) .. "\nTrasfondo: " .. GetBackgroundLabel(data) .. "\n" .. GetFeatsLabel(data))
end

local function RefreshCreationCost()
    local C = S.creation
    if not C then return end
    local total, valid = 0, true
    for _, abil in ipairs(ABIL_KEYS) do
        local value = tonumber(C.boxes[abil.key]:GetText()) or 10
        if not POINT_BUY_COST[value] then
            valid = false
        else
            total = total + POINT_BUY_COST[value]
        end
    end
    if valid then
        C.cost:SetText("Compra por puntos: " .. tostring(total) .. " / 27")
        C.cost:SetTextColor(total <= 27 and 0.6 or 1, total <= 27 and 1 or 0.2, 0.2)
    else
        C.cost:SetText("Compra por puntos: valores validos 8-15")
        C.cost:SetTextColor(1, 0.25, 0.25)
    end
end

local function RollAbility()
    local rolls = {}
    for i = 1, 4 do rolls[i] = random(1, 6) end
    table.sort(rolls)
    return rolls[2] + rolls[3] + rolls[4]
end

local function ApplyCreationScores()
    if not (HarfordDnDContext and HarfordDnDContext.Set and S.creation) then
        Print("La ficha DnD todavia no esta lista.")
        return
    end
    for _, abil in ipairs(ABIL_KEYS) do
        local value = math.floor(tonumber(S.creation.boxes[abil.key]:GetText()) or 10)
        if value < 1 then value = 1 end
        if value > 30 then value = 30 end
        HarfordDnDContext.Set(abil.key, value)
    end
    RefreshGameUI()
    RefreshPanel()
    Print("Caracteristicas aplicadas.")
end

local function CreateCreationPage()
    local page = CreatePage("creation")
    local C = { boxes = {} }
    S.creation = C

    local title = CreateFS(page, "GameFontNormalLarge", "Creacion de ficha")
    title:SetPoint("TOPLEFT", 0, 0)
    local hint = CreateFS(page, "GameFontHighlightSmall", "Ajusta las caracteristicas base. Raza, dotes y rasgos se suman despues como capa derivada.")
    hint:SetPoint("TOPLEFT", 0, -28)
    hint:SetWidth(620)
    hint:SetNonSpaceWrap(true)

    for i, abil in ipairs(ABIL_KEYS) do
        local x = ((i - 1) % 3) * 190
        local y = -78 - math.floor((i - 1) / 3) * 54
        local label = CreateFS(page, "GameFontHighlight", abil.short .. " - " .. abil.key)
        label:SetPoint("TOPLEFT", x, y)
        local box = CreateEdit(page, 58, true)
        box:SetPoint("TOPLEFT", x + 84, y + 3)
        box:SetScript("OnTextChanged", RefreshCreationCost)
        C.boxes[abil.key] = box
    end

    C.cost = CreateFS(page, "GameFontHighlightSmall", "")
    C.cost:SetPoint("TOPLEFT", 0, -188)

    local read = CreateButton(page, "Leer ficha", 90, 22, function()
        for _, abil in ipairs(ABIL_KEYS) do C.boxes[abil.key]:SetText(tostring(AbilityScore(abil.key))) end
        RefreshCreationCost()
    end)
    read:SetPoint("TOPLEFT", 0, -220)

    local array = CreateButton(page, "Array", 74, 22, function()
        local values = { 15, 14, 13, 12, 10, 8 }
        for i, abil in ipairs(ABIL_KEYS) do C.boxes[abil.key]:SetText(tostring(values[i] or 10)) end
    end)
    array:SetPoint("LEFT", read, "RIGHT", 8, 0)

    local pointBuy = CreateButton(page, "Compra 27", 92, 22, function()
        for _, abil in ipairs(ABIL_KEYS) do C.boxes[abil.key]:SetText("8") end
    end)
    pointBuy:SetPoint("LEFT", array, "RIGHT", 8, 0)

    local rolled = CreateButton(page, "Tirar 4d6", 92, 22, function()
        for _, abil in ipairs(ABIL_KEYS) do C.boxes[abil.key]:SetText(tostring(RollAbility())) end
    end)
    rolled:SetPoint("LEFT", pointBuy, "RIGHT", 8, 0)

    local apply = CreateButton(page, "Aplicar", 110, 24, ApplyCreationScores)
    apply:SetPoint("TOPLEFT", 0, -262)
end

local function RefreshCreation()
    if not S.creation then return end
    for _, abil in ipairs(ABIL_KEYS) do
        S.creation.boxes[abil.key]:SetText(tostring(HarfordDnDContext and HarfordDnDContext.Get and HarfordDnDContext.Get(abil.key, 10) or 10))
    end
    RefreshCreationCost()
end

local function RefreshSubraceDrop()
    local L = S.leveling
    if not L then return end
    local data = GetProgression() or {}
    local race = data.race or {}
    local sub = HarfordDnDRaces and HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(race.id, race.subraceId)
    SetDropText(L.subraceDrop, sub and sub.name or "Sin subraza")
    UIDropDownMenu_Initialize(L.subraceDrop, function()
        local raceDef = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(race.id)
        if not (raceDef and raceDef.subraces and #raceDef.subraces > 0) then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Sin subraza"
            info.func = function()
                HarfordDnDProgression.SetRace(race.id, "", GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
            return
        end
        for _, subDef in ipairs(raceDef.subraces) do
            local subChoice = subDef
            local info = UIDropDownMenu_CreateInfo()
            info.text = subChoice.name
            if subChoice.desc and subChoice.desc ~= "" then
                info.tooltipTitle = subChoice.name
                info.tooltipText = subChoice.desc
                info.tooltipOnButton = true
            end
            info.checked = race.subraceId == subChoice.id
            info.func = function()
                HarfordDnDProgression.SetRace(race.id, subChoice.id, GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
end

local function SaveClassEntry()
    if not (HarfordDnDProgression and HarfordDnDBook and S.classId and S.leveling) then return end
    local ok, err = HarfordDnDProgression.SetClassEntry(S.selectedClassIndex, S.classId, S.subclassId, S.leveling.levelBox:GetText(), GetProfileName())
    if not ok then
        Print(err or "No se pudo guardar la clase.")
        return
    end
    RefreshGameUI()
    RefreshPanel()
end

local function RefreshFeatureList()
    local L = S.leveling
    local child = L.featureChild
    ClearDynamicRows(child)
    local y = 0
    local features = HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures and HarfordDnDProgression.GetUnlockedFeatures(GetProfileName()) or {}
    if #features == 0 then
        MakeLine(child, "Aun no hay rasgos desbloqueados.", 0, y, "GameFontDisableSmall")
        child:SetHeight(80)
        return
    end
    for _, item in ipairs(features) do
        local feature = item.feature
        if feature then
            local row = AddDynamicRow(child, CreateFrame("Frame", nil, child))
            row:SetPoint("TOPLEFT", 0, y)
            row:SetSize(600, 36)

            local name = CreateFS(row, "GameFontHighlightSmall", (feature.name or feature.id or "Rasgo") .. " |cff888888" .. tostring(item.className or "") .. "|r")
            name:SetPoint("TOPLEFT", 0, -2)
            name:SetWidth(548)

            local desc = CreateFS(row, "GameFontDisableSmall", feature.description or "")
            desc:SetPoint("TOPLEFT", 0, -18)
            desc:SetWidth(548)
            desc:SetNonSpaceWrap(false)
            y = y - 40

            if feature.choice and HarfordDnDBook and HarfordDnDBook.GetChoiceSlots then
                local chosen = HarfordDnDProgression.GetChoice and HarfordDnDProgression.GetChoice(feature.id, GetProfileName()) or {}
                for slot = 1, HarfordDnDBook.GetChoiceSlots(feature) do
                    local slotNo = slot
                    local drop = AddDynamicRow(child, CreateDrop(child, 210))
                    drop:SetPoint("TOPLEFT", 0, y)
                    local opt = HarfordDnDBook.GetChoiceOption and HarfordDnDBook.GetChoiceOption(feature, chosen[slotNo])
                    SetDropText(drop, opt and opt.label or ("Eleccion " .. tostring(slotNo)))
                    UIDropDownMenu_Initialize(drop, function()
                        for _, option in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
                            local optionChoice = option
                            local info = UIDropDownMenu_CreateInfo()
                            info.text = optionChoice.label
                            info.checked = chosen[slotNo] == optionChoice.id
                            info.func = function()
                                HarfordDnDProgression.SetChoiceSlot(feature.id, slotNo, optionChoice.id, GetProfileName())
                                RefreshGameUI()
                                RefreshPanel()
                            end
                            UIDropDownMenu_AddButton(info)
                        end
                    end)
                    y = y - 30
                end
            end
        end
    end
    child:SetHeight(math.max(240, -y + 20))
end

local function CreateLevelingPage()
    local page = CreatePage("leveling")
    local L = {}
    S.leveling = L

    local titleA = CreateFS(page, "GameFontNormalLarge", "Origen")
    titleA:SetPoint("TOPLEFT", 0, 0)
    local titleB = CreateFS(page, "GameFontNormalLarge", "Clases y rasgos")
    titleB:SetPoint("TOPLEFT", 310, 0)

    L.raceDrop = CreateDrop(page, 180)
    L.raceDrop:SetPoint("TOPLEFT", -16, -34)
    UIDropDownMenu_Initialize(L.raceDrop, function()
        if not (HarfordDnDRaces and HarfordDnDRaces.GetRaces) then return end
        local none = UIDropDownMenu_CreateInfo()
        none.text = "Sin raza"
        none.func = function()
            HarfordDnDProgression.SetRace("", "", GetProfileName())
            RefreshGameUI()
            RefreshPanel()
        end
        UIDropDownMenu_AddButton(none)
        for _, raceDef in ipairs(HarfordDnDRaces.GetRaces()) do
            local raceChoice = raceDef
            local info = UIDropDownMenu_CreateInfo()
            info.text = raceChoice.name
            if raceChoice.desc and raceChoice.desc ~= "" then
                info.tooltipTitle = raceChoice.name
                info.tooltipText = raceChoice.desc
                info.tooltipOnButton = true
            end
            info.func = function()
                local sub = HarfordDnDRaces.GetDefaultSubraceId(raceChoice.id) or ""
                HarfordDnDProgression.SetRace(raceChoice.id, sub, GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    L.subraceDrop = CreateDrop(page, 180)
    L.subraceDrop:SetPoint("TOPLEFT", -16, -68)

    L.backgroundDrop = CreateDrop(page, 180)
    L.backgroundDrop:SetPoint("TOPLEFT", -16, -102)
    UIDropDownMenu_Initialize(L.backgroundDrop, function()
        if not (HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgrounds) then return end
        local none = UIDropDownMenu_CreateInfo()
        none.text = "Sin trasfondo"
        none.func = function()
            HarfordDnDProgression.SetBackground("", GetProfileName())
            RefreshGameUI()
            RefreshPanel()
        end
        UIDropDownMenu_AddButton(none)
        for _, bgDef in ipairs(HarfordDnDBackgrounds.GetBackgrounds()) do
            local bgChoice = bgDef
            local info = UIDropDownMenu_CreateInfo()
            info.text = bgChoice.name
            local bgDesc = bgChoice.desc or bgChoice.description
            if bgDesc and bgDesc ~= "" then
                info.tooltipTitle = bgChoice.name
                info.tooltipText = bgDesc
                info.tooltipOnButton = true
            end
            info.func = function()
                HarfordDnDProgression.SetBackground(bgChoice.id, GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    L.featsDrop = CreateDrop(page, 180)
    L.featsDrop:SetPoint("TOPLEFT", -16, -136)
    UIDropDownMenu_Initialize(L.featsDrop, function()
        if not (HarfordDnDFeats and HarfordDnDFeats.GetFeats) then return end
        for _, featDef in ipairs(HarfordDnDFeats.GetFeats()) do
            local featChoice = featDef
            local info = UIDropDownMenu_CreateInfo()
            info.text = featChoice.name
            local featDesc = featChoice.desc or featChoice.description
            if featDesc and featDesc ~= "" then
                info.tooltipTitle = featChoice.name
                info.tooltipText = featDesc
                info.tooltipOnButton = true
            end
            info.keepShownOnClick = true
            info.isNotRadio = true
            info.checked = HarfordDnDProgression and HarfordDnDProgression.HasFeat and HarfordDnDProgression.HasFeat(featChoice.id, GetProfileName()) or false
            info.func = function(_, _, _, checked)
                HarfordDnDProgression.SetFeatEnabled(featChoice.id, checked, GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    L.manaCheck = CreateCheck(page, "Usar Mana", function(_, checked)
        HarfordDnDProgression.SetUseMana(checked, GetProfileName())
        RefreshGameUI()
        RefreshPanel()
    end)
    L.manaCheck:SetPoint("TOPLEFT", 0, -176)
    L.manaInfo = CreateFS(page, "GameFontDisableSmall", "")
    L.manaInfo:SetPoint("TOPLEFT", 4, -208)
    L.manaInfo:SetWidth(260)

    L.classDrop = CreateDrop(page, 170)
    L.classDrop:SetPoint("TOPLEFT", 292, -34)
    UIDropDownMenu_Initialize(L.classDrop, function()
        if not (HarfordDnDBook and HarfordDnDBook.GetClasses) then return end
        for _, classDef in ipairs(HarfordDnDBook.GetClasses()) do
            local classChoice = classDef
            local info = UIDropDownMenu_CreateInfo()
            info.text = classChoice.name
            if classChoice.desc and classChoice.desc ~= "" then
                info.tooltipTitle = classChoice.name
                info.tooltipText = classChoice.desc
                info.tooltipOnButton = true
            end
            info.func = function()
                S.classId = classChoice.id
                S.subclassId = HarfordDnDBook.GetDefaultSubclassId(classChoice.id) or ""
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    L.subclassDrop = CreateDrop(page, 170)
    L.subclassDrop:SetPoint("TOPLEFT", 292, -68)

    local lvl = CreateFS(page, "GameFontHighlightSmall", "Nivel")
    lvl:SetPoint("TOPLEFT", 312, -106)
    L.levelBox = CreateEdit(page, 42, true)
    L.levelBox:SetPoint("TOPLEFT", 360, -102)

    local save = CreateButton(page, "Guardar", 82, 22, SaveClassEntry)
    save:SetPoint("TOPLEFT", 416, -102)
    local add = CreateButton(page, "Nueva", 72, 22, function()
        local data = GetProgression()
        S.selectedClassIndex = data and data.classLevels and (#data.classLevels + 1) or 1
        SaveClassEntry()
    end)
    add:SetPoint("LEFT", save, "RIGHT", 8, 0)
    local remove = CreateButton(page, "Quitar", 72, 22, function()
        HarfordDnDProgression.RemoveClassEntry(S.selectedClassIndex, GetProfileName())
        S.selectedClassIndex = 1
        RefreshGameUI()
        RefreshPanel()
    end)
    remove:SetPoint("LEFT", add, "RIGHT", 8, 0)

    L.entryText = CreateFS(page, "GameFontHighlightSmall", "")
    L.entryText:SetPoint("TOPLEFT", 310, -138)
    L.entryButtons = {}
    for i = 1, 4 do
        local btn = CreateButton(page, "", 132, 20, function(self)
            S.selectedClassIndex = self._index or 1
            RefreshPanel()
        end)
        btn:SetPoint("TOPLEFT", 310 + ((i - 1) % 2) * 142, -162 - math.floor((i - 1) / 2) * 24)
        L.entryButtons[i] = btn
    end

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 310, -220)
    scroll:SetPoint("BOTTOMRIGHT", -26, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(300, 500)
    scroll:SetScrollChild(child)
    L.featureChild = child
end

local function RefreshLeveling()
    local L = S.leveling
    local data = GetProgression() or {}
    local race = data.race or {}
    SetDropText(L.raceDrop, race.id ~= "" and (HarfordDnDRaces and HarfordDnDRaces.GetRaceName and HarfordDnDRaces.GetRaceName(race.id) or race.id) or "Sin raza")
    RefreshSubraceDrop()
    SetDropText(L.backgroundDrop, data.background ~= "" and (HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgroundName and HarfordDnDBackgrounds.GetBackgroundName(data.background) or data.background) or "Sin trasfondo")
    SetDropText(L.featsDrop, GetFeatsLabel(data))
    L.manaCheck:SetChecked(HarfordDnDProgression.GetUseMana and HarfordDnDProgression.GetUseMana(GetProfileName()) or false)

    local entry = data.classLevels and data.classLevels[S.selectedClassIndex]
    if entry then
        S.classId = entry.classId
        S.subclassId = entry.subclassId
        L.levelBox:SetText(tostring(entry.level or 1))
    elseif not S.classId then
        local first = HarfordDnDBook and HarfordDnDBook.GetClasses and HarfordDnDBook.GetClasses()[1]
        S.classId = first and first.id or nil
        S.subclassId = S.classId and HarfordDnDBook.GetDefaultSubclassId(S.classId) or nil
        L.levelBox:SetText("1")
    end
    SetDropText(L.classDrop, S.classId and HarfordDnDBook and HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(S.classId) or "Clase")
    SetDropText(L.subclassDrop, S.classId and S.subclassId and HarfordDnDBook and HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(S.classId, S.subclassId) or "Subclase")
    UIDropDownMenu_Initialize(L.subclassDrop, function()
        local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
        if not classDef then return end
        for _, sub in ipairs(classDef.subclasses or {}) do
            local subChoice = sub
            local info = UIDropDownMenu_CreateInfo()
            info.text = subChoice.name
            if subChoice.desc and subChoice.desc ~= "" then
                info.tooltipTitle = subChoice.name
                info.tooltipText = subChoice.desc
                info.tooltipOnButton = true
            end
            info.checked = S.subclassId == subChoice.id
            info.func = function()
                S.subclassId = subChoice.id
                RefreshPanel()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local total = HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(GetProfileName()) or 0
    local pb = HarfordDnDProgression.GetProficiencyBonus and HarfordDnDProgression.GetProficiencyBonus(GetProfileName()) or nil
    local caster = HarfordDnDMana and HarfordDnDMana.GetCasterLevel and HarfordDnDMana.GetCasterLevel(GetProfileName()) or 0
    local mana = HarfordDnDMana and HarfordDnDMana.GetManaPool and HarfordDnDMana.GetManaPool(GetProfileName()) or 0
    local maxSpell = HarfordDnDMana and HarfordDnDMana.GetMaxSpellLevel and HarfordDnDMana.GetMaxSpellLevel(GetProfileName()) or 0
    L.manaInfo:SetText("Nivel total " .. tostring(total) .. " | Comp " .. (pb and Signed(pb) or "-") .. "\nLanzador " .. tostring(caster) .. " | Mana " .. tostring(mana) .. " | Espacio max " .. tostring(maxSpell))

    for i, btn in ipairs(L.entryButtons) do
        local e = data.classLevels and data.classLevels[i]
        if e and HarfordDnDBook then
            btn._index = i
            btn:SetText((HarfordDnDBook.GetClassName(e.classId) or e.classId) .. " " .. tostring(e.level or 1))
            btn:Show()
        else
            btn._index = nil
            btn:Hide()
        end
    end
    L.entryText:SetText("Entrada seleccionada: " .. tostring(S.selectedClassIndex))
    RefreshFeatureList()
end

local function CreateReputationPage()
    CreatePage("reputation")
end

local function CreateFrameIfNeeded()
    if S.frame then return end

    local f = CreateFrame("Frame", "HarfordCharacterPanelFrame", UIParent, "ButtonFrameTemplate")
    f:SetSize(NORMAL_W, NORMAL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnHide", function()
        if HarfordReputationUI and HarfordReputationUI.DetachEmbedded then
            HarfordReputationUI.DetachEmbedded(true)
        end
    end)
    f:Hide()
    S.frame = f

    if f.TitleText then
        f.TitleText:SetText(GetPanelTitle())
        S.title = f.TitleText
    else
        local title = CreateFS(f, "GameFontNormalLarge", GetPanelTitle())
        title:SetPoint("TOP", 0, -12)
        S.title = title
    end
    -- Fondo principal igual al CharacterFrame nativo (CharacterFrameBg): textura de roca
    -- TILEADA, capa BACKGROUND, con los mismos margenes del nativo (2,-21)/(-2,2).
    local fbg = f:CreateTexture(nil, "BACKGROUND", nil, -6)
    fbg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", true, true)
    if fbg.SetHorizTile then fbg:SetHorizTile(true) end
    if fbg.SetVertTile then fbg:SetVertTile(true) end
    fbg:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -21)
    fbg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    S.frameBg = fbg

    S.content = CreateFrame("Frame", nil, f)
    S.content:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -68)
    S.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -22, 30)

    local portrait = f.portrait or _G["HarfordCharacterPanelFramePortrait"]
    if not portrait then
        portrait = f:CreateTexture("HarfordCharacterPanelFramePortrait", "ARTWORK")
        portrait:SetSize(58, 58)
        portrait:SetPoint("TOPLEFT", f, "TOPLEFT", -4, 4)
    end
    S.portrait = portrait
    portrait:SetSize(58, 58)
    portrait:ClearAllPoints()
    portrait:SetPoint("TOPLEFT", f, "TOPLEFT", -4, 4)
    portrait:SetDrawLayer("ARTWORK", 2)
    if portrait.AddMaskTexture and f.CreateMaskTexture then
        local mask = f:CreateMaskTexture(nil, "ARTWORK")
        mask:SetTexture(TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(portrait)
        portrait:AddMaskTexture(mask)
        S.portraitMask = mask
    end

    local tabData = {
        { "sheet", "Personaje" },
        { "reputation", "Reputacion" },
        { "creation", "Creacion" },
        { "leveling", "Subida" },
    }
    for i, t in ipairs(tabData) do
        local key = t[1]
        S.tabs[key] = CreateNativeTab(f, i, t[2], function()
            S.activeTab = key
            RefreshPanel()
        end)
    end
    PositionTabs()

    CreateSheetPage()
    CreateCreationPage()
    CreateLevelingPage()
    CreateReputationPage()

    S.refreshers.sheet = RefreshSheet
    S.refreshers.creation = RefreshCreation
    S.refreshers.leveling = RefreshLeveling
    S.refreshers.reputation = function() end
    f:SetScript("OnShow", RefreshPanel)
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_TARGET_CHANGED"
            or unit == "player"
            or unit == "target"
        then
            RefreshPortrait()
        end
    end)
end

function API.Open(tab)
    CreateFrameIfNeeded()
    S.activeTab = tab or "sheet"
    S.frame:Show()
    RefreshPanel()
end

function API.Close()
    if HarfordReputationUI and HarfordReputationUI.DetachEmbedded then
        HarfordReputationUI.DetachEmbedded(true)
    end
    if S.frame then S.frame:Hide() end
end

function API.Toggle(tab)
    CreateFrameIfNeeded()
    if S.frame:IsShown() and (not tab or tab == S.activeTab) then
        if HarfordReputationUI and HarfordReputationUI.DetachEmbedded then
            HarfordReputationUI.DetachEmbedded(true)
        end
        S.frame:Hide()
    else
        API.Open(tab or "sheet")
    end
end

function API.Refresh()
    RefreshPanel()
end

if HarfordDebug and HarfordDebug.RegisterCommand then
    HarfordDebug.RegisterCommand("trp3build", function()
        SeedProgressionFromTRP3()
        local profile = HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetPlayerProfile("player") or nil
        local data = GetProgression() or {}
        HarfordDebug.Print("perfil: " .. GetProfileName())
        HarfordDebug.Print("clases: " .. GetClassSummary(data, " / "))
        for i, entry in ipairs(data.classLevels or {}) do
            local className = HarfordDnDBook and HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId) or entry.classId
            local classFile = GetClassFileForEntry(entry, className, className)
            local r, g, b = GetClassColorParts(entry, className, className)
            HarfordDebug.Print(string.format("  color clase %d: id=%s file=%s rgb=%.2f,%.2f,%.2f", i, tostring(entry.classId or "-"), tostring(classFile or "-"), tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0))
        end
        HarfordDebug.Print("raza: " .. GetRaceLabel(data))
        HarfordDebug.Print("trasfondo: " .. GetBackgroundLabel(data))
        if profile and HarfordTRP3.GetProfileRaceEntry then
            local race = HarfordTRP3.GetProfileRaceEntry(profile)
            HarfordDebug.Print("TRP3 raza detectada: " .. (race and ((race.raceId or "-") .. " / " .. (race.subraceId or "-")) or "NO"))
        end
        if profile and HarfordTRP3.GetProfileBackgroundId then
            local bg = HarfordTRP3.GetProfileBackgroundId(profile)
            HarfordDebug.Print("TRP3 trasfondo detectado: " .. tostring(bg or "NO"))
        end
        local rows = GetClassFeatureRows(8) or GetTRP3FeatureRows(8) or {}
        HarfordDebug.Print("rasgos visibles: " .. tostring(#rows))
        for i, row in ipairs(rows) do
            HarfordDebug.Print("  " .. tostring(i) .. ". " .. tostring(row[1] or ""))
        end
    end, "diagnostica clase/raza/trasfondo/rasgos TRP3 del panel de personaje")
end

SLASH_HARFORDCHARACTERPANEL1 = "/harfordchar"
SLASH_HARFORDCHARACTERPANEL2 = "/hchar"
SlashCmdList.HARFORDCHARACTERPANEL = function(msg)
    msg = tostring(msg or ""):lower()
    if msg == "rep" or msg == "reputacion" then
        API.Toggle("reputation")
    elseif msg == "crear" or msg == "creacion" then
        API.Toggle("creation")
    elseif msg == "subir" or msg == "clases" then
        API.Toggle("leveling")
    else
        API.Toggle("sheet")
    end
end
