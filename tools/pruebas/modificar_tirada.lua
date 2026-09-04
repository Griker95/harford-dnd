-- Modificar una tirada YA HECHA: puntos de heroe y dados de enfoque del Cazador.
--
-- La familia entera de 5e que se usa "despues de tirar y antes de saber si acertaste". Vivia
-- dentro de los puntos de heroe con su 1d6 escrito dentro, asi que ningun otro rasgo podia usarla.
--
-- Lo que se prueba: que solo se pueda usar UNA vez sobre la misma tirada, que respete el tipo de
-- tirada, y que la MITAD de la Llamada de lo Salvaje redondee hacia arriba. Los tres se pierden en
-- silencio: nadie ve que un dado se ha gastado dos veces sobre el mismo d20.
local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")
local i = assert(src:find("HarfordDnDRolls.MODIFIABLE_ROLLS = {"))
local codigo = "local HarfordDnDRolls = HarfordDnDRolls\n" .. src:sub(i)

local ULTIMA
local difundido = {}
local HR = { Broadcast = function(d) difundido[#difundido + 1] = d end }
local G = { DND5E_ARC_API = {} }
local env = {
    HarfordDnDRolls = HR, _G = G, type = type, tostring = tostring, tonumber = tonumber,
    math = math, string = string, ipairs = ipairs,
}
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
f()

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-14s %s", etiqueta, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
local function poner(t) G.DND5E_ARC_API._lastRoll = t; difundido = {} end

print("El tipo de tirada se lee de `kind`")
chk("kind", HR.RollKind({ kind = "attack" }), "attack")
chk("rollType heredado", HR.RollKind({ rollType = "save" }), "save")
chk("sin nada cae a roll", HR.RollKind({}), "roll")
chk("sin tirada", HR.RollKind(nil), "roll")

print("Sin tirada reciente no se puede")
G.DND5E_ARC_API._lastRoll = nil
local ok, total, err = HR.ModifyLastRoll({ die = 6, label = "Punto de heroe" })
chk("rechazado", ok, false)
chk("motivo", err, "No hay ninguna tirada reciente")

print("Suma a la ultima tirada (dado fijo con `amount`)")
poner({ kind = "attack", label = "Ataque espada", total = 14 })
ok, total = HR.ModifyLastRoll({ amount = 5, label = "Ataque preciso", applies = { attack = true }, markKey = "focusDie" })
chk("aceptado", ok, true)
chk("total nuevo", total, 19)
chk("la tirada guardada cambia", G.DND5E_ARC_API._lastRoll.total, 19)
chk("se anuncia en mesa", #difundido, 1)
chk("etiqueta con la tirada original", difundido[1].label, "Ataque preciso: Ataque espada")

print("  -- y no se puede usar dos veces sobre la misma tirada:")
ok, total, err = HR.ModifyLastRoll({ amount = 5, label = "Ataque preciso", applies = { attack = true }, markKey = "focusDie" })
chk("rechazado", ok, false)
chk("motivo", err, "Ya usaste eso en esa tirada")
chk("el total no vuelve a subir", G.DND5E_ARC_API._lastRoll.total, 19)

print("  -- pero OTRO rasgo con su propia marca si:")
ok, total = HR.ModifyLastRoll({ amount = 3, label = "Punto de heroe", markKey = "heroPointSpent" })
chk("aceptado", ok, true)
chk("total", total, 22)

print("Respeta el tipo de tirada")
poner({ kind = "save", label = "Salv DES", total = 10 })
ok, total, err = HR.ModifyLastRoll({ amount = 5, applies = { attack = true }, markKey = "focusDie" })
chk("Ataque Preciso no vale en una salvacion", ok, false)
chk("motivo", err, "En esa tirada no se puede usar")
chk("el total no cambia", G.DND5E_ARC_API._lastRoll.total, 10)

print("Llamada de lo Salvaje: la MITAD, redondeando hacia arriba")
local function mitad(dado)
    poner({ kind = "ability", label = "Naturaleza", total = 0 })
    local _, nuevo = HR.ModifyLastRoll({ amount = dado, half = true,
        applies = { ability = true }, markKey = "focusDie" })
    return nuevo
end
for _, par in ipairs({ {1,1}, {2,1}, {3,2}, {4,2}, {5,3}, {6,3}, {7,4}, {8,4} }) do
    chk("d8 = " .. par[1], mitad(par[1]), par[2])
end

print("Si la tirada sabia contra que CA iba, se dice si ahora la supera")
poner({ kind = "attack", label = "Ataque", total = 14, armorClass = 17 })
HR.ModifyLastRoll({ amount = 5, label = "Ataque preciso", applies = { attack = true }, markKey = "focusDie" })
chk("ahora impacta", difundido[1].modifiers, " vs CA 17 |cff00ff00EXITO|r")
poner({ kind = "attack", label = "Ataque", total = 10, armorClass = 17 })
HR.ModifyLastRoll({ amount = 1, label = "Ataque preciso", applies = { attack = true }, markKey = "focusDie" })
chk("sigue sin impactar", difundido[1].modifiers, " vs CA 17 |cffff3333FALLO|r")

print("Anuncio de un numero suelto, sin tocar ninguna tirada")
poner({ kind = "attack", label = "Ataque", total = 14 })
local ok2, valor = HR.AnnounceRollValue({ amount = 6, label = "Tacticas", valueLabel = "a tu CA" })
chk("aceptado", ok2, true)
chk("valor", valor, 6)
chk("la tirada anterior NO se toca", G.DND5E_ARC_API._lastRoll.total, 14)
chk("etiqueta", difundido[1].label, "Tacticas a tu CA")

print("El dado se tira dentro del rango declarado")
local minimo, maximo = 99, 0
for _ = 1, 400 do
    poner({ kind = "attack", label = "A", total = 0 })
    local _, n = HR.ModifyLastRoll({ die = 8, applies = { attack = true }, markKey = "focusDie" })
    if n < minimo then minimo = n end
    if n > maximo then maximo = n end
end
chk("d8 minimo", minimo, 1)
chk("d8 maximo", maximo, 8)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
