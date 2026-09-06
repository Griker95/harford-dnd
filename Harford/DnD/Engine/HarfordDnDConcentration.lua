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
-- SIN anuncio propio (2026-09-05, decision de mesa "una linea por gesto"): la linea del
-- lanzamiento ya sale con el desenlace CONCENTRACION en morado. El estado visible es el
-- estado NUESTRO `concentrando` de la tira Harford (se probo un aura de servidor, la 19746, y
-- el cliente moderno ya no la tiene); el conjuro activo viaja como `sourceName` del registro,
-- que la tira pinta en cian tras el titulo y el sync de estados ya reparte a los demas.
function API.Begin(spellName, spellId)
    spellName = tostring(spellName or "")
    if spellName == "" then return false, "Falta el nombre del conjuro" end
    current = { spell = spellName, spellId = tonumber(spellId), startedAt = (time and time()) or 0 }
    if HarfordDnDConditions and HarfordDnDConditions.ApplyOwned then
        -- Volver a aplicarlo con otro conjuro SUSTITUYE el registro: el detalle cambia solo.
        current.stateApplied = HarfordDnDConditions.ApplyOwned("concentrando",
            { sourceName = spellName }) == true
        -- PUBLICAR: el resto de clientes necesita el apply al instante (no solo por el
        -- snapshot bajo peticion), porque el REMOVE de este mismo estado es lo que les
        -- dispara la caida de los estados de conjuro que mantengas sobre ellos.
        if current.stateApplied and HarfordDnDConditions.PublishOwnedCondition then
            HarfordDnDConditions.PublishOwnedCondition("concentrando", "apply")
        end
    end
    if HarfordDnDStore and HarfordDnDStore.RefreshMainUI then HarfordDnDStore.RefreshMainUI() end
    return true
end

-- Soltar la concentracion. `reason` describe por que, para el aviso de mesa.
function API.Break(reason)
    if not current then return false end
    local spell = current.spell
    -- `current` se vacia ANTES de retirar el estado: la retirada dispara Notify y el listener
    -- de abajo volveria a entrar aqui si viera la concentracion todavia activa.
    current = nil
    if HarfordDnDConditions and HarfordDnDConditions.RemoveOwned then
        HarfordDnDConditions.RemoveOwned("concentrando")
        -- PUBLICAR el remove ANTES que nada: es la senal que dispara en cada cliente la
        -- caida de los estados de conjuro que este lanzador mantenia sobre ellos o sobre
        -- sus unidades registradas (OnConcentrationBroken en el receptor).
        if HarfordDnDConditions.PublishOwnedCondition then
            HarfordDnDConditions.PublishOwnedCondition("concentrando", "remove")
        end
        -- El estado del CONJURO mantenido cae CON la concentracion (peticion de mesa
        -- 2026-09-06): solo puedes concentrarte en uno, asi que se retira todo estado de
        -- conjuro marcado `concentration` que lleves puesto, y se publica la retirada para
        -- que el resto de clientes dejen de verlo.
        if HarfordDnDConditions.GetActive then
            for _, activo in ipairs(HarfordDnDConditions.GetActive("player")) do
                if activo.definition and activo.definition.concentration then
                    HarfordDnDConditions.RemoveOwned(activo.id)
                    if HarfordDnDConditions.PublishOwnedCondition then
                        HarfordDnDConditions.PublishOwnedCondition(activo.id, "remove")
                    end
                end
            end
        end
        -- Y el barrido LOCAL del lanzador: lo que EL puso con su fuente sobre NPCs u otras
        -- unidades registradas en su cliente cae tambien (los receptores jugadores hacen su
        -- propio barrido al recibir el remove de arriba).
        if HarfordDnDConditions.OnConcentrationBroken then
            HarfordDnDConditions.OnConcentrationBroken(
                UnitGUID and UnitGUID("player") or "",
                HarfordClassColors and HarfordClassColors.UnitFullName
                    and HarfordClassColors.UnitFullName("player") or "")
        end
    end
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
    -- Si el estado `concentrando` desaparecio sin pasar por Break (click derecho en la tira),
    -- soltar la concentracion: el estado ES la cara visible y no pueden divergir. Solo si
    -- consta que se llego a aplicar, para no romperla cuando el estado no pudo ponerse.
    if current and current.stateApplied and HarfordDnDConditions and HarfordDnDConditions.Has
        and not HarfordDnDConditions.Has("player", "concentrando") then
        API.Break()
    end
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
