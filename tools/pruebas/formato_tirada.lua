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



-- El bono del arma en la etiqueta se colorea con el MISMO criterio que el resto de bonos.
print("Bonos coloreados: verde suma, rojo resta")
local rolls = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")
local dnd = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("el criterio es publico", rolls:find("HarfordDnDRolls.ColorSigned = ColorSigned", 1, true) ~= nil, true)
chk("el bono de arma lo usa", dnd:find("HarfordDnDRolls.ColorSigned(wmod)", 1, true) ~= nil, true)

-- Migrar la ficha de OTRO no debe anunciar nada: el aviso hablaba en primera persona.
print("La migracion calla cuando la ficha no es tuya")
local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("Migrate acepta silencio", prog:find("local function Migrate(data, silencioso, slot)", 1, true) ~= nil, true)
-- El tercer parametro es el hueco del PERFIL: los usos por descanso viven ahi, no en la
-- progresion, asi que sin el no se les puede renombrar nada.
chk("y el hueco del perfil, para los usos por descanso",
    prog:find("slot._featureUses = nuevo", 1, true) ~= nil, true)
chk("el aviso lo respeta", prog:find("if total > 0 and not silencioso", 1, true) ~= nil, true)
chk("inspeccion migra en silencio",
    prog:find("Migrate(CopyTable(data), true)", 1, true) ~= nil, true)

-- La marca del NPC ocupa bytes aunque solo se vea una calavera. Antes provocaba un
-- recorte dentro del hyperlink del ataque en la copia recibida por el otro jugador.
HarfordDnDStore = { ToNumber = function(n, defecto) return tonumber(n) or defecto end }
function strsplit(sep, texto)
    local partes = {}
    for campo in (texto .. sep):gmatch("(.-)" .. sep) do partes[#partes + 1] = campo end
    return (unpack or table.unpack)(partes)
end
dofile("Harford/Core/HarfordSync.lua")
dofile("Harford/DnD/Engine/HarfordDnDRolls.lua")
local R = HarfordDnDRolls
local original = {
    type = "attack", player = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14|t Horror de la Pesadilla",
    nameColor = "ff0000", total = 24, dice = "18", modifiers = "+6 vs CA 18 |cff00ff00EXITO|r",
    critical = "EXITO", label = "Ataque |cffffd100|Htotalrp3:Griker-Epsilon:123456789012345678901234567890|h[Garras de Pesadilla]|h|r |cffffcc00Cody|r",
}
local rutaLib = "G:/Epsilon/_retail_/Interface/AddOns/EpsilonLib/Lib/LibDeflate/LibDeflate.lua"
local hay = io.open(rutaLib)
if hay then
    hay:close()
    LibDeflate = dofile(rutaLib)
    local payload = R.Serialize(original)
    local vuelta = R.Deserialize(payload)
    chk("la tirada marcada cabe", #payload <= 240, true)
    chk("el ataque llega completo con su enlace", vuelta and vuelta.label, original.label)
    chk("la calavera y el nombre llegan completos", vuelta and vuelta.player, original.player)
    chk("el total no cambia", vuelta and vuelta.total, 24)
    chk("el desenlace no cambia", vuelta and vuelta.critical, "EXITO")
    local nombreBase = "Horror de la Pesadilla"
    for marca = 0, 8 do
        original.player = marca == 0 and nombreBase or
            ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marca .. ":14:14|t " .. nombreBase)
        local recibido = R.Deserialize(R.Serialize(original))
        local salida
        DEFAULT_CHAT_FRAME = { AddMessage = function(_, texto) salida = texto end }
        R.DisplayInChat(original)
        local localTexto = salida
        R.DisplayInChat(recibido)
        chk("chat local y remoto iguales, marca " .. marca, salida == localTexto, true)
    end
else
    print("Compresion real saltada: falta LibDeflate del cliente")
end
LibDeflate = nil
local vuelta = R.Deserialize(R.Serialize(original))
local _, marcas = vuelta.label:gsub("|h", "")
chk("sin compresion no queda medio hyperlink", marcas % 2, 0)
chk("sin compresion no queda cabecera abierta",
    vuelta.label:match("|H[^|]*$") == nil, true)
chk("sin compresion conserva el total", vuelta.total, 24)
chk("sin compresion conserva el nombre del ataque",
    vuelta.label:find("[Garras de Pesadilla]", 1, true) ~= nil, true)
chk("el recorte no deja una textura abierta",
    R.NetworkLabel(string.rep("x", 185) .. "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14|t"):find("|T", 1, true), nil)
chk("el recorte no parte una letra UTF-8",
    R.NetworkLabel(string.rep("x", 199) .. "\195\177"), string.rep("x", 199))

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
