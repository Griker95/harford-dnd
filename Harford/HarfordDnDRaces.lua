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

-- faction: "alianza" | "horda" | "aliada"
API.RACES = {
    {
        id = "humano", name = "Humano", faction = "alianza", size = "Mediano", speed = 9,
        traits = {
            { id = "hum_inc_2", name = "Incremento de Caracteristica (+2)", type = "choice", description = "Una caracteristica de tu eleccion aumenta en 2.", effects = {}, choice = { slots = 1, optionsFrom = "ability+2" } },
            { id = "hum_inc_1", name = "Incremento de Caracteristica (+1)", type = "choice", description = "Otra caracteristica de tu eleccion aumenta en 1.", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
            { id = "hum_determinacion", name = "Determinacion", type = "informativo", description = "Una vez por descanso, haces una tirada de ataque, prueba o salvacion con ventaja.", effects = {} },
            { id = "hum_espiritu", name = "Espiritu Humano", type = "informativo", description = "Cuando sacas un 1 en ataque, prueba o salvacion, puedes repetir el dado (usas el nuevo resultado).", effects = {} },
            { id = "hum_versatilidad", name = "Versatilidad de Habilidades", type = "choice", description = "Competencia en dos habilidades de tu eleccion.", effects = {}, choice = { slots = 2, optionsFrom = "skillProf" } },
            { id = "hum_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y un idioma adicional de tu eleccion.", effects = {} },
        },
    },
    {
        id = "enano", name = "Enano", faction = "alianza", size = "Mediano", speed = 7.5,
        subraces = {
            { id = "forjaz", name = "Enano de Forjaz", traits = {
                { id = "ena_forjaz_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "ena_forjaz_dureza", name = "Dureza Enana", type = "informativo", description = "Tus PG maximos aumentan en 1, y +1 cada vez que subes de nivel.", effects = {} },
                { id = "ena_forjaz_piedra", name = "Forma de Piedra", type = "informativo", description = "Reaccion al recibir un ataque cuerpo a cuerpo: resistencia a fisico hasta tu proximo turno. 1 uso por descanso largo.", effects = {} },
            } },
            { id = "martillo_salvaje", name = "Enano Martillo Salvaje", traits = {
                { id = "ena_mart_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "ena_mart_altura", name = "Residencia en Altura", type = "informativo", description = "Acostumbrado a grandes altitudes y al frio.", effects = {} },
                { id = "ena_mart_valentia", name = "Valentia Irrazonable", type = "informativo", description = "Ventaja en tiradas de salvacion contra el miedo.", effects = {} },
                { id = "ena_mart_domador", name = "Domador Natural", type = "pasivo", description = "Competencia en Trato con Animales y en tiradas hacia grifos.", effects = { { kind = "skillProf", skill = "Animales" } } },
            } },
            { id = "hierro_negro", name = "Enano Hierro Negro", traits = {
                { id = "ena_hn_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                { id = "ena_hn_sangre", name = "Sangre de Fuego", type = "informativo", description = "Lanzas restauracion menor en ti mismo una vez al dia.", effects = {} },
                { id = "ena_hn_forjado", name = "Forjado en Llamas", type = "informativo", description = "Resistencia al daño por fuego.", effects = {} },
                { id = "ena_hn_vision", name = "Vision en la Oscuridad Superior", type = "informativo", description = "Vision en la oscuridad de 36 metros.", effects = {} },
            } },
        },
        traits = {
            { id = "ena_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +2.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 2 } } },
            { id = "ena_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Ves en luz tenue a 18 metros como luz brillante y en oscuridad como luz tenue (tonos de gris).", effects = {} },
            { id = "ena_entrenamiento", name = "Entrenamiento de Combate Enano", type = "informativo", description = "Competencia con hacha de batalla, hacha de mano, martillo de guerra, pistolas y rifles.", effects = {} },
            { id = "ena_piedra", name = "Conocimiento de la Piedra", type = "informativo", description = "En pruebas de Historia sobre mamposteria, competente y sumas el doble de tu bono de competencia.", effects = {} },
            { id = "ena_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Enano.", effects = {} },
        },
    },
    {
        id = "elfo_noche", name = "Elfo de la Noche", faction = "alianza", size = "Mediano", speed = 10.5,
        traits = {
            { id = "eln_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +2 y Sabiduria +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },
            } },
            { id = "eln_vision", name = "Vision en la Oscuridad Superior", type = "informativo", description = "Ves en penumbra a 36 metros como luz brillante y en oscuridad como penumbra (tono violeta).", effects = {} },
            { id = "eln_armas", name = "Entrenamiento con Armas Kaldorei", type = "informativo", description = "Competencia con arco largo, espada lunar, glaive lunar y glaive de guerra.", effects = {} },
            { id = "eln_sentidos", name = "Sentidos Agudos", type = "pasivo", description = "Competencia en Percepcion.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "eln_mascara", name = "Mascara de lo Salvaje", type = "informativo", description = "Puedes ocultarte cuando estas ligeramente cubierto por elementos naturales.", effects = {} },
            { id = "eln_fusion", name = "Fusion con las Sombras", type = "informativo", description = "Ventaja en Sigilo al estar completamente oculto por la oscuridad.", effects = {} },
            { id = "eln_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Darnassiano.", effects = {} },
        },
    },
    {
        id = "gnomo", name = "Gnomo", faction = "alianza", size = "Pequeño", speed = 7.5,
        subraces = {
            { id = "gnomeregan", name = "Gnomo de Gnomeregan", traits = {
                { id = "gno_gnom_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Carisma +1.", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 1 } } },
                { id = "gno_gnom_mente", name = "Mente Expansiva", type = "informativo", description = "Sumas la mitad de tu bono de competencia en pruebas de Inteligencia sin competencia.", effects = {} },
                { id = "gno_gnom_ingenieria", name = "Ingenieria Gnomica", type = "informativo", description = "Competencia con herramientas de artesano; creas pequeños dispositivos con efectos simples.", effects = {} },
            } },
            { id = "mecagnomo", name = "Mecagnomo", traits = {
                { id = "gno_mec_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "gno_mec_mejoras", name = "Mejoras Mecanicas", type = "choice", description = "Elige una mejora (otra al nivel 5).", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "emergencia",  label = "Sistema de Emergencia (curacion una vez/descanso largo)", effects = {} },
                        { id = "vision",      label = "Vision Mejorada (vision en la oscuridad 18 m)", effects = {} },
                        { id = "piernas",     label = "Piernas Mecanicas (velocidad 9 m; duplicar 1/turno)", effects = {} },
                        { id = "brazos",      label = "Brazos Mecanicos (golpe desarmado 1d6 + herramienta)", effects = {} },
                        { id = "resiliencia", label = "Resiliencia Metalica (sin armadura, CA 13 + Des)", effects = {} },
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
        id = "draenei", name = "Draenei", faction = "alianza", size = "Mediano", speed = 9,
        subraces = {
            { id = "exodar", name = "Draenei del Exodar", traits = {
                { id = "dra_exo_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "dra_exo_gemas", name = "Tallado de Gemas", type = "informativo", description = "Competencia con herramientas de joyero.", effects = {} },
                { id = "dra_exo_naaru", name = "Don de los Naaru", type = "informativo", description = "Accion: tocas y curas (= tu nivel). 1 uso por descanso largo.", effects = {} },
                { id = "dra_exo_heroica", name = "Presencia Heroica", type = "informativo", description = "Lanzas heroismo y favor divino usando Sabiduria. 1 uso por descanso largo.", effects = {} },
            } },
            { id = "forjado_luz", name = "Draenei Forjado por la Luz", traits = {
                { id = "dra_fl_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "dra_fl_forjado", name = "Forjado en Luz", type = "informativo", description = "Sin armadura, tu CA es 12 + Mod. Destreza.", effects = {} },
                { id = "dra_fl_resistencia", name = "Resistencia Sagrada", type = "informativo", description = "Resistencia al daño radiante.", effects = {} },
                { id = "dra_fl_juicio", name = "Juicio de la Luz", type = "informativo", description = "Conoces luz; a niveles 3/5 lanzas rayo guiador / golpe de marca (Sabiduria).", effects = {} },
            } },
            { id = "tabido", name = "Draenei Tabido", traits = {
                { id = "dra_tab_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "dra_tab_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 18 metros (tonos de gris).", effects = {} },
                { id = "dra_tab_elemental", name = "Vinculo Elemental", type = "informativo", description = "Conoces escarcha; a niveles 3/5 lanzas temblor de tierra / rafaga de viento (Sabiduria).", effects = {} },
                { id = "dra_tab_paria", name = "Paria", type = "pasivo", description = "Competencia en Supervivencia.", effects = { { kind = "skillProf", skill = "Supervivencia" } } },
            } },
        },
        traits = {
            { id = "dra_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Carisma +2.", effects = { { kind = "bonus", target = "ability", ability = "Carisma", value = 2 } } },
            { id = "dra_sombras", name = "Resistencia a las Sombras", type = "informativo", description = "Resistencia al daño necrotico.", effects = {} },
            { id = "dra_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Draenei.", effects = {} },
        },
    },
    {
        id = "huargen", name = "Huargen", faction = "alianza", size = "Mediano", speed = 9,
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
        id = "orco", name = "Orco", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "cazadores", name = "Clanes Cazadores", traits = {
                { id = "orc_caz_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +1.", effects = { { kind = "bonus", target = "ability", ability = "Destreza", value = 1 } } },
                { id = "orc_caz_emboscador", name = "Emboscador", type = "pasivo", description = "Competencia en Sigilo.", effects = { { kind = "skillProf", skill = "Sigilo" } } },
                { id = "orc_caz_sorpresa", name = "Ataque Sorpresa", type = "informativo", description = "Si sorprendes y atacas en tu primer turno, +1d6 de daño (sube con nivel).", effects = {} },
            } },
            { id = "misticos", name = "Clanes Misticos", traits = {
                { id = "orc_mis_inc", name = "Incremento de Caracteristica", type = "choice", description = "Inteligencia o Sabiduria +1.", effects = {}, choice = {
                    slots = 1,
                    options = {
                        { id = "inteligencia", label = "Inteligencia +1", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                        { id = "sabiduria",    label = "Sabiduria +1",    effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                    },
                } },
                { id = "orc_mis_llamado", name = "Llamado Ancestral", type = "informativo", description = "Lanzas augurio una vez por descanso largo.", effects = {} },
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
            { id = "guerreros", name = "Clanes Guerreros", traits = {
                { id = "orc_gue_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 } } },
                { id = "orc_gue_agresivo", name = "Agresivo", type = "informativo", description = "Accion adicional: muevete hasta tu velocidad hacia un enemigo visible.", effects = {} },
                { id = "orc_gue_salvajes", name = "Ataques Salvajes", type = "informativo", description = "Al hacer un golpe critico, tira un dado de daño adicional del arma.", effects = {} },
            } },
        },
        traits = {
            { id = "orc_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +1 y Constitucion +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Fuerza", value = 1 },
                { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
            } },
            { id = "orc_amenazante", name = "Amenazante", type = "pasivo", description = "Competencia en Intimidacion.", effects = { { kind = "skillProf", skill = "Intimidacion" } } },
            { id = "orc_armas", name = "Entrenamiento con Armas Orcas", type = "informativo", description = "Competencia con hacha de mano, hacha de batalla y garra de guerra.", effects = {} },
            { id = "orc_resistencia", name = "Resistencia Implacable", type = "informativo", description = "Al caer a 0 PG sin morir, puedes quedarte en 1 PG. 1 uso por descanso largo.", effects = {} },
            { id = "orc_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Orco.", effects = {} },
        },
    },
    {
        id = "renegado", name = "Renegado", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "humano", name = "Renegado Humano", traits = {
                { id = "ren_hum_inc", name = "Incremento de Caracteristica", type = "choice", description = "Una caracteristica de tu eleccion +1.", effects = {}, choice = { slots = 1, optionsFrom = "ability+1" } },
                { id = "ren_hum_determinacion", name = "Determinacion", type = "informativo", description = "Repites una tirada de ataque/prueba/salvacion con ventaja. 1 uso por descanso.", effects = {} },
                { id = "ren_hum_versatilidad", name = "Versatilidad", type = "choice", description = "Competencia en una habilidad de tu eleccion.", effects = {}, choice = { slots = 1, optionsFrom = "skillProf" } },
            } },
            { id = "elfo", name = "Renegado Elfo", traits = {
                { id = "ren_elf_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1.", effects = { { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 } } },
                { id = "ren_elf_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Arcano; lanzas detectar magia (Inteligencia) 1 vez por descanso.", effects = { { kind = "skillProf", skill = "Arcano" } } },
                { id = "ren_elf_idioma", name = "Idioma Extra", type = "informativo", description = "Hablas, lees y escribes Thalassiano.", effects = {} },
            } },
        },
        traits = {
            { id = "ren_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +2.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 2 } } },
            { id = "ren_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 18 metros (tonos de gris).", effects = {} },
            { id = "ren_descanso", name = "Descanso de la Tumba", type = "informativo", description = "Para un descanso largo, basta con 6 horas de actividad ligera (no duermes).", effects = {} },
            { id = "ren_naturaleza", name = "Naturaleza No-Muerta", type = "informativo", description = "Eres no-muerto (cuentas como humanoide para lo que no afecta a no-muertos); ventaja y resistencia a veneno; no necesitas comer/beber/respirar/dormir.", effects = {} },
            { id = "ren_voluntad", name = "Voluntad de los Renegados", type = "informativo", description = "Ventaja en salvaciones contra encantamiento y efectos que vuelven a los no-muertos.", effects = {} },
            { id = "ren_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Guturasico.", effects = {} },
        },
    },
    {
        id = "tauren", name = "Tauren", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "mulgore", name = "Tauren de Mulgore", traits = {
                { id = "tau_mul_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "tau_mul_resistencia", name = "Resistencia", type = "informativo", description = "Tus PG maximos aumentan en 1 y +1 cada nivel.", effects = {} },
                { id = "tau_mul_pisoton", name = "Pisoton de Guerra", type = "informativo", description = "Lanzas temblor de tierra 1 vez por descanso largo (Fuerza).", effects = {} },
            } },
            { id = "monte_alto", name = "Tauren de Monte Alto", traits = {
                { id = "tau_ma_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +1.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 } } },
                { id = "tau_ma_montanes", name = "Montanes", type = "informativo", description = "Adaptado a grandes altitudes y climas frios.", effects = {} },
                { id = "tau_ma_tenacidad", name = "Tenacidad Rugosa", type = "informativo", description = "Reaccion: reduces el daño en 1d12 + mitad de tu nivel. Recarga con descanso.", effects = {} },
            } },
            { id = "taunka", name = "Taunka", traits = {
                { id = "tau_tau_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
                { id = "tau_tau_frio", name = "Resistencia al Frio", type = "informativo", description = "Resistencia al daño por frio.", effects = {} },
                { id = "tau_tau_atleta", name = "Atleta Natural", type = "pasivo", description = "Competencia en Atletismo.", effects = { { kind = "skillProf", skill = "Atletismo" } } },
                { id = "tau_tau_tundra", name = "Caminante de la Tundra", type = "informativo", description = "Te mueves por terreno dificil de hielo o nieve sin coste adicional.", effects = {} },
            } },
        },
        traits = {
            { id = "tau_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +2.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 } } },
            { id = "tau_cuernos", name = "Cuernos", type = "informativo", description = "Arma natural: golpe desarmado que inflige 1d6 + Mod. Fuerza perforante.", effects = {} },
            { id = "tau_construccion", name = "Construccion Poderosa", type = "informativo", description = "Cuentas como una categoria de tamaño mayor para carga/empujar/arrastrar/levantar.", effects = {} },
            { id = "tau_armas", name = "Entrenamiento de Armas Tauren", type = "informativo", description = "Competencia con alabarda, totem de batalla, pistola y rifle.", effects = {} },
            { id = "tau_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Taur-ahe.", effects = {} },
        },
    },
    {
        id = "trol", name = "Trol", faction = "horda", size = "Mediano", speed = 9,
        subraces = {
            { id = "jungla", name = "Troll de la Jungla", traits = {
                { id = "tro_jun_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1 y Sabiduria +1.", effects = {
                    { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 },
                    { kind = "bonus", target = "ability", ability = "Sabiduria", value = 1 },
                } },
                { id = "tro_jun_berserker", name = "Berserker", type = "informativo", description = "Accion adicional para un ataque o truco. Recarga con descanso.", effects = {} },
                { id = "tro_jun_voodoo", name = "Da Voodoo Shuffle", type = "informativo", description = "Te mueves por terreno dificil no magico sin coste adicional.", effects = {} },
                { id = "tro_jun_armas", name = "Entrenamiento con Armas Troll", type = "informativo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = {} },
            } },
            { id = "zandalari", name = "Troll Zandalari", traits = {
                { id = "tro_zan_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Sabiduria +2.", effects = { { kind = "bonus", target = "ability", ability = "Sabiduria", value = 2 } } },
                { id = "tro_zan_conocimiento", name = "Conocimiento Antiguo", type = "pasivo", description = "Competencia en Historia.", effects = { { kind = "skillProf", skill = "Historia" } } },
                { id = "tro_zan_loa", name = "Abrazo de los Loa", type = "informativo", description = "Conoces guia; a nivel 3 lanzas habilidad mejorada 1 vez al dia (Sabiduria).", effects = {} },
                { id = "tro_zan_armas", name = "Entrenamiento con Armas Zandalari", type = "informativo", description = "Competencia con hachas de mano, hachas de batalla, espadas largas y espadas grandes.", effects = {} },
            } },
            { id = "bosque", name = "Trol de Bosque", traits = {
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
                { id = "tro_bos_armas", name = "Entrenamiento con Armas Troll", type = "informativo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = {} },
            } },
            { id = "hielo", name = "Troll de Hielo", traits = {
                { id = "tro_hie_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Fuerza +2.", effects = { { kind = "bonus", target = "ability", ability = "Fuerza", value = 2 } } },
                { id = "tro_hie_piel", name = "Piel de Nacido del Hielo", type = "informativo", description = "Resistencia al daño por frio.", effects = {} },
                { id = "tro_hie_constitucion", name = "Constitucion Poderosa", type = "informativo", description = "Cuentas como una criatura de un tamaño mayor para carga/empujar/arrastrar/levantar.", effects = {} },
                { id = "tro_hie_armas", name = "Entrenamiento con Armas Troll", type = "informativo", description = "Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.", effects = {} },
            } },
        },
        traits = {
            { id = "tro_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Constitucion +1.", effects = { { kind = "bonus", target = "ability", ability = "Constitucion", value = 1 } } },
            { id = "tro_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 60 pies (tonos de gris).", effects = {} },
            { id = "tro_regeneracion", name = "Regeneracion", type = "informativo", description = "Al gastar un Dado de Golpe recuperas lo lanzado + el doble de tu Mod. Constitucion; como accion puedes gastar dados hasta la mitad de tu nivel. Recarga con descanso largo.", effects = {} },
            { id = "tro_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Zandali.", effects = {} },
        },
    },
    {
        id = "elfo_sangre", name = "Elfo de Sangre", faction = "horda", size = "Mediano", speed = 9,
        traits = {
            { id = "esa_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Destreza +2 e Inteligencia +1.", effects = {
                { kind = "bonus", target = "ability", ability = "Destreza", value = 2 },
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
            } },
            { id = "esa_vision", name = "Vision en la Oscuridad", type = "informativo", description = "Vision en la oscuridad a 60 pies (tonos de gris).", effects = {} },
            { id = "esa_arcano", name = "Conocimiento Arcano", type = "pasivo", description = "Competencia en Arcano; lanzas detectar magia (Inteligencia) 1 vez por descanso.", effects = { { kind = "skillProf", skill = "Arcano" } } },
            { id = "esa_sentidos", name = "Sentidos Agudos", type = "pasivo", description = "Competencia en Percepcion.", effects = { { kind = "skillProf", skill = "Percepcion" } } },
            { id = "esa_reversion", name = "Reversion de Conjuros", type = "informativo", description = "Al fallar una salvacion contra un conjuro, repites la tirada (usas el nuevo resultado). Recarga con descanso.", effects = {} },
            { id = "esa_legado", name = "Legado Thalassiano", type = "choice", description = "Elige un beneficio.", effects = {}, choice = {
                slots = 1,
                options = {
                    { id = "truco", label = "Un truco de mago (Inteligencia)", effects = {} },
                    { id = "armas", label = "Competencia con espada gemela, guja, arco corto y largo", effects = {} },
                },
            } },
            { id = "esa_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun y Thalassiano.", effects = {} },
        },
    },
    {
        id = "goblin", name = "Goblin", faction = "horda", size = "Pequeño", speed = 7.5,
        traits = {
            { id = "gob_inc", name = "Incremento de Caracteristica", type = "pasivo", description = "Inteligencia +1 y Carisma +2.", effects = {
                { kind = "bonus", target = "ability", ability = "Inteligencia", value = 1 },
                { kind = "bonus", target = "ability", ability = "Carisma", value = 2 },
            } },
            { id = "gob_tratos", name = "Mejores Tratos", type = "informativo", description = "Al regatear (Carisma/Persuasion), competente y sumas el doble de tu bono de competencia.", effects = {} },
            { id = "gob_esquivar", name = "Esquivar", type = "informativo", description = "Ventaja en una salvacion de Destreza contra un efecto visible (antes de tirar). Recarga con descanso.", effects = {} },
            { id = "gob_ingenieria", name = "Ingenieria Goblin", type = "informativo", description = "Competencia con herramientas de artesano; construyes dispositivos con un hechizo a elegir (Inteligencia).", effects = {} },
            { id = "gob_familiaridad", name = "Familiaridad Mecanica", type = "informativo", description = "Competencia en armas de fuego y herramientas de armero.", effects = {} },
            { id = "gob_idiomas", name = "Idiomas", type = "informativo", description = "Hablas, lees y escribes Comun, Goblin y un idioma adicional de tu eleccion.", effects = {} },
        },
    },
}

local raceById, raceOrder

local function Normalize(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[_%-]+", " ")
    value = value:gsub("[áàäâÁÀÄÂ]", "a")
    value = value:gsub("[éèëêÉÈËÊ]", "e")
    value = value:gsub("[íìïîÍÌÏÎ]", "i")
    value = value:gsub("[óòöôÓÒÖÔ]", "o")
    value = value:gsub("[úùüûÚÙÜÛ]", "u")
    value = value:gsub("[ñÑ]", "n")
    return value:gsub("^%s+", ""):gsub("%s+$", "")
end

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
    local bestId, bestLen
    for _, raceDef in ipairs(API.RACES) do
        local candidates = { raceDef.id, raceDef.name }
        for _, candidate in ipairs(candidates) do
            local normalized = Normalize(candidate)
            if normalized ~= "" and clean:find(normalized, 1, true) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = raceDef.id, len
                end
            end
        end
        for _, sub in ipairs(raceDef.subraces or {}) do
            local normalized = Normalize(sub.name)
            if normalized ~= "" and clean:find(normalized, 1, true) then
                local len = #normalized
                if not bestLen or len > bestLen then
                    bestId, bestLen = raceDef.id, len
                end
            end
        end
    end
    return bestId
end

function API.FindSubraceIdByText(raceId, text)
    local raceDef = API.GetRace(raceId)
    local clean = Normalize(text)
    if not raceDef or clean == "" then return nil end
    local bestId, bestLen
    for _, sub in ipairs(raceDef.subraces or {}) do
        local candidates = { sub.id, sub.name }
        for _, candidate in ipairs(candidates) do
            local normalized = Normalize(candidate)
            if normalized ~= "" and clean:find(normalized, 1, true) then
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
