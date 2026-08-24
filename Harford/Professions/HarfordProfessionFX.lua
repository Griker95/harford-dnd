-- Presentacion de una fabricacion: animacion, sonido y lo que cada profesion quiera hacer.
--
-- Vive fuera de la ventana de recetas a proposito. `HarfordProfessionsCraftUI` es solo UI y no
-- debe saber que suena la alquimia ni que animacion usa el herrero; aqui se decide todo eso y
-- alli solo se avisa de en que punto va la fabricacion.
--
-- El ciclo tiene TRES fases, y cada profesion puede engancharse a las que necesite:
--   inicio  -> al empezar la barra          (animacion, aura, emote, arranque del sonido)
--   medio   -> una sola vez, a mitad        (para gestos intermedios)
--   final   -> al terminar, con exito o no  (cortar sonido, sonido de exito)
-- Ademas hay un `Stop` que cierra la tanda entera y devuelve al personaje a reposo.
--
-- Por ahora todas comparten la animacion de artesano. La idea es que cada profesion se vaya
-- llevando su bloque a `PERFILES` sin tocar la ventana: basta con darle `alInicio`/`alMedio`/
-- `alFinal` propios.

HarfordProfessionFX = HarfordProfessionFX or {}
local API = HarfordProfessionFX

-- `.mod anim 69` es la animacion de artesano; NO se corta sola, hay que devolver la 13 (reposo).
API.ANIM_ARTESANO, API.ANIM_REPOSO = 69, 13

-- COMO SUENA CONTINUO, y por que NO hay ningun temporizador aqui.
--
-- El juego base no resuelve esto en Lua: el sonido de fabricar forma parte de los datos del
-- hechizo -por eso los ids son los `precast` de cada oficio- y es el motor el que lo mantiene
-- sonando mientras dura el lanzamiento y lo corta al acabar o al interrumpir.
--
-- Desde Lua no hay modo bucle, pero si hay algo mejor que un reloj a ojo: `PlaySound` acepta un
-- cuarto argumento `avisarAlTerminar` y entonces el cliente dispara `SOUNDKIT_FINISHED` con el
-- manejador en cuanto ese sonido acaba. Encadenando ahi, el sonido se repite EXACTO: ni se
-- solapa ni deja silencio, y sin necesidad de saber cuanto dura ninguno. Comprobado en este
-- cliente: lo usan `SpellCreator/Actions/Data_Scripts.lua` y `Epsilon_Merchant/SoundPicker.lua`,
-- ambos con la firma `PlaySound(id, canal, sinDuplicados, avisarAlTerminar)`.
--
-- Ids (wowhead): alquimia 1105 trade-brew-potion, mineria 1166 tradeskill-smelt, desollar 3781
-- skinning, peleteria 6426 leatherworking, herboristeria 1104 gather-herb, sastreria 6425
-- tailoring, ingenieria 7141 engineering, inscripcion 6426 (comparte con peleteria),
-- encantamiento 27 precast-nature-low con remate 3084 conjure-item, joyeria 10589
-- precastjewelcrafting.
API.PERFILES = {
    alquimia      = { sonido = 1105 },
    mineria       = { sonido = 1166 },
    desollar      = { sonido = 3781 },
    peleteria     = { sonido = 6426 },
    herboristeria = { sonido = 1104 },
    sastreria     = { sonido = 6425 },
    ingenieria    = { sonido = 7141 },
    inscripcion   = { sonido = 6426 },
    joyeria       = { sonido = 10589 },
    -- El unico con remate: el de conjurar suena DESPUES de cortar el bucle, y solo si acerto.
    encantamiento = { sonido = 27, sonidoExito = 3084 },
}

local function Perfil(profId)
    return API.PERFILES[profId or ""] or {}
end

local function Anim(animId)
    if HarfordServerActions and HarfordServerActions.ModAnim then
        HarfordServerActions.ModAnim(animId, { addonName = "Harford", showMessages = false })
        return true
    end
    return false
end

-- Solo hay una fabricacion en vuelo a la vez, asi que basta con recordar cual esta sonando.
local enBucle = nil

-- El manejador es lo unico que permite cortar el sonido, y lo que identifica al NUESTRO cuando
-- llega el aviso de que ha terminado.
local function Suena(estado, soundId)
    if not (soundId and PlaySound) then return end
    local suena, manejador = PlaySound(soundId, "SFX", false, true)
    estado.manejador = suena and manejador or nil
    enBucle = estado.manejador and estado or nil
end

local function Calla(estado)
    if estado.manejador and StopSound then StopSound(estado.manejador) end
    estado.manejador = nil
    if enBucle == estado then enBucle = nil end
end

-- Un solo frame a la escucha, creado al cargar. No es un tick: solo reacciona al aviso.
local avisos = CreateFrame("Frame")
avisos:RegisterEvent("SOUNDKIT_FINISHED")
avisos:SetScript("OnEvent", function(_, _, manejador)
    manejador = tonumber(manejador)
    if not (manejador and enBucle and enBucle.manejador == manejador) then return end
    -- Se acabo el nuestro y la fabricacion sigue: se relanza pegado, sin hueco.
    Suena(enBucle, Perfil(enBucle.profId).sonido)
end)

-- ── Fases ────────────────────────────────────────────────────────────────────

-- Arranca una pieza. Se le pasa el estado de la anterior cuando se encadenan varias: la
-- animacion NO se relanza entre piezas, porque devolverla y volver a pedirla daba el parpadeo
-- 69-13-69 en cada unidad de la cola.
function API.Begin(profId, estado)
    estado = estado or { profId = profId }
    estado.profId = profId
    estado.transcurrido = 0
    estado.medioHecho = false

    local perfil = Perfil(profId)
    if not estado.animEnCurso then
        estado.animEnCurso = Anim(perfil.anim or API.ANIM_ARTESANO)
    end
    Suena(estado, perfil.sonido)
    if perfil.alInicio then perfil.alInicio(estado) end
    return estado
end

-- Se llama desde el OnUpdate que YA mueve la barra: no abre nada nuevo. Solo sirve para la fase
-- intermedia; el sonido no depende de esto, se encadena por evento.
function API.Tick(estado, dt, total)
    if not estado or estado.medioHecho then return end
    estado.transcurrido = estado.transcurrido + (dt or 0)
    if not (total and total > 0 and estado.transcurrido >= total / 2) then return end
    estado.medioHecho = true
    local perfil = Perfil(estado.profId)
    if perfil.alMedio then perfil.alMedio(estado) end
end

-- Corta el bucle YA. Se llama en el momento exacto en que para la barra -tanto al completarse
-- como al interrumpirse-, antes de resolver nada: el sonido no debe seguir mientras se tira el
-- dado ni mientras se descuentan materiales. Es idempotente.
function API.CutSound(estado)
    if estado then Calla(estado) end
end

-- Cierra la pieza. El bucle ya deberia estar cortado por `CutSound`; se vuelve a cortar por si
-- acaso. El de exito es el unico que puede seguir sonando despues.
function API.Finish(estado, exito)
    if not estado then return end
    Calla(estado)
    local perfil = Perfil(estado.profId)
    if exito and perfil.sonidoExito and PlaySound then
        PlaySound(perfil.sonidoExito, "SFX")
    end
    if perfil.alFinal then perfil.alFinal(estado, exito and true or false) end
end

-- Cierra la tanda: corta el sonido y devuelve el personaje a reposo. Devuelve nil para que quien
-- llama suelte el estado de una vez (`fx = HarfordProfessionFX.Stop(fx)`).
function API.Stop(estado)
    if not estado then return nil end
    Calla(estado)
    local perfil = Perfil(estado.profId)
    if estado.animEnCurso then
        estado.animEnCurso = false
        Anim(perfil.animReposo or API.ANIM_REPOSO)
    end
    if perfil.alSoltar then perfil.alSoltar(estado) end
    return nil
end
