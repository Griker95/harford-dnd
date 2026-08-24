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
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
