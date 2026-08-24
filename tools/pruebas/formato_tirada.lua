-- FORMATO UNICO de las lineas de tirada.
--
-- Todas siguen el mismo orden y ningun sitio compone el suyo: etiqueta, total, detalle entre
-- parentesis y desenlace al final. Lo que separa las partes es el COLOR, no la puntuacion -- por eso
-- no hay ":" antes del total.
--
-- El desenlace va ULTIMO porque es lo que se busca al leer la linea, y porque asi la de fabricar
-- (que pedia "CD 16 10 (7+3) FALLO") sale del formato generico en vez de tener el suyo propio.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("El render compone la linea en ese orden y sin dos puntos")
chk("desenlace al final", src:find("labelStr .. damageTypeStr .. detailStr .. critStr", 1, true) ~= nil, true)
chk("sin ':' antes del total",
    src:find('(data.label or "Tirada") .. " "', 1, true) ~= nil, true)
chk("la paleta es unica y publica", src:find("HarfordDnDRolls.COLORS = {", 1, true) ~= nil, true)

print("Nadie compone su propia linea de tirada")
local sospechosos = {}
for _, ruta in ipairs({
    "Harford/Professions/HarfordProfessions.lua",
    "Harford/DnD/Engine/HarfordDnDManeuvers.lua",
    "Harford/DnD/Engine/HarfordDnDConcentration.lua",
}) do
    local s = io.open(ruta):read("*a")
    -- Una tirada emitida como `info` con el total metido en la etiqueta es una linea a medida.
    if s:find('type = "info"', 1, true) and s:find("COLORS.roll", 1, true) then
        sospechosos[#sospechosos + 1] = ruta
    end
end
for _, r in ipairs(sospechosos) do print("     compone su propia linea: " .. r) end
chk("ninguno", #sospechosos, 0)

print("El detalle no repite que era un d20: ya se ve que son los dados")
for _, ruta in ipairs({
    "Harford/Professions/HarfordProfessions.lua",
    "Harford/DnD/Engine/HarfordDnDManeuvers.lua",
    "Harford/DnD/Engine/HarfordDnDConcentration.lua",
}) do
    local s = io.open(ruta):read("*a")
    chk(ruta:match("([^/]+)%.lua$"), s:find('"d20: "', 1, true) == nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
