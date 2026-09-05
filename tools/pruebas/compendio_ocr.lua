-- BARRIDO OCR DEL COMPENDIO — candado del estado limpio (2026-09-05).
--
-- La auditoria comparada contra la web (fuente canonica de texto) dio: 1 artefacto real
-- (rociada_venenosa "2dl 2" -> "2d12"), 0 dados desviados de la web, 0 cabeceras de pagina,
-- 0 mojibake, 0 descripciones con contenido de otro conjuro incrustado, y cobertura completa
-- de nivel 0-4 salvo sp_castigo_abrasador (duplicado web de golpe_llameante: ANOTADO en
-- CONJUROS_PENDIENTES, no se importa) y sp_resplandor_enfermizo (alta hecha).
--
-- Esta suite impide la regresion: si una edicion futura re-introduce artefactos de OCR, o
-- borra la alta, o el dado vuelve a romperse, falla aqui antes de llegar al juego.
--
-- LECCION del escaner (no repetirla): los ids anidados (`condition = { id = "..." }`) parten
-- un parser ingenuo de bloques; las entradas reales van con `id` a INDENTACION 8 en su linea.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-60s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

local t = io.open("HarfordCompendio/HarfordCompendio.lua"):read("*a")

print("Sin artefactos de OCR")
-- Dados con "l" por "1" u "O" por "0": "2dl 2", "ldl0", "3dO"... El patron busca las formas
-- que aparecieron en la auditoria original y en esta.
chk("sin 'dl' pegado a cifras", t:find("%ddl%s?%d") == nil, true)
chk("sin 'ld' como dado", t:find("[%s%(]ld%d") == nil, true)
chk("sin dados con O por cero", t:find("%dd[O]%f[%W]") == nil, true)
-- Cabeceras de pagina del OCR original. "JUROS" solo como palabra partida en mayusculas
-- (la trampa: "conjuros" contiene "juros" y un patron descuidado lo pesca).
chk("sin PITULO", t:find("PITULO") == nil, true)
chk("sin PARTE N |", t:find("PARTE %d+%s*|") == nil, true)
chk("sin '| HECHIZOS'", t:find("|%s*HECHIZOS") == nil, true)
chk("sin JUROS partido", t:find("%f[%u]JUROS%f[%A]") == nil, true)
-- Mojibake y controles: el fichero es UTF-8 limpio.
chk("sin U+FFFD", t:find("\239\191\189") == nil, true)
chk("sin dobles codificaciones tipicas", t:find("\195\131") == nil and t:find("\195\162") == nil, true)
chk("sin caracteres de control", t:find("[\1-\8\11\12\14-\31]") == nil, true)

print("El dado de rociada_venenosa quedo arreglado")
chk("dice 2d12", t:find("nivel 5 (2d12), nivel 11 (3d12)", 1, true) ~= nil, true)

print("La alta de Resplandor enfermizo (unico 0-4 que faltaba)")
local i = t:find('id = "sp_resplandor_enfermizo"', 1, true)
chk("existe", i ~= nil, true)
if i then
    local bloque = t:sub(i, i + 2200)
    chk("nivel 4", bloque:find("level = 4", 1, true) ~= nil, true)
    chk("Brujo", bloque:find('classes = { "Brujo" }', 1, true) ~= nil, true)
    chk("salvacion de Constitucion", bloque:find('savingThrow = "Constitucion"', 1, true) ~= nil, true)
    chk("4d10 radiante", bloque:find('damage = "4d10 radiante"', 1, true) ~= nil, true)
    chk("en metrico (36 metros)", bloque:find('range = "36 metros"', 1, true) ~= nil, true)
    chk("icono numerico reutilizado y valido", bloque:find("icon = 137020", 1, true) ~= nil, true)
    -- La recurrencia y el agotamiento son de mesa: la alta NO declara condicion automatica
    -- (la norma: no usar el resolvedor simple para daño recurrente).
    chk("sin condition automatica", bloque:find("condition = {", 1, true) == nil, true)
end
-- Y el duplicado web NO se importo: el addon ya tiene ese conjuro como golpe_llameante.
chk("sin sp_castigo_abrasador (duplicado anotado)",
    t:find('id = "sp_castigo_abrasador"', 1, true) == nil, true)

print("Conteo de entradas (parser a nivel de entrada)")
local n = 0
for _ in t:gmatch('\n        id = "[%w_]+",') do n = n + 1 end
chk("385 entradas de nivel superior (384 + la alta)", n, 385)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
