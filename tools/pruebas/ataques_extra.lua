-- Rasgos que conceden ATAQUES de verdad (Punos de Furia: dos golpes desarmados).
--
-- Se disparan por la ruta normal de ataque de arma para que traigan consigo lo que esa ruta ya sabe
-- hacer -- CA del objetivo, criticos, Artes Marciales subiendo el dado del desarmado, mitigacion
-- del defensor y animacion -- en vez de reimplementarlo en el rasgo.
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
local monje = io.open("Harford/DnD/Data/Classes/Monje.lua"):read("*a")

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-8s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

print("Usa la ruta normal de ataque, no una propia")
chk("dispara ataques reales", panel:find("HarfordDnDStore.AttackWithBlock(def,", 1, true) ~= nil, true)
chk("con el arma que declare el rasgo",
    panel:find('HarfordDnDStore.GetWeaponDef(spec.weaponKey or "Desarmado")', 1, true) ~= nil, true)

-- `AttackWithBlock` suprime el modificador por defecto (es para ataques de bloque y acompanantes).
-- Un golpe desarmado del Monje SI lo suma: dejarlo por defecto le quitaria su Destreza a cada
-- golpe, y eso no daria ningun error.
print("El modificador de caracteristica SI cuenta en un golpe desarmado")
chk("se pide explicitamente", panel:find("suppressAbilityDamage = false", 1, true) ~= nil, true)

print("Exige objetivo y cobra antes de pegar")
chk("pide objetivo", panel:find('necesita un objetivo."', 1, true) ~= nil, true)
chk("cobra el recurso", panel:find("local ok, err = SpendPowerWord(feature)", 1, true) ~= nil, true)

print("Punos de Furia declara sus dos golpes")
chk("dos", monje:find('extraAttacks = { count = 2, weaponKey = "Desarmado" }', 1, true) ~= nil, true)
chk("como accion adicional", monje:find('name = "Punos de Furia", cast = "accion_adicional"', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
