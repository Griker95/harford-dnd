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

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
