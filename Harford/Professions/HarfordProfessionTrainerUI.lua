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
-- Replica el ClassTrainerFrame NATIVO a partir de su XML real de la build 45745, recuperado de
-- Townlong Yak y guardado en `RuleSource/framexml/`. Ya no se aproxima con el arte de la ventana
-- de recetas: se usan las texturas y medidas que el propio Blizzard declara.
------------------------------------------------------------

HarfordProfessionTrainerUI = HarfordProfessionTrainerUI or {}
local API = HarfordProfessionTrainerUI

local frame
-- Los tres filtros del nativo, con SUS valores por defecto (TRAINER_FILTER_AVAILABLE = 1,
-- UNAVAILABLE = 1, USED = 0): las ya conocidas empiezan OCULTAS.
local state = { trainerId = nil, selected = nil, offset = 0, rows = {},
                filtro = { puede = true, nopuede = true, sabida = false } }

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
        local d = P.GetDefinition and P.GetDefinition(recipe.profession)
        return "sinprof", ((d and d.name) or recipe.profession)
            .. " (" .. tostring(tonumber(recipe.skillReq) or 1) .. ")", { 0.6, 0.2, 0.2 }
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
        -- Formato del nativo (TRAINER_REQ_SKILL_RANK = "%s (%d)"), que con el prefijo de la fila
        -- queda "Requiere: Alquimia (50)". Antes decia "Requiere: Requiere 50 de habilidad".
        local d = P.GetDefinition and P.GetDefinition(recipe.profession)
        return "skill", ((d and d.name) or recipe.profession) .. " (" .. req .. ")", { dr, dg, db }
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

------------------------------------------------------------
-- Replica del ClassTrainerFrame nativo
--
-- Medidas y texturas tomadas del XML REAL de la build 45745, no de un pantallazo:
--   RuleSource/framexml/Blizzard_TrainerUI.xml  (ClassTrainerFrame, ClassTrainerStatusBar)
--   RuleSource/framexml/UIPanelTemplates.xml    (UIServiceButtonTemplate, la fila)
--   RuleSource/framexml/Blizzard_TrainerUI.lua  (constantes y pintado de fila)
--
-- Lo importante que se aprendio de ahi: el entrenador nativo NO tiene panel de detalle a la
-- derecha. Es UNA sola columna, y cada fila lleva icono, nombre, una linea de requisito debajo y
-- el precio a la derecha. El panel de detalle que teniamos era invento nuestro.
------------------------------------------------------------

-- Constantes del Lua nativo (CLASS_TRAINER_*)
local FILAS_VISIBLES = 7      -- CLASS_TRAINER_SKILLS_DISPLAYED
local FILA_ALTO      = 47     -- CLASS_TRAINER_SKILL_HEIGHT
-- Dos anchos: el nativo estrecha las filas cuando aparece la barra de scroll y las ensancha
-- cuando no hace falta (ClassTrainerScrollFrameScrollBar.Show/Hide del Lua nativo).
local FILA_ANCHO_CON = 298    -- CLASS_TRAINER_SKILL_BARBUTTON_WIDTH
local FILA_ANCHO_SIN = 318    -- CLASS_TRAINER_SKILL_BUTTON_WIDTH
local SCROLL_ALTO    = 330    -- CLASS_TRAINER_SCROLL_HEIGHT
-- La sonda del cliente da el scroll en 320x330 anclado al Inset por TOPLEFT +5,-5, con la barra
-- oculta: 318 + 2. Con barra visible seria 300.
local SCROLL_ANCHO   = 320

-- Atlas 512x512 del entrenador. Las coordenadas salen tal cual del XML; el bloque comentado del
-- propio XML dice que trozo es cada una (fondo 299x334, fila 293x47, hover y seleccion).
local TEX_ENTRENADOR = "Interface\\ClassTrainerFrame\\TrainerTextures"
local C_FONDO = { 0.00195313, 0.58593750, 0.00195313, 0.65429688 }
local C_FILA  = { 0.00195313, 0.57421875, 0.65820313, 0.75000000 }
local C_HOVER = { 0.00195313, 0.57421875, 0.75390625, 0.84570313 }
local C_SEL   = { 0.00195313, 0.57421875, 0.84960938, 0.94140625 }
-- La barra de habilidad y el candado salen del atlas de hermandad, no del de entrenador.
local TEX_HERMANDAD = "Interface\\GuildFrame\\GuildFrame"
local C_BARRA_IZQ = { 0.60742188, 0.62500000, 0.78710938, 0.82226563 }
local C_BARRA_DER = { 0.60742188, 0.62500000, 0.82617188, 0.86132813 }
local C_BARRA_MED = { 0.60742188, 0.62500000, 0.74804688, 0.78320313 }
local C_CANDADO   = { 0.51660156, 0.53320313, 0.92578125, 0.96679688 }

-- Una ruta que el cliente no tenga se pinta en verde chillon sin avisar, asi que se comprueba.
local function Existe(ruta)
    if not GetFileIDFromPath then return true end
    return GetFileIDFromPath(ruta) and true or false
end

local function PonerTrozo(tex, ruta, coords)
    if not Existe(ruta) then return false end
    tex:SetTexture(ruta)
    tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    return true
end

------------------------------------------------------------
-- Fila: replica de UIServiceButtonTemplate
------------------------------------------------------------
local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(FILA_ANCHO_SIN, FILA_ALTO)
    -- Encadenadas sin hueco: el nativo las crea con HybridScrollFrame_CreateButtons a offset 0.
    if index == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    else
        row:SetPoint("TOPLEFT", parent.rows[index - 1], "BOTTOMLEFT", 0, 0)
    end

    local normal = row:CreateTexture(nil, "BACKGROUND")
    normal:SetAllPoints(row)
    if PonerTrozo(normal, TEX_ENTRENADOR, C_FILA) then
        row:SetNormalTexture(normal)
    else
        normal:SetColorTexture(0, 0, 0, 0.25)
    end
    row.artNormal = normal

    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(row)
    hover:SetBlendMode("ADD")
    if not PonerTrozo(hover, TEX_ENTRENADOR, C_HOVER) then
        hover:SetColorTexture(1, 1, 1, 0.10)
    end

    -- La seleccion es OVERLAY sublevel 1 en el nativo y va en ADD sobre la fila.
    row.sel = row:CreateTexture(nil, "OVERLAY", nil, 1)
    row.sel:SetAllPoints(row)
    row.sel:SetBlendMode("ADD")
    if not PonerTrozo(row.sel, TEX_ENTRENADOR, C_SEL) then
        row.sel:SetColorTexture(1, 0.82, 0, 0.20)
    end
    row.sel:Hide()

    -- Atenuar la fila cuando el servicio no esta disponible.
    --
    -- El nativo lo hace con una textura gris en `alphaMode="MOD"`, pero replicarla como una
    -- textura propia en capa BACKGROUND la dejaba POR DETRAS del arte de la fila: el multiplicado
    -- caia sobre el panel de atras en vez de sobre la fila, y como iba metida 2px por dentro
    -- dejaba un anillo sin atenuar que se veia como un borde rojo brillante alrededor de cada
    -- fila. El efecto buscado -multiplicar el arte por 0.55- se consigue directamente con el
    -- vertexColor de la propia textura de la fila, sin capas ni ambiguedad de orden.

    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(36, 36)
    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)

    row.candado = row:CreateTexture(nil, "OVERLAY", nil, 1)
    row.candado:SetSize(17, 21)
    row.candado:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 0, 0)
    PonerTrozo(row.candado, TEX_HERMANDAD, C_CANDADO)
    row.candado:Hide()

    -- El precio ocupa el sitio del SmallMoneyFrame nativo (TOPRIGHT +5,-7). Se pinta con
    -- GetCoinTextureString, que son los MISMOS iconos de moneda que usa ese frame.
    -- Precio: el MISMO widget del nativo (`UIServiceButtonTemplate` declara un
    -- SmallMoneyFrameTemplate en TOPRIGHT +5,-7 y lo pone en STATIC). Asi las monedas y los
    -- numeros salen con el espaciado del juego, y el rojo de "no te llega" lo pone
    -- SetMoneyFrameColor en vez de un |cff a mano.
    local okPrecio, precio = pcall(CreateFrame, "Frame", "HarfordTrainerRowMoney" .. index,
        row, "SmallMoneyFrameTemplate")
    if okPrecio and precio then
        precio:SetPoint("TOPRIGHT", row, "TOPRIGHT", 5, -7)
        if MoneyFrame_SetType then pcall(MoneyFrame_SetType, precio, "STATIC") end
        row.precioFrame = precio
    end
    row.precio = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.precio:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, -7)
    row.precio:SetJustifyH("RIGHT")

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetHeight(12)
    row.name:SetJustifyH("LEFT")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -1)
    row.name:SetPoint("RIGHT", row.precio, "LEFT", -2, 0)

    row.subText = row:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Small")
    row.subText:SetSize(240, 30)
    row.subText:SetJustifyH("LEFT")
    row.subText:SetJustifyV("MIDDLE")
    row.subText:SetPoint("LEFT", row.name, "LEFT", 0, -19)

    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(self)
        if not self.recipeId then return end
        state.selected = self.recipeId
        RefreshUI()
    end)
    return row
end

------------------------------------------------------------
-- Ventana
------------------------------------------------------------
local function CreateFrameIfNeeded()
    if frame then return frame end
    frame = CreateFrame("Frame", "HarfordProfessionTrainerFrame", UIParent, "ButtonFrameTemplate")
    -- 338 de ancho es lo que da ButtonFrameTemplate y con lo que cuadran los 302 del scroll.
    frame:SetSize(338, 424)
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "HarfordProfessionTrainerFrame") end

    -- El Inset del template es la caja donde vive la lista; el nativo cuelga de el.
    local inset = frame.Inset or _G["HarfordProfessionTrainerFrameInset"]

    local scroll = CreateFrame("Frame", nil, frame)
    scroll:SetSize(SCROLL_ANCHO, SCROLL_ALTO)
    -- Medido en el cliente: TOPLEFT del Inset +5,-5. El XML lo declara por TOPRIGHT, pero lo que
    -- vale es lo que resuelve esta build.
    if inset then
        scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 5, -5)
    else
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, -65)
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        state.offset = math.max(0, state.offset - delta)
        RefreshUI()
    end)
    scroll.rows = {}
    frame.scroll = scroll

    -- Fondo del entrenador: anclado al scroll con el desborde exacto del nativo (-3,+4 / +3,-4).
    local fondo = frame:CreateTexture(nil, "BACKGROUND")
    fondo:SetPoint("TOPLEFT", scroll, "TOPLEFT", -3, 4)
    fondo:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 3, -4)
    if not PonerTrozo(fondo, TEX_ENTRENADOR, C_FONDO) then fondo:Hide() end
    frame.fondo = fondo

    for i = 1, FILAS_VISIBLES do
        scroll.rows[i] = CreateRow(scroll, i)
    end
    state.rows = scroll.rows

    local slider = CreateFrame("Slider", nil, frame, "HybridScrollBarTemplate")
    if slider then
        slider:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 3, -12)
        slider:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 13)
        slider:SetMinMaxValues(0, 0)
        slider:SetValueStep(1)
        slider:SetScript("OnValueChanged", function(self, value)
            if self._updating then return end
            state.offset = math.floor(value + 0.5)
            RefreshUI()
        end)
        -- Las flechas de la plantilla llaman a HybridScrollFrame_OnMouseWheel sobre un frame que
        -- no es un HybridScrollFrame y revientan por `stepSize` nil. Se les pone manejador propio:
        -- solo mueven el valor, y el OnValueChanged de arriba hace el refresco.
        local arriba = slider.ScrollUpButton or slider.ScrollUp
        local abajo = slider.ScrollDownButton or slider.ScrollDown
        if arriba then
            arriba:SetScript("OnClick", function() slider:SetValue((slider:GetValue() or 0) - 1) end)
        end
        if abajo then
            abajo:SetScript("OnClick", function() slider:SetValue((slider:GetValue() or 0) + 1) end)
        end
        frame.slider = slider
    end

    -- Barra de habilidad: 136x18 en TOPLEFT +64,-36, con los tres trozos del atlas de hermandad.
    local barra = CreateFrame("StatusBar", nil, frame)
    barra:SetSize(136, 18)
    barra:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -36)
    barra:SetMinMaxValues(0, 1)
    barra:SetValue(0)
    local relleno = barra:CreateTexture(nil, "ARTWORK")
    if Existe("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar") then
        relleno:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
    else
        relleno:SetColorTexture(1, 1, 1)
    end
    barra:SetStatusBarTexture(relleno)
    relleno:SetDrawLayer("BACKGROUND")      -- en el nativo el relleno va en BACKGROUND
    barra:SetStatusBarColor(0, 0, 1, 0.5)   -- BarColor del XML
    -- Fondo translucido, igual que la barra de la ventana de recetas: el XML lo declara como una
    -- Texture sin anclajes ni tamano y el cliente la estira a la barra entera. Aqui se baja a
    -- alpha 0.1 en vez del 0.5 que declara este XML concreto: con 0.5 el fondo (0,0,0.75) queda
    -- casi igual que el relleno (0,0,1 a 0.5) y la barra parece llena aunque el valor sea 0. El
    -- 0.1 es el que usa el StatusBar equivalente del TradeSkillFrame, donde SI se distinguen.
    local barraBg = barra:CreateTexture(nil, "BACKGROUND")
    barraBg:SetAllPoints(barra)
    barraBg:SetColorTexture(0, 0, 0.75, 0.1)
    local capIzq = barra:CreateTexture(nil, "ARTWORK")
    capIzq:SetWidth(18)
    capIzq:SetPoint("TOPLEFT", barra, "TOPLEFT", -2, 0)
    capIzq:SetPoint("BOTTOMLEFT", barra, "BOTTOMLEFT", -2, 0)
    PonerTrozo(capIzq, TEX_HERMANDAD, C_BARRA_IZQ)
    local capDer = barra:CreateTexture(nil, "ARTWORK")
    capDer:SetWidth(18)
    capDer:SetPoint("TOPRIGHT", barra, "TOPRIGHT", 2, 0)
    capDer:SetPoint("BOTTOMRIGHT", barra, "BOTTOMRIGHT", 2, 0)
    PonerTrozo(capDer, TEX_HERMANDAD, C_BARRA_DER)
    local capMed = barra:CreateTexture(nil, "ARTWORK")
    capMed:SetPoint("TOPLEFT", capIzq, "TOPRIGHT", 0, 0)
    capMed:SetPoint("BOTTOMRIGHT", capDer, "BOTTOMLEFT", 0, 0)
    PonerTrozo(capMed, TEX_HERMANDAD, C_BARRA_MED)
    barra.texto = barra:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    barra.texto:SetPoint("CENTER", barra, "CENTER", 0, 0)
    frame.barra = barra

    -- Dinero del jugador abajo a la izquierda, sobre el borde de moneda nativo.
    local monedero = frame:CreateTexture(nil, "ARTWORK")
    monedero:SetSize(148, 34)
    monedero:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, -9)
    if Existe("Interface\\MoneyFrame\\UI-MoneyFrame-Border") then
        monedero:SetTexture("Interface\\MoneyFrame\\UI-MoneyFrame-Border")
    else
        monedero:Hide()
    end
    -- El dinero se pinta con el MISMO widget que el nativo, no con una cadena de texto.
    -- `SmallMoneyFrameTemplate` trae sus botones de oro/plata/cobre con el icono, la fuente y el
    -- espaciado ya resueltos; montarlo con GetCoinTextureString en una FontString dejaba los
    -- numeros y las monedas descuadrados dentro de la placa. El anclaje es el del XML nativo:
    -- RIGHT del borde de moneda, +8,+6. Necesita nombre porque MoneyFrame_Update lo busca por el.
    local okDinero, dinero = pcall(CreateFrame, "Frame", "HarfordProfessionTrainerMoney",
        frame, "SmallMoneyFrameTemplate")
    if okDinero and dinero then
        dinero:SetPoint("RIGHT", monedero, "RIGHT", 8, 6)
        -- STATIC a proposito: por defecto un SmallMoneyFrame es de tipo PLAYER y se refrescaria
        -- solo con el oro REAL del personaje, pisando nuestro saldo de economia D&D.
        if MoneyFrame_SetType then pcall(MoneyFrame_SetType, dinero, "STATIC") end
        -- Lo mismo que hace ClassTrainerFrame_OnLoad con el suyo.
        if MoneyFrame_SetMaxDisplayWidth then
            pcall(MoneyFrame_SetMaxDisplayWidth, dinero, 152)
        end
        frame.dinero = dinero
    else
        -- Sin la plantilla, texto plano: mejor eso que dejar el saldo en blanco.
        frame.saldo = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.saldo:SetPoint("RIGHT", monedero, "RIGHT", 8, 6)
        frame.saldo:SetJustifyH("RIGHT")
    end

    -- Desplegable de filtro: 150x32 en TOPRIGHT +6,-30 segun la sonda, con los tres mismos
    -- conmutadores que el nativo (disponible / no disponible / ya conocida).
    local filtro = CreateFrame("Frame", "HarfordProfessionTrainerFilter", frame, "UIDropDownMenuTemplate")
    if filtro then
        filtro:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 6, -30)
        frame.filtro = filtro
        if UIDropDownMenu_Initialize and UIDropDownMenu_SetWidth then
            UIDropDownMenu_SetWidth(filtro, 100)
            UIDropDownMenu_SetText(filtro, "Filtro")
            UIDropDownMenu_Initialize(filtro, function()
                local opciones = {
                    -- Textos propios: el cliente es enUS y sus globales (_G.AVAILABLE, _G.USED,
                    -- _G.REQUIRES_LABEL...) saldrian en ingles dentro de un addon en castellano.
                    { clave = "puede",   texto = "|cff20ff20Disponible|r" },
                    { clave = "nopuede", texto = "|cffff2020No disponible|r" },
                    { clave = "sabida",  texto = "|cff808080Ya conocida|r" },
                }
                for _, o in ipairs(opciones) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = o.texto
                    info.isNotRadio = true
                    info.keepShownOnClick = true
                    info.checked = state.filtro[o.clave]
                    info.func = function(_, _, _, marcado)
                        state.filtro[o.clave] = marcado and true or false
                        state.offset = 0
                        RefreshUI()
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end)
        end
    end

    -- El nativo solo tiene el boton de entrenar: para cerrar esta la X del template.
    frame.learnBtn = CreateFrame("Button", nil, frame, "MagicButtonTemplate")
    frame.learnBtn:SetSize(80, 22)
    frame.learnBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 4)
    frame.learnBtn:SetText("Aprender")
    frame.learnBtn:SetScript("OnClick", function()
        local T = Trainers()
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
    if not (frame and frame:IsShown()) then return end
    local def, P = Def(), Profs()
    if not (def and P) then return end

    -- Titulo: PROFESION - RANGO ("Alquimia - Aprendiz"), no el nombre del entrenador. Es lo que
    -- identifica que ensena esta ventana; quien la imparte ya lo dice el NPC con el que hablas.
    local profDef = P.GetDefinition and P.GetDefinition(def.profession)
    if frame.TitleText then
        frame.TitleText:SetWidth(0)
        local titulo = (profDef and profDef.name) or def.profession or "Entrenador"
        if def.tier and def.tier ~= "" then titulo = titulo .. " - " .. def.tier end
        frame.TitleText:SetText(titulo)
    end
    if frame.portrait and SetPortraitToTexture then
        SetPortraitToTexture(frame.portrait,
            "Interface\\Icons\\" .. ((profDef and profDef.icon) or "INV_Misc_QuestionMark"))
    end

    local skill = (P.EffectiveSkill and P.EffectiveSkill(def.profession)) or 0
    local maximo = P.MAX_SKILL or 300
    frame.barra:SetMinMaxValues(0, maximo)
    frame.barra:SetValue(skill)
    frame.barra.texto:SetText(skill .. "/" .. maximo)

    local saldo = (HarfordDnDEconomy and HarfordDnDEconomy.GetBalance
        and HarfordDnDEconomy.GetBalance()) or 0
    if frame.dinero and MoneyFrame_Update then
        MoneyFrame_Update(frame.dinero:GetName(), saldo)
    elseif frame.saldo then
        frame.saldo:SetText(GetCoinTextureString and GetCoinTextureString(saldo) or tostring(saldo))
    end

    -- El filtro se aplica AQUI y no en Lista(): Lista() es "que ensena este entrenador", que no
    -- depende de lo que el jugador quiera ver.
    local todas, lista = Lista(), {}
    for _, r in ipairs(todas) do
        local clave = API.GetRecipeState(r)
        local grupo = (clave == "sabida" and "sabida") or (clave == "puede" and "puede") or "nopuede"
        if state.filtro[grupo] then lista[#lista + 1] = r end
    end
    local maxOffset = math.max(0, #lista - FILAS_VISIBLES)
    state.offset = math.max(0, math.min(state.offset, maxOffset))
    if frame.slider then
        frame.slider._updating = true
        frame.slider:SetMinMaxValues(0, maxOffset)
        frame.slider:SetValue(state.offset)
        frame.slider._updating = false
        frame.slider:SetShown(maxOffset > 0)
    end
    -- Igual que el nativo: al aparecer la barra de scroll se estrechan las filas Y EL PROPIO
    -- SCROLL. Solo estrechar las filas dejaba la barra colgando 14px fuera del borde derecho de
    -- la ventana, que es como se veia. El nativo hace las dos cosas a la vez en
    -- ClassTrainerScrollFrameScrollBar.Show/Hide: SetWidth(ANCHO_FILA + 2).
    local conBarra = (maxOffset > 0)
    local anchoFila = conBarra and FILA_ANCHO_CON or FILA_ANCHO_SIN
    frame.scroll:SetWidth(anchoFila + 2)
    for _, row in ipairs(state.rows) do row:SetWidth(anchoFila) end

    -- Una receta que el filtro acaba de ocultar no puede seguir seleccionada: el boton
    -- "Aprender" quedaria activo sobre algo que no se ve.
    if state.selected then
        local sigue = false
        for _, r in ipairs(lista) do if r.id == state.selected then sigue = true break end end
        if not sigue then state.selected = nil end
    end

    -- Sin seleccion, la primera que se pueda aprender.
    if not state.selected then
        for _, r in ipairs(lista) do
            if API.GetRecipeState(r) == "puede" then state.selected = r.id break end
        end
    end

    local puedeAprender = false
    for i = 1, FILAS_VISIBLES do
        local row = state.rows[i]
        local rec = lista[state.offset + i]
        if not rec then
            row.recipeId = nil
            row:Hide()
        else
            row.recipeId = rec.id
            row.icon:SetTexture(RecipeIcon(rec))
            row.name:SetText(rec.name or rec.id)

            local clave, etiqueta = API.GetRecipeState(rec)
            local T = Trainers()
            local coste = (T and T.GetRecipeCost and T.GetRecipeCost(rec.id)) or 0

            -- Como pinta el nativo cada caso (ClassTrainerFrame_SetServiceButton):
            --   no disponible -> icono desaturado, nombre en gris y velo gris encima
            --   ya conocida   -> subtexto "Ya la conoces" y SIN precio
            --   disponible    -> nombre normal y precio; en rojo si no te llega
            local noDisponible = (clave == "skill" or clave == "sinprof" or clave == "dinero")
            row.icon:SetDesaturated(noDisponible)
            -- 0.55 es el mismo factor que declara el `disabledBG` del nativo.
            if row.artNormal then
                local g = noDisponible and 0.55 or 1
                row.artNormal:SetVertexColor(g, g, g)
            end
            row.candado:SetShown(clave == "skill" or clave == "sinprof")
            -- El precio lo pinta el widget nativo si existe; la FontString queda de reserva.
            -- Como el nativo: si ya la conoces NO se muestra precio.
            local function PintarPrecio(cantidad, sinDinero)
                if row.precioFrame and MoneyFrame_Update then
                    row.precio:SetText("")
                    if not cantidad or cantidad <= 0 then
                        row.precioFrame:Hide()
                        if cantidad == 0 then row.precio:SetText("Gratis") end
                        return
                    end
                    MoneyFrame_Update(row.precioFrame:GetName(), cantidad)
                    if SetMoneyFrameColor then
                        SetMoneyFrameColor(row.precioFrame:GetName(),
                            sinDinero and "red" or "white")
                    end
                    row.precioFrame:Show()
                    return
                end
                if row.precioFrame then row.precioFrame:Hide() end
                if not cantidad or cantidad <= 0 then
                    row.precio:SetText(cantidad == 0 and "Gratis" or "")
                    return
                end
                row.precio:SetText((sinDinero and "|cffff2020" or "")
                    .. FormatMoney(cantidad) .. (sinDinero and "|r" or ""))
            end

            if clave == "sabida" then
                row.name:SetTextColor(0.5, 0.5, 0.5)
                row.subText:SetText("Ya la conoces")
                PintarPrecio(nil)
            else
                if noDisponible then
                    row.name:SetTextColor(0.5, 0.5, 0.5)
                else
                    row.name:SetTextColor(1, 0.82, 0)   -- el color propio de GameFontNormal
                end
                row.subText:SetText(clave == "puede" and ""
                    or ("Requiere: " .. tostring(etiqueta)))
                PintarPrecio(coste, clave == "dinero")
            end

            row.sel:SetShown(rec.id == state.selected)
            if rec.id == state.selected and clave == "puede" then puedeAprender = true end
            row:Show()
        end
    end

    frame.learnBtn:SetEnabled(puedeAprender and not frame._buying)
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
