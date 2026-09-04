-- HarfordDnDCombat: CA, impacto y los bonos del objetivo.
--
-- Aqui se decide si un ataque entra, y estaba sin cubrir: de 14 mutaciones, las 14 pasaban. Un `>`
-- por `>=` convierte cada empate en impacto, que es el fallo mas silencioso posible -- nadie mira
-- la tirada que empata, solo lee "EXITO".

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable = setmetatable
env.HarfordClassColors = {
    NormalizeKey = function(v) return tostring(v or ""):lower() end,
    UnitFullName = function(u) return tostring(u) end,
}

local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
assert(pcall(f))
local K = env.HarfordDnDCombat

-- Deja la linea de color fuera de la comparacion: lo que se prueba es la REGLA, no el markup.
local function limpio(texto)
    return tostring(texto or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

-- ─── El empate lo pierde el atacante ────────────────────────────────────────
-- Regla del manual: hay que IGUALAR o superar la CA... y en Harford la comparacion es `>` sobre la
-- CA ya resuelta. La mesa lo tiene decidido asi: el defensor gana los empates.
print("Impacto contra la CA")
env.HarfordDnDCombat.ArmorClassOverrides = { ["target"] = 15 }
env.UnitExists = function() return true end
env.UnitGUID = function(u) return "GUID-" .. tostring(u) end
env.UnitIsPlayer = function() return false end
K.SetArmorClassForUnit("target", 15)

local ca, impacta, texto = K.ResolveArmorClassOutcome(16, "", "target")
chk("por encima, entra", impacta, true)
chk("y dice contra que CA", limpio(texto), " vs CA 15 EXITO")
_, impacta = K.ResolveArmorClassOutcome(15, "", "target")
chk("empatando, NO entra", impacta, false)
_, impacta = K.ResolveArmorClassOutcome(14, "", "target")
chk("por debajo, no entra", impacta, false)

-- Un critico entra pase lo que pase, y una pifia falla aunque el total sobre.
print("Critico y pifia mandan sobre el numero")
_, impacta = K.ResolveArmorClassOutcome(1, "CRÍTICO", "target")
chk("critico con total 1 entra igual", impacta, true)
_, impacta = K.ResolveArmorClassOutcome(99, "PIFIA", "target")
chk("pifia con total 99 falla igual", impacta, false)

-- La etiqueta llega con y sin tilde segun de donde venga; las dos son el mismo critico.
print("El critico se reconoce con tilde y sin ella")
chk("con tilde", K.IsCriticalRollTag("CRÍTICO"), true)
chk("sin tilde", K.IsCriticalRollTag("CRITICO"), true)
chk("y otra cosa no", K.IsCriticalRollTag("PIFIA"), false)

-- ─── Cobertura ──────────────────────────────────────────────────────────────
print("La cobertura sube la CA del objetivo")
env.HarfordDnDManeuvers = { GetCover = function()
    return "media", { ac = 2, label = "Media" }
end }
ca, impacta, texto = K.ResolveArmorClassOutcome(16, "", "target")
chk("media suma 2", ca, 17)
chk("y un 16 ya no entra", impacta, false)
chk("y se dice en la linea", limpio(texto):find("cobertura media", 1, true) ~= nil, true)
env.HarfordDnDManeuvers = { GetCover = function()
    return "tres_cuartos", { ac = 5, label = "Tres cuartos" }
end }
chk("tres cuartos suma 5", (K.ResolveArmorClassOutcome(16, "", "target")), 20)
-- Cobertura total no es una CA mas alta: es que no se le puede elegir como objetivo.
env.HarfordDnDManeuvers = { GetCover = function() return "total", { label = "Total" } end }
ca, impacta, texto = K.ResolveArmorClassOutcome(99, "", "target")
chk("total no deja atacar ni con 99", impacta, false)
chk("y lo explica", limpio(texto):find("no puedes elegirlo", 1, true) ~= nil, true)
env.HarfordDnDManeuvers = nil

-- Sin CA conocida no se inventa un resultado: el ataque se anuncia sin veredicto.
print("Sin CA conocida no se dictamina nada")
K.ArmorClassOverrides = {}
env.UnitExists = function() return false end
ca, impacta, texto = K.ResolveArmorClassOutcome(16, "", "target")
chk("sin CA", ca, "nil")
chk("sin veredicto", impacta, "nil")
chk("y sin texto", texto, "")
env.UnitExists = function() return true end

-- ─── CA propia ──────────────────────────────────────────────────────────────
print("CA propia: sin armadura son 10 mas Destreza")
env.HarfordDnDItems = { GetEquippedArmorClass = function() return nil end }
env.HarfordDnDCalc = { GetAbilityMod = function(a)
    return ({ Destreza = 3, Sabiduria = 2, Inteligencia = 4 })[a] or 0
end }
env.HarfordDnDFeatureEffects = { GetBonus = function() return 0 end }
chk("desarmado", K.ComputeSelfArmorClass(), 13)

-- Defensa sin Armadura NO se acumula: un multiclase Monje/Cazador de Demonios se queda con la
-- MEJOR, no con las dos. Sumarlas daba 10 + Des + Sab + Int.
print("Defensa sin Armadura: la mejor, nunca la suma")
env.HarfordDnDFeatureEffects = { GetBonus = function() return 0 end,
    GetUnarmoredDefenseAbilities = function() return { "Sabiduria" } end }
chk("solo Monje: 10+3+2", K.ComputeSelfArmorClass(), 15)
env.HarfordDnDFeatureEffects.GetUnarmoredDefenseAbilities = function()
    return { "Sabiduria", "Inteligencia" }
end
chk("Monje y Cazador de Demonios: la mejor, no las dos", K.ComputeSelfArmorClass(), 17)

-- Con armadura equipada esa rama ni se toca: la CA sale del equipo.
print("Con armadura equipada manda el equipo")
env.HarfordDnDItems = { GetEquippedArmorClass = function() return 16 end }
chk("la del equipo", K.ComputeSelfArmorClass(), 16)
chk("y Defensa sin Armadura ya no suma", K.ComputeSelfArmorClass(), 16)
env.HarfordDnDFeatureEffects.GetBonus = function(k) return k == "armorClass" and 1 or 0 end
chk("pero un bonus de rasgo si", K.ComputeSelfArmorClass(), 17)

-- Prioridades: una forma druidica manda sobre todo, y TRP3 sobre el equipo.
print("Prioridad: forma, luego TRP3, luego equipo")
env.HarfordTRP3 = { GetPlayerArmorClass = function() return 14 end }
chk("TRP3 gana al equipo", K.ComputeSelfArmorClass(), 14)
env.HarfordDnDForms = { GetArmorClass = function() return 12 end }
chk("y la forma gana a TRP3", K.ComputeSelfArmorClass(), 12)
env.HarfordDnDForms = nil
env.HarfordTRP3 = nil

-- ─── Bonos del objetivo ─────────────────────────────────────────────────────
print("Salvacion del objetivo: la del stat block, o su modificador")
env.HarfordTRP3 = { GetNPCStatBlock = function()
    return {
        savingThrows = { dexterity = 6 },
        stats = { dexterity = { mod = 2 }, wisdom = { mod = 1 } },
        skills = { { name = "Sigilo", bonus = 7 } },
    }
end }
chk("la declarada", K.GetSaveBonusForUnit("target", "Destreza"), 6)
chk("y si no la declara, su modificador", K.GetSaveBonusForUnit("target", "Sabiduria"), 1)
chk("sin ninguno de los dos, cero", K.GetSaveBonusForUnit("target", "Carisma"), 0)

print("Habilidad del objetivo: la del stat block, o el modificador de su caracteristica")
env.HarfordDnDData = { SKILLS = {
    { id = "sigilo", name = "Sigilo", ability = "Destreza" },
    { id = "percepcion", name = "Percepcion", ability = "Sabiduria" },
} }
chk("la declarada", K.GetSkillBonusForUnit("target", "Sigilo"), 7)
chk("y si no, la caracteristica", K.GetSkillBonusForUnit("target", "Percepcion"), 1)
chk("una que no existe, cero", K.GetSkillBonusForUnit("target", "Inventada"), 0)
chk("sin nombre, cero", K.GetSkillBonusForUnit("target", ""), 0)
-- Sin unidad no hay a quien preguntar: cero, no un error.
env.UnitExists = function() return false end
chk("sin unidad, cero", K.GetSkillBonusForUnit("target", "Sigilo"), 0)
chk("y la salvacion tambien", K.GetSaveBonusForUnit("target", "Destreza"), 0)

-- ─── De donde sale la CA: NPC y jugador son dos cadenas distintas ───────────
-- Es lo que separa atacar a un NPC de atacar a un jugador, y ninguna de las dos se comprobaba.
print("Objetivo NPC: turnos, luego lo escrito a mano, luego su stat block")
env.UnitExists = function() return true end
env.UnitIsPlayer = function() return false end
env.UnitIsUnit = function() return false end
env.UnitGUID = function() return "GUID-NPC" end
K.ArmorClassOverrides = {}
env.HarfordTurnOrderAPI = nil
env.HarfordTRP3 = { GetNPCStatBlock = function() return { ac = 13 } end }
chk("sin nada mas, la del stat block", K.GetArmorClassForUnit("target"), 13)
K.SetArmorClassForUnit("target", 17)
chk("lo escrito a mano manda sobre el stat block", K.GetArmorClassForUnit("target"), 17)
env.HarfordTurnOrderAPI = { GetArmorClassForGuid = function() return 20 end }
chk("y el tracker de turnos manda sobre todo", K.GetArmorClassForUnit("target"), 20)
env.HarfordTurnOrderAPI = nil
K.ArmorClassOverrides = {}
env.HarfordTRP3 = { GetNPCStatBlock = function() return { ac = 0 } end }
chk("un stat block sin CA no vale", K.GetArmorClassForUnit("target"), "nil")

print("Objetivo JUGADOR: TRP3 manda, luego lo que el mismo publica")
env.UnitIsPlayer = function() return true end
env.HarfordTRP3 = { GetPlayerArmorClass = function() return 18 end }
chk("lo que ponga en TRP3", K.GetArmorClassForUnit("target"), 18)
-- Sin TRP3, lo que su propio cliente haya difundido; y si no, lo escrito a mano.
env.HarfordTRP3 = { GetPlayerArmorClass = function() return nil end }
env.HarfordDnDStore = { GetRemoteResource = function() return nil end }
K.SetArmorClassForUnit("target", 15)
chk("si no, lo escrito a mano", K.GetArmorClassForUnit("target"), 15)
K.ArmorClassOverrides = {}
chk("y sin nada, no se inventa", K.GetArmorClassForUnit("target"), "nil")

-- Contra uno mismo se usa la CA propia calculada, no la cache remota.
print("Contra uno mismo se usa la CA propia")
env.UnitIsUnit = function(a, b) return b == "player" end
env.HarfordDnDItems = { GetEquippedArmorClass = function() return 16 end }
env.HarfordDnDFeatureEffects = { GetBonus = function() return 0 end }
chk("la calculada", K.GetArmorClassForUnit("player"), 16)
env.UnitIsUnit = function() return false end

-- Sin unidad no hay CA: ni cero, ni un valor por defecto que mienta.
print("Sin unidad no hay CA")
env.UnitExists = function() return false end
chk("nil, no cero", K.GetArmorClassForUnit("target"), "nil")
env.UnitExists = function() return true end

-- ─── EL DEFENSOR GANA LOS EMPATES ───────────────────────────────────────────
-- Divergencia DELIBERADA del manual: en 5e una tirada que iguala la CA impacta; en esta mesa no.
-- Se comprueba que los TRES sitios que resuelven la comparacion dicen lo mismo, porque uno usaba
-- `>=` y la misma tirada contra la misma CA salia "FALLO" al atacar y "EXITO" al gastar
-- un dado sobre ella.
print("Los tres sitios resuelven el empate igual")
local combate2 = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
local area2 = io.open("Harford/DnD/Engine/HarfordDnDArea.lua"):read("*a")
local rolls2 = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")
chk("al atacar", combate2:find("(tonumber(total) or 0) > armorClass", 1, true) ~= nil, true)
chk("en area", area2:find("request.attackTotal > armorClass", 1, true) ~= nil, true)
chk("y al recalcular tras gastar", rolls2:find('nuevo > ca and "|cff00ff00EXITO|r"', 1, true) ~= nil, true)
-- Si alguno vuelve a `>=`, esto lo caza antes de que la mesa vea dos respuestas distintas.
chk("ninguno usa >= contra la CA",
    (rolls2:find("nuevo >= ca", 1, true) == nil)
    and (combate2:find("or 0) >= armorClass", 1, true) == nil)
    and (area2:find("attackTotal >= armorClass", 1, true) == nil), true)
-- Y que quede escrito: sin documentar, la siguiente revision lo marca como bug y lo "arregla".
local agentes = io.open("AGENTS.md"):read("*a")
chk("y esta documentado como divergencia",
    agentes:find("El defensor gana los empates de CA", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
