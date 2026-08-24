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
                local nombre = skillId
                for _, sk in ipairs((HarfordDnDData and HarfordDnDData.SKILLS) or {}) do
                    if sk.id == skillId then nombre = sk.name or skillId break end
                end
                opciones[#opciones + 1] = {
                    id = skillId, label = nombre,
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
                description = "Elige " .. cuantas .. " habilidades de la lista de tu clase.",
                effects = {},
                choice = { slots = cuantas, options = opciones },
            })
        end
    end
end
