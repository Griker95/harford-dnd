------------------------------------------------------------
-- HarfordDnDConcentration - Concentracion en conjuros (Manual del Jugador, "Duracion").
--
-- Regla literal del manual:
--   * No puedes concentrarte en dos conjuros a la vez: lanzar otro que requiera concentracion
--     termina el primero.
--   * Puedes dejar de concentrarte cuando quieras, sin gastar una accion.
--   * Al recibir dano haces una salvacion de Constitucion para mantenerla. La CD es 10 o la
--     MITAD DEL DANO SUFRIDO, lo que sea mayor. Si el dano viene de varias fuentes, una
--     salvacion POR CADA FUENTE.
--   * Se pierde al quedar incapacitado o al morir.
--
-- Que hace este modulo y que no: lleva la cuenta de que conjuro se esta concentrando y aplica
-- las tres roturas. NO decide cuando se lanza un conjuro ni resuelve sus efectos: eso vive en
-- el compendio. La tirada de salvacion sale por la via normal de tiradas, para que la mesa la
-- vea como cualquier otra.
--
-- Estado EFIMERO a proposito: la concentracion no sobrevive a un /reload, igual que no
-- sobrevive a la inconsciencia. Persistirla daria un estado fantasma imposible de limpiar.
------------------------------------------------------------

HarfordDnDConcentration = HarfordDnDConcentration or {}
local API = HarfordDnDConcentration

local current = nil   -- { spell = "Nombre", spellId = n, startedAt = time }

local function Print(text)
    if HarfordChat and HarfordChat.Print then HarfordChat.Print(text) end
end

local function Announce(text)
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({ type = "info", label = text })
    else
        Print(text)
    end
end

function API.Get()
    return current
end

function API.IsActive()
    return current ~= nil
end

function API.GetSpellName()
    return current and current.spell or nil
end

-- Empieza a concentrarse. Si ya habia otro conjuro, lo termina: el manual no permite dos.
function API.Begin(spellName, spellId)
    spellName = tostring(spellName or "")
    if spellName == "" then return false, "Falta el nombre del conjuro" end
    local previo = current and current.spell
    current = { spell = spellName, spellId = tonumber(spellId), startedAt = (time and time()) or 0 }
    if previo and previo ~= spellName then
        Announce(string.format("deja de concentrarse en %s para concentrarse en %s.", previo, spellName))
    else
        Announce(string.format("se concentra en %s.", spellName))
    end
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

-- Soltar la concentracion. `reason` describe por que, para el aviso de mesa.
function API.Break(reason)
    if not current then return false end
    local spell = current.spell
    current = nil
    if reason then
        Announce(string.format("pierde la concentracion en %s (%s).", spell, reason))
    else
        Announce(string.format("deja de concentrarse en %s.", spell))
    end
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true, spell
end

------------------------------------------------------------
-- Rotura por dano
------------------------------------------------------------

-- CD del manual: 10 o la mitad del dano, lo que sea mayor.
function API.GetSaveDC(damage)
    return math.max(10, math.floor((tonumber(damage) or 0) / 2))
end

-- Una salvacion POR FUENTE de dano. Devuelve mantiene(bool), total, cd.
-- `damage` es el dano de ESA fuente, ya mitigado.
function API.OnDamage(damage, sourceLabel)
    if not current then return nil end
    damage = tonumber(damage) or 0
    if damage <= 0 then return nil end

    local dc = API.GetSaveDC(damage)
    local d20 = math.random(1, 20)
    -- Salvacion de Constitucion: modificador + bonificador de competencia si la tiene.
    local bonus = 0
    if HarfordDnDCalc then
        bonus = tonumber(HarfordDnDCalc.GetAbilityMod("Constitucion")) or 0
        if HarfordDnDCalc.GetSaveProf and HarfordDnDCalc.GetSaveProf("Constitucion") then
            bonus = bonus + (tonumber(HarfordDnDCalc.GetPB and HarfordDnDCalc.GetPB()) or 0)
        end
    end
    local total = d20 + bonus
    -- Un 1 natural falla siempre y un 20 natural la mantiene, como cualquier salvacion.
    local mantiene = d20 ~= 1 and (d20 == 20 or total >= dc)

    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = string.format("Concentracion: %s (CD %d)%s", current.spell, dc,
                sourceLabel and (" <" .. tostring(sourceLabel) .. ">") or ""),
            total = total,
            dice = tostring(d20),
            modifiers = bonus ~= 0 and string.format("%s%d", bonus > 0 and "+" or "", bonus) or "",
            critical = d20 == 20 and "CRITICO" or (d20 == 1 and "FALLO" or nil),
        })
    end

    if not mantiene then API.Break("dano recibido") end
    return mantiene, total, dc
end

------------------------------------------------------------
-- Rotura por estado
------------------------------------------------------------

-- Se pierde al quedar incapacitado o al morir. Lo comprueba en cada cambio de condiciones en
-- vez de sondear: el motor de condiciones ya avisa cuando algo cambia.
local function CheckIncapacitated()
    if not current then return end
    if not (HarfordDnDConditions and HarfordDnDConditions.Has) then return end
    for _, id in ipairs({ "incapacitated", "paralyzed", "petrified", "stunned", "sleeping" }) do
        if HarfordDnDConditions.Has("player", id) then
            API.Break("queda incapacitado")
            return
        end
    end
    -- Nivel 6 de cansancio es la muerte.
    if HarfordDnDConditions.GetExhaustion and HarfordDnDConditions.GetExhaustion("player") >= 6 then
        API.Break("muere")
    end
end

function API.OnConditionsChanged()
    CheckIncapacitated()
end

-- Vida a 0: inconsciente, se pierde la concentracion.
function API.OnHealthChanged(current_hp)
    if current and (tonumber(current_hp) or 1) <= 0 then
        API.Break("cae inconsciente")
    end
end

do
    -- El motor de condiciones publica sus cambios; si existe ese registro, se engancha.
    if HarfordDnDConditions and HarfordDnDConditions.RegisterListener then
        HarfordDnDConditions.RegisterListener(API.OnConditionsChanged)
    end
end
