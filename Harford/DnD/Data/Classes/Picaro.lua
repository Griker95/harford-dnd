-- Picaro: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "picaro", name = "Picaro", desc = "Especialista en llegar donde nadie mira: sigilo, cerraduras y emboscadas. Golpea una vez y fuerte, y se va antes de que le respondan.", hitDie = 8, startingGold = { dice = 4, sides = 4, multiplier = 1 },
    -- Herramientas de clase segun el manual.
    toolProfs = { "Herramientas de ladron" },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Un estoque", items = { "Estoque" } },
            { label = "Una espada corta", items = { "Espada corta" } },
        } },
        { label = "Arma secundaria",
            options = {
            { label = "Un arco corto y un carcaj con 20 flechas", items = { "Arco corto", "Carcaj con 20 flechas" } },
            { label = "Una espada corta", items = { "Espada corta" } },
        } },
        { label = "Paquete",
            fixed = { "Cuero", "Daga", "Daga", "Herramientas de ladron" },
            options = {
            { label = "Paquete de ladron", items = { "Paquete de ladron" } },
            { label = "Paquete de mazmorras", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 4,
    skillOptions = { "Acrobacias", "Atletismo", "Engano", "Perspicacia", "Intimidacion",
        "Investigacion", "Percepcion", "Interpretacion", "Persuasion", "JuegoManos", "Sigilo" },
    saves = { "Destreza", "Inteligencia" },
    armorProfs = { "ligera" },
    weaponProfs = { "sencillas", "ballestas de mano", "espadas largas", "floretes", "espadas cortas" },
    subclasses = {
        { id = "asesino", name = "Asesinato", desc = "Golpes letales, venenos y muerte desde las sombras.", features = {
            { id = "pic_ase_competencia", level = 3, name = "Competencia con venenos", type = "pasivo", description = "Competencia con el equipo de envenenador.", effects = {
                { kind = "toolProf", tool = "Equipo de envenenador" },
            } },
            { id = "pic_ase_intuicion", level = 3, name = "Intuicion de asesino", type = "pasivo", description = "Ventaja en ataques contra criaturas que aun no han actuado; tu primer impacto del combate inflige daño extra = tu nivel de picaro.", effects = {
                { kind = "conditionalWeaponDamage", id = "assassin_intuition", label = "Intuicion del Asesino", flatBonus = "level", flatClassId = "picaro" },
            } },
        } },
        { id = "forajido", name = "Forajido", desc = "Combate audaz con armas de fuego y trucos sucios.", features = {
            { id = "pic_for_competencia", level = 3, name = "Competencia con armas de fuego", type = "pasivo", description = "Obtienes competencia con pistolas y rifles.", effects = WeaponProfEffects("pistolas", "rifles") },
            { id = "pic_for_alacridad", level = 3, name = "Alacridad", type = "pasivo", description = "Cuando eliges este arquetipo en el nivel 3, tu confianza te impulsa al combate. Puedes darte un bono a tus tiradas de iniciativa igual a Mod. Carisma.\n\nAdemás, aprendes cómo golpear y retirarte sin represalias. Durante tu turno, si haces un ataque cuerpo a cuerpo contra una criatura, esa criatura no puede hacer ataques de oportunidad contra ti durante el resto de tu turno.", effects = {
                { kind = "initiativeAbility", ability = "Carisma" },
            } },
        } },
        { id = "sutileza", name = "Sutileza", desc = "Sigilo extremo y ataques furtivos precisos.", casterType = "third", expandedSpells = { "Resguardo contra las hojas", "Hoja retumbante", "Amistad", "Rafaga", "Impacto certero", "Mano de mago", "Mensaje", "Ilusion menor", "Prestidigitacion", "Rompante de espadas" }, features = {
            { id = "pic_sut_conjuracion", level = 3, name = "Conjuracion", type = "pasivo", description = "Cuando eliges este arquetipo en el nivel 3, aprendes a aprovechar la magia de las sombras. Consulta [las reglas generales de lanzamiento de conjuros](reglas.html#conjuros); la lista de conjuros de sutileza está al final de esta ficha.\n\n***Trucos.*** Aprendes dos trucos de tu elección de la lista de hechizos de sutileza. Aprendes otro truco de sutileza de tu elección en el nivel 10.\n\n ***Espacios de conjuro.*** La tabla de Conjuración de Sutileza muestra cuántos espacios de conjuro tienes para lanzar tus hechizos de nivel 1 o superior. Para lanzar uno de estos hechizos, debes gastar un espacio de conjuro del nivel del hechizo o superior. Recuperas todos los espacios de conjuro gastados cuando terminas un descanso largo.\n\nPor ejemplo, si conoces el hechizo de nivel 1 *orden* y tienes un espacio de conjuro de nivel 1 y una de nivel 2 disponibles, puedes lanzar *orden* usando cualquiera de los dos espacios.\n\n***Hechizos conocidos de nivel 1 y superior.*** Conoces tres hechizos de sutileza de nivel 1 de tu elección.\n\nLa columna de Hechizos Conocidos de la tabla de Conjuración de Sutileza muestra cuándo aprendes más hechizos de sutileza de nivel 1 o superior. Cada uno de estos hechizos debe ser de un nivel para el que tengas espacios de conjuro. Por ejemplo, cuando alcanzas el nivel 7 en esta clase, puedes aprender un nuevo hechizo de nivel 1 o 2.\n\nSiempre que ganes un nivel en esta clase, puedes reemplazar uno de los hechizos de sutileza que conoces por otro hechizo de tu elección de la lista de hechizos de sutileza. El nuevo hechizo debe ser de un nivel para el que tengas espacios de conjuro.\n\n***Habilidad para lanzar hechizos.*** La Inteligencia es tu habilidad para lanzar tus hechizos de sutileza. Usas tu Inteligencia siempre que un hechizo se refiera a tu habilidad para lanzar hechizos. Además, usas Mod. Inteligencia al establecer la CD de salvación para un hechizo de sutileza que lances y al realizar una tirada de ataque con uno.\n\n**CD de salvación del hechizo** = 8 + Bonus Competencia + Mod. Inteligencia\n\n**Modificador de ataque del hechizo** = Bonus Competencia + Mod. Inteligencia", effects = {} },
            { id = "pic_sut_vista", level = 3, name = "Vista de penumbra", type = "pasivo", description = "También a nivel 3, ganas visión en la oscuridad con un alcance de 18 metros. Si ya tienes visión en la oscuridad debido a tu raza, su alcance aumenta en 9 metros.", effects = {} },
        } },
    },
    features = {
        { id = "pic_pericia", level = 1, name = "Pericia", type = "choice", description = "Elige 2 competencias para duplicar su bonus de competencia.", effects = {}, choice = {
            slots = 2, optionsFrom = "skillExpertise",
        } },
        { id = "pic_ataque_furtivo", level = 1, name = "Ataque furtivo", type = "pasivo", description = "A partir del 1er nivel, sabes cómo golpear sutilmente y aprovechar la distracción de un enemigo. Una vez por turno, puedes infligir un daño extra de 1d6 a una criatura que golpees con un ataque si tienes ventaja en la tirada de ataque. El ataque debe usar un arma ligera, de precisión o a distancia.\n\nNo necesitas tener ventaja en el ataque si otro enemigo del objetivo está a 1,5 metros de él, ese enemigo no está incapacitado y no tienes desventaja en la tirada de ataque.\n\nLa cantidad de daño extra aumenta a medida que ganas niveles en esta clase, como se muestra en la columna de Ataque Furtivo de la tabla del Pícaro.", effects = {
            { kind = "conditionalWeaponDamage", id = "sneak", label = "Ataque Furtivo", die = 6, perTwoClassLevels = "picaro" },
        } },
        { id = "pic_misivas", level = 1, name = "Misivas secretas", type = "pasivo", description = "Durante tu entrenamiento como pícaro, aprendiste a ocultar mensajes, instrucciones e ideas simples a plena vista. Lo haces mediante la incorporación de jerga sutil y gestos en diálogos aparentemente normales, compartiendo declaraciones con significados ocultos o incluso escribiendo en un código críptico.\n\nPuedes usar 4 horas para compartir un conjunto de estas reglas con otra criatura, permitiéndote entrelazar mensajes y comandos secretos en tus conversaciones y cartas. Las reglas más elaboradas pueden requerir una prueba de Inteligencia, a discreción del DM.", effects = {} },
        { id = "pic_energia", level = 2, name = "Energia", type = "pasivo", description = "En el 2do nivel, aprendes a debilitar aún más a una criatura mediante el uso de energía. Tu nivel de pícaro determina la cantidad de puntos de energía que tienes, como se muestra en la columna de Puntos de Energía de la tabla del Pícaro.\n\nPuedes gastar estos puntos para activar diversas maniobras de energía. Comienzas conociendo tres maniobras: Mutilar, Exponer Armadura y Garrote. Aprendes más maniobras de energía a medida que ganas niveles en esta clase.\n\nCuando gastas un punto de energía, este no está disponible hasta que termines un descanso corto o largo, al final del cual recuperas toda tu energía gastada.\n\nTus características de energía requieren que tu objetivo realice una tirada de salvación para resistir sus efectos. La CD de salvación de energía se calcula de la siguiente manera:\n\n**CD de salvación de energía** = 8 + Bonus Competencia + Mod. Destreza", effects = {
            { kind = "resourceMax", resource = "energy", perClassLevel = "picaro",
              values = { 0, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
        } },
        { id = "pic_mutilar", level = 2, name = "Mutilar", type = "maniobra", description = "Inmediatamente después de golpear a una criatura con la acción de Ataque, puedes gastar 1 punto de energía para mutilarla. El objetivo debe superar una tirada de salvación de Fuerza o ser derribado.", effects = {
            { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Fuerza", outcome = "Derribado", dcAbility = "Destreza", onFailAura = 267937, conditionId = "prone" },
        } },
        { id = "pic_exponer_armadura", level = 2, name = "Exponer armadura", cast = "accion", type = "maniobra", description = "Puedes usar tu acción y gastar 1 punto de energía para realizar un ataque especial con arma. Si aciertas, infliges daño normal y expones fallos en su defensa. Cada otra criatura tiene ventaja en la primera tirada de ataque con arma que haga contra el objetivo antes del final de tu siguiente turno.", effects = {
            { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, onHitAura = 11971, conditionId = "exposed_armor", conditionDuration = "source_turn_end", conditionTurns = 2 },
        } },
        { id = "pic_garrote", level = 2, name = "Garrote", type = "maniobra", description = "Cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar 1 punto de energía para garrotearla. El objetivo debe superar una tirada de salvación de Constitución o no podrá hablar hasta el final de tu siguiente turno.", effects = {
            { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Constitucion", outcome = "Silenciado", dcAbility = "Destreza", onFailAura = 30900, conditionId = "silenced", conditionDuration = "source_turn_end", conditionTurns = 2 },
        } },
        { id = "pic_accion_astuta", level = 2, name = "Accion astuta", type = "informativo", grantsAsBonus = { "correr", "desengancharse", "esconderse" }, description = "Acción adicional cada turno solo para Correr, Desengancharse o Esconderse.", effects = {} },
        { id = "pic_arquetipo", subclassMarker = true, level = 3, name = "Arquetipo de Picaro", type = "informativo", description = "En el 3er nivel, eliges un área en la que especializarte, que moldea tus habilidades como pícaro: Asesino, Forajido o Sutileza, todos detallados al final de la descripción de la clase. Tu elección de arquetipo te otorga características en el 3er nivel y luego nuevamente en los niveles 9, 13 y 17.", effects = {} },
        ASI("picaro", 4),
        { id = "pic_esquiva_sobrenatural", level = 5, name = "Esquiva sobrenatural", type = "informativo", cast = "reaccion", reactionTrigger = "damage_taken", reactionEffect = "half_damage", description = "Reacción al recibir un ataque de un atacante visible: reduces el daño a la mitad.", effects = {} },
        { id = "pic_pericia_6", level = 6, name = "Pericia", type = "choice", description = "Elige 2 competencias mas para duplicar su bonus de competencia.", effects = {}, choice = {
            slots = 2, optionsFrom = "skillExpertise",
        } },
                { id = "pic_evasion", icon = "spell_shadow_shadowward", level = 7, name = "Evasión", type = "informativo", description = "En el 7mo nivel, puedes esquivar con agilidad ciertos efectos de área, como el aliento de fuego de un dragón rojo o el conjuro *tormenta de hielo*. Cuando te sometas a un efecto que te permita realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibirás daño si tienes éxito en la tirada de salvación, y solo recibirás la mitad del daño si fallas.", effects = {} },
        { id = "pic_anticipacion", icon = "ability_rogue_slaughterfromtheshadows", level = 15, name = "Anticipación", type = "informativo", description = "En el 15vo nivel, siempre estás observando a tus enemigos en busca de oportunidades. En combate, obtienes una segunda reacción que puedes tomar una vez por turno. Puedes usar esta segunda reacción solo para realizar un ataque de oportunidad, y no puedes usarla en el mismo turno en el que usas tu reacción normal.", effects = {} },
        { id = "pic_esquivo", icon = "ability_rogue_feint", level = 18, name = "Esquivo", type = "informativo", description = "A partir de nivel 18, eres tan escurridizo que será raro que un atacante pueda tomar el control de la situación. Ninguna tirada de ataque hecha contra ti tendrá ventaja mientras no estés incapacitado.", effects = {} },
        { id = "pic_golpe_de_suerte", icon = "inv_misc_coin_02", level = 20, name = "Golpe de Suerte", type = "informativo", description = "A nivel 20 has desarrollado una capacidad asombrosa para tener éxito justo cuando lo necesitas. Si fallas al atacar a un objetivo dentro del alcance, puedes transformar el fa llo en un impacto. También puedes emplear este rasgo para, si fallas al hacer una prueba de caracte rística, considerar el resultado de la tirada del d20 como un 20. Una vez utilizado este rasgo, deberás terminar un descanso corto o largo para poder volver a usarlo otra vez.", effects = {} },
    },
}
