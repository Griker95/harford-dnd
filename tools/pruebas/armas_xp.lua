-- Tres modulos de datos sin ninguna prueba (8 de 8 mutaciones pasaban en cada uno):
--   HarfordDnDWeapons  -> dados del arma, versatil y familia de animacion.
--   HarfordCharacterXP -> la tabla de XP del manual y el progreso en la barra.
--   HarfordDnDResources-> claves y existencia de un recurso.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local function cargarModulo(ruta, env)
    env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
    env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
    env.setmetatable, env.next = setmetatable, next
    local src = io.open(ruta):read("*a")
    local f
    if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
    pcall(f)
    return env
end

-- ═══ ARMAS ══════════════════════════════════════════════════════════════════
local VERSATIL = 0
local envW = cargarModulo("Harford/DnD/Data/HarfordDnDWeapons.lua",
    setmetatable({
        HarfordDnDContext = { Get = function(k, d)
            if k == "Versatil" then return tostring(VERSATIL) end
            return d
        end },
    }, { __index = function() return nil end }))
local W = envW.HarfordDnDWeapons

print("Leer un dado")
local n, c = W.ParseDice("2d6")
chk("dos de seis", tostring(n) .. "/" .. tostring(c), "2/6")
chk("sin cadena, nada", (W.ParseDice(nil)), "nil")
-- Solo el formato exacto: "2d6+1" no es un dado de arma, y aceptarlo a medias daria 2d6 callando
-- el +1.
chk("con anadidos, nada", (W.ParseDice("2d6+1")), "nil")
chk("texto suelto, nada", (W.ParseDice("mucho")), "nil")

-- Un arma versatil tiene DOS dados: el de una mano y el de dos. El segundo solo cuenta con el
-- interruptor puesto, o una espada larga pegaria siempre como si fuera a dos manos.
print("Versatil: el segundo dado solo con el interruptor puesto")
local espada = { key = "Espada larga", mode = "Melee", dmgN = 1, dmgS = 8,
                 props = { "Versátil (1d10)" } }
chk("se detecta el dado versatil", W.GetVersatileDice(espada), "1d10")
VERSATIL = 0
chk("apagado, el normal", W.WeaponBaseDice(espada), "1d8")
VERSATIL = 1
chk("encendido, el grande", W.WeaponBaseDice(espada), "1d10")
VERSATIL = 0
-- Un arma sin la propiedad no cambia por mucho que el interruptor este puesto.
local maza = { key = "Maza", mode = "Melee", dmgN = 1, dmgS = 6, props = {} }
VERSATIL = 1
chk("una no versatil no cambia", W.WeaponBaseDice(maza), "1d6")
VERSATIL = 0
chk("sin dados, un guion", W.WeaponBaseDice({ key = "X", dmgN = 0, dmgS = 0 }), "-")
chk("sin arma, un guion", W.WeaponBaseDice(nil), "-")

-- La familia decide QUE animacion se lanza. Equivocarla no rompe nada: solo hace que un mandoble
-- se blanda como una daga.
print("Familia de animacion")
chk("desarmado", W.GetAnimFamily({ key = "Desarmado", mode = "Melee" }), "unarmed")
chk("escudo", W.GetAnimFamily({ key = "Escudo", mode = "Melee" }), "shield")
chk("una mano", W.GetAnimFamily(maza), "one_hand")
chk("dos manos", W.GetAnimFamily({ key = "Mandoble", mode = "Melee", props = { "Dos manos" } }), "two_hand")
-- Alcance + dos manos es un asta, que se anima distinto de un mandoble.
chk("asta", W.GetAnimFamily({ key = "Alabarda", mode = "Melee",
    props = { "Alcance", "Dos manos" } }), "polearm")
-- Un arma a distancia no tiene animacion cuerpo a cuerpo: se conserva el emote actual.
chk("a distancia, ninguna", W.GetAnimFamily({ key = "Arco", mode = "Ranged", props = {} }), "nil")
-- Un versatil se anima a dos manos SOLO con el interruptor puesto.
chk("versatil apagado, una mano", W.GetAnimFamily(espada, false), "one_hand")
chk("versatil encendido, dos manos", W.GetAnimFamily(espada, true), "two_hand")

-- El rango se lee de las propiedades del arma, no de una segunda tabla que
-- pudiera desincronizarse del manual. Los numeros del manual son pies y el
-- motor comun trabaja en metros.
print("Alcance de armas")
local arco = { key = "Arco", mode = "Ranged", props = { "Munición (80/320)" } }
local range = W.GetAttackRange(arco)
chk("arco normal en metros", string.format("%.2f", range.normalMeters), "24.38")
chk("arco largo en metros", string.format("%.2f", range.longMeters), "97.54")
range = W.GetAttackRange({ key = "Lanza", mode = "Melee", props = { "Alcance" } })
chk("alcance melee", string.format("%.3f", range.normalMeters), "3.048")
range = W.GetAttackRange({ key = "Daga", mode = "Melee", props = { "Arrojadiza (20/60)" } })
chk("daga equipada exige contacto", string.format("%.3f", range.normalMeters), "0.000")
range = W.GetAttackRange({ key = "Daga", mode = "Melee", props = { "Arrojadiza (20/60)" } }, "thrown")
chk("daga arrojada normal", string.format("%.2f", range.normalMeters), "6.10")
chk("daga arrojada largo", string.format("%.2f", range.longMeters), "18.29")

-- Epsilon responde en yardas. El alcance usa el borde del hitbox en 3D, no el
-- centro del modelo: una criatura grande no debe requerir llegar hasta su centro.
local envRange = cargarModulo("Harford/DnD/Engine/HarfordDnDRange.lua",
    setmetatable({}, { __index = function() return nil end }))
local D = envRange.HarfordDnDRange
print("Distancias de Epsilon y conjuros")
local meters, _, _, source = D.ParseDistanceReply({
    "Hitbox distance to target is 4.430309 in 3D, 4.430304 in 2D Exact distance to target is 7.430309 in 3D, 7.430304 in 2D",
})
chk("hitbox 3D antes que centro", string.format("%.4f", meters), "4.0511")
chk("origen hitbox 3D", source, "hitbox_3d")
local distanceDetails = D.ParseDistanceDetails({
    "Hitbox distance to target is 4.430309 in 3D, 4.430304 in 2D Exact distance to target is 7.430309 in 3D, 7.430304 in 2D",
})
chk("exacta 3D separada", string.format("%.4f", distanceDetails.exactMeters), "6.7943")
local coloredDistance = D.ParseDistanceDetails({
    "|cff00ff00Hitbox distance to target is |cffffffff4.430309|r in 3D, 4.430304 in 2D Exact distance to target is 7.430309 in 3D, 7.430304 in 2D|r",
})
chk("respuesta coloreada conserva hitbox", string.format("%.4f", coloredDistance.hitboxMeters), "4.0511")
chk("contexto de mapa", D.BuildPositionContext(1220), "1220")
local spellRange = D.ParseSpellRange("30 metros")
chk("conjuro en metros", string.format("%.1f", spellRange.normalMeters), "30.0")
spellRange = D.ParseSpellRange("Toque")
chk("toque exige contacto", spellRange.requiresContact, true)
chk("toque sin alcance metrico", string.format("%.3f", spellRange.normalMeters), "0.000")
local contact = D.CheckDistance(0, { normalMeters = 0, longMeters = 0, requiresContact = true })
chk("contacto permitido", contact.ok, true)
local noContact = D.CheckDistance(0.1, { normalMeters = 0, longMeters = 0, requiresContact = true })
chk("melé fuera de contacto bloqueado", noContact.ok, false)
local exactRange = D.CheckDistance(distanceDetails.exactMeters, { normalMeters = 6.8 })
chk("alcance numerico usa exacta", exactRange.ok, true)
local out = D.CheckDistance(31, { normalMeters = 30 })
chk("fuera de alcance", out.ok, false)
local long = D.CheckDistance(20, { normalMeters = 10, longMeters = 30 })
chk("rango largo permitido", long.ok, true)
chk("rango largo da desventaja", long.disadvantage, true)

-- ═══ XP ═════════════════════════════════════════════════════════════════════
local XP = 0
local envX = cargarModulo("Harford/Character/HarfordCharacterXP.lua",
    setmetatable({
        HarfordDnDProgression = { GetTotalLevel = function() return NIVEL_PJ or 0 end },
        HarfordChat = { Print = function() end },
    }, { __index = function() return nil end }))
local X = envX.HarfordCharacterXP
-- `GetXP` lee de la progresion; se sustituye para poder fijar el valor.
X.GetXP = function() return XP end

-- La tabla del manual, con los umbrales exactos. Un umbral mal puesto sube de nivel antes o
-- despues de tiempo y nadie lo nota hasta que alguien compara con la tabla.
print("La tabla de XP del manual")
chk("veinte niveles", #X.XP_TABLE, 20)
chk("el 1 empieza en 0", X.XP_TABLE[1], 0)
chk("el 2 a 300", X.XP_TABLE[2], 300)
chk("el 5 a 6500", X.XP_TABLE[5], 6500)
chk("el 20 a 355000", X.XP_TABLE[20], 355000)

print("El nivel que corresponde a una cantidad")
local casos = { [0] = 1, [299] = 1, [300] = 2, [899] = 2, [900] = 3, [6499] = 4, [6500] = 5 }
for xp, nivel in pairs(casos) do
    chk(xp .. " XP", X.LevelForXP(xp), nivel)
end
-- Justo en el umbral ya cuenta: 300 es nivel 2, no 299.
chk("por debajo de cero, nivel 1", X.LevelForXP(-50), 1)
chk("pasado el maximo, se queda en 20", X.LevelForXP(999999), 20)

print("El progreso dentro del tramo, que es lo que pinta la barra")
XP = 300
local nivel, dentro, tramo = X.Progress()
chk("recien llegado al 2", nivel .. " " .. dentro .. "/" .. tramo, "2 0/600")
XP = 600
nivel, dentro, tramo = X.Progress()
chk("a mitad del tramo", nivel .. " " .. dentro .. "/" .. tramo, "2 300/600")
XP = 899
nivel, dentro, tramo = X.Progress()
chk("a punto de subir", nivel .. " " .. dentro .. "/" .. tramo, "2 599/600")
-- En nivel maximo no hay tramo siguiente: la barra se pinta llena en vez de dividir por cero.
XP = 400000
nivel, dentro, tramo = X.Progress()
chk("en el maximo, barra llena", nivel .. " " .. dentro .. "/" .. tramo, "20 1/1")

-- Avisar de subida sin XP para ello seria invitar a subir de gratis; y no avisar teniendola,
-- dejar al jugador esperando.
print("Cuando hay subida pendiente")
XP, NIVEL_PJ = 300, 1
chk("XP de 2 con personaje de 1", X.PendingLevelUp(), true)
XP, NIVEL_PJ = 300, 2
chk("ya subido, no", X.PendingLevelUp(), false)
XP, NIVEL_PJ = 299, 1
chk("sin XP suficiente, no", X.PendingLevelUp(), false)
-- Un personaje sin clases no puede subir: no hay de que.
XP, NIVEL_PJ = 100000, 0
chk("sin personaje, no", X.PendingLevelUp(), false)

-- La regla del proyecto: ganar XP AVISA de que hay subida, pero NUNCA la aplica. Subir de nivel
-- es siempre un gesto del jugador en el asistente, porque una subida automatica elegiria por el.
print("Ganar XP avisa, pero nunca sube de nivel")
local PROG = { xp = 0 }
envX.HarfordDnDProgression.Get = function() return PROG end
envX.HarfordDnDProgression.GetData = function() return PROG end
X.GetXP = function() return tonumber(PROG.xp) or 0 end
X.SetXP = function(v) PROG.xp = math.max(0, math.floor(tonumber(v) or 0)); return true end
X.Refresh = function() end

NIVEL_PJ = 1
PROG.xp = 0
X.AddXP(500)
chk("la XP sube", PROG.xp, 500)
chk("y avisa de que hay subida", X.PendingLevelUp(), true)
chk("pero el nivel del personaje no se toca", NIVEL_PJ, 1)
-- Sumar cero no es una ganancia: no se anuncia ni se guarda.
chk("sumar cero no hace nada", (X.AddXP(0)), false)
chk("y la XP se queda igual", PROG.xp, 500)

-- Ajustar al nivel del personaje sube la XP al minimo del nivel, pero NUNCA la baja: quien ya
-- lleva XP de sobra dentro de su tramo no la pierde por sincronizar.
print("Sincronizar al nivel no puede quitar XP")
NIVEL_PJ, PROG.xp = 3, 0
X.SyncToCharacterLevel("prueba")
chk("sube al minimo del nivel 3", PROG.xp, 900)
PROG.xp = 2000
X.SyncToCharacterLevel("prueba")
chk("con XP de sobra, no la baja", PROG.xp, 2000)
chk("y devuelve false porque no hizo falta", (X.SyncToCharacterLevel("prueba")), false)
-- Sin personaje no hay nivel al que ajustar.
NIVEL_PJ = 0
PROG.xp = 50
chk("sin personaje, no ajusta", (X.SyncToCharacterLevel("prueba")), false)
chk("y no toca la XP", PROG.xp, 50)

print("Reiniciar deja la XP a cero")
NIVEL_PJ, PROG.xp = 3, 5000
X.ResetXP("ficha nueva")
chk("a cero", PROG.xp, 0)
chk("que es nivel 1", X.LevelForXP(PROG.xp), 1)

-- ═══ RECURSOS ═══════════════════════════════════════════════════════════════
local envR = cargarModulo("Harford/DnD/State/HarfordDnDResources.lua",
    setmetatable({}, { __index = function() return nil end }))
local R = envR.HarfordDnDResources

print("Claves de recurso")
chk("actual", R.CurKey("chi"), "Res_chi_Cur")
chk("maximo", R.MaxKey("chi"), "Res_chi_Max")

-- Un recurso EXISTE si tiene maximo, no si tiene valor. Confundirlo pinta barras vacias de
-- recursos que ese personaje no tiene.
print("Un recurso existe si tiene maximo")
chk("con maximo y a cero, existe", R.Exists("chi", 0, 5), true)
chk("sin maximo, no", R.Exists("chi", 3, 0), false)
chk("ninguno de los dos, no", R.Exists("chi", 0, 0), false)

-- La vida temporal NO esta en el orden de barras a proposito: no es una barra propia, se pinta
-- como absorcion sobre la de vida.
print("La vida temporal no es una barra propia")
local enOrden = false
for _, k in ipairs(R.ORDER or {}) do if k == "temp_health" then enOrden = true end end
chk("no esta en el orden de barras", enOrden, false)
chk("pero si esta definida", R.DEFS and R.DEFS.temp_health ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
