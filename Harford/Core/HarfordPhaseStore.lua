HarfordPhaseStore = HarfordPhaseStore or {}
local API = HarfordPhaseStore

------------------------------------------------------------
-- Transporte comun del almacen de fase de Epsilon.
--
-- Comparte lo que es igual para todos los sistemas (contratos, loot, facciones): escribir con
-- pcall, leer con plazo, descartar lecturas de otra fase y vaciar segmentos. NO comparte la
-- politica -- indice, manifiesto, fusion -- porque cada sistema la necesita distinta.
--
-- Limites CONFIRMADOS en vivo (ver AGENTS.md):
--   * clave <= 100 caracteres, validado por el SERVIDOR con error Lua duro
--   * 3000 caracteres por segmento, troceado y reensamblado automaticos
--   * throttle de 45 lecturas / 1,5 s con cola propia dentro de EpsilonLib
--   * NO hay ruta de error en la lectura: si el servidor calla, el callback no se llama jamas
--   * borrar es escribir cadena vacia; sobrescribir NO limpia segmentos sobrantes
------------------------------------------------------------

-- El troceado anade "_2", "_3"... a la clave, asi que el presupuesto util es menor que 100.
API.MAX_CLAVE = 96
API.ESPERA_LECTURA = 8

local function Lib()
  return EpsilonLib and EpsilonLib.PhaseAddonData
end

function API.IsAvailable()
  return (Lib() ~= nil) and (C_Epsilon ~= nil) and (C_Epsilon.GetPhaseAddonData ~= nil)
end

function API.GetPhaseId()
  if C_Epsilon and C_Epsilon.GetPhaseId then return C_Epsilon.GetPhaseId() end
  return nil
end

-- Escribir en la fase es de OFICIAL. Los filtros que aplican SpellCreator (miembro) y TRP3
-- (oficial) son politica de cada addon, no del servidor; aqui se elige el mas restrictivo
-- de los dos que se han visto en produccion.
function API.CanWrite()
  return HarfordAuthority and HarfordAuthority.IsOfficerPlus
    and HarfordAuthority.IsOfficerPlus() == true
end

-- ¿Cabe la clave? Devuelve false y la clave completa para poder decir cual fallo.
function API.KeyFits(clave)
  clave = tostring(clave or "")
  if clave == "" or #clave > API.MAX_CLAVE then return false, clave end
  return true, clave
end

-- Escribe una tabla. El servidor VALIDA y lanza error Lua; sin pcall una escritura invalida
-- aborta la operacion entera y deja el sistema a medias.
function API.Write(clave, tabla)
  local L = Lib()
  if not L then return false, "EpsilonLib no disponible" end
  local cabe, completa = API.KeyFits(clave)
  if not cabe then
    return false, "clave demasiado larga (" .. #completa .. " de " .. API.MAX_CLAVE .. ")"
  end
  local ok, err = pcall(L.SaveTable, clave, tabla)
  if not ok then
    return false, (tostring(err):gsub("^.*%.lua:%d+: ", ""))
  end
  return true
end

-- Lee una tabla. callback(tabla, error): `tabla` nil YA significa que fallo, asi que no hay
-- un `ok` aparte. El error nunca ocupa el hueco de los datos.
function API.Read(clave, callback)
  local L = Lib()
  if not L then callback(nil, "EpsilonLib no disponible"); return end
  local cabe = API.KeyFits(clave)
  if not cabe then callback(nil, "clave demasiado larga"); return end

  local fase = API.GetPhaseId()
  local contestado = false

  L.LoadTable(clave, function(tabla)
    if contestado then return end
    contestado = true
    -- La fase pudo cambiar mientras la lectura viajaba; ese dato ya no es de aqui.
    if API.GetPhaseId() ~= fase then
      callback(nil, "cambio de fase durante la lectura")
      return
    end
    callback(type(tabla) == "table" and tabla or nil)
  end)

  -- Sin plazo, un servidor que calla deja la UI colgada sin decir nada.
  C_Timer.After(API.ESPERA_LECTURA, function()
    if contestado then return end
    contestado = true
    callback(nil, "sin respuesta del servidor")
  end)
end

-- Vacia una clave y sus posibles segmentos. Borrar es escribir cadena vacia: no hay borrado
-- real, y sobrescribir con menos datos NO limpia los sobrantes. TRP3 tiene justo este fallo
-- al desvincular un perfil de NPC: vacia solo el primero y deja la cola colgada para siempre.
function API.WipeKey(clave, segmentos)
  if not (C_Epsilon and C_Epsilon.SetPhaseAddonData) then return false end
  local cabe = API.KeyFits(clave)
  if not cabe then return false end
  local ok = pcall(C_Epsilon.SetPhaseAddonData, clave, "")
  for i = 2, (segmentos or 8) do
    pcall(C_Epsilon.SetPhaseAddonData, clave .. "_" .. i, "")
  end
  return ok
end

-- Union sin duplicados de varias listas de claves, respetando el orden de la primera.
-- La usan los manifiestos para combinar lo que declara la fase con el espejo local.
function API.MergeKeys(...)
  local out, vistas = {}, {}
  for i = 1, select("#", ...) do
    local origen = select(i, ...)
    if type(origen) == "table" then
      for _, clave in ipairs(origen) do
        local k = tostring(clave)
        if k ~= "" and not vistas[k] then
          vistas[k] = true
          out[#out + 1] = k
        end
      end
    end
  end
  return out
end

------------------------------------------------------------
-- Refresco por eventos
------------------------------------------------------------

-- El proyecto PROHIBE el sondeo (nada de NewTicker, OnUpdate permanente ni polling), asi que
-- lo unico que puede disparar una recarga es un evento. `HarfordAuthority` ya escucha
-- EPSILON_PHASE_CHANGE de EpsilonLib mas PLAYER_ENTERING_WORLD y compania; aqui se filtra
-- para llamar SOLO cuando la fase cambia de verdad, porque ese listener tambien dispara con
-- CHAT_MSG_SYSTEM y cualquier cambio de permisos.
local ultimaFaseVista = {}

function API.OnPhaseChanged(owner, callback)
  if type(owner) ~= "string" or type(callback) ~= "function" then return false end
  if not (HarfordAuthority and HarfordAuthority.RegisterChangeListener) then return false end

  return HarfordAuthority.RegisterChangeListener(owner, function(status)
    local fase = status and status.phaseId
    if fase == nil then return end
    if ultimaFaseVista[owner] == fase then return end
    ultimaFaseVista[owner] = fase
    callback(fase)
  end) == true
end

------------------------------------------------------------
-- Aviso de cambio (recarga en caliente)
------------------------------------------------------------

-- Al publicar, se avisa a los conectados para que relean YA en vez de esperar al siguiente
-- cambio de fase. Es lo que hace SpellCreator con su `_PUNLOCK`.
--
-- El mensaje NO lleva datos, solo "esto cambio, ve a releer". Por eso puede ir por GUILD sin
-- riesgo, a diferencia de los mensajes que aplican efectos: el receptor no se cree nada de lo
-- que le digan, va a la fase y lee de la fuente. Y sin GUILD, alguien que no vaya en tu grupo
-- no se enteraria nunca.
--
-- No hay prefijo nuevo: cada sistema pasa el suyo.
local MARCA = "PHASEUPD"

local function Canal()
  if IsInRaid and IsInRaid() then return "RAID" end
  if IsInGroup and IsInGroup() then return "PARTY" end
  if IsInGuild and IsInGuild() then return "GUILD" end
  return nil
end

function API.NotifyChanged(prefix, sistema)
  if type(prefix) ~= "string" or prefix == "" then return false end
  local canal = Canal()
  if not canal then return false end
  if not (HarfordSync and HarfordSync.Send) then return false end
  local mensaje = table.concat({ MARCA, tostring(API.GetPhaseId() or "?"), tostring(sistema or "?") }, "|")
  local ok = HarfordSync.Send(prefix, mensaje, canal)
  return ok == true
end

-- Devuelve true si el mensaje era un aviso PARA ESTA fase y este sistema, tras invocar
-- `alRecargar`. Devuelve false si no era para nosotros, para que el handler siga probando.
function API.HandleNotify(message, sistema, alRecargar)
  message = tostring(message or "")
  if message:sub(1, #MARCA + 1) ~= (MARCA .. "|") then return false end
  local fase, quien = message:match("^" .. MARCA .. "|([^|]*)|([^|]*)")
  if quien ~= tostring(sistema) then return false end
  -- Un aviso de OTRA fase no nos incumbe: al cambiar de fase ya se recarga por evento.
  if tostring(fase) ~= tostring(API.GetPhaseId() or "?") then return true end
  if alRecargar then alRecargar() end
  return true
end
