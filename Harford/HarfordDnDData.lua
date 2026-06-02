-- HarfordDnDData: tablas de datos estaticos de la ficha D&D 5e.
-- Solo datos, sin logica. Las consume HarfordDnD.lua (y quien necesite el orden
-- canonico de caracteristicas/habilidades).

HarfordDnDData = HarfordDnDData or {}

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
