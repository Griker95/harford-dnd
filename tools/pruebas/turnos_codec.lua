-- Arnes del codec de turnos. Ya no hace falta simular frames ni el store.
strsplit = function(sep, str)
    local out = {}
    for part in (tostring(str) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do out[#out+1] = part end
    return (unpack or table.unpack)(out)
end
Ambiguate = function(n) return (tostring(n):match("^[^-]+")) or n end
GetRealmName = function() return "Epsilon" end
dofile("Harford/Frames/HarfordTurnsCodec.lua")
local C = HarfordTurnsCodec
C.Init({ NormalizeKind = function(k)
    local ok = { round=1, generic=1, players=1, player=1, npc=1 }
    k = tostring(k or "")
    return ok[k] and k or "npc"
end })
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-22s %s", n, tostring(real):sub(1,22), ok and "ok" or ("FALLA: " .. tostring(esp))))
end

print("Escapado: los separadores del protocolo no pueden colarse")
for _, t in ipairs({ "Grom|Hellscream", "a,b;c", "100%", "Nombre normal", "|c00ff00Verde|r", "" }) do
    chk("ida y vuelta: " .. (t == "" and "(vacio)" or t), C.UnescapeText(C.EscapeText(t)), t)
end
chk("no queda ninguna | cruda", C.EscapeText("a|b"):find("|", 1, true), "nil")
chk("no queda ninguna , cruda", C.EscapeText("a,b"):find(",", 1, true), "nil")
chk("no queda ningun ; crudo", C.EscapeText("a;b"):find(";", 1, true), "nil")

print("Entrada completa: ida y vuelta")
local e = { id = "abc-1", name = "Gnoll|Jefe, el 100%", kind = "npc", initiative = 17,
            hp = 23, maxHp = 40, hidden = false, mana = 3, maxMana = 9,
            unitName = "Gnoll-Epsilon", icon = "Interface/Icons/X", displayId = 5,
            armorClass = 15 }
local v = C.DeserializeEntry(C.SerializeEntry(e))
chk("nombre con separadores intacto", v.name, e.name)
chk("iniciativa", v.initiative, 17)
chk("vida", v.hp .. "/" .. v.maxHp, "23/40")
chk("CA", v.armorClass, 15)
chk("tipo", v.kind, "npc")

print("Tipos: lo que llega raro se normaliza")
local raro = C.DeserializeEntry(C.SerializeEntry({ id="x", name="N", kind="focus" }))
chk('un cliente viejo manda "focus"', raro.kind, "npc")

print("Troceado y reensamblado de una carga larga")
local largo = string.rep("Nombre|con,separadores;raros ", 40)
local trozos = C.SplitEscapedChunks(largo)
print(string.format("  %d trozos para %d caracteres", #trozos, #largo))
local buf = {}
local hecho = false
for i, t in ipairs(trozos) do
    local r = C.ApplyChunked("SCHUNK|tid|" .. i .. "|" .. #trozos .. "|" .. t, "Pepe", "SCHUNK", "",
        function(m) buf[1] = m hecho = true return true end)
end
chk("se reensambla completo", hecho, true)
chk("y es identico al original", buf[1], largo)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
