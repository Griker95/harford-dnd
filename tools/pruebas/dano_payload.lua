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
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
