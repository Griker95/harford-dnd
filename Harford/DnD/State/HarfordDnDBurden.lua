------------------------------------------------------------
-- HarfordDnDBurden - Sintonizacion de objetos magicos y capacidad de carga.
--
-- SINTONIZACION (Guia del Dungeon Master):
--   * Un objeto solo puede estar sintonizado con UNA criatura a la vez, y una criatura no
--     puede estar sintonizada con MAS DE TRES objetos magicos. El cuarto intento falla; hay
--     que romper antes otra sintonizacion.
--   * Tampoco se puede estar sintonizado con dos copias del MISMO objeto.
--   * Quien no se sintoniza con un objeto que lo requiere solo disfruta de sus beneficios NO
--     magicos (un escudo magico sigue siendo un escudo).
--
-- CARGA (Manual del Jugador): el peso que puedes llevar es tu puntuacion de Fuerza x 15.
--
-- Que decide este modulo y que no: lleva la cuenta de que objetos estan sintonizados y del
-- peso transportado. NO decide que objeto requiere sintonizacion: eso lo declara el objeto
-- (por descripcion o por marca del DM), igual que el resto de reglas de objeto ya se leen de
-- la descripcion en HarfordDnDItems.
--
-- Persistencia: junto al equipo del perfil, en `_attunement`.
------------------------------------------------------------

HarfordDnDBurden = HarfordDnDBurden or {}
local API = HarfordDnDBurden

API.MAX_ATTUNED = 3          -- limite del manual
API.CARRY_PER_STRENGTH = 15  -- Fuerza x 15 libras

local function Print(text)
    if HarfordChat and HarfordChat.Print then HarfordChat.Print(text) end
end

local function ProfileName(profileName)
    if profileName and profileName ~= "" then return profileName end
    if HarfordDnDAPI and HarfordDnDAPI.GetProfileName then
        local n = HarfordDnDAPI.GetProfileName()
        if n and n ~= "" then return n end
    end
    return (UnitName and UnitName("player")) or "player"
end

-- Tabla de sintonizacion del perfil: { [itemId] = { name = "...", at = epoch } }
local function Store(profileName, create)
    local profiles = HarfordDnDPersistStore and HarfordDnDPersistStore.profiles
    if not profiles then return nil end
    local slot = profiles[ProfileName(profileName)]
    if not slot then
        if not create then return nil end
        slot = {}
        profiles[ProfileName(profileName)] = slot
    end
    if type(slot._attunement) ~= "table" then
        if not create then return nil end
        slot._attunement = {}
    end
    return slot._attunement
end

------------------------------------------------------------
-- Sintonizacion
------------------------------------------------------------

function API.GetAttuned(profileName)
    local out = {}
    for itemId, entry in pairs(Store(profileName, false) or {}) do
        out[#out + 1] = { itemId = tonumber(itemId), name = entry.name, at = entry.at }
    end
    table.sort(out, function(a, b) return (a.at or 0) < (b.at or 0) end)
    return out
end

function API.CountAttuned(profileName)
    local n = 0
    for _ in pairs(Store(profileName, false) or {}) do n = n + 1 end
    return n
end

function API.IsAttuned(itemId, profileName)
    local store = Store(profileName, false)
    return store and store[tostring(itemId)] ~= nil or false
end

-- Sintonizarse con un objeto. Falla si ya hay tres, o si ya se tiene una copia del mismo.
function API.Attune(itemId, itemName, profileName)
    itemId = tonumber(itemId)
    if not itemId then return false, "Objeto invalido" end
    local store = Store(profileName, true)
    if not store then return false, "Sin perfil" end
    local key = tostring(itemId)

    if store[key] then return false, "Ya estas sintonizado con ese objeto" end
    -- "No se puede estar sintonizado con mas de una copia del mismo objeto": mismo itemId ya
    -- lo cubre la comprobacion anterior, y el mismo NOMBRE cubre copias con id distinto.
    local wanted = tostring(itemName or ""):lower()
    if wanted ~= "" then
        for _, entry in pairs(store) do
            if tostring(entry.name or ""):lower() == wanted then
                return false, "Ya estas sintonizado con otra copia de ese objeto"
            end
        end
    end
    if API.CountAttuned(profileName) >= API.MAX_ATTUNED then
        return false, string.format("Ya estas sintonizado con %d objetos: rompe una sintonizacion antes",
            API.MAX_ATTUNED)
    end

    store[key] = { name = itemName or ("Objeto " .. itemId), at = (time and time()) or 0 }
    Print(string.format("Te sintonizas con |cffffd100%s|r (%d de %d).",
        store[key].name, API.CountAttuned(profileName), API.MAX_ATTUNED))
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

function API.Unattune(itemId, profileName)
    local store = Store(profileName, false)
    local key = tostring(tonumber(itemId) or "")
    if not (store and store[key]) then return false, "No estabas sintonizado con ese objeto" end
    local name = store[key].name
    store[key] = nil
    Print(string.format("Rompes la sintonizacion con |cffffd100%s|r.", tostring(name)))
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

-- ¿Este objeto pide sintonizacion? Se lee de su descripcion, igual que el resto de reglas de
-- objeto. No se inventa: si el texto no lo dice, no la requiere.
function API.RequiresAttunement(itemLink)
    if not itemLink then return false end
    local text = tostring(itemLink)
    if GameTooltip and GameTooltip.SetHyperlink and C_Item then
        -- El tooltip es la via fiable; el enlace suelto solo trae el nombre.
        local scanner = _G.HarfordBurdenScanner
        if not scanner then
            scanner = CreateFrame("GameTooltip", "HarfordBurdenScanner", nil, "GameTooltipTemplate")
            scanner:SetOwner(UIParent, "ANCHOR_NONE")
            _G.HarfordBurdenScanner = scanner
        end
        scanner:ClearLines()
        local ok = pcall(scanner.SetHyperlink, scanner, itemLink)
        if ok then
            for i = 1, scanner:NumLines() do
                local line = _G["HarfordBurdenScannerTextLeft" .. i]
                local t = line and line:GetText()
                if t and t:lower():find("sintoniza") then return true, t end
            end
        end
    end
    return text:lower():find("sintoniza") ~= nil
end

------------------------------------------------------------
-- Carga
------------------------------------------------------------

-- Capacidad = Fuerza x 15 (libras).
function API.GetCapacity(profileName)
    local fuerza = 10
    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityScore then
        fuerza = tonumber(HarfordDnDCalc.GetAbilityScore("Fuerza")) or 10
    end
    return fuerza * API.CARRY_PER_STRENGTH
end

-- PESO: el cliente de WoW NO expone el peso de un objeto (en 5e es un dato de la ficha, no del
-- juego), asi que la carga solo puede calcularse con pesos DECLARADOS. Se leen de la tabla
-- `API.WEIGHTS`, que el DM o el registro de objetos pueden rellenar por itemId. Lo que no
-- tenga peso declarado cuenta 0: es preferible a inventar una cifra y que la carga mienta.
API.WEIGHTS = API.WEIGHTS or {}   -- [itemId] = libras

function API.SetWeight(itemId, pounds)
    itemId = tonumber(itemId)
    if not itemId then return false end
    API.WEIGHTS[itemId] = math.max(0, tonumber(pounds) or 0)
    return true
end

local function ItemIdFromLink(link)
    local id = tostring(link or ""):match("item:(%d+)")
    return tonumber(id)
end

function API.GetCarried(profileName)
    if not (HarfordDnDItems and HarfordDnDItems.GetEquipment) then return 0, 0 end
    local total, sinPeso = 0, 0
    for _, link in pairs(HarfordDnDItems.GetEquipment(profileName) or {}) do
        local id = ItemIdFromLink(link)
        local peso = id and API.WEIGHTS[id]
        if peso then total = total + peso else sinPeso = sinPeso + 1 end
    end
    -- Se devuelve tambien cuantos objetos no declaran peso, para que la UI pueda decir
    -- "12 kg (3 objetos sin peso declarado)" en vez de dar una cifra enganosa.
    return total, sinPeso
end

function API.GetStatus(profileName)
    local capacity = API.GetCapacity(profileName)
    local carried, unknown = API.GetCarried(profileName)
    return {
        carried = carried,
        capacity = capacity,
        unknownWeights = unknown,
        overloaded = carried > capacity,
        attuned = API.CountAttuned(profileName),
        maxAttuned = API.MAX_ATTUNED,
    }
end
