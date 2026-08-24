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

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
