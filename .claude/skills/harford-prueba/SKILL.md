---
name: harford-prueba
description: Escribe o amplia una suite de tools/pruebas para candar un comportamiento de Harford. Usar al mecanizar algo nuevo, arreglar un bug que pueda volver, o cuando el usuario pida "candalo" o "ponle una prueba".
---

# Candar comportamiento en `tools/pruebas/`

Toda mecánica nueva o bug arreglado se CANDA en una suite. La batería entera corre con lua 5.1
de consola y debe terminar en `TODO CORRECTO`.

## Estructura de una suite

- Contador `fallos` + helper `chk(etiqueta, real, esperado)` que imprime alineado y compara por
  `tostring`. Última línea: `print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))`.
- Etiquetas y prints en español, minúsculas, contando la HISTORIA de la regla (el porqué),
  no solo el qué. Comentario de cabecera con la fecha si es un candado de una decisión del día.

## Cargar un módulo real en sandbox

```lua
local cargar = loadstring or load
local function cargarModulo(ruta, env)
    env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
    env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
    env.setmetatable = setmetatable
    local src = io.open(ruta):read("*a")
    local f
    if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
    pcall(f)
    return env
end
-- env = setmetatable({ <stubs de deps> }, { __index = function() return nil end })
```

Los stubs capturan efectos (p. ej. `Broadcast = function(d) ULTIMA = d.label end`) y variables
upvalue del test (`NIVEL`, `PROG`) controlan el estado entre casos.

## Cuándo candar por TEXTO en vez de ejecutar

Si la lógica vive en un chunk grande con UI (HarfordDnD.lua, CompendioCore, AdminUnitMenu),
leer el fichero con `io.open(...):read("*a")` y `t:find(fragmento, 1, true)` sobre el código
exacto. Comentar POR QUÉ se cierra por texto. Ojo: si una suite escanea un fichero que se
modularizó, debe leer la UNIÓN padre+módulo.

## Antes de dar por buena

```bash
cd "C:/Users/marco/Documents/New project" && luac -p tools/pruebas/<suite>.lua && lua tools/pruebas/<suite>.lua
```

y después la batería completa (ver skill harford-release, paso 1). Una prueba que pasa a la
primera sin haberla visto fallar es sospechosa: romper a mano lo que canda y verla fallar.
