-- DEFENSAS DEL JUGADOR SINCRONIZADAS (estilo CA): resistencias/inmunidades/vulnerabilidades
-- derivadas de rasgos+raza+objetos viajan como clave `DmgStatus` del payload de recursos y
-- aterrizan en la RemoteCache del receptor con el ciclo de vida de los recursos.
--
-- Lo que sella: (1) el formato compacto "tipo.letra" va ORDENADO (payload estable), la cadena
-- vacia es dato afirmativo ("sin defensas") y la clave ausente es "no se sabe" (cliente viejo);
-- (2) el payload la adjunta junto a la CA, y el envio de fichas del BANCO no la adjunta (el mapa
-- es del jugador vivo, no del perfil enviado); (3) el receptor la lee por nombre (largo/corto) y
-- distingue "conocido" de "desconocido"; (4) para un jugador remoto el mapa sincronizado MANDA
-- sobre la reconstruccion local (About TRP3/inspect), que solo es una copia que puede estar
-- vieja. La APLICACION del daño no cambia: la victima con Harford sigue resolviendo lo suyo.

local cargar = loadstring or load
local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-14s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── (1) CODIFICACION: FeatureEffects real con progresion de stub ───────────
local desbloqueados = {}
local envF = setmetatable({}, { __index = function() return nil end })
envF.ipairs, envF.pairs, envF.tostring, envF.tonumber = ipairs, pairs, tostring, tonumber
envF.type, envF.table, envF.string, envF.math, envF.select = type, table, string, math, select
envF.setmetatable, envF.next = setmetatable, next
envF.HarfordClassColors = { StripAccents = function(v) return tostring(v or "") end }
envF.HarfordDnDProgression = {
    GetUnlockedFeatures = function() return desbloqueados end,
    IsFeatureEnabled = function() return true end,
    GetClassLevels = function() return {} end,
    GetChoice = function() return {} end,
}
local srcF = io.open("Harford/DnD/Engine/HarfordDnDFeatureEffects.lua"):read("*a")
local fF
if setfenv then fF = assert(cargar(srcF)); setfenv(fF, envF) else fF = assert(cargar(srcF, "t", "t", envF)) end
assert(pcall(fF))
local FE = envF.HarfordDnDFeatureEffects

print("Codificacion compacta y estable")
desbloqueados = {
    { feature = { id = "a", effects = { { kind = "resist", damage = "veneno" } } } },
    { feature = { id = "b", effects = { { kind = "immune", damage = "fuego" } } } },
}
FE.Invalidate()
chk("dos defensas, orden alfabetico", FE.EncodeDamageStatus("X"), "fuego.i,veneno.r")
desbloqueados = { { feature = { id = "c", effects = { { kind = "vuln", damage = "frio" } } } } }
FE.Invalidate()
chk("vulnerable con su letra", FE.EncodeDamageStatus("X"), "frio.v")
desbloqueados = {}
FE.Invalidate()
chk("sin defensas: cadena VACIA (dato afirmativo)", FE.EncodeDamageStatus("X"), "")

print("Descodificacion")
local mapa = FE.DecodeDamageStatus("fuego.i,veneno.r")
chk("inmune", mapa.fuego, "immune")
chk("resistente", mapa.veneno, "resistant")
chk("vacia -> mapa vacio, no nil", next(FE.DecodeDamageStatus("")), nil)
chk("nil -> nil (clave ausente = no se sabe)", FE.DecodeDamageStatus(nil), nil)
chk("letra desconocida se ignora", (FE.DecodeDamageStatus("fuego.z") or {}).fuego, nil)

-- ─── (2) EL PAYLOAD LA ADJUNTA (y el banco NO) ──────────────────────────────
print("El payload de recursos lleva DmgStatus junto a la CA")
local envN = setmetatable({}, { __index = function() return nil end })
envN.ipairs, envN.pairs, envN.tostring, envN.tonumber = ipairs, pairs, tostring, tonumber
envN.type, envN.table, envN.string, envN.math = type, table, string, math
envN.UnitName = function() return "Yo" end
envN.HarfordDnDStore = { ToNumber = function(v, d) return tonumber(v) or d end }
envN.HarfordDnDResources = { BuildPayloadFromRuntime = function() return {}, {} end }
envN.HarfordDnDContext = { Get = function() return "0" end, State = {} }
envN.HarfordDnDFeatureEffects = { EncodeDamageStatus = function() return "veneno.r" end }
local srcN = io.open("Harford/DnD/Engine/HarfordDnDNet.lua"):read("*a")
local fN
if setfenv then fN = assert(cargar(srcN)); setfenv(fN, envN) else fN = assert(cargar(srcN, "t", "t", envN)) end
assert(pcall(fN))
local Net = envN.HarfordDnDNet
local out, keys = Net.BuildActiveResourcePayload(function() return "10" end)
chk("DmgStatus en el payload", out.DmgStatus, "veneno.r")
local enLista = false
for _, k in ipairs(keys) do if k == "DmgStatus" then enLista = true end end
chk("y en la lista de claves a enviar", enLista, true)
chk("la CA sigue viajando", out.ArmorClass, "10")
out = Net.BuildActiveResourcePayload(function() return "10" end, { includeDamageStatus = false })
chk("con includeDamageStatus=false NO viaja", out.DmgStatus, nil)
chk("el envio del BANCO la excluye (el mapa es del jugador vivo)",
    srcN:find("{ includeDamageStatus = false }", 1, true) ~= nil, true)

-- ─── (3) EL RECEPTOR LA LEE Y DISTINGUE CONOCIDO DE DESCONOCIDO ─────────────
print("GetSyncedStatus lee la RemoteCache por nombre")
local envM = setmetatable({}, { __index = function() return nil end })
envM.ipairs, envM.pairs, envM.tostring, envM.tonumber = ipairs, pairs, tostring, tonumber
envM.type, envM.table, envM.string, envM.math = type, table, string, math
envM.HarfordClassColors = { StripAccents = function(v) return tostring(v or "") end }
envM.GetUnitName = function() return "Deryk-Reino" end
envM.UnitName = function() return "Deryk", "Reino" end
envM.Ambiguate = function(n) return tostring(n):match("^[^%-]+") end
envM.UnitExists = function() return true end
envM.UnitIsPlayer = function() return true end
envM.UnitIsUnit = function() return false end
envM.HarfordDnDResources = { RemoteCache = {} }
envM.HarfordDnDFeatureEffects = {
    DecodeDamageStatus = FE.DecodeDamageStatus,
    NormDamageKey = function(v) return tostring(v or ""):lower():gsub("%s+", "") end,
    GetCachedDamageStatus = function() return nil end,
}
local srcM = io.open("Harford/DnD/Data/HarfordDamageMitigation.lua"):read("*a")
local fM
if setfenv then fM = assert(cargar(srcM)); setfenv(fM, envM) else fM = assert(cargar(srcM, "t", "t", envM)) end
assert(pcall(fM))
local DM = envM.HarfordDamageMitigation

local st, conocido = DM.GetSyncedStatus("target", "veneno")
chk("sin cache: desconocido", conocido, false)
envM.HarfordDnDResources.RemoteCache["Deryk"] = { DmgStatus = "fuego.i,veneno.r" }
st, conocido = DM.GetSyncedStatus("target", "veneno")
chk("por nombre corto: resistente", st, "resistant")
chk("y conocido", conocido, true)
st, conocido = DM.GetSyncedStatus("target", "fuego")
chk("inmune", st, "immune")
st, conocido = DM.GetSyncedStatus("target", "frio")
chk("tipo sin entrada: normal (nil) pero CONOCIDO", st == nil and conocido, true)
envM.HarfordDnDResources.RemoteCache["Deryk"] = { DmgStatus = "" }
st, conocido = DM.GetSyncedStatus("target", "veneno")
chk("mapa vacio: sin defensas y conocido", st == nil and conocido, true)

-- ─── (4) EL MAPA SINCRONIZADO MANDA SOBRE LA RECONSTRUCCION LOCAL ───────────
print("Prioridad: sincronizado antes que About/inspect")
local iSync = srcM:find("HarfordDamageMitigation.GetSyncedStatus(unit, typeText)", 1, true)
local iLoop = srcM:find("HarfordDnDProgression.HasProgression) then", 1, true)
chk("ResolvePlayerFeatureStatus consulta el mapa primero",
    iSync ~= nil and iLoop ~= nil and iSync < iLoop, true)
chk("y si es conocido no sigue buscando",
    srcM:find("if conocido then return synced end", 1, true) ~= nil, true)
-- La victima con Harford sigue resolviendo su propio daño: el contrato de aplicacion no cambia.
chk("TargetResolvesOwnDamage sigue intacto",
    srcM:find('if UnitIsUnit and UnitIsUnit(unit, "player") then return false end', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
