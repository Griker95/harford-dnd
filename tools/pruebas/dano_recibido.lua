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



-- ¿CUANDO se anuncia? En un ataque normal, el atacante ya ha publicado ese numero y ese tipo:
-- repetirlo desde la victima es una linea de ruido por cada golpe. Solo se dice cuando el resultado
-- NO es el que se anuncio.
print("Se anuncia solo si hay algo que contar")
chk("la condicion esta en el codigo", src:find("if mitigado or total ~= bruto then", 1, true) ~= nil, true)

local function anuncia(bruto, total, mitigado)
    return (mitigado or total ~= bruto) and true or false
end
chk("golpe normal, nada cambia", anuncia(9, 9, false), false)
chk("resistencia: la mitad", anuncia(9, 4, true), true)
chk("inmunidad: a cero", anuncia(9, 0, true), true)
chk("vulnerabilidad: el doble", anuncia(9, 18, true), true)
chk("reduccion plana sin marcador", anuncia(9, 4, false), true)
chk("desviado al demonio", anuncia(9, 5, false), true)
chk("cero de entrada, cero de salida", anuncia(0, 0, false), false)



-- El DETALLE de la linea del atacante no debe repetir el tipo de la cabecera.
-- Salia "9 Perforante (1d6: 1+3+1 + Ataque Furtivo 2d6: 2+2 perforante)": el tipo dos veces en la
-- misma linea. Solo se nombra cuando el componente es de OTRO tipo que el arma.
print("El detalle solo nombra el tipo si difiere del arma")
local wr = io.open("Harford/DnD/Engine/HarfordDnDWeaponRolls.lua"):read("*a")
chk("dano condicional", wr:find('if cdType ~= "" and cdType ~= dtype then', 1, true) ~= nil, true)
chk("dano extra", wr:find('if extraType ~= "" and extraType ~= dtype then', 1, true) ~= nil, true)

local function etiqueta(base, tipoArma, tipoComp, marcador)
    local out = base
    if tipoComp ~= "" and tipoComp ~= tipoArma then out = out .. " " .. tipoComp end
    if marcador ~= "" then out = out .. " " .. marcador end
    return out
end
chk("mismo tipo que el arma", etiqueta("Ataque Furtivo 2d6: 2+2", "perforante", "perforante", ""),
    "Ataque Furtivo 2d6: 2+2")
chk("otro tipo si se nombra", etiqueta("Golpe Runico 1d6: 4", "cortante", "necrotico", ""),
    "Golpe Runico 1d6: 4 necrotico")
chk("el marcador va siempre", etiqueta("Ataque Furtivo 2d6: 2+2", "perforante", "perforante", "R"),
    "Ataque Furtivo 2d6: 2+2 R")
chk("otro tipo y marcador", etiqueta("Golpe Runico 1d6: 4", "cortante", "fuego", "V"),
    "Golpe Runico 1d6: 4 fuego V")
chk("componente sin tipo declarado", etiqueta("Extra 1d4: 3", "perforante", "", ""), "Extra 1d4: 3")

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
