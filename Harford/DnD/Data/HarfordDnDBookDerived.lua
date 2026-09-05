-- Rasgos derivados COMUNES a todas las clases. Carga el ULTIMO: necesita que las 12 clases
-- de DnD/Data/Classes ya esten apiladas en API.CLASSES.
--
-- Los rasgos derivados de UNA clase concreta (maniobras del Guerrero, Maldiciones del Brujo,
-- Ataques con Armas del Chaman, Palabras de Poder del Sacerdote) viven en su propio fichero
-- de clase, que se basta a si mismo.

local API = HarfordDnDBook

-- Competencias de habilidad de clase: se genera un rasgo de eleccion a nivel 1 desde
-- `skillChoices`/`skillOptions`. Solo para las clases que declaren ese dato; el resto no genera
-- nada hasta que se revisen contra su manual.
do
    for _, clase in ipairs((API.GetClasses and API.GetClasses()) or {}) do
        local cuantas = tonumber(clase.skillChoices) or 0
        local lista = clase.skillOptions
        if cuantas > 0 and type(lista) == "table" and #lista > 0 then
            local opciones = {}
            for _, skillId in ipairs(lista) do
                local nombre, regla = skillId, ""
                for _, sk in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
                    if sk.id == skillId then
                        nombre = sk.name or skillId
                        -- La descripcion real de la habilidad: es la "regla" que muestran el
                        -- tooltip del selector y el About.
                        regla = tostring(sk.desc or "")
                        break
                    end
                end
                opciones[#opciones + 1] = {
                    id = skillId, label = nombre, desc = regla,
                    effects = { { kind = "skillProf", skill = skillId } },
                }
            end
            table.insert(clase.features, 1, {
                id = clase.id .. "_competencias_clase",
                level = 1,
                -- NO "Competencias" a secas: ese nombre lo reconoce `IsAggregatedFeature` como
                -- la entrada fija de General (el listado agregado) y el tooltip mostraria eso en
                -- lugar de la eleccion.
                name = "Competencias de clase",
                type = "choice",
                icon = "inv_scroll_11",  -- el mismo arte que la entrada agregada Competencias
                description = "Elige " .. cuantas .. " habilidades de la lista de tu clase.",
                effects = {},
                -- Regla de multiclase: la eleccion COMPLETA solo la da la clase INICIAL. La
                -- puerta la aplican Progression.GetUnlockedFeatures, el Libro y el asistente.
                onlyFirstClass = true,
                choice = { slots = cuantas, options = opciones },
            })
        end
        -- Variante MULTICLASE (seccion "Multiclase" del manual, `clase.multiclass`): al entrar
        -- en la clase sin ser la inicial se recibe UNA habilidad de su lista (skillChoices = 1;
        -- Cazador, Sacerdote, Picaro, Brujo) o una FIJA (skillFixed; Druida: Naturaleza).
        -- Las clases sin ese dato no generan nada, que es lo que dice su manual.
        local multi = clase.multiclass
        if multi and (tonumber(multi.skillChoices) or 0) > 0
            and cuantas > 0 and type(lista) == "table" and #lista > 0 then
            local opciones = {}
            for _, skillId in ipairs(lista) do
                local nombre, regla = skillId, ""
                for _, sk in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
                    if sk.id == skillId then
                        nombre = sk.name or skillId
                        -- La descripcion real de la habilidad: es la "regla" que muestran el
                        -- tooltip del selector y el About.
                        regla = tostring(sk.desc or "")
                        break
                    end
                end
                opciones[#opciones + 1] = {
                    id = skillId, label = nombre, desc = regla,
                    effects = { { kind = "skillProf", skill = skillId } },
                }
            end
            table.insert(clase.features, 2, {
                id = clase.id .. "_competencias_multiclase",
                level = 1,
                name = "Competencias de multiclase",
                type = "choice",
                icon = "inv_scroll_11",
                description = "Multiclase: elige " .. tostring(multi.skillChoices)
                    .. " habilidad de la lista de la clase.",
                effects = {},
                onlyMulticlass = true,
                choice = { slots = tonumber(multi.skillChoices) or 1, options = opciones },
            })
        elseif multi and type(multi.skillFixed) == "table" and #multi.skillFixed > 0 then
            local efectos, nombres = {}, {}
            for _, skillId in ipairs(multi.skillFixed) do
                efectos[#efectos + 1] = { kind = "skillProf", skill = skillId }
                local nombre = skillId
                for _, sk in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
                    if sk.id == skillId then nombre = sk.name or skillId break end
                end
                nombres[#nombres + 1] = nombre
            end
            table.insert(clase.features, 2, {
                id = clase.id .. "_competencias_multiclase",
                level = 1,
                name = "Competencias de multiclase",
                type = "pasivo",
                icon = "inv_scroll_11",
                description = "Multiclase: obtienes la habilidad " .. table.concat(nombres, ", ") .. ".",
                onlyMulticlass = true,
                effects = efectos,
            })
        end
    end
end
