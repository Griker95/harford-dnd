-- Carga los ficheros del addon como lo haria el cliente, para ver los errores de EJECUCION que
-- ocurren al cargar. El compilador no los ve: un `end` de mas cierra una funcion antes de tiempo,
-- el fichero sigue compilando y su cuerpo pasa a ejecutarse en el chunk principal, donde las
-- variables locales de la funcion no existen. Eso es exactamente lo que rompio HarfordUnitFrames.
--
-- No es el cliente: los frames son objetos permisivos y el entorno grafico no existe. Sirve para
-- una sola cosa, que es la que faltaba -- saber si un fichero revienta NADA MAS CARGARSE.

local raiz = ...

-- ---------------------------------------------------------------- objeto permisivo
-- Todo lo que devuelve CreateFrame responde a cualquier metodo y devuelve otro igual, de modo que
-- las cadenas largas de construccion de UI no fallan por falta de stub. Lo que SI se deja nil es
-- cualquier global de WoW que no declaremos: asi un `algo.campo` sobre un nil sale a la luz en vez
-- de quedar tapado.
local objeto
local function nuevo()
    local t = {}
    setmetatable(t, {
        __index = function(_, k)
            if k == "GetName" then return function() return "Stub" end end
            return objeto
        end,
        __newindex = function(tt, k, v) rawset(tt, k, v) end,
        __call = function() return nuevo() end,
        -- Un frame de verdad devuelve numeros en GetFrameLevel, GetWidth, GetScale... Sin esto el
        -- arnes falla en cualquier `f:GetFrameLevel() + 5` y esos falsos positivos ahogarian los
        -- errores de verdad.
        __add = function() return 0 end, __sub = function() return 0 end,
        __mul = function() return 0 end, __div = function() return 0 end,
        __unm = function() return 0 end, __mod = function() return 0 end,
        __pow = function() return 0 end, __len = function() return 0 end,
        __lt = function() return false end, __le = function() return false end,
        __concat = function(x, y)
            local function txt(v) return type(v) == "table" and "" or tostring(v) end
            return txt(x) .. txt(y)
        end,
    })
    return t
end
objeto = setmetatable({}, {
    __call = function(...) return nuevo() end,
    __index = function() return objeto end,
})

local function fn() return nuevo() end

-- ---------------------------------------------------------------- API de WoW
local WOW = {
    "CreateFrame", "hooksecurefunc", "UIParent", "GameTooltip", "GameFontNormal",
    "GameFontHighlight", "GameFontNormalSmall", "GameFontHighlightSmall", "NumberFontNormal",
    "UnitName", "UnitGUID", "UnitClass", "UnitRace", "UnitSex", "UnitLevel", "UnitExists",
    "UnitIsPlayer", "UnitIsUnit", "UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax",
    "UnitPosition", "UnitAffectingCombat", "GetTime", "GetLocale", "GetRealmName",
    "GetInventorySlotInfo", "GetInventoryItemLink", "GetItemInfo", "GetItemStats",
    "GetItemIcon", "GetFileIDFromPath", "GetSpellInfo", "GetSpellTexture", "GetActionInfo",
    "GetActionBarPage", "GetCursorPosition", "InCombatLockdown", "IsShiftKeyDown",
    "IsControlKeyDown", "IsAltKeyDown", "IsInGroup", "IsInRaid", "IsInGuild",
    "GetNumGroupMembers", "UnitInParty", "UnitInRaid", "PlaySound", "PlaySoundFile",
    "SendChatMessage", "C_ChatInfo", "C_Timer", "C_Map", "C_Epsilon", "C_Item", "C_Container",
    "C_Spell", "C_UnitAuras", "C_CVar", "C_AddOns", "Ambiguate", "strsplit", "strjoin",
    "strtrim", "date", "time", "random", "wipe", "tContains", "tinsert", "tremove",
    "UIDropDownMenu_Initialize", "UIDropDownMenu_CreateInfo", "UIDropDownMenu_AddButton",
    "ToggleDropDownMenu", "CloseDropDownMenus", "UIDropDownMenu_SetWidth",
    "ChatFrame1", "DEFAULT_CHAT_FRAME", "SlashCmdList", "StaticPopupDialogs", "StaticPopup_Show",
    "SetCVar", "GetCVar", "ReloadUI", "Screenshot", "PlayerFrame", "TargetFrame", "FocusFrame",
    "TargetFrameToT", "MainMenuBar", "MainMenuBarArtFrame", "ActionButton1",
    "ActionBarButtonEventsFrame", "MultiBarBottomLeftButton1", "CharacterFrame",
    "SpellBookFrame", "TradeSkillFrame", "ObjectiveTrackerFrame", "MerchantFrame",
    "NamePlateDriverFrame", "CompactRaidFrameContainer", "Enum", "LE_ITEM_QUALITY_COMMON",
    "BackdropTemplateMixin", "Mixin", "CreateFromMixins", "CopyTable", "securecall",
    "issecurevariable", "GetBuildInfo", "GetAddOnMetadata", "IsAddOnLoaded", "LoadAddOn",
    "GetContainerNumSlots", "GetContainerItemLink", "UnitBuff", "UnitDebuff", "UnitAura",
    "GetSpellCooldown", "GetTalentInfo", "GetNumSpellTabs", "GetSpellTabInfo",
    "TRP3_API", "EpsilonLib", "ARC", "Kui", "MSA_DropDownMenu_Create",
    "MSA_DropDownMenu_Initialize", "MSA_ToggleDropDownMenu", "LibStub", "Settings",
    "GetMouseFocus", "GetScreenWidth", "GetScreenHeight", "InterfaceOptions_AddCategory",
    "PanelTemplates_SetNumTabs", "PanelTemplates_SetTab", "PaperDollFrame", "GetSpecialization",
    "ChatFrame_AddMessageEventFilter", "ChatFrame_OnHyperlinkShow", "IsMouseButtonDown",
    "GetMoney", "GetCoinTextureString", "BreakUpLargeNumbers", "FormatLargeNumber",
    "UnitFactionGroup", "GetFactionInfoByID", "SetPortraitTexture", "SetPortraitToTexture",
    "ButtonFrameTemplate_HideButtonBar", "ButtonFrameTemplate_HideAtticButton",
    "NineSliceUtil", "SetLootMethod", "GetLootMethod", "UnitIsGroupLeader",
    "UIDropDownMenu_SetText", "Saturate",
}
for _, nombre in ipairs(WOW) do
    if _G[nombre] == nil then _G[nombre] = objeto end
end
-- Los que tienen que devolver algo concreto para no falsear el flujo:
-- Un frame CON NOMBRE registra su global, igual que en el cliente: hay codigo que luego lo busca
-- por ese nombre (HarfordLootFrameDownButton). Sin esto el arnes daria un falso positivo ahi.
_G.CreateFrame = function(_, nombre)
    local f = nuevo()
    if type(nombre) == "string" and nombre ~= "" then _G[nombre] = f end
    return f
end
_G.hooksecurefunc = function() end
_G.GetTime = function() return 0 end
_G.time = os.time
_G.date = os.date
_G.UnitName = function() return "Pruebas", nil end
_G.GetLocale = function() return "esES" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
_G.strsplit = function(sep, s)
    local fuera = {}
    for parte in tostring(s):gmatch("([^" .. sep .. "]*)") do fuera[#fuera + 1] = parte end
    return unpack(fuera)
end
_G.SlashCmdList = {}
_G.DEFAULT_CHAT_FRAME = nuevo()
_G.UIParent = nuevo()
_G.C_Timer = { After = function() end, NewTicker = function() return nuevo() end }
_G.geterrorhandler = function() return function(e) error(e, 0) end end

-- ---------------------------------------------------------------- carga
local function ficherosDelToc(carpeta, toc)
    local fuera = {}
    local fh = io.open(raiz .. "/" .. carpeta .. "/" .. toc)
    if not fh then return fuera end
    for linea in fh:lines() do
        linea = linea:gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if linea:match("%.lua$") and not linea:match("^#") then
            fuera[#fuera + 1] = carpeta .. "/" .. (linea:gsub("\\", "/"))
        end
    end
    fh:close()
    return fuera
end

local ADDONS = {
    { "HarfordProfessionsData", "HarfordProfessionsData.toc" },
    { "HarfordCompendioData", "HarfordCompendioData.toc" },
    { "Harford", "Harford.toc" },
    { "HarfordAdmin", "HarfordAdmin.toc" },
    { "HarfordDebug", "HarfordDebug.toc" },
}

local total, fallos = 0, {}
for _, a in ipairs(ADDONS) do
    for _, rel in ipairs(ficherosDelToc(a[1], a[2])) do
        local ruta = raiz .. "/" .. rel
        local chunk, err = loadfile(ruta)
        if not chunk then
            fallos[#fallos + 1] = { rel, "no compila: " .. tostring(err) }
        else
            total = total + 1
            local ok, e = pcall(chunk)
            if not ok then fallos[#fallos + 1] = { rel, tostring(e) } end
        end
    end
end

print(string.format("Ficheros cargados: %d   con error al cargar: %d", total, #fallos))
for _, f in ipairs(fallos) do
    print("")
    print("  " .. f[1])
    print("    " .. f[2])
end
os.exit(#fallos > 0 and 1 or 0)
