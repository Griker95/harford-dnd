-- Arnes minimo: stubs de WoW y del proyecto, solo lo que toca la mitigacion.
HarfordClassColors = { StripAccents = function(s)
    s = tostring(s or "")
    local m = { ["á"]="a",["é"]="e",["í"]="i",["ó"]="o",["ú"]="u",["Á"]="A",["ñ"]="n" }
    for k,v in pairs(m) do s = s:gsub(k, v) end
    return s
end }
UnitExists = function(u) return u == "target" end
UnitIsPlayer = function() return false end
UnitIsUnit = function() return false end
local RESIST = {}
HarfordTRP3 = { GetNPCStatBlock = function() return RESIST end }

dofile("Harford/DnD/Data/HarfordDamageMitigation.lua")
local M = HarfordDamageMitigation

local function caso(nombre, resistencias, magico, esperado)
    RESIST = { resistances = resistencias, immunities = {}, vulnerabilities = {} }
    HarfordTRP3.GetNPCStatBlock = function() return RESIST end
    local aplicado, estado = M.ForTarget("target", "contundente", 10,
        magico and { magical = true } or nil)
    local ok = (estado == esperado)
    print(string.format("  %-46s %-4s -> %-10s (%2d)  %s",
        nombre, magico and "MAG" or "-", estado, aplicado, ok and "ok" or "FALLA"))
    return ok
end

print("Golpes empoderados por el chi -- mitigacion")
local todo = true
todo = caso('resistencia "contundente" a secas, golpe normal',
    { "contundente" }, false, "resistant") and todo
todo = caso('resistencia "contundente" a secas, golpe magico',
    { "contundente" }, true, "resistant") and todo
todo = caso('"contundente de ataques no magicos", golpe normal',
    { "contundente de ataques no magicos" }, false, "resistant") and todo
todo = caso('"contundente de ataques no magicos", golpe MAGICO',
    { "contundente de ataques no magicos" }, true, "normal") and todo
todo = caso('"bludgeoning from nonmagical attacks", golpe MAGICO',
    { "bludgeoning from nonmagical attacks" }, true, "normal") and todo
todo = caso('resistencia a otro tipo (fuego), golpe magico',
    { "fuego" }, true, "normal") and todo
print(todo and "TODO CORRECTO" or "HAY FALLOS")
