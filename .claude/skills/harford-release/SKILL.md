---
name: harford-release
description: Cierra un lote de cambios de Harford - bateria de pruebas, despliegue con exit code directo, commit, retag y zips de distribucion. Usar al terminar cualquier cambio de codigo que haya que entregar, o cuando el usuario pida "commit", "despliega" o "los zips".
---

# Cierre de un lote de cambios de Harford

Orden FIJO. No saltarse pasos ni reordenarlos.

## 1. Batería de pruebas

```bash
cd "C:/Users/marco/Documents/New project" && for f in tools/pruebas/*.lua; do out=$(lua "$f" 2>&1 | tail -1); case "$out" in *CORRECTO*|*ok*) : ;; *) echo "REVISAR $(basename $f): $out";; esac; done; echo "bateria hecha"
```

Cualquier `REVISAR` bloquea el cierre. Antes de la batería, `luac -p` sobre cada `.lua` tocado.

## 2. Despliegue — exit code DIRECTO

```bash
cd "C:/Users/marco/Documents/New project" && python tools/desplegar.py > "$TEMP/dep.log" 2>&1; echo "deploy exit $?"; tail -3 "$TEMP/dep.log"
```

**NUNCA `desplegar.py | tail`**: el pipe enmascara el exit code y ya se hizo commit sobre despliegues rojos cuatro veces. Si el exit no es 0, leer `$TEMP/dep.log` entero y arreglar antes de seguir.

## 3. Commit y retag

- Rama `dev`. Mensaje en español, convención `tipo(ámbito): resumen` (feat/fix/docs/refactor).
- Tras el commit: `git tag -f v2.1.0 -m "Harford v2.1.0"` (o la versión vigente del `.toc`).

## 4. Zips de distribución — SOLO aquí (o si el usuario los pide)

No reconstruirlos entre cambios: el usuario lo pidió expresamente (2026-08-29).

- **jugador**: `Harford` + `HarfordCompendio` + `HarfordProfesiones` + `README.md` + `CHANGELOG.md`
- **dm**: lo anterior + `HarfordAdmin` + `HarfordDebug`
- Excluir siempre `HarfordObjectCatalog.lua` (tooling de 1.2 MB, no carga en el toc) y `__pycache__`.
- `Harford-2.1.0.zip` envuelve la carpeta `Harford-2.1.0-jugador`.
- Verificar tras zipear: cero entradas `ObjectCatalog` y cero restos de nombres viejos (`HarfordCompendioData`).
- Entregar los zips con SendUserFile (`display: attach`).

## Recordatorios que ya costaron

- Todos los `.lua` UTF-8 SIN BOM; tras editar, buscar mojibake compuesto (`\u00C3\u0192`, `\u00E2\u20AC`, `\uFFFD`), nunca `Ã`/`Â` sueltos.
- Scripts Python al scratchpad con el tool Write, nunca heredoc de Git Bash (se come un nivel de backslashes).
- Si el cambio confirma una limitación o patrón nuevo, actualizar `AGENTS.md` en el mismo lote.
