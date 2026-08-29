-- Acciones basicas, rituales, reservas de curacion y prompts de cantidad del panel de
-- personaje, extraidos de HarfordCharacterPanel.lua (fase C de refactorizacion).
--
-- Igual que HarfordDnDActionPanel: no puede construirse al cargar (los popups y menus
-- necesitan helpers del panel), asi que expone Build(D), que el panel llama donde vivian
-- los bloques, y devuelve las cinco funciones que antes eran locales suyos. Las
-- dependencias de funcion llegan como CLOSURES de late-binding: varias (AnnounceAbility,
-- RefreshBook) se asignan en el panel DESPUES de este punto y capturarlas por valor las
-- dejaria a nil.

HarfordCharacterBookActions = HarfordCharacterBookActions or {}

function HarfordCharacterBookActions.Build(D)
    -- El global ya existe cuando el panel llama a Build (es quien lo crea); la forma
    -- `local API = HarfordCharacterPanel` es ademas la que el comprobador de referencias
    -- del despliegue sabe resolver como alias de modulo.
    local API = HarfordCharacterPanel or D.API
    local Print = D.Print
    local AnnounceAbility = D.AnnounceAbility
    local RefreshBook = D.RefreshBook
    local RefreshGameUI = D.RefreshGameUI
    local SpendPowerWord = D.SpendPowerWord
    local GetProgression = D.GetProgression
    local ClassLevelOf = D.ClassLevelOf
    local EntregarAObjetivo = D.EntregarAObjetivo
    local ObjetivoDeApoyoValido = D.ObjetivoDeApoyoValido
    local GetFeatureUseState = D.GetFeatureUseState
    local FeatureUseAvailable = D.FeatureUseAvailable
    local GetProfileName = D.GetProfileName
    local IsInspecting = D.IsInspecting
    local WarnFeatureWithoutUses = D.WarnFeatureWithoutUses
    local K = D.K
    local S = D.S
    local FeatureReactionTrigger = D.FeatureReactionTrigger
    local FeatureReactionEffect = D.FeatureReactionEffect
    local GetPowerWordOptionById = D.GetPowerWordOptionById
    local PowerWordDisplayFeature = D.PowerWordDisplayFeature
    local ResolveBookFeatureById = D.ResolveBookFeatureById
    local AbrirAccionBasica, AbrirRitualDeRasgo, UsarReservaDeCuracion
    local OpenLayOnHandsPrompt, OpenDemonicFirePrompt

do
    local menu, pendiente
    local menuOpc, pendienteOpc

    -- Todo lo del personaje que abre costes alternativos por su `grantsAsBonus`: sus rasgos
    -- permanentes y las condiciones que lleva puestas ahora mismo. Gracia de Elune abre las
    -- mismas tres acciones que la Accion Astuta, pero solo mientras dura, asi que tiene que
    -- entrar y salir de esta lista sola.
    local function RasgosQueAbren()
        local fuera = {}
        if HarfordDnDConditions and HarfordDnDConditions.GetActive then
            for _, activo in ipairs(HarfordDnDConditions.GetActive("player")) do
                if type(activo.definition.grantsAsBonus) == "table" then
                    fuera[#fuera + 1] = activo.definition
                end
            end
        end
        local secciones = (HarfordCharacterBook and HarfordCharacterBook.BuildSections
            and HarfordCharacterBook.BuildSections(GetProgression())) or {}
        for _, seccion in ipairs(secciones) do
            for _, it in ipairs(seccion.features or {}) do
                if it.feature and type(it.feature.grantsAsBonus) == "table" then
                    fuera[#fuera + 1] = it.feature
                end
            end
        end
        return fuera
    end

    -- Varias acciones se declaran ANTES de resolverse: Empujar (derribar o apartar), Ayudar (en
    -- una prueba o en un ataque) y Lanzar arma (con que mano). Es el mismo gesto en las tres, asi
    -- que el menu es uno solo: `opciones` es una lista de { label, ... } y se vuelve a llamar al
    -- mismo ejecutor con la elegida. Devuelve true si abrio menu, es decir, si aun no toca actuar.
    local function Elegir(opciones, def, ejecutor, yaElegida)
        if yaElegida or type(opciones) ~= "table" or #opciones == 0 then return false end
        -- Una sola opcion no es una eleccion: preguntar seria un clic de mas.
        if #opciones == 1 then ejecutor(def, opciones[1]); return true end
        if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then return false end
        menuOpc = menuOpc or CreateFrame("Frame", "HarfordAccionOpcionMenu", UIParent, "UIDropDownMenuTemplate")
        pendienteOpc = def
        UIDropDownMenu_Initialize(menuOpc, function()
            for _, opcion in ipairs(opciones) do
                local esta = opcion
                local info = UIDropDownMenu_CreateInfo()
                info.text = esta.label
                info.notCheckable = true
                info.func = function()
                    CloseDropDownMenus()
                    ejecutor(pendienteOpc, esta)
                end
                UIDropDownMenu_AddButton(info)
            end
        end, "MENU")
        ToggleDropDownMenu(1, nil, menuOpc, "cursor", 0, 0)
        return true
    end

    -- AYUDAR. El estado va sobre el ALIADO, no sobre quien ayuda, asi que sale por `ApplyToUnit`,
    -- que ya sabe pedirselo a su cliente si es jugador. La ventaja se gasta en su primera tirada
    -- del tipo elegido (`consumeAfterRoll`), que es exactamente lo que dice el manual.
    local function Ayudar(def, elegida)
        if Elegir(def.helpOther.options, def, Ayudar, elegida) then return true end
        -- `Elegir` tambien devuelve false por su guardia de "sin API de desplegable", y ahi
        -- `elegida` sigue nil. Se cae a la primera opcion, como hace `LanzarArma`.
        elegida = elegida or (def.helpOther.options and def.helpOther.options[1])
        if not elegida then
            HarfordChat.Print("Ayudar no tiene ninguna opcion declarada.")
            return false
        end
        if not (UnitExists and UnitExists("target")) then
            HarfordChat.Print("Ayudar necesita un objetivo.")
            return false
        end
        if not (HarfordDnDConditions and HarfordDnDConditions.ApplyToUnit) then return false end
        local ok, err = HarfordDnDConditions.ApplyToUnit("target", elegida.conditionId, {
            duration = "source_turn_start",
            sourceName = HarfordClassColors.UnitFullName("player"),
            sourceGuid = UnitGUID and UnitGUID("player") or nil,
        })
        if not ok then HarfordChat.Print("Ayudar: " .. tostring(err or "no se pudo")) end
        return ok and true or false
    end

    -- LANZAR ARMA. Se ofrece la mano que lleva ARMA: un escudo no se lanza. El ataque sale por la
    -- ruta normal, asi que trae consigo la CA del objetivo, el critico y la mitigacion del
    -- defensor en vez de reimplementar nada de eso.
    local function LanzarArma(def, elegida)
        local items = _G.HarfordDnDItems
        if not (items and items.GetEquippedWeapon and HarfordDnDStore and HarfordDnDStore.AttackWithBlock) then
            HarfordChat.Print("El equipo no esta disponible.")
            return false
        end
        if not elegida then
            local opciones = {}
            for _, slot in ipairs(def.throwWeapon.slots) do
                local arma = items.GetEquippedWeapon(slot)
                if arma then
                    opciones[#opciones + 1] = {
                        label = (slot == "MainHand" and "Mano principal" or "Mano secundaria")
                            .. "  |cff808080" .. tostring(arma.key or arma.name or "") .. "|r",
                        slot = slot,
                    }
                end
            end
            if #opciones == 0 then
                HarfordChat.Print("No llevas ningun arma que lanzar.")
                return false
            end
            if Elegir(opciones, def, LanzarArma, nil) then return true end
            elegida = opciones[1]
        end
        local arma = items.GetEquippedWeapon(elegida.slot)
        if not arma then return false end
        -- `suppressAbilityDamage = false`: un arma lanzada suma tu modificador, como cualquier otro
        -- ataque con arma. El valor por defecto es para ataques de bloque y acompanantes.
        HarfordDnDStore.AttackWithBlock(arma, { suppressAbilityDamage = false })
        return true
    end

    -- PREPARAR. No concede nada: gasta la accion ahora y deja la reaccion comprometida. El segundo
    -- clic, con el estado ya puesto, la DISPARA y cobra la reaccion. El disparador lo reconoce la
    -- mesa; el cliente solo lleva la cuenta de que hay algo preparado y de lo que cuesta soltarlo.
    local function Preparar(def)
        local C = HarfordDnDConditions
        if not (C and C.ApplyOwned) then return false end
        local spec = def.readyAction
        -- El anuncio (y el cobro de la reaccion) ya lo hizo el ejecutor, que necesita saber si se
        -- esta preparando o disparando ANTES de anunciar. Aqui solo se retira el estado.
        if C.Has and C.Has("player", spec.conditionId) then
            if C.RemoveOwned then C.RemoveOwned(spec.conditionId) end
            if C.PublishOwnedCondition then C.PublishOwnedCondition(spec.conditionId, "remove") end
            return true
        end
        C.ApplyOwned(spec.conditionId, {
            duration = spec.duration,
            sourceName = HarfordClassColors.UnitFullName("player"),
        })
        if C.PublishOwnedCondition then C.PublishOwnedCondition(spec.conditionId, "apply") end
        return true
    end

    -- TIRADA ENFRENTADA (Agarrar, Empujar). La dificultad no es fija: la pone el atacante con su
    -- propia tirada, y el defensor responde con la mejor de las habilidades que se le ofrecen.
    --
    -- Empujar deja elegir entre derribar y apartar, y se pregunta ANTES de tirar porque es cuando
    -- lo decide el manual: se declara la intencion y despues se ve si sale. Apartar no deja estado
    -- -- mueve, y el movimiento se lleva en mesa --, asi que su opcion trae `conditionId = false`.
    local function Contienda(def, elegida)
        local contest = def.contest
        local rolls = _G.HarfordDnDWeaponRolls
        if not (rolls and rolls.RollContest) then
            HarfordChat.Print("El motor de tiradas enfrentadas no esta disponible.")
            return false
        end
        if Elegir(contest.options, def, Contienda, elegida) then return true end
        local ok, err = rolls.RollContest(contest,
            elegida and { conditionId = elegida.conditionId } or nil)
        if not ok then HarfordChat.Print(tostring(def.name) .. ": " .. tostring(err)) end
        return ok
    end

    local function Ejecutar(def, coste)
        -- El recurso lo pide el RASGO que abre el coste (el chi de Paso del Viento), no la accion.
        if coste.resourceKey and (tonumber(coste.resourceCost) or 0) > 0 then
            local ok, err = SpendPowerWord({ resourceKey = coste.resourceKey, resourceCost = coste.resourceCost })
            if not ok then HarfordChat.Print(err); return false end
        end
        -- Disparar una accion YA preparada cuesta la reaccion, no otra accion: la accion se pago
        -- al prepararla. Hay que saberlo ANTES de anunciar, porque el anuncio es lo que la
        -- economia de turno mira para cobrar.
        local disparando = type(def.readyAction) == "table" and HarfordDnDConditions
            and HarfordDnDConditions.Has
            and HarfordDnDConditions.Has("player", def.readyAction.conditionId)

        -- Se anuncia con el coste ELEGIDO: es lo que la economia de turno mira para cobrarlo.
        local anuncio = {
            id = "harford_accion_" .. def.id, name = def.name, icon = def.icon,
            description = def.description, cast = disparando and "reaccion" or coste.cast,
        }
        if disparando then
            anuncio.name = "Accion preparada"
            anuncio.description = "Se dispara la accion preparada."
        elseif coste.porRasgo then
            anuncio.name = def.name .. " (" .. tostring(coste.porRasgo) .. ")"
        end
        -- UNA linea por accion. Si la accion va a tirar, la tirada YA lleva su nombre delante
        -- ("Esconderse: Sigilo"), asi que anunciarla aparte son dos lineas para decir lo mismo.
        -- Se cobra igual --el coste no depende de cuantas lineas salgan-- pero sin difundir.
        local vaATirar = type(def.skillCheck) == "table" and _G.DND5E_ARC_API
            and _G.DND5E_ARC_API.RollSkillEx and type(def.selfCondition) ~= "table"
        -- Si no cabe el coste, la accion NO ocurre: ni tirada, ni estado, ni nada.
        if AnnounceAbility(anuncio, { silencioso = vaATirar }) == false then return false end

        if type(def.selfCondition) == "table" and HarfordDnDConditions
            and HarfordDnDConditions.ApplyOwned then
            HarfordDnDConditions.ApplyOwned(def.selfCondition.id, {
                duration = def.selfCondition.duration, turns = def.selfCondition.turns,
                sourceName = HarfordClassColors.UnitFullName("player"),
            })
        elseif type(def.skillCheck) == "table" and _G.DND5E_ARC_API
            and _G.DND5E_ARC_API.RollSkillEx then
            -- Se tira con `RollSkillEx` y no con `RollSkill` porque hace falta el TOTAL para
            -- compararlo con la CD. Estabilizar la tiene fija en el manual (Medicina 10);
            -- Esconderse no, porque la suya es la Percepcion pasiva de quien mira y este cliente
            -- no la conoce: ahi se tira y decide la mesa.
            local resultado = _G.DND5E_ARC_API.RollSkillEx(def.skillCheck.skill, def.name)
            local dc = tonumber(def.skillCheck.dc)
            if dc and resultado and tonumber(resultado.total) then
                local supera = tonumber(resultado.total) >= dc
                local C = (HarfordDnDRolls and HarfordDnDRolls.COLORS) or {}
                HarfordDnDRolls.Broadcast({
                    type = "info",
                    label = string.format("%s vs CD %d: %s%s%s", tostring(def.name), dc,
                        supera and (C.crit or "") or (C.fumble or ""),
                        supera and "EXITO" or "FALLO", C.close or ""),
                })
            end
        elseif type(def.contest) == "table" then
            Contienda(def)
        elseif type(def.helpOther) == "table" then
            Ayudar(def)
        elseif type(def.throwWeapon) == "table" then
            LanzarArma(def)
        elseif type(def.readyAction) == "table" then
            Preparar(def)
        elseif def.dobleMovimiento then
            -- `Correr` dobla el tope del contador hasta que empiece tu siguiente turno. Antes la
            -- accion existia y solo decia que el movimiento "se lleva en mesa".
            if HarfordDnDAttackUI and HarfordDnDAttackUI.SetDashActive then
                HarfordDnDAttackUI.SetDashActive(true)
            end
        elseif def.sinEfecto then
            HarfordChat.Print("|cff808080" .. tostring(def.sinEfecto) .. "|r")
        end
        if RefreshGameUI then RefreshGameUI() end
        if RefreshBook then RefreshBook() end
        return true
    end

    AbrirAccionBasica = function(actionId, anchor)
        local cat = _G.HarfordDnDActions
        local def = cat and cat.Get and cat.Get(actionId)
        if not def then return false end
        local costes = cat.CostsFor(actionId, RasgosQueAbren())
        if #costes <= 1 then return Ejecutar(def, costes[1] or { cast = def.cast }) end

        if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then
            return Ejecutar(def, costes[1])
        end
        menu = menu or CreateFrame("Frame", "HarfordAccionBasicaMenu", UIParent, "UIDropDownMenuTemplate")
        pendiente = { def = def, costes = costes }
        UIDropDownMenu_Initialize(menu, function()
            for _, coste in ipairs(pendiente.costes) do
                local elegido = coste
                local info = UIDropDownMenu_CreateInfo()
                info.text = (elegido.cast == "accion_adicional" and "Accion adicional" or "Accion")
                    .. (elegido.porRasgo and ("  |cff808080" .. elegido.porRasgo .. "|r") or "")
                    .. (elegido.resourceKey and (elegido.resourceCost or 0) > 0
                        and ("  |cff808080-" .. tostring(elegido.resourceCost) .. "|r") or "")
                info.notCheckable = true
                info.func = function()
                    CloseDropDownMenus()
                    Ejecutar(pendiente.def, elegido)
                end
                UIDropDownMenu_AddButton(info)
            end
        end, "MENU")
        ToggleDropDownMenu(1, nil, menu, anchor or "cursor", 0, 0)
        return true
    end
end

do
    local menu
    AbrirRitualDeRasgo = function(feature, anchor)
        local spec = feature.ritualCast
        local api = _G.HarfordCompendioAPI
        if not (api and api.GetAllSpells and api.ResolveCast) then
            HarfordChat.Print("El compendio de conjuros no esta disponible.")
            return false
        end
        local clase = tostring(spec.className or "")
        local nivelClase = ClassLevelOf(spec.classId)
        local maximo = api.GetMaxSpellLevel and api.GetMaxSpellLevel(clase, nivelClase) or 9

        local elegibles = {}
        for _, s in ipairs(api.GetAllSpells() or {}) do
            if s.ritual == true and (tonumber(s.level) or 0) <= maximo then
                for _, c in ipairs(s.classes or {}) do
                    if tostring(c):find(clase, 1, true) then
                        elegibles[#elegibles + 1] = s
                        break
                    end
                end
            end
        end
        table.sort(elegibles, function(a, b)
            local la, lb = tonumber(a.level) or 0, tonumber(b.level) or 0
            if la ~= lb then return la < lb end
            return tostring(a.name) < tostring(b.name)
        end)
        if #elegibles == 0 then
            HarfordChat.Print("No tienes ningun conjuro de ritual que puedas lanzar todavia.")
            return false
        end

        if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then return false end
        menu = menu or CreateFrame("Frame", "HarfordRitualMenu", UIParent, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(menu, function()
            for _, s in ipairs(elegibles) do
                local conjuro = s
                local info = UIDropDownMenu_CreateInfo()
                info.text = string.format("%s  |cff808080(nivel %d)|r", tostring(conjuro.name),
                    tonumber(conjuro.level) or 0)
                info.notCheckable = true
                info.func = function()
                    CloseDropDownMenus()
                    local ok, err = SpendPowerWord(feature)   -- el rasgo declara su propio recurso
                    if not ok then HarfordChat.Print(err); return end
                    -- `ritual` para que no gaste espacio, `free` porque lo pagas con el recurso.
                    local lanzado, castErr = api.ResolveCast(conjuro.id, { ritual = true, free = true })
                    if not lanzado then
                        local key = tostring(feature.resourceKey or "")
                        local cost = tonumber(feature.resourceCost) or 0
                        if key ~= "" and cost > 0 and HarfordDnDStore.AdjustResourceCurrent then
                            HarfordDnDStore.AdjustResourceCurrent(key, cost)
                        end
                        HarfordChat.Print(tostring(castErr or "No se pudo lanzar el ritual."))
                        return
                    end
                    AnnounceAbility(feature)
                    if RefreshGameUI then RefreshGameUI() end
                    if RefreshBook then RefreshBook() end
                end
                UIDropDownMenu_AddButton(info)
            end
        end, "MENU")
        ToggleDropDownMenu(1, nil, menu, anchor or "cursor", 0, 0)
        return true
    end
end

-- RESERVA DE CURACION (Monje, Niebla Calmante). Se distingue de una concesion normal en que la
-- cantidad NO esta declarada: el manual dice "hasta el maximo que quede en tu reservorio", asi que
-- la elige el jugador. Los escalones del menu son atajos; el tope real es lo que quede.
--
-- Lo que el cliente NO puede comprobar y por eso no se finge: el manual dice que no funciona sobre
-- muertos vivientes ni constructos. Eso lo sabe la mesa, no el addon.
do
    local menuReserva, reservaPendiente

    local function GastarReserva(feature, cantidad, esCura)
        local spec = feature.poolHeal
        local nombre = tostring(spec.noun or "curacion")
        if not ObjetivoDeApoyoValido(nombre, feature.name) then return false end

        local queda = math.max(0, math.floor(tonumber(
            HarfordDnDStore.GetResourceCurrent and HarfordDnDStore.GetResourceCurrent(spec.resource) or 0) or 0))
        cantidad = math.min(math.max(1, math.floor(tonumber(cantidad) or 0)), queda)
        if cantidad <= 0 then
            HarfordChat.Print("No queda nada en la reserva de " .. nombre .. ".")
            return false
        end

        -- Se gasta ANTES de entregar y se devuelve si la entrega falla, igual que la Fe.
        HarfordDnDStore.AdjustResourceCurrent(spec.resource, -cantidad)
        -- Curar enfermedad o veneno gasta de la reserva pero NO da puntos de golpe: son dos usos
        -- distintos de la misma reserva, y sumar vida ademas seria regalar los dos.
        if not esCura then
            if not EntregarAObjetivo("health", cantidad, nombre) then
                HarfordDnDStore.AdjustResourceCurrent(spec.resource, cantidad)
                return false
            end
        end

        AnnounceAbility({
            id = feature.id, name = feature.name, icon = feature.icon, cast = feature.cast,
            description = esCura
                and ("Gasta " .. cantidad .. " de la reserva para curar una enfermedad o neutralizar un veneno.")
                or ("Restaura " .. cantidad .. " puntos de golpe."),
        })
        if RefreshGameUI then RefreshGameUI() end
        if RefreshBook then RefreshBook() end
        return true
    end

    UsarReservaDeCuracion = function(feature, anchor)
        local spec = feature.poolHeal
        if not (spec and HarfordDnDStore and HarfordDnDStore.GetResourceCurrent) then return false end
        local queda = math.max(0, math.floor(tonumber(HarfordDnDStore.GetResourceCurrent(spec.resource)) or 0))
        if queda <= 0 then
            HarfordChat.Print("No queda nada en la reserva de " .. tostring(spec.noun or "curacion") .. ".")
            return false
        end
        if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then
            return GastarReserva(feature, queda, false)
        end
        menuReserva = menuReserva or CreateFrame("Frame", "HarfordReservaCuracionMenu", UIParent,
            "UIDropDownMenuTemplate")
        reservaPendiente = feature
        UIDropDownMenu_Initialize(menuReserva, function()
            local puestos = {}
            for _, paso in ipairs(spec.steps or {}) do
                -- Solo lo que se puede pagar, y sin repetir el "todo lo que queda" de abajo.
                if paso < queda and not puestos[paso] then
                    puestos[paso] = true
                    local cantidad = paso
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = "Curar " .. cantidad
                    info.notCheckable = true
                    info.func = function()
                        CloseDropDownMenus()
                        GastarReserva(reservaPendiente, cantidad, false)
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end
            local todo = UIDropDownMenu_CreateInfo()
            todo.text = "Curar todo lo que queda (" .. queda .. ")"
            todo.notCheckable = true
            todo.func = function()
                CloseDropDownMenus()
                GastarReserva(reservaPendiente, queda, false)
            end
            UIDropDownMenu_AddButton(todo)
            local cura = spec.cure
            if type(cura) == "table" and queda >= (tonumber(cura.amount) or 5) then
                local info = UIDropDownMenu_CreateInfo()
                info.text = tostring(cura.label or "Curar enfermedad o veneno")
                    .. "  |cff808080-" .. tostring(cura.amount) .. "|r"
                info.notCheckable = true
                info.func = function()
                    CloseDropDownMenus()
                    GastarReserva(reservaPendiente, cura.amount, true)
                end
                UIDropDownMenu_AddButton(info)
            end
        end, "MENU")
        ToggleDropDownMenu(1, nil, menuReserva, anchor or "cursor", 0, 0)
        return true
    end
end

-- Imposicion de Manos usa una reserva de PG, no una barra de recursos. El prompt captura
-- una cantidad concreta y delega la curacion al motor comun de jugadores/NPCs.
do
    -- Cuadro UNICO de "elige una cantidad". Lo comparten Imposicion de Manos (curar) y Canalizar
    -- fuego demoniaco (danar): eran dos popups identicos salvo el texto del boton. Lo que cambia
    -- va en `data`: el rango, la etiqueta y que hacer con la cantidad.
    StaticPopupDialogs["HARFORD_AMOUNT_PROMPT"] = {
        text = "%s",
        button1 = "Aceptar",
        button2 = "Cancelar",
        hasEditBox = true,
        maxLetters = 5,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        OnShow = function(self)
            local data = self.data or {}
            if self.button1 and data.acceptText then self.button1:SetText(data.acceptText) end
            self.editBox:SetText(tostring(data.defaultAmount or 1))
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local data = self.data
            if data and type(data.confirm) == "function" then data.confirm(self.editBox:GetText()) end
        end,
        EditBoxOnEnterPressed = function(editBox)
            local popup = editBox:GetParent()
            if popup and popup.button1 then popup.button1:Click() end
        end,
    }

    -- Pide una cantidad entre 1 y `max` y llama a `apply(cantidad)`. Valida el rango y que el
    -- objetivo no haya cambiado entre la pregunta y la respuesta.
    local function OpenAmountPrompt(opts)
        if IsInspecting() then return end
        if not (UnitExists and UnitExists("target")) then
            HarfordChat.Print(tostring(opts.title or "Esta habilidad") .. " requiere un objetivo.")
            return
        end
        local max = math.floor(tonumber(opts.max) or 0)
        if max < 1 then
            HarfordChat.Print(tostring(opts.emptyText or "No queda reserva disponible."))
            return
        end
        local targetGuid = UnitGUID and UnitGUID("target") or ""
        local texto = tostring(opts.title or "") .. "\n"
            .. tostring(opts.subtitle or "") .. "\n"
            .. tostring(opts.prompt or "Cantidad") .. " (1-" .. tostring(max) .. "):"
        StaticPopup_Show("HARFORD_AMOUNT_PROMPT", texto, nil, {
            defaultAmount = max,
            acceptText = opts.acceptText,
            confirm = function(bruto)
                local cantidad = math.floor(tonumber(bruto) or 0)
                if cantidad < 1 or cantidad > max then
                    HarfordChat.Print("Introduce una cantidad entre 1 y " .. tostring(max) .. ".")
                    return
                end
                if not (UnitExists and UnitExists("target"))
                    or (targetGuid ~= "" and UnitGUID("target") ~= targetGuid) then
                    HarfordChat.Print("El objetivo ha cambiado.")
                    return
                end
                opts.apply(cantidad, targetGuid)
            end,
        })
    end

    -- Canalizar fuego demoniaco: recibes N de fuego (hasta tu nivel de brujo) y el objetivo el DOBLE.
    OpenDemonicFirePrompt = function(feature)
        local nivel = 0
        for _, entry in ipairs((HarfordDnDProgression and HarfordDnDProgression.GetClassLevels
            and HarfordDnDProgression.GetClassLevels(GetProfileName())) or {}) do
            if entry.classId == "brujo" then nivel = tonumber(entry.level) or 0 break end
        end
        OpenAmountPrompt({
            title = tostring(feature.name or "Canalizar fuego demoniaco"),
            subtitle = "Recibes dano por fuego y el objetivo recibe el doble.",
            prompt = "Cantidad que RECIBES",
            acceptText = "Canalizar",
            max = nivel,
            emptyText = "Necesitas niveles de Brujo para canalizar fuego demoniaco.",
            apply = function(propio)
                if not AnnounceAbility(feature) then return end
                -- El dano propio no se mitiga: es el coste que paga el brujo.
                if HarfordDnDStore and HarfordDnDStore.AdjustResourceCurrent then
                    HarfordDnDStore.AdjustResourceCurrent("health", -propio)
                end
                local objetivo, marca = propio * 2, ""
                if HarfordDamageMitigation and HarfordDamageMitigation.ForTarget then
                    local aplicado, _estado, mk = HarfordDamageMitigation.ForTarget("target", "fuego", propio * 2)
                    objetivo, marca = aplicado, mk or ""
                end
                if HarfordDnDCombat and HarfordDnDCombat.ApplyWeaponDamageToTarget then
                    HarfordDnDCombat.ApplyWeaponDamageToTarget(
                        HarfordDnDCombat.PayloadFor("target", objetivo, "fuego"), false)
                end
                if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
                    HarfordDnDRolls.Broadcast({
                        type = "damage", targetUnit = "target",
                        label = tostring(feature.name or "Canalizar fuego demoniaco"),
                        total = objetivo, dice = "recibes " .. tostring(propio),
                        modifiers = "Fuego" .. (marca ~= "" and (" " .. marca) or ""),
                        critical = "", mode = "",
                    })
                end
                if RefreshBook then RefreshBook() end
            end,
        })
    end

    -- Imposicion de Manos: reserva de PG de la que gastas la cantidad que quieras.
    OpenLayOnHandsPrompt = function(feature)
        local tracked = GetFeatureUseState(feature)
        local available = math.max(0, tonumber(tracked and tracked.available) or 0)
        local maximum = math.max(0, tonumber(tracked and tracked.max) or 0)
        if available <= 0 then WarnFeatureWithoutUses(feature); return end
        local targetName = HarfordClassColors.UnitFullName("target")
        OpenAmountPrompt({
            title = "Imposicion de Manos",
            subtitle = "Reserva disponible: " .. tostring(available) .. "/" .. tostring(maximum)
                .. "   Objetivo: " .. tostring(targetName ~= "" and targetName or "objetivo"),
            prompt = "Cantidad a curar",
            acceptText = "Curar",
            max = available,
            -- NO pasa por el motor de areas. Se enrutaba por el como "area de forma otra, tamano
            -- Objetivo" para reusar su entrega, y eso arrastraba toda su presentacion: la linea
            -- salia con "(Area Objetivo)" y con un EXITO de una tirada que aqui no existe --
            -- Imposicion de manos no tira nada, tocas y curas.
            --
            -- Entrega directa, como la reserva de curacion del Monje, y UNA linea.
            apply = function(amount)
                if not ObjetivoDeApoyoValido("curacion", feature.name) then return end
                amount = math.max(1, math.min(math.floor(tonumber(amount) or 0), available))
                -- Se gasta ANTES de entregar y se devuelve si la entrega falla, igual que la Fe.
                if not (HarfordDnDFeatureUses and HarfordDnDFeatureUses.Spend
                    and HarfordDnDFeatureUses.Spend(feature.id, GetProfileName(), amount)) then
                    HarfordChat.Print("No queda reserva suficiente para " .. tostring(feature.name) .. ".")
                    return
                end
                if not EntregarAObjetivo("health", amount, "curacion") then
                    -- `Restore` devuelve UNO. Aqui puede haberse gastado media reserva, asi que se
                    -- descuenta lo gastado a mano o el paladin perderia la diferencia.
                    if HarfordDnDFeatureUses.GetSpent and HarfordDnDFeatureUses.SetSpent then
                        local gastado = HarfordDnDFeatureUses.GetSpent(feature.id, GetProfileName())
                        HarfordDnDFeatureUses.SetSpent(feature.id,
                            math.max(0, gastado - amount), GetProfileName())
                    end
                    return
                end
                -- `ORIGEN [Imposicion de manos] OBJETIVO N curacion`, y nada mas. El nombre de
                -- quien lo hace lo antepone el render de la tirada.
                local link = (HarfordTRP3 and HarfordTRP3.GetAbilityChatLink
                    and HarfordTRP3.GetAbilityChatLink(feature))
                    or ("|cff66ccff[" .. tostring(feature.name) .. "]|r")
                local quien = HarfordClassColors.UnitFullName("target")
                HarfordDnDRolls.Broadcast({
                    type = "info",
                    label = link .. " " .. tostring(quien ~= "" and quien or "objetivo")
                        .. " |cff66ff66" .. amount .. "|r curacion",
                    targetUnit = "target",
                })
                if RefreshGameUI then RefreshGameUI() end
                if RefreshBook then RefreshBook() end
            end,
        })
    end
end

-- COMPETENCIAS E IDIOMAS: un solo sitio donde consultarlo todo.
--
-- Las competencias no se reparten en un rasgo por fuente: raza, clase y trasfondo aportan a la
-- MISMA bolsa, que `HarfordDnDFeatureEffects.GetProficiencies` ya tiene agregada. Cada rasgo de
-- origen sigue mostrando lo suyo -su texto- y aqui se ve el resultado sumado.
--
-- Una seccion vacia NO se pinta: un tooltip con "Herramientas: -" no dice nada.
--
-- Todo va dentro de un `do...end` y solo sale UNA funcion, por la tabla del modulo: este
-- fichero esta en el limite de 200 locales de Lua 5.1 y seis mas lo rompian.
do
-- Solo estas cuatro. Salvaciones y habilidades NO son "competencias" en este sentido: se
-- consultan en la ficha, donde ya salen con su modificador, y repetirlas aqui era ruido.
K.PROF_SECCIONES = {
    { clave = "armor",  titulo = "Armadura" },
    { clave = "weapon", titulo = "Armas" },
    { clave = "tool",   titulo = "Herramientas" },
}

-- Las claves de armadura/arma vienen en minusculas del libro ("ligera", "marciales").
do
    local function ProfEtiqueta(texto)
        texto = tostring(texto or "")
        if texto == "" then return texto end
        return texto:sub(1, 1):upper() .. texto:sub(2)
    end

    -- Las lineas de "Competencias", con su color ya embebido. Fuente UNICA para el tooltip del
    -- libro y para la fila del panel de Atributos: antes eran dos implementaciones y no coincidian.
    -- Una seccion sin contenido no genera linea.
    function API.GetProficiencyLines()
        local FE = HarfordDnDFeatureEffects
        if not FE then return {} end
        local perfil = GetProfileName()
        local lineas = {}
        local function Seccion(titulo, lista)
            if not (lista and #lista > 0) then return end
            local partes = {}
            for i, v in ipairs(lista) do partes[i] = ProfEtiqueta(v) end
            lineas[#lineas + 1] = "- |cffffd100" .. titulo .. ":|r " .. table.concat(partes, ", ")
        end
    Seccion("Armadura", FE.GetArmorProfs and FE.GetArmorProfs(perfil))
    Seccion("Armas", FE.GetWeaponProfs and FE.GetWeaponProfs(perfil))
    -- GetToolProfs incluye las herramientas de las profesiones conocidas; es la lista buena.
    Seccion("Herramientas", FE.GetToolProfs and FE.GetToolProfs(perfil))

    local oficios = {}
    if HarfordProfessions and HarfordProfessions.GetProfessions then
        for _, def in ipairs(HarfordProfessions.GetProfessions() or {}) do
            if HarfordProfessions.KnowsProfession and HarfordProfessions.KnowsProfession(def.id) then
                local rango = HarfordProfessions.GetTierName and HarfordProfessions.EffectiveSkill
                    and HarfordProfessions.GetTierName(HarfordProfessions.EffectiveSkill(def.id))
                oficios[#oficios + 1] = (def.name or def.id) .. (rango and (" (" .. rango .. ")") or "")
            end
        end
    end
    table.sort(oficios)
    if #oficios > 0 then
        lineas[#lineas + 1] = "- |cffffd100Profesiones:|r " .. table.concat(oficios, ", ")
    end
    return lineas
end
end

do
    local function AddProficienciesToTooltip()
        local lineas = API.GetProficiencyLines()
        if #lineas == 0 then
            GameTooltip:AddLine("Sin competencias registradas.", 0.7, 0.7, 0.7, true)
            return true
        end
        for _, l in ipairs(lineas) do
            -- Blanco de base: el color de cada etiqueta ya va dentro de la linea.
            GameTooltip:AddLine(l, 1, 1, 1, true)
        end
        return true
    end

    local function AddLanguagesToTooltip()
        -- GetLanguages ya fusiona los idiomas derivados de los DATOS (raza, trasfondo, clase, dotes
        -- y elecciones) con los importados del About, sin repetir por acentos o mayusculas. Antes
        -- esto leia SOLO el About, asi que un personaje creado con el asistente salia sin idiomas.
        local idiomas = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetLanguages
            and HarfordDnDFeatureEffects.GetLanguages(GetProfileName())) or {}
        if #idiomas == 0 then
            GameTooltip:AddLine("Sin idiomas registrados.", 0.7, 0.7, 0.7, true)
            return true
        end
        table.sort(idiomas)
        -- Con su ORIGEN al lado. Antes cada raza metia ademas una fila suelta `Idioma` en el Libro
        -- solo para decir de donde salia el suyo: una entrada entera por un dato que cabe aqui.
        local origenes = (HarfordDnDFeatureEffects.GetLanguageSources
            and HarfordDnDFeatureEffects.GetLanguageSources(GetProfileName())) or {}
        for _, idioma in ipairs(idiomas) do
            local de = origenes[idioma]
            GameTooltip:AddLine("- " .. idioma
                .. (de and ("  |cff808080" .. tostring(de) .. "|r") or ""), 1, 0.82, 0)
        end
        return true
    end

    -- Se reconoce por NOMBRE y no por id: cada raza declara el suyo (`hum_idiomas`, `ena_idiomas`...).
    -- Los rasgos AGREGADOS (su contenido es un listado, no una regla) se reconocen por nombre.
    function API.IsAggregatedFeature(feature)
        local nombre = tostring(feature and feature.name or "")
        return nombre == "Competencias" or nombre == "Idiomas"
    end

    function API.AddAggregatedFeatureTooltip(feature)
        local nombre = tostring(feature and feature.name or "")
        if nombre == "Competencias" then return AddProficienciesToTooltip() end
        if nombre == "Idiomas" then return AddLanguagesToTooltip() end
        return false
    end
end
end

-- Geometria EXACTA del SpellBookFrame nativo (probe de GRIKER), 1:1. El panel del Libro usa el
-- tamaño nativo (550x525) y TODO se ancla al frame con los offsets literales del probe.
do
    local function RollReactionDice(expr)
        local count, sides = tostring(expr or ""):match("^(%d*)d(%d+)$")
        count = tonumber(count ~= "" and count or "1") or 0
        sides = tonumber(sides) or 0
        if count <= 0 or sides <= 0 then return 0 end

        local total = 0
        for _ = 1, count do
            if HarfordDnDCalc and HarfordDnDCalc.RollDie then
                total = total + HarfordDnDCalc.RollDie(sides)
            else
                total = total + math.random(1, sides)
            end
        end
        return total
    end

    local function ReactionFlatBonus(feature)
        local flat = feature and feature.reactionFlat
        if flat == "half_level" then
            local lvl = HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel(GetProfileName()) or 0
            return math.floor((tonumber(lvl) or 0) / 2)
        end
        return tonumber(flat) or 0
    end

    local function ApplyReactionEffect(feature, damage, context)
        damage = math.max(0, math.floor(tonumber(damage) or 0))
        if damage <= 0 then return damage end

        local effect = FeatureReactionEffect(feature)
        if effect == "half_damage" then
            return math.max(0, math.floor(damage / 2))
        elseif effect == "reduce_damage_roll" then
            local reduction = RollReactionDice(feature.reactionDice) + ReactionFlatBonus(feature)
            return math.max(0, damage - reduction)
        end
        return nil
    end

    function API.TriggerPreparedReaction(trigger, context)
        trigger = tostring(trigger or "")
        context = context or {}
        local damage = tonumber(context.damage) or 0
        if HarfordDnDConditions and HarfordDnDConditions.CanPerform then
            local allowed = HarfordDnDConditions.CanPerform("reaction", { actorUnit = "player" })
            if not allowed then return damage, false end
        end
        if trigger == "" or not (S.activeReactions and next(S.activeReactions)) then
            return damage, false
        end

        for id in pairs(S.activeReactions) do
            local feature = ResolveBookFeatureById(id)
            local prepared = S.activeReactions[id]
            local option = GetPowerWordOptionById(feature, prepared and prepared.optionId)
            local reaction = option or feature
            if feature and FeatureReactionTrigger(reaction) == trigger and FeatureUseAvailable(feature) then
                local resourceKey = tostring(reaction.resourceKey or "")
                local resourceCost = math.max(0, tonumber(reaction.resourceCost) or 0)
                if resourceKey ~= "" and resourceCost > 0 then
                    if not (HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
                        and HarfordDnDStore.AdjustResourceCurrent)
                        or HarfordDnDStore.GetResourceCurrent(resourceKey) < resourceCost then
                        return damage, false
                    end
                    HarfordDnDStore.AdjustResourceCurrent(resourceKey, -resourceCost)
                end
                local newDamage = ApplyReactionEffect(reaction, damage, context)
                if newDamage ~= nil then
                    S.activeReactions[id] = nil
                    AnnounceAbility(option and PowerWordDisplayFeature(feature, option) or feature)
                    if RefreshBook then RefreshBook() end
                    return newDamage, true, feature
                end
            end
        end
        return damage, false
    end

-- Reacciones que deben ocurrir antes de aplicar el resultado del ataque. El
-- cliente defensor decide y paga su propio recurso; el atacante no modifica
-- nunca el estado de reacciones de otra ficha.
function API.TriggerPreparedAttackReaction(trigger, context)
    trigger = tostring(trigger or "")
    context = context or {}
    if trigger == "" or not (S.activeReactions and next(S.activeReactions)) then
        return false
    end
    if HarfordDnDConditions and HarfordDnDConditions.CanPerform then
        local allowed = HarfordDnDConditions.CanPerform("reaction", { actorUnit = "player" })
        if not allowed then return false end
    end

    for id in pairs(S.activeReactions) do
        local feature = ResolveBookFeatureById(id)
        local prepared = S.activeReactions[id]
        local option = GetPowerWordOptionById(feature, prepared and prepared.optionId)
        local reaction = option or feature
        if feature and FeatureReactionTrigger(reaction) == trigger
            and FeatureReactionEffect(reaction) == "reroll_attack" then
            prepared = S.activeReactions[id]
            local protectedGuid = tostring(prepared and prepared.protectedGuid or "")
            local requestedGuid = tostring(context.protectedGuid or "")
            if protectedGuid == "" or (requestedGuid ~= "" and requestedGuid ~= protectedGuid) then
                return false
            end
            local resourceKey = tostring(reaction.resourceKey or "")
            local resourceCost = math.max(0, tonumber(reaction.resourceCost) or 0)
            if resourceKey == "" or resourceCost <= 0
                or not (HarfordDnDStore and HarfordDnDStore.GetResourceCurrent
                    and HarfordDnDStore.AdjustResourceCurrent)
                or HarfordDnDStore.GetResourceCurrent(resourceKey) < resourceCost then
                return false
            end
            S.activeReactions[id] = nil
            if HarfordDnDCombat and HarfordDnDCombat.SetPreparedAttackReaction then
                HarfordDnDCombat.SetPreparedAttackReaction(protectedGuid, nil)
            end
            if HarfordSync and HarfordSync.SendPreparedAttackReaction then
                HarfordSync.SendPreparedAttackReaction("DND5EARC", id, protectedGuid, false)
            end
            HarfordDnDStore.AdjustResourceCurrent(resourceKey, -resourceCost)
            AnnounceAbility(option and PowerWordDisplayFeature(feature, option) or feature)
            if RefreshBook then RefreshBook() end
            return true, feature
        end
    end
    return false
end
end

    return {
        AbrirAccionBasica = AbrirAccionBasica,
        AbrirRitualDeRasgo = AbrirRitualDeRasgo,
        UsarReservaDeCuracion = UsarReservaDeCuracion,
        OpenLayOnHandsPrompt = OpenLayOnHandsPrompt,
        OpenDemonicFirePrompt = OpenDemonicFirePrompt,
    }
end
