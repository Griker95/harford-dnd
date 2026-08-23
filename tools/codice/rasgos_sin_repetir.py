# -*- coding: utf-8 -*-
"""Quita de la presentacion de cada raza los rasgos que ya salen abajo con su icono.

La presentacion que viene del libro repite, uno a uno, los mismos rasgos que la ficha ya
enseña como lista. Aqui se retiran, con una regla estricta: **solo se borra el parrafo si
su texto ya esta entero en el rasgo**. Si dice algo distinto se queda y se avisa, porque
lo contrario seria perder texto sin que nadie se entere.

Las secciones de subraza (`### Enano de Forjaz`) tambien se retiran, pero su presentacion
NO se tira: se pasa a la descripcion de la subraza si no la tiene ya.

Lo que no es un rasgo -- Edad, Alineamiento, Tamano, los nombres, la tabla de altura y
peso -- no se toca.
"""
import difflib
import re
import unicodedata

TITULO = re.compile(r"^\*{2,3}\s*([^*]+?)\s*\.?\*{2,3}\s*([\s\S]*)$")
CABECERA = re.compile(r"^#{3,4}\s+(.+?)\s*(?:\n([\s\S]*))?$")


def nk(s):
    s = "".join(c for c in unicodedata.normalize("NFD", s or "")
                if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "", s.lower())


# El libro y la ficha no siempre nombran igual a la subraza: "Troll del bosque" contra
# "Troll de Bosque". Con la comparacion literal, la seccion entera de esa subraza se
# quedaba dentro de la raza y su incremento parecia una promesa que la raza no cumplia.
_PARTICULAS = ("del", "de", "la", "las", "los", "el")


def clave_flexible(s):
    palabras = [w for w in re.split(r"[^0-9A-Za-zÁÉÍÓÚÜÑáéíóúüñ']+", s or "") if w]
    return "".join(nk(w) for w in palabras if nk(w) not in _PARTICULAS)


def _contenido(parrafo, rasgo):
    """El parrafo no aporta nada si el rasgo ya dice lo mismo.

    No basta con comparar el texto: el libro y la ficha redactan igual con otras palabras
    ("Competente con Percepcion" / "Competencia en Percepcion", "chequeo" / "prueba"), y
    eso dejaba el parrafo duplicado. Se acepta un parecido alto, pero con una condicion
    que no se negocia: **ningun numero del parrafo puede faltar en el rasgo**. Asi nunca
    se pierde un dado, un alcance ni un bonificador por parecerse mucho la frase.
    """
    a, b = nk(parrafo), nk(rasgo)
    if not a:
        return True
    if a == b or a in b:
        return True
    if set(re.findall(r"\d+", parrafo)) - set(re.findall(r"\d+", rasgo)):
        return False
    return difflib.SequenceMatcher(None, a, b).ratio() >= 0.85


def aplicar(kb):
    quitados = conservados = movidos = 0
    avisos = []
    for r in kb.get("races", []):
        rasgos_raza = {nk(f["name"]): f for f in r.get("traits", [])}
        subrazas = {}
        for s in r.get("subraces", []):
            subrazas[nk(s["name"])] = s
            subrazas.setdefault(clave_flexible(s["name"]), s)
        rasgos_sub = {nk(s["name"]): {nk(f["name"]): f for f in s.get("traits", [])}
                      for s in r.get("subraces", [])}

        bloques = [b.strip() for b in (r.get("desc") or "").split("\n\n") if b.strip()]
        salida, ambito = [], None
        for b in bloques:
            cab = CABECERA.match(b)
            _cabk = nk(cab.group(1)) if cab else ""
            _cabf = clave_flexible(cab.group(1)) if cab else ""
            if cab and (_cabk in subrazas or _cabf in subrazas):
                # cabecera de subraza: su presentacion se guarda y la seccion desaparece
                sub = subrazas.get(_cabk) or subrazas[_cabf]
                ambito = nk(sub["name"])
                intro = (cab.group(2) or "").strip()
                if intro and not _contenido(intro, sub.get("desc") or ""):
                    sub["desc"] = ((sub.get("desc") or "").rstrip() + "\n\n" + intro).strip()
                    movidos += 1
                quitados += 1
                continue
            if cab:
                ambito = None          # cualquier otra cabecera cierra el ambito de subraza
                # "### Rasgos de los Enanos" solo encabeza lo que la ficha ya lista aparte
                if not re.match(r"(?i)^rasgos\b", cab.group(1).strip()):
                    salida.append(b)
                else:
                    quitados += 1
                continue

            m = TITULO.match(b)
            if not m:
                salida.append(b)
                continue
            titulo, cuerpo = m.group(1), m.group(2).strip()
            k = nk(titulo)
            # primero el ambito en el que estamos; si no, los rasgos de la raza
            rasgo = (rasgos_sub.get(ambito, {}).get(k) if ambito else None) or rasgos_raza.get(k)
            hermanos = ""
            # los hermanos se juntan SIEMPRE, no solo cuando no hay coincidencia exacta:
            # el Elfo del Vacio tiene "Incremento de caracteristica" y "(eleccion)", y al
            # encontrar el primero se dejaba de mirar el segundo, que era justo el que
            # completaba la frase del libro.
            if k:
                # El libro dice "Incremento de caracteristica" en una frase y la ficha lo
                # parte en "(+2)" y "(+1)". Se compara contra los DOS juntos: por separado
                # ninguno contiene la frase entera y el parrafo se quedaba duplicado.
                cand = [f for kk, f in (rasgos_sub.get(ambito) or rasgos_raza).items()
                        if kk.startswith(k)]
                if len(cand) > 1:
                    hermanos = " ".join(f.get("desc") or "" for f in cand)
                if cand and not rasgo:
                    rasgo = cand[0]
            if not rasgo:
                salida.append(b)
                continue
            if _contenido(cuerpo, rasgo.get("desc") or "") or (
                    hermanos and _contenido(cuerpo, hermanos)):
                quitados += 1
            else:
                conservados += 1
                avisos.append((r["name"], titulo, len(cuerpo), len(rasgo.get("desc") or "")))
                salida.append(b)
        r["desc"] = "\n\n".join(salida)
    return quitados, conservados, movidos, avisos
