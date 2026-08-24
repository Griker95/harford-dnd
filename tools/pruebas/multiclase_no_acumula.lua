-- Recursos y rasgos que NO se acumulan al multiclasear.
--
-- Dos reglas explicitas del PHB que el motor sumaba a ciegas:
--   - Canalizar Divinidad: si ya tienes el rasgo y subes nivel en otra clase que tambien lo
--     concede, obtienes sus efectos pero NO usos adicionales. Paladin y Sacerdote lo dan.
--   - Defensa sin Armadura: solo puedes beneficiarte de UNA. Monje suma Sabiduria y Cazador de
--     Demonios suma Inteligencia; sumarlas daba 10 + Des + Sab + Int.
local cargar = loadstring or load
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ── 1. resourceMax con stack = "max", extraido del motor real ──
local src = io.open("Harford/DnD/Engine/HarfordDnDFeatureEffects.lua"):read("*a")
local i = assert(src:find('elseif kind == "resourceMax" and effect%.resource then'))
local j = assert(src:find("\n    elseif kind ==", i))
local cuerpo = src:sub(i, j)
-- Se envuelve el fragmento en una funcion que aplica UN efecto.
local codigo = [[
local resolved = { resourceMax = {} }
local function Add(t, k, v) t[k] = (tonumber(t[k]) or 0) + (tonumber(v) or 0) end
local function Aplicar(effect)
    local kind = effect.kind
    if false then
]] .. cuerpo .. [[
    end
    return resolved
end
return Aplicar, resolved
]]
local env = { tonumber = tonumber, tostring = tostring, math = math, type = type, ipairs = ipairs,
              HarfordDnDProgression = nil }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "rm", "t", env)) end
local Aplicar, resolved = f()

print("Canalizar Divinidad: Paladin + Sacerdote")
Aplicar({ kind = "resourceMax", resource = "channel_divinity", value = 1, stack = "max" })
chk("una fuente da 1 uso", resolved.resourceMax.channel_divinity, 1)
Aplicar({ kind = "resourceMax", resource = "channel_divinity", value = 1, stack = "max" })
chk("la segunda NO anade uso", resolved.resourceMax.channel_divinity, 1)

print("Sin stack = max, se sigue sumando (Furia, Chi, etc.)")
Aplicar({ kind = "resourceMax", resource = "chi", value = 2 })
Aplicar({ kind = "resourceMax", resource = "chi", value = 3 })
chk("dos fuentes suman", resolved.resourceMax.chi, 5)

print("Un maximo mayor si manda")
Aplicar({ kind = "resourceMax", resource = "channel_divinity", value = 3, stack = "max" })
chk("3 supera a 1", resolved.resourceMax.channel_divinity, 3)
Aplicar({ kind = "resourceMax", resource = "channel_divinity", value = 2, stack = "max" })
chk("2 no lo baja", resolved.resourceMax.channel_divinity, 3)

-- ── 2. Defensa sin Armadura, extraida de HarfordDnDCombat ──
local MODS = { Destreza = 3, Sabiduria = 4, Inteligencia = 2 }
local ABILIDADES = {}
HarfordDnDCalc = { GetAbilityMod = function(a) return MODS[a] or 0 end }
HarfordDnDFeatureEffects = { GetUnarmoredDefenseAbilities = function() return ABILIDADES end }
local src2 = io.open("Harford/DnD/Engine/HarfordDnDCombat.lua"):read("*a")
local a2 = assert(src2:find("local unarmored = 0"))
local b2 = assert(src2:find("return math.floor%(10 %+ dex %+ unarmored %+ bonus%)", a2))
local codigo2 = "local dex, bonus = ...\n" .. src2:sub(a2, b2 - 1) ..
    "\nreturn math.floor(10 + dex + unarmored + bonus)"
local env2 = { ipairs = ipairs, math = math,
    HarfordDnDCalc = HarfordDnDCalc, HarfordDnDFeatureEffects = HarfordDnDFeatureEffects }
local f2
if setfenv then f2 = assert(cargar(codigo2)); setfenv(f2, env2) else f2 = assert(cargar(codigo2, "ud", "t", env2)) end

print("Defensa sin Armadura")
ABILIDADES = {}
chk("sin ninguna: 10 + Des", f2(3, 0), 13)
ABILIDADES = { "Sabiduria" }
chk("Monje: 10 + Des + Sab", f2(3, 0), 17)
ABILIDADES = { "Sabiduria", "Inteligencia" }
chk("Monje/CdD: NO suma las dos, coge la mejor", f2(3, 0), 17)
ABILIDADES = { "Inteligencia", "Sabiduria" }
chk("el orden da igual", f2(3, 0), 17)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
