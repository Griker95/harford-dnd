-- Rasgos que actuan SOBRE EL ULTIMO CONJURO ya lanzado.
--
-- Caos apunta a una segunda criatura; Quemar alma: Rebotar lo redirige si fallo. Ninguno relanza el
-- conjuro -- ya se pago -- : vuelven a resolver su efecto contra otro objetivo a cambio de un
-- fragmento de alma. Sin registrar el lanzamiento no habia nada a lo que agarrarse, y por eso los
-- dos se quedaron sin mecanizar.
local cargar = loadstring or load
local src = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
local i = assert(src:find("local VENTANA_ULTIMO_CONJURO", 1, true))
local j = assert(src:find("function API.ResolveCast", i, true))
local codigo = "local API, HarfordDnDArea, HarfordDnDRolls, UnitGUID, UnitName, time = ...\n"
    .. src:sub(i, j - 1) .. "\nreturn API"

local abiertos = {}
local Area = { Open = function(def) abiertos[#abiertos + 1] = def; return true end }
local ahora = 1000
local API = {}
local env = { type = type, tostring = tostring, pairs = pairs }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
f(API, Area, { GetDisplayName = function() return "Brujo" end },
  function() return "guid" end, function() return "Brujo" end, function() return ahora end)

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-30s %s", etiqueta, "'" .. tostring(real) .. "'",
        ok and "ok" or ("FALLA, esperaba '" .. tostring(esp) .. "'")))
end

print("Sin conjuro reciente no hay nada que redirigir")
local ok, err = API.RecastLastSingleTarget("caos", "Caos")
chk("rechazado", ok, false)
chk("motivo", err, "No has lanzado ningun conjuro de objetivo unico")

print("Con uno registrado, se vuelve a resolver contra otro objetivo")
API._ultimoConjuroUnico = { spellId = "rayo_enfermedad", nombre = "Rayo de enfermedad",
    definicion = { label = "Rayo de enfermedad", networkLabel = "Rayo de enfermedad" },
    castLevel = 1, cuando = 1000 }
abiertos = {}
local ok2, nombre = API.RecastLastSingleTarget("caos", "Caos")
chk("aceptado", ok2, true)
chk("dice cual", nombre, "Rayo de enfermedad")
chk("se abre una resolucion", #abiertos, 1)
chk("etiquetada con el rasgo", abiertos[1].label, "Caos: Rayo de enfermedad")

print("  -- y no dos veces con el MISMO rasgo:")
local ok3, err3 = API.RecastLastSingleTarget("caos", "Caos")
chk("rechazado", ok3, false)
chk("motivo", err3, "Ya lo usaste sobre ese conjuro")

print("  -- pero otro rasgo distinto si puede:")
local ok4 = API.RecastLastSingleTarget("rebotar", "Quemar alma: Rebotar")
chk("aceptado", ok4, true)
chk("con su etiqueta", abiertos[#abiertos].label, "Quemar alma: Rebotar: Rayo de enfermedad")

print("Un conjuro viejo ya no vale")
ahora = 1000 + 200
API._ultimoConjuroUnico = { spellId = "x", nombre = "X", definicion = {}, cuando = 1000 }
local ok5, err5 = API.RecastLastSingleTarget("caos", "Caos")
chk("rechazado", ok5, false)
chk("motivo", err5, "Ese conjuro es de hace demasiado")

print("No se toca la definicion original: se resuelve sobre una copia")
ahora = 1000
local original = { label = "Original", networkLabel = "Original" }
API._ultimoConjuroUnico = { nombre = "Original", definicion = original, cuando = 1000 }
API.RecastLastSingleTarget("caos", "Caos")
chk("la original conserva su etiqueta", original.label, "Original")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
