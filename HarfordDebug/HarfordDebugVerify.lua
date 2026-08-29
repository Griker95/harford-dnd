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
-- Los codigos de color de WoW sobran en un fichero: se quitan al volcar el informe.
local function SinColor(texto)
    texto = tostring(texto or "")
    texto = texto:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return texto
end

local function NuevoRegistro()
    local r = { ok = 0, fallos = {}, manuales = {}, notas = {} }
    function r.chk(texto, condicion, detalle)
        if condicion then r.ok = r.ok + 1
        else r.fallos[#r.fallos + 1] = texto .. (detalle and ("  |cff808080" .. tostring(detalle) .. "|r") or "") end
    end
    -- `montaje` dice QUE HAY QUE PREPARAR para poder comprobarlo. Se agrupa por eso al final, no
    -- por grupo: asi un solo preparativo --seleccionar un NPC, montar un combate-- desbloquea un
    -- lote entero, en vez de obligar a repasar veinte grupos uno a uno.
    function r.manual(texto, montaje)
        r.manuales[#r.manuales + 1] = { texto = texto, montaje = montaje or "suelto" }
    end
    -- Una NOTA informa; no es algo que quede por comprobar. Se separan porque mezclarlas hacia
    -- que la bateria pareciera una lista de sesenta tareas cuando de verdad quedan muchas menos.
    function r.nota(texto) r.notas[#r.notas + 1] = texto end
    return r
end

-- Los montajes, en el orden en que conviene hacerlos: de lo que no pide nada a lo que pide a otra
-- persona. Cada uno dice como prepararlo, para no tener que recordarlo.
local MONTAJES = {
    { clave = "suelto",   titulo = "Sin preparar nada" },
    { clave = "npc",      titulo = "Con un NPC seleccionado" },
    { clave = "jugador",  titulo = "Con OTRO JUGADOR seleccionado" },
    { clave = "combate",  titulo = "Con un combate montado (3-4 tarjetas)" },
    { clave = "ficha",    titulo = "Con la ficha o el panel abiertos" },
    { clave = "dos",      titulo = "CON DOS CLIENTES (lo unico que no se puede automatizar)" },
}

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
        r.nota("GetFileIDFromPath no existe en este cliente: los iconos no se pueden verificar.")
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

    -- La tabla de NOMBRES es el fallback visual y donde acaban los iconos escritos a mano
    -- (maniobras del Guerrero, Maldiciones del Brujo): tambien se comprueba entera. El arte
    -- declarado puede no estar en este build aunque exista en retail.
    if type(cat.names) == "table" then
        local totalN, rotosN = 0, 0
        for nombre, icono in pairs(cat.names) do
            totalN = totalN + 1
            local ruta = "Interface\\Icons\\" .. tostring(icono)
            if not GetFileIDFromPath(ruta) then
                rotosN = rotosN + 1
                r.chk("icono por nombre inexistente: " .. tostring(nombre), false, icono)
            end
        end
        r.chk("los " .. totalN .. " iconos por nombre existen", rotosN == 0, rotosN .. " rotos")
    end

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
        -- `dobleMovimiento` faltaba en esta lista: Correr paso de "se lleva en mesa" a doblar de
        -- verdad el tope del contador, y la comprobacion se quedo vieja marcandolo en rojo. Una
        -- bateria que da falsos fallos entrena a ignorarla entera, asi que se corrige EN CUANTO se
        -- ve -- no se convive con un rojo conocido.
        local ruta = def.selfCondition or def.skillCheck or def.contest or def.helpOther
            or def.throwWeapon or def.readyAction or def.dobleMovimiento or def.soloAnuncio
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
        r.nota("Para ejecutarlas de verdad: /harford debug run verificar acciones ejecutar")
        r.nota("  (anuncia cada una por chat; hazlo a solas)")
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
    r.manual("Las de objetivo y las de menu no se automatizan: usa /harford debug run accion <id>", "npc")
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
        r.manual("Sin objetivo: coge uno y repite este grupo para comprobar el anclaje.", "npc")
        return
    end
    -- Un estado sobre OTRO JUGADOR lo aplica SU cliente, no el tuyo: aqui no aparece nada, y las
    -- comprobaciones de abajo caian las dos por eso. No es un fallo de la tira -- es que desde este
    -- cliente no se puede montar la escena. Con un NPC (o contigo mismo) si se aplica en local.
    local otroJugador = UnitIsPlayer and UnitIsPlayer("target")
        and not (UnitIsUnit and UnitIsUnit("target", "player"))
    if otroJugador then
        r.manual("El objetivo es otro JUGADOR: un estado suyo lo aplica su cliente, asi que la "
            .. "tira no se puede comprobar desde aqui. Coge un NPC y repite este grupo.", "npc")
        return
    end

    local C = _G.HarfordDnDConditions
    local prueba = "esquivando"
    local tenia = C and C.Has and C.Has("target", prueba)
    if C and C.ApplyToUnit and not tenia then
        C.ApplyToUnit("target", prueba, { duration = "manual" })
    end
    -- Que el estado haya prendido DE VERDAD antes de medir nada: si no, lo que sigue mide una tira
    -- vacia y el fallo sale ilegible ("no se muestra") sin decir por que.
    local prendio = C and C.Has and C.Has("target", prueba)
    r.chk("el estado de prueba prende en el objetivo", prendio and true or false,
        "sin el, la tira no tiene nada que pintar y lo de abajo no significa nada")
    if not prendio then
        if C and C.RemoveFromUnit and not tenia then C.RemoveFromUnit("target", prueba) end
        return
    end
    UF.RefreshConditionStrip("target")
    local tira = _G["HarfordEstadostarget"]
    r.chk("la tira se construye", tira ~= nil)
    if tira then
        r.chk("y se muestra con un estado puesto", tira:IsShown())
        local frame = _G["TargetFrame"]
        if frame and tira:GetBottom() and frame:GetTop() then
            -- Con el marco pegado al TECHO de la pantalla la tira NO CABE encima, y el codigo
            -- elige solaparse a proposito: "verla mal es infinitamente mejor que no verla". La
            -- comprobacion exigia "por encima" sin conocer esa regla y fallaba justo en el montaje
            -- mas comun (marco arriba del todo, 1005 de 1009): fallo de la PRUEBA, no de la tira.
            local techoPantalla = UIParent and UIParent:GetHeight()
            local sitioArriba = techoPantalla
                and (frame:GetTop() + 6 + tira:GetHeight() <= techoPantalla)
            if sitioArriba then
                r.chk("y queda POR ENCIMA del unitframe", tira:GetBottom() >= frame:GetTop(),
                    string.format("tira=%.0f frame=%.0f", tira:GetBottom(), frame:GetTop()))
            else
                r.chk("sin sitio arriba: se solapa A PROPOSITO y se queda visible",
                    tira:GetBottom() ~= nil and tira:IsShown(),
                    "el marco esta pegado al techo de la pantalla")
            end
        end
        -- "Por encima" no basta: con el marco pegado al borde superior, la tira quedaba colocada
        -- perfectamente respecto a el y VEINTIDOS PIXELES fuera de la pantalla. Las tres
        -- comprobaciones de arriba pasaban y no se veia nada.
        local techo = UIParent and UIParent:GetHeight()
        local arriba = tira:GetTop()
        if techo and arriba then
            r.chk("y DENTRO de la pantalla", arriba <= techo,
                string.format("arriba=%.0f pantalla=%.0f", arriba, techo))
        end
        -- Un icono sin textura se pinta transparente y parece que no hay tira.
        local sinTextura = 0
        for _, b in ipairs(tira.iconos or {}) do
            if b:IsShown() and not (b.icon and b.icon.GetTexture and b.icon:GetTexture()) then
                sinTextura = sinTextura + 1
            end
        end
        r.chk("y sus iconos tienen textura", sinTextura == 0, sinTextura .. " sin textura")
    end
    if C and C.RemoveFromUnit and not tenia then C.RemoveFromUnit("target", prueba) end
    -- El estado se pone y se QUITA, asi que no queda nada que mirar: pedir "mira el objetivo" aqui
    -- era una instruccion imposible de seguir. Para verlo hace falta uno que se quede.
    r.nota("Para VERLO, deja un estado puesto y vuelve a mirar:")
    r.nota("  /harford debug run estadoen prone")
    r.nota("  /harford debug run tira        (dice que deberia pintar, y si quedo por encima)")
    r.nota("  /harford debug run estadoen prone quitar")
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

    -- Sin grupo no hay canal, y entonces NADA de esto llega aunque este bien compuesto.
    local canal = _G.HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
    r.chk("hay canal para publicar estados y tiradas", canal ~= nil,
        "sin grupo, los estados no se publican a nadie")

    r.manual("Queda por ver con OTRO jugador de objetivo (que llegue, no que se componga):", "dos")
    r.manual("  1. Agarrar -> el debe tirar Atletismo o Acrobacias en SU cliente y salir Agarrado si pierde.", "dos")
    r.manual("  2. Empujar -> elige Apartar: NO debe quedar Derribado. Repite con Derribar: si debe.", "suelto")
    r.manual("  3. Ayudar -> elige prueba: su siguiente prueba sale con ventaja y el estado se le va.", "combate")
    r.manual("Con un NPC de objetivo: Agarrar debe resolverse en TU cliente, sin pedirle nada a nadie.", "npc")
    r.manual("Preparar: primer clic gasta ACCION, segundo clic gasta REACCION y retira el estado.", "suelto")
end)

------------------------------------------------------------
-- TIRADAS. La API publica es la que usan Arcanum y los propios rasgos: si devuelve basura, falla
-- todo lo que cuelga de ella y el sintoma aparece lejos de la causa.
------------------------------------------------------------
------------------------------------------------------------
-- COMPRESION Y ATRIBUCION DEL DANO. Lo que cambio el 28/08: la foto de turnos, el equipo y la
-- progresion viajan comprimidos, y la linea de dano la publica la VICTIMA.
--
-- Lo que este cliente NO puede comprobar solo va marcado a mano: si el OTRO recibe. Aqui se
-- verifica el FORMATO y la ida y vuelta; la ENTREGA solo se ve con dos clientes.
------------------------------------------------------------
------------------------------------------------------------
-- SISTEMAS SIN SUITE PROPIA. Estos grupos EJERCITAN de verdad -- estado sintetico, ciclo completo
-- y limpieza garantizada -- lo que hasta ahora solo cubrian los barridos estaticos.
------------------------------------------------------------
Grupo("misiones", "el ciclo completo de una mision con una sintetica (se limpia sola)", function(r)
    local Q = _G.HarfordQuests or _G.HarfordQuestAPI
    r.chk("el sistema de misiones esta cargado", Q and Q.Accept ~= nil)
    if not (Q and Q.Accept) then return end

    -- Mision SINTETICA y SIN recompensas: ejercita aceptar, rastrear, progresar, auto-completar y
    -- abandonar sin conceder nada real. El id es propio de la bateria y se limpia SIEMPRE.
    local ID = "debug:bateria_verificar"
    pcall(Q.Abandon, ID)  -- resto de una pasada anterior, si lo hubiera

    local ok = Q.Accept(ID, {
        title = "Prueba de la bateria",
        description = "Mision sintetica del verificador; si la ves, puedes abandonarla.",
        objectives = {
            { text = "Primer objetivo", required = 1 },
            { text = "Segundo objetivo", required = 2 },
        },
    })
    r.chk("se acepta", ok and Q.IsAccepted(ID) or false)
    if not Q.IsAccepted(ID) then return end

    -- Todo lo que sigue va protegido para que la limpieza corra aunque algo falle.
    local okTodo, err = pcall(function()
        if Q.SetTracked then
            Q.SetTracked(ID, true, true)
            r.chk("se rastrea", Q.IsTracked and Q.IsTracked(ID) or false)
        end
        if Q.AdvanceObjective then
            Q.AdvanceObjective(ID, 1)
            r.chk("con un objetivo hecho NO se completa", not Q.IsComplete(ID))
        end
        if Q.SetObjectiveProgress then
            Q.SetObjectiveProgress(ID, 2, 2)
            -- El auto-completado es de RecomputeCompletion: todos los objetivos hechos cierran la
            -- mision sin que nadie llame a "completar".
            r.chk("con todos hechos se completa SOLA", Q.IsComplete(ID) == true)
        end
        if Q.GetObjectives then
            local objetivos = Q.GetObjectives(ID) or {}
            r.chk("los objetivos conservan su contador", #objetivos == 2
                and tonumber(objetivos[2].current or objetivos[2].curr or -1) == 2)
        end
    end)
    Q.Abandon(ID)
    r.chk("y abandonar la limpia del todo", not Q.IsAccepted(ID)
        and not (Q.IsTracked and Q.IsTracked(ID)))
    if not okTodo then
        r.chk("el ciclo no reviento", false, tostring(err))
    end
end)

Grupo("loot", "que el loot serializado vuelva identico de la red", function(r)
    local S = _G.HarfordSync
    r.chk("la serializacion de loot existe", S and S.SerializeTaggedLootMessage ~= nil)
    if not (S and S.SerializeTaggedLootMessage and S.DeserializeTaggedLootMessage) then return end

    -- Ida y vuelta con una tabla sintetica: guid + filas {itemId, cantidad, asignado}.
    local guid = "Creature-0-1111-2-3-4-0001"
    local tabla = { { 14074575, 3, true }, { 14088020, 1, false }, { 2770, 12, true } }
    local payload = S.SerializeTaggedLootMessage(guid, tabla)
    r.chk("cabe en un mensaje", #payload <= 240, #payload .. " bytes")
    local guidVuelta, filas = S.DeserializeTaggedLootMessage(payload)
    r.chk("el guid vuelve", guidVuelta == guid, tostring(guidVuelta))
    r.chk("las filas vuelven", type(filas) == "table" and #filas == 3)
    if type(filas) == "table" and filas[1] then
        local f = filas[1]
        r.chk("con item, cantidad y asignacion", (tonumber(f[1]) == 14074575)
            and (tonumber(f[2]) == 3) and (f[3] == true or f[3] == 1),
            tostring(f[1]) .. "/" .. tostring(f[2]) .. "/" .. tostring(f[3]))
    end
end)

Grupo("subida", "la tabla de XP 5e y el aviso de subida pendiente", function(r)
    local X = _G.HarfordCharacterXP
    r.chk("el sistema de XP esta cargado", X and X.LevelForXP ~= nil)
    if not (X and X.LevelForXP) then return end

    -- Umbrales del manual, niveles 1-6 (el alcance del addon): el nivel que da cada XP exacta y
    -- la anterior. Una tabla mal copiada aqui sube o retiene niveles a todo el mundo.
    local UMBRALES = { [2] = 300, [3] = 900, [4] = 2700, [5] = 6500, [6] = 14000 }
    local mal = {}
    for nivel, xp in pairs(UMBRALES) do
        if X.LevelForXP(xp) ~= nivel then mal[#mal + 1] = xp .. "->" .. tostring(X.LevelForXP(xp)) end
        if X.LevelForXP(xp - 1) ~= nivel - 1 then mal[#mal + 1] = (xp - 1) .. "->" .. tostring(X.LevelForXP(xp - 1)) end
    end
    r.chk("los umbrales 1-6 casan con el manual", #mal == 0, table.concat(mal, ", "))
    r.chk("con 0 XP eres nivel 1", X.LevelForXP(0) == 1)
    -- Coherencia del aviso: pendiente == (nivel por XP > nivel real). Solo se COMPRUEBA la
    -- formula; la subida sigue siendo manual siempre.
    if X.PendingLevelUp and X.GetXP and HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel then
        local porXP = X.LevelForXP(tonumber(X.GetXP()) or 0)
        local real = tonumber(HarfordDnDProgression.GetTotalLevel()) or 0
        local esperado = (real > 0) and (porXP > real) or false
        r.chk("el aviso de subida dice la verdad", (X.PendingLevelUp() == true) == esperado,
            string.format("porXP=%d real=%d", porXP, real))
    end
end)

Grupo("secuencias", "que la biblioteca de secuencias este bien formada (sin ejecutarlas)", function(r)
    local A = _G.HarfordActionSequence
    r.chk("el motor de secuencias esta cargado", A and A.Run ~= nil)
    if not (A and A.LIBRARY) then return end
    -- Solo FORMA: ejecutarlas mandaria comandos reales al servidor. Cada secuencia es una lista de
    -- pasos con retardo numerico y algo que hacer.
    local total, rotas = 0, {}
    for nombre, secuencia in pairs(A.LIBRARY) do
        total = total + 1
        if type(secuencia) ~= "table" or #secuencia == 0 then
            rotas[#rotas + 1] = nombre .. " (vacia)"
        else
            for i, paso in ipairs(secuencia) do
                if type(paso) ~= "table" then
                    rotas[#rotas + 1] = nombre .. "#" .. i .. " (no es tabla)"
                elseif paso.delay and not tonumber(paso.delay) then
                    rotas[#rotas + 1] = nombre .. "#" .. i .. " (delay no numerico)"
                end
            end
        end
    end
    r.chk("hay secuencias registradas", total > 0, tostring(total))
    r.chk("y todas bien formadas", #rotas == 0, table.concat(rotas, ", "))
end)

Grupo("comprimir", "que la compresion este disponible y no pierda un byte", function(r)
    local S = _G.HarfordSync
    r.chk("el transporte expone la compresion", S and S.Comprimir ~= nil and S.Descomprimir ~= nil)
    if not (S and S.Comprimir) then return end

    -- LA pieza fragil: LibDeflate NO viene con Harford, se toma prestada de EpsilonLib, TRP3 o
    -- Epsilon_Book. Si un cliente la tiene y otro no, el que no la tiene DESCARTA EN SILENCIO todo
    -- lo comprimido -- y antes le llegaba troceado y funcionaba.
    local ok, lib = pcall(function()
        if LibStub and LibStub.GetLibrary then return LibStub:GetLibrary("LibDeflate", true) end
    end)
    local D = (ok and lib) or _G.LibDeflate
    r.chk("LibDeflate esta en ESTE cliente", D ~= nil,
        "sin ella no comprimes, pero tampoco DESCOMPRIMES lo que te llegue")
    if not D then
        r.manual("SIN LibDeflate: lo que otro te mande comprimido lo descartaras sin aviso. "
            .. "Instala EpsilonLib o pide que se empaquete dentro de Harford.", "dos")
        return
    end

    local original = "STATE|1|~~activo|" .. string.rep(
        "1,Nombre,npc,Nombre,,28,34,Interface\\Icons\\inv_misc_head_01,12345,15,5,ff00ff;", 20)
    local comprimido = S.Comprimir(original)
    r.chk("comprime un estado grande", comprimido ~= nil)
    if comprimido then
        r.chk("y encoge de verdad", #comprimido < #original,
            #original .. " -> " .. #comprimido .. " bytes")
        r.chk("vuelve al original EXACTO", S.Descomprimir(comprimido) == original)
    end

    -- Lo pequenio va en CLARO a proposito: asi lo entiende cualquier cliente, incluido uno sin
    -- actualizar. Si esto dejara de cumplirse, romperiamos la mesa por un mensaje corto.
    local corto = "STATE|1|~~activo|uno"
    r.chk("lo corto NO se comprime (no compensa)", S.Comprimir(corto) == nil,
        "si comprimiera, un cliente sin actualizar dejaria de entenderlo")
    r.chk("y un texto sin marca pasa tal cual", S.Descomprimir(corto) == corto)

    r.manual("ENTREGA: equipa 4-5 objetos y que OTRO cliente te inspeccione. Si no le llega el "
        .. "equipo, mira si el tiene LibDeflate: es el fallo mas silencioso de este cambio.", "dos")
end)

Grupo("dano", "quien publica la linea de dano: el atacante o la victima", function(r)
    local C = _G.HarfordDnDCombat
    r.chk("existe la decision de quien publica", C and C.VictimaPublicaSuDano ~= nil)
    if not (C and C.VictimaPublicaSuDano) then return end

    -- Contra un NPC no cambia nada y NO DEBE: lo resuelve y lo publica el atacante, como siempre.
    -- Lo garantiza `UnitIsPlayer`, no una tabla de excepciones.
    if UnitExists and UnitExists("target") then
        local esJugador = UnitIsPlayer and UnitIsPlayer("target")
        local publica = C.VictimaPublicaSuDano("target")
        if not esJugador then
            r.chk("con un NPC delante publica el ATACANTE", publica == false,
                "si saliera true, el dano a NPC habria cambiado y no debe")
        elseif UnitIsUnit and UnitIsUnit("target", "player") then
            r.chk("contigo mismo delante publica el atacante", publica == false)
        else
            r.manual("Con " .. tostring(UnitName("target")) .. " delante publica "
                .. (publica and "LA VICTIMA" or "el ATACANTE (aun no difundio sus recursos)")
                .. ". Pegale y comprueba que sale UNA sola linea de dano, no dos.", "jugador")
        end
    else
        r.manual("Sin objetivo: selecciona un NPC y repite, para comprobar que el dano a NPC "
            .. "sigue igual que siempre.", "npc")
    end

    local S = _G.HarfordSync
    if S and S.SerializeDamage and S.DeserializeDamage then
        local enlace = "|cff1eff00|Hitem:14088020::::::::60:259:::::::::|h[Espada larga]|h|r"
        local p = S.SerializeDamage({ { amount = 10, damageType = "cortante" } }, false, false,
            "Dano " .. enlace)
        r.chk("el dano viaja con la etiqueta del arma", p ~= nil)
        if p then
            local comps, _crit, _mag, etq = S.DeserializeDamage(p)
            r.chk("los componentes vuelven", comps ~= nil and #comps == 1)
            -- Un enlace lleva PIPES dentro y el separador tambien es pipe: por eso va el ultimo y
            -- se coge de una pieza. Cortarlo ahi dejaba la etiqueta en "Dano " -- fallo real.
            r.chk("y el enlace entero, con su ID",
                etq ~= nil and etq:find("|Hitem:14088020|h", 1, true) ~= nil, tostring(etq))
            r.chk("conservando el color de calidad",
                etq ~= nil and etq:find("|cff1eff00", 1, true) ~= nil)
            r.chk("y cabe en un mensaje", #p <= 240, #p .. " bytes")
        end
    end

    r.manual("Con arma BASICA la linea sale con el nombre a secas, sin enlace.", "suelto")
    r.manual("Si la victima tiene RESISTENCIA, el numero debe venir YA mitigado y NO debe salir "
        .. "una segunda linea de correccion detras.", "suelto")
    r.manual("Y con un NPC poseido pegando a un jugador: mismo trato, una sola linea.", "jugador")
end)

Grupo("turnored", "que avanzar turno mande UN mensaje y no la lista entera", function(r)
    local T = _G.HarfordTurnOrderAPI
    r.chk("api de turnos cargada", T ~= nil)
    if not T then return end
    r.chk("hay estado de combate explicito", T.GetCombatState ~= nil)
    r.chk("y se sabe si mandas tu", T.IsTurnAdmin ~= nil)

    local store = _G.HarfordTurnOrderStore
    local entradas = (type(store) == "table" and type(store.entries) == "table") and #store.entries or 0
    if entradas == 0 then
        r.manual("Mesa vacia: monta un combate con 3-4 tarjetas para poder medir el estado.", "combate")
        return
    end
    r.chk("hay combatientes montados", entradas > 0, entradas .. " entradas")

    -- El tamanio REAL de tu mesa ahora mismo, que es lo que decide si se trocea.
    local S = _G.HarfordSync
    local Codec = _G.HarfordTurnsCodec
    if S and Codec and Codec.SerializeEntry then
        local partes = {}
        for _, e in ipairs(store.entries) do partes[#partes + 1] = Codec.SerializeEntry(e) end
        local payload = table.concat(partes, ";")
        local comprimido = S.Comprimir and S.Comprimir(payload)
        local trozos = math.ceil(#payload / 200)
        local trozosC = comprimido and math.ceil(#comprimido / 200) or trozos
        r.chk("la foto de TU mesa cabe en pocos trozos", trozosC <= 3,
            #payload .. " B en " .. trozos .. " trozos -> " .. trozosC .. " comprimida")
        -- El reensamblado es todo o nada y no hay acuse: basta perder UN trozo para que el receptor
        -- descarte el estado entero, en silencio.
        if trozosC > 3 then
            r.manual("Tu mesa genera " .. trozosC .. " trozos aun comprimida: con esa cifra el "
                .. "estado se pierde a menudo. Quita tarjetas o revisa que miembros llevan dentro.", "combate")
        end
    end

    r.manual("Dale a Siguiente varias veces con OTRO cliente delante: el turno activo tiene que "
        .. "moverse alli y salir el anuncio en su chat. Eso es lo que estaba roto.", "dos")
    r.manual("Golpea a un NPC de la lista: su vida debe bajar tambien en el otro cliente.", "dos")
    r.manual("Y haz /reload en mitad del combate: la ventana debe volver sola.", "combate")
end)

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
        r.manual("Sin objetivo. Selecciona un NPC o un jugador y repite: verificar ataque", "npc")
        return
    end

    local esJugador = UnitIsPlayer and UnitIsPlayer("target")
    local yo = UnitIsUnit and UnitIsUnit("target", "player")
    local nombre = tostring(UnitName("target"))
    r.manual("Objetivo: " .. nombre .. " (" .. (esJugador and "JUGADOR" or "NPC")
        .. (yo and ", eres tu" or "") .. ")", "npc")

    -- La CA es lo primero: sin ella el ataque se anuncia sin veredicto, y eso se lee como que
    -- "no funciona" cuando en realidad es que no se sabe contra que comparar.
    local ca = K.GetArmorClassForUnit("target")
    r.chk("se conoce la CA del objetivo", ca ~= nil and ca > 0,
        ca and ("CA " .. tostring(ca)) or "sin CA: mira su TRP3 o ponla a mano")
    if not ca then
        r.manual(esJugador
            and "Jugador sin CA: que la escriba en TRP3 (Currently/Other Information) o que abra su ficha."
            or "NPC sin CA: ponsela con el editbox CA, o dale un stat block en su perfil TRP3.", "npc")
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
        r.manual("Pegale de verdad y confirma EN SU CLIENTE: que le baje la vida, que aplique", "dos")
        r.manual("  sus resistencias, y que la linea salga con tu nombre.", "suelto")
    elseif not esJugador then
        -- Contra NPC el dano lo aplica el atacante por comando de servidor, asi que hace falta
        -- permiso de oficial de fase: sin el, el ataque sale pero la vida no se mueve.
        local A = _G.HarfordAuthority
        local puede = A and A.CanUseOfficerCommands and A.CanUseOfficerCommands()
        r.chk("puedes modificar la vida del NPC", puede == true,
            "sin permiso de oficial de fase el ataque sale pero su vida no baja")
        r.chk("hay ruta de dano a NPC", K.ApplyWeaponDamageToNpc ~= nil)
        r.manual("Pegale de verdad y confirma que le baja la vida y que emota la herida.", "jugador")
    else
        r.manual("Te tienes a ti mismo de objetivo: para el resto, coge un NPC o a otro jugador.", "npc")
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
                r.nota("Este build no da altura (z): el corte vertical de las areas no filtra.")
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
            r.manual("Objetivo jugador: una esfera se centrara EN EL, que es lo correcto.", "npc")
        else
            r.manual("Objetivo NPC: una esfera se centrara EN TI (los NPC no responden posicion).", "npc")
            r.manual("  Para centrarla lejos, apunta a un jugador que este en el punto.", "jugador")
        end
    end
    r.manual("Lanza un area y comprueba en la ventana: distancia por objetivo y los de fuera en gris.", "npc")
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
    r.manual("Con otro jugador: que un ataque suyo te baje la vida, y que uno de fuera del", "dos")
    r.manual("  grupo y sin verte NO pueda (esto ultimo solo se puede probar con un tercero).", "dos")
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


Grupo("turnos", "bandos, bloques y quien va dentro de cada uno", function(r)
    local T = _G.HarfordTurnOrderAPI
    r.chk("el orden de turnos esta cargado", T ~= nil)
    if not T then return end

    -- Los cuatro bandos y su orden FIJO. Sin tirada: saber siempre quien va detras de quien vale
    -- mas en mesa que la sorpresa de quien empieza.
    r.chk("hay cuatro bandos", type(T.BANDOS) == "table" and #T.BANDOS == 4,
        T.BANDOS and #T.BANDOS)
    r.chk("en el orden acordado", T.BANDOS and T.BANDOS[1] == "pjs" and T.BANDOS[4] == "aliados",
        T.BANDOS and (T.BANDOS[1] .. ".." .. T.BANDOS[4]))
    -- SIN fases: el avance por bloques se retiro el 27/08 y con el las dos fases por bloque, que
    -- obligaban a pulsar `Siguiente` dos veces. Se comprueba que NO han vuelto: el turno pasa de
    -- criatura en criatura y los bloques son tarjetas, no un modo de avance.
    r.chk("y sin fases: el avance por bloques se retiro", T.FASES == nil)
    r.chk("  ni interruptor de modo", T.SetModoBandos == nil and T.IsModoBandos == nil)

    -- Un PJ no se mueve de su bando ni a mano, y el hueco COLECTIVO tampoco: su `kind` es
    -- "players", no "player", y durante un tiempo caia por reaccion 0 en enemigos.
    r.chk("un jugador va a pjs", T.GetBando and T.GetBando({ kind = "player" }) == "pjs")
    r.chk("y el hueco colectivo tambien", T.GetBando and T.GetBando({ kind = "players" }) == "pjs",
        T.GetBando and T.GetBando({ kind = "players" }))
    r.chk("y no se les puede mover", T.SetBando and T.SetBando({ kind = "players" }, "enemigos") == false)

    -- Los BLOQUES guardan a los suyos: quien esta dentro no tiene tarjeta, su vida se mira en el
    -- unitframe. Sin esto, anadir a alguien llenaba la lista de tarjetas sueltas.
    r.chk("los bloques admiten miembros", type(T.AddBlockMember) == "function")
    r.chk("y se pueden sacar", type(T.RemoveBlockMember) == "function")
    local store = _G.HarfordTurnOrderStore
    local bloques, dentro = 0, 0
    for _, e in ipairs((type(store) == "table" and store.entries) or {}) do
        local k = tostring(e.kind or "")
        if k == "players" or k == "generic" then
            bloques = bloques + 1
            dentro = dentro + #(e.miembros or {})
        end
    end
    -- Un bloque LLENO no puede parecer vacio, o el avance lo saltaria entero. Solo se comprueba si
    -- HAY bloques: que no los hayas creado no es un fallo, y marcarlo en rojo entrena a ignorar la
    -- bateria entera.
    if bloques > 0 and T.GetBandoMembers then
        local total = 0
        for _, b in ipairs(T.BANDOS or {}) do total = total + #T.GetBandoMembers(b) end
        r.chk("el avance cuenta a los bloques y a los suyos", total >= bloques,
            total .. " contados para " .. bloques .. " bloque(s) y " .. dentro .. " dentro")
    end

    if bloques == 0 then
        r.manual("No hay bloques: pulsa `PJs`/`Aliado`/`Neutral`/`Enemigo` en la ventana de turnos.", "combate")
    elseif dentro == 0 then
        r.manual("Los bloques estan vacios: click DERECHO en uno y `Anadir` con algo en el objetivo.", "npc")
    end
end)

Grupo("economia", "que la accion, la adicional y la reaccion se gasten Y bloqueen", function(r)
    local C = _G.HarfordDnDConditions
    local T = C and C.Turn
    r.chk("la economia de turno esta cargada", T ~= nil)
    if not T then return end

    -- Todo lo del turno cuelga de `IsActive`, que exige DOS cosas: que haya combate y que TU estes
    -- dentro. Estar en la raid no es estar en la pelea.
    local TO = _G.HarfordTurnOrderAPI
    local hayCombate = TO and TO.HasActiveCombat and TO.HasActiveCombat()
    local estoyDentro = TO and TO.AmIInCombat and TO.AmIInCombat()
    r.chk("se sabe si TU estas dentro", type(TO and TO.AmIInCombat) == "function")
    r.chk("y la economia lo respeta",
        (T.IsActive() == false) or (hayCombate and estoyDentro),
        "combate=" .. tostring(hayCombate) .. " dentro=" .. tostring(estoyDentro))

    -- Un gasto que NO cabe tiene que devolver false y no dejar rastro: si se apunta igual, el
    -- contador se va a negativo y el aviso es lo unico que pasa.
    r.chk("gastar devuelve si cupo", type(T.Spend) == "function")
    r.chk("y hay coste de ataque mecanizado", type(T.SpendWeaponAttack) == "function")
    r.chk("que sabe cuantos caben en una accion", type(T.AtaquesPorAccion) == "function")
    if T.AtaquesPorAccion then
        local n = T.AtaquesPorAccion()
        r.chk("uno, o dos con Ataque Extra", n == 1 or n == 2, n)
    end

    -- Sobrevive a un /reload: con la economia bloqueando, recargar seria la forma de saltarsela.
    r.chk("se guarda para sobrevivir a un /reload", type(T.RestoreFromStore) == "function")

    if not T.IsActive() then
        r.nota("Sin combate activo (o no estas en la lista): la economia no limita nada, a proposito.")
    else
        for _, k in ipairs(T.ORDEN or {}) do
            r.manual(string.format("%s: %d/%d", tostring(T.ETIQUETA[k]),
                T.GetRemaining(k), T.GetBudget(k)), "suelto")
        end
    end
end)

Grupo("movimiento", "que el contador arranque solo, mida y te ate al agotarse", function(r)
    local U = _G.HarfordDnDAttackUI
    r.chk("el seguimiento esta cargado", U ~= nil)
    if not U then return end

    -- El motor NO puede colgar del boton: WoW no ejecuta `OnUpdate` en un frame oculto, y con la
    -- ficha cerrada el contador no contaba nada sin que nada lo dijera.
    local motor = _G.HarfordMovementDriver
    r.chk("hay motor propio, fuera de la ficha", motor ~= nil)
    r.chk("y esta mostrado", motor and motor:IsShown())

    -- El oyente del turno se apunta a mano en la lista porque este fichero carga ANTES que
    -- HarfordTurns: con `RegisterMyTurnListener` no se registraba nunca.
    local TO = _G.HarfordTurnOrderAPI
    local oyentes = 0
    for _ in ipairs((TO and TO._myTurnListeners) or {}) do oyentes = oyentes + 1 end
    r.chk("alguien escucha el inicio de turno", oyentes > 0, oyentes .. " oyente(s)")

    r.chk("el tope se calcula al preguntarlo", type(U.GetTurnMovementMax) == "function")
    local tope = U.GetTurnMovementMax and U.GetTurnMovementMax() or 0
    -- Un tope de 0 esconde la barra y hace que el muro no salte nunca.
    r.chk("y no es cero", tope > 0, string.format("%.1f m", tope))
    r.chk("se puede volver al inicio del turno", type(U.ReturnToTurnStart) == "function")

    if not (TO and TO.HasActiveCombat and TO.HasActiveCombat()) then
        r.manual("Sin combate no se cuenta ni se ata: es lo correcto. Inicia un combate para probarlo.", "combate")
    else
        r.manual(string.format("Llevas %.1f m de %.1f. Anda y mira si sube solo.",
            (U.GetRecordedMovementMeters and U.GetRecordedMovementMeters()) or 0, tope), "suelto")
    end
end)

Grupo("espacios", "los espacios de conjuro y los de pacto del brujo", function(r)
    local M = _G.HarfordDnDMana
    r.chk("el modulo de mana esta cargado", M ~= nil)
    if not M then return end

    -- `IsEnabled` devuelve true con el MANA activo: la piramide es el caso CONTRARIO. Es la
    -- confusion que mas veces se ha colado al leer este modulo.
    local mana = M.IsEnabled and M.IsEnabled()
    r.chk("se sabe el modo de coste", type(M.IsEnabled) == "function")
    r.chk("y hay tabla de pacto", type(M.PACT_SLOTS) == "table")

    if mana then
        r.nota("Modo MANA: no hay orbes, a proposito. Para verlos: /harford config spell_cost_mode slots")
        return
    end
    local maxNivel = (M.GetMaxSpellLevel and M.GetMaxSpellLevel()) or 0
    if maxNivel <= 0 then
        r.nota("Sin niveles de lanzador: no hay espacios que pintar.")
        return
    end
    -- Lo que QUEDA nunca puede pasar del tope: si pasa, algo devolvio de mas.
    local descuadre = 0
    for nivel = 1, maxNivel do
        local quedan, tope = M.GetSpellSlotCurrent(nivel)
        if (tonumber(quedan) or 0) > (tonumber(tope) or 0) then descuadre = descuadre + 1 end
    end
    r.chk("ningun nivel tiene mas de lo que cabe", descuadre == 0, descuadre .. " descuadrado(s)")

    local B = _G.HarfordActionBars
    local _, orbes = B and B.RefreshTurnEconomy and B.RefreshTurnEconomy()
    r.chk("se pintan orbes", (tonumber(orbes) or 0) > 0, tostring(orbes))
    r.nota("Detalle nivel a nivel: /harford debug run espacios")
end)

Grupo("aviso", "el estandarte y el marcador de turno, y que su arte exista", function(r)
    local T = _G.HarfordTurnOrderAPI
    r.chk("el orden de turnos esta cargado", T ~= nil)
    if not T then return end

    r.chk("hay estandarte", type(T.ShowTurnBanner) == "function")
    r.chk("y se puede retirar de golpe", type(T.HideTurnBanner) == "function")
    r.chk("hay marcador permanente", type(T.RefreshTurnMarker) == "function")

    -- Un atlas que no existe NO borra la textura anterior: la deja como estaba. Por eso se
    -- comprueba antes de pintar, y por eso se comprueba aqui.
    local faltan = {}
    for _, a in ipairs({ "BossBanner-BgBanner-Top", "BossBanner-BgBanner-Mid",
                         "BossBanner-BgBanner-Bottom", "BossBanner-SkullCircle",
                         "BossBanner-RedLightning", "LootBanner-ItemBg", "LootBanner-IconGlow",
                         "AllianceScenario-TrackerHeader" }) do
        if not (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(a)) then
            faltan[#faltan + 1] = a
        end
    end
    r.chk("el arte del aviso existe en este cliente", #faltan == 0, table.concat(faltan, ", "))

    local estilo = _G.HarfordConfig and _G.HarfordConfig.Get and _G.HarfordConfig.Get("turnbanner")
    r.manual("Estilo puesto: " .. tostring(estilo)
        .. ". Verlos todos: /harford debug run banners", "suelto")
end)

Grupo("combate", "los tres estados del combate y que terminar no vacie la mesa", function(r)
    local T = _G.HarfordTurnOrderAPI
    r.chk("el orden de turnos esta cargado", T ~= nil)
    if not T then return end

    -- "Hay combate" ya no se deduce de que haya entradas: son dos preguntas distintas, y
    -- confundirlas hacia que terminar el combate y vaciar la lista fueran lo mismo.
    r.chk("el estado es explicito", type(T.GetCombatState) == "function")
    r.chk("y se distingue de tener gente montada", type(T.HasCombatants) == "function")
    local estado = T.GetCombatState and T.GetCombatState()
    local gente = T.HasCombatants and T.HasCombatants()
    r.chk("activo implica gente montada", (estado ~= "activo") or gente,
        "estado=" .. tostring(estado) .. " gente=" .. tostring(gente))

    -- Terminar recoge TODO en un sitio: si cada cosa se engancha por su cuenta, lo que se anada
    -- despues no lo limpia nadie.
    local Combate = _G.HarfordTurnsCombat
    r.chk("hay recogida de fin de combate", type(Combate and Combate.CleanUpAfterCombat) == "function")
    r.chk("y un modulo nuevo puede sumarse",
        type(Combate and Combate.RegisterCombatCleanup) == "function")

    r.manual("Estado: " .. tostring(estado or "sin combate")
        .. ". Terminar ya NO vacia la lista -- eso es `Limpiar`.", "combate")
end)

Grupo("delegar", "que un jugador sin permiso pueda pegarle a un NPC igual", function(r)
    local C = _G.HarfordDnDConditions
    r.chk("el motor de condiciones esta cargado", C ~= nil)
    if not C then return end

    r.chk("hay punto unico para aplicar", type(C.AplicarEfectoNpc) == "function")
    r.chk("y cadena de mando", type(C.CadenaDeMando) == "function")

    local puedo = C.PuedoAplicarEnNpc and C.PuedoAplicarEnNpc()
    r.chk("se sabe si puedo emitir comandos", type(puedo) == "boolean", tostring(puedo))

    local cadena = C.CadenaDeMando and C.CadenaDeMando() or {}
    -- El lider va primero porque el que aplica tiene que tener el NPC SELECCIONADO: si no, se le
    -- queda en la cola. El lider suele estar en todo; un secundario puede no mirar nunca a ese NPC.
    r.chk("la cadena se puede construir", type(cadena) == "table", #cadena .. " eslabon(es)")

    local pendientes = C.GetPendingAuraCount and C.GetPendingAuraCount() or 0
    r.chk("la cola de pendientes responde", type(pendientes) == "number", pendientes .. " en cola")

    if puedo then
        r.manual("Eres oficial de fase: TU aplicas directo y no delegas. Para probar la cadena hace "
            .. "falta un segundo cliente SIN ese permiso.", "suelto")
    elseif #cadena == 0 then
        r.chk("hay a quien delegar", false, "no estas en grupo con un lider que no seas tu")
    else
        r.manual("Pega a un NPC: deberia decir que el efecto se envio al lider.", "jugador")
    end
    if pendientes > 0 then
        r.manual("Hay " .. pendientes .. " efecto(s) esperando: selecciona a ese NPC y se aplicaran.", "npc")
    end
end)

Grupo("dotes", "que una dote sea UNA habilidad y este activada, no solo elegida", function(r)
    local P, F, B = _G.HarfordDnDProgression, _G.HarfordDnDFeats, _G.HarfordCharacterBook
    r.chk("el libro de dotes esta cargado", F ~= nil)
    if not (P and F) then return end

    -- Una dote elegida NO se aplica sola: su opcion no lleva `effects`, lo que aplica son sus
    -- rasgos, que llegan por `progression.feats`. Guardar la eleccion no basta.
    local data = P.Get and P.Get() or {}
    local lista = type(data.feats) == "table" and data.feats or {}
    local porClave = 0
    for k in pairs(lista) do if type(k) ~= "number" then porClave = porClave + 1 end end
    r.chk("`feats` es una LISTA, no un mapa", porClave == 0, porClave .. " clave(s) no numerica(s)")

    -- Una entrada por DOTE, no una por cada cosa que hace: antes "Mago de batalla" salia como tres
    -- habilidades y la dote no aparecia por su nombre.
    r.chk("hay forma de agruparlas", type(F.GetFeatAbilities) == "function")
    if F.GetFeatAbilities and #lista > 0 then
        local agrupadas = F.GetFeatAbilities(lista)
        r.chk("una entrada por dote", #agrupadas == #lista,
            #agrupadas .. " entradas para " .. #lista .. " dote(s)")
        for _, item in ipairs(agrupadas) do
            local n = item.feature and tostring(item.feature.name or "")
            r.chk("se llama 'Dote: ...'", n:find("Dote:", 1, true) == 1, n)
            r.chk("y trae su contenido",
                item.feature and #tostring(item.feature.description or "") > 0, n)
        end
    end

    -- Y que el Libro las deje pasar hasta General.
    if B and B.IsVisible and F.GetFeatAbilities and #lista > 0 then
        local visibles = 0
        for _, item in ipairs(F.GetFeatAbilities(lista)) do
            if item.feature and B.IsVisible(item.feature) then visibles = visibles + 1 end
        end
        r.chk("el Libro no las oculta", visibles == #lista, visibles .. "/" .. #lista)
    end

    if #lista == 0 then
        r.manual("Esta ficha no tiene dotes. Se eligen en la Mejora de Caracteristica (nivel 4); "
            .. "`ficha6 <clase>` monta una al azar.", "ficha")
    else
        r.manual("Abre el Libro y comprueba que sale en General como una sola entrada.", "ficha")
    end
end)

------------------------------------------------------------
-- Ejecucion
------------------------------------------------------------
-- Que hay montado AHORA MISMO, y que desbloquea cada cosa. Se dice ANTES de correr: enterarse al
-- final de que faltaba un objetivo obliga a repetir la pasada entera.
local function Preflight()
    local hayTarget = UnitExists and UnitExists("target")
    local esJugador = hayTarget and UnitIsPlayer and UnitIsPlayer("target")
        and not (UnitIsUnit and UnitIsUnit("target", "player"))
    local esNpc = hayTarget and not (UnitIsPlayer and UnitIsPlayer("target"))
    local store = _G.HarfordTurnOrderStore
    local combate = type(store) == "table" and type(store.entries) == "table" and #store.entries > 0
    local T = _G.HarfordTurnOrderAPI
    local mandas = T and T.IsTurnAdmin and T.IsTurnAdmin()

    Print("|cff00ccff--- que tienes montado ---|r")
    local function linea(ok, texto, desbloquea)
        Print(string.format("  %s %s|r  %s", ok and "|cff00ff00si " or "|cffff8800NO",
            texto, ok and "" or ("|cff808080-> " .. desbloquea .. "|r")))
    end
    linea(esNpc, "un NPC seleccionado    ", "13 comprobaciones: selecciona una criatura")
    linea(esJugador, "OTRO JUGADOR seleccionado", "5 comprobaciones: selecciona a otro jugador")
    linea(combate, "un combate montado     ", "7 comprobaciones: monta 3-4 tarjetas en Turnos")
    linea(mandas, "permiso de DM (.ph dm) ", "las de admin y el limite de 4 h de caducidad")
    if not (esNpc or esJugador) then
        Print("  |cff808080El objetivo es lo que mas desbloquea: NPC y jugador comprueban cosas")
        Print("  distintas, asi que merece la pena lanzarlo dos veces, una con cada uno.|r")
    end
    Print(" ")
end

API.RegisterCommand("verificar", function(args)
    local pedido, extra = tostring(args or ""):match("^%s*(%S*)%s*(%S*)")
    local lista = {}
    if pedido == "todo" then pedido, extra = "", extra end
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

    -- Solo en la pasada completa: para un grupo suelto sobra, ya sabes que estas montando.
    if #lista > 1 then Preflight() end

    local totalOk, totalFallos, totalManuales, totalNotas = 0, 0, 0, 0
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
        totalNotas = totalNotas + #(r.notas or {})
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
    -- Agrupadas por MONTAJE y no por grupo: lo que cuesta no es leer la comprobacion, es preparar
    -- la escena. Juntas todas las que comparten preparativo, se hacen de una tacada.
    local porMontaje = {}
    for _, d in ipairs(detalle) do
        for _, m in ipairs(d.r.manuales) do
            local clave = m.montaje or "suelto"
            porMontaje[clave] = porMontaje[clave] or {}
            porMontaje[clave][#porMontaje[clave] + 1] = "|cff808080[" .. d.nombre .. "]|r " .. m.texto
        end
    end
    for _, montaje in ipairs(MONTAJES) do
        local lista = porMontaje[montaje.clave]
        if lista and #lista > 0 then
            Print("|cffffcc00--- " .. montaje.titulo .. " (" .. #lista .. ") ---|r")
            for _, linea in ipairs(lista) do Print("  " .. linea) end
        end
    end

    -- Las NOTAS al final y aparte: informan, no son tarea pendiente.
    local hayNotas = false
    for _, d in ipairs(detalle) do
        if #(d.r.notas or {}) > 0 then
            if not hayNotas then Print("|cff808080--- notas ---|r") hayNotas = true end
            for _, n in ipairs(d.r.notas) do Print("  |cff808080[" .. d.nombre .. "]|r " .. n) end
        end
    end

    Print(string.format("TOTAL: |cff00ff00%d ok|r, |cffff3333%d fallan|r, |cffffcc00%d a mano|r, "
        .. "|cff808080%d notas|r", totalOk, totalFallos, totalManuales, totalNotas))

    -- Y ADEMAS a SavedVariables. Leerlo del chat obliga a mandar capturas, que se cortan y no se
    -- pueden buscar; en disco se lee entero. Solo la ULTIMA pasada: esto es un informe, no un log.
    -- Se vuelca al hacer `/reload` o al salir, que es cuando WoW escribe las SavedVariables.
    HarfordDebugSettings = HarfordDebugSettings or {}
    local informe = {
        cuando = date and date("%Y-%m-%d %H:%M:%S") or tostring(time and time() or 0),
        personaje = UnitName and UnitName("player") or "?",
        montaje = {
            objetivo = UnitExists and UnitExists("target") and (UnitName("target") or "?") or "ninguno",
            objetivoEsJugador = (UnitExists and UnitExists("target") and UnitIsPlayer
                and UnitIsPlayer("target")) and true or false,
            combatientes = (type(_G.HarfordTurnOrderStore) == "table"
                and type(_G.HarfordTurnOrderStore.entries) == "table")
                and #_G.HarfordTurnOrderStore.entries or 0,
            mandas = (_G.HarfordTurnOrderAPI and _G.HarfordTurnOrderAPI.IsTurnAdmin
                and _G.HarfordTurnOrderAPI.IsTurnAdmin()) and true or false,
        },
        total = { ok = totalOk, fallan = totalFallos, aMano = totalManuales, notas = totalNotas },
        grupos = {},
    }
    for _, d in ipairs(detalle) do
        local g = { nombre = d.nombre, ok = d.r.ok, fallos = {}, aMano = {}, notas = {} }
        for _, f in ipairs(d.r.fallos) do g.fallos[#g.fallos + 1] = SinColor(f) end
        for _, m in ipairs(d.r.manuales) do
            g.aMano[#g.aMano + 1] = (m.montaje or "suelto") .. ": " .. SinColor(m.texto)
        end
        for _, n in ipairs(d.r.notas or {}) do g.notas[#g.notas + 1] = SinColor(n) end
        informe.grupos[#informe.grupos + 1] = g
    end
    HarfordDebugSettings.ultimaVerificacion = informe
    Print("|cff808080Guardado en SavedVariables (HarfordDebugSettings.ultimaVerificacion). "
        .. "Haz /reload y ya se puede leer del disco: no hace falta captura.|r")
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
    -- Los estados se publican por PARTY/RAID. Sin grupo, `BestChannel` devuelve nil y
    -- `PublishState` se sale sin mandar NADA: el estado se aplica solo en el cliente que lo
    -- recibe y nadie mas lo ve. Callarselo hace parecer que la sincronizacion esta rota.
    if esJugador and ok then
        local canal = HarfordSync and HarfordSync.BestChannel and HarfordSync.BestChannel()
        if canal then
            Print("Confirma en el OTRO cliente que le ha llegado (se publica por " .. canal .. ").")
        else
            Print("|cffffcc00No estas en grupo: el estado NO se publica a nadie mas.|r")
            Print("  Los estados viajan por PARTY/RAID. Formad grupo y repite.")
        end
    end
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
    -- Lo que ha LLEGADO frente a lo que se PINTA. Un estado puede estar en el almacen y no salir
    -- en la lista de activos: los que llevan aura exigen que el aura este de verdad en la unidad,
    -- y si el receptor no la ve, descarta el registro. Sin ver las dos listas, "no llega" y "llega
    -- y se descarta" son indistinguibles, y se arreglan de forma muy distinta.
    local guid = UnitGUID and UnitGUID(unit)
    local nombre = HarfordClassColors and HarfordClassColors.UnitFullName
        and HarfordClassColors.UnitFullName(unit)
    local cubo = C.State and C.State.units
        and ((guid and C.State.units[guid]) or (nombre and C.State.units[nombre])
             or (UnitIsUnit and UnitIsUnit(unit, "player") and C.State.units.player))
    local guardados = 0
    for id, rec in pairs(cubo or {}) do
        guardados = guardados + 1
        local def = C.DEFS and C.DEFS[id]
        local origen = rec.authority and "propio" or "|cff66ccffremoto|r"
        local aura = ""
        if def and def.auraId then
            local tiene = false
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                for i = 1, 40 do
                    local a = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
                        or C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
                    if not a then break end
                    if a.spellId == def.auraId then tiene = true break end
                end
            end
            aura = tiene and "  aura SI" or "  |cffff3333aura NO -> se descarta|r"
        end
        Print(string.format("  guardado: %-20s %s%s", id, origen, aura))
    end
    Print("  registros en el almacen: " .. guardados)

    local tira = _G["HarfordEstados" .. unit]
    local frame = _G[(unit == "focus" and "FocusFrame" or "TargetFrame")]
    if not tira then Print("la tira no existe todavia"); return end
    Print(string.format("tira: %s  base=%.0f  frame arriba=%.0f  %s",
        tira:IsShown() and "visible" or "oculta",
        tira:GetBottom() or -1, (frame and frame:GetTop()) or -1,
        (tira:GetBottom() and frame and frame:GetTop() and tira:GetBottom() >= frame:GetTop())
            and "|cff00ff00por encima|r" or "|cffff3333NO esta por encima|r"))

    -- "Visible y en su sitio" no basta: puede estar transparente, de tamano cero, fuera de la
    -- pantalla o tapada. Se vuelca todo lo que puede hacer que no se vea, para no adivinar.
    Print(string.format("  tamano=%.0fx%.0f  alfa=%.2f  escala=%.2f  strata=%s  nivel=%d",
        tira:GetWidth() or 0, tira:GetHeight() or 0, tira:GetAlpha() or 0,
        tira:GetEffectiveScale() or 0, tostring(tira:GetFrameStrata()), tira:GetFrameLevel() or 0))
    local alto = UIParent and UIParent:GetHeight() or 0
    local arriba = tira:GetTop() or 0
    Print(string.format("  arriba=%.0f  alto de UIParent=%.0f  %s", arriba, alto,
        (arriba > alto) and "|cffff3333SE SALE POR ARRIBA|r" or "dentro de la pantalla"))
    local pintados = 0
    for i, b in ipairs(tira.iconos or {}) do
        if b:IsShown() then
            pintados = pintados + 1
            if i <= 3 then
                local tex = b.icon and b.icon.GetTexture and b.icon:GetTexture()
                Print(string.format("  icono %d: %.0fx%.0f  alfa=%.2f  textura=%s", i,
                    b:GetWidth() or 0, b:GetHeight() or 0, b:GetAlpha() or 0,
                    tex and tostring(tex) or "|cffff3333SIN TEXTURA|r"))
            end
        end
    end
    Print("  iconos pintados: " .. pintados .. " de " .. #(tira.iconos or {}))
end, "vuelca la tira de estados del objetivo: tira [target|focus]")
