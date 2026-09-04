-- PERCEPCION PASIVA (regla 5e): 10 + bono TOTAL de la habilidad (mod + competencia/pericia +
-- bonos). Sin tirada: el DM la compara contra el Sigilo de quien se esconde. La dote
-- Observador suma +5 a Percepcion e Investigacion pasivas via los bonus nuevos.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local calc = io.open("Harford/DnD/Engine/HarfordDnDCalc.lua"):read("*a")
local fe = io.open("Harford/DnD/Engine/HarfordDnDFeatureEffects.lua"):read("*a")
local feats = io.open("Harford/DnD/Data/HarfordDnDFeats.lua"):read("*a")
local sheet = io.open("Harford/Character/HarfordCharacterSheet.lua"):read("*a")

print("La pasiva es 10 + bono total, calculada en Calc")
chk("GetPassiveScore existe", calc:find("function HarfordDnDCalc.GetPassiveScore", 1, true) ~= nil, true)
chk("parte del bono de tirada real (mod+competencia)",
    calc:find("local base, prof = HarfordDnDCalc.GetSkillRollBonuses(skill)", 1, true) ~= nil, true)
chk("suma los bonus pasivos", calc:find('"passivePerception"', 1, true) ~= nil
    and calc:find('"passiveInvestigation"', 1, true) ~= nil, true)

print("Los bonus pasivos existen y Observador los usa")
chk("buckets inicializados", fe:find("passivePerception = 0", 1, true) ~= nil
    and fe:find("passiveInvestigation = 0", 1, true) ~= nil, true)
chk("Observador +5/+5", feats:find(
    '{ kind = "bonus", target = "passivePerception", value = 5 }, { kind = "bonus", target = "passiveInvestigation", value = 5 }',
    1, true) ~= nil, true)

print("La ficha la muestra bajo su habilidad")
-- Sobre SkillTotal, que ya sabe de inspeccion: el DM la ve tambien al inspeccionar.
chk("fila de pasiva sobre SkillTotal",
    sheet:find("10 + (tonumber(SkillTotal(skill)) or 0)", 1, true) ~= nil, true)
chk("con el bonus pasivo del perfil que toque",
    sheet:find('skill.id == "Percepcion" and "passivePerception" or "passiveInvestigation"', 1, true) ~= nil, true)
-- El pool de filas de la vista es de 26 y la vista usa 24 + las 2 pasivas: JUSTO. Si se anade
-- una habilidad o cabecera mas, hay que ampliar el pool o las ultimas filas se caen en silencio.
chk("el pool sigue en 26", sheet:find("for i = 1, 26 do", 1, true) ~= nil, true)

print("El DM conserva el dato del NPC")
local trp3 = io.open("Harford/TRP3/HarfordTRP3.lua"):read("*a")
chk("el parser NPC la saca del bloque de Sentidos",
    trp3:find("percepcion pasiva%s*", 1, true) ~= nil
    and trp3:find("result.passivePerception = tonumber(valor)", 1, true) ~= nil, true)
local menu = io.open("HarfordAdmin/HarfordAdminUnitMenu.lua"):read("*a")
chk("pero el menu DM no la duplica",
    menu:find("block.passivePerception", 1, true) == nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
