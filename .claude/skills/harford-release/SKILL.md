---
name: harford-release
description: Cierra un lote de cambios de Harford - bateria de pruebas, despliegue con exit code directo, commit, retag y zips de distribucion. Usar al terminar cualquier cambio de codigo que haya que entregar, o cuando el usuario pida "commit", "despliega" o "los zips".
---

# Cierre de un lote de cambios de Harford

Orden FIJO. No saltarse pasos ni reordenarlos.

## 1-2. Compilación + batería + despliegue: UN comando, UN exit code

```bash
cd "C:/Users/marco/Documents/New project" && python tools/lote.py; echo "lote exit $?"
```

`tools/lote.py` compila los 6 addons con `luac -p`, corre la batería completa de
`tools/pruebas/` y despliega con `tools/desplegar.py`. Si algo falla NO despliega y sale
con 1: solo se sigue con `LOTE VERDE`. Con `--sin-desplegar` se queda en compilación+batería.

**NUNCA encadenar el despliegue a un pipe** (`desplegar.py | tail`): el pipe enmascara el
exit code y ya se hizo commit sobre despliegues rojos cuatro veces — por eso existe lote.py.

## 3. Commit y retag

- Rama `dev`. Mensaje en español, convención `tipo(ámbito): resumen` (feat/fix/docs/refactor).
- Tras el commit: `git tag -f v2.1.0 -m "Harford v2.1.0"` (o la versión vigente del `.toc`).

## 4. Zips de distribución — SOLO si el usuario los pide expresamente

**NUNCA generarlos por iniciativa propia** — ni entre cambios, ni al hacer commit. El cierre
normal de lote TERMINA en el retag. Los zips son un acto de distribución que decide el usuario
(2026-08-29, corregido dos veces: "en cada commit" tampoco vale).

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
