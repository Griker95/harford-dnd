-- HarfordDnDBook: libro hardcodeado de clases/subclases/rasgos.
-- Solo datos + helpers puros. Los efectos son declarativos, nunca codigo Lua.
--
-- Sistema: World of Warcraft D&D 5ª Edicion (homebrew). Las clases, subclases
-- (especializaciones) y rasgos salen del manual en español. Contenido en curso:
-- rasgos hasta NIVEL 6. Lo no automatizable va como `informativo` con su texto.

HarfordDnDBook = HarfordDnDBook or {}

local API = HarfordDnDBook

-- Rasgo ASI estandar (niveles 4/8/12/16/19; hasta nivel 6 solo aplica el de 4).
function API.ASI(classId, level)
    return {
        id = classId .. "_asi_" .. tostring(level), level = level,
        name = "Mejora de Caracteristica", type = "choice",
        description = "Aumenta una característica en 2 o dos caracteristicas en 1 (maximo 20), "
            .. "o elige una dote en su lugar.",
        effects = {},
        -- `allowFeat`: ademas de las caracteristicas, la lista incluye las dotes. Elegir una dote
        -- consume la mejora entera (no se suben caracteristicas), y de eso se encarga el dialogo.
        choice = { slots = 2, optionsFrom = "ability+1", allowFeat = true },
    }
end

function API.WeaponProfEffects(...)
    local out = {}
    for i = 1, select("#", ...) do
        out[#out + 1] = { kind = "weaponProf", weapon = select(i, ...) }
    end
    return out
end

-- Motivo por el que un rasgo NO esta mecanizado, o nil si SI lo esta. Sirve para clases,
-- razas, dotes y trasfondos (mismo formato de feature). Se considera mecanizado si tiene
-- efectos, un contador de usos (`uses`) o una eleccion (`choice`). Para el resto (solo
-- `type=="informativo"`) deduce el motivo de la descripcion (heuristica; solo informativo
-- para la UI, no afecta a calculos). Asi "se indica" en los datos que sigue sin mecanizar.
function API.GetUnmechanizedReason(feature)
    if type(feature) ~= "table" then return nil end
    local hasEffects = type(feature.effects) == "table" and #feature.effects > 0
    if hasEffects or type(feature.uses) == "table" or type(feature.choice) == "table" then
        return nil  -- mecanizado: efecto, contador de usos o eleccion
    end
    if feature.type ~= "informativo" then return nil end
    local d = HarfordClassColors.StripAccents(feature.description):lower()
    local function has(...)
        for i = 1, select("#", ...) do if d:find((select(i, ...)), 1, true) then return true end end
        return false
    end
    if has("vision en la oscuridad", "vision en oscuridad", "penumbra a ", "luz tenue a ", "oscuridad como", "ves en luz tenue") then
        return "Vision en la oscuridad: el addon no modela sentidos."
    elseif has("hablas, lees y escribes", "idioma adicional", "idioma extra") then
        return "Idiomas: no se modelan mecanicamente."
    elseif has("arma natural", "golpe desarmado que inflige") then
        return "Arma natural: requiere una capa de arma natural (no existe)."
    elseif has("pg maximos", "puntos de golpe maximos", "puntos de golpe maximos") then
        return "Bono de PG por nivel total: resourceMax solo escala por clase."
    elseif has("conjuro", "truco", "ranura", "hechizo", "lanzas ", "lanzar el conjuro", "augurio", "heroismo") then
        return "Depende del sistema de conjuros (no modelado)."
    elseif has("reaccion") then
        return "Reaccion sobre daño entrante: limitacion del modelo de red."
    elseif has("ventaja en", "con ventaja", "desventaja en") then
        return "Ventaja/desventaja situacional: no hay efecto de ventaja pasiva."
    elseif has("doble de tu bono de competencia", "doble bono de competencia", "competente y sumas el doble", "la mitad de tu bono de competencia") then
        return "Pericia situacional (solo en cierto tipo de pruebas)."
    elseif has("terreno dificil", "velocidad", "salto", "categoria de tamano", "tamano mayor", "altitudes", "altura", "volar", "vuelo") then
        return "Movimiento/tamaño/terreno: no modelado."
    elseif has("herramientas") then
        return "Competencia de herramienta (situacional/no aplicada)."
    elseif has("1 vez por turno", "una vez por turno", "1 vez al turno") then
        return "Limite por turno: el tracker de usos es por descanso, no por turno."
    end
    return "Rasgo narrativo o situacional sin mecanica aplicable."
end

-- Las 12 clases viven en DnD/Data/Classes/*.lua y se APILAN aqui al cargarse. El orden lo
-- fija el .toc; cada fichero de clase se basta a si mismo e incluye su propio generador de
-- rasgos derivados. Los rasgos derivados COMUNES a todas las clases (Competencias de clase)
-- se construyen en HarfordDnDBookDerived.lua, que carga el ultimo.
API.CLASSES = {}


local classById, classOrder

local SUBCLASS_ID_ALIASES = {
    paladin = {
        retribucion = "represion",
        reprension = "represion",
    },
}

local SUBCLASS_TEXT_ALIASES = {
    paladin = {
        retribucion = "represion",
        reprension = "represion",
    },
}

local function Normalize(value)
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))  -- parentesis: gsub devuelve 2 valores
end

local function NormalizeSubclassId(classId, subclassId)
    classId = tostring(classId or "")
    subclassId = tostring(subclassId or "")
    local aliases = SUBCLASS_ID_ALIASES[classId]
    return (aliases and aliases[subclassId]) or subclassId
end

-- Variante en MASCULINO de un texto ya normalizado (sin acentos, minusculas). Sirve para
-- que los nombres en FEMENINO del About TRP3 (Maga, Bruja, Picara, Guerrera, Sacerdotisa,
-- Cazadora, Forajida...) resuelvan a su clase/subclase canonica (masculina). Se usa SOLO
-- como fallback: el texto original se prueba primero, asi no rompe nombres canonicos que
-- acaban en 'a' (Escarcha, Ira, Sutileza, Restauracion...).
local GENDER_ALIAS = {
    sacerdotisa = "sacerdote", cazadora = "cazador", luchadora = "luchador",
    hechicera = "hechicero", guerrera = "guerrero", druidesa = "druida",
}
-- Palabras funcionales que NO se masculinizan (si no, "la"->"lo" rompe "Elfa de la Noche").
local GENDER_STOP = { la = true, las = true, una = true, unas = true, de = true,
    del = true, el = true, los = true, ["a"] = true, ["y"] = true, en = true }
local function Masculinize(normalized)
    return (tostring(normalized or ""):gsub("%a+", function(w)
        if GENDER_ALIAS[w] then return GENDER_ALIAS[w] end
        if GENDER_STOP[w] then return w end
        return (w:gsub("a$", "o"))  -- 'a' final de palabra -> 'o'
    end))
end

-- El indice se invalida si han entrado clases nuevas. Necesario desde que cada clase vive en su
-- fichero: la primera que consulta el indice (su generador llama a GetClass) lo cacheaba con las
-- clases cargadas HASTA ESE MOMENTO, y las siguientes no aparecian. No daba error: sus generadores
-- recibian nil y no creaban ningun rasgo, en silencio.
local classCount = 0
local function EnsureIndex()
    if classById and classCount == #API.CLASSES then return end
    classCount = #API.CLASSES
    classById, classOrder = {}, {}
    for _, classDef in ipairs(API.CLASSES) do
        classById[classDef.id] = classDef
        classOrder[#classOrder + 1] = classDef.id
    end
end

function API.GetClasses()
    EnsureIndex()
    return API.CLASSES
end

function API.GetClass(classId)
    EnsureIndex()
    return classById[tostring(classId or "")]
end

function API.GetClassOrder()
    EnsureIndex()
    return classOrder
end

function API.GetSubclass(classId, subclassId)
    local classDef = API.GetClass(classId)
    if not classDef then return nil end
    subclassId = NormalizeSubclassId(classId, subclassId)
    for _, subclass in ipairs(classDef.subclasses or {}) do
        if subclass.id == subclassId then return subclass end
    end
    return nil
end

function API.NormalizeSubclassId(classId, subclassId)
    return NormalizeSubclassId(classId, subclassId)
end

function API.GetDefaultSubclassId(classId)
    local classDef = API.GetClass(classId)
    local first = classDef and classDef.subclasses and classDef.subclasses[1]
    return first and first.id or ""
end

function API.GetSubclassUnlockLevel(classId)
    local classDef = API.GetClass(classId)
    local best
    for _, subclass in ipairs((classDef and classDef.subclasses) or {}) do
        for _, feature in ipairs(subclass.features or {}) do
            local level = tonumber(feature.level)
            if level and (not best or level < best) then
                best = level
            end
        end
    end
    return best
end

function API.FindClassIdByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil end
    EnsureIndex()
    local masc = Masculinize(clean)
    for _, classDef in ipairs(API.CLASSES) do
        local n, i = Normalize(classDef.name), Normalize(classDef.id)
        if clean:find(n, 1, true) or clean:find(i, 1, true)
            or (masc ~= clean and (masc:find(n, 1, true) or masc:find(i, 1, true)))
        then
            return classDef.id
        end
    end
    return nil
end

function API.FindSubclassIdByText(classId, text)
    local classDef = API.GetClass(classId)
    local clean = Normalize(text)
    if not classDef or clean == "" then return nil end
    local masc = Masculinize(clean)
    local bestId, bestLen
    for _, subclass in ipairs(classDef.subclasses or {}) do
        local candidates = { subclass.id, subclass.name }
        local aliases = SUBCLASS_TEXT_ALIASES[classDef.id]
        if aliases then
            for alias, targetId in pairs(aliases) do
                if targetId == subclass.id then
                    candidates[#candidates + 1] = alias
                end
            end
        end
        local normalizedName = Normalize(subclass.name)
        -- Muchas especializaciones del libro usan prefijos ("Camino de",
        -- "Marca de", "Presencia de"). El About TRP3 suele escribir solo el
        -- nombre jugable, asi que probamos tambien la ultima palabra relevante.
        local tail = normalizedName:match("([^%s]+)$")
        if tail and tail ~= normalizedName then
            candidates[#candidates + 1] = tail
        end
        for _, candidate in ipairs(candidates) do
            local normalized = Normalize(candidate)
            -- original primero; fallback en masculino para subclases escritas en femenino
            -- (Forajida->forajido, etc.). Las subclases canonicas acabadas en 'a' (Escarcha,
            -- Sutileza, Ira...) casan con el texto original, no con la variante.
            if normalized ~= "" and (clean:find(normalized, 1, true)
                or (masc ~= clean and masc:find(normalized, 1, true))) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = subclass.id, len
                end
            end
        end
    end
    return bestId
end

function API.GetClassName(classId)
    local classDef = API.GetClass(classId)
    return classDef and classDef.name or tostring(classId or "")
end

function API.GetSubclassName(classId, subclassId)
    local subclass = API.GetSubclass(classId, subclassId)
    return subclass and subclass.name or ""
end

-- Resuelve la lista de opciones de un rasgo con `choice`. Devuelve { {id,label,effects}, ... }.
-- `choice.options` se usa tal cual; `choice.optionsFrom` genera la lista desde datos:
--   "ability+1"      -> cada caracteristica como +1 (ASI).
--   "skillProf"      -> cada habilidad como competencia.
--   "skillExpertise" -> cada habilidad como pericia (x2).
function API.GetChoiceOptions(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return nil end

    -- Trucos de una clase, desde el compendio. Cada truco es una opcion con su `spellId`, para
    -- que la eleccion sea el truco CONCRETO y no un "elige un truco" sin resolver.
    local function CantripsDe(className)
        local C = _G.HarfordCompendioAPI
        if not (C and C.GetAllSpells) then return {} end
        local out = {}
        for _, spell in ipairs(C.GetAllSpells() or {}) do
            if (tonumber(spell.level) or 0) == 0 then
                for _, cn in ipairs(spell.classes or {}) do
                    if cn == className then
                        out[#out + 1] = {
                            id = "truco_" .. tostring(spell.id),
                            label = tostring(spell.name or spell.id),
                            spellId = spell.id,
                            effects = {},
                        }
                        break
                    end
                end
            end
        end
        table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
        return out
    end

    if type(choice.options) == "table" then
        -- CATEGORIAS del catalogo de herramientas dentro de opciones literales: muchos trasfondos
        -- declaran "her_instrumento"/"her_juego" como UNA opcion, pero son categorias y se elige
        -- un miembro concreto (laud, dados...). Se expanden AQUI, en el unico punto por el que
        -- pasan todas las listas, en una COPIA (la tabla del libro es compartida).
        local function Expandir(lista)
            local hayCategoria = false
            for _, o in ipairs(lista) do
                if o.id == "her_instrumento" or o.id == "her_juego" then hayCategoria = true break end
            end
            if not hayCategoria then return lista end
            local fuera = {}
            for _, o in ipairs(lista) do
                if o.id == "her_instrumento" or o.id == "her_juego" then
                    local marca = o.id == "her_instrumento" and "instrumento" or "juego"
                    for _, tool in ipairs((HarfordDnDData and HarfordDnDData.TOOLS) or {}) do
                        if tool[marca] then
                            fuera[#fuera + 1] = {
                                id = tool.id, label = tool.name or tool.id,
                                effects = { { kind = "toolProf", tool = tool.name or tool.id } },
                            }
                        end
                    end
                else
                    fuera[#fuera + 1] = o
                end
            end
            return fuera
        end
        local extra = tostring(choice.extraFrom or ""):match("^cantrip:(.+)$")
        if not extra then return Expandir(choice.options) end
        -- Copia: no se toca la tabla del libro, que es compartida.
        local combinadas = {}
        for _, o in ipairs(Expandir(choice.options)) do combinadas[#combinadas + 1] = o end
        for _, o in ipairs(CantripsDe(extra)) do combinadas[#combinadas + 1] = o end
        return combinadas
    end

    local from = tostring(choice.optionsFrom or "")
    local out = {}
    -- "ability+N": cada caracteristica como +N (ASI usa +1; razas usan +2 o +1).
    local abilInc = from:match("^ability%+(%d+)$")
    if abilInc and HarfordDnDData and HarfordDnDData.ABIL then
        local value = tonumber(abilInc) or 1
        for _, abil in ipairs(HarfordDnDData.ABIL) do
            out[#out + 1] = {
                id = abil.key, label = abil.key .. " +" .. value,
                effects = { { kind = "bonus", target = "ability", ability = abil.key, value = value } },
            }
        end
    end
    if abilInc and choice.allowFeat and HarfordDnDFeats and HarfordDnDFeats.GetFeats then
        -- Las dotes, detras de las caracteristicas y marcadas con `feat` para que el dialogo las
        -- trate como excluyentes. Sin `effects`: lo que aplica la dote son sus propios rasgos,
        -- que llegan por `progression.feats` -> `GetFeatTraits`.
        for _, featDef in ipairs(HarfordDnDFeats.GetFeats() or {}) do
            out[#out + 1] = {
                id = "dote_" .. tostring(featDef.id),
                label = "Dote: " .. tostring(featDef.name or featDef.id),
                feat = featDef.id,
                effects = {},
            }
        end
    end
    if abilInc then return out end

    -- Elecciones que pertenecen a la BESTIA companera del Cazador: se registran para que el
    -- jugador las tenga anotadas y visibles, pero NO llevan efectos, porque no son suyas. El
    -- bloque de la bestia lo mantiene el jugador en su TRP3; aplicarlas aqui las contaria dos veces.
    if from == "beastSkill" and HarfordDnDData and HarfordDnDData.SKILLS then
        for _, skill in ipairs(HarfordDnDData.SKILLS) do
            out[#out + 1] = { id = "bestia_" .. tostring(skill.id), label = skill.name or skill.id, effects = {} }
        end
        return out
    end
    if from == "beastAbility" and HarfordDnDData and HarfordDnDData.ABIL then
        for _, abil in ipairs(HarfordDnDData.ABIL) do
            out[#out + 1] = { id = "bestia_" .. tostring(abil.key), label = abil.key .. " +1", effects = {} }
        end
        return out
    end

    if (from == "skillProf" or from == "skillExpertise") and HarfordDnDData and HarfordDnDData.SKILLS then
        local kind = (from == "skillExpertise") and "skillExpertise" or "skillProf"
        for _, skill in ipairs(HarfordDnDData.SKILLS) do
            out[#out + 1] = {
                id = skill.id, label = skill.name or skill.id,
                effects = { { kind = kind, skill = skill.id } },
            }
        end
    elseif from == "language" and HarfordDnDData and HarfordDnDData.LANGUAGES then
        -- Un idioma a elegir. `choice.exotic` decide si entran los exoticos; por defecto no,
        -- que es lo que dan raza y trasfondo ("un idioma adicional de tu eleccion").
        local permiteExoticos = choice.exotic and true or false
        for _, lang in ipairs(HarfordDnDData.LANGUAGES) do
            if permiteExoticos or not lang.exotic then
                out[#out + 1] = {
                    id = "idioma_" .. tostring(lang.id),
                    label = tostring(lang.name or lang.id),
                    effects = { { kind = "language", language = tostring(lang.name or lang.id) } },
                }
            end
        end
    elseif from == "artisanTool" and HarfordDnDData and HarfordDnDData.TOOLS then
        -- "Un tipo de herramientas de artesano o un instrumento musical" (Monje). Las marcadas
        -- `artisan` mas los INSTRUMENTOS CONCRETOS: "instrumento musical" es una categoria y se
        -- elige uno de verdad (laud, flauta...), no la categoria entera. No entran kits, ladron,
        -- juegos ni vehiculos.
        for _, tool in ipairs(HarfordDnDData.TOOLS) do
            if tool.artisan or tool.instrumento then
                out[#out + 1] = {
                    id = tool.id, label = tool.name or tool.id,
                    effects = { { kind = "toolProf", tool = tool.name or tool.id } },
                }
            end
        end
    elseif (from == "instrument" or from == "game" or from == "instrumentOrGame")
        and HarfordDnDData and HarfordDnDData.TOOLS then
        -- Miembro CONCRETO de la categoria: "instrumento musical" lista instrumentos, "juego"
        -- lista juegos (dados, ajedrez, naipes...; la categoria se llama Juego a secas, no
        -- "juego de azar"), y el combinado ambos.
        for _, tool in ipairs(HarfordDnDData.TOOLS) do
            local entra = (from ~= "game" and tool.instrumento) or (from ~= "instrument" and tool.juego)
            if entra then
                out[#out + 1] = {
                    id = tool.id, label = tool.name or tool.id,
                    effects = { { kind = "toolProf", tool = tool.name or tool.id } },
                }
            end
        end
    elseif from == "toolProf" and HarfordDnDData and HarfordDnDData.TOOLS then
        -- Competencia con una herramienta a elegir del catalogo estandar (Prodigio, Artifice, etc.).
        -- Los marcadores de CATEGORIA no son elegibles: se eligen sus miembros concretos.
        for _, tool in ipairs(HarfordDnDData.TOOLS) do
            if not tool.categoria then
                out[#out + 1] = {
                    id = tool.id, label = tool.name or tool.id,
                    effects = { { kind = "toolProf", tool = tool.name or tool.id } },
                }
            end
        end
    else
        return nil
    end
    return out
end

-- Busca una opcion de choice por id dentro de un rasgo.
function API.GetChoiceOption(feature, optionId)
    optionId = tostring(optionId or "")
    if optionId == "" then return nil end
    local opciones = API.GetChoiceOptions(feature) or {}
    for _, opt in ipairs(opciones) do
        if opt.id == optionId then return opt end
    end
    -- Tolerancia de acentos: hubo ids con tilde/enie ("doble_empuñadura") ya guardados en
    -- perfiles antes de normalizarlos a ASCII; sin esto, esa eleccion vieja perderia su efecto.
    local Strip = HarfordClassColors and HarfordClassColors.StripAccents
    if Strip then
        local buscado = Strip(optionId)
        for _, opt in ipairs(opciones) do
            if Strip(tostring(opt.id or "")) == buscado then return opt end
        end
    end
    -- Compatibilidad: perfiles que eligieron la CATEGORIA ("her_instrumento"/"her_juego") antes
    -- de que los selectores la expandieran a miembros concretos. Su eleccion sigue valiendo como
    -- competencia generica de la categoria.
    if optionId == "her_instrumento" then
        return { id = optionId, label = "Instrumento musical",
            effects = { { kind = "toolProf", tool = "Instrumento musical" } } }
    elseif optionId == "her_juego" then
        return { id = optionId, label = "Juego",
            effects = { { kind = "toolProf", tool = "Juego" } } }
    end
    return nil
end

-- Texto completo de cada estilo de combate (las opciones solo llevan label corto; el detalle
-- vive aqui, compartido por todas las clases que ofrecen Estilo de Combate).
local COMBAT_STYLE_DESC = {
    defensa             = "Mientras lleves armadura, ganas +1 a la Clase de Armadura.",
    duelo               = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    duelos              = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    ["doble_empuñadura"] = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    gran_arma           = "Con un arma a dos manos (o versatil usada a dos manos), repites los dados de daño que saquen 1 o 2 y usas el nuevo resultado.",
    proteccion          = "Con un escudo, usas tu reaccion para imponer desventaja a un atacante (a 5 pies) que ataque a otro objetivo distinto de ti.",
    dos_armas           = "Cuando portas dos armas, puedes agregar tu modificador de habilidad al daño del segundo ataque.",
    tiro_arco           = "Ganas +2 a las tiradas de ataque con armas a distancia.",
    tirador             = "Atacar a distancia estando en cuerpo a cuerpo no te impone desventaja, e ignoras media cobertura y tres cuartos; +1 al ataque a distancia.",
    guerrero_profano    = "Aprendes dos trucos de brujo (lanzados con Carisma); no cuentan en tu limite de trucos.",
    guerrero_bendito    = "Aprendes dos trucos de sacerdote (lanzados con Carisma); no cuentan en tu limite de trucos.",
}

-- Descripcion de la OPCION elegida de un choice (para el tooltip del Libro): usa opt.desc si
-- existe; para Estilo de Combate cae al texto compartido por id. nil si no hay descripcion propia.
function API.GetChoiceOptionDesc(feature, optionId)
    local opt = API.GetChoiceOption(feature, optionId)
    if opt and type(opt.desc) == "string" and opt.desc ~= "" then return opt.desc end
    -- Sin acentos y en minusculas: el rasgo se llama "Estilo de combate" y comparar con
    -- "Estilo de Combate" no casaba en ninguna de las cuatro clases que lo ofrecen.
    local nombre = tostring(feature and feature.name or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        nombre = HarfordClassColors.StripAccents(nombre)
    end
    if nombre:lower():find("estilo de combate", 1, true) then
        return COMBAT_STYLE_DESC[tostring(optionId)]
    end
    return nil
end

-- Numero de slots a elegir de un rasgo con choice (default 1).
function API.GetChoiceSlots(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return 0 end
    return math.max(1, math.floor(tonumber(choice.slots) or 1))
end

function API.GetFeature(featureId)
    featureId = tostring(featureId or "")
    for _, classDef in ipairs(API.CLASSES) do
        for _, feature in ipairs(classDef.features or {}) do
            if feature.id == featureId then
                return feature, classDef
            end
        end
    end
    return nil
end

function API.GetUnlockedFeatures(classLevels)
    local out = {}
    for _, entry in ipairs(classLevels or {}) do
        local classDef = API.GetClass(entry.classId)
        local level = tonumber(entry.level) or 0
        if classDef and level > 0 then
            for _, feature in ipairs(classDef.features or {}) do
                if (tonumber(feature.level) or 0) <= level then
                    out[#out + 1] = {
                        classId = classDef.id,
                        className = classDef.name,
                        subclassId = entry.subclassId,
                        level = feature.level,
                        feature = feature,
                    }
                end
            end
            -- Rasgos de la subclase (especializacion) SELECCIONADA, por nivel.
            local subclass = API.GetSubclass(classDef.id, entry.subclassId)
            if subclass then
                for _, feature in ipairs(subclass.features or {}) do
                    if (tonumber(feature.level) or 0) <= level then
                        out[#out + 1] = {
                            classId = classDef.id,
                            className = (classDef.name or "") .. " / " .. (subclass.name or ""),
                            subclassId = entry.subclassId,
                            level = feature.level,
                            feature = feature,
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.className or "") ~= (b.className or "") then return (a.className or "") < (b.className or "") end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return tostring(a.feature and a.feature.name or "") < tostring(b.feature and b.feature.name or "")
    end)
    return out
end


-- Construye el efecto `energyManeuver` de una opcion elegible. SIN esto, un rasgo generado con
-- `effects = {}` se clasifica como PASIVO (el clasificador exige un efecto energyManeuver para
-- devolver "maniobra"), asi que salia como tooltip y no se podia ejecutar.
function API.ManeuverEffects(opcion, recurso)
    local man = opcion and opcion.maneuver
    if type(man) ~= "table" then return {} end
    local efecto = { kind = "energyManeuver", resource = recurso }
    for _, campo in ipairs({ "cost", "attack", "spendOnHit", "save", "outcome", "dcAbility",
        "onFailAura", "onHitAura", "conditionId", "conditionDuration", "conditionTurns",
        "damageDie", "damageType", "levelCost", "minLevel", "maxLevel", "noTarget", "skill" }) do
        if man[campo] ~= nil then efecto[campo] = man[campo] end
    end
    return { efecto }
end


