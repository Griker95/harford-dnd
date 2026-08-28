-- El COSTE DE ACCION que declara un rasgo tiene que coincidir con lo que dice su texto.
--
-- Es el fallo mas silencioso que hemos encontrado: un rasgo que no declara `cast` gasta la ACCION
-- del turno, y si su texto dice "como accion adicional" el jugador pierde su accion entera sin que
-- nada avise. Paso en las OCHO Maldiciones del Brujo, en Punos de Furia y en Paso del Viento.
--
-- Se leen los ficheros de clase REALES. Solo se mira lo que el texto dice sin ambiguedad.
local CLASES = { "Brujo","CaballerodelaMuerte","Cazador","CazadordeDemonios","Chaman","Druida",
                 "Guerrero","Mago","Monje","Paladin","Picaro","Sacerdote" }

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-6s %s", etiqueta, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- Entradas que declaran coste de accion: los RASGOS (llevan `level`) y las OPCIONES elegibles
-- (llevan `label` y `desc`). Se excluye cualquier otra tabla con `id`, como los `selfCondition`
-- anidados, que heredarian la descripcion del rasgo que los contiene.
local function entradas(src)
    local fuera = {}
    for pos, id in src:gmatch('()%{ id = "([a-z_0-9]+)", level = %d') do
        fuera[#fuera + 1] = { id = id, pos = pos, campo = "description" }
    end
    for pos, id in src:gmatch('()%{ id = "([a-z_0-9]+)", cast = "[a-z_]+", label = ') do
        fuera[#fuera + 1] = { id = id, pos = pos, campo = "desc" }
    end
    for pos, id in src:gmatch('()%{ id = "([a-z_0-9]+)", label = ') do
        fuera[#fuera + 1] = { id = id, pos = pos, campo = "desc" }
    end
    table.sort(fuera, function(a, b) return a.pos < b.pos end)
    for i, e in ipairs(fuera) do
        e.cuerpo = src:sub(e.pos, (fuera[i + 1] and fuera[i + 1].pos - 1) or #src)
    end
    return fuera
end

local revisados, malos = 0, {}
for _, cl in ipairs(CLASES) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. cl .. ".lua")
    local src = fh and fh:read("*a") or ""
    if fh then fh:close() end
    for _, r in ipairs(entradas(src)) do
        local cuerpo = r.cuerpo or ""
        -- Solo la CABECERA del rasgo: la descripcion de un rasgo puede mencionar otro.
        local desc = cuerpo:match("" .. r.campo .. [[ = "([^"]*)"]]) or ""
        local declarado = cuerpo:match('cast = "([a-z_]+)"')
        local dice = desc:lower()
        local esperado
        if dice:find("como accion adicional", 1, true) or dice:find("accion adicional %+")
            or dice:find("^accion adicional") then
            esperado = "accion_adicional"
        elseif dice:find("^reaccion:", 1, true) or dice:find("usar tu reaccion", 1, true) then
            esperado = "reaccion"
        end
        -- Solo lo que se USA gastando algo. "Puedes transformarte como accion adicional" no cuesta
        -- una accion adicional: PERMITE que otra cosa la cueste, y declararle un coste seria
        -- decir que se gasta al leerlo.
        local consume = cuerpo:find("resourceKey =", 1, true) or cuerpo:find("usesFrom =", 1, true)
            or cuerpo:find('type = "accion"', 1, true) or cuerpo:find('type = "maniobra"', 1, true)
            -- y lo que YA declara un coste, para que cambiarlo por el equivocado tambien salte
            or cuerpo:find('cast = "', 1, true)
        if esperado and consume then
            revisados = revisados + 1
            if declarado ~= esperado then
                malos[#malos + 1] = string.format("%s (%s): dice %s, declara %s",
                    r.id, cl, esperado, tostring(declarado))
            end
        end
    end
end

print("Rasgos cuyo texto dice sin ambiguedad que accion cuestan")
print("  revisados: " .. revisados)
for i = 1, math.min(#malos, 12) do print("     " .. malos[i]) end
if #malos > 12 then print("     ... y " .. (#malos - 12) .. " mas") end
chk("todos declaran el coste que dice su texto", #malos, 0)

-- ─── TODO ACTIVABLE DECLARA SU COSTE ────────────────────────────────────────
-- Un rasgo de tipo accion/reaccion sin `cast` no cobra nada, y eso no se distingue de un olvido:
-- el 45% de los activables estaba asi. Ahora TODOS declaran -- un coste real, o `"ninguna"`, que
-- es gratis A PROPOSITO (riders que modifican algo ya pagado, o rasgos que conceden). Las
-- maniobras quedan exentas: su coste se DEDUCE del tipo, y escribirlo en quince tablas era el
-- error que la deduccion vino a quitar.
print("Todo activable declara su coste")
local sinCast, revisados = {}, 0
for fichero in ("Brujo Caballerodelamuerte Cazador CazadordeDemonios Chaman Druida Guerrero "
    .. "Mago Monje Paladin Picaro Sacerdote"):gmatch("%S+") do
    local ruta = "Harford/DnD/Data/Classes/" .. fichero .. ".lua"
    local h = io.open(ruta) or io.open(ruta:gsub("delamuerte", "delaMuerte"))
    if h then
        local src = h:read("*a") h:close()
        for linea in src:gmatch('{ id = "[a-z0-9_]+", level = %d+, name = "[^"]+",[%g ]*') do
            local tipo = linea:match('type = "(%a+)"')
            if tipo == "accion" or tipo == "reaccion" then
                revisados = revisados + 1
                if not linea:find('cast = "', 1, true) then
                    sinCast[#sinCast + 1] = linea:match('id = "([a-z0-9_]+)"')
                end
            end
        end
    end
end
chk("se revisaron rasgos activables", revisados > 50, true)
chk("y ninguno se queda sin declarar", table.concat(sinCast, ","), "")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
