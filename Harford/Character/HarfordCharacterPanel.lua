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
    -- Y de la seccion "Caracteristicas" en la vista de ficha. Baja respecto al -70 historico para
    -- dejar sitio a la barra de experiencia, que ahora cae por debajo de la banda del numero de
    -- nivel. Las filas de caracteristica, la barra de "Rasgos" y su scroll se derivan de este
    -- valor, asi que mover la seccion los mueve a todos. Afinable con `xpbarpanel`.
    ABIL_BAR_Y = -80,
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

-- Constantes de presentacion agrupadas en una sola tabla. En file-scope ocupaban 50 de los
-- 200 locales que permite Lua 5.1 y el fichero se quedaba con 6 de margen; agrupadas gastan 1.
-- No cambia ninguna logica: solo deja de gastar un slot por constante.
local K = {}

K.TEX_PORTRAIT_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
-- Tamano/aspecto del CharacterFrame nativo (medido con FrameDump: Bg 536x401 + insets).
K.NORMAL_W, K.NORMAL_H = 540, 424
K.REPUTATION_W, K.REPUTATION_H = 390, 460
-- Pestaña Libro: tamaño EXACTO del SpellBookFrame nativo (probe). Todo se ancla al frame 1:1.
K.BOOK_W, K.BOOK_H = 550, 525
K.BOTTOM_TAB_W, K.BOTTOM_TAB_H, K.BOTTOM_TAB_GAP = 85, 28, 4

K.ABIL_KEYS = {
    { key = "Fuerza", short = "FUE" },
    { key = "Destreza", short = "DES" },
    { key = "Constitucion", short = "CON" },
    { key = "Inteligencia", short = "INT" },
    { key = "Sabiduria", short = "SAB" },
    { key = "Carisma", short = "CAR" },
}

K.CLASS_INFO_ATLAS = {
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

K.CLASS_FILE_TO_ATLAS = {
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

K.CLASS_ID_TO_CLASS_FILE = {
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

K.MODEL_BG_SOURCES = {
    { key = "tl" },
    { key = "tr" },
    { key = "bl" },
    { key = "br" },
}

K.MODEL_BG_TEXCOORDS = {
    tl = { 0.171875, 1, 0.039215688, 1 },
    tr = { 0, 0.296875, 0.039215688, 1 },
    bl = { 0.171875, 1, 0, 1 },
    br = { 0, 0.296875, 0, 1 },
}

K.MODEL_BG_RACE_TOKENS = {
    raza_humano = "Human",
    raza_renegado_humano = "Scourge",
    raza_enano = { default = "Dwarf", subraces = { raza_enano_hierro_negro = "DarkIronDwarf" } },
    raza_elfo_noche = "NightElf",
    raza_gnomo = { default = "Gnome", subraces = { raza_gnomo_mecagnomo = "Mechagnome" } },
    raza_draenei = { default = "Draenei", subraces = { raza_draenei_forjado_luz = "LightforgedDraenei" } },
    raza_huargen = "Worgen",
    raza_orco = "Orc",
    raza_renegado = "Scourge",
    raza_tauren = { default = "Tauren", subraces = { raza_tauren_monte_alto = "HighmountainTauren" } },
    raza_trol = { default = "Troll", subraces = { raza_trol_zandalari = "ZandalariTroll" } },
    raza_elfo_sangre = "BloodElf",
    raza_goblin = "Goblin",
    raza_nocheterna = "Nightborne",
    raza_pandaren = "Pandaren",
    raza_elfo_vacio = "VoidElf",
    raza_vulpera = "Vulpera",
}

K.PAPERDOLL_SLOT_NAMES = {
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

K.PAPERDOLL_SLOT_TOKENS = {
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
K.PAPERDOLL_SLOT_LABELS_ES = {
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

K.POINT_BUY_COST = {
    [8] = 0, [9] = 1, [10] = 2, [11] = 3, [12] = 4, [13] = 5, [14] = 7, [15] = 9,
}

-- La pestana Ficha (paperdoll y sus tres vistas laterales) vive en HarfordCharacterSheet.
local Ficha = HarfordCharacterSheet
-- La pestana Profesiones vive en HarfordCharacterProfessions.
local Profesiones = HarfordCharacterProfessions

local function Print(msg)
    HarfordChat.Print(msg)
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
    local function ApplyPortrait(texture, unit)
        if not texture then return end
        local mode = GetPortraitMode(unit)
        local icon
        if mode ~= "wow" and HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.GetProfileIcon then
            local profile = HarfordTRP3.GetPlayerProfile(unit)
            icon = profile and HarfordTRP3.GetProfileIcon(profile)
        end
        if icon and texture.SetTexture then
            texture:SetTexture(tonumber(icon) or icon)
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        elseif SetPortraitTexture then
            SetPortraitTexture(texture, unit)
            texture:SetTexCoord(0, 1, 0, 1)
        end
        texture:Show()
    end
    ApplyPortrait(S.portrait, GetPortraitUnit())
    -- El Libro siempre pertenece al jugador local: no hereda el retrato de una inspeccion.
    ApplyPortrait(S.skillsPortrait, "player")
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

K.TAB_ORDER = { "sheet", "reputation", "creation", "leveling" }
K.SKILLS_TAB_ORDER = { "book", "spells", "professions" }

-- Pestañas OCULTAS para el despliegue (Creacion/Subida aun no listas). No se crean sus
-- botones (ver tabData) y cualquier intento de activarlas cae a "sheet". Las paginas siguen
-- construyendose para no romper refrescos; solo no son accesibles desde la UI.
K.HIDDEN_TABS = { creation = true, leveling = true }

-- Creacion y Subida no forman parte de la navegacion inferior. La subida sigue
-- accesible de forma explicita desde `/harford char subir`, sin reintroducir una
-- pestaña visual que compita con Personaje/Reputacion/Profesiones.
local function IsExplicitHiddenTab(tab)
    return K.HIDDEN_TABS[tab] and S.explicitHiddenTab == tab
end

local function PositionTabs()
    if not S.frame then return end
    -- Anclaje nativo: primera pestaña a BOTTOMLEFT(11,2), las siguientes solapadas a la
    -- derecha (-15) igual que CharacterFrameTab1/2/3.
    local prev
    for _, key in ipairs(K.TAB_ORDER) do
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

local function PositionSkillsTabs()
    if not S.skillsFrame then return end
    local prev
    for _, key in ipairs(K.SKILLS_TAB_ORDER) do
        local btn = S.skillsTabs and S.skillsTabs[key]
        if btn then
            btn:ClearAllPoints()
            if prev then
                btn:SetPoint("LEFT", prev, "RIGHT", -15, 0)
            else
                btn:SetPoint("TOPLEFT", S.skillsFrame, "BOTTOMLEFT", 11, 2)
            end
            prev = btn
        end
    end
end

local function SetPanelMode()
    for _, key in ipairs(K.TAB_ORDER) do
        local tab = S.tabs[key]
        if tab then tab:Show() end
    end
    for _, key in ipairs(K.SKILLS_TAB_ORDER) do
        local tab = S.tabs[key]
        if tab then tab:Hide() end
    end
end

local function ApplyFrameLayout()
    if not S.frame then return end
    local isRep = S.activeTab == "reputation"
    local w = isRep and K.REPUTATION_W or K.NORMAL_W
    local h = isRep and K.REPUTATION_H or K.NORMAL_H
    S.frame:SetSize(w, h)
    if S.content then
        S.content:ClearAllPoints()
        S.content:SetPoint("TOPLEFT", S.frame, "TOPLEFT", isRep and 18 or 14, isRep and -62 or -52)
        S.content:SetPoint("BOTTOMRIGHT", S.frame, "BOTTOMRIGHT", isRep and -18 or -14, isRep and 30 or 12)
    end
    -- El Bg/Inset propios del ButtonFrameTemplate tapan el cuerpo nativo del libro y lo hacen
    -- parecer "incrustado"; se ocultan en las pestañas de libro para que se vea 374155 + pergamino.
    local inset = S.frame.Inset or _G["HarfordCharacterPanelFrameInset"]
    if inset then inset:Show() end
    local tplBg = S.frame.Bg or _G["HarfordCharacterPanelFrameBg"]
    if tplBg then tplBg:Show() end
    if S.frameBg then S.frameBg:Show() end
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
    if HarfordNamePlates and HarfordNamePlates.RefreshAll then
        HarfordNamePlates.RefreshAll()
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
K.ABILITY_TOOLTIP_TEXT = {}
for _, a in ipairs((HarfordDnDData and HarfordDnDData.ABIL) or {}) do
    if a.key and a.desc then K.ABILITY_TOOLTIP_TEXT[a.key] = a.desc end
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
K.TAB_TEX_INACTIVE = "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab"
K.TAB_TEX_ACTIVE = "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"
K.TAB_TEX_HILITE = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-RealHighlight"

-- Pestana inferior replicando el CharacterFrameTab nativo: 3-slice inactivo (32px),
-- 3-slice activo (34px, ActiveTab) y highlight de hover (RealHighlight).
local function CreateNativeTab(parent, id, text, onClick)
    local b = CreateFrame("Button", "HarfordCharPanelTab" .. id, parent)
    b:SetHeight(32)

    -- Estado INACTIVO: regiones CharacterFrameTab*Left/Middle/Right.
    local il = b:CreateTexture(nil, "BACKGROUND"); il:SetTexture(K.TAB_TEX_INACTIVE); il:SetTexCoord(0, 0.15625, 0, 1); il:SetSize(20, 32); il:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -1)
    local im = b:CreateTexture(nil, "BACKGROUND"); im:SetTexture(K.TAB_TEX_INACTIVE); im:SetTexCoord(0.15625, 0.84375, 0, 1); im:SetHeight(32); im:SetPoint("LEFT", il, "RIGHT", 0, 0)
    local ir = b:CreateTexture(nil, "BACKGROUND"); ir:SetTexture(K.TAB_TEX_INACTIVE); ir:SetTexCoord(0.84375, 1, 0, 1); ir:SetSize(20, 32); ir:SetPoint("LEFT", im, "RIGHT", 0, 0)
    b.inactive = { il, im, ir }

    -- Estado ACTIVO/seleccionado: regiones *Disabled del CharacterFrameTab.
    local al = b:CreateTexture(nil, "BACKGROUND"); al:SetTexture(K.TAB_TEX_ACTIVE); al:SetTexCoord(0, 0.15625, 0, 0.546875); al:SetSize(20, 35); al:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    local am = b:CreateTexture(nil, "BACKGROUND"); am:SetTexture(K.TAB_TEX_ACTIVE); am:SetTexCoord(0.15625, 0.84375, 0, 0.546875); am:SetHeight(35); am:SetPoint("LEFT", al, "RIGHT", 0, 0)
    local ar = b:CreateTexture(nil, "BACKGROUND"); ar:SetTexture(K.TAB_TEX_ACTIVE); ar:SetTexCoord(0.84375, 1, 0, 0.546875); ar:SetSize(20, 35); ar:SetPoint("LEFT", am, "RIGHT", 0, 0)
    b.active = { al, am, ar }

    -- Hover nativo, pero solo para pestanas inactivas.
    local h = b:CreateTexture(nil, "OVERLAY")
    h:SetTexture(K.TAB_TEX_HILITE)
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
        return (lower:gsub("^%l", string.upper))  -- parentesis: gsub devuelve 2 valores
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
    if HarfordDnDProgression and HarfordDnDProgression.IsImportedFromTRP3
        and HarfordDnDProgression.IsImportedFromTRP3(profileName) then
        return nil
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
            -- Sin la guarda `and`: en una cadena asi solo llega el PRIMER valor devuelto y
            -- `hex` quedaba nil, asi que el nombre de clase nunca llegaba a colorearse.
            -- `GetClassColorParts` es un upvalue ya asignado cuando esto se ejecuta.
            local _, _, _, hex = GetClassColorParts(entry, className, className)
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
            local presentationFeature = HarfordCharacterBook and HarfordCharacterBook.PresentFeature
                and HarfordCharacterBook.PresentFeature(feature) or feature
            local name = tostring(feature.name)
            local choiceSummary = GetFeatureChoiceDisplay(feature, profileName)
            local value = choiceSummary or ""
            local tooltip = AddFeatureChoiceTooltip(feature, profileName,
                tostring(presentationFeature.description or item.className or ""))
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

-- Paginas que viven en la VENTANA DE HABILIDADES, no en el panel de personaje. Es una sola
-- fuente a proposito: el bucle que oculta paginas del panel usa esta misma tabla, y cuando
-- Profesiones se mudo aqui pero no alli, abrir el panel de personaje ocultaba sus marcos.
K.SKILLS_WINDOW_PAGES = { book = true, spells = true, professions = true }

local function RefreshPanel()
    if not S.frame or not S.frame:IsShown() then return end
    if K.HIDDEN_TABS[S.activeTab] and not IsExplicitHiddenTab(S.activeTab) then
        S.activeTab = "sheet"
    end
    if S.activeTab == "book" or S.activeTab == "spells" then
        S.activeTab = "sheet"
    end
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
        -- Las paginas del libro de habilidades las gobierna SU ventana, no esta.
        if not K.SKILLS_WINDOW_PAGES[key] then
            page:SetShown((not isReputation) and key == S.activeTab)
        end
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

local RefreshSkillsPanel

RefreshSkillsPanel = function()
    local f = S.skillsFrame
    if not (f and f:IsShown()) then return end
    f:SetSize(K.BOOK_W, K.BOOK_H)
    if S.skillsContent then
        S.skillsContent:ClearAllPoints()
        S.skillsContent:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -21)
        S.skillsContent:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    end
    local isBook = S.skillsActiveTab == "book"
    local isSpells = S.skillsActiveTab == "spells"
    local isProf = S.skillsActiveTab == "professions"
    if S.book then
        if S.book.page then S.book.page:SetShown(isBook) end
        if S.book.body then S.book.body:SetShown(isBook) end
        if S.book.page1 then S.book.page1:SetShown(isBook) end
        if S.book.page2 then S.book.page2:SetShown(isBook) end
    end
    if S.spellBook then
        if S.spellBook.page then S.spellBook.page:SetShown(isSpells) end
        if S.spellBook.body then S.spellBook.body:SetShown(isSpells) end
        if S.spellBook.page1 then S.spellBook.page1:SetShown(isSpells) end
        if S.spellBook.page2 then S.spellBook.page2:SetShown(isSpells) end
    end
    if S.professions then
        local P = S.professions
        if P.page then P.page:SetShown(isProf) end
        if P.profBody then P.profBody:SetShown(isProf) end
        if P.profPage1 then P.profPage1:SetShown(isProf) end
        if P.profPage2 then P.profPage2:SetShown(isProf) end
        if P.bookmark then P.bookmark:SetShown(isProf) end
    end
    for key, button in pairs(S.skillsTabs or {}) do
        if button.SetSelectedLook then button:SetSelectedLook(key == S.skillsActiveTab) end
    end
    if f.TitleText then
        f.TitleText:SetText(S.skillsActiveTab == "spells" and "Conjuros"
            or (S.skillsActiveTab == "professions" and "Profesiones" or "Habilidades"))
    end
    PositionSkillsTabs()
    local refresh = S.refreshers and S.refreshers[S.skillsActiveTab]
    if refresh then refresh() end
end

local function CreatePage(key)
    local parent = (K.SKILLS_WINDOW_PAGES[key] and S.skillsContent) or S.content or S.frame
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

GetClassFileForEntry = function(entry, className, label)
    if not HarfordClassColors then return nil end
    local rawId = tostring(entry and entry.classId or "")
    return K.CLASS_ID_TO_CLASS_FILE[rawId]
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
    local def = K.MODEL_BG_RACE_TOKENS[tostring(race.id or "")]
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
    for index, spec in ipairs(K.MODEL_BG_SOURCES) do
        local t = sheet.modelBg[spec.key]
        if t then
            if token then
                t:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. token .. tostring(index))
                SetTexCoord8(t, K.MODEL_BG_TEXCOORDS[spec.key])
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

-- Mueve la seccion de Salvaciones y recoloca lo que depende de ella. Existe para poder
-- afinar la posicion en juego sin recargar; la vista se repinta sola al refrescar.
function API.SetSavesSectionY(y)
    local SH = S.sheet
    if not (SH and SH.attrScroll) then return false end
    SH.savesBarY = tonumber(y) or SH.savesBarY or -226
    SH.attrScroll:SetPoint("BOTTOMRIGHT", SH.statsPane, "TOPRIGHT", -26, SH.savesBarY + 2)
    return true, SH.savesBarY
end

-- Mueve/redimensiona la barra de experiencia en caliente. Existe para afinarla en juego sin
-- recargar: no se puede ver el resultado desde fuera del cliente.
function API.SetXPBarPlacement(y, ancho, alto, x)
    local SH = S.sheet
    local bar = SH and SH.xpBar
    if not bar then return false end
    local w = tonumber(ancho) or bar:GetWidth()
    local h = tonumber(alto) or bar:GetHeight()
    SH.xpBarY = tonumber(y) or SH.xpBarY or -7
    SH.xpBarX = tonumber(x) or SH.xpBarX or 3
    bar:SetSize(w, h)
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", SH.levelValueFrame, "BOTTOM", SH.xpBarX, SH.xpBarY)
    return true, w, h, SH.xpBarX, SH.xpBarY
end

-- Baja/sube la seccion de "Caracteristicas" y arrastra con ella todo lo que va debajo (las filas
-- de caracteristica, la barra de "Rasgos" y su scroll). Existe porque la barra de experiencia se
-- come el hueco que habia entre el numero de nivel y esta seccion.
function API.SetAbilitySectionY(y)
    local SH = S.sheet
    if not (SH and SH.featScroll) then return false end
    SH.abilBarY = tonumber(y) or SH.abilBarY or S.ABIL_BAR_Y
    SH.featScroll:SetPoint("TOPLEFT", SH.statsPane, "TOPLEFT", 14, -243 + (SH.abilBarY + 70))
    return true, SH.abilBarY
end

-- texCoords EXACTOS del PaperDollSidebarTabs nativo (sacados de /harford debug run probeframe).
K.SBTAB_TC = {
    TOP     = { 0.015625, 0.003906, 0.015625, 0.046875, 0.453125, 0.003906, 0.453125, 0.046875 },
    BOTTOM  = { 0.015625, 0.054688, 0.015625, 0.105469, 0.453125, 0.054688, 0.453125, 0.105469 },
    GLOW    = { 0.015625, 0.613281, 0.015625, 0.781250, 0.796875, 0.613281, 0.796875, 0.781250 }, -- fondo inactivo 50x43
    DIVIDER = { 0.015625, 0.113281, 0.015625, 0.187500, 0.546875, 0.113281, 0.546875, 0.187500 }, -- separador 33x19
    HILITE  = { 0.015625, 0.195313, 0.015625, 0.316406, 0.500000, 0.195313, 0.500000, 0.316406 },
    ICON2   = { 0.015625, 0.324219, 0.015625, 0.460938, 0.531250, 0.324219, 0.531250, 0.460938 }, -- icono tab2 33x34
    ICON3   = { 0.015625, 0.468750, 0.015625, 0.605469, 0.531250, 0.468750, 0.531250, 0.605469 }, -- icono tab3 33x34
    ACTIVE_BG = { 0.015625, 0.789063, 0.015625, 0.957031, 0.796875, 0.789063, 0.796875, 0.957031 }, -- fondo activo 50x43
}

K.SBTAB_TOOLTIP = {
    summary = "Caracteristicas",
    skills = "Habilidades",
    details = "Atributos",
}

local function RefreshCreationCost()
    local C = S.creation
    if not C then return end
    local total, valid = 0, true
    for _, abil in ipairs(K.ABIL_KEYS) do
        local value = tonumber(C.boxes[abil.key]:GetText()) or 10
        if not K.POINT_BUY_COST[value] then
            valid = false
        else
            total = total + K.POINT_BUY_COST[value]
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
    for _, abil in ipairs(K.ABIL_KEYS) do
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

    for i, abil in ipairs(K.ABIL_KEYS) do
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
        for _, abil in ipairs(K.ABIL_KEYS) do C.boxes[abil.key]:SetText(tostring(AbilityScore(abil.key))) end
        RefreshCreationCost()
    end)
    read:SetPoint("TOPLEFT", 0, -220)

    local array = CreateButton(page, "Array", 74, 22, function()
        local values = { 15, 14, 13, 12, 10, 8 }
        for i, abil in ipairs(K.ABIL_KEYS) do C.boxes[abil.key]:SetText(tostring(values[i] or 10)) end
    end)
    array:SetPoint("LEFT", read, "RIGHT", 8, 0)

    local pointBuy = CreateButton(page, "Compra 27", 92, 22, function()
        for _, abil in ipairs(K.ABIL_KEYS) do C.boxes[abil.key]:SetText("8") end
    end)
    pointBuy:SetPoint("LEFT", array, "RIGHT", 8, 0)

    local rolled = CreateButton(page, "Tirar 4d6", 92, 22, function()
        for _, abil in ipairs(K.ABIL_KEYS) do C.boxes[abil.key]:SetText(tostring(RollAbility())) end
    end)
    rolled:SetPoint("LEFT", pointBuy, "RIGHT", 8, 0)

    local apply = CreateButton(page, "Aplicar", 110, 24, ApplyCreationScores)
    apply:SetPoint("TOPLEFT", 0, -262)
end

local function RefreshCreation()
    if not S.creation then return end
    for _, abil in ipairs(K.ABIL_KEYS) do
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
    -- Cambio de Forma y Metamorfosis tienen activadores propios en el Libro. No
    -- son elecciones de progresion ni checkboxes de configuracion.
    local visibleStates = {}
    for _, state in ipairs(states) do
        if state.id ~= "wild_shape" and state.id ~= "metamorphosis" then
            visibleStates[#visibleStates + 1] = state
        end
    end
    if #visibleStates > 0 then
        MakeLine(child, "Estados activables", 0, y, "GameFontNormal")
        y = y - 22
        for _, state in ipairs(visibleStates) do
            local stateId = state.id
            local label = state.label or stateId
            local chk = AcquireDynamicCheck(child, label, function(_, checked)
                HarfordDnDProgression.SetToggleState(stateId, checked, GetProfileName())
                RefreshGameUI()
                RefreshPanel()
            end)
            chk:SetPoint("TOPLEFT", 0, y)
            chk:SetChecked(HarfordDnDProgression.IsToggleStateActive
                and HarfordDnDProgression.IsToggleStateActive(stateId, GetProfileName()) or false)
            if chk.text then chk.text:SetWidth(250) end
            -- "Lobo Solitario" son los rasgos del Cazador que SOLO valen SIN companero bestial.
            -- Invocar la bestia apaga el estado, pero sin esto se podia volver a marcar con la
            -- bestia en juego y quedarse con las dos cosas, que es lo que el manual excluye.
            local bloqueo
            if stateId == "lone_wolf" and HarfordDnDCompanions and HarfordDnDCompanions.GetActive then
                local activa = HarfordDnDCompanions.GetActive(GetProfileName())
                if activa then
                    bloqueo = "No puedes combatir como Lobo Solitario mientras tengas a "
                        .. tostring(activa.name) .. " invocada."
                end
            end
            -- Enable/Disable en vez de SetEnabled: existen desde siempre y Epsilon no siempre
            -- trae la API moderna. El label es GameFontHighlightSmall (blanco), asi que el gris
            -- de bloqueo se aplica y se restaura a blanco explicitamente.
            if bloqueo then chk:Disable() else chk:Enable() end
            if chk.text then
                if bloqueo then chk.text:SetTextColor(0.5, 0.5, 0.5)
                else chk.text:SetTextColor(1, 1, 1) end
            end
            if bloqueo or (state.description and state.description ~= "") then
                chk:SetScript("OnEnter", function(self)
                    TooltipLines(self, state.label or stateId, bloqueo or state.description)
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
                -- POR HUECO, no la lista compactada: `GetChoice` mueve las elecciones de sitio y
                -- el desplegable del hueco 1 acababa mostrando lo elegido en el 2.
                local chosen = HarfordDnDProgression.GetChoiceSlotMap
                    and HarfordDnDProgression.GetChoiceSlotMap(feature.id, GetProfileName()) or {}
                for slot = 1, HarfordDnDBook.GetChoiceSlots(feature) do
                    local slotNo = slot
                    local drop = AcquireDynamicDrop(child, 210)
                    drop:SetPoint("TOPLEFT", 0, y)
                    local opt = HarfordDnDBook.GetChoiceOption and HarfordDnDBook.GetChoiceOption(feature, chosen[slotNo])
                    SetDropText(drop, opt and opt.label or ("Eleccion " .. tostring(slotNo)))
                    -- Las mejoras de caracteristica (`ability+N`) SI admiten repetir la misma
                    -- opcion en dos slots (es el "+2 a una caracteristica" del manual). El resto
                    -- (metamagia, estilos, habilidades) no: se ocultan las ya elegidas en OTRO
                    -- slot para no poder gastar dos slots en la misma opcion.
                    local stackable = tostring(feature.choice.optionsFrom or ""):match("^ability%+%d+$") ~= nil
                    local isExpertise = tostring(feature.choice.optionsFrom or "") == "skillExpertise"
                    UIDropDownMenu_Initialize(drop, function()
                        -- Pericia: solo habilidades en las que YA se es competente (regla 5e). Se
                        -- filtra aqui, en la UI, y no en `GetChoiceOptions`: el Libro es capa de
                        -- datos y `HarfordDnDProgression` la llama durante la importacion TRP3,
                        -- asi que no debe depender del motor de efectos.
                        local available = HarfordDnDBook.GetChoiceOptions(feature) or {}
                        if isExpertise and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetSkillRank then
                            local profName = GetProfileName()
                            local eligible = {}
                            for _, option in ipairs(available) do
                                local rank = HarfordDnDFeatureEffects.GetSkillRank(option.id, profName) or 0
                                if rank >= 1 or chosen[slotNo] == option.id then
                                    eligible[#eligible + 1] = option
                                end
                            end
                            -- Si no hay ninguna competente aun, mostrar todas antes que un menu vacio.
                            if #eligible > 0 then available = eligible end
                        end
                        for _, option in ipairs(available) do
                            local optionChoice = option
                            local takenElsewhere = false
                            if not stackable then
                                for otherSlot, takenId in pairs(chosen) do
                                    if otherSlot ~= slotNo and takenId == optionChoice.id then
                                        takenElsewhere = true
                                        break
                                    end
                                end
                            end
                            if not takenElsewhere then
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

    L.manaInfo = CreateFS(page, "GameFontDisableSmall", "El coste de conjuros se configura globalmente en /harford config.")
    L.manaInfo:SetPoint("TOPLEFT", 4, -176)
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
    if L.manaInfo then
        local useSlots = HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("spell_cost_mode") == "slots"
        L.manaInfo:SetText(useSlots and "Coste global: espacios de conjuro." or "Coste global: mana automatico.")
    end

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
        local raceId = tostring(((GetProgression() or {}).race or {}).id or "")
        for _, sub in ipairs(classDef.subclasses or {}) do
            local subChoice = sub
            local info = UIDropDownMenu_CreateInfo()
            info.text = subChoice.name
            if subChoice.desc and subChoice.desc ~= "" then
                info.tooltipTitle = subChoice.name
                info.tooltipText = subChoice.desc
                info.tooltipOnButton = true
            end
            if subChoice.requiredRace and raceId ~= "" and raceId ~= subChoice.requiredRace then
                info.disabled = true
                info.tooltipTitle = subChoice.name
                info.tooltipText = "Requiere la raza Elfo de la Noche."
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

-- El nativo reparte la pagina en DOS huecos grandes de profesion principal (437x81, paso 93)
-- y TRES pequenos (437x46) con el arte de cocina/pesca/arqueologia HORNEADO en la textura.
-- En Harford todas las profesiones son iguales, asi que se usan CINCO huecos grandes con el
-- mismo paso nativo: 67 + 5*93 = 520 sobre 525 de alto, caben justos. Los tres ultimos caen
-- encima del arte de secundarias, que se tapa con el marco recortado de la propia pagina
-- (ver PROF_FRAME_OFFSET).
-- CUATRO huecos: el quinto (que acabaria en -520) se sale del area visible del libro.
-- 67 + 3*93 + 81 = 427, con margen de sobra hasta el borde inferior de la pagina.
K.PROF_SLOTS = {}
for i = 1, 4 do
    K.PROF_SLOTS[i] = { kind = "primary", x = 80, y = -(67 + (i - 1) * 93), w = 437, h = 81 }
end

-- Para tapar el arte de secundarias se recorta el marco del PRIMER hueco de la propia pagina.
-- No hacen falta texCoords ni saber el tamano del fichero: basta con volver a dibujar la pagina
-- dentro de un frame que recorta, desplazada de modo que el hueco 1 caiga sobre el hueco actual.
-- Pagina izquierda anclada en (7,-25) y hueco 1 en (80,-67) => desplazamiento (-73, +42).
K.PROF_FRAME_OFFSET = { x = -73, y = 42 }

-- El hueco de contenido mide 437x81, pero el ornamento de la pagina nativa SOBRESALE de ese
-- rectangulo: recortando justo el hueco se pierde parte del marco por arriba y por abajo. Este
-- margen ensancha la ventana de recorte por los cuatro lados (y desplaza la copia de la pagina
-- otro tanto, para que siga cayendo el mismo trozo). El paso entre huecos es 12, asi que 6 es
-- justo la mitad del hueco entre marcos: mas que eso y dos marcos contiguos se solaparian.
K.PROF_FRAME_MARGIN = 4

-- Franja izquierda de la pagina de profesiones que se recorta para quedarse solo con el
-- marcapaginas VERDE, superpuesto sobre el borde del libro de habilidades (que lleva el suyo
-- azul). `x/top/bottom` situan la ventana de recorte sobre el libro; `w` es su ancho y `tx/ty`
-- desplazan la textura DENTRO de la ventana (para elegir que trozo de la pagina asoma).
-- Rectangulo EXACTO en el que el libro de habilidades dibuja su pagina (Habilidades/Conjuros).
-- Vive aqui una sola vez porque lo usan dos cosas: la pagina base de Profesiones y la textura
-- del marcapaginas, que debe estirarse al MISMO rectangulo para que el marcapaginas verde caiga
-- justo sobre el azul al que sustituye. A tamano natural la escala no coincidiria.
K.SKILLS_PAGE_RECT = { left = 0, top = -25, right = -31, bottom = -15, rightWidth = 41 }

-- Ventana de recorte del marcapaginas: mismo alto que la pagina y `w` de ancho por la izquierda.
-- `tx/ty` solo estan para afinar; con 0 la textura queda exactamente donde la pagina base.
K.PROF_BOOKMARK = { w = 65, tx = 0, ty = 0 }

-- Barra de progreso de profesion, 1:1 con ProfessionStatusBarTemplate del XML nativo:
-- 95x16, relleno Professions-Progress-Fill, dos fondos de extremo de 16x16 y dos remates de
-- 12x12 (el DERECHO va hidden=true en el propio XML, no es un apano nuestro), y el fondo
-- central anclado ENTRE los dos fondos de extremo, de donde hereda altura y el desplazamiento
-- de +2. Texto TextStatusBarText centrado con +2 en vertical.
-- Tooltip de los botones de profesion. El libro nativo muestra uno al pasar por encima y el
-- nuestro no mostraba nada. Aqui no hay hechizo del que sacar la descripcion, asi que se compone
-- con lo que si tenemos: tipo, herramienta, caracteristica que la rige, rango y recetas.
K.PROF_KIND_LABEL = {
    craft = "Profesion de fabricacion",
    gather = "Profesion de recoleccion",
    utility = "Competencia de herramienta",
}

S.RefreshProfessions = Profesiones.RefreshProfessions

-- ===========================================================================
-- Pestaña LIBRO: libro de habilidades con look spellbook VANILLA. Lista los rasgos
-- del personaje por seccion (General / Clase N / Subclase N) con icono + nombre + nivel.
-- Comportamiento por click: pasivo = nada (tooltip), activo = anuncia en chat con enlace
-- propio + ejecuta su mecanica, reaccion = toggle (vacio por ahora). Texturas vanilla.
-- ===========================================================================
K.BOOK_COLS, K.BOOK_ROWS = 2, 6
K.BOOK_PER_PAGE = K.BOOK_COLS * K.BOOK_ROWS
-- Clasificacion y datos de presentacion del Libro -> extraidos a HarfordCharacterBook (modulo
-- puro, sin `S`). Alias locales para no tocar los call-sites de la UI del Libro de abajo.
K.BOOK_ICON = HarfordCharacterBook.ICON
local FeatureCondDamageId     = HarfordCharacterBook.CondDamageId
local BookCategory            = HarfordCharacterBook.Category
K.REACTION_TRIGGER_TEXT = HarfordCharacterBook.REACTION_TRIGGER_TEXT
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

-- `usesFrom` apunta al id de otro rasgo: este consume la reserva de aquel. Lo usan las
-- Maldiciones, que gastan usos de Corrupcion y no tienen reserva propia.
local function GetFeatureUseState(feature)
    if not (feature and (feature.uses or feature.usesFrom)
        and HarfordDnDFeatureUses and HarfordDnDFeatureUses.GetTracked) then
        return nil
    end
    local id = feature.usesFrom or feature.id
    if not id then return nil end
    for _, tracked in ipairs(HarfordDnDFeatureUses.GetTracked(GetProfileName()) or {}) do
        if tracked.featureId == id then
            return tracked
        end
    end
    return nil
end

local function FeatureUseCompactText(feature)
    local tracked = GetFeatureUseState(feature)
    if not tracked then return nil end
    return tostring(tracked.available or 0) .. "/" .. tostring(tracked.max or 0)
end

local function FeatureUseTooltipText(feature)
    local tracked = GetFeatureUseState(feature)
    if not tracked then return nil end
    local recharge = tracked.recharge == "short" and "Descanso corto" or "Descanso largo"
    return "Usos: " .. FeatureUseCompactText(feature) .. " · " .. recharge, tracked
end

local function FeatureUseAvailable(feature)
    if not (feature and (feature.uses or feature.usesFrom)) then return true end
    local tracked = GetFeatureUseState(feature)
    if not tracked then return true end
    return (tonumber(tracked.available) or 0) > 0
end

do
end

local function WarnFeatureWithoutUses(feature)
    if DEFAULT_CHAT_FRAME then
        HarfordChat.Print("No quedan usos de " .. tostring(feature and feature.name or "este rasgo") .. ".")
    end
end

local AnnounceAbility, OpenLayOnHandsPrompt, OpenDemonicFirePrompt
local ApplyPowerWordGrant  -- forward: la usan la carga llevada y el estado propio, mas arriba

local function GetPowerWordOption(feature)
    if not (feature and HarfordCharacterBook.IsOptionAbility(feature) and HarfordDnDProgression
        and HarfordDnDProgression.GetChoice and HarfordDnDBook and HarfordDnDBook.GetChoiceOption) then
        return nil
    end
    if type(feature.powerWordOption) == "table" then return feature.powerWordOption end
    local parent = feature.powerWordParent or feature
    local chosen = HarfordDnDProgression.GetChoice(parent.id, GetProfileName())
    return type(chosen) == "table" and HarfordDnDBook.GetChoiceOption(parent, chosen[1]) or nil
end

local function GetPowerWordOptionById(feature, optionId)
    if not optionId or not HarfordDnDBook or not HarfordDnDBook.GetChoiceOption then return GetPowerWordOption(feature) end
    local parent = feature and (feature.powerWordParent or feature) or nil
    return parent and HarfordDnDBook.GetChoiceOption(parent, optionId) or nil
end

local function PowerWordDisplayFeature(feature, option)
    local icon = tostring(option.icon or "")
    if icon ~= "" and not icon:find("\\", 1, true) then
        icon = "Interface\\Icons\\" .. icon
    end
    return {
        id = tostring(feature.id) .. "_" .. tostring(option.id),
        name = tostring(option.label),
        description = option.desc or feature.description,
        icon = icon,
        -- `cast` SE ARRASTRA: es lo que mira `BroadcastAbility` para cobrar la economia de turno.
        -- Sin el, una reaccion elegida como opcion (Palabra de Poder) disparaba sin gastar la
        -- reaccion del turno. La opcion manda sobre el rasgo padre, que puede tener otro coste.
        cast = option.cast or feature.cast,
    }
end

local function SpendPowerWord(option)
    local key = tostring(option and option.resourceKey or "")
    local cost = math.max(0, tonumber(option and option.resourceCost) or 0)
    if key == "" or cost <= 0 then return true end
    if not (HarfordDnDStore and HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.AdjustResourceCurrent) then
        return false, "El sistema de recursos no esta disponible."
    end
    if HarfordDnDStore.GetResourceCurrent(key) < cost then
        return false, "No hay recurso suficiente para esa opcion."
    end
    HarfordDnDStore.AdjustResourceCurrent(key, -cost)
    return true
end

-- CD de salvacion de una opcion elegida. La caracteristica NO es fija: la declara el rasgo padre
-- en `dcAbility` (Carisma en las Palabras de Poder del Sacerdote, Sabiduria en los brebajes del
-- Monje, las trampas del Cazador y los ataques del Chaman). Carisma queda como valor por defecto
-- porque Palabra de Poder fue el primer usuario de esta ruta.
local function OptionSaveDC(feature, option)
    local abil = tostring((option and option.dcAbility) or (feature and feature.dcAbility) or "Carisma")
    local mod = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod(abil) or 0
    local pb = HarfordDnDCalc and HarfordDnDCalc.GetSpellPB and HarfordDnDCalc.GetSpellPB() or 0
    local bonus = HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetBonus
        and HarfordDnDFeatureEffects.GetBonus("spellDC") or 0
    return 8 + mod + pb + bonus
end

local function OpenPowerWordChoice(anchor, feature)
    if not (UIDropDownMenu_Initialize and UIDropDownMenu_CreateInfo and UIDropDownMenu_AddButton
        and ToggleDropDownMenu and HarfordDnDBook and HarfordDnDBook.GetChoiceOptions) then return end
    local menu = _G.HarfordPowerWordChoiceMenu
    if not menu then
        menu = CreateFrame("Frame", "HarfordPowerWordChoiceMenu", UIParent, "UIDropDownMenuTemplate")
    end
    UIDropDownMenu_Initialize(menu, function()
        for _, option in ipairs(HarfordDnDBook.GetChoiceOptions(feature) or {}) do
            local selected = option
            local info = UIDropDownMenu_CreateInfo()
            info.text = selected.label
            info.checked = GetPowerWordOption(feature) and GetPowerWordOption(feature).id == selected.id
            info.func = function()
                HarfordDnDProgression.SetChoiceSlot(feature.id, 1, selected.id, GetProfileName())
                if RefreshPanel then RefreshPanel() end
                if RefreshBook then RefreshBook() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, menu, anchor, 0, 0)
end

-- Nivel del jugador en una clase concreta (0 si no la tiene).
local function ClassLevelOf(classId)
    if not classId then return 0 end
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(GetProfileName()) or {}) do
        if entry.classId == classId then return tonumber(entry.level) or 0 end
    end
    return 0
end

-- Un area declarada en los datos NO puede llevar CD ni dano escritos: dependen de la ficha de
-- quien la usa (nivel de clase y caracteristica de lanzamiento). Se rellenan aqui sobre una COPIA,
-- porque la tabla del libro es compartida por todos los personajes de la sesion.
--
-- `damageFrom` cubre el dano FIJO de 5e ("tu nivel de Monje mas tu Mod. Sabiduria" del Aliento de
-- Fuego, "el doble de tu nivel de Cazador" de la trampa explosiva), que no es una tirada de dados.
local function ResolveAreaValues(feature)
    if type(feature) ~= "table" or type(feature.area) ~= "table" then return feature end
    local area = {}
    for k, v in pairs(feature.area) do area[k] = v end
    -- El motor de areas cobra `area.resourceKey`, no el del rasgo. Un brebaje declara su chi en el
    -- rasgo, asi que si el area no trae coste propio hereda el suyo.
    if area.resourceKey == nil and feature.resourceKey then
        area.resourceKey = feature.resourceKey
        area.resourceCost = feature.resourceCost
    end
    if area.resolution == "save" and not tonumber(area.dc) then
        area.dc = OptionSaveDC(feature, nil)
    end
    if area.conditionSaveAbility and not tonumber(area.conditionSaveDC) then
        area.conditionSaveDC = OptionSaveDC(feature, nil)
    end
    if area.conditionApplySaveAbility and not tonumber(area.conditionApplySaveDC) then
        area.conditionApplySaveDC = OptionSaveDC(feature, nil)
    end
    -- `damageDiceFrom`: los dados escalan con el nivel de clase (la Maldicion de la Agonia pasa de
    -- 1d4 a 2d4, 3d4 y 4d4). El escalon se declara como { nivel, cantidad }, de menor a mayor.
    local dados = area.damageDiceFrom
    if type(dados) == "table" then
        local nivel, cantidad = ClassLevelOf(dados.classLevel), tonumber(dados.count) or 1
        for _, escalon in ipairs(dados.scale or {}) do
            if nivel >= (tonumber(escalon[1]) or 0) then cantidad = tonumber(escalon[2]) or cantidad end
        end
        area.damageComponents = { {
            damageDice = tostring(cantidad) .. "d" .. tostring(tonumber(dados.die) or 4),
            damageType = dados.damageType,
        } }
        area.damageDiceFrom = nil
    end
    -- `damageBonusFrom`: suma fija a los dados ya declarados (el Martillo de Luz hace "2d10 mas tu
    -- nivel de paladin"). No sustituye los dados, a diferencia de `damageFrom`.
    local bono = area.damageBonusFrom
    if type(bono) == "table" and type(area.damageComponents) == "table" then
        local extra = math.floor(ClassLevelOf(bono.classLevel) * (tonumber(bono.multiplier) or 1))
        if bono.abilityMod and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
            extra = extra + (HarfordDnDCalc.GetAbilityMod(bono.abilityMod) or 0)
        end
        local copia = {}
        for i, comp in ipairs(area.damageComponents) do
            local c = {}
            for k, v in pairs(comp) do c[k] = v end
            if i == 1 then c.damageBonus = (tonumber(c.damageBonus) or 0) + extra end
            copia[i] = c
        end
        area.damageComponents = copia
        area.damageBonusFrom = nil
    end
    local from = area.damageFrom
    if type(from) == "table" then
        local total = math.floor(ClassLevelOf(from.classLevel) * (tonumber(from.multiplier) or 1))
        if from.abilityMod and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
            total = total + (HarfordDnDCalc.GetAbilityMod(from.abilityMod) or 0)
        end
        total = total + (tonumber(from.flat) or 0)
        area.damageComponents = { { fixedAmount = math.max(1, total), damageType = from.damageType } }
        area.damageFrom = nil
    end
    local copia = {}
    for k, v in pairs(feature) do copia[k] = v end
    copia.area = area
    return copia
end

-- TRAMPAS DEL CAZADOR. Una trampa no se resuelve al pulsarla: se COLOCA con una accion, gastando
-- un uso, y se dispara mas tarde cuando alguien la pisa. Son dos momentos distintos y el cliente no
-- puede observar el segundo, asi que lo dice el jugador.
--
-- No se lleva registro de las trampas puestas: sobreviven a un /reload, a un cambio de zona y a una
-- sesion entera, asi que un contador local mentiria mas de lo que ayudaria. El uso se descuenta al
-- colocarla, que es donde el manual lo pone.
-- Cantidades que dependen de la ficha y que la habilidad NO puede repartir sola: los 5 PG por
-- nivel de la Luz del Amanecer, que el paladin reparte entre quien quiera, o los PG temporales que
-- Consagracion da a los aliados que elija. Fingir un reparto seria inventarse la regla, asi que se
-- calcula el numero y se dice en voz alta; el reparto lo hace el jugador.
local function AnunciarValoresDerivados(feature)
    for _, v in ipairs(feature.announceValues or {}) do
        local total = math.floor(ClassLevelOf(v.classLevel) * (tonumber(v.multiplier) or 1))
        if v.abilityMod and HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod then
            total = total + (HarfordDnDCalc.GetAbilityMod(v.abilityMod) or 0)
        end
        total = math.max(0, total + (tonumber(v.flat) or 0))
        if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
            HarfordDnDRolls.Broadcast({ type = "info",
                label = "|cffffd100" .. tostring(total) .. "|r " .. tostring(v.label or "") })
        end
    end
end

-- CARGA QUE SE LLEVA ENCIMA: las piedras del Brujo. Forjarla y gastarla son dos momentos, y entre
-- uno y otro la llevas puesta -- Harford no tiene inventario para un objeto asi, de modo que lo que
-- representa llevarla es un ESTADO. El mismo boton hace las dos cosas segun si la llevas o no.
--
-- Al gastarla se aplica lo que declare `grant`, si declara algo; las que modifican un conjuro
-- (Fuego, Conjuro, Alma) solo se anuncian, porque lo que hacen le pasa al conjuro y el cliente no
-- lo sostiene.
local function UsarCargaLlevada(feature)
    local carga = feature.carriedCharge
    if not (HarfordDnDConditions and HarfordDnDConditions.ApplyOwned) then
        HarfordChat.Print("El sistema de condiciones no esta disponible.")
        return false
    end
    local llevada = HarfordDnDConditions.Has and HarfordDnDConditions.Has("player", carga.condition)

    if not llevada then
        local ok, err = SpendPowerWord(feature)
        if not ok then HarfordChat.Print(err); return false end
        local aplicado, aplErr = HarfordDnDConditions.ApplyOwned(carga.condition, {
            duration = "manual",
            sourceName = HarfordClassColors.UnitFullName("player"),
        })
        if not aplicado then
            local key, cost = tostring(feature.resourceKey or ""), tonumber(feature.resourceCost) or 0
            if key ~= "" and cost > 0 and HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
                HarfordDnDStore.AdjustResourceCurrent(key, cost)
            end
            HarfordChat.Print(tostring(aplErr or "No se pudo forjar la piedra."))
            return false
        end
        AnnounceAbility(feature)
        if RefreshGameUI then RefreshGameUI() end
        return true
    end

    -- Gastarla. El recurso ya se pago al forjarla, asi que la opcion que se pasa no declara coste.
    HarfordDnDConditions.RemoveOwned(carga.condition)
    if type(carga.grant) == "table" then
        ApplyPowerWordGrant(feature, { grant = carga.grant, label = feature.name }, feature)
    else
        AnnounceAbility(feature)
    end
    if RefreshGameUI then RefreshGameUI() end
    return true
end

-- Rasgos que se usan DESPUES de tirar: los dados de enfoque del Cazador. La mecanica es de
-- `HarfordDnDRolls`; aqui solo se cobra el recurso y se decide cual de las dos formas es.
--
-- El recurso se cobra al final A PROPOSITO: si no hay una tirada reciente que mejorar, el rasgo no
-- hace nada y el dado no se pierde.
local function UsarModificadorDeTirada(feature)
    local mod = feature.rollModifier
    if not (HarfordDnDRolls and HarfordDnDRolls.ModifyLastRoll) then
        HarfordChat.Print("El sistema de tiradas no esta disponible.")
        return false
    end
    local spec = {
        label = mod.label or feature.name, die = mod.die, amount = mod.amount,
        half = mod.half, applies = mod.applies, markKey = mod.markKey,
        valueLabel = mod.valueLabel,
    }
    if mod.reroll and not (HarfordDnDRolls and HarfordDnDRolls.RerollLastHeal) then
        HarfordChat.Print("El sistema de tiradas no sabe repetir curaciones.")
        return false
    end
    -- Sin `applies` no corrige nada: solo tira el dado y dice el numero, porque lo que modifica
    -- (tu CA, una CD de concentracion, el dano de tu mascota) no lo lleva el cliente.
    local puede = HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
        and HarfordDnDStore.GetResourceCurrent(tostring(feature.resourceKey or ""))
        >= (tonumber(feature.resourceCost) or 0)
    if not puede then
        HarfordChat.Print("No tienes recurso suficiente para " .. tostring(feature.name) .. ".")
        return false
    end
    local ok, nuevo, err, anterior
    if mod.reroll then
        -- Repetir no es sumar: se vuelven a tirar los dados y vale el resultado nuevo.
        ok, nuevo, err, anterior = HarfordDnDRolls.RerollLastHeal(spec)
        -- La curacion ya se habia aplicado: se ajusta SOLO la diferencia, y unicamente si fue a
        -- parar a uno mismo. Sobre la de otro no se puede: sus dados nunca llegan a este cliente.
        if ok then
            local last = HarfordDnDRolls.GetLastRoll and HarfordDnDRolls.GetLastRoll()
            if last and last.aplicadoA == "self" and HarfordDnDStore
                and HarfordDnDStore.AdjustResourceCurrent then
                local delta = (tonumber(nuevo) or 0) - (tonumber(anterior) or 0)
                if delta ~= 0 then HarfordDnDStore.AdjustResourceCurrent("health", delta) end
            end
        end
    elseif mod.applies then
        ok, nuevo, err = HarfordDnDRolls.ModifyLastRoll(spec)
    else
        ok, nuevo, err = HarfordDnDRolls.AnnounceRollValue(spec)
    end
    if not ok then
        HarfordChat.Print(tostring(err or "No se pudo usar ese rasgo") .. ".")
        return false
    end
    local ok2, err2 = SpendPowerWord(feature)
    if not ok2 then HarfordChat.Print(err2) end
    if RefreshGameUI then RefreshGameUI() end
    return true
end

-- ACCIONES BASICAS (Esquivar, Correr, Desengancharse, Esconderse).
--
-- Lo que cuesta y lo que hace son cosas distintas. El COSTE puede abrirlo un rasgo de clase -- la
-- Accion Astuta del Picaro deja tomarlas como accion adicional -- y entonces se pregunta; con un
-- solo coste posible se usa directamente, sin molestar.
--
-- El EFECTO es el que declare la accion: un estado propio (Esquivar), una prueba de habilidad
-- (Esconderse) o ninguno (Correr y Desengancharse, que el addon no modela y lo dicen).
local AbrirAccionBasica

-- Rasgos que conceden ATAQUES de verdad, no una nota en el chat: Punos de Furia hace dos golpes
-- desarmados. Se disparan por la ruta normal de ataque de arma, asi que traen consigo lo que ya
-- sabe hacer -- CA del objetivo, criticos, Artes Marciales subiendo el dado del desarmado,
-- mitigacion del defensor y animacion -- en vez de reimplementar nada de eso aqui.
local function UsarAtaquesExtra(feature)
    local spec = feature.extraAttacks
    if not (HarfordDnDStore and HarfordDnDStore.AttackWithBlock and HarfordDnDStore.GetWeaponDef) then
        HarfordChat.Print("El sistema de ataques no esta disponible.")
        return false
    end
    if not (UnitExists and UnitExists("target")) then
        HarfordChat.Print(tostring(feature.name or "Ese rasgo") .. " necesita un objetivo.")
        return false
    end
    local def = HarfordDnDStore.GetWeaponDef(spec.weaponKey or "Desarmado")
    if not def then
        HarfordChat.Print("No se encontro el arma " .. tostring(spec.weaponKey or "Desarmado") .. ".")
        return false
    end

    local ok, err = SpendPowerWord(feature)
    if not ok then HarfordChat.Print(err); return false end
    AnnounceAbility(feature)
    for _ = 1, math.max(1, math.floor(tonumber(spec.count) or 1)) do
        -- `suppressAbilityDamage = false`: un golpe desarmado del Monje SI suma su modificador.
        -- El valor por defecto de `AttackWithBlock` es para ataques de bloque y acompanantes.
        HarfordDnDStore.AttackWithBlock(def, { suppressAbilityDamage = false })
    end
    if RefreshGameUI then RefreshGameUI() end
    return true
end

-- Rasgos que actuan SOBRE EL ULTIMO CONJURO ya lanzado: apuntar a una segunda criatura (Caos) o
-- redirigirlo si fallo (Quemar alma: Rebotar). No lo relanzan -- el conjuro ya se pago --: vuelven
-- a resolver su efecto contra otro objetivo a cambio del recurso del rasgo.
--
-- El recurso se cobra al FINAL: si no hay un conjuro reciente al que agarrarse, el rasgo no hace
-- nada y el fragmento no se pierde.
local function UsarSobreUltimoConjuro(feature)
    local spec = feature.recastLastSpell
    local api = _G.HarfordCompendioAPI
    if not (api and api.RecastLastSingleTarget) then
        HarfordChat.Print("El compendio de conjuros no esta disponible.")
        return false
    end
    if not (UnitExists and UnitExists("target")) then
        HarfordChat.Print(tostring(feature.name or "Ese rasgo") .. " necesita un objetivo nuevo.")
        return false
    end
    local ok, err = api.RecastLastSingleTarget(spec.markKey or feature.id, feature.name)
    if not ok then
        HarfordChat.Print("|cffff5555" .. tostring(err) .. ".|r")
        return false
    end
    local cobrado, cobroErr = SpendPowerWord(feature)
    if not cobrado then HarfordChat.Print(cobroErr) end
    AnnounceAbility(feature)
    if RefreshGameUI then RefreshGameUI() end
    return true
end

-- LANZAR UN RITUAL gastando un recurso propio (Ritos de alma del Brujo: un fragmento de alma).
--
-- El ritual no consume espacio de conjuro -- por eso `free` --: lo que se paga es el recurso del
-- rasgo. Se ofrecen solo los conjuros de esa clase con etiqueta de ritual y de un nivel que ya
-- puedas lanzar, que es lo que dice el rasgo.
local AbrirRitualDeRasgo

-- Un rasgo que se pone a UNO MISMO un estado con duracion (el Brebaje de Piel de Hierro y su
-- resistencia de 1 minuto). Se modela como condicion y no como bono suelto porque asi caduca sola
-- por rondas, se ve en la lista de estados y viaja al resto de clientes.
local function AplicarEstadoPropio(feature)
    local est = feature.selfCondition
    if not (HarfordDnDConditions and HarfordDnDConditions.ApplyOwned) then
        HarfordChat.Print("El sistema de condiciones no esta disponible.")
        return false
    end
    local ok, err = SpendPowerWord(feature)   -- el rasgo declara su propio recurso
    if not ok then HarfordChat.Print(err); return false end
    local aplicado, aplErr = HarfordDnDConditions.ApplyOwned(est.id, {
        duration = est.duration, turns = est.turns,
        sourceName = HarfordClassColors.UnitFullName("player"),
    })
    if not aplicado then
        -- Devolver el recurso: se gasto antes de saber que el estado no entraba.
        local key, cost = tostring(feature.resourceKey or ""), tonumber(feature.resourceCost) or 0
        if key ~= "" and cost > 0 and HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
            HarfordDnDStore.AdjustResourceCurrent(key, cost)
        end
        HarfordChat.Print(tostring(aplErr or "No se pudo aplicar el estado."))
        return false
    end
    AnnounceAbility(feature)
    AnunciarValoresDerivados(feature)
    if RefreshGameUI then RefreshGameUI() end
    return true
end

-- Un rasgo que concede "los efectos del conjuro X": los brebajes del Monje que replican Contorno
-- borroso, Acelerar y Libertad de movimiento. Lo lanza el COMPENDIO, no una copia de sus reglas
-- aqui, asi que trae consigo su duracion, su concentracion y su anuncio reales.
--
-- Va con `free`: el coste ya se pago con el recurso del rasgo (chi), y un Monje no tiene ni mana
-- ni espacios de conjuro con los que pagarlo otra vez.
local function LanzarConjuroDeRasgo(feature)
    local api = _G.HarfordCompendioAPI
    if not (api and api.ResolveCast and api.GetSpellById) then
        HarfordChat.Print("El compendio de conjuros no esta disponible.")
        return false
    end
    if not api.GetSpellById(feature.castsSpell) then
        HarfordChat.Print("El conjuro de " .. tostring(feature.name or "ese rasgo")
            .. " no esta en el compendio todavia.")
        return false
    end
    local ok, err = SpendPowerWord(feature)   -- el rasgo declara su propio resourceKey/resourceCost
    if not ok then HarfordChat.Print(err); return false end
    local lanzado, castErr = api.ResolveCast(feature.castsSpell, { free = true })
    if not lanzado then
        -- Devolver el recurso: se gasto antes de saber que el lanzamiento no salia.
        local key, cost = tostring(feature.resourceKey or ""), tonumber(feature.resourceCost) or 0
        if key ~= "" and cost > 0 and HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
            HarfordDnDStore.AdjustResourceCurrent(key, cost)
        end
        HarfordChat.Print(tostring(castErr or "No se pudo lanzar el conjuro."))
        return false
    end
    AnnounceAbility(feature)
    if RefreshGameUI then RefreshGameUI() end
    return true
end

-- Abre el area de un rasgo cuyo coste YA se ha cobrado en otra ruta (la trampa gasto su uso al
-- colocarse; la Maldicion gasto su Corrupcion al invocarse). Sin `onCommit`, por eso.
local function AbrirAreaDeRasgo(feature)
    if not (HarfordDnDArea and HarfordDnDArea.Open) then return false end
    local definition, err = HarfordDnDArea.DefinitionFromFeature(ResolveAreaValues(feature))
    if not definition then
        HarfordChat.Print(tostring(err or "Definicion de area incompleta."))
        return false
    end
    -- Objetivo unico se resuelve solo, como un ataque normal; un area de verdad abre la ventana.
    local resolucionUnica = definition.shape == "other" and definition.sizeText == "Objetivo"
    HarfordDnDArea.Open(definition, {
        sourceKind = "player",
        sourceGuid = UnitGUID and UnitGUID("player") or nil,
        abilityFeature = feature,
        autoResolve = resolucionUnica or nil,
    })
    return true
end
API.AbrirAreaDeRasgo = AbrirAreaDeRasgo

local AbrirMenuTrampa
do
    local menu, trampa, anclaje
    AbrirMenuTrampa = function(feature, anchor)
        if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then return end
        menu = menu or CreateFrame("Frame", "HarfordTrapMenu", UIParent, "UIDropDownMenuTemplate")
        trampa, anclaje = feature, anchor
        UIDropDownMenu_Initialize(menu, function()
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Colocar (gasta un uso)"
            info.notCheckable = true
            info.disabled = not FeatureUseAvailable(trampa)
            info.func = function()
                CloseDropDownMenus()
                -- Anuncio sin area: colocarla no hace nada a nadie todavia. `AnnounceAbility`
                -- gasta el uso porque el rasgo declara `usesFrom`.
                AnnounceAbility(trampa)
            end
            UIDropDownMenu_AddButton(info)

            info = UIDropDownMenu_CreateInfo()
            info.text = "Se ha activado (resolver)"
            info.notCheckable = true
            info.disabled = type(trampa.area) ~= "table"
            info.func = function()
                CloseDropDownMenus()
                AbrirAreaDeRasgo(trampa)   -- el uso ya se gasto al colocarla
            end
            UIDropDownMenu_AddButton(info)
        end, "MENU")
        ToggleDropDownMenu(1, nil, menu, anclaje or "cursor", 0, 0)
    end
end

-- Constructor UNICO de area para las opciones elegidas (Palabras de Poder, brebajes del Monje,
-- trampas del Cazador). Antes habia dos funciones casi identicas que solo diferian en valores
-- declarados. Lo que cambia lo dice la OPCION: si trae una tabla `area` completa se usa tal cual
-- (cono, esfera, dano) y solo se le rellena la CD; si no, se construye el area de objetivo unico
-- a partir de `resolution`, `saveAbility`, `applicationCountAbility` y `sizeText`.
local function OpenPowerWordArea(feature, option)
    if not (HarfordDnDArea and HarfordDnDArea.Open) then
        HarfordChat.Print("El motor de areas no esta disponible.")
        return
    end
    local display = PowerWordDisplayFeature(feature, option)
    local area, resolucion
    if type(option.area) == "table" then
        -- Copia: la tabla del libro es compartida y la CD depende de la ficha de quien la usa.
        area = {}
        for k, v in pairs(option.area) do area[k] = v end
        resolucion = area.resolution
    else
        resolucion = option.resolution or (option.saveAbility and "save" or "auto")
        area = {
            shape = "other",
            sizeText = option.sizeText or (option.applicationCountAbility and "Objetivos" or "Objetivo"),
            resolution = resolucion,
            conditionId = option.conditionId,
            conditionDuration = option.conditionDuration or "target_turn_end",
        }
        if resolucion == "save" then
            area.saveAbility = option.saveAbility
            area.success = "none"
        end
    end
    -- La CD nunca se declara en los datos: sale de la ficha de quien usa la habilidad.
    if resolucion == "save" and not tonumber(area.dc) then
        area.dc = OptionSaveDC(feature, option)
    end
    if area.conditionSaveAbility and not tonumber(area.conditionSaveDC) then
        area.conditionSaveDC = OptionSaveDC(feature, option)
    end
    -- Fortaleza afecta a tantas criaturas como tu Mod. de Carisma (minimo 1).
    if option.applicationCountAbility then
        local mod = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod
            and HarfordDnDCalc.GetAbilityMod(option.applicationCountAbility) or 1
        area.applicationCount = math.max(1, mod)
    end
    local opened, err = HarfordDnDArea.Open({ name = display.name, area = area }, {
        sourceKind = "player",
        sourceGuid = UnitGUID and UnitGUID("player") or "",
        sourceName = HarfordDnDRolls and HarfordDnDRolls.GetDisplayName and HarfordDnDRolls.GetDisplayName()
            or HarfordClassColors.UnitFullName("player"),
        -- Objetivo unico se resuelve solo, como un ataque normal. Un area de verdad (el cono del
        -- Aliento de Fuego) o varias criaturas (Fortaleza) abren la ventana para marcarlas.
        autoResolve = (resolucion == "save" and area.shape == "other"
            and not area.applicationCount and area.sizeText ~= "Objetivos") or nil,
        onCommit = function()
            local ok, spendErr = SpendPowerWord(option)
            if ok then AnnounceAbility(display) end
            return ok, spendErr
        end,
    })
    if not opened then HarfordChat.Print(tostring(err or "No se pudo resolver esa habilidad.")) end
end

-- Entrega una cantidad de un recurso al objetivo: a uno mismo directo, a otro jugador por red.
-- Estaba dentro de la concesion de Palabra de Poder; se saca porque la Niebla Calmante del Monje
-- hace lo mismo con una cantidad que elige el jugador, y copiarlo daria dos versiones que un dia
-- dejarian de coincidir. Devuelve false si no se pudo entregar, para poder devolver lo gastado.
local function EntregarAObjetivo(recurso, cantidad, nombreEfecto)
    if UnitIsUnit and UnitIsUnit("target", "player") then
        HarfordDnDStore.AdjustResourceCurrent(recurso, cantidad)
        return true
    end
    if not (HarfordDnDNet and HarfordDnDNet.SendResourceAdjustToPlayer) then return false end
    local targetName = HarfordClassColors.UnitFullName("target")
    if not HarfordDnDNet.SendResourceAdjustToPlayer(targetName, recurso, cantidad) then
        HarfordChat.Print("No se pudo enviar " .. tostring(nombreEfecto) .. " al objetivo.")
        return false
    end
    return true
end

-- Un objetivo valido para curar o reforzar: tiene que existir y ser JUGADOR. Un NPC lo gestiona su
-- ficha de DM, que es quien puede tocarle la vida en el servidor.
local function ObjetivoDeApoyoValido(nombreEfecto, quien)
    if not (UnitExists and UnitExists("target")) then
        HarfordChat.Print(tostring(quien) .. " requiere un objetivo.")
        return false
    end
    if not (UnitIsPlayer and UnitIsPlayer("target")) then
        HarfordChat.Print("La " .. tostring(nombreEfecto) .. " de un NPC debe gestionarla su ficha de DM.")
        return false
    end
    return true
end

-- Concesion directa de un recurso a un jugador objetivo (Escudo = vida temporal, Consuelo =
-- curacion). Eran dos funciones identicas salvo el recurso, la formula y el sustantivo de los
-- avisos: ahora los declara la OPCION en `grant`. Un NPC no se toca: lo gestiona su ficha de DM.
ApplyPowerWordGrant = function(feature, option, display)
    local grant = option.grant
    if type(grant) ~= "table" then return end
    -- LOS USOS SE MIRAN AQUI, ANTES DE CONCEDER NADA. El guardia estaba solo dentro de
    -- `AnnounceAbility`, que se llama al FINAL: con el contador a cero, la Reserva de ira te daba
    -- sus puntos y despues avisaba de que no te quedaban usos. Un rasgo agotado no puede tener
    -- efecto, asi que la comprobacion va antes que el efecto y no despues.
    local conUsos = display or feature
    if conUsos and (conUsos.uses or conUsos.usesFrom) and not FeatureUseAvailable(conUsos) then
        WarnFeatureWithoutUses(conUsos)
        return
    end
    local nombre = tostring(grant.noun or "el efecto")
    -- `self`: el efecto es sobre uno mismo (Brebaje Fortificante) y no mira el objetivo.
    if not grant.self and not ObjetivoDeApoyoValido(nombre, option.label or "Esta Palabra") then
        return
    end
    -- `amount`: cantidad fija, sin caracteristica ni nivel (Capturar Fragmento de Alma da uno).
    local amount = tonumber(grant.amount)
    -- `byClassLevel`: la cantidad la da una TABLA por nivel de clase, no una formula.
    if not amount and type(grant.byClassLevel) == "table" then
        local nivel = ClassLevelOf(grant.byClassLevel.classId)
        local valores = grant.byClassLevel.values or {}
        -- Se busca hacia abajo: la tabla solo anota los niveles en los que CAMBIA.
        while nivel > 0 and not valores[nivel] do nivel = nivel - 1 end
        amount = valores[nivel]
    end
    if not amount then
        amount = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod
            and HarfordDnDCalc.GetAbilityMod(grant.ability) or 0
        -- Escudo suma ademas la mitad de tu nivel de clase; Consuelo no declara esta parte.
        if grant.perClassLevel then
            local nivel = 0
            for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(GetProfileName()) or {}) do
                if entry.classId == grant.perClassLevel then nivel = tonumber(entry.level) or 0 break end
            end
            amount = amount + math.floor(nivel / (tonumber(grant.perLevelDiv) or 1))
        end
    end
    amount = math.max(1, amount)

    local ok, err = SpendPowerWord(option)
    if not ok then HarfordChat.Print(err); return end
    if grant.self then
        HarfordDnDStore.AdjustResourceCurrent(grant.resource, amount)
    elseif not EntregarAObjetivo(grant.resource, amount, nombre) then
        -- Devolver la Fe: se gasto antes de saber que el envio fallaba.
        HarfordDnDStore.AdjustResourceCurrent(option.resourceKey or "light_point", tonumber(option.resourceCost) or 0)
        return
    end
    AnnounceAbility(display or PowerWordDisplayFeature(feature, option))
    if RefreshGameUI then RefreshGameUI() end
    if RefreshBook then RefreshBook() end
end

local UsarReservaDeCuracion

local function UsePowerWord(feature, anchor)
    local parent = feature and (feature.powerWordParent or feature) or nil
    local option = GetPowerWordOption(feature)
    if not option then
        OpenPowerWordChoice(anchor, parent)
        HarfordChat.Print("Elige una opcion para Palabra de Poder.")
        return
    end
    -- Barrera no lleva rama propia: hacia exactamente lo mismo que el `else` final (gastar Fe y
    -- anunciar). No existe una ventana fiable entre impacto y daño para que el defensor confirme
    -- esa reaccion, asi que se resuelve en mesa y NO se deja preparada.
    -- Salvacion o aplicacion directa: lo decide lo que declara la opcion, no su id.
    if option.saveAbility or option.applicationCountAbility then
        OpenPowerWordArea(parent, option)
    -- Concede un recurso al objetivo (Escudo, Consuelo): lo declara la opcion.
    elseif type(option.grant) == "table" then
        ApplyPowerWordGrant(parent, option)
    elseif option.id == "muerte" then
        if not (HarfordDnDStore and HarfordDnDStore.PreparePowerWordDeath) then
            HarfordChat.Print("El sistema de dano de conjuros no esta disponible.")
            return
        end
        HarfordDnDStore.PreparePowerWordDeath(parent, option)
    else
        local ok, err = SpendPowerWord(option)
        if not ok then HarfordChat.Print(err); return end
        AnnounceAbility(PowerWordDisplayFeature(parent, option))
    end
    if RefreshBook then RefreshBook() end
end

-- Click en rasgo ACTIVO: anuncia su uso a la mesa con enlace clicable y, si es de uso
-- limitado, gasta un uso. (La mecanica de recurso/daño activable vive en la seccion Ataque.)
AnnounceAbility = function(feature, opciones)
    if not feature then return false end
    if (feature.uses or feature.usesFrom) and not FeatureUseAvailable(feature) then
        WarnFeatureWithoutUses(feature)
        return false
    end
    if feature.spendResourceOnAnnounce and not IsInspecting() then
        local key = tostring(feature.resourceKey or "")
        local cost = math.max(0, tonumber(feature.resourceCost) or 0)
        if key ~= "" and cost > 0 and HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
            and HarfordDnDStore.AdjustResourceCurrent
            and HarfordDnDStore.GetResourceCurrent(key) < cost then
            HarfordChat.Print("No hay recurso suficiente para " .. tostring(feature.name or "esta habilidad") .. ".")
            return false
        end
    end
    -- Enlace clicable real via TRP3 ChatLinks (los enlaces de tipo propio no son clicables en
    -- este cliente). Cae a texto de color si TRP3 no esta disponible.
    local link = (HarfordTRP3 and HarfordTRP3.GetAbilityChatLink and HarfordTRP3.GetAbilityChatLink(feature))
        or AbilityChatLink(feature)
    if HarfordDnDRolls and HarfordDnDRolls.BroadcastAbility then
        -- Si la economia dice que NO cabe, el anuncio devuelve false y el llamador tiene que
        -- pararse: antes se avisaba y la accion seguia adelante --tirada incluida--, que es
        -- exactamente no llevar economia.
        --
        -- `silencioso`: se cobra y se comprueba igual, pero no se difunde -- lo usa quien va a
        -- sacar su propia linea (una tirada con el nombre de la accion delante) y no quiere dos.
        if HarfordDnDRolls.BroadcastAbility(feature,
            { skipBroadcast = opciones and opciones.silencioso }) == false then return false end
    elseif HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info", label = link })
    elseif DEFAULT_CHAT_FRAME then
        HarfordChat.Print(link)
    end
    if (feature.uses or feature.usesFrom) and HarfordDnDFeatureUses and HarfordDnDFeatureUses.Spend
        and not IsInspecting() then
        HarfordDnDFeatureUses.Spend(feature.usesFrom or feature.id, GetProfileName())
        if RefreshBook then RefreshBook() end
    end
    if feature.spendResourceOnAnnounce and not IsInspecting() then
        local key = tostring(feature.resourceKey or "")
        local cost = math.max(0, tonumber(feature.resourceCost) or 0)
        if key ~= "" and cost > 0 and HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
            and HarfordDnDStore.AdjustResourceCurrent then
            HarfordDnDStore.AdjustResourceCurrent(key, -cost)
        end
    end
    if type(feature.resourceGain) == "table" and not IsInspecting()
        and HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
        local key = tostring(feature.resourceGain.key or "")
        local amount = math.max(0, tonumber(feature.resourceGain.amount) or 0)
        if key ~= "" and amount > 0 then HarfordDnDStore.AdjustResourceCurrent(key, amount) end
    end
    -- EMBESTIDA VIL (CdD Devoradora): rider sobre Momentum. Al usarlo con el rasgo desbloqueado
    -- se tira y publica el dado de Caos del recorrido; el anuncio de Momentum ya salio.
    if tostring(feature.id or "") == "dh_momentum" and not IsInspecting()
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("felRush")
        and HarfordDnDStore and HarfordDnDStore.AnnounceFelRush then
        HarfordDnDStore.AnnounceFelRush()
    end
    return true
end
-- (Extraidos a HarfordCharacterBookActions en la fase C; Build devuelve las funciones que
-- antes se asignaban aqui. Deps de funcion como closures: varias se asignan mas abajo.)
do
    local construidas = HarfordCharacterBookActions and HarfordCharacterBookActions.Build
        and HarfordCharacterBookActions.Build({
            API = API,
            Print = function(...) return Print(...) end,
            AnnounceAbility = function(...) return AnnounceAbility(...) end,
            RefreshBook = function(...) if RefreshBook then return RefreshBook(...) end end,
            RefreshGameUI = function(...) return RefreshGameUI(...) end,
            SpendPowerWord = function(...) return SpendPowerWord(...) end,
            GetProgression = function(...) return GetProgression(...) end,
            ClassLevelOf = function(...) return ClassLevelOf(...) end,
            EntregarAObjetivo = function(...) return EntregarAObjetivo(...) end,
            ObjetivoDeApoyoValido = function(...) return ObjetivoDeApoyoValido(...) end,
            GetFeatureUseState = function(...) return GetFeatureUseState(...) end,
            FeatureUseAvailable = function(...) return FeatureUseAvailable(...) end,
            GetProfileName = function(...) return GetProfileName(...) end,
            IsInspecting = function(...) return IsInspecting(...) end,
            WarnFeatureWithoutUses = function(...) return WarnFeatureWithoutUses(...) end,
            K = K,
            S = S,
            FeatureReactionTrigger = FeatureReactionTrigger,
            FeatureReactionEffect = FeatureReactionEffect,
            GetPowerWordOptionById = function(...) return GetPowerWordOptionById(...) end,
            PowerWordDisplayFeature = function(...) return PowerWordDisplayFeature(...) end,
            ResolveBookFeatureById = function(...) return ResolveBookFeatureById(...) end,
        }) or {}
    AbrirAccionBasica = construidas.AbrirAccionBasica
    AbrirRitualDeRasgo = construidas.AbrirRitualDeRasgo
    UsarReservaDeCuracion = construidas.UsarReservaDeCuracion
    OpenLayOnHandsPrompt = construidas.OpenLayOnHandsPrompt
    OpenDemonicFirePrompt = construidas.OpenDemonicFirePrompt
end

-- Colores/label de categoria -> HarfordCharacterBook (modulo). Alias locales.
K.BOOK_CAT_COLOR = HarfordCharacterBook.CAT_COLOR
local BookCategoryLabel = HarfordCharacterBook.CategoryLabel

local function BookFeatureDescription(feature, source, classId)
    if not (HarfordDnDBookText and HarfordDnDBookText.GetFeatureDescription) then
        return feature and feature.description or ""
    end
    local progression = GetProgression()
    return HarfordDnDBookText.GetFeatureDescription(feature, classId, source,
        progression and progression.background)
end

local function BookButtonOnEnter(self)
    if not (self.feature and GameTooltip) then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.feature.name or "?", 1, 1, 1, true)
    local cat = BookCategory(self.feature)
    -- Cabecera igual que el subtexto del boton: solo "<Categoria>  ·  Nivel N" (sin pista de click).
    local catTxt = BookCategoryLabel(cat, self.feature)
    if self.featLevel and self.featLevel > 0 then catTxt = catTxt .. "  ·  Nivel " .. self.featLevel end
    -- Los agregados (Competencias, Idiomas) tampoco llevan la categoria en el tooltip: su
    -- contenido es el listado, y "Pasiva" solo anade una linea vacia de informacion.
    -- Ni en los de ELECCION: lo que importa de ellos es que se eligio, no que sean pasivos.
    if not (API.IsAggregatedFeature(self.feature) or self.feature.choice) then
        local col = (HarfordCharacterBook.CategoryColor
            and HarfordCharacterBook.CategoryColor(cat, self.feature))
            or K.BOOK_CAT_COLOR[cat] or { 0.6, 0.8, 1 }
        GameTooltip:AddLine(catTxt, col[1], col[2], col[3])
    end
    local useText, useState = FeatureUseTooltipText(self.feature)
    if useText and useState then
        local r, g, b = 0.8, 0.8, 0.8
        if (tonumber(useState.available) or 0) <= 0 then r, g, b = 1, 0.25, 0.25 end
        GameTooltip:AddLine(useText, r, g, b)
    end
    local choiceText, pendingChoice = GetFeatureChoiceDisplay(self.feature, GetProfileName())
    if choiceText then
        local r, g, b = pendingChoice and 1 or 0.8, pendingChoice and 0.25 or 0.8, pendingChoice and 0.25 or 0.8
        -- Resuelta: solo lo elegido, con su separador. La etiqueta "Eleccion:" sobra cuando el
        -- contenido ya se explica solo. PENDIENTE si la conserva: "pendiente" a secas no dice
        -- nada, y ademas es el texto que fija el contrato del proyecto.
        GameTooltip:AddLine(pendingChoice and ("Eleccion: " .. choiceText) or choiceText, r, g, b)
    end
    if cat == "reaccion" then
        local trigger = FeatureReactionTrigger(self.feature)
        if trigger then
            GameTooltip:AddLine("Disparador: " .. (K.REACTION_TRIGGER_TEXT[trigger] or trigger), 0.8, 0.8, 0.8)
        end
    end
    -- Para rasgos de eleccion resueltos, la descripcion es la de la OPCION elegida (p.ej. el
    -- estilo de combate concreto), no la generica "Adoptas un estilo...".
    local descText = BookFeatureDescription(self.feature, self.source, self.classId)
    local opcionDesc
    if self.feature.choice and HarfordDnDProgression and HarfordDnDProgression.GetChoice
        and HarfordDnDBook and HarfordDnDBook.GetChoiceOptionDesc then
        local chosen = HarfordDnDProgression.GetChoice(self.feature.id, GetProfileName())
        if type(chosen) == "table" then
            for _, optId in ipairs(chosen) do
                local d = HarfordDnDBook.GetChoiceOptionDesc(self.feature, optId)
                if d then opcionDesc = d; break end
            end
        end
    end
    if opcionDesc then
        -- Resuelto: SOLO lo que hace la opcion elegida. Ni el texto del manual (enumera todas las
        -- opciones y contradice a la ya elegida) ni la introduccion del rasgo, que no anade nada
        -- cuando la eleccion ya se muestra arriba.
        descText = opcionDesc
        opcionDesc = nil
    end
    -- La descripcion de un agregado es un resumen PARCIAL heredado del rasgo de origen
    -- ("Competencia en Engano y Atletismo", "Hablas Comun y Darnassiano") que contradice al
    -- listado completo de abajo. No se muestra en ninguno de los dos.
    if descText and descText ~= "" and not API.IsAggregatedFeature(self.feature) then
        -- Dorado del tooltip nativo: titulo en blanco, descripcion en NORMAL_FONT_COLOR.
        local nf = NORMAL_FONT_COLOR
        GameTooltip:AddLine(descText, nf and nf.r or 1, nf and nf.g or 0.82, nf and nf.b or 0, true)
    end
    -- Competencias e Idiomas anaden su listado agregado.
    -- "Lista ampliada de conjuros": los nombres viven en `expandedSpells` de la SUBCLASE, no en el
    -- rasgo. Se leen de ahi para no tener la misma lista en dos sitios y que no puedan divergir.
    if self.feature.showsExpandedSpells and HarfordDnDBook and HarfordDnDBook.GetSubclass then
        local progression = GetProgression()
        for _, entry in ipairs((progression and progression.classLevels) or {}) do
            local sub = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
            if sub and type(sub.expandedSpells) == "table" and #sub.expandedSpells > 0 then
                GameTooltip:AddLine(" ")
                for _, nombre in ipairs(sub.expandedSpells) do
                    GameTooltip:AddLine("- " .. tostring(nombre), 0.8, 0.8, 0.8)
                end
                break
            end
        end
    end
    if API.AddAggregatedFeatureTooltip(self.feature) then
        -- (las lineas ya se han anadido)
    end
    GameTooltip:Show()
end

local function BookButtonOnClick(self)
    if not self.feature then return end
    -- Igual que los conjuros: Shift+click solo inserta el hyperlink TRP3 en el chat.
    -- No activa, consume ni prepara la habilidad.
    if IsShiftKeyDown and IsShiftKeyDown() then
        if not (HarfordTRP3 and HarfordTRP3.InsertAbilityChatLink
            and HarfordTRP3.InsertAbilityChatLink(self.feature)) then
            HarfordChat.Print("TRP3 no esta disponible para crear el enlace de esta habilidad.")
        end
        return
    end
    local cat = BookCategory(self.feature)
    local powerOption = HarfordCharacterBook.IsOptionAbility(self.feature) and GetPowerWordOption(self.feature) or nil

    -- ── UN RASGO AGOTADO NO HACE NADA ───────────────────────────────────────
    -- Se comprueba AQUI, una sola vez, antes de repartir a las veinticinco ramas de abajo. Cada
    -- una lo miraba por su cuenta o no lo miraba, y las que no acababan aplicando su efecto y
    -- avisando DESPUES -- la Reserva de ira daba sus puntos de ira con el contador a cero, porque
    -- el guardia vivia dentro del anuncio, que va al final. Un guardia por rama es un guardia que
    -- alguien olvidara en la siguiente.
    --
    -- Dos excepciones, las dos a proposito:
    --   `pasivo`  no gasta nada: es un tooltip.
    --   `trap`    colocar la trampa y que se dispare son momentos distintos. Si colocaste la
    --             ultima y luego salta, hay que poder resolverla con el contador ya a 0.
    if cat ~= "pasivo" and not self.feature.trap then
        local conUsos = self.feature
        if (conUsos.uses or conUsos.usesFrom) and not FeatureUseAvailable(conUsos) then
            WarnFeatureWithoutUses(conUsos)
            return
        end
    end

    -- ── Y EL COSTE DE TURNO, TAMBIEN AQUI ───────────────────────────────────
    -- Cobrarlo solo en el anuncio dejaba fuera todas las ramas que no anuncian: Imposicion de
    -- manos declaraba `cast = "accion"` y no gastaba nada, y con ella la familia `actionKind`
    -- entera (Tormenta divina, Penitencia, Rejuvenecimiento, Absolucion...). Aqui pasan TODAS.
    --
    -- Las que SI anuncian volverian a cobrar por el mismo gesto, asi que el click se marca: la
    -- segunda llamada devuelve lo que devolvio la primera y no toca nada.
    -- Las acciones BASICAS quedan fuera del cobro de click: su coste se elige DENTRO del menu
    -- (Correr puede ser accion, o adicional por Accion Astuta) y lo cobra el anuncio de la
    -- seleccion con el coste elegido. Cobrar aqui gastaba la ACCION al abrir el menu, eligieras lo
    -- que eligieras -- el anuncio posterior quedaba deduplicado por la marca de click y ya no
    -- corregia nada.
    if cat ~= "pasivo" and not self.feature.trap and not self.feature.basicAction
        and HarfordDnDConditions and HarfordDnDConditions.Turn then
        local T = HarfordDnDConditions.Turn
        if T.BeginClick then T.BeginClick(self.feature.id or self) end
        if T.SpendForFeature and T.SpendForFeature(self.feature) == false then return end
    end

    if cat ~= "pasivo" and HarfordDnDConditions and HarfordDnDConditions.CanPerform then
        local actionType = (cat == "reaccion" or (powerOption and powerOption.cast == "reaccion")) and "reaction" or "action"
        local allowed, condition = HarfordDnDConditions.CanPerform(actionType, { actorUnit = "player", targetUnit = "target" })
        if not allowed then
            if DEFAULT_CHAT_FRAME then
                HarfordChat.Print("No puedes usar esa habilidad: " .. tostring(condition or "condicion activa") .. ".")
            end
            return
        end
    end
    if cat == "forma" then
        if not (HarfordDnDForms and HarfordDnDForms.OpenMenu) then
            Print("El sistema de formas druidicas no esta disponible.")
            return
        end
        -- El icono de habilidad es el unico activador; la flecha solo indica
        -- que existe un flyout hacia la derecha.
        local opened, err = HarfordDnDForms.OpenMenu(self, function()
            RefreshGameUI()
            RefreshPanel()
            if RefreshBook then RefreshBook() end
        end)
        if not opened then Print(err or "No se pudo leer una forma druidica valida.") end
    elseif cat == "acompanante" then
        if not (HarfordDnDCompanions and HarfordDnDCompanions.OpenMenu) then
            Print("El sistema de criaturas acompanantes no esta disponible.")
            return
        end
        local opened, err = HarfordDnDCompanions.OpenMenu(self, function()
            RefreshGameUI()
            RefreshPanel()
            if RefreshBook then RefreshBook() end
            -- Tomar o soltar un nucleo demoniaco cambia que conjuros son tuyos, asi que la
            -- pestana de Conjuros tiene que repintarse si esta abierta.
            if HarfordCharacterSpellbook and HarfordCharacterSpellbook.RefreshSpells then
                HarfordCharacterSpellbook.RefreshSpells()
            end
        end)
        if not opened then Print(err or "No se pudo abrir el selector de criaturas.") end
    elseif self.feature.actionKind == "painSuppression" then
        if HarfordDnDStore and HarfordDnDStore.UsePainSuppression then
            HarfordDnDStore.UsePainSuppression(self.feature)
        end
    elseif self.feature.actionKind == "arcaneCharge" then
        if HarfordDnDStore and HarfordDnDStore.OpenArcaneChargeMenu then
            HarfordDnDStore.OpenArcaneChargeMenu(self.feature, self)
        end
    elseif self.feature.actionKind == "unleashedRage" then
        if HarfordDnDStore and HarfordDnDStore.ToggleUnleashedRage then
            HarfordDnDStore.ToggleUnleashedRage(self.feature)
        end
    elseif self.feature.actionKind == "flashOfLight" then
        if HarfordDnDStore and HarfordDnDStore.OpenFlashOfLight then
            HarfordDnDStore.OpenFlashOfLight(self.feature, self)
        end
    elseif self.feature.actionKind == "divineStorm" then
        if HarfordDnDStore and HarfordDnDStore.OpenDivineStorm then
            HarfordDnDStore.OpenDivineStorm(self.feature, self)
        end
    elseif self.feature.actionKind == "spearHand" then
        if HarfordDnDStore and HarfordDnDStore.OpenSpearHandMenu then
            HarfordDnDStore.OpenSpearHandMenu(self.feature, self)
        end
    elseif self.feature.actionKind == "chiJiPalm" then
        if HarfordDnDStore and HarfordDnDStore.UseChiJiPalm then
            HarfordDnDStore.UseChiJiPalm(self.feature)
        end
    elseif self.feature.actionKind == "windwalking" then
        if HarfordDnDStore and HarfordDnDStore.UseWindwalking then
            HarfordDnDStore.UseWindwalking(self.feature)
        end
    elseif self.feature.actionKind == "voidLegacy" then
        if HarfordDnDStore and HarfordDnDStore.UseVoidLegacy then
            HarfordDnDStore.UseVoidLegacy(self.feature)
        end
    elseif self.feature.actionKind == "penance" then
        -- Penitencia gasta HASTA 5 puntos y todo escala por punto: el desplegable pide modalidad,
        -- cuantos puntos y, si condena, el tipo de dano.
        if HarfordDnDStore and HarfordDnDStore.OpenPenanceMenu then
            HarfordDnDStore.OpenPenanceMenu(self.feature, self)
        end
    elseif self.feature.actionKind == "rejuvenation" then
        -- Cuantos d6 se gastan lo elige el jugador (tope: la mitad de su nivel de druida).
        if HarfordDnDStore and HarfordDnDStore.OpenRejuvenationMenu then
            HarfordDnDStore.OpenRejuvenationMenu(self.feature, self)
        end
    elseif self.feature.actionKind == "atonement" then
        if HarfordDnDStore and HarfordDnDStore.OpenAtonementMenu then
            HarfordDnDStore.OpenAtonementMenu(self.feature, self)
        end
    elseif self.feature.actionKind == "elementalFury" then
        -- Furia Elemental: elegir el tipo no es un lanzamiento, es configurar el siguiente.
        if HarfordDnDStore and HarfordDnDStore.OpenElementalFuryMenu then
            HarfordDnDStore.OpenElementalFuryMenu(self.feature, self)
        end
    elseif self.feature.actionKind == "slotConversion" then
        -- Lanzamiento Flexible / Devocion: el nivel del espacio se elige en un desplegable,
        -- porque el coste y lo que ganas dependen de el.
        if HarfordDnDStore and HarfordDnDStore.OpenSlotConversionMenu then
            HarfordDnDStore.OpenSlotConversionMenu(self.feature, self)
        end
    elseif cat == "poder" then
        UsePowerWord(self.feature, self)
    elseif type(self.feature.poolHeal) == "table" then
        UsarReservaDeCuracion(self.feature, self)
    elseif self.feature.basicAction then
        AbrirAccionBasica(self.feature.basicAction, self)
    elseif type(self.feature.extraAttacks) == "table" then
        UsarAtaquesExtra(self.feature)
        if RefreshBook then RefreshBook() end
    elseif type(self.feature.recastLastSpell) == "table" then
        UsarSobreUltimoConjuro(self.feature)
        if RefreshBook then RefreshBook() end
    elseif type(self.feature.ritualCast) == "table" then
        AbrirRitualDeRasgo(self.feature, self)
    elseif type(self.feature.carriedCharge) == "table" then
        UsarCargaLlevada(self.feature)
        if RefreshBook then RefreshBook() end
    elseif type(self.feature.grant) == "table" then
        -- El rasgo concede un recurso directamente (vida temporal del Brebaje Fortificante, la
        -- curacion de Efusion, el fragmento de Capturar Fragmento de Alma). El rasgo hace de
        -- opcion de si mismo, asi que se pasa como los tres argumentos.
        ApplyPowerWordGrant(self.feature, self.feature, self.feature)
    elseif type(self.feature.rollModifier) == "table" then
        UsarModificadorDeTirada(self.feature)
        if RefreshBook then RefreshBook() end
    elseif type(self.feature.announceValues) == "table" and not self.feature.area then
        -- Solo numeros: la habilidad no aplica nada por si misma (Luz del Amanecer reparte su
        -- curacion a mano), pero el numero sale de la ficha y hay que decirlo.
        if AnnounceAbility(self.feature) then AnunciarValoresDerivados(self.feature) end
        if RefreshBook then RefreshBook() end
    elseif type(self.feature.selfCondition) == "table" then
        AplicarEstadoPropio(self.feature)
        if RefreshBook then RefreshBook() end
    elseif self.feature.castsSpell then
        LanzarConjuroDeRasgo(self.feature)
        if RefreshBook then RefreshBook() end
    elseif self.feature.actionKind == "malediction" then
        -- Antes vivia dentro de `cat == "activo"`. Al declarar su area pasaron a categoria "area",
        -- que se resolveria sin gastar la Corrupcion ni ofrecer ampliarla.
        if not FeatureUseAvailable(self.feature) then
            WarnFeatureWithoutUses(self.feature)
            return
        end
        if HarfordDnDStore and HarfordDnDStore.OpenMaledictionMenu then
            HarfordDnDStore.OpenMaledictionMenu(self.feature, self)
        end
    elseif self.feature.trap then
        -- Colocarla y que se dispare son dos momentos distintos: lo decide el jugador. El menu NO
        -- exige usos disponibles: si colocaste la ultima y luego se dispara, hay que poder
        -- resolverla con el contador ya a 0.
        AbrirMenuTrampa(self.feature, self)
    elseif cat == "area" then
        if (self.feature.uses or self.feature.usesFrom) and not FeatureUseAvailable(self.feature) then
            WarnFeatureWithoutUses(self.feature)
            return
        end
        -- La CD y el dano por nivel se calculan AHORA: en los datos solo esta declarado de donde
        -- salen (`dcAbility`, `damageFrom`), porque dependen de la ficha de quien la usa.
        local resuelta = ResolveAreaValues(self.feature)
        local definition, err
        if HarfordDnDArea and HarfordDnDArea.DefinitionFromFeature then
            definition, err = HarfordDnDArea.DefinitionFromFeature(resuelta)
        end
        if not definition then
            if DEFAULT_CHAT_FRAME then
                HarfordChat.Print(tostring(err or "Definicion de area incompleta."))
            end
            return
        end
        HarfordDnDArea.Open(definition, {
            sourceKind = "player",
            sourceGuid = UnitGUID and UnitGUID("player") or nil,
            abilityFeature = self.feature,
            onCommit = function()
                if (self.feature.uses or self.feature.usesFrom) and not FeatureUseAvailable(self.feature) then return false, "No quedan usos." end
                local resourceKey, resourceCost = definition.resourceKey, tonumber(definition.resourceCost) or 0
                if resourceKey ~= "" and resourceCost > 0 then
                    if not (HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.AdjustResourceCurrent) then
                        return false, "Sistema de recursos no disponible."
                    end
                    if HarfordDnDStore.GetResourceCurrent(resourceKey) < resourceCost then
                        return false, "No hay recurso suficiente."
                    end
                end
                if (self.feature.uses or self.feature.usesFrom) and HarfordDnDFeatureUses
                    and HarfordDnDFeatureUses.Spend
                    and not HarfordDnDFeatureUses.Spend(self.feature.usesFrom or self.feature.id, GetProfileName()) then
                    return false, "No quedan usos."
                end
                if resourceKey ~= "" and resourceCost > 0 then HarfordDnDStore.AdjustResourceCurrent(resourceKey, -resourceCost) end
                AnunciarValoresDerivados(self.feature)
                if RefreshBook then RefreshBook() end
                return true
            end,
        })
    elseif cat == "al_accion" then
        if (self.feature.uses or self.feature.usesFrom) and not FeatureUseAvailable(self.feature) then
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
    elseif cat == "activo" or cat == "absolution" then
        if self.feature.actionKind == "layOnHands" then
            OpenLayOnHandsPrompt(self.feature)
            return
        end
        -- Maldicion del Brujo: pregunta si se amplia gastando un fragmento de alma. El uso de
        -- Corrupcion y el fragmento los descuenta OpenMaledictionMenu, no la ruta de anuncio.
        if self.feature.actionKind == "demonicFire" then
            OpenDemonicFirePrompt(self.feature)
            return
        end
        if self.feature.actionKind == "demonBite" then
            if not (HarfordDnDStore and HarfordDnDStore.UseDemonBite and HarfordDnDStore.UseDemonBite()) then
                return
            end
            if RefreshBook then RefreshBook() end
            return
        end
        if self.feature.actionKind == "secondWind" then
            if not (HarfordDnDStore and HarfordDnDStore.UseSecondWind and HarfordDnDStore.UseSecondWind()) then
                return
            end
            if RefreshBook then RefreshBook() end
            return
        end
        if self.feature.actionKind == "metamorphosis" then
            local profileName = GetProfileName()
            local active = HarfordDnDProgression.IsToggleStateActive("metamorphosis", profileName)
            if active then
                HarfordDnDProgression.SetToggleState("metamorphosis", false, profileName)
                if RefreshGameUI then RefreshGameUI() end
                if RefreshBook then RefreshBook() end
                return
            end
            if not AnnounceAbility(self.feature) then
                return
            end
            HarfordDnDProgression.SetToggleState("metamorphosis", true, profileName)
            local level = 0
            for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
                if entry.classId == "cazador_demonios" then level = tonumber(entry.level) or 0; break end
            end
            local intMod = HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod
                and HarfordDnDCalc.GetAbilityMod("Inteligencia") or 0
            local temp = math.max(1, level + intMod)
            HarfordDnDStore.AdjustResourceCurrent("temp_health", temp)
            if RefreshGameUI then RefreshGameUI() end
            if RefreshBook then RefreshBook() end
            return
        end
        if self.feature.actionKind == "elunesGrace" then
            if not (HarfordDnDStore and HarfordDnDStore.UseElunesGrace and HarfordDnDStore.UseElunesGrace()) then
                return
            end
            if RefreshGameUI then RefreshGameUI() end
            if RefreshBook then RefreshBook() end
            return
        end
        if self.feature.actionKind == "huntersMark" then
            if not (HarfordDnDStore and HarfordDnDStore.UseHuntersMark
                and HarfordDnDStore.UseHuntersMark(self.feature)) then
                return
            end
            if RefreshBook then RefreshBook() end
            return
        end
        local resourceKey = tostring(self.feature.resourceKey or "")
        local resourceCost = math.max(0, tonumber(self.feature.resourceCost) or 0)
        if resourceKey ~= "" and resourceCost > 0 then
            if not (HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
                and HarfordDnDStore.AdjustResourceCurrent) then
                HarfordChat.Print("El sistema de recursos no esta disponible.")
                return
            end
            if HarfordDnDStore.GetResourceCurrent(resourceKey) < resourceCost then
                HarfordChat.Print("No hay recurso suficiente para " .. tostring(self.feature.name or "esta habilidad") .. ".")
                return
            end
            HarfordDnDStore.AdjustResourceCurrent(resourceKey, -resourceCost)
        end
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
                    HarfordChat.Print(tostring(err or "No se pudo aplicar el estado."))
                end
            end
        end
    elseif cat == "reaccion" then
        -- Solo se preparan reacciones cuyo disparador y efecto pueda resolver
        -- Harford localmente. Las demas se usan de inmediato y se resuelven en
        -- mesa; no fingimos una intercepcion de red que no existe.
        if not (FeatureReactionTrigger(self.feature) and FeatureReactionEffect(self.feature)) then
            AnnounceAbility(self.feature)
            if RefreshBook then RefreshBook() end
            return
        end
        -- Toggle por id de rasgo (persiste aunque RefreshBook reconstruya los botones). Se queda
        -- activa hasta volver a clicarla o hasta que empiece tu turno (HarfordTurns la limpia).
        local id = self.feature.id or self.feature.name
        if id then
            S.activeReactions = S.activeReactions or {}
            if S.activeReactions[id] then
                local prior = S.activeReactions[id]
                S.activeReactions[id] = nil
                if FeatureReactionEffect(self.feature) == "reroll_attack" then
                    local protectedGuid = prior and prior.protectedGuid
                    if protectedGuid and HarfordDnDCombat and HarfordDnDCombat.SetPreparedAttackReaction then
                        HarfordDnDCombat.SetPreparedAttackReaction(protectedGuid, nil)
                    end
                    if protectedGuid and HarfordSync and HarfordSync.SendPreparedAttackReaction then
                        HarfordSync.SendPreparedAttackReaction("DND5EARC", id, protectedGuid, false)
                    end
                end
            elseif FeatureUseAvailable(self.feature) then
                local reactionResource = tostring(self.feature.resourceKey or "")
                local reactionCost = math.max(0, tonumber(self.feature.resourceCost) or 0)
                if reactionResource ~= "" and reactionCost > 0
                    and (not HarfordDnDStore or not HarfordDnDStore.GetResourceCurrent
                        or HarfordDnDStore.GetResourceCurrent(reactionResource) < reactionCost) then
                    HarfordChat.Print("No hay recurso suficiente para preparar " .. tostring(self.feature.name or "esta reaccion") .. ".")
                    return
                end
                local protectedGuid = UnitGUID and UnitGUID("target") or nil
                if not protectedGuid then protectedGuid = UnitGUID and UnitGUID("player") or nil end
                S.activeReactions[id] = {
                    trigger = FeatureReactionTrigger(self.feature),
                    protectedGuid = protectedGuid,
                }
                if FeatureReactionEffect(self.feature) == "reroll_attack" and protectedGuid then
                    if HarfordDnDCombat and HarfordDnDCombat.SetPreparedAttackReaction then
                        HarfordDnDCombat.SetPreparedAttackReaction(protectedGuid, HarfordClassColors.UnitFullName("player"))
                    end
                    if HarfordSync and HarfordSync.SendPreparedAttackReaction then
                        HarfordSync.SendPreparedAttackReaction("DND5EARC", id, protectedGuid, true)
                    end
                end
            else
                WarnFeatureWithoutUses(self.feature)
            end
        end
        if RefreshBook then RefreshBook() end
    end
    -- pasivo: nada
end

-- Activa una habilidad del Libro por su id, sin tener el boton del Libro delante. Lo usa la barra
-- de accion, que coloca habilidades en los botones nativos de Blizzard.
--
-- Reutiliza `BookButtonOnClick` en vez de repetir sus decisiones: categoria, condiciones que
-- impiden actuar, coste de recurso, area, reaccion preparada y anuncio. Son 338 lineas de reglas
-- que no deben existir dos veces.
--
-- `anchor` es el frame sobre el que abrir menus y flyouts (el propio boton de la barra).
function API.ActivarHabilidadPorId(featureId, anchor)
    local feature = ResolveBookFeatureById(featureId)
    if not feature then
        HarfordChat.Print("Esa habilidad ya no existe en tu ficha.")
        return false
    end
    -- Objeto minimo con la forma que espera el manejador del Libro.
    local falso = anchor or CreateFrame("Frame", nil, UIParent)
    falso.feature = feature
    BookButtonOnClick(falso)
    return true
end

-- Datos de presentacion para pintar la habilidad en un boton ajeno.
function API.DatosDeHabilidad(featureId)
    local feature = ResolveBookFeatureById(featureId)
    if not feature then return nil end
    -- GetFeatureIcon espera la TABLA del rasgo (dentro lee feature.id); pasarle el id como
    -- string devolvia nil sin error. Y IconPath(nil) devuelve "" -- truthy -- que ganaba el
    -- `or` y dejaba el icono de arrastre INVISIBLE: parecia que la habilidad no se arrastraba.
    local icono = HarfordDnDData and HarfordDnDData.GetFeatureIcon
        and HarfordDnDData.GetFeatureIcon(feature) or nil
    if (not icono or icono == "") and feature.icon then
        icono = HarfordCharacterBook.IconPath(feature.icon)
    end
    if icono == "" then icono = nil end
    return {
        name = feature.name,
        icon = icono or 134400,  -- INV_Misc_QuestionMark: mejor interrogante que invisible
        description = feature.description,
        feature = feature,
    }
end

K.BOOK_BTN = 37                 -- SpellButton 37x37
K.BOOK_COL_X = { 100, 325 }     -- columnas izq/der (SpellButton1 x=100, +225)
K.BOOK_ROW_Y0, K.BOOK_ROW_PITCH = -72, 66  -- primera fila (SpellButton1 y=-72) y pitch

local function CreateBookPage()
    local page = CreatePage("book")
    local host = S.skillsFrame

    -- Contenedor transparente (controla la visibilidad). Los botones se anclan al FRAME con
    -- offsets nativos; el fondo/pergamino son REGIONES del frame para que el retrato quede encima.
    local area = CreateFrame("Frame", nil, page)
    area:SetAllPoints(page)

    -- Fondo oscuro: 374155 es la roca de fondo. Rellena TODO el frame por detras para que nunca
    -- asome un hueco gris/transparente bajo el borde ni donde el pergamino no llegue.
    local body = host:CreateTexture(nil, "BACKGROUND", nil, -7)
    body:SetTexture(374155)
    body:SetTexCoord(0, 0.533203125, 0, 0.4902344048)
    body:SetAllPoints(host)
    body:Hide()

    -- Cuerpo del libro: Spellbook-Page-1 (375503) trae el pergamino, la cinta turquesa, las
    -- esquinas doradas y los bordes de madera. Cubre el interior a ras (deja sitio al cierre dcho).
    local lpage = host:CreateTexture(nil, "BACKGROUND", nil, -6)
    lpage:SetTexture("Interface\\Spellbook\\Spellbook-Page-1")
    lpage:SetTexCoord(0, 1, 0, 1)
    lpage:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -25)
    lpage:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -31, -15)
    lpage:Hide()

    -- Cierre lateral derecho: Spellbook-Page-2 (375504), tira vertical pegada al borde derecho
    -- de Page-1.
    local rpage = host:CreateTexture(nil, "BACKGROUND", nil, -5)
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
    for i = 1, K.BOOK_PER_PAGE do
        local b = CreateFrame("Button", nil, area)
        b:SetSize(K.BOOK_BTN, K.BOOK_BTN)
        -- Relleno column-major como el nativo: botones 1..6 columna izquierda (arriba->abajo),
        -- 7..12 columna derecha. RefreshBook llena buttons[i] en orden.
        local col = (i <= K.BOOK_ROWS) and 0 or 1
        local row = (i <= K.BOOK_ROWS) and (i - 1) or (i - 1 - K.BOOK_ROWS)
        b:SetPoint("TOPLEFT", host, "TOPLEFT", K.BOOK_COL_X[col + 1], K.BOOK_ROW_Y0 - row * K.BOOK_ROW_PITCH)

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
        -- Piezas exactas de ActionButtonTemplate cuando un boton abre un
        -- SpellFlyout. Solo se muestran mientras el selector esta abierto.
        b.formFlyoutShadow = b:CreateTexture(nil, "ARTWORK", nil, 0)
        b.formFlyoutShadow:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
        b.formFlyoutShadow:SetSize(48, 48)
        b.formFlyoutShadow:SetTexCoord(0.015625, 0.765625, 0.0078125, 0.3828125)
        b.formFlyoutShadow:SetPoint("CENTER", b, "CENTER")
        b.formFlyoutShadow:Hide()
        b.formFlyoutBorder = b:CreateTexture(nil, "ARTWORK", nil, 1)
        b.formFlyoutBorder:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
        b.formFlyoutBorder:SetSize(42, 42)
        b.formFlyoutBorder:SetTexCoord(0.015625, 0.671875, 0.3984375, 0.7265625)
        b.formFlyoutBorder:SetPoint("CENTER", b, "CENTER")
        b.formFlyoutBorder:Hide()
        -- La flecha nativa es solo un indicador del icono padre; el clic se
        -- queda en el propio boton de habilidad, nunca en una flecha aparte.
        b.formArrow = b:CreateTexture(nil, "OVERLAY", nil, 2)
        -- SetClampedTextureRotation(90) intercambia estas medidas a 11x23.
        -- Se conserva la base 23x11 de ActionBarFlyoutButton-ArrowUp.
        b.formArrow:SetSize(23, 11)
    b.formArrow:SetPoint("RIGHT", b, "RIGHT", 9, 0)
        -- Recorte y orientacion originales de SpellButton/FlyoutArrow.
        b.formArrow:SetTexture("Interface\\Buttons\\ActionBarFlyoutButton")
        b.formArrow:SetTexCoord(0.625, 0.984375, 0.7421875, 0.828125)
        if SetClampedTextureRotation then
            SetClampedTextureRotation(b.formArrow, 90)
        elseif b.formArrow.SetRotation then
            b.formArrow:SetRotation(math.pi / 2)
        end
        b.formArrow:Hide()
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
        -- Arrastrar a la barra de accion. La habilidad no es un hechizo real, asi que no vale
        -- `PickupSpell`: la carga la lleva HarfordActionBars con su propio icono de cursor.
        b:RegisterForDrag("LeftButton")
        b:SetScript("OnDragStart", function(self)
            local f = self.feature
            if not (f and f.id and HarfordActionBars and HarfordActionBars.RecogerHabilidad) then return end
            -- Una pasiva no tiene click que ejecutar: en la barra seria un boton muerto.
            if HarfordCharacterBook and HarfordCharacterBook.Category
                and HarfordCharacterBook.Category(f) == "pasivo" then return end
            HarfordActionBars.RecogerHabilidad(f.id)
        end)
        -- Soltar en el vacio no debe dejar el icono pegado al cursor. Se difiere un tick porque
        -- el `OnReceiveDrag` del boton de la barra corre en el mismo instante y necesita leerlo.
        b:SetScript("OnDragStop", function()
            if C_Timer and HarfordActionBars and HarfordActionBars.SoltarHabilidad then
                C_Timer.After(0, HarfordActionBars.SoltarHabilidad)
            end
        end)
        b:Hide()
        buttons[i] = b
    end

    -- Navegacion de pagina anclada al FRAME, como el nativo (Prev -66 / Next -31 / texto -110, y=26).
    local nxt = CreateFrame("Button", nil, area)
    nxt:SetSize(32, 32); nxt:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -31, 26)
    nxt:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nxt:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nxt:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nxt:SetScript("OnClick", function()
        -- RefreshBook es quien reajusta al maximo: se compara despues de refrescar.
        local antes = S.book.pageNum
        S.book.pageNum = antes + 1
        RefreshBook()
        if S.book.pageNum ~= antes then if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("book_page_turned") end end
    end)

    local prev = CreateFrame("Button", nil, area)
    prev:SetSize(32, 32); prev:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -66, 26)
    prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prev:SetScript("OnClick", function()
        -- En la primera pagina la flecha no hace nada: tampoco debe sonar.
        if S.book.pageNum > 1 then
            S.book.pageNum = S.book.pageNum - 1
            if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("book_page_turned") end
            RefreshBook()
        end
    end)

    local pageText = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -110, 38)

    S.book = { page = page, area = area, body = body, page1 = lpage, page2 = rpage,
               buttons = buttons, sideTabs = {}, prev = prev, nxt = nxt, pageText = pageText,
               section = 1, pageNum = 1 }
end

-- classId de Harford -> token de clase en ingles para el icono classicon_<token>.
K.CLASS_ICON_TOKEN = {
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
K.BOOK_GENERAL_ICON = "Interface\\Icons\\INV_Misc_Book_09"

-- Icono de la pestaña: General = libro fijo; clase/subclase = classicon_<clase>.
local function SectionIcon(sec)
    if sec and sec.isGeneral then return K.BOOK_GENERAL_ICON end
    if sec and sec.classId and sec.subclassId and HarfordDnDData and HarfordDnDData.GetSubclassIcon then
        local subclassIcon = HarfordDnDData.GetSubclassIcon(sec.classId, sec.subclassId)
        if subclassIcon then return subclassIcon end
    end
    if sec and sec.classId then
        local token = K.CLASS_ICON_TOKEN[sec.classId]
        if token then return "Interface\\Icons\\classicon_" .. token end
    end
    return K.BOOK_GENERAL_ICON
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
            tab:SetPoint("TOPLEFT", S.skillsFrame, "TOPRIGHT", -2, -36 - (i - 1) * 49)
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
            tab:SetScript("OnClick", function(self)
                if S.book.section ~= self._idx then if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("book_side_tab_changed") end end
                S.book.section = self._idx; S.book.pageNum = 1; RefreshBook()
            end)
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
    local pages = math.max(1, math.ceil(#feats / K.BOOK_PER_PAGE))
    if S.book.pageNum > pages then S.book.pageNum = pages end
    if S.book.pageNum < 1 then S.book.pageNum = 1 end
    local startI = (S.book.pageNum - 1) * K.BOOK_PER_PAGE
    for i = 1, K.BOOK_PER_PAGE do
        local b = S.book.buttons[i]
        local item = feats[startI + i]
        if item and item.feature then
            b.feature, b.featLevel, b.source = item.feature, item.level, item.source
            b.classId = sec.classId
            local cat = BookCategory(item.feature)
            -- Un icono declarado EXPLICITAMENTE en el Libro (p.ej. cada Palabra de Poder tiene el
            -- suyo) es AUTORITATIVO y gana al catalogo por-nombre. El catalogo (`GetFeatureIcon` ->
            -- `GetIcon` por nombre) colisiona entre homonimos: el hechizo "Escudo" y la Palabra de
            -- Poder "Escudo" son cosas distintas, y sin esta prioridad la Palabra tomaba el icono del
            -- hechizo. Solo sin icono declarado se recurre al catalogo TRP3 (mas especifico que los
            -- defaults de categoria).
            local declaredIcon = item.feature.icon
            if declaredIcon == "" then declaredIcon = nil end
            if declaredIcon and not tostring(declaredIcon):find("\\", 1, true) then
                declaredIcon = "Interface\\Icons\\" .. declaredIcon
            end
            local realIcon = declaredIcon
                or (HarfordDnDData and HarfordDnDData.GetFeatureIcon and HarfordDnDData.GetFeatureIcon(item.feature))
            local activeForm = cat == "forma" and HarfordDnDForms and HarfordDnDForms.GetActiveForm
                and HarfordDnDForms.GetActiveForm() or nil
            if activeForm and activeForm.icon then realIcon = activeForm.icon end
            local activeCompanion = cat == "acompanante" and HarfordDnDCompanions
                and HarfordDnDCompanions.GetActive and HarfordDnDCompanions.GetActive() or nil
            if activeCompanion and activeCompanion.icon then realIcon = activeCompanion.icon end
            -- Sosteniendo un nucleo no hay criatura, pero la fila debe decir cual llevas.
            local activeCore = (cat == "acompanante" and not activeCompanion) and HarfordDnDCompanions
                and HarfordDnDCompanions.GetActiveCore and HarfordDnDCompanions.GetActiveCore() or nil
            -- Se COMPRUEBA que exista: `SetTexture` con una ruta invalida deja la textura
            -- anterior, y como la fila viene de un pool, hereda el icono de la habilidad que
            -- ocupaba ese hueco antes. Es lo que llenaba la pagina del mismo dibujo.
            local respaldo = K.BOOK_ICON[cat] or K.BOOK_ICON.pasivo
            local final = realIcon or respaldo
            if type(final) == "string" and GetFileIDFromPath and not GetFileIDFromPath(final) then
                final = respaldo
            end
            b.icon:SetTexture(final)
            b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            b.icon:Show()
            -- Marco: pasivo (marron, detras); activo/al_accion (SlotFrame ENCIMA); reaccion (UnlearnedSlotFrame).
            local frameKey = (cat == "al_accion" or cat == "maniobra" or cat == "forma"
                or cat == "acompanante" or cat == "poder" or cat == "absolution") and "activo" or cat
            local fr = HarfordCharacterPanel._bookFrame[frameKey] or HarfordCharacterPanel._bookFrame.pasivo
            b.ring:SetTexCoord(fr.tc[1], fr.tc[2], fr.tc[3], fr.tc[4])
            b.ring:SetSize(fr.w, fr.h)
            b.ring:ClearAllPoints()
            b.ring:SetPoint("CENTER", b, "CENTER", fr.ox or 0, fr.oy or 0)
            b.ring:SetDrawLayer(cat == "pasivo" and "BACKGROUND" or "OVERLAY")
            b.ring:SetAlpha(1); b.bar:SetAlpha(1)
            -- En los rasgos de ELECCION se quita el sufijo entre parentesis del nombre
            -- ("Incremento de caracteristica (+2)" -> "Incremento de caracteristica"): el
            -- valor ya lo dice la eleccion, que va justo debajo. Los dos incrementos de humano
            -- quedan con el mismo titulo y se distinguen por su eleccion, que es lo util.
            local nombreRasgo = tostring(item.feature.name or "?")
            if item.feature.choice then
                nombreRasgo = nombreRasgo:gsub("%s*%b()%s*$", "")
            end
            b.name:SetText(nombreRasgo)
            b.name:SetWidth(145)
            b.sub:SetWidth(145)
            b.formArrow:SetShown(cat == "forma" or cat == "acompanante")
            if cat ~= "forma" and cat ~= "acompanante" then
                b.formFlyoutBorder:Hide()
                b.formFlyoutShadow:Hide()
            end
            -- Estado del daño condicional (al_accion) y de reaccion.
            local cdId = (cat == "al_accion") and FeatureCondDamageId(item.feature) or nil
            local cdActive = cdId and HarfordDnDStore and HarfordDnDStore.IsConditionalDamageActive
                and HarfordDnDStore.IsConditionalDamageActive(cdId)
            local rfid = item.feature.id or item.feature.name
            local reactionOn = cat == "reaccion" and S.activeReactions and rfid and S.activeReactions[rfid] and true or false
            -- Subtexto: SIEMPRE muestra la categoria explicita (Pasiva/Activa/Reacción/Al atacar),
            -- el nivel del rasgo y el estado preparado (con cantidad para Golpe Runico, etc.).
            local catTxt = BookCategoryLabel(cat, item.feature)
            local sub = (item.level and item.level > 0) and (catTxt .. "  ·  Nivel " .. item.level) or catTxt
            if cat == "forma" then
                sub = activeForm and ("Forma activa: " .. tostring(activeForm.name)) or "Forma normal"
            elseif item.feature.actionKind == "arcaneCharge" and HarfordDnDStore
                and HarfordDnDStore.GetArcaneChargeState then
                sub = HarfordDnDStore.GetArcaneChargeState()
            elseif item.feature.actionKind == "voidLegacy" and HarfordDnDStore
                and HarfordDnDStore.GetVoidLegacyState then
                -- La CD sube con cada uso, asi que el estado es lo util de ver en la fila.
                sub = HarfordDnDStore.GetVoidLegacyState()
            elseif cat == "acompanante" then
                if activeCompanion then
                    local _, pg = HarfordDnDCompanions.GetActive()
                    sub = string.format("%s  ·  %d/%d PG", tostring(activeCompanion.name),
                        tonumber(pg) or 0, HarfordDnDCompanions.GetMaxHP(activeCompanion) or 0)
                elseif activeCore then
                    sub = "Nucleo de " .. tostring(activeCore.name)
                else
                    sub = "Sin invocar"
                end
            elseif cat == "al_accion" and cdActive then
                local lvl = HarfordDnDStore.GetConditionalDamageActiveLevel and HarfordDnDStore.GetConditionalDamageActiveLevel(cdId)
                sub = sub .. ((lvl and lvl > 1) and ("  ·  Preparado x" .. lvl) or "  ·  Preparado")
            elseif reactionOn then
                sub = sub .. "  ·  Preparada"
            end
            -- Competencias e Idiomas no llevan subtexto de categoria: lo suyo es el listado del
            -- tooltip, y poner "Pasiva" debajo solo ocupa sitio sin decir nada.
            if API.IsAggregatedFeature(item.feature) then sub = "" end
            local choiceText, pendingChoice = GetFeatureChoiceDisplay(item.feature, GetProfileName())
            if choiceText then
                -- SOLO la eleccion. Decir "Pasiva - Eleccion: Sabiduria +2" era repetir dos
                -- etiquetas para dar un dato; lo que interesa de un rasgo de eleccion es QUE
                -- se eligio. La categoria sigue estando en el tooltip y en el marco del icono.
                --
                -- EXCEPCION: un rasgo de criatura acompanante que ADEMAS tiene eleccion (Domar
                -- bestia: dos habilidades). Ahi el estado -que criatura hay y con cuantos PG-
                -- cambia a cada momento y es lo que se consulta; la eleccion es fija. Se muestran
                -- los dos, con el mismo separador gris que usa la linea de usos.
                if cat == "acompanante" and sub ~= "" then
                    sub = sub .. " |cff888888|||r " .. choiceText
                else
                    sub = choiceText
                end
            end
            local useState = GetFeatureUseState(item.feature)
            local useExhausted = useState and (tonumber(useState.available) or 0) <= 0
            if useState then
                -- Mismo separador gris que usa la linea de eleccion. La barra va ESCAPADA
                -- (`||`): una `|` suelta es prefijo de secuencia de escape para WoW y no se
                -- pinta como caracter. Aqui ademas iba sin color, asi que heredaba el del
                -- subtitulo en vez de quedar apagada como separador.
                sub = sub .. " |cff888888|||r " .. FeatureUseCompactText(item.feature)
            end
            b.sub:SetText(sub)
            local col = (HarfordCharacterBook.CategoryColor
                and HarfordCharacterBook.CategoryColor(cat, item.feature))
                or K.BOOK_CAT_COLOR[cat] or { 0.82, 0.82, 0.82 }
            if pendingChoice then
                b.sub:SetTextColor(1, 0.25, 0.25)
            elseif useExhausted then
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
            b.formArrow:Hide()
            b.formFlyoutBorder:Hide(); b.formFlyoutShadow:Hide()
            b.name:SetWidth(145); b.sub:SetWidth(145)
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

-- Ajusta en vivo el marco de una categoria a partir de la CAJA EN PIXELES (esquina sup-izq
-- x1,y1 e inf-der x2,y2) sobre el sheet Spellbook-Parts; calcula texCoord y tamaño y refresca.
-- Refresca el Libro si el panel esta visible (lo llama HarfordDnD tras elegir nivel/cantidad de
-- un daño condicional en el dropdown del Libro, para reflejar el estado "Preparado").
-- Punto de entrada publico a una accion basica, para poder dispararla sin abrir el Libro. Es la
-- MISMA ruta que usa el boton (menus de coste y de opcion incluidos): una via de prueba que no
-- pasara por donde pasa el jugador no probaria lo que hay que probar.
function HarfordCharacterPanel.RunBasicAction(actionId, anchor)
    return AbrirAccionBasica(actionId, anchor)
end

function HarfordCharacterPanel.RefreshBookIfShown()
    if S.skillsFrame and S.skillsFrame:IsShown() and RefreshBook then
        RefreshBook()
    end
end

-- Todas las rutas de gasto/restauracion de usos (incluidas las que no pasan por
-- el click generico del Libro) actualizan la tarjeta y el tooltip si estan
-- abiertos. No se asocia ningun rasgo a un recurso distinto de su featureId.
if HarfordDnDFeatureUses and HarfordDnDFeatureUses.RegisterListener
    and not HarfordCharacterPanel._featureUseListenerInstalled then
    HarfordDnDFeatureUses.RegisterListener(function()
        HarfordCharacterPanel.RefreshBookIfShown()
    end)
    HarfordCharacterPanel._featureUseListenerInstalled = true
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
    f:SetSize(K.NORMAL_W, K.NORMAL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    -- La ficha DnD vive en DIALOG/100. Este panel y el Libro deben ser ventanas completas:
    -- nivel superior + toplevel evita que sus bordes, fondos y pestañas se intercalen con ella.
    f:SetFrameLevel(110)
    if f.SetToplevel then f:SetToplevel(true) end
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

    -- Libro de Habilidades/Conjuros: ventana real e independiente. Las paginas se crean una
    -- vez en este contenedor, por lo que los filtros y el estado del Libro se reutilizan sin
    -- duplicar datos ni obligar a cerrar el panel de personaje.
    local sf = CreateFrame("Frame", "HarfordSkillsPanelFrame", UIParent, "ButtonFrameTemplate")
    sf:SetSize(K.BOOK_W, K.BOOK_H)
    sf:SetPoint("CENTER", UIParent, "CENTER", 80, 0)
    sf:SetFrameStrata("DIALOG")
    sf:SetFrameLevel(120)
    if sf.SetToplevel then sf:SetToplevel(true) end
    sf:SetMovable(true)
    sf:EnableMouse(true)
    sf:RegisterForDrag("LeftButton")
    sf:SetScript("OnDragStart", sf.StartMoving)
    sf:SetScript("OnDragStop", sf.StopMovingOrSizing)
    if sf.TitleText then sf.TitleText:SetText("Habilidades") end
    local skillsPortrait = sf.portrait or _G["HarfordSkillsPanelFramePortrait"]
    if not skillsPortrait then
        skillsPortrait = sf:CreateTexture("HarfordSkillsPanelFramePortrait", "ARTWORK")
    end
    skillsPortrait:SetSize(58, 58)
    skillsPortrait:ClearAllPoints()
    skillsPortrait:SetPoint("TOPLEFT", sf, "TOPLEFT", -4, 4)
    skillsPortrait:SetDrawLayer("ARTWORK", 2)
    if skillsPortrait.AddMaskTexture and sf.CreateMaskTexture then
        local mask = sf:CreateMaskTexture(nil, "ARTWORK")
        mask:SetTexture(K.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(skillsPortrait)
        skillsPortrait:AddMaskTexture(mask)
        S.skillsPortraitMask = mask
    end
    S.skillsPortrait = skillsPortrait
    if sf.Inset then sf.Inset:Hide() end
    if sf.Bg then sf.Bg:Hide() end
    sf:Hide()
    S.skillsFrame = sf
    S.skillsContent = CreateFrame("Frame", nil, sf)
    S.skillsContent:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, -21)
    S.skillsContent:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 0, 0)
    S.skillsTabs = {}
    S.skillsActiveTab = "book"

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
        mask:SetTexture(K.TEX_PORTRAIT_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(portrait)
        portrait:AddMaskTexture(mask)
        S.portraitMask = mask
    end

    local tabData = {
        { "sheet", "Personaje" },
        { "reputation", "Reputacion" },
        { "professions", "Profesiones" },
        -- Creacion/Subida ocultas para el despliegue (ver HIDDEN_TABS).
    }
    for i, t in ipairs(tabData) do
        local key = t[1]
        S.tabs[key] = CreateNativeTab(f, i, t[2], function()
            if HarfordUISounds and HarfordUISounds.Play then
                HarfordUISounds.Play("character_panel_tab_changed")
            end
            SetPanelMode("character")
            S.explicitHiddenTab = nil
            S.activeTab = key
            RefreshPanel()
        end)
    end
    local skillTabData = {
        { "book", "Habilidades" },
        { "spells", "Conjuros" },
        { "professions", "Profesiones" },
    }
    for i, t in ipairs(skillTabData) do
        local key = t[1]
        S.skillsTabs[key] = CreateNativeTab(sf, i, t[2], function()
            if HarfordUISounds and HarfordUISounds.Play then
                HarfordUISounds.Play("skills_panel_tab_changed")
            end
            S.skillsActiveTab = key
            RefreshSkillsPanel()
        end)
    end
    SetPanelMode()
    PositionTabs()
    PositionSkillsTabs()

    Ficha.CreateSheetPage()
    CreateCreationPage()
    CreateLevelingPage()
    CreateReputationPage()
    Profesiones.CreateProfessionsPage()
    CreateBookPage()
    -- Pestaña Conjuros extraida a HarfordCharacterSpellbook; se le inyectan estado + constantes del libro.
    HarfordCharacterSpellbook.Init({
        S = S, CreatePage = CreatePage, BookSideTabOnEnter = BookSideTabOnEnter,
        BOOK_PER_PAGE = K.BOOK_PER_PAGE, BOOK_ROWS = K.BOOK_ROWS, BOOK_BTN = K.BOOK_BTN,
        BOOK_COL_X = K.BOOK_COL_X, BOOK_ROW_Y0 = K.BOOK_ROW_Y0, BOOK_ROW_PITCH = K.BOOK_ROW_PITCH,
        BOOK_GENERAL_ICON = K.BOOK_GENERAL_ICON,
    })
    HarfordCharacterSpellbook.CreateSpellsPage()

    S.refreshers.sheet = Ficha.RefreshSheet
    S.refreshers.creation = RefreshCreation
    S.refreshers.leveling = RefreshLeveling
    S.refreshers.reputation = function() end
    S.refreshers.professions = Profesiones.RefreshProfessions
    S.refreshers.book = RefreshBook
    S.refreshers.spells = HarfordCharacterSpellbook.RefreshSpells
    sf:SetScript("OnShow", function()
        sf:Raise()
        if HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("skills_panel_opened")
        end
        RefreshPortrait()
        RefreshSkillsPanel()
    end)
    -- Al empezar TU turno, las reacciones preparadas se apagan solas (se quedan activas solo hasta
    -- tu siguiente turno o hasta volver a clicarlas).
    if not S._turnListenerHooked and HarfordTurnOrderAPI and HarfordTurnOrderAPI.RegisterMyTurnListener then
        S._turnListenerHooked = true
        HarfordTurnOrderAPI.RegisterMyTurnListener(function()
            if S.activeReactions and next(S.activeReactions) then
                for id, prepared in pairs(S.activeReactions) do
                    local feature = ResolveBookFeatureById(id)
                    local option = GetPowerWordOptionById(feature, prepared and prepared.optionId)
                    local reaction = option or feature
                    if feature and FeatureReactionEffect(reaction) == "reroll_attack" then
                        local protectedGuid = prepared and prepared.protectedGuid
                        if protectedGuid and HarfordDnDCombat and HarfordDnDCombat.SetPreparedAttackReaction then
                            HarfordDnDCombat.SetPreparedAttackReaction(protectedGuid, nil)
                        end
                        if protectedGuid and HarfordSync and HarfordSync.SendPreparedAttackReaction then
                            HarfordSync.SendPreparedAttackReaction("DND5EARC", id, protectedGuid, false)
                        end
                    end
                end
                wipe(S.activeReactions)
                if RefreshBook then RefreshBook() end
            end
        end)
    end
    f:SetScript("OnShow", function(self)
        self:Raise()
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
        if HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("character_panel_opened")
        end
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

function API.Open(tab, opts)
    if tab == "book" or tab == "spells" or tab == "professions" then
        if tab == "professions" and S.professions and not (opts and opts.keepProfessionFilter) then
            S.professions.forcedProfession = nil
        end
        return API.OpenSkills(tab)
    end
    CreateFrameIfNeeded()
    S.inspectName = nil
    S.inspectUnit = nil
    if HarfordCharacterInspect and HarfordCharacterInspect.ClearInspectStores then
        HarfordCharacterInspect.ClearInspectStores()  -- descarta snapshot efimero al volver a modo propio
    end
    SetPanelMode()
    S.activeTab = tab or "sheet"
    S.explicitHiddenTab = (opts and opts.allowHidden and K.HIDDEN_TABS[S.activeTab]) and S.activeTab or nil
    if K.HIDDEN_TABS[S.activeTab] and not IsExplicitHiddenTab(S.activeTab) then
        S.activeTab = "sheet"
    end
    S.frame:Show()
    RefreshPanel()
end

-- Abre una estacion concreta (Spark/Arcanum). No concede la profesion: solo muestra
-- sus recetas y deja que CanCraft explique por que una receta no esta disponible.
function API.OpenProfession(profId)
    profId = tostring(profId or ""):lower()
    if not (HarfordProfessions and HarfordProfessions.GetDefinition and HarfordProfessions.GetDefinition(profId)) then
        return false, "Profesion desconocida: " .. profId
    end
    if HarfordProfessionsCraftUI and HarfordProfessionsCraftUI.Open then
        return HarfordProfessionsCraftUI.Open(profId)
    end
    CreateFrameIfNeeded()
    S.professions.forcedProfession = profId
    S.professions.selected = profId
    S.professions.view = "recipes"
    API.Open("professions", { keepProfessionFilter = true })
    return true
end

function API.OpenSkills(tab)
    CreateFrameIfNeeded()
    local targetTab = (tab == "spells" or tab == "professions") and tab or "book"
    local wasShown = S.skillsFrame:IsShown()
    local changedTab = S.skillsActiveTab ~= targetTab
    S.inspectName = nil
    S.inspectUnit = nil
    if HarfordCharacterInspect and HarfordCharacterInspect.ClearInspectStores then
        HarfordCharacterInspect.ClearInspectStores()
    end
    S.skillsActiveTab = targetTab
    S.skillsFrame:Show()
    if wasShown and changedTab and HarfordUISounds and HarfordUISounds.Play then
        HarfordUISounds.Play("skills_panel_opened")
    end
    RefreshSkillsPanel()
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
    S.explicitHiddenTab = nil
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
    if S.skillsFrame then S.skillsFrame:Hide() end
end

function API.Toggle(tab)
    if tab == "book" or tab == "spells" or tab == "professions" then
        CreateFrameIfNeeded()
        if S.skillsFrame:IsShown() and S.skillsActiveTab == tab then
            S.skillsFrame:Hide()
        else
            API.OpenSkills(tab)
        end
        return
    end
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
    RefreshSkillsPanel()
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
        for index, spec in ipairs(K.MODEL_BG_SOURCES) do
            local t = SH.modelBg[spec.key]
            if t then
                t:SetTexture("Interface\\DressUpFrame\\DressUpBackground-" .. cmd .. tostring(index))
                SetTexCoord8(t, K.MODEL_BG_TEXCOORDS[spec.key])
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
        if HarfordCharacterAdvancement and HarfordCharacterAdvancement.OpenPrototype then
            HarfordCharacterAdvancement.OpenPrototype("guerrero")
        else
            API.Toggle("sheet")
        end
    elseif msg == "subir" or msg == "clases" then
        if HarfordCharacterAdvancement and HarfordCharacterAdvancement.OpenLevelUp then
            HarfordCharacterAdvancement.OpenLevelUp()
        else
            API.Open("leveling", { allowHidden = true })
        end
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

-- La pestana Ficha recibe aqui el estado del panel y los ayudantes compartidos. Al FINAL del
-- fichero: varios de estos son de asignacion adelantada y antes de este punto serian nil.
if Ficha and Ficha.Init then
    Ficha.Init({
        S = S, K = K, API = API,
        AbilityBaseAndBonus = AbilityBaseAndBonus,
        GetClassColorParts = GetClassColorParts,
        GetInspectSnapshot = GetInspectSnapshot,
        GetPrimaryClassId = GetPrimaryClassId,
        RawSigned = RawSigned,
        AbilityMod = AbilityMod,
        AbilityScore = AbilityScore,
        ColorSigned = ColorSigned,
        CreateButton = CreateButton,
        CreateFS = CreateFS,
        GetBackgroundLabel = GetBackgroundLabel,
        GetClassFeatureRows = GetClassFeatureRows,
        GetClassParts = GetClassParts,
        GetClassSummary = GetClassSummary,
        GetFeatsLabel = GetFeatsLabel,
        GetPortraitUnit = GetPortraitUnit,
        GetProfileName = GetProfileName,
        GetProfileValue = GetProfileValue,
        GetProgression = GetProgression,
        GetRaceLabel = GetRaceLabel,
        GetTRP3FeatureRows = GetTRP3FeatureRows,
        IsInspecting = IsInspecting,
        Print = Print,
        RefreshGameUI = RefreshGameUI,
        RefreshPanel = RefreshPanel,
        RefreshRaceModelBackground = RefreshRaceModelBackground,
        SetColoredTextList = SetColoredTextList,
        SetTexCoord8 = SetTexCoord8,
        Signed = Signed,
        TooltipLines = TooltipLines,
    })
end

if Profesiones and Profesiones.Init then
    Profesiones.Init({
        CreateFS = CreateFS,
        CreatePage = CreatePage,
        K = K,
        S = S,
    })
end
