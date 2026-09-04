-- FICHAS ANTIGUAS: al subir de nivel se ACOPLAN a la mecanica nueva. Los efectos ya se
-- derivan en vivo del libro (eso no necesita nada), pero una eleccion que no existia cuando
-- se creo el personaje (una dote que hoy es `choice`, un rasgo racial nuevo) quedaba
-- "pendiente" sin superficie donde resolverla: la subida ahora la lista, la exige y la
-- persiste por el mismo bucle que las demas.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local adv = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")

print("La subida recoge las elecciones pendientes de TODA la ficha")
chk("recorre la ficha viva, no solo el nivel nuevo",
    adv:find("ELECCIONES PENDIENTES DE TU FICHA", 1, true) ~= nil
    and adv:find("HarfordDnDProgression.GetUnlockedFeatures() or {}", 1, true) ~= nil, true)
chk("solo huecos sin rellenar (compara con el slot map vivo)",
    adv:find("puestas < slots", 1, true) ~= nil, true)
chk("los marcadores de subclase no cuentan",
    adv:find("not f.subclassMarker", 1, true) ~= nil, true)
chk("lo ya elegido se siembra (solo pide el resto)",
    adv:find("if #previa > 0 then S.choiceSelections[f.id] = previa end", 1, true) ~= nil, true)
chk("bloquean y persisten como las demas (pendingFeatures)",
    adv:find("S.pendingFeatures[#S.pendingFeatures + 1] = f", 1, true) ~= nil, true)
chk("solo en subida, no en creacion",
    adv:find("if IsLevelUpMode() and HarfordDnDProgression and HarfordDnDProgression.GetUnlockedFeatures then", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
