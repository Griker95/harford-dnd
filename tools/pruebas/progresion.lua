-- HarfordDnDProgression: el estado del que cuelga todo lo demas -- niveles, elecciones, raza y
-- que rasgos estan activos. 2239 lineas sin una sola prueba.
--
-- Aqui viven dos reglas que ya dieron problemas: la COMPACTACION de huecos en las elecciones (con
-- el slot 1 vacio, la eleccion entera se comportaba como inexistente) y los gates de rasgo por
-- raza y por nucleo activo (sin ellos, los cinco nucleos del Brujo concedian sus conjuros a la vez).

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local DATOS = {}
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable, env.next, env.unpack = setmetatable, next, unpack
env.UnitName = function() return "Prueba" end
env.HarfordClassColors = { StripAccents = function(v) return v end,
    NormalizeKey = function(v) return tostring(v or ""):lower() end }
env.HarfordChat = { Print = function() end }
-- `SetClassEntry` valida la clase contra el libro: sin el, rechaza cualquier id. Se le da un libro
-- minimo con las dos clases que usa la prueba.
local LIBRO = { guerrero = { id = "guerrero" }, picaro = { id = "picaro" } }
env.HarfordDnDBook = {
    GetClass = function(id) return LIBRO[tostring(id or "")] end,
    GetDefaultSubclassId = function() return "" end,
    NormalizeSubclassId = function(_, sub) return tostring(sub or "") end,
}

local cargar = loadstring or load
local src = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
assert(pcall(f))
local P = env.HarfordDnDProgression

-- `Get` construye o devuelve la tabla del perfil; se sustituye por una controlable para poder
-- fijar el estado sin depender de SavedVariables.
local function conEstado(t)
    DATOS = t
    DATOS.classLevels = DATOS.classLevels or {}
    DATOS.featureStates = DATOS.featureStates or {}
    DATOS.choices = DATOS.choices or {}
    return DATOS
end
P.Get = function() return DATOS end
conEstado({})

-- ─── Nivel total ────────────────────────────────────────────────────────────
print("El nivel total es la suma de las clases")
conEstado({ classLevels = { { classId = "guerrero", level = 3 } } })
chk("una clase", P.GetTotalLevel(), 3)
conEstado({ classLevels = { { classId = "guerrero", level = 3 }, { classId = "picaro", level = 2 } } })
chk("multiclase", P.GetTotalLevel(), 5)
conEstado({})
chk("sin clases, cero", P.GetTotalLevel(), 0)

-- ─── Bonus de competencia ───────────────────────────────────────────────────
-- La tabla del manual: sube en 5, 9, 13 y 17. Un umbral corrido cambia CADA tirada del personaje.
print("El bonus de competencia, con sus escalones exactos")
local ESPERADO = { [1]=2, [4]=2, [5]=3, [8]=3, [9]=4, [12]=4, [13]=5, [16]=5, [17]=6, [20]=6 }
for nivel = 1, 20 do
    if ESPERADO[nivel] then
        conEstado({ classLevels = { { classId = "guerrero", level = nivel } } })
        chk("nivel " .. nivel, P.GetProficiencyBonus(), ESPERADO[nivel])
    end
end
-- Sin personaje no hay bonus: devolver 2 haria creer que hay ficha donde no la hay.
conEstado({})
chk("sin niveles, ninguno", P.GetProficiencyBonus(), "nil")
-- En multiclase cuenta el TOTAL, no el de la clase mas alta: un 3/2 tiene el bonus de un 5.
conEstado({ classLevels = { { classId = "guerrero", level = 3 }, { classId = "picaro", level = 2 } } })
chk("multiclase 3/2 usa el total", P.GetProficiencyBonus(), 3)

-- ─── Elecciones: los huecos se compactan ────────────────────────────────────
-- El desplegable por slot deja poner el 2 sin el 1. Los consumidores recorren con `ipairs`, que
-- se detiene en el primer hueco: con el slot 1 vacio la eleccion entera se comportaba como si no
-- existiera -- sin efecto, sin salir en el About y marcada como pendiente en el Libro.
print("Las elecciones se devuelven compactadas")
conEstado({ choices = { rasgo = { [1] = "a", [2] = "b" } } })
chk("dos seguidas", table.concat(P.GetChoice("rasgo"), ","), "a,b")
conEstado({ choices = { rasgo = { [2] = "b" } } })
chk("con el primer hueco vacio, la segunda sigue contando",
    table.concat(P.GetChoice("rasgo"), ","), "b")
conEstado({ choices = { rasgo = { [1] = "a", [3] = "c" } } })
chk("con un hueco en medio, las dos", table.concat(P.GetChoice("rasgo"), ","), "a,c")
conEstado({ choices = { rasgo = { [1] = "", [2] = "b" } } })
chk("una cadena vacia no cuenta como eleccion", table.concat(P.GetChoice("rasgo"), ","), "b")
conEstado({})
chk("un rasgo sin elecciones, lista vacia", #P.GetChoice("rasgo"), 0)
-- Las importaciones antiguas guardaban con clave de texto: se conservan al final, no se pierden.
conEstado({ choices = { rasgo = { [1] = "a", vieja = "z" } } })
chk("las claves antiguas se conservan", table.concat(P.GetChoice("rasgo"), ","), "a,z")

print("Guardar una eleccion en su slot")
conEstado({})
chk("se guarda", (P.SetChoiceSlot("rasgo", 1, "opcion")), true)
chk("y se lee", P.GetChoice("rasgo")[1], "opcion")
-- Guardar vacio BORRA el slot, que es como se deshace una eleccion.
P.SetChoiceSlot("rasgo", 1, "")
chk("guardar vacio la borra", #P.GetChoice("rasgo"), 0)
chk("un slot cero se rechaza", (P.SetChoiceSlot("rasgo", 0, "x")), false)
chk("y un rasgo sin id tambien", (P.SetChoiceSlot("", 1, "x")), false)

-- ─── Rasgos activos ─────────────────────────────────────────────────────────
-- Por defecto un rasgo desbloqueado FUNCIONA. `featureStates` es para desactivar expresamente, no
-- una segunda puerta que obligue a guardar `true` para cada accion.
print("Un rasgo desbloqueado funciona por defecto")
conEstado({})
chk("sin estado guardado, activo", P.IsFeatureEnabled({ id = "x" }), true)
conEstado({ featureStates = { x = false } })
chk("desactivado expresamente, no", P.IsFeatureEnabled({ id = "x" }), false)
conEstado({ featureStates = { x = true } })
chk("y activado, si", P.IsFeatureEnabled({ id = "x" }), true)
chk("sin rasgo, no", P.IsFeatureEnabled(nil), false)
chk("sin id, no", P.IsFeatureEnabled({}), false)

-- Una subclase puede exigir raza. Durante una importacion incompleta NO se bloquea -- seria peor
-- perder rasgos por no haber leido aun la raza --, pero una raza distinta ya conocida si bloquea.
print("Un rasgo que exige raza")
conEstado({ race = { id = "elfo_noche" } })
chk("con la raza correcta", P.IsFeatureEnabled({ id = "x", requiredRace = "elfo_noche" }), true)
conEstado({ race = { id = "humano" } })
chk("con otra raza, no", P.IsFeatureEnabled({ id = "x", requiredRace = "elfo_noche" }), false)
conEstado({})
chk("sin raza aun, no bloquea", P.IsFeatureEnabled({ id = "x", requiredRace = "elfo_noche" }), true)
conEstado({ race = { id = "" } })
chk("con raza vacia, tampoco", P.IsFeatureEnabled({ id = "x", requiredRace = "elfo_noche" }), true)

-- Los cinco nucleos del Brujo existen desde nivel 2, pero solo cuenta el que sostienes: sin este
-- gate, sus conjuros se concedian los cinco a la vez.
print("Solo cuenta el nucleo que sostienes")
conEstado({ activeCore = "fuego" })
chk("el nucleo activo", P.IsFeatureEnabled({ id = "x", requiredCore = "fuego" }), true)
chk("otro nucleo, no", P.IsFeatureEnabled({ id = "x", requiredCore = "sombra" }), false)
conEstado({})
chk("sin nucleo, ninguno", P.IsFeatureEnabled({ id = "x", requiredCore = "fuego" }), false)

-- ─── Clases ─────────────────────────────────────────────────────────────────
print("Entradas de clase")
conEstado({})
P.SetClassEntry(1, "guerrero", nil, 3)
chk("se guarda", P.GetClassLevels()[1] and P.GetClassLevels()[1].classId, "guerrero")
chk("con su nivel", P.GetClassLevels()[1].level, 3)
P.SetClassEntry(2, "picaro", "forajido", 2)
chk("y una segunda", P.GetTotalLevel(), 5)
chk("con su subclase", P.GetClassLevels()[2].subclassId, "forajido")
P.RemoveClassEntry(2)
chk("quitarla baja el total", P.GetTotalLevel(), 3)

-- ─── EL EQUIPO VIAJA COMPRIMIDO ─────────────────────────────────────────────
-- Un equipo completo son item links repetidos con la misma estructura: comprime muy bien. Importa
-- porque hoy se trocea a mano y el reensamblado es todo o nada -- si falta un trozo, se descarta
-- entero y no hay acuse ni reintento. El fallo es MULTIPLICATIVO: con 7 trozos y un 1% de perdida
-- por mensaje falla el 6,8% de los envios; con 2 trozos, el 2%.
--
-- De COMPORTAMIENTO: comprime, deshace y compara byte a byte. LibDeflate vive en el cliente
-- (EpsilonLib), no en el repo, asi que si no esta se salta en vez de fallar.
do
    local ruta = "G:/Epsilon/_retail_/Interface/AddOns/EpsilonLib/Lib/LibDeflate/LibDeflate.lua"
    local hay = io.open(ruta)
    if not hay then
        print("El equipo viaja comprimido  (saltada: LibDeflate no esta en este equipo)")
    else
        hay:close()
        local D = dofile(ruta)
        print("El equipo viaja comprimido")
        local partes = {}
        for i, hueco in ipairs({ "Head","Shoulder","Back","Chest","Wrist","Hands","Waist","Legs",
            "Feet","Finger0","Finger1","Trinket0","Trinket1","MainHand","SecondaryHand" }) do
            partes[#partes+1] = hueco .. "=" .. string.format(
                "|cff1eff00|Hitem:1408%04d::::::::60:259:::::::::|h[Objeto %d]|h|r", 8000 + i, i)
        end
        local payload = "DNDEQUIP|Griker|" .. table.concat(partes, ";")
        local comp = "Z|" .. D:EncodeForWoWAddonChannel(D:CompressDeflate(payload, { level = 9 }))
        chk("encoge de verdad", #comp < #payload, true)
        -- Lo que importa no son los bytes sino los TROZOS: cada uno es una oportunidad de perderlo.
        local CHUNK = 200
        chk("y en menos trozos", math.ceil(#comp/CHUNK) < math.ceil(#payload/CHUNK), true)
        local vuelta = D:DecompressDeflate(D:DecodeForWoWAddonChannel(comp:sub(3)))
        chk("y vuelve al original exacto", vuelta == payload, true)
    end
end

-- El receptor lo deshace en `DeserializeDnDEquipment`, que cubre las DOS rutas: mensaje suelto y
-- reensamblado por trozos, porque el segundo acaba llamando al primero.
do
    local sync = io.open("Harford/Core/HarfordSync.lua"):read("*a")
    chk("el receptor lo deshace",
        sync:find("message = HarfordSync.Descomprimir(message)", 1, true) ~= nil, true)
    -- Y solo se comprime lo que NO cabe en un mensaje: por debajo de eso se manda en claro y lo
    -- entiende cualquier cliente, incluido uno sin actualizar.
    chk("solo lo que no cabe",
        sync:find("payload = HarfordSync.Comprimir(payload) or payload", 1, true) ~= nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
