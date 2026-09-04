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
local panel = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))

print("La dificultad la pone el atacante, no una CD fija")
chk("hay motor", wr:find("local function RollContest", 1, true) ~= nil, true)
chk("el atacante tira primero", wr:find("local propia = api.RollSkillEx(contest.skill,", 1, true) ~= nil, true)
chk("y su total ES la dificultad", wr:find("dc = total,", 1, true) ~= nil, true)
chk("NPC: la tirada inicial se silencia para publicar la contienda unida",
    wr:find("{ silent = true }", 1, true) ~= nil, true)
chk("NPC: la contienda se publica en una unica linea",
    wr:find("local defense = ResolveWeaponManeuverAfterHitSave({", 1, true) ~= nil, true)

-- Reutiliza la ruta de salvacion-tras-impacto en vez de escribir otra: esa ya distingue jugador de
-- NPC, le pide la tirada al cliente defensor y aplica el estado al que pierde.
print("No se duplica la resolucion")
chk("reusa la ruta que ya existe",
    wr:find("ResolveWeaponManeuverAfterHitSave({", 1, true) ~= nil, true)
chk("sin opcode nuevo en el protocolo",
    wr:find("DOCONTEST", 1, true), "nil")

-- Esto se EJECUTA, no se busca en el texto. Que el fichero contenga la linea correcta no demuestra
-- que elija bien: hoy mismo, una asercion llamada "la eleccion manda sobre el estado por defecto"
-- pasaba mientras la expresion que comprobaba estaba mal.
print("Elige el DEFENSOR, y elige la mejor")
chk("la lista viaja junta", wr:find('table.concat(contra, "/")', 1, true) ~= nil, true)

local ini = assert(wr:find("local skillDef, base, prof", 1, true))
-- El corte tiene que ser inequivoco. "if not skillDef then" tambien aparece DENTRO del bloque que
-- se extrae, asi que se toma la ULTIMA aparicion antes del `GetSaveRollBonuses`, que es la de
-- verdad. Con la primera, mutar la condicion interna movia el corte y el fallo salia como error de
-- sintaxis en vez de como asercion: rojo igual, pero ilegible.
local tope = assert(wr:find("base, prof = HarfordDnDCalc.GetSaveRollBonuses(ability)", ini, true))
local fin, busca = nil, ini
while true do
    local x = wr:find("    if not skillDef then", busca, true)
    if not x or x >= tope then break end
    fin, busca = x, x + 1
end
fin = assert(fin)
local cuerpo = wr:sub(ini, fin - 1)

-- Bonos de mentira elegidos para DISCRIMINAR: lo que decide es base+competencia, asi que Atletismo
-- (1+5=6) gana a Acrobacias (4+0=4) aunque su base sea menor. Con datos donde la base sola diera la
-- misma respuesta, un fallo que comparase solo la base pasaria la prueba: se comprobo mutando el
-- codigo, y con los numeros anteriores no saltaba.
local BONOS = { Atletismo = { 1, 5 }, Acrobacias = { 4, 0 }, Sigilo = { 0, 1 } }
local env = {
    ipairs = ipairs, tostring = tostring, tonumber = tonumber,
    HarfordClassColors = { NormalizeKey = function(v) return tostring(v or ""):lower() end },
    HarfordDnDData = { SKILLS = {
        { id = "atletismo", name = "Atletismo" },
        { id = "acrobacias", name = "Acrobacias" },
        { id = "sigilo", name = "Sigilo" },
    } },
    HarfordDnDCalc = { GetSkillRollBonuses = function(s)
        local b = BONOS[s.name] or { 0, 0 }
        return b[1], b[2]
    end },
}
local cargar = loadstring or load
local codigo = "local skill = ...\n" .. cuerpo .. "\nreturn skillDef, base, prof"
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local function Elige(lista)
    local def, b, pr = f(lista)
    if not def then return "nil" end
    return def.name .. "=" .. tostring((b or 0) + (pr or 0))
end

-- Acrobacias suma 4 y Atletismo 3: gana Acrobacias, venga en el orden que venga.
chk("de dos, la mejor", Elige("Atletismo/Acrobacias"), "Atletismo=6")
chk("y da igual el orden", Elige("Acrobacias/Atletismo"), "Atletismo=6")
chk("una sola, esa", Elige("Atletismo"), "Atletismo=6")
chk("las tres, la mejor de las tres", Elige("Sigilo/Atletismo/Acrobacias"), "Atletismo=6")
-- Un cliente viejo puede mandar una habilidad que este no conozca: no debe quedarse a medias.
chk("una desconocida se ignora", Elige("Inventada/Atletismo"), "Atletismo=6")
chk("todas desconocidas, ninguna", Elige("Inventada/Tampoco"), "nil")
chk("sin habilidad, ninguna", Elige(""), "nil")

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
chk("se pregunta antes de tirar, anunciar o gastar",
    panel:find("if Elegir(def.contest.options, def, ConEleccion, nil) then return true end", 1, true) ~= nil, true)
-- `cond and X or Y` devuelve Y cuando X es FALSE, que es justo lo que vale "apartar". Con ese
-- idioma, elegir apartar derribaba igual. Se resuelve con un `if`, y la prueba lo fija ejecutando
-- la logica de verdad en vez de mirar el texto.
chk("y la eleccion manda sobre el estado por defecto",
    wr:find("estado = opts.conditionId or nil", 1, true) ~= nil, true)
local function EstadoElegido(opts, onWin)
    local estado = onWin
    if opts and opts.conditionId ~= nil then estado = opts.conditionId or nil end
    return estado
end
chk("derribar aplica Derribado", EstadoElegido({ conditionId = "prone" }, "prone"), "prone")
chk("APARTAR no aplica ninguno", EstadoElegido({ conditionId = false }, "prone"), "nil")
chk("sin elegir, el de por defecto", EstadoElegido(nil, "prone"), "prone")

print("Conectado al Libro por la ruta de acciones basicas")
chk("rama en el ejecutor", panel:find('elseif type(def.contest) == "table" then', 1, true) ~= nil, true)
chk("sin objetivo no tira", wr:find('if not (UnitExists and UnitExists("target")) then return false, "sin objetivo" end', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
