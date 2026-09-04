-- MEJORAS MECANICAS DEL MECAGNOMO, mecanizadas (2026-09-04). Cada opcion aplica de verdad:
-- piernas = bono de velocidad, brazos = dado desarmado + herramienta, resiliencia = base
-- alternativa de CA sin armadura, generador = truco por spellId, emergencia = rasgo derivado
-- (requiresOption) con boton selfHeal y 1 uso/descanso largo. La segunda mejora es un choice
-- propio con puerta `minCharacterLevel = 5`. Vision queda narrativa a proposito (el cliente
-- no observa la vision).

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable, env.pcall = setmetatable, pcall
env._G = env
local function ejecutar(ruta)
    local f
    local src = io.open(ruta):read("*a")
    if setfenv then f = assert(cargar(src), ruta); setfenv(f, env)
    else f = assert(cargar(src, "t", "t", env), ruta) end
    pcall(f)
end
ejecutar("Harford/Core/HarfordClassColors.lua")
ejecutar("Harford/DnD/Data/HarfordDnDRaces.lua")

local R = env.HarfordDnDRaces
local sub = R.GetSubrace("raza_gnomo", "raza_gnomo_mecagnomo")
local porId = {}
for _, t in ipairs((sub and sub.traits) or {}) do porId[t.id] = t end

print("Las dos elecciones y el rasgo derivado existen")
chk("mejoras (nivel 1)", porId.gno_mec_mejoras and porId.gno_mec_mejoras.choice ~= nil, true)
chk("mejora adicional a nivel 5", porId.gno_mec_mejoras_5
    and porId.gno_mec_mejoras_5.minCharacterLevel, 5)
chk("emergencia derivada de la opcion", porId.gno_mec_emergencia
    and porId.gno_mec_emergencia.requiresOption, "emergencia")
chk("con boton de curacion", porId.gno_mec_emergencia
    and porId.gno_mec_emergencia.actionKind, "selfHeal")
chk("nivel + Constitucion", porId.gno_mec_emergencia
    and porId.gno_mec_emergencia.healBase .. "/" .. porId.gno_mec_emergencia.healAbility,
    "level/Constitucion")
chk("1 uso por descanso largo", porId.gno_mec_emergencia
    and porId.gno_mec_emergencia.uses.max .. "/" .. porId.gno_mec_emergencia.uses.recharge, "1/long")

print("Cada opcion aplica su mecanica")
local function Opcion(feature, id)
    for _, o in ipairs(feature.choice.options) do if o.id == id then return o end end
end
for _, featureId in ipairs({ "gno_mec_mejoras", "gno_mec_mejoras_5" }) do
    local f = porId[featureId]
    local piernas = Opcion(f, "piernas")
    chk(featureId .. ": piernas suma velocidad", piernas.effects[1].kind .. "/"
        .. piernas.effects[1].target .. "/" .. piernas.effects[1].value, "bonus/speed/1.5")
    local brazos = Opcion(f, "brazos")
    chk(featureId .. ": brazos 1d6 desarmado", brazos.effects[1].kind .. "/" .. brazos.effects[1].die,
        "unarmedDie/6")
    chk(featureId .. ": brazos herramienta", brazos.effects[2].kind, "toolProf")
    local resil = Opcion(f, "resiliencia")
    chk(featureId .. ": resiliencia base 13", resil.effects[1].kind .. "/" .. resil.effects[1].base,
        "unarmoredDefenseBase/13")
    chk(featureId .. ": generador concede el truco", Opcion(f, "generador_luz").spellId, "ilusion_menor")
    chk(featureId .. ": caracteristica del truco", f.spellAbility, "Inteligencia")
end

print("Los motores consumen los efectos nuevos")
local fe = io.open("Harford/DnD/Engine/HarfordDnDFeatureEffects.lua"):read("*a")
chk("kind unarmoredDefenseBase", fe:find('kind == "unarmoredDefenseBase"', 1, true) ~= nil, true)
chk("kind unarmedDie", fe:find('kind == "unarmedDie"', 1, true) ~= nil, true)
local combat = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
chk("Combat usa la base alternativa", combat:find("GetUnarmoredDefenseBase", 1, true) ~= nil, true)
local rolls = io.open("Harford/DnD/Engine/HarfordDnDWeaponRolls.lua"):read("*a")
chk("WeaponRolls sube el dado desarmado",
    rolls:find('def.key == "Desarmado"', 1, true) ~= nil
    and rolls:find("GetUnarmedDie", 1, true) ~= nil, true)
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
chk("el Libro ejecuta selfHeal", panel:find('actionKind == "selfHeal"', 1, true) ~= nil, true)

print("Las puertas se aplican en las tres rutas")
local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("runtime (GetUnlockedFeatures)", prog:find("minCharacterLevel", 1, true) ~= nil
    and prog:find("local function Entra(item)", 1, true) ~= nil, true)
local cre = io.open("Harford/Character/HarfordCharacterCreation.lua"):read("*a")
chk("About del creador", cre:find("feature.minCharacterLevel", 1, true) ~= nil, true)
local adv = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")
chk("asistente (oferta racial)", adv:find("local function EntraRacial(feature)", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
