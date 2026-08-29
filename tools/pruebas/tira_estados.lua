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
-- La tira tambien pinta los estados PROPIOS sobre el PlayerFrame: admite "player", el repintado
-- de contadores la incluye (sin tocar botones nativos, que con "player" se fuerzan a target), y
-- hay primera pintada al entrar al mundo (los persistidos se restauran antes del anclaje).
chk("admite al propio jugador",
    uf:find('unit ~= "target" and unit ~= "focus" and unit ~= "player"', 1, true) ~= nil, true)
chk("el repintado de contadores la incluye",
    uf:find('{ "target", "focus", "player" }', 1, true) ~= nil, true)
chk("sin contadores nativos para player",
    uf:find('unit ~= "player" and UnitExists and UnitExists(unit) and RefreshNativeAuraButtons', 1, true) ~= nil, true)
chk("primera pintada al entrar al mundo",
    uf:find('API.RefreshConditionStrip("player")', 1, true) ~= nil, true)
chk("con frame propio por unidad", uf:find('CreateFrame("Frame", "HarfordEstados"', 1, true) ~= nil, true)
-- Regla de Epsilon: overlays de unitframe en UIParent/MEDIUM, nunca DIALOG (taparia otros addons).
chk("en UIParent", uf:find('CreateFrame("Frame", "HarfordEstados" .. unit, UIParent)', 1, true) ~= nil, true)
chk("strata MEDIUM", uf:find('f:SetFrameStrata("MEDIUM")', 1, true) ~= nil, true)

print("Se ancla sobre lo mas alto que haya, no a ciegas sobre el frame")
chk("calcula el ancla", uf:find("local function AnclaSuperior", 1, true) ~= nil, true)
chk("mira las auras nativas", uf:find('for _, kind in ipairs({ "Buff", "Debuff" })', 1, true) ~= nil, true)
chk("y se ancla al objeto, no a una coordenada",
    uf:find('local ancla, margen = AnclaSuperior(frame, prefix), 6', 1, true) ~= nil, true)
chk("por encima de ese ancla, y en su columna",
    uf:find('SetPoint("BOTTOMLEFT", ancla, "TOPLEFT", desplazX, margen)', 1, true) ~= nil, true)

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
-- Sin numero fijo: cada condicion nueva sube esta cuenta, y una prueba que hay que retocar cada
-- vez deja de leerse y se actualiza sin mirar. Lo que importa es que TODAS tengan icono, y eso se
-- comprueba justo debajo.
chk("hay condiciones sin aura", #sinAura > 0, true)
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
chk("la del aura la reutiliza", cond:find("mapa[id] = API.CounterFor(def, active.record)", 1, true) ~= nil, true)
-- Y se calcula UNA vez por unidad: antes era un recorrido de las ~50 condiciones por cada boton de
-- aura, en la ruta de UNIT_AURA, que las reglas de rendimiento exigen barata.
chk("y solo una vez por unidad", cond:find("function API.GetAuraCounterMap", 1, true) ~= nil, true)
chk("invalidada por el aviso del motor", cond:find("S.selloAviso = (S.selloAviso or 0) + 1", 1, true) ~= nil, true)



-- LA TIRA NO PUEDE SALIRSE DE LA PANTALLA.
--
-- Paso en juego: el marco del objetivo estaba a 1005 y la pantalla medía 1009, asi que los 20 px
-- de la tira acababan en 1031. Colocada con exquisitez respecto al marco, y completamente
-- invisible. Las comprobaciones automaticas pasaban -- construida, visible, "por encima" -- porque
-- ninguna miraba si eso caia dentro de la vista.
local uf3 = io.open("Harford/Frames/HarfordUnitFrames.lua"):read("*a")
print("Si no cabe arriba, se baja lo justo para que quepa")
chk("se mira el techo de la pantalla", uf3:find("local techo = UIParent and UIParent:GetHeight()", 1, true) ~= nil, true)
chk("y se compara con lo alto que queda", uf3:find("if techo and arriba and arriba > techo then", 1, true) ~= nil, true)
chk("bajandola justo lo que se sale",
    uf3:find("margen - (arriba - techo) - 2", 1, true) ~= nil, true)

-- La aritmetica, ejecutada: con 20 de alto, ancla en 1005 y pantalla de 1009, tiene que acabar
-- dentro. Sin el ajuste la tira ocupaba de 1011 a 1031.
local function ColocarY(anclaArriba, altoTira, margen, techo)
    local base = anclaArriba + margen
    local arriba = base + altoTira
    if techo and arriba > techo then base = base - (arriba - techo) - 2 end
    return base, base + altoTira
end
local base, arriba = ColocarY(1005, 20, 6, 1009)
chk("con la pantalla justa, entra", arriba <= 1009, true)
-- No pegada al filo: se dejan 2 px, o el borde superior del icono se confunde con el de la
-- pantalla y parece cortado.
chk("con dos pixeles de aire", arriba, 1007)
-- Con sitio de sobra no se toca nada: el ajuste solo actua cuando hace falta.
base, arriba = ColocarY(500, 20, 6, 1009)
chk("con sitio de sobra, no se mueve", base, 506)
chk("y sigue por encima del ancla", base > 500, true)
-- Dos filas de estados ocupan mas y tambien tienen que caber.
base, arriba = ColocarY(1005, 43, 6, 1009)
chk("con dos filas, tambien entra", arriba <= 1009, true)

-- ─── En columna con los buffs ───────────────────────────────────────────────
-- Los botones de aura no empiezan en el borde izquierdo del frame. Anclando la tira al frame
-- quedaba desplazada respecto a ellos y no parecia del mismo bloque.
print("La tira se alinea con la columna del primer buff")
chk("busca el primer buff", uf3:find('local ref = _G[prefix .. "Buff1"]', 1, true) ~= nil, true)
chk("y si no hay, el primer debuff",
    uf3:find('if not (ref and ref.IsShown and ref:IsShown()) then ref = _G[prefix .. "Debuff1"] end', 1, true) ~= nil, true)
chk("se desplaza esa diferencia", uf3:find("desplazX, medido = a - b, true", 1, true) ~= nil, true)
-- Sin la marca, un desplazamiento de 0 -- valido cuando el ancla ya es Buff1 -- se tomaba por "no
-- medido" y se recuperaba la columna aprendida de OTRO objetivo, moviendo la tira 20 px.
chk("y 0 cuenta como medido", uf3:find("if medido then", 1, true) ~= nil, true)
chk("y el desplazamiento sobrevive al ajuste vertical",
    uf3:find('SetPoint("BOTTOMLEFT", ancla, "TOPLEFT", desplazX, margen - (arriba - techo) - 2)', 1, true) ~= nil, true)

-- Sin auras visibles no hay con que alinearse: se queda en el borde, que es lo que habia antes.
local function Desplazamiento(izqBuff, izqAncla)
    if izqBuff and izqAncla then return izqBuff - izqAncla end
    return 0
end
chk("con buff, la diferencia", Desplazamiento(120, 100), 20)
chk("sin buff, ninguno", Desplazamiento(nil, 100), 0)
-- Si el ancla YA es un boton de aura, estan en la misma columna y no hay que mover nada.
chk("si el ancla ya es el buff, cero", Desplazamiento(120, 120), 0)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
