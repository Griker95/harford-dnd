-- HarfordDnDData: tablas de datos estaticos de la ficha D&D 5e.
-- Solo datos, sin logica. Las consume HarfordDnD.lua (y quien necesite el orden
-- canonico de caracteristicas/habilidades).

HarfordDnDData = HarfordDnDData or {}

-- Caracteristicas en orden de ficha. `key` es la clave ARC; `short` la etiqueta.
HarfordDnDData.ABIL = {
    { key = "Fuerza",       short = "FUE" },
    { key = "Destreza",     short = "DES" },
    { key = "Constitucion", short = "CON" },
    { key = "Inteligencia", short = "INT" },
    { key = "Sabiduria",    short = "SAB" },
    { key = "Carisma",      short = "CAR" },
}

-- Habilidades en orden de ficha. `ability` referencia una key de ABIL.
HarfordDnDData.SKILLS = {
    { name="Acrobacias", ability="Destreza", id="Acrobacias" },
    { name="Atletismo", ability="Fuerza", id="Atletismo" },
    { name="Conocimiento Arcano", ability="Inteligencia", id="Arcano" },
    { name="Engaño", ability="Carisma", id="Engano" },
    { name="Historia", ability="Inteligencia", id="Historia" },
    { name="Interpretación", ability="Carisma", id="Interpretacion" },
    { name="Intimidación", ability="Carisma", id="Intimidacion" },
    { name="Investigación", ability="Inteligencia", id="Investigacion" },
    { name="Juego de Manos", ability="Destreza", id="JuegoManos" },
    { name="Medicina", ability="Sabiduria", id="Medicina" },
    { name="Naturaleza", ability="Inteligencia", id="Naturaleza" },
    { name="Percepción", ability="Sabiduria", id="Percepcion" },
    { name="Perspicacia", ability="Sabiduria", id="Perspicacia" },
    { name="Persuasión", ability="Carisma", id="Persuasion" },
    { name="Religión", ability="Inteligencia", id="Religion" },
    { name="Sigilo", ability="Destreza", id="Sigilo" },
    { name="Supervivencia", ability="Sabiduria", id="Supervivencia" },
    { name="Trato con Animales", ability="Sabiduria", id="Animales" },
}
