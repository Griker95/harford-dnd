-- HarfordActionSequencePresets: catalogo hardcodeado de secuencias de ataque
-- decodificadas desde SpellCreator/ArcSpell. Mantener solo datos aqui; el motor
-- vive en HarfordActionSequence.lua.
--
-- Fuente: SpellCreatorSavedSpells en WTF/Account/MORTYN/SavedVariables/SpellCreator.lua
-- Filtro: commID/key que empieza por Galerne.

if not (HarfordActionSequence and HarfordActionSequence.Register) then return end

local Register = HarfordActionSequence.Register

-- Anim Fist attack
-- Attack and back into stance
-- icon: 2903169
Register("FistAttack", {
    { delay = 0, actionType = "Anim", vars = "35", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "27", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Fist Block
-- Attack and back into stance
-- icon: 999951
Register("FistBlock", {
    { delay = 0, actionType = "Anim", vars = "39", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "27", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Fist Dodge
-- Dodge and back into stance
-- icon: 461119
Register("FistDodge", {
    { delay = 0, actionType = "Anim", vars = "2030", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "27", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "15927, SFX, 20", selfOnly = false },
})

-- Anim Fist Kick
-- Kick and back into stance
-- icon: 132219
Register("FistKick", {
    { delay = 0, actionType = "Anim", vars = "60", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "27", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Fist Special
-- Special attack and back into stance
-- icon: 463460
Register("FistSpecial", {
    { delay = 0, actionType = "Anim", vars = "477", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "27", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Glaive Main Attack
-- Attack with main hand and back into stance
-- icon: 2267322
Register("GlaiveAttack", {
    { delay = 0, actionType = "Anim", vars = "664", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53246, SFX, 20", selfOnly = false },
})

-- Anim Glaive Dodge
-- Dodge and back into stance
-- icon: 461119
Register("GlaiveDodge", {
    { delay = 0, actionType = "Anim", vars = "2030", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "15927, SFX, 20", selfOnly = false },
})

-- Anim Glaive Double Attack
-- Attack with both hands and back into stance
-- icon: 1309100
Register("GlaiveDoubleAttack", {
    { delay = 0, actionType = "Anim", vars = "666", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53246, SFX, 20", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56761, SFX, 20", selfOnly = false },
})

-- Anim Glaive Dual Attack
-- Jump in the air to deliver a blow with both weapons and get back into stance. They are not prepared.
-- icon: 1309101
Register("GlaiveDualAttack", {
    { delay = 0, actionType = "Anim", vars = "3028", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.3, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.3, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56761, SFX, 20", selfOnly = false },
})

-- Anim Glaive Jump Attack
-- Jump attack with main hand and back into stance
-- icon: 1305159
Register("GlaiveJumpAttack", {
    { delay = 0, actionType = "Anim", vars = "3022", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53246, SFX, 20", selfOnly = false },
})

-- Anim Glaive Kick
-- Kick and back into stance
-- icon: 132219
Register("GlaiveKick", {
    { delay = 0, actionType = "Anim", vars = "60", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Glaive Off Attack
-- Attack with off hand and back into stance
-- icon: 1970140
Register("GlaiveOffAttack", {
    { delay = 0, actionType = "Anim", vars = "665", selfOnly = false },
    { delay = 0.8, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53246, SFX, 20", selfOnly = false },
})

-- Anim Glaive Spin
-- Spin into an attack and back into stance
-- icon: 1117879
Register("GlaiveSpin", {
    { delay = 0, actionType = "Anim", vars = "3016", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "663", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53246, SFX, 20", selfOnly = false },
})

-- Anim MonkDef attack
-- Attack and back into stance
-- icon: 606543
Register("MonkDefAttack", {
    { delay = 0, actionType = "Anim", vars = "2682", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "706", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim MonkDef Block
-- Parry and back into stance
-- icon: 615342
Register("MonkDefBlock", {
    { delay = 0, actionType = "Anim", vars = "2686", selfOnly = false },
    { delay = 1.1, actionType = "Anim", vars = "706", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "15927, SFX, 20", selfOnly = false },
})

-- Anim MonkDef Kick
-- Kick and back into stance
-- icon: 132219
Register("MonkDefKick", {
    { delay = 0, actionType = "Anim", vars = "60", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "706", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim MonkDef Offattack
-- Attack and back into stance
-- icon: 2447780
Register("MonkDefOffAttack", {
    { delay = 0, actionType = "Anim", vars = "2684", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "706", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim MonkDef EyeJab
-- Go for the eyes then the balls! You don't fight for honor, you fight to win!
-- icon: 1305156
Register("MonkDefSpecial", {
    { delay = 0, actionType = "Anim", vars = "2690", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "706", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
    { delay = 0.6, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.6, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Monk OffAttack
-- Attack with offhand and back into stance
-- icon: 574572
Register("MonkOffAttack2", {
    { delay = 0, actionType = "Anim", vars = "2674", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "510", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Monk palm
-- Charged palm attack and back into stance
-- icon: 606551
Register("MonkPalm", {
    { delay = 0, actionType = "Anim", vars = "511", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "510", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Monk Rising Sun Kick
-- Cartwheel kick and back into stance. You're a reak martial artist.
-- icon: 642415
Register("MonkRisingSunKick", {
    { delay = 0, actionType = "Anim", vars = "2736", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "510", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Monk Hadouken
-- Special attack and back into stance
-- icon: 607848
Register("MonkSpecial", {
    { delay = 0, actionType = "Anim", vars = "508", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "510", selfOnly = false },
    { delay = 0.45, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.45, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim OffHand attack
-- Attack with your off hand weapon and back into stance
-- icon: 454059
Register("OffhandAttack", {
    { delay = 0, actionType = "Anim", vars = "389", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = "npc cast 78960", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
})

-- Anim OffHand Carve
-- A carving motion with your off hand weapon and back into stance
-- icon: 1376039
Register("OffhandCarve", {
    { delay = 0, actionType = "Anim", vars = "3320", selfOnly = false },
    { delay = 0.9, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim OffHand Chop
-- Chop with your off hand weapon and back into stance
-- icon: 383597
Register("OffhandChop", {
    { delay = 0, actionType = "Anim", vars = "2970", selfOnly = false },
    { delay = 0.9, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim OffHand Slice
-- Upward slice with your off hand weapon and back into stance
-- icon: 132306
Register("OffhandSlice", {
    { delay = 0, actionType = "Anim", vars = "2972", selfOnly = false },
    { delay = 0.9, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim OffHand Stab
-- Stab with your off hand weapon and back into stance
-- icon: 132090
Register("OffhandStab", {
    { delay = 0, actionType = "Anim", vars = "2998", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H attack
-- Attack and back into stance
-- icon: 135275
Register("OnehandAttack", {
    { delay = 0, actionType = "Anim", vars = "36", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H Berserk
-- Wail on your target with both weapons and back into stance
-- icon: 135726
Register("OneHandBerserk", {
    { delay = 0, actionType = "Anim", vars = "2979", selfOnly = false },
    { delay = 2, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
    { delay = 1.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 1.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H chop
-- Large chop and back into stance
-- icon: 1698637
Register("OnehandChop", {
    { delay = 0, actionType = "Anim", vars = "2822", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.3, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.3, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H Dodge
-- Dodge and back into stance
-- icon: 461119
Register("OnehandDodge", {
    { delay = 0, actionType = "Anim", vars = "2030", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "15927, SFX, 20", selfOnly = false },
})

-- Anim 1H Double Slash
-- Attack with both weapons and back into stance
-- icon: 537468
Register("OneHandDouble", {
    { delay = 0, actionType = "Anim", vars = "3322", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
    { delay = 0.6, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.6, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H Simultaneous Stab
-- Stab with both weapons at once and back into stance
-- icon: 1301080
Register("OneHandDoubleStab", {
    { delay = 0, actionType = "Anim", vars = "2212", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = "npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "333", selfOnly = false },
})

-- Anim 1H Dual Stab
-- Stab with both weapons and back into stance
-- icon: 1273726
Register("OneHandDualStab", {
    { delay = 0, actionType = "Anim", vars = "3034", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
    { delay = 0.6, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.6, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H Kick
-- Kick and back into stance
-- icon: 132219
Register("OnehandKick", {
    { delay = 0, actionType = "Anim", vars = "60", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim 1H low attack
-- Low attack and back into stance
-- icon: 135272
Register("OnehandLowAttack", {
    { delay = 0, actionType = "Anim", vars = "2818", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim 1H parry
-- Block and back into stance
-- icon: 132269
Register("OnehandParry", {
    { delay = 0, actionType = "Anim", vars = "441", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69052, SFX, 20", selfOnly = false },
})

-- Anim 1H Simultaneous Strike
-- Attack with both weapons at once and back into stance
-- icon: 132147
Register("OneHandSimultaneous", {
    { delay = 0, actionType = "Anim", vars = "2650", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim 1H spin
-- Large chop and back into stance
-- icon: 132109
Register("OnehandSpin", {
    { delay = 0, actionType = "Anim", vars = "2824", selfOnly = false },
    { delay = 0.3, actionType = "Command", vars = "npc cast 78960", selfOnly = false },
    { delay = 0.3, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
    { delay = 0.9, actionType = "Anim", vars = "333", selfOnly = false },
})

-- Anim 1H stab
-- Stab and back into stance
-- icon: 897137
Register("OnehandStab", {
    { delay = 0, actionType = "Anim", vars = "2085", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim Polearm attack
-- Attack and back into stance
-- icon: 1376046
Register("PolearmAttack", {
    { delay = 0, actionType = "Anim", vars = "38", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "127374, SFX, 20", selfOnly = false },
})

-- Anim Polearm Chop
-- Side choping attack and back into stance
-- icon: 589119
Register("PolearmChop", {
    { delay = 0, actionType = "Anim", vars = "2823", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim Polearm Cleave
-- Cleaving attack and back into stance
-- icon: 460959
Register("PolearmCleave", {
    { delay = 0, actionType = "Anim", vars = "2827", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim Polearm Dodge
-- Dodge and back into stance
-- icon: 461119
Register("PolearmDodge", {
    { delay = 0, actionType = "Anim", vars = "2030", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "15927, SFX, 20", selfOnly = false },
})

-- Anim Polearm Execute
-- Exec attack and back into stance
-- icon: 132413
Register("PolearmExecute", {
    { delay = 0, actionType = "Anim", vars = "3064", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim Polearm Jump Spin
-- Jump spin attack and back into stance
-- icon: 645223
Register("PolearmJumpSpin", {
    { delay = 0, actionType = "Anim", vars = "2845", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim Polearm Kick
-- Kick and back into stance
-- icon: 132219
Register("PolearmKick", {
    { delay = 0, actionType = "Anim", vars = "60", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim Polearm Obliterate
-- Large overhead strike and back into stance
-- icon: 625998
Register("PolearmObliterate", {
    { delay = 0, actionType = "Anim", vars = "2656", selfOnly = false },
    { delay = 1.25, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.7, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.7, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim Polearm Overhead
-- Overhead attack and back into stance
-- icon: 132363
Register("PolearmOverhead", {
    { delay = 0, actionType = "Anim", vars = "3016", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim Polearm parry
-- Block and back into stance
-- icon: 135159
Register("PolearmParry", {
    { delay = 0, actionType = "Anim", vars = "443", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "127382, SFX, 20", selfOnly = false },
})

-- Anim Polearm Swipe
-- Swiping attack and back into stance
-- icon: 1396978
Register("PolearmSwipe", {
    { delay = 0, actionType = "Anim", vars = "2819", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "425", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim Shield Bash
-- Attack with shield and back into stance
-- icon: 132357
Register("ShieldBash", {
    { delay = 0, actionType = "Anim", vars = "2059", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "64008, SFX, 20", selfOnly = false },
})

-- Anim Shield Bash and strike
-- Attack with shield, slash and back into stance
-- icon: 132362
Register("ShieldBashSlash", {
    { delay = 0, actionType = "Anim", vars = "3322", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.1, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.1, actionType = "TRP3e_Sound_playLocalSoundID", vars = "64008, SFX, 20", selfOnly = false },
    { delay = 0.6, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.6, actionType = "TRP3e_Sound_playLocalSoundID", vars = "69044, SFX, 20", selfOnly = false },
})

-- Anim Shield Block
-- Block and back into stance
-- icon: 132359
Register("ShieldBlock", {
    { delay = 0, actionType = "Anim", vars = "620", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "333", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "64025, SFX, 20", selfOnly = false },
})

-- Anim 2H attack
-- Attack and back into stance
-- icon: 135311
Register("TwohandAttack", {
    { delay = 0, actionType = "Anim", vars = "37", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.5, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim 2H Chop
-- Side choping attack and back into stance
-- icon: 589119
Register("TwohandChop", {
    { delay = 0, actionType = "Anim", vars = "2823", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim 2H Cleave
-- Cleaving attack and back into stance
-- icon: 460959
Register("TwohandCleave", {
    { delay = 0, actionType = "Anim", vars = "2827", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim 2H Dodge
-- Dodge and back into stance
-- icon: 461119
Register("TwohandDodge", {
    { delay = 0, actionType = "Anim", vars = "2030", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "15927, SFX, 20", selfOnly = false },
})

-- Anim 2H Execute
-- Exec attack and back into stance
-- icon: 132413
Register("TwohandExecute", {
    { delay = 0, actionType = "Anim", vars = "3064", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim 2H Jump Attack
-- Jump attack and back into stance
-- icon: 236171
Register("TwohandJumpAttack", {
    { delay = 0, actionType = "Anim", vars = "2810", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.35, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.35, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim 2H Jump Spin
-- Jump spin attack and back into stance
-- icon: 645223
Register("TwohandJumpSpin", {
    { delay = 0, actionType = "Anim", vars = "2845", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim 2H Kick
-- Kick and back into stance
-- icon: 132219
Register("TwohandKick", {
    { delay = 0, actionType = "Anim", vars = "60", selfOnly = false },
    { delay = 0.95, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.25, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.25, actionType = "TRP3e_Sound_playLocalSoundID", vars = "1014, SFX, 20", selfOnly = false },
})

-- Anim 2H Low Strike
-- Low attack and back into stance
-- icon: 1373912
Register("TwohandLowStrike", {
    { delay = 0, actionType = "Anim", vars = "2813", selfOnly = false },
    { delay = 0.8, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim 2H Obliterate
-- Large overhead strike and back into stance
-- icon: 625998
Register("TwohandObliterate", {
    { delay = 0, actionType = "Anim", vars = "2656", selfOnly = false },
    { delay = 1.25, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.7, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.7, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim 2H Overhead
-- Overhead attack and back into stance
-- icon: 132363
Register("TwohandOverhead", {
    { delay = 0, actionType = "Anim", vars = "3016", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

-- Anim 2H parry
-- Block and back into stance
-- icon: 132269
Register("TwohandParry", {
    { delay = 0, actionType = "Anim", vars = "2251", selfOnly = false },
    { delay = 1, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.5, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53250, SFX, 20", selfOnly = false },
})

-- Anim 2H Spin
-- Spin attack and back into stance
-- icon: 879926
Register("TwohandSpin", {
    { delay = 0, actionType = "Anim", vars = "3081", selfOnly = false },
    { delay = 0.7, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.15, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.15, actionType = "TRP3e_Sound_playLocalSoundID", vars = "53247, SFX, 20", selfOnly = false },
})

-- Anim 2H Swipe
-- Swiping attack and back into stance
-- icon: 1396978
Register("TwohandSwipe", {
    { delay = 0, actionType = "Anim", vars = "2819", selfOnly = false },
    { delay = 0.85, actionType = "Anim", vars = "375", selfOnly = false },
    { delay = 0.2, actionType = "Command", vars = ".npc cast 78960", selfOnly = false },
    { delay = 0.2, actionType = "TRP3e_Sound_playLocalSoundID", vars = "56760, SFX, 20", selfOnly = false },
})

