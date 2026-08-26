-- HarfordDnDConditions: catalogo y motor de condiciones de combate.
-- Las auras son la fuente de verdad cuando contienen toda la informacion. Solo
-- se guarda estado cuando hacen falta metadatos (fuente/duracion/CD) o no existe
-- una aura visual conocida.

HarfordDnDConditions = HarfordDnDConditions or {}
local API = HarfordDnDConditions

local PREFIX = "DND5EARC"
local AURA_GRACE = 2
local REMOTE_TTL = 600
local EsNpcDeLosTurnos   -- se asigna abajo; el guardia de efectos delegados la usa antes
local REQUEST_TTL = 60
local MAX_STATES_PER_UNIT = 32

API.ORDER = {
    "blinded", "charmed", "deafened", "frightened", "grappled",
    "incapacitated", "invisible", "paralyzed", "petrified", "poisoned",
    "prone", "restrained", "stunned", "sleeping", "silenced", "rooted", "slowed",
    "disarmed", "exposed_armor", "burning", "frozen", "chilled", "blessed",
    "bioluminescence", "dancing_lights", "elunes_grace", "exhaustion", "piel_hierro", "imprudente", "escudo_sagrado", "veredicto", "apartado", "buey_negro", "esquivando", "circulo_demoniaco",
    "piedra_salud", "piedra_fuego", "piedra_conjuro", "piedra_alma",
}

API.DEFS = {
    -- Guerrero "Ira desatada": no es una condicion del manual sino el estado que deja el rasgo.
    -- Se modela como condicion porque el motor ya sabe hacer las dos mitades a la vez: ventaja en
    -- tus ataques y ventaja en los ataques CONTRA ti.
    unleashed_rage = {
        label = "Ira desatada", tracking = "state",
        description = "Ventaja en tus ataques cuerpo a cuerpo con Fuerza; los ataques contra ti tambien tienen ventaja hasta tu proximo turno.",
        effects = {
            { kind = "rollMode", rolls = { attack = true }, mode = "adv" },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
        },
    },
    -- PIEDRAS DE ALMA del Brujo (Forja de almas). No conceden nada por si mismas: representan que
    -- LLEVAS la piedra encima, que es lo que hace que forjarla y gastarla sean dos momentos. Sin
    -- este estado la segunda mitad del rasgo no tendria donde vivir: Harford no tiene inventario
    -- para un objeto asi. Duran hasta que las gastas, por eso no caducan.
    piedra_salud = {
        label = "Piedra de Salud", tracking = "state",
        description = "Llevas una Piedra de Salud. Al aplastarla, tu o quien la tenga recupera puntos de golpe.",
        effects = {},
    },
    piedra_fuego = {
        label = "Piedra de Fuego", tracking = "state",
        description = "Llevas una Piedra de Fuego. Gastala al lanzar un conjuro de brujo.",
        effects = {},
    },
    piedra_conjuro = {
        label = "Piedra de Conjuro", tracking = "state",
        description = "Llevas una Piedra de Conjuro. Gastala al lanzar un conjuro de brujo.",
        effects = {},
    },
    piedra_alma = {
        label = "Piedra de Alma", tracking = "state",
        description = "Llevas una Piedra de Alma. Gastala para lanzar reanimar, o se gasta sola si caes a 0 puntos de golpe.",
        effects = {},
    },
    -- ESQUIVAR. No es de ninguna clase: es la accion basica del manual, y esta aqui porque hay
    -- rasgos que la conceden como accion adicional (Danza Elusiva del Monje). Dura hasta el inicio
    -- de tu proximo turno.
    esquivando = {
        label = "Esquivando", tracking = "state",
        description = "Los ataques contra ti se hacen con desventaja y tus salvaciones de Destreza tienen ventaja.",
        effects = {
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "dis" },
            { kind = "rollMode", rolls = { save = true }, ability = "Destreza", mode = "adv" },
        },
    },
    -- Brujo "Circulo demoniaco". La ventaja es solo MIENTRAS SIGAS DENTRO, y el cliente no sabe
    -- donde estas: por eso dura `manual` y lo retira el jugador al salir. Se ve en su lista de
    -- estados, que es lo unico que evita que se quede puesto sin querer.
    circulo_demoniaco = {
        label = "Circulo demoniaco", tracking = "state",
        description = "Ventaja en los chequeos de concentracion mientras permanezcas dentro del circulo.",
        effects = { { kind = "rollMode", rolls = { save = true }, ability = "Constitucion", mode = "adv" } },
    },
    -- Ayudar. Son DOS estados y no uno con dos efectos porque en el manual son dos usos distintos
    -- de la accion: o ayudas en una prueba, o distraes a una criatura para el ataque de un aliado.
    -- Quien ayuda declara cual, y con un solo estado la ventaja se gastaria en la primera tirada
    -- que hiciera el ayudado, que casi nunca seria la que le prometieron.
    ayudado_prueba = {
        label = "Ayudado", tracking = "state",
        description = "Ventaja en tu proxima prueba de caracteristica.",
        effects = { { kind = "rollMode", rolls = { ability = true }, mode = "adv" } },
        consumeAfterRoll = { ability = true },
    },
    ayudado_ataque = {
        label = "Ayudado en el ataque", tracking = "state",
        description = "Ventaja en tu proximo ataque contra la criatura distraida.",
        effects = { { kind = "rollMode", rolls = { attack = true }, mode = "adv" } },
        consumeAfterRoll = { attack = true },
    },
    -- Preparar. NO da efecto mecanico ninguno, y es a proposito: preparar no concede nada, solo
    -- adelanta una accion para gastarla con la reaccion cuando ocurra el disparador. El estado
    -- existe para que se VEA que la tienes preparada -- en tu tira y en la del resto -- y para
    -- saber que hay algo que disparar. El disparador lo reconoce la mesa, no el cliente.
    preparado = {
        label = "Accion preparada", tracking = "state",
        description = "Tienes una accion preparada. Cuando ocurra el disparador, gastas tu reaccion "
            .. "para ejecutarla.",
        effects = {},
    },
    -- Monje "Brebaje del Buey Negro". Es ventaja en el PROXIMO ataque, no durante un minuto: se
    -- gasta al tirar (`consumeAfterRoll`), y el minuto es solo el plazo para usarlo.
    buey_negro = {
        label = "Buey negro", tracking = "state",
        description = "Ventaja en tu proximo ataque cuerpo a cuerpo.",
        effects = { { kind = "rollMode", rolls = { attack = true }, mode = "adv" } },
        consumeAfterRoll = { attack = true },
    },
    -- Paladin "Escudo Sagrado" (Proteccion). El dano de represalia de 1d6 + medio nivel se queda
    -- fuera: es una reaccion al ataque recibido y el cliente no observa ese momento.
    escudo_sagrado = {
        label = "Escudo sagrado", tracking = "state",
        description = "Las tiradas de ataque contra ti se hacen con desventaja.",
        effects = { { kind = "incomingRollMode", rolls = { attack = true }, mode = "dis" } },
    },
    -- Paladin "Veredicto del Templario" (Represion). La ventaja es SOLO para quien lo emitio.
    veredicto = {
        label = "Bajo veredicto", tracking = "state",
        description = "Quien emitio el veredicto tiene ventaja en sus ataques contra la criatura.",
        effects = { { kind = "incomingRollModeFromSource", rolls = { attack = true }, mode = "adv" } },
    },
    -- Paladin "Rechazar lo Profano" (Represion). "Apartado" del manual: la criatura huye y no
    -- puede acercarse. Lo unico que el cliente puede sostener es que no ataque a quien la aparto y
    -- que el efecto acabe al recibir dano; el movimiento se juega en mesa.
    apartado = {
        label = "Apartado", tracking = "state",
        description = "Huye de quien la aparto, no puede acercarsele voluntariamente y no puede atacarle. Termina si recibe dano.",
        effects = { { kind = "blockAttackSource" }, { kind = "breakOnDamage" } },
    },
    -- Brujo "Maldicion de la Imprudencia". Como Ira desatada, pero solo la mitad mala: la victima
    -- no gana nada, solo recibe ataques con ventaja.
    imprudente = {
        label = "Imprudente", tracking = "state",
        description = "Los ataques contra la criatura tienen ventaja.",
        effects = { { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" } },
    },
    -- Monje "Brebaje de Piel de Hierro". No es una condicion del manual, sino el estado que deja
    -- el brebaje durante 1 minuto. Se modela como condicion porque es lo que ya sabe caducar por
    -- rondas y viajar al resto de clientes.
    piel_hierro = {
        label = "Piel de hierro", tracking = "state",
        description = "Resistencia al dano contundente, perforante y cortante de ataques no magicos.",
        effects = {
            { kind = "resistTypes", nonMagical = true,
              types = { "bludgeoning", "piercing", "slashing" } },
        },
    },
    blinded = {
        label = "Cegado", tracking = "state",
        description = "Ataques propios con desventaja; ataques contra la criatura con ventaja.",
        effects = {
            { kind = "rollMode", rolls = { attack = true }, mode = "dis" },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
        },
    },
    charmed = {
        label = "Hechizado", tracking = "state",
        description = "No puede atacar a la fuente que lo hechizo.",
        effects = { { kind = "blockAttackSource" } },
    },
    -- CANSANCIO (PHB, "Estados"). Es la unica condicion con NIVELES: del 1 al 6, y cada uno
    -- arrastra los efectos de los inferiores. El nivel vive en el registro de estado
    -- (`record.level`), y `EffectsFor` expande los efectos hasta ese nivel.
    --   1 Desventaja en pruebas de caracteristica
    --   2 Velocidad reducida a la mitad
    --   3 Desventaja en tiradas de ataque y de salvacion
    --   4 Puntos de golpe maximos reducidos a la mitad
    --   5 Velocidad reducida a 0
    --   6 Muerte
    -- Un descanso largo lo reduce en 1 si la criatura comio y bebio.
    exhaustion = {
        label = "Cansancio", tracking = "state", leveled = true, maxLevel = 6,
        description = "Seis niveles acumulativos; el descanso largo reduce uno.",
        levelEffects = {
            [1] = { { kind = "rollMode", rolls = { ability = true }, mode = "dis" } },
            [2] = { { kind = "speedHalved" } },
            [3] = { { kind = "rollMode", rolls = { attack = true, save = true }, mode = "dis" } },
            [4] = { { kind = "maxHealthHalved" } },
            [5] = { { kind = "speedZero" } },
            [6] = { { kind = "dead" } },
        },
        levelLabels = {
            "Desventaja en pruebas de caracteristica",
            "Velocidad reducida a la mitad",
            "Desventaja en tiradas de ataque y de salvacion",
            "Puntos de golpe maximos reducidos a la mitad",
            "Velocidad reducida a 0",
            "Muerte",
        },
        effects = {},
    },
    elunes_grace = {
        label = "Gracia de Elune", tracking = "state",
        description = "Puede usar Destrabarse, Esquivar u Ocultarse como accion adicional mientras dure la bendicion.",
        -- No es un efecto sobre tiradas, sino sobre la ECONOMIA del turno: abre esas tres
        -- acciones como adicional mientras dure. Se declara igual que en un rasgo (`grantsAsBonus`)
        -- para que el resolutor de costes no tenga que distinguir de donde le llega.
        grantsAsBonus = { "desengancharse", "esquivar", "esconderse" },
        effects = {},
    },
    palabra_fortaleza = {
        label = "Fortaleza", tracking = "state",
        description = "Tiene ventaja en la proxima tirada de salvacion indicada por la Palabra de Poder.",
        effects = { { kind = "rollMode", rolls = { save = true }, mode = "adv" } },
        consumeAfterRoll = { save = true },
    },
    -- Sacerdote Disciplina "Supresion del dolor". Primera condicion CON VALOR: la cantidad que
    -- reduce viaja en `vars.reduccion` (distinta para cada sacerdote), y a QUE tipos afecta es fijo
    -- del rasgo, asi que vive aqui y no en la instancia.
    supresion_dolor = {
        label = "Supresion del dolor", tracking = "state",
        description = "Reduce el dano contundente, perforante y cortante que recibe.",
        damageReduction = { "contundente", "perforante", "cortante" },
        effects = {},
    },
    marca_ignea = {
        label = "Marca ignea", tracking = "state",
        description = "Tiene desventaja en las tiradas de ataque hasta el final de su siguiente turno.",
        effects = { { kind = "rollMode", rolls = { attack = true }, mode = "dis" } },
    },
    palabra_dolor = {
        label = "Dolor", tracking = "state",
        description = "Tiene desventaja en todas las tiradas de ataque hasta el final de su siguiente turno.",
        effects = { { kind = "rollMode", rolls = { attack = true }, mode = "dis" } },
    },
    deafened = {
        label = "Ensordecido", tracking = "state",
        description = "Falla pruebas que dependan exclusivamente del oido.",
        effects = {},
    },
    frightened = {
        label = "Asustado", auraId = 167026, tracking = "aura_state",
        description = "Desventaja en ataques y pruebas mientras persista el miedo.",
        effects = { { kind = "rollMode", rolls = { attack = true, ability = true }, mode = "dis" } },
    },
    grappled = {
        label = "Agarrado", tracking = "state",
        description = "La velocidad pasa a 0.",
        effects = { { kind = "speedZero" } },
    },
    incapacitated = {
        label = "Incapacitado", auraId = 30980, tracking = "aura",
        description = "No puede realizar acciones ni reacciones.",
        effects = {
            { kind = "blockAction", actions = { action = true, reaction = true } },
        },
    },
    invisible = {
        label = "Invisible", tracking = "state",
        description = "Ataques propios con ventaja; ataques contra la criatura con desventaja.",
        effects = {
            { kind = "rollMode", rolls = { attack = true }, mode = "adv" },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "dis" },
        },
    },
    paralyzed = {
        label = "Paralizado", tracking = "state",
        description = "Incapacitado; falla salvaciones de Fuerza y Destreza; ataques recibidos con ventaja.",
        effects = {
            { kind = "blockAction", actions = { action = true, reaction = true } },
            { kind = "autoFailSave", abilities = { Fuerza = true, Destreza = true } },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
            { kind = "speedZero" },
        },
    },
    petrified = {
        label = "Petrificado", auraId = 210138, tracking = "aura",
        description = "Incapacitado, inmovil, falla salvaciones de Fuerza y Destreza y resiste todo dano.",
        effects = {
            { kind = "blockAction", actions = { action = true, reaction = true } },
            { kind = "autoFailSave", abilities = { Fuerza = true, Destreza = true } },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
            { kind = "speedZero" }, { kind = "resistAll" },
        },
    },
    poisoned = {
        label = "Envenenado", auraId = 167407, tracking = "aura",
        description = "Desventaja en tiradas de ataque y pruebas de habilidad.",
        effects = { { kind = "rollMode", rolls = { attack = true, ability = true }, mode = "dis" } },
    },
    -- Orden oscura (Caballero de la Muerte N3): provocacion. La criatura ataca con desventaja a
    -- cualquiera MENOS a quien se la aplico, asi que no vale un `rollMode` normal: penalizaria
    -- tambien los ataques contra el propio caballero, que es lo contrario del rasgo.
    orden_oscura = {
        label = "Orden oscura", tracking = "state",
        description = "Desventaja en ataques contra cualquiera que no sea quien impuso la orden.",
        effects = {
            { kind = "rollModeExceptSource", rolls = { attack = true }, mode = "dis" },
        },
    },
    prone = {
        label = "Derribado", auraId = 267937, tracking = "aura",
        description = "Ataques propios con desventaja; cuerpo a cuerpo contra el objetivo con ventaja y distancia con desventaja.",
        effects = {
            { kind = "rollMode", rolls = { attack = true }, mode = "dis" },
            { kind = "incomingRollMode", rolls = { attack = true }, range = "melee", mode = "adv" },
            { kind = "incomingRollMode", rolls = { attack = true }, range = "ranged", mode = "dis" },
        },
    },
    restrained = {
        label = "Restringido", tracking = "state",
        description = "Velocidad 0; ataques propios y salvaciones de Destreza con desventaja; ataques recibidos con ventaja.",
        effects = {
            { kind = "speedZero" },
            { kind = "rollMode", rolls = { attack = true }, mode = "dis" },
            { kind = "rollMode", rolls = { save = true }, ability = "Destreza", mode = "dis" },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
        },
    },
    stunned = {
        label = "Aturdido", tracking = "state",
        description = "Incapacitado; falla salvaciones de Fuerza y Destreza; ataques recibidos con ventaja.",
        effects = {
            { kind = "blockAction", actions = { action = true, reaction = true } },
            { kind = "autoFailSave", abilities = { Fuerza = true, Destreza = true } },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
            { kind = "speedZero" },
        },
    },
    sleeping = {
        label = "Dormido", tracking = "state", persist = true,
        description = "Incapacitado y derribado; falla salvaciones de Fuerza y Destreza; despierta al recibir dano.",
        effects = {
            { kind = "blockAction", actions = { action = true, reaction = true } },
            { kind = "autoFailSave", abilities = { Fuerza = true, Destreza = true } },
            { kind = "incomingRollMode", rolls = { attack = true }, mode = "adv" },
            { kind = "speedZero" }, { kind = "breakOnDamage" },
        },
    },
    silenced = {
        label = "Silenciado", auraId = 30900, tracking = "aura_state",
        description = "No puede ejecutar acciones marcadas como conjuro verbal.",
        effects = { { kind = "blockAction", actions = { verbal_spell = true } } },
    },
    rooted = {
        label = "Enraizado", auraId = 263196, tracking = "aura",
        description = "La velocidad pasa a 0.", effects = { { kind = "speedZero" } },
    },
    slowed = {
        label = "Ralentizado", tracking = "state",
        description = "La velocidad se reduce a la mitad.",
        effects = {},  -- la media velocidad se aplica de forma narrativa (no hay efecto mecanico de mitad)
    },
    disarmed = {
        label = "Desarmado", auraId = 177714, tracking = "aura",
        description = "No puede realizar ataques con arma mientras mantenga el estado.",
        effects = { { kind = "blockAction", actions = { weapon_attack = true } } },
    },
    exposed_armor = {
        label = "Exponer armadura", auraId = 11971, tracking = "aura_state",
        description = "Estado visual de armadura expuesta; su efecto concreto depende de la habilidad.", effects = {},
    },
    burning = {
        label = "Ardiendo", auraId = 279489, tracking = "aura",
        description = "Estado visual de fuego persistente; el dano debe declararlo la habilidad.", effects = {},
    },
    frozen = {
        label = "Congelado", auraId = 153574, tracking = "aura",
        description = "La velocidad pasa a 0.", effects = { { kind = "speedZero" } },
    },
    chilled = {
        label = "Enfriado", auraId = 287295, tracking = "aura",
        description = "Estado visual de frio; no aplica una penalizacion numerica sin una habilidad que la declare.", effects = {},
    },
    blessed = {
        label = "Bendito", auraId = 232365, tracking = "aura",
        description = "Estado visual; el bonus concreto debe declararlo la habilidad que lo aplica.", effects = {},
    },
    bioluminescence = {
        label = "Bioluminescencia", auraId = 292133, tracking = "aura",
        description = "Estado visual sin modificador mecanico general.", effects = {},
    },
    dancing_lights = {
        label = "Luces danzantes", auraId = 128987, tracking = "aura",
        description = "Estado visual sin modificador mecanico general.", effects = {},
    },
}

-- `API.ORDER` es el orden de PRESENTACION -- el que siguen la tira del unitframe, el menu del DM y
-- la ficha --, pero `GetActive` tambien lo usa para recorrer las condiciones. Eso convertia una
-- lista de presentacion en una lista de existencia: una condicion definida y no listada aqui no
-- aparecia como activa NUNCA, y por tanto sus efectos no se aplicaban jamas. No fallaba, no
-- avisaba y compilaba igual; simplemente no hacia nada.
--
-- Paso por aqui nueve veces, seis de ellas sin que nadie lo notara (Ira desatada, Fortaleza,
-- Supresion del dolor, Marca ignea, Dolor y Orden oscura). Asi que la lista deja de mantenerse a
-- mano: lo declarado ordena lo que le importa y el resto se anade solo, en orden estable. Olvidarse
-- ya no puede apagar una condicion, solo ponerla al final.
do
    local listadas = {}
    for _, id in ipairs(API.ORDER) do listadas[id] = true end
    local resto = {}
    for id in pairs(API.DEFS) do
        if not listadas[id] then resto[#resto + 1] = id end
    end
    table.sort(resto)
    for _, id in ipairs(resto) do API.ORDER[#API.ORDER + 1] = id end
end

API.State = API.State or {
    units = {}, remote = {}, processed = {}, pending = {}, serial = 0,
    listeners = {}, loadedOwned = false, lastTurn = nil,
}
local S = API.State

local function Now()
    return (GetTime and GetTime()) or (time and time()) or 0
end

local function Print(message)
    HarfordChat.Print(message)
end

local function ShortName(name)
    name = tostring(name or "")
    if Ambiguate then return Ambiguate(name, "short") end
    return name:match("^[^%-]+") or name
end

local function IsTrustedSender(sender)
    sender = tostring(sender or "")
    if sender == "" then return false end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(sender) ~= nil
    end
    return ShortName(sender) == ShortName(UnitName and UnitName("player") or "")
end

local function CanonicalAbility(value)
    local key = HarfordClassColors.NormalizeKey(value)
    local aliases = {
        fue = "Fuerza", fuerza = "Fuerza", des = "Destreza", destreza = "Destreza",
        con = "Constitucion", cons = "Constitucion", constitucion = "Constitucion",
        int = "Inteligencia", inteligencia = "Inteligencia", sab = "Sabiduria", sabiduria = "Sabiduria",
        car = "Carisma", carisma = "Carisma",
    }
    return aliases[key] or ""
end

local function PlayerProfileName()
    return (UnitName and UnitName("player")) or "default"
end

local function PersistRoot(create)
    if type(HarfordDnDPersistStore) ~= "table" then
        if not create then return nil end
        HarfordDnDPersistStore = {}
    end
    if create and type(HarfordDnDPersistStore.conditionStates) ~= "table" then
        HarfordDnDPersistStore.conditionStates = {}
    end
    return HarfordDnDPersistStore.conditionStates
end

local NormalizeVars  -- forward: se usa mas arriba de donde se define
local function CopyRecord(record)
    if type(record) ~= "table" then return nil end
    return {
        id = tostring(record.id or ""), sourceGuid = tostring(record.sourceGuid or ""),
        sourceName = tostring(record.sourceName or ""), duration = tostring(record.duration or "manual"),
        turns = math.max(0, math.floor(tonumber(record.turns) or 0)),
        saveAbility = tostring(record.saveAbility or ""), saveDC = math.max(0, math.floor(tonumber(record.saveDC) or 0)),
        targetGuid = tostring(record.targetGuid or ""), targetName = tostring(record.targetName or ""),
        created = tonumber(record.created) or Now(), appliedTurnSerial = tonumber(record.appliedTurnSerial) or 0,
        expiresAt = tonumber(record.expiresAt), persist = record.persist == true,
        authority = record.authority == true,
        -- `level` NO se copiaba: al persistir y recargar, una condicion con niveles (cansancio)
        -- volvia a 1 y sus efectos de nivel 2+ no se aplicaban. Es el mismo fallo que ya se
        -- corrigio al APLICARLA, pero seguia vivo en la ruta de guardado.
        level = record.level and math.max(1, math.floor(tonumber(record.level) or 1)) or nil,
        vars = NormalizeVars(record.vars),
    }
end

-- Variables de una condicion: `{ nombre = numero }`. Es lo que convierte una etiqueta de si/no en
-- algo que lleva una cantidad ("reduce 5") o un contador ("3 acumulaciones"). Solo numeros: el QUE
-- hace la condicion vive en su definicion (`API.DEFS`), la instancia solo lleva CUANTO.
NormalizeVars = function(vars)
    if type(vars) ~= "table" then return nil end
    local out, n = {}, 0
    for nombre, valor in pairs(vars) do
        nombre = tostring(nombre):match("^[%w_]+$")
        valor = tonumber(valor)
        if nombre and valor then out[nombre] = math.floor(valor); n = n + 1 end
    end
    return n > 0 and out or nil
end

local function SaveOwned()
    local root = PersistRoot(true)
    local profile = PlayerProfileName()
    local src = S.units.player or {}
    local out = {}
    for id, record in pairs(src) do
        local def = API.DEFS[id]
        if def and (def.persist or record.persist == true) then out[id] = CopyRecord(record) end
    end
    root[profile] = next(out) and out or nil
    if not next(root) then HarfordDnDPersistStore.conditionStates = nil end
end

local function LoadOwned()
    if S.loadedOwned then return end
    S.loadedOwned = true
    local root = PersistRoot(false)
    local saved = root and root[PlayerProfileName()]
    S.units.player = S.units.player or {}
    for id, record in pairs(type(saved) == "table" and saved or {}) do
        local def = API.DEFS[id]
        if def then
            local copy = CopyRecord(record)
            copy.id = id
            S.units.player[id] = copy
        end
    end
end

local function UnitHasAuraId(unit, spellId)
    spellId = tonumber(spellId)
    if not (unit and spellId and UnitExists and UnitExists(unit)) then return false end
    local findAura = AuraUtil and (AuraUtil.FindAuraBySpellId or AuraUtil.FindAuraBySpellID)
    if findAura then
        if findAura(spellId, unit, "HELPFUL|HARMFUL") then return true end
    end
    if not UnitAura then return false end
    for _, filter in ipairs({ "HARMFUL", "HELPFUL" }) do
        for index = 1, 40 do
            local name, _, _, _, _, _, _, _, _, auraSpellId = UnitAura(unit, index, filter)
            if not name then break end
            if tonumber(auraSpellId) == spellId then return true end
        end
    end
    return false
end
API.UnitHasAuraId = UnitHasAuraId

local function FindUnitByGuid(guid)
    guid = tostring(guid or "")
    if guid == "" or not UnitGUID then return nil end
    local fixed = { "player", "target", "focus", "mouseover", "targettarget", "focustarget" }
    for _, unit in ipairs(fixed) do
        if UnitExists and UnitExists(unit) and UnitGUID(unit) == guid then return unit end
    end
    local group = IsInRaid and IsInRaid() and "raid" or "party"
    local count = group == "raid" and 40 or 4
    for i = 1, count do
        local unit = group .. i
        if UnitExists and UnitExists(unit) and UnitGUID(unit) == guid then return unit end
    end
    return nil
end

local function ResolveRef(ref)
    if type(ref) == "table" then
        local unit = ref.unit
        local guid = tostring(ref.guid or (unit and UnitGUID and UnitGUID(unit)) or "")
        local name = tostring(ref.name or (unit and HarfordClassColors.UnitFullName(unit)) or "")
        return unit, guid, name
    end
    ref = tostring(ref or "player")
    if UnitExists and UnitExists(ref) then
        return ref, tostring(UnitGUID and UnitGUID(ref) or ""),
            tostring(HarfordClassColors.UnitFullName(ref) or "")
    end
    local unit = FindUnitByGuid(ref)
    return unit, ref, ""
end

local function StateKey(unit, guid, name)
    if unit and UnitIsUnit and UnitIsUnit(unit, "player") then return "player" end
    if guid and guid ~= "" then return guid end
    return name ~= "" and name or nil
end

local function Notify()
    -- Invalida el mapa de contadores por aura sin tener que saber a quien afecto el cambio.
    S.selloAviso = (S.selloAviso or 0) + 1
    for _, fn in ipairs(S.listeners) do pcall(fn) end
    if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
    -- El contador que se pinta sobre el icono de aura lo lleva Harford, no el aura: si cambia sin
    -- que entre o salga ninguna, `UNIT_AURA` no dispara y el numero se quedaria viejo.
    if HarfordUnitFrames and HarfordUnitFrames.RefreshAuraCounters then
        HarfordUnitFrames.RefreshAuraCounters()
    end
end

local function RemoveRecord(key, id, silent)
    local bucket = key and S.units[key]
    if not (bucket and bucket[id]) then return false end
    bucket[id] = nil
    if not next(bucket) then S.units[key] = nil end
    if key == "player" then SaveOwned() end
    if not silent then Notify() end
    return true
end

local function StoreRecord(key, id, options)
    if not key then return false end
    local bucket = S.units[key]
    if not bucket then bucket = {}; S.units[key] = bucket end
    local count = 0
    for _ in pairs(bucket) do count = count + 1 end
    if not bucket[id] and count >= MAX_STATES_PER_UNIT then return false end
    options = options or {}
    bucket[id] = {
        id = id, sourceGuid = tostring(options.sourceGuid or ""), sourceName = tostring(options.sourceName or ""),
        targetGuid = tostring(options.targetGuid or ""), targetName = tostring(options.targetName or ""),
        duration = tostring(options.duration or "manual"), turns = math.max(0, math.floor(tonumber(options.turns) or 0)),
        saveAbility = CanonicalAbility(options.saveAbility), saveDC = math.max(0, math.floor(tonumber(options.saveDC) or 0)),
        created = Now(), appliedTurnSerial = tonumber(options.turnSerial) or 0,
        expiresAt = tonumber(options.expiresAt), persist = options.persist == true,
        authority = options.authority == true or key == "player",
        -- El nivel es parte del estado en las condiciones con niveles (cansancio). Sin
        -- guardarlo aqui se perdia al aplicarlo y GetExhaustion caia siempre a 1: ningun
        -- efecto de nivel 2 o superior llegaba a activarse.
        level = options.level and math.max(1, math.floor(tonumber(options.level) or 1)) or nil,
        vars = NormalizeVars(options.vars),
    }
    if key == "player" then SaveOwned() end
    Notify()
    return true
end

local function NeedsMetadataRecord(def, options)
    if not def then return false end
    if def.tracking ~= "aura" then return true end
    options = options or {}
    local duration = tostring(options.duration or "manual")
    return duration ~= "manual"
        or (tonumber(options.turns) or 0) > 0
        or tostring(options.saveAbility or "") ~= ""
        or (tonumber(options.saveDC) or 0) > 0
        or options.persist == true
end

function API.GetDefinition(id) return API.DEFS[tostring(id or "")] end
function API.FindIdByText(value)
    local key = HarfordClassColors.NormalizeKey(value)
    for id, def in pairs(API.DEFS) do
        if HarfordClassColors.NormalizeKey(id) == key or HarfordClassColors.NormalizeKey(def.label) == key then return id end
    end
    return nil
end
function API.GetDefinitions()
    local out = {}
    for _, id in ipairs(API.ORDER) do
        local def = API.DEFS[id]
        if def then out[#out + 1] = { id = id, label = def.label, auraId = def.auraId, description = def.description } end
    end
    return out
end

local function RecordActive(def, unit, key, id)
    local record = key and S.units[key] and S.units[key][id]
    if record and record.expiresAt and record.expiresAt <= Now() then
        RemoveRecord(key, id, true)
        record = nil
    end
    if def.tracking == "aura" or def.tracking == "aura_state" then
        if UnitHasAuraId(unit, def.auraId) then return true, record end
        if record and Now() - (record.created or 0) <= AURA_GRACE then return true, record end
        if record and unit then RemoveRecord(key, id, true) end
        return false, nil
    end
    return record ~= nil, record
end

function API.GetActive(ref)
    LoadOwned()
    local unit, guid, name = ResolveRef(ref)
    local key = StateKey(unit, guid, name)
    local out = {}
    for _, id in ipairs(API.ORDER) do
        local def = API.DEFS[id]
        local active, record = RecordActive(def, unit, key, id)
        if active then out[#out + 1] = { id = id, definition = def, record = record } end
    end
    return out
end

function API.GetActiveIds(ref)
    local out = {}
    for _, active in ipairs(API.GetActive(ref)) do out[#out + 1] = active.id end
    return out
end

function API.Has(ref, id)
    id = tostring(id or "")
    local def = API.DEFS[id]
    if not def then return false end
    LoadOwned()
    local unit, guid, name = ResolveRef(ref)
    return RecordActive(def, unit, StateKey(unit, guid, name), id) == true
end

-- VARIABLES DE CONDICION. Lee y opera sobre el valor que lleva una condicion activa.
-- Las operaciones son las de TRP3 Extended, que ya resolvio este problema:
--   "[=]" fija solo si NO existe (inicializar sin pisar)
--   "="   fija siempre
--   "+" / "-" / "*" operan sobre lo que hubiera (0 si no habia)
-- Solo NUMEROS: el que hace la condicion vive en su definicion, la instancia lleva el cuanto.
function API.GetVar(ref, conditionId, varName, default)
    local def = API.DEFS[tostring(conditionId or "")]
    if not def then return default end
    LoadOwned()
    local unit, guid, name = ResolveRef(ref)
    local key = StateKey(unit, guid, name)
    local record = key and S.units[key] and S.units[key][tostring(conditionId or "")]
    local vars = record and record.vars
    local valor = vars and tonumber(vars[tostring(varName or "")])
    if valor == nil then return default end
    return valor
end

-- Arte del estado. El que TIENE aura usa el icono del propio aura: es el que el jugador ya ve en
-- pantalla, y declarar una segunda version solo serviria para que un dia dejaran de coincidir. Los
-- demas lo sacan del catalogo de iconos, que es la fuente unica de arte del proyecto.
function API.GetIcon(conditionId)
    local def = API.DEFS[tostring(conditionId or "")]
    if not def then return nil end
    if HarfordIconCatalog and HarfordIconCatalog.GetFeatureIcon then
        local icono = HarfordIconCatalog.GetFeatureIcon("harford_estado_" .. tostring(conditionId))
        if icono then return icono end
    end
    if def.auraId and GetSpellTexture then
        local textura = GetSpellTexture(def.auraId)
        if textura then return textura end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- El numero que lleva una condicion activa, o nil si no lleva ninguno.
--
-- El contador NO sale del aura: en Epsilon no se pueden aplicar auras con acumulaciones, asi que lo
-- lleva Harford en la instancia (`vars.contador`, o el nivel en las que los tienen, como el
-- Cansancio). Un 1 no se pinta: un contador que siempre marca uno es ruido.
function API.CounterFor(def, record)
    if not def then return nil end
    if def.leveled then
        local nivel = record and tonumber(record.level)
        if nivel and nivel > 1 then return math.floor(nivel) end
        return nil
    end
    local n = record and record.vars and tonumber(record.vars.contador)
    if n and n > 1 then return math.floor(n) end
    return nil
end

-- Numero que lleva la condicion respaldada por ese aura, o nil si no lleva ninguno.
--
-- El contador NO sale del aura: en Epsilon no se pueden aplicar auras con acumulaciones, asi que lo
-- lleva Harford en la instancia de la condicion (`vars.contador`, o el nivel si es de las que los
-- tienen, como el Cansancio) y luego se pinta encima del icono.
-- Mapa aura -> contador de una unidad, calculado UNA vez. Se invalida por sello: `Notify` lo sube
-- cada vez que algo cambia, asi que no caduca por tiempo ni necesita ticker.
local cacheContadores = {}
function API.GetAuraCounterMap(ref)
    local clave = tostring(ref or "player")
    local guardado = cacheContadores[clave]
    if guardado and guardado.sello == (S.selloAviso or 0) then return guardado.mapa end
    local mapa = {}
    for _, active in ipairs(API.GetActive(clave)) do
        local def = active.definition
        local id = def and tonumber(def.auraId)
        if id then mapa[id] = API.CounterFor(def, active.record) end
    end
    cacheContadores[clave] = { sello = S.selloAviso or 0, mapa = mapa }
    return mapa
end

function API.GetAuraCounter(ref, spellId)
    spellId = tonumber(spellId)
    if not spellId then return nil end
    return API.GetAuraCounterMap(ref or "player")[spellId]
end

function API.SetVar(ref, conditionId, opType, varName, value)
    conditionId, varName = tostring(conditionId or ""), tostring(varName or ""):match("^[%w_]+$")
    if not API.DEFS[conditionId] or not varName then return false end
    LoadOwned()
    local unit, guid, name = ResolveRef(ref)
    local key = StateKey(unit, guid, name)
    local record = key and S.units[key] and S.units[key][conditionId]
    if not record then return false end
    record.vars = record.vars or {}
    local previo = tonumber(record.vars[varName]) or 0
    value = tonumber(value) or 0
    opType = tostring(opType or "=")
    if opType == "[=]" then
        if record.vars[varName] == nil then record.vars[varName] = math.floor(value) end
    elseif opType == "+" then record.vars[varName] = math.floor(previo + value)
    elseif opType == "-" then record.vars[varName] = math.floor(previo - value)
    elseif opType == "*" then record.vars[varName] = math.floor(previo * value)
    else record.vars[varName] = math.floor(value) end
    if key == "player" then SaveOwned() end
    Notify()
    return true, record.vars[varName]
end

-- Reduccion PLANA que aplican las condiciones activas de una unidad a un tipo de dano concreto.
-- Es distinto de resistir (mitad) o ser inmune (nada): aqui se RESTA una cantidad fija, y no se
-- gasta -- a diferencia de la vida temporal, reduce todos los golpes mientras dure.
function API.GetDamageReduction(ref, damageType)
    LoadOwned()
    local unit, guid, name = ResolveRef(ref)
    local key = StateKey(unit, guid, name)
    local bucket = key and S.units[key]
    if not bucket then return 0 end
    damageType = tostring(damageType or ""):lower()
    local total = 0
    for id, record in pairs(bucket) do
        local def = API.DEFS[id]
        local tipos = def and def.damageReduction
        if tipos and record.vars then
            local cantidad = tonumber(record.vars.reduccion) or 0
            if cantidad > 0 then
                for _, t in ipairs(tipos) do
                    if tostring(t):lower() == damageType then total = total + cantidad break end
                end
            end
        end
    end
    return total
end

function API.HasConditionImmunity(ref, conditionId)
    conditionId = tostring(conditionId or "")
    local unit = ResolveRef(ref)
    if unit and UnitIsPlayer and UnitIsPlayer(unit) and HarfordDnDFeatureEffects
        and HarfordDnDFeatureEffects.HasConditionImmunity then
        local profile = UnitIsUnit and UnitIsUnit(unit, "player") and PlayerProfileName()
            or HarfordClassColors.UnitFullName(unit)
        if HarfordDnDFeatureEffects.HasConditionImmunity(conditionId, profile) then return true end
    end
    if unit and HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        local stats = HarfordTRP3.GetNPCStatBlock(unit)
        local needle = HarfordClassColors.NormalizeKey((API.DEFS[conditionId] and API.DEFS[conditionId].label) or conditionId)
        for _, text in ipairs(stats and stats.immunities or {}) do
            if HarfordClassColors.NormalizeKey(text):find(needle, 1, true) then return true end
        end
    end
    return false
end

local function ApplyAura(def, scope, remove)
    if not def.auraId or not HarfordAuras then return true end
    local fn = remove and HarfordAuras.RemoveById or HarfordAuras.ApplyById
    if not fn then return false end
    return fn(def.auraId, scope, { addonName = "Harford" })
end

function API.ApplyOwned(id, options)
    id = tostring(id or "")
    local def = API.DEFS[id]
    if not def then return false, "Condicion desconocida" end
    if API.HasConditionImmunity("player", id) then return false, "immune" end
    options = options or {}
    if def.auraId then
        local auraOk, auraErr = ApplyAura(def, "self", false)
        if auraOk == false then return false, auraErr or "No se pudo aplicar la aura" end
    end
    if NeedsMetadataRecord(def, options) then
        options.targetGuid = UnitGUID and UnitGUID("player") or ""
        options.targetName = HarfordClassColors.UnitFullName("player") or PlayerProfileName()
        options.persist = options.persist == true or def.persist == true
        if not StoreRecord("player", id, options) then
            if def.auraId then ApplyAura(def, "self", true) end
            return false, "Limite de condiciones activas alcanzado"
        end
    else
        Notify()
    end
    return true, "applied"
end

function API.RemoveOwned(id)
    id = tostring(id or "")
    local def = API.DEFS[id]
    if not def then return false, "Condicion desconocida" end
    if def.auraId then
        local auraOk, auraErr = ApplyAura(def, "self", true)
        if auraOk == false then return false, auraErr or "No se pudo retirar la aura" end
    end
    RemoveRecord("player", id, true)
    Notify()
    return true, "removed"
end

function API.SetUnitState(ref, id, options)
    local def = API.DEFS[tostring(id or "")]
    if not def then return false, "Condicion desconocida" end
    local unit, guid, name = ResolveRef(ref)
    if unit and API.HasConditionImmunity(unit, id) then return false, "immune" end
    if NeedsMetadataRecord(def, options) then
        options = options or {}
        options.targetGuid, options.targetName = guid, name
        local stored = StoreRecord(StateKey(unit, guid, name), id, options)
        return stored, stored and "applied" or "Limite de condiciones activas alcanzado"
    end
    Notify()
    return true, "applied"
end

function API.RemoveUnitState(ref, id)
    local unit, guid, name = ResolveRef(ref)
    id = tostring(id or "")
    local removed = RemoveRecord(StateKey(unit, guid, name), id, true)
    -- Si el estado llevaba aura y el NPC no esta delante, se apunta para retirarla cuando lo este.
    -- El estado desaparece ya -- es dato de Harford -- pero el icono seguiria pegado.
    local def = API.DEFS[id]
    if removed and def and def.auraId and guid and guid ~= "" then
        local esteEsElObjetivo = UnitExists and UnitExists("target") and UnitGUID
            and UnitGUID("target") == guid
        if not (unit and UnitIsPlayer and UnitIsPlayer(unit)) then
            if esteEsElObjetivo then
                API.QueueNpcAura(guid, def.auraId, "remove")
                API.FlushPendingAuras("target")
            else
                API.QueueNpcAura(guid, def.auraId, "remove")
            end
        end
    end
    Notify()
    return removed
end

function API.ApplyToUnit(unit, conditionId, options)
    if not (UnitExists and UnitExists(unit)) then return false, "Objetivo inexistente" end
    if UnitIsPlayer and UnitIsPlayer(unit) then return API.RequestPlayer(unit, conditionId, true, options) end
    local def = API.DEFS[tostring(conditionId or "")]
    if not def then return false, "Condicion desconocida" end
    if unit ~= "target" then return false, "El NPC debe ser el target actual" end
    if API.HasConditionImmunity(unit, conditionId) then return false, "immune" end
    if def.auraId then
        -- Las condiciones disparadas por una habilidad (Desarme, Derribado...) son
        -- reglas core, no herramientas del menu DM. Igual que el dano a un NPC,
        -- requieren el permiso de oficial de fase, pero no HarfordAdmin ni .ph dm.
        if not (HarfordAuthority and HarfordAuthority.CanUseOfficerCommands
            and HarfordAuthority.CanUseOfficerCommands()) then
            return false, "Requiere permiso de oficial de fase para aplicar la condicion al NPC"
        end
        local ok, err = ApplyAura(def, "npc", false)
        if ok == false then return false, err or "No se pudo aplicar la aura al NPC" end
    end
    options = options or {}
    options.authority = true
    return API.SetUnitState(unit, conditionId, options)
end

function API.RemoveFromUnit(unit, conditionId)
    if not (UnitExists and UnitExists(unit)) then return false, "Objetivo inexistente" end
    if UnitIsPlayer and UnitIsPlayer(unit) then return API.RequestPlayer(unit, conditionId, false) end
    local def = API.DEFS[tostring(conditionId or "")]
    if not def then return false, "Condicion desconocida" end
    if unit ~= "target" then return false, "El NPC debe ser el target actual" end
    if def.auraId then
        if not (API.AdminHooks and API.AdminHooks.removeAura) then
            return false, "HarfordAdmin no esta disponible para retirar la aura del NPC"
        end
        local ok, err = API.AdminHooks.removeAura({
            unit = unit,
            guid = UnitGUID and UnitGUID(unit) or "",
            name = HarfordClassColors.UnitFullName(unit) or "",
        }, conditionId)
        if ok == false then return false, err end
    end
    API.RemoveUnitState(unit, conditionId)
    return true
end

function API.RemoveAllFromUnit(unit)
    local ids = API.GetActiveIds(unit)
    local removed = 0
    for _, id in ipairs(ids) do
        local ok = API.RemoveFromUnit(unit, id)
        if ok then removed = removed + 1 end
    end
    return removed
end

-- ─── COLA DE AURAS PENDIENTES SOBRE NPC ─────────────────────────────────────
-- Poner o quitar un aura a un NPC exige tenerlo SELECCIONADO: el comando de servidor actua sobre
-- el objetivo actual y no hay forma de hacerlo en bloque. Eso choca con los contadores, que bajan
-- de golpe para todo un bando sin tocar a nadie: cuando a cinco enemigos les expira algo a la vez,
-- el numero desaparece al instante pero el icono se queda pegado hasta que alguien los seleccione.
--
-- En vez de pedirle al DM que vaya uno por uno, se APUNTA lo que falta y se ejecuta sola en cuanto
-- selecciona a ese NPC -- cosa que va a hacer igualmente, porque le toca actuar. El coste
-- desaparece porque se aprovecha una seleccion que ya ocurre.
--
-- Mismo patron que la cola por GUID del motor de areas, que ya resolvia esto para el dano.
local pendientesAura = {}

function API.QueueNpcAura(guid, auraId, op)
    guid, auraId = tostring(guid or ""), tonumber(auraId)
    if guid == "" or not auraId or auraId <= 0 then return false end
    pendientesAura[guid] = pendientesAura[guid] or {}
    -- Sin duplicados: si ya estaba apuntado quitar esa aura, apuntarlo otra vez no anade nada.
    for _, p in ipairs(pendientesAura[guid]) do
        if p.auraId == auraId and p.op == op then return true end
    end
    pendientesAura[guid][#pendientesAura[guid] + 1] = { auraId = auraId, op = op or "remove" }
    Notify()
    return true
end

-- Dano pendiente sobre un NPC. NO se deduplica y NO se agrupa por igualdad como las auras: dos
-- golpes de 7 son catorce puntos de vida, no siete. Se SUMAN en una sola entrada para no emitir
-- dos comandos de servidor donde basta uno.
function API.QueueNpcDamage(guid, cantidad, autor)
    guid = tostring(guid or "")
    cantidad = math.floor(tonumber(cantidad) or 0)
    if guid == "" or cantidad == 0 then return false end
    pendientesAura[guid] = pendientesAura[guid] or {}
    for _, p in ipairs(pendientesAura[guid]) do
        if p.op == "damage" then
            p.cantidad = p.cantidad + cantidad
            p.autores = p.autores or {}
            if autor and autor ~= "" then p.autores[#p.autores + 1] = autor end
            Notify()
            return true
        end
    end
    pendientesAura[guid][#pendientesAura[guid] + 1] = {
        op = "damage", cantidad = cantidad,
        autores = (autor and autor ~= "") and { autor } or {},
    }
    Notify()
    return true
end

-- Cuantas quedan, para poder decirlo en la ventana en vez de dejarlo mudo.
function API.GetPendingAuraCount()
    local total = 0
    for _, lista in pairs(pendientesAura) do total = total + #lista end
    return total
end

function API.GetPendingAurasFor(guid)
    return pendientesAura[tostring(guid or "")]
end

-- Ejecuta lo apuntado para la unidad que se acaba de seleccionar. Se llama al cambiar de objetivo.
function API.FlushPendingAuras(unit)
    unit = unit or "target"
    if not (UnitExists and UnitExists(unit)) then return 0 end
    if UnitIsPlayer and UnitIsPlayer(unit) then return 0 end
    local guid = UnitGUID and UnitGUID(unit)
    local lista = guid and pendientesAura[guid]
    if not lista or #lista == 0 then return 0 end
    -- Sin permiso no se intenta: se deja apuntado para quien pueda, en vez de perderlo.
    if not (HarfordAuthority and HarfordAuthority.CanUseOfficerCommands
        and HarfordAuthority.CanUseOfficerCommands()) then
        return 0
    end
    local hechas = 0
    for i = #lista, 1, -1 do
        local p = lista[i]
        local ok = false
        -- `RemoveAura` y `ApplyAuraToCurrentTarget` ya actuan sobre el objetivo actual: no hace
        -- falta accion nueva de servidor, solo llamarlas en el momento adecuado.
        if p.op == "remove" and HarfordServerActions and HarfordServerActions.RemoveAura then
            ok = HarfordServerActions.RemoveAura(p.auraId, { addonName = "Harford" })
        elseif p.op == "apply" and HarfordServerActions and HarfordServerActions.ApplyAuraToCurrentTarget then
            ok = HarfordServerActions.ApplyAuraToCurrentTarget(p.auraId, { addonName = "Harford" })
        elseif p.op == "damage" and HarfordServerActions and HarfordServerActions.SetNpcHealthDelta then
            -- El dano ya viene MITIGADO por quien lo calculo: aqui no se vuelve a resolver nada,
            -- solo se emite el comando que el otro no podia emitir.
            ok = HarfordServerActions.SetNpcHealthDelta(-math.abs(p.cantidad), { addonName = "Harford" })
            if ok and HarfordChat and HarfordChat.Print then
                local de = (#(p.autores or {}) > 0) and (" (" .. table.concat(p.autores, ", ") .. ")") or ""
                HarfordChat.Print(string.format("Aplicados %d de dano pendiente a %s%s.",
                    math.abs(p.cantidad), tostring(UnitName and UnitName(unit) or "?"), de))
            end
        end
        -- Solo se tacha lo que se pudo hacer: un fallo de servidor no debe borrar el recordatorio.
        if ok then
            table.remove(lista, i)
            hechas = hechas + 1
        end
    end
    if #lista == 0 then pendientesAura[guid] = nil end
    if hechas > 0 then Notify() end
    return hechas
end

-- ─── DELEGAR EL EFECTO EN QUIEN PUEDA EMITIRLO ──────────────────────────────
-- `EsNpcDeLosTurnos` se declara mas abajo; aqui solo se cierra sobre ella.
-- Quien manda el efecto ya lo ha resuelto entero: tirada, dano y mitigacion son del cliente. Lo
-- unico que no puede hacer es EMITIR el comando de servidor, porque no es oficial.
--
-- Se manda al lider del grupo, que es el DM principal en mesa. Si el lider tampoco puede, se queda
-- apuntado en su cola y no pasa nada: es mejor que se pierda un comando a que se pierda el turno.
local function NombreDelLider()
    if not (IsInGroup and IsInGroup()) then return nil end
    local n = GetNumGroupMembers and GetNumGroupMembers() or 0
    local prefijo = (IsInRaid and IsInRaid()) and "raid" or "party"
    for i = 1, n do
        local u = prefijo .. i
        if UnitExists and UnitExists(u) and UnitIsGroupLeader and UnitIsGroupLeader(u) then
            return HarfordClassColors.UnitFullName(u)
        end
    end
    return nil
end

-- ¿Puedo emitirlo yo? Si si, no hay nada que delegar.
function API.PuedoAplicarEnNpc()
    return (HarfordAuthority and HarfordAuthority.CanUseOfficerCommands
        and HarfordAuthority.CanUseOfficerCommands()) == true
end

-- Punto unico: aplicar un efecto a un NPC, lo pueda yo o no. Devuelve "aplicado", "encolado",
-- "delegado" o nil, para que quien llama pueda decirlo por chat sin repetir la logica.
function API.AplicarEfectoNpc(guid, tipo, valor, unidad)
    guid = tostring(guid or "")
    if guid == "" then return nil end

    if API.PuedoAplicarEnNpc() then
        if tipo == "damage" then API.QueueNpcDamage(guid, valor, nil)
        else API.QueueNpcAura(guid, valor, tipo) end
        -- Si ya lo tengo delante, se ejecuta ahora mismo en vez de esperar a re-seleccionarlo.
        local mirando = UnitExists and UnitExists(unidad or "target")
            and UnitGUID and UnitGUID(unidad or "target") == guid
        if mirando and API.FlushPendingAuras(unidad or "target") > 0 then return "aplicado" end
        return "encolado"
    end

    local lider = NombreDelLider()
    if not (lider and HarfordSync and HarfordSync.SerializeNpcEffect) then return nil end
    local yo = HarfordClassColors.UnitFullName("player") or ""
    HarfordSync.Send(PREFIX, HarfordSync.SerializeNpcEffect(guid, tipo, valor, yo), "WHISPER", lider)
    return "delegado"
end

-- Recepcion. Solo entra si YO puedo emitirlo: si no, encolarlo seria acumular trabajo que nunca
-- se hara y ademas dejaria creer al que lo mando que esta resuelto.
function API.RecibirEfectoNpc(guid, tipo, valor, autor, sender)
    if not API.PuedoAplicarEnNpc() then return false end
    if not EsNpcDeLosTurnos(guid) then return false end
    if tipo == "damage" then
        API.QueueNpcDamage(guid, valor, autor ~= "" and ShortName(autor) or ShortName(sender or ""))
    elseif tipo == "apply" or tipo == "remove" then
        API.QueueNpcAura(guid, valor, tipo)
    else
        return false
    end
    -- Si ya lo tengo seleccionado, se ejecuta sin esperar.
    API.FlushPendingAuras("target")
    return true
end

function API.ClearPendingAuras(guid)
    if guid then pendientesAura[tostring(guid)] = nil else pendientesAura = {} end
    Notify()
end

function API.ClearUnitStateRecords(ref)
    local unit, guid, name = ResolveRef(ref)
    local key = StateKey(unit, guid, name)
    if not key or not S.units[key] then return 0 end
    local count = 0
    for _ in pairs(S.units[key]) do count = count + 1 end
    S.units[key] = nil
    if key == "player" then SaveOwned() end
    Notify()
    return count
end

local function EffectApplies(effect, rollType, context)
    if not (effect.rolls and effect.rolls[rollType]) then return false end
    if effect.ability and tostring(context.ability or "") ~= effect.ability then return false end
    if effect.range and tostring(context.attackRange or "") ~= effect.range then return false end
    return true
end

local function AddMode(flags, mode)
    if mode == "adv" then flags.adv = true elseif mode == "dis" then flags.dis = true end
end

local function EffectsFor(ref)
    local out = {}
    for _, active in ipairs(API.GetActive(ref)) do
        for _, effect in ipairs(active.definition.effects or {}) do out[#out + 1] = effect end
        -- Condiciones con niveles (cansancio): se acumulan los efectos de todos los niveles
        -- hasta el actual, como manda el manual.
        local levels = active.definition.levelEffects
        if levels then
            local level = math.min(active.record and tonumber(active.record.level) or 1,
                                   active.definition.maxLevel or 6)
            for i = 1, level do
                for _, effect in ipairs(levels[i] or {}) do out[#out + 1] = effect end
            end
        end
    end
    return out
end

local function EffectsForIds(ids)
    local out = {}
    for _, id in ipairs(ids or {}) do
        local def = API.DEFS[id]
        for _, effect in ipairs(def and def.effects or {}) do out[#out + 1] = effect end
    end
    return out
end

function API.ResolveRollMode(baseMode, rollType, context)
    context = context or {}
    local flags = { adv = baseMode == "adv", dis = baseMode == "dis" }
    local actor = context.actorUnit or context.actorGuid or "player"
    local actorEffects = context.actorConditionIds and EffectsForIds(context.actorConditionIds) or EffectsFor(actor)
    for _, effect in ipairs(actorEffects) do
        if effect.kind == "rollMode" and EffectApplies(effect, rollType, context) then AddMode(flags, effect.mode) end
    end
    -- `rollModeExceptSource`: se resuelve aparte porque necesita el sourceGuid de la INSTANCIA,
    -- que `EffectsFor` no arrastra. Mismo patron que `blockAttackSource` mas abajo.
    do
        local objetivo = context.targetGuid
            or (context.targetUnit and UnitGUID and UnitGUID(context.targetUnit))
        for _, active in ipairs(API.GetActive(actor)) do
            local origen = active.record and active.record.sourceGuid
            for _, effect in ipairs(active.definition and active.definition.effects or {}) do
                if effect.kind == "rollModeExceptSource" and EffectApplies(effect, rollType, context) then
                    -- Sin objetivo conocido se aplica: es el caso conservador para el defensor.
                    if not (origen and origen ~= "" and objetivo and origen == objetivo) then
                        AddMode(flags, effect.mode)
                    end
                end
            end
        end
    end
    local target = context.targetUnit or context.targetGuid
    if target or context.targetConditionIds then
        local targetEffects = context.targetConditionIds and EffectsForIds(context.targetConditionIds) or EffectsFor(target)
        for _, effect in ipairs(targetEffects) do
            if effect.kind == "incomingRollMode" and EffectApplies(effect, rollType, context) then AddMode(flags, effect.mode) end
        end
        -- `incomingRollModeFromSource`: solo se lo aplica QUIEN puso la condicion. El Veredicto del
        -- Templario da ventaja a los ataques del paladin contra esa criatura, no a los de todos.
        -- Va aparte por lo mismo que `rollModeExceptSource`: necesita el sourceGuid de la
        -- INSTANCIA, que `EffectsFor` no arrastra.
        local actorGuid = context.actorGuid
            or (context.actorUnit and UnitGUID and UnitGUID(context.actorUnit))
            or (UnitGUID and UnitGUID("player"))
        for _, active in ipairs(API.GetActive(target)) do
            local origen = active.record and active.record.sourceGuid
            if origen and origen ~= "" and actorGuid and origen == actorGuid then
                for _, effect in ipairs(active.definition and active.definition.effects or {}) do
                    if effect.kind == "incomingRollModeFromSource"
                        and EffectApplies(effect, rollType, context) then
                        AddMode(flags, effect.mode)
                    end
                end
            end
        end
    end
    if flags.adv == flags.dis then return "normal" end
    return flags.adv and "adv" or "dis"
end

function API.CanPerform(actionType, context)
    context = context or {}
    local actor = context.actorUnit or context.actorGuid or "player"
    for _, active in ipairs(API.GetActive(actor)) do
        for _, effect in ipairs(active.definition.effects or {}) do
            if effect.kind == "blockAction" and effect.actions
                and (effect.actions[actionType]
                    or ((actionType == "weapon_attack" or actionType == "verbal_spell") and effect.actions.action)) then
                return false, active.definition.label
            elseif effect.kind == "blockAttackSource"
                and (actionType == "action" or actionType == "verbal_spell") then
                local sourceGuid = active.record and active.record.sourceGuid
                local targetGuid = context.targetGuid or (context.targetUnit and UnitGUID and UnitGUID(context.targetUnit))
                if sourceGuid and sourceGuid ~= "" and sourceGuid == targetGuid then return false, active.definition.label end
            end
        end
    end
    return true
end

function API.IsSaveAutoFailed(ref, ability)
    ability = tostring(ability or "")
    for _, effect in ipairs(EffectsFor(ref or "player")) do
        if effect.kind == "autoFailSave" and effect.abilities and effect.abilities[ability] then return true end
    end
    return false
end

-- ── Cansancio: nivel, subida y bajada ───────────────────────────────────────
-- Es la unica condicion con nivel, asi que tiene su propio acceso en vez de obligar a los
-- llamantes a hurgar en el registro de estado.

function API.GetExhaustion(ref)
    for _, active in ipairs(API.GetActive(ref or "player")) do
        if active.id == "exhaustion" then
            return math.max(1, math.min(6, tonumber(active.record and active.record.level) or 1))
        end
    end
    return 0
end

-- Fija el nivel exacto. 0 lo retira; 6 significa muerte y se anuncia como tal.
function API.SetExhaustion(ref, level)
    ref = ref or "player"
    level = math.max(0, math.min(6, math.floor(tonumber(level) or 0)))
    if level == 0 then
        if ref == "player" then API.RemoveOwned("exhaustion") else API.RemoveUnitState(ref, "exhaustion") end
        return 0
    end
    local options = { level = level }
    if ref == "player" then
        API.ApplyOwned("exhaustion", options)
    else
        API.SetUnitState(ref, "exhaustion", options)
    end
    return level
end

-- Suma o resta niveles. Devuelve el nivel resultante.
function API.AddExhaustion(ref, delta)
    ref = ref or "player"
    local current = API.GetExhaustion(ref)
    return API.SetExhaustion(ref, current + (tonumber(delta) or 1))
end

-- Texto de los efectos activos, para tooltips y para el aviso al cambiar de nivel.
function API.GetExhaustionEffects(level)
    level = math.max(0, math.min(6, math.floor(tonumber(level) or 0)))
    local def = API.DEFS.exhaustion
    local out = {}
    for i = 1, level do out[#out + 1] = (def.levelLabels or {})[i] end
    return out
end

-- Etiqueta del efecto que APARECE en un nivel concreto (no los acumulados). La usa el menu de
-- estado de la ficha para que elegir el nivel diga que implica.
function API.GetExhaustionLevelLabel(level)
    level = math.floor(tonumber(level) or 0)
    if level < 1 or level > 6 then return nil end
    return (API.DEFS.exhaustion.levelLabels or {})[level]
end

-- ¿La velocidad esta a la mitad? (nivel 2 de cansancio, y cualquier efecto equivalente)
function API.IsSpeedHalved(ref)
    for _, effect in ipairs(EffectsFor(ref or "player")) do
        if effect.kind == "speedHalved" then return true end
    end
    return false
end

-- ¿Los puntos de golpe maximos estan a la mitad? (nivel 4 de cansancio)
function API.IsMaxHealthHalved(ref)
    for _, effect in ipairs(EffectsFor(ref or "player")) do
        if effect.kind == "maxHealthHalved" then return true end
    end
    return false
end

function API.IsSpeedZero(ref)
    for _, effect in ipairs(EffectsFor(ref or "player")) do
        if effect.kind == "speedZero" or effect.kind == "dead" then return true end
    end
    return false
end

-- Estado frente a un tipo de dano por CONDICIONES activas.
--
-- `resistAll` no mira el tipo (Petrificado resiste todo). `resistTypes` si: la Piel de Hierro del
-- Monje resiste contundente, perforante y cortante y nada mas, y solo de golpes NO magicos --
-- `opts.magical` lo dice el atacante, igual que en el resto de la mitigacion.
--
-- `damageType` puede llegar en español ("contundente") o con la clave interna ("bludgeoning").
local function ClaveDeTipo(valor)
    if type(valor) ~= "string" then return nil end
    local minus = valor:lower()
    if HarfordDamageTypes then
        if HarfordDamageTypes.FromWord and HarfordDamageTypes.FromWord(minus) then
            return HarfordDamageTypes.FromWord(minus)
        end
        if HarfordDamageTypes.Exists and HarfordDamageTypes.Exists(minus) then return minus end
    end
    return minus
end

-- Estados de UN SOLO USO: se retiran en cuanto se hace la tirada para la que servian. Los declara
-- la propia condicion en `consumeAfterRoll`; antes esto era un `if` con el id de Palabra de Poder:
-- Fortaleza escrito dentro del calculo de la tirada.
function API.ConditionsToConsumeAfterRoll(rollType)
    local fuera = {}
    if not rollType then return fuera end
    for _, active in ipairs(API.GetActive("player")) do
        local consumo = active.definition and active.definition.consumeAfterRoll
        if type(consumo) == "table" and consumo[rollType] then fuera[#fuera + 1] = active.id end
    end
    return fuera
end

function API.GetDamageStatus(ref, damageType, opts)
    local clave = ClaveDeTipo(damageType)
    for _, effect in ipairs(EffectsFor(ref or "player")) do
        if effect.kind == "resistAll" then return "resistant" end
        if effect.kind == "resistTypes" and clave
            and not (effect.nonMagical and opts and opts.magical) then
            for _, tipo in ipairs(effect.types or {}) do
                if ClaveDeTipo(tipo) == clave then return "resistant" end
            end
        end
    end
    return nil
end

local function PublishState(op, id, record)
    if not (HarfordSync and HarfordSync.SendConditionState) then return end
    local channel = HarfordSync.BestChannel and HarfordSync.BestChannel()
    if not channel then return end
    record = record or {}
    HarfordSync.SendConditionState(PREFIX, channel, {
        op = op, conditionId = id, targetGuid = UnitGUID and UnitGUID("player") or "",
        targetName = HarfordClassColors.UnitFullName("player") or PlayerProfileName(),
        sourceGuid = record.sourceGuid, sourceName = record.sourceName,
        duration = record.duration, turns = record.turns,
        saveAbility = record.saveAbility, saveDC = record.saveDC,
    })
end

function API.PublishOwnedCondition(id, op)
    local record = S.units.player and S.units.player[id]
    if (op or "apply") == "apply" and not record then return false end
    PublishState(op or "apply", id, record)
    return true
end

function API.OnDamageTaken(ref, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local unit, guid, name = ResolveRef(ref or "player")
    local key = StateKey(unit, guid, name)
    local remove = {}
    for _, active in ipairs(API.GetActive(ref or "player")) do
        for _, effect in ipairs(active.definition.effects or {}) do
            if effect.kind == "breakOnDamage" then remove[#remove + 1] = active.id; break end
        end
    end
    for _, id in ipairs(remove) do
        if key == "player" then
            API.RemoveOwned(id)
            PublishState("remove", id)
        else
            API.RemoveUnitState(ref, id)
            if API.AdminHooks and API.AdminHooks.removeAura then pcall(API.AdminHooks.removeAura, ref, id) end
        end
    end
    return #remove > 0
end

-- Los miembros de un bando, como conjunto de guid y nombre corto, para poder preguntar rapido si
-- un registro pertenece a quien le acaba de tocar.
local function MiembrosDeBando(bando)
    local guids, nombres = {}, {}
    if not (HarfordTurnOrderAPI and HarfordTurnOrderAPI.GetBandoMembers) then return guids, nombres end
    for _, e in ipairs(HarfordTurnOrderAPI.GetBandoMembers(bando) or {}) do
        local g = tostring(e.guid or e.id or "")
        if g ~= "" then guids[g] = true end
        if e.name and e.name ~= "" then nombres[ShortName(e.name)] = true end
    end
    return guids, nombres
end

local function IdentityMatches(record, entry, which)
    if not (record and entry) then return false end
    local guid = tostring(record[which .. "Guid"] or "")
    local name = tostring(record[which .. "Name"] or "")
    -- Turno de BANDO: no es un combatiente sino un bloque, asi que casa con CUALQUIERA de sus
    -- miembros. Es lo que hace que a los cinco enemigos les baje el contador de golpe en vez de
    -- uno a uno, y cada cliente lo resuelve solo: el DM unicamente anuncia que bando empieza.
    if tostring(entry.kind or "") == "bando" then
        local guids, nombres
        if entry.miembros then
            -- La lista vino con el anuncio del DM: esa manda. Es lo que evita que dos clientes
            -- con la foto desincronizada hagan tocar a criaturas distintas.
            guids, nombres = entry.miembros.guids or {}, {}
            for n in pairs(entry.miembros.nombres or {}) do nombres[ShortName(n)] = true end
        else
            guids, nombres = MiembrosDeBando(entry.bando)
        end
        if guid ~= "" and guids[guid] then return true end
        if name ~= "" and nombres[ShortName(name)] then return true end
        -- Y si el bloque es el de los PJs, mis propios estados cuentan aunque el registro no traiga
        -- identidad: son mios, y yo soy un PJ.
        if entry.bando == "pjs" and guid == "" and name == "" then return true end
        return false
    end
    return (guid ~= "" and guid == tostring(entry.guid or entry.id or ""))
        or (name ~= "" and ShortName(name) == ShortName(entry.name))
end

local function ResolveEndSave(key, id, record)
    local ability, dc = tostring(record.saveAbility or ""), tonumber(record.saveDC) or 0
    if ability == "" or dc <= 0 then return nil end
    local unit = key == "player" and "player" or FindUnitByGuid(record.targetGuid or key)
    if not unit then return nil end
    local autoFail = API.IsSaveAutoFailed(unit, ability)
    local mode = API.ResolveRollMode("normal", "save", { actorUnit = unit, ability = ability })
    local die = autoFail and 0 or select(1, HarfordDnDCalc.RollD20(mode))
    local bonus = 0
    if unit == "player" then
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(ability)
        bonus = (tonumber(base) or 0) + (tonumber(prof) or 0)
    elseif HarfordDnDCombat and HarfordDnDCombat.GetSaveBonusForUnit then
        bonus = tonumber(HarfordDnDCombat.GetSaveBonusForUnit(unit, ability)) or 0
    end
    local total, saved = die + bonus, not autoFail and die + bonus >= dc
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        local def = API.DEFS[id]
        local rollName = HarfordTRP3 and HarfordTRP3.GetUnitRPName and HarfordTRP3.GetUnitRPName(unit)
        if not rollName or rollName == "" then rollName = ShortName(record.targetName) end
        local rollColor = HarfordTRP3 and HarfordTRP3.GetUnitNameColor and HarfordTRP3.GetUnitNameColor(unit) or nil
        HarfordDnDRolls.Broadcast({
            type = "info",
            player = rollName,
            nameColor = rollColor,
            label = string.format("Salv %s %d (%d%+d vs CD %d) %s%s", ability, total, die, bonus, dc,
                saved and "|cff00ff00EXITO|r termina " or "|cffff3333FALLO|r mantiene ", def and def.label or id),
        })
    end
    return saved
end

-- ─── ECONOMIA DE TURNO ───────────────────────────────────────────────────────
-- Accion, accion adicional y reaccion como presupuesto que se renueva al empezar TU turno.
--
-- Vive en este modulo, y no en uno propio, porque es el que ya posee la frontera de turno: aqui
-- estan `OnTurnChanged` y las duraciones `*_turn_start`. Un modulo aparte significaria un segundo
-- listener y un segundo guard de turno repetido, con dos verdades sobre cuando empieza un turno.
--
-- Estado EFIMERO: no se persiste ni viaja por red. Cada cliente cuenta lo suyo, igual que el
-- tracker de turnos ya hace con su propia vista.
--
-- INFORMA, NO BLOQUEA. `Spend` gasta SIEMPRE y devuelve si habia presupuesto. Si el tracker esta
-- desincronizado o alguien juega sin el, impedir usar un rasgo dejaria al jugador sin su propio
-- recurso en mitad de la escena; avisar es util, prohibir es un riesgo de mesa. Es la misma linea
-- que ya sigue el proyecto con Barrera (manual) y con las reacciones que no puede resolver.
do
    -- `extra`: presupuesto CONCEDIDO este turno por un rasgo (Accion adicional del Guerrero, que
    -- da una adicional mas y se gasta con usos propios). Se limpia con el turno, igual que lo
    -- gastado: es un permiso de ESTE turno, no una mejora permanente.
    local ECONOMIA = { spent = {}, extra = {}, activa = false }

    -- Los tres presupuestos, en el orden en que se muestran.
    local ORDEN = { "action", "bonus", "reaction" }
    local ETIQUETA = {
        action   = "Accion",
        bonus    = "Adicional",
        reaction = "Reaccion",
    }
    -- `cast` tal como lo declaran los datos de clase -> presupuesto que consume.
    local DE_CAST = {
        accion             = "action",
        accion_adicional   = "bonus",
        reaccion           = "reaction",
        bonus              = "bonus",
        reaction           = "reaction",
        action             = "action",
    }

    local Turn = {}
    Turn.ORDEN = ORDEN
    Turn.ETIQUETA = ETIQUETA

    -- Sin orden de turnos no hay frontera que detectar, asi que los contadores quedan INACTIVOS en
    -- vez de a cero para siempre: fuera de combate no se lleva la cuenta de acciones.
    function Turn.IsActive()
        if not (HarfordTurnOrderAPI and HarfordTurnOrderAPI.HasActiveCombat) then return false end
        return HarfordTurnOrderAPI.HasActiveCombat()
    end

    -- Presupuesto de cada tipo. Uno de cada por turno; los rasgos que conceden acciones extra
    -- (Impetu de Accion) suman aqui via el flag correspondiente.
    function Turn.GetBudget(kind)
        kind = tostring(kind or "")
        if not ETIQUETA[kind] then return 0 end
        local base = 1
        -- Flag PASIVO: sube el presupuesto siempre, sin gastar nada.
        local FLAG = { action = "extraTurnAction", bonus = "extraTurnBonus", reaction = "extraTurnReaction" }
        if FLAG[kind] and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
            and HarfordDnDFeatureEffects.HasFlag(FLAG[kind]) then
            base = base + 1
        end
        return base + math.max(0, math.floor(tonumber(ECONOMIA.extra[kind]) or 0))
    end

    function Turn.GetSpent(kind)
        return math.max(0, math.floor(tonumber(ECONOMIA.spent[tostring(kind or "")]) or 0))
    end

    function Turn.GetRemaining(kind)
        return math.max(0, Turn.GetBudget(kind) - Turn.GetSpent(kind))
    end

    -- Gasta y devuelve `cabia, restante`. `cabia` es false cuando ya no habia presupuesto; el
    -- gasto se registra igual, para que el contador refleje lo que de verdad se ha hecho.
    function Turn.Spend(kind, amount)
        kind = tostring(kind or "")
        if not ETIQUETA[kind] then return true, 0 end
        if not Turn.IsActive() then return true, Turn.GetBudget(kind) end
        amount = math.max(1, math.floor(tonumber(amount) or 1))
        local cabia = Turn.GetRemaining(kind) >= amount
        ECONOMIA.spent[kind] = Turn.GetSpent(kind) + amount
        Notify()
        return cabia, Turn.GetRemaining(kind)
    end

    -- Traduce el `cast` de un rasgo al presupuesto que consume. nil si no lo declara: el 92% de
    -- los rasgos todavia no lo dice, y adivinarlo por `type = "accion"` seria erroneo (en 5e
    -- "accion" es la categoria e incluye las adicionales).
    function Turn.KindFromFeature(feature)
        if type(feature) ~= "table" then return nil end
        local cast = tostring(feature.cast or ""):lower()
        return DE_CAST[cast]
    end

    -- Gasta lo que declare el rasgo. Devuelve nil si no declara nada (no se cuenta ni se avisa).
    function Turn.SpendForFeature(feature)
        local kind = Turn.KindFromFeature(feature)
        if not kind then return nil end
        local cabia, restante = Turn.Spend(kind, 1)
        if not cabia then
            Print(string.format("Ya habias gastado tu %s este turno.", ETIQUETA[kind]:lower()))
        end
        return cabia, restante, kind
    end

    -- Concede presupuesto EXTRA para el turno en curso. Lo usan los rasgos que dan una accion en
    -- vez de costarla; desaparece al empezar el siguiente turno, con el resto de la economia.
    function Turn.GrantExtra(kind, amount)
        kind = tostring(kind or "")
        if not ETIQUETA[kind] then return 0 end
        amount = math.max(1, math.floor(tonumber(amount) or 1))
        ECONOMIA.extra[kind] = math.max(0, math.floor(tonumber(ECONOMIA.extra[kind]) or 0)) + amount
        Notify()
        return ECONOMIA.extra[kind]
    end

    -- Traduce lo que un rasgo CONCEDE (`grantsTurnAction`) al presupuesto que sube.
    function Turn.GrantForFeature(feature)
        if type(feature) ~= "table" then return nil end
        local kind = DE_CAST[tostring(feature.grantsTurnAction or ""):lower()]
        if not kind then return nil end
        return kind, Turn.GrantExtra(kind, 1)
    end

    function Turn.Reset()
        ECONOMIA.spent = {}
        ECONOMIA.extra = {}
        Notify()
    end

    -- Texto compacto para la ficha: "Accion 1/1  Adicional 0/1  Reaccion 1/1".
    function Turn.StatusText()
        if not Turn.IsActive() then return "" end
        local partes = {}
        for _, kind in ipairs(ORDEN) do
            local restante, total = Turn.GetRemaining(kind), Turn.GetBudget(kind)
            local color = restante > 0 and "ff40ff40" or "ffff4040"
            partes[#partes + 1] = string.format("%s |c%s%d/%d|r",
                ETIQUETA[kind], color, restante, total)
        end
        return table.concat(partes, "  ")
    end

    -- Forma corta para la cabecera de la ficha, donde no hay ancho para los nombres enteros.
    local CORTA = { action = "Acc", bonus = "Adi", reaction = "Rea" }
    function Turn.StatusShort()
        if not Turn.IsActive() then return "" end
        local partes = {}
        for _, kind in ipairs(ORDEN) do
            local restante = Turn.GetRemaining(kind)
            partes[#partes + 1] = string.format("|c%s%s %d|r",
                restante > 0 and "ff40ff40" or "ffff4040", CORTA[kind], restante)
        end
        return table.concat(partes, "  ")
    end

    API.Turn = Turn
end

-- Que duraciones toca cada fase de un bloque. `fase` nil = iniciativa individual, donde el
-- cierre de un turno es la apertura del siguiente y por eso se mira contra la entrada ANTERIOR.
-- Devuelve: si toca, y contra quien casar ("actual" o "anterior").
function API.DurationTicks(duration, fase)
    local abre = (duration == "target_turn_start" or duration == "source_turn_start")
    local cierra = (duration == "target_turn_end" or duration == "source_turn_end")
    if not fase then
        if abre then return true, "actual" end
        if cierra then return true, "anterior" end
        return false
    end
    if fase == "inicio" then return abre, abre and "actual" or nil end
    if fase == "fin" then return cierra, cierra and "actual" or nil end
    return false
end

-- Y para la salvacion de fin de turno, que sigue la misma regla.
function API.EndSaveTicks(fase)
    if not fase then return true, "anterior" end
    return fase == "fin", (fase == "fin") and "actual" or nil
end

-- ─── PONERSE AL DIA TRAS UNA AUSENCIA ───────────────────────────────────────
-- Mientras estabas desconectado nadie bajaba tus contadores: tu cliente no corria y los demas no
-- tocan registros ajenos (solo los `authority`). Al volver, un estado que debio expirar hace tres
-- asaltos seguia entero, y nada lo delataba.
--
-- Con el numero de asalto en el aviso se puede saber cuantos se perdieron. Cada criatura actua UNA
-- vez por asalto, asi que una duracion por turno baja exactamente una vez por asalto: restar los
-- asaltos perdidos es la cuenta correcta, no una aproximacion.
--
-- Lo que NO se puede reconstruir son las salvaciones de fin de turno (`save_at_turn_end`): habria
-- que tirarlas, y tirar tres dados de golpe por algo que ya paso es inventarse la partida. Esas se
-- dejan como estan y se avisa, para que la mesa decida.
local POR_TURNO = {
    target_turn_start = true, source_turn_start = true,
    target_turn_end = true, source_turn_end = true, rounds = true,
}

function API.CatchUpRounds(perdidos)
    perdidos = math.floor(tonumber(perdidos) or 0)
    if perdidos <= 0 then return 0, 0 end
    LoadOwned()
    local bajados, caducados, aMano = 0, 0, 0
    local quitar = {}
    for key, bucket in pairs(S.units) do
        for id, record in pairs(bucket) do
            -- Solo lo PROPIO: de los demas informa su dueno, y su cliente ya hizo esta cuenta.
            if record.authority then
                if record.duration == "save_at_turn_end" then
                    aMano = aMano + 1
                elseif POR_TURNO[record.duration] and (tonumber(record.turns) or 0) > 0 then
                    local antes = tonumber(record.turns) or 0
                    record.turns = math.max(0, antes - perdidos)
                    bajados = bajados + 1
                    if record.turns <= 0 then
                        quitar[#quitar + 1] = { key = key, id = id }
                        caducados = caducados + 1
                    end
                end
            end
        end
    end
    for _, r in ipairs(quitar) do RemoveRecord(r.key, r.id, true) end
    SaveOwned()
    if bajados > 0 or aMano > 0 then
        local partes = {}
        if caducados > 0 then partes[#partes + 1] = caducados .. " expirado(s)" end
        if bajados - caducados > 0 then partes[#partes + 1] = (bajados - caducados) .. " al dia" end
        if aMano > 0 then partes[#partes + 1] = aMano .. " con salvacion, revisalos a mano" end
        Print(string.format("Te perdiste %d asalto(s): %s.", perdidos, table.concat(partes, ", ")))
    end
    Notify()
    return bajados, caducados
end

-- El ultimo asalto visto se PERSISTE junto a los estados: si viviera en memoria, al reconectar
-- valdria 0 y la cuenta de perdidos seria el asalto entero.
function API.NoteRound(asalto)
    asalto = math.floor(tonumber(asalto) or 0)
    if asalto <= 0 then return end
    local root = PersistRoot(true)
    local perfil = PlayerProfileName()
    root._asalto = type(root._asalto) == "table" and root._asalto or {}
    local visto = tonumber(root._asalto[perfil]) or 0
    -- Solo hacia adelante y solo si hay hueco: un salto de 1 es el asalto normal, no una ausencia.
    if visto > 0 and asalto > visto + 1 then
        API.CatchUpRounds(asalto - visto - 1)
    end
    root._asalto[perfil] = asalto
end

function API.OnTurnChanged(entry, serial)
    LoadOwned()
    if entry and entry.asalto then API.NoteRound(entry.asalto) end
    local turnKey = tostring(serial or 0) .. ":"
        .. tostring(entry and entry.kind == "bando"
            and ("bando:" .. tostring(entry.bando) .. ":" .. tostring(entry.fase or "inicio"))
            or (entry and (entry.guid or entry.id or entry.name)) or "")
    if S.lastTurnKey == turnKey then return end
    S.lastTurnKey = turnKey
    local previous = S.lastTurn
    S.lastTurn = entry and { guid = entry.guid or entry.id, name = entry.name, kind = entry.kind } or nil
    local removals = {}
    for key, bucket in pairs(S.units) do
        for id, record in pairs(bucket) do
            if not record.authority then
                -- Las caches remotas solo informan tiradas; su propietario gestiona duracion y retirada.
            else
            local duration = record.duration
            local fase = entry and entry.fase
            local toca, contra = API.DurationTicks(duration, fase)
            local quien = (contra == "anterior") and previous or entry
            local lado = (duration == "source_turn_start" or duration == "source_turn_end")
                and "source" or "target"
            local durationMatch = toca and IdentityMatches(record, quien, lado)
            local expire = durationMatch
            if durationMatch and (tonumber(record.turns) or 0) > 0 then
                record.turns = math.max(0, record.turns - 1)
                expire = record.turns <= 0
                if key == "player" then SaveOwned() end
            end
            local salva, salvaContra = API.EndSaveTicks(fase)
            local tocaSalvacion = salva and IdentityMatches(record,
                (salvaContra == "anterior") and previous or entry, "target")
            if duration == "save_at_turn_end" and tocaSalvacion then
                local saved = ResolveEndSave(key, id, record)
                if saved == nil then
                    record.pendingEndSave = true
                else
                    record.pendingEndSave = nil
                    expire = saved
                end
            end
            if duration == "rounds" and entry and entry.kind == "round" then
                record.turns = math.max(0, (tonumber(record.turns) or 1) - 1)
                expire = record.turns <= 0
                if key == "player" then SaveOwned() end
            end
            if expire and tonumber(record.appliedTurnSerial or 0) ~= tonumber(serial or -1) then
                removals[#removals + 1] = { key = key, id = id }
            end
            end
        end
    end
    for _, item in ipairs(removals) do
        if item.key == "player" then API.RemoveOwned(item.id); PublishState("remove", item.id)
        else
            local unit = FindUnitByGuid(item.key)
            if API.AdminHooks and API.AdminHooks.removeAura then pcall(API.AdminHooks.removeAura, { guid = item.key, unit = unit }, item.id) end
            RemoveRecord(item.key, item.id, true)
        end
    end
    if #removals > 0 then Notify() end
end

function API.ResolvePendingForUnit(unit)
    if not (unit and UnitExists and UnitExists(unit) and UnitGUID) then return 0 end
    local guid = UnitGUID(unit)
    local bucket = guid and S.units[guid]
    if not bucket then return 0 end
    local removals = {}
    local resolved = 0
    for id, record in pairs(bucket) do
        if record.pendingEndSave and record.duration == "save_at_turn_end" then
            local saved = ResolveEndSave(guid, id, record)
            if saved ~= nil then
                record.pendingEndSave = nil
                resolved = resolved + 1
                if saved then removals[#removals + 1] = id end
            end
        end
    end
    for _, id in ipairs(removals) do
        if API.AdminHooks and API.AdminHooks.removeAura then
            pcall(API.AdminHooks.removeAura, { guid = guid, unit = unit }, id)
        end
        RemoveRecord(guid, id, true)
    end
    if resolved > 0 then Notify() end
    return resolved
end

function API.RegisterListener(fn)
    if type(fn) == "function" then S.listeners[#S.listeners + 1] = fn end
end

function API.SetAdminHooks(hooks) API.AdminHooks = type(hooks) == "table" and hooks or nil end

local function PruneRuntime()
    local now = Now()
    for key, record in pairs(S.processed) do if (record.expires or 0) <= now then S.processed[key] = nil end end
    for key, pending in pairs(S.pending) do if (pending.expires or 0) <= now then S.pending[key] = nil end end
    for key, bucket in pairs(S.units) do
        if key ~= "player" then
        for id, record in pairs(bucket) do
                if record.expiresAt and record.expiresAt <= now then bucket[id] = nil end
            end
            if not next(bucket) then S.units[key] = nil end
        end
    end
end

local function CacheRemoteState(data, sender)
    if sender and sender ~= "" and data.targetName and data.targetName ~= "" then
        if ShortName(sender) ~= ShortName(data.targetName) then return end
    end
    local key = tostring(data.targetGuid or "")
    if key == "" then key = tostring(data.targetName or "") end
    if key == "" or not API.DEFS[data.conditionId] then return end
    local bucket = S.units[key]
    if not bucket then bucket = {}; S.units[key] = bucket end
    if data.op == "remove" then bucket[data.conditionId] = nil
    else
        local record = CopyRecord(data)
        record.id, record.expiresAt = data.conditionId, Now() + REMOTE_TTL
        bucket[data.conditionId] = record
    end
    if not next(bucket) then S.units[key] = nil end
    Notify()
end

-- Pedirle a otro jugador que cuente sus estados. Con el mismo enfriamiento por jugador que los
-- recursos: al cambiar de objetivo a menudo, sin el se llenaria el canal de peticiones.
local PETICION_ENFRIAMIENTO = 12
local ultimaPeticion = {}

-- Preguntar por los NPCs. Solo tiene sentido si hay combate montado: fuera de el no hay NPCs de
-- los que hablar, y preguntarlo seria ruido en el canal.
local ULTIMA_PETICION_NPC = 0
function API.RequestNpcStates()
    local store = _G.HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" or #store.entries == 0 then
        return false
    end
    local ahora = Now()
    if ahora - ULTIMA_PETICION_NPC < 12 then return false end
    ULTIMA_PETICION_NPC = ahora
    if not (HarfordSync and HarfordSync.SerializeNpcStatesRequest and HarfordSync.BestChannel) then
        return false
    end
    local canal = HarfordSync.BestChannel()
    if not canal then return false end
    return HarfordSync.Send(PREFIX, HarfordSync.SerializeNpcStatesRequest(
        HarfordClassColors.UnitFullName("player") or ""), canal)
end

-- ¿Soy el lider del grupo? Es la senal de "DM principal" que usa la mesa. Estando solo se cuenta
-- como lider: no hay nadie con mas derecho a contestar.
local function SoyElLider()
    if not (IsInGroup and IsInGroup()) then return true end
    return UnitIsGroupLeader and UnitIsGroupLeader("player") == true
end

API.RETRASO_DM_SECUNDARIO = 3

-- Contestar. Solo el DM: es quien aplico esos estados y quien tiene los registros con autoridad.
-- Un DM que NO es lider espera antes de responder, para dejar contestar primero al principal.
-- Quien puede informar de los estados de un NPC. Por defecto NADIE: el core no decide si eres DM
-- -- eso vive en HarfordAdmin, que sobrescribe esto en su PLAYER_LOGIN, igual que con
-- `HarfordTRP3.InsertGlanceLink`. Sin Admin cargado no se contesta, que es lo correcto: los
-- registros con autoridad sobre NPC los tiene el DM.
function API.CanAnswerNpcStates()
    return false
end

function API.SendNpcStatesTo(target, yaEsperado)
    if not (target and target ~= "") then return false end
    if not API.CanAnswerNpcStates() then return false end
    if not (yaEsperado or SoyElLider()) then
        -- No se descarta: si el lider no es DM, nadie contestaria y quien entra se queda a ciegas.
        if C_Timer and C_Timer.After then
            C_Timer.After(API.RETRASO_DM_SECUNDARIO, function() API.SendNpcStatesTo(target, true) end)
            return true
        end
    end
    local store = _G.HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return false end
    local enviados = 0
    for _, e in ipairs(store.entries) do
        local guid = tostring(e.guid or "")
        if tostring(e.kind or "") == "npc" and guid ~= "" then
            local estados = {}
            for _, activo in ipairs(API.GetActive(guid) or {}) do
                local rec = activo.record
                estados[#estados + 1] = {
                    id = activo.id,
                    duration = rec and rec.duration or "manual",
                    turns = rec and rec.turns or 0,
                    level = rec and rec.level or 0,
                }
            end
            -- Se manda tambien si esta VACIO: es la unica forma de que el otro borre lo que
            -- creyera que ese NPC llevaba encima. Callar dejaria estados fantasma.
            HarfordSync.SendConditionList(PREFIX, target, guid, tostring(e.name or ""), estados)
            enviados = enviados + 1
        end
    end
    return enviados > 0
end

function API.RequestStatesFrom(unit)
    if not (UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)) then return false end
    if UnitIsUnit and UnitIsUnit(unit, "player") then return false end
    local target = HarfordClassColors.UnitFullName(unit)
    if not target or target == "" then return false end
    local ahora = Now()
    if ahora - (ultimaPeticion[target] or 0) < PETICION_ENFRIAMIENTO then return false end
    ultimaPeticion[target] = ahora
    if not (HarfordSync and HarfordSync.SendConditionRequest2) then return false end
    return HarfordSync.SendConditionRequest2(PREFIX,
        HarfordClassColors.UnitFullName("player") or "", target)
end

-- Contestar: los estados PROPIOS, con lo que necesitan para pintarse y caducar bien.
function API.SendMyStatesTo(target)
    if not (target and target ~= "" and HarfordSync and HarfordSync.SendConditionList) then return false end
    LoadOwned()
    local estados = {}
    for _, activo in ipairs(API.GetActive("player")) do
        local rec = activo.record
        estados[#estados + 1] = {
            id = activo.id,
            duration = rec and rec.duration or "manual",
            turns = rec and rec.turns or 0,
            level = rec and rec.level or 0,
        }
    end
    return HarfordSync.SendConditionList(PREFIX, target,
        UnitGUID and UnitGUID("player") or "",
        HarfordClassColors.UnitFullName("player") or PlayerProfileName(), estados)
end

-- Guardar la respuesta. SUSTITUYE lo que hubiera de ese jugador: es una foto completa, asi que un
-- estado que ya no este en la lista es un estado que se ha quitado.
-- ¿Este guid es un NPC que ya esta en el orden de turnos? Es el unico caso en que se acepta que
-- alguien informe de estados ajenos: sin esto, cualquiera podria inventarse condiciones sobre
-- cualquier cosa.
EsNpcDeLosTurnos = function(guid)
    guid = tostring(guid or "")
    if guid == "" then return false end
    local store = _G.HarfordTurnOrderStore
    if type(store) ~= "table" or type(store.entries) ~= "table" then return false end
    for _, e in ipairs(store.entries) do
        if tostring(e.guid or "") == guid and tostring(e.kind or "") == "npc" then return true end
    end
    return false
end

-- De quien se acepto la ultima foto de cada NPC, y si venia del lider. Un DM secundario no puede
-- pisar lo que dijo el principal; el principal si puede corregir al secundario.
local ultimaFuenteNpc = {}
local VENTANA_DESEMPATE = 15

-- ¿Le dejo pisar la foto que ya tengo de este NPC? Puede haber varios DMs, pero el principal
-- suele ser el lider: el secundario no corrige al principal, y el principal si al secundario.
-- Devuelve true si la nueva fuente manda.
function API.FuenteNpcGana(previo, lider, sender, ahora, ventana)
    if not previo then return true end
    -- El mismo que hablo antes siempre puede actualizarse a si mismo.
    if ShortName(previo.sender or "") == ShortName(sender or "") then return true end
    if lider then return true end
    if not previo.lider then return true end
    return (ahora - (tonumber(previo.cuando) or 0)) >= (tonumber(ventana) or 0)
end

local function EsElLider(nombre)
    if not (nombre and nombre ~= "" and UnitIsGroupLeader) then return false end
    local unidad = HarfordClassColors and HarfordClassColors.FindUnitByName
        and HarfordClassColors.FindUnitByName(nombre)
    return unidad ~= nil and UnitIsGroupLeader(unidad) == true
end

function API.CacheStateList(guid, name, estados, sender)
    local key = guid ~= "" and guid or name
    if not key or key == "" then return false end

    -- Desempate entre DMs, solo para NPCs: los estados de un jugador siempre los cuenta el mismo.
    if EsNpcDeLosTurnos(guid) then
        local lider = EsElLider(sender)
        if not API.FuenteNpcGana(ultimaFuenteNpc[key], lider, sender, Now(), VENTANA_DESEMPATE) then
            return false
        end
        ultimaFuenteNpc[key] = { sender = sender, lider = lider, cuando = Now() }
    end
    if sender and sender ~= "" and name and name ~= "" then
        if ShortName(sender) ~= ShortName(name) and not EsNpcDeLosTurnos(guid) then return false end
    end
    local bucket = {}
    for _, e in ipairs(estados or {}) do
        if API.DEFS[e.id] then
            bucket[e.id] = {
                id = e.id, duration = e.duration, turns = e.turns, level = e.level,
                targetGuid = guid, targetName = name,
                created = Now(), expiresAt = Now() + REMOTE_TTL,
            }
        end
    end
    S.units[key] = next(bucket) and bucket or nil
    Notify()
    return true
end

function API.RequestPlayer(unit, conditionId, apply, options)
    conditionId = tostring(conditionId or "")
    if not API.DEFS[conditionId] or not (UnitExists and UnitExists(unit) and UnitIsPlayer and UnitIsPlayer(unit)) then
        return false, "Objetivo jugador invalido"
    end
    if UnitIsUnit and UnitIsUnit(unit, "player") then
        local ok, err
        if apply then ok, err = API.ApplyOwned(conditionId, options)
        else ok, err = API.RemoveOwned(conditionId) end
        if ok and (not apply or (S.units.player and S.units.player[conditionId])) then
            PublishState(apply and "apply" or "remove", conditionId,
                apply and S.units.player and S.units.player[conditionId] or nil)
        end
        return ok, err
    end
    local target = HarfordClassColors.UnitFullName(unit)
    if not target or target == "" then return false, "Jugador sin nombre" end
    S.serial = (S.serial % 999999) + 1
    local opId = tostring(math.floor(Now() * 1000)) .. "." .. tostring(S.serial)
    local guid = UnitGUID and UnitGUID(unit) or ""
    S.pending[opId] = {
        conditionId = conditionId, apply = apply == true, targetGuid = guid, targetName = target,
        sourceGuid = options and options.sourceGuid or "", sourceName = options and options.sourceName or "",
        duration = options and options.duration or "manual", turns = options and options.turns or 0,
        saveAbility = options and options.saveAbility or "", saveDC = options and options.saveDC or 0,
        persist = options and options.persist == true,
        vars = options and options.vars or nil,
        expires = Now() + REQUEST_TTL,
    }
    local payload = {
        id = opId, op = apply and "apply" or "remove", conditionId = conditionId,
        sourceGuid = options and options.sourceGuid or "",
        sourceName = options and options.sourceName or "",
        duration = options and options.duration, turns = options and options.turns,
        saveAbility = options and options.saveAbility, saveDC = options and options.saveDC,
        persist = options and options.persist == true,
        vars = options and options.vars or nil,
    }
    local ok, err = HarfordSync.SendConditionRequest(PREFIX, target, payload)
    if not ok then S.pending[opId] = nil end
    return ok, err
end

function API.HandleMessage(message, sender)
    if not HarfordSync then return false end
    local request = HarfordSync.DeserializeConditionRequest and HarfordSync.DeserializeConditionRequest(message)
    if request then
        if not IsTrustedSender(sender) then return true end
        PruneRuntime()
        local cacheKey = tostring(sender or "") .. "|" .. request.id
        local cached = S.processed[cacheKey]
        if cached then HarfordSync.SendConditionResult(PREFIX, sender, cached.result); return true end
        local ok, status
        if request.op == "apply" then ok, status = API.ApplyOwned(request.conditionId, request)
        else ok, status = API.RemoveOwned(request.conditionId) end
        status = status or (ok and (request.op == "apply" and "applied" or "removed") or "error")
        local result = { id = request.id, conditionId = request.conditionId, status = status }
        S.processed[cacheKey] = { expires = Now() + REQUEST_TTL, result = result }
        if sender and sender ~= "" then HarfordSync.SendConditionResult(PREFIX, sender, result) end
        if ok and (request.op == "remove" or (S.units.player and S.units.player[request.conditionId])) then
            local record = S.units.player and S.units.player[request.conditionId]
            PublishState(request.op, request.conditionId, record)
        end
        return true
    end
    local result = HarfordSync.DeserializeConditionResult and HarfordSync.DeserializeConditionResult(message)
    if result then
        local pending = S.pending[result.id]
        if pending then
            if result.conditionId ~= pending.conditionId or (sender and sender ~= ""
                and ShortName(sender) ~= ShortName(pending.targetName)) then return true end
            S.pending[result.id] = nil
            if result.status == "applied" and NeedsMetadataRecord(API.DEFS[pending.conditionId], pending) then
                CacheRemoteState({
                    op = "apply", conditionId = pending.conditionId, targetGuid = pending.targetGuid, targetName = pending.targetName,
                    sourceGuid = pending.sourceGuid, sourceName = pending.sourceName, duration = pending.duration,
                    turns = pending.turns, saveAbility = pending.saveAbility, saveDC = pending.saveDC,
                    persist = pending.persist == true,
                }, sender)
            elseif result.status == "removed" then
                CacheRemoteState({ op = "remove", conditionId = pending.conditionId, targetGuid = pending.targetGuid, targetName = pending.targetName }, sender)
            elseif result.status == "immune" then
                Print(ShortName(pending.targetName) .. " es inmune a " .. API.DEFS[pending.conditionId].label .. ".")
            end
        end
        return true
    end
    local state = HarfordSync.DeserializeConditionState and HarfordSync.DeserializeConditionState(message)
    if state then
        if IsTrustedSender(sender) then CacheRemoteState(state, sender) end
        return true
    end
    -- Un jugador sin permiso delega en mi un efecto que ya ha resuelto por su cuenta.
    if HarfordSync.DeserializeNpcEffect then
        local guid, tipo, valor, autor = HarfordSync.DeserializeNpcEffect(message)
        if guid then
            if IsTrustedSender(sender) then API.RecibirEfectoNpc(guid, tipo, valor, autor, sender) end
            return true
        end
    end
    -- Alguien acaba de entrar y pregunta por los NPCs. Solo contesta el DM.
    if HarfordSync.DeserializeNpcStatesRequest then
        local quien = HarfordSync.DeserializeNpcStatesRequest(message)
        if quien then
            if IsTrustedSender(sender) then API.SendNpcStatesTo(sender) end
            return true
        end
    end
    -- Alguien pregunta que llevo puesto: se le contesta con la lista entera.
    if HarfordSync.DeserializeConditionRequest2 then
        local requester = HarfordSync.DeserializeConditionRequest2(message)
        if requester then
            if IsTrustedSender(sender) then API.SendMyStatesTo(sender) end
            return true
        end
    end
    -- La respuesta de otro: es una foto completa y sustituye lo que hubiera suyo.
    if HarfordSync.DeserializeConditionList then
        local guid, name, estados = HarfordSync.DeserializeConditionList(message)
        if guid then
            if IsTrustedSender(sender) then API.CacheStateList(guid, name, estados, sender) end
            return true
        end
    end
    return false
end

local function ReconcileOwnedAuras()
    local bucket = S.units.player
    if not bucket then return end
    local removed = {}
    for id, record in pairs(bucket) do
        local def = API.DEFS[id]
        if def and def.auraId and Now() - (record.created or 0) > AURA_GRACE
            and not UnitHasAuraId("player", def.auraId) then
            removed[#removed + 1] = id
        end
    end
    for _, id in ipairs(removed) do
        RemoveRecord("player", id, true)
        PublishState("remove", id)
    end
    if #removed > 0 then Notify() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
-- Al seleccionar un NPC se ejecuta lo que quedara apuntado para el: es el unico momento en que se
-- le puede tocar el aura. Mismo enganche que usa el motor de areas para su cola.
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        API.FlushPendingAuras("target")
        return
    end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        LoadOwned()
        if not S.myTurnHooked and HarfordTurnOrderAPI and HarfordTurnOrderAPI.RegisterMyTurnListener then
            S.myTurnHooked = true
            -- Accion, adicional y reaccion se renuevan al EMPEZAR tu turno (en 5e la reaccion
            -- tambien, no al terminarlo).
            HarfordTurnOrderAPI.RegisterMyTurnListener(function() API.Turn.Reset() end)
        end
        if not S.turnHooked and HarfordTurnOrderAPI and HarfordTurnOrderAPI.RegisterTurnChangedListener then
            S.turnHooked = true
            HarfordTurnOrderAPI.RegisterTurnChangedListener(API.OnTurnChanged)
        end
        Notify()
        if C_Timer and C_Timer.After then
            C_Timer.After(4, function() API.RequestNpcStates() end)
        end
    elseif event == "UNIT_AURA" then
        if unit == "player" then ReconcileOwnedAuras() end
        if unit == "player" or unit == "target" or unit == "focus" then Notify() end
    elseif event == "GROUP_ROSTER_UPDATE" then
        PruneRuntime()
        -- Entrar al grupo a mitad de combate no pasa por PLAYER_ENTERING_WORLD. El enfriamiento de
        -- la propia peticion evita que un roster movido dispare una rafaga.
        API.RequestNpcStates()
    end
end)
