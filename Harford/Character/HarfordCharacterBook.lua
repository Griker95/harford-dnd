-- HarfordCharacterBook: clasificacion y datos de PRESENTACION del Libro (pestaña tipo
-- spellbook de HarfordCharacterPanel). Logica PURA, sin estado del panel (`S`): categoria de
-- cada habilidad, etiquetas/colores/iconos por categoria y disparadores/efectos de reaccion.
-- La UI (RefreshBook, CreateBookPage, botones) sigue en HarfordCharacterPanel por su
-- acoplamiento a `S`. Carga en el .toc ANTES que HarfordCharacterPanel.

HarfordCharacterBook = HarfordCharacterBook or {}
local API = HarfordCharacterBook

-- Publica: la usa tambien el panel para pintar la barra de accion. Era local, y desde fuera
-- resolvia a nil, asi que la barra reventaba en cada arrastre.
function API.IconPath(icon)
    icon = tostring(icon or "")
    if icon == "" or icon:find("\\", 1, true) then return icon end
    return "Interface\\Icons\\" .. icon
end
local IconPath = API.IconPath

API.ICON = {
    activo   = "Interface\\Icons\\Ability_Warrior_BattleShout",
    forma    = "Interface\\Icons\\Ability_Druid_CatForm",
    reaccion = "Interface\\Icons\\Ability_Warrior_Revenge",
    pasivo   = "Interface\\Icons\\INV_Misc_Book_09",
    maniobra = "Interface\\Icons\\Ability_Warrior_Trauma",
    area     = "Interface\\Icons\\Spell_Fire_SelfDestruct",
    poder    = "Interface\\Icons\\Spell_Holy_PowerWordShield",
    acompanante = "Interface\\Icons\\Spell_Shadow_RaiseDead",
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

-- Un rasgo cuyas OPCIONES ELEGIDAS se convierten en habilidades propias del Libro. Palabra de
-- Poder fue el primero y le dio nombre al marcador; `optionAbility` es el generico para los demas
-- (brebajes del Monje, trampas del Cazador, maldiciones del Brujo, ataques del Chaman).
function API.IsOptionAbility(feature)
    if type(feature) ~= "table" then return false end
    local k = feature.actionKind
    return k == "powerWord" or k == "optionAbility"
end

function API.Category(feature)
    if not feature then return "pasivo" end
    -- Cambio de Forma no es un checkbox de configuracion: es una accion de
    -- combate que se abre exclusivamente desde el Libro de habilidades.
    if feature.id == "dru_cambio_forma" then return "forma" end
    -- Las Absoluciones son dones propios del sacerdote; algunas delegan su
    -- resolucion en el Compendio, pero no pasan a ser conjuros por ello.
    -- `category` es PRESENTACION declarada (etiqueta y color del boton), no comportamiento. Las
    -- Absoluciones del Sacerdote la usan para distinguirse; su mecanica es la normal de un rasgo.
    -- El rasgo concede criatura(s) acompanante(s): su boton abre el selector de
    -- invocar/despedir/ordenar, igual que Cambio de Forma abre el de formas. `companionId` es una
    -- criatura concreta; `companions` son varias y se elige cual al invocar (los 5 demonios del
    -- brujo). Que criaturas salen lo decide HarfordDnDCompanions por clase, nivel y elecciones.
    if feature.companionId or feature.companions then return "acompanante" end
    if feature.category then return tostring(feature.category) end
    if API.IsOptionAbility(feature) then return feature.actionKind == "powerWord" and "poder" or "activo" end
    -- Marca del Cazador se activa sobre un objetivo y su dado se resuelve luego
    -- automaticamente al impactar a esa presa; no es un toggle de "Daño extra".
    if feature.actionKind == "huntersMark" then return "activo" end
    if type(feature.area) == "table" then return "area" end
    if feature.cast == "reaccion" then return "reaccion" end
    if API.IsEnergyManeuver(feature) then return "maniobra" end  -- ejecuta contra el objetivo
    if API.CondDamageId(feature) then return "al_accion" end  -- daño condicional preparable
    -- `usesArePool`: el rasgo NO es una accion, es la reserva que gastan otros mediante
    -- `usesFrom` (Corrupcion y sus Maldiciones). Pulsarlo quemaria un uso sin invocar nada.
    if feature.usesArePool then return "pasivo" end
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
    acompanante = "Criatura",
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
    acompanante = { 0.72, 0.90, 0.62 },
}

-- Etiqueta visible de la categoria. "activo" se desglosa en "Accion" o "Adicional" segun el
-- coste de accion: el libro indica "Accion adicional" en la descripcion de las de bonus action.
function API.CategoryLabel(cat, feature)
    -- Una maniobra declarada como tal en el libro se etiqueta como maniobra aunque su mecanica
    -- sea la de dano condicional: para el jugador son lo mismo (Carga, Desarme, Golpe heroico).
    if cat == "al_accion" and feature and feature.type == "maniobra" then
        return API.CAT_LABEL.maniobra
    end
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
    return (text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))  -- parentesis: gsub devuelve 2 valores
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

-- Expuesto porque el generador del About necesita el mismo criterio que el Libro para no
-- escribir los marcadores de subclase como si fueran rasgos.
API.IsSubclassMarker = IsSubclassMarkerFeature

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
        if feature and API.IsOptionAbility(feature)
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
                            actionKind = feature.actionKind,
                            powerWordParent = feature,
                            powerWordOption = option,
                            -- `cast` y el coste viajan con la habilidad sintetizada: son lo que
                            -- mira la economia de turno y el gasto de recurso.
                            cast = option.cast or feature.cast,
                            resourceKey = option.resourceKey,
                            resourceCost = option.resourceCost,
                            area = option.area,
                            icon = IconPath(option.icon),
                            -- Lo que la opcion declara como MECANICA viaja con ella: es lo que
                            -- mira el resolvedor para saber si la resuelve un motor (maniobra,
                            -- area, concesion de recurso, dano condicional) o si solo se anuncia.
                            maneuver = option.maneuver,
                            grant = option.grant,
                            trap = option.trap,
                            saveAbility = option.saveAbility,
                            -- La CD la fija la caracteristica de lanzamiento de la CLASE, no la
                            -- opcion: se hereda del rasgo padre salvo que la opcion la cambie.
                            dcAbility = option.dcAbility or feature.dcAbility,
                            -- Los usos son del rasgo PADRE (una reserva compartida por todas sus
                            -- opciones), asi que gastar cualquiera descuenta del mismo contador.
                            usesFrom = feature.usesFrom or (feature.uses and feature.id) or nil,
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

    -- Un rasgo con `requiresOption` es la CONSECUENCIA de una eleccion: solo existe si esa opcion
    -- esta elegida. Lo respetaban la creacion, la subida, el borrador y los acompanantes, pero NO
    -- el Libro, que los pintaba todos: las ocho Maldiciones del Brujo cuando solo se elige una, y
    -- lo mismo con los brebajes del Monje, las trampas del Cazador y los ataques del Chaman.
    --
    -- Una opcion cuenta como elegida si aparece en CUALQUIER seleccion del perfil, igual que en
    -- `OpcionElegida` de la creacion: la misma opcion puede venir de dos elecciones distintas (el
    -- Brujo elige Maldiciones a nivel 2 y otra mas a nivel 6).
    local opcionesElegidas = {}
    for _, seleccion in pairs(data.choices or {}) do
        for _, optId in pairs(seleccion or {}) do opcionesElegidas[tostring(optId)] = true end
    end
    local function OpcionConcedida(feature)
        local req = feature and feature.requiresOption
        if not req then return true end
        return opcionesElegidas[tostring(req)] == true
    end

    local general = {}
    local function addList(list, src)
        for _, it in ipairs(list or {}) do
            if it.feature and API.IsVisible(it.feature) and OpcionConcedida(it.feature) then
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
    -- Una entrada POR DOTE, no una por cada cosa que hace: `GetFeatTraits` las devuelve sueltas y
    -- el Libro las pintaba como habilidades independientes, asi que la dote no salia por su
    -- nombre en ninguna parte.
    if HarfordDnDFeats and HarfordDnDFeats.GetFeatAbilities and type(data.feats) == "table" and #data.feats > 0 then
        addList(HarfordDnDFeats.GetFeatAbilities(data.feats), "feat")
    end
    -- «Competencias» e «Idiomas» son FIJAS: no dependen de que una raza o un trasfondo declaren
    -- un rasgo con ese nombre. Competencias venia del trasfondo (41 de 52 lo declaran) e Idiomas
    -- de la raza, asi que un PJ sin trasfondo se quedaba sin la primera, y las competencias de
    -- armadura y arma vienen sobre todo de la CLASE.
    --
    -- Los rasgos reales con esos nombres se RETIRAN para no duplicar la fila: su contenido ya lo
    -- agrega el tooltip, que lee las competencias e idiomas efectivos del personaje.
    do
        local fijas = {
            { id = "harford_competencias", name = "Competencias", icon = "Interface"
                .. string.char(92) .. "Icons" .. string.char(92) .. "inv_scroll_11" },
            { id = "harford_idiomas", name = "Idiomas", icon = "Interface" .. string.char(92)
                .. "Icons" .. string.char(92) .. "inv_misc_note_05" },
        }

        -- ACCIONES BASICAS. Las tiene cualquiera, no dependen de clase ni de nivel, asi que van
        -- aqui con Competencias e Idiomas y no en la seccion de ninguna clase. `basicAction` es lo
        -- que las distingue de un rasgo: el Libro las manda a su propio catalogo.
        for _, acc in ipairs((HarfordDnDActions and HarfordDnDActions.GetOrdered and
            HarfordDnDActions.GetOrdered()) or {}) do
            fijas[#fijas + 1] = {
                -- Sin `icon`: el arte sale del catalogo por el id, que es la fuente unica.
                id = "harford_accion_" .. tostring(acc.id), name = acc.name,
                description = acc.description, cast = acc.cast, type = "accion",
                basicAction = acc.id,
            }
        end
        -- Solo Competencias e Idiomas retiran el rasgo real que se llame igual: su contenido ya lo
        -- agrega el tooltip. Las acciones basicas NO deben hacerlo -- borrarian por el nombre un
        -- rasgo de clase que se llamase parecido, y eso desaparece sin dar ningun error.
        local esFija = { Competencias = true, Idiomas = true }

        local limpio = {}
        for _, it in ipairs(general) do
            local nombre = it.feature and tostring(it.feature.name or "")
            if not esFija[nombre] then limpio[#limpio + 1] = it end
        end
        -- Al FINAL de General y en su orden: son entradas de consulta, no rasgos del personaje,
        -- y no deben desplazar a los rasgos reales de raza y trasfondo.
        for _, f in ipairs(fijas) do
            limpio[#limpio + 1] = {
                feature = {
                    id = f.id, name = f.name, icon = f.icon,
                    -- Competencias e Idiomas son de consulta (pasivas); las acciones basicas se
                    -- USAN, y su coste y descripcion tienen que llegar tal cual se declararon.
                    type = f.type or "pasivo",
                    description = f.description or "",
                    cast = f.cast,
                    basicAction = f.basicAction,
                },
                level = 0,
                source = "core",
            }
        end
        general = limpio
    end
    sections[#sections + 1] = { label = "General", short = "Gen.", features = general, isGeneral = true }

    for i, entry in ipairs(data.classLevels or {}) do
        local clsName = (HarfordDnDBook.GetClassName and HarfordDnDBook.GetClassName(entry.classId)) or entry.classId
        local clsF, subF = {}, {}
        for _, it in ipairs((HarfordDnDBook.GetUnlockedFeatures and HarfordDnDBook.GetUnlockedFeatures({ entry })) or {}) do
            if API.IsVisible(it.feature) and OpcionConcedida(it.feature) then
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
