-- HarfordCharacterAdvancement: prototipo visual de creacion y progresion.
-- No persiste ni modifica fichas; solo presenta el arbol construido desde el Libro.

HarfordCharacterAdvancement = HarfordCharacterAdvancement or {}

-- Adelantada: se usa (linea ~1034) antes de definirse (linea ~1600). Era un global accidental.
local OpenWeaponPickDialog

local API = HarfordCharacterAdvancement
local S = { frame = nil, mode = "creation", targetTotal = nil, stage = "race", raceId = "raza_humano", subraceId = "", backgroundId = nil, selected = nil, nodeRows = {}, choiceSelections = {}, choiceRows = {}, attributeArrays = nil, selectedArray = nil, attributeAssignments = {}, pendingScore = nil, classConfirmed = false, secondaryClassId = nil, secondarySubclassId = "", primaryLevel = 0, secondaryLevel = 0, levelPlan = {}, pendingClassId = nil, pendingFeatures = {}, classSelectionOpen = true, classSelectionMode = "base" }

local CREATION_LEVEL = 1  -- la creacion confirma SOLO el nivel 1; los niveles 2 y 3 se encadenan como subidas
local MAX_PREVIEW_LEVEL = CREATION_LEVEL

-- Aplicar el borrador (crear personaje / subir nivel) vive en HarfordCharacterDraft.
local Draft = HarfordCharacterDraft

local function CopyTable(source)
    if type(source) ~= "table" then return source end
    local out = {}
    for key, value in pairs(source) do out[key] = CopyTable(value) end
    return out
end

local function RequiredTotal()
    return tonumber(S.targetTotal) or CREATION_LEVEL
end

local function IsLevelUpMode()
    return S.mode == "levelup"
end

-- Desplazamiento de la columna izquierda: en SUBIDA no se dibuja la barra de pasos (144 px),
-- asi que la lista de clases y sus controles se recolocan a la izquierda. Los botones se anclan
-- en absoluto al frame, asi que no basta con mover el scroll.
local function LeftShift()
    return IsLevelUpMode() and -144 or 0
end

-- Marco de las tarjetas. `WhiteIconFrame` es un aro cuadrado BLANCO pensado para rodear un icono,
-- asi que admite tinte con SetVertexColor (es como se pintan los bordes de calidad de objeto).
-- Ya lo usa el PaperDoll del panel de personaje, o sea que existe en Epsilon.
local TEX_MARCO = "Interface\\Common\\WhiteIconFrame"
local MARCO_ORO = { 1, 0.82, 0 }
local MARCO_APAGADO = { 0.45, 0.43, 0.38 }

-- Marco de TODA la tarjeta (la zona pulsable, la misma que se aclara al pasar por encima). Es un
-- backdrop, asi que la tarjeta debe crearse con "BackdropTemplate"; se tine con
-- SetBackdropBorderColor igual que el marco del icono.
--
-- Los tres bordes que el proyecto ya usa en Epsilon, por si se quiere cambiar (solo estas dos
-- constantes; `edgeSize` acompana al grosor del arte):
--   Tooltips\\UI-Tooltip-Border          fino y neutro, el generico (edgeSize 12)
--   DialogFrame\\UI-DialogBox-Border      ornamentado oscuro, con relieve (edgeSize 16)
--   DialogFrame\\UI-DialogBox-Gold-Border dorado ornamentado, el mas cargado (edgeSize 16)
local TEX_BORDE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local BORDE_GROSOR = 16

local function PonerBorde(card)
    if not card.SetBackdrop then return false end
    if not card._bordePuesto then
        card:SetBackdrop({ edgeFile = TEX_BORDE, edgeSize = BORDE_GROSOR })
        card._bordePuesto = true
    end
    return true
end

-- Fabrica UNICA de tarjeta de seleccion. Las tres rejillas (raza/trasfondo, clase, y el pool
-- compartido de subraza/subclase/variante) tenian el mismo bloque copiado, con las mismas capas
-- en el mismo orden y solo cambiando medidas. Los nombres de campo tambien difieren en origen
-- (`harfordIcon`...), asi que se unifican aqui: `fondo`, `sel`, `icono`, `nombre`.
local function CrearTarjeta(parent, ancho, alto, tamIcono, padTexto)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(ancho, alto)
    card.fondo = card:CreateTexture(nil, "BACKGROUND")
    card.fondo:SetAllPoints(card)
    card.fondo:SetColorTexture(0, 0, 0, 0.35)
    -- Tinte dorado de seleccion, por debajo del contenido.
    card.sel = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    card.sel:SetAllPoints(card)
    card.sel:SetColorTexture(0.55, 0.42, 0.1, 0.30)
    local hl = card:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(card)
    hl:SetColorTexture(1, 1, 1, 0.08)
    card.icono = card:CreateTexture(nil, "ARTWORK")
    card.icono:SetSize(tamIcono, tamIcono)
    card.icono:SetPoint("CENTER", card, "CENTER", 0, 12)
    card.icono:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- El nombre se ancla al FONDO y crece hacia arriba, con tope de 2 lineas: colgandolo del
    -- icono, un nombre largo se salia por abajo y cruzaba el marco.
    card.nombre = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.nombre:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 4, padTexto)
    card.nombre:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, padTexto)
    card.nombre:SetJustifyH("CENTER")
    card.nombre:SetWordWrap(true)
    if card.nombre.SetMaxLines then card.nombre:SetMaxLines(2) end
    return card
end

local function PonerMarco(card, icono)
    if card.marco then return card.marco end
    card.marco = card:CreateTexture(nil, "OVERLAY")
    card.marco:SetTexture(TEX_MARCO)
    card.marco:SetPoint("TOPLEFT", icono, "TOPLEFT", -1, 1)
    card.marco:SetPoint("BOTTOMRIGHT", icono, "BOTTOMRIGHT", 1, -1)
    return card.marco
end

-- Rejilla de tarjetas de seleccion de raza y trasfondo: 4 por fila.
local GRID_COLUMNS, GRID_CELL_W, GRID_CELL_H, GRID_GAP, GRID_ICON = 4, 94, 82, 4, 40
-- Las clases van en la columna estrecha (layout "list", 996 de ancho): 2 por fila, y con 12
-- clases eso son 6 filas, que a la altura de las de raza no cabrian en los 620 del frame.
local CLASS_COLUMNS, CLASS_CELL_W, CLASS_CELL_H, CLASS_ICON = 2, 130, 72, 32

-- Razas cuyo tronco es elegible como "subraza" ademas de las declaradas. HOY NINGUNA: el Elfo
-- de la Noche paso a tener DOS subrazas reales (Elfo de la Noche y Altonato), como en la web.
-- El mecanismo se conserva por si otra raza lo necesita.
local BASE_RACE_IDS = {}

local function MakeText(parent, template, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetText(text or "")
    return fs
end

-- Tooltip al pasar por encima, para razas, subrazas, clases y subclases. Los textos se piden con
-- callbacks y no se guardan en el frame: las tarjetas se reutilizan entre refrescos y un texto
-- pegado al frame se quedaria mostrando la eleccion anterior.
-- Resumen de una descripcion de origen (raza, subraza, clase, subclase, trasfondo, variante):
-- parrafos narrativos (la cita en cursiva de apertura y su atribucion se saltan), corta en el
-- primer encabezado ### y limita a DOS parrafos. Los textos cortos sin estructura pasan tal
-- cual. Es lo que muestran los tooltips de las tarjetas y la seccion de origen: el texto
-- completo del manual sigue en los datos, pero la UI enseña el resumen, como la web.
local function ResumenDeOrigen(texto)
    texto = tostring(texto or "")
    local parrafos = {}
    for p in (texto .. "\n\n"):gmatch("(.-)\n%s*\n") do
        p = p:gsub("^%s+", ""):gsub("%s+$", "")
        if p:find("^#") then break end                -- empieza el detalle por secciones
        local esCita = p:find("^%*") and (p:find("%*$") or p:find("^%*[—%-]"))
        if p ~= "" and not esCita then
            p = p:gsub("%*%*%*", ""):gsub("%*%*", ""):gsub("%*", "")
            parrafos[#parrafos + 1] = p
            if #parrafos == 2 then break end
        end
    end
    if #parrafos == 0 then return texto end           -- textos cortos sin estructura: tal cual
    return table.concat(parrafos, "\n\n")
end

-- Version para TOOLTIP: UN solo parrafo y tope de ~600 caracteres (unas 7-10 lineas en el
-- GameTooltip), cortando en limite de palabra (el espacio es ASCII: no parte UTF-8). Varios
-- trasfondos traen un unico parrafo enorme y el tooltip ocupaba media pantalla.
local function ResumenTooltip(texto)
    texto = ResumenDeOrigen(texto)
    local parrafo = texto:match("^(.-)\n%s*\n") or texto
    if #parrafo > 600 then
        local corte = parrafo:sub(1, 600):match("^(.*)%s%S*$") or parrafo:sub(1, 600)
        parrafo = corte .. "…"
    end
    return parrafo
end

local function AttachTooltip(frame, obtenerTitulo, obtenerCuerpo, colorTitulo)
    if not frame or not frame.SetScript then return end
    frame:SetScript("OnEnter", function(self)
        local titulo = obtenerTitulo and obtenerTitulo()
        if not titulo or titulo == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local r, g, b = 1, 0.82, 0
        if colorTitulo then
            local cr, cg, cb = colorTitulo()
            if cr then r, g, b = cr, cg, cb end
        end
        GameTooltip:SetText(titulo, r, g, b, 1, true)
        local cuerpo = obtenerCuerpo and obtenerCuerpo()
        if cuerpo and cuerpo ~= "" then
            GameTooltip:AddLine(cuerpo, 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function MakeButton(parent, text, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text or "")
    button:SetScript("OnClick", onClick)
    return button
end

local function ClearRows()
    for _, row in ipairs(S.nodeRows) do row:Hide() end
    wipe(S.nodeRows)
    S.nodePoolUsed = 0  -- los botones de nodo se reutilizan del pool (ver CreateNode)
end

local function SetManualScroll(scroll, child, offset)
    offset = math.max(0, tonumber(offset) or 0)
    scroll._offset = offset
    child:ClearAllPoints()
    child:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, offset)
end

local function GetClass()
    return HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
end

local function GetSubclass(classDef)
    if not (classDef and HarfordDnDBook and HarfordDnDBook.GetSubclass) then return nil end
    return HarfordDnDBook.GetSubclass(classDef.id, S.subclassId)
end

local function NodeKind(feature)
    if feature and feature.choice then return "choice" end
    if feature and feature.type == "accion" then return "action" end
    return "auto"
end

local function NodeColor(kind)
    if kind == "choice" then return 0.22, 0.82, 0.42 end
    if kind == "action" then return 0.76, 0.54, 0.16 end
    return 0.55, 0.42, 0.18
end

local function HasSubraces(raceDef)
    return raceDef and type(raceDef.subraces) == "table" and #raceDef.subraces > 0
end

local function AllowsBaseRace(raceDef)
    return raceDef and BASE_RACE_IDS[raceDef.id] == true
end

local function ContainsChoice(selections, optionId)
    for index, selectedId in ipairs(selections or {}) do
        if selectedId == optionId then return index end
    end
    return nil
end

-- Nº de veces que una opcion esta elegida (las mejoras de caracteristica pueden repetirse).
local function CountChoice(selections, optionId)
    local n = 0
    for _, selectedId in ipairs(selections or {}) do
        if selectedId == optionId then n = n + 1 end
    end
    return n
end

-- ¿La eleccion admite repetir la misma opcion? Solo las mejoras de caracteristica
-- (`optionsFrom = "ability+N"`): elegir dos veces la misma es el "+2 a una caracteristica" del
-- manual. Metamagia, estilos de combate, habilidades, etc. NO se pueden duplicar.
local function IsStackableChoice(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return false end
    local from = tostring(choice.optionsFrom or "")
    -- La Mejora de Caracteristica de la bestia es el mismo "+2 a una o +1 a dos" del jugador.
    if from == "beastAbility" then return true end
    return from:match("^ability%+%d+$") ~= nil
end

local function GetBookFeatureDescription(feature, source)
    if not (feature and HarfordDnDBookText and HarfordDnDBookText.GetFeatureDescription) then
        return feature and feature.description or "Sin descripcion."
    end
    return HarfordDnDBookText.GetFeatureDescription(feature, S.classId, source, S.backgroundId)
end

local OpenChoiceDialog
local RefreshSteps   -- forward: se asigna junto al frame; lo llaman los refrescos de cada etapa
local RaceAbilityBonus     -- forward: se asigna mas abajo; el picker de conjuros lo usa antes de su def
local AppendSpellPickers   -- forward: definido tras OpenSpellDialog; lo llama RefreshPendingLevelFeatures
local SpellsForClass       -- forward: definido con el selector; lo usa Draft.PersistSpellPicks, mas arriba
local ExpandedSpellNames   -- forward: mismo motivo, la poda de Draft.PersistSpellPicks lo usa antes

local function SetDetail(feature, level, source)
    S.selected = feature
    for _, button in ipairs(S.choiceRows) do button:Hide() end
    wipe(S.choiceRows)
    if not (S.detailTitle and S.detailText and S.detailChoices) then return end
    if not feature then
        S.detailTitle:SetText("Selecciona un nodo")
        S.detailText:SetText("El arbol muestra rasgos reales del Libro. Los nodos verdes requieren una eleccion.")
        S.detailChoices:SetText("")
        return
    end
    local title = tostring(source or "Rasgo")
    if level then title = title .. " - Nivel " .. tostring(level) end
    S.detailTitle:SetText(title)
    S.detailText:SetText(tostring(GetBookFeatureDescription(feature, source)))
    local options = HarfordDnDBook and HarfordDnDBook.GetChoiceOptions and HarfordDnDBook.GetChoiceOptions(feature) or nil
    if options and #options > 0 then
        local selected = S.choiceSelections[feature.id] or {}
        local labels = {}
        for _, optionId in ipairs(selected) do
            local option = HarfordDnDBook.GetChoiceOption and HarfordDnDBook.GetChoiceOption(feature, optionId)
            labels[#labels + 1] = tostring(option and option.label or optionId)
        end
        local slots = HarfordDnDBook.GetChoiceSlots and HarfordDnDBook.GetChoiceSlots(feature) or 1
        S.detailChoices:SetText("Elecciones: " .. tostring(#selected) .. "/" .. tostring(slots)
            .. (#labels > 0 and "\n" .. table.concat(labels, "\n") or "\nPulsa el boton para elegir."))
        if S.stage == "race_choices" or S.stage == "background_choices" or S.stage == "class" then
            local choose = MakeButton(S.frame, "Elegir opciones", 204, 24, function()
                OpenChoiceDialog(feature, level, source)
            end)
            -- Anclado al bloque de elecciones (que ApplyModeLayout recoloca), no a una x absoluta
            choose:SetPoint("BOTTOMLEFT", S.detailChoices, "TOPLEFT", 0, 10)
            S.choiceRows[#S.choiceRows + 1] = choose
        else
            S.detailChoices:SetText("Confirma primero esta opcion para realizar la eleccion.")
        end
    else
        S.detailChoices:SetText("Se concede automaticamente al confirmar el nivel.")
    end
end

-- Nodos reutilizados de un pool persistente (S.nodePool): cada refresh reconfigura los botones ya
-- creados en vez de crear frames nuevos (WoW no permite destruirlos; crearlos por refresh los fuga).
local function CreateNode(parent, x, y, level, feature, source)
    local kind = NodeKind(feature)
    local r, g, b = NodeColor(kind)
    -- Ancho relativo a la x de entrada: todas las filas cierran en el mismo borde derecho
    -- (348 en coords del child = 16px antes del divisor), tengan la sangria que tengan.
    local width = 348 - (tonumber(x) or 26)

    S.nodePool = S.nodePool or {}
    S.nodePoolUsed = (S.nodePoolUsed or 0) + 1
    local row = S.nodePool[S.nodePoolUsed]
    if not row then
        row = CreateFrame("Button", nil, parent)
        row._bg = row:CreateTexture(nil, "BACKGROUND")
        row._bg:SetAllPoints(row)
        row._accent = row:CreateTexture(nil, "BORDER")
        row._icon = row:CreateTexture(nil, "ARTWORK")
        row._icon:SetSize(24, 24)
        row._icon:SetPoint("LEFT", row, "LEFT", 10, 0)
        row._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row._name = MakeText(row, "GameFontHighlightSmall", "")
        row._name:SetJustifyH("LEFT")
        row._badge = MakeText(row, "GameFontDisableSmall", "")
        row:SetScript("OnEnter", function(self) self._bg:SetColorTexture(0.12, 0.1, 0.055, 0.96) end)
        row:SetScript("OnLeave", function(self) self._bg:SetColorTexture(0.025, 0.024, 0.02, 0.92) end)
        S.nodePool[S.nodePoolUsed] = row
    end

    row:SetParent(parent)
    row:ClearAllPoints()
    row:SetSize(width, 38)
    row:SetPoint("TOPLEFT", x, y)
    row._bg:SetColorTexture(0.025, 0.024, 0.02, 0.92)
    row._accent:ClearAllPoints()
    row._accent:SetPoint("LEFT", row, "LEFT", 0, 0)
    row._accent:SetSize(4, 38)
    row._accent:SetColorTexture(r, g, b, 1)
    row._icon:SetTexture((HarfordDnDData and HarfordDnDData.GetFeatureIcon and HarfordDnDData.GetFeatureIcon(feature))
        or "Interface\\Icons\\INV_Misc_QuestionMark")
    row._name:ClearAllPoints()
    row._name:SetPoint("LEFT", row._icon, "RIGHT", 8, 0)
    row._name:SetWidth(width - 120)
    row._name:SetText(feature.name or "Rasgo")
    row._badge:ClearAllPoints()
    row._badge:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row._badge:SetText(kind == "choice" and "ELECCION" or (source == "Subclase" and "RAMA" or "RASGO"))
    row._badge:SetTextColor(r, g, b)
    row:SetScript("OnClick", function() SetDetail(feature, level, source) end)
    row:Show()
    S.nodeRows[#S.nodeRows + 1] = row
end

local RefreshClassStage
local RefreshOptionCards  -- forward: la usan subraza (etapa raza) y subclase (etapa clase)
local EquipmentGroups     -- forward: la etapa de clase pregunta si hay equipo mucho antes de
                          -- que se defina, junto al selector de equipo
local CommitClassLevel

local function RefreshClassList()
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    S.classButtons = S.classButtons or {}
    local y, columna, indice = -76, 0, 0
    -- Tope de 2 clases: si la ficha ya es multiclase, en subida solo se listan ESAS dos
    -- clases (no se puede añadir una tercera).
    local lockToOwned = S.mode == "levelup" and S.secondaryClassId ~= nil and S.secondaryClassId ~= ""
    for _, classDef in ipairs(HarfordDnDBook.GetClasses() or {}) do
        local chosen = classDef
        local owned = chosen.id == S.classId or chosen.id == S.secondaryClassId
        if not lockToOwned or owned then
            -- En subida, cada clase muestra el nivel que recibiria: "Chaman (6)" si ya tienes
            -- Chaman 5, "Guerrero (1)" si seria multiclase nueva. En creacion, solo el nombre.
            local label = tostring(chosen.name or "")
            if S.mode == "levelup" then
                local current = 0
                if chosen.id == S.classId then current = tonumber(S.primaryLevel) or 0
                elseif chosen.id == S.secondaryClassId then current = tonumber(S.secondaryLevel) or 0 end
                label = label .. " (" .. (current + 1) .. ")"
            end
            -- Tarjeta, igual que la rejilla de razas: icono de clase arriba y nombre debajo,
            -- 4 por fila. Antes era una lista vertical de botones de 210x28.
            local seleccionada = S.pendingClassId == chosen.id
            indice = indice + 1
            -- Reutilizadas entre refrescos, como el resto de listas del panel.
            local card = S.classButtons[indice]
            if not card then
                card = CrearTarjeta(S.frame, CLASS_CELL_W, CLASS_CELL_H, CLASS_ICON, 7)
                S.classButtons[indice] = card
            end
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", 154 + LeftShift() + columna * (CLASS_CELL_W + GRID_GAP), y)
            card.sel:SetShown(seleccionada)
            card.nombre:SetText(label)

            -- Icono y color de clase: misma fuente que el resto del addon y la web
            -- (classicon_<token> via ClassFileFromText, color unico de HarfordClassColors).
            local classFile = HarfordClassColors and HarfordClassColors.ClassFileFromText
                and HarfordClassColors.ClassFileFromText(chosen.name)
            if classFile then
                card.icono:SetTexture("Interface\\Icons\\classicon_" .. classFile:lower())
                local r, g, b = HarfordClassColors.ColorRGBForClassFile(classFile)
                if r then card.nombre:SetTextColor(r, g, b) end
            else
                card.icono:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            card.icono:SetDesaturated(not seleccionada)
            -- El marco toma el COLOR DE LA CLASE, que aqui es informacion y no adorno. La
            -- seleccionada lo lleva a plena intensidad; el resto, atenuado.
            local marco = PonerMarco(card, card.icono)
            local mr, mg, mb = MARCO_APAGADO[1], MARCO_APAGADO[2], MARCO_APAGADO[3]
            if classFile and HarfordClassColors.ColorRGBForClassFile then
                local cr, cg, cb = HarfordClassColors.ColorRGBForClassFile(classFile)
                if cr then
                    local k = seleccionada and 1 or 0.55
                    mr, mg, mb = cr * k, cg * k, cb * k
                end
            end
            marco:SetVertexColor(mr, mg, mb)
            if PonerBorde(card) then
                card:SetBackdropBorderColor(mr, mg, mb, seleccionada and 1 or 0.55)
            end

            local bloqueada = S.classSelectionMode == "add" and chosen.id == S.classId
            card:SetEnabled(not bloqueada)
            if bloqueada then card.icono:SetDesaturated(true) end
            card:SetScript("OnClick", function()
                S.pendingClassId = chosen.id
                RefreshClassStage()
            end)
            AttachTooltip(card,
                function() return tostring(chosen.name or "") end,
                function() return chosen.summary or ResumenTooltip(chosen.desc or chosen.description) end,
                function()
                    if classFile and HarfordClassColors.ColorRGBForClassFile then
                        return HarfordClassColors.ColorRGBForClassFile(classFile)
                    end
                end)
            card:Show()
            columna = columna + 1
            if columna >= CLASS_COLUMNS then
                columna = 0
                y = y - (CLASS_CELL_H + GRID_GAP)
            end
        end
    end
end

-- Un rasgo con `requiresOption` es la CONSECUENCIA de una eleccion, no algo que recibas por subir:
-- solo se lista si esa opcion esta elegida. Sin esto, un Brujo de nivel 2 veia las 8 Maldiciones
-- como si las obtuviera todas, y el resumen del About las listaba como rasgos nuevos.
local function PendingOptionChosen(feature)
    local req = feature and feature.requiresOption
    if not req then return true end
    for _, seleccion in pairs(S.choiceSelections or {}) do
        for _, optId in ipairs(seleccion or {}) do
            if tostring(optId) == tostring(req) then return true end
        end
    end
    return false
end

local function RefreshPendingLevelFeatures(classDef, classLevel)
    S.pendingFeatures = {}
    local y = -34
    local heading = MakeText(S.tree, "GameFontNormal", "RASGOS QUE RECIBIRAS EN ESTE NIVEL")
    heading:SetPoint("TOPLEFT", 28, y)
    heading:SetTextColor(1, 0.82, 0)
    S.nodeRows[#S.nodeRows + 1] = heading
    y = y - 34
    local firstFeature
    for _, feature in ipairs(classDef.features or {}) do
        if tonumber(feature.level) == classLevel and PendingOptionChosen(feature) then
            S.pendingFeatures[#S.pendingFeatures + 1] = feature
            CreateNode(S.tree, 26, y, classLevel, feature, "Clase")
            firstFeature = firstFeature or { feature = feature, source = "Clase" }
            y = y - 44
        end
    end
    if classDef.id == S.classId or classDef.id == S.secondaryClassId or not S.classId then
        local unlockLevel = HarfordDnDBook.GetSubclassUnlockLevel and HarfordDnDBook.GetSubclassUnlockLevel(classDef.id) or 99
        local subclassId = classDef.id == S.classId and S.subclassId or S.secondarySubclassId
        local subclass = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, subclassId)
        if subclass and classLevel >= unlockLevel then
            for _, feature in ipairs(subclass.features or {}) do
                if tonumber(feature.level) == classLevel and PendingOptionChosen(feature) then
                    S.pendingFeatures[#S.pendingFeatures + 1] = feature
                    CreateNode(S.tree, 44, y, classLevel, feature, "Subclase")
                    firstFeature = firstFeature or { feature = feature, source = "Subclase" }
                    y = y - 44
                end
            end
        end
    end
    if not firstFeature then
        local empty = MakeText(S.tree, "GameFontDisableSmall", "Esta clase no obtiene un rasgo nuevo en este nivel.")
        empty:SetPoint("TOPLEFT", 28, y)
        S.nodeRows[#S.nodeRows + 1] = empty
        y = y - 28
        SetDetail(nil)
    else
        SetDetail(firstFeature.feature, classLevel, firstFeature.source)
    end

    -- Selector de conjuros: solo si la clase (o clase+subclase) es lanzadora en este nivel.
    y = AppendSpellPickers(classDef, classLevel, y)

    S.treeChild:SetHeight(math.max(420, -y + 18))
    SetManualScroll(S.treeScroll, S.treeChild, 0)
end

local function PendingChoicesComplete()
    for _, feature in ipairs(S.pendingFeatures or {}) do
        if feature.choice then
            local selected = S.choiceSelections[feature.id] or {}
            local slots = HarfordDnDBook.GetChoiceSlots and HarfordDnDBook.GetChoiceSlots(feature) or 1
            if #selected < slots then return false end
        end
    end
    return true
end

local function ConfigureSubclassChoice(classDef, classLevel)
    local unlockLevel = HarfordDnDBook.GetSubclassUnlockLevel and HarfordDnDBook.GetSubclassUnlockLevel(classDef.id) or 99
    if classLevel < unlockLevel then return true end
    local primarySlot = classDef.id == S.classId or not S.classId
    local selectedId = primarySlot and S.subclassId or S.secondarySubclassId
    -- Una subclase ya CONFIRMADA en la progresion viva no se vuelve a elegir: la subida a
    -- nivel 2+ mostraba otra vez las tarjetas (Sacerdote elige dominio a nivel 1) e invitaba
    -- a cambiar de subclase, cosa que las reglas no permiten. Se muestra fija, sin tarjetas.
    -- La PRIMERA eleccion (la progresion aun no la tiene) sigue abriendo el selector normal.
    if IsLevelUpMode() and selectedId and selectedId ~= "" then
        local vivo = HarfordDnDProgression and HarfordDnDProgression.Get and HarfordDnDProgression.Get()
        for _, e in ipairs((vivo and vivo.classLevels) or {}) do
            if tostring(e.classId) == tostring(classDef.id)
                and tostring(e.subclassId or "") == tostring(selectedId) then
                local sub = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, selectedId)
                S.selectorLabel:SetText("Subclase: " .. tostring((sub and sub.name) or selectedId))
                S.selectorLabel:Show()
                S.subclassDrop:Hide()
                RefreshOptionCards(nil)
                return true
            end
        end
    end
    local subclasses = classDef.subclasses or {}
    -- Requisito racial de subclase (Sacerdocio de Elune = raza_elfo_noche): la que tu raza no
    -- puede tomar no aparece como tarjeta. Raza del borrador en creacion; de la progresion en
    -- subida. Si el filtro vaciara la lista (datos raros), se muestran todas antes que bloquear.
    do
        local razaId = S.raceId
        if (not razaId or razaId == "") and HarfordDnDProgression and HarfordDnDProgression.GetRace then
            local r = HarfordDnDProgression.GetRace()
            razaId = r and r.id
        end
        razaId = tostring(razaId or "")
        local permitidas = {}
        for _, sub in ipairs(subclasses) do
            if not sub.requiredRace or razaId == "" or razaId == tostring(sub.requiredRace) then
                permitidas[#permitidas + 1] = sub
            end
        end
        if #permitidas > 0 then subclasses = permitidas end
    end
    if #subclasses == 0 then return true end
    S.selectorLabel:SetText("Subclase")
    S.selectorLabel:Show()
    S.subclassDrop:Hide()

    -- Igual que las subrazas: tarjetas con icono en vez de desplegable, y una elegida de entrada
    -- para que el panel no quede en un "Elige subclase" vacio. Aqui no hay equivalente a la raza
    -- base: si la subclase esta desbloqueada, elegir una es obligatorio.
    if (not selectedId or selectedId == "") and subclasses[1] then
        selectedId = subclasses[1].id
        if primarySlot then S.subclassId = selectedId else S.secondarySubclassId = selectedId end
    end
    local selected = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, selectedId)

    RefreshOptionCards(subclasses, selectedId,
        function(choice)
            return HarfordDnDData and HarfordDnDData.GetSubclassIcon
                and HarfordDnDData.GetSubclassIcon(classDef.id, choice.id)
        end,
        function(choice)
            if primarySlot then S.subclassId = choice.id else S.secondarySubclassId = choice.id end
            RefreshClassStage()
        end)
    return selected ~= nil
end

RefreshClassStage = function()
    if RefreshSteps then RefreshSteps() end
    ClearRows()
    S.originScroll:Hide()
    S.originSlider:Hide()
    local assigned = S.primaryLevel + S.secondaryLevel
    local requiredTotal = RequiredTotal()
    local nextLevel = assigned + 1
    for _, button in ipairs(S.classMetaButtons or {}) do button:Hide() end
    S.classMetaButtons = {}
    if S.classSelectionOpen then
        -- En subida el rotulo sobra (el panel derecho ya dice el nivel); en creacion se conserva.
        S.listTitle:SetText(IsLevelUpMode() and "" or ("ELIGE CLASE: NIVEL " .. tostring(nextLevel) .. " DE " .. tostring(requiredTotal)))
        RefreshClassList()
        local preview = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.pendingClassId)
        S.classTitle:SetText(preview and tostring(preview.name) or "Elige la clase que recibira este nivel")
        -- Con SUBCLASE elegida, su descripcion sustituye a la de la clase (la tarjeta de
        -- Sombra debe contar lo suyo, no repetir el resumen del Sacerdote).
        local previewDesc = preview and tostring(preview.desc or "") or nil
        if preview then
            local subId = preview.id == S.classId and S.subclassId or S.secondarySubclassId
            local sub = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(preview.id, subId)
            if sub and tostring(sub.desc or "") ~= "" then previewDesc = tostring(sub.desc) end
        end
        S.classSummary:SetText(previewDesc or (S.classSelectionMode == "add"
            and "La nueva clase empezara en nivel 1. Solo se permiten dos clases."
            or "Selecciona una clase para continuar la subida de nivel."))
        S.subclassDrop:Hide()
        S.selectorLabel:Hide()
        RefreshOptionCards(nil)
        if preview then
            local previewLevel = preview.id == S.classId and S.primaryLevel + 1
                or (preview.id == S.secondaryClassId and S.secondaryLevel + 1 or 1)
            RefreshPendingLevelFeatures(preview, previewLevel)
            local subclassReady = ConfigureSubclassChoice(preview, previewLevel)
            S.nextButton:SetEnabled(subclassReady and PendingChoicesComplete())
        else
            SetDetail(nil)
        end
        S.nextButton:SetText(preview and ("Elegir " .. tostring(preview.name)) or "Selecciona una clase")
        if not preview then S.nextButton:SetEnabled(false) end
        S.nextButton:SetShown(true)
        return
    end
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    if assigned >= requiredTotal then
        local first = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
        local second = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.secondaryClassId)
        S.listTitle:SetText(IsLevelUpMode() and "SUBIDA PREPARADA" or "NIVELES ASIGNADOS")
        S.classTitle:SetText((IsLevelUpMode() and "Subida preparada a nivel " or "Creacion preparada a nivel ") .. tostring(requiredTotal))
        S.classSummary:SetText(tostring(first and first.name or "") .. " nivel " .. tostring(S.primaryLevel)
            .. (second and (" / " .. tostring(second.name) .. " nivel " .. tostring(S.secondaryLevel)) or "")
            .. (IsLevelUpMode()
                and "\nTodo esta listo para aplicar el nivel y actualizar el About de TRP3."
                or "\nTodo esta listo para crear la ficha y generar el About de TRP3."))
        S.subclassDrop:Hide()
        S.selectorLabel:Hide()
        RefreshOptionCards(nil)
        SetDetail(nil)
        -- En creacion, si la clase reparte equipo, antes de crear se pasa por esa pantalla.
        local conEquipo = (not IsLevelUpMode()) and #EquipmentGroups() > 0
        S.nextButton:SetText(IsLevelUpMode() and "Aplicar subida de nivel"
            or (conEquipo and "Elegir equipo" or "Crear ficha y generar About TRP3"))
        S.nextButton:SetEnabled(true)
        S.nextButton:Show()
        return
    end
    local pending = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.pendingClassId)
    if not pending then
        S.classSelectionOpen = true
        RefreshClassStage()
        return
    end
    local pendingLevel = pending.id == S.classId and S.primaryLevel + 1 or (pending.id == S.secondaryClassId and S.secondaryLevel + 1 or 1)
    S.listTitle:SetText("NIVEL " .. tostring(nextLevel) .. " DE " .. tostring(requiredTotal))
    S.classTitle:SetText(tostring(pending.name) .. " recibira nivel " .. tostring(pendingLevel))
    S.classSummary:SetText("Esta es la unica clase que sube en este paso. Confirma el nivel para aplicar sus rasgos y elecciones.")
    local subclassReady = ConfigureSubclassChoice(pending, pendingLevel)
    RefreshPendingLevelFeatures(pending, pendingLevel)
    local function AddClassControl(text, y, onClick)
        local button = MakeButton(S.frame, text, 150, 24, onClick)
        button:SetPoint("TOPLEFT", 164 + LeftShift(), y)
        S.classMetaButtons[#S.classMetaButtons + 1] = button
        return button
    end
    local first = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
    local second = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.secondaryClassId)
    AddClassControl("Progreso: " .. tostring(first and first.name or "") .. " " .. tostring(S.primaryLevel) .. (second and (" / " .. tostring(second.name) .. " " .. tostring(S.secondaryLevel)) or ""), -414, nil):Disable()
    if second then
        AddClassControl("Cambiar a " .. tostring(S.pendingClassId == S.classId and second.name or first.name), -442, function()
            S.pendingClassId = S.pendingClassId == S.classId and S.secondaryClassId or S.classId
            RefreshClassStage()
        end)
    elseif assigned > 0 then
        AddClassControl("Anadir clase", -442, function()
            S.classSelectionOpen, S.classSelectionMode = true, "add"
            RefreshClassStage()
        end)
    end
    S.nextButton:SetText("Confirmar nivel " .. tostring(nextLevel))
    S.nextButton:SetEnabled(assigned < requiredTotal and subclassReady and PendingChoicesComplete())
    S.nextButton:SetShown(true)
end

CommitClassLevel = function()
    local assigned = S.primaryLevel + S.secondaryLevel
    if assigned >= RequiredTotal() then return end
    local id = S.pendingClassId
    if id == S.classId then
        S.primaryLevel = S.primaryLevel + 1
    elseif id == S.secondaryClassId then
        S.secondaryLevel = S.secondaryLevel + 1
    elseif not S.classId then
        S.classId = id
        -- En clases cuya subclase se desbloquea a nivel 1 (Sacerdote incluido),
        -- ConfigureSubclassChoice ya la ha elegido antes de confirmar la clase.
        -- Solo descartamos un id que no pertenezca a la clase recien elegida.
        if not (HarfordDnDBook and HarfordDnDBook.GetSubclass
            and HarfordDnDBook.GetSubclass(id, S.subclassId)) then
            S.subclassId = ""
        end
        S.primaryLevel = 1
    elseif not S.secondaryClassId then
        S.secondaryClassId = id
        if not (HarfordDnDBook and HarfordDnDBook.GetSubclass
            and HarfordDnDBook.GetSubclass(id, S.secondarySubclassId)) then
            S.secondarySubclassId = ""
        end
        S.secondaryLevel = 1
    else
        return
    end
    S.levelPlan[#S.levelPlan + 1] = id
    S.classConfirmed = S.primaryLevel + S.secondaryLevel == RequiredTotal()
    S.classSelectionOpen, S.classSelectionMode = false, "advance"
    RefreshClassStage()
end

local RefreshOrigin

-- Icono de una tarjeta. Las razas tienen arte propio POR SEXO en HarfordCharacterCreation, que
-- es su unica fuente y no se toca. Los trasfondos SI tienen icono propio por id en el catalogo
-- (importado de la web); antes salian los 191 con el mismo pergamino generico.
local function GridIconFor(isRace, id)
    local C = HarfordCharacterCreation
    local sep = string.char(92)  -- backslash: la ruta de textura de WoW lo exige
    local RAIZ = "Interface" .. sep .. "Icons" .. sep

    -- Las fuentes no devuelven todas lo mismo: GetRaceIcon y GetGenericIcon dan el nombre pelado,
    -- pero HarfordIconCatalog.GetFeatureIcon ya devuelve la RUTA completa (pasa por TexturePath).
    -- Anteponer la raiz a ciegas duplicaba el prefijo y dejaba el icono roto.
    local function Ruta(icono)
        if type(icono) == "number" then return icono end
        icono = tostring(icono or "")
        if icono == "" then return nil end
        if icono:sub(1, #RAIZ) == RAIZ then return icono end
        if icono:sub(1, 10) == "Interface" .. sep then return icono end
        return RAIZ .. icono
    end

    local icon = isRace and C and C.GetRaceIcon and C.GetRaceIcon(id)
    if not icon then
        icon = HarfordIconCatalog and HarfordIconCatalog.GetFeatureIcon
            and HarfordIconCatalog.GetFeatureIcon(id)
    end
    -- El propio elemento puede traer su arte declarada. Los trasfondos la declaran en sus datos
    -- (`icon = "..."`) y el catalogo plano no siempre los tiene: sin esto, un trasfondo con icono
    -- propio salia con el generico solo por faltarle la entrada duplicada en el catalogo.
    if not icon and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground then
        local bg = HarfordDnDBackgrounds.GetBackground(id)
        if bg and bg.icon and bg.icon ~= "" then icon = bg.icon end
    end
    icon = icon or (C and C.GetGenericIcon and C.GetGenericIcon())
    return Ruta(icon) or (RAIZ .. "INV_Misc_QuestionMark")
end

-- Tarjetas de eleccion en el panel de detalle (subraza y subclase): mismo aspecto que la rejilla
-- de razas (icono arriba, nombre debajo, tinte dorado en la seleccionada) pero mas pequenas,
-- porque ninguna raza ni clase pasa de cuatro opciones. Las dos comparten pool y posicion: nunca
-- se muestran a la vez, porque una es de la etapa de raza y la otra de la de clase.
-- `opciones = nil` las oculta todas.
local SUB_CELL_W, SUB_CELL_H, SUB_ICON, SUB_GAP = 86, 70, 32, 4
RefreshOptionCards = function(opciones, seleccionadoId, iconoDe, alElegir)
    S.subraceCards = S.subraceCards or {}
    for _, card in ipairs(S.subraceCards) do card:Hide() end
    if not opciones then return end

    for indice, entrada in ipairs(opciones) do
        local choice = entrada
        local card = S.subraceCards[indice]
        if not card then
            card = CrearTarjeta(S.frame, SUB_CELL_W, SUB_CELL_H, SUB_ICON, 6)
            S.subraceCards[indice] = card
        end
        local columna = (indice - 1) % 4
        card:SetPoint("TOPLEFT", S.frame, "TOPLEFT",
            592 + (S.layoutDX or 0) + columna * (SUB_CELL_W + SUB_GAP), S.subraceCardsY or -118)
        local seleccionada = (choice.id or "") == (seleccionadoId or "")
        -- El icono puede venir pelado o como ruta completa segun la fuente; Ruta() de GridIconFor
        -- ya normaliza eso, pero aqui llega crudo, asi que se normaliza igual.
        local icono = iconoDe and iconoDe(choice)
        card.icono:SetTexture(GridIconFor(false, "")) -- respaldo si no hay arte declarado
        if icono then
            local sep = string.char(92)
            icono = tostring(icono)
            if icono:sub(1, 10) ~= "Interface" .. sep then
                icono = "Interface" .. sep .. "Icons" .. sep .. icono
            end
            card.icono:SetTexture(icono)
        end
        card.icono:SetDesaturated(not seleccionada)
        card.nombre:SetText(tostring(choice.name or choice.id or ""))
        card.nombre:SetTextColor(seleccionada and 1 or 0.85, seleccionada and 0.82 or 0.85,
            seleccionada and 0 or 0.85)
        card.sel:SetShown(seleccionada)
        local marco = PonerMarco(card, card.icono)
        local mc = seleccionada and MARCO_ORO or MARCO_APAGADO
        marco:SetVertexColor(mc[1], mc[2], mc[3])
        if PonerBorde(card) then card:SetBackdropBorderColor(mc[1], mc[2], mc[3], seleccionada and 1 or 0.55) end
        card:SetScript("OnClick", function()
            if alElegir then alElegir(choice) end
        end)
        AttachTooltip(card,
            function() return tostring(choice.name or "") end,
            function() return choice.summary or ResumenTooltip(choice.desc or choice.description) end)
        card:Show()
    end
end

local function RefreshOriginList()
    if RefreshSteps then RefreshSteps() end
    for _, button in ipairs(S.originButtons or {}) do button:Hide() end
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    for _, button in ipairs(S.classMetaButtons or {}) do button:Hide() end
    S.originButtons = S.originButtons or {}
    S.originScroll:SetShown(S.stage ~= "race_choices" and S.stage ~= "background_choices")
    S.originSlider:SetShown(false)
    if S.stage == "equipment" then return end
    if S.stage == "race_choices" or S.stage == "background_choices" then return end
    local entries = S.stage == "race" and HarfordDnDRaces.GetRaces() or HarfordDnDBackgrounds.GetBackgrounds()
    -- Rejilla de tarjetas con icono, al estilo de la creacion de BG3: 4 por fila, icono arriba y
    -- nombre debajo. Los trasfondos no tienen arte propio y usan el icono generico (no inventar).
    local isRace = S.stage == "race"
    local column, row, indice = 0, 0, 0
    for _, entry in ipairs(entries or {}) do
        local choice = entry
        local selected = (isRace and choice.id == S.raceId) or (not isRace and choice.id == S.backgroundId)
        indice = indice + 1
        -- Tarjeta propia (sin plantilla azul de UIPanelButton): el boton cubre toda la celda,
        -- icono arriba y nombre debajo. Se REUTILIZAN entre refrescos: antes se creaba un frame
        -- nuevo por tarjeta en cada pasada y los viejos solo se ocultaban.
        local card = S.originButtons[indice]
        if not card then
            card = CrearTarjeta(S.originChild, GRID_CELL_W, GRID_CELL_H, GRID_ICON, 7)
            S.originButtons[indice] = card
        end
        card:SetScript("OnClick", function()
            if isRace then
                S.raceId = choice.id
                -- Viene una opcion elegida de entrada, para que el panel nunca quede en un
                -- "Elige subraza" vacio. Se toma la PRIMERA subraza, salvo en las razas cuyo
                -- libro admite la raza base (hoy solo Elfo de la Noche): ahi la base es una
                -- eleccion legitima y no se puede reclasificar al jugador sin que lo pida.
                if AllowsBaseRace(choice) then
                    S.subraceId = ""
                else
                    local primera = (choice.subraces or {})[1]
                    S.subraceId = (primera and primera.id) or ""
                end
            else
                S.backgroundId = choice.id
                -- La variante es del trasfondo anterior; se descarta al cambiar.
                S.backgroundVariantId = ""
            end
            RefreshOriginList()
            RefreshOrigin()
        end)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", 4 + column * (GRID_CELL_W + GRID_GAP), -4 - row * (GRID_CELL_H + GRID_GAP))
        card.icono:SetTexture(GridIconFor(isRace, choice.id))
        -- Sin marco circular ni mascara: todos los iconos son cuadrados y se muestran tal cual
        -- (decision 2026-08-20; el recorte por mascara no funciono de forma fiable en Epsilon
        -- para estas tarjetas).
        card.nombre:SetText(tostring(choice.name or ""))
        card.nombre:SetTextColor(selected and 1 or 0.85, selected and 0.82 or 0.85, selected and 0 or 0.85)
        card.icono:SetDesaturated(not selected)
        card.sel:SetShown(selected)
        local marco = PonerMarco(card, card.icono)
        local mc = selected and MARCO_ORO or MARCO_APAGADO
        marco:SetVertexColor(mc[1], mc[2], mc[3])
        if PonerBorde(card) then card:SetBackdropBorderColor(mc[1], mc[2], mc[3], selected and 1 or 0.55) end
        AttachTooltip(card,
            function() return tostring(choice.name or "") end,
            function() return choice.summary or ResumenTooltip(choice.desc or choice.description) end)
        card:Show()
        column = column + 1
        if column >= GRID_COLUMNS then column, row = 0, row + 1 end
    end
    local usedRows = row + (column > 0 and 1 or 0)
    S.originChild:SetHeight(math.max(430, usedRows * (GRID_CELL_H + GRID_GAP) + 12))
    local range = math.max(0, S.originChild:GetHeight() - 494)
    -- Elegir una tarjeta refresca la lista entera, y reponer el scroll a 0 devolvia al principio
    -- de los 52 trasfondos cada vez que pulsabas uno. Se conserva la posicion mientras sea LA
    -- MISMA lista; al cambiar de etapa (razas <-> trasfondos) si se vuelve arriba, porque es otro
    -- contenido y la posicion anterior no significa nada.
    local desplazamiento = 0
    if S.originListaEtapa == S.stage then
        desplazamiento = math.min(tonumber(S.originScroll._offset) or 0, range)
    end
    S.originListaEtapa = S.stage
    SetManualScroll(S.originScroll, S.originChild, desplazamiento)
    S.originSlider:SetMinMaxValues(0, range)
    S.originSlider:SetValue(desplazamiento)
    S.originSlider:SetShown(range > 0)
end

RefreshOrigin = function()
    if RefreshSteps then RefreshSteps() end
    if not S.frame then return end
    ClearRows()
    local isRace = S.stage == "race" or S.stage == "race_choices"
    local def = isRace and HarfordDnDRaces.GetRace(S.raceId) or HarfordDnDBackgrounds.GetBackground(S.backgroundId)
    if not def then return end
    S.listTitle:SetText(S.stage == "race_choices" and "RAZA CONFIRMADA"
        or (S.stage == "background_choices" and "TRASFONDO CONFIRMADO" or (isRace and "RAZAS" or "TRASFONDOS")))
    -- Solo el nombre: la seccion ya dice si estas en Raza o en Trasfondo, y el prefijo robaba
    -- ancho a nombres largos ("Trasfondo: Mercenario veterano harford").
    S.classTitle:SetText(tostring(def.name or ""))
    -- La descripcion larga va DENTRO del scroll (ver mas abajo): con el texto fijo en el
    -- frame y los rasgos a altura fija, las descripciones largas de trasfondo se solapaban.
    S.classSummary:SetText("")
    S.selectorLabel:SetText(isRace and "Subraza" or "Origen")
    -- ANTES de pintar las tarjetas: su y la leen al anclarse.
    S.subraceCardsY = -78

    -- Subraza: tarjetas con icono, como la rejilla de razas, en vez de un desplegable. El
    -- desplegable compartido se reserva para la subclase.
    if isRace then
        local subraces = def.subraces or {}
        local mostrar = #subraces > 0 and S.stage == "race"
        if S.subclassDrop then S.subclassDrop:Hide() end
        S.selectorLabel:SetShown(mostrar)
        local opciones
        if mostrar then
            opciones = {}
            -- La raza base es una opcion propia cuando el libro la admite (hoy solo Elfo de la
            -- Noche): se muestra como una tarjeta mas, la primera, para poder volver a ella.
            if AllowsBaseRace(def) then
                opciones[#opciones + 1] = { id = "", name = tostring(def.name), desc = def.desc, base = true }
            end
            for _, entry in ipairs(subraces) do opciones[#opciones + 1] = entry end
        end
        RefreshOptionCards(opciones, S.subraceId,
            function(choice)
                local Cre = HarfordCharacterCreation
                return Cre and Cre.GetRaceIcon
                    and Cre.GetRaceIcon(def.id, choice.base and "" or choice.id)
            end,
            function(choice)
                S.subraceId = choice.id or ""
                RefreshOrigin()
            end)
    else
        if S.subclassDrop then S.subclassDrop:Hide() end
        -- Variantes de trasfondo (Criminal -> Espia, Noble -> Caballero nobiliario...). Son
        -- OPCIONALES: el trasfondo a secas es un personaje valido, asi que va como primera
        -- tarjeta y es la que viene elegida. Solo son narrativas, no conceden rasgos.
        local variantes = def.variants or {}
        local mostrar = #variantes > 0 and S.stage == "background"
        S.selectorLabel:SetText("Variante")
        S.selectorLabel:SetShown(mostrar)
        local opciones
        if mostrar then
            opciones = { { id = "", name = tostring(def.name), desc = def.desc, base = true } }
            for _, v in ipairs(variantes) do opciones[#opciones + 1] = v end
        end
        RefreshOptionCards(opciones, S.backgroundVariantId,
            function(choice)
                if choice.base then
                    -- El base lleva el icono del propio trasfondo, el mismo de su tarjeta.
                    return HarfordIconCatalog and HarfordIconCatalog.GetFeatureIcon
                        and HarfordIconCatalog.GetFeatureIcon(def.id)
                end
                return choice.icon
            end,
            function(choice)
                S.backgroundVariantId = choice.id or ""
                RefreshOrigin()
            end)
    end

    -- Recolocacion vertical segun haya tarjetas o no. ApplyModeLayout (que corre al principio,
    -- via RefreshSteps) deja las posiciones del modo; aqui se ajusta la vertical del detalle.
    do
        local dx = S.layoutDX or 0
        local hayTarjetas = S.selectorLabel:IsShown()
        S.selectorLabel:ClearAllPoints()
        S.selectorLabel:SetPoint("TOPLEFT", 592 + dx, -62)
        local topArbol = hayTarjetas and -(78 + SUB_CELL_H + 14) or -64
        if S.treeScroll then
            S.treeScroll:ClearAllPoints()
            S.treeScroll:SetPoint("TOPLEFT", 588 + dx, topArbol)
            S.treeScroll:SetPoint("BOTTOMRIGHT", 602 + dx, 48)
        end
    end

    local traits = {}
    if isRace then
        for _, feature in ipairs(def.traits or {}) do traits[#traits + 1] = { feature = feature, source = "Raza" } end
        local sub = HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
        for _, feature in ipairs((sub and sub.traits) or {}) do traits[#traits + 1] = { feature = feature, source = "Subraza" } end
    else
        local bgTraits = (HarfordDnDBackgrounds.ResolveTraits
            and HarfordDnDBackgrounds.ResolveTraits(S.backgroundId, S.backgroundVariantId)) or def.traits or {}
        for _, feature in ipairs(bgTraits) do traits[#traits + 1] = { feature = feature, source = "Trasfondo" } end
    end
    -- Descripcion dentro del scroll: los rasgos arrancan justo debajo de donde termina,
    -- y descripcion + rasgos se desplazan juntos con la rueda. Se muestra un RESUMEN, no el
    -- texto completo del manual. Con SUBRAZA elegida manda la descripcion de la subraza
    -- (Altonato debe contar lo suyo, no repetir el texto del Elfo de la Noche); sin texto
    -- propio de subraza se cae al de la raza.
    -- El summary de la raza manda sobre el resumen automatico: varias razas (Trol) no
    -- tienen parrafo introductorio general y el automatico mezclaba parrafos de subrazas.
    local descTexto = def.summary or def.desc
    if isRace then
        local sub = HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
        if sub then descTexto = sub.summary or ((tostring(sub.desc or "") ~= "") and sub.desc) or descTexto end
    else
        -- Variante de trasfondo elegida: manda su descripcion (Gladiador cuenta lo suyo,
        -- no repite el texto del Animador). El "base" no tiene desc propia: texto del padre.
        for _, v in ipairs(def.variants or {}) do
            if tostring(v.id) == tostring(S.backgroundVariantId or "")
                and tostring(v.desc or "") ~= "" then descTexto = v.desc break end
        end
    end
    local desc = MakeText(S.tree, "GameFontHighlightSmall", ResumenDeOrigen(descTexto))
    desc:SetPoint("TOPLEFT", 8, -8)
    desc:SetWidth(340)  -- cierra en el mismo borde derecho que las filas (348 - 8)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    desc:SetTextColor(0.82, 0.82, 0.82)
    S.nodeRows[#S.nodeRows + 1] = desc
    local descBottom = 8 + math.ceil(desc:GetStringHeight() or 0)

    local heading = MakeText(S.tree, "GameFontNormal", isRace and "RASGOS DE RAZA" or "RASGOS DE TRASFONDO")
    heading:SetPoint("TOPLEFT", 8, -(descBottom + 20))
    heading:SetTextColor(1, 0.82, 0)
    S.nodeRows[#S.nodeRows + 1] = heading
    local y = -(descBottom + 48)
    for _, entry in ipairs(traits) do
        CreateNode(S.tree, entry.source == "Subraza" and 28 or 8, y, nil, entry.feature, entry.source)
        y = y - 44
    end
    if #traits == 0 then
        local empty = MakeText(S.tree, "GameFontDisableSmall", "No hay rasgos registrados para esta opcion.")
        empty:SetPoint("TOPLEFT", 8, y)
        S.nodeRows[#S.nodeRows + 1] = empty
        y = y - 28
    end
    S.treeChild:SetHeight(math.max(420, -y + 16))
    SetManualScroll(S.treeScroll, S.treeChild, 0)
    local choicesComplete = true
    for _, entry in ipairs(traits) do
        if entry.feature.choice then
            local selected = S.choiceSelections[entry.feature.id] or {}
            local slots = HarfordDnDBook.GetChoiceSlots and HarfordDnDBook.GetChoiceSlots(entry.feature) or 1
            if #selected < slots then choicesComplete = false end
        end
    end
    local canConfirmRace = not HasSubraces(def) or AllowsBaseRace(def) or (S.subraceId and S.subraceId ~= "")
    if S.stage == "race" then
        S.nextButton:SetText(canConfirmRace and "Confirmar raza" or "Elige una subraza")
        S.nextButton:SetEnabled(canConfirmRace)
    elseif S.stage == "race_choices" then
        S.nextButton:SetText(choicesComplete and "Elegir trasfondo" or "Completa las elecciones")
        S.nextButton:SetEnabled(choicesComplete)
    elseif S.stage == "background" then
        S.nextButton:SetText("Confirmar trasfondo")
        S.nextButton:SetEnabled(true)
    elseif S.stage == "background_choices" then
        S.nextButton:SetText(choicesComplete and "Caracteristicas" or "Completa las elecciones")
        S.nextButton:SetEnabled(choicesComplete)
    end
    S.nextButton:SetShown(true)
    if traits[1] then
        SetDetail(traits[1].feature, nil, traits[1].source)
    else
        SetDetail(nil)
    end
end

-- Seleccion de equipo del grupo `i`, creandola si hace falta.
local function EquipPick(i)
    S.equipmentPicks = S.equipmentPicks or {}
    if type(S.equipmentPicks[i]) ~= "table" then
        S.equipmentPicks[i] = { opcion = 1, armas = {} }
    end
    return S.equipmentPicks[i]
end

-- Grupos de equipo inicial de la clase que se esta creando.
EquipmentGroups = function()
    local classId = S.classId or S.pendingClassId
    local clase = classId and HarfordDnDBook and HarfordDnDBook.GetClass
        and HarfordDnDBook.GetClass(classId)
    return (clase and clase.startingEquipment) or {}
end

local RefreshEquipmentStage
RefreshEquipmentStage = function()
    ClearRows()
    S.originScroll:Hide()
    if RefreshSteps then RefreshSteps() end
    S.listTitle:SetText("EQUIPO INICIAL")
    S.classTitle:SetText("Equipo inicial")
    S.classSummary:SetText("Elige una opcion de cada grupo. Donde el manual dice una categoria, "
        .. "escoge el arma concreta: es la que se equipara y la que saldra en tu ficha.")
    S.subclassDrop:SetShown(false)
    S.selectorLabel:SetShown(false)
    RefreshOptionCards(nil)

    local y = -34
    local armasPendientes = 0
    for i, grupo in ipairs(EquipmentGroups()) do
        local pick = EquipPick(i)
        local titulo = MakeText(S.tree, "GameFontNormal", string.upper(tostring(grupo.label or "Grupo")))
        titulo:SetPoint("TOPLEFT", 26, y)
        titulo:SetTextColor(1, 0.82, 0)
        S.nodeRows[#S.nodeRows + 1] = titulo
        y = y - 24

        for _, item in ipairs(grupo.fixed or {}) do
            local fijo = MakeText(S.tree, "GameFontHighlightSmall", "- " .. tostring(item))
            fijo:SetPoint("TOPLEFT", 44, y)
            S.nodeRows[#S.nodeRows + 1] = fijo
            y = y - 18
        end

        for j, opcion in ipairs(grupo.options or {}) do
            local marca = (pick.opcion == j) and "[X] " or "[ ] "
            local b = MakeButton(S.tree, marca .. tostring(opcion.label or "?"), 330, 24, function()
                pick.opcion = j
                pick.armas = {}   -- otra opcion, otros huecos: las armas elegidas ya no valen
                RefreshEquipmentStage()
            end)
            b:SetPoint("TOPLEFT", 40, y)
            S.nodeRows[#S.nodeRows + 1] = b
            y = y - 26

            -- Huecos de categoria de la opcion ELEGIDA: un boton por hueco que abre la lista.
            if pick.opcion == j then
                local hueco = 0
                for _, item in ipairs(opcion.items or {}) do
                    if type(item) == "table" and item.pick then
                        hueco = hueco + 1
                        local idx = hueco
                        local actual = pick.armas[idx]
                        if not actual then armasPendientes = armasPendientes + 1 end
                        -- Numerado: "Dos armas marciales" son DOS elecciones y debe verse.
                        local texto = actual or ("Elegir arma " .. tostring(item.pick):lower()
                            .. " (" .. tostring(idx) .. ")")
                        local w = MakeButton(S.tree, texto, 300, 22, function()
                            OpenWeaponPickDialog(item.pick, function(nombre)
                                pick.armas[idx] = nombre
                                RefreshEquipmentStage()
                            end, item.mode)
                        end)
                        w:SetPoint("TOPLEFT", 60, y)
                        S.nodeRows[#S.nodeRows + 1] = w
                        y = y - 24
                    end
                end
            end
        end
        y = y - 8
    end

    S.treeChild:SetHeight(math.max(240, -y + 10))
    -- No se confirma con huecos de arma sin elegir: "Dos armas marciales" son DOS elecciones y
    -- confirmarlas vacias dejaba la ficha sin las armas que el manual promete.
    S.nextButton:SetText(armasPendientes == 0 and "Confirmar equipo"
        or ("Elige " .. armasPendientes .. (armasPendientes == 1 and " arma" or " armas")))
    S.nextButton:SetEnabled(armasPendientes == 0)
    S.nextButton:SetShown(true)
end

local function RollAbilityArray()
    local values, total, odd = {}, 0, 0
    for slot = 1, 6 do
        local dice = { math.random(1, 6), math.random(1, 6), math.random(1, 6), math.random(1, 6) }
        table.sort(dice)
        local value = dice[2] + dice[3] + dice[4]
        values[slot] = value
        total = total + value
        if value % 2 ~= 0 then odd = odd + 1 end
    end
    table.sort(values, function(a, b) return a > b end)
    return { values = values, total = total, odd = odd }
end

local function GenerateAttributeArrays()
    S.attributeArrays = { RollAbilityArray(), RollAbilityArray(), RollAbilityArray() }
    local best = 1
    for index = 2, #S.attributeArrays do
        local candidate, current = S.attributeArrays[index], S.attributeArrays[best]
        if candidate.total > current.total or (candidate.total == current.total and candidate.odd < current.odd) then
            best = index
        end
    end
    S.recommendedArray = best
    S.selectedArray, S.attributeAssignments, S.pendingScore = nil, {}, nil
end

RaceAbilityBonus = function(ability)
    local total = 0
    local function Apply(feature)
        for _, effect in ipairs(feature.effects or {}) do
            if effect.kind == "bonus" and effect.target == "ability" and effect.ability == ability then
                total = total + (tonumber(effect.value) or 0)
            end
        end
        for _, optionId in ipairs(S.choiceSelections[feature.id] or {}) do
            local option = HarfordDnDBook and HarfordDnDBook.GetChoiceOption and HarfordDnDBook.GetChoiceOption(feature, optionId)
            for _, effect in ipairs((option and option.effects) or {}) do
                if effect.kind == "bonus" and effect.target == "ability" and effect.ability == ability then
                    total = total + (tonumber(effect.value) or 0)
                end
            end
        end
    end
    local race = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
    for _, feature in ipairs((race and race.traits) or {}) do Apply(feature) end
    local subrace = HarfordDnDRaces and HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
    for _, feature in ipairs((subrace and subrace.traits) or {}) do Apply(feature) end
    return total
end

-- ─── Compra por puntos (sistema estandar de 5e) ─────────────────────────────────
-- Coste acumulado por puntuacion: de 8 a 13 cuesta 1 punto cada subida y de 14 a 15 cuesta 2.
-- El bono racial NO se compra: se suma despues, por eso el tope de compra es 15.
local POINT_BUY_BUDGET, POINT_MIN, POINT_MAX = 27, 8, 15
local POINT_COST = { [8]=0, [9]=1, [10]=2, [11]=3, [12]=4, [13]=5, [14]=7, [15]=9 }

local function EnsurePointBuy()
    if type(S.pointBuy) ~= "table" then
        S.pointBuy = {}
        for _, ability in ipairs(HarfordDnDData.ABIL or {}) do S.pointBuy[ability.key] = POINT_MIN end
    end
    return S.pointBuy
end

local function PointsSpent()
    local spent = 0
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        spent = spent + (POINT_COST[EnsurePointBuy()[ability.key] or POINT_MIN] or 0)
    end
    return spent
end

-- Puntuacion base elegida por el jugador, sea cual sea el sistema. Sin bono racial: ese lo
-- hornea HarfordCharacterCreation.Apply al aplicar el borrador.
local function BaseScoreFor(abilityKey)
    if S.abilityMode == "points" then return EnsurePointBuy()[abilityKey] or POINT_MIN end
    local array = S.attributeArrays and S.selectedArray and S.attributeArrays[S.selectedArray]
    local assignedIndex = S.attributeAssignments and S.attributeAssignments[abilityKey]
    return (array and assignedIndex and array.values[assignedIndex]) or nil
end

-- Una creacion desde cero sustituye al personaje anterior. El grimorio es una
-- SavedVariablePerCharacter independiente de la progresion, asi que vaciarlo
-- aqui evita que el About mezcle conjuros de una ficha previa con las elecciones
-- del nuevo borrador. Las subidas de nivel solo anaden elecciones y no pasan por
-- esta funcion.
local function ResetCreationSpellState()
    local db = _G.HarfordCompendioCharacterDB
    if type(db) ~= "table" then return end
    db.knownSpells = {}
    db.wizardBook = {}
    db.preparedSpells = {}
end

-- Modificador D&D coloreado: verde si es bonificador, rojo si es penalizador, gris en 0.
local function ModifierText(mod)
    local color = mod > 0 and "38d26a" or (mod < 0 and "ff5555" or "aaaaaa")
    return string.format("|cff%s(%+d)|r", color, mod)
end

local function RefreshAttributes()
    if RefreshSteps then RefreshSteps() end
    ClearRows()
    S.originScroll:Hide()
    S.originSlider:Hide()
    -- Venir desde la seccion Clase dejaba sus botones pintados encima
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    for _, button in ipairs(S.classMetaButtons or {}) do button:Hide() end
    S.subclassDrop:Hide()
    S.selectorLabel:Hide()
    RefreshOptionCards(nil)
    S.listTitle:SetText("CARACTERISTICAS")
    S.classTitle:SetText("Caracteristicas")
    S.classSummary:SetText("Tres arrays de 4d6, descartando el dado menor de cada caracteristica.")
    SetDetail(nil)
    S.abilityMode = S.abilityMode or "points"
    S.classSummary:SetText(S.abilityMode == "points"
        and "Compra por puntos: 27 a repartir. De 8 a 13 cuesta 1 por subida; 14 y 15 cuestan 2."
        or "Tres arrays de 4d6, descartando el dado menor de cada caracteristica.")

    -- Selector de sistema. Cambiarlo no borra lo del otro: cada uno conserva su estado.
    for index, mode in ipairs({ { "points", "Compra por puntos" }, { "roll", "Tirada 4d6" } }) do
        local modeId, modeLabel = mode[1], mode[2]
        local tab = MakeButton(S.tree, modeLabel, 168, 22, function()
            S.abilityMode = modeId
            RefreshAttributes()
        end)
        tab:SetPoint("TOPLEFT", 6 + (index - 1) * 174, -2)
        if S.abilityMode == modeId then tab:LockHighlight() else tab:UnlockHighlight() end
        S.nodeRows[#S.nodeRows + 1] = tab
    end

    if S.abilityMode == "points" then
        EnsurePointBuy()
        local spent = PointsSpent()
        local remaining = POINT_BUY_BUDGET - spent
        local py = -34
        for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
            local key = ability.key
            local score = S.pointBuy[key] or POINT_MIN
            local bonus = RaceAbilityBonus(key)
            -- Columna de nombres a la izquierda del todo con sitio completo (Inteligencia
            -- y Constitucion se cortaban con los botones encima)
            local name = MakeText(S.tree, "GameFontHighlight", key)
            name:SetPoint("TOPLEFT", 6, py - 4)
            S.nodeRows[#S.nodeRows + 1] = name

            local down = MakeButton(S.tree, "-", 24, 22, function()
                if (S.pointBuy[key] or POINT_MIN) > POINT_MIN then
                    S.pointBuy[key] = S.pointBuy[key] - 1
                    RefreshAttributes()
                end
            end)
            down:SetPoint("TOPLEFT", 100, py)
            down:SetEnabled(score > POINT_MIN)
            S.nodeRows[#S.nodeRows + 1] = down

            local value = MakeText(S.tree, "GameFontNormalLarge", tostring(score))
            value:SetPoint("TOPLEFT", 132, py - 2)
            S.nodeRows[#S.nodeRows + 1] = value

            -- Solo se puede subir si queda presupuesto para el SIGUIENTE escalon (14 y 15 cuestan 2).
            local nextCost = (POINT_COST[score + 1] or 99) - (POINT_COST[score] or 0)
            local canRaise = score < POINT_MAX and nextCost <= remaining
            local up = MakeButton(S.tree, "+", 24, 22, function()
                S.pointBuy[key] = math.min(POINT_MAX, (S.pointBuy[key] or POINT_MIN) + 1)
                RefreshAttributes()
            end)
            up:SetPoint("TOPLEFT", 162, py)
            up:SetEnabled(canRaise)
            S.nodeRows[#S.nodeRows + 1] = up

            -- Racial en blanco (no verde) + total en oro + bonificador/penalizador D&D
            local final = score + bonus
            local mod = math.floor((final - 10) / 2)
            local totalText
            if bonus ~= 0 then
                totalText = string.format("|cffffffff%+d|r = |cffffd100%d|r ", bonus, final) .. ModifierText(mod)
            else
                totalText = string.format("= |cffffd100%d|r ", final) .. ModifierText(mod)
            end
            local total = MakeText(S.tree, "GameFontHighlightSmall", totalText)
            total:SetPoint("TOPLEFT", 196, py - 4)
            S.nodeRows[#S.nodeRows + 1] = total
            py = py - 30
        end
        local counter = MakeText(S.tree, "GameFontNormal", string.format("Puntos: %d/%d", spent, POINT_BUY_BUDGET))
        counter:SetPoint("TOPLEFT", 6, py - 6)
        counter:SetTextColor(remaining == 0 and 0.22 or 1, remaining == 0 and 0.82 or 0.82, remaining == 0 and 0.42 or 0)
        S.nodeRows[#S.nodeRows + 1] = counter

        S.nextButton:SetText(remaining == 0 and "Confirmar caracteristicas"
            or string.format("Reparte %d puntos", remaining))
        S.nextButton:SetEnabled(remaining == 0)
        S.nextButton:SetShown(true)
        S.treeChild:SetHeight(math.max(420, -py + 60))
        SetManualScroll(S.treeScroll, S.treeChild, 0)
        return
    end

    if not S.attributeArrays then
        local intro = MakeText(S.tree, "GameFontHighlight", "Genera tres arrays y elige uno. El recomendado tiene mayor total; en empate, menos valores impares.")
        intro:SetPoint("TOPLEFT", 24, -34)
        intro:SetWidth(340)
        intro:SetJustifyH("LEFT")
        intro:SetNonSpaceWrap(false)
        S.nodeRows[#S.nodeRows + 1] = intro
        local roll = MakeButton(S.tree, "Generar 3 arrays", 190, 28, function()
            GenerateAttributeArrays()
            RefreshAttributes()
        end)
        roll:SetPoint("TOPLEFT", 24, -100)
        S.nodeRows[#S.nodeRows + 1] = roll
        S.nextButton:Hide()
        return
    end
    local heading = MakeText(S.tree, "GameFontNormal", "ELIGE UN ARRAY")
    heading:SetPoint("TOPLEFT", 24, -28)
    heading:SetTextColor(1, 0.82, 0)
    S.nodeRows[#S.nodeRows + 1] = heading
    local y = -56
    for index, array in ipairs(S.attributeArrays) do
        local values = table.concat(array.values, "  ")
        local card = CreateFrame("Frame", nil, S.tree)
        card:SetSize(350, 32)
        card:SetPoint("TOPLEFT", 20, y)
        local background = card:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(card)
        background:SetColorTexture(0.025, 0.024, 0.02, 0.92)
        local select = MakeButton(card, tostring(index), 30, 26, function()
            S.selectedArray, S.attributeAssignments, S.pendingScore = index, {}, nil
            RefreshAttributes()
        end)
        select:SetPoint("LEFT", 3, 0)
        if S.selectedArray == index then select:LockHighlight() end
        local valuesText = MakeText(card, "GameFontHighlight", values)
        valuesText:SetPoint("LEFT", select, "RIGHT", 12, 0)
        local totalText = MakeText(card, "GameFontNormalSmall", "Total " .. tostring(array.total))
        totalText:SetPoint("RIGHT", card, "RIGHT", index == S.recommendedArray and -108 or -12, 0)
        if index == S.recommendedArray then
            local recommended = MakeText(card, "GameFontNormalSmall", "RECOMENDADO")
            recommended:SetPoint("RIGHT", card, "RIGHT", -12, 0)
            recommended:SetTextColor(0.22, 0.82, 0.42)
        end
        S.nodeRows[#S.nodeRows + 1] = card
        y = y - 38
    end
    if S.selectedArray then
        local array = S.attributeArrays[S.selectedArray]
        local valuesHeading = MakeText(S.tree, "GameFontNormal", "VALOR ACTIVO: ELIGE UN DADO Y ASIGNALO")
        valuesHeading:SetPoint("TOPLEFT", 24, y - 6)
        valuesHeading:SetTextColor(1, 0.82, 0)
        S.nodeRows[#S.nodeRows + 1] = valuesHeading
        y = y - 34
        for index, value in ipairs(array.values) do
            local used = false
            for _, assignedIndex in pairs(S.attributeAssignments) do if assignedIndex == index then used = true end end
            local score = MakeButton(S.tree, tostring(value), 48, 24, function()
                if not used then S.pendingScore = index; RefreshAttributes() end
            end)
            score:SetPoint("TOPLEFT", 22 + (index - 1) * 56, y)
            score:SetEnabled(not used)
            if S.pendingScore == index then score:LockHighlight() end
            S.nodeRows[#S.nodeRows + 1] = score
        end
        y = y - 42
        -- Filas compactas con el MISMO layout que la compra por puntos: nombre a la
        -- izquierda, hueco de valor clicable (asigna el dado activo) y racial/total/mod.
        for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
            local key = ability.key
            local assignedIndex = S.attributeAssignments[key]
            local base = assignedIndex and array.values[assignedIndex] or nil
            local bonus = RaceAbilityBonus(key)

            local name = MakeText(S.tree, "GameFontHighlight", key)
            name:SetPoint("TOPLEFT", 6, y - 4)
            S.nodeRows[#S.nodeRows + 1] = name

            local slot = MakeButton(S.tree, base and tostring(base) or "-", 48, 22, function()
                if S.pendingScore then
                    for otherKey, scoreIndex in pairs(S.attributeAssignments) do
                        if scoreIndex == S.pendingScore then S.attributeAssignments[otherKey] = nil end
                    end
                    S.attributeAssignments[key] = S.pendingScore
                    S.pendingScore = nil
                    RefreshAttributes()
                end
            end)
            slot:SetPoint("TOPLEFT", 108, y)
            S.nodeRows[#S.nodeRows + 1] = slot

            local info
            if base then
                local final = base + bonus
                local mod = math.floor((final - 10) / 2)
                if bonus ~= 0 then
                    info = string.format("|cffffffff%+d|r = |cffffd100%d|r ", bonus, final) .. ModifierText(mod)
                else
                    info = string.format("= |cffffd100%d|r ", final) .. ModifierText(mod)
                end
            elseif bonus ~= 0 then
                -- Sin dado asignado: el incremento racial se anuncia "por fuera", en verde
                info = string.format("|cff38d26a%+d|r", bonus)
            end
            if info then
                local total = MakeText(S.tree, "GameFontHighlightSmall", info)
                total:SetPoint("TOPLEFT", 196, y - 4)
                S.nodeRows[#S.nodeRows + 1] = total
            end
            y = y - 30
        end
        -- El Reiniciar vive FUERA del scroll (S.attrResetButton, junto a Confirmar): dentro
        -- quedaba bajo el borde visible.
        local assigned = 0
        for _ in pairs(S.attributeAssignments) do assigned = assigned + 1 end
        S.nextButton:SetText(assigned == 6 and "Confirmar caracteristicas" or "Asigna " .. tostring(6 - assigned) .. " valores")
        S.nextButton:SetEnabled(assigned == 6)
        S.nextButton:SetShown(true)
    else
        S.nextButton:Hide()
    end
    S.treeChild:SetHeight(math.max(420, -y + 16))
    SetManualScroll(S.treeScroll, S.treeChild, 0)
end

local function CreateChoiceDialog()
    if S.choiceDialog then return S.choiceDialog end
    local dialog = CreateFrame("Frame", nil, S.frame, "BasicFrameTemplateWithInset")
    dialog:SetSize(440, 450)
    dialog:SetPoint("CENTER", S.frame, "CENTER", 0, 0)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel(S.frame:GetFrameLevel() + 30)
    dialog:Hide()
    dialog.TitleText:SetText("Elegir opcion")
    dialog.description = MakeText(dialog, "GameFontHighlightSmall", "")
    dialog.description:SetPoint("TOPLEFT", 20, -46)
    dialog.description:SetWidth(396)
    dialog.description:SetJustifyH("LEFT")
    dialog.description:SetNonSpaceWrap(false)
    dialog.status = MakeText(dialog, "GameFontNormalSmall", "")
    dialog.status:SetPoint("BOTTOMLEFT", 20, 48)
    dialog.status:SetWidth(280)
    dialog.status:SetJustifyH("LEFT")
    -- Debajo del contador, los NOMBRES de lo marcado: con la lista larga y scroll, lo elegido
    -- puede quedar fuera de la vista y el contador solo no dice que hay dentro.
    dialog.selectedNames = MakeText(dialog, "GameFontHighlightSmall", "")
    -- Ocupa el hueco de abajo a la IZQUIERDA de los botones: ancho corto para no tocar
    -- Confirmar, hasta tres lineas y de ahi no pasa (elipsis).
    dialog.selectedNames:SetPoint("BOTTOMLEFT", 20, 12)
    dialog.selectedNames:SetWidth(190)
    dialog.selectedNames:SetJustifyH("LEFT")
    dialog.selectedNames:SetWordWrap(true)
    if dialog.selectedNames.SetMaxLines then dialog.selectedNames:SetMaxLines(3) end
    -- Shadowlands/Epsilon no expone ScrollFrameTemplate; este panel controla
    -- rueda y contenido directamente, asi que no necesita heredar un template.
    local scroll = CreateFrame("ScrollFrame", nil, dialog)
    scroll:SetPoint("TOPLEFT", 18, -100)
    scroll:SetPoint("BOTTOMRIGHT", -30, 76)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(370, 240)
    scroll:SetScrollChild(child)
    SetManualScroll(scroll, child, 0)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, child:GetHeight() - self:GetHeight())
        SetManualScroll(self, child, math.max(0, math.min(range, (self._offset or 0) - delta * 48)))
    end)
    dialog.tree, dialog.treeChild = scroll, child
    dialog.cancel = MakeButton(dialog, "Cancelar", 90, 24, function() dialog:Hide() end)
    dialog.cancel:SetPoint("BOTTOMRIGHT", -16, 16)
    dialog.confirm = MakeButton(dialog, "Confirmar", 100, 24, function()
        dialog:Hide()
        if S.stage == "class" then RefreshClassStage() else RefreshOrigin() end
    end)
    dialog.confirm:SetPoint("BOTTOMRIGHT", dialog.cancel, "BOTTOMLEFT", -8, 0)
    S.choiceDialog = dialog
    return dialog
end

-- ¿Es un rasgo de Estilo de combate? Por nombre, sin acentos ni mayusculas: lo declaran cuatro
-- clases con ids distintos (`gue_estilo`, `pal_estilo`...).
local function EsEstiloDeCombate(feature)
    local nombre = tostring(feature and feature.name or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        nombre = HarfordClassColors.StripAccents(nombre)
    end
    return nombre:lower():find("estilo de combate", 1, true) ~= nil
end

-- Opciones de Estilo de combate ya tomadas en OTRO rasgo del personaje.
--
-- Se juntan los rasgos de las dos fuentes posibles (los ya desbloqueados y los que se estan
-- ganando en este paso) para saber cuales son estilos: no hay un buscador de rasgo por id en el
-- libro, y sin ese mapa las elecciones de la sesion en curso no se podian clasificar.
local function EstilosYaElegidos(featureIdActual)
    local usadas, porId = {}, {}
    local P = HarfordDnDProgression
    for _, item in ipairs((P and P.GetUnlockedFeatures and P.GetUnlockedFeatures()) or {}) do
        if item.feature and item.feature.id then porId[tostring(item.feature.id)] = item.feature end
    end
    for _, f in ipairs(S.pendingFeatures or {}) do
        if f and f.id then porId[tostring(f.id)] = f end
    end

    -- Confirmado en la progresion (p.ej. el estilo del Guerrero al elegir el del Paladin).
    for fid, f in pairs(porId) do
        if fid ~= featureIdActual and EsEstiloDeCombate(f) then
            for _, optId in ipairs((P and P.GetChoice and P.GetChoice(fid)) or {}) do
                usadas[tostring(optId)] = true
            end
        end
    end
    -- Y lo elegido en esta misma sesion del asistente (creacion con dos clases).
    for fid, seleccion in pairs(S.choiceSelections or {}) do
        if fid ~= featureIdActual and EsEstiloDeCombate(porId[tostring(fid)]) then
            for _, optId in ipairs(seleccion or {}) do usadas[tostring(optId)] = true end
        end
    end
    return usadas
end

local function RefreshChoiceDialog()
    local dialog = S.choiceDialog
    if not (dialog and dialog.feature) then return end
    for _, row in ipairs(S.choiceDialogRows or {}) do row:Hide() end
    S.choiceDialogRows = {}
    local feature = dialog.feature
    local options = HarfordDnDBook.GetChoiceOptions(feature) or {}
    -- Pericia: por regla 5e solo puede recaer sobre habilidades en las que YA se es competente.
    -- Aqui la competencia sale del borrador (el PJ todavia no existe como perfil). Si aun no hay
    -- ninguna -- p.ej. se elige la dote antes que raza/trasfondo -- se muestran todas antes que
    -- dejar la lista vacia y bloquear la creacion.
    -- Requisito de nivel de la opcion (maniobras de 6o nivel). Se mide contra el nivel de clase
    -- que se esta asignando, no contra el nivel del rasgo: la eleccion de nivel 3 sigue abierta
    -- cuando el personaje ya es de nivel 6 y entonces si valen.
    do
        local nivelClase = math.max(tonumber(S.primaryLevel) or 0, tonumber(S.secondaryLevel) or 0,
            tonumber(dialog.level) or 0)
        local permitidas = {}
        for _, option in ipairs(options) do
            local req = tonumber(option.requiresLevel)
            if not req or nivelClase >= req then permitidas[#permitidas + 1] = option end
        end
        options = permitidas
    end

    -- Estilo de combate: fuera las opciones ya tomadas en OTRO estilo del mismo personaje.
    if EsEstiloDeCombate(feature) then
        local usadas = EstilosYaElegidos(feature.id)
        local libres = {}
        for _, option in ipairs(options) do
            if not usadas[tostring(option.id)] then libres[#libres + 1] = option end
        end
        -- Si no quedara ninguna (no deberia pasar), se muestran todas antes que bloquear.
        if #libres > 0 then options = libres end
    end
    -- LO QUE YA TIENES NO SE VUELVE A OFRECER: idiomas que ya hablas, habilidades en las que ya
    -- eres competente (Conocimiento nomada no debe ofrecer el Sigilo que ya te dio la clase) y
    -- dotes o trucos ya tomados en OTRA eleccion. Lo marcado en ESTA eleccion se excluye del
    -- computo -- debe seguir visible para poder desmarcarse -- y las elecciones apilables
    -- (Mejora de Caracteristica +1/+1) no se filtran: repetir es su gracia. Si no quedara
    -- ninguna opcion (no deberia pasar), se muestran todas antes que bloquear.
    -- DOTES RACIALES: las que tu raza (o subraza) no puede tomar no se ofrecen. La raza sale
    -- del borrador en creacion y de la progresion en subida.
    do
        local razaId, subrazaId = S.raceId, S.subraceId
        if (not razaId or razaId == "") and HarfordDnDProgression and HarfordDnDProgression.GetRace then
            local r = HarfordDnDProgression.GetRace()
            razaId, subrazaId = r and r.id, r and r.subraceId
        end
        if HarfordDnDFeats and HarfordDnDFeats.RaceAllowed and HarfordDnDFeats.GetFeat then
            -- Puntuacion para el prerequisito de caracteristica: en creacion, la asignada MAS el
            -- bono racial (que es la puntuacion final que tendra); en subida, la de la ficha viva.
            local esBorrador = S.raceId and S.raceId ~= ""
            local profsCache  -- se calcula UNA vez por refresco, solo si alguna dote lo pide
            local casterCache -- idem para el prerequisito de lanzador
            local function Puntuacion(clave)
                if esBorrador then
                    local base = BaseScoreFor and tonumber(BaseScoreFor(clave)) or 0
                    local bono = RaceAbilityBonus and tonumber(RaceAbilityBonus(clave)) or 0
                    return base + bono
                end
                return HarfordDnDCalc and HarfordDnDCalc.GetAbilityScore
                    and tonumber(HarfordDnDCalc.GetAbilityScore(clave)) or 0
            end
            local permitidas = {}
            for _, option in ipairs(options) do
                local ok = true
                if option.feat then
                    local def = HarfordDnDFeats.GetFeat(option.feat)
                    ok = HarfordDnDFeats.RaceAllowed(def, razaId, subrazaId)
                    if ok and def and def.requiredAbility and HarfordDnDFeats.AbilityAllowed then
                        ok = HarfordDnDFeats.AbilityAllowed(def, Puntuacion)
                    end
                    if ok and def and def.requiredCaster and HarfordDnDFeats.CasterAllowed then
                        if not casterCache and Draft.DraftCasterInfo then
                            casterCache = Draft.DraftCasterInfo(feature.id)
                        end
                        ok = HarfordDnDFeats.CasterAllowed(def, casterCache or {})
                    end
                    if ok and def and def.requiredProficiency and HarfordDnDFeats.ProficiencyAllowed then
                        if not profsCache then
                            if esBorrador and Draft.DraftEquipProficiencies then
                                profsCache = Draft.DraftEquipProficiencies(feature.id)
                            elseif HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.Resolve then
                                local r = HarfordDnDFeatureEffects.Resolve()
                                profsCache = { armor = r.armorProf or {}, weapon = r.weaponProf or {} }
                            else
                                profsCache = { armor = {}, weapon = {} }
                            end
                        end
                        ok = HarfordDnDFeats.ProficiencyAllowed(def, profsCache)
                    end
                end
                if ok then permitidas[#permitidas + 1] = option end
            end
            if #permitidas > 0 then options = permitidas end
        end
    end
    if not IsStackableChoice(feature) and Draft.DraftLanguages and Draft.DraftSkillProficiencies then
        local idiomas = Draft.DraftLanguages(feature.id)
        local habilidades = Draft.DraftSkillProficiencies(feature.id)
        local elegidosOtra = {}
        for fid, lista in pairs(S.choiceSelections or {}) do
            if fid ~= feature.id then
                for _, oid in ipairs(lista) do elegidosOtra[tostring(oid)] = true end
            end
        end
        local function Normaliza(nombre)
            nombre = tostring(nombre or "")
            if HarfordClassColors and HarfordClassColors.StripAccents then
                nombre = HarfordClassColors.StripAccents(nombre)
            end
            return nombre:lower()
        end
        local nuevas = {}
        for _, option in ipairs(options) do
            local repetida = false
            for _, e in ipairs(option.effects or {}) do
                if e.kind == "language" and e.language and idiomas[Normaliza(e.language)] then repetida = true end
                if e.kind == "skillProf" and e.skill and habilidades[e.skill] then repetida = true end
            end
            -- Dotes y trucos: el MISMO id tomado en otra eleccion no se repite. Solo ellos: un
            -- id generico ("defensa") puede ser legitimo en dos elecciones distintas y los
            -- estilos ya tienen su propio filtro.
            local id = tostring(option.id or "")
            if (option.feat or id:find("^truco_")) and elegidosOtra[id] then repetida = true end
            if not repetida then nuevas[#nuevas + 1] = option end
        end
        if #nuevas > 0 then options = nuevas end
    end
    if tostring(feature.choice and feature.choice.optionsFrom or "") == "skillExpertise" then
        local prof = Draft.DraftSkillProficiencies()
        local eligible = {}
        for _, option in ipairs(options) do
            if prof[option.id] then eligible[#eligible + 1] = option end
        end
        if #eligible > 0 then options = eligible end
    end
    local slots = HarfordDnDBook.GetChoiceSlots(feature)
    local selected = S.choiceSelections[feature.id] or {}
    S.choiceSelections[feature.id] = selected
    -- Una dote OCUPA la mejora entera: mientras este elegida solo hay un hueco que llenar.
    local function EsDote(optionId)
        local o = HarfordDnDBook.GetChoiceOption and HarfordDnDBook.GetChoiceOption(feature, optionId)
        return o and o.feat ~= nil
    end
    local doteElegida = false
    for _, id in ipairs(selected) do if EsDote(id) then doteElegida = true break end end
    if doteElegida then slots = 1 end
    dialog.TitleText:SetText("Elegir: " .. tostring(feature.name or "Rasgo"))
    dialog.description:SetText(tostring(feature.description or "") .. "\n\nElige " .. tostring(slots) .. ".")
    dialog.status:SetText("Seleccionadas: " .. tostring(#selected) .. "/" .. tostring(slots))
    if dialog.selectedNames then
        local nombres = {}
        for _, id in ipairs(selected) do
            local o = HarfordDnDBook.GetChoiceOption and HarfordDnDBook.GetChoiceOption(feature, id)
            nombres[#nombres + 1] = tostring((o and (o.label or o.name)) or id)
        end
        dialog.selectedNames:SetText(table.concat(nombres, ", "))
    end
    dialog.status:SetTextColor(#selected == slots and 0.22 or 1, #selected == slots and 0.82 or 0.78, #selected == slots and 0.42 or 0.2)
    dialog.confirm:SetEnabled(#selected == slots)
    local stackable = IsStackableChoice(feature)
    local y = 0
    for _, option in ipairs(options) do
        local choice = option
        local count = CountChoice(selected, choice.id)
        local mark = (count == 0 and "[ ] ") or (count == 1 and "[X] ") or ("[X" .. count .. "] ")
        local row = MakeButton(dialog.treeChild, mark .. tostring(choice.label or choice.id), 350, 25, function()
            -- Dote y caracteristicas son excluyentes entre si: elegir una limpia la otra.
            if choice.feat then
                if ContainsChoice(selected, choice.id) then
                    wipe(selected)
                else
                    wipe(selected)
                    selected[1] = choice.id
                end
                RefreshChoiceDialog()
                return
            elseif doteElegida then
                wipe(selected)
            end
            if stackable then
                -- Repetible: cada click suma una copia; sin slots libres, un click sobre una ya
                -- elegida la libera entera (asi se puede pasar de "+2 a una" a "+1 y +1").
                if #selected < slots then
                    selected[#selected + 1] = choice.id
                elseif count > 0 then
                    for i = #selected, 1, -1 do
                        if selected[i] == choice.id then table.remove(selected, i) end
                    end
                else
                    dialog.status:SetText("Ya has elegido el maximo de opciones.")
                    return
                end
            else
                local index = ContainsChoice(selected, choice.id)
                if index then
                    table.remove(selected, index)
                elseif #selected < slots then
                    selected[#selected + 1] = choice.id
                else
                    dialog.status:SetText("Ya has elegido el maximo de opciones.")
                    return
                end
            end
            RefreshChoiceDialog()
        end)
        row:SetPoint("TOPLEFT", 4, y)
        -- Un CONJURO como opcion se presenta como en el compendio: icono a la izquierda y
        -- tooltip con escuela y descripcion, para poder leer que es antes de elegirlo. El resto
        -- de opciones ganan tooltip con su desc si la tienen.
        local spell = choice.spellId and _G.HarfordCompendioAPI
            and _G.HarfordCompendioAPI.GetSpellById
            and _G.HarfordCompendioAPI.GetSpellById(choice.spellId) or nil
        if spell then
            local icono = row:CreateTexture(nil, "ARTWORK")
            icono:SetSize(20, 20)
            icono:SetPoint("LEFT", row, "LEFT", 5, 0)
            icono:SetTexCoord(0.06, 0.94, 0.06, 0.94)
            local api = _G.HarfordCompendioAPI
            icono:SetTexture((api.GetSpellIcon and api.GetSpellIcon(spell)) or spell.icon or 134400)
        end
        row:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            if spell then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(spell.name or "?", 1, 0.82, 0)
                local nivel = tonumber(spell.level) or 0
                GameTooltip:AddLine((nivel == 0 and "Truco" or ("Nivel " .. nivel))
                    .. "  -  " .. (spell.school or "-"), 0.8, 0.8, 0.8)
                if spell.description and spell.description ~= "" then
                    GameTooltip:AddLine(spell.description, 1, 1, 1, true)
                end
                GameTooltip:Show()
            elseif choice.desc or choice.description then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tostring(choice.label or choice.id), 1, 0.82, 0)
                GameTooltip:AddLine(tostring(choice.desc or choice.description), 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        S.choiceDialogRows[#S.choiceDialogRows + 1] = row
        y = y - 29
    end
    dialog.treeChild:SetHeight(math.max(240, -y + 4))
    SetManualScroll(dialog.tree, dialog.treeChild, 0)
end

OpenChoiceDialog = function(feature, level, source)
    local dialog = CreateChoiceDialog()
    dialog.feature, dialog.level, dialog.source = feature, level, source
    RefreshChoiceDialog()
    dialog:Show()
end

-- Elegir un arma concreta de una categoria ("Marcial", "Simple"...). `alElegir` recibe el nombre.
OpenWeaponPickDialog = function(categoria, alElegir, modo)
    local dialog = CreateChoiceDialog()
    for _, row in ipairs(S.choiceDialogRows or {}) do row:Hide() end
    S.choiceDialogRows = {}
    dialog.feature = nil
    dialog.TitleText:SetText("Elegir arma: " .. tostring(categoria))
    dialog.description:SetText("Escoge el arma concreta que llevaras.")
    dialog.status:SetText("")
    dialog.confirm:SetEnabled(false)

    local armas = (HarfordCharacterCreation and HarfordCharacterCreation.WeaponsByCategory
        and HarfordCharacterCreation.WeaponsByCategory(categoria, modo)) or {}
    local y = 0
    for _, nombre in ipairs(armas) do
        local fila = MakeButton(dialog.treeChild, tostring(nombre), 350, 25, function()
            dialog:Hide()
            if alElegir then alElegir(nombre) end
        end)
        fila:SetPoint("TOPLEFT", 4, y)
        S.choiceDialogRows[#S.choiceDialogRows + 1] = fila
        y = y - 29
    end
    dialog.treeChild:SetHeight(math.max(240, -y + 4))
    SetManualScroll(dialog.tree, dialog.treeChild, 0)
    dialog:Show()
end

-- ============================ SELECTOR DE CONJUROS ============================
-- Picker reutilizable (creacion y descanso largo). Modal con filas toggle + contador, como el de
-- elecciones. `S.spellPicks` guarda las selecciones del PJ que se creara: cantrips/spells/prepared.
local function EnsureSpellPicks()
    if type(S.spellPicks) ~= "table" then
        S.spellPicks = { cantrips = {}, spells = {}, prepared = {} }
    end
    return S.spellPicks
end

-- Conjuros de una clase filtrados por tipo ("cantrip" = nivel 0; "spell" = nivel 1..maxLevel).
-- `extraNames` son las Listas Ampliadas de Conjuros de la subclase: nombres del COMPENDIO que se
-- suman a la lista de la clase aunque el conjuro no la incluya entre sus `classes`.
-- `className` es la lista base; `subclassClassName`, cuando existe, es una lista propia
-- declarada directamente en el Compendio (ej. "Picaro Sutileza"). Ambas se UNEN, junto a
-- `extraNames` del Libro: una subclase nunca debe ocultar los conjuros de su clase madre.
SpellsForClass = function(className, kind, maxLevel, extraNames, subclassClassName)
    local C = _G.HarfordCompendioAPI
    if not (C and C.GetAllSpells) then return {} end
    local out = {}
    for _, spell in ipairs(C.GetAllSpells() or {}) do
        local lvl = tonumber(spell.level) or 0
        local classes = spell.classes or {}
        local match = false
        for _, cn in ipairs(classes) do
            if cn == className or (subclassClassName and cn == subclassClassName) then
                match = true
                break
            end
        end
        if (not match) and extraNames and extraNames[tostring(spell.name or "")] then match = true end
        if match then
            if kind == "cantrip" and lvl == 0 then out[#out + 1] = spell
            elseif kind == "spell" and lvl >= 1 and lvl <= (maxLevel or 9) then out[#out + 1] = spell end
        end
    end
    table.sort(out, function(a, b)
        if (a.level or 0) == (b.level or 0) then return tostring(a.name or "") < tostring(b.name or "") end
        return (a.level or 0) < (b.level or 0)
    end)
    return out
end

local RefreshSpellDialog
local function CreateSpellDialog()
    if S.spellDialog then return S.spellDialog end
    -- Parent robusto: el picker se usa tambien standalone (menu de descanso largo) sin el frame de
    -- creacion abierto; en ese caso cuelga de UIParent.
    local anchor = S.frame or UIParent
    local dialog = CreateFrame("Frame", nil, anchor, "BasicFrameTemplateWithInset")
    dialog:SetSize(460, 500)
    dialog:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetFrameLevel((anchor.GetFrameLevel and anchor:GetFrameLevel() or 0) + 30)
    dialog:Hide()
    dialog.TitleText:SetText("Elegir conjuros")
    dialog.status = MakeText(dialog, "GameFontNormalSmall", "")
    dialog.status:SetPoint("TOPLEFT", 20, -40)
    dialog.status:SetWidth(410)
    dialog.status:SetJustifyH("LEFT")
    local scroll = CreateFrame("ScrollFrame", nil, dialog)
    scroll:SetPoint("TOPLEFT", 18, -64)
    scroll:SetPoint("BOTTOMRIGHT", -30, 52)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(392, 240)
    scroll:SetScrollChild(child)
    SetManualScroll(scroll, child, 0)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, child:GetHeight() - self:GetHeight())
        SetManualScroll(self, child, math.max(0, math.min(range, (self._offset or 0) - delta * 48)))
    end)
    dialog.tree, dialog.treeChild = scroll, child
    dialog.close = MakeButton(dialog, "Hecho", 100, 24, function() dialog:Hide()
        if S.stage == "class" then RefreshClassStage() end
        if dialog.onClose then dialog.onClose() end
    end)
    dialog.close:SetPoint("BOTTOMRIGHT", -16, 14)
    S.spellDialog = dialog
    return dialog
end

RefreshSpellDialog = function()
    local dialog = S.spellDialog
    if not (dialog and dialog.store) then return end
    for _, row in ipairs(S.spellDialogRows or {}) do row:Hide() end
    S.spellDialogRows = {}
    local store, limit = dialog.store, dialog.limit
    local count = 0
    for _ in pairs(store) do count = count + 1 end
    dialog.status:SetText("Seleccionados: " .. count .. "/" .. tostring(limit) .. "   (" .. tostring(dialog.subtitle or "") .. ")")
    dialog.status:SetTextColor(count >= limit and 0.22 or 1, count >= limit and 0.82 or 0.78, count >= limit and 0.42 or 0.2)
    local y = 0
    for _, spell in ipairs(dialog.spells or {}) do
        local sp = spell
        local marked = store[sp.id] == true
        local label = (marked and "|cff33ff33[X]|r " or "[ ] ") .. tostring(sp.name or sp.id)
            .. (sp.level and sp.level > 0 and ("  |cff888888(Nv " .. sp.level .. ")|r") or "")
        local row = MakeButton(dialog.treeChild, label, 372, 24, function()
            if store[sp.id] then
                store[sp.id] = nil
            elseif count < limit then
                store[sp.id] = true
            else
                return
            end
            RefreshSpellDialog()
        end)
        row:SetPoint("TOPLEFT", 4, y)
        -- El selector de conjuros es una vista del Compendio, no una lista de texto plana:
        -- usa su resolvedor de iconos (TRP3/Epsilon) y expone la descripcion canonica al pasar.
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        local compendio = _G.HarfordCompendioAPI
        icon:SetTexture((compendio and compendio.GetSpellIcon and compendio.GetSpellIcon(sp))
            or sp.icon or "Interface\\Icons\\INV_Misc_Book_09")
        local text = row.GetFontString and row:GetFontString()
        if text then
            text:ClearAllPoints()
            text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            text:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            text:SetJustifyH("LEFT")
        end
        row:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tostring(sp.name or sp.id or "Conjuro"), 1, 0.82, 0)
            local level = tonumber(sp.level) or 0
            GameTooltip:AddLine((level == 0 and "Truco" or ("Nivel " .. tostring(level)))
                .. " - " .. tostring(sp.school or "Sin escuela"), 0.8, 0.8, 0.8)
            local description = tostring(sp.description or sp.mechanics or "")
            if description ~= "" then GameTooltip:AddLine(description, 1, 1, 1, true) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        S.spellDialogRows[#S.spellDialogRows + 1] = row
        y = y - 28
    end
    dialog.treeChild:SetHeight(math.max(240, -y + 4))
    SetManualScroll(dialog.tree, dialog.treeChild, 0)
end

-- Abre el picker. store = tabla {spellId=true}; limit = maximo; kind = "cantrip"/"spell"/"prepared".
local function OpenSpellDialog(className, store, limit, kind, maxLevel, subtitle, title, onClose, extraNames, subclassClassName)
    local dialog = CreateSpellDialog()
    dialog.store, dialog.limit, dialog.subtitle, dialog.onClose = store, tonumber(limit) or 0, subtitle, onClose
    dialog.spells = SpellsForClass(className, kind == "cantrip" and "cantrip" or "spell", maxLevel, extraNames, subclassClassName)
    dialog.TitleText:SetText(title or ("Conjuros de " .. tostring(className)))
    RefreshSpellDialog()
    dialog:Show()
end
_G.HarfordAdvancementOpenSpellDialog = OpenSpellDialog  -- reutilizado por el menu de descanso largo

-- Menu de descanso largo: reelegir conjuros PREPARADOS del PJ actual. Standalone (no depende del
-- frame de creacion): opera directamente sobre HarfordCompendioCharacterDB.preparedSpells y usa el
-- Mod real de HarfordDnDCalc. `silent` evita el aviso cuando se dispara automatico tras el descanso.
local function OpenPrepareSpellsMenu(silent)
    local C = _G.HarfordCompendioAPI
    local P = HarfordDnDProgression
    if not (C and P and P.GetClassLevels and HarfordDnDBook) then return end
    local className, classLevel, casting
    for _, e in ipairs(P.GetClassLevels() or {}) do
        local cls = HarfordDnDBook.GetClass(e.classId)
        local name = cls and cls.name
        local cast = name and C.GetClassCasting and C.GetClassCasting(name)
        if not cast and name then
            local sub = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(e.classId, e.subclassId)
            if sub and C.GetClassCasting then
                local combo = name .. " " .. sub.name
                if C.GetClassCasting(combo) then cast, name = C.GetClassCasting(combo), combo end
            end
        end
        local prog = name and C.GetSpellProgression and C.GetSpellProgression(name)
        if cast and prog and prog.prepared then
            className, classLevel, casting = name, tonumber(e.level) or 1, cast
            break
        end
    end
    if not className then
        if not silent and HarfordChat and HarfordChat.Print then HarfordChat.Print("Tu personaje no prepara conjuros.") end
        return
    end
    local mod = (HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod(casting.ability)) or 0
    local limit = (C.GetPreparedCount and C.GetPreparedCount(className, mod, classLevel)) or 1
    local maxLevel = (C.GetMaxSpellLevel and C.GetMaxSpellLevel(className, classLevel))
        or math.max(1, math.min(5, math.ceil((classLevel or 1) / 2)))
    local db = _G.HarfordCompendioCharacterDB
    if type(db) ~= "table" then return end
    db.preparedSpells = db.preparedSpells or {}
    OpenSpellDialog(className, db.preparedSpells, limit, "spell", maxLevel, "preparados",
        "Descanso largo - Preparar conjuros de " .. className, function()
            if HarfordChat and HarfordChat.Print then HarfordChat.Print("Conjuros preparados actualizados.") end
        end)
end
_G.HarfordOpenPrepareSpellsMenu = OpenPrepareSpellsMenu

-- Conjuntos de nombres de las Listas Ampliadas de la subclase (Brujo: Afliccion/Demonologia/
-- Destruccion). Devuelve nil si esa subclase no declara ninguna, para no cambiar el filtro.
ExpandedSpellNames = function(classId, subclassId)
    local sub = HarfordDnDBook and HarfordDnDBook.GetSubclass
        and HarfordDnDBook.GetSubclass(classId, subclassId)
    local lista = sub and sub.expandedSpells
    if type(lista) ~= "table" or #lista == 0 then return nil end
    local set = {}
    for _, nombre in ipairs(lista) do set[tostring(nombre)] = true end
    return set
end

-- Dibuja el/los boton(es) de seleccion de conjuros para una clase lanzadora en el paso de nivel.
-- Devuelve la nueva `y`. Limite = TOTAL acumulado al nivel; los preparados usan el calculo Mod+nivel.
AppendSpellPickers = function(classDef, classLevel, y)
    local C = _G.HarfordCompendioAPI
    if not (classDef and C and C.GetClassCasting and C.GetSpellProgression) then return y end
    -- La progresion puede pertenecer a una subclase (p. ej. Chaman Mejora), pero los
    -- conjuros del Compendio estan indexados por su clase BASE. No mezclar ambos nombres:
    -- hacerlo dejaba al creador con una lista parcial o vacia al elegir una subclase.
    local spellClassName = classDef.name
    local castingClassName = spellClassName
    -- La tabla de la SUBCLASE manda sobre la de la clase: Chaman Mejora sustituye la progresion
    -- del Chaman desde N3 (medio lanzador). Antes solo se miraba si la clase base no lanzaba, asi
    -- que una subclase de una clase lanzadora nunca se consultaba.
    local casting
    do
        local subId = classDef.id == S.classId and S.subclassId or S.secondarySubclassId
        local subclass = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, subId)
        if subclass then
            local combo = spellClassName .. " " .. subclass.name
            if C.GetClassCasting(combo) then
                casting, castingClassName = C.GetClassCasting(combo), combo
            end
        end
    end
    casting = casting or C.GetClassCasting(spellClassName)
    if not casting then return y end
    local prog = C.GetSpellProgression(castingClassName)
    if not prog then return y end

    local subIdSel = (classDef.id == S.classId) and S.subclassId or S.secondarySubclassId
    local extraNames = ExpandedSpellNames(classDef.id, subIdSel)
    local picks = EnsureSpellPicks()
    local subclassSpellClassName = castingClassName ~= spellClassName and castingClassName or nil
    -- La llave identifica esta entrada de clase/subclase en una ficha multiclase. Se conserva
    -- para que la poda final use EXACTAMENTE la misma union de listas que vio el jugador.
    local pickerKey = tostring(classDef.id or spellClassName) .. ":" .. tostring(subIdSel or "")
    picks.spellSources = picks.spellSources or {}
    picks.spellSources[pickerKey] = {
        className = spellClassName,
        subclassClassName = subclassSpellClassName,
        extraNames = extraNames,
    }
    local maxLevel = (C.GetMaxSpellLevel and C.GetMaxSpellLevel(castingClassName, classLevel))
        or math.max(1, math.min(5, math.ceil(classLevel / 2)))

    -- Siembra: lo que el personaje YA sabe de ESTA clase entra en el selector, para que se vea
    -- marcado y el contador cuente sobre el total real. Solo una vez por clase y sesion.
    picks.sembradas = picks.sembradas or {}
    if not picks.sembradas[pickerKey] then
        picks.sembradas[pickerKey] = true
        local db = _G.HarfordCompendioCharacterDB
        if type(db) == "table" then
            local function Sembrar(destino, origen, kind)
                if type(origen) ~= "table" then return end
                for _, spell in ipairs(SpellsForClass(spellClassName, kind, 9, extraNames, subclassSpellClassName) or {}) do
                    if origen[spell.id] then destino[spell.id] = true end
                end
            end
            Sembrar(picks.cantrips, db.knownSpells, "cantrip")
            Sembrar(picks.spells, db.knownSpells, "spell")
            Sembrar(picks.spells, db.wizardBook, "spell")
            Sembrar(picks.prepared, db.preparedSpells, "spell")
        end
    end

    -- La cabecera "CONJUROS DE X" solo aparece si hay ALGUN selector debajo: un medio
    -- lanzador a nivel 1 (Paladin, Caballero de la Muerte) ya tiene tabla de lanzamiento
    -- pero aun no lanza nada, y la cabecera sola sugeria conjuros que no existen.
    local headingPuesto = false
    local function PonHeading()
        if headingPuesto then return end
        headingPuesto = true
        local heading = MakeText(S.tree, "GameFontNormal", "CONJUROS DE " .. string.upper(spellClassName))
        heading:SetPoint("TOPLEFT", 26, y)
        heading:SetTextColor(0.4, 0.8, 1)
        S.nodeRows[#S.nodeRows + 1] = heading
        y = y - 30
    end

    local function CountStore(store)
        local n = 0
        for _ in pairs(store) do n = n + 1 end
        return n
    end
    local function AddPickerButton(label, store, limit, kind, title)
        PonHeading()
        local b = MakeButton(S.tree, label .. " (" .. CountStore(store) .. "/" .. limit .. ")", 240, 24, function()
            OpenSpellDialog(spellClassName, store, limit, kind, kind == "cantrip" and 0 or maxLevel,
                label, title, function() RefreshClassStage() end, extraNames, subclassSpellClassName)
        end)
        b:SetPoint("TOPLEFT", 40, y)
        S.nodeRows[#S.nodeRows + 1] = b
        y = y - 28
    end

    local cantripLimit = tonumber(prog.cantrips and prog.cantrips[classLevel]) or 0
    if cantripLimit > 0 then
        AddPickerButton("Trucos", picks.cantrips, cantripLimit, "cantrip", "Trucos de " .. spellClassName)
    end
    -- Botones de conjuro/preparar solo si la clase ya lanza conjuros con nivel (maxLevel > 0).
    if maxLevel > 0 then
        if prog.spells then
            local spellLimit = tonumber(prog.spells[classLevel]) or 0
            if spellLimit > 0 then
                local label = casting.mode == "wizard_book" and "Libro de conjuros" or "Conjuros conocidos"
                AddPickerButton(label, picks.spells, spellLimit, "spell", label .. " - " .. spellClassName)
            end
        elseif prog.prepared then
            -- En CREACION la puntuacion sale del reparto en curso; en una SUBIDA ese estado no
            -- existe (es nil) y hay que leer la caracteristica ya horneada del personaje, o el
            -- modificador salia 0 y el numero de preparados era el que no era.
            local mod
            local array = S.attributeArrays and S.attributeArrays[S.selectedArray]
            local assigned = S.attributeAssignments and S.attributeAssignments[casting.ability]
            if array and assigned then
                local base = array.values[assigned] or 10
                mod = math.floor((base + (RaceAbilityBonus and RaceAbilityBonus(casting.ability) or 0) - 10) / 2)
            elseif HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityScore then
                mod = HarfordDnDCalc.GetAbilityMod(HarfordDnDCalc.GetAbilityScore(casting.ability))
            else
                mod = 0
            end
            local prepLimit = (C.GetPreparedCount and C.GetPreparedCount(castingClassName, mod, classLevel)) or 0
            if prepLimit > 0 then
                -- Se anota para que la poda de preparados solo afecte a las clases que los usan.
                picks.usaPreparados = picks.usaPreparados or {}
                picks.usaPreparados[pickerKey] = true
                AddPickerButton("Preparar conjuros", picks.prepared, prepLimit, "spell", "Preparar - " .. spellClassName)
            end
        end
    end
    return y
end

-- Pasos del asistente en su orden REAL de ejecucion. `stages` son las etapas internas que
-- cubre cada paso; `value` resuelve el texto de lo ya elegido (o "" si aun no toca).
local CREATION_STEPS = {
    { label = "Raza",            stages = { race = true, race_choices = true } },
    { label = "Trasfondo",       stages = { background = true, background_choices = true } },
    { label = "Caracteristicas", stages = { attributes = true } },
    { label = "Clase",           stages = { class = true } },
    { label = "Equipo",          stages = { equipment = true } },
}

local function StepValue(index)
    if index == 1 then
        local race = S.raceId and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
        if not race then return "" end
        local sub = S.subraceId ~= "" and HarfordDnDRaces.GetSubrace
            and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
        if not sub then return tostring(race.name or "") end
        return tostring(race.name or "") .. string.char(10) .. tostring(sub.name or "")
    elseif index == 2 then
        local bg = S.backgroundId and HarfordDnDBackgrounds.GetBackground
            and HarfordDnDBackgrounds.GetBackground(S.backgroundId)
        return bg and tostring(bg.name or "") or ""
    elseif index == 3 then
        if S.abilityMode == "points" then
            return string.format("%d/%d puntos", PointsSpent(), POINT_BUY_BUDGET)
        end
        if not S.selectedArray then return "" end
        local assigned = 0
        for _ in pairs(S.attributeAssignments or {}) do assigned = assigned + 1 end
        return string.format("%d/6 asignadas", assigned)
    end
    local class = S.classId and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
    if not class then return "" end
    return string.format("%s (%d)", tostring(class.name or ""), S.primaryLevel or 0)
end

-- Pinta la barra: el paso actual en dorado, los ya cerrados con marca y su eleccion.
-- Rellena el panel derecho con lo elegido hasta ahora. Las caracteristicas muestran la
-- puntuacion asignada mas el bono racial ya sumado, igual que la pantalla de reparto, para que
-- el numero coincida con el que acabara horneado en la ficha.
local function RefreshSummary()
    if not S.sumClass then return end
    local class = S.classId and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
    S.sumClass:SetText(class
        and string.format("Nivel %d  %s", S.primaryLevel or 0, tostring(class.name or ""))
        or "Clase sin elegir")
    local race = S.raceId and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
    local sub = S.subraceId ~= "" and HarfordDnDRaces.GetSubrace
        and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
    local bg = S.backgroundId and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(S.backgroundId)
    local origin = race and tostring(race.name or "") or "Sin raza"
    if sub then origin = origin .. " (" .. tostring(sub.name or "") .. ")" end
    if bg then origin = origin .. "  |cffcccccc" .. tostring(bg.name or "") .. "|r" end
    S.sumOrigin:SetText(origin)

    for index, ability in ipairs(HarfordDnDData.ABIL or {}) do
        local text = S.sumAbilities[index]
        if text then
            local base = BaseScoreFor(ability.key)
            local total = base and (base + RaceAbilityBonus(ability.key))
            text:SetText(string.format("|cffcccccc%s|r %s", tostring(ability.key),
                total and ("|cffffd100" .. tostring(total) .. "|r") or "-"))
        end
    end

    local skills = {}
    for skillId in pairs(Draft.DraftSkillProficiencies()) do skills[#skills + 1] = skillId end
    table.sort(skills)
    S.sumSkills:SetText(#skills > 0
        and ("|cffffd100Competencias|r  " .. table.concat(skills, ", "))
        or "|cffffd100Competencias|r  -")
end

-- Elecciones completas de un conjunto de rasgos (raza/trasfondo)
local function TraitListChoicesComplete(traits)
    for _, feature in ipairs(traits or {}) do
        if feature.choice then
            local selected = S.choiceSelections[feature.id] or {}
            local slots = HarfordDnDBook.GetChoiceSlots and HarfordDnDBook.GetChoiceSlots(feature) or 1
            if #selected < slots then return false end
        end
    end
    return true
end

-- Un paso esta COMPLETO por sus datos reales, no por haber pasado de largo:
-- raza/trasfondo con elecciones resueltas, puntos repartidos, niveles asignados.
local function StepDone(index)
    local confirmed = S.confirmedSteps or {}
    if index == 1 and not IsLevelUpMode() and not confirmed.race then return false end
    if index == 2 and not IsLevelUpMode() and not confirmed.background then return false end
    if index == 3 and not IsLevelUpMode() and not confirmed.attributes then return false end
    if index == 1 then
        local race = S.raceId and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
        if not race then return false end
        if HasSubraces(race) and not AllowsBaseRace(race) and (not S.subraceId or S.subraceId == "") then return false end
        local traits = {}
        for _, f in ipairs(race.traits or {}) do traits[#traits + 1] = f end
        local sub = HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
        for _, f in ipairs((sub and sub.traits) or {}) do traits[#traits + 1] = f end
        return TraitListChoicesComplete(traits)
    elseif index == 2 then
        local bg = S.backgroundId and HarfordDnDBackgrounds.GetBackground and HarfordDnDBackgrounds.GetBackground(S.backgroundId)
        if not bg then return false end
        return TraitListChoicesComplete((HarfordDnDBackgrounds.ResolveTraits
            and HarfordDnDBackgrounds.ResolveTraits(S.backgroundId, S.backgroundVariantId)) or bg.traits)
    elseif index == 3 then
        if S.abilityMode == "roll" then
            if not S.selectedArray then return false end
            local assigned = 0
            for _ in pairs(S.attributeAssignments or {}) do assigned = assigned + 1 end
            return assigned == 6
        end
        return PointsSpent() >= POINT_BUY_BUDGET
    end
    return (S.primaryLevel + S.secondaryLevel) >= RequiredTotal()
end

local ApplyModeLayout  -- forward: el ancho del frame depende de la seccion activa

RefreshSteps = function()
    if ApplyModeLayout then ApplyModeLayout() end
    RefreshSummary()
    if not S.stepRows then return end
    local currentIndex
    for index, step in ipairs(CREATION_STEPS) do
        if step.stages[S.stage] then currentIndex = index break end
    end
    for index, row in ipairs(S.stepRows) do
        local isCurrent = index == currentIndex
        -- Estrella solo con el paso realmente COMPLETO (datos), no por navegar mas alla
        local isDone = StepDone(index)
        row.mark:SetText(isDone and "|cff38d26a*|r" or (isCurrent and "|cffffd100>|r" or "|cff6a6a6a-|r"))
        if isCurrent then
            row.name:SetTextColor(1, 0.82, 0)
        elseif isDone then
            row.name:SetTextColor(0.75, 0.75, 0.75)
        else
            row.name:SetTextColor(0.45, 0.45, 0.45)
        end
        local value = StepValue(index)
        row.value:SetText(value)
        -- Dorado SOLO en el paso seleccionado; confirmado (estrella) en claro; el resto apagado
        if isCurrent then
            row.value:SetTextColor(0.85, 0.72, 0.35)
        elseif isDone then
            row.value:SetTextColor(0.75, 0.75, 0.75)
        else
            row.value:SetTextColor(0.45, 0.45, 0.45)
        end
    end
end

-- Navegacion libre entre secciones desde la barra de pasos (solo creacion): cada paso
-- es un boton que salta a su seccion sin perder lo elegido en las demas.
local function GoToStep(index)
    if IsLevelUpMode() or not S.frame then return end
    if index == 1 then
        S.stage = "race"
        RefreshOriginList()
        RefreshOrigin()
    elseif index == 2 then
        S.stage = "background"
        if not S.backgroundId then
            local first = HarfordDnDBackgrounds.GetBackgrounds and HarfordDnDBackgrounds.GetBackgrounds()[1]
            S.backgroundId = first and first.id or nil
        end
        RefreshOriginList()
        RefreshOrigin()
    elseif index == 3 then
        S.stage = "attributes"
        RefreshAttributes()
    elseif index == 5 then
        -- Solo se puede llegar al equipo con una clase ya elegida: de ella salen los grupos.
        if S.classId and RefreshEquipmentStage then
            S.stage = "equipment"
            RefreshEquipmentStage()
        end
        return
    elseif index == 4 then
        S.stage = "class"
        -- Inicializar el plan de clases solo la PRIMERA vez: volver a esta seccion no
        -- debe borrar los niveles ya asignados.
        if (S.primaryLevel or 0) == 0 and not S.pendingClassId then
            S.classId, S.subclassId, S.secondaryClassId, S.secondarySubclassId = nil, "", nil, ""
            S.primaryLevel, S.secondaryLevel, S.levelPlan, S.classConfirmed = 0, 0, {}, false
            S.pendingClassId, S.classSelectionOpen, S.classSelectionMode = nil, true, "base"
        end
        RefreshClassStage()
    end
end

local function CreateFrameIfNeeded()
    if S.frame then return end
    local frame = CreateFrame("Frame", "HarfordCharacterAdvancementFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(1200, 620)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Harford - Creacion de personaje")
    S.frame = frame

    if not StaticPopupDialogs["HARFORD_CONFIRM_CHARACTER_CREATION"] then
        StaticPopupDialogs["HARFORD_CONFIRM_CHARACTER_CREATION"] = {
            text = "Se creara la ficha de Harford a nivel 1 (reemplazando el About del perfil activo de Total RP 3) y a continuacion se encadenaran las subidas a nivel 2 y 3.",
            button1 = "Crear ficha",
            button2 = "Cancelar",
            OnAccept = Draft.FinishCreation,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    -- ─── Barra de pasos (columna izquierda) ─────────────────────────────────────
    -- Cada paso muestra su estado y la eleccion hecha, como en la creacion de BG3, para no
    -- perder de vista lo ya decidido. El orden es el REAL del asistente, no el de BG3.
    local stepsTitle = MakeText(frame, "GameFontNormal", "CREACION")
    stepsTitle:SetPoint("TOPLEFT", 18, -38)
    stepsTitle:SetTextColor(1, 0.82, 0)
    S.stepRows = {}
    for index = 1, #CREATION_STEPS do
        -- Boton: en creacion permite saltar libremente a esa seccion (en subida no hace nada)
        local row = CreateFrame("Button", nil, frame)
        row:SetSize(126, 40)
        row:SetPoint("TOPLEFT", 16, -62 - (index - 1) * 46)
        row:SetScript("OnClick", function() GoToStep(index) end)
        local rowHl = row:CreateTexture(nil, "HIGHLIGHT")
        rowHl:SetAllPoints(row)
        rowHl:SetColorTexture(1, 1, 1, 0.06)
        row.mark = MakeText(row, "GameFontNormalLarge", "")
        row.mark:SetPoint("TOPLEFT", 0, -2)
        row.name = MakeText(row, "GameFontHighlightSmall", CREATION_STEPS[index].label)
        row.name:SetPoint("TOPLEFT", 18, -2)
        row.value = MakeText(row, "GameFontDisableSmall", "")
        row.value:SetPoint("TOPLEFT", 18, -18)
        row.value:SetWidth(106)
        row.value:SetJustifyH("LEFT")
        row.value:SetWordWrap(true)
        S.stepRows[index] = row
    end
    S.stepsTitle = stepsTitle
    -- ─── Resumen del personaje (columna derecha) ────────────────────────────────
    -- Como el panel derecho de BG3: lo elegido hasta ahora, siempre visible. Solo muestra datos
    -- que EXISTEN durante la creacion; PG y CA no, porque dependen de clase y equipo aun sin fijar.
    local sumTitle = MakeText(frame, "GameFontNormal", "PERSONAJE")
    S.sumTitle = sumTitle
    sumTitle:SetPoint("TOPLEFT", 970, -38)
    sumTitle:SetTextColor(1, 0.82, 0)
    S.sumClass = MakeText(frame, "GameFontHighlight", "")
    S.sumClass:SetPoint("TOPLEFT", 970, -80)
    S.sumOrigin = MakeText(frame, "GameFontHighlightSmall", "")
    S.sumOrigin:SetPoint("TOPLEFT", 970, -98)
    S.sumOrigin:SetWidth(214)
    S.sumOrigin:SetJustifyH("LEFT")
    S.sumAbilities = {}
    for index = 1, 6 do
        local column = (index - 1) % 3
        local rowIndex = math.floor((index - 1) / 3)
        local text = MakeText(frame, "GameFontHighlightSmall", "")
        text:SetPoint("TOPLEFT", 970 + column * 72, -132 - rowIndex * 18)
        text:SetWidth(70)
        text:SetJustifyH("LEFT")
        S.sumAbilities[index] = text
    end
    S.sumSkills = MakeText(frame, "GameFontDisableSmall", "")
    S.sumSkills:SetPoint("TOPLEFT", 970, -174)
    S.sumSkills:SetWidth(214)
    S.sumSkills:SetJustifyH("LEFT")
    S.sumSkills:SetWordWrap(true)

    -- Se guarda: en subida se oculta junto con la barra de pasos.
    S.dividerSteps = frame:CreateTexture(nil, "BORDER")
    local dividerSteps = S.dividerSteps
    dividerSteps:SetPoint("TOPLEFT", 150, -50)
    dividerSteps:SetPoint("BOTTOMLEFT", 150, 46)
    dividerSteps:SetWidth(1)
    dividerSteps:SetColorTexture(0.45, 0.34, 0.14, 0.8)

    local leftTitle = MakeText(frame, "GameFontNormal", "RAZAS")
    leftTitle:SetPoint("TOPLEFT", 164, -38)
    leftTitle:SetTextColor(1, 0.82, 0)
    S.listTitle = leftTitle
    local originScroll = CreateFrame("ScrollFrame", "HarfordCharacterAdvancementOriginScroll", frame)
    S.originScrollY = -76
    originScroll:SetPoint("TOPLEFT", 160, -76)
    originScroll:SetSize(400, 494)
    originScroll:EnableMouseWheel(true)
    local originChild = CreateFrame("Frame", nil, originScroll)
    originChild:SetSize(398, 430)
    originScroll:SetScrollChild(originChild)
    SetManualScroll(originScroll, originChild, 0)
    local originSlider = CreateFrame("Slider", nil, frame)
    originSlider:SetOrientation("VERTICAL")
    originSlider:SetSize(10, 486)
    originSlider:SetPoint("TOPLEFT", 560, -78)
    originSlider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    originSlider:SetMinMaxValues(0, 0)
    originSlider:SetValueStep(24)
    originSlider:SetScript("OnValueChanged", function(_, value)
        SetManualScroll(originScroll, originChild, value)
    end)
    originScroll:SetScript("OnMouseWheel", function(_, delta)
        local minimum, maximum = originSlider:GetMinMaxValues()
        local nextValue = math.max(minimum, math.min(maximum, originSlider:GetValue() - delta * 48))
        originSlider:SetValue(nextValue)
    end)
    S.originScroll, S.originChild, S.originSlider = originScroll, originChild, originSlider
    local dividerA = frame:CreateTexture(nil, "BORDER")
    S.dividerA = dividerA
    dividerA:SetPoint("TOPLEFT", 572, -50)
    dividerA:SetPoint("BOTTOMLEFT", 572, 46)
    dividerA:SetWidth(1)
    dividerA:SetColorTexture(0.45, 0.34, 0.14, 0.8)

    S.classTitle = MakeText(frame, "GameFontNormalLarge", "")
    S.classTitle:SetPoint("TOPLEFT", 592, -38)
    S.classTitle:SetTextColor(1, 0.82, 0)
    S.classSummary = MakeText(frame, "GameFontDisableSmall", "")
    S.classSummary:SetPoint("TOPLEFT", 592, -82)
    S.classSummary:SetWidth(350)
    -- Tres lineas como maximo: el resumen web de clase ocupa 2-3 y sin tope invadia el
    -- selector de subclase y la cabecera de rasgos.
    if S.classSummary.SetMaxLines then S.classSummary:SetMaxLines(3) end
    S.classSummary:SetJustifyH("LEFT")
    S.classSummary:SetNonSpaceWrap(false)
    local subclassLabel = MakeText(frame, "GameFontDisableSmall", "Subraza")
    S.subclassLabel = subclassLabel
    subclassLabel:SetPoint("TOPLEFT", 592, -106)
    S.selectorLabel = subclassLabel
    local subclassDrop = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    subclassDrop:SetPoint("TOPLEFT", 579, -117)
    UIDropDownMenu_SetWidth(subclassDrop, 150)
    S.subclassDrop = subclassDrop

    local tree = CreateFrame("ScrollFrame", nil, frame)
    tree:SetPoint("TOPLEFT", 588, -146)
    tree:SetPoint("BOTTOMRIGHT", 602, 48)
    tree:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, tree)
    child:SetSize(350, 420)
    tree:SetScrollChild(child)
    SetManualScroll(tree, child, 0)
    tree:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, child:GetHeight() - self:GetHeight())
        SetManualScroll(self, child, math.max(0, math.min(range, (self._offset or 0) - delta * 48)))
    end)
    S.tree, S.treeChild, S.treeScroll = child, child, tree

    local dividerB = frame:CreateTexture(nil, "BORDER")
    S.dividerB = dividerB
    dividerB:SetPoint("TOPLEFT", 952, -50)
    dividerB:SetPoint("BOTTOMLEFT", 952, 46)
    dividerB:SetWidth(1)
    dividerB:SetColorTexture(0.45, 0.34, 0.14, 0.8)
    local detailHeader = MakeText(frame, "GameFontNormal", "DETALLE")
    S.detailHeader = detailHeader
    detailHeader:SetPoint("TOPLEFT", 970, -234)
    detailHeader:SetTextColor(1, 0.82, 0)
    S.detailTitle = MakeText(frame, "GameFontHighlight", "Selecciona un nodo")
    S.detailTitle:SetPoint("TOPLEFT", 970, -262)
    S.detailTitle:SetWidth(214)
    S.detailTitle:SetJustifyH("LEFT")
    S.detailTitle:SetNonSpaceWrap(false)
    S.detailText = MakeText(frame, "GameFontHighlightSmall", "")
    S.detailText:SetPoint("TOPLEFT", 970, -296)
    S.detailText:SetWidth(214)
    -- El hueco hasta el bloque de elecciones (-468) son ~170px: sin tope, un rasgo con texto
    -- largo del manual (Lanzamiento de Conjuros del Paladin) se desbordaba por debajo del
    -- frame entero. El texto completo se consulta en el Libro; aqui es un panel de resumen.
    if S.detailText.SetMaxLines then S.detailText:SetMaxLines(12) end
    S.detailText:SetJustifyH("LEFT")
    S.detailText:SetNonSpaceWrap(false)
    S.detailChoices = MakeText(frame, "GameFontDisableSmall", "")
    S.detailChoices:SetPoint("TOPLEFT", 970, -468)
    S.detailChoices:SetWidth(214)
    S.detailChoices:SetJustifyH("LEFT")
    S.detailChoices:SetNonSpaceWrap(false)

    local close = MakeButton(frame, "Cerrar", 92, 24, function() frame:Hide() end)
    close:SetPoint("BOTTOMRIGHT", -16, 16)
    local nextButton = MakeButton(frame, "Confirmar raza", 150, 24, function()
        if S.stage == "race" then
            S.stage = "race_choices"
            RefreshOriginList()
            RefreshOrigin()
        elseif S.stage == "race_choices" then
            S.confirmedSteps = S.confirmedSteps or {}
            S.confirmedSteps.race = true
            S.stage = "background"
            if not S.backgroundId then
                local first = HarfordDnDBackgrounds.GetBackgrounds and HarfordDnDBackgrounds.GetBackgrounds()[1]
                S.backgroundId = first and first.id or nil
            end
            RefreshOriginList()
            RefreshOrigin()
        elseif S.stage == "background" then
            S.stage = "background_choices"
            RefreshOriginList()
            RefreshOrigin()
        elseif S.stage == "background_choices" then
            S.confirmedSteps = S.confirmedSteps or {}
            S.confirmedSteps.background = true
            S.stage = "attributes"
            RefreshAttributes()
        elseif S.stage == "attributes" then
            S.confirmedSteps = S.confirmedSteps or {}
            S.confirmedSteps.attributes = true
            S.stage = "class"
            S.classId, S.subclassId, S.secondaryClassId, S.secondarySubclassId = nil, "", nil, ""
            S.primaryLevel, S.secondaryLevel, S.levelPlan, S.classConfirmed = 0, 0, {}, false
            S.pendingClassId, S.classSelectionOpen, S.classSelectionMode = nil, true, "base"
            RefreshClassStage()
        elseif S.stage == "class" then
            if S.primaryLevel + S.secondaryLevel >= RequiredTotal() then
                if IsLevelUpMode() then
                    Draft.FinishLevelUp()
                elseif #EquipmentGroups() > 0 and RefreshEquipmentStage then
                    -- Falta repartir el equipo inicial: se crea despues de elegirlo.
                    S.stage = "equipment"
                    RefreshEquipmentStage()
                else
                    StaticPopup_Show("HARFORD_CONFIRM_CHARACTER_CREATION")
                end
            else
                CommitClassLevel()
            end
        elseif S.stage == "equipment" then
            S.confirmedSteps = S.confirmedSteps or {}
            S.confirmedSteps.equipment = true
            StaticPopup_Show("HARFORD_CONFIRM_CHARACTER_CREATION")
        end
    end)
    nextButton:SetPoint("BOTTOMLEFT", 18, 16)
    S.nextButton = nextButton
end

-- Recoloca columnas segun la SECCION activa: el frame se hace mas o menos ancho para
-- acomodar solo lo necesario.
--   "grid": raza/trasfondo (rejilla de 400px)        -> dx 0    (frame 1200)
--   "list": clase y toda la subida (lista de botones) -> dx -204 (frame 996; divisor en 368,
--           pegado a los botones: x154 + 210 de boton + 4)
--   "none": caracteristicas y vistas de elecciones (sin columna de seleccion)
--           -> dx -424 (frame 776; el contenido arranca junto a la barra de pasos)
ApplyModeLayout = function()
    if not S.frame then return end
    local layout
    if IsLevelUpMode() then
        layout = "list"
    elseif S.stage == "attributes" or S.stage == "race_choices" or S.stage == "background_choices"
        or S.stage == "equipment" then
        -- Equipo tambien va sin columna de lista: sus grupos se pintan enteros en el detalle y la
        -- lista quedaba VACIA con el titulo "EQUIPO INICIAL" duplicando al de la seccion.
        layout = "none"
    elseif S.stage == "class" then
        layout = "class"
    else
        layout = "grid"
    end
    -- "class" es un intermedio entre "list" y "grid": la columna de clases necesita mas ancho que
    -- una lista de botones porque son tarjetas, pero no los 400 px de la rejilla de razas.
    local dx = layout == "list" and -204
        or (layout == "class" and -150)
        or (layout == "none" and -424)
        -- "grid": -16 para que la rejilla de razas/trasfondos deje el mismo margen (20 px) hasta
        -- el panel de detalle que la de clases; sin el, dejaba 36.
        or -16
    -- En subida desaparece la barra de pasos (144 px): la lista de clases y todo lo de su derecha
    -- se recolocan a la izquierda y el frame se estrecha otro tanto.
    local dxPasos = LeftShift()
    dx = dx + dxPasos
    S.layoutDX = dx  -- para anclajes hechos fuera de esta funcion (tarjetas de subraza)
    local newWidth = 1200 + dx
    if math.abs((S.frame:GetWidth() or 0) - newWidth) > 0.5 then
        -- Conservar la esquina superior izquierda al cambiar de ancho: la barra de pasos
        -- y los botones quedan donde estaban y el cursor no tiene que perseguirlos.
        local left, top = S.frame:GetLeft(), S.frame:GetTop()
        S.frame:SetWidth(newWidth)
        if left and top then
            S.frame:ClearAllPoints()
            S.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
    else
        S.frame:SetWidth(newWidth)
    end
    if S.dividerA then S.dividerA:SetShown(layout ~= "none") end
    if S.listTitle then S.listTitle:SetShown(layout ~= "none") end
    -- Barra de pasos: solo en creacion.
    local conPasos = not IsLevelUpMode()
    if S.stepsTitle then S.stepsTitle:SetShown(conPasos) end
    for _, row in ipairs(S.stepRows or {}) do row:SetShown(conPasos) end
    if S.dividerSteps then S.dividerSteps:SetShown(conPasos) end
    local function put(obj, x, y)
        if obj then
            obj:ClearAllPoints()
            obj:SetPoint("TOPLEFT", x, y)
        end
    end
    if S.dividerA then
        S.dividerA:ClearAllPoints()
        S.dividerA:SetPoint("TOPLEFT", 572 + dx, -50)
        S.dividerA:SetPoint("BOTTOMLEFT", 572 + dx, 46)
    end
    put(S.classTitle, 592 + dx, -38)
    put(S.classSummary, 592 + dx, -82)
    put(S.subclassLabel, 592 + dx, -106)
    put(S.subclassDrop, 579 + dx, -117)
    if S.treeScroll then
        S.treeScroll:ClearAllPoints()
        S.treeScroll:SetPoint("TOPLEFT", 588 + dx, -146)
        S.treeScroll:SetPoint("BOTTOMRIGHT", 602 + dx, 48)
    end
    if S.dividerB then
        S.dividerB:ClearAllPoints()
        S.dividerB:SetPoint("TOPLEFT", 952 + dx, -50)
        S.dividerB:SetPoint("BOTTOMLEFT", 952 + dx, 46)
    end
    put(S.sumTitle, 970 + dx, -38)
    put(S.sumClass, 970 + dx, -80)
    put(S.sumOrigin, 970 + dx, -98)
    for index, text in ipairs(S.sumAbilities or {}) do
        local column = (index - 1) % 3
        local rowIndex = math.floor((index - 1) / 3)
        put(text, 970 + dx + column * 72, -132 - rowIndex * 18)
    end
    put(S.sumSkills, 970 + dx, -174)
    put(S.detailHeader, 970 + dx, -234)
    put(S.detailTitle, 970 + dx, -262)
    put(S.detailText, 970 + dx, -296)
    put(S.detailChoices, 970 + dx, -468)

    -- Columna de la lista (titulo y scroll) y su separador.
    put(S.listTitle, 164 + dxPasos, -38)
    if S.originScroll then
        S.originScroll:ClearAllPoints()
        S.originScroll:SetPoint("TOPLEFT", 160 + dxPasos, S.originScrollY or -76)
    end
    if S.originSlider then
        -- El slider va pegado al borde derecho de la lista; se mueve con ella.
        S.originSlider:ClearAllPoints()
        S.originSlider:SetPoint("TOPLEFT", 560 + dxPasos, -78)
    end
    -- El boton de confirmar, DEBAJO de la lista: es donde se toma la decision. En creacion se
    -- queda en la esquina, bajo la barra de pasos.
    if S.nextButton then
        S.nextButton:ClearAllPoints()
        S.nextButton:SetPoint("BOTTOMLEFT", 18 + (IsLevelUpMode() and (160 + dxPasos - 18) or 0), 16)
    end
    -- Reiniciar de Caracteristicas: FUERA del scroll (dentro quedaba bajo el borde visible y
    -- parecia que no existia), pegado a Confirmar. Resetea lo que toque segun el modo.
    if not S.attrResetButton and S.nextButton then
        S.attrResetButton = MakeButton(S.frame, "Reiniciar", 100, 22, function()
            if S.abilityMode == "points" then
                S.pointBuy = nil
            else
                S.attributeAssignments, S.pendingScore = {}, nil
            end
            RefreshAttributes()
        end)
        S.attrResetButton:SetPoint("BOTTOMLEFT", S.nextButton, "BOTTOMRIGHT", 10, 0)
    end
    if S.attrResetButton then S.attrResetButton:SetShown(S.stage == "attributes") end
end

function API.OpenPrototype(classId)
    if not (HarfordDnDRaces and HarfordDnDRaces.GetRaces and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgrounds) then
        return false, "Las opciones de origen no estan disponibles."
    end
    CreateFrameIfNeeded()
    S.mode, S.targetTotal = "creation", CREATION_LEVEL
    ApplyModeLayout()
    S.frame.TitleText:SetText("Harford - Creacion de personaje")
    S.stepsTitle:SetText("CREACION")
    S.stage = "race"
    if not S.raceId or not HarfordDnDRaces.GetRace(S.raceId) then
        local first = HarfordDnDRaces.GetRaces()[1]
        S.raceId = first and first.id or ""
    end
    S.subraceId = ""
    S.attributeArrays, S.selectedArray, S.attributeAssignments, S.pendingScore = nil, nil, {}, nil
    -- La compra por puntos tambien se reinicia: es estado del PJ en curso, igual que los arrays.
    -- `S.abilityMode` se conserva a proposito, como preferencia de sistema del usuario.
    S.pointBuy = nil
    S.autoLevelTarget = nil
    S.confirmedSteps = {}
    S.choiceSelections, S.pendingFeatures = {}, {}
    S.classConfirmed = false
    S.classId, S.subclassId, S.secondaryClassId, S.secondarySubclassId = nil, "", nil, ""
    S.primaryLevel, S.secondaryLevel, S.levelPlan = 0, 0, {}
    S.pendingClassId, S.classSelectionOpen, S.classSelectionMode = nil, true, "base"
    S.spellPicks = nil
    S.frame:ClearAllPoints()
    S.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if HarfordCharacterPanel and HarfordCharacterPanel.Close then HarfordCharacterPanel.Close() end
    RefreshOriginList()
    RefreshOrigin()
    S.frame:Show()
    return true
end

-- Entrada de subida moderna. Parte de la ficha actual y avanza exactamente un
-- nivel total; no vuelve a mostrar ni puede modificar las etapas de origen.
function API.OpenLevelUp()
    if not (HarfordDnDProgression and HarfordDnDProgression.Get and HarfordDnDBook and HarfordDnDBook.GetClass) then
        return false, "La progresion o el Libro no estan disponibles."
    end
    local data = HarfordDnDProgression.Get()
    local classes = data and data.classLevels or {}
    if #classes == 0 or #classes > 2 then
        return false, "La subida moderna requiere una ficha con una o dos clases."
    end
    local currentTotal = HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel() or 0
    local maxTotal = tonumber(HarfordDnDProgression.MAX_TOTAL_LEVEL) or 20
    if currentTotal >= maxTotal then
        return false, "La ficha ya ha alcanzado el nivel maximo (" .. tostring(maxTotal) .. ")."
    end
    CreateFrameIfNeeded()
    S.mode = "levelup"
    ApplyModeLayout()
    S.targetTotal = currentTotal + 1
    S.stage = "class"
    S.raceId = tostring(data.race and data.race.id or "")
    S.subraceId = tostring(data.race and data.race.subraceId or "")
    S.backgroundId = tostring(data.background or "")
    S.choiceSelections = CopyTable(data.choices or {})
    S.pendingFeatures = {}
    S.classId, S.subclassId = classes[1].classId, classes[1].subclassId or ""
    S.primaryLevel = tonumber(classes[1].level) or 1
    S.secondaryClassId, S.secondarySubclassId, S.secondaryLevel = nil, "", 0
    if classes[2] then
        S.secondaryClassId, S.secondarySubclassId = classes[2].classId, classes[2].subclassId or ""
        S.secondaryLevel = tonumber(classes[2].level) or 1
    end
    S.levelPlan = {}
    S.classSelectionOpen, S.classSelectionMode = true, "advance"
    S.pendingClassId = S.classId
    S.spellPicks = nil
    S.frame.TitleText:SetText("Harford - Subida de nivel")
    S.stepsTitle:SetText("SUBIDA")
    S.frame:ClearAllPoints()
    S.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if HarfordCharacterPanel and HarfordCharacterPanel.Close then HarfordCharacterPanel.Close() end
    RefreshClassStage()
    S.frame:Show()
    return true
end

-- Al FINAL: varias dependencias son de asignacion adelantada.
if Draft and Draft.Init then
    Draft.Init({
        API = API,
        BaseScoreFor = BaseScoreFor,
        ExpandedSpellNames = ExpandedSpellNames,
        RequiredTotal = RequiredTotal,
        ResetCreationSpellState = ResetCreationSpellState,
        S = S,
        SpellsForClass = SpellsForClass,
    })
end
