-- Orbes de espacios de conjuro sobre la barra NATIVA.
--
-- Las FICHAS de accion y la barra de movimiento estuvieron aqui y se MUDARON al marcador de turno:
-- son lo que te queda ESTE TURNO y su sitio es junto al turno y el asalto. Tenerlas en los dos
-- lados era la misma informacion en dos sitios. Los orbes se quedan porque NO son del turno --no
-- se renuevan con el-- y por eso se ven tambien fuera de combate.
-- Y una diferencia con BG3 que impone el motor: los espacios de PACTO del brujo se suman a los
-- normales de su nivel, no van en reserva aparte.
local cargar = loadstring or load

local function NuevoFrame(nombre)
    local f = { nombre = nombre, visible = false }
    for _, m in ipairs({"SetSize","SetWidth","SetPoint","ClearAllPoints","EnableMouse","SetScript",
                        "RegisterEvent","SetFrameStrata","SetFrameLevel","SetText",
                        "SetHeight","SetStatusBarTexture","SetMinMaxValues","SetStatusBarColor",
                        "SetValue"}) do f[m] = function() end end
    -- El contenedor se sube POR ENCIMA del ancla, asi que el falso tiene que saber decir su nivel:
    -- nacia en el suelo de MEDIUM y la barra de accion nativa lo tapaba.
    f.GetFrameLevel = function() return 1 end
    -- La altura apilada se mide en pixeles de pantalla: sin `GetTop` no hay nada que medir.
    f.GetTop = function() return 100 end
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
local CREADOS = {}
CreateFrame = function(_, nombre)
    local f = NuevoFrame(nombre)
    if nombre then CREADOS[nombre] = f end
    return f
end
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
-- La barra de movimiento necesita saber de cuanto es el turno y cuanto llevas. Fuera de combate
-- el tope da igual: la barra no se pinta.
local MOV_TOPE, MOV_GASTADO = 9, 0
HarfordDnDAttackUI = {
    GetTurnMovementMax = function() return MOV_TOPE end,
    GetRecordedMovementMeters = function() return MOV_GASTADO end,
}
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
    HarfordDnDAttackUI = HarfordDnDAttackUI, string = string,
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
local a, b = R(); chk("las fichas ya no se pintan aqui", a, b, 0, 0)

print("Lanzador con piramide")
PIRAMIDE = { [1] = { total = 4, gastados = 1 }, [2] = { total = 3 }, [3] = { total = 2 } }
a, b = R(); chk("9 orbes (4+3+2), sin fichas", a, b, 0, 9)

print("Los orbes se ven FUERA de combate; las fichas no")
ACTIVO = false
a, b = R(); chk("0 fichas, 9 orbes", a, b, 0, 9)

print("Modo mana: no hay piramide que pintar")
MODO_MANA = true
a, b = R(); chk("nada", a, b, 0, 0)
ACTIVO = true
a, b = R(); chk("en modo mana no se pinta nada", a, b, 0, 0)

print("Un nivel sin espacios no genera grupo")
MODO_MANA = false
PIRAMIDE = { [1] = { total = 2 }, [2] = { total = 0 }, [3] = { total = 1 } }
a, b = R(); chk("2 + 1 orbes, el nivel vacio se salta", a, b, 0, 3)

print("Sin barra nativa no se pinta nada")
_G.ActionButton1 = nil
a, b = R(); chk("cero y cero", a, b, 0, 0)
-- ─── LAS FICHAS TIENEN QUE QUEDAR DELANTE ───────────────────────────────────
-- Se dibujaban, estaban en pantalla y con alfa 1... y no se veian: nacian en el nivel 1, el suelo
-- de MEDIUM, y la barra de accion nativa comparte capa con niveles mas altos. Estar en pantalla no
-- es estar visible, que es la misma leccion que dejo la tira de estados.
local fuente = io.open("Harford/DnD/UI/HarfordActionBars.lua"):read("*a")
-- `chk` de esta suite compara PARES (fichas, orbes); aqui basta con una condicion.
local function chk1(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-50s %-6s %s", n, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end
-- ── LA PILA DE BARRAS SE BUSCA POR NOMBRE ───────────────────────────────────
-- Una tabla `{ _G["A"], _G["B"] }` donde el primero no existe se construye con un hueco en el
-- indice 1, y `ipairs` para en el primer nil: con la barra de Sigilo la primera de la lista, un
-- cliente sin ella no encontraba NINGUNA barra. Funcionaba de milagro porque el unico que solia
-- existir estaba el primero.
print("La pila de barras se busca por nombre")
chk1("por nombre, no por frame", fuente:find('for _, nombre in ipairs(pila) do', 1, true) ~= nil, true)
chk1("y ningun hueco en la lista",
    fuente:find('"StanceBarFrame",            -- Sigilo', 1, true) ~= nil, true)
-- Centrado sobre la barra, no pegado a su borde izquierdo: es donde el juego pone la barra de
-- Sigilo y las formas de druida, y es donde se mira.
-- El CENTRO sale de la barra principal y la ALTURA de lo mas alto que haya apilado: son dos cosas
-- distintas, y mezclarlas dejaba los iconos centrados sobre la barra de la DERECHA, que ni empieza
-- donde la principal ni mide lo mismo.
chk1("centrado sobre la barra principal",
    fuente:find('cont:SetPoint("BOTTOM", base, "TOP", 0, 8 + AlturaApilada(base))', 1, true) ~= nil, true)
chk1("y la altura se mide, no se cuenta por barras",
    fuente:find("local function AlturaApilada(base)", 1, true) ~= nil, true)
chk1("y la fila de fichas centrada dentro",
    fuente:find('cont.fichas[1]:SetPoint("BOTTOMLEFT", cont, "BOTTOM", -fila / 2, 0)', 1, true) ~= nil, true)

print("Las fichas se pintan por delante de la barra nativa")
chk1("nacen en un nivel alto", fuente:find("fichasFrame:SetFrameLevel(90)", 1, true) ~= nil, true)
-- Y por encima del ancla REAL: con Dominos o Bartender la barra puede estar mas alta que 90.
chk1("y por encima del ancla real",
    fuente:find("math.max(90, (ancla:GetFrameLevel() or 0) + 5)", 1, true) ~= nil, true)
chk1("sin salirse de su capa", fuente:find('fichasFrame:SetFrameStrata("MEDIUM")', 1, true) ~= nil, true)


print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
