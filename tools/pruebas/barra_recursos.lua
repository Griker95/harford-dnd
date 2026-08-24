-- Recursos sobre la barra NATIVA, estilo BG3: fichas de accion y orbes de espacios de conjuro.
--
-- Dos reglas que los separan y conviene no confundir:
--   - Las FICHAS de accion solo existen con combate activo: fuera de combate no se lleva la cuenta.
--   - Los ORBES de conjuro se ven SIEMPRE: no se renuevan por turno y saber cuantos quedan importa
--     tambien fuera de combate.
-- Y una diferencia con BG3 que impone el motor: los espacios de PACTO del brujo se suman a los
-- normales de su nivel, no van en reserva aparte.
local cargar = loadstring or load

local function NuevoFrame(nombre)
    local f = { nombre = nombre, visible = false }
    for _, m in ipairs({"SetSize","SetWidth","SetPoint","ClearAllPoints","EnableMouse","SetScript",
                        "RegisterEvent","SetFrameStrata","SetText"}) do f[m] = function() end end
    function f:GetObjectType() return "Frame" end
    function f:IsShown() return self.visible end
    function f:Show() self.visible = true end
    function f:Hide() self.visible = false end
    function f:CreateTexture()
        local t = {}
        function t:SetPoint() end function t:SetAllPoints() end function t:SetTexture() end
        function t:SetColorTexture() end function t:SetVertexColor() end
        return t
    end
    function f:CreateFontString()
        local t = { }
        function t:SetText(v) self.texto = v end
        function t:SetPoint() end function t:ClearAllPoints() end
        function t:Show() self.visible = true end function t:Hide() self.visible = false end
        return t
    end
    return f
end
CreateFrame = function() return NuevoFrame() end
UIParent = NuevoFrame("UIParent")
GameTooltip = nil
local BOTON = NuevoFrame("ActionButton1"); BOTON.visible = true
_G = { ActionButton1 = BOTON }

local ACTIVO = true
local GASTADO, PRESUPUESTO = {}, { action = 1, bonus = 1, reaction = 1 }
HarfordDnDConditions = { Turn = {
    ORDEN = { "action", "bonus", "reaction" },
    ETIQUETA = { action = "Accion", bonus = "Adicional", reaction = "Reaccion" },
    IsActive = function() return ACTIVO end,
    GetBudget = function(k) return PRESUPUESTO[k] or 0 end,
    GetRemaining = function(k) return math.max(0, (PRESUPUESTO[k] or 0) - (GASTADO[k] or 0)) end,
} }
local MODO_MANA, PIRAMIDE = false, {}
HarfordDnDMana = {
    IsEnabled = function() return MODO_MANA end,
    GetMaxSpellLevel = function()
        local m = 0
        for n in pairs(PIRAMIDE) do if n > m then m = n end end
        return m
    end,
    GetSpellSlotCurrent = function(n)
        local e = PIRAMIDE[n]
        if not e then return 0, 0 end
        return math.max(0, e.total - (e.gastados or 0)), e.total
    end,
}
local API = {}
local src = io.open("Harford/DnD/UI/HarfordActionBars.lua"):read("*a")
local i = assert(src:find("local function AnclaBarraNativa"))
local j = assert(src:find("\nend", src:find("function API.RefreshTurnEconomy")))
local env = { API = API, CreateFrame = CreateFrame, UIParent = UIParent, _G = _G, pairs = pairs,
    HarfordDnDConditions = HarfordDnDConditions, HarfordDnDMana = HarfordDnDMana,
    ipairs = ipairs, math = math, tostring = tostring, GameTooltip = nil }
local codigo = src:sub(i, j + 4)
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "rec", "t", env)) end
f()
local R = API.RefreshTurnEconomy

local fallos = 0
local function chk(n, a, b, ea, eb)
    local ok = tostring(a) == tostring(ea) and tostring(b) == tostring(eb)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %s fichas, %s orbes   %s", n, tostring(a), tostring(b),
        ok and "ok" or ("FALLA, esperaba " .. tostring(ea) .. "/" .. tostring(eb))))
end

print("Solo combate, sin conjuros")
MODO_MANA, PIRAMIDE, ACTIVO, GASTADO = false, {}, true, {}
local a, b = R(); chk("tres fichas, ningun orbe", a, b, 3, 0)

print("Lanzador con piramide")
PIRAMIDE = { [1] = { total = 4, gastados = 1 }, [2] = { total = 3 }, [3] = { total = 2 } }
a, b = R(); chk("3 fichas y 9 orbes (4+3+2)", a, b, 3, 9)

print("Los orbes se ven FUERA de combate; las fichas no")
ACTIVO = false
a, b = R(); chk("0 fichas, 9 orbes", a, b, 0, 9)

print("Modo mana: no hay piramide que pintar")
MODO_MANA = true
a, b = R(); chk("nada", a, b, 0, 0)
ACTIVO = true
a, b = R(); chk("solo las fichas de accion", a, b, 3, 0)

print("Un nivel sin espacios no genera grupo")
MODO_MANA = false
PIRAMIDE = { [1] = { total = 2 }, [2] = { total = 0 }, [3] = { total = 1 } }
a, b = R(); chk("2 + 1 orbes, el nivel vacio se salta", a, b, 3, 3)

print("Sin barra nativa no se pinta nada")
_G.ActionButton1 = nil
a, b = R(); chk("cero y cero", a, b, 0, 0)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
