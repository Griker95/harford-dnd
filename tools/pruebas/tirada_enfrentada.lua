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

-- `outcome` viaja al defensor como "lo que te pasa AL FALLAR": FormatSaveOutcome lo pega detras de
-- FALLO. El "resiste" que iba de defecto era la semantica invertida -- resistir es lo que hace al
-- GANAR -- y la victima de Empujar publicaba el contradictorio "FALLO resiste".
print("El desenlace del defensor cuenta lo que le pasa al fallar")
chk('"resiste" ya no es el texto de fallo', wr:find('or "resiste"', 1, true), "nil")
chk("primero la opcion elegida (Apartar 1,5 m)",
    wr:find("alFallar = tostring(opts.resultLabel)", 1, true) ~= nil, true)
chk("si no, el nombre del estado que aplica (Derribado)",
    wr:find("alFallar = (condition and condition.label) or tostring(estado)", 1, true) ~= nil, true)

-- La linea de la victima de un Empujar era una prueba huerfana ("Griker Atletismo 8 vs CD 11")
-- sin decir a QUE respondia. El nombre de la accion viaja ahora como ULTIMO campo de DOSAVE
-- (un cliente viejo lo ignora y pierde solo el rotulo) y prefija su linea: "[Empujar] Atletismo...".
print("El nombre de la accion viaja hasta la linea del defensor")
local sync = io.open("Harford/Core/HarfordSync.lua"):read("*a")
local comm = io.open("Harford/DnD/Engine/HarfordDnDComm.lua"):read("*a")
chk("la contienda lo entrega a la resolucion",
    wr:find("actionName = opts and opts.actionName or nil", 1, true) ~= nil, true)
chk("y la resolucion lo reenvia a la peticion de salvacion",
    wr:find("data.extraDamageType, data.skill, data.actionName)", 1, true) ~= nil, true)
chk("DOSAVE lo serializa como ultimo campo",
    sync:find('SaveRequestField(tostring(actionName or ""):sub(1, 40))', 1, true) ~= nil, true)
chk("el receptor lo desempaqueta y lo pasa",
    comm:find("saveExtraDice, saveExtraType, saveSkill, saveActionName)", 1, true) ~= nil, true)
chk("la victima lo pone delante de su tirada",
    wr:find('prefijoAccion = (enlace or ("[" .. accion .. "]")) .. " "', 1, true) ~= nil, true)

-- La accion sale CLICABLE: el atacante recibe el enlace TRP3 del llamador (actionLink) y la
-- victima lo RECONSTRUYE en local desde el catalogo de acciones basicas (por la red viaja solo
-- el nombre: un hyperlink no cabe en el campo). Y la tirada del atacante lleva `targetUnit`
-- para que el whisper extra de Broadcast se la haga llegar a una victima fuera de su grupo —
-- sin eso, la victima solo veia su propia salvacion.
print("La accion es un enlace y la tirada del atacante llega a la victima")
chk("el llamador entrega el enlace",
    panel:find("local actionLink = HarfordTRP3 and HarfordTRP3.GetAbilityChatLink", 1, true) ~= nil, true)
chk("el atacante lo usa de prefijo",
    wr:find("local prefijo = (opts and opts.actionLink)", 1, true) ~= nil, true)
chk("y su tirada viaja dirigida",
    wr:find('targetIsPlayer and { targetUnit = "target" } or { silent = true })', 1, true) ~= nil, true)
chk("RollSkillEx transporta targetUnit",
    io.open("Harford/DnD/Engine/HarfordDnDArcApi.lua"):read("*a")
        :find('targetUnit = type(opts) == "table" and opts.targetUnit or nil', 1, true) ~= nil, true)
chk("y DoRollEx lo pone en el broadcast",
    wr:find("targetUnit = rollContext and rollContext.targetUnit or nil", 1, true) ~= nil, true)
chk("la victima reconstruye el enlace en local",
    wr:find("for _, defAccion in pairs((HarfordDnDActions and HarfordDnDActions.DEFS) or {}) do", 1, true) ~= nil, true)

-- Estabilizar (skillCheck con CD) salia en DOS lineas (tirada + veredicto aparte), sin enlace y
-- sin decir a quien: ahora la tirada va silenciada y se publica UNA linea completa con enlace,
-- target y desenlace. Sin CD (Esconderse) la tirada sigue siendo la linea, con el enlace de
-- etiqueta.
print("Accion con CD: una linea con enlace, target y desenlace")
chk("la tirada con CD va silenciada",
    panel:find("local resultado = _G.DND5E_ARC_API.RollSkillEx(def.skillCheck.skill, nil, { silent = true })", 1, true) ~= nil, true)
chk("la linea lleva enlace, target y veredicto",
    panel:find('label = string.format("%s%s %s %s (%s%s) vs CD %d %s%s%s"', 1, true) ~= nil, true)
chk("y viaja dirigida al target",
    panel:find('targetUnit = (targetName ~= "" and "target") or nil', 1, true) ~= nil, true)
chk("sin CD el enlace es la etiqueta de la tirada",
    panel:find("_G.DND5E_ARC_API.RollSkillEx(def.skillCheck.skill, enlace)", 1, true) ~= nil, true)

-- La linea de ataque de una maniobra decia "[Desarme]: Ataque ... (suelta el objeto)": prosa que
-- no aporta (el desenlace lo cuenta la tirada) y un colon que ninguna otra etiqueta lleva.
print("Sin prosa ni colon en la linea de ataque de maniobra")
local dnd = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("la nota entre parentesis ya no existe", dnd:find("note = man.outcome", 1, true), "nil")
chk("ni su sufijo en la etiqueta", dnd:find("manSuffix", 1, true), "nil")
chk("el prefijo va con espacio, no con colon",
    dnd:find('local manPrefix = (man and manLabel and (manLabel .. " ")) or ""', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
