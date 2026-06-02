-- HarfordDnDWeapons: tabla WEAPONS + helpers de arma sin estado de UI.
--
-- Los helpers que dependen del flag "Versátil" leen su valor via
-- HarfordDnDContext.Get (no necesitan el chunk de HarfordDnD.lua). Los helpers
-- que necesitan modificadores de caracteristica (GetWeaponAttackAbility) se
-- quedan en HarfordDnD.lua hasta que HarfordDnDCalc exponga GetAbilityMod.

HarfordDnDWeapons = HarfordDnDWeapons or {}

local GREEN  = "|cff00ff00"
local GREY   = "|cff999999"
local ENDCLR = "|r"

HarfordDnDWeapons.WEAPONS = {
    { key="Desarmado", cat="Especial", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={} },
    { key="Arco corto", cat="Simple", mode="Ranged", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Munición (80/320)","Dos manos"} },
    { key="Ballesta ligera", cat="Simple", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (80/320)","Recarga","Dos manos"} },
    { key="Bastón", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="contundente", addAbi=true, props={"Versátil (1d8)"} },
    { key="Clava", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Ligera"} },
    { key="Daga", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Ligera","Sutil","Arrojadiza (20/60)"} },
    { key="Dardo", cat="Simple", mode="Ranged", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Sutil","Arrojadiza (20/60)"} },
    { key="Gran clava", cat="Simple", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Dos manos"} },
    { key="Hacha de mano", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Ligera","Arrojadiza (20/60)"} },
    { key="Honda", cat="Simple", mode="Ranged", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Munición (30/120)"} },
    { key="Hoz", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Ligera"} },
    { key="Jabalina", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Arrojadiza (30/120)"} },
    { key="Lanza", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Versátil (1d8)","Arrojadiza (20/60)"} },
    { key="Martillo ligero", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Ligera","Arrojadiza (20/60)"} },
    { key="Maza", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="contundente", addAbi=true, props={} },
    { key="Alabarda", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Arco largo", cat="Marcial", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (150/600)","Pesada","Dos manos"} },
    { key="Ballesta de mano", cat="Marcial", mode="Ranged", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Munición (30/120)","Ligera","Recarga"} },
    { key="Ballesta pesada", cat="Marcial", mode="Ranged", dmgN=1, dmgS=10, dmgType="perforante", addAbi=true, props={"Munición (100/400)","Pesada","Recarga","Dos manos"} },
    { key="Cerbatana", cat="Marcial", mode="Ranged", dmgN=1, dmgS=1, dmgType="perforante", addAbi=false, props={"Munición (25/100)","Recarga"} },
    { key="Cimitarra", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Espada corta", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Espada larga", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Versátil (1d10)"} },
    { key="Espadón", cat="Marcial", mode="Melee", dmgN=2, dmgS=6, dmgType="cortante", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Estoque", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Sutil"} },
    { key="Flagelo", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={} },
    { key="Gran hacha", cat="Marcial", mode="Melee", dmgN=1, dmgS=12, dmgType="cortante", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Guja", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Hacha de batalla", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Versátil (1d10)"} },
    { key="Lanza de caballería", cat="Marcial", mode="Melee", dmgN=1, dmgS=12, dmgType="perforante", addAbi=true, props={"Alcance","Especial"} },
    { key="Látigo", cat="Marcial", mode="Melee", dmgN=1, dmgS=4, dmgType="cortante", addAbi=true, props={"Sutil","Alcance"} },
    { key="Lucero del alba", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={} },
    { key="Martillo de guerra", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Versátil (1d10)"} },
    { key="Mazo de guerra", cat="Marcial", mode="Melee", dmgN=2, dmgS=6, dmgType="contundente", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Pica", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="perforante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Pico de guerra", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={} },
    { key="Red", cat="Marcial", mode="Ranged", dmgN=0, dmgS=0, dmgType="", addAbi=false, props={"Especial","Arrojadiza (5/15)"} },
    { key="Tridente", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Versátil (1d8)","Arrojadiza (20/60)"} },
    { key="Pistola", cat="De fuego", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (30/120)", "Retumbante", "Recarga", "Ligera"} },
    { key="Rifle", cat="De fuego", mode="Ranged", dmgN=1, dmgS=12, dmgType="perforante", addAbi=true, props={"Munición (60/240)", "Retumbante", "Recarga", "Pesada", "Dos manos"} },
    { key="Escopeta", cat="De fuego", mode="Ranged", dmgN=2, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (15/60)", "Retumbante", "Recarga", "Dos manos"} },
    { key="Martillo arrojadizo enano", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Arrojadiza (20/60)"} },
    { key="Espada quel'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Sutil","Versátil (1d10)"} },
    { key="Espada lunar kal'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Sutil","Versátil (1d10)"} },
    { key="Guja lunar kal'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera","Arrojadiza (60/120)"} },
    { key="Doble hoja sin'dorei", cat="Racial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Sutil","Dos manos"} },
    { key="Alabarda tauren", cat="Racial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Pesada","Alcance","Dos manos"} },
    { key="Totem de guerra tauren", cat="Racial", mode="Melee", dmgN=2, dmgS=8, dmgType="contundente", addAbi=true, props={"Pesada","Dos manos"} },
    { key="Garra de guerra orca", cat="Racial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Guja de guerra", cat="Especial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Arrojadiza (20/60)","Versátil (1d10)"} },
    { key="Aquajet", cat="Especial", mode="Ranged", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Municion (20/60)","Recarga", "Especial"} },
    { key="Escudo", cat="Otros", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, emoteId=2059, critEmoteId=2992, props={} },
}

-- Estado del flag "Versátil" leido del contexto de ficha (ARC).
local function VersatileActive()
    return (tonumber(HarfordDnDContext.Get("Versatil", "0")) or 0) == 1
end

function HarfordDnDWeapons.ParseDice(diceStr)
    if not diceStr then return nil, nil end
    local n, s = diceStr:match("^(%d+)d(%d+)$")
    n, s = tonumber(n), tonumber(s)
    return n, s
end

function HarfordDnDWeapons.GetVersatileDice(def)
    if not def or not def.props then return nil end
    for _, p in ipairs(def.props) do
        local d = p:match("Versátil %((%d+d%d+)%)")
        if d then return d end
    end
    return nil
end

-- Familia de animacion de ataque (presets de HarfordActionSequence) segun el arma.
-- Devuelve: "unarmed" | "one_hand" | "two_hand" | "polearm" | "shield", o nil para
-- armas a distancia/conjuro (sin preset cuerpo a cuerpo: mantienen el emote actual).
-- Las arrojadizas cuerpo a cuerpo (mode "Melee") animan como su familia melee.
function HarfordDnDWeapons.GetAnimFamily(def, versatileActive)
    if not def then return nil end
    if def.key == "Escudo" then return "shield" end
    if def.key == "Desarmado" then return "unarmed" end
    if def.mode == "Ranged" then return nil end

    local function hasProp(name)
        for _, p in ipairs(def.props or {}) do
            if p == name or p:find(name, 1, true) then return true end
        end
        return false
    end

    if hasProp("Alcance") and hasProp("Dos manos") then return "polearm" end
    local vDice = HarfordDnDWeapons.GetVersatileDice(def)
    if (vDice and versatileActive) or hasProp("Dos manos") then return "two_hand" end
    return "one_hand"
end

function HarfordDnDWeapons.WeaponBaseDice(def)
    if not def or not def.dmgN or not def.dmgS or def.dmgN == 0 or def.dmgS == 0 then return "-" end
    local use = tostring(def.dmgN) .. "d" .. tostring(def.dmgS)
    local v = HarfordDnDWeapons.GetVersatileDice(def)
    if v and VersatileActive() then use = v end
    return use
end

function HarfordDnDWeapons.WeaponPropsLabel(def)
    if not def or not def.props or #def.props == 0 then return "" end
    local out = {}
    local v = HarfordDnDWeapons.GetVersatileDice(def)
    local vOn = v and VersatileActive()
    for _, p in ipairs(def.props) do
        if v and p:find("Versátil") then
            if vOn then
                out[#out+1] = GREEN .. p .. ENDCLR
            else
                out[#out+1] = GREY .. p .. ENDCLR
            end
        else
            out[#out+1] = p
        end
    end
    return table.concat(out, ", ")
end

function HarfordDnDWeapons.GetWeaponMenuGroups()
    local groupOrder = {
        "Simple",
        "Marcial",
        "De fuego",
        "Racial",
        "Otros",
    }

    local groupLabels = {
        ["Simple"] = "Armas simples",
        ["Marcial"] = "Armas marciales",
        ["De fuego"] = "Armas de fuego",
        ["Racial"] = "Armas raciales",
        ["Otros"] = "Otros",
    }

    local groupsByKey = {}
    local groups = {}

    for _, key in ipairs(groupOrder) do
        local group = {
            key = key,
            text = groupLabels[key] or key,
            items = {},
        }
        groupsByKey[key] = group
        table.insert(groups, group)
    end

    for _, w in ipairs(HarfordDnDWeapons.WEAPONS) do
        local cat = w.cat or "Otros"
        local group = groupsByKey[cat] or groupsByKey["Otros"]
        table.insert(group.items, w)
    end

    for _, group in ipairs(groups) do
        table.sort(group.items, function(a, b)
            return tostring(a.key) < tostring(b.key)
        end)
    end

    return groups
end
