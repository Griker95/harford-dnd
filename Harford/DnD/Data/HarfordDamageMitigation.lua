-- HarfordDamageMitigation: resuelve si una unit es inmune/resistente/vulnerable a un
-- tipo de dano leyendo el stat block TRP3 ya parseado por HarfordTRP3.GetNPCStatBlock.
--
-- Vive separado de HarfordDamageTypes porque ese modulo solo guarda identidad/presentacion.
-- El consumidor canonico es HarfordDamage.lua, que llama Resolve(...) + ApplyMultiplier(...).
--
-- Funciona tambien para "player" porque HarfordTRP3.GetNPCStatBlock cae a perfil
-- de jugador (CollectRawAboutText) cuando no hay companion NPC.

HarfordDamageMitigation = HarfordDamageMitigation or {}

local STATUS_NORMAL     = "normal"
local STATUS_RESISTANT  = "resistant"
local STATUS_IMMUNE     = "immune"
local STATUS_VULNERABLE = "vulnerable"

HarfordDamageMitigation.STATUS = {
    NORMAL     = STATUS_NORMAL,
    RESISTANT  = STATUS_RESISTANT,
    IMMUNE     = STATUS_IMMUNE,
    VULNERABLE = STATUS_VULNERABLE,
}

-- Palabras (sin tildes, minusculas) que indican el tipo en el texto libre del stat block.
-- Si el parser TRP3 captura "fuego, frio" como una sola entrada, basta con que cualquiera
-- de las palabras del tipo aparezca en la cadena.
HarfordDamageMitigation.MITIGATION_MAP = {
    slashing    = { words = { "cortante", "slashing" } },
    piercing    = { words = { "perforante", "piercing" } },
    bludgeoning = { words = { "contundente", "bludgeoning" } },

    fire        = { words = { "fuego", "fire" } },
    cold        = { words = { "frio", "cold" } },
    lightning   = { words = { "rayo", "relampago", "lightning" } },
    thunder     = { words = { "trueno", "thunder" } },
    acid        = { words = { "acido", "acid" } },
    poison      = { words = { "veneno", "poison" } },
    necrotic    = { words = { "necrotico", "necrotic" } },
    radiant     = { words = { "radiante", "radiant" } },
    psychic     = { words = { "psiquico", "psychic" } },
    force       = { words = { "fuerza", "force" } },
}

-- Normaliza una cadena (minusculas, sin tildes, sin marcado TRP3 residual).
local function Normalize(s)
    s = HarfordClassColors.StripAccents(s):lower()
    s = s:gsub("{[^}]*}", "")
    return s
end

local function ContainsAny(haystack, words)
    if not haystack or haystack == "" then return false end
    local n = Normalize(haystack)
    for _, word in ipairs(words) do
        if n:find(word, 1, true) then return true end
    end
    return false
end

-- Calificadores que limitan una defensa a ataques NO magicos. El stat block es texto libre, asi
-- que aparecen redactados de muchas formas ("contundente de ataques no magicos", "bludgeoning
-- from nonmagical attacks"). "no magic" cubre magico/magicos/magica/magicas ya sin tildes.
local NO_MAGICO = { "no magic", "nonmagical", "non magical", "non-magical" }

-- `golpeMagico` viene del atacante: si el golpe cuenta como magico, las entradas calificadas como
-- "no magicas" se IGNORAN, que es justo lo que concede Golpes empoderados por el chi. Sin ese dato
-- el comportamiento es el de antes: cualquier entrada del tipo cuenta.
local function ListMatchesType(list, words, golpeMagico)
    if type(list) ~= "table" then return false end
    for _, entry in ipairs(list) do
        if ContainsAny(entry, words) then
            if not (golpeMagico and ContainsAny(entry, NO_MAGICO)) then return true end
        end
    end
    return false
end

local function AddCandidate(out, seen, value)
    value = tostring(value or "")
    if value == "" or seen[value] then return end
    seen[value] = true
    out[#out + 1] = value
end

local function GetUnitProfileCandidates(unit)
    local out, seen = {}, {}
    local full = GetUnitName and GetUnitName(unit, true)
    AddCandidate(out, seen, full)
    if Ambiguate then AddCandidate(out, seen, Ambiguate(full or "", "short")) end

    if UnitName then
        local name, realm = UnitName(unit)
        AddCandidate(out, seen, name)
        realm = tostring(realm or "")
        if name and name ~= "" and realm ~= "" then
            AddCandidate(out, seen, name .. "-" .. realm:gsub("%s+", ""))
        end
    end
    return out
end

local trp3ProgressionChecked = {}

local function EnsureUnitInspectProgression(unit, profileName)
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile and HarfordTRP3.ParsePlayerSheet) then
        return false
    end
    if not (HarfordDnDProgression and HarfordDnDProgression.SetInspectDataFromTRP3Sheet) then
        return false
    end

    local key = tostring(profileName or "")
    if key == "" and UnitGUID then key = tostring(UnitGUID(unit) or "") end
    if key == "" or trp3ProgressionChecked[key] then return false end

    local profile = HarfordTRP3.GetPlayerProfile(unit)
    if not profile then return false end

    trp3ProgressionChecked[key] = true
    local sheet = HarfordTRP3.ParsePlayerSheet(profile)
    if type(sheet) ~= "table" then return false end
    return HarfordDnDProgression.SetInspectDataFromTRP3Sheet(profileName, sheet)
end

local function ResolvePlayerFeatureStatus(unit, typeText)
    if not (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetCachedDamageStatus) then
        return nil
    end

    if UnitIsUnit and UnitIsUnit(unit, "player") then
        local name = UnitName and UnitName("player")
        local status = HarfordDnDFeatureEffects.GetCachedDamageStatus(typeText, name)
        if not status and HarfordDnDFeatureEffects.Prime then
            HarfordDnDFeatureEffects.Prime(name)
            status = HarfordDnDFeatureEffects.GetCachedDamageStatus(typeText, name)
        end
        return status
    end

    if not (HarfordDnDProgression and HarfordDnDProgression.HasProgression) then
        return nil
    end
    for _, profileName in ipairs(GetUnitProfileCandidates(unit)) do
        if not HarfordDnDProgression.HasProgression(profileName) then
            EnsureUnitInspectProgression(unit, profileName)
        end
        if HarfordDnDProgression.HasProgression(profileName) then
            local status = HarfordDnDFeatureEffects.GetCachedDamageStatus(typeText, profileName)
            if not status and HarfordDnDFeatureEffects.Prime then
                HarfordDnDFeatureEffects.Prime(profileName)
                status = HarfordDnDFeatureEffects.GetCachedDamageStatus(typeText, profileName)
            end
            if status then return status end
        end
    end
    return nil
end

-- Resuelve el status de mitigacion de `unit` frente a `damageKey`.
-- Devuelve uno de: "immune" | "resistant" | "vulnerable" | "normal".
-- Si no hay stat block disponible, asume "normal" (sin mitigacion).
function HarfordDamageMitigation.Resolve(unit, damageKey, opts)
    if not damageKey then return STATUS_NORMAL end
    local mapping = HarfordDamageMitigation.MITIGATION_MAP[damageKey]
    if not mapping then return STATUS_NORMAL end

    local stats
    if HarfordTRP3 and HarfordTRP3.GetNPCStatBlock then
        stats = HarfordTRP3.GetNPCStatBlock(unit or "target")
    end
    if not stats then return STATUS_NORMAL end

    local words = mapping.words
    local golpeMagico = (opts and opts.magical) and true or false

    -- Orden de prioridad: inmunidad antes que resistencia/vulnerabilidad.
    if ListMatchesType(stats.immunities, words, golpeMagico) then
        return STATUS_IMMUNE
    end
    -- Resistencia y vulnerabilidad se cancelan entre si (regla 5e).
    local isResistant  = ListMatchesType(stats.resistances, words, golpeMagico)
    local isVulnerable = ListMatchesType(stats.vulnerabilities, words, golpeMagico)
    if isResistant and isVulnerable then
        return STATUS_NORMAL
    elseif isResistant then
        return STATUS_RESISTANT
    elseif isVulnerable then
        return STATUS_VULNERABLE
    end
    return STATUS_NORMAL
end

-- Aplica el multiplicador 5e estandar. Para vulnerabilidad se duplica antes
-- de cualquier otra operacion; para resistencia se divide a la mitad
-- (redondeando hacia abajo). Inmunidad colapsa el dano a 0.
function HarfordDamageMitigation.ApplyMultiplier(amount, status)
    amount = tonumber(amount) or 0
    if amount <= 0 then return 0 end

    if status == STATUS_IMMUNE then
        return 0
    elseif status == STATUS_RESISTANT then
        return math.max(1, math.floor(amount / 2))
    elseif status == STATUS_VULNERABLE then
        return amount * 2
    end
    return amount
end

-- Marcador coloreado de una sola letra para incrustar en la tirada de daño:
-- R azul (resistente), V rojo (vulnerable), I amarillo (inmune). "" si normal.
HarfordDamageMitigation.MARKERS = {
    [STATUS_RESISTANT]  = { letter = "R", color = "ff4fa3ff" },
    [STATUS_VULNERABLE] = { letter = "V", color = "ffff4040" },
    [STATUS_IMMUNE]     = { letter = "I", color = "ffffd000" },
}

function HarfordDamageMitigation.Marker(status)
    local m = HarfordDamageMitigation.MARKERS[status]
    if not m then return "" end
    return "|c" .. m.color .. m.letter .. "|r"
end

-- Encuentra la damageKey canonica a partir del texto libre del tipo de daño
-- (p.ej. "cortante" -> "slashing"). nil si no se reconoce.
function HarfordDamageMitigation.KeyFromTypeText(typeText)
    if not typeText or typeText == "" then return nil end
    for key, mapping in pairs(HarfordDamageMitigation.MITIGATION_MAP) do
        if ContainsAny(typeText, mapping.words) then
            return key
        end
    end
    return nil
end

-- Resuelve el status de mitigacion directamente desde el texto libre del tipo.
function HarfordDamageMitigation.ResolveByTypeText(unit, typeText, opts)
    local key = HarfordDamageMitigation.KeyFromTypeText(typeText)
    if not key then return STATUS_NORMAL end
    return HarfordDamageMitigation.Resolve(unit, key, opts)
end

-- Punto de entrada para la tirada de daño: solo mitiga si `unit` es un NPC
-- (las defensas no afectan a victimas jugador). Devuelve:
--   amountAplicado, status, marcadorColoreado
-- ¿Resuelve el objetivo su propia mitigacion? Si es OTRO jugador, si: su cliente recibe el dano en
-- bruto (`DNDDMG`) y aplica SUS resistencias, sus reducciones y su vida temporal, que son datos que
-- aqui solo se tienen por una copia cacheada que puede faltar o estar vieja.
--
-- Es la pieza que migra `RADJ` al modelo del motor de area sin tocar los sitios que calculan dano:
-- ellos siguen llamando a `ForTarget` igual, y aqui se decide si mitigar o dejar pasar el bruto.
-- Contra un NPC o contra uno mismo NO aplica: no hay otro cliente que lo resuelva.
function HarfordDamageMitigation.TargetResolvesOwnDamage(unit)
    if not (unit and UnitExists and UnitExists(unit)) then return false end
    if not (UnitIsPlayer and UnitIsPlayer(unit)) then return false end
    if UnitIsUnit and UnitIsUnit(unit, "player") then return false end
    return true
end

-- `opts.magical`: el golpe cuenta como magico (Golpes empoderados por el chi, arma encantada...),
-- asi que las defensas limitadas a ataques no magicos no se le aplican.
function HarfordDamageMitigation.ForTarget(unit, typeText, amount, opts)
    amount = tonumber(amount) or 0
    if not unit or not (UnitExists and UnitExists(unit)) then
        return amount, STATUS_NORMAL, ""
    end
    if HarfordDamageMitigation.TargetResolvesOwnDamage(unit) then
        -- Bruto: lo mitiga su cliente. El marcador queda vacio a proposito -- desde aqui no se
        -- sabe si es resistente, y fingir un marcador seria peor que no poner ninguno.
        return amount, STATUS_NORMAL, ""
    end
    local status = STATUS_NORMAL
    if UnitIsPlayer and UnitIsPlayer(unit) then
        status = ResolvePlayerFeatureStatus(unit, typeText)
            or HarfordDamageMitigation.ResolveByTypeText(unit, typeText, opts)
            or STATUS_NORMAL
    else
        status = HarfordDamageMitigation.ResolveByTypeText(unit, typeText, opts)
    end

    -- El tipo y `opts` hacen falta: hay condiciones que solo resisten ciertos tipos y solo de
    -- golpes no magicos (Piel de Hierro). Sin ellos resistiria cualquier cosa.
    local conditionStatus = HarfordDnDConditions and HarfordDnDConditions.GetDamageStatus
        and HarfordDnDConditions.GetDamageStatus(unit, typeText, opts)
    if conditionStatus == STATUS_IMMUNE or status == STATUS_IMMUNE then
        status = STATUS_IMMUNE
    elseif (conditionStatus == STATUS_RESISTANT and status == STATUS_VULNERABLE)
        or (conditionStatus == STATUS_VULNERABLE and status == STATUS_RESISTANT) then
        status = STATUS_NORMAL
    elseif status == STATUS_NORMAL and conditionStatus then
        status = conditionStatus
    end
    -- Dote "Versado en un elemento" del ATACANTE (viaja en la peticion de area): la resistencia
    -- a ese tipo se ignora. La inmunidad no -- el manual solo perdona la resistencia.
    if opts and opts.ignoreResist and status == STATUS_RESISTANT then
        status = STATUS_NORMAL
    end
    local applied = HarfordDamageMitigation.ApplyMultiplier(amount, status)
    -- Dote "Maestro de armaduras pesadas" (flag heavyArmorMaster): -3 al dano FISICO no magico
    -- que recibe EL PROPIO jugador llevando armadura pesada. Solo cuando la victima es este
    -- cliente: los golpes a otros jugadores llegan en bruto y los mitiga su propio cliente
    -- (TargetResolvesOwnDamage), que aplicara su propia dote.
    if applied > 0 and UnitIsUnit and UnitIsUnit(unit, "player")
        and not (opts and opts.magical)
        and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasFlag
        and HarfordDnDFeatureEffects.HasFlag("heavyArmorMaster") then
        local clave = HarfordDamageMitigation.KeyFromTypeText and HarfordDamageMitigation.KeyFromTypeText(typeText)
        local def = clave and HarfordDamageTypes and HarfordDamageTypes.DEFS and HarfordDamageTypes.DEFS[clave]
        local pesada = HarfordDnDItems and HarfordDnDItems.GetEquippedArmorCategory
            and HarfordDnDItems.GetEquippedArmorCategory() == "pesada"
        if pesada and def and def.category == "fisico" then
            applied = math.max(0, applied - 3)
        end
    end
    return applied, status, HarfordDamageMitigation.Marker(status)
end
