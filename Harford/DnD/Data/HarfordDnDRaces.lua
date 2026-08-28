-- HarfordDnDRaces: libro hardcodeado de razas (World of Warcraft D&D 5ª Ed. ES).
-- Solo datos + helpers puros. Los rasgos raciales son "features" con el mismo
-- formato que los de clase (id/name/type/description/effects/choice), para reusar
-- el motor de efectos (HarfordDnDFeatureEffects) y la UI de la pestaña Clases.
--
-- Incrementos de caracteristica -> effects { kind="bonus", target="ability", ... }
-- o un `choice` (optionsFrom = "ability+2"/"ability+1") cuando son a eleccion.
-- Lo no automatizable va como `informativo` con su texto del manual.

HarfordDnDRaces = HarfordDnDRaces or {}

local API = HarfordDnDRaces

local function WeaponProfEffects(...)
    local out = {}
    for i = 1, select("#", ...) do
        out[#out + 1] = { kind = "weaponProf", weapon = select(i, ...) }
    end
    return out
end

-- faction: "alianza" | "horda" | "aliada"
API.RACES = {
    {
        id = "raza_humano", name = "Humano", nameF = "Humana", desc = "Versatiles y ambiciosos; sus vidas breves los empujan a grandes logros y han forjado los mayores reinos de Azeroth.", faction = "alianza", size = "Mediano", speed = 9,
        traits = {
            { id = "hum_inc_2", name = "Incremento de caracteristica (+2)", type = "choice", description = "Una característica de tu elección aumenta en 2.", effects = {}, choice = { slots = 1, optionsFrom = "ability+2" } },
            { id = "hum_inc_1", name = "Incremento de caracteristica (+1)", type = "choice", description = "Otra característica de tu elección aumenta en 1.", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
            { id = "hum_determinacion", name = "Determinacion", type = "informativo", description = "Cuando realices una tirada de ataque, una prueba de habilidad o una tirada de salvación, puedes hacerlo con ventaja. No puedes hacerlo de nuevo hasta que termines un descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            { id = "hum_espiritu", name = "Espiritu Humano", type = "pasivo", description = "Cuando saques un 1 en una tirada de ataque, prueba de habilidad o tirada de salvación, puedes volver a tirar el dado. Debes usar el nuevo resultado, incluso si es un 1. No puedes hacerlo de nuevo hasta que termines un descanso largo.", effects = {} },
            { id = "hum_versatilidad", name = "Versatilidad de habilidades", type = "choice", description = "Competencia en dos habilidades de tu elección.", effects = {}, choice = { slots = 2, optionsFrom = "skillProf" } },
            { id = "hum_idiomas", name = "Idiomas", type = "choice", description = "Hablas, lees y escribes Comun y un idioma adicional de tu elección.", effects = { { kind = "language", language = "Comun" } }, choice = { slots = 1, optionsFrom = "language" } },
        },
    },
    {
        id = "raza_enano", name = "Enano", nameF = "Enana", desc = "Pueblo de las montanas de Khaz Modan, ligado al clan y la tradicion, maestro de la piedra, la forja y la mineria.", faction = "alianza", size = "Mediano", speed = 7.5,
        subraces = {
            { id = "raza_enano_forjaz", name = "Enano de Forjaz", nameF = "Enana de Forjaz", desc = "Robustos y tradicionales enanos de Forjaz, firmes como la piedra y maestros de la forja y la mineria.", traits = {
                { id = "ena_forjaz_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "ena_forjaz_dureza", name = "Dureza enana", type = "pasivo", description = "Tus PG máximos aumentan en 1, y +1 cada vez que subes de nivel.", effects = {} },
                { id = "ena_forjaz_piedra", name = "Forma de piedra", type = "informativo", description = "Reaccion al recibir un ataque cuerpo a cuerpo: resistencia a fisico hasta tu proximo turno. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "raza_enano_martillo_salvaje", name = "Enano Martillo Salvaje", nameF = "Enana Martillo Salvaje", desc = "Enanos libres de las alturas, jinetes de grifos de espíritu salvaje y vínculo con la naturaleza.", traits = {
                { id = "ena_mart_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Sabiduría +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "ena_mart_altura", name = "Residencia en altura", type = "pasivo", description = "Acostumbrado a grandes altitudes y al frío.", effects = {} },
                { id = "ena_mart_valentia", name = "Valentia irrazonable", type = "pasivo", description = "Ventaja en tiradas de salvación contra el miedo.", effects = {} },
                { id = "ena_mart_domador", name = "Domador natural", type = "pasivo", description = "Competencia en Trato con Animales y en tiradas hacia grifos.", effects = { { kind = "skillProf", skill = "Animales" } } },
            } },
            { id = "raza_enano_hierro_negro", name = "Enano Hierro Negro", nameF = "Enana Hierro Negro", desc = "Enanos oscuros ligados al fuego y la magia, antano siervos de Ragnaros en las profundidades.", traits = {
                { id = "ena_hn_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +1.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                { id = "ena_hn_sangre", name = "Sangre de fuego", type = "informativo", description = "Lanzas restauración menor en ti mismo una vez al día.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "ena_hn_forjado", name = "Forjado en llamas", type = "pasivo", description = "Resistencia al daño por fuego.", effects = {
                    { kind = "resist", damage = "fuego" },
                } },
                { id = "ena_hn_vision", name = "Vision en la oscuridad superior", type = "pasivo", description = "Visión en la oscuridad de 36 metros.", effects = {} },
            } },
        },
        traits = {
            { id = "ena_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +2.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 2 } } },
            { id = "ena_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Ves en luz tenue a 18 metros como luz brillante y en oscuridad como luz tenue (tonos de gris).", effects = {} },
            { id = "ena_entrenamiento", name = "Entrenamiento de combate Enano", type = "pasivo", description = "Competencia con hacha de batalla, hacha de mano, martillo de guerra, pistolas y rifles.", effects = WeaponProfEffects("hacha de batalla", "hacha de mano", "martillo de guerra", "pistolas", "rifles") },
            { id = "ena_piedra", name = "Conocimiento de la piedra", type = "pasivo", description = "En pruebas de Historia sobre mamposteria, competente y sumas el doble de tu bono de competencia.", effects = {} },
            { id = "ena_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Enano.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Enano" } } },
        },
    },
    {
        id = "raza_elfo_noche", name = "Elfo de la Noche", nameF = "Elfa de la Noche", desc = "Kaldorei antiguos y orgullosos, primeros estudiosos de la magia; hoy guardianes de la naturaleza y devotos de Elune.", faction = "alianza", size = "Mediano", speed = 10.5,
        subraces = {
            { id = "raza_elfo_noche_altonato", name = "Altonato", nameF = "Altonata", desc = "Kaldorei de Eldre'Thalas (los Shen'dralar/Altonato), eruditos arcanos de la antigua Dire Maul; conservan un saber mágico vedado al resto de los suyos.", traits = {
                { id = "eln_alt_conocimiento", name = "Conocimiento antiguo de eldre'thalas", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia. Además duplicas tu bono de competencia en Historia en tiradas relacionadas con civilizaciones antiguas o artefactos.", effects = {
                    { kind = "skillProf", skill = "Arcano" },
                    { kind = "skillProf", skill = "Historia" },
                } },
                { id = "eln_alt_erudito", name = "Erudito arcano", type = "pasivo", description = "Conoces el truco Mano de mago. A nivel 3 puedes lanzar Detectar magia 1 vez al día; a nivel 5, Identificar 1 vez al día. La característica para estos conjuros es Inteligencia.", effects = {} },
                { id = "eln_alt_proteccion", name = "Proteccion mental", type = "pasivo", description = "Ventaja en todas las tiradas de salvación de Inteligencia, Sabiduría y Carisma contra magia.", effects = {} },
            } },
        },
        traits = {
            { id = "eln_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +2 y Sabiduría +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },
            } },
            { id = "eln_vision", name = "Vision en la oscuridad superior", type = "pasivo", description = "Puedes ver en penumbra hasta 36 metros como luz brillante y en oscuridad como penumbra, todo en un tono violeta.", effects = {} },
            { id = "eln_armas", name = "Entrenamiento con armas Kaldorei", type = "pasivo", description = "Competencia con arco largo, espada lunar, glaive lunar y glaive de guerra.", effects = WeaponProfEffects("arco largo", "espada lunar", "glaive lunar", "glaive de guerra") },
            { id = "eln_sentidos", name = "Sentidos agudos", type = "pasivo", description = "Competencia en Percepción.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "eln_mascara", name = "Mascara de lo salvaje", type = "pasivo", description = "Puedes ocultarte cuando estés ligeramente cubierto por elementos naturales.", effects = {} },
            { id = "eln_fusion", name = "Fusion con las sombras", type = "pasivo", description = "Ventaja en tiradas de Sigilo al estar completamente oculto por la oscuridad.", effects = {} },
            { id = "eln_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Darnassiano.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Darnassiano" } } },
        },
    },
    {
        id = "raza_semielfo", name = "Semielfo", nameF = "Semielfa", desc = "Hijos de dos mundos, mezcla de humano y elfo; combinan la versatilidad humana con la gracia y el legado arcano élfico.", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "sme_espiritu", name = "Espiritu mestizo", type = "pasivo", description = "Cuando obtienes un 1 en una tirada de ataque, prueba de característica o tirada de salvación, puedes repetir el dado. Debes usar el nuevo resultado aunque sea un 1. No puedes hacerlo de nuevo hasta que termines un descanso largo.", effects = {} },
            { id = "sme_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Puedes ver en la oscuridad hasta 60 pies.", effects = {} },
            { id = "sme_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Tienes competencia en la habilidad de Conocimiento Arcano. Además, puedes lanzar el conjuro Detectar magia una vez al día. La Inteligencia es tu característica de lanzamiento para este conjuro.", uses = { max = 1, recharge = "long" }, spellGrants = { { level = 1, ids = { "detectar_magia" }, ability = "Inteligencia", note = "1/dia" } }, effects = {
                { kind = "skillProf", skill = "Arcano" },
            } },
            { id = "sme_legado", name = "Legado elfico", type = "pasivo", description = "Conoces un truco de mago a tu elección (característica Inteligencia).", effects = {} },
        },
    },
    {
        id = "raza_gnomo", name = "Gnomo", nameF = "Gnoma", desc = "Raza diminuta de ingenieros e inventores subterraneos, celebres por su ingenio mecanico y su curiosidad insaciable.", faction = "alianza", size = "Pequeño", speed = 7.5,
        subraces = {
            { id = "raza_gnomo_gnomeregan", name = "Gnomo de Gnomeregan", nameF = "Gnoma de Gnomeregan", desc = "Los brillantes ingenieros e inventores clasicos, mentes inquietas de Gnomeregan.", traits = {
                { id = "gno_gnom_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Carisma +1.", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
                { id = "gno_gnom_mente", name = "Mente expansiva", type = "pasivo", description = "Sumas la mitad de tu bono de competencia en pruebas de Inteligencia sin competencia.", effects = {} },
                { id = "gno_gnom_ingenieria", name = "Ingenieria gnomica", type = "pasivo", description = "Competencia con herramientas de artesano; creas pequeños dispositivos con efectos simples.", effects = {
                    { kind = "toolProf", tool = "Herramientas de artesano" },
                } },
            } },
            { id = "raza_gnomo_mecagnomo", name = "Mecagnomo", nameF = "Mecagnoma", desc = "Gnomos parcialmente mecanizados, con miembros y mejoras de metal integrados en su cuerpo.", traits = {
                { id = "gno_mec_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "gno_mec_mejoras", name = "Mejoras mecanicas", type = "choice", description = "Elige una mejora (otra al nivel 5).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "emergencia",  label = "Sistema de Emergencia (curacion una vez/descanso largo)", effects = {} },
                        { id = "vision",      label = "Vision Mejorada (vision en la oscuridad 18 m)", effects = {} },
                        { id = "piernas",     label = "Piernas Mecanicas (velocidad 9 m; duplicar 1/turno)", effects = {} },
                        { id = "brazos",      label = "Brazos Mecanicos (golpe desarmado 1d6 + herramienta)", effects = {} },
                        { id = "resiliencia", label = "Resiliencia Metalica (sin armadura, CA 13 + Des)", effects = {} },
                        { id = "generador_luz", label = "Generador de Luz Hiperorganica (truco Ilusion menor)", effects = {} },
                    },
                } },
            } },
        },
        traits = {
            { id = "gno_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +2.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 2 } } },
            { id = "gno_artifice", name = "Conocimientos del artifice", type = "pasivo", description = "Doble bono de competencia en Inteligencia (Historia) sobre objetos magicos, alquimicos o tecnologicos.", effects = {} },
            { id = "gno_escapista", name = "Escapista", type = "pasivo", description = "Desenganche como accion adicional cada turno; ventaja para evitar/terminar apresado.", effects = {} },
            { id = "gno_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Gnomico.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Gnomico" } } },
        },
    },
    {
        id = "raza_draenei", name = "Draenei", desc = "Eredar que huyeron de la Legion guiados por la Luz Sagrada; viajeros de mundo en mundo, sabios y devotos.", faction = "alianza", size = "Mediano", speed = 9,
        subraces = {
            { id = "raza_draenei_exodar", name = "Draenei del Exodar", desc = "Draenei devotos portadores del don de los Naaru y de la Luz Sagrada.", traits = {
                { id = "dra_exo_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "dra_exo_gemas", name = "Tallado de gemas", type = "pasivo", description = "Competencia con herramientas de joyero.", effects = {
                    { kind = "toolProf", tool = "Herramientas de joyero" },
                } },
                { id = "dra_exo_naaru", name = "Don de los Naaru", type = "informativo", description = "Accion: tocas y curas (= tu nivel). 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "dra_exo_heroica", name = "Presencia heroica", type = "informativo", description = "Lanzas heroismo y favor divino usando Sabiduría. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "raza_draenei_forjado_luz", name = "Draenei Forjado por la Luz", nameF = "Draenei Forjada por la Luz", desc = "Cruzados imbuidos de Luz Sagrada, forjados como arma viviente contra la Legion Ardiente.", traits = {
                { id = "dra_fl_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "dra_fl_forjado", name = "Forjado en Luz", type = "pasivo", description = "Sin armadura, tu CA es 12 + Mod. Destreza.", effects = {} },
                { id = "dra_fl_resistencia", name = "Resistencia sagrada", type = "pasivo", description = "Resistencia al daño radiante.", effects = {
                    { kind = "resist", damage = "radiante" },
                } },
                { id = "dra_fl_juicio", name = "Juicio de la Luz", type = "pasivo", description = "Conoces luz; a niveles 3/5 lanzas rayo guiador / golpe de marca (Sabiduría).", effects = {} },
            } },
            { id = "raza_draenei_tabido", name = "Draenei Tabido", nameF = "Draenei Tábida", desc = "Draenei rotos por la energia vil; marginados pero resistentes y perseverantes.", traits = {
                { id = "dra_tab_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Sabiduría +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "dra_tab_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Visión en la oscuridad a 18 metros (tonos de gris).", effects = {} },
                { id = "dra_tab_elemental", name = "Vinculo elemental", type = "pasivo", description = "Conoces escarcha; a niveles 3/5 lanzas temblor de tierra / rafaga de viento (Sabiduría).", effects = {} },
                { id = "dra_tab_paria", name = "Paria", type = "pasivo", description = "Competencia en Supervivencia.", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
            } },
            { id = "raza_draenei_man_ari", name = "Man'ari", desc = "Draenei corrompidos por la energia vil de la Legion Ardiente; cuerpo y alma alterados por fuerzas infernales. Algunos aun caminan por Azeroth buscando redencion... o poder.", traits = {
                { id = "dra_man_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Sabiduría +2 y Constitución +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 },
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                } },
                { id = "dra_man_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Ves en la oscuridad a 18 metros (60 pies) como si fuera luz tenue; en oscuridad total ves en escala de grises.", effects = {} },
                { id = "dra_man_resiliencia", name = "Resiliencia vil", type = "pasivo", description = "Resistencia al daño por fuego.", effects = {
                    { kind = "resist", damage = "fuego" },
                } },
                { id = "dra_man_magia", name = "Magia vil", type = "pasivo", description = "Conoces el truco Taumaturgia. A nivel 3 puedes lanzar Reprension Infernal 1/descanso largo; a nivel 5, Oscuridad 1/descanso largo. La característica para estos conjuros es Carisma.", effects = {} },
                { id = "dra_man_presencia", name = "Presencia retorcida", type = "pasivo", description = "Competencia en Intimidación. Además tienes desventaja en tiradas de Persuasión contra criaturas de alineamiento bueno o que usen la Luz abiertamente, salvo que ocultes tu naturaleza.", effects = {
                    { kind = "skillProf", skill = "Intimidacion" },
                } },
            } },
        },
        traits = {
            { id = "dra_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Carisma +2.", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 2 } } },
            { id = "dra_sombras", name = "Resistencia a las sombras", type = "pasivo", description = "Resistencia al daño necrótico.", effects = {
                { kind = "resist", damage = "necrotico" },
            } },
            { id = "dra_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Draenei.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Draenei" } } },
        },
    },
    {
        id = "raza_huargen", name = "Huargen", desc = "Lobos humanoides nacidos de una maldicion druidica; conservan su humanidad bajo una ferocidad salvaje.", faction = "alianza", size = "Mediano", speed = 9,
        traits = {
            { id = "hua_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +2 y Destreza +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },
            } },
            { id = "hua_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Puedes ver en luz tenue hasta 18 metros como si fuera luz brillante, y en la oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.", effects = {} },
            { id = "hua_mordida", name = "Mordida", type = "pasivo", description = "En forma huargen, si aciertas en un ataque desarmado, infliges 1d6 + Mod. Fuerza de daño.", effects = {} },
            { id = "hua_oido", name = "Oido y olfato agudo", type = "pasivo", description = "Ventaja en las pruebas de Percepción que dependan del oído o el olfato.", effects = {} },
            { id = "hua_cazador", name = "Conocimiento del Cazador", type = "choice", description = "Competencia en una habilidad a elegir.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "animales",     label = "Trato con Animales", effects = { { kind = "skillProf", skill = "Animales" } } },
                    { id = "naturaleza",   label = "Naturaleza",         effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                    { id = "percepcion",   label = "Percepcion",         effects = { { kind = "skillProf", skill = "Percepcion" } } },
                    { id = "sigilo",       label = "Sigilo",             effects = { { kind = "skillProf", skill = "Sigilo" } } },
                    { id = "supervivencia", label = "Supervivencia",     effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                },
            } },
            { id = "hua_salto", name = "Salto de pie", type = "pasivo", description = "En forma huargen, puedes realizar un salto largo de hasta 9 metros y un salto alto de hasta 6 metros, con o sin carrera.", effects = {} },
            { id = "hua_dos_formas", name = "Dos formas", type = "pasivo", description = "Puedes transformarte en humano en 1 minuto. En esta forma, te ves igual que antes de la maldición. Puedes volver a la forma de huargen como una acción gratuita.", effects = {} },
            { id = "hua_idiomas", name = "Idiomas", type = "choice", description = "Hablas, lees y escribes Comun y un idioma adicional de tu elección.", effects = { { kind = "language", language = "Comun" } }, choice = { slots = 1, optionsFrom = "language" } },
        },
    },
    {
        id = "raza_orco", name = "Orco", nameF = "Orca", desc = "Guerreros de honor y fuerza que rompieron el ansia de sangre de la Legion y reconstruyeron la Horda con el chamanismo.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "raza_orco_cazadores", name = "Clanes Cazadores", desc = "Orcos de los clanes cazadores: emboscadores agiles y rastreadores letales.", traits = {
                { id = "orc_caz_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +1.", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 } } },
                { id = "orc_caz_emboscador", name = "Emboscador", type = "pasivo", description = "Competencia en Sigilo.", effects = { { kind = "skillProf", skill = "Sigilo" } } },
                { id = "orc_caz_sorpresa", name = "Ataque sorpresa", type = "pasivo", description = "Si sorprendes y atacas en tu primer turno, +1d6 de daño (sube con nivel). Activa el daño extra desde el boton de daño condicional al atacar por sorpresa.", effects = {
                    { kind = "conditionalWeaponDamage", id = "surprise_attack", label = "Ataque Sorpresa", count = 1, die = 6 },
                } },
            } },
            { id = "raza_orco_misticos", name = "Clanes Misticos", desc = "Orcos de los clanes misticos: videntes y chamanes en contacto con los ancestros y los elementos.", traits = {
                { id = "orc_mis_inc", name = "Incremento de caracteristica", type = "choice", description = "Inteligencia o Sabiduría +1.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "inteligencia", label = "Inteligencia +1", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                        { id = "sabiduria",    label = "Sabiduria +1",    effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                    },
                } },
                { id = "orc_mis_llamado", name = "Llamado ancestral", type = "informativo", description = "Lanzas augurio una vez por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "orc_mis_conocimientos", name = "Conocimientos misticos", type = "choice", description = "Competencia en Arcano, Historia, Naturaleza o Religión.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "arcano",     label = "Conocimiento Arcano", effects = { { kind = "skillProf", skill = "Arcano" } } },
                        { id = "historia",   label = "Historia",            effects = { { kind = "skillProf", skill = "Historia" } } },
                        { id = "naturaleza", label = "Naturaleza",          effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                        { id = "religion",   label = "Religion",            effects = { { kind = "skillProf", skill = "Religion" } } },
                    },
                } },
            } },
            { id = "raza_orco_guerreros", name = "Clanes Guerreros", desc = "Orcos de los clanes guerreros: brutales y agresivos en la primera linea de batalla.", traits = {
                { id = "orc_gue_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "orc_gue_agresivo", name = "Agresivo", type = "pasivo", description = "Accion adicional: muevete hasta tu velocidad hacia un enemigo visible.", effects = {} },
                { id = "orc_gue_salvajes", name = "Ataques salvajes", type = "pasivo", description = "Al hacer un golpe crítico, tira un dado de daño adicional del arma.", effects = {
                    { kind = "flag", flag = "savageCritDie" },
                } },
            } },
        },
        traits = {
            { id = "orc_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +1 y Constitución +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 },
                { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
            } },
            { id = "orc_amenazante", name = "Amenazante", type = "pasivo", description = "Competencia en Intimidación.", effects = { { kind = "skillProf", skill = "Intimidacion" } } },
            { id = "orc_armas", name = "Entrenamiento con armas orcas", type = "pasivo", description = "Competencia con hacha de mano, hacha de batalla y garra de guerra.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "garra de guerra") },
            { id = "orc_resistencia", name = "Resistencia implacable", type = "informativo", description = "Al caer a 0 PG sin morir, puedes quedarte en 1 PG. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            { id = "orc_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Orco.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Orco" } } },
        },
    },
    {
        id = "raza_renegado", name = "Renegado", nameF = "Renegada", desc = "Humanos y elfos no-muertos liberados del Rey Exanime; una fuerza oscura de Entranas, aliada de la Horda por conveniencia.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "raza_renegado_humano", name = "Renegado Humano", nameF = "Renegada Humana", desc = "La mayoría de los Renegados: humanos no-muertos, decididos y versatiles tras su muerte.", traits = {
                { id = "ren_hum_inc", name = "Incremento de caracteristica", type = "choice", description = "Una característica de tu elección +1.", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
                { id = "ren_hum_determinacion", name = "Determinacion", type = "informativo", description = "Repites una tirada de ataque/prueba/salvación con ventaja. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "ren_hum_versatilidad", name = "Versatilidad", type = "choice", description = "Competencia en una habilidad de tu elección.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            } },
            { id = "raza_renegado_elfo", name = "Renegado Elfo", nameF = "Renegada Elfa", desc = "Renegados de origen élfico, agiles y afilados, que conservan parte de su gracia en la no-muerte.", traits = {
                { id = "ren_elf_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +1.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                { id = "ren_elf_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Arcano; lanzas detectar magia (Inteligencia) 1 vez por descanso.", spellGrants = { { level = 1, ids = { "detectar_magia" }, ability = "Inteligencia", note = "1/dia" } }, effects = { { kind = "skillProf", skill = "Arcano" } } },
                { id = "ren_elf_idioma", name = "Idioma extra", type = "pasivo", description = "Hablas, lees y escribes Thalassiano.", effects = {} },
            } },
        },
        traits = {
            { id = "ren_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +2.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 2 } } },
            { id = "ren_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Visión en la oscuridad a 18 metros (tonos de gris).", effects = {} },
            { id = "ren_descanso", name = "Descanso de la tumba", type = "pasivo", description = "Para un descanso largo, basta con 6 horas de actividad ligera (no duermes).", effects = {} },
            { id = "ren_naturaleza", name = "Naturaleza no-muerta", type = "pasivo", description = "Eres no-muerto (cuentas como humanoide para lo que no afecta a no-muertos); ventaja y resistencia a veneno; no necesitas comer/beber/respirar/dormir.", effects = {
                { kind = "resist", damage = "veneno" },
                { kind = "conditionImmunity", condition = "poisoned" },
                { kind = "conditionImmunity", condition = "sleeping" },
            } },
            { id = "ren_voluntad", name = "Voluntad de los renegados", type = "pasivo", description = "Ventaja en salvaciones contra encantamiento y efectos que vuelven a los no-muertos.", effects = {} },
            { id = "ren_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Visceralico.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Visceralico" } } },
        },
    },
    {
        id = "raza_tauren", name = "Tauren", desc = "Pueblo espiritual y nomada de las llanuras de Kalimdor; chamanes, cazadores y guerreros en comunion con la naturaleza.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "raza_tauren_mulgore", name = "Tauren de Mulgore", desc = "Los tauren clasicos de las llanuras de Mulgore: espirituales, pacificos pero formidables.", traits = {
                { id = "tau_mul_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Sabiduría +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "tau_mul_resistencia", name = "Resistencia", type = "pasivo", description = "Tus PG máximos aumentan en 1 y +1 cada nivel.", effects = {} },
                { id = "tau_mul_pisoton", name = "Pisoton de guerra", type = "informativo", description = "Lanzas temblor de tierra 1 vez por descanso largo (Fuerza).", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "raza_tauren_monte_alto", name = "Tauren de Monte Alto", desc = "Tauren astados de Monte Alto, fuertes vinculados a la tierra y herederos del legado de Huln.", traits = {
                { id = "tau_ma_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Sabiduría +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "tau_ma_montanes", name = "Montanes", type = "pasivo", description = "Adaptado a grandes altitudes y climas frios.", effects = {} },
                { id = "tau_ma_tenacidad", name = "Tenacidad rugosa", type = "informativo", cast = "reaccion", reactionTrigger = "damage_taken", reactionEffect = "reduce_damage_roll", reactionDice = "1d12", reactionFlat = "half_level", description = "Reaccion: reduces el daño en 1d12 + mitad de tu nivel. Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            } },
            { id = "raza_tauren_taunka", name = "Taunka", desc = "Tauren curtidos de Rasganorte, pragmaticos supervivientes de climas implacables.", traits = {
                { id = "tau_tau_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "tau_tau_frio", name = "Resistencia al frio", type = "pasivo", description = "Resistencia al daño por frío.", effects = {
                    { kind = "resist", damage = "frio" },
                } },
                { id = "tau_tau_atleta", name = "Atleta natural", type = "pasivo", description = "Competencia en Atletismo.", effects = { { kind = "skillProf", skill = "Atletismo" } } },
                { id = "tau_tau_tundra", name = "Caminante de la tundra", type = "pasivo", description = "Te mueves por terreno dificil de hielo o nieve sin coste adicional.", effects = {} },
            } },
        },
        traits = {
            { id = "tau_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +2.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 } } },
            { id = "tau_cuernos", name = "Cuernos", type = "pasivo", description = "Arma natural: golpe desarmado que inflige 1d6 + Mod. Fuerza perforante.", effects = {} },
            { id = "tau_construccion", name = "Construccion poderosa", type = "pasivo", description = "Cuentas como una categoria de tamaño mayor para carga/empujar/arrastrar/levantar.", effects = {} },
            { id = "tau_armas", name = "Entrenamiento de armas Tauren", type = "pasivo", description = "Competencia con alabarda, tótem de batalla, pistola y rifle.", effects = WeaponProfEffects("alabarda", "totem de batalla", "pistolas", "rifles") },
            { id = "tau_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Taur-ahe.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Taur-ahe" } } },
        },
    },
    {
        id = "raza_trol", name = "Trol", desc = "Pueblo antiguo, supersticioso y resistente, de rapida regeneracion; tribus dispersas de jungla, hielo y desierto.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "raza_trol_jungla", name = "Troll de la Jungla", desc = "Trolls Lanza Negra: vudu, astucia y resistencia, aliados leales de la Horda.", traits = {
                { id = "tro_jun_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1 y Sabiduría +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                    { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },
                } },
                { id = "tro_jun_berserker", name = "Berserker", type = "informativo", description = "Accion adicional para un ataque o truco. Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "tro_jun_voodoo", name = "Da voodoo shuffle", type = "pasivo", description = "Te mueves por terreno dificil no mágico sin coste adicional.", effects = {} },
                { id = "tro_jun_armas", name = "Entrenamiento con armas Troll", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "dagas", "jabalinas") },
            } },
            { id = "raza_trol_zandalari", name = "Troll Zandalari", desc = "Trolls del antiguo imperio, orgullosos y devotos de los loa, herederos de una civilizacion milenaria.", traits = {
                { id = "tro_zan_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Sabiduría +2.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 } } },
                { id = "tro_zan_conocimiento", name = "Conocimiento antiguo", type = "pasivo", description = "Competencia en Historia.", effects = { { kind = "skillProf", skill = "Historia" } } },
                { id = "tro_zan_loa", name = "Abrazo de los loa", type = "informativo", description = "Conoces guia; a nivel 3 lanzas habilidad mejorada 1 vez al día (Sabiduría).", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "tro_zan_armas", name = "Entrenamiento con armas zandalari", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, espadas largas y espadas grandes.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "espadas largas", "espadas grandes") },
            } },
            { id = "raza_trol_bosque", name = "Troll de Bosque", desc = "Trolls de bosque amani, feroces y territoriales, ligados a las profundidades arboladas.", traits = {
                { id = "tro_bos_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +1 y Constitución +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                } },
                { id = "tro_bos_instintos", name = "Instintos amani", type = "choice", description = "Competencia en Naturaleza, Sigilo o Supervivencia.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "naturaleza",    label = "Naturaleza",    effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                        { id = "sigilo",        label = "Sigilo",        effects = { { kind = "skillProf", skill = "Sigilo" } } },
                        { id = "supervivencia", label = "Supervivencia", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                    },
                } },
                { id = "tro_bos_mascara", name = "Mascara de lo salvaje", type = "pasivo", description = "Puedes esconderte ligeramente cubierto por follaje, lluvia, nieve, niebla, etc.", effects = {} },
                { id = "tro_bos_armas", name = "Entrenamiento con armas Troll", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "dagas", "jabalinas") },
            } },
            { id = "raza_trol_hielo", name = "Troll de Hielo", desc = "Trolls drakkari de Rasganorte, brutales supervivientes de las tierras heladas.", traits = {
                { id = "tro_hie_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Fuerza +2.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 } } },
                { id = "tro_hie_piel", name = "Piel de nacido del hielo", type = "pasivo", description = "Resistencia al daño por frío.", effects = {
                    { kind = "resist", damage = "frio" },
                } },
                { id = "tro_hie_constitucion", name = "Constitucion poderosa", type = "pasivo", description = "Cuentas como una criatura de un tamaño mayor para carga/empujar/arrastrar/levantar.", effects = {} },
                { id = "tro_hie_armas", name = "Entrenamiento con armas Troll", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "dagas", "jabalinas") },
            } },
        },
        traits = {
            { id = "tro_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "tro_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Visión en la oscuridad a 60 pies (tonos de gris).", effects = {} },
            { id = "tro_regeneracion", name = "Regeneracion", type = "pasivo", description = "Al gastar un Dado de Golpe recuperas lo lanzado + el doble de tu Mod. Constitución; como accion puedes gastar dados hasta la mitad de tu nivel. Recarga con descanso largo.", effects = {
                { kind = "flag", flag = "trollRegenHitDie" },
            } },
            { id = "tro_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Zandali.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Zandali" } } },
        },
    },
    {
        id = "raza_elfo_sangre", name = "Elfo de Sangre", nameF = "Elfa de Sangre", desc = "Sin'dorei de Quel'Thalas, sedientos de magia tras la caida del Pozo del Sol; elegantes, arcanos y orgullosos.", faction = "horda", size = "Mediano", speed = 9,
        traits = {
            { id = "esa_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +2 e Inteligencia +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
            } },
            { id = "esa_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Puedes ver en luz tenue en un radio de 60 pies como si fuera luz brillante, y en oscuridad como si fuera luz tenue. En la oscuridad, solo puedes distinguir tonos de gris, sin distinguir colores.", effects = {} },
            { id = "esa_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Tienes competencia en la habilidad de Conocimiento Arcano. Además, puedes lanzar el conjuro Detectar magia una vez al día. La Inteligencia es tu característica de lanzamiento para este conjuro.", spellGrants = { { level = 1, ids = { "detectar_magia" }, ability = "Inteligencia", note = "1/dia" } }, effects = { { kind = "skillProf", skill = "Arcano" } } },
            { id = "esa_sentidos", name = "Sentidos agudos", type = "pasivo", description = "Eres competente en Percepción.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "esa_reversion", name = "Reversion de conjuros", type = "informativo", description = "Cuando fallas una tirada de salvación contra un conjuro o efecto mágico, puedes repetir la tirada y debes usar el nuevo resultado. No puedes usar esta característica de nuevo hasta que termines un descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "esa_legado", name = "Legado thalassiano", type = "choice", description = "Conoces un truco de la lista de mago a tu elección. La Inteligencia es tu característica de lanzamiento para este conjuro. En su lugar puedes ganar competencia con espada gemela, guja, arco corto y arco largo.", effects = {}, choice = {
                slots = 1,
                -- Los trucos de mago se listan uno a uno (`extraFrom`, ver HarfordDnDBook): lo
                -- elegido es el truco CONCRETO, no un generico "un truco de mago".
                extraFrom = "cantrip:Mago",
                options = {
                    { id = "armas", label = "Competencia con espada gemela, guja, arco corto y largo", effects = WeaponProfEffects("espada gemela", "guja", "arco corto", "arco largo") },
                },
            } },
            { id = "esa_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Thalassiano.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Thalassiano" } } },
        },
    },
    {
        id = "raza_goblin", name = "Goblin", desc = "Mercaderes e ingenieros codiciosos potenciados por la kaja'mita; astutos, explosivos y siempre buscando un trato.", faction = "horda", size = "Pequeño", speed = 7.5,
        traits = {
            { id = "gob_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Inteligencia +1 y Carisma +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
                { kind = "bonus", target = "ability", ability = "Carisma", value = 2 },
            } },
            { id = "gob_tratos", name = "Mejores tratos", type = "pasivo", description = "Al regatear (Carisma/Persuasión), competente y sumas el doble de tu bono de competencia.", effects = {} },
            { id = "gob_esquivar", name = "Esquivar", type = "informativo", description = "Ventaja en una salvación de Destreza contra un efecto visible (antes de tirar). Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "gob_ingenieria", name = "Ingenieria Goblin", type = "pasivo", description = "Competencia con herramientas de artesano; construyes dispositivos con un hechizo a elegir (Inteligencia).", effects = {
                { kind = "toolProf", tool = "Herramientas de artesano" },
            } },
            { id = "gob_familiaridad", name = "Familiaridad mecanica", type = "pasivo", description = "Competencia en armas de fuego y herramientas de armero.", effects = {
                { kind = "weaponProf", weapon = "armas de fuego" },
                { kind = "toolProf", tool = "Herramientas de armero" },
            } },
            { id = "gob_idiomas", name = "Idiomas", type = "choice", description = "Hablas, lees y escribes Comun, Goblin y un idioma adicional de tu elección.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Goblin" } }, choice = { slots = 1, optionsFrom = "language" } },
        },
    },
    {
        id = "raza_pandaren", name = "Pandaren", desc = "Osos humanoides de Pandaria, esclavos liberados de los mogu; pacificos, armoniosos y maestros del combate desarmado. Neutrales ante las facciones (tushui/huojin).", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "pan_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Constitución +1 y Sabiduría +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 },
            } },
            { id = "pan_gourmet", name = "Gourmet", type = "pasivo", description = "Obtienes competencia con utensilios de cocina y utensilios de cervecero.", effects = {
                { kind = "toolProf", tool = "Utensilios de cocina" },
                { kind = "toolProf", tool = "Suministros de cerveceria" },
            } },
            { id = "pan_paz", name = "Paz interior", type = "pasivo", description = "Tienes ventaja en tiradas de salvación contra ser encantado o asustado.", effects = {} },
            { id = "pan_marcial", name = "Experto marcial", type = "pasivo", description = "Tus ataques desarmados infligen 1d4 + Mod. Fuerza como daño contundente en un golpe. Además, obtienes un bono de +1 a tu Clase de Armadura. Para usar este bono, no debes llevar armadura mediana o pesada ni usar un escudo.", effects = {} },
            { id = "pan_palma", name = "Palma temblorosa", type = "informativo", description = "Eres capaz de atacar puntos focales en un objetivo. Como acción adicional, puedes hacer un ataque desarmado especial. Si el ataque impacta, causa su daño normal y el objetivo debe superar una tirada de salvación de Constitución (CD 8 + Mod. Sabiduría + Bonus Competencia). Si falla, queda aturdido hasta el final de tu próximo turno. Después de usarla, no puedes volver a hacerlo hasta que termines un descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "pan_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Pandaren.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Pandaren" } } },
        },
    },
    {
        id = "raza_nocheterna", name = "Nocheterna", nameF = "Elfa Nocheterna", desc = "Shal'dorei de Suramar, elfos arcanos refinados por milenios bajo el Mana del Pozo; ordenados, orgullosos y sensibles a la luz solar.", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "noc_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +1 e Inteligencia +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 2 },
            } },
            { id = "noc_vision", name = "Vision en la oscuridad superior", type = "pasivo", description = "Ves en luz tenue a 36 metros como luz brillante y en oscuridad como luz tenue (tonos de violeta).", effects = {} },
            { id = "noc_solar", name = "Sensibilidad a la Luz solar", type = "pasivo", description = "Desventaja en ataques y en pruebas de Sabiduría (Percepción) basadas en la vista bajo luz solar directa.", effects = {} },
            { id = "noc_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Conocimiento Arcano.", effects = { { kind = "skillProf", skill = "Arcano" } } },
            { id = "noc_sentidos", name = "Sentidos agudos", type = "pasivo", description = "Competencia en Percepción.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "noc_proteccion", name = "Proteccion mental", type = "pasivo", description = "Ventaja en todas las tiradas de salvación de Inteligencia, Sabiduría y Carisma contra magia.", effects = {} },
            { id = "noc_magia", name = "Magia Nocheterna", type = "pasivo", description = "Conoces el truco Mano de mago. A nivel 3 lanzas Detectar magia 1/día; a nivel 5, Desenfoque 1/día. Característica: Inteligencia.", effects = {} },
            { id = "noc_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Shalassiano.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Shalassiano" } } },
        },
    },
    {
        id = "raza_elfo_vacio", name = "Elfo del Vacio", nameF = "Elfa del Vacio", desc = "Ren'dorei exiliados de Quel'Thalas que abrazaron el poder del Vacio siguiendo a Umbric; elegantes y arcanos, marcados por energías sombrias.", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "elv_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +2.", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 2 } } },
            { id = "elv_inc_choice", name = "Incremento de caracteristica (eleccion)", type = "choice", description = "Inteligencia o Carisma +1.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "inteligencia", label = "Inteligencia +1", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                    { id = "carisma", label = "Carisma +1", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
                },
            } },
            { id = "elv_vision", name = "Vision en la oscuridad", type = "pasivo", description = "Ves en luz tenue a 18 metros como luz brillante y en oscuridad como luz tenue (tonos de gris).", effects = {} },
            { id = "elv_sentidos", name = "Sentidos agudos", type = "pasivo", description = "Competencia en Percepción.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "elv_frio", name = "Frio de la Noche", type = "pasivo", description = "Resistencia al daño necrótico.", effects = { { kind = "resist", damage = "necrotico" } } },
            { id = "elv_grieta", name = "Grieta espacial", type = "informativo", description = "Accion adicional: te teletransportas hasta 9 metros a un espacio visible. 1 uso por descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "elv_legado", name = "Legado thalassiano", type = "choice", description = "Conoces un truco de la lista de mago a tu elección. La Inteligencia es tu característica de lanzamiento para este conjuro. En su lugar puedes ganar competencia con espada gemela, guja, arco corto y arco largo.", effects = {}, choice = {
                slots = 1,
                -- Los trucos de mago se listan uno a uno (`extraFrom`, ver HarfordDnDBook): lo
                -- elegido es el truco CONCRETO, no un generico "un truco de mago".
                extraFrom = "cantrip:Mago",
                options = {
                    { id = "armas", label = "Competencia con espada gemela, guja, arco corto y largo", effects = WeaponProfEffects("espada gemela", "guja", "arco corto", "arco largo") },
                },
            } },
            { id = "elv_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Thalassiano.", effects = { { kind = "language", language = "Comun" }, { kind = "language", language = "Thalassiano" } } },
        },
    },
    {
        id = "raza_vulpera", name = "Vulpera", desc = "Pequeños zorros nomadas del desierto de Vol'dun; astutos, sociables y resistentes, viajeros de caravana aliados de la Horda.", faction = "aliada", size = "Pequeño", speed = 9,
        traits = {
            { id = "vul_inc", name = "Incremento de caracteristica", type = "pasivo", description = "Destreza +2 e Inteligencia +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
            } },
            { id = "vul_desierto", name = "Nacido del desierto", type = "pasivo", description = "Estás naturalmente adaptado a climas cálidos.", effects = {} },
            { id = "vul_furia", name = "Furia del pequeño", type = "informativo", description = "Cuando infliges daño a una criatura con un ataque o conjuro y la criatura es de un tamaño mayor que el tuyo, puedes causar daño adicional igual a tu nivel. Una vez que uses este rasgo, no podrás volver a hacerlo hasta que termines un descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "vul_oido", name = "Oido agudo", type = "pasivo", description = "Ventaja en pruebas de Sabiduría (Percepción) basadas en el oído.", effects = {} },
            { id = "vul_nomada", name = "Conocimiento nomada", type = "choice", description = "Obtienes competencia en una de las siguientes habilidades a tu elección: Manejo de Animales, Naturaleza, Sigilo o Supervivencia.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "animales", label = "Trato con Animales", effects = { { kind = "skillProf", skill = "Animales" } } },
                    { id = "naturaleza", label = "Naturaleza", effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                    { id = "sigilo", label = "Sigilo", effects = { { kind = "skillProf", skill = "Sigilo" } } },
                    { id = "supervivencia", label = "Supervivencia", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                },
            } },
            { id = "vul_olfato", name = "Olfato para el peligro", type = "pasivo", description = "Puedes realizar la acción de Desengancharse o Esquivar como acción adicional durante tu primer turno de cada combate. Si te sorprenden al comienzo del combate y no estás incapacitado, aún puedes realizar la acción de Esquivar en tu primer turno.", effects = {} },
            { id = "vul_explorador", name = "Explorador", type = "pasivo", description = "Siempre que hagas una prueba de Sabiduría (Supervivencia) relacionada con la navegación, se te considera competente en la habilidad de Supervivencia y agregas el doble de tu bonificador por competencia al chequeo, en lugar de tu bonificador normal.", effects = {} },
            { id = "vul_idiomas", name = "Idiomas", type = "choice", description = "Hablas, lees y escribes Comun y dos idiomas adicionales a tu elección.", effects = { { kind = "language", language = "Comun" } }, choice = { slots = 2, optionsFrom = "language" } },
        },
    },
}

local raceById, raceOrder

local function Normalize(value)
    value = HarfordClassColors.StripAccents(value):lower()
    value = value:gsub("[_%-]+", " ")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))  -- parentesis: gsub devuelve 2 valores
end

-- Variante en MASCULINO de un texto ya normalizado (fallback de genero): el About TRP3
-- escribe la raza en femenino (Gnoma, Humana, Elfa de sangre, Maga...). Se prueba el texto
-- original primero y, si falla, esta variante (Gnoma->gnomo, Elfa->elfo, Humana->humano).
local RACE_GENDER_ALIAS = { semielfa = "semielfo" }
local RACE_GENDER_STOP = { la = true, las = true, una = true, unas = true, de = true,
    del = true, el = true, los = true, ["a"] = true, ["y"] = true, en = true }
local function Masculinize(normalized)
    return (tostring(normalized or ""):gsub("%a+", function(w)
        if RACE_GENDER_ALIAS[w] then return RACE_GENDER_ALIAS[w] end
        if RACE_GENDER_STOP[w] then return w end
        return (w:gsub("a$", "o"))  -- 'a' final de palabra -> 'o'
    end))
end

-- Alias de TEXTO de raza -> id del libro, para razas que no existen como entrada propia
-- pero comparten rasgos con una existente. "Elfo noble" / "alto elfo" (quel'dorei) se tratan
-- como Elfo de Sangre (sin'dorei) a efectos de rasgos. (Semielfo SI es raza propia, ver
-- abajo.) Las claves van normalizadas (sin acentos, minusculas); el femenino lo cubre Masculinize.
-- OJO: el destino es el ID ACTUAL, con su prefijo `raza_`. Los dos alias se quedaron apuntando a
-- "elfo_sangre" tras el renombrado de razas, y como el alias gana el "match mas largo" y despues
-- se busca por id, resolvian a una raza inexistente: una ficha TRP3 con "Elfo noble" o "Alto elfo"
-- cargaba SIN rasgos raciales y sin dar error. Lo cazo la auditoria de referencias cruzadas.
local RACE_TEXT_ALIAS = {
    ["elfo noble"] = "raza_elfo_sangre",
    ["alto elfo"]  = "raza_elfo_sangre",
}

local function EnsureIndex()
    if raceById then return end
    raceById, raceOrder = {}, {}
    for _, raceDef in ipairs(API.RACES) do
        raceById[raceDef.id] = raceDef
        raceOrder[#raceOrder + 1] = raceDef.id
    end
end

function API.GetRaces()
    EnsureIndex()
    return API.RACES
end

function API.GetRace(raceId)
    EnsureIndex()
    return raceById[tostring(raceId or "")]
end

function API.GetRaceOrder()
    EnsureIndex()
    return raceOrder
end

function API.GetRaceName(raceId)
    local raceDef = API.GetRace(raceId)
    return raceDef and raceDef.name or tostring(raceId or "")
end

function API.GetSubrace(raceId, subraceId)
    local raceDef = API.GetRace(raceId)
    if not raceDef then return nil end
    for _, sub in ipairs(raceDef.subraces or {}) do
        if sub.id == subraceId then return sub end
    end
    return nil
end

function API.GetDefaultSubraceId(raceId)
    local raceDef = API.GetRace(raceId)
    local first = raceDef and raceDef.subraces and raceDef.subraces[1]
    return first and first.id or ""
end

function API.FindRaceIdByText(text)
    local clean = Normalize(text)
    if clean == "" then return nil end
    EnsureIndex()
    local masc = Masculinize(clean)
    local function hits(normalized)
        return normalized ~= "" and (clean:find(normalized, 1, true)
            or (masc ~= clean and masc:find(normalized, 1, true)))
    end
    local bestId, bestLen
    for _, raceDef in ipairs(API.RACES) do
        for _, candidate in ipairs({ raceDef.id, raceDef.name }) do
            local normalized = Normalize(candidate)
            if hits(normalized) then
                local len = #normalized
                if not bestLen or len > bestLen then bestId, bestLen = raceDef.id, len end
            end
        end
        for _, sub in ipairs(raceDef.subraces or {}) do
            local normalized = Normalize(sub.name)
            if hits(normalized) then
                local len = #normalized
                if not bestLen or len > bestLen then bestId, bestLen = raceDef.id, len end
            end
        end
    end
    -- Alias de texto (Semielfo/Semielfa/elfo noble -> Elfo de Sangre). Compiten en el mismo
    -- "match mas largo" para no pisar coincidencias de nombre de raza mas especificas.
    for phrase, raceId in pairs(RACE_TEXT_ALIAS) do
        local normalized = Normalize(phrase)
        if hits(normalized) then
            local len = #normalized
            if not bestLen or len > bestLen then bestId, bestLen = raceId, len end
        end
    end
    return bestId
end

function API.FindSubraceIdByText(raceId, text)
    local raceDef = API.GetRace(raceId)
    local clean = Normalize(text)
    if not raceDef or clean == "" then return nil end
    local masc = Masculinize(clean)
    local bestId, bestLen
    for _, sub in ipairs(raceDef.subraces or {}) do
        for _, candidate in ipairs({ sub.id, sub.name }) do
            local normalized = Normalize(candidate)
            if normalized ~= "" and (clean:find(normalized, 1, true)
                or (masc ~= clean and masc:find(normalized, 1, true))) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = sub.id, len
                end
            end
        end
    end
    return bestId
end

-- Devuelve los rasgos de la raza (y subraza elegida) en el MISMO formato que
-- HarfordDnDBook.GetUnlockedFeatures: { { className, level=0, feature }, ... }.
-- Asi FeatureEffects y la UI los tratan como cualquier otra "feature" desbloqueada.
function API.GetRaceTraits(raceId, subraceId)
    local out = {}
    local raceDef = API.GetRace(raceId)
    if not raceDef then return out end
    for _, trait in ipairs(raceDef.traits or {}) do
        out[#out + 1] = { className = raceDef.name, level = 0, subclassId = subraceId, feature = trait }
    end
    local sub = API.GetSubrace(raceId, subraceId)
    if sub then
        for _, trait in ipairs(sub.traits or {}) do
            out[#out + 1] = { className = (raceDef.name or "") .. " / " .. (sub.name or ""), level = 0, subclassId = subraceId, feature = trait }
        end
    end
    return out
end

function API.GetTrait(traitId)
    traitId = tostring(traitId or "")
    for _, raceDef in ipairs(API.RACES) do
        for _, trait in ipairs(raceDef.traits or {}) do
            if trait.id == traitId then return trait, raceDef end
        end
        for _, sub in ipairs(raceDef.subraces or {}) do
            for _, trait in ipairs(sub.traits or {}) do
                if trait.id == traitId then return trait, raceDef, sub end
            end
        end
    end
    return nil
end
