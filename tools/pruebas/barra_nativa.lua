-- Habilidades y conjuros en la barra de accion NATIVA (patron Arcanum): las fuentes de arrastre
-- existen, la carga distingue conjuro de habilidad, y las pasivas no viajan (serian botones
-- muertos). El click de barra reusa las MISMAS rutas que el Libro y el compendio.
local fallos = 0
local function chk(nombre, real, esperado)
    if real ~= esperado then
        fallos = fallos + 1
        print("  FALLO " .. nombre .. ": " .. tostring(real) .. " ~= " .. tostring(esperado))
    else
        print("  ok " .. nombre)
    end
end

local barras = io.open("Harford/DnD/UI/HarfordActionBars.lua"):read("*a")
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
local libro = io.open("Harford/Character/HarfordCharacterSpellbook.lua"):read("*a")

print("La carga distingue conjuro de habilidad")
chk("prefijo de conjuro en la carga", barras:find('"^conjuro:(.+)$"', 1, true) ~= nil, true)
chk("RecogerConjuro existe", barras:find("function API.RecogerConjuro(spellId)", 1, true) ~= nil, true)
chk("el click de conjuro lanza ResolveCast", barras:find("api.ResolveCast(spellId)", 1, true) ~= nil, true)
chk("el click de habilidad reusa el repartidor del Libro",
    barras:find("HarfordCharacterPanel.ActivarHabilidadPorId(id, self)", 1, true) ~= nil, true)

print("Las fuentes de arrastre estan enganchadas")
chk("el Libro arrastra habilidades", panel:find("HarfordActionBars.RecogerHabilidad(f.id)", 1, true) ~= nil, true)
chk("pero NO las pasivas", panel:find('Category(f) == "pasivo" then return end', 1, true) ~= nil, true)
chk("la pestana Conjuros arrastra conjuros", libro:find("HarfordActionBars.RecogerConjuro(self.spell.id)", 1, true) ~= nil, true)
chk("y soltar en el vacio limpia el cursor (diferido un tick)",
    libro:find("C_Timer.After(0, HarfordActionBars.SoltarHabilidad)", 1, true) ~= nil, true)

print("Convivencia con Blizzard y Arcanum")
chk("type propio, no secuestra el action", barras:find('local TIPO = "harford"', 1, true) ~= nil, true)
chk("si Blizzard pone un hechizo real encima, manda Blizzard",
    barras:find("API.LimpiarBoton(self)", 1, true) ~= nil, true)
chk("nada en combate", barras:find("function EnCombate()", 1, true) ~= nil, true)

print("La posesion (.poss) no borra lo colocado")
chk("hay deteccion de posesion/vehiculo", barras:find("local function EnPosesion()", 1, true) ~= nil, true)
chk("apartarse en posesion conserva la ranura",
    barras:find("API.LimpiarBoton(self, EnPosesion())", 1, true) ~= nil, true)
chk("la restauracion no pisa acciones reales",
    barras:find("if id and not accionReal and", 1, true) ~= nil, true)
chk("y los eventos de posesion restauran al salir",
    barras:find('ev:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")', 1, true) ~= nil
    and barras:find('ev:RegisterEvent("UNIT_EXITED_VEHICLE")', 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
