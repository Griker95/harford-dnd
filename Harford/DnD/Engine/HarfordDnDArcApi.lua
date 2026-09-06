-- API de tiradas para uso externo (ArcSpell/macro), extraida de HarfordDnD.lua (fase C).
-- Solo usa modulos globales; carga despues de HarfordDnDWeaponRolls y no necesita Init.
local WeaponRolls = HarfordDnDWeaponRolls
_G.DND5E_ARC_API = _G.DND5E_ARC_API or {}

-- API de tiradas para uso externo (ArcSpell/macro): dispara la MISMA tirada que el boton, con los
-- bonos correctos del PJ activo, y la publica igual (chat + red). Reusa el DoRoll local. En do...end
-- para no anadir locales de file-scope.
do
    local function FindAbility(k)
        k = tostring(k or ""):lower()
        for _, a in ipairs(HarfordDnDData.ABIL) do
            if a.key:lower() == k or a.short:lower() == k then return a end
        end
    end
    local function FindSkill(k)
        k = tostring(k or ""):lower()
        for _, s in ipairs(HarfordDnDData.SKILLS) do
            if tostring(s.id):lower() == k or tostring(s.name):lower() == k then return s end
        end
    end

    local function SetLastRoll(result)
        if type(result) == "table" then
            result.timestamp = result.timestamp or (time and time() or 0)
            _G.DND5E_ARC_API._lastRoll = result
        end
        return result
    end

    local function NormalizeCompareOp(op)
        op = tostring(op or ">=")
        if op == "=" then op = "==" end
        return op
    end

    local function CompareNumber(left, op, right)
        left = tonumber(left)
        right = tonumber(right)
        if not left or not right then return false end
        op = NormalizeCompareOp(op)
        if op == ">=" then return left >= right end
        if op == ">" then return left > right end
        if op == "<=" then return left <= right end
        if op == "<" then return left < right end
        if op == "==" then return left == right end
        if op == "~=" or op == "!=" then return left ~= right end
        return false
    end

    -- Prueba de caracteristica. abilityKey: nombre ("Fuerza") o abreviatura ("FUE").
    -- Devuelven el TOTAL de la tirada (y el critico "CRITICO"/"FALLO"/nil) para comparar en ArcSpell.
    _G.DND5E_ARC_API.RollAbilityEx = function(abilityKey)
        local a = FindAbility(abilityKey)
        if not a then return nil end
        local result = WeaponRolls.DoRollEx(a.short, HarfordDnDCalc.GetAbilityMod(a.key), 0, "ability", { actorUnit = "player", ability = a.key })
        result.kind = "ability"
        return SetLastRoll(result)
    end
    _G.DND5E_ARC_API.RollAbility = function(abilityKey)
        local result = _G.DND5E_ARC_API.RollAbilityEx(abilityKey)
        if not result then return nil end
        return result.total, result.crit
    end

    -- Tirada de salvacion.
    _G.DND5E_ARC_API.RollSaveEx = function(abilityKey)
        local a = FindAbility(abilityKey)
        if not a then return nil end
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses(a.key)
        local result = WeaponRolls.DoRollEx("Salv " .. a.short, base, prof, "save", { actorUnit = "player", ability = a.key })
        result.kind = "save"
        return SetLastRoll(result)
    end
    _G.DND5E_ARC_API.RollSave = function(abilityKey)
        local result = _G.DND5E_ARC_API.RollSaveEx(abilityKey)
        if not result then return nil end
        return result.total, result.crit
    end

    -- Prueba de habilidad (con su competencia). skillNameOrId: "Sigilo" o su id.
    -- `etiqueta` deja que quien tira ponga su propio nombre delante ("Esconderse: Sigilo"). Sirve
    -- para que una accion no ocupe dos lineas de chat: el anuncio y la tirada son la misma cosa.
    _G.DND5E_ARC_API.RollSkillEx = function(skillNameOrId, etiqueta, opts)
        local s = FindSkill(skillNameOrId)
        if not s then return nil end
        local base, prof = HarfordDnDCalc.GetSkillRollBonuses(s)
        local nombre = (etiqueta and etiqueta ~= "") and (etiqueta .. ": " .. s.name) or s.name
        local result = WeaponRolls.DoRollEx(nombre, base, prof, "ability", {
            actorUnit = "player", ability = s.ability, skill = s.id,
            silent = type(opts) == "table" and opts.silent == true,
            targetUnit = type(opts) == "table" and opts.targetUnit or nil,
        })
        result.kind = "skill"
        return SetLastRoll(result)
    end
    _G.DND5E_ARC_API.RollSkill = function(skillNameOrId)
        local result = _G.DND5E_ARC_API.RollSkillEx(skillNameOrId)
        if not result then return nil end
        return result.total, result.crit
    end

    -- Iniciativa.
    _G.DND5E_ARC_API.RollInitiativeEx = function()
        local result = WeaponRolls.DoRollEx("Iniciativa", HarfordDnDCalc.GetAbilityMod("Destreza"), HarfordDnDGetInitiativeMod(), "ability",
            { actorUnit = "player", ability = "Destreza" })
        result.kind = "initiative"
        return SetLastRoll(result)
    end
    _G.DND5E_ARC_API.RollInitiative = function()
        local result = _G.DND5E_ARC_API.RollInitiativeEx()
        if not result then return nil end
        return result.total, result.crit
    end

    -- Tirada libre tipo "2d6+3" / "1d20-1". label opcional para la etiqueta en chat.
    _G.DND5E_ARC_API.RollExpressionEx = function(expr, label)
        expr = tostring(expr or ""):gsub("%s+", "")
        if expr == "" then return { ok = false, error = "expresion vacia", kind = "expression", label = tostring(label or "") } end
        local total, detail = 0, {}
        for sign, n, sides in expr:gmatch("([%+%-]?)(%d*)[dD](%d+)") do
            local count = tonumber(n) or 1
            sides = tonumber(sides)
            local mult = (sign == "-") and -1 or 1
            local rolls = {}
            for _ = 1, count do
                local v = HarfordDnDCalc.RollDie(sides)
                total = total + mult * v
                rolls[#rolls + 1] = v
            end
            detail[#detail + 1] = (sign == "-" and "-" or "") .. count .. "d" .. sides
                .. "(" .. table.concat(rolls, "+") .. ")"
        end
        local flats = expr:gsub("([%+%-]?)(%d*)[dD](%d+)", "")
        for sign, num in flats:gmatch("([%+%-]?)(%d+)") do
            local v = tonumber(num) or 0
            if sign == "-" then total = total - v else total = total + v end
            detail[#detail + 1] = (sign == "-" and "-" or "+") .. v
        end
        local diceText = table.concat(detail, " ")
        HarfordDnDRolls.Broadcast({ type = "roll", label = tostring(label or expr), total = total,
            dice = diceText, modifiers = "" })
        return SetLastRoll({
            ok = true,
            kind = "expression",
            label = tostring(label or expr),
            total = total,
            dice = diceText,
            modifiers = "",
            crit = nil,
            critical = nil,
            timestamp = time and time() or 0,
        })
    end
    _G.DND5E_ARC_API.RollExpression = function(expr, label)
        local result = _G.DND5E_ARC_API.RollExpressionEx(expr, label)
        if not result or result.ok == false then return false end
        return result.total
    end

    _G.DND5E_ARC_API.GetLastRoll = function()
        return _G.DND5E_ARC_API._lastRoll
    end

    _G.DND5E_ARC_API.ClearLastRoll = function()
        _G.DND5E_ARC_API._lastRoll = nil
        return true
    end

    _G.DND5E_ARC_API.LastTotal = function()
        local result = _G.DND5E_ARC_API._lastRoll
        return result and result.total or nil
    end

    _G.DND5E_ARC_API.LastCrit = function()
        local result = _G.DND5E_ARC_API._lastRoll
        return result and result.crit or nil
    end

    _G.DND5E_ARC_API.LastIsCritical = function()
        local crit = _G.DND5E_ARC_API.LastCrit()
        return crit == "CRÍTICO" or crit == "CRITICO" or crit == "crit" or crit == "critical"
    end

    _G.DND5E_ARC_API.LastIsFumble = function()
        local crit = _G.DND5E_ARC_API.LastCrit()
        return crit == "PIFIA" or crit == "FALLO" or crit == "fumble"
    end

    _G.DND5E_ARC_API.LastMeets = function(dc)
        return CompareNumber(_G.DND5E_ARC_API.LastTotal(), ">=", dc)
    end

    _G.DND5E_ARC_API.LastFails = function(dc)
        return CompareNumber(_G.DND5E_ARC_API.LastTotal(), "<", dc)
    end

    _G.DND5E_ARC_API.CheckLastRoll = function(op, value)
        return CompareNumber(_G.DND5E_ARC_API.LastTotal(), op, value)
    end

    _G.DND5E_ARC_API.LastIsKind = function(kind)
        local result = _G.DND5E_ARC_API._lastRoll
        return result and tostring(result.kind or ""):lower() == tostring(kind or ""):lower() or false
    end
end
