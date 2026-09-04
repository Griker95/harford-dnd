-- REELECCIONES DE DESCANSO LARGO: rasgos `choice` con `rechooseOnLongRest` (Forja de runas
-- del CdM). El manual permite reinscribir la runa al terminar cada descanso largo; sin este
-- flujo, la eleccion del nivel 6 quedaba clavada para siempre (el unico editor de elecciones
-- vive en la pagina "Subida" legacy, oculta de la navegacion).

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local cdm = io.open("Harford/DnD/Data/Classes/CaballerodelaMuerte.lua"):read("*a")
local rest = io.open("Harford/DnD/UI/HarfordDnDRest.lua"):read("*a")
local adv = io.open("Harford/Character/HarfordCharacterAdvancement.lua"):read("*a")

print("La Forja de runas se reelige en el descanso largo")
chk("el rasgo declara el flag",
    cdm:find('id = "cdm_forja_runas".-rechooseOnLongRest = true') ~= nil, true)
chk("el descanso largo abre el menu (silencioso)",
    rest:find("_G.HarfordOpenLongRestChoicesMenu(true)", 1, true) ~= nil, true)

print("El menu es generico y declarativo")
chk("filtra por el flag, no por id",
    adv:find("f.choice and f.rechooseOnLongRest", 1, true) ~= nil, true)
chk("reescribe la eleccion de UN slot",
    adv:find("P.SetChoiceSlot(f.id, 1, elegida.id)", 1, true) ~= nil, true)
chk("expone el global que consume el descanso",
    adv:find("_G.HarfordOpenLongRestChoicesMenu = OpenLongRestChoicesMenu", 1, true) ~= nil, true)
-- El About solo se regenera si el guardia lo reconoce como del generador: nunca a ciegas.
chk("About por la via guardada",
    adv:find("Cre%.CanRewriteAbout%(%)%s+and Cre%.RewriteAbout") ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
