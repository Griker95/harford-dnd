-- Los iconos del About generado de TRP3 (2026-08-29). Dos regresiones que candar:
--
-- 1. La tabla de candidatos de icono POR CONJURO se PERDIO en el refactor de carpetas
--    (918a636): HarfordCompendioIconMap paso de 461 a 71 lineas delegando en
--    IconCatalog.GetSpellCandidates, pero NADIE llamaba a RegisterSpells y los candidatos
--    quedaron vacios. Sin nombre, el generador del About escribia el fileID numerico del
--    Compendio en {icon:...}, y TRP3 antepone Interface\ICONS\ al TEXTO tal cual
--    (Utils.getIconTexture), asi que "136234" salia como textura rota.
--
-- 2. El generador no validaba el nombre: un fileID, un "spell:<id>" o arte que este build
--    de Epsilon no tiene (tools/codice/_iconos_faltan_en_epsilon.md) acababa igual en el
--    markup. Ahora IconNameParaMarkup los rechaza y cae al icono por defecto.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local function cargarModulo(ruta, env)
    env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
    env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
    env.setmetatable, env.pcall = setmetatable, pcall
    local src = io.open(ruta):read("*a")
    local f
    if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
    pcall(f)
    return env
end

-- ═══ 1. LA TABLA DE CANDIDATOS SE REGISTRA AL CARGAR ════════════════════════
print("El mapa de iconos registra sus candidatos en el catalogo")
local registrados
local env = setmetatable({
    HarfordCompendioAPI = {},
    HarfordIconCatalog = { RegisterSpells = function(t) registrados = t end },
    _G = { HarfordCompendioAPI = {}, HarfordIconCatalog = false },
}, { __index = function() return nil end })
-- el modulo lee _G.HarfordCompendioAPI y _G.HarfordIconCatalog: el _G del sandbox debe
-- apuntar a las MISMAS tablas del env para que el registro llegue al stub.
env._G = env
cargarModulo("Harford/Compendium/HarfordCompendioIconMap.lua", env)
chk("RegisterSpells se llama al cargar", registrados ~= nil, true)
local total = 0
for _ in pairs(registrados or {}) do total = total + 1 end
chk("con la tabla completa (>300 conjuros)", total > 300, true)
local agarre = registrados and registrados.agarre_electrizante
chk("candidato preferente por NOMBRE (arte BG3)", agarre and agarre[1], "eps_bg3_shockingrasp")
local vida = registrados and registrados.vida_falsa
chk("la cadena de respaldo de vida_falsa sigue entera", vida and #vida >= 2, true)

-- ═══ 2. EL GENERADOR DEL ABOUT SOLO ESCRIBE NOMBRES VALIDOS ═════════════════
print("El About rechaza lo que TRP3 no sabe pintar")
local gen = io.open("Harford/Character/HarfordCharacterCreation.lua"):read("*a")
chk("existe el validador de nombre para el markup",
    gen:find("local function IconNameParaMarkup", 1, true) ~= nil, true)
chk("rechaza fileID numerico y spell:<id>",
    gen:find([[name:find("^spell:") or name:match("^%d+$")]], 1, true) ~= nil, true)
chk("en juego comprueba que el icono EXISTA en este build",
    gen:find([[GetFileIDFromPath and not GetFileIDFromPath("Interface\\Icons\\" .. name)]], 1, true) ~= nil, true)
chk("los rasgos pasan por el validador con respaldo",
    gen:find("IconNameParaMarkup(feature and feature.icon)", 1, true) ~= nil
    and gen:find("or ICON_TRAIT_DEFAULT", 1, true) ~= nil, true)
chk("los conjuros recorren los candidatos hasta uno valido",
    gen:find("for _, cand in ipairs(type(cands) == \"table\" and cands or {}) do", 1, true) ~= nil, true)
chk("y sin candidato caen al defecto, nunca a un numero",
    gen:find("icon = icon or IconNameParaMarkup(spell and spell.icon) or ICON_TRAIT_DEFAULT", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
