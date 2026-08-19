HarfordConfig = HarfordConfig or {}

local DEFAULTS = {
    portrait_player        = "trp3",       -- "trp3" | "wow"
    portrait_target_player = "trp3",       -- "trp3" | "wow"
    portrait_target_npc    = "trp3",       -- "trp3" | "wow"
    resources              = "unitframe",  -- "unitframe" | "frame"
    nameplates             = "on",         -- "on" | "off"
    actionbar              = "off",        -- "on" | "off": barra de accion de madera del Libro
    spell_cost_mode        = "mana",       -- "mana" | "slots": coste global de lanzamiento
}

local listeners = {}

-- ── API pública ─────────────────────────────────────────────────────────────

function HarfordConfig.Get(key)
    local sv = HarfordConfigStore
    if type(sv) == "table" and sv[key] ~= nil then
        return sv[key]
    end
    return DEFAULTS[key]
end

function HarfordConfig.Set(key, value)
    if type(HarfordConfigStore) ~= "table" then
        HarfordConfigStore = {}
    end
    HarfordConfigStore[key] = value
    for _, fn in ipairs(listeners) do
        pcall(fn, key, value)
    end
end

function HarfordConfig.Reset()
    HarfordConfigStore = {}
    for _, fn in ipairs(listeners) do
        pcall(fn, nil, nil)
    end
end

function HarfordConfig.RegisterChangeListener(fn)
    if type(fn) == "function" then
        listeners[#listeners + 1] = fn
    end
end

-- ── Helpers de UI ────────────────────────────────────────────────────────────

local function MakeLabel(parent, text, size, x, y)
    if text == "Unitframes" then
        text = "UnitFrames Harford"
    elseif type(text) == "string" and text:find("Retrato", 1, true) and text:find("Target jugador", 1, true) then
        text, x, y = "Objetivo:", 214, 94
    elseif type(text) == "string" and text:find("Retrato", 1, true) and text:find("Target NPC", 1, true) then
        text, x, y = "Objetivo NPC:", 404, 94
    elseif type(text) == "string" and text:find("Retrato", 1, true) and text:find("Jugador", 1, true) then
        text, x, y = "Propio:", 24, 94
    elseif text == "Recursos del target" then
        y = 178
    elseif text == "Mostrar recursos en:" then
        y = 198
    end
    local fs = parent:CreateFontString(nil, "OVERLAY", size or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 16, -(y or 16))
    fs:SetText(text)
    return fs
end

local function MakeSeparator(parent, y)
    if y == 268 then
        y = 170
    end
    local tex = parent:CreateTexture(nil, "BACKGROUND")
    tex:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    tex:SetPoint("TOPLEFT",  parent, "TOPLEFT",  16, -y)
    tex:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -y)
    tex:SetHeight(1)
    return tex
end

-- Crea un dropdown (UIDropDownMenu) ligado a una clave de configuración.
-- options = { { value=..., label=... }, ... }
-- Devuelve (dropdown, refreshFn).
local function MakeDropDown(parent, cfgKey, options, x, y)
    if cfgKey == "portrait_target_player" then
        x, y = 222, 114
    elseif cfgKey == "portrait_target_npc" then
        x, y = 412, 114
    elseif cfgKey == "resources" then
        y = 218
    end
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, -y)  -- UIDropDownMenu tiene padding interno de ~16px
    UIDropDownMenu_SetWidth(dd, 160)

    local function GetLabel(value)
        for _, opt in ipairs(options) do
            if opt.value == value then return opt.label end
        end
        return value
    end

    UIDropDownMenu_Initialize(dd, function(self, level)
        local current = HarfordConfig.Get(cfgKey)
        for _, opt in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.value   = opt.value
            info.checked = (current == opt.value)
            info.func    = function(btn)
                HarfordConfig.Set(cfgKey, btn.value)
                UIDropDownMenu_SetText(dd, GetLabel(btn.value))
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local function Refresh()
        UIDropDownMenu_SetText(dd, GetLabel(HarfordConfig.Get(cfgKey)))
    end

    Refresh()  -- texto inicial al crear el dropdown

    return dd, Refresh
end

-- ── Panel de opciones ─────────────────────────────────────────────────────────

local function BuildPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Harford"

    -- Título
    MakeLabel(panel, "Harford DnD 5e", "GameFontNormalLarge", 16, 16)
    MakeLabel(panel, "Configuración del addon", "GameFontHighlightSmall", 16, 40)

    -- ── Sección: Unitframes ──────────────────────────────────────────────────
    MakeSeparator(panel, 62)
    MakeLabel(panel, "Unitframes", "GameFontNormal", 16, 70)

    local PORTRAIT_OPTIONS = {
        { value = "trp3", label = "Icono TRP3" },
        { value = "wow",  label = "Retrato 3D WoW" },
    }

    -- Retrato: Jugador
    MakeLabel(panel, "Retrato — Jugador:", "GameFontHighlight", 24, 94)
    local _, refreshPortraitPlayer = MakeDropDown(panel, "portrait_player", PORTRAIT_OPTIONS, 32, 114)

    -- Retrato: Target jugador
    MakeLabel(panel, "Retrato — Target jugador:", "GameFontHighlight", 24, 150)
    local _, refreshPortraitTargetPlayer = MakeDropDown(panel, "portrait_target_player", PORTRAIT_OPTIONS, 32, 170)

    -- Retrato: Target NPC
    MakeLabel(panel, "Retrato — Target NPC:", "GameFontHighlight", 24, 206)
    local _, refreshPortraitTargetNPC = MakeDropDown(panel, "portrait_target_npc", PORTRAIT_OPTIONS, 32, 226)

    -- Recursos
    MakeSeparator(panel, 268)
    MakeLabel(panel, "Recursos del target", "GameFontNormal", 16, 276)
    MakeLabel(panel, "Mostrar recursos en:", "GameFontHighlight", 24, 296)
    local _, refreshResources = MakeDropDown(panel, "resources", {
        { value = "unitframe", label = "Unitframe integrado" },
        { value = "frame",     label = "Frame separado" },
    }, 32, 316)

    -- ── Sección: Nameplates ──────────────────────────────────────────────────
    MakeSeparator(panel, 260)
    MakeLabel(panel, "Nameplates Harford", "GameFontNormal", 16, 270)
    MakeLabel(panel, "Overlays D&D en nameplates:", "GameFontHighlight", 24, 292)
    local _, refreshNameplates = MakeDropDown(panel, "nameplates", {
        { value = "on",  label = "Activado" },
        { value = "off", label = "Desactivado" },
    }, 32, 312)

    -- ── Sección: Barra de acción ─────────────────────────────────────────────
    MakeLabel(panel, "Barra de acción (Libro)", "GameFontNormal", 280, 270)
    MakeLabel(panel, "Mostrar barra de madera:", "GameFontHighlight", 288, 292)
    local _, refreshActionBar = MakeDropDown(panel, "actionbar", {
        { value = "on",  label = "Activada" },
        { value = "off", label = "Desactivada" },
    }, 296, 312)

    -- El coste de conjuros es una regla de mesa global, no una eleccion por personaje.
    MakeLabel(panel, "Coste de conjuros:", "GameFontHighlight", 288, 354)
    local _, refreshSpellCostMode = MakeDropDown(panel, "spell_cost_mode", {
        { value = "mana",  label = "Mana automatico" },
        { value = "slots", label = "Espacios de conjuro" },
    }, 296, 374)

    -- Botón de reset
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 22)
    resetBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -414)
    resetBtn:SetText("Restaurar defaults")
    resetBtn:SetScript("OnClick", function()
        HarfordConfig.Reset()
        refreshPortraitPlayer()
        refreshPortraitTargetPlayer()
        refreshPortraitTargetNPC()
        refreshResources()
        refreshNameplates()
        refreshActionBar()
        refreshSpellCostMode()
    end)

    local function RefreshAll()
        refreshPortraitPlayer()
        refreshPortraitTargetPlayer()
        refreshPortraitTargetNPC()
        refreshResources()
        refreshNameplates()
        refreshActionBar()
        refreshSpellCostMode()
    end

    -- Refrescar estado al abrir el panel
    panel:SetScript("OnShow", RefreshAll)
    panel.refreshAll = RefreshAll

    return panel
end

-- ── Registro en Interface Options ─────────────────────────────────────────────

local function RegisterPanel(panel)
    -- Dragonflight+ (Settings API)
    if Settings and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterAddOnCategory(panel)
        if category and Settings.RegisterAddOnCategory then
            Settings.RegisterAddOnCategory(category)
        end
        return category
    end
    -- Shadowlands / legacy
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

local function OpenPanel(panel)
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(panel.name)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel) -- doble llamada, quirk conocido de WoW
    end
end

-- ── Inicialización ────────────────────────────────────────────────────────────

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()

    local panel = BuildPanel()
    RegisterPanel(panel)

    -- Comando suelto retirado: usar `/harford config`.
    SlashCmdList["HARFORDCONFIG"] = function()
        OpenPanel(panel)
    end
end)
