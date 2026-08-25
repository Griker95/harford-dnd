-- HarfordDnDArea: la geometria de las areas y sus UNIDADES.
--
-- Aqui ya hubo un fallo real de reglas: el tamano del area se compara contra posiciones del cliente,
-- que vienen en YARDAS, mientras que el area se escribe en metros -- o en pies cuando el conjuro lo
-- dice, porque el compendio conserva la unidad de su manual. Sin convertir, un "radio 9 m" cubria
-- 8,2 m (un 9% corto en TODAS las areas) y un "cono de 30 pies" se leia como 30 yardas, casi cuatro
-- veces su tamano.
--
-- Se extrae el bloque de geometria del modulo y se ejecuta: son funciones locales, y esto prueba las
-- de verdad en vez de una copia.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
local function casi(etiqueta, real, esp, tolerancia)
    local ok = math.abs((tonumber(real) or 0) - esp) <= (tolerancia or 0.01)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, string.format("%.3f", tonumber(real) or 0),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local src = io.open("Harford/DnD/Engine/HarfordDnDArea.lua"):read("*a")
local ini = assert(src:find("local function PositionDistance2DSq", 1, true))
-- Hasta el final de `IsPositionAffected`, que es el que decide si te toca.
local tope = assert(src:find("local function NormalizeConditionMetadata", ini, true))
local cuerpo = src:sub(ini, tope - 1)

local env = {
    math = math, tostring = tostring, tonumber = tonumber, ipairs = ipairs, pairs = pairs,
    string = string, table = table, type = type,
    DEFAULT_MAX_Z = 5, DEFAULT_CONE_ANGLE = 90, DEFAULT_LINE_WIDTH = 5,
    HarfordClassColors = { StripAccents = function(v) return v end },
}
local cargar = loadstring or load
local codigo = cuerpo .. "\nreturn AreaGeometry, IsPositionAffected, ParseAreaNumbers"
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Geometria, Afecta, Numeros = f()

-- ─── Leer los numeros del texto ─────────────────────────────────────────────
print("Los numeros salen del texto del conjuro")
chk("uno", Numeros("radio de 9 metros")[1], 9)
chk("dos", Numeros("linea de 30 x 1,5 metros")[2], 1.5)
chk("la coma decimal vale como el punto", Numeros("1,5 m")[1], 1.5)
chk("sin numeros, ninguno", #Numeros("a tu alrededor"), 0)

-- ─── METROS a yardas ────────────────────────────────────────────────────────
-- Una yarda son 0,9144 m, asi que 9 m son 9,84 yardas. Sin convertir se cubriria un 9% menos.
print("El area se escribe en metros y el mundo mide en yardas")
casi("radio de 9 m", Geometria({ shape = "sphere", sizeText = "radio de 9 metros" }).radius, 9.843)
casi("cubo de 6 m", Geometria({ shape = "square", sizeText = "cubo de 6 metros" }).size, 6.562)
casi("linea de 30 m", Geometria({ shape = "line", sizeText = "linea de 30 x 1,5 metros" }).length, 32.808)
casi("y su anchura", Geometria({ shape = "line", sizeText = "linea de 30 x 1,5 metros" }).width, 1.640)

-- ─── PIES a yardas ──────────────────────────────────────────────────────────
-- Tres pies son una yarda. Un cono de 30 pies son 10 yardas, no 30.
print("Cuando el conjuro habla en pies, se lee en pies")
casi("cono de 30 pies", Geometria({ shape = "cone", sizeText = "cono de 30 pies" }).range, 10)
casi("radio de 20 pies", Geometria({ shape = "sphere", sizeText = "radio de 20 pies" }).radius, 6.667)
casi("abreviado ft", Geometria({ shape = "cone", sizeText = "30 ft cone" }).range, 10)
-- "piesoso" no es "pies": la palabra tiene que estar entera, o cualquier texto con esas letras
-- cambiaria la unidad sin querer.
casi("una palabra que solo contiene 'pies' no cuenta",
    Geometria({ shape = "sphere", sizeText = "radio de 9 metros sobre sus pieles" }).radius, 9.843)

-- ─── Los grados de un cono NO son una distancia ─────────────────────────────
-- Convertir el segundo numero abriria o cerraria el cono sin motivo.
print("El angulo de un cono no se convierte")
chk("60 grados siguen siendo 60",
    Geometria({ shape = "cone", sizeText = "cono de 9 metros, 60 grados" }).angle, 60)
chk("sin angulo, el de por defecto",
    Geometria({ shape = "cone", sizeText = "cono de 9 metros" }).angle, 90)

-- ─── A quien alcanza ────────────────────────────────────────────────────────
local origen = { x = 0, y = 0, z = 0 }
local function en(x, y, z) return { x = x, y = y, z = z or 0 } end

print("Circulo: dentro del radio")
local circulo = { shape = "circle", radius = 10, maxZ = 5 }
chk("en el centro", Afecta(circulo, en(0, 0), origen), true)
chk("dentro", Afecta(circulo, en(6, 6), origen), true)
chk("justo en el borde", Afecta(circulo, en(10, 0), origen), true)
chk("un paso fuera", Afecta(circulo, en(10.1, 0), origen), false)
chk("lejos", Afecta(circulo, en(50, 0), origen), false)

-- La altura importa: un area en el suelo no alcanza al que esta en una torre.
print("La altura corta el area")
chk("a la misma altura", Afecta(circulo, en(1, 1, 0), origen), true)
chk("cinco metros arriba, aun", Afecta(circulo, en(1, 1, 5), origen), true)
chk("seis, ya no", Afecta(circulo, en(1, 1, 6), origen), false)

-- Y el contexto: dos criaturas en instancias distintas no se alcanzan aunque coincidan las
-- coordenadas, que es exactamente lo que pasa entre fases.
print("Dos contextos distintos no se alcanzan")
local aqui = { x = 0, y = 0, z = 0, contextId = "fase1" }
chk("mismo contexto", Afecta(circulo, { x = 1, y = 1, contextId = "fase1" }, aqui), true)
chk("contexto distinto", Afecta(circulo, { x = 1, y = 1, contextId = "fase2" }, aqui), false)
chk("sin contexto declarado, se asume el mismo",
    Afecta(circulo, { x = 1, y = 1 }, aqui), true)

print("Cono: hacia donde apuntas")
local cono = { shape = "cone", range = 10, angle = 90, maxZ = 5 }
local mirandoAlNorte = { x = 0, y = 10 }
chk("justo delante", Afecta(cono, en(0, 5), origen, mirandoAlNorte), true)
chk("al borde del angulo", Afecta(cono, en(3, 3), origen, mirandoAlNorte), true)
chk("a un lado, fuera", Afecta(cono, en(5, 0.1), origen, mirandoAlNorte), false)
chk("detras, nunca", Afecta(cono, en(0, -5), origen, mirandoAlNorte), false)
chk("delante pero lejos", Afecta(cono, en(0, 11), origen, mirandoAlNorte), false)
chk("en el origen mismo", Afecta(cono, en(0, 0), origen, mirandoAlNorte), true)
-- Sin direccion no hay cono: no se puede adivinar hacia donde apunta.
chk("sin direccion, no alcanza", Afecta(cono, en(0, 5), origen, nil), false)

print("Linea: larga y estrecha")
local linea = { shape = "line", length = 20, width = 4, maxZ = 5 }
chk("en el eje", Afecta(linea, en(0, 10), origen, mirandoAlNorte), true)
chk("dentro del ancho", Afecta(linea, en(1.9, 10), origen, mirandoAlNorte), true)
chk("fuera del ancho", Afecta(linea, en(2.1, 10), origen, mirandoAlNorte), false)
chk("mas alla del largo", Afecta(linea, en(0, 21), origen, mirandoAlNorte), false)
-- Una linea sale HACIA DELANTE: no se extiende a la espalda del que la lanza.
chk("hacia atras no", Afecta(linea, en(0, -5), origen, mirandoAlNorte), false)

print("Cuadrado: centrado, no desde una esquina")
local cuadrado = { shape = "square", size = 10, maxZ = 5 }
chk("en el centro", Afecta(cuadrado, en(0, 0), origen), true)
chk("a media anchura", Afecta(cuadrado, en(5, 5), origen), true)
chk("un paso fuera", Afecta(cuadrado, en(5.1, 0), origen), false)
-- Un cuadrado alcanza la esquina, donde un circulo del mismo tamano ya no llega.
chk("la esquina si entra", Afecta(cuadrado, en(4.9, 4.9), origen), true)

-- ─── Un area de tamano cero no alcanza a nadie ──────────────────────────────
-- Un texto sin numeros no puede convertirse en "toca a todo el mundo".
print("Sin tamano no se alcanza a nadie")
chk("circulo de radio 0", Afecta({ shape = "circle", radius = 0, maxZ = 5 }, en(0, 0), origen), false)
chk("cono de alcance 0",
    Afecta({ shape = "cone", range = 0, angle = 90, maxZ = 5 }, en(0, 1), origen, mirandoAlNorte), false)
chk("y una forma desconocida tampoco", Afecta(nil, en(0, 0), origen), false)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
