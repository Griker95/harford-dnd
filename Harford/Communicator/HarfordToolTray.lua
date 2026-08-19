------------------------------------------------------------
-- HarfordToolTray - "Herramientas de Rol": bandeja propia de Harford, replica FIEL del Epsilon
-- AddOn Tray (Epsilon_Launcher): mismo panel, misma flecha, misma animacion (scale+alpha con
-- easeOutCubic), mismo grid. Usa los assets del propio Epsilon_Launcher (flecha) por ruta,
-- asumiendo que esta cargado. Bandeja separada, colgada de NUESTRO boton de minimapa (unico).
------------------------------------------------------------

HarfordToolTray = HarfordToolTray or {}

local API = HarfordToolTray

-- Assets del Epsilon_Launcher (se asume cargado).
local ASSETS = "Interface\\AddOns\\Epsilon_Launcher\\assets\\"

local MAX_COL = 4
local ICON = 34
local GAP = 5
local INSET = 7

local tools = {}
local iconButtons = {}
local tray
local arrow
local anchorButton

local function AnchorFrame()
    return anchorButton or _G.HarfordDnDMinimapButton
end

local function IsToolEnabled(def)
    if type(def.isEnabled) ~= "function" then return true end
    local ok, enabled = pcall(def.isEnabled)
    return ok and enabled and true or false
end

local function RefreshToolButton(btn)
    local enabled = IsToolEnabled(btn.toolDef)
    btn:SetEnabled(enabled)
    btn:SetAlpha(enabled and 1 or 0.42)
    if btn.icon and btn.icon.SetDesaturated then btn.icon:SetDesaturated(not enabled) end
end

local function CallTool(def)
    if not IsToolEnabled(def) then return end
    if type(def.onClick) == "function" then pcall(def.onClick) end
    API.Close()
end

-- Icono redondo (mascara circular) + aro, imitando el look del Epsilon tray.
local function CreateIconButton(def)
    local btn = CreateFrame("Button", nil, tray)
    btn:SetSize(ICON, ICON)

    -- Helper: textura recortada en circulo (mascara).
    local function roundTex(layer, size)
        local t = btn:CreateTexture(nil, layer)
        t:SetSize(size, size)
        t:SetPoint("CENTER")
        local m = btn:CreateMaskTexture(nil, layer)
        m:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        m:SetAllPoints(t)
        t:AddMaskTexture(m)
        return t
    end

    -- Aro dorado = disco dorado redondo; encima un anillo oscuro fino y el icono grande, dejando
    -- ver el borde dorado (look del Epsilon tray, sin marco ornamentado ni muesca).
    local ring = roundTex("BACKGROUND", ICON)
    ring:SetColorTexture(0.83, 0.67, 0.19, 1)

    local darkRim = roundTex("BORDER", ICON - 3)
    darkRim:SetColorTexture(0.05, 0.05, 0.08, 1)

    local iconTex = roundTex("ARTWORK", ICON - 6)
    iconTex:SetTexture(def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = iconTex
    btn.toolDef = def

    -- Glow de hover redondo.
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    local hl = btn:GetHighlightTexture()
    if hl then hl:ClearAllPoints(); hl:SetPoint("CENTER"); hl:SetSize(ICON, ICON) end

    btn:SetScript("OnClick", function() CallTool(def) end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(def.label or def.key or "", 1, 0.82, 0)
        if def.tooltip then GameTooltip:AddLine(def.tooltip, 1, 1, 1, true) end
        if not IsToolEnabled(def) then
            GameTooltip:AddLine(def.disabledTooltip or "No disponible ahora mismo.", 1, 0.25, 0.25, true)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    RefreshToolButton(btn)
    return btn
end

-- Grid identico al Epsilon tray: primer icono TOPRIGHT; columna 1 baja una fila; resto a la
-- izquierda del anterior. Rellena de derecha a izquierda, de arriba a abajo.
local function Layout()
    if not tray then return end
    local n = #iconButtons
    if n == 0 then tray:SetSize(ICON + INSET * 2, ICON + INSET * 2); return end
    local rows = math.ceil(n / MAX_COL)
    local cols = math.min(n, MAX_COL)
    tray:SetHeight(rows * (ICON + GAP) + 12)
    tray:SetWidth(cols * (ICON + GAP) + 12)
    for i, btn in ipairs(iconButtons) do
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("TOPRIGHT", tray, "TOPRIGHT", -INSET, -INSET)
        else
            local col = ((i - 1) % MAX_COL) + 1
            if col == 1 then
                btn:SetPoint("TOPRIGHT", iconButtons[i - MAX_COL], "BOTTOMRIGHT", 0, -GAP)
            else
                btn:SetPoint("TOPRIGHT", iconButtons[i - 1], "TOPLEFT", -GAP, 0)
            end
        end
        btn:SetSize(ICON, ICON)
    end
end

-- Animacion portada TAL CUAL del Epsilon_Launcher: scale+alpha con easeOutCubic desde una escala
-- minima. Driver OnUpdate que se auto-apaga (sin ticker permanente).
local function SetupAnimation()
    local frame = tray
    local animInSpeed = 0.20
    local MIN_SCALE = 0.01

    local driver = CreateFrame("Frame")
    driver:Hide()

    local function easeOutCubic(t) return 1 - (1 - t) * (1 - t) * (1 - t) end

    local anim = { running = false, start = 0, duration = animInSpeed, from = MIN_SCALE, to = 1 }

    local function onUpdate()
        local t = (GetTime() - anim.start) / anim.duration
        if t >= 1 then t = 1 end
        local v = anim.from + (anim.to - anim.from) * easeOutCubic(t)
        if v < MIN_SCALE then v = MIN_SCALE end
        frame:SetScale(v)
        frame:SetAlpha((v - MIN_SCALE) / (1 - MIN_SCALE))
        if t == 1 then
            driver:SetScript("OnUpdate", nil)
            driver:Hide()
            anim.running = false
            if anim.to == MIN_SCALE then
                frame:SetScale(1); frame:SetAlpha(1); frame:Hide()
            else
                frame:SetScale(1); frame:SetAlpha(1)
            end
        end
    end

    local function startAnim(from, to, duration)
        if anim.running then driver:SetScript("OnUpdate", nil); driver:Hide(); anim.running = false end
        anim.start = GetTime()
        anim.duration = duration or animInSpeed
        anim.from = math.max(from, MIN_SCALE)
        anim.to = math.max(to, MIN_SCALE)
        anim.running = true
        if anim.to > anim.from then frame:Show() end
        frame:SetScale(anim.from)
        frame:SetAlpha((anim.from - MIN_SCALE) / (1 - MIN_SCALE))
        driver:SetScript("OnUpdate", onUpdate)
        driver:Show()
    end

    function frame:Open() startAnim(MIN_SCALE, 1, animInSpeed) end
    function frame:Close() startAnim(1, MIN_SCALE, animInSpeed) end
end

local function BuildTray()
    if tray then return end
    tray = CreateFrame("Frame", "HarfordToolTrayFrame", UIParent, "TooltipBackdropTemplate")
    tray:SetFrameStrata("DIALOG")
    tray:SetToplevel(true)
    tray:EnableMouse(true)
    if tray.SetBackdropBorderColor then tray:SetBackdropBorderColor(1, 0.75, 0) end
    if tray.SetBackdropColor then tray:SetBackdropColor(0.04, 0.06, 0.13, 0.96) end
    tray:Hide()
    for _, def in ipairs(tools) do
        iconButtons[#iconButtons + 1] = CreateIconButton(def)
    end
    Layout()
    SetupAnimation()
end

function API.Register(def)
    if type(def) ~= "table" or type(def.onClick) ~= "function" then return end
    tools[#tools + 1] = def
    if tray then
        iconButtons[#iconButtons + 1] = CreateIconButton(def)
        Layout()
    end
end

function API.RefreshAvailability()
    for _, button in ipairs(iconButtons) do
        RefreshToolButton(button)
    end
end

-- Ancla la bandeja al boton de minimapa (mmIcon) igual que genLauncherTray del Epsilon tray:
-- parent + TOPRIGHT->TOPLEFT y la flecha a la izquierda del boton.
function API.Attach(button)
    if not button then return end
    anchorButton = button
    BuildTray()
    tray:SetParent(button)
    tray:ClearAllPoints()
    tray:SetPoint("TOPRIGHT", button, "TOPLEFT", 0, 3)

    if not arrow then
        -- Holder por ENCIMA del MiniMap-TrackingBorder del boton (si no, lo tapa el marco).
        local holder = CreateFrame("Frame", nil, button)
        holder:SetAllPoints(button)
        holder:SetFrameLevel((button:GetFrameLevel() or 0) + 20)
        arrow = holder:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(10, 18)
        arrow:SetTexture(ASSETS .. "EpsilonTrayArrowOut")
        arrow:SetPoint("RIGHT", button, "LEFT", 4, 3)
        arrow.flip = function(self, open)
            self:SetTexture(ASSETS .. (open and "EpsilonTrayArrow" or "EpsilonTrayArrowOut"))
        end
    end
end

function API.Open()
    BuildTray()
    if not anchorButton then
        local a = AnchorFrame()
        if a then API.Attach(a) end
    end
    if not anchorButton then
        tray:ClearAllPoints()
        tray:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
    end
    if arrow then arrow:flip(true) end
    tray:Open()
end

function API.Close()
    if tray then tray:Close() end
    if arrow then arrow:flip(false) end
end

function API.Toggle()
    BuildTray()
    if tray:IsShown() then API.Close() else API.Open() end
end

------------------------------------------------------------
-- Herramientas Harford registradas
------------------------------------------------------------

local function OpenPanel(tab)
    return function()
        if (tab == "book" or tab == "spells") and HarfordCharacterPanel and HarfordCharacterPanel.OpenSkills then
            HarfordCharacterPanel.OpenSkills(tab)
        elseif HarfordCharacterPanel and HarfordCharacterPanel.Open then
            HarfordCharacterPanel.Open(tab)
        end
    end
end

local function RouteSlash(key)
    return function() local f = SlashCmdList[key]; if f then f("") end end
end

-- Orden: fila 1 Tiradas, Turnos, Habilidades, Conjuros | fila 2 Personaje, Reputacion, Misiones.
API.Register({ key = "tiradas", label = "Tiradas / Ficha", icon = "Interface\\Icons\\INV_Misc_Dice_02",
    tooltip = "Caracteristicas, ataque y habilidades",
    onClick = function() if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Toggle then _G.DND5E_ARC_API.Toggle() end end })
API.Register({ key = "turnos", label = "Turnos", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
    tooltip = "Orden de turnos", onClick = RouteSlash("HARFORDTURNOS") })
API.Register({ key = "habilidades", label = "Habilidades", icon = "Interface\\Icons\\INV_Misc_Book_09",
    tooltip = "Libro de habilidades", onClick = OpenPanel("book") })
API.Register({ key = "conjuros", label = "Conjuros", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
    tooltip = "Libro de conjuros", onClick = OpenPanel("spells") })
API.Register({ key = "personaje", label = "Personaje", icon = "Interface\\Icons\\Achievement_Character_Human_Male",
    tooltip = "Panel de personaje", onClick = OpenPanel("sheet") })
API.Register({ key = "reputacion", label = "Reputacion", icon = "Interface\\Icons\\Achievement_Reputation_01",
    tooltip = "Reputaciones", onClick = RouteSlash("HARFORDREP") })
API.Register({ key = "misiones", label = "Misiones", icon = "Interface\\Icons\\INV_Misc_Note_01",
    tooltip = "Registro de misiones", onClick = RouteSlash("HARFORDQUESTLOG") })
API.Register({ key = "profesiones", label = "Profesiones", icon = "Interface\\Icons\\Trade_BlackSmithing",
    tooltip = "Profesiones y crafteo", onClick = OpenPanel("professions") })
