-- La migracion guarda una COPIA de la ficha antes de tocarla.
--
-- Reescribe la ficha en el sitio, corre sola al primer acceso y no se puede repetir: si un
-- renombrado sale mal, el rasgo desaparece sin dar error y sin nada a lo que volver. Depender de
-- que el jugador copiase el WTF a mano no es una red, es una esperanza.
local cargar = loadstring or load
local src = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("La copia se toma ANTES de migrar, no despues")
local iCopia = src:find("previo = CopyTable(limpio)", 1, true)
local iRenombra = src:find("RenombrarClaves(data[campo])", 1, true)
local iGuarda = src:find("data._previo = {", 1, true)
chk("se copia antes de renombrar", (iCopia and iRenombra and iCopia < iRenombra) and true or false, true)
chk("se guarda despues de renombrar", (iGuarda and iRenombra and iGuarda > iRenombra) and true or false, true)

print("No se encadenan copias de copias")
chk("la copia excluye la copia anterior", src:find('if k ~= "_previo" then', 1, true) ~= nil, true)

print("Solo se copia si hay migracion que hacer")
chk("condicionada al esquema", src:find("if oldSchema < SCHEMA_VERSION then", 1, true) ~= nil, true)

print("Hay como consultarla y como volver a ella")
chk("consulta", src:find("function API.GetPreviousProgression", 1, true) ~= nil, true)
chk("restauracion", src:find("function API.RestorePreviousProgression", 1, true) ~= nil, true)
local dbg = io.open("HarfordDebug/HarfordDebug.lua"):read("*a")
chk("comando", dbg:find('RegisterCommand("fichaprevia"', 1, true) ~= nil, true)

print("Y el aviso dice que existe")
chk("el mensaje la nombra", src:find("Se ha guardado una copia de la ficha anterior", 1, true) ~= nil, true)



-- Lo que de verdad no se puede perder es el ABOUT de TRP3: es lo unico de la ficha que escribe el
-- JUGADOR (su lore, sus notas, sus frames) y que Harford reescribe. La progresion se rehace
-- subiendo de nivel otra vez; un About perdido no sale de ningun sitio.
print("El About se copia antes de sobrescribirlo")
local trp = io.open("Harford/TRP3/HarfordTRP3.lua"):read("*a")
local iPrev = trp:find("local prev = type(profile.player.about)", 1, true)
local iCopia = trp:find("API.SavePreviousAbout(prev)", 1, true)
-- El punto destructivo no es una reasignacion: es el vaciado in-place del About.
local iEscribe = trp:find("for key in pairs(about) do about[key] = nil end", 1, true)
chk("la copia se toma antes de escribir",
    (iCopia and iEscribe and iCopia < iEscribe) and true or false, true)
chk("y despues de leer el About actual",
    (iPrev and iCopia and iPrev < iCopia) and true or false, true)
chk("guardar", trp:find("function API.SavePreviousAbout", 1, true) ~= nil, true)
chk("consultar", trp:find("function API.GetPreviousAbout", 1, true) ~= nil, true)
chk("restaurar", trp:find("function API.RestorePreviousAbout", 1, true) ~= nil, true)
chk("restaurar no comparte tabla con la copia",
    trp:find("profile.player.about = CopiaProfunda(prev.datos)", 1, true) ~= nil, true)
local dbg2 = io.open("HarfordDebug/HarfordDebug.lua"):read("*a")
chk("comando", dbg2:find('RegisterCommand("aboutprevio"', 1, true) ~= nil, true)

print("La migracion de ids vuelve a ser automatica")
chk("sin cuadro de permiso", src:find("HARFORD_MIGRAR_IDS", 1, true) == nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
