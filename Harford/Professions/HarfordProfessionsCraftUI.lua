-- HarfordProfessionsCraftUI: ventana de recetas de una profesion Harford, replica del
-- TradeSkillFrame moderno. Toda la geometria sale de la sonda `nativeprobe prof` diffeada
-- contra `nativeprobe harford` (nuestra propia captura); los valores exactos y el porque de
-- cada uno estan en el contrato de AGENTS.md.
-- Solo UI: todos los datos/acciones pasan por HarfordProfessions (CanCraft/Craft).

HarfordProfessionsCraftUI = HarfordProfessionsCraftUI or {}
local API = HarfordProfessionsCraftUI

local frame            -- ventana (creada bajo demanda)
local state = { profId = nil, selected = nil, offset = 0, rows = {}, reagents = {}, search = "" }

local ROWS_VISIBLE = 23
local ROW_H = 16

-- Color de dificultad por margen de skill (aproximacion de los colores nativos)
local function DifficultyColor(skill, req)
    if skill < req then return 0.5, 0.5, 0.5 end          -- aun no disponible (gris oscuro)
    local margin = skill - req
    if margin < 20 then return 1.0, 0.5, 0.25 end         -- naranja: sube casi seguro
    if margin < 45 then return 1.0, 1.0, 0.0 end          -- amarillo
    if margin < 70 then return 0.25, 0.75, 0.25 end       -- verde
    return 0.6, 0.6, 0.6                                  -- gris: trivial
end

local function Prof()
    return state.profId and HarfordProfessions and HarfordProfessions.GetDefinition
        and HarfordProfessions.GetDefinition(state.profId) or nil
end

local RefreshUI  -- forward

-- TEXTURAS: los fileID NUMERICOS de la sonda son la fuente correcta.
--
-- Comprobado con el diff entre la captura del TradeSkillFrame nativo y la nuestra: el frame
-- nativo usa EXACTAMENTE estos numeros (136569 riel del scroll, 136571 borde de la barra,
-- 132086/132085 pestanas...), asi que el cliente los resuelve perfectamente. Sustituirlos por
-- rutas "equivalentes" fue un error: esas rutas NO existen y la ventana se quedo sin esas
-- piezas. Regla: copiar el fileID tal cual de la sonda; solo usar ruta cuando la sonda
-- devuelva una ruta. Lo que no cargue se registra en API._textureIssues (`crafttex`).
API._textureIssues = {}

local function SafeTexture(texture, source, label)
    if not texture then return false end
    if type(source) == "number" then
        texture:SetTexture(source)   -- fileID tomado del nativo: no se inventa nada
        return true
    end
    if GetFileIDFromPath and not GetFileIDFromPath(source) then
        API._textureIssues[#API._textureIssues + 1] = (label or "?") .. " -> " .. tostring(source)
        texture:Hide()
        return false
    end
    texture:SetTexture(source)
    return true
end

-- fileID EXACTOS del TradeSkillFrame nativo (captura nativo2).
local TEX = {
    barBorder = 136571,
    scrollRail = 136569,
    scrollKnob = 130849,
    tabActive = 132086,
    tabInactive = 132085,
    tabHighlight = 136580,
    nameFrame = 136796,
}

-- Algunos nombres de icono del catalogo NO existen en el cliente Epsilon (se renderizan
-- como cuadrado verde): validar la ruta contra el cliente y caer al icono del item resultante.
local function RecipeIconTexture(rec)
    local path = rec and rec.icon and ("Interface\\Icons\\" .. rec.icon) or nil
    if path and GetFileIDFromPath and GetFileIDFromPath(path) then return path end
    -- Si el icono declarado no existe, se usa el del OBJETO RESULTANTE, que es lo que la
    -- receta fabrica. Si tampoco lo hay, interrogacion: mejor eso que un icono de otra cosa.
    local outId = rec and HarfordProfessions and HarfordProfessions.GetOutputItemId
        and HarfordProfessions.GetOutputItemId(rec.id)
    local tex = outId and GetItemIcon and GetItemIcon(outId)
    if tex then return tex end
    if outId then API.NoteMissingIcon(outId) end
    if path and not GetFileIDFromPath then return path end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ── Construccion ─────────────────────────────────────────────────────────────
local function CreateReagentSlot(parent, index)
    -- Geometria nativa exacta: boton 147x41 en dos columnas encadenadas (col2 a la derecha
    -- de col1 sin hueco) y filas a -2. El icono va SIN recorte y el borde blanco del nativo
    -- esta OCULTO (vis=None en la sonda): mostrarlo es lo que dibujaba "marcos raros".
    local slot = CreateFrame("Frame", nil, parent)
    slot:SetSize(147, 41)
    local column = (index - 1) % 2
    local rowIndex = math.floor((index - 1) / 2)
    slot:SetPoint("TOPLEFT", parent, "TOPLEFT", 5 + column * 147, -120 - rowIndex * 43)
    slot.icon = slot:CreateTexture(nil, "BACKGROUND")
    slot.icon:SetSize(39, 39)
    slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 0, 0)
    local bg = slot:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\QuestFrame\\UI-QuestItemNameFrame")
    bg:SetSize(128, 64)
    bg:SetPoint("LEFT", slot.icon, "RIGHT", -10, 0)
    slot.count = slot:CreateFontString(nil, "OVERLAY")
    slot.count:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
    slot.count:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", -1, 1)
    slot.name = slot:CreateFontString(nil, "BORDER")
    slot.name:SetFont("Fonts\\FRIZQT__.TTF", 12)
    slot.name:SetPoint("LEFT", bg, "LEFT", 15, 0)
    slot.name:SetSize(92, 12)
    slot.name:SetJustifyH("LEFT")
    slot.name:SetWordWrap(false)   -- el nombre partido se salia del marco
    -- Tooltip del material (como el nativo). Si la clave aun no tiene itemId real,
    -- se muestra el nombre del catalogo para que la receta siga siendo legible.
    slot:EnableMouse(true)
    slot:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.itemId then
            GameTooltip:SetHyperlink("item:" .. self.itemId)
        else
            GameTooltip:SetText(self.itemName or "?", 1, 1, 1)
            GameTooltip:AddLine("Pendiente de crear en el vault", 1, 0.35, 0.35)
        end
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return slot
end

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(300, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_H))
    row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
    row.sel = row:CreateTexture(nil, "BACKGROUND")
    row.sel:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
    row.sel:SetAllPoints(row)
    row.sel:SetAlpha(0.6)
    row.sel:Hide()
    row.text = row:CreateFontString(nil, "ARTWORK")
    row.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWidth(288)
    row.text:SetWordWrap(false)
    -- Contador de recetas del grupo (solo cabeceras, en oro a la derecha como el nativo)
    row.count = row:CreateFontString(nil, "ARTWORK")
    row.count:SetFont("Fonts\\FRIZQT__.TTF", 12)
    row.count:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.count:SetTextColor(1, 0.82, 0)
    row:SetScript("OnClick", function(self)
        if self.recipeId then
            state.selected = self.recipeId
            RefreshUI()
        end
    end)
    return row
end

local function CreateFrameIfNeeded()
    if frame then return frame end
    frame = CreateFrame("Frame", "HarfordProfessionsCraftFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(670, 496)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(520)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    table.insert(UISpecialFrames, "HarfordProfessionsCraftFrame")

    -- DOS insets nativos (sonda prof_seleccion): el TradeSkillFrame no usa el inset unico
    -- del template sino dos paneles con marco propio; ocultamos el del ButtonFrameTemplate.
    if frame.Inset then frame.Inset:Hide() end
    local okL, insetLeft = pcall(CreateFrame, "Frame", nil, frame, "InsetFrameTemplate")
    if not okL then
        insetLeft = CreateFrame("Frame", nil, frame)
        local bg = insetLeft:CreateTexture(nil, "BACKGROUND", nil, -5)
        bg:SetTexture(374154); bg:SetAllPoints(insetLeft)
    end
    insetLeft:SetSize(325, 410)
    insetLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -80)
    local okR, insetRight = pcall(CreateFrame, "Frame", nil, frame, "InsetFrameTemplate")
    if not okR then
        insetRight = CreateFrame("Frame", nil, frame)
        local bg = insetRight:CreateTexture(nil, "BACKGROUND", nil, -5)
        bg:SetTexture(374154); bg:SetAllPoints(insetRight)
    end
    insetRight:SetSize(335, 390)
    insetRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -80)
    frame.insetLeft, frame.insetRight = insetLeft, insetRight

    -- Barra de skill superior nativa: 447x14 CENTRADA (TOP +0,-33), fill 136570 azul puro y
    -- borde en TRES piezas de 136571 (caps 9x20 a -3/+3 + centro estirado), texto FRIZQT 10.
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetSize(447, 14)
    bar:SetPoint("TOP", frame, "TOP", 0, -33)
    bar:SetStatusBarTexture(136570)   -- mismo fileID que la barra nativa
    -- Nativo (dato crudo de la sonda): el relleno va con alpha 0.5 y SIN fondo negro debajo;
    -- con alpha 1 y una banda negra la barra se ve como una franja dura y desencajada.
    bar:SetStatusBarColor(0, 0, 1, 0.5)
    local fill = bar:GetStatusBarTexture()
    if fill then fill:SetAlpha(0.5); fill:SetDrawLayer("BACKGROUND") end
    bar:SetMinMaxValues(0, 300)
    -- Sin marco: los fileID del borde nativo (136571) salen como una CAJA BLANCA en este
    -- cliente. Mejor una barra limpia con fondo oscuro que un rectangulo blanco encima.
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetColorTexture(0, 0, 0, 0.55)
    barBg:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
    barBg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
    frame.skillBar = bar
    frame.skillText = bar:CreateFontString(nil, "OVERLAY")
    frame.skillText:SetFont("Fonts\\FRIZQT__.TTF", 10)
    frame.skillText:SetTextColor(1, 1, 1)
    frame.skillText:SetPoint("CENTER", bar, "CENTER", 0, 0)

    -- Panel izquierdo: lista de recetas (Inset del template hace de marco)
    local list = CreateFrame("Frame", nil, frame)
    list:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -83)  -- nativo: ScrollFrame +7,-83
    list:SetSize(300, ROWS_VISIBLE * ROW_H)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        state.offset = math.max(0, state.offset - delta)
        RefreshUI()
    end)
    frame.list = list
    for i = 1, ROWS_VISIBLE do
        state.rows[i] = CreateRow(list, i)
    end

    -- SCROLLBAR por PLANTILLA de Blizzard.
    -- Montarlo a mano con los fileID del nativo (136569 riel, 130849 pomo) sale VERDE en este
    -- cliente: son fileID de arte Classic y Epsilon no los traduce para addons, aunque su propio
    -- XML si los cargue. La plantilla la construye el cliente, asi que su arte carga siempre.
    local slider = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
    slider:SetWidth(16)
    slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, -16)
    slider:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 4, 16)
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider._updating = false
    slider:SetScript("OnValueChanged", function(self, value)
        if self._updating then return end
        state.offset = math.floor(value + 0.5)
        RefreshUI()
    end)
    frame.scrollSlider = slider
    -- PESTAÑAS por plantilla nativa. Con los fileID de HelpFrameTab (132086/132085) salian
    -- rectangulos grises lisos: mismo problema que el riel del scroll.
    local function CreateListTab(label)
        local ok, tab = pcall(CreateFrame, "Button", nil, frame, "CharacterFrameTabButtonTemplate")
        if not ok or not tab then
            ok, tab = pcall(CreateFrame, "Button", nil, frame, "UIPanelButtonTemplate")
        end
        if not ok or not tab then return nil end
        tab:SetText(label)
        if tab.GetTextWidth and tab.SetWidth then tab:SetWidth(tab:GetTextWidth() + 34) end
        function tab:SetActiveLook(active)
            -- La plantilla de pestaña trae Disable/Enable como estado activo/inactivo.
            if self.SetDisabledFontObject and self.Disable and self.Enable then
                if active then self:Disable() else self:Enable() end
            elseif self.SetAlpha then
                self:SetAlpha(active and 1 or 0.7)
            end
        end
        return tab
    end
    frame.tabLearned = CreateListTab("Aprendidas")
    if frame.tabLearned then
        frame.tabLearned:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 6, 2)
        frame.tabLearned:SetScript("OnClick", function()
            state.tab = "learned"; state.offset = 0; state.selected = nil; RefreshUI()
        end)
    end
    frame.tabUnlearned = CreateListTab("No aprendidas")
    if frame.tabUnlearned then
        frame.tabUnlearned:SetPoint("LEFT", frame.tabLearned, "RIGHT", -4, 0)
        frame.tabUnlearned:SetScript("OnClick", function()
            state.tab = "unlearned"; state.offset = 0; state.selected = nil; RefreshUI()
        end)
    end
    state.tab = "learned"

    -- Caja de busqueda nativa (112x20 en +220,-54, bordes common-search + lupa); filtra la lista
    local search = CreateFrame("EditBox", nil, frame)
    search:SetSize(112, 20)
    search:SetPoint("TOPLEFT", frame, "TOPLEFT", 350, -56)
    search:SetAutoFocus(false)
    search:SetMaxLetters(40)
    search:SetFont("Fonts\\FRIZQT__.TTF", 10)
    search:SetTextInsets(16, 4, 0, 0)
    local hasSearch = C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("common-search-border-middle")
    if hasSearch then
        local sL = search:CreateTexture(nil, "BACKGROUND")
        sL:SetAtlas("common-search-border-left"); sL:SetSize(8, 20)
        sL:SetPoint("LEFT", search, "LEFT", -5, 0)
        local sR = search:CreateTexture(nil, "BACKGROUND")
        sR:SetAtlas("common-search-border-right"); sR:SetSize(8, 20)
        sR:SetPoint("RIGHT", search, "RIGHT", 0, 0)
        local sM = search:CreateTexture(nil, "BACKGROUND")
        sM:SetAtlas("common-search-border-middle")
        sM:SetPoint("LEFT", sL, "RIGHT", 0, 0)
        sM:SetPoint("RIGHT", sR, "LEFT", 0, 0)
        local lupa = search:CreateTexture(nil, "OVERLAY")
        lupa:SetAtlas("common-search-magnifyingglass"); lupa:SetSize(10, 10)
        lupa:SetVertexColor(0.6, 0.6, 0.6)
        lupa:SetPoint("LEFT", search, "LEFT", 1, -1)
    else
        local sBg = search:CreateTexture(nil, "BACKGROUND")
        sBg:SetColorTexture(0, 0, 0, 0.5); sBg:SetAllPoints(search)
    end
    search.placeholder = search:CreateFontString(nil, "ARTWORK")
    search.placeholder:SetFont("Fonts\\FRIZQT__.TTF", 10)
    search.placeholder:SetTextColor(0.35, 0.35, 0.35)
    search.placeholder:SetPoint("LEFT", search, "LEFT", 16, 0)
    search.placeholder:SetText("Buscar")
    search:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    search:SetScript("OnEnterPressed", search.ClearFocus)
    search:SetScript("OnTextChanged", function(self)
        self.placeholder:SetShown(self:GetText() == "")
        state.search = self:GetText() or ""
        state.offset = 0
        RefreshUI()
    end)
    frame.searchBox = search

    -- Panel derecho: detalle de la receta, dentro del inset derecho nativo
    local detail = CreateFrame("Frame", nil, frame)
    detail:SetPoint("TOPLEFT", insetRight, "TOPLEFT", 3, -3)
    detail:SetPoint("BOTTOMRIGHT", insetRight, "BOTTOMRIGHT", -3, 3)
    frame.detail = detail
    -- Fondo del detalle: tamaño FIJO 310x383 en TOPLEFT -5,0 (estirarlo a todo el panel
    -- deformaba el pergamino), capa BACKGROUND -1 como el nativo.
    local detailBg = detail:CreateTexture(nil, "BACKGROUND", nil, -1)
    if detailBg.SetAtlas and C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("tradeskill-background-recipe") then
        detailBg:SetAtlas("tradeskill-background-recipe")
        detailBg:SetSize(310, 383)
        detailBg:SetPoint("TOPLEFT", detail, "TOPLEFT", -5, 0)
    else
        detailBg:SetColorTexture(0.08, 0.07, 0.06, 0.92)
        detailBg:SetAllPoints(detail)
    end

    -- Icono de la receta: 47x47 en +10,-20 con el borde 51x51 CENTRADO (el nativo usa un
    -- marco MAS GRANDE centrado, no uno del mismo tamaño pegado al icono).
    detail.icon = detail:CreateTexture(nil, "ARTWORK")
    detail.icon:SetSize(47, 47)
    detail.icon:SetPoint("TOPLEFT", detail, "TOPLEFT", 10, -20)
    detail.iconBorder = detail:CreateTexture(nil, "OVERLAY")
    detail.iconBorder:SetSize(51, 51)
    detail.iconBorder:SetPoint("CENTER", detail.icon, "CENTER", 0, 0)
    if detail.iconBorder.SetAtlas and C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("tradeskills-iconborder") then
        detail.iconBorder:SetAtlas("tradeskills-iconborder")
    else
        detail.iconBorder:Hide()
    end
    -- Zona de raton sobre el icono para el tooltip del objeto resultante (el nativo lo tiene)
    detail.iconHit = CreateFrame("Frame", nil, detail)
    detail.iconHit:SetAllPoints(detail.icon)
    detail.iconHit:EnableMouse(true)
    detail.iconHit:SetScript("OnEnter", function(self)
        if not self.itemId then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.itemId)
        GameTooltip:Show()
    end)
    detail.iconHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    detail.name = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    detail.name:SetPoint("TOPLEFT", detail.icon, "TOPRIGHT", 10, -2)
    detail.name:SetWidth(220)
    detail.name:SetJustifyH("LEFT")
    detail.req = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail.req:SetPoint("TOPLEFT", detail.icon, "TOPRIGHT", 10, -26)
    detail.req:SetJustifyH("LEFT")
    detail.reagentsTitle = detail:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detail.reagentsTitle:SetPoint("TOPLEFT", detail, "TOPLEFT", 8, -96)
    detail.reagentsTitle:SetText("Materiales")

    -- Botonera nativa: [Crear todo] ... [cantidad] [Crear] [Salir], todos 80x22
    --
    -- EL CRAFTEO ES UNO POR UNO: nunca hay dos en vuelo. Pedir varias unidades encola, no dispara
    -- una rafaga. Cada pieza espera a que las bolsas CONFIRMEN el gasto de la anterior antes de
    -- empezar la siguiente, porque `RemoveItem` es un comando de servidor asincrono y encadenar a
    -- ciegas dejaria craftear con material ya gastado (ademas de reventar el servidor a comandos).
    local MAX_QUEUE = 20
    local CRAFT_TIME = 3.0   -- fundicion visible, al estilo del lanzamiento nativo
    local queue = { left = 0, timeout = nil }
    local bagWatcher = CreateFrame("Frame")

    -- Barra de fundicion con el arte de la barra de lanzamiento nativa. El OnUpdate solo vive
    -- mientras dura la fundicion y se retira al terminar (no hay ticks permanentes).
    local castBar = CreateFrame("StatusBar", nil, frame)
    castBar:SetSize(220, 18)
    castBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 10)
    castBar:SetStatusBarTexture(136570)
    castBar:SetStatusBarColor(1, 0.7, 0)
    castBar:SetMinMaxValues(0, 1)
    local castBg = castBar:CreateTexture(nil, "BACKGROUND")
    castBg:SetColorTexture(0, 0, 0, 0.6)
    castBg:SetAllPoints(castBar)
    local castBorder = castBar:CreateTexture(nil, "OVERLAY")
    local borderPath = "Interface\\CastingBar\\UI-CastingBar-Border"
    if not GetFileIDFromPath or GetFileIDFromPath(borderPath) then
        castBorder:SetTexture(borderPath)
        castBorder:SetPoint("TOPLEFT", castBar, "TOPLEFT", -23, 20)
        castBorder:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 23, -20)
    else
        castBorder:Hide()
    end
    castBar.text = castBar:CreateFontString(nil, "OVERLAY")
    castBar.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    castBar.text:SetPoint("CENTER", castBar, "CENTER", 0, 0)
    castBar:Hide()
    frame.castBar = castBar

    local function CancelCast()
        castBar:SetScript("OnUpdate", nil)
        castBar:Hide()
    end

    local function StopQueue(reason)
        queue.left = 0
        bagWatcher:UnregisterAllEvents()
        if queue.timeout then queue.timeout = nil end
        CancelCast()
        if reason and HarfordChat and HarfordChat.Print then HarfordChat.Print(reason) end
        RefreshUI()
    end
    frame:HookScript("OnHide", function() StopQueue() end)

    local ResolveCraft

    -- Fundicion: animacion de artesano en el personaje + barra + sonido, y la receta se
    -- resuelve (tirada incluida) SOLO al terminar la barra.
    local function BeginCast(recipeName)
        if HarfordServerActions and HarfordServerActions.ModAnim then
            HarfordServerActions.ModAnim(69, { addonName = "Harford", showMessages = false })
        end
        if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("craft_started") end
        castBar.text:SetText(recipeName or "")
        castBar:SetValue(0)
        castBar:Show()
        local elapsed = 0
        castBar:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            self:SetValue(math.min(1, elapsed / CRAFT_TIME))
            if elapsed >= CRAFT_TIME then
                CancelCast()
                ResolveCraft()
            end
        end)
    end

    local CraftNext
    ResolveCraft = function()
        if not (state.selected and HarfordProfessions and HarfordProfessions.Craft) then
            return StopQueue()
        end
        -- Craft revalida CanCraft por su cuenta y descuenta el material reservado, asi que una
        -- pieza que ya no se puede hacer corta la cola en vez de seguir intentandolo.
        local ok = HarfordProfessions.Craft(state.selected)
        if HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play(ok and "craft_succeeded" or "craft_failed")
        end
        if not ok then return StopQueue() end
        if queue.left <= 0 then return StopQueue() end
        -- Encadenar solo cuando el servidor confirme el gasto (o rendirse si no llega).
        bagWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
        local token = {}
        queue.timeout = token
        if C_Timer and C_Timer.After then
            C_Timer.After(6, function()
                if queue.timeout == token and queue.left > 0 then
                    StopQueue("Crafteo interrumpido: el servidor no confirmo el gasto de materiales.")
                end
            end)
        end
        RefreshUI()
    end

    CraftNext = function()
        if queue.left <= 0 then return StopQueue() end
        if not state.selected then return StopQueue() end
        queue.left = queue.left - 1
        local rec = HarfordProfessions and HarfordProfessions.GetRecipe
            and HarfordProfessions.GetRecipe(state.selected)
        BeginCast(rec and (rec.name or rec.id) or "")
    end

    bagWatcher:SetScript("OnEvent", function()
        bagWatcher:UnregisterAllEvents()
        queue.timeout = nil
        if queue.left > 0 then CraftNext() end
    end)

    local function CraftTimes(n)
        if queue.left > 0 then return end  -- ya hay una cola en marcha: no solapar
        n = math.max(1, math.min(math.floor(tonumber(n) or 1), MAX_QUEUE))
        queue.left = n
        CraftNext()
    end
    state.IsCrafting = function() return queue.left > 0 end
    local exitBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exitBtn:SetSize(80, 22)
    exitBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)
    exitBtn:SetText("Salir")
    exitBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.craftBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.craftBtn:SetSize(80, 22)
    frame.craftBtn:SetPoint("TOPRIGHT", exitBtn, "TOPLEFT", -1, 0)
    frame.craftBtn:SetText("Crear")
    frame.craftBtn:SetScript("OnClick", function()
        CraftTimes(frame.qtyBox and frame.qtyBox:GetNumber() or 1)
    end)
    -- Caja de cantidad nativa: EditBox 31x20 con bordes common-search y ARIALN 14
    local qty = CreateFrame("EditBox", nil, frame)
    qty:SetSize(31, 20)
    qty:SetPoint("RIGHT", frame.craftBtn, "LEFT", -8, 0)
    qty:SetAutoFocus(false)
    qty:SetNumeric(true)
    qty:SetMaxLetters(3)
    qty:SetFont("Fonts\\ARIALN.TTF", 14)
    qty:SetJustifyH("CENTER")
    qty:SetText("1")
    qty:SetScript("OnEscapePressed", qty.ClearFocus)
    qty:SetScript("OnEnterPressed", qty.ClearFocus)
    local hasSearchAtlas = C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("common-search-border-middle")
    if hasSearchAtlas then
        local qL = qty:CreateTexture(nil, "BACKGROUND")
        qL:SetAtlas("common-search-border-left"); qL:SetSize(8, 20)
        qL:SetPoint("LEFT", qty, "LEFT", -5, 0)
        local qR = qty:CreateTexture(nil, "BACKGROUND")
        qR:SetAtlas("common-search-border-right"); qR:SetSize(8, 20)
        qR:SetPoint("RIGHT", qty, "RIGHT", 0, 0)
        local qM = qty:CreateTexture(nil, "BACKGROUND")
        qM:SetAtlas("common-search-border-middle")
        qM:SetPoint("LEFT", qL, "RIGHT", 0, 0)
        qM:SetPoint("RIGHT", qR, "LEFT", 0, 0)
    else
        local qBg = qty:CreateTexture(nil, "BACKGROUND")
        qBg:SetColorTexture(0, 0, 0, 0.5); qBg:SetAllPoints(qty)
    end
    frame.qtyBox = qty
    frame.craftAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.craftAllBtn:SetSize(80, 22)
    frame.craftAllBtn:SetPoint("RIGHT", qty, "LEFT", -13, 0)
    frame.craftAllBtn:SetText("Crear todo")
    frame.craftAllBtn:SetScript("OnClick", function()
        CraftTimes(frame.craftAllBtn.craftableCount or 1)
    end)
    return frame
end

-- ── Refresco ─────────────────────────────────────────────────────────────────
RefreshUI = function()
    if not (frame and frame:IsShown()) then return end
    local def = Prof()
    if not (def and HarfordProfessions) then return end
    local skill = HarfordProfessions.EffectiveSkill(def.id)

    if frame.TitleText then
        -- El titulo salia cortado ("Herreri"): el TitleText del template viene estrecho.
        frame.TitleText:SetWidth(0)
        frame.TitleText:SetText(def.name)
    end
    if frame.portrait then
        -- SetPortraitToTexture recorta en circulo (evita el cuadrado con esquinas oscuras)
        if SetPortraitToTexture then
            SetPortraitToTexture(frame.portrait, "Interface\\Icons\\" .. (def.icon or "INV_Misc_QuestionMark"))
        else
            frame.portrait:SetTexture("Interface\\Icons\\" .. (def.icon or "INV_Misc_QuestionMark"))
            frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end
    if frame.tabLearned and frame.tabLearned.SetActiveLook then frame.tabLearned:SetActiveLook(state.tab ~= "unlearned") end
    if frame.tabUnlearned and frame.tabUnlearned.SetActiveLook then frame.tabUnlearned:SetActiveLook(state.tab == "unlearned") end
    frame.skillBar:SetValue(skill)
    -- Formato nativo de la barra: "Herreria 50/300" (el rango va en las cabeceras de grupo)
    frame.skillText:SetText(string.format("%s %d/%d", def.name, skill, HarfordProfessions.MAX_SKILL))

    -- Filtro por pestaña: Aprendidas = disponibles (las normales van con la profesion);
    -- No aprendidas = recetas worldLearned que el DM aun no ha enseñado.
    local Strip = HarfordClassColors and HarfordClassColors.StripAccents or tostring
    local needle = state.search ~= "" and Strip(state.search):lower() or nil
    local recipes = {}
    for _, r in ipairs(HarfordProfessions.GetRecipes(def.id) or {}) do
        local learned = not HarfordProfessions.IsRecipeLearned
            or HarfordProfessions.IsRecipeLearned(r.id)
        if (state.tab == "unlearned") ~= (learned and true or false) then
            if not needle or Strip(tostring(r.name or r.id)):lower():find(needle, 1, true) then
                recipes[#recipes + 1] = r
            end
        end
    end
    -- Seleccion valida por defecto: la primera receta
    local selValid = false
    for _, r in ipairs(recipes) do if r.id == state.selected then selValid = true break end end
    if not selValid then state.selected = recipes[1] and recipes[1].id or nil end

    -- Lista con cabeceras de grupo por rango de skill (oro + contador, como el nativo):
    -- se ordena por skillReq y se inserta una cabecera cada vez que cambia el rango.
    table.sort(recipes, function(a, b)
        local sa, sb = tonumber(a.skillReq) or 1, tonumber(b.skillReq) or 1
        if sa ~= sb then return sa < sb end
        return tostring(a.name or a.id) < tostring(b.name or b.id)
    end)
    local display, lastTier, headerIdx = {}, nil, nil
    for _, r in ipairs(recipes) do
        local tier = HarfordProfessions.GetTierName(tonumber(r.skillReq) or 1)
        if tier ~= lastTier then
            display[#display + 1] = { header = tier, count = 0 }
            headerIdx = #display
            lastTier = tier
        end
        display[headerIdx].count = display[headerIdx].count + 1
        display[#display + 1] = r
    end

    local maxOffset = math.max(0, #display - ROWS_VISIBLE)
    state.offset = math.max(0, math.min(state.offset, maxOffset))
    if frame.scrollSlider then
        local s = frame.scrollSlider
        s._updating = true
        s:SetMinMaxValues(0, maxOffset)
        s:SetValue(state.offset)
        s._updating = false
    end
    for i = 1, ROWS_VISIBLE do
        local row = state.rows[i]
        local entry = display[state.offset + i]
        if entry and entry.header then
            -- Cabecera de grupo: rango en ORO con el contador de recetas a la derecha
            row.recipeId = nil
            row.text:SetText(entry.header)
            row.text:SetTextColor(1, 0.82, 0)
            row.count:SetText(tostring(entry.count))
            row.sel:Hide()
            row:Show()
        elseif entry then
            local rec = entry
            row.recipeId = rec.id
            local r, g, b = DifficultyColor(skill, tonumber(rec.skillReq) or 1)
            -- El numero entre corchetes es CUANTAS puedes fabricar con tus materiales
            -- (como el nativo), no el requisito de skill (ese va en el detalle).
            local craftable
            do
                local _, _, mats = HarfordProfessions.CanCraft(rec.id)
                for _, m in ipairs(mats or {}) do
                    local possible = m.missingId and 0 or math.floor((m.have or 0) / math.max(1, m.need or 1))
                    craftable = craftable and math.min(craftable, possible) or possible
                end
            end
            row.text:SetText((rec.name or rec.id)
                .. ((craftable and craftable > 0) and (" [" .. craftable .. "]") or ""))
            row.text:SetTextColor(r, g, b)
            row.count:SetText("")
            row.sel:SetShown(rec.id == state.selected)
            row:Show()
        else
            row.recipeId = nil
            row:Hide()
        end
    end

    -- Detalle de la seleccionada
    local sel
    for _, r in ipairs(recipes) do if r.id == state.selected then sel = r break end end
    local d = frame.detail
    if not sel then
        d.name:SetText("")
        d.req:SetText("")
        for _, slot in ipairs(state.reagents) do slot:Hide() end
        frame.craftBtn:SetEnabled(false)
        if frame.craftAllBtn then
            frame.craftAllBtn.craftableCount = 0
            frame.craftAllBtn:SetEnabled(false)
        end
        return
    end
    d.icon:SetTexture(RecipeIconTexture(sel))
    if d.iconHit then
        d.iconHit.itemId = HarfordProfessions.GetOutputItemId
            and HarfordProfessions.GetOutputItemId(sel.id) or nil
    end
    d.name:SetText(sel.name or sel.id)
    local ok, reason, detailMats = HarfordProfessions.CanCraft(sel.id)
    d.req:SetText(string.format("Requiere skill %d%s", tonumber(sel.skillReq) or 1,
        ok and "" or ("  |cffff5555" .. tostring(reason or "") .. "|r")))
    local mats = detailMats or {}
    for i, m in ipairs(mats) do
        local slot = state.reagents[i]
        if not slot then
            slot = CreateReagentSlot(d, i)
            state.reagents[i] = slot
        end
        local enough = (m.have or 0) >= (m.need or 1)
        -- Detalle de CanCraft: { key, name, need, have, id, missingId }
        if m.id and GetItemIcon then
            local ico = GetItemIcon(m.id)
            if not ico then API.NoteMissingIcon(m.id) end
            slot.icon:SetTexture(ico or "Interface\\Icons\\INV_Misc_QuestionMark")
        else
            slot.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        slot.icon:SetDesaturated(m.missingId and true or false)
        -- Nativo: icono e info en gris (0.5) cuando faltan materiales, blanco si hay bastante,
        -- y el contador con el formato "0 /15" en ARIALN.
        local tint = enough and 1 or 0.5
        slot.icon:SetVertexColor(tint, tint, tint)
        slot.count:SetText(string.format("%d /%d", m.have or 0, m.need or 1))
        slot.count:SetTextColor(1, 1, 1)
        slot.name:SetText(m.name or "?")
        slot.name:SetTextColor(tint, tint, tint)
        slot.itemId, slot.itemName = m.id, m.name
        slot:Show()
    end
    for i = #mats + 1, #state.reagents do state.reagents[i]:Hide() end
    frame.craftBtn:SetEnabled(ok and true or false)
    if frame.craftAllBtn then
        -- "Crear todo" fabrica tantas veces como permitan los materiales actuales
        local craftableCount
        for _, m in ipairs(mats) do
            local possible = m.missingId and 0 or math.floor((m.have or 0) / math.max(1, m.need or 1))
            craftableCount = craftableCount and math.min(craftableCount, possible) or possible
        end
        craftableCount = (ok and craftableCount and craftableCount > 0) and craftableCount or 0
        frame.craftAllBtn.craftableCount = craftableCount
        frame.craftAllBtn:SetEnabled(craftableCount > 0)
    end
end

-- ── API publica ──────────────────────────────────────────────────────────────
function API.Open(profId)
    profId = tostring(profId or ""):lower()
    if not (HarfordProfessions and HarfordProfessions.GetDefinition and HarfordProfessions.GetDefinition(profId)) then
        return false, "Profesion desconocida: " .. profId
    end
    CreateFrameIfNeeded()
    if state.profId ~= profId then
        state.selected, state.offset = nil, 0
    end
    state.profId = profId
    frame:Show()
    RefreshUI()
    return true
end

function API.Close()
    if frame then frame:Hide() end
end

-- El icono de un item custom de Epsilon llega vacio hasta que el cliente cachea el item.
-- Se solicita y se repinta al recibirlo, en vez de dejar una interrogacion fija.
do
    local waiting = false
    local f = CreateFrame("Frame")
    f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    f:SetScript("OnEvent", function()
        if waiting and frame and frame:IsShown() then
            waiting = false
            RefreshUI()
        end
    end)
    API.NoteMissingIcon = function(itemId)
        if itemId and GetItemInfo then
            waiting = true
            GetItemInfo(itemId)
        end
    end
end

function API.Refresh()
    RefreshUI()
end
