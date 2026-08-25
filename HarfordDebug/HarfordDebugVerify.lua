------------------------------------------------------------
-- HarfordDebugVerify - Bateria de verificacion EN JUEGO.
--
-- Las suites de `tools/pruebas` corren fuera de WoW y solo ven el codigo: comprueban que la logica
-- dice lo que debe decir. Lo que no pueden ver es el cliente -- si un icono existe de verdad, si un
-- frame se ancla donde toca, si un estado llega al cliente de otro jugador. Eso solo se comprueba
-- aqui dentro, y hasta ahora se comprobaba a ojo.
--
-- Cada verificacion cae en una de tres:
--   OK       la comprobo el cliente y pasa.
--   FALLA    la comprobo el cliente y no pasa. Es un fallo real, no una advertencia.
--   MANUAL   el cliente NO puede comprobarla solo (hace falta otro jugador, o mirar la pantalla).
--            Se imprime QUE hacer y QUE tiene que pasar. Nunca se cuenta como aprobada: una
--            verificacion que se da por buena sin mirarla es peor que no tenerla.
--
-- Uso: /harford debug run verificar          -- todos los grupos
--      /harford debug run verificar iconos   -- un grupo suelto
------------------------------------------------------------

local API = HarfordDebug
if not API then return end

local Print = API.Print

local GRUPOS = {}         -- nombre -> funcion(reg)
local ORDEN_GRUPOS = {}

local function Grupo(nombre, fn)
    GRUPOS[nombre] = fn
    ORDEN_GRUPOS[#ORDEN_GRUPOS + 1] = nombre
end

-- Registrador que se pasa a cada grupo. Acumula en vez de imprimir para poder dar primero el
-- resumen y luego solo lo que falla: una pared de cien lineas verdes no se lee.
local function NuevoRegistro()
    local r = { ok = 0, fallos = {}, manuales = {} }
    function r.chk(texto, condicion, detalle)
        if condicion then r.ok = r.ok + 1
        else r.fallos[#r.fallos + 1] = texto .. (detalle and ("  |cff808080" .. tostring(detalle) .. "|r") or "") end
    end
    function r.manual(texto) r.manuales[#r.manuales + 1] = texto end
    return r
end

------------------------------------------------------------
-- ICONOS. El que no existe sale VERDE en Epsilon, y desde fuera del juego no hay forma de saberlo:
-- los nombres se eligen a ciegas. Esta es la unica comprobacion posible, y es automatica.
------------------------------------------------------------
Grupo("iconos", function(r)
    local cat = _G.HarfordIconCatalog
    if not (cat and cat.features) then
        r.chk("catalogo de iconos disponible", false, "HarfordIconCatalog no cargado")
        return
    end
    if not GetFileIDFromPath then
        r.manual("GetFileIDFromPath no existe en este cliente: los iconos no se pueden verificar.")
        return
    end
    local total, rotos = 0, 0
    for id, icono in pairs(cat.features) do
        local ruta = cat.GetFeatureIcon(id)
        total = total + 1
        if type(ruta) == "string" and not GetFileIDFromPath(ruta) then
            rotos = rotos + 1
            -- Uno a uno: saber CUAL es lo unico que permite arreglarlo.
            r.chk("icono inexistente: " .. tostring(id), false, icono)
        end
    end
    r.chk("los " .. total .. " iconos del catalogo existen", rotos == 0, rotos .. " rotos")

    -- Todo estado sin aura necesita icono propio; el que la tiene usa el del aura.
    local C = _G.HarfordDnDConditions
    if C and C.DEFS and C.GetIcon then
        local sinIcono = {}
        for id, def in pairs(C.DEFS) do
            local ruta = C.GetIcon(id)
            if not ruta or (GetFileIDFromPath and type(ruta) == "string" and not GetFileIDFromPath(ruta)) then
                sinIcono[#sinIcono + 1] = id
            end
        end
        r.chk("todo estado resuelve icono", #sinIcono == 0, table.concat(sinIcono, ", "))
    end
end)

------------------------------------------------------------
-- ESTADOS. Se recorre el ciclo de verdad sobre uno mismo: aplicar, verlo activo, que sus efectos
-- se resuelvan, retirarlo. Solo los que NO llevan aura: aplicar los otros lanzaria comandos de
-- servidor y le pondria quince auras encima al que verifica.
------------------------------------------------------------
Grupo("estados", function(r)
    local C = _G.HarfordDnDConditions
    if not (C and C.DEFS and C.GetActive) then
        r.chk("motor de condiciones disponible", false)
        return
    end

    -- Que TODA definicion sea alcanzable. Es el fallo que estuvo nueve veces apagando condiciones
    -- enteras sin avisar, asi que se comprueba tambien aqui dentro y no solo fuera.
    local enOrden, definidas, invisibles = {}, 0, {}
    for _, id in ipairs(C.ORDER or {}) do enOrden[id] = true end
    for id in pairs(C.DEFS) do
        definidas = definidas + 1
        if not enOrden[id] then invisibles[#invisibles + 1] = id end
    end
    r.chk("las " .. definidas .. " condiciones son recorribles", #invisibles == 0,
        table.concat(invisibles, ", "))

    local probados, fallidos = 0, {}
    for id, def in pairs(C.DEFS) do
        if def.tracking == "state" and not def.auraId then
            local yaEstaba = C.Has and C.Has("player", id)
            if not yaEstaba then
                probados = probados + 1
                local aplicado = C.ApplyOwned and C.ApplyOwned(id, { duration = "manual" })
                local activo = aplicado and C.Has and C.Has("player", id)
                local enLista = false
                if activo then
                    for _, a in ipairs(C.GetActive("player")) do
                        if a.id == id then enLista = true break end
                    end
                end
                if not (aplicado and activo and enLista) then
                    fallidos[#fallidos + 1] = id
                end
                if C.RemoveOwned then C.RemoveOwned(id) end
            end
        end
    end
    r.chk("ciclo aplicar/ver/retirar en " .. probados .. " estados", #fallidos == 0,
        table.concat(fallidos, ", "))

    -- Que resolver el modo de tirada con todos ellos no reviente. Es la ruta que atraviesa cada
    -- tirada del juego: si un efecto mal declarado la rompe, se rompe TODO, no solo su estado.
    if C.ResolveRollMode then
        local ok = pcall(C.ResolveRollMode, "normal", "attack", { actorUnit = "player" })
        local ok2 = pcall(C.ResolveRollMode, "normal", "save", { actorUnit = "player", ability = "Destreza" })
        r.chk("resolver el modo de tirada no falla", ok and ok2)
    end
end)

------------------------------------------------------------
-- ACCIONES BASICAS. Definicion, arte, coste y ruta: las cuatro cosas que hacen falta para que una
-- entrada del Libro haga algo al pulsarla.
------------------------------------------------------------
Grupo("acciones", function(r)
    local A = _G.HarfordDnDActions
    if not (A and A.GetOrdered) then
        r.chk("catalogo de acciones disponible", false)
        return
    end
    local C = _G.HarfordDnDConditions
    for _, def in ipairs(A.GetOrdered()) do
        local ruta = def.selfCondition or def.skillCheck or def.contest or def.helpOther
            or def.throwWeapon or def.readyAction or def.sinEfecto
        r.chk("accion sin forma de resolverse: " .. def.id, ruta ~= nil)
        r.chk("accion sin coste: " .. def.id, def.cast ~= nil)
        local costes = A.CostsFor(def.id, {})
        r.chk("accion sin coste base: " .. def.id, costes and #costes >= 1)
        -- Un estado referido y no definido no da error hasta que alguien pulsa el boton.
        for _, campo in ipairs({ def.selfCondition, def.contest, def.readyAction }) do
            local cid = type(campo) == "table" and (campo.id or campo.onWin or campo.conditionId)
            if cid and C and C.DEFS then
                r.chk("estado inexistente en " .. def.id .. ": " .. tostring(cid), C.DEFS[cid] ~= nil)
            end
        end
        if type(def.helpOther) == "table" then
            for _, op in ipairs(def.helpOther.options or {}) do
                r.chk("estado inexistente en " .. def.id .. ": " .. tostring(op.conditionId),
                    C and C.DEFS and C.DEFS[op.conditionId] ~= nil)
            end
        end
    end
end)

------------------------------------------------------------
-- TIRA DE ESTADOS. Lo unico verificable solo es que se construya y se coloque; que se VEA bien es
-- de mirar la pantalla, y se dice como.
------------------------------------------------------------
Grupo("tira", function(r)
    local UF = _G.HarfordUnitFrames
    r.chk("la tira existe", UF and UF.RefreshConditionStrip ~= nil)
    if not (UF and UF.RefreshConditionStrip) then return end

    if not (UnitExists and UnitExists("target")) then
        r.manual("Sin objetivo: coge uno y repite este grupo para comprobar el anclaje.")
        return
    end
    local C = _G.HarfordDnDConditions
    local prueba = "esquivando"
    local tenia = C and C.Has and C.Has("target", prueba)
    if C and C.ApplyToUnit and not tenia then
        C.ApplyToUnit("target", prueba, { duration = "manual" })
    end
    UF.RefreshConditionStrip("target")
    local tira = _G["HarfordEstadostarget"]
    r.chk("la tira se construye", tira ~= nil)
    if tira then
        r.chk("y se muestra con un estado puesto", tira:IsShown())
        local frame = _G["TargetFrame"]
        if frame and tira:GetBottom() and frame:GetTop() then
            r.chk("y queda POR ENCIMA del unitframe", tira:GetBottom() >= frame:GetTop(),
                string.format("tira=%.0f frame=%.0f", tira:GetBottom(), frame:GetTop()))
        end
    end
    if C and C.RemoveFromUnit and not tenia then C.RemoveFromUnit("target", prueba) end
    r.manual("Mira el objetivo: el icono debe verse encima del retrato, sin tapar sus buffs.")
end)

------------------------------------------------------------
-- RED. Nada de esto se puede verificar en solitario: hace falta otro cliente. Se imprime el guion.
------------------------------------------------------------
Grupo("red", function(r)
    local WR = _G.HarfordDnDWeaponRolls
    r.chk("motor de tiradas enfrentadas cargado", WR and WR.RollContest ~= nil)
    local C = _G.HarfordDnDConditions
    r.chk("ruta de estado a otro jugador cargada", C and C.ApplyToUnit ~= nil)

    r.manual("Con OTRO jugador de objetivo:")
    r.manual("  1. Agarrar -> el debe tirar Atletismo o Acrobacias en SU cliente y salir Agarrado si pierde.")
    r.manual("  2. Empujar -> elige Apartar: NO debe quedar Derribado. Repite con Derribar: si debe.")
    r.manual("  3. Ayudar -> elige prueba: su siguiente prueba sale con ventaja y el estado se le va.")
    r.manual("Con un NPC de objetivo: Agarrar debe resolverse en TU cliente, sin pedirle nada a nadie.")
    r.manual("Preparar: primer clic gasta ACCION, segundo clic gasta REACCION y retira el estado.")
end)

------------------------------------------------------------
-- LIBRO. Que ninguna entrada quede sin arte ni sin categoria, que es lo que la deja muerta al clic.
------------------------------------------------------------
Grupo("libro", function(r)
    local B = _G.HarfordCharacterBook
    local P = _G.HarfordDnDProgression
    if not (B and B.BuildSections and P) then
        r.chk("libro disponible", false)
        return
    end
    local ok, secciones = pcall(B.BuildSections, P.GetData and P.GetData() or nil)
    r.chk("el libro se construye sin error", ok, not ok and tostring(secciones) or nil)
    if not ok then return end
    local n, sinIcono, sinNombre = 0, 0, 0
    for _, sec in ipairs(secciones or {}) do
        for _, it in ipairs(sec.features or {}) do
            n = n + 1
            local f = it.feature or it
            if not (f.icon or f.id) then sinIcono = sinIcono + 1 end
            if not f.name or f.name == "" then sinNombre = sinNombre + 1 end
        end
    end
    r.chk("las " .. n .. " entradas del libro tienen nombre", sinNombre == 0, sinNombre .. " sin nombre")
    r.chk("y todas tienen de donde sacar arte", sinIcono == 0, sinIcono .. " sin icono ni id")
end)

------------------------------------------------------------
-- Ejecucion
------------------------------------------------------------
API.RegisterCommand("verificar", function(args)
    local pedido = tostring(args or ""):match("^%s*(%S*)")
    local lista = {}
    if pedido and pedido ~= "" then
        if not GRUPOS[pedido] then
            Print("grupo desconocido: " .. pedido)
            Print("grupos: " .. table.concat(ORDEN_GRUPOS, ", "))
            return
        end
        lista = { pedido }
    else
        lista = ORDEN_GRUPOS
    end

    local totalOk, totalFallos, totalManuales = 0, 0, 0
    local detalle = {}
    for _, nombre in ipairs(lista) do
        local r = NuevoRegistro()
        -- Un grupo que revienta no puede llevarse por delante a los demas: lo que se esta
        -- verificando es precisamente codigo del que se duda.
        local ok, err = pcall(GRUPOS[nombre], r)
        if not ok then r.fallos[#r.fallos + 1] = "el grupo reviento: " .. tostring(err) end
        totalOk = totalOk + r.ok
        totalFallos = totalFallos + #r.fallos
        totalManuales = totalManuales + #r.manuales
        detalle[#detalle + 1] = { nombre = nombre, r = r }
        Print(string.format("%-10s %s%d ok|r  %s  %s", nombre,
            "|cff00ff00", r.ok,
            #r.fallos > 0 and ("|cffff3333" .. #r.fallos .. " FALLAN|r") or "",
            #r.manuales > 0 and ("|cffffcc00" .. #r.manuales .. " a mano|r") or ""))
    end

    for _, d in ipairs(detalle) do
        if #d.r.fallos > 0 then
            Print("|cffff3333--- " .. d.nombre .. " ---|r")
            for _, f in ipairs(d.r.fallos) do Print("  " .. f) end
        end
    end
    for _, d in ipairs(detalle) do
        if #d.r.manuales > 0 then
            Print("|cffffcc00--- " .. d.nombre .. ": comprobar a mano ---|r")
            for _, m in ipairs(d.r.manuales) do Print("  " .. m) end
        end
    end

    Print(string.format("TOTAL: |cff00ff00%d ok|r, |cffff3333%d fallan|r, |cffffcc00%d a mano|r",
        totalOk, totalFallos, totalManuales))
    if totalManuales > 0 then
        Print("Lo marcado 'a mano' NO esta verificado: el cliente no puede comprobarlo solo.")
    end
end, "bateria de verificacion en juego [iconos|estados|acciones|tira|red|libro]")

------------------------------------------------------------
-- Comandos de apoyo para la sesion de pruebas.
--
-- La bateria comprueba lo que puede sola; estos son para MONTAR la escena de lo que no puede.
------------------------------------------------------------

-- Dispara una accion basica sin abrir el Libro, por la MISMA ruta que el boton: menus de coste y
-- de opcion incluidos. Una via de prueba que no pase por donde pasa el jugador no prueba lo que
-- hay que probar.
API.RegisterCommand("accion", function(args)
    local id = tostring(args or ""):match("^%s*(%S*)")
    local A = _G.HarfordDnDActions
    local P = _G.HarfordCharacterPanel
    if not (A and P and P.RunBasicAction) then Print("acciones o panel no cargados"); return end
    if id == "" then
        local nombres = {}
        for _, def in ipairs(A.GetOrdered()) do
            nombres[#nombres + 1] = def.id .. " (" .. tostring(def.cast) .. ")"
        end
        Print("Uso: accion <id>.  Disponibles:")
        for _, n in ipairs(nombres) do Print("  " .. n) end
        return
    end
    if not A.Get(id) then Print("accion desconocida: " .. id); return end
    Print("ejecutando " .. id .. (UnitExists and UnitExists("target")
        and (" sobre " .. tostring(UnitName("target"))) or " (sin objetivo)"))
    P.RunBasicAction(id)
end, "dispara una accion basica: accion <id>")

-- Aplica o retira un estado al OBJETIVO por la ruta real (`ApplyToUnit`), que es la de red: si el
-- objetivo es jugador, se le pide a su cliente. `conditiontest` solo opera sobre uno mismo, y lo
-- que suele fallar es justo el salto al otro cliente.
API.RegisterCommand("estadoen", function(args)
    local id, op = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")
    local C = _G.HarfordDnDConditions
    if not (C and C.ApplyToUnit) then Print("HarfordDnDConditions no cargado"); return end
    if id == "" then Print("Uso: estadoen <condicion> [quitar]"); return end
    if not (UnitExists and UnitExists("target")) then Print("necesita objetivo"); return end
    local esJugador = UnitIsPlayer and UnitIsPlayer("target")
    local ok, err
    if op:lower() == "quitar" then ok, err = C.RemoveFromUnit("target", id)
    else ok, err = C.ApplyToUnit("target", id, { duration = "manual",
        sourceName = HarfordClassColors and HarfordClassColors.UnitFullName("player") or nil,
        sourceGuid = UnitGUID and UnitGUID("player") or nil }) end
    Print(string.format("%s -> %s (%s): %s", id, tostring(UnitName("target")),
        esJugador and "jugador, va por red" or "NPC, local",
        ok and "|cff00ff00hecho|r" or ("|cffff3333" .. tostring(err) .. "|r")))
    if esJugador and ok then Print("Confirma en el OTRO cliente que le ha llegado.") end
end, "aplica/retira un estado al objetivo: estadoen <condicion> [quitar]")

-- Que cree la tira que tiene que pintar, y donde. Separa "el estado no esta" de "el estado esta
-- pero no se ve", que son dos fallos distintos y se confunden mirando la pantalla.
API.RegisterCommand("tira", function(args)
    local unit = tostring(args or ""):match("^%s*(%S*)")
    if unit ~= "focus" then unit = "target" end
    local C, UF = _G.HarfordDnDConditions, _G.HarfordUnitFrames
    if not (C and UF and UF.RefreshConditionStrip) then Print("no cargado"); return end
    if not (UnitExists and UnitExists(unit)) then Print("no hay " .. unit); return end
    UF.RefreshConditionStrip(unit)
    local activos = C.GetActive(unit)
    Print(unit .. " (" .. tostring(UnitName(unit)) .. "): " .. #activos .. " estados")
    for _, a in ipairs(activos) do
        Print(string.format("  %-22s %-28s n=%s", a.id, tostring(a.definition.label),
            tostring(C.CounterFor and C.CounterFor(a.definition, a.record) or "-")))
    end
    local tira = _G["HarfordEstados" .. unit]
    local frame = _G[(unit == "focus" and "FocusFrame" or "TargetFrame")]
    if not tira then Print("la tira no existe todavia"); return end
    Print(string.format("tira: %s  base=%.0f  frame arriba=%.0f  %s",
        tira:IsShown() and "visible" or "oculta",
        tira:GetBottom() or -1, (frame and frame:GetTop()) or -1,
        (tira:GetBottom() and frame and frame:GetTop() and tira:GetBottom() >= frame:GetTop())
            and "|cff00ff00por encima|r" or "|cffff3333NO esta por encima|r"))
end, "vuelca la tira de estados del objetivo: tira [target|focus]")
