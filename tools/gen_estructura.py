# -*- coding: utf-8 -*-
"""Regenera ESTRUCTURA.md, el organigrama de modulos del addon.

Uso:  python tools/gen_estructura.py

Los datos salen del codigo real: el orden de carga del `.toc`, el tamaño de cada archivo y el rol
declarado en su cabecera de comentario. Los modulos cuya cabecera no declara un rol lo toman del
mapa ROLE de abajo, verificado leyendo el codigo. Si añades un modulo sin cabecera, añadelo ahi:
el script avisa si alguno se queda sin rol.
"""
import re, io, os, sys
from collections import OrderedDict

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "Harford")
TOC = os.path.join(ADDON, "Harford.toc")

# Modulos cuya cabecera no declara rol (verificados leyendo el codigo).
ROLE = {
 "Core/HarfordPhaseStore.lua": "Transporte comun del almacen de fase de Epsilon: escribir con pcall, leer con plazo y vaciar segmentos. Comparte el como, no la politica.",
 "Contracts/HarfordContractsPhase.lua": "Tablon guardado EN LA FASE: indice mas un bloque por contrato. No exige que el DM este conectado.",
 "Loot/HarfordLootPhase.lua": "Loot guardado en la fase, con manifiesto local de las claves escritas para poder limpiarlas.",
 "Reputation/HarfordReputationPhase.lua": "Facciones guardadas en la fase, con espejo local de ids para no pisar el trabajo de otro DM.",
 "Core/HarfordSync.lua": "Transporte de addon messages: serializacion, troceo en chunks, canales y reensamblado con TTL.",
 "Core/HarfordConfig.lua": "Ajustes del addon con listeners de cambio (gates tipo `actionbar`, modo de coste de conjuros).",
 "Core/HarfordAuthority.lua": "Fuente unica de autoridad: rango de phase, modo DM y permisos (`IsOfficerPlus`, `CanUseDMTools`).",
 "Server/HarfordEpsilonCommands.lua": "Wrapper de bajo nivel sobre EpsilonLib/ARC para enviar comandos al servidor.",
 "Server/HarfordServerActions.lua": "Acciones de servidor validadas (dar item, auras, vida y emotes de NPC). Unica puerta desde gameplay.",
 "TRP3/HarfordTRP3.lua": "Lectura segura de perfiles TRP3: ficha de jugador, stat block de NPC, enlaces y escritura del About.",
 "Compendium/HarfordCompendioCore.lua": "API del compendio: coste y resolucion de lanzamiento (`ResolveCast`), progresion de conjuros y filtros.",
 "Compendium/HarfordCompendioData.lua": "Catalogo de conjuros (nivel, escuela, componentes, dano, mecanica). Solo datos.",
 "Compendium/HarfordCompendioIconMap.lua": "Resuelve el icono de un conjuro (fileID, `spell:`, ruta o LibRPMedia).",
 "Compendium/HarfordCompendioUI.lua": "Ventana del compendio: listado, filtros y detalle de conjuro.",
 "DnD/State/HarfordDnDResources.lua": "Definicion y orden de los recursos, cache de recursos remotos y flags de animacion.",
 "DnD/State/HarfordDnDStore.lua": "Persistencia compacta de la ficha (SavedVariables) y helpers numericos compartidos.",
 "DnD/Engine/HarfordDnDComm.lua": "Despachador de `DND5EARC`: valida el remitente y enruta cada opcode a su handler.",
 "Frames/HarfordUnitFrames.lua": "Overlays de Harford sobre los unitframes nativos (target, focus, ToT, party/raid).",
 "Frames/HarfordNamePlates.lua": "Overlays sobre nameplates nativos y KuiNameplates.",
 "Reputation/HarfordReputation.lua": "Nucleo de reputaciones: facciones, puntos por PJ y rangos.",
 "Reputation/HarfordReputationSync.lua": "Sync de reputacion (`HARFORDREP`) con snapshots troceados y TTL.",
 "Reputation/HarfordReputationUI.lua": "Panel de reputaciones, standalone o embebido en el panel de personaje.",
 "Contracts/HarfordContractsCore.lua": "Nucleo del tablon: estado, SavedVariable y gate de modo DM.",
 "Contracts/HarfordContractsData.lua": "Modelo de contratos: alta, edicion, borrado, dificultad y orden.",
 "Contracts/HarfordContractsUtil.lua": "Helpers de presentacion del tablon (iconos, color por dificultad, metadatos).",
 "Contracts/HarfordContractsUI.lua": "Tablon de contratos: lista, detalle y reclamacion de recompensas.",
 "Contracts/HarfordContractsDM.lua": "Editor DM de contratos (crear, publicar, resetear).",
 "Contracts/HarfordContractsComm.lua": "Sync del tablon: snapshots fragmentados y autoridad de sesion del DM.",
 "Contracts/HarfordContractsMinimap.lua": "Boton/hub de minimapa del tablon.",
 "Loot/HarfordLoot.lua": "Loot resuelto por GUID, configuracion global y su sync (`HARFORDLOOT`/`HARFORDCFG`).",
}

LAYER = {
 "Core": ("Infraestructura", "Transporte, chat, configuracion, autoridad y utilidades puras. No depende de nadie."),
 "Server": ("Servidor Epsilon", "Comandos validados hacia el servidor. Solo se entra por aqui."),
 "TRP3": ("Integracion TRP3", "Lectura/escritura de perfiles de TotalRP3."),
 "Compendium": ("Compendio de conjuros", "Catalogo y resolucion de lanzamiento."),
 "DnD/Data": ("D&D - Datos", "Libros hardcodeados: clases, razas, trasfondos, dotes, armas, mitigacion."),
 "DnD/State": ("D&D - Estado", "Persistencia y estado por perfil: ficha, progresion, equipo, formas."),
 "DnD/Engine": ("D&D - Motor", "Calculo y reglas: tiradas, combate, condiciones, area y red."),
 "DnD/UI": ("D&D - Interfaz", "Ficha de personaje y controles de tirada."),
 "Character": ("Panel de personaje", "Creacion, subida de nivel, libro, conjuros e inspeccion."),
 "Frames": ("Frames del juego", "Overlays sobre unitframes, nameplates y tracker de turnos."),
 "Reputation": ("Reputacion", "Facciones y rangos por personaje."),
 "Quests": ("Misiones", "Catalogo, estado por PJ, registro, tracker y quests de mundo."),
 "Contracts": ("Contratos", "Tablon de contratos con autoridad DM."),
 "Professions": ("Profesiones", "Profesiones D&D/WoW y sus recetas."),
 "Communicator": ("Comunicador", "Mensajeria RP fiable y bandeja de herramientas."),
 "Loot": ("Loot", "Loot resuelto y configuracion compartida."),
}
SEQ = ["Core", "Server", "TRP3", "Compendium", "DnD/Data", "DnD/State", "DnD/Engine", "DnD/UI",
       "Character", "Frames", "Reputation", "Quests", "Contracts", "Professions", "Communicator", "Loot"]

ROLECLEAN = re.compile(r"^--+\s?")

def header_role(src):
    """Rol declarado en las primeras lineas de comentario del archivo."""
    out = []
    for line in src.split("\n")[:8]:
        if line.startswith("--"):
            text = ROLECLEAN.sub("", line).strip()
            if text and not set(text) <= set("-=_ "):
                out.append(text)
        elif out or line.strip():
            break
    return " ".join(out)

def tidy(role, filename):
    """Quita el prefijo redundante con el nombre del modulo y deja UNA frase."""
    role = (role or "").strip()
    base = filename[:-4]
    for prefix in (base, base.replace("Harford", "")):
        role = re.sub(r"^%s\s*[-:]\s*" % re.escape(prefix), "", role)
    match = re.match(r"(.+?\.)(?:\s|$)", role)
    if match and len(match.group(1)) > 30:
        role = match.group(1)
    role = role.strip()
    return (role[0].upper() + role[1:]) if role else ""

def collect():
    rows = []
    for line in io.open(TOC, encoding="utf-8"):
        entry = line.strip()
        if not entry.endswith(".lua") or entry.startswith("#"):
            continue
        rel = entry.replace("\\", "/")
        src = io.open(os.path.join(ADDON, rel), encoding="utf-8", errors="replace").read()
        rows.append({
            "folder": os.path.dirname(rel),
            "file": os.path.basename(rel),
            "path": rel,
            "lines": src.count("\n") + 1,
            "role": ROLE.get(rel) or tidy(header_role(src), os.path.basename(rel)),
        })
    return rows

def build(rows):
    by_folder = OrderedDict()
    for row in rows:
        by_folder.setdefault(row["folder"], []).append(row)
    total = sum(r["lines"] for r in rows)

    out = []
    add = out.append
    add("# Estructura del addon Harford")
    add("")
    add("Organigrama de los modulos: que hay en cada carpeta, que hace cada archivo y como fluyen los")
    add("datos entre capas. **Documento generado desde el codigo** con `python tools/gen_estructura.py`;")
    add("regeneralo cuando muevas o añadas un modulo.")
    add("")
    add("- Contratos de modulo, limitaciones de Epsilon y enfoques fallidos: **`AGENTS.md`**")
    add("- Instrucciones para agentes: **`CLAUDE.md`** - **`.github/copilot-instructions.md`**")
    add("- Historial de cambios: **`CHANGELOG.md`**")
    add("")
    add("## Resumen")
    add("")
    add("| | |")
    add("|---|---|")
    add("| Modulos (`Harford/`) | **%d** en **%d** carpetas |" % (len(rows), len(by_folder)))
    add("| Lineas de codigo | ~%s |" % format(total, ",").replace(",", " "))
    add("| Addons hermanos | `HarfordAdmin/` (herramientas DM) - `HarfordDebug/` (diagnostico, opcional) |")
    add("")
    add("## Capas y orden de carga")
    add("")
    add("WoW carga los archivos **en el orden del `.toc`**, y todos comparten el namespace global: no hay")
    add("`require` ni rutas entre archivos. Por eso el orden es lo unico que importa, y va de la")
    add("infraestructura hacia la interfaz. Mover un archivo de carpeta es seguro; cambiarlo de sitio en")
    add("el `.toc` solo lo es si su dependencia sigue cargando antes.")
    add("")
    add("```")
    add("Core --> Server --> TRP3 --> Compendium")
    add("  |")
    add("  +--> DnD/Data --> DnD/State --> DnD/Engine --> DnD/UI")
    add("                                      |")
    add("                                      +--> Character - Frames - Reputation - Quests")
    add("                                           Contracts - Professions - Communicator - Loot")
    add("```")
    add("")
    for folder in SEQ:
        items = by_folder.get(folder)
        if not items:
            continue
        title, desc = LAYER[folder]
        add("## `%s/` - %s" % (folder, title))
        add("")
        add(desc)
        add("")
        add("| Archivo | Lineas | Rol |")
        add("|---|--:|---|")
        for row in items:
            role = (row["role"] or "-").replace("|", "/")
            if len(role) > 190:
                role = role[:190].rsplit(" ", 1)[0] + "..."
            add("| `%s` | %d | %s |" % (row["file"], row["lines"], role))
        add("")

    add("## Flujo de datos")
    add("")
    add("```")
    add("Libros (DnD/Data)        catalogos hardcodeados: clases, razas, trasfondos, dotes, armas")
    add("        |")
    add("        v")
    add("Estado (DnD/State)       progresion, ficha, equipo y formas por perfil -> SavedVariables")
    add("        |")
    add("        v")
    add("Motor (DnD/Engine)       resuelve efectos, calcula y tira; unico que aplica reglas")
    add("        |")
    add("        v")
    add("Interfaz (DnD/UI,        pinta y dispara acciones; no decide reglas")
    add("  Character, Frames)")
    add("```")
    add("")
    add("Regla practica: **los datos no llaman al motor** (el Libro es capa de datos y lo consume la")
    add("importacion de TRP3), y **la interfaz no calcula reglas**: pide el valor ya resuelto.")
    add("")
    add("## Red")
    add("")
    add("Todo mensaje entre clientes pasa por `HarfordSync`. Los receptores que aplican algo **validan")
    add("siempre el remitente** (propio, unidad visible o miembro de grupo/raid).")
    add("")
    add("| Prefijo | Modulo | Transporta |")
    add("|---|---|---|")
    add("| `DND5EARC` | `DnD/Engine/HarfordDnDComm.lua` | Ficha, tiradas, recursos, condiciones, area y auras |")
    add("| `HARFORDTURN` | `Frames/HarfordTurns.lua` | Estado del tracker de turnos |")
    add("| `HARFORDLOOT` / `HARFORDCFG` | `Loot/HarfordLoot.lua` | Loot resuelto y configuracion global |")
    add("| `HARFORDREP` | `Reputation/HarfordReputationSync.lua` | Reputaciones y snapshots |")
    add("| `HARFORDQUEST` | `Quests/HarfordQuests.lua` | Estado de misiones y cierre por el DM |")
    add("| `HARFCOM` | `Communicator/HarfordCommunicator.lua` | Mensajeria RP (solo texto) |")
    add("| `HARFORDPROF` | `Professions/HarfordProfessions.lua` | Enseñar recetas worldLearned (DM -> jugador) |")
    add("| Tablon | `Contracts/HarfordContractsComm.lua` | Snapshots de contratos con autoridad de sesion |")
    add("")
    add("## Donde toco cada cosa")
    add("")
    add("| Quiero cambiar... | Archivo |")
    add("|---|---|")
    add("| Una clase, subclase o rasgo | `DnD/Data/HarfordDnDBook.lua` |")
    add("| Una raza o un trasfondo | `DnD/Data/HarfordDnDRaces.lua` - `HarfordDnDBackgrounds.lua` |")
    add("| Un conjuro | `Compendium/HarfordCompendioData.lua` |")
    add("| Como se calcula una tirada o un bonus | `DnD/Engine/HarfordDnDCalc.lua` - `HarfordDnDFeatureEffects.lua` |")
    add("| La CA, el impacto o la mitigacion | `DnD/Engine/HarfordDnDCombat.lua` - `DnD/Data/HarfordDamageMitigation.lua` |")
    add("| La ventana de la ficha | `DnD/UI/HarfordDnD.lua` |")
    add("| La creacion o la subida de nivel | `Character/HarfordCharacterCreation.lua` - `HarfordCharacterAdvancement.lua` |")
    add("| Los overlays sobre unitframes | `Frames/HarfordUnitFrames.lua` |")
    add("| Un comando al servidor Epsilon | `Server/HarfordServerActions.lua` |")
    add("| Un diagnostico temporal | `HarfordDebug/HarfordDebug.lua` (nunca en modulos de gameplay) |")
    add("| Algo exclusivo de modo DM | `HarfordAdmin/` (nunca en el core) |")
    add("")
    return "\n".join(out)

def main():
    rows = collect()
    missing = [r["path"] for r in rows if not r["role"]]
    io.open(os.path.join(ROOT, "ESTRUCTURA.md"), "w", encoding="utf-8", newline="\n").write(build(rows))
    print("ESTRUCTURA.md regenerado: %d modulos, %d carpetas" % (
        len(rows), len({r["folder"] for r in rows})))
    if missing:
        print("AVISO: sin rol (añadelos al mapa ROLE): %s" % ", ".join(missing))
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
