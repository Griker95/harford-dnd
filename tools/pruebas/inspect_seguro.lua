-- INSPECCIONAR A OTRO NO PUEDE TOCAR TUS DATOS.
--
-- El riesgo es real y sutil: `Get(perfil)` devuelve el SNAPSHOT de inspeccion si existe para ese
-- nombre, y de ahi leen TODOS los setters. Si un snapshot pudiera existir bajo tu propio nombre,
-- cada cosa que guardaras iria a una tabla efimera y se perderia al cerrar; y si el snapshot
-- compartiera tabla con lo que llega por la red, un mensaje ajeno escribiria en tu ficha.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
local insp = io.open("Harford/Character/HarfordCharacterInspect.lua"):read("*a")
local panel = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))

-- 1. No se puede inspeccionar a uno mismo. Es la barrera que impide que un snapshot ensombrezca tu
--    propio perfil y se trague todo lo que guardes despues.
print("No se puede inspeccionar a uno mismo")
chk("se compara con tu nombre",
    insp:find("if targetName == myName or ShortName(targetName) == ShortName(myName) then", 1, true) ~= nil, true)
chk("y se rechaza", insp:find('return false, "No hace falta inspeccionar tu propio panel."', 1, true) ~= nil, true)

-- 2. El snapshot es una COPIA. Sin copiar, la tabla que llega por la red y la que usa la ficha
--    serian la misma, y cualquier escritura posterior cruzaria datos entre las dos.
print("El snapshot se copia, no se enlaza")
chk("se copia al guardarlo",
    prog:find("inspectData[key] = (type(data) == \"table\") and Migrate(CopyTable(data), true) or nil", 1, true) ~= nil, true)

-- 3. Vive en una tabla APARTE de la persistencia, y `Get` sale por ahi ANTES de tocar el perfil.
print("Vive aparte de la persistencia")
chk("hay una tabla efimera propia", prog:find("local ins = inspectData[ShortKey(name)]", 1, true) ~= nil, true)
chk("y se devuelve sin tocar el perfil",
    prog:find("if ins then return ins, name end", 1, true) ~= nil, true)
-- El comentario del propio codigo lo dice; que siga ahi es parte del contrato.
chk("declarado en el codigo",
    prog:find("modo inspeccion: snapshot efimero, sin tocar persistencia", 1, true) ~= nil, true)

-- 4. Se limpia. Un snapshot que sobreviviera al cierre seguiria ensombreciendo lecturas de ese
--    nombre en toda la sesion.
print("Se limpia al cerrar o cambiar de objetivo")
chk("hay limpieza", insp:find("function API.ClearInspectStores", 1, true) ~= nil, true)
chk("limpia progresion", insp:find("HarfordDnDProgression.ClearInspectData()", 1, true) ~= nil, true)
chk("limpia equipo", insp:find("HarfordDnDItems.ClearInspectData()", 1, true) ~= nil, true)
-- Y alguien tiene que llamarla: una limpieza que nadie invoca es peor que ninguna, porque
-- tranquiliza sin hacer nada.
local llamadas = select(2, panel:gsub("HarfordCharacterInspect.ClearInspectStores", ""))
chk("y el panel la llama", llamadas >= 1, true)

-- 5. Los snapshots caducan solos, para que un cliente que se fue no deje datos suyos indefinidamente.
print("Y caducan solos")
chk("tienen tiempo de vida", insp:find("SNAPSHOT_TTL", 1, true) ~= nil or insp:find("TTL", 1, true) ~= nil, true)

-- 6. Solo se acepta un snapshot que se haya PEDIDO. Sin esto, cualquiera podria mandarte una ficha
--    y aparecerte en el panel como si la hubieras inspeccionado.
print("Solo se acepta lo que se ha pedido")
chk("se comprueba que hubo peticion", insp:find("requestedAt", 1, true) ~= nil, true)

-- 7. En inspeccion la ficha es de SOLO LECTURA, y eso incluye no invitar a editar. La flecha de
--    seleccion de equipo se creaba una vez y se quedaba visible: ofrecia cambiarle el equipo a
--    otro jugador, que ni se puede ni tendria sentido.
print("En inspeccion no se ofrece editar el equipo")
local sheet = io.open("Harford/Character/HarfordCharacterSheet.lua"):read("*a")
chk("la flecha se guarda para poder gatearla",
    sheet:find("b.flechaEquipo = arrow", 1, true) ~= nil, true)
chk("y se oculta en inspeccion",
    sheet:find("if slot.flechaEquipo then slot.flechaEquipo:SetShown(not soloLectura) end", 1, true) ~= nil, true)
-- Se decide en cada REFRESCO, no al crearla: el panel alterna entre ficha propia e inspeccion sin
-- reconstruir los huecos, asi que decidirlo al crearla la dejaria fija para siempre.
chk("decidido en el refresco, no al crearla",
    sheet:find("local soloLectura = IsInspecting and IsInspecting()", 1, true)
    > sheet:find("local function RefreshPaperDollSlots", 1, true), true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
