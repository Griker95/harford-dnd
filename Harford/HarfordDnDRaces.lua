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
        id = "humano", name = "Humano", desc = "Versatiles y ambiciosos; sus vidas breves los empujan a grandes logros y han forjado los mayores reinos de Azeroth.", faction = "alianza", size = "Mediano", speed = 9,
        traits = {
            { id = "hum_inc_2", name = "Incremento de Caracteristica (+2)", type = "choice", description = "Una caracteristica de tu eleccion aumenta en 2.", effects = {}, choice = { slots = 1, optionsFrom = "ability+2" } },
            { id = "hum_inc_1", name = "Incremento de Caracteristica (+1)", type = "choice", description = "Otra caracteristica de tu eleccion aumenta en 1.", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
            { id = "hum_determinacion", name = "Determinacion", type = "informativo", description = "Una vez por descanso, haces una tirada de ataque, prueba o salvacion con ventaja.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "hum_espiritu", name = "Espiritu Humano", type = "informativo", description = "Cuando sacas un 1 en ataque, prueba o salvacion, puedes repetir el dado (usas el nuevo resultado).", effects = {} },
            { id = "hum_versatilidad", name = "Versatilidad de Habilidades", type = "choice", description = "Competencia en dos habilidades de tu eleccion.", effects = {}, choice = { slots = 2, optionsFrom = "skillProf" } },
            { id = "hum_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y un idioma adicional de tu eleccion.", effects = {} },
        },
    },
    {
        id = "enano", name = "Enano", desc = "Pueblo de las montanas de Khaz Modan, ligado al clan y la tradicion, maestro de la piedra, la forja y la mineria.", faction = "alianza", size = "Mediano", speed = 7.5,
        subraces = {
            { id = "forjaz", name = "Enano de Forjaz", desc = "Robustos y tradicionales enanos de Forjaz, firmes como la piedra y maestros de la forja y la mineria.", traits = {
                { id = "ena_forjaz_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "ena_forjaz_dureza", name = "Dureza Enana", type = "informativo", description = "Tus PG maximos aumentan en 1, y +1 cada vez que subes de nivel.", effects = {} },
                { id = "ena_forjaz_piedra", name = "Forma de Piedra", type = "informativo", description = "Reaccion al recibir un ataque cuerpo a cuerpo: resistencia a fisico hasta tu proximo turno. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "martillo_salvaje", name = "Enano Martillo Salvaje", desc = "Enanos libres de las alturas, jinetes de grifos de espiritu salvaje y vinculo con la naturaleza.", traits = {
                { id = "ena_mart_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "ena_mart_altura", name = "Residencia en Altura", type = "informativo", description = "Acostumbrado a grandes altitudes y al frio.", effects = {} },
                { id = "ena_mart_valentia", name = "Valentia Irrazonable", type = "informativo", description = "Ventaja en tiradas de salvacion contra el miedo.", effects = {} },
                { id = "ena_mart_domador", name = "Domador Natural", type = "pasivo", description = "Competencia en Trato con Animales y en tiradas hacia grifos.", effects = { { kind = "skillProf", skill = "Animales" } } },
            } },
            { id = "hierro_negro", name = "Enano Hierro Negro", desc = "Enanos oscuros ligados al fuego y la magia, antano siervos de Ragnaros en las profundidades.", traits = {
                { id = "ena_hn_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                { id = "ena_hn_sangre", name = "Sangre de Fuego", type = "informativo", description = "Lanzas restauracion menor en ti mismo una vez al dia.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "ena_hn_forjado", name = "Forjado en Llamas", type = "pasivo", description = "Resistencia al daño por fuego.", effects = {
                    { kind = "resist", damage = "fuego" },
                } },
                { id = "ena_hn_vision", name = "Vision en la Oscuridad Superior", type = "informativo", description = "Vision en la oscuridad de 36 metros.", effects = {} },
            } },
        },
        traits = {
            { id = "ena_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +2.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 2 } } },
            { id = "ena_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Ves en luz tenue a 18 metros como luz brillante y en oscuridad como luz tenue (tonos de gris).", effects = {} },
            { id = "ena_entrenamiento", name = "Entrenamiento de Combate Enano", type = "pasivo", description = "Competencia con hacha de batalla, hacha de mano, martillo de guerra, pistolas y rifles.", effects = WeaponProfEffects("hacha de batalla", "hacha de mano", "martillo de guerra", "pistolas", "rifles") },
            { id = "ena_piedra", name = "Conocimiento de la Piedra", type = "informativo", description = "En pruebas de Historia sobre mamposteria, competente y sumas el doble de tu bono de competencia.", effects = {} },
            { id = "ena_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Enano.", effects = {} },
        },
    },
    {
        id = "elfo_noche", name = "Elfo de la Noche", desc = "Kaldorei antiguos y orgullosos, primeros estudiosos de la magia; hoy guardianes de la naturaleza y devotos de Elune.", faction = "alianza", size = "Mediano", speed = 10.5,
        subraces = {
            { id = "altonato", name = "Altonato", desc = "Kaldorei de Eldre'Thalas (los Shen'dralar/Altonato), eruditos arcanos de la antigua Dire Maul; conservan un saber magico vedado al resto de los suyos.", traits = {
                { id = "eln_alt_conocimiento", name = "Conocimiento antiguo de Eldre'Thalas", type = "pasivo", description = "Competencia en Conocimiento Arcano e Historia. Ademas duplicas tu bono de competencia en Historia en tiradas relacionadas con civilizaciones antiguas o artefactos.", effects = {
                    { kind = "skillProf", skill = "Arcano" },
                    { kind = "skillProf", skill = "Historia" },
                } },
                { id = "eln_alt_erudito", name = "Erudito arcano", type = "informativo", description = "Conoces el truco Mano de mago. A nivel 3 puedes lanzar Detectar magia 1 vez al dia; a nivel 5, Identificar 1 vez al dia. La caracteristica para estos conjuros es Inteligencia.", effects = {} },
                { id = "eln_alt_proteccion", name = "Proteccion mental", type = "informativo", description = "Ventaja en todas las tiradas de salvacion de Inteligencia, Sabiduria y Carisma contra magia.", effects = {} },
            } },
        },
        traits = {
            { id = "eln_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +2 y Sabiduria +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },
            } },
            { id = "eln_vision", name = "Vision en la Oscuridad Superior", type = "informativo", description = "Ves en penumbra a 36 metros como luz brillante y en oscuridad como penumbra (tono violeta).", effects = {} },
            { id = "eln_armas", name = "Entrenamiento con Armas Kaldorei", type = "pasivo", description = "Competencia con arco largo, espada lunar, glaive lunar y glaive de guerra.", effects = WeaponProfEffects("arco largo", "espada lunar", "glaive lunar", "glaive de guerra") },
            { id = "eln_sentidos", name = "Sentidos Agudos", type = "pasivo", description = "Competencia en Percepcion.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "eln_mascara", name = "Mascara de lo Salvaje", type = "informativo", description = "Puedes ocultarte cuando estas ligeramente cubierto por elementos naturales.", effects = {} },
            { id = "eln_fusion", name = "Fusion con las Sombras", type = "informativo", description = "Ventaja en Sigilo al estar completamente oculto por la oscuridad.", effects = {} },
            { id = "eln_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Darnassiano.", effects = {} },
        },
    },
    {
        id = "semielfo", name = "Semielfo", desc = "Hijos de dos mundos, mezcla de humano y elfo; combinan la versatilidad humana con la gracia y el legado arcano elfico.", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "sme_espiritu", name = "Espiritu Mestizo", type = "informativo", description = "Repites cualquier dado que saque un 1 en una tirada de ataque, prueba de habilidad o tirada de salvacion (usas el nuevo resultado).", effects = {} },
            { id = "sme_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 18 metros (60 pies).", effects = {} },
            { id = "sme_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Conocimiento Arcano. Ademas puedes lanzar Detectar magia 1 vez al dia usando Inteligencia.", uses = { max = 1, recharge = "long" }, effects = {
                { kind = "skillProf", skill = "Arcano" },
            } },
            { id = "sme_legado", name = "Legado Elfico", type = "informativo", description = "Conoces un truco de mago a tu eleccion (caracteristica Inteligencia).", effects = {} },
        },
    },
    {
        id = "gnomo", name = "Gnomo", desc = "Raza diminuta de ingenieros e inventores subterraneos, celebres por su ingenio mecanico y su curiosidad insaciable.", faction = "alianza", size = "Pequeño", speed = 7.5,
        subraces = {
            { id = "gnomeregan", name = "Gnomo de Gnomeregan", desc = "Los brillantes ingenieros e inventores clasicos, mentes inquietas de Gnomeregan.", traits = {
                { id = "gno_gnom_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Carisma +1.", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
                { id = "gno_gnom_mente", name = "Mente Expansiva", type = "informativo", description = "Sumas la mitad de tu bono de competencia en pruebas de Inteligencia sin competencia.", effects = {} },
                { id = "gno_gnom_ingenieria", name = "Ingenieria Gnomica", type = "pasivo", description = "Competencia con herramientas de artesano; creas pequeños dispositivos con efectos simples.", effects = {
                    { kind = "toolProf", tool = "Herramientas de artesano" },
                } },
            } },
            { id = "mecagnomo", name = "Mecagnomo", desc = "Gnomos parcialmente mecanizados, con miembros y mejoras de metal integrados en su cuerpo.", traits = {
                { id = "gno_mec_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "gno_mec_mejoras", name = "Mejoras Mecanicas", type = "choice", description = "Elige una mejora (otra al nivel 5).", effects = {}, choice = {
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
            { id = "gno_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +2.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 2 } } },
            { id = "gno_artifice", name = "Conocimientos del Artifice", type = "informativo", description = "Doble bono de competencia en Inteligencia (Historia) sobre objetos magicos, alquimicos o tecnologicos.", effects = {} },
            { id = "gno_escapista", name = "Escapista", type = "informativo", description = "Desenganche como accion adicional cada turno; ventaja para evitar/terminar apresado.", effects = {} },
            { id = "gno_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Gnomico.", effects = {} },
        },
    },
    {
        id = "draenei", name = "Draenei", desc = "Eredar que huyeron de la Legion guiados por la Luz Sagrada; viajeros de mundo en mundo, sabios y devotos.", faction = "alianza", size = "Mediano", speed = 9,
        subraces = {
            { id = "exodar", name = "Draenei del Exodar", desc = "Draenei devotos portadores del don de los Naaru y de la Luz Sagrada.", traits = {
                { id = "dra_exo_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "dra_exo_gemas", name = "Tallado de Gemas", type = "pasivo", description = "Competencia con herramientas de joyero.", effects = {
                    { kind = "toolProf", tool = "Herramientas de joyero" },
                } },
                { id = "dra_exo_naaru", name = "Don de los Naaru", type = "informativo", description = "Accion: tocas y curas (= tu nivel). 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "dra_exo_heroica", name = "Presencia Heroica", type = "informativo", description = "Lanzas heroismo y favor divino usando Sabiduria. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "forjado_luz", name = "Draenei Forjado por la Luz", desc = "Cruzados imbuidos de Luz Sagrada, forjados como arma viviente contra la Legion Ardiente.", traits = {
                { id = "dra_fl_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "dra_fl_forjado", name = "Forjado en Luz", type = "informativo", description = "Sin armadura, tu CA es 12 + Mod. Destreza.", effects = {} },
                { id = "dra_fl_resistencia", name = "Resistencia Sagrada", type = "pasivo", description = "Resistencia al daño radiante.", effects = {
                    { kind = "resist", damage = "radiante" },
                } },
                { id = "dra_fl_juicio", name = "Juicio de la Luz", type = "informativo", description = "Conoces luz; a niveles 3/5 lanzas rayo guiador / golpe de marca (Sabiduria).", effects = {} },
            } },
            { id = "tabido", name = "Draenei Tabido", desc = "Draenei rotos por la energia vil; marginados pero resistentes y perseverantes.", traits = {
                { id = "dra_tab_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "dra_tab_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 18 metros (tonos de gris).", effects = {} },
                { id = "dra_tab_elemental", name = "Vinculo Elemental", type = "informativo", description = "Conoces escarcha; a niveles 3/5 lanzas temblor de tierra / rafaga de viento (Sabiduria).", effects = {} },
                { id = "dra_tab_paria", name = "Paria", type = "pasivo", description = "Competencia en Supervivencia.", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
            } },
            { id = "man_ari", name = "Man'ari", desc = "Draenei corrompidos por la energia vil de la Legion Ardiente; cuerpo y alma alterados por fuerzas infernales. Algunos aun caminan por Azeroth buscando redencion... o poder.", traits = {
                { id = "dra_man_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +2 y Constitucion +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 },
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                } },
                { id = "dra_man_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Ves en la oscuridad a 18 metros (60 pies) como si fuera luz tenue; en oscuridad total ves en escala de grises.", effects = {} },
                { id = "dra_man_resiliencia", name = "Resiliencia Vil", type = "pasivo", description = "Resistencia al daño por fuego.", effects = {
                    { kind = "resist", damage = "fuego" },
                } },
                { id = "dra_man_magia", name = "Magia Vil", type = "informativo", description = "Conoces el truco Taumaturgia. A nivel 3 puedes lanzar Reprension Infernal 1/descanso largo; a nivel 5, Oscuridad 1/descanso largo. La caracteristica para estos conjuros es Carisma.", effects = {} },
                { id = "dra_man_presencia", name = "Presencia Retorcida", type = "pasivo", description = "Competencia en Intimidacion. Ademas tienes desventaja en tiradas de Persuasion contra criaturas de alineamiento bueno o que usen la Luz abiertamente, salvo que ocultes tu naturaleza.", effects = {
                    { kind = "skillProf", skill = "Intimidacion" },
                } },
            } },
        },
        traits = {
            { id = "dra_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Carisma +2.", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 2 } } },
            { id = "dra_sombras", name = "Resistencia a las Sombras", type = "pasivo", description = "Resistencia al daño necrotico.", effects = {
                { kind = "resist", damage = "necrotico" },
            } },
            { id = "dra_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Draenei.", effects = {} },
        },
    },
    {
        id = "huargen", name = "Huargen", desc = "Lobos humanoides nacidos de una maldicion druidica; conservan su humanidad bajo una ferocidad salvaje.", faction = "alianza", size = "Mediano", speed = 9,
        traits = {
            { id = "hua_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +2 y Destreza +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },
            } },
            { id = "hua_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Ves en luz tenue a 18 metros como luz brillante y en oscuridad como luz tenue (tonos de gris).", effects = {} },
            { id = "hua_mordida", name = "Mordida", type = "informativo", description = "Arma natural: golpe desarmado que inflige 1d6 + Mod. Fuerza perforante.", effects = {} },
            { id = "hua_oido", name = "Oido y Olfato Agudo", type = "informativo", description = "Ventaja en Sabiduria (Percepcion) basada en oido u olfato.", effects = {} },
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
            { id = "hua_salto", name = "Salto de Pie", type = "informativo", description = "Salto largo hasta 9 m y alto hasta 6 m, con o sin carrera.", effects = {} },
            { id = "hua_dos_formas", name = "Dos Formas", type = "informativo", description = "Te transformas en humano en 1 minuto; vuelves a huargen como accion gratuita (automatico al atacar/lanzar ofensivo).", effects = {} },
            { id = "hua_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y un idioma adicional de tu eleccion.", effects = {} },
        },
    },
    {
        id = "orco", name = "Orco", desc = "Guerreros de honor y fuerza que rompieron el ansia de sangre de la Legion y reconstruyeron la Horda con el chamanismo.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "cazadores", name = "Clanes Cazadores", desc = "Orcos de los clanes cazadores: emboscadores agiles y rastreadores letales.", traits = {
                { id = "orc_caz_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +1.", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 } } },
                { id = "orc_caz_emboscador", name = "Emboscador", type = "pasivo", description = "Competencia en Sigilo.", effects = { { kind = "skillProf", skill = "Sigilo" } } },
                { id = "orc_caz_sorpresa", name = "Ataque Sorpresa", type = "pasivo", description = "Si sorprendes y atacas en tu primer turno, +1d6 de daño (sube con nivel). Activa el daño extra desde el boton de daño condicional al atacar por sorpresa.", effects = {
                    { kind = "conditionalWeaponDamage", id = "surprise_attack", label = "Ataque Sorpresa", count = 1, die = 6 },
                } },
            } },
            { id = "misticos", name = "Clanes Misticos", desc = "Orcos de los clanes misticos: videntes y chamanes en contacto con los ancestros y los elementos.", traits = {
                { id = "orc_mis_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia o Sabiduria +1.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "inteligencia", label = "Inteligencia +1", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                        { id = "sabiduria",    label = "Sabiduria +1",    effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                    },
                } },
                { id = "orc_mis_llamado", name = "Llamado Ancestral", type = "informativo", description = "Lanzas augurio una vez por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "orc_mis_conocimientos", name = "Conocimientos Misticos", type = "choice", description = "Competencia en Arcano, Historia, Naturaleza o Religion.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "arcano",     label = "Conocimiento Arcano", effects = { { kind = "skillProf", skill = "Arcano" } } },
                        { id = "historia",   label = "Historia",            effects = { { kind = "skillProf", skill = "Historia" } } },
                        { id = "naturaleza", label = "Naturaleza",          effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                        { id = "religion",   label = "Religion",            effects = { { kind = "skillProf", skill = "Religion" } } },
                    },
                } },
            } },
            { id = "guerreros", name = "Clanes Guerreros", desc = "Orcos de los clanes guerreros: brutales y agresivos en la primera linea de batalla.", traits = {
                { id = "orc_gue_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "orc_gue_agresivo", name = "Agresivo", type = "informativo", description = "Accion adicional: muevete hasta tu velocidad hacia un enemigo visible.", effects = {} },
                { id = "orc_gue_salvajes", name = "Ataques Salvajes", type = "pasivo", description = "Al hacer un golpe critico, tira un dado de daño adicional del arma.", effects = {
                    { kind = "flag", flag = "savageCritDie" },
                } },
            } },
        },
        traits = {
            { id = "orc_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1 y Constitucion +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 },
                { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
            } },
            { id = "orc_amenazante", name = "Amenazante", type = "pasivo", description = "Competencia en Intimidacion.", effects = { { kind = "skillProf", skill = "Intimidacion" } } },
            { id = "orc_armas", name = "Entrenamiento con Armas Orcas", type = "pasivo", description = "Competencia con hacha de mano, hacha de batalla y garra de guerra.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "garra de guerra") },
            { id = "orc_resistencia", name = "Resistencia Implacable", type = "informativo", description = "Al caer a 0 PG sin morir, puedes quedarte en 1 PG. 1 uso por descanso largo.", uses = { max = 1, recharge = "long" }, effects = {} },
            { id = "orc_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Orco.", effects = {} },
        },
    },
    {
        id = "renegado", name = "Renegado", desc = "Humanos y elfos no-muertos liberados del Rey Exanime; una fuerza oscura de Entranas, aliada de la Horda por conveniencia.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "humano", name = "Renegado Humano", desc = "La mayoria de los Renegados: humanos no-muertos, decididos y versatiles tras su muerte.", traits = {
                { id = "ren_hum_inc", name = "Incremento de Caracteristica", type = "choice", description = "Una caracteristica de tu eleccion +1.", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
                { id = "ren_hum_determinacion", name = "Determinacion", type = "informativo", description = "Repites una tirada de ataque/prueba/salvacion con ventaja. 1 uso por descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "ren_hum_versatilidad", name = "Versatilidad", type = "choice", description = "Competencia en una habilidad de tu eleccion.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            } },
            { id = "elfo", name = "Renegado Elfo", desc = "Renegados de origen elfico, agiles y afilados, que conservan parte de su gracia en la no-muerte.", traits = {
                { id = "ren_elf_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                { id = "ren_elf_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Arcano; lanzas detectar magia (Inteligencia) 1 vez por descanso.", effects = { { kind = "skillProf", skill = "Arcano" } } },
                { id = "ren_elf_idioma", name = "Idioma Extra", type = "informativo", description = "Hablas, lees y escribes Thalassiano.", effects = {} },
            } },
        },
        traits = {
            { id = "ren_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +2.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 2 } } },
            { id = "ren_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 18 metros (tonos de gris).", effects = {} },
            { id = "ren_descanso", name = "Descanso de la Tumba", type = "informativo", description = "Para un descanso largo, basta con 6 horas de actividad ligera (no duermes).", effects = {} },
            { id = "ren_naturaleza", name = "Naturaleza No-Muerta", type = "pasivo", description = "Eres no-muerto (cuentas como humanoide para lo que no afecta a no-muertos); ventaja y resistencia a veneno; no necesitas comer/beber/respirar/dormir.", effects = {
                { kind = "resist", damage = "veneno" },
            } },
            { id = "ren_voluntad", name = "Voluntad de los Renegados", type = "informativo", description = "Ventaja en salvaciones contra encantamiento y efectos que vuelven a los no-muertos.", effects = {} },
            { id = "ren_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Guturasico.", effects = {} },
        },
    },
    {
        id = "tauren", name = "Tauren", desc = "Pueblo espiritual y nomada de las llanuras de Kalimdor; chamanes, cazadores y guerreros en comunion con la naturaleza.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "mulgore", name = "Tauren de Mulgore", desc = "Los tauren clasicos de las llanuras de Mulgore: espirituales, pacificos pero formidables.", traits = {
                { id = "tau_mul_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "tau_mul_resistencia", name = "Resistencia", type = "informativo", description = "Tus PG maximos aumentan en 1 y +1 cada nivel.", effects = {} },
                { id = "tau_mul_pisoton", name = "Pisoton de Guerra", type = "informativo", description = "Lanzas temblor de tierra 1 vez por descanso largo (Fuerza).", uses = { max = 1, recharge = "long" }, effects = {} },
            } },
            { id = "monte_alto", name = "Tauren de Monte Alto", desc = "Tauren astados de Monte Alto, fuertes vinculados a la tierra y herederos del legado de Huln.", traits = {
                { id = "tau_ma_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "tau_ma_montanes", name = "Montanes", type = "informativo", description = "Adaptado a grandes altitudes y climas frios.", effects = {} },
                { id = "tau_ma_tenacidad", name = "Tenacidad Rugosa", type = "informativo", cast = "reaccion", reactionTrigger = "damage_taken", reactionEffect = "reduce_damage_roll", reactionDice = "1d12", reactionFlat = "half_level", description = "Reaccion: reduces el daño en 1d12 + mitad de tu nivel. Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            } },
            { id = "taunka", name = "Taunka", desc = "Tauren curtidos de Rasganorte, pragmaticos supervivientes de climas implacables.", traits = {
                { id = "tau_tau_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "tau_tau_frio", name = "Resistencia al Frio", type = "pasivo", description = "Resistencia al daño por frio.", effects = {
                    { kind = "resist", damage = "frio" },
                } },
                { id = "tau_tau_atleta", name = "Atleta Natural", type = "pasivo", description = "Competencia en Atletismo.", effects = { { kind = "skillProf", skill = "Atletismo" } } },
                { id = "tau_tau_tundra", name = "Caminante de la Tundra", type = "informativo", description = "Te mueves por terreno dificil de hielo o nieve sin coste adicional.", effects = {} },
            } },
        },
        traits = {
            { id = "tau_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +2.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 } } },
            { id = "tau_cuernos", name = "Cuernos", type = "informativo", description = "Arma natural: golpe desarmado que inflige 1d6 + Mod. Fuerza perforante.", effects = {} },
            { id = "tau_construccion", name = "Construccion Poderosa", type = "informativo", description = "Cuentas como una categoria de tamaño mayor para carga/empujar/arrastrar/levantar.", effects = {} },
            { id = "tau_armas", name = "Entrenamiento de Armas Tauren", type = "pasivo", description = "Competencia con alabarda, totem de batalla, pistola y rifle.", effects = WeaponProfEffects("alabarda", "totem de batalla", "pistolas", "rifles") },
            { id = "tau_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Taur-ahe.", effects = {} },
        },
    },
    {
        id = "trol", name = "Trol", desc = "Pueblo antiguo, supersticioso y resistente, de rapida regeneracion; tribus dispersas de jungla, hielo y desierto.", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "jungla", name = "Troll de la Jungla", desc = "Trolls Lanza Negra: vudu, astucia y resistencia, aliados leales de la Horda.", traits = {
                { id = "tro_jun_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1 y Sabiduria +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                    { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },
                } },
                { id = "tro_jun_berserker", name = "Berserker", type = "informativo", description = "Accion adicional para un ataque o truco. Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
                { id = "tro_jun_voodoo", name = "Da Voodoo Shuffle", type = "informativo", description = "Te mueves por terreno dificil no magico sin coste adicional.", effects = {} },
                { id = "tro_jun_armas", name = "Entrenamiento con Armas Troll", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "dagas", "jabalinas") },
            } },
            { id = "zandalari", name = "Troll Zandalari", desc = "Trolls del antiguo imperio, orgullosos y devotos de los loa, herederos de una civilizacion milenaria.", traits = {
                { id = "tro_zan_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +2.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 } } },
                { id = "tro_zan_conocimiento", name = "Conocimiento Antiguo", type = "pasivo", description = "Competencia en Historia.", effects = { { kind = "skillProf", skill = "Historia" } } },
                { id = "tro_zan_loa", name = "Abrazo de los Loa", type = "informativo", description = "Conoces guia; a nivel 3 lanzas habilidad mejorada 1 vez al dia (Sabiduria).", uses = { max = 1, recharge = "long" }, effects = {} },
                { id = "tro_zan_armas", name = "Entrenamiento con Armas Zandalari", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, espadas largas y espadas grandes.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "espadas largas", "espadas grandes") },
            } },
            { id = "bosque", name = "Trol de Bosque", desc = "Trolls de bosque amani, feroces y territoriales, ligados a las profundidades arboladas.", traits = {
                { id = "tro_bos_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +1 y Constitucion +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                } },
                { id = "tro_bos_instintos", name = "Instintos Amani", type = "choice", description = "Competencia en Naturaleza, Sigilo o Supervivencia.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "naturaleza",    label = "Naturaleza",    effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                        { id = "sigilo",        label = "Sigilo",        effects = { { kind = "skillProf", skill = "Sigilo" } } },
                        { id = "supervivencia", label = "Supervivencia", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                    },
                } },
                { id = "tro_bos_mascara", name = "Mascara de lo Salvaje", type = "informativo", description = "Puedes esconderte ligeramente cubierto por follaje, lluvia, nieve, niebla, etc.", effects = {} },
                { id = "tro_bos_armas", name = "Entrenamiento con Armas Troll", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "dagas", "jabalinas") },
            } },
            { id = "hielo", name = "Troll de Hielo", desc = "Trolls drakkari de Rasganorte, brutales supervivientes de las tierras heladas.", traits = {
                { id = "tro_hie_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +2.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 } } },
                { id = "tro_hie_piel", name = "Piel de Nacido del Hielo", type = "pasivo", description = "Resistencia al daño por frio.", effects = {
                    { kind = "resist", damage = "frio" },
                } },
                { id = "tro_hie_constitucion", name = "Constitucion Poderosa", type = "informativo", description = "Cuentas como una criatura de un tamaño mayor para carga/empujar/arrastrar/levantar.", effects = {} },
                { id = "tro_hie_armas", name = "Entrenamiento con Armas Troll", type = "pasivo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = WeaponProfEffects("hacha de mano", "hacha de batalla", "dagas", "jabalinas") },
            } },
        },
        traits = {
            { id = "tro_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "tro_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 60 pies (tonos de gris).", effects = {} },
            { id = "tro_regeneracion", name = "Regeneracion", type = "pasivo", description = "Al gastar un Dado de Golpe recuperas lo lanzado + el doble de tu Mod. Constitucion; como accion puedes gastar dados hasta la mitad de tu nivel. Recarga con descanso largo.", effects = {
                { kind = "flag", flag = "trollRegenHitDie" },
            } },
            { id = "tro_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Zandali.", effects = {} },
        },
    },
    {
        id = "elfo_sangre", name = "Elfo de Sangre", desc = "Sin'dorei de Quel'Thalas, sedientos de magia tras la caida del Pozo del Sol; elegantes, arcanos y orgullosos.", faction = "horda", size = "Mediano", speed = 9,
        traits = {
            { id = "esa_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +2 e Inteligencia +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
            } },
            { id = "esa_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 60 pies (tonos de gris).", effects = {} },
            { id = "esa_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Arcano; lanzas detectar magia (Inteligencia) 1 vez por descanso.", effects = { { kind = "skillProf", skill = "Arcano" } } },
            { id = "esa_sentidos", name = "Sentidos Agudos", type = "pasivo", description = "Competencia en Percepcion.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "esa_reversion", name = "Reversion de Conjuros", type = "informativo", description = "Al fallar una salvacion contra un conjuro, repites la tirada (usas el nuevo resultado). Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "esa_legado", name = "Legado Thalassiano", type = "choice", description = "Elige un beneficio.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "truco", label = "Un truco de mago (Inteligencia)", effects = {} },
                    { id = "armas", label = "Competencia con espada gemela, guja, arco corto y largo", effects = WeaponProfEffects("espada gemela", "guja", "arco corto", "arco largo") },
                },
            } },
            { id = "esa_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Thalassiano.", effects = {} },
        },
    },
    {
        id = "goblin", name = "Goblin", desc = "Mercaderes e ingenieros codiciosos potenciados por la kaja'mita; astutos, explosivos y siempre buscando un trato.", faction = "horda", size = "Pequeño", speed = 7.5,
        traits = {
            { id = "gob_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1 y Carisma +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
                { kind = "bonus", target = "ability", ability = "Carisma", value = 2 },
            } },
            { id = "gob_tratos", name = "Mejores Tratos", type = "informativo", description = "Al regatear (Carisma/Persuasion), competente y sumas el doble de tu bono de competencia.", effects = {} },
            { id = "gob_esquivar", name = "Esquivar", type = "informativo", description = "Ventaja en una salvacion de Destreza contra un efecto visible (antes de tirar). Recarga con descanso.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "gob_ingenieria", name = "Ingenieria Goblin", type = "pasivo", description = "Competencia con herramientas de artesano; construyes dispositivos con un hechizo a elegir (Inteligencia).", effects = {
                { kind = "toolProf", tool = "Herramientas de artesano" },
            } },
            { id = "gob_familiaridad", name = "Familiaridad Mecanica", type = "pasivo", description = "Competencia en armas de fuego y herramientas de armero.", effects = {
                { kind = "weaponProf", weapon = "armas de fuego" },
                { kind = "toolProf", tool = "Herramientas de armero" },
            } },
            { id = "gob_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun, Goblin y un idioma adicional de tu eleccion.", effects = {} },
        },
    },
    {
        id = "pandaren", name = "Pandaren", desc = "Osos humanoides de Pandaria, esclavos liberados de los mogu; pacificos, armoniosos y maestros del combate desarmado. Neutrales ante las facciones (tushui/huojin).", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "pan_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1 y Sabiduria +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 },
            } },
            { id = "pan_gourmet", name = "Gourmet", type = "pasivo", description = "Competencia con herramientas de artesano: utensilios de cocina y suministros de cerveceria.", effects = {
                { kind = "toolProf", tool = "Utensilios de cocina" },
                { kind = "toolProf", tool = "Suministros de cerveceria" },
            } },
            { id = "pan_paz", name = "Paz Interior", type = "informativo", description = "Ventaja en tiradas de salvacion contra ser encantado o asustado.", effects = {} },
            { id = "pan_marcial", name = "Experto Marcial", type = "informativo", description = "Tus ataques desarmados infligen 1d4 + Mod. Fuerza contundente. Ademas +1 a la CA si no llevas armadura mediana/pesada ni escudo.", effects = {} },
            { id = "pan_palma", name = "Palma Temblorosa", type = "informativo", description = "Accion adicional: ataque desarmado especial; si impacta, el objetivo hace salvacion de Constitucion (CD 8 + Mod. Sabiduria + comp) o queda aturdido hasta el final de tu proximo turno. 1 uso por descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "pan_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Pandaren.", effects = {} },
        },
    },
    {
        id = "nocheterna", name = "Nocheterna", desc = "Shal'dorei de Suramar, elfos arcanos refinados por milenios bajo el Mana del Pozo; ordenados, orgullosos y sensibles a la luz solar.", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "noc_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +1 e Inteligencia +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 1 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 2 },
            } },
            { id = "noc_vision", name = "Vision en la Oscuridad Superior", type = "informativo", description = "Ves en luz tenue a 36 metros como luz brillante y en oscuridad como luz tenue (tonos de violeta).", effects = {} },
            { id = "noc_solar", name = "Sensibilidad a la Luz Solar", type = "informativo", description = "Desventaja en ataques y en pruebas de Sabiduria (Percepcion) basadas en la vista bajo luz solar directa.", effects = {} },
            { id = "noc_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Conocimiento Arcano.", effects = { { kind = "skillProf", skill = "Arcano" } } },
            { id = "noc_sentidos", name = "Sentidos Agudos", type = "pasivo", description = "Competencia en Percepcion.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "noc_proteccion", name = "Proteccion Mental", type = "informativo", description = "Ventaja en todas las tiradas de salvacion de Inteligencia, Sabiduria y Carisma contra magia.", effects = {} },
            { id = "noc_magia", name = "Magia Nocheterna", type = "informativo", description = "Conoces el truco Mano de mago. A nivel 3 lanzas Detectar magia 1/dia; a nivel 5, Desenfoque 1/dia. Caracteristica: Inteligencia.", effects = {} },
            { id = "noc_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Shalassiano.", effects = {} },
        },
    },
    {
        id = "elfo_vacio", name = "Elfo del Vacio", desc = "Ren'dorei exiliados de Quel'Thalas que abrazaron el poder del Vacio siguiendo a Umbric; elegantes y arcanos, marcados por energias sombrias.", faction = "aliada", size = "Mediano", speed = 9,
        traits = {
            { id = "elv_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +2.", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 2 } } },
            { id = "elv_inc_choice", name = "Incremento de Caracteristica (eleccion)", type = "choice", description = "Inteligencia o Carisma +1.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "inteligencia", label = "Inteligencia +1", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                    { id = "carisma", label = "Carisma +1", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
                },
            } },
            { id = "elv_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Ves en luz tenue a 18 metros como luz brillante y en oscuridad como luz tenue (tonos de gris).", effects = {} },
            { id = "elv_sentidos", name = "Sentidos Agudos", type = "pasivo", description = "Competencia en Percepcion.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "elv_frio", name = "Frio de la Noche", type = "pasivo", description = "Resistencia al daño necrotico.", effects = { { kind = "resist", damage = "necrotico" } } },
            { id = "elv_grieta", name = "Grieta Espacial", type = "informativo", description = "Accion adicional: te teletransportas hasta 9 metros a un espacio visible. 1 uso por descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "elv_legado", name = "Legado Thalassiano", type = "choice", description = "Elige un beneficio.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "truco", label = "Un truco de mago (Inteligencia)", effects = {} },
                    { id = "armas", label = "Competencia con espada gemela, guja, arco corto y largo", effects = WeaponProfEffects("espada gemela", "guja", "arco corto", "arco largo") },
                },
            } },
            { id = "elv_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Thalassiano.", effects = {} },
        },
    },
    {
        id = "vulpera", name = "Vulpera", desc = "Pequeños zorros nomadas del desierto de Vol'dun; astutos, sociables y resistentes, viajeros de caravana aliados de la Horda.", faction = "aliada", size = "Pequeño", speed = 9,
        traits = {
            { id = "vul_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +2 e Inteligencia +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
            } },
            { id = "vul_desierto", name = "Nacido del Desierto", type = "informativo", description = "Adaptado a climas calidos (Guia del DM, cap. 5).", effects = {} },
            { id = "vul_furia", name = "Furia del Pequeño", type = "informativo", description = "Al dañar a una criatura de tamaño mayor que el tuyo, infliges daño adicional igual a tu nivel. 1 uso por descanso corto o largo.", uses = { max = 1, recharge = "short" }, effects = {} },
            { id = "vul_oido", name = "Oido Agudo", type = "informativo", description = "Ventaja en pruebas de Sabiduria (Percepcion) basadas en el oido.", effects = {} },
            { id = "vul_nomada", name = "Conocimiento Nomada", type = "choice", description = "Competencia en una habilidad a elegir.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "animales", label = "Trato con Animales", effects = { { kind = "skillProf", skill = "Animales" } } },
                    { id = "naturaleza", label = "Naturaleza", effects = { { kind = "skillProf", skill = "Naturaleza" } } },
                    { id = "sigilo", label = "Sigilo", effects = { { kind = "skillProf", skill = "Sigilo" } } },
                    { id = "supervivencia", label = "Supervivencia", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
                },
            } },
            { id = "vul_olfato", name = "Olfato para el Peligro", type = "informativo", description = "Puedes Desengancharte o Esquivar como accion adicional en tu primer turno; aun sorprendido puedes Esquivar.", effects = {} },
            { id = "vul_explorador", name = "Explorador", type = "informativo", description = "En pruebas de Sabiduria (Supervivencia) de navegacion cuentas como competente y duplicas tu bono de competencia.", effects = {} },
            { id = "vul_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y dos idiomas adicionales a tu eleccion.", effects = {} },
        },
    },
}

local raceById, raceOrder

local function Normalize(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    -- Acentos por SECUENCIA UTF-8 (lider \195); NO clases de bytes (corrompen multibyte).
    value = value:gsub("\195[\129\161\128\160\132\164\130\162]", "a")
    value = value:gsub("\195[\137\169\136\168\139\171\138\170]", "e")
    value = value:gsub("\195[\141\173\140\172\143\175\142\174]", "i")
    value = value:gsub("\195[\147\179\146\178\150\182\148\180]", "o")
    value = value:gsub("\195[\154\186\153\185\156\188\155\187]", "u")
    value = value:gsub("\195[\145\177]", "n")
    return value:gsub("^%s+", ""):gsub("%s+$", "")
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
local RACE_TEXT_ALIAS = {
    ["elfo noble"] = "elfo_sangre",
    ["alto elfo"]  = "elfo_sangre",
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
