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
    -- El golpe sin armas no tira dado: son 1 + Mod. Fuerza de dano contundente (PHB).
    -- Se escribe 1d1 igual que la cerbatana para que pase por el flujo normal de dados,
    -- y ademas deja que Artes Marciales suba el dado desde nivel 1 (1d4 > 1d1).
    { key="Desarmado", icon="inv_gauntlets_04", cat="Especial", mode="Melee", dmgN=1, dmgS=1, dmgType="contundente", addAbi=true, props={} },
    { key="Arco corto", icon="inv_weapon_bow_05", cat="Simple", mode="Ranged", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Munición (80/320)","Dos manos"} },
    { key="Ballesta ligera", icon="inv_weapon_crossbow_02", cat="Simple", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (80/320)","Recarga","Dos manos"} },
    { key="Bastón", icon="inv_staff_08", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="contundente", addAbi=true, props={"Versátil (1d8)"} },
    { key="Clava", icon="inv_mace_11", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Ligera"} },
    { key="Daga", icon="inv_weapon_shortblade_05", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Ligera","Sutil","Arrojadiza (20/60)"} },
    { key="Dardo", icon="inv_throwingknife_05", cat="Simple", mode="Ranged", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Sutil","Arrojadiza (20/60)"} },
    { key="Gran clava", icon="inv_mace_10", cat="Simple", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Dos manos"} },
    { key="Hacha de mano", icon="inv_axe_14", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Ligera","Arrojadiza (20/60)"} },
    { key="Honda", icon="ability_hunter_beastcall02", cat="Simple", mode="Ranged", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Munición (30/120)"} },
    { key="Hoz", icon="inv_misc_1h_farmsickle_a_01", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Ligera"} },
    { key="Jabalina", icon="inv_weapon_halberd_ahnqiraj", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Arrojadiza (30/120)"} },
    { key="Lanza", icon="inv_polearm_2h_draenorcrafted_d_01_a", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Versátil (1d8)","Arrojadiza (20/60)"} },
    { key="Martillo ligero", icon="inv_hammer_17", cat="Simple", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, props={"Ligera","Arrojadiza (20/60)"} },
    { key="Maza", icon="inv_mace_01", cat="Simple", mode="Melee", dmgN=1, dmgS=6, dmgType="contundente", addAbi=true, props={} },
    { key="Alabarda", icon="inv_weapon_halberd_02", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Arco largo", icon="inv_weapon_bow_02", cat="Marcial", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (150/600)","Pesada","Dos manos"} },
    { key="Ballesta de mano", icon="inv_weapon_crossbow_03", cat="Marcial", mode="Ranged", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Munición (30/120)","Ligera","Recarga"} },
    { key="Ballesta pesada", icon="inv_weapon_crossbow_04", cat="Marcial", mode="Ranged", dmgN=1, dmgS=10, dmgType="perforante", addAbi=true, props={"Munición (100/400)","Pesada","Recarga","Dos manos"} },
    { key="Cerbatana", icon="inv_blowdart_zandalari", cat="Marcial", mode="Ranged", dmgN=1, dmgS=1, dmgType="perforante", addAbi=false, props={"Munición (25/100)","Recarga"} },
    { key="Cimitarra", icon="inv_sword_24", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Espada corta", icon="inv_sword_04", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Espada larga", icon="inv_sword_20", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Versátil (1d10)"} },
    { key="Espadón", icon="inv_sword_23", cat="Marcial", mode="Melee", dmgN=2, dmgS=6, dmgType="cortante", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Estoque", icon="inv_sword_30", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Sutil"} },
    { key="Flagelo", icon="eps_lol_sejuani_flailofthenorthernwinds2", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={} },
    { key="Gran hacha", icon="inv_axe_09", cat="Marcial", mode="Melee", dmgN=1, dmgS=12, dmgType="cortante", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Guja", icon="inv_weapon_halberd_04", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Hacha de batalla", icon="inv_axe_18", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Versátil (1d10)"} },
    { key="Lanza de caballería", icon="inv_spear_05", cat="Marcial", mode="Melee", dmgN=1, dmgS=12, dmgType="perforante", addAbi=true, props={"Alcance","Especial"} },
    { key="Látigo", icon="inv_misc_crop_01", cat="Marcial", mode="Melee", dmgN=1, dmgS=4, dmgType="cortante", addAbi=true, props={"Sutil","Alcance"} },
    { key="Lucero del alba", icon="inv_mace_05", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={} },
    { key="Martillo de guerra", icon="inv_hammer_07", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Versátil (1d10)"} },
    { key="Mazo de guerra", icon="inv_hammer_11", cat="Marcial", mode="Melee", dmgN=2, dmgS=6, dmgType="contundente", addAbi=true, props={"Dos manos","Pesada"} },
    { key="Pica", icon="inv_spear_06", cat="Marcial", mode="Melee", dmgN=1, dmgS=10, dmgType="perforante", addAbi=true, props={"Alcance","Dos manos","Pesada"} },
    { key="Pico de guerra", icon="inv_hammer_19", cat="Marcial", mode="Melee", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={} },
    { key="Red", icon="inv_misc_net_01", cat="Marcial", mode="Ranged", dmgN=0, dmgS=0, dmgType="", addAbi=false, props={"Especial","Arrojadiza (5/15)"} },
    { key="Tridente", icon="inv_spear_07", cat="Marcial", mode="Melee", dmgN=1, dmgS=6, dmgType="perforante", addAbi=true, props={"Versátil (1d8)","Arrojadiza (20/60)"} },
    { key="Pistola", icon="eps_plunder_piratepistol_03", cat="De fuego", mode="Ranged", dmgN=1, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (30/120)", "Retumbante", "Recarga", "Ligera"} },
    { key="Rifle", icon="inv_weapon_rifle_04", cat="De fuego", mode="Ranged", dmgN=1, dmgS=12, dmgType="perforante", addAbi=true, props={"Munición (60/240)", "Retumbante", "Recarga", "Pesada", "Dos manos"} },
    { key="Escopeta", icon="inv_weapon_rifle_08", cat="De fuego", mode="Ranged", dmgN=2, dmgS=8, dmgType="perforante", addAbi=true, props={"Munición (15/60)", "Retumbante", "Recarga", "Dos manos"} },
    { key="Martillo arrojadizo enano", icon="inv_hammer_21", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="contundente", addAbi=true, props={"Arrojadiza (20/60)"} },
    { key="Espada quel'dorei", icon="inv_sword_bloodelf_03", cat="Racial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Sutil","Versátil (1d10)"} },
    { key="Espada lunar kal'dorei", icon="inv_sword_2h_warfrontsnightelf_d_01", cat="Racial", mode="Melee", dmgN=2, dmgS=4, dmgType="cortante", addAbi=true, props={"Sutil","Versátil (1d10)"} },
    { key="Guja lunar kal'dorei", icon="inv_glaive_1h_tyrande_d_01", cat="Racial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera","Arrojadiza (60/120)"} },
    { key="Doble hoja sin'dorei", icon="inv_sword_28", cat="Racial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Sutil","Dos manos"} },
    { key="Alabarda tauren", icon="inv_weapon_halberd_09", cat="Racial", mode="Melee", dmgN=1, dmgS=10, dmgType="cortante", addAbi=true, props={"Pesada","Alcance","Dos manos"} },
    { key="Totem de guerra tauren", icon="inv_relics_totemofrebirth", cat="Racial", mode="Melee", dmgN=2, dmgS=8, dmgType="contundente", addAbi=true, props={"Pesada","Dos manos"} },
    { key="Garra de guerra orca", icon="inv_hand_1h_bwdraid_d_01", cat="Racial", mode="Melee", dmgN=1, dmgS=6, dmgType="cortante", addAbi=true, props={"Sutil","Ligera"} },
    { key="Guja de guerra", icon="inv_glaive_1h_newplayer_a_01", cat="Especial", mode="Melee", dmgN=1, dmgS=8, dmgType="cortante", addAbi=true, props={"Especial","Arrojadiza (20/60)","Versátil (1d10)"} },
    { key="Aquajet", icon="inv_weapon_rifle_33", cat="Especial", mode="Ranged", dmgN=1, dmgS=4, dmgType="perforante", addAbi=true, props={"Munición (20/60)","Recarga", "Especial"} },
    { key="Escudo", icon="inv_shield_04", cat="Otros", mode="Melee", dmgN=1, dmgS=4, dmgType="contundente", addAbi=true, emoteId=2059, critEmoteId=2992, props={} },
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

-- Alcance utilizable del ataque. Los datos base guardan las armas del manual en
-- pies dentro de `Municion (normal/largo)` o `Arrojadiza (normal/largo)`.
-- `attackMode="thrown"` queda listo para la futura eleccion explicita de arrojar;
-- nunca se selecciona solo por tener al objetivo lejos.
function HarfordDnDWeapons.GetAttackRange(def, attackMode)
    if not def then return nil end
    local feetToMeters = 0.3048
    local function hasProp(fragment)
        for _, prop in ipairs(def.props or {}) do
            if tostring(prop):find(fragment, 1, true) then return prop end
        end
        return nil
    end
    local function parseRange(prop)
        if not prop then return nil end
        local normal, long = tostring(prop):match("%((%d+)%s*/%s*(%d+)%)")
        normal, long = tonumber(normal), tonumber(long)
        if not normal then return nil end
        return { normalMeters = normal * feetToMeters, longMeters = (long or normal) * feetToMeters,
            normalFeet = normal, longFeet = long or normal }
    end

    if attackMode == "thrown" then
        local range = parseRange(hasProp("Arrojadiza"))
        if range then range.kind = "thrown"; return range end
        -- Sin la propiedad Arrojadiza, lanzarla es un ataque IMPROVISADO (regla 5e): alcance
        -- 20/60 pies. El 1d4 y la perdida de competencia los pone la accion de Lanzar arma.
        return { kind = "thrown", improvised = true,
            normalMeters = 20 * feetToMeters, longMeters = 60 * feetToMeters,
            normalFeet = 20, longFeet = 60 }
    end
    if tostring(def.mode) == "Ranged" then
        local range = parseRange(hasProp("Munición")) or parseRange(hasProp("Arrojadiza"))
        if range then range.kind = "ranged"; return range end
        local feet = tonumber(def.rangeFeet)
        if feet and feet > 0 then
            return { kind = "ranged", normalMeters = feet * feetToMeters, longMeters = feet * feetToMeters,
                normalFeet = feet, longFeet = feet }
        end
    end
    local feet = tonumber(def.rangeFeet)
    if feet and feet > 0 then
        return { kind = "melee", normalMeters = feet * feetToMeters, longMeters = feet * feetToMeters,
            normalFeet = feet, longFeet = feet }
    end
    if not hasProp("Alcance") then
        -- En Epsilon el hitbox ya expresa el contacto real entre ambos modelos.
        -- Un arma melé corriente no alcanza a distancia: debe devolver exactamente 0.
        return { kind = "melee", normalMeters = 0, longMeters = 0, requiresContact = true }
    end
    return {
        kind = "melee",
        -- `Alcance` es la excepcion declarada: permite golpear sin contacto.
        normalMeters = 10 * feetToMeters,
        longMeters = 10 * feetToMeters,
    }
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

-- Ruta de textura del icono del arma. Los nombres vienen de la web (fuente canonica) via
-- `tools/codice/importar_iconos_armas.py`, y son nombres sueltos de Interface/Icons.
local ICONO_DESCONOCIDO = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Icono del arma, resuelto. Puede devolver una RUTA o un fileID: `SetTexture` acepta ambos.
--
-- Los nombres del catalogo vienen de la web y son nombres de Wowhead, que NO siempre existen
-- como fichero suelto en Epsilon; una ruta que no resuelve se pinta en verde sin avisar. Por
-- eso pasa primero por el resolutor del compendio, que los busca en LibRPMedia -mapea nombre
-- a fileID y cachea- y solo despues se intenta la ruta directa, comprobada.
function HarfordDnDWeapons.GetIconPath(def)
    local icon = def and def.icon
    if not icon or icon == "" then return ICONO_DESCONOCIDO end
    if type(icon) == "number" then return icon end
    if icon:find("\\", 1, true) then return icon end

    local C = _G.HarfordCompendioAPI
    if C and C.ResolveRP3IconName then
        local resuelto = C.ResolveRP3IconName(icon)
        if resuelto then return resuelto end
    end

    local ruta = "Interface\\Icons\\" .. icon
    if GetFileIDFromPath and not GetFileIDFromPath(ruta) then return ICONO_DESCONOCIDO end
    return ruta
end

-- Como se ESCRIBE el dano de un arma. Un dado de UNA cara no se pinta como "1d1": es un
-- valor fijo y se lee como tal. Aplica al Desarmado (1 + Fuerza) y a la Cerbatana, que ya
-- usaba esa convencion. La TIRADA sigue usando WeaponBaseDice, que devuelve el dado real
-- para que ParseDice lo entienda; asi no hace falta un caso especial en el motor.
function HarfordDnDWeapons.WeaponDamageText(def)
    local dados = HarfordDnDWeapons.WeaponBaseDice(def)
    local n, caras = HarfordDnDWeapons.ParseDice(dados)
    if n and caras == 1 then return tostring(n) end
    return dados
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
