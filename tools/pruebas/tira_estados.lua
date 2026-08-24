-- TIRA DE ESTADOS SOBRE EL UNITFRAME.
--
-- Harford pinta sus estados APARTE de las auras del juego, porque 30 de las 45 condiciones no
-- tienen aura detras y no apareceran nunca en el unitframe por si solas.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local uf = io.open("Harford/Frames/HarfordUnitFrames.lua"):read("*a")
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local cat = io.open("Harford/Compendium/HarfordIconCatalog.lua"):read("*a")

print("La tira existe y es propia, no toca las auras nativas")
chk("hay tira", uf:find("function API.RefreshConditionStrip", 1, true) ~= nil, true)
chk("con frame propio por unidad", uf:find('CreateFrame("Frame", "HarfordEstados"', 1, true) ~= nil, true)
-- Regla de Epsilon: overlays de unitframe en UIParent/MEDIUM, nunca DIALOG (taparia otros addons).
chk("en UIParent", uf:find('CreateFrame("Frame", "HarfordEstados" .. unit, UIParent)', 1, true) ~= nil, true)
chk("strata MEDIUM", uf:find('f:SetFrameStrata("MEDIUM")', 1, true) ~= nil, true)

print("Se ancla sobre lo mas alto que haya, no a ciegas sobre el frame")
chk("calcula el ancla", uf:find("local function AnclaSuperior", 1, true) ~= nil, true)
chk("mira las auras nativas", uf:find('for _, kind in ipairs({ "Buff", "Debuff" })', 1, true) ~= nil, true)
chk("y se ancla al objeto, no a una coordenada",
    uf:find('SetPoint("BOTTOMLEFT", AnclaSuperior(frame, prefix), "TOPLEFT", 0, 6)', 1, true) ~= nil, true)

print("Se repinta cuando algo puede haber cambiado")
chk("al cambiar de target", uf:find('QueueNativeAuraCleanup("target")\n        API.RefreshConditionStrip("target")', 1, true) ~= nil, true)
chk("al cambiar de focus", uf:find('API.RefreshConditionStrip("focus")', 1, true) ~= nil, true)
chk("al reanclar las auras", uf:find("    API.RefreshConditionStrip(unit)\nend", 1, true) ~= nil, true)
chk("y cuando el motor avisa de un cambio de estado",
    cond:find("HarfordUnitFrames.RefreshAuraCounters()", 1, true) ~= nil, true)

print("Sin ticker: ningun OnUpdate ni temporizador para la tira")
chk("sin OnUpdate en la tira", uf:find('b:SetScript("OnUpdate"', 1, true), "nil")

print("Reutiliza iconos con pool, no crea frames en cada refresco")
chk("pool", uf:find("local function EnsureIcono(tira, i)", 1, true) ~= nil, true)
chk("reusa el que ya hay", uf:find("local b = tira.iconos[i]\n        if b then return b end", 1, true) ~= nil, true)
chk("oculta los sobrantes", uf:find("for i = #estados + 1, #tira.iconos do tira.iconos[i]:Hide() end", 1, true) ~= nil, true)

print("Arte: las que tienen aura usan la del aura, las demas el catalogo")
chk("hay resolutor de icono", cond:find("function API.GetIcon", 1, true) ~= nil, true)
chk("el catalogo manda", cond:find('HarfordIconCatalog.GetFeatureIcon("harford_estado_"', 1, true) ~= nil, true)
chk("y si no, la textura del aura", cond:find("GetSpellTexture(def.auraId)", 1, true) ~= nil, true)

-- Las 30 sin aura necesitan icono declarado; las 15 con aura NO deben tenerlo, para que no haya
-- dos versiones del mismo arte que un dia dejen de coincidir.
local conAura, sinAura = {}, {}
-- Solo el bloque de definiciones: el fichero tiene otras tablas con la misma sangria (`units`,
-- `listeners`) que no son condiciones.
-- `find` devuelve inicio Y fin: sin parentesis, el segundo valor entra como segundo argumento de
-- `sub` y devolveria solo la cabecera de la tabla.
local defs = cond:sub((assert(cond:find("API.DEFS = {", 1, true))))
defs = defs:sub(1, (assert(defs:find("\n}", 1, true))))
for id, cuerpo in defs:gmatch("\n    ([a-z_0-9]+) = (%b{})") do
    if cuerpo:find("auraId", 1, true) then conAura[#conAura + 1] = id else sinAura[#sinAura + 1] = id end
end
chk("condiciones con aura", #conAura, 15)
chk("condiciones sin aura", #sinAura, 30)
local faltan, sobran = 0, 0
for _, id in ipairs(sinAura) do
    if not cat:find("\n    harford_estado_" .. id .. " = ", 1, true) then faltan = faltan + 1 end
end
for _, id in ipairs(conAura) do
    if cat:find("\n    harford_estado_" .. id .. " = ", 1, true) then sobran = sobran + 1 end
end
chk("todas las que no tienen aura llevan icono", faltan, 0)
chk("ninguna con aura duplica el arte", sobran, 0)

-- Misma nomenclatura y misma sintaxis que su hermana `harford_accion_<id>`: una tabla con dos
-- estilos de clave invita a escribir el siguiente en un tercero.
print("Nomenclatura consistente con el resto del catalogo")
chk("clave desnuda, no [\"clave\"]", cat:find('["harford_estado_', 1, true), "nil")
chk("junto a las acciones basicas",
    cat:find('harford_accion_preparar = "eps_bg3_detectthoughts",\n    --', 1, true) ~= nil, true)

print("El contador es una sola regla, no dos copias")
chk("regla unica", cond:find("function API.CounterFor", 1, true) ~= nil, true)
chk("la del aura la reutiliza", cond:find("return API.CounterFor(def, active.record)", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
