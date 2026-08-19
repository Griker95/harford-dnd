HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.Data = TC.Data or {}

TC.Data.ContractTypes = {
  {
    key = "mercenary",
    label = "Mercenario",
    icon = "garrison_building_sparringarena",
    description = "Los contratos de mercenario abarcan encargos realizados por civiles, comerciantes o autoridades que requieren el uso de la fuerza o la proteccion de personas y bienes. Suelen implicar enfrentamientos contra bandidos, criminales, mercenarios u otras amenazas organizadas.",
    dangers = "Combate contra grupos armados, emboscadas, escoltas y defensa de objetivos.",
    skills = "Combate, Proteccion y Supervivencia.",
  },
  {
    key = "hunt",
    label = "Caza",
    icon = "Ability_hunter_assassinate",
    description = "Los contratos de caza estan destinados a eliminar o capturar bestias y criaturas peligrosas que amenazan la seguridad de una region. Muchas de estas misiones requieren rastrear a la presa antes de enfrentarse a ella.",
    dangers = "Criaturas salvajes, monstruos, terrenos hostiles y depredadores de gran poder.",
    skills = "Rastreo, Supervivencia y Combate.",
  },
  {
    key = "investigation",
    label = "Investigacion",
    icon = "inv_misc_spyglass_03",
    description = "Los contratos de investigacion consisten en resolver misterios mediante la busqueda de pistas, el analisis de pruebas y la recopilacion de informacion. La fuerza bruta rara vez es suficiente; la observacion y la deduccion son fundamentales.",
    dangers = "Conspiraciones, trampas, magia oculta, asesinos y amenazas desconocidas.",
    skills = "Investigacion, Percepcion e Inteligencia.",
  },
  {
    key = "exploration",
    label = "Exploracion",
    icon = "ability_hunter_huntervswild",
    description = "Los contratos de exploracion llevan a los aventureros hacia regiones desconocidas o poco cartografiadas en busca de informacion, reliquias o rutas seguras. La supervivencia y la capacidad de adaptacion son esenciales.",
    dangers = "Terrenos inexplorados, ruinas antiguas, fenomenos naturales y criaturas desconocidas.",
    skills = "Supervivencia, Atletismo y Orientacion.",
  },
  {
    key = "resources",
    label = "Recursos",
    icon = "inv_faction_warresources",
    description = "Los contratos de recursos tienen como objetivo localizar, extraer, recolectar y transportar materias primas para artesanos, comerciantes u organizaciones. Aunque parecen sencillos, la competencia y los peligros del entorno suelen complicar el trabajo.",
    dangers = "Fauna agresiva, accidentes naturales, zonas peligrosas y disputas por los recursos.",
    skills = "Mineria, Recoleccion y Artesania.",
  },
  {
    key = "crafting",
    label = "Creacion",
    icon = "Achievement_guildperk_workingovertime",
    description = "Los contratos de creacion se centran en la fabricacion, reparacion, investigacion y evaluacion de objetos. Algunos encargos requieren trabajar con artefactos antiguos o eliminar maldiciones que afectan a determinados objetos.",
    dangers = "Objetos inestables, artefactos malditos, experimentos fallidos y energias magicas impredecibles.",
    skills = "Herreria, Ingenieria, Alquimia y Encantamiento.",
  },
  {
    key = "alliance",
    label = "Alianza",
    icon = "ui_alliance_7legionmedal",
    description = "Los contratos de la Alianza son encargos emitidos por sus reinos, ejercitos y organizaciones oficiales. Incluyen misiones solicitadas por el |cff3399ffIV:7|r, la inteligencia de la Alianza, asi como operaciones para proteger sus territorios, apoyar campanas militares, investigar amenazas o asistir a sus ciudadanos.",
    dangers = "Operaciones militares, espionaje, infiltraciones enemigas, conflictos territoriales y amenazas contra los intereses de la Alianza.",
    skills = "Combate, Investigacion, Diplomacia y Trabajo en equipo.",
  },
  {
    key = "horde",
    label = "Horda",
    icon = "ui_horde_honorboundmedal",
    description = "Los contratos de la Horda son encargos procedentes de sus clanes, tribus y gobiernos. Tambien incluyen operaciones solicitadas por los |cffff3333Forestales Oscuros|r, la unidad de investigacion y espionaje de la Horda, ademas de misiones para proteger sus territorios, descubrir amenazas o garantizar la seguridad de sus aliados.",
    dangers = "Guerras de faccion, operaciones encubiertas, criaturas peligrosas, conflictos tribales y amenazas contra la Horda.",
    skills = "Combate, Supervivencia, Sigilo e Investigacion.",
  },
  {
    key = "neutral",
    label = "Neutrales",
    icon = "eps_lol_spell_bannerofcommand",
    description = "Los contratos neutrales son encargos ofrecidos por organizaciones independientes que colaboran con aventureros de cualquier faccion. Entre ellas se encuentran los |cff9d9d9dCarteles Goblin|r, el |cff9d9d9dKirin Tor|r, la |cff9d9d9dCruzada Argenta|r, el |cff9d9d9dAcuerdo del Reposo del Dragon|r, el |cff9d9d9dCirculo de la Tierra|r y otras organizaciones neutrales repartidas por Azeroth.",
    dangers = "Misiones muy variadas, amenazas de alcance mundial, expediciones, conflictos entre facciones y peligros imprevisibles.",
    skills = "Adaptabilidad, Cooperacion, Resolucion de problemas y Versatilidad.",
  },
  {
    key = "social",
    label = "Sociales",
    icon = "achievement_worldevent_childrensweek",
    description = "Los contratos sociales se centran en la vida cotidiana y la convivencia de las comunidades de Azeroth. Pueden consistir en ayudar a sus habitantes, resolver conflictos locales, colaborar con comerciantes, organizar celebraciones o participar en eventos publicos y festividades estacionales.",
    dangers = "Conflictos sociales, intrigas, robos durante eventos, altercados, problemas de organizacion, sabotajes y situaciones inesperadas que afecten a la comunidad.",
    skills = "Carisma, Persuasion, Interpretacion, Organizacion y Resolucion de conflictos.",
  },
  {
    key = "magic",
    label = "Magicos",
    title = "Contratos Magicos",
    icon = "hd_ldabookmagic",
    description = "Los contratos magicos abarcan encargos relacionados con las fuerzas sobrenaturales de Azeroth. Pueden proceder de estudiosos de la magia que requieran ayuda para investigar artefactos, contener energias descontroladas, detener criaturas magicas, cerrar portales, romper maldiciones o enfrentarse a invocaciones fuera de control.",
    dangers = "Magia inestable, maldiciones, invocaciones desatadas, criaturas sobrenaturales, artefactos ancestrales, rituales peligrosos y fenomenos arcanos impredecibles.",
    skills = "Conocimiento Arcano, Alquimia, Encantamiento, Investigacion y Control de la magia.",
  },
  {
    key = "legendary",
    label = "Harford",
    title = "Contratos Harford",
    icon = "Inv_tabard_duelersguild",
    description = "Los contratos Harford son misiones personales de los miembros de la Compañia Harford o encargos que afectan a la compañia en general. Pueden abordar deudas, alianzas, recursos, amenazas, asuntos internos o consecuencias de aventuras anteriores.",
    dangers = "Rivales de la compañia, deudas pendientes, conflictos internos, enemigos recurrentes y consecuencias de decisiones pasadas.",
    skills = "Trabajo en equipo, Lealtad, Investigacion, Combate y Diplomacia.",
  },
}

TC.Data.Difficulties = {
  gray = {
    label = "Muy facil",
    icon = "Interface\\Icons\\achievement_quests_completed_01",
    color = { 0.55, 0.55, 0.55 },
    description = "Muy por debajo del nivel del grupo. No suele conceder experiencia, aunque puede dar reputacion o conducir a contratos mas exigentes.",
  },
  green = {
    label = "Facil",
    icon = "Interface\\Icons\\achievement_quests_completed_03",
    color = { 0.1, 1.0, 0.1 },
    description = "Adecuada para el nivel actual. Conviene resolverla antes de subir de nivel.",
  },
  yellow = {
    label = "Media",
    icon = "Interface\\Icons\\achievement_quests_completed_04",
    color = { 1.0, 1.0, 0.0 },
    description = "El objetivo de aventura optimo: ofrece buen progreso sin exigir preparacion extraordinaria.",
  },
  orange = {
    label = "Dificil",
    icon = "Interface\\Icons\\achievement_quests_completed_06",
    color = { 1.0, 0.45, 0.0 },
    description = "Muy por encima del nivel del grupo. Requiere cautela y puede necesitar ayuda de otros jugadores.",
  },
  red = {
    label = "Muy dificil",
    icon = "Interface\\Icons\\achievement_quests_completed_08",
    color = { 1.0, 0.1, 0.1 },
    description = "Extremadamente dificil para el nivel del grupo; casi imposible en solitario sin una preparacion importante.",
  },
}

TC.Data.DifficultyOrder = { "gray", "green", "yellow", "orange", "red" }

-- Los contratos creados antes de la escala de colores se mantienen legibles.
-- La conversión solo normaliza el significado de la dificultad; no borra ni
-- recrea contratos guardados.
local LegacyDifficultyKeys = {
  easy = "green",
  normal = "yellow",
  hard = "orange",
  veryHard = "red",
  boss = "red",
}

function TC.Data.NormalizeDifficultyKey(key)
  key = tostring(key or "")
  if TC.Data.Difficulties[key] then
    return key
  end
  return LegacyDifficultyKeys[key] or "yellow"
end

local DifficultyRanks = {}
local contractSerial = 0
for index, difficultyKey in ipairs(TC.Data.DifficultyOrder) do
  DifficultyRanks[difficultyKey] = index
end

function TC.Data.NewContractId()
  repeat
    contractSerial = contractSerial + 1
    local id = "contract-" .. tostring(time()) .. "-" .. tostring(contractSerial)
    if not TC.Data.GetContractById(id) then
      return id
    end
  until false
end

local function CanEditContracts()
  return TC.IsDMMode and TC.IsDMMode() == true
end

TC.Data.Statuses = {
  draft = "Borrador",
  available = "Disponible",
  accepted = "Aceptada",
  preparing = "En preparacion",
  active = "En curso",
  completed = "Completada",
  archived = "Archivada",
}

TC.Data.StatusOrder = { "draft", "available", "accepted", "preparing", "active", "completed", "archived" }


function TC.Data.GetTypeByKey(key)
  for _, contractType in ipairs(TC.Data.ContractTypes) do
    if contractType.key == key then
      return contractType
    end
  end
end

function TC.Data.GetDifficulty(key)
  return TC.Data.Difficulties[TC.Data.NormalizeDifficultyKey(key)]
end

function TC.Data.GetDifficultyRank(key)
  return DifficultyRanks[TC.Data.NormalizeDifficultyKey(key)] or DifficultyRanks.yellow or 3
end

function TC.Data.GetStatusLabel(key)
  return TC.Data.Statuses[key or "available"] or key or "Disponible"
end


-- Orden canonico y UNICO de las misiones: dificultad de menor a mayor y, dentro de cada
-- dificultad, alfabetico por titulo (sin acentos, insensible a mayusculas). No hay reordenacion
-- manual: el orden se deriva siempre de estos dos criterios.
function TC.Data.CompareByDifficulty(a, b)
  local aRank = TC.Data.GetDifficultyRank(a and a.difficulty)
  local bRank = TC.Data.GetDifficultyRank(b and b.difficulty)
  if aRank ~= bRank then
    return aRank < bRank
  end
  local function key(t)
    local title = tostring(t and t.title or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
      title = HarfordClassColors.StripAccents(title)
    end
    return title:lower()
  end
  return key(a) < key(b)
end

function TC.Data.GetContractsByCategory(category)
  local db = TC.GetDB()
  local result = {}
  for _, contract in ipairs(db.contracts) do
    if not category or contract.category == category then
      table.insert(result, contract)
    end
  end
  table.sort(result, TC.Data.CompareByDifficulty)
  return result
end

function TC.Data.GetContractById(id)
  local db = TC.GetDB()
  for _, contract in ipairs(db.contracts) do
    if contract.id == id then
      return contract
    end
  end
end

function TC.Data.FindContractByName(query)
  query = tostring(query or ""):lower()
  if query == "" then
    return nil
  end

  local db = TC.GetDB()
  for _, contract in ipairs(db.contracts) do
    local title = tostring(contract.title or ""):lower()
    if string.find(title, query, 1, true) then
      return contract
    end
  end
end

function TC.Data.AddDraft(category)
  if not CanEditContracts() then
    return nil
  end

  local db = TC.GetDB()
  local id = TC.Data.NewContractId()
  local contract = {
    id = id,
    title = "Nuevo contrato",
    category = category or "mercenary",
    difficulty = "yellow",
    rewardText = "Sin recompensa definida",
    duration = "1 sesion",
    players = "3-5",
    location = "",
    status = "draft",
    description = "",
    objectives = {},
    privateNotes = "",
    prep = {
      secretNotes = "",
      enemies = "",
      npcs = "",
      success = "",
      failure = "",
    },
    rewardItems = {},
    rewardMoney = { gold = 0, silver = 0, copper = 0 },  -- dinero estructurado (oro/plata/cobre)
  }
  table.insert(db.contracts, contract)
  return contract
end

function TC.Data.DeleteContract(contractId)
  if not CanEditContracts() then
    return false
  end

  if not contractId then
    return false
  end

  local db = TC.GetDB()
  local removed = false
  for index = #db.contracts, 1, -1 do
    if db.contracts[index].id == contractId then
      table.remove(db.contracts, index)
      removed = true
      break
    end
  end

  return removed
end

function TC.Data.ClearPublishedContracts()
  local db = TC.GetDB()
  local removedIds = {}
  local removed = 0
  for index = #db.contracts, 1, -1 do
    local contract = db.contracts[index]
    local status = contract and contract.status or "available"
    if status ~= "draft" and status ~= "archived" then
      removedIds[tostring(contract.id or "")] = true
      table.remove(db.contracts, index)
      removed = removed + 1
    end
  end
  if removed > 0 then
    TC.Refresh()
  end
  return removed
end

-- Vacia COMPLETAMENTE el tablon (todos los contratos, incluidos borradores y archivados). Para
-- resetear cuando la SavedVariable arrastra contratos de ejemplo/antiguos. Devuelve cuantos borro.
function TC.Data.ClearAllContracts()
  local db = TC.GetDB()
  local n = #db.contracts
  db.contracts = {}
  TC.Refresh()
  return n
end

-- Reemplaza exclusivamente la copia PUBLICA recibida de un DM. Los borradores
-- locales se conservan porque nunca forman parte de una publicacion remota.
function TC.Data.ReplacePublishedContracts(publicContracts)
  if type(publicContracts) ~= "table" then
    return false
  end

  local db = TC.GetDB()
  local preservedDrafts = {}
  for _, contract in ipairs(db.contracts or {}) do
    if type(contract) == "table" and contract.status == "draft" then
      table.insert(preservedDrafts, contract)
    end
  end

  local nextContracts = preservedDrafts
  for _, contract in ipairs(publicContracts) do
    if type(contract) == "table" and tostring(contract.id or "") ~= "" then
      contract.__hasSharedRewardFields = nil
      contract.privateNotes = ""
      contract.prep = nil
      table.insert(nextContracts, contract)
    end
  end

  db.contracts = nextContracts
  TC.Refresh()
  return true
end

function TC.Data.GetPlayerKey()
  local name, realm = UnitFullName("player")
  if name and realm and realm ~= "" then
    return name .. "-" .. realm
  end
  return UnitName("player") or "Jugador"
end

function TC.Data.ClaimRewardItem(contractId, rewardIndex)
  local contract = TC.Data.GetContractById(contractId)
  if not contract or type(contract.rewardItems) ~= "table" then
    return false, "No se encontro la recompensa."
  end

  local item = contract.rewardItems[tonumber(rewardIndex)]
  if not item then
    return false, "No se encontro la recompensa."
  end

  if TC.Util.GetRewardItemRemaining(item) <= 0 then
    return false, "Ya ha sido extraida la recompensa."
  end

  item.claimed = (tonumber(item.claimed) or 0) + 1
  TC.Refresh()
  return true, item
end

-- Dinero de recompensa: BOTE UNICO (lo cobra una sola persona, como un item). `claimed` marca que
-- ya se llevo. Devuelve el total en cobre para el comando de entrega.
function TC.Data.ClaimMoney(contractId)
  local contract = TC.Data.GetContractById(contractId)
  if not contract or type(contract.rewardMoney) ~= "table" then return false, "Este contrato no tiene dinero." end
  local m = contract.rewardMoney
  local copper = (m.gold or 0) * 10000 + (m.silver or 0) * 100 + (m.copper or 0)
  if copper <= 0 then return false, "Este contrato no tiene dinero." end
  if m.claimed then return false, "El dinero ya fue cobrado." end
  m.claimed = true
  TC.Refresh()
  return true, copper
end

function TC.Data.UnclaimMoney(contractId)
  local contract = TC.Data.GetContractById(contractId)
  if contract and type(contract.rewardMoney) == "table" then
    contract.rewardMoney.claimed = nil
    TC.Refresh()
  end
end

function TC.Data.UnclaimRewardItem(contractId, rewardIndex)
  local contract = TC.Data.GetContractById(contractId)
  if not contract or type(contract.rewardItems) ~= "table" then
    return false
  end

  local item = contract.rewardItems[tonumber(rewardIndex)]
  if not item then
    return false
  end

  item.claimed = math.max(0, (tonumber(item.claimed) or 0) - 1)
  TC.Refresh()
  return true
end

