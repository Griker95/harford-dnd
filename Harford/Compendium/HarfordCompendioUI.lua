local API = _G.HarfordCompendioAPI
if not API then return end

local PAGE_SIZE = 12
local GOLD = { 1.0, 0.82, 0.22 }
local PARCHMENT = { 0.78, 0.56, 0.28, 0.94 }
local DARK = { 0.03, 0.025, 0.02, 0.96 }

local state = {
    tab = "all",
    level = nil,
    page = 1,
    query = "",
    results = {},
    selectedSpell = nil,
    school = "Todas",
    className = "Todas",
    category = "Todas",
    affinity = "Todas",
    sourceGroup = "Todas",
    mineFilter = "all",
    preparedLevelFilter = nil,
    masterTab = "status",
}

local MainFrame
local DetailFrame
local CastFrame
local ClassBookFrame
local MasterFrame
local classBookSlots = {}
local classBookPage = 1
local classBookPageText
local classBookLevelButtons = {}
local slots = {}
local tabButtons = {}
local pageText
local searchBox
local titleText
local RefreshSlots
local filterButtons = {}
local mineFilterButtons = {}
local masterTabButtons = {}

local filterOptions = {
    school = { "Todas", "Abjuracion", "Adivinacion", "Conjuracion", "Encantamiento", "Evocacion", "Ilusion", "Nigromancia", "Transmutacion" },
    className = { "Todas", "Caballero de la Muerte", "Druida", "Mago", "Paladin", "Sacerdote", "Chaman", "Brujo", "Picaro Sutileza" },
    category = { "Todas", "Adivinacion", "Cambiaformas", "Coaccion", "Combate", "Comunicacion", "Control", "Coste", "Creacion", "Curacion", "Dano", "Destierro", "Desventaja", "Deteccion", "Encantamiento", "Engano", "Entorno", "Exploracion", "Invocacion", "Mejora", "Movimiento", "Negacion", "Presciencia", "Proteccion", "Ritual", "Social", "Teletransporte", "Utilidad" },
    affinity = { "Todas", "Arcano", "Fuego", "Escarcha", "Naturaleza", "Sagrado", "Sombra", "Vil", "Sangre", "Runa", "Veneno", "Psiquico", "Relampago", "Tierra", "Agua", "Aire", "Luz", "Oscuridad", "No-muerto", "Bestia", "Demonio" },
    sourceGroup = { "Todas", "DnD", "Warcraft Custom", "Harford" },
}

local mineFilterOptions = {
    { key = "all", label = "Todos" },
    { key = "known", label = "Conocidos" },
    { key = "prepared", label = "Preparados" },
    { key = "book", label = "Grimorio" },
    { key = "favorites", label = "Favoritos" },
}
local preparedLevelOptions = {
    { key = nil, label = "Todos" },
    { key = 0, label = "Trucos" },
    { key = 1, label = "Nivel 1" },
    { key = 2, label = "Nivel 2" },
    { key = 3, label = "Nivel 3" },
    { key = 4, label = "Nivel 4" },
}
local filterLabels = {
    school = "Escuela",
    className = "Clase",
    category = "Categoria",
    affinity = "Afinidad",
    sourceGroup = "Fuente",
}

local CLASS_COLORS = {
    ["Caballero de la Muerte"] = "c41e3a",
    ["Cazador"] = "abd473",
    ["Cazador de demonios"] = "a330c9",
    ["Druida"] = "ff7c0a",
    ["Evocador"] = "33937f",
    ["Guerrero"] = "c69b6d",
    ["Mago"] = "3fc7eb",
    ["Monje"] = "00ff98",
    ["Paladin"] = "f48cba",
    ["Picaro"] = "fff468",
    ["Picaro Sutileza"] = "fff468",
    ["Sacerdote"] = "ffffff",
    ["Chaman"] = "0070dd",
    ["Brujo"] = "8788ee",
}

local function ColorizeClassName(className)
    local color = CLASS_COLORS[className] or "ffd100"
    return "|cff" .. color .. className .. "|r"
end

local function JoinClassList(list)
    if not list or #list == 0 then return "" end
    local colored = {}
    for _, className in ipairs(list) do
        table.insert(colored, ColorizeClassName(className))
    end
    return table.concat(colored, ", ")
end

local function ShortText(text, maxChars)
    text = tostring(text or "")
    maxChars = maxChars or 30
    if string.len(text) <= maxChars then return text end
    if maxChars <= 3 then return string.sub(text, 1, maxChars) end
    return string.sub(text, 1, maxChars - 3) .. "..."
end

local SHORT_CLASS_NAMES = {
    ["Caballero de la Muerte"] = "Cab. de la Muerte",
    ["Cazador de demonios"] = "Caz. de demonios",
    ["Picaro Sutileza"] = "Picaro Sut.",
}

local function ColorizeShortClassName(className)
    local label = SHORT_CLASS_NAMES[className] or className
    local color = CLASS_COLORS[className] or "ffd100"
    return "|cff" .. color .. label .. "|r", label
end

local function JoinShortClassList(list, maxChars)
    if not list or #list == 0 then return "" end
    maxChars = maxChars or 34
    local lines = { "" }
    local visible = { 0 }
    local current = 1

    for _, className in ipairs(list) do
        local colored, plain = ColorizeShortClassName(className)
        local plainPart = (visible[current] == 0) and plain or (", " .. plain)
        local coloredPart = (visible[current] == 0) and colored or (", " .. colored)
        if visible[current] > 0 and (visible[current] + string.len(plainPart)) > maxChars and current < 2 then
            current = current + 1
            lines[current] = colored
            visible[current] = string.len(plain)
        else
            lines[current] = lines[current] .. coloredPart
            visible[current] = visible[current] + string.len(plainPart)
        end
    end

    return table.concat(lines, "\n")
end
local function BackdropTemplateName()
    return _G.BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function CreatePanelFrame(name, parent)
    return CreateFrame("Frame", name, parent, BackdropTemplateName())
end

local function CreateBackdroppedButton(name, parent)
    return CreateFrame("Button", name, parent, BackdropTemplateName())
end

local tabs = {
    { key = "all", label = "Todos", level = nil, icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "cantrip", label = "Trucos", level = 0, icon = "Interface\\Icons\\Spell_Holy_MagicalSentry" },
    { key = "level1", label = "Nivel 1", level = 1, icon = "Interface\\Icons\\INV_Scroll_03" },
    { key = "level2", label = "Nivel 2", level = 2, icon = "Interface\\Icons\\INV_Scroll_06" },
    { key = "level3", label = "Nivel 3", level = 3, icon = "Interface\\Icons\\INV_Scroll_05" },
    { key = "level4", label = "Nivel 4", level = 4, icon = "Interface\\Icons\\INV_Scroll_04" },
    { key = "favorites", label = "Favoritos", favoritesOnly = true, iconName = "eps_rumble_starpoints", icon = 135451 },
    { key = "mine", label = "Mis Conjuros", mineOnly = true, icon = "Interface\\Icons\\INV_Misc_Book_11" },
}

-- Lista de filtros laterales (nivel/favoritos/mis conjuros), fuente unica para la ventana suelta
-- y para la pestaña Conjuros embebida en HarfordCharacterPanel. Solo lectura.
function API.GetFilterTabs()
    return tabs
end

local function ApplyBackdrop(frame, r, g, b, a)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 24,
        edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(0.72, 0.52, 0.22, 1)
end

local function CreateFont(parent, template, point, relativeTo, relativePoint, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    fs:SetPoint(point, relativeTo, relativePoint, x, y)
    fs:SetText(text or "")
    return fs
end

local function JoinList(list)
    if not list or #list == 0 then return "" end
    return table.concat(list, ", ")
end

local function LevelLabel(level)
    if level == 0 then return "Truco" end
    return "Nivel " .. tostring(level or 0)
end

local function BoolLabel(value)
    return value and "Si" or "No"
end

local function GetTabByKey(key)
    for _, tab in ipairs(tabs) do
        if tab.key == key then return tab end
    end
end

local function SpellIsKnown(spell)
    local charDB = HarfordCompendioCharacterDB or {}
    return spell and charDB.knownSpells and charDB.knownSpells[spell.id]
end

local function SpellIsPrepared(spell)
    local charDB = HarfordCompendioCharacterDB or {}
    if not spell then return false end
    if API.IsPreparedSpell then return API.IsPreparedSpell(spell.id) end
    return charDB.preparedSpells and charDB.preparedSpells[spell.id]
end

local function SpellIsInBook(spell)
    local charDB = HarfordCompendioCharacterDB or {}
    return spell and charDB.wizardBook and charDB.wizardBook[spell.id]
end

local function SpellIsMine(spell)
    if not spell then return false end
    if API.IsMySpell and API.IsMySpell(spell.id) then return true end
    if API.IsFavorite and API.IsFavorite(spell.id) then return true end
    return SpellIsKnown(spell) or SpellIsPrepared(spell) or SpellIsInBook(spell)
end

local function SpellMatchesMineFilter(spell)
    if state.mineFilter == "known" then return SpellIsKnown(spell) end
    if state.mineFilter == "prepared" then return SpellIsPrepared(spell) end
    if state.mineFilter == "book" then return SpellIsInBook(spell) end
    if state.mineFilter == "favorites" then return API.IsFavorite and API.IsFavorite(spell.id) end
    return SpellIsMine(spell)
end

local function SetButtonEnabled(button, enabled)
    if not button then return end
    if enabled then
        button:Enable()
        local fs = button:GetFontString()
        if fs then fs:SetTextColor(1, 0.82, 0.22) end
    else
        button:Disable()
        local fs = button:GetFontString()
        if fs then fs:SetTextColor(0.45, 0.45, 0.45) end
    end
end

local dropdownAnchor
local activeDropdownKey

local function SetFilter(key, value)
    state[key] = value or "Todas"
    state.page = 1
    CloseDropDownMenus()
    RefreshSlots()
end

local function ClearFilter(key)
    SetFilter(key, "Todas")
end

local function OpenFilterDropdown(key, anchor)
    local values = filterOptions[key]
    if not values then return end
    activeDropdownKey = key
    dropdownAnchor = anchor
    UIDropDownMenu_Initialize(HarfordCompendioFilterDropdown, function(_, level)
        if not level then return end
        for _, value in ipairs(values) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = value
            info.checked = state[key] == value
            info.func = function() SetFilter(key, value) end
            UIDropDownMenu_AddButton(info, level)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, HarfordCompendioFilterDropdown, anchor, 0, 0)
end

local function RefreshFilterButtons()
    for key, button in pairs(filterButtons) do
        button:SetText((filterLabels[key] or key) .. ": " .. (state[key] or "Todas"))
    end
end

local function RefreshResults()
    local tab = GetTabByKey(state.tab) or tabs[1]
    state.results = API.FilterSpells({
        query = state.query,
        level = tab.level,
        favoritesOnly = tab.favoritesOnly,
        school = state.school,
        className = state.className,
        category = state.category,
        affinity = state.affinity,
        sourceGroup = state.sourceGroup,
    })
    if tab.mineOnly then
        local mine = {}
        for _, spell in ipairs(state.results) do
            if SpellMatchesMineFilter(spell) then table.insert(mine, spell) end
        end
        state.results = mine
    end
    local maxPage = math.max(1, math.ceil(#state.results / PAGE_SIZE))
    if state.page > maxPage then state.page = maxPage end
    if state.page < 1 then state.page = 1 end
end

local function UpdateMineFilterButtons()
    local show = false
    for key, button in pairs(mineFilterButtons) do
        button:SetShown(show)
        if show then
            local active = key == state.mineFilter
            local font = button:GetFontString()
            if font then font:SetTextColor(active and 1 or 0.95, active and 1 or 0.82, active and 0.55 or 0.22) end
        end
    end
end

local function UpdateTabs()
    for key, button in pairs(tabButtons) do
        local active = key == state.tab
        button:SetBackdropColor(active and 0.95 or 0.22, active and 0.65 or 0.14, active and 0.12 or 0.05, 1)
        button.label:SetTextColor(active and 1 or 0.95, active and 1 or 0.82, active and 0.55 or 0.22, 1)
    end
    UpdateMineFilterButtons()
end

-- Habilita/deshabilita "Lanzar Hechizo" segun haya mana suficiente (API.CanCast). Se re-evalua
-- al abrir el detalle y ante cualquier cambio de recurso (hook de AdjustResourceCurrent).
local function RefreshDetailCastState()
    if not (DetailFrame and DetailFrame.launch and DetailFrame:IsShown()) then return end
    local spell = state.selectedSpell
    if not spell then return end
    local enabled = (not API.CanCast) or (API.CanCast(spell.id) ~= false)  -- mana suficiente
    if enabled and API.SpellNeedsTarget and API.SpellNeedsTarget(spell) then
        -- Ataque directo: ademas requiere objetivo valido (no uno mismo).
        local hasTarget = UnitExists and UnitExists("target")
            and not (UnitIsUnit and UnitIsUnit("target", "player"))
        enabled = hasTarget and true or false
    end
    DetailFrame.launch:SetEnabled(enabled and true or false)
end

local function ShowDetail(spell)
    state.selectedSpell = spell
    if not DetailFrame then return end
    DetailFrame.spellName:SetText(spell.name)
    DetailFrame.meta:SetText(LevelLabel(spell.level) .. " - " .. (spell.school or "Sin escuela") .. " - " .. (spell.affinity or "Sin afinidad"))
    DetailFrame.icon:SetTexture(API.GetSpellIcon(spell))
    if API.GetSpellCostMode and API.GetSpellCostMode() == "slots" then
        local current, maximum = 0, 0
        if HarfordDnDMana and HarfordDnDMana.GetSpellSlotCurrent then
            current, maximum = HarfordDnDMana.GetSpellSlotCurrent(spell.level)
        end
        DetailFrame.cost:SetText(spell.level > 0
            and ("Espacios nivel " .. tostring(spell.level) .. ": " .. tostring(current) .. "/" .. tostring(maximum))
            or "Truco: sin coste")
    else
        DetailFrame.cost:SetText("Coste de mana: " .. tostring(API.GetManaCost(spell.level)))
    end
    DetailFrame.cast:SetText("Tiempo: " .. (spell.castingTime or "-"))
    DetailFrame.range:SetText("Alcance: " .. (spell.range or "-"))
    DetailFrame.components:SetText("Componentes: " .. ((spell.components and spell.components ~= "" and spell.components) or "-"))
    DetailFrame.duration:SetText("Duracion: " .. (spell.duration or "-"))
    DetailFrame.flags:SetText("Concentracion: " .. BoolLabel(spell.concentration) .. "    Ritual: " .. BoolLabel(spell.ritual))
    DetailFrame.classes:SetText("Clases: " .. JoinClassList(spell.classes))
    DetailFrame.categories:SetText("Categorias: " .. JoinList(spell.categories))
    DetailFrame.attack:SetText("Ataque/Salvacion: " .. ((spell.attack and spell.attack ~= "" and spell.attack) or (spell.savingThrow and spell.savingThrow ~= "" and spell.savingThrow) or "-"))
    DetailFrame.damage:SetText("Dano: " .. ((spell.damage and spell.damage ~= "" and spell.damage) or "-"))
    DetailFrame.description:SetText("Descripcion:\n" .. (spell.description or "-"))
    DetailFrame.mechanics:SetText("Efecto mecanico:\n" .. (spell.mechanics or "-"))
    DetailFrame.role:SetText("Notas de rol:\n" .. (spell.roleNotes or "-"))
    DetailFrame.source:SetText("Fuente: " .. (spell.sourceGroup or "-"))
    -- Favorito/Preparado/Mi Conjuro viven ahora en el dropdown del boton "Ajuste".
    DetailFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    DetailFrame:SetFrameLevel(80)
    DetailFrame:Show()
    DetailFrame:Raise()
    RefreshDetailCastState()
end

function RefreshSlots()
    RefreshResults()
    UpdateTabs()
    RefreshFilterButtons()
    UpdateMineFilterButtons()
    local startIndex = (state.page - 1) * PAGE_SIZE + 1
    for i = 1, PAGE_SIZE do
        local slot = slots[i]
        local spell = state.results[startIndex + i - 1]
        slot.spell = spell
        if spell then
            slot:Show()
            slot.icon:SetTexture(API.GetSpellIcon(spell))
            slot.name:SetText(ShortText(spell.name, 32))
            slot.meta:SetText(ShortText(LevelLabel(spell.level) .. " - " .. (spell.school or "-") .. " - " .. (spell.affinity or "-"), 42))
            slot.classes:SetText(JoinShortClassList(spell.classes, 34))
            slot.favorite:SetText(API.IsFavorite(spell.id) and "*" or "")
        else
            slot:Hide()
        end
    end
    local maxPage = math.max(1, math.ceil(#state.results / PAGE_SIZE))
    pageText:SetText("Pagina " .. state.page .. " / " .. maxPage .. "  -  " .. #state.results .. " conjuros")
    titleText:SetText("Compendio Harford")
end

local function CastOptions()
    local options = {}
    if CastFrame and CastFrame.castLevel and CastFrame.castLevel > 0 then
        options.castLevel = CastFrame.castLevel
    end
    return options
end

local function ShowCastFrame(spell, requestedLevel)
    if not CastFrame then return end
    local baseLevel = math.max(0, tonumber(spell.level) or 0)
    local maxLevel = API.GetMaxCastLevel and API.GetMaxCastLevel(spell) or baseLevel
    local castLevel = baseLevel <= 0 and 0 or math.max(baseLevel, math.min(maxLevel,
        tonumber(requestedLevel) or CastFrame.castLevel or baseLevel))
    local options = castLevel > 0 and { castLevel = castLevel } or {}
    local cost = API.GetSpellCost and API.GetSpellCost(spell, options) or API.GetManaCost(castLevel)
    local manaCur = API.GetManaCurrent and API.GetManaCurrent() or 0
    local manaMax = API.GetManaMax and API.GetManaMax() or 0
    local canCast, reason = API.CanCast and API.CanCast(spell.id, options)
    if canCast == nil then canCast = true end
    local costText
    if API.GetSpellCostMode and API.GetSpellCostMode() == "slots" then
        local current, maximum = 0, 0
        if HarfordDnDMana and HarfordDnDMana.GetSpellSlotCurrent then
            current, maximum = HarfordDnDMana.GetSpellSlotCurrent(castLevel)
        end
        costText = castLevel > 0
            and ("Coste si tiene exito: 1 espacio de nivel " .. tostring(castLevel)
                .. " (" .. tostring(current) .. "/" .. tostring(maximum) .. ")")
            or "Truco: sin coste"
    else
        costText = "Coste si tiene exito: " .. tostring(cost) .. " mana\n"
            .. "Mana actual: " .. tostring(manaCur) .. " / " .. tostring(manaMax)
    end
    CastFrame.spell = spell
    CastFrame.castLevel = castLevel
    CastFrame.title:SetText("Lanzar: " .. spell.name)
    CastFrame.levelText:SetText(castLevel > 0 and ("Nivel de lanzamiento: " .. tostring(castLevel)) or "Truco")
    CastFrame.levelDown:SetShown(baseLevel > 0)
    CastFrame.levelUp:SetShown(baseLevel > 0)
    SetButtonEnabled(CastFrame.levelDown, castLevel > baseLevel)
    SetButtonEnabled(CastFrame.levelUp, castLevel < maxLevel)
    CastFrame.summary:SetText(
        costText .. "\n" ..
        ((not canCast and reason) and ("Estado: " .. tostring(reason) .. "\n") or "") ..
        "Ataque/Salvacion: " .. ((spell.attack and spell.attack ~= "" and spell.attack) or (spell.savingThrow and spell.savingThrow ~= "" and spell.savingThrow) or "-") .. "\n" ..
        "Dano: " .. ((spell.damage and spell.damage ~= "" and spell.damage) or "-") .. "\n" ..
        "Efecto: " .. (spell.mechanics or "-")
    )
    CastFrame.ritual:SetShown(spell.ritual == true)
    SetButtonEnabled(CastFrame.success, canCast == true)
    CastFrame:SetFrameLevel(90)
    CastFrame:Show()
    CastFrame:Raise()
end

local function PrintMessage(text)
    if DEFAULT_CHAT_FRAME then
        HarfordChat.Print(text)
    end
end


local function TRP3Color(name, fallbackHex)
    if not TRP3_API or not TRP3_API.Ellyb then return nil end
    local manager = TRP3_API.Ellyb.ColorManager
    if manager and manager[name] then return manager[name] end
    if fallbackHex and TRP3_API.Ellyb.Color then return TRP3_API.Ellyb.Color(fallbackHex) end
    return nil
end

local function AddTRP3Line(lines, label, value, color)
    if value == nil or value == "" then value = "-" end
    lines:AddLine(label .. tostring(value), color)
end

local function BuildTRP3SpellTooltipData(spell)
    return {
        id = spell.id,
        name = spell.name or "Conjuro",
        icon = API.GetSpellIcon(spell),
        meta = LevelLabel(spell.level) .. " - " .. (spell.school or "Sin escuela") .. " - " .. (spell.affinity or "Sin afinidad"),
        mana = tostring(API.GetManaCost(spell.level)),
        castTime = spell.castingTime or spell.castTime or "-",
        range = spell.range or "-",
        components = (spell.components and spell.components ~= "" and spell.components) or "-",
        duration = spell.duration or "-",
        concentration = BoolLabel(spell.concentration == true),
        ritual = BoolLabel(spell.ritual == true),
        classes = JoinList(spell.classes),
        categories = JoinList(spell.categories),
        attack = (spell.attack and spell.attack ~= "" and spell.attack) or (spell.savingThrow and spell.savingThrow ~= "" and spell.savingThrow) or "-",
        damage = (spell.damage and spell.damage ~= "" and spell.damage) or "-",
        description = spell.description or "-",
        mechanics = spell.mechanics or "-",
        roleNotes = spell.roleNotes or "-",
        source = spell.sourceGroup or spell.source or "-",
    }
end

local function EnsureTRP3SpellChatLinkModule()
    if API.TRP3SpellChatLinkModule then return API.TRP3SpellChatLinkModule end
    if not TRP3_API or not TRP3_API.ChatLinks or not TRP3_API.ChatLinkTooltipLines then return nil end

    local moduleID = "COMPENDIO_HARFORD_SPELL"
    local module = TRP3_API.ChatLinks.GetModuleByID and TRP3_API.ChatLinks:GetModuleByID(moduleID)
    if not module then
        local ok, created = pcall(function()
            return TRP3_API.ChatLinks:InstantiateModule("Conjuro Harford", moduleID)
        end)
        if ok then module = created end
    end
    if not module then return nil end

    function module:GetLinkData(spell)
        if not spell then return "Conjuro", { name = "Conjuro" } end
        local data = BuildTRP3SpellTooltipData(spell)
        return data.name, data
    end

    function module:GetTooltipLines(data)
        local lines = TRP3_API.ChatLinkTooltipLines()
        local yellow = TRP3Color("YELLOW", "ffff00")
        local orange = TRP3Color("ORANGE", "ff9900")
        local white = TRP3Color("WHITE", "ffffff")
        local gray = TRP3Color("GREY", "aaaaaa") or white
        local icon = data.icon and ("|T" .. tostring(data.icon) .. ":20:20:0:0|t ") or ""

        lines:SetTitle(icon .. (data.name or "Conjuro"))
        lines:AddLine(data.meta or "", yellow)
        lines:AddLine(" ")
        AddTRP3Line(lines, "Coste de mana: ", data.mana, white)
        AddTRP3Line(lines, "Tiempo: ", data.castTime, white)
        AddTRP3Line(lines, "Alcance: ", data.range, white)
        AddTRP3Line(lines, "Componentes: ", data.components, white)
        AddTRP3Line(lines, "Duracion: ", data.duration, white)
        lines:AddDoubleLine("Concentracion: " .. (data.concentration or "No"), "Ritual: " .. (data.ritual or "No"), white, white)
        AddTRP3Line(lines, "Clases: ", data.classes, white)
        AddTRP3Line(lines, "Categorias: ", data.categories, white)
        AddTRP3Line(lines, "Ataque/Salvacion: ", data.attack, white)
        AddTRP3Line(lines, "Dano: ", data.damage, white)
        lines:AddLine(" ")
        lines:AddLine("Descripcion:", orange)
        lines:AddLine(data.description or "-", white)
        lines:AddLine(" ")
        lines:AddLine("Efecto mecanico:", orange)
        lines:AddLine(data.mechanics or "-", white)
        if data.roleNotes and data.roleNotes ~= "" and data.roleNotes ~= "-" then
            lines:AddLine(" ")
            lines:AddLine("Notas de rol:", orange)
            lines:AddLine(data.roleNotes, white)
        end
        lines:AddLine(" ")
        lines:AddLine("Fuente: " .. (data.source or "-"), gray)
        return lines
    end

    API.TRP3SpellChatLinkModule = module
    return module
end

local function InsertTRP3SpellChatLink(spell)
    local module = EnsureTRP3SpellChatLinkModule()
    if not module then
        PrintMessage("TRP3 no esta disponible para crear el enlace publico del conjuro.")
        return
    end
    module:InsertLink(spell)
end

-- Cadena del enlace TRP3 clicable del conjuro (mismo formato que GetAbilityChatLink del libro),
-- para incrustarla en los anuncios de lanzamiento. Fallback no clicable si TRP3 no esta.
function API.GetSpellChatLink(spell)
    if not spell then return "" end
    local nm = tostring(spell.name or "Conjuro")
    local module = EnsureTRP3SpellChatLinkModule()
    if module and TRP3_API and TRP3_API.ChatLink then
        local ok, text = pcall(function()
            local name, data = module:GetLinkData(spell)
            local link = TRP3_API.ChatLink(name, data, module:GetID())
            local id = link:GetIdentifier()
            local player = (TRP3_API.globals and TRP3_API.globals.player_id)
                or (GetUnitName and GetUnitName("player", true))
                or UnitName("player") or "?"
            return "|cffffd100|Htotalrp3:" .. player .. ":" .. id .. "|h[" .. name .. "]|h|r"
        end)
        if ok and type(text) == "string" then return text end
    end
    return "|cff66bbff[" .. nm .. "]|r"
end

local function HandleSpellSlotClick(spell, button)
    if not spell then return end
    if button == "LeftButton" and IsControlKeyDown and IsControlKeyDown() then
        InsertTRP3SpellChatLink(spell)
    else
        ShowDetail(spell)
    end
end

-- Dropdown del boton "Ajuste": unifica Favorito / Preparado / Mi Conjuro como toggles checkables.
local function AdjustMenu_Init(_, level)
    local spell = state.selectedSpell
    if not spell then return end
    local function add(text, isOnFn, toggleFn)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.isNotRadio = true
        info.keepShownOnClick = true
        info.checked = isOnFn  -- funcion: el check se reevalua en vivo al togglear
        info.func = function()
            if toggleFn then toggleFn(spell.id) end
            RefreshSlots()
            if ClassBookFrame and ClassBookFrame:IsShown() then RefreshClassBookFrame() end
        end
        UIDropDownMenu_AddButton(info, level)
    end
    add("Favorito", function() return API.IsFavorite(spell.id) end, API.ToggleFavorite)
    add("Preparado", function() return SpellIsPrepared(spell) end, API.TogglePreparedSpell)
    add("Mi Conjuro", function() return SpellIsMine(spell) end, API.ToggleMySpell)
end

local function CreateDetailFrame()
    DetailFrame = CreatePanelFrame("HarfordCompendioDetailFrame", UIParent)
    DetailFrame:SetSize(680, 640)
    DetailFrame:SetPoint("CENTER")
    DetailFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    DetailFrame:SetFrameLevel(80)
    DetailFrame:Hide()
    ApplyBackdrop(DetailFrame, PARCHMENT[1], PARCHMENT[2], PARCHMENT[3], PARCHMENT[4])
    -- Fondo plano (el pergamino del libro tiene bordes horneados y se ve con costuras al estirarlo).
    -- Cubre todo el interior por debajo de la barra de titulo.
    -- Pergamino en espejo (U invertida), estirado a todo el frame hasta arriba.
    -- Capa BORDER (no BACKGROUND): asi queda POR ENCIMA del fondo translucido oscuro del
    -- ApplyBackdrop (que antes lo oscurecia) y POR DEBAJO del icono/texto (ARTWORK/OVERLAY).
    local detailBg = DetailFrame:CreateTexture(nil, "BORDER")
    detailBg:SetPoint("TOPLEFT", DetailFrame, "TOPLEFT", 8, -6)
    detailBg:SetPoint("BOTTOMRIGHT", DetailFrame, "BOTTOMRIGHT", -8, 8)
    detailBg:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
    detailBg:SetTexCoord(1, 0, 0, 1)
    DetailFrame:SetMovable(true)
    DetailFrame:EnableMouse(true)
    DetailFrame:RegisterForDrag("LeftButton")
    DetailFrame:SetScript("OnDragStart", DetailFrame.StartMoving)
    DetailFrame:SetScript("OnDragStop", DetailFrame.StopMovingOrSizing)
    local detailClose = CreateFrame("Button", nil, DetailFrame, "UIPanelCloseButton")
    detailClose:SetPoint("TOPRIGHT", DetailFrame, "TOPRIGHT", -4, -4)

    DetailFrame.icon = DetailFrame:CreateTexture(nil, "ARTWORK")
    DetailFrame.icon:SetSize(64, 64)
    DetailFrame.icon:SetPoint("TOPLEFT", 26, -34)

    DetailFrame.spellName = CreateFont(DetailFrame, "GameFontNormalLarge", "TOPLEFT", DetailFrame, "TOPLEFT", 102, -36)
    DetailFrame.spellName:SetTextColor(0.05, 0.025, 0.01, 1)
    DetailFrame.meta = CreateFont(DetailFrame, "GameFontHighlightSmall", "TOPLEFT", DetailFrame.spellName, "BOTTOMLEFT", 0, -6)
    DetailFrame.meta:SetTextColor(0.12, 0.06, 0.02, 1)

    DetailFrame.cost = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame, "TOPLEFT", 28, -118)
    DetailFrame.cast = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.cost, "BOTTOMLEFT", 0, -6)
    DetailFrame.range = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.cast, "BOTTOMLEFT", 0, -6)
    DetailFrame.components = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.range, "BOTTOMLEFT", 0, -6)
    DetailFrame.duration = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.components, "BOTTOMLEFT", 0, -6)
    DetailFrame.flags = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.duration, "BOTTOMLEFT", 0, -6)
    DetailFrame.classes = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.flags, "BOTTOMLEFT", 0, -10)
    DetailFrame.categories = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.classes, "BOTTOMLEFT", 0, -6)
    DetailFrame.attack = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.categories, "BOTTOMLEFT", 0, -10)
    DetailFrame.damage = CreateFont(DetailFrame, "GameFontHighlight", "TOPLEFT", DetailFrame.attack, "BOTTOMLEFT", 0, -6)
    for _, fs in ipairs({ DetailFrame.cost, DetailFrame.cast, DetailFrame.range, DetailFrame.duration, DetailFrame.components, DetailFrame.flags, DetailFrame.classes, DetailFrame.categories, DetailFrame.attack, DetailFrame.damage }) do
        fs:SetTextColor(0.03, 0.018, 0.01, 1)
    end

    local function BodyText(anchor, y)
        local fs = DetailFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
        fs:SetWidth(620)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.03, 0.018, 0.01, 1)
        return fs
    end
    DetailFrame.description = BodyText(DetailFrame.damage, -10)
    DetailFrame.mechanics = BodyText(DetailFrame.description, -10)
    DetailFrame.role = BodyText(DetailFrame.mechanics, -10)
    DetailFrame.source = CreateFont(DetailFrame, "GameFontHighlightSmall", "BOTTOMLEFT", DetailFrame, "BOTTOMLEFT", 28, 52)
    DetailFrame.source:SetTextColor(0.08, 0.04, 0.015, 1)
    -- Fila de botones: Lanzar Hechizo | Enlace Chat | Ajuste (dropdown Favorito/Preparado/Mi Conjuro).
    DetailFrame.launch = CreateFrame("Button", nil, DetailFrame, "UIPanelButtonTemplate")
    DetailFrame.launch:SetSize(140, 28)
    DetailFrame.launch:SetPoint("BOTTOMLEFT", DetailFrame, "BOTTOMLEFT", 28, 18)
    DetailFrame.launch:SetText("Lanzar Hechizo")
    DetailFrame.launch:SetScript("OnClick", function()
        if state.selectedSpell then ShowCastFrame(state.selectedSpell) end
    end)

    DetailFrame.chat = CreateFrame("Button", nil, DetailFrame, "UIPanelButtonTemplate")
    DetailFrame.chat:SetSize(120, 28)
    DetailFrame.chat:SetPoint("LEFT", DetailFrame.launch, "RIGHT", 10, 0)
    DetailFrame.chat:SetText("Enlace Chat")
    DetailFrame.chat:SetScript("OnClick", function()
        if state.selectedSpell then InsertTRP3SpellChatLink(state.selectedSpell) end
    end)

    DetailFrame.adjustDropdown = CreateFrame("Frame", "HarfordCompendioAdjustDropdown", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(DetailFrame.adjustDropdown, AdjustMenu_Init, "MENU")
    DetailFrame.adjust = CreateFrame("Button", nil, DetailFrame, "UIPanelButtonTemplate")
    DetailFrame.adjust:SetSize(100, 28)
    DetailFrame.adjust:SetPoint("LEFT", DetailFrame.chat, "RIGHT", 10, 0)
    DetailFrame.adjust:SetText("Ajuste")
    DetailFrame.adjust:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, DetailFrame.adjustDropdown, self, 0, 0)
    end)

    -- Re-evalua "Lanzar Hechizo" ante CUALQUIER cambio de recurso local (gasto al lanzar, +/- de la
    -- UI de recursos, descanso, ajuste manual). Todos terminan en ScheduleMyResourceBroadcast ->
    -- HarfordUnitFrames.Refresh(), el endpoint universal; lo enganchamos. Sin polling.
    if not API._castStateHooked and hooksecurefunc then
        if HarfordUnitFrames and HarfordUnitFrames.Refresh then
            API._castStateHooked = true
            hooksecurefunc(HarfordUnitFrames, "Refresh", function() RefreshDetailCastState() end)
        elseif HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
            API._castStateHooked = true
            hooksecurefunc(HarfordDnDStore, "AdjustResourceCurrent", function() RefreshDetailCastState() end)
        end
    end

    -- Re-evalua el boton al cambiar de objetivo, pero solo mientras el detalle esta visible.
    DetailFrame:SetScript("OnEvent", function() RefreshDetailCastState() end)
    DetailFrame:HookScript("OnShow", function(self) self:RegisterEvent("PLAYER_TARGET_CHANGED") end)
    DetailFrame:HookScript("OnHide", function(self) self:UnregisterEvent("PLAYER_TARGET_CHANGED") end)
end

local function CreateCastFrame()
    CastFrame = CreatePanelFrame("HarfordCompendioCastFrame", UIParent)
    CastFrame:SetSize(440, 340)
    CastFrame:SetPoint("CENTER", 0, 30)
    CastFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    CastFrame:SetFrameLevel(90)
    CastFrame:Hide()
    ApplyBackdrop(CastFrame, DARK[1], DARK[2], DARK[3], 0.98)
    local castBg = CastFrame:CreateTexture(nil, "BACKGROUND")
    castBg:SetPoint("TOPLEFT", CastFrame, "TOPLEFT", 10, -28)
    castBg:SetPoint("BOTTOMRIGHT", CastFrame, "BOTTOMRIGHT", -10, 10)
    castBg:SetColorTexture(0.03, 0.025, 0.02, 0.98)
    CastFrame:SetMovable(true)
    CastFrame:EnableMouse(true)
    CastFrame:RegisterForDrag("LeftButton")
    CastFrame:SetScript("OnDragStart", CastFrame.StartMoving)
    CastFrame:SetScript("OnDragStop", CastFrame.StopMovingOrSizing)
    local castClose = CreateFrame("Button", nil, CastFrame, "UIPanelCloseButton")
    castClose:SetPoint("TOPRIGHT", CastFrame, "TOPRIGHT", -4, -4)

    CastFrame.title = CreateFont(CastFrame, "GameFontNormalLarge", "TOP", CastFrame, "TOP", 0, -32)
    CastFrame.summary = CastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    CastFrame.summary:SetPoint("TOPLEFT", 24, -64)
    CastFrame.summary:SetWidth(392)
    CastFrame.summary:SetJustifyH("LEFT")
    CastFrame.summary:SetJustifyV("TOP")

    CastFrame.levelText = CreateFont(CastFrame, "GameFontHighlight", "TOP", CastFrame, "TOP", 0, -62)
    CastFrame.levelText:SetTextColor(1, 0.82, 0, 1)
    CastFrame.levelDown = CreateFrame("Button", nil, CastFrame, "UIPanelButtonTemplate")
    CastFrame.levelDown:SetSize(26, 22)
    CastFrame.levelDown:SetPoint("RIGHT", CastFrame.levelText, "LEFT", -10, 0)
    CastFrame.levelDown:SetText("-")
    CastFrame.levelDown:SetScript("OnClick", function()
        if CastFrame.spell then ShowCastFrame(CastFrame.spell, (CastFrame.castLevel or 0) - 1) end
    end)
    CastFrame.levelUp = CreateFrame("Button", nil, CastFrame, "UIPanelButtonTemplate")
    CastFrame.levelUp:SetSize(26, 22)
    CastFrame.levelUp:SetPoint("LEFT", CastFrame.levelText, "RIGHT", 10, 0)
    CastFrame.levelUp:SetText("+")
    CastFrame.levelUp:SetScript("OnClick", function()
        if CastFrame.spell then ShowCastFrame(CastFrame.spell, (CastFrame.castLevel or 0) + 1) end
    end)
    CastFrame.summary:ClearAllPoints()
    CastFrame.summary:SetPoint("TOPLEFT", 24, -92)

    CastFrame.announce = CreateFrame("Button", nil, CastFrame, "UIPanelButtonTemplate")
    CastFrame.announce:SetSize(120, 28)
    CastFrame.announce:SetPoint("BOTTOMLEFT", 22, 22)
    CastFrame.announce:SetText("Anunciar Intento")
    CastFrame.announce:SetScript("OnClick", function()
        if CastFrame.spell and API.AnnounceCastAttempt then
            local ok, err = API.AnnounceCastAttempt(CastFrame.spell.id)
            if not ok then PrintMessage(tostring(err or "no se pudo anunciar")) end
        end
    end)

    CastFrame.success = CreateFrame("Button", nil, CastFrame, "UIPanelButtonTemplate")
    CastFrame.success:SetSize(120, 28)
    CastFrame.success:SetPoint("LEFT", CastFrame.announce, "RIGHT", 10, 0)
    CastFrame.success:SetText("Confirmar Exito")
    CastFrame.success:SetScript("OnClick", function()
        if CastFrame.spell then
            local resolver = API.ResolveCast or API.ConfirmCast
            local ok, costOrErr = resolver(CastFrame.spell.id, CastOptions())
            if not ok then
                PrintMessage(tostring(costOrErr or "no se pudo lanzar"))
                ShowCastFrame(CastFrame.spell)
                return
            end
        end
        CastFrame:Hide()
    end)

    CastFrame.cancel = CreateFrame("Button", nil, CastFrame, "UIPanelButtonTemplate")
    CastFrame.cancel:SetSize(110, 28)
    CastFrame.cancel:SetPoint("LEFT", CastFrame.success, "RIGHT", 10, 0)
    CastFrame.cancel:SetText("Fallo / Cancelar")
    CastFrame.cancel:SetScript("OnClick", function()
        if CastFrame.spell then PrintMessage(CastFrame.spell.name .. " no tiene exito. Mana no consumido.") end
        CastFrame:Hide()
    end)

    CastFrame.ritual = CreateFrame("Button", nil, CastFrame, "UIPanelButtonTemplate")
    CastFrame.ritual:SetSize(150, 24)
    CastFrame.ritual:SetPoint("BOTTOM", CastFrame, "BOTTOM", 0, 58)
    CastFrame.ritual:SetText("Lanzar como Ritual")
    CastFrame.ritual:SetScript("OnClick", function()
        if CastFrame.spell and (API.ResolveCast or API.ConfirmCast) then
            local resolver = API.ResolveCast or API.ConfirmCast
            local options = CastOptions()
            options.ritual = true
            local ok, err = resolver(CastFrame.spell.id, options)
            if not ok then
                PrintMessage(tostring(err or "no se pudo lanzar el ritual"))
                return
            end
            CastFrame:Hide()
        end
    end)
end

local function GetClassBookResults()
    local base = API.FilterSpells({
        query = state.query,
        school = state.school,
        className = state.className,
        category = state.category,
        affinity = state.affinity,
        sourceGroup = state.sourceGroup,
    })
    local results = {}
    for _, spell in ipairs(base) do
        if SpellMatchesMineFilter(spell) and (state.mineFilter ~= "prepared" or state.preparedLevelFilter == nil or spell.level == state.preparedLevelFilter) then table.insert(results, spell) end
    end
    return results
end

local function UpdatePreparedLevelButtons()
    local show = ClassBookFrame and ClassBookFrame:IsShown() and state.mineFilter == "prepared"
    for key, button in pairs(classBookLevelButtons) do
        button:SetShown(show)
        if show then
            local active = key == tostring(state.preparedLevelFilter or "all")
            local font = button:GetFontString()
            if font then font:SetTextColor(active and 1 or 0.95, active and 1 or 0.82, active and 0.55 or 0.22) end
        end
    end
end
local function RefreshClassBookFrame()
    if not ClassBookFrame then return end
    UpdatePreparedLevelButtons()
    local results = GetClassBookResults()
    local maxPage = math.max(1, math.ceil(#results / PAGE_SIZE))
    if classBookPage > maxPage then classBookPage = maxPage end
    if classBookPage < 1 then classBookPage = 1 end
    local startIndex = (classBookPage - 1) * PAGE_SIZE + 1
    for i = 1, PAGE_SIZE do
        local slot = classBookSlots[i]
        local spell = results[startIndex + i - 1]
        slot.spell = spell
        if spell then
            slot:Show()
            slot.icon:SetTexture(API.GetSpellIcon(spell))
            slot.name:SetText(ShortText(spell.name, 30))
            slot.meta:SetText(ShortText(LevelLabel(spell.level) .. " - " .. (spell.school or "-") .. " - " .. (spell.affinity or "-"), 40))
            slot.classes:SetText(JoinShortClassList(spell.classes, 32))
            slot.favorite:SetText(API.IsFavorite(spell.id) and "*" or "")
        else
            slot:Hide()
        end
    end
    classBookPageText:SetText("Pagina " .. classBookPage .. " / " .. maxPage .. "  -  " .. #results .. " conjuros")
end

local function CreateClassBookFrame()
    ClassBookFrame = CreatePanelFrame("HarfordCompendioClassBookFrame", UIParent)
    ClassBookFrame:SetSize(720, 560)
    ClassBookFrame:SetPoint("CENTER", 30, 10)
    ClassBookFrame:SetFrameStrata("DIALOG")
    ClassBookFrame:SetFrameLevel(20)
    ClassBookFrame:Hide()
    ClassBookFrame:SetMovable(true)
    ClassBookFrame:EnableMouse(true)
    ClassBookFrame:RegisterForDrag("LeftButton")
    ClassBookFrame:SetScript("OnDragStart", ClassBookFrame.StartMoving)
    ClassBookFrame:SetScript("OnDragStop", ClassBookFrame.StopMovingOrSizing)
    ApplyBackdrop(ClassBookFrame, DARK[1], DARK[2], DARK[3], DARK[4])

    local close = CreateFrame("Button", nil, ClassBookFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", ClassBookFrame, "TOPRIGHT", -4, -4)
    local title = CreateFont(ClassBookFrame, "GameFontNormalLarge", "TOP", ClassBookFrame, "TOP", 0, -16, "Libro de Clase")
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1)

    local content = CreatePanelFrame(nil, ClassBookFrame)
    content:SetSize(668, 470)
    content:SetPoint("TOP", ClassBookFrame, "TOP", 0, -54)
    ApplyBackdrop(content, PARCHMENT[1], PARCHMENT[2], PARCHMENT[3], PARCHMENT[4])
    local bg = content:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    bg:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    bg:SetColorTexture(0.68, 0.48, 0.23, 0.92)

    for i, option in ipairs(mineFilterOptions) do
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(118, 22)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 34 + ((i - 1) * 124), -20)
        btn:SetText(option.label)
        btn:SetScript("OnClick", function()
            state.mineFilter = option.key
            if option.key ~= "prepared" then state.preparedLevelFilter = nil end
            classBookPage = 1
            RefreshClassBookFrame()
        end)
    end

    for i, option in ipairs(preparedLevelOptions) do
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(96, 20)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 34 + ((i - 1) * 102), -46)
        btn:SetText(option.label)
        btn:SetScript("OnClick", function()
            state.preparedLevelFilter = option.key
            classBookPage = 1
            RefreshClassBookFrame()
        end)
        btn:Hide()
        classBookLevelButtons[tostring(option.key or "all")] = btn
    end

    local grid = CreateFrame("Frame", nil, content)

    grid:SetSize(620, 354)
    grid:SetPoint("TOP", content, "TOP", 0, -86)
    for i = 1, PAGE_SIZE do
        local slot = CreateBackdroppedButton(nil, grid)
        slot:SetSize(304, 52)
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        slot:SetPoint("TOPLEFT", grid, "TOPLEFT", col * 312, -row * 58)
        ApplyBackdrop(slot, 0.18, 0.12, 0.05, 0.9)
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(36, 36)
        slot.icon:SetPoint("LEFT", 8, 0)
        slot.name = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slot.name:SetPoint("TOPLEFT", slot.icon, "TOPRIGHT", 8, 1)
        slot.name:SetWidth(242)
        slot.name:SetHeight(12)
        slot.name:SetJustifyH("LEFT")
        if slot.name.SetFont then slot.name:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE") end
        slot.name:SetWordWrap(false)
        if slot.name.SetMaxLines then slot.name:SetMaxLines(1) end
        slot.meta = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        slot.meta:SetPoint("TOPLEFT", slot.name, "BOTTOMLEFT", 0, 2)
        slot.meta:SetWidth(242)
        slot.meta:SetHeight(11)
        slot.meta:SetJustifyH("LEFT")
        if slot.meta.SetFont then slot.meta:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE") end
        slot.meta:SetWordWrap(false)
        if slot.meta.SetMaxLines then slot.meta:SetMaxLines(1) end
        slot.classes = slot:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        slot.classes:SetPoint("TOPLEFT", slot.meta, "BOTTOMLEFT", 0, 1)
        slot.classes:SetWidth(242)
        slot.classes:SetHeight(18)
        slot.classes:SetJustifyH("LEFT")
        if slot.classes.SetFont then slot.classes:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE") end
        if slot.classes.SetSpacing then slot.classes:SetSpacing(-3) end
        slot.classes:SetWordWrap(true)
        if slot.classes.SetMaxLines then slot.classes:SetMaxLines(2) end
        slot.favorite = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slot.favorite:SetPoint("RIGHT", slot, "RIGHT", -10, 0)
        slot.favorite:SetTextColor(1, 0.85, 0.1, 1)
        slot:RegisterForClicks("LeftButtonUp")
        slot:SetScript("OnClick", function(self, button)
            HandleSpellSlotClick(self.spell, button)
        end)
        classBookSlots[i] = slot
    end

    local prev = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    prev:SetSize(34, 26)
    prev:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -76, 8)
    prev:SetText("<")
    prev:SetScript("OnClick", function()
        classBookPage = math.max(1, classBookPage - 1)
        RefreshClassBookFrame()
    end)
    local next = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    next:SetSize(34, 26)
    next:SetPoint("LEFT", prev, "RIGHT", 8, 0)
    next:SetText(">")
    next:SetScript("OnClick", function()
        local maxPage = math.max(1, math.ceil(#GetClassBookResults() / PAGE_SIZE))
        classBookPage = math.min(maxPage, classBookPage + 1)
        RefreshClassBookFrame()
    end)
    classBookPageText = CreateFont(content, "GameFontHighlightSmall", "BOTTOMLEFT", content, "BOTTOMLEFT", 28, 10, "Pagina 1 / 1")
    classBookPageText:SetTextColor(0.16, 0.08, 0.03, 1)
end

local function ShowClassBookFrame()
    if not ClassBookFrame then CreateClassBookFrame() end
    classBookPage = 1
    ClassBookFrame:Show()
    RefreshClassBookFrame()
end

local function IsDMModeActive()
    return HarfordAuthority and HarfordAuthority.CanUseDMTools
        and HarfordAuthority.CanUseDMTools() == true
end

local function GetPhaseRankLabel()
    -- La senal de rango sale solo de HarfordAuthority (misma fuente ARC.PHASE que decide permisos);
    -- no leer C_Epsilon/ARC directo desde core ni invertir la prioridad.
    if HarfordAuthority then
        if HarfordAuthority.IsPhaseOwner and HarfordAuthority.IsPhaseOwner() then return "Owner" end
        if HarfordAuthority.IsPhaseOfficer and HarfordAuthority.IsPhaseOfficer() then return "Oficial" end
        if HarfordAuthority.IsPhaseMember and HarfordAuthority.IsPhaseMember() then return "Miembro" end
    end
    return "No detectado"
end

local function CountSavedFlags(tbl)
    local count = 0
    if tbl then
        for _, value in pairs(tbl) do
            if value == true then count = count + 1 end
        end
    end
    return count
end

local function BuildCompendiumAuditText()
    local total = 0
    local noClass = 0
    local pendingIcon = 0
    local byName = {}
    local duplicateNames = 0
    local custom = 0
    for _, spell in ipairs(API.GetAllSpells()) do
        total = total + 1
        if not spell.classes or #spell.classes == 0 then noClass = noClass + 1 end
        if spell.sourceGroup == "Warcraft Custom" then custom = custom + 1 end
        local icon = tostring(spell.iconName or spell.icon or "")
        if icon == "" or icon == "eps_buildershaven_gobinfo" then pendingIcon = pendingIcon + 1 end
        local name = spell.name or ""
        if name ~= "" then
            byName[name] = (byName[name] or 0) + 1
            if byName[name] == 2 then duplicateNames = duplicateNames + 1 end
        end
    end
    local charDB = HarfordCompendioCharacterDB or {}
    return table.concat({
        "Conjuros totales: " .. total,
        "Warcraft Custom: " .. custom,
        "Sin clase asignada: " .. noClass,
        "Posibles nombres duplicados: " .. duplicateNames,
        "Iconos pendientes/marcador: " .. pendingIcon,
        "Favoritos guardados: " .. CountSavedFlags(charDB.favorites),
        "Mis conjuros marcados: " .. CountSavedFlags(charDB.mySpells),
        "Preparados marcados: " .. CountSavedFlags(charDB.preparedSpells),
    }, "\n")
end

local masterTabs = {
    { key = "status", label = "Estado", icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend" },
    { key = "audit", label = "Auditoria", icon = "Interface\\Icons\\INV_Misc_Note_06" },
    { key = "rest", label = "Descansos", icon = "Interface\\Icons\\Spell_Holy_BorrowedTime" },
    { key = "future", label = "Futuro", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
}

local function RefreshMasterTabs()
    for key, button in pairs(masterTabButtons) do
        local active = state.masterTab == key
        button:SetBackdropColor(active and 0.95 or 0.22, active and 0.65 or 0.14, active and 0.12 or 0.05, 1)
        button.label:SetTextColor(active and 1 or 0.95, active and 1 or 0.82, active and 0.55 or 0.22, 1)
    end
end

local function RefreshMasterFrame()
    if not MasterFrame then return end
    local adminLoaded = IsAddOnLoaded and IsAddOnLoaded("HarfordAdmin")
    MasterFrame.statusText:SetText(table.concat({
        "Modo DM: " .. (IsDMModeActive() and "Activo" or "Inactivo"),
        "Rango phase: " .. GetPhaseRankLabel(),
        "HarfordAdmin: " .. (adminLoaded and "Detectado" or "No detectado"),
        "TRP3: " .. ((TRP3_API and "Detectado") or "No detectado"),
        "",
        "Este panel requiere HarfordAdmin y .ph dm on activo.",
        "La integracion con ficha Harford se conectara en la siguiente fase.",
    }, "\n"))
    MasterFrame.auditText:SetText(BuildCompendiumAuditText())
    MasterFrame.restText:SetText(table.concat({
        "Descanso corto",
        "- Futuro control de concentracion y efectos temporales.",
        "- Futuro registro de conjuros mantenidos entre escenas.",
        "",
        "Descanso largo",
        "- Futura restauracion completa de mana.",
        "- Futura preparacion de conjuros para Druida, Paladin y Sacerdote.",
        "- Futuro control de Grimorio para Mago.",
        "",
        "Regla activa",
        "- El mana solo se consume si el lanzamiento tiene exito.",
        "- Trucos no consumen mana.",
        "- Rituales pueden lanzarse sin mana suficiente si el conjuro lo permite.",
    }, "\n"))
    MasterFrame.futureText:SetText(table.concat({
        "Herramientas previstas",
        "- Leer clase, nivel y atributo de lanzamiento desde ficha Harford.",
        "- Ver mana actual/maximo de jugadores.",
        "- Revisar conocidos, preparados y grimorio.",
        "- Auditoria de ultimos lanzamientos.",
        "- Acciones de descanso para grupo o jugador.",
        "",
        "Estado actual",
        "- Bloqueado como panel informativo para no ejecutar acciones de DM sin validar.",
    }, "\n"))

    for key, page in pairs(MasterFrame.pages) do
        page:SetShown(key == state.masterTab)
    end
    RefreshMasterTabs()
end

local function CreateMasterFrame()
    MasterFrame = CreatePanelFrame("HarfordCompendioMasterFrame", UIParent)
    MasterFrame:SetSize(820, 620)
    MasterFrame:SetPoint("CENTER", 60, 10)
    MasterFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    MasterFrame:SetFrameLevel(95)
    MasterFrame:Hide()
    MasterFrame:SetMovable(true)
    MasterFrame:EnableMouse(true)
    MasterFrame:RegisterForDrag("LeftButton")
    MasterFrame:SetScript("OnDragStart", MasterFrame.StartMoving)
    MasterFrame:SetScript("OnDragStop", MasterFrame.StopMovingOrSizing)
    ApplyBackdrop(MasterFrame, DARK[1], DARK[2], DARK[3], 0.98)

    local close = CreateFrame("Button", nil, MasterFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", MasterFrame, "TOPRIGHT", -4, -4)
    local title = CreateFont(MasterFrame, "GameFontNormalLarge", "TOP", MasterFrame, "TOP", 0, -16, "Panel del Master")
    title:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1)

    local content = CreatePanelFrame(nil, MasterFrame)
    content:SetSize(660, 540)
    content:SetPoint("TOPLEFT", MasterFrame, "TOPLEFT", 16, -52)
    ApplyBackdrop(content, PARCHMENT[1], PARCHMENT[2], PARCHMENT[3], PARCHMENT[4])
    local contentBg = content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    contentBg:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    contentBg:SetColorTexture(0.68, 0.48, 0.23, 0.92)

    local rightTabs = CreatePanelFrame(nil, MasterFrame)
    rightTabs:SetSize(112, 540)
    rightTabs:SetPoint("LEFT", content, "RIGHT", 12, 0)
    ApplyBackdrop(rightTabs, 0.02, 0.018, 0.014, 1)

    MasterFrame.pages = {}
    local function CreatePage(key, headerText)
        local page = CreateFrame("Frame", nil, content)
        page:SetPoint("TOPLEFT", content, "TOPLEFT", 26, -24)
        page:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -26, 24)
        local header = CreateFont(page, "GameFontNormalLarge", "TOPLEFT", page, "TOPLEFT", 0, 0, headerText)
        header:SetTextColor(0.22, 0.11, 0.035, 1)
        if header.SetShadowColor then header:SetShadowColor(0, 0, 0, 0) end
        if header.SetShadowOffset then header:SetShadowOffset(0, 0) end
        local line = page:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(0.36, 0.20, 0.08, 0.65)
        line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
        line:SetSize(590, 1)
        local body = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -24)
        body:SetWidth(590)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")
        body:SetTextColor(0.24, 0.13, 0.045, 1)
        if body.SetFont then body:SetFont(STANDARD_TEXT_FONT, 13, "") end
        if body.SetShadowColor then body:SetShadowColor(0, 0, 0, 0) end
        if body.SetShadowOffset then body:SetShadowOffset(0, 0) end
        if body.SetSpacing then body:SetSpacing(3) end
        MasterFrame.pages[key] = page
        return body
    end

    MasterFrame.statusText = CreatePage("status", "Estado de permisos")
    MasterFrame.auditText = CreatePage("audit", "Auditoria de compendio")
    MasterFrame.restText = CreatePage("rest", "Descansos y mana")
    MasterFrame.futureText = CreatePage("future", "Herramientas futuras")

    for i, tab in ipairs(masterTabs) do
        local btn = CreateBackdroppedButton(nil, rightTabs)
        btn:SetSize(92, 58)
        btn:SetPoint("TOP", rightTabs, "TOP", 0, -12 - ((i - 1) * 64))
        ApplyBackdrop(btn, 0.22, 0.14, 0.05, 1)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetSize(30, 30)
        btn.icon:SetPoint("TOP", 0, -6)
        btn.icon:SetTexture(tab.icon)
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("BOTTOM", 0, 7)
        btn.label:SetText(tab.label)
        btn.label:SetTextColor(0.95, 0.82, 0.22, 1)
        btn:SetScript("OnClick", function()
            state.masterTab = tab.key
            RefreshMasterFrame()
        end)
        masterTabButtons[tab.key] = btn
    end
end
local function ShowMasterFrame()
    if not IsDMModeActive() then
        PrintMessage("Panel del Master disponible solo con HarfordAdmin y .ph dm on activo.")
        return
    end
    if not MasterFrame then CreateMasterFrame() end
    RefreshMasterFrame()
    MasterFrame:Show()
    MasterFrame:Raise()
end
local function CreateMainFrame()
    MainFrame = CreatePanelFrame("HarfordCompendioFrame", UIParent)
    MainFrame:SetSize(820, 620)
    MainFrame:SetPoint("CENTER")
    MainFrame:SetFrameStrata("HIGH")
    MainFrame:Hide()
    MainFrame:SetMovable(true)
    MainFrame:EnableMouse(true)
    MainFrame:RegisterForDrag("LeftButton")
    MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
    MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
    ApplyBackdrop(MainFrame, DARK[1], DARK[2], DARK[3], DARK[4])
    local mainClose = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
    mainClose:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -4, -4)

    titleText = CreateFont(MainFrame, "GameFontNormalLarge", "TOP", MainFrame, "TOP", 0, -14, "Compendio Harford")
    titleText:SetTextColor(GOLD[1], GOLD[2], GOLD[3], 1)

    local content = CreatePanelFrame(nil, MainFrame)
    content:SetSize(660, 540)
    content:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 16, -52)
    ApplyBackdrop(content, PARCHMENT[1], PARCHMENT[2], PARCHMENT[3], PARCHMENT[4])
    local contentBg = content:CreateTexture(nil, "BACKGROUND")
    contentBg:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    contentBg:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    contentBg:SetColorTexture(0.68, 0.48, 0.23, 0.90)

    local rightTabs = CreatePanelFrame(nil, MainFrame)
    rightTabs:SetSize(112, 540)
    rightTabs:SetPoint("LEFT", content, "RIGHT", 12, 0)
    ApplyBackdrop(rightTabs, 0.02, 0.018, 0.014, 1)

    searchBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    searchBox:SetSize(260, 24)
    searchBox:SetPoint("TOPLEFT", 30, -20)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("")
    searchBox:SetScript("OnTextChanged", function(self)
        state.query = self:GetText() or ""
        state.page = 1
        RefreshSlots()
        if ClassBookFrame and ClassBookFrame:IsShown() then RefreshClassBookFrame() end
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local placeholder = CreateFont(content, "GameFontDisableSmall", "LEFT", searchBox, "RIGHT", 12, 0, "Buscar conjuro")
    placeholder:SetTextColor(0.48, 0.34, 0.14, 1)

    HarfordCompendioFilterDropdown = CreateFrame("Frame", "HarfordCompendioFilterDropdown", UIParent, "UIDropDownMenuTemplate")
    local filterOrder = { "school", "className", "category", "affinity", "sourceGroup" }
    for i, key in ipairs(filterOrder) do
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(118, 22)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", 30 + ((i - 1) * 122), -48)
        btn:SetText((filterLabels[key] or key) .. ": Todas")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                ClearFilter(key)
            else
                OpenFilterDropdown(key, self)
            end
            if ClassBookFrame and ClassBookFrame:IsShown() then RefreshClassBookFrame() end
        end)
        filterButtons[key] = btn
    end

    for i, tab in ipairs(tabs) do
        local btn = CreateBackdroppedButton(nil, rightTabs)
        btn:SetSize(92, 58)
        btn:SetPoint("TOP", rightTabs, "TOP", 0, -12 - ((i - 1) * 64))
        ApplyBackdrop(btn, 0.22, 0.14, 0.05, 1)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetSize(30, 30)
        btn.icon:SetPoint("TOP", 0, -6)
        btn.icon:SetTexture((API.ResolveRP3IconName and API.ResolveRP3IconName(tab.iconName, tab.icon)) or tab.icon)
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("BOTTOM", 0, 7)
        btn.label:SetText(tab.label)
        btn.label:SetTextColor(0.95, 0.82, 0.22, 1)
        btn:SetScript("OnClick", function()
            if tab.key == "mine" then
                ShowClassBookFrame()
                return
            end
            state.tab = tab.key
            state.page = 1
            RefreshSlots()
        end)
        tabButtons[tab.key] = btn
    end

    local grid = CreateFrame("Frame", nil, content)
    grid:SetSize(610, 430)
    grid:SetPoint("TOP", content, "TOP", 0, -100)
    for i = 1, PAGE_SIZE do
        local slot = CreateBackdroppedButton(nil, grid)
        slot:SetSize(302, 62)
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        slot:SetPoint("TOPLEFT", grid, "TOPLEFT", col * 306, -row * 66)
        ApplyBackdrop(slot, 0.18, 0.12, 0.05, 0.9)
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(36, 36)
        slot.icon:SetPoint("LEFT", 8, 0)
        slot.name = slot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slot.name:SetPoint("TOPLEFT", slot.icon, "TOPRIGHT", 8, 2)
        slot.name:SetWidth(242)
        slot.name:SetHeight(12)
        slot.name:SetJustifyH("LEFT")
        if slot.name.SetFont then slot.name:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE") end
        slot.name:SetWordWrap(false)
        if slot.name.SetMaxLines then slot.name:SetMaxLines(1) end
        slot.meta = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        slot.meta:SetPoint("TOPLEFT", slot.name, "BOTTOMLEFT", 0, 2)
        slot.meta:SetWidth(242)
        slot.meta:SetHeight(11)
        slot.meta:SetJustifyH("LEFT")
        if slot.meta.SetFont then slot.meta:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE") end
        slot.meta:SetWordWrap(false)
        if slot.meta.SetMaxLines then slot.meta:SetMaxLines(1) end
        slot.classes = slot:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        slot.classes:SetPoint("TOPLEFT", slot.meta, "BOTTOMLEFT", 0, 1)
        slot.classes:SetWidth(242)
        slot.classes:SetHeight(18)
        slot.classes:SetJustifyH("LEFT")
        if slot.classes.SetFont then slot.classes:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE") end
        if slot.classes.SetSpacing then slot.classes:SetSpacing(-3) end
        slot.classes:SetWordWrap(true)
        if slot.classes.SetMaxLines then slot.classes:SetMaxLines(2) end
        slot.favorite = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slot.favorite:SetPoint("RIGHT", slot, "RIGHT", -10, 0)
        slot.favorite:SetTextColor(1, 0.85, 0.1, 1)
        slot:RegisterForClicks("LeftButtonUp")
        slot:SetScript("OnClick", function(self, button)
            HandleSpellSlotClick(self.spell, button)
        end)
        slots[i] = slot
    end

    local prev = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    prev:SetSize(34, 28)
    prev:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -78, 18)
    prev:SetText("<")
    prev:SetScript("OnClick", function()
        state.page = math.max(1, state.page - 1)
        RefreshSlots()
    end)
    local next = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    next:SetSize(34, 28)
    next:SetPoint("LEFT", prev, "RIGHT", 8, 0)
    next:SetText(">")
    next:SetScript("OnClick", function()
        local maxPage = math.max(1, math.ceil(#state.results / PAGE_SIZE))
        state.page = math.min(maxPage, state.page + 1)
        RefreshSlots()
    end)
    pageText = CreateFont(content, "GameFontHighlightSmall", "BOTTOMLEFT", content, "BOTTOMLEFT", 28, 25, "Pagina 1 / 1")
    pageText:SetTextColor(0.16, 0.08, 0.03, 1)

    local settings = CreateBackdroppedButton(nil, MainFrame)
    settings:SetSize(28, 28)
    settings:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -44, -10)
    ApplyBackdrop(settings, 0.05, 0.04, 0.03, 0.95)
    settings.icon = settings:CreateTexture(nil, "ARTWORK")
    settings.icon:SetSize(20, 20)
    settings.icon:SetPoint("CENTER")
    settings.icon:SetTexture((API.ResolveRP3IconName and API.ResolveRP3IconName("pet_type_mechanical", "Interface\\Icons\\INV_Gizmo_02")) or "Interface\\Icons\\INV_Gizmo_02")
    settings:SetScript("OnClick", function()
        ShowMasterFrame()
    end)
end
function API.Toggle()
    if not MainFrame then
        CreateDetailFrame()
        CreateCastFrame()
        CreateMainFrame()
    end
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
        RefreshSlots()
    end
end

function API.OpenSpellById(spellId)
    local spell = API.GetSpellById(spellId)
    if not spell then
        PrintMessage("conjuro no encontrado: " .. tostring(spellId))
        return
    end
    if not MainFrame then
        CreateDetailFrame()
        CreateCastFrame()
        CreateMainFrame()
    end
    ShowDetail(spell)
end

-- Aperturas embebibles desde la pestaña Conjuros de HarfordCharacterPanel (sin ventana suelta).
function API.OpenGrimoire()
    ShowClassBookFrame()
end

-- El Master se auto-gatea: ShowMasterFrame rechaza si no hay modo DM activo.
function API.OpenMaster()
    ShowMasterFrame()
end

function API.IsDMModeActive()
    return IsDMModeActive()
end


local function RunSlash()
    local ok, err = pcall(API.Toggle)
    if not ok then
        PrintMessage("error al abrir: " .. tostring(err))
    end
end

-- Comando suelto retirado: usar `/harford compendio` o `/harford magia`.
SlashCmdList["HARFORDCOMPENDIO"] = RunSlash

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    API.Init()
    if HarfordDebug and HarfordDebug.Log then
        HarfordDebug.Log("HarfordCompendio cargado.")
    end
end)











































