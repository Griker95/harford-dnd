-- LA BATERIA DE VERIFICACION EN JUEGO.
--
-- Las suites de aqui corren FUERA de WoW y solo ven el codigo. Lo que no pueden ver es el cliente:
-- si un icono existe de verdad, si un frame se ancla donde toca, si un estado llega al cliente de
-- otro jugador. Para eso esta `/harford debug run verificar`, y esto comprueba que exista y que no
-- se autoengane.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local v = io.open("HarfordDebug/HarfordDebugVerify.lua"):read("*a")
local toc = io.open("HarfordDebug/HarfordDebug.toc"):read("*a")

print("Existe y esta enganchada")
chk("el fichero se carga", toc:find("HarfordDebugVerify.lua", 1, true) ~= nil, true)
chk("registra el comando", v:find('API.RegisterCommand("verificar"', 1, true) ~= nil, true)
-- Regla del proyecto: los diagnosticos van en HarfordDebug, nunca en modulos de gameplay.
chk("y no se cuela en el core", io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
    :find("RegisterCommand", 1, true), "nil")

-- La lista de grupos NO se escribe aqui: se lee del fichero. Una lista a mano se queda vieja al
-- anadir un grupo, y entonces la prueba deja de proteger justo lo nuevo.
local grupos = {}
for nombre in v:gmatch('Grupo%("([a-z_]+)"') do grupos[#grupos + 1] = nombre end
print("Hay grupos, y cada uno cumple el contrato")
chk("hay grupos", #grupos > 0, true)

-- Todo grupo tiene que aparecer en la ayuda del comando, o nadie sabra que existe.
local ayuda = v:match('end, "bateria de verificacion en juego %[(.-)%]"') or ""
if ayuda == "" then
    ayuda = v:match('end, "bateria de verificacion en juego %[([^"]+)') or ""
end
local sinAyuda = {}
for _, g in ipairs(grupos) do
    if not ayuda:find(g, 1, true) then sinAyuda[#sinAyuda + 1] = g end
end
chk("todos salen en la ayuda del comando", #sinAyuda, 0)
for _, g in ipairs(sinAyuda) do print("     falta en la ayuda: " .. g) end

-- Y todo grupo tiene que COMPROBAR algo. Uno que solo imprima instrucciones da la sensacion de
-- estar verificando sin verificar nada, que es peor que no tenerlo.
local sinChk = {}
for _, g in ipairs(grupos) do
    local ini = v:find('Grupo("' .. g .. '"', 1, true)
    local sig = v:find('Grupo("', ini + 10, true) or #v
    if not v:sub(ini, sig):find("r.chk(", 1, true) then sinChk[#sinChk + 1] = g end
end
chk("todos comprueban algo, no solo instruyen", #sinChk, 0)
for _, g in ipairs(sinChk) do print("     solo instruye: " .. g) end

-- La red no necesita otro cliente para comprobar que el mensaje se COMPONE y se vuelve a leer. Solo
-- para ver si llega. Antes el grupo entero era manual por no distinguir esas dos cosas.
print("La red se comprueba sola hasta donde se puede")
chk("ida y vuelta de una tirada", v:find("R.Deserialize(R.Serialize(original))", 1, true) ~= nil, true)
-- Ya hubo un fallo mudo: una etiqueta larga pasaba de 255 bytes y SendAddonMessage la descartaba.
chk("el limite de bytes se mide", v:find("#payload <= 240", 1, true) ~= nil, true)
chk("los separadores sobreviven al texto", v:find("con ^ y | y % dentro", 1, true) ~= nil, true)
chk("la contienda viaja con las dos habilidades",
    v:find('skill == "Atletismo/Acrobacias"', 1, true) ~= nil, true)
chk("y la peticion de estado tambien", v:find("S.DeserializeConditionRequest(", 1, true) ~= nil, true)

-- Ejecutar una accion la ANUNCIA por chat, asi que no puede ser lo que pasa por defecto.
print("Ejecutar acciones es opt-in, y solo las que se resuelven en uno mismo")
chk("hace falta pedirlo", v:find('if extra ~= "ejecutar" then', 1, true) ~= nil, true)
chk("y se avisa del ruido", v:find("anuncia cada una por chat", 1, true) ~= nil, true)
chk("preparar comprueba los DOS clics",
    v:find("preparar: el segundo clic lo retira", 1, true) ~= nil, true)
-- Fingir un clic de menu no comprobaria el menu.
chk("las de menu no se fingen",
    v:find("no se automatizan: usa /harford debug run accion", 1, true) ~= nil, true)

-- Lo que el cliente no puede comprobar NO se cuenta como aprobado. Una verificacion que se da por
-- buena sin mirarla es peor que no tenerla: da una seguridad que no existe.
print("Lo que no puede comprobar lo dice, no lo aprueba")
chk("tiene categoria propia", v:find("r.manual(", 1, true) ~= nil, true)
chk("se cuenta aparte del ok", v:find("totalManuales = totalManuales + #r.manuales", 1, true) ~= nil, true)
chk("y se avisa al final",
    v:find("Lo marcado 'a mano' NO esta verificado", 1, true) ~= nil, true)

print("Un grupo que revienta no se lleva a los demas")
chk("cada grupo va en pcall", v:find("local ok, err = pcall(GRUPOS[nombre], r, extra)", 1, true) ~= nil, true)
chk("y el reventon cuenta como fallo", v:find('r.fallos[#r.fallos + 1] = "el grupo reviento: "', 1, true) ~= nil, true)

-- Aplicar un estado CON aura lanzaria comandos de servidor y le pondria quince auras encima a quien
-- verifica. El ciclo solo se prueba con los que no la llevan.
print("No tiene efectos secundarios sobre quien la ejecuta")
chk("solo estados sin aura", v:find('if def.tracking == "state" and not def.auraId then', 1, true) ~= nil, true)
chk("y no toca los que ya estaban puestos", v:find("if not yaEstaba then", 1, true) ~= nil, true)
chk("la tira restaura lo que encontro", v:find("if C and C.RemoveFromUnit and not tenia then", 1, true) ~= nil, true)

print("Comprueba lo que las suites de fuera NO pueden")
-- Un icono inventado sale VERDE en Epsilon y desde fuera no hay forma de saberlo.
chk("que los iconos existan de verdad", v:find("GetFileIDFromPath(ruta)", 1, true) ~= nil, true)
chk("que la tira quede por encima del frame",
    v:find("tira:GetBottom() >= frame:GetTop()", 1, true) ~= nil, true)
chk("y nombra el icono roto, no solo la cuenta",
    v:find('r.chk("icono inexistente: " .. tostring(id), false, icono)', 1, true) ~= nil, true)

-- Los comandos de apoyo montan la escena de lo que la bateria no puede comprobar sola.
print("Comandos de apoyo para la sesion")
for _, c in ipairs({ "accion", "estadoen", "tira" }) do
    chk(c, v:find('API.RegisterCommand("' .. c .. '"', 1, true) ~= nil, true)
end
-- Una via de prueba que no pase por donde pasa el jugador no prueba lo que hay que probar.
chk("la accion va por la ruta del boton",
    v:find("P.RunBasicAction(id)", 1, true) ~= nil, true)
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
chk("y esa ruta es la misma", panel:find("return AbrirAccionBasica(actionId, anchor)", 1, true) ~= nil, true)
-- `conditiontest` solo opera sobre uno mismo, y lo que suele fallar es el salto al otro cliente.
chk("estadoen usa la ruta de red", v:find('C.ApplyToUnit("target", id', 1, true) ~= nil, true)
chk("y avisa de donde confirmarlo",
    v:find("Confirma en el OTRO cliente", 1, true) ~= nil, true)
-- Separa "el estado no esta" de "el estado esta pero no se ve": son dos fallos distintos.
chk("tira distingue estado de pintado",
    v:find("la tira no existe todavia", 1, true) ~= nil, true)

-- ATAQUE trabaja sobre EL OBJETIVO QUE YA HAY: no se puede cambiar de objetivo por comando, asi
-- que se selecciona antes y se ejecuta despues. Y NPC y jugador son dos caminos distintos.
print("Ataque: sobre el objetivo actual, y distinguiendo NPC de jugador")
chk("no intenta cambiar de objetivo", v:find("TargetUnit(", 1, true), "nil")
chk("dice que hay que seleccionar antes",
    v:find("Selecciona un NPC o un jugador y repite", 1, true) ~= nil, true)
chk("distingue quien es", v:find('UnitIsPlayer and UnitIsPlayer("target")', 1, true) ~= nil, true)
chk("y lo dice en la salida", v:find('(esJugador and "JUGADOR" or "NPC")', 1, true) ~= nil, true)
-- Contra jugador el dano viaja en bruto; contra NPC lo aplica el atacante y hace falta permiso.
chk("contra jugador comprueba el paquete de dano",
    v:find("K.PayloadFor, \"target\"", 1, true) ~= nil, true)
chk("contra NPC comprueba el permiso de oficial",
    v:find("A.CanUseOfficerCommands()", 1, true) ~= nil, true)
-- Sin CA no hay veredicto, y eso se lee como "no funciona" si no se explica.
chk("sin CA explica que mirar", v:find("sin CA: mira su TRP3 o ponla a mano", 1, true) ~= nil, true)
-- El empate lo gana el defensor, y se comprueba contra la CA REAL del que tienes delante.
chk("comprueba el empate con la CA real",
    v:find('K.ResolveArmorClassOutcome(ca, "", "target")', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
