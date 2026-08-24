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
    bar.fichas = {}
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
    if API.RefreshTurnEconomy then API.RefreshTurnEconomy() end
end

-- ─── INDICADORES DE ECONOMIA DE TURNO ────────────────────────────────────────
-- Fichas de Accion / Adicional / Reaccion sobre la barra, al estilo BG3: una ficha por punto
-- disponible, encendida si te queda y apagada si la gastaste.
--
-- El presupuesto NO siempre es 1: Impetu de Accion da una accion extra, asi que se pinta una ficha
-- por punto y no una por tipo. Eso es lo que hace que se lea de un vistazo cuantas te quedan.
--
-- Se alimentan de `HarfordDnDConditions.Turn`, que es la fuente unica de la economia (la misma que
-- muestra el texto de la seccion Ataque). Solo se ven con orden de turnos activo: fuera de combate
-- no se lleva la cuenta y unas fichas llenas serian informacion falsa.
--
-- Sin ticker: el motor de condiciones avisa a sus listeners al gastar y al reiniciar el turno.
local FICHA_TAM, FICHA_HUECO = 15, 4
local COLOR_FICHA = {
    action   = { 0.91, 0.71, 0.30 },   -- dorado
    bonus    = { 0.39, 0.76, 0.42 },   -- verde
    reaction = { 0.49, 0.56, 0.88 },   -- azul
}
local TEX_MARCO = "Interface\\Common\\WhiteIconFrame"

local function Economia()
    return HarfordDnDConditions and HarfordDnDConditions.Turn
end

local function EnsureFicha(i)
    local f = bar.fichas[i]
    if f then return f end
    f = CreateFrame("Frame", nil, bar)
    f:SetSize(FICHA_TAM, FICHA_TAM)
    f.fondo = f:CreateTexture(nil, "ARTWORK")
    f.fondo:SetPoint("TOPLEFT", 2, -2)
    f.fondo:SetPoint("BOTTOMRIGHT", -2, 2)
    f.marco = f:CreateTexture(nil, "OVERLAY")
    f.marco:SetTexture(TEX_MARCO)
    f.marco:SetAllPoints()
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        if not (GameTooltip and self.etiqueta) then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(self.etiqueta, 1, 1, 1)
        GameTooltip:AddLine(self.gastada and "Gastada este turno" or "Disponible",
            self.gastada and 0.7 or 0.3, self.gastada and 0.3 or 0.9, 0.3)
        if self.kind == "reaction" then
            -- La regla que mas se confunde: la reaccion NO vuelve al acabar el asalto.
            GameTooltip:AddLine("Vuelve al empezar tu turno", 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    bar.fichas[i] = f
    return f
end

-- Redibuja la fila entera. Devuelve cuantas fichas quedaron visibles.
function API.RefreshTurnEconomy()
    if not bar then return 0 end
    bar.fichas = bar.fichas or {}
    local T = Economia()
    if not (T and T.IsActive and T.IsActive()) then
        for _, f in ipairs(bar.fichas) do f:Hide() end
        return 0
    end
    local n = 0
    for _, kind in ipairs(T.ORDEN or {}) do
        local total = T.GetBudget(kind)
        local quedan = T.GetRemaining(kind)
        for punto = 1, total do
            n = n + 1
            local f = EnsureFicha(n)
            f.kind, f.etiqueta = kind, T.ETIQUETA[kind]
            f.gastada = punto > quedan
            local c = COLOR_FICHA[kind] or { 0.7, 0.7, 0.7 }
            if f.gastada then
                f.fondo:SetColorTexture(c[1] * 0.22, c[2] * 0.22, c[3] * 0.22, 0.9)
                f.marco:SetVertexColor(0.35, 0.35, 0.35)
            else
                f.fondo:SetColorTexture(c[1], c[2], c[3], 1)
                f.marco:SetVertexColor(c[1] * 1.1, c[2] * 1.1, c[3] * 1.1)
            end
            f:ClearAllPoints()
            if n == 1 then
                f:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", HarfordActionBars._cfg.capW + 10, 3)
            else
                f:SetPoint("LEFT", bar.fichas[n - 1], "RIGHT", FICHA_HUECO, 0)
            end
            f:Show()
        end
    end
    for i = n + 1, #bar.fichas do bar.fichas[i]:Hide() end
    return n
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

-- El motor de condiciones avisa al gastar una accion y al reiniciar el turno. Un solo listener,
-- sin ticker: es la regla del proyecto y aqui basta de sobra.
if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
    HarfordDnDConditions.RegisterListener(function()
        if API.IsShown and API.IsShown() then API.RefreshTurnEconomy() end
    end)
end
