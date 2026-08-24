-- HarfordDnDBeast: la bestia companera del Cazador (Domar Bestia / Vinculo del Compañero).
--
-- No es un bloque escrito a mano como el esbirro o los demonios: el manual dice "cualquier bestia"
-- (Mediana o menor de desafio 1/2; Grande o menor de desafio 1 con Domador de bestias) y NO trae
-- bestiario. Asi que el bloque lo escribe el jugador en su TRP3, igual que las formas druidicas, y
-- este modulo lo lee y le aplica encima las reglas del Vinculo del Compañero.
--
-- Se registra como PROVEEDOR de HarfordDnDCompanions: la bestia entra por la misma puerta que las
-- demas criaturas y comparte estado, PG, flyout del Libro y ruta de ataque. Aqui solo esta lo que
-- es propio de ella: leer el TRP3 y transformar el bloque.
--
-- FORMATO ESPERADO EN EL TRP3 (frame {h1}Compañero bestial{/h1}, y dentro un {h2} por bestia):
--
--   {h1}Compañero bestial{/h1}
--   {h2}{icon:Ability_Hunter_Pet_Wolf:25}Lobo{/h2}
--   CA 13   PG 11 (2d8 + 2)   Velocidad 40 pies
--   {h3}Mordisco{/h3}
--   Ataque de arma cuerpo a cuerpo: +4 al ataque, alcance 5 pies, un objetivo.
--   Impacto: 2d4 + 2 de dano perforante.
--
-- El bloque se escribe TAL CUAL viene del bestiario, con su propia competencia (+2). El Vinculo
-- se aplica encima; no hay que precalcular nada.

HarfordDnDBeast = HarfordDnDBeast or {}

local API = HarfordDnDBeast

local SECCION = "companero_bestial"
local NIVEL_VINCULO = 3   -- "Domar Bestia" y el Vinculo del Compañero llegan a nivel 3

-- Reutiliza los helpers de TRP3 de las formas druidicas: es el mismo About, el mismo markup y el
-- mismo problema de acentos. Duplicar el limpiador seria dos sitios donde arreglar el mismo bug.
local function Limpio(v)
    v = tostring(v or "")
    v = v:gsub("{icon:[^}]+}", ""):gsub("{col:[^}]+}", ""):gsub("{/col}", ""):gsub("{[^}]+}", "")
    v = v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return (v:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Clave(v)
    v = HarfordClassColors.StripAccents(Limpio(v)):lower()
    return (v:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", ""))
end

local function Icono(v)
    local ico = tostring(v or ""):match("{icon:([^}:]+)")
    if not ico or ico == "" then return nil end
    if ico:find("^Interface\\", 1, false) then return ico end
    return "Interface\\Icons\\" .. ico
end

local function TextoAbout()
    if not (HarfordTRP3 and HarfordTRP3.GetPlayerProfile) then return nil end
    local profile = HarfordTRP3.GetPlayerProfile("player")
    local character = profile and (profile.player or profile)
    local about = character and character.about
    if type(about) ~= "table" then return nil end
    local partes = {}
    local function add(sec)
        local t = type(sec) == "table" and sec.TX or nil
        if t and t ~= "" then partes[#partes + 1] = tostring(t) end
    end
    add(about.T1)
    for _, sec in ipairs(about.T2 or {}) do add(sec) end
    for _, sec in pairs(about.T3 or {}) do add(sec) end
    return #partes > 0 and table.concat(partes, "\n") or nil
end

local function Bloques(texto, tag)
    local out, pos = {}, 1
    while true do
        local ini, fin = texto:find("{" .. tag .. "[^}]*}", pos)
        if not ini then break end
        local cierraIni, cierraFin = texto:find("{/" .. tag .. "}", fin + 1, true)
        if not cierraIni then break end
        local sig = texto:find("{" .. tag .. "[^}]*}", cierraFin + 1)
        out[#out + 1] = {
            title = texto:sub(fin + 1, cierraIni - 1),
            body = texto:sub(cierraFin + 1, (sig and sig - 1) or #texto),
        }
        pos = cierraFin + 1
    end
    return out
end

local function Seccion(raw)
    for _, b in ipairs(Bloques(raw or "", "h1")) do
        if Clave(b.title) == SECCION then return b.body end
    end
    return nil
end

-- Un ataque del bestiario: "+4 al ataque ... 2d4 + 2 de dano perforante".
local function LeerAccion(bloque)
    local body = HarfordClassColors.StripAccents(Limpio(bloque.body)):lower()
    if not body:find("ataque de arma", 1, true) and not body:find("ataque de conjuro", 1, true) then
        return nil
    end
    local n, caras, signo, fijo, tipo = body:match("(%d*)d(%d+)%s*([+-])%s*(%d+)%s+de%s+dano%s+([%a]+)")
    if not caras then n, caras, tipo = body:match("(%d*)d(%d+)%s+de%s+dano%s+([%a]+)") end
    n, caras = tonumber(n == "" and "1" or n), tonumber(caras)
    if not (n and caras and tipo) then return nil end
    local bonoDano = tonumber(fijo) or 0
    if signo == "-" then bonoDano = -bonoDano end

    local sAtk, vAtk = body:match("([+-])%s*(%d+)%s+al%s+ataque")
    local ataque = tonumber(vAtk) or 0
    if sAtk == "-" then ataque = -ataque end

    if HarfordDamageTypes and HarfordDamageTypes.FromWord then
        tipo = HarfordDamageTypes.FromWord(tipo) or tipo
    end
    return {
        key = Limpio(bloque.title),
        icon = Icono(bloque.title),
        cat = "Acompanante",
        mode = body:find("a distancia", 1, true) and "Ranged" or "Melee",
        rangeFeet = tonumber(body:match("(%d+)%s+pies")) or 5,
        targetText = "un objetivo",
        dmgN = n, dmgS = caras, dmgType = tipo,
        addAbi = false,
        weaponDamageBonus = bonoDano,
        -- Vinculo del Compañero: "tu compañero tambien agrega su bonificador de competencia a su
        -- CA y a sus tiradas de dano". Es una SUMA, encima de lo que ya declare el bloque.
        damagePlusProficiency = true,
        attackBonus = ataque,
        ignoreGlobalWeaponBonuses = true,
        source = "beast",
        props = { "Natural" },
        note = Limpio(bloque.body),
    }
end

-- "PG 11 (2d8 + 2)" -> PG base 11, dado d8, Mod. Constitucion 1 (el +2 repartido entre 2 dados).
local function LeerPuntosDeGolpe(texto)
    local base = tonumber(texto:match("PG%s*(%d+)")) or tonumber(texto:match("Puntos de Golpe%s*(%d+)"))
    local nDados, caras = texto:match("%((%d+)d(%d+)")
    local signo, extra = texto:match("%(%d+d%d+%s*([+-])%s*(%d+)%)")
    nDados, caras = tonumber(nDados), tonumber(caras)
    local modCon = 0
    if nDados and nDados > 0 and extra then
        modCon = math.floor(tonumber(extra) / nDados)
        if signo == "-" then modCon = -modCon end
    end
    return base, caras, modCon
end

local function LeerBestias(raw)
    local seccion = raw and Seccion(raw)
    if not seccion then return {} end
    local out = {}
    for _, bloque in ipairs(Bloques(seccion, "h2")) do
        local titulo = Limpio(bloque.title)
        local cuerpo = HarfordClassColors.StripAccents(Limpio(bloque.body))
        local ca = tonumber(cuerpo:match("CA%s*(%d+)"))
        local pg, dado, modCon = LeerPuntosDeGolpe(cuerpo)
        if ca and pg and dado and Clave(titulo) ~= "" then
            local bestia = {
                id = "bestia_" .. Clave(titulo),
                name = titulo,
                icon = Icono(bloque.title) or "Interface\\Icons\\Ability_Hunter_BeastCall",
                classId = "cazador",
                minLevel = NIVEL_VINCULO,
                -- "a menos que uses tu accion adicional para ordenarle que realice la accion de
                -- Atacar, Correr, Desengancharse o Ayudar".
                commandAction = "adicional",
                creatureType = "Bestia companera",
                armorClassBase = ca,
                -- +PB a la CA (Vinculo del Compañero).
                acPlusProficiency = true,
                -- Su competencia se SUSTITUYE por la tuya. El bloque del bestiario esta escrito
                -- con +2, asi que el ajuste es `PB - 2`: exactamente el mismo escalado que
                -- "Poder del Maestro" de los demonios, por eso reusa ese campo.
                masterPower = { attack = true },
                hp = {
                    base = pg,
                    hitDie = dado,
                    hitDieConMod = modCon,
                    -- "Por cada nivel de personaje que ganes despues del 3, tu compañero gana un
                    -- dado de golpe adicional y aumenta sus puntos de golpe en consecuencia."
                    extraDiceAfterLevel = NIVEL_VINCULO,
                },
                speed = tonumber(cuerpo:match("Velocidad%s*(%d+)")) or 30,
                traits = {
                    "Vinculo del Compañero: usa TU bonificacion de competencia en lugar de la suya, y ademas la suma a su CA y a sus tiradas de dano.",
                    "Es competente en TODAS las tiradas de salvacion, y en dos habilidades que eliges tu.",
                    "Pierde su accion de Multiataque, si la tenia.",
                    "Comparte tu iniciativa pero actua justo despues de ti. Si estas incapacitado o ausente, actua por su cuenta.",
                },
                actions = {},
                source = "trp3",
            }
            for _, accionBloque in ipairs(Bloques(bloque.body, "h3")) do
                local accion = LeerAccion(accionBloque)
                if accion then bestia.actions[#bestia.actions + 1] = accion end
            end
            if #bestia.actions > 0 then out[#out + 1] = bestia end
        end
    end
    return out
end

-- Bestias declaradas en el TRP3 del jugador. Se lee en cada consulta: el About es la fuente y no
-- se cachea, igual que hacen las formas druidicas, para que editar el perfil se note al momento.
function API.GetBeasts()
    local ok, lista = pcall(LeerBestias, TextoAbout())
    if not ok then return {} end
    return lista or {}
end

if HarfordDnDCompanions and HarfordDnDCompanions.RegisterProvider then
    HarfordDnDCompanions.RegisterProvider(function() return API.GetBeasts() end)
end
