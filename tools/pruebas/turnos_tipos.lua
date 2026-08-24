-- Tipos de entrada del tracker. `AddUnit` hacia `kind or unit`, asi que el tipo acababa siendo el
-- token de unidad ("target", "focus", "nameplate3") segun desde donde se anadiera. Catalogo cerrado
-- de cinco tipos; todo lo demas se normaliza a "npc", tambien al recibir por red.
local cargar = loadstring or load
local src = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
local i = assert(src:find("local ENTRY_KINDS"))
local j = assert(src:find("\nend", i))
local codigo = src:sub(i, j + 4) .. "\nreturn NormalizeKind"
local env = { tostring = tostring }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "t", "t", env)) end
local N = f()
local fallos = 0
local function chk(entrada, esp)
    local real = N(entrada)
    local ok = real == esp
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-24s -> %-10s %s", tostring(entrada), real, ok and "ok" or ("FALLA, esperaba " .. esp)))
end
print("Normalizacion de tipo de entrada")
for _, k in ipairs({"round","generic","players","player","npc"}) do chk(k, k) end
print("  -- los que se colaban antes:")
chk("target", "npc")
chk("focus", "npc")
chk("mouseover", "npc")
chk("nameplate3", "npc")
chk(nil, "npc")
chk("", "npc")
chk("PLAYER", "npc")
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
