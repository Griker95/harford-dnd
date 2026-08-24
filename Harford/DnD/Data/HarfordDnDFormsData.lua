-- HarfordDnDFormsData: las 7 formas canonicas de Cambio de Forma (Anexo A del manual).
-- Solo datos. `HarfordDnDForms` (State) las mezcla con las que el jugador declare en su ficha
-- TRP3: una forma de TRP3 con el mismo id SUSTITUYE a la canonica, para no pisar personalizaciones.
--
-- La CA se declara como `armorClassBase` + `armorClassAbilities` porque el manual la da como
-- "12 + Mod. Destreza", no como un numero fijo. Las formas de TRP3 traen su CA ya calculada.
--
-- `minLevel` es el nivel de druida al que se desbloquea la forma (tabla de Formas de Cambio).
--
-- Caracteristica de ataque: el manual la fija por forma. Las que dejan ELEGIR entre Fuerza y
-- Destreza llevan la propiedad "Sutil", que es como el calculo comun expresa "el mejor de los dos".

HarfordDnDFormsData = HarfordDnDFormsData or {}

local function Ataque(nombre, dmgN, dmgS, tipo, sutil)
    local props = { "Natural" }
    if sutil then props[#props + 1] = "Sutil" end
    return {
        key = nombre, cat = "Forma", mode = "Melee", rangeFeet = 5,
        targetText = "un objetivo",
        dmgN = dmgN, dmgS = dmgS, dmgType = tipo,
        addAbi = true,                    -- el manual dice "(1dX + modificador)"
        ignoreGlobalWeaponBonuses = true, -- la forma no hereda bonos del equipo
        source = "form", props = props,
    }
end

HarfordDnDFormsData.FORMS = {
    {
        id = "gato", name = "Forma de Gato", minLevel = 2, size = "Mediano",
        armorClassBase = 12, armorClassAbilities = { "Destreza" },
        speed = 40, icon = "ability_druid_catform",
        traits = { "Vision en la oscuridad 18 m", "Olfato Agudo: ventaja en Sabiduria (Percepcion) por olfato",
                   "Embestida: si te mueves 6 m en linea recta antes de golpear, salvacion de Fuerza (CD 8 + Mod. Destreza + competencia) o derribada; si falla, tu ataque de ese turno causa 2d6 adicionales",
                   "Multiataque: al Atacar puedes usar una accion adicional para atacar con un arma diferente" },
        actions = { Ataque("Mordisco", 1, 6, "perforante", true), Ataque("Garra", 1, 8, "cortante", true) },
    },
    {
        id = "oso", name = "Forma de Oso", minLevel = 2, size = "Mediano",
        armorClassBase = 12, armorClassAbilities = { "Destreza", "Constitucion" },
        speed = 40, icon = "ability_racial_bearform",
        traits = { "Olfato Agudo: ventaja en Sabiduria (Percepcion) por olfato", "Trepar 9 m",
                   "Carga: si te mueves 6 m en linea recta y golpeas, 1d8 adicional; si el objetivo es una criatura, salvacion de Fuerza (CD 8 + Mod. Fuerza + competencia) o derribada" },
        actions = { Ataque("Mordisco", 1, 8, "perforante"), Ataque("Garra", 1, 12, "cortante") },
    },
    {
        id = "lechucito_lunar", name = "Forma de Lechucito Lunar", minLevel = 2, size = "Mediano",
        armorClassBase = 12, armorClassAbilities = { "Destreza" },
        speed = 30, icon = "spell_druid_owlkinfrenzy",
        traits = { "Vision en la oscuridad 18 m", "Vista Aguda: ventaja en Sabiduria (Percepcion) por vista",
                   "Conjuracion: puedes lanzar conjuros de druida y hacer sus componentes en esta forma. Al lanzar uno que cause dano puedes repetir un dado; debes usar el nuevo resultado" },
        actions = { Ataque("Pico", 1, 6, "perforante"), Ataque("Garra", 1, 4, "cortante") },
    },
    {
        id = "antarbol", name = "Forma de Antarbol", minLevel = 2, size = "Mediano",
        armorClassBase = 12, armorClassAbilities = { "Destreza" },
        speed = 30, icon = "ability_druid_treeoflife",
        traits = { "Apariencia Falsa: inmovil, ventaja en Destreza (Sigilo)",
                   "Susurro de Plantas: preguntas a las plantas por sucesos del ultimo dia",
                   "Conjuracion: puedes lanzar conjuros de druida en esta forma. Al restaurar puntos de golpe, un 1 natural puede cambiarse a 2" },
        actions = { Ataque("Garra", 1, 6, "cortante") },
    },
    {
        id = "acuatica", name = "Forma Acuatica", minLevel = 4, size = "Mediano",
        armorClassBase = 12, armorClassAbilities = { "Destreza" },
        speed = 0, icon = "ability_druid_aquaticform",
        traits = { "Nado 15 m", "Vision ciega 18 m", "Respiracion Acuatica: solo respiras bajo el agua",
                   "Ritmo de Viaje: viajando 1 hora o mas, tu ritmo total se duplica" },
        actions = { Ataque("Mordisco", 1, 8, "perforante") },
    },
    {
        id = "viaje", name = "Forma de Viaje", minLevel = 4, size = "Grande",
        armorClassBase = 12, armorClassAbilities = { "Destreza" },
        speed = 50, icon = "ability_druid_travelform",
        traits = { "Montura Estable: quien te monte tiene ventaja en salvaciones de Destreza para mantenerse",
                   "Ritmo de Viaje: viajando 1 hora o mas, tu ritmo total se duplica" },
        actions = { Ataque("Cornada", 1, 6, "cortante", true) },
    },
    {
        id = "vuelo", name = "Forma de Vuelo", minLevel = 8, size = "Grande",
        armorClassBase = 12, armorClassAbilities = { "Destreza" },
        speed = 10, icon = "ability_druid_flightform",
        traits = { "Volar 21 m", "Vuelo Rapido: no provocas ataques de oportunidad al volar fuera del alcance",
                   "Vista Aguda: ventaja en Sabiduria (Percepcion) por vista",
                   "Ritmo de Viaje: viajando 1 hora o mas, tu ritmo total se duplica" },
        actions = { Ataque("Pico", 1, 10, "perforante", true), Ataque("Garra", 1, 4, "cortante", true) },
    },
}
