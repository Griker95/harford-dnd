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
-- El degradado vive en HarfordProfessions: es la misma regla que usa la ventana de entrenador y
-- tenerla dos veces es como divergen. Aqui se conserva el escalon trivial en gris, porque en
-- esta ventana significa algo real: fabricarla ya no sube habilidad.
local function DifficultyColor(skill, req)
    if not (HarfordProfessions and HarfordProfessions.DifficultyColor) then
        return 0.8, 0.8, 0.8
    end
    local r, g, b = HarfordProfessions.DifficultyColor(skill, req)
    return r, g, b
end

local function Prof()
    return state.profId and HarfordProfessions and HarfordProfessions.GetDefinition
        and HarfordProfessions.GetDefinition(state.profId) or nil
end

local RefreshUI, RefreshList, RefreshDetail  -- forward

-- La lista construida (`state.model`) y las cantidades fabricables ya calculadas
-- (`state.craftableCache`) se reutilizan mientras nada cambie. Al hacer scroll NO se recalcula
-- nada: solo se repintan las 20 filas visibles con datos que ya estan.
local function InvalidarLista()
    state.model = nil
    state.craftableCache = nil
end

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
        -- Arial Narrow 14 con contorno (NumberFontNormal), alineado a la derecha y anclado por
        -- BOTTOMRIGHT. SIN ancho fijo: el XML nativo lo declara sin \`Size\`, asi que la cadena
        -- crece hacia la izquierda sola. Ponerle los 26 que MEDIA la sonda fue el error -eso era
        -- el ancho del texto "0 /5" ya pintado, no una anchura declarada- y con dos cifras
        -- ("12 /1") el texto no cabia y se partia en dos lineas desbordando el icono.
        slot.count:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
        slot.count:SetJustifyH("RIGHT")
        slot.count:SetWordWrap(false)
        slot.count:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", -1, 1)
    end
    slot:SetScript("OnEnter", function(self)
        if self.itemKey and HarfordProfessionsItems and HarfordProfessionsItems.ShowTooltip then
            HarfordProfessionsItems.ShowTooltip(self, self.itemKey)
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.itemId then
            GameTooltip:SetHyperlink("item:" .. self.itemId)
        else
            GameTooltip:SetText(self.itemName or "?", 1, 1, 1)
            GameTooltip:AddLine("Pendiente de crear en el vault", 1, 0.35, 0.35)
        end
        GameTooltip:Show()
    end)
    -- Shift+click sobre un material: su enlace al chat, igual que el del resultado.
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot:SetScript("OnClick", function(self)
        if not (IsShiftKeyDown and IsShiftKeyDown() and self.itemKey) then return end
        if HarfordProfessionsItems and HarfordProfessionsItems.InsertLinkInChat then
            HarfordProfessionsItems.InsertLinkInChat(self.itemKey)
        end
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
-- Las plantillas de barra (HybridScrollBarTemplate y compania) traen sus flechas con un OnClick
-- propio que sube dos padres esperando encontrar un HybridScrollFrame de verdad, con su
-- `stepSize`, `buttonHeight` y `range`. Nuestras listas NO lo son: el desplazamiento lo llevamos
-- nosotros por indice de fila. Ese manejador reventaba al pulsar la flecha:
--   HybridScrollFrame.lua:67: attempt to perform arithmetic on local 'stepSize' (a nil value)
-- Se sustituye por uno propio que solo mueve el valor del slider; el clamp lo hace el Slider y el
-- refresco lo dispara su OnValueChanged.
local function WireScrollArrows(slider, paso)
    if not slider then return end
    paso = paso or 1
    local arriba = slider.ScrollUpButton or slider.ScrollUp
    local abajo = slider.ScrollDownButton or slider.ScrollDown
    if arriba then
        arriba:SetScript("OnClick", function()
            slider:SetValue((slider:GetValue() or 0) - paso)
        end)
    end
    if abajo then
        abajo:SetScript("OnClick", function()
            slider:SetValue((slider:GetValue() or 0) + paso)
        end)
    end
end

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
    -- Resaltado y manejador se montan AQUI, no en cada refresco: cargar una textura por ruta
    -- y crear un cierre nuevo veinte veces por muesca de rueda costaba fps. El rango al que
    -- corresponde la fila viaja en `row.tier`, que si cambia en cada refresco.
    row.expander:SetHighlightTexture(TEX.expanderHi, "ADD")
    row.expander:SetScript("OnClick", function(self)
        local fila = self:GetParent()
        local tier = fila and fila.tier
        if not tier then return end
        state.collapsed[tier] = not state.collapsed[tier] or nil
        state.offset = 0
        InvalidarLista()   -- plegar/desplegar cambia que filas hay
        RefreshList()
    end)
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
    -- HarfordProfessionsCraftSkin.lua lo escribe tools/codice/gen_frame_from_probe.py a partir de
    -- `nativeprobe prof`: insets con su nine-slice, barra de skill con su marco de tres
    -- piezas... con las medidas, texCoords y colores EXACTOS del nativo. No editarlo a mano:
    -- se regenera. Aqui solo se recogen las piezas por su uid para colgarles la logica.
    if frame.Inset then frame.Inset:Hide() end
    local skin = HarfordProfessionsCraftSkin and HarfordProfessionsCraftSkin.Build and HarfordProfessionsCraftSkin.Build(frame)
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
    -- FONDO TRANSLUCIDO de la barra. El XML lo declara dentro del StatusBar como una Texture SIN
    -- anclajes ni tamano y con \`<Color r="0" g="0" b="0.75" a="0.1"/>\`; el cliente la estira a la
    -- barra entera -la sonda del nativo la mide a 447x14 en capa BACKGROUND-. Sin el, la barra se
    -- ve vacia a la derecha del relleno en vez de tener carril.
    if not bar._harfordFondo then
        bar._harfordFondo = bar:CreateTexture(nil, "BACKGROUND")
        bar._harfordFondo:SetAllPoints(bar)
        bar._harfordFondo:SetColorTexture(0, 0, 0.75, 0.1)
    end
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
        -- Solo la lista: mover la rueda no cambia la receta seleccionada, asi que rehacer el
        -- panel de detalle en cada muesca era trabajo tirado (y lo que bajaba los fps).
        RefreshList()
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
        RefreshList()
    end)
    WireScrollArrows(slider, 1)
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
        if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("filter_menu_opened") end
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

    -- BOTON DE TIRADA. Ocupa el sitio y el tamano del `LinkToButton` nativo -30x30 en
    -- BOTTOMRIGHT del boton de filtro (+3,+1)- con su mismo resaltado, pero con un dado en
    -- vez del icono de enlazar profesion: aqui no se enlaza la profesion al chat, se tira.
    --
    -- La REGLA no vive aqui: la ventana solo llama a HarfordProfessions.RollTool, que es la
    -- prueba de profesion (d20 + competencia + modificador de caracteristica).
    local rollBtn = CreateFrame("Button", nil, frame)
    rollBtn:SetSize(30, 30)
    rollBtn:SetPoint("BOTTOMRIGHT", filterBtn, "TOPRIGHT", 3, 1)
    local dado = rollBtn:CreateTexture(nil, "ARTWORK")
    dado:SetPoint("CENTER", rollBtn, "CENTER", 0, 0)
    dado:SetSize(22, 22)
    -- SafeTexture es el validador que ya usa esta ventana: si la ruta no existe en el cliente
    -- oculta la textura y lo anota, en vez de pintar el cuadrado verde.
    SafeTexture(dado, "Interface\\Icons\\INV_Misc_Dice_01", "dado de tirada")
    rollBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    -- Pulsado: el nativo cambia de textura; aqui basta con hundir el icono un pixel.
    rollBtn:SetScript("OnMouseDown", function() dado:SetPoint("CENTER", rollBtn, "CENTER", 1, -1) end)
    rollBtn:SetScript("OnMouseUp", function() dado:SetPoint("CENTER", rollBtn, "CENTER", 0, 0) end)
    rollBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        local def = Prof()
        GameTooltip:SetText("Tirada de " .. ((def and def.name) or "profesion"), 1, 1, 1)
        -- La caracteristica de cada profesion esta en el catalogo (`def.ability`), asi que se
        -- nombra en vez de decir "modificador de caracteristica" a secas.
        GameTooltip:AddLine("d20 + Bonus Competencia + Mod. "
            .. ((def and def.ability) or "Caracteristica"), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    rollBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rollBtn:SetScript("OnClick", function()
        if state.profId and HarfordProfessions and HarfordProfessions.RollTool then
            HarfordProfessions.RollTool(state.profId)
        end
    end)
    frame.rollBtn = rollBtn

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
    -- El detalle se desplaza en pixeles, no en filas: el paso del nativo para una flecha.
    WireScrollArrows(detailSlider, 20)
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
        if self.itemKey and HarfordProfessionsItems and HarfordProfessionsItems.ShowTooltip then
            HarfordProfessionsItems.ShowTooltip(self, self.itemKey)
            return
        end
        if not self.itemId then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.itemId)
        GameTooltip:Show()
    end)
    detail.iconHit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- Shift+click mete el enlace en el chat, como en la bolsa. `OnMouseDown` y no `OnClick`
    -- porque iconHit es un Frame, no un Button.
    detail.iconHit:SetScript("OnMouseDown", function(self)
        if not (IsShiftKeyDown and IsShiftKeyDown() and self.itemKey) then return end
        if HarfordProfessionsItems and HarfordProfessionsItems.InsertLinkInChat then
            HarfordProfessionsItems.InsertLinkInChat(self.itemKey)
        end
    end)
    -- Contador del resultado sobre el icono (XML: Count inherits="NumberFontNormal" en
    -- BOTTOMRIGHT -2,+3). Sin el no se ve que una receta produce mas de una unidad.
    detail.resultCount = detail:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
    detail.resultCount:SetPoint("BOTTOMRIGHT", detail.icon, "BOTTOMRIGHT", -2, 3)
    detail.resultCount:SetJustifyH("RIGHT")

    -- Medidas tomadas de la sonda del TradeSkillFrame nativo (captura "nativo",
    -- panel root.f6.f9, 300x232). Se fija fuente, tamano, ancho, alineacion y color a mano
    -- porque los FontObject con nombre no coinciden: el nativo usa Friz Quadrata a 14/11/10/12
    -- segun la fila, no la escala de un unico objeto.
    local FRIZ = "Fonts\\FRIZQT__.TTF"
    local ORO_R, ORO_G, ORO_B = 1, 0.82, 0

    -- r1: 230x14, LEFT/MIDDLE, blanco, TOPLEFT del panel +65,-20
    detail.name = detail:CreateFontString(nil, "OVERLAY")
    detail.name:SetFont(FRIZ, 14, "")
    detail.name:SetPoint("TOPLEFT", detail, "TOPLEFT", 65, -20)
    detail.name:SetWidth(230)
    detail.name:SetJustifyH("LEFT")
    detail.name:SetJustifyV("MIDDLE")
    detail.name:SetTextColor(1, 1, 1)

    -- r2: 290 de ancho, LEFT/MIDDLE, blanco, TOPLEFT del panel +8,-85. La posicion es FIJA
    -- en el nativo aunque la receta no tenga descripcion: con el texto vacio la cadena mide 0
    -- de alto y la fila de "Requiere" sube sola. Por eso no se oculta ni se re-ancla.
    detail.desc = detail:CreateFontString(nil, "OVERLAY")
    detail.desc:SetFont(FRIZ, 11, "")
    detail.desc:SetPoint("TOPLEFT", detail, "TOPLEFT", 8, -85)
    detail.desc:SetWidth(290)
    detail.desc:SetJustifyH("LEFT")
    detail.desc:SetJustifyV("MIDDLE")
    detail.desc:SetTextColor(1, 1, 1)

    -- r3: 48x10, CENTER/MIDDLE, dorado. r4: 188x10, LEFT/TOP, blanco (el rojo del requisito
    -- no cumplido viaja en linea dentro del propio texto, igual que en el nativo).
    -- SIN ancho fijo. El XML declara \`RequirementLabel\` sin \`Size\`, asi que mide lo que mida su
    -- texto; los 48 que veia la sonda eran el ancho del ingles "Requires:", no una anchura
    -- declarada, y en castellano no tiene por que coincidir.
    detail.reqLabel = detail:CreateFontString(nil, "OVERLAY")
    detail.reqLabel:SetFont(FRIZ, 10, "")
    detail.reqLabel:SetJustifyV("MIDDLE")
    detail.reqLabel:SetTextColor(ORO_R, ORO_G, ORO_B)
    detail.reqLabel:SetText("Requiere:")
    -- El anclaje vertical es CONDICIONAL y se decide en el refresco (ver abajo).
    detail.reqLabel:SetPoint("TOPLEFT", detail.desc, "BOTTOMLEFT", 0, 0)

    detail.req = detail:CreateFontString(nil, "OVERLAY")
    detail.req:SetFont(FRIZ, 10, "")
    detail.req:SetPoint("TOPLEFT", detail.reqLabel, "TOPRIGHT", 4, 0)
    -- Su ancho lo calcula el nativo en el OnLoad: \`SetWidth(236 - RequirementLabel:GetWidth())\`.
    -- Se aplica en el refresco, cuando la etiqueta ya tiene metricas de fuente.
    detail.req:SetJustifyH("LEFT")
    detail.req:SetJustifyV("TOP")
    detail.req:SetTextColor(1, 1, 1)

    -- r8: 54x10, CENTER/MIDDLE, dorado. DOS anclajes, como el nativo: la Y cuelga de los
    -- valores del requisito (si ocupan dos lineas, los materiales bajan con ellos) y la X
    -- vuelve al margen izquierdo por su cuenta.
    detail.reagentsTitle = detail:CreateFontString(nil, "OVERLAY")
    detail.reagentsTitle:SetFont(FRIZ, 10, "")
    -- El nativo le pone 54 de ancho, que es lo que mide "Reagents:". En castellano
    -- "Materiales:" no cabe y salia cortado, asi que aqui se deja que la cadena mida lo suyo:
    -- solo se ancla por la izquierda, nadie cuelga de su borde derecho.
    detail.reagentsTitle:SetWidth(0)
    detail.reagentsTitle:SetJustifyH("CENTER")
    detail.reagentsTitle:SetJustifyV("MIDDLE")
    detail.reagentsTitle:SetTextColor(ORO_R, ORO_G, ORO_B)
    detail.reagentsTitle:SetText("Materiales:")
    -- -12 y no 0: el nativo mete entre medias una cadena vacia para la experiencia ganada
    -- (r7, anclada a -11 del valor y con 1 de alto) que no muestra nada pero si separa. Aqui
    -- no existe esa fila, asi que su hueco se aplica como desplazamiento.
    detail.reagentsTitle:SetPoint("TOP", detail.req, "BOTTOM", 0, -12)
    detail.reagentsTitle:SetPoint("LEFT", detail.reqLabel, "LEFT", 0, 0)

    -- r11: instructor Y coste son UNA SOLA cadena de 290 de ancho separada por |n, en Friz 12
    -- blanco. Tambien lleva dos anclajes: la Y del ultimo hueco de material y la X del margen.
    -- Ese segundo punto es justo lo que evitaba que la linea se fuera a la derecha cuando la
    -- ultima fila de materiales tenia una sola columna.
    detail.trainerLine = detail:CreateFontString(nil, "OVERLAY")
    detail.trainerLine:SetFont(FRIZ, 12, "")
    detail.trainerLine:SetWidth(290)
    detail.trainerLine:SetJustifyH("LEFT")
    detail.trainerLine:SetJustifyV("MIDDLE")
    detail.trainerLine:SetTextColor(1, 1, 1)

    -- Botonera nativa: [Crear todo] ... [cantidad] [Crear] [Salir], todos 80x22
    --
    -- EL CRAFTEO ES UNO POR UNO: nunca hay dos en vuelo. Pedir varias unidades encola, no dispara
    -- una rafaga. Cada pieza espera a que las bolsas CONFIRMEN el gasto de la anterior antes de
    -- empezar la siguiente, porque `RemoveItem` es un comando de servidor asincrono y encadenar a
    -- ciegas dejaria craftear con material ya gastado (ademas de reventar el servidor a comandos).
    local MAX_QUEUE = 20
    local CRAFT_TIME = 5.0   -- fundicion visible, al estilo del lanzamiento nativo
    -- `recipeId` se fija al arrancar la cola: si se leyera `state.selected` en cada pieza,
    -- cambiar de receta a mitad haria que se fabricase otra cosa distinta.
    local queue = { left = 0, timeout = nil, recipeId = nil }
    local bagWatcher = CreateFrame("Frame")

    -- Barra de fundicion con el arte de la barra de lanzamiento nativa. El OnUpdate solo vive
    -- mientras dura la fundicion y se retira al terminar (no hay ticks permanentes).
    -- BARRA DE FUNDICION, montada A MANO con las texturas nativas de la barra de lanzamiento.
    --
    -- Se descarto `CastingBarFrameTemplate`: la plantilla trae borde, destello, chispa, escudo y
    -- marco de texto que solo quedan colocados si corre `CastingBarFrame_OnLoad`, y esa funcion
    -- NO existe en este cliente -no la referencia ningun addon instalado-. Sin ella las piezas
    -- se quedan todas superpuestas, que era el amasijo que se veia.
    --
    -- Aqui son tres piezas y se sabe donde esta cada una. La geometria es la del nativo: barra
    -- de 195x13 y borde de 256x64 desbordandola 23 a los lados y 20 arriba y abajo.
    local castBar = CreateFrame("StatusBar", "HarfordCraftCastBar", UIParent)
    -- TAMANO Y SITIO: se copian de la barra de lanzamiento NATIVA de este cliente en vez de
    -- hardcodear medidas. `CastingBarFrame` ya existe con el tamano bueno para esta build;
    -- los 195x13 que habia eran una estimacion y la barra se salia del marco.
    -- 195x13, medido en la CastingBarFrame de este cliente con la sonda.
    castBar:SetSize(195, 13)
    -- HIGH, la misma strata que la CastingBarFrame nativa segun la sonda.
    castBar:SetFrameStrata("HIGH")
    -- Encima de la barra de lanzamiento del jugador, como hace SpellCreator. Cuelga de UIParent
    -- para seguir viendose aunque la ventana quede detras.
    -- SITIO: el de la nativa, medido en BOTTOM -> UIParent.BOTTOM (0, +160). Si el jugador la
    -- ha movido, se copia su punto para que la de fabricar salga donde espera ver una barra.
    local nativa = _G.CastingBarFrame
    local punto, rel, puntoRel, dx, dy
    if nativa and nativa.GetPoint and nativa:GetNumPoints() > 0 then
        punto, rel, puntoRel, dx, dy = nativa:GetPoint(1)
    end
    if punto and rel then
        castBar:SetPoint(punto, rel, puntoRel, dx or 0, dy or 0)
    else
        castBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 160)
    end

    local RUTA_RELLENO = "Interface\\CastingBar\\UI-CastingBar-Fill"
    local RUTA_BORDE   = "Interface\\CastingBar\\UI-CastingBar-Border"
    local RUTA_CHISPA  = "Interface\\CastingBar\\UI-CastingBar-Spark"
    local function Existe(ruta)
        return (not GetFileIDFromPath) or GetFileIDFromPath(ruta) ~= nil
    end

    local castBg = castBar:CreateTexture(nil, "BACKGROUND")
    castBg:SetColorTexture(0, 0, 0, 0.7)
    castBg:SetAllPoints(castBar)

    -- El relleno SIEMPRE tiene que pintar. Antes se ponia solo `if Existe(...)`, y como en este
    -- cliente esa ruta no resuelve, la barra se quedaba vacia: borde perfecto y nada dentro.
    -- SpellCreator llego a la misma conclusion y por eso trae su propia `castingbar-fill.blp`;
    -- aqui se resuelve con respaldo en vez de con un fichero de arte propio.
    --
    -- Ultimo recurso un color solido: sin textura no hay barra, y una barra lisa se ve, que es
    -- infinitamente mejor que un hueco.
    -- La sonda de la nativa dice que su relleno es `UI-StatusBar`, no `UI-CastingBar-Fill`
    -- (esa ruta ni siquiera resuelve en este cliente). Se usa la buena directamente.
    local relleno = castBar:CreateTexture(nil, "ARTWORK")
    if Existe("Interface\\TargetingFrame\\UI-StatusBar") then
        relleno:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    else
        relleno:SetColorTexture(1, 1, 1)
    end
    castBar:SetStatusBarTexture(relleno)
    castBar:SetStatusBarColor(1, 0.7, 0)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)

    -- La chispa marca el frente del relleno. ADD para que brille sobre la barra.
    local castSpark = castBar:CreateTexture(nil, "OVERLAY")
    if Existe(RUTA_CHISPA) then
        castSpark:SetTexture(RUTA_CHISPA)
        castSpark:SetBlendMode("ADD")
        castSpark:SetSize(32, 32)
        -- La nativa la centra con +2 de alto; el avance lo mueve el OnUpdate.
    else
        castSpark:Hide()
    end
    castBar.spark = castSpark

    -- El borde va en su propio frame POR ENCIMA: como textura del StatusBar quedaria por debajo
    -- del relleno y se veria cortado por el avance de la barra.
    local castOverlay = CreateFrame("Frame", nil, castBar)
    castOverlay:SetFrameLevel(castBar:GetFrameLevel() + 2)
    castOverlay:SetAllPoints(castBar)
    local castBorder = castOverlay:CreateTexture(nil, "ARTWORK")
    if Existe(RUTA_BORDE) then
        castBorder:SetTexture(RUTA_BORDE)
        -- El marco es una textura de TAMANO FIJO 256x64 anclada por su TOP al TOP de la
        -- barra con +28, tal cual lo mide la sonda de la nativa. NO se estira con
        -- TOPLEFT/BOTTOMRIGHT: hacerlo la deformaba a 241x53 y el relleno parecia salirse
        -- del marco. El arte ya trae su propio margen alrededor de los 195x13 utiles.
        castBorder:SetSize(256, 64)
        castBorder:SetPoint("TOP", castBar, "TOP", 0, 28)
    else
        castBorder:Hide()
    end

    castBar.text = castOverlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castBar.text:SetPoint("CENTER", castBar, "CENTER", 0, 0)
    castBar:Hide()
    frame.castBar = castBar

    -- Animacion y sonido los lleva `HarfordProfessionFX`: aqui solo se le dice en que punto va
    -- la fabricacion. `fx` es el estado de la TANDA, no de la pieza, para que la animacion no se
    -- devuelva entre piezas encadenadas (daba el parpadeo 69-13-69 en cada unidad de la cola).
    --
    -- Se declara ANTES de CancelCast a proposito: un cierre solo captura las locales que ya
    -- existen cuando se crea, y declarada despues seria una global nil ahi dentro.
    local fx = nil

    local function CancelCast()
        castBar:SetScript("OnUpdate", nil)
        castBar:Hide()
        -- El sonido muere con la barra, no despues: por aqui pasan TODAS las salidas del casteo
        -- -completarse, moverse, cerrar la ventana-, asi que corta en el instante exacto y no
        -- sigue sonando mientras se tira el dado o se descuentan materiales.
        if HarfordProfessionFX then HarfordProfessionFX.CutSound(fx) end
    end

    -- `Stop` va en StopQueue y no en CancelCast a proposito: devuelve la ANIMACION a reposo, y
    -- CancelCast corre tambien ENTRE piezas encadenadas (daria el parpadeo). El sonido si se
    -- corta en cada pieza, la animacion no.
    local function ResetAnim()
        if HarfordProfessionFX then fx = HarfordProfessionFX.Stop(fx) else fx = nil end
    end

    local function StopQueue(reason)
        queue.left = 0
        queue.recipeId = nil
        bagWatcher:UnregisterAllEvents()
        if queue.timeout then queue.timeout = nil end
        CancelCast()
        ResetAnim()
        if reason and HarfordChat and HarfordChat.Print then HarfordChat.Print(reason) end
        RefreshUI()
    end
    frame:HookScript("OnHide", function() StopQueue() end)

    local ResolveCraft

    -- Fundicion: animacion de artesano en el personaje + barra + sonido, y la receta se
    -- resuelve (tirada incluida) SOLO al terminar la barra.
    local function BeginCast(recipeName)
        if HarfordProfessionFX then
            fx = HarfordProfessionFX.Begin(state.profId, fx)
        end
        castBar.text:SetText(recipeName or "")
        castBar:SetValue(0)
        castBar:Show()
        local elapsed = 0
        castBar:SetScript("OnUpdate", function(self, dt)
            -- Moverse interrumpe, como en el juego. Se mira la VELOCIDAD y no
            -- PLAYER_STARTED_MOVING: AGENTS.md avisa de que ese evento puede no disparar en
            -- Epsilon, y aqui ya hay un OnUpdate corriendo, asi que preguntarla sale gratis.
            -- Como los materiales se gastan al COMPLETAR, interrumpir no cuesta nada.
            if GetUnitSpeed and (GetUnitSpeed("player") or 0) > 0 then
                -- Sin motivo en el chat: la barra desapareciendo ya lo dice, y moverse es algo
                -- que el jugador acaba de hacer a proposito.
                return StopQueue()
            end
            elapsed = elapsed + dt
            if HarfordProfessionFX then HarfordProfessionFX.Tick(fx, dt, CRAFT_TIME) end
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
        -- Craft revalida CanCraft por su cuenta y descuenta el material reservado.
        local ok, motivo = HarfordProfessions.Craft(queue.recipeId)
        -- Cierra la fase de la pieza: corta el sonido de la profesion en seco. El de exito -solo
        -- lo tiene encantamiento- es el unico que puede seguir sonando despues de la barra.
        if HarfordProfessionFX then HarfordProfessionFX.Finish(fx, ok) end

        -- "Crear todo" pide N INTENTOS, no N aciertos: un fallo normal no gasta nada y se sigue
        -- con el siguiente. Antes el primer fallo se llevaba por delante los que quedaban.
        --
        -- La PIFIA si corta: acaba de echar a perder los materiales, y encadenar mas intentos
        -- despues de eso es justo lo que el jugador no querria. Y tampoco se sigue cuando la
        -- pieza ya NO SE PUEDE intentar -sin materiales, sin herramienta, receta no aprendida-,
        -- porque eso no cambia por reintentar.
        local seguirIntentando = (motivo == "fallo")
        if not ok and not seguirIntentando then return StopQueue() end
        if queue.left <= 0 then return StopQueue() end

        -- Un fallo SIN pifia no gasta materiales, asi que la bolsa no cambia y su evento no
        -- llegaria nunca: se encadena directo en vez de esperar a un aviso que no vendra.
        if not ok and motivo == "fallo" then
            RefreshUI()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, CraftNext)
            else
                CraftNext()
            end
            return
        end

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

    -- Refresco automatico mientras la ventana este abierta. Recibir o gastar objetos cambia lo
    -- que se puede fabricar y cuantas unidades salen, y hasta ahora habia que hacer click en algo
    -- para que la lista se enterase.
    --
    -- Watcher APARTE del de la cola: aquel se des-registra solo al encadenar piezas con
    -- `UnregisterAllEvents`, asi que compartirlo apagaria tambien este.
    --
    -- `BAG_UPDATE_DELAYED` y no `BAG_UPDATE`: dispara UNA vez por tanda de cambios en vez de una
    -- por hueco de bolsa, que al descontar materiales serian varias seguidas.
    --
    -- Se registra en OnShow y se suelta en OnHide: con la ventana cerrada no hay nada que
    -- repintar, y dejar el evento vivo es justo lo que el contrato pide no hacer.
    local stockWatcher = CreateFrame("Frame")
    stockWatcher:SetScript("OnEvent", function()
        if frame and frame:IsShown() then RefreshUI() end
    end)
    frame:HookScript("OnShow", function()
        stockWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
    end)
    frame:HookScript("OnHide", function()
        stockWatcher:UnregisterAllEvents()
        -- La estacion dura lo que la ventana: al cerrarla dejas de estar en la forja. Asi no
        -- hace falta vigilar la distancia, que seria sondeo continuo.
        if HarfordProfessions and HarfordProfessions.ClearActiveStation then
            HarfordProfessions.ClearActiveStation()
        end
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
-- MODELO DE LA LISTA: recetas filtradas, ordenadas y con sus cabeceras de rango.
--
-- Se construye UNA vez y se guarda en `state.model`. Antes esto corria entero en CADA muesca
-- de rueda -recorrer las 1614 recetas del catalogo, filtrar, ordenar y montar las cabeceras-
-- y era lo que hundia los fps. Al hacer scroll no cambia ningun dato: solo hay que repintar
-- las filas visibles. Lo invalida `InvalidarLista()`, que llaman las cosas que SI cambian el
-- contenido: cambiar de profesion o de pestana, buscar, filtrar, plegar un rango, fabricar y
-- las bolsas.
local function ConstruirModelo(def)
    -- Filtro por pestaña: Aprendidas = iniciales o aprendidas explicitamente;
    -- No aprendidas = cualquier receta que aun debe enseñarse o comprarse.
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

    return display
end

RefreshList = function()
    if not (frame and frame:IsShown()) then return end
    local def = Prof()
    if not (def and HarfordProfessions) then return end
    local skill = HarfordProfessions.EffectiveSkill(def.id)

    if frame.TitleText then
        -- El titulo salia cortado ("Herreri"): el TitleText del template viene estrecho.
        frame.TitleText:SetWidth(0)
        frame.TitleText:SetText(def.name)
    end
    -- El retrato solo se recarga al CAMBIAR de profesion: es una carga de textura, y repetirla
    -- en cada refresco de la lista no cambia nada de lo que se ve.
    if frame.portrait and frame._retratoDe ~= def.id then
        frame._retratoDe = def.id
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

    local display = state.model
    if not display then
        display = ConstruirModelo(def)
        state.model = display
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
            row.tier = tier
            -- Solo se toca la textura si de verdad cambia de estado: SetNormalTexture por ruta
            -- vuelve a resolver el fichero cada vez. El resaltado y el OnClick ya se pusieron al
            -- crear la fila, y el rango que necesita el manejador viaja en `row.tier`.
            local plegado = state.collapsed[tier] and true or false
            if row._plegado ~= plegado then
                row._plegado = plegado
                row.expander:SetNormalTexture(plegado
                    and "Interface\\Buttons\\UI-PlusButton-Up"
                    or "Interface\\Buttons\\UI-MinusButton-Up")
            end
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
            -- CanCraft es CARO en la pestana de no aprendidas (resuelve el entrenador de cada
            -- receta), asi que su resultado se cachea por receta y solo se recalcula cuando la
            -- lista se invalida. Antes se llamaba 20 veces por muesca de rueda.
            state.craftableCache = state.craftableCache or {}
            local craftable = state.craftableCache[rec.id]
            if craftable == nil then
                local _, _, mats = HarfordProfessions.CanCraft(rec.id)
                for _, m in ipairs(mats or {}) do
                    local possible = m.missingId and 0 or math.floor((m.have or 0) / math.max(1, m.need or 1))
                    craftable = craftable and math.min(craftable, possible) or possible
                end
                state.craftableCache[rec.id] = craftable or false
            elseif craftable == false then
                craftable = nil
            end
            -- La CANTIDAD FABRICABLE va pegada al nombre y entre corchetes -"Espada larga [3]"-,
            -- como en la ventana de referencia. Antes iba en una etiqueta suelta a la derecha,
            -- que la separaba de la receta a la que se refiere.
            row.expander:Hide()
            row.tier = nil
            -- Sin icono de plegar no hay nada que iluminar: dejarlo encendido pintaba un brillo
            -- suelto en el margen izquierdo que el nativo no tiene.
            if row.hi then row.hi:SetAlpha(0) end
            local nombre = rec.name or rec.id
            if craftable and craftable > 0 then
                nombre = nombre .. " [" .. craftable .. "]"
            end
            row.text:SetText(nombre)
            row.text:SetTextColor(r, g, b)
            row.baseColor = { r, g, b }
            -- La etiqueta suelta se vacia: el contador vive ahora dentro del nombre.
            row.count:SetText("")
            row.sel:SetVertexColor(r, g, b)   -- nativo: la seleccion toma el color de la fila
            local seleccionada = rec.id == state.selected
            row.sel:SetShown(seleccionada)
            -- Seleccionada: texto en blanco y ahi se queda (el nativo hace lo mismo).
            if seleccionada then row.text:SetTextColor(1, 1, 1) end
            row:Show()
        else
            row.recipeId = nil
            row.tier = nil
            row:Hide()
        end
    end

end

-- El detalle solo se rehace cuando cambia la RECETA SELECCIONADA. Antes iba pegado al
-- refresco de la lista, asi que cada muesca de la rueda volvia a cargar el icono de la
-- receta, los de todos los materiales y sus tooltips aunque la seleccion no hubiera
-- cambiado: eso era lo que hundia los fps al hacer scroll.
RefreshDetail = function()
    if not (frame and frame:IsShown()) then return end
    local def = Prof()
    if not (def and HarfordProfessions) then return end
    local skill = HarfordProfessions.EffectiveSkill(def.id)
    -- Detalle de la seleccionada
    -- La receta se pide por id: \`recipes\` era una local del refresco de la LISTA y aqui ya no
    -- existe. Con ella nil, \`ipairs\` reventaba y el detalle no se repintaba nunca.
    local sel = state.selected and HarfordProfessions.GetRecipe
        and HarfordProfessions.GetRecipe(state.selected) or nil
    local d = frame.detail
    if not sel then
        d.name:SetText("")
        d.req:SetText("")
        d.desc:SetText("")
        d.reqLabel:Hide()
        if d.trainerLine then d.trainerLine:SetText("") end
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
        d.iconHit.itemKey = sel.output and sel.output.key or nil
    end
    d.name:SetText(sel.name or sel.id)
    local ok, reason, detailMats = HarfordProfessions.CanCraft(sel.id)
    -- Cantidad producida sobre el icono (solo si es mas de una, como el nativo)
    local outQty = (sel.output and tonumber(sel.output.qty)) or 1
    d.resultCount:SetText(outQty > 1 and tostring(outQty) or "")

    -- Descripcion: la de la receta si la declara; si no, de que profesion y rango es. Antes
    -- este medio panel quedaba vacio porque no pintabamos nada de esto.
    -- Solo la descripcion PROPIA de la receta. La de relleno -"Receta de alquimia del rango
    -- Oficial"- no decia nada que no estuviera ya en la lista y en la linea de instructor.
    --
    -- El hueco bajo la descripcion es CONDICIONAL, igual que en el nativo
    -- (Blizzard_TradeSkillDetails.lua): por defecto ancla a BOTTOMLEFT (0,0) y SOLO cuando hay
    -- descripcion de verdad lo baja a -18. Sin esto queda un hueco muerto entre el icono y
    -- "Requiere" en las recetas sin texto.
    local hayDesc = sel.description and sel.description ~= ""
    d.desc:SetText(hayDesc and sel.description or "")
    d.reqLabel:ClearAllPoints()
    d.reqLabel:SetPoint("TOPLEFT", d.desc, "BOTTOMLEFT", 0, hayDesc and -18 or 0)

    -- "Requiere" son las CONDICIONES DEL SITIO Y DEL EQUIPO: estacion y herramienta, en una
    -- sola linea separadas por coma, como el "Requires: Anvil, Blacksmith Hammer" del nativo.
    --
    -- El nivel de profesion ya NO va aqui: es lo que hace falta para APRENDERLA, no para
    -- fabricarla, y por eso baja a la linea de instructor.
    local skillReq = tonumber(sel.skillReq) or 1
    local reqPartes = {}

    local estacionNombre = select(2, HarfordProfessions.GetRequiredStation
        and HarfordProfessions.GetRequiredStation(sel))
    if estacionNombre then
        local dentro = HarfordProfessions.HasRequiredStation
            and HarfordProfessions.HasRequiredStation(sel)
        reqPartes[#reqPartes + 1] = (dentro and "|cff40c040" or "|cffff5555")
            .. estacionNombre .. "|r"
    end

    -- La herramienta va en rojo si es comprobable y no la llevas. Si su objeto aun no esta
    -- registrado no se puede comprobar, asi que se muestra sin color y sin prometer nada.
    if def.tool then
        local comprobable = HarfordProfessions.ToolIsCheckable
            and HarfordProfessions.ToolIsCheckable(def.id)
        local llevada = not comprobable or (HarfordProfessions.HasToolItem
            and HarfordProfessions.HasToolItem(def.id))
        if not comprobable then
            reqPartes[#reqPartes + 1] = def.tool
        else
            reqPartes[#reqPartes + 1] = (llevada and "|cff40c040" or "|cffff5555")
                .. def.tool .. "|r"
        end
    end

    -- Aqui SOLO van el sitio y la herramienta, como el "Requires: Anvil, Blacksmith Hammer"
    -- nativo. Los demas motivos ya se ven en su sitio y repetirlos era ruido: los materiales que
    -- faltan los pintan los propios huecos en rojo, y lo de la habilidad y donde se aprende lo
    -- dice la linea de instructor de abajo.
    local hayReq = #reqPartes > 0
    d.reqLabel:SetShown(hayReq)
    d.req:SetShown(hayReq)
    -- La formula del nativo, con la etiqueta ya medida en castellano.
    d.req:SetWidth(236 - (d.reqLabel:GetWidth() or 48))
    d.req:SetText(table.concat(reqPartes, ", "))

    -- "Materiales:" no se re-ancla: sus dos puntos fijos ya lo resuelven. Si no hay requisitos
    -- la cadena de valores mide 0 de alto y la etiqueta sube sola hasta la fila de "Requiere".

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
            local fallback = HarfordProfessionsItems and HarfordProfessionsItems.GetIcon
                and HarfordProfessionsItems.GetIcon(m.key)
            slot.icon:SetTexture(ico or (fallback and "Interface\\Icons\\" .. fallback)
                or "Interface\\Icons\\INV_Misc_QuestionMark")
        else
            local fallback = HarfordProfessionsItems and HarfordProfessionsItems.GetIcon
                and HarfordProfessionsItems.GetIcon(m.key)
            slot.icon:SetTexture((fallback and "Interface\\Icons\\" .. fallback)
                or "Interface\\Icons\\INV_Misc_QuestionMark")
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
        slot.itemId, slot.itemName, slot.itemKey = m.id, m.name, m.key
        slot:Show()
    end
    for i = #mats + 1, #state.reagents do state.reagents[i]:Hide() end

    -- INSTRUCTOR Y COSTE: una SOLA cadena separada por |n, como el nativo, que lo guarda todo
    -- en un unico FontString. Dos anclajes: la Y del ultimo hueco de material -por eso se pone
    -- aqui y no al construir, la altura depende de cuantas filas haya- y la X del margen
    -- izquierdo. Sin ese segundo punto la linea se iba a la derecha cuando la ultima fila de
    -- materiales tenia una sola columna.
    local ultimoHueco = (#mats > 0) and state.reagents[#mats] or d.reagentsTitle
    d.trainerLine:ClearAllPoints()
    d.trainerLine:SetPoint("TOP", ultimoHueco, "BOTTOM", 0, -15)
    d.trainerLine:SetPoint("LEFT", d.reagentsTitle, "LEFT", 0, 0)

    -- Se muestra mientras NO la tengas: una vez aprendida ya no dice nada util.
    local yaLaTienes = HarfordProfessions.IsRecipeLearned
        and HarfordProfessions.IsRecipeLearned(sel.id)
    if yaLaTienes then
        d.trainerLine:SetText("")
    else
        -- Como lo escribe el nativo, leido de la sonda: la ETIQUETA en dorado dentro de la
        -- propia cadena (|cFFFFD200) y el VALOR en blanco, que es el color del FontString.
        -- El valor va en rojo si aun no llegas al nivel, igual que el nativo pinta en rojo lo
        -- que te falta en "Requires".
        local enRojo = HarfordProfessions.EffectiveSkill(def.id) < skillReq
        local lineas = string.format("|cFFFFD200Instructor de profesion: |r%s%s (%d)%s",
            enRojo and "|cffff2020" or "", def.name or "", skillReq, enRojo and "|r" or "")

        -- El coste con los iconos de moneda del juego, como el "Cost:" nativo.
        local coste = HarfordProfessionTrainers and HarfordProfessionTrainers.GetRecipeCost
            and HarfordProfessionTrainers.GetRecipeCost(sel.id) or 0
        if coste > 0 and GetCoinTextureString then
            lineas = lineas .. "|n|cFFFFD200Coste: |r" .. GetCoinTextureString(coste)
        end
        d.trainerLine:SetText(lineas)
    end
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

RefreshUI = function()
    -- Refresco completo = los datos pueden haber cambiado (pestana, busqueda, filtro, una
    -- fabricacion, las bolsas). El scroll llama a RefreshList a secas y reaprovecha el modelo.
    InvalidarLista()
    RefreshList()
    RefreshDetail()
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

------------------------------------------------------------
-- Entrada desde el mundo
------------------------------------------------------------

-- Lo que llama el ArcSpell de la forja, del yunque o de la fogata: abre la ventana Y deja
-- constancia de que estas en esa estacion, para las recetas que la exijan.
--
-- `profId` es opcional: con el se abre directamente esa profesion; sin el solo se marca la
-- estacion y el jugador abre lo que quiera desde el libro.
--
-- Se marca ANTES de abrir porque `Open` refresca, y el refresco ya tiene que ver la estacion
-- puesta o pintaria las recetas como no disponibles durante un instante.
function API.OpenAtStation(stationId, profId)
    if not (HarfordProfessions and HarfordProfessions.SetActiveStation) then
        return false, "Profesiones no disponible"
    end
    local ok, err = HarfordProfessions.SetActiveStation(stationId)
    if not ok then return false, err end
    if profId then return API.Open(profId) end
    return true
end

-- Mismo nombre publico que usan los entrenadores y las misiones de mundo, para que el gossip
-- tenga un solo sitio donde mirar.
_G.HarfordProfessionsAPI = _G.HarfordProfessionsAPI or {}
_G.HarfordProfessionsAPI.OpenAtStation = API.OpenAtStation
_G.HarfordProfessionsAPI.OpenProfession = API.Open
