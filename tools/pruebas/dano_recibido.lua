-- La linea de dano RECIBIDO.
--
-- Se renderiza como "<total> <modifiers>", asi que meter la cantidad tambien en el desglose daba
-- "Recibido: 9 9 Perforante": el mismo numero dos veces. Y `dice = "-"` pintaba un "(-)" que no
-- significaba nada, porque aqui no se tira nada: se recibe.
--
-- La regla se reproduce aqui y se comprueba que la LINEA REAL del codigo sigue siendo esa: si
-- alguien la cambia, esta suite deja de valer y hay que enterarse.
local RUTA = "Harford/DnD/UI/HarfordDnD.lua"
local LINEA = 'partes[#partes + 1] = (#detalle > 1 and (tostring(d.cantidad) .. " ") or "") .. d.texto'
local DICE = 'type = "damage", label = "Recibido", total = total, dice = "",'

local src = io.open(RUTA):read("*a")

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = real == esp
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-46s %-26s %s", etiqueta, "'" .. tostring(real) .. "'",
        ok and "ok" or ("FALLA, esperaba '" .. tostring(esp) .. "'")))
end

print("El codigo real sigue construyendo la linea asi")
chk("desglose por tipo", src:find(LINEA, 1, true) ~= nil, true)
chk("sin dados: no se tira, se recibe", src:find(DICE, 1, true) ~= nil, true)

-- Misma regla que la linea de arriba.
local function partes(detalle)
    local out = {}
    for _, d in ipairs(detalle) do
        out[#out + 1] = (#detalle > 1 and (tostring(d.cantidad) .. " ") or "") .. d.texto
    end
    return table.concat(out, "  ")
end

print("Un solo tipo: el numero NO se repite")
chk("perforante", partes({ { cantidad = 9, texto = "Perforante" } }), "Perforante")
chk("con marcador de resistencia", partes({ { cantidad = 5, texto = "Perforante R" } }), "Perforante R")
chk("mitigado a cero", partes({ { cantidad = 0, texto = "Fuego I" } }), "Fuego I")

print("Varios tipos: cada uno con su cantidad, que ahi si hace falta")
chk("dos tipos", partes({ { cantidad = 9, texto = "Perforante" }, { cantidad = 5, texto = "Frio" } }),
    "9 Perforante  5 Frio")
chk("tres, con marcadores",
    partes({ { cantidad = 4, texto = "Cortante R" }, { cantidad = 7, texto = "Fuego" },
             { cantidad = 2, texto = "Veneno V" } }),
    "4 Cortante R  7 Fuego  2 Veneno V")

print("Sin componentes no hay desglose")
chk("vacio", partes({}), "")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
