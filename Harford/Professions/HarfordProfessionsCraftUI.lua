-- HarfordProfessionsCraftUI: ventana de recetas de una profesion Harford, replica del
-- TradeSkillFrame moderno (sonda nativeprobe prof 2026-08-21): ButtonFrameTemplate 670x496,
-- barra de skill superior (UI-Character-Skills-Bar + caps 136571), lista izquierda de filas
-- 300x16 con highlight UI-Listbox-Highlight2 y colores de dificultad, y panel derecho de
-- detalle (tradeskills-iconborder + slots de reactivos UI-QuestItemNameFrame 128x64 con
-- iconos 39 y borde auctionhouse-itemicon-border-white) con boton Crear.
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

-- Algunos nombres de icono del catalogo NO existen en el cliente Epsilon (se renderizan
-- como cuadrado verde): validar la ruta contra el cliente y caer al icono del item resultante.
local function RecipeIconTexture(rec)
    local path = rec and rec.icon and ("Interface\\Icons\\" .. rec.icon) or nil
    if path and GetFileIDFromPath and GetFileIDFromPath(path) then return path end
    local outId = rec and HarfordProfessions and HarfordProfessions.GetOutputItemId
        and HarfordProfessions.GetOutputItemId(rec.id)
    local tex = outId and GetItemIcon and GetItemIcon(outId)
    if tex then return tex end
    if path and not GetFileIDFromPath then return path end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ── Construccion ─────────────────────────────────────────────────────────────
-- Slot de reactivo con la geometria NATIVA exacta (estudio 2026-08-21): icono 39x39 con el
-- borde blanco DEL MISMO tamaño encima, y el UI-QuestItemNameFrame 128x64 anclado a
-- icono.RIGHT -10 (el marco abraza al icono, no flota separado).
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
    slot.name:SetSize(90, 36)
    slot.name:SetJustifyH("LEFT")
    slot.name:SetWordWrap(true)
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
    bar:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
    -- Nativo (dato crudo de la sonda): el relleno va con alpha 0.5 y SIN fondo negro debajo;
    -- con alpha 1 y una banda negra la barra se ve como una franja dura y desencajada.
    bar:SetStatusBarColor(0, 0, 1, 0.5)
    local fill = bar:GetStatusBarTexture()
    if fill then fill:SetAlpha(0.5); fill:SetDrawLayer("BACKGROUND") end
    bar:SetMinMaxValues(0, 300)
    local capL = bar:CreateTexture(nil, "OVERLAY")
    capL:SetTexture(136571)
    capL:SetTexCoord(0.0078429999, 0.0431369990, 0.1935479939, 0.7741929889)
    capL:SetSize(9, 20); capL:SetPoint("LEFT", bar, "LEFT", -3, 0)
    local capR = bar:CreateTexture(nil, "OVERLAY")
    capR:SetTexture(136571)
    capR:SetTexCoord(0.0431369990, 0.0078429999, 0.1935479939, 0.7741929889)
    capR:SetSize(9, 20); capR:SetPoint("RIGHT", bar, "RIGHT", 3, 0)
    local barMid = bar:CreateTexture(nil, "OVERLAY")
    barMid:SetTexture(136571)
    barMid:SetTexCoord(0.1137259975, 0.1490195989, 0.1935479938, 0.7741929888)
    barMid:SetPoint("TOPLEFT", capL, "TOPRIGHT", 0, 0)
    barMid:SetPoint("BOTTOMRIGHT", capR, "BOTTOMLEFT", 0, 0)
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

    -- Scrollbar con el arte nativo (estudio: Slider 20 ancho en lista.TOPRIGHT +1,-14;
    -- riel 136569 en 3 piezas, thumb 130849 18x24, botones 18x16)
    local slider = CreateFrame("Slider", nil, frame)
    slider:SetOrientation("VERTICAL")
    slider:SetWidth(20)
    slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 1, -14)
    slider:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 1, 12)  -- nativo: doble anclaje
    local railTop = slider:CreateTexture(nil, "ARTWORK")
    railTop:SetTexture(136569)
    railTop:SetTexCoord(0, 0.484375, 0, 0.2)
    railTop:SetSize(27, 48)
    railTop:SetPoint("TOPLEFT", slider, "TOPLEFT", -4, 17)
    local railBottom = slider:CreateTexture(nil, "ARTWORK")
    railBottom:SetTexture(136569)
    railBottom:SetTexCoord(0.515625, 1, 0.1440625, 0.4140625)
    railBottom:SetSize(27, 64)
    railBottom:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", -4, -15)
    local railMid = slider:CreateTexture(nil, "ARTWORK")
    railMid:SetTexture(136569)
    railMid:SetTexCoord(0, 0.484375, 0.1640625, 1)
    railMid:SetPoint("TOPLEFT", railTop, "BOTTOMLEFT", 0, 0)
    railMid:SetPoint("BOTTOMRIGHT", railBottom, "TOPRIGHT", 0, 0)
    slider:SetThumbTexture(130849)
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(18, 24)
    thumb:SetTexCoord(0.2, 0.8, 0.125, 0.875)
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider._updating = false
    slider:SetScript("OnValueChanged", function(self, value)
        if self._updating then return end
        state.offset = math.floor(value + 0.5)
        RefreshUI()
    end)
    frame.scrollSlider = slider
    local upBtn = CreateFrame("Button", nil, slider)
    upBtn:SetSize(18, 16)
    upBtn:SetPoint("BOTTOM", slider, "TOP", 0, -2)
    upBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    upBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    upBtn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
    upBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight", "ADD")
    upBtn:SetScript("OnClick", function()
        state.offset = math.max(0, state.offset - 1)
        RefreshUI()
    end)
    local downBtn = CreateFrame("Button", nil, slider)
    downBtn:SetSize(18, 16)
    downBtn:SetPoint("TOP", slider, "BOTTOM", 0, 2)
    downBtn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    downBtn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    downBtn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
    downBtn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight", "ADD")
    downBtn:SetScript("OnClick", function()
        local mx = select(2, frame.scrollSlider:GetMinMaxValues())
        state.offset = math.min(mx, state.offset + 1)
        RefreshUI()
    end)

    -- Pestañas Aprendidas/No aprendidas sobre la lista (arte nativo HelpFrameTab en 3
    -- piezas: activa 132086 al ras, inactiva 132085 hundida -3; texto oro/blanco FRIZQT 10)
    local function CreateListTab(width, label)
        local tab = CreateFrame("Button", nil, frame)
        tab:SetSize(width, 32)
        local mid = width - 32
        tab.pieces = {}
        local coords = { { 0, 0.25 }, { 0.25, 0.75 }, { 0.75, 1 } }
        local widths = { 16, mid, 16 }
        for i = 1, 3 do
            local t = tab:CreateTexture(nil, "BACKGROUND")
            t:SetTexCoord(coords[i][1], coords[i][2], 0, 1)
            t:SetSize(widths[i], 32)
            if i == 1 then
                t:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
            else
                t:SetPoint("LEFT", tab.pieces[i - 1], "RIGHT", 0, 0)
            end
            tab.pieces[i] = t
        end
        tab.text = tab:CreateFontString(nil, "ARTWORK")
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
        tab.text:SetPoint("CENTER", tab, "CENTER", 0, 2)
        tab.text:SetText(label)
        local hl = tab:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture(136580)
        hl:SetPoint("BOTTOM", tab, "BOTTOM", 2, -8)
        hl:SetSize(width, 32)
        function tab:SetActiveLook(active)
            for _, t in ipairs(self.pieces) do
                t:SetTexture(active and 132086 or 132085)
                -- La inactiva queda 3px hundida (nativo)
            end
            self.pieces[1]:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, active and 0 or -3)
            self.text:SetTextColor(active and 1 or 1, active and 0.82 or 1, active and 0 or 1)
            self.text:SetPoint("CENTER", self, "CENTER", 0, active and 2 or -3)
        end
        return tab
    end
    frame.tabLearned = CreateListTab(90, "Aprendidas")
    frame.tabLearned:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 10, 3)
    frame.tabLearned:SetScript("OnClick", function()
        state.tab = "learned"; state.offset = 0; state.selected = nil; RefreshUI()
    end)
    frame.tabUnlearned = CreateListTab(110, "No aprendidas")
    frame.tabUnlearned:SetPoint("LEFT", frame.tabLearned, "RIGHT", 0, 0)
    frame.tabUnlearned:SetScript("OnClick", function()
        state.tab = "unlearned"; state.offset = 0; state.selected = nil; RefreshUI()
    end)
    state.tab = "learned"

    -- Caja de busqueda nativa (112x20 en +220,-54, bordes common-search + lupa); filtra la lista
    local search = CreateFrame("EditBox", nil, frame)
    search:SetSize(112, 20)
    search:SetPoint("TOPLEFT", frame, "TOPLEFT", 220, -54)
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
    local function CraftTimes(n)
        if not (state.selected and HarfordProfessions and HarfordProfessions.Craft) then return end
        n = math.max(1, math.min(tonumber(n) or 1, 20))  -- tope prudente de comandos de servidor
        for _ = 1, n do
            if not HarfordProfessions.Craft(state.selected) then break end
        end
        RefreshUI()
    end
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

    if frame.TitleText then frame.TitleText:SetText(def.name) end
    if frame.portrait then
        -- SetPortraitToTexture recorta en circulo (evita el cuadrado con esquinas oscuras)
        if SetPortraitToTexture then
            SetPortraitToTexture(frame.portrait, "Interface\\Icons\\" .. (def.icon or "INV_Misc_QuestionMark"))
        else
            frame.portrait:SetTexture("Interface\\Icons\\" .. (def.icon or "INV_Misc_QuestionMark"))
            frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end
    if frame.tabLearned then frame.tabLearned:SetActiveLook(state.tab ~= "unlearned") end
    if frame.tabUnlearned then frame.tabUnlearned:SetActiveLook(state.tab == "unlearned") end
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
            slot.icon:SetTexture(GetItemIcon(m.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
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

function API.Refresh()
    RefreshUI()
end
