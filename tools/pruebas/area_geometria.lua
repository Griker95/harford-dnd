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
local codigo = cuerpo .. "\nreturn AreaGeometry, IsPositionAffected, ParseAreaNumbers, AreaDistanceInfo, AreaDistanceText, AreaCenter, AreaCenterFallsBack"
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local Geometria, Afecta, Numeros, Distancia, TextoDistancia, Centro, CaeEnMi = f()

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

-- ─── La distancia que se ensena ─────────────────────────────────────────────
-- Saber quien entra no basta: lo que se discute en mesa es por que uno entro y otro no, y por
-- cuanto. Cada figura se mide desde SU referencia, que no es la misma en todas.
print("Cada figura se mide desde su referencia")
local _, _, ref = Distancia({ shape = "circle", radius = 10 }, en(3, 0), origen)
chk("la esfera, desde el centro", ref, "centro")
_, _, ref = Distancia({ shape = "square", size = 10 }, en(3, 0), origen)
chk("el cubo, desde el centro", ref, "centro")
_, _, ref = Distancia({ shape = "cone", range = 10 }, en(3, 0), origen)
chk("el cono, desde el origen", ref, "origen")
_, _, ref = Distancia({ shape = "line", length = 20, width = 4 }, en(3, 0), origen)
chk("la linea, desde el origen", ref, "origen")

-- Se ensena en METROS, que es como se escriben las areas, aunque por dentro todo son yardas.
print("Se ensena en metros, aunque por dentro sean yardas")
local d, limite = Distancia({ shape = "circle", radius = 10.936 }, en(10.936, 0), origen)
casi("diez yardas son 10 metros", d, 10)
casi("y el limite tambien se convierte", limite, 10)

-- En un cubo el limite es la MITAD del lado: un cubo de 10 alcanza 5 desde el centro.
print("En un cubo el limite es media anchura")
_, limite = Distancia({ shape = "square", size = 10.936 }, en(0, 0), origen)
casi("un cubo de 10 m alcanza 5", limite, 5)

-- En una linea lo que cuenta es lo que AVANZA por el eje, no la distancia directa: alguien muy a un
-- lado puede estar cerca de ti y quedar fuera igualmente por anchura.
print("En una linea se mide lo que avanza por el eje")
local haciaElNorte = { x = 0, y = 10 }
d = Distancia({ shape = "line", length = 21.872, width = 4 }, en(0, 10.936), origen, haciaElNorte)
casi("justo en el eje", d, 10)
d = Distancia({ shape = "line", length = 21.872, width = 4 }, en(10.936, 10.936), origen, haciaElNorte)
casi("desplazado a un lado, avanza lo mismo", d, 10)
-- Hacia atras avanza en negativo, que es la senal de que esta a tu espalda.
d = Distancia({ shape = "line", length = 21.872, width = 4 }, en(0, -10.936), origen, haciaElNorte)
casi("a la espalda, negativo", d, -10)

print("El texto de la fila")
chk("con coma decimal, como se escribe en espanol",
    TextoDistancia({ shape = "circle", radius = 10.936 }, en(4.572, 0), origen), "4,2 / 10,0 m")
chk("una forma sin geometria no ensena nada",
    TextoDistancia({ shape = "other" }, en(1, 0), origen), "")

-- Los que quedan FUERA se ensenan, pero NUNCA entran en la lista que recibe el dano.
local area = io.open("Harford/DnD/Engine/HarfordDnDArea.lua"):read("*a")
print("Los que quedan fuera se ensenan, pero no reciben nada")
chk("se guardan aparte", area:find("session.outside = {}", 1, true) ~= nil, true)
chk("no en la lista de objetivos",
    area:find("session.outside[#session.outside + 1] = {", 1, true) ~= nil, true)
chk("se ordenan del mas cerca al mas lejos",
    area:find("table.sort(session.outside", 1, true) ~= nil, true)
chk("se pintan en gris", area:find('"|cff707070fuera  "', 1, true) ~= nil, true)
chk("y la distancia acompana al marcado",
    area:find('dist = "  |cff909090" .. texto', 1, true) ~= nil, true)

-- ─── DONDE SE CENTRA ────────────────────────────────────────────────────────
-- Una esfera o un cubo se centran en un punto ELEGIDO dentro del alcance; un cono o una linea salen
-- siempre de quien lanza. Centrarlo todo en el lanzador ponia la Bola de fuego en el sitio
-- contrario: marcaba a los companeros de al lado y no a los orcos del fondo.
print("Esfera y cubo se centran donde apuntas")
local puntoLejano = { x = 30, y = 0, z = 0 }
chk("la esfera, en el punto", Centro({ shape = "circle" }, origen, puntoLejano).x, 30)
chk("el cubo, tambien", Centro({ shape = "square" }, origen, puntoLejano).x, 30)

print("Cono y linea salen SIEMPRE de quien lanza")
chk("el cono, del origen", Centro({ shape = "cone" }, origen, puntoLejano).x, 0)
chk("la linea, del origen", Centro({ shape = "line" }, origen, puntoLejano).x, 0)
-- El rectangulo se usa para muros y va orientado desde el origen: moverle el centro lo desorienta.
chk("el rectangulo, del origen", Centro({ shape = "rectangle" }, origen, puntoLejano).x, 0)

print("Sin punto al que apuntar, se centra en uno mismo")
chk("la esfera cae al lanzador", Centro({ shape = "circle" }, origen, nil).x, 0)
chk("y se avisa de ello", CaeEnMi({ shape = "circle" }, nil), true)
chk("con punto, no hay que avisar", CaeEnMi({ shape = "circle" }, puntoLejano), false)
-- Un cono centrado en ti es lo normal, no una degradacion: no hay nada que avisar.
chk("un cono no avisa nunca", CaeEnMi({ shape = "cone" }, nil), false)

-- El caso real: Bola de fuego (esfera de 6 m) contra un grupo a 30 m.
print("Bola de fuego a 30 metros, con el caso real")
local bola = { shape = "circle", radius = 6.56, maxZ = 5 }   -- 6 m
local orco = { x = 30, y = 0, z = 0 }
local companero = { x = 2, y = 0, z = 0 }
local centro = Centro(bola, origen, orco)
chk("el orco entra", Afecta(bola, orco, centro), true)
chk("y el companero de al lado NO", Afecta(bola, companero, centro), false)
-- Antes, centrando en el lanzador, pasaba justo al reves.
chk("centrando en ti pasaba al reves: el orco fuera", Afecta(bola, orco, origen), false)
chk("y el companero dentro", Afecta(bola, companero, origen), true)

-- La distancia que se ensena tambien se mide desde el centro real, o no explicaria nada.
print("Y la distancia se mide desde ese centro")
local d = Distancia(bola, orco, origen, orco)
casi("el orco esta a cero del centro", d, 0)
d = Distancia(bola, companero, origen, orco)
casi("y el companero, a 25,6 m", d, 25.6, 0.2)

-- NO todos los conjuros llevan area: 69 de 381. Los de objetivo unico no tienen geometria, y sin
-- geometria no hay centro que mover. El cambio no puede alcanzarlos.
print("Un conjuro sin area no se ve afectado")
chk("sin geometria no hay centro", Centro(nil, origen, puntoLejano).x, 0)
chk("una forma desconocida se queda en el origen",
    Centro({ shape = "other" }, origen, puntoLejano).x, 0)
chk("y no avisa de nada", CaeEnMi({ shape = "other" }, nil), false)

-- ─── UN OBJETIVO UNICO NO SE ROTULA COMO AREA ───────────────────────────────
-- Muchos efectos de objetivo unico se enrutan por este motor para reusar su salvacion, su dano y
-- la mitigacion del receptor. Eso es util. Rotularlos "(Area Objetivo)" en el chat no: decir la
-- forma sirve cuando hay forma que decir, y "Objetivo" no lo es.
print("Un objetivo unico no se rotula como area")
local areaSrc = io.open("Harford/DnD/Engine/HarfordDnDArea.lua"):read("*a")
chk("se reconoce el objetivo unico",
    areaSrc:find("local function EsObjetivoUnico(def)", 1, true) ~= nil, true)
chk("y su rotulo se queda vacio",
    areaSrc:find('if EsObjetivoUnico(def) then return "" end', 1, true) ~= nil, true)
-- Y donde se pinta, un rotulo vacio no deja los parentesis colgando.
chk("sin parentesis vacios",
    areaSrc:find('and (" (" .. ShapeText(definition) .. ")") or ""', 1, true) ~= nil, true)
chk("ni guiones sueltos",
    areaSrc:find('((forma ~= "") and (forma .. " - ") or "")', 1, true) ~= nil, true)

-- El desenlace se publica primero SIEMPRE que hay desenlace: los dados de daño quedan para la
-- primera victima alcanzada, sea por impacto o por salvacion fallada (Explosion arcana los
-- sacaba ANTES de la salvacion). Solo la curacion, que no depende de ninguna tirada, se anuncia
-- al tirar. Y la linea de la victima no incrusta el daño en los modos de daño: la linea de
-- dados llega justo despues y salia duplicado (y teñido del rojo del FALLO).
chk("solo la curacion se anuncia al tirar",
    areaSrc:find('and session.definition.resolution == "heal" then', 1, true) ~= nil, true)
chk("el dano espera a una victima alcanzada",
    areaSrc:find('or (result.status == "saved" and (tonumber(result.applied) or 0) > 0)', 1, true) ~= nil, true)
-- Y el invariante vale tambien POR VICTIMA (multiimpactos): al tirar solo anuncian curacion y
-- auto-impactos, que no tienen tirada delante; ataque y salvacion difieren su linea.
chk("por victima, solo lo que no tiene tirada anuncia al tirar",
    areaSrc:find('and (session.definition.resolution == "heal" or session.definition.resolution == "auto") then', 1, true) ~= nil, true)
chk("y el diferido por victima solo exime al auto-impacto",
    areaSrc:find('if def.resolution == "auto" then return end', 1, true) ~= nil, true)

-- ─── PROYECTIL MAGICO REPARTE SUS DARDOS (2026-09-05) ───────────────────────
-- El campo damage trae el TOTAL (3d4+3) y antes se aplicaba como UN paquete a UN objetivo. El
-- auto-impacto lee del texto el numero de dardos y el daño POR DARDO ("cada dardo inflige
-- 1d4+1"), suma un dardo por nivel de espacio, y abre la ventana de reparto como cualquier
-- multiimpacto. Sin parse fiable, o con la sobrecarga de heroe (x10 sobre el total), se queda
-- el paquete unico.
print("Proyectil magico reparte sus dardos")
local coreSrc = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
chk("cuenta los dardos del texto",
    coreSrc:find('local dardos = tonumber(texto:match("(%d+)%s+dardos"))', 1, true) ~= nil, true)
chk("con el daño POR dardo, leido del texto",
    coreSrc:find('ParseDamageComponents(texto:match("cada dardo inflige%s+([^%.]+)") or "")', 1, true) ~= nil, true)
chk("un dardo mas por nivel de espacio",
    coreSrc:find('dardos = dardos + math.max(0, math.floor(tonumber(lanzado) or base) - base)', 1, true) ~= nil, true)
chk("con sobrecarga de heroe no se reparte",
    coreSrc:find("if not sobrecargaHeroe then", 1, true) ~= nil, true)
chk("y el reparto usa la ventana de multiimpacto",
    coreSrc:find('area.sizeText = tostring(dardos) .. " dardos"', 1, true) ~= nil, true)

-- ─── BENDICION ABRE EL SELECTOR (2026-09-05) ────────────────────────────────
-- Una condicion pura SIN salvacion ("hasta tres criaturas") caia al anuncio informativo: la
-- rama nueva la resuelve como auto-impacto y la ventana admite N objetivos. La linea de la
-- victima va sin "Impacto automatico": una bendicion no impacta.
print("Condicion pura sin salvacion: selector de hasta N objetivos")
chk("la rama existe",
    coreSrc:find("elseif condition and not damageComponents and not IsSpellAttack(spell) then", 1, true) ~= nil, true)
chk("y parsea hasta N criaturas",
    coreSrc:find('tonumber(texto:match("hasta%s+(%d+)%s+criaturas"))', 1, true) ~= nil, true)
chk("bendicion declara la condicion Bendito",
    io.open("HarfordCompendio/HarfordCompendio.lua"):read("*a")
        :find('condition = { id = "blessed" }', 1, true) ~= nil, true)
chk("el auto sin daño no rotula Impacto automatico",
    areaSrc:find('rollText = #(request.components or {}) > 0 and "Impacto automatico" or ""', 1, true) ~= nil, true)

-- ─── MAESTRO EN ESCUDOS Y GRAN MAESTRO DE ARMAS (2026-09-05) ────────────────
-- Escudos: el marcador `single` (objetivo unico) viaja como CAMPO FINAL del DNDAREAREQ (los
-- clientes viejos lo ignoran); el defensor suma el bono del escudo a salvaciones de DESTREZA
-- solo-para-ti, y el Abrigo PREPARADO deja el daño en cero al superar una salvacion de
-- mitad-al-exito (vale contra areas: RAW). GMA: el critico y el remate c/c conceden la marca
-- que Turn.SpendWeaponAttack cobra como adicional.
print("Maestro en escudos y Gran maestro de armas")
local syncSrc = io.open("Harford/Core/HarfordSync.lua"):read("*a")
chk("single viaja al final del payload",
    syncSrc:find("applySaveCode, applySaveDC, ignoreResist, single }, \"|\")", 1, true) ~= nil, true)
chk("y se lee al deserializar",
    syncSrc:find('single = singleTarget == "1",', 1, true) ~= nil, true)
chk("la peticion lo marca con EsObjetivoUnico",
    areaSrc:find("single = EsObjetivoUnico(session.definition) and true or nil,", 1, true) ~= nil, true)
chk("el defensor suma el escudo a la salvacion de Destreza solo-para-ti",
    areaSrc:find('HarfordDnDFeatureEffects.HasFlag("shieldMasterSave")', 1, true) ~= nil
    and areaSrc:find("base = (tonumber(base) or 0) + (HarfordDnDItems.GetShieldBonus() or 0)", 1, true) ~= nil, true)
chk("el Abrigo preparado deja el daño a cero (sin exigir objetivo unico)",
    areaSrc:find('HarfordCharacterPanel.TriggerPreparedReaction("dex_save_damage", { damage = applied })', 1, true) ~= nil, true)
local itemsSrc = io.open("Harford/DnD/State/HarfordDnDItems.lua"):read("*a")
chk("GetShieldBonus detecta item y seleccion basica",
    itemsSrc:find("function API.GetShieldBonus(profileName)", 1, true) ~= nil, true)
local featsSrc = io.open("Harford/DnD/Data/HarfordDnDFeats.lua"):read("*a")
chk("el empujon con escudo abre coste adicional",
    featsSrc:find('grantsAsBonus = { "empujar" }', 1, true) ~= nil, true)
chk("y los rasgos con grantsAsBonus tienen fila propia en el Libro",
    featsSrc:find("or trait.grantsAsBonus then", 1, true) ~= nil, true)
local wrollsSrc = io.open("Harford/DnD/Engine/HarfordDnDWeaponRolls.lua"):read("*a")
local dndSrc = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("GMA: el critico c/c concede la marca",
    dndSrc:find('HarfordDnDFeatureEffects.HasFlag("gwmBonusAttack")', 1, true) ~= nil, true)
chk("GMA: el remate c/c tambien",
    wrollsSrc:find('HarfordDnDFeatureEffects.HasFlag("gwmBonusAttack")', 1, true) ~= nil, true)

-- ─── CURACION SIN TARGET = A UNO MISMO (2026-09-05) ─────────────────────────
-- "Sin objetivo, lo propio": Curar heridas sin target te toca a ti (antes caia a la ventana de
-- marcado manual), y el gate de alcance no exige target cuando no hay nada que medir (a ese
-- punto sin target solo llegan curaciones; Palabra de curacion sin target abortaba).
print("Curacion sin objetivo se resuelve sobre uno mismo")
chk("el auto-resolve cae a uno mismo solo en curacion",
    areaSrc:find('if normalized.resolution == "heal" and S.session and not S.session.resolved then', 1, true) ~= nil, true)
chk("marcandote con CaptureUnit(player)",
    areaSrc:find('local yo = CaptureUnit("player")', 1, true) ~= nil, true)
chk("y el gate de alcance del core exige target para medir",
    coreSrc:find('and (UnitExists and UnitExists("target"))\n        if needsRange then', 1, true) ~= nil, true)
chk("la linea de victima solo incrusta curacion",
    areaSrc:find('if request.mode ~= "heal" then visibleApplied, visibleSummaries = 0, {} end', 1, true) ~= nil, true)
chk("y sin dos puntos: el color separa",
    areaSrc:find("Salv %s: %d", 1, true) == nil and areaSrc:find('%s %s: %s', 1, true) == nil, true)

-- ─── LUZ DEL AMANECER: AREA DE CURACION REPARTIDA (2026-09-06) ──────────────
-- Anunciaba el total ("30 PG de curacion a repartir") y NO abria area. Ahora es un cono de 9 m
-- resolution heal: el total (5 x nivel de paladin, `fixedPerClassLevel` con multiplicador) se
-- DIVIDE a partes iguales entre los marcados (`splitHealing`); el anuncio sale ya con la parte
-- de cada uno. Y los rotulos del Libro: un OBJETIVO UNICO (shape "other", Veredicto) no se
-- rotula Area — misma regla que el chat — y Tormenta divina declara `category = "area"` para
-- el rotulo sin cambiar su mecanica de rider (el click despacha por actionKind).
print("Luz del Amanecer reparte su curacion en area")
local palSrc = io.open("Harford/DnD/Data/Classes/Paladin.lua"):read("*a")
chk("la accion es un cono heal con reparto",
    palSrc:find('area = { shape = "cone", sizeText = "cono de 9 m", resolution = "heal", splitHealing = true', 1, true) ~= nil, true)
chk("el total es 5 x nivel de paladin",
    palSrc:find('healingComponents = { { fixedPerClassLevel = "paladin", multiplier = 5 } }', 1, true) ~= nil, true)
chk("el motor entiende nivel de clase",
    areaSrc:find("if component.fixedPerClassLevel and HarfordDnDProgression", 1, true) ~= nil, true)
chk("y divide entre los marcados",
    areaSrc:find("if session.definition.splitHealing then", 1, true) ~= nil
    and areaSrc:find("c.amount = math.max(1, math.floor((tonumber(c.amount) or 0) / n))", 1, true) ~= nil, true)
print("Los rotulos del Libro dicen la verdad")
local bookSrc = io.open("Harford/Character/HarfordCharacterBook.lua"):read("*a")
chk("objetivo unico no se rotula Area",
    bookSrc:find('and tostring(feature.area.shape or "") == "other" then', 1, true) ~= nil, true)
chk("Tormenta divina se rotula Area sin cambiar su mecanica",
    palSrc:find('category = "area", actionKind = "divineStorm"', 1, true) ~= nil, true)
-- Iconos modernos/custom (spell_paladin_templarsverdict...): sin ruta fisica en el cliente,
-- GetFileIDFromPath los rechazaba y el Libro caia al respaldo aunque TRP3 los pinta. Se
-- resuelven a FileDataID via LibRPMedia (la via del compendio) antes de rendirse.
-- OJO con el nombre: la funcion vive en HarfordCompendioAPI (el fichero IconMap escribe ahi;
-- no existe un global HarfordCompendioIconMap — con ese nombre el respaldo salia SIEMPRE).
chk("el Libro resuelve iconos via LibRPMedia antes del respaldo",
    io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
        :find("C.ResolveRP3IconName(final:match(", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
