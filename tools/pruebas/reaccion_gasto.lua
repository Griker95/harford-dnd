-- La reaccion se gasta al USARLA. El cobro vive en un punto unico (`BroadcastAbility` ->
-- `SpendForFeature`) que mira el campo `cast` del rasgo. El agujero estaba en los rasgos
-- SINTETIZADOS: `PowerWordDisplayFeature` arma una tabla para anunciar la opcion elegida y no
-- arrastraba `cast`, asi que una reaccion de Palabra de Poder disparaba GRATIS.
local cargar = loadstring or load

-- 1. La economia real, extraida de HarfordDnDConditions.
local src = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local i = assert(src:find("local ECONOMIA"))
-- Retroceder a la ultima linea que sea exactamente `do`: es la que abre el bloque.
-- Buscarla por proximidad de texto no vale: los comentarios de por medio cambian.
i = assert(src:sub(1, i):match(".*()\ndo\n"))
local fin = assert(src:find("    API.Turn = Turn\nend", i))
HarfordTurnOrderStore = { entries = { { kind = "npc", name = "Gnoll" } } }
HarfordTurnOrderAPI = { HasActiveCombat = function()
    for _, e in ipairs(HarfordTurnOrderStore.entries) do
        if e.kind ~= "round" then return true end
    end
    return false
end }
HarfordDnDFeatureEffects = { HasFlag = function() return false end }
local API = {}
local env = { API = API, math = math, string = string, table = table, ipairs = ipairs,
    tonumber = tonumber, tostring = tostring, type = type, Notify = function() end,
    Print = function() end, HarfordTurnOrderStore = HarfordTurnOrderStore,
    HarfordTurnOrderAPI = HarfordTurnOrderAPI, HarfordDnDFeatureEffects = HarfordDnDFeatureEffects }
local f = src:sub(i, fin + #"    API.Turn = Turn\nend")
local chunk
if setfenv then chunk = assert(cargar(f)); setfenv(chunk, env) else chunk = assert(cargar(f, "eco", "t", env)) end
chunk()
local T = API.Turn

-- 2. El sintetizador real, extraido de HarfordCharacterPanel.
local src2 = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
local a = assert(src2:find("local function PowerWordDisplayFeature"))
local b = assert(src2:find("\nend", a))
local env2 = { tostring = tostring }
local c2 = src2:sub(a, b + 4) .. "\nreturn PowerWordDisplayFeature"
local chunk2
if setfenv then chunk2 = assert(cargar(c2)); setfenv(chunk2, env2) else chunk2 = assert(cargar(c2, "pw", "t", env2)) end
local Sintetizar = chunk2()

local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-10s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("Un rasgo de reaccion normal gasta la reaccion")
T.Reset()
chk("antes queda 1", T.GetRemaining("reaction"), 1)
T.SpendForFeature({ id = "pic_esquiva", name = "Esquiva sobrenatural", cast = "reaccion" })
chk("despues queda 0", T.GetRemaining("reaction"), 0)
chk("la accion no se toco", T.GetRemaining("action"), 1)

print("El rasgo SINTETIZADO de una opcion tambien (era el agujero)")
T.Reset()
local padre = { id = "sac_palabra_poder", description = "Palabra de poder", cast = "accion" }
local opcion = { id = "escudo", label = "Palabra de poder: Escudo", cast = "reaccion" }
local display = Sintetizar(padre, opcion)
chk("el sintetizado conserva cast", display.cast, "reaccion")
chk("y manda la OPCION, no el padre", T.KindFromFeature(display), "reaction")
T.SpendForFeature(display)
chk("gasta la reaccion", T.GetRemaining("reaction"), 0)
chk("y NO la accion del padre", T.GetRemaining("action"), 1)

print("Sin cast en ninguno de los dos, no se cobra nada")
T.Reset()
local d2 = Sintetizar({ id = "x", description = "" }, { id = "y", label = "Y" })
chk("no se adivina el coste", T.KindFromFeature(d2), "nil")
chk("la reaccion sigue entera", T.GetRemaining("reaction"), 1)

print("Hereda del padre si la opcion no lo declara")
local d3 = Sintetizar({ id = "z", description = "", cast = "reaccion" }, { id = "w", label = "W" })
chk("cast heredado", d3.cast, "reaccion")

print("Rasgos que CONCEDEN presupuesto en vez de gastarlo")
T.Reset()
chk("adicional de partida", T.GetRemaining("bonus"), 1)
T.GrantForFeature({ id = "guerrero_accion_adicional", name = "Accion adicional",
                    grantsTurnAction = "accion_adicional" })
chk("tras usar el rasgo del Guerrero: dos", T.GetRemaining("bonus"), 2)
chk("  la accion normal no sube", T.GetRemaining("action"), 1)
T.SpendForFeature({ id = "x", cast = "accion_adicional" })
chk("gasto una: queda una", T.GetRemaining("bonus"), 1)
T.Reset()
chk("al empezar el turno, la concedida SE VA", T.GetRemaining("bonus"), 1)
chk("un rasgo sin grantsTurnAction no concede",
    tostring(T.GrantForFeature({ id = "y", cast = "accion" })), "nil")
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
