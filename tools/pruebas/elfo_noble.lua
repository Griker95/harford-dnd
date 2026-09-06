-- ELFO NOBLE (2026-09-06): el High Elf del Libro 2 ("Heroes of Warcraft 5º (Alt)", High Elf
-- Traits) entra como SUBRAZA del Elfo de Sangre, y con el la raza se reestructura: lo comun a
-- ambos linajes queda en la base (vision, Conocimiento Arcano, idiomas) y lo que ANTES era de
-- la raza base (incremento, sentidos, reversion, legado thalassiano) pasa a la subraza
-- sin'dorei CONSERVANDO sus ids — las elecciones guardadas (esa_legado) siguen resolviendo.
-- Las fichas sin subraza migran a sin'dorei en Progression.Migrate para no perder rasgos en
-- silencio.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cargar = loadstring or load
local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable, env.pcall = setmetatable, pcall
env._G = env
local function ejecutar(ruta)
    local f
    local src = io.open(ruta):read("*a")
    if setfenv then f = assert(cargar(src), ruta); setfenv(f, env)
    else f = assert(cargar(src, "t", "t", env), ruta) end
    pcall(f)
end
ejecutar("Harford/Core/HarfordClassColors.lua")
ejecutar("Harford/DnD/Data/HarfordDnDRaces.lua")

local R = env.HarfordDnDRaces
local sindorei = R.GetSubrace("raza_elfo_sangre", "raza_elfo_sangre_sindorei")
local noble = R.GetSubrace("raza_elfo_sangre", "raza_elfo_sangre_noble")

print("La raza tiene dos linajes y el sin'dorei es el default")
chk("sin'dorei existe", sindorei ~= nil, true)
chk("noble existe", noble ~= nil, true)
chk("el default es lo que la raza siempre fue",
    R.GetDefaultSubraceId("raza_elfo_sangre"), "raza_elfo_sangre_sindorei")
chk("con nombre femenino propio", noble.nameF, "Elfa Noble")

local function porId(sub)
    local out = {}
    for _, t in ipairs((sub and sub.traits) or {}) do out[t.id] = t end
    return out
end
local base = {}
for _, raza in ipairs(R.RACES) do
    if raza.id == "raza_elfo_sangre" then
        for _, t in ipairs(raza.traits or {}) do base[t.id] = t end
    end
end
local s, n = porId(sindorei), porId(noble)

print("Los ids viejos se CONSERVAN en el sin'dorei (elecciones guardadas)")
chk("esa_inc", s.esa_inc ~= nil, true)
chk("esa_sentidos", s.esa_sentidos ~= nil, true)
chk("esa_reversion", s.esa_reversion ~= nil, true)
chk("esa_legado con su choice", s.esa_legado and s.esa_legado.choice ~= nil, true)

print("Lo comun a ambos linajes queda en la base")
chk("vision", base.esa_vision ~= nil, true)
chk("Conocimiento Arcano con detectar magia", base.esa_arcano
    and base.esa_arcano.spellGrants ~= nil, true)
chk("idiomas", base.esa_idiomas ~= nil, true)
chk("y el incremento YA NO esta en la base", base.esa_inc, "nil")

print("El noble trae los rasgos del Libro 2")
chk("DES+2 SAB+1", n.eno_inc and n.eno_inc.effects[1].ability .. "+"
    .. n.eno_inc.effects[1].value .. "/" .. n.eno_inc.effects[2].ability .. "+"
    .. n.eno_inc.effects[2].value, "Destreza+2/Sabiduria+1")
-- La "hoja quel'dorei" del libro ES la "Espada quel'dorei" del catalogo: las tres armas
-- van mecanizadas, ninguna se queda en la prosa.
chk("Artes de los quel'dorei: las TRES armas",
    n.eno_artes and n.eno_artes.effects[1].weapon .. "/" .. n.eno_artes.effects[2].weapon
    .. "/" .. n.eno_artes.effects[3].weapon,
    "espada quel'dorei/arco largo/espada corta")
-- Herencia de Quel'Thalas: competencia TEMPORAL elegida en cada descanso largo. Reusa el
-- mecanismo de la Forja de runas (rechooseOnLongRest) y el generador nuevo weaponOrTool.
chk("Herencia: se reelige en cada descanso largo",
    n.eno_herencia and n.eno_herencia.choice.rechooseOnLongRest, true)
chk("entre TODAS las armas y herramientas",
    n.eno_herencia and n.eno_herencia.choice.optionsFrom, "weaponOrTool")
-- Legado de precision: usos = bonificador por competencia, mecanismo existente de FeatureUses
-- (uses.proficiencyBonus suma el PB al base).
chk("Precision: usos por bono de competencia",
    n.eno_precision and tostring(n.eno_precision.uses.base) .. "/"
    .. tostring(n.eno_precision.uses.proficiencyBonus) .. "/" .. n.eno_precision.uses.recharge,
    "0/true/long")
chk("y es rasgo activable (anuncia y gasta)", n.eno_precision.type, "activo")
chk("idioma adicional a elegir", n.eno_idioma and n.eno_idioma.choice.optionsFrom, "language")

print("Los buscadores resuelven el linaje, en ambos generos")
chk("subraza por texto femenino", R.FindSubraceIdByText("raza_elfo_sangre", "Elfa Noble"),
    "raza_elfo_sangre_noble")
chk("subraza por texto masculino", R.FindSubraceIdByText("raza_elfo_sangre", "elfo noble"),
    "raza_elfo_sangre_noble")
chk("la raza por texto sigue cayendo al Elfo de Sangre",
    R.FindRaceIdByText("Elfa noble"), "raza_elfo_sangre")
chk("la cabecera sin'dorei de un About viejo tambien resuelve",
    R.FindSubraceIdByText("raza_elfo_sangre", "Elfa de Sangre"), "raza_elfo_sangre_sindorei")

-- weaponOrTool: generador de opciones del Libro (armas del catalogo + TODAS las herramientas).
print("El generador weaponOrTool y la migracion existen")
local book = io.open("Harford/DnD/Data/HarfordDnDBook.lua"):read("*a")
chk("weaponOrTool comparte la rama de armas",
    book:find('(from == "weaponProf" or from == "weaponOrTool")', 1, true) ~= nil, true)
chk("y suma las herramientas",
    book:find('if from == "weaponOrTool" and HarfordDnDData and HarfordDnDData.TOOLS then', 1, true) ~= nil, true)
-- Una ficha de elfo de sangre ANTERIOR a las subrazas no tiene subraceId: sin migrar perderia
-- incremento/sentidos/reversion/legado en silencio. Corre en cada carga, idempotente, con aviso.
local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("la ficha vieja migra a sin'dorei",
    prog:find('data.race.subraceId = "raza_elfo_sangre_sindorei"', 1, true) ~= nil
    and prog:find('and (data.race.subraceId == "" or data.race.subraceId == "raza_elfo_sangre") then', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
