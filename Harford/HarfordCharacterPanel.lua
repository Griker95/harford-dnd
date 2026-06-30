-- HarfordCharacterPanel: panel de personaje unificado.
-- No sustituye el panel de reputaciones; lo usa como modulo externo desde una
-- pestana. La primera vista siempre es la ficha/resumen del PJ.

HarfordCharacterPanel = HarfordCharacterPanel or {}

local API = HarfordCharacterPanel
-- Tamaño/offset del marco metalico del tab (SpellBook-SkillLineTab). Ajustable en vivo con
-- /harford debug run booktab w h x y para encontrar el encaje exacto sin recargar el addon.
HarfordCharacterPanel._tabSkin = HarfordCharacterPanel._tabSkin or { w = 66, h = 66, x = 0, y = 11, is = 34 }
-- Marco del icono de cada boton del Libro segun categoria, todos en Spellbook-Parts (375505,
-- 256x256): pasivo = marco marron; activo/reaccion = marcos ornamentados. tc {izq,dcha,arriba,abajo}
-- (en 0-1) y w/h (px). Ajustables en vivo en PIXELES con /harford debug run bookframe.
HarfordCharacterPanel._bookFrameTexSize = 256
-- Valores NATIVOS exactos del framedump (regiones SlotFrame / UnlearnedSlotFrame del SpellButton),
-- todas en Spellbook-Parts. ox/oy = offset de anclaje CENTER respecto al boton.
HarfordCharacterPanel._bookFrame = HarfordCharacterPanel._bookFrame or {
    pasivo   = { tc = { 0.79296875, 0.9609375, 0.00390625, 0.171875 },   w = 43, h = 43, ox = 0,   oy = 0 },
    activo   = { tc = { 0.00390625, 0.27734375, 0.44140625, 0.6953125 }, w = 70, h = 65, ox = 1.5, oy = 0 },  -- SlotFrame
    reaccion = { tc = { 0.00390625, 0.27734375, 0.703125, 0.93359375 },  w = 70, h = 59, ox = 1.5, oy = -3 }, -- UnlearnedSlotFrame
}
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
    inspectName = nil,
    inspectUnit = nil,
}

local TEX_PORTRAIT_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
-- Tamano/aspecto del CharacterFrame nativo (medido con FrameDump: Bg 536x401 + insets).
local NORMAL_W, NORMAL_H = 540, 424
local REPUTATION_W, REPUTATION_H = 390, 460
-- Pestaña Libro: tamaño EXACTO del SpellBookFrame nativo (probe). Todo se ancla al frame 1:1.
local BOOK_W, BOOK_H = 550, 525
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

-- Nombres de slot en español para los tooltips (las claves internas siguen en ingles).
local PAPERDOLL_SLOT_LABELS_ES = {
    Head = "Cabeza",
    Neck = "Cuello",
    Shoulder = "Hombros",
    Back = "Espalda",
    Chest = "Pecho",
    Shirt = "Camisa",
    Tabard = "Tabardo",
    Wrists = "Muñecas",
    Hands = "Manos",
    Waist = "Cintura",
    Legs = "Piernas",
    Feet = "Pies",
    Finger0 = "Anillo",
    Finger1 = "Anillo",
    Trinket0 = "Abalorio",
    Trinket1 = "Abalorio",
    MainHand = "Mano principal",
    SecondaryHand = "Mano secundaria",
}

local function SlotLabelES(key)
    return PAPERDOLL_SLOT_LABELS_ES[tostring(key or "")] or tostring(key or "")
end

local POINT_BUY_COST = {
    [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9,
}

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r " .. tostring(msg or ""))
    end
end

local function GetProfileName()
    if S.inspectName and S.inspectName ~= "" then
        return tostring(S.inspectName)
    end
    return tostring((UnitName and UnitName("player")) or "Personaje")
end

local function IsInspecting()
    return S.inspectName and S.inspectName ~= ""
end

local function GetInspectSnapshot()
    if not IsInspecting() then return nil end
    return HarfordCharacterInspect and HarfordCharacterInspect.GetSnapshot
        and HarfordCharacterInspect.GetSnapshot(S.inspectName)
        or nil
end

local function GetProfileValue(key, default)
    if IsInspecting() then
        local snap = GetInspectSnapshot()
        local base = snap and snap.base
        local v = base and base[key]
        if v == nil or v == "" then return default end
        return v
    end
    if HarfordDnDContext and HarfordDnDContext.Get then
        return HarfordDnDContext.Get(key, default)
    end
    return default
end

local function GetPortraitUnit()
    if IsInspecting() then
        local unit = S.inspectUnit
        if unit and UnitExists and UnitExists(unit) then return unit end
        if UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
            local targetName = HarfordClassColors.UnitFullName("target")
            local short = Ambiguate and Ambiguate(targetName or "", "short") or tostring(targetName or ""):match("^[^%-]+")
            local inspectShort = Ambiguate and Ambiguate(S.inspectName, "short") or tostring(S.inspectName):match("^[^%-]+")
            if targetName == S.inspectName or (short and inspectShort and short == inspectShort) then
                return "target"
            end
        end
        return "player"
    end
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
    if IsInspecting() then
        return "Inspeccion: " .. tostring((Ambiguate and Ambiguate(S.inspectName, "short")) or S.inspectName)
    end
    if S.activeTab == "reputation" then
        return "Reputacion"
    end
    local name = HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName("player")
    return name or GetProfileName()
end

local TAB_ORDER = { "sheet", "book", "spells", "reputation", "professions", "creation", "leveling" }

-- Pestañas OCULTAS para el despliegue (Creacion/Subida aun no listas). No se crean sus
-- botones (ver tabData) y cualquier intento de activarlas cae a "sheet". Las paginas siguen
-- construyendose para no romper refrescos; solo no son accesibles desde la UI.
local HIDDEN_TABS = { professions = true, creation = true, leveling = true }

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
    local isBook = S.activeTab == "book"
    local isSpells = S.activeTab == "spells"
    local isBookLike = isBook or isSpells  -- Habilidades y Conjuros comparten el marco de libro
    local w = isRep and REPUTATION_W or (isBookLike and BOOK_W or NORMAL_W)
    local h = isRep and REPUTATION_H or (isBookLike and BOOK_H or NORMAL_H)
    S.frame:SetSize(w, h)
    if S.content then
        S.content:ClearAllPoints()
        if isBookLike then
            -- El cuerpo lo dibujan regiones del frame con offsets nativos; el contenido solo
            -- contiene botones/nav anclados al frame, asi que cubre todo el cuerpo.
            S.content:SetPoint("TOPLEFT", S.frame, "TOPLEFT", 0, -21)
            S.content:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", 0, 0)
        else
            S.content:SetPoint("TOPLEFT", S.frame, "TOPLEFT", isRep and 18 or 14, isRep and -62 or -52)
            S.content:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", isRep and -18 or -14, isRep and 30 or 12)
        end
    end
    -- El Bg/Inset propios del ButtonFrameTemplate tapan el cuerpo nativo del libro y lo hacen
    -- parecer "incrustado"; se ocultan en las pestañas de libro para que se vea 374155 + pergamino.
    local inset = S.frame.Inset or _G["HarfordCharacterPanelFrameInset"]
    if inset then inset:SetShown(not isBookLike) end
    local tplBg = S.frame.Bg or _G["HarfordCharacterPanelFrameBg"]
    if tplBg then tplBg:SetShown(not isBookLike) end
    if S.frameBg then S.frameBg:SetShown(not isBookLike) end
    if S.book then
        if S.book.body then S.book.body:SetShown(isBook) end
        if S.book.page1 then S.book.page1:SetShown(isBook) end
        if S.book.page2 then S.book.page2:SetShown(isBook) end
    end
    if S.spellBook then
        if S.spellBook.body then S.spellBook.body:SetShown(isSpells) end
        if S.spellBook.page1 then S.spellBook.page1:SetShown(isSpells) end
        if S.spellBook.page2 then S.spellBook.page2:SetShown(isSpells) end
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
    if IsInspecting() then return end
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
    if IsInspecting() then
        local base = tonumber(GetProfileValue(key, 10)) or 10
        local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
            and HarfordDnDFeatureEffects.GetBonus("ability", key, GetProfileName())
            or 0
        return base + (tonumber(bonus) or 0)
    end
    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityScore then
        return HarfordDnDCalc.GetAbilityScore(key)
    end
    return tonumber(GetProfileValue(key, 10)) or 10
end

local function AbilityBaseAndBonus(key)
    local base = tonumber(GetProfileValue(key, 10)) or 10
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

-- Texturas exactas del CharacterFrameTab nativo (sacadas de /harford debug run probeframe).
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
    parent._harfordPool = parent._harfordPool or {}
    for _, row in ipairs(parent._harfordRows) do
        if row.ClearAllPoints then row:ClearAllPoints() end
        if row.SetScript then
            row:SetScript("OnEnter", nil)
            row:SetScript("OnLeave", nil)
        end
        if row.EnableMouse then row:EnableMouse(false) end
        row:Hide()
        local poolType = row._harfordPoolType
        if poolType then
            parent._harfordPool[poolType] = parent._harfordPool[poolType] or {}
            parent._harfordPool[poolType][#parent._harfordPool[poolType] + 1] = row
        end
    end
    wipe(parent._harfordRows)
end

local function AddDynamicRow(parent, row, poolType)
    parent._harfordRows = parent._harfordRows or {}
    if poolType then row._harfordPoolType = poolType end
    parent._harfordRows[#parent._harfordRows + 1] = row
    return row
end

local function AcquireDynamicRow(parent, poolType, createFn)
    parent._harfordPool = parent._harfordPool or {}
    local pool = parent._harfordPool[poolType]
    local row = pool and table.remove(pool) or nil
    if not row then row = createFn() end
    row._harfordPoolType = poolType
    if row.Show then row:Show() end
    return AddDynamicRow(parent, row, poolType)
end

local function AcquireDynamicFS(parent, template, text)
    template = template or "GameFontHighlightSmall"
    local fs = AcquireDynamicRow(parent, "fs:" .. template, function()
        return CreateFS(parent, template, "")
    end)
    fs:SetText(text or "")
    return fs
end

local function AcquireDynamicCheck(parent, text, onClick)
    local c = AcquireDynamicRow(parent, "check", function()
        return CreateCheck(parent, "", nil)
    end)
    if c.text then c.text:SetText(text or "") end
    c:SetChecked(false)
    c:EnableMouse(true)
    c:SetScript("OnClick", function(self)
        if onClick then onClick(self, self:GetChecked()) end
    end)
    return c
end

local function AcquireDynamicDrop(parent, width)
    local drop = AcquireDynamicRow(parent, "drop:" .. tostring(width or 130), function()
        return CreateDrop(parent, width)
    end)
    UIDropDownMenu_SetWidth(drop, width or 130)
    drop:EnableMouse(true)
    return drop
end

local function AcquireFeatureRow(parent)
    local row = AcquireDynamicRow(parent, "featureRow", function()
        local f = CreateFrame("Frame", nil, parent)
        f.name = CreateFS(f, "GameFontHighlightSmall", "")
        f.name:SetPoint("TOPLEFT", 0, -2)
        f.name:SetWidth(548)
        f.desc = CreateFS(f, "GameFontDisableSmall", "")
        f.desc:SetPoint("TOPLEFT", 0, -18)
        f.desc:SetWidth(548)
        f.desc:SetNonSpaceWrap(false)
        return f
    end)
    row:SetScript("OnEnter", nil)
    row:SetScript("OnLeave", nil)
    row:EnableMouse(false)
    return row
end

local function MakeLine(parent, text, x, y, template)
    local fs = AcquireDynamicFS(parent, template or "GameFontHighlightSmall", text)
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

local function PrettyCustomLabel(text)
    text = tostring(text or ""):gsub("[_%-%s]+", " ")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return "" end
    return (text:gsub("(%S+)", function(word)
        local lower = word:lower()
        if lower == "de" or lower == "del" or lower == "la" or lower == "las"
            or lower == "el" or lower == "los" or lower == "y" then
            return lower
        end
        return lower:gsub("^%l", string.upper)
    end):gsub("^%l", string.upper))
end

local function GetBackgroundLabel(data)
    local id = data and data.background
    if id and id ~= "" then
        if HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground then
            local bgDef = HarfordDnDBackgrounds.GetBackground(id)
            if bgDef and bgDef.name and bgDef.name ~= "" then
                return bgDef.name
            end
        end
        return PrettyCustomLabel(id)
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

-- Clasificadores de feature del Libro -> HarfordCharacterBook (modulo). Alias locales.
local IsMagicLikeFeature   = HarfordCharacterBook.IsMagicLike
local IsVisibleBookFeature = HarfordCharacterBook.IsVisible

local function FormatFeatureChoiceLabels(labels)
    if type(labels) ~= "table" or #labels == 0 then return nil end
    local out = {}
    for i, label in ipairs(labels) do
        if i > 1 then
            out[#out + 1] = " |cff888888|||r "
        end
        out[#out + 1] = "|cff00ffff" .. tostring(label) .. "|r"
    end
    return table.concat(out)
end

local function GetFeatureChoiceSummary(feature, profileName)
    if not (feature and feature.choice and HarfordDnDProgression and HarfordDnDProgression.GetChoice
        and HarfordDnDBook and HarfordDnDBook.GetChoiceOption) then
        return nil
    end
    local chosen = HarfordDnDProgression.GetChoice(feature.id, profileName)
    if type(chosen) ~= "table" or #chosen == 0 then return nil end
    local labels = {}
    for _, optionId in ipairs(chosen) do
        local opt = HarfordDnDBook.GetChoiceOption(feature, optionId)
        local label = opt and tostring(opt.label or opt.id or "") or tostring(optionId or "")
        label = label:gsub("%s*%b()%s*$", "")
        label = label:gsub("^%s+", ""):gsub("%s+$", "")
        if label ~= "" then labels[#labels + 1] = label end
    end
    return FormatFeatureChoiceLabels(labels)
end

local function GetFeatureChoiceDisplay(feature, profileName)
    if not (feature and feature.choice) then return nil end
    local summary = GetFeatureChoiceSummary(feature, profileName)
    if summary and summary ~= "" then
        return summary, false
    end
    return "pendiente", true
end

local function AddFeatureChoiceTooltip(feature, profileName, tooltip)
    local choiceText, pending = GetFeatureChoiceDisplay(feature, profileName)
    if not choiceText then return tooltip end
    tooltip = tostring(tooltip or "")
    local line = "Eleccion: " .. choiceText
    if pending and HarfordDnDBook and HarfordDnDBook.GetChoiceOptions then
        local opts = {}
        for _, opt in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
            local label = tostring(opt.label or opt.id or "")
            label = label:gsub("%s*%b()%s*$", "")
            label = label:gsub("^%s+", ""):gsub("%s+$", "")
            if label ~= "" then opts[#opts + 1] = label end
        end
        if #opts > 0 then
            line = line .. "\nOpciones: " .. table.concat(opts, ", ")
        end
    end
    return tooltip ~= "" and (tooltip .. "\n\n" .. line) or line
end

local GetClassFileForEntry, GetClassColorParts

local function GetClassFeatureRows(limit)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures) then
        return nil
    end
    local profileName = GetProfileName()
    local unlocked = HarfordDnDProgression.GetUnlockedFeatures(profileName)
    if type(unlocked) ~= "table" then return nil end
    local rows = {}
    limit = tonumber(limit) or 5
    local data = GetProgression() or {}
    for _, entry in ipairs(data.classLevels or {}) do
        local subName = HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(entry.classId, entry.subclassId) or ""
        local level = tonumber(entry.level) or 0
        local unlockLevel = HarfordDnDBook.GetSubclassUnlockLevel and HarfordDnDBook.GetSubclassUnlockLevel(entry.classId) or 1
        if subName ~= "" and level >= (tonumber(unlockLevel) or 1) then
            local className = HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId) or entry.classId
            local titleClass = tostring(className)
            local _, _, _, hex = GetClassColorParts and GetClassColorParts(entry, className, className)
            if hex then
                titleClass = "|cff" .. hex .. titleClass .. "|r"
            end
            local title = "Subclase " .. titleClass .. ": " .. tostring(subName)
            local subDef = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
            rows[#rows + 1] = { title, "", title, subDef and tostring(subDef.desc or "") or "" }
            if #rows >= limit then return rows end
        end
    end
    for _, item in ipairs(unlocked) do
        local feature = item and item.feature
        if feature and feature.name and IsVisibleBookFeature(feature) and not IsMagicLikeFeature(feature) then
            local name = tostring(feature.name)
            local choiceSummary = GetFeatureChoiceDisplay(feature, profileName)
            local value = choiceSummary or ""
            local tooltip = AddFeatureChoiceTooltip(feature, profileName, tostring(feature.description or item.className or ""))
            rows[#rows + 1] = {
                name,
                value,
                name,
                tooltip,
            }
            if #rows >= limit then break end
        end
    end
    return #rows > 0 and rows or nil
end

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

local function RefreshPanel()
    if not S.frame or not S.frame:IsShown() then return end
    if HIDDEN_TABS[S.activeTab] then S.activeTab = "sheet" end  -- Creacion/Subida ocultas
    if IsInspecting() and S.activeTab ~= "sheet" then
        S.activeTab = "sheet"
    end
    -- Siembra TRP3 retirada del refresco automatico: la carga desde TRP3 es exclusiva del
    -- comando `/harford cargarficha`. Abrir el panel ya no auto-rellena clase/raza/trasfondo.
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
        if key == "creation" or key == "leveling" or key == "reputation" or key == "professions" then
            local enabled = not IsInspecting()
            if button.SetEnabled then button:SetEnabled(enabled) end
            button:SetAlpha(enabled and 1 or 0.45)
        end
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
            local texture = nil
            local equipped = HarfordDnDItems and HarfordDnDItems.ResolveSlot
                and HarfordDnDItems.ResolveSlot(slot.harfordSlotKey or slot.slotToken, GetProfileName())
            if equipped and equipped.icon then
                texture = equipped.icon
            else
                local basicInfo
                if HarfordDnDItems and HarfordDnDItems.GetBasicWeaponInfo then
                    basicInfo = HarfordDnDItems.GetBasicWeaponInfo(slot.harfordSlotKey or slot.slotToken, GetProfileName())
                end
                if not basicInfo and HarfordDnDItems and HarfordDnDItems.GetBasicArmorInfo then
                    basicInfo = HarfordDnDItems.GetBasicArmorInfo(slot.harfordSlotKey or slot.slotToken, GetProfileName())
                end
                texture = basicInfo and basicInfo.icon or slot.emptyTexture
                if slot.slotToken and GetInventorySlotInfo then
                    local _, nativeTexture = GetInventorySlotInfo(slot.slotToken)
                    if not basicInfo then texture = nativeTexture or texture end
                end
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
    if IsInspecting() then
        local snap = GetInspectSnapshot()
        local resources = snap and snap.resources
        if not resources and HarfordDnDResources and HarfordDnDResources.RemoteCache then
            resources = HarfordDnDResources.RemoteCache[GetProfileName()]
        end
        return tonumber(resources and resources[suffixKey] or 0) or 0
    end
    return tonumber(GetProfileValue(suffixKey, 0)) or 0
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

-- texCoords EXACTOS del PaperDollSidebarTabs nativo (sacados de /harford debug run probeframe).
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
-- /harford debug run probeframe CharacterFrame y FrameDump.lua, no de ajustes a ojo.
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
        b.harfordSlotKey = key
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
        local function makeBasicSelector()
            local isWeaponSlot = key == "MainHand" or key == "SecondaryHand"
            local isArmorSlot = key == "Chest"
            if not (isWeaponSlot or isArmorSlot) then return end
            local arrow = CreateFrame("Button", nil, b)
            arrow:SetSize(14, 14)
            arrow:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
            arrow:SetFrameLevel((b:GetFrameLevel() or 1) + 5)
            local up = arrow:CreateTexture(nil, "ARTWORK")
            up:SetAllPoints(arrow)
            up:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
            arrow:SetNormalTexture(up)
            local hi = arrow:CreateTexture(nil, "OVERLAY")
            hi:SetAllPoints(arrow)
            hi:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Highlight")
            arrow:SetHighlightTexture(hi)
            local drop = CreateFrame("Frame", nil, arrow, "UIDropDownMenuTemplate")
            drop:SetPoint("TOPLEFT", arrow, "BOTTOMLEFT", -16, 0)
            local function refreshAfterChoice()
                RefreshGameUI()
                RefreshPanel()
                CloseDropDownMenus()
            end
            UIDropDownMenu_Initialize(drop, function(_, level, menuList)
                if IsInspecting() then return end
                level = level or 1
                if isArmorSlot then
                    local groups = HarfordDnDItems and HarfordDnDItems.GetArmorMenuGroups
                        and HarfordDnDItems.GetArmorMenuGroups() or {}
                    local currentArmor = HarfordDnDItems and HarfordDnDItems.GetBasicArmor
                        and HarfordDnDItems.GetBasicArmor(key, GetProfileName())
                    if level == 1 then
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = "Sin armadura (CA 10 + Des)"
                        info.checked = not currentArmor or currentArmor == "none"
                        info.func = function()
                            if HarfordDnDItems and HarfordDnDItems.SetBasicArmor then
                                HarfordDnDItems.SetBasicArmor(key, nil, GetProfileName())
                            end
                            refreshAfterChoice()
                        end
                        UIDropDownMenu_AddButton(info, level)
                        for _, group in ipairs(groups) do
                            if #(group.items or {}) > 0 then
                                info = UIDropDownMenu_CreateInfo()
                                info.text = group.text or group.key
                                info.hasArrow = true
                                info.notCheckable = true
                                info.menuList = group.key
                                UIDropDownMenu_AddButton(info, level)
                            end
                        end
                    elseif level == 2 then
                        for _, group in ipairs(groups) do
                            if group.key == menuList then
                                for _, armor in ipairs(group.items or {}) do
                                    local armorKey = armor.key
                                    local info = UIDropDownMenu_CreateInfo()
                                    info.text = armor.label .. " (CA " .. tostring(armor.caText or armor.base or 10) .. ")"
                                    info.checked = currentArmor == armorKey
                                    info.func = function()
                                        if HarfordDnDItems and HarfordDnDItems.SetBasicArmor then
                                            HarfordDnDItems.SetBasicArmor(key, armorKey, GetProfileName())
                                        end
                                        refreshAfterChoice()
                                    end
                                    UIDropDownMenu_AddButton(info, level)
                                end
                                return
                            end
                        end
                    end
                    return
                end
                local groups = HarfordDnDWeapons and HarfordDnDWeapons.GetWeaponMenuGroups and HarfordDnDWeapons.GetWeaponMenuGroups() or {}
                -- Filtro por mano: principal sin escudo; secundaria solo armas a 1 mano
                -- (sin armas a dos manos; escudo si). Desarmado nunca se ofrece (sin item
                -- ni arma basica ya cuenta como Desarmado).
                local offhand = (key == "SecondaryHand")
                local mainhand = (key == "MainHand")
                local function isTwoHanded(weapon)
                    for _, p in ipairs(weapon.props or {}) do
                        if tostring(p) == "Dos manos" then return true end
                    end
                    return false
                end
                local function isAllowed(weapon)
                    if weapon.key == "Desarmado" then return false end
                    local isShield = (weapon.key == "Escudo")
                    if mainhand and isShield then return false end
                    -- Mano secundaria: solo se excluyen armas a DOS MANOS (las de una mano,
                    -- incluidas a distancia como Pistola o Ballesta de mano, si valen).
                    if offhand and not isShield and isTwoHanded(weapon) then return false end
                    return true
                end
                local function groupHasAllowed(group)
                    for _, weapon in ipairs(group.items or {}) do
                        if isAllowed(weapon) then return true end
                    end
                    return false
                end
                if level == 1 then
                    local clear = UIDropDownMenu_CreateInfo()
                    clear.text = "Sin arma basica"
                    clear.notCheckable = true
                    clear.func = function()
                        if HarfordDnDItems and HarfordDnDItems.SetBasicWeapon then
                            HarfordDnDItems.SetBasicWeapon(key, nil, GetProfileName())
                        end
                        refreshAfterChoice()
                    end
                    UIDropDownMenu_AddButton(clear, level)
                    for _, group in ipairs(groups) do
                        if groupHasAllowed(group) then
                            local info = UIDropDownMenu_CreateInfo()
                            info.text = group.text or group.key
                            info.hasArrow = true
                            info.notCheckable = true
                            info.menuList = group.key
                            UIDropDownMenu_AddButton(info, level)
                        end
                    end
                elseif level == 2 then
                    for _, group in ipairs(groups) do
                        if group.key == menuList then
                            for _, weapon in ipairs(group.items or {}) do
                                local weaponKey = weapon.key
                                if isAllowed(weapon) then
                                local info = UIDropDownMenu_CreateInfo()
                                info.text = weaponKey
                                info.checked = HarfordDnDItems and HarfordDnDItems.GetBasicWeapon and HarfordDnDItems.GetBasicWeapon(key, GetProfileName()) == weaponKey
                                info.func = function()
                                    if HarfordDnDItems and HarfordDnDItems.SetBasicWeapon then
                                        HarfordDnDItems.SetBasicWeapon(key, weaponKey, GetProfileName())
                                    end
                                    refreshAfterChoice()
                                end
                                UIDropDownMenu_AddButton(info, level)
                                end
                            end
                            return
                        end
                    end
                end
            end, "MENU")
            arrow:SetScript("OnClick", function(self)
                if IsInspecting() then return end
                ToggleDropDownMenu(1, nil, drop, self, 0, 0)
            end)
            arrow:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(isArmorSlot and "Armadura basica" or "Arma basica", 1, 0.82, 0, true)
                GameTooltip:AddLine("Se usa solo si no hay un objeto equipado en este slot.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            arrow:SetScript("OnLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
            b.basicSelector = arrow
        end
        makeBasicSelector()
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
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:RegisterForDrag("LeftButton")
        local function equipFromCursor()
            if IsInspecting() then return false end
            if not (HarfordDnDItems and HarfordDnDItems.EquipSlot and GetCursorInfo) then return false end
            local cursorType, itemId, itemLink = GetCursorInfo()
            if cursorType ~= "item" then return false end
            itemLink = itemLink or (itemId and select(2, GetItemInfo(itemId)))
            if not itemLink or itemLink == "" then return false end
            -- Solo se permite equipar objetos que correspondan a este slot.
            local itemName, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
            if itemName and not (HarfordDnDItems.CanEquipInSlot and HarfordDnDItems.CanEquipInSlot(equipLoc, key)) then
                Print("Ese objeto no va en el slot " .. SlotLabelES(key) .. ".")
                return false
            end
            HarfordDnDItems.EquipSlot(key, itemLink, GetProfileName())
            if ClearCursor then ClearCursor() end
            RefreshGameUI()
            RefreshPanel()
            return true
        end
        b:SetScript("OnReceiveDrag", equipFromCursor)
        b:SetScript("OnClick", function(self, button)
            -- Shift+click en un objeto equipado (no basico): linkearlo en el chat como un
            -- objeto normal. Funciona tambien en inspeccion (solo comparte el link).
            local slotEntry = HarfordDnDItems and HarfordDnDItems.GetSlot and HarfordDnDItems.GetSlot(key, GetProfileName())
            if slotEntry and slotEntry.itemLink and slotEntry.itemLink ~= ""
                and ((IsModifiedClick and IsModifiedClick("CHATLINK")) or (IsShiftKeyDown and IsShiftKeyDown()))
            then
                if ChatEdit_InsertLink then ChatEdit_InsertLink(slotEntry.itemLink) end
                return
            end
            if IsInspecting() then return end
            if button == "RightButton" or (IsAltKeyDown and IsAltKeyDown()) then
                if HarfordDnDItems and HarfordDnDItems.UnequipSlot then
                    HarfordDnDItems.UnequipSlot(key, GetProfileName())
                    RefreshGameUI()
                    RefreshPanel()
                end
                return
            end
            equipFromCursor()
        end)
        b:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            local entry = HarfordDnDItems and HarfordDnDItems.GetSlot and HarfordDnDItems.GetSlot(key, GetProfileName())
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            -- Solo SetHyperlink con un link de objeto REAL (contiene "|H..."). Las armas/armaduras
            -- basicas no tienen itemLink (solo una clave); pasarlas a SetHyperlink lanza
            -- "Unknown link type". El pcall protege ademas de items custom de Epsilon no cacheados.
            local linkShown = false
            if entry and entry.itemLink and tostring(entry.itemLink):find("|H", 1, true) then
                linkShown = pcall(GameTooltip.SetHyperlink, GameTooltip, entry.itemLink)
            end
            if linkShown then
                local basicLabel = HarfordDnDItems and HarfordDnDItems.GetSlotBasicLabel and HarfordDnDItems.GetSlotBasicLabel(key, GetProfileName())
                if basicLabel then
                    GameTooltip:AddLine("Basico guardado: " .. tostring(basicLabel) .. " (ignorado por el objeto equipado)", 0.7, 0.7, 0.7, true)
                end
                if not IsInspecting() then
                    GameTooltip:AddLine("Click derecho para desequipar", 0.4, 1, 0.4, true)
                end
            else
                GameTooltip:SetText(SlotLabelES(key), 1, 0.82, 0, true)
                if IsInspecting() then
                    GameTooltip:AddLine("Sin objeto informado en el snapshot remoto.", 1, 1, 1, true)
                else
                    GameTooltip:AddLine("Arrastra un objeto aqui para equiparlo en la ficha Harford.", 1, 1, 1, true)
                    local basicLabel = HarfordDnDItems and HarfordDnDItems.GetSlotBasicLabel and HarfordDnDItems.GetSlotBasicLabel(key, GetProfileName())
                    if basicLabel then
                        GameTooltip:AddLine("Basico activo: " .. tostring(basicLabel), 0.3, 1, 0.3, true)
                    end
                end
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
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
    SH.modelDark = sceneDark
    model:SetScript("OnShow", function(self) if self.SetUnit then self:SetUnit(GetPortraitUnit()) end end)
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

    -- Zona scrollable de "Rasgos" (vista resumen): la scrollbar nativa
    -- aparece sola cuando los rasgos desbordan el alto del area.
    local featScroll = CreateFrame("ScrollFrame", "HarfordCharPanelFeatScroll", statsPane, "UIPanelScrollFrameTemplate")
    featScroll:SetPoint("TOPLEFT", statsPane, "TOPLEFT", 14, -240)
    featScroll:SetPoint("BOTTOMRIGHT", statsPane, "BOTTOMRIGHT", -26, 8)
    local featChild = CreateFrame("Frame", nil, featScroll)
    featChild:SetSize(150, 10)
    featScroll:SetScrollChild(featChild)
    featScroll:Hide()
    SH.featScroll = featScroll
    SH.featChild = featChild
    SH.featRows = {}

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
    if opts and opts.labelTop then
        row.l:SetPoint("TOPLEFT", row.f, "TOPLEFT", 0, 0)
        if row.l.SetJustifyV then row.l:SetJustifyV("TOP") end
    else
        row.l:SetPoint("LEFT", row.f, "LEFT", 0, 0)
        if row.l.SetJustifyV then row.l:SetJustifyV("MIDDLE") end
    end
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
    if row.abilityScoreText then row.abilityScoreText:Hide() end
    if row.abilityModText then row.abilityModText:Hide() end
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

local function SetAbilitySheetRow(row, y, label, score, mod, tooltipTitle, tooltipText)
    SetSheetRow(row, y, label, "", tooltipTitle, tooltipText, { tooltip = { nativeAbility = true } })
    if not row then return 14 end
    row.v:Hide()
    if not row.abilityScoreText then
        row.abilityScoreText = row.f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.abilityScoreText:SetJustifyH("RIGHT")
    end
    if not row.abilityModText then
        row.abilityModText = row.f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.abilityModText:SetJustifyH("RIGHT")
    end
    row.abilityScoreText:ClearAllPoints()
    row.abilityScoreText:SetPoint("RIGHT", row.f, "RIGHT", -28, 0)
    row.abilityScoreText:SetWidth(24)
    row.abilityScoreText:SetText("|cffffffff" .. tostring(score or 0) .. "|r")
    row.abilityScoreText:Show()

    row.abilityModText:ClearAllPoints()
    row.abilityModText:SetPoint("RIGHT", row.f, "RIGHT", 0, 0)
    row.abilityModText:SetWidth(24)
    row.abilityModText:SetText(ColorSigned(mod))
    row.abilityModText:Show()
    return row.f:GetHeight() or 14
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
    row.l:ClearAllPoints()
    row.l:SetPoint("TOPLEFT", row.f, "TOPLEFT", 0, 0)
    if row.l.SetJustifyV then row.l:SetJustifyV("TOP") end
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
    if IsInspecting() then
        local name = GetProfileName()
        local pb = HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus
            and HarfordDnDProgression.GetProficiencyBonus(name)
            or tonumber(GetProfileValue("BonusCompetencia", 2)) or 2
        local profFlag = tonumber(GetProfileValue("Hab_" .. skill.id .. "_Prof", 0)) or 0
        local expFlag = tonumber(GetProfileValue("Hab_" .. skill.id .. "_Exp", 0)) or 0
        local featureRank = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetSkillRank
            and HarfordDnDFeatureEffects.GetSkillRank(skill.id, name)
            or 0
        local prof = 0
        if expFlag == 1 or featureRank >= 2 then
            prof = 2 * pb
        elseif profFlag == 1 or featureRank >= 1 then
            prof = pb
        end
        local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
            and HarfordDnDFeatureEffects.GetBonus("skill", skill.id, name)
            or 0
        return AbilityMod(AbilityScore(skill.ability)) + (tonumber(bonus) or 0) + prof
    end
    if HarfordDnDCalc and HarfordDnDCalc.GetSkillRollBonuses then
        local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)
        return (tonumber(base) or 0) + (tonumber(prof) or 0)
    end
    return AbilityMod(AbilityScore(skill.ability))
end

local function SaveTotal(abilityKey)
    if IsInspecting() then
        local name = GetProfileName()
        local pb = HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus
            and HarfordDnDProgression.GetProficiencyBonus(name)
            or tonumber(GetProfileValue("BonusCompetencia", 2)) or 2
        local prof = tonumber(GetProfileValue("Salv_" .. abilityKey, 0)) == 1
            or (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasSaveProf
                and HarfordDnDFeatureEffects.HasSaveProf(abilityKey, name) == true)
        local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
            and HarfordDnDFeatureEffects.GetBonus("save", abilityKey, name)
            or 0
        if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetAllSavesAbilities then
            for _, entry in ipairs(HarfordDnDFeatureEffects.GetAllSavesAbilities(name)) do
                local mod = AbilityMod(AbilityScore(entry.ability))
                local minVal = tonumber(entry.min) or 0
                bonus = bonus + math.max(minVal, mod)
            end
        end
        return AbilityMod(AbilityScore(abilityKey)) + (tonumber(bonus) or 0) + (prof and pb or 0)
    end
    if HarfordDnDCalc and HarfordDnDCalc.GetSaveRollBonuses then
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(abilityKey)
        return (tonumber(base) or 0) + (tonumber(prof) or 0)
    end
    return AbilityMod(AbilityScore(abilityKey))
end

-- Pinta los rasgos en el area scrollable (vista resumen). Cada fila muestra el nombre
-- del rasgo con su descripcion en tooltip. El alto del child decide si sale scrollbar.
local function SetFeatureScroll(rows)
    local SH = S.sheet
    if not (SH and SH.featChild and SH.featScroll) then return end
    rows = rows or {}
    SH.featRows = SH.featRows or {}
    local lineH = 15
    for i, r in ipairs(rows) do
        local row = SH.featRows[i]
        if not row then
            row = CreateFrame("Button", nil, SH.featChild)
            row:SetHeight(lineH)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetJustifyH("LEFT")
            row.text:SetTextColor(1, 0.82, 0)
            if row.text.SetWordWrap then row.text:SetWordWrap(false) end
            if row.text.SetNonSpaceWrap then row.text:SetNonSpaceWrap(false) end
            row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.value:SetJustifyH("RIGHT")
            row.value:SetTextColor(1, 1, 1)
            if row.value.SetWordWrap then row.value:SetWordWrap(false) end
            if row.value.SetNonSpaceWrap then row.value:SetNonSpaceWrap(false) end
            SH.featRows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", SH.featChild, "TOPLEFT", 0, -(i - 1) * lineH)
        row:SetPoint("RIGHT", SH.featChild, "RIGHT", -2, 0)
        row.text:ClearAllPoints()
        row.value:ClearAllPoints()
        local value = tostring(r[2] or "")
        local valueWidth = (value ~= "") and 62 or 0
        row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -valueWidth - 4, 0)
        row.text:SetText(tostring(r[1] or ""))
        row.text:SetTextColor(1, 0.82, 0)
        row.value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row.value:SetWidth(valueWidth)
        row.value:SetText(value)
        row.value:SetShown(value ~= "")
        row:SetScript("OnClick", nil)
        local tipTitle, tipText = r[3] or r[1], r[4]
        row:SetScript("OnEnter", function(self)
            if GameTooltip and tipTitle then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tostring(tipTitle), 1, 0.82, 0, true)
                if tipText and tipText ~= "" then GameTooltip:AddLine(tostring(tipText), 1, 1, 1, true) end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        row:Show()
    end
    for i = #rows + 1, #SH.featRows do SH.featRows[i]:Hide() end
    SH.featChild:SetWidth(math.max(1, (SH.featScroll:GetWidth() or 150) - 18))
    SH.featChild:SetHeight(math.max(1, #rows * lineH + 2))
end

local function RefreshSheet()
    local SH = S.sheet
    if not SH then return end
    if SH.featScroll then SH.featScroll:Hide() end  -- solo se muestra en la vista resumen
    local name = GetProfileName()
    local data = GetProgression()
    local total = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(name) or 0

    RefreshSubtitleClasses(SH, data)
    if SH.model and SH.model.SetUnit then SH.model:SetUnit(GetPortraitUnit()) end
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
    -- Mismo calculo que HarfordDnDCalc.GetInitiativeBonus pero por perfil mostrado (soporta inspect):
    -- + Mod. de caracteristicas que suman a iniciativa (Alacridad/Reflejos/Instintos) y + PB (Afinidad Aire).
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetInitiativeAbilities then
        for _, ability in ipairs(HarfordDnDFeatureEffects.GetInitiativeAbilities(name)) do
            initBonus = initBonus + AbilityMod(AbilityScore(ability))
        end
    end
    if pb and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("initiativeProfBonus", name) then
        initBonus = initBonus + pb
    end
    local manualCA = tonumber(GetProfileValue("ArmorClass", 10)) or 10
    local itemCA = HarfordDnDItems and HarfordDnDItems.GetEquippedArmorClass and HarfordDnDItems.GetEquippedArmorClass(name) or nil
    local featCA = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus and HarfordDnDFeatureEffects.GetBonus("armorClass", nil, name)) or 0
    local ca = math.floor(math.max(manualCA, tonumber(itemCA) or 0) + featCA)
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
            bgTipTitle, bgTipText = (bd and bd.name) or GetBackgroundLabel(data), txt
        elseif data and data.background and data.background ~= "" then
            bgTipTitle = GetBackgroundLabel(data)
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
        if HarfordDnDConditions and HarfordDnDConditions.GetActive then
            local conditionRef = IsInspecting() and S.inspectUnit or "player"
            if conditionRef then
                local labels = {}
                for _, active in ipairs(HarfordDnDConditions.GetActive(conditionRef)) do
                    labels[#labels + 1] = active.definition.label
                end
                if #labels > 0 then
                    rows[#rows + 1] = { "Estados", table.concat(labels, ", "), "Estados activos", table.concat(labels, "\n") }
                end
            end
        end
        if HarfordDnDHitDice and HarfordDnDHitDice.GetTotalMax and HarfordDnDHitDice.GetTotalMax(name) > 0 then
            rows[#rows + 1] = { "Dados de Golpe", HarfordDnDHitDice.GetSummaryText(name) }
        end
        if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetToolProfs then
            local tools = HarfordDnDFeatureEffects.GetToolProfs(name)
            if tools and #tools > 0 then
                rows[#rows + 1] = { "Herramientas", table.concat(tools, ", ") }
            end
        end
        if HarfordDnDMana and HarfordDnDProgression and HarfordDnDProgression.GetUseMana
            and HarfordDnDProgression.GetUseMana(name) then
            local pool = HarfordDnDMana.GetManaPool and HarfordDnDMana.GetManaPool(name) or 0
            -- La variante ya esta ON por defecto; la fila solo tiene sentido para lanzadores
            -- (pool > 0), si no un no-lanzador mostraria "Mana: 0".
            if pool > 0 then
                local ms = HarfordDnDMana.GetMaxSpellLevel and HarfordDnDMana.GetMaxSpellLevel(name) or 0
                rows[#rows + 1] = { "Mana", tostring(pool) .. "  (esp. " .. tostring(ms) .. ")" }
            end
        end
        local y = -50
        for i, r in ipairs(rows) do
            if r[1] == "Clase" then
                y = y - SetClassSheetRow(SH.sheetRows[i], y, data)
            else
                local opts = r[1] == "Trasfondo" and { wrapValue = true, labelTop = true, labelWidth = 70, valueWidth = 104 } or nil
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
            SetAbilitySheetRow(SH.sheetRows[i], -107 - (i - 1) * 15, abil.key,
                score,
                mod,
                AbilityTooltipTitle(abil.key),
                ABILITY_TOOLTIP_TEXT[abil.key] or "")
        end
        SetSheetBar(SH.combatBar, "Rasgos", -206, true)
        -- Lista completa de rasgos (sin tope de 5) en el area scrollable: la scrollbar
        -- aparece sola al desbordar. Las filas fijas sobrantes se ocultan.
        local featureRows = GetClassFeatureRows(100) or GetTRP3FeatureRows(100) or {
            { "Raza", GetRaceLabel(data), "Raza", GetRaceLabel(data) },
            { "Trasfondo", GetBackgroundLabel(data), "Trasfondo", GetBackgroundLabel(data) },
            { "Dotes", GetFeatsLabel(data), "Dotes", GetFeatsLabel(data) },
            { "Competencia", pb and Signed(pb) or "-", "Competencia", "Bonificador por competencia actual." },
            { "Puntos de Golpe", hpMax > 0 and (tostring(hpCur) .. " / " .. tostring(hpMax)) or "-", "Puntos de Golpe", "Salud actual / maxima." },
        }
        for i = 7, #SH.sheetRows do
            if SH.sheetRows[i] and SH.sheetRows[i].f then SH.sheetRows[i].f:Hide() end
        end
        SetFeatureScroll(featureRows)
        if SH.featScroll then SH.featScroll:Show() end
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
    local states = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetToggleStates
        and HarfordDnDFeatureEffects.GetToggleStates(GetProfileName())
        or {}
    if #states > 0 then
        MakeLine(child, "Estados activables", 0, y, "GameFontNormal")
        y = y - 22
        for _, state in ipairs(states) do
            local stateId = state.id
            local chk = AcquireDynamicCheck(child, state.label or stateId, function(_, checked)
                HarfordDnDProgression.SetToggleState(stateId, checked, GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end)
            chk:SetPoint("TOPLEFT", 0, y)
            chk:SetChecked(HarfordDnDProgression.IsToggleStateActive
                and HarfordDnDProgression.IsToggleStateActive(stateId, GetProfileName()) or false)
            if chk.text then chk.text:SetWidth(250) end
            if state.description and state.description ~= "" then
                chk:SetScript("OnEnter", function(self)
                    TooltipLines(self, state.label or stateId, state.description)
                end)
                chk:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            y = y - 26
        end
        y = y - 8
    end
    local features = HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures and HarfordDnDProgression.GetUnlockedFeatures(GetProfileName()) or {}
    if #features == 0 then
        MakeLine(child, "Aun no hay rasgos desbloqueados.", 0, y, "GameFontDisableSmall")
        child:SetHeight(80)
        return
    end
    for _, item in ipairs(features) do
        local feature = item.feature
        if feature then
            local row = AcquireFeatureRow(child)
            row:SetPoint("TOPLEFT", 0, y)
            row:SetSize(600, 36)

            -- Indicador de "sin mecanizar" + su motivo (clases/razas/dotes/trasfondos).
            local noMech = HarfordDnDBook and HarfordDnDBook.GetUnmechanizedReason
                and HarfordDnDBook.GetUnmechanizedReason(feature) or nil
            local nameText = (feature.name or feature.id or "Rasgo") .. " |cff888888" .. tostring(item.className or "") .. "|r"
            if noMech then nameText = nameText .. "  |cff8a6d3b(sin mecanizar)|r" end

            row.name:SetText(nameText)
            row.desc:SetText(feature.description or "")
            y = y - 40

            if noMech then
                row:EnableMouse(true)
                row:SetScript("OnEnter", function(self)
                    TooltipLines(self, feature.name or "Rasgo",
                        (feature.description or "") .. "\n\n|cff8a6d3bSin mecanizar:|r " .. noMech)
                end)
                row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            end

            if feature.choice and HarfordDnDBook and HarfordDnDBook.GetChoiceSlots then
                local chosen = HarfordDnDProgression.GetChoice and HarfordDnDProgression.GetChoice(feature.id, GetProfileName()) or {}
                for slot = 1, HarfordDnDBook.GetChoiceSlots(feature) do
                    local slotNo = slot
                    local drop = AcquireDynamicDrop(child, 210)
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

local function CreateProfessionsPage()
    local page = CreatePage("professions")
    local title = CreateFS(page, "GameFontNormalLarge", "Profesiones")
    title:SetPoint("TOPLEFT", 16, -8)
    local info = CreateFS(page, "GameFontHighlight", "Sistema de profesiones (proximamente).")
    info:SetPoint("TOPLEFT", 16, -40)
    info:SetWidth(380)
    info:SetJustifyH("LEFT")
    S.professions = { page = page, title = title, info = info }
end

local function RefreshProfessions()
    -- Placeholder: el sistema de profesiones aun no tiene datos.
end

-- ===========================================================================
-- Pestaña LIBRO: libro de habilidades con look spellbook VANILLA. Lista los rasgos
-- del personaje por seccion (General / Clase N / Subclase N) con icono + nombre + nivel.
-- Comportamiento por click: pasivo = nada (tooltip), activo = anuncia en chat con enlace
-- propio + ejecuta su mecanica, reaccion = toggle (vacio por ahora). Texturas vanilla.
-- ===========================================================================
local BOOK_COLS, BOOK_ROWS = 2, 6
local BOOK_PER_PAGE = BOOK_COLS * BOOK_ROWS
-- Clasificacion y datos de presentacion del Libro -> extraidos a HarfordCharacterBook (modulo
-- puro, sin `S`). Alias locales para no tocar los call-sites de la UI del Libro de abajo.
local BOOK_ICON               = HarfordCharacterBook.ICON
local FeatureCondDamageId     = HarfordCharacterBook.CondDamageId
local BookCategory            = HarfordCharacterBook.Category
local REACTION_TRIGGER_TEXT   = HarfordCharacterBook.REACTION_TRIGGER_TEXT
local FeatureReactionTrigger  = HarfordCharacterBook.ReactionTrigger
local FeatureReactionEffect   = HarfordCharacterBook.ReactionEffect

-- Construye las secciones (pestañas laterales) del libro para el perfil actual.
-- Busca un rasgo por id en TODOS los libros (clase/subclase/raza/trasfondo/dote) para
-- resolver el enlace clicable de habilidad en cualquier cliente con Harford.
local function ResolveBookFeatureById(id)
    id = tostring(id or "")
    if id == "" then return nil end
    if HarfordDnDRaces and HarfordDnDRaces.GetTrait then local t = HarfordDnDRaces.GetTrait(id); if t then return t end end
    if HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetTrait then local t = HarfordDnDBackgrounds.GetTrait(id); if t then return t end end
    if HarfordDnDFeats and HarfordDnDFeats.GetTrait then local t = HarfordDnDFeats.GetTrait(id); if t then return t end end
    -- En el libro de clases/subclases: casa por id O por nombre (el enlace puede llevar el nombre
    -- como id cuando el rasgo no tiene id propio).
    if HarfordDnDBook and HarfordDnDBook.GetClasses then
        for _, c in ipairs(HarfordDnDBook.GetClasses()) do
            for _, f in ipairs(c.features or {}) do if f.id == id or f.name == id then return f end end
            for _, s in ipairs(c.subclasses or {}) do
                for _, f in ipairs(s.features or {}) do if f.id == id or f.name == id then return f end end
            end
        end
    end
    return nil
end

-- Enlace de chat clicable propio para una habilidad: |Hharford:abil:<id>|h[Nombre]|h.
local function AbilityChatLink(feature)
    local id = feature and (feature.id or feature.name) or "?"
    local nm = (feature and feature.name) or "?"
    return "|cff66bbff|Hharford:abil:" .. tostring(id) .. "|h[" .. nm .. "]|h|r"
end

local RefreshBook   -- forward (los handlers lo llaman)
local RefreshSpells  -- forward (pestaña Conjuros)

local function GetFeatureUseState(feature)
    if not (feature and feature.uses and HarfordDnDFeatureUses and HarfordDnDFeatureUses.GetTracked) then
        return nil
    end
    local id = feature.id
    if not id then return nil end
    for _, tracked in ipairs(HarfordDnDFeatureUses.GetTracked(GetProfileName()) or {}) do
        if tracked.featureId == id then
            return tracked
        end
    end
    return nil
end

local function FeatureUseAvailable(feature)
    if not (feature and feature.uses) then return true end
    local tracked = GetFeatureUseState(feature)
    if not tracked then return true end
    return (tonumber(tracked.available) or 0) > 0
end

local function FeatureRechargeText(recharge)
    return (recharge == "short") and "Descanso corto" or "Descanso largo"
end

local function WarnFeatureWithoutUses(feature)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r No quedan usos de " .. tostring(feature and feature.name or "este rasgo") .. ".")
    end
end

-- Click en rasgo ACTIVO: anuncia su uso a la mesa con enlace clicable y, si es de uso
-- limitado, gasta un uso. (La mecanica de recurso/daño activable vive en la seccion Ataque.)
local function AnnounceAbility(feature)
    if not feature then return false end
    if feature.uses and not FeatureUseAvailable(feature) then
        WarnFeatureWithoutUses(feature)
        return false
    end
    -- Enlace clicable real via TRP3 ChatLinks (los enlaces de tipo propio no son clicables en
    -- este cliente). Cae a texto de color si TRP3 no esta disponible.
    local link = (HarfordTRP3 and HarfordTRP3.GetAbilityChatLink and HarfordTRP3.GetAbilityChatLink(feature))
        or AbilityChatLink(feature)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info", label = "usa " .. link })
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r usa " .. link)
    end
    if feature.uses and HarfordDnDFeatureUses and HarfordDnDFeatureUses.Spend and not IsInspecting() then
        HarfordDnDFeatureUses.Spend(feature.id, GetProfileName())
        if RefreshBook then RefreshBook() end
    end
    return true
end

-- Colores/label de categoria -> HarfordCharacterBook (modulo). Alias locales.
local BOOK_CAT_COLOR    = HarfordCharacterBook.CAT_COLOR
local BookCategoryLabel = HarfordCharacterBook.CategoryLabel

local function BookButtonOnEnter(self)
    if not (self.feature and GameTooltip) then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.feature.name or "?", 1, 1, 1, true)
    local cat = BookCategory(self.feature)
    -- Cabecera igual que el subtexto del boton: solo "<Categoria>  ·  Nivel N" (sin pista de click).
    local catTxt = BookCategoryLabel(cat, self.feature)
    if self.featLevel and self.featLevel > 0 then catTxt = catTxt .. "  ·  Nivel " .. self.featLevel end
    local col = BOOK_CAT_COLOR[cat] or { 0.6, 0.8, 1 }
    GameTooltip:AddLine(catTxt, col[1], col[2], col[3])
    local useState = GetFeatureUseState(self.feature)
    if useState then
        local r, g, b = 0.8, 0.8, 0.8
        if (tonumber(useState.available) or 0) <= 0 then r, g, b = 1, 0.25, 0.25 end
        GameTooltip:AddLine("Usos: " .. tostring(useState.available or 0) .. "/" .. tostring(useState.max or 0) .. " (" .. FeatureRechargeText(useState.recharge) .. ")", r, g, b)
    end
    local choiceText, pendingChoice = GetFeatureChoiceDisplay(self.feature, GetProfileName())
    if choiceText then
        local r, g, b = pendingChoice and 1 or 0.8, pendingChoice and 0.25 or 0.8, pendingChoice and 0.25 or 0.8
        GameTooltip:AddLine("Eleccion: " .. choiceText, r, g, b)
    end
    if cat == "reaccion" then
        local trigger = FeatureReactionTrigger(self.feature)
        if trigger then
            GameTooltip:AddLine("Disparador: " .. (REACTION_TRIGGER_TEXT[trigger] or trigger), 0.8, 0.8, 0.8)
        end
    end
    -- Para rasgos de eleccion resueltos, la descripcion es la de la OPCION elegida (p.ej. el
    -- estilo de combate concreto), no la generica "Adoptas un estilo...".
    local descText = self.feature.description
    if self.feature.choice and HarfordDnDProgression and HarfordDnDProgression.GetChoice
        and HarfordDnDBook and HarfordDnDBook.GetChoiceOptionDesc then
        local chosen = HarfordDnDProgression.GetChoice(self.feature.id, GetProfileName())
        if type(chosen) == "table" then
            for _, optId in ipairs(chosen) do
                local d = HarfordDnDBook.GetChoiceOptionDesc(self.feature, optId)
                if d then descText = d; break end
            end
        end
    end
    if descText and descText ~= "" then
        GameTooltip:AddLine(descText, 0.9, 0.9, 0.9, true)
    end
    GameTooltip:Show()
end

local function BookButtonOnClick(self)
    if not self.feature then return end
    local cat = BookCategory(self.feature)
    if cat ~= "pasivo" and HarfordDnDConditions and HarfordDnDConditions.CanPerform then
        local actionType = cat == "reaccion" and "reaction" or "action"
        local allowed, condition = HarfordDnDConditions.CanPerform(actionType, { actorUnit = "player", targetUnit = "target" })
        if not allowed then
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r No puedes usar esa habilidad: " .. tostring(condition or "condicion activa") .. ".")
            end
            return
        end
    end
    if cat == "area" then
        if self.feature.uses and not FeatureUseAvailable(self.feature) then
            WarnFeatureWithoutUses(self.feature)
            return
        end
        local definition, err
        if HarfordDnDArea and HarfordDnDArea.DefinitionFromFeature then
            definition, err = HarfordDnDArea.DefinitionFromFeature(self.feature)
        end
        if not definition then
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r " .. tostring(err or "Definicion de area incompleta."))
            end
            return
        end
        HarfordDnDArea.Open(definition, {
            sourceKind = "player",
            sourceGuid = UnitGUID and UnitGUID("player") or nil,
            onCommit = function()
                if self.feature.uses and not FeatureUseAvailable(self.feature) then return false, "No quedan usos." end
                local resourceKey, resourceCost = definition.resourceKey, tonumber(definition.resourceCost) or 0
                if resourceKey ~= "" and resourceCost > 0 then
                    if not (HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.AdjustResourceCurrent) then
                        return false, "Sistema de recursos no disponible."
                    end
                    if HarfordDnDStore.GetResourceCurrent(resourceKey) < resourceCost then
                        return false, "No hay recurso suficiente."
                    end
                end
                if self.feature.uses and HarfordDnDFeatureUses and HarfordDnDFeatureUses.Spend
                    and not HarfordDnDFeatureUses.Spend(self.feature.id, GetProfileName()) then
                    return false, "No quedan usos."
                end
                if resourceKey ~= "" and resourceCost > 0 then HarfordDnDStore.AdjustResourceCurrent(resourceKey, -resourceCost) end
                if RefreshBook then RefreshBook() end
                return true
            end,
        })
    elseif cat == "al_accion" then
        if self.feature.uses and not FeatureUseAvailable(self.feature) then
            WarnFeatureWithoutUses(self.feature)
            return
        end
        -- Preparar el daño condicional (mismo estado que el menu "Daño extra"): el ataque de la
        -- ficha lo consume. Las de NIVEL (Golpe Runico, Golpe del Cruzado…) abren un DROPDOWN para
        -- elegir la cantidad/nivel; las simples se togglean on/off directo.
        local cdId = FeatureCondDamageId(self.feature)
        if cdId and HarfordDnDStore and HarfordDnDStore.OpenConditionalDamageMenu then
            HarfordDnDStore.OpenConditionalDamageMenu(cdId, self)
        end
        if RefreshBook then RefreshBook() end
    elseif cat == "maniobra" then
        -- Ejecuta la maniobra contra el objetivo: las de cantidad variable (levelCost, p.ej.
        -- Espiral de la Muerte) abren dropdown; las simples se resuelven directo. Gasta el
        -- recurso y resuelve salvacion/ataque/daño.
        if HarfordDnDStore and HarfordDnDStore.OpenEnergyManeuverMenu then
            HarfordDnDStore.OpenEnergyManeuverMenu(self.feature, self)
        elseif HarfordDnDStore and HarfordDnDStore.UseEnergyManeuver then
            HarfordDnDStore.UseEnergyManeuver(self.feature)
        end
        if RefreshBook then RefreshBook() end
    elseif cat == "activo" then
        AnnounceAbility(self.feature)
        for _, effect in ipairs(self.feature.effects or {}) do
            if effect.kind == "applyCondition" and effect.condition and HarfordDnDConditions
                and HarfordDnDConditions.ApplyToUnit then
                local unit = effect.target == "self" and "player" or "target"
                local ok, err = HarfordDnDConditions.ApplyToUnit(unit, effect.condition, {
                    duration = effect.duration or "manual", turns = effect.turns,
                    saveAbility = effect.saveAbility, saveDC = effect.saveDC,
                    sourceGuid = UnitGUID and UnitGUID("player") or "",
                    sourceName = HarfordClassColors.UnitFullName("player"),
                    persist = effect.persist == true,
                })
                if not ok and DEFAULT_CHAT_FRAME then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff[Harford]|r " .. tostring(err or "No se pudo aplicar el estado."))
                end
            end
        end
    elseif cat == "reaccion" then
        -- Toggle por id de rasgo (persiste aunque RefreshBook reconstruya los botones). Se queda
        -- activa hasta volver a clicarla o hasta que empiece tu turno (HarfordTurns la limpia).
        local id = self.feature.id or self.feature.name
        if id then
            S.activeReactions = S.activeReactions or {}
            if S.activeReactions[id] then
                S.activeReactions[id] = nil
            elseif FeatureUseAvailable(self.feature) then
                S.activeReactions[id] = {
                    trigger = FeatureReactionTrigger(self.feature),
                }
            else
                WarnFeatureWithoutUses(self.feature)
            end
        end
        if RefreshBook then RefreshBook() end
    end
    -- pasivo: nada
end

-- Geometria EXACTA del SpellBookFrame nativo (probe de GRIKER), 1:1. El panel del Libro usa el
-- tamaño nativo (550x525) y TODO se ancla al frame con los offsets literales del probe.
local function RollReactionDice(expr)
    local count, sides = tostring(expr or ""):match("^(%d*)d(%d+)$")
    count = tonumber(count ~= "" and count or "1") or 0
    sides = tonumber(sides) or 0
    if count <= 0 or sides <= 0 then return 0 end

    local total = 0
    for _ = 1, count do
        if HarfordDnDCalc and HarfordDnDCalc.RollDie then
            total = total + HarfordDnDCalc.RollDie(sides)
        else
            total = total + math.random(1, sides)
        end
    end
    return total
end

local function ReactionFlatBonus(feature)
    local flat = feature and feature.reactionFlat
    if flat == "half_level" then
        local lvl = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(GetProfileName()) or 0
        return math.floor((tonumber(lvl) or 0) / 2)
    end
    return tonumber(flat) or 0
end

local function ApplyReactionEffect(feature, damage, context)
    damage = math.max(0, math.floor(tonumber(damage) or 0))
    if damage <= 0 then return damage end

    local effect = FeatureReactionEffect(feature)
    if effect == "half_damage" then
        return math.max(0, math.floor(damage / 2))
    elseif effect == "reduce_damage_roll" then
        local reduction = RollReactionDice(feature.reactionDice) + ReactionFlatBonus(feature)
        return math.max(0, damage - reduction)
    end
    return nil
end

function API.TriggerPreparedReaction(trigger, context)
    trigger = tostring(trigger or "")
    context = context or {}
    local damage = tonumber(context.damage) or 0
    if HarfordDnDConditions and HarfordDnDConditions.CanPerform then
        local allowed = HarfordDnDConditions.CanPerform("reaction", { actorUnit = "player" })
        if not allowed then return damage, false end
    end
    if trigger == "" or not (S.activeReactions and next(S.activeReactions)) then
        return damage, false
    end

    for id in pairs(S.activeReactions) do
        local feature = ResolveBookFeatureById(id)
        if feature and FeatureReactionTrigger(feature) == trigger and FeatureUseAvailable(feature) then
            local newDamage = ApplyReactionEffect(feature, damage, context)
            if newDamage ~= nil then
                S.activeReactions[id] = nil
                AnnounceAbility(feature)
                if RefreshBook then RefreshBook() end
                return newDamage, true, feature
            end
        end
    end
    return damage, false
end

local BOOK_BTN = 37                 -- SpellButton 37x37
local BOOK_COL_X = { 100, 325 }     -- columnas izq/der (SpellButton1 x=100, +225)
local BOOK_ROW_Y0, BOOK_ROW_PITCH = -72, 66  -- primera fila (SpellButton1 y=-72) y pitch

local function CreateBookPage()
    local page = CreatePage("book")

    -- Contenedor transparente (controla la visibilidad). Los botones se anclan al FRAME con
    -- offsets nativos; el fondo/pergamino son REGIONES del frame para que el retrato quede encima.
    local area = CreateFrame("Frame", nil, page)
    area:SetAllPoints(page)

    -- Fondo oscuro: 374155 es la roca de fondo. Rellena TODO el frame por detras para que nunca
    -- asome un hueco gris/transparente bajo el borde ni donde el pergamino no llegue.
    local body = S.frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    body:SetTexture(374155)
    body:SetTexCoord(0, 0.533203125, 0, 0.4902344048)
    body:SetAllPoints(S.frame)
    body:Hide()

    -- Cuerpo del libro: Spellbook-Page-1 (375503) trae el pergamino, la cinta turquesa, las
    -- esquinas doradas y los bordes de madera. Cubre el interior a ras (deja sitio al cierre dcho).
    local lpage = S.frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    lpage:SetTexture("Interface\\Spellbook\\Spellbook-Page-1")
    lpage:SetTexCoord(0, 1, 0, 1)
    lpage:SetPoint("TOPLEFT", S.frame, "TOPLEFT", 0, -25)
    lpage:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -31, -15)
    lpage:Hide()

    -- Cierre lateral derecho: Spellbook-Page-2 (375504), tira vertical pegada al borde derecho
    -- de Page-1.
    local rpage = S.frame:CreateTexture(nil, "BACKGROUND", nil, -5)
    rpage:SetTexture("Interface\\Spellbook\\Spellbook-Page-2")
    rpage:SetTexCoord(0, 1, 0, 1)
    rpage:SetPoint("TOPLEFT", lpage, "TOPRIGHT", 0, 0)
    rpage:SetPoint("BOTTOMLEFT", lpage, "BOTTOMRIGHT", 0, 0)
    rpage:SetWidth(41)
    rpage:Hide()

    -- Partes nativas del SpellButton (sprite sheet Spellbook-Parts, textureFileID 375505) con
    -- los texCoord literales del probe. El boton es 37x37 (solo el icono) como el nativo; el
    -- nombre y la barra son regiones que se extienden a la derecha. Anclados al FRAME (offsets nativos).
    local PARTS = "Interface\\Spellbook\\Spellbook-Parts"
    local buttons = {}
    for i = 1, BOOK_PER_PAGE do
        local b = CreateFrame("Button", nil, area)
        b:SetSize(BOOK_BTN, BOOK_BTN)
        -- Relleno column-major como el nativo: botones 1..6 columna izquierda (arriba->abajo),
        -- 7..12 columna derecha. RefreshBook llena buttons[i] en orden.
        local col = (i <= BOOK_ROWS) and 0 or 1
        local row = (i <= BOOK_ROWS) and (i - 1) or (i - 1 - BOOK_ROWS)
        b:SetPoint("TOPLEFT", S.frame, "TOPLEFT", BOOK_COL_X[col + 1], BOOK_ROW_Y0 - row * BOOK_ROW_PITCH)

        -- ════════════════════════════════════════════════════════════════════════════════
        -- LAYOUT DEL BOTON DEL LIBRO. Todo cuelga del boton `b` (= el icono 37x37). Cada parte
        -- tiene su offset respecto a `b`; mover el boton (constantes BOOK_COL_X / BOOK_ROW_Y0 /
        -- BOOK_ROW_PITCH, arriba) mueve TODO. `bar2`→`bar` y `sub`→`name` van encadenados.
        -- ════════════════════════════════════════════════════════════════════════════════

        -- ── MARCO (ring) ──────────────────────────────────────────────────────────────────
        -- OJO: el TAMAÑO y RECORTE del marco NO se editan aqui; los pone RefreshBook desde la
        -- tabla HarfordCharacterPanel._bookFrame (pasivo/activo/reaccion → tc, w, h) o en vivo con
        -- /harford debug run bookframe. Aqui SOLO se edita su POSICION (los dos ultimos numeros):
        b.ring = b:CreateTexture(nil, "BACKGROUND")
        b.ring:SetTexture(PARTS)
        b.ring:SetTexCoord(0.79296875, 0.9609375, 0.00390625, 0.171875)
        b.ring:SetSize(43, 43)
        b.ring:SetPoint("CENTER", b, "CENTER", 0, 0)   -- POSICION del marco (x, y) respecto al centro del icono

        -- ── BARRA / SOMBRA del nombre ─────────────────────────────────────────────────────
        b.bar = b:CreateTexture(nil, "BACKGROUND")
        b.bar:SetTexture(PARTS)
        b.bar:SetTexCoord(0.3125, 0.96484375, 0.37109375, 0.5234375)
        b.bar:SetSize(167, 39)                         -- TAMAÑO de la barra (ancho, alto)
        -- Posicion NATIVA: el nativo ancla la sombra a Background(marco 43) TOPRIGHT (-4,-5);
        -- como nuestro marco varia de tamaño, la fijamos al boton en el punto equivalente (36,-2).
        b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 36, -2)
        b.bar2 = b:CreateTexture(nil, "BACKGROUND")    -- segunda copia (intensidad); copia a bar, no tocar
        b.bar2:SetTexture(PARTS)
        b.bar2:SetTexCoord(0.3125, 0.96484375, 0.37109375, 0.5234375)
        b.bar2:SetAllPoints(b.bar)

        -- ── ICONO ─────────────────────────────────────────────────────────────────────────
        -- Por defecto llena el boton (37x37). Para cambiar su tamaño/posicion independiente,
        -- sustituye SetAllPoints(b) por  b.icon:SetSize(W,H)  y  b.icon:SetPoint("CENTER", b, "CENTER", x, y)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b); b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

        -- ── NOMBRE y SUBTEXTO ──────────────────────────────────────────────────────────────
        b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")  -- fuente (dorado+sombra). Cambiable con :SetFont(...)
        b.name:SetPoint("LEFT", b, "RIGHT", 8, 4)      -- POSICION del nombre (x, y) desde el lado derecho del icono
        b.name:SetWidth(145); b.name:SetJustifyH("LEFT")
        b.sub = b:CreateFontString(nil, "ARTWORK")
        b.sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")  -- TAMAÑO + contorno negro para leerse sobre el pergamino
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -1)  -- POSICION del subtexto respecto al nombre
        b.sub:SetWidth(145); b.sub:SetJustifyH("LEFT")
        b.sub:SetTextColor(0.25, 0.12, 0)

        -- ── HIGHLIGHT de REACCION ACTIVA ───────────────────────────────────────────────────
        -- TrainSlotFrame (sunburst sobre el icono) + TrainTextBackground (glow hacia la derecha),
        -- ambos de Spellbook-Parts con sus anclajes nativos. Visibles solo con la reaccion preparada.
        b.rxSlot = b:CreateTexture(nil, "OVERLAY", nil, -1)
        b.rxSlot:SetTexture(PARTS)
        b.rxSlot:SetTexCoord(0.00390625, 0.3046875, 0.00390625, 0.43359375)
        b.rxSlot:SetSize(77, 110)
        b.rxSlot:SetPoint("TOPLEFT", b, "TOPLEFT", -35, 35)
        b.rxSlot:Hide()
        b.rxGlow = b:CreateTexture(nil, "BACKGROUND", nil, 1)
        b.rxGlow:SetTexture(PARTS)
        b.rxGlow:SetTexCoord(0.3125, 0.78515625, 0.00390625, 0.36328125)
        b.rxGlow:SetSize(121, 92)
        b.rxGlow:SetPoint("TOPLEFT", b.rxSlot, "TOPRIGHT", 0, -12)
        b.rxGlow:Hide()

        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnEnter", BookButtonOnEnter)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        b:SetScript("OnClick", BookButtonOnClick)
        b:Hide()
        buttons[i] = b
    end

    -- Navegacion de pagina anclada al FRAME, como el nativo (Prev -66 / Next -31 / texto -110, y=26).
    local nxt = CreateFrame("Button", nil, area)
    nxt:SetSize(32, 32); nxt:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -31, 26)
    nxt:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nxt:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nxt:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nxt:SetScript("OnClick", function() S.book.pageNum = S.book.pageNum + 1; RefreshBook() end)

    local prev = CreateFrame("Button", nil, area)
    prev:SetSize(32, 32); prev:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -66, 26)
    prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prev:SetScript("OnClick", function() S.book.pageNum = math.max(1, S.book.pageNum - 1); RefreshBook() end)

    local pageText = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -110, 38)

    S.book = { page = page, area = area, body = body, page1 = lpage, page2 = rpage,
               buttons = buttons, sideTabs = {}, prev = prev, nxt = nxt, pageText = pageText,
               section = 1, pageNum = 1 }
end

-- classId de Harford -> token de clase en ingles para el icono classicon_<token>.
local CLASS_ICON_TOKEN = {
    caballero_muerte = "deathknight",
    cazador_demonios = "demonhunter",
    druida           = "druid",
    cazador          = "hunter",
    mago             = "mage",
    monje            = "monk",
    paladin          = "paladin",
    sacerdote        = "priest",
    picaro           = "rogue",
    chaman           = "shaman",
    brujo            = "warlock",
    guerrero         = "warrior",
}
local BOOK_GENERAL_ICON = "Interface\\Icons\\INV_Misc_Book_09"

-- Icono de la pestaña: General = libro fijo; clase/subclase = classicon_<clase>.
local function SectionIcon(sec)
    if sec and sec.isGeneral then return BOOK_GENERAL_ICON end
    if sec and sec.classId then
        local token = CLASS_ICON_TOKEN[sec.classId]
        if token then return "Interface\\Icons\\classicon_" .. token end
    end
    return BOOK_GENERAL_ICON
end

local function BookSideTabOnEnter(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(self._label or "?", 1, 0.82, 0, true)
    GameTooltip:Show()
end

RefreshBook = function()
    if not (S.book and S.book.page) then return end
    local sections = HarfordCharacterBook.BuildSections(GetProgression())
    if S.book.section > #sections or S.book.section < 1 then S.book.section = 1 end

    -- Pestañas laterales (skill-line tabs nativas), apiladas verticalmente a la derecha.
    for i, sec in ipairs(sections) do
        local tab = S.book.sideTabs[i]
        if not tab then
            -- Hija de la pagina (se oculta con ella) pero anclada al FRAME para colgar fuera del
            -- borde derecho, igual que las SpellBookSkillLineTab nativas (32x32 + marco metalico).
            tab = CreateFrame("Button", nil, S.book.page)
            tab:SetSize(32, 32)
            -- Cuelgan POR FUERA del borde derecho (nativo: SideTabsFrame=frame, tab1 en TOPRIGHT
            -- 0,-36; pitch 49). x=-2 para solapar minimamente el borde como el nativo.
            tab:SetPoint("TOPLEFT", S.frame, "TOPRIGHT", -2, -36 - (i - 1) * 49)
            -- Marco del tab: SpellBook-SkillLineTab POR DEBAJO del icono (como el nativo). Tamaño y
            -- offset ajustables en vivo con /harford debug run booktab (BookTabSkin guarda los valores).
            local ts = HarfordCharacterPanel._tabSkin
            tab.skin = tab:CreateTexture(nil, "BACKGROUND")
            tab.skin:SetTexture("Interface\\Spellbook\\SpellBook-SkillLineTab")
            tab.skin:SetSize(ts.w, ts.h)
            tab.skin:SetPoint("TOPLEFT", tab, "TOPLEFT", ts.x, ts.y)
            -- Icono del tab. ▼▼▼ EDITA AQUI tamaño y posicion del icono ▼▼▼
            tab.icon = tab:CreateTexture(nil, "ARTWORK", nil, 0)
            tab.icon:SetSize(32, 32)                          -- TAMAÑO del icono (ancho, alto)
            tab.icon:SetPoint("CENTER", tab, "CENTER", 3, -1)  -- POSICION (x, y) respecto al centro del tab
            tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            -- ▲▲▲ EDITA AQUI ▲▲▲
            -- Marco metalico del icono (GuildSpellbooktabIconFrame), ENCIMA del icono como el nativo
            -- (region [3] del probe: ARTWORK 2, 32x32 sobre el icono). Era lo que faltaba.
            tab.iconFrame = tab:CreateTexture(nil, "ARTWORK", nil, 2)
            tab.iconFrame:SetTexture("Interface\\Spellbook\\GuildSpellbooktabIconFrame")
            tab.iconFrame:SetAllPoints(tab.icon)
            -- Resaltado de seleccion y highlight de hover anclados al ICONO (no al tab) para que
            -- coincidan exactamente con la parte visible.
            tab.checked = tab:CreateTexture(nil, "OVERLAY")
            tab.checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            tab.checked:SetBlendMode("ADD"); tab.checked:SetAllPoints(tab.icon)
            tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            local hl = tab:GetHighlightTexture()
            if hl then hl:ClearAllPoints(); hl:SetAllPoints(tab.icon) end
            tab:SetScript("OnEnter", BookSideTabOnEnter)
            tab:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            tab:SetScript("OnClick", function(self) S.book.section = self._idx; S.book.pageNum = 1; RefreshBook() end)
            S.book.sideTabs[i] = tab
        end
        tab._idx = i
        tab._label = sec.label or sec.short
        tab.icon:SetTexture(SectionIcon(sec))
        local on = (i == S.book.section)
        -- Como el nativo: iconos de pestaña siempre a todo color; el activo lleva glow.
        tab.icon:SetDesaturated(false)
        tab.icon:SetVertexColor(1, 1, 1, 1)
        tab.checked:SetShown(on)
        tab:Show()
    end
    for i = #sections + 1, #S.book.sideTabs do S.book.sideTabs[i]:Hide() end

    -- Contenido de la seccion activa, paginado.
    local sec = sections[S.book.section] or { features = {} }
    local feats = sec.features or {}
    local pages = math.max(1, math.ceil(#feats / BOOK_PER_PAGE))
    if S.book.pageNum > pages then S.book.pageNum = pages end
    if S.book.pageNum < 1 then S.book.pageNum = 1 end
    local startI = (S.book.pageNum - 1) * BOOK_PER_PAGE
    for i = 1, BOOK_PER_PAGE do
        local b = S.book.buttons[i]
        local item = feats[startI + i]
        if item and item.feature then
            b.feature, b.featLevel, b.source = item.feature, item.level, item.source
            local cat = BookCategory(item.feature)
            local realIcon = HarfordDnDData and HarfordDnDData.GetIcon and HarfordDnDData.GetIcon(item.feature.name)
            b.icon:SetTexture(realIcon or BOOK_ICON[cat] or BOOK_ICON.pasivo)
            b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            b.icon:Show()
            -- Marco: pasivo (marron, detras); activo/al_accion (SlotFrame ENCIMA); reaccion (UnlearnedSlotFrame).
            local frameKey = (cat == "al_accion" or cat == "maniobra") and "activo" or cat
            local fr = HarfordCharacterPanel._bookFrame[frameKey] or HarfordCharacterPanel._bookFrame.pasivo
            b.ring:SetTexCoord(fr.tc[1], fr.tc[2], fr.tc[3], fr.tc[4])
            b.ring:SetSize(fr.w, fr.h)
            b.ring:ClearAllPoints()
            b.ring:SetPoint("CENTER", b, "CENTER", fr.ox or 0, fr.oy or 0)
            b.ring:SetDrawLayer(cat == "pasivo" and "BACKGROUND" or "OVERLAY")
            b.ring:SetAlpha(1); b.bar:SetAlpha(1)
            b.name:SetText(item.feature.name or "?")
            -- Estado del daño condicional (al_accion) y de reaccion.
            local cdId = (cat == "al_accion") and FeatureCondDamageId(item.feature) or nil
            local cdActive = cdId and HarfordDnDStore and HarfordDnDStore.IsConditionalDamageActive
                and HarfordDnDStore.IsConditionalDamageActive(cdId)
            local rfid = item.feature.id or item.feature.name
            local reactionOn = (cat == "reaccion") and S.activeReactions and rfid and S.activeReactions[rfid] and true or false
            -- Subtexto: SIEMPRE muestra la categoria explicita (Pasiva/Activa/Reacción/Al atacar),
            -- el nivel del rasgo y el estado preparado (con cantidad para Golpe Runico, etc.).
            local catTxt = BookCategoryLabel(cat, item.feature)
            local sub = (item.level and item.level > 0) and (catTxt .. "  ·  Nivel " .. item.level) or catTxt
            if cat == "al_accion" and cdActive then
                local lvl = HarfordDnDStore.GetConditionalDamageActiveLevel and HarfordDnDStore.GetConditionalDamageActiveLevel(cdId)
                sub = sub .. ((lvl and lvl > 1) and ("  ·  Preparado x" .. lvl) or "  ·  Preparado")
            elseif reactionOn then
                sub = sub .. "  ·  Preparada"
            end
            local choiceText, pendingChoice = GetFeatureChoiceDisplay(item.feature, GetProfileName())
            if choiceText then
                sub = sub .. "  -  Eleccion: " .. choiceText
            end
            local useState = GetFeatureUseState(item.feature)
            if useState then
                sub = sub .. "  ·  Usos " .. tostring(useState.available or 0) .. "/" .. tostring(useState.max or 0)
                    .. "  ·  " .. FeatureRechargeText(useState.recharge)
            end
            b.sub:SetText(sub)
            local col = BOOK_CAT_COLOR[cat] or { 0.82, 0.82, 0.82 }
            if pendingChoice then
                b.sub:SetTextColor(1, 0.25, 0.25)
            elseif useState and (tonumber(useState.available) or 0) <= 0 then
                b.sub:SetTextColor(1, 0.25, 0.25)
            else
                b.sub:SetTextColor(col[1], col[2], col[3])
            end
            -- Highlight "preparado": reaccion activa o daño condicional activo.
            local rxOn = reactionOn or (cat == "al_accion" and cdActive and true or false)
            b.rxSlot:SetShown(rxOn); b.rxGlow:SetShown(rxOn)
            b:EnableMouse(true)   -- con habilidad: responde a hover/click
            b:Show()
        else
            -- Slot vacio: como el nativo, mismo marco pasivo + barras pero SIN icono.
            b.feature = nil
            b.icon:Hide()
            local frP = HarfordCharacterPanel._bookFrame.pasivo
            b.ring:SetTexCoord(frP.tc[1], frP.tc[2], frP.tc[3], frP.tc[4])
            b.ring:SetSize(frP.w, frP.h)
            b.ring:ClearAllPoints()
            b.ring:SetPoint("CENTER", b, "CENTER", frP.ox or 0, frP.oy or 0)
            b.ring:SetDrawLayer("BACKGROUND")
            b.name:SetText(""); b.sub:SetText("")
            b.ring:SetAlpha(1); b.bar:SetAlpha(1)
            b.rxSlot:Hide(); b.rxGlow:Hide()
            b:EnableMouse(false)  -- slot vacio: sin hover/click
            b:Show()
        end
    end
    S.book.pageText:SetText("Pagina " .. S.book.pageNum)
    if S.book.pageNum > 1 then S.book.prev:Enable() else S.book.prev:Disable() end
    if S.book.pageNum < pages then S.book.nxt:Enable() else S.book.nxt:Disable() end
end

-- ════════════════════════════════════════════════════════════════════════════════════════
-- PESTAÑA CONJUROS: replica del libro de hechizos nativo, poblada por el compendio
-- (HarfordCompendioAPI). Reutiliza la misma maquinaria visual que el Libro de Habilidades.
-- ════════════════════════════════════════════════════════════════════════════════════════

-- Texturas del libro de Conjuros. PUNTO UNICO para cambiarlas: por ahora identicas a las de
-- Habilidades, pero separadas para poder divergir luego sin tocar el Libro de Habilidades.
local SPELLS_SKIN = {
    body   = 374155,
    bodyTC = { 0, 0.533203125, 0, 0.4902344048 },
    page1  = "Interface\\Spellbook\\Spellbook-Page-1",
    page2  = "Interface\\Spellbook\\Spellbook-Page-2",
    parts  = "Interface\\Spellbook\\Spellbook-Parts",
}

local function CompendioAPI()
    return _G.HarfordCompendioAPI
end

local function SpellLevelText(level)
    level = tonumber(level) or 0
    return level <= 0 and "Truco" or ("Nivel " .. level)
end

-- Dimensiones del dropdown unico de filtros secundarios (las claves coinciden con FilterSpells).
local SPELL_FILTER_DIMS = {
    { key = "school",      label = "Escuela" },
    { key = "className",   label = "Clase" },
    { key = "category",    label = "Categoria" },
    { key = "affinity",    label = "Afinidad" },
    { key = "sourceGroup", label = "Fuente" },
}

-- Valores distintos por dimension, derivados de los datos del compendio (cache por referencia).
local spellFilterValues, spellFilterValuesSource
local function CollectSpellFilterValues()
    local api = CompendioAPI()
    local all = (api and api.GetAllSpells and api.GetAllSpells()) or {}
    if spellFilterValues and spellFilterValuesSource == all then return spellFilterValues end
    local sets = { school = {}, className = {}, category = {}, affinity = {}, sourceGroup = {} }
    for _, sp in ipairs(all) do
        if sp.school and sp.school ~= "" then sets.school[sp.school] = true end
        if sp.affinity and sp.affinity ~= "" then sets.affinity[sp.affinity] = true end
        if sp.sourceGroup and sp.sourceGroup ~= "" then sets.sourceGroup[sp.sourceGroup] = true end
        for _, c in ipairs(sp.classes or {}) do sets.className[c] = true end
        for _, c in ipairs(sp.categories or {}) do sets.category[c] = true end
    end
    local out = {}
    for dim, set in pairs(sets) do
        local list = {}
        for v in pairs(set) do list[#list + 1] = v end
        table.sort(list)
        out[dim] = list
    end
    spellFilterValues, spellFilterValuesSource = out, all
    return out
end

-- Init del dropdown unico de filtros: nivel 1 = una entrada por dimension (con submenu) +
-- "Limpiar"; nivel 2 = "Todas" + los valores distintos de esa dimension.
local function SpellFilterMenu_Init(_, level)
    local sb = S.spellBook
    if not sb then return end
    level = level or 1
    if level == 1 then
        local title = UIDropDownMenu_CreateInfo()
        title.text, title.isTitle, title.notCheckable = "Filtros", true, true
        UIDropDownMenu_AddButton(title, level)
        for _, dim in ipairs(SPELL_FILTER_DIMS) do
            local info = UIDropDownMenu_CreateInfo()
            local cur = sb.filters[dim.key]
            info.text = (cur and cur ~= "Todas") and (dim.label .. ": " .. cur) or dim.label
            info.notCheckable, info.hasArrow, info.value = true, true, dim.key
            UIDropDownMenu_AddButton(info, level)
        end
        local clear = UIDropDownMenu_CreateInfo()
        clear.text, clear.notCheckable = "Limpiar filtros", true
        clear.func = function() wipe(sb.filters); sb.pageNum = 1; CloseDropDownMenus(); RefreshSpells() end
        UIDropDownMenu_AddButton(clear, level)
    elseif level == 2 then
        local dimKey = UIDROPDOWNMENU_MENU_VALUE
        local all = UIDropDownMenu_CreateInfo()
        all.text = "Todas"
        all.checked = (sb.filters[dimKey] == nil or sb.filters[dimKey] == "Todas")
        all.func = function() sb.filters[dimKey] = nil; sb.pageNum = 1; CloseDropDownMenus(); RefreshSpells() end
        UIDropDownMenu_AddButton(all, level)
        for _, v in ipairs(CollectSpellFilterValues()[dimKey] or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = v, (sb.filters[dimKey] == v)
            info.func = function() sb.filters[dimKey] = v; sb.pageNum = 1; CloseDropDownMenus(); RefreshSpells() end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

local function CreateSpellsPage()
    local page = CreatePage("spells")
    local area = CreateFrame("Frame", nil, page)
    area:SetAllPoints(page)

    -- Fondo + pergamino como regiones del FRAME (igual que el Libro de Habilidades).
    local body = S.frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    body:SetTexture(SPELLS_SKIN.body)
    body:SetTexCoord(unpack(SPELLS_SKIN.bodyTC))
    body:SetAllPoints(S.frame)
    body:Hide()
    local lpage = S.frame:CreateTexture(nil, "BACKGROUND", nil, -6)
    lpage:SetTexture(SPELLS_SKIN.page1)
    lpage:SetPoint("TOPLEFT", S.frame, "TOPLEFT", 0, -25)
    lpage:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -31, -15)
    lpage:Hide()
    local rpage = S.frame:CreateTexture(nil, "BACKGROUND", nil, -5)
    rpage:SetTexture(SPELLS_SKIN.page2)
    rpage:SetPoint("TOPLEFT", lpage, "TOPRIGHT", 0, 0)
    rpage:SetPoint("BOTTOMLEFT", lpage, "BOTTOMRIGHT", 0, 0)
    rpage:SetWidth(41)
    rpage:Hide()

    -- Busqueda + UN solo boton de Filtros (dropdown con submenus por dimension).
    local search = CreateFrame("EditBox", nil, area, "InputBoxTemplate")
    search:SetAutoFocus(false); search:SetSize(150, 20)
    search:SetPoint("TOPLEFT", S.frame, "TOPLEFT", 100, -46)
    search:SetScript("OnTextChanged", function(self)
        S.spellBook.query = self:GetText() or ""
        S.spellBook.pageNum = 1
        RefreshSpells()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local searchLabel = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("BOTTOMLEFT", search, "TOPLEFT", -2, 2)
    searchLabel:SetText("Buscar conjuro")

    S.spellFilterDropdown = CreateFrame("Frame", "HarfordSpellFilterDropdown", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(S.spellFilterDropdown, SpellFilterMenu_Init, "MENU")
    local filterBtn = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")
    filterBtn:SetSize(80, 22)
    filterBtn:SetPoint("LEFT", search, "RIGHT", 10, 0)
    filterBtn:SetText("Filtros")
    filterBtn:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, S.spellFilterDropdown, self, 0, 0)
    end)

    -- Grimorio (libro de clase) y Master DM como popups del compendio, accesibles desde la pestaña.
    local grimoireBtn = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")
    grimoireBtn:SetSize(80, 22)
    grimoireBtn:SetPoint("LEFT", filterBtn, "RIGHT", 8, 0)
    grimoireBtn:SetText("Grimorio")
    grimoireBtn:SetScript("OnClick", function()
        local api = CompendioAPI()
        if api and api.OpenGrimoire then api.OpenGrimoire() end
    end)
    local masterBtn = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")
    masterBtn:SetSize(72, 22)
    masterBtn:SetPoint("LEFT", grimoireBtn, "RIGHT", 8, 0)
    masterBtn:SetText("Master")
    masterBtn:SetScript("OnClick", function()
        local api = CompendioAPI()
        if api and api.OpenMaster then api.OpenMaster() end
    end)
    masterBtn:Hide()  -- visible solo en modo DM (lo conmuta RefreshSpells)

    -- Botones de conjuro: mismo pool/estilo que el Libro de Habilidades.
    local PARTS = SPELLS_SKIN.parts
    local buttons = {}
    for i = 1, BOOK_PER_PAGE do
        local b = CreateFrame("Button", nil, area)
        b:SetSize(BOOK_BTN, BOOK_BTN)
        local col = (i <= BOOK_ROWS) and 0 or 1
        local row = (i <= BOOK_ROWS) and (i - 1) or (i - 1 - BOOK_ROWS)
        b:SetPoint("TOPLEFT", S.frame, "TOPLEFT", BOOK_COL_X[col + 1], BOOK_ROW_Y0 - row * BOOK_ROW_PITCH)
        b.ring = b:CreateTexture(nil, "BACKGROUND")
        b.ring:SetTexture(PARTS)
        b.ring:SetSize(43, 43)
        b.ring:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.bar = b:CreateTexture(nil, "BACKGROUND")
        b.bar:SetTexture(PARTS)
        b.bar:SetTexCoord(0.3125, 0.96484375, 0.37109375, 0.5234375)
        b.bar:SetSize(167, 39)
        b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 36, -2)
        b.bar2 = b:CreateTexture(nil, "BACKGROUND")
        b.bar2:SetTexture(PARTS)
        b.bar2:SetTexCoord(0.3125, 0.96484375, 0.37109375, 0.5234375)
        b.bar2:SetAllPoints(b.bar)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b); b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        b.name:SetPoint("LEFT", b, "RIGHT", 8, 4)
        b.name:SetWidth(145); b.name:SetJustifyH("LEFT")
        b.sub = b:CreateFontString(nil, "ARTWORK")
        b.sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -1)
        b.sub:SetWidth(145); b.sub:SetJustifyH("LEFT")
        b.sub:SetTextColor(0.96, 0.90, 0.72)  -- crema claro: legible sobre el pergamino con OUTLINE
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnEnter", function(self)
            if not (self.spell and GameTooltip) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.spell.name or "?", 1, 0.82, 0)
            GameTooltip:AddLine(SpellLevelText(self.spell.level) .. "  -  " .. (self.spell.school or "-"), 0.8, 0.8, 0.8)
            if self.spell.description and self.spell.description ~= "" then
                GameTooltip:AddLine(self.spell.description, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        b:SetScript("OnClick", function(self)
            local api = CompendioAPI()
            if self.spell and api and api.OpenSpellById then api.OpenSpellById(self.spell.id) end
        end)
        b:Hide()
        buttons[i] = b
    end

    local nxt = CreateFrame("Button", nil, area)
    nxt:SetSize(32, 32); nxt:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -31, 26)
    nxt:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nxt:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nxt:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nxt:SetScript("OnClick", function() S.spellBook.pageNum = S.spellBook.pageNum + 1; RefreshSpells() end)
    local prev = CreateFrame("Button", nil, area)
    prev:SetSize(32, 32); prev:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -66, 26)
    prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prev:SetScript("OnClick", function() S.spellBook.pageNum = math.max(1, S.spellBook.pageNum - 1); RefreshSpells() end)
    local pageText = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", -110, 38)

    S.spellBook = { page = page, area = area, body = body, page1 = lpage, page2 = rpage,
                    buttons = buttons, sideTabs = {}, prev = prev, nxt = nxt, pageText = pageText,
                    search = search, filterBtn = filterBtn, masterBtn = masterBtn,
                    filters = {}, tabKey = "all", query = "", pageNum = 1 }
end

RefreshSpells = function()
    if not (S.spellBook and S.spellBook.page) then return end
    local api = CompendioAPI()
    if not api then return end
    local sb = S.spellBook
    -- Boton Master solo para DM: senal canonica HarfordAuthority, con fallback al gate del compendio.
    if sb.masterBtn then
        local isDM = (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools())
            or (api.IsDMModeActive and api.IsDMModeActive()) or false
        sb.masterBtn:SetShown(isDM and true or false)
    end
    local tabs = (api.GetFilterTabs and api.GetFilterTabs()) or {}

    -- Pestañas laterales (filtros nivel/favoritos/mis conjuros) estilo SkillLineTab, como Habilidades.
    for i, t in ipairs(tabs) do
        local tab = sb.sideTabs[i]
        if not tab then
            tab = CreateFrame("Button", nil, sb.page)
            tab:SetSize(32, 32)
            tab:SetPoint("TOPLEFT", S.frame, "TOPRIGHT", -2, -36 - (i - 1) * 49)
            local ts = HarfordCharacterPanel._tabSkin
            tab.skin = tab:CreateTexture(nil, "BACKGROUND")
            tab.skin:SetTexture("Interface\\Spellbook\\SpellBook-SkillLineTab")
            tab.skin:SetSize(ts.w, ts.h)
            tab.skin:SetPoint("TOPLEFT", tab, "TOPLEFT", ts.x, ts.y)
            tab.icon = tab:CreateTexture(nil, "ARTWORK", nil, 0)
            tab.icon:SetSize(32, 32)
            tab.icon:SetPoint("CENTER", tab, "CENTER", 3, -1)
            tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            tab.iconFrame = tab:CreateTexture(nil, "ARTWORK", nil, 2)
            tab.iconFrame:SetTexture("Interface\\Spellbook\\GuildSpellbooktabIconFrame")
            tab.iconFrame:SetAllPoints(tab.icon)
            tab.checked = tab:CreateTexture(nil, "OVERLAY")
            tab.checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            tab.checked:SetBlendMode("ADD"); tab.checked:SetAllPoints(tab.icon)
            tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            local hl = tab:GetHighlightTexture()
            if hl then hl:ClearAllPoints(); hl:SetAllPoints(tab.icon) end
            tab:SetScript("OnEnter", BookSideTabOnEnter)
            tab:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            tab:SetScript("OnClick", function(self) sb.tabKey = self._key; sb.pageNum = 1; RefreshSpells() end)
            sb.sideTabs[i] = tab
        end
        tab._key, tab._label = t.key, (t.label or t.key)
        -- iconName (ej. favoritos "eps_rumble_starpoints") se resuelve via LibRPMedia como en la
        -- ventana suelta; t.icon es solo el fallback si no resuelve.
        tab.icon:SetTexture((t.iconName and api.ResolveRP3IconName and api.ResolveRP3IconName(t.iconName, t.icon))
            or t.icon or BOOK_GENERAL_ICON)
        tab.checked:SetShown(t.key == sb.tabKey)
        tab:Show()
    end
    for i = #tabs + 1, #sb.sideTabs do sb.sideTabs[i]:Hide() end

    -- Filtro = side tab activa + busqueda + dropdown de filtros secundarios.
    local active
    for _, t in ipairs(tabs) do if t.key == sb.tabKey then active = t; break end end
    active = active or {}
    local filter = { query = sb.query or "" }
    if active.level ~= nil then filter.level = active.level end
    if active.favoritesOnly then filter.favoritesOnly = true end
    if active.mineOnly then filter.mineOnly = true end
    for k, v in pairs(sb.filters) do if v and v ~= "Todas" then filter[k] = v end end
    local results = (api.FilterSpells and api.FilterSpells(filter)) or {}

    local pages = math.max(1, math.ceil(#results / BOOK_PER_PAGE))
    if sb.pageNum > pages then sb.pageNum = pages end
    if sb.pageNum < 1 then sb.pageNum = 1 end
    local startI = (sb.pageNum - 1) * BOOK_PER_PAGE
    local frA = HarfordCharacterPanel._bookFrame.activo or HarfordCharacterPanel._bookFrame.pasivo
    local frP = HarfordCharacterPanel._bookFrame.pasivo
    for i = 1, BOOK_PER_PAGE do
        local b = sb.buttons[i]
        local spell = results[startI + i]
        if spell then
            b.spell = spell
            b.icon:SetTexture((api.GetSpellIcon and api.GetSpellIcon(spell)) or spell.icon)
            b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94); b.icon:Show()
            -- Marco dorado (activo) si el conjuro es "mio"/preparado; marron (pasivo) si no.
            local known = (api.IsMySpell and api.IsMySpell(spell.id))
                or (api.IsPreparedSpell and api.IsPreparedSpell(spell.id))
            local fr = known and frA or frP
            b.ring:SetTexCoord(fr.tc[1], fr.tc[2], fr.tc[3], fr.tc[4])
            b.ring:SetSize(fr.w, fr.h)
            b.ring:ClearAllPoints(); b.ring:SetPoint("CENTER", b, "CENTER", fr.ox or 0, fr.oy or 0)
            b.ring:SetDrawLayer(known and "OVERLAY" or "BACKGROUND")
            b.name:SetText(spell.name or "?")
            local sub = SpellLevelText(spell.level) .. "  ·  " .. (spell.school or "-")
            if spell.affinity and spell.affinity ~= "" then sub = sub .. "  ·  " .. spell.affinity end
            if api.IsFavorite and api.IsFavorite(spell.id) then sub = sub .. "  ·  *" end
            b.sub:SetText(sub); b.sub:SetTextColor(0.96, 0.90, 0.72)
            b:EnableMouse(true); b:Show()
        else
            b.spell = nil
            b.icon:Hide()
            b.ring:SetTexCoord(frP.tc[1], frP.tc[2], frP.tc[3], frP.tc[4])
            b.ring:SetSize(frP.w, frP.h)
            b.ring:ClearAllPoints(); b.ring:SetPoint("CENTER", b, "CENTER", frP.ox or 0, frP.oy or 0)
            b.ring:SetDrawLayer("BACKGROUND")
            b.name:SetText(""); b.sub:SetText("")
            b:EnableMouse(false); b:Show()
        end
    end
    sb.pageText:SetText("Pagina " .. sb.pageNum .. " / " .. pages .. "  -  " .. #results .. " conjuros")
    if sb.pageNum > 1 then sb.prev:Enable() else sb.prev:Disable() end
    if sb.pageNum < pages then sb.nxt:Enable() else sb.nxt:Disable() end
end

-- Ajusta en vivo el marco de una categoria a partir de la CAJA EN PIXELES (esquina sup-izq
-- x1,y1 e inf-der x2,y2) sobre el sheet Spellbook-Parts; calcula texCoord y tamaño y refresca.
-- Refresca el Libro si el panel esta visible (lo llama HarfordDnD tras elegir nivel/cantidad de
-- un daño condicional en el dropdown del Libro, para reflejar el estado "Preparado").
function HarfordCharacterPanel.RefreshBookIfShown()
    if S.frame and S.frame:IsShown() and RefreshBook then
        RefreshBook()
    end
end

function HarfordCharacterPanel.ApplyBookFrame(kind, x1, y1, x2, y2)
    local fr = HarfordCharacterPanel._bookFrame[kind]
    if not fr then return nil end
    local sz = HarfordCharacterPanel._bookFrameTexSize or 256
    fr.tc = { x1 / sz, x2 / sz, y1 / sz, y2 / sz }
    fr.w = x2 - x1
    fr.h = y2 - y1
    if RefreshBook then RefreshBook() end
    return fr
end

-- Reaplica el tamaño/offset del marco metalico del tab a todas las pestañas (ajuste en vivo).
function HarfordCharacterPanel.ApplyTabSkin(w, h, x, y, is)
    local ts = HarfordCharacterPanel._tabSkin
    if w then ts.w = w end
    if h then ts.h = h end
    if x then ts.x = x end
    if y then ts.y = y end
    if is then ts.is = is end
    if S.book and S.book.sideTabs then
        for _, tab in ipairs(S.book.sideTabs) do
            if tab.skin then
                tab.skin:SetSize(ts.w, ts.h)
                tab.skin:ClearAllPoints()
                tab.skin:SetPoint("TOPLEFT", tab, "TOPLEFT", ts.x, ts.y)
            end
        end
    end
    return ts
end

-- Enlace clicable propio de habilidad (|Hharford:abil:<id>|h): al clicarlo, muestra el
-- rasgo (nombre + descripcion) en ItemRefTooltip. hooksecurefunc es aditivo -> no rompe TRP3.
if not HarfordCharacterPanel._abilLinkHooked then
    HarfordCharacterPanel._abilLinkHooked = true
    hooksecurefunc("SetItemRef", function(link)
        local id = link and link:match("harford:abil:([^|]+)")
        if not id then return end
        if not ItemRefTooltip then return end
        local f = ResolveBookFeatureById(id)
        -- Siempre mostramos algo (al menos el id) para confirmar que el clic llega.
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
        ItemRefTooltip:ClearLines()
        ItemRefTooltip:AddLine((f and f.name) or id, 1, 0.82, 0)
        if f and f.description and f.description ~= "" then
            ItemRefTooltip:AddLine(f.description, 0.9, 0.9, 0.9, true)
        end
        ItemRefTooltip:Show()
    end)
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
        { "book", "Habilidades" },
        { "spells", "Conjuros" },
        { "reputation", "Reputacion" },
        -- Creacion/Subida ocultas para el despliegue (ver HIDDEN_TABS).
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
    CreateProfessionsPage()
    CreateBookPage()
    CreateSpellsPage()

    S.refreshers.sheet = RefreshSheet
    S.refreshers.creation = RefreshCreation
    S.refreshers.leveling = RefreshLeveling
    S.refreshers.reputation = function() end
    S.refreshers.professions = RefreshProfessions
    S.refreshers.book = RefreshBook
    S.refreshers.spells = RefreshSpells
    -- Al empezar TU turno, las reacciones preparadas se apagan solas (se quedan activas solo hasta
    -- tu siguiente turno o hasta volver a clicarlas).
    if not S._turnListenerHooked and HarfordTurnOrderAPI and HarfordTurnOrderAPI.RegisterMyTurnListener then
        S._turnListenerHooked = true
        HarfordTurnOrderAPI.RegisterMyTurnListener(function()
            if S.activeReactions and next(S.activeReactions) then
                wipe(S.activeReactions)
                if RefreshBook then RefreshBook() end
            end
        end)
    end
    f:SetScript("OnShow", function(self)
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        RefreshPanel()
    end)
    f:SetScript("OnHide", function(self)
        self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
    end)
    f:SetScript("OnEvent", function(_, event, unit)
        if not (S.frame and S.frame:IsShown()) then return end
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
    S.inspectName = nil
    S.inspectUnit = nil
    if HarfordCharacterInspect and HarfordCharacterInspect.ClearInspectStores then
        HarfordCharacterInspect.ClearInspectStores()  -- descarta snapshot efimero al volver a modo propio
    end
    S.activeTab = tab or "sheet"
    if HIDDEN_TABS[S.activeTab] then S.activeTab = "sheet" end
    S.frame:Show()
    RefreshPanel()
end

function API.OpenInspect(unitOrName)
    CreateFrameIfNeeded()
    local function isUnitToken(value)
        value = tostring(value or "")
        return value == "player" or value == "target" or value == "focus"
            or value:match("^party%d+$") or value:match("^raid%d+$")
    end
    local unit = (type(unitOrName) == "string"
        and UnitExists and UnitExists(unitOrName)
        and ((not UnitIsPlayer) or UnitIsPlayer(unitOrName)))
        and unitOrName or nil
    local name = unit and (HarfordClassColors.UnitFullName(unit)) or tostring(unitOrName or "")
    if (not name or name == "") and UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
        unit = "target"
        name = HarfordClassColors.UnitFullName("target")
    end
    if (not unit) and isUnitToken(unitOrName) then
        name = ""
    end
    if not name or name == "" then
        Print("No hay jugador para inspeccionar.")
        return false
    end
    S.inspectName = name
    S.inspectUnit = unit
    S.activeTab = "sheet"
    if HarfordCharacterInspect and HarfordCharacterInspect.ClearInspectStores then
        HarfordCharacterInspect.ClearInspectStores()  -- descarta el snapshot anterior antes de pedir el nuevo
    end
    if HarfordCharacterInspect and HarfordCharacterInspect.Request then
        HarfordCharacterInspect.Request(unit or name)
    end
    S.frame:Show()
    RefreshPanel()
    return true
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
        S.inspectName = nil
        S.inspectUnit = nil
        API.Open(tab or "sheet")
    end
end

function API.Refresh()
    RefreshPanel()
end

-- Diagnostico en vivo del fondo del modelo 3D (lo usa HarfordDebug "modelbg"). Permite
-- probar tokens de DressUpBackground y ajustes de contraste sin recargar, para afinar el
-- mapeo definitivo en MODEL_BG_RACE_TOKENS / la desaturacion. Devuelve un texto de estado.
function API.DebugModelBg(argStr)
    local SH = S.sheet
    if not (SH and SH.modelBg and SH.model) then
        return "Abre el panel con /harford char (pestana Ficha) antes de probar el fondo."
    end
    argStr = tostring(argStr or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = argStr:match("^(%S*)%s*(.-)$")
    rest = tostring(rest or ""):gsub("%s+$", "")
    local lc = (cmd or ""):lower()

    if lc == "" or lc == "info" or lc == "status" then
        local data = GetProgression() or {}
        local race = data.race or {}
        local token = GetModelBackgroundToken(race)
        local da = (SH.modelDark and SH.modelDark.GetAlpha and SH.modelDark:GetAlpha()) or -1
        return string.format("raza id='%s' subraza='%s' -> token=%s | overlay.alpha=%.2f", tostring(race.id or ""), tostring(race.subraceId or ""), tostring(token), da)
    elseif lc == "reset" then
        RefreshRaceModelBackground(SH, GetProgression())
        return "Restaurado al fondo de la raza actual."
    elseif lc == "desat" then
        local on = (rest ~= "0" and rest:lower() ~= "off")
        for _, q in pairs(SH.modelBg) do
            if q.SetDesaturated then pcall(q.SetDesaturated, q, on) end
            if q.SetDesaturation then pcall(q.SetDesaturation, q, on and 1 or 0) end
        end
        return "Desaturacion = " .. tostring(on)
    elseif lc == "dark" then
        local a = tonumber(rest); if not a then return "uso: modelbg dark <0..1>" end
        if SH.modelDark then SH.modelDark:SetColorTexture(0, 0, 0, a) end
        return "Overlay oscuro alpha = " .. tostring(a)
    elseif lc == "bright" then
        local v = tonumber(rest); if not v then return "uso: modelbg bright <0..1>" end
        for _, q in pairs(SH.modelBg) do q:SetVertexColor(v, v, v, 1) end
        return "VertexColor (brillo) = " .. tostring(v)
    else
        -- Tratar cmd como token de DressUpBackground: aplica DressUpBackground-<token>1..4.
        for index, spec in ipairs(MODEL_BG_SOURCES) do
            local t = SH.modelBg[spec.key]
            if t then
                t:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. cmd .. tostring(index))
                SetTexCoord8(t, MODEL_BG_TEXCOORDS[spec.key])
                t:SetVertexColor(1, 1, 1, 1); t:SetAlpha(1)
            end
        end
        return "Aplicado token '" .. cmd .. "' (DressUpBackground-" .. cmd .. "1..4). Mira el panel."
    end
end

-- Diagnostico TRP3 del panel. Usa locales del modulo, por eso vive aqui como funcion publica;
-- el comando /harford debug run trp3build se registra en HarfordDebug.lua y la llama.
function API.RunTRP3BuildDiagnostic()
    if not (HarfordDebug and HarfordDebug.Print) then return end
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
end

-- Comandos sueltos retirados: usar `/harford char` (subir/crear/rep via subargumento).
-- Se conserva la funcion en SlashCmdList para el dispatcher.
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

-- Comando suelto retirado: usar `/harford inspect <unidad>`.
SlashCmdList.HARFORDCHARACTERINSPECT = function(msg)
    msg = tostring(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg ~= "" then
        API.OpenInspect(msg)
    else
        API.OpenInspect("target")
    end
end
