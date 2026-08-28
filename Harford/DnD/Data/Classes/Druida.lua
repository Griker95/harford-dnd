-- Druida: datos de clase para HarfordDnDBook.
-- Generado al separar el libro por clases; el nucleo (HarfordDnDBook.lua) carga antes
-- y aporta API.CLASSES, API.ASI y API.WeaponProfEffects.

local API = HarfordDnDBook
local ASI, WeaponProfEffects = API.ASI, API.WeaponProfEffects

API.CLASSES[#API.CLASSES + 1] =
{
    id = "druida", name = "Druida", desc = "Guardian de la naturaleza capaz de adoptar formas animales y lanzar magia primigenia de equilibrio, fiereza o restauración.", hitDie = 8, casterType = "full", startingGold = { dice = 2, sides = 4, multiplier = 1 },
    -- Herramientas de clase segun el manual.
    toolProfs = { "Kit de herborista" },
    startingEquipment = {
        { label = "Arma principal",
            options = {
            { label = "Un baston", items = { "Bastón" } },
            { label = "Cualquier arma simple", items = { { pick = "Simple" } } },
        } },
        { label = "Arma secundaria",
            fixed = { "Cuero", "Paquete de explorador", "Foco druidico" },
            options = {
            { label = "Una daga", items = { "Daga" } },
            { label = "Cualquier arma simple", items = { { pick = "Simple" } } },
        } },
    },
    -- Habilidades de clase segun el manual.
    skillChoices = 2,
    skillOptions = { "Arcano", "Animales", "Perspicacia", "Medicina", "Naturaleza", "Percepcion",
        "Religion", "Supervivencia" },
    saves = { "Inteligencia", "Sabiduria" },
    armorProfs = { "ligera" },
    weaponProfs = { "sencillas" },
    subclasses = {
        { id = "equilibrio", name = "Equilibrio", desc = "Magia lunar y solar que castiga al enemigo a distancia.", features = {
            { id = "dru_eq_conjuros_camino", level = 3, name = "Conjuros del camino", type = "informativo", grantedSpells = { "potenciar_caracteristica", "rayo_de_luna" }, description = "Nivel 3 del Camino del Equilibrio: Potenciar caracteristica (habilidad mejorada) y Rayo de luna. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar.", effects = {} },
            { id = "dru_eq_conjuros_camino_5", level = 5, name = "Conjuros del camino", type = "informativo", grantedSpells = { "luz_del_dia" }, description = "Nivel 5 del Camino del Equilibrio: Luz del dia. Estallido estelar es contenido propio de Warcraft y todavia no esta en el compendio, asi que se juega a mano. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar.", effects = {} },
            { id = "dru_eq_invocar", level = 2, name = "Invocar", type = "informativo", description = "En un descanso corto recuperas espacios de conjuro (nivel combinado <= mitad de tu nivel de druida, ninguno de 6+). 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            { id = "dru_eq_fuerza_naturaleza", level = 6, name = "Fuerza de la naturaleza", type = "informativo", description = "Al lanzar un conjuro de un solo objetivo, infliges daño extra o curas igual a tu nivel de druida. 2 usos por descanso largo.", uses = { max = 2, recharge = "long" }, effects = {} },
                        { id = "dru_eq_influencia_astral", level = 10, name = "Influencia Astral", type = "informativo", description = "Al alcanzar el 10º nivel, encuentras consuelo y poder en la diosa Elune, obteniendo las siguientes características. - Ganas resistencia al daño radiante. - Puedes elegir infligir daño radiante con tu característica Fuerza de la Naturaleza, en lugar del tipo de daño del conjuro. - Tienes ventaja en las pruebas y tiradas de salvación para evitar ser encantado o asustado por efectos de conjuros.", effects = {} },
            { id = "dru_eq_bendicion_de_los_ancestros", level = 14, name = "Bendición de los Ancestros", type = "informativo", description = "A partir del 14º nivel, equilibras las dos fuerzas del mundo. Siempre que terminas un descanso corto o largo, puedes elegir *an'she* o *elune* y obtener los beneficios del equilibrio elegido hasta que termines tu próximo descanso. ***An'she.*** Siempre estás bajo los efectos de un conjuro de *ver lo invisible*. Además, eres inmune a la ceguera y cuando se hace un ataque cuerpo a cuerpo contra ti, puedes usar tu reacción para imponer desventaja en la tirada de ataque. ***Elune.*** Obtienes visión en la oscuridad con un alcance de 18,3 metros. Si ya tienes visión en la oscuridad debido a tu raza, su alcance aumenta en 9,1 metros. Además, mientras estés en penumbra u oscuridad, puedes usar tu reacción para obtener ventaja en tus ataques de hechizo hasta el final de tu turno.", effects = {} },
            { id = "dru_eq_encarnacion_elegido_de_elune", level = 20, name = "Encarnación: Elegido de Elune", type = "informativo", description = "En el nivel 20, has sido elegido por Elune y puedes dejar que sus poderes fluyan a través de ti, tomando una apariencia según tu elección. Por ejemplo, los colores y las estrellas de Elune podrían moverse por tu piel, tu forma de luniscente podría brillar con una luz tenue azulada, o podrías tener una luna creciente flotando sobre tu cabeza. Puedes usar tu acción para asumir tu forma de luniscente y permitir que los poderes de la diosa fluyan a través de ti. Durante 1 minuto, obtienes los siguientes beneficios: - Puedes usar un espacio de conjuro para lanzar el hechizo *rayo de luna*, incluso si no lo tienes preparado, y puedes mover el rayo como una acción adicional. - El alcance de cualquier hechizo de druida que lances se duplica, y cualquier hechizo de druida con un alcance de toque tiene un alcance de 9,1 metros.", effects = {} },
        } },
        { id = "feral", name = "Feral", desc = "Forma de fiera con garras y sigilo depredador.", casterType = "half", features = {
            { id = "dru_fer_adaptacion", level = 2, name = "Adaptacion salvaje", type = "choice", description = "Ganas competencia en salvaciones de Destreza o Constitución (además de las del druida). Cuentas como medio lanzador (tabla Feral).", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "destreza",     label = "Salvacion de Destreza",     effects = { { kind = "saveProf", ability = "Destreza" } } },
                    { id = "constitucion", label = "Salvacion de Constitucion", effects = { { kind = "saveProf", ability = "Constitucion" } } },
                },
            } },
            { id = "dru_fer_marca_ursol", level = 2, name = "Marca de ursol", type = "informativo", description = "Puedes lanzar conjuros mientras estas transformado (ignoras componentes V/S y materiales sin coste). 2 usos por descanso.", uses = { max = 2, recharge = "short" }, effects = {} },
            { id = "dru_fer_afinidad", level = 2, name = "Afinidad feral o guardiana", type = "choice", description = "Elige Ravager (daño extra gastando espacio de conjuro) o Frenesi (resistencia fisica transformado).", effects = {}, choice = {
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
            { id = "dru_fer_instintos", level = 6, name = "Instintos primales", type = "pasivo", description = "Sumas tu Mod. Sabiduría a la iniciativa y no puedes ser sorprendido mientras estas despierto.", effects = {
                { kind = "initiativeAbility", ability = "Sabiduria" },
            } },
            { id = "dru_fer_ataque_adicional", level = 6, name = "Ataque adicional (transformado)", type = "pasivo", description = "Atacas dos veces al realizar la acción de Atacar mientras estas transformado; esos ataques cuentan como magicos.", effects = {
                { kind = "flag", flag = "extraAttack", requiresState = "wild_shape" },
            } },
            { id = "dru_fer_tacticas", level = 6, name = "Tacticas ferales", type = "choice", description = "Transformado, elige Defensor de la Manada (intercambiar lugar para recibir un ataque) o Demoledor Pulverizante (derribar con salvación de Fuerza).", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "defensor",  label = "Defensor de la Manada", effects = {} },
                    { id = "demoledor", label = "Demoledor Pulverizante", effects = {} },
                },
            } },
            { id = "dru_fer_mutilacion_brutal", level = 10, name = "Mutilación Brutal", type = "informativo", description = "En el nivel 10, cuando golpeas a una criatura con un ataque de arma mientras estás transformado, la criatura golpeada tiene desventaja en la próxima tirada de salvación que haga contra un hechizo de druida que lances antes del final de tu siguiente turno.", effects = {} },
            { id = "dru_fer_afinidad_superior_feral_o_guar", level = 14, name = "Afinidad Superior Feral o Guardiana", type = "informativo", description = "A partir del nivel 14, obtienes una de las siguientes características, según tu elección en el nivel 2. ***Ravager.*** Cuando una criatura hostil que puedes ver a tu alcance sea golpeada por un ataque realizado por otra criatura, puedes usar tu reacción para hacer un ataque de oportunidad contra esa criatura hostil. ***Frenesí.*** Mientras estás en frenesí, cualquier criatura a 1,5 metros de ti que sea hostil hacia ti tiene desventaja en las tiradas de ataque contra objetivos que no seas tú u otro personaje con esta característica. Un enemigo es inmune a este efecto si no puede verte u oírte o si no puede ser asustado.", effects = {} },
            { id = "dru_fer_encarnacion_guardian_de_las_ti", level = 20, name = "Encarnación: Guardián de las Tierras Salvajes", type = "informativo", description = "En el nivel 20, puedes asumir la forma de un guardián de las tierras salvajes, mejorando la apariencia de tu transformación y empoderándote a través de las fuerzas de la naturaleza. La corteza se manifiesta como una armadura alrededor de ti y tu apariencia se vuelve feroz y aterradora a medida que las tierras salvajes te otorgan su poder. Mientras estás transformado, puedes usar tu acción para encarnar las tierras salvajes. Durante 1 minuto, obtienes los siguientes beneficios: - Cuando realizas la acción de Ataque en tu turno, puedes hacer un ataque adicional como parte de esa acción. - Todas las tiradas de ataque tienen desventaja contra ti, ya que la armadura de corteza toma el frente de los golpes. - Tu velocidad base aumenta en 3 metros y puedes ignorar el terreno difícil. La encarnación persiste más allá de tus transformaciones, pero no tiene efecto fuera de ellas.", effects = {} },
        } },
        { id = "restauracion", name = "Restauracion", desc = "Sanacion sostenida con magia de la naturaleza.", features = {
            { id = "dru_res_conjuros_camino", level = 3, name = "Hechizos del camino", type = "informativo", grantedSpells = { "piel_robliza", "restablecimiento_menor" }, description = "Nivel 3: Piel robliza (corteza de arbol) y Restablecimiento menor. Nivel 5: Palabra de curacion en masa y Revivir. Siempre los tienes preparados y NO cuentan contra los que puedes preparar.", effects = {} },
            { id = "dru_res_conjuros_camino_5", level = 5, name = "Hechizos del camino", type = "informativo", grantedSpells = { "palabra_de_curacion_en_masa", "revivir" }, description = "Nivel 5 del Camino de la Restauracion: Palabra de curacion en masa y Revivir. Siempre los tienes preparados y NO cuentan contra los conjuros que puedes preparar.", effects = {} },
                        { id = "dru_res_rejuvenecimiento", level = 2, name = "Rejuvenecimiento", cast = "accion_adicional", type = "accion", description = "Cuando eliges este camino en el nivel 2, recibes las bendiciones de Elune, convirtiéndote en una fuente de energía que ofrece alivio de las heridas. Tienes una reserva de energía representada por un número de d6 igual a tu nivel de druida. Como acción adicional, puedes elegir una criatura que puedas ver a 36,6 metros de ti y gastar un número de esos dados igual a la mitad de tu nivel de druida o menos. Lanza los dados gastados y súmalos. El objetivo recupera una cantidad de puntos de golpe igual al total. El objetivo también gana 1 punto de golpe temporal por dado. Recuperas todos los dados gastados cuando terminas un descanso largo.", actionKind = "rejuvenation", resourceKey = "living_seeds",
                    -- El maximo (un d6 por nivel de druida) lo declaraba "Alivio presto",
                    -- que no esta en ninguno de los dos libros. Vive aqui, que es el rasgo real.
                    effects = {
                        { kind = "resourceMax", resource = "living_seeds",
                          perClassLevel = "druida", perLevel = 1 },
                    } },
            { id = "dru_res_corteza_de_hierro", level = 6, name = "Corteza de Hierro", type = "informativo", cast = "reaccion", description = "A partir del nivel 6, cuando tú o una criatura dentro de 9,1 metros de ti reciban daño por ácido, frío, fuego, relámpago o trueno, puedes usar tu reacción para otorgar resistencia a la criatura contra esa instancia del daño.", effects = {} },
            { id = "dru_res_tranquilidad", level = 10, name = "Tranquilidad", type = "informativo", description = "A partir del nivel 10, puedes recurrir a la naturaleza tranquila que te rodea para calmar a tus aliados. Como acción, invocas la tranquilidad y obtienes una reserva de energía de curación que puede restaurar puntos de golpe igual a cinco veces tu nivel de druida. Mantener la tranquilidad requiere tu concentración, dura hasta 1 minuto, y mientras estás concentrado en ella, tu velocidad de movimiento se reduce a la mitad. Mientras esté activa, puedes usar una acción adicional para elegir cualquier número de criaturas dentro de 9,1 metros de ti y dividir un número de puntos de golpe de tu reserva entre ellas, hasta un máximo de puntos de golpe igual a tu nivel de druida. Una vez que usas esta característica, no puedes usarla nuevamente hasta que termines un descanso largo.", effects = {} },
            { id = "dru_res_guardia_cenarion", level = 14, name = "Guardia Cenarion", type = "informativo", description = "Cuando alcanzas el nivel 14, las criaturas del mundo natural sienten tu conexión con la naturaleza y se vuelven reticentes a atacarte. Cuando una bestia o planta te ataque, la criatura debe hacer una tirada de salvación de Sabiduría contra la CD de salvación de tus hechizos de druida. Si falla, la criatura debe elegir un objetivo diferente o el ataque falla automáticamente. Si tiene éxito, la criatura es inmune a este efecto durante 24 horas. La criatura es consciente de este efecto antes de realizar su ataque contra ti.", effects = {} },
            { id = "dru_res_encarnacion_arbol_de_vida", level = 20, name = "Encarnación: Arbol de Vida", type = "informativo", description = "Al llegar al nivel 20, puedes obtener fuerza de los árboles del mundo de Azeroth, aumentando tu forma de árbol a igualar a un anciano mientras asumes la forma serena de un Árbol de la Vida. Puedes usar tu acción para asumir tu forma de árbol y encarnar el Árbol de la Vida. Durante 1 minuto, obtienes los siguientes beneficios: - Al comienzo de cada uno de tus turnos, ganas 10 puntos de golpe temporales. Cuando la encarnación termina, pierdes cualquier punto de golpe temporal que te quede. - Tu tamaño se convierte en Grande, a menos que ya fueras más grande. - Cuando lanzas un hechizo que restaura puntos de golpe a un objetivo, otra criatura a tu elección dentro de 9,1 metros de ese objetivo recupera puntos de golpe igual a la mitad de la cantidad restaurada. La encarnación persiste más allá de la transformación, pero no tiene efecto fuera de tu forma de árbol.", effects = {} },
        } },
    },
    features = {
        { id = "dru_druidico", level = 1, name = "Druidico", type = "informativo", description = "Conoces el druidico, el lenguaje secreto de los druidas (hablar, leer y escribir).", effects = { { kind = "language", language = "Druidico" } } },
        { id = "dru_lanzamiento_conjuros", level = 1, name = "Lanzamiento de conjuros", type = "informativo", description = "Lanzas conjuros de druida usando Sabiduría (preparas Mod. Sabiduría + nivel). CD = 8 + comp + Mod. Sabiduría; ataque = comp + Mod. Sabiduría. Foco druidico.", effects = {} },
        { id = "dru_cambio_forma", level = 2, name = "Cambio de forma", cast = "accion", type = "pasivo", description = "Accion: asumes una forma druidica que conozcas. Nivel 2: Gato, Oso, Lechucito Lunar y Antarbol. Nivel 4: Acuatica y Viaje. Nivel 8: Vuelo. Conservas tus estadisticas, alineamiento y personalidad; mientras estas en forma de cambio calculas tu CA segun la forma. Al cambiar los PG se mantienen; el dano recibido en una forma se transfiere a tu forma normal. No puedes lanzar conjuros salvo que la forma lo indique. Sin limite de tiempo; revertir es una accion adicional, y ocurre solo si quedas inconsciente, caes a 0 PG o mueres.", effects = {
            { kind = "toggleState", state = "wild_shape", label = "Transformado", description = "Activa rasgos que solo funcionan mientras estas en forma druidica." },
        } },
        { id = "dru_senda", level = 2, name = "Senda del Druida", type = "informativo", description = "Eliges tu senda (Equilibrio, Feral o Restauración). Concede rasgos en niveles 2, 6, 10, 14 y 20.", effects = {} },
        { id = "dru_afinidades", level = 3, name = "Afinidades salvajes", type = "choice", description = "Eliges DOS afinidades salvajes. Si una tiene requisitos previos, debes cumplirlos para aprenderla; puedes aprender la afinidad al mismo tiempo que cumples sus requisitos. Al subir de nivel puedes reemplazar una que conozcas por otra que pudieras aprender.", effects = {}, choice = {
                slots = 2,
                options = {
                    { id = "hablar_bestias", label = "Hablar con Bestias", desc = "Puedes lanzar hablar con animales a voluntad, sin gastar un espacio de conjuro." },
                    { id = "transformacion_combate", label = "Transformacion en Combate", desc = "Puedes transformarte como accion adicional en tu turno." },
                    { id = "bestia_desplazadora", label = "Bestia Desplazadora", desc = "Gastas un espacio de nivel 2 o superior para lanzar paso brumoso; reapareces en una transformacion disponible a tu eleccion. Feral: una vez sin gastar espacio, recarga en descanso corto." },
                    { id = "rapidez_feral", label = "Rapidez Feral", desc = "Mientras estes transformado puedes realizar la accion de correr como accion adicional. No tiene efecto en forma de lechucito o arbol." },
                    { id = "nueve_vidas", label = "Nueve Vidas / Aleteo", desc = "Transformado como gato o lechucito lunar, usas tu reaccion para darte los beneficios de caida de pluma hasta el final de tu turno. Una vez por descanso corto." },
                    { id = "rugido_estampida", label = "Rugido Estampida", desc = "Gastas un espacio de nivel 1 o superior y eliges cualquier numero de criaturas a 18 metros: su velocidad aumenta 3 metros hasta el final de tu siguiente turno. +3 m por cada nivel de espacio por encima del 2." },
                    { id = "lider_manada", label = "Lider de la Manada", requiresLevel = 4, desc = "Cualquier criatura a 18 metros se ve afectada tambien por tu Ritmo de Viaje, siempre que no estes incapacitado." },
                    { id = "furia_primal", label = "Furia Primal", requiresLevel = 5, desc = "Mientras estes transformado tienes +1 a tus tiradas de ataque y dano con armas cuerpo a cuerpo." },
                    { id = "piel_gruesa", label = "Piel Gruesa", requiresLevel = 5, desc = "Mientras estes transformado sumas +1 a tu Clase de Armadura." },
                    { id = "golpe_craneo", label = "Golpe de Craneo", requiresLevel = 5, desc = "Gastas un espacio para lanzar contraconjuro una vez usando un espacio de conjuro, solo como hechizo de toque. Una vez por descanso largo." },
                    { id = "rugido", label = "Rugido", desc = "Requisito: Camino Feral. Transformado, gastas un espacio de conjuro para lanzar duelo obligado." },
                    { id = "marca_ursoc", label = "Marca de Ursoc", desc = "Requisito: Camino Feral. Transformado como oso, gastas un espacio para lanzar agrandar/reducir sobre ti. Una vez por descanso largo." },
                    { id = "acechar", label = "Acechar", desc = "Requisito: Camino Feral. Transformado, gastas un espacio para lanzar invisibilidad sobre ti. Una vez por descanso largo." },
                    { id = "renovacion", label = "Renovacion", desc = "Requisito: Camino Feral. Transformado, gastas un espacio de nivel 1 o superior para lanzar curar heridas sobre ti. La curacion aumenta 1d8 por nivel por encima del 1." },
                    { id = "instintos_supervivencia", label = "Instintos de Supervivencia", desc = "Requisito: Camino Feral. Transformado como oso, si te reducen a 0 puntos de golpe sin ser asesinado de inmediato, caes a 1 punto de golpe. Una vez por descanso largo." },
                    { id = "favor_ursoc", label = "Favor de Ursoc", desc = "Requisito: Camino Feral. Usas la Marca de Ursoc tantas veces como tu Mod. Sabiduria en lugar de una. Recargan en descanso corto o largo." },
                    { id = "golpe_poderoso", label = "Golpe Poderoso", requiresLevel = 5, desc = "Requisito: Camino Feral. Al golpear transformado, la criatura hace una salvacion de Constitucion contra tu CD de druida o queda aturdida hasta el final de tu proximo turno. Una vez por descanso largo." },
                    { id = "lluvia_lunar", label = "Lluvia Lunar", desc = "Requisito: Camino del Equilibrio y el truco golpe lunar. Al golpear con golpe lunar transformado como lechucito lunar, la velocidad del objetivo se reduce 3 metros hasta el inicio de tu proximo turno." },
                    { id = "deriva_solar", label = "Deriva Solar", desc = "Requisito: Camino del Equilibrio y el truco ira solar. Transformado como lechucito lunar, el alcance de ira solar aumenta a 36 metros." },
                    { id = "fuego_solar", label = "Fuego Solar", desc = "Requisito: Camino del Equilibrio y el truco ira solar. Al golpear con ira solar transformado como lechucito lunar, el objetivo hace una salvacion de Constitucion contra tu CD o queda cegado hasta el inicio de tu proximo turno." },
                    { id = "alineacion_celestial", label = "Alineacion Celestial", requiresLevel = 5, desc = "Requisito: Camino del Equilibrio. Transformado como lechucito lunar, puedes usar cualquiera de los dos resultados al repetir una tirada de dado de dano." },
                    { id = "florecer", label = "Florecer", desc = "Requisito: Camino de la Restauracion. Una vez por turno, al lanzar dados de golpe para Rejuvenecimiento, repites uno de los dados y usas cualquiera de los resultados." },
        } } },
        ASI("druida", 4),
        { id = "dru_mejora_cambio_forma", level = 4, name = "Mejora de cambio de forma", type = "informativo", description = "Ganas formas adicionales de Cambio de Forma, segun la tabla de Formas de Cambio: a nivel 4 la Forma Acuatica y la Forma de Viaje; a nivel 8 la Forma de Vuelo.", effects = {} },
        { id = "dru_cuerpo_atemporal", level = 18, name = "Cuerpo Atemporal", type = "informativo", description = "A partir del nivel 18, la magia primigenia que manejas ha hecho que envejezcas más lentamente. Por cada 10 años que pasan, tu cuerpo envejece solo 1 año.", effects = {} },
        { id = "dru_alma_del_bosque", level = 18, name = "Alma del Bosque", type = "informativo", description = "A partir del nivel 18, tu conexión con la naturaleza crece a nuevas profundidades, fortaleciendo tu vínculo con ella y permitiéndote conjurar un portal al Sueño Esmeralda. Si pasas 10 minutos en un área de naturaleza intacta, puedes conjurar un portal al Sueño Esmeralda. La entrada brilla tenuemente y mide 1,5 metros de ancho y 3 metros de alto. Tú y cualquier criatura que designes al conjurar el portal pueden entrar al Sueño Esmeralda mientras el portal permanezca abierto. Puedes abrir y cerrar el portal si estás a menos de 9,1 metros de él. Cuando está cerrado, el portal en Azeroth se desmorona y es efectivamente invisible. El portal permanece conjurado durante 24 horas, después de lo cual se desmorona por completo y no puede ser conjurado nuevamente durante 7 días.", effects = {} },
    },
}
