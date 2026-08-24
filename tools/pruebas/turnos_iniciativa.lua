-- Arnes del modulo de combate: ya se puede probar la iniciativa sin frames ni red real.
strsplit = function(sep, str)
    local out = {}
    for part in (tostring(str) .. sep):gmatch("([^" .. sep .. "]*)" .. sep) do out[#out+1] = part end
    return (unpack or table.unpack)(out)
end
Ambiguate = function(n) return (tostring(n):match("^[^-]+")) or n end
random = math.random
dofile("Harford/Frames/HarfordTurnsCombat.lua")
local C = HarfordTurnsCombat

local store = { entries = {}, activeIndex = 1 }
local esAdmin, enviados, impresos = true, {}, {}
HarfordSync = { Send = function(_, msg, ch, to) enviados[#enviados+1] = { msg = msg, ch = ch, to = to } return true end,
                BestChannel = function() return "RAID" end }
HarfordDnDCalc = { GetInitiativeBonus = function() return 5 end }
HarfordTurnOrderAPI = { HasActiveCombat = function()
    for _, e in ipairs(store.entries) do if e.kind ~= "round" then return true end end
    return false
end }
C.Init({
    commPrefix = "HARFORDTURN", roundMarkerInitiative = 9999,
    EnsureStore = function() return store end,
    EnsureRoundMarker = function() end,
    EnsureActiveVisible = function() end,
    AdvanceTurnSerial = function() return 7 end,
    ClaimAdminIfNeeded = function() end,
    IsTurnAdmin = function() return esAdmin end,
    IsSystemEntry = function(e) return e and (e.kind == "round" or e.kind == "generic" or e.kind == "players") end,
    EntryBelongsToMe = function(e) return e and e.name == "Marcos" end,
    MarkChanged = function() end,
    SendState = function() end,
    Print = function(m) impresos[#impresos+1] = m end,
    SafeNumber = function(v, d) local n = tonumber(v) if n == nil then return d end return n end,
})
local fallos = 0
local function chk(n, real, esp)
    local ok = tostring(real) == tostring(esp)
    if not ok then fallos = fallos + 1 end
    print(string.format("  %-52s %-10s %s", n, tostring(real):sub(1,10), ok and "ok" or ("FALLA: " .. tostring(esp))))
end

print("Sin combatientes no se puede iniciar")
store.entries = { { kind = "round", name = "Asalto", initiative = 9999 } }
C.StartCombat()
chk("avisa en vez de iniciar", impresos[#impresos]:find("Anade combatientes") ~= nil, true)

print("Inicio de combate")
math.randomseed(1)
store.entries = {
    { kind = "round", name = "Asalto", initiative = 9999 },
    { kind = "npc", name = "Gnoll", unitName = "Gnoll" },
    { kind = "player", name = "Marcos", unitName = "Marcos" },
    { kind = "player", name = "Otra", unitName = "Otra" },
}
enviados = {}
C.StartCombat()
chk("todos tienen iniciativa", (store.entries[2].initiative ~= nil and store.entries[3].initiative ~= nil), true)
chk("el marcador sigue el primero", store.entries[1].name, "Asalto")
local ordenado = true
for i = 2, #store.entries - 1 do
    if (store.entries[i].initiative or 0) < (store.entries[i+1].initiative or 0) then ordenado = false end
end
chk("ordenado de mayor a menor", ordenado, true)
chk("pide a los jugadores que tiren", enviados[1] and enviados[1].msg:find("INITREQ") ~= nil, true)

print("Respuesta de un jugador")
local otra
for _, e in ipairs(store.entries) do if e.name == "Otra" then otra = e end end
otra.id = "id-otra"
chk("aplica la tirada de su dueno", C.ApplyInitiativeReply("INITRES|id-otra|18", "Otra"), true)
chk("  valor aplicado", otra.initiative, 18)
chk("RECHAZA si el remitente no es el dueno", C.ApplyInitiativeReply("INITRES|id-otra|99", "Impostor"), false)
chk("  y no se toco", otra.initiative, 18)

print("Fin de combate")
C.EndCombat()
chk("lista vaciada", #store.entries, 0)

print("Solo el admin")
esAdmin = false
store.entries = { { kind = "npc", name = "X" } }
C.StartCombat()
chk("un jugador no puede iniciar", impresos[#impresos]:find("Solo el admin") ~= nil, true)
print(fallos == 0 and "TODO CORRECTO" or (fallos .. " FALLOS"))
