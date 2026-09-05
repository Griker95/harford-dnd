-- Chaman: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects
local ManeuverEffects = API.ManeuverEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "chaman", name = "Chaman", nameF = "Chamana", desc = "Pacta con los elementos en vez de mandarlos: rayo, agua y tierra, tótems plantados y armas encantadas.", hitDie = 8, casterType = "full", startingGold = { dice = 5, sides = 4, multiplier = 1 },
    -- Idioma que concede la clase (rasgo de nivel 1 del manual).
    languages = { "Kalimag" },
    -- Herramientas de clase segun el manual.
    toolProfs = { "Kit de herborista" },
    startingEquipment = {
        { label = "Armadura",
            options = {
            { label = "Armadura de pieles", items = { "Pieles" } },
            { label = "Armadura de cuero", items = { "Cuero" } },
        } },
        { label = "Arma principal",
            options = {
            { label = "Una maza y un escudo", items = { "Maza", "Escudo" } },
            { label = "Dos armas simples", items = { { pick = "Simple" }, { pick = "Simple" } } },
        } },
        { label = "Paquete",
            fixed = { "Foco druidico" },
            options = {
            { label = "Paquete de aventurero", items = { "Paquete de aventurero" } },
            { label = "Paquete de explorador", items = { "Paquete de explorador" } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Animales", "Arcano", "Historia", "Perspicacia", "Medicina", "Naturaleza",
        "Percepcion", "Supervivencia" },
    saves = { "Fuerza", "Sabiduria" },
    armorProfs = { "ligera", "media", "escudo" },
    weaponProfs = { "sencillas" },
    -- Seccion "Multiclase" del manual: al ENTRAR en la clase (no siendo la inicial).
    multiclass = { minimums = { { "Sabiduria" } },
        armorProfs = { "ligera", "media", "escudo" }, weaponProfs = { "sencillas" } },
    subclasses = {
        { id = "elemental", name = "Elemental", desc = "Desata rayos, fuego y tierra contra el enemigo a distancia.", features = {
            { id = "cha_ele_poder", level = 3, name = "Poder totemico: Mente tranquila", type = "informativo", cast = "reaccion", description = "Puedes activar el tótem cuando una criatura a 4,5 metros de él se vea obligada a realizar una tirada de salvación de Constitución para mantener la concentración, otorgándole ventaja en la tirada.", effects = {} },
            { id = "cha_ele_furia", level = 3, name = "Furia elemental", cast = "ninguna", type = "accion", actionKind = "elementalFury", description = "Al lanzar un conjuro de daño elemental (acido/frío/fuego/rayo/trueno) puedes cambiar su tipo por otro de la lista. El boton elige el tipo al que conviertes; se aplica a cada conjuro elemental hasta que lo cambies o lo apagues.", effects = {} },
            { id = "cha_ele_vinculo_aire_3", level = 3, name = "Conjuros de vinculo (Aire)", type = "informativo", description = "Por tu Afinidad Elemental de Aire aprendes Diablo de polvo y Viento guardian. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "aire", grantedSpells = { "diablo_de_polvo", "viento_guardian" }, requiresOption = "aire", spellGrants = { { level = 2, ids = { "diablo_de_polvo", "viento_guardian" } } }, effects = {} },
            { id = "cha_ele_vinculo_aire_5", level = 5, name = "Conjuros de vinculo (Aire)", type = "informativo", description = "Por tu Afinidad Elemental de Aire aprendes Llamar al relampago y Muro de viento. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "aire", grantedSpells = { "llamar_al_relampago", "muro_de_viento" }, requiresOption = "aire", spellGrants = { { level = 3, ids = { "llamar_al_relampago", "muro_de_viento" } } }, effects = {} },
            { id = "cha_ele_vinculo_tierra_3", level = 3, name = "Conjuros de vinculo (Tierra)", type = "informativo", description = "Por tu Afinidad Elemental de Tierra aprendes Puno terrestre de Maximiliano y Hacer anicos. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "tierra", grantedSpells = { "puno_terrestre_de_maximiliano", "hacer_anicos" }, requiresOption = "tierra", spellGrants = { { level = 2, ids = { "puno_terrestre_de_maximiliano", "hacer_anicos" } } }, effects = {} },
            { id = "cha_ele_vinculo_tierra_5", level = 5, name = "Conjuros de vinculo (Tierra)", type = "informativo", description = "Por tu Afinidad Elemental de Tierra aprendes Pua terrestre y Tierra en erupcion. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "tierra", grantedSpells = { "pua_terrestre", "tierra_en_erupcion" }, requiresOption = "tierra", spellGrants = { { level = 3, ids = { "pua_terrestre", "tierra_en_erupcion" } } }, effects = {} },
            { id = "cha_ele_vinculo_fuego_3", level = 3, name = "Conjuros de vinculo (Fuego)", type = "informativo", description = "Por tu Afinidad Elemental de Fuego aprendes Calentar metal y Rafaga de lava. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "fuego", grantedSpells = { "calentar_metal", "erupcion_de_lava" }, requiresOption = "fuego", spellGrants = { { level = 2, ids = { "calentar_metal", "erupcion_de_lava" } } }, effects = {} },
            { id = "cha_ele_vinculo_fuego_5", level = 5, name = "Conjuros de vinculo (Fuego)", type = "informativo", description = "Por tu Afinidad Elemental de Fuego aprendes Luz del dia y Meteoros menores de Melf. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "fuego", grantedSpells = { "luz_del_dia", "meteoros_menores_de_melf" }, requiresOption = "fuego", spellGrants = { { level = 3, ids = { "luz_del_dia", "meteoros_menores_de_melf" } } }, effects = {} },
            { id = "cha_ele_vinculo_agua_3", level = 3, name = "Conjuros de vinculo (Agua)", type = "informativo", description = "Por tu Afinidad Elemental de Agua aprendes Auxilio y Restablecimiento menor. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "agua", grantedSpells = { "auxilio", "restablecimiento_menor" }, requiresOption = "agua", spellGrants = { { level = 2, ids = { "auxilio", "restablecimiento_menor" } } }, effects = {} },
            { id = "cha_ele_vinculo_agua_5", level = 5, name = "Conjuros de vinculo (Agua)", type = "informativo", description = "Por tu Afinidad Elemental de Agua aprendes Cadena de curacion y Muro de agua. Cuentan como conjuros de chaman pero NO cuentan contra tus conjuros conocidos, y no se pueden reemplazar.", requiresOption = "agua", grantedSpells = { "cadena_de_curacion", "muro_de_agua" }, requiresOption = "agua", spellGrants = { { level = 3, ids = { "cadena_de_curacion", "muro_de_agua" } } }, effects = {} },
            { id = "cha_ele_eco", level = 6, name = "Eco de los elementos", type = "informativo", description = "A nivel 6, cuando lances un conjuro de chamán que cause daño, puedes volver a tirar un número de dados de daño hasta Mod. Sabiduría y usar cualquiera de los resultados.\n\nPuedes usar esta característica un número de veces igual a Mod. Sabiduría. Recuperas los usos gastados al finalizar un descanso largo.", uses = { ability = "Sabiduria", min = 1, recharge = "long" }, effects = {} },
        } },
        { id = "mejora", name = "Mejora", desc = "Imbuye sus armas con los elementos para el cuerpo a cuerpo.", casterType = "half", features = {
            { id = "cha_mej_poder", level = 3, name = "Poder totemico: Furia del viento", type = "informativo", cast = "reaccion", description = "Puedes activar este tótem cuando una criatura a 4,5 metros de él falle un ataque con un arma cuerpo a cuerpo; esa criatura puede intentar el mismo ataque con el arma de inmediato contra el objetivo.", effects = {} },
            { id = "cha_mej_competencia", level = 3, name = "Competencia adicional (armas marciales)", type = "pasivo", description = "A nivel 3, obtienes competencia con armas marciales y puedes usar un arma simple o marcial como enfoque para lanzar tus conjuros de chamán.", effects = WeaponProfEffects("marciales") },
            { id = "cha_mej_llamado_marcial", level = 3, name = "Llamado marcial", type = "pasivo", description = "A partir del nivel 3, consulta la tabla de Lanzamiento de Conjuros de Mejora para determinar tus conjuros truco, conjuros conocidos y espacios de conjuro cada vez que subas de nivel en esta clase. También cuentas como *medio lanzador* para determinar los espacios de conjuro disponibles cuando multiclaseas con otras clases.", effects = {} },
            { id = "cha_mej_torbellino", level = 3, name = "Torbellino", type = "pasivo", description = "También a nivel 3, puedes aprovechar las fuerzas del torbellino y canalizarlas en tus armas.\n\n***Puntos de torbellino.*** Tienes un número de puntos de torbellino igual a la mitad de tu nivel de chamán (redondeado hacia arriba). Puedes gastar estos puntos para potenciar diversos ataques con armas. Cuando gastas un punto de torbellino, no está disponible hasta que completes un descanso corto o largo, al final del cual recuperas todos los puntos de torbellino gastados.\n\n***Ataques con armas.*** Conoces dos ataques con armas de tu elección, que se detallan a continuación en \"Ataques con Armas\". Los ataques con armas mejoran un ataque de alguna manera. Solo puedes usar un ataque por cada ataque, salvo que se indique lo contrario.\n\nAprendes un ataque con armas adicional de tu elección a nivel 7, 11 y 15. Cada vez que aprendas un nuevo ataque, puedes reemplazar uno que conozcas por otro diferente.\n\n***Tiradas de salvación.*** Algunos de tus ataques requieren que tu objetivo haga una tirada de salvación para resistir el efecto. La CD de la tirada de salvación es igual a tu CD de salvación de conjuros.", effects = {
                { kind = "resourceMax", resource = "maelstrom", perClassLevel = "chaman", values = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10 } },
            } },
            { id = "cha_mej_ataques_3", level = 3, name = "Ataques con armas conocidos", actionKind = "optionAbility", bookHidden = true, type = "choice", description = "Conoces dos ataques con armas a tu eleccion; aprendes mas a los niveles 7, 11 y 15. La CD de sus salvaciones es la de tus conjuros.", effects = {}, choice = {
            slots = 2,
            options = {
                { id = "golpe_roca", icon = "spell_nature_earthshock", label = "Golpe de Roca", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para obligarla a una salvacion de Fuerza. Si falla, es empujada 4,6 metros directamente lejos de ti.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Fuerza", outcome = "empujado 4,6 metros" } },
                { id = "mordida_roca", icon = "spell_nature_rockbiter", label = "Mordida de Roca", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para intentar un golpe que derriba. Salvacion de Fuerza o cae derribado.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Fuerza", outcome = "Derribado", onFailAura = 267937, conditionId = "prone" } },
                { id = "golpe_tormenta", icon = "spell_holy_sealofmight", label = "Golpe de Tormenta", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para descargar un rayo. Salvacion de Constitucion o no podra tomar reacciones hasta el inicio de tu proximo turno.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Constitucion", outcome = "sin reacciones" } },
                { id = "marca_hielo", icon = "spell_frost_frostbrand", label = "Marca de Hielo", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para intentar una marca helada. Salvacion de Constitucion o tendra desventaja en ataques hasta el final de su proximo turno.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Constitucion", outcome = "desventaja en ataques", onFailAura = 287295, conditionId = "chilled" } },
                { id = "latigo_elemental", icon = "spell_shaman_unleashweapon_flame", label = "Latigo Elemental", resourceKey = "maelstrom", resourceCost = 1, desc = "Cuando golpeas con un ataque con arma, gastas 1 punto de torbellino para azotar a otra criatura a 4,6 metros de ella. Salvacion de Destreza o recibe 1d10 del tipo de dano de tu Afinidad Elemental.", maneuver = { cost = 1, attack = true, spendOnHit = true, save = "Destreza", outcome = "azotado por los elementos", damageDie = 10 } },
                { id = "golpe_torbellino", icon = "spell_nature_cyclone", label = "Golpe de Torbellino", resourceKey = "maelstrom", resourceCost = 1, desc = "Al realizar la accion de ataque, gastas 1 punto de torbellino para que todos tus ataques con arma cuenten como magicos hasta el final de tu turno. Combinable con otro ataque con armas.", maneuver = { cost = 1, attack = true, spendOnHit = true } },
                { id = "golpe_impactante", icon = "spell_shaman_unleashweapon_wind", label = "Golpe Impactante", resourceKey = "maelstrom", resourceCost = 3, requiresLevel = 7, desc = "Cuando golpeas con un ataque con arma, gastas 3 puntos de torbellino para intentar un golpe impactante. Salvacion de Constitucion o queda incapacitada hasta el inicio de tu proximo turno.", maneuver = { cost = 3, attack = true, spendOnHit = true, save = "Constitucion", outcome = "Incapacitado", conditionId = "incapacitated" } },
            } } },
            -- `cast = "ninguna"` A PROPOSITO: es un dano condicional conmutable (como Golpe Runico) y quien
            -- paga la accion es el ATAQUE que lo consume. Sin declararlo, la deduccion de "maniobra =
            -- accion" cobraria una accion por darle al conmutador, o sea dos por el mismo golpe.
            { id = "cha_mej_golpe_elemental", level = 3, name = "Golpe elemental", type = "maniobra", cast = "ninguna", description = "Cuando realices la acción de ataque, puedes gastar 1 punto de torbellino para envolver tus ataques en el elemento de tu Afinidad Elemental hasta el final de tu turno. Cada ataque inflige 1d4 de daño adicional del tipo de tu afinidad elemental si golpea. Eliges el tipo de daño de tu Afinidad Elemental cuando activas este ataque.\n\nPuedes usar Golpe Elemental en combinación con otro ataque al realizar un ataque.", effects = {
            { kind = "conditionalWeaponDamage", id = "shaman_elemental_strike", label = "Golpe elemental", count = 1, die = 4, resourceCost = "maelstrom", costPerLevel = 1, minLevel = 1, maxLevel = 1 },
            } },
            { id = "cha_mej_ataque_adicional", level = 6, name = "Ataque adicional", type = "pasivo", description = "A partir del nivel 6, puedes atacar dos veces, en lugar de una, cuando realices la acción de ataque en tu turno.", effects = {
                { kind = "flag", flag = "extraAttack" },
            } },
        } },
        { id = "restauracion", name = "Restauracion", desc = "Sanacion y apoyo mediante totems y aguas curativas.", features = {
            { id = "cha_res_poder", level = 3, name = "Poder totemico: Marea viva", type = "informativo", cast = "reaccion", description = "Puedes activar este tótem cuando una criatura a 4,5 metros de él lanza un conjuro o usa una habilidad que restaura puntos de golpe, causando que el tótem irradie una marea viva hacia una criatura de tu elección a 4,5 metros de él. Esa criatura recupera puntos de golpe iguales a Mod. Sabiduría.", effects = {} },
            { id = "cha_res_guia", level = 3, name = "Guia ancestral", type = "informativo", description = "A partir del nivel 3, tus conjuros restaurativos son guiados por la mano de tus ancestros. Siempre que uses un conjuro de nivel 1 o superior para restaurar puntos de golpe a una criatura y saques un 1 o un 2 al lanzar el dado, puedes volver a tirar el dado y debes usar el nuevo resultado, incluso si es otro 1 o 2.", effects = { { kind = "flag", flag = "ancestralGuidance" } } },
            { id = "cha_res_fuerzas", level = 6, name = "Fuerzas anuladoras", type = "informativo", description = "A nivel 6, puedes canalizar los elementos para interrumpir el trabajo de los conjuros de otros. Cuando lanzas un conjuro que tiene como objetivo una criatura aliada, también puedes intentar poner fin a un efecto de conjuro que la esté afectando. Si el nivel de espacio de conjuro del efecto es igual o menor que el nivel del conjuro que lanzas, el efecto termina. De lo contrario, debes realizar un chequeo de Sabiduría (CD 10 + el nivel del conjuro) para intentar ponerle fin.\n\nPuedes usar esta característica dos veces. Recuperas los usos gastados al finalizar un descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
        } },
    },
    features = {
        { id = "cha_kalimag", level = 1, name = "Kalimag", type = "informativo", description = "Conoces Kalimag, el idioma de los elementales. Puedes hablar el idioma y usarlo para dejar mensajes en rocas y charcas de agua que solo tú y otros chamanes pueden notar. Los mensajes se transmiten como si fuera un conjuro de *mensaje*, con las limitaciones de dicho conjuro.", effects = { { kind = "language", language = "Kalimag" } } },
        { id = "cha_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "pasivo", description = "Al conectarte con los elementos, puedes manifestar su poder mediante conjuros. Consulta [las reglas generales de lanzamiento de conjuros](reglas.html#conjuros); la lista de conjuros del chamán está al final de esta ficha.\n\n### Conjuros truco\nConoces dos conjuros truco de tu elección de la lista de conjuros del chamán. Aprendes más conjuros truco adicionales a niveles superiores, como se muestra en la columna de Conjuros Conocidos de la tabla del Chamán.\n\n### Espacios de conjuro la tabla del Chamán muestra cuántos espacios de conjuro tienes para lanzar tus conjuros de nivel 1 o superior. Para lanzar uno de estos conjuros, debes gastar un espacio de conjuro del nivel correspondiente o superior. Recuperas todos los espacios de conjuro gastados al finalizar un descanso largo.\n\n### Conjuros conocidos de nivel 1 o superior\nConoces cuatro conjuros de nivel 1 de tu elección de la lista de conjuros del chamán.\n\nLa columna de Conjuros Conocidos de la tabla del Chamán muestra cuándo aprendes más conjuros de tu elección. Cada uno de estos conjuros debe ser de un nivel para el que tengas espacios de conjuro. Por ejemplo, cuando alcanzas el nivel 3 en esta clase, aprendes un nuevo conjuro de nivel 1 o 2.\n\nAdemás, cuando subes de nivel en esta clase, puedes elegir uno de los conjuros de chamán que conoces y reemplazarlo por otro conjuro de la lista del chamán, que también debe ser de un nivel para el que tengas espacios de conjuro.\n\n### Habilidad para lanzar conjuros\nLa Sabiduría es tu habilidad para lanzar conjuros de chamán, ya que tu poder proviene de los elementos y los espíritus. Usas tu Sabiduría siempre que un conjuro de chamán haga referencia a tu habilidad para lanzar conjuros. Además, utilizas Mod. Sabiduría para establecer la CD de salvación de los conjuros de chamán que lanzas y al hacer una tirada de ataque con uno.\n\n**CD de salvación de conjuro** = 8 + Bonus Competencia + Mod. Sabiduría\n\n**Bonificador de ataque de conjuro** = Bonus Competencia + Mod. Sabiduría\n\n### Lanzamiento ritual\nPuedes lanzar un conjuro de chamán que conozcas como ritual si ese conjuro tiene la etiqueta de ritual.\n\n### Enfoque para lanzar conjuros\nPuedes usar un enfoque druídico como enfoque para lanzar tus conjuros de chamán.", effects = {} },
        { id = "cha_totemista", level = 2, name = "Totemista", cast = "accion_adicional", type = "recurso", description = "A partir del nivel 2, puedes usar tu acción adicional para canalizar fuerzas elementales en un tótem Pequeño en un espacio vacío sobre una superficie horizontal a 4,5 metros de ti.\n\nEl tótem es un objeto mágico que ocupa su espacio. Tiene una CA de 15 y un número de puntos de golpe igual al doble de tu nivel de chamán. Es inmune al daño por veneno, daño psíquico y a todas las condiciones. Si se ve obligado a realizar un chequeo de característica o una tirada de salvación, todos sus valores de característica son 10 (+0). El tótem desaparece si se reduce a 0 puntos de golpe o tras 1 minuto. Puedes disiparlo antes como una acción adicional.\n\nPuedes usar tu reacción para hacer que el tótem se active si estás a 18 metros de él y elijes uno de sus poderes para que surta efecto. Tu tótem comienza con dos de estos poderes: Resistencia Elemental y un poder determinado por tu Afinidad Elemental. Tu tótem gana un poder adicional al nivel 3, determinado por tu vínculo chamánico.\n\nPuedes usar tu característica de Totemista dos veces entre descansos. Recuperas todos los usos gastados al finalizar un descanso corto o largo. Puedes invocar un tótem adicional entre descansos al alcanzar el nivel 10, y nuevamente al nivel 18.\n\n***Poder totémico: Resistencia elemental.*** Puedes activar el tótem cuando una criatura a 4,5 metros de él reciba daño de ácido, frío, fuego, rayo o trueno, otorgándoles resistencia a ese tipo de daño hasta el final de su siguiente turno.", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "cha_totem_resistencia", level = 2, name = "Poder totemico: Resistencia Elemental", type = "informativo", cast = "reaccion", description = "Activas el tótem cuando una criatura a 4,5 metros de el reciba daño de ácido, frío, fuego, rayo o trueno, otorgándole resistencia a ese tipo de daño hasta el final de su siguiente turno. Este poder lo tiene el tótem siempre.", effects = {} },
            { id = "cha_totem_aire", level = 2, name = "Poder totemico: Gracia del Aire", type = "informativo", cast = "reaccion", requiresOption = "aire", description = "Por tu Afinidad Elemental de Aire: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Destreza, otorgandole ventaja en su tirada.", effects = {} },
            { id = "cha_totem_tierra", level = 2, name = "Poder totemico: Fuerza de la Tierra", type = "informativo", cast = "reaccion", requiresOption = "tierra", description = "Por tu Afinidad Elemental de Tierra: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Fuerza, otorgandole ventaja en su tirada.", effects = {} },
            { id = "cha_totem_fuego", level = 2, name = "Poder totemico: Lengua de Fuego", type = "informativo", cast = "reaccion", requiresOption = "fuego", description = "Por tu Afinidad Elemental de Fuego: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Carisma, otorgandole ventaja en su tirada.", effects = {} },
            { id = "cha_totem_agua", level = 2, name = "Poder totemico: Corriente Purificadora", type = "informativo", cast = "reaccion", requiresOption = "agua", description = "Por tu Afinidad Elemental de Agua: activas el totem cuando una criatura a 4,6 metros de el realice un chequeo o tirada de salvacion de Sabiduria, otorgandole ventaja en su tirada.", effects = {} },
        { id = "cha_afinidad_elemental", level = 2, name = "Afinidad elemental", type = "choice", description = "Te sintonizas con un elemento.", effects = {}, choice = {
            slots = 1,
            options = {
                { id = "aire", icon = "spell_nature_earthbind",  label = "Aire (+1,5 m de velocidad, +comp a iniciativa)", effects = { { kind = "flag", flag = "initiativeProfBonus" }, { kind = "bonus", target = "speed", value = 1.5 } } },
                { id = "tierra", icon = "spell_nature_stoneskintotem", label = "Tierra (competencia en salvacion de Constitucion)", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                { id = "fuego", label = "Fuego (+comp de daño por fuego, 1/turno)", effects = { { kind = "conditionalWeaponDamage", id = "shaman_fire_affinity", label = "Afinidad Fuego", flatBonus = "pb", damageType = "fuego" } } },
                { id = "agua", icon = "spell_frost_summonwaterelemental",  label = "Agua (conjuros conocidos extra)",          effects = {} },
            },
        } },
        { id = "cha_vinculo", subclassMarker = true, level = 3, name = "Vinculo chamanico", type = "informativo", description = "A nivel 3, eliges un vínculo chamánico que define tu enfoque hacia las fuerzas de los elementos. Elige entre Elemental, Mejora o Restauración, cada uno de los cuales se detalla al final de la descripción de la clase. Tu elección te otorga características al nivel 3 y nuevamente al 6.º, 14.º y 20.º nivel.", effects = {} },
        ASI("chaman", 4),
        { id = "cha_bestia_espiritual", level = 5, name = "Bestia espiritual", cast = "accion", type = "accion", description = "A nivel 5, obtienes el favor de una bestia espiritual y eres capaz de asumir su apariencia espectral. Elige una bestia Mediana o Pequeña que no tenga velocidad de vuelo o nado para representar tu espíritu.\n\nPuedes usar tu acción para asumir la apariencia ilusoria de tu bestia espiritual. Esta apariencia no afecta a tus estadísticas de juego, excepto que cambia tu velocidad de movimiento a 15 metros.\n\nPermaneces transformado hasta que lances un conjuro, realices un ataque o uses tu acción adicional para regresar a tu forma original.", effects = {
            { kind = "toggleState", state = "spirit_beast", label = "Bestia espiritual", description = "Apariencia espectral activa: tu velocidad es 15 m." },
            { kind = "speedOverride", value = 15, requiresState = "spirit_beast" },
        } },
    },
}

-- Rasgos generados a partir de los Ataques con Armas elegidos (Chaman, Mejora). Mismo patron que
-- las maniobras del Guerrero: la opcion elegida se convierte en un rasgo real y ejecutable.
do
    local clase = API.GetClass and API.GetClass("chaman")
    local sub
    for _, sc in ipairs((clase and clase.subclasses) or {}) do
        if sc.id == "mejora" then sub = sc break end
    end
    local eleccion
    for _, f in ipairs((sub and sub.features) or {}) do
        if f.id == "cha_mej_ataques_3" then eleccion = f break end
    end
    for _, opcion in ipairs((eleccion and eleccion.choice and eleccion.choice.options) or {}) do
        sub.features[#sub.features + 1] = {
            id = "cha_mej_atq_" .. tostring(opcion.id),
            icon = opcion.icon,
            level = tonumber(opcion.requiresLevel) or 3,
            name = opcion.label,
            type = "maniobra",
            description = opcion.desc,
            requiresOption = opcion.id,
            effects = ManeuverEffects(opcion, "maelstrom"),
        }
    end
end
