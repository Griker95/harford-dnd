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

-- Cada grupo trae su descripcion. Antes la ayuda era una cadena escrita aparte al final del
-- fichero, que se quedaba vieja al anadir un grupo; ahora se genera de aqui y no puede desfasarse.
local DESCRIPCIONES = {}

local function Grupo(nombre, descripcion, fn)
    -- Firma tolerante: si solo llegan dos argumentos, el segundo es la funcion.
    if type(descripcion) == "function" then fn, descripcion = descripcion, nil end
    GRUPOS[nombre] = fn
    DESCRIPCIONES[nombre] = descripcion or ""
    ORDEN_GRUPOS[#ORDEN_GRUPOS + 1] = nombre
end

-- Que hace cada uno, para poder elegir sin salir del juego.
local function ListarGrupos()
    Print("grupos de verificacion:")
    for _, nombre in ipairs(ORDEN_GRUPOS) do
        Print(string.format("  |cff00ccff%-11s|r %s", nombre, DESCRIPCIONES[nombre] or ""))
    end
    Print("uso: /harford debug run verificar [grupo]   ·   sin grupo, los ejecuta todos")
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
Grupo("iconos", "que los iconos existan de verdad (uno inventado sale verde)", function(r)
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
Grupo("estados", "las 48 condiciones: alcanzables, y su ciclo aplicar/ver/retirar", function(r)
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
Grupo("acciones", 'las diez acciones basicas; anade "ejecutar" para dispararlas de verdad', function(r, extra)
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

    -- EJECUTARLAS de verdad es lo unico que demuestra que hacen algo, pero cada una ANUNCIA por
    -- chat, asi que no se hace sola: `verificar acciones ejecutar`. Con gente delante, el ruido
    -- seria peor que la comprobacion.
    if extra ~= "ejecutar" then
        r.manual("Para ejecutarlas de verdad: /harford debug run verificar acciones ejecutar")
        r.manual("  (anuncia cada una por chat; hazlo a solas)")
        return
    end
    local P = _G.HarfordCharacterPanel
    if not (P and P.RunBasicAction and C) then
        r.chk("panel disponible para ejecutar", false)
        return
    end
    -- Solo las que se resuelven sobre UNO MISMO. Las de objetivo tiran dados contra alguien y las
    -- de menu se quedan esperando un clic: eso no se automatiza sin fingir la interaccion, y una
    -- comprobacion que finge la interaccion no comprueba la interaccion.
    local propias = {
        { id = "esquivar", estado = "esquivando" },
        { id = "preparar", estado = "preparado" },
    }
    for _, caso in ipairs(propias) do
        local antes = C.Has and C.Has("player", caso.estado)
        if antes then
            if C.RemoveOwned then C.RemoveOwned(caso.estado) end
        end
        local ok = pcall(P.RunBasicAction, caso.id)
        r.chk(caso.id .. " se ejecuta sin reventar", ok)
        r.chk(caso.id .. " deja su estado", C.Has and C.Has("player", caso.estado) == true,
            "esperaba " .. caso.estado)
        -- Preparar es la unica con dos golpes: el segundo lo dispara y RETIRA el estado.
        if caso.id == "preparar" then
            pcall(P.RunBasicAction, caso.id)
            r.chk("preparar: el segundo clic lo retira",
                C.Has and C.Has("player", caso.estado) == false)
        elseif C.RemoveOwned then
            C.RemoveOwned(caso.estado)
        end
    end
    r.manual("Las de objetivo y las de menu no se automatizan: usa /harford debug run accion <id>")
end)

------------------------------------------------------------
-- TIRA DE ESTADOS. Lo unico verificable solo es que se construya y se coloque; que se VEA bien es
-- de mirar la pantalla, y se dice como.
------------------------------------------------------------
Grupo("tira", "la tira de estados sobre el objetivo, y que quede encima del frame", function(r)
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
-- RED. Hace falta otro cliente para ver si LLEGA, pero no para comprobar que el mensaje se compone
-- y se vuelve a leer bien. Eso se prueba entero aqui, en solitario, y es donde ya hubo un fallo
-- mudo: una etiqueta larga pasaba de 255 bytes, `SendAddonMessage` descartaba el mensaje y la
-- tirada simplemente no llegaba, sin error en ninguno de los dos lados.
------------------------------------------------------------
Grupo("red", "que los mensajes se compongan y se vuelvan a leer, con su limite de bytes", function(r)
    local WR = _G.HarfordDnDWeaponRolls
    r.chk("motor de tiradas enfrentadas cargado", WR and WR.RollContest ~= nil)
    local C = _G.HarfordDnDConditions
    r.chk("ruta de estado a otro jugador cargada", C and C.ApplyToUnit ~= nil)

    -- Ida y vuelta de una tirada: lo que se manda tiene que volver a leerse igual.
    local R = _G.HarfordDnDRolls
    if R and R.Serialize and R.Deserialize then
        local original = { type = "info", label = "Ataque [Espada corta] +1", total = 17,
            dice = "1d20", modifiers = "+5", critical = "", mode = "", player = "Prueba" }
        local vuelta = R.Deserialize(R.Serialize(original))
        r.chk("una tirada vuelve de la red", vuelta ~= nil)
        if vuelta then
            r.chk("con su etiqueta", vuelta.label == original.label, tostring(vuelta.label))
            r.chk("con su total", tostring(vuelta.total) == tostring(original.total), tostring(vuelta.total))
        end

        -- El limite de verdad: `SendAddonMessage` descarta por encima de ~255 bytes y no avisa.
        local larga = { type = "info", player = "Prueba", total = 9, dice = "", modifiers = "",
            critical = "", mode = "",
            label = string.rep("Exponer Armadura: Ataque con nota muy larga ", 12) }
        local payload = R.Serialize(larga)
        r.chk("una etiqueta larga se recorta bajo el limite", #payload <= 240, #payload .. " bytes")
        r.chk("y sigue siendo legible al volver", R.Deserialize(payload) ~= nil)

        -- Los separadores del formato tienen que sobrevivir dentro del texto.
        local sucia = { type = "info", player = "Prueba", total = 1, dice = "", modifiers = "",
            critical = "", mode = "", label = "con ^ y | y % dentro" }
        local v2 = R.Deserialize(R.Serialize(sucia))
        r.chk("los separadores no rompen la etiqueta", v2 and v2.label == sucia.label,
            v2 and tostring(v2.label) or "no vuelve")
    end

    -- La peticion de estado a otro cliente, ida y vuelta.
    local S = _G.HarfordSync
    if S and S.SerializeConditionRequest and S.DeserializeConditionRequest then
        local datos = { id = "1.1", op = "apply", conditionId = "ayudado_prueba",
            sourceGuid = "Player-1-0000", sourceName = "Prueba", duration = "source_turn_start", turns = 0 }
        local v = S.DeserializeConditionRequest(S.SerializeConditionRequest(datos))
        r.chk("una peticion de estado vuelve", v ~= nil)
        if v then
            r.chk("con la condicion correcta", v.conditionId == datos.conditionId, tostring(v.conditionId))
            r.chk("y con su duracion", v.duration == datos.duration, tostring(v.duration))
        end
    end

    -- La contienda viaja por `DOSAVE` con las DOS habilidades en el ultimo campo. Si el campo se
    -- pierde o se trunca, el defensor tiraria una salvacion en vez de su prueba y nadie lo notaria.
    if S and S.SerializeRequestedSave and S.DeserializeRequestedSave then
        local msg = S.SerializeRequestedSave("Fuerza", 15, "agarrado", 0, "grappled",
            "manual", 0, "Player-1-0000", "Prueba", "", "", "Atletismo/Acrobacias")
        local _, dc, _, _, cond2, _, _, _, _, _, _, skill = S.DeserializeRequestedSave(msg)
        r.chk("la contienda viaja entera", tostring(dc) == "15" and cond2 == "grappled",
            tostring(dc) .. " / " .. tostring(cond2))
        r.chk("con las DOS habilidades", skill == "Atletismo/Acrobacias", tostring(skill))
    end

    r.manual("Queda por ver con OTRO jugador de objetivo (que llegue, no que se componga):")
    r.manual("  1. Agarrar -> el debe tirar Atletismo o Acrobacias en SU cliente y salir Agarrado si pierde.")
    r.manual("  2. Empujar -> elige Apartar: NO debe quedar Derribado. Repite con Derribar: si debe.")
    r.manual("  3. Ayudar -> elige prueba: su siguiente prueba sale con ventaja y el estado se le va.")
    r.manual("Con un NPC de objetivo: Agarrar debe resolverse en TU cliente, sin pedirle nada a nadie.")
    r.manual("Preparar: primer clic gasta ACCION, segundo clic gasta REACCION y retira el estado.")
end)

------------------------------------------------------------
-- TIRADAS. La API publica es la que usan Arcanum y los propios rasgos: si devuelve basura, falla
-- todo lo que cuelga de ella y el sintoma aparece lejos de la causa.
------------------------------------------------------------
Grupo("tiradas", "la API publica de tiradas, y que registre la ultima", function(r)
    local api = _G.DND5E_ARC_API
    if not api then
        r.chk("API de tiradas disponible", false)
        return
    end
    -- Cada una TIRA de verdad: no hay forma de comprobar el resultado sin producirlo.
    local casos = {
        { "RollAbilityEx", "Fuerza" }, { "RollSaveEx", "Destreza" }, { "RollSkillEx", "Atletismo" },
    }
    for _, caso in ipairs(casos) do
        local fn = api[caso[1]]
        if type(fn) ~= "function" then
            r.chk("falta " .. caso[1], false)
        else
            local ok, res = pcall(fn, caso[2])
            r.chk(caso[1] .. " no revienta", ok, not ok and tostring(res) or nil)
            if ok then
                local total = res and tonumber(res.total)
                r.chk(caso[1] .. " devuelve un total", total ~= nil, tostring(res and res.total))
                -- Un d20 mas bonos: por debajo de -20 o por encima de 60 algo va muy mal.
                if total then
                    r.chk(caso[1] .. " da un numero creible", total > -20 and total < 60, total)
                end
            end
        end
    end
    -- La ultima tirada tiene que quedar registrada: de ella dependen los puntos de heroe y los
    -- dados de enfoque, que modifican una tirada YA hecha.
    r.chk("queda registrada la ultima tirada", api._lastRoll ~= nil)
    if api._lastRoll then
        r.chk("con su tipo", api._lastRoll.kind ~= nil, tostring(api._lastRoll.kind))
    end
end)

------------------------------------------------------------
-- FICHA. Los valores derivados: si uno revienta, la ficha se queda a medias sin decir por que.
------------------------------------------------------------
Grupo("ficha", "habilidades, salvaciones, CA y que ningun recurso pase de su maximo", function(r)
    local Calc, Datos = _G.HarfordDnDCalc, _G.HarfordDnDData
    if not (Calc and Datos) then
        r.chk("calculo y datos disponibles", false)
        return
    end
    -- Las 18 habilidades y las 6 salvaciones, una por una: basta con que una tabla mal escrita
    -- rompa el bucle para que la ficha se quede sin pintar de ahi para abajo.
    local malas = {}
    for _, s in ipairs(Datos.SKILLS or {}) do
        local ok = pcall(Calc.GetSkillRollBonuses, s)
        if not ok then malas[#malas + 1] = tostring(s.name) end
    end
    r.chk("las " .. #(Datos.SKILLS or {}) .. " habilidades calculan", #malas == 0, table.concat(malas, ", "))
    local malasSalv = {}
    for _, a in ipairs(Datos.ABIL or {}) do
        local ok = pcall(Calc.GetSaveRollBonuses, a.name or a.key or a.id)
        if not ok then malasSalv[#malasSalv + 1] = tostring(a.name or a.key) end
    end
    r.chk("las salvaciones calculan", #malasSalv == 0, table.concat(malasSalv, ", "))

    local Combat = _G.HarfordDnDCombat
    if Combat and Combat.ComputeSelfArmorClass then
        local ok, ca = pcall(Combat.ComputeSelfArmorClass)
        r.chk("la CA se calcula", ok and tonumber(ca) ~= nil, tostring(ca))
        if ok and tonumber(ca) then
            r.chk("y da un valor creible", ca >= 5 and ca <= 40, ca)
        end
    end

    -- Ningun recurso puede tener el actual por encima del maximo: eso es una barra desbordada.
    local Store, Res = _G.HarfordDnDStore, _G.HarfordDnDResources
    if Store and Store.GetResourceCurrent and Res and Res.ORDER then
        local desbordados = {}
        for _, clave in ipairs(Res.ORDER) do
            local cur = tonumber(Store.GetResourceCurrent(clave)) or 0
            local max = Store.GetResourceMax and tonumber(Store.GetResourceMax(clave)) or nil
            if max and max > 0 and cur > max then
                desbordados[#desbordados + 1] = clave .. " " .. cur .. "/" .. max
            end
        end
        r.chk("ningun recurso pasa de su maximo", #desbordados == 0, table.concat(desbordados, ", "))
    end
end)

------------------------------------------------------------
-- PROGRESION. Que las 12 clases construyan sus rasgos de 1 a 6 sin reventar. Es barrido puro: no
-- cambia nada de tu ficha, solo pregunta al libro.
------------------------------------------------------------
Grupo("progresion", "que las 12 clases construyan sus rasgos de 1 a 6", function(r)
    local B = _G.HarfordDnDBook
    local API_B = B and (B.API or B)
    local clases = API_B and API_B.CLASSES
    if not clases then
        r.chk("libro de clases disponible", false)
        return
    end
    local n, rotas = 0, {}
    for id, clase in pairs(clases) do
        n = n + 1
        for nivel = 1, 6 do
            local ok, err = pcall(function()
                local lista = clase.features or clase.rasgos or {}
                for _, f in ipairs(lista) do
                    if (tonumber(f.level) or 1) <= nivel then
                        -- Tocar los campos es suficiente: un `name` que no sea texto o un `uses`
                        -- que no sea tabla revientan al pintarlos, no al declararlos.
                        local _ = tostring(f.name) .. tostring(f.id)
                        if f.uses ~= nil and type(f.uses) ~= "table" then error("uses no es tabla") end
                        if f.effects ~= nil and type(f.effects) ~= "table" then error("effects no es tabla") end
                    end
                end
            end)
            if not ok then rotas[#rotas + 1] = tostring(id) .. " n" .. nivel .. ": " .. tostring(err) end
        end
    end
    r.chk("las " .. n .. " clases construyen de 1 a 6", #rotas == 0, table.concat(rotas, " | "))
    r.chk("hay 12 clases", n == 12, n)
end)

------------------------------------------------------------
-- ATAQUE. Se comprueba contra EL OBJETIVO QUE YA TIENES: no se puede cambiar de objetivo por
-- comando, asi que selecciona primero y ejecuta despues.
--
-- NPC y jugador son dos caminos DISTINTOS y hay que probar los dos:
--   NPC      -> su CA sale del tracker de turnos, de lo escrito a mano o de su stat block TRP3, y
--               el dano se lo aplica el atacante por comando de servidor.
--   Jugador  -> su CA sale de su TRP3 o de lo que su propio cliente publica, y el dano se le manda
--               en BRUTO para que lo resuelva el con sus resistencias.
-- Confundirlos es como se cuela un fallo que solo aparece contra uno de los dos.
------------------------------------------------------------
Grupo("ataque", "contra EL OBJETIVO QUE TENGAS: distingue NPC de jugador", function(r)
    local K = _G.HarfordDnDCombat
    if not K then
        r.chk("motor de combate disponible", false)
        return
    end
    if not (UnitExists and UnitExists("target")) then
        r.manual("Sin objetivo. Selecciona un NPC o un jugador y repite: verificar ataque")
        return
    end

    local esJugador = UnitIsPlayer and UnitIsPlayer("target")
    local yo = UnitIsUnit and UnitIsUnit("target", "player")
    local nombre = tostring(UnitName("target"))
    r.manual("Objetivo: " .. nombre .. " (" .. (esJugador and "JUGADOR" or "NPC")
        .. (yo and ", eres tu" or "") .. ")")

    -- La CA es lo primero: sin ella el ataque se anuncia sin veredicto, y eso se lee como que
    -- "no funciona" cuando en realidad es que no se sabe contra que comparar.
    local ca = K.GetArmorClassForUnit("target")
    r.chk("se conoce la CA del objetivo", ca ~= nil and ca > 0,
        ca and ("CA " .. tostring(ca)) or "sin CA: mira su TRP3 o ponla a mano")
    if not ca then
        r.manual(esJugador
            and "Jugador sin CA: que la escriba en TRP3 (Currently/Other Information) o que abra su ficha."
            or "NPC sin CA: ponsela con el editbox CA, o dale un stat block en su perfil TRP3.")
        return
    end

    -- El veredicto, contra la CA de VERDAD del objetivo que tienes delante.
    local _, entra = K.ResolveArmorClassOutcome(ca + 1, "", "target")
    r.chk("un total por encima entra", entra == true)
    local _, empate = K.ResolveArmorClassOutcome(ca, "", "target")
    -- Regla de la mesa: el defensor gana los empates.
    r.chk("un empate NO entra", empate == false, "empate con CA " .. tostring(ca))
    local _, debajo = K.ResolveArmorClassOutcome(ca - 1, "", "target")
    r.chk("por debajo no entra", debajo == false)
    local _, critico = K.ResolveArmorClassOutcome(1, "CRÍTICO", "target")
    r.chk("un critico entra aunque el total sea 1", critico == true)
    local _, pifia = K.ResolveArmorClassOutcome(ca + 99, "PIFIA", "target")
    r.chk("una pifia falla aunque el total sobre", pifia == false)

    if esJugador and not yo then
        -- Contra jugador el dano viaja en BRUTO: lo resuelve su cliente con sus resistencias, su
        -- vida temporal y sus reacciones. Aqui solo se comprueba que la ruta exista y componga.
        r.chk("hay ruta de dano a jugador", K.PayloadFor ~= nil)
        if K.PayloadFor then
            local ok, payload = pcall(K.PayloadFor, "target", 7, "cortante")
            r.chk("el paquete de dano se compone", ok and payload ~= nil,
                not ok and tostring(payload) or nil)
        end
        r.manual("Pegale de verdad y confirma EN SU CLIENTE: que le baje la vida, que aplique")
        r.manual("  sus resistencias, y que la linea salga con tu nombre.")
    elseif not esJugador then
        -- Contra NPC el dano lo aplica el atacante por comando de servidor, asi que hace falta
        -- permiso de oficial de fase: sin el, el ataque sale pero la vida no se mueve.
        local A = _G.HarfordAuthority
        local puede = A and A.CanUseOfficerCommands and A.CanUseOfficerCommands()
        r.chk("puedes modificar la vida del NPC", puede == true,
            "sin permiso de oficial de fase el ataque sale pero su vida no baja")
        r.chk("hay ruta de dano a NPC", K.ApplyWeaponDamageToNpc ~= nil)
        r.manual("Pegale de verdad y confirma que le baja la vida y que emota la herida.")
    else
        r.manual("Te tienes a ti mismo de objetivo: para el resto, coge un NPC o a otro jugador.")
    end
end)

------------------------------------------------------------
-- AREAS. La geometria se prueba fuera de WoW; lo que solo se puede comprobar aqui es que el
-- cliente de VERDAD entregue posiciones, y que el centro caiga donde debe con lo que hay delante.
------------------------------------------------------------
Grupo("areas", "posicion, contexto y donde va a caer el centro de un area", function(r)
    local A = _G.HarfordDnDArea
    r.chk("motor de areas cargado", A ~= nil)
    if not A then return end

    -- Sin posicion propia no hay area automatica: todo habria que marcarlo a mano.
    if C_Epsilon and C_Epsilon.GetPosition then
        local ok, x, y, z, ctx = pcall(C_Epsilon.GetPosition)
        r.chk("el cliente da tu posicion", ok and tonumber(x) ~= nil and tonumber(y) ~= nil)
        if ok and tonumber(x) then
            -- La z falta en algunos builds; no es un fallo, pero conviene saberlo porque es lo
            -- que corta el area en vertical.
            if tonumber(z) == nil then
                r.manual("Este build no da altura (z): el corte vertical de las areas no filtra.")
            end
            r.chk("y un identificador de contexto", tostring(ctx or "") ~= "",
                "sin contexto no se distinguen dos fases con las mismas coordenadas")
        end
    else
        r.chk("C_Epsilon.GetPosition disponible", false, "sin el no hay automarcado de areas")
    end

    -- Solo los jugadores del grupo responden posicion. Es la limitacion que mas confunde: el
    -- automarcado no ve a nadie fuera del grupo, y sin grupo no ve a nadie.
    local enGrupo = IsInGroup and IsInGroup()
    r.chk("estas en grupo para poder pedir posiciones", enGrupo == true,
        "sin grupo, el automarcado no puede preguntar a nadie")

    -- El centro de una esfera sale de la posicion del jugador al que apuntas. Apuntar a un NPC no
    -- da centro, y el area cae en ti: la ventana lo avisa, pero conviene verlo aqui.
    if UnitExists and UnitExists("target") then
        local esJugador = UnitIsPlayer and UnitIsPlayer("target")
        if esJugador then
            r.manual("Objetivo jugador: una esfera se centrara EN EL, que es lo correcto.")
        else
            r.manual("Objetivo NPC: una esfera se centrara EN TI (los NPC no responden posicion).")
            r.manual("  Para centrarla lejos, apunta a un jugador que este en el punto.")
        end
    end
    r.manual("Lanza un area y comprueba en la ventana: distancia por objetivo y los de fuera en gris.")
end)

------------------------------------------------------------
-- SEGURIDAD. Quien puede hacerte que. Es la unica barrera que impide que un desconocido te baje la
-- vida o te ponga un estado, y no se ve por ninguna parte hasta que falla.
------------------------------------------------------------
Grupo("seguridad", "quien puede aplicarte dano o estados, y quien no", function(r)
    local Comm = _G.HarfordDnDComm
    r.chk("capa de mensajes cargada", Comm and Comm.CreateHandlers ~= nil)

    -- La resolucion de nombre a unidad es lo que decide si un mensaje de efecto se acepta.
    local CC = _G.HarfordClassColors
    r.chk("se puede resolver un nombre a unidad", CC and CC.FindUnitByName ~= nil)
    if CC and CC.FindUnitByName then
        local yo = CC.UnitFullName and CC.UnitFullName("player")
        r.chk("te resuelves a ti mismo", yo ~= nil and yo ~= "")
        -- Un nombre inventado NO puede resolverse: si lo hiciera, cualquiera pasaria el filtro.
        r.chk("un nombre inventado no se resuelve",
            CC.FindUnitByName("Nadie" .. tostring(math.random(100000, 999999))) == nil)
    end

    -- Los prefijos de efecto tienen que estar registrados, o los mensajes no llegan siquiera.
    if C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered then
        for _, prefijo in ipairs({ "DND5EARC", "HARFORDTURN" }) do
            r.chk("prefijo registrado: " .. prefijo,
                C_ChatInfo.IsAddonMessagePrefixRegistered(prefijo) == true)
        end
    end
    r.manual("Con otro jugador: que un ataque suyo te baje la vida, y que uno de fuera del")
    r.manual("  grupo y sin verte NO pueda (esto ultimo solo se puede probar con un tercero).")
end)

------------------------------------------------------------
-- LIBRO. Que ninguna entrada quede sin arte ni sin categoria, que es lo que la deja muerta al clic.
------------------------------------------------------------
Grupo("libro", "que el Libro se construya y no queden entradas sin nombre ni arte", function(r)
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
    local pedido, extra = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")
    local lista = {}
    if pedido and pedido ~= "" then
        if pedido == "ayuda" or pedido == "grupos" then
            ListarGrupos()
            return
        end
        if not GRUPOS[pedido] then
            Print("grupo desconocido: " .. pedido)
            ListarGrupos()
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
        local ok, err = pcall(GRUPOS[nombre], r, extra)
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
end, "bateria de verificacion en juego; 'verificar ayuda' lista los grupos")

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
