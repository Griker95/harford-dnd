-- HarfordDnDProfile: aplicacion de tablas de perfil/recursos sobre HarfordDnDStore.
--
-- Empaqueta las claves de recurso (HarfordDnDResources) y los callbacks de la
-- ficha (EnsureDefaults / RefreshMainUI) que HarfordDnD.lua registra una vez con
-- SetHooks. Los wrappers triviales (EnsurePersist/LoadPersistToRuntime/
-- SaveCurrentProfileToBank) NO viven aqui: se llaman directos sobre HarfordDnDStore.

HarfordDnDProfile = HarfordDnDProfile or {}

local _ensureDefaults = function() end
local _refresh = function() end

-- HarfordDnD.lua registra sus callbacks tras definir EnsureDefaults/RefreshMainUI.
function HarfordDnDProfile.SetHooks(ensureDefaultsFn, refreshFn)
    _ensureDefaults = type(ensureDefaultsFn) == "function" and ensureDefaultsFn or _ensureDefaults
    _refresh        = type(refreshFn) == "function" and refreshFn or _refresh
end

-- Reemplaza el perfil completo (atributos + recursos) y refresca.
function HarfordDnDProfile.Apply(tbl, profileName)
    return HarfordDnDStore.ApplyProfileTable(
        tbl,
        profileName,
        HarfordDnDResources.ALL_KEYS,
        HarfordDnDResources.CurKey,
        HarfordDnDResources.MaxKey,
        _ensureDefaults,
        _refresh
    )
end

-- Aplica solo la configuracion de recursos (max/orden) sin tocar el resto.
function HarfordDnDProfile.ApplyResourceConfig(tbl, profileName)
    return HarfordDnDStore.ApplyResourceConfigTable(
        tbl,
        profileName,
        HarfordDnDResources.ALL_KEYS,
        HarfordDnDResources.CurKey,
        HarfordDnDResources.MaxKey,
        _ensureDefaults,
        _refresh
    )
end

-- Fusiona los flags Hab_X_Prof/Exp recibidos via DNDPROF en el perfil existente.
-- No reemplaza el perfil completo para no perder los atributos ya aplicados.
function HarfordDnDProfile.MergeProfFlags(tbl, profileName)
    return HarfordDnDStore.MergeProfileKeys(tbl, profileName, _ensureDefaults, _refresh)
end
