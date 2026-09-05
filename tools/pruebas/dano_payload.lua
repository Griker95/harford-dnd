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

-- La etiqueta pasa por el compactador DOS veces: una al mandar el dano y otra cuando la victima la
-- publica como tirada. Si no fuera idempotente, el enlace se degradaria por el camino y llegaria a
-- la mesa sin color, sin nombre o sin poder pincharse.
print("El enlace del arma sobrevive a las dos pasadas")
local unaVez = HarfordDnDRolls.NetworkLabel(etiqueta)
local dosVeces = HarfordDnDRolls.NetworkLabel(unaVez)
chk("compactar dos veces es igual que una", dosVeces == unaVez, true)
chk("conserva el ID del objeto", dosVeces:find("|Hitem:14088020|h", 1, true) ~= nil, true)
chk("conserva el nombre visible", dosVeces:find("[Espada larga]", 1, true) ~= nil, true)
chk("conserva el color de calidad", dosVeces:find("|cff1eff00", 1, true) ~= nil, true)
chk("y lo cierra", dosVeces:sub(-2) == "|r", true)
-- Un hyperlink solo es clicable con su apertura y su cierre.
local _, marcas = dosVeces:gsub("|h", "")
chk("sigue siendo clicable (|h abre y cierra)", marcas, 2)

-- Y con arma BASICA, sin enlace, la etiqueta es el nombre a secas -- como siempre ha sido.
-- `WeaponRollName` devuelve el itemLink solo si el arma viene de un objeto; si no, su nombre. La
-- etiqueta que viaja es la MISMA cadena que habria publicado el atacante, asi que los dos casos se
-- conservan sin ramas aparte.
print("Sin objeto, el nombre del arma tal cual")
local basica = S(comps, false, false, "Dano Espada larga")
local outB, _cb, _mb, etqB = D(basica)
chk("vuelve igual", etqB, "Dano Espada larga")
chk("sin enlace inventado", etqB:find("|Hitem", 1, true) == nil, true)
chk("y los componentes intactos", outB and #outB or 0, 2)

-- ─── DAÑO SIN TIPO: el ajuste de mesa del DM ────────────────────────────────
-- Los botones de vida de TURNOS y el menu DM mandan ahora el daño EN BRUTO sin tipo (daño de
-- mesa: sin tipo no se aplica ninguna resistencia) y lo resuelve la victima con sus datos
-- vivos. Antes turnos partia temp/salud con la CACHE remota (reparto erroneo con cache vieja)
-- y el menu DM iba directo a salud saltandose la vida temporal y la reaccion preparada.
print("Daño sin tipo (ajustes de mesa)")
local sinTipo = S({ { amount = 12, damageType = "" } }, false, false, nil)
chk("serializa", sinTipo ~= nil, true)
local outT = D(sinTipo)
chk("y vuelve entero", outT and outT[1] and outT[1].amount, 12)
chk("con el tipo vacio intacto", outT and outT[1] and outT[1].damageType, "")

print("Los dos emisores de mesa migrados a bruto")
local turnos = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
chk("turnos: el daño va por SendDamage",
    turnos:find('HarfordSync.SendDamage("DND5EARC", targetName', 1, true) ~= nil, true)
chk("turnos: ya no parte temp/salud en el emisor",
    turnos:find('AdjustResourceForName(targetName, "temp_health"', 1, true), nil)
chk("turnos: la curacion sigue por RADJ",
    turnos:find('AdjustResourceForName(targetName, "health", amount)', 1, true) ~= nil, true)
local menu = io.open("HarfordAdmin/HarfordAdminUnitMenu.lua"):read("*a")
chk("menu DM: el daño va por SendDamage",
    menu:find("HarfordSync.SendDamage(\"DND5EARC\", nombre", 1, true) ~= nil, true)
chk("menu DM: la curacion y el editor siguen por RADJ",
    menu:find('AdjustResourceForName(snapshot.name, "health", delta)', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
