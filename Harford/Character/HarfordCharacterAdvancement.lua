-- HarfordCharacterAdvancement: prototipo visual de creacion y progresion.
-- No persiste ni modifica fichas; solo presenta el arbol construido desde el Libro.

HarfordCharacterAdvancement = HarfordCharacterAdvancement or {}

local API = HarfordCharacterAdvancement
local S = { frame = nil, stage = "race", raceId = "humano", subraceId = "", backgroundId = nil, selected = nil, nodeRows = {}, choiceSelections = {}, choiceRows = {}, attributeArrays = nil, selectedArray = nil, attributeAssignments = {}, pendingScore = nil, classConfirmed = false, secondaryClassId = nil, secondarySubclassId = "", primaryLevel = 0, secondaryLevel = 0, levelPlan = {}, pendingClassId = nil, pendingFeatures = {}, classSelectionOpen = true, classSelectionMode = "base" }

local CREATION_LEVEL = 4
local MAX_PREVIEW_LEVEL = CREATION_LEVEL
local BASE_RACE_IDS = { elfo_noche = true }

local function MakeText(parent, template, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetText(text or "")
    return fs
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

local function GetBookFeatureDescription(feature, source)
    if not (feature and HarfordDnDBookText and HarfordDnDBookText.GetFeatureDescription) then
        return feature and feature.description or "Sin descripcion."
    end
    return HarfordDnDBookText.GetFeatureDescription(feature, S.classId, source, S.backgroundId)
end

local OpenChoiceDialog
local RaceAbilityBonus     -- forward: se asigna mas abajo; el picker de conjuros lo usa antes de su def
local AppendSpellPickers   -- forward: definido tras OpenSpellDialog; lo llama RefreshPendingLevelFeatures

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
            choose:SetPoint("TOPLEFT", 640, -258)
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
    local width = source == "Subclase" and 322 or 340

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
local CommitClassLevel

local function RefreshClassList()
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    S.classButtons = {}
    local y = -76
    for _, classDef in ipairs(HarfordDnDBook.GetClasses() or {}) do
        local chosen = classDef
        local button = MakeButton(S.frame, chosen.name, 150, 24, function()
            S.pendingClassId = chosen.id
            RefreshClassStage()
        end)
        button:SetPoint("TOPLEFT", 18, y)
        if S.pendingClassId == chosen.id then button:LockHighlight() end
        if S.classSelectionMode == "add" and chosen.id == S.classId then button:SetEnabled(false) end
        S.classButtons[#S.classButtons + 1] = button
        y = y - 27
    end
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
        if tonumber(feature.level) == classLevel then
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
                if tonumber(feature.level) == classLevel then
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
    local subclasses = classDef.subclasses or {}
    if #subclasses == 0 then return true end
    S.selectorLabel:SetText("Subclase")
    S.selectorLabel:Show()
    S.subclassDrop:Show()
    local selected = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, selectedId)
    UIDropDownMenu_SetText(S.subclassDrop, selected and selected.name or "Elige subclase")
    UIDropDownMenu_Initialize(S.subclassDrop, function()
        for _, entry in ipairs(subclasses) do
            local choice = entry
            local info = UIDropDownMenu_CreateInfo()
            info.text = choice.name or choice.id
            info.checked = choice.id == selectedId
            info.func = function()
                if primarySlot then S.subclassId = choice.id else S.secondarySubclassId = choice.id end
                RefreshClassStage()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    return selected ~= nil
end

RefreshClassStage = function()
    ClearRows()
    S.originScroll:Hide()
    S.originSlider:Hide()
    local assigned = S.primaryLevel + S.secondaryLevel
    local nextLevel = assigned + 1
    for _, button in ipairs(S.classMetaButtons or {}) do button:Hide() end
    S.classMetaButtons = {}
    if S.classSelectionOpen then
        S.listTitle:SetText("ELIGE CLASE: NIVEL " .. tostring(nextLevel) .. " DE " .. tostring(CREATION_LEVEL))
        RefreshClassList()
        local preview = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.pendingClassId)
        S.classTitle:SetText(preview and tostring(preview.name) or "Elige la clase que recibira este nivel")
        S.classSummary:SetText(preview and tostring(preview.desc or "") or (S.classSelectionMode == "add"
            and "La nueva clase empezara en nivel 1. Solo se permiten dos clases."
            or "Selecciona una clase para continuar la subida de nivel."))
        S.subclassDrop:Hide()
        S.selectorLabel:Hide()
        if preview then
            local previewLevel = preview.id == S.classId and S.primaryLevel + 1
                or (preview.id == S.secondaryClassId and S.secondaryLevel + 1 or 1)
            RefreshPendingLevelFeatures(preview, previewLevel)
            local subclassReady = ConfigureSubclassChoice(preview, previewLevel)
            S.nextButton:SetEnabled(subclassReady and PendingChoicesComplete())
        else
            SetDetail(nil)
        end
        S.nextButton:SetText(preview and ("Elegir " .. tostring(preview.name) .. " para nivel " .. tostring(nextLevel)) or "Selecciona una clase")
        if not preview then S.nextButton:SetEnabled(false) end
        S.nextButton:SetShown(true)
        return
    end
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    if assigned >= CREATION_LEVEL then
        local first = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.classId)
        local second = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(S.secondaryClassId)
        S.listTitle:SetText("NIVELES ASIGNADOS")
        S.classTitle:SetText("Creacion preparada a nivel " .. tostring(CREATION_LEVEL))
        S.classSummary:SetText(tostring(first and first.name or "") .. " nivel " .. tostring(S.primaryLevel)
            .. (second and (" / " .. tostring(second.name) .. " nivel " .. tostring(S.secondaryLevel)) or "")
            .. "\nTodo esta listo para crear la ficha y generar el About de TRP3.")
        S.subclassDrop:Hide()
        S.selectorLabel:Hide()
        SetDetail(nil)
        S.nextButton:SetText("Crear ficha y generar About TRP3")
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
    S.listTitle:SetText("NIVEL " .. tostring(nextLevel) .. " DE " .. tostring(CREATION_LEVEL))
    S.classTitle:SetText(tostring(pending.name) .. " recibira nivel " .. tostring(pendingLevel))
    S.classSummary:SetText("Esta es la unica clase que sube en este paso. Confirma el nivel para aplicar sus rasgos y elecciones.")
    local subclassReady = ConfigureSubclassChoice(pending, pendingLevel)
    RefreshPendingLevelFeatures(pending, pendingLevel)
    local function AddClassControl(text, y, onClick)
        local button = MakeButton(S.frame, text, 150, 24, onClick)
        button:SetPoint("TOPLEFT", 18, y)
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
    S.nextButton:SetEnabled(assigned < CREATION_LEVEL and subclassReady and PendingChoicesComplete())
    S.nextButton:SetShown(true)
end

CommitClassLevel = function()
    local assigned = S.primaryLevel + S.secondaryLevel
    if assigned >= CREATION_LEVEL then return end
    local id = S.pendingClassId
    if id == S.classId then
        S.primaryLevel = S.primaryLevel + 1
    elseif id == S.secondaryClassId then
        S.secondaryLevel = S.secondaryLevel + 1
    elseif not S.classId then
        S.classId = id
        S.subclassId = ""
        S.primaryLevel = 1
    elseif not S.secondaryClassId then
        S.secondaryClassId = id
        S.secondarySubclassId = ""
        S.secondaryLevel = 1
    else
        return
    end
    S.levelPlan[#S.levelPlan + 1] = id
    S.classConfirmed = S.primaryLevel + S.secondaryLevel == CREATION_LEVEL
    S.classSelectionOpen, S.classSelectionMode = false, "advance"
    RefreshClassStage()
end

local RefreshOrigin

local function RefreshOriginList()
    for _, button in ipairs(S.originButtons or {}) do button:Hide() end
    for _, button in ipairs(S.classButtons or {}) do button:Hide() end
    for _, button in ipairs(S.classMetaButtons or {}) do button:Hide() end
    S.originButtons = {}
    S.originScroll:SetShown(S.stage ~= "race_choices" and S.stage ~= "background_choices")
    S.originSlider:SetShown(false)
    if S.stage == "race_choices" or S.stage == "background_choices" then return end
    local entries = S.stage == "race" and HarfordDnDRaces.GetRaces() or HarfordDnDBackgrounds.GetBackgrounds()
    local y = -4
    for _, entry in ipairs(entries or {}) do
        local choice = entry
        local label = tostring(choice.name or "")
        local height = #label > 36 and 52 or (#label > 20 and 38 or 24)
        local button = MakeButton(S.originChild, label, 150, height, function()
            if S.stage == "race" then
                S.raceId = choice.id
                -- La raza base es una opcion valida: las subrazas nunca se eligen por defecto.
                S.subraceId = ""
            else
                S.backgroundId = choice.id
            end
            RefreshOriginList()
            RefreshOrigin()
        end)
        local text = button.GetFontString and button:GetFontString()
        if text then
            text:SetWidth(140)
            text:SetJustifyH("CENTER")
            text:SetJustifyV("MIDDLE")
            text:SetWordWrap(true)
        end
        button:SetPoint("TOPLEFT", 2, y)
        if (S.stage == "race" and choice.id == S.raceId) or (S.stage == "background" and choice.id == S.backgroundId) then
            button:LockHighlight()
        end
        S.originButtons[#S.originButtons + 1] = button
        y = y - height - 3
    end
    S.originChild:SetHeight(math.max(430, -y + 4))
    local range = math.max(0, S.originChild:GetHeight() - 494)
    SetManualScroll(S.originScroll, S.originChild, 0)
    S.originSlider:SetMinMaxValues(0, range)
    S.originSlider:SetValue(0)
    S.originSlider:SetShown(range > 0)
end

RefreshOrigin = function()
    if not S.frame then return end
    ClearRows()
    local isRace = S.stage == "race" or S.stage == "race_choices"
    local def = isRace and HarfordDnDRaces.GetRace(S.raceId) or HarfordDnDBackgrounds.GetBackground(S.backgroundId)
    if not def then return end
    S.listTitle:SetText(S.stage == "race_choices" and "RAZA CONFIRMADA"
        or (S.stage == "background_choices" and "TRASFONDO CONFIRMADO" or (isRace and "RAZAS" or "TRASFONDOS")))
    S.classTitle:SetText((isRace and "Raza: " or "Trasfondo: ") .. tostring(def.name or ""))
    S.classSummary:SetText(tostring(def.desc or ""))
    S.selectorLabel:SetText(isRace and "Subraza" or "Origen")

    if S.subclassDrop then
        if isRace then
            local subraces = def.subraces or {}
            local sub = HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
            local canChangeSubrace = S.stage == "race"
            S.subclassDrop:SetShown(#subraces > 0 and canChangeSubrace)
            S.selectorLabel:SetShown(#subraces > 0 and canChangeSubrace)
            if sub then
                UIDropDownMenu_SetText(S.subclassDrop, sub.name)
            elseif AllowsBaseRace(def) then
                UIDropDownMenu_SetText(S.subclassDrop, tostring(def.name) .. " (raza base)")
            else
                UIDropDownMenu_SetText(S.subclassDrop, "Elige subraza")
            end
            UIDropDownMenu_Initialize(S.subclassDrop, function()
                if AllowsBaseRace(def) then
                    local base = UIDropDownMenu_CreateInfo()
                    base.text = tostring(def.name) .. " (raza base)"
                    base.checked = not S.subraceId or S.subraceId == ""
                    base.func = function()
                        S.subraceId = ""
                        RefreshOrigin()
                    end
                    UIDropDownMenu_AddButton(base)
                end
                for _, entry in ipairs(subraces) do
                    local choice = entry
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = choice.name or choice.id
                    info.checked = choice.id == S.subraceId
                    info.func = function()
                        S.subraceId = choice.id
                        RefreshOrigin()
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end)
        else
            S.subclassDrop:Hide()
            S.selectorLabel:Hide()
        end
    end

    local traits = {}
    if isRace then
        for _, feature in ipairs(def.traits or {}) do traits[#traits + 1] = { feature = feature, source = "Raza" } end
        local sub = HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
        for _, feature in ipairs((sub and sub.traits) or {}) do traits[#traits + 1] = { feature = feature, source = "Subraza" } end
    else
        for _, feature in ipairs(def.traits or {}) do traits[#traits + 1] = { feature = feature, source = "Trasfondo" } end
    end
    local heading = MakeText(S.tree, "GameFontNormal", isRace and "RASGOS DE RAZA" or "RASGOS DE TRASFONDO")
    heading:SetPoint("TOPLEFT", 46, -154)
    heading:SetTextColor(1, 0.82, 0)
    S.nodeRows[#S.nodeRows + 1] = heading
    local y = -182
    for _, entry in ipairs(traits) do
        CreateNode(S.tree, entry.source == "Subraza" and 64 or 46, y, nil, entry.feature, entry.source)
        y = y - 44
    end
    if #traits == 0 then
        local empty = MakeText(S.tree, "GameFontDisableSmall", "No hay rasgos registrados para esta opcion.")
        empty:SetPoint("TOPLEFT", 46, y)
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

local function BuildCreationDraft()
    local abilities = {}
    local array = S.attributeArrays and S.attributeArrays[S.selectedArray]
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        local assigned = S.attributeAssignments[ability.key]
        local base = array and assigned and array.values[assigned] or 0
        -- Guardar SOLO la base asignada. El bono racial lo aplica HarfordDnDCalc en vivo (rasgos de
        -- raza via FeatureEffects); sumarlo aqui lo contaba DOS veces. Igual que importa cargarficha.
        abilities[ability.key] = base
    end
    local classes = {
        { classId = S.classId, subclassId = S.subclassId, level = S.primaryLevel },
    }
    if S.secondaryClassId then
        classes[#classes + 1] = { classId = S.secondaryClassId, subclassId = S.secondarySubclassId, level = S.secondaryLevel }
    end
    return {
        raceId = S.raceId,
        subraceId = S.subraceId,
        backgroundId = S.backgroundId,
        abilities = abilities,
        classes = classes,
        choices = S.choiceSelections,
    }
end

-- Escribe los conjuros elegidos en el picker al compendio del PJ. Se llama ANTES de Apply para que
-- el About generado ya incluya las secciones de magia. Cantrips -> knownSpells (siempre); pool ->
-- knownSpells (known) o wizardBook (mago); preparados -> preparedSpells.
local function PersistSpellPicks(draft)
    if type(S.spellPicks) ~= "table" then return end
    local db = _G.HarfordCompendioCharacterDB
    local C = _G.HarfordCompendioAPI
    if type(db) ~= "table" then return end
    db.knownSpells = db.knownSpells or {}
    db.wizardBook = db.wizardBook or {}
    db.preparedSpells = db.preparedSpells or {}
    local poolMode = "known"
    for _, entry in ipairs((draft and draft.classes) or {}) do
        local cls = HarfordDnDBook.GetClass(entry.classId)
        local name = cls and cls.name
        local casting = name and C and C.GetClassCasting and C.GetClassCasting(name)
        if not casting and name then
            local sub = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
            if sub and C and C.GetClassCasting then casting = C.GetClassCasting(name .. " " .. sub.name) end
        end
        if casting then poolMode = casting.mode; break end
    end
    for id in pairs(S.spellPicks.cantrips or {}) do db.knownSpells[id] = true end
    local poolTbl = poolMode == "wizard_book" and db.wizardBook or db.knownSpells
    for id in pairs(S.spellPicks.spells or {}) do poolTbl[id] = true end
    for id in pairs(S.spellPicks.prepared or {}) do db.preparedSpells[id] = true end
end

local function FinishCreation()
    local draft = BuildCreationDraft()
    PersistSpellPicks(draft)  -- conjuros al compendio ANTES de generar el About
    -- OJO: `X and Y and Y(draft)` truncaba los 2 retornos de Apply a uno, perdiendo el MOTIVO del
    -- error (siempre salia "nil"). Capturar ambos valores con una llamada directa.
    local ok, result
    if HarfordCharacterCreation and HarfordCharacterCreation.Apply then
        ok, result = HarfordCharacterCreation.Apply(draft)
    else
        result = "Modulo de creacion (HarfordCharacterCreation) no disponible."
    end
    if not ok then
        if HarfordChat and HarfordChat.Print then HarfordChat.Print("|cffff5555No se pudo crear la ficha: " .. tostring(result) .. "|r") end
        return
    end
    if HarfordChat and HarfordChat.Print then
        HarfordChat.Print("|cff38d26aFicha creada a nivel 4 y About de TRP3 generado.|r")
    end
    S.frame:Hide()
end

local function RefreshAttributes()
    ClearRows()
    S.originScroll:Hide()
    S.originSlider:Hide()
    S.subclassDrop:Hide()
    S.selectorLabel:Hide()
    S.listTitle:SetText("CARACTERISTICAS")
    S.classTitle:SetText("Caracteristicas")
    S.classSummary:SetText("Tres arrays de 4d6, descartando el dado menor de cada caracteristica.")
    SetDetail(nil)
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
        for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
            local key = ability.key
            local assignedIndex = S.attributeAssignments[key]
            local base = assignedIndex and array.values[assignedIndex] or nil
            local bonus = RaceAbilityBonus(key)
            local label = key .. ": " .. (base and tostring(base) or "-")
            if base and bonus ~= 0 then label = label .. "  |cff38d26a+" .. tostring(bonus) .. " = " .. tostring(base + bonus) .. "|r" end
            local row = MakeButton(S.tree, label, 260, 25, function()
                if S.pendingScore then
                    for otherKey, scoreIndex in pairs(S.attributeAssignments) do
                        if scoreIndex == S.pendingScore then S.attributeAssignments[otherKey] = nil end
                    end
                    S.attributeAssignments[key] = S.pendingScore
                    S.pendingScore = nil
                    RefreshAttributes()
                end
            end)
            row:SetPoint("TOPLEFT", 22, y)
            S.nodeRows[#S.nodeRows + 1] = row
            y = y - 29
        end
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

local function RefreshChoiceDialog()
    local dialog = S.choiceDialog
    if not (dialog and dialog.feature) then return end
    for _, row in ipairs(S.choiceDialogRows or {}) do row:Hide() end
    S.choiceDialogRows = {}
    local feature = dialog.feature
    local options = HarfordDnDBook.GetChoiceOptions(feature) or {}
    local slots = HarfordDnDBook.GetChoiceSlots(feature)
    local selected = S.choiceSelections[feature.id] or {}
    S.choiceSelections[feature.id] = selected
    dialog.TitleText:SetText("Elegir: " .. tostring(feature.name or "Rasgo"))
    dialog.description:SetText(tostring(feature.description or "") .. "\n\nElige " .. tostring(slots) .. ".")
    dialog.status:SetText("Seleccionadas: " .. tostring(#selected) .. "/" .. tostring(slots))
    dialog.status:SetTextColor(#selected == slots and 0.22 or 1, #selected == slots and 0.82 or 0.78, #selected == slots and 0.42 or 0.2)
    dialog.confirm:SetEnabled(#selected == slots)
    local y = 0
    for _, option in ipairs(options) do
        local choice = option
        local row = MakeButton(dialog.treeChild, (ContainsChoice(selected, choice.id) and "[X] " or "[ ] ") .. tostring(choice.label or choice.id), 350, 25, function()
            local index = ContainsChoice(selected, choice.id)
            if index then
                table.remove(selected, index)
            elseif #selected < slots then
                selected[#selected + 1] = choice.id
            else
                dialog.status:SetText("Ya has elegido el maximo de opciones.")
                return
            end
            RefreshChoiceDialog()
        end)
        row:SetPoint("TOPLEFT", 4, y)
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
local function SpellsForClass(className, kind, maxLevel)
    local C = _G.HarfordCompendioAPI
    if not (C and C.GetAllSpells) then return {} end
    local out = {}
    for _, spell in ipairs(C.GetAllSpells() or {}) do
        local lvl = tonumber(spell.level) or 0
        local classes = spell.classes or {}
        local match = false
        for _, cn in ipairs(classes) do if cn == className then match = true break end end
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
        S.spellDialogRows[#S.spellDialogRows + 1] = row
        y = y - 28
    end
    dialog.treeChild:SetHeight(math.max(240, -y + 4))
    SetManualScroll(dialog.tree, dialog.treeChild, 0)
end

-- Abre el picker. store = tabla {spellId=true}; limit = maximo; kind = "cantrip"/"spell"/"prepared".
local function OpenSpellDialog(className, store, limit, kind, maxLevel, subtitle, title, onClose)
    local dialog = CreateSpellDialog()
    dialog.store, dialog.limit, dialog.subtitle, dialog.onClose = store, tonumber(limit) or 0, subtitle, onClose
    dialog.spells = SpellsForClass(className, kind == "cantrip" and "cantrip" or "spell", maxLevel)
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

-- Dibuja el/los boton(es) de seleccion de conjuros para una clase lanzadora en el paso de nivel.
-- Devuelve la nueva `y`. Limite = TOTAL acumulado al nivel; los preparados usan el calculo Mod+nivel.
AppendSpellPickers = function(classDef, classLevel, y)
    local C = _G.HarfordCompendioAPI
    if not (classDef and C and C.GetClassCasting and C.GetSpellProgression) then return y end
    local className = classDef.name
    local casting = C.GetClassCasting(className)
    if not casting then
        local subId = classDef.id == S.classId and S.subclassId or S.secondarySubclassId
        local subclass = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, subId)
        if subclass then
            local combo = className .. " " .. subclass.name
            if C.GetClassCasting(combo) then casting, className = C.GetClassCasting(combo), combo end
        end
    end
    if not casting then return y end
    local prog = C.GetSpellProgression(className)
    if not prog then return y end

    local picks = EnsureSpellPicks()
    local maxLevel = (C.GetMaxSpellLevel and C.GetMaxSpellLevel(className, classLevel))
        or math.max(1, math.min(5, math.ceil(classLevel / 2)))

    local heading = MakeText(S.tree, "GameFontNormal", "CONJUROS DE " .. string.upper(className))
    heading:SetPoint("TOPLEFT", 26, y)
    heading:SetTextColor(0.4, 0.8, 1)
    S.nodeRows[#S.nodeRows + 1] = heading
    y = y - 30

    local function CountStore(store)
        local n = 0
        for _ in pairs(store) do n = n + 1 end
        return n
    end
    local function AddPickerButton(label, store, limit, kind, title)
        local b = MakeButton(S.tree, label .. " (" .. CountStore(store) .. "/" .. limit .. ")", 240, 24, function()
            OpenSpellDialog(className, store, limit, kind, kind == "cantrip" and 0 or maxLevel,
                label, title, function() RefreshClassStage() end)
        end)
        b:SetPoint("TOPLEFT", 40, y)
        S.nodeRows[#S.nodeRows + 1] = b
        y = y - 28
    end

    local cantripLimit = tonumber(prog.cantrips and prog.cantrips[classLevel]) or 0
    if cantripLimit > 0 then
        AddPickerButton("Trucos", picks.cantrips, cantripLimit, "cantrip", "Trucos de " .. className)
    end
    -- Botones de conjuro/preparar solo si la clase ya lanza conjuros con nivel (maxLevel > 0).
    if maxLevel > 0 then
        if prog.spells then
            local spellLimit = tonumber(prog.spells[classLevel]) or 0
            if spellLimit > 0 then
                local label = casting.mode == "wizard_book" and "Libro de conjuros" or "Conjuros conocidos"
                AddPickerButton(label, picks.spells, spellLimit, "spell", label .. " - " .. className)
            end
        elseif prog.prepared then
            local array = S.attributeArrays and S.attributeArrays[S.selectedArray]
            local assigned = S.attributeAssignments and S.attributeAssignments[casting.ability]
            local base = (array and assigned and array.values[assigned]) or 10
            local mod = math.floor((base + (RaceAbilityBonus and RaceAbilityBonus(casting.ability) or 0) - 10) / 2)
            local prepLimit = (C.GetPreparedCount and C.GetPreparedCount(className, mod, classLevel)) or 0
            if prepLimit > 0 then
                AddPickerButton("Preparar conjuros", picks.prepared, prepLimit, "spell", "Preparar - " .. className)
            end
        end
    end
    return y
end

local function CreateFrameIfNeeded()
    if S.frame then return end
    local frame = CreateFrame("Frame", "HarfordCharacterAdvancementFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(900, 620)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Harford - Creacion y progresion")
    S.frame = frame

    if not StaticPopupDialogs["HARFORD_CONFIRM_CHARACTER_CREATION"] then
        StaticPopupDialogs["HARFORD_CONFIRM_CHARACTER_CREATION"] = {
            text = "Se creara la ficha de Harford a nivel 4 y se reemplazara el About del perfil activo de Total RP 3. El resto del perfil no se modifica.",
            button1 = "Crear ficha",
            button2 = "Cancelar",
            OnAccept = FinishCreation,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    local header = MakeText(frame, "GameFontHighlightSmall", "La ficha se aplica al finalizar y genera el About de Total RP 3.")
    header:SetPoint("TOPLEFT", 18, -38)
    header:SetTextColor(0.65, 0.85, 0.7)
    local leftTitle = MakeText(frame, "GameFontNormal", "RAZAS")
    leftTitle:SetPoint("TOPLEFT", 18, -58)
    leftTitle:SetTextColor(1, 0.82, 0)
    S.listTitle = leftTitle
    local originScroll = CreateFrame("ScrollFrame", "HarfordCharacterAdvancementOriginScroll", frame)
    originScroll:SetPoint("TOPLEFT", 14, -76)
    originScroll:SetSize(152, 494)
    originScroll:EnableMouseWheel(true)
    local originChild = CreateFrame("Frame", nil, originScroll)
    originChild:SetSize(150, 430)
    originScroll:SetScrollChild(originChild)
    SetManualScroll(originScroll, originChild, 0)
    local originSlider = CreateFrame("Slider", nil, frame)
    originSlider:SetOrientation("VERTICAL")
    originSlider:SetSize(10, 486)
    originSlider:SetPoint("TOPLEFT", 166, -78)
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
    dividerA:SetPoint("TOPLEFT", 178, -50)
    dividerA:SetPoint("BOTTOMLEFT", 178, 46)
    dividerA:SetWidth(1)
    dividerA:SetColorTexture(0.45, 0.34, 0.14, 0.8)

    S.classTitle = MakeText(frame, "GameFontNormalLarge", "")
    S.classTitle:SetPoint("TOPLEFT", 198, -58)
    S.classTitle:SetTextColor(1, 0.82, 0)
    S.classSummary = MakeText(frame, "GameFontDisableSmall", "")
    S.classSummary:SetPoint("TOPLEFT", 198, -82)
    S.classSummary:SetWidth(390)
    S.classSummary:SetJustifyH("LEFT")
    S.classSummary:SetNonSpaceWrap(false)
    local subclassLabel = MakeText(frame, "GameFontDisableSmall", "Subraza")
    subclassLabel:SetPoint("TOPLEFT", 198, -106)
    S.selectorLabel = subclassLabel
    local subclassDrop = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
    subclassDrop:SetPoint("TOPLEFT", 185, -117)
    UIDropDownMenu_SetWidth(subclassDrop, 150)
    S.subclassDrop = subclassDrop

    local tree = CreateFrame("ScrollFrame", nil, frame)
    tree:SetPoint("TOPLEFT", 194, -146)
    tree:SetPoint("BOTTOMRIGHT", 602, 48)
    tree:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, tree)
    child:SetSize(390, 420)
    tree:SetScrollChild(child)
    SetManualScroll(tree, child, 0)
    tree:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(0, child:GetHeight() - self:GetHeight())
        SetManualScroll(self, child, math.max(0, math.min(range, (self._offset or 0) - delta * 48)))
    end)
    S.tree, S.treeChild, S.treeScroll = child, child, tree

    local dividerB = frame:CreateTexture(nil, "BORDER")
    dividerB:SetPoint("TOPLEFT", 622, -50)
    dividerB:SetPoint("BOTTOMLEFT", 622, 46)
    dividerB:SetWidth(1)
    dividerB:SetColorTexture(0.45, 0.34, 0.14, 0.8)
    local detailHeader = MakeText(frame, "GameFontNormal", "DETALLE")
    detailHeader:SetPoint("TOPLEFT", 640, -58)
    detailHeader:SetTextColor(1, 0.82, 0)
    S.detailTitle = MakeText(frame, "GameFontHighlight", "Selecciona un nodo")
    S.detailTitle:SetPoint("TOPLEFT", 640, -86)
    S.detailTitle:SetWidth(214)
    S.detailTitle:SetJustifyH("LEFT")
    S.detailTitle:SetNonSpaceWrap(false)
    S.detailText = MakeText(frame, "GameFontHighlightSmall", "")
    S.detailText:SetPoint("TOPLEFT", 640, -120)
    S.detailText:SetWidth(214)
    S.detailText:SetJustifyH("LEFT")
    S.detailText:SetNonSpaceWrap(false)
    S.detailChoices = MakeText(frame, "GameFontDisableSmall", "")
    S.detailChoices:SetPoint("TOPLEFT", 640, -292)
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
            S.stage = "attributes"
            RefreshAttributes()
        elseif S.stage == "attributes" then
            S.stage = "class"
            S.classId, S.subclassId, S.secondaryClassId, S.secondarySubclassId = nil, "", nil, ""
            S.primaryLevel, S.secondaryLevel, S.levelPlan, S.classConfirmed = 0, 0, {}, false
            S.pendingClassId, S.classSelectionOpen, S.classSelectionMode = nil, true, "base"
            RefreshClassStage()
        elseif S.stage == "class" then
            if S.primaryLevel + S.secondaryLevel >= CREATION_LEVEL then
                StaticPopup_Show("HARFORD_CONFIRM_CHARACTER_CREATION")
            else
                CommitClassLevel()
            end
        end
    end)
    nextButton:SetPoint("BOTTOMLEFT", 18, 16)
    S.nextButton = nextButton
end

function API.OpenPrototype(classId)
    if not (HarfordDnDRaces and HarfordDnDRaces.GetRaces and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgrounds) then
        return false, "Las opciones de origen no estan disponibles."
    end
    CreateFrameIfNeeded()
    S.stage = "race"
    if not S.raceId or not HarfordDnDRaces.GetRace(S.raceId) then
        local first = HarfordDnDRaces.GetRaces()[1]
        S.raceId = first and first.id or ""
    end
    S.subraceId = ""
    S.attributeArrays, S.selectedArray, S.attributeAssignments, S.pendingScore = nil, nil, {}, nil
    S.choiceSelections, S.pendingFeatures = {}, {}
    S.classConfirmed = false
    S.classId, S.subclassId, S.secondaryClassId, S.secondarySubclassId = nil, "", nil, ""
    S.primaryLevel, S.secondaryLevel, S.levelPlan = 0, 0, {}
    S.pendingClassId, S.classSelectionOpen, S.classSelectionMode = nil, true, "base"
    S.frame:ClearAllPoints()
    S.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if HarfordCharacterPanel and HarfordCharacterPanel.Close then HarfordCharacterPanel.Close() end
    RefreshOriginList()
    RefreshOrigin()
    S.frame:Show()
    return true
end
