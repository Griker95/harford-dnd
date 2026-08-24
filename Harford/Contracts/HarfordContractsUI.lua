HarfordContracts = HarfordContracts or {}
local TC = HarfordContracts

TC.UI = TC.UI or {}

local UI = TC.UI
local selectedCategory
local selectedContractId
local hoverCategory
local listPage = 1
local listStatusFilter = "available"
local CONTRACTS_PER_PAGE = 5
local ALL_CATEGORY_KEY = "__all"
-- Las misiones terminadas salen de las categorias normales y tienen su propia seccion, para
-- que el tablon siga mostrando lo que se puede coger sin mezclarlo con lo ya cerrado.
local COMPLETED_CATEGORY_KEY = "__completed"
local helpPage = 1
local pendingRewardClaims = {}

local function RewardClaimKey(contractId, rewardIndex)
  return tostring(contractId or "") .. "#" .. tostring(rewardIndex or "")
end

local HELP_PAGES = {
  {
    title = "1. Que es el Tablon",
    lines = {
      "|cffffd100Que hace el addon|r",
      "El Tablon de Contratos es un panel de misiones de rol para organizar aventuras dentro del juego.",
      "",
      "El DM publica contratos y los jugadores pueden verlos, leer su informacion y seguir la mision que quieran jugar.",
      "",
      "Cada contrato puede mostrar:",
      "- Tipo de contrato.",
      "- Dificultad.",
      "- Recompensa en oro, texto u objetos.",
      "- Duracion estimada.",
      "- Localizacion.",
      "- Descripcion narrativa.",
      "- Objetivos.",
      "- Estado de la mision.",
      "",
      "La idea es que el tablon sirva como punto comun entre jugadores y DM antes de preparar una sesion.",
    },
  },
  {
    title = "2. Jugadores y misiones",
    lines = {
      "|cffffd100Como usarlo como jugador|r",
      "1. Abre el icono del minimapa.",
      "2. Pulsa el icono del Tablon de Contratos.",
      "3. Elige un tipo de contrato.",
      "4. Selecciona una mision de la lista.",
      "5. Lee la recompensa, dificultad, localizacion y objetivos.",
      "",
      "|cffffd100Seguir una mision|r",
      "- Pulsa Seguir mision para anadirla a tu registro (/harford misiones).",
      "- Las misiones se ordenan solas por dificultad y, dentro de cada dificultad, por orden alfabetico.",
    },
  },
  {
    title = "3. Sincronizacion",
    lines = {
      "|cffffd100Como se sincroniza el tablon|r",
      "El DM publica y sincroniza los contratos publicos cuando corresponda. Los jugadores reciben esos datos por los canales habituales del addon.",
      "",
      "|cffffd100Estados que puedes ver|r",
      "- Tablon recibido: han llegado contratos desde otro jugador/DM.",
      "- Sincronizado: el DM ha enviado el tablon actual.",
      "",
      "|cffffd100Que hace el DM|r",
      "El DM puede pulsar Sincronizar para enviar el tablon actual al grupo, banda o hermandad.",
    },
  },
  {
    title = "4. Recompensas",
    lines = {
      "|cffffd100Recompensas normales|r",
      "La linea de recompensa puede ser texto libre: oro, favores, materiales, descuentos o cualquier premio narrativo.",
      "",
      "|cffffd100Objetos de recompensa|r",
      "Algunos contratos tienen iconos de objetos. Puedes pasar el raton por encima para ver el tooltip del objeto.",
      "",
      "|cffffd100Cuando se pueden reclamar|r",
      "Los objetos estan bloqueados hasta que el DM marque la mision como Completada.",
      "",
      "Cuando la mision este completada, haz click derecho sobre el icono del objeto y usa Enviar al inventario.",
      "",
      "Si una recompensa ya fue extraida, queda marcada con OK y no deberia volver a entregarse si la cantidad se agoto.",
    },
  },
  {
    title = "5. Modo DM",
    lines = {
      "|cffffd100Como activar herramientas DM|r",
      "En el servidor, el DM activa sus herramientas con:",
      ".ph dm on",
      "",
      "Cuando el addon detecta el modo DM, aparecen botones extra como DM, Resumen, Editar y Preparar.",
      "",
      "|cffffd100Que desbloquea|r",
      "- Crear y editar contratos.",
      "- Elegir tipo, dificultad y estado.",
      "- Publicar o borrar contratos.",
      "- Duplicar contratos.",
      "- Cambiar estados: aceptada, en preparacion, en curso, completada o archivada.",
      "- Sincronizar el tablon con otros jugadores.",
      "- Crear respaldos del tablon.",
    },
  },
  {
    title = "6. Preparacion DM y TRP3",
    lines = {
      "|cffffd100Preparar una mision|r",
      "El boton Preparar abre una ventana privada para el DM. Esa informacion no esta pensada para los jugadores.",
      "",
      "Puedes guardar:",
      "- Notas secretas.",
      "- Enemigos previstos.",
      "- NPCs o enlaces TRP3.",
      "- Resultado si ganan.",
      "- Resultado si fallan.",
      "",
      "|cffffd100TRP3|r",
      "Puedes pegar enlaces importables de perfiles de companero TRP3 en el campo NPCs / TRP3.",
      "",
      "El boton Enviar links TRP3 manda esos enlaces al chat para que otros puedan abrir o importar las fichas, siempre que el enlace sea compatible con Total RP 3.",
      "",
      "El addon no modifica Total RP 3. Solo guarda y reenvia los enlaces que tu pegues en la preparacion.",
    },
  },
  {
    title = "7. Estados de mision",
    lines = {
      "|cffffd100Que significa cada estado|r",
      "- Disponible: la mision esta visible y se puede seguir.",
      "- Aceptada: el DM ha elegido esa mision como candidata.",
      "- En preparacion: el DM esta preparando enemigos, escenas, NPCs o recompensas.",
      "- En curso: la mision se esta jugando o ya ha empezado.",
      "- Completada: la mision termino y las recompensas por objeto pueden reclamarse.",
      "- Archivada: la mision queda guardada como historial y ya no aparece como contrato activo normal.",
      "",
      "|cffffd100Importante para jugadores|r",
      "Si una mision no esta Completada, los objetos de recompensa siguen bloqueados aunque puedas ver sus iconos.",
      "",
      "|cffffd100Importante para DM|r",
      "Usa el Resumen DM para cambiar estados rapido y mantener limpio el tablon.",
    },
  },
  {
    title = "8. Consejos y problemas comunes",
    lines = {
      "|cffffd100Tipos de contrato|r",
      "Primero se elige una categoria: Mercenario, Caza, Investigacion, Exploracion, Recursos, Creacion, facciones, Sociales, Magicos o Contratos Harford.",
      "",
      "Cada tipo ayuda a entender que clase de aventura vas a encontrar y que personajes pueden encajar mejor.",
      "",
      "|cffffd100No veo contratos nuevos|r",
      "- Comprueba que estas en grupo, banda o hermandad con el DM.",
      "- Pide al DM que pulse Sincronizar.",
      "",
      "|cffffd100No veo botones DM|r",
      "Activa .ph dm on. Si el modo DM no esta activo, el addon se comporta como panel de jugador.",
      "",
      "|cffffd100Un jugador acaba de entrar|r",
      "El DM puede abrir Resumen/DM y sincronizar el tablon actual.",
    },
  },
}

local function CreateLabel(parent, text, size)
  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetText(text or "")
  if size == "large" then
    label:SetFontObject(GameFontHighlightLarge)
  elseif size == "small" then
    label:SetFontObject(GameFontDisableSmall)
  end
  return label
end

local function CreateButton(parent, text, width, height)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width or 120, height or 24)
  button:SetText(text or "")
  return button
end

local function ApplyBoardBackdrop(frame)
  if not frame or not frame.SetBackdrop then
    return
  end
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 24,
    insets = { left = 7, right = 7, top = 7, bottom = 7 },
  })
  frame:SetBackdropColor(0.018, 0.016, 0.014, 0.96)
  frame:SetBackdropBorderColor(0.42, 0.35, 0.27, 1)
end

local function ApplyWoodFrame(frame)
  if not frame then
    return
  end
  frame.woodBg = frame:CreateTexture(nil, "BORDER", nil, -8)
  frame.woodBg:SetPoint("TOPLEFT", 8, -28)
  frame.woodBg:SetPoint("BOTTOMRIGHT", -8, 8)
  frame.woodBg:SetTexture(1694961)
  frame.woodBg:SetTexCoord(0, 1, 0, 1)
  frame.woodBg:SetVertexColor(1.0, 0.92, 0.72, 1)

  frame.woodWarmth = frame:CreateTexture(nil, "BORDER", nil, -7)
  frame.woodWarmth:SetPoint("TOPLEFT", frame.woodBg, "TOPLEFT", 0, 0)
  frame.woodWarmth:SetPoint("BOTTOMRIGHT", frame.woodBg, "BOTTOMRIGHT", 0, 0)
  frame.woodWarmth:SetColorTexture(0.32, 0.17, 0.065, 0.10)
  frame.woodWarmth:SetBlendMode("ADD")

  frame.woodShade = frame:CreateTexture(nil, "BORDER", nil, -5)
  frame.woodShade:SetPoint("TOPLEFT", frame.woodBg, "TOPLEFT", 0, 0)
  frame.woodShade:SetPoint("BOTTOMRIGHT", frame.woodBg, "BOTTOMRIGHT", 0, 0)
  frame.woodShade:SetColorTexture(0.0, 0.0, 0.0, 0.02)

  frame.topBanner = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  frame.topBanner:SetPoint("TOPLEFT", 22, -40)
  frame.topBanner:SetPoint("TOPRIGHT", -22, -40)
  frame.topBanner:SetHeight(48)
  frame.topBanner:SetFrameLevel(frame:GetFrameLevel())
  frame.topBanner:EnableMouse(false)

  frame.topBannerBg = frame:CreateTexture(nil, "BORDER", nil, 1)
  frame.topBannerBg:SetAllPoints(frame.topBanner)
  frame.topBannerBg:SetColorTexture(0, 0, 0, 0.88)

  frame.boardBottomShade = frame:CreateTexture(nil, "BORDER", nil, -4)
  frame.boardBottomShade:SetPoint("BOTTOMLEFT", frame.woodBg, "BOTTOMLEFT", 0, 0)
  frame.boardBottomShade:SetPoint("BOTTOMRIGHT", frame.woodBg, "BOTTOMRIGHT", 0, 0)
  frame.boardBottomShade:SetHeight(24)
  frame.boardBottomShade:SetColorTexture(0, 0, 0, 0.02)
end

local function ApplyPosterBackdrop(frame, selected)
  if not frame or not frame.SetBackdrop then
    return
  end
  frame:SetBackdrop({
    bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0.98, 0.78, 0.48, selected and 1.0 or 0.96)
  frame:SetBackdropBorderColor(0.36, 0.18, 0.055, 0.96)
end

local function ApplyParchmentBackdrop(frame)
  if not frame or not frame.SetBackdrop then
    return
  end
  frame:SetBackdrop({
    bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = false,
    edgeSize = 18,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
  })
  frame:SetBackdropColor(1.0, 0.86, 0.60, 0.98)
  frame:SetBackdropBorderColor(0.56, 0.30, 0.10, 0.98)
end

local function CreateEditBox(parent, width)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(width or 180, 22)
  box:SetAutoFocus(false)
  return box
end

-- Oculta lo pintado en el refresco anterior y VACIA la lista. Sin el vaciado, `children` crecia
-- sin limite (cada refresco añadia sus filas y ninguna salia), asi que cada refresco tenia que
-- recorrer tambien todas las filas de todos los refrescos previos: coste que se dispara en una
-- sesion larga. Los frames ocultos siguen existiendo -- WoW no permite destruirlos -- pero ya no
-- se vuelven a recorrer.
local function ClearChildren(container)
  if not container.children then
    container.children = {}
    return
  end
  for _, child in ipairs(container.children) do
    child:Hide()
  end
  wipe(container.children)
end

local function TrackChild(container, child)
  container.children = container.children or {}
  table.insert(container.children, child)
  return child
end

local function SetSelectedContract(contract)
  selectedContractId = contract and contract.id or nil
  -- Si el contrato solo esta como esbozo del indice de fase, se baja su bloque completo al
  -- abrirlo. Llega asincrono: RefreshDetails se repite solo cuando el bloque aterriza.
  if TC.Phase and TC.Phase.EnsureContract then TC.Phase.EnsureContract(contract) end
  UI.RefreshDetails()
  UI.RefreshList()
end

local CanPlayerOpenContract

local function OpenSearchMatch(query)
  query = tostring(query or "")
  if string.len(query) < 2 then
    if UI.frame and UI.frame.searchResult then
      UI.frame.searchResult:SetText("")
    end
    return
  end

  local contract = TC.Data.FindContractByName(query)
  if not CanPlayerOpenContract(contract) then
    if UI.frame and UI.frame.searchResult then
      UI.frame.searchResult:SetText("Sin coincidencias")
    end
    return
  end

  if UI.frame and UI.frame.searchResult then
    UI.frame.searchResult:SetText("Encontrada: " .. tostring(contract.title or "Contrato"))
  end
  UI.OpenContract(contract.id)
end

local function GetPageCount(total)
  local pages = math.ceil((total or 0) / CONTRACTS_PER_PAGE)
  if pages < 1 then
    pages = 1
  end
  return pages
end

local function CountAvailableContractsByCategory(categoryKey)
  local count = 0
  if categoryKey == COMPLETED_CATEGORY_KEY then
    for _, contractType in ipairs(TC.Data.ContractTypes) do
      for _, contract in ipairs(TC.Data.GetContractsByCategory(contractType.key)) do
        if contract.status == "completed" then count = count + 1 end
      end
    end
    return count
  end
  if categoryKey == ALL_CATEGORY_KEY then
    for _, contractType in ipairs(TC.Data.ContractTypes) do
      for _, contract in ipairs(TC.Data.GetContractsByCategory(contractType.key)) do
        if contract.status == "available" then
          count = count + 1
        end
      end
    end
  else
    for _, contract in ipairs(TC.Data.GetContractsByCategory(categoryKey)) do
      if contract.status == "available" then
        count = count + 1
      end
    end
  end
  return count
end

local function IsAllContractsCategory(category)
  return category == ALL_CATEGORY_KEY
end

local function IsCompletedCategory(category)
  return category == COMPLETED_CATEGORY_KEY
end

local function GetCategoryTitle(category)
  if IsCompletedCategory(category) then
    return "Misiones completadas"
  end
  if IsAllContractsCategory(category) then
    return "Todos los contratos"
  end
  local contractType = category and TC.Data.GetTypeByKey(category)
  return contractType and (contractType.title or ("Contratos de " .. contractType.label)) or "Tipos de contrato"
end

local function GetListStatusFilterLabel(value)
  if value == "all" then
    return "Todas"
  elseif value == "available" then
    return "Disponibles"
  elseif value == "active" then
    return "En curso"
  elseif value == "completed" then
    return "Completadas"
  elseif value == "archived" then
    return "Archivadas"
  end
  return TC.Data.GetStatusLabel(value)
end

local function ContractPassesListStatus(contract)
  if not contract then
    return false
  end
  if not TC.IsDMMode() then
    return contract.status ~= "draft" and contract.status ~= "archived"
  end
  if listStatusFilter == "all" then
    return true
  end
  return contract.status == listStatusFilter
end

CanPlayerOpenContract = function(contract)
  if not contract then return false end
  if TC.IsDMMode() then return true end
  return contract.status ~= "draft" and contract.status ~= "archived"
end

local function GetVisibleContractsByCategory(category)
  local visible = {}
  if IsCompletedCategory(category) then
    for _, contractType in ipairs(TC.Data.ContractTypes) do
      for _, contract in ipairs(TC.Data.GetContractsByCategory(contractType.key)) do
        if contract.status == "completed" and ContractPassesListStatus(contract) then
          table.insert(visible, contract)
        end
      end
    end
    table.sort(visible, TC.Data.CompareByDifficulty)
    return visible
  end
  -- Una completada ya tiene su seccion; mostrarla tambien aqui la duplicaria. Excepcion: el
  -- DM que filtra explicitamente por "completed" quiere verlas donde este mirando.
  local function Cabe(contract)
    if not ContractPassesListStatus(contract) then return false end
    if contract.status == "completed" and listStatusFilter ~= "completed" then return false end
    return true
  end

  if IsAllContractsCategory(category) then
    for _, contractType in ipairs(TC.Data.ContractTypes) do
      for _, contract in ipairs(TC.Data.GetContractsByCategory(contractType.key)) do
        if Cabe(contract) then
          table.insert(visible, contract)
        end
      end
    end
  else
    for _, contract in ipairs(TC.Data.GetContractsByCategory(category)) do
      if Cabe(contract) then
        table.insert(visible, contract)
      end
    end
  end
  if IsAllContractsCategory(category) then
    table.sort(visible, function(a, b)
      local aRank = TC.Data.GetDifficultyRank(a.difficulty)
      local bRank = TC.Data.GetDifficultyRank(b.difficulty)
      if aRank ~= bRank then
        return aRank < bRank
      end
      local aTitle = tostring(a.title or "")
      local bTitle = tostring(b.title or "")
      return aTitle < bTitle
    end)
  end
  return visible
end

local function SetListStatusFilter(value)
  listStatusFilter = value or "available"
  listPage = 1
  local selectedContract = selectedContractId and TC.Data.GetContractById(selectedContractId)
  if selectedContract and not ContractPassesListStatus(selectedContract) then
    selectedContractId = nil
  end
  if UI.frame and UI.frame.listStatusDropDown then
    UIDropDownMenu_SetText(UI.frame.listStatusDropDown, GetListStatusFilterLabel(listStatusFilter))
  end
  UI.Refresh()
end

local function IsRewardClaimUnlocked(contract)
  return contract and contract.status == "completed"
end

local function OpenRewardClaimPopup(contractId, rewardIndex)
  local contract = contractId and TC.Data.GetContractById(contractId)
  local item = contract and contract.rewardItems and contract.rewardItems[rewardIndex]
  if not item then
    return
  end
  local claimKey = RewardClaimKey(contractId, rewardIndex)
  if pendingRewardClaims[claimKey] then
    TC.Print("Esa recompensa ya esta pendiente de confirmacion.")
    return
  end
  if not IsRewardClaimUnlocked(contract) then
    TC.Print("La recompensa solo puede extraerse cuando la mision este Completada.")
    return
  end
  if TC.Util.GetRewardItemRemaining(item) <= 0 then
    TC.Print("Ya ha sido extraida la recompensa.")
    return
  end

  StaticPopupDialogs.TABLONCONTRATOS_CLAIM_REWARD = StaticPopupDialogs.TABLONCONTRATOS_CLAIM_REWARD or {
    text = "Enviar esta recompensa al inventario?",
    button1 = "Enviar al inventario",
    button2 = CANCEL,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function(_, data)
      local claimContract = TC.Data.GetContractById(data.contractId)
      local claimItem = claimContract and claimContract.rewardItems and claimContract.rewardItems[data.rewardIndex]
      if not IsRewardClaimUnlocked(claimContract) then
        TC.Print("La recompensa solo puede extraerse cuando la mision este Completada.")
        return
      end
      if not claimItem or TC.Util.GetRewardItemRemaining(claimItem) <= 0 then
        TC.Print("Ya ha sido extraida la recompensa.")
        return
      end
      local key = RewardClaimKey(data.contractId, data.rewardIndex)
      if pendingRewardClaims[key] then
        TC.Print("Esa recompensa ya esta pendiente de confirmacion.")
        return
      end
      local ok, claimedItemOrMessage = TC.Data.ClaimRewardItem(data.contractId, data.rewardIndex)
      if not ok then
        TC.Print(claimedItemOrMessage or "No se pudo extraer la recompensa.")
        return
      end
      pendingRewardClaims[key] = true
      UI.Refresh()
      local itemId = claimedItemOrMessage.itemId
      local sent = TC.Util.SendAddItemCommand(itemId, function(success, messages)
        pendingRewardClaims[key] = nil
        if not success then
          if TC.Data and TC.Data.UnclaimRewardItem then
            TC.Data.UnclaimRewardItem(data.contractId, data.rewardIndex)
          end
          local message = messages and messages[1] or "El servidor no confirmo la entrega."
          TC.Print("No se pudo enviar la recompensa al inventario: " .. tostring(message))
          return
        end
        if TC.Comm and TC.Comm.PublishRewardClaim then
          TC.Comm.PublishRewardClaim(data.contractId, data.rewardIndex)
        end
        -- Si quien extrae es el propio DM, su mensaje no vuelve por el canal
        -- addon. Publicamos la foto completa directamente en ese caso.
        if TC.IsDMMode and TC.IsDMMode() and TC.Comm and TC.Comm.SyncPublicContracts then
          TC.Comm.SyncPublicContracts(true)
        end
        TC.SetSyncStatus("Pendiente: recompensa extraida")
        TC.Print("Recompensa extraida por " .. tostring(TC.Data.GetPlayerKey()) .. " y enviada al inventario.")
        UI.Refresh()
      end)
      if not sent then
        pendingRewardClaims[key] = nil
        if TC.Data and TC.Data.UnclaimRewardItem then
          TC.Data.UnclaimRewardItem(data.contractId, data.rewardIndex)
        end
        TC.Print("No se pudo enviar la recompensa al inventario.")
        UI.Refresh()
      end
    end,
  }

  StaticPopup_Show("TABLONCONTRATOS_CLAIM_REWARD", nil, nil, {
    contractId = contractId,
    rewardIndex = rewardIndex,
  })
end

local function BuildFrame(parent, embedded)
  local frame
  if embedded then
    frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame._harfordEmbedded = true
    frame:SetAllPoints(parent)
    frame:SetFrameStrata(parent:GetFrameStrata() or "DIALOG")
    frame:SetFrameLevel((parent:GetFrameLevel() or 0) + 2)
  else
    frame = CreateFrame("Frame", "HarfordContractsFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(860, 560)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(20)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  end
  frame:HookScript("OnHide", function()
    if frame._harfordEmbedded and not UI.releasingEmbedded and UI.embeddedParent then
      local parent, onClose = UI.embeddedParent, UI.embeddedOnClose
      UI.embeddedParent = nil
      UI.embeddedOnClose = nil
      if parent:IsShown() and type(onClose) == "function" then
        onClose()
      end
    end
    if not frame._harfordEmbedded and UI.standaloneOnClose then
      local onClose = UI.standaloneOnClose
      UI.standaloneOnClose = nil
      onClose()
    end
  end)
  frame:Hide()
  ApplyBoardBackdrop(frame)
  ApplyWoodFrame(frame)
  if embedded then
    -- El tablon comparte la ventana del comunicador, pero conserva el cromo
    -- nativo del ButtonFrame sin convertirse en otro UIPanel independiente.
    local chrome = CreateFrame("Frame", nil, frame, "ButtonFrameTemplate")
    chrome:SetAllPoints(frame)
    chrome:SetFrameStrata(frame:GetFrameStrata() or "DIALOG")
    chrome:SetFrameLevel(frame:GetFrameLevel())
    chrome:EnableMouse(false)
    if chrome.Bg then chrome.Bg:Hide() end
    if chrome.Inset then chrome.Inset:Hide() end
    if chrome.TitleText then chrome.TitleText:Hide() end
    if ButtonFrameTemplate_HideButtonBar then
      ButtonFrameTemplate_HideButtonBar(chrome)
    end
    frame.chrome = chrome
  end
  if not embedded and ButtonFrameTemplate_HideButtonBar then
    ButtonFrameTemplate_HideButtonBar(frame)
  end
  if not embedded and frame.TitleText then
    frame.TitleText:Hide()
  end
  if embedded then
    frame.CloseButton = frame.chrome and frame.chrome.CloseButton
    if not frame.CloseButton then
      frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
      frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    end
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
  end

  frame.title = CreateLabel(frame, TC.title, "large")
  frame.title:SetPoint("TOP", 0, -5)
  frame.title:SetTextColor(1, 0.86, 0.38)
  if embedded and frame.chrome and frame.chrome.TitleText then
    frame.title:Hide()
    frame.chrome.TitleText:SetText(TC.title)
    frame.chrome.TitleText:Show()
  end

  -- El retrato integrado no puede reutilizar el global del tablon autonomo:
  -- ese Texture sigue siendo hijo del otro frame y desaparece al alternar.
  local portrait
  if embedded then
    portrait = frame.chrome and frame.chrome.portrait
    if not portrait then
      portrait = frame:CreateTexture(nil, "ARTWORK", nil, 2)
    end
  else
    portrait = frame.portrait or _G["HarfordContractsFramePortrait"]
    if not portrait then
      portrait = frame:CreateTexture("HarfordContractsFramePortrait", "ARTWORK", nil, 2)
    end
  end
  frame.portrait = portrait
  frame.portrait:SetSize(52, 52)
  frame.portrait:ClearAllPoints()
  frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
  frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  TC.Util.SetIcon(frame.portrait, TC.icon)
  if frame.CreateMaskTexture and frame.portrait.AddMaskTexture then
    frame.portraitMask = frame:CreateMaskTexture(nil, "BACKGROUND")
    frame.portraitMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    frame.portraitMask:SetAllPoints(frame.portrait)
    frame.portrait:AddMaskTexture(frame.portraitMask)
  end

  frame.dmButton = CreateButton(frame, "DM", 52, 24)
  frame.dmButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -26)
  frame.dmButton:SetScript("OnClick", function()
    TC.OpenDM()
  end)

  frame.summaryButton = CreateButton(frame, "Resumen", 86, 24)
  frame.summaryButton:SetPoint("RIGHT", frame.dmButton, "LEFT", -8, 0)
  frame.summaryButton:SetScript("OnClick", function()
    if TC.DM and TC.DM.OpenSummary then
      TC.DM.OpenSummary()
    end
  end)

  frame.syncStatusText = CreateLabel(frame, "", "small")
  frame.syncStatusText:SetPoint("TOPRIGHT", -36, -62)
  frame.syncStatusText:SetWidth(260)
  frame.syncStatusText:SetJustifyH("RIGHT")

  frame.helpButton = CreateButton(frame, "?", 28, 22)
  frame.helpButton:SetPoint("RIGHT", frame.topBanner, "RIGHT", -12, 0)
  frame.helpButton:SetScript("OnClick", function()
    UI.OpenHelp()
  end)

  frame.backButton = CreateButton(frame, "Tipos", 70, 24)
  frame.backButton:SetPoint("LEFT", frame.topBanner, "LEFT", 12, 0)
  frame.backButton:SetScript("OnClick", function()
    selectedCategory = nil
    hoverCategory = nil
    SetSelectedContract(nil)
    UI.Refresh()
  end)

  frame.categoryTitle = CreateLabel(frame, "Tipos de contrato", "large")
  frame.categoryTitle:SetPoint("LEFT", frame.backButton, "RIGHT", 14, 0)

  frame.searchLabel = CreateLabel(frame, "Buscar", "small")

  frame.searchBox = CreateEditBox(frame, 170)
  frame.searchBox:SetPoint("CENTER", frame.topBanner, "CENTER", 80, 0)
  frame.searchLabel:SetPoint("RIGHT", frame.searchBox, "LEFT", -8, 0)
  frame.searchBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
      OpenSearchMatch(self:GetText())
    end
  end)
  frame.searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)

  frame.searchResult = CreateLabel(frame, "", "small")
  frame.searchResult:SetPoint("LEFT", frame.searchBox, "RIGHT", 8, 0)
  frame.searchResult:SetWidth(190)
  frame.searchResult:SetJustifyH("LEFT")

  frame.listStatusLabel = CreateLabel(frame, "Estado", "small")
  frame.listStatusLabel:SetPoint("TOPLEFT", 18, -76)

  frame.listStatusDropDown = CreateFrame("Frame", "HarfordContractsListStatusDropDown", frame, "UIDropDownMenuTemplate")
  frame.listStatusDropDown:SetPoint("LEFT", frame.listStatusLabel, "RIGHT", -10, -2)
  UIDropDownMenu_SetWidth(frame.listStatusDropDown, 118)
  UIDropDownMenu_SetText(frame.listStatusDropDown, GetListStatusFilterLabel(listStatusFilter))
  UIDropDownMenu_Initialize(frame.listStatusDropDown, function(_, level)
    if level ~= 1 then
      return
    end
    local options = {
      { text = "Disponibles", value = "available" },
      { text = "En curso", value = "active" },
      { text = "Completadas", value = "completed" },
      { text = "Archivadas", value = "archived" },
      { text = "Todas", value = "all" },
    }
    for _, option in ipairs(options) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = option.text
      info.arg1 = option.value
      info.func = function(_, value)
        SetListStatusFilter(value)
      end
      info.checked = listStatusFilter == option.value
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  frame.categoryPanel = CreateFrame("Frame", nil, frame)
  frame.categoryPanel:SetPoint("TOPLEFT", 18, -102)
  frame.categoryPanel:SetSize(350, 406)

  frame.listPanel = CreateFrame("Frame", nil, frame)
  frame.listPanel:SetPoint("TOPLEFT", 18, -102)
  frame.listPanel:SetSize(360, 406)

  frame.prevPageButton = CreateButton(frame, "<-", 42, 24)
  frame.prevPageButton:SetPoint("BOTTOMLEFT", frame.listPanel, "BOTTOMLEFT", 2, -32)
  frame.prevPageButton:SetScript("OnClick", function()
    if listPage > 1 then
      listPage = listPage - 1
      UI.RefreshList()
    end
  end)

  frame.pageText = CreateLabel(frame, "1", nil)
  frame.pageText:SetPoint("LEFT", frame.prevPageButton, "RIGHT", 8, 0)
  frame.pageText:SetWidth(28)
  frame.pageText:SetJustifyH("CENTER")

  frame.nextPageButton = CreateButton(frame, "->", 42, 24)
  frame.nextPageButton:SetPoint("LEFT", frame.pageText, "RIGHT", 8, 0)
  frame.nextPageButton:SetScript("OnClick", function()
    local total = #GetVisibleContractsByCategory(selectedCategory)
    local pageCount = GetPageCount(total)
    if listPage < pageCount then
      listPage = listPage + 1
      UI.RefreshList()
    end
  end)

  frame.detailPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  frame.detailPanel:SetPoint("TOPLEFT", 395, -102)
  frame.detailPanel:SetSize(440, 406)
  ApplyParchmentBackdrop(frame.detailPanel)

  -- Scroll del contenido de TEXTO (si desborda). Los 3 botones de accion quedan FIJOS abajo (fuera
  -- del scroll). El contenido de texto se reparenta a `detailContent` mas abajo (batch), conservando
  -- sus anclajes relativos; solo el ancla raiz (detailIcon) pasa a `detailContent`.
  frame.detailScroll = CreateFrame("ScrollFrame", nil, frame.detailPanel)
  frame.detailScroll:SetPoint("TOPLEFT", 14, -14)
  frame.detailScroll:SetPoint("BOTTOMRIGHT", -18, 46)   -- 46px inferiores para la barra de botones
  frame.detailScroll:EnableMouseWheel(true)
  frame.detailScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxScroll = math.max(0, (frame.detailContent:GetHeight() or 0) - (self:GetHeight() or 0))
    self:SetVerticalScroll(math.max(0, math.min((self:GetVerticalScroll() or 0) - delta * 30, maxScroll)))
  end)
  frame.detailContent = CreateFrame("Frame", nil, frame.detailScroll)
  frame.detailContent:SetSize(408, 1)
  frame.detailScroll:SetScrollChild(frame.detailContent)

  frame.detailIcon = frame.detailPanel:CreateTexture(nil, "ARTWORK")
  frame.detailIcon:SetSize(54, 54)
  frame.detailIcon:SetPoint("TOPLEFT", 14, -14)

  frame.detailTitle = CreateLabel(frame.detailPanel, "Selecciona una mision", "large")
  frame.detailTitle:SetPoint("TOPLEFT", frame.detailIcon, "TOPRIGHT", 12, -2)
  frame.detailTitle:SetWidth(340)
  frame.detailTitle:SetJustifyH("LEFT")

  frame.detailMeta = CreateLabel(frame.detailPanel, "", "small")
  frame.detailMeta:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -6)
  frame.detailMeta:SetWidth(330)
  frame.detailMeta:SetJustifyH("LEFT")
  frame.detailMeta:SetTextColor(0.25, 0.20, 0.14)

  frame.detailReward = CreateLabel(frame.detailPanel, "", nil)
  frame.detailReward:SetPoint("TOPLEFT", frame.detailIcon, "BOTTOMLEFT", 0, -16)
  frame.detailReward:SetWidth(405)
  frame.detailReward:SetJustifyH("LEFT")
  frame.detailReward:SetTextColor(0.45, 0.25, 0.04)

  frame.detailRewardState = CreateLabel(frame.detailPanel, "", "small")
  frame.detailRewardState:SetPoint("TOPLEFT", frame.detailReward, "BOTTOMLEFT", 0, -4)
  frame.detailRewardState:SetWidth(405)
  frame.detailRewardState:SetJustifyH("LEFT")

  frame.detailLocation = CreateLabel(frame.detailPanel, "", nil)
  frame.detailLocation:SetPoint("TOPLEFT", frame.detailRewardState, "BOTTOMLEFT", 0, -6)
  frame.detailLocation:SetWidth(405)
  frame.detailLocation:SetJustifyH("LEFT")
  frame.detailLocation:SetTextColor(0.45, 0.25, 0.04)

  frame.detailDangers = CreateLabel(frame.detailPanel, "", nil)
  frame.detailDangers:SetPoint("TOPLEFT", frame.detailReward, "BOTTOMLEFT", 0, -42)
  frame.detailDangers:SetWidth(405)
  frame.detailDangers:SetJustifyH("LEFT")
  frame.detailDangers:SetTextColor(1.0, 0.35, 0.15)

  frame.detailSkills = CreateLabel(frame.detailPanel, "", nil)
  frame.detailSkills:SetPoint("TOPLEFT", frame.detailDangers, "BOTTOMLEFT", 0, -14)
  frame.detailSkills:SetWidth(405)
  frame.detailSkills:SetJustifyH("LEFT")
  frame.detailSkills:SetTextColor(1.0, 0.82, 0.0)

  frame.rewardItemsPanel = CreateFrame("Frame", nil, frame.detailPanel)
  frame.rewardItemsPanel:SetPoint("TOPLEFT", frame.detailLocation, "BOTTOMLEFT", 0, -8)
  frame.rewardItemsPanel:SetSize(405, 34)
  frame.rewardItemButtons = {}
  for index = 1, 6 do
    local button = CreateFrame("Button", nil, frame.rewardItemsPanel, "BackdropTemplate")
    button:SetSize(30, 30)
    button:SetPoint("LEFT", (index - 1) * 36, 0)
    button:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 3, -3)
    button.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", -1, 1)
    button.claimed = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    button.claimed:SetPoint("CENTER", 0, 0)
    button.claimed:SetText("OK")
    button.claimed:SetTextColor(0.15, 1.0, 0.15)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouseButton)
      if mouseButton == "RightButton" and self.contractId and self.rewardIndex then
        OpenRewardClaimPopup(self.contractId, self.rewardIndex)
      end
    end)
    button:SetScript("OnEnter", function(self)
      if not self.itemId then
        return
      end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetHyperlink("item:" .. tostring(self.itemId))
      GameTooltip:AddLine(" ")
      if self.claimPending then
        GameTooltip:AddLine("Entrega pendiente de confirmacion.", 1, 0.82, 0)
      elseif not self.claimUnlocked then
        GameTooltip:AddLine("Recompensa bloqueada.", 0.9, 0.35, 0.25)
        GameTooltip:AddLine("El DM debe marcar la mision como Completada.", 1, 1, 1)
      elseif self.remaining and self.remaining > 0 then
        GameTooltip:AddLine("Disponibles: " .. tostring(self.remaining), 1, 0.82, 0)
        GameTooltip:AddLine("Click derecho: enviar 1 al inventario", 1, 1, 1)
      else
        GameTooltip:AddLine("Ya ha sido extraida la recompensa.", 0.9, 0.35, 0.25)
      end
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    frame.rewardItemButtons[index] = button
  end

  -- Boton para cobrar la recompensa COMPARTIDA (reputacion y XP) de esta mision. La cobra cada
  -- miembro por separado, con su propio recibo; no es un bote unico como el dinero.
  frame.sharedClaimButton = CreateButton(frame.detailPanel, "Cobrar recompensa", 150, 26)
  frame.sharedClaimButton:Hide()
  frame.sharedClaimButton:SetScript("OnClick", function(self)
    local contract = self.contractId and TC.Data.GetContractById(self.contractId)
    if not (contract and TC.Rewards and TC.Rewards.IsSharedClaimable
      and TC.Rewards.IsSharedClaimable(contract)) then
      TC.Print("Esa recompensa no esta disponible (¿ya cobrada o mision sin completar?).")
      return
    end
    if TC.Rewards.ClaimShared(contract) then
      TC.Refresh()
    else
      TC.Print("No se pudo cobrar la recompensa.")
    end
  end)
  frame.sharedClaimButton:SetScript("OnEnter", function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Recompensa compartida", 1, 0.82, 0)
    GameTooltip:AddLine("Reputacion y experiencia. La cobra cada miembro por separado.", 1, 1, 1, true)
    if self.motivoNpc then
      GameTooltip:AddLine("Esta mision se entrega a un NPC: la reputacion y la experiencia "
        .. "se reparten al entregarla alli.", 1, 0.82, 0, true)
    end
    if self.yaCobrada then
      GameTooltip:AddLine("Ya la has cobrado con este personaje.", 0.6, 1, 0.6, true)
    end
    GameTooltip:Show()
  end)
  frame.sharedClaimButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

  -- Boton para cobrar el BOTE de dinero (bote unico, lo coge una persona). Visible solo si el
  -- contrato esta Completado, tiene dinero y no se ha cobrado. Posicion en el render.
  frame.moneyClaimButton = CreateButton(frame.detailPanel, "Cobrar dinero", 130, 22)
  frame.moneyClaimButton:Hide()
  frame.moneyClaimButton:SetScript("OnClick", function(self)
    local cid = self.contractId
    local contract = cid and TC.Data.GetContractById(cid)
    if not contract or contract.status ~= "completed"
      or type(contract.rewardMoney) ~= "table" or contract.rewardMoney.claimed then
      TC.Print("El dinero no esta disponible (¿ya cobrado o mision no completada?).")
      return
    end
    StaticPopupDialogs.TABLONCONTRATOS_CLAIM_MONEY = StaticPopupDialogs.TABLONCONTRATOS_CLAIM_MONEY or {
      text = "Cobrar el dinero de esta mision?\nLo cobra UNA sola persona.",
      button1 = "Cobrar", button2 = CANCEL, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
      OnAccept = function(_, data)
        local c = data and data.contractId and TC.Data.GetContractById(data.contractId)
        if not c or c.status ~= "completed" or type(c.rewardMoney) ~= "table" or c.rewardMoney.claimed then
          TC.Print("El dinero ya no esta disponible.")
          return
        end
        local ok, copper = TC.Data.ClaimMoney(data.contractId)
        if not ok then TC.Print(tostring(copper or "No se pudo cobrar.")); return end
        if not (HarfordDnDEconomy and HarfordDnDEconomy.Grant) then
          TC.Data.UnclaimMoney(data.contractId)
          TC.Print("La economia Harford no esta disponible.")
          return
        end
        local sent, sendErr = HarfordDnDEconomy.Grant(copper, {
          callback = function(success, messages)
            if not success then
              TC.Data.UnclaimMoney(data.contractId)
              TC.Print(tostring((messages and messages[1]) or "El servidor rechazo el pago."))
              UI.Refresh()
              return
            end
            if TC.Comm and TC.Comm.PublishMoneyClaim then TC.Comm.PublishMoneyClaim(data.contractId) end
            if TC.IsDMMode and TC.IsDMMode() and TC.Comm and TC.Comm.SyncPublicContracts then TC.Comm.SyncPublicContracts(true) end
            TC.Print("Dinero cobrado y enviado a tu bolsa.")
            UI.Refresh()
          end,
        })
        if not sent then
          TC.Data.UnclaimMoney(data.contractId)
          TC.Print(tostring(sendErr or "No se pudo enviar el pago."))
          UI.Refresh()
        end
      end,
    }
    StaticPopup_Show("TABLONCONTRATOS_CLAIM_MONEY", nil, nil, { contractId = cid })
  end)

  frame.detailDescription = frame.detailPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.detailDescription:SetPoint("TOPLEFT", frame.rewardItemsPanel, "BOTTOMLEFT", 0, -10)
  frame.detailDescription:SetWidth(405)
  frame.detailDescription:SetJustifyH("LEFT")
  frame.detailDescription:SetJustifyV("TOP")
  frame.detailDescription:SetTextColor(0.10, 0.07, 0.035)

  -- Mueve el contenido de TEXTO al hijo desplazable (sus anclajes relativos entre si se conservan).
  -- Los botones de accion NO se mueven: quedan fijos en la barra inferior del panel.
  for _, el in ipairs({
    frame.detailIcon, frame.detailTitle, frame.detailMeta, frame.detailReward, frame.detailRewardState,
    frame.detailLocation, frame.detailDangers, frame.detailSkills, frame.detailDescription,
    frame.rewardItemsPanel, frame.moneyClaimButton,
  }) do
    if el then el:SetParent(frame.detailContent) end
  end
  frame.detailIcon:ClearAllPoints()
  frame.detailIcon:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 0, 0)

  -- Seguir contrato: lo anade al quest log per-PJ (HarfordQuests) y lo abre con /harford misiones.
  frame.trackButton = CreateButton(frame.detailPanel, "Seguir mision", 140, 26)
  frame.trackButton:SetPoint("BOTTOMRIGHT", -14, 14)
  -- El de cobrar recompensa se ancla AQUI y no donde se crea: es un boton de accion de la
  -- barra inferior, y trackButton todavia no existia en ese punto.
  frame.sharedClaimButton:SetPoint("RIGHT", frame.trackButton, "LEFT", -8, 0)
  frame.trackButton:Hide()
  frame.trackButton:SetScript("OnClick", function()
    local contract = TC.Data.GetContractById(selectedContractId)
    if not contract then return end
    if not (HarfordQuests and HarfordQuests.Accept) then
      TC.Print("Sistema de misiones no disponible.")
      return
    end
    if HarfordQuests.IsAccepted(contract.id) then
      HarfordQuests.Abandon(contract.id)
      TC.Print("Dejaste de seguir: " .. tostring(contract.title))
    else
      -- Recompensa ESTRUCTURADA (rep/xp/money/items): el registro muestra la ficha nativa y la rep
      -- se concede al reclamar. La rep lleva factionId estable si el editor lo guardo.
      local rewards = {}
      -- Reputaciones (varias): lista rewardReps, fallback a la unica rewardRep.
      local repsSrc = (type(contract.rewardReps) == "table" and #contract.rewardReps > 0 and contract.rewardReps)
        or (type(contract.rewardRep) == "table" and { contract.rewardRep }) or nil
      if repsSrc then
        rewards.reps = {}
        for _, rr in ipairs(repsSrc) do
          if (rr.faction or rr.factionId) and tonumber(rr.amount) then
            rewards.reps[#rewards.reps + 1] = { faction = rr.faction, factionId = rr.factionId, amount = tonumber(rr.amount) }
          end
        end
        if #rewards.reps == 0 then rewards.reps = nil end
      end
      if tonumber(contract.rewardXP) then rewards.xp = tonumber(contract.rewardXP) end
      if type(contract.rewardMoney) == "table" then
        rewards.money = {
          gold = contract.rewardMoney.gold, silver = contract.rewardMoney.silver, copper = contract.rewardMoney.copper,
        }
      end
      if type(contract.rewardItems) == "table" then
        local items = {}
        for _, it in ipairs(contract.rewardItems) do
          if it.itemId then items[#items + 1] = { id = tonumber(it.itemId), count = tonumber(it.quantity) or 1 } end
        end
        if #items > 0 then rewards.items = items end
      end
      HarfordQuests.Accept(contract.id, {
        title = contract.title,
        description = contract.description,
        -- Objetivos ESTRUCTURADOS (texto + contador `*N` + objeto `#ID`) para que el registro muestre
        -- el progreso 0/N y el avance por inventario funcione.
        objectives = (TC.Util.ParseObjectives and TC.Util.ParseObjectives(contract.objectives)) or nil,
        rewards = rewards,
        -- Solo texto libre si NO hay recompensa estructurada (si la hay, se compone con iconos).
        reward = (next(rewards) == nil) and contract.rewardText or nil,
        category = contract.category,
        difficulty = contract.difficulty,
        icon = (TC.Data.GetTypeByKey(contract.category) or {}).icon,
      })
      TC.Print("Siguiendo: " .. tostring(contract.title) .. ". Abrelo con /harford misiones.")
    end
    UI.RefreshDetails()
  end)

  frame.dmEditButton = CreateButton(frame.detailPanel, "Editar", 86, 26)
  frame.dmEditButton:SetPoint("BOTTOMLEFT", 14, 14)
  frame.dmEditButton:SetScript("OnClick", function()
    local contract = TC.Data.GetContractById(selectedContractId)
    if contract and TC.DM and TC.DM.OpenForContract then
      TC.DM.OpenForContract(contract.id)
    end
  end)

  frame.dmPrepButton = CreateButton(frame.detailPanel, "Preparar", 96, 26)
  frame.dmPrepButton:SetPoint("LEFT", frame.dmEditButton, "RIGHT", 8, 0)
  frame.dmPrepButton:SetScript("OnClick", function()
    local contract = TC.Data.GetContractById(selectedContractId)
    if contract and TC.DM and TC.DM.OpenPrepForContract then
      TC.DM.OpenPrepForContract(contract.id)
    end
  end)

  if embedded then UI.embeddedFrame = frame else UI.standaloneFrame = frame end
  UI.frame = frame
  if not embedded then UI.Refresh() end
  return frame
end

function UI.Create()
  if UI.embeddedParent and UI.embeddedFrame then
    UI.frame = UI.embeddedFrame
    return UI.frame
  end
  if UI.standaloneFrame then
    UI.frame = UI.standaloneFrame
    return UI.frame
  end
  return BuildFrame(UIParent, false)
end

function UI.Toggle()
  UI.Create()
  if UI.frame:IsShown() then
    UI.frame:Hide()
  else
    UI.OpenStandalone()
  end
end

-- Apertura libre para futuros tablones fisicos del mundo. Esta ruta no depende
-- del Comunicador y siempre devuelve el frame a UIParent.
function UI.OpenStandalone(onClose)
  if UI.embeddedParent then
    UI.CloseEmbedded()
  end
  UI.Create()
  UI.standaloneOnClose = onClose
  UI.frame:Show()
  UI.Refresh()
  if TC.Phase and TC.Phase.EnsureBoard then TC.Phase.EnsureBoard() end
  return UI.frame
end

-- El tablón puede vivir dentro de otra herramienta Harford sin duplicar su UI ni
-- sus datos. Al cerrarse desde su propia X devuelve el control al contenedor.
function UI.OpenEmbedded(parent, onClose)
  if not parent then
    return false
  end
  local board = UI.embeddedFrame
  if not board or board:GetParent() ~= parent then
    if board then board:Hide() end
    board = BuildFrame(parent, true)
  end
  UI.frame = board
  UI.embeddedParent = parent
  UI.embeddedOnClose = onClose
  board:ClearAllPoints()
  board:SetAllPoints(parent)
  board:SetFrameStrata(parent:GetFrameStrata() or "DIALOG")
  board:SetFrameLevel((parent:GetFrameLevel() or 0) + 5)
  board:Show()
  UI.Refresh()
  if TC.Phase and TC.Phase.EnsureBoard then TC.Phase.EnsureBoard() end
  return true
end

function UI.CloseEmbedded()
  local embedded = UI.embeddedFrame
  if not embedded or not UI.embeddedParent then
    return
  end
  UI.releasingEmbedded = true
  embedded:Hide()
  UI.embeddedParent = nil
  UI.embeddedOnClose = nil
  UI.releasingEmbedded = nil
  if UI.standaloneFrame then UI.frame = UI.standaloneFrame end
end

function UI.RefreshCategories()
  local frame = UI.frame
  ClearChildren(frame.categoryPanel)

  local columns = 3
  local buttonWidth = 108
  local buttonHeight = 74
  local function CreateCategoryButton(index, contractType, options)
    options = options or {}
    local button = TrackChild(frame.categoryPanel, CreateFrame("Button", nil, frame.categoryPanel, "BackdropTemplate"))
    button:SetSize(buttonWidth, buttonHeight)
    local col = (index - 1) % columns
    local row = math.floor((index - 1) / columns)
    button:SetPoint("TOPLEFT", col * (buttonWidth + 10), -row * (buttonHeight + 8))
    ApplyPosterBackdrop(button)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(34, 34)
    button.icon:SetPoint("TOP", 0, -8)
    TC.Util.SetIcon(button.icon, contractType.icon)

    button.text = CreateLabel(button, contractType.label, nil)
    button.text:SetPoint("TOP", button.icon, "BOTTOM", 0, -8)
    button.text:SetWidth(buttonWidth - 10)
    button.text:SetJustifyH("CENTER")
    button.text:SetTextColor(0.20, 0.10, 0.02)

    button.countBadge = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.countBadge:SetSize(22, 16)
    button.countBadge:SetPoint("RIGHT", button.icon, "LEFT", -5, 0)
    button.countBadge:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = false,
      edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button.countBadge:SetBackdropColor(0.02, 0.02, 0.025, 0.85)

    button.countText = button.countBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.countText:SetPoint("CENTER", 0, 0)
    local availableCount = CountAvailableContractsByCategory(contractType.key)
    button.countText:SetText(tostring(availableCount))
    if availableCount > 0 then
      button.countBadge:SetBackdropBorderColor(0.95, 0.82, 0.2, 0.9)
      button.countText:SetTextColor(0.1, 1.0, 0.1)
    else
      button.countBadge:SetBackdropBorderColor(0.45, 0.45, 0.48, 0.65)
      button.countText:SetTextColor(0.55, 0.55, 0.58)
    end

    button:SetScript("OnClick", function()
      selectedCategory = contractType.key
      hoverCategory = nil
      listPage = 1
      SetSelectedContract(nil)
      UI.Refresh()
    end)
    button:SetScript("OnEnter", function()
      if not selectedCategory and not options.skipHoverPreview then
        hoverCategory = contractType.key
        UI.RefreshDetails()
      end
    end)
    button:SetScript("OnLeave", function()
      if hoverCategory == contractType.key then
        hoverCategory = nil
        UI.RefreshDetails()
      end
    end)
    button:Show()
  end

  for index, contractType in ipairs(TC.Data.ContractTypes) do
    CreateCategoryButton(index, contractType)
  end

  CreateCategoryButton(14, {
    key = ALL_CATEGORY_KEY,
    label = "Todos",
    icon = TC.icon,
  }, { skipHoverPreview = true })

  CreateCategoryButton(15, {
    key = COMPLETED_CATEGORY_KEY,
    label = "Completadas",
    icon = "Interface\\Icons\\Achievement_Quests_Completed_08",
  }, { skipHoverPreview = true })
end

function UI.RefreshList()
  local frame = UI.frame
  ClearChildren(frame.listPanel)

  if not selectedCategory then
    return
  end

  local contracts = GetVisibleContractsByCategory(selectedCategory)
  local pageCount = GetPageCount(#contracts)
  if listPage > pageCount then
    listPage = pageCount
  end
  if listPage < 1 then
    listPage = 1
  end

  frame.prevPageButton:SetEnabled(listPage > 1)
  frame.nextPageButton:SetEnabled(listPage < pageCount)
  frame.pageText:SetText(tostring(listPage))

  if #contracts == 0 then
    local empty = TrackChild(frame.listPanel, CreateLabel(frame.listPanel, "No hay contratos para este filtro.", nil))
    empty:SetPoint("TOPLEFT", 6, -6)
    empty:Show()
    return
  end

  local startIndex = ((listPage - 1) * CONTRACTS_PER_PAGE) + 1
  local endIndex = math.min(startIndex + CONTRACTS_PER_PAGE - 1, #contracts)
  local visualIndex = 0

  for index = startIndex, endIndex do
    local contract = contracts[index]
    visualIndex = visualIndex + 1
    local difficulty = TC.Data.GetDifficulty(contract.difficulty)
    local row = TrackChild(frame.listPanel, CreateFrame("Button", nil, frame.listPanel, "BackdropTemplate"))
    row:SetSize(355, 74)
    row:SetPoint("TOPLEFT", 0, -(visualIndex - 1) * 82)
    ApplyPosterBackdrop(row, selectedContractId == contract.id)
    local color = difficulty.color or { 1, 1, 1 }
    row:SetBackdropBorderColor(color[1], color[2], color[3], selectedContractId == contract.id and 1 or 0.45)
    row:SetBackdropColor(0.98, 0.78, 0.48, selectedContractId == contract.id and 1.0 or 0.96)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(42, 42)
    row.icon:SetPoint("LEFT", 12, 0)
    TC.Util.SetIcon(row.icon, contract.icon or difficulty.icon)

    row.title = CreateLabel(row, contract.title, nil)
    row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -2)
    row.title:SetWidth(TC.IsDMMode() and 224 or 250)
    row.title:SetJustifyH("LEFT")
    TC.Util.ApplyDifficultyColor(row.title, contract.difficulty)

    row.meta = CreateLabel(row, TC.Util.FormatContractMeta(contract), "small")
    row.meta:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -5)
    row.meta:SetWidth(TC.IsDMMode() and 224 or 250)
    row.meta:SetJustifyH("LEFT")
    row.meta:SetTextColor(0.22, 0.16, 0.10)

    row.reward = CreateLabel(row, contract.rewardText or "Sin recompensa", "small")
    row.reward:SetPoint("TOPLEFT", row.meta, "BOTTOMLEFT", 0, -4)
    row.reward:SetWidth(TC.IsDMMode() and 224 or 250)
    row.reward:SetJustifyH("LEFT")
    row.reward:SetTextColor(0.30, 0.18, 0.06)

    row:SetScript("OnClick", function()
      SetSelectedContract(contract)
    end)
    row:Show()
  end
end

function UI.RefreshDetails()
  local frame = UI.frame
  local contract = selectedContractId and TC.Data.GetContractById(selectedContractId)
  if frame.trackButton then frame.trackButton:Hide() end

  if not contract then
    -- Limpia el pool de lineas de recompensa (dinero/rep/xp): solo se ocultaba en la ruta CON
    -- contrato, asi que al pasar a un placeholder (tipo/"selecciona un tipo") se quedaban pegadas.
    for _, ln in ipairs(frame.rewardValueLines or {}) do ln.label:Hide(); ln.value:Hide() end
    for _, button in ipairs(frame.rewardItemButtons or {}) do button:Hide() end
    if frame.detailScroll then frame.detailScroll:SetVerticalScroll(0) end
    local previewCategory = hoverCategory or selectedCategory
    local contractType = previewCategory and TC.Data.GetTypeByKey(previewCategory)
    if contractType then
      TC.Util.SetIcon(frame.detailIcon, contractType.icon)
      frame.detailTitle:SetText(contractType.title or ("Contratos de " .. contractType.label))
      frame.detailTitle:SetTextColor(0.1, 1.0, 0.1)
      frame.detailMeta:SetText("")
      frame.detailReward:SetText("")
      frame.detailRewardState:SetText("")
      frame.detailLocation:SetText("")
      frame.rewardItemsPanel:Hide()
      if frame.moneyClaimButton then frame.moneyClaimButton:Hide() end
      if frame.sharedClaimButton then frame.sharedClaimButton:Hide() end
      frame.detailDescription:ClearAllPoints()
      frame.detailDescription:SetPoint("TOPLEFT", frame.detailIcon, "BOTTOMLEFT", 0, -24)
      frame.detailDangers:SetText("Peligros habituales: " .. (contractType.dangers or "Sin definir."))
      frame.detailDangers:ClearAllPoints()
      frame.detailDangers:SetPoint("TOPLEFT", frame.detailPanel, "TOPLEFT", 14, -230)
      frame.detailSkills:SetText("Habilidades recomendadas: " .. (contractType.skills or "Sin definir."))
      frame.detailSkills:ClearAllPoints()
      frame.detailSkills:SetPoint("TOPLEFT", frame.detailDangers, "BOTTOMLEFT", 0, -16)
      frame.detailDescription:SetText(contractType.description or "")
      frame.dmEditButton:Hide()
      frame.dmPrepButton:Hide()
      return
    end

    if IsAllContractsCategory(selectedCategory) then
      TC.Util.SetIcon(frame.detailIcon, TC.icon)
      frame.detailTitle:SetText("Todos los contratos")
      frame.detailTitle:SetTextColor(0.1, 1.0, 0.1)
      frame.detailMeta:SetText("Todas las categorias reunidas en una sola lista.")
      frame.detailReward:SetText("")
      frame.detailRewardState:SetText("")
      frame.detailLocation:SetText("")
      frame.rewardItemsPanel:Hide()
      if frame.moneyClaimButton then frame.moneyClaimButton:Hide() end
      if frame.sharedClaimButton then frame.sharedClaimButton:Hide() end
      frame.detailDescription:ClearAllPoints()
      frame.detailDescription:SetPoint("TOPLEFT", frame.detailIcon, "BOTTOMLEFT", 0, -24)
      frame.detailDescription:SetText("Aqui puedes revisar todos los contratos publicados sin entrar categoria por categoria. Usa el buscador o las paginas para encontrar una mision concreta.")
      frame.detailDangers:SetText("")
      frame.detailSkills:SetText("")
      frame.dmEditButton:Hide()
      frame.dmPrepButton:Hide()
      return
    end

    TC.Util.SetIcon(frame.detailIcon, TC.icon)
    frame.detailTitle:SetText("Selecciona un tipo de contrato")
    frame.detailTitle:SetTextColor(0.1, 1.0, 0.1)
    frame.detailMeta:SetText("Elige una categoria para ver sus contratos disponibles.")
    frame.detailReward:SetText("")
    frame.detailRewardState:SetText("")
    frame.detailLocation:SetText("")
    frame.rewardItemsPanel:Hide()
    frame.detailDangers:SetText("")
    frame.detailSkills:SetText("")
    if frame.moneyClaimButton then frame.moneyClaimButton:Hide() end
    if frame.sharedClaimButton then frame.sharedClaimButton:Hide() end
    frame.detailDescription:ClearAllPoints()
    frame.detailDescription:SetPoint("TOPLEFT", frame.detailIcon, "BOTTOMLEFT", 0, -24)  -- a detailIcon (NO a rewardItemsPanel: crearia ciclo con el reordenado)
    frame.detailDescription:SetText("")
    frame.dmEditButton:Hide()
    frame.dmPrepButton:Hide()
    return
  end

  local difficulty = TC.Data.GetDifficulty(contract.difficulty)
  TC.Util.SetIcon(frame.detailIcon, contract.icon or difficulty.icon)
  frame.detailTitle:SetText(contract.title or "Contrato")
  TC.Util.ApplyDifficultyColor(frame.detailTitle, contract.difficulty)
  -- Subtitulo SIN dificultad (ya la indica el color del titulo, es redundante) y con separadores en
  -- gris. `||` = pipe literal dentro del codigo de color.
  local metaSep = "|cff808080 || |r"
  frame.detailMeta:SetText(table.concat({
    contract.duration and contract.duration ~= "" and contract.duration or "-",
    TC.Data.GetStatusLabel(contract.status),
    (contract.players or "-") .. " jugadores",
  }, metaSep))
  -- Recompensa con formato del REGISTRO: cabecera + filas Recibiras/Experiencia/Reputacion (monedas
  -- grandes, rep coloreada) reusando el helper compartido HarfordQuestAPI.GetRewardValueLines. Se
  -- pinta multilinea en el mismo fontstring (mantiene el anclaje fragil del panel); los items siguen
  -- en sus botones nativos debajo.
  local rewards = {}
  local detailRepsSrc = (type(contract.rewardReps) == "table" and #contract.rewardReps > 0 and contract.rewardReps)
    or (type(contract.rewardRep) == "table" and { contract.rewardRep }) or nil
  if detailRepsSrc then
    rewards.reps = {}
    for _, rr in ipairs(detailRepsSrc) do
      if (rr.faction or rr.factionId) and tonumber(rr.amount) then
        rewards.reps[#rewards.reps + 1] = { faction = rr.faction, factionId = rr.factionId, amount = tonumber(rr.amount) }
      end
    end
  end
  if tonumber(contract.rewardXP) then rewards.xp = tonumber(contract.rewardXP) end
  if type(contract.rewardMoney) == "table" then
    rewards.money = { gold = contract.rewardMoney.gold, silver = contract.rewardMoney.silver, copper = contract.rewardMoney.copper }
  end
  -- Orden Descripcion -> Objetivos -> Recompensas: la Recompensa se ancla DEBAJO de la descripcion
  -- (que ya incluye los objetivos). Cabecera + filas etiqueta(FRIZQT negra)+valor(ARIALN blanco).
  frame.detailReward:ClearAllPoints()
  frame.detailReward:SetPoint("TOPLEFT", frame.detailDescription, "BOTTOMLEFT", 0, -16)
  frame.detailReward:SetText("Recompensa")
  frame.detailReward:SetTextColor(0, 0, 0)
  frame.rewardValueLines = frame.rewardValueLines or {}
  local function getRewLine(i)
    local ln = frame.rewardValueLines[i]
    if ln then return ln end
    ln = {}
    ln.label = frame.detailContent:CreateFontString(nil, "OVERLAY")
    ln.label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    ln.label:SetTextColor(0, 0, 0)
    ln.label:SetJustifyH("LEFT")
    ln.value = frame.detailContent:CreateFontString(nil, "OVERLAY")
    ln.value:SetFont("Fonts\\ARIALN.TTF", 16, "OUTLINE")
    ln.value:SetTextColor(1, 1, 1)
    ln.value:SetJustifyH("LEFT")
    frame.rewardValueLines[i] = ln
    return ln
  end
  for _, ln in ipairs(frame.rewardValueLines) do ln.label:Hide(); ln.value:Hide() end

  local questApi = _G.HarfordQuestAPI
  local valueLines = (questApi and questApi.GetRewardValueLines and questApi.GetRewardValueLines(rewards)) or {}
  local lastRew = frame.detailReward
  for i, data in ipairs(valueLines) do
    local ln = getRewLine(i)
    ln.label:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    ln.label:SetText(data.label)
    ln.label:ClearAllPoints()
    ln.label:SetPoint("TOPLEFT", lastRew, "BOTTOMLEFT", 0, (lastRew == frame.detailReward) and -6 or -5)
    ln.label:Show()
    ln.value:SetText(data.value)
    ln.value:ClearAllPoints()
    ln.value:SetPoint("LEFT", ln.label, "RIGHT", 4, 0)
    ln.value:Show()
    lastRew = ln.label
  end
  if #valueLines == 0 then
    -- Sin recompensa estructurada: una sola fila con el texto libre (o "Sin recompensa").
    local ln = getRewLine(1)
    local freeText = contract.rewardText
    ln.label:SetText((freeText and freeText ~= "" and freeText ~= "Sin recompensa definida") and freeText or "Sin recompensa")
    ln.label:ClearAllPoints()
    ln.label:SetPoint("TOPLEFT", frame.detailReward, "BOTTOMLEFT", 0, -6)
    ln.label:Show()
    lastRew = ln.label
  end
  -- Sin estado "bloqueadas/disponibles" (no aporta). Boton de cobrar dinero entre las filas de
  -- recompensa y los items; luego los items; la localizacion al final del panel.
  frame.detailRewardState:SetText("")
  local money = contract.rewardMoney
  local moneyCopper = (type(money) == "table") and ((money.gold or 0) * 10000 + (money.silver or 0) * 100 + (money.copper or 0)) or 0
  -- NO en contratos con NPC (mision de mundo): ahi el dinero lo entrega el turn-in del NPC (evita
  -- doble cobro). Solo botón de tablón para contratos normales.
  local showMoneyBtn = (moneyCopper > 0) and (contract.status == "completed")
    and not (money and money.claimed) and not contract.worldNpc
  frame.moneyClaimButton.contractId = contract.id
  frame.moneyClaimButton:SetShown(showMoneyBtn)
  local afterReward = lastRew

  -- Recompensa compartida (rep/XP). El boton NO se recoloca: vive fijo en la barra inferior.
  -- Se muestra en cuanto la mision esta completada y reparte algo compartido, y se DESACTIVA
  -- cuando ya no hay nada que cobrar; ocultarlo dejaba al jugador sin saber si habia cobrado.
  local shared = TC.Rewards and TC.Rewards.HasShared and TC.Rewards.HasShared(contract)
  local showSharedBtn = shared and (contract.status == "completed")
  frame.sharedClaimButton.contractId = contract.id
  frame.sharedClaimButton:SetShown(showSharedBtn and true or false)
  if showSharedBtn then
    if contract.worldNpc then
      -- Mision de mundo: su rep/XP la reparte el turn-in del NPC, con la clave del id pelado.
      -- Cobrarla aqui la daria DOS veces, asi que el boton solo informa.
      -- Misma consulta que el resto: `IsSharedClaimed` ya usa el id pelado (la clave del NPC)
      -- y ademas mira la heredada. Preguntar aparte aqui era duplicar la regla.
      local yaNpc = TC.Rewards.IsSharedClaimed and TC.Rewards.IsSharedClaimed(contract)
      frame.sharedClaimButton.yaCobrada = yaNpc and true or false
      frame.sharedClaimButton.motivoNpc = true
      frame.sharedClaimButton:SetText(yaNpc and "Recompensa cobrada" or "Se cobra en el NPC")
      frame.sharedClaimButton:SetEnabled(false)
    else
      local cobrada = TC.Rewards.IsSharedClaimed and TC.Rewards.IsSharedClaimed(contract)
      frame.sharedClaimButton.yaCobrada = cobrada
      frame.sharedClaimButton.motivoNpc = false
      frame.sharedClaimButton:SetText(cobrada and "Recompensa cobrada" or "Cobrar recompensa")
      frame.sharedClaimButton:SetEnabled(not cobrada)
    end
  end

  if showMoneyBtn then
    frame.moneyClaimButton:ClearAllPoints()
    frame.moneyClaimButton:SetPoint("TOPLEFT", lastRew, "BOTTOMLEFT", 0, -6)
    afterReward = frame.moneyClaimButton
  end
  frame.rewardItemsPanel:ClearAllPoints()
  frame.rewardItemsPanel:SetPoint("TOPLEFT", afterReward, "BOTTOMLEFT", 0, -8)
  frame.detailDangers:SetText("")
  frame.detailSkills:SetText("")
  frame.detailDangers:ClearAllPoints()
  frame.detailDangers:SetPoint("TOPLEFT", frame.detailReward, "BOTTOMLEFT", 0, -42)
  frame.detailSkills:ClearAllPoints()
  frame.detailSkills:SetPoint("TOPLEFT", frame.detailDangers, "BOTTOMLEFT", 0, -14)
  -- Localizacion PRIMERO: primera linea del cuerpo, en NEGRO, justo tras el subtitulo.
  frame.detailLocation:ClearAllPoints()
  frame.detailLocation:SetPoint("TOPLEFT", frame.detailIcon, "BOTTOMLEFT", 0, -16)
  frame.detailLocation:SetTextColor(0, 0, 0)
  if contract.location and contract.location ~= "" then
    frame.detailLocation:SetText("Localizacion: " .. contract.location)
  else
    frame.detailLocation:SetText("Localizacion: Sin definir")
  end
  -- Descripcion + objetivos debajo de Localizacion; la Recompensa se ancla debajo de la descripcion.
  frame.detailDescription:ClearAllPoints()
  frame.detailDescription:SetPoint("TOPLEFT", frame.detailLocation, "BOTTOMLEFT", 0, -10)
  local hasRewardItems = type(contract.rewardItems) == "table" and #contract.rewardItems > 0
  local rewardClaimUnlocked = IsRewardClaimUnlocked(contract)
  -- Sin texto de estado "bloqueadas/disponibles" (no aporta); el bloqueo se ve en los botones.
  frame.detailRewardState:SetText("")
  frame.rewardItemsPanel:SetShown(hasRewardItems)
  for index, button in ipairs(frame.rewardItemButtons) do
    local item = type(contract.rewardItems) == "table" and contract.rewardItems[index]
    if item then
      local remaining = TC.Util.GetRewardItemRemaining(item)
      button.itemId = item.itemId
      button.contractId = contract.id
      button.rewardIndex = index
      button.remaining = remaining
      button.claimUnlocked = rewardClaimUnlocked
      button.claimPending = pendingRewardClaims[RewardClaimKey(contract.id, index)] == true
      button.icon:SetTexture(TC.Util.GetItemIcon(item.itemId))
      button.icon:SetDesaturated((remaining <= 0) or not rewardClaimUnlocked or button.claimPending)
      button.count:SetText(remaining > 1 and tostring(remaining) or "")
      button.claimed:SetText(button.claimPending and "..." or "OK")
      button.claimed:SetShown((remaining <= 0) or button.claimPending)
      button:Show()
    else
      button.itemId = nil
      button.contractId = nil
      button.rewardIndex = nil
      button.remaining = nil
      button.claimUnlocked = nil
      button.claimPending = nil
      button.claimed:Hide()
      button:Hide()
    end
  end
  frame.detailDescription:SetText((contract.description or "") .. "\n\nObjetivos:\n" .. TC.Util.JoinObjectives(contract.objectives))
  if HarfordQuests and HarfordQuests.Accept then
    frame.trackButton:Show()
    frame.trackButton:SetText(HarfordQuests.IsAccepted(contract.id) and "Dejar de seguir" or "Seguir mision")
  end
  frame.dmEditButton:SetShown(TC.IsDMMode())
  frame.dmPrepButton:SetShown(TC.IsDMMode())

  -- Altura del contenido desplazable = hasta el elemento mas bajo colocado (para que el scroll
  -- cubra todo y no corte la Recompensa). Se calcula tras el layout con GetBottom (frame visible).
  if frame.detailContent and frame.detailScroll then
    local top = frame.detailContent:GetTop()
    if top then
      local lowest = top
      local candidates = {
        frame.detailDescription, frame.detailReward, frame.rewardItemsPanel,
        frame.moneyClaimButton, frame.detailLocation,
      }
      for _, ln in ipairs(frame.rewardValueLines or {}) do
        candidates[#candidates + 1] = ln.label; candidates[#candidates + 1] = ln.value
      end
      for _, el in ipairs(candidates) do
        if el and el:IsShown() and el:GetBottom() then lowest = math.min(lowest, el:GetBottom()) end
      end
      frame.detailContent:SetHeight(math.max((top - lowest) + 16, frame.detailScroll:GetHeight() or 1))
    end
    frame.detailScroll:SetVerticalScroll(0)
  end
end

function UI.RefreshSyncStatus()
  if UI.frame and UI.frame.syncStatusText then
    UI.frame.syncStatusText:SetText(TC.GetSyncStatus())
  end
end

function UI.RefreshHelpPage()
  if not UI.helpFrame then
    return
  end

  local total = #HELP_PAGES
  if helpPage < 1 then
    helpPage = total
  elseif helpPage > total then
    helpPage = 1
  end

  local page = HELP_PAGES[helpPage]
  UI.helpFrame.pageTitle:SetText(page.title or "")
  UI.helpFrame.text:SetText(table.concat(page.lines or {}, "\n"))
  UI.helpFrame.pageText:SetText(tostring(helpPage) .. " / " .. tostring(total))
end

function UI.CreateHelp()
  if UI.helpFrame then
    return
  end

  local frame = CreateFrame("Frame", "HarfordContractsPublicHelpFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(640, 520)
  frame:SetPoint("CENTER", 70, -20)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(260)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  local blocker = frame:CreateTexture(nil, "BACKGROUND")
  blocker:SetAllPoints(frame)
  blocker:SetColorTexture(0.02, 0.02, 0.025, 0.98)

  frame.title = CreateLabel(frame, "Ayuda - Tablon de Contratos", "large")
  frame.title:SetPoint("TOPLEFT", 16, -5)

  frame.pageTitle = CreateLabel(frame, "", "large")
  frame.pageTitle:SetPoint("TOPLEFT", 24, -46)
  frame.pageTitle:SetTextColor(0.2, 1, 0.2)

  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.text:SetPoint("TOPLEFT", 24, -82)
  frame.text:SetWidth(590)
  frame.text:SetJustifyH("LEFT")
  frame.text:SetJustifyV("TOP")

  frame.prevButton = CreateButton(frame, "<-", 46, 24)
  frame.prevButton:SetPoint("BOTTOM", frame, "BOTTOM", -60, 18)
  frame.prevButton:SetScript("OnClick", function()
    helpPage = helpPage - 1
    UI.RefreshHelpPage()
  end)

  frame.pageText = CreateLabel(frame, "1 / 1", nil)
  frame.pageText:SetPoint("LEFT", frame.prevButton, "RIGHT", 18, 0)
  frame.pageText:SetWidth(70)
  frame.pageText:SetJustifyH("CENTER")

  frame.nextButton = CreateButton(frame, "->", 46, 24)
  frame.nextButton:SetPoint("LEFT", frame.pageText, "RIGHT", 18, 0)
  frame.nextButton:SetScript("OnClick", function()
    helpPage = helpPage + 1
    UI.RefreshHelpPage()
  end)

  UI.helpFrame = frame
  UI.RefreshHelpPage()
end

function UI.OpenHelp()
  UI.CreateHelp()
  UI.RefreshHelpPage()
  UI.helpFrame:Show()
  UI.helpFrame:Raise()
end

function UI.Refresh()
  UI.Create()
  local frame = UI.frame
  local contractType = selectedCategory and TC.Data.GetTypeByKey(selectedCategory)

  frame.dmButton:SetShown(TC.IsDMMode())
  frame.summaryButton:SetShown(TC.IsDMMode())
  frame.listStatusLabel:SetShown(TC.IsDMMode() and selectedCategory ~= nil)
  frame.listStatusDropDown:SetShown(TC.IsDMMode() and selectedCategory ~= nil)
  frame.categoryPanel:SetShown(selectedCategory == nil)
  frame.listPanel:SetShown(selectedCategory ~= nil)
  frame.prevPageButton:SetShown(selectedCategory ~= nil)
  frame.pageText:SetShown(selectedCategory ~= nil)
  frame.nextPageButton:SetShown(selectedCategory ~= nil)
  frame.backButton:SetShown(selectedCategory ~= nil)
  frame.categoryTitle:SetText(GetCategoryTitle(selectedCategory))
  UI.RefreshSyncStatus()

  if selectedCategory then
    UI.RefreshList()
  else
    UI.RefreshCategories()
  end
  UI.RefreshDetails()
end

function UI.GetSelectedCategory()
  return selectedCategory
end

function UI.SelectContract(contractId)
  selectedContractId = contractId
  UI.Refresh()
end

function UI.OpenContract(contractId)
  local contract = contractId and TC.Data.GetContractById(contractId)
  if not contract then
    return
  end
  if not CanPlayerOpenContract(contract) then
    return
  end

  selectedCategory = contract.category
  selectedContractId = contract.id
  listPage = 1
  if TC.IsDMMode() and not ContractPassesListStatus(contract) then
    listStatusFilter = "all"
    if UI.frame and UI.frame.listStatusDropDown then
      UIDropDownMenu_SetText(UI.frame.listStatusDropDown, GetListStatusFilterLabel(listStatusFilter))
    end
  end

  local contracts = GetVisibleContractsByCategory(selectedCategory)
  for index, listedContract in ipairs(contracts) do
    if listedContract.id == contract.id then
      listPage = math.ceil(index / CONTRACTS_PER_PAGE)
      break
    end
  end

  UI.Create()
  UI.frame:Show()
  UI.Refresh()
end
