-- HarfordActionBars: barra de accion de madera para colocar habilidades del Libro.
--
-- FASE 1 (este archivo): la barra VISUAL (tapas + tablon central + N slots). Las piezas son
-- texturas sueltas; las rutas de madera de retail (Interface\PlayerActionBarAlt\spellbar-wood*)
-- NO estan en el cliente Epsilon, asi que de momento usa pergamino/quickslot (que SI cargan).
-- Gate por HarfordConfig ("actionbar" = on/off).
--
-- Los comandos de diagnostico viven en HarfordDebug.lua (convencion del proyecto); este modulo
-- solo expone API publica (Toggle / SetTestTexture / SetGeometry / Layout).
--
-- La colocacion de habilidades NO usa esta barra visual, sino los ActionButton NATIVOS de
-- Blizzard (bloque del final del fichero): es donde el jugador ya tiene sus teclas y sus addons
-- de barras. Arrastrar desde el Libro, click para ejecutar, y persistencia por personaje en
-- `HarfordActionBarStore`. La ejecucion la resuelve `HarfordCharacterPanel.ActivarHabilidadPorId`,
-- que reutiliza el manejador del Libro en vez de repetir sus reglas.

HarfordActionBars = HarfordActionBars or {}
local API = HarfordActionBars

-- Texturas que SI existen en el cliente. Cambiar aqui cuando se encuentren las de madera reales.
local TEX_CENTER = "Interface\\Spellbook\\Spellbook-Page-1"   -- fondo (placeholder)
local TEX_LEFT   = nil                                        -- sin tapa por ahora
local TEX_RIGHT  = nil
local TEX_BTN    = "Interface\\Buttons\\UI-Quickslot2"        -- marco del slot

-- Geometria ajustable.
HarfordActionBars._cfg = HarfordActionBars._cfg or {
    h     = 72,   -- altura de la barra
    capW  = 70,   -- ancho de cada tapa
    slot  = 40,   -- tamaño de cada slot
    gap   = 10,   -- separacion entre slots
    count = 6,    -- numero de slots
}

local bar  -- frame unico

-- ─── Construccion / relayout ─────────────────────────────────────────────────
local function Build()
    if bar then return bar end
    bar = CreateFrame("Frame", "HarfordActionBarFrame", UIParent)
    bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", bar.StopMovingOrSizing)
    bar:Hide()

    bar.center = bar:CreateTexture(nil, "BACKGROUND")
    bar.center:SetTexture(TEX_CENTER)
    bar.leftCap = bar:CreateTexture(nil, "ARTWORK")
    if TEX_LEFT then bar.leftCap:SetTexture(TEX_LEFT) end
    bar.rightCap = bar:CreateTexture(nil, "ARTWORK")
    if TEX_RIGHT then bar.rightCap:SetTexture(TEX_RIGHT) end

    bar.slots = {}
    return bar
end

function API.Layout()
    if not bar then return end
    local c = HarfordActionBars._cfg
    local innerW = c.count * c.slot + (c.count - 1) * c.gap
    local totalW = innerW + 2 * c.capW + 40

    bar:SetSize(totalW, c.h)

    bar.leftCap:ClearAllPoints()
    bar.leftCap:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.leftCap:SetSize(c.capW, c.h)

    bar.rightCap:ClearAllPoints()
    bar.rightCap:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    bar.rightCap:SetSize(c.capW, c.h)

    bar.center:ClearAllPoints()
    bar.center:SetPoint("TOPLEFT", bar.leftCap, "TOPRIGHT", -2, 0)
    bar.center:SetPoint("BOTTOMRIGHT", bar.rightCap, "BOTTOMLEFT", 2, 0)

    for i = 1, c.count do
        local s = bar.slots[i]
        if not s then
            s = CreateFrame("CheckButton", "HarfordActionSlot" .. i, bar)
            s.bg = s:CreateTexture(nil, "BORDER")
            s.bg:SetTexture(TEX_BTN)
            s.bg:SetAllPoints()
            s.icon = s:CreateTexture(nil, "ARTWORK")
            s.icon:SetPoint("TOPLEFT", 3, -3); s.icon:SetPoint("BOTTOMRIGHT", -3, 3)
            s.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); s.icon:Hide()
            s:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            bar.slots[i] = s
        end
        s:SetSize(c.slot, c.slot)
        s:ClearAllPoints()
        if i == 1 then
            s:SetPoint("LEFT", bar, "LEFT", c.capW + 10, 0)
        else
            s:SetPoint("LEFT", bar.slots[i - 1], "RIGHT", c.gap, 0)
        end
        s:Show()
    end
    for i = c.count + 1, #bar.slots do bar.slots[i]:Hide() end
end

-- ─── ANCLAJE A LA BARRA NATIVA ───────────────────────────────────────────────
-- Las fichas van ENCIMA de la barra de accion de Blizzard, como en BG3, no sobre la barra propia
-- de Harford: esa esta apagada por defecto y puede no usarse nunca.
--
-- El frame se busca en varios sitios porque los addons de barras (Dominos, Bartender) reparentan
-- los botones, y el propio cliente ha movido estos frames entre versiones. Si no hay ninguno, las
-- fichas no se pintan: es preferible a colocarlas en una esquina al azar.
local function AnclaBarraNativa()
    -- En ORDEN DE ALTURA, de la barra mas alta de la pila a la mas baja. Las barras extra se
    -- apilan encima de la principal, asi que colgarse de la principal cuando hay una extra puesta
    -- deja las fichas DEBAJO de ella. Se coge la mas alta que este visible.
    -- Lista de NOMBRES, no de frames. Una tabla `{ _G["A"], _G["B"] }` donde el primero no existe
    -- se construye con un hueco en el indice 1, y `ipairs` para en el primer nil: con este orden,
    -- un cliente sin `StanceBarFrame` no encontraba NINGUNA barra. Antes funcionaba de milagro,
    -- porque el unico que solia existir estaba el primero.
    local pila = {
        "StanceBarFrame",            -- Sigilo / formas: ya vive donde queremos estar
        "MultiBarBottomRight",
        "MultiBarBottomLeft",
        "MainMenuBarArtFrame",
        "MainMenuBar",
        "ActionButton1",
    }
    for _, nombre in ipairs(pila) do
        local f = _G[nombre]
        if f and f.GetObjectType and f:IsShown() then return f end
    end
    -- Nada visible: vale cualquiera para tener de donde colgar, aunque no se vea.
    for _, nombre in ipairs(pila) do
        local f = _G[nombre]
        if f and f.GetObjectType then return f end
    end
    return nil
end

-- Cuanto sobresale por encima de la barra principal lo que haya apilado. Se mide en pixeles de
-- pantalla en vez de contar barras: da igual como las haya colocado el addon de turno.
local function AlturaApilada(base)
    if not (base and base.GetTop) then return 0 end
    local suelo = base:GetTop()
    if not suelo then return 0 end
    local extra = 0
    for _, nombre in ipairs({ "MultiBarBottomLeft", "MultiBarBottomRight", "StanceBarFrame",
                             "PetActionBarFrame", "MultiCastActionBarFrame" }) do
        local f = _G[nombre]
        if f and f.IsShown and f:IsShown() and f.GetTop then
            local arriba = f:GetTop()
            if arriba and arriba - suelo > extra then extra = arriba - suelo end
        end
    end
    return extra
end

-- La barra PRINCIPAL, que es la que manda el centro. Las extras se apilan encima pero no siempre
-- ocupan el mismo ancho ni empiezan donde ella, asi que centrarse en una de ellas deja los iconos
-- descolocados a un lado -- que es justo lo que pasaba con la de la derecha.
local function BarraPrincipal()
    for _, nombre in ipairs({ "MainMenuBarArtFrame", "MainMenuBar", "ActionButton1" }) do
        local f = _G[nombre]
        if f and f.GetObjectType and f:IsShown() then return f end
    end
    for _, nombre in ipairs({ "MainMenuBarArtFrame", "MainMenuBar", "ActionButton1" }) do
        local f = _G[nombre]
        if f and f.GetObjectType then return f end
    end
    return nil
end


-- ─── INDICADORES DE ECONOMIA DE TURNO ────────────────────────────────────────
-- Fichas de Accion / Adicional / Reaccion sobre la barra, al estilo BG3: una ficha por punto
-- disponible, encendida si te queda y apagada si la gastaste.
--
-- El presupuesto NO siempre es 1: Impetu de Accion da una accion extra, asi que se pinta una ficha
-- por punto y no una por tipo. Eso es lo que hace que se lea de un vistazo cuantas te quedan.
--
-- Se alimentan de `HarfordDnDConditions.Turn`, que es la fuente unica de la economia (la misma que
-- muestra el texto de la seccion Ataque). Solo se ven con orden de turnos activo: fuera de combate
-- no se lleva la cuenta y unas fichas llenas serian informacion falsa.
--
-- Sin ticker: el motor de condiciones avisa a sus listeners al gastar y al reiniciar el turno.
local FICHA_TAM, FICHA_HUECO = 15, 4
-- Los orbes de conjuro son mas pequenos que las fichas de accion a proposito: son otro tipo de
-- recurso (no se renuevan por turno) y conviene que no se confundan de un vistazo.
local ORBE_TAM, ORBE_HUECO, GRUPO_HUECO = 10, 3, 12
local COLOR_ORBE = { 0.44, 0.63, 0.90 }
-- Los colores de BG3, que es de donde viene el gesto: quien ha jugado a eso ya sabe cual es cual
-- sin leer nada, y cambiarlos por otros le obliga a reaprenderlo.
local COLOR_FICHA = {
    action   = { 0.36, 0.74, 0.36 },   -- verde
    bonus    = { 0.62, 0.42, 0.24 },   -- marron
    reaction = { 0.62, 0.36, 0.80 },   -- morado
}
local TEX_MARCO = "Interface\\Common\\WhiteIconFrame"

local function Economia()
    return HarfordDnDConditions and HarfordDnDConditions.Turn
end

-- Contenedor propio: las fichas no dependen de que la barra de Harford exista ni este visible.
local fichasFrame

local function EnsureFichasFrame()
    if fichasFrame then return fichasFrame end
    fichasFrame = CreateFrame("Frame", "HarfordTurnEconomyFrame", UIParent)
    fichasFrame:SetSize(1, FICHA_TAM)
    fichasFrame:SetFrameStrata("MEDIUM")
    -- Nivel alto DENTRO de MEDIUM: nacia en el 1 y la barra de accion nativa, que comparte capa,
    -- se pintaba encima. Es la misma leccion que la tira de estados: medir "esta en pantalla" no
    -- basta, hay que mirar tambien QUE hay delante.
    fichasFrame:SetFrameLevel(90)
    fichasFrame.fichas = {}
    fichasFrame.orbes = {}
    fichasFrame.niveles = {}
    return fichasFrame
end

-- Un orbe de espacio de conjuro. Pool propio: no comparten geometria con las fichas de accion.
local function EnsureOrbe(i)
    local cont = EnsureFichasFrame()
    cont.orbes = cont.orbes or {}
    local o = cont.orbes[i]
    if o then return o end
    o = CreateFrame("Frame", nil, cont)
    o:SetSize(ORBE_TAM, ORBE_TAM)
    o.fondo = o:CreateTexture(nil, "ARTWORK")
    o.fondo:SetPoint("TOPLEFT", 1, -1)
    o.fondo:SetPoint("BOTTOMRIGHT", -1, 1)
    o.marco = o:CreateTexture(nil, "OVERLAY")
    o.marco:SetTexture(TEX_MARCO)
    o.marco:SetAllPoints()
    o:EnableMouse(true)
    o:SetScript("OnEnter", function(self)
        if not (GameTooltip and self.nivel) then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Espacio de conjuro de nivel " .. tostring(self.nivel), 1, 1, 1)
        GameTooltip:AddLine(self.quedan .. " de " .. self.total .. " disponibles", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    cont.orbes[i] = o
    return o
end

-- Etiqueta con el numero de nivel delante de cada grupo de orbes.
local function EnsureNivelTexto(i)
    local cont = EnsureFichasFrame()
    cont.niveles = cont.niveles or {}
    local t = cont.niveles[i]
    if t then return t end
    t = cont:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cont.niveles[i] = t
    return t
end

local function EnsureFicha(i)
    local cont = EnsureFichasFrame()
    local f = cont.fichas[i]
    if f then return f end
    f = CreateFrame("Frame", nil, cont)
    f:SetSize(FICHA_TAM, FICHA_TAM)
    f.fondo = f:CreateTexture(nil, "ARTWORK")
    f.fondo:SetPoint("TOPLEFT", 2, -2)
    f.fondo:SetPoint("BOTTOMRIGHT", -2, 2)
    f.marco = f:CreateTexture(nil, "OVERLAY")
    f.marco:SetTexture(TEX_MARCO)
    f.marco:SetAllPoints()
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        if not (GameTooltip and self.etiqueta) then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(self.etiqueta, 1, 1, 1)
        GameTooltip:AddLine(self.gastada and "Gastada este turno" or "Disponible",
            self.gastada and 0.7 or 0.3, self.gastada and 0.3 or 0.9, 0.3)
        if self.kind == "reaction" then
            -- La regla que mas se confunde: la reaccion NO vuelve al acabar el asalto.
            GameTooltip:AddLine("Vuelve al empezar tu turno", 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    cont.fichas[i] = f
    return f
end

-- Las fichas de accion y la barra de movimiento VIVEN AHORA EN EL MARCADOR DE TURNO, con el turno
-- y el asalto. Tenerlas ademas aqui encima de la barra de accion era la misma informacion en dos
-- sitios: dos cosas que mantener y dos sitios donde mirar. Esta funcion se queda para los ORBES de
-- espacios de conjuro, que no son del turno --no se renuevan con el-- y siguen teniendo sentido
-- pegados a la barra.
--
-- Redibuja la fila entera. Devuelve cuantas fichas quedaron visibles.
-- Dibuja los recursos sobre la barra nativa: fichas de accion (solo con combate activo, porque
-- fuera de combate no se lleva la cuenta) y orbes de espacios de conjuro (SIEMPRE, porque no se
-- renuevan por turno y saber cuantos quedas es util fuera de combate).
--
-- Devuelve `fichas, orbes` para que se pueda comprobar.
function API.RefreshTurnEconomy()
    local cont = EnsureFichasFrame()
    cont.orbes = cont.orbes or {}
    cont.niveles = cont.niveles or {}
    local ancla = AnclaBarraNativa()
    if not ancla then
        cont:Hide()
        return 0, 0
    end

    -- ── Fichas de accion ────────────────────────────────────────────────────
    local T = Economia()
    -- Las fichas de accion y la barra de movimiento VIVEN EN EL MARCADOR DE TURNO, con el turno y
    -- el asalto. Tenerlas ademas aqui era la misma informacion en dos sitios: dos cosas que
    -- mantener y dos sitios donde mirar.
    local n = 0
    for i = n + 1, #cont.fichas do cont.fichas[i]:Hide() end
    local ancho = n * FICHA_TAM + math.max(0, n - 1) * FICHA_HUECO
    local ultimo = n > 0 and cont.fichas[n] or nil

    -- ── Orbes de espacios de conjuro ────────────────────────────────────────
    -- Solo en modo "slots": en modo mana no hay piramide que pintar. `IsEnabled` devuelve true
    -- cuando el MANA esta activo, asi que la piramide es justo el caso contrario.
    local M = HarfordDnDMana
    local orbes, grupos = 0, 0
    if M and M.IsEnabled and not M.IsEnabled() and M.GetMaxSpellLevel and M.GetSpellSlotCurrent then
        for nivel = 1, (M.GetMaxSpellLevel() or 0) do
            local quedan, total = M.GetSpellSlotCurrent(nivel)
            if (total or 0) > 0 then
                grupos = grupos + 1
                local etiqueta = EnsureNivelTexto(grupos)
                etiqueta:SetText(tostring(nivel))
                etiqueta:ClearAllPoints()
                if ultimo then
                    etiqueta:SetPoint("LEFT", ultimo, "RIGHT", GRUPO_HUECO, 0)
                else
                    etiqueta:SetPoint("BOTTOMLEFT", cont, "BOTTOMLEFT", 0, 1)
                end
                etiqueta:Show()
                ancho = ancho + GRUPO_HUECO + 10
                local anterior
                for punto = 1, total do
                    orbes = orbes + 1
                    local o = EnsureOrbe(orbes)
                    o.nivel, o.quedan, o.total = nivel, quedan, total
                    local gastado = punto > quedan
                    local c = COLOR_ORBE
                    if gastado then
                        o.fondo:SetColorTexture(c[1] * 0.20, c[2] * 0.20, c[3] * 0.20, 0.9)
                        o.marco:SetVertexColor(0.32, 0.32, 0.32)
                    else
                        o.fondo:SetColorTexture(c[1], c[2], c[3], 1)
                        o.marco:SetVertexColor(c[1] * 1.1, c[2] * 1.1, c[3] * 1.1)
                    end
                    o:ClearAllPoints()
                    o:SetPoint("LEFT", anterior or etiqueta, "RIGHT", anterior and ORBE_HUECO or 3, 0)
                    o:Show()
                    anterior = o
                    ancho = ancho + ORBE_TAM + ORBE_HUECO
                end
                ultimo = anterior or ultimo
            end
        end
    end
    for i = orbes + 1, #cont.orbes do cont.orbes[i]:Hide() end
    for i = grupos + 1, #cont.niveles do cont.niveles[i]:Hide() end

    if n == 0 and orbes == 0 then
        cont:Hide()
        return 0, 0
    end
    cont:ClearAllPoints()
    -- Por encima del ancla REAL: con Dominos, Bartender o similares la barra puede estar en un
    -- nivel mas alto que el fijo de arriba.
    if ancla.GetFrameLevel then
        cont:SetFrameLevel(math.max(90, (ancla:GetFrameLevel() or 0) + 5))
    end
    -- El CENTRO sale de la barra principal y la ALTURA de lo mas alto que haya apilado: son dos
    -- cosas distintas y mezclarlas dejaba los iconos centrados sobre la barra de la DERECHA, que
    -- ni empieza donde la principal ni mide lo mismo.
    local base = BarraPrincipal() or ancla
    cont:SetPoint("BOTTOM", base, "TOP", 0, 8 + AlturaApilada(base))
    cont:SetWidth(math.max(1, ancho))
    -- La fila de fichas se centra dentro del contenedor moviendo solo la primera: las demas van
    -- encadenadas a ella.
    if n > 0 then
        local fila = n * FICHA_TAM + math.max(0, n - 1) * FICHA_HUECO
        cont.fichas[1]:ClearAllPoints()
        cont.fichas[1]:SetPoint("BOTTOMLEFT", cont, "BOTTOM", -fila / 2, 0)
    end
    cont:Show()
    return n, orbes
end

-- ─── API publica ─────────────────────────────────────────────────────────────
function API.SetShown(show)
    if show then
        Build()
        API.Layout()
        bar:Show()
    elseif bar then
        bar:Hide()
    end
end

function API.IsShown()
    return bar ~= nil and bar:IsShown()
end

function API.Toggle()
    API.SetShown(not API.IsShown())
    return API.IsShown()
end

-- Pone una textura de prueba en fondo+tapas (para verificar en vivo si una ruta carga).
function API.SetTestTexture(path)
    if not path or path == "" then return end
    API.SetShown(true)
    bar.center:SetTexture(path)
    bar.leftCap:SetTexture(path)
    bar.rightCap:SetTexture(path)
end

-- Ajusta la geometria y relayouta. Devuelve la tabla _cfg.
function API.SetGeometry(h, capW, slot, gap, count)
    local c = HarfordActionBars._cfg
    if h then
        c.h, c.capW, c.slot, c.gap, c.count = h, capW, slot, gap, count
    end
    if not bar then API.SetShown(true) end
    API.Layout()
    return c
end

function API.IsEnabled()
    return HarfordConfig and HarfordConfig.Get and HarfordConfig.Get("actionbar") == "on"
end

function API.Refresh()
    API.SetShown(API.IsEnabled())
end

-- ─── Eventos ─────────────────────────────────────────────────────────────────
if HarfordConfig and HarfordConfig.RegisterChangeListener then
    HarfordConfig.RegisterChangeListener(function(key)
        if key == nil or key == "actionbar" then API.Refresh() end
    end)
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function()
        API.Refresh()
        f:UnregisterAllEvents()
    end)
end

-- El motor de condiciones avisa al gastar una accion y al reiniciar el turno. Un solo listener,
-- sin ticker: es la regla del proyecto y aqui basta de sobra.
if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
    HarfordDnDConditions.RegisterListener(function()
        API.RefreshTurnEconomy()
    end)
end

-- El movimiento no pasa por el motor de condiciones: lo lleva el seguimiento de la ficha, que ya
-- corre mientras andas. Que avise el, y solo cuando cambia -- preguntarselo en un ticker seria
-- justo lo que este addon no hace.
if HarfordDnDAttackUI and HarfordDnDAttackUI.RegisterMovementListener then
    HarfordDnDAttackUI.RegisterMovementListener(function()
        API.RefreshTurnEconomy()
    end)
end

-- Un refresco al entrar: el motor de condiciones solo avisa cuando algo cambia, y al arrancar no ha
-- cambiado nada todavia. Sin ticker.
do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:SetScript("OnEvent", function()
        if API.RefreshTurnEconomy then API.RefreshTurnEconomy() end
    end)
end

-- Gastar o crear un espacio de conjuro no pasa por el motor de condiciones y no tiene evento de
-- WoW propio. En vez de tocarle el control de flujo a HarfordDnDMana, se envuelven sus mutaciones
-- desde aqui, que es el modulo al que le interesa el refresco.
--
-- `{ original(...) }` + `unpack` conserva TODOS los valores de retorno: varias de estas devuelven
-- tres, y recortarlos romperia a sus llamadores.
do
    local desempaquetar = unpack or table.unpack
    local MUTACIONES = { "SpendSpellSlot", "CreateSlotFromPoints", "ConvertSlotToPoints" }
    local function Envolver()
        if not HarfordDnDMana then return end
        for _, nombre in ipairs(MUTACIONES) do
            local original = HarfordDnDMana[nombre]
            if type(original) == "function" and not HarfordDnDMana["_harfordEnvuelto_" .. nombre] then
                HarfordDnDMana["_harfordEnvuelto_" .. nombre] = true
                HarfordDnDMana[nombre] = function(...)
                    local r = { original(...) }
                    if API.RefreshTurnEconomy then API.RefreshTurnEconomy() end
                    return desempaquetar(r)
                end
            end
        end
    end
    local ev2 = CreateFrame("Frame")
    ev2:RegisterEvent("PLAYER_LOGIN")
    ev2:SetScript("OnEvent", Envolver)
    Envolver()
end

-- ─── HABILIDADES EN LA BARRA NATIVA ──────────────────────────────────────────
-- Se colocan sobre los ActionButton de Blizzard, no en una barra propia: es donde el jugador ya
-- tiene sus teclas y sus addons de barras. El patron es el de SpellCreator/Arcanum, que lleva anos
-- funcionando en Epsilon: un SecureActionButton acepta un `type` PERSONALIZADO y ejecuta el
-- manejador declarado en `_<type>`.
--
-- Convivencia con Arcanum: cada addon toca SOLO los botones cuyo `type` es el suyo. Mientras los
-- dos respeten eso, se reparten la barra sin pisarse.
--
-- NADA de esto funciona en combate: cambiar atributos seguros esta bloqueado por el cliente. Todas
-- las rutas abortan con aviso, igual que hace Arcanum.
do
    local TIPO = "harford"
    local TEX_LLENO = "Interface\\Buttons\\UI-Quickslot2"

    local function Aviso(texto)
        if HarfordChat and HarfordChat.Print then HarfordChat.Print(texto) end
    end

    local function EnCombate()
        if InCombatLockdown and InCombatLockdown() then
            Aviso("No se pueden mover habilidades de la barra en combate.")
            return true
        end
        return false
    end

    -- Clave de registro. La barra principal cambia de accion segun la PAGINA, asi que la pagina
    -- forma parte de la identidad de la ranura; las barras secundarias no cambian.
    local function Ranura(button)
        if not (button and button.GetName and button:GetName()) then return nil end
        local nombre = button:GetName()
        local padre = button.GetParent and button:GetParent()
        local nombrePadre = padre and padre.GetName and padre:GetName() or ""
        if nombrePadre == "MainMenuBarArtFrame" or nombrePadre:find("Dominos", 1, true)
            or nombre:find("^ActionButton%d") then
            return nombre .. ":" .. tostring(GetActionBarPage and GetActionBarPage() or 1)
        end
        return nombre
    end

    local function Store()
        HarfordActionBarStore = HarfordActionBarStore or {}
        HarfordActionBarStore.botones = HarfordActionBarStore.botones or {}
        return HarfordActionBarStore
    end

    local function Pintar(button)
        local icono = button.icon or (button.GetName and _G[button:GetName() .. "Icon"])
        if not (icono and button.harfordIcon) then return end
        icono:SetTexture(button.harfordIcon)
        icono:SetVertexColor(1, 1, 1, 1)
        icono:SetAlpha(1)
        icono:Show()
        if button.SetNormalTexture then
            button:SetNormalTexture(TEX_LLENO)
            if button.NormalTexture then button.NormalTexture:SetVertexColor(0.45, 0.75, 1, 1) end
        end
        -- Nombre sobre el boton, en el FontString del nombre de macro (es el hueco nativo para
        -- "esto no es un hechizo de verdad"), y recortado como hace Blizzard.
        local nombre = button.Name or (button.GetName and _G[button:GetName() .. "Name"])
        if nombre and button.harfordName then nombre:SetText(button.harfordName) end
    end

    -- Estamos llevando OTRA barra (posesion de NPC / vehiculo): Blizzard superpone acciones
    -- reales sobre los mismos botones y las retira al soltar. En ese estado, apartarse es
    -- temporal y el registro NO debe tocarse.
    local function EnPosesion()
        if HasOverrideActionBar and HasOverrideActionBar() then return true end
        if HasVehicleActionBar and HasVehicleActionBar() then return true end
        if UnitHasVehicleUI and UnitHasVehicleUI("player") then return true end
        return false
    end

    -- Quita la habilidad y devuelve al boton sus atributos normales. `conservarRegistro` aparta
    -- solo el BOTON (posesion): la ranura guardada sobrevive y la restauracion la devuelve al
    -- soltar al NPC. Sin el, se olvida tambien la ranura (arrastre/limpieza del usuario). Esto
    -- es justo lo que pierde Arcanum con .poss: limpia el registro al ceder el boton y al
    -- despose(er) ya no queda nada que restaurar.
    function API.LimpiarBoton(button, conservarRegistro)
        if not button or EnCombate() then return false end
        if button:GetAttribute("type") ~= TIPO then return false end
        button:SetAttribute("type", "action")
        button:SetAttribute("_" .. TIPO, nil)
        button.harfordFeature, button.harfordIcon = nil, nil
        button.harfordName, button.harfordDesc = nil, nil
        local nombre = button.Name or (button.GetName and _G[button:GetName() .. "Name"])
        if nombre then nombre:SetText("") end
        if not conservarRegistro then
            local r = Ranura(button)
            if r then Store().botones[r] = nil end
        end
        if button.Update then pcall(button.Update, button) end
        return true
    end

    -- Datos de presentacion de una carga: habilidad del Libro (featureId pelado, el formato
    -- guardado de siempre) o conjuro del compendio ("conjuro:<id>").
    local function DatosDeCarga(carga)
        carga = tostring(carga or "")
        local spellId = carga:match("^conjuro:(.+)$")
        if spellId then
            local api = _G.HarfordCompendioAPI
            local spell = api and api.GetSpellById and api.GetSpellById(spellId)
            if not spell then return nil end
            return {
                name = spell.name,
                icon = (api.GetSpellIcon and api.GetSpellIcon(spell)) or spell.icon,
                description = spell.description,
            }
        end
        return HarfordCharacterPanel and HarfordCharacterPanel.DatosDeHabilidad
            and HarfordCharacterPanel.DatosDeHabilidad(carga)
    end

    -- Coloca una carga (habilidad del Libro o conjuro) en un boton nativo.
    function API.AsignarBoton(button, carga, silencioso)
        if not button or EnCombate() then return false end
        local datos = DatosDeCarga(carga)
        if not datos then
            if not silencioso then Aviso("Esa habilidad ya no existe en tu ficha.") end
            return false
        end
        button.harfordFeature = tostring(carga)
        button.harfordIcon = datos.icon
        button.harfordName = datos.name
        button.harfordDesc = datos.description
        button:SetAttribute("type", TIPO)
        button:SetAttribute("_" .. TIPO, function(self)
            local id = tostring(self.harfordFeature or "")
            local spellId = id:match("^conjuro:(.+)$")
            if spellId then
                local api = _G.HarfordCompendioAPI
                if api and api.ResolveCast then
                    local ok, err = api.ResolveCast(spellId)
                    if ok == false and err then Aviso(tostring(err)) end
                end
            elseif HarfordCharacterPanel and HarfordCharacterPanel.ActivarHabilidadPorId then
                HarfordCharacterPanel.ActivarHabilidadPorId(id, self)
            end
        end)
        Pintar(button)
        local r = Ranura(button)
        if r then Store().botones[r] = button.harfordFeature end
        return true
    end

    -- ── Arrastre desde el Libro ──────────────────────────────────────────────
    -- Estas habilidades no son hechizos reales, asi que `PickupSpell` no vale: la carga la lleva el
    -- propio addon y un icono sigue al cursor, como hace Arcanum.
    local arrastre

    local function IconoArrastre()
        if arrastre then return arrastre end
        arrastre = CreateFrame("Frame", "HarfordActionDragIcon", UIParent)
        arrastre:SetFrameStrata("TOOLTIP")
        arrastre:SetSize(32, 32)
        arrastre:EnableMouse(false)
        arrastre.tex = arrastre:CreateTexture(nil, "OVERLAY")
        arrastre.tex:SetAllPoints()
        arrastre:Hide()
        -- OnUpdate solo mientras dura el arrastre: la guardia sale en la primera linea.
        arrastre:SetScript("OnUpdate", function(self)
            if not self.activo then return end
            local escala, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
            self:ClearAllPoints()
            self:SetPoint("CENTER", nil, "BOTTOMLEFT", x / escala, y / escala)
        end)
        return arrastre
    end

    function API.RecogerHabilidad(featureId)
        if EnCombate() then return false end
        local datos = HarfordCharacterPanel and HarfordCharacterPanel.DatosDeHabilidad
            and HarfordCharacterPanel.DatosDeHabilidad(featureId)
        if not datos then return false end
        local f = IconoArrastre()
        f.featureId, f.activo = tostring(featureId), true
        f.tex:SetTexture(datos.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        f:Show()
        if GameTooltip then GameTooltip:Hide() end
        return true
    end

    -- Recoge un conjuro del compendio; misma carga de cursor que las habilidades.
    function API.RecogerConjuro(spellId)
        if EnCombate() then return false end
        local carga = "conjuro:" .. tostring(spellId or "")
        local datos = DatosDeCarga(carga)
        if not datos then return false end
        local f = IconoArrastre()
        f.featureId, f.activo = carga, true
        f.tex:SetTexture(datos.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        f:Show()
        if GameTooltip then GameTooltip:Hide() end
        return true
    end

    function API.HabilidadEnElCursor()
        return arrastre and arrastre.activo and arrastre.featureId or nil
    end

    local BotonesNativos  -- adelantada: se define mas abajo y aqui solo se llama al soltar

    -- Suelta la carga y, si el raton esta sobre un boton nativo, la COLOCA. No se puede confiar
    -- en el OnReceiveDrag del boton: solo dispara con cargas del cursor REAL de WoW (hechizos,
    -- items), y la nuestra es un icono propio -- por eso arrastrar "no hacia nada". Mismo
    -- enfoque que Arcanum: mirar que hay bajo el raton en el momento de soltar.
    function API.SoltarHabilidad()
        if not arrastre then return end
        local carga = arrastre.activo and arrastre.featureId or nil
        arrastre.activo, arrastre.featureId = false, nil
        arrastre:Hide()
        if not carga then return end
        if MouseIsOver and BotonesNativos then
            for _, b in ipairs(BotonesNativos()) do
                if b:IsVisible() and MouseIsOver(b) then
                    API.AsignarBoton(b, carga)
                    return
                end
            end
        end
    end

    -- ── Enganche a los botones nativos ───────────────────────────────────────
    local enganchados = {}

    local function Enganchar(button)
        if not button or enganchados[button] then return end
        enganchados[button] = true
        local function soltar(self)
            local id = API.HabilidadEnElCursor()
            if not id then return end
            API.AsignarBoton(self, id)
            API.SoltarHabilidad()
        end
        button:HookScript("OnEnter", function(self)
            if self:GetAttribute("type") ~= TIPO or not GameTooltip then return end
            local id = tostring(self.harfordFeature or "")
            local spellId = id:match("^conjuro:(.+)$")
            if spellId then
                -- Formato de la pestana Conjuros: nombre, "Nivel N - Escuela" y descripcion.
                local api = _G.HarfordCompendioAPI
                local spell = api and api.GetSpellById and api.GetSpellById(spellId)
                if not spell then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(spell.name or "?", 1, 0.82, 0)
                local nivel = tonumber(spell.level) or 0
                GameTooltip:AddLine((nivel == 0 and "Truco" or ("Nivel " .. nivel))
                    .. "  -  " .. (spell.school or "-"), 0.8, 0.8, 0.8)
                if spell.description and spell.description ~= "" then
                    GameTooltip:AddLine(spell.description, 1, 1, 1, true)
                end
                GameTooltip:Show()
            elseif HarfordCharacterPanel and HarfordCharacterPanel.TooltipDeHabilidad then
                -- El MISMO tooltip que el Libro de habilidades: cabecera, usos y colores.
                HarfordCharacterPanel.TooltipDeHabilidad(id, self)
            end
        end)
        button:HookScript("OnLeave", function(self)
            if self:GetAttribute("type") == TIPO and GameTooltip then GameTooltip:Hide() end
        end)
        button:HookScript("OnReceiveDrag", soltar)
        button:HookScript("OnClick", soltar)
        button:HookScript("OnDragStart", function(self)
            -- Sacar la habilidad del boton devuelve el hueco a Blizzard.
            if self:GetAttribute("type") == TIPO then API.LimpiarBoton(self) end
        end)
    end

    function BotonesNativos()
        local fuera = {}
        if ActionBarButtonEventsFrame and ActionBarButtonEventsFrame.frames then
            for _, b in ipairs(ActionBarButtonEventsFrame.frames) do fuera[#fuera + 1] = b end
        else
            for i = 1, 12 do
                local b = _G["ActionButton" .. i]
                if b then fuera[#fuera + 1] = b end
            end
        end
        return fuera
    end

    -- Restaura lo guardado. Se llama al entrar y al cambiar de pagina de barra.
    function API.RestaurarBarra()
        if InCombatLockdown and InCombatLockdown() then return 0 end
        local n = 0
        for _, b in ipairs(BotonesNativos()) do
            Enganchar(b)
            local r = Ranura(b)
            local id = r and Store().botones[r]
            -- Con accion real presente (posesion o hechizo del usuario) no se asigna NI se
            -- olvida: si la accion es pasajera, la siguiente restauracion la devuelve.
            local accionReal = b.CalculateAction and GetActionInfo
                and b:CalculateAction() and GetActionInfo(b:CalculateAction())
            if id and not accionReal and b:GetAttribute("type") ~= TIPO then
                if API.AsignarBoton(b, id, true) then n = n + 1 end
            elseif not id and b:GetAttribute("type") == TIPO then
                API.LimpiarBoton(b)
            end
        end
        return n
    end

    -- Blizzard repinta sus botones y borraria el icono. `ActionButton_UpdateFlyout` sigue siendo
    -- global y se llama al final de la actualizacion, asi que es donde se recupera. Y si le han
    -- soltado encima un hechizo REAL, la habilidad se aparta: manda Blizzard.
    if hooksecurefunc and _G.ActionButton_UpdateFlyout then
        hooksecurefunc("ActionButton_UpdateFlyout", function(self)
            if not (self and self.GetAttribute and self:GetAttribute("type") == TIPO) then return end
            if self.CalculateAction and GetActionInfo then
                local accion = self:CalculateAction()
                if accion and GetActionInfo(accion) then
                    -- En posesion la accion real es la del NPC y es pasajera: apartarse SIN
                    -- olvidar la ranura. Fuera de posesion es el usuario poniendo algo encima.
                    API.LimpiarBoton(self, EnPosesion())
                    if self.Update then pcall(self.Update, self) end
                    return
                end
            end
            Pintar(self)
        end)
    end

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_LOGIN")
    ev:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- Posesion (.poss) y vehiculos: al entrar, la barra del NPC manda; al salir, restaurar lo
    -- nuestro. Diferido un tick para mirar la barra DESPUES de que el cliente la haya movido.
    ev:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
    ev:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    ev:RegisterEvent("UNIT_ENTERED_VEHICLE")
    ev:RegisterEvent("UNIT_EXITED_VEHICLE")
    ev:SetScript("OnEvent", function(_, evento, unidad)
        if (evento == "UNIT_ENTERED_VEHICLE" or evento == "UNIT_EXITED_VEHICLE") and unidad ~= "player" then return end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() API.RestaurarBarra() end)
        else
            API.RestaurarBarra()
        end
    end)
end
