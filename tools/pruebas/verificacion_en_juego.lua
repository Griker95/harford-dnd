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

print("Cubre los seis grupos")
for _, g in ipairs({ "iconos", "estados", "acciones", "tira", "red", "libro" }) do
    chk(g, v:find('Grupo("' .. g .. '"', 1, true) ~= nil, true)
end

-- Lo que el cliente no puede comprobar NO se cuenta como aprobado. Una verificacion que se da por
-- buena sin mirarla es peor que no tenerla: da una seguridad que no existe.
print("Lo que no puede comprobar lo dice, no lo aprueba")
chk("tiene categoria propia", v:find("r.manual(", 1, true) ~= nil, true)
chk("se cuenta aparte del ok", v:find("totalManuales = totalManuales + #r.manuales", 1, true) ~= nil, true)
chk("y se avisa al final",
    v:find("Lo marcado 'a mano' NO esta verificado", 1, true) ~= nil, true)

print("Un grupo que revienta no se lleva a los demas")
chk("cada grupo va en pcall", v:find("local ok, err = pcall(GRUPOS[nombre], r)", 1, true) ~= nil, true)
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

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
