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
chk("y en el marco propio la columna es la barra de salud",
    uf:find('ref = _G[prefix .. "HealthBar"]', 1, true) ~= nil, true)
-- Click derecho retira: lo propio lo hace el core via RequestPlayer (Muriendo NO: su aura la
-- gobierna Salv Muerte); lo ajeno solo a traves del gancho que instala HarfordAdmin, que valida
-- autoridad y exige target para NPC (npc unaura actua sobre el target del SERVIDOR).
chk("click derecho propio retira por RequestPlayer",
    uf:find('HarfordDnDConditions.RequestPlayer("player", self.estado.id, false)', 1, true) ~= nil, true)
chk("Muriendo propio no se retira a mano",
    uf:find('if self.estado.id == "dying" then', 1, true) ~= nil, true)
chk("lo ajeno pasa por el gancho de Admin",
    uf:find('API.OnConditionIconRightClick(unidad, self.estado.id)', 1, true) ~= nil, true)
local adm = io.open("HarfordAdmin/HarfordAdminConditions.lua"):read("*a")
chk("Admin instala el gancho", adm:find("HarfordUnitFrames.OnConditionIconRightClick = function", 1, true) ~= nil, true)
chk("y exige target para NPC", adm:find('if not snapshot.isPlayer and unit ~= "target" then', 1, true) ~= nil, true)
-- Y las auras NATIVAS del target: click derecho DM lanza .unaura de ese spell. Solo TargetFrame
-- (unaura actua sobre el target del servidor; el hook ignora al FocusFrame) y solo con permisos.
local menuAdm = io.open("HarfordAdmin/HarfordAdminUnitMenu.lua"):read("*a")
chk("las auras nativas del target tienen click DM",
    menuAdm:find('hooksecurefunc("TargetFrame_UpdateAuras"', 1, true) ~= nil, true)
chk("que ignora al FocusFrame", menuAdm:find("if frame ~= TargetFrame then return end", 1, true) ~= nil, true)
chk("y exige CanUseDMTools", menuAdm:find("CanUseDMTools()) then return end", 1, true) ~= nil, true)
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
chk("condiciones con aura", #conAura, 17)  -- dying 2026-08-29 (29266); charmed 2026-09-04 (253996)
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
    cat:find('harford_accion_trabado_melee = "eps_bg3_forcedmove",\n    --', 1, true) ~= nil, true)

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

-- ─── LOS ESTADOS SOBREVIVEN AL FIN DE COMBATE (decision de mesa 2026-09-05) ─
-- Terminar el combate NO retira estados ni auras: RecogerTodo solo recoge economia de turno,
-- movimiento y estandarte. Un estado con turnos/rondas restantes se queda CONGELADO (la
-- caducidad por turnos solo avanza con OnTurnChanged, y sin combate no hay turnos) y se retira
-- a mano: el propio jugador con click derecho en su tira (menos Muriendo), los ajenos el DM.
-- Si alguien ve un "10 rondas" congelado fuera de combate y le parece un despiste: NO lo es.
print("Los estados sobreviven al fin de combate")
local tc = io.open("Harford/Frames/HarfordTurnsCombat.lua"):read("*a")
local ini = assert(tc:find("local function RecogerTodo()", 1, true))
local fin = assert(tc:find("\nend", ini))
local recoger = tc:sub(ini, fin)
chk("RecogerTodo no toca condiciones (solo Turn.Reset)",
    recoger:find("RemoveOwned", 1, true) == nil
    and recoger:find("ClearPendingAuras", 1, true) == nil
    and recoger:find("RemoveRecord", 1, true) == nil, true)
chk("recoge la economia", recoger:find("HarfordDnDConditions.Turn.Reset", 1, true) ~= nil, true)
chk("nadie registra un limpiador de estados",
    cond:find("RegisterCombatCleanup", 1, true), nil)
-- El propio jugador se quita los suyos: click derecho en el icono de su tira (core, sin DM).
chk("click derecho propio retira (via RequestPlayer)",
    uf:find('HarfordDnDConditions.RequestPlayer("player", self.estado.id, false)', 1, true) ~= nil, true)
chk("Muriendo propio no se toca a mano",
    uf:find("Muriendo se retira recuperando vida, no a mano.", 1, true) ~= nil, true)
-- Y quitarse el estado retira tambien su aura de servidor (RemoveOwned -> ApplyAura remove self).
chk("RemoveOwned retira el aura del estado",
    cond:find("local auraOk, auraErr = ApplyAura(def, \"self\", true)", 1, true) ~= nil, true)

-- El tooltip de Cansancio dice EL NIVEL (cian, tras el titulo) y lista sus efectos acumulados,
-- no solo la descripcion generica. El nivel viaja en el registro sincronizado.
chk("Cansancio ensena su nivel en el tooltip",
    uf:find('detalle = "Nivel " .. nivel .. (nivel >= 6 and " (muerte)" or "")', 1, true) ~= nil, true)
chk("y lista los efectos acumulados",
    uf:find("lineas = HarfordDnDConditions.GetExhaustionEffects(nivel)", 1, true) ~= nil
    and uf:find('GameTooltip:AddLine("- " .. tostring(linea), 1, 1, 1, true)', 1, true) ~= nil, true)
-- Y SOLO eso: ni la descripcion generica ni la ayuda del click derecho (el gesto sigue vivo).
chk("sin la descripcion generica",
    uf:find("descripcion = nil", 1, true) ~= nil, true)
chk("sin la ayuda del click derecho",
    uf:find('if self.estado.id ~= "exhaustion"', 1, true) ~= nil, true)

-- Terreno dificil: estado con efecto declarativo movementCostDouble y su helper, para que el
-- contador de movimiento doble el gasto. Con icono propio (estado sin aura).
chk("terreno_dificil existe con su efecto",
    cond:find('effects = { { kind = "movementCostDouble" } },', 1, true) ~= nil, true)
chk("y su helper IsMovementDoubled",
    cond:find("function API.IsMovementDoubled(ref)", 1, true) ~= nil, true)
chk("con icono en el catalogo",
    io.open("Harford/Compendium/HarfordIconCatalog.lua"):read("*a")
        :find("\n    harford_estado_terreno_dificil = ", 1, true) ~= nil, true)

-- ─── ENGRANAJE DE AUTOGESTION EN EL UNITFRAME PROPIO (2026-09-05) ───────────
-- Menu del propio jugador SIN .ph dm y SIN HarfordAdmin: estados del catalogo (toggle por
-- ApplyOwned/RemoveOwned, Cansancio por niveles, Muriendo excluido) y devoluciones de
-- movimiento/accion/adicional/reaccion. Autogestion de LO PROPIO por vias que ya existian.
print("El engranaje de autogestion del unitframe propio")
chk("el boton existe",
    uf:find('CreateFrame("Button", "HarfordPlayerGearButton", UIParent)', 1, true) ~= nil, true)
chk("sin puerta de DM ni Admin",
    uf:find("HarfordPlayerGearButton", 1, true) ~= nil
    and not uf:sub(uf:find("Engranaje de AUTOGESTION", 1, true) or 1)
        :find("CanUseDMTools", 1, true), true)
chk("estados por toggle propio",
    uf:find("if C.RemoveOwned then C.RemoveOwned(id) end", 1, true) ~= nil
    and uf:find("C.ApplyOwned(id)", 1, true) ~= nil, true)
chk("Muriendo y Cansancio tratados aparte",
    uf:find('if def.id ~= "dying" and def.id ~= "exhaustion" then', 1, true) ~= nil, true)
chk("devoluciones de las cuatro cosas",
    uf:find('Devolver("action", "acci', 1, true) ~= nil
    and uf:find('Devolver("bonus", "acci', 1, true) ~= nil
    and uf:find('Devolver("reaction", "reacci', 1, true) ~= nil
    and uf:find("M.ConcederODevolverMovimiento()", 1, true) ~= nil, true)
chk("y la seccion Combate con los tres gestos de /harfordcombat",
    uf:find('{ text = "Movimiento libre", isNotRadio = true,', 1, true) ~= nil
    and uf:find('{ text = "Reubicar", notCheckable = true,', 1, true) ~= nil
    and uf:find('{ text = "Parar combate", notCheckable = true,', 1, true) ~= nil, true)
chk("mas el tope de movimiento manual con su dialogo",
    uf:find('StaticPopupDialogs["HARFORD_MOVE_MAX"] = {', 1, true) ~= nil
    and uf:find("HarfordDnDAttackUI.SetMovementMaxOverride", 1, true) ~= nil, true)
-- Conjuros (solo en modo slots): "Espacios Nº X/Y" por nivel; el click recupera UNO. La
-- recuperacion devuelve primero el gasto NORMAL (el de pacto vuelve con el descanso corto).
chk("y Conjuros recupera espacios en modo slots",
    uf:find("compendio.GetSpellCostMode() == \"slots\"", 1, true) ~= nil
    and uf:find('string.format("Espacios %dº %d/%d", nivelFijo, cur or 0, maxi)', 1, true) ~= nil
    and uf:find("HarfordDnDMana.RecoverSpellSlot(nivelFijo) then", 1, true) ~= nil, true)
chk("RecoverSpellSlot devuelve primero el gasto normal",
    io.open("Harford/DnD/State/HarfordDnDMana.lua"):read("*a")
        :find("HarfordDnDProgression.SetSpellSlotsSpent(spellLevel, spent - 1, profileName)", 1, true) ~= nil, true)
-- El boton lleva EL MISMO arte que el boton de HarfordAdmin (StyleButton): circulo de minimapa
-- con INV_Misc_Gear_01 enmascarado y borde de tracking — no el engranaje amarillo plano de
-- UI-OptionsButton, que desentonaba.
chk("con el arte del boton Admin, no el engranaje amarillo",
    uf:find('gearIcon:SetTexture("Interface\\\\Icons\\\\INV_Misc_Gear_01")', 1, true) ~= nil
    and uf:find('gearBorder:SetTexture("Interface\\\\Minimap\\\\MiniMap-TrackingBorder")', 1, true) ~= nil
    and not uf:find("UI-OptionsButton", 1, true), true)
-- Y el anclaje esta CALCADO de AnchorUnitButton del Admin, no es un offset fijo sobre el
-- PlayerFrame nativo (asi salia en otra posicion y otra capa): parent = frame Harford del
-- player si esta visible, strata/level sincronizados, y CENTER en el borde derecho del retrato
-- MEDIDO. Se re-ancla por el mismo camino que los botones del Admin (API.Refresh) y se aparta
-- a la derecha si el boton Admin esta visible (DM con .ph dm usa los dos menus).
chk("parentado y medido como el boton Admin",
    uf:find('local parent = API.GetFrame and API.GetFrame("player")', 1, true) ~= nil
    and uf:find('local layout = API.GetMeasuredLayout and API.GetMeasuredLayout("player", false)', 1, true) ~= nil
    and uf:find("(box.x or 0) + (box.width or 0) - 2 + offset, -((box.y or 0) + 13))", 1, true) ~= nil, true)
chk("re-anclado en API.Refresh y apartandose del boton Admin",
    uf:find("if API.ReanchorPlayerGear then API.ReanchorPlayerGear() end", 1, true) ~= nil
    and uf:find('_G["HarfordAdminUnitMenuPlayerButton"]', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
