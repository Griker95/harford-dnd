# -*- coding: utf-8 -*-
"""Refresca las fichas de personal de la web con los perfiles TRP3 del disco.

Reescribe DOS cosas de cada personaje y no toca nada mas:

  - `profileData.rawTrpSections`: los frames del About tal cual (titulo, icono y markup).
  - `profileData.combatSheet`: lo que se deriva del frame "Ficha" --clases y nivel,
    caracteristicas, recursos, armadura, armas, bono de competencia, competencias,
    salvaciones, habilidades e idiomas-- y las dotes, que en los perfiles reales viven al
    final del frame de RAZA (ver AGENTS.md), no en uno propio.

Todo lo redactado a mano (resumen, cita, relaciones, fortalezas...) se conserva.

El segundo recurso: si el perfil declara PM, manda el perfil. Si no lo declara --las clases
que no lanzan con mana-- se calcula el recurso principal de la clase con la formula
`resourceMax` del propio addon, para no inventar un numero ni dejar la tarjeta a medias.
"""
import io
import json
import unicodedata
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fichas_desde_trp3 as trp3
from terminologia import normalizar_habilidades

WEB = "C:/Users/marco/Documents/harfordweb/js/characters.js"
ADDON = "C:/Users/marco/Documents/New project/Harford"

# El nombre del perfil no siempre es el de la ficha: Bunny firma como Ellie y el de Griker
# no lleva la marca {PJ}. Dornalei es de OTRO jugador, asi que su ficha al dia no esta en
# los perfiles propios sino en el registro de vistos, y por eso va sin marca.
# Lo que no aparece aqui se queda como esta.
MAPA = {
    "melian-albor": "{PJ} Melyan",
    "cody": "Cody",
    "kijava": "{PJ} Kijava",
    "baird": "{PJ} Baird",
    "ziegler-stendel": "{PJ} Ziegler",
    "hizdahr-hazdalansen": "{PJ} Hizdahr",
    "bunny": "{PJ} Ellie",
    "dornalei": "Dornalei",
    "griker-vaughn": "Griker - Celadores",
}

CARACS = ("Fuerza", "Destreza", "Constitución", "Inteligencia", "Sabiduría", "Carisma")


# La convencion del juego, no la equivalencia real: 5 pies = 1,5 m. Es la que ya usa el
# compendio, y mezclarlas haria que el mismo alcance saliera distinto en cada sitio.
PIE_METROS = 0.3
LIBRA_KILOS = 0.45
PULGADA_CM = 2.5
_PIES = re.compile(r"(\d+(?:[.,]\d+)?)\s*(pies|pie)\b", re.I)
_LIBRAS = re.compile(r"(\d+(?:[.,]\d+)?)\s*(libras|libra)\b", re.I)
_PULGADAS = re.compile(r"(\d+(?:[.,]\d+)?)\s*(pulgadas|pulgada)\b", re.I)
MILLA_KM = 1.6
_MILLAS = re.compile(r"(\d+(?:[.,]\d+)?)\s*millas?\b", re.I)


def _cifra(v):
    return str(int(round(v))) if abs(v - round(v)) < 0.05 else ("%.1f" % v).replace(".", ",")


def a_metrico(texto):
    def pies(m):
        v = float(m.group(1).replace(",", ".")) * PIE_METROS
        return "%s metro%s" % (_cifra(v), "" if abs(v - 1) < 0.05 else "s")

    def libras(m):
        return "%s kg" % _cifra(float(m.group(1).replace(",", ".")) * LIBRA_KILOS)

    def pulgadas(m):
        return "%s cm" % _cifra(float(m.group(1).replace(",", ".")) * PULGADA_CM)

    def millas(m):
        return "%s km" % _cifra(float(m.group(1).replace(",", ".")) * MILLA_KM)

    t = _PIES.sub(pies, texto or "")
    t = _LIBRAS.sub(libras, t)
    t = _MILLAS.sub(millas, t)
    # el markup de TRP3 no tiene negrita: los ** que algun perfil trae escritos a mano se
    # verian tal cual, como dos asteriscos
    return re.sub(r"\*\*(.+?)\*\*", r"\1", _PULGADAS.sub(pulgadas, t), flags=re.S)


def _sin_markup(x):
    return trp3.limpio(x)


def _lista_tras(markup, titulo):
    """Los `- item` que siguen a un encabezado concreto."""
    m = re.search(r"\{h[23]\}\s*" + re.escape(titulo) + r".{0,40}?\{/h[23]\}\s*\n(.*?)(?=\n\s*\{h[123]|\Z)",
                  markup, re.S)
    if not m:
        return []
    return [_sin_markup(l).lstrip("- ").strip()
            for l in m.group(1).split("\n") if l.strip().startswith("-")]


def _clases(markup):
    salida = []
    for m in re.finditer(r"\{h2\}\{icon:classicon[^}]*\}(.{0,120}?)\{/h2\}", markup, re.S):
        texto = _sin_markup(m.group(1))
        nivel = re.search(r"\((\d+)\)\s*$", texto)
        salida.append({"name": re.sub(r"\s*\(\d+\)\s*$", "", texto).strip(),
                       "level": int(nivel.group(1)) if nivel else None})
    return salida


def _atributos(markup):
    """Objeto por nombre con puntuacion y modificador NUMERICO, que es lo que pinta la web."""
    salida = {}
    for c in CARACS:
        m = re.search(r"\{h3\}\{icon:[^}]*\}\s*" + c + r"\s*\{col:[^}]*\}(\d+)\{/col\}(.{0,40}?)\{/h3\}",
                      markup, re.S)
        if not m:
            continue
        crudo = _sin_markup(m.group(2)).strip().replace("+", "") or "0"
        try:
            mod = int(crudo)
        except ValueError:
            mod = 0
        salida[c] = {"score": int(m.group(1)), "modifier": mod}
    return salida


def _linea(markup, etiqueta):
    """Una fila `{h3}...Etiqueta <gris> <naranja> <cian>{/h3}` en sus tres trozos."""
    m = re.search(r"\{h3\}\{icon:[^}]*\}\s*" + etiqueta + r"(.{0,200}?)\{/h3\}", markup, re.S)
    if not m:
        return None
    cuerpo = m.group(1)
    trozos = [_sin_markup(t).strip() for t in re.findall(r"\{col:[^}]*\}(.*?)\{/col\}", cuerpo, re.S)]
    suelto = _sin_markup(re.sub(r"\{col:[^}]*\}.*?\{/col\}", "", cuerpo, flags=re.S)).strip()
    return {"trozos": [t for t in trozos if t], "suelto": suelto}


def _dotes(frames):
    """Las dotes viven al final del frame de RAZA, con la cabecera coloreada."""
    salida = []
    for f in frames:
        for m in re.finditer(r"\{h2\}\{icon:[^}]*\}\{col:[^}]*\}\s*Dote\{/col\}\s*(.{0,60}?)\{/h2\}",
                             f["markup"], re.S):
            n = _sin_markup(m.group(1)).strip()
            if n:
                salida.append(n)
    return salida


def _formulas_del_addon():
    """resource -> (etiqueta, formula) leidas del propio addon."""
    etiquetas = {}
    ruta = os.path.join(ADDON, "DnD", "State", "HarfordDnDResources.lua")
    for m in re.finditer(r'(\w+)\s*=\s*\{\s*label\s*=\s*"([^"]+)"', io.open(ruta, encoding="utf-8").read()):
        etiquetas[m.group(1)] = m.group(2)

    formulas = {}
    base = os.path.join(ADDON, "DnD", "Data", "Classes")
    for f in sorted(os.listdir(base)):
        if not f.endswith(".lua"):
            continue
        t = io.open(os.path.join(base, f), encoding="utf-8").read()
        m = re.search(r'kind\s*=\s*"resourceMax"[^}]*?resource\s*=\s*"(\w+)"', t, re.S)
        if not m:
            continue
        # el resto de la declaracion, sin cortar en la primera llave: las clases con tabla
        # (Cazador, Chaman, Brujo) meten un `values = { ... }` y cortar ahi dejaba la
        # formula vacia, o sea el recurso a cero y la tarjeta sin pintar
        res, resto = m.group(1), t[m.end():m.end() + 400]
        clase = re.search(r'perClassLevel\s*=\s*"(\w+)"', resto)
        valores = re.search(r"values\s*=\s*\{([^}]*)\}", resto)
        formulas[clase.group(1) if clase else f[:-4].lower()] = {
            "resource": res,
            "label": etiquetas.get(res, res),
            "base": int((re.search(r"base\s*=\s*(\d+)", resto) or [0, 0])[1]) if re.search(r"base\s*=\s*(\d+)", resto) else 0,
            "perLevel": int(re.search(r"perLevel\s*=\s*(\d+)", resto).group(1)) if re.search(r"perLevel\s*=\s*(\d+)", resto) else 0,
            "value": int(re.search(r"value\s*=\s*(\d+)", resto).group(1)) if re.search(r"\bvalue\s*=\s*(\d+)", resto) else None,
            "values": [int(x) for x in re.findall(r"\d+", valores.group(1))] if valores else None,
        }
    return formulas


# el nombre de clase del perfil no es el id del addon
ID_DE_CLASE = {
    "caballero de la muerte": "caballero_muerte", "cazador de demonios": "cazador_demonios",
    "guerrero": "guerrero", "cazador": "cazador", "mago": "mago", "maga": "mago",
    "picaro": "picaro", "picara": "picaro", "sacerdote": "sacerdote", "sacerdotisa": "sacerdote",
    "chaman": "chaman", "chamana": "chaman", "brujo": "brujo", "bruja": "brujo",
    "monje": "monje", "monja": "monje", "druida": "druida", "paladin": "paladin",
    "paladina": "paladin",
}


def _recurso_principal(clases, formulas):
    """Recurso principal de la clase de mas nivel, con la formula del addon."""
    if not clases:
        return None
    principal = max(clases, key=lambda c: c.get("level") or 0)
    # por prefijo mas largo: "Caballero de la Muerte Sangre" son cuatro palabras antes de
    # la especializacion, y probar por numero fijo de palabras se quedaba corto
    nombre = trp3.nk(principal["name"])
    cid = next((v for k, v in sorted(ID_DE_CLASE.items(), key=lambda kv: -len(kv[0]))
                if nombre == k or nombre.startswith(k + " ")), None)
    if not cid:
        return None
    f = formulas.get(cid)
    if not f:
        return None
    n = principal.get("level") or 1
    if f["values"]:
        valor = f["values"][min(n, len(f["values"])) - 1]
    elif f["value"] is not None:
        valor = f["value"]
    else:
        valor = f["base"] + f["perLevel"] * n
    return "%s %d" % (f["label"], valor) if valor else None


# PG adicionales por nivel TOTAL que concede una dote. `Duro` da 2 por nivel; la dote
# racial Tauren, 1. Sin esto el total se queda corto en quien las lleve.
PG_POR_NIVEL_DE_DOTE = {"duro": 2, "resistencia tauren": 1}


def _dados_de_golpe():
    """hitDie por id de clase, leido de los ficheros de clase del addon."""
    dados = {}
    base = os.path.join(ADDON, "DnD", "Data", "Classes")
    for f in sorted(os.listdir(base)):
        if not f.endswith(".lua"):
            continue
        t = io.open(os.path.join(base, f), encoding="utf-8").read()
        cid = re.search(r'id\s*=\s*"(\w+)"', t)
        die = re.search(r"hitDie\s*=\s*(\d+)", t)
        if cid and die:
            dados[cid.group(1)] = int(die.group(1))
    return dados


def _id_de(nombre):
    n = trp3.nk(nombre)
    return next((v for k, v in sorted(ID_DE_CLASE.items(), key=lambda kv: -len(kv[0]))
                 if n == k or n.startswith(k + " ")), None)


def _pg_del_addon(clases, atributos, dados, dotes=()):
    """Regla del manual: dado entero el primer nivel, dado/2+1 el resto, + Mod. CON por nivel."""
    if not clases:
        return None
    con = next((v for k, v in (atributos or {}).items() if k.startswith("Constituci")), None)
    mod = int(con["modifier"]) if con else 0
    pg, total, primero = 0, 0, True
    for c in clases:
        die = dados.get(_id_de(c["name"]) or "", 8)
        for _ in range(max(0, int(c.get("level") or 0))):
            total += 1
            pg += die if primero else die // 2 + 1
            primero = False
    if not total:
        return None
    extra = 0
    for d in dotes:
        extra += PG_POR_NIVEL_DE_DOTE.get(trp3.nk(d), 0)
    return max(1, pg + (mod + extra) * total), total


def hoja_de(frames, formulas):
    ficha = next((f for f in frames if trp3.nk(f["title"]) == "ficha"), None)
    if not ficha:
        return None
    m = ficha["markup"]
    clases = _clases(m)

    recursos = []
    # Los PG salen de la regla del addon, no del numero escrito en el perfil, que puede
    # estar desfasado. Si no hay clases de las que calcularlo, se respeta el del perfil.
    calculado = _pg_del_addon(clases, _atributos(m), DADOS, _dotes(frames))
    fila_pg = _linea(m, "PG")
    if calculado:
        recursos.append("PG %d" % calculado[0])
    elif fila_pg and fila_pg["trozos"]:
        recursos.append("PG %s" % fila_pg["trozos"][0])
    fila_pm = _linea(m, "PM")
    if fila_pm and fila_pm["trozos"]:
        recursos.append("PM %s" % fila_pm["trozos"][0])
    if len(recursos) < 2:
        extra = _recurso_principal(clases, formulas)
        if extra:
            recursos.append(extra)

    armadura = _linea(m, "Armadura")
    armas = _linea(m, "Armas")
    comp = re.search(r"\{h2\}\s*Competencia\s*\{col:[^}]*\}\((.{0,6}?)\)\{/col\}\s*\{/h2\}", m)

    return {
        "classes": clases,
        "attributes": _atributos(m),
        "resources": recursos,
        # listas, que es como las pinta la web
        "armor": ([" ".join(armadura["trozos"])] if armadura and armadura["trozos"] else []),
        "weapons": ([" ".join(armas["trozos"])] if armas and armas["trozos"] else []),
        "proficiencyBonus": (comp.group(1).strip() if comp else ""),
        "proficiencies": _lista_tras(m, "Competencia"),
        "savingThrows": _lista_tras(m, "Tiradas de salvación"),
        "skills": _lista_tras(m, "Habilidades"),
        "languages": _lista_tras(m, "Idiomas"),
        "feats": _dotes(frames),
    }


DADOS = _dados_de_golpe()


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    perfiles = trp3.perfiles(solo_pj=False)
    formulas = _formulas_del_addon()

    texto = io.open(WEB, encoding="utf-8").read()
    cabecera, cuerpo = texto.split("=", 1)
    fichas = json.loads(cuerpo.strip().rstrip(";").strip())

    tocados, sin_perfil = 0, []
    for f in fichas:
        nombre = MAPA.get(f.get("id"))
        if not nombre:
            sin_perfil.append(f.get("id"))
            continue
        p = perfiles.get(unicodedata.normalize("NFC", nombre))
        if not p:
            sin_perfil.append(f.get("id") + " (perfil no encontrado)")
            continue
        pd = f.setdefault("profileData", {})
        pd["rawTrpSections"] = [{"title": fr["title"] or "Sin titulo",
                                 "icon": fr["icon"], "markup": normalizar_habilidades(a_metrico(fr["markup"]))}
                                for fr in p["frames"]]
        hoja = hoja_de(p["frames"], formulas)
        if hoja:
            anterior = pd.get("combatSheet") or {}
            # se conserva lo que no sale del perfil
            for k, v in anterior.items():
                hoja.setdefault(k, v)
            hoja.pop("notice", None)
            pd["combatSheet"] = hoja
        tocados += 1
        print("   %-22s %2d frames | %s | %s" % (
            f["id"], len(p["frames"]),
            ", ".join("%s %s" % (c["name"], c["level"]) for c in (hoja or {}).get("classes", [])),
            " / ".join((hoja or {}).get("resources", []))))

    salida = cabecera + "= " + json.dumps(fichas, ensure_ascii=False, indent=2) + ";\n"
    io.open(WEB, "w", encoding="utf-8", newline="").write(salida)
    print("\nfichas actualizadas: %d | sin perfil mapeado: %s" % (tocados, sin_perfil))


if __name__ == "__main__":
    main()
