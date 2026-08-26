-- LAS 12 CLASES CONTRA EL MANUAL.
--
-- El repaso a mano ya se hizo (`ESTADO_CLASES.md`) y dejo tres fallos que salieron en CASI TODAS
-- las clases. Un repaso a mano no se repite solo, asi que aqui se convierten en comprobaciones:
--
--   1. Un recurso declarado y NINGUNA forma de gastarlo. La clase nombra chi, enfoque o fragmentos
--      en sus descripciones y no existe el rasgo que los consume.
--   2. Catalogos truncados. Un rasgo `informativo` que enumera opciones en su descripcion y se
--      corto a media frase: las Maldiciones del Brujo tenian 2 de 8.
--   3. Rasgos que se nombran entre si y no existen.
--
-- Mas los datos duros del manual, que son objetivos y no opinables: dado de golpe y las DOS
-- salvaciones de cada clase.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── Cargar el libro de verdad, en el orden del .toc ────────────────────────
-- El propio AGENTS.md avisa: verificar CARGANDO el libro, no leyendo el fichero con grep. Un grep
-- sobre una linea larga miente -- mostro 2 opciones de metamagia donde habia 7.
local cargar = loadstring or load
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable, env.unpack = setmetatable, unpack

local function ejecutar(ruta)
    local fh = io.open(ruta)
    if not fh then return false end
    local src = fh:read("*a")
    fh:close()
    local f
    if setfenv then f = assert(cargar(src), ruta); setfenv(f, env)
    else f = assert(cargar(src, "t", "t", env), ruta) end
    local ok, err = pcall(f)
    if not ok then print("   no carga " .. ruta .. ": " .. tostring(err)) end
    return ok
end

ejecutar("Harford/DnD/Data/HarfordDnDBook.lua")
local ORDEN = { "Guerrero", "Picaro", "Mago", "Sacerdote", "Druida", "Paladin", "Cazador",
                "Monje", "Brujo", "Chaman", "CaballerodelaMuerte", "CazadordeDemonios" }
local cargadas = 0
for _, nombre in ipairs(ORDEN) do
    if ejecutar("Harford/DnD/Data/Classes/" .. nombre .. ".lua") then cargadas = cargadas + 1 end
end
ejecutar("Harford/DnD/Data/HarfordDnDBookDerived.lua")

local API = env.HarfordDnDBook and (env.HarfordDnDBook.API or env.HarfordDnDBook)
local CLASES = API and API.CLASSES or {}

print("Las doce clases estan")
chk("ficheros cargados", cargadas, 12)
chk("clases en el libro", #CLASES, 12)

-- ─── Datos duros, LEIDOS DEL MANUAL ─────────────────────────────────────────
-- El dado de golpe no es opinable, pero tampoco se escribe aqui a mano: se LEE del manual de
-- Warcraft 5a, que es la fuente. La primera version de esta prueba llevaba los valores de D&D
-- vanilla escritos por mi y marcaba como fallo dos que estaban BIEN: el Sacerdote es d6 y el
-- Cazador de Demonios d8 en Warcraft, no d8 y d10. La prueba estaba mal, no los datos.
-- Los doce salen del manual (`Warcraft 5a Edicion.txt`, lineas "Dado de Golpe: 1dN por nivel de X").
-- Se intentan LEER de ahi, que es lo correcto; pero el nombre del fichero lleva acentos y el
-- `io.open` de Lua en Windows no abre rutas UTF-8, asi que hay una copia escrita aqui como
-- respaldo. Si el manual se puede leer, MANDA el manual y el respaldo se comprueba contra el: asi
-- la copia no puede quedarse vieja sin que salte.
local RESPALDO = {
    guerrero = 10, picaro = 8, mago = 6, sacerdote = 6, druida = 8, paladin = 10,
    cazador = 10, monje = 8, brujo = 8, chaman = 8, caballero_muerte = 10, cazador_demonios = 8,
}
local NOMBRE_A_ID = {
    ["guerrero"] = "guerrero", ["picaro"] = "picaro", ["mago"] = "mago",
    ["sacerdote"] = "sacerdote", ["druida"] = "druida", ["paladin"] = "paladin",
    ["cazador"] = "cazador", ["monje"] = "monje", ["brujo"] = "brujo",
    ["chaman"] = "chaman", ["caballero de la muerte"] = "caballero_muerte",
    ["cazador de demonios"] = "cazador_demonios",
}
local DADO, delManual = {}, false
do
    local fh = io.open("RuleSource/Rulebooks/Warcraft 59486 Edici959n.txt")
    if fh then
        local texto = fh:read("*a")
        fh:close()
        for caras, nombre in texto:gmatch("[Dd]ados? de [Gg]olpe:%*%* 1d(%d+) por nivel de ([^%c]+)") do
            local limpio = nombre:lower():gsub("%s+$", "")
            limpio = limpio:gsub("95q", "a"):gsub("959", "e"):gsub("95{", "i")
                           :gsub("959", "o"):gsub("9586", "u"):gsub("95", "n")
            local id = NOMBRE_A_ID[limpio]
            if id then DADO[id] = tonumber(caras) end
        end
        local leidos = 0
        for _ in pairs(DADO) do leidos = leidos + 1 end
        delManual = leidos == 12
    end
end
if delManual then
    print("Dado de golpe: LEIDO del manual")
    -- El respaldo se contrasta contra el manual, para que no se quede viejo sin avisar.
    local divergen = {}
    for id, caras in pairs(DADO) do
        if RESPALDO[id] ~= caras then
            divergen[#divergen + 1] = id .. ": manual " .. caras .. ", copia " .. tostring(RESPALDO[id])
        end
    end
    chk("la copia de la prueba coincide con el manual", #divergen, 0)
    for _, m in ipairs(divergen) do print("     " .. m) end
else
    -- No poder leer el manual no puede pasar en silencio: se dice y se usa la copia.
    print("Dado de golpe: el manual no se pudo leer (nombre con acentos); se usa la copia")
    DADO = RESPALDO
end

print("Dado de golpe de cada clase")
local malDado = {}
for _, clase in ipairs(CLASES) do
    local id = tostring(clase.id or "?")
    local esperado = DADO[id]
    if esperado and tonumber(clase.hitDie) ~= esperado then
        malDado[#malDado + 1] = id .. "=" .. tostring(clase.hitDie) .. " (deberia " .. esperado .. ")"
    elseif not esperado then
        malDado[#malDado + 1] = id .. " (sin dado esperado en la prueba)"
    end
end
chk("todas con su dado", #malDado, 0)
for _, m in ipairs(malDado) do print("     " .. m) end

-- Toda clase da EXACTAMENTE dos competencias de salvacion. Ni una ni tres.
print("Cada clase da exactamente dos salvaciones")
local malSalv = {}
for _, clase in ipairs(CLASES) do
    local id = tostring(clase.id or "?")
    local cuantas = #(clase.saves or {})
    if cuantas ~= 2 then malSalv[#malSalv + 1] = id .. " tiene " .. cuantas end
end
chk("dos cada una", #malSalv, 0)
for _, m in ipairs(malSalv) do print("     " .. m) end

-- ─── Fallo 1: un recurso sin forma de gastarlo ──────────────────────────────
-- Si una clase declara un recurso, tiene que existir al menos un rasgo que lo consuma. Un recurso
-- que solo sube y nunca baja es una barra decorativa.
print("Todo recurso declarado tiene quien lo gaste")
-- Cuarta via: gastarlo desde el MOTOR con `AdjustResourceCurrent(clave, -n)`, que es como se gastan
-- las semillas del Druida y el Canalizar Divinidad. No es declarativa, pero es legitima: ignorarla
-- daria dos falsos positivos mas.
local gastoEnMotor = {}
for _, ruta in ipairs({ "Harford/DnD/UI/HarfordDnD.lua", "Harford/DnD/Engine/HarfordDnDAbilities.lua",
                        "Harford/Character/HarfordCharacterPanel.lua" }) do
    local fh = io.open(ruta)
    if fh then
        local src = fh:read("*a")
        fh:close()
        for clave in src:gmatch('AdjustResourceCurrent%("([a-z_]+)"%s*,%s*%-') do
            gastoEnMotor[clave] = true
        end
    end
end

local sinGasto = {}
for _, clase in ipairs(CLASES) do
    local id = tostring(clase.id or "?")
    local declarados, gastadores = {}, {}
    local function recorrer(lista)
        for _, f in ipairs(lista or {}) do
            for _, e in ipairs(f.effects or {}) do
                if e.kind == "resourceMax" and e.resource then declarados[e.resource] = true end
            end
            if f.resourceKey and (tonumber(f.resourceCost) or 0) > 0 then
                gastadores[f.resourceKey] = true
            end
            -- Hay tres vias de gasto, no una. La primera version solo miraba `resourceKey` y daba
            -- cinco falsos positivos: la ira del Guerrero, la energia del Picaro, las semillas del
            -- Druida y la niebla del Monje se gastan por MANIOBRA, no por coste de rasgo.
            -- Quinta via: una RESERVA que se gasta en cantidad elegida (Niebla reconfortante).
            if type(f.poolHeal) == "table" and f.poolHeal.resource then
                gastadores[f.poolHeal.resource] = true
            end
            for _, e in ipairs(f.effects or {}) do
                if e.kind == "conditionalWeaponDamage" and e.resourceCost then
                    gastadores[e.resourceCost] = true
                elseif e.kind == "energyManeuver" and e.resource then
                    gastadores[e.resource] = true
                end
            end
        end
    end
    recorrer(clase.features)
    for _, sub in pairs(clase.subclasses or {}) do recorrer(sub.features) end
    for recurso in pairs(declarados) do
        if not gastadores[recurso] and not gastoEnMotor[recurso] then
            sinGasto[#sinGasto + 1] = id .. " declara " .. recurso .. " y nadie lo gasta"
        end
    end
end
-- Ya no queda ninguno: `healing_mist` era el ultimo y se mecanizo. La lista se deja vacia a
-- proposito, para que declarar un hueco nuevo sea un gesto explicito y no un descuido.
local CONOCIDOS = {}
local nuevos = {}
for _, m in ipairs(sinGasto) do
    if not CONOCIDOS[m] then nuevos[#nuevos + 1] = m end
end
chk("ningun recurso sin gastador", #nuevos, 0)
for _, m in ipairs(nuevos) do print("     " .. m) end
sinGasto = nuevos
for _, m in ipairs(sinGasto) do print("     " .. m) end

-- ─── Fallo 2: catalogos truncados ───────────────────────────────────────────
-- Un rasgo que enumera opciones y se corta a media frase. La senal es la descripcion terminada sin
-- cerrar: sin punto final, o cortada en una coma o en "y".
print("Ninguna descripcion se corta a media frase")
local truncadas = {}
for _, clase in ipairs(CLASES) do
    local id = tostring(clase.id or "?")
    local function recorrer(lista, donde)
        for _, f in ipairs(lista or {}) do
            local d = tostring(f.description or "")
            if #d > 60 then
                local ultimo = d:sub(-1)
                if ultimo == "," or ultimo == ";" or d:sub(-2) == " y" or d:sub(-2) == " o" then
                    truncadas[#truncadas + 1] = id .. donde .. " · " .. tostring(f.name)
                end
            end
        end
    end
    recorrer(clase.features, "")
    for sid, sub in pairs(clase.subclasses or {}) do recorrer(sub.features, "/" .. sid) end
end
chk("ninguna cortada", #truncadas, 0)
for _, m in ipairs(truncadas) do print("     " .. m) end

-- ─── Fallo 3: rasgos e ids ──────────────────────────────────────────────────
-- Dos rasgos con el mismo id: el segundo tapa al primero y desaparece del Libro sin avisar.
print("Ningun id de rasgo se repite")
local vistos, repetidos = {}, {}
for _, clase in ipairs(CLASES) do
    local id = tostring(clase.id or "?")
    local function recorrer(lista)
        for _, f in ipairs(lista or {}) do
            local fid = tostring(f.id or "")
            if fid ~= "" then
                if vistos[fid] then repetidos[#repetidos + 1] = fid .. " (" .. id .. " y " .. vistos[fid] .. ")"
                else vistos[fid] = id end
            end
        end
    end
    recorrer(clase.features)
    for _, sub in pairs(clase.subclasses or {}) do recorrer(sub.features) end
end
chk("sin repetidos", #repetidos, 0)
for _, m in ipairs(repetidos) do print("     " .. m) end

-- Todo rasgo tiene nombre y nivel: sin uno de los dos no se puede ni pintar ni desbloquear.
print("Todo rasgo tiene nombre y nivel")
local incompletos = {}
for _, clase in ipairs(CLASES) do
    local id = tostring(clase.id or "?")
    local function recorrer(lista, donde)
        for _, f in ipairs(lista or {}) do
            if not f.name or f.name == "" then
                incompletos[#incompletos + 1] = id .. donde .. " · un rasgo sin nombre"
            elseif not tonumber(f.level) then
                incompletos[#incompletos + 1] = id .. donde .. " · " .. f.name .. " sin nivel"
            end
        end
    end
    recorrer(clase.features, "")
    for sid, sub in pairs(clase.subclasses or {}) do recorrer(sub.features, "/" .. sid) end
end
chk("todos completos", #incompletos, 0)
for _, m in ipairs(incompletos) do print("     " .. m) end

-- ─── Alcance del proyecto ───────────────────────────────────────────────────
-- El alcance declarado es 1-6. Un rasgo de nivel 7 o mas no es un fallo, pero conviene saber
-- cuantos hay: es deuda declarada, no accidental.
print("Alcance 1-6, con lo de mas arriba contado aparte")
local dentro, fuera = 0, 0
for _, clase in pairs(CLASES) do
    local function recorrer(lista)
        for _, f in ipairs(lista or {}) do
            local nivel = tonumber(f.level) or 1
            if nivel <= 6 then dentro = dentro + 1 else fuera = fuera + 1 end
        end
    end
    recorrer(clase.features)
    for _, sub in pairs(clase.subclasses or {}) do recorrer(sub.features) end
end
chk("hay rasgos dentro del alcance", dentro > 0, true)
print(string.format("     %d rasgos de nivel 1-6, %d por encima", dentro, fuera))



-- ─── Fallo 3 del repaso: conjuros que no existen ────────────────────────────
-- El manual y el compendio traducen distinto, y un conjuro concedido que no existe no da error:
-- el rasgo se anuncia y no concede nada. AGENTS.md avisa de buscar por NIVEL y EFECTO, nunca por
-- parecido -- `Rayo de hechiceria` parece *rayo del caos* y es *witch bolt*.
local IDS, NOMBRES = {}, {}
do
    local fh = io.open("HarfordCompendioData/HarfordCompendioData.lua")
    if fh then
        local src = fh:read("*a")
        fh:close()
        for id in src:gmatch('\n        id = \"([a-z_0-9]+)\"') do IDS[id] = true end
        for nombre in src:gmatch('\n        name = \"([^\"]+)\"') do
            NOMBRES[nombre:lower()] = true
        end
    end
end
local hayCompendio = next(IDS) ~= nil
print("Los conjuros que conceden las clases existen en el compendio")
chk("el compendio se pudo leer", hayCompendio, true)

if hayCompendio then
    local rotosId, rotosNombre = {}, {}
    for _, clase in ipairs(CLASES) do
        local id = tostring(clase.id or "?")
        local function mirar(lista, donde)
            for _, f in ipairs(lista or {}) do
                -- Por id: `grantedSpells` y las listas de `spellGrants`.
                for _, sid in ipairs(f.grantedSpells or {}) do
                    if not IDS[sid] then rotosId[#rotosId + 1] = id .. donde .. " · " .. sid end
                end
                for _, grupo in ipairs(f.spellGrants or {}) do
                    for _, sid in ipairs(grupo.ids or {}) do
                        if not IDS[sid] then rotosId[#rotosId + 1] = id .. donde .. " · " .. sid end
                    end
                end
                for _, sid in ipairs(f.cantripSpellIds or {}) do
                    if not IDS[sid] then rotosId[#rotosId + 1] = id .. donde .. " · " .. sid end
                end
            end
        end
        mirar(clase.features, "")
        for sid, sub in pairs(clase.subclasses or {}) do
            mirar(sub.features, "/" .. sid)
            -- La lista AMPLIADA cuelga de la SUBCLASE, no de un rasgo, y va por nombre visible en
            -- vez de por id. Mi primera version la buscaba en los rasgos y no encontraba ninguna:
            -- decia "0 sin casar" mirando una lista vacia, que es peor que no comprobar.
            for _, nom in ipairs(sub.expandedSpells or {}) do
                if not NOMBRES[tostring(nom):lower()] then
                    rotosNombre[#rotosNombre + 1] = id .. "/" .. tostring(sub.id or sid) .. " · " .. tostring(nom)
                end
            end
        end
    end
    chk("ningun id de conjuro inexistente", #rotosId, 0)
    for _, m in ipairs(rotosId) do print("     " .. m) end
    -- Los nombres se listan aparte: divergen mas a menudo y son mas faciles de arreglar.
    print("     nombres de la lista ampliada que no casan: " .. #rotosNombre)
    for i, m in ipairs(rotosNombre) do
        if i <= 12 then print("        " .. m) end
    end
end

-- ─── Niebla reconfortante ───────────────────────────────────────────────────
-- Era el ultimo recurso sin gastador. El manual dice "hasta el maximo que quede en tu reservorio",
-- asi que la cantidad NO se declara: la elige el jugador y el tope es lo que quede.
local monje
for _, c in ipairs(CLASES) do if c.id == "monje" then monje = c end end
local niebla
for _, sub in pairs(monje and monje.subclasses or {}) do
    for _, f in ipairs(sub.features or {}) do
        if f.id == "monje_tej_niebla_calmante" then niebla = f end
    end
end
print("La reserva del Tejedor de niebla ya se puede gastar")
chk("el rasgo existe", niebla ~= nil, true)
chk("es una accion, no solo un recurso", niebla and niebla.cast, "accion")
chk("declara su reserva", niebla and niebla.poolHeal and niebla.poolHeal.resource, "healing_mist")
chk("sin cantidad fija, que la elige el jugador", niebla and niebla.poolHeal.amount, "nil")
chk("y la cura de enfermedad cuesta 5", niebla and niebla.poolHeal.cure.amount, 5)
-- El nombre NO se toca: "Niebla reconfortante" es el canonico de la web/TRP3, y el texto largo del
-- manual se busca por "Niebla Calmante" a traves del mapeo de `HarfordDnDBookText`. Renombrarlo
-- dejaria la ficha con la descripcion corta.
chk("conserva su nombre canonico", niebla and niebla.name, "Niebla reconfortante")
local texto = io.open("Harford/DnD/Data/HarfordDnDBookText.lua"):read("*a")
chk("y el mapeo al titulo del manual sigue",
    texto:find('monje_tej_niebla_calmante = "Niebla Calmante"', 1, true) ~= nil, true)

local panel2 = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
chk("el Libro la enruta", panel2:find('type(self.feature.poolHeal) == "table"', 1, true) ~= nil, true)
-- Curar enfermedad gasta de la reserva pero NO da puntos de golpe: son dos usos de lo mismo.
chk("curar enfermedad no da ademas vida",
    panel2:find("if not esCura then", 1, true) ~= nil, true)
-- Se gasta antes de entregar y se devuelve si la entrega falla, igual que la Fe.
chk("si la entrega falla, se devuelve lo gastado",
    panel2:find("HarfordDnDStore.AdjustResourceCurrent(spec.resource, cantidad)", 1, true) ~= nil, true)
-- La entrega al objetivo se REUSA de la concesion; no se copio.
chk("la entrega al objetivo es una sola",
    select(2, panel2:gsub("function EntregarAObjetivo", "")), 1)

-- ─── FICHA DE NIVEL 6 DE CADA CLASE ─────────────────────────────────────────
-- Nivel 6 es el techo del alcance actual, asi que es donde una clase tiene todo lo que va a tener.
-- El comando `ficha6` monta esto en juego; aqui se comprueba lo que puede comprobarse sin cliente:
-- que las doce producen rasgos, que llegan con especializacion elegida y que las elecciones que
-- dejan pendientes se pueden enumerar -- si no, el comando no podria decir cuales faltan.
print("Las doce montan a nivel 6")
local sinRasgos, sinSub, rasgosTotales = {}, {}, 0
for _, c in ipairs(CLASES) do
    local sub = API.GetDefaultSubclassId and API.GetDefaultSubclassId(c.id)
    local niveles = { { classId = c.id, subclassId = sub, level = 6 } }
    local rasgos = API.GetUnlockedFeatures and API.GetUnlockedFeatures(niveles) or {}
    rasgosTotales = rasgosTotales + #rasgos
    if #rasgos == 0 then sinRasgos[#sinRasgos + 1] = c.id end
    -- La especializacion se elige al 3 en casi todas, asi que al 6 ninguna deberia quedarse sin
    -- una por defecto: sin ella, la ficha de prueba saldria a medias y no serviria para probar.
    if not sub or sub == "" then sinSub[#sinSub + 1] = c.id end
end
chk("todas dan rasgos al 6", #sinRasgos == 0 and "si" or table.concat(sinRasgos, ","), "si")
chk("todas tienen especializacion por defecto",
    #sinSub == 0 and "si" or table.concat(sinSub, ","), "si")
chk("y el total es razonable, no cero", rasgosTotales > 60, true)

-- Un nivel 6 tiene que traer MAS que un nivel 1. Parece obvio, pero si `GetUnlockedFeatures`
-- dejara de filtrar por nivel, las dos cifras serian iguales y nadie se enteraria.
local unoTotal, seisTotal = 0, 0
for _, c in ipairs(CLASES) do
    local sub = API.GetDefaultSubclassId and API.GetDefaultSubclassId(c.id)
    unoTotal = unoTotal + #(API.GetUnlockedFeatures({ { classId = c.id, subclassId = sub, level = 1 } }) or {})
    seisTotal = seisTotal + #(API.GetUnlockedFeatures({ { classId = c.id, subclassId = sub, level = 6 } }) or {})
end
chk("el 6 trae mas que el 1", seisTotal > unoTotal, true)
-- Y el nivel 1 NO puede traer rasgos de subclase, que se elige despues.
chk("el 1 no trae ya todo", unoTotal < seisTotal, true)

print("Las elecciones pendientes se pueden enumerar")
local conEleccion = 0
for _, c in ipairs(CLASES) do
    local sub = API.GetDefaultSubclassId and API.GetDefaultSubclassId(c.id)
    for _, item in ipairs(API.GetUnlockedFeatures({ { classId = c.id, subclassId = sub, level = 6 } }) or {}) do
        local f = item.feature
        if f and f.choice then
            local huecos = API.GetChoiceSlots and API.GetChoiceSlots(f) or 0
            if huecos > 0 then conEleccion = conEleccion + 1 end
            -- Un rasgo de eleccion sin nombre no se podria listar por pantalla.
            if not (f.name and f.name ~= "") then
                chk("rasgo de eleccion sin nombre en " .. tostring(c.id), f.id, "(deberia tener nombre)")
            end
        end
    end
end
-- Si esto fuera 0, `ficha6` diria siempre "completa" y no estaria comprobando nada.
chk("hay rasgos de eleccion al 6", conEleccion > 0, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
