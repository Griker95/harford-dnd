-- Menus y riders de habilidades del Libro, extraidos de HarfordDnD.lua (fase C de
-- refactorizacion): Maldiciones del Brujo, conversion de espacios, Furia Elemental,
-- Penitencia, Expiacion, Legado del Vacio, riders del Monje y castigos por ranura.
-- Cada bloque cuelga sus funciones de HarfordDnDStore, igual que antes: ningun llamador cambia.
--
-- Lo que necesitan de la ficha llega por Init(deps) al FINAL de la carga de HarfordDnD.lua
-- (varias dependencias son de asignacion adelantada alli y antes serian nil). Los wrappers de
-- abajo conservan los NOMBRES originales para que los cuerpos extraidos queden intactos.

HarfordDnDBookActions = HarfordDnDBookActions or {}

local D = {}
local SheetContext = {}  -- alias estable; Init lo sustituye por el real

function HarfordDnDBookActions.Init(deps)
    for k, v in pairs(deps or {}) do D[k] = v end
    if deps and deps.SheetContext then SheetContext = deps.SheetContext end
end

local function Print(msg) return D.Print(msg) end
local function GetResourceCurrent(key) return D.GetResourceCurrent(key) end
local function AdjustResourceCurrent(key, delta) return D.AdjustResourceCurrent(key, delta) end
local function GetSpellAbilityKey() return D.GetSpellAbilityKey() end
local function GetWeaponDef(key) return D.GetWeaponDef(key) end
local function RefreshMainUI() return D.RefreshMainUI() end
local function fmtSigned(n) return D.fmtSigned(n) end

-- Maldiciones del Brujo (Estudio de la Afliccion). Gastan un uso de Corrupcion (`usesFrom`) y,
-- opcionalmente, un fragmento de alma para AMPLIAR. El manual deja decidir el ampliado en el
-- momento de invocarla, asi que se pregunta al pulsar en vez de dejarlo preparado de antemano.
do
    local bookMaledictionFeature
    local bookMaledictionMenu = CreateFrame("Frame", "HarfordBookMaledictionMenu", UIParent, "UIDropDownMenuTemplate")

    local function UseMalediction(feature, amplificada)
        if SheetContext and SheetContext.active then return false end
        if not feature then return false end
        local profileName = UnitName and UnitName("player") or "Personaje"
        local usesId = feature.usesFrom or feature.id

        -- El fragmento se comprueba ANTES de gastar el uso: si no hay, no se pierde la Corrupcion.
        if amplificada and GetResourceCurrent("soul_shard") < 1 then
            Print("No tienes fragmentos de alma para ampliar " .. tostring(feature.name or "la Maldicion") .. ".")
            return false
        end
        if not (HarfordDnDFeatureUses and HarfordDnDFeatureUses.Spend) then return false end
        if not HarfordDnDFeatureUses.Spend(usesId, profileName) then
            Print("No quedan usos de Corrupcion.")
            return false
        end
        if amplificada then AdjustResourceCurrent("soul_shard", -1) end

        HarfordDnDRolls.BroadcastAbility(feature, {
            targetUnit = (UnitExists and UnitExists("target")) and "target" or nil,
        })
        if amplificada then
            HarfordDnDRolls.Broadcast({
                type = "info",
                label = "|cffb388ff[Ampliada]|r " .. tostring(feature.name or "Maldicion"),
            })
        end
        -- Lo que le hace a la victima se resuelve DESPUES: la Corrupcion se gasta al invocarla,
        -- supere o no la salvacion. Solo las Maldiciones que declaran area llegan aqui.
        if feature.area and HarfordCharacterPanel and HarfordCharacterPanel.AbrirAreaDeRasgo then
            HarfordCharacterPanel.AbrirAreaDeRasgo(feature)
        end
        return true
    end

    UIDropDownMenu_Initialize(bookMaledictionMenu, function()
        local feature = bookMaledictionFeature
        if not feature then return end
        local info = UIDropDownMenu_CreateInfo()
        info.text = tostring(feature.name or "Maldicion") .. " (1 uso de Corrupcion)"
        info.func = function()
            UseMalediction(feature, false)
            CloseDropDownMenus()
            if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
                HarfordCharacterPanel.RefreshBookIfShown()
            end
        end
        UIDropDownMenu_AddButton(info)

        local fragmentos = GetResourceCurrent("soul_shard")
        local amp = UIDropDownMenu_CreateInfo()
        amp.text = "Ampliada (1 uso + 1 fragmento)"
        amp.disabled = fragmentos < 1
        amp.func = function()
            UseMalediction(feature, true)
            CloseDropDownMenus()
            if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
                HarfordCharacterPanel.RefreshBookIfShown()
            end
        end
        UIDropDownMenu_AddButton(amp)
    end, "MENU")

    -- Sin fragmentos no hay nada que elegir: se invoca directa y no se abre un menu de una sola opcion.
    function HarfordDnDStore.OpenMaledictionMenu(feature, anchor)
        if not feature then return end
        if GetResourceCurrent("soul_shard") < 1 then
            UseMalediction(feature, false)
            if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
                HarfordCharacterPanel.RefreshBookIfShown()
            end
            return
        end
        bookMaledictionFeature = feature
        ToggleDropDownMenu(1, nil, bookMaledictionMenu, anchor or "cursor", 0, 0)
end
end

-- LANZAMIENTO FLEXIBLE (Mago) / DEVOCION (Sacerdote): puntos <-> espacios de conjuro.
-- Todo dentro de un do...end: este fichero esta en el limite de 200 locales de Lua 5.1 y estos
-- tres no deben subir al scope del chunk.
do
    local slotMenu = CreateFrame("Frame", "HarfordBookSlotMenu", UIParent, "UIDropDownMenuTemplate")
    local slotFeature

    local function RefrescarVistas()
        if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
            HarfordCharacterPanel.RefreshBookIfShown()
        end
        if HarfordCharacterSpellbook and HarfordCharacterSpellbook.RefreshSpells then
            HarfordCharacterSpellbook.RefreshSpells()
        end
        RefreshMainUI()
    end

    UIDropDownMenu_Initialize(slotMenu, function()
        local feature = slotFeature
        local conv = feature and feature.slotConversion
        if not conv then return end
        local recurso = tostring(conv.resource or "")
        -- Nombre visible del recurso: "Puntos de Hechiceria" / "Puntos de Fe". Sale de la tabla
        -- de recursos para que un cambio de etiqueta se refleje aqui sin tocar nada.
        local def = HarfordDnDResources and HarfordDnDResources.DEFS and HarfordDnDResources.DEFS[recurso]
        local etiqueta = (def and def.label) or "puntos"

        if conv.mode == "create" then
            local lista = HarfordDnDMana.GetCreatableSlots(recurso)
            for _, e in ipairs(lista) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = string.format("Espacio de nivel %d  (%d %s)", e.level, e.cost, etiqueta)
                info.notCheckable = true
                info.disabled = not e.affordable
                info.func = function()
                    local ok, err, coste = HarfordDnDMana.CreateSlotFromPoints(e.level, recurso)
                    if not ok then Print(tostring(err or "No se pudo crear el espacio.")) return end
                    HarfordDnDRolls.BroadcastAbility(feature)
                    CloseDropDownMenus()
                    RefrescarVistas()
                end
                UIDropDownMenu_AddButton(info)
            end
            return
        end

        local lista = HarfordDnDMana.GetConvertibleSlots()
        for _, e in ipairs(lista) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = string.format("Nivel %d  (%d/%d)  ->  +%d %s", e.level, e.current, e.max, e.gain, etiqueta)
            info.notCheckable = true
            info.func = function()
                local ok, err, ganados = HarfordDnDMana.ConvertSlotToPoints(e.level, recurso)
                if not ok then Print(tostring(err or "No se pudo convertir el espacio.")) return end
                HarfordDnDRolls.BroadcastAbility(feature)
                CloseDropDownMenus()
                RefrescarVistas()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Abre el selector de nivel. Si la mesa juega con mana no hay nada que convertir, y se dice
    -- por que en lugar de desplegar un menu vacio.
    function HarfordDnDStore.OpenSlotConversionMenu(feature, anchor)
        local conv = feature and feature.slotConversion
        if not (conv and HarfordDnDMana) then return end
        local recurso = tostring(conv.resource or "")
        local lista, motivo
        if conv.mode == "create" then
            lista, motivo = HarfordDnDMana.GetCreatableSlots(recurso)
        else
            lista, motivo = HarfordDnDMana.GetConvertibleSlots()
        end
        if motivo then Print(motivo) return end
        if #lista == 0 then
            Print(conv.mode == "create"
                and "Todavia no puedes crear ningun espacio de conjuro."
                or "No te queda ningun espacio de conjuro que convertir.")
            return
        end
        slotFeature = feature
        ToggleDropDownMenu(1, nil, slotMenu, anchor or "cursor", 0, 0)
    end
end

-- FURIA ELEMENTAL (Chaman Elemental): elige el tipo al que conviertes el daño elemental de tus
-- conjuros. No es un lanzamiento: es un ajuste persistente por perfil que el Compendio consulta al
-- construir cada conjuro. En do...end por el limite de 200 locales del fichero.
do
    local furyMenu = CreateFrame("Frame", "HarfordBookElementalFuryMenu", UIParent, "UIDropDownMenuTemplate")
    local TIPOS = { "acid", "cold", "fire", "lightning", "thunder" }

    UIDropDownMenu_Initialize(furyMenu, function()
        local actual = tostring(HarfordDnDStore.GetValue("FuriaElemental", "") or "")
        for _, key in ipairs(TIPOS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = (HarfordDamageTypes and HarfordDamageTypes.GetLabel and HarfordDamageTypes.GetLabel(key)) or key
            info.checked = (actual == key)
            info.func = function()
                HarfordDnDStore.SetValue("FuriaElemental", key)
                Print("Furia elemental: tus conjuros elementales haran daño de "
                    .. ((HarfordDamageTypes and HarfordDamageTypes.GetLabel and HarfordDamageTypes.GetLabel(key)) or key) .. ".")
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
        local info = UIDropDownMenu_CreateInfo()
        info.text = "No cambiar (tipo original)"
        info.checked = (actual == "")
        info.func = function()
            HarfordDnDStore.SetValue("FuriaElemental", "")
            Print("Furia elemental desactivada: cada conjuro conserva su tipo.")
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info)
    end)

    function HarfordDnDStore.OpenElementalFuryMenu(feature, anchor)
        ToggleDropDownMenu(1, nil, furyMenu, anchor or "cursor", 0, 0)
    end
end

-- ABSOLUCION: PENITENCIA (Sacerdote Disciplina, nivel 2).
--
-- Gasta HASTA CINCO puntos de fe, y todo el efecto escala por punto, asi que ni el coste ni el
-- resultado son fijos: el desplegable pide primero la modalidad y luego cuantos puntos.
--
--   Encomendar: cura (2 + 1d6) por punto de fe gastado.
--   Condenar:   1d10 de dano radiante o necrotico por punto, SIN salvacion contra el dano, mas
--               una salvacion de Sabiduria aparte o queda asustado hasta el final de tu
--               siguiente turno. Por eso `resolution = "auto"` (dano automatico) con
--               `conditionApplySaveAbility`, y no `resolution = "save"`, que dejaria que la
--               salvacion redujera el dano.
--
-- Vive en un do...end por el limite de 200 locales de este fichero.
do
    local penanceMenu = CreateFrame("Frame", "HarfordBookPenanceMenu", UIParent, "UIDropDownMenuTemplate")
    local penanceFeature
    local MAX_PUNTOS = 5

    local function PuntosDisponibles()
        return math.max(0, math.floor(tonumber(GetResourceCurrent("light_point")) or 0))
    end

    local function CD()
        return 8 + HarfordDnDCalc.GetPB() + HarfordDnDCalc.GetAbilityMod(GetSpellAbilityKey())
    end

    -- Gasta los puntos SOLO si el area se confirma, via onCommit: si el jugador cancela la
    -- ventana de area no debe perder la reserva.
    local function Lanzar(feature, modo, puntos, tipoDano)
        local nombre = tostring(feature.name or "Absolucion: Penitencia")
        local definicion
        if modo == "encomendar" then
            definicion = {
                title = nombre .. " - Encomendar", shape = "other", sizeText = "Objetivo",
                resolution = "heal",
                healingComponents = { { dice = tostring(puntos) .. "d6" }, { fixedAmount = 2 * puntos } },
            }
        else
            definicion = {
                title = nombre .. " - Condenar", shape = "other", sizeText = "Objetivo",
                resolution = "auto",
                damageComponents = { { dice = tostring(puntos) .. "d10", damageType = tipoDano } },
                conditionId = "frightened",
                conditionApplySaveAbility = "Sabiduria",
                conditionApplySaveDC = CD(),
                conditionDuration = "manual",
            }
        end
        local opened, err = HarfordDnDArea.Open(definicion, {
            sourceKind = "player",
            sourceGuid = UnitGUID and UnitGUID("player") or "",
            abilityFeature = feature,
            autoResolve = true,
            onCommit = function()
                if PuntosDisponibles() < puntos then
                    return false, "Ya no te quedan " .. tostring(puntos) .. " puntos de fe."
                end
                AdjustResourceCurrent("light_point", -puntos)
                return true
            end,
        })
        if not opened then Print(tostring(err or "No se pudo lanzar Penitencia.")) end
    end

    UIDropDownMenu_Initialize(penanceMenu, function(_, level, menuList)
        local feature = penanceFeature
        if not feature then return end
        local tope = math.min(MAX_PUNTOS, PuntosDisponibles())
        level = level or 1
        if level == 1 then
            for _, modo in ipairs({
                { id = "encomendar", texto = "Encomendar  (cura 2+1d6 por punto)" },
                { id = "condenar",   texto = "Condenar  (1d10 por punto + salvacion de Sabiduria)" },
            }) do
                local info = UIDropDownMenu_CreateInfo()
                info.text, info.notCheckable, info.hasArrow = modo.texto, true, true
                info.menuList = modo.id
                UIDropDownMenu_AddButton(info, level)
            end
            return
        end
        -- Nivel 2: cuantos puntos. Condenar pregunta ademas el tipo de dano, asi que abre otro nivel.
        if level == 2 then
            for n = 1, tope do
                local info = UIDropDownMenu_CreateInfo()
                info.text = tostring(n) .. (n == 1 and " punto de fe" or " puntos de fe")
                info.notCheckable = true
                if menuList == "condenar" then
                    info.hasArrow = true
                    info.menuList = "condenar:" .. tostring(n)
                else
                    info.func = function()
                        CloseDropDownMenus()
                        Lanzar(feature, "encomendar", n)
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            return
        end
        local puntos = tonumber(tostring(menuList or ""):match("^condenar:(%d+)$"))
        if not puntos then return end
        for _, tipo in ipairs({ "radiante", "necrotico" }) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Dano " .. tipo
            info.notCheckable = true
            info.func = function()
                CloseDropDownMenus()
                Lanzar(feature, "condenar", puntos, tipo)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function HarfordDnDStore.OpenPenanceMenu(feature, anchor)
        if SheetContext and SheetContext.active then return end
        if PuntosDisponibles() < 1 then
            Print("No te quedan puntos de fe para usar Penitencia.")
            return
        end
        penanceFeature = feature
        ToggleDropDownMenu(1, nil, penanceMenu, anchor or "cursor", 0, 0)
    end
end

-- EXPIACION (Sacerdote Disciplina, nivel 1).
--
-- Es un RIDER de un conjuro que acabas de lanzar, y el cliente no observa ese lanzamiento de forma
-- fiable, asi que el nivel se pregunta en vez de deducirse. No cuesta recurso: el limite es "solo
-- uno de los dos efectos por lanzamiento", que lo lleva el jugador.
--
--   Tras un conjuro que causa dano  -> un aliado a 9 m recupera 2 x nivel del conjuro.
--   Tras un conjuro que cura        -> una criatura a 9 m recibe 2 x nivel, necrotico o radiante.
do
    local atonementMenu = CreateFrame("Frame", "HarfordBookAtonementMenu", UIParent, "UIDropDownMenuTemplate")
    local atonementFeature

    local function Aplicar(feature, modo, nivel, tipoDano)
        local nombre = tostring(feature.name or "Expiacion")
        local cantidad = 2 * nivel
        local definicion
        if modo == "curar" then
            definicion = {
                title = nombre .. " - cura", shape = "other", sizeText = "Objetivo",
                resolution = "heal", healingComponents = { { fixedAmount = cantidad } },
            }
        else
            definicion = {
                title = nombre .. " - dano", shape = "other", sizeText = "Objetivo",
                resolution = "auto",
                damageComponents = { { fixedAmount = cantidad, damageType = tipoDano } },
            }
        end
        local opened, err = HarfordDnDArea.Open(definicion, {
            sourceKind = "player",
            sourceGuid = UnitGUID and UnitGUID("player") or "",
            abilityFeature = feature,
            autoResolve = true,
        })
        if not opened then Print(tostring(err or "No se pudo aplicar Expiacion.")) end
    end

    UIDropDownMenu_Initialize(atonementMenu, function(_, level, menuList)
        local feature = atonementFeature
        if not feature then return end
        local tope = math.max(1, (HarfordDnDMana and HarfordDnDMana.GetMaxSpellLevel
            and HarfordDnDMana.GetMaxSpellLevel()) or 1)
        level = level or 1
        if level == 1 then
            for _, modo in ipairs({
                { id = "curar", texto = "Tras un conjuro de DANO: curar a un aliado" },
                { id = "danar", texto = "Tras un conjuro de CURACION: danar a una criatura" },
            }) do
                local info = UIDropDownMenu_CreateInfo()
                info.text, info.notCheckable, info.hasArrow = modo.texto, true, true
                info.menuList = modo.id
                UIDropDownMenu_AddButton(info, level)
            end
            return
        end
        if level == 2 then
            for n = 1, tope do
                local info = UIDropDownMenu_CreateInfo()
                info.text = string.format("Conjuro de nivel %d  (%d puntos)", n, 2 * n)
                info.notCheckable = true
                if menuList == "danar" then
                    info.hasArrow = true
                    info.menuList = "danar:" .. tostring(n)
                else
                    info.func = function() CloseDropDownMenus(); Aplicar(feature, "curar", n) end
                end
                UIDropDownMenu_AddButton(info, level)
            end
            return
        end
        local nivel = tonumber(tostring(menuList or ""):match("^danar:(%d+)$"))
        if not nivel then return end
        for _, tipo in ipairs({ "necrotico", "radiante" }) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = "Dano " .. tipo
            info.notCheckable = true
            info.func = function() CloseDropDownMenus(); Aplicar(feature, "danar", nivel, tipo) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function HarfordDnDStore.OpenAtonementMenu(feature, anchor)
        if SheetContext and SheetContext.active then return end
        atonementFeature = feature
        ToggleDropDownMenu(1, nil, atonementMenu, anchor or "cursor", 0, 0)
    end
end

-- LEGADO DEL VACIO (Sacerdote Sombra, nivel 1).
--
-- "Cuando infliges dano a una criatura con un truco de sacerdote, puedes causar dano psiquico
-- adicional igual a tu Mod. Carisma. Cuando usas esta caracteristica, debes tener exito en una
-- salvacion de Sabiduria (CD 10 + 1 por cada uso adicional desde el ultimo descanso largo). Si
-- fallas, no podras usarla de nuevo hasta que termines un descanso largo."
--
-- El disparador -haber danado con un truco- NO lo observa el cliente, asi que se activa a mano,
-- igual que Expiacion. Lo que si es rastreable y va automatico: la CD escalonada, la salvacion y
-- el bloqueo hasta el descanso. El dano se aplica ANTES de la salvacion: fallar no lo deshace,
-- solo impide volver a usarlo.
do
    local CLAVE = "void_legacy"
    local BLOQUEADO = -1

    local function Contador()
        return (HarfordDnDProgression and HarfordDnDProgression.GetRestCounter
            and HarfordDnDProgression.GetRestCounter(CLAVE)) or 0
    end

    local function Anotar(valor)
        if HarfordDnDProgression and HarfordDnDProgression.SetRestCounter then
            HarfordDnDProgression.SetRestCounter(CLAVE, valor)
        end
    end

    function HarfordDnDStore.UseVoidLegacy(feature)
        if SheetContext and SheetContext.active then return end
        if not feature then return end
        local usos = Contador()
        if usos == BLOQUEADO then
            Print("Fallaste la salvacion de Legado del Vacio: no puedes usarlo hasta un descanso largo.")
            return
        end
        local extra = HarfordDnDCalc.GetAbilityMod("Carisma")
        if extra <= 0 then
            Print("Legado del Vacio no anade dano con un Mod. Carisma de " .. tostring(extra) .. ".")
            return
        end

        -- 1) El dano psiquico extra, por la ruta comun de area (aplica mitigacion y lo publica).
        local opened, err = HarfordDnDArea.Open({
            title = tostring(feature.name or "Legado del Vacio"),
            shape = "other", sizeText = "Objetivo", resolution = "auto",
            damageComponents = { { fixedAmount = extra, damageType = "psiquico" } },
        }, {
            sourceKind = "player",
            sourceGuid = UnitGUID and UnitGUID("player") or "",
            abilityFeature = feature,
            autoResolve = true,
        })
        if not opened then Print(tostring(err or "No se pudo aplicar Legado del Vacio.")); return end

        -- 2) La salvacion propia, con la CD que sube 1 por cada uso adicional desde el descanso.
        local dc = 10 + usos
        local total, ra, rb, critTag, modeTag = HarfordDnDCalc.RollD20Full("save", { actorUnit = "player" })
        -- GetSaveRollBonuses devuelve (bono, competencia) por separado, como el resto de salvaciones.
        local base, prof = HarfordDnDCalc.GetSaveRollBonuses("Sabiduria")
        local bono = (tonumber(base) or 0) + (tonumber(prof) or 0)
        local resultado = total + bono
        local exito = resultado >= dc
        if exito then Anotar(usos + 1) else Anotar(BLOQUEADO) end
        HarfordDnDRolls.Broadcast({
            type = "save",
            -- La habilidad ya se firma con su LINK en la linea de dano (abilityFeature del area);
            -- esta es SU salvacion, asi que no repite el nombre en prosa.
            label = string.format("Salv Sabiduria CD %d  %s", dc,
                exito and "|cff00ff00EXITO|r" or "|cffff3333FALLO|r (bloqueado hasta el descanso largo)"),
            total = resultado,
            dice = HarfordDnDCalc.FormatD20Dice(total, ra, rb),
            modifiers = fmtSigned(bono),
            critical = critTag or "",
            mode = modeTag or "",
        })
        if HarfordCharacterPanel and HarfordCharacterPanel.RefreshBookIfShown then
            HarfordCharacterPanel.RefreshBookIfShown()
        end
    end

    -- Texto para el subtitulo del Libro: cuantas veces se ha usado y la CD que tocaria ahora.
    function HarfordDnDStore.GetVoidLegacyState()
        local usos = Contador()
        if usos == BLOQUEADO then return "Bloqueado hasta el descanso largo" end
        return string.format("Proxima CD %d  ·  %d uso%s", 10 + usos, usos, usos == 1 and "" or "s")
    end
end

-- RIDERS DEL MONJE. Los tres cuelgan de otra cosa que acabas de hacer (Niebla reconfortante,
-- Puños de Furia, Paso del Viento) y el cliente NO observa ese disparador, asi que se activan a
-- mano, igual que Expiacion y Legado del Vacio. Lo que si es calculable va automatico.
do
    local manoLanzaMenu = CreateFrame("Frame", "HarfordBookSpearHandMenu", UIParent, "UIDropDownMenuTemplate")
    local manoLanzaFeature

    local function CDMonje()
        return 8 + HarfordDnDCalc.GetPB() + HarfordDnDCalc.GetAbilityMod("Sabiduria")
    end

    -- GOLPES DE MANO DE LANZA: al golpear con Puños de Furia impones UNO de tres efectos.
    UIDropDownMenu_Initialize(manoLanzaMenu, function()
        local feature = manoLanzaFeature
        if not feature then return end
        local OPCIONES = {
            { texto = "Salvacion de Destreza o DERRIBADO", save = "Destreza", cond = "prone",
              fallo = "cae derribado" },
            { texto = "Salvacion de Fuerza o EMPUJADO 4,5 m", save = "Fuerza", cond = nil,
              fallo = "es empujado hasta 4,5 m lejos de ti" },
            { texto = "Sin reacciones hasta el final de tu proximo turno", save = nil, cond = nil,
              fallo = "no puede tomar reacciones hasta el final de tu proximo turno" },
        }
        for _, o in ipairs(OPCIONES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.notCheckable = o.texto, true
            info.func = function()
                CloseDropDownMenus()
                if not o.save then
                    -- Sin salvacion: se anuncia y se resuelve en mesa, no hay tirada que hacer.
                    HarfordDnDRolls.BroadcastAbility(feature, { targetUnit = "target" })
                    return
                end
                local definicion = {
                    title = tostring(feature.name or "Golpes de mano de lanza"),
                    shape = "other", sizeText = "Objetivo",
                    resolution = "save", saveAbility = o.save, dc = CDMonje(), success = "none",
                }
                if o.cond then
                    definicion.conditionId = o.cond
                    definicion.conditionDuration = "manual"
                else
                    definicion.note = "Si falla, " .. o.fallo .. "."
                end
                local opened, err = HarfordDnDArea.Open(definicion, {
                    sourceKind = "player",
                    sourceGuid = UnitGUID and UnitGUID("player") or "",
                    abilityFeature = feature,
                    autoResolve = true,
                })
                if not opened then Print(tostring(err or "No se pudo imponer el efecto.")) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    function HarfordDnDStore.OpenSpearHandMenu(feature, anchor)
        if SheetContext and SheetContext.active then return end
        manoLanzaFeature = feature
        ToggleDropDownMenu(1, nil, manoLanzaMenu, anchor or "cursor", 0, 0)
    end

    -- PALMA DE CHI-JI: golpe desarmado adicional que usa Sabiduria al ataque y al dano. Reusa la
    -- ruta de ataque de arma con un bloque propio, como las criaturas acompanantes.
    function HarfordDnDStore.UseChiJiPalm(feature)
        if SheetContext and SheetContext.active then return end
        local mod = HarfordDnDCalc.GetAbilityMod("Sabiduria")
        local desarmado = HarfordDnDStore.GetWeaponDef and HarfordDnDStore.GetWeaponDef("Desarmado")
        local n, caras = 1, 4
        if HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetMartialArtsDamageDice then
            local mn, mc = HarfordDnDFeatureEffects.GetMartialArtsDamageDice(desarmado)
            if mn and mc then n, caras = mn, mc end
        end
        HarfordDnDStore.AttackWithBlock({
            key = tostring(feature.name or "Palma de chi-ji"),
            actorLabel = nil,
            mode = "Melee", rangeFeet = 5, targetText = "un objetivo",
            dmgN = n, dmgS = caras, dmgType = "contundente",
            addAbi = false, weaponDamageBonus = mod,
            attackBonusOverride = HarfordDnDCalc.GetPB() + mod,
            ignoreGlobalWeaponBonuses = true, externalActor = true,
            props = { "Natural" }, source = "feature",
        })
    end

    -- CAMINAVIENTOS: velocidad de vuelo hasta el final del turno y reduccion de dano por caida.
    -- No hay mecanica de vuelo ni de caida, asi que se calculan los numeros y se anuncian.
    function HarfordDnDStore.UseWindwalking(feature)
        if SheetContext and SheetContext.active then return end
        -- GetSpeed(base) necesita la velocidad base: la del Monje es 9 m mas su bono de clase.
        local velocidad = (HarfordDnDFeatureEffects and HarfordDnDFeatureEffects.GetSpeed
            and HarfordDnDFeatureEffects.GetSpeed(9)) or 9
        local nivel = 0
        for _, e in ipairs((HarfordDnDProgression and HarfordDnDProgression.GetClassLevels
            and HarfordDnDProgression.GetClassLevels()) or {}) do
            if e.classId == "monje" then nivel = tonumber(e.level) or 0 break end
        end
        HarfordDnDRolls.BroadcastAbility(feature)
    end
end

-- RASGOS QUE GASTAN UNA RANURA DE CONJURO A CAMBIO DE UN EFECTO ESCALADO.
--
-- El coste, si te lo puedes permitir y el cobro ya los resuelve HarfordDnDConditionalDamage con
-- `spellLevelCost` (es lo que hace Golpe del Cruzado), y funciona igual en modo mana y en modo
-- espacios. Aqui solo se reusa pasandole un condicional minimo, en vez de escribir otra ruta.
--
-- Formula compartida del Paladin: 2d6 por ranura de 1.er nivel, +1d6 por cada nivel por encima,
-- hasta un maximo de 6d6.
do
    local slotMenu = CreateFrame("Frame", "HarfordBookSpellLevelMenu", UIParent, "UIDropDownMenuTemplate")
    local slotFeature, slotOnChosen
    -- MISMA forma que Golpe del Cruzado: sin `maxSpellLevel`/`countPerLevel`/`maxCount` el
    -- calculo de nivel maximo se queda en 1. `maxCount - extraCountOffset` = 5, que es el nivel
    -- al que la formula llega a 6d6.
    local COSTE = { spellLevelCost = "level", minLevel = 1, maxSpellLevel = true,
                    countPerLevel = 1, maxCount = 6, extraCountOffset = 1 }

    local function DadosPaladin(nivel)
        return math.min(6, 2 + math.max(0, nivel - 1))
    end

    UIDropDownMenu_Initialize(slotMenu, function()
        local feature, alElegir = slotFeature, slotOnChosen
        if not (feature and alElegir) then return end
        local maximo = (HarfordDnDMana and HarfordDnDMana.GetMaxSpellLevel
            and HarfordDnDMana.GetMaxSpellLevel()) or 0
        for nivel = 1, maximo do
            local info = UIDropDownMenu_CreateInfo()
            local texto = HarfordDnDConditionalDamage.GetCostText(COSTE, nivel) or ""
            info.text = string.format("Nivel %d  ->  %dd6   (%s)", nivel, DadosPaladin(nivel), texto)
            info.notCheckable = true
            info.disabled = not HarfordDnDConditionalDamage.CanPay(COSTE, nivel)
            info.func = function()
                CloseDropDownMenus()
                if not HarfordDnDConditionalDamage.Spend(COSTE, nivel) then
                    Print("No pudiste gastar la ranura de nivel " .. tostring(nivel) .. ".")
                    return
                end
                alElegir(feature, nivel, DadosPaladin(nivel))
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local function AbrirSelector(feature, anchor, alElegir)
        if SheetContext and SheetContext.active then return end
        local maximo = (HarfordDnDMana and HarfordDnDMana.GetMaxSpellLevel
            and HarfordDnDMana.GetMaxSpellLevel()) or 0
        if maximo < 1 then
            Print("Todavia no puedes lanzar conjuros de nivel 1 o superior.")
            return
        end
        slotFeature, slotOnChosen = feature, alElegir
        ToggleDropDownMenu(1, nil, slotMenu, anchor or "cursor", 0, 0)
    end

    -- DESTELLO DE LUZ (Sagrado): accion adicional, cura a un objetivo a 6 m. No afecta a
    -- no-muertos ni constructos; eso queda como nota, porque el motor no conoce el tipo del objetivo.
    function HarfordDnDStore.OpenFlashOfLight(feature, anchor)
        AbrirSelector(feature, anchor, function(ft, nivel, dados)
            local opened, err = HarfordDnDArea.Open({
                title = tostring(ft.name or "Destello de Luz"),
                shape = "other", sizeText = "Objetivo",
                resolution = "heal",
                healingComponents = { { dice = tostring(dados) .. "d6" } },
                note = "No tiene efecto en no-muertos ni constructos.",
            }, {
                sourceKind = "player",
                sourceGuid = UnitGUID and UnitGUID("player") or "",
                abilityFeature = ft,
                autoResolve = true,
            })
            if not opened then Print(tostring(err or "No se pudo lanzar Destello de Luz.")) end
        end)
    end

    -- TORMENTA DIVINA (Represion): al golpear cuerpo a cuerpo, dano radiante al objetivo Y a todo
    -- lo que este a 1,5 m de TI, con salvacion de Destreza por la mitad. El area centrada en uno
    -- mismo ya cubre al objetivo de un ataque cuerpo a cuerpo, asi que es un solo area.
    function HarfordDnDStore.OpenDivineStorm(feature, anchor)
        AbrirSelector(feature, anchor, function(ft, nivel, dados)
            local opened, err = HarfordDnDArea.Open({
                title = tostring(ft.name or "Tormenta divina"),
                shape = "sphere", sizeText = "1,5 m de radio",
                resolution = "save", saveAbility = "Destreza", success = "half",
                damageComponents = { { dice = tostring(dados) .. "d6", damageType = "radiante" } },
                note = "Un ataque solo puede beneficiarse de Golpe del Cruzado O de Tormenta divina, no de los dos.",
            }, {
                sourceKind = "player",
                sourceGuid = UnitGUID and UnitGUID("player") or "",
                abilityFeature = ft,
                autoResolve = true,
            })
            if not opened then Print(tostring(err or "No se pudo lanzar Tormenta divina.")) end
        end)
    end
end
