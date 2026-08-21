------------------------------------------------------------
-- HarfordDnDHeroPoints - Puntos de heroe (regla opcional de la Guia del Dungeon Master).
--
-- Regla literal del manual:
--   * Cada personaje empieza con 5 puntos a nivel 1. Al subir de nivel PIERDE los no gastados
--     y recibe un total nuevo: 5 + la mitad del nivel del personaje.
--   * Se gasta 1 punto en una tirada de ataque, prueba de caracteristica o salvacion. Se
--     decide DESPUES de tirar pero ANTES de aplicar los efectos: se tira 1d6 y se suma al d20.
--     Solo 1 punto por tirada.
--   * Ademas, al fallar una salvacion contra muerte se puede gastar 1 punto para convertir
--     el fallo en exito.
--
-- Por que "despues de tirar": es lo que hace util el sistema, y encaja con `_lastRoll` que ya
-- guarda la ultima tirada. La ventana de gasto se cierra en cuanto se hace otra tirada.
--
-- Persistencia: en la progresion del perfil (`heroPoints`), junto al nivel que la determina.
------------------------------------------------------------

HarfordDnDHeroPoints = HarfordDnDHeroPoints or {}
local API = HarfordDnDHeroPoints

local function Print(text)
    if HarfordChat and HarfordChat.Print then HarfordChat.Print(text) end
end

local function ProfileName(profileName)
    if profileName and profileName ~= "" then return profileName end
    -- `HarfordDnDAPI.GetProfileName` no existe: `activeProfile` quedo obsoleto y el perfil es
    -- SIEMPRE el personaje actual. La llamada guardada solo hacia creer que habia otra via.
    return (UnitName and UnitName("player")) or "player"
end

local function Progression(profileName)
    -- `Get` devuelve la tabla de progresion del perfil (o el snapshot de inspeccion, que es de
    -- solo lectura: por eso los cambios se hacen siempre sobre el perfil propio).
    if not (HarfordDnDProgression and HarfordDnDProgression.Get) then return nil end
    return (HarfordDnDProgression.Get(ProfileName(profileName)))
end

-- Nivel total del personaje (suma de clases). Sin progresion, nivel 1.
local function CharacterLevel(profileName)
    if HarfordDnDProgression and HarfordDnDProgression.GetTotalLevel then
        local level = tonumber(HarfordDnDProgression.GetTotalLevel(ProfileName(profileName)))
        if level and level > 0 then return level end
    end
    return 1
end

-- Total del manual: 5 + la mitad del nivel.
function API.GetMax(profileName)
    return 5 + math.floor(CharacterLevel(profileName) / 2)
end

function API.Get(profileName)
    local prog = Progression(profileName)
    local stored = prog and tonumber(prog.heroPoints)
    if stored == nil then return API.GetMax(profileName) end
    return math.max(0, math.min(API.GetMax(profileName), stored))
end

function API.Set(profileName, value)
    local prog = Progression(profileName)
    if not prog then return false end
    prog.heroPoints = math.max(0, math.min(API.GetMax(profileName), math.floor(tonumber(value) or 0)))
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

-- Al subir de nivel se PIERDEN los no gastados y se recibe el total nuevo. Lo llama la
-- progresion; no se recalcula solo, porque perder puntos sin avisar seria confuso.
function API.OnLevelUp(profileName)
    local nuevo = API.GetMax(profileName)
    API.Set(profileName, nuevo)
    Print(string.format("Puntos de heroe restablecidos a |cffffd100%d|r por la subida de nivel.", nuevo))
    return nuevo
end

------------------------------------------------------------
-- Gasto sobre la ultima tirada
------------------------------------------------------------

-- Tipos de tirada donde el manual permite gastar el punto.
local SPENDABLE = { roll = true, attack = true, save = true, ability = true, skill = true }

-- Devuelve la ultima tirada si todavia se puede mejorar, o nil con el motivo.
local function LastRoll()
    local api = _G.DND5E_ARC_API
    local last = api and api._lastRoll
    if type(last) ~= "table" then return nil, "No hay ninguna tirada reciente" end
    if last.heroPointSpent then return nil, "Ya gastaste un punto en esa tirada" end
    local kind = tostring(last.type or last.rollType or "roll"):lower()
    if not SPENDABLE[kind] then return nil, "En esa tirada no se puede gastar un punto" end
    return last
end

-- Gasta 1 punto: tira 1d6 y lo suma a la ultima tirada. Un punto por tirada.
function API.Spend(profileName)
    local disponibles = API.Get(profileName)
    if disponibles <= 0 then
        Print("|cffff5555No te quedan puntos de heroe.|r")
        return false, "sin puntos"
    end
    local last, err = LastRoll()
    if not last then
        Print("|cffff5555" .. tostring(err) .. ".|r")
        return false, err
    end

    local d6 = math.random(1, 6)
    local anterior = tonumber(last.total) or 0
    local nuevo = anterior + d6
    last.total = nuevo
    last.heroPointSpent = true

    API.Set(profileName, disponibles - 1)
    -- Se anuncia en mesa, como cualquier accion real: cambia el resultado de una tirada que
    -- los demas ya han visto.
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = "Punto de heroe" .. (last.label and (": " .. tostring(last.label)) or ""),
            total = nuevo,
            dice = string.format("%d + d6: %d", anterior, d6),
            modifiers = "",
        })
    end
    Print(string.format("Gastas un punto de heroe: |cffffd100%d|r + %d = |cff38d26a%d|r. Te quedan %d.",
        anterior, d6, nuevo, API.Get(profileName)))
    return true, nuevo
end

-- Convierte un fallo de salvacion contra muerte en exito. Lo llama la ficha cuando el jugador
-- lo pide tras fallar; aqui solo se cobra el punto y se anuncia.
function API.SpendOnDeathSave(profileName)
    local disponibles = API.Get(profileName)
    if disponibles <= 0 then
        Print("|cffff5555No te quedan puntos de heroe.|r")
        return false, "sin puntos"
    end
    API.Set(profileName, disponibles - 1)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "info",
            label = "gasta un punto de heroe y convierte el fallo de salvacion de muerte en exito.",
        })
    end
    Print(string.format("Punto de heroe gastado. Te quedan %d.", API.Get(profileName)))
    return true
end

-- Instantanea para la UI.
function API.GetStatus(profileName)
    return {
        current = API.Get(profileName),
        max = API.GetMax(profileName),
        level = CharacterLevel(profileName),
    }
end
