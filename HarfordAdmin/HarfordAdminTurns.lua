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
            API().OpenBlockPanel(entry)
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
                if T.SetBando(entry, b) then
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

-- ─── LO QUE EL DM AÑADE A LA LISTA DE UN BLOQUE ─────────────────────────────
-- La lista la abre y la pinta el CORE, y la puede abrir cualquiera: mirar quien esta dentro es
-- informacion. EDITARLA si es del DM, y es lo unico que se cuelga desde aqui -- los dos botones de
-- anadir y la X de cada tarjeta. Sin HarfordAdmin la lista sigue existiendo, solo que de lectura.
do
    local panel, bloqueActual
    local AnadirObjetivo, AnadirDelGrupo   -- se asignan abajo; los botones cierran sobre ellas

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
        -- Que entre no se anuncia: se ve aparecer en la lista, que esta abierta delante. Una linea
        -- por miembro son diez seguidas al montar un bando. Lo que NO se ve es un fallo, y eso si.
        local ok, err = T.AddBlockMember(bloqueActual, "target")
        if not ok then Print(tostring(err)) end
        API().RefreshBlockPanel()
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
            -- En RAID, `raidN` ya te incluye a ti: anadir ademas "player" te listaba dos veces.
            -- En grupo no, porque `partyN` son los OTROS. Se filtra por guid en vez de por el tipo
            -- de grupo: es la misma unidad se llame como se llame, y asi tampoco cuela un `focus`
            -- o un `target` que apunte a alguien ya listado.
            local unidades, vistos = {}, {}
            local function Apuntar(u)
                if not (UnitExists and UnitExists(u)) then return end
                local guid = UnitGUID and UnitGUID(u)
                if not guid or vistos[guid] then return end
                vistos[guid] = true
                unidades[#unidades + 1] = u
            end
            Apuntar("player")
            for i = 1, n do Apuntar((enRaid and "raid" or "party") .. i) end
            for _, u in ipairs(unidades) do
                -- Un desconectado NO se enumera. Antes salia en gris y deshabilitado, y con una
                -- hermandad detras eran veinte lineas muertas para encontrar a los tres que
                -- estaban: no va a jugar su turno, asi que no pinta nada en la lista.
                if UnitExists and UnitExists(u)
                    and ((not UnitIsConnected) or UnitIsConnected(u)) then
                    local guid = UnitGUID(u)
                    local i = UIDropDownMenu_CreateInfo()
                    i.text = tostring(UnitName(u))
                    i.checked = dentro[guid] and true or false
                    i.func = function()
                        if dentro[guid] then T.RemoveBlockMember(bloqueActual, guid)
                        else T.AddBlockMember(bloqueActual, u) end
                        API().RefreshBlockPanel()
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
                API().RefreshBlockPanel()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(todos, level)
        end, "MENU")
        ToggleDropDownMenu(1, nil, menuAnadir, panel.anadirGrupo, 0, 0)
    end

    -- El decorador corre en CADA refresco, asi que todo lo que crea se reutiliza. Crear un boton
    -- por refresco seria una fuga silenciosa que solo se nota tras un rato largo de mesa.
    local function Decorar(p, entry, tarjetas, cuantas)
        panel, bloqueActual = p, entry
        -- Tener HarfordAdmin instalado no es estar de DM: sin `.ph dm` la lista es de LECTURA,
        -- igual que para quien no lo tiene. Antes los botones salian siempre y el que los pulsaba
        -- se comia el rechazo del servidor sin saber por que.
        if not EsAdmin() then
            if p.anadir then p.anadir:Hide() end
            if p.anadirGrupo then p.anadirGrupo:Hide() end
            for _, f in ipairs(tarjetas) do
                if f.quitar then f.quitar:Hide() end
            end
            return
        end
        if not p.anadir then
            local ancho = API().GetBlockPanelWidth()
            p.anadir = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
            p.anadir:SetHeight(22)
            p.anadir:SetScript("OnClick", function() AnadirObjetivo() end)
            p.anadirGrupo = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
            p.anadirGrupo:SetHeight(22)
            p.anadirGrupo:SetText("Anadir al grupo...")
            p.anadirGrupo:SetScript("OnClick", function() AnadirDelGrupo() end)
            p.anchoPanel = ancho
        end

        -- En PJs van los dos, uno al lado del otro; en un bloque de NPCs solo el del objetivo, y
        -- entonces ocupa el ancho entero.
        p.anadir:SetText("Anadir el objetivo")
        p.anadir:ClearAllPoints()
        if tostring(entry.kind or "") == "players" then
            local mitad = (p.anchoPanel - 28) / 2
            p.anadir:SetWidth(mitad)
            p.anadir:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 10, 10)
            p.anadirGrupo:SetWidth(mitad)
            p.anadirGrupo:ClearAllPoints()
            p.anadirGrupo:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -10, 10)
            p.anadirGrupo:Show()
        else
            p.anadir:SetWidth(p.anchoPanel - 24)
            p.anadir:SetPoint("BOTTOM", p, "BOTTOM", 0, 10)
            p.anadirGrupo:Hide()
        end
        p.anadir:Show()

        for i, f in ipairs(tarjetas) do
            if not f.quitar then
                f.quitar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
                f.quitar:SetSize(20, 20)
                f.quitar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
                f.quitar:SetFrameLevel(f.border:GetFrameLevel() + 1)
            end
            local m = f.miembro
            f.quitar:SetShown(i <= (cuantas or 0) and m ~= nil)
            if m then
                f.quitar:SetScript("OnClick", function()
                    API().RemoveBlockMember(bloqueActual, m.guid)
                    API().RefreshBlockPanel()
                end)
            end
        end
    end

    HarfordAdminTurnsDecorarBloque = Decorar
end

-- ─── ENGANCHE ────────────────────────────────────────────────────────────────
do
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_LOGIN")
    ev:SetScript("OnEvent", function()
        local T = API()
        if not T then return end
        T.OnCardRightClick = AbrirMenu
        -- La edicion de la lista de un bloque: sin Admin, la lista sigue abriendose de lectura.
        if T.RegisterBlockPanelDecorator and HarfordAdminTurnsDecorarBloque then
            T.RegisterBlockPanelDecorator(HarfordAdminTurnsDecorarBloque)
        end
        -- Click IZQUIERDO sobre un bloque: su lista de miembros. Sobre una criatura no se toca --
        -- ahi el core abre su ficha, que es lo util.
        if T.RegisterOnCardLeftClick then
            T.RegisterOnCardLeftClick(function(entry)
                local k = tostring(entry and entry.kind or "")
                if k ~= "players" and k ~= "generic" then return false end
                API().OpenBlockPanel(entry)
                return true
            end)
        end
    end)
end
