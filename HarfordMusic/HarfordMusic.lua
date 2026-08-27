-- HarfordMusic: emisoras extra para la radio del Comunicador.
--
-- Es un addon APARTE a proposito. Un tema de tres minutos en OGG son varios megas, y quien no los
-- quiera no tiene por que llevarlos: sin este paquete la radio funciona igual, solo que con las
-- emisoras de casa. Es el mismo trato que dan DBM y BigWigs a sus paquetes de voz.
--
-- DOS TIPOS DE EMISORA, y no son intercambiables:
--
--   `soundId`  Pista que YA esta en el cliente (un FileDataID). **La oye cualquiera en Epsilon**
--              sin instalar nada y no pesa un byte. Los ids salen de LibRPMedia, que trae TRP3:
--              `LibStub:GetLibrary("LibRPMedia-1.0"):GetMusicFileByName("nombre")`.
--
--   `file`     Fichero OGG dentro de este addon. **Solo lo oye quien tenga el paquete.** Es la
--              unica via para musica que Epsilon no tenga, y el precio es el peso y que hay que
--              repartirlo a mano.
--
-- OJO CON LOS FICHEROS: WoW indexa el audio de los addons AL ARRANCAR. Un fichero nuevo NO suena
-- hasta que cierras y abres el cliente entero -- un `/reload` no basta, y el sintoma es silencio,
-- que se confunde con "no funciona".

local ESTACIONES = {
    -- Pistas del cliente: se pueden anadir sin descargar nada y las oye toda la mesa.
    -- (Ejemplos; cambia los ids por los que quieras usar.)
    -- { name = "Taberna de Refugio", soundId = 53209 },

    -- Ficheros propios: pon el .ogg en `Media\` y apunta aqui su ruta.
    -- { name = "Tema de la Compania", file = "Interface\\AddOns\\HarfordMusic\\Media\\compania.ogg" },
}

local function Registrar()
    if not (HarfordCommunicator and HarfordCommunicator.RegisterRadioStations) then return end
    if #ESTACIONES == 0 then return end
    HarfordCommunicator.RegisterRadioStations(ESTACIONES)
end

-- Se registra al cargar Y en `PLAYER_LOGIN`: `RequiredDeps` garantiza que Harford esta cargado,
-- pero no que el Comunicador haya llegado a definir su tabla. Registrar dos veces no duplica
-- porque la segunda no hace nada si la primera funciono.
local yaRegistrado = false
local function Intentar()
    if yaRegistrado then return end
    if HarfordCommunicator and HarfordCommunicator.RegisterRadioStations then
        Registrar()
        yaRegistrado = true
    end
end

Intentar()
if not yaRegistrado then
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_LOGIN")
    ev:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        Intentar()
    end)
end

-- Para que otro pueda anadir emisoras sin tocar este fichero.
HarfordMusic = HarfordMusic or {}
HarfordMusic.ESTACIONES = ESTACIONES
HarfordMusic.Registrar = Registrar
