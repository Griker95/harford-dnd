------------------------------------------------------------
-- HarfordProfessionTrainerUI - Ventana de entrenador de recetas.
--
-- Es lo que abre el gossip del NPC: una opcion "lua" del gossip llama a
-- `HarfordTrainerAPI.OpenTrainer("herreria_experto")` y esta API monta la ventana entera a
-- partir de ese id. El NPC no pasa recetas ni precios: solo dice quien es; el precio vive en
-- `recipe.trainCost` y lo cobra el modulo de entrenadores tras confirmacion del servidor.
--
-- Solo UI. Que ensena cada entrenador lo decide `HarfordProfessionTrainers` y aprender pasa
-- siempre por su `Purchase`/`Teach`, que revalida rango, profesion, dinero y si ya la sabes: la
-- ventana no es una via alternativa para aprender nada.
--
-- Reutiliza `HarfordProfessionsCraftSkin` (replica del TradeSkillFrame nativo, generada desde la sonda) en
-- vez de inventar arte para un ClassTrainerFrame que no tenemos capturado: misma familia visual
-- que la ventana de recetas, y sin rutas de textura a ciegas.
------------------------------------------------------------

HarfordProfessionTrainerUI = HarfordProfessionTrainerUI or {}
local API = HarfordProfessionTrainerUI

local frame
local state = { trainerId = nil, selected = nil, offset = 0, rows = {} }

local ROWS_VISIBLE = 25
local ROW_H = 16

local RefreshUI   -- forward: las filas y el scroll lo llaman antes de estar definido

local function Trainers() return _G.HarfordProfessionTrainers end
local function Profs() return _G.HarfordProfessions end

local function Def()
    local T = Trainers()
    return T and T.Get and T.Get(state.trainerId or "")
end

-- El dinero lo pinta la funcion NATIVA.
--
-- El resto del addon (registro de misiones, quests de mundo) ya la usa, asi que el mismo dinero
-- se veia de dos formas distintas segun la ventana. Y el montaje a mano metia un espacio de
-- separacion que el nativo no pone.
--
-- No se fuerza nada para el modo daltonico: si alguien lo tiene puesto y prefiere las monedas,
-- lo desactiva. Pelearse con un ajuste del cliente para imponer un aspecto no compensa.
local function FormatMoney(copper)
    copper = math.max(0, math.floor(tonumber(copper) or 0))
    if copper == 0 then return "Gratis" end
    if GetCoinTextureString then return GetCoinTextureString(copper) end
    -- Sin la nativa disponible, texto plano: nunca dejar el precio en blanco.
    local oro, resto = math.floor(copper / 10000), copper % 10000
    local plata, cobre = math.floor(resto / 100), resto % 100
    local partes = {}
    if oro > 0 then partes[#partes + 1] = oro .. "o" end
    if plata > 0 then partes[#partes + 1] = plata .. "p" end
    if cobre > 0 then partes[#partes + 1] = cobre .. "c" end
    return table.concat(partes, " ")
end

------------------------------------------------------------
-- Estado de una receta frente a este entrenador
------------------------------------------------------------

-- Devuelve clave, etiqueta y color. Es la unica fuente de "que le pasa a esta receta", para que
-- la fila, el detalle y el boton no puedan contradecirse.
function API.GetRecipeState(recipe)
    local P = Profs()
    if not (P and recipe) then return "no", "No disponible", { 0.5, 0.5, 0.5 } end
    local sabida = P.IsRecipeLearned and P.IsRecipeLearned(recipe.id)
    if sabida then return "sabida", "Ya la conoces", { 0.5, 0.5, 0.5 } end
    if P.KnowsProfession and not P.KnowsProfession(recipe.profession) then
        return "sinprof", "No conoces la profesion", { 0.6, 0.2, 0.2 }
    end
    -- Degradado de dificultad respecto a TU habilidad, la misma regla que la ventana de recetas.
    -- Aqui el escalon trivial NO baja a gris: el gris es exclusivamente "ya la conoces", y dos
    -- cosas distintas no pueden compartir color en una lista que muestra ambas.
    local skill = (P.EffectiveSkill and P.EffectiveSkill(recipe.profession)) or 0
    local req = tonumber(recipe.skillReq) or 1
    local dr, dg, db, escalon = 0.1, 0.9, 0.1, "facil"
    if P.DifficultyColor then dr, dg, db, escalon = P.DifficultyColor(skill, req) end
    if escalon == "trivial" then dr, dg, db = 0.25, 0.75, 0.25 end

    if skill < req then
        return "skill", "Requiere " .. req .. " de habilidad", { dr, dg, db }
    end
    -- Una economia sin inicializar vale 0, asi que aqui no hay dos casos: o llega el dinero o no.
    -- El mensaje dice el precio, que es lo unico accionable; antes decia "termina la creacion",
    -- que para un personaje anterior a la creacion nueva salia en TODAS las recetas.
    local cost = Trainers() and Trainers().GetRecipeCost and Trainers().GetRecipeCost(recipe.id) or 0
    if cost > 0 and not (HarfordDnDEconomy and HarfordDnDEconomy.CanAfford
        and HarfordDnDEconomy.CanAfford(cost)) then
        return "dinero", "Te falta dinero: cuesta " .. FormatMoney(cost), { 0.8, 0.3, 0.3 }
    end
    return "puede", "Puedes aprenderla", { dr, dg, db }
end

local function RecipeIcon(recipe)
    local icon = recipe and recipe.icon
    if not icon or icon == "" then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if icon:find("\\") then return icon end
    return "Interface\\Icons\\" .. icon
end

-- Las recetas del entrenador, ordenadas como en el nativo: por requisito y luego por nombre.
local function Lista()
    local T, def = Trainers(), Def()
    if not (T and def and T.GetRecipesFor) then return {} end
    local out = T.GetRecipesFor(def)
    table.sort(out, function(a, b)
        local ra, rb = tonumber(a.skillReq) or 0, tonumber(b.skillReq) or 0
        if ra ~= rb then return ra < rb end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

------------------------------------------------------------
-- Construccion
------------------------------------------------------------

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(300, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index - 1) * ROW_H)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_H - 2, ROW_H - 2)
    row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -84, 0)
    row.text:SetJustifyH("LEFT")

    row.price = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.price:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.price:SetWidth(78)
    row.price:SetJustifyH("RIGHT")

    row.sel = row:CreateTexture(nil, "BACKGROUND")
    row.sel:SetAllPoints(row)
    row.sel:SetColorTexture(1, 1, 1, 0.18)
    row.sel:Hide()

    -- El nativo no pinta franja al pasar por encima: solo aclara el texto.
    row:SetScript("OnEnter", function(self)
        if self.recipe then self.text:SetTextColor(1, 1, 1) end
    end)
    row:SetScript("OnLeave", function(self)
        if self.recipe and state.selected ~= self.recipe.id then
            local _, _, c = API.GetRecipeState(self.recipe)
            self.text:SetTextColor(c[1], c[2], c[3])
        end
    end)
    row:SetScript("OnClick", function(self)
        if not self.recipe then return end
        state.selected = self.recipe.id
        if HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("craft_recipe_selected")
        end
        RefreshUI()
    end)
    return row
end

local function CreateFrameIfNeeded()
    if frame then return frame end
    frame = CreateFrame("Frame", "HarfordProfessionTrainerFrame", UIParent, "PortraitFrameTemplate")
        or CreateFrame("Frame", "HarfordProfessionTrainerFrame", UIParent, "ButtonFrameTemplate")
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
    -- Un frame recien creado nace visible, asi que este Hide de construccion SI dispara OnHide:
    -- la bandera evita que suene el cierre antes de haberse abierto nunca.
    frame:HookScript("OnHide", function(self)
        if self._harfordSonidoListo and HarfordUISounds and HarfordUISounds.Play then
            HarfordUISounds.Play("craft_window_closed")
        end
    end)
    frame._harfordSonidoListo = true
    table.insert(UISpecialFrames, "HarfordProfessionTrainerFrame")

    if frame.Inset then frame.Inset:Hide() end
    local skin = HarfordProfessionsCraftSkin and HarfordProfessionsCraftSkin.Build and HarfordProfessionsCraftSkin.Build(frame)
    local byUid = skin and skin.byUid or {}
    local insetLeft, insetRight = byUid["root.f3"], byUid["root.f4"]
    local bar = byUid["root.f7"]
    if not (insetLeft and insetRight and bar) then
        HarfordChat.Print("|cffff5555No se pudo construir el armazon de la ventana de entrenador|r")
        return frame
    end
    for _, inset in ipairs({ insetLeft, insetRight }) do
        if inset.SetFrameLevel and frame.GetFrameLevel then
            inset:SetFrameLevel(frame:GetFrameLevel())
        end
    end
    frame.skillBar = bar
    frame.skillText = bar:CreateFontString(nil, "OVERLAY", "WhiteNormalNumberFont")
    frame.skillText:SetPoint("CENTER", bar, "CENTER", 0, 0)

    local list = CreateFrame("Frame", nil, frame)
    list:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -83)
    list:SetSize(300, ROWS_VISIBLE * ROW_H)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        state.offset = math.max(0, state.offset - delta)
        RefreshUI()
    end)
    frame.list = list
    for i = 1, ROWS_VISIBLE do state.rows[i] = CreateRow(list, i) end

    local slider = CreateFrame("Slider", nil, frame, "HybridScrollBarTemplate")
    if not slider then slider = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate") end
    slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 1, -14)
    slider:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 1, 12)
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

    -- Panel derecho: detalle de la receta seleccionada.
    local d = CreateFrame("Frame", nil, frame)
    d:SetPoint("TOPLEFT", insetRight, "TOPLEFT", 12, -12)
    d:SetPoint("BOTTOMRIGHT", insetRight, "BOTTOMRIGHT", -12, 12)
    frame.detail = d

    d.icon = d:CreateTexture(nil, "ARTWORK")
    d.icon:SetSize(40, 40)
    d.icon:SetPoint("TOPLEFT", d, "TOPLEFT", 0, 0)
    d.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    d.title = d:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    d.title:SetPoint("TOPLEFT", d.icon, "TOPRIGHT", 8, -4)
    d.title:SetPoint("RIGHT", d, "RIGHT", 0, 0)
    d.title:SetJustifyH("LEFT")
    d.title:SetWordWrap(false)

    d.req = d:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    d.req:SetPoint("TOPLEFT", d.title, "BOTTOMLEFT", 0, -4)
    d.req:SetJustifyH("LEFT")

    d.price = d:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    d.price:SetPoint("TOPLEFT", d.req, "BOTTOMLEFT", 0, -3)
    d.price:SetJustifyH("LEFT")

    d.body = d:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    d.body:SetPoint("TOPLEFT", d.price, "BOTTOMLEFT", 0, -10)
    d.body:SetPoint("RIGHT", d, "RIGHT", 0, 0)
    d.body:SetJustifyH("LEFT")
    d.body:SetJustifyV("TOP")
    d.body:SetSpacing(3)

    local exitBtn = CreateFrame("Button", nil, frame, "MagicButtonTemplate")
    exitBtn:SetSize(80, 22)
    exitBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 4)
    exitBtn:SetText("Salir")
    exitBtn:SetScript("OnClick", function() API.Close() end)

    frame.learnBtn = CreateFrame("Button", nil, frame, "MagicButtonTemplate")
    frame.learnBtn:SetSize(80, 22)
    frame.learnBtn:SetPoint("TOPRIGHT", exitBtn, "TOPLEFT", 0, 0)
    frame.learnBtn:SetText("Aprender")
    frame.learnBtn:SetScript("OnClick", function()
        local T, P = Trainers(), Profs()
        if not (T and T.Purchase and state.selected) or frame._buying then return end
        frame._buying = true
        frame.learnBtn:SetEnabled(false)
        T.Purchase(state.trainerId, state.selected, function(ok, err, recipe)
            frame._buying = false
            if ok then
                HarfordChat.Print("Has aprendido |cffffd100" ..
                    tostring(recipe and recipe.name or state.selected) .. "|r.")
            else
                HarfordChat.Print("|cffff5555" .. tostring(err or "No se puede aprender") .. "|r")
            end
            RefreshUI()
        end)
    end)

    return frame
end

------------------------------------------------------------
-- Refresco
------------------------------------------------------------

RefreshUI = function()
    if not frame then return end
    local def = Def()
    if not def then return end
    local P = Profs()
    local recetas = Lista()

    if frame.TitleText then
        frame.TitleText:SetWidth(0)
        frame.TitleText:SetText(tostring(def.name or def.id) ..
            (def.tier and (" (" .. def.tier .. ")") or ""))
    end
    local profDef = P and P.GetDefinition and P.GetDefinition(def.profession)
    if frame.portrait then
        local ruta = "Interface\\Icons\\" .. ((profDef and profDef.icon) or "INV_Misc_QuestionMark")
        if SetPortraitToTexture then
            SetPortraitToTexture(frame.portrait, ruta)
        else
            frame.portrait:SetTexture(ruta)
            frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    local skill = (P and P.EffectiveSkill and P.EffectiveSkill(def.profession)) or 0
    local maximo = (P and P.MAX_SKILL) or 300
    if frame.skillText then
        frame.skillText:SetText(string.format("%s %d/%d",
            tostring(profDef and profDef.name or def.profession), skill, maximo))
    end

    -- Scroll
    local total = #recetas
    local maxOffset = math.max(0, total - ROWS_VISIBLE)
    state.offset = math.max(0, math.min(state.offset, maxOffset))
    if frame.scrollSlider then
        frame.scrollSlider._updating = true
        frame.scrollSlider:SetMinMaxValues(0, maxOffset)
        frame.scrollSlider:SetValue(state.offset)
        frame.scrollSlider._updating = false
        frame.scrollSlider:SetShown(maxOffset > 0)
    end

    for i = 1, ROWS_VISIBLE do
        local row = state.rows[i]
        local r = recetas[i + state.offset]
        row.recipe = r
        if not r then
            row:Hide()
        else
            local _, _, color = API.GetRecipeState(r)
            row.icon:SetTexture(RecipeIcon(r))
            row.text:SetText(tostring(r.name or r.id))
            row.text:SetTextColor(color[1], color[2], color[3])
            local cost = Trainers() and Trainers().GetRecipeCost and Trainers().GetRecipeCost(r.id) or 0
            row.price:SetText(FormatMoney(cost))
            row.sel:SetShown(state.selected == r.id)
            row:Show()
        end
    end

    -- Detalle
    local sel = state.selected and P and P.GetRecipe and P.GetRecipe(state.selected) or nil
    local d = frame.detail
    if not sel then
        d.icon:SetTexture(nil)
        d.title:SetText("")
        d.req:SetText("")
        d.price:SetText("")
        d.body:SetText(total > 0 and "Elige una receta de la lista."
            or "Este entrenador no tiene nada que ensenarte.")
        frame.learnBtn:SetEnabled(false)
        return
    end

    local clave, etiqueta, color = API.GetRecipeState(sel)
    d.icon:SetTexture(RecipeIcon(sel))
    d.title:SetText(tostring(sel.name or sel.id))
    d.req:SetText(string.format("Requiere %s %d",
        tostring(profDef and profDef.name or def.profession), tonumber(sel.skillReq) or 1))

    local cost = Trainers() and Trainers().GetRecipeCost and Trainers().GetRecipeCost(sel.id) or 0
    d.price:SetText("Precio: " .. FormatMoney(cost))

    local lineas = { string.format("|cff%02x%02x%02x%s|r",
        color[1] * 255, color[2] * 255, color[3] * 255, etiqueta) }
    if sel.materials and #sel.materials > 0 then
        lineas[#lineas + 1] = " "
        lineas[#lineas + 1] = "Materiales:"
        for _, m in ipairs(sel.materials) do
            lineas[#lineas + 1] = string.format("  %s x%d", tostring(m.key), tonumber(m.qty) or 1)
        end
    end
    d.body:SetText(table.concat(lineas, "\n"))
    frame.learnBtn:SetEnabled(clave == "puede" and not frame._buying)
end

------------------------------------------------------------
-- API publica
------------------------------------------------------------

-- Lo que llama la opcion de gossip del NPC. Solo necesita el id del entrenador.
function API.Open(trainerId)
    local T = Trainers()
    if not (T and T.Get) then return false, "Entrenadores no disponibles" end
    local def = T.Get(trainerId)
    if not def then return false, "Entrenador desconocido: " .. tostring(trainerId) end

    local built, err = pcall(CreateFrameIfNeeded)
    if not built then
        HarfordChat.Print("|cffff5555Error construyendo la ventana de entrenador:|r " .. tostring(err))
        return false, err
    end
    if state.trainerId ~= def.id then state.selected, state.offset = nil, 0 end
    state.trainerId = def.id
    if HarfordUISounds and HarfordUISounds.Play then
        HarfordUISounds.Play("craft_window_opened")
    end
    frame:Show()
    local ok, refreshErr = pcall(RefreshUI)
    if not ok then
        HarfordChat.Print("|cffff5555Error refrescando la ventana de entrenador:|r " .. tostring(refreshErr))
    end
    return true
end

function API.Close()
    if frame then frame:Hide() end
end

function API.Toggle(trainerId)
    if frame and frame:IsShown() and (not trainerId or state.trainerId == trainerId) then
        API.Close()
        return false
    end
    return API.Open(trainerId or state.trainerId)
end

function API.GetOpenTrainer()
    if frame and frame:IsShown() then return state.trainerId end
    return nil
end

-- Se cuelga de la misma API que usa el gossip para todo lo demas.
_G.HarfordTrainerAPI = _G.HarfordTrainerAPI or {}
_G.HarfordTrainerAPI.OpenTrainer = API.Open
_G.HarfordTrainerAPI.CloseTrainer = API.Close
