-- HarfordEmotes: tabla de datos de emotes/animaciones servidor que el addon usa.
-- Sigue el patron canonico de HarfordDnDResources: ORDER + DEFS + helpers + constantes.
-- Solo datos: no construye comandos ni envia nada al servidor.

HarfordEmotes = HarfordEmotes or {}

-- Sembrar el RNG una vez al cargar: WoW arranca math.random con semilla fija, lo que
-- produce la MISMA secuencia cada sesion y patrones por posicion. La defensa del NPC
-- consume el RNG en posiciones fijas (2 d20 + 1 pick por fallo) y sin sembrar tendia
-- a elegir siempre lo mismo (solo dodge). Sembrar con la hora rompe ese patron.
if not HarfordEmotes._seeded and math.randomseed then
    local seed = (GetServerTime and GetServerTime())
        or (time and time())
        or (GetTime and math.floor(GetTime() * 1000))
        or 1
    math.randomseed(seed)
    for _ = 1, 5 do math.random() end  -- descartar primeros valores (calentar)
    HarfordEmotes._seeded = true
end

-- Reaccion breve del NPC al recibir dano real (`npc emote 33` = ONESHOT_WOUND).
-- HarfordServerActions.SetNpcHealthDelta lo dispara al restar mas de 1.
HarfordEmotes.NPC_WOUND = { id = 33, label = "Herida (ONESHOT_WOUND)" }

-- Variante critica: golpe especialmente potente (`npc emote 34` = ONESHOT_WOUND_CRIT).
-- SetNpcHealthDelta la usa cuando opts.isCritical = true.
HarfordEmotes.NPC_WOUND_CRIT = { id = 34, label = "Herida crítica (ONESHOT_WOUND_CRIT)" }

-- Lista de emotes de combate ofrecidos en el dropdown del panel NPC del DM.
-- ORDER se respeta tal cual en el dropdown; "none" no envia comando.
HarfordEmotes.ORDER = {
    "none",
    "unarmed",
    "one_hand",
    "two_hand",
    "polearm",
    "bow",
    "rifle",
    "offhand",
    "thrust",
    "thrust_2hl",
    "thrust_offhand",
    "throw",
    "unarmed_offhand",
}

HarfordEmotes.DEFS = {
    none             = { id = nil,  label = "Ninguno",           weaponClass = nil       },
    unarmed          = { id = 2016, label = "Desarmado",         weaponClass = "unarmed" },
    one_hand         = { id = 2017, label = "Una mano",          weaponClass = "1h"      },
    two_hand         = { id = 2018, label = "A dos manos",       weaponClass = "2h"      },
    polearm          = { id = 2018, label = "Arma Asta",         weaponClass = "polearm" },
    bow              = { id = 2046, label = "Arco",              weaponClass = "bow"     },
    rifle            = { id = 2049, label = "Rifle",             weaponClass = "rifle"   },
    offhand          = { id = 2087, label = "Offhand",           weaponClass = "offhand" },
    thrust           = { id = 2085, label = "Estocada",          weaponClass = "1h"      },
    thrust_2hl       = { id = 2086, label = "Estocada 2HL",      weaponClass = "2h"      },
    thrust_offhand   = { id = 2088, label = "Estocada Offhand",  weaponClass = "offhand" },
    throw            = { id = 2107, label = "Lanzar",            weaponClass = "throw"   },
    unarmed_offhand  = { id = 2117, label = "Desarmado Offhand", weaponClass = "offhand" },
}

function HarfordEmotes.Get(key)
    return key and HarfordEmotes.DEFS[key] or nil
end

function HarfordEmotes.GetById(id)
    if id == nil then return nil, "none" end
    for _, key in ipairs(HarfordEmotes.ORDER) do
        local def = HarfordEmotes.DEFS[key]
        if def and def.id == id then return def, key end
    end
    return nil, nil
end

-- Lista ordenada para alimentar dropdowns: { { key, id, label }, ... }
function HarfordEmotes.GetOrderedList()
    local list = {}
    for _, key in ipairs(HarfordEmotes.ORDER) do
        local def = HarfordEmotes.DEFS[key]
        if def then
            list[#list + 1] = { key = key, id = def.id, label = def.label }
        end
    end
    return list
end

function HarfordEmotes.Default()
    return HarfordEmotes.DEFS.none, "none"
end

-- ─── Modo combate ───────────────────────────────────────────────────────────
-- Posturas de combate persistentes (`npc emote`/`mod anim`). "stand" sale del
-- modo combate: en el jugador es `mod anim 26` (id), en el NPC es
-- `npc emote 0 repeat` (npcId). El resto se mapea desde el arma equipada del
-- jugador y se ofrece tal cual en el dropdown de la ficha NPC; cuando npcId no
-- se declara, el dropdown NPC reutiliza id. Versátil activo → "two_hand".
HarfordEmotes.COMBAT_ORDER = {
    "stand",
    "unarmed",
    "one_hand",
    "two_hand",
    "polearm",
    "bow",
    "rifle",
    "spell_direct",
    "spell_area",
    "thrown",
}

HarfordEmotes.COMBAT_DEFS = {
    stand        = { id = 26,   npcId = 0, label = "Stand"  },
    unarmed      = { id = 4254, label = "Desarmado"        },
    one_hand     = { id = 4255, label = "Una mano"         },
    two_hand     = { id = 4256, label = "A dos manos"      },
    polearm      = { id = 4257, label = "Armas de asta"    },
    bow          = { id = 4258, label = "Arco"             },
    rifle        = { id = 4277, label = "Rifle y ballesta" },
    spell_direct = { id = 4280, label = "Hechizo directo"  },
    spell_area   = { id = 4281, label = "Hechizo área"     },
    thrown       = { id = 4337, label = "Arrojadiza"       },
}

-- Lista ordenada para el dropdown de modo combate: { { key, id, npcId, label }, ... }
-- id    -> emote para el jugador (`mod anim`).
-- npcId -> emote para la ficha NPC (`npc emote ... repeat`); por defecto = id.
function HarfordEmotes.GetCombatList()
    local list = {}
    for _, key in ipairs(HarfordEmotes.COMBAT_ORDER) do
        local def = HarfordEmotes.COMBAT_DEFS[key]
        if def then
            list[#list + 1] = {
                key   = key,
                id    = def.id,
                npcId = def.npcId or def.id,
                label = def.label,
            }
        end
    end
    return list
end

function HarfordEmotes.GetCombat(key)
    return key and HarfordEmotes.COMBAT_DEFS[key] or nil
end

-- ─── Reaccion defensiva al fallar un ataque (parry/dodge/block) ───────────────
-- Cada postura tiene una LISTA de defensas posibles; se elige una AL AZAR en cada
-- fallo (un guerrero con arma puede parar o esquivar; a distancia/desarmado solo
-- esquiva). Cada entrada es el nombre de una secuencia de HarfordActionSequence
-- (anim de defensa + vuelta a postura + sonido). La misma secuencia sirve para el
-- jugador defensor (`mod anim` en su cliente) y para el NPC (npcAnim -> npc emote).
HarfordEmotes.DEFENSE_DEFS = {
    one_hand     = { "OnehandParry", "OnehandDodge" },
    two_hand     = { "TwohandParry", "TwohandDodge" },
    polearm      = { "PolearmParry", "PolearmDodge" },
    unarmed      = { "FistBlock",    "FistDodge"    },
    bow          = { "FistDodge" },
    rifle        = { "FistDodge" },
    spell_direct = { "FistDodge" },
    spell_area   = { "FistDodge" },
    thrown       = { "FistDodge" },
    stand        = { "FistDodge" },
}

-- Defensas cuando el defensor lleva ESCUDO (prioridad sobre la postura): bloquear
-- o esquivar al azar. Solo aplica a defensores jugador (se detecta su equipo).
HarfordEmotes.SHIELD_DEFENSE_DEFS = { "ShieldBlock", "OnehandDodge" }

-- Defensa por defecto cuando no se conoce el modo de combate del defensor: se asume
-- arma a una mano -> parar o esquivar al azar (no solo esquivar).
HarfordEmotes.DEFAULT_DEFENSE_DEFS = HarfordEmotes.DEFENSE_DEFS.one_hand

-- Devuelve el NOMBRE de una secuencia de defensa elegida al azar para la postura
-- (o la lista de escudo si hasShield). nil si no hay opciones.
function HarfordEmotes.PickDefenseSeq(key, hasShield)
    local list = (hasShield and HarfordEmotes.SHIELD_DEFENSE_DEFS)
        or (key and HarfordEmotes.DEFENSE_DEFS[key])
        or HarfordEmotes.DEFAULT_DEFENSE_DEFS
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

-- ─── Secuencia de ATAQUE por familia de animacion ─────────────────────────────
-- Mapea la familia (HarfordDnDWeapons.GetAnimFamily) al preset de ataque a usar
-- segun el contexto: golpe normal, critico (golpe pesado) u offhand (mano
-- secundaria). Solo familias cuerpo a cuerpo: arco/rifle/conjuro mantienen el
-- emote actual y no pasan por aqui.
HarfordEmotes.ATTACK_SEQ_DEFS = {
    unarmed  = { normal = "FistAttack",    critical = "FistSpecial",       offhand = "FistAttack"    },
    one_hand = { normal = "OnehandAttack", critical = "OnehandChop",       offhand = "OffhandAttack" },
    two_hand = { normal = "TwohandAttack", critical = "TwohandObliterate", offhand = "TwohandAttack" },
    polearm  = { normal = "PolearmAttack", critical = "PolearmObliterate", offhand = "PolearmAttack" },
    shield   = { normal = "ShieldBash",    critical = "ShieldBashSlash",   offhand = "ShieldBash"    },
}

-- Devuelve el NOMBRE del preset de ataque (registrado en HarfordActionSequence).
-- opts: { critical = bool, offhand = bool }. offhand tiene prioridad (define que
-- arma golpea); luego critico; si no, el golpe normal. nil si no hay familia melee.
function HarfordEmotes.GetAttackSequence(family, opts)
    local def = family and HarfordEmotes.ATTACK_SEQ_DEFS[family]
    if not def then return nil end
    opts = opts or {}
    if opts.offhand and def.offhand then return def.offhand end
    if opts.critical and def.critical then return def.critical end
    return def.normal
end
