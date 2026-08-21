-- HarfordCharacterSpellbook: pestaña Conjuros (replica del libro de hechizos poblada por el
-- compendio). Extraida de HarfordCharacterPanel; recibe estado/constantes del libro via Init.
HarfordCharacterSpellbook = HarfordCharacterSpellbook or {}
local M = HarfordCharacterSpellbook

-- Dependencias inyectadas por HarfordCharacterPanel.Init (estado del panel + libro nativo).
local S, CreatePage, BookSideTabOnEnter
local BOOK_PER_PAGE, BOOK_ROWS, BOOK_BTN, BOOK_COL_X, BOOK_ROW_Y0, BOOK_ROW_PITCH, BOOK_GENERAL_ICON
local RefreshSpells  -- forward (closures internos)

-- ════════════════════════════════════════════════════════════════════════════════════════
-- PESTAÑA CONJUROS: replica del libro de hechizos nativo, poblada por el compendio
-- (HarfordCompendioAPI). Reutiliza la misma maquinaria visual que el Libro de Habilidades.
-- ════════════════════════════════════════════════════════════════════════════════════════

-- Texturas del libro de Conjuros. PUNTO UNICO para cambiarlas: por ahora identicas a las de
-- Habilidades, pero separadas para poder divergir luego sin tocar el Libro de Habilidades.
local SPELLS_SKIN = {
    body   = 374155,
    bodyTC = { 0, 0.533203125, 0, 0.4902344048 },
    page1  = "Interface\\Spellbook\\Spellbook-Page-1",
    page2  = "Interface\\Spellbook\\Spellbook-Page-2",
    parts  = "Interface\\Spellbook\\Spellbook-Parts",
}

local function CompendioAPI()
    return _G.HarfordCompendioAPI
end

local function SpellLevelText(level)
    level = tonumber(level) or 0
    return level <= 0 and "Truco" or ("Nivel " .. level)
end

-- Dimensiones del dropdown unico de filtros secundarios (las claves coinciden con FilterSpells).
local SPELL_FILTER_DIMS = {
    { key = "school",      label = "Escuela" },
    { key = "className",   label = "Clase" },
    { key = "category",    label = "Categoria" },
    { key = "affinity",    label = "Afinidad" },
    { key = "sourceGroup", label = "Fuente" },
}

-- Valores distintos por dimension, derivados de los datos del compendio (cache por referencia).
local spellFilterValues, spellFilterValuesSource
local function CollectSpellFilterValues()
    local api = CompendioAPI()
    local all = (api and api.GetAllSpells and api.GetAllSpells()) or {}
    if spellFilterValues and spellFilterValuesSource == all then return spellFilterValues end
    local sets = { school = {}, className = {}, category = {}, affinity = {}, sourceGroup = {} }
    for _, sp in ipairs(all) do
        if sp.school and sp.school ~= "" then sets.school[sp.school] = true end
        if sp.affinity and sp.affinity ~= "" then sets.affinity[sp.affinity] = true end
        if sp.sourceGroup and sp.sourceGroup ~= "" then sets.sourceGroup[sp.sourceGroup] = true end
        for _, c in ipairs(sp.classes or {}) do sets.className[c] = true end
        for _, c in ipairs(sp.categories or {}) do sets.category[c] = true end
    end
    local out = {}
    for dim, set in pairs(sets) do
        local list = {}
        for v in pairs(set) do list[#list + 1] = v end
        table.sort(list)
        out[dim] = list
    end
    spellFilterValues, spellFilterValuesSource = out, all
    return out
end

-- Init del dropdown unico de filtros: nivel 1 = una entrada por dimension (con submenu) +
-- "Limpiar"; nivel 2 = "Todas" + los valores distintos de esa dimension.
local function SpellFilterMenu_Init(_, level)
    local sb = S.spellBook
    if not sb then return end
    level = level or 1
    if level == 1 then
        local title = UIDropDownMenu_CreateInfo()
        title.text, title.isTitle, title.notCheckable = "Filtros", true, true
        UIDropDownMenu_AddButton(title, level)
        for _, dim in ipairs(SPELL_FILTER_DIMS) do
            local info = UIDropDownMenu_CreateInfo()
            local cur = sb.filters[dim.key]
            info.text = (cur and cur ~= "Todas") and (dim.label .. ": " .. cur) or dim.label
            info.notCheckable, info.hasArrow, info.value = true, true, dim.key
            UIDropDownMenu_AddButton(info, level)
        end
        local clear = UIDropDownMenu_CreateInfo()
        clear.text, clear.notCheckable = "Limpiar filtros", true
        clear.func = function() wipe(sb.filters); sb.pageNum = 1; CloseDropDownMenus(); RefreshSpells() end
        UIDropDownMenu_AddButton(clear, level)
    elseif level == 2 then
        local dimKey = UIDROPDOWNMENU_MENU_VALUE
        local all = UIDropDownMenu_CreateInfo()
        all.text = "Todas"
        all.checked = (sb.filters[dimKey] == nil or sb.filters[dimKey] == "Todas")
        all.func = function() sb.filters[dimKey] = nil; sb.pageNum = 1; CloseDropDownMenus(); RefreshSpells() end
        UIDropDownMenu_AddButton(all, level)
        for _, v in ipairs(CollectSpellFilterValues()[dimKey] or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.checked = v, (sb.filters[dimKey] == v)
            info.func = function() sb.filters[dimKey] = v; sb.pageNum = 1; CloseDropDownMenus(); RefreshSpells() end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

local function CreateSpellsPage()
    local page = CreatePage("spells")
    local host = S.skillsFrame or S.frame
    local area = CreateFrame("Frame", nil, page)
    area:SetAllPoints(page)

    -- Fondo + pergamino como regiones del FRAME (igual que el Libro de Habilidades).
    local body = host:CreateTexture(nil, "BACKGROUND", nil, -7)
    body:SetTexture(SPELLS_SKIN.body)
    body:SetTexCoord(unpack(SPELLS_SKIN.bodyTC))
    body:SetAllPoints(host)
    body:Hide()
    local lpage = host:CreateTexture(nil, "BACKGROUND", nil, -6)
    lpage:SetTexture(SPELLS_SKIN.page1)
    lpage:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -25)
    lpage:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -31, -15)
    lpage:Hide()
    local rpage = host:CreateTexture(nil, "BACKGROUND", nil, -5)
    rpage:SetTexture(SPELLS_SKIN.page2)
    rpage:SetPoint("TOPLEFT", lpage, "TOPRIGHT", 0, 0)
    rpage:SetPoint("BOTTOMLEFT", lpage, "BOTTOMRIGHT", 0, 0)
    rpage:SetWidth(41)
    rpage:Hide()

    -- Busqueda + UN solo boton de Filtros (dropdown con submenus por dimension).
    local search = CreateFrame("EditBox", nil, area, "InputBoxTemplate")
    search:SetAutoFocus(false); search:SetSize(150, 20)
    search:SetPoint("TOPLEFT", host, "TOPLEFT", 100, -46)
    search:SetScript("OnTextChanged", function(self)
        S.spellBook.query = self:GetText() or ""
        S.spellBook.pageNum = 1
        RefreshSpells()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local searchLabel = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("BOTTOMLEFT", search, "TOPLEFT", -2, 2)
    searchLabel:SetText("Buscar conjuro")

    S.spellFilterDropdown = CreateFrame("Frame", "HarfordSpellFilterDropdown", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(S.spellFilterDropdown, SpellFilterMenu_Init, "MENU")
    local filterBtn = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")
    filterBtn:SetSize(80, 22)
    filterBtn:SetPoint("LEFT", search, "RIGHT", 10, 0)
    filterBtn:SetText("Filtros")
    filterBtn:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, S.spellFilterDropdown, self, 0, 0)
    end)

    -- Grimorio (libro de clase) y Master DM como popups del compendio, accesibles desde la pestaña.
    local grimoireBtn = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")
    grimoireBtn:SetSize(80, 22)
    grimoireBtn:SetPoint("LEFT", filterBtn, "RIGHT", 8, 0)
    grimoireBtn:SetText("Grimorio")
    grimoireBtn:SetScript("OnClick", function()
        local api = CompendioAPI()
        if api and api.OpenGrimoire then api.OpenGrimoire() end
    end)
    local masterBtn = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")
    masterBtn:SetSize(72, 22)
    masterBtn:SetPoint("LEFT", grimoireBtn, "RIGHT", 8, 0)
    masterBtn:SetText("Master")
    masterBtn:SetScript("OnClick", function()
        local api = CompendioAPI()
        if api and api.OpenMaster then api.OpenMaster() end
    end)
    masterBtn:Hide()  -- visible solo en modo DM (lo conmuta RefreshSpells)

    -- Botones de conjuro: mismo pool/estilo que el Libro de Habilidades.
    local PARTS = SPELLS_SKIN.parts
    local buttons = {}
    for i = 1, BOOK_PER_PAGE do
        local b = CreateFrame("Button", nil, area)
        b:SetSize(BOOK_BTN, BOOK_BTN)
        local col = (i <= BOOK_ROWS) and 0 or 1
        local row = (i <= BOOK_ROWS) and (i - 1) or (i - 1 - BOOK_ROWS)
        b:SetPoint("TOPLEFT", host, "TOPLEFT", BOOK_COL_X[col + 1], BOOK_ROW_Y0 - row * BOOK_ROW_PITCH)
        b.ring = b:CreateTexture(nil, "BACKGROUND")
        b.ring:SetTexture(PARTS)
        b.ring:SetSize(43, 43)
        b.ring:SetPoint("CENTER", b, "CENTER", 0, 0)
        b.bar = b:CreateTexture(nil, "BACKGROUND")
        b.bar:SetTexture(PARTS)
        b.bar:SetTexCoord(0.3125, 0.96484375, 0.37109375, 0.5234375)
        b.bar:SetSize(167, 39)
        b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 36, -2)
        b.bar2 = b:CreateTexture(nil, "BACKGROUND")
        b.bar2:SetTexture(PARTS)
        b.bar2:SetTexCoord(0.3125, 0.96484375, 0.37109375, 0.5234375)
        b.bar2:SetAllPoints(b.bar)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints(b); b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        b.name = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        b.name:SetPoint("LEFT", b, "RIGHT", 8, 4)
        b.name:SetWidth(145); b.name:SetJustifyH("LEFT")
        b.sub = b:CreateFontString(nil, "ARTWORK")
        b.sub:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -1)
        b.sub:SetWidth(145); b.sub:SetJustifyH("LEFT")
        b.sub:SetTextColor(0.96, 0.90, 0.72)  -- crema claro: legible sobre el pergamino con OUTLINE
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetScript("OnEnter", function(self)
            if not (self.spell and GameTooltip) then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.spell.name or "?", 1, 0.82, 0)
            GameTooltip:AddLine(SpellLevelText(self.spell.level) .. "  -  " .. (self.spell.school or "-"), 0.8, 0.8, 0.8)
            if self.spell.description and self.spell.description ~= "" then
                GameTooltip:AddLine(self.spell.description, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        b:SetScript("OnClick", function(self)
            local api = CompendioAPI()
            if self.spell and api and api.OpenSpellById then api.OpenSpellById(self.spell.id) end
        end)
        b:Hide()
        buttons[i] = b
    end

    local nxt = CreateFrame("Button", nil, area)
    nxt:SetSize(32, 32); nxt:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -31, 26)
    nxt:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nxt:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nxt:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nxt:SetScript("OnClick", function() S.spellBook.pageNum = S.spellBook.pageNum + 1; RefreshSpells() end)
    local prev = CreateFrame("Button", nil, area)
    prev:SetSize(32, 32); prev:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -66, 26)
    prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prev:SetScript("OnClick", function() S.spellBook.pageNum = math.max(1, S.spellBook.pageNum - 1); RefreshSpells() end)
    local pageText = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -110, 38)

    -- Espacios de conjuro (o mana) DE UN VISTAZO. Hasta ahora solo se veian de uno en uno al
    -- abrir el detalle de un conjuro concreto, asi que no habia forma de saber con que cuentas
    -- antes de elegir. Va abajo a la izquierda: la fila de arriba (buscar + filtros + Grimorio
    -- + Master) ocupa de 100 a 508 sobre 550, y abajo a la derecha esta el pasapaginas.
    local slotsText = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- Anclada por BOTTOMLEFT a proposito: un lanzador de nivel 20 tiene NUEVE niveles de
    -- espacio y no caben en una linea, asi que la segunda crece hacia ARRIBA y no invade el
    -- pasapaginas. El ancho se corta antes del texto de pagina (que acaba hacia x=360).
    slotsText:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 60, 38)
    slotsText:SetWidth(295)
    slotsText:SetJustifyH("LEFT")
    slotsText:SetWordWrap(true)
    if slotsText.SetMaxLines then slotsText:SetMaxLines(2) end

    S.spellBook = { page = page, area = area, body = body, page1 = lpage, page2 = rpage,
                    buttons = buttons, sideTabs = {}, prev = prev, nxt = nxt, pageText = pageText,
                    search = search, filterBtn = filterBtn, masterBtn = masterBtn,
                    slotsText = slotsText,
                    filters = {}, tabKey = "all", query = "", pageNum = 1 }
end

-- Numeracion romana de 1 a 9, que es hasta donde llegan los espacios de conjuro.
local ROMANOS = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX" }

-- Linea de recursos de lanzamiento. Respeta el modo GLOBAL (HarfordConfig.spell_cost_mode):
-- con "slots" enumera los espacios por nivel y con "mana" ensena el pool. Un no lanzador no
-- tiene ninguno de los dos y la linea queda vacia en vez de mentir con ceros.
local function CastingResourceText()
    local mana = _G.HarfordDnDMana
    if not mana then return "" end

    local usaEspacios = HarfordConfig and HarfordConfig.Get
        and HarfordConfig.Get("spell_cost_mode") == "slots"

    if not usaEspacios then
        local pool = mana.GetManaPool and mana.GetManaPool() or 0
        if pool <= 0 then return "" end
        local actual = pool
        -- La via canonica del mana actual es el store (es la que usa el propio compendio);
        -- HarfordDnDAPI no expone GetResourceCurrent.
        if HarfordDnDStore and HarfordDnDStore.GetResourceCurrent then
            actual = tonumber(HarfordDnDStore.GetResourceCurrent("mana")) or pool
        end
        return string.format("|cffffd100Mana|r %d/%d", actual, pool)
    end

    local maxLevel = mana.GetMaxSpellLevel and mana.GetMaxSpellLevel() or 0
    if maxLevel <= 0 then return "" end
    local partes = {}
    for nivel = 1, maxLevel do
        local actual, maximo = mana.GetSpellSlotCurrent(nivel)
        if (maximo or 0) > 0 then
            -- Agotado en rojo, gastado a medias en blanco, intacto en dorado: se lee sin contar.
            local color = (actual == 0 and "|cffff5555")
                or (actual < maximo and "|cffffffff")
                or "|cffffd100"
            partes[#partes + 1] = string.format("%s%s %d/%d|r", color, ROMANOS[nivel] or nivel, actual, maximo)
        end
    end
    return table.concat(partes, "  ")
end

RefreshSpells = function()
    if not (S.spellBook and S.spellBook.page) then return end
    local api = CompendioAPI()
    if not api then return end
    local sb = S.spellBook
    -- Recursos de lanzamiento: se recalculan en cada refresco porque gastar un espacio o
    -- descansar tiene que verse aqui sin reabrir el libro.
    if sb.slotsText then
        local linea = CastingResourceText()
        sb.slotsText:SetText(linea)
        sb.slotsText:SetShown(linea ~= "")
    end
    -- Boton Master solo para DM: senal canonica HarfordAuthority, con fallback al gate del compendio.
    if sb.masterBtn then
        local isDM = (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools())
            or (api.IsDMModeActive and api.IsDMModeActive()) or false
        sb.masterBtn:SetShown(isDM and true or false)
    end
    local tabs = (api.GetFilterTabs and api.GetFilterTabs()) or {}

    -- Pestañas laterales (filtros nivel/favoritos/mis conjuros) estilo SkillLineTab, como Habilidades.
    for i, t in ipairs(tabs) do
        local tab = sb.sideTabs[i]
        if not tab then
            tab = CreateFrame("Button", nil, sb.page)
            tab:SetSize(32, 32)
            tab:SetPoint("TOPLEFT", S.skillsFrame or S.frame, "TOPRIGHT", -2, -36 - (i - 1) * 49)
            local ts = HarfordCharacterPanel._tabSkin
            tab.skin = tab:CreateTexture(nil, "BACKGROUND")
            tab.skin:SetTexture("Interface\\Spellbook\\SpellBook-SkillLineTab")
            tab.skin:SetSize(ts.w, ts.h)
            tab.skin:SetPoint("TOPLEFT", tab, "TOPLEFT", ts.x, ts.y)
            tab.icon = tab:CreateTexture(nil, "ARTWORK", nil, 0)
            tab.icon:SetSize(32, 32)
            tab.icon:SetPoint("CENTER", tab, "CENTER", 3, -1)
            tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            tab.iconFrame = tab:CreateTexture(nil, "ARTWORK", nil, 2)
            tab.iconFrame:SetTexture("Interface\\Spellbook\\GuildSpellbooktabIconFrame")
            tab.iconFrame:SetAllPoints(tab.icon)
            tab.checked = tab:CreateTexture(nil, "OVERLAY")
            tab.checked:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            tab.checked:SetBlendMode("ADD"); tab.checked:SetAllPoints(tab.icon)
            tab:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            local hl = tab:GetHighlightTexture()
            if hl then hl:ClearAllPoints(); hl:SetAllPoints(tab.icon) end
            tab:SetScript("OnEnter", BookSideTabOnEnter)
            tab:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            tab:SetScript("OnClick", function(self) sb.tabKey = self._key; sb.pageNum = 1; RefreshSpells() end)
            sb.sideTabs[i] = tab
        end
        tab._key, tab._label = t.key, (t.label or t.key)
        -- iconName (ej. favoritos "eps_rumble_starpoints") se resuelve via LibRPMedia como en la
        -- ventana suelta; t.icon es solo el fallback si no resuelve.
        tab.icon:SetTexture((t.iconName and api.ResolveRP3IconName and api.ResolveRP3IconName(t.iconName, t.icon))
            or t.icon or BOOK_GENERAL_ICON)
        tab.checked:SetShown(t.key == sb.tabKey)
        tab:Show()
    end
    for i = #tabs + 1, #sb.sideTabs do sb.sideTabs[i]:Hide() end

    -- Filtro = side tab activa + busqueda + dropdown de filtros secundarios.
    local active
    for _, t in ipairs(tabs) do if t.key == sb.tabKey then active = t; break end end
    active = active or {}
    local filter = { query = sb.query or "" }
    if active.level ~= nil then filter.level = active.level end
    if active.favoritesOnly then filter.favoritesOnly = true end
    if active.mineOnly then filter.mineOnly = true end
    for k, v in pairs(sb.filters) do if v and v ~= "Todas" then filter[k] = v end end
    local results = (api.FilterSpells and api.FilterSpells(filter)) or {}

    local pages = math.max(1, math.ceil(#results / BOOK_PER_PAGE))
    if sb.pageNum > pages then sb.pageNum = pages end
    if sb.pageNum < 1 then sb.pageNum = 1 end
    local startI = (sb.pageNum - 1) * BOOK_PER_PAGE
    local frA = HarfordCharacterPanel._bookFrame.activo or HarfordCharacterPanel._bookFrame.pasivo
    local frP = HarfordCharacterPanel._bookFrame.pasivo
    for i = 1, BOOK_PER_PAGE do
        local b = sb.buttons[i]
        local spell = results[startI + i]
        if spell then
            b.spell = spell
            b.icon:SetTexture((api.GetSpellIcon and api.GetSpellIcon(spell)) or spell.icon)
            b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94); b.icon:Show()
            -- Marco dorado (activo) si el conjuro es "mio"/preparado; marron (pasivo) si no.
            local known = (api.IsMySpell and api.IsMySpell(spell.id))
                or (api.IsPreparedSpell and api.IsPreparedSpell(spell.id))
            local fr = known and frA or frP
            b.ring:SetTexCoord(fr.tc[1], fr.tc[2], fr.tc[3], fr.tc[4])
            b.ring:SetSize(fr.w, fr.h)
            b.ring:ClearAllPoints(); b.ring:SetPoint("CENTER", b, "CENTER", fr.ox or 0, fr.oy or 0)
            b.ring:SetDrawLayer(known and "OVERLAY" or "BACKGROUND")
            b.name:SetText(spell.name or "?")
            local sub = SpellLevelText(spell.level) .. "  ·  " .. (spell.school or "-")
            if spell.affinity and spell.affinity ~= "" then sub = sub .. "  ·  " .. spell.affinity end
            if api.IsFavorite and api.IsFavorite(spell.id) then sub = sub .. "  ·  *" end
            b.sub:SetText(sub); b.sub:SetTextColor(0.96, 0.90, 0.72)
            b:EnableMouse(true); b:Show()
        else
            b.spell = nil
            b.icon:Hide()
            b.ring:SetTexCoord(frP.tc[1], frP.tc[2], frP.tc[3], frP.tc[4])
            b.ring:SetSize(frP.w, frP.h)
            b.ring:ClearAllPoints(); b.ring:SetPoint("CENTER", b, "CENTER", frP.ox or 0, frP.oy or 0)
            b.ring:SetDrawLayer("BACKGROUND")
            b.name:SetText(""); b.sub:SetText("")
            b:EnableMouse(false); b:Show()
        end
    end
    sb.pageText:SetText("Pagina " .. sb.pageNum .. " / " .. pages .. "  -  " .. #results .. " conjuros")
    if sb.pageNum > 1 then sb.prev:Enable() else sb.prev:Disable() end
    if sb.pageNum < pages then sb.nxt:Enable() else sb.nxt:Disable() end
end

M.CreateSpellsPage = CreateSpellsPage
M.RefreshSpells = RefreshSpells

function M.Init(deps)
    S = deps.S
    CreatePage = deps.CreatePage
    BookSideTabOnEnter = deps.BookSideTabOnEnter
    BOOK_PER_PAGE, BOOK_ROWS, BOOK_BTN = deps.BOOK_PER_PAGE, deps.BOOK_ROWS, deps.BOOK_BTN
    BOOK_COL_X, BOOK_ROW_Y0, BOOK_ROW_PITCH = deps.BOOK_COL_X, deps.BOOK_ROW_Y0, deps.BOOK_ROW_PITCH
    BOOK_GENERAL_ICON = deps.BOOK_GENERAL_ICON
end
