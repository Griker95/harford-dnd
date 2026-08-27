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
local AbrirPanelDeBloque   -- se asigna abajo; el menu de tarjeta cierra sobre ella

local function AbrirMenu(entry, ancla)
    if not entry then return end
    -- Sin ser admin no se abre menu y YA ESTA. Avisarlo convertia cada click derecho sobre una
    -- tarjeta en una linea de chat repetida, y el click derecho es un gesto que se da constantemente.
    if not EsAdmin() then return end
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
        -- Un BLOQUE no abre menu: sus miembros se gestionan en su lista, que ya abre el click
        -- izquierdo. Tener ademas un submenu de anadir aqui era la misma cosa en dos sitios, y el
        -- de aqui ni siquiera podia enseniar la vida ni la CA de quien esta dentro.
        if tipo == "players" or tipo == "generic" then
            AbrirPanelDeBloque(entry)
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
    local AnadirObjetivo, AnadirDelGrupo   -- se asignan abajo; los botones cierran sobre ellas
    local bloqueActual
    -- Las mismas medidas que las tarjetas de la ventana de turnos (70x122): son lo mismo, un
    -- combatiente, y tienen que leerse igual. Tres por fila, cuatro filas.
    local TARJ_W, TARJ_H, TARJ_HUECO = 70, 122, 6
    local COLUMNAS, FILAS_A_LA_VISTA = 3, 4
    -- Hueco para la barra de desplazamiento a la derecha: si no, se come media tarjeta.
    local PANEL_ANCHO = 16 + COLUMNAS * TARJ_W + (COLUMNAS - 1) * TARJ_HUECO + 22
    local ALTO_VISTA = FILAS_A_LA_VISTA * (TARJ_H + TARJ_HUECO)
    local RefrescarPanel

    local function EnsureFila(i)
        local f = filas[i]
        if f then return f end
        -- La monta el CORE, con las mismas piezas que las tarjetas de la ventana de turnos.
        -- Rehacerlas aqui fue el error de la primera version: quedaban parecidas y se actualizaban
        -- de otra forma, asi que cualquier cambio en una no llegaba a la otra.
        f = API().CreateCardVisuals(panel.contenido)
        f:EnableMouse(true)
        f.quitar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        f.quitar:SetSize(20, 20)
        f.quitar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
        f.quitar:SetFrameLevel(f.border:GetFrameLevel() + 1)
        filas[i] = f
        return f
    end

    local function CrearPanel()
        if panel then return panel end
        panel = CreateFrame("Frame", "HarfordAdminBlockFrame", UIParent, "BackdropTemplate")
        panel:SetSize(PANEL_ANCHO, 30 + ALTO_VISTA + 40)
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
        -- Con muchas tarjetas se baja a verlas, pero el boton NO se va con ellas: vive en el
        -- panel, fuera del area que se desplaza, asi que no lo recorta el scroll ni se pierde de
        -- vista cuando la lista crece.
        panel.scroll = CreateFrame("ScrollFrame", "HarfordAdminBlockScroll", panel,
            "UIPanelScrollFrameTemplate")
        panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -30)
        panel.scroll:SetSize(COLUMNAS * TARJ_W + (COLUMNAS - 1) * TARJ_HUECO, ALTO_VISTA)
        panel.contenido = CreateFrame("Frame", nil, panel.scroll)
        panel.contenido:SetSize(COLUMNAS * TARJ_W + (COLUMNAS - 1) * TARJ_HUECO, ALTO_VISTA)
        panel.scroll:SetScrollChild(panel.contenido)

        -- Abajo, donde se busca: anadir es lo que mas se hace en esta ventana.
        panel.anadir = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        panel.anadir:SetHeight(22)
        panel.anadir:SetScript("OnClick", function() AnadirObjetivo() end)
        -- Anadir al grupo entero es SOLO para el bloque de PJs: a los NPC no se les puede hacer
        -- porque el cliente no permite enumerarlos mas alla de los que tengan placa visible.
        panel.anadirGrupo = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        panel.anadirGrupo:SetHeight(22)
        panel.anadirGrupo:SetText("Anadir al grupo...")
        panel.anadirGrupo:SetScript("OnClick", function() AnadirDelGrupo() end)

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
        -- En PJs van los dos, uno al lado del otro; en un bloque de NPCs solo el del objetivo, y
        -- entonces ocupa el ancho entero.
        panel.anadir:SetText("Anadir el objetivo")
        panel.anadir:ClearAllPoints()
        if tostring(bloqueActual.kind or "") == "players" then
            local mitad = (PANEL_ANCHO - 28) / 2
            panel.anadir:SetWidth(mitad)
            panel.anadir:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)
            panel.anadirGrupo:SetWidth(mitad)
            panel.anadirGrupo:ClearAllPoints()
            panel.anadirGrupo:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)
            panel.anadirGrupo:Show()
        else
            panel.anadir:SetWidth(PANEL_ANCHO - 24)
            panel.anadir:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
            panel.anadirGrupo:Hide()
        end
        -- El alto del contenido crece con las tarjetas; el area a la vista no. Eso es lo que hace
        -- que aparezca la barra en vez de recortar la lista.
        local filasNecesarias = math.max(FILAS_A_LA_VISTA, math.ceil(#dentro / COLUMNAS))
        panel.contenido:SetHeight(filasNecesarias * (TARJ_H + TARJ_HUECO))
        for i = 1, math.max(#dentro, #filas) do
            local m, f = dentro[i], EnsureFila(i)
            if not m then f:Hide()
            else
                -- El miembro YA ES una entrada, con los mismos datos que una tarjeta normal.
                -- Se le pasa tal cual al pintor del core: nada de rellenar de la unidad que tengas
                -- delante, que era lo que hacia perder el icono al cambiar de objetivo y ponia la
                -- vida NATIVA de un PJ en vez de la del sistema.
                API().PaintEntryCard(f, m, false)
                f.quitar:SetScript("OnClick", function()
                    T.RemoveBlockMember(bloqueActual, m.guid)
                    Print(tostring(m.name or "?") .. " sale de " .. tostring(bloqueActual.name) .. ".")
                    RefrescarPanel()
                end)
                f:ClearAllPoints()
                local col, fila = (i - 1) % COLUMNAS, math.floor((i - 1) / COLUMNAS)
                f:SetPoint("TOPLEFT", panel.contenido, "TOPLEFT",
                    col * (TARJ_W + TARJ_HUECO), -fila * (TARJ_H + TARJ_HUECO))
                f:Show()
            end
        end
    end

    -- Anadir al que tengas delante. Vale para cualquier bloque, PJs incluido: un jugador tambien
    -- se mete apuntandolo, sin tener que buscarlo en una lista.
    local menuAnadir
    AnadirObjetivo = function()
        local T = API()
        if not bloqueActual then return end
        if not (UnitExists and UnitExists("target")) then
            Print("No tienes ningun objetivo.")
            return
        end
        -- Un jugador NO entra en un bloque de NPCs: los PJs van siempre con los PJs, y meterlo
        -- aqui lo sacaria de su bando sin que nadie lo note.
        local esJugador = UnitIsPlayer and UnitIsPlayer("target")
        local esBloqueDePJs = tostring(bloqueActual.kind or "") == "players"
        if esJugador and not esBloqueDePJs then
            Print("|cffff5555" .. tostring(UnitName("target")) .. " es un jugador:|r va en el "
                .. "bloque de PJs, no en " .. tostring(bloqueActual.name) .. ".")
            return
        end
        -- Y al reves: el bloque de PJs es de jugadores. Un NPC ahi rompe el bando igual de callado.
        if esBloqueDePJs and not esJugador then
            Print("|cffff5555" .. tostring(UnitName("target")) .. " no es un jugador:|r va en un "
                .. "bloque de NPCs, no en " .. tostring(bloqueActual.name) .. ".")
            return
        end
        local ok, err = T.AddBlockMember(bloqueActual, "target")
        Print(ok and (tostring(UnitName("target")) .. " entra en "
            .. tostring(bloqueActual.name) .. ".") or tostring(err))
        RefrescarPanel()
    end

    -- Y la lista del grupo, solo para PJs: son varios y estan todos a mano.
    AnadirDelGrupo = function()
        local T = API()
        if not bloqueActual then return end
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
        ToggleDropDownMenu(1, nil, menuAnadir, panel.anadirGrupo, 0, 0)
    end

    AbrirPanelDeBloque = function(entry)
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
