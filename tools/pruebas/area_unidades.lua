-- UNIDADES del motor de areas.
--
-- Las posiciones del cliente vienen en YARDAS (`C_Epsilon.GetPosition`, igual que `UnitPosition`,
-- que en el resto del addon se convierte con *0.9144). El tamano del area se escribe en METROS, o
-- en PIES cuando el texto lo dice porque el conjuro conserva la unidad de su manual.
--
-- Sin convertir pasaban dos cosas, y ninguna daba error: toda area quedaba un 9% corta, y una
-- escrita en pies se leia como si fueran metros -- un cono de 30 pies pasaba a 30, casi cuatro
-- veces su tamano.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDArea.lua"):read("*a")
local i = assert(src:find("local YARDAS_POR_METRO", 1, true))
local j = assert(src:find("\nlocal function IsInCircle", i, true))
local codigo = "local ParseAreaNumbers, DEFAULT_CONE_ANGLE, DEFAULT_LINE_WIDTH, DEFAULT_MAX_Z = ...\n"
    .. src:sub(i, j) .. "\nreturn AreaGeometry, FactorAYardas"

-- El mismo parser de numeros del modulo, extraido aparte.
local k = assert(src:find("local function ParseAreaNumbers", 1, true))
local k2 = assert(src:find("\nlocal function AreaGeometry", k, true))
local pcodigo = "local HarfordClassColors = ...\n" .. src:sub(k, k2) .. "\nreturn ParseAreaNumbers"

local HCC = { StripAccents = function(s) return s end }
local env = { tostring = tostring, tonumber = tonumber, HarfordClassColors = HCC, ipairs = ipairs }
local function enEntorno(fuente)
    local fn
    if setfenv then fn = assert(cargar(fuente)); setfenv(fn, env)
    else fn = assert(cargar(fuente, "t", "t", env)) end
    return fn
end
local Parse = enEntorno(pcodigo)(HCC)
local Geometry = enEntorno(codigo)(Parse, 90, 5, 5)

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = math.abs((tonumber(real) or -1) - esp) < 0.01
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-46s %-10s %s", etiqueta, string.format("%.2f", tonumber(real) or 0),
        ok and "ok" or ("FALLA, esperaba " .. string.format("%.2f", esp))))
end

local M = 1 / 0.9144   -- yardas por metro

print("Metros -> yardas (la unidad de las posiciones)")
chk("radio 9 m", Geometry({ shape = "sphere", sizeText = "9 m de radio" }).radius, 9 * M)
chk("radio 6 m", Geometry({ shape = "sphere", sizeText = "6 m de radio" }).radius, 6 * M)
chk("cono 4,6 m (coma decimal)", Geometry({ shape = "cone", sizeText = "4,6 m" }).range, 4.6 * M)
chk("sin unidad: se asume metros", Geometry({ shape = "sphere", sizeText = "9" }).radius, 9 * M)

print("Pies -> yardas (3 pies = 1 yarda)")
chk("cono de 30 pies", Geometry({ shape = "cone", sizeText = "30 pies" }).range, 10)
chk("radio de 15 pies", Geometry({ shape = "sphere", sizeText = "15 pies" }).radius, 5)
chk("abreviado ft", Geometry({ shape = "sphere", sizeText = "60 ft" }).radius, 20)
chk("singular pie", Geometry({ shape = "sphere", sizeText = "3 pie" }).radius, 1)

print("El angulo del cono son GRADOS: no se convierte")
chk("cono 9 m 60 grados", Geometry({ shape = "cone", sizeText = "9 m 60" }).angle, 60)
chk("sin angulo declarado", Geometry({ shape = "cone", sizeText = "9 m" }).angle, 90)

print("Linea y rectangulo: las dos medidas son distancias")
local linea = Geometry({ shape = "line", sizeText = "18 m 1,5 m" })
chk("largo", linea.length, 18 * M)
chk("ancho", linea.width, 1.5 * M)
local rect = Geometry({ shape = "rectangle", sizeText = "12 m 6 m" })
chk("largo", rect.length, 12 * M)
chk("ancho", rect.width, 6 * M)
local cuadrado = Geometry({ shape = "square", sizeText = "6 m" })
chk("cuadrado", cuadrado.size, 6 * M)

print("Sin numero no hay area")
chk("solo texto", Geometry({ shape = "sphere", sizeText = "Objetivo" }).radius, 0)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
