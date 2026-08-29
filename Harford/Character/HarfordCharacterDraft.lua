-- Aplicacion del borrador de personaje: convertir lo elegido en el asistente en progresion
-- persistida, tanto al CREAR como al SUBIR de nivel.
--
-- Sale de HarfordCharacterAdvancement.lua porque es lo unico de ese fichero que no es UI: no crea
-- frames ni lee widgets, recibe el borrador y escribe progresion. Eso lo hace comprobable, que es
-- justo lo que interesa de la parte que decide el personaje de alguien.
--
-- Contrato que se conserva: la creacion confirma SOLO el nivel 1 y el asistente encadena despues
-- las subidas a 2 y 3; la subida parte de la progresion existente, sube UN nivel total y no
-- reescribe origen, caracteristicas ni equipo.

HarfordCharacterDraft = HarfordCharacterDraft or {}

-- Inyectadas por HarfordCharacterAdvancement.
local API, BaseScoreFor, ExpandedSpellNames, RequiredTotal, ResetCreationSpellState, S, SpellsForClass

function HarfordCharacterDraft.Init(deps)
    deps = deps or {}
    API = deps.API or API
    BaseScoreFor = deps.BaseScoreFor or BaseScoreFor
    ExpandedSpellNames = deps.ExpandedSpellNames or ExpandedSpellNames
    RequiredTotal = deps.RequiredTotal or RequiredTotal
    ResetCreationSpellState = deps.ResetCreationSpellState or ResetCreationSpellState
    S = deps.S or S
    SpellsForClass = deps.SpellsForClass or SpellsForClass
end

-- Habilidades en las que el BORRADOR ya es competente: rasgos de raza/subraza, de trasfondo y de
-- clase/subclase, mas las opciones de otras elecciones ya marcadas. Durante la creacion el PJ aun
-- no existe como perfil, asi que no se puede preguntar a HarfordDnDFeatureEffects.GetSkillRank:
-- hay que derivarlo de lo elegido en el asistente.
-- `excludeFeatureId`: al filtrar las opciones de una eleccion ABIERTA, lo marcado en ella misma
-- no debe contar como "ya lo tienes" -- desapareceria de su propia lista y no podria desmarcarse.
local function DraftSkillProficiencies(excludeFeatureId)
    local prof = {}
    local function ApplyEffects(effects)
        for _, effect in ipairs(effects or {}) do
            if effect.kind == "skillProf" and effect.skill then prof[effect.skill] = true end
        end
    end
    local function ApplyFeature(feature)
        if type(feature) ~= "table" then return end
        ApplyEffects(feature.effects)
        if excludeFeatureId and feature.id == excludeFeatureId then return end
        -- Una eleccion ya resuelta (p.ej. las dos habilidades del trasfondo) tambien da competencia.
        for _, optionId in ipairs(S.choiceSelections[feature.id] or {}) do
            local option = HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                and HarfordDnDBook.GetChoiceOption(feature, optionId)
            ApplyEffects(option and option.effects)
        end
    end
    local race = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
    for _, feature in ipairs((race and race.traits) or {}) do ApplyFeature(feature) end
    local subrace = HarfordDnDRaces and HarfordDnDRaces.GetSubrace
        and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
    for _, feature in ipairs((subrace and subrace.traits) or {}) do ApplyFeature(feature) end
    local background = HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(S.backgroundId)
    for _, feature in ipairs((background and background.traits) or {}) do ApplyFeature(feature) end
    for _, classId in ipairs({ S.classId, S.secondaryClassId }) do
        local classDef = classId and HarfordDnDBook and HarfordDnDBook.GetClass
            and HarfordDnDBook.GetClass(classId)
        for _, feature in ipairs((classDef and classDef.features) or {}) do ApplyFeature(feature) end
    end
    return prof
end

-- Idiomas que el borrador YA conoce, normalizados (sin acentos, minusculas): mismos origenes
-- que DraftSkillProficiencies mas, si el personaje ya existe como perfil (subida de nivel), los
-- idiomas vivos de FeatureEffects. Sirve para que el selector de "un idioma adicional" no
-- ofrezca los que ya se hablan: el Goblin veia Comun y Goblin en su propia lista.
local function DraftLanguages(excludeFeatureId)
    local conocidos = {}
    local function Normaliza(nombre)
        nombre = tostring(nombre or "")
        if HarfordClassColors and HarfordClassColors.StripAccents then
            nombre = HarfordClassColors.StripAccents(nombre)
        end
        return nombre:lower()
    end
    local function ApplyEffects(effects)
        for _, effect in ipairs(effects or {}) do
            if effect.kind == "language" and effect.language then
                conocidos[Normaliza(effect.language)] = true
            end
        end
    end
    local function ApplyFeature(feature)
        if type(feature) ~= "table" then return end
        ApplyEffects(feature.effects)
        if excludeFeatureId and feature.id == excludeFeatureId then return end
        for _, optionId in ipairs(S.choiceSelections[feature.id] or {}) do
            local option = HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                and HarfordDnDBook.GetChoiceOption(feature, optionId)
            ApplyEffects(option and option.effects)
        end
    end
    local race = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
    for _, feature in ipairs((race and race.traits) or {}) do ApplyFeature(feature) end
    local subrace = HarfordDnDRaces and HarfordDnDRaces.GetSubrace
        and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
    for _, feature in ipairs((subrace and subrace.traits) or {}) do ApplyFeature(feature) end
    local background = HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(S.backgroundId)
    for _, feature in ipairs((background and background.traits) or {}) do ApplyFeature(feature) end
    for _, classId in ipairs({ S.classId, S.secondaryClassId }) do
        local classDef = classId and HarfordDnDBook and HarfordDnDBook.GetClass
            and HarfordDnDBook.GetClass(classId)
        for _, feature in ipairs((classDef and classDef.features) or {}) do ApplyFeature(feature) end
    end
    -- Personaje ya existente (subida SIN borrador de origen): sus idiomas vivos cuentan. Con
    -- S.raceId puesto estamos CREANDO (quiza re-creando encima de una ficha vieja) y el perfil
    -- vivo es el anterior: mezclarlo filtraria idiomas por datos que van a ser sustituidos.
    if not S.raceId and HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetLanguages then
        for _, lang in ipairs(HarfordDnDFeatureEffects.GetLanguages() or {}) do
            conocidos[Normaliza(type(lang) == "table" and (lang.name or lang.id) or lang)] = true
        end
    end
    return conocidos
end

-- Competencias de ARMADURA y ARMA del borrador, como sets de tokens. Salen de los efectos
-- armorProf/weaponProf de los rasgos elegidos y de las listas armorProfs/weaponProfs de las
-- clases del plan. Para los prerequisitos de dote (Muy acorazado, Iniciado en el combate).
local function DraftEquipProficiencies(excludeFeatureId)
    local profs = { armor = {}, weapon = {} }
    local function ApplyEffects(effects)
        for _, effect in ipairs(effects or {}) do
            if effect.kind == "armorProf" and (effect.armor or effect.value) then
                profs.armor[tostring(effect.armor or effect.value)] = true
            elseif effect.kind == "weaponProf" and (effect.weapon or effect.value) then
                profs.weapon[tostring(effect.weapon or effect.value):lower()] = true
            end
        end
    end
    local function ApplyFeature(feature)
        if type(feature) ~= "table" then return end
        ApplyEffects(feature.effects)
        if excludeFeatureId and feature.id == excludeFeatureId then return end
        for _, optionId in ipairs(S.choiceSelections[feature.id] or {}) do
            local option = HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                and HarfordDnDBook.GetChoiceOption(feature, optionId)
            ApplyEffects(option and option.effects)
        end
    end
    local race = HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(S.raceId)
    for _, feature in ipairs((race and race.traits) or {}) do ApplyFeature(feature) end
    local subrace = HarfordDnDRaces and HarfordDnDRaces.GetSubrace
        and HarfordDnDRaces.GetSubrace(S.raceId, S.subraceId)
    for _, feature in ipairs((subrace and subrace.traits) or {}) do ApplyFeature(feature) end
    local background = HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground
        and HarfordDnDBackgrounds.GetBackground(S.backgroundId)
    for _, feature in ipairs((background and background.traits) or {}) do ApplyFeature(feature) end
    for _, classId in ipairs({ S.classId, S.secondaryClassId }) do
        local classDef = classId and HarfordDnDBook and HarfordDnDBook.GetClass
            and HarfordDnDBook.GetClass(classId)
        if classDef then
            for _, a in ipairs(classDef.armorProfs or {}) do profs.armor[tostring(a)] = true end
            for _, w in ipairs(classDef.weaponProfs or {}) do profs.weapon[tostring(w):lower()] = true end
            for _, feature in ipairs(classDef.features or {}) do ApplyFeature(feature) end
        end
    end
    return profs
end

-- Es lanzador? { class = tiene rasgo de clase (con sus puertas de nivel: medio desde 2,
-- tercio desde 3), any = eso o magia RACIAL (spellGrants/trucos de raza, incluidos los
-- elegidos, p.ej. Legado elfico) }. Borrador si hay plan de clases en S; si no, progresion.
local function DraftCasterInfo(excludeFeatureId)
    local clase = false
    local plan = {}
    if S.classId then
        plan[#plan + 1] = { classId = S.classId, subclassId = S.subclassId, level = S.primaryLevel }
        if S.secondaryClassId then
            plan[#plan + 1] = { classId = S.secondaryClassId, subclassId = S.secondarySubclassId, level = S.secondaryLevel }
        end
    elseif HarfordDnDProgression and HarfordDnDProgression.GetClassLevels then
        for _, e in ipairs(HarfordDnDProgression.GetClassLevels() or {}) do plan[#plan + 1] = e end
    end
    for _, e in ipairs(plan) do
        local classDef = HarfordDnDBook and HarfordDnDBook.GetClass and HarfordDnDBook.GetClass(e.classId)
        if classDef then
            local ct = classDef.casterType
            local sub = HarfordDnDBook.GetSubclass and HarfordDnDBook.GetSubclass(classDef.id, e.subclassId)
            if sub and sub.casterType then ct = sub.casterType end
            local nivel = tonumber(e.level) or 0
            if ct == "full" or ct == "pact" then
                if nivel >= 1 then clase = true end
            elseif ct == "half" then
                if nivel >= 2 then clase = true end
            elseif ct == "third" then
                if nivel >= 3 then clase = true end
            end
        end
    end
    local magia = false
    local raceId, subraceId = S.raceId, S.subraceId
    if (not raceId or raceId == "") and HarfordDnDProgression and HarfordDnDProgression.GetRace then
        local r = HarfordDnDProgression.GetRace()
        raceId, subraceId = r and r.id, r and r.subraceId
    end
    local function Mira(feature)
        if type(feature) ~= "table" then return end
        if (feature.spellGrants and #feature.spellGrants > 0)
            or (feature.cantripSpellIds and #feature.cantripSpellIds > 0) then magia = true end
        if feature.choice and not (excludeFeatureId and feature.id == excludeFeatureId) then
            local elegidos = S.choiceSelections[feature.id]
            if not elegidos and HarfordDnDProgression and HarfordDnDProgression.GetChoice then
                elegidos = HarfordDnDProgression.GetChoice(feature.id)
            end
            for _, optId in ipairs(elegidos or {}) do
                local opt = HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                    and HarfordDnDBook.GetChoiceOption(feature, optId)
                if opt and opt.spellId then magia = true end
            end
        end
    end
    local race = raceId and HarfordDnDRaces and HarfordDnDRaces.GetRace and HarfordDnDRaces.GetRace(raceId)
    for _, feature in ipairs((race and race.traits) or {}) do Mira(feature) end
    local subrace = race and HarfordDnDRaces.GetSubrace and HarfordDnDRaces.GetSubrace(raceId, subraceId)
    for _, feature in ipairs((subrace and subrace.traits) or {}) do Mira(feature) end
    return { class = clase, any = clase or magia }
end

local function BuildCreationDraft()
    local abilities = {}
    local array = S.attributeArrays and S.attributeArrays[S.selectedArray]
    for _, ability in ipairs(HarfordDnDData.ABIL or {}) do
        local base = BaseScoreFor(ability.key) or 0
        -- Guardar SOLO la base asignada: sumar aqui el bono racial lo contaba DOS veces, porque el
        -- asistente ya lo muestra sumado (`RaceAbilityBonus`). Quien lo hornea es
        -- `HarfordCharacterCreation.Apply`, con `GetCreationAbilityBonus` y tras fijar la
        -- progresion. OJO: los `bonus ability` NO se aplican en vivo (van al bucket
        -- `creationBonus` de FeatureEffects), asi que el draft por si solo no basta.
        abilities[ability.key] = base
    end
    local classes = {
        { classId = S.classId, subclassId = S.subclassId, level = S.primaryLevel },
    }
    if S.secondaryClassId then
        classes[#classes + 1] = { classId = S.secondaryClassId, subclassId = S.secondarySubclassId, level = S.secondaryLevel }
    end
    return {
        raceId = S.raceId,
        subraceId = S.subraceId,
        backgroundId = S.backgroundId, backgroundVariantId = S.backgroundVariantId,
        abilities = abilities,
        classes = classes,
        choices = S.choiceSelections,
        -- Equipo inicial: la eleccion de clase mas lo que aporta el trasfondo.
        equipment = (HarfordCharacterCreation and HarfordCharacterCreation.BuildStartingEquipment
            and HarfordCharacterCreation.BuildStartingEquipment(S.classId, S.equipmentPicks, S.backgroundId))
            or nil,
    }
end

-- Escribe los conjuros elegidos en el picker al compendio del PJ. Se llama ANTES de Apply para que
-- el About generado ya incluya las secciones de magia. Cantrips -> knownSpells (siempre); pool ->
-- knownSpells (known) o wizardBook (mago); preparados -> preparedSpells.
local function PersistSpellPicks(draft)
    if type(S.spellPicks) ~= "table" then return end
    local db = _G.HarfordCompendioCharacterDB
    local C = _G.HarfordCompendioAPI
    if type(db) ~= "table" then return end
    db.knownSpells = db.knownSpells or {}
    db.wizardBook = db.wizardBook or {}
    db.preparedSpells = db.preparedSpells or {}
    local poolMode = "known"
    for _, entry in ipairs((draft and draft.classes) or {}) do
        local cls = HarfordDnDBook.GetClass(entry.classId)
        local name = cls and cls.name
        -- Mismo orden que el selector: la subclase manda sobre la clase.
        local casting
        if name and C and C.GetClassCasting then
            local sub = HarfordDnDBook.GetSubclass(entry.classId, entry.subclassId)
            if sub then casting = C.GetClassCasting(name .. " " .. sub.name) end
            casting = casting or C.GetClassCasting(name)
        end
        if casting then poolMode = casting.mode; break end
    end
    local poolTbl = poolMode == "wizard_book" and db.wizardBook or db.knownSpells

    -- PODA: lo que el selector gobierna y ya no esta marcado, se retira. Ver la nota de arriba
    -- sobre por que se acota por clase y por tipo.
    -- Los conjuros de las Listas Ampliadas tambien tienen que entrar en la poda: si no, al
    -- deseleccionar uno se quedaria en la ficha para siempre.
    local ampliados = {}
    for _, entry in ipairs((draft and draft.classes) or {}) do
        for nombre in pairs(ExpandedSpellNames(entry.classId, entry.subclassId) or {}) do
            ampliados[nombre] = true
        end
    end
    if not next(ampliados) then ampliados = nil end

    local picks = S.spellPicks
    for className in pairs(picks.sembradas or {}) do
        for _, spell in ipairs((SpellsForClass and SpellsForClass(className, "cantrip", 9, ampliados)) or {}) do
            if db.knownSpells[spell.id] and not (picks.cantrips or {})[spell.id] then
                db.knownSpells[spell.id] = nil
            end
        end
        for _, spell in ipairs((SpellsForClass and SpellsForClass(className, "spell", 9, ampliados)) or {}) do
            if poolTbl[spell.id] and not (picks.spells or {})[spell.id] then
                poolTbl[spell.id] = nil
            end
            if (picks.usaPreparados or {})[className]
                and db.preparedSpells[spell.id] and not (picks.prepared or {})[spell.id] then
                db.preparedSpells[spell.id] = nil
            end
        end
    end

    for id in pairs(picks.cantrips or {}) do db.knownSpells[id] = true end
    for id in pairs(picks.spells or {}) do poolTbl[id] = true end
    for id in pairs(picks.prepared or {}) do db.preparedSpells[id] = true end

    -- Conjuros CONCEDIDOS por un rasgo (Maestro de maldiciones, Piromaniaco): el manual dice que
    -- NO cuentan contra los conjuros conocidos, asi que no pasan por el selector ni por su limite.
    -- Va al FINAL a proposito: los tres son conjuros de Brujo, y la poda de arriba los borraria por
    -- no estar marcados en el picker.
    if HarfordDnDBook and HarfordDnDBook.GetUnlockedFeatures then
        -- Un rasgo con `requiresOption` solo concede si esa opcion esta ELEGIDA. Lo necesitan los
        -- Conjuros de Vinculo del Chaman Elemental, que dependen de la Afinidad Elemental. El
        -- GetUnlockedFeatures del LIBRO no filtra por eleccion (el de la progresion si), asi que
        -- el filtro va aqui, sobre las elecciones del draft.
        local elegidas = {}
        for _, seleccion in pairs((draft and draft.choices) or {}) do
            for _, optId in pairs(seleccion or {}) do elegidas[tostring(optId)] = true end
        end
        for _, item in ipairs(HarfordDnDBook.GetUnlockedFeatures((draft and draft.classes) or {}) or {}) do
            local feature = item and item.feature
            local req = feature and feature.requiresOption
            if not req or elegidas[tostring(req)] then
                for _, spellId in ipairs((feature and feature.grantedSpells) or {}) do
                    db.knownSpells[tostring(spellId)] = true
                end
            end
        end
    end
end

local function FinishCreation()
    local draft = BuildCreationDraft()
    ResetCreationSpellState()
    PersistSpellPicks(draft)  -- conjuros al compendio ANTES de generar el About
    -- OJO: `X and Y and Y(draft)` truncaba los 2 retornos de Apply a uno, perdiendo el MOTIVO del
    -- error (siempre salia "nil"). Capturar ambos valores con una llamada directa.
    local ok, result
    if HarfordCharacterCreation and HarfordCharacterCreation.Apply then
        ok, result = HarfordCharacterCreation.Apply(draft)
    else
        result = "Modulo de creacion (HarfordCharacterCreation) no disponible."
    end
    if not ok then
        if HarfordChat and HarfordChat.Print then HarfordChat.Print("|cffff5555No se pudo crear la ficha: " .. tostring(result) .. "|r") end
        return
    end
    if HarfordChat and HarfordChat.Print then
        HarfordChat.Print("|cff38d26aFicha creada a nivel 1 y About de TRP3 generado.|r")
    end
    S.frame:Hide()
    -- Encadenar las subidas de creacion: nivel 2 y nivel 3 pasan por el asistente de
    -- subida normal, uno a uno, abriendose solos hasta alcanzar el objetivo.
    S.autoLevelTarget = 3
    if API.OpenLevelUp then API.OpenLevelUp() end
end

-- Aplica SOLO el nivel preparado por el asistente. A diferencia de la creacion,
-- conserva raza, trasfondo, caracteristicas, equipo y elecciones ya existentes.
local function FinishLevelUp()
    if not (HarfordDnDProgression and HarfordDnDProgression.SetClassEntry) then
        if HarfordChat and HarfordChat.Print then HarfordChat.Print("No se puede aplicar la subida: progresion no disponible.") end
        return
    end
    if S.primaryLevel + S.secondaryLevel ~= RequiredTotal() then return end

    local entries = {
        { classId = S.classId, subclassId = S.subclassId, level = S.primaryLevel },
    }
    if S.secondaryClassId then
        entries[#entries + 1] = { classId = S.secondaryClassId, subclassId = S.secondarySubclassId, level = S.secondaryLevel }
    end
    for index, entry in ipairs(entries) do
        local ok, err = HarfordDnDProgression.SetClassEntry(index, entry.classId, entry.subclassId, entry.level)
        if not ok then
            if HarfordChat and HarfordChat.Print then HarfordChat.Print("No se pudo aplicar la subida: " .. tostring(err)) end
            return
        end
    end
    for _, feature in ipairs(S.pendingFeatures or {}) do
        for slot, optionId in ipairs(S.choiceSelections[feature.id] or {}) do
            HarfordDnDProgression.SetChoiceSlot(feature.id, slot, optionId)
            -- Si la eleccion fue una DOTE, hay que activarla: su opcion no lleva `effects`, lo
            -- que aplica son los rasgos de la dote via `progression.feats`.
            local opcion = HarfordDnDBook and HarfordDnDBook.GetChoiceOption
                and HarfordDnDBook.GetChoiceOption(feature, optionId)
            if opcion and opcion.feat and HarfordDnDProgression.SetFeatEnabled then
                HarfordDnDProgression.SetFeatEnabled(opcion.feat, true)
            end
            -- Un truco elegido en una eleccion se concede aqui: su opcion no lleva `effects`
            -- porque el motor de efectos no sabe conceder conjuros.
            if opcion and opcion.spellId and type(_G.HarfordCompendioCharacterDB) == "table" then
                local db = _G.HarfordCompendioCharacterDB
                db.knownSpells = db.knownSpells or {}
                db.knownSpells[opcion.spellId] = true
            end
        end
    end
    PersistSpellPicks({ classes = entries, choices = S.choiceSelections })
    -- El About de TRP3, de mas a menos capaz. La mecanica de la subida YA quedo aplicada arriba,
    -- asi que ninguno de estos caminos puede dejarla a medias:
    --   1. Harford genero el About  -> se regenera entero (conservando frames ajenos).
    --   2. Ficha llevada a mano     -> NO se regenera, pero se INTENTA anadir lo del nivel nuevo
    --                                  en un frame propio, sin tocar nada de lo suyo.
    --   3. Ni eso                   -> se le pide que lo actualice a mano, diciendo que anadir.
    local C = HarfordCharacterCreation
    local aboutHecho = false
    if C and C.RewriteAbout and C.CanRewriteAbout and C.CanRewriteAbout() then
        aboutHecho = C.RewriteAbout() and true or false
    elseif C and C.SyncAboutAdditive then
        -- Ficha llevada a mano: se actualiza TODO lo que la subida cambia (nivel, caracteristicas,
        -- rasgos de clase y subclase, conjuros, dotes) pero sin regenerar su perfil: solo se
        -- sustituye el frame de Ficha, que es dato puro, y a los demas se les anaden los bloques
        -- que les falten. Su texto propio no se toca ni se mueve.
        local ok, detalle = C.SyncAboutAdditive()
        aboutHecho = ok and true or false
        if aboutHecho and HarfordChat and HarfordChat.Print then
            HarfordChat.Print("Tu About de TRP3 no lo genera Harford: se ha actualizado sin tocar "
                .. "tu texto (" .. tostring(detalle or "") .. ").")
        end
    end
    if not aboutHecho and HarfordChat and HarfordChat.Print then
        HarfordChat.Print("|cffffcc00Subida aplicada en la ficha, pero no se pudo actualizar el "
            .. "About de TRP3: actualizalo a mano.|r")
        local nuevos = {}
        for _, feature in ipairs(S.pendingFeatures or {}) do
            if feature and feature.name then nuevos[#nuevos + 1] = tostring(feature.name) end
        end
        if #nuevos > 0 then
            HarfordChat.Print("   Este nivel anade: " .. table.concat(nuevos, ", "))
        end
    end

    -- La XP acompana al nivel recien alcanzado. Es un suelo: si ya ibas por delante no se toca,
    -- porque la XP puede adelantarse al nivel (es lo que enciende el aviso de subida).
    if HarfordCharacterXP and HarfordCharacterXP.SyncToCharacterLevel then
        HarfordCharacterXP.SyncToCharacterLevel("subida de nivel")
    end
    if HarfordCharacterPanel and HarfordCharacterPanel.Refresh then HarfordCharacterPanel.Refresh() end
    if HarfordChat and HarfordChat.Print then
        HarfordChat.Print("|cff38d26aSubida de nivel aplicada.|r")
    end
    S.frame:Hide()
    -- Cadena de creacion: si venimos del asistente de creacion, seguir subiendo
    -- automaticamente hasta el nivel objetivo (3), un nivel por pasada.
    if S.autoLevelTarget then
        local total = HarfordDnDProgression.GetTotalLevel and HarfordDnDProgression.GetTotalLevel() or 0
        if total < S.autoLevelTarget then
            if API.OpenLevelUp then API.OpenLevelUp() end
            return
        end
        S.autoLevelTarget = nil
        if HarfordChat and HarfordChat.Print then
            HarfordChat.Print("|cff38d26aCreacion completada: ficha a nivel " .. total .. ".|r")
        end
    end
end

HarfordCharacterDraft.DraftSkillProficiencies = DraftSkillProficiencies
HarfordCharacterDraft.DraftLanguages = DraftLanguages
HarfordCharacterDraft.DraftEquipProficiencies = DraftEquipProficiencies
HarfordCharacterDraft.DraftCasterInfo = DraftCasterInfo
HarfordCharacterDraft.BuildCreationDraft = BuildCreationDraft
HarfordCharacterDraft.PersistSpellPicks = PersistSpellPicks
HarfordCharacterDraft.FinishCreation = FinishCreation
HarfordCharacterDraft.FinishLevelUp = FinishLevelUp
