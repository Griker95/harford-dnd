# -*- coding: utf-8 -*-
"""Saca TODO lo que el export de Discord sabe de cada trasfondo, no solo las tablas.

`bgs_source.json` se extrajo a mano de un export parcial (25 trasfondos) y quedo marcado
como fuente no regenerable. Con el export completo (42) ya no hace falta: esto lo
reconstruye entero y ademas recoge lo que antes se perdia -- las VARIANTES y la IMAGEN de
cada trasfondo, incluida la de la propia variante.

Lo que hay en cada pagina, en mensajes sueltos y sin orden fijo:
  - la presentacion, seguida de "Competencias en habilidades / con herramientas /
    Vehiculos / Idiomas / Equipo";
  - "**Rasgo: <Nombre>**" con su texto;
  - "Caracteristicas recomendadas" y las cuatro tablas (esas las sigue leyendo
    `tablas_discord`, que ya las resuelve bien);
  - "**Variante del <trasfondo>: *Nombre*" con su texto;
  - una imagen por mensaje propio, que pertenece al mensaje de TEXTO anterior. Asi es como
    se sabe cual es la del trasfondo y cual la de su variante.

Los trasfondos de la casa NO estan en el export y no se tocan aqui.
"""
import glob
import html
import io
import json
import os
import re
import sys
import unicodedata

EXPORT = r"C:/Users/marco/Documents/New project/RuleSource/Discord_Export"
SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bgs_source.json")

# Cada etiqueta abre un campo y lo cierra la siguiente. "Vehiculos" va aparte de las
# herramientas en el export, aunque el compendio las junte despues.
CAMPOS = (
    ("skills", r"competencias?\s+en\s+habilidades?"),
    ("tools", r"competencias?\s+con\s+herramientas?"),
    ("weapons", r"competencias?\s+con\s+armas?"),
    ("vehicles", r"veh[ií]culos?"),
    ("langs", r"idiomas?"),
    ("equip", r"equipo"),
)
ETIQUETA = re.compile(r"^\s*(%s)\s*:\s*$" % "|".join(p for _, p in CAMPOS), re.I)
MARCA_HORA = re.compile(r"^\d{1,2}/\d{1,2}/\d{4}\s+\d{1,2}:\d{2}\s*[AP]M$")
IMG = re.compile(r"@@IMG:([^@]+)@@")


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9 ]", " ", s.lower()).strip()


def limpio(x):
    """Quita el markdown de Discord y los restos de la exportacion."""
    x = re.sub(r"\*{1,3}", "", x or "")
    return re.sub(r"\s+", " ", x).strip()


def bloques(carpeta):
    """Los mensajes de la pagina, en orden, con sus imagenes marcadas.

    Las etiquetas se sustituyen ANTES de aplanar el HTML: si no, el nombre del fichero de
    la imagen se pierde con el resto de atributos y no hay forma de saber a que mensaje
    pertenece."""
    txt = ""
    for f in sorted(glob.glob(os.path.join(carpeta, "*.html"))):
        s = io.open(f, encoding="utf-8", errors="ignore").read()
        s = re.sub(r"<(script|style)\b.*?</\1>", "", s, flags=re.S | re.I)
        # se sustituye la ETIQUETA ENTERA, no solo el atributo: el marcador puesto dentro
        # de la etiqueta se lo llevaba por delante el `<[^>]+>` que aplana el HTML
        s = re.sub(r'<(?:img|a)\b[^>]*?(?:src|href)="([^"]*media/attachments/[^"]+)"[^>]*>',
                   lambda m: "\n@@IMG:%s@@\n" % os.path.basename(m.group(1)), s)
        txt += html.unescape(re.sub(r"<[^>]+>", "\n", s))
    lineas = [l.strip() for l in txt.split("\n") if l.strip()]
    out, actual = [], []
    for l in lineas:
        if MARCA_HORA.match(l):
            if actual:
                out.append(actual)
            actual = []
            continue
        actual.append(l)
    if actual:
        out.append(actual)
    return out


def _campos(lineas):
    """Presentacion + competencias/equipo de un mensaje que traiga las etiquetas."""
    d, campo, buf, pres = {}, None, [], []
    for l in lineas:
        m = ETIQUETA.match(l)
        if m:
            if campo:
                d[campo] = limpio(" ".join(buf)).rstrip(".")
            etq = nk(m.group(1))
            campo = next((k for k, p in CAMPOS if re.fullmatch(p, etq, re.I)), None)
            buf = []
            continue
        (buf if campo else pres).append(l)
    if campo:
        d[campo] = limpio(" ".join(buf)).rstrip(".")
    if pres:
        d["desc"] = "\n\n".join(limpio(p) for p in pres if limpio(p))
    return d


# Los bloques de las cuatro tablas y el de "Caracteristicas recomendadas" no son la
# presentacion, aunque tampoco traigan etiquetas: los reconoce su encabezado o sus filas
# numeradas. Las tablas las lee `tablas_discord`, no esto.
_CABECERA_TABLA = re.compile(
    r"^(rasgos? de personalidad|ideales?|v[ií]nculos?|defectos?|caracter[ií]sticas recomendadas)",
    re.I)


def _es_tabla(texto):
    if any(_CABECERA_TABLA.match(l) for l in texto):
        return True
    numeradas = sum(1 for l in texto if re.fullmatch(r"\d{1,2}\.", l))
    return numeradas >= 3


def de_carpeta(carpeta):
    datos, ultimo_texto = {"variants": []}, None
    for b in bloques(carpeta):
        crudo = "\n".join(b)
        img = IMG.search(crudo)
        texto = [l for l in b if not IMG.match(l) and l not in ("(no content)", "🖼️", "Local")
                 and not re.fullmatch(r"[\d.,]+\s*[KM]B", l) and l != "image.png"]
        # un mensaje que solo trae imagen es la ilustracion del mensaje de texto anterior
        if img and not [l for l in texto if len(l) > 25]:
            if ultimo_texto is not None:
                ultimo_texto["image"] = img.group(1)
            continue

        cuerpo = "\n".join(texto)
        destino = None

        mvar = re.search(r"Variante\s+del?\s+[^:]{2,40}:\s*\*{0,3}([^*\n]{2,60})", cuerpo, re.I)
        mr = re.search(r"Rasgo\s*:\s*\n?\s*(.+)", cuerpo)
        if mvar:
            resto = cuerpo[mvar.end():].strip()
            destino = {"name": limpio(mvar.group(1)),
                       "desc": "\n\n".join(limpio(p) for p in resto.split("\n") if limpio(p))}
            datos["variants"].append(destino)
        elif mr and "Rasgo:" in cuerpo:
            nombre = limpio(mr.group(1).split("\n")[0])
            cola = cuerpo[cuerpo.index(mr.group(1)) + len(mr.group(1)):].strip()
            datos["rasgoName"] = nombre
            datos["rasgoDesc"] = "\n\n".join(limpio(p) for p in cola.split("\n") if limpio(p))
            destino = datos
        elif any(ETIQUETA.match(l) for l in texto):
            datos.update(_campos(texto))
            destino = datos
        elif not datos.get("desc") and not _es_tabla(texto):
            # La presentacion no siempre viaja con las competencias: el Forjador de la
            # Hermandad del Torio la manda en un mensaje suelto y se perdia entera.
            prosa = [limpio(l) for l in texto if len(l) > 60]
            if prosa:
                datos["desc"] = "\n\n".join(prosa)
                destino = datos

        # La imagen puede venir en el mismo mensaje o en el suyo propio justo detras. El
        # bloque del final arrastra ademas el pie del export ("Exported with Discrub..."),
        # asi que no vale con mirar si el bloque trae texto: se decide por lo que APORTA.
        if img:
            objetivo = destino or ultimo_texto
            if objetivo is not None and not objetivo.get("image"):
                objetivo["image"] = img.group(1)
        if destino is not None:
            ultimo_texto = destino
    if not datos["variants"]:
        datos.pop("variants")
    return datos


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    out = {}
    for slug in sorted(os.listdir(EXPORT)):
        carpeta = os.path.join(EXPORT, slug)
        if not os.path.isdir(carpeta) or not glob.glob(os.path.join(carpeta, "*.html")):
            continue
        out[slug] = de_carpeta(carpeta)
    io.open(SALIDA, "w", encoding="utf-8", newline="").write(
        json.dumps(out, ensure_ascii=False, indent=1, sort_keys=True))
    print("trasfondos del export: %d" % len(out))
    for campo in ("desc", "rasgoName", "skills", "tools", "langs", "equip", "vehicles",
                  "image", "variants"):
        n = sum(1 for v in out.values() if v.get(campo))
        print("   %-11s %2d" % (campo, n))
    faltan = [s for s, v in out.items() if not v.get("desc")]
    for s in faltan:
        print("   sin presentacion: %s" % s)
    nv = sum(len(v.get("variants") or []) for v in out.values())
    print("variantes: %d | con imagen: %d"
          % (nv, sum(1 for v in out.values() for x in (v.get("variants") or []) if x.get("image"))))


if __name__ == "__main__":
    main()
