HarfordReputationPhase = HarfordReputationPhase or {}
local API = HarfordReputationPhase

------------------------------------------------------------
-- Definiciones de faccion guardadas EN LA FASE.
--
-- Sube SOLO el catalogo: `factions` (que facciones existen) y `groups` (como se agrupan y
-- ordenan en el panel). La reputacion acumulada de cada personaje (`players`) es personal y
-- NO sale de su cliente. `guilds`, `npcLinks` y `logs` son restos obsoletos y tampoco viajan.
--
-- UNA SOLA CLAVE, no una por faccion. El motivo no es el tamano sino la longitud de clave:
-- `HarfordReputation.NormalizeId` construye el id desde el NOMBRE de la faccion sin truncar,
-- asi que con un prefijo de 14 caracteres una faccion con nombre largo pasaria del tope de
-- 100 y el servidor lanzaria error duro. Las facciones son pocas y cambian poco, asi que
-- caben juntas; si algun dia crecieran, el troceado las parte solo.
--
--   HARFORD_REP_KEYS   manifiesto
--   HARFORD_REP_ALL    { factions = {...}, groups = {...}, meta = { by, at } }
------------------------------------------------------------

local CLAVE_MANIFIESTO = "HARFORD_REP_KEYS"
local CLAVE_TODO = "HARFORD_REP_ALL"

local function Store()
  return _G.HarfordPhaseStore
end

local function Rep()
  return _G.HarfordReputation
end

local function Yo()
  return (UnitName and UnitName("player")) or "?"
end

------------------------------------------------------------
-- Estado local
------------------------------------------------------------

-- Espejo del manifiesto y sello de lo ultimo aplicado, por fase. El sello guarda tambien los
-- ids que se vieron: sin ellos no se puede distinguir "esta faccion la borre yo" de "esta la
-- anadio otro DM", que es justo lo que evita destruir trabajo ajeno al publicar.
local function EstadoLocal()
  HarfordReputationPhaseStore = HarfordReputationPhaseStore or {}
  local fase = tostring((Store() and Store().GetPhaseId()) or "?")
  HarfordReputationPhaseStore[fase] = HarfordReputationPhaseStore[fase] or {}
  return HarfordReputationPhaseStore[fase], HarfordReputationPhaseStore, fase
end

function API.IsAvailable()
  local S = Store()
  return S ~= nil and S.IsAvailable()
end

function API.CanWrite()
  local S = Store()
  return S ~= nil and S.CanWrite()
end

------------------------------------------------------------
-- Lectura
------------------------------------------------------------

function API.Load(callback)
  local S = Store()
  if not S then callback(nil, "HarfordPhaseStore no disponible"); return end
  S.Read(CLAVE_TODO, callback)
end

-- Aplica el catalogo de la fase sobre el store local. NUNCA toca `players`.
-- `reemplazar` retira las facciones locales que la fase ya no declara; sin el, una faccion
-- borrada por otro DM reviviria en el siguiente que publique.
function API.Apply(payload, reemplazar)
  local R = Rep()
  if not (R and R.EnsureStore) then return 0, 0 end
  if type(payload) ~= "table" then return 0, 0 end

  local store = R.EnsureStore()
  if type(store) ~= "table" then return 0, 0 end

  store.factions = store.factions or {}
  store.groups = store.groups or {}

  local aplicadas, retiradas = 0, 0
  local enFase = {}

  for id, faccion in pairs(payload.factions or {}) do
    if type(faccion) == "table" then
      enFase[tostring(id)] = true
      store.factions[tostring(id)] = faccion
      aplicadas = aplicadas + 1
    end
  end

  if reemplazar then
    for id in pairs(store.factions) do
      if not enFase[tostring(id)] then
        store.factions[tostring(id)] = nil
        retiradas = retiradas + 1
      end
    end
  end

  if type(payload.groups) == "table" then
    store.groups = payload.groups
  end

  -- Mismo refresco que usa el propio modulo de reputacion al cambiar una faccion.
  if HarfordReputationUI and HarfordReputationUI.Refresh then HarfordReputationUI.Refresh() end
  return aplicadas, retiradas
end

-- Trae el catalogo y lo aplica si ha cambiado. Como en el tablon, el sello decide: si es el
-- mismo que la ultima vez, no se toca nada.
function API.EnsureCatalog(force, callback)
  if not API.IsAvailable() then
    if callback then callback(false, nil, "almacen de fase no disponible") end
    return
  end

  API.Load(function(payload, err)
    if not payload then
      if callback then callback(false, nil, err) end
      return
    end

    local estado, _, fase = EstadoLocal()
    local meta = payload.meta or {}
    if not force and meta.at and estado.at and meta.at == estado.at then
      if callback then callback(true, 0) end
      return
    end

    -- SALVAGUARDA: si la fase dice CERO facciones y tu tienes catalogo, es muchisimo mas
    -- probable que sea una escritura a medias, una purga ajena o un dato corrupto que una
    -- decision real de borrarlo todo. Aplicar el reemplazo ahi te dejaria sin catalogo y,
    -- como el tuyo era el ultimo que quedaba, sin forma de recuperarlo.
    -- Los PUNTOS nunca corren peligro: viven en store.players y no se tocan aqui.
    local R2 = Rep()
    local locales = 0
    if R2 and R2.EnsureStore then
      for _ in pairs(R2.EnsureStore().factions or {}) do locales = locales + 1 end
    end
    local entrantes = 0
    for _ in pairs(payload.factions or {}) do entrantes = entrantes + 1 end
    if entrantes == 0 and locales > 0 then
      if HarfordChat and HarfordChat.Print then
        HarfordChat.Print("La fase no declara ninguna faccion y tu tienes " .. locales
          .. ". No se toca nada: usa Compartir estructura para volver a escribirlas.")
      end
      if callback then callback(false, nil, "la fase vino vacia") end
      return
    end

    local aplicadas, retiradas = API.Apply(payload, true)
    -- De que fase es el catalogo que tienes cargado.
    local R = Rep()
    if R and R.EnsureStore then R.EnsureStore().phaseOrigin = tostring(fase) end

    local ids = {}
    for id in pairs(payload.factions or {}) do ids[#ids + 1] = tostring(id) end
    estado.at, estado.by, estado.ids = meta.at, meta.by, ids
    HarfordReputationPhaseStore[fase] = estado

    if callback then callback(true, aplicadas, retiradas) end
  end)
end

------------------------------------------------------------
-- Escritura
------------------------------------------------------------

-- Publicar NO pisa: se trae lo que hay y se fusiona a tres bandas, igual que el tablon.
--   * en la fase y en tu store  -> mandas tu
--   * en la fase, no en el tuyo, y LO VISTE  -> la borraste tu -> se retira
--   * en la fase, no en el tuyo, y no lo viste -> la anadio otro DM -> se adopta
function API.Publish(quiet, callback)
  local S, R = Store(), Rep()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end
  if not (R and R.EnsureStore) then
    if callback then callback(false, nil, "HarfordReputation no disponible") end
    return
  end

  -- ACOTADO A LA FASE: el catalogo se puede usar en varias, pero el que tienes cargado es de
  -- UNA. Publicarlo en otra subiria facciones que no son de aqui y, peor, la fusion retiraria
  -- las de esta fase que la otra no tenia.
  local faseActual = Store().GetPhaseId()
  local origenCat = R.EnsureStore().phaseOrigin
  if origenCat and tostring(origenCat) ~= tostring(faseActual) then
    if HarfordChat and HarfordChat.Print then
      HarfordChat.Print("Tu catalogo de facciones se cargo de la fase " .. tostring(origenCat)
        .. " y estas en la " .. tostring(faseActual) .. ". Recargalo antes de publicar.")
    end
    if callback then callback(false, nil, "el catalogo es de otra fase") end
    return
  end

  API.Load(function(enFase)
    enFase = type(enFase) == "table" and enFase or {}
    local store = R.EnsureStore()
    local estado, _, fase = EstadoLocal()

    local vistos = {}
    for _, id in ipairs(estado.ids or {}) do vistos[tostring(id)] = true end

    local salida, adoptadas, retiradas = {}, 0, 0
    for id, faccion in pairs(store.factions or {}) do
      salida[tostring(id)] = faccion
    end

    for id, faccion in pairs(enFase.factions or {}) do
      id = tostring(id)
      if salida[id] == nil then
        if vistos[id] then
          retiradas = retiradas + 1
        else
          salida[id] = faccion
          adoptadas = adoptadas + 1
        end
      end
    end

    local payload = {
      factions = salida,
      groups = store.groups or {},
      meta = { by = Yo(), at = (time and time()) or 0 },
    }

    local ok, err = S.Write(CLAVE_TODO, payload)
    if not ok then
      if callback then callback(false, nil, err) end
      return
    end
    S.Write(CLAVE_MANIFIESTO, { CLAVE_TODO, CLAVE_MANIFIESTO })

    local ids = {}
    for id in pairs(salida) do ids[#ids + 1] = id end
    estado.at, estado.by, estado.ids = payload.meta.at, payload.meta.by, ids
    HarfordReputationPhaseStore[fase] = estado
    store.phaseOrigin = tostring(fase)

    -- Lo adoptado tambien entra en el store local, para que el panel lo enseñe al momento.
    if adoptadas > 0 then API.Apply(payload, false) end

    local n = 0
    for _ in pairs(salida) do n = n + 1 end
    if not quiet and HarfordChat and HarfordChat.Print then
      HarfordChat.Print(string.format("Facciones publicadas: %d%s%s", n,
        adoptadas > 0 and (", " .. adoptadas .. " de otros DM") or "",
        retiradas > 0 and (", " .. retiradas .. " retiradas") or ""))
    end
    if callback then callback(true, n, { adoptadas = adoptadas, retiradas = retiradas }) end
  end)
end

function API.Purge(callback)
  local S = Store()
  if not (S and API.CanWrite()) then
    if callback then callback(false, nil, "sin permiso de escritura en la fase") end
    return
  end
  S.WipeKey(CLAVE_TODO, 8)
  S.WipeKey(CLAVE_MANIFIESTO, 4)
  local _, tabla, fase = EstadoLocal()
  tabla[fase] = nil
  if callback then callback(true, 2) end
end

function API.GetKeys()
  return CLAVE_MANIFIESTO, CLAVE_TODO
end

function API.GetLocalState()
  return (EstadoLocal())
end

------------------------------------------------------------
-- Carga automatica
------------------------------------------------------------

-- Sin esto el catalogo solo llegaba si alguien lo pedia a mano por debug: un jugador que
-- entrara en la fase no veia ninguna faccion. Por eventos, nunca por sondeo.
do
  local S = _G.HarfordPhaseStore
  if S and S.OnPhaseChanged then
    S.OnPhaseChanged("HarfordReputationPhase", function()
      API.EnsureCatalog(true)
    end)
  end
end

------------------------------------------------------------
-- Publicacion automatica
------------------------------------------------------------

-- Sin esto el catalogo solo se subia a mano desde debug, asi que en juego normal la fase
-- nunca se enteraba de una faccion nueva.
--
-- Coalescido: crear un grupo, meterle facciones y ordenarlas son muchos cambios seguidos y
-- una sola publicacion. Un `C_Timer.After` de un disparo, no un ticker.
local COALESCE = 2
local armado = false

function API.SyncSoon()
  if armado then return true end
  if not (API.IsAvailable() and API.CanWrite()) then return false end
  armado = true
  C_Timer.After(COALESCE, function()
    armado = false
    -- SOLO ACTUALIZA, NO SIEMBRA. Si la fase no tiene catalogo, no se escribe: entrar en la
    -- fase de otro y tocar una faccion no debe volcarle tu catalogo entero. Sembrar una fase
    -- es deliberado y va por `Publish` directo (boton/comando).
    API.Load(function(payload)
      if type(payload) ~= "table" then return end
      API.Publish(true)
    end)
  end)
  return true
end

-- Se envuelven los mutadores publicos en vez de tocar `HarfordReputation`: asi el modulo de
-- reputacion no necesita saber que existe la fase, y si este no carga, todo sigue igual.
do
  local R = Rep()
  for _, nombre in ipairs(R and {
    "CreateFaction", "UpdateFaction", "DeleteFaction", "SetFactionGroup",
    "CreateGroup", "CreateSubgroup", "RenameGroup", "RenameSubgroup", "DeleteGroup",
  } or {}) do
    local original = R[nombre]
    if type(original) == "function" then
      R[nombre] = function(...)
        local a, b, c = original(...)
        API.SyncSoon()
        return a, b, c
      end
    end
  end
end
