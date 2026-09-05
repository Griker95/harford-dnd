-- SALIDA DE CHAT: todo mensaje visible pasa por HarfordChat.Print (prefijo unico [Harford]).
--
-- Candado del barrido de la revision de distribucion (2026-09-05): en los ficheros DISTRIBUIDOS
-- no queda ningun uso del `print` GLOBAL salvo dos excepciones declaradas:
--   1. El fallback interno del propio HarfordChat (es la implementacion).
--   2. La salida de DEBUG gateada (linea con [HarfordDebug] en fichero con un gate HARFORD_*
--      _DEBUG): diagnostico real, misma excepcion de la norma que el addon HarfordDebug, y
--      migrarla a HarfordChat.Print doblaria el prefijo.
-- OJO con el patron de sombra: HarfordLoot/Professions/QuestLog/WorldQuests/HarfordAdmin.lua
-- definen `local function print(...)` que redirige a HarfordChat.Print, asi que sus `print(...)`
-- posteriores CUMPLEN la norma — un escaner ingenuo los marcaba (7 supuestos hallazgos, 0 reales).
--
-- HarfordDebug queda fuera a proposito: es la excepcion declarada de la norma.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-64s %-6s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local ADDONS = { "Harford", "HarfordAdmin", "HarfordCompendio", "HarfordProfesiones", "HarfordMusic" }

-- Los ficheros que carga cada .toc (los no cargados no llegan al cliente y no aplican).
local function FicherosDelToc(addon)
    local toc = io.open(addon .. "/" .. addon .. ".toc")
    if not toc then return {} end
    local out = {}
    for linea in toc:lines() do
        linea = linea:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if linea ~= "" and not linea:find("^#") and linea:find("%.lua$") then
            out[#out + 1] = addon .. "/" .. linea:gsub("\\", "/")
        end
    end
    toc:close()
    return out
end

-- Usos del `print` global: fuera de comentario, sin `.`/`:`/identificador delante, no cubiertos
-- por una sombra `local function print` anterior, y sin ser debug declarado ([HarfordDebug] en
-- la linea + gate *_DEBUG en el fichero).
local function PrintsGlobales(ruta)
    local f = io.open(ruta)
    if not f then return {} end
    local t = f:read("*a")
    f:close()
    local sombra = t:find("local function print%(") or t:find("local print[^%w_]")
    local conGateDebug = t:find("HARFORD_%u+_DEBUG") ~= nil
    local hits, linea, pos = {}, 0, 1
    for line in (t .. "\n"):gmatch("(.-)\n") do
        linea = linea + 1
        local codigo = line:gsub('%-%-.*$', "")
        local ini = 1
        while true do
            local s = codigo:find("print%(", ini)
            if not s then break end
            ini = s + 1
            local previo = s > 1 and codigo:sub(s - 1, s - 1) or ""
            if not previo:find("[%w_.:]") then
                local absoluto = pos + s - 1
                local esDebug = conGateDebug and codigo:find("[HarfordDebug]", 1, true) ~= nil
                if not (sombra and absoluto > sombra) and not esDebug then
                    hits[#hits + 1] = linea
                end
            end
        end
        pos = pos + #line + 1
    end
    return hits
end

print("Ningun print global en ficheros distribuidos (salvo las excepciones declaradas)")
local ofensores = {}
for _, addon in ipairs(ADDONS) do
    for _, ruta in ipairs(FicherosDelToc(addon)) do
        if ruta ~= "Harford/Core/HarfordChat.lua" then
            local hits = PrintsGlobales(ruta)
            if #hits > 0 then
                ofensores[#ofensores + 1] = ruta .. ":" .. table.concat(hits, ",")
            end
        end
    end
end
for _, o in ipairs(ofensores) do print("   OFENSOR: " .. o) end
chk("cero usos del print global", #ofensores, 0)

-- El fallback de HarfordChat existe y es el unico estructural permitido.
local chat = io.open("Harford/Core/HarfordChat.lua"):read("*a")
chk("HarfordChat conserva su fallback", #PrintsGlobales("Harford/Core/HarfordChat.lua") > 0, true)
chk("y define Print (via su alias API)", chat:find("function API.Print(", 1, true) ~= nil, true)

-- El debug de misiones es debug DECLARADO: gateado y con su prefijo honesto.
local quests = io.open("Harford/Quests/HarfordQuests.lua"):read("*a")
chk("el debug de misiones sigue gateado",
    quests:find("if not _G.HARFORD_QOBJ_DEBUG then return end", 1, true) ~= nil, true)
chk("con su prefijo [HarfordDebug]",
    quests:find('print("|cff88ccff[HarfordDebug]|r " .. tostring(message))', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
