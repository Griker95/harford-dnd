-- Fichas de economia de turno de la barra de accion (estilo BG3): una ficha por PUNTO disponible,
-- no una por tipo. Impetu de Accion da una accion extra, y eso tiene que verse como dos fichas
-- doradas, no como un "2" escondido. Se comprueba tambien que fuera de combate no se pinta nada.
local cargar = loadstring or load

-- Stubs minimos de frame: solo lo que toca RefreshTurnEconomy.
local function NuevoFrame()
    local f = { puntos = {}, visible = false }
    function f:SetSize() end
    function f:SetPoint() end
    function f:ClearAllPoints() end
    function f:EnableMouse() end
    function f:SetScript() end
    function f:Show() self.visible = true end
    function f:Hide() self.visible = false end
    function f:CreateTexture()
        local t = {}
        function t:SetPoint() end
        function t:SetAllPoints() end
        function t:SetTexture() end
        function t:SetColorTexture(r,g,b) self.r, self.g, self.b = r, g, b end
        function t:SetVertexColor() end
        return t
    end
    return f
end
CreateFrame = function() return NuevoFrame() end
GameTooltip = nil

local GASTADO, PRESUPUESTO = {}, { action = 1, bonus = 1, reaction = 1 }
local ACTIVO = true
HarfordDnDConditions = { Turn = {
    ORDEN = { "action", "bonus", "reaction" },
    ETIQUETA = { action = "Accion", bonus = "Adicional", reaction = "Reaccion" },
    IsActive = function() return ACTIVO end,
    GetBudget = function(k) return PRESUPUESTO[k] or 0 end,
    GetRemaining = function(k) return math.max(0, (PRESUPUESTO[k] or 0) - (GASTADO[k] or 0)) end,
} }
HarfordActionBars = { _cfg = { capW = 70 } }
local bar = NuevoFrame()
bar.fichas = {}

local src = io.open("Harford/DnD/UI/HarfordActionBars.lua"):read("*a")
local i = assert(src:find("local FICHA_TAM"))
local j = assert(src:find("\nend", src:find("function API.RefreshTurnEconomy")))
local env = {
    API = HarfordActionBars, bar = bar, CreateFrame = CreateFrame,
    HarfordDnDConditions = HarfordDnDConditions, HarfordActionBars = HarfordActionBars,
    ipairs = ipairs, math = math, GameTooltip = nil,
}
local f
local codigo = src:sub(i, j + 4)
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "fichas", "t", env)) end
f()
local Refresh = HarfordActionBars.RefreshTurnEconomy

local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
local function encendidas()
    local n = 0
    for _, f in ipairs(bar.fichas) do
        if f.visible and not f.gastada then n = n + 1 end
    end
    return n
end

print("Presupuesto normal: una ficha por tipo")
GASTADO, ACTIVO = {}, true
chk("tres fichas", Refresh(), 3)
chk("las tres encendidas", encendidas(), 3)

print("Al gastar, la ficha se apaga")
GASTADO.action = 1
Refresh()
chk("quedan dos encendidas", encendidas(), 2)
chk("la de accion esta gastada", bar.fichas[1].gastada, true)
chk("la adicional no", bar.fichas[2].gastada, false)

print("Impetu de Accion: dos fichas doradas, no un contador")
GASTADO, PRESUPUESTO = {}, { action = 2, bonus = 1, reaction = 1 }
chk("cuatro fichas en total", Refresh(), 4)
chk("las cuatro encendidas", encendidas(), 4)
GASTADO.action = 1
Refresh()
chk("gastada una: la segunda accion sigue", encendidas(), 3)
-- Las que QUEDAN se leen de izquierda a derecha: con 1 de 2, se enciende la primera y se apaga
-- la segunda. Es la convencion de cualquier fila de cargas, y se lee "me queda una".
chk("  la primera sigue encendida", bar.fichas[1].gastada, false)
chk("  la segunda apagada", bar.fichas[2].gastada, true)

print("Fuera de combate no se pinta nada")
ACTIVO = false
chk("cero fichas", Refresh(), 0)
chk("ninguna visible", (function() for _,f in ipairs(bar.fichas) do if f.visible then return false end end return true end)(), true)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
