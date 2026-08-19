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
function TC.Rewards.Reconcile()
    if not (HarfordQuests and HarfordQuests.ClaimRewards) then return end
    local db = TC.GetDB and TC.GetDB()
    if type(db) ~= "table" or type(db.contracts) ~= "table" then return end

    for _, contract in ipairs(db.contracts) do
        -- Los contratos que son MISION DE MUNDO (worldNpc) reparten su rep/xp por la ruta del world
        -- quest (turn-in del NPC + DM reparto a ausentes, clave de claim = id pelado). Reconciliarlos
        -- aqui (clave "contract:<id>") concederia la rep DOS veces. Se saltan.
        if type(contract) == "table" and contract.status == "completed" and not contract.worldNpc then
            -- (a) Recompensa compartida (XP/rep) no cobrada por este PJ. Soporta VARIAS reputaciones
            -- (`rewardReps`, lista) ademas de la unica legacy (`rewardRep`). Sin la lista, un contrato
            -- con multiples reps no concedia ninguna al reconciliar (solo miraba `rewardRep`).
            local reps = (type(contract.rewardReps) == "table" and #contract.rewardReps > 0 and contract.rewardReps) or nil
            local rep = type(contract.rewardRep) == "table" and contract.rewardRep or nil
            if tonumber(contract.rewardXP) or reps or rep then
                local granted = HarfordQuests.ClaimRewards({
                    id = "contract:" .. tostring(contract.id),
                    reward = { xp = tonumber(contract.rewardXP), rep = rep, reps = reps },
                })
                -- El aviso de rep lo emite ya HarfordQuests.ClaimRewards (una vez, incluida la
                -- recuperacion offline); no duplicar aqui. `granted` se conserva por si hace falta.
                local _ = granted
            end

            -- (b) Si lo seguias en tu quest log, sacalo: la mision esta entregada (como el juego).
            if HarfordQuests.IsAccepted and HarfordQuests.Abandon
                and HarfordQuests.IsAccepted(contract.id) then
                HarfordQuests.Abandon(contract.id)
            end
        end
    end
end
