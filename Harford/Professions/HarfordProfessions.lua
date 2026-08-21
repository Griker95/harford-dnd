------------------------------------------------------------
-- HarfordProfessions - Core del sistema de profesiones D&D (unifica profesiones WoW + herramientas
-- D&D). Estado por-PJ, skill numerico 1-300 con tiers, y resolucion de crafteo por tirada D&D.
--
-- Reglas fijadas:
--  * Skill NUMERICO 1-300; los tiers se derivan del numero (Aprendiz/Oficial/Experto/Artesano/Maestro).
--  * "Tener la competencia de herramienta = conoces la profesion" (nivel base). Las que no tienen
--    herramienta D&D (Mineria/Pesca/etc.) se conocen al aprenderlas (skill > 0, via DM o mundo).
--  * Recetas gateadas por tier de skill; algunas `worldLearned` (no auto por nivel, se aprenden fuera).
--  * MATERIALES REALES: se verifican con GetItemCount y se consumen con HarfordServerActions.RemoveItem
--    (`.additem <id> -<qty>`, verificado). El output se da con GiveItem (`.additem`).
--  * Los IDs de items viven en HarfordProfessionsItems (registro por clave); receta con material sin
--    ID registrado = "pendiente" (no crafteable) hasta que llegue el ID.
--
-- Datos (catalogo de profesiones + recetas) en HarfordProfessionsData.
------------------------------------------------------------

HarfordProfessions = HarfordProfessions or {}
local API = HarfordProfessions

local function print(...)
    if not (HarfordChat and HarfordChat.Print) then return end
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    HarfordChat.Print(table.concat(parts, " "))
end

API.MAX_SKILL = 300
-- Tiers por umbral de skill (de mayor a menor al buscar).
API.TIERS = {
    { name = "Aprendiz", min = 1 },
    { name = "Oficial",  min = 75 },
    { name = "Experto",  min = 150 },
    { name = "Artesano", min = 225 },
    { name = "Maestro",  min = 300 },
}

------------------------------------------------------------
-- Persistencia (per-character)
------------------------------------------------------------
local function Store()
    HarfordProfessionsStore = HarfordProfessionsStore or {}
    HarfordProfessionsStore.skills = HarfordProfessionsStore.skills or {}   -- [profId] = skill (num)
    HarfordProfessionsStore.learned = HarfordProfessionsStore.learned or {} -- [recipeId] = true (worldLearned)
    HarfordProfessionsStore.nodeCooldowns = HarfordProfessionsStore.nodeCooldowns or {} -- [nodeGuid] = expiraEpoch
    return HarfordProfessionsStore
end

local function ProfileName()
    if HarfordDnD and HarfordDnDAPI and HarfordDnDAPI.GetProfileName then
        local n = HarfordDnDAPI.GetProfileName(); if n and n ~= "" then return n end
    end
    return (UnitName and UnitName("player")) or "player"
end

------------------------------------------------------------
-- Catalogo (delega en HarfordProfessionsData)
------------------------------------------------------------
local function Data() return _G.HarfordProfessionsData end
local function Items() return _G.HarfordProfessionsItems end

function API.GetProfessions()
    local d = Data()
    return (d and d.PROFESSIONS) or {}
end

function API.GetDefinition(profId)
    profId = tostring(profId or "")
    for _, p in ipairs(API.GetProfessions()) do
        if p.id == profId then return p end
    end
    return nil
end

function API.GetRecipes(profId)
    profId = tostring(profId or "")
    local out = {}
    local d = Data()
    for _, r in ipairs((d and d.RECIPES) or {}) do
        if r.profession == profId then out[#out + 1] = r end
    end
    return out
end

function API.GetRecipe(recipeId)
    recipeId = tostring(recipeId or "")
    local d = Data()
    for _, r in ipairs((d and d.RECIPES) or {}) do
        if r.id == recipeId then return r end
    end
    return nil
end

------------------------------------------------------------
-- Skill / tiers / conocer
------------------------------------------------------------
function API.GetSkill(profId)
    return tonumber(Store().skills[tostring(profId or "")]) or 0
end

function API.SetSkill(profId, value)
    profId = tostring(profId or "")
    if profId == "" then return end
    value = math.max(0, math.min(API.MAX_SKILL, math.floor(tonumber(value) or 0)))
    Store().skills[profId] = value > 0 and value or nil
end

-- ¿Conoce la profesion? Por competencia de herramienta (auto) o por skill aprendido (>0).
function API.KnowsProfession(profId)
    if API.GetSkill(profId) > 0 then return true end
    local def = API.GetDefinition(profId)
    if def and def.tool and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasToolProf
        and HarfordDnDFeatureEffects.HasToolProf(def.tool, ProfileName()) then
        return true
    end
    return false
end

-- Skill efectivo: si conoce por competencia pero no tiene skill guardado, cuenta como 1 (base).
function API.EffectiveSkill(profId)
    local s = API.GetSkill(profId)
    if s > 0 then return s end
    return API.KnowsProfession(profId) and 1 or 0
end

function API.GetTierName(skill)
    skill = tonumber(skill) or 0
    local name = "-"
    for _, t in ipairs(API.TIERS) do
        if skill >= t.min then name = t.name end
    end
    return name
end

-- Instantanea segura para UI externa/Arcanum. No devuelve la persistencia interna.
function API.GetStationInfo(profId)
    profId = tostring(profId or ""):lower()
    local def = API.GetDefinition(profId)
    if not def then return nil end
    local skill = API.EffectiveSkill(profId)
    return {
        id = def.id,
        name = def.name,
        kind = def.kind,
        known = API.KnowsProfession(profId),
        skill = skill,
        tier = API.GetTierName(skill),
    }
end

-- Entrada publica para un Spark/ArcSpell de estacion. El argumento es SIEMPRE el id
-- de profesion ("herreria", "alquimia"...), nunca un tipo de objeto como "forja".
function API.OpenStation(profId)
    profId = tostring(profId or ""):lower()
    local info = API.GetStationInfo(profId)
    if not info then
        print("|cffff5555Estacion mal configurada: profesion desconocida (" .. profId .. ").|r")
        return false, "Profesion desconocida: " .. profId
    end
    if not (HarfordCharacterPanel and HarfordCharacterPanel.OpenProfession) then
        print("|cffff5555No se pudo abrir la estacion: panel de profesiones no disponible.|r")
        return false, "Panel de profesiones no disponible"
    end
    return HarfordCharacterPanel.OpenProfession(profId)
end

------------------------------------------------------------
-- Tirada de la profesion (competencia herramienta + caracteristica)
------------------------------------------------------------
local function ProfBonusIfTool(def)
    if not (def and def.tool) then return 0 end
    if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.HasToolProf
        and HarfordDnDFeatureEffects.HasToolProf(def.tool, ProfileName())
        and HarfordDnDCalc and HarfordDnDCalc.GetProficiencyBonus then
        return tonumber(HarfordDnDCalc.GetProficiencyBonus()) or 0
    end
    return 0
end

local function AbilityMod(ability)
    if HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and ability then
        return tonumber(HarfordDnDCalc.GetAbilityMod(ability)) or 0
    end
    return 0
end

------------------------------------------------------------
-- Materiales (registro de items)
--
-- RESERVA DE MATERIAL EN VUELO. `RemoveItem` es un comando de servidor ASINCRONO: entre que se
-- craftea y que el servidor descuenta, `GetItemCount` sigue devolviendo el valor viejo. Sin esto,
-- craftear en rafaga (o repulsar "Crear todo") permitiria fabricar mas de lo que los materiales
-- dan de si, porque cada comprobacion leeria bolsas sin actualizar.
--
-- Solucion: al craftear se APUNTA lo consumido como reservado y `InspectMaterials` lo resta del
-- `have`. La reserva de una clave se libera cuando las bolsas confirman el descuento (BAG_UPDATE
-- con recuento ya por debajo del esperado) o, como red de seguridad si el comando se perdio, al
-- expirar RESERVE_TTL. No es un tick: son eventos + un one-shot.
------------------------------------------------------------
local RESERVE_TTL = 15
local reserved = {}  -- key -> { qty = <en vuelo>, expected = <recuento objetivo>, at = <time> }

local function ReservedQty(key)
    local r = reserved[key]
    return r and r.qty or 0
end

local function ReleaseSettledReservations()
    local items = Items()
    if not items then return end
    local now = time()
    for key, r in pairs(reserved) do
        local have = items.GetOwnedCount(key) or 0
        if have <= (r.expected or 0) or (now - (r.at or now)) >= RESERVE_TTL then
            reserved[key] = nil
        end
    end
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("BAG_UPDATE_DELAYED")
    watcher:RegisterEvent("BAG_UPDATE")
    watcher:SetScript("OnEvent", ReleaseSettledReservations)
end

-- Apunta como en vuelo lo que acaba de gastar un crafteo.
local function ReserveMaterials(recipe)
    local items = Items()
    if not items then return end
    for _, m in ipairs((recipe and recipe.materials) or {}) do
        local qty = tonumber(m.qty) or 1
        local prev = reserved[m.key]
        local have = items.GetOwnedCount(m.key) or 0
        reserved[m.key] = {
            qty = (prev and prev.qty or 0) + qty,
            expected = math.max(0, have - qty),
            at = time(),
        }
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(RESERVE_TTL + 1, ReleaseSettledReservations)
    end
end

-- Devuelve: resolvable(bool, todos los materiales tienen ID), enough(bool, hay cantidad suficiente),
-- y una lista detallada por material { key, name, need, have, id, missingId }.
local function InspectMaterials(recipe)
    local items = Items()
    local detail, resolvable, enough = {}, true, true
    for _, m in ipairs((recipe and recipe.materials) or {}) do
        local id = items and items.GetId(m.key)
        -- El material ya comprometido por un crafteo anterior no vuelve a contar como disponible.
        local have = math.max(0, ((items and items.GetOwnedCount(m.key)) or 0) - ReservedQty(m.key))
        local need = tonumber(m.qty) or 1
        if not id then resolvable = false end
        if have < need then enough = false end
        detail[#detail + 1] = {
            key = m.key, name = (items and items.GetName(m.key)) or m.key,
            need = need, have = have, id = id, missingId = (id == nil),
        }
    end
    return resolvable, enough, detail
end

-- ¿Se puede intentar craftear? Devuelve ok, razon.
function API.CanCraft(recipeId)
    local r = API.GetRecipe(recipeId)
    if not r then return false, "Receta desconocida" end
    if not API.KnowsProfession(r.profession) then return false, "No conoces esa profesion" end
    if API.EffectiveSkill(r.profession) < (tonumber(r.skillReq) or 1) then
        return false, "Skill insuficiente (requiere " .. tostring(r.skillReq) .. ")"
    end
    if r.worldLearned and not Store().learned[r.id] then
        return false, "Receta no aprendida (se obtiene en el mundo)"
    end
    local resolvable, enough, detail = InspectMaterials(r)
    if not resolvable then return false, "Materiales pendientes de ID (aun no crafteable)", detail end
    local outId = Items() and Items().GetId(r.output and r.output.key)
    if not outId then return false, "Resultado pendiente de ID", detail end
    if not enough then return false, "Faltan materiales", detail end
    return true, nil, detail
end

-- Marca una receta worldLearned como aprendida (DM / hallazgo).
-- ¿Esta aprendida? Las recetas normales van con la profesion; las worldLearned requieren
-- que el DM las haya enseñado (LearnRecipe/TEACH).
function API.IsRecipeLearned(recipeId)
    local r = API.GetRecipe(recipeId)
    if not r then return false end
    if not r.worldLearned then return true end
    return Store().learned[tostring(recipeId)] == true
end

-- Tirada suelta de la herramienta de la profesion (sin receta ni CD): d20 + competencia de
-- herramienta (si la tiene) + modificador de la caracteristica. Es la prueba de "uso de
-- herramientas" de 5e, independiente de fabricar; la regla vive aqui, no en la UI.
function API.RollTool(profId)
    local def = API.GetDefinition(profId)
    if not def then return false end
    local d20 = math.random(1, 20)
    local bonus = ProfBonusIfTool(def) + AbilityMod(def.ability)
    local total = d20 + bonus
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = def.tool or def.name,
            total = total,
            dice = "d20: " .. d20,
            modifiers = bonus ~= 0 and string.format("%s%d", bonus > 0 and "+" or "", bonus) or "",
            critical = d20 == 20 and "CRITICO" or (d20 == 1 and "FALLO" or nil),
        })
    end
    return true, total
end

-- Copia del material en vuelo (solo diagnostico: no exponer la tabla interna).
function API.GetReservedMaterials()
    ReleaseSettledReservations()
    local out = {}
    for key, r in pairs(reserved) do
        out[key] = { qty = r.qty, expected = r.expected, at = r.at }
    end
    return out
end

-- Item id del resultado de una receta (para iconos/tooltips de UI).
function API.GetOutputItemId(recipeId)
    local r = API.GetRecipe(recipeId)
    local items = Items()
    if r and items and r.output then return items.GetId(r.output.key) end
    return nil
end

function API.LearnRecipe(recipeId)
    recipeId = tostring(recipeId or "")
    if API.GetRecipe(recipeId) then Store().learned[recipeId] = true; return true end
    return false
end

-- Sube skill al craftear con exito, estilo WoW: solo si aun aprendes de la receta (skill por debajo
-- del umbral "gris" = skillReq + 100) y por debajo del maximo.
local function SkillUp(profId, recipe)
    local cur = API.GetSkill(profId)
    -- Primer craft (conocia por competencia, skill 0): persiste el punto base = 1 (no saltar a 2).
    if cur <= 0 then API.SetSkill(profId, 1); return end
    local grey = (tonumber(recipe.skillReq) or 1) + 100
    if cur < API.MAX_SKILL and cur < grey then
        API.SetSkill(profId, cur + 1)
    end
end

-- Ejecuta el crafteo: tirada, consumo de materiales reales y entrega del output.
function API.Craft(recipeId)
    local ok, reason, detail = API.CanCraft(recipeId)
    if not ok then print("|cffff5555" .. tostring(reason) .. "|r"); return false, reason end
    local r = API.GetRecipe(recipeId)
    local def = API.GetDefinition(r.profession)
    local items = Items()
    local server = HarfordServerActions

    -- Tirada: d20 + competencia (si tiene la herramienta) + mod. caracteristica.
    local ability = r.ability or (def and def.ability) or "Inteligencia"
    local d20 = math.random(1, 20)
    local bonus = ProfBonusIfTool(def) + AbilityMod(ability)
    local total = d20 + bonus
    local dc = tonumber(r.dc) or 10
    local crit = (d20 == 20)
    local success = crit or (d20 ~= 1 and total >= dc)

    local outName = items.GetName(r.output.key)

    -- El crafteo es una ACCION REAL: se tira en mesa como cualquier otra prueba, no se
    -- resuelve en el chat local del artesano. Se emite siempre, salga bien o mal.
    if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
        HarfordDnDRolls.Broadcast({
            type = "roll",
            label = string.format("%s: %s (CD %d)", def and def.name or r.profession,
                r.name or outName, dc),
            total = total,
            dice = "d20: " .. d20,
            modifiers = bonus ~= 0 and string.format("%s%d", bonus > 0 and "+" or "", bonus) or "",
            critical = crit and "CRITICO" or (d20 == 1 and "FALLO" or nil),
        })
    end

    local function Announce(text)
        if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
            HarfordDnDRolls.Broadcast({ type = "info", label = text })
        else
            HarfordChat.Print(text)
        end
    end

    if not success then
        -- Fallo: por defecto NO gasta materiales (mas amable para RP). Cambiar si se quiere coste.
        Announce(string.format("falla al fabricar %s.", r.name or outName))
        return false, "fallo"
    end

    -- Consumir materiales reales. Se reservan ANTES de emitir los comandos: hasta que el servidor
    -- confirme el descuento, esa cantidad deja de contar como disponible para el siguiente crafteo.
    ReserveMaterials(r)
    for _, m in ipairs(r.materials or {}) do
        local id = items.GetId(m.key)
        if id and server and server.RemoveItem then server.RemoveItem(id, tonumber(m.qty) or 1) end
    end
    -- Entregar output (doble en critico).
    local outId = items.GetId(r.output.key)
    local outQty = (tonumber(r.output.qty) or 1) * (crit and 2 or 1)
    if outId and server and server.GiveItem then server.GiveItem(outId, outQty) end

    SkillUp(r.profession, r)
    Announce(string.format("fabrica %s x%d.%s", outName, outQty,
        crit and " |cffffd100Obra maestra: produccion doble.|r" or ""))
    return true
end

------------------------------------------------------------
-- Nodos de recoleccion en el mundo (vetas, plantas, bancos de peces).
--
-- El DM coloca un NPC/objeto de fase y su gossip ejecuta un ArcSpell que llama:
--     HarfordProfessions.GatherNode("min_cobre", 300)
-- (recipeId de una profesion de RECOLECCION + cooldown en segundos, opcional, 300 por defecto).
--
-- Mismo patron que HarfordWorldQuests: la identidad del nodo es el GUID de la unidad del gossip,
-- asi que hace falta tener el nodo como unidad activa (npc/target). El cooldown es POR NODO Y POR
-- PERSONAJE, persiste en HarfordProfessionsStore.nodeCooldowns y se aplica AL INTENTO (exito o
-- fallo): la tirada ya se hizo, el nodo queda "trabajado" y no se puede reintentar en bucle.
-- La tirada, materiales, entrega y anuncio son los de Craft(); esto solo añade la puerta de nodo.
------------------------------------------------------------
local function PruneNodeCooldowns()
    local cooldowns = Store().nodeCooldowns
    local now = time and time() or 0
    for guid, expira in pairs(cooldowns) do
        if (tonumber(expira) or 0) <= now then cooldowns[guid] = nil end
    end
end

function API.GatherNode(recipeId, cooldownSeconds)
    local r = API.GetRecipe(recipeId)
    if not r then print("|cffff5555Nodo mal configurado: receta desconocida (" .. tostring(recipeId) .. ").|r") return false end
    local def = API.GetDefinition(r.profession)
    if not (def and def.kind == "gather") then
        print("|cffff5555Los nodos de mundo son solo de recoleccion (" .. tostring(r.profession) .. " no lo es).|r")
        return false
    end
    local guid = (UnitExists and UnitExists("npc") and UnitGUID and UnitGUID("npc"))
        or (UnitExists and UnitExists("target") and UnitGUID and UnitGUID("target"))
    if not guid then
        print("|cffff5555No se detecta el nodo: interactua con la veta/planta (gossip o target).|r")
        return false
    end
    PruneNodeCooldowns()
    local cooldowns = Store().nodeCooldowns
    local now = time and time() or 0
    local expira = tonumber(cooldowns[guid]) or 0
    if expira > now then
        local resta = expira - now
        print(string.format("|cffffcc00Este nodo ya esta trabajado. Vuelve en %d min %d s.|r",
            math.floor(resta / 60), resta % 60))
        return false
    end
    -- Validar ANTES de consumir el nodo: si el personaje no puede ni intentarlo (no conoce la
    -- profesion, skill corto, item pendiente de ID), Craft avisara pero el nodo no debe gastarse.
    local puede, motivo = API.CanCraft(recipeId)
    if not puede then
        print("|cffff5555" .. tostring(motivo) .. "|r")
        return false
    end
    -- El INTENTO consume el nodo aunque la tirada falle: sin reintentos en bucle.
    cooldowns[guid] = now + math.max(30, math.floor(tonumber(cooldownSeconds) or 300))
    local ok = API.Craft(recipeId)
    return ok and true or false
end

------------------------------------------------------------
-- Enseñar recetas `worldLearned` (los remates a skill 300: planos, formulas, tomos).
--
-- El DM (HarfordAdmin + .ph dm) targetea al jugador y usa el menu de unidad
-- ("Profesiones > Enseñar receta") o llama `HarfordProfessions.TeachRecipe(nombre, recipeId)`.
-- Viaja como `TEACH|recipeId` por el prefix propio HARFORDPROF (WHISPER). El receptor solo
-- concede un beneficio (marcar la receta como aprendida), asi que basta el filtro estandar de
-- remitente reconocido; el gate de DM esta en el EMISOR, como en QDONE de las misiones.
------------------------------------------------------------
local COMM_PREFIX = "HARFORDPROF"

-- Recetas que se pueden enseñar (las marcadas worldLearned), para el menu del DM.
function API.GetTeachableRecipes()
    local out = {}
    for _, recipe in ipairs((Data() and Data().RECIPES) or {}) do
        if recipe.worldLearned then out[#out + 1] = recipe end
    end
    table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return out
end

function API.TeachRecipe(targetName, recipeId)
    if not (HarfordAuthority and HarfordAuthority.CanUseDMTools and HarfordAuthority.CanUseDMTools()) then
        print("|cffff5555Enseñar recetas requiere HarfordAdmin y .ph dm activo.|r")
        return false
    end
    local recipe = API.GetRecipe(recipeId)
    if not recipe then print("|cffff5555Receta desconocida: " .. tostring(recipeId) .. "|r") return false end
    if not recipe.worldLearned then
        print("|cffff5555Esa receta se aprende sola por skill; solo se enseñan las worldLearned.|r")
        return false
    end
    targetName = tostring(targetName or "")
    if targetName == "" then print("|cffff5555Falta el nombre del jugador.|r") return false end
    if not (HarfordSync and HarfordSync.Send) then print("|cffff5555HarfordSync no disponible.|r") return false end
    local ok, err = HarfordSync.Send(COMM_PREFIX, "TEACH|" .. tostring(recipe.id), "WHISPER", targetName)
    if ok then
        print(string.format("Receta |cffffd100%s|r enseñada a |cffffcc00%s|r.", tostring(recipe.name), targetName))
    else
        print("|cffff5555No se pudo enviar: " .. tostring(err) .. "|r")
    end
    return ok and true or false
end

local function IsTrustedSender(sender)
    sender = tostring(sender or "")
    if sender == "" then return false end
    if HarfordClassColors and HarfordClassColors.FindUnitByName then
        return HarfordClassColors.FindUnitByName(sender) ~= nil
    end
    return false
end

local comm = CreateFrame("Frame")
comm:RegisterEvent("PLAYER_LOGIN")
comm:RegisterEvent("CHAT_MSG_ADDON")
comm:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(COMM_PREFIX)
        end
        return
    end
    if prefix ~= COMM_PREFIX then return end
    if not IsTrustedSender(sender) then return end
    local recipeId = tostring(message or ""):match("^TEACH|([a-z_0-9]+)$")
    if not recipeId then return end
    local recipe = API.GetRecipe(recipeId)
    if not (recipe and recipe.worldLearned) then return end
    if Store().learned[recipeId] then
        print(string.format("Ya conocias la receta |cffffd100%s|r.", tostring(recipe.name)))
        return
    end
    API.LearnRecipe(recipeId)
    local short = (Ambiguate and Ambiguate(tostring(sender), "short")) or tostring(sender)
    print(string.format("|cff38d26aHas aprendido la receta:|r |cffffd100%s|r (enseñada por %s).",
        tostring(recipe.name), short))
end)
