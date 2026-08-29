------------------------------------------------------------
-- HarfordDnDHeroPoints - Puntos de heroe segun el MANUAL WARCRAFT (capitulo propio), que
-- sustituye a la regla opcional de la DMG que este modulo implementaba antes (5 + nivel/2 con
-- +1d6 a la tirada). La regla de la casa es otra:
--   * Tienes UN punto de heroe o no tienes ninguno. No se acumulan.
--   * NO se recibe por defecto ni al subir de nivel: lo CONCEDE el DM por actos valientes
--     contra enemigos poderosos. Es algo especial.
--   * Gastarlo hace la prueba un EXITO INMEDIATO, con seis usos declarados (Impulso de Accion,
--     Luchador Fisico, Luchador Magico, Defensa, Sobreviviente, Experto Innato). El detalle de
--     cada uso se resuelve en mesa; el gasto se ANUNCIA con su uso elegido, vinculante.
--   * No se gana un punto con una accion en la que se gasto uno.
--
-- Persistencia: en la progresion del perfil (`heroPoints`).
------------------------------------------------------------

HarfordDnDHeroPoints = HarfordDnDHeroPoints or {}
local API = HarfordDnDHeroPoints

local function Print(text)
    if HarfordChat and HarfordChat.Print then HarfordChat.Print(text) end
end

-- Descripcion del PUNTO en si, para el tooltip de su enlace. La regla completa vive aqui y no
-- en la linea de chat: la linea son solo los dos enlaces, como cualquier habilidad del Libro.
local REGLA_PUNTO = "Un punto de heroe o ninguno: no se acumulan. Lo concede el DM por actos "
    .. "valientes contra enemigos poderosos. Gastarlo convierte la prueba en un EXITO INMEDIATO "
    .. "con uno de sus usos declarados; no se gana un punto con la accion en la que se gasto uno."

-- Enlace clicable de "habilidad" (hyperlink totalrp3 de TRP3, el mismo de las tiradas del
-- Libro). Sin TRP3 cae a texto coloreado no clicable; nunca lanza error.
local function Enlace(nombre, descripcion)
    if HarfordTRP3 and HarfordTRP3.GetAbilityChatLink then
        return HarfordTRP3.GetAbilityChatLink({
            id = "hero_" .. tostring(nombre):lower():gsub("%W", "_"),
            name = nombre,
            icon = "achievement_legionpvptier4",
            description = descripcion,
        })
    end
    return "|cff66bbff[" .. tostring(nombre) .. "]|r"
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

-- El manual Warcraft: un punto o ninguno.
function API.GetMax(profileName)
    return 1
end

function API.Get(profileName)
    local prog = Progression(profileName)
    local stored = prog and tonumber(prog.heroPoints)
    -- Sin dato NO hay punto: se empieza a cero y solo el DM lo concede.
    if stored == nil then return 0 end
    return math.max(0, math.min(API.GetMax(profileName), stored))
end

function API.Set(profileName, value)
    local prog = Progression(profileName)
    if not prog then return false end
    prog.heroPoints = math.max(0, math.min(API.GetMax(profileName), math.floor(tonumber(value) or 0)))
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

-- Subir de nivel NO da puntos de heroe: se ganan por actos heroicos, no por experiencia.
-- La progresion sigue llamando aqui por compatibilidad; el punto (si lo hay) se conserva.
function API.OnLevelUp(profileName)
    return API.Get(profileName)
end

-- El DM te lo concede (por chat/mesa) y lo registras aqui: se anuncia a la mesa para que quede
-- constancia. Si ya lo tienes, no se acumula.
function API.Grant(profileName)
    if API.Get(profileName) >= API.GetMax(profileName) then
        Print("Ya tienes tu punto de heroe: no se acumulan.")
        return false
    end
    API.Set(profileName, 1)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info", label = "recibe " .. Enlace("Punto de Heroe", REGLA_PUNTO) })
    end
    return true
end

------------------------------------------------------------
-- Gasto: los seis usos del manual. Cada uno se ANUNCIA con su efecto vinculante; el detalle
-- fino (miembro cortado, dano x10) se resuelve en mesa con la linea ya publicada.
------------------------------------------------------------

-- `anuncio` es la descripcion VINCULANTE del uso: ya no sale en la linea de chat (que son solo
-- los dos enlaces, como pidio la mesa) sino en el tooltip del enlace del uso, donde cualquiera
-- puede leerla con un click. `mecanica` es lo que el cliente automatiza al gastar, si hay algo
-- que automatizar; el resto se resuelve en mesa con la linea publicada.
API.USOS = {
    { id = "impulso", label = "Impulso de Accion",
      anuncio = "Toma su proximo turno fuera del orden de iniciativa." },
    { id = "fisico_poderoso", label = "Luchador Fisico: Golpe Poderoso",
      anuncio = "Su proximo ataque de arma impacta automaticamente como Golpe Critico Masivo: dados de dano x10, mas modificadores, mas su nivel de personaje." },
    { id = "fisico_mutilar", label = "Luchador Fisico: Mutilar",
      anuncio = "Su proximo ataque de arma impacta automaticamente y MUTILA: dano normal, y la criatura supera una salvacion de Constitucion CD 10 o mitad del dano (la mayor) o pierde el miembro elegido." },
    { id = "magico_sobrecarga", label = "Luchador Magico: Sobrecarga",
      anuncio = "Su proximo hechizo impacta automaticamente como Golpe Critico Masivo: dados de dano x10 mas su nivel de personaje." },
    { id = "magico_preciso", label = "Luchador Magico: Hechizo Preciso",
      anuncio = "Su hechizo impacta, y tantas criaturas como su modificador de lanzamiento fallan automaticamente la salvacion." },
    { id = "defensa_esquiva", label = "Defensa: Esquiva",
      anuncio = "El ataque que le apunta FALLA automaticamente." },
    { id = "defensa_resistente", label = "Defensa: Resistente",
      anuncio = "Exito en su salvacion, con evasion de picaro hasta el final del turno actual." },
    { id = "sobreviviente", label = "Sobreviviente",
      anuncio = "Sobrevive con su salud a 0, estabilizado: sus salvaciones de muerte se reinician." },
    { id = "experto", label = "Experto Innato",
      anuncio = "Su prueba de habilidad cuenta como 20 natural (no vale para Inteligencia, Sabiduria ni Carisma)." },
}

-- Mecanizacion por uso: marcas de un solo consumo en HarfordDnDStore que los motores ya
-- existentes recogen. Golpe Poderoso/Mutilar las consume el proximo Ataque/Daño de arma
-- (DoWeaponAttack + RollWeaponDamage); Sobrecarga, el proximo lanzamiento del Compendio
-- (BuildAreaDefinition, con el mismo patron mirar-sin-gastar de la carga arcana);
-- Sobreviviente reinicia las salvaciones de muerte en el acto.
local MECANICA = {
    fisico_poderoso = function()
        HarfordDnDStore.pendingHeroAutoHit = true
        HarfordDnDStore.pendingHeroMassiveDamage = true
    end,
    fisico_mutilar = function()
        HarfordDnDStore.pendingHeroAutoHit = true
        HarfordDnDStore.pendingHeroMutilate = true
    end,
    magico_sobrecarga = function()
        HarfordDnDStore.pendingHeroSpellOverload = true
    end,
    sobreviviente = function()
        HarfordDnDStore.deathSaveSuccesses = 0
        HarfordDnDStore.deathSaveFailures  = 0
        if HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    end,
}

-- Cobra el punto y publica el uso elegido como DOS enlaces clicables:
-- `Nombre [Punto de Heroe][<Uso>]`. El detalle vinculante va en el tooltip de cada enlace.
function API.SpendUse(usoId, profileName)
    local disponibles = API.Get(profileName)
    if disponibles <= 0 then
        Print("|cffff5555No tienes punto de heroe.|r")
        return false, "sin punto"
    end
    local uso
    for _, u in ipairs(API.USOS) do if u.id == usoId then uso = u break end end
    if not uso then return false, "uso desconocido" end
    API.Set(profileName, 0)
    if HarfordDnDStore and MECANICA[uso.id] then MECANICA[uso.id]() end
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "info",
            label = Enlace("Punto de Heroe", REGLA_PUNTO) .. Enlace(uso.label, uso.anuncio),
        })
    end
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
