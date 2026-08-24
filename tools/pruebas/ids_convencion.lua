-- Convencion de ids de rasgo de clase: <abrevClase>_<abrevSub>_<cosa>.
--
-- Lee los ficheros de clase REALES. Comprueba dos cosas:
--   1. Ningun rasgo se nombra solo por su subclase (era el caso de 63: `afliccion_drenar_alma`).
--      Sin prefijo de clase, dos clases con la misma subclase -- Druida y Chaman comparten
--      "restauracion" -- solo se distinguian por suerte.
--   2. Ningun id queda huerfano: todo id renombrado debe haber desaparecido por completo.
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-5s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local CLASES = {
    Brujo = { "bru", { "afliccion", "demonologia", "destruccion" } },
    CaballerodelaMuerte = { "cdm", { "sangre", "escarcha", "profana" } },
    Cazador = { "caz", { "bestias", "punteria", "supervivencia" } },
    CazadordeDemonios = { "dh", { "devastacion", "venganza", "ira" } },
    Chaman = { "cha", { "elemental", "mejora", "restauracion" } },
    Druida = { "dru", { "equilibrio", "feral", "restauracion" } },
    Guerrero = { "gue", { "armas", "furia", "proteccion" } },
    Mago = { "mago", { "arcano", "fuego", "escarcha" } },
    Monje = { "monje", { "cervecero", "tejedor", "caminavientos" } },
    Paladin = { "pal", { "sagrado", "proteccion", "represion" } },
    Picaro = { "pic", { "asesino", "forajido", "sutileza" } },
    Sacerdote = { "sac", { "disciplina", "sagrado", "sombra", "elune" } },
}
local total, porSubclase = 0, {}
for clase, def in pairs(CLASES) do
    local fh = io.open("Harford/DnD/Data/Classes/" .. clase .. ".lua")
    if fh then
        local s = fh:read("*a"); fh:close()
        for id in s:gmatch('{ id = "([a-z_0-9]+)", level = %d+, name = "') do
            total = total + 1
            for _, sub in ipairs(def[2]) do
                if id:sub(1, #sub + 1) == sub .. "_" then
                    porSubclase[#porSubclase + 1] = clase .. ": " .. id
                end
            end
        end
    end
end
print("Ids de rasgo de clase revisados: " .. total)
chk("ninguno se nombra solo por su subclase", #porSubclase, 0)
for i = 1, math.min(#porSubclase, 6) do print("     sobra: " .. porSubclase[i]) end

-- Ningun resto de los nombres viejos en TODO el addon (incluido el catalogo de iconos).
local VIEJOS = { "afliccion_drenar_alma", "armas_golpe_colosal", "bestias_vinculo_del_companero",
                 "disciplina_expiacion", "restauracion_rejuvenecimiento", "sangre_purgatorio",
                 "cervecero_brebajes_elusivos", "equilibrio_influencia_astral" }
local RUTAS = { "Harford/Compendium/HarfordIconCatalog.lua", "Harford/DnD/Data/HarfordDnDBook.lua" }
for clase in pairs(CLASES) do RUTAS[#RUTAS + 1] = "Harford/DnD/Data/Classes/" .. clase .. ".lua" end
local restos = 0
for _, ruta in ipairs(RUTAS) do
    local fh = io.open(ruta)
    if fh then
        local s = fh:read("*a"); fh:close()
        for _, viejo in ipairs(VIEJOS) do
            if s:find(viejo, 1, true) then
                restos = restos + 1
                print("     resto de " .. viejo .. " en " .. ruta)
            end
        end
    end
end
chk("ningun id viejo sobrevive en el addon", restos, 0)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
