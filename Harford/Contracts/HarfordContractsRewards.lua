------------------------------------------------------------
-- HarfordContractsRewards - Capa de recompensas compartidas (XP/rep) sobre los contratos.
--
-- Reutiliza HarfordQuests (ledger per-PJ + self-grant de rep + reconciliacion) para dar la
-- parte de XP/rep de raid a CADA jugador una sola vez cuando un contrato queda "completed".
-- El offline la recupera: al recibir el tablon por sync (Comm -> TC.Refresh), se reconcilia y
-- cobra lo que aun no tenia. item/oro NO va aqui (eso es reclamacion individual via rewardItems).
------------------------------------------------------------

HarfordContracts = HarfordContracts or {}

local TC = HarfordContracts

TC.Rewards = TC.Rewards or {}

-- ¿Existe la faccion (por id o nombre) en HarfordReputation? Para avisar al DM al guardar y para
-- no anunciar rep que no se concedera. Devuelve el factionId resuelto o nil.
function TC.Rewards.ResolveFaction(nameOrId)
    local R = HarfordReputation
    if not (R and R.GetFactions) then return nil end
    if R.GetFaction and R.GetFaction(nameOrId) then return tostring(nameOrId) end
    if not HarfordClassColors then return nil end
    local wanted = HarfordClassColors.StripAccents(tostring(nameOrId or "")):lower()
    for _, f in ipairs(R.GetFactions(true)) do
        if HarfordClassColors.StripAccents(tostring(f.name or "")):lower() == wanted then
            return f.id
        end
    end
    return nil
end

-- Recorre los contratos completados y concede la parte propia de XP/rep no cobrada. Idempotente
-- (HarfordQuests.ClaimRewards no repite: marca "claimed" en el ledger per-PJ). El id se prefija
-- para no chocar con otros ids en HarfordQuestsStore.claimed. Anuncia solo la primera concesion.
-- Clave del recibo per-PJ: el id PELADO del contrato. Es la MISMA que usan el listener de
-- completado de HarfordQuests y la ruta de mision de mundo, y esa unificacion es justamente el
-- arreglo: con dos claves distintas para el mismo contrato, ninguna bloqueaba a la otra.
function TC.Rewards.SharedKey(contract)
    return tostring(contract and contract.id or "")
end

-- Clave HEREDADA de cuando esta ruta iba prefijada. No se escribe nunca: solo se consulta, para
-- reconocer lo que ya se cobro entonces y no volver a concederlo ahora.
function TC.Rewards.LegacySharedKey(contract)
    return "contract:" .. tostring(contract and contract.id or "")
end

-- ¿Este contrato reparte algo compartido (XP o reputacion)? El oro y los objetos NO cuentan: son
-- individuales de quien entrega en el NPC.
-- Una entrada de reputacion solo reparte si trae faccion Y cantidad: es EXACTAMENTE lo que exige
-- el bucle de `HarfordQuests.ClaimRewards`, que se salta las demas. Cualquier prueba mas laxa
-- enciende un boton que no se puede completar nunca.
local function RepValida(rp)
    return type(rp) == "table"
        and (rp.faction or rp.factionId) ~= nil
        and (tonumber(rp.amount) or 0) ~= 0
end

-- Las reputaciones que de verdad se pueden conceder. Fuente UNICA: antes habia tres pruebas
-- distintas repartidas -- `HasShared`, `ClaimShared` y el bucle de concesion -- y divergian.
function TC.Rewards.SharedReps(contract)
    if type(contract) ~= "table" then return nil end
    local fuera = {}
    for _, rp in ipairs((type(contract.rewardReps) == "table" and contract.rewardReps) or {}) do
        if RepValida(rp) then fuera[#fuera + 1] = rp end
    end
    if RepValida(contract.rewardRep) then fuera[#fuera + 1] = contract.rewardRep end
    return (#fuera > 0) and fuera or nil
end

function TC.Rewards.HasShared(contract)
    if type(contract) ~= "table" then return false end
    -- Cero XP no es una recompensa: con `~= nil` bastaba con que el campo existiera.
    local xp = (tonumber(contract.rewardXP) or 0) > 0
    return xp or (TC.Rewards.SharedReps(contract) ~= nil)
end

-- ¿Ya lo cobro ESTE personaje? Se consultan las DOS claves: la actual y la heredada. Mirar solo
-- una es exactamente el fallo que se esta corrigiendo.
function TC.Rewards.IsSharedClaimed(contract)
    if not (HarfordQuests and HarfordQuests.IsSharedRewardsClaimed) then return false end
    if HarfordQuests.IsSharedRewardsClaimed(TC.Rewards.SharedKey(contract)) then return true end
    return HarfordQuests.IsSharedRewardsClaimed(TC.Rewards.LegacySharedKey(contract)) and true or false
end

-- Las misiones de mundo reparten su rep/xp por la ruta del world quest (turn-in del NPC + reparto
-- del DM a los ausentes, con la clave del id pelado). Cobrarlas tambien aqui la daria DOS veces.
function TC.Rewards.IsSharedClaimable(contract)
    if type(contract) ~= "table" then return false end
    if contract.status ~= "completed" or contract.worldNpc then return false end
    if not TC.Rewards.HasShared(contract) then return false end
    return not TC.Rewards.IsSharedClaimed(contract)
end

-- Concede la parte compartida de UN contrato. Idempotente: `HarfordQuests.ClaimRewards` lleva su
-- propio recibo por componente, asi que llamarla de mas no concede de mas.
function TC.Rewards.ClaimShared(contract)
    if not (HarfordQuests and HarfordQuests.ClaimRewards) then return false end
    if type(contract) ~= "table" or contract.status ~= "completed" or contract.worldNpc then return false end
    -- La MISMA prueba que `HasShared`: si divergen, el boton se enciende y esto lo rechaza, o al
    -- reves. Ya paso.
    if not TC.Rewards.HasShared(contract) then return false end
    -- Cortafuegos del recibo heredado: si se cobro con la clave antigua, no se concede otra vez.
    -- `ClaimRewards` no puede saberlo, porque su recibo va por la clave que se le pasa.
    if HarfordQuests.IsSharedRewardsClaimed
        and HarfordQuests.IsSharedRewardsClaimed(TC.Rewards.LegacySharedKey(contract)) then
        return false
    end
    return HarfordQuests.ClaimRewards({
        id = TC.Rewards.SharedKey(contract),
        -- La lista ya FILTRADA: se manda solo lo que `ClaimRewards` puede conceder, y asi el
        -- recibo cuadra con lo concedido. `rep` va dentro de `reps`, no aparte.
        reward = { xp = tonumber(contract.rewardXP), reps = TC.Rewards.SharedReps(contract) },
    }) and true or false
end

function TC.Rewards.Reconcile()
    if not (HarfordQuests and HarfordQuests.ClaimRewards) then return end
    local db = TC.GetDB and TC.GetDB()
    if type(db) ~= "table" or type(db.contracts) ~= "table" then return end

    for _, contract in ipairs(db.contracts) do
        -- Los contratos que son MISION DE MUNDO (worldNpc) reparten su rep/xp por la ruta del world
        -- quest (turn-in del NPC + DM reparto a ausentes, clave de claim = id pelado). Reconciliarlos
        -- aqui (clave "contract:<id>") concederia la rep DOS veces. Se saltan.
        if type(contract) == "table" and contract.status == "completed" and not contract.worldNpc then
            -- (a) Recompensa compartida (XP/rep) no cobrada por este PJ. Misma funcion que el
            -- boton de la pestaña Completadas: una sola via, un solo recibo.
            TC.Rewards.ClaimShared(contract)

            -- (b) Si lo seguias en tu quest log, sacalo: la mision esta entregada (como el juego).
            if HarfordQuests.IsAccepted and HarfordQuests.Abandon
                and HarfordQuests.IsAccepted(contract.id) then
                HarfordQuests.Abandon(contract.id)
            end
        end
    end
end
