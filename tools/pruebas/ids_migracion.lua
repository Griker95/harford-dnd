-- Migracion de ids de rasgo en datos de jugador.
--
-- El estado se guarda POR ID: `choices`, `featureStates`, `featureUses`, `activeStates`. Al aplicar
-- la convencion <abrevClase>_<abrevSub>_<cosa>, un personaje perderia su eleccion de Estilo de
-- combate, su brebaje o sus usos por descanso si nadie tradujera esas claves.
--
-- Se extrae la tabla y la funcion REALES de HarfordDnDProgression.
local cargar = loadstring or load
local src = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
local i = assert(src:find("local IDS_RENOMBRADOS"), "no encuentro la tabla")
local fin = assert(src:find("\nend", src:find("local function RenombrarClaves", i)))
local codigo = src:sub(i, fin + 4) .. "\nreturn IDS_RENOMBRADOS, RenombrarClaves"
local env = { type = type, pairs = pairs }
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "mig", "t", env)) end
local TABLA, Renombrar = f()

local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
local function cuenta(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

print("La tabla cubre los dos pases")
chk("hay entradas", cuenta(TABLA) > 100, true)
chk("pase 1: afliccion_drenar_alma", TABLA["afliccion_drenar_alma"], "bru_afl_drenar_alma")
chk("pase 2: guerrero_estilo_combate", TABLA["guerrero_estilo_combate"], "gue_estilo_combate")
chk("pase 2: cdm_comando_oscuro", TABLA["cdm_comando_oscuro"], "cdm_san_comando_oscuro")

print("El caso real: el unico id guardado en datos de jugador")
local choices = { guerrero_estilo_combate = { "defensa" }, pic_pericia = { "sigilo", "engano" } }
local nuevo, n = Renombrar(choices)
chk("traduce 1 clave", n, 1)
chk("la eleccion sobrevive", nuevo.gue_estilo_combate and nuevo.gue_estilo_combate[1], "defensa")
chk("el id viejo desaparece", tostring(nuevo.guerrero_estilo_combate), "nil")
chk("lo que no cambia se queda", nuevo.pic_pericia and nuevo.pic_pericia[2], "engano")

print("Casos limite")
local vacio, n2 = Renombrar({})
chk("tabla vacia", cuenta(vacio) .. "/" .. n2, "0/0")
local sinCambios, n3 = Renombrar({ sac_pp_barrera = true })
chk("nada que renombrar", n3, 0)
chk("  y conserva la clave", tostring(sinCambios.sac_pp_barrera), "true")
chk("nil no revienta", tostring(Renombrar(nil)), "nil")

print("Usos y estados, no solo elecciones")
local usos, n4 = Renombrar({ ["cazador_demo_preparado"] = 1, ["monje_cer_breb_agil"] = 2 })
chk("traduce el que cambia", n4, 1)
chk("  al nombre nuevo", usos.dh_preparado, 1)
chk("  y respeta el de runtime", usos.monje_cer_breb_agil, 2)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
