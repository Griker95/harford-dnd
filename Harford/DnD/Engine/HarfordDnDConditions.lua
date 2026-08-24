-- HarfordDnDConditions: catalogo y motor de condiciones de combate.
-- Las auras son la fuente de verdad cuando contienen toda la informacion. Solo
-- se guarda estado cuando hacen falta metadatos (fuente/duracion/CD) o no existe
-- una aura visual conocida.

HarfordDnDConditions = HarfordDnDConditions or {}
local API = HarfordDnDConditions

local PREFIX = "DND5EARC"
local AURA_GRACE = 2
local REMOTE_TTL = 600
local REQUEST_TTL = 60
local MAX_STATES_PER_UNIT = 32

API.ORDER = {
    "blinded", "charmed", "deafened", "frightened", "grappled",
    "incapacitated", "invisible", "paralyzed", "petrified", "poisoned",
    "prone", "restrained", "stunned", "sleeping", "silenced", "rooted", "slowed",
    "disarmed", "exposed_armor", "burning", "frozen", "chilled", "blessed",
    "bioluminescence", "dancing_lights", "elunes_grace", "exhaustion",
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
        effects = {},
    },
    palabra_fortaleza = {
        label = "Fortaleza", tracking = "state",
        description = "Tiene ventaja en la proxima tirada de salvacion indicada por la Palabra de Poder.",
        effects = { { kind = "rollMode", rolls = { save = true }, mode = "adv" } },
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
local function NormalizeVars(vars)
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
    for _, fn in ipairs(S.listeners) do pcall(fn) end
    if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
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
    local removed = RemoveRecord(StateKey(unit, guid, name), tostring(id or ""), true)
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

function API.GetDamageStatus(ref)
    for _, effect in ipairs(EffectsFor(ref or "player")) do if effect.kind == "resistAll" then return "resistant" end end
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

local function IdentityMatches(record, entry, which)
    if not (record and entry) then return false end
    local guid = tostring(record[which .. "Guid"] or "")
    local name = tostring(record[which .. "Name"] or "")
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

function API.OnTurnChanged(entry, serial)
    LoadOwned()
    local turnKey = tostring(serial or 0) .. ":" .. tostring(entry and (entry.guid or entry.id or entry.name) or "")
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
            local durationMatch = (duration == "target_turn_start" and IdentityMatches(record, entry, "target"))
                or (duration == "source_turn_start" and IdentityMatches(record, entry, "source"))
                or (duration == "target_turn_end" and IdentityMatches(record, previous, "target"))
                or (duration == "source_turn_end" and IdentityMatches(record, previous, "source"))
            local expire = durationMatch
            if durationMatch and (tonumber(record.turns) or 0) > 0 then
                record.turns = math.max(0, record.turns - 1)
                expire = record.turns <= 0
                if key == "player" then SaveOwned() end
            end
            if duration == "save_at_turn_end" and IdentityMatches(record, previous, "target") then
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
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        LoadOwned()
        if not S.turnHooked and HarfordTurnOrderAPI and HarfordTurnOrderAPI.RegisterTurnChangedListener then
            S.turnHooked = true
            HarfordTurnOrderAPI.RegisterTurnChangedListener(API.OnTurnChanged)
        end
        Notify()
    elseif event == "UNIT_AURA" then
        if unit == "player" then ReconcileOwnedAuras() end
        if unit == "player" or unit == "target" or unit == "focus" then Notify() end
    elseif event == "GROUP_ROSTER_UPDATE" then
        PruneRuntime()
    end
end)
