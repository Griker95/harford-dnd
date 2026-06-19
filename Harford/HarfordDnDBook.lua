-- HarfordDnDBook: libro hardcodeado de clases/subclases/rasgos.
-- Solo datos + helpers puros. Los efectos son declarativos, nunca codigo Lua.
--
-- Sistema: World of Warcraft D&D 5ª Edicion (homebrew). Las clases, subclases
-- (especializaciones) y rasgos salen del manual en español. Contenido en curso:
-- rasgos hasta NIVEL 6. Lo no automatizable va como `informativo` con su texto.

HarfordDnDBook = HarfordDnDBook or {}

local API = HarfordDnDBook

-- Rasgo ASI estandar (niveles 4/8/12/16/19; hasta nivel 6 solo aplica el de 4).
local function ASI(classId, level)
    return {
        id = classId .. "_asi_" .. tostring(level), level = level,
        name = "Mejora de Caracteristica", type = "choice",
        description = "Aumenta una caracteristica en 2 o dos caracteristicas en 1 (maximo 20).",
        effects = {},
        choice = { slots = 2, optionsFrom = "ability+1" },
    }
end

local function WeaponProfEffects(...)
    local out = {}
    for i = 1, select("#", ...) do
        out[#out + 1] = { kind = "weaponProf", weapon = select(i, ...) }
    end
    return out
end

-- Motivo por el que un rasgo NO esta mecanizado, o nil si SI lo esta. Sirve para clases,
-- razas, dotes y trasfondos (mismo formato de feature). Se considera mecanizado si tiene
-- efectos, un contador de usos (`uses`) o una eleccion (`choice`). Para el resto (solo
-- `type=="informativo"`) deduce el motivo de la descripcion (heuristica; solo informativo
-- para la UI, no afecta a calculos). Asi "se indica" en los datos que sigue sin mecanizar.
function API.GetUnmechanizedReason(feature)
    if type(feature) ~= "table" then return nil end
    local hasEffects = type(feature.effects) == "table" and #feature.effects > 0
    if hasEffects or type(feature.uses) == "table" or type(feature.choice) == "table" then
        return nil  -- mecanizado: efecto, contador de usos o eleccion
    end
    if feature.type ~= "informativo" then return nil end
    local d = tostring(feature.description or ""):lower()
    d = d:gsub("[áàä]", "a"):gsub("[éèë]", "e"):gsub("[íìï]", "i"):gsub("[óòö]", "o"):gsub("[úùü]", "u"):gsub("ñ", "n")
    local function has(...)
        for i = 1, select("#", ...) do if d:find((select(i, ...)), 1, true) then return true end end
        return false
    end
    if has("vision en la oscuridad", "vision en oscuridad", "penumbra a ", "luz tenue a ", "oscuridad como", "ves en luz tenue") then
        return "Vision en la oscuridad: el addon no modela sentidos."
    elseif has("hablas, lees y escribes", "idioma adicional", "idioma extra") then
        return "Idiomas: no se modelan mecanicamente."
    elseif has("arma natural", "golpe desarmado que inflige") then
        return "Arma natural: requiere una capa de arma natural (no existe)."
    elseif has("pg maximos", "puntos de golpe maximos", "puntos de vida maximos") then
        return "Bono de PG por nivel total: resourceMax solo escala por clase."
    elseif has("conjuro", "truco", "ranura", "hechizo", "lanzas ", "lanzar el conjuro", "augurio", "heroismo") then
        return "Depende del sistema de conjuros (no modelado)."
    elseif has("reaccion") then
        return "Reaccion sobre daño entrante: limitacion del modelo de red."
    elseif has("ventaja en", "con ventaja", "desventaja en") then
        return "Ventaja/desventaja situacional: no hay efecto de ventaja pasiva."
    elseif has("doble de tu bono de competencia", "doble bono de competencia", "competente y sumas el doble", "la mitad de tu bono de competencia") then
        return "Pericia situacional (solo en cierto tipo de pruebas)."
    elseif has("terreno dificil", "velocidad", "salto", "categoria de tamano", "tamano mayor", "altitudes", "altura", "volar", "vuelo") then
        return "Movimiento/tamaño/terreno: no modelado."
    elseif has("herramientas") then
        return "Competencia de herramienta (situacional/no aplicada)."
    elseif has("1 vez por turno", "una vez por turno", "1 vez al turno") then
        return "Limite por turno: el tracker de usos es por descanso, no por turno."
    end
    return "Rasgo narrativo o situacional sin mecanica aplicable."
end

API.CLASSES = {
    {
        id = "caballero_muerte", name = "Caballero de la Muerte", desc = "Antiguo campeon caido y resucitado que empuna poder runico y magia profana, de escarcha y de sangre para dominar el campo de batalla.", hitDie = 10, casterType = "half",
        saves = { "Constitucion", "Carisma" },
        armorProfs = { "ligera", "media", "pesada" },
        weaponProfs = { "sencillas", "marciales" },
        subclasses = {
            { id = "sangre", name = "Sangre", desc = "Tanque no-muerto que se sostiene drenando la vida de sus enemigos.", features = {
                { id = "cdm_comando_oscuro", level = 3, name = "Comando Oscuro", type = "informativo", description = "Al dañar con Poder Runico, la criatura tiene desventaja en ataques contra otros que no seas tu hasta el final de tu proximo turno.", effects = {} },
                { id = "cdm_escudo_sangre", level = 3, name = "Escudo de Sangre", type = "informativo", description = "Al lanzar un conjuro de 1er nivel o superior creas un escudo de sangre (PG = 2x nivel CdM + Mod. Carisma) que absorbe daño. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "escarcha", name = "Escarcha", desc = "Doble empunadura y magia de hielo para ralentizar y despedazar.", features = {
                { id = "cdm_golpe_escarcha", level = 3, name = "Golpe de Escarcha", type = "pasivo", description = "Los dados de Poder Runico gastados en un golpe runico pasan a d8 e infligen daño por frio en vez de necrotico.", effects = {
                    { kind = "flag", flag = "frostRunicStrike" },
                } },
                { id = "cdm_maquina_matar", level = 3, name = "Maquina de Matar", type = "pasivo", description = "Critico con armas cuerpo a cuerpo con 19-20. Puedes combatir con dos armas aunque no sean ligeras (si no son pesadas ni a dos manos).", effects = {
                    { kind = "critRange", value = 19, melee = true },
                } },
            } },
            { id = "profana", name = "Profano", desc = "Enfermedades y magia profana que corroen y debilitan al enemigo.", features = {
                { id = "cdm_portador_plagas", level = 3, name = "Portador de Plagas", type = "informativo", description = "Eliges Brotes (infligir enfermedades profanas con Poder Runico) o Levantar a los Muertos (esbirro no-muerto). Detalle en el manual.", effects = {} },
            } },
        },
        features = {
            { id = "cdm_renacer_oscuro", level = 1, name = "Renacer Oscuro", type = "informativo", description = "Eres humanoide y no-muerto a la vez. No duermes (4h de trance = 8h de sueño). Ventaja en salvaciones contra efectos exclusivos de no-muertos.", effects = {} },
            { id = "cdm_armas_runicas", level = 1, name = "Armas Runicas", type = "informativo", description = "Vinculas armas runicas (un arma a dos manos o dos de una mano). No te pueden desarmar salvo incapacitado; las invocas como accion adicional.", effects = {} },
            { id = "cdm_poder_runico", level = 1, name = "Poder Runico", type = "pasivo", description = "Reserva de dados d6 (1 + nivel CdM) que recarga en descanso largo; no gastas mas dados que tu Mod. Carisma. Alimenta Espiral de la Muerte y Golpe Runico.", effects = {
                { kind = "resourceMax", resource = "runic_power", base = 1, perClassLevel = "caballero_muerte", perLevel = 1 },
            } },
            { id = "cdm_golpe_runico", level = 1, name = "Golpe Runico", type = "recurso", description = "Al impactar con un ataque con arma, gastas dados de Poder Runico para infligir dano necrotico adicional. No puedes gastar mas dados que tu Mod. Carisma.", effects = {
                { kind = "conditionalWeaponDamage", id = "runic_strike", label = "Golpe Runico", count = 1, die = 6, damageType = "necrotico", resourceCost = "runic_power", costPerLevel = 1, minLevel = 1, maxLevelAbility = "Carisma", countPerLevel = 1 },
            } },
            { id = "cdm_espiral_muerte", level = 1, name = "Espiral de la Muerte", type = "maniobra", description = "Accion: gastas dados de Poder Runico para lanzar energia necrotica contra una criatura. La criatura realiza una salvacion de Constitucion contra tu CD de conjuro; si falla, sufre dano necrotico por los dados gastados.", effects = {
                { kind = "energyManeuver", resource = "runic_power", cost = 1, save = "Constitucion", outcome = "sufre energia necrotica", dcAbility = "Carisma", levelCost = true, minLevel = 1, maxLevelAbility = "Carisma", damageDie = 6, damageType = "necrotico" },
            } },
            { id = "cdm_estilo_combate", level = 2, name = "Estilo de Combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "defensa",         label = "Defensa (+1 CA con armadura)",       effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                    { id = "duelos",          label = "Duelos (+2 daño un arma a una mano)", effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                    { id = "gran_arma",       label = "Gran Lucha con Armas (repetir 1-2 a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                    { id = "guerrero_profano", label = "Guerrero Profano (2 trucos de brujo, Carisma)", effects = {} },
                    { id = "dos_armas",       label = "Combate con Dos Armas (+mod al 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                },
            } },
            { id = "cdm_lanzamiento_conjuros", level = 2, name = "Lanzamiento de Conjuros", type = "informativo", description = "Lanzas conjuros de caballero de la muerte usando Carisma. CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma. Foco: tu arma runica.", effects = {} },
            { id = "cdm_constitucion_nomuerta", level = 3, name = "Constitucion No-Muerta", type = "pasivo", description = "Inmune a enfermedades y a la condicion envenenado; resistente al daño por veneno.", effects = {
                { kind = "resist", damage = "veneno" },
            } },
            { id = "cdm_presencia_maligna", level = 3, name = "Presencia Maligna", type = "informativo", description = "Eliges tu presencia (Sangre, Escarcha o Profana). Concede rasgos en niveles 3, 7, 11, 15 y 20.", effects = {} },
            ASI("cdm", 4),
            { id = "cdm_ataque_extra", level = 5, name = "Ataque Extra", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la accion de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "cdm_forja_runas", level = 6, name = "Forja de Runas", type = "informativo", description = "Tras un descanso largo inscribes una runa en tus armas runicas (una activa a la vez) mientras las empuñas.", effects = {} },
        },
    },
    {
        id = "cazador_demonios", name = "Cazador de Demonios", desc = "Illidari que sacrifico su humanidad absorbiendo esencia demoniaca; agil cazador de gran movilidad y metamorfosis demoniaca.", hitDie = 8,
        saves = { "Destreza", "Carisma" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas", "marciales", "gujas" },
        subclasses = {
            { id = "devastacion", name = "Devastacion", desc = "Agresion implacable de gran movilidad y dano demoniaco.", features = {
                { id = "dh_dev_competencia", level = 3, name = "Competencia Adicional (Acrobacias)", type = "pasivo", description = "Pericia en Acrobacias (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Acrobacias" },
                } },
                { id = "dh_dev_embestida", level = 3, name = "Embestida Vil", type = "informativo", description = "Al gastar un punto de vil en Momentum, obtienes Esquivar y Desenganchar hasta el final de tu turno.", effects = {} },
                { id = "dh_dev_momentum_vengativo", level = 6, name = "Momentum Vengativo", type = "informativo", description = "Al usar Momentum, ventaja en el siguiente ataque con arma antes del final de tu proximo turno.", effects = {} },
            } },
            { id = "venganza", name = "Venganza", desc = "Defensa demoniaca que absorbe el castigo y lo devuelve.", features = {
                { id = "dh_ven_competencia", level = 3, name = "Competencia Adicional (Intimidacion)", type = "pasivo", description = "Pericia en Intimidacion (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Intimidacion" },
                } },
                { id = "dh_ven_tormento", level = 3, name = "Tormento", type = "informativo", description = "Accion: una criatura a 30 pies con salvacion de Sabiduria o desventaja en ataques contra otros que no seas tu durante 1 minuto.", effects = {} },
                { id = "dh_ven_puas", level = 6, name = "Puas Demoniacas", type = "pasivo", description = "En metamorfosis: resistencia a contundente/perforante/cortante y ventaja en pruebas y salvaciones de Fuerza y Destreza.", effects = {
                    { kind = "resist", damage = "contundente", requiresState = "metamorphosis" },
                    { kind = "resist", damage = "perforante", requiresState = "metamorphosis" },
                    { kind = "resist", damage = "cortante", requiresState = "metamorphosis" },
                } },
            } },
            { id = "ira", name = "Ira", desc = "Furia desatada que crece con el frenesi del combate.", features = {
                { id = "dh_ira_competencia", level = 3, name = "Competencia Adicional (Arcano)", type = "pasivo", description = "Pericia en Conocimiento Arcano (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Arcano" },
                } },
                { id = "dh_ira_llamas", level = 3, name = "Llamas del Caos", type = "informativo", description = "Ataque a distancia (30 pies) con tu Mod. Destreza; 1d6 de fuego al impactar (1d10 a nivel 11).", effects = {} },
                { id = "dh_ira_marca_ignea", level = 6, name = "Marca Ignea", type = "informativo", description = "En metamorfosis, las Llamas del Caos de tu Mordida de Demonio imponen salvacion de Constitucion (desventaja en ataques) e ignoran resistencia al fuego.", effects = {} },
            } },
        },
        features = {
            { id = "dh_defensa_sin_armadura", level = 1, name = "Defensa sin Armadura", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Inteligencia.", effects = {
                { kind = "unarmoredDefenseAbility", ability = "Inteligencia" },
            } },
            { id = "dh_iniciacion_illidari", level = 1, name = "Iniciacion Illidari", type = "informativo", description = "Ventaja en el primer turno contra criaturas que no han actuado; tratas armas no pesadas/dos manos como ligeras y precisas; competencia en Supervivencia al rastrear; hablas Eredun; ventaja contra demonios.", effects = {} },
            { id = "dh_vision_espectral", level = 1, name = "Vision Espectral", type = "informativo", description = "Vision en oscuridad normal y magica a 60 pies (con color); inmune a cegado. A nivel 7 puedes usar detectar magia.", effects = {} },
            { id = "dh_vil", level = 2, name = "Vil", type = "pasivo", description = "Puntos de vil (= nivel) para alimentar caracteristicas (Mordida de Demonio, Potenciar Protecciones, Momentum). CD de Vil = 8 + comp + Mod. Inteligencia. Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "fel_point", perClassLevel = "cazador_demonios", perLevel = 1 },
            } },
            { id = "dh_metamorfosis", level = 2, name = "Metamorfosis", type = "recurso", description = "Accion adicional: te transformas 1 minuto (PG temporales = nivel + Mod. Int, daño extra de fuego, +10 pies velocidad, ataques magicos). Usos segun la tabla; recargan en descanso largo.", effects = {
                { kind = "resourceMax", resource = "metamorphosis", perClassLevel = "cazador_demonios", values = { 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5 } },
                { kind = "toggleState", state = "metamorphosis", label = "Metamorfosis", description = "Activa rasgos que solo funcionan mientras estas en metamorfosis." },
            } },
            { id = "dh_marca_demoniaca", level = 3, name = "Marca Demoniaca", type = "informativo", description = "Eliges tu marca (Devastacion, Venganza o Ira). Concede rasgos en niveles 3, 6, 10 y 17.", effects = {} },
            ASI("dh", 4),
            { id = "dh_ataque_adicional", level = 5, name = "Ataque Adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la accion de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "dh_hambre_instintiva", level = 5, name = "Hambre Instintiva", type = "informativo", description = "Reaccion al terminar una criatura su turno a 15 pies: te mueves media velocidad hacia ella sin provocar ataques de oportunidad y obtienes ventaja en tu primer ataque contra ella.", effects = {} },
        },
    },
    {
        id = "druida", name = "Druida", desc = "Guardian de la naturaleza capaz de adoptar formas animales y lanzar magia primigenia de equilibrio, fiereza o restauracion.", hitDie = 8, casterType = "full",
        saves = { "Inteligencia", "Sabiduria" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "equilibrio", name = "Equilibrio", desc = "Magia lunar y solar que castiga al enemigo a distancia.", features = {
                { id = "dru_eq_conjuros_camino", level = 2, name = "Conjuros del Camino", type = "informativo", description = "Obtienes conjuros del camino (Elune) a niveles 3/5/7/9; siempre preparados y no cuentan en tu limite.", effects = {} },
                { id = "dru_eq_invocar", level = 2, name = "Invocar", type = "informativo", description = "En un descanso corto recuperas espacios de conjuro (nivel combinado <= mitad de tu nivel de druida, ninguno de 6+). 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "dru_eq_fuerza_naturaleza", level = 6, name = "Fuerza de la Naturaleza", type = "informativo", description = "Al lanzar un conjuro de un solo objetivo, infliges daño extra o curas igual a tu nivel de druida. 2 usos por descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
            } },
            { id = "feral", name = "Feral", desc = "Forma de fiera con garras y sigilo depredador.", features = {
                { id = "dru_fer_adaptacion", level = 2, name = "Adaptacion Salvaje", type = "choice", description = "Ganas competencia en salvaciones de Destreza o Constitucion (ademas de las del druida). Cuentas como medio lanzador (tabla Feral).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "destreza",     label = "Salvacion de Destreza",     effects = { { kind = "saveProf", ability = "Destreza" } } },
                        { id = "constitucion", label = "Salvacion de Constitucion", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                    },
                } },
                { id = "dru_fer_marca_ursol", level = 2, name = "Marca de Ursol", type = "informativo", description = "Puedes lanzar conjuros mientras estas transformado (ignoras componentes V/S y materiales sin coste). 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
                { id = "dru_fer_afinidad", level = 2, name = "Afinidad Feral o Guardiana", type = "choice", description = "Elige Ravager (daño extra gastando espacio de conjuro) o Frenesi (resistencia fisica transformado).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "ravager", label = "Ravager (daño extra con espacio de conjuro)", effects = {} },
                        { id = "frenesi", label = "Frenesi (resistencia fisica transformado)",   effects = {
                            { kind = "resist", damage = "contundente", requiresState = "wild_shape" },
                            { kind = "resist", damage = "perforante", requiresState = "wild_shape" },
                            { kind = "resist", damage = "cortante", requiresState = "wild_shape" },
                        } },
                    },
                } },
                { id = "dru_fer_instintos", level = 6, name = "Instintos Primales", type = "pasivo", description = "Sumas tu Mod. Sabiduria a la iniciativa y no puedes ser sorprendido mientras estas despierto.", effects = {
                    { kind = "initiativeAbility", ability = "Sabiduria" },
                } },
                { id = "dru_fer_ataque_adicional", level = 6, name = "Ataque Adicional (transformado)", type = "pasivo", description = "Atacas dos veces al realizar la accion de Atacar mientras estas transformado; esos ataques cuentan como magicos.", effects = {
                    { kind = "flag", flag = "extraAttack", requiresState = "wild_shape" },
                } },
                { id = "dru_fer_tacticas", level = 6, name = "Tacticas Ferales", type = "choice", description = "Transformado, elige Defensor de la Manada (intercambiar lugar para recibir un ataque) o Demoledor Pulverizante (derribar con salvacion de Fuerza).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "defensor",  label = "Defensor de la Manada", effects = {} },
                        { id = "demoledor", label = "Demoledor Pulverizante", effects = {} },
                    },
                } },
            } },
            { id = "restauracion", name = "Restauracion", desc = "Sanacion sostenida con magia de la naturaleza.", features = {
                { id = "dru_res_conjuros_camino", level = 2, name = "Hechizos del Camino", type = "informativo", description = "Obtienes hechizos del camino a niveles 3/5/7/9; siempre preparados y no cuentan en tu limite.", effects = {} },
                { id = "dru_res_rejuvenecimiento", level = 2, name = "Rejuvenecimiento", type = "recurso", description = "Reserva de d6 (= nivel de druida). Accion adicional: cura a un objetivo a 120 pies (gastas hasta mitad de tu nivel en dados) + 1 PG temporal por dado. Recarga en descanso largo.", effects = {
                    { kind = "resourceMax", resource = "living_seeds", perClassLevel = "druida", perLevel = 1 },
                } },
                { id = "dru_res_corteza_hierro", level = 6, name = "Corteza de Hierro", type = "informativo", description = "Reaccion: otorgas resistencia a acido/frio/fuego/relampago/trueno a ti o a un aliado a 30 pies contra esa instancia de daño.", effects = {} },
            } },
        },
        features = {
            { id = "dru_druidico", level = 1, name = "Druidico", type = "informativo", description = "Conoces el druidico, el lenguaje secreto de los druidas (hablar, leer y escribir).", effects = {} },
            { id = "dru_lanzamiento_conjuros", level = 1, name = "Lanzamiento de Conjuros", type = "informativo", description = "Lanzas conjuros de druida usando Sabiduria (preparas Mod. Sabiduria + nivel). CD = 8 + comp + Mod. Sabiduria; ataque = comp + Mod. Sabiduria. Foco druidico.", effects = {} },
            { id = "dru_cambio_forma", level = 2, name = "Cambio de Forma", type = "pasivo", description = "Accion: asumes una forma druidica conocida (gato, oso, lechucico lunar, arbol...). Mas formas a niveles 4 y 8.", effects = {
                { kind = "toggleState", state = "wild_shape", label = "Transformado", description = "Activa rasgos que solo funcionan mientras estas en forma druidica." },
            } },
            { id = "dru_senda", level = 2, name = "Senda del Druida", type = "informativo", description = "Eliges tu senda (Equilibrio, Feral o Restauracion). Concede rasgos en niveles 2, 6, 10, 14 y 20.", effects = {} },
            { id = "dru_afinidades", level = 3, name = "Afinidades Salvajes", type = "informativo", description = "Obtienes 2 afinidades salvajes de tu eleccion (mas a niveles superiores). Opciones detalladas al final de la clase.", effects = {} },
            ASI("druida", 4),
            { id = "dru_mejora_cambio_forma", level = 4, name = "Mejora de Cambio de Forma", type = "informativo", description = "Mejora tus formas druidicas (nuevas formas/beneficios segun la tabla de formas).", effects = {} },
        },
    },
    {
        id = "cazador", name = "Cazador", desc = "Experto rastreador y tirador que combate junto a una bestia companera y domina las armas a distancia.", hitDie = 10,
        saves = { "Fuerza", "Destreza" },
        armorProfs = { "ligera", "media" },
        weaponProfs = { "sencillas", "marciales", "armas de fuego" },
        subclasses = {
            { id = "bestias", name = "Bestias", desc = "Vinculo profundo con una poderosa bestia companera.", features = {
                { id = "caz_bes_domador", level = 3, name = "Domador de Bestias", type = "informativo", description = "Puedes domar bestias Grandes o menores con valor de desafio 1 o menor.", effects = {} },
                { id = "caz_bes_aspecto", level = 3, name = "Aspecto de la Bestia", type = "informativo", description = "Lanzas sentido de la bestia como ritual, solo en tu mascota.", effects = {} },
                { id = "caz_bes_comando", level = 5, name = "Comando de Matar", type = "informativo", description = "Accion adicional + dado de enfoque: tu mascota Ataca con ventaja; añades el dado al daño del primer impacto.", effects = {} },
            } },
            { id = "punteria", name = "Punteria", desc = "Tiros precisos y devastadores a larga distancia.", features = {
                { id = "caz_pun_disparo_arcano", level = 3, name = "Disparo Arcano", type = "informativo", description = "Tus ataques a distancia contra tu marcado ignoran cobertura e infligen +(2 + mitad de nivel) de fuerza. Usos = Mod. Sabiduria.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
                { id = "caz_pun_lobo_apuntado", level = 3, name = "Lobo Solitario: Ataque Apuntado", type = "pasivo", description = "Sin compañero bestial, accion adicional para dar ventaja a tu proximo ataque con arma.", effects = {
                    { kind = "toggleState", state = "lone_wolf", label = "Lobo Solitario", description = "Activa rasgos que requieren combatir sin companero bestial." },
                } },
                { id = "caz_pun_disparo_conmocionante", level = 5, name = "Disparo Conmocionante", type = "informativo", description = "Gasta un dado de enfoque para sumarlo a la CD de concentracion que provoque tu ataque.", effects = {} },
                { id = "caz_pun_lobo_ataque", level = 5, name = "Lobo Solitario: Ataque Adicional", type = "pasivo", description = "Sin compañero bestial, atacas dos veces al realizar la accion de Atacar.", effects = {
                    { kind = "flag", flag = "extraAttack", requiresState = "lone_wolf" },
                } },
            } },
            { id = "supervivencia", name = "Supervivencia", desc = "Trampas, cuerpo a cuerpo y dominio del terreno.", features = {
                { id = "caz_sup_trampero", level = 3, name = "Trampero Experto", type = "informativo", description = "Aprendes y colocas trampas (2 conocidas; mas a niveles superiores). CD de Trampa = 8 + comp + Mod. Sabiduria.", effects = {} },
                { id = "caz_sup_estudiante", level = 3, name = "Estudiante de lo Salvaje", type = "pasivo", description = "Pericia en Supervivencia (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Supervivencia" },
                } },
                { id = "caz_sup_lobo_salvaje", level = 3, name = "Lobo Solitario: Nacido para ser Salvaje", type = "pasivo", description = "Sin compañero bestial, tus ataques con arma son criticos con 19-20 y Desengancharte es accion adicional.", effects = {
                    { kind = "toggleState", state = "lone_wolf", label = "Lobo Solitario", description = "Activa rasgos que requieren combatir sin companero bestial." },
                    { kind = "critRange", value = 19, requiresState = "lone_wolf" },
                } },
                { id = "caz_sup_corte_ala", level = 5, name = "Corte de Ala", type = "informativo", description = "Al golpear, gasta un dado de enfoque: el objetivo con Fuerza (Atletismo) o su velocidad baja a 0 hasta tu proximo turno.", effects = {} },
                { id = "caz_sup_lobo_ataque", level = 5, name = "Lobo Solitario: Ataque Adicional", type = "pasivo", description = "Sin compañero bestial, atacas dos veces al realizar la accion de Atacar.", effects = {
                    { kind = "flag", flag = "extraAttack", requiresState = "lone_wolf" },
                } },
            } },
        },
        features = {
            { id = "caz_marca_cazador", level = 1, name = "Marca del Cazador", type = "pasivo", description = "Accion adicional: marcas una criatura a 120 pies. Una vez por turno, +1d4 de daño al golpearla con arma (sube a 1d6/1d8/1d10 con el nivel). Ventaja en Percepcion/Supervivencia para encontrarla. Activa el daño extra desde el boton de daño condicional al impactar a tu presa.", effects = {
                { kind = "conditionalWeaponDamage", id = "hunters_mark", label = "Marca del Cazador", count = 1, die = 4, scaleClassId = "cazador", dieScale = { { 6, 6 }, { 11, 8 }, { 16, 10 } } },
            } },
            { id = "caz_explorador_natural", level = 1, name = "Explorador Natural", type = "pasivo", description = "Sumas tu Mod. Sabiduria a la iniciativa; ventaja en el primer turno contra criaturas que no han actuado; ventajas viajando por la naturaleza.", effects = {
                { kind = "initiativeAbility", ability = "Sabiduria" },
            } },
            { id = "caz_estilo_combate", level = 2, name = "Estilo de Combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "tiro_arco",   label = "Tiro con Arco (+2 ataque a distancia)", effects = { { kind = "bonus", target = "weaponAttack", value = 2 } } },
                    { id = "tirador",     label = "Tirador en Combate Cercano (+1 ataque a distancia, ignora cobertura)", effects = { { kind = "bonus", target = "weaponAttack", value = 1 } } },
                    { id = "dos_armas",   label = "Combate con Dos Armas (+mod al 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                    { id = "gran_arma",   label = "Combate con Arma Grande (repetir 1-2 a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                },
            } },
            { id = "caz_enfoque", level = 2, name = "Enfoque", type = "pasivo", description = "Dados de enfoque (d8, segun la tabla) para Llamada de lo Salvaje, Ataque Preciso y Tacticas de Supervivencia. Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "focus", perClassLevel = "cazador", values = { 0, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10 } },
            } },
            { id = "caz_empatia_animal", level = 2, name = "Empatia Animal", type = "informativo", description = "Te comunicas con bestias y lees su estado de animo e intencion basica.", effects = {} },
            { id = "caz_arquetipo", level = 3, name = "Arquetipo de Cazador", type = "informativo", description = "Eliges tu arquetipo (Maestro de Bestias, Punteria o Supervivencia). Concede rasgos en niveles 3, 5, 7, 11 y 15.", effects = {} },
            { id = "caz_domar_bestia", level = 3, name = "Domar Bestia", type = "informativo", description = "Vinculas una bestia (Mediana o menor, desafio 1/2 o menor) como compañero (Vinculo del Compañero).", effects = {} },
            ASI("cazador", 4),
        },
    },
    {
        id = "mago", name = "Mago", desc = "Estudioso de las artes arcanas que moldea fuego, escarcha y energia pura mediante conjuros aprendidos.", hitDie = 6, casterType = "full",
        saves = { "Inteligencia", "Sabiduria" },
        armorProfs = {},
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "arcano", name = "Arcano", desc = "Manipulacion de energia arcana pura y gran eficiencia magica.", features = {
                { id = "mago_arc_truco", level = 2, name = "Truco Adicional (prestidigitacion)", type = "informativo", description = "Aprendes prestidigitacion (u otro truco de mago); no cuenta en tu limite.", effects = {} },
                { id = "mago_arc_cargas", level = 2, name = "Cargas Arcanas", type = "informativo", description = "Al lanzar un conjuro de 1er nivel o superior ganas una carga arcana (= nivel, max 5) que gastas para sumar bonus a ataque/daño o salvaciones.", effects = {} },
                { id = "mago_arc_desplazamiento", level = 2, name = "Desplazamiento Temporal", type = "informativo", description = "Tras tirar iniciativa, intercambias tu resultado con el de otra criatura visible. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "mago_arc_brillantez", level = 6, name = "Brillantez Arcana", type = "pasivo", description = "Pericia en Conocimiento Arcano (competencia y bonus duplicado). Siempre bajo entender idiomas.", effects = {
                    { kind = "skillExpertise", skill = "Arcano" },
                } },
            } },
            { id = "fuego", name = "Fuego", desc = "Conjuros incendiarios de alto dano y combustion.", features = {
                { id = "mago_fue_truco", level = 2, name = "Truco Adicional (controlar llamas)", type = "informativo", description = "Aprendes controlar llamas (u otro truco de mago); no cuenta en tu limite.", effects = {} },
                { id = "mago_fue_racha", level = 2, name = "Racha de Calor", type = "informativo", description = "Al sacar el maximo en un dado de daño de conjuro, relanza ese dado y suma el resultado. 1 vez por turno.", effects = {} },
                { id = "mago_fue_cauterizar", level = 6, name = "Cauterizar", type = "informativo", description = "Reaccion al caer a 0 PG: quedas a 1 PG y las criaturas a 10 pies reciben fuego = mitad de nivel + Mod. Inteligencia. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "escarcha", name = "Escarcha", desc = "Control, ralentizacion y dano de hielo.", features = {
                { id = "mago_esc_truco", level = 2, name = "Truco Adicional (moldear agua)", type = "informativo", description = "Aprendes moldear agua (u otro truco de mago); no cuenta en tu limite.", effects = {} },
                { id = "mago_esc_dedos", level = 2, name = "Dedos de Escarcha", type = "choice", description = "Elige Barrera de Hielo (escudo de PG temporal con conjuros de frio) o Elemental de Agua (compañero).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "barrera",   label = "Barrera de Hielo", effects = {} },
                        { id = "elemental", label = "Elemental de Agua", effects = {} },
                    },
                } },
                { id = "mago_esc_congelacion", level = 6, name = "Congelacion Cerebral", type = "informativo", description = "El daño por frio de tus conjuros reduce 10 pies la velocidad; puedes gastar un punto de hechiceria para restringir (salvacion de Fuerza).", effects = {} },
            } },
        },
        features = {
            { id = "mago_lanzamiento_conjuros", level = 1, name = "Lanzamiento de Conjuros", type = "informativo", description = "Libro de conjuros; preparas Mod. Inteligencia + nivel. CD = 8 + comp + Mod. Inteligencia; ataque = comp + Mod. Inteligencia. Foco arcano.", effects = {} },
            { id = "mago_sentido_magico", level = 1, name = "Sentido Magico", type = "informativo", description = "Percibes magia residual reciente y lees escritura magica oculta. Ademas puedes crear escritura magica oculta en idiomas que conozcas.", effects = {} },
            { id = "mago_fuente_magia", level = 2, name = "Fuente de Magia", type = "pasivo", description = "Puntos de hechiceria (= nivel) para Lanzamiento Flexible (convertir puntos en espacios de conjuro y viceversa). Recargan en descanso largo.", effects = {
                { kind = "resourceMax", resource = "mage_point", perClassLevel = "mago", perLevel = 1 },
            } },
            { id = "mago_estudio_magico", level = 2, name = "Estudio Magico", type = "informativo", description = "Eliges tu estudio (Arcano, Fuego o Escarcha). Concede rasgos en niveles 2, 6, 10 y 14.", effects = {} },
            { id = "mago_metamagia", level = 3, name = "Metamagia", type = "informativo", description = "Aprendes opciones de metamagia para alterar tus conjuros gastando puntos de hechiceria (mas a niveles 10 y 17).", effects = {} },
            { id = "mago_formulas_cantrips", level = 3, name = "Formulas de Trucos", type = "informativo", description = "Aprendes a modificar tus trucos con formulas arcanas.", effects = {} },
            ASI("mago", 4),
        },
    },
    {
        id = "monje", name = "Monje", desc = "Artista marcial que canaliza el chi para golpear con rapidez, sanar con nieblas o resistir como un muro.", hitDie = 8,
        saves = { "Fuerza", "Destreza" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas", "espadas cortas" },
        subclasses = {
            { id = "cervecero", name = "Maestro cervecero", desc = "Muro resistente que aguanta y dispersa el dano.", features = {
                { id = "monje_cer_competencia", level = 3, name = "Competencia Adicional (cervecero)", type = "pasivo", description = "Competencia con herramientas de cervecero (bonus de competencia duplicado en sus pruebas).", effects = {
                    { kind = "toolProf", tool = "Herramientas de cervecero" },
                } },
                { id = "monje_cer_brebajes", level = 3, name = "Cervecero Elusivo", type = "informativo", description = "Conoces brebajes (Buey Negro + uno a elegir; mas a niveles superiores) que gastan chi para diversos efectos.", effects = {} },
                { id = "monje_cer_tambaleo", level = 6, name = "Tambaleo", type = "informativo", description = "Reaccion al recibir daño: resistencia a todo el daño del ataque salvo psiquico. 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
            } },
            { id = "tejedor", name = "Tejedor de niebla", desc = "Sanacion y apoyo mediante nieblas restauradoras.", features = {
                { id = "monje_tej_niebla_calmante", level = 3, name = "Niebla Calmante", type = "recurso", description = "Reserva de chi sanador (= nivel x 10 PG). Accion: rayo a 30 pies que cura; o gasta 5 para curar enfermedad/veneno. Recarga en descanso largo.", effects = {
                    { kind = "resourceMax", resource = "healing_mist", perClassLevel = "monje", base = 0, perLevel = 10 },
                } },
                { id = "monje_tej_palma_chiji", level = 3, name = "Palma de Chi-Ji", type = "informativo", description = "Al usar Niebla Calmante, golpe desarmado como accion adicional usando tu Mod. Sabiduria al ataque y daño.", effects = {} },
                { id = "monje_tej_caminante", level = 6, name = "Caminante de la Niebla", type = "informativo", description = "Accion + 1 punto de chi: te teletransportas 60 pies y puedes usar Niebla Calmante desde la nueva posicion.", effects = {} },
            } },
            { id = "caminavientos", name = "Viajero del viento", desc = "Dano agil y veloz con golpes encadenados.", features = {
                { id = "monje_cam_golpes_lanza", level = 3, name = "Golpes de Mano de Lanza", type = "informativo", description = "Al golpear con Puños de Furia, impones un efecto (derribar, empujar 15 pies o impedir reacciones).", effects = {} },
                { id = "monje_cam_reflejos", level = 3, name = "Reflejos del Tigre", type = "pasivo", description = "Sumas tu Mod. Sabiduria a la iniciativa.", effects = {
                    { kind = "initiativeAbility", ability = "Sabiduria" },
                } },
                { id = "monje_cam_caminavientos", level = 6, name = "Caminavientos", type = "informativo", description = "Al usar Paso del Viento ganas velocidad de vuelo (mitad de tu velocidad) hasta el final del turno; reduces daño por caida.", effects = {} },
            } },
        },
        features = {
            { id = "monje_defensa_sin_armadura", level = 1, name = "Defensa sin Armadura", type = "pasivo", description = "Sin armadura ni escudo, tu CA = 10 + Mod. Destreza + Mod. Sabiduria.", effects = {
                { kind = "unarmoredDefenseAbility", ability = "Sabiduria" },
            } },
            { id = "monje_artes_marciales", level = 1, name = "Artes Marciales", type = "informativo", description = "Con golpes desarmados y armas de monje: usas Destreza al ataque/daño, dado de arte marcial (d4+), y golpe desarmado como accion adicional tras Atacar.", effects = {} },
            { id = "monje_chi", level = 2, name = "Chi", type = "pasivo", description = "Puntos de chi (= nivel) para Puños de Furia, Danza Elusiva, Paso del Viento y Efusion. CD de Chi = 8 + comp + Mod. Sabiduria. Recargan en descanso corto o largo.", effects = {
                { kind = "resourceMax", resource = "chi", perClassLevel = "monje", perLevel = 1 },
            } },
            { id = "monje_rodar", level = 2, name = "Rodar", type = "informativo", description = "Sin escudo, una vez por turno ruedas en linea recta gastando movimiento; los ataques de oportunidad contra ti se hacen con desventaja.", effects = {} },
            { id = "monje_tradicion", level = 3, name = "Tradicion Monastica", type = "informativo", description = "Eliges tu tradicion (Maestro Cervecero, Tejedor de Niebla o Caminavientos). Concede rasgos en niveles 3, 6, 11 y 17.", effects = {} },
            { id = "monje_serenidad", level = 3, name = "Serenidad", type = "informativo", description = "Al usar chi entras en postura serena 1 minuto: usas tu Mod. Sabiduria al ataque/daño con armas de monje o golpes desarmados.", effects = {} },
            ASI("monje", 4),
            { id = "monje_ataque_adicional", level = 5, name = "Ataque Adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la accion de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "monje_palma_aturdidora", level = 5, name = "Palma Aturdidora", type = "informativo", description = "Una vez por turno, al golpear cuerpo a cuerpo, gasta 1 punto de chi: el objetivo con salvacion de Constitucion o aturdido hasta tu proximo turno.", effects = {} },
            { id = "monje_golpes_empoderados_chi", level = 6, name = "Golpes Empoderados por el Chi", type = "informativo", description = "Tus golpes desarmados cuentan como magicos para superar resistencias e inmunidades no magicas.", effects = {} },
        },
    },
    {
        id = "paladin", name = "Paladin", desc = "Cruzado sagrado que une fuerza marcial y Luz Sagrada para proteger, castigar y sanar.", hitDie = 10, casterType = "half",
        saves = { "Sabiduria", "Carisma" },
        armorProfs = { "ligera", "media", "pesada", "escudo" },
        weaponProfs = { "sencillas", "marciales" },
        subclasses = {
            { id = "sagrado", name = "Sagrado", desc = "Luz sanadora y apoyo para los aliados.", features = {
                { id = "pal_sag_canalizar", level = 3, name = "Canalizar Divinidad (Sagrado)", type = "informativo", description = "Opciones: Luz del Amanecer (disipa oscuridad y cura) y Martillo de Luz (estallido de luz, salvacion de Constitucion).", effects = {} },
                { id = "pal_sag_destello", level = 3, name = "Destello de Luz", type = "informativo", description = "Accion adicional + ranura de conjuro: curas a un objetivo a 20 pies (2d6 por ranura de 1er nivel, +1d6 por nivel superior, max 6d6).", effects = {} },
            } },
            { id = "proteccion", name = "Proteccion", desc = "Guardian acorazado que protege a los suyos.", features = {
                { id = "pal_pro_canalizar", level = 3, name = "Canalizar Divinidad (Proteccion)", type = "informativo", description = "Opciones: Consagracion (radio 30 pies, daño radiante + PG temporal a aliados) y Escudo Sagrado (desventaja a atacantes; daño al fallar contra ti).", effects = {} },
                { id = "pal_pro_bastion", level = 3, name = "Bastion Divino", type = "recurso", description = "Al golpear cuerpo a cuerpo, gasta ranura de conjuro: +2d6 radiante (1er nivel; +1d6 por nivel superior, max 6d6) y el objetivo tiene desventaja en ataques contra otros. No se combina con Golpe del Cruzado (elige solo uno por ataque). Toggle por nivel en 'Daño extra'.", effects = {
                    { kind = "conditionalWeaponDamage", id = "divine_bastion", label = "Bastion Divino", count = 2, die = 6, damageType = "radiante", spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, extraCountOffset = 1, maxCount = 6 },
                } },
            } },
            { id = "represion", name = "Represion", desc = "Castigo sagrado que aniquila al impio.", features = {
                { id = "pal_ret_canalizar", level = 3, name = "Canalizar Divinidad (Represion)", type = "informativo", description = "Opciones: Veredicto del Templario (ventaja en ataques contra una criatura 1 minuto) y Rechazar lo Profano (apartar demonios/no-muertos).", effects = {} },
                { id = "pal_ret_tormenta", level = 3, name = "Tormenta Divina", type = "informativo", description = "Al golpear, gasta ranura de conjuro: daño radiante a la criatura y a todo a 5 pies (salvacion de Destreza por mitad). No se combina con Golpe del Cruzado.", effects = {} },
            } },
        },
        features = {
            { id = "pal_sentido_divino", level = 1, name = "Sentido Divino", type = "informativo", description = "Accion: detectas celestiales, infernales y no-muertos a 60 pies, y lugares/objetos consagrados o profanados. Usos = 1 + Mod. Carisma.", uses = { base = 1, ability = "Carisma", min = 1, recharge = "long" }, effects = {} },
            { id = "pal_imposicion_manos", level = 1, name = "Imposicion de Manos", type = "recurso", description = "Reserva de curacion (= nivel x5 PG). Accion: tocas y curas; o gastas 5 PG para curar enfermedad/neutralizar veneno. Recarga en descanso largo.", effects = {
                { kind = "resourceMax", resource = "lay_on_hands", perClassLevel = "paladin", base = 0, perLevel = 5 },
            } },
            { id = "pal_estilo_combate", level = 2, name = "Estilo de Combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "guerrero_bendito", label = "Guerrero Bendito (2 trucos de sacerdote, Carisma)", effects = {} },
                    { id = "defensa",          label = "Defensa (+1 CA con armadura)",            effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                    { id = "doble_empuñadura", label = "Doble Empuñadura (+2 daño un arma a una mano)", effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                    { id = "gran_arma",        label = "Gran Arma (repetir 1-2 a dos manos)",     effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                    { id = "proteccion",       label = "Proteccion (desventaja a atacantes, con escudo)", effects = {} },
                },
            } },
            { id = "pal_lanzamiento_conjuros", level = 2, name = "Lanzamiento de Conjuros", type = "informativo", description = "Lanzas conjuros de paladin usando Carisma (preparas Mod. Carisma + mitad de nivel). CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma.", effects = {} },
            { id = "pal_golpe_cruzado", level = 2, name = "Golpe del Cruzado", type = "pasivo", description = "Al golpear cuerpo a cuerpo, gasta ranura de conjuro: +2d8 radiante (1er nivel; +1d8 por nivel superior, max 6d8; +1d8 contra no-muertos/infernales). El toggle suma el daño base de 1er nivel (2d8); los dados extra por ranura superior se añaden manualmente.", effects = {
                { kind = "conditionalWeaponDamage", id = "smite", label = "Golpe del Cruzado", count = 2, die = 8, damageType = "radiante", spellLevelCost = "level", minLevel = 1, maxSpellLevel = true, countPerLevel = 1, extraCountOffset = 1, maxCount = 6 },
            } },
            { id = "pal_camino_sagrado", level = 3, name = "Camino Sagrado", type = "recurso", description = "Eliges tu camino (de lo Sagrado, de la Proteccion o de la Represion). Concede rasgos y Canalizar Divinidad (1 uso, recarga en descanso corto o largo) en niveles 3, 7, 15 y 20.", effects = {
                { kind = "resourceMax", resource = "channel_divinity", value = 1 },
            } },
            ASI("paladin", 4),
            { id = "pal_ataque_extra", level = 5, name = "Ataque Extra", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la accion de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "pal_aura_proteccion", level = 6, name = "Aura de Proteccion", type = "pasivo", description = "Tu y aliados a 10 pies suman tu Mod. Carisma (minimo +1) a sus tiradas de salvacion mientras estes consciente.", effects = {
                { kind = "allSavesAbility", ability = "Carisma", min = 1 },
            } },
        },
    },
    {
        id = "sacerdote", name = "Sacerdote", desc = "Servidor devoto que canaliza la fe para sanar, proteger o castigar con poder sagrado y sombrio.", hitDie = 6, casterType = "full",
        saves = { "Sabiduria", "Carisma" },
        armorProfs = {},
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "disciplina", name = "Disciplina", desc = "Escudos y prevencion que sanan mitigando el dano.", features = {
                { id = "sac_dis_truco", level = 1, name = "Truco de Bonificacion", type = "informativo", description = "Aprendes un truco adicional de sacerdote; no cuenta en tu limite.", effects = {} },
                { id = "sac_dis_supresion", level = 6, name = "Supresion del Dolor", type = "informativo", description = "Accion adicional: barrera invisible a un aliado a 60 pies que reduce daño fisico en 2 + tu bonus de competencia durante 1 minuto.", effects = {} },
            } },
            { id = "sagrado", name = "Sagrado", desc = "Sanacion pura y restauradora con la Luz.", features = {
                { id = "sac_sag_competencia", level = 1, name = "Competencia Adicional (Religion)", type = "pasivo", description = "Pericia en Religion (competencia y bonus de competencia duplicado).", effects = {
                    { kind = "skillExpertise", skill = "Religion" },
                } },
                { id = "sac_sag_himno", level = 1, name = "Himno Divino", type = "informativo", description = "Accion: curacion (= nivel x5 PG) repartida entre criaturas a 30 pies (no por encima de la mitad de su maximo). 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "sac_sag_oracion", level = 6, name = "Oracion de Curacion", type = "informativo", description = "Gasta 1 punto de fe para volver a tirar dados de curacion (tuya o de un aliado a 5 pies). 1 vez por turno.", effects = {} },
            } },
            { id = "sombra", name = "Sombra", desc = "Magia de la mente y energia sombria para destruir.", features = {
                { id = "sac_som_voz", level = 1, name = "Voz Psiquica", type = "informativo", description = "Telepatia con cualquier criatura visible a 30 pies (no necesitais compartir idioma, pero debe entender alguno).", effects = {} },
                { id = "sac_som_legado", level = 1, name = "Legado del Vacio", type = "informativo", description = "Al dañar con un truco, daño psiquico extra = Mod. Carisma (con salvacion de Sabiduria para seguir usandolo).", effects = {} },
                { id = "sac_som_forma", level = 6, name = "Forma de Sombra", type = "informativo", description = "Accion adicional 1 minuto: si vas sin armadura sumas Mod. Carisma a la CA; daño necrotico a quien te golpee; tus conjuros ignoran resistencia necrotica/psiquica. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            } },
        },
        features = {
            { id = "sac_lanzamiento_conjuros", level = 1, name = "Lanzamiento de Conjuros", type = "informativo", description = "Lanzas conjuros de sacerdote usando Carisma (preparas Mod. Carisma + nivel). CD = 8 + comp + Mod. Carisma; ataque = comp + Mod. Carisma. Foco: simbolo sagrado.", effects = {} },
            { id = "sac_llamado_divino", level = 1, name = "Llamado Divino", type = "informativo", description = "Eliges tu llamado (Disciplina, Sagrado o Sombra) a nivel 1. Concede rasgos en niveles 1, 6, 14 y 20.", effects = {} },
            { id = "sac_ecos_fe", level = 2, name = "Ecos de Fe", type = "recurso", description = "Puntos de fe (= nivel) para Devocion (convertir puntos en ranuras de conjuro y viceversa). Recargan en descanso largo.", effects = {
                { kind = "resourceMax", resource = "light_point", perClassLevel = "sacerdote", perLevel = 1 },
            } },
            { id = "sac_absolucion", level = 3, name = "Absolucion", type = "informativo", description = "Canalizas tu fe en absoluciones (empiezas con Encadenar No-muertos + una de tu llamado). CD = tu CD de conjuros.", effects = {} },
            ASI("sacerdote", 4),
            { id = "sac_restauracion_fieles", level = 5, name = "Restauracion de los Fieles", type = "informativo", description = "Recuperas 2 puntos de fe al terminar un descanso corto (3 a nivel 10, 4 a nivel 17).", effects = {} },
        },
    },
    {
        id = "picaro", name = "Picaro", desc = "Maestro del sigilo, las trampas y el ataque furtivo que prospera con astucia y precision.", hitDie = 8,
        saves = { "Destreza", "Inteligencia" },
        armorProfs = { "ligera" },
        weaponProfs = { "sencillas", "ballestas de mano", "espadas largas", "floretes", "espadas cortas" },
        subclasses = {
            { id = "asesino", name = "Asesinato", desc = "Golpes letales, venenos y muerte desde las sombras.", features = {
                { id = "pic_ase_competencia", level = 3, name = "Competencia Adicional (envenenador)", type = "pasivo", description = "Competencia con el equipo de envenenador.", effects = {
                    { kind = "toolProf", tool = "Equipo de envenenador" },
                } },
                { id = "pic_ase_intuicion", level = 3, name = "Intuicion del Asesino", type = "pasivo", description = "Ventaja en ataques contra criaturas que aun no han actuado; tu primer impacto del combate inflige daño extra = tu nivel de picaro.", effects = {
                    { kind = "conditionalWeaponDamage", id = "assassin_intuition", label = "Intuicion del Asesino", flatBonus = "level", flatClassId = "picaro" },
                } },
            } },
            { id = "forajido", name = "Forajido", desc = "Combate audaz con armas de fuego y trucos sucios.", features = {
                { id = "pic_for_competencia", level = 3, name = "Competencia Adicional (pistolas/rifles)", type = "pasivo", description = "Competencia con pistolas y rifles.", effects = WeaponProfEffects("pistolas", "rifles") },
                { id = "pic_for_alacridad", level = 3, name = "Alacridad", type = "pasivo", description = "Sumas tu Mod. Carisma a la iniciativa; al atacar cuerpo a cuerpo, ese objetivo no puede hacerte ataques de oportunidad el resto del turno.", effects = {
                    { kind = "initiativeAbility", ability = "Carisma" },
                } },
            } },
            { id = "sutileza", name = "Sutileza", desc = "Sigilo extremo y ataques furtivos precisos.", features = {
                { id = "pic_sut_conjuracion", level = 3, name = "Conjuracion", type = "informativo", description = "Aprendes magia de sombras (trucos + hechizos). Inteligencia es tu habilidad de conjuro: CD = 8 + comp + Mod. Inteligencia.", effects = {} },
                { id = "pic_sut_vista", level = 3, name = "Vista de Penumbra", type = "informativo", description = "Vision en la oscuridad 60 pies (o +30 si ya la tienes por raza).", effects = {} },
            } },
        },
        features = {
            { id = "pic_pericia", level = 1, name = "Pericia", type = "choice", description = "Elige 2 competencias para duplicar su bonus de competencia.", effects = {}, choice = {
                slots = 2, optionsFrom = "skillExpertise",
            } },
            { id = "pic_ataque_furtivo", level = 1, name = "Ataque Furtivo", type = "pasivo", description = "Una vez por turno, +1d6 de daño (sube con nivel) a una criatura si tienes ventaja o un aliado adyacente, con arma ligera/precision/distancia.", effects = {
                { kind = "conditionalWeaponDamage", id = "sneak", label = "Ataque Furtivo", die = 6, perTwoClassLevels = "picaro" },
            } },
            { id = "pic_misivas", level = 1, name = "Misivas Secretas", type = "informativo", description = "Ocultas mensajes e ideas en conversaciones y cartas mediante jerga y codigos.", effects = {} },
            { id = "pic_energia", level = 2, name = "Energia", type = "pasivo", description = "Puntos de energia (segun la tabla) para maniobras (Mutilar, Exponer Armadura, Garrote). CD de Energia = 8 + comp + Mod. Destreza. Recargan en descanso.", effects = {
                { kind = "resourceMax", resource = "energy", perClassLevel = "picaro",
                  values = { 0, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
            } },
            { id = "pic_mutilar", level = 2, name = "Mutilar", type = "maniobra", description = "Tras impactar a una criatura con la accion de Ataque, gastas 1 punto de energia: el objetivo supera una salvacion de Fuerza (CD de Energia) o queda derribado.", effects = {
                { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Fuerza", outcome = "Derribado", dcAbility = "Destreza", onFailAura = 267937 },
            } },
            { id = "pic_exponer_armadura", level = 2, name = "Exponer Armadura", type = "maniobra", description = "Accion: gastas 1 punto de energia y haces un ataque especial con arma. Si aciertas, infliges daño normal y expones fallos en su defensa: cada otra criatura tiene ventaja en su primera tirada de ataque con arma contra el objetivo antes del final de tu siguiente turno.", effects = {
                { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, onHitAura = 11971 },
            } },
            { id = "pic_garrote", level = 2, name = "Garrote", type = "maniobra", description = "Tras impactar a una criatura con un ataque cuerpo a cuerpo, gastas 1 punto de energia: el objetivo supera una salvacion de Constitucion (CD de Energia) o no puede hablar hasta el final de tu siguiente turno.", effects = {
                { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Constitucion", outcome = "Silenciado", dcAbility = "Destreza", onFailAura = 30900 },
            } },
            { id = "pic_accion_astuta", level = 2, name = "Accion Astuta", type = "informativo", description = "Accion adicional cada turno solo para Correr, Desengancharse o Esconderse.", effects = {} },
            { id = "pic_arquetipo", level = 3, name = "Arquetipo de Picaro", type = "informativo", description = "Eliges tu arquetipo (Asesino, Forajido o Sutileza). Concede rasgos en niveles 3, 9, 13 y 17.", effects = {} },
            ASI("picaro", 4),
            { id = "pic_esquiva_sobrenatural", level = 5, name = "Esquiva Sobrenatural", type = "informativo", cast = "reaccion", reactionTrigger = "damage_taken", reactionEffect = "half_damage", description = "Reaccion al recibir un ataque de un atacante visible: reduces el daño a la mitad.", effects = {} },
            { id = "pic_pericia_2", level = 6, name = "Pericia (mejora)", type = "choice", description = "Elige 2 competencias mas para duplicar su bonus de competencia.", effects = {}, choice = {
                slots = 2, optionsFrom = "skillExpertise",
            } },
        },
    },
    {
        id = "chaman", name = "Chaman", desc = "Mediador de los elementos y los espiritus ancestrales; desata furia elemental, potencia armas o restaura con totems.", hitDie = 8, casterType = "full",
        saves = { "Fuerza", "Sabiduria" },
        armorProfs = { "ligera", "media", "escudo" },
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "elemental", name = "Elemental", desc = "Desata rayos, fuego y tierra contra el enemigo a distancia.", features = {
                { id = "cha_ele_poder", level = 3, name = "Poder Totemico: Mente Tranquila", type = "informativo", description = "Tu totem da ventaja en salvaciones de Constitucion para concentracion a criaturas a 15 pies.", effects = {} },
                { id = "cha_ele_furia", level = 3, name = "Furia Elemental", type = "informativo", description = "Al lanzar un conjuro de daño elemental (acido/frio/fuego/rayo/trueno) puedes cambiar su tipo por otro de la lista.", effects = {} },
                { id = "cha_ele_eco", level = 6, name = "Eco de los Elementos", type = "informativo", description = "Al lanzar un conjuro de daño, repite hasta Mod. Sabiduria dados y usa el resultado que quieras. Usos = Mod. Sabiduria por descanso largo.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
            } },
            { id = "mejora", name = "Mejora", desc = "Imbuye sus armas con los elementos para el cuerpo a cuerpo.", features = {
                { id = "cha_mej_poder", level = 3, name = "Poder Totemico: Furia del Viento", type = "informativo", description = "Tu totem permite repetir un ataque cuerpo a cuerpo fallado a una criatura a 15 pies.", effects = {} },
                { id = "cha_mej_competencia", level = 3, name = "Competencia Adicional (armas marciales)", type = "pasivo", description = "Competencia con armas marciales; puedes usar un arma como foco de conjuro. Cuentas como medio lanzador.", effects = WeaponProfEffects("marciales") },
                { id = "cha_mej_torbellino", level = 3, name = "Torbellino", type = "pasivo", description = "Puntos de torbellino (mitad de tu nivel, redondeado hacia arriba) para ataques con armas elementales (Golpe de Roca, Latigo Elemental, etc.). Recargan en descanso corto o largo.", effects = {
                    { kind = "resourceMax", resource = "maelstrom", perClassLevel = "chaman", values = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
                } },
                { id = "cha_mej_ataque_adicional", level = 6, name = "Ataque Adicional", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la accion de Atacar.", effects = {
                    { kind = "flag", flag = "extraAttack" },
                } },
            } },
            { id = "restauracion", name = "Restauracion", desc = "Sanacion y apoyo mediante totems y aguas curativas.", features = {
                { id = "cha_res_poder", level = 3, name = "Poder Totemico: Marea Viva", type = "informativo", description = "Cuando una criatura a 15 pies del totem cura, el totem cura a otra criatura a 15 pies (= Mod. Sabiduria).", effects = {} },
                { id = "cha_res_guia", level = 3, name = "Guia Ancestral", type = "informativo", description = "Al curar con un conjuro de 1er nivel o superior y sacar 1 o 2 en un dado, repites el dado (usas el nuevo resultado).", effects = {} },
                { id = "cha_res_fuerzas", level = 6, name = "Fuerzas Anuladoras", type = "informativo", description = "Al lanzar un conjuro sobre un aliado, intentas terminar un efecto de conjuro que lo afecte (segun nivel de ranura). 2 usos por descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
            } },
        },
        features = {
            { id = "cha_kalimag", level = 1, name = "Kalimag", type = "informativo", description = "Conoces Kalimag, el idioma de los elementales; dejas mensajes en rocas y agua como el conjuro mensaje.", effects = {} },
            { id = "cha_lanzamiento_conjuros", level = 1, name = "Lanzamiento de Conjuros", type = "informativo", description = "Lanzas conjuros de chaman usando Sabiduria. CD = 8 + comp + Mod. Sabiduria; ataque = comp + Mod. Sabiduria. Foco druidico.", effects = {} },
            { id = "cha_totemista", level = 2, name = "Totemista", type = "recurso", description = "Accion adicional: invocas un totem (CA 15, PG = 2x nivel) con poderes (Resistencia Elemental + el de tu afinidad). 2 usos por descanso corto o largo (3 a nivel 10, 4 a nivel 18).", effects = {
                { kind = "resourceMax", resource = "totem", perClassLevel = "chaman", values = { 0, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4 } },
            } },
            { id = "cha_afinidad_elemental", level = 2, name = "Afinidad Elemental", type = "choice", description = "Te sintonizas con un elemento.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "aire",  label = "Aire (+5 velocidad, +comp a iniciativa)", effects = { { kind = "flag", flag = "initiativeProfBonus" } } },
                    { id = "tierra", label = "Tierra (competencia en salvacion de Constitucion)", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                    { id = "fuego", label = "Fuego (+comp de daño por fuego, 1/turno)", effects = { { kind = "conditionalWeaponDamage", id = "shaman_fire_affinity", label = "Afinidad Fuego", flatBonus = "pb", damageType = "fuego" } } },
                    { id = "agua",  label = "Agua (conjuros conocidos extra)",          effects = {} },
                },
            } },
            { id = "cha_vinculo", level = 3, name = "Vinculo Chamanico", type = "informativo", description = "Eliges tu vinculo (Elemental, Mejora o Restauracion). Concede rasgos en niveles 3, 6, 14 y 20.", effects = {} },
            ASI("chaman", 4),
            { id = "cha_bestia_espiritual", level = 5, name = "Bestia Espiritual", type = "informativo", description = "Accion: asumes la apariencia ilusoria de tu bestia espiritual (velocidad 50 pies). Termina al lanzar conjuro, atacar o como accion adicional.", effects = {} },
        },
    },
    {
        id = "brujo", name = "Brujo", desc = "Invocador que pacta con entidades oscuras para lanzar maldiciones, dominar demonios y desatar fuego vil.", hitDie = 8, casterType = "full",
        saves = { "Constitucion", "Inteligencia" },
        armorProfs = {},
        weaponProfs = { "sencillas" },
        subclasses = {
            { id = "afliccion", name = "Afliccion", desc = "Maldiciones y enfermedades que consumen poco a poco.", features = {
                { id = "bru_afl_lista", level = 2, name = "Lista Ampliada de Conjuros (Afliccion)", type = "informativo", description = "Añade conjuros de sombra/tormento a tu lista de brujo.", effects = {} },
                { id = "bru_afl_corrupcion", level = 2, name = "Corrupcion", type = "informativo", description = "Lanzas Maldiciones (aprendes una; mas a niveles superiores) que puedes amplificar gastando un fragmento de alma. CD = tu CD de conjuros.", effects = {} },
                { id = "bru_afl_acechar", level = 2, name = "Acechar", type = "informativo", description = "Reaccion: una criatura a 60 pies con salvacion de Sabiduria o falla su prueba de habilidad (mente nublada).", effects = {} },
                { id = "bru_afl_maestro_maldiciones", level = 6, name = "Maestro de Maldiciones", type = "informativo", description = "Aprendes conceder maldicion y quitar maldicion (no cuentan); puedes apuntar a dos criaturas en lugar de una.", effects = {} },
            } },
            { id = "demonologia", name = "Demonologia", desc = "Dominio e invocacion de demonios al servicio del brujo.", features = {
                { id = "bru_dem_lista", level = 2, name = "Lista Ampliada de Conjuros (Demonologia)", type = "informativo", description = "Añade conjuros de invocacion/proteccion demoniaca a tu lista de brujo.", effects = {} },
                { id = "bru_dem_conducto", level = 2, name = "Conducto de Almas", type = "informativo", description = "Telepatia con tu esbirro demoniaco; puedes ver/oir por sus sentidos y entregar conjuros de toque a traves de el.", effects = {} },
                { id = "bru_dem_sentir", level = 2, name = "Sentir Demonios", type = "informativo", description = "Accion: detectas demonios a 60 pies. Usos = Mod. Inteligencia por descanso largo.", uses = { ability = "Inteligencia", min = 1, recharge = "long" }, effects = {} },
                { id = "bru_dem_vinculo_almas", level = 6, name = "Vinculo de Almas", type = "informativo", description = "Con tu demonio a 60 pies, la mitad del daño que recibes se transfiere a el; tu demonio puede generar fragmentos de alma con su reaccion.", effects = {} },
            } },
            { id = "destruccion", name = "Destruccion", desc = "Fuego vil explosivo y dano directo abrasador.", features = {
                { id = "bru_des_lista", level = 2, name = "Lista Ampliada de Conjuros (Destruccion)", type = "informativo", description = "Añade conjuros de fuego/destruccion a tu lista de brujo.", effects = {} },
                { id = "bru_des_piromaniaco", level = 2, name = "Piromaniaco", type = "informativo", description = "Aprendes producir llama (no cuenta) y puedes encender objetos inflamables al tocarlos.", effects = {} },
                { id = "bru_des_canalizar", level = 2, name = "Canalizar Fuego Demoniaco", type = "informativo", description = "Al dañar con un conjuro, puedes recibir hasta tu nivel en fuego para que el objetivo reciba el doble de ese daño por fuego.", effects = {} },
                { id = "bru_des_caos", level = 6, name = "Caos", type = "informativo", description = "Con una ranura de Hechiceria Vil de un solo objetivo (no personal), gasta un fragmento de alma para apuntar a una segunda criatura.", effects = {} },
            } },
        },
        features = {
            { id = "bru_secretos_profanos", level = 1, name = "Secretos Profanos", type = "informativo", description = "Hablas Eredun; ventaja en Inteligencia sobre aberraciones/demonios/no-muertos; aplicas competencia (o doble) en Carisma con demonios.", effects = {} },
            { id = "bru_hechiceria_vil", level = 1, name = "Hechiceria Vil", type = "informativo", description = "Lanzas conjuros de brujo usando Inteligencia; ranuras de un mismo nivel que recargan en descanso corto. CD = 8 + comp + Mod. Inteligencia.", effects = {} },
            { id = "bru_toque_vida", level = 1, name = "Toque de Vida", type = "informativo", description = "Sin ranuras, lanzas un conjuro perdiendo PG (= nivel + nivel de ranura). 1 uso a nivel 1 (mas a niveles superiores).", effects = {} },
            { id = "bru_estudio_vil", level = 2, name = "Estudio Vil", type = "informativo", description = "Eliges tu estudio (Afliccion, Demonologia o Destruccion) a nivel 2. Concede rasgos en niveles 2, 6, 10, 14 y 18.", effects = {} },
            { id = "bru_conocimiento_demoniaco", level = 2, name = "Conocimiento Demoniaco", type = "informativo", description = "Invocas demonios (Grimorio de Servidumbre = minion, o de Sacrificio = nucleo). Solo uno a la vez, tras descanso largo.", effects = {} },
            { id = "bru_fragmentos_alma", level = 3, name = "Fragmentos de Alma", type = "pasivo", description = "Cristales de alma (hasta 3; 5 a nivel 9) que gastas para potenciar conjuros (Circulo de Conjuros, Quemar Alma, Ritos de Alma). Los creas en descanso o de criaturas moribundas.", effects = {
                { kind = "resourceMax", resource = "soul_shard", perClassLevel = "brujo", values = { 0, 0, 3, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5 } },
            } },
            ASI("brujo", 4),
            { id = "bru_forjado_almas", level = 5, name = "Forjado de Almas", type = "informativo", description = "Gastas un fragmento de alma para forjar piedras (Fuego, Salud, Alma, Conjuro). Una de cada tipo a la vez.", effects = {} },
        },
    },
    {
        id = "guerrero", name = "Guerrero", desc = "Maestro de las armas y la armadura, versatil en el combate cuerpo a cuerpo y a distancia, puro musculo y tecnica.", hitDie = 10,
        saves = { "Fuerza", "Constitucion" },
        armorProfs = { "ligera", "media", "pesada", "escudo" },
        weaponProfs = { "sencillas", "marciales", "armas de fuego" },
        subclasses = {
            { id = "armas", name = "Armas", desc = "Maestria tecnica con armas pesadas y golpes precisos.", features = {
                { id = "gue_arm_arrollar", level = 3, name = "Arrollar", type = "informativo", description = "Reaccion al recibir un ataque cuerpo a cuerpo: tira 1d10 y sumalo a tu CA; si el ataque falla, puedes atacar al objetivo. 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
                { id = "gue_arm_intrepido", level = 3, name = "Intrepido", type = "informativo", description = "Recuperas 1 punto de Furia al final de tu turno si golpeaste a una criatura con un movimiento de furia ese turno.", effects = {} },
            } },
            { id = "furia", name = "Furia", desc = "Berserker de doble empunadura que ataca con ira incontenible.", features = {
                { id = "gue_fur_desatada", level = 3, name = "Furia Desatada", type = "informativo", description = "En tu primer ataque del turno puedes desatar tu furia: ventaja en ataques cuerpo a cuerpo con Fuerza ese turno, pero los ataques contra ti tienen ventaja hasta tu proximo turno.", effects = {} },
                { id = "gue_fur_temible", level = 3, name = "Temible", type = "pasivo", description = "Competencia en Intimidacion (si no la tienes); puedes usar tu Mod. Fuerza en lugar de Carisma en sus pruebas.", effects = { { kind = "skillProf", skill = "Intimidacion" } } },
            } },
            { id = "proteccion", name = "Proteccion", desc = "Tanque con escudo que protege a sus aliados.", features = {
                { id = "gue_pro_provocacion", level = 3, name = "Provocacion", type = "informativo", description = "Accion: las criaturas a 9 m que elijas hacen salvacion de Sabiduria (CD de Furia) o tienen desventaja en ataques contra otros durante 1 minuto. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "gue_pro_control", level = 3, name = "Control de Ira", type = "informativo", description = "Cuando una criatura hostil te golpea con un ataque, ganas 1 punto de Furia (una vez por turno).", effects = {} },
            } },
        },
        features = {
            { id = "guerrero_estilo_combate", level = 1, name = "Estilo de Combate", type = "choice", description = "Adoptas un estilo de combate como especialidad. Elige una opcion.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "defensa",    label = "Defensa (+1 CA con armadura)",          effects = { { kind = "bonus", target = "armorClass", value = 1 } } },
                    { id = "duelo",      label = "Duelo (+2 daño un arma a una mano)",    effects = { { kind = "bonus", target = "weaponDamage", value = 2 } } },
                    { id = "gran_arma",  label = "Gran Arma (repetir 1-2 en daño a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
                    { id = "proteccion", label = "Proteccion (desventaja a atacantes, con escudo)", effects = {} },
                    { id = "dos_armas",  label = "Combate con Dos Armas (+mod al daño del 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                },
            } },
            { id = "guerrero_segundo_aliento", level = 1, name = "Segundo Aliento", type = "accion", description = "Accion adicional: gasta un dado de golpe para recuperar PG (total + Mod. Constitucion). Recarga con descanso.", effects = {} },
            { id = "guerrero_furia_interna", level = 2, name = "Furia Interna", type = "pasivo", description = "Ganas puntos de Furia al dañar con armas; los gastas en maniobras (Desarme, Golpe Heroico, Carga). Maximo de Furia = tu nivel de Guerrero. CD Furia = 8 + comp + Mod. Fuerza.", effects = {
                { kind = "resourceMax", resource = "rage", perClassLevel = "guerrero", base = 0, perLevel = 1 },
            } },
            { id = "guerrero_man_golpe_heroico", level = 2, name = "Golpe Heroico", type = "recurso", description = "Gasta 1 punto de Furia en una tirada de ataque para infligir daño adicional igual a tu Mod. Fuerza. Activalo en 'Daño extra'.", effects = {
                { kind = "conditionalWeaponDamage", id = "war_golpe_heroico", label = "Golpe Heroico", flatAbility = "Fuerza", resourceCost = "rage", costPerLevel = 1, minLevel = 1, maxLevel = 1 },
            } },
            { id = "guerrero_man_desarme", level = 2, name = "Desarme", type = "recurso", description = "Gasta 2 puntos de Furia en una tirada de ataque; si impacta, daño normal y el objetivo suelta un objeto a tu eleccion. Activalo en 'Daño extra'.", effects = {
                { kind = "conditionalWeaponDamage", id = "war_desarme", label = "Desarme (suelta objeto)", resourceCost = "rage", costPerLevel = 2, minLevel = 1, maxLevel = 1, onHitAura = 177714 },
            } },
            { id = "guerrero_man_carga", level = 2, name = "Carga", type = "maniobra", description = "Gasta 1 punto de Furia para realizar una carga contra el objetivo y resolver un ataque especial con arma.", effects = {
                { kind = "energyManeuver", resource = "rage", cost = 1, spendOnHit = true, attack = true },
            } },
            { id = "guerrero_arquetipo_marcial", level = 3, name = "Arquetipo Marcial", type = "informativo", description = "Eliges tu arquetipo (Armas, Furia o Proteccion). Concede rasgos en niveles 3, 7, 11, 15 y 18.", effects = {} },
            ASI("guerrero", 4),
            { id = "guerrero_ataque_extra", level = 5, name = "Ataque Extra", type = "pasivo", description = "Atacas dos veces, en lugar de una, al realizar la accion de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
            { id = "guerrero_accion_adicional", level = 6, name = "Accion Adicional", type = "accion", description = "Una accion adicional extra en tu turno; recarga con descanso corto o largo.", effects = {} },
        },
    },
}

local classById, classOrder

local UTF8_ACCENT_MAP = {
    ["\195\129"] = "a", ["\195\161"] = "a", ["\195\128"] = "a", ["\195\160"] = "a",
    ["\195\132"] = "a", ["\195\164"] = "a", ["\195\130"] = "a", ["\195\162"] = "a",
    ["\195\137"] = "e", ["\195\169"] = "e", ["\195\136"] = "e", ["\195\168"] = "e",
    ["\195\139"] = "e", ["\195\171"] = "e", ["\195\138"] = "e", ["\195\170"] = "e",
    ["\195\141"] = "i", ["\195\173"] = "i", ["\195\140"] = "i", ["\195\172"] = "i",
    ["\195\143"] = "i", ["\195\175"] = "i", ["\195\142"] = "i", ["\195\174"] = "i",
    ["\195\147"] = "o", ["\195\179"] = "o", ["\195\146"] = "o", ["\195\178"] = "o",
    ["\195\150"] = "o", ["\195\182"] = "o", ["\195\148"] = "o", ["\195\180"] = "o",
    ["\195\154"] = "u", ["\195\186"] = "u", ["\195\153"] = "u", ["\195\185"] = "u",
    ["\195\156"] = "u", ["\195\188"] = "u", ["\195\155"] = "u", ["\195\187"] = "u",
    ["\195\145"] = "n", ["\195\177"] = "n",
}

local SUBCLASS_ID_ALIASES = {
    paladin = {
        retribucion = "represion",
        reprension = "represion",
    },
}

local SUBCLASS_TEXT_ALIASES = {
    paladin = {
        retribucion = "represion",
        reprension = "represion",
    },
}

local function Normalize(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    -- Acentos por SECUENCIA UTF-8 (2 bytes, lider \195). NO usar clases de bytes [áàä]:
    -- en UTF-8 cada vocal acentuada son 2 bytes y la clase corrompe el texto (la "o" de
    -- "Restauracion" se partia en "ao"), rompiendo el match de subclases/razas acentuadas.
    value = value:gsub("\195.", UTF8_ACCENT_MAP)
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function NormalizeSubclassId(classId, subclassId)
    classId = tostring(classId or "")
    subclassId = tostring(subclassId or "")
    local aliases = SUBCLASS_ID_ALIASES[classId]
    return (aliases and aliases[subclassId]) or subclassId
end

-- Variante en MASCULINO de un texto ya normalizado (sin acentos, minusculas). Sirve para
-- que los nombres en FEMENINO del About TRP3 (Maga, Bruja, Picara, Guerrera, Sacerdotisa,
-- Cazadora, Forajida...) resuelvan a su clase/subclase canonica (masculina). Se usa SOLO
-- como fallback: el texto original se prueba primero, asi no rompe nombres canonicos que
-- acaban en 'a' (Escarcha, Ira, Sutileza, Restauracion...).
local GENDER_ALIAS = {
    sacerdotisa = "sacerdote", cazadora = "cazador", luchadora = "luchador",
    hechicera = "hechicero", guerrera = "guerrero", druidesa = "druida",
}
-- Palabras funcionales que NO se masculinizan (si no, "la"->"lo" rompe "Elfa de la Noche").
local GENDER_STOP = { la = true, las = true, una = true, unas = true, de = true,
    del = true, el = true, los = true, ["a"] = true, ["y"] = true, en = true }
local function Masculinize(normalized)
    return (tostring(normalized or ""):gsub("%a+", function(w)
        if GENDER_ALIAS[w] then return GENDER_ALIAS[w] end
        if GENDER_STOP[w] then return w end
        return (w:gsub("a$", "o"))  -- 'a' final de palabra -> 'o'
    end))
end

local function EnsureIndex()
    if classById then return end
    classById, classOrder = {}, {}
    for _, classDef in ipairs(API.CLASSES) do
        classById[classDef.id] = classDef
        classOrder[#classOrder + 1] = classDef.id
    end
end

function API.GetClasses()
    EnsureIndex()
    return API.CLASSES
end

function API.GetClass(classId)
    EnsureIndex()
    return classById[tostring(classId or "")]
end

function API.GetClassOrder()
    EnsureIndex()
    return classOrder
end

function API.GetSubclass(classId, subclassId)
    local classDef = API.GetClass(classId)
    if not classDef then return nil end
    subclassId = NormalizeSubclassId(classId, subclassId)
    for _, subclass in ipairs(classDef.subclasses or {}) do
        if subclass.id == subclassId then return subclass end
    end
    return nil
end

function API.NormalizeSubclassId(classId, subclassId)
    return NormalizeSubclassId(classId, subclassId)
end

function API.GetDefaultSubclassId(classId)
    local classDef = API.GetClass(classId)
    local first = classDef and classDef.subclasses and classDef.subclasses[1]
    return first and first.id or ""
end

function API.GetSubclassUnlockLevel(classId)
    local classDef = API.GetClass(classId)
    local best
    for _, subclass in ipairs((classDef and classDef.subclasses) or {}) do
        for _, feature in ipairs(subclass.features or {}) do
            local level = tonumber(feature.level)
            if level and (not best or level < best) then
                best = level
            end
        end
    end
    return best
end

function API.FindClassIdByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil end
    EnsureIndex()
    local masc = Masculinize(clean)
    for _, classDef in ipairs(API.CLASSES) do
        local n, i = Normalize(classDef.name), Normalize(classDef.id)
        if clean:find(n, 1, true) or clean:find(i, 1, true)
            or (masc ~= clean and (masc:find(n, 1, true) or masc:find(i, 1, true)))
        then
            return classDef.id
        end
    end
    return nil
end

function API.FindSubclassIdByText(classId, text)
    local classDef = API.GetClass(classId)
    local clean = Normalize(text)
    if not classDef or clean == "" then return nil end
    local masc = Masculinize(clean)
    local bestId, bestLen
    for _, subclass in ipairs(classDef.subclasses or {}) do
        local candidates = { subclass.id, subclass.name }
        local aliases = SUBCLASS_TEXT_ALIASES[classDef.id]
        if aliases then
            for alias, targetId in pairs(aliases) do
                if targetId == subclass.id then
                    candidates[#candidates + 1] = alias
                end
            end
        end
        local normalizedName = Normalize(subclass.name)
        -- Muchas especializaciones del libro usan prefijos ("Camino de",
        -- "Marca de", "Presencia de"). El About TRP3 suele escribir solo el
        -- nombre jugable, asi que probamos tambien la ultima palabra relevante.
        local tail = normalizedName:match("([^%s]+)$")
        if tail and tail ~= normalizedName then
            candidates[#candidates + 1] = tail
        end
        for _, candidate in ipairs(candidates) do
            local normalized = Normalize(candidate)
            -- original primero; fallback en masculino para subclases escritas en femenino
            -- (Forajida->forajido, etc.). Las subclases canonicas acabadas en 'a' (Escarcha,
            -- Sutileza, Ira...) casan con el texto original, no con la variante.
            if normalized ~= "" and (clean:find(normalized, 1, true)
                or (masc ~= clean and masc:find(normalized, 1, true))) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = subclass.id, len
                end
            end
        end
    end
    return bestId
end

function API.GetClassName(classId)
    local classDef = API.GetClass(classId)
    return classDef and classDef.name or tostring(classId or "")
end

function API.GetSubclassName(classId, subclassId)
    local subclass = API.GetSubclass(classId, subclassId)
    return subclass and subclass.name or ""
end

-- Resuelve la lista de opciones de un rasgo con `choice`. Devuelve { {id,label,effects}, ... }.
-- `choice.options` se usa tal cual; `choice.optionsFrom` genera la lista desde datos:
--   "ability+1"      -> cada caracteristica como +1 (ASI).
--   "skillProf"      -> cada habilidad como competencia.
--   "skillExpertise" -> cada habilidad como pericia (x2).
function API.GetChoiceOptions(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return nil end
    if type(choice.options) == "table" then return choice.options end

    local from = tostring(choice.optionsFrom or "")
    local out = {}
    -- "ability+N": cada caracteristica como +N (ASI usa +1; razas usan +2 o +1).
    local abilInc = from:match("^ability%+(%d+)$")
    if abilInc and HarfordDnDData and HarfordDnDData.ABIL then
        local value = tonumber(abilInc) or 1
        for _, abil in ipairs(HarfordDnDData.ABIL) do
            out[#out + 1] = {
                id = abil.key, label = abil.key .. " +" .. value,
                effects = { { kind = "bonus", target = "ability", ability = abil.key, value = value } },
            }
        end
    elseif (from == "skillProf" or from == "skillExpertise") and HarfordDnDData and HarfordDnDData.SKILLS then
        local kind = (from == "skillExpertise") and "skillExpertise" or "skillProf"
        for _, skill in ipairs(HarfordDnDData.SKILLS) do
            out[#out + 1] = {
                id = skill.id, label = skill.name or skill.id,
                effects = { { kind = kind, skill = skill.id } },
            }
        end
    else
        return nil
    end
    return out
end

-- Busca una opcion de choice por id dentro de un rasgo.
function API.GetChoiceOption(feature, optionId)
    optionId = tostring(optionId or "")
    if optionId == "" then return nil end
    for _, opt in ipairs(API.GetChoiceOptions(feature) or {}) do
        if opt.id == optionId then return opt end
    end
    return nil
end

-- Texto completo de cada estilo de combate (las opciones solo llevan label corto; el detalle
-- vive aqui, compartido por todas las clases que ofrecen Estilo de Combate).
local COMBAT_STYLE_DESC = {
    defensa             = "Mientras lleves armadura, ganas +1 a la Clase de Armadura.",
    duelo               = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    duelos              = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    ["doble_empuñadura"] = "Cuando empuñas un arma a una mano y ninguna otra, ganas +2 al daño con esa arma.",
    gran_arma           = "Con un arma a dos manos (o versatil usada a dos manos), repites los dados de daño que saquen 1 o 2 y usas el nuevo resultado.",
    proteccion          = "Con un escudo, usas tu reaccion para imponer desventaja a un atacante (a 5 pies) que ataque a otro objetivo distinto de ti.",
    dos_armas           = "Cuando portas dos armas, puedes agregar tu modificador de habilidad al daño del segundo ataque.",
    tiro_arco           = "Ganas +2 a las tiradas de ataque con armas a distancia.",
    tirador             = "Atacar a distancia estando en cuerpo a cuerpo no te impone desventaja, e ignoras media cobertura y tres cuartos; +1 al ataque a distancia.",
    guerrero_profano    = "Aprendes dos trucos de brujo (lanzados con Carisma); no cuentan en tu limite de trucos.",
    guerrero_bendito    = "Aprendes dos trucos de sacerdote (lanzados con Carisma); no cuentan en tu limite de trucos.",
}

-- Descripcion de la OPCION elegida de un choice (para el tooltip del Libro): usa opt.desc si
-- existe; para Estilo de Combate cae al texto compartido por id. nil si no hay descripcion propia.
function API.GetChoiceOptionDesc(feature, optionId)
    local opt = API.GetChoiceOption(feature, optionId)
    if opt and type(opt.desc) == "string" and opt.desc ~= "" then return opt.desc end
    if feature and tostring(feature.name or ""):find("Estilo de Combate") then
        return COMBAT_STYLE_DESC[tostring(optionId)]
    end
    return nil
end

-- Numero de slots a elegir de un rasgo con choice (default 1).
function API.GetChoiceSlots(feature)
    local choice = feature and feature.choice
    if type(choice) ~= "table" then return 0 end
    return math.max(1, math.floor(tonumber(choice.slots) or 1))
end

function API.GetFeature(featureId)
    featureId = tostring(featureId or "")
    for _, classDef in ipairs(API.CLASSES) do
        for _, feature in ipairs(classDef.features or {}) do
            if feature.id == featureId then
                return feature, classDef
            end
        end
    end
    return nil
end

function API.GetUnlockedFeatures(classLevels)
    local out = {}
    for _, entry in ipairs(classLevels or {}) do
        local classDef = API.GetClass(entry.classId)
        local level = tonumber(entry.level) or 0
        if classDef and level > 0 then
            for _, feature in ipairs(classDef.features or {}) do
                if (tonumber(feature.level) or 0) <= level then
                    out[#out + 1] = {
                        classId = classDef.id,
                        className = classDef.name,
                        subclassId = entry.subclassId,
                        level = feature.level,
                        feature = feature,
                    }
                end
            end
            -- Rasgos de la subclase (especializacion) SELECCIONADA, por nivel.
            local subclass = API.GetSubclass(classDef.id, entry.subclassId)
            if subclass then
                for _, feature in ipairs(subclass.features or {}) do
                    if (tonumber(feature.level) or 0) <= level then
                        out[#out + 1] = {
                            classId = classDef.id,
                            className = (classDef.name or "") .. " / " .. (subclass.name or ""),
                            subclassId = entry.subclassId,
                            level = feature.level,
                            feature = feature,
                        }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.className or "") ~= (b.className or "") then return (a.className or "") < (b.className or "") end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return tostring(a.feature and a.feature.name or "") < tostring(b.feature and b.feature.name or "")
    end)
    return out
end
