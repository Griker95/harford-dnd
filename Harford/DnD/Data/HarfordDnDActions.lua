------------------------------------------------------------
-- HarfordDnDActions - Acciones basicas de combate.
--
-- Esquivar, Correr, Desengancharse y Esconderse las tiene CUALQUIER personaje: no pertenecen a
-- ninguna clase, y por eso viven en su propio catalogo y no coladas en una. El Libro las pinta como
-- entradas fijas de General, igual que Competencias e Idiomas.
--
-- EL COSTE NO ES FIJO. Cada accion declara el suyo BASE, y un rasgo de clase puede abrirla a otro:
-- la Accion Astuta del Picaro permite Correr, Desengancharse y Esconderse como accion adicional.
-- El rasgo no duplica la accion, la REFERENCIA por id -- si duplicara, el dia que cambie una habria
-- dos versiones y solo una se actualizaria.
--
-- LOS ICONOS NO ESTAN AQUI. Van en `HarfordIconCatalog`, con el id que el Libro les da
-- (`harford_accion_<id>`), que es la fuente unica de arte del proyecto. Declararlos tambien aqui
-- crearia una segunda version que dejaria de coincidir en cuanto se tocara una de las dos.
--
-- Lo que una accion HACE es otra cosa que lo que CUESTA. Esquivar tiene efecto mecanico completo
-- (su estado ya existe); Correr y Desengancharse no, porque el addon no lleva presupuesto de
-- movimiento ni ataques de oportunidad. Su coste si se cuenta, que es lo que da sentido a los
-- rasgos que las abren. `sinEfecto` lo dice explicitamente para no venderlas como algo que no son.
------------------------------------------------------------

HarfordDnDActions = HarfordDnDActions or {}
local API = HarfordDnDActions

API.DEFS = {
    esquivar = {
        id = "esquivar", name = "Esquivar",
        cast = "accion", orden = 1,
        description = "Hasta el inicio de tu proximo turno, las tiradas de ataque contra ti se hacen "
            .. "con desventaja si puedes ver al atacante, y tus salvaciones de Destreza tienen ventaja.",
        selfCondition = { id = "esquivando", duration = "source_turn_start" },
    },
    correr = {
        id = "correr", name = "Correr",
        cast = "accion", orden = 2,
        description = "Ganas movimiento adicional igual a tu velocidad en este turno.",
        sinEfecto = "El movimiento se lleva en mesa: Harford no cuenta cuanto te queda por moverte.",
    },
    desengancharse = {
        id = "desengancharse", name = "Desengancharse",
        cast = "accion", orden = 3,
        description = "Tu movimiento no provoca ataques de oportunidad durante el resto del turno.",
        sinEfecto = "Los ataques de oportunidad se llevan en mesa: Harford no sabe quien esta trabado con quien.",
    },
    esconderse = {
        id = "esconderse", name = "Esconderse",
        cast = "accion", orden = 4,
        description = "Haces una prueba de Sigilo para ocultarte.",
        -- Sin CD: la de esconderse es la Percepcion pasiva de quien mira, que este cliente no
        -- conoce. Se tira y decide la mesa; inventarse un numero seria peor que no ponerlo.
        skillCheck = { skill = "Sigilo" },
    },
    agarrar = {
        id = "agarrar", name = "Agarrar",
        cast = "accion", orden = 5,
        description = "Prueba de Atletismo contra el Atletismo o la Acrobacias del objetivo. "
            .. "Si ganas, queda Agarrado: su velocidad pasa a 0.",
        -- `against` lleva las DOS: en una tirada enfrentada elige el defensor, no el atacante.
        contest = { skill = "Atletismo", ability = "Fuerza",
            against = { "Atletismo", "Acrobacias" }, onWin = "grappled" },
    },
    empujar = {
        id = "empujar", name = "Empujar",
        cast = "accion", orden = 6,
        description = "Misma prueba enfrentada. Si ganas, lo derribas o lo apartas 1,5 metros.",
        -- Derribar o apartar se decide ANTES de tirar, que es cuando lo decide el manual, y solo
        -- derribar deja estado: apartar mueve, y el movimiento se lleva en mesa.
        contest = { skill = "Atletismo", ability = "Fuerza",
            against = { "Atletismo", "Acrobacias" }, onWin = "prone",
            options = {
                { label = "Derribar", conditionId = "prone" },
                { label = "Apartar 1,5 m", conditionId = false },
            } },
    },
    ayudar = {
        id = "ayudar", name = "Ayudar",
        cast = "accion", orden = 7,
        description = "Un aliado tira con ventaja su proxima prueba de caracteristica, o su proximo "
            .. "ataque contra una criatura a la que distraes.",
        sinEfecto = "Harford aun no sabe conceder ventaja a OTRO: que la aplique el quien la reciba.",
    },
    estabilizar = {
        id = "estabilizar", name = "Estabilizar",
        cast = "accion", orden = 8,
        description = "Prueba de Medicina CD 10 sobre una criatura a 0 puntos de golpe. Si la superas, "
            .. "queda estable: deja de tirar salvaciones de muerte.",
        -- La UNICA de las nuevas con CD fija en el manual, asi que se resuelve entera aqui.
        skillCheck = { skill = "Medicina", dc = 10 },
    },
    lanzar_arma = {
        id = "lanzar_arma", name = "Lanzar arma",
        cast = "accion", orden = 9,
        description = "Lanzas un arma arrojadiza contra un objetivo a distancia.",
        sinEfecto = "Usa el ataque normal de la ficha con el arma arrojadiza equipada.",
    },
    preparar = {
        id = "preparar", name = "Preparar",
        cast = "accion", orden = 10,
        description = "Eliges una accion y un disparador. Cuando ocurra, la ejecutas gastando tu reaccion.",
        sinEfecto = "Gasta la accion ahora; el disparador y la reaccion los lleva la mesa.",
    },
}

function API.Get(actionId)
    return API.DEFS[tostring(actionId or "")]
end

-- En el orden en que se presentan, que es el del manual y no el alfabetico.
function API.GetOrdered()
    local fuera = {}
    for _, def in pairs(API.DEFS) do fuera[#fuera + 1] = def end
    table.sort(fuera, function(a, b)
        local oa, ob = tonumber(a.orden) or 99, tonumber(b.orden) or 99
        if oa ~= ob then return oa < ob end
        return tostring(a.name) < tostring(b.name)
    end)
    return fuera
end

-- Costes con los que ESTE personaje puede usar la accion: el base, mas los que le abra algun rasgo.
-- Devuelve una lista de { cast, porRasgo, resourceKey, resourceCost }, con el base el primero.
--
-- `data` es la progresion ya resuelta (la misma que recibe el Libro), para no volver a mirarla.
function API.CostsFor(actionId, rasgos)
    local def = API.Get(actionId)
    if not def then return {} end
    local fuera = { { cast = def.cast } }
    local vistos = { [tostring(def.cast)] = true }
    for _, feature in ipairs(rasgos or {}) do
        local abre = feature and feature.grantsAsBonus
        if type(abre) == "table" then
            for _, id in ipairs(abre) do
                if tostring(id) == tostring(actionId) and not vistos["accion_adicional"] then
                    vistos["accion_adicional"] = true
                    fuera[#fuera + 1] = {
                        cast = "accion_adicional",
                        porRasgo = feature.name,
                        resourceKey = feature.resourceKey,
                        resourceCost = feature.resourceCost,
                    }
                end
            end
        end
    end
    return fuera
end
