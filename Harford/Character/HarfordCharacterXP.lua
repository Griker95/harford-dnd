-- HarfordCharacterXP: sistema de experiencia propio de Harford (D&D 5e).
-- Epsilon no tiene comando fiable de XP (`.mod xp` no existe), asi que la XP es
-- enteramente de addon: vive en la progresion del perfil activo (campo `xp` de
-- HarfordDnDProgression, persiste y viaja con la ficha) y se muestra en una barra
-- anclada donde vive la barra de experiencia nativa (StatusTrackingBarManager).
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

-- Pone la XP al minimo que corresponde al nivel que YA tiene el personaje. Se llama al crear la
-- ficha, al cargarla del TRP3 y al terminar cada subida: un PJ de nivel 3 arranca con la XP de
-- nivel 3, no a 0.
--
-- Es un SUELO, no una asignacion: si ya tenias XP de sobra para el siguiente nivel se conserva,
-- porque la XP puede ir POR DELANTE del nivel. Ese desfase es justo lo que enciende el aviso de
-- subida disponible: el nivel de personaje solo cambia por el asistente, nunca solo.
function API.SyncToCharacterLevel(reason)
    if not Progression() then return false end
    local charLevel = (HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
        and HarfordDnDProgression.GetTotalLevel()) or 0
    if charLevel < 1 then return false end
    local minimo = XP_TABLE[math.min(charLevel, MAX_LEVEL)] or 0
    local antes = API.GetXP()
    if antes >= minimo then return false end
    if not API.SetXP(minimo) then return false end
    API.Refresh()
    if HarfordChat and HarfordChat.Print then
        HarfordChat.Print(string.format("Experiencia ajustada al nivel %d: %d XP%s",
            charLevel, minimo, (reason and reason ~= "") and (" (" .. reason .. ")") or ""))
    end
    return true
end

-- Acota la XP AL TRAMO del nivel que tiene el personaje: nunca por debajo de su umbral y nunca
-- tanta como para dar el siguiente nivel. Es lo que usa `/harford cargarficha`, donde la ficha
-- cargada manda sobre el nivel: si traias XP de sobra, te quedas en ese nivel con la barra llena
-- menos 1, en vez de con una subida pendiente que la ficha no contempla.
--
-- Se diferencia de SyncToCharacterLevel en el TECHO: alli la XP puede ir por delante del nivel
-- (subiste de nivel pero te sobraba XP); aqui no.
function API.ClampToCharacterLevel(reason)
    if not Progression() then return false end
    local charLevel = (HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel
        and HarfordDnDProgression.GetTotalLevel()) or 0
    if charLevel < 1 then return false end
    charLevel = math.min(charLevel, MAX_LEVEL)
    local antes = API.GetXP()
    local objetivo = math.max(antes, XP_TABLE[charLevel] or 0)
    -- En nivel maximo no hay tramo siguiente que acotar.
    local siguiente = XP_TABLE[charLevel + 1]
    if siguiente then objetivo = math.min(objetivo, siguiente - 1) end
    if objetivo == antes then return false end
    if not API.SetXP(objetivo) then return false end
    API.Refresh()
    if HarfordChat and HarfordChat.Print then
        HarfordChat.Print(string.format("Experiencia ajustada al nivel %d: %d XP%s",
            charLevel, objetivo, (reason and reason ~= "") and (" (" .. reason .. ")") or ""))
    end
    return true
end

-- Vuelve a empezar: XP a 0 (nivel 1). Solo lo llama la creacion de ficha desde cero, para que la
-- experiencia del personaje anterior no se cuele en el nuevo.
function API.ResetXP(reason)
    if not Progression() then return false end
    if not API.SetXP(0) then return false end
    API.Refresh()
    if HarfordChat and HarfordChat.Print and reason and reason ~= "" then
        HarfordChat.Print("Experiencia reiniciada a 0 (" .. reason .. ").")
    end
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

-- ── Barra de XP en el gestor nativo (StatusTrackingBarManager) ───────────────
-- El personaje es nivel maximo de WoW, asi que el gestor no muestra ninguna barra
-- nativa: registramos la nuestra como si fuera la barra de rep seguida, y es el
-- propio gestor quien recoloca el arte/la UI al aparecer o desaparecer (igual que
-- nativamente). Si este cliente no expone el gestor, cae a una barra propia.
do
    local xpBar, repBar      -- barras registradas en el gestor (false = intento fallido)
    local fallbackBar

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

    -- Crea una barra en el gestor nativo con su contrato (visibilidad/prioridad/pintado).
    local function CreateManagedBar(priority, shouldBeVisible, paint)
        local mgr = _G.StatusTrackingBarManager
        if not (mgr and mgr.AddBarFromTemplate and mgr.UpdateBarsShown) then return nil end
        if type(mgr.bars) ~= "table" then return nil end
        local before = #mgr.bars
        -- AddBarFromTemplate inserta la barra y llama UpdateBarsShown ANTES de que podamos
        -- asignarle metodos: ese primer UpdateBarsShown SIEMPRE lanza error (ShouldBeVisible
        -- nil) y ademas no devuelve la barra. Se ignora el error y se recupera la barra de
        -- mgr.bars: es OBLIGATORIO asignarle los metodos aunque el pcall falle, o queda una
        -- barra huerfana que rompe todos los GetNumberVisibleBars posteriores.
        pcall(mgr.AddBarFromTemplate, mgr, "FRAME", "StatusTrackingBarTemplate")
        if #mgr.bars <= before then return nil end
        local b = mgr.bars[#mgr.bars]
        b.ShouldBeVisible = shouldBeVisible
        b.GetPriority = function() return priority end
        b.Update = paint
        -- La plantilla base no trae mixin de texto (las nativas lo heredan de sus plantillas
        -- derivadas): crear FontString propio y las funciones que el gestor/hover esperan.
        if not b.SetBarText then
            local host = b.OverlayFrame or b
            local fs = host:CreateFontString(nil, "OVERLAY")
            fs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            fs:SetPoint("CENTER", b, "CENTER", 0, 0)
            fs:Hide()
            b._harfordText = fs
            b.SetBarText = function(_, txt) fs:SetText(txt or "") end
            b.ShowText = function() fs:Show() end
            b.HideText = function() fs:Hide() end
            b:EnableMouse(true)
            b:SetScript("OnEnter", function(self) self:ShowText() end)
            b:SetScript("OnLeave", function(self)
                if self.UpdateTextVisibility then self:UpdateTextVisibility() end
            end)
        end
        -- El gestor llama UpdateTextVisibility en cada barra (p.ej. SetTextLocked al abrir
        -- el panel de personaje): visible si el gestor lo bloquea, si la opcion nativa de
        -- Texto de estado esta activa, o si el raton esta encima.
        b.UpdateTextVisibility = b.UpdateTextVisibility or function(self)
            local m = _G.StatusTrackingBarManager
            local locked = m and m.IsTextLocked and m:IsTextLocked()
            if locked or AlwaysShowText() or (self.IsMouseOver and self:IsMouseOver()) then
                if self.ShowText then self:ShowText() end
            else
                if self.HideText then self:HideText() end
            end
        end
        -- Algunas rutas del gestor llaman UpdateTick/OnStatusBarsUpdated en cada barra
        b.UpdateTick = b.UpdateTick or function() end
        b.OnStatusBarsUpdated = b.OnStatusBarsUpdated or function(self) self:Update() end
        return b
    end

    local function PaintBar(bar, cur, size, r, g, b, text)
        local sb = bar.StatusBar
        if sb then
            sb:SetMinMaxValues(0, math.max(1, size))
            sb:SetValue(math.min(cur, size))
            if sb.SetStatusBarColor then sb:SetStatusBarColor(r, g, b, 1) end
        end
        if bar.SetBarText then pcall(bar.SetBarText, bar, text) end
        -- La visibilidad del texto la decide UpdateTextVisibility (bloqueo del gestor +
        -- opcion nativa de Texto de estado + hover)
        if bar.UpdateTextVisibility then pcall(bar.UpdateTextVisibility, bar) end
    end

    local function EnsureManagedBars()
        if xpBar == nil then
            xpBar = CreateManagedBar(5,
                function() return Enabled() and Progression() ~= nil end,
                function(self)
                    local _, cur, size = API.Progress()
                    PaintBar(self, cur, size, BAR_COLOR.r, BAR_COLOR.g, BAR_COLOR.b, XpText())
                end) or false
        end
        if repBar == nil then
            -- Reputacion seguida: MISMA opcion de config que la XP (Enabled). Solo visible
            -- si ademas hay una faccion seguida; con ambas, el gestor usa el layout doble.
            repBar = CreateManagedBar(6,
                function() return Enabled() and WatchedRepData() ~= nil end,
                function(self)
                    local d = WatchedRepData()
                    if not d then return end
                    PaintBar(self, d.cur, d.size, d.r, d.g, d.b,
                        string.format("%s: %d / %d (%s)", d.name, d.cur, d.size, d.standing))
                end) or false
        end
        return xpBar
    end

    -- Arte de la barra de experiencia, en un solo sitio para que la del borde inferior y la
    -- fina del panel de personaje no acaben pareciendose "casi".
    --
    -- `framed` reproduce el envoltorio de la barra nativa. Sale de la sonda del gestor
    -- (`/harford debug run probeframe StatusTrackingBarManager`): NO son piezas por secciones,
    -- es UN atlas OVERLAY del tamano exacto de la barra, que se estira al ancho que tenga; el
    -- gestor solo cambia de variante segun el ancho (large 804 / small 550). El relleno nativo
    -- es la textura 1098846, y la altura nativa de ambos es 14.
    local XP_FRAME_ATLAS = "hud-MainMenuBar-experiencebar-small-single"
    -- Ancho en pixeles de cada remate del envoltorio, sin escalar.
    local XP_FRAME_CAP = 12
    -- NO anadir una capa de tono con `XPBarAnim-OrangeGain`. La sonda la muestra a alpha 1 sobre
    -- la barra nativa, pero los `XPBarAnim-*` son las texturas de la ANIMACION de ganancia de XP
    -- (en reposo van a alpha 0); reproducirla aqui cubre la barra de amarillo, tanto en BLEND como
    -- en ADD. Comprobado en juego con `/harford debug run xpcapas tono off`.

    function API.SkinBar(bar, framed)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(BAR_COLOR.r, BAR_COLOR.g, BAR_COLOR.b, 1)
        bar:SetMinMaxValues(0, 1)
        local bg = bar.harfordBg
        if not bg then
            bg = bar:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(bar)
            bar.harfordBg = bg
        end
        bg:SetColorTexture(0, 0, 0, framed and 1 or 0.55)
        if not framed then return bar end

        -- Capas de la barra nativa, en su orden y con sus tintes exactos: carril tintado debajo
        -- del relleno y envoltorio encima. El relleno es la MISMA textura de arriba.
        if not bar.harfordRail then
            local rail = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
            rail:SetAllPoints(bar)
            rail:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            -- NO el 0.50,0.44,0.28 de la sonda: ese tostado es del carril nativo, que va bajo un
            -- envoltorio de 14 px que lo oculta. Con 9 px de alto se ve, y se lee como una barra
            -- amarilla en vez de como un hueco. Oscuro conserva el grano de la textura sin color.
            rail:SetVertexColor(0.16, 0.14, 0.13, 1)
            bar.harfordRail = rail
        end
        -- Envoltorio en TRES piezas. El atlas esta pensado para usarse a su ancho natural (550 u
        -- 804 segun variante); estirarlo a 199 apelotona los remates y la barra sale moteada. Se
        -- corta por UV: cada remate a su ancho real y el centro, que es liso, estirado.
        --
        -- Si el atlas no existe en este cliente la barra se queda sin marco pero legible; nunca
        -- con una textura de ruta inventada.
        local info = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(XP_FRAME_ATLAS)
        local archivo = info and (info.file or info.fileID)
        if not bar.harfordFrame and archivo then
            local u0, u1 = info.leftTexCoord, info.rightTexCoord
            local v0, v1 = info.topTexCoord, info.bottomTexCoord
            local anchoAtlas = tonumber(info.width) or 550
            local capPx = math.min(XP_FRAME_CAP, math.floor(anchoAtlas / 4))
            local frac = capPx / anchoAtlas
            local du = (u1 - u0)

            local izq = bar:CreateTexture(nil, "OVERLAY")
            izq:SetTexture(archivo)
            izq:SetTexCoord(u0, u0 + du * frac, v0, v1)
            izq:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
            izq:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
            izq:SetWidth(capPx)

            local der = bar:CreateTexture(nil, "OVERLAY")
            der:SetTexture(archivo)
            der:SetTexCoord(u1 - du * frac, u1, v0, v1)
            der:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
            der:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
            der:SetWidth(capPx)

            local centro = bar:CreateTexture(nil, "OVERLAY")
            centro:SetTexture(archivo)
            centro:SetTexCoord(u0 + du * frac, u1 - du * frac, v0, v1)
            centro:SetPoint("TOPLEFT", izq, "TOPRIGHT", 0, 0)
            centro:SetPoint("BOTTOMRIGHT", der, "BOTTOMLEFT", 0, 0)

            -- `harfordFrame` sigue siendo la referencia que apaga `xpcapas marco off`; las otras
            -- dos cuelgan de ella para no multiplicar campos en la barra.
            bar.harfordFrame = centro
            centro.piezas = { izq, der }
        end
        return bar
    end

    local function EnsureFallbackBar()
        if fallbackBar then return fallbackBar end
        local bar = CreateFrame("StatusBar", "HarfordXPBar", UIParent)
        -- Overlay de zona nativa: UIParent/MEDIUM (regla del proyecto)
        bar:SetFrameStrata("MEDIUM")
        bar:SetFrameLevel(85)
        bar:SetSize(570, 11)
        bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        API.SkinBar(bar)
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
        fallbackBar = bar
        return bar
    end

    -- La barra fina del panel de personaje la dibuja HarfordCharacterPanel y no se entera de un
    -- cambio de XP. Solo se repinta si la ventana esta abierta: Refresh() es un repintado
    -- completo del panel, no algo que lanzar a ciegas en cada evento.
    local function RefreshCharacterPanelBar()
        local f = _G.HarfordCharacterPanelFrame
        if not (f and f.IsShown and f:IsShown()) then return end
        local panel = _G.HarfordCharacterPanel
        if panel and panel.Refresh then panel.Refresh() end
    end

    -- Enciende o apaga una capa concreta de una barra ya pintada. Sirve para identificar en juego
    -- que capa produce un artefacto visual, en vez de ir tocando a ciegas desde fuera del cliente.
    function API.SetBarLayer(bar, capa, visible)
        local tex = bar and ({ carril = bar.harfordRail, tono = bar.harfordTone,
            marco = bar.harfordFrame, fondo = bar.harfordBg })[tostring(capa or "")]
        if not tex then return false end
        tex:SetShown(visible and true or false)
        for _, extra in ipairs(tex.piezas or {}) do extra:SetShown(visible and true or false) end
        return true
    end

    function API.Refresh()
        RefreshCharacterPanelBar()
        -- Via nativa: el gestor decide mostrar/ocultar y recoloca la UI
        if EnsureManagedBars() then
            local mgr = _G.StatusTrackingBarManager
            if xpBar then pcall(xpBar.Update, xpBar) end
            if repBar then pcall(repBar.Update, repBar) end
            if mgr and mgr.UpdateBarsShown then pcall(mgr.UpdateBarsShown, mgr) end
            if fallbackBar then fallbackBar:Hide() end
            return
        end
        -- Fallback sin gestor: barra propia en el borde inferior
        if not Enabled() or not Progression() then
            if fallbackBar then fallbackBar:Hide() end
            return
        end
        local b = EnsureFallbackBar()
        local _, cur, size = API.Progress()
        b:SetMinMaxValues(0, math.max(1, size))
        b:SetValue(math.min(cur, size))
        b.Text:SetText(XpText())
        b.Text:SetShown(AlwaysShowText() or (b.IsMouseOver and b:IsMouseOver()) or false)
        b:Show()
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
