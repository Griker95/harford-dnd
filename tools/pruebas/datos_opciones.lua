-- Los COSTES de las opciones son datos, no parte del nombre.
--
-- Estaban escritos dentro de la etiqueta: "Brebaje Fortificante (1 chi)". Asi el motor no los podia
-- cobrar, el Libro no los podia mostrar como recurso y el catalogo de iconos no casaba por nombre.
-- Esta suite lee los ficheros de clase REALES y comprueba que no vuelvan a colarse ahi.
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local CLASES = { "Brujo","CaballerodelaMuerte","Cazador","CazadordeDemonios","Chaman","Druida",
                 "Guerrero","Mago","Monje","Paladin","Picaro","Sacerdote" }
local conCoste, sinDeclarar, total = 0, 0, 0
local ejemplos = {}
for _, cl in ipairs(CLASES) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    if fh then
        local s = fh:read("*a"); fh:close()
        for cabeza, lab, resto in s:gmatch('{ id = "[a-z_0-9]+", label = "([^"]*)()"([^\n]*)') do end
        for lab, resto in s:gmatch('{ id = "[a-z_0-9]+", label = "([^"]+)"([^\n]*)') do
            total = total + 1
            -- Un coste dentro del NOMBRE: "(2 chi)", "(3 puntos)".
            if lab:lower():match("%(%s*%d+%s*chi%s*%)") or lab:lower():match("%(%s*%d+%s*puntos?%s*%)") then
                conCoste = conCoste + 1
                ejemplos[#ejemplos + 1] = cl .. ": " .. lab
            end
            -- Si el TEXTO dice que gasta N de un recurso, deberia declararlo.
            if resto:match("resourceCost") == nil and resto:match('desc = "[^"]*[Gg]astas %d+ punto') then
                sinDeclarar = sinDeclarar + 1
            end
        end
    end
end
print("Etiquetas de opcion revisadas: " .. total)
chk("ninguna lleva el coste dentro del nombre", conCoste, 0)
for i = 1, math.min(#ejemplos, 5) do print("     sobra: " .. ejemplos[i]) end
chk("ninguna dice 'gastas N puntos' sin declararlo", sinDeclarar, 0)

-- Un `castsSpell` que apunte a un conjuro inexistente no da error: el rasgo simplemente no hace
-- nada al pulsarlo. Se comprueba contra los datos REALES del compendio.
print("Rasgos que lanzan un conjuro del compendio")
local compendio = io.open("HarfordCompendioData/HarfordCompendioData.lua")
local datos = compendio and compendio:read("*a") or ""
if compendio then compendio:close() end
local revisados, huerfanos = 0, {}
for _, cl in ipairs(CLASES) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    local src = fh and fh:read("*a") or ""
    if fh then fh:close() end
    for id in src:gmatch('castsSpell = "([a-z_0-9]+)"') do
        revisados = revisados + 1
        if not datos:find('id = "' .. id .. '"', 1, true) then
            huerfanos[#huerfanos + 1] = id
        end
    end
end
print("  referencias a conjuro revisadas: " .. revisados)
for _, id in ipairs(huerfanos) do print("     no existe en el compendio: " .. id) end
chk("todas apuntan a un conjuro que existe", #huerfanos, 0)


-- Un `conditionId` que no exista en el catalogo hace que el motor rechace el area entera con
-- "Condicion de area desconocida", asi que el rasgo deja de funcionar del todo.
print("Condiciones referidas por los datos de clase")
local fh = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua")
local motor = fh and fh:read("*a") or ""
if fh then fh:close() end
local condRevisadas, condHuerfanas = 0, {}
local vistas = {}
for _, cl in ipairs(CLASES) do
    local f2 = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    local src = f2 and f2:read("*a") or ""
    if f2 then f2:close() end
    for id in src:gmatch('conditionId = "([a-z_0-9]+)"') do
        if not vistas[id] then
            vistas[id] = true
            condRevisadas = condRevisadas + 1
            if not motor:find("    " .. id .. " = {", 1, true) then
                condHuerfanas[#condHuerfanas + 1] = id
            end
        end
    end
end
print("  condiciones distintas revisadas: " .. condRevisadas)
for _, id in ipairs(condHuerfanas) do print("     no esta en el catalogo: " .. id) end
chk("todas existen en el catalogo", #condHuerfanas, 0)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
