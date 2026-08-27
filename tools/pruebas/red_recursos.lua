-- La capa de red de la ficha: HarfordDnDNet (payloads de recursos) y HarfordDnDComm (quien puede
-- hacerte que).
--
-- Ninguno tenia prueba (12 de 12 mutaciones pasaban). Y aqui vive la unica barrera que impide que
-- un desconocido te aplique dano o un estado: un mensaje de efecto solo se acepta si el que lo
-- manda eres tu mismo o alguien que el cliente puede resolver como unidad visible o companero de
-- grupo. Sin esa comprobacion, cualquiera con el addon podria bajarte la vida.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local function cargarModulo(ruta, env)
    env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
    env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
    env.setmetatable, env.next = setmetatable, next
    local src = io.open(ruta):read("*a")
    local f
    if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
    pcall(f)
    return env
end

-- ═══ PAYLOADS DE RECURSO ════════════════════════════════════════════════════
local envN = cargarModulo("Harford/DnD/Engine/HarfordDnDNet.lua",
    setmetatable({
        HarfordDnDStore = { ToNumber = function(v, d)
            local n = tonumber(v); if n == nil then return d end; return n
        end, EnsurePersist = function() end },
        HarfordDnDResources = {
            CurKey = function(k) return k .. "_Cur" end,
            MaxKey = function(k) return k .. "_Max" end,
            Exists = function(_, cur, max) return (tonumber(max) or 0) > 0 end,
            BuildPayloadFromRuntime = function() return { health_Cur = "10" }, { "health_Cur" } end,
            BuildPayloadFromTable = function() return {} end,
        },
        HarfordDnDContext = { State = {}, Get = function(k, d) return d end },
    }, { __index = function() return nil end }))
local N = envN.HarfordDnDNet

-- La CA viaja con los recursos porque otros clientes la necesitan para resolver sus ataques
-- contra ti sin preguntartela.
print("La CA acompana siempre al payload de recursos, salvo que se pida lo contrario")
local out, claves = N.BuildActiveResourcePayload(function(k) return k == "ArmorClass" and "17" or "0" end)
chk("va la CA", out.ArmorClass, 17)
chk("y esta en la lista de claves a enviar", claves[#claves], "ArmorClass")
out = N.BuildActiveResourcePayload(function() return "17" end, { includeArmorClass = false })
chk("si se pide sin ella, no va", out.ArmorClass, "nil")
-- Sin opciones tambien va: el caso por defecto es incluirla.
out = N.BuildActiveResourcePayload(function() return "17" end, {})
chk("con opciones vacias, tambien va", out.ArmorClass, 17)

print("Lectura de la cache remota")
chk("sin tabla, cero", N.GetRemoteResourceValue(nil, "health_Cur"), 0)
chk("un valor que no es numero, cero", N.GetRemoteResourceValue({ health_Cur = "x" }, "health_Cur"), 0)
chk("y uno que si", N.GetRemoteResourceValue({ health_Cur = "23" }, "health_Cur"), 23)

-- Que un recurso EXISTA en el otro cliente no es que valga 0: es que tenga maximo. Confundirlo
-- pintaria barras vacias de recursos que ese personaje no tiene.
print("Un recurso existe si tiene maximo, no si tiene valor")
chk("sin tabla, no existe", N.RemoteResourceExists(nil, "chi"), false)
chk("con maximo, existe", N.RemoteResourceExists({ chi_Cur = "0", chi_Max = "5" }, "chi"), true)
chk("sin maximo, no", N.RemoteResourceExists({ chi_Cur = "3", chi_Max = "0" }, "chi"), false)

print("No se envia nada a un destinatario vacio")
chk("sin nombre", (N.SendResourceResponseTo("")), false)
chk("ni nulo", (N.SendResourceResponseTo(nil)), false)

-- ═══ QUIEN PUEDE HACERTE QUE ════════════════════════════════════════════════
local VISIBLES, APLICADO = {}, nil
local envC = cargarModulo("Harford/DnD/Engine/HarfordDnDComm.lua",
    setmetatable({
        HarfordClassColors = {
            FindUnitByName = function(n) return VISIBLES[n] and "party1" or nil end,
            UnitFullName = function() return "Yo-Reino" end,
        },
        UnitName = function() return "Yo" end,
        GetUnitName = function() return "Yo-Reino" end,
        UnitExists = function() return false end,
        UnitIsPlayer = function() return false end,
        -- Solo se reconoce el ajuste de recurso. Cualquier otro deserializador devuelve nil, que
        -- es lo que hace el de verdad con un mensaje que no es suyo, y el handler sigue de largo.
        HarfordSync = setmetatable({
            DeserializeResourceAdjustMessage = function(m)
                local k, d = tostring(m):match("^RADJ|([%a_]+)|(%-?%d+)$")
                if k then return k, tonumber(d) end
                return nil
            end,
        }, { __index = function() return function() return nil end end }),
    }, { __index = function() return nil end }))

local H = envC.HarfordDnDComm.CreateHandlers({
    ADDON_PREFIX = "DND5EARC",
    ApplyResourceDelta = function(k, d, quien) APLICADO = { k, d, quien } end,
    -- Lo ultimo que hace el handler con un mensaje que no reconoce es pasarselo al render de
    -- tiradas. Aqui solo hace falta que exista para llegar hasta ahi.
    HandleRollSync = function() end,
})

print("Reconocerse a uno mismo")
chk("por el nombre corto", H.IsSelfSender("Yo"), true)
chk("y por el largo con reino", H.IsSelfSender("Yo-Reino"), true)
chk("otro nombre no", H.IsSelfSender("Fulano"), false)
chk("ni uno vacio", H.IsSelfSender(""), false)
chk("ni nulo", H.IsSelfSender(nil), false)

-- Esta es la barrera. Un mensaje que BAJA LA VIDA solo se acepta de quien el cliente puede
-- resolver: tu mismo, o alguien visible o de tu grupo.
print("Un ajuste de recurso solo se acepta de quien se puede resolver")
VISIBLES, APLICADO = {}, nil
chk("de un desconocido, se ignora", H.HandleAddonMessage("DND5EARC", "RADJ|health|-10", "Desconocido"), false)
chk("y no toca la vida", APLICADO, "nil")

VISIBLES, APLICADO = { ["Companero"] = true }, nil
chk("de alguien del grupo, se acepta", H.HandleAddonMessage("DND5EARC", "RADJ|health|-10", "Companero"), true)
chk("y se aplica", APLICADO and (APLICADO[1] .. " " .. APLICADO[2]), "health -10")
chk("con el nombre de quien lo mando", APLICADO and APLICADO[3], "Companero")

APLICADO = nil
chk("de uno mismo, tambien", H.HandleAddonMessage("DND5EARC", "RADJ|health|-3", "Yo"), true)
chk("y se aplica", APLICADO and APLICADO[2], -3)

-- Un prefijo ajeno no se toca ni para mirarlo: es de otro addon.
print("Un mensaje de otro addon no se procesa")
APLICADO = nil
chk("prefijo distinto", H.HandleAddonMessage("OTROADDON", "RADJ|health|-10", "Companero"), false)
chk("y no se aplica nada", APLICADO, "nil")

-- El valor de retorno es un CONTRATO de rendimiento: true solo cuando cambia algo que los
-- overlays de unitframe pintan. Devolver true de mas repinta todos los frames en cada mensaje.
print("Solo devuelve true lo que cambia lo que se ve")
chk("un mensaje que no reconoce", H.HandleAddonMessage("DND5EARC", "ALGO|raro", "Companero"), false)

-- ─── ENTREGA POR ChatThrottleLib ────────────────────────────────────────────
-- `SendAddonMessage` a secas no dice si el mensaje salio. CTL devuelve el enum de WoW, y ahi esta
-- `NotInGroup = 5`, que es el fallo silencioso que se venia persiguiendo: `BestChannel()` a nil, o
-- un grupo del que ya no formas parte. Se guarda la causa para el diagnostico, sin avisar por chat
-- -- un aviso por cada fallo seria peor que el fallo.
local envSync = { _G = {} }
local Sync = cargarModulo("Harford/Core/HarfordSync.lua", envSync)
Sync = envSync.HarfordSync or Sync

print("Cada trafico tiene su prioridad en la cola")
-- Una tirada y un cambio de turno la mesa los espera YA. Una foto de reputacion puede esperar, y
-- no debe adelantar a una tirada.
chk("las tiradas van primero", Sync.PRIORIDAD_POR_PREFIJO.DND5EARC, "ALERT")
chk("el turno tambien", Sync.PRIORIDAD_POR_PREFIJO.HARFORDTURN, "ALERT")
chk("las fotos de reputacion esperan", Sync.PRIORIDAD_POR_PREFIJO.HARFORDREP, "BULK")
chk("y las de contratos", Sync.PRIORIDAD_POR_PREFIJO.TCBOARD, "BULK")

print("La causa del fallo se traduce, no se guarda un numero")
chk("no estar en el grupo", Sync.CAUSA_ENTREGA[5], "no estas en el grupo")
chk("saturacion", Sync.CAUSA_ENTREGA[3], "saturado")
chk("entrega buena", Sync.CAUSA_ENTREGA[0], "entregado")

print("El registro de entregas cuenta lo que pasa")
Sync.ENTREGA.ok, Sync.ENTREGA.fallos = 0, 0
Sync._AlEntregar("DND5EARC", true, 0)
Sync._AlEntregar("DND5EARC", true, 0)
chk("dos entregadas", Sync.ENTREGA.ok, 2)
chk("y ningun fallo", Sync.ENTREGA.fallos, 0)
Sync._AlEntregar("HARFORDTURN", false, 5)
chk("un fallo contado", Sync.ENTREGA.fallos, 1)
chk("con su causa en claro", Sync.ENTREGA.ultimoFallo, "no estas en el grupo")
chk("y de que trafico era", Sync.ENTREGA.ultimoPrefijo, "HARFORDTURN")
-- Un codigo que no conocemos no puede perderse: mejor "codigo 99" que nil.
Sync._AlEntregar("DND5EARC", false, 99)
chk("un codigo desconocido no se traga", Sync.ENTREGA.ultimoFallo, "codigo 99")

-- Turnos solo EMPUJABA la foto. Quien reconectaba veia su lista guardada -- de antes de caerse --
-- hasta que el DM avanzara, sin nada que le dijera que miraba algo viejo.
local turnos = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
print("Los turnos ya se pueden pedir, no solo recibir")
chk("hay peticion", turnos:find('"TREQ|"', 1, true) ~= nil, true)
chk("y quien la atiende es el DM",
    turnos:find("if IsTurnAdmin() then SendStateTo(sender) return true end", 1, true) ~= nil, true)
-- Y si el DM se ha caido no contesta NADIE, asi que quien entra se queda sin combate. Un companero
-- tiene la misma foto --se la mandaron a el igual-- y puede servirla, pero DESPUES de esperar: la
-- del DM es la buena y tiene que llegar primero si esta.
chk("y si no hay DM, releva un companero",
    turnos:find("SendStateTo(sender, true)", 1, true) ~= nil, true)
-- No contesta si desde la peticion ha pasado una foto por el canal: alguien con mas derecho ya lo
-- hizo, y dos fotos distintas serian peor que ninguna.
chk("pero no si alguien ya contesto",
    turnos:find("if (ULTIMA_FOTO_VISTA or 0) >= pedido then return end", 1, true) ~= nil, true)
-- Ni si el no tiene combate que servir.
chk("ni si no tiene combate",
    turnos:find("if not HarfordTurnOrderAPI.HasCombatants() then return true end", 1, true) ~= nil, true)
-- Por susurro: la foto completa solo le interesa a quien la pidio, no a toda la mesa.
chk("se contesta a uno solo",
    turnos:find('SendSerializedState(SerializeState(), "WHISPER", target)', 1, true) ~= nil, true)
chk("se pide al entrar en grupo",
    turnos:find('if event == "GROUP_ROSTER_UPDATE" then', 1, true) ~= nil, true)

-- Con dos DMs, dos clics seguidos eran dos seriales y el bloque saltaba DOS veces.
print("Dos DMs no avanzan el turno dos veces sin querer")
chk("se avisa del avance ajeno",
    turnos:find("acaba de avanzar el turno", 1, true) ~= nil, true)
-- Avisar y no bloquear: bloquear al segundo DM le dejaria sin poder corregir al primero.
chk("pero el segundo clic pasa",
    turnos:find("Pulsa otra vez si quieres avanzarlo igualmente", 1, true) ~= nil, true)
chk("y se anota quien avanzo", turnos:find("ultimoAvanceAjeno.quien", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
