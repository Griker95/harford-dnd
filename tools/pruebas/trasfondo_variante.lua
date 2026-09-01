-- Variantes de trasfondo con RASGOS propios (2026-09-01). El esquema: una variante puede
-- declarar `traits` que SUSTITUYEN por completo a los del base; sin traits es narrativa y
-- deja los del base, como siempre. Nacio del Mercenario veterano, que llevaba en el BASE
-- todo el contenido de su variante Veterano Harford (aviso del chat del codice, con el
-- texto original de Griker): competencias que se concedian de verdad al crear personaje.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-10s %s", etiqueta, tostring(real),
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

local env = setmetatable({}, { __index = function() return nil end })
cargarModulo("Harford/DnD/Data/HarfordDnDBackgrounds.lua", env)
local B = env.HarfordDnDBackgrounds

print("El base del Mercenario veterano vuelve a ser el original")
local base = B.ResolveTraits("mercenario_veterano_harford", nil)
chk("cuatro rasgos", #base, 4)
local nombres = {}
for _, tr in ipairs(base) do nombres[tr.name] = tr end
chk("competencias FIJAS (no eleccion)", nombres["Competencias"] and nombres["Competencias"].type, "pasivo")
chk("sin competencia con armas", nombres["Competencia con armas"], "nil")
chk("con Vida mercenaria", nombres["Vida mercenaria"] ~= nil, true)
chk("sin Espiritu Harford en el base", nombres["Espiritu Harford"], "nil")
chk("oro del base: 10 po", B.GetStartingGold("mercenario_veterano_harford"), 10)

print("La variante Veterano Harford lleva lo suyo")
local vid = "mercenario_veterano_harford_veterano_harford"
local vtraits = B.ResolveTraits("mercenario_veterano_harford", vid)
chk("seis rasgos", #vtraits, 6)
local vn = {}
for _, tr in ipairs(vtraits) do vn[tr.id] = tr end
chk("eleccion de habilidad conserva su id", vn.bg_merc_hab and vn.bg_merc_hab.type, "choice")
chk("armas marciales", vn.bg_merc_armas ~= nil, true)
chk("herramienta adicional conserva su id", vn.bg_merc_herr and vn.bg_merc_herr.type, "choice")
chk("Espiritu Harford", vn.bg_merc_espiritu ~= nil, true)
chk("oro de la variante: 8 po", B.GetStartingGold("mercenario_veterano_harford", vid), 8)
chk("GetTrait encuentra rasgos de variante", (B.GetTrait("bg_merc_espiritu")) ~= nil, true)

print("Una variante narrativa deja los rasgos del base")
local esp = B.ResolveTraits("criminal", "criminal_espia")
local basecrim = B.ResolveTraits("criminal", nil)
chk("mismos rasgos", #esp, #basecrim)

print("Ningun rasgo se llama ya 'Caracteristica: ...'")
local conPrefijo = 0
for _, bg in ipairs(B.BACKGROUNDS or {}) do
    for _, tr in ipairs(bg.traits or {}) do
        if tostring(tr.name or ""):find("^Caracteristica") then conPrefijo = conPrefijo + 1 end
    end
end
chk("cero prefijos", conPrefijo, 0)

print("Los consumidores pasan la variante")
for etiqueta, ruta, frag in (function(l) local i = 0; return function()
    i = i + 3; return l[i-2], l[i-1], l[i] end end){
    "book", "Harford/Character/HarfordCharacterBook.lua", "GetBackgroundTraits(data.background, data.backgroundVariant)",
    "progresion", "Harford/DnD/State/HarfordDnDProgression.lua", "GetBackgroundTraits(data.background, data.backgroundVariant)",
    "creacion", "Harford/Character/HarfordCharacterCreation.lua", "ResolveTraits(draft.backgroundId, draft.backgroundVariantId)",
    "borrador", "Harford/Character/HarfordCharacterDraft.lua", "ResolveTraits(S.backgroundId, S.backgroundVariantId)",
    "asistente", "Harford/Character/HarfordCharacterAdvancement.lua", "ResolveTraits(S.backgroundId, S.backgroundVariantId)",
    "economia", "Harford/DnD/State/HarfordDnDEconomy.lua", "GetStartingGold(bgDef.id, draft.backgroundVariantId)",
} do
    local src = io.open(ruta):read("*a")
    chk("variante en " .. etiqueta, src:find(frag, 1, true) ~= nil, true)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
