-- La radio del Comunicador y el paquete de musica opcional.
--
-- Lo critico: la radio tiene que funcionar SIN el paquete. Es un addon aparte porque un tema en
-- OGG son varios megas y quien no los quiera no tiene por que llevarlos; si el core dependiera de
-- el, esa decision dejaria de ser opcional.
local com = io.open("Harford/Communicator/HarfordCommunicator.lua"):read("*a")
local mus = io.open("HarfordMusic/HarfordMusic.lua"):read("*a")
local toc = io.open("HarfordMusic/HarfordMusic.toc"):read("*a")

local fallos = 0
local function chk(nombre, real, esperado)
    local ok = tostring(real) == tostring(esperado)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-6s %s", nombre, tostring(real), ok and "ok" or "FALLA"))
end

print("Las emisoras se pueden ampliar desde fuera")
chk("hay puerta de registro",
    com:find("function HarfordCommunicator.RegisterRadioStations(lista)", 1, true) ~= nil, true)
-- Se ACUMULA en vez de sustituir: asi pueden sumarse varios paquetes, y el de casa no se pierde.
chk("y acumula, no sustituye",
    com:find("RADIO_EXTRA[#RADIO_EXTRA + 1] = {", 1, true) ~= nil, true)
-- Lo que no traiga ni id ni fichero no se apunta: no sonaria, y una emisora muda es peor que no
-- tenerla porque parece una averia.
chk("y descarta lo que no puede sonar",
    com:find("if type(e) == \"table\" and e.name and (e.soundId or e.file) then", 1, true) ~= nil, true)
-- Las de casa van primero y no dependen de nadie.
chk("las de casa siguen sin depender del paquete",
    com:find("local function TodasLasEmisoras()", 1, true) ~= nil, true)

print("Dos tipos de emisora, por caminos distintos")
-- `soundId` es una pista del cliente: la oye cualquiera en Epsilon. `file` es del paquete: solo la
-- oye quien lo tenga. Confundirlos es prometer a la mesa algo que la mitad no va a escuchar.
chk("el fichero suena por PlaySoundFile",
    com:find('pcall(PlaySoundFile, station.file, "Music")', 1, true) ~= nil, true)
-- Canal `Music` a proposito: respeta el volumen de musica del juego.
chk("en el canal de musica", com:find('station.file, "Music"', 1, true) ~= nil, true)
chk("y la pista del cliente por TRP3",
    com:find("music.playLocalMusic(station.soundId, 25)", 1, true) ~= nil, true)
-- `PlaySoundFile` devuelve un manejador y es la UNICA forma de cortar lo que esta sonando.
chk("se guarda el manejador para poder parar",
    com:find("radioHandle = handle", 1, true) ~= nil, true)
chk("y apagar corta las dos vias",
    com:find("local function StopRadio()", 1, true) ~= nil, true)

print("Un fichero que no suena se DICE")
-- Silencio y ya seria indistinguible de "no ha sonado". Y la causa mas comun no es que falte el
-- fichero: WoW indexa el audio de los addons AL ARRANCAR, asi que uno nuevo no suena hasta
-- reiniciar el cliente entero -- un /reload no basta.
chk("se avisa si no sono", com:find("if not (ok and sono) then", 1, true) ~= nil, true)
chk("y se explica lo del reinicio",
    com:find("un /reload no basta", 1, true) ~= nil, true)

print("Los ficheros de audio llegan al juego")
-- El despliegue solo copiaba .lua/.toc/.xml, asi que los OGG se quedaban en el repo: en juego cada
-- emisora avisaba de que no suena. La funcion entera rota, y con un sintoma que apunta a otro
-- sitio (parecia que faltaba el fichero, y faltaba el COPIADO).
local desp = io.open("tools/desplegar.py"):read("*a")
chk("el despliegue copia los .ogg", desp:find(".ogg", 1, true) ~= nil, true)
-- Y la carpeta tiene que existir tras un clon: git no guarda carpetas vacias.
local marca = io.open("HarfordMusic/Media/.gitkeep")
chk("la carpeta Media sobrevive a un clon", marca ~= nil, true)
if marca then marca:close() end

print("El paquete es opcional de verdad")
chk("depende de Harford", toc:find("## RequiredDeps: Harford", 1, true) ~= nil, true)
-- Al reves NO: el core no puede DEPENDER de el, o dejaria de ser opcional. Nombrarlo en un
-- comentario si vale --explica el contrato-- pero mirarlo en el codigo no.
chk("y el core no depende de el",
    com:find("IsAddOnLoaded(\"HarfordMusic\")", 1, true) == nil
    and com:find("_G.HarfordMusic", 1, true) == nil
    and com:find("HarfordMusic.", 1, true) == nil, true)
-- `RequiredDeps` garantiza que Harford esta cargado, pero no que el Comunicador haya definido su
-- tabla: hay que reintentar en PLAYER_LOGIN.
chk("se registra aunque llegue antes que el Comunicador",
    mus:find('ev:RegisterEvent("PLAYER_LOGIN")', 1, true) ~= nil, true)
chk("y no se registra dos veces", mus:find("if yaRegistrado then return end", 1, true) ~= nil, true)

print("La lista de botones se repuebla y se reutiliza")
-- El paquete puede cargar DESPUES de que la ventana exista, asi que la lista no puede montarse una
-- sola vez. Y los botones se reutilizan, que es la regla de las listas del proyecto.
chk("hay repoblado", com:find("HarfordCommunicator._RefreshRadio = function()", 1, true) ~= nil, true)
chk("con pool de botones", com:find("frame.radio.botones[i] = button", 1, true) ~= nil, true)
chk("y el registro lo dispara",
    com:find("if HarfordCommunicator._RefreshRadio then HarfordCommunicator._RefreshRadio() end",
        1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
if fallos > 0 then os.exit(1) end
