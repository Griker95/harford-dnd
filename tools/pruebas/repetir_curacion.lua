-- REPETIR una curacion ya tirada (Oracion de Curacion del Sacerdote).
--
-- El motor de "modificar una tirada ya hecha" solo sabia SUMAR. Repetir es otra cosa: se vuelven a
-- tirar los dados y vale el resultado nuevo, salga mejor o peor -- quedarse con el mejor de los dos
-- seria otra regla distinta.
--
-- Y hacen falta los DADOS, no el total: sin saber cuantos eran y de que caras no hay nada que
-- repetir. Por eso las curaciones pasan a registrarse como ultima tirada.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")
local i = assert(src:find("function HarfordDnDRolls.RecordHealRoll", 1, true))
local j = assert(src:find("function HarfordDnDRolls.ModifyLastRoll", i, true))
local codigo = "local HarfordDnDRolls, HarfordDnDCalc, time = ...\n" .. src:sub(i, j - 1)
    .. "\nreturn HarfordDnDRolls"

local difundido = {}
local R = {
    Broadcast = function(d) difundido[#difundido + 1] = d end,
    RollKind = function(r) return tostring((r and r.kind) or "roll"):lower() end,
}
local G = { DND5E_ARC_API = {} }
local siguiente = 1
local Calc = { RollDie = function() siguiente = siguiente + 1; return siguiente end }
local env = { _G = G, type = type, tostring = tostring, tonumber = tonumber, math = math,
              ipairs = ipairs, table = table, string = string }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
f(R, Calc, function() return 0 end)

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-16s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("Sin curacion registrada no hay nada que repetir")
G.DND5E_ARC_API._lastRoll = nil
local ok, nuevo, err = R.RerollLastHeal({})
chk("rechazado", ok, false)
chk("motivo", err, "No hay ninguna tirada reciente")

print("Una tirada que no es curacion tampoco")
G.DND5E_ARC_API._lastRoll = { kind = "attack", total = 14 }
ok, nuevo, err = R.RerollLastHeal({})
chk("rechazado", ok, false)
chk("motivo", err, "La ultima tirada no fue una curacion")

print("Una curacion sin dados (cantidad fija) tampoco")
R.RecordHealRoll({ label = "Efusion", total = 3, aplicadoA = "self" })
ok, nuevo, err = R.RerollLastHeal({})
chk("rechazado", ok, false)
chk("motivo", err, "Esa curacion no tenia dados que repetir")

print("Con dados: se repiten y vale el resultado NUEVO")
siguiente = 4
R.RecordHealRoll({ label = "Dado de Golpe d8", total = 5, aplicadoA = "self",
    healDice = { { count = 1, sides = 8, bonus = 2 } }, healRolls = { 3 } })
difundido = {}
local ok2, total, _, anterior = R.RerollLastHeal({ label = "Oracion", markKey = "oracionCuracion" })
chk("aceptado", ok2, true)
chk("total nuevo (d8=5, bonus 2)", total, 7)
chk("devuelve el anterior", anterior, 5)
chk("la tirada guardada se actualiza", G.DND5E_ARC_API._lastRoll.total, 7)
chk("se anuncia", #difundido, 1)
chk("y dice cual era", difundido[1].modifiers, "antes 5")

print("  -- y no se puede repetir dos veces la misma:")
ok2, total, err = R.RerollLastHeal({ markKey = "oracionCuracion" })
chk("rechazado", ok2, false)
chk("motivo", err, "Ya repetiste esa curacion")

print("Varios grupos de dados se repiten todos")
siguiente = 0
R.RecordHealRoll({ label = "Curacion mayor", total = 99, aplicadoA = "self",
    healDice = { { count = 2, sides = 6, bonus = 0 }, { count = 1, sides = 4, bonus = 3 } } })
local _, t2 = R.RerollLastHeal({})
chk("2d6 (1+2) + 1d4 (3) + 3", t2, 9)

print("El resultado peor tambien vale: repetir es repetir")
siguiente = 0
R.RecordHealRoll({ label = "Dado de Golpe d8", total = 8, aplicadoA = "self",
    healDice = { { count = 1, sides = 8, bonus = 0 } } })
local _, t3, _, ant3 = R.RerollLastHeal({})
chk("baja de 8 a 1", t3, 1)
chk("y el anterior era", ant3, 8)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
