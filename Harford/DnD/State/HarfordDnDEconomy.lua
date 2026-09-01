-- HarfordDnDEconomy: saldo de oro por personaje para la economia D&D.
-- No inicializa ni modifica el dinero nativo hasta que CharacterCreation termina
-- una ficha valida. Despues conserva el saldo local y corrige el exceso inicial de
-- Epsilon al entrar al mundo. El saldo persistido de Harford es autoritativo: cambios
-- nativos ajenos no se incorporan y se restauran mediante el mismo comando seguro.

HarfordDnDEconomy = HarfordDnDEconomy or {}

local API = HarfordDnDEconomy
local COPPER_PER_GOLD = 10000
local PENDING_TIMEOUT = 5
local LOGIN_SETTLE_DELAY = 1.25

local runtime = {
    pending = nil,
    merchantPending = nil,
    tradePending = nil,
    mailReceivePending = nil,
    mailSendPending = nil,
    suppressExternalUntil = 0,
    setupPromptScheduled = false,
    setupPromptDismissedFor = nil,
}

local function ProfileName(profileName)
    return tostring(profileName or (UnitName and UnitName("player")) or "default")
end

local function Profiles(create)
    HarfordDnDPersistStore = HarfordDnDPersistStore or {}
    if create and type(HarfordDnDPersistStore.profiles) ~= "table" then
        HarfordDnDPersistStore.profiles = {}
    end
    return HarfordDnDPersistStore.profiles
end

local function Entry(profileName, create)
    local profiles = Profiles(create)
    local name = ProfileName(profileName)
    local profile = profiles and profiles[name]
    if create and type(profile) ~= "table" then
        profile = {}
        profiles[name] = profile
    end
    local entry = profile and profile._economy
    if create and type(entry) ~= "table" then
        entry = {}
        profile._economy = entry
    end
    return entry, name
end

local function IsInitialized(entry)
    return type(entry) == "table" and entry.initialized == true and tonumber(entry.balance) ~= nil
end

local function CurrentMoney()
    return GetMoney and math.max(0, math.floor(tonumber(GetMoney()) or 0)) or nil
end

local function Now()
    return GetTime and GetTime() or 0
end

local function GoldToCopper(value)
    return math.max(0, math.floor((tonumber(value) or 0) * COPPER_PER_GOLD))
end

local function Roll(spec)
    spec = type(spec) == "table" and spec or {}
    local dice = math.max(0, math.floor(tonumber(spec.dice) or 0))
    local sides = math.max(1, math.floor(tonumber(spec.sides) or 1))
    local total = 0
    for _ = 1, dice do total = total + math.random(1, sides) end
    return total * math.max(1, math.floor(tonumber(spec.multiplier) or 1))
end

-- Epsilon_Merchant envia `.mod money` por su cuenta. Se autoriza una sola variacion
-- exacta, calculada desde la accion de compra/venta; abrir el merchant no basta.
local function ExpectMerchantDelta(delta)
    local before = CurrentMoney()
    delta = math.floor(tonumber(delta) or 0)
    if before == nil or delta == 0 then return false end
    runtime.merchantPending = {
        target = math.max(0, before + delta),
        expires = Now() + PENDING_TIMEOUT,
    }
    return true
end

-- Comercio y correo no convierten PLAYER_MONEY en una fuente de verdad. Cada ruta
-- arma antes una autorizacion efimera con el saldo exacto esperado; asi un `.mod money`
-- manual sigue siendo externo aunque se ejecute con las ventanas abiertas.
local function ExpectExternalDelta(kind, delta)
    local before = CurrentMoney()
    delta = math.floor(tonumber(delta) or 0)
    if before == nil or delta == 0 then return false end
    runtime[kind] = {
        target = math.max(0, before + delta),
        expires = Now() + PENDING_TIMEOUT,
    }
    return true
end

local function ClearExpiredExternalPending()
    for _, key in ipairs({ "merchantPending", "tradePending", "mailReceivePending", "mailSendPending" }) do
        local pending = runtime[key]
        if pending and Now() >= (tonumber(pending.expires) or 0) then
            runtime[key] = nil
        end
    end
end

local function GetMailHeaderMoney(index)
    if not GetInboxHeaderInfo then return 0, 0 end
    local _, _, _, _, money, cod = GetInboxHeaderInfo(index)
    return math.max(0, math.floor(tonumber(money) or 0)), math.max(0, math.floor(tonumber(cod) or 0))
end

local mailHooks = {}
local function InstallMailHooks()
    if not hooksecurefunc then return end

-- Enviar correo puede descontar adjunto y porte. MAIL_SEND_SUCCESS y
-- PLAYER_MONEY no tienen un orden estable en Epsilon, asi que conservamos la
-- operacion pendiente hasta observar el saldo final real.
    if not mailHooks.send and type(_G.SendMail) == "function" then
        hooksecurefunc("SendMail", function()
            local before = CurrentMoney()
            if before == nil then return end
            runtime.mailSendPending = {
                baseline = before,
                expires = Now() + PENDING_TIMEOUT,
                awaitingSuccess = true,
            }
        end)
        mailHooks.send = true
    end

    if not mailHooks.takeMoney and type(_G.TakeInboxMoney) == "function" then
        hooksecurefunc("TakeInboxMoney", function(index)
            local money = GetMailHeaderMoney(index)
            if money > 0 then ExpectExternalDelta("mailReceivePending", money) end
        end)
        mailHooks.takeMoney = true
    end

    -- El cobro contra reembolso es tambien una salida de dinero de correo. No se
    -- confunde con una compra normal porque solo se arma al retirar ese adjunto.
    local function ExpectCOD(index)
        local _, cod = GetMailHeaderMoney(index)
        if cod > 0 then ExpectExternalDelta("mailReceivePending", -cod) end
    end
    if not mailHooks.takeItem and type(_G.TakeInboxItem) == "function" then
        hooksecurefunc("TakeInboxItem", ExpectCOD)
        mailHooks.takeItem = true
    end
    if not mailHooks.autoLoot and type(_G.AutoLootMailItem) == "function" then
        hooksecurefunc("AutoLootMailItem", ExpectCOD)
        mailHooks.autoLoot = true
    end
end

local function ArmTradeDelta()
    local own = GetPlayerTradeMoney and tonumber(GetPlayerTradeMoney()) or 0
    local other = GetTargetTradeMoney and tonumber(GetTargetTradeMoney()) or 0
    own, other = math.max(0, math.floor(own or 0)), math.max(0, math.floor(other or 0))
    if own == 0 and other == 0 then
        runtime.tradePending = nil
        return
    end
    ExpectExternalDelta("tradePending", other - own)
end

local merchantHooks = {}
local function GetEpsilonMerchantPrice(itemId)
    local frame = _G.Epsilon_MerchantFrame
    local merchantId = frame and frame.merchantID
    local data = merchantId and _G.EPSILON_VENDOR_DATA and _G.EPSILON_VENDOR_DATA[merchantId]
    if type(data) ~= "table" then return nil, nil end
    for _, row in ipairs(data) do
        if type(row) == "table" and tonumber(row[1]) == tonumber(itemId) then
            return tonumber(row[2]), tonumber(row[3])
        end
    end
    return nil, nil
end

local function InstallEpsilonMerchantHooks()
    if not hooksecurefunc then return end

    if not merchantHooks.buy and type(_G.BuyEpsilon_MerchantItem) == "function" then
        hooksecurefunc("BuyEpsilon_MerchantItem", function(itemId, amount)
            local price = GetEpsilonMerchantPrice(itemId)
            if price and price > 0 then
                ExpectMerchantDelta(-price * math.max(1, math.floor(tonumber(amount) or 1)))
            end
        end)
        merchantHooks.buy = true
    end

    if not merchantHooks.sell and type(_G.SellEpsilon_MerchantItem) == "function" then
        hooksecurefunc("SellEpsilon_MerchantItem", function(bag, slot)
            local itemId = GetContainerItemID and GetContainerItemID(bag, slot)
            local _, count = GetContainerItemInfo and GetContainerItemInfo(bag, slot)
            if not itemId or not count or count <= 0 then return end

            local price, stackSize = GetEpsilonMerchantPrice(itemId)
            if price and price > 0 and stackSize and stackSize > 0 then
                ExpectMerchantDelta((price / stackSize) * count)
                return
            end

            local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemId)
            vendorPrice = tonumber(vendorPrice)
            if vendorPrice and vendorPrice > 0 then
                ExpectMerchantDelta(vendorPrice * count)
            end
        end)
        merchantHooks.sell = true
    end
end

-- Confirma solo el destino de una operacion iniciada por Harford. `PLAYER_MONEY` tambien
-- llega tras un `.modify money` manual, pero ese cambio no puede alterar la economia.
local function ConfirmPendingNativeBalance(profileName)
    local entry, name = Entry(profileName, false)
    if not IsInitialized(entry) then return nil end

    -- Esta economia pertenece exclusivamente al personaje local; nunca mezclar el oro
    -- del cliente con un perfil remoto que se este inspeccionando.
    if tostring(name) ~= ProfileName(nil) then
        return math.max(0, math.floor(tonumber(entry.balance) or 0))
    end

    local money = CurrentMoney()
    if money == nil then return math.max(0, math.floor(tonumber(entry.balance) or 0)) end
    ClearExpiredExternalPending()

    local pending = runtime.pending
    if pending and pending.profileName == name then
        if money == pending.target then
            runtime.pending = nil
            entry.balance = money
        end
    end

    for _, key in ipairs({ "merchantPending", "tradePending", "mailReceivePending" }) do
        local pending = runtime[key]
        if pending and money == pending.target then
            runtime[key] = nil
            entry.balance = money
            return money
        end
    end
    return math.max(0, math.floor(tonumber(entry.balance) or 0))
end

local function CommitMailSendBalance(profileName, pending, money)
    local entry = Entry(profileName, false)
    local baseline = tonumber(pending.baseline)
    -- Un correo real solo puede mantener o reducir el oro del remitente. No adoptar
    -- aumentos anormales evita convertir un comando manual en un ingreso valido.
    if money ~= nil and baseline ~= nil and money <= baseline then
        entry.balance = money
        runtime.mailSendPending = nil
        return true
    end
    return false
end

local function ConfirmMailSent(profileName)
    local pending = runtime.mailSendPending
    if not pending then return false end

    pending.awaitingSuccess = nil
    pending.successConfirmed = true

    -- Si PLAYER_MONEY llego primero, ya conocemos el saldo que confirmo el envio.
    if CommitMailSendBalance(profileName, pending, pending.observedMoney) then
        return true
    end

    -- Si MAIL_SEND_SUCCESS llego primero, Epsilon puede tardar varios frames (o
    -- segundos) en emitir PLAYER_MONEY. Renovar toda la ventana evita cerrar con
    -- el saldo previo y revertir despues el porte o el dinero adjunto.
    pending.expires = Now() + PENDING_TIMEOUT
    if C_Timer and C_Timer.After then
        C_Timer.After(PENDING_TIMEOUT, function()
            if runtime.mailSendPending ~= pending then return end
            CommitMailSendBalance(profileName, pending, CurrentMoney())
        end)
    else
        CommitMailSendBalance(profileName, pending, CurrentMoney())
    end
    return true
end

local function ObserveMailSendMoney(profileName)
    local pending = runtime.mailSendPending
    if not pending or Now() >= (tonumber(pending.expires) or 0) then return false end

    local money = CurrentMoney()
    local baseline = tonumber(pending.baseline)
    if money == nil or baseline == nil or money > baseline then return false end

    pending.observedMoney = money
    if pending.successConfirmed then
        return CommitMailSendBalance(profileName, pending, money)
    end
    return true
end

local function SetNativeBalance(target, profileName, callback)
    local entry, name = Entry(profileName, false)
    if not IsInitialized(entry) then
        if callback then callback(false, { "La economia no esta inicializada para este personaje." }) end
        return false, "La economia no esta inicializada para este personaje."
    end
    local current = CurrentMoney()
    if current == nil then
        if callback then callback(false, { "GetMoney no esta disponible." }) end
        return false, "GetMoney no esta disponible."
    end
    target = math.max(0, math.floor(tonumber(target) or 0))
    if current == target then
        entry.balance = target
        runtime.pending = nil
        if callback then callback(true) end
        return true
    end
    if not HarfordServerActions then
        if callback then callback(false, { "HarfordServerActions no disponible." }) end
        return false, "HarfordServerActions no disponible."
    end

    local delta = target - current
    local sender = delta > 0 and HarfordServerActions.GiveMoney or HarfordServerActions.TakeMoney
    if not sender then
        if callback then callback(false, { "Accion de dinero no disponible." }) end
        return false, "Accion de dinero no disponible."
    end

    -- Un cobro a la vez. `runtime.pending` es UNA ranura: dos operaciones en vuelo leen el mismo
    -- saldo de partida, calculan el mismo destino y la segunda pisa a la primera, de modo que se
    -- cobra una sola vez lo que se compro dos veces. Encadenar compras rapidas lo dispara solo.
    local enVuelo = runtime.pending
    if enVuelo and (tonumber(enVuelo.expires) or 0) > Now() then
        if callback then callback(false, { "Espera a que termine el cobro anterior." }) end
        return false, "Hay un cobro en curso."
    end

    runtime.pending = {
        profileName = name,
        target = target,
        expires = Now() + PENDING_TIMEOUT,
    }
    local function Done(success, messages)
        if success then
            entry.balance = target
            -- Conserva `pending` hasta que PLAYER_MONEY vea el saldo real: evita adoptar
            -- el oro previo de Epsilon si el callback llega antes que el evento nativo.
            if C_Timer and C_Timer.After then
                C_Timer.After(PENDING_TIMEOUT, function()
                    local pending = runtime.pending
                    if pending and pending.profileName == name and pending.target == target then
                        runtime.pending = nil
                    end
                end)
            end
        else
            runtime.pending = nil
        end
        if callback then callback(success and true or false, messages) end
    end
    local sent, err = sender(math.abs(delta), {
        addonName = "Harford",
        forceEpsilon = true,
        showMessages = false,
        callback = Done,
    })
    if not sent then runtime.pending = nil end
    return sent, err
end

function API.IsInitialized(profileName)
    return IsInitialized(Entry(profileName, false))
end

-- Una economia sin inicializar vale CERO, no "desconocido". Devolver nil obligaba a cada
-- consumidor a distinguir dos casos que para el jugador son el mismo —no tiene dinero— y hacia
-- que la ventana de entrenador pintase "necesitas mas dinero" en TODAS las recetas de cualquier
-- personaje anterior a la creacion nueva, tuviera el oro que tuviera.
--
-- Sigue siendo distinto de "esta inicializada": para eso esta `API.IsInitialized`, que es lo que
-- mira la oferta de puesta en marcha. Aqui la pregunta es cuanto hay, y la respuesta es cero.
function API.GetBalance(profileName)
    local entry = Entry(profileName, false)
    if not IsInitialized(entry) then return 0 end
    return math.max(0, math.floor(tonumber(entry.balance) or 0))
end

function API.GetInitialGold(draft)
    if type(draft) ~= "table" then return nil, "Borrador invalido." end
    local classEntry = type(draft.classes) == "table" and draft.classes[1] or nil
    local classDef = classEntry and HarfordDnDBook and HarfordDnDBook.GetClass
        and HarfordDnDBook.GetClass(classEntry.classId)
    local bgDef = HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(draft.backgroundId)
    if not classDef or not bgDef then return nil, "Clase o trasfondo sin datos de inicio." end
    local classGold = Roll(classDef.startingGold)
    local backgroundGold = HarfordDnDBackgrounds.GetStartingGold and HarfordDnDBackgrounds.GetStartingGold(bgDef.id, draft.backgroundVariantId) or 0
    return {
        classGold = classGold,
        backgroundGold = math.max(0, math.floor(tonumber(backgroundGold) or 0)),
        totalGold = classGold + math.max(0, math.floor(tonumber(backgroundGold) or 0)),
        classId = classDef.id,
        backgroundId = bgDef.id,
    }
end

-- Las fichas creadas antes de la economia ya tienen progresion, pero no un saldo
-- Harford. Se construye el mismo borrador minimo que usa la creacion solo para
-- ofrecer una sugerencia; el jugador siempre puede sustituirla.
local function ExistingSheetDraft(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.HasProgression
        and HarfordDnDProgression.HasProgression(profileName)) then
        return nil
    end
    local data = HarfordDnDProgression.Get and HarfordDnDProgression.Get(profileName)
    if type(data) ~= "table" or type(data.classLevels) ~= "table" or not data.classLevels[1] then
        return nil
    end
    local classes = {}
    for _, entry in ipairs(data.classLevels) do
        classes[#classes + 1] = { classId = entry.classId, subclassId = entry.subclassId, level = entry.level }
    end
    return { classes = classes, backgroundId = data.background }
end

function API.GetExistingSheetSuggestion(profileName)
    local entry = Entry(profileName, true)
    if tonumber(entry.setupSuggestedGold) ~= nil then
        return math.max(0, math.floor(tonumber(entry.setupSuggestedGold) or 0))
    end
    local draft = ExistingSheetDraft(profileName)
    local initial = draft and API.GetInitialGold(draft)
    if type(initial) ~= "table" then return nil end
    entry.setupSuggestedGold = math.max(0, math.floor(tonumber(initial.totalGold) or 0))
    return entry.setupSuggestedGold
end

function API.InitializeExistingSheet(copper, profileName, callback)
    local draft = ExistingSheetDraft(profileName)
    if not draft then
        if callback then callback(false, { "No hay una ficha Harford valida para inicializar." }) end
        return false, "No hay una ficha Harford valida para inicializar."
    end
    local existing = Entry(profileName, false)
    if IsInitialized(existing) then
        if callback then callback(true, existing) end
        return true, existing
    end
    local current = CurrentMoney()
    if current == nil then
        if callback then callback(false, { "GetMoney no esta disponible." }) end
        return false, "GetMoney no esta disponible."
    end

    local entry, name = Entry(profileName, true)
    entry.balance = math.max(0, math.floor(tonumber(copper) or 0))
    entry.initialized = true
    entry.initializedFromExistingSheet = true
    entry.setupSuggestedGold = nil
    local target = entry.balance
    local sent, sendErr = SetNativeBalance(target, name, function(success, messages)
        if not success then
            entry.initialized = nil
            entry.balance = nil
            entry.initializedFromExistingSheet = nil
        end
        if callback then callback(success, messages) end
    end)
    if not sent then
        entry.initialized = nil
        entry.balance = nil
        entry.initializedFromExistingSheet = nil
    end
    return sent, sendErr
end

function API.DismissExistingSheetSetup(profileName)
    local entry, name = Entry(profileName, false)
    if IsInitialized(entry) then return false end
    -- Cancelar no persiste una decision economica: solo evita insistir hasta el
    -- siguiente runtime (reload/login), cuando la ficha se vuelve a comprobar.
    runtime.setupPromptDismissedFor = name
    return true
end

function API.ResetExistingSheetSetup(profileName)
    local entry, name = Entry(profileName, false)
    if IsInitialized(entry) then return false end
    runtime.setupPromptDismissedFor = nil
    return true
end

local setupFrame
local function MoneyInput(parent, label, textureX, anchor, x)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -14)
    text:SetText(label)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(76, 22)
    box:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -4)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(8)
    box:SetText("0")

    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", box, "RIGHT", 4, 0)
    icon:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
    icon:SetTexCoord(textureX, textureX + .25, 0, 1)
    return box
end

local function OpenExistingSheetSetup(profileName)
    if not UIParent then return end
    local suggested = API.GetExistingSheetSuggestion(profileName)

    if not setupFrame then
        local frame = CreateFrame("Frame", "HarfordEconomySetupFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(380, 252)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetToplevel(true)
        frame:Hide()
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("Configurar saldo Harford")
        frame.info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.info:SetPoint("TOPLEFT", 22, -38)
        frame.info:SetPoint("TOPRIGHT", -22, -38)
        frame.info:SetJustifyH("LEFT")
        frame.info:SetJustifyV("TOP")
        frame.info:SetWordWrap(true)
        frame.info:SetText("Esta ficha ya existe, pero aun no tiene un saldo Harford.\nLa cantidad sugerida procede de su primera clase y trasfondo; puedes cambiarla antes de aplicarla una sola vez.")
        frame.gold = MoneyInput(frame, "Oro", 0, frame.info, 0)
        frame.silver = MoneyInput(frame, "Plata", .25, frame.info, 122)
        frame.copper = MoneyInput(frame, "Cobre", .5, frame.info, 244)
        frame.suggestion = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        frame.suggestion:SetPoint("TOPLEFT", frame.gold, "BOTTOMLEFT", 0, -13)
        frame.suggestion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -130)
        frame.suggestion:SetJustifyH("LEFT")

        frame.apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.apply:SetSize(142, 24)
        frame.apply:SetPoint("BOTTOMLEFT", 52, 18)
        frame.apply:SetText(ACCEPT or "Aceptar")
        frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.cancel:SetSize(142, 24)
        frame.cancel:SetPoint("BOTTOMRIGHT", -52, 18)
        frame.cancel:SetText(CANCEL or "Cancelar")
        frame.cancel:SetScript("OnClick", function(self)
            API.DismissExistingSheetSetup(self.profileName)
            self:GetParent():Hide()
        end)
        frame.apply:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            local gold = math.max(0, math.floor(tonumber(parent.gold:GetText()) or 0))
            local silver = math.max(0, math.min(99, math.floor(tonumber(parent.silver:GetText()) or 0)))
            local copper = math.max(0, math.min(99, math.floor(tonumber(parent.copper:GetText()) or 0)))
            self:Disable()
            local ok, err = API.InitializeExistingSheet(gold * COPPER_PER_GOLD + silver * 100 + copper, parent.profileName,
                function(success, messages)
                    if success then
                        parent:Hide()
                        return
                    end
                    self:Enable()
                    if HarfordChat and HarfordChat.Print then
                        HarfordChat.Print("|cffff5555No se pudo inicializar el saldo: "
                            .. tostring((type(messages) == "table" and messages[1]) or messages or "error desconocido") .. "|r")
                    end
                end)
            if not ok then
                self:Enable()
                if HarfordChat and HarfordChat.Print then
                    HarfordChat.Print("|cffff5555No se pudo inicializar el saldo: " .. tostring(err or "error desconocido") .. "|r")
                end
            end
        end)
        setupFrame = frame
    end

    local gold = math.floor(tonumber(suggested) or 0)
    setupFrame.profileName = ProfileName(profileName)
    setupFrame.gold:SetText(tostring(gold))
    setupFrame.silver:SetText("0")
    setupFrame.copper:SetText("0")
    if suggested ~= nil then
        setupFrame.suggestion:SetText("Sugerencia de clase y trasfondo: " .. tostring(gold) .. " oro.")
    else
        setupFrame.suggestion:SetText("No hay datos suficientes para calcular la sugerencia; indica el saldo que corresponda.")
    end
    setupFrame.apply:Enable()
    setupFrame:Show()
end

local function PromptExistingSheetSetup(profileName)
    runtime.setupPromptScheduled = false
    local entry, name = Entry(profileName, false)
    if IsInitialized(entry) or runtime.setupPromptDismissedFor == name then return end
    if not ExistingSheetDraft(name) or not StaticPopup_Show then return end

    StaticPopupDialogs.HARFORD_ECONOMY_EXISTING_SHEET = StaticPopupDialogs.HARFORD_ECONOMY_EXISTING_SHEET or {
        text = "Tu ficha Harford ya esta cargada, pero su saldo Harford aun no se ha inicializado. Puedes configurarlo ahora o continuar sin economia Harford.",
        button1 = "Configurar saldo",
        button2 = "Ahora no",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(self) OpenExistingSheetSetup(self.data) end,
        OnCancel = function(self) API.DismissExistingSheetSetup(self.data) end,
    }
    StaticPopup_Show("HARFORD_ECONOMY_EXISTING_SHEET", nil, nil, name)
end

function API.InitializeFromCreation(draft, profileName, callback)
    local existing = Entry(profileName, false)
    if IsInitialized(existing) then
        if callback then callback(true, existing) end
        return true, existing
    end
    local initial, err = API.GetInitialGold(draft)
    if not initial then
        if callback then callback(false, { err }) end
        return false, err
    end
    local current = CurrentMoney()
    if current == nil then
        if callback then callback(false, { "GetMoney no esta disponible." }) end
        return false, "GetMoney no esta disponible."
    end
    local entry = Entry(profileName, true)
    entry.balance = GoldToCopper(initial.totalGold)
    entry.initialGold = initial.totalGold
    entry.classGold = initial.classGold
    entry.backgroundGold = initial.backgroundGold
    entry.classId = initial.classId
    entry.backgroundId = initial.backgroundId

    -- Aun no queda activada: si el servidor rechaza la correccion no se bloqueara
    -- al personaje con un saldo ficticio y la siguiente aplicacion podra reintentarlo.
    entry.initialized = true
    local target = entry.balance
    local sent, sendErr = SetNativeBalance(target, profileName, function(success, messages)
        if not success then
            entry.initialized = nil
            entry.balance = nil
            entry.initialGold = nil
            entry.classGold = nil
            entry.backgroundGold = nil
            entry.classId = nil
            entry.backgroundId = nil
        end
        if callback then callback(success, messages) end
    end)
    if not sent then
        entry.initialized = nil
        entry.balance = nil
        entry.initialGold = nil
        entry.classGold = nil
        entry.backgroundGold = nil
        entry.classId = nil
        entry.backgroundId = nil
    end
    return sent, sendErr or initial
end

function API.CanAfford(copper, profileName)
    local cost = math.max(0, math.floor(tonumber(copper) or 0))
    return API.GetBalance(profileName) >= cost
end

function API.Spend(copper, opts)
    opts = opts or {}
    local cost = math.max(0, math.floor(tonumber(copper) or 0))
    -- Sin economia inicializada el saldo es 0, asi que esto cae solo en el mensaje honesto de
    -- abajo. Escribir sigue guardado en SetNativeBalance, que es donde toca.
    local balance = API.GetBalance(opts.profileName)
    if cost > balance then
        if opts.callback then opts.callback(false, { "No tienes suficiente dinero." }) end
        return false, "No tienes suficiente dinero."
    end
    return SetNativeBalance(balance - cost, opts.profileName, opts.callback)
end

function API.Grant(copper, opts)
    opts = opts or {}
    local amount = math.max(0, math.floor(tonumber(copper) or 0))
    local balance = API.GetBalance(opts.profileName)
    return SetNativeBalance(balance + amount, opts.profileName, opts.callback)
end

function API.Reconcile(profileName)
    local entry = Entry(profileName, false)
    if not IsInitialized(entry) then return false end
    return SetNativeBalance(entry.balance, profileName)
end

do
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("TRADE_SHOW")
    events:RegisterEvent("TRADE_ACCEPT_UPDATE")
    events:RegisterEvent("TRADE_REQUEST_CANCEL")
    events:RegisterEvent("TRADE_CLOSED")
    events:RegisterEvent("MAIL_SEND_SUCCESS")
    events:RegisterEvent("MAIL_FAILED")
    events:SetScript("OnEvent", function(_, event, arg1, ...)
        if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and arg1 == "Epsilon_Merchant") then
            InstallEpsilonMerchantHooks()
            InstallMailHooks()
            return
        end
        local entry, name = Entry(nil, false)
        if not IsInitialized(entry) then
            if event == "PLAYER_ENTERING_WORLD" and not runtime.setupPromptScheduled
                and runtime.setupPromptDismissedFor ~= name then
                runtime.setupPromptScheduled = true
                if C_Timer and C_Timer.After then
                    C_Timer.After(LOGIN_SETTLE_DELAY, function() PromptExistingSheetSetup(name) end)
                else
                    PromptExistingSheetSetup(name)
                end
            end
            return
        end

        if event == "TRADE_SHOW" then
            runtime.tradePending = nil
            return
        end
        if event == "TRADE_ACCEPT_UPDATE" then
            local playerAccepted, targetAccepted = arg1, select(1, ...)
            if playerAccepted == 1 and targetAccepted == 1 then
                ArmTradeDelta()
            else
                runtime.tradePending = nil
            end
            return
        end
        if event == "TRADE_REQUEST_CANCEL" then
            runtime.tradePending = nil
            return
        end
        if event == "TRADE_CLOSED" then
            -- La actualizacion de dinero puede llegar justo despues del cierre; el
            -- permiso exacto expira solo, en vez de adoptar cualquier cambio.
            return
        end
        if event == "MAIL_FAILED" then
            runtime.mailSendPending = nil
            return
        end
        if event == "MAIL_SEND_SUCCESS" then
            if not ConfirmMailSent(name) then
                API.Reconcile(name)
            end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" then
            runtime.suppressExternalUntil = Now() + LOGIN_SETTLE_DELAY
            if C_Timer and C_Timer.After then
                C_Timer.After(LOGIN_SETTLE_DELAY, function()
                    runtime.suppressExternalUntil = 0
                    API.Reconcile(name)
                end)
            else
                API.Reconcile(name)
            end
            return
        end

        -- Durante el breve arranque Epsilon puede emitir cambios de su oro inicial.
        -- El reconcile diferido de PLAYER_ENTERING_WORLD lo corrige una sola vez.
        if Now() < runtime.suppressExternalUntil then return end

        -- El servidor puede emitir PLAYER_MONEY antes o despues de MAIL_SEND_SUCCESS.
        -- Mientras exista un envio pendiente, ese evento pertenece al correo y no se
        -- puede tratar como una modificacion externa que haya que revertir.
        if runtime.mailSendPending then
            ObserveMailSendMoney(name)
            return
        end

        local balance = ConfirmPendingNativeBalance(name)
        if balance ~= nil and CurrentMoney() ~= balance then
            -- Cambio externo: el contador Harford se conserva y el oro visible vuelve
            -- al saldo autorizado. El siguiente PLAYER_MONEY confirmara este destino.
            API.Reconcile(name)
        end
    end)
end
