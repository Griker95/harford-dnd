-- HarfordProfessionsCraftUI: ventana de recetas de una profesion Harford, replica del
-- TradeSkillFrame moderno. Toda la geometria sale de la sonda `nativeprobe prof` diffeada
-- contra `nativeprobe harford` (nuestra propia captura); los valores exactos y el porque de
-- cada uno estan en el contrato de AGENTS.md.
-- Solo UI: todos los datos/acciones pasan por HarfordProfessions (CanCraft/Craft).

HarfordProfessionsCraftUI = HarfordProfessionsCraftUI or {}
local API = HarfordProfessionsCraftUI

-- Marca de compilacion: permite comprobar QUE version esta corriendo el cliente, en vez de
-- suponer que lo copiado a disco es lo que se ejecuta. Ver `/harford debug run craftver`.
API.BUILD = "20260821-124720"


local frame            -- ventana (creada bajo demanda)
local state = { profId = nil, selected = nil, offset = 0, rows = {}, reagents = {}, search = "",
                collapsed = {} }

local ROWS_VISIBLE = 25   -- nativo: lista de 405 de alto = 25 filas de 16
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

-- TEXTURAS: SIEMPRE por RUTA. Los fileID numericos NO se resuelven para addons en Epsilon.
--
-- Medido con `/harford debug run texpath`, que pregunta al cliente a que fileID resuelve cada
-- ruta y lo contrasta con el que la sonda leyo del frame nativo: todas estas rutas COINCIDEN
-- con el numero del nativo, luego son el mismo arte. Pero pasar ese numero a SetTexture desde
-- un addon pinta verde o una caja blanca: el nativo lo carga por ruta desde su XML.
--
-- OJO con las pestañas: los ficheros estan INVERTIDOS respecto a su nombre. La ruta
-- "HelpFrameTab-Active" resuelve a 132085, y el nativo usa 132086 para la pestaña ACTIVA,
-- que es el fichero llamado "-Inactive". No fiarse del nombre, fiarse del fileID.
API._textureIssues = {}

local function SafeTexture(texture, source, label)
    if not texture then return false end
    if GetFileIDFromPath and type(source) == "string" and not GetFileIDFromPath(source) then
        API._textureIssues[#API._textureIssues + 1] = (label or "?") .. " -> " .. tostring(source)
        texture:Hide()
        return false
    end
    texture:SetTexture(source)
    return true
end

-- Rutas VERIFICADAS contra el fileID que usa el frame nativo (ver texpath).
local TEX = {
    barFill      = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",        -- 136570
    barBorder    = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder",  -- 136571
    scrollRail   = "Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar",         -- 136569
    scrollKnob   = "Interface\\Buttons\\UI-ScrollBar-Knob",                         -- 130849
    tabActive    = "Interface\\HelpFrame\\HelpFrameTab-Inactive",                   -- 132086 (si, invertido)
    tabInactive  = "Interface\\HelpFrame\\HelpFrameTab-Active",                     -- 132085
    tabHighlight = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",     -- 136580
    nameFrame    = "Interface\\QuestFrame\\UI-QuestItemNameFrame",                  -- 136796
    rowHighlight = "Interface\\Buttons\\UI-Listbox-Highlight2",                     -- 130783
    -- Resaltado del icono de plegar (16x16), NO de la fila entera: el XML nativo lo declara
    -- como HighlightTexture del boton con tamano y anclaje propios.
    expanderHi   = "Interface\\Buttons\\UI-PlusButton-Hilight",
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
    -- El XML declara TradeSkillReagentTemplate como `inherits="LargeItemButtonTemplate"`:
    -- 147x41, icono 39x39, NameFrame UI-QuestItemNameFrame 128x64 a icono.RIGHT -10,
    -- nombre 90x36 a NameFrame.LEFT +15 y el borde blanco del icono OCULTO por defecto.
    local ok, slot = pcall(CreateFrame, "Button", nil, parent, "LargeItemButtonTemplate")
    if not ok or not slot then return nil end
    local column = (index - 1) % 2
    local rowIndex = math.floor((index - 1) / 2)
    -- Anclados a la etiqueta "Materiales", NO a una `y` fija del panel: la descripcion y los
    -- requisitos crecen con el texto de cada receta, y con un -120 fijo los materiales se les
    -- montaban encima. El XML nativo hace lo mismo (Reagents -> ReagentLabel.BOTTOMLEFT -5,-6).
    local ancla = parent.reagentsTitle or parent
    local relativo = parent.reagentsTitle and "BOTTOMLEFT" or "TOPLEFT"
    local baseY = parent.reagentsTitle and -6 or -120
    local baseX = parent.reagentsTitle and -5 or 5
    slot:SetPoint("TOPLEFT", ancla, relativo, baseX + column * 147, baseY - rowIndex * 43)
    slot.icon = slot.Icon or slot.icon
    slot.name = slot.Name or slot.name
    if not slot.count then
        slot.count = slot:CreateFontString(nil, "OVERLAY")
        slot.count:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
        slot.count:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", -1, 1)
    end
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

-- Habilita o apaga la caja de cantidad Y sus flechas. `NumericInputSpinnerTemplate` trae su
-- propio SetEnabled, que es el que pone las flechas en su textura Disabled.
-- Estado de las flechas de un scroll, con la regla de siempre:
--   sin recorrido            -> las dos apagadas
--   arriba del todo          -> la de subir apagada
--   abajo del todo           -> la de bajar apagada
--   en medio                 -> las dos encendidas
-- Un Slider no lo hace por su cuenta: en el nativo lo hace ScrollFrame_OnScrollRangeChanged.
-- Las plantillas nombran sus flechas de dos formas segun cual sea, asi que se prueban ambas.
local function UpdateScrollArrows(slider)
    if not slider then return end
    local minimo, maximo = slider:GetMinMaxValues()
    minimo, maximo = minimo or 0, maximo or 0
    local valor = slider:GetValue() or 0
    local hayRecorrido = maximo > minimo
    local arriba = slider.ScrollUpButton or slider.ScrollUp
    local abajo = slider.ScrollDownButton or slider.ScrollDown
    if arriba and arriba.SetEnabled then arriba:SetEnabled(hayRecorrido and valor > minimo) end
    if abajo and abajo.SetEnabled then abajo:SetEnabled(hayRecorrido and valor < maximo) end
    if slider.SetEnabled then slider:SetEnabled(hayRecorrido) end
end

local function SetQuantityEnabled(enabled)
    local qty = frame and frame.qtyBox
    if not qty then return end
    if qty.SetEnabled then pcall(qty.SetEnabled, qty, enabled and true or false) end
    if qty.IncrementButton then qty.IncrementButton:SetEnabled(enabled and true or false) end
    if qty.DecrementButton then qty.DecrementButton:SetEnabled(enabled and true or false) end
end

local function CreateRow(parent, index)
    -- XML TradeSkillRowButtonTemplate: boton 300x16; el icono de plegar es 16x16 en LEFT +3
    -- (no +23, deduccion mia equivocada), el texto va a su RIGHT +2,+1 con 270x13 y fuente
    -- GameFontHighlightLeft, la seleccion es UI-Listbox-Highlight2 y el hueco de la derecha
    -- (SkillUps) ocupa 26x16 en RIGHT -2.
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(300, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * ROW_H))
    -- XML TradeSkillRowButtonTemplate: el HighlightTexture es UI-PlusButton-Hilight de 16x16 en
    -- LEFT +3, es decir SOLO sobre el icono de plegar. Sin tamano ni anclaje, WoW lo estira a
    -- todo el boton y aparece la franja blanca que no tiene el nativo.
    row:SetHighlightTexture(TEX.expanderHi, "ADD")
    row.hi = row:GetHighlightTexture()
    if row.hi then
        row.hi:SetSize(16, 16)
        row.hi:ClearAllPoints()
        row.hi:SetPoint("LEFT", row, "LEFT", 3, 0)
    end
    -- XML: SelectedTexture es UI-Listbox-Highlight2 en capa ARTWORK, oculta por defecto. Se crea
    -- ANTES que el texto para que este quede por encima dentro de la misma capa.
    row.sel = row:CreateTexture(nil, "ARTWORK")
    row.sel:SetTexture(TEX.rowHighlight)
    row.sel:SetAllPoints(row)
    row.sel:Hide()
    row.expander = CreateFrame("Button", nil, row)
    row.expander:SetSize(16, 16)
    row.expander:SetPoint("LEFT", row, "LEFT", 3, 0)
    row.expander:Hide()
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightLeft")
    row.text:SetPoint("LEFT", row.expander, "RIGHT", 2, 1)
    row.text:SetJustifyH("LEFT")
    row.text:SetSize(270, 13)
    row.text:SetWordWrap(false)
    -- Lo que el nativo SI cambia al pasar por encima es el color del texto, porque su texto es
    -- el ButtonText del boton y usa la fuente de resaltado. Aqui el texto es una FontString
    -- propia (hace falta para colorearlo por dificultad), asi que el cambio se hace a mano
    -- guardando el color base y devolviendolo al salir.
    row:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
    end)
    row:SetScript("OnLeave", function(self)
        -- La fila seleccionada se queda en blanco aunque salga el raton, como el nativo.
        if self.recipeId and self.recipeId == state.selected then
            self.text:SetTextColor(1, 1, 1)
            return
        end
        local c = self.baseColor
        if c then self.text:SetTextColor(c[1], c[2], c[3]) else self.text:SetTextColor(1, 0.82, 0) end
    end)

    row.count = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.count:SetPoint("RIGHT", row, "RIGHT", -2, 1)
    row.count:SetTextColor(1, 0.82, 0)
    row:SetScript("OnClick", function(self)
        if self.recipeId then
            -- Solo al CAMBIAR de receta: repicar sobre la ya seleccionada seria ruido.
            if state.selected ~= self.recipeId and HarfordUISounds and HarfordUISounds.Play then
                HarfordUISounds.Play("craft_recipe_selected")
            end
            state.selected = self.recipeId
            RefreshUI()
        end
    end)
    return row
end

local function CreateFrameIfNeeded()
    if frame then return frame end
    -- El XML declara TradeSkillFrame como `inherits="PortraitFrameTemplate"`. Con
    -- ButtonFrameTemplate se añadia ademas la barra de botones inferior, que el nativo no tiene.
    frame = CreateFrame("Frame", "HarfordProfessionsCraftFrame", UIParent, "PortraitFrameTemplate")
        or CreateFrame("Frame", "HarfordProfessionsCraftFrame", UIParent, "ButtonFrameTemplate")
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
    -- El sonido de cierre va en OnHide y no en API.Close: la ventana esta en UISpecialFrames,
    -- asi que ESC la oculta sin pasar por Close. La bandera evita que suene con este Hide de
    -- construccion, que si dispara OnHide porque un frame recien creado nace visible.
    frame:HookScript("OnHide", function(self)
        if self._harfordSonidoListo and HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("craft_window_closed")
        end
    end)
    frame._harfordSonidoListo = true
    table.insert(UISpecialFrames, "HarfordProfessionsCraftFrame")

    -- ARMAZON GENERADO desde la captura del frame nativo.
    -- HarfordCraftSkin.lua lo escribe tools/codice/gen_frame_from_probe.py a partir de
    -- `nativeprobe prof`: insets con su nine-slice, barra de skill con su marco de tres
    -- piezas... con las medidas, texCoords y colores EXACTOS del nativo. No editarlo a mano:
    -- se regenera. Aqui solo se recogen las piezas por su uid para colgarles la logica.
    if frame.Inset then frame.Inset:Hide() end
    local skin = HarfordCraftSkin and HarfordCraftSkin.Build and HarfordCraftSkin.Build(frame)
    local byUid = skin and skin.byUid or {}
    local insetLeft, insetRight = byUid["root.f3"], byUid["root.f4"]
    local bar = byUid["root.f7"]
    if not (insetLeft and insetRight and bar) then
        HarfordChat.Print("|cffff5555No se pudo construir el armazon de la ventana de recetas|r")
        return frame
    end
    -- El XML declara InsetFrameTemplate con useParentLevel="true": el inset comparte nivel con
    -- su padre para no dibujarse por encima de los hermanos.
    for _, inset in ipairs({ insetLeft, insetRight }) do
        if inset.SetFrameLevel and frame.GetFrameLevel then
            inset:SetFrameLevel(frame:GetFrameLevel())
        end
    end
    frame.insetLeft, frame.insetRight = insetLeft, insetRight
    frame.skillBar = bar
    -- XML: RankText inherits="WhiteNormalNumberFont", justifyH="CENTER"
    frame.skillText = bar:CreateFontString(nil, "OVERLAY", "WhiteNormalNumberFont")
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

    -- SCROLL: el XML declara `Slider inherits="HybridScrollBarTemplate"` anclado
    -- TOPLEFT>lista.TOPRIGHT +1,-14 y BOTTOMLEFT>lista.BOTTOMRIGHT +1,+12. La plantilla trae
    -- riel, pomo y flechas; montarlo a mano con los fileID del nativo salia en verde.
    local slider = CreateFrame("Slider", nil, frame, "HybridScrollBarTemplate")
    if not slider then slider = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate") end
    slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 1, -14)
    slider:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 1, 12)
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider._updating = false
    slider:SetScript("OnValueChanged", function(self, value)
        UpdateScrollArrows(self)
        if self._updating then return end
        state.offset = math.floor(value + 0.5)
        RefreshUI()
    end)
    frame.scrollSlider = slider
    -- PESTAÑAS: el XML del cliente (Blizzard_TradeSkillRecipeList.xml, build 45745) las
    -- declara como `inherits="TabButtonTemplate"` ancladas BOTTOMLEFT>lista.TOPLEFT +10,+3 y
    -- la segunda LEFT>primera.RIGHT. Montarlas a mano con piezas de HelpFrameTab era el error:
    -- la plantilla ya trae el arte, el ancho segun el texto y los estados de seleccion.
    local function CreateListTab(label)
        local ok, tab = pcall(CreateFrame, "Button", nil, frame, "TabButtonTemplate")
        if not ok or not tab then
            ok, tab = pcall(CreateFrame, "Button", nil, frame, "UIPanelButtonTemplate")
        end
        if not ok or not tab then return nil end
        tab:SetText(label)
        if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
        function tab:SetActiveLook(active)
            if PanelTemplates_SelectTab and PanelTemplates_DeselectTab then
                if active then PanelTemplates_SelectTab(self) else PanelTemplates_DeselectTab(self) end
            end
        end
        return tab
    end
    frame.tabLearned = CreateListTab("Aprendidas")
    if frame.tabLearned then
        frame.tabLearned:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 10, 3)
        frame.tabLearned:SetScript("OnClick", function()
            state.tab = "learned"; state.offset = 0; state.selected = nil; RefreshUI()
        end)
    end
    frame.tabUnlearned = CreateListTab("No aprendidas")
    if frame.tabUnlearned and frame.tabLearned then
        frame.tabUnlearned:SetPoint("LEFT", frame.tabLearned, "RIGHT", 0, 0)
        frame.tabUnlearned:SetScript("OnClick", function()
            state.tab = "unlearned"; state.offset = 0; state.selected = nil; RefreshUI()
        end)
    end
    state.tab = "learned"

    -- Buscador: el XML lo declara `inherits="SearchBoxTemplate"` 112x20 en +220,-54.
    -- La plantilla ya trae borde, lupa, texto de sugerencia y boton de limpiar.
    local okS, search = pcall(CreateFrame, "EditBox", nil, frame, "SearchBoxTemplate")
    if not okS or not search then
        search = CreateFrame("EditBox", nil, frame)
        search:SetAutoFocus(false)
        search:SetFont("Fonts\\FRIZQT__.TTF", 10)
    end
    search:SetSize(112, 20)
    -- 230 y no los 220 del XML: con el ancho de nuestras pestanas el buscador quedaba pegado a
    -- "No aprendidas".
    search:SetPoint("TOPLEFT", frame, "TOPLEFT", 230, -54)
    -- La plantilla pone "Search" en ingles; el texto de sugerencia es suyo, no del EditBox.
    if search.Instructions then search.Instructions:SetText("Buscar") end
    search:SetScript("OnTextChanged", function(self)
        if SearchBoxTemplate_OnTextChanged then pcall(SearchBoxTemplate_OnTextChanged, self) end
        state.search = self:GetText() or ""
        state.offset = 0
        RefreshUI()
    end)
    search:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    search:SetScript("OnEnterPressed", search.ClearFocus)
    frame.searchBox = search


    -- Boton de filtro del nativo (70x22 en TOPRIGHT -12,-55). El nativo filtra por
    -- categorias de receta; aqui filtra por lo que tiene sentido en Harford.
    local filterBtn = CreateFrame("Button", nil, frame, "UIMenuButtonStretchTemplate")
    filterBtn:SetSize(70, 22)
    filterBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -55)
    filterBtn:SetText("Filtro")
    filterBtn:SetScript("OnClick", function(self)
        local menu = {
            { text = "Filtrar recetas", isTitle = true, notCheckable = true },
            { text = "Todas", checked = not state.onlyCraftable, notCheckable = false,
              func = function() state.onlyCraftable = nil; state.offset = 0; RefreshUI() end },
            { text = "Solo las que puedo fabricar", checked = state.onlyCraftable == true,
              notCheckable = false,
              func = function() state.onlyCraftable = true; state.offset = 0; RefreshUI() end },
        }
        if EasyMenu and CreateFrame then
            frame._filterMenu = frame._filterMenu or CreateFrame("Frame", "HarfordCraftFilterMenu", UIParent, "UIDropDownMenuTemplate")
            EasyMenu(menu, frame._filterMenu, self, 0, 0, "MENU")
        end
    end)
    frame.filterBtn = filterBtn

    -- Panel derecho: detalle de la receta, dentro del inset derecho nativo
    -- En el nativo el detalle NO es un panel fijo: es un ScrollFrame 300x385 en TOPRIGHT
    -- -32,-83 con su propio slider (20x351 a +6,-17 / +6,+17). Sin el, una receta con muchos
    -- materiales se desborda por abajo.
    local detailScroll = CreateFrame("ScrollFrame", nil, frame)
    detailScroll:SetSize(300, 385)
    detailScroll:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -32, -83)
    local detail = CreateFrame("Frame", nil, detailScroll)
    detail:SetSize(300, 385)
    detailScroll:SetScrollChild(detail)
    frame.detail, frame.detailScroll = detail, detailScroll

    -- El XML del detalle declara `Slider inherits="UIPanelStretchableArtScrollBarTemplate"`.
    local detailSlider = CreateFrame("Slider", nil, detailScroll, "UIPanelStretchableArtScrollBarTemplate")
        or CreateFrame("Slider", nil, detailScroll, "UIPanelScrollBarTemplate")
    detailSlider:SetPoint("TOPLEFT", detailScroll, "TOPRIGHT", 6, -17)
    detailSlider:SetPoint("BOTTOMLEFT", detailScroll, "BOTTOMRIGHT", 6, 17)
    detailSlider:SetMinMaxValues(0, 0)
    detailSlider:SetValueStep(10)
    detailSlider:SetScript("OnValueChanged", function(self, value)
        detailScroll:SetVerticalScroll(value)
        UpdateScrollArrows(self)
    end)
    detailScroll:EnableMouseWheel(true)
    detailScroll:SetScript("OnMouseWheel", function(_, delta)
        local mx = select(2, detailSlider:GetMinMaxValues())
        detailSlider:SetValue(math.max(0, math.min(mx, detailSlider:GetValue() - delta * 20)))
    end)
    detailSlider:Show()
    frame.detailSlider = detailSlider
    -- Fondo del detalle: en el XML pertenece al ScrollFrame, NO al contenido que scrollea
    -- (`Texture parentKey="Background" atlas="tradeskill-background-recipe"` 310x383 en
    -- TOPLEFT -5). Colgado del hijo se desplazaba con el scroll y se perdia al seleccionar.
    local detailBg = detailScroll:CreateTexture(nil, "BACKGROUND", nil, -1)
    if detailBg.SetAtlas and C_Texture and C_Texture.GetAtlasInfo
        and C_Texture.GetAtlasInfo("tradeskill-background-recipe") then
        detailBg:SetAtlas("tradeskill-background-recipe")
        detailBg:SetSize(310, 383)
        detailBg:SetPoint("TOPLEFT", detailScroll, "TOPLEFT", -5, 0)
    else
        detailBg:SetColorTexture(0.08, 0.07, 0.06, 0.92)
        detailBg:SetAllPoints(detailScroll)
    end
    frame.detailBg = detailBg
    -- El nativo usa DOS fondos distintos para el panel de detalle: el normal y uno propio para
    -- recetas NO aprendidas (`tradeskill-background-recipe-unlearned`). Salio del diff entre la
    -- sonda del frame nativo (capturada en la pestana "No aprendidas") y la nuestra: alli
    -- aparece el atlas `-unlearned` y no el normal.
    detailBg.atlasNormal = "tradeskill-background-recipe"
    detailBg.atlasUnlearned = "tradeskill-background-recipe-unlearned"
    frame.SetDetailBackground = function(_, aprendida)
        if not (detailBg.SetAtlas and C_Texture and C_Texture.GetAtlasInfo) then return end
        local nombre = aprendida and detailBg.atlasNormal or detailBg.atlasUnlearned
        -- Si el cliente no conoce el atlas de no aprendidas, se queda con el normal antes que
        -- dejar el panel sin fondo.
        if not C_Texture.GetAtlasInfo(nombre) then nombre = detailBg.atlasNormal end
        if not C_Texture.GetAtlasInfo(nombre) then return end
        detailBg:SetAtlas(nombre)
        detailBg:SetSize(310, 383)
        detailBg:SetPoint("TOPLEFT", detailScroll, "TOPLEFT", -5, 0)
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
    -- Contador del resultado sobre el icono (XML: Count inherits="NumberFontNormal" en
    -- BOTTOMRIGHT -2,+3). Sin el no se ve que una receta produce mas de una unidad.
    detail.resultCount = detail:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
    detail.resultCount:SetPoint("BOTTOMRIGHT", detail.icon, "BOTTOMRIGHT", -2, 3)
    detail.resultCount:SetJustifyH("RIGHT")

    -- XML: RecipeName GameFontNormalMed2, 230 de ancho, en TOPLEFT +65,-20
    detail.name = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    detail.name:SetPoint("TOPLEFT", detail, "TOPLEFT", 65, -20)
    detail.name:SetWidth(230)
    detail.name:SetJustifyH("LEFT")

    -- XML: Description GameFontHighlightSmall2, 290 de ancho, en TOPLEFT +8,-85. Es lo que
    -- llena la mitad del panel en el nativo; sin ella el detalle se ve medio vacio.
    detail.desc = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall2")
    detail.desc:SetPoint("TOPLEFT", detail, "TOPLEFT", 8, -85)
    detail.desc:SetWidth(290)
    detail.desc:SetJustifyH("LEFT")
    detail.desc:SetJustifyV("TOP")

    -- XML: RequirementLabel/RequirementText debajo de la descripcion
    detail.reqLabel = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detail.reqLabel:SetPoint("TOPLEFT", detail.desc, "BOTTOMLEFT", 0, -6)
    detail.reqLabel:SetText("Requiere:")
    detail.req = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detail.req:SetPoint("TOPLEFT", detail.reqLabel, "BOTTOMLEFT", 0, -2)
    detail.req:SetWidth(290)
    detail.req:SetJustifyH("LEFT")
    detail.req:SetJustifyV("TOP")

    -- XML: ReagentLabel GameFontNormalSmall, encadenado bajo lo anterior
    detail.reagentsTitle = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detail.reagentsTitle:SetPoint("TOPLEFT", detail.req, "BOTTOMLEFT", 0, -8)
    detail.reagentsTitle:SetText("Materiales")

    -- Botonera nativa: [Crear todo] ... [cantidad] [Crear] [Salir], todos 80x22
    --
    -- EL CRAFTEO ES UNO POR UNO: nunca hay dos en vuelo. Pedir varias unidades encola, no dispara
    -- una rafaga. Cada pieza espera a que las bolsas CONFIRMEN el gasto de la anterior antes de
    -- empezar la siguiente, porque `RemoveItem` es un comando de servidor asincrono y encadenar a
    -- ciegas dejaria craftear con material ya gastado (ademas de reventar el servidor a comandos).
    local MAX_QUEUE = 20
    local CRAFT_TIME = 3.0   -- fundicion visible, al estilo del lanzamiento nativo
    -- `recipeId` se fija al arrancar la cola: si se leyera `state.selected` en cada pieza,
    -- cambiar de receta a mitad haria que se fabricase otra cosa distinta.
    local queue = { left = 0, timeout = nil, recipeId = nil }
    local bagWatcher = CreateFrame("Frame")

    -- Barra de fundicion con el arte de la barra de lanzamiento nativa. El OnUpdate solo vive
    -- mientras dura la fundicion y se retira al terminar (no hay ticks permanentes).
    local castBar = CreateFrame("StatusBar", nil, frame)
    castBar:SetSize(220, 18)
    castBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 10)
    castBar:SetStatusBarTexture(TEX.barFill)
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
        queue.recipeId = nil
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
        if not (queue.recipeId and HarfordProfessions and HarfordProfessions.Craft) then
            return StopQueue()
        end
        -- Craft revalida CanCraft por su cuenta y descuenta el material reservado, asi que una
        -- pieza que ya no se puede hacer corta la cola en vez de seguir intentandolo.
        local ok = HarfordProfessions.Craft(queue.recipeId)
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
        if not queue.recipeId then return StopQueue() end
        queue.left = queue.left - 1
        local rec = HarfordProfessions and HarfordProfessions.GetRecipe
            and HarfordProfessions.GetRecipe(queue.recipeId)
        BeginCast(rec and (rec.name or rec.id) or "")
    end

    bagWatcher:SetScript("OnEvent", function()
        bagWatcher:UnregisterAllEvents()
        queue.timeout = nil
        if queue.left > 0 then CraftNext() end
    end)

    local function CraftTimes(n)
        if queue.left > 0 then return end  -- ya hay una cola en marcha: no solapar
        if not state.selected then return end
        n = math.max(1, math.min(math.floor(tonumber(n) or 1), MAX_QUEUE))
        queue.recipeId = state.selected
        queue.left = n
        CraftNext()
    end
    state.IsCrafting = function() return queue.left > 0 end
    local exitBtn = CreateFrame("Button", nil, frame, "MagicButtonTemplate")
    exitBtn:SetSize(80, 22)
    exitBtn:SetPoint("TOPRIGHT", detailScroll, "BOTTOMRIGHT", 22, -3)
    exitBtn:SetText("Salir")
    -- Por API.Close y no `frame:Hide()`: si no, Salir se saltaria el sonido de cierre.
    exitBtn:SetScript("OnClick", function() API.Close() end)
    frame.craftBtn = CreateFrame("Button", nil, frame, "MagicButtonTemplate")
    frame.craftBtn:SetSize(80, 22)
    -- XML: CreateButton se ancla TOPRIGHT>ExitButton.TOPLEFT SIN desplazamiento.
    frame.craftBtn:SetPoint("TOPRIGHT", exitBtn, "TOPLEFT", 0, 0)
    frame.craftBtn:SetText("Crear")
    frame.craftBtn:SetScript("OnClick", function()
        local box = frame.qtyBox
        local n = box and tonumber(box.GetNumber and box:GetNumber() or box:GetText()) or 1
        CraftTimes(n)
    end)
    -- El XML declara CreateMultipleInputBox como `inherits="NumericInputSpinnerTemplate"`
    -- anclado LEFT>CrearTodo.RIGHT +31: es el que trae las flechas del nativo.
    local okQ, qty = pcall(CreateFrame, "EditBox", nil, frame, "NumericInputSpinnerTemplate")
    if not okQ or not qty then
        qty = CreateFrame("EditBox", nil, frame)
        qty:SetAutoFocus(false); qty:SetNumeric(true); qty:SetMaxLetters(3)
        qty:SetFont("Fonts\\ARIALN.TTF", 14); qty:SetJustifyH("CENTER")
        local qBg = qty:CreateTexture(nil, "BACKGROUND")
        qBg:SetColorTexture(0, 0, 0, 0.5); qBg:SetAllPoints(qty)
    end
    qty:SetSize(31, 20)
    qty:SetText("1")
    if qty.SetMinMaxValues then qty:SetMinMaxValues(1, 20) end   -- tope de la cola
    frame.qtyBox = qty
    frame.craftAllBtn = CreateFrame("Button", nil, frame, "MagicButtonTemplate")
    frame.craftAllBtn:SetSize(80, 22)
    frame.craftAllBtn:SetPoint("TOPLEFT", detailScroll, "BOTTOMLEFT", -5, -3)
    frame.craftAllBtn:SetText("Crear todo")
    -- XML: CreateMultipleInputBox se ancla LEFT>CreateAllButton.RIGHT +31,0. Se hace aqui
    -- porque el boton se crea despues que la caja.
    qty:SetPoint("LEFT", frame.craftAllBtn, "RIGHT", 31, 0)

    -- Flechas -1 / +1 tal como las declara NumericInputSpinnerTemplate en el XML del cliente:
    -- botones 23x22, Increment a LEFT>caja.RIGHT +0,0 y Decrement a RIGHT>caja.LEFT -6,0, con
    -- el arte de paso de pagina del libro de hechizos y el resaltado comun. Solo se crean si
    -- la plantilla no las trajo ya.
    if not (qty.DecrementButton and qty.IncrementButton) then
        local function SpinnerButton(page, point, relPoint, dx, delta)
            local b = CreateFrame("Button", nil, frame)
            b:SetSize(23, 22)
            b:SetPoint(point, qty, relPoint, dx, 0)
            local base = "Interface\\Buttons\\UI-SpellbookIcon-" .. page .. "Page-"
            b:SetNormalTexture(base .. "Up")
            b:SetPushedTexture(base .. "Down")
            b:SetDisabledTexture(base .. "Disabled")
            b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
            b:SetScript("OnClick", function()
                local current = tonumber(qty.GetNumber and qty:GetNumber() or qty:GetText()) or 1
                local maximo = frame.craftAllBtn and frame.craftAllBtn.craftableCount or MAX_QUEUE
                maximo = math.max(1, math.min(MAX_QUEUE, maximo))
                qty:SetText(tostring(math.max(1, math.min(maximo, current + delta))))
            end)
            return b
        end
        frame.qtyPlus  = SpinnerButton("Next", "LEFT", "RIGHT", 0, 1)
        frame.qtyMinus = SpinnerButton("Prev", "RIGHT", "LEFT", -6, -1)
    end

    frame.craftAllBtn:SetScript("OnClick", function()
        CraftTimes(frame.craftAllBtn.craftableCount or 1)
    end)
    frame._buildComplete = true
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
            local passSearch = not needle or Strip(tostring(r.name or r.id)):lower():find(needle, 1, true)
            local passFilter = true
            if state.onlyCraftable then passFilter = HarfordProfessions.CanCraft(r.id) == true end
            if passSearch and passFilter then
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
    local display, lastTier = {}, nil
    for _, r in ipairs(recipes) do
        local tier = HarfordProfessions.GetTierName(tonumber(r.skillReq) or 1)
        if tier ~= lastTier then
            -- Sin contador de recetas por rango: la cabecera solo nombra el rango.
            display[#display + 1] = { header = tier }
            lastTier = tier
        end
        if not state.collapsed[tier] then display[#display + 1] = r end
    end

    local maxOffset = math.max(0, #display - ROWS_VISIBLE)
    state.offset = math.max(0, math.min(state.offset, maxOffset))
    if frame.scrollSlider then
        local s = frame.scrollSlider
        s._updating = true
        s:SetMinMaxValues(0, maxOffset)
        s:SetValue(state.offset)
        s._updating = false
        UpdateScrollArrows(s)
    end
    for i = 1, ROWS_VISIBLE do
        local row = state.rows[i]
        local entry = display[state.offset + i]
        if entry and entry.header then
            -- Cabecera de grupo: rango en ORO con el contador de recetas a la derecha
            row.recipeId = nil
            local tier = entry.header
            row.expander:SetNormalTexture(state.collapsed[tier]
                and "Interface\\Buttons\\UI-PlusButton-Up"
                or "Interface\\Buttons\\UI-MinusButton-Up")
            row.expander:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
            row.expander:SetScript("OnClick", function()
                state.collapsed[tier] = not state.collapsed[tier] or nil
                state.offset = 0
                RefreshUI()
            end)
            row.expander:Show()
            -- El resaltado es el del icono de plegar: solo tiene sentido donde hay icono.
            if row.hi then row.hi:SetAlpha(1) end
            row.text:SetText(entry.header)
            row.text:SetTextColor(1, 0.82, 0)
            row.baseColor = { 1, 0.82, 0 }
            row.count:SetText("")
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
            -- Como el nativo: el nombre va limpio y la CANTIDAD FABRICABLE va suelta a la
            -- derecha, con el mismo color de dificultad de la fila.
            row.expander:Hide()
            -- Sin icono de plegar no hay nada que iluminar: dejarlo encendido pintaba un brillo
            -- suelto en el margen izquierdo que el nativo no tiene.
            if row.hi then row.hi:SetAlpha(0) end
            row.text:SetText(rec.name or rec.id)
            row.text:SetTextColor(r, g, b)
            row.baseColor = { r, g, b }
            row.count:SetText((craftable and craftable > 0) and tostring(craftable) or "")
            row.count:SetTextColor(r, g, b)
            row.sel:SetVertexColor(r, g, b)   -- nativo: la seleccion toma el color de la fila
            local seleccionada = rec.id == state.selected
            row.sel:SetShown(seleccionada)
            -- Seleccionada: texto en blanco y ahi se queda (el nativo hace lo mismo).
            if seleccionada then row.text:SetTextColor(1, 1, 1) end
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
        d.desc:SetText("")
        d.reqLabel:Hide()
        d.resultCount:SetText("")
        for _, slot in ipairs(state.reagents) do slot:Hide() end
        frame.craftBtn:SetEnabled(false)
        if frame.craftAllBtn then
            frame.craftAllBtn.craftableCount = 0
            frame.craftAllBtn:SetEnabled(false)
        end
        SetQuantityEnabled(false)
        return
    end
    d.icon:SetTexture(RecipeIconTexture(sel))
    if d.iconHit then
        d.iconHit.itemId = HarfordProfessions.GetOutputItemId
            and HarfordProfessions.GetOutputItemId(sel.id) or nil
    end
    d.name:SetText(sel.name or sel.id)
    local ok, reason, detailMats = HarfordProfessions.CanCraft(sel.id)
    -- Cantidad producida sobre el icono (solo si es mas de una, como el nativo)
    local outQty = (sel.output and tonumber(sel.output.qty)) or 1
    d.resultCount:SetText(outQty > 1 and tostring(outQty) or "")

    -- Descripcion: la de la receta si la declara; si no, de que profesion y rango es. Antes
    -- este medio panel quedaba vacio porque no pintabamos nada de esto.
    local tierName = HarfordProfessions.GetTierName(tonumber(sel.skillReq) or 1)
    d.desc:SetText(sel.description or string.format("Receta de %s del rango %s.",
        (def.name or ""):lower(), tierName))

    d.reqLabel:Show()
    local reqLines = { string.format("Nivel de %s: %d", (def.name or ""):lower(),
        tonumber(sel.skillReq) or 1) }
    if def.tool then reqLines[#reqLines + 1] = def.tool end
    if not ok and reason then reqLines[#reqLines + 1] = "|cffff5555" .. tostring(reason) .. "|r" end
    d.req:SetText(table.concat(reqLines, "\n"))
    local mats = detailMats or {}
    for i, m in ipairs(mats) do
        local slot = state.reagents[i]
        if not slot then
            slot = CreateReagentSlot(d, i)
            state.reagents[i] = slot
        end
        if not slot then break end
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
    if frame.SetDetailBackground then
        frame:SetDetailBackground(state.tab ~= "unlearned")
    end
    if frame.detailSlider then
        -- Alto real del contenido: cabecera (120) + filas de materiales de 43.
        local needed = 120 + math.ceil(#mats / 2) * 43
        local over = math.max(0, needed - 385)
        frame.detailSlider:SetMinMaxValues(0, over)
        if frame.detailSlider:GetValue() > over then frame.detailSlider:SetValue(over) end
        -- SIEMPRE visible, como el nativo: el rail esta ahi aunque la receta quepa entera.
        -- Ocultarlo dejaba un hueco vacio a la derecha del detalle.
        UpdateScrollArrows(frame.detailSlider)
    end
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
    -- El nativo apaga los TRES a la vez (TradeSkillDetailsMixin: CreateButton, CreateAllButton y
    -- CreateMultipleInputBox comparten `effectivelyCraftable`). Sin esto las flechas de cantidad
    -- se quedaban doradas —habilitadas— sobre una receta que no se puede fabricar.
    SetQuantityEnabled(ok and true or false)
end

-- ── API publica ──────────────────────────────────────────────────────────────
function API.Open(profId)
    profId = tostring(profId or ""):lower()
    if not (HarfordProfessions and HarfordProfessions.GetDefinition and HarfordProfessions.GetDefinition(profId)) then
        return false, "Profesion desconocida: " .. profId
    end
    -- Si la construccion o el refresco fallan a media, la ventana se queda a medias y desde
    -- fuera parece "igual que antes". Se reporta el error en vez de morir en silencio.
    local built, buildErr = pcall(CreateFrameIfNeeded)
    if not built then
        HarfordChat.Print("|cffff5555Error construyendo la ventana:|r " .. tostring(buildErr))
        return false, buildErr
    end
    if state.profId ~= profId then
        state.selected, state.offset = nil, 0
    end
    state.profId = profId
    -- Suena tambien al cambiar de profesion con la ventana ya abierta: para el jugador es la
    -- ventana de esa profesion la que se abre, aunque el frame ya estuviera visible.
    if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("craft_window_opened") end
    frame:Show()
    local okRefresh, refreshErr = pcall(RefreshUI)
    if not okRefresh then
        HarfordChat.Print("|cffff5555Error refrescando la ventana:|r " .. tostring(refreshErr))
    end
    return true
end

function API.Close()
    -- El sonido lo pone el OnHide del frame, para que suene igual cerrando con ESC.
    if frame then frame:Hide() end
end

-- Alternar desde el sello de una profesion:
--   ventana abierta con ESA profesion  -> se cierra
--   ventana abierta con OTRA           -> cambia a esta, sin cerrarse
--   ventana cerrada                    -> se abre con esta
function API.Toggle(profId)
    profId = tostring(profId or ""):lower()
    if frame and frame:IsShown() and state.profId == profId then
        API.Close()
        return false
    end
    local ok, err = API.Open(profId)
    return ok and true or false, err
end

-- ¿Que profesion se esta mostrando? nil si la ventana esta cerrada.
function API.GetOpenProfession()
    if not (frame and frame:IsShown()) then return nil end
    return state.profId
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
