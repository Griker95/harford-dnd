-- HarfordActionBars: barra de accion de madera para colocar habilidades del Libro.
--
-- FASE 1 (este archivo): la barra VISUAL (tapas + tablon central + N slots). Las piezas son
-- texturas sueltas; las rutas de madera de retail (Interface\PlayerActionBarAlt\spellbar-wood*)
-- NO estan en el cliente Epsilon, asi que de momento usa pergamino/quickslot (que SI cargan).
-- Gate por HarfordConfig ("actionbar" = on/off).
--
-- Los comandos de diagnostico viven en HarfordDebug.lua (convencion del proyecto); este modulo
-- solo expone API publica (Toggle / SetTestTexture / SetGeometry / Layout).
--
-- FASE 2 (pendiente): arrastrar habilidades del Libro a los slots, click = ejecutar/preparar
-- (reutiliza la logica de HarfordCharacterPanel), y persistencia en SavedVariables.

HarfordActionBars = HarfordActionBars or {}
local API = HarfordActionBars

-- Texturas que SI existen en el cliente. Cambiar aqui cuando se encuentren las de madera reales.
local TEX_CENTER = "Interface\\Spellbook\\Spellbook-Page-1"   -- fondo (placeholder)
local TEX_LEFT   = nil                                        -- sin tapa por ahora
local TEX_RIGHT  = nil
local TEX_BTN    = "Interface\\Buttons\\UI-Quickslot2"        -- marco del slot

-- Geometria ajustable.
HarfordActionBars._cfg = HarfordActionBars._cfg or {
    h     = 72,   -- altura de la barra
    capW  = 70,   -- ancho de cada tapa
    slot  = 40,   -- tamaño de cada slot
    gap   = 10,   -- separacion entre slots
    count = 6,    -- numero de slots
}

local bar  -- frame unico

-- ─── Construccion / relayout ─────────────────────────────────────────────────
local function Build()
    if bar then return bar end
    bar = CreateFrame("Frame", "HarfordActionBarFrame", UIParent)
    bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", bar.StopMovingOrSizing)
    bar:Hide()

    bar.center = bar:CreateTexture(nil, "BACKGROUND")
    bar.center:SetTexture(TEX_CENTER)
    bar.leftCap = bar:CreateTexture(nil, "ARTWORK")
    if TEX_LEFT then bar.leftCap:SetTexture(TEX_LEFT) end
    bar.rightCap = bar:CreateTexture(nil, "ARTWORK")
    if TEX_RIGHT then bar.rightCap:SetTexture(TEX_RIGHT) end

    bar.slots = {}
    return bar
end

function API.Layout()
    if not bar then return end
    local c = HarfordActionBars._cfg
    local innerW = c.count * c.slot + (c.count - 1) * c.gap
    local totalW = innerW + 2 * c.capW + 40

    bar:SetSize(totalW, c.h)

    bar.leftCap:ClearAllPoints()
    bar.leftCap:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.leftCap:SetSize(c.capW, c.h)

    bar.rightCap:ClearAllPoints()
    bar.rightCap:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    bar.rightCap:SetSize(c.capW, c.h)

    bar.center:ClearAllPoints()
    bar.center:SetPoint("TOPLEFT", bar.leftCap, "TOPRIGHT", -2, 0)
    bar.center:SetPoint("BOTTOMRIGHT", bar.rightCap, "BOTTOMLEFT", 2, 0)

    for i = 1, c.count do
        local s = bar.slots[i]
        if not s then
            s = CreateFrame("CheckButton", "HarfordActionSlot" .. i, bar)
            s.bg = s:CreateTexture(nil, "BORDER")
            s.bg:SetTexture(TEX_BTN)
            s.bg:SetAllPoints()
            s.icon = s:CreateTexture(nil, "ARTWORK")
            s.icon:SetPoint("TOPLEFT", 3, -3); s.icon:SetPoint("BOTTOMRIGHT", -3, 3)
            s.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); s.icon:Hide()
            s:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            bar.slots[i] = s
        end
        s:SetSize(c.slot, c.slot)
        s:ClearAllPoints()
        if i == 1 then
            s:SetPoint("LEFT", bar, "LEFT", c.capW + 10, 0)
        else
            s:SetPoint("LEFT", bar.slots[i - 1], "RIGHT", c.gap, 0)
        end
        s:Show()
    end
    for i = c.count + 1, #bar.slots do bar.slots[i]:Hide() end
end

-- ─── API publica ─────────────────────────────────────────────────────────────
function API.SetShown(show)
    if show then
        Build()
        API.Layout()
        bar:Show()
    elseif bar then
        bar:Hide()
    end
end

function API.IsShown()
    return bar ~= nil and bar:IsShown()
end

function API.Toggle()
    API.SetShown(not API.IsShown())
    return API.IsShown()
end

-- Pone una textura de prueba en fondo+tapas (para verificar en vivo si una ruta carga).
function API.SetTestTexture(path)
    if not path or path == "" then return end
    API.SetShown(true)
    bar.center:SetTexture(path)
    bar.leftCap:SetTexture(path)
    bar.rightCap:SetTexture(path)
end

-- Ajusta la geometria y relayouta. Devuelve la tabla _cfg.
function API.SetGeometry(h, capW, slot, gap, count)
    local c = HarfordActionBars._cfg
    if h then
        c.h, c.capW, c.slot, c.gap, c.count = h, capW, slot, gap, count
    end
    if not bar then API.SetShown(true) end
    API.Layout()
    return c
end

function API.IsEnabled()
    return HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("actionbar") == "on"
end

function API.Refresh()
    API.SetShown(API.IsEnabled())
end

-- ─── Eventos ─────────────────────────────────────────────────────────────────
if HarfordConfig and HarfordConfig.RegisterChangeListener then
    HarfordConfig.RegisterChangeListener(function(key)
        if key == nil or key == "actionbar" then API.Refresh() end
    end)
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function()
        API.Refresh()
        f:UnregisterAllEvents()
    end)
end
