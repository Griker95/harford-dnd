-- Picaro: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "picaro", name = "Picaro", desc = "Maestro del sigilo, las trampas y el ataque furtivo que prospera con astucia y precision.", hitDie = 8, startingGold = { dice = 4, sides = 4, multiplier = 1 },
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
            { id = "pic_for_alacridad", level = 3, name = "Alacridad", type = "pasivo", description = "Sumas tu Mod. Carisma a la iniciativa; al atacar cuerpo a cuerpo, ese objetivo no puede hacerte ataques de oportunidad el resto del turno.", effects = {
                { kind = "initiativeAbility", ability = "Carisma" },
            } },
        } },
        { id = "sutileza", name = "Sutileza", desc = "Sigilo extremo y ataques furtivos precisos.", casterType = "third", expandedSpells = { "Resguardo contra las hojas", "Hoja retumbante", "Amistad", "Rafaga", "Mano de mago", "Mensaje", "Ilusion menor", "Prestidigitacion", "Rompante de espadas" }, features = {
            { id = "pic_sut_conjuracion", level = 3, name = "Conjuracion", type = "pasivo", description = "Aprendes magia de sombras (trucos + hechizos). Inteligencia es tu habilidad de conjuro: CD = 8 + comp + Mod. Inteligencia.", effects = {} },
            { id = "pic_sut_vista", level = 3, name = "Vista de penumbra", type = "pasivo", description = "Visión en la oscuridad 60 pies (o +30 si ya la tienes por raza).", effects = {} },
        } },
    },
    features = {
        { id = "pic_pericia", level = 1, name = "Pericia", type = "choice", description = "Elige 2 competencias para duplicar su bonus de competencia.", effects = {}, choice = {
            slots = 2, optionsFrom = "skillExpertise",
        } },
        { id = "pic_ataque_furtivo", level = 1, name = "Ataque furtivo", type = "pasivo", description = "Una vez por turno, +1d6 de daño (sube con nivel) a una criatura si tienes ventaja o un aliado adyacente, con arma ligera/precision/distancia.", effects = {
            { kind = "conditionalWeaponDamage", id = "sneak", label = "Ataque Furtivo", die = 6, perTwoClassLevels = "picaro" },
        } },
        { id = "pic_misivas", level = 1, name = "Misivas secretas", type = "pasivo", description = "Ocultas mensajes e ideas en conversaciones y cartas mediante jerga y códigos.", effects = {} },
        { id = "pic_energia", level = 2, name = "Energia", type = "pasivo", description = "Puntos de energía (según la tabla) para maniobras (Mutilar, Exponer Armadura, Garrote). CD de Energía = 8 + comp + Mod. Destreza. Recargan en descanso.", effects = {
            { kind = "resourceMax", resource = "energy", perClassLevel = "picaro",
              values = { 0, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
        } },
        { id = "pic_mutilar", level = 2, name = "Mutilar", type = "maniobra", description = "Tras impactar a una criatura con la acción de Ataque, gastas 1 punto de energía: el objetivo supera una salvación de Fuerza (CD de Energía) o queda derribado.", effects = {
            { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Fuerza", outcome = "Derribado", dcAbility = "Destreza", onFailAura = 267937, conditionId = "prone" },
        } },
        { id = "pic_exponer_armadura", level = 2, name = "Exponer armadura", cast = "accion", type = "maniobra", description = "Acción: gastas 1 punto de energía y haces un ataque especial con arma. Si aciertas, infliges daño normal y expones fallos en su defensa: cada otra criatura tiene ventaja en su primera tirada de ataque con arma contra el objetivo antes del final de tu siguiente turno.", effects = {
            { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, onHitAura = 11971, conditionId = "exposed_armor", conditionDuration = "source_turn_end", conditionTurns = 2 },
        } },
        { id = "pic_garrote", level = 2, name = "Garrote", type = "maniobra", description = "Tras impactar a una criatura con un ataque cuerpo a cuerpo, gastas 1 punto de energía: el objetivo supera una salvación de Constitución (CD de Energía) o no puede hablar hasta el final de tu siguiente turno.", effects = {
            { kind = "energyManeuver", resource = "energy", cost = 1, spendOnHit = true, attack = true, save = "Constitucion", outcome = "Silenciado", dcAbility = "Destreza", onFailAura = 30900, conditionId = "silenced", conditionDuration = "source_turn_end", conditionTurns = 2 },
        } },
        { id = "pic_accion_astuta", level = 2, name = "Accion astuta", type = "informativo", grantsAsBonus = { "correr", "desengancharse", "esconderse" }, description = "Acción adicional cada turno solo para Correr, Desengancharse o Esconderse.", effects = {} },
        { id = "pic_arquetipo", level = 3, name = "Arquetipo de Picaro", type = "informativo", description = "Eliges tu arquetipo (Asesino, Forajido o Sutileza). Concede rasgos en niveles 3, 9, 13 y 17.", effects = {} },
        ASI("picaro", 4),
        { id = "pic_esquiva_sobrenatural", level = 5, name = "Esquiva sobrenatural", type = "informativo", cast = "reaccion", reactionTrigger = "damage_taken", reactionEffect = "half_damage", description = "Reacción al recibir un ataque de un atacante visible: reduces el daño a la mitad.", effects = {} },
        { id = "pic_pericia_6", level = 6, name = "Pericia", type = "choice", description = "Elige 2 competencias mas para duplicar su bonus de competencia.", effects = {}, choice = {
            slots = 2, optionsFrom = "skillExpertise",
        } },
                { id = "pic_evasion", level = 7, name = "Evasión", type = "informativo", description = "A nivel 7 tu agilidad instintiva te da opción de evitar ciertos efectos de área, como el aliento de relámpago de un dragón o un conjuro de _bolá de fuego._ Cua ndo seas víctima de un efecto que te permita hacer una tirada de salvación de Destreza para recibir solo la mitad del daño, no recibirás daño alguno si tienes éxito en la tirada de salvación y solo la mitad si la fallas.", effects = {} },
        { id = "pic_anticipacion", level = 15, name = "Anticipación", type = "informativo", description = "A nivel 15 has adquirido una fortaleza mental considerable. Ganas competencia en las tiradas de salvación de Sabiduría.", effects = {} },
        { id = "pic_esquivo", level = 18, name = "Esquivo", type = "informativo", description = "A partir de nivel 18, eres tan escurrid izo que será raro que un atacante pueda tomar el control de la situación. Ninguna tirada de ataque hecha contra ti tendrá ventaja mientras no estés incapacitado.", effects = {} },
        { id = "pic_golpe_de_suerte", level = 20, name = "Golpe de Suerte", type = "informativo", description = "A nivel 20 h as desarrollado una capacidad asombrosa para tener éxito justo c uando lo necesitas. Si fallas al atacar a un objetivo dentro del alcance, puedes transformar el fa llo en un impacto. También puedes emplear este rasgo para, si fallas al hacer una prueba de caracte rística, considerar el resultado de la tirada del d20 como un 20. Una vez utilizado este rasgo, deberás terminar un descanso corto o largo para poder volver a usarlo otra vez.", effects = {} },
    },
}
