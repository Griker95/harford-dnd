-- TIRADA ENFRENTADA (Agarrar, Empujar).
--
-- No es una salvacion contra CD fija: la CD la pone el atacante con su propia tirada, y el
-- defensor responde con la MEJOR de las habilidades que se le ofrecen. Quien elige es el que se
-- defiende, asi que la eleccion tiene que resolverse en SU cliente.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local wr = io.open("Harford/DnD/Engine/HarfordDnDWeaponRolls.lua"):read("*a")
local acc = io.open("Harford/DnD/Data/HarfordDnDActions.lua"):read("*a")
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")

print("La dificultad la pone el atacante, no una CD fija")
chk("hay motor", wr:find("local function RollContest", 1, true) ~= nil, true)
chk("el atacante tira primero", wr:find("local propia = api.RollSkillEx(contest.skill)", 1, true) ~= nil, true)
chk("y su total ES la dificultad", wr:find("dc = total,", 1, true) ~= nil, true)

-- Reutiliza la ruta de salvacion-tras-impacto en vez de escribir otra: esa ya distingue jugador de
-- NPC, le pide la tirada al cliente defensor y aplica el estado al que pierde.
print("No se duplica la resolucion")
chk("reusa la ruta que ya existe",
    wr:find("ResolveWeaponManeuverAfterHitSave({", 1, true) ~= nil, true)
chk("sin opcode nuevo en el protocolo",
    wr:find("DOCONTEST", 1, true), "nil")

print("Elige el DEFENSOR, y elige la mejor")
chk("la lista viaja junta", wr:find('table.concat(contra, "/")', 1, true) ~= nil, true)
chk("el defensor la parte", wr:find('for nombre in tostring(skill):gmatch("[^/]+") do', 1, true) ~= nil, true)
chk("y se queda con la mejor",
    wr:find("if not skillDef or ((b or 0) + (pr or 0)) > ((base or 0) + (prof or 0)) then", 1, true) ~= nil, true)

-- En 5e el defensor gana los empates. `saved = total >= dc` ya lo hace: si iguala, se defiende.
print("El empate lo gana el defensor")
chk("comparacion inclusiva en el defensor", wr:find("local saved = not autoFail and total >= dc", 1, true) ~= nil, true)
chk("y en el NPC", wr:find("local saved = not autoFail and saveTotal >= dc", 1, true) ~= nil, true)

print("Las dos acciones quedan mecanizadas")
chk("agarrar ya no es narrativa", acc:find('id = "agarrar"', 1, true) and acc:sub(acc:find('id = "agarrar"', 1, true), acc:find('id = "empujar"', 1, true)):find("sinEfecto", 1, true), "nil")
chk("agarrar aplica Agarrado", acc:find('onWin = "grappled"', 1, true) ~= nil, true)
chk("empujar aplica Derribado", acc:find('onWin = "prone"', 1, true) ~= nil, true)
chk("ambas se defienden con dos habilidades",
    select(2, acc:gsub('against = { "Atletismo", "Acrobacias" }', "")), 2)

-- Derribar o apartar se declara ANTES de tirar, que es cuando lo decide el manual. Apartar mueve y
-- el movimiento se lleva en mesa, asi que su opcion no deja estado.
print("Empujar deja elegir, y se pregunta antes de tirar")
chk("tiene opciones", acc:find("options = {", 1, true) ~= nil, true)
chk("apartar no deja estado", acc:find("conditionId = false", 1, true) ~= nil, true)
chk("se pregunta antes", panel:find("if type(opciones) == \"table\" and not elegida", 1, true) ~= nil, true)
chk("y la eleccion manda sobre el estado por defecto",
    wr:find("(opts and opts.conditionId ~= nil) and opts.conditionId or contest.onWin", 1, true) ~= nil, true)

print("Conectado al Libro por la ruta de acciones basicas")
chk("rama en el ejecutor", panel:find('elseif type(def.contest) == "table" then', 1, true) ~= nil, true)
chk("sin objetivo no tira", wr:find('if not (UnitExists and UnitExists("target")) then return false, "sin objetivo" end', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
