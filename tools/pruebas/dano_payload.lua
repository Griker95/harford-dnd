-- Payload DNDDMG: ida y vuelta del dano en bruto que viaja al defensor.
-- El cuarto campo `M` (golpe magico) se anadio para Golpes empoderados por el chi; se comprueba que
-- es compatible en los DOS sentidos con clientes sin actualizar, que es lo que se rompe facil.
local cargar = loadstring or load
local desempaquetar = unpack or table.unpack
strsplit = function(sep, str)
    local out = {}
    for part in (tostring(str) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do out[#out+1] = part end
    return desempaquetar(out)
end
local src = io.open("Harford/Core/HarfordSync.lua"):read("*a")
HarfordSync = {}
-- `SerializeDamage` compacta la etiqueta con el mismo helper que las tiradas.
HarfordDnDRolls = { NetworkLabel = function(l)
    l = tostring(l or ""):gsub("(|Hitem:%d+)[^|]-|h", "%1|h")
    if #l > 200 then l = l:sub(1, 200) end
    return l
end }
for _, nombre in ipairs({ "SerializeDamage", "DeserializeDamage" }) do
    local i = src:find("function HarfordSync%." .. nombre)
    local j = src:find("\nend", i)
    assert(i and j, nombre)
    assert(cargar(src:sub(i, j + 4)))()
end
local S, D = HarfordSync.SerializeDamage, HarfordSync.DeserializeDamage
local fallos = 0
local comps = { { amount = 7, damageType = "contundente" }, { amount = 3, damageType = "frio" } }
print("ida y vuelta")
for _, mag in ipairs({ false, true }) do
    local p = S(comps, true, mag)
    local out, crit, m = D(p)
    local ok = (#out == 2 and crit == true and m == mag)
    if not ok then fallos = fallos + 1 end
    print(string.format("  magico=%-5s  %-38s -> %d comps  crit=%-5s magico=%-5s %s",
        tostring(mag), p, #out, tostring(crit), tostring(m), ok and "ok" or "FALLA"))
end
print("compatibilidad")
local out, crit, m = D("DNDDMG|7:contundente,3:frio|C")
local okv = (#out == 2 and crit and m == false)
if not okv then fallos = fallos + 1 end
print(string.format("  payload VIEJO de 3 campos -> %d comps crit=%s magico=%s  %s",
    #out, tostring(crit), tostring(m), okv and "ok" or "FALLA"))
local nuevo = S(comps, false, true)
print(string.format("  payload nuevo: %d bytes (limite 240)  %s", #nuevo, #nuevo <= 240 and "ok" or "FALLA"))
-- ─── LA ETIQUETA DEL ATACANTE VIAJA CON EL DANO ─────────────────────────────
-- La linea de dano la publica LA VICTIMA, porque solo ella conoce sus resistencias -- pero tiene
-- que salir con el nombre y el arma del ATACANTE o en la mesa no se entiende de donde viene. Por
-- eso la etiqueta va en el mensaje.
local function chk(nombre, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-46s %-8s %s", nombre, tostring(real):sub(1,8),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
print("La etiqueta del atacante viaja con el dano")
local ENLACE = "|cff1eff00|Hitem:14088020::::::::60:259:::::::::|h[Espada larga]|h|r"
local etiqueta = "Dano " .. ENLACE
local compacta = "Dano |cff1eff00|Hitem:14088020|h[Espada larga]|h|r"
local payload = S(comps, false, false, etiqueta)
local out2, _c2, _m2, etqVuelta = D(payload)
chk("vuelve entera", etqVuelta, compacta)
-- ESTE es el fallo que costo encontrar: un enlace de objeto lleva pipes dentro
-- (`|cff…|Hitem:…|h[…]|h|r`), asi que `strsplit("|")` lo cortaba en el primero y la etiqueta
-- llegaba como "Dano ". Va la ULTIMA a proposito y se coge el resto de la cadena de una pieza.
chk("con su enlace intacto", etqVuelta:find("|Hitem:14088020|h[Espada larga]|h|r", 1, true) ~= nil, true)
chk("y sigue clicable (conserva el color)", etqVuelta:find("|cff1eff00", 1, true) ~= nil, true)
chk("los componentes no se tocan", #out2, 2)
chk("y cabe en un mensaje", #payload <= 240, true)

-- Una etiqueta larguisima se recorta a ella, nunca a los componentes: el dano es el dato.
local largo = S(comps, false, false, "Dano " .. string.rep("X", 400))
local outL = D(largo)
chk("una etiqueta enorme no tira el mensaje", largo ~= nil, true)
chk("y no se come los componentes", outL and #outL or 0, 2)
chk("recortando hasta caber", #largo <= 240, true)

-- Sin etiqueta (cliente anterior) se sigue entendiendo: son cuatro campos y ya.
local viejo = "DNDDMG|7:contundente,3:frio||"
local outV, _cv, _mv, etqV = D(viejo)
chk("un mensaje sin etiqueta se entiende", outV and #outV or 0, 2)
chk("y no inventa etiqueta", etqV == nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
