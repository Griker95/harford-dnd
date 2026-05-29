-- HarfordDnDMinimap: boton de minimapa de la ficha Harford.
--
-- El click izquierdo abre/cierra la ficha via _G.DND5E_ARC_API.Toggle (global).
-- El click derecho reinicia posiciones de marcos: como esa logica vive en
-- HarfordDnD.lua, se inyecta con SetResetHandler. Posicion/visibilidad se
-- persisten en HarfordDnDMinimapSettings (SavedVariable).

HarfordDnDMinimap = HarfordDnDMinimap or {}

local _onReset = nil

-- HarfordDnD.lua registra aqui su ResetAllFramePositions para el click derecho.
function HarfordDnDMinimap.SetResetHandler(fn)
    _onReset = type(fn) == "function" and fn or nil
end

local function EnsureState()
    HarfordDnDMinimapSettings = HarfordDnDMinimapSettings or {}
    if HarfordDnDMinimapSettings.angle == nil then HarfordDnDMinimapSettings.angle = 220 end
    if HarfordDnDMinimapSettings.hide == nil then HarfordDnDMinimapSettings.hide = false end
end

local function UpdatePosition(btn)
    EnsureState()

    local angle = math.rad(HarfordDnDMinimapSettings.angle or 220)

    -- radio más conservador para que no se salga del anillo
    local radius = 76

    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

HarfordDnDMinimap.UpdatePosition = UpdatePosition

-- Crea (o reanima) el boton del minimapa. Idempotente.
function HarfordDnDMinimap.Create()
    EnsureState()

    if _G.HarfordDnDMinimapButton then
        _G.HarfordDnDMinimapButton:SetShown(not HarfordDnDMinimapSettings.hide)
        UpdatePosition(_G.HarfordDnDMinimapButton)
        return
    end

    local btn = CreateFrame("Button", "HarfordDnDMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:EnableMouse(true)
    btn:SetFrameStrata("MEDIUM")

    local background = btn:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", 0, 1)
    btn.background = background

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Inv_tabard_duelersguild")
    icon:SetSize(17, 17)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.18, 0.82, 0.18, 0.82)
    btn.icon = icon

    local innerHighlight = btn:CreateTexture(nil, "HIGHLIGHT")
    innerHighlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    innerHighlight:SetBlendMode("ADD")
    innerHighlight:SetAlpha(0.75)
    innerHighlight:SetSize(22, 22)
    innerHighlight:SetPoint("CENTER", 0, 1)
    btn.innerHighlight = innerHighlight

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT", 0, 0)
    btn.overlay = overlay

    local function SetIconPressed(self, pressed)
        if not self.icon then return end
        self.icon:ClearAllPoints()
        if pressed then
            self.icon:SetPoint("CENTER", 1, 0)
        else
            self.icon:SetPoint("CENTER", 0, 1)
        end
    end

    local function UpdateAngleFromCursor(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        px = px / scale
        py = py / scale

        local angle = math.deg(math.atan2(py - my, px - mx))
        HarfordDnDMinimapSettings.angle = angle
        UpdatePosition(self)
    end

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Ficha Harford", 1, 0.82, 0)
        GameTooltip:AddLine("Click izquierdo: abrir/cerrar ficha", 1, 1, 1)
        GameTooltip:AddLine("Click derecho: reiniciar posiciones de los marcos", 1, 1, 1)
        GameTooltip:AddLine("Arrastrar: mover botón", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("/FichaHarford minimap show", 0.7, 0.9, 0.7)
        GameTooltip:AddLine("/FichaHarford minimap hide", 0.7, 0.9, 0.7)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        SetIconPressed(self, false)
    end)

    btn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            SetIconPressed(self, true)
        end
    end)

    btn:SetScript("OnMouseUp", function(self)
        SetIconPressed(self, false)
    end)

    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            if _G.DND5E_ARC_API and _G.DND5E_ARC_API.Toggle then
                _G.DND5E_ARC_API.Toggle()
            end
        elseif button == "RightButton" then
            if _onReset then _onReset() end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HarfordDnD]|r Posiciones de los marcos reiniciadas.")
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        SetIconPressed(self, false)
        self:SetScript("OnUpdate", UpdateAngleFromCursor)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        SetIconPressed(self, false)
        UpdateAngleFromCursor(self)
    end)

    UpdatePosition(btn)
    btn:SetShown(not HarfordDnDMinimapSettings.hide)
end
