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

-- ─── TODO ACTIVABLE DECLARA SU COSTE, Y NADIE VIVE EN EL LIMBO ─────────────
-- Se cargan los ficheros de clase REALES (los cortes por linea se rompian con los acentos y no
-- veian los `effects` multilinea). Dos reglas de una pasada:
--   1. Un rasgo de tipo accion sin `cast` no cobra nada, indistinguible de un olvido: todos
--      declaran un coste real o `"ninguna"` (gratis A PROPOSITO: riders sobre algo ya pagado).
--      Las maniobras quedan exentas -- su coste se DEDUCE del tipo.
--   2. SIN LIMBO: cada rasgo 1-6 es MECANIZADO, PASIVO deliberado o MARCADOR de subclase.
--      "Informativo sin mecanica" era el cajon de lo sin revisar y el 2026-08-28 se vacio: si
--      esto falla, un rasgo nuevo entro sin decidir cual de las tres cosas es.
print("Activables con coste declarado, y nadie en el limbo")
do
    local cargarSrc = loadstring or load
    local function cargaFichero(ruta)
        local h = io.open(ruta) if not h then return false end
        local src = h:read("*a") h:close()
        local f = cargarSrc(src, ruta) if not f then return false end
        return pcall(f)
    end
    cargaFichero("Harford/DnD/Data/HarfordDnDBook.lua")
    for fichero in ("Guerrero Picaro Mago Sacerdote Paladin Cazador Druida Chaman Brujo Monje "
        .. "CaballerodelaMuerte CazadordeDemonios"):gmatch("%S+") do
        cargaFichero("Harford/DnD/Data/Classes/" .. fichero .. ".lua")
    end
    cargaFichero("Harford/DnD/Data/HarfordDnDBookDerived.lua")

    local function esMec(f)
        if f.effects and #f.effects > 0 then return true end
        if f.type == "choice" or f.options or f.optionsFrom then return true end
        if f.uses or f.resourceKey or f.resourceCost or f.spellGrants or f.actionKind then return true end
        if f.type == "reaccion" then return true end
        if f.cast and f.cast ~= "ninguna" then return true end
        if f.trap or f.usesFrom or f.area or f.conditionalWeaponDamage then return true end
        if f.grantsAsBonus or f.grantsTurnAction then return true end
        return false
    end
    local function esMarcador(f)
        local d = tostring(f.description or ""):lower()
        return (d:find("concede rasgos", 1, true) and d:find("eliges tu", 1, true)) and true or false
    end
    local sinCast, limbo, revisados = {}, {}, 0
    for _, c in ipairs((HarfordDnDBook and HarfordDnDBook.CLASSES) or {}) do
        local function recorrer(fs)
            for _, f in ipairs(fs or {}) do
                if (tonumber(f.level) or 99) <= 6 and not esMarcador(f) then
                    revisados = revisados + 1
                    if (f.type == "accion" or f.type == "reaccion") and not f.cast then
                        sinCast[#sinCast + 1] = f.id
                    end
                    if not esMec(f) and f.type ~= "pasivo" then
                        limbo[#limbo + 1] = f.id
                    end
                end
            end
        end
        recorrer(c.features)
        for _, s in ipairs(c.subclasses or {}) do recorrer(s.features) end
    end
    chk("se revisaron rasgos de las 12 clases", revisados > 300, true)
    chk("todo activable declara su coste", table.concat(sinCast, ","), "")
    chk("y nadie queda en el limbo", table.concat(limbo, ","), "")
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
