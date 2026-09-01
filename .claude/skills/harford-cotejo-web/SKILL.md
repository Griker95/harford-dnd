---
name: harford-cotejo-web
description: Coteja o sincroniza descripciones del addon Harford contra la web (compendium-*.js) sin pisar la mecanica adaptada. Usar cuando el usuario pida cotejar/sincronizar trasfondos, razas, clases, dotes o conjuros contra la web, o importar descripciones nuevas.
---

# Cotejo del addon contra la web Harford

La web publicada (`harfordweb`) es la fuente canónica de textos. La copia local
(`C:/Users/marco/Documents/harfordweb/js/compendium-*.js`) puede ir POR DETRÁS de la viva:
revisar primero los ids tocados hoy en el addon antes de re-sincronizar (ya pisó el CON+1
del Man'ari una vez).

## Reglas del script de sincronización

1. **Sincronizar por ID**, nunca por nombre ni por posición.
2. **Guarda de MECÁNICA**: no tocar líneas que contengan mecánica adaptada — `choice`,
   `optionsFrom`, `spellGrants`, `grantedSpells`, `actionKind`, `area`, `effects`,
   `subclassMarker`, `requiredRaces/Ability/Proficiency/Caster`. Solo se sincroniza texto
   (`desc`/descripciones).
3. **Offsets frescos**: mutar el string invalida los offsets de un `finditer` previo.
   Re-buscar CADA id en el texto ACTUAL antes de cada reemplazo (esto corrompió los 12
   ficheros de clase una vez).
4. **Auto-revert**: tras escribir, `luac -p` sobre cada fichero tocado; si no compila,
   `git checkout` de ese fichero y reportar el id que rompió.
5. Scripts al scratchpad con el tool Write (heredocs de Git Bash comen backslashes).

## Si el cambio AÑADE CAMPOS a cabeceras de datos

Insertar un campo entre `id` y `name` (o en general en la cabecera de dotes/razas/subrazas/
clases/trasfondos) ha dejado TRES veces colecciones del códice en CERO: sus extractores
reescribían el fichero web vacío sin quejarse (latente hasta el siguiente rebuild). Ya
toleran campos intermedios y `extract_dotes`/`deploy_compendium` llevan seguro de vuelco
(<80% de lo publicado = aborta), pero la regla sigue: tras añadir campos, avisar al chat del
códice o comprobar los recuentos tras regenerar (12 clases, 17 razas, 52 trasfondos,
77 dotes, 44 profesiones).

## Después del cotejo

- Los marcadores de subclase se detectan por el campo `subclassMarker = true`, no por frase:
  si se añade una clase o selector nuevo, marcarlo.
- Correr la batería (`tools/pruebas/`), en particular `datos_opciones.lua`,
  `clases_manual.lua` y `efectos_rasgos.lua`.
- Incoherencias detectadas en la web (niveles mal, duplicados) se ANOTAN y se pasan al otro
  chat (el del códice), no se corrigen unilateralmente: `HarfordCompendio/HarfordCompendio.lua`
  es compartido con ese chat y con Codex.
