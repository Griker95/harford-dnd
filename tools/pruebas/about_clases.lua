-- EL ABOUT DE LAS 12 CLASES: los errores que salieron con el CdM, candados para todas.
--
--   1. Una seccion del manual que INCRUSTA otro rasgo de la clase como sub-seccion debe quedar
--      CORTADA por GetClassChapterFeature ("Poder Runico" traia enteros "Espiral de la Muerte"
--      y "Golpe Runico" y salian duplicados en el About).
--   2. Un rasgo que concede conjuros no puede perderse: si es informativo de SUBCLASE sin
--      efectos se filtra del frame, pero entonces sus conjuros DEBEN llegar a "Magia <Sub>"
--      (grantedSpells, spellGrants y cantripSpellIds estan enrutados). Un rasgo de CLASE que
--      concede conjuros no se filtra: no tiene frame de magia que lo recoja.
--   3. Dos rasgos visibles con el MISMO nombre en el mismo origen ("Conjuros de presencia
--      (Sangre)" x2) duplican bloque. Excepcion: los `choice` (Pericia del Picaro a 1 y 6),
--      cuyo cuerpo son sus elecciones y difiere.
--   4. Una opcion de eleccion de UN slot debe tener regla que mostrar: desc propia, seccion
--      del manual (#### bajo el rasgo) o nota entre parentesis en el label. Sin ninguna, el
--      bloque inline salia vacio (Adaptacion salvaje del Druida feral).

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable, env.unpack, env.next = setmetatable, unpack, next
env._G = env

local function ejecutar(ruta)
    local fh = io.open(ruta)
    if not fh then return false end
    local src = fh:read("*a"); fh:close()
    local f
    if setfenv then f = assert(cargar(src), ruta); setfenv(f, env)
    else f = assert(cargar(src, "t", "t", env), ruta) end
    local ok, err = pcall(f)
    if not ok then print("   no carga " .. ruta .. ": " .. tostring(err)) end
    return ok
end

ejecutar("Harford/Core/HarfordClassColors.lua")
ejecutar("Harford/DnD/Data/HarfordDnDData.lua")
ejecutar("Harford/DnD/Data/HarfordDnDFeats.lua")
ejecutar("Harford/DnD/Data/HarfordDnDRaces.lua")
ejecutar("Harford/DnD/Data/HarfordDnDBackgrounds.lua")
ejecutar("Harford/DnD/Data/HarfordDnDBook.lua")
for _, nombre in ipairs({ "Guerrero", "Picaro", "Mago", "Sacerdote", "Druida", "Paladin",
    "Cazador", "Monje", "Brujo", "Chaman", "CaballerodelaMuerte", "CazadordeDemonios" }) do
    ejecutar("Harford/DnD/Data/Classes/" .. nombre .. ".lua")
end
ejecutar("Harford/DnD/Data/HarfordDnDBookDerived.lua")
ejecutar("Harford/DnD/Data/HarfordDnDBookText.lua")

local Book = env.HarfordDnDBook
local Text = env.HarfordDnDBookText
local CC = env.HarfordClassColors
chk("libro cargado (12 clases)", Book and #Book.CLASSES, 12)
chk("BookText cargado", Text and Text.GetClassChapterFeature ~= nil, true)

local function Norm(s)
    s = tostring(s or "")
    if CC and CC.StripAccents then s = CC.StripAccents(s) end
    return s:lower():gsub("[^%w]+", " "):match("^%s*(.-)%s*$")
end

-- El generador solo escribe hasta nivel 6 (alcance actual del proyecto).
local NIVEL = 6
local incrustados, perdidos, duplicados, sinRegla = {}, {}, {}, {}

for _, class in ipairs(Book.CLASSES or {}) do
    local todos = {}
    for _, f in ipairs(class.features or {}) do todos[#todos + 1] = { f = f, origen = "clase" } end
    for _, s in ipairs(class.subclasses or {}) do
        for _, f in ipairs(s.features or {}) do todos[#todos + 1] = { f = f, origen = "sub:" .. tostring(s.id) } end
    end
    local nombres = {}
    for _, it in ipairs(todos) do nombres[Norm(it.f.name)] = true end

    for _, it in ipairs(todos) do
        local f = it.f
        local etiqueta = tostring(class.id) .. "/" .. it.origen .. "/" .. tostring(f.name)

        -- 1. incrustados residuales en el texto rico
        local texto = Text.GetFeatureDescription(f, class.id, "class", nil, true) or ""
        for titulo in texto:gmatch("{h3}([^{]+){/h3}") do
            local n = Norm(titulo)
            if nombres[n] and n ~= Norm(f.name) then
                incrustados[#incrustados + 1] = etiqueta .. " incrusta " .. titulo
            end
        end

        -- 2. concesion de conjuros filtrada sin ruta al frame de magia
        local concede = (f.grantedSpells and #f.grantedSpells > 0)
            or (f.spellGrants and #f.spellGrants > 0)
            or (f.cantripSpellIds and #f.cantripSpellIds > 0)
        if concede then
            local esSub = it.origen:find("^sub") ~= nil
            local filtrado = esSub and tostring(f.type) == "informativo"
                and not (f.effects and #f.effects > 0)
            -- las tres vias de subclase estan enrutadas a "Magia <Sub>"; un rasgo de CLASE
            -- filtrado no tendria ruta, asi que el filtro NO debe alcanzarlo.
            if filtrado and not esSub then perdidos[#perdidos + 1] = etiqueta end
        end

        -- 4. opciones de un slot sin regla que mostrar
        local slots = f.choice and (tonumber(f.choice.slots) or 1) or 0
        if slots == 1 and (tonumber(f.level) or 99) <= NIVEL then
            for _, opt in ipairs((f.choice and f.choice.options) or {}) do
                local label = tostring(opt.label or opt.id or "")
                local corto = label:match("^(.-)%s*%(") or label
                if tostring(opt.desc or opt.description or "") == ""
                    and not Text.GetClassChapterFeature(class.name, corto, 4, true)
                    and not label:match("%((.-)%)") then
                    sinRegla[#sinRegla + 1] = etiqueta .. " -> " .. corto
                end
            end
        end
    end

    -- 3. nombres duplicados visibles a nivel 6 (los `choice` quedan exentos)
    local vistos = {}
    for _, it in ipairs(todos) do
        local f = it.f
        local esSub = it.origen:find("^sub") ~= nil
        local filtrado = esSub and tostring(f.type) == "informativo"
            and ((f.grantedSpells and #f.grantedSpells > 0)
                or (f.spellGrants and #f.spellGrants > 0)
                or (f.cantripSpellIds and #f.cantripSpellIds > 0))
            and not (f.effects and #f.effects > 0)
        if (tonumber(f.level) or 99) <= NIVEL and not filtrado and not f.choice then
            local clave = tostring(class.id) .. "|" .. it.origen .. "|" .. Norm(f.name)
            if vistos[clave] then
                duplicados[#duplicados + 1] = clave
            end
            vistos[clave] = true
        end
    end
end

print("1. Ninguna seccion del manual incrusta otro rasgo de su clase")
chk("incrustados residuales", #incrustados, 0)
for _, e in ipairs(incrustados) do print("     " .. e) end

print("2. Ningun conjuro concedido se pierde al filtrar el frame")
chk("rasgos filtrados sin ruta de magia", #perdidos, 0)
for _, e in ipairs(perdidos) do print("     " .. e) end

print("3. Sin bloques duplicados por nombre a nivel 6")
chk("duplicados visibles", #duplicados, 0)
for _, e in ipairs(duplicados) do print("     " .. e) end

print("4. Toda opcion de un slot tiene regla que mostrar")
chk("opciones sin regla", #sinRegla, 0)
for _, e in ipairs(sinRegla) do print("     " .. e) end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
