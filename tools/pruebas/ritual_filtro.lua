-- Que conjuros ofrece "Ritos de alma": rituales de tu clase que YA puedas lanzar.
--
-- El rasgo dice "un conjuro de brujo con etiqueta de ritual, siempre que dispongas del nivel de
-- lanzamiento necesario". Ofrecer uno de nivel 5 a un brujo de nivel 3 seria dejarle gastar el
-- fragmento en algo que no puede lanzar.
local cargar = loadstring or load
local src = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))
local i = assert(src:find("        local elegibles = {}", 1, true))
local j = assert(src:find("        if #elegibles == 0 then", i, true))
local codigo = "local api, spec, maximo, clase = ...\n" .. src:sub(i, j) .. "\nreturn elegibles"

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-46s %-28s %s", etiqueta, "'" .. tostring(real) .. "'",
        ok and "ok" or ("FALLA, esperaba '" .. tostring(esp) .. "'")))
end

local CONJUROS = {
    { id = "identificar",   name = "Identificar",   level = 1, ritual = true,  classes = { "Brujo", "Mago" } },
    { id = "alarma",        name = "Alarma",        level = 1, ritual = true,  classes = { "Mago" } },
    { id = "descarga_vil",  name = "Descarga vil",  level = 1, ritual = false, classes = { "Brujo" } },
    { id = "caminar_agua",  name = "Caminar",       level = 3, ritual = true,  classes = { "Brujo" } },
    { id = "puerta_lejana", name = "Puerta",        level = 5, ritual = true,  classes = { "Brujo" } },
}
local api = { GetAllSpells = function() return CONJUROS end }
local env = { ipairs = ipairs, tonumber = tonumber, tostring = tostring, table = table }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end

local function ofrecidos(maximo)
    local out = {}
    for _, s in ipairs(f(api, {}, maximo, "Brujo")) do out[#out + 1] = s.id end
    return table.concat(out, ",")
end

print("Solo rituales, solo de tu clase, solo de nivel que puedas lanzar")
chk("brujo que llega a nivel 1", ofrecidos(1), "identificar")
chk("brujo que llega a nivel 3", ofrecidos(3), "identificar,caminar_agua")
chk("brujo que llega a nivel 5", ofrecidos(5), "identificar,caminar_agua,puerta_lejana")
chk("sin nivel de lanzamiento", ofrecidos(0), "")

print("  -- y quedan fuera:")
print("     alarma        ritual, pero no es de Brujo")
print("     descarga_vil  de Brujo, pero no es ritual")

print("Ordenados por nivel, que es como se eligen")
chk("primero el de nivel 1", (f(api, {}, 5, "Brujo")[1] or {}).level, 1)
chk("ultimo el de nivel 5", (f(api, {}, 5, "Brujo")[3] or {}).level, 5)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
