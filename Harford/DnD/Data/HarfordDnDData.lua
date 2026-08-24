-- HarfordDnDData: tablas de datos estaticos de la ficha D&D 5e.
-- Solo datos, sin logica. Las consume HarfordDnD.lua (y quien necesite el orden
-- canonico de caracteristicas/habilidades).

HarfordDnDData = HarfordDnDData or {}
local IconCatalog = _G.HarfordIconCatalog

-- Caracteristicas en orden de ficha. `key` es la clave ARC; `short` la etiqueta.
HarfordDnDData.ABIL = {
    { key = "Fuerza",       short = "FUE", desc = "Potencia física, entrenamiento atlético y capacidad para aplicar fuerza bruta.",
        saveDesc = "Resistencia frente a empujones, agarres, derribos y otros efectos que ponen a prueba la potencia física." },
    { key = "Destreza",     short = "DES", desc = "Agilidad, reflejos, coordinación y equilibrio.",
        saveDesc = "Reflejos, agilidad y rapidez para evitar peligros repentinos." },
    { key = "Constitucion", short = "CON", desc = "Salud, aguante y resistencia física.",
        saveDesc = "Aguante físico frente a venenos, enfermedades, fatiga y otras adversidades corporales." },
    { key = "Inteligencia", short = "INT", desc = "Capacidad de aprender, recordar, analizar y razonar.",
        saveDesc = "Fortaleza del razonamiento y la memoria frente a ilusiones, engaños y ataques mentales." },
    { key = "Sabiduria",    short = "SAB", desc = "Sentido común, intuición, voluntad y conciencia del entorno.",
        saveDesc = "Fuerza de voluntad y claridad mental ante el miedo, los encantamientos y la manipulación de la mente." },
    { key = "Carisma",      short = "CAR", desc = "Magnetismo personal, liderazgo, confianza y capacidad de influir en otros.",
        saveDesc = "Firmeza de la identidad y del espíritu frente a posesiones, destierros y efectos que alteran la esencia del individuo." },
}

-- Habilidades en orden de ficha. `ability` referencia una key de ABIL.
HarfordDnDData.SKILLS = {
    { name="Acrobacias", ability="Destreza", id="Acrobacias", desc="Mantener el equilibrio y realizar maniobras acrobáticas." },
    { name="Atletismo", ability="Fuerza", id="Atletismo", desc="Trepar, saltar, nadar y otras proezas físicas exigentes." },
    { name="Conocimiento Arcano", ability="Inteligencia", id="Arcano", desc="Conocimiento sobre magia, planos, objetos mágicos y tradiciones arcanas." },
    { name="Engaño", ability="Carisma", id="Engano", desc="Mentir, disfrazar la verdad y fingir." },
    { name="Historia", ability="Inteligencia", id="Historia", desc="Conocimiento de acontecimientos históricos, leyendas y civilizaciones." },
    { name="Interpretación", ability="Carisma", id="Interpretacion", desc="Actuar, cantar, bailar o entretener." },
    { name="Intimidación", ability="Carisma", id="Intimidacion", desc="Influir mediante amenazas o presencia." },
    { name="Investigación", ability="Inteligencia", id="Investigacion", desc="Deducción, búsqueda de pistas y análisis." },
    { name="Juego de Manos", ability="Destreza", id="JuegoManos", desc="Prestidigitación, ocultar objetos, hurtar bolsillos." },
    { name="Medicina", ability="Sabiduria", id="Medicina", desc="Diagnosticar heridas o enfermedades y estabilizar criaturas." },
    { name="Naturaleza", ability="Inteligencia", id="Naturaleza", desc="Conocimiento del mundo natural." },
    { name="Percepción", ability="Sabiduria", id="Percepcion", desc="Detectar detalles mediante los sentidos." },
    { name="Perspicacia", ability="Sabiduria", id="Perspicacia", desc="Leer intenciones, emociones y mentiras." },
    { name="Persuasión", ability="Carisma", id="Persuasion", desc="Convencer mediante tacto, educación o diplomacia." },
    { name="Religión", ability="Inteligencia", id="Religion", desc="Conocimiento de dioses, cultos y tradiciones religiosas." },
    { name="Sigilo", ability="Destreza", id="Sigilo", desc="Ocultarse, moverse sin ser visto ni oído." },
    { name="Supervivencia", ability="Sabiduria", id="Supervivencia", desc="Rastrear, orientarse y sobrevivir en la naturaleza." },
    { name="Trato con Animales", ability="Sabiduria", id="Animales", desc="Calmar, controlar o interpretar animales." },
}

-- TOOLS: catalogo estandar de herramientas D&D 5e (herramientas de artesano + kits + instrumentos +
-- juegos + vehiculos). Lo usa el selector `optionsFrom = "toolProf"` de los choice (dotes como
-- Prodigio o Artifice Iniciado). El campo `name` es el que consume el efecto `toolProf`.
HarfordDnDData.TOOLS = {
    { id="her_alquimista",   name="Suministros de alquimista", artisan=true },
    { id="her_cervecero",    name="Suministros de cervecero", artisan=true },
    { id="her_caligrafia",   name="Suministros de caligrafia", artisan=true },
    { id="her_carpintero",   name="Herramientas de carpintero", artisan=true },
    { id="her_cartografo",   name="Herramientas de cartografo", artisan=true },
    { id="her_zapatero",     name="Herramientas de zapatero", artisan=true },
    { id="her_cocinero",     name="Utiles de cocinero", artisan=true },
    { id="her_soplavidrio",  name="Herramientas de soplador de vidrio", artisan=true },
    { id="her_joyero",       name="Herramientas de joyero", artisan=true },
    { id="her_curtidor",     name="Herramientas de curtidor", artisan=true },
    { id="her_albanil",      name="Herramientas de albanil", artisan=true },
    { id="her_pintor",       name="Suministros de pintor", artisan=true },
    { id="her_alfarero",     name="Herramientas de alfarero", artisan=true },
    { id="her_herrero",      name="Herramientas de herrero", artisan=true },
    { id="her_armero",       name="Herramientas de armero", artisan=true },
    { id="her_hojalatero",   name="Herramientas de hojalatero", artisan=true },
    { id="her_tejedor",      name="Herramientas de tejedor", artisan=true },
    { id="her_tallador",     name="Herramientas de tallador de madera", artisan=true },
    { id="her_disfraz",      name="Kit de disfraz" },
    { id="her_falsificacion",name="Kit de falsificacion" },
    { id="her_herborista",   name="Kit de herborista" },
    { id="her_ladron",       name="Herramientas de ladron" },
    { id="her_navegante",    name="Herramientas de navegante" },
    { id="her_envenenador",  name="Utiles de envenenador" },
    { id="her_instrumento",  name="Instrumento musical", categoria=true },
    { id="her_juego",        name="Juego de azar", categoria=true },
    { id="her_vehiculos_tierra", name="Vehiculos (terrestres)", vehiculo=true },
    { id="her_vehiculos_agua",   name="Vehiculos (acuaticos)", vehiculo=true },
}

-- Los iconos viven en HarfordIconCatalog; se expone este alias por compatibilidad.
HarfordDnDData.ICONS = (IconCatalog and IconCatalog.names) or {}

HarfordDnDData.PRESENTATION = {
    -- Alias de nombres del Libro cuya tarjeta TRP3 se ha verificado durante la
    -- auditoria. Se mantienen aqui, no se leen los perfiles en tiempo de juego.
    ["artes marciales"] = {},
    ["ataque adicional"] = {},
    ["bastion divino"] = {},
    ["chi"] = {},
    ["control de ira"] = {},
    ["dedos de escarcha"] = {},
    ["enfoque"] = {},
    ["entrenamiento de centinela"] = {},
    ["estilo de combate"] = {},
    ["formulas de trucos"] = {},
    ["fragmentos de alma"] = {},
    ["furia de elune"] = {},
    ["gracia de elune"] = {},
    ["metamagia"] = {},
    ["palma aturdidora"] = {},
    ["palma de chi ji"] = {},
    ["provocacion"] = {},
    ["rejuvenecimiento"] = {},
    ["rodar"] = {},
    ["serenidad"] = {},
    ["canalizar divinidad"] = {description = "Tu devoción te permite canalizar energía divina para alimentar dones sagrados. Recuperas los usos de Canalizar Divinidad al terminar un descanso corto o largo." },
    ["conjuros del sacerdocio de elune"] = {description = "Los conjuros de Elune están siempre preparados y no cuentan contra tu limite de conjuros de sacerdote. Nivel 1: Encontrar familiar y Marca del cazador. Nivel 2: Rayo de luna y Oleada estelar. Nivel 3: Señal de esperanza y Explosión lunar. Nivel 4: Destierro e Invisibilidad mayor. Nivel 5: Curar heridas en masa y Carcaj veloz." },
    ["accion astuta"] = {description = "Puedes realizar Correr, Destrabarse o Esconderse como acción adicional." },
    ["alacridad"] = {description = "Puedes sumar tu modificador de Carisma a tus tiradas de iniciativa. Tras atacar cuerpo a cuerpo durante tu turno, ese objetivo no puede hacer ataques de oportunidad contra ti durante el resto del turno." },
    ["armas runicas"] = {description = "Sabes inscribir runas en armas y vincularlas a ti mediante un ritual de una hora." },
    ["ataque furtivo"] = {description = "Una vez por turno, cuando impactas con un arma ligera, de precision o a distancia, infliges daño extra si tienes ventaja o si un enemigo del objetivo esta a 5 pies de el y no estas en desventaja." },
    ["cambio de forma"] = {description = "Puedes usar tu acción para asumir mágicamente una forma druidica que conozcas. Puedes volver a tu forma normal cuando quieras." },
    ["canalizar fuego demoniaco"] = {description = "Canalizas fuego demoniaco para alimentar tus tecnicas Illidari." },
    ["constitucion no muerta"] = {description = "Eres inmune a enfermedad, envenenado y hemorragia, y tienes resistencia al daño de veneno." },
    ["defensa sin armadura"] = {description = "Mientras no lleves armadura ni escudo, tu CA es 10 + modificador de Destreza + modificador de Inteligencia." },
    ["disparo arcano"] = {description = "Puedes convertir tus ataques a distancia contra una presa marcada en disparos arcanos: ignoran cobertura y causan daño de fuerza adicional al impactar." },
    ["domar bestia"] = {description = "Puedes vincularte con una bestia y ganarte su lealtad como companera." },
    ["druidico"] = {description = "Conoces el idioma secreto de los druidas y sus simbolos ocultos." },
    ["empatia animal"] = {description = "Puedes comunicar ideas simples a bestias, leer su estado de animo e intencion y conocer necesidades inmediatas o posibles formas de calmarlas." },
    ["espiral de la muerte"] = {description = "Como acción, gastas dados de Poder Runico para herir a una criatura visible a distancia o curar a una criatura no muerta." },
    ["explorador natural"] = {description = "Tu experiencia en tierras salvajes te permite rastrear, orientarte y moverte por la naturaleza con eficacia." },
    ["fuente de magia"] = {description = "Tu conexion con las artes arcanas te permite recuperar y canalizar mana." },
    ["golpe de escarcha"] = {description = "Cuando impactas con un arma, puedes canalizar escarcha runica para infligir daño adicional." },
    ["golpe del cruzado"] = {description = "Cuando impactas con un ataque cuerpo a cuerpo, puedes gastar un espacio de conjuro para infligir daño radiante adicional. El daño aumenta con el nivel del espacio." },
    ["golpe runico"] = {description = "Cuando impactas con un ataque cuerpo a cuerpo, puedes gastar dados de Poder Runico para infligir daño adicional." },
    ["guia ancestral"] = {description = "Los espíritus ancestrales guian tus acciones y sostienen a tus aliados." },
    ["imposicion de manos"] = {description = "Como acción, puedes extraer poder de tu reserva curativa para restaurar puntos de golpe a una criatura que toques. También puedes gastar 5 puntos para curar una enfermedad o neutralizar un veneno." },
    ["iniciacion illidari"] = {description = "Has sobrevivido al entrenamiento Illidari y puedes usar Destreza en lugar de Fuerza para ataques y daño con gujas de guerra." },
    ["llamas del caos"] = {description = "Obtienes un ataque a distancia de fuego vil que usa Destreza para impactar y causar daño." },
    ["lobo solitario: ataque apuntado"] = {description = "Cuando no tienes mascota, puedes usar una acción adicional para obtener ventaja en tu próximo ataque con arma." },
    ["maquina de matar"] = {description = "La violencia de tus ataques alimenta tu eficacia marcial." },
    ["marca del cazador"] = {description = "Como acción adicional, marcas una presa visible. Una vez por turno, infliges daño adicional cuando la golpeas con un ataque con arma y tienes ventaja para encontrarla mediante Percepción o Supervivencia." },
    ["metamorfosis"] = {description = "Como acción adicional, liberas el poder de tu demonio atado y entras en metamorfosis durante el tiempo indicado por el rasgo." },
    ["misivas secretas"] = {description = "Puedes dedicar cuatro horas a crear un lenguaje criptico compartido con otra criatura para entrelazar mensajes y comandos secretos." },
    ["mordida de demonio"] = {description = "Tras realizar la acción de Ataque, puedes gastar Vil para hacer dos ataques con arma como acción adicional." },
    ["pericia"] = {description = "Tu bonificador de competencia se duplica para las pruebas de habilidad realizadas con las competencias elegidas." },
    ["piromaniaco"] = {description = "Cuando obtienes el resultado maximo en un dado de daño de un conjuro de fuego, puedes volver a tirar uno de esos dados y sumar el nuevo resultado." },
    ["poder runico"] = {description = "Las energías necroticas se representan mediante una reserva de dados de Poder Runico que se recupera tras un descanso largo." },
    ["racha de calor"] = {description = "Cuando sacas el resultado maximo en un dado de daño de un conjuro, puedes volver a tirar uno de esos dados y sumar el resultado; una vez por turno." },
    ["renacer oscuro"] = {description = "Tu naturaleza no muerta te permite volver a levantarte mediante poder necrótico." },
    ["secretos profanos"] = {description = "Tu estudio de secretos prohibidos amplia tu dominio de la magia vil y oscura." },
    ["segundo aliento"] = {description = "Como acción adicional puedes gastar dados de golpe para recuperar puntos de golpe. Recuperas los dados gastados al descansar según corresponda." },
    ["sentido divino"] = {description = "Como acción, detectas celestiales, infernales, no muertos y lugares u objetos consagrados o profanados dentro de 60 pies hasta el final de tu siguiente turno." },
    ["sentido magico"] = {description = "Puedes percibir las corrientes de magia y las presencias sobrenaturales cercanas." },
    ["toque de vida"] = {description = "Puedes drenar esencia vital para sostenerte en combate." },
    ["totemista"] = {description = "Puedes invocar y dirigir totems para canalizar los poderes de los elementos." },
    ["vil"] = {description = "Canalizas energía vil para alimentar las tecnicas de tu clase." },
    ["vision espectral"] = {description = "Tus cuencas oculares están imbuidas de magia: puedes ver normalmente en oscuridad y percibir energías mágicas según el alcance de tu rasgo." },
}

-- Presentacion extraida de tarjetas TRP3 de referencia durante desarrollo.
-- Se guarda hardcodeada: el addon nunca abre SavedVariables de TRP3 en juego.
HarfordDnDData.TRP3_PRESENTATION = {
    ["accion astuta"] = {description = "Puedes realizar Correr, Destrabarse o Esconderse como acción adicional." },
    ["adaptacion salvaje"] = {description = "Destreza\nObtienes competencia en tus elecciones de salvaciones de Destreza o Constitución, además de las del druida. Además, te refieres a la tabla de Conjuración Feral en la descripción de la clase Feral para determinar tus trucos, espacios de conjuro y afinidades conocidas cada vez que subas de nivel en esta clase. También cuentas como un lanzador de primera categoría para determinar los espacios de conjuro disponibles al combinarte con otras clases." },
    ["afinidad elemental"] = {description = "Sintonización de agua\nConoces un número adicional de conjuros de chamán de nivel 1 o superior igual a tu bonificador de competencia." },
    ["afinidades salvajes"] = {description = "Al haber acostumbrado tu ser a las fuerzas druídicas, has aprendido a aprovechar el verdadero potencial de sus poderes y el potencial de ciertas formas. Obtienes dos afinidades salvajes de tu elección:" },
    ["alacridad"] = {description = "Puedes darte un bono a tus tiradas de iniciativa igual a tu modificador de Carisma.\n\nAdemás, aprendes cómo golpear y retirarte sin represalias. Durante tu turno, si haces un ataque cuerpo a cuerpo contra una criatura, esa criatura no puede hacer ataques de oportunidad contra ti durante el resto de tu turno." },
    ["armas runicas"] = {description = "Sabes inscribir runas en armas, dotándolas de poder y confiándolas a ti. Realizas un ritual de 1 hora para inscribir las runas, que puede completarse durante un descanso largo. Las armas deben estar a tu alcance durante todo el ritual. Solo puedes tener un arma de dos manos unida o dos armas de una mano. Vincular nuevas armas rompe inmediatamente el vínculo con las anteriores.\n\n- No puedes ser desarmado de tus armas rúnicas a menos que estés incapacitado. Si están en el mismo plano de existencia que tú, puedes invocarlas como acción adicional, teletransportándolas a tus manos. Si tienes dos armas rúnicas de una mano, al usar un rasgo de caballero de la muerte que se refiera a tu arma rúnica, puedes elegir cuál usar (pero no ambas)." },
    ["arrollar"] = {description = "Aprendes a usar tu arma como barrera. Cuando recibas un ataque cuerpo a cuerpo, puedes usar tu reacción para tirar 1d10 y sumar el resultado a tu CA. Si tu arrollamiento hace que el ataque falle, puedes realizar un ataque de arma contra el objetivo como parte de la misma reacción.\n\nPuedes usar esta característica dos veces. Recuperas los usos gastados al completar un descanso corto o largo." },
    ["artes marciales"] = {description = "Tu práctica de las artes marciales te da maestría en estilos de combate que usan golpes desarmados y armas de monje, que son las espadas cortas y cualquier arma cuerpo a cuerpo simple que no tenga la propiedad de dos manos ni pesada.\n\nObtienes los siguientes beneficios mientras estés desarmado o empuñando solo armas de monje y no llevas armadura de malla o de placas, ni empuñas un escudo:\n\n- Puedes usar Destreza en lugar de Fuerza para las tiradas de ataque y daño de tus golpes desarmados y armas de monje.\n- Puedes tirar un d4 en lugar del daño normal de tu golpe desarmado o arma de monje. Este dado cambia a medida que ganas niveles como monje, como se muestra en la columna de Artes Marciales de la tabla de Monje.\n- Cuando usas la acción de Ataque con un golpe desarmado o un arma de monje en tu turno, puedes realizar un golpe desarmado como acción adicional. Por ejemplo, si tomas la acción de Ataque y atacas con un bastón, puedes realizar también un golpe desarmado como acción adicional." },
    ["ataque adicional"] = {description = "Puedes atacar dos veces, en lugar de una, siempre que tomes la acción de Ataque en tu turno." },
    ["ataque furtivo"] = {description = "2d6\nUna vez por turno, puedes infligir daño extra a una criatura que golpees con un ataque si tienes ventaja en la tirada de ataque. El ataque debe usar un arma ligera, de precisión o a distancia. No necesitas tener ventaja en el ataque si otro enemigo del objetivo está a 5 pies de él, ese enemigo no está incapacitado y no tienes desventaja en la tirada de ataque" },
    ["bastion divino"] = {description = "Cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar una ranura de conjuro para infligir daño radiante al objetivo, además del daño del arma. El daño adicional es de 2d6 por una ranura de conjuro de 1er nivel, más 1d6 por cada nivel de conjuro superior al 1º, hasta un máximo de 6d6. \n\nAdemás, la criatura tiene desventaja en las tiradas de ataque contra criaturas que no seas tú hasta el final de tu próximo turno. Por cada nivel de conjuro superior al 1º, puedes elegir una criatura adicional dentro de 10 pies de ti para que sufra este efecto hasta el final de tu próximo turno. \n\nUn ataque cuerpo a cuerpo puede beneficiarse de tu Golpe del Cruzado o de tu Bastión Divino, pero solo uno de estos efectos puede aplicarse a un ataque." },
    ["cambio de forma"] = {description = "Puedes usar tu acción para asumir mágicamente una forma druídica. No hay límite en cuántas veces puedes cambiar de forma a una que conozcas.\nTu nivel de druida determina las formas a las que puedes transformarte:\n\n Gato\n Oso\n Lechúcico Lunar\n Árbol\n\nNo hay límite en cuánto tiempo puedes permanecer transformado, y puedes regresar a tu forma normal como acción adicional. Revertirás automáticamente si quedas inconsciente, caes a 0 puntos de golpe o mueres. \nMientras estás transformado, se aplican las siguientes reglas:\n\n- Conservas tus estadísticas de juego, alineamiento y personalidad. Mientras estás en forma de cambio, se te considera sin armadura y calculas tu Clase de Armadura según la forma.\n\n- Cuando cambias de forma, tus puntos de golpe no cambian, y cualquier daño recibido en una forma se transfiere a tu forma normal.\n\n- No puedes lanzar conjuros, a menos que la forma lo indique, y tu capacidad para hablar o realizar acciones que requieran manos se limita a las capacidades de tu forma. Sin embargo, cambiar de forma no rompe tu concentración en un conjuro que ya hayas lanzado ni te impide realizar acciones que formen parte de un conjuro, como rayo de luna, que ya hayas lanzado.\n\n- Conservas el beneficio de cualquier característica de tu clase, raza u otra fuente y puedes usarlas si la forma es físicamente capaz de hacerlo, además de ganar las características de la forma. Sin embargo, no puedes usar tus sentidos especiales, como visión en la oscuridad, a menos que tu nueva forma también posea ese sentido.\n\n- Eliges si tu equipo cae al suelo en tu espacio, se fusiona con tu nueva forma o es usado por ella. El equipo usado funciona con normalidad, pero el DM decide si es práctico para la nueva forma usar una pieza de equipo, según la forma y el tamaño de la criatura. Tu equipo no cambia de tamaño ni de forma para coincidir con la nueva forma, y cualquier equipo que la nueva forma no pueda usar debe fusionarse o caer al suelo. El equipo fusionado con tu forma no tiene efecto y no puede ser activado hasta que dejes la forma, pero cualquier propiedad mágica pasiva seguirá afectándote." },
    ["canalizar divinidad"] = {description = "Tu devoción te permite canalizar energía divina para alimentar efectos mágicos. Cuando usas tu Canalizar Divinidad, eliges qué opción usar. Luego debes terminar un descanso corto o largo para usar Canalizar Divinidad de nuevo." },
    ["canalizar fuego demoniaco"] = {description = "Puedes canalizar el poder de las llamas infernales en tus conjuros. \nCuando infliges daño con un conjuro de brujo, puedes optar por recibir una cantidad de daño de fuego igual al nivel del conjuro. Un objetivo recibe el doble de daño de fuego que tú recibiste." },
    ["carga"] = {description = "Si te mueves al menos 20 pies directamente hacia un objetivo y luego realizas un ataque con arma en el mismo turno, la criatura sufre 1d8 de daño adicional. Si el objetivo es una criatura, debe tener éxito en una tirada de salvación de Fuerza CD 14. En una salvación fallida, la criatura es derribada." },
    ["chi"] = {description = "Puntos 5 || CD Salv 15\nTu entrenamiento te permite aprovechar la energía mística del chi. Tu acceso a esta energía se representa por una cantidad de puntos de chi. Tu nivel de monje determina cuántos puntos tienes. Puedes gastar estos puntos para alimentar varias características de chi. \nCuando gastas un punto de chi, no está disponible hasta que termines un descanso corto o largo, al final del cual recuperas todos los puntos de chi gastados. Debes pasar 30 minutos del descanso meditando para recuperar tus puntos de chi." },
    ["conocimiento demoniaco"] = {description = "Tus estudios en grimorios de conocimiento oscuro te han otorgado el poder de invocar demonios.\nLa invocación de un demonio solo puede realizarse al final de un descanso largo. Solo puedes tener un demonio invocado o un núcleo a la vez." },
    ["constitucion no muerta"] = {description = "Tu naturaleza no-muerta te hace inmune a las enfermedades, a la condición de envenenado y a la de hemorragia, además de ganar resistencia al daño por veneno." },
    ["control de ira"] = {description = "Tu ira se renueva con los golpes que recibes.\nCuando una criatura hostil te golpea con un ataque, ganas 1 punto de ira de inmediato.\nSolo puedes beneficiarte de este efecto una vez por turno." },
    ["dedos de escarcha"] = {description = "Evocación 1 acción || Uno mismo (cono de 15 pies) || V, S || Instantánea\nUn estallido de frío helado surge de tus dedos en un cono de 15 pies. Cada criatura en esa área debe realizar una tirada de salvación de Constitución. Una criatura sufre 2d8 de daño por frío si falla la tirada, o la mitad de daño si la supera.\n\nEl frío congela los líquidos no mágicos en el área que no estén siendo llevados ni transportados." },
    ["defensa sin armadura"] = {description = "Mientras no lleves armadura ni estés empuñando un escudo, tu CA será igual a 10 + Mod. Destreza + Mod. Sabiduría 17." },
    ["desarme"] = {description = "Puedes gastar 2 puntos de furia cuando hagas una tirada de ataque para intentar un golpe desarmador. Si el ataque impacta, infliges daño normal y el objetivo suelta un objeto de tu elección que esté sujetando." },
    ["disparo arcano"] = {description = "Puedes evocar energía arcana en tus ataques. Cuando realices la acción de Ataque, puedes elegir realizar tus ataques con armas a distancia contra tu criatura marcada como **Disparos Arcanos**. Hasta el final de tu turno, tus ataques a distancia contra tu objetivo marcado obtienen los siguientes beneficios:\n\n- Tus ataques ignoran la media y tres cuartos de cobertura.\n- En cada impacto, el arma inflige daño de fuerza adicional al objetivo igual a 2 + la mitad de tu nivel de cazador.\n\nPuedes usar esta característica un número de veces igual a tu modificador de Sabiduría. Recuperas todos los usos gastados al finalizar un descanso corto o largo." },
    ["domar bestia"] = {description = "Puedes intentar domar a una bestia que esté a 60 pies de ti y que pueda verte y oírte; la bestia no puede ser más grande que Mediana y debe tener un valor de desafío de 1/2 o menor. Domar a una bestia requiere gastar 50 po en hierbas raras y comida fina, y en muchos casos puede llevar varias horas de trabajo o días (a discreción del DM). Solo puedes tener una bestia domesticada a la vez." },
    ["druidico"] = {description = "Conoces el druídico, el lenguaje secreto de los druidas. Puedes hablar, leer y escribir en druídico, un lenguaje sagrado para los druidas que no se enseña a los forasteros sin severas consecuencias para el maestro y el aprendiz." },
    ["ecos de fe"] = {description = "4 puntos\nLa fuerza de tu llamado resuena en ti. Esta fuerza resonante se representa mediante puntos de fe, que te permiten crear una variedad de efectos mágicos. Nunca puedes tener más puntos de fe que los que se muestran en la tabla para tu nivel. Recuperas todos los puntos de fe gastados cuando terminas un descanso largo" },
    ["empatia animal"] = {description = "Tu dominio del conocimiento de cazador te permite establecer un vínculo poderoso con las bestias y el entorno que te rodea. Tienes la habilidad innata de comunicarte con las bestias, y estas te reconocen como un espíritu afín. Mediante sonidos y gestos, puedes comunicar ideas simples a una bestia como acción, y puedes leer su estado de ánimo e intención básica. Aprendes su estado emocional, si está afectada por algún tipo de magia, sus necesidades a corto plazo (como comida o seguridad) y acciones que puedes realizar (si las hay) para persuadirla de que no ataque. No puedes usar esta habilidad contra una criatura que hayas atacado en las últimas 24 horas." },
    ["energia"] = {description = "Puntos 2 || CD Salv 12" },
    ["enfoque"] = {description = "1d8 || 2 Dados\nTu enfoque como cazador te diferencia de los rastreadores y exploradores comunes, dándote acceso a un grupo de dados de enfoque, que son d8. Puedes usar estos dados para obtener diferentes beneficios. Un dado de enfoque se gasta cuando lo usas. Recuperas todos los dados de enfoque gastados cuando terminas un descanso corto o largo." },
    ["entrenamiento de centinela"] = {description = "Ganas competencia con armadura ligera y media. Aprendes el truco Golpe lunar como truco de sacerdote; no cuenta contra tu límite de trucos conocidos." },
    ["escudo de sangre"] = {description = "Aprendes a tejer tu magia profana en una barrera protectora. Cuando lanzas un conjuro de caballero de la muerte de 1er nivel o superior, puedes usar la esencia oscura del conjuro para crear un escudo de sangre sobre ti que dura hasta que termines un descanso largo. El escudo tiene puntos de golpe iguales al doble de tu nivel de caballero de la muerte + mod Carisma 4.\nSiempre que recibas daño, el escudo lo absorbe primero. Si el daño reduce el escudo a 0 puntos de golpe, recibes cualquier daño restante.\n\nMientras el escudo de sangre tenga 0 puntos de golpe, no puede absorber daño de nuevo, pero su magia permanece.\nSiempre que lances un conjuro de caballero de la muerte de 1er nivel o superior, el escudo recupera puntos de golpe iguales al doble del nivel del conjuro.\n\nUna vez que el escudo de sangre se disipa, no puedes crearlo de nuevo hasta que termines un descanso largo." },
    ["espiral de la muerte"] = {description = "Gasta dados de Poder Rúnico como acción e inyecta una criatura visible dentro de 120 pies. Si es no-muerta, recupera puntos de golpe iguales al resultado de los dados. \nSi no es no-muerta, realizas conjuro a distancia usando tu Mod. Carisma; si impactas, infliges daño necrótico igual al doble del resultado de los dados gastados." },
    ["explorador natural"] = {description = "Eres hábil para moverte por el mundo natural y reaccionas con rapidez y decisión cuando te atacan. Ganas los siguientes beneficios:\n\n• Añades tu modificador de Sabiduría a tus tiradas de iniciativa. \n• En tu primer turno durante el combate, tienes ventaja en las tiradas de ataque contra criaturas que no hayan actuado todavía.\n\nAdemás, eres experto en recorrer la naturaleza y obtienes los siguientes beneficios cuando viajas durante una hora o más:\n\n• Tienes ventaja en las pruebas para evitar perderte. \n• Tienes ventaja en las pruebas de Sabiduría (Supervivencia) que hagas para buscar comida. \n• Incluso cuando estás realizando otra actividad mientras viajas (como buscar comida, ver o rastrear), permaneces alerta al peligro. \n• Si viajas solo o solo con tu compañero bestia, puedes moverte sigilosamente a un ritmo normal. \n• Mientras estés rastreando criaturas, también puedes saber su número exacto, sus tamaños y cuánto tiempo ha pasado desde que pasaron por el área." },
    ["exponer armadura"] = {description = "Puedes usar tu acción y gastar 1 punto de energía para realizar un ataque especial con arma. Si aciertas, infliges daño normal y expones fallos en su defensa. Cada otra criatura tiene ventaja en la primera tirada de ataque con arma que haga contra el objetivo antes del final de tu siguiente turno." },
    ["formulas de trucos"] = {description = "Has inscrito un conjunto de fórmulas arcanas en tu libro de conjuros que puedes usar para formular un truco en tu mente. Siempre que termines un descanso largo y consultes esas fórmulas en tu libro de conjuros, puedes reemplazar un truco de mago que conozcas por otro truco de la lista de conjuros de mago." },
    ["fragmentos de alma"] = {description = "Puedes tener hasta tres fragmentos de alma en cualquier momento; intentar crear un fragmento de alma adicional resulta en una gema inútil y opaca. Los fragmentos de alma duran hasta que se usan, momento en el que desaparecen. Si un fragmento de alma sale de tu posesión durante al menos 8 horas, desaparece. Los fragmentos de alma que creas solo pueden ser utilizados por ti; los fragmentos creados por otros brujos son inútiles.\n\nDurante el transcurso de un descanso, puedes recolectar fragmentos de almas errantes para crear fragmentos de alma. Puedes crear un solo fragmento de alma durante un descanso breve o cualquier cantidad durante un descanso largo.\n\nPuedes capturar parte de las almas que escapan de las criaturas moribundas. Cuando una criatura apropiada a 60 pies de ti muere, puedes usar tu reacción para crear un fragmento de alma.\n\n- Todos los humanoides pueden producir fragmentos de alma.\n- La mayoría de los no muertos y casi todos los constructos no pueden producir fragmentos de alma.\n\nPuedes gastar un fragmento de alma a 5 pies." },
    ["fuente de magia"] = {description = "Puntos hechicería 3\nAccedes a un profundo manantial de magia dentro de ti. Este manantial se representa mediante puntos de hechicería, que te permiten crear una variedad de efectos mágicos. Nunca puedes tener más puntos de hechicería que los mostrados en la tabla para tu nivel. Recuperas todos los puntos de hechicería gastados cuando terminas un descanso largo.\n\nPuedes usar tus puntos de hechicería para ganar espacios de conjuro adicionales o sacrificar espacios de conjuro para ganar puntos de hechicería adicionales.\n\nPuedes transformar puntos de hechicería no gastados en un espacio de conjuro como una acción adicional en tu turno. Los espacios de conjuro creados de esta manera desaparecen al final de un descanso largo." },
    ["ira"] = {description = "Puntos máximos 2 || CD Salv 12\nGanas 1 punto de ira cuando infliges daño a una criatura con un ataque de arma que no hayas gastado puntos de ira en él. Puedes gastar estos puntos para realizar diversas maniobras. Para usar una de estas maniobras, debes gastar una cantidad de puntos de ira igual a su coste. No puedes tener más puntos de ira que tu nivel de Guerrero. Tus puntos de ira acumulados permanecen durante 1 hora antes de disiparse, devolviendo tu reserva de ira a 0." },
    ["furia de elune"] = {description = "Cuando usas tu acción para lanzar un truco de sacerdote, puedes realizar un ataque con arma como acción adicional.\nPuedes usar este rasgo un número de veces igual a tu modificador de Carisma, mínimo una vez. Recuperas los usos al terminar un descanso corto o largo." },
    ["garrote"] = {description = "Cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar 1 punto de energía para garrotearla. El objetivo debe superar una tirada de salvación de Constitución o no podrá hablar hasta el final de tu siguiente turno." },
    ["golpe de escarcha"] = {description = "Aprendes a potenciar tus ataques con furia invernal. Cuando gastas dados de Poder Rúnico en un golpe rúnico, los dados se convierten en d8 y el golpe rúnico inflige daño frío en lugar de daño necrótico." },
    ["golpe del cruzado"] = {description = "Cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar una ranura de conjuro para infligir daño radiante al objetivo, además del daño del arma. El daño adicional es de 2d8 por un espacio de conjuro de nivel 1, más 1d8 por cada nivel de conjuro superior a 1°, hasta un máximo de 6d8. El daño de Golpe del Cruzado aumenta en 1d8 si el objetivo es un no-muerto o un infernal." },
    ["golpe heroico"] = {description = "Cuando hagas daño con un ataque de arma cuerpo a cuerpo, puedes gastar 1 punto de furia para infligir daño adicional igual a tu modificador de Fuerza." },
    ["golpe runico"] = {description = "Cuando impactas a una criatura con un ataque cuerpo a cuerpo, puedes gastar dados de tu reserva de Poder Rúnico para infligir daño adicional. El tipo de daño es el de tu arma. El daño adicional es igual al resultado de los dados gastados." },
    ["gracia de elune"] = {description = "Como acción adicional, gastas Canalizar Divinidad para bendecir a una criatura a 30 pies durante 1 minuto. Puede usar Destrabarse, Esquivar u Ocultarse como acción adicional. Si te eliges a ti, puedes realizar una de esas acciones al activarla." },
    ["guia ancestral"] = {description = "Siempre que uses un conjuro de nivel 1 o superior para restaurar puntos de golpe a una criatura y saques un 1 o un 2 al lanzar el dado, puedes volver a tirar ese dado y debes usar el nuevo resultado, incluso si es otro 1 o 2." },
    ["himno divino"] = {description = "Puedes usar tu acción y presentar tu símbolo sagrado para evocar energía curativa que puede restaurar un número de PG igual a 5 veces tu nivel de sacerdote.\nElige cualquier criatura en un radio de 30 pies y divide esos PG entre ellas. Esta característica no puede restaurar a una criatura por encima de la mitad de su máximo de puntos de golpe. No puedes usar esta característica en no-muertos o constructos.\n\nUna vez que usas esta característica, no puedes volver a usarla hasta que completes un descanso corto o largo." },
    ["imposicion de manos"] = {description = "Tu toque bendito puede curar heridas. Tienes una reserva de poder curativo que se repone cuando tomas un descanso largo. Con esa reserva, puedes restaurar un número total de puntos de golpe igual a tu nivel de paladín × 5 10.\n\nComo acción, puedes tocar a una criatura y extraer poder de la reserva para restaurar un número de puntos de golpe a esa criatura, hasta la cantidad máxima que quede en tu reserva.\n\nAlternativamente, puedes gastar 5 puntos de golpe de tu reserva de curación para curar al objetivo de una enfermedad o neutralizar un veneno que lo esté afectando. Puedes curar múltiples enfermedades y neutralizar múltiples venenos con un solo uso de Imposición de Manos, gastando puntos de golpe por separado para cada uno.\n\nEsta característica no tiene efecto en muertos vivientes o constructos." },
    ["iniciacion illidari"] = {description = "Eres un iniciado Illidari, habiendo sobrevivido a las pruebas despiadadas de los Illidari y recibido un entrenamiento inaudito en otros lugares. Esto te otorga los siguientes beneficios:\n\n- En tu primer turno del combate, tienes ventaja en las tiradas de ataque contra criaturas que aún no hayan actuado.\n- Puedes tratar las armas cuerpo a cuerpo que no tengan la propiedad de pesada o de dos manos como si tuvieran las propiedades de ligereza y precisión, además de sus otras propiedades.\n- Cuando haces una prueba de Supervivencia relacionada con rastrear una criatura, se considera que tienes competencia en la habilidad de Supervivencia.\n\nAdemás, tienes un odio profundo hacia los seres demoníacos y has sido entrenado para derrotarlos. Esto te otorga los siguientes beneficios adicionales:\n\n- Tienes ventaja en las pruebas de Supervivencia para rastrear a los demonios, así como en las pruebas de Inteligencia para recordar información sobre ellos.\n- Puedes hablar, leer y escribir Eredun." },
    ["intrepido"] = {description = "Tu furia se regenera a medida que la viertes en tus ataques. Recuperas 1 punto de furia al final de tu turno si golpeas a una criatura con un movimiento de furia durante el mismo." },
    ["ira"] = {description = "Puntos máximos 2 || CD Salv 13\nGanas 1 punto de ira cuando infliges daño a una criatura con un ataque de arma que no hayas gastado puntos de ira en él. Puedes gastar estos puntos para realizar diversas maniobras. Para usar una de estas maniobras, debes gastar una cantidad de puntos de ira igual a su coste. No puedes tener más puntos de ira que tu nivel de Guerrero. Tus puntos de ira acumulados permanecen durante 1 hora antes de disiparse, devolviendo tu reserva de ira a 0." },
    ["kalimag"] = {description = "Conoces Kalimag, el idioma de los elementales. Puedes hablar el idioma y usarlo para dejar mensajes en rocas y charcas de agua que solo tú y otros chamanes pueden notar. Los mensajes se transmiten como si fuera un conjuro de mensaje, con las limitaciones de dicho conjuro." },
    ["legado del vacio"] = {description = "Cuando infliges daño a una criatura con un truco de sacerdote, puedes causar daño psíquico adicional igual a tu Mod. Carisma 3.\n\nCuando usas esta característica, debes tener éxito en una tirada de salvación de Sabiduría (CD 10 + 1 por cada uso adicional de esta característica desde el último descanso largo). Si fallas, no podrás usar esta característica nuevamente hasta que termines un descanso largo." },
    ["llamas del caos"] = {description = "Aprendes a manifestar llamas viles puras. Obtienes una nueva opción de ataque que puedes usar con la acción de Ataque.\n\nEste ataque especial es un ataque a distancia con un arma con un alcance de 30 pies. Tienes competencia con él y añades tu modificador de Destreza a sus tiradas de ataque y de daño.\nEn un golpe exitoso, este ataque especial inflige 1d6 de daño por fuego." },
    ["lobo solitario: ataque apuntado"] = {description = "Puedes elegir no domar una bestia y en su lugar enfocarte en tu propia destreza. Cuando no tienes la lealtad de una mascota, puedes usar tu acción adicional para otorgarte ventaja en tu próximo ataque con arma." },
    ["maquina de matar"] = {description = "Tus ataques con armas cuerpo a cuerpo obtienen un golpe crítico con una tirada de 19 o 20.\nAdemás, puedes usar combate con dos armas incluso si las armas cuerpo a cuerpo que empuñas no son ligeras, siempre que no tengan las propiedades de pesada o dos manos." },
    ["marca del cazador"] = {description = "1d4\nPuedes marcar a un objetivo como tu presa. Como acción adicional, elige una criatura que puedas ver a 120 pies de distancia. El objetivo permanece marcado durante 1 hora, hasta que uses esta característica nuevamente o hasta que muera. La marca también termina si caes inconsciente.\n\nUna vez por turno, puedes infligir un daño adicional de 1d4 a esa criatura cuando la golpeas con un ataque con arma. La cantidad de daño adicional aumenta a medida que subes de nivel en esta clase, como se muestra en la columna Marca del Cazador de la tabla de Cazador.\n\nAdemás, tienes ventaja en las pruebas de Sabiduría (Percepción) y Sabiduría (Supervivencia) para encontrar a tu objetivo marcado." },
    ["metamagia"] = {description = "Obtienes la capacidad de modificar tus conjuros para que se ajusten a tus necesidades" },
    ["metamorfosis"] = {description = "Usos 1 || +2\nEres capaz de liberar el poder de tu demonio atado. En tu turno, puedes entrar en metamorfosis como una acción adicional y transformarte en un ser demoníaco.\n\nMientras estés metamorfoseado, obtienes los siguientes beneficios:\n\n- Obtienes un número de puntos de golpe temporales igual a tu nivel de cazador de demonios + Mod Inteligencia 6. Estos puntos de golpe duran mientras esté activa tu metamorfosis.\n- Tienes ventaja en las pruebas de Intimidación.\n- Tus ataques con armas cuentan como mágicos para superar resistencias e inmunidades a ataques y daños no mágicos.\n- Cuando realizas un ataque con arma, infliges daño adicional por fuego que aumenta a medida que subes de nivel en esta clase +2.\n- Tu velocidad de movimiento aumenta en 10 pies.\n\nTu metamorfosis dura 1 minuto. Termina antes si quedas inconsciente. También puedes finalizarla en tu turno como una acción adicional.\n\nPuedes usar esta característica un número de veces igual a tu modificador de Inteligencia (mínimo una vez). Recuperas todos los usos gastados después de un descanso largo." },
    ["misivas secretas"] = {description = "Puedes usar 4 horas para compartir un conjunto de lenguaje criptico con otra criatura, permitiéndote entrelazar mensajes y comandos secretos en tus conversaciones y cartas. Las reglas más elaboradas pueden requerir una prueba de Inteligencia" },
    ["momentum"] = {description = "Puedes gastar 1 punto de vil para realizar la acción de Desengancharse o Correr como acción adicional en tu turno, y tu distancia de salto se duplica durante ese turno." },
    ["mordida de demonio"] = {description = "Inmediatamente después de realizar la acción de Ataque en tu turno, puedes gastar 1 punto de vil para hacer dos ataques con armas como acción adicional. No sumas tu modificador de habilidad al daño de estos ataques." },
    ["mutilar"] = {description = "Inmediatamente después de golpear a una criatura con la acción de Ataque, puedes gastar 1 punto de energía para mutilarla. El objetivo debe superar una tirada de salvación de Fuerza o ser derribado." },
    ["palma aturdidora"] = {description = "Puedes interferir con el flujo de chi en el cuerpo de un oponente. Una vez por turno, cuando golpees a otra criatura con un ataque cuerpo a cuerpo, puedes gastar 1 punto de chi para intentar un golpe aturdidor. El objetivo debe tener éxito en una tirada de salvación de Constitución o quedar aturdido hasta el final de tu próximo turno." },
    ["palma de chi ji"] = {description = "Cuando usas tu característica de Niebla reconfortante, puedes realizar un golpe desarmado como acción adicional, y puedes usar tu Mod. Sabiduría para la tirada de ataque y daño de ese golpe." },
    ["pericia"] = {description = "Acrobacias || Juego de manos\nTu bono de competencia se duplica para las pruebas de habilidad que realices con dos competencias de tu elección." },
    ["piromaniaco"] = {description = "Aprendes el truco Producir llama, que cuentas como un truco de brujo y no cuenta contra tus trucos conocidos.\nAdemás, puedes encender mágicamente un objeto inflamable que toques con tu mano como una acción." },
    ["poder runico"] = {description = "Energías necróticas recorren tu cuerpo que se representa con una reserva de d6 que se recarga tras un descanso largo. El número de dados en esta reserva es igual a 1 + tu nivel de caballero de la muerte 4. Nunca puedes gastar en el mismo turno más dados rúnicos que tu Mod. Carisma (mínimo 1)." },
    ["provocacion"] = {description = "Puedes usar tu Acción para provocar a criaturas en un radio de 30 pies.\nToda criatura que elijas en el rango debe superar una tirada de salvación de Sabiduría contra la CD de tu Furia (13) o tener desventaja en las tiradas de ataque contra criaturas que no seas tú durante 1 minuto.\nUna criatura puede repetir la salvación al final de cada uno de sus turnos, terminando el efecto si tiene éxito.\nUna vez que uses esta característica, no puedes volver a usarla hasta que completes un descanso corto o largo." },
    ["racha de calor"] = {description = "La energía ardiente de tus conjuros se intensifica. Cuando lanzas daño para un conjuro y sacas el número más alto posible en cualquiera de los dados, elige uno de esos dados, lánzalo de nuevo y suma ese resultado al daño. Puedes usar esta característica solo una vez por turno." },
    ["rejuvenecimiento"] = {description = "Recibes las bendiciones de Elune, convirtiéndote en una fuente de energía que ofrece alivio de las heridas. Tienes una reserva de energía representada por un número de d6 igual a tu nivel de druida 3d6.\n\nComo acción adicional, puedes elegir una criatura que puedas ver a 120 pies de ti y gastar un número de esos dados igual a la mitad de tu nivel de druida o menos 1d6. Lanza los dados gastados y súmalos. El objetivo recupera una cantidad de puntos de golpe igual al total. El objetivo también gana 1 punto de golpe temporal por dado.\n\nRecuperas todos los dados gastados cuando terminas un descanso largo." },
    ["renacer oscuro"] = {description = "Como caballero de la muerte, caminas entre el mundo de los vivos y los muertos, existiendo en ambos y en ninguno.\n\n- Eres considerado tanto un humanoide como un no-muerto, lo cual te permite ser afectado por cualquier cosa que afecte a esos tipos de criatura. Por ejemplo, como no-muerto, puedes ser detectado por el Sentido divino de un paladín, pero como humanoide, puedes ser sanado por su Imposición de manos.\n- No necesitas dormir. En su lugar, entras en un estado semi-consciente, alimentando tu hambre eterna recordando el sufrimiento causado. Después de 4 horas en este estado, obtienes los mismos beneficios que un humano tras 8 horas de sueño.\n- Ventaja en las tiradas de salvación contra cualquier efecto que afecte exclusivamente a los no-muertos, como el conjuro Encantar no-muertos de un sacerdote." },
    ["rodar"] = {description = "Puedes rodar por el campo de batalla cuando no estés empuñando un escudo. Una vez por turno, puedes gastar movimiento para rodar una cantidad de metros en línea recta igual al movimiento gastado. Puedes rodar a través del espacio de criaturas hostiles, sin embargo, no puedes terminar tu rodar dentro de su espacio. Cualquier ataque de oportunidad realizado contra ti mientras estás rodando se hace con desventaja." },
    ["secretos profanos"] = {description = "Has pasado largas horas investigando y practicando conocimientos prohibidos, obteniendo los siguientes beneficios:\n\n- Puedes hablar, leer y escribir en Eredun.\n- Tienes ventaja en los chequeos de Inteligencia realizados para recordar información sobre aberraciones, demonios y no muertos.\n- Aplicás tu bonificador de competencia cuando haces un chequeo de Carisma al interactuar con demonios, o el doble de tu bonificador de competencia si eres competente en la habilidad." },
    ["segundo aliento"] = {description = "Dado de golpe ||1d10 por nivel de guerrero\nPuedes recurrir a tu resistencia para protegerte del daño. Como acción adicional, puedes gastar un dado de golpe (1d10) para recuperar puntos de golpe al instante, como si hubieras tomado un descanso corto, recuperando puntos de golpe equivalentes al total + tu modificador de Constitución. Los dados se golpe se recuperan tras un descanso largo." },
    ["sentido divino"] = {description = "La presencia de un mal poderoso se registra en tus sentidos como un hedor nocivo, y el bien poderoso resuena como música celestial en tus oídos. Como acción, puedes abrir tu percepción para detectar tales fuerzas. Hasta el final de tu siguiente turno, conoces la ubicación de cualquier celestial, infernal o no-muerto en un radio de 60 pies que no esté bajo cobertura total. Conoces el tipo (celestial, infernal o no-muerto) de cualquier ser cuya presencia detectes, pero no su identidad (como el demonio Illidan Tempestira, por ejemplo). Dentro del mismo radio, también detectas la presencia de cualquier lugar u objeto que haya sido consagrado o profanado, como con el hechizo santuario. Puedes usar esta característica un número de veces igual a 1 + Mod Carisma 5. Cuando terminas un descanso largo, recuperas todos los usos gastados." },
    ["sentido magico"] = {description = "Tus estudios te enseñaron a percibir la energía mágica residual. Puedes sentir cuando un conjuro fue lanzado en el último hora en tu ubicación actual y ver escritura creada o usada por magia que esté oculta para otros. Mientras entiendas el idioma, también puedes descifrarla y leerla." },
    ["serenidad"] = {description = "Puedes entrar en una postura serena durante 1 minuto cuando usas puntos de chi. Mientras estás en esta postura, usas tu Mod. Sabiduría para tus tiradas de ataque y daño cuando ataques con un arma de monje o tus golpes desarmados.\n\nTu serenidad termina de manera prematura si te vuelves encantado, asustado o incapacitado, o si intentas una tarea más extenuante que interactuar con un objeto." },
    ["toque de vida"] = {description = "Cuando no tienes mana restante, aún puedes lanzar un conjuro como si lo tuvieras. Como parte de la acción para lanzar el conjuro, pierdes puntos de golpe iguales a tu nivel más el nivel de la ranura de conjuro.\nEste daño no puede ser resistido y no puedes usar esta característica si hacerlo te reduciría a 0 puntos de golpe." },
    ["tormenta divina"] = {description = "cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar una ranura de conjuro para infligir daño radiante al objetivo y a todas las criaturas a 5 pies de ti, además del daño del arma. Una criatura puede hacer una tirada de salvación de Destreza, recibiendo la mitad del daño si tiene éxito. El daño adicional es de 2d6 por una ranura de conjuro de 1er nivel, más 1d6 por cada nivel de conjuro superior al 1º, hasta un máximo de 6d6.\n\nUn ataque cuerpo a cuerpo puede beneficiarse de tu Golpe del Cruzado o de tu Tormenta Divina, pero solo uno de estos efectos puede aplicarse a un ataque." },
    ["totemista"] = {description = "2 / descanso\nPuedes usar tu acción adicional para canalizar fuerzas elementales en un tótem Pequeño en un espacio vacío sobre una superficie horizontal a 15 pies de ti.\n\nEl tótem es un objeto mágico que ocupa su espacio. Tiene una CA de 15 y un número de puntos de golpe igual al doble de tu nivel de chamán 6. Es inmune al daño por veneno, daño psíquico y todas las condiciones. Si se ve obligado a realizar un chequeo de característica o una tirada de salvación, todos sus valores de característica son 10 (+0). El tótem desaparece si se reduce a 0 puntos de golpe o tras 1 minuto. Puedes dispararlo antes como una acción adicional.\n\nPuedes usar tu reacción para hacer que el tótem se active si estás a 60 pies de él y eliges uno de sus poderes para que surta efecto. Tu tótem comienza con dos de estos poderes: Resistencia Elemental y un poder determinado por tu Afinidad Elemental. Tu tótem gana un poder adicional al nivel 3, determinado por tu vínculo chamánico.\nPuedes usar tu característica de Totemista dos veces entre descansos. Recuperas todos los usos gastados al finalizar un descanso breve o prolongado. Puedes invocar un tótem adicional entre descansos al alcanzar el nivel 10, y nuevamente al nivel 18." },
    ["vil"] = {description = "Puntos 3 || CD Salvación 13\nPuedes extraer energía vil caótica que duerme en tu interior. Tu acceso a esta fuerza caótica está representado por una cantidad de puntos de vil.\n\nCuando gastas un punto de vil, no estará disponible hasta que termines un descanso corto o largo, al final del cual recuperarás toda tu energía vil gastada." },
    ["vision espectral"] = {description = "Jenn puede percibir las almas y las energías mágicas de los seres vivos. Ve a las criaturas como sombras oscuras con un núcleo brillante que representa su alma, rodeado por el maná y las energías que portan. El uso prolongado de esta percepción fatiga su vista y su mente. Por ello suele cubrir sus ojos con una venda blanca para amortiguar el flujo constante de información espiritual.\n\nPuede identificar de forma aproximada:\n- El tipo de magia predominante de una criatura.\n- Rastros recientes de magia residual.\n- Corrupciones, alteraciones o energías anómalas visibles." },
    ["vista de penumbra"] = {description = "Ganas visión en la oscuridad con un alcance de 60 pies. Si ya tienes visión en la oscuridad debido a tu raza, su alcance aumenta en 30 pies." },
    ["voz psiquica"] = {description = "Puedes penetrar las mentes de otras criaturas. Puedes comunicarte telepáticamente con cualquier criatura que puedas ver a 30 pies de ti. No necesitas compartir un idioma con la criatura para que comprenda tus expresiones telepáticas, pero la criatura debe poder entender al menos un idioma." },
}

local function NormIconKey(v)
    v = HarfordClassColors.StripAccents(v):lower():gsub("[_%-]+", " ")
    return (v:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Devuelve la ruta de icono (Interface\Icons\<X>) para un nombre de rasgo, o nil si no hay.
-- Match: exacto normalizado; si falla, una clave del mapa que EMPIECE por el nombre del rasgo
-- (ej. "Estilo de Combate" -> "estilo de combate gran arma"). El libro cae a un icono generico.
function HarfordDnDData.GetIcon(name)
    local k = NormIconKey(name)
    if k == "" then return nil end
    local presentation = HarfordDnDData.TRP3_PRESENTATION[k] or HarfordDnDData.PRESENTATION[k]
    local id = presentation and presentation.icon or HarfordDnDData.ICONS[k]
    -- Los rasgos del Libro pueden anotar la especializacion entre parentesis
    -- (p.ej. "Canalizar Divinidad (Elune)"). El catalogo conserva el nombre
    -- canonico de TRP3, asi que se intenta tambien sin ese sufijo visual.
    if not id then
        local base = k:gsub("%s*%b()%s*$", "")
        if base ~= k then
            local basePresentation = HarfordDnDData.TRP3_PRESENTATION[base] or HarfordDnDData.PRESENTATION[base]
            id = (basePresentation and basePresentation.icon) or HarfordDnDData.ICONS[base]
        end
    end
    if not id then
        for mapKey, data in pairs(HarfordDnDData.PRESENTATION) do
            if mapKey:find(k, 1, true) == 1 and data.icon then id = data.icon; break end
        end
    end
    if not id then
        for mapKey, mapIcon in pairs(HarfordDnDData.ICONS) do
            if mapKey:find(k, 1, true) == 1 then id = mapIcon; break end
        end
    end
    return id and ("Interface\\Icons\\" .. id) or nil
end

-- Signo de mas coloreado por caracteristica. Los incrementos salian todos con el mismo
-- dibujo, y cada uno sube una cosa distinta. El color va por la clase que encarna esa
-- caracteristica: guerrero la Fuerza, picaro la Destreza, mago la Inteligencia.
local SIGNO_CARACTERISTICA = {
    fuerza       = "Interface\\Icons\\hd_plussign_warrior",
    destreza     = "Interface\\Icons\\hd_plussign_rogue",
    constitucion = "Interface\\Icons\\hd_plussign_deathknight",
    inteligencia = "Interface\\Icons\\hd_plussign_mage",
    sabiduria    = "Interface\\Icons\\hd_plussign_monk",
    carisma      = "Interface\\Icons\\hd_plussign_paladin",
}
local SIGNO_SIN_ASIGNAR = "Interface\\Icons\\hd_plussign_priest"
local SIGNO_MEJORA      = "Interface\\Icons\\hd_plussign_hunter"

local function AbilityKey(value)
    value = HarfordClassColors and HarfordClassColors.StripAccents
        and HarfordClassColors.StripAccents(tostring(value or "")) or tostring(value or "")
    return value:lower():gsub("%s+", "")
end

-- Devuelve el signo del color que le toca a un rasgo de caracteristica, o nil si no lo es.
-- A diferencia de la web, aqui SI se sabe que ha elegido el jugador, asi que un incremento
-- a eleccion deja de ser gris en cuanto se resuelve.
local function AbilitySignIcon(feature)
    local name = AbilityKey(feature.name)
    -- El rasgo de idiomas lleva siempre la misma nota, este en una raza, una subraza o un
    -- trasfondo. Va por nombre y no por id porque son cuarenta repartidos por todo el libro.
    if name:match("^idiomas?") then return "Interface\\Icons\\inv_misc_note_05" end
    if name:find("mejoradecaracteristica", 1, true) then return SIGNO_MEJORA end
    if not name:find("incrementodecaracteristica", 1, true) then return nil end

    -- "Destreza +2 y Sabiduria +1" sube dos cosas y no hay un color que represente eso,
    -- asi que va el verde de mejora, el mismo que el ASI de clase. Cuando el rasgo se
    -- parta en dos pasivas, cada una recuperara su color sola.
    local primero, distintas = nil, 0
    local vistas = {}
    for _, effect in ipairs(feature.effects or {}) do
        if effect.kind == "bonus" and effect.target == "ability" and effect.ability then
            local key = AbilityKey(effect.ability)
            if SIGNO_CARACTERISTICA[key] and not vistas[key] then
                vistas[key] = true
                distintas = distintas + 1
                primero = primero or SIGNO_CARACTERISTICA[key]
            end
        end
    end
    if distintas > 1 then return SIGNO_MEJORA end
    if primero then return primero end

    local choice = feature.choice
    if type(choice) == "table" and tostring(choice.optionsFrom or ""):match("^ability%+%d+$")
        and HarfordDnDProgression and HarfordDnDProgression.GetChoice then
        -- el id de opcion de un ASI es el nombre de la caracteristica ("Fuerza")
        for _, chosen in ipairs(HarfordDnDProgression.GetChoice(feature.id) or {}) do
            local icon = SIGNO_CARACTERISTICA[AbilityKey(chosen)]
            if icon then return icon end
        end
    end
    return SIGNO_SIN_ASIGNAR
end

function HarfordDnDData.GetFeatureIcon(feature)
    if type(feature) ~= "table" then return nil end
    local signo = AbilitySignIcon(feature)
    if signo then return signo end
    local icon = IconCatalog and IconCatalog.GetFeatureIcon and IconCatalog.GetFeatureIcon(feature.id)
    if icon then return icon end
    -- Arte declarada en los propios datos del rasgo (los de raza y trasfondo la traen). El catalogo
    -- manda sobre ella, pero esto va ANTES del respaldo por nombre: si no, un rasgo con su icono
    -- puesto acababa cogiendo el de otro que se llamase parecido, o ninguno.
    local propio = feature.icon
    if type(propio) == "number" then return propio end
    if type(propio) == "string" and propio ~= "" then
        if propio:find(string.char(92), 1, true) then return propio end
        local sep = string.char(92)   -- barra invertida: la ruta de textura de WoW la exige
        return "Interface" .. sep .. "Icons" .. sep .. propio
    end
    return HarfordDnDData.GetIcon(feature.name)
end

function HarfordDnDData.GetPresentation(name)
    local key = NormIconKey(name)
    if key == "" then return nil end
    local presentation = HarfordDnDData.TRP3_PRESENTATION[key] or HarfordDnDData.PRESENTATION[key]
    if presentation then return presentation end
    local base = key:gsub("%s*%b()%s*$", "")
    if base ~= key then
        return HarfordDnDData.TRP3_PRESENTATION[base] or HarfordDnDData.PRESENTATION[base]
    end
    return nil
end

function HarfordDnDData.GetSubclassIcon(classId, subclassId)
    local catalogIcon = IconCatalog and IconCatalog.GetSubclassIcon and IconCatalog.GetSubclassIcon(classId, subclassId)
    if catalogIcon then return catalogIcon end
    return nil
end

-- Idiomas de Warcraft 5a (tabla "Idiomas" del manual). `exotic` distingue los exoticos,
-- que algunas elecciones no ofrecen.
HarfordDnDData.LANGUAGES = {
    { id="idioma_comun", name="Comun" },
    { id="idioma_darnassiano", name="Darnassiano" },
    { id="idioma_draenei", name="Draenei" },
    { id="idioma_enano", name="Enano" },
    { id="idioma_goblin", name="Goblin" },
    { id="idioma_gnomico", name="Gnomico" },
    { id="idioma_visceralico", name="Visceralico" },
    { id="idioma_orco", name="Orco" },
    { id="idioma_pandaren", name="Pandaren" },
    { id="idioma_shalassiano", name="Shalassiano" },
    { id="idioma_taurahe", name="Taur-ahe" },
    { id="idioma_thalassiano", name="Thalassiano" },
    { id="idioma_zandali", name="Zandali" },
    { id="idioma_draconico", name="Draconico", exotic=true },
    { id="idioma_eredun", name="Eredun", exotic=true },
    { id="idioma_kalimag", name="Kalimag", exotic=true },
    { id="idioma_bajocomun", name="Bajo Comun", exotic=true },
    { id="idioma_ogro", name="Ogro", exotic=true },
    { id="idioma_shathyar", name="Shath'Yar", exotic=true },
    { id="idioma_titanico", name="Titanico", exotic=true },
    -- Lengua secreta de los druidas: la concede la clase, no se elige.
    { id="idioma_druidico", name="Druidico", exotic=true },
}
