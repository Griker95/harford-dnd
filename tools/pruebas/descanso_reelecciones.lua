-- MENU DE DESCANSO LARGO: un solo desplegable con todo lo que el manual deja cambiar al
-- terminarlo — preparar conjuros (una entrada POR CADA clase preparadora: una multiclase puede
-- preparar por dos) y los rasgos `choice` con `rechooseOnLongRest` (Forja de runas del CdM).
-- Antes se encadenaban dos menus sueltos y el de preparados solo ofrecia la PRIMERA clase
-- preparadora que encontraba; sin este flujo, la runa del nivel 6 quedaba clavada para siempre.

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
chk("el descanso largo abre el menu UNIFICADO (silencioso)",
    rest:find("_G.HarfordOpenLongRestMenu(true)", 1, true) ~= nil, true)
chk("y ya no encadena dos menus sueltos",
    rest:find("HarfordOpenPrepareSpellsMenu(true)", 1, true), nil)

print("El menu es generico y declarativo")
chk("filtra por el flag, no por id",
    adv:find("f.choice and f.rechooseOnLongRest", 1, true) ~= nil, true)
chk("reescribe la eleccion de UN slot",
    adv:find("P.SetChoiceSlot(f.id, 1, elegida.id)", 1, true) ~= nil, true)
chk("expone el global que consume el descanso",
    adv:find("_G.HarfordOpenLongRestMenu = OpenLongRestMenu", 1, true) ~= nil, true)
chk("y el nombre historico sigue abriendo lo mismo (compat)",
    adv:find("_G.HarfordOpenLongRestChoicesMenu = OpenLongRestMenu", 1, true) ~= nil, true)

print("Preparar conjuros: todas las clases preparadoras, no solo la primera")
chk("hay recolector de preparadoras",
    adv:find("local function PreparedCasters()", 1, true) ~= nil, true)
chk("el menu lista una entrada por clase",
    adv:find('"Preparar conjuros (" .. tostring(caster.className) .. ")"', 1, true) ~= nil, true)
chk("y el picker abre por clase concreta",
    adv:find("local function OpenPrepareDialogFor(caster)", 1, true) ~= nil, true)
-- El About solo se regenera si el guardia lo reconoce como del generador: nunca a ciegas.
chk("About por la via guardada",
    adv:find("Cre%.CanRewriteAbout%(%)%s+and Cre%.RewriteAbout") ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
