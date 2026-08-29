# Iconos que la web declara y el cliente de Epsilon no tiene

Detectado con `/harford debug run iconoscheck` sobre un cliente real de Epsilon.
Son **15 de 1430** (1%), de los cuales **13 hay que cambiarlos en la web**. Los tres
`spell:<id>` que aparecian en la primera pasada eran
un falso positivo del validador, ya corregido.

Todos existen como PNG en `assets/compendium-icons/`, asi que **en la web se ven bien**:
el problema es solo que el cliente no sirve esa textura bajo `Interface\Icons\<nombre>`.
Hace falta sustituirlos por un nombre que Epsilon si tenga.

Dato util para acotar: `eps_bg3_shockingrasp` esta en la web **y funciona** en juego,
mientras que `eps_bg3_levitate` esta en la web y no. No es que falte la familia entera.

## Los que hay que cambiar en la web (13)

| id | nombre | icono que falla | fichero de la web | fichero del addon | png en la web |
|---|---|---|---|---|---|
| `feat_mb_potente` | Conjuro potente | `ArcaneIntensity` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `resiliente` | Resiliente | `HotS_ResilientShield` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `novato_liga_expedicionarios` | Novato de la Liga de Expedicionarios | `INV_Cape_Armor_Explorer_D_01_backpack` | compendium-data.js | HarfordDnDBackgrounds.lua | si |
| `bg_liga_pionero` | Pionero audaz | `INV_Helm_Armor_Explorer_D_01` | compendium-data.js | HarfordDnDBackgrounds.lua | si |
| `amigo_criaturas` | Amigo de las criaturas | `Ivern_FriendOfTheForest` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `versado_elemento` | Versado en un elemento | `LiMing_TalRashasElements` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `abrazo_vacio` | Abrazo del Vacío | `Malzahar_VoidShift` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `operativo_ravenholdt` | Operativo de Ravenholdt | `Medivh_RavenForm` | compendium-data.js | HarfordDnDBackgrounds.lua | si |
| `feat_pe_reroll` | Precisión | `Tyrande_HuntersMark` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `feat_fe_esquivar` | Esquivar y curar | `XinZhao_Determination` | compendium-dotes.js | HarfordDnDFeats.lua | si |
| `levitar` | Levitar | `eps_bg3_levitate` | compendium-data.js | HarfordCompendio.lua | si |
| `enmaranar` | Enmarañar | `eps_lol_zyra_graspingroot` | compendium-data.js | HarfordCompendio.lua | si |
| `feriante_luna_negra` | Feriante de la Luna Negra | `poster_darkmoon1` | compendium-data.js | HarfordDnDBackgrounds.lua | si |

## Dos que NO son trabajo de la web

- **`vida_falsa` / `eps_bg3_aid`**: es el SEGUNDO candidato de ese conjuro en el
  catalogo del addon (`{ "spell:20707", "eps_bg3_aid", "eps_buildershaven_gobinfo" }`).
  El primero, `spell:20707`, si existe, asi que el conjuro se ve bien y la cadena de
  respaldo hace su trabajo. Inofensivo; lo limpio yo en el addon.
- **`guardia_ciudad_detective` / `Secret`**: ese id solo existe en la web y en el
  catalogo importado; ningun fichero de datos del addon lo usa, asi que en juego no se
  ve. Merece arreglarse igualmente para la web, pero no afecta al addon.

## Reparto

- -: 2
- HarfordCompendio.lua: 2
- HarfordDnDBackgrounds.lua: 4
- HarfordDnDFeats.lua: 7

## Al terminar

Cuando esten cambiados en la web, reimportar con:

```
python tools/codice/importar_iconos_web.py --escribir --lista
```

y volver a pasar `/harford debug run iconoscheck` en juego para confirmar que quedan 0.
