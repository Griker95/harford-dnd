-- Pestana PROFESIONES del panel de personaje: la rejilla de sellos, sus tooltips y el refresco.
--
-- Sale de HarfordCharacterPanel.lua con una sola llamada desde fuera. Reutiliza el skin del libro
-- de habilidades y solo cambia el marcapaginas y el sello de cada profesion; el click abre
-- HarfordProfessionsCraftUI, que es una ventana aparte y no vive aqui.

HarfordCharacterProfessions = HarfordCharacterProfessions or {}

-- Inyectadas por HarfordCharacterPanel.
local CreateFS, CreatePage, K, S

function HarfordCharacterProfessions.Init(deps)
    deps = deps or {}
    CreateFS = deps.CreateFS or CreateFS
    CreatePage = deps.CreatePage or CreatePage
    K = deps.K or K
    S = deps.S or S
end

-- El cliente de Epsilon resuelve rutas con fiabilidad y los fileID sueltos no siempre; se usa la
-- ruta y solo se cae al id numerico si esa ruta no existe en este build.
local function ProfTexture(path, fileId)
    if GetFileIDFromPath and GetFileIDFromPath(path) then return path end
    -- Si la ruta no existe en este build se cae al fileID, pero se AVISA una vez: sin aviso, un
    -- id equivocado deja la pagina en verde y no hay forma de saber por que.
    if not ProfTexture.avisado then
        ProfTexture.avisado = true
        if HarfordChat and HarfordChat.Print then
            HarfordChat.Print(string.format(
                "|cffff9900Profesiones:|r la textura |cffffd100%s|r no existe en este cliente; se usa el fileID %s.",
                tostring(path), tostring(fileId)))
        end
    end
    return fileId or path
end

local function CreateProfessionsPage()
    local page = CreatePage("professions")
    -- El libro NATIVO no recorta ornamentos por hueco: al entrar en la pestana Profesiones
    -- sustituye las DOS paginas enteras (SpellBookFrame.lua: bgFileL/bgFileR ->
    -- Professions-Book-Left / Professions-Book-Right). El marco ornamentado de cada profesion,
    -- el marcapaginas verde y el resto del adorno vienen horneados en esas dos texturas.
    -- Por eso aqui ya no hay ni `stamp` por boton ni parche para tapar la cinta azul: no hay
    -- cinta azul que tapar, porque la pagina de conjuros no llega a dibujarse.
    local host = S.skillsFrame or S.frame
    local profBody = host:CreateTexture(nil, "BACKGROUND", nil, -7)
    profBody:SetTexture(374155)
    profBody:SetTexCoord(0, 0.533203125, 0, 0.4902344048)
    profBody:SetAllPoints(host)
    profBody:Hide()
    -- Base: las MISMAS paginas del libro de habilidades (Habilidades/Conjuros), para que las
    -- tres pestanas sean el mismo libro. La pagina de profesiones nativa NO se dibuja: de ella
    -- solo se recorta el marco ornamentado de cada hueco (ver los `frameCovers` de abajo), que
    -- es justo lo que la diferencia. Anclaje identico al de la pestana Conjuros.
    local profPage1 = host:CreateTexture(nil, "BACKGROUND", nil, -6)
    profPage1:SetTexture("Interface\\Spellbook\\Spellbook-Page-1")
    profPage1:SetPoint("TOPLEFT", host, "TOPLEFT", K.SKILLS_PAGE_RECT.left, K.SKILLS_PAGE_RECT.top)
    profPage1:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", K.SKILLS_PAGE_RECT.right, K.SKILLS_PAGE_RECT.bottom)
    profPage1:Hide()
    -- Identica a la del libro de habilidades, incluidos el sublevel -5 (por ENCIMA de la
    -- pagina izquierda, que va en -6) y el ancho de 41. Sin ese ancho la textura de cierre
    -- no tiene medida propia y no cierra igual que en Habilidades/Conjuros.
    local profPage2 = host:CreateTexture(nil, "BACKGROUND", nil, -5)
    profPage2:SetTexture("Interface\\Spellbook\\Spellbook-Page-2")
    profPage2:SetPoint("TOPLEFT", profPage1, "TOPRIGHT", 0, 0)
    profPage2:SetPoint("BOTTOMLEFT", profPage1, "BOTTOMRIGHT", 0, 0)
    profPage2:SetWidth(K.SKILLS_PAGE_RECT.rightWidth)
    profPage2:Hide()

    -- Marco ornamentado de cada hueco, recortado de la pagina de profesiones NATIVA aunque el
    -- fondo sea el del libro de habilidades: un frame que recorta (`SetClipsChildren`) con la
    -- pagina de profesiones dentro, desplazada PROF_FRAME_OFFSET, de modo que en la ventana de
    -- 437x81 caiga exactamente el marco del hueco 1. Asi el marco es el nativo de verdad, sin
    -- texCoords calculadas ni arte inventado, y de paso tapa el arte de profesion secundaria.
    -- Van colgados de la PAGINA y no del boton: los botones solo se crean para los huecos con
    -- contenido (con cero profesiones conocidas solo se crean dos), asi que dentro del boton el
    -- marco no llegaba a existir nunca.
    -- MARCAPAGINAS VERDE. Es una TEXTURA del libro, no un frame que recorta: el retrato de la
    -- ventana (58x58 en -4,+4) cae justo sobre esta franja, y un frame hijo dibuja SIEMPRE por
    -- encima de las texturas de su padre, asi que tapaba el retrato con el lomo negro de la
    -- pagina de profesiones. Como textura en BACKGROUND -4 queda encima de las dos paginas
    -- (-6 y -5) y por debajo del retrato (ARTWORK 2), que es donde debe estar.
    -- El recorte se hace con texCoord en vez de con SetClipsChildren, que solo existe en frames.
    local bookmarkPage = host:CreateTexture(nil, "BACKGROUND", nil, -4)
    bookmarkPage:SetTexture(ProfTexture("Interface\\Spellbook\\Professions-Book-Left", 383588))
    bookmarkPage:Hide()

    local frameCovers = {}
    for i = 1, #K.PROF_SLOTS do
        local slot = K.PROF_SLOTS[i]
        local m = K.PROF_FRAME_MARGIN
        local cover = CreateFrame("Frame", nil, page)
        cover:SetSize(slot.w + m * 2, slot.h + m * 2)
        -- Anclado al LIBRO, no a la pagina de contenido: `skillsContent` empieza 21 px mas
        -- abajo que el frame, y las coordenadas nativas son respecto al frame (ahi se ancla
        -- tambien la textura de pagina). Colgarlos de `page` los bajaba 21 px.
        cover:SetPoint("TOPLEFT", host, "TOPLEFT", slot.x - m, slot.y + m)
        if cover.SetClipsChildren then cover:SetClipsChildren(true) end
        local left = cover:CreateTexture(nil, "BACKGROUND")
        left:SetTexture(ProfTexture("Interface\\Spellbook\\Professions-Book-Left", 383588))
        left:SetPoint("TOPLEFT", cover, "TOPLEFT",
            K.PROF_FRAME_OFFSET.x + m, K.PROF_FRAME_OFFSET.y - m)
        cover.pageLeft = left
        local right = cover:CreateTexture(nil, "BACKGROUND")
        right:SetTexture(ProfTexture("Interface\\Spellbook\\Professions-Book-Right", 383589))
        right:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
        frameCovers[#frameCovers + 1] = cover
    end

    -- Toda la geometria ajustable se aplica desde aqui, para que el ajuste en vivo use el mismo
    -- camino que el arranque y no haya dos verdades.
    local function ApplyProfSkin()
        -- La pagina base se dibuja estirada en un ancho de `host - 31`. El marcapaginas ocupa
        -- los `w` primeros pixeles de esa misma pagina, asi que su texCoord es esa fraccion:
        -- se recorta lo mismo que veria un frame que recortase, pero sin frame.
        local anchoPagina = (host:GetWidth() or 550) + K.SKILLS_PAGE_RECT.right - K.SKILLS_PAGE_RECT.left
        if anchoPagina < 1 then anchoPagina = 519 end
        local fraccion = math.min(1, K.PROF_BOOKMARK.w / anchoPagina)
        bookmarkPage:SetTexCoord(0, fraccion, 0, 1)
        bookmarkPage:ClearAllPoints()
        bookmarkPage:SetPoint("TOPLEFT", host, "TOPLEFT",
            K.SKILLS_PAGE_RECT.left + K.PROF_BOOKMARK.tx, K.SKILLS_PAGE_RECT.top + K.PROF_BOOKMARK.ty)
        bookmarkPage:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT",
            K.SKILLS_PAGE_RECT.left + K.PROF_BOOKMARK.tx, K.SKILLS_PAGE_RECT.bottom + K.PROF_BOOKMARK.ty)
        bookmarkPage:SetWidth(K.PROF_BOOKMARK.w)
        for i, cover in ipairs(frameCovers) do
            local slot = K.PROF_SLOTS[i]
            local m = K.PROF_FRAME_MARGIN
            cover:SetSize(slot.w + m * 2, slot.h + m * 2)
            cover:ClearAllPoints()
            cover:SetPoint("TOPLEFT", host, "TOPLEFT", slot.x - m, slot.y + m)
            cover.pageLeft:ClearAllPoints()
            cover.pageLeft:SetPoint("TOPLEFT", cover, "TOPLEFT",
                K.PROF_FRAME_OFFSET.x + m, K.PROF_FRAME_OFFSET.y - m)
        end
    end
    ApplyProfSkin()
    HarfordCharacterPanel._ApplyProfSkin = ApplyProfSkin
    HarfordCharacterPanel._ProfSkinValues = {
        bookmark = K.PROF_BOOKMARK, frame = K.PROF_FRAME_OFFSET,
        margen = function(v)
            if v then K.PROF_FRAME_MARGIN = math.max(0, math.floor(v)) end
            return K.PROF_FRAME_MARGIN
        end,
    }

    local title = CreateFS(page, "GameFontNormalLarge", "Profesiones")
    title:SetPoint("TOPLEFT", 14, -10)
    title:Hide()  -- el retrato lo pisa y la pestaña ya se llama Profesiones
    local empty = CreateFS(page, "GameFontDisable",
        "No conoces ninguna profesion todavia (llegan con competencias de herramienta o el DM).")
    empty:SetPoint("TOPLEFT", 16, -44); empty:SetWidth(380); empty:SetJustifyH("LEFT"); empty:Hide()

    -- Vista LISTA: los cinco huecos nativos sobre la pagina. Vista RECETAS: panel de crafteo
    -- con boton de volver. Se alternan (P.view), como el libro nativo al abrir una profesion.
    -- Los huecos se anclan a la PAGINA con coordenadas nativas, asi que profList cubre el frame.
    local profList = CreateFrame("Frame", nil, page)
    -- Cubre el LIBRO entero (no la pagina de contenido, 21 px mas baja): los huecos se anclan
    -- dentro con las coordenadas nativas, que son respecto al frame de 550x525.
    profList:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
    profList:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
    -- Por encima de los marcos: si no, el marco recortado taparia icono, nombre y barra.
    profList:SetFrameLevel((page:GetFrameLevel() or 1) + 3)
    profList:EnableMouseWheel(true)
    profList:SetScript("OnMouseWheel", function(_, delta)
        local P = S.professions
        local antes = P.pageNum or 1
        P.pageNum = math.max(1, antes - delta)
        -- La rueda tambien pasa pagina: suena solo si se ha movido.
        if P.pageNum ~= antes then if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("book_page_turned") end end
        if S.RefreshProfessions then S.RefreshProfessions() end
    end)
    -- Pasapaginas: mismas texturas, medidas y anclajes que en Habilidades/Conjuros, para que
    -- las tres pestanas del libro se pasen igual. Anclados al LIBRO, no a la pagina de
    -- contenido (que empieza 21 px mas abajo).
    local nxt = CreateFrame("Button", nil, page)
    nxt:SetSize(32, 32)
    nxt:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -31, 26)
    nxt:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nxt:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nxt:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nxt:SetScript("OnClick", function()
        local P = S.professions
        local antes = P.pageNum or 1
        P.pageNum = antes + 1
        if S.RefreshProfessions then S.RefreshProfessions() end
        if P.pageNum ~= antes then if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("book_page_turned") end end
    end)
    local prev = CreateFrame("Button", nil, page)
    prev:SetSize(32, 32)
    prev:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -66, 26)
    prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prev:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prev:SetScript("OnClick", function()
        local P = S.professions
        if (P.pageNum or 1) > 1 then
            P.pageNum = P.pageNum - 1
            if HarfordUISounds and HarfordUISounds.Play then HarfordUISounds.Play("book_page_turned") end
        end
        if S.RefreshProfessions then S.RefreshProfessions() end
    end)
    local pageText = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pageText:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -110, 38)

    local recipePanel = CreateFrame("Frame", nil, page)
    recipePanel:SetPoint("TOPLEFT", host, "TOPLEFT", 80, -67); recipePanel:SetSize(437, 430)
    recipePanel:Hide()
    recipePanel:EnableMouseWheel(true)
    recipePanel:SetScript("OnMouseWheel", function(_, delta)
        local P = S.professions
        P.recipeOffset = math.max(0, (P.recipeOffset or 0) - delta)
        if S.RefreshProfessions then S.RefreshProfessions() end
    end)
    local backBtn = CreateFrame("Button", nil, recipePanel, "UIPanelButtonTemplate")
    backBtn:SetSize(92, 20); backBtn:SetPoint("TOPLEFT", 0, 0); backBtn:SetText("< Volver")
    backBtn:SetScript("OnClick", function()
        S.professions.view = "list"
        if S.RefreshProfessions then S.RefreshProfessions() end
    end)
    local recipeHeader = CreateFS(recipePanel, "GameFontNormal", "")
    recipeHeader:SetPoint("TOPLEFT", 100, -4); recipeHeader:SetWidth(278); recipeHeader:SetJustifyH("LEFT")
    recipeHeader:SetTextColor(0.25, 0.13, 0.05)

    S.professions = { page = page, title = title, empty = empty, profList = profList,
        recipePanel = recipePanel, recipeHeader = recipeHeader, backBtn = backBtn,
        profBody = profBody, profPage1 = profPage1, profPage2 = profPage2,
        frameCovers = frameCovers, bookmark = bookmarkPage,
        profButtons = {}, recipeRows = {},
        prev = prev, nxt = nxt, pageText = pageText,
        selected = nil, forcedProfession = nil, view = "list", pageNum = 1 }
    -- Solo para diagnostico (`/harford debug run proftex`): medir el alto real de la pagina,
    -- del que depende hasta donde llegan los marcos.
    HarfordCharacterPanel._professionsState = S.professions
end

-- Sello de profesion (pool, pagina completa): el marco ornamentado de la pestaña
-- Profesiones nativa (recorte de 383588) como envoltorio, con icono+borde nativo (383591),
-- nombre en MORPHEUS y la barra de skill nativa (ProfessionsBook + Professions-Progress-Fill).
-- Icono GRANDE del hueco: recorte CIRCULAR, como hace `FormatProfession` en SpellBookFrame.lua
-- para una profesion aprendida (`SetPortraitToTexture(frame.icon, texture)`). La sonda muestra
-- ese icono con texCoord 0,0,1,1 solo porque se capturo SIN profesiones aprendidas: nunca llego
-- a formatearse. Sin el recorte, las esquinas del icono asoman por fuera del aro.
local function SetProfIcon(texture, iconName)
    local path = "Interface\\Icons\\" .. (iconName or "INV_Misc_QuestionMark")
    if SetPortraitToTexture then
        SetPortraitToTexture(texture, path)
    else
        texture:SetTexture(path)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Icono de los BOTONES de hechizo: cuadrado y a pelo. Aqui el nativo NO recorta —
-- `ProfessionButtonTemplate` declara `$parentIconTexture` con `setAllPoints` y sin texCoord, y
-- la sonda lo confirma (40x40, capa BORDER, mezcla BLEND, sin texCoord).
local function SetProfButtonIcon(texture, iconName)
    texture:SetTexture("Interface\\Icons\\" .. (iconName or "INV_Misc_QuestionMark"))
    texture:SetTexCoord(0, 1, 0, 1)
end

local function SetProfTooltip(button, profId, modo)
    button:SetScript("OnEnter", function(self)
        local def = HarfordProfessions and HarfordProfessions.GetDefinition
            and HarfordProfessions.GetDefinition(profId)
        if not (def and GameTooltip) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if modo == "tool" then
            GameTooltip:SetText(def.tool or "Herramienta", 1, 0.82, 0)
            if def.ability then
                GameTooltip:AddLine("Tirada de " .. def.ability .. " con la herramienta.", 1, 1, 1, true)
            end
            GameTooltip:AddLine("Click para tirar.", 0.4, 1, 0.4, true)
        else
            local skill = HarfordProfessions.EffectiveSkill(profId)
            GameTooltip:SetText(def.name or profId, 1, 0.82, 0)
            GameTooltip:AddLine(K.PROF_KIND_LABEL[def.kind] or "Profesion", 1, 1, 1, true)
            if def.ability then
                GameTooltip:AddDoubleLine("Caracteristica", def.ability, 0.7, 0.7, 0.7, 1, 1, 1)
            end
            if def.tool then
                GameTooltip:AddDoubleLine("Herramienta", def.tool, 0.7, 0.7, 0.7, 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("Rango", string.format("%s  %d/%d",
                HarfordProfessions.GetTierName(skill), skill, HarfordProfessions.MAX_SKILL),
                0.7, 0.7, 0.7, 1, 1, 1)
            local recetas = HarfordProfessions.GetRecipes and HarfordProfessions.GetRecipes(profId) or {}
            local alAlcance = 0
            for _, r in ipairs(recetas) do
                if (tonumber(r.skillReq) or 1) <= skill then alAlcance = alAlcance + 1 end
            end
            GameTooltip:AddDoubleLine("Recetas", string.format("%d de %d a tu alcance",
                alAlcance, #recetas), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddLine(" ")
            local abierta = HarfordProfessionsCraftUI and HarfordProfessionsCraftUI.GetOpenProfession
                and HarfordProfessionsCraftUI.GetOpenProfession() == profId
            GameTooltip:AddLine(abierta and "Click para cerrar las recetas."
                or "Click para abrir las recetas.", 0.4, 1, 0.4, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

local function ProfStatusBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(95, 16)
    bar:SetStatusBarTexture("Interface\\Spellbook\\Professions-Progress-Fill")
    bar:SetMinMaxValues(0, 300)
    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetTexture("Interface\\Spellbook\\ProfessionsBook")
    barBg:SetTexCoord(0, 1, 0.0078125, 0.1328125)
    local bgCapL = bar:CreateTexture(nil, "BACKGROUND")
    bgCapL:SetTexture("Interface\\Spellbook\\ProfessionsBook")
    bgCapL:SetTexCoord(0.00390625, 0.06640625, 0.484375, 0.609375)
    bgCapL:SetSize(16, 16); bgCapL:SetPoint("RIGHT", bar, "LEFT", 0, 2)
    local bgCapR = bar:CreateTexture(nil, "BACKGROUND")
    bgCapR:SetTexture("Interface\\Spellbook\\ProfessionsBook")
    bgCapR:SetTexCoord(0.00390625, 0.06640625, 0.625, 0.75)
    bgCapR:SetSize(16, 16); bgCapR:SetPoint("LEFT", bar, "RIGHT", 0, 2)
    barBg:SetPoint("TOPLEFT", bgCapL, "TOPRIGHT", 0, 0)
    barBg:SetPoint("BOTTOMRIGHT", bgCapR, "BOTTOMLEFT", 0, 0)
    local capL = bar:CreateTexture(nil, "OVERLAY")
    capL:SetTexture("Interface\\Spellbook\\ProfessionsBook")
    capL:SetTexCoord(0.00390625, 0.05078125, 0.875, 0.96875)
    capL:SetSize(12, 12); capL:SetPoint("RIGHT", bar, "LEFT", 0, 2)
    bar.text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 2)
    return bar
end

-- Boton de "hechizo" del hueco, 1:1 con ProfessionButtonTemplate: 40x40, icono a todo el boton
-- en capa BORDER, NameFrame de 108x41 (Professions-Item-Border, alpha 0.8) pegado a su derecha,
-- nombre GameFontNormal de 100 de ancho y 2 lineas a LEFT>boton.RIGHT +5,+7 y subtitulo de
-- 95x28 debajo. El primero va a TOPRIGHT -109,-3.
local function ProfSpellButton(parent, previous, secondary)
    local sb = CreateFrame("Button", nil, parent)
    sb:SetSize(40, 40)
    if previous then
        -- XML: en el hueco grande el segundo boton cae DEBAJO del primero; en el pequeno va a
        -- su IZQUIERDA, porque solo hay 46 de alto.
        if secondary then
            sb:SetPoint("TOPRIGHT", previous, "TOPLEFT", -109, 0)
        else
            sb:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
        end
    else
        -- Ya solo hay UN boton por profesion (la tirada se fue al dado de la ventana de recetas),
        -- y va en el hueco de ABAJO, que es el que ocupaba la tirada: en el hueco grande son dos
        -- posiciones de 40 apiladas, asi que la segunda empieza en -43. En el hueco pequeno no
        -- cabe esa segunda fila y se queda arriba.
        sb:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -109, secondary and -3 or -43)
    end
    -- Sonda: 40x40, capa BORDER, mezcla BLEND, sin texCoord. Icono cuadrado y a pelo.
    sb.icon = sb:CreateTexture(nil, "BORDER")
    sb.icon:SetAllPoints(sb)
    sb.icon:SetBlendMode("BLEND")
    sb.nameFrame = sb:CreateTexture(nil, "BACKGROUND")
    sb.nameFrame:SetTexture("Interface\\Spellbook\\ProfessionsBook")
    sb.nameFrame:SetTexCoord(0.00390625, 0.42578125, 0.1484375, 0.46875)
    sb.nameFrame:SetSize(108, 41)
    sb.nameFrame:SetVertexColor(1, 1, 1, 0.8)
    sb.nameFrame:SetPoint("LEFT", sb.icon, "RIGHT", 1, 0)
    sb.label = sb:CreateFontString(nil, "BORDER", "GameFontNormal")
    sb.label:SetPoint("LEFT", sb, "RIGHT", 5, 7)
    sb.label:SetSize(100, 0)
    sb.label:SetJustifyH("LEFT")
    if sb.label.SetMaxLines then sb.label:SetMaxLines(2) end
    sb.sub = sb:CreateFontString(nil, "BORDER", "GameFontDisableSmall")
    sb.sub:SetPoint("TOPLEFT", sb.label, "BOTTOMLEFT", 0, -1)
    sb.sub:SetSize(95, 28)
    sb.sub:SetJustifyH("LEFT")
    sb.sub:SetJustifyV("TOP")
    sb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    sb:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    sb:Hide()
    return sb
end

local function ProfButton(i)
    local P = S.professions
    if P.profButtons[i] then return P.profButtons[i] end
    -- Cada hueco va en SU sitio nativo (PROF_SLOTS) sobre la pagina, no apilados con un paso
    -- fijo: el nativo tiene DOS huecos grandes (con aro de icono) y TRES pequenos (sin aro), y
    -- el ornamento de todos ellos esta horneado en la textura de la pagina. El boton no dibuja
    -- marco propio.
    local slotDef = K.PROF_SLOTS[i] or K.PROF_SLOTS[#K.PROF_SLOTS]
    local secondary = slotDef.kind == "secondary"
    local b = CreateFrame("Button", nil, P.profList)
    b.slotKind = slotDef.kind
    b:SetSize(slotDef.w, slotDef.h)
    b:SetPoint("TOPLEFT", P.profList, "TOPLEFT", slotDef.x, slotDef.y)
    -- Sin resaltado al pasar el raton: el hueco NO es clicable (como en el libro nativo, donde
    -- se pulsa el boton de hechizo), asi que iluminarlo entero prometia una interaccion que
    -- no existe. El resaltado lo pone `spellOpen`, que si lo es.
    b:EnableMouse(false)

    b.bar = ProfStatusBar(b)
    b.barText = b.bar.text

    if not secondary then
        -- XML PrimaryProfessionTemplate ------------------------------------------------
        -- iconBorder 72x72 en TOPLEFT +7,-7. La region recortada de ProfessionsBook mide 74x74
        -- reales (manifiesto de atlas del propio XML: Professions-MajorRing-Normal), y el
        -- nativo la mete en 72: se conserva ese encogimiento de 2 px.
        -- Capa OVERLAY/0, no ARTWORK: es lo que devuelve la sonda del frame nativo
        -- (PrimaryProfession1IconBorder drawLayer = OVERLAY/0), coherente con el
        -- <Layer level="OVERLAY"> del XML. El icono va en BORDER y queda debajo.
        b.iconBorder = b:CreateTexture(nil, "OVERLAY")
        b.iconBorder:SetTexture("Interface\\Spellbook\\ProfessionsBook")
        b.iconBorder:SetTexCoord(0.43359375, 0.72265625, 0.1484375, 0.7265625)
        b.iconBorder:SetSize(72, 72); b.iconBorder:SetPoint("TOPLEFT", 7, -7)
        b.icon = b:CreateTexture(nil, "BORDER")
        b.icon:SetBlendMode("ADD")   -- XML: alphaMode="ADD"
        b.icon:SetPoint("TOPLEFT", b.iconBorder, "TOPLEFT", 1, -1)
        b.icon:SetPoint("BOTTOMRIGHT", b.iconBorder, "BOTTOMRIGHT", -1, 1)

        b.name = b:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
        b.name:SetPoint("TOPLEFT", 100, -2); b.name:SetJustifyH("LEFT")
        b.name:SetTextColor(1, 0.82, 0)
        b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -33)   -- XML: rank
        b.sub:SetWidth(300); b.sub:SetJustifyH("LEFT")
        b.sub:SetTextColor(1, 1, 1)
        b.bar:SetPoint("TOPLEFT", b.sub, "BOTTOMLEFT", 14, -5)    -- XML: rank.BOTTOMLEFT +14,-5

        b.missingHeader = b:CreateFontString(nil, "OVERLAY", "QuestTitleFontBlackShadow")
        b.missingHeader:SetPoint("TOPLEFT", 120, -13)
        b.missingHeader:SetJustifyH("LEFT")
        b.missingHeader:SetTextColor(0.85, 0.7, 0.6)
        b.missingText = b:CreateFontString(nil, "OVERLAY", "SubSpellFont")
        b.missingText:SetPoint("TOPLEFT", b.missingHeader, "BOTTOMLEFT", 0, -1)
        b.missingText:SetWidth(305); b.missingText:SetJustifyH("LEFT")
        b.missingText:SetTextColor(0.1, 0.05, 0.05)
    else
        -- XML SecondaryProfessionTemplate ----------------------------------------------
        -- NO se usa con el reparto actual de cinco huecos iguales: se conserva porque es la
        -- transcripcion fiel del hueco pequeno nativo y volveria a hacer falta si algun dia se
        -- adopta el reparto 2 principales + 3 secundarias.
        -- El hueco pequeno NO tiene aro de icono: solo barra, rango y nombre, montados de abajo
        -- hacia arriba (statusBar en BOTTOMLEFT +16,-1 y el resto anclado sobre ella).
        b.bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 16, -1)
        b.sub = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.sub:SetPoint("BOTTOMLEFT", b.bar, "TOPLEFT", -14, 4)
        b.sub:SetPoint("BOTTOMRIGHT", b.bar, "TOPRIGHT", 25, 4)
        b.sub:SetJustifyH("LEFT")
        b.name = b:CreateFontString(nil, "OVERLAY", "QuestFont_Shadow_Small")
        b.name:SetPoint("BOTTOMLEFT", b.sub, "TOPLEFT", 0, 2)
        b.name:SetPoint("BOTTOMRIGHT", b.sub, "TOPRIGHT", 0, 2)
        b.name:SetJustifyH("LEFT")
        b.name:SetTextColor(1, 0.82, 0)

        b.missingHeader = b:CreateFontString(nil, "OVERLAY", "QuestFont_Large")
        b.missingHeader:SetPoint("TOPLEFT", 4, -15)
        b.missingHeader:SetJustifyH("LEFT")
        b.missingHeader:SetTextColor(0.15, 0.1, 0.1)
        b.missingText = b:CreateFontString(nil, "OVERLAY", "SubSpellFont")
        b.missingText:SetPoint("RIGHT", b, "RIGHT", -5, 0)
        b.missingText:SetWidth(250); b.missingText:SetJustifyH("LEFT")
        b.missingText:SetTextColor(0.1, 0.05, 0.05)
    end

    -- El hueco en si NO abre nada (como el libro nativo, donde se pulsa el boton de hechizo):
    -- abrir la profesion es `spellOpen`. La tirada suelta se fue al boton de dado de la
    -- ventana de recetas, asi que aqui ya no hay un segundo boton.
    b.spellOpen = ProfSpellButton(b, nil, secondary)
    P.profButtons[i] = b
    return b
end

-- Fila de receta (pool, panel derecho): icono + nombre(reqskill) + materiales + boton Craftear.
local function RecipeRow(i)
    local P = S.professions
    if P.recipeRows[i] then return P.recipeRows[i] end
    local r = CreateFrame("Frame", nil, P.recipePanel)
    r:SetSize(449, 40); r:SetPoint("TOPLEFT", 0, -26 - ((i - 1) * 42))
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(26, 26); r.icon:SetPoint("TOPLEFT", 0, -2); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); r.name:SetPoint("TOPLEFT", 32, -2); r.name:SetWidth(300); r.name:SetJustifyH("LEFT"); r.name:SetTextColor(0.25, 0.13, 0.05)
    r.mats = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); r.mats:SetPoint("TOPLEFT", 32, -18); r.mats:SetWidth(360); r.mats:SetJustifyH("LEFT")
    r.craft = CreateFrame("Button", nil, r, "UIPanelButtonTemplate"); r.craft:SetSize(58, 20); r.craft:SetPoint("TOPRIGHT", 0, -2); r.craft:SetText("Craftear")
    P.recipeRows[i] = r
    return r
end

local function RefreshProfessions()
    local P = S.professions
    if not P or not HarfordProfessions then return end
    local known = {}
    local forced = P.forcedProfession and HarfordProfessions.GetDefinition(P.forcedProfession)
    if forced then
        -- Una estacion del mundo abre su profesion aunque el PJ aun no la conozca.
        known[1] = forced
    else
        for _, def in ipairs(HarfordProfessions.GetProfessions()) do
            if HarfordProfessions.KnowsProfession(def.id) then known[#known + 1] = def end
        end
    end
    P.empty:Hide()  -- los envoltorios vacios ya explican como se aprende una profesion

    -- Mantener seleccion valida.
    local selValid = false
    for _, d in ipairs(known) do if d.id == P.selected then selValid = true break end end
    if not selValid then P.selected = known[1] and known[1].id or nil end

    -- Dos vistas alternadas: LISTA de sellos <-> RECETAS de la seleccionada
    if P.view ~= "recipes" or not P.selected then P.view = "list" end
    local isList = P.view == "list"
    P.profList:SetShown(isList)
    P.recipePanel:SetShown(not isList)
    if P.prev then P.prev:SetShown(isList) end
    if P.nxt then P.nxt:SetShown(isList) end
    if P.pageText then P.pageText:SetShown(isList) end

    -- Los marcos CRECEN con las profesiones: uno por cada una conocida, y un unico hueco vacio
    -- cuando no hay ninguna (a modo de invitacion). El nativo enseña siempre dos porque solo
    -- admite dos principales; aqui todas son equivalentes y no hay numero fijo que reservar.
    local VISIBLE = #K.PROF_SLOTS
    local totalSlots = math.max(#known, 1)
    local maxPage = math.max(1, math.ceil(totalSlots / VISIBLE))
    P.pageNum = math.max(1, math.min(P.pageNum or 1, maxPage))
    local offset = (P.pageNum - 1) * VISIBLE
    -- Marcos visibles en ESTA pagina: los que tengan hueco detras. Un marco suelto sobre
    -- pergamino vacio se leeria como una profesion que no esta.
    local enEstaPagina = math.max(0, math.min(VISIBLE, totalSlots - offset))
    for i, cover in ipairs(P.frameCovers or {}) do
        cover:SetShown(isList and i <= enEstaPagina)
    end
    if P.pageText then
        -- Con una sola pagina no se anuncia el numero: el libro nativo tampoco lo hace.
        P.pageText:SetText(maxPage > 1 and ("Pagina " .. P.pageNum) or "")
    end
    if P.prev then if P.pageNum > 1 then P.prev:Enable() else P.prev:Disable() end end
    if P.nxt then if P.pageNum < maxPage then P.nxt:Enable() else P.nxt:Disable() end end
    for i = 1, VISIBLE do
        local slot = offset + i
        local def = isList and known[slot] or nil
        local emptySlot = isList and not def and slot <= totalSlots
        local b = P.profButtons[i] or ((def or emptySlot) and ProfButton(i))
        if b then
            if def then
                local profId = def.id
                local skill = HarfordProfessions.EffectiveSkill(profId)
                -- Solo los huecos GRANDES tienen aro de icono (SecondaryProfessionTemplate no
                -- declara ninguno), asi que cada acceso al icono va guardado.
                if b.icon then
                    -- El icono del hueco va SIEMPRE al 60% y desaturado, tambien con la
                    -- profesion aprendida: el `OnLoad` de PrimaryProfessionTemplate lo deja asi
                    -- y `FormatProfession` nunca lo revierte (solo llama a SetPortraitToTexture).
                    -- Devolverlo a color pleno, con la mezcla ADD encima, lo dejaba lavado y con
                    -- tinte. Ese aspecto palido es el normal del nativo, no el de "sin aprender".
                    SetProfIcon(b.icon, def.icon)
                    b.icon:SetAlpha(0.6)
                    if SetDesaturation then SetDesaturation(b.icon, true) end
                    b.icon:Show()
                end
                b.missingHeader:Hide()
                b.missingText:Hide()
                b.name:Show()
                b.sub:Show()
                b.name:SetText(def.name)
                b.name:SetTextColor(1, 0.82, 0)
                b.sub:SetText(HarfordProfessions.GetTierName(skill))
                b.bar:Show()
                b.bar:SetValue(skill)
                b.barText:SetText(string.format("%d/%d", skill, HarfordProfessions.MAX_SKILL))
                -- El sello es el envoltorio: no abre nada por si mismo (como el libro nativo,
                -- donde se pulsa el boton de hechizo). Abrir la profesion es `spellOpen`.
                b:SetScript("OnClick", nil)
                SetProfButtonIcon(b.spellOpen.icon, def.icon)
                b.spellOpen.label:SetText(def.name)
                SetProfTooltip(b.spellOpen, profId, "open")
                b.spellOpen:SetScript("OnClick", function()
                    P.selected = profId
                    -- Alterna: si ya esta abierta CON ESTA profesion se cierra; si esta abierta
                    -- con otra, cambia a esta sin cerrarse. La estacion del mundo no usa esto:
                    -- ahi siempre se abre.
                    if HarfordProfessionsCraftUI and HarfordProfessionsCraftUI.Toggle then
                        HarfordProfessionsCraftUI.Toggle(profId)
                    else
                        P.view = "recipes"
                        P.recipeOffset = 0
                        RefreshProfessions()
                    end
                end)
                b.spellOpen:Show()
                b:Show()
            elseif emptySlot then
                -- Hueco VACIO, tal y como lo declara el XML: se ocultan professionName, rank y
                -- barra, y se muestran missingHeader/missingText en SU posicion (+120,-13), que
                -- no es la del nombre de una profesion aprendida.
                -- El aro sigue ahi con el icono desaturado al 60% (OnLoad del template nativo).
                b.name:Hide()
                b.sub:Hide()
                b.missingHeader:SetText("Sin profesiones")
                b.missingHeader:Show()
                b.missingText:SetText("Se aprende con la competencia de su herramienta o por decision del DM.")
                b.missingText:Show()
                if b.icon then
                    b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    b.icon:SetAlpha(0.6)
                    if SetDesaturation then SetDesaturation(b.icon, true) end
                    b.icon:Show()
                end
                b.bar:Hide()
                b:SetScript("OnClick", nil)
                b.spellOpen:Hide()
                b:Show()
            else
                b:Hide()
            end
        end
    end

    local sel = P.selected and HarfordProfessions.GetDefinition(P.selected)
    if sel then
        local skill = HarfordProfessions.EffectiveSkill(sel.id)
        P.recipeHeader:SetText(string.format("%s  |cff6b4a2a%d/%d %s|r", sel.name, skill,
            HarfordProfessions.MAX_SKILL, HarfordProfessions.GetTierName(skill)))
    else
        P.recipeHeader:SetText("")
    end
    local recipes = (not isList and sel) and HarfordProfessions.GetRecipes(sel.id) or {}
    -- Ventana deslizante: 9 filas visibles, rueda para desplazar (parche hasta tener la
    -- ventana nativa de recetas replicada; ver sonda nativeprobe prof)
    local RECIPES_VISIBLE = 9
    local recipeMax = math.max(0, #recipes - RECIPES_VISIBLE)
    P.recipeOffset = math.max(0, math.min(P.recipeOffset or 0, recipeMax))
    local visibleRecipes = {}
    for i = 1, RECIPES_VISIBLE do
        local rec = recipes[P.recipeOffset + i]
        if rec then visibleRecipes[#visibleRecipes + 1] = rec end
    end
    recipes = visibleRecipes
    for i, rec in ipairs(recipes) do
        local row = RecipeRow(i)
        local recipeId = rec.id
        local recipeName = rec.name or rec.id
        local recipeIcon = rec.icon
        local recipeSkillReq = tonumber(rec.skillReq) or 1
        local ok, reason, detail = HarfordProfessions.CanCraft(recipeId)
        local reasonText = reason
        local parts = {}
        for _, m in ipairs(detail or {}) do
            local col = m.missingId and "|cff888888" or (m.have >= m.need and "|cff44dd44" or "|cffdd4444")
            parts[#parts + 1] = string.format("%s%s %d/%d|r", col, m.name, m.have, m.need)
        end
        if #parts == 0 then parts[1] = ok and "Listo" or (reason or "") end
        row.icon:SetTexture("Interface\\Icons\\" .. (recipeIcon or "INV_Misc_QuestionMark"))
        row.name:SetText(string.format("%s |cff808080(%d)|r", recipeName, recipeSkillReq))
        row.mats:SetText(table.concat(parts, "  "))
        row.craft:SetEnabled(ok and true or false)
        row.craft:SetScript("OnClick", function()
            HarfordProfessions.Craft(recipeId)
            RefreshProfessions()
        end)
        row.craft:SetScript("OnEnter", function(self)
            if reasonText then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText(reasonText, 1, 0.4, 0.4, true)
                GameTooltip:Show()
            end
        end)
        row.craft:SetScript("OnLeave", GameTooltip_Hide)
        row:Show()
    end
    for i = #recipes + 1, #P.recipeRows do P.recipeRows[i]:Hide() end
end

HarfordCharacterProfessions.CreateProfessionsPage = CreateProfessionsPage
HarfordCharacterProfessions.RefreshProfessions = RefreshProfessions
