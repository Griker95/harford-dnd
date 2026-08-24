-- SkillTotal/SaveTotal de HarfordCharacterSheet, en su rama de INSPECCION (la que calcula sola).
local cargar = loadstring or load
local PERFIL, RANK, BONUS = {}, {}, {}
local INSPECT = true
HarfordDnDProgression = { GetProficiencyBonus = function() return PERFIL.pb end }
HarfordDnDFeatureEffects = {
    GetSkillRank = function(id) return RANK[id] or 0 end,
    GetBonus = function(kind, id) return (BONUS[kind] or {})[id] or 0 end,
}
HarfordDnDCalc = nil
local src = io.open("Harford/Character/HarfordCharacterSheet.lua"):read("*a")
local piezas = {}
for _, n in ipairs({"SkillTotal","SaveTotal"}) do
    local i = assert(src:find("local function "..n.."%("), n)
    local j = assert(src:find("\nend", i))
    piezas[#piezas+1] = src:sub(i, j + 4)
end
local env = {
    ipairs=ipairs, tonumber=tonumber, tostring=tostring, type=type, math=math,
    HarfordDnDProgression=HarfordDnDProgression, HarfordDnDFeatureEffects=HarfordDnDFeatureEffects,
    HarfordDnDCalc=nil,
    IsInspecting=function() return INSPECT end,
    GetProfileName=function() return "Prueba" end,
    GetProfileValue=function(k,d) local v=PERFIL[k] if v==nil then return d end return v end,
    AbilityMod=function(v) return math.floor(((tonumber(v) or 10)-10)/2) end,
    AbilityScore=function(a) return PERFIL["car_"..a] or 10 end,
}
local codigo = table.concat(piezas,"\n").."\nreturn SkillTotal, SaveTotal"
local f
if setfenv then f=assert(cargar(codigo)); setfenv(f,env) else f=assert(cargar(codigo,"sheet","t",env)) end
local Skill, Save = f()
local fallos=0
local function chk(n,real,esp)
    local ok = tostring(real)==tostring(esp)
    if not ok then fallos=fallos+1 end
    print(string.format("  %-52s %-6s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba "..tostring(esp))))
end
local SIGILO = { id="sigilo", ability="Destreza" }

print("SkillTotal (competencia = 3, Destreza 16 -> mod +3)")
PERFIL = { pb = 3, car_Destreza = 16 }
RANK, BONUS = {}, {}
chk("sin competencia: solo el modificador", Skill(SIGILO), 3)
PERFIL.Hab_sigilo_Prof = 1
chk("con competencia: +3", Skill(SIGILO), 6)
PERFIL.Hab_sigilo_Exp = 1
chk("con pericia: competencia DOBLE", Skill(SIGILO), 9)

print("La pericia por RASGO equivale a la marcada a mano")
PERFIL.Hab_sigilo_Prof, PERFIL.Hab_sigilo_Exp = nil, nil
RANK.sigilo = 2
chk("rasgo con rango 2 = pericia", Skill(SIGILO), 9)
RANK.sigilo = 1
chk("rasgo con rango 1 = competencia", Skill(SIGILO), 6)

print("Bonus de objeto encima")
RANK.sigilo = 0
BONUS.skill = { sigilo = 1 }
chk("solo el bonus", Skill(SIGILO), 4)
PERFIL.Hab_sigilo_Prof = 1
chk("bonus + competencia", Skill(SIGILO), 7)

print("Caracteristica impar redondea hacia abajo")
PERFIL = { pb = 2, car_Destreza = 15 }
RANK, BONUS = {}, {}
chk("15 -> +2", Skill(SIGILO), 2)
PERFIL.car_Destreza = 9
chk("9 -> -1", Skill(SIGILO), -1)
PERFIL.car_Destreza = 8
chk("8 -> -1", Skill(SIGILO), -1)
print(fallos==0 and "TODO CORRECTO" or (fallos.." FALLOS"))
