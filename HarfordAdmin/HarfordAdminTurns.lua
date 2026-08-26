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
    if tipo ~= "npc" and tipo ~= "player" then return end

    local T = API()
    menuTarjeta = menuTarjeta or CreateFrame("Frame", "HarfordAdminTurnsMenu", UIParent,
        "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(menuTarjeta, function(_, level)
        local titulo = UIDropDownMenu_CreateInfo()
        titulo.isTitle, titulo.notCheckable = true, true
        titulo.text = tostring(entry.name or "?")
        UIDropDownMenu_AddButton(titulo, level)

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
        -- El boton necesita la ventana, que se crea al abrirla por primera vez. Se intenta ahora y
        -- se reintenta al abrirse: sin ticker, solo dos oportunidades reales.
        MontarBotonModo()
        if T.RegisterOnFrameCreated then T.RegisterOnFrameCreated(MontarBotonModo) end
    end)
end
