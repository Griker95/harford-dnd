-- Migracion de HERRAMIENTAS y PROFESIONES en datos de jugador.
--
-- Guardan en sitios distintos y de formas distintas, asi que necesitan dos migraciones:
--   - Una PROFESION es una CLAVE en `HarfordProfessionsStore.skills` (["herreria"] = 50). Ese
--     almacen es per-character y no pasa por la migracion de la progresion.
--   - Una HERRAMIENTA viaja como VALOR: la opcion elegida en una eleccion de competencia
--     (`choices["bg_des_herr"] = { "instrumento" }`).
-- Ademas OCHO ids existian en los dos espacios (`ladron`, `instrumento`, `disfraz`...), asi que
-- traducirlos por su nombre suelto habria sido ambiguo.
local cargar = loadstring or load
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ── Herramientas: valores dentro de las elecciones ──
local src = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
local i = assert(src:find("local HERRAMIENTAS_RENOMBRADAS"), "no encuentro la tabla")
local fin = assert(src:find("\nend", src:find("local function RenombrarOpciones", i)))
local env = { type = type, pairs = pairs }
local f
local codigo = src:sub(i, fin + 4) .. "\nreturn HERRAMIENTAS_RENOMBRADAS, RenombrarOpciones"
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "h", "t", env)) end
local TABLA_H, RenombrarOpciones = f()

print("Herramientas: la eleccion guardada sobrevive")
chk("instrumento -> her_instrumento", TABLA_H["instrumento"], "her_instrumento")
local choices = { bg_des_herr = { "instrumento" }, pic_pericia = { "sigilo" } }
local n = RenombrarOpciones(choices)
chk("traduce 1 valor", n, 1)
chk("la eleccion apunta al id nuevo", choices.bg_des_herr[1], "her_instrumento")
chk("lo que no es herramienta se queda", choices.pic_pericia[1], "sigilo")
chk("nil no revienta", RenombrarOpciones(nil), 0)

-- ── Profesiones: claves en su propio almacen ──
local src2 = io.open("Harford/Professions/HarfordProfessions.lua"):read("*a")
local a = assert(src2:find("local PROFESIONES_RENOMBRADAS"), "no encuentro la tabla")
local b = assert(src2:find("\nend", src2:find("local function MigrarIds", a)))
local env2 = { type = type, pairs = pairs }
local f2
local c2 = src2:sub(a, b + 4) .. "\nreturn PROFESIONES_RENOMBRADAS, MigrarIds"
if setfenv then f2 = assert(cargar(c2)); setfenv(f2, env2) else f2 = assert(cargar(c2, "p", "t", env2)) end
local TABLA_P, MigrarIds = f2()

print("Profesiones: el nivel sobrevive")
chk("herreria -> prof_herreria", TABLA_P["herreria"], "prof_herreria")
local store = { skills = { herreria = 50, ladron = 1, algo_raro = 7 } }
local n2 = MigrarIds(store)
chk("traduce 2 claves", n2, 2)
chk("el nivel de herreria se conserva", store.skills.prof_herreria, 50)
chk("  y el de ladron", store.skills.prof_ladron, 1)
chk("la clave vieja desaparece", tostring(store.skills.herreria), "nil")
chk("lo desconocido se respeta", store.skills.algo_raro, 7)
chk("sin skills no revienta", MigrarIds({}), 0)

print("Los ocho ambiguos van cada uno a su espacio")
for _, id in ipairs({ "ladron", "instrumento", "disfraz", "falsificacion" }) do
    chk("  " .. id .. " tiene destino de herramienta", TABLA_H[id], "her_" .. id)
    chk("  " .. id .. " tiene destino de profesion", TABLA_P[id], "prof_" .. id)
end
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
