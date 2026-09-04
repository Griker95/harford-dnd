-- HarfordDnDCompanions: estado de la criatura acompanante del jugador.
--
-- Modelado sobre HarfordDnDForms (formas druidicas), NO sobre la ficha NPC: el contexto NPC
-- (`ApplySheetContext`) es la herramienta del DM y no debe usarse para criaturas del jugador.
--
-- Lo que se guarda por perfil en la progresion es minimo: que criatura esta invocada y sus PG
-- actuales. Todo lo demas se DERIVA del bloque + el invocador en cada consulta, para que subir de
-- nivel o cambiar una caracteristica se refleje sin migrar nada.

HarfordDnDCompanions = HarfordDnDCompanions or {}

local API = HarfordDnDCompanions

API.providers = API.providers or {}

-- Registra una fuente de bloques que NO estan escritos a mano en los datos (la bestia del
-- Cazador, que sale del TRP3 del jugador). Entran por la misma puerta que el resto: el
-- proveedor devuelve bloques con la misma forma y ya se filtran por clase, nivel y elecciones.
function API.RegisterProvider(fn)
    if type(fn) ~= "function" then return end
    API.providers[#API.providers + 1] = fn
end

local function Datos(profileName)
    local out = {}
    for _, c in ipairs((HarfordDnDCompanionsData and HarfordDnDCompanionsData.COMPANIONS) or {}) do
        out[#out + 1] = c
    end
    for _, fn in ipairs(API.providers) do
        local ok, lista = pcall(fn, profileName)
        if ok and type(lista) == "table" then
            for _, c in ipairs(lista) do out[#out + 1] = c end
        end
    end
    return out
end

local function Perfil(profileName)
    return profileName or (UnitName and UnitName("player")) or "Personaje"
end

local function NivelDeClase(classId, profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.GetClassLevels) then return 0 end
    for _, entry in ipairs(HarfordDnDProgression.GetClassLevels(profileName) or {}) do
        if tostring(entry.classId or "") == tostring(classId) then return tonumber(entry.level) or 0 end
    end
    return 0
end

local function Mod(ability)
    return (HarfordDnDCalc and HarfordDnDCalc.GetAbilityMod and HarfordDnDCalc.GetAbilityMod(ability)) or 0
end

local function ModDeBloque(bloque, ability)
    local valor = tonumber((bloque.abilities or {})[ability])
    if not valor then return 0 end
    return math.floor((valor - 10) / 2)
end

local function Competencia(profileName)
    if HarfordDnDProgression and HarfordDnDProgression.GetProficiencyBonus then
        return tonumber(HarfordDnDProgression.GetProficiencyBonus(profileName)) or 2
    end
    return (HarfordDnDCalc and HarfordDnDCalc.GetPB and HarfordDnDCalc.GetPB()) or 2
end

-- "Poder del Maestro" (los demonios del brujo) y el equivalente del esbirro no-muerto: los numeros
-- del bloque suben 1 cada vez que TU bonus de competencia sube 1. El bloque esta escrito con el
-- bonus base de 2, asi que el incremento es `PB - 2`; nunca resta.
local function Maestria(c, campo, profileName)
    local m = c and c.masterPower
    if not (type(m) == "table" and m[campo]) then return 0 end
    return math.max(0, Competencia(profileName) - 2)
end

-- Criaturas que el personaje puede invocar segun su clase, nivel y elecciones.
function API.GetAvailable(profileName)
    profileName = Perfil(profileName)
    local elegidas
    local out = {}
    for _, c in ipairs(Datos(profileName)) do
        local nivel = NivelDeClase(c.classId, profileName)
        if nivel >= (tonumber(c.minLevel) or 1) then
            local ok = true
            if c.requiresOption then
                if not elegidas then
                    elegidas = {}
                    local data = HarfordDnDProgression and HarfordDnDProgression.Get
                        and HarfordDnDProgression.Get(profileName)
                    for _, seleccion in pairs((data and data.choices) or {}) do
                        -- `choices[featureId]` esta indexado por SLOT: con ipairs, un slot 2 sin
                        -- slot 1 no se leeria.
                        for _, optId in pairs(seleccion or {}) do elegidas[tostring(optId)] = true end
                    end
                end
                ok = elegidas[tostring(c.requiresOption)] == true
            end
            if ok then out[#out + 1] = c end
        end
    end
    return out
end

function API.GetById(companionId, profileName)
    for _, c in ipairs(Datos(profileName)) do
        if tostring(c.id) == tostring(companionId) then return c end
    end
    return nil
end

-- PG maximos: base + Mod. propio del bloque + Mod. TUYO + porNivel x tu nivel en esa clase.
function API.GetMaxHP(companion, profileName)
    if not (companion and companion.hp) then return 0 end
    profileName = Perfil(profileName)
    local h = companion.hp
    local total = tonumber(h.base) or 0
    if h.ownAbility then total = total + ModDeBloque(companion, h.ownAbility) end
    if h.ownerAbility then total = total + Mod(h.ownerAbility) end
    if h.perOwnerLevel then
        total = total + (tonumber(h.perOwnerLevel) or 0) * NivelDeClase(companion.classId, profileName)
    end
    -- Bestia del Cazador: parte de los PG de su bloque y gana un dado de golpe por cada nivel
    -- de personaje despues del 3. Se usa el valor PROMEDIO (convencion del manual del jugador,
    -- `dado/2 + 1`), no una tirada: los PG de una ficha no pueden depender de una tirada que se
    -- repetiria en cada consulta.
    if h.hitDie and h.extraDiceAfterLevel then
        -- Es NIVEL DE PERSONAJE, no de clase: el manual dice "por cada nivel de personaje
        -- que ganes despues del 3".
        local nivelPJ = 0
        for _, entry in ipairs((HarfordDnDProgression and HarfordDnDProgression.GetClassLevels
            and HarfordDnDProgression.GetClassLevels(profileName)) or {}) do
            nivelPJ = nivelPJ + (tonumber(entry.level) or 0)
        end
        local extra = math.max(0, nivelPJ - h.extraDiceAfterLevel)
        total = total + extra * (math.floor(h.hitDie / 2) + 1 + (tonumber(h.hitDieConMod) or 0))
    end
    return math.max(1, total)
end

function API.GetArmorClass(companion, profileName)
    if not companion then return nil end
    profileName = Perfil(profileName)
    local ca = tonumber(companion.armorClassBase) or 10
    if companion.acPlusProficiency then ca = ca + Competencia(profileName) end
    return ca + Maestria(companion, "ac", profileName)
end

-- Ataque de conjuro del invocador: varias acciones lo usan en lugar del suyo propio.
local function AtaqueDeConjuro(profileName)
    local pb = Competencia(Perfil(profileName))
    local abil = (HarfordDnDStore and HarfordDnDStore.GetSpellAbilityKey
        and HarfordDnDStore.GetSpellAbilityKey()) or "Inteligencia"
    return pb + Mod(abil)
end

-- Devuelve la accion lista para tirar: resuelve el bono de ataque y el de dano.
function API.ResolveAction(companion, action, profileName)
    if not (companion and action) then return nil end
    profileName = Perfil(profileName)
    local pb = Competencia(profileName)
    local resuelta = {}
    for k, v in pairs(action) do resuelta[k] = v end
    if action.attackFrom == "spellAttack" then
        resuelta.attackBonusOverride = AtaqueDeConjuro(profileName)
    elseif action.attackBonus then
        -- El bloque declara su bono; sube con tu competencia si asi lo dice su rasgo.
        resuelta.attackBonusOverride = action.attackBonus + Maestria(companion, "attack", profileName)
    end
    local dano = tonumber(action.weaponDamageBonus) or 0
    if action.damagePlusProficiency then dano = dano + pb end
    resuelta.weaponDamageBonus = dano + Maestria(companion, "damage", profileName)
    return resuelta
end

-- Acciones de la criatura invocada, ya resueltas y listas para el selector del Libro.
function API.GetActions(profileName)
    profileName = Perfil(profileName)
    local c = API.GetActive(profileName)
    if not c then return {}, nil end
    local lista = {}
    for _, accion in ipairs(c.actions or {}) do
        lista[#lista + 1] = API.ResolveAction(c, accion, profileName)
    end
    return lista, c
end

-- Convierte una accion en la MISMA forma que un arma, para que tire por los motores comunes
-- (DoWeaponAttack / RollWeaponDamage) en lugar de tener una ruta de tirada propia. Es el patron
-- de las formas druidicas; `externalActor` marca que el atacante no es el jugador y que por tanto
-- no hereda sus rasgos de combate.
function API.GetWeaponDef(actionKey, profileName)
    profileName = Perfil(profileName)
    local lista, c = API.GetActions(profileName)
    if not c then return nil, "No tienes ninguna criatura invocada." end
    local elegida
    for _, accion in ipairs(lista) do
        if tostring(accion.key) == tostring(actionKey) then elegida = accion break end
    end
    elegida = elegida or lista[1]
    if not elegida then return nil, tostring(c.name) .. " no tiene acciones de ataque." end
    elegida.externalActor = true
    elegida.actorLabel = c.name
    return elegida, nil
end

-- Estado: que criatura esta invocada y con cuantos PG.
function API.GetActive(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.Get) then return nil end
    local data = HarfordDnDProgression.Get(Perfil(profileName))
    local id = tostring((data and data.activeCompanion) or "")
    if id == "" then return nil end
    return API.GetById(id), tonumber(data.activeCompanionHP) or 0
end

-- Lineas del tooltip de un bloque: lo que hace falta para jugarlo sin abrir el manual.
local function Detalle(c, profileName)
    local lineas = {
        tostring(c.creatureType or ""),
        string.format("CA %d%s   PG %d   Velocidad %d m",
            API.GetArmorClass(c, profileName) or 10,
            c.armorClassNote and (" (" .. c.armorClassNote .. ")") or "",
            API.GetMaxHP(c, profileName) or 1, math.floor((tonumber(c.speed) or 30) * 0.3048 + 0.5)),
    }
    for _, t in ipairs(c.traits or {}) do lineas[#lineas + 1] = t end
    if c.senses and c.senses ~= "" then lineas[#lineas + 1] = c.senses end
    return lineas
end

-- Que te cuesta ordenarle esta accion. La criatura no tiene turno propio: actua dentro del tuyo,
-- y en el suyo solo Esquiva salvo que pagues este coste.
local COSTE_ORDEN = {
    accion    = "Ordenarselo gasta tu ACCION.",
    adicional = "Ordenarselo gasta tu ACCION ADICIONAL.",
}

local function DetalleAccion(c, a)
    local bono = tonumber(a.attackBonusOverride) or 0
    local lineas = {
        string.format("Ataque %s%d al impactar, %dd%d%s de dano %s.",
            bono >= 0 and "+" or "", bono, a.dmgN or 0, a.dmgS or 0,
            (tonumber(a.weaponDamageBonus) or 0) ~= 0
                and string.format("%+d", a.weaponDamageBonus) or "",
            tostring(a.dmgType or "")),
        COSTE_ORDEN[tostring(c.commandAction or "accion")] or COSTE_ORDEN.accion,
    }
    if a.note and a.note ~= "" then lineas[#lineas + 1] = a.note end
    return lineas
end

-- Selector del Libro. Sin criatura invocada lista las que puedes invocar; con una invocada
-- lista sus acciones (atacan al instante) y la opcion de despedirla. Reusa el flyout de las
-- formas druidicas: es el mismo gesto y el mismo arte.
function API.OpenMenu(anchor, onSelect)
    if not (HarfordDnDForms and HarfordDnDForms.OpenEntryFlyout) then
        return false, "El selector de criaturas no esta disponible."
    end
    local profileName = Perfil()
    local activa = API.GetActive(profileName)
    local entradas = {}
    local nucleo, rasgoNucleo = API.GetActiveCore(profileName)
    if nucleo then
        -- Sosteniendo un nucleo no hay criatura: solo se puede soltar.
        local grants = API.GetCoreGrants(profileName)
        local detalle = { "Mientras lo sostengas tienes ventaja en chequeos de " .. tostring((grants and grants.advantage) or "?") .. "." }
        for _, linea in ipairs((grants and grants.activos) or {}) do detalle[#detalle + 1] = linea end
        for _, linea in ipairs((grants and grants.pendientes) or {}) do detalle[#detalle + 1] = linea end
        entradas[#entradas + 1] = {
            key = "", soltarNucleo = true,
            name = "Soltar el nucleo de " .. tostring(nucleo.name),
            icon = (rasgoNucleo and rasgoNucleo.icon and ("Interface\\Icons\\" .. rasgoNucleo.icon)) or nucleo.icon,
            detail = detalle,
        }
        return HarfordDnDForms.OpenEntryFlyout("Companions", anchor, entradas, "", function(elegida)
            if elegida.soltarNucleo then API.DropCore(profileName) end
            if onSelect then onSelect(elegida) end
        end)
    end
    if activa then
        entradas[#entradas + 1] = {
            key = "", despedir = true, name = "Despedir a " .. tostring(activa.name),
            icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield",
            detail = "La criatura desaparece. Volver a invocarla la trae con sus PG al maximo.",
        }
        if activa.coreFeatureId then
            entradas[#entradas + 1] = {
                key = "_nucleo", tomarNucleo = true,
                name = "Destruir a " .. tostring(activa.name) .. " y quedarte su nucleo",
                icon = "Interface\\Icons\\" .. "INV_Misc_Gem_Amethyst_02",
                detail = "Grimorio de sacrificio: te quedas su nucleo demoniaco en lugar de la criatura. Solo puedes tener una de las dos cosas.",
            }
        end
        entradas[#entradas + 1] = {
            key = "_pg", ajustarPG = true, name = "Ajustar PG",
            icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
            detail = "Anota el dano o la curacion que recibe la criatura. Negativo resta, positivo suma.",
        }
        for _, accion in ipairs(select(1, API.GetActions(profileName))) do
            entradas[#entradas + 1] = {
                key = accion.key, accion = accion, name = accion.key,
                icon = accion.icon or activa.icon, detail = DetalleAccion(activa, accion),
            }
        end
    else
        for _, c in ipairs(API.GetAvailable(profileName)) do
            entradas[#entradas + 1] = {
                key = c.id, criatura = c, name = "Invocar a " .. tostring(c.name),
                icon = c.icon, detail = Detalle(c, profileName),
            }
        end
        if #entradas == 0 then return false, "Todavia no puedes invocar ninguna criatura." end
    end
    return HarfordDnDForms.OpenEntryFlyout("Companions", anchor, entradas,
        activa and "" or "", function(elegida)
            if elegida.despedir then
                API.Dismiss(profileName)
            elseif elegida.tomarNucleo then
                local ok, err = API.TakeCore(activa and activa.id, profileName)
                if not ok and HarfordChat then HarfordChat.Print("|cffff5555" .. tostring(err) .. "|r") end
            elseif elegida.ajustarPG then
                API.OpenHealthPrompt(profileName)
            elseif elegida.criatura then
                local ok, err = API.Summon(elegida.criatura.id, profileName)
                if not ok and HarfordChat then HarfordChat.Print("|cffff5555" .. tostring(err) .. "|r") end
            elseif elegida.accion then
                -- Ordenar un ataque lo ejecuta YA: no hay paso intermedio de "preparado".
                if HarfordDnDStore and HarfordDnDStore.AttackWithCompanion then
                    HarfordDnDStore.AttackWithCompanion(elegida.accion.key)
                end
            end
            if onSelect then onSelect(elegida) end
        end)
end

-- Pregunta cuanto dano/curacion anotar. No exige objetivo: la criatura no es una unidad del
-- juego, es un bloque tuyo.
function API.OpenHealthPrompt(profileName)
    profileName = Perfil(profileName)
    local c, pg = API.GetActive(profileName)
    if not c then
        if HarfordChat then HarfordChat.Print("No tienes ninguna criatura invocada.") end
        return false
    end
    if not (StaticPopupDialogs and StaticPopup_Show) then return false end
    StaticPopupDialogs["HARFORD_COMPANION_HP"] = StaticPopupDialogs["HARFORD_COMPANION_HP"] or {
        text = "%s", button1 = "Aceptar", button2 = "Cancelar",
        hasEditBox = true, maxLetters = 6, timeout = 0, whileDead = 1, hideOnEscape = 1,
        OnShow = function(self)
            self.editBox:SetText("")
            self.editBox:SetFocus()
        end,
        OnAccept = function(self)
            local data = self.data
            if data and type(data.confirm) == "function" then data.confirm(self.editBox:GetText()) end
        end,
        EditBoxOnEnterPressed = function(editBox)
            local popup = editBox:GetParent()
            if popup and popup.button1 then popup.button1:Click() end
        end,
    }
    local texto = tostring(c.name) .. "\n" .. tostring(pg) .. "/"
        .. tostring(API.GetMaxHP(c, profileName)) .. " PG\nDano en negativo, curacion en positivo:"
    StaticPopup_Show("HARFORD_COMPANION_HP", texto, nil, {
        confirm = function(bruto)
            local delta = tonumber(bruto)
            if not delta or delta == 0 then
                if HarfordChat then HarfordChat.Print("Introduce una cantidad (por ejemplo -8 o 5).") end
                return
            end
            API.AdjustHP(math.floor(delta), profileName)
        end,
    })
    return true
end

-- NUCLEOS DEMONIACOS (Brujo). "Puedes destruir al demonio al invocarlo para obtener su nucleo
-- demoniaco. Solo puedes mantener un demonio invocado o un nucleo a la vez." Esa exclusion ya es
-- la del estado: sostener un nucleo despide al demonio y viceversa, sin poder tener los dos.
--
-- El nucleo NO es una criatura, asi que no tiene PG ni acciones. Lo que concede (ventaja en dos
-- chequeos y conjuros por escalon de nivel) vive junto a su prosa en el rasgo de clase, y aqui
-- solo se lee: un unico sitio donde corregirlo.
local function RasgoDeNucleo(featureId)
    if not (HarfordDnDBook and HarfordDnDBook.GetClass) then return nil end
    local brujo = HarfordDnDBook.GetClass("brujo")
    for _, f in ipairs((brujo and brujo.features) or {}) do
        if tostring(f.id) == tostring(featureId) then return f end
    end
    return nil
end

-- Nucleo sostenido: devuelve el bloque del demonio del que salio y su rasgo.
function API.GetActiveCore(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.Get) then return nil end
    local data = HarfordDnDProgression.Get(Perfil(profileName))
    local id = tostring((data and data.activeCore) or "")
    if id == "" then return nil end
    local demonio = API.GetById(id, profileName)
    if not demonio then return nil end
    return demonio, RasgoDeNucleo(demonio.coreFeatureId)
end

-- Lo que el nucleo te concede AHORA, segun tu nivel de brujo. Los escalones superiores se
-- anuncian igualmente, para que se vea que existen y a que nivel llegan.
function API.GetCoreGrants(profileName)
    profileName = Perfil(profileName)
    local demonio, rasgo = API.GetActiveCore(profileName)
    local core = rasgo and rasgo.core
    if not core then return nil end
    local nivel = NivelDeClase("brujo", profileName)
    local activos, pendientes = {}, {}
    if core.atWill and core.atWill ~= "" then
        activos[#activos + 1] = core.atWill .. " (a voluntad)"
    end
    for _, t in ipairs(core.tiers or {}) do
        local linea = tostring(t.spell) .. " (1 vez por descanso largo, sin gastar ranura)"
        if nivel >= (tonumber(t.level) or 99) then
            activos[#activos + 1] = linea
        else
            pendientes[#pendientes + 1] = "Nivel " .. tostring(t.level) .. ": " .. linea
        end
    end
    return {
        demonio = demonio, feature = rasgo, advantage = core.advantage,
        activos = activos, pendientes = pendientes,
    }
end

-- Quedarte con el nucleo de un demonio. Requiere tenerlo disponible; si lo tenias invocado, esto
-- ES destruirlo, que es justo lo que dice Grimorio de sacrificio.
function API.TakeCore(companionId, profileName)
    profileName = Perfil(profileName)
    local c = API.GetById(companionId, profileName)
    if not (c and c.coreFeatureId) then return false, "Esa criatura no deja un nucleo demoniaco." end
    local disponible = false
    for _, x in ipairs(API.GetAvailable(profileName)) do
        if x.id == c.id then disponible = true break end
    end
    if not disponible then return false, "Todavia no puedes invocar a " .. tostring(c.name) .. "." end
    local data = HarfordDnDProgression.Get(profileName)
    data.activeCompanion = ""
    data.activeCompanionHP = 0
    data.activeCore = tostring(c.id)
    -- `Save` no existe en Progression: la llamada estaba guardada por un `if`, asi que no fallaba
    -- -- simplemente no invalidaba nada. `Set` es el que persiste y refresca los efectos.
    if HarfordDnDProgression.Set then HarfordDnDProgression.Set(profileName, data) end
    return true
end

function API.DropCore(profileName)
    profileName = Perfil(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.Get) then return false end
    local data = HarfordDnDProgression.Get(profileName)
    data.activeCore = ""
    -- `Save` no existe en Progression: la llamada estaba guardada por un `if`, asi que no fallaba
    -- -- simplemente no invalidaba nada. `Set` es el que persiste y refresca los efectos.
    if HarfordDnDProgression.Set then HarfordDnDProgression.Set(profileName, data) end
    return true
end

function API.Summon(companionId, profileName)
    profileName = Perfil(profileName)
    local c = API.GetById(companionId)
    if not c then return false, "Criatura desconocida." end
    local disponible = false
    for _, x in ipairs(API.GetAvailable(profileName)) do
        if x.id == c.id then disponible = true break end
    end
    if not disponible then return false, "Todavia no puedes invocar a " .. tostring(c.name) .. "." end
    if not (HarfordDnDProgression and HarfordDnDProgression.Get) then return false end
    local data = HarfordDnDProgression.Get(profileName)
    data.activeCompanion = tostring(c.id)
    data.activeCompanionHP = API.GetMaxHP(c, profileName)
    -- Un demonio invocado y un nucleo sostenido se excluyen.
    data.activeCore = ""
    -- Los rasgos "Lobo Solitario" del Cazador solo valen SIN companero bestial (critico 19-20,
    -- ataque adicional, ventaja). Tener la bestia invocada y el estado activo a la vez daria
    -- ventajas que el manual excluye, asi que invocar apaga el estado.
    if tostring(c.classId) == "cazador" and HarfordDnDProgression.SetToggleState
        and HarfordDnDProgression.IsToggleStateActive
        and HarfordDnDProgression.IsToggleStateActive("lone_wolf", profileName) then
        HarfordDnDProgression.SetToggleState("lone_wolf", false, profileName)
        if HarfordChat then
            HarfordChat.Print("Lobo Solitario se desactiva: sus rasgos exigen no tener companero bestial.")
        end
    end
    -- `Save` no existe en Progression: la llamada estaba guardada por un `if`, asi que no fallaba
    -- -- simplemente no invalidaba nada. `Set` es el que persiste y refresca los efectos.
    if HarfordDnDProgression.Set then HarfordDnDProgression.Set(profileName, data) end
    return true
end

function API.Dismiss(profileName)
    if not (HarfordDnDProgression and HarfordDnDProgression.Get) then return false end
    local data = HarfordDnDProgression.Get(Perfil(profileName))
    data.activeCompanion = ""
    data.activeCompanionHP = 0
    if HarfordDnDProgression.Set then HarfordDnDProgression.Set(Perfil(profileName), data) end
    return true
end

-- Ajusta los PG de la criatura. Devuelve los nuevos PG, o nil si no hay ninguna invocada.
function API.AdjustHP(delta, profileName)
    profileName = Perfil(profileName)
    local c = API.GetActive(profileName)
    if not c then return nil end
    local data = HarfordDnDProgression.Get(profileName)
    local maximo = API.GetMaxHP(c, profileName)
    local nuevo = math.max(0, math.min(maximo, (tonumber(data.activeCompanionHP) or 0) + (tonumber(delta) or 0)))
    data.activeCompanionHP = nuevo
    -- `Save` no existe en Progression: la llamada estaba guardada por un `if`, asi que no fallaba
    -- -- simplemente no invalidaba nada. `Set` es el que persiste y refresca los efectos.
    if HarfordDnDProgression.Set then HarfordDnDProgression.Set(profileName, data) end
    if nuevo <= 0 then
        -- A 0 PG la criatura cae y deja de estar invocada. La Fortaleza No-Muerta del esbirro
        -- (salvacion para quedarse a 1 PG) es una tirada de mesa: se resuelve antes de anotar
        -- el dano, no automaticamente aqui.
        API.Dismiss(profileName)
        if HarfordDnDRolls and HarfordDnDRolls.Broadcast then
            HarfordDnDRolls.Broadcast({ type = "info", label = "pierde a su " .. tostring(c.name) .. " (0 PG)" })
        end
    end
    return nuevo
end
