-- HarfordUIGeom: helpers puros de geometria y busqueda de StatusBars usados por
-- los overlays de HarfordUnitFrames. Sin estado mutable ni dependencias del addon
-- (solo leen el arbol de frames nativo). Extraidos para aliviar el conteo de
-- locales de HarfordUnitFrames.lua.
--
-- Nota: Bounds/RelativeBounds se quedan en HarfordUnitFrames.lua (colisionarian
-- como substring entre si en reescrituras masivas).

HarfordUIGeom = HarfordUIGeom or {}

function HarfordUIGeom.Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

-- Recorre root[k1][k2]... de forma segura; devuelve nil si algun tramo falta.
function HarfordUIGeom.FieldPath(root, ...)
    local value = root
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        value = value and value[key]
    end
    return value
end

function HarfordUIGeom.FirstExisting(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value then return value end
    end
    return nil
end

-- Recolecta recursivamente todos los StatusBar bajo root.
function HarfordUIGeom.FindStatusBars(root, out, seen)
    out = out or {}
    seen = seen or {}
    if not root or seen[root] then return out end
    seen[root] = true

    if root.GetObjectType and root:GetObjectType() == "StatusBar" then
        out[#out + 1] = root
    end

    if root.GetChildren then
        for _, child in ipairs({ root:GetChildren() }) do
            HarfordUIGeom.FindStatusBars(child, out, seen)
        end
    end

    return out
end

function HarfordUIGeom.StatusBarScore(bar, hints)
    if not bar then return -1000 end
    hints = hints or {}
    local score = 0
    local name = bar.GetName and tostring(bar:GetName() or ""):lower() or ""
    for _, hint in ipairs(hints) do
        if name:find(tostring(hint):lower(), 1, true) then
            score = score + 100
        end
    end
    local w = bar.GetWidth and (bar:GetWidth() or 0) or 0
    local h = bar.GetHeight and (bar:GetHeight() or 0) or 0
    if w > h and w >= 30 then score = score + 10 end
    if bar.IsShown and bar:IsShown() then score = score + 3 end
    return score
end

function HarfordUIGeom.PickStatusBar(root, hints, exclude)
    local best, bestScore
    exclude = exclude or {}
    for _, bar in ipairs(HarfordUIGeom.FindStatusBars(root)) do
        if not exclude[bar] then
            local score = HarfordUIGeom.StatusBarScore(bar, hints)
            if not best or score > bestScore then
                best = bar
                bestScore = score
            end
        end
    end
    return best
end

-- Copia una caja escalando x/y/width/height/cx/cy por (sx, sy).
function HarfordUIGeom.ScaleBox(box, sx, sy)
    if not box then return nil end
    local out = {}
    for key, value in pairs(box) do
        out[key] = value
    end
    if out.x then out.x = out.x * sx end
    if out.y then out.y = out.y * sy end
    if out.width then out.width = out.width * sx end
    if out.height then out.height = out.height * sy end
    if out.cx then out.cx = out.cx * sx end
    if out.cy then out.cy = out.cy * sy end
    return out
end

function HarfordUIGeom.IsSaneBox(box, rootWidth, rootHeight, minW, minH, maxW, maxH)
    if not box then return false end
    local width = tonumber(box.width) or 0
    local height = tonumber(box.height) or 0
    if width < minW or height < minH then return false end
    if width > maxW or height > maxH then return false end
    if box.x and (box.x < -4 or box.x > rootWidth + 4) then return false end
    if box.y and (box.y < -4 or box.y > rootHeight + 4) then return false end
    return true
end
