-- NUCLEOS DEMONIACOS DEL BRUJO: los cinco cotejados contra el manual y con mecanica real.
--
-- Lo que sella: (1) los datos de los cinco rasgos `bru_nucleo_*` calcan el Apendice C del
-- Warcraft 5ª (ventajas, conjuro a voluntad y escalones 5/9, con las equivalencias de nombre
-- del compendio); (2) la ventaja en chequeos esta MECANIZADA (efecto `skillAdvantage`) y solo
-- la da el nucleo SOSTENIDO (puerta `requiredCore` via IsFeatureEnabled); (3) el lanzamiento
-- gratis "1 vez por descanso largo" tiene contador con escalon real (0 hasta N4, 1 desde N5,
-- 2 desde N9), asi que un brujo de nivel 2-4 no ve un contador de algo que aun no existe;
-- (4) un rasgo NO habilitado se lee en el Libro pero no se anuncia ni se gasta.

local cargar = loadstring or load
local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-58s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── CARGA REAL de los rasgos del Brujo (el fichero de clase, no copias) ────
local B = { CLASSES = {} }
B.ASI = function() return { id = "asi_stub", level = 4, name = "Mejora", effects = {} } end
B.WeaponProfEffects = function() return {} end
B.ManeuverEffects = function() return {} end
B.GetClass = function(id)
    for _, c in ipairs(B.CLASSES) do if c.id == id then return c end end
end
local envB = setmetatable({ HarfordDnDBook = B }, { __index = function() return nil end })
envB.ipairs, envB.pairs, envB.tostring, envB.tonumber = ipairs, pairs, tostring, tonumber
envB.type, envB.table, envB.string, envB.math = type, table, string, math
local srcB = io.open("Harford/DnD/Data/Classes/Brujo.lua"):read("*a")
local fB
if setfenv then fB = assert(cargar(srcB)); setfenv(fB, envB) else fB = assert(cargar(srcB, "t", "t", envB)) end
assert(pcall(fB))
local brujo = B.GetClass("brujo")
chk("la clase carga", brujo ~= nil, true)

local nucleos = {}
for _, f in ipairs((brujo and brujo.features) or {}) do
    if tostring(f.id):find("^bru_nucleo_") then nucleos[f.requiredCore or f.id] = f end
end

-- ─── (1) DATOS = MANUAL (Apendice C, Companeros Demoniacos) ─────────────────
print("Los cinco nucleos calcan el manual")
-- { demonio = { habilidades con ventaja }, atWill, conjuro N5, conjuro N9 (id o nil si no existe) }
local LIBRO = {
    guardia_vil = { { "Atletismo", "Supervivencia" }, "armadura_de_mago", "arma_magica", nil },
    manafago    = { { "Investigacion", "Percepcion" }, "detectar_magia", "contrahechizo", "localizar_criatura" },
    diablillo   = { { "JuegoManos", "Sigilo" }, "burla_danina", "parpadeo", nil },
    sucubo      = { { "Engano", "Persuasion" }, "hechizar_persona", "sugestion", nil },
    abisario    = { { "Perspicacia", "Intimidacion" }, "armadura_de_agathys", "hambre_de_hadar", nil },
}
local compendio = io.open("HarfordCompendio/HarfordCompendio.lua"):read("*a")
local total = 0
for core, esp in pairs(LIBRO) do
    total = total + 1
    local f = nucleos[core]
    chk(core .. ": el rasgo existe", f ~= nil, true)
    if f then
        -- La ventaja mecanizada declara EXACTAMENTE las dos habilidades del libro.
        local adv = {}
        for _, e in ipairs(f.effects or {}) do
            if e.kind == "skillAdvantage" then
                for _, s in ipairs(e.skills or {}) do adv[#adv + 1] = s end
            end
        end
        table.sort(adv)
        local esperadas = { esp[1][1], esp[1][2] }
        table.sort(esperadas)
        chk(core .. ": ventaja en " .. table.concat(esperadas, "+"),
            table.concat(adv, "+"), table.concat(esperadas, "+"))
        -- Conjuros concedidos por escalon de NIVEL DE CLASE (2 = a voluntad, 5 y 9 = gratis 1/largo).
        local porNivel = {}
        for _, g in ipairs(f.spellGrants or {}) do
            porNivel[tonumber(g.level) or 0] = (g.ids or {})[1]
        end
        chk(core .. ": a voluntad desde N2", porNivel[2], esp[2])
        chk(core .. ": conjuro de N5", porNivel[5], esp[3])
        if esp[4] then
            chk(core .. ": conjuro de N9", porNivel[9], esp[4])
        else
            -- El del N9 NO esta en el compendio (documentado); no se inventa un grant.
            chk(core .. ": sin grant de N9 (conjuro sin alta)", porNivel[9], nil)
        end
        -- Todo id concedido existe en el compendio: un grant a un id fantasma no concede nada.
        for _, g in ipairs(f.spellGrants or {}) do
            for _, id in ipairs(g.ids or {}) do
                chk(core .. ": '" .. id .. "' existe en el compendio",
                    compendio:find('id = "' .. id .. '"', 1, true) ~= nil, true)
            end
        end
        -- El contador del lanzamiento gratis: 0 hasta N4, 1 desde N5, 2 desde N9.
        local u = f.uses
        chk(core .. ": contador por nivel de brujo", u and u.perClassLevel, "brujo")
        chk(core .. ": recarga en descanso largo", u and u.recharge, "long")
        local v = (u and u.values) or {}
        chk(core .. ": 0 usos a N4, 1 a N5, 2 a N9",
            table.concat({ v[4] or -1, v[5] or -1, v[9] or -1 }, "/"), "0/1/2")
    end
end
chk("y son exactamente cinco", total, 5)

-- El bloque del demonio apunta de vuelta a su rasgo (coreFeatureId <-> requiredCore).
print("Demonio y rasgo se apuntan mutuamente")
local companions = io.open("Harford/DnD/Data/HarfordDnDCompanionsData.lua"):read("*a")
for core, _ in pairs(LIBRO) do
    chk(core .. " -> bru_nucleo_" .. core,
        companions:find('coreFeatureId = "bru_nucleo_' .. core .. '"', 1, true) ~= nil, true)
end

-- ─── (2) LA VENTAJA SOLO LA DA EL NUCLEO SOSTENIDO ──────────────────────────
print("skillAdvantage: solo el nucleo que sostienes")
local activeCore = ""
local desbloqueados = {}
for _, f in pairs(nucleos) do desbloqueados[#desbloqueados + 1] = { feature = f, level = 2, classId = "brujo" } end
local envF = setmetatable({}, { __index = function() return nil end })
envF.ipairs, envF.pairs, envF.tostring, envF.tonumber = ipairs, pairs, tostring, tonumber
envF.type, envF.table, envF.string, envF.math, envF.select = type, table, string, math, select
envF.setmetatable, envF.next = setmetatable, next
envF.HarfordDnDProgression = {
    GetUnlockedFeatures = function() return desbloqueados end,
    -- Misma puerta que la real: un rasgo con requiredCore solo cuenta con ese nucleo activo.
    IsFeatureEnabled = function(f)
        if f.requiredCore and tostring(f.requiredCore) ~= activeCore then return false end
        return true
    end,
    GetClassLevels = function() return { { classId = "brujo", level = 5 } } end,
    GetChoice = function() return {} end,
}
local srcF = io.open("Harford/DnD/Engine/HarfordDnDFeatureEffects.lua"):read("*a")
local fF
if setfenv then fF = assert(cargar(srcF)); setfenv(fF, envF) else fF = assert(cargar(srcF, "t", "t", envF)) end
assert(pcall(fF))
local FE = envF.HarfordDnDFeatureEffects

chk("sin nucleo, sin ventaja", FE.HasSkillAdvantage("Atletismo"), false)
activeCore = "guardia_vil"; FE.Invalidate()
chk("guardia vil: Atletismo", FE.HasSkillAdvantage("Atletismo"), true)
chk("y da igual la capitalizacion", FE.HasSkillAdvantage("atletismo"), true)
chk("guardia vil: Supervivencia", FE.HasSkillAdvantage("Supervivencia"), true)
chk("pero Sigilo no", FE.HasSkillAdvantage("Sigilo"), false)
activeCore = "diablillo"; FE.Invalidate()
chk("cambiar de nucleo cambia la ventaja", FE.HasSkillAdvantage("Sigilo"), true)
chk("y la anterior se apaga", FE.HasSkillAdvantage("Atletismo"), false)
activeCore = ""; FE.Invalidate()
chk("soltar el nucleo la quita", FE.HasSkillAdvantage("Sigilo"), false)

-- ─── (3) LA FUSION 5e VIVE EN ResolveRollMode ───────────────────────────────
-- El flag `featureAdvantage` viaja en el contexto (como rangeDisadvantage) y se anula con
-- cualquier desventaja: ventaja + desventaja = normal, no "gana la ultima".
print("featureAdvantage se fusiona con las reglas 5e")
local envC = setmetatable({}, { __index = function() return nil end })
envC.ipairs, envC.pairs, envC.tonumber, envC.tostring = ipairs, pairs, tonumber, tostring
envC.type, envC.select, envC.next, envC.error, envC.assert = type, select, next, error, assert
envC.table, envC.string, envC.math, envC.pcall = table, string, math, pcall
envC.setmetatable, envC.print = setmetatable, function() end
envC.HarfordClassColors = { NormalizeKey = function(v) return tostring(v or ""):lower() end,
    UnitFullName = function() return "" end, FindUnitByName = function() return nil end,
    StripAccents = function(v) return v end }
envC.GetTime = function() return 1000 end
envC.CreateFrame = function()
    local f = {}
    setmetatable(f, { __index = function() return function() end end })
    return f
end
local srcC = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
local fC
if setfenv then fC = assert(cargar(srcC)); setfenv(fC, envC) else fC = assert(cargar(srcC, "t", "t", envC)) end
assert(pcall(fC))
local C = envC.HarfordDnDConditions
chk("normal + rasgo = ventaja",
    C.ResolveRollMode("normal", "ability", { actorUnit = "player", featureAdvantage = true }), "adv")
chk("desventaja + rasgo = normal (se anulan)",
    C.ResolveRollMode("dis", "ability", { actorUnit = "player", featureAdvantage = true }), "normal")
chk("sin flag no toca nada",
    C.ResolveRollMode("normal", "ability", { actorUnit = "player" }), "normal")

-- ─── (4) CABLEADO EN LA TIRADA Y EN EL LIBRO ────────────────────────────────
print("La tirada consulta el rasgo y el Libro respeta la puerta")
local calc = io.open("Harford/DnD/Engine/HarfordDnDCalc.lua"):read("*a")
chk("RollD20Full consulta HasSkillAdvantage",
    calc:find("HarfordDnDFeatureEffects.HasSkillAdvantage(context.skill)", 1, true) ~= nil, true)
chk("solo en tirada propia", calc:find("if propia and context and context.skill", 1, true) ~= nil, true)
chk("y nunca en contexto NPC (aislamiento de ficha)",
    calc:find("not (HarfordDnDContext and HarfordDnDContext.State and HarfordDnDContext.State.active)", 1, true) ~= nil, true)
-- La ficha pasa el id de la habilidad en el contexto de la tirada, o no habria que consultar.
local ficha = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("la tirada de habilidad lleva skill en el contexto",
    ficha:find('{ actorUnit = "player", ability = s.ability, skill = s.id }', 1, true) ~= nil, true)
-- Un rasgo NO habilitado (nucleo que no sostienes) se lee pero no se anuncia ni gasta.
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
local guardia = panel:find("not HarfordDnDProgression.IsFeatureEnabled(feature, GetProfileName())", 1, true)
chk("AnnounceAbility bloquea rasgos no habilitados", guardia ~= nil, true)
-- Y lo hace ANTES del aviso de usos: la LLAMADA a WarnFeatureWithoutUses que sigue al guardia
-- (no su definicion, que va antes en el fichero) tiene que quedar detras.
chk("antes de mirar los usos", guardia ~= nil
    and panel:find("WarnFeatureWithoutUses(feature)", guardia, true) ~= nil, true)
-- Y el contador de un nucleo que NO sostienes ni aparece: GetTracked filtra por IsFeatureEnabled
-- y por maximo > 0, asi que los otros cuatro no ensenan "Usos".
local prog = io.open("Harford/DnD/State/HarfordDnDProgression.lua"):read("*a")
chk("GetTracked filtra rasgos deshabilitados",
    prog:find("if uses and (not API.IsFeatureEnabled or API.IsFeatureEnabled(feature, profileName)) then", 1, true) ~= nil, true)
chk("y contadores a cero (brujo 2-4)", prog:find("if maxUses > 0 then", 1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
