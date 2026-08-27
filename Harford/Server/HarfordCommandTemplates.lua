-- HarfordCommandTemplates: plantillas de comandos Epsilon con placeholders
-- {clave}. Concentra los strings literales para que HarfordServerActions y
-- otros consumidores no construyan comandos a base de `..` repartidos.
--
-- Reglas:
--   * Las plantillas no incluyen el punto inicial (lo añade EpsilonLib/ARC).
--   * Los valores numericos se siguen validando en HarfordServerActions
--     (ToPositiveInteger); este modulo solo interpola.
--
-- Convencion de scope reflejada en los nombres:
--   *_SELF   -> sufijo "self" (propio personaje, jugador).
--   *_TARGET -> sin sufijo    (unit seleccionado en juego).
--   NPC_*    -> "npc set ..." (NPC poseido/objetivo).

HarfordCommandTemplates = HarfordCommandTemplates or {}

-- Vuelve al sitio exacto donde terminaste tu turno. Los decimales importan: seis, como los emite
-- Epsilon, porque redondear a menos te deja dentro de una pared.
HarfordCommandTemplates.WORLDPORT      = "worldport {x} {y} {z} {map} {o}"

HarfordCommandTemplates.AURA_SELF      = "aura {id} self"
HarfordCommandTemplates.AURA_TARGET    = "aura {id}"
HarfordCommandTemplates.UNAURA_SELF    = "unaura {id} self"
HarfordCommandTemplates.UNAURA_TARGET  = "unaura {id}"
HarfordCommandTemplates.NPC_SET_AURA   = "npc set aura {id}"
HarfordCommandTemplates.NPC_SET_UNAURA = "npc set unaura {id}"
HarfordCommandTemplates.NPC_EMOTE        = "npc emote {id}"
HarfordCommandTemplates.NPC_EMOTE_REPEAT = "npc emote {id} repeat"
HarfordCommandTemplates.NPC_SET_HEALTH = "npc set health {sign}{amount}"
HarfordCommandTemplates.MOD_ANIM       = "mod anim {id}"
HarfordCommandTemplates.ADD_ITEM       = "additem {id} {qty}"
-- Consumir items: `additem <id> -<qty>` con cantidad NEGATIVA quita del inventario. VERIFICADO en
-- juego (Epsilon/AzerothCore). Lo usan las profesiones para gastar materiales al craftear.
HarfordCommandTemplates.REMOVE_ITEM    = "additem {id} -{qty}"
-- Dinero en COBRE (1 oro = 100 plata = 10000 cobre). Epsilon usa el subcomando
-- completo `modify money`; `mod money` no existe y el servidor lo rechaza.
HarfordCommandTemplates.MOD_MONEY      = "modify money {copper}"
HarfordCommandTemplates.PH_F_N_FAC     = "ph f n fac {factionId}"
HarfordCommandTemplates.PHASE_INFO     = "phase info addon"
HarfordCommandTemplates.UNPOSS         = "unposs"
HarfordCommandTemplates.POSS           = "poss"

-- Interpola {clave} con args[clave]. Si falta una clave referenciada, devuelve
-- nil + mensaje de error (preferible a producir un comando con "{id}" literal).
function HarfordCommandTemplates.Build(template, args)
    if type(template) ~= "string" then
        return nil, "template no es string"
    end
    args = args or {}

    local missing
    local result = template:gsub("{(%w+)}", function(key)
        local value = args[key]
        if value == nil then
            missing = missing or key
            return ""
        end
        return tostring(value)
    end)
    if missing then
        return nil, "placeholder ausente: " .. tostring(missing)
    end
    return result
end
