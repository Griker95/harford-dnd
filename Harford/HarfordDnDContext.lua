-- HarfordDnDContext: estado de contexto de ficha + accesores de valores ARC.
--
-- Es la "bisagra" que desacopla el resto de modulos de HarfordDnD.lua: cualquier
-- helper puro (calculo, recursos) puede leer/escribir valores de la ficha sin
-- estar dentro del chunk principal, llamando a HarfordDnDContext.Get/Set.
--
-- HarfordDnD.lua mantiene aliases locales (`local SheetContext = HarfordDnDContext.State`,
-- `local ARCGET = HarfordDnDContext.Get`, `local ARCSET = HarfordDnDContext.Set`)
-- para no tocar sus call-sites existentes.

HarfordDnDContext = HarfordDnDContext or {}

-- Contexto temporal de ficha provisto por una extension (por ejemplo HarfordAdmin).
-- El core solo lo representa y usa al tirar; no decide permisos ni carga targets NPC.
-- Es una tabla unica y estable: HarfordDnD.lua referencia esta misma tabla.
HarfordDnDContext.State = HarfordDnDContext.State or {
    active = false,
    overrides = nil,
    rollName = nil,
    rollColor = nil,
    actions = nil,
    showActionPanel = false,
    spellProficiencyBonus = nil,
    kind = nil,
    lockedSource = false,
    canAttack = nil,
    canDamage = nil,
    onAttackAnimation = nil,
    onDamageRolled = nil,
}

-- Hook opcional para resincronizar la referencia al runtime profile que vive
-- como local en HarfordDnD.lua. Se registra en load con SetSyncHook.
local _syncHook = nil

function HarfordDnDContext.SetSyncHook(fn)
    _syncHook = type(fn) == "function" and fn or nil
end

-- Lee un valor de la ficha. Prioriza los overrides del contexto (modo NPC) y
-- cae al store persistente/runtime.
function HarfordDnDContext.Get(k, default)
    local State = HarfordDnDContext.State
    if State.overrides and State.overrides[k] ~= nil then
        return State.overrides[k]
    end
    local value = HarfordDnDStore.GetValue(k, default)
    if _syncHook then _syncHook() end
    return value
end

-- Escribe un valor de la ficha. Durante la hidratacion desde persistencia
-- escribe directo al runtime para no disparar broadcasts intermedios.
function HarfordDnDContext.Set(k, v)
    if _G.HarfordDnDHydratingFromPersist then
        HarfordDnDStore.state.runtime[k] = tostring(v)
    else
        HarfordDnDStore.SetValue(k, tostring(v))
    end
    if _syncHook then _syncHook() end
end
