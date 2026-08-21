-- Vuelca TODAS las capturas de HarfordFrameProbe a un unico JSON, sin editar nada por caso.
--
--   lua tools/codice/export_probe.lua [cuenta] [salida.json]
--
-- Estructura de salida:  { "NombreDeFrame": { "etiqueta": <arbol> , ... }, ... }
-- Luego:  python tools/codice/gen_frame_from_probe.py <salida.json> "Frame/etiqueta" ...

local account = ... or "MORTYN"
local out_path = select(2, ...) or "probe_captures.json"
local sv = "G:/Epsilon/_retail_/WTF/Account/" .. account .. "/SavedVariables/HarfordDebug.lua"

local ok, err = pcall(dofile, sv)
if not ok then
    print("No se pudo leer " .. sv .. ": " .. tostring(err))
    return
end

local function esc(s)
    s = tostring(s)
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", " "):gsub("\r", ""):gsub("%c", " ")
    return s
end

local function ser(v, depth)
    depth = depth or 0
    if depth > 16 then return '"..."' end
    local t = type(v)
    if t == "number" or t == "boolean" then return tostring(v) end
    if t ~= "table" then return '"' .. esc(v) .. '"' end
    if #v > 0 then
        local parts = {}
        for _, x in ipairs(v) do parts[#parts + 1] = ser(x, depth + 1) end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for k, x in pairs(v) do parts[#parts + 1] = '"' .. esc(k) .. '":' .. ser(x, depth + 1) end
    return "{" .. table.concat(parts, ",") .. "}"
end

local captures = HarfordFrameProbe and HarfordFrameProbe.captures
if type(captures) ~= "table" then
    print("No hay HarfordFrameProbe.captures en " .. sv)
    return
end

local total, frames = 0, 0
for frame, labels in pairs(captures) do
    frames = frames + 1
    for _ in pairs(labels) do total = total + 1 end
end

local f = io.open(out_path, "wb")
f:write(ser(captures))
f:close()
print(string.format("%s escrito: %d frames, %d capturas", out_path, frames, total))
for frame, labels in pairs(captures) do
    local names = {}
    for label in pairs(labels) do names[#names + 1] = label end
    table.sort(names)
    print("  " .. frame .. ": " .. table.concat(names, ", "))
end
