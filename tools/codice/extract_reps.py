# -*- coding: utf-8 -*-
# Extrae facciones (nombre+icono WoW) y las reps de Gmaster del SavedVariables Harford,
# calcula el rango por puntos y lo cruza con las organizaciones de la web.
import io, re, os, json, sys, unicodedata
sys.stdout.reconfigure(encoding="utf-8")

SV = r"G:/Epsilon/_retail_/WTF/Account/GRIKER/SavedVariables/Harford.lua"
WEB = r"C:/Users/marco/Documents/harfordweb"
OUT = os.path.dirname(os.path.abspath(__file__))

TIERS = [(-42000,-6001,"Odiado","hated"),(-6000,-3001,"Hostil","hostile"),(-3000,-1,"Adverso","adverse"),
         (0,2999,"Neutral","neutral"),(3000,8999,"Amistoso","friendly"),(9000,20999,"Honorable","honored"),
         (21000,41999,"Reverenciado","revered"),(42000,42999,"Exaltado","exalted")]
def rank(points):
    for lo,hi,name,cls in TIERS:
        if lo <= points <= hi: return name, cls
    return ("Exaltado","exalted") if points>42999 else ("Odiado","hated")

def sa(s): return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c)!="Mn")
def nk(s): return re.sub(r"[^a-z0-9]+"," ", sa(s or "").lower()).strip()

t = io.open(SV, encoding="utf-8", errors="replace").read()

def balanced(text, i):
    d=0
    for j in range(i,len(text)):
        if text[j]=="{": d+=1
        elif text[j]=="}":
            d-=1
            if d==0: return j+1
    return len(text)

def block(text, key):
    m = re.search(r'\["'+re.escape(key)+r'"\]\s*=\s*\{', text)
    if not m: return None
    s = text.index("{", m.start())
    return text[s:balanced(text, s)]

def field(b, key):
    m = re.search(r'\["'+key+r'"\]\s*=\s*"((?:[^"\\]|\\.)*)"', b)
    return m.group(1) if m else None
def numfield(b, key):
    m = re.search(r'\["'+key+r'"\]\s*=\s*(-?\d+)', b)
    return int(m.group(1)) if m else None
def boolfield(b, key):
    m = re.search(r'\["'+key+r'"\]\s*=\s*(true|false)', b)
    return (m.group(1)=="true") if m else None

store = t[t.index("HarfordReputationStore"):]
factions_b = block(store, "factions")
# cada faccion: ["id"] = { ... }
factions = {}
for m in re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{', factions_b):
    fb = factions_b[m.start():balanced(factions_b, factions_b.index("{", m.start()))]
    fid = field(fb,"id") or m.group(1)
    if not field(fb,"name"): continue
    factions[fid] = {"id":fid,"name":field(fb,"name"),"icon":field(fb,"icon"),
        "color":field(fb,"color"),"group":field(fb,"group"),"subgroup":field(fb,"subgroup"),
        "sortOrder":numfield(fb,"sortOrder"),"hidden":boolfield(fb,"hidden"),
        "description":(field(fb,"description") or "").replace("\\n","\n")}

# reps de Gmaster
players_b = block(store, "players")
gm_b = block(players_b, "Gmaster")
reps_b = block(gm_b, "reps")
reps = {}
for m in re.finditer(r'\["([a-z0-9_]+)"\]\s*=\s*\{', reps_b):
    rb = reps_b[m.start():balanced(reps_b, reps_b.index("{", m.start()))]
    reps[m.group(1)] = {"points":numfield(rb,"points"),"atWar":boolfield(rb,"atWar"),"visible":boolfield(rb,"visible")}

# combinar
combined = []
for fid,f in factions.items():
    r = reps.get(fid)
    pts = r["points"] if r else None
    rname,rcls = rank(pts) if pts is not None else ("Sin registrar","unknown")
    combined.append({**f,"points":pts,"atWar":(r or {}).get("atWar",False),"rankName":rname,"rankClass":rcls})
combined.sort(key=lambda x:(x.get("sortOrder") or 999, x["name"]))

json.dump(combined, io.open(os.path.join(OUT,"reps_gmaster.json"),"w",encoding="utf-8"), ensure_ascii=False, indent=1)

# cruce con la web
web = io.open(os.path.join(WEB,"js","organizations.js"),encoding="utf-8").read()
web_orgs = re.findall(r'"id":\s*"([^"]+)",\s*"name":\s*"([^"]+)"', web)
fnk = {nk(f["name"]):f["id"] for f in combined}
print("=== FACCIONES en store: %d | reps Gmaster: %d ==="%(len(factions),len(reps)))
for f in combined:
    war=" [EN GUERRA]" if f["atWar"] else ""
    print("  %-26s %-22s pts=%s  icon=%s%s"%(f["id"], f["rankName"], f["points"], f["icon"], war))
print("\n=== ORGS WEB (%d) -> match por nombre ==="%len(web_orgs))
for oid,oname in web_orgs:
    hit = fnk.get(nk(oname))
    print("  %-28s %-34s -> %s"%(oid, oname, hit or "SIN MATCH"))
