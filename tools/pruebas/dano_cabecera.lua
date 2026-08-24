-- Arnes de la cabecera de dano por tipo, ahora que existe una sola implementacion.
HarfordDnDRolls = {}
HarfordDamageTypes = {
    FromWord = function(k) return ({cortante="slashing", frio="cold", fuego="fire"})[k] or k end,
    GetLabel = function(k) return ({slashing="Cortante", cold="Frio", fire="Fuego"})[k] or k end,
}
local src = io.open("Harford/DnD/Engine/HarfordDnDRolls.lua"):read("*a")
local i = assert(src:find("function HarfordDnDRolls.FormatDamageHeader"))
local j = assert(src:find("\nend", i))
assert((loadstring or load)(src:sub(i, j + 4)))()
local F = HarfordDnDRolls.FormatDamageHeader
local fallos = 0
local function chk(n, a, b, ea, eb)
    local ok = tostring(a) == tostring(ea) and b == eb
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-44s %-4s %-32s %s", n, tostring(a), b, ok and "ok" or ("FALLA: "..tostring(ea).." / "..eb)))
end
local function limpio(s) return (s:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")) end

print("Un solo tipo")
local a, b = F({"cortante"}, {cortante={total=9, marker=""}}, 9)
chk("9 cortante", a, limpio(b), 9, "Cortante")

print("Dos tipos: el segundo va en modifiers")
a, b = F({"cortante","frio"}, {cortante={total=6,marker=""}, frio={total=10,marker=""}}, 16)
chk("6 cortante + 10 frio", a, limpio(b), 6, "Cortante 10 Frio")

print("Marcadores de mitigacion")
a, b = F({"cortante","frio"}, {cortante={total=3,marker="R"}, frio={total=10,marker="V"}}, 13)
chk("resistente y vulnerable", a, limpio(b), 3, "Cortante R 10 Frio V")

print("Casos limite")
a, b = F({}, {}, 7)
chk("sin tipos: devuelve el total dado", a, b, 7, "")
a, b = F({"fuego"}, {}, 5)
chk("tipo sin entrada en el mapa", a, b, 5, "")
a, b = F(nil, nil, 4)
chk("nil no revienta", a, b, 4, "")
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
