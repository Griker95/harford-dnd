-- Arnes de HarfordCharacterDraft. Antes vivia entre 2800 lineas de frames y no se podia tocar.
local cargar = loadstring or load
HarfordCharacterDraft = {}
local S = {}
HarfordDnDData = { ABIL = {
    {key="Fuerza"},{key="Destreza"},{key="Constitucion"},
    {key="Inteligencia"},{key="Sabiduria"},{key="Carisma"} } }
local BASES = {}
local RAZAS, TRASFONDOS, CLASES = {}, {}, {}
HarfordDnDRaces = {
    GetRace = function(id) return RAZAS[id] end,
    GetSubrace = function(r, s) return RAZAS[(r or "").."/"..(s or "")] end,
}
HarfordDnDBackgrounds = { GetBackground = function(id) return TRASFONDOS[id] end }
HarfordDnDBook = {
    GetClass = function(id) return CLASES[id] end,
    GetChoiceOption = function(feature, optId)
        for _, o in ipairs((feature and feature.choice and feature.choice.options) or {}) do
            if o.id == optId then return o end
        end
    end,
}
HarfordCharacterCreation = nil

local src = io.open("Harford/Character/HarfordCharacterDraft.lua"):read("*a")
local piezas = {}
for _, n in ipairs({"DraftSkillProficiencies","BuildCreationDraft"}) do
    local i = assert(src:find("local function "..n.."%("), n)
    local j = assert(src:find("\nend", i))
    piezas[#piezas+1] = src:sub(i, j + 4)
end
local codigo = table.concat(piezas, "\n") .. "\nreturn DraftSkillProficiencies, BuildCreationDraft"
local env = {
    S = S, ipairs = ipairs, type = type, tostring = tostring, table = table,
    HarfordDnDData = HarfordDnDData, HarfordDnDRaces = HarfordDnDRaces,
    HarfordDnDBackgrounds = HarfordDnDBackgrounds, HarfordDnDBook = HarfordDnDBook,
    HarfordCharacterCreation = nil,
    BaseScoreFor = function(k) return BASES[k] end,
}
local f
if setfenv then f = assert(cargar(codigo)); setfenv(f, env) else f = assert(cargar(codigo, "draft", "t", env)) end
local Skills, Build = f()

local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-14s %s", n, tostring(real), ok and "ok" or ("FALLA, esperaba "..tostring(esp))))
end

print("BuildCreationDraft: guarda la BASE, no el bono racial")
print("  (sumarlo aqui lo contaba DOS veces; lo hornea Creation.Apply)")
BASES = { Fuerza=15, Destreza=14, Constitucion=13, Inteligencia=12, Sabiduria=10, Carisma=8 }
S.raceId, S.subraceId = "humano", nil
S.backgroundId = "soldado"
S.classId, S.subclassId, S.primaryLevel = "guerrero", nil, 1
S.choiceSelections = {}
local d = Build()
chk("Fuerza se guarda tal cual", d.abilities.Fuerza, 15)
chk("Carisma se guarda tal cual", d.abilities.Carisma, 8)
chk("las seis caracteristicas presentes", (function() local n=0 for _ in pairs(d.abilities) do n=n+1 end return n end)(), 6)
chk("raza", d.raceId, "humano")
chk("trasfondo", d.backgroundId, "soldado")

print("Multiclase")
chk("una sola clase si no hay secundaria", #d.classes, 1)
S.secondaryClassId, S.secondarySubclassId, S.secondaryLevel = "picaro", "forajido", 2
d = Build()
chk("dos clases con secundaria", #d.classes, 2)
chk("  la segunda es picaro", d.classes[2].classId, "picaro")
chk("  con su subclase", d.classes[2].subclassId, "forajido")
chk("  y su nivel", d.classes[2].level, 2)
S.secondaryClassId = nil

print("DraftSkillProficiencies: de donde salen las competencias")
RAZAS.humano = { traits = { { id="hum_versatil", effects = { { kind="skillProf", skill="Persuasion" } } } } }
TRASFONDOS.soldado = { traits = { { id="sol_comp", effects = { { kind="skillProf", skill="Atletismo" } } } } }
CLASES.guerrero = { features = { { id="gue_comp", effects = { { kind="skillProf", skill="Supervivencia" } } } } }
S.choiceSelections = {}
local p = Skills()
chk("de la raza", p.Persuasion, true)
chk("del trasfondo", p.Atletismo, true)
chk("de la clase", p.Supervivencia, true)
chk("no inventa ninguna", p.Arcanos, "nil")

print("Una eleccion YA RESUELTA tambien concede competencia")
TRASFONDOS.soldado = { traits = { {
    id = "sol_dos_hab",
    choice = { options = {
        { id = "intimidar", effects = { { kind="skillProf", skill="Intimidar" } } },
        { id = "historia",  effects = { { kind="skillProf", skill="Historia" } } },
    } },
} } }
S.choiceSelections = { sol_dos_hab = { "intimidar" } }
p = Skills()
chk("la opcion elegida da competencia", p.Intimidar, true)
chk("la NO elegida no", p.Historia, "nil")

print("Subraza")
RAZAS["elfo/noche"] = { traits = { { id="eln", effects = { { kind="skillProf", skill="Percepcion" } } } } }
RAZAS.elfo = { traits = {} }
S.raceId, S.subraceId = "elfo", "noche"
p = Skills()
chk("los rasgos de subraza cuentan", p.Percepcion, true)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
