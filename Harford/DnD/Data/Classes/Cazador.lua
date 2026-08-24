-- Cazador: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "cazador", name = "Cazador", desc = "Experto rastreador y tirador que combate junto a una bestia companera y domina las armas a distancia.", hitDie = 10, startingGold = { dice = 5, sides = 4, multiplier = 1 },
    -- Herramientas de clase segun el manual.
    toolProfs = { "Herramientas de armero" },
    startingEquipment = {
        { label = "Armadura",
            options = {
            { label = "Cota de escamas", items = { "Cota de escamas" } },
            { label = "Armadura de cuero", items = { "Cuero" } },
        } },
        { label = "Arma cuerpo a cuerpo",
            options = {
            { label = "Dos espadas cortas", items = { "Espada corta", "Espada corta" } },
            { label = "Un arma marcial cuerpo a cuerpo", items = { { pick = "Marcial", mode = "Melee" } } },
        } },
        { label = "Arma a distancia",
            options = {
            { label = "Una ballesta ligera y 20 virotes", items = { "Ballesta ligera", "20 virotes" } },
            { label = "Un arco largo y carcaj con 20 flechas", items = { "Arco largo", "Carcaj con 20 flechas" } },
            { label = "Un rifle y 20 balas", items = { "Rifle", "20 balas" } },
        } },
        { label = "Paquete",
            fixed = { "Herramientas de armero", "Trampa de caza" },
            options = {
            { label = "Paquete de aventurero", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 3,
    skillOptions = { "Animales", "Perspicacia", "Investigacion", "Naturaleza", "Percepcion",
        "Sigilo", "Supervivencia" },
    saves = { "Fuerza", "Destreza" },
    armorProfs = { "ligera", "media" },
    weaponProfs = { "sencillas", "marciales", "armas de fuego" },
    subclasses = {
        { id = "bestias", name = "Bestias", desc = "Vínculo profundo con una poderosa bestia companera.", features = {
            { id = "caz_bes_domador", level = 3, name = "Domador de bestias", type = "informativo", companions = true, description = "Puedes domar bestias Grandes o menores con valor de desafío 1 o menor.", effects = {} },
            { id = "caz_bes_aspecto", level = 3, name = "Aspecto de la bestia", type = "informativo", description = "Lanzas sentido de la bestia como ritual, solo en tu mascota.", -- El conjuro existe en el compendio (`sentido_de_bestia`), asi que se concede como tal en
                -- vez de dejarlo solo en la descripcion. El limite "solo en tu mascota" queda
                -- narrativo: el motor no distingue objetivos de conjuro por tipo de criatura.
                grantedSpells = { "sentido_de_bestia" }, effects = {} },
            { id = "caz_bes_comando", level = 5, name = "Comando de matar", cast = "accion_adicional", type = "accion", resourceKey = "focus", resourceCost = 1, rollModifier = { die = 8, valueLabel = "al dano del primer impacto de tu mascota" }, description = "Acción adicional + dado de enfoque: tu mascota Ataca con ventaja; añades el dado al daño del primer impacto.", effects = {} },
                        { id = "caz_bes_vinculo_del_companero", level = 3, name = "Vínculo del Compañero", type = "informativo", companions = true, description = "Tu leal compañero gana una variedad de beneficios. - La bestia pierde su acción de Multiataque, si tiene una. - Tu compañero obedece tus órdenes lo mejor que puede. Comparte tu conteo de iniciativa, pero actúa inmediatamente después de ti. Puede moverse y usar su reacción por sí solo, pero la única acción que realiza es la acción de Esquivar, a menos que uses tu acción adicional para ordenarle que realice la acción de Atacar, Correr, Desengancharse o Ayudar. Si estás incapacitado o ausente, tu bestia actúa por su cuenta. - Tu compañero bestial tiene habilidades y estadísticas determinadas en parte por tu nivel, usando tu bonificador de competencia en lugar del suyo. Además de las áreas donde normalmente usa su bonificador de competencia, tu compañero también agrega su bonificador de competencia a su CA y a sus tiradas de daño.", effects = {} },
        } },
        { id = "punteria", name = "Punteria", desc = "Tiros precisos y devastadores a larga distancia.", features = {
            { id = "caz_pun_disparo_arcano", level = 3, name = "Disparo arcano", type = "informativo", description = "Tus ataques a distancia contra tu marcado ignoran cobertura e infligen +(2 + mitad de nivel) de fuerza. Usos = Mod. Sabiduría.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
            { id = "caz_pun_lobo_apuntado", level = 3, name = "Lobo solitario: Ataque apuntado", cast = "accion_adicional", type = "pasivo", description = "Sin compañero bestial, acción adicional para dar ventaja a tu próximo ataque con arma.", effects = {
                { kind = "toggleState", state = "lone_wolf", label = "Lobo Solitario", description = "Activa rasgos que requieren combatir sin companero bestial." },
            } },
            { id = "caz_pun_disparo_conmocionante", level = 5, name = "Disparo conmocionante", type = "accion", resourceKey = "focus", resourceCost = 1, rollModifier = { die = 8, valueLabel = "a la CD de concentracion de tu disparo" }, description = "Gasta un dado de enfoque para sumarlo a la CD de concentración que provoque tu ataque.", effects = {} },
            { id = "caz_pun_lobo_ataque", level = 5, name = "Lobo solitario: Ataque adicional", type = "pasivo", description = "Sin compañero bestial, atacas dos veces al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack", requiresState = "lone_wolf" },
            } },
                        { id = "caz_pun_aspecto_del_aguila", level = 7, name = "Aspecto del Aguila", type = "informativo", description = "A partir del nivel 7, puedes ver hasta 1,6 km de distancia sin dificultad, pudiendo discernir incluso los detalles más finos como si estuvieras observando algo a no más de 30 metros de distancia. Además, atacar a larga distancia no impone desventaja en tus tiradas de ataque con armas a distancia.", effects = {} },
            { id = "caz_pun_ataque_multiple", level = 11, name = "Ataque Múltiple", type = "informativo", description = "Al alcanzar el nivel 11, obtienes una de las siguientes características de tu elección. ***Disparo de Quimera.*** Una vez en cada uno de tus turnos, cuando hagas un ataque con arma a distancia, puedes realizar otro ataque con la misma arma contra una criatura diferente que esté a 1,5 metros del objetivo original y dentro del alcance de tu arma. Si se usa con tu característica Lobo Solitario, ambos ataques tienen ventaja. ***Disparo Penetrante.*** Una vez en cada uno de tus turnos, cuando realices un ataque con arma a distancia contra una criatura, puedes hacer que el ataque atraviese múltiples criaturas. Realiza una tirada de ataque con desventaja contra cada criatura en una línea directamente detrás del objetivo original, hasta que falles, golpees un objeto o alcances el rango normal de tu arma, lo que ocurra primero.", effects = {} },
            { id = "caz_pun_enfoque_del_tirador", level = 15, name = "Enfoque del Tirador", type = "informativo", description = "En el nivel 15, cuando lances iniciativa y no tengas usos restantes de Disparo Arcano, recuperas un uso.", effects = {} },
        } },
        { id = "supervivencia", name = "Supervivencia", desc = "Trampas, cuerpo a cuerpo y dominio del terreno.", features = {
            { id = "caz_sup_trampero", level = 3, name = "Trampero experto", actionKind = "optionAbility", bookHidden = true, type = "choice", description = "Aprendes DOS trampas a tu eleccion; mas a los niveles 7, 11 y 15. Accion: gastas un uso para colocar una trampa en un espacio a 9 metros. Dura 1 hora o hasta que se use. CD de salvacion de trampa = 8 + tu bonus de competencia + Mod. Sabiduria.", uses = { base = 0, perClassLevel = "cazador", values = { 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3 }, recharge = "short" }, effects = {}, choice = {
                slots = 2,
                options = {
                    { id = "oso", label = "Trampa de oso", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Destreza", success = "none", conditionId = "prone", conditionDuration = "target_turn_start" }, desc = "Al activarse, la criatura debe superar una salvacion de Destreza o ser derribada y quedar boca abajo en su espacio. Cualquier criatura derribada por esta trampa tiene su velocidad reducida a 0 hasta el inicio de su siguiente turno." },
                    { id = "cegadora", label = "Trampa cegadora", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Constitucion", success = "none", conditionId = "blinded", conditionDuration = "target_turn_start" }, desc = "Al activarse, la criatura debe superar una salvacion de Constitucion o quedar cegada hasta el inicio de su siguiente turno. Cualquier criatura invisible que falle esta tirada brilla con luz tenue, haciendola visible durante la duracion." },
                    { id = "enredadora", label = "Trampa enredadora", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Fuerza", success = "none", conditionId = "restrained", conditionDuration = "rounds", conditionTurns = 10 }, desc = "Al activarse, la criatura debe superar una salvacion de Fuerza o quedar restringida durante 1 minuto. Una criatura restringida puede usar su accion para hacer una prueba de Fuerza contra tu CD de trampa; con exito, se libera." },
                    { id = "explosiva", label = "Trampa explosiva", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Destreza", success = "half", damageFrom = { classLevel = "cazador", multiplier = 2, damageType = "fuego" } }, desc = "Al activarse, la criatura debe superar una salvacion de Destreza. Si falla recibe dano por fuego igual al DOBLE de tu nivel de cazador; con exito, la mitad." },
                    { id = "congelacion", label = "Trampa de congelacion", area = { shape = "other", sizeText = "Objetivo", resolution = "save", saveAbility = "Destreza", success = "none", conditionId = "restrained", conditionDuration = "rounds", conditionTurns = 10 }, desc = "Al activarse, la criatura debe superar una salvacion de Destreza o quedar restringida durante 1 minuto. Mientras lo este, tiene cobertura total y no puede realizar ninguna accion salvo intentar liberarse con una prueba de Fuerza contra tu CD de trampa. Con exito rompe el hielo y se libera. No afecta a criaturas de tamano Enorme o mayores. La criatura esta encerrada en hielo, con CA 10 y puntos de golpe iguales a cuatro veces tu nivel de cazador." },
                    { id = "hielo", label = "Trampa de hielo", area = { shape = "sphere", sizeText = "6 m de radio", resolution = "save", saveAbility = "Destreza", success = "none", conditionId = "prone", conditionDuration = "manual" }, desc = "Al activarse, el hielo se extiende en un radio de 6 metros alrededor de la trampa, creando terreno dificil. Una criatura que se mueva por el area por primera vez en su turno debe superar una salvacion de Destreza o caer derribada." },
                    { id = "inmolacion", label = "Trampa de inmolacion", area = { shape = "sphere", sizeText = "Alcance de la trampa", resolution = "save", saveAbility = "Destreza", success = "half", damageFrom = { classLevel = "cazador", damageType = "fuego" } }, desc = "Al activarse, cada criatura a su alcance debe superar una salvacion de Destreza. Si falla, recibe dano por fuego igual a tu nivel de cazador y ademas se prende en llamas: al inicio de cada uno de sus turnos recibe dano igual a la mitad de tu nivel de cazador (redondeado hacia arriba) hasta que las llamas sean apagadas como una accion. Con exito, solo el dano inicial." },
                    { id = "veneno", label = "Trampa de veneno", area = { shape = "sphere", sizeText = "Alcance de la trampa", resolution = "save", saveAbility = "Constitucion", success = "none", conditionId = "poisoned", conditionDuration = "save_at_turn_end", conditionSaveAbility = "Constitucion" }, desc = "Al activarse, cada criatura a su alcance recibe 1 punto de dano perforante y debe superar una salvacion de Constitucion o quedar envenenada durante 1 minuto. Puede repetir la salvacion al final de cada uno de sus turnos, terminando el efecto con exito." },
            } } },
            { id = "caz_sup_estudiante", level = 3, name = "Estudiante de lo salvaje", type = "pasivo", description = "Pericia en Supervivencia (competencia y bonus de competencia duplicado).", effects = {
                { kind = "skillExpertise", skill = "Supervivencia" },
            } },
            { id = "caz_sup_lobo_salvaje", level = 3, name = "Lobo solitario: Nacido para ser salvaje", type = "pasivo", description = "Sin compañero bestial, tus ataques con arma son criticos con 19-20 y Desengancharte es acción adicional.", effects = {
                { kind = "toggleState", state = "lone_wolf", label = "Lobo Solitario", description = "Activa rasgos que requieren combatir sin companero bestial." },
                { kind = "critRange", value = 19, requiresState = "lone_wolf" },
            } },
            { id = "caz_sup_corte_ala", level = 5, name = "Corte de ala", resourceKey = "focus", resourceCost = 1, type = "maniobra", description = "Al golpear, gasta un dado de enfoque: el objetivo con Fuerza (Atletismo) o su velocidad baja a 0 hasta tu próximo turno.", effects = { { kind = "energyManeuver", resource = "focus", cost = 1, spendOnHit = true, attack = true, save = "Fuerza", skill = "Atletismo", dcAbility = "Sabiduria", outcome = "velocidad 0", conditionId = "rooted", conditionDuration = "source_turn_start" } } },
            { id = "caz_sup_lobo_ataque", level = 5, name = "Lobo solitario: Ataque adicional", type = "pasivo", description = "Sin compañero bestial, atacas dos veces al realizar la acción de Atacar.", effects = {
                { kind = "flag", flag = "extraAttack", requiresState = "lone_wolf" },
            } },
            { id = "caz_sup_camuflaje_natural", level = 7, name = "Camuflaje Natural", type = "informativo", description = "A partir del nivel 7, obtienes la capacidad de lanzar el conjuro *pasar sin dejar rastro* sin proporcionar componentes materiales, pero solo como un ritual. Debes tener acceso a barro fresco, tierra, plantas, hollín u otros materiales naturales para poder hacerlo.", effects = {} },
            { id = "caz_sup_contraataque_marcado", level = 11, name = "Contraataque Marcado", type = "informativo", description = "Al alcanzar el nivel 11, si tu objetivo marcado te obliga a realizar una tirada de salvación, puedes usar tu reacción para realizar un ataque con arma contra el objetivo. Realizas este ataque antes de hacer la tirada de salvación. Si tu ataque impacta, obtienes ventaja en tu tirada de salvación, además de los efectos normales del ataque.", effects = {} },
            { id = "caz_sup_terminos_de_compromiso", level = 15, name = "Términos de Compromiso", type = "informativo", description = "En el nivel 15, demuestras un control incomparable sobre tus trampas y utilizas las oportunidades que crean. Obtienes los siguientes beneficios: - Tienes ventaja en ataques con armas contra cualquier criatura que haya sido golpeada por una de tus trampas desde el final de tu último turno. - Tus trampas ya no se activan cuando una criatura entra en su alcance; en su lugar, puedes elegir como acción gratuita activar una trampa, incluso si no hay una criatura cerca.", effects = {} },
        } },
    },
    features = {
        { id = "caz_marca_cazador", level = 1, name = "Marca del Cazador", cast = "accion_adicional", type = "accion", actionKind = "huntersMark", markAuraId = 259556, description = "Acción adicional: marcas una criatura a 120 pies. Hasta que termine la marca, una vez por turno infliges +1d4 de daño al golpearla con un arma (sube a 1d6/1d8/1d10 con el nivel). Ventaja en Percepción y Supervivencia para encontrarla.", effects = {
            { kind = "conditionalWeaponDamage", id = "hunters_mark", label = "Marca del Cazador", count = 1, die = 4, scaleClassId = "cazador", dieScale = { { 6, 6 }, { 11, 8 }, { 16, 10 } }, requiresMarkedTarget = true },
        } },
        { id = "caz_explorador_natural", level = 1, name = "Explorador natural", type = "pasivo", description = "Sumas tu Mod. Sabiduría a la iniciativa; ventaja en el primer turno contra criaturas que no han actuado; ventajas viajando por la naturaleza.", effects = {
            { kind = "initiativeAbility", ability = "Sabiduria" },
        } },
        { id = "caz_estilo_combate", level = 2, name = "Estilo de combate", type = "choice", description = "Adoptas un estilo de combate como especialidad.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "tiro_arco",   label = "Tiro con Arco (+2 ataque a distancia)", effects = { { kind = "bonus", target = "weaponAttack", value = 2 } } },
                { id = "tirador",     label = "Tirador en Combate Cercano (+1 ataque a distancia, ignora cobertura)", effects = { { kind = "bonus", target = "weaponAttack", value = 1 } } },
                { id = "dos_armas",   label = "Combate con Dos Armas (+mod al 2º ataque)", effects = { { kind = "flag", flag = "offhandDamageMod" } } },
                { id = "gran_arma",   label = "Combate con Arma Grande (repetir 1-2 a dos manos)", effects = { { kind = "flag", flag = "greatWeaponFighting" } } },
            },
        } },
        { id = "caz_enfoque", level = 2, name = "Enfoque", type = "pasivo", description = "Dados de enfoque (d8, según la tabla) para Llamada de lo Salvaje, Ataque Preciso y Tacticas de Supervivencia. Recargan en descanso corto o largo.", effects = {
            { kind = "resourceMax", resource = "focus", perClassLevel = "cazador", values = { 0, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10 } },
        } },
        { id = "caz_empatia_animal", level = 2, name = "Empatia animal", type = "informativo", description = "Te comunicas con bestias y lees su estado de animo e intencion básica.", effects = {} },
            { id = "caz_enf_llamada", level = 2, name = "Llamada de lo salvaje", type = "accion", resourceKey = "focus", resourceCost = 1, rollModifier = { die = 8, half = true, applies = { ability = true, skill = true, roll = true }, markKey = "focusDie" }, description = "Cuando hagas una prueba que te permita aplicar tu competencia en Naturaleza, Percepcion o Supervivencia, gastas un dado de enfoque y anades la MITAD del resultado (redondeando hacia arriba) a la prueba. Puedes usarlo despues de tirar, pero antes de saber si fue exitosa.", effects = {} },
            { id = "caz_enf_ataque_preciso", level = 2, name = "Ataque preciso", type = "accion", resourceKey = "focus", resourceCost = 1, rollModifier = { die = 8, applies = { attack = true }, markKey = "focusDie" }, description = "Cuando ataques con arma a una criatura, gastas un dado de enfoque y lo anades a la tirada de ataque. Puedes usarlo antes o despues de tirar, pero antes de que se apliquen los efectos.", effects = {} },
            { id = "caz_enf_tacticas", level = 2, name = "Tacticas de supervivencia", type = "informativo", cast = "reaccion", resourceKey = "focus", resourceCost = 1, rollModifier = { die = 8, valueLabel = "a tu CA contra ese ataque (y mitad de dano si aun asi impacta)" }, description = "Reaccion: si te golpean llevando armadura ligera o media, gastas un dado de enfoque y lo anades a tu CA. Si el ataque aun asi golpea, recibes la mitad del dano.", effects = {} },
        { id = "caz_arquetipo", level = 3, name = "Arquetipo de Cazador", type = "informativo", description = "Eliges tu arquetipo (Maestro de Bestias, Punteria o Supervivencia). Concede rasgos en niveles 3, 5, 7, 11 y 15.", effects = {} },
        { id = "caz_domar_bestia", level = 3, name = "Domar bestia", type = "choice", companions = true, description = "Vinculas una bestia (Mediana o menor, desafio 1/2 o menor) como companero. Escribe su bloque en tu TRP3 bajo el frame \"Companero bestial\"; el Vinculo del Companero se aplica solo encima. Elige las dos habilidades en las que sera competente.", effects = {}, choice = { slots = 2, optionsFrom = "beastSkill" } },
        { id = "caz_bestia_mejora", level = 4, name = "Mejora de Caracteristica (bestia)", type = "choice", description = "Al obtener tu Mejora de Caracteristica, la bestia tambien mejora: +2 a una de sus caracteristicas, o +1 a dos. No puede pasar de 20. Actualiza su bloque en el TRP3.", effects = {}, choice = { slots = 2, optionsFrom = "beastAbility" } },
        ASI("cazador", 4),
                { id = "caz_conocimiento_del_depredador", level = 10, name = "Conocimiento del Depredador", type = "informativo", description = "En el 10º nivel, puedes obtener un conocimiento íntimo de las capacidades de tu objetivo marcado. Puedes usar tu acción para aprender dos de las siguientes características de tu elección sobre el objetivo de tu marca de cazador si está dentro de 36,6 metros. - Tipo de Criatura - Clase de Armadura - Velocidad - Vulnerabilidades al Daño - Resistencias al Daño - Inmunidades al Daño - Sentidos Una vez que hayas obtenido las capacidades de una criatura, no puedes usar *Conocimiento del Depredador* para aprender más sobre la criatura, o sobre otra criatura similar, durante las siguientes 24 horas.", effects = {} },
        { id = "caz_acechador", level = 14, name = "Acechador", type = "informativo", description = "A partir del 14º nivel, puedes usar la acción de Esconderse como una acción adicional en tu turno. Además, no puedes ser rastreado por medios no mágicos, a menos que elijas dejar un rastro.", effects = {} },
        { id = "caz_sentidos_agudizados", level = 18, name = "Sentidos Agudizados", type = "informativo", description = "A partir del 18º nivel, obtienes sentidos sobrenaturales que te ayudan a luchar contra criaturas que no puedes ver. Cuando atacas a una criatura que no puedes ver, tu incapacidad para verla no impone desventaja en tus tiradas de ataque contra ella. También eres consciente de la ubicación de cualquier criatura invisible dentro de 9,1 metros de ti, siempre que la criatura no esté escondida de ti y no estés cegado o ensordecido.", effects = {} },
        { id = "caz_aspecto_de_lo_salvaje", level = 20, name = "Aspecto de lo Salvaje", type = "informativo", description = "En el 20º nivel, te conviertes en un cazador incomparable. Una vez en cada uno de tus turnos, puedes añadir tu modificador de Sabiduría a la tirada de ataque o a la tirada de daño de un ataque que realices. Puedes elegir usar esta característica antes o después de la tirada, pero antes de que se apliquen los efectos de la tirada.", effects = {} },
    },
}

-- Rasgos generados a partir de las Trampas elegidas (Cazador, Supervivencia). Mismo patron que
-- las maniobras del Guerrero: la opcion elegida se convierte en un rasgo real y ejecutable, que
-- gasta un uso de Trampero experto (`usesFrom`) al colocarla.
do
    local clase = API.GetClass and API.GetClass("cazador")
    local sub
    for _, sc in ipairs((clase and clase.subclasses) or {}) do
        if sc.id == "supervivencia" then sub = sc break end
    end
    local eleccion
    for _, f in ipairs((sub and sub.features) or {}) do
        if f.id == "caz_sup_trampero" then eleccion = f break end
    end
    for _, opcion in ipairs((eleccion and eleccion.choice and eleccion.choice.options) or {}) do
        sub.features[#sub.features + 1] = {
            id = "caz_sup_trampa_" .. tostring(opcion.id),
            icon = opcion.icon,
            level = 3,
            name = opcion.label,
            type = "accion",
            description = opcion.desc,
            requiresOption = opcion.id,
            usesFrom = "caz_sup_trampero",
            -- Una trampa se COLOCA ahora y se dispara despues, asi que no se resuelve al pulsarla:
            -- `trap` hace que el Libro pregunte cual de las dos cosas estas haciendo.
            trap = true,
            -- CD de trampa = 8 + bonus de competencia + Mod. Sabiduria.
            dcAbility = "Sabiduria",
            area = opcion.area,
            effects = {},
        }
    end
end
