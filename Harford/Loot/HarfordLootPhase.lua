HarfordLootPhase = HarfordLootPhase or {}
local API = HarfordLootPhase

------------------------------------------------------------
-- Tablas de loot guardadas EN LA FASE.
--
-- Hoy `BroadcastConfig` manda el registro entero por addon message a todo el grupo, asi que
-- sin DM conectado no hay tablas de loot. Esto las deja escritas en el servidor.
--
-- Claves:
--   HARFORD_LOOT_KEYS            manifiesto (sin el, una clave huerfana es irrecuperable)
--   HARFORD_LOOT_GLOBAL          tabla global, se aplica a todo
--   HARFORD_LOOT_C_<creatureId>  tabla por criatura
--
-- SIN INDICE, a diferencia del tablon de contratos: cuando vas a saquear ya sabes el template
-- id de la criatura, asi que se pide su clave directamente. Es el patron de Epsilon_Merchant
-- y de los perfiles de NPC de TRP3. El manifiesto sirve para limpiar y para que el editor
-- del DM pueda listar.
--
-- ESCRITURA INCREMENTAL, tambien a diferencia del tablon: una fase puede tener cientos de
-- criaturas y reescribirlas todas cada vez que se toca una seria absurdo. Solo se escribe la
-- criatura editada.
--
-- Lo que NO se guarda aqui: `HarfordLootTaggedCreatureRegistry`, que es el loot YA TIRADO de
-- un cadaver concreto y se consume mientras la gente saquea. Eso sigue por `HARFORDLOOT`.
------------------------------------------------------------

local CLAVE_MANIFIESTO = "HARFORD_LOOT_KEYS"
local CLAVE_GLOBAL = "HARFORD_LOOT_GLOBAL"
local PREFIJO_CRIATURA = "HARFORD_LOOT_C_"

-- Cache por criatura: en una zona matas veinte del mismo template y pedirlo veinte veces
-- gastaria el cupo de 45 lecturas por 1,5 s para nada.
local TTL_CACHE = 300
local cache = {}

local function Store()
  return _G.HarfordPhaseStore
end

local function Ahora()
  return (GetTime and GetTime()) or 0
end

local function ClaveCriatura(creatureId)
  creatureId = tonumber(creatureId)
  if not creatureId then return nil end
  return PREFIJO_CRIATURA .. tostring(creatureId)
end

------------------------------------------------------------
-- Espejo local del manifiesto
------------------------------------------------------------

-- Igual que en contratos: no es la autoridad -- otro DM escribiendo no toca tu SavedVariable --
-- pero permite limpiar aunque la fase pierda su manifiesto. El fallo es asimetrico a favor:
-- claves de mas se vacian sin dano, claves de menos dejan las cosas como sin espejo.
local function EspejoLocal()
  HarfordLootPhaseStore = HarfordLootPhaseStore or {}
  local fase = tostring((Store() and Store().GetPhaseId()) or "?")
  HarfordLootPhaseStore[fase] = HarfordLootPhaseStore[fase] or {}
  return HarfordLootPhaseStore[fase], HarfordLootPhaseStore, fase
end

function API.GetLocalManifest()
  return (EspejoLocal())
end

------------------------------------------------------------
-- Disponibilidad
------------------------------------------------------------

function API.IsAvailable()
  local S = Store()
  return S ~= nil and S.IsAvailable()
end

function API.CanWrite()
  local S = Store()
  return S ~= nil and S.CanWrite()
end

------------------------------------------------------------
-- Manifiesto
------------------------------------------------------------

-- Devuelve la UNION de lo que declara la fase y lo que recuerda el espejo local.
function API.LoadManifest(callback)
  local S = Store()
  if not S then callback({}, "HarfordPhaseStore no disponible"); return end
  S.Read(CLAVE_MANIFIESTO, function(lista, err)
    callback(S.MergeKeys(lista, (EspejoLocal())), err)
  end)
end

local function EscribirManifiesto(claves)
  local S = Store()
  if not S then return false end
  local _, tabla, fase = EspejoLocal()
  local copia = {}
  for i, k in ipairs(claves) do copia[i] = tostring(k) end
  tabla[fase] = copia
  return S.Write(CLAVE_MANIFIESTO, claves)
end

-- Anade una clave al manifiesto sin reescribirlo entero desde cero. Es lee-modifica-escribe
-- asincrono, asi que dos DM a la vez pueden pisarse; lo cubren la union, el espejo local y
-- `RebuildManifest`, que reconstruye el manifiesto desde el registro local del DM.
local function RegistrarClave(clave, callback)
  API.LoadManifest(function(claves)
    for _, k in ipairs(claves) do
      if k == clave then
        if callback then callback(true) end
        return
      end
    end
    claves[#claves + 1] = clave
    local ok = EscribirManifiesto(claves)
    if callback then callback(ok) end
  end)
end

local function OlvidarClave(clave, callback)
  API.LoadManifest(function(claves)
    local out = {}
    for _, k in ipairs(claves) do
      if k ~= clave then out[#out + 1] = k end
    end
    local ok = EscribirManifiesto(out)
    if callback then callback(ok) end
  end)
end

------------------------------------------------------------
-- Escritura
------------------------------------------------------------

-- Guarda la tabla de una criatura. `tabla` son entradas {itemID, chance, min, max}.
function API.SetCreatureLoot(creatureId, tabla, callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end
  local clave = ClaveCriatura(creatureId)
  if not clave then
    if callback then callback(false, nil, "id de criatura invalido") end
    return
  end

  local ok, err = S.Write(clave, tabla or {})
  if not ok then
    if callback then callback(false, nil, err) end
    return
  end
  cache[clave] = { datos = tabla or {}, cuando = Ahora() }
  RegistrarClave(clave, function()
    if callback then callback(true, creatureId) end
  end)
end

function API.ClearCreatureLoot(creatureId, callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end
  local clave = ClaveCriatura(creatureId)
  if not clave then
    if callback then callback(false, nil, "id de criatura invalido") end
    return
  end
  S.WipeKey(clave, 4)
  cache[clave] = nil
  OlvidarClave(clave, function()
    if callback then callback(true, creatureId) end
  end)
end

function API.SetGlobalLoot(tabla, callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end
  local ok, err = S.Write(CLAVE_GLOBAL, tabla or {})
  if not ok then
    if callback then callback(false, nil, err) end
    return
  end
  cache[CLAVE_GLOBAL] = { datos = tabla or {}, cuando = Ahora() }
  RegistrarClave(CLAVE_GLOBAL, function()
    if callback then callback(true) end
  end)
end

------------------------------------------------------------
-- Lectura
------------------------------------------------------------

local function LeerCacheado(clave, callback)
  local S = Store()
  if not S then callback(nil, "HarfordPhaseStore no disponible"); return end

  local guardado = cache[clave]
  if guardado and (Ahora() - guardado.cuando) < TTL_CACHE then
    callback(guardado.datos)
    return
  end

  S.Read(clave, function(tabla, err)
    if tabla then cache[clave] = { datos = tabla, cuando = Ahora() } end
    callback(tabla, err)
  end)
end

function API.LoadCreatureLoot(creatureId, callback)
  local clave = ClaveCriatura(creatureId)
  if not clave then callback(nil, "id de criatura invalido"); return end
  LeerCacheado(clave, callback)
end

function API.LoadGlobalLoot(callback)
  LeerCacheado(CLAVE_GLOBAL, callback)
end

function API.ClearCache(creatureId)
  if creatureId == nil then cache = {}; return end
  local clave = ClaveCriatura(creatureId)
  if clave then cache[clave] = nil end
end

------------------------------------------------------------
-- Mantenimiento
------------------------------------------------------------

-- Reconstruye el manifiesto desde el registro local del DM. Es la valvula de escape cuando
-- dos DM escribiendo a la vez lo dejan incompleto: las claves son deducibles de los ids que
-- el DM ya tiene, asi que el manifiesto siempre se puede rehacer.
function API.RebuildManifest(callback)
  if not API.CanWrite() then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end

  API.LoadManifest(function(viejas)
    local claves = { CLAVE_MANIFIESTO }
    if type(_G.HarfordLootGlobalLootRegistry) == "table"
      and #_G.HarfordLootGlobalLootRegistry > 0 then
      claves[#claves + 1] = CLAVE_GLOBAL
    end
    -- Solo las que de verdad tienen tabla: `PublishAll` no escribe las vacias, asi que
    -- declararlas aqui pondria en el manifiesto claves que no existen y despistaria al DM
    -- cuando liste lo que hay escrito.
    for creatureId, tabla in pairs(_G.HarfordLootLootRegistry or {}) do
      local clave = ClaveCriatura(creatureId)
      if clave and type(tabla) == "table" and #tabla > 0 then
        claves[#claves + 1] = clave
      end
    end

    -- Lo que el manifiesto viejo declaraba y el registro local ya no reconoce se conserva:
    -- puede ser de otro DM. Reconstruir NO debe borrar trabajo ajeno.
    local S = Store()
    local final = S and S.MergeKeys(claves, viejas) or claves
    EscribirManifiesto(final)
    if callback then callback(true, #final) end
  end)
end

-- Sube de golpe el registro local entero. Es la migracion inicial: a partir de ahi, cada
-- edicion escribe solo su criatura.
function API.PublishAll(callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end

  local claves, escritas, fallos = { CLAVE_MANIFIESTO }, 0, 0

  local global = _G.HarfordLootGlobalLootRegistry
  if type(global) == "table" and #global > 0 then
    if S.Write(CLAVE_GLOBAL, global) then
      claves[#claves + 1] = CLAVE_GLOBAL
      escritas = escritas + 1
    else
      fallos = fallos + 1
    end
  end

  for creatureId, tabla in pairs(_G.HarfordLootLootRegistry or {}) do
    local clave = ClaveCriatura(creatureId)
    if clave and type(tabla) == "table" and #tabla > 0 then
      if S.Write(clave, tabla) then
        claves[#claves + 1] = clave
        escritas = escritas + 1
      else
        fallos = fallos + 1
      end
    end
  end

  API.LoadManifest(function(viejas)
    EscribirManifiesto(S.MergeKeys(claves, viejas))
    cache = {}
    if callback then callback(fallos == 0, escritas, fallos) end
  end)
end

-- Vacia todo lo que el manifiesto declare. Es lo mas cerca que se puede estar de borrar por
-- prefijo: el servidor no ofrece esa operacion.
function API.PurgeAll(callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end

  API.LoadManifest(function(claves)
    local borradas = {}
    for _, clave in ipairs(claves) do
      if clave ~= CLAVE_MANIFIESTO then
        S.WipeKey(clave, 4)
        borradas[#borradas + 1] = clave
      end
    end
    S.WipeKey(CLAVE_GLOBAL, 4)
    S.WipeKey(CLAVE_MANIFIESTO, 8)
    local _, tabla, fase = EspejoLocal()
    tabla[fase] = nil
    cache = {}
    if callback then callback(true, borradas) end
  end)
end

function API.GetKeys()
  return CLAVE_MANIFIESTO, CLAVE_GLOBAL, PREFIJO_CRIATURA
end
