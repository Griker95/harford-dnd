-- HarfordAdminTurns: lo que solo hace un DM sobre el orden de turnos.
--
-- El core (`HarfordTurns`) guarda los datos y los reparte; aqui vive la UI y las decisiones que
-- son exclusivas del DM, que es la regla del proyecto: sin este addon cargado no aparece ni el
-- menu de bandos, ni el interruptor de modo, ni la asignacion de DMs secundarios.
--
-- Se engancha por los callbacks que el core expone -- `OnCardRightClick`, `RegisterAdminControl`
-- --, igual que `HarfordTRP3.InsertGlanceLink`.

local function Print(mensaje)
    if HarfordChat and HarfordChat.Print then HarfordChat.Print(mensaje) end
end

local function EsAdmin()
    return HarfordAuthority and HarfordAuthority.CanUseDMTools
        and HarfordAuthority.CanUseDMTools() == true
end

local function API()
    return _G.HarfordTurnOrderAPI
end

-- ─── DMs SECUNDARIOS ─────────────────────────────────────────────────────────
-- El lider reparte la carga nombrando ayudantes. Un efecto delegado recorre la CADENA -- lider
-- primero, secundarios detras -- y lo aplica el PRIMERO que pueda emitir el comando.
--
-- Cadena y no difusion a todos: si le llegara a varios y dos tuvieran el NPC seleccionado, se
-- aplicaria dos veces. Un golpe de 7 quitaria 14, y eso no se ve venir en mesa.

local menuTarjeta

local function NombreCorto(nombre)
    nombre = tostring(nombre or "")
    return (Ambiguate and Ambiguate(nombre, "short")) or nombre:match("^[^%-]+") or nombre
end

local function EsSecundario(nombre)
    local T = API()
    if not (T and T.GetSecondaryDMs) then return false end
    local buscado = NombreCorto(nombre):lower()
    for _, n in ipairs(T.GetSecondaryDMs()) do
        if NombreCorto(n):lower() == buscado then return true end
    end
    return false
end

local function AlternarSecundario(entry)
    local T = API()
    if not (T and T.SetSecondaryDMs and T.GetSecondaryDMs) then return end
    local nombre = tostring(entry.unitName or entry.name or "")
    if nombre == "" then Print("Esa entrada no tiene nombre de jugador.") return end

    local lista, fuera = {}, false
    for _, n in ipairs(T.GetSecondaryDMs()) do
        if NombreCorto(n):lower() == NombreCorto(nombre):lower() then fuera = true
        else lista[#lista + 1] = n end
    end
    if not fuera then lista[#lista + 1] = nombre end

    T.SetSecondaryDMs(lista)
    Print(fuera
        and (NombreCorto(nombre) .. " deja de ser DM secundario.")
        or (NombreCorto(nombre) .. " es DM secundario: recibira los efectos que el lider no pueda "
            .. "aplicar."))
end

-- ─── MENU DE LA TARJETA ──────────────────────────────────────────────────────
local function AbrirMenu(entry, ancla)
    if not entry then return end
    if not EsAdmin() then Print("Solo el admin gestiona los turnos.") return end
    local tipo = tostring(entry.kind or "")
    if tipo ~= "npc" and tipo ~= "player" and tipo ~= "players" and tipo ~= "generic" then
        return
    end

    local T = API()
    menuTarjeta = menuTarjeta or CreateFrame("Frame", "HarfordAdminTurnsMenu", UIParent,
        "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menuTarjeta, function(_, level)
        local titulo = UIDropDownMenu_CreateInfo()
        titulo.isTitle, titulo.notCheckable = true, true
        titulo.text = tostring(entry.name or "?")
        UIDropDownMenu_AddButton(titulo, level)

        -- Una tarjeta ESPECIAL es un BLOQUE: aqui se gestiona quien va dentro. Sus miembros no
        -- tienen tarjeta propia -- su vida se mira en el unitframe al seleccionarlos --, asi que
        -- esta es la unica forma de verlos y de tocarlos.
        if tipo == "players" or tipo == "generic" then
            local dentro = T.GetBlockMembers(entry)

            local anadir = UIDropDownMenu_CreateInfo()
            anadir.notCheckable = true
            anadir.text = (UnitExists and UnitExists("target"))
                and ("Anadir a " .. tostring(UnitName("target")))
                or "Anadir el objetivo (no hay ninguno)"
            anadir.disabled = not (UnitExists and UnitExists("target"))
            anadir.func = function()
                local ok, err = T.AddBlockMember(entry, "target")
                Print(ok and (tostring(UnitName("target")) .. " entra en "
                    .. tostring(entry.name or "el bloque") .. ".") or tostring(err))
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(anadir, level)

            -- Solo en el bloque de PJs: a los NPC no se les puede hacer en bloque, porque el
            -- cliente no permite enumerarlos mas alla de los que tengan placa visible.
            if tipo == "players" then
                local todos = UIDropDownMenu_CreateInfo()
                todos.notCheckable = true
                todos.text = "Anadir a todos los jugadores"
                todos.func = function()
                    local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
                    local enRaid = IsInRaid and IsInRaid()
                    local unidades = { "player" }
                    for i = 1, (enRaid and n or math.max(0, n - 1)) do
                        unidades[#unidades + 1] = (enRaid and "raid" or "party") .. i
                    end
                    local puestos = 0
                    for _, u in ipairs(unidades) do
                        -- Solo CONECTADOS: uno desconectado no va a jugar su turno y meterlo
                        -- obliga a quitarlo despues.
                        if UnitExists and UnitExists(u)
                            and (not UnitIsConnected or UnitIsConnected(u))
                            and T.AddBlockMember(entry, u) then
                            puestos = puestos + 1
                        end
                    end
                    Print(puestos > 0
                        and ("Anadidos " .. puestos .. " jugador(es) a " .. tostring(entry.name) .. ".")
                        or "No habia ningun jugador conectado que anadir.")
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(todos, level)
            end

            if #dentro > 0 then
                local sep = UIDropDownMenu_CreateInfo()
                sep.isTitle, sep.notCheckable = true, true
                sep.text = "Dentro (" .. #dentro .. "):"
                UIDropDownMenu_AddButton(sep, level)
                for _, m in ipairs(dentro) do
                    local fila = UIDropDownMenu_CreateInfo()
                    fila.notCheckable = true
                    fila.text = "|cffff8888x|r  " .. tostring(m.name or "?")
                    fila.func = function()
                        T.RemoveBlockMember(entry, m.guid)
                        Print(tostring(m.name or "?") .. " sale de "
                            .. tostring(entry.name or "el bloque") .. ".")
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(fila, level)
                end
            end
            return
        end

        -- Un JUGADOR no cambia de bando -- va siempre con los PJs -- pero si puede ser DM
        -- secundario, que es lo unico que se decide sobre el desde aqui.
        if tipo == "player" then
            local i = UIDropDownMenu_CreateInfo()
            i.text = "DM secundario"
            i.checked = EsSecundario(entry.unitName or entry.name)
            i.func = function() AlternarSecundario(entry); CloseDropDownMenus() end
            UIDropDownMenu_AddButton(i, level)
            return
        end

        local actual = T.GetBando(entry)
        for _, b in ipairs(T.BANDOS) do
            local i = UIDropDownMenu_CreateInfo()
            i.text = T.BANDO_ETIQUETA[b] or b
            i.checked = (b == actual)
            i.func = function()
                local vivo = T.GetActiveBando()
                if T.SetBando(entry, b) then
                    -- Decir SIEMPRE cuando entra en juego: meter a alguien en el bloque que se
                    -- esta jugando y que no le toque nada desconcierta sin explicacion.
                    if vivo == b then
                        Print("El turno de " .. tostring(T.BANDO_ETIQUETA[b] or b)
                            .. " ya esta en juego: entra en el proximo asalto.")
                    end
                    Print(tostring(entry.name or "?") .. " pasa a "
                        .. tostring(T.BANDO_ETIQUETA[b] or b) .. ".")
                    -- Difundir en el acto: si el reparto llegase tarde, el bloque que ya esta en
                    -- juego tocaria con la lista vieja.
                    if T.Broadcast then T.Broadcast() end
                end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(i, level)
        end
    end, "MENU")
    ToggleDropDownMenu(1, nil, menuTarjeta, ancla or "cursor", 0, 0)
end

-- ─── LA LISTA DE TARJETAS DE UN BLOQUE ───────────────────────────────────────
-- Quien esta dentro de un bloque no tiene tarjeta en la lista compartida -- ese es el modelo: la
-- mesa ve el bloque, no a sus quince miembros --, pero el DM necesita verlos y tocarlos. Este
-- panel es esa vista, y es SUYA: vive en HarfordAdmin y no existe para nadie mas.
--
-- La vida sale de la unidad viva cuando esta a la vista; si no lo esta, se dice, en vez de enseniar
-- un numero viejo que nadie puede comprobar.
do
    local panel, filas = nil, {}
    local AnadirABloque   -- se asigna abajo; el boton cierra sobre ella
    local bloqueActual
    local FILA_ALTO, PANEL_ANCHO, VISIBLES = 24, 240, 12
    local RefrescarPanel

    local function EnsureFila(i)
        local f = filas[i]
        if f then return f end
        f = CreateFrame("Button", nil, panel, "BackdropTemplate")
        f:SetSize(PANEL_ANCHO - 16, FILA_ALTO)
        -- Con fondo y marco: son TARJETAS, como las de la ventana de turnos, no lineas de texto.
        -- Quien esta dentro de un bloque es un combatiente, y se tiene que leer como tal.
        f.fondo = f:CreateTexture(nil, "BACKGROUND")
        f.fondo:SetAllPoints(f)
        f.fondo:SetColorTexture(0, 0, 0, 0.35)
        f.retrato = f:CreateTexture(nil, "ARTWORK")
        f.retrato:SetSize(FILA_ALTO - 6, FILA_ALTO - 6)
        f.retrato:SetPoint("LEFT", f, "LEFT", 3, 0)
        -- Retrato circular, como el resto del addon.
        local mascara = f:CreateMaskTexture(nil, "ARTWORK")
        mascara:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
            "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mascara:SetAllPoints(f.retrato)
        f.retrato:AddMaskTexture(mascara)
        f.marco = f:CreateTexture(nil, "OVERLAY")
        f.marco:SetTexture("Interface\\Common\\WhiteIconFrame")
        f.marco:SetSize(FILA_ALTO - 2, FILA_ALTO - 2)
        f.marco:SetPoint("CENTER", f.retrato, "CENTER")
        f.marco:SetVertexColor(0.55, 0.5, 0.4)
        f.texto = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.texto:SetPoint("LEFT", f.retrato, "RIGHT", 6, 0)
        f.texto:SetJustifyH("LEFT")
        f.vida = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        f.vida:SetPoint("RIGHT", f, "RIGHT", -20, 0)
        f.quitar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        f.quitar:SetSize(18, 18)
        f.quitar:SetPoint("RIGHT", f, "RIGHT", 2, 0)
        filas[i] = f
        return f
    end

    -- La unidad viva de un guid, si esta a la vista. Las mismas dos fuentes de siempre: el grupo y
    -- las placas de nombre; no hay forma de mirar a alguien que no este en ninguna.
    local function UnidadDe(guid)
        for _, u in ipairs({ "target", "focus", "mouseover", "player" }) do
            if UnitExists and UnitExists(u) and UnitGUID and UnitGUID(u) == guid then return u end
        end
        local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
        local prefijo = (IsInRaid and IsInRaid()) and "raid" or "party"
        for i = 1, n do
            local u = prefijo .. i
            if UnitExists and UnitExists(u) and UnitGUID(u) == guid then return u end
        end
        if C_NamePlate and C_NamePlate.GetNamePlates then
            for _, placa in ipairs(C_NamePlate.GetNamePlates() or {}) do
                local u = placa.namePlateUnitToken or placa.unit
                if u and UnitGUID(u) == guid then return u end
            end
        end
        return nil
    end

    local function CrearPanel()
        if panel then return panel end
        panel = CreateFrame("Frame", "HarfordAdminBlockFrame", UIParent, "BackdropTemplate")
        panel:SetSize(PANEL_ANCHO, 30 + VISIBLES * FILA_ALTO + 12)
        panel:SetFrameStrata("DIALOG")
        panel:SetFrameLevel(520)
        panel:SetClampedToScreen(true)
        panel:SetMovable(true)
        panel:EnableMouse(true)
        panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart", panel.StartMoving)
        panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
        panel.borde = CreateFrame("Frame", nil, panel, "DialogBorderTemplate")
        panel.borde:SetAllPoints(panel)
        panel.titulo = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        panel.titulo:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -12)
        -- Abajo, donde se busca: anadir es lo que mas se hace en esta ventana.
        panel.anadir = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        panel.anadir:SetSize(PANEL_ANCHO - 24, 22)
        panel.anadir:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
        panel.anadir:SetScript("OnClick", function() AnadirABloque() end)

        panel.cerrar = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        panel.cerrar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
        panel.cerrar:SetScript("OnClick", function() panel:Hide() end)
        -- Solo mientras se ve: las placas y la vida disparan constantemente.
        panel:SetScript("OnShow", function(self)
            self:RegisterEvent("UNIT_HEALTH")
            self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
            self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
            if RefrescarPanel then RefrescarPanel() end
        end)
        panel:SetScript("OnHide", function(self) self:UnregisterAllEvents() end)
        panel:SetScript("OnEvent", function() if RefrescarPanel then RefrescarPanel() end end)
        panel:Hide()
        return panel
    end

    RefrescarPanel = function()
        if not (panel and panel:IsShown() and bloqueActual) then return end
        local T = API()
        local dentro = T.GetBlockMembers(bloqueActual)
        panel.titulo:SetText(tostring(bloqueActual.name or "Bloque")
            .. "  |cff999999(" .. #dentro .. ")|r")
        -- El boton dice lo que va a hacer, que no es lo mismo en un bloque de PJs que en uno de
        -- NPCs: alli hay lista, aqui se anade lo que tengas delante.
        panel.anadir:SetText(tostring(bloqueActual.kind or "") == "players"
            and "Anadir al grupo..." or "Anadir el objetivo")
        for i = 1, VISIBLES do
            local m, f = dentro[i], EnsureFila(i)
            if not m then f:Hide()
            else
                local unidad = UnidadDe(m.guid)
                f.texto:SetText(tostring(m.name or "?"))
                if m.jugador and HarfordClassColors and HarfordClassColors.UnitColorRGB and unidad then
                    local r, g, b = HarfordClassColors.UnitColorRGB(unidad)
                    if r then f.texto:SetTextColor(r, g, b) end
                else
                    f.texto:SetTextColor(0.9, 0.85, 0.7)
                end
                -- La vida sale de la unidad viva. Si no esta a la vista se dice, en vez de enseniar
                -- un numero viejo que nadie puede comprobar.
                if unidad and UnitHealth then
                    f.vida:SetText(tostring(UnitHealth(unidad)) .. "/" .. tostring(UnitHealthMax(unidad)))
                    f.vida:SetTextColor(0.6, 0.85, 0.6)
                else
                    f.vida:SetText("sin vista")
                    f.vida:SetTextColor(0.5, 0.5, 0.5)
                end
                if unidad and SetPortraitTexture then
                    SetPortraitTexture(f.retrato, unidad)
                else
                    f.retrato:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                f.quitar:SetScript("OnClick", function()
                    T.RemoveBlockMember(bloqueActual, m.guid)
                    Print(tostring(m.name or "?") .. " sale de " .. tostring(bloqueActual.name) .. ".")
                    RefrescarPanel()
                end)
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -30 - (i - 1) * FILA_ALTO)
                f:Show()
            end
        end
    end

    -- En PJs se despliega la LISTA del grupo: son varios y estan todos a mano. En los demas se
    -- anade el OBJETIVO, porque a los NPC no hay forma de enumerarlos.
    local menuAnadir
    AnadirABloque = function()
        local T = API()
        if not bloqueActual then return end

        if tostring(bloqueActual.kind or "") ~= "players" then
            -- Un jugador NO entra en un bloque de NPCs: los PJs van siempre con los PJs, y meterlo
            -- aqui lo sacaria de su bando sin que nadie lo note.
            if UnitExists and UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") then
                Print("|cffff5555" .. tostring(UnitName("target")) .. " es un jugador:|r va en el "
                    .. "bloque de PJs, no en " .. tostring(bloqueActual.name) .. ".")
                return
            end
            local ok, err = T.AddBlockMember(bloqueActual, "target")
            Print(ok and (tostring(UnitName("target")) .. " entra en "
                .. tostring(bloqueActual.name) .. ".") or tostring(err))
            RefrescarPanel()
            return
        end

        -- Bloque de PJs: la lista del grupo, con los que ya estan marcados.
        menuAnadir = menuAnadir or CreateFrame("Frame", "HarfordAdminBlockAddMenu", UIParent,
            "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(menuAnadir, function(_, level)
            local titulo = UIDropDownMenu_CreateInfo()
            titulo.isTitle, titulo.notCheckable = true, true
            titulo.text = "Anadir al bloque"
            UIDropDownMenu_AddButton(titulo, level)

            local dentro = {}
            for _, m in ipairs(T.GetBlockMembers(bloqueActual)) do dentro[m.guid] = true end

            local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
            local enRaid = IsInRaid and IsInRaid()
            local unidades = { "player" }
            for i = 1, (enRaid and n or math.max(0, n - 1)) do
                unidades[#unidades + 1] = (enRaid and "raid" or "party") .. i
            end
            for _, u in ipairs(unidades) do
                if UnitExists and UnitExists(u) then
                    local guid = UnitGUID(u)
                    local i = UIDropDownMenu_CreateInfo()
                    i.text = tostring(UnitName(u))
                    -- Un desconectado no va a jugar su turno: se ve, pero no se puede meter.
                    local conectado = (not UnitIsConnected) or UnitIsConnected(u)
                    if not conectado then i.text = i.text .. " |cff808080(desconectado)|r" end
                    i.checked = dentro[guid] and true or false
                    i.disabled = not conectado
                    i.func = function()
                        if dentro[guid] then T.RemoveBlockMember(bloqueActual, guid)
                        else T.AddBlockMember(bloqueActual, u) end
                        RefrescarPanel()
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(i, level)
                end
            end

            local todos = UIDropDownMenu_CreateInfo()
            todos.notCheckable = true
            todos.text = "|cff88ff88Anadir a todo el grupo|r"
            todos.func = function()
                local puestos = 0
                for _, u in ipairs(unidades) do
                    if UnitExists(u) and ((not UnitIsConnected) or UnitIsConnected(u))
                        and T.AddBlockMember(bloqueActual, u) then
                        puestos = puestos + 1
                    end
                end
                Print(puestos > 0 and ("Anadidos " .. puestos .. " jugador(es).")
                    or "No habia a quien anadir.")
                RefrescarPanel()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(todos, level)
        end, "MENU")
        ToggleDropDownMenu(1, nil, menuAnadir, panel.anadir, 0, 0)
    end

    function AbrirPanelDeBloque(entry)
        if not EsAdmin() then return end
        CrearPanel()
        -- Pulsar el mismo bloque cierra; otro CAMBIA sin cerrar, que es lo que se espera al ir
        -- repasando categorias.
        if panel:IsShown() and bloqueActual == entry then panel:Hide() return end
        bloqueActual = entry
        local ventana = API().GetFrame and API().GetFrame()
        panel:ClearAllPoints()
        if ventana then panel:SetPoint("TOPLEFT", ventana, "BOTTOMLEFT", 0, -6)
        else panel:SetPoint("CENTER") end
        panel:Show()
    end
end

-- ─── INTERRUPTOR DE MODO ─────────────────────────────────────────────────────
local function MontarBotonModo()
    local T = API()
    local frame = T and T.GetFrame and T.GetFrame()
    if not (frame and T.RegisterAdminControl) then return end

    local boton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    boton:SetSize(56, 22)
    boton:SetPoint("TOPLEFT", frame, "TOPLEFT", 320, -75)
    boton:SetScript("OnClick", function()
        if not EsAdmin() then Print("Solo el admin cambia el modo de turnos.") return end
        local activo = not T.IsModoBandos()
        T.SetModoBandos(activo)
        Print(activo
            and "Iniciativa por BANDOS: el turno pasa de bloque a bloque."
            or "Iniciativa individual: el turno pasa de criatura a criatura.")
        if T.Broadcast then T.Broadcast() end
    end)

    local control = { frame = boton }
    -- El estado se lee del almacen en cada repintado: el modo viaja en la foto, asi que puede
    -- cambiarlo otro DM y este cliente tiene que enterarse.
    control.Refrescar = function()
        local activo = T.IsModoBandos()
        boton:SetText(activo and "Bandos" or "Individual")
        boton:GetFontString():SetTextColor(activo and 1.0 or 0.55,
            activo and 0.82 or 0.55, activo and 0.1 or 0.55)
    end
    control.Refrescar()
    T.RegisterAdminControl(control)
end

-- ─── ENGANCHE ────────────────────────────────────────────────────────────────
do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_LOGIN")
    ev:SetScript("OnEvent", function()
        local T = API()
        if not T then return end
        T.OnCardRightClick = AbrirMenu
        -- Click IZQUIERDO sobre un bloque: su lista de miembros. Sobre una criatura no se toca --
        -- ahi el core abre su ficha, que es lo util.
        if T.RegisterOnCardLeftClick then
            T.RegisterOnCardLeftClick(function(entry)
                local k = tostring(entry and entry.kind or "")
                if k ~= "players" and k ~= "generic" then return false end
                AbrirPanelDeBloque(entry)
                return true
            end)
        end
        -- El boton necesita la ventana, que se crea al abrirla por primera vez. Se intenta ahora y
        -- se reintenta al abrirse: sin ticker, solo dos oportunidades reales.
        MontarBotonModo()
        if T.RegisterOnFrameCreated then T.RegisterOnFrameCreated(MontarBotonModo) end
    end)
end
