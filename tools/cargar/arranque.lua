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
-- WoW corre Lua 5.1, donde `unpack` es global. En 5.2+ se movio a table.unpack.
_G.unpack = _G.unpack or table.unpack
_G.SlashCmdList = {}
-- Listas de WoW que el codigo rellena: tienen que ser tablas de verdad, no el objeto permisivo.
_G.UISpecialFrames = {}
_G.StaticPopupDialogs = {}
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
    { "HarfordProfesiones", "HarfordProfesiones.toc" },
    { "HarfordCompendio", "HarfordCompendio.toc" },
    { "Harford", "Harford.toc" },
    { "HarfordAdmin", "HarfordAdmin.toc" },
    { "HarfordDebug", "HarfordDebug.toc" },
}

-- Ultima linea del fichero que contiene codigo de verdad (ni blanca ni comentario).
local function ultimaLineaConCodigo(ruta)
    local n, i = 0, 0
    for linea in io.lines(ruta) do
        i = i + 1
        local limpia = linea:gsub("%-%-.*", ""):gsub("%s", "")
        if limpia ~= "" then n = i end
    end
    return n
end

local total, fallos = 0, {}
for _, a in ipairs(ADDONS) do
    for _, rel in ipairs(ficherosDelToc(a[1], a[2])) do
        local ruta = raiz .. "/" .. rel
        local chunk, err = loadfile(ruta)
        if not chunk then
            fallos[#fallos + 1] = { rel, "no compila: " .. tostring(err) }
        else
            total = total + 1
            -- Ultima linea ejecutada en el CHUNK PRINCIPAL. Un `return` a nivel de fichero -- que
            -- es lo que deja un `end` de mas dentro de un `do` -- corta el fichero ahi sin dar
            -- ningun error: todo lo que viene despues no llega a existir. Asi es como el panel de
            -- personaje se quedaba sin sus 2600 ultimas lineas y sin su comando.
            local ultima = 0
            -- Solo el chunk principal DE ESTE fichero: sin comprobar el origen, el hook tambien
            -- cuenta las lineas del propio arnes y todos los ficheros parecen cortarse igual.
            local marca = rel:match("([^/]+)$")
            debug.sethook(function(_, linea)
                local info = debug.getinfo(2, "S")
                if info and info.what == "main" and info.short_src
                    and info.short_src:sub(-#marca) == marca then
                    ultima = linea
                end
            end, "l")
            local ok, e = pcall(chunk)
            debug.sethook()
            if not ok then
                fallos[#fallos + 1] = { rel, tostring(e) }
            elseif ultima > 0 and ultima < ultimaLineaConCodigo(ruta) - 2 then
                fallos[#fallos + 1] = { rel, string.format(
                    "el fichero se corta en la linea %d y tiene codigo hasta la %d: hay un `return` "
                    .. "a nivel de fichero (casi siempre, un `end` de mas dentro de un `do`)",
                    ultima, ultimaLineaConCodigo(ruta)) }
            end
        end
    end
end

-- ---------------------------------------------------------------- rutas de barra
-- El despachador de `/harford` hace `local f = SlashCmdList[key]; if f then f(rest) end`: una clave
-- que NO existe se traga el subcomando en silencio, sin abrir nada y sin dar error. Asi es como
-- `/harford char` dejo de abrir el panel al perderse su registro en el refactor.
--
-- Las claves se sacan del propio despachador, no de una lista escrita aqui, para que anadir un
-- subcomando nuevo quede cubierto solo.
do
    local fh = io.open(raiz .. "/Harford/DnD/UI/HarfordDnD.lua")
    if fh then
        local src = fh:read("*a")
        fh:close()
        local vistas = {}
        for clave in src:gmatch('route%("([A-Z0-9]+)"%)') do vistas[clave] = true end
        for clave in pairs(vistas) do
            if type(SlashCmdList[clave]) ~= "function" then
                -- Las que se registran dentro de un evento (HARFORDCONFIG, en PLAYER_LOGIN) no
                -- existen todavia aqui y no son un fallo.
                if not src:find('SlashCmdList%["' .. clave .. '"%]')
                    and not io.open(raiz .. "/Harford/Core/HarfordConfig.lua") then
                    fallos[#fallos + 1] = { "despachador", clave .. ": /harford la enruta y nadie la registra" }
                end
                local encontrada = false
                for _, a2 in ipairs(ADDONS) do
                    for _, rel2 in ipairs(ficherosDelToc(a2[1], a2[2])) do
                        local f2 = io.open(raiz .. "/" .. rel2)
                        if f2 then
                            local s2 = f2:read("*a"); f2:close()
                            if s2:find('SlashCmdList%["' .. clave .. '"%]')
                                or s2:find('SlashCmdList%.' .. clave) then
                                encontrada = true
                            end
                        end
                    end
                end
                if not encontrada then
                    fallos[#fallos + 1] = { "despachador",
                        clave .. ": `/harford` la enruta y NADIE la registra (el subcomando no hace nada)" }
                end
            end
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
