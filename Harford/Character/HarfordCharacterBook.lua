-- HarfordCharacterBook: clasificacion y datos de PRESENTACION del Libro (pestaña tipo
-- spellbook de HarfordCharacterPanel). Logica PURA, sin estado del panel (`S`): categoria de
-- cada habilidad, etiquetas/colores/iconos por categoria y disparadores/efectos de reaccion.
-- La UI (RefreshBook, CreateBookPage, botones) sigue en HarfordCharacterPanel por su
-- acoplamiento a `S`. Carga en el .toc ANTES que HarfordCharacterPanel.

HarfordCharacterBook = HarfordCharacterBook or {}
local API = HarfordCharacterBook

local function IconPath(icon)
    icon = tostring(icon or "")
    if icon == "" or icon:find("\\", 1, true) then return icon end
    return "Interface\\Icons\\" .. icon
end

API.ICON = {
    activo   = "Interface\\Icons\\Ability_Warrior_BattleShout",
    forma    = "Interface\\Icons\\Ability_Druid_CatForm",
    reaccion = "Interface\\Icons\\Ability_Warrior_Revenge",
    pasivo   = "Interface\\Icons\\INV_Misc_Book_09",
    maniobra = "Interface\\Icons\\Ability_Warrior_Trauma",
    area     = "Interface\\Icons\\Spell_Fire_SelfDestruct",
    poder    = "Interface\\Icons\\Spell_Holy_PowerWordShield",
}

-- Id del daño condicional (conditionalWeaponDamage) declarado por una habilidad, si lo tiene.
-- Estas son las habilidades "al_accion": se preparan en el Libro y las consume el ataque.
function API.CondDamageId(feature)
    if not (feature and type(feature.effects) == "table") then return nil end
    for _, e in ipairs(feature.effects) do
        if type(e) == "table" and e.kind == "conditionalWeaponDamage" and e.id then
            return tostring(e.id)
        end
    end
    return nil
end

-- ¿La habilidad es una maniobra de energia (Mutilar/Garrote/Exponer Armadura)? Se ejecuta
-- al instante contra el objetivo gastando el recurso; la resuelve HarfordDnDStore.UseEnergyManeuver.
function API.IsEnergyManeuver(feature)
    if not (feature and type(feature.effects) == "table") then return false end
    for _, e in ipairs(feature.effects) do
        if type(e) == "table" and e.kind == "energyManeuver" then return true end
    end
    return false
end

function API.Category(feature)
    if not feature then return "pasivo" end
    -- Cambio de Forma no es un checkbox de configuracion: es una accion de
    -- combate que se abre exclusivamente desde el Libro de habilidades.
    if feature.id == "dru_cambio_forma" then return "forma" end
    -- Las Absoluciones son dones propios del sacerdote; algunas delegan su
    -- resolucion en el Compendio, pero no pasan a ser conjuros por ello.
    if feature.actionKind == "absolution" then return "absolution" end
    if feature.actionKind == "powerWord" then return "poder" end
    -- Marca del Cazador se activa sobre un objetivo y su dado se resuelve luego
    -- automaticamente al impactar a esa presa; no es un toggle de "Daño extra".
    if feature.actionKind == "huntersMark" then return "activo" end
    if type(feature.area) == "table" then return "area" end
    if feature.cast == "reaccion" then return "reaccion" end
    if API.IsEnergyManeuver(feature) then return "maniobra" end  -- ejecuta contra el objetivo
    if API.CondDamageId(feature) then return "al_accion" end  -- daño condicional preparable
    -- Un rasgo con usos propios debe poder activarse desde el Libro. Si su
    -- efecto es situacional, el uso se anuncia para resolverlo en mesa.
    if type(feature.uses) == "table" then return "activo" end
    if feature.type == "accion" or feature.type == "recurso" then return "activo" end
    return "pasivo"
end

API.REACTION_TRIGGER_TEXT = {
    damage_taken = "Daño recibido",
    drop_to_zero = "Caer a 0 PG",
    incoming_melee_attack = "Ataque cuerpo a cuerpo recibido",
    attack_hit = "Impacto de ataque recibido",
    dex_save_damage = "Daño por salvación de Destreza",
}

function API.ReactionTrigger(feature)
    if not feature then return nil end
    if feature.reactionTrigger then return tostring(feature.reactionTrigger) end
    if type(feature.reaction) == "table" and feature.reaction.trigger then
        return tostring(feature.reaction.trigger)
    end
    return nil
end

function API.ReactionEffect(feature)
    if not feature then return nil end
    if feature.reactionEffect then return tostring(feature.reactionEffect) end
    if type(feature.reaction) == "table" and feature.reaction.effect then
        return tostring(feature.reaction.effect)
    end
    return nil
end

-- Etiqueta de categoria visible en el boton (subtexto) y color asociado.
API.CAT_LABEL = {
    pasivo    = "Pasiva",
    activo    = "Activa",
    forma     = "Forma",
    reaccion  = "Reacción",
    al_accion = "Al atacar",   -- daño/efecto extra que preparas; lo consume tu ataque con arma
    maniobra  = "Maniobra",    -- se ejecuta al instante contra el objetivo gastando recurso
    area      = "Area",
    poder     = "Palabra",
    absolution = "Absolucion",
}
-- Colores de categoria. El subtexto del boton lleva CONTORNO negro (OUTLINE) para leerse sobre
-- el pergamino con textura, asi que usamos tonos VIVOS (un color apagado con contorno se ve sucio).
-- El tooltip (fondo oscuro) usa esta misma tabla.
API.CAT_COLOR = {
    pasivo    = { 0.92, 0.92, 0.92 },
    activo    = { 0.55, 1.00, 0.62 },
    forma     = { 0.45, 0.95, 0.45 },
    reaccion  = { 0.64, 0.84, 1.00 },
    al_accion = { 1.00, 0.84, 0.52 },
    maniobra  = { 1.00, 0.62, 0.62 },
    area      = { 1.00, 0.72, 0.32 },
    poder     = { 0.78, 0.72, 1.00 },
    absolution = { 1.00, 0.62, 0.30 },
}

-- Etiqueta visible de la categoria. "activo" se desglosa en "Accion" o "Adicional" segun el
-- coste de accion: el libro indica "Accion adicional" en la descripcion de las de bonus action.
function API.CategoryLabel(cat, feature)
    if cat == "activo" then
        local d = ((feature and feature.description) or ""):lower()
        if d:find("accion adicional", 1, true) or d:find("acción adicional", 1, true) then
            return "Adicional"
        end
        return "Accion"
    end
    return API.CAT_LABEL[cat] or "Pasiva"
end

-- ¿La habilidad parece magia (conjuro/truco/mana...)? El resumen de rasgos del panel las
-- filtra; el Libro las muestra en el tab de su clase.
function API.IsMagicLike(feature)
    local name = HarfordClassColors.StripAccents(feature and feature.name):lower()
    return name:find("conjuro", 1, true)
        or name:find("hechizo", 1, true)
        or name:find("truco", 1, true)
        or name:find("metamagia", 1, true)
        or name:find("fuente de magia", 1, true)
        or name:find("mana", 1, true)
end

local function NormalizeFeatureText(value)
    local text = HarfordClassColors.StripAccents(value):lower()
    return text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Marcador de eleccion de subclase (no es un rasgo real): el Libro lo oculta y el resumen
-- de rasgos lo resume como "Subclase <Clase>: <Subclase>".
local function IsSubclassMarkerFeature(feature)
    if type(feature) ~= "table" then return false end
    local desc = NormalizeFeatureText(feature.description)
    if not desc:find("concede rasgos", 1, true) then return false end
    if desc:find("eliges tu", 1, true) then return true end
    local name = NormalizeFeatureText(feature.name)
    return name:find("arquetipo", 1, true)
        or name:find("presencia", 1, true)
        or name:find("marca", 1, true)
        or name:find("senda", 1, true)
        or name:find("estudio", 1, true)
        or name:find("tradicion", 1, true)
        or name:find("camino", 1, true)
        or name:find("llamado", 1, true)
        or name:find("vinculo", 1, true)
end

function API.IsVisible(feature)
    return feature and feature.bookHidden ~= true and not IsSubclassMarkerFeature(feature)
end

-- Solo transforma la presentacion de una copia efimera. Los datos de reglas del Libro
-- (efectos, usos y elecciones) permanecen intactos en el rasgo original.
function API.PresentFeature(feature)
    local presentation = HarfordDnDData and HarfordDnDData.GetPresentation
        and HarfordDnDData.GetPresentation(feature and feature.name)
    if not presentation then return feature end
    local copy = {}
    for key, value in pairs(feature) do copy[key] = value end
    if presentation.description and presentation.description ~= "" then copy.description = presentation.description end
    if presentation.icon and presentation.icon ~= "" then
        copy.icon = "Interface\\Icons\\" .. presentation.icon
    end
    return copy
end

-- Construye las secciones del Libro (General + por clase/subclase) desde la progresion ya
-- resuelta. PURA: no toca estado del panel ni resuelve el perfil activo (el panel pasa
-- GetProgression()). Lee los libros de raza/trasfondo/dote/clase via sus modulos globales.
function API.BuildSections(data)
    data = data or {}
    local sections = {}

    -- Palabra de Poder es una eleccion que se convierte en varias habilidades reales.
    -- El Libro muestra cada palabra ya elegida por separado, pero conserva una referencia
    -- al rasgo padre para que recursos, reacciones y sincronizacion sigan usando su id estable.
    local function AddFeature(bucket, feature, level, source)
        if feature and feature.actionKind == "powerWord"
            and HarfordDnDBook and HarfordDnDBook.GetChoiceOption then
            -- Leer la eleccion del `data` recibido (no de GetChoice, que cae al perfil LOCAL): en
            -- inspeccion el libro debe mostrar las Palabras de Poder del perfil inspeccionado.
            local chosen = data.choices and data.choices[feature.id]
            local added = false
            for _, optionId in ipairs(chosen or {}) do
                local option = HarfordDnDBook.GetChoiceOption(feature, optionId)
                if option then
                    bucket[#bucket + 1] = {
                        feature = {
                            id = tostring(feature.id) .. "_" .. tostring(option.id),
                            name = option.label,
                            description = option.desc or feature.description,
                            actionKind = "powerWord",
                            powerWordParent = feature,
                            powerWordOption = option,
                            icon = IconPath(option.icon),
                        },
                        level = level or 0,
                        source = source,
                    }
                    added = true
                end
            end
            if added then return end
        end
        bucket[#bucket + 1] = { feature = API.PresentFeature(feature), level = level or 0, source = source }
    end

    local general = {}
    local function addList(list, src)
        for _, it in ipairs(list or {}) do
            if it.feature and API.IsVisible(it.feature) then
                AddFeature(general, it.feature, it.level, src)
            end
        end
    end
    if HarfordDnDRaces and HarfordDnDRaces.GetRaceTraits and type(data.race) == "table" and data.race.id ~= "" then
        addList(HarfordDnDRaces.GetRaceTraits(data.race.id, data.race.subraceId), "race")
    end
    if HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackgroundTraits and data.background and data.background ~= "" then
        addList(HarfordDnDBackgrounds.GetBackgroundTraits(data.background), "bg")
    end
    if HarfordDnDFeats and HarfordDnDFeats.GetFeatTraits and type(data.feats) == "table" and #data.feats > 0 then
        addList(HarfordDnDFeats.GetFeatTraits(data.feats), "feat")
    end
    sections[#sections + 1] = { label = "General", short = "Gen.", features = general, isGeneral = true }

    for i, entry in ipairs(data.classLevels or {}) do
        local clsName = (HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId)) or entry.classId
        local clsF, subF = {}, {}
        for _, it in ipairs((HarfordDnDBook.GetUnlockedFeatures and HarfordDnDBook.GetUnlockedFeatures({ entry })) or {}) do
            if API.IsVisible(it.feature) then
                local isSub = type(it.className) == "string" and it.className:find(" / ", 1, true)
                local bucket = isSub and subF or clsF
                AddFeature(bucket, it.feature, it.level, "class")
            end
        end
        sections[#sections + 1] = { label = tostring(clsName), short = tostring(clsName), features = clsF, classId = entry.classId }
        if #subF > 0 then
            local subName = (HarfordDnDBook.GetSubclassName and HarfordDnDBook.GetSubclassName(entry.classId, entry.subclassId)) or ""
            sections[#sections + 1] = { label = tostring(clsName) .. " - " .. tostring(subName), short = tostring(subName), features = subF, classId = entry.classId, subclassId = entry.subclassId }
        end
    end
    return sections
end
