HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.Phase = TC.Phase or {}
local Phase = TC.Phase

------------------------------------------------------------
-- Tablon de contratos guardado EN LA FASE (Epsilon PhaseAddonData).
--
-- A diferencia de HarfordContractsComm (SNAPBEGIN/PUB/SNAPEND), esto NO exige que el DM este
-- conectado: el dato vive en el servidor, ligado a la fase, y cualquiera que entre lo lee.
--
-- Forma (medida sobre el tablon real, ver AGENTS.md):
--   HARFORD_TC_INDEX  -> una fila resumida por contrato. 986 de 3000 caracteres con 17
--                        contratos, asi que pintar el tablon entero cuesta UNA llamada.
--   HARFORD_TC_<id>   -> el contrato publico completo, ~1 segmento cada uno. Solo se baja
--                        cuando alguien abre ese contrato.
--
-- CONTRATO DE LOS CALLBACKS: siempre callback(ok, datos, error). El mensaje de error va en
-- el TERCER hueco, nunca en el de los datos: devolver una cadena donde se espera una lista
-- hace que `#datos` cuente sus letras y que `ipairs` reviente.
--
-- El indice se REGENERA ENTERO desde la BD local en cada publicacion; nunca se lee para
-- modificarlo. Eso evita el lee-modifica-escribe asincrono que obligaria a un cerrojo entre
-- DMs, y deja la misma semantica que ya tiene el snapshot actual: el ultimo que publica manda,
-- con su tablon completo.
------------------------------------------------------------

local CLAVE_INDICE = "HARFORD_TC_INDEX"
local PREFIJO_BLOQUE = "HARFORD_TC_"
-- Manifiesto: la lista de TODAS las claves que Harford ha escrito en esta fase.
-- Existe porque el servidor NO deja listar claves ni borrar por prefijo (la API entera son
-- GetPhaseAddonData/SetPhaseAddonData sobre una clave exacta). Sin el, un bloque que se
-- quede huerfano es irrecuperable: nadie puede saber que existe.
local CLAVE_MANIFIESTO = "HARFORD_TC_KEYS"
local MAX_CLAVE = 96 -- el servidor corta en 100 y el troceado anade "_2", "_3"...
local ESPERA_LECTURA = 8

-- Campos que viajan en el INDICE: exactamente los que pinta la fila del tablon
-- (HarfordContractsUI: icono, titulo coloreado por dificultad, meta duracion||estado,
-- recompensa) mas los que filtran y buscan.
local CAMPOS_INDICE = {
  "id", "title", "difficulty", "status", "duration", "rewardText", "category", "icon",
}

-- Campos que viajan en el BLOQUE completo. Es una LISTA BLANCA a proposito: con lista negra,
-- cualquier campo privado que se anada al contrato en el futuro se subiria sin querer.
-- `prep` y `privateNotes` no estan, y no deben estar nunca.
local CAMPOS_BLOQUE = {
  "id", "title", "category", "difficulty", "rewardText", "duration", "players", "location",
  "status", "description", "objectives", "sortOrder", "icon",
  "rewardXP", "rewardRep", "rewardReps", "rewardMoney", "rewardItems",
  "worldNpc", "pickupText", "progressText", "turnInText",
}

------------------------------------------------------------
-- Disponibilidad
------------------------------------------------------------

local function Lib()
  return EpsilonLib and EpsilonLib.PhaseAddonData
end

function Phase.IsAvailable()
  return (Lib() ~= nil) and (C_Epsilon ~= nil) and (C_Epsilon.GetPhaseAddonData ~= nil)
end

function Phase.GetPhaseId()
  if C_Epsilon and C_Epsilon.GetPhaseId then return C_Epsilon.GetPhaseId() end
  return nil
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function ClaveBloque(contractId)
  local clave = PREFIJO_BLOQUE .. tostring(contractId or "")
  if #clave > MAX_CLAVE then return nil, clave end
  return clave
end

local function Proyectar(contract, campos)
  local out = {}
  for _, campo in ipairs(campos) do
    local valor = contract[campo]
    if valor ~= nil and valor ~= "" then out[campo] = valor end
  end
  return out
end

local function EsPublico(contract)
  return type(contract) == "table"
      and contract.status ~= "draft"
      and contract.status ~= "archived"
end

-- El servidor VALIDA y lanza error Lua (p.ej. clave > 100); sin pcall una escritura invalida
-- aborta la publicacion entera y deja el tablon a medias.
local function Escribir(clave, tabla)
  local L = Lib()
  if not L then return false, "EpsilonLib no disponible" end
  local ok, err = pcall(L.SaveTable, clave, tabla)
  if not ok then
    return false, tostring(err):gsub("^.*%.lua:%d+: ", "")
  end
  return true
end

-- No hay ruta de error en la lectura: si el servidor calla, el callback no se llama JAMAS.
-- Sin este plazo cualquier UI que dependa de esto se queda colgada sin decir nada.
local function LeerTabla(clave, alRecibir)
  local L = Lib()
  if not L then alRecibir(nil, "EpsilonLib no disponible"); return end

  local fase = Phase.GetPhaseId()
  local contestado = false

  L.LoadTable(clave, function(tabla)
    if contestado then return end
    contestado = true
    -- La fase pudo cambiar mientras la lectura viajaba; ese dato ya no es de aqui.
    if Phase.GetPhaseId() ~= fase then
      alRecibir(nil, "cambio de fase durante la lectura")
      return
    end
    alRecibir(type(tabla) == "table" and tabla or nil)
  end)

  C_Timer.After(ESPERA_LECTURA, function()
    if contestado then return end
    contestado = true
    alRecibir(nil, "sin respuesta del servidor")
  end)
end

------------------------------------------------------------
-- Publicar (DM)
------------------------------------------------------------

-- Escribe el tablon entero: un bloque por contrato publico, y despues el indice.
-- ORDEN DELIBERADO: bloques primero, indice al final. Si esto se corta a medias quedan
-- bloques huerfanos (invisibles, inofensivos) en vez de un indice apuntando a la nada.
function Phase.Publish(quiet)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para publicar en la fase.")
    return false
  end
  if not Phase.IsAvailable() then
    TC.Print("El almacen de fase de Epsilon no esta disponible.")
    return false
  end

  local publicos, fallos = {}, 0
  for _, contract in ipairs(TC.GetDB().contracts or {}) do
    if EsPublico(contract) then publicos[#publicos + 1] = contract end
  end

  for _, contract in ipairs(publicos) do
    local clave, larga = ClaveBloque(contract.id)
    if not clave then
      fallos = fallos + 1
      TC.Print("Id demasiado largo para una clave de fase: " .. tostring(larga))
    else
      local ok, err = Escribir(clave, Proyectar(contract, CAMPOS_BLOQUE))
      if not ok then
        fallos = fallos + 1
        TC.Print("No se pudo escribir " .. tostring(contract.title) .. ": " .. tostring(err))
      end
    end
  end

  local indice = {}
  for _, contract in ipairs(publicos) do
    indice[#indice + 1] = Proyectar(contract, CAMPOS_INDICE)
  end
  -- Sello: quien publico y cuando. Va como campo con NOMBRE dentro de la lista, asi que
  -- ipairs lo ignora y no hace falta ni clave aparte ni cambiar el formato.
  indice.meta = { by = (UnitName and UnitName("player")) or "?", at = (time and time()) or 0 }

  local ok, err = Escribir(CLAVE_INDICE, indice)
  if not ok then
    TC.SetSyncStatus("Fase: fallo al escribir el indice (" .. tostring(err) .. ")")
    TC.Print("No se pudo escribir el indice en la fase: " .. tostring(err))
    return false
  end

  local resumen = string.format("Fase %s: %d contratos publicados",
    tostring(Phase.GetPhaseId()), #publicos - fallos)
  TC.SetSyncStatus(resumen)
  if not quiet then
    TC.Print(resumen .. (fallos > 0 and (" (" .. fallos .. " con error)") or ""))
  end
  return fallos == 0, #publicos - fallos
end

-- Quita un contrato del tablon de fase. Borrar es escribir cadena vacia: no hay borrado real.
-- El indice se regenera solo, asi que basta con vaciar el bloque y volver a publicar.
function Phase.DeleteContract(contractId)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on.")
    return false
  end
  local clave = ClaveBloque(contractId)
  if not clave then return false end
  local ok = pcall(C_Epsilon.SetPhaseAddonData, clave, "")
  -- Los segmentos sobrantes no se limpian solos al encoger; se vacian a mano.
  for i = 2, 4 do pcall(C_Epsilon.SetPhaseAddonData, clave .. "_" .. i, "") end
  return ok
end

------------------------------------------------------------
-- Leer
------------------------------------------------------------

-- Trae el indice: una llamada, y con eso se pinta el tablon entero.
function Phase.LoadIndex(callback)
  if not Phase.IsAvailable() then
    if callback then callback(nil, "almacen de fase no disponible") end
    return
  end
  LeerTabla(CLAVE_INDICE, function(indice, err)
    if not indice then
      if callback then callback(nil, err or "indice vacio") end
      return
    end
    if callback then callback(indice) end
  end)
end

-- Trae UN contrato completo. Es lo unico que se baja al abrir una fila.
function Phase.LoadContract(contractId, callback)
  local clave = ClaveBloque(contractId)
  if not clave then
    if callback then callback(nil, "id demasiado largo") end
    return
  end
  LeerTabla(clave, function(contract, err)
    if callback then callback(contract, err) end
  end)
end

------------------------------------------------------------
-- Aplicar sobre la BD local
------------------------------------------------------------

-- Mete/actualiza las filas del indice como contratos "esbozo": llevan lo justo para pintar
-- la lista y quedan marcados con `_phaseStub` hasta que alguien los abra y se baje el bloque.
function Phase.ApplyIndex(indice)
  if type(indice) ~= "table" then return 0 end
  local db = TC.GetDB()
  db.contracts = db.contracts or {}
  local aplicados = 0

  for _, fila in ipairs(indice) do
    if type(fila) == "table" and fila.id then
      local existente = TC.Data.GetContractById(fila.id)
      if existente then
        for _, campo in ipairs(CAMPOS_INDICE) do
          if fila[campo] ~= nil then existente[campo] = fila[campo] end
        end
      else
        local nuevo = { objectives = {}, rewardItems = {}, description = "", _phaseStub = true }
        for _, campo in ipairs(CAMPOS_INDICE) do nuevo[campo] = fila[campo] end
        table.insert(db.contracts, nuevo)
      end
      aplicados = aplicados + 1
    end
  end

  TC.Refresh()
  return aplicados
end

-- Completa un esbozo con su bloque real.
-- Las recompensas COBRADAS son estado local del grupo, no del mundo: la fase no las conoce.
-- Sin esto, recargar el tablon reseteaba a cero lo que ya se habia repartido y se podia
-- cobrar dos veces. Mismo criterio que UpsertPublicContract en HarfordContractsComm.
local function PreservarCobros(existente, entrante)
  for indice, item in ipairs(entrante.rewardItems or {}) do
    local previo = existente.rewardItems and existente.rewardItems[indice]
    if previo and tonumber(previo.itemId) == tonumber(item.itemId) then
      item.claimed = math.max(tonumber(previo.claimed) or 0, tonumber(item.claimed) or 0)
    end
  end
end

function Phase.ApplyContract(contract)
  if type(contract) ~= "table" or not contract.id then return false end
  local existente = TC.Data.GetContractById(contract.id)
  if not existente then
    contract._phaseStub = nil
    table.insert(TC.GetDB().contracts, contract)
    TC.Refresh()
    return true
  end
  PreservarCobros(existente, contract)
  for _, campo in ipairs(CAMPOS_BLOQUE) do
    if contract[campo] ~= nil then existente[campo] = contract[campo] end
  end
  existente._phaseStub = nil
  TC.Refresh()
  return true
end

-- Carga que REEMPLAZA: lo que el indice no nombre y sea publico, se va. Es lo que hace que
-- un contrato borrado por otro DM no resucite al republicar.
-- OJO: `draft` y `archived` NO estan nunca en la fase, asi que borrar "lo que no este en el
-- indice" a secas se llevaria por delante todos los borradores y el archivo del DM.
function Phase.ApplyIndexReplacing(indice)
  if type(indice) ~= "table" then return 0, 0 end

  local enFase = {}
  for _, fila in ipairs(indice) do
    if type(fila) == "table" and fila.id then enFase[tostring(fila.id)] = true end
  end

  local db = TC.GetDB()
  local retirados = 0
  for i = #(db.contracts or {}), 1, -1 do
    local c = db.contracts[i]
    if EsPublico(c) and not enFase[tostring(c.id)] then
      table.remove(db.contracts, i)
      retirados = retirados + 1
    end
  end

  return Phase.ApplyIndex(indice), retirados
end

-- Ruta completa de cliente: indice -> esbozos en pantalla. Los bloques se piden al abrir.
function Phase.LoadBoard(callback)
  Phase.LoadIndex(function(indice, err)
    if not indice then
      TC.SetSyncStatus("Fase: " .. tostring(err))
      if callback then callback(false, err) end
      return
    end
    local n = Phase.ApplyIndex(indice)
    TC.SetSyncStatus(string.format("Fase %s: %d contratos", tostring(Phase.GetPhaseId()), n))
    if callback then callback(true, n) end
  end)
end

-- ¿Este contrato es un esbozo pendiente de bajar?
function Phase.IsStub(contract)
  return type(contract) == "table" and contract._phaseStub == true
end

function Phase.GetKeys()
  return CLAVE_INDICE, PREFIJO_BLOQUE
end

------------------------------------------------------------
-- Puentes para la UI
------------------------------------------------------------

local ultimaCarga, ultimaFase = 0, nil
local enVuelo = {}
local INTERVALO_MINIMO = 5 -- suelo para que abrir y cerrar la ventana no dispare lecturas seguidas

-- Sello del ultimo indice que aplicamos, por fase. Es lo que permite abrir el tablon sin
-- hacer nada cuando no ha cambiado nada.
local function SelloVisto(fase, nuevo)
  local db = TC.GetDB()
  db.phaseSeen = db.phaseSeen or {}
  fase = tostring(fase or Phase.GetPhaseId() or "?")
  if nuevo ~= nil then db.phaseSeen[fase] = nuevo end
  return db.phaseSeen[fase]
end

-- Trae el tablon al abrir la ventana, sin machacar el servidor si se abre y cierra varias
-- veces seguidas. Cambiar de fase siempre fuerza la recarga: el tablon es otro.
-- Se llama al abrir el tablon. Pide el indice (1 llamada) y compara su sello con el ultimo
-- que aplicamos: si es el mismo no toca NADA, ni refresca. Si cambio, decide segun quien seas.
function Phase.EnsureBoard(force)
  if not Phase.IsAvailable() then return false end

  local fase = Phase.GetPhaseId()
  local ahora = (GetTime and GetTime()) or 0
  if not force and fase == ultimaFase and (ahora - ultimaCarga) < INTERVALO_MINIMO then
    return false
  end
  ultimaCarga, ultimaFase = ahora, fase

  Phase.LoadIndex(function(indice, err)
    if not indice then
      TC.SetSyncStatus("Fase: " .. tostring(err))
      return
    end

    local meta = indice.meta or {}
    local visto = SelloVisto(fase) or {}
    if not force and meta.at and visto.at and meta.at == visto.at then
      return -- nada ha cambiado desde la ultima vez
    end

    -- El DM puede tener ediciones sin publicar: no se le pisa el trabajo por sorpresa.
    -- Solo se le avisa y el decide cuando traerselo.
    if TC.IsDMMode() and not force then
      local quien = tostring(meta.by or "alguien")
      if quien ~= ((UnitName and UnitName("player")) or "?") then
        TC.SetSyncStatus("La fase tiene un tablon mas reciente de " .. quien)
        TC.Print("El tablon de la fase lo publico |cffffd100" .. quien
          .. "|r y es mas nuevo que el tuyo. Cargalo cuando quieras.")
        return
      end
    end

    -- Jugador (o DM forzando): la fase es la verdad. Los publicos que ya no esten se retiran;
    -- los borradores y el archivo NO se tocan, porque nunca viajan a la fase.
    local aplicados, retirados = Phase.ApplyIndexReplacing(indice)
    local ids = {}
    for _, fila in ipairs(indice) do
      if fila and fila.id then ids[#ids + 1] = tostring(fila.id) end
    end
    SelloVisto(fase, { at = meta.at, by = meta.by, ids = ids })
    TC.SetSyncStatus(string.format("Fase %s: %d contratos%s", tostring(fase), aplicados,
      retirados > 0 and (", " .. retirados .. " retirados") or ""))
    if TC.UI and TC.UI.Refresh then TC.UI.Refresh() end
  end)
  return true
end

-- Baja el bloque completo de un contrato que solo esta como esbozo. Es lo que convierte
-- "1 llamada para el tablon" en algo utilizable: el resto llega al abrir cada ficha.
function Phase.EnsureContract(contract)
  if not (Phase.IsStub(contract) and Phase.IsAvailable()) then return false end

  local id = contract.id
  if enVuelo[id] then return false end
  enVuelo[id] = true

  Phase.LoadContract(id, function(completo, err)
    enVuelo[id] = nil
    if not completo then
      TC.SetSyncStatus("Fase: no se pudo abrir el contrato (" .. tostring(err) .. ")")
      return
    end
    Phase.ApplyContract(completo)
    if TC.UI and TC.UI.RefreshDetails then TC.UI.RefreshDetails() end
  end)
  return true
end

------------------------------------------------------------
-- Limpieza
------------------------------------------------------------

-- Vacia una clave y sus posibles segmentos. Borrar es escribir cadena vacia: no hay
-- borrado real, y sobrescribir con menos datos NO limpia los segmentos sobrantes.
function Phase.WipeKey(clave, segmentos)
  if not (C_Epsilon and C_Epsilon.SetPhaseAddonData) then return false end
  local ok = pcall(C_Epsilon.SetPhaseAddonData, clave, "")
  for i = 2, (segmentos or 8) do
    pcall(C_Epsilon.SetPhaseAddonData, clave .. "_" .. i, "")
  end
  return ok
end

-- Bloques que siguen en la fase pero ya no pertenecen al tablon. Se detectan comparando el
-- indice que HAY AHORA en la fase contra los contratos publicos locales; por eso hay que
-- ejecutarlo ANTES de publicar, mientras el indice viejo todavia los nombra.
function Phase.PruneOrphans(callback)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on.")
    if callback then callback(false, nil, "sin modo DM") end
    return
  end

  Phase.LoadIndex(function(indice, err)
    if not indice then
      if callback then callback(false, nil, err) end
      return
    end

    local vigentes = {}
    for _, contract in ipairs(TC.GetDB().contracts or {}) do
      if EsPublico(contract) then vigentes[tostring(contract.id)] = true end
    end

    local limpiados = {}
    for _, fila in ipairs(indice) do
      local id = fila and tostring(fila.id or "")
      if id ~= "" and not vigentes[id] then
        local clave = ClaveBloque(id)
        if clave and Phase.WipeKey(clave, 4) then limpiados[#limpiados + 1] = id end
      end
    end

    if callback then callback(true, limpiados) end
  end)
end

-- Publicacion completa: primero se limpian los huerfanos que el indice viejo aun delata,
-- despues se reescribe el tablon. Si el indice no se puede leer se publica igualmente:
-- dejar basura es peor que no publicar, pero mucho menos malo que perder el tablon.
function Phase.PublishClean(quiet, callback)
  Phase.PruneOrphans(function(ok, limpiados)
    if ok and type(limpiados) == "table" and #limpiados > 0 and not quiet then
      TC.Print("Bloques huerfanos limpiados: " .. #limpiados)
    end
    local pub, n = Phase.Publish(quiet)
    if callback then callback(pub, n, ok and limpiados or nil) end
  end)
end

-- Borra TODO lo que Harford tiene escrito en la fase: cada bloque que el indice nombre y el
-- propio indice. Lo que no este en el indice no se puede alcanzar (no se pueden listar claves).
function Phase.Purge(callback)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on.")
    if callback then callback(false, nil, "sin modo DM") end
    return
  end

  Phase.LoadIndex(function(indice, err)
    local borrados = 0
    for _, fila in ipairs(indice or {}) do
      local clave = fila and fila.id and ClaveBloque(fila.id)
      if clave and Phase.WipeKey(clave, 4) then borrados = borrados + 1 end
    end
    Phase.WipeKey(CLAVE_INDICE, 8)
    ultimaCarga, ultimaFase = 0, nil
    if callback then callback(true, borrados, err) end
  end)
end

------------------------------------------------------------
-- Manifiesto de claves
------------------------------------------------------------

-- ESPEJO LOCAL del manifiesto, por fase. No es la autoridad: otro DM publicando no toca tu
-- SavedVariable, asi que la de la fase es la que refleja la realidad compartida. Sirve como
-- red de seguridad, y el fallo es asimetrico a nuestro favor: si el espejo tiene claves de
-- mas, vaciarlas es inofensivo (escribir vacio sobre lo que ya no existe no hace nada); si
-- tiene de menos, quedamos igual que sin el. Unir las dos listas solo puede encontrar MAS
-- basura, nunca menos.
local function EspejoLocal(fase)
  local db = TC.GetDB()
  db.phaseKeys = db.phaseKeys or {}
  fase = tostring(fase or Phase.GetPhaseId() or "?")
  db.phaseKeys[fase] = db.phaseKeys[fase] or {}
  return db.phaseKeys[fase], db.phaseKeys, fase
end

function Phase.GetLocalManifest()
  return EspejoLocal()
end

-- Devuelve la UNION de lo que declara la fase y lo que recuerda el espejo local.
function Phase.LoadManifest(callback)
  LeerTabla(CLAVE_MANIFIESTO, function(lista, err)
    local unidas, vistas = {}, {}
    for _, origen in ipairs({ type(lista) == "table" and lista or {}, EspejoLocal() }) do
      for _, clave in ipairs(origen) do
        local k = tostring(clave)
        if k ~= "" and not vistas[k] then
          vistas[k] = true
          unidas[#unidas + 1] = k
        end
      end
    end
    callback(unidas, err)
  end)
end

-- Deja escrito exactamente que claves componen el tablon ahora mismo, en la fase Y en el espejo.
local function EscribirManifiesto(claves)
  local espejo, tabla, fase = EspejoLocal()
  local copia = {}
  for i, k in ipairs(claves) do copia[i] = tostring(k) end
  tabla[fase] = copia
  return Escribir(CLAVE_MANIFIESTO, claves)
end

-- Publicacion definitiva: el manifiesto viejo dice TODO lo que hay escrito, se vacia lo que
-- ya no pertenece al tablon, se escribe el tablon nuevo y se deja el manifiesto al dia.
-- Usa el manifiesto y no el indice porque el manifiesto tambien recuerda bloques que en su
-- dia se quedaron colgados; el indice solo conoce los vigentes.
-- Publicar NO pisa: primero se trae lo que hay en la fase y lo compara.
--
-- Tres bandas, como una fusion de git:
--   * lo que esta en la fase Y en tu tablon  -> mandas tu (lo estas publicando)
--   * lo que esta en la fase y NO en tu tablon:
--        - si lo VISTE la ultima vez que cargaste -> lo borraste tu -> se retira
--        - si NO lo viste                          -> lo anadio otro DM -> se ADOPTA
--   * lo que solo esta en tu tablon           -> se sube
--
-- Adoptar es barato: la fila del indice ya la tienes de la lectura, y su bloque se deja
-- intacto en la fase. No hace falta descargar el contrato ajeno para conservarlo.
function Phase.PublishTracked(quiet, callback)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on para publicar en la fase.")
    if callback then callback(false, nil, "sin modo DM") end
    return
  end
  if not Phase.IsAvailable() then
    TC.Print("El almacen de fase de Epsilon no esta disponible.")
    if callback then callback(false, nil, "almacen no disponible") end
    return
  end

  local fase = Phase.GetPhaseId()

  -- Dos lecturas: el indice (para fusionar) y el manifiesto (para limpiar claves que el
  -- indice ya no nombra). Publicar es una accion puntual del DM, no una ruta caliente.
  Phase.LoadIndex(function(enFase)
   enFase = type(enFase) == "table" and enFase or {}
   Phase.LoadManifest(function(clavesViejas)

    local mios, indice, claves = {}, {}, { CLAVE_INDICE, CLAVE_MANIFIESTO }
    local fallos = 0
    for _, contract in ipairs(TC.GetDB().contracts or {}) do
      if EsPublico(contract) then
        local clave, larga = ClaveBloque(contract.id)
        if not clave then
          fallos = fallos + 1
          TC.Print("Id demasiado largo para una clave de fase: " .. tostring(larga))
        else
          mios[tostring(contract.id)] = true
          local ok, err = Escribir(clave, Proyectar(contract, CAMPOS_BLOQUE))
          if ok then
            indice[#indice + 1] = Proyectar(contract, CAMPOS_INDICE)
            claves[#claves + 1] = clave
          else
            fallos = fallos + 1
            TC.Print("No se pudo escribir " .. tostring(contract.title) .. ": " .. tostring(err))
          end
        end
      end
    end

    local visto = SelloVisto(fase) or {}
    local vistos = {}
    for _, id in ipairs(visto.ids or {}) do vistos[tostring(id)] = true end

    local adoptados, retirados = 0, 0
    for _, fila in ipairs(enFase) do
      local id = fila and tostring(fila.id or "")
      if id ~= "" and not mios[id] then
        if vistos[id] then
          -- Lo tenias y lo quitaste: se va de verdad.
          local clave = ClaveBloque(id)
          if clave then Phase.WipeKey(clave, 4) end
          retirados = retirados + 1
        else
          -- Nunca lo viste: es de otro DM. Se conserva tal cual.
          indice[#indice + 1] = fila
          local clave = ClaveBloque(id)
          if clave then claves[#claves + 1] = clave end
          adoptados = adoptados + 1
        end
      end
    end

    indice.meta = { by = (UnitName and UnitName("player")) or "?", at = (time and time()) or 0 }

    local ok, err = Escribir(CLAVE_INDICE, indice)
    if not ok then
      TC.SetSyncStatus("Fase: fallo al escribir el indice (" .. tostring(err) .. ")")
      TC.Print("No se pudo escribir el indice en la fase: " .. tostring(err))
      if callback then callback(false, nil, err) end
      return
    end
    -- Claves que el manifiesto viejo declaraba y ya no pertenecen al tablon. Aqui caen los
    -- bloques que quedaron colgados por cualquier via, no solo por borrar un contrato.
    local vigentes = {}
    for _, k in ipairs(claves) do vigentes[tostring(k)] = true end
    for _, k in ipairs(clavesViejas or {}) do
      if not vigentes[tostring(k)] then
        Phase.WipeKey(tostring(k), 4)
        retirados = retirados + 1
      end
    end

    EscribirManifiesto(claves)

    local ids = {}
    for _, fila in ipairs(indice) do
      if fila and fila.id then ids[#ids + 1] = tostring(fila.id) end
    end
    SelloVisto(fase, { at = indice.meta.at, by = indice.meta.by, ids = ids })

    -- El tablon local pasa a reflejar el resultado de la fusion: los contratos que se han
    -- adoptado de otro DM entran como esbozos y se ven al momento. Sin esto publicabas,
    -- adoptabas cosas en la fase y tu propia ventana seguia sin enterarse.
    Phase.ApplyIndex(indice)
    if TC.UI and TC.UI.Refresh then TC.UI.Refresh() end

    local resumen = string.format("Fase %s: %d contratos", tostring(fase), #indice)
    if adoptados > 0 then resumen = resumen .. ", " .. adoptados .. " de otros DM" end
    if retirados > 0 then resumen = resumen .. ", " .. retirados .. " retirados" end
    TC.SetSyncStatus(resumen)
    if not quiet then TC.Print(resumen .. (fallos > 0 and (" (" .. fallos .. " con error)") or "")) end

    if callback then callback(fallos == 0, #indice, { adoptados = adoptados, retirados = retirados }) end
   end)
  end)
end

-- El equivalente real a "borrar por prefijo": vacia todo lo que el manifiesto declare,
-- mas el indice y el propio manifiesto. Es lo mas cerca que se puede estar de un barrido.
function Phase.PurgeAll(callback)
  if not TC.IsDMMode() then
    TC.Print("Activa el modo DM con .ph dm on.")
    if callback then callback(false, nil, "sin modo DM") end
    return
  end

  Phase.LoadManifest(function(claves)
    local borradas = {}
    for _, clave in ipairs(claves) do
      if tostring(clave) ~= CLAVE_MANIFIESTO then
        Phase.WipeKey(tostring(clave), 8)
        borradas[#borradas + 1] = tostring(clave)
      end
    end
    -- El indice puede no estar en el manifiesto si viene de antes de este sistema.
    Phase.WipeKey(CLAVE_INDICE, 8)
    Phase.WipeKey(CLAVE_MANIFIESTO, 8)
    local _, tabla, fase = EspejoLocal()
    tabla[fase] = nil
    ultimaCarga, ultimaFase = 0, nil
    if callback then callback(true, borradas) end
  end)
end

function Phase.GetManifestKey()
  return CLAVE_MANIFIESTO
end
