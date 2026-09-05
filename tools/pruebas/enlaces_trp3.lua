-- ENLACES TRP3: un enlace por CONTENIDO, no por mencion.
--
-- `StoreSentLink` de TRP3 hace unico cada identificador ENCADENANDO numeros mientras el que
-- prueba exista ("X" -> "X1" -> "X12" -> "X123"...), y el identificador ES el texto visible del
-- marcador [TRP3:id]. Crear un enlace NUEVO en cada mencion (cada anuncio, cada intento, cada
-- insercion) alargaba la ristra hasta "Curar heridas123456789101112..." en el chat de la mesa
-- (2026-09-05, la noche del estreno). NO hacen falta 63 lanzamientos: 63 menciones bastan.
--
-- La cura es `HarfordTRP3.CachedChatLink` (cache por modulo+nombre+descripcion) y que TODOS los
-- puntos de creacion pasen por ella; la insercion usa el link cacheado en vez de mod:InsertLink,
-- que crearia otro.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-62s %-6s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local trp3 = io.open("Harford/TRP3/HarfordTRP3.lua"):read("*a")
local compUI = io.open("Harford/Compendium/HarfordCompendioUI.lua"):read("*a")

print("La cache por contenido existe y se usa en todos los creadores")
chk("CachedChatLink existe",
    trp3:find("function API.CachedChatLink(mod, name, data)", 1, true) ~= nil, true)
chk("con clave modulo+nombre+descripcion",
    trp3:find('tostring(data and data.desc or "")', 1, true) ~= nil, true)
-- Creaciones directas restantes: SOLO la de la propia cache y la del cache de estados
-- (glanceLinkCache, que ya deduplicaba por contenido). Cualquier otra es una regresion.
local directas = 0
for _ in trp3:gmatch("TRP3_API%.ChatLink%(name, data") do directas = directas + 1 end
chk("en HarfordTRP3 solo crean la cache y el glance (2)", directas, 2)
chk("habilidad usa la cache",
    trp3:find("local link = API.CachedChatLink(mod, name, data)  -- UN enlace por contenido", 1, true) ~= nil, true)
chk("la insercion de habilidad usa el link cacheado",
    trp3:find("return API.InsertChatLinkText(link)", 1, true) ~= nil, true)
chk("el compendio usa la cache",
    compUI:find("HarfordTRP3.CachedChatLink(module, name, data))", 1, true) ~= nil, true)
chk("y su insercion tambien",
    compUI:find("if ok and link and HarfordTRP3.InsertChatLinkText(link) then return end", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
