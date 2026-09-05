-- HarfordDnDCalc: el calculo puro de la ficha.
--
-- Todo modificador del juego sale de aqui, y estaba practicamente sin cubrir: de 12 mutaciones que
-- se le hicieron al fichero, 11 pasaron sin que ninguna prueba se quejara. Un `>=` cambiado por `>`
-- en el umbral de critico no rompe nada visible -- simplemente los criticos dejan de salir.
--
-- El modulo se carga ENTERO con sus dependencias sustituidas, para poder fijar la ficha y ver que
-- devuelve. No se replica ninguna formula aqui: replicarla probaria la copia.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-54s %-10s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── Ficha de mentira, controlable desde cada prueba ────────────────────────
local FICHA, OVERRIDES, EFECTOS = {}, {}, {}
local CONTEXTO = { active = false, kind = nil, overrides = OVERRIDES }

local env = {
    ipairs = ipairs, pairs = pairs, tonumber = tonumber, tostring = tostring,
    type = type, select = select, table = table, string = string, math = math,
    HarfordDnDStore = { ToNumber = function(v, d)
        local n = tonumber(v)
        if n == nil then return d end
        return n
    end },
    HarfordDnDContext = {
        State = CONTEXTO,
        Get = function(clave, defecto)
            local v = FICHA[clave]
            if v == nil then return defecto end
            return v
        end,
    },
    HarfordDnDFeatureEffects = setmetatable({}, { __index = function(_, k) return EFECTOS[k] end }),
}
env.HarfordDnDCalc = nil

local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDCalc.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
f()
local C = env.HarfordDnDCalc

local function reset()
    for k in pairs(FICHA) do FICHA[k] = nil end
    for k in pairs(OVERRIDES) do OVERRIDES[k] = nil end
    for k in pairs(EFECTOS) do EFECTOS[k] = nil end
    CONTEXTO.active, CONTEXTO.kind = false, nil
end

-- ─── Modificador de caracteristica ──────────────────────────────────────────
-- La tabla del manual. Los impares son los que separan un `floor` de un `ceil`, y los negativos los
-- que separan `floor` de truncar hacia cero: 9 tiene que dar -1, no 0.
print("Modificador de caracteristica: la tabla del manual")
local esperados = { [1] = -5, [3] = -4, [8] = -1, [9] = -1, [10] = 0, [11] = 0,
                    [12] = 1, [13] = 1, [14] = 2, [15] = 2, [20] = 5, [30] = 10 }
for score = 1, 30 do
    if esperados[score] then
        chk("puntuacion " .. score, C.AbilityMod(score), esperados[score])
    end
end
chk("sin puntuacion, cuenta como 10", C.AbilityMod(nil), 0)

-- ─── Critico y pifia ────────────────────────────────────────────────────────
-- Aqui viven los `>=` que ninguna prueba miraba. El umbral es 20 por defecto y 19 con rasgos como
-- Maquina de Matar, asi que la comparacion tiene que ser >=, no ==.
print("Critico y pifia, normal")
chk("20 es critico", C.GetCritTag(nil, 20, nil), "CRÍTICO")
chk("19 no lo es por defecto", C.GetCritTag(nil, 19, nil), "")
chk("1 es pifia", C.GetCritTag(nil, 1, nil), "PIFIA")
chk("10 no es nada", C.GetCritTag(nil, 10, nil), "")
print("Critico con umbral ampliado a 19")
chk("19 ya es critico", C.GetCritTag(nil, 19, nil, 19), "CRÍTICO")
chk("y 20 tambien", C.GetCritTag(nil, 20, nil, 19), "CRÍTICO")
chk("18 sigue sin serlo", C.GetCritTag(nil, 18, nil, 19), "")

-- Con ventaja basta UNO; con desventaja hacen falta los DOS. Es la diferencia que un `and` por `or`
-- se llevaria por delante sin que nada mas cambiara.
print("Con ventaja basta uno; con desventaja hacen falta los dos")
chk("ventaja: 20 y 3 es critico", C.GetCritTag("adv", 20, 3), "CRÍTICO")
chk("ventaja: 3 y 20 tambien", C.GetCritTag("adv", 3, 20), "CRÍTICO")
chk("desventaja: 20 y 3 NO es critico", C.GetCritTag("dis", 20, 3), "")
chk("desventaja: 20 y 20 si", C.GetCritTag("dis", 20, 20), "CRÍTICO")
chk("ventaja: 1 y 1 es pifia", C.GetCritTag("adv", 1, 1), "PIFIA")
chk("ventaja: 1 y 5 no", C.GetCritTag("adv", 1, 5), "")
chk("desventaja: 1 y 5 si es pifia", C.GetCritTag("dis", 1, 5), "PIFIA")

-- ─── Eleccion de dado ───────────────────────────────────────────────────────
print("Ventaja se queda el alto; desventaja el bajo")
chk("normal ignora el segundo", (C.RollTextWithMode(nil, 7, 19)), 7)
chk("ventaja coge el alto", (C.RollTextWithMode("adv", 7, 19)), 19)
chk("desventaja coge el bajo", (C.RollTextWithMode("dis", 7, 19)), 7)
local _, _, rb = C.RollTextWithMode(nil, 7, 19)
chk("y sin modo no hay segundo dado", rb, "nil")

-- ─── Texto de los dados ─────────────────────────────────────────────────────
print("Texto de los dados")
chk("un dado solo", C.FormatD20Dice(14, 14, nil), "14")
chk("dos dados", C.FormatD20Dice(19, 7, 19), "7/19→19")

-- ─── Concatenado de bonos ───────────────────────────────────────────────────
-- Los ceros NO se escriben: un "+0" en la linea es ruido que no aporta.
print("Concatenado de bonos: los ceros no se escriben")
chk("varios", C.BonusConcat(3, -1, 2), "+3-1+2")
chk("el cero se cae", C.BonusConcat(3, 0, 2), "+3+2")
chk("todos cero", C.BonusConcat(0, 0), "")
chk("ninguno", C.BonusConcat(), "")
chk("texto que no es numero cuenta como cero", C.BonusConcat("x", 4), "+4")

-- ─── Bonus de competencia ───────────────────────────────────────────────────
print("Bonus de competencia")
reset()
chk("sin nada, el de nivel 1", C.GetPB(), 2)
FICHA.BonusCompetencia = 4
chk("lo que diga la ficha", C.GetPB(), 4)
-- Un rasgo que lo derive manda sobre el valor escrito.
EFECTOS.GetProficiencyBonus = function() return 3 end
chk("y un rasgo derivado manda", C.GetPB(), 3)
reset()

-- ─── Habilidades ────────────────────────────────────────────────────────────
print("Habilidad: caracteristica, competencia y pericia")
local ATL = { id = "atletismo", name = "Atletismo", ability = "Fuerza" }
FICHA.Fuerza = 16          -- Mod +3
FICHA.BonusCompetencia = 3
local base, prof = C.GetSkillRollBonuses(ATL)
chk("sin competencia: solo la caracteristica", base .. "/" .. prof, "3/0")
FICHA.Hab_atletismo_Prof = 1
base, prof = C.GetSkillRollBonuses(ATL)
chk("con competencia: mas el PB", base .. "/" .. prof, "3/3")
FICHA.Hab_atletismo_Exp = 1
base, prof = C.GetSkillRollBonuses(ATL)
chk("con pericia: el PB DOBLE", base .. "/" .. prof, "3/6")
-- La pericia manda aunque la competencia no este marcada: tener pericia la implica.
FICHA.Hab_atletismo_Prof = 0
base, prof = C.GetSkillRollBonuses(ATL)
chk("la pericia sola ya dobla", base .. "/" .. prof, "3/6")
reset()

print("Un rasgo puede dar competencia o pericia sin tocar la ficha")
FICHA.Fuerza, FICHA.BonusCompetencia = 16, 3
EFECTOS.GetSkillRank = function(id) return id == "atletismo" and 1 or 0 end
chk("rango 1 = competente", select(2, C.GetSkillRollBonuses(ATL)), 3)
EFECTOS.GetSkillRank = function(id) return id == "atletismo" and 2 or 0 end
chk("rango 2 = pericia", select(2, C.GetSkillRollBonuses(ATL)), 6)
EFECTOS.GetSkillRank = function() return 0 end
EFECTOS.GetBonus = function(tipo, id) return (tipo == "skill" and id == "atletismo") and 2 or 0 end
chk("y un bonus suelto se suma a la base", (C.GetSkillRollBonuses(ATL)), 5)
reset()

-- ─── Salvaciones ────────────────────────────────────────────────────────────
print("Salvaciones")
FICHA.Destreza, FICHA.BonusCompetencia = 14, 3     -- Mod +2
base, prof = C.GetSaveRollBonuses("Destreza")
chk("sin competencia", base .. "/" .. prof, "2/0")
FICHA.Salv_Destreza = 1
base, prof = C.GetSaveRollBonuses("Destreza")
chk("con competencia", base .. "/" .. prof, "2/3")
-- Un rasgo tambien puede darla, sin que este marcada en la ficha.
FICHA.Salv_Destreza = 0
EFECTOS.HasSaveProf = function(a) return a == "Destreza" end
chk("o la da un rasgo", select(2, C.GetSaveRollBonuses("Destreza")), 3)
chk("pero solo en la que dice", select(2, C.GetSaveRollBonuses("Fuerza")), 0)
EFECTOS.HasSaveProf = nil

-- Aura de Proteccion del Paladin: suma a TODAS, y nunca menos de 1 aunque el Mod. sea negativo.
print("Un aura que suma a TODAS las salvaciones")
FICHA.Carisma = 18                                  -- Mod +4
EFECTOS.GetAllSavesAbilities = function() return { { ability = "Carisma", min = 1 } } end
chk("suma el modificador", (C.GetSaveRollBonuses("Destreza")), 6)
FICHA.Carisma = 8                                   -- Mod -1
chk("pero nunca menos del minimo", (C.GetSaveRollBonuses("Destreza")), 3)
reset()

-- ─── Iniciativa ─────────────────────────────────────────────────────────────
print("Iniciativa")
FICHA.Destreza, FICHA.BonusCompetencia = 14, 3
EFECTOS.GetBonus = function(t) return t == "initiative" and 1 or 0 end
chk("bonus suelto", C.GetInitiativeBonus(), 1)
-- Alacridad del Picaro Forajido: suma tambien el Mod. de Carisma.
FICHA.Carisma = 18
EFECTOS.GetInitiativeAbilities = function() return { "Carisma" } end
chk("mas una caracteristica extra", C.GetInitiativeBonus(), 5)
-- Afinidad Aire del Chaman: suma el bonus de competencia.
EFECTOS.HasFlag = function(f) return f == "initiativeProfBonus" end
chk("mas el bonus de competencia", C.GetInitiativeBonus(), 8)
reset()

-- ─── Competencia con armas ──────────────────────────────────────────────────
print("Competencia con armas: por categoria o por nombre")
EFECTOS.HasWeaponProf = function(clave) return clave == "sencillas" or clave == "espadas cortas" end
chk("por categoria simple", C.HasWeaponProficiency({ key = "Maza", cat = "Simple" }), true)
chk("por nombre concreto", C.HasWeaponProficiency({ key = "espadas cortas", cat = "Marcial" }), true)
chk("marcial sin competencia, no", C.HasWeaponProficiency({ key = "Alabarda", cat = "Marcial" }), false)
-- El golpe sin armas lo domina todo el mundo.
chk("desarmado siempre", C.HasWeaponProficiency({ key = "Desarmado", cat = "Especial" }), true)
reset()

-- ─── Contexto NPC ───────────────────────────────────────────────────────────
-- La ficha NPC NO debe mirar los rasgos del jugador: sale del stat block y de los overrides.
print("En contexto NPC no se cuelan los rasgos del jugador")
CONTEXTO.active, CONTEXTO.kind = true, "npc"
FICHA.BonusCompetencia = 5
EFECTOS.GetProficiencyBonus = function() return 99 end
chk("el PB sale del stat block", C.GetPB(), 5)
EFECTOS.GetBonus = function() return 99 end
FICHA.Fuerza = 16
chk("y la habilidad no suma bonos del jugador", (C.GetSkillRollBonuses(ATL)), 3)
chk("ni el ataque con arma", C.GetWeaponAttackBonus(), 0)
chk("ni el dano", C.GetWeaponDamageBonus(), 0)
chk("y toda arma es competente", C.HasWeaponProficiency({ key = "Alabarda", cat = "Marcial" }), true)
-- Un override explicito manda sobre el calculo.
OVERRIDES["Context_Hab_atletismo_Bonus"] = 7
base, prof = C.GetSkillRollBonuses(ATL)
chk("un override explicito manda", base .. "/" .. prof, "7/0")
reset()

-- ─── Dados ──────────────────────────────────────────────────────────────────
-- Es aleatorio, asi que lo unico comprobable es el rango, y por eso se tira muchas veces.
print("Los dados caen dentro de su rango")
local minimo, maximo = 21, 0
for _ = 1, 400 do
    local v = C.RollDie(20)
    if v < minimo then minimo = v end
    if v > maximo then maximo = v end
end
chk("nunca por debajo de 1", minimo >= 1, true)
chk("nunca por encima de 20", maximo <= 20, true)
chk("y en 400 tiradas sale el 20", maximo, 20)
chk("y sale el 1", minimo, 1)

-- ─── RollD20 elige el dado, no solo lo formatea ─────────────────────────────
-- `RollTextWithMode` recibe los dos dados ya tirados; `RollD20` los tira Y elige. Son dos sitios
-- distintos donde se puede confundir el alto con el bajo, y hasta ahora solo se miraba uno.
print("RollD20 tira dos dados y se queda con el que toca")
local malAdv, malDis, sinSegundo = 0, 0, 0
for _ = 1, 300 do
    local elegido, a1, b1 = C.RollD20("adv")
    if elegido ~= math.max(a1, b1) then malAdv = malAdv + 1 end
    local e2, a2, b2 = C.RollD20("dis")
    if e2 ~= math.min(a2, b2) then malDis = malDis + 1 end
    local _, _, b3 = C.RollD20(nil)
    if b3 ~= nil then sinSegundo = sinSegundo + 1 end
end
chk("con ventaja siempre el alto", malAdv, 0)
chk("con desventaja siempre el bajo", malDis, 0)
chk("y sin modo no hay segundo dado", sinSegundo, 0)

-- ─── Competencia con arma: entradas que no son un arma ──────────────────────
-- Si no se sabe con que se pega, no se puede afirmar que NO se sea competente: penalizaria una
-- tirada por un dato que falta, que es peor que dejarla pasar.
print("Sin datos del arma no se castiga la tirada")
EFECTOS.HasWeaponProf = function() return false end
chk("sin definicion", C.HasWeaponProficiency(nil), true)
chk("con basura", C.HasWeaponProficiency("una espada"), true)
reset()

-- ─── Salvacion en contexto NPC ──────────────────────────────────────────────
print("La salvacion del NPC sale de su stat block")
CONTEXTO.active, CONTEXTO.kind = true, "npc"
FICHA.Constitucion, FICHA.BonusCompetencia = 16, 4
chk("sin competencia marcada", select(2, C.GetSaveRollBonuses("Constitucion")), 0)
FICHA.Salv_Constitucion = 1
chk("con competencia marcada", select(2, C.GetSaveRollBonuses("Constitucion")), 4)
-- Y un rasgo del JUGADOR no puede darsela a un NPC.
EFECTOS.HasSaveProf = function() return true end
FICHA.Salv_Constitucion = 0
chk("un rasgo del jugador no cuenta", select(2, C.GetSaveRollBonuses("Constitucion")), 0)
reset()

-- ─── Tirada completa: marca de modo y estados de un solo uso ────────────────
-- La marca V/D es la que viaja en la tirada difundida: sin ella, el resto de la mesa no ve que se
-- tiro con ventaja.
print("La tirada completa marca el modo")
local MODO, CONSUMIDOS, RETIRADOS = "normal", {}, {}
env.HarfordDnDConditions = {
    ResolveRollMode = function() return MODO end,
    ConditionsToConsumeAfterRoll = function() return CONSUMIDOS end,
    RemoveOwned = function(id) RETIRADOS[#RETIRADOS + 1] = id end,
}
FICHA.Modo = "normal"
local _, _, _, _, marca = C.RollD20Full("attack", { actorUnit = "player" })
chk("normal no marca", marca, "")
MODO = "adv"
_, _, _, _, marca = C.RollD20Full("attack", { actorUnit = "player" })
chk("ventaja marca V", marca, "V")
MODO = "dis"
_, _, _, _, marca = C.RollD20Full("attack", { actorUnit = "player" })
chk("desventaja marca D", marca, "D")

-- Un estado de un solo uso (Buey Negro, Fortaleza) se gasta al tirar. Pero solo si tiras TU: son
-- estados tuyos, y una tirada de otro no puede gastartelos.
print("Los estados de un solo uso los gasta quien tira, y solo si es suyo")
MODO, CONSUMIDOS, RETIRADOS = "normal", { "buey_negro" }, {}
C.RollD20Full("attack", { actorUnit = "player" })
chk("tirando yo, se gasta", RETIRADOS[1], "buey_negro")
RETIRADOS = {}
C.RollD20Full("attack", { actorUnit = "target" })
chk("tirando otro, no se toca", #RETIRADOS, 0)
-- Sin GUID por ningun lado: `nil == nil` no puede significar "somos el mismo".
RETIRADOS = {}
C.RollD20Full("attack", { actorUnit = "target", actorGuid = nil })
chk("y sin GUID tampoco se cuenta como mia", #RETIRADOS, 0)
-- Con MI guid si es mia, aunque la unidad no diga "player".
env.UnitGUID = function() return "Player-1-0000" end
RETIRADOS = {}
C.RollD20Full("attack", { actorUnit = "target", actorGuid = "Player-1-0000" })
chk("con mi GUID si es mia", RETIRADOS[1], "buey_negro")
RETIRADOS = {}
C.RollD20Full("attack", { actorUnit = "target", actorGuid = "Player-9-9999" })
chk("con el GUID de otro, no", #RETIRADOS, 0)
env.UnitGUID = nil
env.HarfordDnDConditions = nil
reset()

-- ─── Versatil ───────────────────────────────────────────────────────────────
print("Versatil es un si/no de la ficha")
reset()
chk("por defecto no", C.GetVersatileActive(), false)
FICHA.Versatil = 1
chk("activado", C.GetVersatileActive(), true)
FICHA.Versatil = 0
chk("desactivado", C.GetVersatileActive(), false)
reset()

-- ─── PB de conjuros ─────────────────────────────────────────────────────────
-- El stat block de un NPC puede traer un bonus de conjuro DISTINTO del suyo normal. Ese valor es
-- exclusivo del contexto NPC: en la ficha de un jugador debe ignorarse.
print("El PB de conjuro propio del stat block es solo del NPC")
FICHA.BonusCompetencia = 3
CONTEXTO.spellProficiencyBonus = 7
chk("en ficha de jugador se ignora", C.GetSpellPB(), 3)
CONTEXTO.active, CONTEXTO.kind = true, "npc"
chk("en ficha NPC manda", C.GetSpellPB(), 7)
CONTEXTO.spellProficiencyBonus = nil
chk("y sin el, cae al PB normal", C.GetSpellPB(), 3)
reset()
CONTEXTO.spellProficiencyBonus = nil

-- ─── Habilidad del NPC ──────────────────────────────────────────────────────
print("La habilidad del NPC sale de sus banderas, no de rasgos")
CONTEXTO.active, CONTEXTO.kind = true, "npc"
FICHA.Fuerza, FICHA.BonusCompetencia = 16, 4
chk("sin banderas", select(2, C.GetSkillRollBonuses(ATL)), 0)
FICHA.Hab_atletismo_Prof = 1
chk("competente", select(2, C.GetSkillRollBonuses(ATL)), 4)
FICHA.Hab_atletismo_Exp = 1
chk("con pericia, doble", select(2, C.GetSkillRollBonuses(ATL)), 8)
-- Un rasgo del jugador no puede dar pericia a un NPC.
FICHA.Hab_atletismo_Prof, FICHA.Hab_atletismo_Exp = 0, 0
EFECTOS.GetSkillRank = function() return 2 end
chk("un rango de rasgo no cuenta", select(2, C.GetSkillRollBonuses(ATL)), 0)
reset()

-- ─── Sin sistema de rasgos cargado ──────────────────────────────────────────
-- Si el motor de rasgos no esta, no se puede afirmar que NO seas competente. Negarlo penalizaria
-- todas las tiradas por una dependencia que falta.
print("Sin motor de rasgos, se concede la competencia")
EFECTOS.HasWeaponProf = nil
chk("cualquier arma", C.HasWeaponProficiency({ key = "Alabarda", cat = "Marcial" }), true)
reset()

-- ─── Lo que NO se cubre, y por que ──────────────────────────────────────────
-- `mutaciones.py` deja viva una sola: `n >= 0` por `n > 0` en `fmtSigned` (linea 14). No es un
-- hueco: `fmtSigned` solo se llama desde `BonusConcat`, que filtra los ceros ANTES de llamarla, asi
-- que las dos comparaciones no pueden dar resultados distintos nunca. Escribirle una prueba
-- obligaria a exponer una funcion local solo para eso. Si algun dia se llama desde otro sitio con
-- un cero, esta nota deja de valer.

-- ─── MOVIMIENTO POR TURNO ───────────────────────────────────────────────────
-- Sale de la RAZA, que el libro declara en METROS. Los rasgos la modifican por `bonus.speed` y
-- una forma activa la sustituye entera -- si eres un oso, te mueves como un oso -- pero esa viene
-- en PIES, como el stat block de donde se lee.
print("El movimiento del turno sale de la raza")
local calc = io.open("Harford/DnD/Engine/HarfordDnDCalc.lua"):read("*a")
chk("existe la regla", calc:find("function HarfordDnDCalc.GetTurnMovement", 1, true) ~= nil, true)
chk("la forma manda sobre la raza", calc:find("if forma and tonumber(forma.speed) then", 1, true) ~= nil, true)
-- Las formas declaran pies; las razas, metros. Mezclarlos daria un oso que corre tres veces mas.
chk("y convierte los pies de la forma",
    calc:find("tonumber(forma.speed) * 0.3048", 1, true) ~= nil, true)
chk("los rasgos pueden modificarla",
    calc:find("HarfordDnDFeatureEffects.GetSpeed(base, profileName)", 1, true) ~= nil, true)
-- Las velocidades del libro estan en metros y son razonables: si alguna se colara en pies, un
-- personaje se moveria treinta metros por turno.
local razas = io.open("Harford/DnD/Data/HarfordDnDRaces.lua"):read("*a")
local fuera = 0
for v in razas:gmatch("speed = ([%d%.]+)") do
    local n = tonumber(v)
    if n and (n < 5 or n > 15) then fuera = fuera + 1 end
end
chk("y todas las razas van en metros", fuera, 0)

-- El contador tiene que decir cuanto te QUEDA: un numero suelto no dice si te has pasado, que es
-- lo unico que la mesa necesita saber. Y reiniciarse al empezar tu turno, o no significa nada.
local ataque = io.open("Harford/DnD/UI/HarfordDnDAttackUI.lua"):read("*a")
-- GetUnitSpeed devuelve varias velocidades. Si se pasan todas a tonumber,
-- la segunda se interpreta como BASE numerica: 8 deja de ser una velocidad.
-- Ejecutar la rama real del contador con los retornos completos del cliente.
do
    local inicio = assert(ataque:find('            local v = GetUnitSpeed', 1, true))
    local fin = assert(ataque:find('\n        else', inicio, true))
    local medir = assert(cargar('local trozo = 0.1; local avance\n'
        .. ataque:sub(inicio, fin - 1) .. '\nreturn avance or 0'))
    local previo = GetUnitSpeed
    for _, caso in ipairs({
        { pet = 8, player = 0, esperado = 0.7, nombre = "NPC andando con cuatro retornos" },
        { pet = 0, player = 0, esperado = 0, nombre = "NPC quieto no gasta metros" },
        { pet = 0, player = 8, esperado = 0.7, nombre = "respaldo player conserva primer retorno" },
    }) do
        GetUnitSpeed = function(unit)
            return caso[unit] or 0, 7, 7, 4.72
        end
        local ok, metros = pcall(medir)
        chk(caso.nombre .. " sin error", ok, true)
        chk(caso.nombre, ok and string.format("%.1f", metros or 0) or "error",
            string.format("%.1f", caso.esperado))
    end
    GetUnitSpeed = previo
end
print("Y el contador lo usa")
-- Superar el tope del NPC no lo bloquea ni suelta su posesion.
do
    local inicio = assert(ataque:find("        local tope = MaximoDelTurno()\n        if EnCombate()", 1, true))
    local fin = assert(ataque:find("        API.RecordedMovementInfo =", inicio, true))
    local fuente = "return function(API, totalMeters, EnCombate, DirigiendoLaEscena, HarfordServerActions, HarfordChat)\n"
        .. "local function MaximoDelTurno() return 9 end\n"
        .. "local function LlevandoNpc() return true end\n"
        .. ataque:sub(inicio, fin - 1) .. "\nend"
    local cerrar = assert(cargar(fuente))()
    local si, no = function() return true end, function() return false end
    local estado, envios, avisos, callback = {}, 0, 0
    local server = { UnpossessCurrentNpc = function(opts)
        envios = envios + 1; callback = opts.callback; return true
    end }
    local chat = { Print = function() avisos = avisos + 1 end }
    cerrar(estado, 8.9, si, si, server, chat)
    chk("antes del limite no suelta", envios, 0)
    cerrar(estado, 9, no, si, server, chat)
    chk("fuera de combate no suelta", envios, 0)
    cerrar(estado, 9, si, si, server, chat)
    cerrar(estado, 10, si, si, server, chat)
    chk("al agotarse no suelta la posesion", envios, 0)
    chk("no pide soltar la posesion", avisos, 0)
    cerrar({}, 9, si, no, server, chat)
    chk("sin autoridad DM no envia", envios, 0)
    chk("fin de sesion NPC no ancla al jugador",
        ataque:find("API.RecordedMovementAnchor = not sesionNpc and CapturarAncla() or nil", 1, true) ~= nil, true)
end
chk("muestra llevado y tope", ataque:find('"%s%.1f|r / %.1f m"', 1, true) ~= nil, true)
chk("avisa si te pasas", ataque:find("(se pasa ", 1, true) ~= nil, true)
chk("se reinicia en tu turno",
    ataque:find("T._myTurnListeners[#T._myTurnListeners + 1] = function()", 1, true) ~= nil, true)
-- Y se apunta DIRECTAMENTE en la lista, no por `RegisterMyTurnListener`: este fichero carga ANTES
-- que HarfordTurns (linea 102 del toc contra la 123) y esa funcion todavia no existe, asi que el
-- `if` que la comprobaba no se cumplia NUNCA y el oyente no llegaba a registrarse. La lista si se
-- puede sembrar, porque HarfordTurns la crea con `or {}` y respeta lo que encuentre.
chk("sin depender del orden de carga",
    ataque:find("_G.HarfordTurnOrderAPI = _G.HarfordTurnOrderAPI or {}", 1, true) ~= nil, true)
local turnosSrc = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
chk("y HarfordTurns respeta lo sembrado",
    turnosSrc:find("HarfordTurnOrderAPI._myTurnListeners = HarfordTurnOrderAPI._myTurnListeners or {}",
        1, true) ~= nil, true)
-- Se cuenta en la mesa AL PARAR, no en cada paso: difundir cada decima llenaria el canal para
-- decir lo mismo. Atlas lo hace continuo; aqui no hace falta.
chk("y se cuenta en la mesa al parar",
    ataque:find('HarfordDnDRolls.Broadcast({ type = "info", label = texto })', 1, true) ~= nil, true)
-- Reiniciar por turno NO se cuenta: el turno nuevo empieza limpio, no es que hayas terminado de
-- moverte.
chk("pero reiniciar no lo cuenta",
    ataque:find("ReiniciarPorTurno = function()", 1, true) ~= nil, true)

-- ─── VOLVER A DONDE TERMINASTE ──────────────────────────────────────────────
-- `worldport` es el UNICO comando de Harford que MUEVE a alguien, asi que se valida entero antes
-- de emitirlo: con coordenadas malas te deja fuera del mundo.
local acciones = io.open("Harford/Server/HarfordServerActions.lua"):read("*a")
local plantillas = io.open("Harford/Server/HarfordCommandTemplates.lua"):read("*a")
print("El regreso al ancla se valida antes de emitirse")
chk("hay plantilla", plantillas:find("HarfordCommandTemplates.WORLDPORT", 1, true) ~= nil, true)
chk("y accion validada", acciones:find("function API.WorldportSelf", 1, true) ~= nil, true)
chk("sin coordenadas no se manda", acciones:find('return false, "faltan coordenadas"', 1, true) ~= nil, true)
-- El mapa NO se adivina: portar con uno equivocado es peor que no portar.
chk("y sin mapa tampoco",
    acciones:find('return false, "la posicion guardada no trae mapa"', 1, true) ~= nil, true)
-- Seis decimales, como los emite Epsilon: redondear a menos te deja dentro de una pared.
chk("con seis decimales", acciones:find('string.format("%.6f", x)', 1, true) ~= nil, true)

chk("el mapa sale del servidor, no de la interfaz",
    ataque:find("GetInstanceInfo()", 1, true) ~= nil, true)
-- Y del retorno 8, que es `instanceMapID`. Contando huecos me comi uno y salia `isDynamic`, un
-- booleano: el ancla se quedaba SIN mapa y `WorldportSelf` se negaba a emitir, en silencio.
chk("y del retorno 8, que es el id de mapa",
    ataque:find("select(8, GetInstanceInfo())", 1, true) ~= nil, true)
chk("y se guarda hacia donde mirabas",
    ataque:find("GetPlayerFacing and GetPlayerFacing()", 1, true) ~= nil, true)
-- Va en un gesto DISTINTO del que se pulsa cada turno: no vaya a portarte por querer parar.
chk("volver es click derecho", ataque:find('if boton == "RightButton" then', 1, true) ~= nil, true)
-- El ancla del turno pasado no vale: volver ahi te devolveria un asalto entero atras.
chk("y el ancla se olvida en tu turno",
    ataque:find("API.RecordedMovementAnchor = nil", 1, true) ~= nil, true)
-- El salto de VUELTA no cuenta como que has andado. Al aterrizar el teleporte la muestra siguiente
-- veia varios metros de golpe y los sumaba: el tiron se pagaba a si mismo, volvias a pasarte al
-- instante y encadenabas teleportes.
chk("un salto grande no cuenta como paso", ataque:find("if avance > 5 then", 1, true) ~= nil, true)
-- Y lo recorrido se publica EN CADA PASO, no solo al parar: `GetRecordedMovementMeters` es lo que
-- lee la barra de la economia, y escribirlo solo en `StopTracking` la dejaba llena mientras el
-- contador corria por dentro y hasta avisaba de que lo habias agotado.
chk("lo recorrido se publica en cada paso",
    ataque:find("API.RecordedMovementMeters = totalMeters\n        button:SetText", 1, true) ~= nil, true)
chk("y se muestrea a 20 por segundo",
    ataque:find("local pollInterval = 0.05", 1, true) ~= nil, true)

-- ── COMO SE MIDE, SEGUN QUIEN SE MUEVE ──────────────────────────────────────
-- Un JUGADOR tiene posicion: se mide de donde estaba a donde esta, que es el dato real. De una
-- criatura POSEIDA no hay posicion que leer (`UnitPosition` solo habla del jugador), asi que se
-- integra su velocidad. Es una estimacion, pero es la unica via.
print("El movimiento se mide distinto segun quien se mueva")
chk("un NPC poseido es el `pet`", ataque:find('UnitExists("pet")', 1, true) ~= nil, true)
-- MODELO ATLAS REAL (combat_tracker OnUpdate): la velocidad es solo el DETECTOR de "se esta
-- moviendo" y el gasto avanza a RITMO FIJO de 7 m/s. Multiplicar por la velocidad medida
-- fallaba en Epsilon, que puede exponerla a 0 o en el cuerpo equivocado durante la posesion.
chk("gasto a ritmo fijo de Atlas (7 m/s)",
    ataque:find("avance = 7 * trozo", 1, true) ~= nil, true)
-- Detector en `pet` y, si da cero, en `player`: en algunos clientes la orden de movimiento de
-- la posesion se expone en el cuerpo del jugador. Solo DETECTA: el gasto sigue siendo fijo.
-- El respaldo player se ejecuta con retornos multiples en el candado de arriba.
-- Las sesiones no se mezclan: la del jugador se corta y reinicia como NPC al poseer (el gasto
-- del NPC caia en la barra del PLAYER), y la del NPC se corta al des-poseer (el ritmo fijo
-- seguiria descontando mientras el DM anda libre).
chk("sesion etiquetada al arrancar",
    ataque:find("sesionNpc = LlevandoNpc() and true or false", 1, true) ~= nil, true)
chk("posesion sobre sesion de jugador reinicia",
    ataque:find("if not sesionNpc and LlevandoNpc() then", 1, true) ~= nil, true)
chk("des-posesion corta la sesion NPC",
    ataque:find("if sesionNpc and not LlevandoNpc() then", 1, true) ~= nil, true)
chk("y el jugador sigue midiendose por posicion",
    ataque:find("local x, y, z = GetPosition()", 1, true) ~= nil, true)
-- Al NPC se le cuenta, pero NO se le pone muro: `worldport` mueve tu cuerpo, no a la criatura
-- poseida, y `npc info` actua sobre el objetivo, que mientras posees no es ella. Es lo mismo que
-- hace Atlas, cuyo muro se salta entero al poseer.
chk("al NPC no se le pone muro",
    ataque:find("API.MovimientoSinMuro = true", 1, true) ~= nil, true)

-- ── ESTAR EN COMBATE ES UNA CONDICION, NO UN DETALLE ────────────────────────
-- El movimiento del turno solo significa algo dentro de un combate por turnos: fuera de el no hay
-- turno que gastar y un contador corriendo miente.
-- ── EL MOTOR NO PUEDE COLGAR DE LA FICHA ────────────────────────────────────
-- WoW no ejecuta `OnUpdate` en un frame OCULTO, y el boton de movimiento vive dentro de la seccion
-- Ataque: con la ficha cerrada el contador no contaba nada, sin que nada lo dijera. "Funcionaba"
-- al pulsarlo solo porque para pulsarlo tenias la ficha abierta.
print("El contador corre con la ficha cerrada")
chk("hay un frame motor propio",
    ataque:find('CreateFrame("Frame", "HarfordMovementDriver", UIParent)', 1, true) ~= nil, true)
chk("y esta siempre mostrado", ataque:find("motor:Show()", 1, true) ~= nil, true)
chk("el OnUpdate va en el motor",
    ataque:find('motor:SetScript("OnUpdate", OnUpdate)', 1, true) ~= nil, true)
-- Y NO en el boton: ese es solo el mando.
chk("y no en el boton",
    ataque:find('button:SetScript("OnUpdate"', 1, true) == nil, true)

print("El movimiento solo se cuenta en combate")
chk("no arranca solo fuera de combate",
    ataque:find("if not aMano and (not EnCombate() or not EsMiTurno()) then return end",
        1, true) ~= nil, true)
-- Ni fuera de TU turno: moverse es tuyo mientras te toca. Si no, cruzabas la sala gratis durante
-- el turno del enemigo.
chk("ni fuera de tu turno",
    ataque:find("local function EsMiTurno()", 1, true) ~= nil, true)
-- El NPC solo juega cuando ESTA en el bloque activo. No vale que exista `pet`: durante el turno de
-- Aliados no puede gastar el movimiento de un NPC de Enemigos, ni al reves.
chk("el NPC mira su bloque activo",
    ataque:find("T.IsNpcTurn(guid)", 1, true) ~= nil, true)
local turnosNpc = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
chk("y el bloque reconoce sus miembros",
    turnosNpc:find("for _, member in ipairs(entry.miembros or {}) do", 1, true) ~= nil, true)
-- Y su tope sale de la ficha NPC ya cargada, no de tu raza ni de consultar TRP3 sobre `pet`.
chk("y su tope sale de su ficha cargada",
    ataque:find("local function VelocidadDelNpc()", 1, true) ~= nil, true)
chk("sin consultar TRP3 sobre pet",
    ataque:find("HarfordDnDAPI.GetNpcMovementMeters(guid)", 1, true) ~= nil, true)
local fichaNpc = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
chk("la velocidad se publica por GUID",
    fichaNpc:find("function HarfordDnDAPI.GetNpcMovementMeters(guid)", 1, true) ~= nil, true)
chk("poseer durante el turno arranca el contador",
    ataque:find('ev:RegisterEvent("UNIT_PET")', 1, true) ~= nil
    and ataque:find("API.ReconciliarTurnoEnCurso()", 1, true) ~= nil, true)
chk("el NPC no requiere posicion del jugador",
    ataque:find("if not LlevandoNpc() then\n            x, y, z = GetPosition()", 1, true) ~= nil, true)
chk("la posesion notifica al motor antes del comando",
    io.open("HarfordAdmin/HarfordAdminUnitMenu.lua"):read("*a")
        :find("NotifyNpcPossessionRequested(snapshot.guid)", 1, true) ~= nil, true)
-- UNA sola cuenta: la barra del marcador usa la MISMA que el contador. Calcularla aparte daba dos
-- topes distintos --la barra el tuyo, el contador el del NPC-- y eso ya nos costo la barra entera.
chk("y la barra usa esa misma cuenta",
    ataque:find("if API.CalcularTopeTurno then return API.CalcularTopeTurno() end", 1, true) ~= nil, true)
-- Y se dice de QUIEN es: ensenar "9.0 m" a secas hace creer que son tus metros cuando son los de
-- un esqueleto.
chk("diciendo de quien es",
    ataque:find("function API.GetTurnMovementOwner()", 1, true) ~= nil, true)
local turnosSrc2 = io.open("Harford/Frames/HarfordTurns.lua"):read("*a")
chk("y el marcador lo pinta",
    turnosSrc2:find("local dueno = U.GetTurnMovementOwner and U.GetTurnMovementOwner()", 1, true) ~= nil, true)
-- Pero a MANO si: el boton tambien sirve para medir una distancia sin mas.
chk("pero a mano si", ataque:find("ArrancarSeguimiento(true)", 1, true) ~= nil, true)
-- Y se para al ACABAR el combate, que es el caso que se olvida: el turno no "termina", desaparece
-- el combate entero, y el contador se quedaba corriendo con un tope que ya no valia -- y el muro
-- devolviendote a un sitio de otro combate.
chk("y se para al acabar el combate, o al pasar el turno",
    ataque:find("if tracking and (not EnCombate() or not EsMiTurno()) then", 1, true) ~= nil, true)
-- Al pasar el turno se para DONDE ESTABAS y el ancla se queda: si sigues andando, el muro te
-- devuelve. Reiniciar del todo seria regalarte el movimiento del turno siguiente.
chk("dejando el ancla puesta",
    ataque:find("if not API.RecordedMovementAnchor then", 1, true) ~= nil, true)
-- Y FUERA de combate no limita nada: el contador mide, pero no ata. Ni se marca ancla ni se tira
-- de nadie. Todo esto es del modo combate; fuera, la gente hace lo que quiera como siempre.
chk("fuera de combate no se marca ancla",
    ataque:find("if EnCombate() and tope > 0 and totalMeters >= tope", 1, true) ~= nil, true)
chk("ni se tira de nadie",
    ataque:find("if not EnCombate() then return end\n            local ancla", 1, true) ~= nil, true)

-- ── EL MURO SALTA AL SOLTAR LA TECLA ────────────────────────────────────────
-- Un teleporte cada 0.75 s mientras corres es una rafaga de comandos y ademas se ve a trompicones.
-- Enganchando el soltar de cada tecla sale UN comando, y justo cuando has dejado de andar.
-- El muro salta EN EL INSTANTE en que se agota el recurso, no al parar: el movimiento se acaba
-- cuando se acaba, y esperar a que sueltes la tecla te regala los metros de en medio.
print("El muro salta al agotarse el recurso")
chk("se ancla en el momento",
    ataque:find("Anclar()\n            end", 1, true) ~= nil, true)
-- Y si sigues andando te devuelve otra vez: no es un aviso de una sola vez. El salto de vuelta no
-- cuenta como paso (guardia de 5 m), asi que no se realimenta.
chk("y vuelve a tirar si insistes",
    ataque:find("if API.RecordedMovementAnchor and EnCombate() then Anclar() end", 1, true) ~= nil, true)
-- Con enfriamiento: el servidor tarda en responder al worldport y sin el se mandaria uno por
-- muestra, veinte por segundo, mientras el primero esta de camino.
chk("con enfriamiento", ataque:find("if ahora - ultimoTiron < 0.6 then return end", 1, true) ~= nil, true)
-- Y SOLO si de verdad te alejaste: sin la guardia de distancia, el muro tiraba de ti cada 0,6 s
-- aunque estuvieras QUIETO encima del ancla (el PJ "saltaba" todo el turno ajeno y el worldport,
-- que fija orientacion, no dejaba ni girar). Se mide contra C_Epsilon.GetPosition, la misma
-- fuente del ancla; girar no cambia la posicion y queda libre.
chk("solo tira si estas lejos del ancla",
    ataque:find("if not LejosDelAncla(ancla) then return end", 1, true) ~= nil, true)
chk("midiendo contra la fuente del ancla",
    ataque:find("local function LejosDelAncla(ancla)", 1, true) ~= nil
    and ataque:find("local ok, x, y, z = pcall(C_Epsilon.GetPosition)", 1, true) ~= nil, true)
chk("con umbral que tolera el jitter",
    ataque:find("> 4  -- 2 yardas (~1,8 m) al cuadrado", 1, true) ~= nil, true)
-- `/harford libre`: roamear sin gasto ni muro y volver al ancla al empezar tu turno (un ciclo,
-- como el DM dirigiendo pero a peticion de cualquier jugador). El cambio de turno NO pisa su
-- ancla "casa" con la posicion de roameo, la vigilancia le salta, y al tocarle el turno el TP
-- de vuelta lo apaga.
print("Modo libre: roamear y volver")
chk("la vigilancia salta al modo libre",
    ataque:find("and not DirigiendoLaEscena() and not API.ModoLibre then", 1, true) ~= nil, true)
chk("el cambio de turno no pisa su ancla",
    ataque:find("if API.ModoLibre then return end", 1, true) ~= nil, true)
chk("al tocarle el turno vuelve y se apaga",
    ataque:find("(DirigiendoLaEscena() or API.ModoLibre) and EnCombate() then", 1, true) ~= nil
    and ataque:find('HarfordChat.Print("Modo libre terminado: de vuelta a tu posicion, con el movimiento integro.")', 1, true) ~= nil, true)
chk("activar captura la casa solo si no habia ancla",
    ataque:find("if not API.RecordedMovementAnchor then\n            API.RecordedMovementAnchor = CapturarAncla()", 1, true) ~= nil, true)
chk("apagarlo a mano en TU turno levanta el muro y reanuda el contador",
    ataque:find("if totalMeters < MaximoDelTurno() then API.RecordedMovementAnchor = nil end", 1, true) ~= nil, true)
-- El enganche de soltar tecla se queda como RESPALDO, por si la ultima muestra no llego a verlo.
chk("y el soltar la tecla queda de respaldo",
    ataque:find('"MoveForwardStop", "MoveBackwardStop",', 1, true) ~= nil, true)
-- Girar la camara con el raton NO es moverse: `TurnOrActionStop` queda fuera a proposito.
chk("pero no el giro de camara",
    ataque:find('"TurnOrActionStop"', 1, true) == nil, true)
chk("y no se dispara sin haberse pasado",
    ataque:find("if tope <= 0 or totalMeters <= tope + 0.3 then return end", 1, true) ~= nil, true)

-- ── DOS ANCLAS, DOS COSAS DISTINTAS ─────────────────────────────────────────
-- A la del INICIO se vuelve a mano, y deshace el turno entero. A la del AGOTAMIENTO te devuelve el
-- muro. Con una sola, "volver" te dejaba en el punto donde se te acabo, que no es lo que quieres
-- cuando te has colocado mal.
print("Dos anclas de movimiento")
chk("se guarda donde empiezas el turno",
    ataque:find("API.TurnStartAnchor = CapturarAncla()", 1, true) ~= nil, true)
chk("y volver ahi pone el contador a cero",
    ataque:find("local ancla = API.TurnStartAnchor", 1, true) ~= nil, true)

-- `Correr` dobla el tope de ESTE turno. Se guarda aparte del calculo de velocidad porque no es una
-- propiedad del personaje sino algo que hizo en este asalto -- y por eso se apaga al empezar el
-- siguiente, o el doble se heredaria para siempre.
print("Correr dobla el tope, y solo este turno")
chk("hay interruptor", ataque:find("function API.SetDashActive", 1, true) ~= nil, true)
chk("que dobla", ataque:find("corriendo and (base * 2) or base", 1, true) ~= nil, true)
chk("y se apaga en tu turno", ataque:find("corriendo = false", 1, true) ~= nil, true)
-- Y LEVANTA EL MURO si con el doble vuelve a caber: la accion se gastaba, el tope subia y el ancla
-- seguia devolviendote al metro nueve. O sea, Correr no hacia nada.
chk("Correr levanta el muro",
    ataque:find("if corriendo and API.RecordedMovementAnchor", 1, true) ~= nil, true)
chk("solo si con el doble vuelve a caber",
    ataque:find("and totalMeters < MaximoDelTurno() then", 1, true) ~= nil, true)
local panel2 = (io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a") .. io.open("Harford/Character/HarfordCharacterBookActions.lua"):read("*a"))
chk("y la accion lo enciende",
    panel2:find("HarfordDnDAttackUI.SetDashActive(true)", 1, true) ~= nil, true)

-- La unidad pertenece a la cifra, no a toda la descripcion: "a pie" no son pies.
do
    local srcNpc = io.open("HarfordAdmin/HarfordAdminNPC.lua"):read("*a")
    local inicio = assert(srcNpc:find("local function GetNpcMovementMeters(parsed)", 1, true))
    local fin = assert(srcNpc:find("\nfunction API.UpdateNpcSheetArmorClass", inicio, true))
    local leer = assert(cargar(srcNpc:sub(inicio, fin - 1) .. "\nreturn GetNpcMovementMeters"))()
    chk("9 m a pie no son 9 pies", leer({ speed = "9 m a pie" }), 9)
    chk("otra velocidad en pies no cambia caminar", leer({ speed = "9 metros, vuelo 30 pies" }), 9)
    chk("30 pies se convierten", leer({ speed = "30 pies" }), 30 * 0.3048)
    chk("30 ft se convierten", leer({ speed = "30 ft." }), 30 * 0.3048)
    chk("30 feet se convierten", leer({ speed = "30 feet" }), 30 * 0.3048)
    chk("decimal con coma", leer({ speed = "7,5 m a pie" }), 7.5)
    chk("velocidad de tabla", leer({ speed = { walk = "9 m a pie" } }), 9)
    chk("sin unidad conserva metros", leer({ speed = 9 }), 9)
    chk("sin cifra no inventa velocidad", leer({ speed = "desconocida" }), nil)
end

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
