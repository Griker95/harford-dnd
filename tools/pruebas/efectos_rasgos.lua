-- HarfordDnDFeatureEffects: de aqui sale CADA bonus del personaje.
--
-- Todo lo que un rasgo concede pasa por este modulo: competencias, resistencias, dados de artes
-- marciales, umbral de critico, maximos de recurso. Estaba sin cubrir -- de 14 mutaciones, 13
-- pasaban --, y un fallo aqui no rompe nada: simplemente el rasgo deja de dar lo que dice.

local fallos = 0
local function chk(etiqueta, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-56s %-9s %s", etiqueta, tostring(real),
        ok and "ok" or ("FALLA, esperaba " .. tostring(esp))))
end

-- ─── Progresion de mentira, controlable ─────────────────────────────────────
local RASGOS, CLASES, ESTADOS, NIVELES = {}, {}, {}, {}

local env = setmetatable({}, { __index = function() return nil end })
env.ipairs, env.pairs, env.tonumber, env.tostring = ipairs, pairs, tonumber, tostring
env.type, env.math, env.table, env.string, env.select = type, math, table, string, select
env.setmetatable = setmetatable
env.HarfordClassColors = {
    NormalizeKey = function(v) return tostring(v or ""):lower() end,
    StripAccents = function(v) return v end,
}
env.HarfordDnDProgression = {
    GetUnlockedFeatures = function() return RASGOS end,
    IsFeatureEnabled = function() return true end,
    GetClassLevels = function() return NIVELES end,
    IsToggleStateActive = function(id) return ESTADOS[id] == true end,
    GetChoice = function() return {} end,
}
env.HarfordDnDBook = { GetClass = function(id) return CLASES[id] end }

local cargar = loadstring or load
local src = io.open("Harford/DnD/Engine/HarfordDnDFeatureEffects.lua"):read("*a")
local f
if setfenv then f = assert(cargar(src)); setfenv(f, env) else f = assert(cargar(src, "t", "t", env)) end
assert(pcall(f))
local F = env.HarfordDnDFeatureEffects

-- La cache es por perfil y por generacion; sin invalidar, la segunda prueba leeria la primera.
local function conRasgos(efectos)
    RASGOS = { { feature = { id = "prueba", effects = efectos } } }
    F.Invalidate()
end
local function conClases(niveles, defs)
    NIVELES, CLASES = niveles, defs
    F.Invalidate()
end

-- ─── Multiclase: la regla que mas se equivoca ───────────────────────────────
-- En 5e SOLO la primera clase da sus competencias de SALVACION. Las armaduras y armas, en cambio,
-- se unen todas. Confundirlo regala dos salvaciones a cualquier multiclase.
print("Multiclase: salvaciones solo de la PRIMERA clase")
RASGOS = {}
conClases(
    { { classId = "guerrero", level = 3 }, { classId = "picaro", level = 2 } },
    {
        guerrero = { saves = { "Fuerza", "Constitucion" }, armorProfs = { "pesada" },
                     weaponProfs = { "marciales" } },
        picaro   = { saves = { "Destreza", "Inteligencia" }, armorProfs = { "ligera" },
                     weaponProfs = { "sencillas" } },
    })
chk("Fuerza, de la primera", F.HasSaveProf("Fuerza"), true)
chk("Constitucion, de la primera", F.HasSaveProf("Constitucion"), true)
chk("Destreza, de la SEGUNDA, no", F.HasSaveProf("Destreza"), false)
chk("Inteligencia tampoco", F.HasSaveProf("Inteligencia"), false)

print("Pero las competencias de armadura y arma se UNEN")
chk("pesada, de la primera", F.Resolve().armorProf["pesada"], true)
chk("ligera, de la segunda, tambien", F.Resolve().armorProf["ligera"], true)
chk("marciales", F.Resolve().weaponProf["marciales"], true)
chk("y sencillas", F.Resolve().weaponProf["sencillas"], true)

-- Invertir el orden invierte quien da las salvaciones: es el orden en que se subio de nivel.
print("El orden importa: manda con que clase empezaste")
conClases(
    { { classId = "picaro", level = 2 }, { classId = "guerrero", level = 3 } },
    { guerrero = { saves = { "Fuerza" } }, picaro = { saves = { "Destreza" } } })
chk("ahora Destreza si", F.HasSaveProf("Destreza"), true)
chk("y Fuerza no", F.HasSaveProf("Fuerza"), false)
conClases({}, {})

-- ─── Habilidades: competencia y pericia ─────────────────────────────────────
print("Competencia y pericia se guardan como rango")
conRasgos({ { kind = "skillProf", skill = "atletismo" } })
chk("competencia es rango 1", F.GetSkillRank("atletismo"), 1)
conRasgos({ { kind = "skillExpertise", skill = "atletismo" } })
chk("pericia es rango 2", F.GetSkillRank("atletismo"), 2)
-- La pericia no puede bajar a competencia si llegan las dos: se queda el rango mayor.
conRasgos({ { kind = "skillExpertise", skill = "atletismo" },
            { kind = "skillProf", skill = "atletismo" } })
chk("las dos juntas: se queda la pericia", F.GetSkillRank("atletismo"), 2)
chk("una que no tiene, cero", F.GetSkillRank("sigilo"), 0)

-- ─── Bonos ──────────────────────────────────────────────────────────────────
print("Los bonos se SUMAN, no se pisan")
conRasgos({ { kind = "bonus", target = "armorClass", value = 1 },
            { kind = "bonus", target = "armorClass", value = 2 } })
chk("uno mas dos son tres", F.GetBonus("armorClass"), 3)
chk("y un objetivo sin bonos, cero", F.GetBonus("initiative"), 0)
print("Un bonus a una habilidad concreta va por su clave")
conRasgos({ { kind = "bonus", target = "skill", skill = "naturaleza", value = 2 } })
chk("la que dice", F.GetBonus("skill", "naturaleza"), 2)
chk("y no otra", F.GetBonus("skill", "sigilo"), 0)
conRasgos({ { kind = "bonus", target = "save", ability = "Destreza", value = 1 } })
chk("y una salvacion concreta, por su caracteristica", F.GetBonus("save", "Destreza"), 1)
chk("no las demas", F.GetBonus("save", "Fuerza"), 0)

-- ─── Estados activables ─────────────────────────────────────────────────────
-- Un efecto con `requiresState` solo cuenta con ese estado ENCENDIDO. Lobo Solitario del Cazador
-- da ataque extra solo mientras combatas sin companero.
print("Un efecto con `requiresState` no cuenta hasta que el estado se enciende")
conRasgos({
    { kind = "toggleState", state = "lobo", label = "Lobo Solitario" },
    { kind = "bonus", target = "armorClass", value = 5, requiresState = "lobo" },
})
ESTADOS = {}
F.Invalidate()
chk("apagado, no da nada", F.GetBonus("armorClass"), 0)
chk("pero el estado si se declara", F.GetToggleStates()[1] and F.GetToggleStates()[1].id, "lobo")
ESTADOS = { lobo = true }
F.Invalidate()
chk("encendido, ya da", F.GetBonus("armorClass"), 5)
ESTADOS = {}

-- ─── Defensas por tipo ──────────────────────────────────────────────────────
print("Resistencia, vulnerabilidad e inmunidad")
conRasgos({ { kind = "resist", damageType = "veneno" } })
chk("resiste", F.GetDamageStatus("veneno"), "resistant")
conRasgos({ { kind = "vuln", damageType = "fuego" } })
chk("vulnerable", F.GetDamageStatus("fuego"), "vulnerable")
conRasgos({ { kind = "immune", damageType = "veneno" } })
chk("inmune", F.GetDamageStatus("veneno"), "immune")
chk("un tipo sin nada, nil", F.GetDamageStatus("cortante"), "nil")
-- La inmunidad manda sobre la resistencia venga en el orden que venga: es mas fuerte.
print("La inmunidad manda sobre la resistencia, en cualquier orden")
conRasgos({ { kind = "resist", damageType = "veneno" }, { kind = "immune", damageType = "veneno" } })
chk("resistencia y luego inmunidad", F.GetDamageStatus("veneno"), "immune")
conRasgos({ { kind = "immune", damageType = "veneno" }, { kind = "resist", damageType = "veneno" } })
chk("inmunidad y luego resistencia", F.GetDamageStatus("veneno"), "immune")

-- ─── Umbral de critico ──────────────────────────────────────────────────────
-- Maquina de Matar baja el critico a 19, pero solo cuerpo a cuerpo. Se queda el MENOR.
print("Umbral de critico: se queda el menor, y el de melee solo con arma cuerpo a cuerpo")
conRasgos({})
chk("por defecto, 20", F.GetWeaponCritThreshold(false), 20)
conRasgos({ { kind = "critRange", value = 19, melee = true } })
chk("cuerpo a cuerpo baja a 19", F.GetWeaponCritThreshold(true), 19)
chk("a distancia sigue en 20", F.GetWeaponCritThreshold(false), 20)
conRasgos({ { kind = "critRange", value = 19 } })
chk("sin marcar melee, vale para todo", F.GetWeaponCritThreshold(false), 19)
-- Dos rasgos que lo bajan: se queda el mas bajo, no el ultimo.
conRasgos({ { kind = "critRange", value = 19 }, { kind = "critRange", value = 18 } })
chk("dos rebajas: la mejor", F.GetWeaponCritThreshold(false), 18)
conRasgos({ { kind = "critRange", value = 18 }, { kind = "critRange", value = 19 } })
chk("y da igual el orden", F.GetWeaponCritThreshold(false), 18)

-- ─── Sutileza concedida ─────────────────────────────────────────────────────
-- Iniciacion Illidari trata como Sutil las armas cuerpo a cuerpo sin Pesada ni Dos manos.
print("Sutileza concedida: solo donde el rasgo dice")
conRasgos({ { kind = "weaponFinesse", meleeOnly = true, excludeHeavy = true, excludeTwoHanded = true } })
chk("guja cuerpo a cuerpo", F.TreatWeaponAsFinesse({ key = "Guja", mode = "Melee", props = {} }), true)
chk("pero no un arco", F.TreatWeaponAsFinesse({ key = "Arco", mode = "Ranged", props = {} }), false)
chk("ni una pesada",
    F.TreatWeaponAsFinesse({ key = "Mandoble", mode = "Melee", props = { "Pesada" } }), false)
chk("ni una de dos manos",
    F.TreatWeaponAsFinesse({ key = "Pica", mode = "Melee", props = { "Dos manos" } }), false)
-- El desarmado y el escudo nunca: no son armas de las que se pueda hablar de sutileza.
chk("desarmado no", F.TreatWeaponAsFinesse({ key = "Desarmado", mode = "Melee", props = {} }), false)
chk("escudo tampoco", F.TreatWeaponAsFinesse({ key = "Escudo", mode = "Melee", props = {} }), false)
conRasgos({})
chk("y sin el rasgo, ninguna", F.TreatWeaponAsFinesse({ key = "Guja", mode = "Melee", props = {} }), false)

-- ─── Maximos de recurso y vida ──────────────────────────────────────────────
print("Maximos de recurso y vida por nivel")
conRasgos({ { kind = "resourceMax", resource = "chi", value = 3 },
            { kind = "resourceMax", resource = "chi", value = 2 } })
chk("los maximos se suman", F.GetResourceMaxBonus("chi"), 5)
chk("un recurso sin bonos, cero", F.GetResourceMaxBonus("rage"), 0)
conRasgos({ { kind = "hpPerLevel", value = 1 } })
chk("vida por nivel", F.GetHpPerLevelBonus(), 1)

-- ─── Banderas ───────────────────────────────────────────────────────────────
print("Banderas")
conRasgos({ { kind = "flag", flag = "extraAttack" } })
chk("la que hay", F.HasFlag("extraAttack"), true)
chk("y una que no", F.HasFlag("inventada"), false)
-- Una bandera con `requiresState` tampoco cuenta con el estado apagado.
conRasgos({ { kind = "flag", flag = "extraAttack", requiresState = "lobo" } })
chk("con estado apagado, no", F.HasFlag("extraAttack"), false)
ESTADOS = { lobo = true }
F.Invalidate()
chk("con estado encendido, si", F.HasFlag("extraAttack"), true)
ESTADOS = {}

-- ─── Inmunidad a condiciones ────────────────────────────────────────────────
print("Inmunidad a condiciones")
conRasgos({ { kind = "conditionImmunity", condition = "frightened" } })
chk("a la que dice", F.HasConditionImmunity("frightened"), true)
chk("y no a otra", F.HasConditionImmunity("poisoned"), false)
chk("y se puede listar", F.GetConditionImmunities()[1], "frightened")

-- ─── Caracteristicas que suman a iniciativa y salvaciones ───────────────────
print("Caracteristicas extra en iniciativa y salvaciones")
conRasgos({ { kind = "initiativeAbility", ability = "Carisma" } })
chk("iniciativa", F.GetInitiativeAbilities()[1], "Carisma")
conRasgos({ { kind = "allSavesAbility", ability = "Carisma", min = 1 } })
chk("todas las salvaciones", F.GetAllSavesAbilities()[1].ability, "Carisma")
chk("con su minimo", F.GetAllSavesAbilities()[1].min, 1)

-- ─── Defensa sin Armadura ───────────────────────────────────────────────────
-- Se declaran TODAS; quien decide que no se acumulan es HarfordDnDCombat, cogiendo la mejor.
print("Defensa sin Armadura: aqui se declaran, no se eligen")
conRasgos({ { kind = "unarmoredDefenseAbility", ability = "Sabiduria" },
            { kind = "unarmoredDefenseAbility", ability = "Inteligencia" } })
chk("se declaran las dos", #F.GetUnarmoredDefenseAbilities(), 2)

-- ─── La cache no puede servir datos viejos ──────────────────────────────────
-- `Resolve` cachea por perfil y generacion. Si `Invalidate` no subiera la generacion, cambiar de
-- rasgos no cambiaria nada y el personaje se quedaria con los bonos del anterior.
print("Invalidar la cache hace que se vuelva a resolver")
conRasgos({ { kind = "bonus", target = "armorClass", value = 1 } })
chk("primero uno", F.GetBonus("armorClass"), 1)
RASGOS = { { feature = { id = "otro", effects = { { kind = "bonus", target = "armorClass", value = 9 } } } } }
chk("sin invalidar, sigue el viejo", F.GetBonus("armorClass"), 1)
F.Invalidate()
chk("invalidando, el nuevo", F.GetBonus("armorClass"), 9)

-- ─── Vulnerabilidad frente a resistencia e inmunidad ────────────────────────
-- Resistencia y vulnerabilidad del mismo tipo no se anulan a medias: manda la vulnerabilidad. La
-- inmunidad, en cambio, no la tumba nada.
print("Vulnerabilidad sobre resistencia; la inmunidad no se pierde")
conRasgos({ { kind = "resist", damageType = "fuego" }, { kind = "vuln", damageType = "fuego" } })
chk("resistente y luego vulnerable", F.GetDamageStatus("fuego"), "vulnerable")
conRasgos({ { kind = "immune", damageType = "fuego" }, { kind = "vuln", damageType = "fuego" } })
chk("pero inmune no se pierde", F.GetDamageStatus("fuego"), "immune")

-- ─── Competencias de armadura y arma ────────────────────────────────────────
print("Competencias de armadura y arma")
conRasgos({ { kind = "armorProf", armor = "ligera" }, { kind = "weaponProf", weapon = "marciales" } })
chk("la armadura que da", F.HasArmorProf("ligera"), true)
chk("y no otra", F.HasArmorProf("pesada"), false)
chk("el arma que da", F.HasWeaponProf("marciales"), true)
chk("y no otra", F.HasWeaponProf("sencillas"), false)
-- La consulta se normaliza igual que el guardado: preguntar por "de fuego" encuentra
-- "armas de fuego". Sin eso, el Forajido no seria competente con su propia pistola.
conRasgos({ { kind = "weaponProf", weapon = "armas de fuego" } })
chk("y la pregunta se normaliza como el guardado", F.HasWeaponProf("de fuego"), true)

-- ─── Maximo de recurso: sumar o quedarse con el mayor ───────────────────────
-- Una tabla de valores POR NIVEL es un total, no un incremento: sumarla daria la suma de todos los
-- niveles por los que ha pasado el personaje.
print("Maximo de recurso: `stack = max` no acumula")
conRasgos({ { kind = "resourceMax", resource = "chi", value = 3, stack = "max" },
            { kind = "resourceMax", resource = "chi", value = 5, stack = "max" } })
chk("se queda el mayor", F.GetResourceMaxBonus("chi"), 5)
conRasgos({ { kind = "resourceMax", resource = "chi", value = 5, stack = "max" },
            { kind = "resourceMax", resource = "chi", value = 3, stack = "max" } })
chk("y da igual el orden", F.GetResourceMaxBonus("chi"), 5)

-- ─── Ganancias y descansos ──────────────────────────────────────────────────
print("Ganancias de recurso por disparador")
conRasgos({ { kind = "resourceGain", resource = "rage", trigger = "onKill", amount = 1,
              featureId = "cdm_cosecha" } })
local g = F.GetResourceGains("onKill")
chk("hay una", #g, 1)
chk("del recurso que dice", g[1] and g[1].resource, "rage")
chk("y lleva el id del rasgo, para poder enlazarlo", g[1] and g[1].featureId, "cdm_cosecha")
chk("otro disparador no la ve", #F.GetResourceGains("onHit"), 0)

print("Recuperaciones al descansar: corto y largo son listas distintas")
conRasgos({ { kind = "restRestore", resource = "chi", value = 2, rest = "short" } })
chk("el corto la tiene", F.GetRestRestores("short")["chi"], 2)
chk("el largo no", F.GetRestRestores("long")["chi"], "nil")
conRasgos({ { kind = "restRestore", resource = "chi", value = 2, rest = "long" } })
chk("y al reves", F.GetRestRestores("long")["chi"], 2)
-- Sin `rest` declarado se asume el corto, que es el caso comun.
conRasgos({ { kind = "restRestore", resource = "chi", value = 2 } })
chk("sin decirlo, corto", F.GetRestRestores("short")["chi"], 2)
-- Un valor de cero no se registra: seria una recuperacion que no recupera.
conRasgos({ { kind = "restRestore", resource = "chi", value = 0 } })
chk("un cero no se registra", F.GetRestRestores("short")["chi"], "nil")

-- ─── Valores que escalan con el nivel ───────────────────────────────────────
-- `value = "level"` significa "tu nivel", y con `flatClassId` el de ESA clase, no el total. Un
-- multiclase Monje 3 / Picaro 2 tiene nivel total 5 pero nivel de Monje 3.
print("Un valor que escala con el nivel usa el nivel de SU clase")
conClases({ { classId = "monje", level = 3 }, { classId = "picaro", level = 2 } },
    { monje = {}, picaro = {} })
env.HarfordDnDProgression.GetTotalLevel = function() return 5 end
-- Vive en el `flatBonus` de un dano condicional, que es donde hace falta: "+tu nivel de paladin".
local function planoDe(efecto)
    conRasgos({ efecto })
    local lista = F.GetConditionalDamage()
    return lista[1] and lista[1].flat
end
chk("sin clase, el nivel total",
    planoDe({ kind = "conditionalWeaponDamage", id = "x", flatBonus = "level" }), 5)
chk("con clase, el de esa clase",
    planoDe({ kind = "conditionalWeaponDamage", id = "x", flatBonus = "level",
              flatClassId = "monje" }), 3)
-- Una clase que no se tiene da nivel 0, y un dano condicional que no anade NADA (ni dados, ni
-- bonus, ni coste) directamente no se lista: no tendria nada que ofrecer en el menu.
conRasgos({ { kind = "conditionalWeaponDamage", id = "x", flatBonus = "level",
              flatClassId = "brujo" } })
chk("una clase que no se tiene no deja nada que ofrecer", #F.GetConditionalDamage(), 0)
-- "pb" resuelve al bonus de competencia, no a un texto.
env.HarfordDnDFeatureEffects.GetProficiencyBonus = function() return 4 end
chk("y `pb` es el bonus de competencia",
    planoDe({ kind = "conditionalWeaponDamage", id = "x", flatBonus = "pb" }), 4)
env.HarfordDnDFeatureEffects.GetProficiencyBonus = nil
conClases({}, {})

-- ─── UN RASGO AGOTADO NO PUEDE TENER EFECTO ─────────────────────────────────
-- La Reserva de ira te daba sus puntos y DESPUES avisaba de que no te quedaban usos: el guardia
-- estaba dentro de `AnnounceAbility`, que se llama al final, y la concesion iba antes. Un rasgo
-- agotado no puede conceder nada, asi que la comprobacion tiene que ir ANTES del efecto.
print("Un rasgo sin usos no concede nada")
local panel = io.open("Harford/Character/HarfordCharacterPanel.lua"):read("*a")
local i = panel:find("ApplyPowerWordGrant = function(feature, option, display)", 1, true)
chk("existe la concesion", i ~= nil, true)
local cuerpo = panel:sub(i or 1, (i or 1) + 4000)
local guardia = cuerpo:find("FeatureUseAvailable(conUsos)", 1, true)
local efecto = cuerpo:find("AdjustResourceCurrent(grant.resource", 1, true)
chk("comprueba los usos", guardia ~= nil, true)
chk("y lo hace ANTES de conceder", (guardia or 0) < (efecto or 0), true)

-- Y no solo la concesion: el guardia va en el REPARTIDOR, antes de bajar a las veinticinco ramas.
-- Cada una lo miraba por su cuenta o no lo miraba, y un guardia por rama es un guardia que alguien
-- olvidara en la siguiente.
local j = panel:find("local function BookButtonOnClick(self)", 1, true)
chk("el click del Libro existe", j ~= nil, true)
local reparto = panel:sub(j or 1, (j or 1) + 3000)
local arriba = reparto:find("WarnFeatureWithoutUses(conUsos)", 1, true)
local primeraRama = reparto:find('if cat == "forma" then', 1, true)
chk("comprueba los usos antes de repartir", arriba ~= nil, true)
chk("y antes de la primera rama", (arriba or 0) < (primeraRama or 0), true)
-- Con dos excepciones, y las dos a proposito: un pasivo es un tooltip y no gasta nada, y una
-- trampa ya colocada tiene que poder dispararse con el contador a 0.
chk("salvo pasivos y trampas",
    reparto:find('if cat ~= "pasivo" and not self.feature.trap then', 1, true) ~= nil, true)

-- ─── LA ECONOMIA DE TURNO SE GASTA DE VERDAD ────────────────────────────────
-- Solo cobraba a los rasgos del Libro que declaran `cast`. Atacar con el arma y lanzar un conjuro
-- --que es lo que la gente hace en su turno-- no cobraban nada, asi que las fichas no bajaban
-- nunca y el contador era de adorno.
print("Atacar y lanzar cuestan la accion")
local ficha = io.open("Harford/DnD/UI/HarfordDnD.lua"):read("*a")
local cond = io.open("Harford/DnD/Engine/HarfordDnDConditions.lua"):read("*a")
chk("atacar cuesta lo que diga el motor",
    ficha:find("HarfordDnDConditions.Turn.SpendWeaponAttack(offhand and true or false)",
        1, true) ~= nil, true)
-- Ataque Extra es un RASGO que hay que tener, no algo que se da por hecho: a nivel 4 atacas una
-- vez y el segundo ataque seria una segunda accion de Atacar.
chk("cuantos caben sale del rasgo",
    cond:find('HarfordDnDFeatureEffects.HasFlag("extraAttack")', 1, true) ~= nil, true)
chk("uno, o dos con el rasgo", cond:find("return extra and 2 or 1", 1, true) ~= nil, true)
-- Los de en medio ya estan pagados; el que abre otra tanda cobra otra accion.
chk("solo cobra el que abre la tanda",
    cond:find("if (ECONOMIA.ataques - 1) % porAccion ~= 0 then return nil end", 1, true) ~= nil, true)
-- El ataque con la SECUNDARIA es Combate con Dos Armas: cuesta accion ADICIONAL, no la accion, y
-- no cuenta contra los ataques de la accion.
chk("la secundaria cuesta accion adicional",
    cond:find('local cabia = Turn.Spend("bonus", 1)', 1, true) ~= nil, true)
-- Y los ataques ya hechos son de ESTE turno: sin reiniciarlos, el primero del siguiente se
-- tomaria por el segundo y saldria gratis.
chk("y se reinician con el turno", cond:find("ECONOMIA.ataques = 0", 1, true) ~= nil, true)
-- Tener una accion adicional POR RASGO no es lo mismo que Ataque Extra: el Guerrero de nivel 6
-- tiene las dos y son cosas separadas.
chk("la accion adicional por rasgo es otra cosa",
    cond:find("function Turn.GrantForFeature", 1, true) ~= nil, true)
-- Y una maniobra ya cobro al anunciarse: su ataque no vuelve a cobrar.
chk("y una maniobra no cobra dos veces",
    ficha:find("DoWeaponAttack({ skipTurnCost = true })", 1, true) ~= nil, true)
local comp = io.open("Harford/Compendium/HarfordCompendioCore.lua"):read("*a")
chk("lanzar tambien cuesta",
    comp:find("HarfordDnDConditions.Turn.SpendForFeature({ cast = coste", 1, true) ~= nil, true)
-- Lo que diga su tiempo de lanzamiento, no siempre accion.
chk("segun su tiempo de lanzamiento",
    comp:find('if texto:find("adicional") or texto:find("bonus") then coste = "accion_adicional"',
        1, true) ~= nil, true)
-- Un conjuro de minutos u horas no se juega por turnos: no cobra nada.
chk("y los de minutos no cobran",
    comp:find('elseif texto:find("minuto") or texto:find("hora") then coste = nil end',
        1, true) ~= nil, true)

print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
