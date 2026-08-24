-- Rasgos de eleccion cuyas OPCIONES ELEGIDAS se vuelven habilidades propias del Libro.
--
-- El motor existia solo para Palabra de Poder (`actionKind == "powerWord"`), aunque no tenia nada
-- especifico del Sacerdote: usa campos genericos. Ahora acepta tambien `optionAbility`, que es lo
-- que usan brebajes del Monje, ataques del Chaman, trampas del Cazador y maldiciones del Brujo.
--
-- Lo critico es que la habilidad sintetizada arrastre `cast` y el coste: son lo que miran la
-- economia de turno y el gasto de recurso. Sin ellos la opcion se usaria GRATIS.
local cargar = loadstring or load
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-14s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- IsOptionAbility, del modulo real
local src = io.open("Harford/Character/HarfordCharacterBook.lua"):read("*a")
local i = assert(src:find("function API.IsOptionAbility"))
local j = assert(src:find("\nend", i))
local API = {}
local env = { API = API, type = type }
local f
local codigo = src:sub(i, j + 4) .. "\nreturn API.IsOptionAbility"
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "b", "t", env)) end
local EsOpcion = f()

print("Que rasgos convierten sus opciones en habilidades")
chk("Palabra de Poder (el original)", EsOpcion({ actionKind = "powerWord" }), true)
chk("marcador generico", EsOpcion({ actionKind = "optionAbility" }), true)
chk("un rasgo normal no", EsOpcion({ actionKind = "huntersMark" }), false)
chk("sin actionKind tampoco", EsOpcion({}), false)
chk("nil no revienta", EsOpcion(nil), false)

print("Los cuatro rasgos estan marcados en los datos")
local ESPERADOS = {
    { "Monje",   "monje_cer_brebajes"  },
    { "Chaman",  "cha_mej_ataques_3"   },
    { "Cazador", "caz_sup_trampero"    },
    { "Brujo",   "bru_afl_maldiciones" },
}
for _, e in ipairs(ESPERADOS) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. e[1] .. ".lua")
    local s = fh:read("*a"); fh:close()
    local reg = s:match('{ id = "' .. e[2] .. '"[^\n]*')
    chk("  " .. e[2], reg and reg:find('actionKind = "optionAbility"', 1, true) ~= nil, true)
    chk("    y oculta el contenedor", reg and reg:find("bookHidden = true", 1, true) ~= nil, true)
end

print("Sus opciones declaran el coste, que es lo que se cobra")
local CASOS = {
    { "Monje",   "fortificante", "chi"       },
    { "Chaman",  "golpe_roca",   "maelstrom" },
}
for _, c in ipairs(CASOS) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. c[1] .. ".lua")
    local s = fh:read("*a"); fh:close()
    local reg = s:match('{ id = "' .. c[2] .. '"[^\n]*')
    chk("  " .. c[2] .. " gasta " .. c[3], reg and reg:match('resourceKey = "([a-z_]+)"'), c[3])
end
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
