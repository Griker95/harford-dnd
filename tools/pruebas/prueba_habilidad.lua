-- PRUEBAS DE HABILIDAD contra CD, no salvaciones.
--
-- 5e las usa constantemente y el addon solo sabia resolver salvaciones. Se diferencian en la
-- COMPETENCIA: un bruto con Atletismo suma su competencia, en una salvacion de Fuerza no. Resolver
-- una como la otra no es aproximar, es cambiar la regla -- por eso Corte de Ala se quedo fuera dos
-- veces hasta poder hacerlo bien.
local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local sync = io.open("Harford/Core/HarfordSync.lua"):read("*a")
local wr = io.open("Harford/DnD/Engine/HarfordDnDWeaponRolls.lua"):read("*a")
local combat = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
local book = io.open("Harford/DnD/Data/HarfordDnDBook.lua"):read("*a")
local caz = io.open("Harford/DnD/Data/Classes/Cazador.lua"):read("*a")

print("La habilidad viaja por la red, y en el ULTIMO campo")
-- Al final a proposito: un cliente anterior lo ignora y resuelve una salvacion. Es una degradacion
-- visible en el chat, no un fallo mudo ni un desfase de campos que corromperia el resto.
local iTipo = sync:find('extraDamageType or ""):match("^[%a_]+$") or ""', 1, true)
local iSkill = sync:find('SaveRequestField(tostring(skill or ""):sub(1, 32))', 1, true)
chk("se envia", iSkill ~= nil, true)
chk("despues de todos los demas", (iTipo and iSkill and iSkill > iTipo) and true or false, true)
chk("se recibe", sync:find("extraDamageType, skill =", 1, true) ~= nil, true)

print("Cada lado la resuelve con SU competencia")
chk("el defensor jugador", wr:find("HarfordDnDCalc.GetSkillRollBonuses(s)", 1, true) ~= nil, true)
chk("el NPC", wr:find("HarfordDnDCombat.GetSkillBonusForUnit", 1, true) ~= nil, true)
chk("el bonus de NPC existe", combat:find("function HarfordDnDCombat.GetSkillBonusForUnit", 1, true) ~= nil, true)
chk("sin competencia declarada, el modificador",
    combat:find("if st and tonumber(st.mod) then return tonumber(st.mod) end", 1, true) ~= nil, true)

print("Fallar automaticamente es de SALVACIONES, no de pruebas")
chk("no aplica al NPC", wr:find("local autoFail = (not esPrueba)", 1, true) ~= nil, true)
chk("no aplica al defensor", wr:find("local autoFail = (not skillDef)", 1, true) ~= nil, true)

print("Se lee por su nombre, no como 'Salv FUE'")
local dnd = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("hay etiqueta propia", dnd:find("local function FormatCheckRollLabel", 1, true) ~= nil, true)
chk("la usa el defensor", wr:find("FormatCheckRollLabel(skillDef.name", 1, true) ~= nil, true)
chk("y la ruta NPC", wr:find("FormatCheckRollLabel(data.skill", 1, true) ~= nil, true)

print("Y una maniobra puede declararla")
chk("el campo se arrastra", book:find('"noTarget", "skill" }', 1, true) ~= nil, true)
chk("Corte de Ala pide Atletismo", caz:find('skill = "Atletismo"', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
