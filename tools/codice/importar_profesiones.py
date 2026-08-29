# -*- coding: utf-8 -*-
"""Mete en el addon las recetas de WoW descargadas por wowhead_profesiones.py.

Las recetas del proyecto referencian materiales y resultados por CLAVE del registro de
items, nunca por nombre, asi que hay dos escrituras: dar de alta lo que falte en
HarfordProfessionsItems y reescribir las recetas de cada profesion en HarfordProfessionsData.

Se reutiliza la clave que ya exista para un material comparando el nombre sin tildes, para
que "Polvo extraño" siga siendo `polvo_extrano` y las recetas de Ingenieria que ya lo
gastaban sigan apuntando al mismo item.

Dos criterios que Wowhead no da:
  - la CD sale del COLOR de la receta, que en WoW es su dificultad real. Se guardan sus
    cuatro umbrales de habilidad, que parten la escala en cinco tramos: rojo 20 (aun no
    llegas), naranja 16, amarillo 12, verde 10 y gris 8. La
    receta que no declara umbrales se queda en naranja. Sobre esa banda pesa ademas la
    calidad de lo que se fabrica: gris -1, blanco 0, verde +1, azul +3, morado +5 y
    legendario +7.
  - un encantamiento no produce objeto: se aplica sobre una pieza. El proyecto ya resolvia
    eso entregando un pergamino y se mantiene ese criterio.

De las nueve profesiones importadas queda SOLO lo extraido de Wowhead: las recetas que
habia escritas a mano se retiran, tambien las de recoleccion ("Extraer cobre"), que se
colaban entre las de fundicion. Las profesiones que no se importan no se tocan.

Sin --apply solo informa.
"""
import io
import json
import os
import re
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nombres_display import casa                                  # noqa: E402

BASE = os.path.dirname(os.path.abspath(__file__))
ENTRADA = os.path.join(BASE, "cotejo", "profesiones_wowhead.json")
ADDON = r"C:/Users/marco/Documents/New project/HarfordProfesiones"
F_DATA = os.path.join(ADDON, "HarfordProfesiones.lua")
F_ITEMS = os.path.join(ADDON, "HarfordProfesionesItems.lua")

ROTULO = {"encantamiento": "Encantamiento", "ingenieria": "Ingenieria",
          "joyeria": "Joyeria", "inscripcion": "Inscripcion",
          "sastreria": "Sastreria", "alquimia": "Alquimia", "herreria": "Herreria",
          "peleteria": "Peleteria", "primeros_auxilios": "Primeros Auxilios",
          "mineria": "Mineria", "cocina": "Cocina"}


def sa(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "")
                   if unicodedata.category(c) != "Mn")


def visible(nombre):
    """Quita las marcas internas de Blizzard que algun objeto arrastra en las dos versiones.

    El reactivo 23567 se llama "[PH] Polvo Silithus JvJ [DEP]" tanto en Classic como en el
    juego actual: son marcas de marcador de posicion y de obsoleto, no parte del nombre.
    """
    return re.sub(r"\s{2,}", " ", re.sub(r"\[(?:PH|DEP)\]", "", nombre)).strip()


def slug(s, tope=40):
    return re.sub(r"[^a-z0-9]+", "_", sa(s).lower()).strip("_")[:tope].strip("_")


# recetas que nombran un PROCESO y no su producto: ahi el verbo es la informacion
_VERBO = re.compile(r"(?i)^(fundir|transmutar|desencantar|destilar|curtir|extraer|recoger|"
                    r"convertir|encantar|crear|preparar|cocinar|forjar|imbuir)\b")


def nombre_objeto(o):
    """El nombre bueno de un objeto: el de su ficha, que ya resolvio las colisiones.

    `profesiones_wowhead.json` guardo el nombre moderno tal cual, y para los glifos eso
    colapsaba 324 objetos distintos en "Glifo carbonizado". La ficha ya devuelve el de su
    version cuando el actual esta compartido, asi que manda ella.
    """
    if not o:
        return ""
    f = FICHAS.get(str(o.get("id")))
    return (f or {}).get("name") or o.get("name") or ""


def nombre_receta(r):
    """Nombre de la receta con la terminologia del juego actual.

    Wowhead Classic tiene dos traducciones del mismo objeto: la del hechizo de la receta y
    la del item. Solo la del item se ha revisado desde entonces, asi que la del hechizo
    arrastra cosas como "Caba de piel deslizante" o "Torio encantado" donde el juego de hoy
    dice "Caballa de piel escurridiza" y "Barra de torio encantado". Como la ventana de
    profesion lista cada receta por lo que produce, se toma el nombre del producto.
    """
    c = r.get("creates")
    if not c:
        return r["name"]                                  # un encantamiento no produce nada
    if not _VERBO.match(r["name"]):
        return nombre_objeto(c)
    # el verbo se conserva, pero el producto que nombra si se moderniza
    viejo, nuevo = c.get("classic") or "", nombre_objeto(c)
    i = r["name"].lower().find(viejo.lower()) if viejo and viejo != nuevo else -1
    if i > 0:
        return r["name"][:i] + nuevo[0].lower() + nuevo[1:] + r["name"][i + len(viejo):]
    return r["name"]


# La dificultad de una receta no es fija: en WoW depende del color que tenga para tu
# habilidad, y esa es la escala que se traslada a la CD. Los cuatro umbrales vienen de
# Wowhead y parten la habilidad en cinco tramos: por debajo del primero la receta esta en
# ROJO (aun no llegas) y por encima del ultimo en GRIS, que es lo que ya te sale solo.
CD_COLOR = {"rojo": 20, "naranja": 16, "amarillo": 12, "verde": 10, "gris": 8}

# Sobre esa banda pesa ademas lo fino que sea lo que sales fabricando: un objeto legendario
# no se saca con la misma tirada que uno corriente, aunque la receta este igual de verde.
# El indice es la calidad de WoW (0 pobre ... 5 legendario).
CD_CALIDAD = {0: -1, 1: 0, 2: 1, 3: 3, 4: 5, 5: 7}
FICHAS = {}

# De donde se aprende cada receta. Wowhead lo dice en su listado de la profesion con el
# campo `trainingcost`: si lo trae, la ensena el entrenador y ese es su precio; si no, la
# ensena un objeto (el patron, el plano, la formula). No hay un tercer caso.
ENTRENADOR = {}

# Wowhead no declara `learnedat` para unas cuantas recetas de patron raro, pero SI lo dice
# el objeto que las ensena ("Diseño: filo de runa" pide Herreria 285). Ese requisito se
# recupera de la ficha del hechizo y se guarda aqui, porque sin el la receta se quedaba
# sin rango y sin sitio en el arbol.
PLANO = {}


# Las herramientas que exige la receta ("Martillo de herrero, Llave inglesa Arcoluz"). El
# tooltip las da con su nombre de Classic, asi que se cruzan con las fichas de objeto para
# darles el del juego actual; las que no aparecen como material ni resultado en ningun sitio
# se quedan con el suyo, que en esos casos no ha cambiado.
_HERRAMIENTA = {}


def herramientas(r):
    t = (r.get("herramienta") or "").strip()
    if not t:
        return None
    if not _HERRAMIENTA:
        for f in FICHAS.values():
            for n in (f.get("classicName"), f.get("name")):
                if n:
                    _HERRAMIENTA.setdefault(sa(n).lower(), f["name"])
    partes = [x.strip() for x in t.split(",") if x.strip()]
    return ", ".join(_HERRAMIENTA.get(sa(x).lower(), x) for x in partes)


def modificador_calidad(r):
    """Cuanto sube o baja la CD por la calidad del objeto que produce la receta."""
    c = r.get("creates")
    if not c:
        return 0                       # un encantamiento no produce objeto que calificar
    f = FICHAS.get(str(c["id"]))
    if not f or f.get("quality") is None:
        return 0
    return CD_CALIDAD.get(int(f["quality"]), 0)


# El sistema llega hasta habilidad 300, que es el techo de Classic. Joyeria e Inscripcion
# vienen de Burning Crusade y de Wrath, donde el arbol sigue hasta 375 y 450: esa cola se
# descarta. Una receta sin requisito declarado se conserva; son patrones raros de la epoca
# clasica, no contenido de expansion.
TOPE = 300

# Recetas retiradas por decision de mesa, no por el dato. Cada una con su motivo, para que
# se pueda revertir sabiendo por que entro.
#   11447 Elixir del caminante acuatico: es de Classic (objeto 8827, nivel 24, parche
#     1.13.0), pero su producto se llama igual que el elixir de Rasganorte y se queda fuera
#     hasta que ese tramo entre en el sistema.
FUERA = {11447: "coincide de nombre con el elixir de Rasganorte"}

# Habilidad asignada a mano a las recetas que Wowhead deja sin declarar. NO es dato de
# Wowhead y por eso vive aparte, con el porque de cada numero.
#
# Las cinco de Ingenieria llevan el MINIMO que imponen sus propios componentes y su
# herramienta: una receta no puede pedir menos habilidad que las piezas que gasta. La
# Envoltura de mitril se fabrica a 215, el Activador inestable a 200, el Tubo de mitril a
# 195 y la Polvora solida a 175, asi que de ahi salen los numeros sin inventar nada.
#
# Las tres de la cadena de Onyxia van al tope de rama. Ahi el calculo no basta —la Escama
# de Onyxia y la Dragontina negra son botin, no se fabrican, y no aportan minimo—, pero el
# peto es epico de nivel 62 y la cadena es contenido de banda: 300.
HABILIDAD_A_MANO = {
    12900: (200, "Tubo de mitril 195 + Activador inestable 200"),
    12720: (215, "Envoltura de mitril 215"),
    12904: (215, "Envoltura de mitril 215 + Activador inestable 200"),
    12722: (215, "Envoltura de mitril 215 + Activador inestable 200"),
    12719: (175, "Polvora solida 175 + Microajustador giromatico 175"),
    22430: (300, "cadena de Onyxia, tope de rama"),
    22434: (300, "cadena de Onyxia, tope de rama"),
    19106: (300, "cadena de Onyxia, peto epico de nivel 62"),
}


def por_encima_del_tope(r):
    s = r.get("skill") or ((r.get("colors") or [0])[0]) or 0
    return s > TOPE


def es_de_temporada(r):
    """La receta fabrica un objeto que solo existe en la Temporada de Descubrimiento.

    Wowhead sirve el arbol de Classic ya mezclado con el de la Temporada, y no todo lo suyo
    esta por encima de 300: hay piezas de habilidad 100 o 200 que en el Classic original no
    existen. Se reconocen porque su tooltip trae la etiqueta interna de fase.
    """
    c = r.get("creates")
    return bool(c) and bool((FICHAS.get(str(c["id"])) or {}).get("sod"))


def umbrales(r):
    """(naranja, amarillo, verde, gris): la habilidad a la que la receta cambia de color.

    Wowhead escribe 0 en un umbral que coincide con el anterior, y puede haber mas de uno:
    "Lingote de estano" viene como [0, 0, 65, 75] y "Carne de jabali asada" como [0, 45,...].
    Rellenar solo el primero dejaba un amarillo en cero, que no significa nada. Se arrastra
    el valor anterior y se fuerza que la serie no baje.
    """
    c = r.get("colors")
    if not c or len(c) < 4:
        return None
    v = [int(x or 0) for x in c[:4]]
    # de donde parte la serie: el propio umbral, el nivel al que se aprende, o el primero
    # que traiga un numero de verdad
    base = v[0] or int(r.get("skill") or 0) or next((x for x in v if x), 0)
    fuera, ant = [], base
    for i, x in enumerate(v):
        x = base if i == 0 else max(x or ant, ant)
        fuera.append(x)
        ant = x
    return fuera


def cd_sin_umbrales():
    """CD de la receta que no declara umbrales: son patrones raros, nunca de principiante.

    Se les da la banda naranja, la de lo que esta al limite de lo que sabes hacer, porque es
    la lectura conservadora: inventarles una CD baja convertia un martillo de torio en algo
    que cualquiera saca a la primera.
    """
    return CD_COLOR["naranja"]


def pergamino(nombre):
    n = re.sub(r"(?i)^encantar\s+", "", nombre).replace(":", ",")
    return "Pergamino: " + n[0].lower() + n[1:]


def _cierra(t, i, abre="{", cierra="}"):
    d = 0
    for j in range(i, len(t)):
        if t[j] == abre:
            d += 1
        elif t[j] == cierra:
            d -= 1
            if d == 0:
                return j + 1
    return len(t)


def bloque_registry(items_lua):
    i = items_lua.find("API.REGISTRY = {")
    if i < 0:
        raise SystemExit("no encuentro API.REGISTRY")
    ini = i + len("API.REGISTRY = {")
    return ini, _cierra(items_lua, i + len("API.REGISTRY = ")) - 1


def main():
    datos = json.load(io.open(ENTRADA, encoding="utf-8"))
    OBJ = os.path.join(BASE, "cotejo", "objetos_wowhead.json")
    if os.path.exists(OBJ):
        FICHAS.update(json.load(io.open(OBJ, encoding="utf-8")))
    ENT = os.path.join(BASE, "cotejo", "entrenador_wowhead.json")
    if os.path.exists(ENT):
        ENTRENADOR.update(json.load(io.open(ENT, encoding="utf-8")))
    PL = os.path.join(BASE, "cotejo", "habilidad_por_plano.json")
    if os.path.exists(PL):
        PLANO.update(json.load(io.open(PL, encoding="utf-8")))
    data = io.open(F_DATA, encoding="utf-8", newline="").read()
    items = io.open(F_ITEMS, encoding="utf-8", newline="").read()

    ri, rf = bloque_registry(items)
    por_nombre, claves = {}, set()
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*\{([^}]*)\}', items[ri:rf]):
        claves.add(m.group(1))
        mn = re.search(r'name\s*=\s*"([^"]*)"', m.group(2))
        if mn:
            por_nombre.setdefault(sa(mn.group(1)).lower(), m.group(1))

    nuevos, por_wid, refuerzo, renombrar = {}, {}, {}, {}
    # El registro ya conoce el itemId de muchas entradas. Sembrarlo aqui es lo que evita
    # que un cambio de terminologia ("Barra de cobre" -> "Lingote de cobre") cree una clave
    # nueva y deje huerfana la vieja, que es justo la que lleva el itemId de Epsilon.
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*\{([^}]*)\}', items[ri:rf]):
        mw = re.search(r"wow\s*=\s*(\d+)", m.group(2))
        if mw:
            por_wid.setdefault(int(mw.group(1)), m.group(1))

    def clave(nombre, icono=None, wid=None):
        crudo = visible(nombre)
        nombre = casa(crudo)
        if wid and wid in por_wid:
            k = por_wid[wid]
            if k not in nuevos:
                renombrar[k] = nombre
            return k
        # el itemId manda: dos objetos distintos de WoW pueden llamarse igual (la temporada
        # de Descubrimiento reedito piezas con el mismo nombre) y cada uno necesita su clave.
        # Sin indexar tambien por itemId, el segundo nombre repetido creaba una clave nueva
        # en CADA aparicion, porque el nombre seguia apuntando a la primera.
        # se busca por el nombre nuevo y tambien por el viejo, para reaprovechar la entrada
        n = sa(nombre).lower()
        k = por_nombre.get(n) or por_nombre.get(sa(crudo).lower())
        if k is not None and not (wid and k in nuevos and nuevos[k][2] and nuevos[k][2] != wid):
            # el icono real de Wowhead completa la entrada dada de alta sin el
            if icono and k in nuevos and not nuevos[k][1]:
                nuevos[k] = (nuevos[k][0], icono, nuevos[k][2])
            # una clave que ya tenia el proyecto ("Barra de cobre", "Cuero ligero") no lleva
            # el itemId de WoW, y sin el la web no puede colgarle su ficha. Se le anota.
            elif k not in nuevos and (wid or icono):
                refuerzo.setdefault(k, (wid, icono))
            if k not in nuevos:
                renombrar[k] = nombre
            if wid:
                por_wid[wid] = k
            return k
        k, i = slug(nombre), 2
        while k in claves:
            k = "%s_%d" % (slug(nombre, 36), i)
            i += 1
        por_nombre.setdefault(n, k)
        claves.add(k)
        nuevos[k] = (nombre, icono, wid)
        if wid:
            por_wid[wid] = k
        return k

    por_prof, ids, descartadas, de_temporada, retiradas = {}, set(), 0, 0, 0
    for pid, recetas in datos.items():
        lineas = []
        for r in sorted(recetas, key=lambda x: ((x.get("skill") or 0), sa(x["name"]).lower())):
            if r["spell"] in FUERA:
                retiradas += 1
                continue
            if por_encima_del_tope(r):
                descartadas += 1
                continue
            if es_de_temporada(r):
                de_temporada += 1
                continue
            # la receta se llama como su producto, asi que lleva la misma terminologia
            nombre = casa(visible(nombre_receta(r)))
            pre = pid[:3]
            rid, i = "%s_%s" % (pre, slug(nombre, 34)), 2
            while rid in ids:
                rid = "%s_%s_%d" % (pre, slug(nombre, 30), i)
                i += 1
            ids.add(rid)
            mats = ", ".join('{ key = "%s", qty = %d }'
                             % (clave(nombre_objeto(m), m.get("icon"), m["id"]), m["qty"])
                             for m in r["reagents"])
            c = r.get("creates")
            if c:
                ok, oq = clave(nombre_objeto(c), c.get("icon"), c["id"]), c.get("qty") or 1
            else:
                ok, oq = clave(pergamino(nombre), "inv_scroll_03"), 1
            # Wowhead no da requisito para 35 recetas (patrones raros sin nivel declarado).
            # Inventarles un 1 las colaba al principio de la lista, con la espada de torio
            # antes que los brazales de cobre: se marcan con 0, "sin requisito conocido".
            u_ = umbrales(r)
            skl = (r.get("skill") or (u_[0] if u_ else 0) or PLANO.get(str(r["spell"]))
                   or (HABILIDAD_A_MANO.get(r["spell"]) or (0,))[0] or 0)
            desc = (r.get("efecto") or "").replace("\\", "").replace('"', "'")
            herr = (herramientas(r) or "").replace("\\", "").replace('"', "'")
            # `colors` son los cuatro umbrales de habilidad a los que la receta cambia de
            # color, y de ahi sale la CD real. `dc` se conserva como respaldo para la receta
            # que no los declare y para el codigo que solo lea un numero.
            u = u_
            qm = modificador_calidad(r)
            coste = (ENTRENADOR.get(pid) or {}).get(str(r["spell"]))
            lineas.append(
                '    { id = "%s", profession = "%s", skillReq = %d, name = "%s", icon = "%s", '
                'dc = %d, %smaterials = { %s }, output = { key = "%s", qty = %d }%s },'
                % (rid, pid, skl, nombre.replace('"', "'"),
                   r.get("icon") or "INV_Misc_QuestionMark",
                   (CD_COLOR["naranja"] if u else cd_sin_umbrales()) + qm,
                   (("colors = { %d, %d, %d, %d }, " % tuple(u)) if u else "")
                   + (("qmod = %d, " % qm) if qm else "")
                   + ('source = "entrenador", trainCost = %d, ' % coste
                      if coste is not None else 'source = "receta", '),
                   mats, ok, oq,
                   (', desc = "%s"' % desc if desc else "")
                   + (', tools = "%s"' % herr if herr else "")))
        por_prof[pid] = lineas

    rm = re.search(r"D\.RECIPES\s*=\s*\{", data)
    pos, fuera, ancla, quitadas = rm.end(), [], None, 0
    while True:
        m = re.search(r'\{\s*id\s*=\s*"', data[pos:])
        if not m:
            break
        ini = pos + m.start()
        fin = _cierra(data, ini)
        blk = data[ini:fin]
        # No queda NINGUNA receta escrita a mano, ni siquiera de las profesiones que no se
        # importan: la tabla es lo extraido de Wowhead y nada mas. Herboristeria, Pesca,
        # Desollar y Envenenador se quedan sin recetas, que es lo honesto mientras no haya
        # datos suyos: son recoleccion y Wowhead no las publica como arbol.
        quitadas += 1
        a = data.rfind("\n", 0, ini) + 1
        b = fin + (1 if data[fin:fin + 1] == "," else 0)
        fuera.append((a, b))
        if ancla is None:
            ancla = a
        pos = fin

    tot = sum(len(v) for v in por_prof.values())
    print("recetas nuevas: %d   (descartadas por pasar de habilidad %d: %d)"
          % (tot, TOPE, descartadas))
    print("   descartadas por ser de la Temporada de Descubrimiento: %d" % de_temporada)
    print("   retiradas por decision de mesa: %d" % retiradas)
    for p in sorted(por_prof):
        print("   %-20s %4d" % (p, len(por_prof[p])))
    print("\nse retiran %d recetas escritas a mano de esas profesiones" % quitadas)
    print("materiales y resultados nuevos en el registro: %d" % len(nuevos))
    if "--apply" not in sys.argv:
        return

    for a, b in reversed(fuera):
        data = data[:a] + data[b:]
        if ancla is not None and a < ancla:
            ancla -= (b - a)
    cuerpo = []
    for pid in sorted(por_prof, key=lambda p: ROTULO.get(p, p)):
        cuerpo.append("    -- ===== %s (%d recetas, Wowhead Classic con nombres actuales) ====="
                      % (ROTULO.get(pid, pid), len(por_prof[pid])))
        cuerpo += por_prof[pid]
        cuerpo.append("")
    if ancla is None:
        ancla = re.search(r"D\.RECIPES\s*=\s*\{", data).end() + 1
    data = data[:ancla] + "\n".join(cuerpo) + "\n" + data[ancla:]
    io.open(F_DATA, "w", encoding="utf-8", newline="").write(data)

    bloque = ["\n    -- ===== Materiales y resultados de las profesiones de WoW.",
              "    -- `wow` es el itemId de WoW: sirve para mapear al item de Epsilon"
              " cuando se indique. ====="]
    for k in sorted(nuevos):
        nombre, icono, wid = nuevos[k]
        bloque.append('    ["%s"] = { id = nil, name = "%s"%s%s },'
                      % (k, nombre.replace('"', "'"),
                         ', icon = "%s"' % icono if icono else "",
                         ", wow = %d" % wid if wid else ""))
    # Completar las entradas que ya existian: se les anota el itemId (y el icono si les
    # faltaba) sin tocar nada mas de la linea. Sin esto, los materiales mas usados de todos
    # ("Barra de cobre", "Cuero ligero") se quedaban sin ficha en la web, porque reutilizan
    # una clave que el proyecto ya tenia y esa no traia el itemId.
    # La terminologia de la casa se escribe en la entrada que ya existia, en vez de crear
    # una clave nueva: asi "Barra de cobre" pasa a "Lingote de cobre" SIN perder el itemId
    # de Epsilon que alguien puso a mano en `lingote_cobre`.
    rebautizados = 0
    for k, nuevo in renombrar.items():
        m = re.search(r'(\["%s"\]\s*=\s*\{[^}]*?name\s*=\s*")([^"]*)(")' % re.escape(k), items)
        if m and m.group(2) != nuevo:
            items = items[:m.start()] + m.group(1) + nuevo + m.group(3) + items[m.end():]
            rebautizados += 1
    if rebautizados:
        print("entradas renombradas a la terminologia de la casa: %d" % rebautizados)

    puestos = 0
    for k, (wid, icono) in refuerzo.items():
        m = re.search(r'(\["%s"\]\s*=\s*\{)([^}]*)(\})' % re.escape(k), items)
        if not m:
            continue
        cuerpo = m.group(2)
        add = ""
        if wid and not re.search(r"\bwow\s*=", cuerpo):
            add += ", wow = %d" % wid
        if icono and not re.search(r"\bicon\s*=", cuerpo):
            add += ', icon = "%s"' % icono
        if not add:
            continue
        items = (items[:m.start()] + m.group(1) + cuerpo.rstrip().rstrip(",") + add + " "
                 + m.group(3) + items[m.end():])
        puestos += 1
    print("entradas antiguas completadas con su itemId: %d" % puestos)

    ri, rf = bloque_registry(items)
    items = items[:rf] + "\n".join(bloque) + "\n" + items[rf:]

    # Podar lo que ya no usa ninguna receta. Se respeta una excepcion: la entrada que ya
    # tenga su itemId real de Epsilon puesto a mano se conserva aunque nadie la use, porque
    # ese dato no se puede volver a deducir y borrarlo seria tirar trabajo hecho.
    usadas = set(re.findall(r'key = "([^"]+)"', "\n".join(
        l for v in por_prof.values() for l in v)))
    quitar, guardadas = [], []
    for m in re.finditer(r'\n[ \t]*\["([^"]+)"\]\s*=\s*\{([^}]*)\},?', items):
        k, cuerpo = m.group(1), m.group(2)
        if k in usadas:
            continue
        if re.search(r"\bid\s*=\s*\d+", cuerpo):
            guardadas.append(k)
            continue
        quitar.append((m.start(), m.end()))
    for a, b in reversed(quitar):
        items = items[:a] + items[b:]
    print("objetos antiguos retirados del registro: %d" % len(quitar))
    if guardadas:
        print("conservados por tener ya su itemId de Epsilon: %d -> %s"
              % (len(guardadas), ", ".join(sorted(guardadas))))

    io.open(F_ITEMS, "w", encoding="utf-8", newline="").write(items)
    print("\nescrito")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
