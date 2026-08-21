-- HarfordCharacterXP: sistema de experiencia propio de Harford (D&D 5e).
-- Epsilon no tiene comando fiable de XP (`.mod xp` no existe), asi que la XP es
-- enteramente de addon: vive en la progresion del perfil activo (campo `xp` de
-- HarfordDnDProgression, persiste y viaja con la ficha) y se muestra en una barra
-- anclada en el borde inferior, sin modificar el gestor privado de barras nativas.
-- La subida de nivel sigue siendo MANUAL y se abre con `/harford char subir`:
-- la XP solo informa de cuando hay nivel disponible, nunca aplica niveles por si sola.
-- Preparado para que en el futuro la misma barra pueda alternar a reputacion seguida.

HarfordCharacterXP = HarfordCharacterXP or {}
local API = HarfordCharacterXP

-- Tabla oficial 5e de XP acumulada necesaria para cada nivel (1..20)
local XP_TABLE = {
    0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000,
    85000, 100000, 120000, 140000, 165000, 195000, 225000, 265000, 305000, 355000,
}
API.XP_TABLE = XP_TABLE
local MAX_LEVEL = #XP_TABLE

local BAR_COLOR = { r = 0.58, g = 0.0, b = 0.55 }  -- morado XP nativo

local function Enabled()
    if HarfordConfig and HarfordConfig.Get then
        return HarfordConfig.Get("xpbar") ~= "off"
    end
    return true
end

local function Progression()
    return HarfordDnDProgression and HarfordDnDProgression.Get and HarfordDnDProgression.Get() or nil
end

function API.GetXP()
    local data = Progression()
    local xp = data and tonumber(data.xp) or 0
    if xp < 0 then xp = 0 end
    return math.floor(xp)
end

-- Nivel que corresponde a una cantidad de XP acumulada.
function API.LevelForXP(xp)
    xp = tonumber(xp) or 0
    local level = 1
    for i = 1, MAX_LEVEL do
        if xp >= XP_TABLE[i] then level = i else break end
    end
    return level
end

-- Progreso dentro del tramo actual: nivelXP, xpDentroDelTramo, tamanoDelTramo.
-- En nivel maximo devuelve tramo completo (barra llena).
function API.Progress()
    local xp = API.GetXP()
    local level = API.LevelForXP(xp)
    if level >= MAX_LEVEL then
        return level, 1, 1
    end
    local base = XP_TABLE[level]
    local nextReq = XP_TABLE[level + 1]
    return level, xp - base, nextReq - base
end

-- ¿Hay subida de nivel pendiente? (XP alcanza un nivel superior al total actual de clases)
function API.PendingLevelUp()
    local xpLevel = API.LevelForXP(API.GetXP())
    local charLevel = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
        and HarfordDnDProgression.GetTotalLevel() or 0
    if (charLevel or 0) <= 0 then return false end
    return xpLevel > charLevel
end

function API.SetXP(amount)
    if not (HarfordDnDProgression and HarfordDnDProgression.SetXP) then return false end
    local ok = HarfordDnDProgression.SetXP(amount)
    if not ok then return false end
    return true
end

-- Suma XP al perfil activo. Imprime la ganancia y avisa si hay nivel disponible.
function API.AddXP(amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return false end
    local data = Progression()
    if not data then
        if HarfordChat and HarfordChat.Print then
            HarfordChat.Print("XP sin conceder: no hay progresion activa (crea la ficha primero).")
        end
        return false
    end
    local before = API.GetXP()
    local levelBefore = API.LevelForXP(before)
    if not API.SetXP(before + amount) then return false end
    local levelAfter = API.LevelForXP(API.GetXP())
    if HarfordChat and HarfordChat.Print then
        local msg = string.format("%s%d XP", amount >= 0 and "+" or "", amount)
        if reason and reason ~= "" then msg = msg .. " (" .. tostring(reason) .. ")" end
        HarfordChat.Print(msg)
        if levelAfter > levelBefore then
            HarfordChat.Print("|cff00ff00¡Nivel " .. levelAfter .. " disponible!|r Usa /harford char subir.")
        end
    end
    API.Refresh()
    return true
end

-- ── Barras de XP y reputacion seguidas ──────────────────────────────────────
-- No se registran dentro de StatusTrackingBarManager. Ese gestor llama a sus
-- contratos privados durante AddBarFromTemplate y, en este cliente, lo hace antes
-- de que un addon pueda instalar ShouldBeVisible/Update. Una barra Harford propia
-- evita errores silenciosos y no modifica las barras nativas del jugador.
do
    local barHolder
    local xpBar
    local repBar

    -- ── Faccion seguida (per-PJ, en HarfordReputationStore.ui.watchedByChar) ──
    local function WatchedMap()
        if type(HarfordReputationStore) ~= "table" then return nil end
        HarfordReputationStore.ui = HarfordReputationStore.ui or {}
        HarfordReputationStore.ui.watchedByChar = HarfordReputationStore.ui.watchedByChar or {}
        return HarfordReputationStore.ui.watchedByChar
    end

    function API.GetWatchedFaction()
        local map = WatchedMap()
        local me = UnitName and UnitName("player")
        return map and me and map[me] or nil
    end

    function API.SetWatchedFaction(factionId)
        local map = WatchedMap()
        local me = UnitName and UnitName("player")
        if not (map and me) then return false end
        map[me] = factionId
        API.Refresh()
        return true
    end

    function API.ToggleWatchedFaction(factionId, displayName)
        local current = API.GetWatchedFaction()
        local watching = current ~= factionId
        API.SetWatchedFaction(watching and factionId or nil)
        if HarfordChat and HarfordChat.Print then
            local name = tostring(displayName or factionId)
            HarfordChat.Print(watching and ("Siguiendo en la barra de estado: " .. name)
                or ("Dejas de seguir: " .. name))
        end
        if HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("reputation_tracking_changed")
        end
        return watching
    end

    -- Color de barra de reputacion = colores NATIVOS por standing (FACTION_BAR_COLORS),
    -- igual que las filas del panel; el hex del rango es solo para textos.
    local STANDING_BY_NAME = {
        odiado = 1, hostil = 2, adverso = 3, neutral = 4,
        amistoso = 5, honorable = 6, reverenciado = 7, exaltado = 8,
    }
    local function StandingBarColor(standingText)
        local id = STANDING_BY_NAME[tostring(standingText or ""):lower()] or 4
        local c = FACTION_BAR_COLORS and FACTION_BAR_COLORS[id]
        if c then return c.r or 0.5, c.g or 0.5, c.b or 0.5 end
        return 0, 0.6, 0.1
    end

    local function XpText()
        local level, cur, size = API.Progress()
        local txt
        if level >= MAX_LEVEL then
            txt = string.format("Nivel %d (maximo) — %s XP", level, tostring(API.GetXP()))
        else
            txt = string.format("Nivel %d — %d / %d XP", level, cur, size)
        end
        if API.PendingLevelUp() then
            txt = txt .. "  |cff00ff00¡Subida disponible!|r"
        end
        return txt
    end

    -- Datos de la faccion seguida: nombre, cur, size, texto de rango y color
    local function WatchedRepData()
        local fid = API.GetWatchedFaction()
        if not fid or not (HarfordReputation and HarfordReputation.GetFaction) then return nil end
        local faction = HarfordReputation.GetFaction(fid)
        if not faction then return nil end
        local points = HarfordReputation.GetCurrentPlayerPoints
            and HarfordReputation.GetCurrentPlayerPoints(fid) or 0
        points = tonumber(points) or 0
        local standingText, rankColor, rank = HarfordReputation.GetRank(points)
        local minV, maxV = 0, 1
        if rank then
            minV = tonumber(rank.min) or 0
            maxV = tonumber(rank.max) or (minV + 1)
        end
        local cur, size
        if maxV <= minV then
            cur, size = 1, 1  -- rango tope (Exaltado): barra llena
        else
            size = maxV - minV
            cur = math.max(0, math.min(points - minV, size))
        end
        local r, g, b = StandingBarColor(standingText)
        return {
            name = faction.name or fid, cur = cur, size = size,
            standing = standingText or "", r = r, g = g, b = b,
        }
    end

    -- Opcion nativa "Texto de estado" (Interfaz): con statusTextDisplay != NONE el texto
    -- de las barras se muestra SIEMPRE, no solo al hover (mismo criterio que la barra de
    -- exp nativa y que los compact frames Harford).
    local function AlwaysShowText()
        local v = GetCVar and GetCVar("statusTextDisplay")
        return v ~= nil and v ~= "NONE"
    end

    local function CreateBar(name, parent)
        local bar = CreateFrame("StatusBar", name, parent)
        bar:SetSize(570, 11)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetMinMaxValues(0, 1)
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        bg:SetColorTexture(0, 0, 0, 0.55)
        local text = bar:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        text:Hide()
        bar.Text = text
        bar:EnableMouse(true)
        bar:SetScript("OnEnter", function(self) self.Text:Show() end)
        bar:SetScript("OnLeave", function(self)
            if not AlwaysShowText() then self.Text:Hide() end
        end)
        return bar
    end

    local function EnsureBars()
        if barHolder then return end
        barHolder = CreateFrame("Frame", "HarfordStatusBars", UIParent)
        barHolder:SetFrameStrata("MEDIUM")
        barHolder:SetFrameLevel(85)
        barHolder:SetSize(570, 24)
        barHolder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        xpBar = CreateBar("HarfordXPBar", barHolder)
        repBar = CreateBar("HarfordReputationBar", barHolder)
    end

    local function PaintBar(bar, cur, size, r, g, b, text)
        bar:SetMinMaxValues(0, math.max(1, size))
        bar:SetValue(math.min(cur, size))
        bar:SetStatusBarColor(r, g, b, 1)
        bar.Text:SetText(text or "")
        bar.Text:SetShown(AlwaysShowText() or (bar.IsMouseOver and bar:IsMouseOver()) or false)
    end

    function API.Refresh()
        if not Enabled() or not Progression() then
            if barHolder then barHolder:Hide() end
            return
        end
        EnsureBars()
        local _, cur, size = API.Progress()
        local rep = WatchedRepData()
        if rep then
            xpBar:ClearAllPoints()
            xpBar:SetPoint("BOTTOM", barHolder, "BOTTOM", 0, 0)
            repBar:ClearAllPoints()
            repBar:SetPoint("BOTTOM", xpBar, "TOP", 0, 1)
            PaintBar(repBar, rep.cur, rep.size, rep.r, rep.g, rep.b,
                string.format("%s: %d / %d (%s)", rep.name, rep.cur, rep.size, rep.standing))
            repBar:Show()
        else
            repBar:Hide()
            xpBar:ClearAllPoints()
            xpBar:SetPoint("BOTTOM", barHolder, "BOTTOM", 0, 0)
        end
        PaintBar(xpBar, cur, size, BAR_COLOR.r, BAR_COLOR.g, BAR_COLOR.b, XpText())
        xpBar:Show()
        barHolder:Show()
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("CVAR_UPDATE")  -- reflejar el toggle nativo de "Texto de estado"
    events:SetScript("OnEvent", function(_, event)
        if event == "CVAR_UPDATE" then
            API.Refresh()
            return
        end
        -- Diferido puntual: la progresion del perfil activo puede cargar tras el login.
        if C_Timer and C_Timer.After then C_Timer.After(0, API.Refresh) else API.Refresh() end
    end)

    if HarfordConfig and HarfordConfig.RegisterChangeListener then
        HarfordConfig.RegisterChangeListener(function(key)
            if key == "xpbar" then API.Refresh() end
        end)
    end
end
