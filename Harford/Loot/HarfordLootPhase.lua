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

-- Los FALLOS tambien se cachean, con su propio plazo mas corto. La mayoria de criaturas de
-- una zona no tienen tabla propia; sin esto, cada cadaver vacio volveria a preguntar a la
-- fase y se comeria el cupo de lecturas para nada.
local TTL_FALLO = 60

local function LeerCacheado(clave, callback)
  local S = Store()
  if not S then callback(nil, "HarfordPhaseStore no disponible"); return end

  local guardado = cache[clave]
  if guardado then
    local plazo = guardado.datos and TTL_CACHE or TTL_FALLO
    if (Ahora() - guardado.cuando) < plazo then
      callback(guardado.datos or nil)
      return
    end
  end

  S.Read(clave, function(tabla, err)
    cache[clave] = { datos = tabla or false, cuando = Ahora() }
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

------------------------------------------------------------
-- Aislamiento entre fases
------------------------------------------------------------

-- Que ids se han inyectado en HarfordLootLootRegistry desde la fase.
--
-- IMPORTA: ese registro es una SavedVariable GLOBAL, pero las tablas vienen de UNA fase. Sin
-- retirarlas al cambiar, el loot de la fase A se veria en la B y ademas quedaria persistido
-- en disco. Se recuerda exactamente lo inyectado para poder quitarlo sin tocar lo que el DM
-- tenga definido a mano.
local inyectados = {}

function API.NoteInjected(id)
  if id ~= nil then inyectados[id] = true end
end

function API.ClearInjected()
  local n = 0
  for id in pairs(inyectados) do
    if _G.HarfordLootLootRegistry then _G.HarfordLootLootRegistry[id] = nil end
    n = n + 1
  end
  inyectados = {}
  return n
end

-- Al cambiar de fase, TODO lo que venia de la anterior deja de valer: la cache y lo inyectado
-- en el registro. Por eventos, nunca por sondeo.
do
  local S = _G.HarfordPhaseStore
  if S and S.OnPhaseChanged then
    S.OnPhaseChanged("HarfordLootPhase", function()
      API.ClearInjected()
      API.ClearCache()
    end)
  end
end

------------------------------------------------------------
-- Publicacion automatica
------------------------------------------------------------

-- Escribe en la fase el ambito que se acaba de editar. `scope` es "GLOBAL" o un id de
-- criatura, igual que lo maneja el editor de loot de HarfordAdmin.
--
-- Coalescido: editar varias entradas seguidas de la misma criatura es lo normal, y cada
-- pulsacion no debe convertirse en una escritura. Un solo `C_Timer.After` por ambito, que NO
-- es un ticker: se arma al primer cambio y se desarma al disparar.
local COALESCE = 1.5
local pendientesDeEscribir, armado = {}, false

local function VolcarAmbitos(cola)
  for scope in pairs(cola) do
    if scope == "GLOBAL" then
      API.SetGlobalLoot(_G.HarfordLootGlobalLootRegistry or {})
    else
      local tabla = (_G.HarfordLootLootRegistry or {})[scope]
      if type(tabla) == "table" and #tabla > 0 then
        API.SetCreatureLoot(scope, tabla)
      else
        API.ClearCreatureLoot(scope)
      end
    end
  end
end

local function Volcar()
  armado = false
  local cola = pendientesDeEscribir
  pendientesDeEscribir = {}
  -- SOLO ACTUALIZA, NO SIEMBRA. Si esta fase no tiene manifiesto de loot, no se escribe:
  -- editar una tabla estando en la fase de otro no debe volcarle nada. Sembrar va por
  -- `PublishAll` (boton Compartir o comando).
  local S = Store()
  if not S then return end
  S.Read(CLAVE_MANIFIESTO, function(manifiesto)
    if type(manifiesto) ~= "table" or #manifiesto == 0 then return end
    VolcarAmbitos(cola)
  end)
end

function API.SyncScope(scope)
  if scope == nil or not API.IsAvailable() or not API.CanWrite() then return false end
  pendientesDeEscribir[scope] = true
  if armado then return true end
  armado = true
  C_Timer.After(COALESCE, Volcar)
  return true
end

------------------------------------------------------------
-- Historial de saqueo
------------------------------------------------------------

-- Que se ha cogido ya de cada cadaver. Con NPCs PERMANENTES de fase el estado tiene que ser
-- permanente tambien: si no, alguien que llega mas tarde vuelve a ver un loot que ya no esta.
--
-- La clave guarda la tabla YA RESUELTA (que salio y que queda), o sea lo mismo que
-- HarfordLootTaggedCreatureRegistry[guid]. Asi se conserva la tirada, no solo el "vacio".
--
-- PERMISOS: quien saquea suele ser un jugador normal y NO puede escribir en la fase. Por eso
-- `SaveTaken` no falla ruidosamente si no hay permiso: el estado sigue viajando por
-- HARFORDLOOT entre los presentes, como hasta ahora, y lo persiste el primer oficial que
-- pase por ahi. Degradado, no roto.
local PREFIJO_SAQUEO = "HARFORD_LOOT_T_"

local function ClaveSaqueo(guid)
  guid = tostring(guid or "")
  if guid == "" then return nil end
  local clave = PREFIJO_SAQUEO .. guid
  local S = Store()
  if S and not S.KeyFits(clave) then return nil end
  return clave
end

function API.LoadTaken(guid, callback)
  local clave = ClaveSaqueo(guid)
  if not clave then callback(nil, "guid invalido"); return end
  LeerCacheado(clave, callback)
end

function API.SaveTaken(guid, tabla, callback)
  local S = Store()
  local clave = ClaveSaqueo(guid)
  if not (S and clave) then
    if callback then callback(false, nil, "guid invalido") end
    return
  end
  if not API.CanWrite() then
    -- Sin permiso no es un error: lo persistira un oficial. Ver nota de arriba.
    if callback then callback(false, nil, "sin permiso") end
    return
  end

  local ok, err = S.Write(clave, tabla or {})
  if not ok then
    if callback then callback(false, nil, err) end
    return
  end
  cache[clave] = { datos = tabla or {}, cuando = Ahora() }
  RegistrarClave(clave, function()
    if callback then callback(true, guid) end
  end)
end

-- Olvida el saqueo de UN cadaver: vuelve a estar entero.
function API.ClearTaken(guid, callback)
  local S = Store()
  local clave = ClaveSaqueo(guid)
  if not (S and clave and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso o guid invalido") end
    return
  end
  S.WipeKey(clave, 4)
  cache[clave] = nil
  OlvidarClave(clave, function()
    if callback then callback(true, guid) end
  end)
end

-- Olvida TODO el historial de saqueo de la fase, dejando intactas las TABLAS de loot.
-- Es la operacion de "reiniciar el saqueo": todo vuelve a estar por coger.
function API.ClearAllTaken(callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end

  API.LoadManifest(function(claves, err)
    if err then
      if callback then callback(false, nil, err) end
      return
    end

    local quedan, borradas = {}, {}
    for _, k in ipairs(claves) do
      k = tostring(k)
      if k:sub(1, #PREFIJO_SAQUEO) == PREFIJO_SAQUEO then
        S.WipeKey(k, 4)
        cache[k] = nil
        borradas[#borradas + 1] = k
      else
        quedan[#quedan + 1] = k
      end
    end

    -- El manifiesto se reescribe SIN las de saqueo, pero conservando las tablas de loot.
    EscribirManifiesto(quedan)
    -- Y en local: lo resuelto de cada cadaver deja de valer.
    if _G.HarfordLootTaggedCreatureRegistry then
      wipe(_G.HarfordLootTaggedCreatureRegistry)
    end
    if callback then callback(true, borradas) end
  end)
end

function API.GetTakenPrefix()
  return PREFIJO_SAQUEO
end
